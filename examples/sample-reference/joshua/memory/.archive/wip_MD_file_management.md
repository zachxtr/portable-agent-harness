---
created: 2026-07-15
updated: 2026-07-16
---

# WIP — Schema-driven `.md` file display / editor

**Paths:** `packages/services/rap-service/src/agent-templates/_system/agent-persona/` · `rap-service/src/utils/mdEditor/` · `rap-service/src/init/uploadAgentSystemDefaults.ts` · `apps/web/src/components/md-editor/` (**render-only**) · `apps/web/src/pages/dashboard/profile/`  
**Related:** `memory/TODO.md` · `memory/wip_chat-companion-quest.md` (agent-profiles create/manage) · interim create-wizard field maps (**replace** in Phase 3)  
**Templates (locked 2026-07-15):** `USER.md` · `IDENTITY.md` · `SOUL.md`  
**Out of scope (v1):** Admin template authoring UI · MEMORY/ROLLINGMEMORY maintenance UX · WYSIWYG markdown

**Context (2026-07-15):** Multi-companion storage is **`agent-profiles/{agentId}/`** (UI: Companion). USER stays shared under `persona/`. MdEditor Phase 2+ must load IDENTITY/SOUL (and later MEMORY body) **per `agentId`**, not singular persona paths. Create wizard currently uses interim field forms; Phase 3 swaps to MdEditor.

---

## Status

| | |
|--|--|
| **Phase** | **Phase 1 shipped** (USER on User Profile); Phase 2 next |
| **Loop** | 1 |
| **Next** | Phase 2 — Identity + Soul tabs on Companion Settings use `MdEditor` + agent-scoped `md-editor` / PATCH APIs |

Templates locked. **Template interpretation lives in rap-service** — web renders JSON only.

---

## Template source of truth

| Layer | Location | Role |
|-------|----------|------|
| **Canonical (edit here)** | `packages/services/rap-service/src/agent-templates/_system/` | In-repo templates — versioned with rap-service |
| **Runtime bucket** | `mci-agents` → `_system/...` (e.g. `_system/agent-persona/IDENTITY.md`) | Copied on every **rap-service start** |

On startup, `init/uploadAgentSystemDefaults.ts` mirrors `agent-templates/_system/**` into the agents bucket under `_system/`. Edit templates in-repo, **restart rap-service** to refresh S3. Per-user persona files live under each user's workspace path; `personaTemplateSync` merges harness meta and seeds empty body sections from `_system/agent-persona` without clobbering user edits.

---

## Problem

Hard-coded forms duplicate what **system templates already define**. RAP parses frontmatter and patches fields/body generically; the web should **render JSON from the API**, not re-implement template rules in TypeScript.

---

## Product direction (locked 2026-07-15)

### 1. Markdown body layout

Parse **template body skeleton** to know structure; load and save **user file body** as the source of truth.

```
┌─────────────────────────────────────────────────────────────┐
│  # {H1 title}                                               │
│  {intro paragraph}              ← read-only display only    │
├─────────────────────────────────────────────────────────────┤
│  ## {H2 title}                  ← section label             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  textarea — exact section content from the .md file │    │
│  │  (includes template prose when seeded — not a copy) │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**Template prose under `##` is real body content — not a separate “hint panel.”**

| Behavior | Rule |
|----------|------|
| **Seed** | On provision / `personaTemplateSync`, copy template body (including prose under each `##`) into the user file when that section is missing or empty. |
| **Load** | Textarea = section `content` from **`MdEditorView`** (server reads user file). |
| **Edit** | User may **save as-is**, **delete**, or **change** — ordinary markdown text. |
| **Save** | Existing `PATCH …/profile` (frontmatter fields) + `PATCH …/profile/body` (rebuilt body). Web sends values; RAP validates `_required` on write. |
| **H1 + intro** | Read-only in UI (context); always preserved in saved body markdown. |

