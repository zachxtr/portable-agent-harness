---
created: 2026-07-11
updated: 2026-07-11
status: complete
---

# WIP — Rolling memory → domain client

**Scope:** `packages/shared/storage-client/` + thin service migration in core-service / rap-service  
**Related:** `memory/.archive/wip_storage-client-crud.md` · `storage-client/README.md` § Domain map  
**Out of scope:** Agent tool for rolling memory (N/A — internal index, not user-facing list/get)

---

## Status

| | |
|--|--|
| **Phase** | **complete** — RM-1 ✅ · RM-2 ✅ |
| **Next** | *(archived)* · optional RM-3 chat-meta helper split noted below |

---

## Decision (locked for this proposal)

Rolling memory is a **domain entity**, not a package subfolder.

| Layer | File | Role |
|-------|------|------|
| **Types** | `src/types/rolling-memory.ts` | Already exists — `RollingCard`, frontmatter, upsert params |
| **Layout** | `src/layout/rolling-memory.ts` | **Keys + format constants only** (no I/O, no parse loops) |
| **Client** | `src/clients/RollingMemoryClient.ts` | **S3 CRUD + document integrity** on `persona/ROLLINGMEMORY.md` |
| **Bootstrap** | `WorkspaceClients.rollingMemory` | Same pattern as `ChatHistoryClient`, `InboxClient`, … |

**No** `rolling-memory/` directory under `src/`.  
**No** `rollingMemoryIndex.ts` / `rollingMemoryPersist.ts` at package root after migration.

---

## Layout vs client split

### `layout/rolling-memory.ts` (new)

Pure path + constants — same contract as other `layout/*` modules:

```ts
// Path (file lives under persona/ but is its own domain)
export function rollingMemoryDocKey(accountId, userId): string

// Back-compat alias during migration (then remove)
export const assistantRollingMemoryKey = rollingMemoryDocKey

// System template (agents bucket _system/)
export function systemRollingMemoryTemplateKey(): string  // '_system/agent-persona/ROLLINGMEMORY.md'

// Format constants used by client + services when building cards
export const ROLLING_SCHEMA_V1, CHATS_SECTION, SHARE_SETTINGS_SECTION, …
export const DEFAULT_MAX_BODY_CHARS, ROLLING_META_LAST_TOUCHED
```

`layout/persona.ts` keeps the persona tree comment; **canonical rolling-memory key moves to `layout/rolling-memory.ts`**. Re-export from `persona.ts` optional for one release.

### `clients/RollingMemoryClient.ts` (new)

Extends `WorkspaceClientBase`. Uses `StorageClient` directly (drop `RollingMemoryStorage` adapter).

**Public API — structural CRUD only:**

| Method | What it does |
|--------|----------------|
| `read(accountId, userId)` | Download + parse → `{ frontmatter, body }` |
| `write(accountId, userId, doc)` | Serialize + upload full document |
| `upsertCard(accountId, userId, params, templateBody?)` | Merge card, trim body, reconcile frontmatter, persist |
| `removeCard(accountId, userId, cardType, cardId)` | Remove one card (e.g. chat on soft-delete) |
| `replaceShareSettingsCards(accountId, userId, cards, templateBody?)` | Rewrite `## Share settings` section only |
| `syncOnLogin(accountId, userId, templateBody)` | Intro + section skeleton reconcile (uses template) |

**Private / module-level** (same file, below class — not a separate folder):

- `parseRollingMemoryDocument` / `serializeRollingMemoryDocument`
- `parseAllRollingCards`, `recomposeRollingBody`, `upsertCardInBody`, `trimRollingBody`
- `reconcileRollingFrontmatter`, `syncRollingMemoryOnLogin`, …

**Selective re-exports** from package root for callers that parse without I/O (maintenance/review flows):

```ts
export { parseRollingMemoryDocument, parseAllRollingCards, … } from './clients/RollingMemoryClient';
```

Or export from `clients/index.ts` — same as other domains.

---

## What moves UP to services (not storage-client)

Orchestration stays in rap-service / core-service:

| Responsibility | Today | After |
|----------------|-------|-------|
| **When** to upsert (post-turn, library save, login) | Mixed | `RollingMemoryIndexService` (rap), `RollingMemoryWriter` (core) |
| Build chat card meta (title, traceId, skill, …) | `RollingMemoryIndexService` | Same — calls `workspace.rollingMemory.upsertCard` |
| Build book/adventure/annotation meta | `RollingMemoryWriter` | Same |
| Load account roster + gather teammate rows | `gatherShareSettingsTeammates` in persist | **Move to services** — needs `userDb` / `DatabaseManager` + `workspace.sharing` + `workspace.userProfile` |
| Fetch system template from `_system/` | Services + persist | **Services** pass `templateBody` into client methods (client does not know `_system/` paths except via layout constant) |

**Service call shape (target):**

