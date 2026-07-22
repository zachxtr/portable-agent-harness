---
created: 2026-07-17
updated: 2026-07-17
status: approved
approved: 2026-07-17
---

# WIP — Dynamic Book Covers (3-Layer + Effects)

**Paths:** `apps/web/src/pages/dashboard/system/Books/` · `apps/web/src/components/readers/` · `packages/services/rap-service/` (BookCoverService) · `packages/shared/storage-client/src/layout/catalog.ts`  
**Related:** `CompanionAvatarShell` + `avatarEffects.ts` · `LandingSky` / landing stacked art · `composeBookCover.ts` · `BookCoverPickerModal` · `memory/.archive/wip_epub-reader-html-preprocess.md` ✅  
**Out of scope (v1):** User-uploaded custom background art · per-book custom effect authoring · video covers · 3D parallax beyond CSS

---

## Status

| | |
|--|--|
| **Phase** | 1 — shell + presets (ready to build) |
| **Approved** | 2026-07-17 — Zach |
| **Next** | Phase 1 spike: `BookCoverShell` + `BookCoverBuilderModal` scaffold |
| **Blocks** | Transparency extraction approach for AI scene/character layers (Phase 2) |

---

## Locked decisions (approved)

| Topic | Decision |
|-------|----------|
| **Layer model** | Background preset (user) + AI scene + AI character; CSS effects per layer |
| **UI** | One scroll modal: Upload → Create (1·2·3) → Review; via `BookCoverUpload` in Create + Edit |
| **Default cover** | **If user does nothing, save the indexing-extracted cover** as `coverImage.jpg` when one exists and no catalog cover is set yet |
| **Dynamic path** | Optional — user can build layered cover; otherwise extracted/upload flat cover only (no `cover.json`) |
| **Flat fallback** | Always persist `coverImage.jpg` for EPUB metadata, list thumbs, `prefers-reduced-motion` |
| **None — full cover** | **Generate** cover from title/author/summary (+ optional reference upload as seed). Reference/extracted image is **not** saved as `coverImage.jpg` — only the generated art with title/author bands. |

### Default extracted cover (behavior)

When indexing produces a source sidecar (`{sourceBase}__coverImage.jpg`) or inline cover extract:

1. **After index completes** — if `coverImage.jpg` is missing, **promote extracted → `coverImage.jpg` automatically** (no modal required).
2. **Book Create wizard** — finishing the wizard without opening the cover builder still leaves the extracted cover on the book (same as today’s expectation, made explicit).
3. **Cover builder** — Upload section preloads extracted; if user **Cancel**s or closes without Save and never built a dynamic cover, catalog cover remains the auto-saved extracted image (not cleared).
4. **User override** — any Save from the builder (upload-only or dynamic) replaces the default.

Implementation note: promotion can be **indexing-service or core-service** after index job (copy sidecar → `coverImage.jpg`) and/or **client** on index success in Create/Edit — pick one path in Phase 1 to avoid double-write.

---

## Why this WIP

Companion avatars already use **one still image + CSS presentation kit** (`CompanionAvatarShell`: sketch / glow / whisical / realistic). Book covers today are a **single flat JPEG** (`coverImage.jpg`) with optional AI art composed via `composeBookCover()` (title/author bands).

We want **living covers** that stay **contained in the 2:3 cover frame** and render consistently in:

- System Books wizard + edit (`BookCoverUpload` / `BookCoverCard`)
- Admin catalog browse
- EPUB reader chrome (cover slot beside/in reader layout)

The landing page pattern — **stacked layers + per-layer motion** (canvas sky, horizon PNG, moon glow CSS) — maps cleanly: each layer is independent, effects are CSS/canvas-only (no re-generation on effect change).

---

## Concept (approved)

### Three transparent PNG layers (bottom → top)

| Layer | Contents | Source | Motion / style |
|-------|----------|--------|----------------|
| **1. Background** | Sky, sea, landscape, “world” — **no buildings, vehicles, or plot characters** | **User picks** from ~10 curated presets (not AI) | Ambient: shooting stars, rippling water, wind drift, aurora, etc. |
| **2. Scene** | Man-made / inanimate: buildings, ships docked, ruins, furniture, landscape features that don’t move | **AI generate** (+ regenerate) | Style kit on layer: sketch, realism, glow, whimsical (reuse avatar vocabulary where it fits) |
| **3. Character** | Plot subjects: people, creatures, submarines underway, etc. | **AI generate** (+ regenerate) | Movement kit: scroll, breath, breeze, shudder, bob, drift |

**Compiled cover** (bottom of wizard): live preview = three layers + title/author overlay (existing `composeBookCover` bands). User confirms when happy; we persist layers **and** a flat fallback JPEG.

