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
| **`MEMORY.md`** | **What** is true now — status, in progress, active next step, topic index. |
| **`code-log/code-log-YYYYMMDD.md`** | Human-readable session outcomes (non-technical). |
| **`memory/TODO.md`** | Backlog surfaced during work. |

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
| **`memory/.archive/`** | Retired docs | No — historical only |

**WIP rules (`wip_*.md`)**

- A WIP plan is a **CRY work slice** — scoped Create → Refactor → Yield unit (see `docs/wip-work-plans.md` in the distribution repo or your copy after install).
- Read for implementation context; not ground truth until yielded.
- When shipped, archive to `memory/.archive/` and update MEMORY + code log.

**`MEMORY.md` rules**

- Keep short: status, active next step, in progress (~15 bullets max), topic index.
- At session close: update status + next step.

---

## Session start

1. **Read `MEMORY.md`** — status, active next step, topic index
2. **Read `IDENTITY.md`**, **`SOUL.md`**, **`USER.md`**
3. **Read the most recent code log** (`../code-log/code-log-YYYYMMDD.md`)
4. **Load skill(s)** when a recurring task applies
5. **Load `memory/` files** only if the goal matches MEMORY’s index
6. **Restate the goal** in one sentence — confirm with {{USER_WHAT_TO_CALL}} if unclear

---

## Session close

1. **Update `MEMORY.md`** — last session closed, in progress, active next step; add index rows for new memory files
2. **Update or create the code log** — read `skills/code-log-entries/SKILL.md` first
3. **Update `memory/TODO.md`** — capture new backlog items

**Do not** add “Last Session Closed” sections to this file.

---

## Skills index

| Skill | Path | Use when |
|-------|------|----------|
| Code Log Entries | `skills/code-log-entries/SKILL.md` | Document or update the session progress log |
