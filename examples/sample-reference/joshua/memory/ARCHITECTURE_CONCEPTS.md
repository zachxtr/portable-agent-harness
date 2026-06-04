# Policy Command Architecture Concepts

Reference document for established patterns and design decisions used consistently across the stack.
Load this when working on storage, data pipelines, API design, or any cross-layer concern.

---

## Software architecture layers (Policy Command stack)

How the Policy Command monorepo is organized top to bottom. Use this when scoping work across UI, services, shared clients, and infrastructure.

```
┌─────────────────────────────────────────────────────────────┐
│                        APPLICATION LAYER                    │
│  User Interface & User Experience (UI/UX)                   │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                        SERVICES LAYER                       │
│  Microservices accessing clients, providing backend logic   │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTS LAYER                        │
│  Infrastructure as Code - default configs, connections,     │
│  dev-prod component switching                               │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    INFRASTRUCTURE LAYER                     │
│  Raw third-party tools: DB, object store, cloud services,   │
│  LLM APIs, auth components, etc.                            │
└─────────────────────────────────────────────────────────────┘
```

| Layer | Policy Command examples |
|-------|-------------------------|
| Application | `apps/web`, dashboard routes, chat UI, PDF viewer |
| Services | `packages/services/*` (rap-service, indexing-service, …) |
| Clients | `packages/shared/*-client`, storage abstractions, models |
| Infrastructure | PostgreSQL, S3, OpenSearch, Keycloak, Bedrock, ECS/Terraform |

---

## Resource Identifiers

### `billKey` — Universal Bill Identifier
**Format:** `{stateCode}/{session}/{billNumber}` — always lowercase state, numeric bill number (e.g. `fl/2026/6`)

**Session format:** year + optional special-session suffix — `2025`, `2025A`, `2025B`, `2025C`, `2024O`, etc.
The suffix is a letter identifying a special/extraordinary/organizational session within that year.
`sessionYear` parameters in key functions accept the full session string including any suffix.

**Key hierarchy:**
```
Session Key:  fl/2025                              → state + session
              fl/2025A                             → state + special session
Bill Key:     fl/2025/80                           → state + session + bill number
              fl/2025A/6                           → state + special session + bill number
Document Key: fl/2025/80/BillVersions/HB123.pdf   → billKey + docType + filename
```

**Document types** (RAG pipeline): `BillVersions | BillAmendments | BillAnalysis | BillVoteHistory`

Used as the authoritative key for a bill across every layer:
- **PostgreSQL DB**: `UNIQUE` column — primary lookup key (never use the `id` integer externally)
- **S3 bills bucket**: bill key IS the storage path prefix (`fl/2026/6/BillVersions/...`)
- **S3 agent workspace**: encoded in filenames as `fl-2026-6` (see **S3 Key Naming Conventions** — `encodeKey`)
- **OpenSearch / vectorDB**: document ID field
- **Frontend routing**: `/dashboard/bills/{stateCode}/{session}/{billNumber}`

**Single source of truth:** `packages/shared/models-db-client/src/schemas/billKeySchema.ts`

Key functions:
```typescript
generateBillKey(stateCode, sessionYear, billNumber)  // "FL", "2025A", "HB 80" → "fl/2025A/80"
parseBillKey(billKey)                                 // → { stateCode, sessionYear, billNumber } | null
parseBillKeyNumeric(billKey)                          // → { billNumber: number } — for DB inserts
generateSessionKey(stateCode, sessionYear)            // → "fl/2025A"
generateDocumentPath(billKey, documentType, filename) // → "fl/2025A/80/BillVersions/HB123.pdf"
normalizeBillNumber(billNumber)                       // "HB 80", "CS/SB 14" → "80", "14"
```

**`normalizeBillNumber`** strips leading alpha/slash prefixes automatically — always run incoming bill numbers through this. LLM output, user input, and filenames may carry prefixes like `HB`, `SB`, `CS/SB`.

---

### `statuteKey` — Universal Statute Identifier
**Format:** `{stateCode}/{year}/{chapter}.{section}` — always lowercase state (e.g. `fl/2025/316.083`)