### User control — one modal, vertical scroll (Create + Edit)

**Single integration point:** `BookCoverUpload.tsx` — used by **Book Create** wizard and **Book Edit** / `SourcePdfCard`. It keeps the thumbnail + “Choose cover” button; clicking opens one shared builder (refactor today’s `BookCoverPickerModal` → **`BookCoverBuilderModal`**).

**Layout:** one scrollable form inside the modal — **not** the current side-by-side upload | AI columns. User works top → bottom:

```
┌─ Book cover ──────────────────────────────────────── [×] ─┐
│  Scroll ↓                                                  │
│                                                            │
│  ┌─ Upload ─────────────────────────────────────────────┐ │
│  │ Optional: extracted source / file pick / clear        │ │
│  │ Used as: final flat cover OR seed for AI steps below  │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌─ Create ──────────────────────────────────────────────┐ │
│  │  1. Select background   (preset grid — user, no AI)   │ │
│  │  2. Generate scene      [ Generate ] [ Regenerate ]    │ │
│  │  3. Generate characters [ Generate ] [ Regenerate ]  │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌─ Review ──────────────────────────────────────────────┐ │
│  │  Live `BookCoverShell` stack + title/author bands     │ │
│  │  (sticky or pinned at bottom on wide screens — TBD)   │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                            │
│                              [ Cancel ]  [ Save cover ]    │
└────────────────────────────────────────────────────────────┘
```

**Section behavior**

| Section | Purpose |
|---------|---------|
| **Upload** | Same as today’s left slot: extracted indexing cover, manual file, clear. Can **Save** immediately as flat `coverImage.jpg` (skip Create), or keep as **seed** for steps 2–3. |
| **Create** | Three numbered steps on one form — scroll to complete. Step 1 required before scene gen (mood/color). Steps 2 and 3 each have their own generate/regenerate; independent state. |
| **Review** | Always reflects current background + scene + character layers + typography. Updates live as any step changes. **Save cover** commits manifest + layer PNGs + flat JPEG. |

**Create vs Upload path**

- **Default (no action):** indexing extract → auto `coverImage.jpg` (see Locked decisions).
- **Upload-only:** user picks upload in builder → Save (flat cover, no `cover.json`).
- **Dynamic cover:** user completes Create 1→2→3, checks Review → Save (manifest + layers + flat JPEG).
- All paths live in the **same modal** — no second entry point.

- Background change → instant in Review.
- Scene regenerate → does **not** wipe character (unless user chooses “regenerate all”).
- Character regenerate → independent.
- Effect pickers per layer (optional v1: ship defaults from genre/tone; v2: explicit UI like `AvatarEffectPicker`).

### Component map (refactor)

| File | Role |
|------|------|
| `BookCoverUpload.tsx` | Thumbnail, indexing state, opens builder — **unchanged call sites** in Create + Edit |
| `BookCoverBuilderModal.tsx` | **New** — replaces `BookCoverPickerModal`; vertical Upload / Create / Review |
| `BookCoverShell.tsx` | Live layer stack in Review (+ catalog/EPUB later) |
| `BookCoverPickerModal.tsx` | **Remove** after builder ships |

---

## Rendering architecture (mirror companion + landing)

### `BookCoverShell` (new shared component)

Parallel to `CompanionAvatarShell`:

```tsx
<BookCoverShell
  aspect="2/3"
  layers={{
    background: { src, presetId, ambientEffect: 'stars' | 'water' | 'wind' | ... },
    scene:      { src, styleEffect: 'sketch' | 'glow' | 'whisical' | 'realistic' },
    character:  { src, motionEffect: 'breath' | 'breeze' | 'scroll' | 'shudder' | ... },
  }}
  title={...}   // optional — wizard uses compose; catalog may hide text on thumb
  author={...}
  mode="live" | "static"   // static = flat JPEG only (fallback)
/>
```

- **DOM structure:** fixed 2:3 box, `overflow: hidden`, `position: relative`, each layer `absolute inset-0` + `object-fit: cover` (or `contain` for character — TBD in Phase 1 spike).
- **Effects:** CSS classes per layer (`book-cover-layer--background-stars`, `book-cover-layer--scene-glow`, `book-cover-layer--character-breath`). Canvas overlay only on background if needed (like `LandingSky`), scoped to the shell box.
- **`prefers-reduced-motion`:** show top composite static JPEG (same as today).
- **Single `<img>` fallback:** when `cover.json` missing or legacy book → existing `coverImage.jpg`.

### Where it mounts