**Example (SOUL `## Core Truths`):** Template ships three paragraphs under the heading. After sync, those paragraphs **are** the section content in the textarea. User hits Save unchanged → same text written back. User clears or rewrites → file updates accordingly.

### 2. YAML frontmatter controls (from template default value)

| Template default | Control | Example |
|------------------|---------|---------|
| `""` | **text** | `hometown`, `fun_fact`, `name` |
| `"A \| B \| C"` (≥2 segments split on `\|`) | **select** | `play_style`, SOUL `tone` / `humor` / `bluntness` |
| `[""]` | **tags** | `favorite_genres`, `favorite_books`, `favorite_characters` |
| `"{{TOKEN}}"` | **text** (seed via `defaultText`) | `preferred_name: "{{USER_NAME}}"` |

- **Pipe (`|`)** delimiter — locked. Trim segments. No `\|` inside labels v1.
- **Tags** — QuickActions-style chips; save as YAML string array (drop empty entries).
- **`_required` / `_protected`** — frontmatter keys only (see harness meta below).

### 3. Harness meta (unchanged)

| Key | UI |
|-----|-----|
| `_required` | Required on frontmatter controls; block save / wizard continue when empty |
| `_protected` | Lock icon; agent edits need inbox approval |
| `_agent_edit_tier`, `_schema`, `_updated`, `_updated_by` | System; not shown in editor |

---

## Locked templates (2026-07-15)

### USER.md

**Frontmatter**

| Key | Control | Meta |
|-----|---------|------|
| `preferred_name` | text (`{{USER_NAME}}`) | required, protected |
| `hometown` | text | |
| `favorite_genres` / `favorite_books` / `favorite_characters` | tags | |
| `play_style` | select | required |
| `fun_fact` | text | |

**Body:** `# User` + intro (read-only) · `## About Me` (textarea, empty until user writes)

### IDENTITY.md

**Frontmatter:** `name` (text) — required, protected  

**Body:** `# Identity` + intro (read-only) · `## Catchphrase` · `## Origin Story` (textarea **pre-filled with template prose** in file)

### SOUL.md

**Frontmatter:** `tone`, `humor`, `bluntness` (select) — required: humor, bluntness, tone; protected: tone  

**Body:** `# Soul` + intro (read-only) · `## Core Truths` (textarea **pre-filled with template prose** in file)

---

## Target architecture

```
System template (.md) in agent-templates/_system/
  └─ startup upload → mci-agents/_system/agent-persona/

personaTemplateSync / provision
  └─ Seeds user file body (template prose copied into sections when empty)

User workspace file
  └─ Single source of truth for frontmatter + body text

rap-service — buildMdEditorView(fileName, user context)
  ├─ Read _system/agent-persona/{fileName}  → infer controls + body skeleton
  ├─ Read user workspace {fileName}         → current values + section content
  ├─ Resolve {{TOKEN}} defaults server-side (e.g. preferred_name ← auth display name)
  └─ Return MdEditorView JSON

GET /rap/assistant/md-editor/:fileName
  └─ MdEditorView { fields[], bodyLayout, complete }

apps/web — MdEditor (dumb renderer)
  ├─ fetch MdEditorView
  ├─ map fields → MdFieldInput (text | select | tags)
  ├─ map bodyLayout → read-only intro + section textareas
  └─ Save → PATCH field(s) + PATCH body (no template logic in web)
```

**Principle:** One interpretation path in RAP. Add a YAML key or pipe option in the template → UI updates without web TypeScript changes.

---

## Shared types (`MdEditorView`)

Types live in **`@mci/storage-client`** (or rap types re-exported to web) so both services share the contract.

