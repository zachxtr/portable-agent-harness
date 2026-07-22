# Shipped milestones (archive)

Historical record of major shipped work. **Not** session pickup context — read `MEMORY.md` for current status. Append here at session close when something significant ships; do not duplicate into `MEMORY.md`.

---

## 2026-07-22 — Adventures Phase A (manual create / edit / list)

- **Adventures area** — index table (title, guide, books, created, last played), New Adventure wizard (Details → Quest → Objectives → Review), edit cards (Details, Guide, Books, Quest, Objectives)
- **Entry points** — Adventures sidebar CTA, catalog book detail, focus modal New Adventure pill; `bookKey` query pre-fill from catalog/focus
- **`quest.handle`** — optional @short-name on embedded quest for list labels and play context (quest has no separate title)
- **Focus modal cleanup** — discovery limit on chat title row; Defaults and Quest sections removed
- **Create wizard UX** — dark-theme page cards; book picker with action-bar-style LinkPills + quick-tag-style available pool
- **Admin / chat** — `accountId = 0` fixes (Account page, Users list, chat turn avatars); RAP/core adventure + quest-history type alignment

---

## 2026-07-21 — Library reading progress + reader Nav

- **Reader Nav** — Quick View → Nav; `ReaderNavTitleRow` with live `Progress:` (PDF: `Pages:` + progress; EPUB: progress only)
- **Persistence** — `percentComplete` only on `SavedBookDocument`; `readingProgressStore` with **5%** write threshold; login hydrate + library flush
- **Resume** — `?percent=` on open; PDF derives page via `pageFromPercent`; EPUB scroll restore
- **Progress UI** — `LibraryReadingProgressBar` at bottom of reader frame (library books only); draggable seek head (PDF + EPUB); inline bar + `N%` on library cards
- **Reader actions** — Save & Track in Library + Open in Chat on PDF/EPUB `BookActionsCard`
- **Archive:** `memory/.archive/wip_library-reading-progress.md`

---

## 2026-07-21 — Teammates companion Stat cards

- **Backend** — `StatService` + `assistantStatProjection`: OLAP-style companion lens over user rolling memory + `## Activation History` intervals from each companion `MEMORY.md`
- **Stat cards UI** — `CompanionStatGrid`: Totals strip (companions · data points · touches), Time together (Activation%, Joined calendar, Career, Count%), touch counts, `agentId` meta
- **Companion Stats page** — `/dashboard/companions/stats` for own party; accent link from My Companions Actions
- **Reading over shoulder** — saved-book `readingProgress.updatedAt` × activation interval → book count + average progress on Stat cards
- **Teammates** — shared library LinkPills + owner filter (Phase 0b); menu/page rename to Teammates
- **Deferred:** quest/adventure completed vs guided depth; table top-presence chip — see archived WIP Open questions
- **Archive:** `memory/.archive/wip_teammates-activity-scorecard.md`

---

## 2026-07-21 — Home briefing cards, Activity dashboard, annotation memory sync

- **Home briefing cards** — Greetings (full persona + inbox), Adventure Recap (quest history only), Activity (library feed + rolling memory); card-specific prompts prevent cross-card bleed; USER.md omitted from Recap/Activity persona blocks
- **Activity dashboard** — simplified to saved books, chats, and annotations (legacy legislative activity removed)
- **Rolling memory** — annotation create/update/delete syncs annotation cards in ROLLINGMEMORY; shared upsert path for PDF and EPUB

---

## 2026-07-21 — Contacts, theme isolation, companion avatar & create defaults

- **My Contacts** — teammates table, contact details, bidirectional sharing bootstrap, teammate visibility on library rows
- **Theme** — accent/color mode from user profile JSON only; removed global localStorage theme cache (fixed cross-account-user accent leak)
- **Library** — per-owner annotation API rows; mobile Books tab sidebar fix (`DASHBOARD_SIDEBAR_COLUMN`)
- **Companion edit** — MEMORY.md md-editor (agent profile path); rolling memory stays read-only
- **Avatar regen** — persona files from storage, profile accent, no prior-portrait img2img seed; Physical Form honored in prompt
- **Companion create** — “Use default” checkbox for template frontmatter + body sections (`offerTemplateDefaults`)
- **Preferences cleanup** — removed unused legislative search limit from browser preferences store

---

## 2026-07-16 — Schema-driven md-editor (USER / IDENTITY / SOUL)

- **RAP:** `utils/mdEditor/` — `buildMdEditorView`, `inferFieldControl`, `parseMdBodyLayout`; `GET /rap/assistant/md-editor/:fileName` with optional `agentId`; `MdEditorView` types in `@mci/storage-client`; unit tests on locked templates
- **Web:** dumb `MdEditor` renderer (`md-editor/`) — text / select / tags from descriptors; H1 intro read-only + `##` section textareas; no template parsing in `apps/web`
- **Surfaces:** User Profile (`USER.md`) · Companion Edit Identity/Soul tabs (`agent-profiles/{agentId}/`) · create wizard About / Identity / Soul steps + template-driven review
- **Provisioning:** first-load seeds full template body into staging or agent profile paths; wizard finalize promotes `agent-create/` → `agent-profiles/{agentId}/`
- **Deferred (out of scope v1):** admin template authoring UI · ROLLINGMEMORY maintenance UX · WYSIWYG · server-side `_required` PATCH validation
- **Archive:** `memory/.archive/wip_MD_file_management.md`

