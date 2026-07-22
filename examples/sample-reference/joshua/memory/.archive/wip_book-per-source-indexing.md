---
created: 2026-07-13
updated: 2026-07-13
status: archived
---

# WIP — Per-Format Book Records + Indexing Artifacts — ARCHIVED

**Completed:** 2026-07-13 · Phases 1–4 shipped (storage layout, indexing artifacts, core API, Books + Catalog UI)  
**Paths:** `packages/shared/storage-client/` · `packages/services/indexing-service/` · `packages/services/core-service/` · `apps/web/src/pages/dashboard/system/Books/` · `apps/web/src/pages/dashboard/admin/Catalog/` · `@mci/vector-client`  
**Related:** `.archive/wip_book-source-formats.md` (PDF+EPUB ingest done) · `wip_indexing-service-mci.md` · `layout/usage.ts` · `layout/chat-history.ts`  
**Example:** `books/jules-verne/twenty-thousand-leagues-under-the-sea/{epub3|pdf}/` — one format per folder

**Out of scope:** Gutenberg bulk import · user `files/` workspace indexing (separate track — usage via mci-agents) · EPUB annotations · legacy migration scripts · cross-format RAG union queries · wiring mci-documents catalog index artifacts to subscription billing

---

## Status

| | |
|--|--|
| **Phase** | **archived** — Phases 1–4 complete |
| **Loop** | 2 |
| **Yield** | 3-segment `bookKey`, `BookIndexRecord` sidecars, single-format BookEdit/BookCreate, Catalog detail + readers validated |
| **Follow-up (separate track)** | User `files/` indexing — usage via mci-agents workspace scanner |

---

## Why this WIP (revised 2026-07-13)

Multi-format-in-one-folder added complexity: mixed OpenSearch chunks, multi-source UI, and ambiguous agent retrieval. **Simpler model:**

- **One distribution format per book record** — single `format` string on `book.json` (e.g. `EPUB3`, `PDF`).
- **Format in the storage path** — `bookKey` = `{authorSlug}/{titleSlug}/{formatSlug}`.
- **Same literary title can exist as multiple catalog records** — e.g. EPUB edition and PDF edition are separate `book.json` files in sibling folders.
- **One OpenSearch index per book record** — agent/RAG queries exactly one dataset per book.
- **Index-run sidecars** still live in the format folder (tokens, duration, page/spine counts, history).

---

## Locked decisions

| # | Topic | Decision |
|---|-------|----------|
| 1 | **Usage filename segments** | Index artifact filenames use existing tok/stripe conventions (`layout/chat-history.ts`, `layout/usage.ts`). See § Usage filename contract. |
| 2 | **OpenSearch index** | **One index per book record** (one format folder = one source = one index). No multi-index union for a single book. |
| 3 | **Index history** | `{dt}` in filename; UI/API uses **most recent** run; older files stay in folder. |
| 4 | **Source cover sidecar** | Indexing always writes `{sourceBase}__coverImage.jpg` when extractable (EPUB always; PDF only when page 1 looks image-like). **Kept alongside** `coverImage.jpg` — not a replacement. |
| 14 | **Catalog cover selection** | `coverImage.jpg` is the **display cover** (Catalog, library). On **BookEdit**, admin picks catalog cover from: **source-extracted** (`{sourceBase}__coverImage.jpg`), **uploaded**, or **AI-generated** — via existing cover picker flow. |
| 5 | **Legacy layout** | **No legacy.** Move to `{author}/{title}/{formatSlug}/` on next save/re-index. No read fallbacks for old two-segment paths. |
| 6 | **`pages` on book.json** | **Removed.** Page/spine counts live only in index JSON (`pageCount`, `spinCount`). |
| 7 | **`format` on book.json** | **Keep single `format: string`** — not `formats[]`, no TypeScript union of allowed values. Immutable after create (folder slug matches). |
| 8 | **Multi-format same title** | **Separate book records** — create a new catalog entry per format; do not attach PDF + EPUB to one record. |
| 9 | **Source file UI** | **Upload or replace** the one source file for that format — no “add PDF” + “add EPUB” on the same BookEdit page. |
| 10 | **Book Details UX (admin)** | Description textarea **3 rows**; **clearing description must persist** on save (empty string, not omitted from PATCH). |
| 11 | **Format typing** | **`format` is plain `string` everywhere** (`book.json`, `BookIndexRecord`, API) — no managed enum/union; new formats need no type changes. |
| 12 | **List UI** | **Books + Catalog lists already show Format column** — no list redesign needed; derive display format from **`formatSlug` in path** without opening `book.json`. |
| 13 | **Catalog book detail (mobile)** | Cover **below** page heading (title/author); padded + **rounded** like cards; **remove “Available formats” card** — details card + action menu suffice. |