```ts
interface MdFieldDescriptor {
  key:             string
  label:           string
  value:           unknown          // current value from user file
  control:         'text' | 'select' | 'tags'
  options?:        string[]         // select only: pipe-split choices from template default
  defaultText?:    string           // text only: seed when empty / {{TOKEN}} resolved
  required:        boolean
  protected:       boolean
}

interface MdBodySection {
  heading:  string    // H2 title (no ##)
  content:  string    // section body text exactly as stored in user .md
}

interface MdBodyLayout {
  title:     string    // H1 (no #)
  intro:     string    // paragraph(s) after H1 — read-only in UI
  sections:  MdBodySection[]
}

interface MdEditorView {
  fileName:    string               // e.g. 'USER.md'
  fields:      MdFieldDescriptor[]
  bodyLayout:  MdBodyLayout
  complete:    boolean              // all _required frontmatter keys non-empty
}
```

**Field descriptor notes**

| Property | When set | Meaning |
|----------|----------|---------|
| `options` | `control === 'select'` | Parsed dropdown choices. Template `"Warm \| Neutral \| Direct"` → `options: ['Warm', 'Neutral', 'Direct']`. |
| `defaultText` | `control === 'text'` | Display seed when value is empty — e.g. resolved `{{USER_NAME}}`. Not a separate UI panel. |
| `value` | Always | What is on disk in the user file (or empty). Web binds inputs to this. |
| `complete` | View root | Server evaluates `_required` against user file; wizard / save gates use this. |

**Not sent to web:** raw `templateDefault`, harness `_schema` / `_agent_edit_tier` — inference stays server-side.

---

## RAP implementation layout

```
packages/services/rap-service/src/utils/mdEditor/
  buildMdEditorView.ts       # orchestrator: template + user file → MdEditorView
  inferFieldControl.ts       # "" | pipe | [""] | {{TOKEN}} rules
  parseMdBodyLayout.ts       # H1, intro, ## sections from markdown body
  mdEditorTypes.ts           # local types if not yet in storage-client
```

**Reuse:** `AgentFileFrontmatter.ts` (parse/serialize), `personaTemplateSync` (seed), section helpers from `personaMigration.ts` (extract/upsert — consider promoting to shared util).

**Unit tests:** rap-service tests against the three locked templates + round-trip body sections. Web gets thin render tests only.

---

## Web component layout (render-only)

```
apps/web/src/components/md-editor/
  mdEditor.tsx             # fetch view, local draft state, save via PATCH
  mdFieldInput.tsx         # text | select | tags — driven by descriptor.control
  mdBodySection.tsx        # ## label + textarea — driven by section.content
  mdFileIntro.tsx          # title + intro — read-only from bodyLayout
```

No `buildMdFieldDescriptors`, `parseMdBodyLayout`, or `mdTemplateRules` in web.

---

## API

### Load editor

```
GET /rap/assistant/md-editor/:fileName
```

| Param | Values |
|-------|--------|
| `fileName` | `USER.md` · `IDENTITY.md` · `SOUL.md` (v1) |

**Response:** `MdEditorView` (see above).

**Server steps:**
1. Load system template from `_system/agent-persona/{fileName}` (agents bucket).
2. Load user file from workspace (null-safe pre-setup).
3. Merge template rules + user values → `fields[]`.
4. Parse template body for section **headings**; fill `content` from user file sections.
5. Set `complete` from template `_required` vs user frontmatter.

### Save (unchanged endpoints)

| Action | Endpoint |
|--------|----------|
| Frontmatter field | `PATCH /rap/assistant/profile` `{ fileName, field, value }` |
| Body rebuild | `PATCH /rap/assistant/profile/body` `{ fileName, body }` |

**Optional Phase 1+:** validate `_required` on PATCH and return 400 with `{ missing: string[] }` — keeps validation in RAP, not web.

`GET /rap/assistant/profile` stays for manifest, memory bodies, setup flags — editor surfaces use **`md-editor`** endpoint instead of parsing raw profile blobs in the client.

---

## UI surfaces

