# Policy Command — Data Collection Pipeline

## Overview

Policy Command is a legislative data platform built on a hybrid compute architecture: an EC2-backed ECS cluster for always-on user-facing services, and Fargate Spot workers for event-driven batch processing that scales to zero when idle. The platform separates predictable steady-state workloads from bursty legislative data collection and indexing, enabling independent scaling, cost optimization, and resilience.

The core architectural principle is **unit-of-work sizing**: every Fargate Spot worker handles exactly one unit of work (one bill, one statute chapter, one document, one file download) and exits. Concurrency is controlled by the Step Functions Map State, not by in-process thread pools or memory headroom. This means per-task memory requirements are dramatically smaller than the batch-sized allocations of the previous always-on services.

A key pattern is **nested fan-out**: the `bill-scraping-worker` discovers all document URLs for a bill via Playwright, then delegates the actual file retrieval to a nested Map State of `document-download-worker` tasks that fetch and store files in parallel. Separation of concerns keeps each worker focused on a single I/O profile — navigation vs. download vs. parse vs. embed.

---

## Guiding Principles

- **Unit of work, not batch sizing** — each Fargate Spot task handles one bill, one statute chapter, one file download, or one document index operation. The old service memory ceilings (3–4 GB) were sized for running 20+ concurrent units inside a single process. Step Functions Map State controls concurrency externally, allowing each task to be sized for exactly one unit of work.
- **Nested fan-out for heterogeneous work** — `bill-scraping-worker` (Playwright, navigation) delegates file retrieval to a nested Map State of `document-download-worker` tasks (HTTP stream to S3, no browser). Each layer handles one I/O profile at the smallest possible footprint.
- **Infrastructure-agnostic services** — business logic never imports AWS SDK, database drivers, or infrastructure clients directly. All infrastructure access goes through shared client libraries with configuration injection. The same service code runs in local Docker and AWS production; only the `.env` changes.
- **Idempotent workers** — every scraping and indexing operation checks existing state before writing. Re-running any job produces the same result. This makes Step Functions retries, manual re-triggers, and failure recovery safe by default.
- **Tracking tables as the source of truth** — before any bill or statute chapter can be scraped, a corresponding tracking record must exist in `SessionBillTracking` or `StatuteChapterYearTracking`. These tables drive all batch collection and are the authoritative record of what has been processed, what is pending, and what failed.
- **Human-initiated vs automated** — operator-initiated jobs flow through `pipeline-service` (UI → API → Step Functions). Automated event-driven jobs flow through EventBridge → SNS → SQS → Step Functions. Both paths converge on the same Step Functions state machines and the same Fargate Spot workers.
- **Local dev parity** — the event-driven AWS infrastructure (EventBridge, SNS, SQS) does not exist in local development. `pipeline-service` absorbs this role locally, providing the same trigger surface via HTTP that AWS automation provides in production. No local code changes are needed to switch between environments.

---

## Unit of Work — Why Per-Task Sizing is Smaller

The previous `document-scraping-service` was allocated 3072 MB hard limit + 1536 MB swap because it ran a Playwright browser pool processing many bills concurrently inside a single long-running process. The `indexing-service` similarly ran a Python asyncio concurrency loop across many documents simultaneously.

In the new architecture, **Step Functions Map State replaces in-process concurrency**:

```
Old model:
  1 long-running process
  internal Playwright pool (N browsers)
  internal asyncio semaphore (N documents)
  needs memory for ALL concurrent units
  → 3–4 GB to handle throughput

New model:
  Step Functions Map State { MaxConcurrency: 20 }
  spawns 20 Fargate Spot tasks in parallel
  each task: 1 Playwright session, 1 bill, exits when done
  → 1–1.5 GB per task × 20 tasks running in parallel
  → same throughput, smaller per-task footprint
  → each task terminates as soon as its bill is done
    (no slow bill holds memory for the whole batch)
```

**Per-unit memory reality:**

| Unit of work | What it actually needs | Old batch sizing | New per-task sizing |
|---|---|---|---|
| 1 bill (discover docs) | 1 Playwright session, navigate bill page, collect URLs | 3 GB (shared pool) | 512 MB–1 GB |
| 1 PDF / file download | HTTP GET → stream to S3; no browser, no parsing | 3 GB (same process) | 256–512 MB |
| 1 statute chapter | 1 Playwright session or HTTP fetch, HTML scrape, write RDS + S3 | 3 GB (shared pool) | 512 MB–1 GB |
| 1 document (index) | PyMuPDF extract, chunk, 1 Bedrock call, write OpenSearch | 1 GB (shared loop) | 512 MB–1 GB |
| Session bill list check | HTTP scrape only, no Playwright browser session | 3 GB (same process) | 256–512 MB |

The session bill list check (discovering new bills) never needed a full Playwright browser pool — it was just co-located in the same heavy process. Separated into its own thin `session-sync-worker`, it needs almost nothing. Similarly, PDF downloading never needed Playwright at all — it was bundled into the same process as browser navigation. The `document-download-worker` handles pure I/O at 256–512 MB, freeing the `bill-scraping-worker` from holding file bytes in memory.

---

## Worker Decomposition

The existing `document-scraping-service` is decomposed into five single-responsibility workers. Each is a Fargate Spot task that receives one unit of work and exits.

### session-sync-worker

Discovers new bills filed for a session. No Playwright browser — just HTTP requests to the FL legislature website to check the session bill index.