---

## 2026-07-15 — Companion avatar presentation kits (CSS + AI flavor)

- **Approach:** one still PNG per companion (Stable Image Ultra); motion is client CSS only — no GIF/video gen
- **Kits:** `realistic` (default, no CSS) · `sketch` · `glow` · `whisical` — id = label; locked at create generate time on `config.json`
- **Web:** `CompanionAvatarShell`, `AvatarEffectPicker`, create/review/action-bar wiring; dark-mode picker surfaces; `prefers-reduced-motion`
- **RAP:** `SetupAvatarService` kit-aware prompt flavor + presentation instructions; finalize writes `avatarEffect`
- **Defaults:** persona tone/playStyle smart default (`defaultAvatarEffectFromPersona`); platform fallback `realistic`
- **Deferred:** active/speaking intensity · catalog cover kits · user-photo moving background — see archived WIP
- **Archive:** `memory/.archive/wip_holographic-avatar-css-approach.md`

---

## 2026-07-14 — Dashboard dark mode + chat book-focus pipeline

- **Web:** `DashboardThemeContext`, light/dark theme picker, MCI brand assets (logo/wordmark variants), dark-mode pass across chat, admin, profile, trials, readers, modals; EPUB reader theme + passage search
- **Chat focus:** `assistantFocusStore` book + quest pins; `AssistantFocusPanel` / `AssistantActionBar` MCI focus (books, not bills); chat sends `bookKeys` on turns
- **RAP:** `ChatHistoryController` owns `POST /rap/chat/assistant/stream`; `itemKey` + `type` through VALIDATE → `ChatSource`; `corpusPrefix` + `itemKeys[]` in retrieval/discover; `WorkingContext.itemKeys` canonical
- **Stack slice:** indexing-service chunk `itemKey` → vector-client `itemKeyType` from index prefix → RAP `RankedChunk` / `SourceChunk` → storage-client `ChatSource.type` + `itemKey`
- **Deferred:** Quest Guide bar, quest wizard, `ChatItemRef` scope on turns, guide orchestrator — see `memory/TODO.md` Active Backlog

---

## 2026-07-13 — Web app MCI shell (Library, Catalog, SYSTEM Books)

- **Nav & routes:** Home · Chat · My Library · Adventures · Catalog (admin) · SYSTEM Books; legislative SYSTEM pages removed; bills/statutes redirect to Catalog
- **Library:** Saved books, saved chats, annotations tabs with core API wiring
- **Catalog admin:** Grid, detail, PDF/EPUB readers, save-to-library, Assign to Adventure modal
- **SYSTEM Books:** Create wizard (upload → index → cover), edit, chunk modal, per-format `bookKey` paths
- **Readers:** Consolidated under `components/readers/` shared by catalog, library, admin
- **Harness:** `wip_web-app-mci.md` Phases 0–6 partial; legislative UI remnants remain

---

## 2026-07-12 — Catalog book source formats (PDF + EPUB3)

- **Indexing-service:** native PDF and EPUB3 extractors, unified chunk schema with global `startLine`/`endLine`, single `POST /index/book/{author}/{title}` dispatch by extension, `book.json` metadata patch (format, pages, Gutenberg subjects → `Topics:` in description)
- **Core-service:** EPUB upload + asset download for viewers
- **Web:** Source Assets UI (PDF/EPUB upload, re-index, view links), BookPdfViewer + BookEpubViewer, 3-step BookCreate wizard, BookEdit polish, index chunks modal
- **RAP:** cover prompt via `BEDROCK_SYSTEM_MODEL_ID`; Stability Ultra for art
- **Deferred:** EPUB annotations, house-PDF normalization, Gutenberg bulk import — see `memory/.archive/wip_book-source-formats.md`

---

## 2026-07-07 — Landing page production deploy

- AWS prod landing stack live (`enable_fullstack = false`) — ECS web app, public ALB, Route 53, ACM, `mycoreimagination` resource naming, us-east-1
- Public URL: `https://mycoreimagination.com`
- Landing page responsive layout — moon sizing budgets, tagline placement, scroll behavior, laptop height pressure, RGB glow flow

---

## 2026-07-02 — First-round MCI mechanical cleanup

- Infrastructure rebrand: `mci-*` Docker naming, `mycoreimagination` Keycloak realm, Bedrock-only LLM
- Shared packages: `@mci/*` scope, Ollama removed from ai-client
- Services: retired document-scraping and pipeline services; active trio (core, rap, indexing) with MCI run scripts
- `models-db-client`: platform-only PostgreSQL models (5 tables); legislative bill/statute models and schemas removed; TrialOffer gains optional account scope
- `start-project.sh` / service scripts simplified for Bedrock-only, no retired service exclusions

---
