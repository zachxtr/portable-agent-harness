# SESSION.md — {{AGENT_DISPLAY_NAME}} Session Guide

*This file is for the agent. If you are a human, see [README.md](../README.md).*

---

## Standing rule

> **Present a plan and wait for approval before making any code change** — unless {{USER_WHAT_TO_CALL}} has explicitly waived this for the task.
> Show what, where, and why. Then wait.

---

## Separation of concerns

| File | Purpose |
|------|---------|
| **`SESSION.md`** | **How** to run a session. Standing rules only. **No project state, no next steps.** |
| **`MEMORY.md`** | **What** is true now — status, in progress, active next step, topic index, WIP index. |
| **`code-log/code-log-YYYYMMDD.md`** | Human-readable session outcomes (non-technical). |
| **`memory/TODO.md`** | Cross-cutting backlog — Active Backlog, domain concepts, Potential, Ideas dump. |
| **`memory/wip_*.md`** | Scoped initiative plans — one CRY work slice at a time. |

Do not duplicate MEMORY in SESSION. Session narrative belongs in **MEMORY.md** and/or the code log.

---

## Harness guide

**Layers:** procedural (this file) → pickup (`MEMORY.md`) → depth (`memory/*.md`, `skills/*/SKILL.md`) → narrative (`code-log/`).

**Core files** (paths relative to `myAgent/`):

| File | Layer | Load when |
|------|-------|-----------|
| `SESSION.md` | Procedure | Every session — start and close |
| `MEMORY.md` | Pickup snapshot | Every session start — **first read** |
| `IDENTITY.md` | Persona | Every session start |
| `SOUL.md` | Operating principles | Every session start |
| `USER.md` | Human profile | Every session start |
| `memory/TODO.md` | Backlog | Planning or prioritizing |
| `memory/*.md` (root) | Project depth | When task matches MEMORY topic index |
| `memory/<framework>/` | Full CRY!, DX | Process or data-journey work |
| `memory/wip_*.md` | CRY work-slice plans | When MEMORY or task references one |
| `skills/*/SKILL.md` | Recurring procedures | Before that task (Skills Index) |
| `../code-log/code-log-YYYYMMDD.md` | Session history | Session start; session close when writing |

**`memory/` layout**

| Location | Contents | Session cleanup |
|----------|----------|-----------------|
| **`memory/` root** | Project topics, `wip_*.md` | Yes — trim per session close |
| **`memory/<framework>/`** | Full CRY!, DX | **No** — stable methodology |
| **`memory/.archive/`** | Retired WIPs and docs | No — historical only |

**WIP rules (`wip_*.md`)**

- Full CRY! WIP cycle: **design → create ↔ refactor ↔ yield → shipped** (see [README.md](../README.md) § Full CRY! WIP cycle).
- Load **`skills/wip-management/SKILL.md`** before starting, grooming, yielding, or closing out a WIP.
- A WIP plan is a **draft** — read for implementation context; not ground truth until shipped.
- When shipped: append `memory/SHIPPED_MILESTONES.md`, set `phase: shipped`, move WIP to `memory/.archive/`, update MEMORY WIP index.

**`TODO.md` rules**

- Four tiers: **Active Backlog** (`- [ ]` only, no bold in item text), **domain concepts**, **Potential new functionality**, **Ideas dump**.
- WIP owns scoped implementation; TODO owns cross-cutting and unscoped ideas. See wip-management skill for boundary rules.

**`MEMORY.md` rules**

- Keep short: status, active next step, in progress (~15 bullets max), topic index, WIP index.
- At session close: update status + next step.
- **Do not** load `SHIPPED_MILESTONES.md` at session start unless the task needs shipped history.

---

## Session start

1. **Read `MEMORY.md`** — status, active next step, WIP index, topic index
2. **Read `IDENTITY.md`**, **`SOUL.md`**, **`USER.md`**
3. **Read the most recent code log** (`../code-log/code-log-YYYYMMDD.md`)
4. **Load skill(s)** when a recurring task applies (see Skills Index)
5. **Load `memory/` files** only if the goal matches MEMORY's index
6. **Restate the goal** in one sentence — confirm with {{USER_WHAT_TO_CALL}} if unclear

---

## Session close

1. **Update `MEMORY.md`** — last session closed, in progress, active next step; add index rows for new memory files; update WIP index if cycle position changed
2. **Append `memory/SHIPPED_MILESTONES.md`** when significant work shipped (do not grow MEMORY with changelog bullets)
3. **Update or create the code log** — read `skills/code-log-entries/SKILL.md` first
4. **Update `memory/TODO.md`** — capture new backlog items (correct tier; bump frontmatter `updated`)

**Do not** add "Last Session Closed" sections to this file.

---

## Skills index

| Skill | Path | Use when |
|-------|------|----------|
| Code Log Entries | `skills/code-log-entries/SKILL.md` | Document or update the session progress log |
| WIP Management | `skills/wip-management/SKILL.md` | Start/close WIP work, TODO grooming, yield checkpoint, archive shipped WIPs |