---

## Storage layout — format segment in path

### bookKey (logical id)

```
{authorSlug}/{titleSlug}/{formatSlug}
```

**formatSlug** — lowercase folder segment derived at create from the free-form `format` string (e.g. `EPUB3` → `epub3`, `PDF` → `pdf`). Use `encodeKey` / sanitize — not a closed enum in types.

### Catalog paths (`layout/catalog.ts`)

```
books/{authorSlug}/{titleSlug}/{formatSlug}/book.json
books/{authorSlug}/{titleSlug}/{formatSlug}/coverImage.jpg              ← catalog display cover (chosen by admin)
books/{authorSlug}/{titleSlug}/{formatSlug}/{sourceFile}                ← one source file
books/{authorSlug}/{titleSlug}/{formatSlug}/{dt}__{sourceBase}__indexing__stripe{id}stripe__tok{n}tok.json
books/{authorSlug}/{titleSlug}/{formatSlug}/{sourceBase}__coverImage.jpg  ← source-extracted cover (always kept when index extracts one)
```

### Two cover files — different roles

| File | Role |
|------|------|
| **`coverImage.jpg`** | Canonical **catalog / library display** cover. Set only by admin upload, AI generate, or saving the extracted sidecar via the cover picker. Indexing never writes this file. |
| **`{sourceBase}__coverImage.jpg`** | **Index artifact** — cover pulled from EPUB or PDF during indexing. Always retained when extraction succeeds. Shown on **BookEdit → Source Assets**; admin selects it in the cover picker to save as `coverImage.jpg`. |

### Example — same title, two formats = two records

```
books/jules-verne/twenty-thousand-leagues-under-the-sea/
  epub3/
    book.json                    ← format: "EPUB3"
    coverImage.jpg               ← display cover (may match source cover or be AI/upload)
    pg2488-images-3.epub
    pg2488-images-3__coverImage.jpg   ← from EPUB index — kept even when coverImage.jpg differs
    20260713100600__pg2488-images-3__indexing__stripefree__tok12480tok.json
  pdf/
    book.json                    ← format: "PDF"
    coverImage.jpg
    twentythousandle00verniala.pdf
    twentythousandle00verniala__coverImage.jpg   ← only if PDF page-1 heuristic passes
    20260713104500__twentythousandle00verniala__indexing__stripefree__tok48200tok.json
```

Each folder is a **complete, independent book** for catalog, indexing, OpenSearch, and agent retrieval.

---

## Phase 1 — Data model & storage layout

### 1a. `book.json` schema

```typescript
// packages/shared/storage-client/src/types/book.ts

/** Logical key — {authorSlug}/{titleSlug}/{formatSlug} */
bookKey: string;

format?: string;   // free-form distribution format — e.g. "EPUB3", "PDF"; matches formatSlug folder
// pages — REMOVED (index JSON only)
```

- **Remove** `pages`.
- **Keep** single `format` as **plain string** (no union type).
- **No** `formats[]`, **no** `sources[]`, **no** artifact pointers.

Update `layout/catalog.ts`:

- `bookFolderPrefix(authorSlug, titleSlug, formatSlug)`
- `bookKeyFromParts(authorSlug, titleSlug, formatSlug)`
- `parseBookKey(bookKey)` → `{ authorSlug, titleSlug, formatSlug }`
- `parseBookDocKey` — 4-segment path
- `formatSlugFromFormat(format: string)` — lowercase/sanitize helper (not a type enum)

Mirror in `apps/web/src/types/catalog.ts`; remove `pages` from form/display.

### 1b. Index artifact JSON

**Type:** `BookIndexRecord` in `packages/shared/storage-client/src/types/book-index.ts` (new).

```typescript
export interface BookIndexRecord {
  bookKey:          string;
  fileName:         string;
  objectPath:       string;
  format:           string;   // plain string — same as book.json format
  indexedAt:        string;
  durationMs:       number;
  model:            string;
  pageCount?:       number;   // PDF
  spinCount?:       number;   // EPUB spine
  chunksWritten:    number;
  tokens: {
    total:  number;
    input:  number;
    output: number;           // 0 for Titan Embed v2
  };
  openSearchIndex:  string;
  coverExtracted:   boolean;
  traceId?:         string;
  stripeSubscriptionId?: string;
}
```

With **one source file per folder**, `{sourceBase}` is still the filename stem (supports replace with different filename). Latest index resolved by max `{dt}` among `*__indexing__*tok.json` in that folder.

### 1c. Sidecar filename patterns

| Artifact | Pattern |
|----------|---------|
| Index run | `{dt}__{sourceBase}__indexing__stripe{stripeId}stripe__tok{total}tok.json` |
| Source cover | `{sourceBase}__coverImage.jpg` |
| Catalog cover | `coverImage.jpg` |

`{dt}` **first** (required by `parseTokFlaggedUsageFilename`).

### 1d. Index artifact filename (catalog — ops metadata, not billing)

**Book index sidecar (mci-documents catalog bucket):**

```
books/{author}/{title}/{formatSlug}/{dt}__{sourceBase}__indexing__stripe{id}stripe__tok{n}tok.json
```

Tok/stripe segments record **token cost and run metadata** for system ops and the BookEdit index status UI. Catalog lives outside user agent workspaces (`mci-agents`) — **system pays**; no `UsageClient` / subscription billing wiring for `mci-documents`.

**User-owned files (future):** same indexing pipeline under `accounts/{id}/users/{id}/files/…` in **mci-agents**. Those keys are picked up automatically by existing workspace usage scanning (`parseUsageEventKey` on user prefix).

### 1e. Layout helpers

- `bookSourceIndexArtifactKey(authorSlug, titleSlug, formatSlug, dt, sourceBase, stripeId, tokTotal)`
- `bookSourceCoverKey(authorSlug, titleSlug, formatSlug, sourceBase)`
- `parseBookSourceIndexArtifactKey(key)`
- `latestBookSourceIndexKey(keys, sourceBase?)`

### 1f. List API — format without opening files

When listing books, **scan folder prefixes** under `books/{author}/{title}/{formatSlug}/`:

- **`formatSlug`** is available from the path immediately (fast S3/common-prefix listing).
- Map to display label for list column: `formatSlug` → uppercase display (e.g. `epub3` → `EPUB3`) **or** read `book.json` only when full record needed (detail/edit).
- Same author+title may appear as **two rows** (epub3 + pdf) — already how Catalog grid and System Books table behave today.

No change to list UI layout — only backend path parsing to populate `format` on list DTOs from `formatSlug` when `book.json` is not loaded.

---

## Phase 2 — Indexing service

### 2a. Token counting

Count input tokens per embed call; `output: 0`; return totals on `WorkerResult` and in HTTP response.

### 2b. Orchestrator

Per index run (one source file in folder):

