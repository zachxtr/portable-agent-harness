# SESSION.md — {{AGENT_DISPLAY_NAME}} Session Guide

*This file is for the agent. If you are a human, see [README.md](../README.md).*

---

## Standing Rule

> **Always present a plan and wait for approval before making any code change.**  
> No exceptions — not for single-file changes, not for "obvious" fixes, not for small edits.  
> Show what, where, and why. Then wait.

---

## Separation of concerns

| File | Purpose |
|------|---------|
| **`SESSION.md`** | **How** to run a session (start/close protocol, skills index, depth pointers). Standing rules only. **No project state, no "last session" narrative, no next steps.** |
| **`MEMORY.md`** | **What** is true now — status, in progress, active next step, topic index with "load when." **Single source of truth** for pickup. |
| **`code-log/code-log-YYYYMMDD.md`** | Client-readable session outcomes (non-technical). |
| **`memory/TODO.md`** | Backlog items surfaced during work. |

Do not duplicate MEMORY content in SESSION.md. If something belongs in "what we did / what's next," it goes in **MEMORY.md** (and optionally the code log), not here.

---

## Where depth lives

Do not duplicate content from these files in SESSION.md — load them when needed.

| Need | Read |
|------|------|
| Harness layout (human overview) | [`../README.md`](../README.md) |
| Frameworks (Full CRY!, DX) | `SOUL.md` § Working frameworks |
| WIP cycle, TODO grooming, archive | `skills/wip-management/SKILL.md` |
| Project state + topic index | `MEMORY.md` |
| Code log format | `skills/code-log-entries/SKILL.md` |
| Stack shape and conventions | `memory/ARCHITECTURE_CONCEPTS.md` · `memory/CODING_PRINCIPLES.md` |

---

## Session Start

Run through these steps at the start of every session before taking any action:

1. **Read `MEMORY.md`** — current status, active next step, topic index
2. **Read `IDENTITY.md`** — who you are
3. **Read `SOUL.md`** — how you operate
4. **Read `USER.md`** — who {{USER_WHAT_TO_CALL}} is and how they work
5. **Skim `memory/CODING_PRINCIPLES.md` and `memory/ARCHITECTURE_CONCEPTS.md`** — conventions and stack shape
6. **Read the most recent code log** (`../code-log/code-log-YYYYMMDD.md`) — client-facing continuity
7. **Load skill(s)** from `skills/` when a recurring task applies (see Skills Index) — include `skills/wip-management/SKILL.md` for WIP work or TODO grooming
8. **Load `memory/` files** only if the goal matches their "load when" row in `MEMORY.md`
9. **Restate the goal** in one sentence — confirm with {{USER_WHAT_TO_CALL}} if unclear

---

## Session Close

Before ending any session:

1. **Update `MEMORY.md`** — last session closed, verified items (if any), in progress, active next step; add index rows for new **project** or **WIP** files at `memory/` root
2. **Append `memory/SHIPPED_MILESTONES.md`** when significant work shipped (do not grow MEMORY with changelog bullets)
3. **Update or create the code log:**
   - Read `skills/code-log-entries/SKILL.md` — follow its format and audience rules exactly
   - Run `git log --oneline --format="%H %ad %s" --date=short -10` — use the commit date as the log date when commits exist; otherwise use the session calendar day and note uncommitted work
   - Read the most recent existing code log for prior state and next steps context
   - Write to `../code-log/code-log-YYYYMMDD.md` (not inside `myAgent/memory/`)
   - Client-readable bullets only — what was accomplished and why it matters; no file names, no code snippets, no jargon
4. **Update `memory/TODO.md`** — capture new backlog items from the session

**Do not** add "Last Session Closed" sections to this file.

---

## Skills Index

| Skill | Path | Use When |
|-------|------|----------|
| Code Log Entries | `skills/code-log-entries/SKILL.md` | Document or update the session progress log |
| WIP Management | `skills/wip-management/SKILL.md` | Full CRY! WIP cycle, TODO grooming, WIP close-out |
| README Creation | `skills/readme-creation/SKILL.md` | Write or refactor service READMEs as conceptual guides (anti-drift) |

---
