---
name: wip-management
description: "Run the Full CRY! WIP cycle and groom memory/TODO.md against active wip_*.md files. Use when starting or closing WIP work, pulling backlog into a WIP, cleaning stale TODO items, archiving a shipped WIP, or updating MEMORY.md WIP index rows. Encodes portable harness procedures for Create → Refactor → Yield and WIP/TODO boundary rules."
license: MIT — Copyright © 2026 Data Finn (datafinn.com)
compatibility: Portable Full CRY! agent harness (.agents/<agent>/). Works with any agent folder name after init.
allowed-tools: read_file write_file glob grep shell_command
---

# WIP Management — Full CRY! Cycle & TODO Grooming

Operational procedures for **Full CRY! WIP cycles** in the portable agent harness. A WIP (`memory/wip_<topic>.md`) is the working blueprint for one feature or initiative. **`memory/TODO.md`** holds cross-cutting backlog, domain notes, **Potential new functionality**, and an **Ideas dump** — see **TODO file structure** below.

Methodology: `memory/full-cry-sdlc/Full_CRY_Overview.md` § Portable Agent Harness. Session hook: load this skill for WIP work (`SESSION.md` § Session start step 4).

---

## When to use this skill

- {{USER_WHAT_TO_CALL}} asks to groom TODO against a WIP, or to "pull relevant bits from TODO"
- Starting a new `memory/wip_<topic>.md`
- Implementing, yielding, or closing out an active WIP
- Updating `MEMORY.md` WIP index rows or archiving to `memory/.archive/`
- Deciding whether an item belongs in WIP vs TODO

---

## Full CRY! WIP cycle (procedure)

**Canonical lifecycle diagram:** `.agents/README.md` § Full CRY! WIP cycle (same phase names and `loop` semantics below).

```
design ──▶ create ◀──▶ refactor ◀──▶ yield ──▶ shipped
              └──── loop 1, 2, 3… ────┘
```

| WIP `phase` | Full CRY! pillar | What happens | Artifacts |
|-------------|------------------|--------------|-----------|
| **design** | *(planning)* | Scope, architecture, decisions, TODO grooming — **no product code** (negligible spikes OK) | `memory/wip_<topic>.md`; index row in `MEMORY.md` |
| **create** | **Create** | Scaffold, first implementation — WIP bleeds into code as reality emerges | Code + WIP checkbox updates |
| **refactor** | **Refactor** | Sculpt, align `memory/CODING_PRINCIPLES.md`, cleanup, convention passes | Code + WIP updates |
| **yield** | **Yield** | {{USER_WHAT_TO_CALL}} uses the system as first user — **do not stack features on unvalidated work** | `code-log/` entry; `MEMORY.md` status; set `next_yield` in frontmatter |
| **shipped** | *(close-out)* | Cycle complete — archive WIP | `SHIPPED_MILESTONES.md`; WIP → `memory/.archive/` |

**`loop`** — shared counter during **create ↔ refactor ↔ yield** only. Omit in **design**; start at **`1`** on first **create**; **increment by 1** when yield sends you back for another pass. Pickup reads **yield 2**, **refactor 3**, etc. Freeze final number on **shipped**.

**Do not use informal phases** (e.g. `closeout`) in frontmatter — set **`phase: shipped`** when the cycle is complete, then archive.

**After first yield** (loop continues until prosperous):

| Next step | When |
|-----------|------|
| **Create (light)** | Small WIP edits only — deferred items, design tweaks. No full rewrite unless yield invalidated direction. |
| **Refactor** | Bug fixes, alignment, cleanup from yield feedback. |
| **Yield** | Validate again (local or prod). |

```
  CREATE ──bleeds──▶ REFACTOR ──bleeds──▶ YIELD
         ▲               │                   │
         └──── loop ─────┴───────── loop ────┘
                (repeat until prosperous)
                          │
                          ▼
              SHIPPED_MILESTONES + archive WIP
```

**Close-out (cycle complete):**

1. Append bullets to `memory/SHIPPED_MILESTONES.md`
2. Set WIP frontmatter `phase: shipped`, bump `updated`
3. Move `wip_<topic>.md` → `memory/.archive/` (**never delete**)
4. Update `MEMORY.md` — remove active WIP index row; ground truth = code + milestones + git

**Truth hierarchy:** WIP = draft · `SHIPPED_MILESTONES.md` + git = shipped truth · code log = client-readable *why*

---

## TODO file structure

