---
created: 2026-07-11
updated: 2026-07-22
status: in_progress
---

# WIP — Web App → My Core Imagination

**Focus (keep open):** legislative / placeholder **cleanup**, nav shell polish, Catalog polish. **Adventures Phase A shipped** — see `memory/SHIPPED_MILESTONES.md` (2026-07-22). Chat/quest/companion product work → `memory/TODO.md` Active Backlog.

**Paths:** `apps/web/src/services/` · `pages/dashboard/system/Books/` · `pages/dashboard/admin/Catalog/` · `pages/Landing.tsx` · companion bar  
**Related:** `memory/TODO.md` · `.archive/wip_book-per-source-indexing.md` ✅ · `.archive/wip_rap-service-mci.md` ✅ · `.archive/wip_MD_file_management.md` ✅  
**Out of scope:** Full marketing site / SEO · Stripe redesign · Adventure Master · platform-guide rewrite (separate) · deep agent-profile / quest orchestration (TODO backlog)

---

## Status

| | |
|--|--|
| **Phase** | **Cleanup track** — Phases 0–6 largely done; **Adventures Phase A shipped** (2026-07-22) |
| **Loop** | 4 |
| **Updated** | 2026-07-22 |
| **Next (pick one)** | Phase 3 legislative cleanup · Phase 6 Catalog polish · Phase 9 yield pass |

### Where we are now (2026-07-21)

**Shipped this session (web shell + admin)**

- **Activity annotations (2026-07-21):** Item column works for MCI readers — `billKey` → `bookKey` resolution, doc path + type badge, note previews (`Activity.tsx`, `Activity.helpers.ts`; backend `LibraryController` emits `bookKey` from `billKey`).
- **Teammate visibility counts (2026-07-21):** `TeammateVisibilityPanel` always shows item count (including `· 0 items`); `DashboardSectionCard` shows `(0)` in titles.
- **Chat History sidebar (2026-07-21 — web + storage-client):** Title count from visible rows; teammate saved-library chats merged into one `loadConversationSummaries` call (prune bug fixed — second call was wiping own chats). Backend: library-only path for teammate user ids in `ChatHistoryClient.listConversationsForUsers`. Further product UX → `memory/TODO.md`.
- **Chat turn companion avatars (2026-07-21):** Historical companion image from turn `agentId` + turn owner `userId` (`ChatMessage.tsx`, `AssistantAvatar.tsx`). Root cause: `accountId === 0` treated as falsy — same class of bug as admin fixes below.
- **Account admin — `accountId = 0` (2026-07-21):** System-free account admins no longer hit 404 on Account or empty Users list. `AccountEdit` shows graceful “System (Free)” empty state (no `getAccountById(0)`). Users list uses `user?.accountId != null` + `normalizeAccountId` + `getUsersByAccount(0)`. `coreApi.getUsers` no longer drops `accountId=0` from query params.

**Pattern (repeat offender):** Never use truthy checks on `accountId` (`user?.accountId &&`, `!accountId`) — use `!= null` or `getAccountType(...) === 'system-free'`. See `ARCHITECTURE_CONCEPTS.md`.

### Where we were (2026-07-15)

**Shipped and working**

- **Services / SYSTEM Books / Catalog / dark mode / landing CTAs** — as of 2026-07-14 notes below.
- **Landing moon sizing (2026-07-15):** `--landing-moon-width-max-desktop` / `-mobile` (mobile 25% under desktop after shared −30%).
- **Companion management UI (product — see TODO.md):** Create Companion wizard + Companion Profiles table (`AssistantCreate` / `AssistantEdit`); user menu **My Companions**. Backend: `agent-profiles/` + `/rap/assistants`.
- **Companion bar focus (partial):** `activeBookKeys` + quest pins; bill/statute pins deprecated in store but fields remain.

**Still cleanup / incomplete (this WIP)**

- **`documentScrapingApi.ts`** + legislative hooks in `useApi.ts`.
- **`/dashboard/policy-profile/*`** redirects remain; Adventures is live (Phase A shipped)
- **Home Briefs** — still bill/team oriented backend.
- **User menu** — Mana rename still open (Companions label done).
- **Platform guide** — Policy Command / bills / statutes articles.
- **Catalog detail** — no agent-profile preview; adventures list on detail not built.
- **Adventure quest play + Generate modals** — Phase 7+; see `memory/TODO.md` Active Backlog
- **Phase 9 yield** — not signed off.