| Surface | Component today | Target |
|---------|-----------------|--------|
| Book Create wizard | `BookCoverUpload` → `BookCoverPickerModal` | `BookCoverUpload` → **`BookCoverBuilderModal`** (scroll form) |
| Book Edit / Source card | same | same |
| Admin catalog grid | `BookCoverImage` | `BookCoverShell` or thin wrapper |
| EPUB reader | (cover in reader chrome if present) | Same shell in reader sidebar/header cover slot |

All share one shell → **one CSS file** (`bookCoverEffects.css` or section in `index.css` next to avatar block).

---

## Generation pipeline (3 AI steps + 1 user step)

### Step 0 — Background (user)

- Ship **10 preset backgrounds** as optimized WebP/PNG in `apps/web/public/covers/backgrounds/` (or MinIO `_system/cover-backgrounds/` for ops updates).
- Each preset: id, label, thumbnail, full-res asset, default ambient effect.
- Stored on book as `cover.backgroundPresetId` (no AI cost).

**Example preset ids:** `ocean-night`, `desert-dusk`, `forest-mist`, `sky-clouds`, `space-nebula`, `storm-sea`, `mountain-snow`, `cave-glow`, `city-fog`, `plain-grass`.

### Step 1 — Scene layer (AI)

New RAP endpoint (or extend BookCoverService):

`POST /rap/catalog/books/cover/generate-scene`

- **Inputs:** book fields + **selected background preset id** (for color/mood alignment) + optional seed from PDF extract.
- **Prompt rules:** vertical 2:3, **inanimate scene only**, no sky (background handles sky), no people/creatures, **alpha-friendly** (see transparency below).
- **Output:** PNG with transparency (or RGB + mask sidecar).

### Step 2 — Character layer (AI)

`POST /rap/catalog/books/cover/generate-character`

- **Inputs:** book fields + optional scene thumbnail (composition lock) + background preset.
- **Prompt rules:** isolated subject(s) from plot, transparent background, no text, sized for lower/center placement typical of cover art.
- **Output:** PNG + transparency.

### Step 3 — Compile (client)

- Stack layers in canvas (same dimensions as today `COVER_WIDTH = 512`).
- Apply title/author bands (`composeBookCover` logic — extract to shared composer that accepts layer URLs).
- Export:
  - `coverImage.jpg` — flat composite (backward compatible).
  - Layer PNGs uploaded to catalog folder.

**Today’s single-shot** `generateBookCover` remains as **“simple cover”** fallback (upload / one-shot AI) for books that skip dynamic builder.

---

## Transparency extraction (decision needed)

AI image models rarely emit true alpha. Options (pick one for Phase 2):

| Approach | Pros | Cons |
|----------|------|------|
| **A. Segmentation API** (Stability segment — already used for seed in BookCoverService) | Clean cutouts; same vendor | Extra API call; cost |
| **B. Chroma key prompt** (“magenta backdrop”) + client key-out | Cheap | Fringing; brittle |
| **C. Dedicated matting model** (rembg self-host / third party) | Good alpha | New infra |
| **D. Model-native PNG alpha** (if Nova/SD supports) | One step | Unreliable today |

**Recommendation:** **A for scene + character** — reuse `referenceImage.controlMode: 'SEGMENTATION'` pattern or post-process segment pass. Spike on one Jules Verne book before UI build.

---

## Storage layout (catalog folder)

Extend `books/{author}/{title}/{format}/`:

```
coverImage.jpg              ← flat composite (required, EPUB + legacy)
cover/cover.json            ← manifest (effects, preset id, layer paths, version)
cover/layers/background.webp  ← only if custom; else preset id in JSON
cover/layers/scene.png
cover/layers/character.png
```

### `cover.json` (draft schema)

```json
{
  "version": 1,
  "backgroundPresetId": "ocean-night",
  "effects": {
    "background": { "ambient": "stars" },
    "scene": { "style": "sketch" },
    "character": { "motion": "breath" }
  },
  "layers": {
    "scene": "cover/layers/scene.png",
    "character": "cover/layers/character.png"
  },
  "compiledAt": "2026-07-17T…",
  "generationTraceIds": { "scene": "…", "character": "…" }
}
```

`BookDocument` optional fields (or keep manifest-only):

- `coverDynamic?: boolean`
- `coverBackgroundPresetId?: string`

Indexing / EPUB: continue to reference `coverImage.jpg` for metadata; reader uses `BookCoverShell` when `cover/cover.json` exists.

---

## Effect kits (first pass)

### Background ambient (CSS + optional canvas, scoped to shell)

| Id | Description |
|----|-------------|
| `none` | Static |
| `stars` | Slow twinkle + occasional shooting star (LandingSky-lite) |
| `water` | Horizontal shimmer / ripple |
| `wind` | Soft horizontal drift on clouds/foliage in preset art |
| `aurora` | Subtle color wash |