Also has a chapter-level variant: `fl/2025/316` — used by hydration/RAG status tracking.

**Single source of truth:** `packages/shared/models-db-client/src/schemas/statuteKeySchema.ts`

Key functions:
```typescript
generateStatuteKey(stateCode, year, chapter, section)  // → "fl/2025/316.083"
generateStatuteChapterKey(stateCode, year, chapter)    // → "fl/2025/316"
parseStatuteKey(statuteKey)                            // → { stateCode, year, chapter, section } | null
parseStatuteChapterKey(chapterKey)                     // → { stateCode, year, chapter } | null
normalizeStatuteChapter(chapter)                       // "§316", "s. 316" → "316"
```

**Rule:** Never reference a statute by DB `id` externally. Always use `statuteKey`.

---

### `chatHistoryId` — Conversation Identifier
**Format:** `conv-{epochMs}-{shortToken}` (e.g. `conv-1778821251804-ujic330bg`)

Assigned at conversation creation. Used as the S3 folder name for the conversation and as the lookup key in saved-chats. Never changes for the lifetime of the conversation.

### `searchId` — Saved Search Identifier
**Format:** UUID assigned at save time. Stable key for update/delete without re-listing.

---

## Unversal S3 Record ID value - `recordKey` 

Every S3 object in the agent workspace has a filename that IS its unique record identity.
The filename encodes: **who** (user-scoped path), **when** (datetime prefix), and **what** (content key).

### Convention
Files are returned from `UserAgentWorkspaceClient.loadJsonFiles()` with a `recordKey` field injected — the S3 filename without the `.json` extension.

```
recordKey = filename without .json
  e.g.  20260515033446__fl-2025-27   (saved bill)
        20260515033446__bills__a1b2c3d4  (saved search)
        20260519204222__highlight__fvu06w  (annotation)
```

### Frontend DOM ID convention
For any library list item that needs a stable DOM id (scroll-back, highlight-on-return):

```
id = `${accountId}-${userId}-${recordKey}`
  e.g.  0-1-20260515033446__fl-2025-27
```

This is unique even in shared-library views where multiple users save the same bill/statute/chat.

### Why this matters
- Eliminates the legacy MongoDB `_id` field pattern entirely
- Uniform across all record types — no per-type special-casing
- Datetime prefix gives true uniqueness even for edge cases
- Human-readable for debugging in MinIO / logs

---

## S3 Key Naming Conventions

All agent workspace keys follow these rules, defined in `UserAgentWorkspaceLayout.ts`.

### Segment separator
`__` (double underscore) separates logical segments within a filename.

```
{dt}__{chatHistoryId}__{traceId}__tok{n}tok.json
```

### Datetime prefix
`YYYYMMDDHHMMSS` — 14-digit compact UTC timestamp. Enables lexicographic sort = chronological sort.

### Token count embedding (`tok{n}tok`)
Usage events (chat turns, brief runs) embed the token count in the filename:

```
20260519162500__conv-abc__trace-xyz__stripesub_1AbCstripe__tok4823tok.json
```

`tok{n}tok` is parsed by `UserAgentWorkspaceClient.getUsageEvents()` to compute usage dynamically without any stored aggregate. **Never use stored counters** — always derive from filename scan.

### Stripe subscription segment (`stripe{id}stripe`)
Every usage event filename (chat turn, brief) also embeds the active Stripe subscription / invoice ID:

```
{dt}__{chatHistoryId}__{traceId}__stripe{subId}stripe__tok{n}tok.json   ← chat turn
{dt}__{traceId}__stripe{subId}stripe__tok{n}tok.json                     ← brief
```

- For paid accounts: `subId` = Stripe Subscription ID (e.g. `sub_1Ab…`) or Invoice ID (e.g. `in_1Ab…`)
- For free accounts: `subId` = `free` (constant `STRIPE_FREE_ID` from `UserAgentWorkspaceLayout.ts`)

