---
created: 2026-07-16
updated: 2026-07-21
status: archived
---

# WIP — EPUB Reader → Pre-processed HTML Scroll Document — ARCHIVED

**Completed:** 2026-07-21 · HTML reader shipped; spine reader removed; preprocess + chunk alignment in indexing-service  
**Paths:** `packages/services/indexing-service/` · `apps/web/src/components/readers/` · `apps/web/src/pages/dashboard/catalog/CatalogEpubViewer.tsx` · `storage-client` `layout/catalog.ts`  
**Sample fixtures:** `docs/sample-files/pg1727-images-3.epub` · `pg3160-images-3.epub` · `pg139-images-3.epub` · `pg2097-images-3.epub` · `pg2852-images-3.epub` · Gutenberg cache reference `pg1727-images.html`  
**Related:** `memory/wip_indexing-service-mci.md` · `memory/wip_web-app-mci.md` · `memory/.archive/wip_book-source-formats.md` ✅ · `memory/.archive/wip_library-reading-progress.md` ✅ · `memory/TODO.md` § epub layouts  
**Out of scope (v1):** Plain-text / mobi ingest · iframe to gutenberg.org · CFI/epub.js Rendition · multi-source merge per title

**Residual (non-blocking):** `epubjs` still in `apps/web/package.json` — types/helpers in `epubSectionRenderer.ts` / `epubTocNav.ts` reused by HTML reader; safe to remove when those imports are inlined. Per-book `force: true` re-index is ops, not code.

---

## Status

| | |
|--|--|
| **Phase** | **archived** — Phases 1–3 shipped |
| **Loop** | 3 |
| **Yield** | `AnnotatedHtmlReader` + `ChapterNav`; `BookEpubReader` requires `reader/document.html`; `AnnotatedEpubReader` deleted |
| **Blocks** | None |

---

## Why this WIP

The current EPUB viewer (`AnnotatedEpubReader`, ~1,366 lines) already avoids iframe paging, but still carries **spine machinery**: epub.js unzip, per-spine lazy-load, synthetic `epub-loc-{spine}-{n}` addresses, fuzzy `?quote=` citation search, and TOC keyed on spine index.

Project Gutenberg's cache HTML (`https://www.gutenberg.org/cache/epub/1727/pg1727-images.html`) is simpler because it is **one pre-merged scroll document** with native `#chap01` anchors, browser Find, and direct fragment navigation. We can reproduce that experience by **pre-processing at index/upload time** and aligning indexing chunk locators with the merged document.

---

## What Gutenberg does vs what we do today

| | Gutenberg cache HTML | Our EPUB today | Our target |
|--|---------------------|----------------|------------|
| **Document** | Single `pg1727-images.html` | 29+ spine `.xhtml` files inside zip | Single `reader/document.html` in catalog folder |
| **Navigation** | `#chap01` anchor scroll | Spine index + lazy-load window | `#fragment` scroll (native) |
| **Find** | Browser Ctrl+F on full doc | Works only on loaded spine slice | Full doc in DOM — native Find |
| **Citations** | `#fragment` or line in page | `?quote=` fuzzy match + spine load | `?location=chap14` or `?line=4821` |
| **Annotations** | N/A | `epub-loc-3-12` synthetic ids | `fragmentId` + char offsets in block |
| **Runtime** | Static file serve | epub.js + IntersectionObserver | Fetch HTML + DOMPurify once |

**Key insight:** Gutenberg's cache file is **not** identical to EPUB internals. Our `pg1727-images-3.epub` splits content across `1727-h-0` … `1727-h-28` spine files (~30 items). Pre-processing **merges linear spine bodies** into one canonical reader document — the same UX goal as Gutenberg's cache.

---

## Sample fixture analysis (2026-07-16)

### `pg1727-images-3.epub` (Odyssey)

- **Spine:** ~30 linear items — cover wrap + `1727-h-0` (front matter/contents) + `1727-h-1` … `1727-h-28` (books/footnotes)
- **Anchors:** `pref01`, `chap01` … `chap25` (in-file `id` attributes)
- **Gutenberg cache reference:** uploaded `pg1727-images-0.html` shows Contents table linking `#pref01`, `#chap01`, etc. — **same anchor scheme**, one file
- **Size:** merged HTML ~700KB–1MB range (acceptable for mobile eager load)