| Surface | File(s) | Notes |
|---------|---------|-------|
| **User Profile** | `USER.md` | `MdEditor` replaces `UserAboutYouForm` — About You lives here only |
| **Assistant Edit — Memories** | `MEMORY.md` + `ROLLINGMEMORY.md` | Existing maintenance tab (unchanged v1) |
| **Assistant Edit — Identity** | `IDENTITY.md` | New tab; avatar picker stays on this tab |
| **Assistant Edit — Soul** | `SOUL.md` | New tab; split from current combined “My Assistant” tab |
| **Assistant Create** | `USER.md` · `IDENTITY.md` · `SOUL.md` | Wizard steps — see Phase 3 |

**Assistant Edit tab model (target):** **Memories** · **Identity** · **Soul** — no About You tab (already removed; user profile is the sole USER.md editor).

---

## Migration

| Replace | With |
|---------|------|
| `UserAboutYouForm` / `UserProfileDraft` | `MdEditor` + `GET md-editor/USER.md` on User Profile |
| `AssistantEdit` combined “My Assistant” tab | **Identity** + **Soul** tabs, each an `MdEditor` |
| `AssistantEdit` bespoke identity/soul forms | `IDENTITY.md` / `SOUL.md` via `MdEditor` |
| `RolePresetSelect`, `ASSISTANT_TONE_OPTIONS`, etc. | descriptor `options` from API |
| `PersonaSetupAboutDraft` / hardcoded maps | `MdEditorView` + PATCH at finalize |
| Client-side template parsing | **Removed** — RAP only |

**Wizard completion:** `MdEditorView.complete` per step (or aggregate before confirm). Body sections optional unless we add `_required_sections` later.

**Interim code impact:** Remove `birthdate` requirement from `validateUserProfileDraft` / `isUserProfileComplete` when USER editor lands. Drop legacy `core_truths` frontmatter reads — Core Truths is body-only in SOUL template.

---

## Implementation phases

### Phase 1 — RAP builder + USER.md spike (yield)

**rap-service**
- [x] `utils/mdEditor/` — `inferFieldControl`, `parseMdBodyLayout`, `buildMdEditorView`
- [x] Unit tests (three locked templates; pipe / tags / `{{TOKEN}}`; body round-trip)
- [x] `GET /rap/assistant/md-editor/:fileName` in `AssistantController`
- [x] Shared `MdEditorView` types in `@mci/storage-client`
- [ ] Ensure sync/provision seeds template body prose into user file (verify / extend if needed)
- [ ] Optional: `_required` validation on PATCH profile field

**apps/web**
- [x] Dumb `MdEditor` + `mdFieldInput` / `mdBodySection` / `mdFileIntro`
- [x] Replace `UserAboutYouForm` on User Profile — fetch `USER.md` view, save via PATCH
- [x] Drop hardcoded `userProfileDraft` field map for USER (use `view.complete` for gating)

**Manual yield:** Open USER editor → fields and About Me match disk → save unchanged → reload view identical.

### Phase 2 — IDENTITY + SOUL (Companion Settings / `AssistantEdit`)

- [x] Tabs exist: **Identity · Soul · Memory** (+ Companion Profiles table) — interim field editors, not MdEditor yet
- [ ] Identity tab: `MdEditor` for `agent-profiles/{agentId}/IDENTITY.md` + avatar
- [ ] Soul tab: `MdEditor` for `SOUL.md`; Core Truths from body section
- [ ] RAP `GET md-editor` / PATCH accept **`agentId`** (companion-scoped keys)
- [ ] Memory tab: read-only MdEditor or body view of MEMORY (optional v1)

### Phase 3 — Wizard

- [x] `AssistantCreate` creates `agent-profiles/{agentId}/` (interim field forms + finalize) — see chat WIP
- [ ] Steps use MdEditor: 1) **USER** (skip if `complete`), 2) **IDENTITY**, 3) **SOUL**, 4) avatar, 5) confirm
- [ ] Confirm summarizes `MdEditorView` fields + body sections
- [ ] Drop parallel `SetupCollectedFields` maps once MdEditor path is source of truth

### Phase 4 — Docs

- [ ] `agent-persona/README.md` — pipe, `[""]`, body seeding, startup upload, **`md-editor` API contract**

