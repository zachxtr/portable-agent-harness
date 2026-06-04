# SKILL.md Variable Map

Reference for every **SKILL.md** knob — what it controls and where it fires in the worker pipeline (`PREPARE → ASSEMBLE → GENERATE → VALIDATE`). Documents **semantics and defaults in code**; per-skill **values** live in the skill files below (not duplicated here).

**Live templates (edit these):**

| Skill | Path |
|---|---|
| `policy-command-legislative-review` | `packages/services/rap-service/src/agent-templates/_system/skills/policy-command-legislative-review/SKILL.md` |
| `policy-command-legislative-analysis` | `packages/services/rap-service/src/agent-templates/_system/skills/policy-command-legislative-analysis/SKILL.md` |
| `policy-command-legislative-search` | `packages/services/rap-service/src/agent-templates/_system/skills/policy-command-legislative-search/SKILL.md` |

**Runtime load path:** agents bucket `_system/skills/{skill-name}/SKILL.md` (synced from templates on each rap-service start). After editing a template, restart rap-service to bust the in-process skill cache.

Update **this doc** when `WorkerSkillLoader`, phase services, or platform key semantics change. Update **SKILL.md** when tuning retrieval boosts, discovery floor, thresholds, or model settings.

---

## File structure

Every skill is a folder. Two zones in `SKILL.md`:

```yaml
---
name: policy-command-legislative-review
description: "…"                    ← PA INTERPRET routing (skill catalog)
license: …
compatibility: …
allowed-tools: tool_a tool_b         ← top-level; space-separated; not inside platform:
platform:
  response_mode: direct              ← master switch for the full pipeline flow
  model: …
  …
---

## Description                        ← human summary (not injected into worker LLM)
## Instructions                       ← worker system prompt (with token substitution)
## Gotchas
## Examples                           ← usually points to references/few-shot.yaml
```

**Skill directory (agentskills.io layout):**

```
_system/skills/{skill-name}/
├── SKILL.md                 Required
├── references/
│   ├── few-shot.yaml        Optional — PREPARE appends up to 3 examples to system prompt
│   └── …                    Optional reference docs
├── scripts/                 Optional
├── assets/                  Optional
└── evals/                   Optional
```

---

## Pipeline flow

The pipeline has two distinct responsibilities:

**PA INTERPRET** picks *which skill* handles the turn — based on user intent, context, and the skill's `description`.  
**The skill's `response_mode`** then determines *how the worker agent pipeline executes* — which phases run, what each phase does, and whether the LLM is called at all.

This separation is intentional: PA owns routing; the skill owns execution behavior. The worker agent pipeline is generic — `response_mode` is what makes each skill use it differently.

```
PA INTERPRET   picks the skill (description-based routing, or UI override)
    │
    │  ← skill boundary: everything below is driven by this skill's response_mode
    ↓
PREPARE        loads SKILL.md → WorkerExecutionPlan
               response_mode is the master switch for all downstream phases
               P.1 gate: requires_context_key and no key in context → stop here
    ↓
ASSEMBLE       response_mode determines what evidence is loaded
               discover  → hybrid search → bill inventory (up to 20 bills)
               direct    → hybrid search → chunks (two-pass rerank)
               agentic   → metadata grounding only (tools retrieve the rest)
               A.2 gate: no evidence and no tools → skip GENERATE
    ↓
GENERATE       response_mode determines how the LLM is called
               discover  → one summarize LLM call (JSON per row); template fallback on failure
               direct    → single LLM call on prefetched chunks
               agentic   → LLM + tool loop (max_calls iterations)
    ↓
VALIDATE       confidence_threshold — same for all modes
```

Gate codes are log labels in `types/worker.ts`.

---

## Zone 1A — Routing fields (PA INTERPRET)

| Field | Role | Tuning |
|---|---|---|
| `name:` | Skill ID; must match folder name and PA JSON output | Fixed per skill |
| `description:` | Catalog line for INTERPRET | **Primary routing lever** — trigger phrases, use cases, NOT-fors |
| `license:` | agentskills.io license field | Informational |
| `compatibility:` | Platform dependency declaration | Required when using PolicyCommand-native tools |

---

## Zone 1B — Platform block (`platform:`)

Parsed by `WorkerSkillLoader` → `PrepareService` → `WorkerExecutionPlan` (`assemble`, `generate`, `validate`).

Every key is **parsed once in PREPARE** and then **consumed in the phase shown below**. PREPARE stores values in the plan — it does not act on them directly.

### `response_mode` — the master switch

`response_mode` is the single key that controls the **full pipeline flow**: what ASSEMBLE loads, whether GENERATE runs, and how the LLM is called. Everything else in `platform:` is conditional on it.