This allows `UserAgentWorkspaceClient.computeUsageByStripeId(accountId, userId, stripeId)` to count
turns and sum tokens for any subscription block by listing S3 keys and checking for `stripe{id}stripe` —
no JSON download, no DB counter needed. `UserAllotmentService` uses this for allotment checks.

### Key encoding (`encodeKey`)
When a natural key containing `/` is embedded in a filename, `/` is replaced with `-`:

```
billKey   fl/2026/6    →  fl-2026-6
statuteKey fl/732/103  →  fl-732-103
```

Defined as `encodeKey()` in `UserAgentWorkspaceLayout.ts`. Use it — do not hand-roll.

### Object path encoding (annotations + PdfViewer route)
Document paths used as S3 annotation folder names. **`encodeKey()` replaces `/` → `-` only** (match existing MinIO data; do not add space substitution without auditing folders).

```
fl/2026/6/BillVersions/S_6_Filed.pdf  →  fl-2026-6-BillVersions-S_6_Filed.pdf
```

**Web route:** `/dashboard/bills/:stateCode/:session/:billNumber/pdf/:docKey` where `docKey = encodeDocumentKey(documentPath)`. Build URLs via `apps/web/src/utils/documentKeys.ts` → `buildPdfViewerUrl()`. Optional query: `?page=N` only. PDF + annotations load from decoded path; bill detail fetched on mount.

---

## DB Deduplication for Scraped Data - `recordHash` 

**Format:** SHA-256 hex string of a record's key content fields (deterministic, sorted JSON).

Used exclusively in the **document-scraping pipeline** for upsert deduplication on DB tables that have no natural single-column unique key:

| Table | Key fields hashed |
|---|---|
| `BillVersion` | billKey, version, title, postedDate |
| `BillAmendment` | billKey, amendmentNumber, amendmentType, title, sponsor |
| `BillAnalysis` | billKey, analysisType, author, postedDate |
| `BillVoteHistory` | billKey, voteType, voteDate, committeeOrChamber, result |
| `BillHistory` | billKey, date, chamber, action |
| `BillCitation` | billKey, citation, details, locationInBill, citationType, page |
| `BillRelatedBills` | billKey, relatedBillNumber, relationship |
| `StatuteSection` | statuteKey, title |
| `StatuteReference` | statuteKey, referencedStatuteKey |

### Pattern
1. Scraper generates `recordHash` from the scraped content fields
2. DB has `UNIQUE` constraint on `recordHash` (e.g. `bill_version_record_hash_unique`)
3. Upsert: `INSERT ... ON CONFLICT (recordHash) DO UPDATE SET ...`

**Single source of truth:** `packages/shared/models-db-client/src/schemas/recordHash.ts`

Generator functions: `generateBillVersionRecordHash`, `generateStatuteSectionRecordHash`, etc.

All generators use the same internal pattern — `normalizeForHash()` applied to each field, then `JSON.stringify` with sorted keys, then `crypto.createHash('sha256')`.

**Rule:** `recordHash` is scraping-layer infrastructure — never expose it to the API or frontend. `billKey`/`statuteKey` are the external identifiers.

---

## Agent Workspace — Folder Structure

Per-user S3 namespace: `accounts/{accountId}/users/{userId}/`

```
agent-workspace.json        ← workspace manifest (name, avatar, setup status)
annotations/
  {objectPath-encoded}/     ← one folder per annotated document
    {dt}__{type}__{annotationId}.json
briefs/
  greeting/ | team/ | tracking/
    {YYYYMMDD}.md           ← cached brief output (overwritten daily)
    {dt}__{traceId}__stripe{id}stripe__tok{n}tok.json    ← usage record
chat-history/
  {chatHistoryId}/
    {chatHistoryId}.json    ← conversation summary (singleton)
    {dt}__{chatHistoryId}__{traceId}__stripe{id}stripe__tok{n}tok.json  ← turn record
    _deleted/               ← soft-delete: folder moved here, restore = move back
library/
  saved-bills/    {dt}__{billKey-encoded}.json
  saved-statutes/ {dt}__{statuteKey-encoded}.json
  saved-chats/    {dt}__{chatHistoryId}.json
  saved-searches/ {dt}__{sourcePage-slug}__{searchId}.json
navigation-history/
  {dt}__{sessionId}__{device}__{section}.txt  ← content = URL
  _archive-{YYYYMM}/        ← entries older than current month
policy-profiles/
  {uuid}.json
user-profile.json
```