```
Triggered by: EventBridge scheduled rule (every N minutes during session)
              OR pipeline-service manual trigger (Check for New Bills)
    ↓
HTTP scrape of session bill listing (no full browser — lightweight fetch)
    ↓
For each bill number found:
    Check if row exists in SessionBillTracking
    If not: INSERT new row (status: pending)
    If yes and status = completed: check for document updates (optional)
    ↓
Publish SNS message per pending bill → SQS bill-scraping-queue
    ↓
Update RealtimeSyncSettings: lastRunAt, nextRunAt, status → idle
    ↓
Exit
```

**Sizing: 0.25 vCPU / 512 MB.** No browser. Pure Node.js HTTP + DB writes. Runs for seconds to a few minutes per invocation.

---

### bill-scraping-worker

Navigates one bill's page via Playwright, discovers all document URLs, then delegates file retrieval to a nested fan-out of `document-download-worker` tasks. The worker itself never holds PDF bytes in memory — it is responsible only for navigation, metadata writes, and orchestrating the download fan-out.

```
Triggered by: Step Functions Map State (one task per bill)
Input: { billKey, billNumber, sessionYear }
    ↓
Open ONE Playwright browser session
Navigate to bill page
Collect all document URLs and their metadata:
    [ { url, storagePath, documentType, billKey }, ... ]
    (versions, analyses, amendments, vote history — may be 100+ files)
Close browser
    ↓
Write bill metadata to RDS (SessionBillTracking: status → in_progress)
    ↓
Start nested Step Functions child execution: document-download SM
    Map State { MaxConcurrency: 10 } — one document-download-worker per URL
    ├── document-download-worker (hb413_c2.pdf      → s3://bills/fl/2026/413/...)
    ├── document-download-worker (analysis_house.pdf → s3://bills/fl/2026/413/...)
    ├── document-download-worker (amendment_001.pdf  → s3://bills/fl/2026/413/...)
    └── document-download-worker (vote_floor.pdf     → s3://bills/fl/2026/413/...)
    ↓
Collect download results (success / failed per file)
    ↓
Update SessionBillTracking: status → completed, documentCount, lastScrapedAt
    errorMessage populated if any downloads failed
    ↓
For each successfully downloaded file:
    POST pipeline-service /pipelines/index/document { objectPath, documentType, billKey }
    ↓
Exit
```

**Sizing: 0.5–1 vCPU / 512 MB–1 GB.** The worker now only runs Playwright navigation — no PDF bytes held in memory. Memory ceiling is one browser session for the bill page; the heavy I/O is delegated to `document-download-worker` tasks. Start at 0.5 vCPU / 1 GB and benchmark; Chromium navigation is much lighter than Chromium + file downloads.

**Playwright cold start note:** Fargate cold starts add ~30–60 seconds before the task is running. At 0.5 vCPU, Chromium initialization may add another 15–30 seconds. If total cold start is a concern for realtime sync latency, increase to 1 vCPU to reduce initialization time.

---

### document-download-worker

The simplest worker in the fleet. Receives one file URL and a destination storage path, streams the file to S3, and exits. No Playwright. No parsing. No database writes. No indexing signals. Pure I/O.

```
Triggered by: Nested Step Functions Map State inside bill-scraping-worker
Input: { url, storagePath, documentType, billKey, metadata }
    ↓
HTTP GET url
    (retry up to 3× on transient failures with exponential backoff)
    ↓
Stream response body → S3 PutObject at storagePath
    (streamed — file bytes never fully buffered in memory)
    ↓
Verify response: ETag, Content-Length, HTTP 200
    ↓
Return: { success: true, storagePath, sizeBytes, contentType }
     OR: { success: false, url, storagePath, error }
    ↓
Exit
```

Step Functions captures each result. The parent `bill-scraping-worker` inspects the results array after the nested Map State completes — any failed downloads are recorded in `SessionBillTracking.errorMessage` and can be retried individually without re-running the full bill navigation.

**Sizing: 0.25 vCPU / 256–512 MB.**

The worker is almost entirely idle at the CPU level — it waits for HTTP bytes and waits for S3 to acknowledge the write. 0.25 vCPU is sufficient. Memory is bounded by the HTTP streaming buffer, not the file size — a 50 MB PDF never materializes fully in RAM. 256 MB is the Fargate minimum and is appropriate; increase to 512 MB only if streaming libraries require more working memory.

**Why streaming matters:** A bill with 100+ documents averaging 5 MB each = 500 MB of PDFs. If the worker buffered whole files, it would need 500 MB+ of RAM and could only process one file at a time. Streaming means memory usage is constant regardless of file size or count.

**What it deliberately does NOT do:**
- No Playwright or browser (pure HTTP client — axios, requests, or boto3)
- No RDS writes (bill-scraping-worker owns all DB state)
- No indexing signals (bill-scraping-worker signals after all downloads confirm)
- No business logic — just fetch, store, report

This keeps the worker trivially testable, trivially replaceable, and sized at the absolute minimum.

**Cost per 100 files at 0.25 vCPU / 256 MB Fargate Spot (~30s avg per file):**
~0.25 vCPU × (100 × 30s / 3600) hrs × $0.012/vCPU-hr ≈ **$0.003** for 100 file downloads.

---

### statute-chapter-worker

Processes one statute chapter — HTML scrape, write to RDS and S3. Statute HTML is lighter than bill PDFs.

```
Triggered by: Step Functions Map State (one task per chapter from StatuteChapterYearTracking)
Input: { year, state, chapter }
    ↓
Open ONE Playwright browser session (or plain HTTP fetch for HTML chapters)
Scrape chapter HTML, extract sections
    ↓
Write to RDS + S3
Update StatuteChapterYearTracking: status → completed, sectionCount
    ↓
For each chapter HTML written:
    POST pipeline-service /pipelines/index/document { objectPath, documentType: 'statute' }
    ↓
Exit
```

