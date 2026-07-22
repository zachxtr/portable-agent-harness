---
created: 2026-07-12
updated: 2026-07-12
status: archived
---

# WIP — Catalog Book Source Formats — ARCHIVED

**Completed:** 2026-07-12 · Yield validated (PDF + EPUB3 ingest, viewers, admin UI, smoke-tested)  
**Paths:** `packages/services/indexing-service/` · `apps/web/src/pages/dashboard/system/Books/` · `storage-client` `layout/catalog.ts` · `docs/sample-files/gutenberg.org.html`  
**Related:** `memory/wip_indexing-service-mci.md` · `memory/wip_web-app-mci.md` (Books admin)  
**Out of scope (v1):** Gutenberg bulk import · EPUB annotations · plain-text/HTML zip ingest

---

## Status

| | |
|--|--|
| **Phase** | **archived** — Phase 1 complete (PDF + EPUB3 native ingest) |
| **Loop** | 1 |
| **Yield** | Zach validated EPUB smoke (`pg2350-images-3.epub`), index chunks modal, cover generation |

---

## Locked decisions (2026-07-12)

| Topic | Decision |
|-------|----------|
| **Strategy** | **B — multi-format ingest** (index what you store); PDF and EPUB3 in v1 |
| **Index endpoint** | Single `POST /index/book/{author}/{title}` with `{ force: true }`; internal dispatch by file extension |
| **OpenSearch index** | One index per book (`book-{author}-{title}`); chunks differ by `objectPath` + `documentType` |
| **Chunk locators — PDF** | `startPage`/`endPage` + **`startLine`/`endLine`** (global line numbers across extracted text) |
| **Chunk locators — EPUB3** | `chapter`/`sectionTitle` + **`startLine`/`endLine`**; `startPage`/`endPage` = spine item index; optional `sourceHref` |
| **`book.json` after index** | `format` + `pages` always; fill-if-empty for author, publisher, publishedDate, language, isbn, summary; **catalog subjects → `Topics:` line at end of description** (not genres) |
| **Gutenberg subjects** | LOC-style `dc:subject` strings appended as `Topics: …` in description — genre picker stays manual/mapped |
| **Gutenberg publisher** | Inferred as **Project Gutenberg** when identifier/source URL contains `gutenberg.org` |
| **Web viewers** | Dedicated **BookPdfViewer** + **BookEpubViewer** (separate from legislative PdfViewer); HTML/XHTML rendered by epub.js |
| **Annotations** | **PDF only today** — EPUB needs CFI/line locators + new viewer layer (**Phase 2**, not v1) |
| **Not in v1** | Plain text, HTML zip, mobi, house-PDF normalization pipeline |

---

## Implementation summary

### Indexing-service

- `book_pdf_extractor.py` — PyMuPDF; `documentType: book_pdf`
- `book_epub_extractor.py` — zip + OPF spine + BeautifulSoup; `documentType: book_epub3`
- `book_chunker.py` — global `startLine`/`endLine` for all sources
- `orchestrator.py` — dispatches by extension; patches `book.json` with format + pages
- `book_index_naming.is_indexable_book_source()` — `.pdf` and `.epub`

### Core-service

- `POST …/source-pdf` · `POST …/source-epub`
- `GET …/assets/:filename` — download for viewers

### Web

- Source Assets: upload PDF or EPUB, re-index, view links
- Routes: `…/pdf/:filename` · `…/epub/:filename`
- **BookCreate** 3-step wizard (source → details → cover)
- **BookEdit** header: "Book Details" + title/author subtitle
- **BookIndexChunksModal** — chunk selector shows `filename #index`

### RAP (cover pipeline)

- Cover prompt via `BEDROCK_SYSTEM_MODEL_ID` (Nova Lite); art via Stability Ultra in `us-west-2`

---

## Deferred (not in this WIP)

1. **EPUB annotations** (Phase 2) — CFI/line locators + viewer layer
2. **House PDF recipe** (Strategy C) — uniform print-style citations
3. **Multi-source books** — index both PDF and EPUB on same book (supported technically; UX TBD)
4. **Gutenberg import automation** — separate initiative

---

## Zach's Thoughts

> **Zach adds rows here** — raw notes only. **Joshua:** when a note is folded into the body above, prefix that **existing row** with `DONE:` — never add new rows to this section.

DONE: PDF might not be best — Gutenberg has EPUB3, plain text, HTML zip; could create consistent PDFs from those instead of indexing arbitrary PDFs.  
DONE: Support both PDF and EPUB3 natively; startLine/endLine on PDF too; separate PdfViewer + EpubViewer; annotations on EPUB deferred.  
Sample reference: `docs/sample-files/gutenberg.org.html` (Project Gutenberg ebook 2350 download page).
