---
created: 2026-07-15
updated: 2026-07-15
status: archived
---

# WIP — Companion Avatar Presentation Kits (CSS) — ARCHIVED

**Completed:** 2026-07-15 · Yield: still PNG + client CSS kits shipped on create / action bar  
**Paths:** `apps/web/src/theme/avatarEffects.ts` · `CompanionAvatarShell` · `AvatarEffectPicker` · `SetupAvatarService` · `index.css` companion-avatar-shell  
**Shipped kits:** `realistic` (default) · `sketch` · `glow` · `whisical` — id = label; `avatarEffect` on `agent-profiles/{agentId}/config.json`  
**Related:** `memory/SHIPPED_MILESTONES.md` (2026-07-15) · `memory/wip_chat-companion-quest.md`  
**Deferred:** active/speaking intensity · catalog cover kits · user-photo moving background  

---

## Status

| | |
|--|--|
| **Phase** | **archived** — paired gen flavor + CSS shell shipped |
| **Loop** | 1 |
| **Yield** | Zach validated kit rename + `realistic` default + create picker |

---

# Historical draft — Holographic Companion Avatars (original design notes)

## Summary

Generate a single static image per Companion Profile with **Stable Image Ultra** (`stability.stable-image-ultra-v1:1`), then simulate the "moving hologram" effect entirely in the browser with CSS/JS. No video model, no per-user GIF generation, no additional Bedrock cost beyond the initial image.

This avoids the two real problems with generating actual animated frames: character/frame consistency drift across a multi-frame sequence, and the recurring generation cost of producing motion for every companion.

## Why this fits the platform

- One Bedrock call per Companion Profile (image only) instead of N calls for a video/GIF sequence — cheaper and simpler to cache.
- The static PNG becomes a normal static asset — store it the same way as any other domain/companion asset, no special video handling in the pipeline.
- Animation is a purely front-end concern, decoupled from the generation pipeline. If the visual style changes later, it's a CSS tweak, not a re-generation of every companion's avatar.

## Stage 1 — Generate the still

Prompt for translucency, glow, and scan-line texture up front so the image has material to animate against:

```
Holographic projection of [character description], translucent glowing
cyan-blue skin, faint horizontal scan lines, chromatic edge glow, particles
of light drifting around the figure, dark void background, volumetric rim
lighting, sci-fi projection aesthetic

Negative: solid, opaque, matte skin, fully lit face, flat lighting
```

Export as **PNG with transparency** (or with a dark/void background you can key out) so it composites cleanly over any UI background.

## Stage 2 — Animate in CSS/JS

Layer a few lightweight effects over the static image. None of these require canvas or WebGL — plain CSS keyframes are enough and stay performant with many avatars on screen at once.

### 1. Flicker / brightness pulse
Subtle, irregular opacity or brightness variation reads as "unstable projection."

```css
@keyframes hologram-flicker {
  0%, 100% { opacity: 1; filter: brightness(1); }
  92%      { opacity: 1; filter: brightness(1); }
  93%      { opacity: 0.85; filter: brightness(1.1); }
  94%      { opacity: 1; filter: brightness(0.95); }
  96%      { opacity: 0.9; filter: brightness(1.05); }
}

.hologram-avatar {
  animation: hologram-flicker 6s infinite;
}
```

### 2. Scan line sweep
A translucent gradient bar moving top-to-bottom over the image, layered via `::after` or an overlay div.

```css
.hologram-avatar {
  position: relative;
  overflow: hidden;
}

.hologram-avatar::after {
  content: "";
  position: absolute;
  inset: 0;
  background: linear-gradient(
    to bottom,
    transparent 0%,
    rgba(120, 220, 255, 0.25) 48%,
    rgba(120, 220, 255, 0.25) 52%,
    transparent 100%
  );
  animation: scan-sweep 3s linear infinite;
}

@keyframes scan-sweep {
  0%   { transform: translateY(-100%); }
  100% { transform: translateY(100%); }
}
```

### 3. Color/hue drift
A slow hue-rotate keeps the chromatic edge glow from looking static.

```css
@keyframes hologram-hue {
  0%   { filter: hue-rotate(0deg); }
  50%  { filter: hue-rotate(15deg); }
  100% { filter: hue-rotate(0deg); }
}
```
(Combine with the flicker filter using a wrapping element if you need both `brightness` and `hue-rotate` at once, since a single element can only run one `animation-name` cleanly without a shared keyframe — merge into one keyframe block if stacking.)

### 4. Vertical glitch jitter (optional, use sparingly)
A very small, occasional horizontal displacement on a duplicated layer sells a "signal instability" moment. Keep displacement under ~3px and infrequent (every 8–12s) or it reads as a rendering bug rather than an effect.