**Sizing: 0.5 vCPU / 512 MB–1 GB.** Statute chapters are HTML, not PDFs — lighter than bill processing. May not need a full browser if the legislature site serves clean HTML without JS rendering; benchmark both fetch and Playwright to determine the minimum viable approach.

---

### indexing-worker

Processes one document through the full vector pipeline. Stateless, idempotent, exits when done.

```
Triggered by: Step Functions indexing Map State (one task per document)
Input: { objectPath, documentType, billKey }
    ↓
Pre-check: chunks exist in OpenSearch for this objectPath? → exit early unless force=true
    ↓
Fetch file from S3
    ↓
Extract text:
    BillVersions/BillAmendments → PyMuPDF (redline detection)
    BillAnalysis/BillVoteHistory → pdfplumber
    statute → BeautifulSoup HTML
    ↓
Chunk (document-type-aware chunker)
    ↓
Embed: Bedrock Titan v2 (multi-region round-robin, rate-limited)
    ↓
Write chunks to OpenSearch (bulk)
    ↓
ACK → exit
```

**Sizing: 0.5 vCPU / 1 GB.** One document at a time. PyMuPDF on a large multi-version bill PDF can spike to ~600–800 MB. 1 GB gives comfortable headroom. Previous 1 GB hard limit + 512 MB swap mapped to ~1.5 GB burst — 1 GB fixed on Fargate is appropriate for a single document; if large PDFs consistently OOM, increase to 1.5 GB.

---

## Tracking Tables — The Collection Control Layer

Two database tables act as the control plane for all collection jobs. Nothing can be scraped without a corresponding row in one of these tables. This design makes every batch job resumable, auditable, and idempotent by default.

### SessionBillTracking

Tracks every bill known to exist in a given legislative session. Populated by the **Initialize Session** step before any bill collection can begin.

```
SessionBillTracking
  sessionYear       TEXT       e.g. "2026"
  billNumber        TEXT       e.g. "413"
  billKey           TEXT       e.g. "fl/2026/413"
  status            ENUM       pending | in_progress | completed | failed
  lastScrapedAt     TIMESTAMP
  documentCount     INT        number of associated documents collected
  errorMessage      TEXT       populated on failure for operator review
  priority          BOOLEAN    flagged for accelerated realtime sync
```

**Initialize Session flow (`/system/bill-collection` → Initialize Session button):**

```
Operator selects session year (e.g. 2026) → clicks Initialize Session
    ↓
pipeline-service → session-sync-worker task (thin, no browser pool)
    ↓
HTTP scrape of FL legislature session bill listing
Discovers all bill numbers filed for the session
    ↓
Upserts one row per bill into SessionBillTracking (status: pending)
    ↓
UI shows: "Total Bills: 1897 | Last Scraped: 5/7/2026"
```

**Bill Collection flow (`/system/bill-collection` → Start Collection button):**

```
Operator selects session, optional bill number filter,
batch scope (All Unprocessed Bills | specific numbers)
    ↓
pipeline-service starts Step Functions scraping execution
    ↓
Step Functions queries SessionBillTracking WHERE status = 'pending'
Loads matching billKeys into Map State input array
    ↓
Map State { MaxConcurrency: 20 } — spawns one bill-scraping-worker per bill
    ├── bill-scraping-worker (bill A): 1 browser, all docs, write RDS+S3, signal indexing, exit
    ├── bill-scraping-worker (bill B): 1 browser, all docs, write RDS+S3, signal indexing, exit
    └── bill-scraping-worker (bill N): 1 browser, all docs, write RDS+S3, signal indexing, exit
    ↓
Step Functions collects results; failed rows remain in table with errorMessage
```

---

### StatuteChapterYearTracking

Tracks every statute chapter for a given year. Populated by the **Initialize Year** step before any chapter collection can begin.

```
StatuteChapterYearTracking
  year              TEXT       e.g. "2025"
  state             TEXT       e.g. "fl"
  chapter           TEXT       e.g. "817"
  status            ENUM       pending | in_progress | completed | failed
  lastScrapedAt     TIMESTAMP
  sectionCount      INT
  errorMessage      TEXT
```

**Initialize Year flow (`/system/statute-collection` → Initialize Year button):**

```
Operator selects statute year → clicks Initialize Year
    ↓
pipeline-service → session-sync-worker (statute variant, no browser pool needed)
    ↓
HTTP fetch of FL statute chapter index for the year
    ↓
Upserts one row per chapter into StatuteChapterYearTracking (status: pending)
    ↓
UI unlocks Chapter Collection controls
```

**Chapter Collection flow (`/system/statute-collection` → Start Collection button):**

```
Operator selects year, optional chapter filter, max chapters per run
    ↓
pipeline-service starts Step Functions statute scraping execution
    ↓
Step Functions queries StatuteChapterYearTracking WHERE status = 'pending' LIMIT max
    ↓
Map State { MaxConcurrency: 10 } — spawns one statute-chapter-worker per chapter
    ├── statute-chapter-worker (ch. 1): scrape HTML, write RDS+S3, signal indexing, exit
    ├── statute-chapter-worker (ch. 2): scrape HTML, write RDS+S3, signal indexing, exit
    └── statute-chapter-worker (ch. N): scrape HTML, write RDS+S3, signal indexing, exit
    ↓
Step Functions collects results
```

Statutes do not have a realtime sync equivalent — they are updated annually. Operators re-run collection after the annual statute publication is updated.

---

## Realtime Collection & Sync