`memory/TODO.md` opens with **YAML frontmatter** — pickup metadata for agents. **Bump `updated`** on every grooming pass or tier change.

```yaml
---
todo:
  updated: 2026-06-07
  tiers:
    - active_backlog       # actionable - [ ] items; no bold inside item text
    - domain_concepts      # ## sections — product/engineering notes by area
    - potential            # themes materializing from ideas dump; promote to WIP when scoped
    - ideas_dump           # raw capture — plain lines, blank line between each thought
---
```

| Tier | Heading | Owns | Format |
|------|---------|------|--------|
| **Active Backlog** | `## Active Backlog` | Actionable bugs, fixes, harness chores — not tied to one WIP | `- [ ]` checkboxes only; **no bold** in item text |
| **Domain concepts** | `## Your Area`, … | Ongoing notes by product area; may become WIPs | Prose + bullets OK; WIP pointers in italics at section bottom |
| **Potential new functionality** | `## Potential new functionality` | Coherent themes materializing from Ideas dump; not scoped to a WIP yet | `###` sub-themes; short intro; promote upward or demote to dump |
| **Ideas dump** | `## Ideas dump` | Raw capture for later follow-up | Plain lines only — blank line between each thought; no headings inside, no checkboxes, no categorization |

**Promotion path:** Ideas dump → Potential → domain concept or WIP → Active Backlog (when actionable).

**Demotion path:** Stale Potential themes → Ideas dump; shipped items → remove (point to `SHIPPED_MILESTONES.md` or git).

---

## WIP vs TODO (boundary rules)

| Location | Owns |
|----------|------|
| **`memory/wip_<topic>.md`** | Scoped initiative — forward-looking spec, phases, checkboxes, copy targets, implementation status for **this** effort |
| **`memory/TODO.md` — Active Backlog** | Actionable bugs/fixes not tied to a single WIP session |
| **`memory/TODO.md` — domain concepts** | Ongoing product/engineering notes by area |
| **`memory/TODO.md` — Potential new functionality** | Unscoped future themes — promote to a WIP when scheduled |
| **`memory/TODO.md` — Ideas dump** | Raw thoughts — not groomed; agents do not pull from here into WIPs without {{USER_WHAT_TO_CALL}} |

**Do not expand WIP scope** during TODO grooming — pull only items clearly belonging to that WIP's topic.

**Do not duplicate** the same checklist in both files after grooming.

---

## TODO grooming pass (procedure)

Run when {{USER_WHAT_TO_CALL}} asks to clean TODO against a WIP, or when closing a grooming session on a `wip_*.md` file.

### Step 1 — Read both files

1. Target `memory/wip_<topic>.md` (full file — note status, phases, scope statement)
2. `memory/TODO.md` — search by **topic keywords**, not only one section

### Step 2 — Classify each candidate item

| Verdict | Action |
|---------|--------|
| **In WIP scope** | Merge into WIP (appropriate phase/backlog section); remove from TODO |
| **Related but out of scope** | Leave in TODO; add WIP **Related backlog** note (see template below) |
| **Potential / future** | Leave in TODO **Potential new functionality** or domain concept section |
| **Raw / unscoped** | Leave in **Ideas dump** — do not pull into WIP without {{USER_WHAT_TO_CALL}} |
| **Stale / shipped** | Remove from TODO; point to `SHIPPED_MILESTONES.md` or git if needed |

### Step 3 — Update the WIP

- Add groomed content under existing phase headings — do not bloat scope
- End with **Related backlog (`memory/TODO.md`)** using the template below
- **Frontmatter:** bump `updated`; set `phase`, `loop`, and `next_yield` if cycle position changed

### Step 4 — Update TODO

- Remove migrated items
- Bump TODO frontmatter `updated` date
- **Do not** add brittle backlinks from TODO — no WIP `§` sections, no TODO heading anchors, **no line numbers**
- **Active Backlog items:** no bold inside `- [ ]` text

### Step 5 — Update MEMORY.md (if index or status changed)

- WIP index row in `MEMORY.md` § WIP index
- Active next step / in progress only when grooming affects pickup snapshot

---

## Related backlog block (WIP template)

Append near the end of each groomed WIP (under **Reference** is fine). **Do not** cite TODO section names, heading anchors, or **line numbers**.