### `pg3160-images-3.epub` (second fixture)

- **Spine:** ~27 content files + `wrap0000.xhtml` cover wrapper
- Same PG packaging pattern — validates that pre-process pipeline is **author-agnostic**, not Odyssey-specific

---

## Locked decisions (pending Zach approval)

| Topic | Proposal |
|-------|----------|
| **Pre-process when?** | On **`POST source-epub`** upload — **indexing-service** owns unzip → merge → `reader/*` → chunk → embed in one pipeline; re-index `force: true` rebuilds everything |
| **Service ownership** | **All EPUB ingest logic in indexing-service** — no split across core/web; core only stores upload + triggers index job |
| **Keep source EPUB?** | **Yes** — `{source}.epub` stays source-of-record; reader uses derived assets |
| **Reader document** | `reader/document.html` — merged, sanitized body HTML |
| **Assets** | `reader/assets/*` — images/CSS copied from EPUB with rewritten relative URLs |
| **TOC sidecar** | `reader/toc.json` — `[{ label, fragmentId, line? }]` from NCX/`toc.xhtml` or heading scan |
| **Line map** | **Inline `data-line` on blocks** in `document.html` (not a separate sidecar) — global 1-based lines for indexing + citations |
| **Chunk locators (EPUB)** | Add `fragmentId`; `sourceHref` → `document.html#chap14`; keep `startLine`/`endLine` as **global** lines in merged doc; deprecate spine `startPage`/`endPage` for viewer (keep for chunk metadata if useful) |
| **Viewer** | New `AnnotatedHtmlReader` (~300–400 lines) — no epub.js; mobile-first scroll; reuse annotation sidebar/modals |
| **Routes** | Keep `/epub/:filename` route; viewer detects `reader/document.html` and uses HTML path (fallback to legacy spine reader until migrated) |
| **Annotations** | Store `cfiRange` as `fragmentId` (e.g. `chap14`) or `chap14` block id; highlights keep char offsets in `textSelection` |

---

## Target catalog folder layout

```
books/{author}/{title}/{formatSlug}/
  book.json
  coverImage.jpg
  pg1727-images-3.epub                    ← source (unchanged)
  pg1727-images-3__coverImage.jpg
  {dt}__pg1727-images-3__indexing__….json
  reader/
    document.html                           ← merged scroll document
    toc.json                                ← chapter nav
    lines.json                              ← optional line index sidecar
    assets/
      4533179165943612376_cover.jpg
      …                                   ← images referenced by document.html
```

`book.json` additions (proposed):

```json
{
  "reader": {
    "documentPath": "reader/document.html",
    "tocPath": "reader/toc.json",
    "lineMapPath": "reader/lines.json",
    "preprocessVersion": 1,
    "preprocessedAt": "2026-07-16T…"
  }
}
```

---

## Indexing-service changes

### New step: `book_epub_preprocess.py`

Runs inside existing EPUB index pipeline **before** chunking:

1. Unzip EPUB (stdlib — same as `book_epub_extractor.py`)
2. Read OPF spine; skip `linear="no"` and cover-only wrappers (`wrap0000.xhtml`, etc.)
3. For each linear spine item: extract `<body>` inner HTML
4. Concatenate bodies in spine order into one document shell
5. Copy images/CSS into `reader/assets/`; rewrite `src`/`href` to `assets/…`
6. Preserve existing `id` / `name` anchors (`chap01`, `pref01`, …)
7. Stamp `data-line="{n}"` on block elements (`p`, `li`, `h1`–`h6`, …) — **same line numbering rules as chunker**
8. Write `reader/toc.json` from NCX / `toc.xhtml` (fragment + label)
9. Upload artifacts to `mci-document` under book folder
10. Patch `book.json` with `reader` block

### Update `book_epub_extractor.py` + `book_chunker.py`