1. Write `BookIndexRecord` JSON (tok/stripe filename matches body).
2. Extract cover → write **`{sourceBase}__coverImage.jpg`** only (when extractable). **Never** write `coverImage.jpg`.
3. `patch_book_source_metadata` — fill-if-empty catalog fields only; **do not write `pages`**; **do not change `format`** (fixed at create).
4. Write chunks to **one OpenSearch index** for this `bookKey`.

Set `coverExtracted: true` on index JSON when `{sourceBase}__coverImage.jpg` was written.

### 2c. OpenSearch naming

**One index per book record** — encode full 3-segment `bookKey`:

```
bookKey: jules-verne/twenty-thousand-leagues-under-the-sea/epub3
index:   book-jules-verne-twenty-thousand-leagues-under-the-sea-epub3
```

Update `book_index_naming.py`, `@mci/vector-client/indexNaming.ts`, orchestrator, RAP, `BookIndexController`. **No** multi-index union — RAP passes single index from `bookKey`.

Re-index replaces chunks in the same index.

### 2d. Index API paths

Update routes to include `formatSlug`:

```
POST /index/book/{authorSlug}/{titleSlug}/{formatSlug}
```

Body: `{ force, stripeSubscriptionId, traceId? }`

---

## Phase 3 — Core service & web API

1. **CRUD routes** — add `formatSlug` segment (`GET/PUT …/books/{author}/{title}/{format}`).
2. **List books** — scan 3-segment folders; **`format` on list DTO from path `formatSlug`** (no per-row `book.json` read required).
3. **Create book** — user enters/picks format string at create → `formatSlugFromFormat(format)` → folder + `book.json`.
4. **Source upload** — unified `source` upload validates extension loosely against format string; **replace** overwrites existing source in folder.
5. **Re-index** — forward `stripeSubscriptionId`; return latest `BookIndexRecord` fields.
6. **Latest index helper** — `GET …/books/{author}/{title}/{formatSlug}/index` parses max `{dt}` artifact.
7. **Promote source cover** — removed; UI loads extracted sidecar in cover picker and saves via existing `cover-image` upload.

---

## Phase 4 — Web UI

### 4a. BookEdit — source assets + cover selection (single format)

Replace dual PDF/EPUB upload with **one source slot** driven by `book.format` string:

- Upload · Replace · View · Re-index · View chunks — label uses current format (e.g. “Replace EPUB”).
- Index status from latest `*__indexing__*` JSON (pageCount/spinCount, tokens, chunks, indexedAt).
- To add another format → **Create new book** (same author/title, different format).

**Source cover in Source Assets card** (`BookEdit.tsx` / `SourcePdfCard`):

- When `{sourceBase}__coverImage.jpg` exists (from index), show sidecar filename in source card.
- **Cover section** (`BookCoverUpload` + `BookCoverPickerModal`): left tile = upload **or** extracted default; right tile = AI generate (can seed from left). Save always via existing `cover-image` upload — **no promote endpoint**.

Catalog and library always read **`coverImage.jpg`** only — source sidecar is admin-only on BookEdit.

**BookCreate wizard:** after step 2 (create + upload), index runs automatically; step 3 shows index result inline, extracted cover in picker, **Complete** returns to Books list.

### 4b. BookEdit — Book Details card fixes

| Issue | Fix |
|-------|-----|
| Description too tall | `rows={3}` on description textarea. |
| Cleared description not saved | `formToManualUpdateAttributes`: send `description: form.description.trim()` — use `''` or explicit `null`; do not coerce empty → `undefined`. Same audit for `summary` if needed. |

Remove Format/Pages row from details form (format in list/source section; pages from index JSON only).

### 4c. Books list + Catalog grid — no layout change

**Already done** (screenshots validated):

- System **Books** table: Title · Author · **Format**
- **Catalog** grid: cover · title · author · **format label**

After path migration, list endpoints derive **Format** from **`formatSlug` in folder path** — fast listing without opening every `book.json`. Same author+title appears twice when both epub3 and pdf editions exist.

### 4d. Catalog book detail — `CatalogBookDetail.tsx`