### Suggested next steps (your call)

| Option | Work | Unblocks |
|--------|------|----------|
| **A — Finish Phase 3 cleanup** | Delete `documentScrapingApi.ts` + legislative hooks; dead `bills/PdfViewer.tsx`; policy-profile routes/pages; Adventures→policy-profile nav | Cleaner codebase |
| **B — Phase 6 Catalog polish** | Agent-profile preview on detail; linked adventures; admin vs user Catalog route | Catalog “feels done” |
| **C — Phase 7 Adventures** | Quest play, Generate modals, guide orchestrator — **TODO backlog** | Product loop |
| **D — Phase 5 home + labels** | MCI home widgets; Mana rename; Briefs replace | Daily-driver polish |
| **E — Phase 9 yield pass** | End-to-end smoke; archive this WIP | Ship sign-off |

---

## Why this WIP

Backends are MCI-shaped (core `BookController` / `AdventureController` / `BookIndexController`, rap `QuestHistoryController`, indexing book PDF pipeline). The web app is still **Florida Legislative Command**: nav, routes, API clients, focus model, and most SYSTEM pages target bills/statutes/scraping. This WIP tracks conversion to the product shell in `TODO.md` (Home · Chat · Library · Adventures · **Catalog** · Account · SYSTEM Books).

---

## Target UX (from TODO.md)


MCI conversion does **not** remove this menu shell — only renames Companion Settings / Mana and trims legislative copy elsewhere.

### Agent  bar (`AssistantActionBar` / `MobileActionSheet`)

- Focus **content section ** — objective, answer input, Submit; timer in linkPill when timed quest
- Empty quest slot still visible so users learn the format
- Focus pins: **books** and **chats** (replace bill/statute keys + working session/year)
- Component rename (`AssistantActionBar` → `AgentActionBar`) so can be used as the "face" of any LLM agent; behavior first

### Public landing & auth entry (`/`)

| Item | Target |
|------|--------|
| **Register** | `/register` — re-open registration wizard for new accounts (currently reachable but landing does not surface it) |
| **Terms** | `/terms` — make sure have all we need for service description for MCI (companions, catalog books, adventures/quests, AI chat) |
| **Privacy** | `/privacy` — cover what is needed?  |


---

## Current state (services audit — 2026-07-13)

| File | State | Notes |
|------|--------|-------|
| `apiClient.ts` | ✅ Keep | Version discovery works for all three services |
| `coreApi.ts` | ⚠️ Mixed | Book CRUD + adventures + library saved-books ✅ with **`formatSlug`**; `getBookIndexes` / `getBookIndexChunks` / `getLatestBookIndexRecord` ✅; **PolicyProfile** CRUD + saved-bills APIs still present for legacy pages |
| `rapApi.ts` | ⚠️ Mixed | `/rap/assistant/*` + **`/rap/assistants`** agent profiles + quest-history ✅; stale policy profile streams, `getVectorDataByBill` |
| `indexingApi.ts` | ⚠️ Mixed | **`indexBook(author, title, formatSlug)`** ✅; legacy `indexBill` shim for unmigrated code paths |

**Nav today (`MenuBar.tsx`):** Home (Briefs) · Chat · My Library · Adventures · **Catalog** (admin) · Account · Users; SYSTEM: Trials & Subscriptions · Books · Service Monitor · Settings.

**Routes today (`App.tsx`):** MCI dashboard routes + **`/dashboard/admin/catalog/.../:formatSlug`** readers; `/dashboard/bills/*` and `/dashboard/statutes/*` → Catalog redirect; **`/dashboard/policy-profile/*` still registered**; Adventures stub at `/dashboard/adventures`.

**Landing today:** Login + Register CTAs ✅; Terms/Privacy MCI copy ✅; Register wizard uses MCI auth shell (gated by `config.registration.enabled`).

---

## Target API surface (web clients)

### `coreApi.ts` — add / keep

