# Architecture Concepts

Reference document for established patterns and design decisions used consistently across the stack.
Load this when working on storage, data pipelines, API design, or any cross-layer concern.

---

## Software architecture layers (MCI stack)

How the monorepo is organized top to bottom. Use this when scoping work across UI, services, shared clients, and infrastructure.

```
┌─────────────────────────────────────────────────────────────┐
│                        APPLICATION LAYER                    │
│  User Interface & User Experience (UI/UX)                   │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                        SERVICES LAYER                       │
│  HTTP controllers, tool executors, and *business-logic*     │
│  services (LLM pipeline, billing, provisioning, …)         │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTS LAYER                        │
│  Infrastructure as Code default configs, connections,       │
│  dev-prod component switching and simple direct CRUD        │
│  level data access — like stored procedures insert queries  │
│  @mci/storage-client · @mci/models-db-client                │       
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    INFRASTRUCTURE LAYER                     │
│  Raw third-party tools: PostgreSQL, S3, OpenSearch,         │
│  Keycloak, Bedrock, etc.                                    │
└─────────────────────────────────────────────────────────────┘
```

| Layer | MCI examples |
|-------|----------------|
| Application | `apps/web`, dashboard routes, chat UI, book reader |
| Services | `packages/services/*` — **core-service** (mostly CRUD controllers), **rap-service** (controllers + business-logic services) |
| Clients | `packages/shared/*-client` — see `packages/shared/README.md` |
| Infrastructure | PostgreSQL, MinIO/S3, OpenSearch, Keycloak, Bedrock |

---

## Clients layer responsibilities

The Clients layer (diagram above) does **two jobs**:

1. **Infrastructure wiring** — config injection, connections, dev↔prod switching (`StorageClient`, `DatabaseClient`, `auth-client`, `ai-client`, `vector-client`, …). See `packages/shared/README.md`.
2. **Domain data access** — list/get/create/update/delete in shared packages (stored-procedure style): `WorkspaceClients` + domain clients, Sequelize models, domain `*DatabaseManager` helpers.

---

## Request path — Managers yes, CRUD Services no

**Principle:** Persistence logic lives in shared client packages. Controllers call **Managers** or **domain clients** injected at startup — not raw SDKs. Do **not** add a `src/services/*Service.ts` that only forwards CRUD when there is no business logic.

```
Bootstrap (index.ts):
  StorageManager / DatabaseConnection
    → WorkspaceClients, UserDatabaseManager, …

CRUD HTTP request (core-service shape):
  Controller  →  workspace.listAdventures()     // domain client from StorageManager
              →  userDb.getUserById()           // domain DB manager
              →  storageManager.getDocument()   // when catalog bucket needed
  (no AdventureService in between)

Business-logic request (rap-service shape):
  Controller  →  AssistantOrchestrator.runTurn()
              →  GenerateService / PrepareService / …
```

| Service | `src/services/` | Why |
|---------|-----------------|-----|
| **core-service** | ~1 file (`RollingMemoryWriter`) | Mostly CRUD — controllers → managers/clients directly |
| **rap-service** | ~50+ files | LLM pipeline, Agent orchestration, retrieval, validation |

| Store | Client package | CRUD / query home | Service-side access |
|-------|----------------|-------------------|---------------------|
| User workspace (S3) | `@mci/storage-client` | `WorkspaceClients` + domain clients + `src/types/` | `StorageManager` → agents bucket → `workspace` |
| Platform (PostgreSQL) | `@mci/models-db-client` | Sequelize models + `DatabaseClient` | `DatabaseConnection` → `UserDatabaseManager`, `SubscriptionDatabaseManager`, … |

**When to add a `src/services/*Service.ts`:** multi-step orchestration, LLM pipeline, external APIs (Stripe webhooks, Keycloak sync), provisioning, or cross-store rules.

**When not to:** list/get/create/update/delete that maps 1:1 to a client or manager method — keep it in the controller (core-service pattern).

**Managers vs Services:** `StorageManager`, `DatabaseManager`, `UserDatabaseManager` wire infra and expose domain access — **keep them**. A separate `AdventureService` that only calls `workspace.getAdventure()` — **don't add it**.

See `packages/shared/storage-client/README.md` § *Client layer* and *Shared domain API* for workspace parity (UI ↔ agent).