```markdown
## Related backlog (`memory/TODO.md`)

Continued or new functionality related to **[short topic label]** may also live in `memory/TODO.md` (Active Backlog, domain concepts, or **Potential new functionality**). This WIP owns scoped implementation; TODO owns cross-cutting and unscoped ideas. Search TODO by topic when grooming — avoid brittle links to specific headings or lines.
```

Customize only the **topic label** in brackets.

---

## Starting a new WIP (Design)

1. Confirm topic with {{USER_WHAT_TO_CALL}} if ambiguous
2. Create `memory/wip_<topic>.md` with **YAML frontmatter** (`phase: design` — see **WIP file frontmatter** below), then:
   - Scope / out-of-scope block (body)
   - **Spec sections** — describe behavior and contracts as they **will be** (tables, checklists, file touch lists)
   - Implementation phases with checkboxes
   - **Related backlog** block (even if empty of TODO pulls yet)
3. Add row to `MEMORY.md` § WIP index
4. Do **not** grow `SESSION.md` with project state

### WIP body — active sections vs History

| Active body (pickup) | History (archive context) |
|----------------------|---------------------------|
| Forward-looking spec — what we are building | Shipped milestones, superseded drafts, investigation logs |
| Tables for contracts, writers, datasets, routes | "Why we renamed X" retrospectives |
| Checklists tied to current phase | Problem statements that motivated a pivot |

**Avoid in active design/spec sections:** `Problem:`, `Decision (date):`, `Supersedes:`, preferred-vs-alternative debates, and inline TODO line references. State the target design; move old framing to **History** when it still matters for archaeology.

**Reference** may hold stable contracts still in force (prune rules, key paths). **Locked decisions** tables belong there or in spec sections as facts — not as narrative pivots.

---

## WIP file frontmatter

Every `memory/wip_*.md` opens with short YAML — pickup metadata for agents and humans. **Bump `updated`** on every meaningful edit (grooming, phase change, checkbox progress, decision lock).

**Phase arc** — must match `.agents/README.md` § Full CRY! WIP cycle:

```
design ──▶ create ◀──▶ refactor ◀──▶ yield ──▶ shipped
              └──────── loop ────────┘
```

| WIP `phase` | Meaning |
|-------------|---------|
| **design** | Blueprint only — scope, architecture, TODO grooming; **no product code** |
| **create** | Full CRY! **Create** — scaffolding, first implementation |
| **refactor** | Full CRY! **Refactor** — sculpt, align conventions, WIP bleeds with code |
| **yield** | Full CRY! **Yield** — ready for / awaiting first-user validation |
| **shipped** | Cycle complete — set before archive; then move to `memory/.archive/` |

---

## Yield checkpoint (agent checklist)

Before {{USER_WHAT_TO_CALL}} yields or before session close on WIP work:

- [ ] WIP frontmatter — `updated` today; `phase`, `loop`, and `next_yield` reflect reality (pickup reads e.g. **yield 2**)
- [ ] WIP checkboxes reflect what actually shipped
- [ ] `MEMORY.md` status + active next step updated
- [ ] Code log entry if session produced user-visible progress (`skills/code-log-entries/SKILL.md`)
- [ ] New backlog from session appended to `memory/TODO.md` (not duplicated into WIP unless in scope)

---

## Gotchas

- **No brittle TODO links** — never cite TODO line numbers or heading anchors from a WIP; search by topic only
- **No circle references** — WIPs point to TODO generically; TODO may name a WIP **file** but not "§ Section" inside it
- **Design = spec, not debate** — active sections describe the target system; problem/decision retrospectives live in **History**
- **WIP is not ground truth until shipped** — code + `SHIPPED_MILESTONES.md` win
- **Never delete WIPs** — archive to `memory/.archive/`
- **Plan before multi-file code changes** — `SOUL.md` Coding Protocols; yield before stacking the next CREATE cycle
- Grooming is **documentation only** unless {{USER_WHAT_TO_CALL}} explicitly asks for code changes in the same session

---

## Related harness files

| File | Role |
|------|------|
| `SESSION.md` | WIP cycle summary + session start/close |
| `memory/full-cry-sdlc/Full_CRY_Overview.md` | Full CRY! methodology + portable harness overview |
| `../README.md` | Human-facing harness guide — **canonical WIP lifecycle diagram** |
| `skills/code-log-entries/SKILL.md` | Yield / session-close code log |
| `memory/CODING_PRINCIPLES.md` | Coding preferences for this project; refactor alignment guide |
| `memory/SHIPPED_MILESTONES.md` | Close-out permanent record |
