---
name: wip-management
description: "Full CRY! WIP lifecycle — create, yield, archive memory/wip_*.md files; prune TODO.md when grooming. Use when starting or closing WIP work or keeping backlog clean."
license: MIT — Copyright © 2026 Data Finn (datafinn.com)
compatibility: Portable agent harness (.agents/myAgent/).
allowed-tools: read_file write_file glob grep shell_command
---

# WIP Management — Full CRY! Cycle

Operational procedures for **`memory/wip_<topic>.md`** — one working blueprint per feature or initiative. Methodology: `memory/full-cry-sdlc/Full_CRY_Overview.md`. Session hook: `SESSION.md` § Session Start step 7.

**Pickup lives in the WIP body + `MEMORY.md` index** — not in heavy YAML metadata.

---

## When to use

- Starting, implementing, yielding, or archiving a WIP
- Updating `MEMORY.md` WIP index rows
- **TODO grooming** — prune backlog, absorb scoped items into a WIP (when {{USER_WHAT_TO_CALL}} asks or at close-out)

---

## Full CRY! cycle

```
design ──▶ create ◀──▶ refactor ◀──▶ yield ──▶ shipped
              └──── loop 1, 2, 3… ────┘
```

| Phase | Meaning |
|-------|---------|
| **design** | Blueprint — scope, decisions, **no product code** |
| **create** | First implementation |
| **refactor** | Sculpt, align `CODING_PRINCIPLES.md`, cleanup |
| **yield** | {{USER_WHAT_TO_CALL}} validates as first user — don't stack unvalidated features |
| **shipped** | Cycle complete → archive |

Track phase and loop in the **body** (status line or table) — update when something meaningful changes. Pickup reads e.g. **yield 2**, **refactor 3**.

**Close-out:** append `SHIPPED_MILESTONES.md` → bump `updated` → move WIP to `memory/.archive/` (never delete) → update `MEMORY.md` → **groom TODO** (remove absorbed/stale items).

**Truth:** WIP = draft until shipped · code + milestones + git = shipped truth.

---

## WIP file shape

### Frontmatter (optional, minimal)

Two dates only — no `status`, `phase`, or nested `wip:` blocks on new files.

```yaml
---
created: 2026-06-25
updated: 2026-06-25
---
```

| Field | When to set |
|-------|-------------|
| `created` | Once, when the file is created |
| `updated` | Session close, phase change, or substantive spec edit — **not** every checkbox tick |

Pickup: **body Status line** + **`MEMORY.md` index**, not frontmatter.

### Body sections (typical order)

1. **Title + cross-references** — key paths, related WIPs, milestones
2. **Status** — one line or small table: phase, loop, next yield (human pickup)
3. **Product direction ({{USER_WHAT_TO_CALL}}, YYYY-MM-DD)** — locked decisions; principles; out-of-scope
4. **Spec / phases / checklists** — forward-looking plan
5. **Open questions** — awaiting {{USER_WHAT_TO_CALL}}
6. **{{USER_WHAT_TO_CALL}}'s Thoughts** — raw capture (see below)

**Active body = target design.** Avoid debate archaeology in spec sections; use **History** only when needed.

---

## {{USER_WHAT_TO_CALL}}'s Thoughts (required section)

Every WIP ends with this block.

```markdown
## {{USER_WHAT_TO_CALL}}'s Thoughts

> **{{USER_WHAT_TO_CALL}} adds rows here** — raw notes only. **Agent:** when a note is folded into the body above, prefix that **existing row** with `DONE:` — never add new rows to this section.

DONE: Example note already captured in Product direction above.

New raw note goes here as a plain line.
```

**Rules**

- {{USER_WHAT_TO_CALL}} adds **plain lines** — fragments OK
- Agent **never** adds synthesized rows here when folding into the body
- Absorbed thought → prefix **same line** with `DONE:`
- Open questions → **Open questions** section (unless {{USER_WHAT_TO_CALL}} wrote them here first)

**Product direction** = polished output of {{USER_WHAT_TO_CALL}}'s Thoughts + conversation (date-stamped when locked).

---

## WIP vs TODO

| `wip_<topic>.md` | `TODO.md` |
|------------------|-----------|
| One scoped initiative | Cross-cutting backlog, domain notes, Ideas dump |
| Checkboxes for **this** effort | Actionable `- [ ]` not tied to one WIP |

Do not duplicate the same checklist in both files. Do not expand WIP scope during TODO grooming.

---

## TODO grooming — keep `TODO.md` clean

**Goal: prune noise**, not catalog everything in a WIP. Run when {{USER_WHAT_TO_CALL}} asks, at WIP close-out, or when TODO feels stale.

### 1. Prune (default action)

- **Shipped / done** — remove; point to `SHIPPED_MILESTONES.md` or git if useful
- **Absorbed into active WIP** — remove from TODO (content lives in WIP now)
- **Stale or duplicate** — one home only; merge or delete
- **Vague / unscoped** — demote to **Ideas dump** (plain lines) or delete if worthless

### 2. Promote (only when grooming *for* a specific WIP)

- Item clearly **in that WIP's scope** → move into WIP phases/checklist; **remove from TODO**

### 3. Leave alone

- Related but **different initiative** or cross-cutting bug not owned by this WIP
- Domain concept notes that aren't actionable yet

### 4. Hygiene

- Search by **topic keywords** — no line numbers or heading anchors
- Bump TODO frontmatter `updated` **only when TODO changed**
- Active Backlog items: `- [ ]` only, **no bold** inside item text

---

## Starting a new WIP

1. Confirm topic with {{USER_WHAT_TO_CALL}} if ambiguous
2. Create `memory/wip_<topic>.md` with `created` / `updated` (today)
3. Body: **Status: design** + Product direction stub or {{USER_WHAT_TO_CALL}}'s Thoughts
4. Add row to `MEMORY.md` § WIP index
5. Do not grow `SESSION.md` with project state

---

## Yield checkpoint

- [ ] Body **Status** / checkboxes match reality
- [ ] `MEMORY.md` index updated
- [ ] TODO groomed if session closed scoped work (prune absorbed/stale items)
- [ ] Code log if user-visible progress (`skills/code-log-entries/SKILL.md`)

---

## Gotchas

- Plan before multi-file code changes (`SOUL.md`)
- Never delete WIPs — archive only
- Grooming is documentation unless {{USER_WHAT_TO_CALL}} asks for code in the same session

---

## Related files

| File | Role |
|------|------|
| `SESSION.md` | Session start/close |
| `memory/TODO.md` | Backlog — keep pruned |
| `MEMORY.md` | WIP index (primary pickup) |
| `memory/SHIPPED_MILESTONES.md` | Close-out record |
| `../README.md` | Canonical lifecycle diagram |