### Scene style (reuse avatar visual language)

| Id | Maps from avatar |
|----|------------------|
| `realistic` | `realistic` |
| `sketch` | `sketch` |
| `glow` | `glow` |
| `whisical` | `whisical` |

### Character motion

| Id | Motion |
|----|--------|
| `none` | Static |
| `breath` | Scale 1.0 → 1.02 loop |
| `breeze` | Gentle horizontal sway |
| `scroll` | Slow vertical float |
| `shudder` | Rare subtle shake (horror/tension) |
| `bob` | Nautical up/down (submarines, boats) |

All respect `prefers-reduced-motion: reduce` → static composite.

---

## UI / UX phases

### Phase 1 — Shell + presets (no new AI)

- [ ] 10 background presets in repo
- [ ] `BookCoverShell` with 3 `<img>` layers (scene/character optional placeholders)
- [ ] CSS effect stubs (1–2 per layer to prove stacking)
- [ ] `BookCoverBuilderModal`: Upload → Create → Review scroll layout
- [ ] **Auto-promote extracted sidecar → `coverImage.jpg`** when index finishes and no cover exists
- [ ] Still save flat `coverImage.jpg` on explicit Save

### Phase 2 — AI scene + character

- [ ] RAP: `generate-scene`, `generate-character` + segmentation
- [ ] Wizard: regenerate buttons per layer, loading states, trace ids
- [ ] Upload layer PNGs to MinIO on save
- [ ] `cover.json` manifest

### Phase 3 — Catalog + EPUB

- [ ] Replace `BookCoverImage` / wizard thumbs with `BookCoverShell`
- [ ] EPUB reader cover slot uses shell (fetch layers + manifest)
- [ ] coreApi: get cover manifest + layer assets

### Phase 4 — Polish

- [ ] Effect pickers in wizard (per layer)
- [ ] Smart defaults from genre/SOUL-like book summary
- [ ] Book Edit: edit layers without re-running full wizard

---

## API sketch

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/rap/catalog/books/cover/backgrounds` | List preset ids + thumbnails |
| POST | `/rap/catalog/books/cover/generate-scene` | AI scene PNG |
| POST | `/rap/catalog/books/cover/generate-character` | AI character PNG |
| POST | `/rap/catalog/books/cover/compile` | Optional server-side compose (if client canvas too heavy) |
| GET | `/books/.../cover/manifest` | core-service read `cover.json` |
| GET | `/books/.../cover/layers/:name` | serve layer PNG |

Existing `POST …/cover/generate` → rename/clarify as **legacy single-shot** or remove after migration.

---

## Open questions for Zach

1. **Background presets** — OK to ship as static assets in web `public/` for v1, or must they live in MinIO `_system/`?
2. **Character + scene placement** — AI fills full frame and we mask, or generate smaller “sprite” centered/lower-third?
3. **Regenerate coupling** — Character regen always uses latest scene as reference, or fully independent prompts?
4. **Simple path** — Keep current one-shot AI + upload alongside dynamic builder (recommended: yes)?
5. **EPUB** — Animated cover in reader only, or also bake animated preview for catalog list (performance: list uses static JPEG thumb)?

---

## Approval checklist

- [x] 3-layer model (background preset / AI scene / AI character)
- [x] User picks background; AI only scene + character
- [x] **One modal:** Upload → Create (1·2·3) → Review; shared by Create + Edit via `BookCoverUpload`
- [x] Separate regenerate per layer + live Review at bottom
- [x] **Default: save extracted cover when user does nothing**
- [x] CSS/canvas effects per layer (landing-page stacking pattern)
- [x] Storage: `cover.json` + layer PNGs + flat `coverImage.jpg`
- [x] Phased plan (shell first → AI → EPUB/catalog)
- [ ] Segmentation approach for transparency (decide in Phase 2 spike)

---

## References in repo today

| Piece | Location |
|-------|----------|
| Avatar effects CSS | `apps/web/src/index.css` (`.companion-avatar-shell--*`) |
| Avatar shell component | `apps/web/src/components/assistant/CompanionAvatarShell.tsx` |
| Landing layered motion | `LandingSky.tsx` + `landing-sky` canvas |
| Flat cover compose | `apps/web/src/pages/dashboard/system/Books/lib/composeBookCover.ts` |
| AI cover (single shot) | `BookCoverService.ts`, `BookCoverPickerModal.tsx` → **`BookCoverBuilderModal.tsx`** |
| Storage cover key | `bookCoverImageKey()` → `coverImage.jpg` |