| `response_mode` | ASSEMBLE loads | GENERATE does | LLM called? |
|---|---|---|---|
| `discover` | Bill inventory (hybrid search → dedupe → cap-20) | Summarize LLM → platform stitches inventory markdown | Yes — always (template fallback on failure) |
| `direct` | Chunks (hybrid search, two-pass rerank, up to 12) | Single LLM call on prefetched evidence | Yes — always |
| `agentic` | Metadata grounding (bill/statute record) | LLM + tool loop | Yes — always |

---

### Discover mode — assembly and output

**PA → worker inputs (discover path)**

| Input | Source | Role |
|---|---|---|
| `displayQuery` / `ctx.question` | PA INTERPRET rewrite | GENERATE + discover italic line — **not** sent to OpenSearch |
| `retrievalQuery` | PREPARE: `topics[]` joined (+ abbrev expand) | Hybrid primary query; bill discover adds **full PA as RRF variant** |
| `rerankQuery` | PREPARE: full PA (bills) or framing-stripped PA (statutes) | Cohere rerank — bill discover runs **before** bill-level dedupe |
| `topics[]` | PA INTERPRET | Hybrid keywords + topic gate tokens |
| `questionRaw` | User message | Logging only |
| `workingSession`, `defaultStatuteYear` | Working context | Bill session and statute year scope |
| `activeFocus` | PA INTERPRET (+ `normalizeInterpretActiveFocus`) | `bill` \| `statute` \| **omit** = dual corpus (bills + statutes). Generic "legislation/laws" on raw message must **not** set `bill`. |

Worker log: `Bill inventory (pre-floor ranked)` lists all candidates with `[returned]` / `[dropped]` / `[capped]` before the returned inventory block.

Session/year resolution and inventory caps: `services/assemble/discoveryInventory.ts`, `services/RetrievalService.ts`, `workers/sessionScope.ts`.

**User-facing row format (platform-owned, not LLM)**

Built by `formatBillHeader` / `formatStatuteHeader` + `DiscoveryFormatter.formatItemBlock`:

- Intro: separate italic line with PA rewrite (`*…*`), not raw user text
- Bill item: `**{billNumber}: {title}** · *filed by {sponsor}*. {summary} [CITE: N]`
- Statute item: `**§ {section}: {title}**. {summary} [CITE: N]`

A **Summarize LLM call** uses the source chunks and item title to provide 1-3 sentence summary of the found item to include in the response.

**Tuning workflow:** Edit search `SKILL.md`; restart rap-service; run a query; read worker log `=== DISCOVERY ===` → `Score floor (tuning)`.

---

### Platform keys

| YAML Key | Default | Category | What it controls | Active for `response_mode` |
|---|---|---|---|---|
| `response_mode` | — (required) | **Master switch** | Full pipeline flow — drives ASSEMBLE + GENERATE behavior | N/A |
| `requires_context_key` | `false` | **Gate** | P.1 — stops the turn immediately if no bill or statute key is in context | N/A |
| `retrieval_keyword_weight` | `0.3` | **Retrieval** | OpenSearch **boost** on the BM25 (`multi_match`) clause in hybrid search | all |
| `retrieval_vector_weight` | `0.7` | **Retrieval** | OpenSearch **boost** on the kNN vector clause | all |
| `expand_query_variants` | `false` | **Retrieval** | LLM generates 2 rephrased queries; all 3 run in parallel and merge via RRF. Boosts recall — also amplifies noise on broad queries. | all |
| `rerank_mode` | from `response_mode`† | **Retrieval** | Cohere rerank pass on prefetched chunks: `none` \| `single` \| `two-pass`. Default: `direct` → `two-pass`; `discover` + `agentic` → `none`. Override only when tuning retrieval quality. | `direct`; optional others |
| `discovery_min_relevance_score` | — (no floor) | **Retrieval** | Bill-level score floor before cap-20. Omit for no filter. Calibrate using worker log `Score floor (tuning)` (`candidatesBeforeFilter`, `highestDroppedScore`, `lowestReturnedScore`). | `discover` |
| `max_chunks` | `12` | **Retrieval** | Chunk count for hybrid prefetch | `direct` |
| `model` | `BEDROCK_MODEL_ID` | **LLM** | Bedrock model ID for LLM calls | all |
| `temperature` | `0.2` | **LLM** | LLM sampling temperature | all |
| `max_tokens` | `8192` | **LLM** | Max completion tokens per LLM call | all` |
| `context_window` | `32768` | **LLM** | Context budget — mainly controls tool payload sizing | `agentic`; `direct` sizing |
| `max_calls` | `5` | **Tools** | Max tool-loop iterations before forcing synthesis | `agentic` only — parsed for other modes but unused on turn 1 |
| `max_parallel_tools` | `5` | **Tools** | Tool calls executed in parallel per iteration | `agentic` only — parsed for other modes but unused on turn 1 |
| `confidence_threshold` | `0.65` | **Gate** | Minimum confidence score — below this the answer is flagged low-confidence | all |

† `rerank_mode` default per `response_mode`: `direct` → `two-pass`; `discover` → `none` (discovery inventory reranks internally); `agentic` → `none`. At runtime, `direct` downgrades `two-pass` → `single` when no bill/statute key is in context (`AssembleService`).

**Hybrid boosts:** `retrieval_keyword_weight` and `retrieval_vector_weight` are relative OpenSearch boost values on two `bool.should` clauses (BM25 + kNN), not percentages that must sum to 1. Higher keyword boost favors literal term matches; higher vector boost favors semantic similarity. Statues have additaional platform levers built in to manage the much broader dataset (30,000+ statute sections...)

Session and index scoping (OpenSearch index, `fl/{session}/` prefix) is resolved in code (`workers/sessionScope.ts`).

---

## Zone 1C — Tool allowlist (`allowed-tools:`)

Space-separated, top-level. Each name must be in `PLATFORM_TOOLS` or the skill fails validation.

| Tool | Use |
|---|---|
| `search_bill_documents` | Bill text search — focused with `billKey`, or session-scoped corpus |
| `search_statute_documents` | Statute text search — focused or corpus-wide |
| `get_bill_metadata` | Structured bill metadata |
| `get_statute_metadata` | Structured statute metadata |
| `get_bills_by_criteria` | DB query: sponsor, chamber, session, citation — not open topic search |
| `get_statutes_by_criteria` | DB query: chapter, year, keyword; `citedBy` |
| `list_bill_documents` | Document list for a billKey |
| `web_search` | External web (restricted skills) |

---

## Zone 2 — Markdown body

| Section | Pipeline role |
|---|---|
| `## Description` | Documentation; not sent to worker LLM |
| `## Instructions` | Worker system prompt → `plan.systemPrompt` |
| `## Gotchas` | Included in prompt assembly |
| `## Examples` | Pointer to `references/few-shot.yaml` |