| Today | Target |
|-------|--------|
| Extract plain text per spine file | Extract plain text from **merged `document.html`** (or merge in-memory during preprocess) |
| `sourceHref` = spine basename (`1727-h-3.htm.xhtml`) | `sourceHref` = `document.html#chap03` or `fragmentId: chap03` |
| `startPage`/`endPage` = spine index | Optional chapter index; viewer ignores |
| `startLine`/`endLine` = global across concatenated spine text | **Unchanged concept** — but lines align with `data-line` in `document.html` |

### Chunk schema additions (EPUB only)

- `fragmentId` — string, keyword index (e.g. `chap14`, `pref01`)
- `sourceHref` — `document.html#chap14` (stable deep link for chat citations)

Re-index: overwrite `reader/*`; chunk ids regenerated on `force: true` (same as today).

---

## Web reader changes

### Replace spine stack with HTML reader

| Delete / shrink | Keep / reuse |
|-----------------|--------------|
| epub.js import + `EpubBook` lifecycle | `DashboardActionsLayout` sidebar shell |
| Lazy-load sentinels, `extendForward`/`extendBackward` | Highlight / note / tag tools + modals |
| `currentSpineIndex` scroll tracking | `coreApi` annotation CRUD |
| Synthetic `assignEpubBlockLocations` (spine-based) | DOMPurify on inject (one-time) |
| `EpubFileNav` spine-index buttons | New `ChapterNav` from `toc.json` → `#fragment` scroll |
| Fuzzy `findBestQuoteMatch` as primary | Keep as **fallback** when chunk has no `fragmentId` |

### New `AnnotatedHtmlReader`

```
Fetch reader/document.html (+ toc.json)
  → inject into scroll container
  → wire chapter nav clicks to element.scrollIntoView
  → citations: ?location=chap14 or ?line=4821
  → annotations: fragmentId + text offsets (highlights) or fragmentId (notes/tags)
```

**Mobile:** single column scroll, font-scale via CSS variable (already exists), no horizontal paging.

### `CatalogEpubViewer` / `BookEpubReader`

Thin router:

- If `book.json.reader.documentPath` exists → `AnnotatedHtmlReader`
- Else → legacy `AnnotatedEpubReader` (until all books re-indexed)

---

## Chat / citation deep links

Update `annotationNavigation.ts`:

| Param | Meaning |
|-------|---------|
| `?location=chap14` | Scroll to `#chap14` in merged document |
| `?line=4821` | Scroll to `[data-line="4821"]` |
| `?section=Chapter XIV` | Fallback TOC label match in `toc.json` |
| `?quote=…` | Last-resort fuzzy match (legacy chunks) |

Chunk cards in chat should prefer `fragmentId` + `startLine` when present.

---

## Implementation phases

### Phase 1 — Preprocess spike (indexing-service)

- [x] `book_epub_preprocess.py` on all `docs/sample-files/*.epub` (5 Gutenberg fixtures)
- [x] `epub_package.py` shared spine/NCX parsing; cover-wrapper skip (`wrap0000.xhtml`)
- [x] Orchestrator calls preprocess on EPUB index → uploads `reader/document.html`, `reader/toc.json`, `reader/assets/*`, patches `book.json.reader`
- [ ] Manual inspect `reader/document.html` in MinIO — compare to Gutenberg cache UX
- [ ] Verify `#chap01` anchors survive merge; images resolve in deployed env

### Phase 2 — Chunk alignment

- [x] `book_epub_reader_extract.py` — lines from merged `document.html` via `data-line`
- [x] Chunker emits `fragmentId` + `sourceHref` (`document.html#chap14`); EPUB chunks omit spine `startPage`/`endPage`
- [x] Per-chunk `startLine`/`endLine` on size splits (line-boundary split, not whole-segment range)
- [x] Trim PG boilerplate before first `chap|pref|book` nav fragment
- [x] `RetrievalFormatter` emits `fragment` in chunk JSON header
- [ ] Re-index after OpenSearch wipe; verify chunk modal + chat citation fields

### Phase 3 — HTML reader (web)

