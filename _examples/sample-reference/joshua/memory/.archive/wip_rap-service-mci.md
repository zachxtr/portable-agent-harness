---
created: 2026-07-10
updated: 2026-07-15
status: archived
---

# WIP — RAP Service → My Core Imagination — ARCHIVED

**Completed:** 2026-07-15 · Conversion create/refactor done; remaining smoke + product work owned by other WIPs  
**Paths:** `packages/services/rap-service/` · `@mci/storage-client` · `@mci/vector-client`  
**Related:** `rap-service/README.md` · `memory/.archive/wip_storage-client-crud.md` · `memory/wip_chat-companion-quest.md` · `memory/wip_indexing-service-mci.md`

---

## Status

| | |
|--|--|
| **Phase** | **archived** — Phases 0–4 complete |
| **Leftovers** | Book RAG / dual-wiring / catalog parity **smoke** → `wip_chat-companion-quest.md` (RAP smoke carry-forward) · blocked on indexing until books index |
| **Not this WIP** | Agent profiles / Companion create · Quest Guide · Adventure Master |

---

## Outcome (locked)

| Topic | Decision |
|-------|----------|
| Skills | `mci-book-search` / `mci-book-review` / `mci-book-analysis` |
| Worker tools | `get_book_metadata`, `get_book_by_criteria`, `list_books`, `search_books`, `web_search` |
| Assistant tools | list/get adventures, quests, chats; get library, annotations; list inbox, team |
| Identity | **`bookKey`** (`authorSlug/titleSlug[/formatSlug]`) |
| Quest play | rap `QuestHistoryController`; adventure design core `AdventureController` |
| Book index QA | core `BookIndexController` |
| Briefings / policy profile | **deleted** from RAP hot path |
| Controllers | `ChatHistoryController`, `QuestHistoryController`, `AssistantController` |

---

## Phases completed

### Phase 0–3 — Design + create ✅ (2026-07-11)

Skills, worker tools, Assistant list/get tools, persona/enrichment, legislative strip, controller split. Client CRUD: `.archive/wip_storage-client-crud.md`.

### Phase 4 — Refactor + README ✅ (2026-07-11)

- [x] Align types/comments with CODING_PRINCIPLES
- [x] **`rap-service/README.md`** — MCI companion engine
- [x] Grep-clean bill/statute strings in hot paths

### Phase 5 — Yield smoke → moved

Manual smoke checklist **moved** to `memory/wip_chat-companion-quest.md` § RAP conversion smoke (carry-forward). Indexing-service still unblocks book RAG.

---

## Zach's Thoughts

DONE: MCI conversion scope for RAP service. Archive so chat/quest WIP owns remaining engine smoke + agent-profile product work.