Root platform namespaces (not per-user):
```
_system/agent-persona/      ← default persona template files (loaded at agent setup)
```

---

## System / Free Account - `accountId = 0`

In the dev and production environments, `accountId = 0` is a valid account used by system admins and free-tier users.

**Rule:** Never use falsy checks (`!accountId`, `!user?.accountId`) to guard on "user has an account". These checks fail silently for `accountId = 0`.

**Correct pattern:**
```typescript
// Wrong — breaks for accountId=0
if (!user?.accountId) return

// Correct — null/undefined check
if (user?.accountId == null) return

// Correct — explicit business rule (e.g. library sharing requires real account)
if (user?.accountId == null || user.accountId === 0) return
```

---

## Dynamic Usage Tracking

Token and turn usage is **never stored as an aggregate**. It is computed on-demand by:

1. Listing all keys under `accounts/{accountId}/users/{userId}/`
2. Parsing `tok{n}tok` from filenames of chat turns and brief usage records
3. Summing and grouping in `UserAgentWorkspaceClient.getUsageEvents()`

This means:
- No counter drift / race conditions
- Usage is always accurate to the last turn
- Subscription enforcement reads from the same scan

`UsageBlockSubscription.turnsUsed` / `tokensUsed` fields on the DB model are **deprecated** — they are no longer maintained and will be removed once the dynamic path is fully exercised everywhere.

---

## Key Builder Functions

All S3 key construction lives in `UserAgentWorkspaceLayout.ts` (`packages/shared/storage-client/src/`).
**Never construct S3 keys inline in service or controller code.** Always use the exported helpers.

Notable functions:
| Function | Output example |
|---|---|
| `savedBillKey(accountId, userId, dt, billKey)` | `accounts/0/users/1/library/saved-bills/20260515__fl-2025-27.json` |
| `annotationKey(accountId, userId, objectPath, dt, type, annotationId)` | `.../annotations/fl-2026-6-S_6_Filed.pdf/20260519__highlight__fvu06w.json` |
| `navEntryKey(accountId, userId, dt, sessionId, device, section)` | `.../navigation-history/20260519__session123__desktop__Bills.txt` |
| `userProfileKey(accountId, userId)` | `accounts/0/users/1/user-profile.json` |
| `encodeKey(key)` | `fl/2026/6` → `fl-2026-6` |
| `dateCompact(date)` | `Date` → `YYYYMMDDHHMMSS` string |

---

## Tags

Short string labels (e.g. `"Priority"`, `"Watch"`, `"Oppose"`) that a user applies to saved library items and PDF annotations. Conceptually the same — "I want to mark this for follow-up" — stored differently depending on the surface.

**Display convention:** Tags render with a `#` prefix everywhere in the UI (e.g. `#Priority`, `#Bob`) following the social media convention — instant recognition as a label. The `#` is purely presentational; raw strings are stored and filtered without it. This pairs with the `@handle` convention on Policy Profiles: `@` = identity, `#` = label.

**User-managed tag list:** Configured in Quick Actions (`/dashboard/profile/quick-actions`). Stored as `UserProfileDocument.tags?: string[]` in `user-profile.json` (S3). Served by `GET/PUT/DELETE /accounts/:accountId/users/:userId/chat-tags` (`UserDataController`). Defaults to `DEFAULT_CHAT_TAGS = ['Priority', 'Watch', 'Follow Up', 'Research']` when no custom list is set (`user-profile.ts`). Max 25 chars per tag (`CHAT_TAG_MAX_LENGTH`).

**On saved items (bills, statutes, chats, searches):** `tags?: string[]` on each record. Applied via save modals (`SaveChatModal`, `SaveBillModal`, etc.) which pre-populate one-click chips from the user's quick tag list.