```ts
// rap — after turn
const meta = buildChatCardMeta({ summary, traceId, mode, … });  // service helper
await workspace.rollingMemory.upsertCard(accountId, userId, {
  cardType: 'chat',
  cardId: chatHistoryId,
  metaLines: meta,
}, templateBody);

// core — saved book
await workspace.rollingMemory.upsertCard(accountId, userId, {
  cardType: 'book',
  cardId: bookKey,
  metaLines: buildBookCardMeta(book),
});

// rap — login share sync
const teammates = await buildShareSettingsTeammates({ sharing, userProfile, userDb, … });
const cards = shareSettingsCardsFromInput(teammates);  // can stay exported helper
await workspace.rollingMemory.replaceShareSettingsCards(accountId, userId, cards, templateBody);
```

---

## Service files after migration

| File | Role |
|------|------|
| `rap-service/…/RollingMemoryIndexService.ts` | **Orchestration** — post-turn, remove chat, login sync; meta builders; template load |
| `core-service/…/RollingMemoryWriter.ts` | **Orchestration** — entity touch from library/reader; fire-and-forget upserts |

Both shrink to: load template → build params → `workspace.rollingMemory.*`. No direct `StorageManager.uploadAgentsFile` for rolling memory.

---

## Files to delete

| File | Replacement |
|------|-------------|
| `src/rollingMemoryIndex.ts` | Logic → `RollingMemoryClient.ts` (module functions) + constants → `layout/rolling-memory.ts` |
| `src/rollingMemoryPersist.ts` | Logic → `RollingMemoryClient.ts`; `gatherShareSettingsTeammates` → services |

Update `src/index.ts`: remove `export * from './rollingMemoryIndex'` / `rollingMemoryPersist`; export via `clients`.

---

## `WorkspaceClients` wiring

```ts
readonly rollingMemory: RollingMemoryClient;

this.rollingMemory = new RollingMemoryClient(storage);
// No sharing/profile in constructor — services pass teammate data into replaceShareSettingsCards
```

---

## `PersonaClient` boundary

| Client | Owns |
|--------|------|
| `PersonaClient` | Generic persona file read/write/list; `memory-index.json` |
| `RollingMemoryClient` | **`ROLLINGMEMORY.md` only** — structured index with cards + frontmatter |

No overlap: `PersonaClient.readPersonaFile(rollingMemoryDocKey(...))` callers migrate to `RollingMemoryClient.read()`.

---

## Domain map row (README)

| Domain | Types | Layout | Client | UI / service |
|--------|-------|--------|--------|--------------|
| Rolling memory | `rolling-memory.ts` | `layout/rolling-memory.ts` | `RollingMemoryClient` | `RollingMemoryWriter` (core), `RollingMemoryIndexService` (rap) — **not** Agent tools |

Agent reads rolling memory via `AgentWorkspaceService` loading the file body into context — unchanged surface, different client underneath.

---

## Implementation phases (after approval)

### RM-1 — storage-client ✅ (2026-07-11)

- [x] Add `layout/rolling-memory.ts`; export from `layout/index.ts`
- [x] Add `clients/RollingMemoryClient.ts` (absorb index + persist I/O)
- [x] Wire `WorkspaceClients.rollingMemory`
- [x] Move `libraryItemKey`, share-settings gather → `utils/rollingMemoryHelpers.ts` (core + rap)
- [x] Delete `rollingMemoryIndex.ts`, `rollingMemoryPersist.ts`
- [x] `npm run build` storage-client

### RM-2 — services ✅ (2026-07-11)

- [x] `utils/rollingMemoryHelpers.ts` (core + rap) — share settings, card keys, template load
- [x] `RollingMemoryWriter`, `RollingMemoryIndexService` → narrow client + service utils
- [x] Removed orchestration from `RollingMemoryClient` exports

### RM-3 — optional cleanup

- [ ] Move `buildThinChatMeta`, `resolveChatTitle` from `RollingMemoryIndexService` → `utils/rollingMemoryChat.ts`
- [ ] Deduplicate core/rap `rollingMemoryShareSettings.ts` if a shared service package appears later

---

## Open questions — resolved (Zach 2026-07-11)

1. **Key location** — ✅ **`layout/rolling-memory.ts` is canonical.** `assistantRollingMemoryKey` becomes alias/re-export from persona during migration, then remove.
2. **Parse exports** — ✅ **Single implementation in `RollingMemoryClient.ts`; export specific pure functions** (`parseRollingMemoryDocument`, `parseAllRollingCards`, …) from `clients/` for callers that parse in-memory without persisting. No duplicate logic in services — exports are the same functions the client uses internally.
3. **Template loading** — ✅ **Services pass `templateBody`.** Rolling memory is platform-maintained (unlike static persona markdown). Client does not fetch `_system/` templates; services load via layout key + `StorageManager` and pass string in.

---

## Approval

- [x] Zach approves layout + client split
- [x] Zach approves moving `gatherShareSettingsTeammates` to services
- [x] Proceed with RM-1