During an active legislative session, bills are filed and updated continuously. The Realtime Collection & Sync system (`/system/realtime-sync`) provides automated polling configured via a `RealtimeSyncSettings` database table, running three independent task types per active session.

### RealtimeSyncSettings Table

```
RealtimeSyncSettings
  sessionYear         TEXT
  taskType            ENUM    session | bill | priority_bill
  enabled             BOOLEAN
  intervalMinutes     INT
  lastRunAt           TIMESTAMP
  lastRunDuration     INT     milliseconds
  nextRunAt           TIMESTAMP
  status              ENUM    idle | running | paused | error
```

### Three Task Types

**Session task** — discovers newly filed bills (runs `session-sync-worker`)

```
Fires every N minutes (lightweight — no browser pool)
    ↓
session-sync-worker: HTTP check of session bill index
New bills found → INSERT into SessionBillTracking (pending)
                → publish to SNS bills-pending
                → Step Functions bill-scraping Map State fires for new bills only
No new bills → update lastRunAt, exit
```

This is cheap and fast — just an HTTP call and some DB upserts. Designed to run every 15 minutes during session without meaningful cost.

**Bill task** — full idempotent sync across all tracked bills

```
Fires every N minutes (less frequent)
    ↓
Reads all billKeys from SessionBillTracking WHERE sessionYear = active
    ↓
Step Functions Map State: spawns one bill-scraping-worker per bill
Each worker: idempotent check → if nothing changed, exit immediately
             if changed: scrape updated docs, write, signal indexing
```

Single-bill processing is idempotent — if nothing has changed the worker exits in seconds. Cost of a no-op bill check is minimal (Fargate Spot task startup + a few HTTP calls + exit).

**Priority bill task** — accelerated sync for flagged bills

```
Fires more frequently than bill task
    ↓
Reads billKeys WHERE priority = true from SessionBillTracking
    ↓
Same Map State pattern, smaller input set, higher frequency
```

### Realtime Sync in Production (EventBridge)

Each active task type maps to one EventBridge scheduled rule. `pipeline-service` manages rule state based on `RealtimeSyncSettings`.

```
RealtimeSyncSettings: { taskType: 'session', intervalMinutes: 15, enabled: true }
    ↓
EventBridge rule: rate(15 minutes) → pipeline-service POST /pipelines/sync/run
    ↓
pipeline-service starts session-sync Step Functions execution
    ↓
session-sync-worker runs, inserts new bills, publishes SNS if any found
    ↓
Updates RealtimeSyncSettings: lastRunAt, nextRunAt, status → idle
```

### Realtime Sync in Local Dev

No EventBridge rules locally. Operator uses Manual Actions panel:
- **Check for New Bills** → `POST /pipelines/sync/run { taskType: 'session' }` → `pipeline-service` calls `document-scraping-service` session-check endpoint directly
- **Process Specific Bill** → `POST /pipelines/sync/run { taskType: 'bill', billNumber }` → `pipeline-service` calls `document-scraping-service` single-bill endpoint directly

---

## Bill Collection — Full Trigger Hierarchy

```
LEVEL 1: Initialize (required once per session, before anything else)
─────────────────────────────────────────────────────────────────────
Operator: Initialize Session
    → session-sync-worker (thin, HTTP only, no browser pool)
    → Populates SessionBillTracking (all rows pending)
    → UI shows bill count and unlocks collection controls

LEVEL 2: Batch Collection (operator-initiated)
─────────────────────────────────────────────────────────────────────
Operator: Start Collection
    → Step Functions reads SessionBillTracking WHERE status = pending
    → Map State { MaxConcurrency: 20 }
    → One bill-scraping-worker per bill (1 browser each, ~1–1.5 GB each)
    → Each worker: write RDS + S3 → signal indexing → exit

LEVEL 3: Realtime Sync (automated during session, or manual)
─────────────────────────────────────────────────────────────────────
Session task (frequent, lightweight):
    → session-sync-worker finds NEW bills → inserts to SessionBillTracking
    → SNS fan-out → SQS → Step Functions spawns bill-scraping-workers for new bills only

Bill task (less frequent, comprehensive):
    → Map State across ALL tracked bills
    → Each bill-scraping-worker: idempotent check, exits fast if no changes

Priority bill task (most frequent, targeted):
    → Map State across priority-flagged bills only
```

---

## Statute Collection — Full Trigger Hierarchy

```
LEVEL 1: Initialize (required once per year)
─────────────────────────────────────────────────────────────────────
Operator: Initialize Year
    → session-sync-worker (statute variant, HTTP fetch of chapter index)
    → Populates StatuteChapterYearTracking (all rows pending)
    → UI unlocks Chapter Collection controls

LEVEL 2: Batch Collection (operator-initiated)
─────────────────────────────────────────────────────────────────────
Operator: Start Collection (optional chapter filter + max chapters)
    → Step Functions reads StatuteChapterYearTracking WHERE status = pending
    → Map State { MaxConcurrency: 10 }
    → One statute-chapter-worker per chapter (~512 MB–1 GB each)
    → Each worker: write RDS + S3 → signal indexing → exit
```

---

## Document Indexing Trigger — Scraper Signals, Not S3

Each `bill-scraping-worker` signals `pipeline-service` after the nested `document-download-worker` fan-out confirms all files are written to S3 and the RDS record is updated. The `statute-chapter-worker` signals the same way after its single HTML write. This eliminates the race condition where an S3 event could fire the indexing worker before the database record is ready.