**Mobile + desktop cleanup** (one format per record after migration):

| Change | Detail |
|--------|--------|
| **Cover placement (mobile)** | Move cover **below** the “Book” heading and title/author lines — not full-bleed above the header. |
| **Cover styling (mobile)** | Remove `-mx-4` full-bleed and `rounded-none`. Use **card-style** treatment: horizontal padding/buffer + `rounded-lg` + `shadow-sm` to match catalog grid cards. |
| **Remove “Available formats” card** | Delete mobile and desktop sidebar “Available formats” blocks. One record = one format; **details card** shows Format, book key, etc. Read action stays in **Actions sidebar / mobile menu** (Read PDF or Read EPUB — whichever matches this record). |
| **Details card** | Keep metadata card; drop `Pages` from book.json once removed (show page/spine from latest index JSON when available, or omit). |
| **Routes** | Update params to include `formatSlug` when 3-segment bookKey lands (`/catalog/.../:formatSlug`). |

**Target mobile order:**

```
[ Book heading + icon ]
[ Title / Author lines ]
[ Cover image — padded, rounded ]
[ Details card — format, language, publisher, description, … ]
```

---

## Future — User `files/` indexing (not this WIP)

When users upload their own PDFs/EPUBs for indexing:

- Store under `accounts/{accountId}/users/{userId}/files/…` in **mci-agents**
- Reuse indexing-service + tok/stripe artifact naming
- Token counts flow into subscription usage via existing `UsageClient` / `parseUsageEventKey` — no mci-documents wiring

---

## Implementation order

| # | Work |
|---|------|
| 1 | `layout/catalog.ts` — 3-segment paths, `formatSlug` helpers, `parseBookKey` |
| 2 | Types: `bookKey` shape, remove `pages`, `BookIndexRecord` (`format: string`); web mirrors |
| 3 | Core list API — `format` from path `formatSlug`; CRUD + indexing routes with `formatSlug` |
| 4 | OpenSearch naming (3-segment bookKey) — Python, vector-client, RAP, core |
| 5 | Token counting + index artifact write + metadata patch |
| 6 | BookEdit: single-format source UI, cover picker (extracted default + upload + AI), Book Details fixes |
| 7 | BookCreate: format field → `formatSlug` folder; index then show extracted cover default |
| 8 | CatalogBookDetail: mobile cover layout + remove Available formats card |

---

## Open questions

| Question | Proposed default |
|----------|------------------|
| **formatSlug derivation** | `encodeKey(format.trim().toLowerCase())` — not a closed enum |
| **List format display** | Uppercase slug for column (`epub3` → `EPUB3`) unless `book.json` loaded |
| **Token estimate** | chars/4 per chunk unless tiktoken added |
| **Old 2-segment folders** | Re-create or move on re-index (no auto-migration) |
| **Catalog grouping** | Flat rows per format; future “editions” group by `{author}/{title}` prefix |

---

## Approval checklist

- [x] `bookKey` = `{authorSlug}/{titleSlug}/{formatSlug}`
- [x] Single `format: string` on `book.json` and `BookIndexRecord`; no `pages`; no `formats[]`
- [x] Separate book records per format (sibling folders under same title)
- [x] One OpenSearch index per book record
- [x] Index JSON + tok/stripe sidecars; latest by `{dt}`
- [x] List API: format from path without opening every `book.json`
- [x] Books + Catalog list UI unchanged (Format column already present)
- [x] Dual covers: `{sourceBase}__coverImage.jpg` from index; `coverImage.jpg` only from admin UI
- [x] BookEdit: source cover in Source Assets; save to catalog via cover picker; upload/AI still available
- [x] BookEdit: upload/replace one source; description 3 rows; empty description persists
- [x] CatalogBookDetail: cover below heading, rounded/padded; no Available formats card
- [x] Token counting in indexing-service

**Ops note:** Legacy 2-segment folders are not auto-migrated — re-create or move on next save/re-index.