**On PDF annotations:** One of four annotation types — `highlight | note | drawing | tag` (`AnnotationRecord.type`, `coreApi.ts`). Stored as `{dt}__tag__{id}.json` under `annotations/` in S3. Surfaces in `TeamActivity` as an annotation count badge.

**Filtering — AND logic, case-insensitive, consistent everywhere:**
```typescript
selectedTags.every(selectedTag =>
  itemTags.map(t => t.toLowerCase()).includes(selectedTag.toLowerCase())
)
```
Applied in every library sub-page (`SavedBills`, `SavedChats`, `SavedStatutes`, `SavedSearches`, `AnnotatedDocuments`) and the unified library index via `useLibraryFiltersStore`.

**Team coordination:** `TeamActivity.tsx` shows the tags of saved library items in a sortable column. This makes tags a lightweight async communication tool — a user can tag a set of items `"special report"` or `"Review This"` and tell a teammate to sort or filter Team Activity by that tag — the team agrees on conventions informally, which keeps the system flexible.

---

## Chat vs Policy Assistant (UI Icons)

Product distinction — not a storage or API rule, but it shapes web components and session stores.

**Chat** is the product surface: legislative Q&A, team threads, library saves. **Navigation to Chat always uses the sparkles icon** (e.g. sidebar **Chat**, page title, mobile sheet header on Bills/Statutes/Library → **New Chat**). Sparkles mean “open the chat app,” not “show my PA’s face.”

**Policy Assistant** is modeled like **another user in the account** for display: name + avatar on status cards, not on global nav. Use `AssistantAvatar` (reads `assistantWorkspaceStore.personaSummary.avatar`; sparkles only when no avatar is set). Surfaces:

- `AssistantActionBar` — Chat: inline below composer; mobile sheet panel 1 (swipe right) embeds ActionBar + Inbox + Focus panels; Briefs; Assistant Profile
- `AssistantModals` — portaled Focus / Inbox dialogs via `useAssistantModals()` (replaces tabbed `AssistantPanelContext`)
- User menu **Assistant Settings** link → `/dashboard/profile/assistant/edit` — static **Assistant Settings** label and `SparklesIcon` (not persona avatar; PA identity lives in `AssistantActionBar`, not global nav)
- **First-time setup:** **Set up Assistant** → `/dashboard/profile/assistant/create` — stepped wizard (AccountCreate pattern); `/profile/assistant/setup` redirects to create. On success → Assistant Edit **Memories** tab.
- Chat `MobileActionSheet` **only** — second panel / “{name} ›” header (persona, not “Ask …”)

**Mobile action sheet** (all pages, two panels):

| Panel | Content |
| --- | --- |
| 0 — Page | Page sidebar (actions, filters, chat history, etc.) |
| 1 — Assistant | `AssistantActionBar` + embedded `AssistantInboxPanel` + `AssistantFocusPanel` |

Focus / Inbox nav pills also open portaled modals (`AssistantModals`). Chat adds an inline `AssistantActionBar` below the composer for quick access without opening the sheet.

**Session caches (browser, per logged-in user):**

| Store | Holds |
| --- | --- |
| `assistantWorkspaceStore` | Workspace manifest, PA `personaSummary` (name, avatar), session refresh, proposal count stub |
| `accountTeamStore` | Account users for names/SSO flags — fed into `AccountUserAvatar` |

**Avatar components:**

| Component | Use for |
| --- | --- |
| `UserAvatar` | Low-level: workspace image via `userId` + `accountId` (+ SSO URL when applicable) |
| `AccountUserAvatar` | Humans everywhere (library rows, chat history, team UI) |
| `AssistantAvatar` | PA persona only — never for Chat nav or menu |

---

## Navigation context (breadcrumbs & scroll restore)

Session stack in `navigationContextStore` — `pushContext` before navigating away from a list; on return, match `target.url`, `popContext()`, scroll/highlight `row-{scrollTarget}` where `scrollTarget` equals the table `getRowKey()` value.