---

## Resource Identifiers

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
Files are returned from `WorkspaceClientBase.loadJsonFiles()` with a `recordKey` field injected — the S3 filename without the `.json` extension.

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
- Uniform across all record types — no per-type special-casing
- Datetime prefix gives true uniqueness even for edge cases
- Human-readable for debugging in MinIO / logs

---

## S3 Key Naming Conventions

All agent workspace keys follow these rules, defined in `layout/`.

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
- For free accounts: `subId` = `free` (constant `STRIPE_FREE_ID` from `layout/`)

This allows `UserAgentWorkspaceClient.computeUsageByStripeId(accountId, userId, stripeId)` to count
turns and sum tokens for any subscription block by listing S3 keys and checking for `stripe{id}stripe` —
no JSON download, no DB counter needed. `UserAllotmentService` uses this for allotment checks.

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
  {chatHistoryId}__{dt}.json    ← conversation summary (root)
  {chatHistoryId}/              ← turn records, logs, NOTES.md
    {dt}__{chatHistoryId}__{traceId}__stripe{id}stripe__tok{n}tok.json
  _deleted/                     ← soft-deleted summary + artifact folder mirror
quest-history/
  {questHistoryId}__{adventureUuid}__{dt}.json   ← quest session summary (root)
  {questHistoryId}/             ← objective answers, session logs
adventures/
  {uuid}/adventure.json         ← public | _private/{uuid} | _deleted/{uuid}
library/
  saved-books/    {dt}__{bookKey-encoded}.json
  saved-chats/    {dt}__{chatHistoryId}.json
inbox/                          ← assistant inbox messages
agent-profiles/{agentId}/       ← assistant agent persona + config (UI: Companion)
user-profile/                   ← USER.md, profile JSON, avatar
navigation-history/
  {dt}__{sessionId}__{device}__{section}.txt
  _archive-{YYYYMM}/
```

Root platform namespaces (not per-user):
```
_system/agent-persona/      ← default persona template files (loaded at agent setup)
```

---

## System / Free Account - `accountId = 0`

In dev and production, users with **`Users.accountId = null`** in PostgreSQL (no billing tenant) map to **workspace account `0`** for mci-agents paths (`accounts/0/users/{userId}/…`) and API responses. The DB value stays `null`; only billing/usage code treats them as **system-free**.

**Rule:** Never use falsy checks (`!accountId`, `!user?.accountId`) to guard workspace features — they fail silently for `accountId = 0`.

**Correct pattern:**
```typescript
// Wrong — breaks for accountId=0
if (!user?.accountId) return

// Correct — null/undefined only (unauthenticated / not synced)
if (user?.accountId == null) return

// Correct — billing tier only (not sharing, library, chat, etc.)
if (getAccountType(user.accountId) === 'system-free') { /* skip Stripe/subscription */ }
```

**Teammate roster:** `getUsersByAccountId(0)` includes users where `accountId IS NULL` or `accountId = 0` — same pseudo-tenant.

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

All S3 key construction lives in `layout/` (`packages/shared/storage-client/src/`).
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

## Navigation context (breadcrumbs & scroll restore)

Session stack in `navigationContextStore` — `pushContext` before navigating away from a list; on return, match `target.url`, `popContext()`, scroll/highlight `row-{scrollTarget}` where `scrollTarget` equals the table `getRowKey()` value.

Used on token usage history, library pages, bill/statute detail, navigation history, etc.

---

## Token usage (terminology)

User-facing billing label is **Token** / **Token usage** (not “chat usage” or “agent usage”). **Chat** remains the product nav surface (see **Chat vs Agent** above).

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

## Agent harness (orchestrator)

The user-facing **Agent** orchestrates each chat turn: INTERPRET → worker dispatch (optional) → ALIGN. Persona, inbox, and chat-history keys live under each user's workspace in the agents bucket.

| Topic | Location |
| --- | --- |
| Turn pipeline & phases | `packages/services/rap-service/README.md` |
| S3 key builders (persona, chat-history, library, …) | `packages/shared/storage-client/src/layout/` |
| Agent types & handoff contracts | `packages/services/rap-service/src/types/assistant.ts` |
| Skill knobs & routing | `.agents/joshua/memory/SKILL_VARIABLES.md` |