| Area | Endpoints (core-service) — **target paths (no `rag`)** |
|------|--------------------------------------------------------|
| Books (catalog) | `GET/POST /books`, `GET/PUT/DELETE /books/:author/:title/:formatSlug` |
| System adventures | `GET/POST /books/:author/adventures`, `GET/PUT/DELETE …/:uuid` |
| User adventures | `GET/POST /accounts/:accountId/users/:userId/adventures`, … |
| Book indexes | `GET /books/indexes` → **`getBookIndexes`**; `GET /books/:author/:title/indexes/chunks` → **`getBookIndexChunks`** |
| Library | Migrate saved-bills/statutes → saved-books (coordinate with `LibraryController`) |
| Strip | PolicyProfile CRUD, bill tracking, legislative associated types |

**Backend note:** `BookIndexController` still mounts `/books/rag/indices` and `…/rag/vectors` today — rename to **`/books/indexes`** and **`/books/:author/:title/indexes/chunks`** in core-service as part of Phase 1 (or thin alias + deprecate `rag` paths).

Types: mirror `BookDocument` / `AdventureDocument` from `@mci/storage-client` (see `types/book.ts`, `types/adventure.ts`).

### `rapApi.ts` — add / strip

| Area | Endpoints (rap-service) |
|------|-------------------------|
| Quest history | `GET/POST /rap/quest-history`, `GET …/:id`, `GET …/:id/with-answers` |
| Companion (legacy `/rap/assistant` paths) | chat/stream, profile, setup, inbox, chat history, health, logs — **user-facing Companion**; HTTP prefix unchanged until optional rename |
| Strip | Policy profile report streams, `getVectorDataByBill`, legislative search helpers |

### `indexingApi.ts` — rewrite

| Area | Endpoints (indexing-service) |
|------|-------------------------------|
| Index book | `POST /index/book/{authorSlug}/{titleSlug}/{formatSlug}`, `POST /index/document` |
| Crawl | `POST /crawl/start` with `books/` or `books/{authorSlug}/` prefix |
| Status | `GET /crawl/status`, `GET /status`, `POST /crawl/stop`; `GET /index/status/{objectPath}` for single-document job |
| Strip | `indexBill`, `indexStatuteChapter`, legacy **`getIndexSummary`**, all `/storage/*` stats helpers |

**`getIndexSummary` (dropped):** Old legislative Indexing UI called `GET /index/summary` for fast OpenSearch **aggregate counts** per session/year index (chunk count, doc count) on list rows without loading every chunk. MCI indexing-service **does not expose this route** in the book pipeline. SYSTEM Books list instead uses **`coreApi.getBookIndexes`** (index exists + counts) and **`indexingApi.getIndexStatus`** / crawl status during jobs; chunk detail only on the detail page via **`getBookIndexChunks`**. Reintroduce a book-scoped summary endpoint only if list performance needs it.

### Delete (after Phase 3)

- `documentScrapingApi.ts` and all imports

---

## SYSTEM Books admin — design (Phase 2) ✅

**Route:** `/dashboard/system/books` (list) · `/dashboard/system/books/new` (create wizard) · `/dashboard/system/books/:authorSlug/:titleSlug/:formatSlug` (edit)

**Storage:** `books/{authorSlug}/{titleSlug}/{formatSlug}/` — one format per book record (see `.archive/wip_book-per-source-indexing.md`).

### Workflow (detail / create)

1. **Create wizard** — metadata + format → upload source (PDF or EPUB) → auto-index → cover picker (extracted default / upload / AI) → complete.
2. **Upload / replace source** — single slot per format folder.
3. **Index book** — `indexingApi.indexBook(author, title, formatSlug)`; companion-reading animation; status from latest `BookIndexRecord` sidecar.
4. **BookDocument form** — `BookDetailsCard` (description 3 rows; empty description persists); format immutable after create; page/spine counts from index JSON only.
5. **Index quality** — `BookIndexChunksModal` via `getBookIndexChunks`.
6. **Viewers** — system PDF/EPUB readers under `…/:formatSlug/pdf|epub/:filename`.

### List page

- All catalog books from `coreApi.listBooks` (one row per format edition)
- Per-row format from `bookKey` / `formatSlug`
- Actions: open edit, create new book

---

## Adventure create — multi-step wizard (Phase 6)

Adventure creation is **not** a single form. Wizard aligned to `AdventureDocument` + embedded `AdventureQuest`:

| Step | Content | Types |
|------|---------|-------|
| **1 — Adventure** | Title, description, handle, contact, linked `bookKey[]`, privacy | `AdventureDocument` metadata (minus quest) |
| **2 — Quest settings** | `timeLimit` (minutes or none), `competitive` toggle | `AdventureQuest` shell |
| **3 — Objectives** | Ordered list builder: add/reorder/remove objectives | `QuestObjective[]` — `sequenceId`, `type` (v1: `"qa"`), `question`, `acceptableAnswers[]`, optional `pageNumber`, `instructionText`, `transitionText` |

System adventures (SYSTEM Books) use the same wizard under catalog book context (`BookController` system adventure routes). User adventures use `AdventureController` + same UI component.

Play surface (Phase 6): quest history from rap; companion bar Quest focus for active objective + Submit.

---

## Phases / checklist

### Phase 0 — Design + audit ✅ (2026-07-11)

- [x] Inventory `apps/web/src/services/*`
- [x] Map TODO.md UI/UX to current nav/routes
- [x] Cross-check backend controllers (core Book/Adventure/BookIndex, rap QuestHistory, indexing book API)
- [x] Create this WIP
- [x] Review feedback: Catalog, menu order, SYSTEM Books before strip, adventure wizard, index animation, Trial Codes, indexes naming, Companion vs Assistant

### Phase 1 — `services/` wire-up ✅ (2026-07-11)

- [x] **`indexingApi.ts`** — MCI book methods; legacy shim on `indexingApi` for legislative pages until Phase 3
- [x] **`coreApi.ts`** — catalog book + system/user adventure CRUD; **`getBookIndexes`**, **`getBookIndexChunks`**
- [x] **`core-service`** — `BookIndexController` `/books/indexes`, `…/indexes/chunks` (+ legacy `/rag/*` aliases)
- [x] **`rapApi.ts`** — quest-history list/get/create/with-answers
- [x] **`types/catalog.ts`** — BookDocument, AdventureDocument, QuestHistory mirrors
- [x] Deprecated aliases retained for unmigrated call sites (`getBookRagIndices`, policy-profile reports, `getVectorDataByBill`)

### Phase 2 — SYSTEM Books admin ✅ (2026-07-13)

- [x] **`/dashboard/system/books`** — list + create + edit routes with **`formatSlug`**
- [x] **Upload PDF / EPUB** — `source-pdf` / `source-epub` per format folder
- [x] **Index book** — `indexingApi.indexBook(author, title, formatSlug)` + companion-reading animation
- [x] **`BookDocument` form** — `BookDetailsCard` + save; description 3 rows; empty description persists
- [x] **Index quality viewer** — `BookIndexChunksModal` via `getBookIndexChunks`
- [x] **BookCreate wizard** — create → upload → index → cover picker → complete
- [x] **Cover picker** — extracted sidecar default, upload, AI generate (no promote endpoint)
- [ ] **Create system adventure** from Books detail — still Phase 6/7 (Assign to Adventure exists on **Catalog** detail only)

### Phase 3 — Strip legislative SYSTEM pages (mostly ✅)

- [x] Remove routes: bill-collection, statute-collection, realtime-sync, bill-quality, statute-quality, backup, standalone indexing
- [x] Delete pages under `pages/dashboard/system/{BillCollection,StatuteCollection,Realtime,BillQuality,StatuteQuality,Backup,Indexing}`
- [ ] Delete `documentScrapingApi.ts` + legislative hooks in `useApi.ts`
- [ ] Remove dead `pages/dashboard/bills/PdfViewer.tsx` (no route)
- [x] `MenuBar` — MCI SYSTEM nav: Trials, Books, Service Monitor, Settings
- [x] `serviceMonitorStore` / `ServiceMonitor` — MCI service list (core, indexing, rap)
- [x] `Settings` — legislative collection/scraping settings removed
- [x] **Keep** Trials routes/pages
- [ ] Remove **`/dashboard/policy-profile/*`** routes and pages (still live; Adventures nav depends on them today)
- [x] `/dashboard/bills/*` and `/dashboard/statutes/*` redirect to Catalog

### Phase 4 — Public landing, auth entry & legal (✅)