```
document-download-worker streams file → S3 (storagePath confirmed)
    ↓
bill-scraping-worker collects nested Map State results
    ↓
Writes bill metadata to RDS (SessionBillTracking: completed, documentCount)
    ↓
For each successfully downloaded file:
    POST pipeline-service /pipelines/index/document
        { objectPath, documentType, billKey }
    ↓
pipeline-service → Step Functions indexing execution
    ↓
indexing Map State { MaxConcurrency: 50 }:
    one indexing-worker per document
    pre-check → extract → chunk → embed → OpenSearch → ACK → exit
```

**Fan-out via SNS (optional, additive):** `pipeline-service` can publish to `SNS: bill-document-landed` before triggering indexing. Future consumers (audit log, quality monitoring, analytics) subscribe with their own SQS queues and process independently without touching the indexing path.

---

## Service Tiers

### Tier 1 — EC2-backed ECS Cluster (always on)

Five predictable, steady-state services run on a single EC2 instance (t3.large, ~$60/mo). These have consistent memory profiles and benefit from EC2's soft reservation model — paying for what they actually use rather than a fixed Fargate allocation.

| Service | EC2 reservation | EC2 hard limit | EC2 swap | Notes |
|---|---|---|---|---|
| `web-app` | 512 MB | 1024 MB | none | nginx + React SPA |
| `keycloak` | 1536 MB | 2048 MB | none | JVM `-Xmx1024m` |
| `core-service` | 768 MB | 1536 MB | 768 MB | Primary UI API |
| `rap-service` | 512 MB | 1024 MB | 256 MB | LLM orchestration |
| `pipeline-service` | 256 MB | 512 MB | none | New; thin SDK-only service |
| **Total soft reservations** | **~3.6 GB** | | | **of ~6 GB on t3.large — comfortable deploy headroom** |

Removing `document-scraping-service` and `indexing-service` from the EC2 cluster is the primary benefit. The Playwright memory hog (3 GB hard + 1.5 GB swap) no longer competes with `core-service`, `keycloak`, and `rap-service` for EC2 capacity during batch collection or deploys.

**t3.large → t3.xlarge during peak session:** If realtime sync generates heavy bill-scraping-worker traffic that creates downstream pressure, the EC2 instance can be scaled vertically without changing task definitions. This is a simpler scaling lever than ECS ASG for a 5-service cluster.

### Tier 2 — Orchestration Layer (serverless, no persistent compute)

| Component | Role |
|---|---|
| **EventBridge Scheduler** | Three rules per active session (session / bill / priority-bill); rates from `RealtimeSyncSettings` |
| **SNS: `bills-pending`** | Fan-out when session-sync-worker finds new bills |
| **SNS: `bill-document-landed`** | Optional — fan-out when a document is written; future subscribers |
| **SQS: `bill-scraping-queue`** | Durable buffer between SNS and bill-scraping Map State |
| **SQS: `indexing-queue`** | Durable buffer for indexing triggers; holds until worker ACKs |
| **SQS DLQ** | Catches persistent failures; CloudWatch alarm; manual replay |
| **EventBridge Pipes** | Connects SQS queues directly to Step Functions — no polling code |
| **Step Functions: session-sync SM** | Runs session-sync-worker; updates RealtimeSyncSettings |
| **Step Functions: bill-scraping SM** | Map State fan-out → bill-scraping-workers; each spawns nested document-download SM |
| **Step Functions: document-download SM** | Nested Map State fan-out → document-download-workers (called from within bill-scraping SM) |
| **Step Functions: statute-scraping SM** | Map State fan-out → statute-chapter-workers |
| **Step Functions: indexing SM** | Map State fan-out → indexing-workers; verify OpenSearch counts |
| **Step Functions: backup SM** | Orchestrates S3 backup/restore and OpenSearch snapshot |

### Tier 3 — Fargate Spot Workers (scale to zero)

One unit of work per task. Memory sized for a single unit, not batch throughput. Concurrency is Step Functions Map State's responsibility, not the worker's.

| Worker | Unit of work | vCPU | Memory | Basis |
|---|---|---|---|---|
| `session-sync-worker` | Session bill list check or chapter index fetch — HTTP only, no browser | 0.25 | 512 MB | No Playwright; pure HTTP + DB |
| `bill-scraping-worker` | 1 bill — Playwright navigation, collect URLs, orchestrate download fan-out | 0.5–1 | 512 MB–1 GB | Playwright navigation only; no PDF bytes in memory |
| `document-download-worker` | 1 file — HTTP stream to S3; no browser, no parsing, no DB writes | 0.25 | 256–512 MB | Pure I/O; streaming keeps memory constant regardless of file size |
| `statute-chapter-worker` | 1 statute chapter — HTML scrape | 0.5 | 512 MB–1 GB | May not need full browser |
| `indexing-worker` | 1 document — extract, chunk, embed, index | 0.5 | 1 GB | PyMuPDF peaks at ~600–800 MB |
| `backup-worker` | S3 migration or OpenSearch snapshot | 0.5 | 1 GB | I/O bound |

**MaxConcurrency recommendations (Step Functions Map State):**

| State machine | MaxConcurrency | Rationale |
|---|---|---|
| Bill scraping | 20 | 20 parallel Playwright sessions; tune based on legislature site rate limits |
| Document download (nested per bill) | 10 | 10 concurrent HTTP→S3 streams per bill; balance against legislature site rate limits |
| Statute scraping | 10 | Statute site is lighter; 10 concurrent chapters is safe |
| Indexing | 50 | No browser; CPU + Bedrock API calls; Bedrock multi-region handles rate limits |

**Cost comparison — old batch model vs new unit model (same throughput):**