**Dynamic tokens** (substituted in `## Instructions` by PREPARE):

| Token | Source |
|---|---|
| `{{USER_NAME}}` | `WorkingContext.userName` |
| `{{BILL_KEY}}` | First bill key in scope |
| `{{STATUTE_KEY}}` | First statute key in scope |
| `{{WORKING_SESSION}}` | Focus session slug (e.g. `2026`, `2026E`) |
| `{{ACTIVE_FOCUS}}` | PA `activeFocus` hint merged with keys in PREPARE (`bill` \| `statute`; empty = both) |

---

## Platform defaults (external skills without `platform:`)

External or guide skills without a `platform:` block receive these at parse time:

| Field | Default |
|---|---|
| `model` | `BEDROCK_MODEL_ID` / `qwen.qwen3-32b-v1:0` |
| `context_window` | `32768` |
| `temperature` | `0.2` |
| `max_tokens` | `8192` |
| `response_mode` | `agentic` | Master switch when `platform:` block omitted |
| `rerank_mode` | from `response_mode`† | `direct` → `two-pass`; `discover` / `agentic` → `none` |
| `max_chunks` | from `response_mode` | `direct` → `12`; `discover` / `agentic` → `0` |
| `confidence_threshold` | `0.65` | |
| `retrieval_vector_weight` / `retrieval_keyword_weight` | `0.7` / `0.3` (kNN / BM25 boosts) |
| `expand_query_variants` | `false` |
| `requires_context_key` | `false` |
| `max_calls` / `max_parallel_tools` | `5` / `5` |

Unknown tool names in `allowed-tools` are rejected by `validateExternalSkill()`.

---

## Base skills

Read each skill's `platform:` block in its **SKILL.md** (paths above) for current boosts, floors, model, and thresholds — those files are the source of truth.

| Skill | Turn 1 ASSEMBLE | Turn 1 GENERATE |
|---|---|---|
| `policy-command-legislative-review` | metadata + hybrid chunks (rerank per plan) | direct LLM on chunks |
| `policy-command-legislative-analysis` | metadata grounding | agentic tool loop |
| `policy-command-legislative-search` | discovery inventory per `activeFocus` | summarize LLM + platform layout (template fallback on failure) |

**Tuning discover mode:** edit `policy-command-legislative-search/SKILL.md`; validate with worker log `Score floor (tuning)`. Discovery quality is knob-driven — not hardcoded topic logic in `discoveryInventory.ts`.

---

## Three-skill routing (PA)

| Skill | Route when |
|---|---|
| `legislative-review` | Bill/statute in focus; read-out of known document |
| `legislative-analysis` | Tools, reasoning, cross-doc, fiscal, citations, version diffs |
| `legislative-search` | Topic discovery — "find bills about X"; no focused key |

Priority: **review** (single-doc read-out) → **analysis** (depth/tools) → **search** (corpus discovery).

---