```css
@keyframes hologram-glitch {
  0%, 97%, 100% { transform: translateX(0); }
  97.5%          { transform: translateX(2px); }
  98%            { transform: translateX(-2px); }
  98.5%          { transform: translateX(0); }
}
```

### 5. Idle floating drift (optional)
A slow, small vertical bob (`translateY` between -4px and 4px over 4–6s) reinforces "projected, not physically anchored," and is very cheap.

## Putting it together

```html
<div class="hologram-avatar">
  <img src="companion-avatar.png" alt="" />
</div>
```

```css
.hologram-avatar {
  animation:
    hologram-flicker 6s infinite,
    hologram-float 5s ease-in-out infinite;
}
.hologram-avatar::after {
  /* scan sweep, as above */
}
```

Stack only what's needed for the intended intensity — flicker + scan sweep alone already reads clearly as "hologram" for a small avatar-sized asset. Glitch and hue drift are accent layers for larger/featured character displays (e.g. an Adventure Master reveal moment) where more visual weight is warranted.

## Performance notes

- All effects above are `transform`/`opacity`/`filter` only — GPU-accelerated, no layout thrashing, safe to run dozens of instances simultaneously (e.g. a roster/grid view of companions).
- `filter` stacking (brightness + hue-rotate together) is slightly more expensive than transform/opacity alone; if a grid view has many avatars visible at once, consider limiting hue-drift and glitch to the single "focused" or "speaking" companion rather than the whole roster.
- No JS is required for the base effect — the `sendPrompt`-style JS hooks are only needed if you want animation state to react to app events (e.g. speed up flicker when a companion is "active" in a scene).

## Open question for later

Whether "active/speaking" companions should get an intensified version of this effect (faster flicker, added glitch) versus idle/background companions in a roster — worth deciding once the UI states (idle, active, loading) are finalized.

---

## Joshua review + implementation plan (2026-07-15)

### Verdict

This is the right call. A still from Stable Image Ultra + client CSS beats animated GIF/video generation for cost, consistency, and cacheability. The TODO items about “moving hologram GIFs” should redirect here: **one PNG per companion, effect chosen at create time, rendered in the avatar shell**.

What I like:
- Animation stays a presentation concern — re-skin without regenerating every companion.
- Safe for roster grids (transform/opacity/filter).
- Fits multi-companion `agent-profiles/{agentId}/avatar.{ext}` — no special media pipeline.

What I’d tighten:
- Don’t bake “cyan hologram” into every Bedrock prompt by default. Prompt flavor should follow the **selected effect** (+ light Identity/Soul hints). Uploaded photos still get the CSS effect without re-prompting.
- Persist `avatarEffect` on companion `config.json`, not only in UI state.
- One shared wrapper component (`CompanionAvatarShell`) so chat bar, create review, edit table, and inbox all look the same.

### Locked design: paired power (gen + UI)

Each effect id is a **matched pair**, not two unrelated knobs:

| Layer | What it does | When |
|-------|----------------|------|
| **How it’s generated** | Bedrock prompt flavor / negative prompt tuned to the kit (hologram material, storyglow paint, arcane aura) | AI generate only — skipped for upload |
| **How it lives in the UI** | CSS kit on `CompanionAvatarShell` (flicker/scan, breathe/rim, orbit/sparkle) | Always — create preview, chat bar, edit, inbox |

One selection in the picker drives both. Combined, the still already “belongs” to the motion language, so the CSS reads as personality rather than a sticker on a generic face.

- **AI path:** default effect from Identity/Soul → user may change → generate with that kit’s flavor → if they dislike it, switch effect + regenerate (same persona, new prompt kit) → save PNG + `avatarEffect`.  
- **Upload path:** pick/adjust effect → PNG as-is → save `avatarEffect` → shell still pops (no Bedrock).  
- **Edit later:** change effect → CSS updates immediately; **Regenerate with this look** re-runs AI using the newly selected kit (v1 — first-class, not a stretch goal).

### Prompt instructions — tell the model what we do with the image

Today `SetupAvatarService` asks the LLM for a “stylized illustrated portrait” but **does not** explain presentation: a single static PNG that the client will animate with CSS (scan sweep, flicker, breathe, aura). Without that context the model may paint a fully opaque, evenly lit face that fights the kit.

**Required additions when we wire `avatarEffect` into generate:**

1. **System / instruction block** (always for AI avatar path) — short, fixed copy, e.g.  
   - Output is one **still** portrait (PNG), not a video or GIF.  
   - The app will layer **client-side motion** on this still (opacity flicker, scan-line sweep, soft pulse, or aura ring — depending on the selected presentation kit).  
   - Compose so those effects read clearly: leave room for rim/edge glow, avoid flat matte fill edge-to-edge, prefer a dark or simple void/soft backdrop that composites in a circular crop.  
   - Do not describe multi-frame animation; bake **material and lighting** that motion can play against.