| Approach | Tasks | Memory each | Total memory | Cost basis |
|---|---|---|---|---|
| Old: 1 batch process, 20 concurrent bills with downloads | 1 always-on task | 4 GB | 4 GB, 24/7 | EC2 always-on |
| New: 20 bill-scraping-workers + up to 200 download-workers | Up to 220 Fargate Spot tasks | 1 GB / 256 MB | ~22 GB aggregate, only while running | Fargate Spot, ~$0.012/vCPU-hr |

The aggregate memory is higher but the cost is lower because tasks exist only while doing work — a bill that finishes in 90 seconds releases its 1.5 GB immediately rather than holding it for the duration of the full batch.

---

## Failure Handling

| Failure scenario | Handled by |
|---|---|
| bill-scraping-worker crashes mid-bill | Step Functions retries the Map State item; `SessionBillTracking` row resets to `pending`; idempotent re-run safe |
| document-download-worker fails (site timeout, S3 error) | Step Functions retries the nested Map State item up to 3×; failed downloads reported back to bill-scraping-worker; recorded in `errorMessage`; individual files replayable without re-running Playwright navigation |
| Bill scrape error (site unavailable, parse failure) | Worker writes error to `SessionBillTracking.errorMessage`; row → `failed`; visible to operator |
| statute-chapter-worker crashes | Same pattern; `StatuteChapterYearTracking` row resets |
| indexing-worker OOM on large PDF | Increase worker memory to 1.5 GB; Step Functions retries; pre-check prevents duplicate chunks |
| Step Functions execution fails entirely | Execution marked FAILED; SNS alert fires; tracking rows remain inspectable and replayable |
| SQS message fails N retries | Moved to DLQ; CloudWatch alarm fires; message safe for manual replay |
| Bedrock rate limit | Handled inside `indexing-worker` via multi-region round-robin; transparent to Step Functions |
| Duplicate indexing trigger | Pre-check in indexing SM skips already-indexed objectPaths |
| Realtime sync task overlap | `RealtimeSyncSettings.status = running` prevents concurrent execution of same task type |
| Fargate Spot interruption | AWS gives 2-minute warning; Step Functions retries interrupted tasks; idempotent workers safe to re-run |

---

## pipeline-service API

```
Session initialization
  POST /pipelines/scrape/bills/initialize      → run session-sync-worker (bill variant)
  POST /pipelines/scrape/statutes/initialize   → run session-sync-worker (statute variant)

Bill + statute collection
  POST /pipelines/scrape/bills                 → start bill-scraping SM
  POST /pipelines/scrape/statutes              → start statute-scraping SM
  GET  /pipelines/scrape/status/{arn}          → Step Functions execution status

Realtime sync
  POST /pipelines/sync/enable                  → enable EventBridge rules; set RealtimeSyncSettings.enabled = true
  POST /pipelines/sync/disable                 → disable EventBridge rules
  POST /pipelines/sync/run                     → manual trigger { taskType, sessionYear, billNumber? }
  GET  /pipelines/sync/status/{sessionYear}    → current RealtimeSyncSettings rows

Indexing
  POST /pipelines/index/document               → index one document (called by scraping workers after write)
  POST /pipelines/index/bill                   → index all documents for a bill
  POST /pipelines/index/crawl                  → full crawl indexing SM
  GET  /pipelines/index/status/{arn}           → execution status

Backup / restore
  POST /pipelines/backup
  POST /pipelines/restore
  GET  /pipelines/backup/status/{arn}

Health + quality
  GET  /pipelines/health
  GET  /pipelines/quality/bills/{session}
  GET  /pipelines/quality/statutes/{year}
```

---

## System Pages → pipeline-service Mapping

| System page | UI action | pipeline-service endpoint |
|---|---|---|
| `/system/bill-collection` | Initialize Session | `POST /pipelines/scrape/bills/initialize` |
| `/system/bill-collection` | Start Collection | `POST /pipelines/scrape/bills` |
| `/system/statute-collection` | Initialize Year | `POST /pipelines/scrape/statutes/initialize` |
| `/system/statute-collection` | Start Collection | `POST /pipelines/scrape/statutes` |
| `/system/realtime-sync` | Enable & Start Collection | `POST /pipelines/sync/enable` |
| `/system/realtime-sync` | Check for New Bills | `POST /pipelines/sync/run { taskType: session }` |
| `/system/realtime-sync` | Process Specific Bill | `POST /pipelines/sync/run { taskType: bill, billNumber }` |
| `/system/realtime-sync` | Status cards (poll) | `GET /pipelines/sync/status/{sessionYear}` |
| `/system/backup` | Run Backup | `POST /pipelines/backup` |
| `/system/indexing` | Start Crawl | `POST /pipelines/index/crawl` |
| `/system/bill-quality` | Load stats | `GET /pipelines/quality/bills/{session}` |
| `/system/statute-quality` | Load stats | `GET /pipelines/quality/statutes/{year}` |
| `/system/service-monitor` | Health check | `GET /pipelines/health` |

The web app replaces `VITE_DOCUMENT_SCRAPING_SERVICE_URL` and `VITE_INDEXING_SERVICE_URL` with a single `VITE_PIPELINE_SERVICE_URL`. The `coreApi` and `rapApi` clients are unchanged.

---

## Local Development — No AWS Event Infrastructure

The AWS event-driven layer (EventBridge, SNS, SQS, Step Functions) does not exist in local development. `pipeline-service` absorbs this role, routing requests directly to worker service HTTP endpoints.