- [x] **`Landing.tsx`** — Log in + Register + Terms/Privacy footer
- [x] **`palette.js` + moon glow** — MCI phase colors
- [x] **Landing moon max sizes** — desktop / mobile CSS vars (`index.css`)
- [x] **`Login.tsx`** — MCI horizon shell + wordmark
- [x] **`Terms.tsx` / `Privacy.tsx`** — MCI copy
- [x] **`Register`** — MCI auth shell in `RegistrationWizard` (same visual language as login)
- [ ] **`/register` e2e** — verify when `config.registration.enabled`; soft-launch “closed” UI when disabled
- [ ] Required before Phase 9 yield

### Phase 5 — Main nav + route shell (partial)

- [x] Nav: **Home · Chat · My Library · Adventures** (+ admin **Catalog**, Account, Users)
- [x] Home sub-nav: Briefs + **Activity** (`/dashboard/activity`)
- [x] **Activity page** — annotation rows for MCI `bookKey` / `documentPath` readers (2026-07-21)
- [x] **Teammate visibility panel** — item counts always visible, including zero (2026-07-21)
- [x] **Account admin (system-free)** — graceful Account page + Users list for `accountId = 0` (2026-07-21)
- [x] **My Library** — Books · Chats · Annotations; saved-books CRUD; opens catalog PDF/EPUB readers
- [x] `/dashboard/bills/*` and `/dashboard/statutes/*` → Catalog redirect
- [ ] **Adventures nav** — still expands to **policy-profile** list; replace with real adventures (Phase 7)
- [ ] **Adventures page** — stub only; remove policy-profile reference
- [ ] Home Briefs — replace legislative tracking backend / cards with MCI widgets
- [x] User menu — **My Companions** (was Assistant Settings)
- [ ] User menu — **Mana** label (still Token Usage)
- [ ] Platform guide — MCI articles (bills/statutes pages still documented)
- [ ] Remove `/dashboard/policy-profile` entirely (after Adventures migration)

### Phase 6 — Catalog (admin — partial ✅)

- [x] **`/dashboard/admin/catalog`** — grid from `coreApi.listBooks` (Guides-style cards, format column)
- [x] Book card cover via `BookCoverImage` + `formatSlug` paths
- [x] **Detail page** — metadata, mobile cover below heading, save to library, Read PDF/EPUB
- [x] **Assign to Adventure** modal — link/unlink `bookKey` on existing adventures
- [ ] **Companion preview** on detail (avatar, truncated origin story)
- [ ] **Adventures list** on detail (quests for this book)
- [ ] Decide: keep admin-only Catalog vs add user-facing `/dashboard/catalog` for non-admins

### Phase 7 — Adventures + quest play UI

- [ ] **`/dashboard/adventures`** — list user + system adventures (core) + quest history (rap)
- [ ] **Adventure create wizard** — 3 steps: Adventure metadata → Quest settings → Objectives builder
- [ ] System adventure create from SYSTEM Books or Catalog detail (same wizard)
- [ ] Quest detail / play surface (deep-link from Catalog or Adventures)
- [ ] **`AssistantActionBar` / `MobileActionSheet`** — Quest focus section (objective, answer, Submit, timer linkPill)
- [ ] **`assistantFocusStore` + `focus.ts`** — `bookKeys`, `chatHistoryId`; remove `billKeys` / `statuteKeys` / working session

### Phase 8 — Library migration (partial)

- [x] Library **saved-books** API wired; Books tab uses `bookKey` + catalog readers
- [ ] Annotated documents — confirm all annotation flows use `bookKey` (not `billKey`); Activity list fixed 2026-07-21
- [x] Saved chats — keep
- [ ] Strip `saved-bills` / PolicyProfile from `coreApi` once pages removed

### Phase 9 — Yield

- [ ] `./start.sh` — all services up; web connects without legislative 404s
- [ ] **Public entry:** `/` → Login or Register → dashboard
- [ ] SYSTEM Books: upload → index → chunk QA
- [ ] Catalog: grid → detail → read PDF/EPUB; save to library
- [ ] Adventure wizard → quest play (Catalog or Adventures → focus bar → Submit)
- [ ] Sign off → archive WIP; trim `TODO.md` active backlog web item

### Phase 10 — Trial Codes (future)

- [ ] Rename nav **Tickets** → **Trial Codes**
- [ ] Account-level trial code CRUD (extend beyond system-wide trial offers)
- [ ] Align SYSTEM **Trials** section with account-scoped UX

---

## Locked decisions