---

## Template authoring README (Phase 4)

- `""` → text · `"A | B"` → select · `[""]` → tags · `{{TOKEN}}` → `defaultText` on text control
- `# Title` + paragraph → read-only intro in UI
- `## Section` + optional prose → prose is **initial body text** in user file after sync
- `_required` / `_protected` → frontmatter keys only
- `_schema` → bump on breaking changes
- Edit in `rap-service/src/agent-templates/_system/`; restart service to push to `mci-agents/_system/`
- UI never parses templates — change template → restart RAP → `GET md-editor` reflects it

---

## Decisions log

| Decision | Choice |
|----------|--------|
| Template interpretation | **rap-service only** — web is a dumb renderer |
| API contract | `GET /rap/assistant/md-editor/:fileName` → `MdEditorView` JSON |
| Component namespace | **`md-editor`** — generic, not persona-prefixed |
| Template canonical path | In-repo `agent-templates/_system/` → bucket `_system/` on startup |
| Body default prose | **Real `.md` content** in textarea (seed on sync), not a UI-only Default panel |
| Select delimiter | `\|` pipe → populates descriptor **`options`** |
| Text seed naming | **`defaultText`** (not “placeholder”) for empty/`{{TOKEN}}` defaults |
| Tag sentinel | `[""]` in template |
| H1 intro | Read-only in UI; stored in body |
| `_required` scope | Frontmatter keys only (v1); **`complete`** computed server-side |
| birthdate on USER | **Removed** from template |
| core_truths | **Body section** only; not in `_required` YAML |
| Assistant Edit tabs | **Memories · Identity · Soul** — About You on User Profile only |

---

## Open questions (non-blocking — pick at Phase 1 kickoff)

1. **Token resolution v1:** resolve `{{USER_NAME}}` in `buildMdEditorView` from auth context only, or also from core user profile API?
2. **Wizard draft:** keep `config.json` step snapshot or rely on live file writes + re-fetch `MdEditorView` between steps?

---

## Risks

| Risk | Mitigation |
|------|------------|
| Sync overwrites user-edited body | Sync merges prose only into **empty** sections; never clobber non-empty |
| Startup upload overwrites `_system` | Expected for platform defaults; user workspace files are separate paths |
| `\|` in label | Document restriction v1 |
| Full body rebuild | Unit test H1 + all sections round-trip in **rap-service** |
| Web re-introduces template logic | No parser imports in `apps/web/md-editor`; code review gate |

---

## Success criteria

- Add YAML key to template → `GET md-editor` returns new field → UI renders without web TS change
- Change pipe options in template → dropdown **`options`** update after RAP restart
- SOUL Core Truths: seeded text in `bodyLayout.sections[].content`; Save persists via PATCH body
- One dumb **`MdEditor`** for User Profile (USER) + Assistant Edit (IDENTITY, SOUL) + wizard
- Assistant Edit shows three tabs: Memories, Identity, Soul
- Zero template-rule TypeScript in `apps/web`

---

## Approval

- [x] **Zach — approved to implement Phase 1**

---

## Zach's Thoughts

> **Zach adds rows here** — raw notes only.

DONE: Body = H1 read-only + intro, then ## label + textarea; template section prose as Default on screen.
DONE: Frontmatter: "" = text, "A | B" = select, [""] = tags (QuickActions pattern), _required/_protected for meta.
DONE: Templates locked USER / IDENTITY / SOUL (2026-07-15).
DONE: Template ## prose IS default body content in the file — user saves, deletes, or edits; not a separate panel.
DONE: IDENTITY origin story — one short paragraph, present tense, locked.
DONE: md-editor naming (expand past persona); options = select choices; defaultText for text seeds.
DONE: Assistant Edit → Memories · Identity · Soul tabs; About You stays on User Profile only.
DONE: Template interpretation in rap-service Phase 1 — web renders MdEditorView JSON only (`GET md-editor/:fileName`).