```
Production:                                    Local dev:
──────────────────────────────────             ──────────────────────────────────
EventBridge fires session task                 Developer clicks "Check Now"
  → session-sync SM                            → POST /pipelines/sync/run
  → session-sync-worker (Fargate Spot)           → document-scraping-service /session-check

bill-scraping SM Map State (20 workers)        pipeline-service calls sequentially
  → 20 bill-scraping-worker tasks                → document-scraping-service /process-bill
                                                   for each bill (no parallelism locally)

bill-scraping-worker signals completion        Same signal
  → POST /pipelines/index/document             → POST /pipelines/index/document
  → indexing SM Map State                        → indexing-service:3003 /api/v1/index/document
  → indexing-worker tasks
```

```bash
NODE_ENV=development   # pipeline-service calls existing worker HTTP endpoints directly
NODE_ENV=production    # pipeline-service uses Step Functions + manages EventBridge rules
```

**What local dev does NOT replicate:** Step Functions Map State parallelism (local runs sequentially), SQS durability and DLQ, EventBridge scheduling, Fargate Spot interruption handling, multi-AZ failover. These are covered by a staging environment mirroring production.

---

## Cost Estimates — Current vs Target Architecture

### Current Production (EC2-backed ECS, 6 services)

From `terraform/README.md`: **~$314–329/month** base (excludes Bedrock LLM token costs).

| Component | Current | Notes |
|---|---|---|
| ECS EC2 instances | 2× t3.large | All 6 services share capacity; deploy-time squeeze |
| OpenSearch | Self-hosted EC2 t3.medium | 2 GB JVM heap; 100 GB gp3 |
| MongoDB | Self-hosted EC2 t3.small | 50 GB gp3 |
| RDS PostgreSQL | 2× single-AZ | Keycloak + main; no Multi-AZ resilience |
| ALBs | Public + Private | Private ALB for inter-service routing |

---

### Target Architecture (Hybrid EC2 ECS + Fargate Spot)

#### EC2 ECS Cluster — Always-On Tier 1

| Service | Reservation | Hard limit | Tasks | Notes |
|---|---|---|---|---|
| `web-app` | 512 MB | 1 GB | 1–2 | nginx static |
| `keycloak` | 1536 MB | 2 GB | 1–2 | JVM heap |
| `core-service` | 768 MB | 1.5 GB | 1–2 | Primary API |
| `rap-service` | 512 MB | 1 GB | 1–2 | LLM orchestration |
| `pipeline-service` | 256 MB | 512 MB | 1 | New; SDK calls only |
| **Total soft reservation** | **~3.6 GB** | | | **of ~6 GB t3.large** |

EC2 instance cost: **~$60/mo (1× t3.large)**. Down from ~$120–140 (2× instances) because the Playwright memory hog (`document-scraping-service`, 3 GB hard + 1.5 GB swap) is removed from the cluster entirely.

#### Fargate Spot — Unit-of-Work Workers

Spot pricing ~$0.012/vCPU-hour, ~$0.0013/GB-hour.

| Worker | vCPU | Memory | Typical run time | Cost per 100 bills |
|---|---|---|---|---|
| `session-sync-worker` | 0.25 | 0.5 GB | ~30–60s | ~$0.01 |
| `bill-scraping-worker` | 0.5–1 | 512 MB–1 GB | ~1–3 min/bill (nav only) | ~$0.03–0.08 |
| `document-download-worker` | 0.25 | 256–512 MB | ~15–60s/file | ~$0.30–1.00 (est. 500 files/100 bills) |
| `statute-chapter-worker` | 0.5 | 1 GB | ~1–2 min/chapter | ~$0.01–0.02 |
| `indexing-worker` | 0.5 | 1 GB | ~30–90s/doc | ~$0.01–0.03 |
| `backup-worker` | 0.5 | 1 GB | ~10–30 min/run | ~$0.01/run |

**Monthly worker cost estimates:**

| Scenario | Est. cost |
|---|---|
| Off-session (workers idle) | ~$0 |
| Light session (50 bills/week, incremental indexing) | ~$5–15 |
| Active session (200+ bills/week, realtime sync) | ~$25–60 |
| Full initial collection (1897 bills, all docs) | ~$20–50 one-time |

#### Shared Infrastructure (unchanged from current)

| Component | Monthly est. |
|---|---|
| RDS PostgreSQL (2× single-AZ, keep current) | ~$60–80 |
| OpenSearch (self-hosted EC2 t3.medium, keep current) | ~$30 |
| MongoDB (self-hosted EC2 t3.small, keep current) | ~$15 |
| S3 (`policycommand-documents` + `policycommand-agents`) | ~$4–6 |
| Public ALB only (private ALB eliminated) | ~$20–25 |
| Bedrock embeddings (~200M tokens/mo incremental) | ~$4 |
| Step Functions (~5K executions × ~15 transitions) | ~$2 |
| EventBridge / SNS / SQS | ~$1 |
| ECR | ~$1 |

---

### Side-by-Side Monthly Total

| Category | Current (EC2 ECS, 6 services) | Target (Hybrid) | Δ |
|---|---|---|---|
| EC2 compute | ~$120–140 (2× t3.large) | ~$60 (1× t3.large) | **-$60–80** |
| Fargate Spot workers | — | ~$5–60 (varies by session activity) | +$5–60 |
| RDS PostgreSQL | ~$60–80 (2× single-AZ) | ~$60–80 (keep current) | $0 |
| OpenSearch | ~$30 (self-hosted, keep) | ~$30 (keep) | $0 |
| MongoDB | ~$15 (self-hosted, keep) | ~$15 (keep) | $0 |
| S3 | ~$4–6 | ~$4–6 | $0 |
| Bedrock embed | ~$4 | ~$4 | $0 |
| ALBs | ~$35–45 (public + private) | ~$20–25 (public only) | **-$15–20** |
| Step Functions / EventBridge / SNS / SQS | — | ~$3 | +$3 |
| ECR | ~$1 | ~$1 | $0 |
| **Total (base, excl. LLM tokens)** | **~$314–329** | **~$202–278** | **-$50–125** |