- [x] `AnnotatedHtmlReader` + `ChapterNav`
- [x] `BookEpubReader` routes to HTML path when `reader/document.html` exists (no legacy spine fallback)
- [x] Annotations save/load with `fragmentId` / block anchors
- [x] Reading progress + seek bar (`memory/.archive/wip_library-reading-progress.md` ✅)

### Phase 4 — Cleanup

- [ ] Re-index catalog books with `force: true` (ops — per env)
- [x] Delete or archive `AnnotatedEpubReader` spine machinery
- [ ] Remove `epubjs` dependency if nothing else uses it (helpers still import types)
- [ ] Update platform-guide / token history labels if needed

---

## Risks / mitigations

| Risk | Mitigation |
|------|------------|
| Large merged HTML slow on old phones | Odyssey ~1MB is fine; add size guard (warn if >3MB); optional lazy chapter sections later **only if needed** |
| EPUBs without stable anchor ids | Fall back to `data-line` only; TOC from headings; keep quote fallback |
| Non-PG EPUBs (multi-file novels) | Same pipeline — merge linear spine; PG is the test case, not the only case |
| Annotation migration | Old `epub-loc-*` annotations: one-time orphan or map if spine file + block still parseable |
| CSS breakage after merge | Copy EPUB CSS to `reader/assets/`; scope under `.book-reader` wrapper |

---

## Open questions for Zach

1. **Sidecar vs inline lines** — see **Design notes** below (recommendation: **inline `data-line`**).
2. **Route name** — **DONE:** keep `/epub/:filename`.
3. **Preprocess timing** — **DONE:** run on **`POST source-epub`** (upload); indexing-service owns the pipeline (preprocess → chunk → embed). Re-index `force: true` rebuilds `reader/*` too.
4. **Legacy spine reader** — **DONE:** delete after re-index; no prod annotations to preserve.

### Design notes — Q1: sidecar vs inline lines

When we index and cite a passage, we need a **stable line number** in the merged book (same idea as PDF `startLine`/`endLine` today).

**Inline (recommended):** during preprocess, stamp each paragraph/heading in `document.html`:

```html
<p data-line="4821">maiden on either side of her...</p>
```

- Viewer scrolls to `[data-line="4821"]` for citations
- Chunker and viewer share one source of truth
- No second file to load or keep in sync

**Sidecar:** keep HTML clean; store a separate `reader/lines.json`:

```json
{ "4821": { "fragmentId": "chap09", "textPreview": "maiden on..." } }
```

- Smaller HTML file
- Extra fetch + risk of HTML/lines.json drift on re-index

**Recommendation:** inline `data-line` on block elements. Chapter jumps still use native `#chap01` anchors; lines are for fine-grained citations inside a chapter.

### Design notes — Q4: what is the “spine reader”?

The **current** `AnnotatedEpubReader` (~1,300 lines). It treats an EPUB as a **spine** — an ordered list of internal `.xhtml` files — and:

- Unzips with **epub.js**
- Renders **one spine file at a time** (lazy-load as you scroll)
- Tracks **spine index** (file 3 of 29) for nav and annotations
- Invents synthetic ids like `epub-loc-3-12`

That is the machinery we are **replacing** with one pre-merged `reader/document.html` — Gutenberg-cache style. “Spine reader” = the old approach; “HTML reader” = the new one.

---

## Zach's Thoughts

> **Zach adds rows here** — raw notes only. **Joshua:** when a note is folded into the body above, prefix that **existing row** with `DONE:` — never add new rows to this section.

DONE: Pre-process EPUB into storage folder like Gutenberg cache HTML — one scroll file, chapter anchors, reliable citations and annotations.  
DONE: Keep `/epub/:filename` route.  
DONE: Preprocess on upload POST — indexing-service owns pipeline.  
DONE: Drop spine reader after re-index (no legacy fallback).  
DONE: Prefer inline `data-line` on HTML blocks (not lines.json sidecar).  
DONE: All EPUB preprocess + chunk + embed logic lives in **indexing-service** (single pipeline).  
DONE: End state per book folder: **original `.epub` (source)** + **`reader/document.html` (UI + index source of truth)** + `toc.json` + `assets/` + OpenSearch chunks.