Used on token usage history, library pages, bill/statute detail, navigation history, etc.

---

## Token usage (terminology)

User-facing billing label is **Token** / **Token usage** (not “chat usage” or “agent usage”). **Chat** remains the product nav surface (see **Chat vs Policy Assistant** above).

| UI / API | Name |
| --- | --- |
| Profile route | `/dashboard/profile/token-usage` → `TokenUsageHistory` |
| Admin route | `/dashboard/admin/users/:userId/token-usage` → `UserTokenHistory` |
| Events endpoint | `GET .../token-usage` |
| Login / subscription blob | `periodUsage` (counts + limits + period dates) |
| Stripe sub IDs on login | `subscriptionIds` |
| Overview prop (web) | `currentPeriodUsage` |
| Sidebar period picker label | **Usage Period** (`viewingPeriod` internally) |

Storage paths (`chat-history/`, `UsageEvent.area`) are unchanged — not user-facing.

---

## PA Agent Harness

Full design: `memory/POLICY_ASSISTANT_AGENT_HARNESS.md` — canonical harness reference (implementation status table at top).

---

## Bill Tracking Log

Append-only audit trail in PostgreSQL (`BillTrackingLog` table). Written by FL bill scrapers in `document-scraping-service` via `insertBillTrackingLog()`. Each row records one discrete change to a bill — new session listing, new history entry, new version, etc.

**Purpose:** power the user Bill Tracking activity feed (core-service) and the admin sync log UI (document-scraping-service). Not sync state — that lives in `RealtimeSyncSettings` / `SessionBillTracking`.

**Idempotency:** log only when the underlying DB insert returns `isNew === true`. Re-scrapes and verification passes must not duplicate rows.

**User visibility:** `isUserDisplay = true` rows appear on the Bill Tracking page and per-bill log modal. Admin Realtime page shows all types.

**Document storage:** PDF uploads call `publishDocumentEvent()` for indexing. PDF paths are recorded on granular types (`bill-versions`, `bill-amendment`, etc.) via `objectPath` — not as separate log types.

### Per-type map (FL bill scrapers)

| Type | Scraper | When logged | User display | Notes |
| --- | --- | --- | --- | --- |
| `new-bill` | `SessionScraper` | First insert into `SessionBillTracking` (`isNew`) | No | Session list discovery — audit only |
| `bill-overview` | `BillScraper` | First insert into `Bills` (`isNew`) | No | Audit only; user sees substantive changes via `bill-history` (dated) |
| `bill-history` | `BillHistoryScraper` | New `BillHistory` row (`isNew`) | Yes | Chamber + action; `date` = history date |
| `bill-versions` | `BillVersionScraper` | New `BillVersions` row (`isNew`) | Yes | Version label; `date` = posted date; `objectPath` = PDF |
| `bill-amendment` | `BillAmendmentScraper` | New `BillAmendments` row (`isNew`) | Yes | Type, title, sponsor; `objectPath` = PDF |
| `bill-analysis` | `BillAnalysisScraper` | New `BillAnalyses` row (`isNew`) | Yes | Type, author, analysis; `objectPath` = PDF |
| `bill-votes` | `BillVoteHistoryScraper` | New `BillVoteHistory` row (`isNew`) | Yes | Vote type + result; `objectPath` = PDF |
| `bill-citations` | `BillCitationScraper` | New `BillCitations` row (`isNew`) | Yes | Citation type, text, details |
| `bill-related-bills` | `BillRelatedBillScraper` | New `BillRelatedBills` row (`isNew`) | Yes | Relationship, related bill #, subject |

### API surfaces

| Consumer | Endpoint | Filter |
| --- | --- | --- |
| User Bill Tracking page | `GET /bills/:state/bill-tracking/activity` | `isUserDisplay = true` |
| Per-bill modal | `POST /bills/:state/bill-tracking/activity/filter` | `isUserDisplay = true` + `billKeys` |
| Admin Realtime page | `GET /bill-tracking/:state/:session/logs` | All entries for session |

Model: `packages/shared/models-db-client/src/models/BillTrackingLog.ts`