The hybrid EC2 + Fargate Spot model is **cheaper than the current architecture**, not more expensive. The two savings are:
- Dropping from 2 EC2 instances to 1 (~$60–80/mo saved) by removing Playwright from the cluster
- Eliminating the private ALB (~$15–20/mo saved) since pipeline-service replaces inter-service HTTP routing for operational tasks

Fargate Spot worker costs during active session (~$25–60) are offset by the EC2 reduction. Off-session, the total drops below $250/mo since workers are completely idle.

### What the Hybrid Architecture Buys

- **Deploy-time squeeze eliminated** — `document-scraping-service` (the memory culprit) is gone from the EC2 cluster; 5 services on 1 t3.large has comfortable headroom
- **Workers cost $0 at rest** — Fargate Spot tasks exist only while processing; no idle Playwright capacity paid for 24/7
- **Per-bill memory drops 3–4×** — from 4 GB batch to 1–1.5 GB per unit; Step Functions controls concurrency externally
- **Independent failure domains** — a Playwright crash kills one bill's task, not the whole cluster
- **Fargate Spot interruption is safe** — idempotent workers and SQS visibility timeout mean an interrupted task just retries
- **No code changes to existing services** — `document-scraping-service` and `indexing-service` refactored into workers; same logic, new boundaries

---

## Migration Path

1. **Build `pipeline-service`** — scaffold Express service; implement Step Functions SDK calls; implement `NODE_ENV=development` passthrough to existing service HTTP endpoints; implement `RealtimeSyncSettings` read/write.
2. **Migrate system pages** — update UI to call `pipeline-service` instead of `document-scraping-service` and `indexing-service` directly. Verify all system pages work end-to-end.
3. **Extract `session-sync-worker`** — pull session bill list check and chapter index fetch out of `document-scraping-service` into a thin standalone worker. No Playwright, no browser pool.
4. **Extract `bill-scraping-worker`** — encapsulate `processSingleBill` navigation logic into a standalone Fargate Spot worker. Playwright discovers document URLs; delegates file retrieval to the nested document-download SM.
4a. **Build `document-download-worker`** — simple HTTP stream → S3 worker. ~50 lines of code. No browser, no DB, no indexing logic. Wire as a nested Step Functions Map State called from within bill-scraping SM.
5. **Extract `statute-chapter-worker`** — same pattern for statute chapter scraping.
6. **Convert `indexing-service` to `indexing-worker`** — remove internal crawl concurrency loop; accept single `objectPath` via task input; let Step Functions Map State own concurrency.
7. **Wire Step Functions state machines** — bill-scraping SM with Map State, statute-scraping SM, indexing SM. Set MaxConcurrency values.
8. **Wire EventBridge + SNS + SQS** — scheduled rules from `RealtimeSyncSettings`, SQS queues with DLQs, EventBridge Pipes connecting queues to state machines.
9. **Remove `document-scraping-service` and `indexing-service` from EC2 ECS cluster** — redeploy cluster; verify 5-service memory profile; downsize from 2× to 1× EC2 instance.
10. **Eliminate private ALB** — update nginx routing; verify all inter-service calls route through `pipeline-service`.

---

## Key Design Decisions

**Unit-of-work sizing replaces batch sizing**
Each Fargate Spot task handles one bill, one chapter, or one document. Step Functions Map State controls concurrency at the orchestration layer, not inside the worker process. This reduces per-task memory 3–4× compared to the batch model while delivering the same throughput via parallelism.

**session-sync-worker is separated from bill-scraping-worker**
Discovering new bills (a lightweight HTTP check) was previously co-located in the same heavy process as Playwright bill scraping. Separated, it runs at 256 MB instead of consuming 3+ GB. The session task now runs cheaply every 15 minutes during session with negligible cost.

**document-download-worker is separated from bill-scraping-worker**
PDF downloading is pure I/O — HTTP stream to S3 — with no need for Playwright, parsing, or database access. Previously bundled into the same process as browser navigation, it now runs as a nested Map State of tiny 256 MB tasks. A bill with 100+ files fans out to 100+ parallel downloads, each using only a streaming HTTP buffer in memory regardless of file size. The bill-scraping-worker is freed from holding file bytes and can focus solely on Playwright navigation and result coordination.

**Tracking tables gate all collection**
`SessionBillTracking` and `StatuteChapterYearTracking` are mandatory prerequisites. Initialize populates them; workers read from and write back to them. Jobs are resumable (failed rows stay pending), auditable (every row has timestamps and error messages), and operator-visible.

**Realtime sync is table-driven**
`RealtimeSyncSettings` is the single source of truth for sync state. EventBridge schedules are derived from it; `pipeline-service` manages rule enable/disable. Changing sync frequency is a DB row update, not a code or infrastructure change.

**Scraper signals indexing, not S3 events**
Each scraping worker signals `pipeline-service` after both the RDS record and S3 file are confirmed written, eliminating the race condition where an S3 trigger fires the indexing worker before the database record is ready.

**pipeline-service is the local dev event bus**
In production, EventBridge and SNS handle automated triggers. Locally, `pipeline-service` routes the same HTTP surface directly to worker services sequentially. Developers never need AWS credentials or local emulators to run the full platform.

**Fargate Spot interruption is safe by design**
All workers are idempotent. SQS visibility timeout means an interrupted task's message becomes visible again automatically. Step Functions retries failed Map State items. No data is lost on interruption — the tracking table row remains in `in_progress` and resets to `pending` on timeout.