2. **Selected kit paragraph** — inject the matching flavor row from the table below (hologram / storyglow / arcane) plus negatives for that kit.

3. **Identity / Soul summary** — keep existing `buildPersonaSummary` (name, tone, catchphrase, etc.) so the face matches companion personality.

4. **Accent line** — keep optional favorite-color accent (MCI brand, not Policy Command teal).

Upload path: no Bedrock call; instructions above do not apply.

### Three selectable effects (user picks at avatar creation)

| Id | Name | Feel | CSS stack (keep it light) | Prompt flavor (AI gen only) |
|----|------|------|---------------------------|-------------------------------|
| `hologram` | **Hologram** | Sci-fi projection, unstable signal | Flicker + scan sweep; optional tiny glitch on focused/speaking | Translucent cyan projection, scan lines, chromatic edge, void bg |
| `storyglow` | **Storyglow** | Warm living portrait, storyteller energy | Slow breathe (scale 1→1.02) + soft amber rim pulse + gentle light sweep | Warm painted portrait, soft golden rim light, candlelit depth, subtle ember dust |
| `arcane` | **Arcane** | Magical companion, adventure energy | Slow orbiting ring (conic-gradient `::before`) + sparkle dots + cool hue drift | Soft magical aura, faint constellation motes, iridescent edge glow, deep twilight bg |

Why these three (tied to Identity/Soul without over-fitting):
- **Hologram** — Analytical / Direct / Tactician; “machine that learned by playing.”
- **Storyglow** — Warm / High humor / Storyteller; the companion who remembers plot and mood.
- **Arcane** — Explorer / playful mystery; quests, adventures, make-believe.

### Default from Identity / Soul — override anytime

**Smart default (never locked):** map from SOUL `tone` (+ optional USER `play_style`) when the avatar step opens; user can change the effect before or after generating.

```
tone Analytical|Direct     → hologram
tone Warm                  → storyglow
play_style Explorer        → arcane
else                       → hologram (platform default)
```

**Happy path if they don’t like the look:**
1. Change the selected effect (live CSS preview updates immediately on the current still).  
2. Hit **Regenerate** — Bedrock runs again with the **new kit’s prompt flavor** + same Identity/Soul summary.  
3. Confirm → save PNG + `avatarEffect` together.

No need to re-enter Identity/Soul. Upload users skip regenerate; they only change the CSS kit (or switch to AI gen with the chosen effect).

### Where it lives in the product

1. **Create Companion — Avatar step** (after image chosen, before Continue)  
   - Three effect cards with live preview on the same still.  
   - Selection stored in wizard draft (`assistant.avatarEffect`) and carried through Review.

2. **Finalize**  
   - Write `avatarEffect: 'hologram' | 'storyglow' | 'arcane'` on `agent-profiles/{agentId}/config.json`.  
   - Avatar bytes already reflect gen flavor if AI was used; UI kit is always driven by `avatarEffect`.

3. **Edit Companion**  
   - Same three cards on Identity or a small “Presentation” strip — patch config only (no re-gen required).

4. **Render everywhere**  
   - `AssistantAvatar` / new shell: `className={`companion-avatar companion-avatar--${effect}`}`  
   - Idle = base stack; speaking/active (chat) = optional intensified modifiers later.

### Implementation slices (when we build)

**A — Presentation (web)**  
- CSS module or `index.css` blocks for `--hologram`, `--storyglow`, `--arcane` (wrapper + `::before`/`::after`).  
- `CompanionAvatarShell` props: `src`, `effect`, `size`, `intensity?: 'idle' | 'active'`.  
- Respect `prefers-reduced-motion: reduce` → static image, no animation.

**B — Config + API**  
- Extend `AssistantConfigDocument` with optional `avatarEffect`.  
- Default missing → `hologram` for backwards compat.  
- List/detail APIs already return config — surface the field to the web.

**C — Create / picker UX**  
- Effect chooser in `AssistantAvatarPickerPanel` or a step under avatar preview.  
- Live CSS preview on the draft blob URL (no extra Bedrock call).  
- AI generate: append effect-specific prompt line from a small map in RAP `SetupAvatarService` (or web → collectedFields).

**D — Optional later**  
- Active/speaking intensity.  
- Catalog book covers reusing the same CSS kits (separate WIP — don’t block companions).  
- User profile photo “moving background” as a fourth kit or Storyglow variant.

### Out of scope for v1

- Per-user GIF/video generation  
- WebGL / canvas particle systems  
- Re-generating existing avatars when effect CSS changes  

### Success check

- Create companion → pick Storyglow → lands on Edit with warm pulse.  
- Switch to Arcane in Edit → chat bar updates with no new image upload.  
- Reduced-motion users see a still.  
- Roster of many companions stays smooth.