| Topic | Decision |
|-------|----------|
| Start here | **`apps/web/src/services/`** then **SYSTEM Books pages** before deleting legacy SYSTEM UI |
| Catalog naming | User-facing **Catalog** matches backend **catalog** (`CatalogClient`, `BookController`) — not “Store” |
| Main menu order | Home · Chat · Library · Adventures · Catalog · Account · Users · **Tickets** |
| Trial admin | **Keep** trial pages now; **Tickets** → **Trial Codes** + account-level scope = **future phase (Phase 10)** |
| Companion vs Assistant | **Companion** in UI copy; **Agent** in rap harness docs; **`/rap/assistant`** HTTP paths legacy until rename |
| Book index paths | **`/books/indexes`**, **`/books/.../indexes/chunks`** — no **`rag`** in target API or client names |
| Book index clients | **`getBookIndexes`**, **`getBookIndexChunks`** |
| Index list aggregates | **No `getIndexSummary`** — use `getBookIndexes` + job status; **no indexing-service `/storage/*` stats** |
| Book metadata | `BookDocument` fields: user form + import/dropdown + system pre-fill post-index |
| Indexing UX | Companion **reading** animation (scrolling PDF pages) while index job runs |
| SYSTEM strip gate | Phase 3 only after Phase 2 Books admin is functional |
| Catalog layout | Guides-style grid at **`/dashboard/admin/catalog`** (admin-gated today); detail + readers + Assign to Adventure |
| Catalog route | **`/dashboard/admin/catalog/:author/:title/:formatSlug`** — 3-segment `bookKey` |
| Adventure create | **3-step wizard** — adventure doc → quest settings → objectives list |
| Legislative UI | **Delete** routes/pages/APIs — no feature flags |
| Policy Profiles | **Remove** (rap briefings/reports already deleted) |
| Companion catalog CRUD | SYSTEM Books UI; backend companion routes may lag — stub in Phase 2 if needed |
| Public landing | **Login + Register on `/`**; Terms/Privacy MCI copy — Phase 4; required before yield |
| Legal pages | Rewrite **Terms** + **Privacy** for MCI; Finndigo LLC entity can stay — product is My Core Imagination |
| `accountId = 0` guards | **System-free pseudo-tenant** — use `accountId != null`, `normalizeAccountId()`, or `getAccountType()`; never truthy `user?.accountId &&` (breaks avatars, Users, Account admin) |

---

## Dependency order (updated 2026-07-13)

```
indexing-service + per-format bookKey ✅ (.archive/wip_book-per-source-indexing.md)
        ↓
web Phase 1 services/ ✅
        ↓
web Phase 2 SYSTEM Books ✅
        ↓
web Phase 3 SYSTEM strip (mostly ✅ — policy-profile + documentScrapingApi remain)
        ↓
web Phase 4 landing + auth ✅
        ↓
web Phase 5 nav shell (partial — Activity + admin accountId=0 fixes 2026-07-21) + Phase 6 Catalog admin (partial) ← YOU ARE HERE
        ↓
web Phase 7 Adventures wizard + Quest UI + focus bar
        ↓
web Phase 8 library/annotation cleanup
        ↓
web Phase 9 yield
        ↓
web Phase 10 Trial Codes (account-level — later)
```

---

## Zach's Thoughts

Services first, then SYSTEM Books while old pages still exist to copy from. The companion-reading animation is the emotional hook — indexing isn’t a batch job, it’s the companion learning the book. Adventure wizard separates “world setup” from “quest design” so objectives stay editable without touching adventure metadata. Trial-code admin stays on the bus — rename and account scope can wait until catalog/adventures ship. **Landing must let people in** — CTAs and Terms/Privacy are part of shipping MCI, not a separate marketing project.

## Design — rainbow spectrum (reference)

| Color | RGB | Hex |
|-------|-----|-----|
| Red | 255, 13, 13 | `#FF0D0D` |
| Orange | 255, 131, 13 | `#FF830D` |
| Yellow | 255, 255, 22 | `#FFFF16` |
| Green | 31, 255, 22 | `#1FFF16` |
| Blue | 1, 46, 255 | `#012EFF` |
| Indigo | 59, 11, 117 | `#3B0B75` |
| Violet | 139, 31, 203 | `#8B1FCB` |
