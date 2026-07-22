---
created: 2026-07-11
updated: 2026-07-11
status: archived
---

# WIP — storage-client CRUD build-out & dual wiring (UI + agent) — ARCHIVED

**Completed:** 2026-07-11 · Yield smoke → `.archive/wip_rap-service-mci.md` → now `wip_chat-companion-quest.md` § RAP smoke  
**Paths:** `packages/shared/storage-client/` · consumers `core-service` · `rap-service`  
**Related:** `memory/.archive/wip_rolling-memory-client.md` · `memory/.archive/wip_rap-service-mci.md` · `storage-client/README.md`

---

## Status

| | |
|--|--|
| **Phase** | **archived** — Phases 0–4 complete |
| **Yield / smoke** | Moved to `wip_rap-service-mci.md` Phase 5 |

---

## Outcome (locked)

| Concept | Bucket | Client |
|---------|--------|--------|
| **Catalog** | `mci-document` | `CatalogClient` |
| **Library** | `mci-agents` `library/` | `LibraryClient` |
| **Workspace** | `mci-agents` (rest) | `WorkspaceClients` + domain clients |

**Service split:**
- **core-service** — adventures, library, books/catalog, `BookIndexController`
- **rap-service** — `ChatHistoryController`, `QuestHistoryController`, Assistant list/get tools

**Deferred:** companion catalog CRUD · `list_library_items` (use `get_library_item` + rolling memory)

---

## Entity matrix — mci-agents (final)

| Entity | Client | core HTTP | rap HTTP | Agent tools |
|--------|--------|-----------|----------|-------------|
| Adventures | `AdventureClient` | `AdventureController` | — | `list_adventures`, `get_adventure` |
| Quest history | `QuestHistoryClient` | — | `QuestHistoryController` | `list_quest_history`, `get_quest_history` |
| Chat history | `ChatHistoryClient` | — | `ChatHistoryController` | `list_chat_history`, `get_chat_history` |
| Library | `LibraryClient` | `LibraryController` | — | `get_library_item` |
| Annotations | `AnnotationsClient` | `LibraryController` | — | `get_annotations` |
| Inbox | `InboxClient` | — | assistant | `list_inbox_messages` |
| Rolling memory | `RollingMemoryClient` | `RollingMemoryWriter` | `RollingMemoryIndexService` | N/A |

## Entity matrix — Catalog (final)

| Entity | Client | Status |
|--------|--------|--------|
| Catalog books | `CatalogClient` | ✅ |
| Book-scoped adventures | `CatalogClient` | ✅ |
| System companions | — | deferred |

---

## Phases (all complete except yield — moved)

- [x] Phase 0 — Design
- [x] Phase 1 — Domain clients (`CatalogClient`, `LibraryClient`, `AdventureClient`, `WorkspaceClients`, `RollingMemoryClient`)
- [x] Phase 2 — HTTP routes (quest/chat → rap; adventures/library/books → core; `BookIndexController`)
- [x] Phase 3 — Agent list/get tools + `workspaceListGet.ts`
- [x] Phase 4 — Consistency (README, ARCHITECTURE, type headers)
- [x] Phase 5 — **moved to `wip_rap-service-mci.md`**

---

## Zach's Thoughts

Catalog = system-level virtual association. Library = user bookmarks. Quest play = rap; adventure design = core.
