# SESSION.md — Joshua's Session Guide

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
| **`SESSION.md`** | **How** to run a session (harness guide, start/close protocol, skills index). Standing rules only. **No project state, no “last session” narrative, no next steps.** |
| **`MEMORY.md`** | **What** is true now — status, in progress, active next step, topic index with “load when.” **Single source of truth** for pickup. |
| **`code-log/code-log-YYYYMMDD.md`** | Client-readable session outcomes (non-technical). |
| **`memory/TODO.md`** | Backlog items surfaced during work. |

Do not duplicate MEMORY content in SESSION.md. If something belongs in “what we did / what’s next,” it goes in **MEMORY.md** (and optionally the code log), not here.

---

## Joshua harness guide

**Layers:** procedural (this file) → pickup snapshot (`MEMORY.md`) → depth (`memory/*.md`, `skills/*/SKILL.md`) → client narrative (`code-log/`).

**Core files** (paths relative to `joshua/`):

| File | Layer | Load when |
|------|-------|-----------|
| `SESSION.md` | Procedure | Every session — start and close |
| `MEMORY.md` | Pickup snapshot | Every session start — first read |
| `IDENTITY.md` | Persona | Every session start |
| `SOUL.md` | Operating principles | Every session start |
| `USER.md` | Human profile | Every session start |
| `memory/TODO.md` | Backlog | Planning or prioritizing |
| `memory/*.md` (root) | Project topic depth | When task matches “load when” in `MEMORY.md` § Project |
| `memory/<framework>/` | Full CRY!, DX | `SOUL.md` § Working frameworks; when process/DX applies |
| `skills/*/SKILL.md` | Recurring procedures | Before that task (see Skills Index) |
| `../code-log/code-log-YYYYMMDD.md` | Session history (client) | Session start; session close when writing |

**`memory/` layout**

| Location | Contents | Session cleanup |
|----------|----------|-----------------|
| **`memory/` root** (`*.md`, `wip_*.md`) | Policy Command project topics | Yes — trim/update per session close rules |
| **`memory/<framework>/`** (e.g. `full-cry-sdlc/`, `data-experience-journey/`) | **Full CRY!**, DX — transferable methodology | **No** — stable; primary pointer in `SOUL.md` |
| **`memory/.archive/`** | Retired docs | No |

**`memory/` rules**

- Each depth file should be self-contained; open with a clear summary (title + first paragraph).
- **Framework subfolders** — load when doing process/DX work; do not duplicate into `MEMORY.md`.
- **WIP** (`wip_*.md`) = design drafts — read for implementation context, not ground truth.
- **Archive** (`.archive/`) = historical only.
- **Do not** load `SHIPPED_MILESTONES.md`, `UI_TOKENS.md`, or `OPS_BEDROCK.md` at session start unless the task needs them.

**`MEMORY.md` rules**

- Keep short: current status, active next step, in progress (~15 bullets max), topic index.
- Index **project** files at `memory/` root; frameworks are in the index for lookup but **SOUL** owns the pointer.
- Move shipped history, UI tokens, and ops notes to the reference files listed in MEMORY’s index.
- At session close: update status + next step; append significant ships to `memory/SHIPPED_MILESTONES.md`.

**PA parallel (product agent, S3 `persona/`)** — for cross-reference when working on assistant memory: long-term `MEMORY.md`, rolling index `SESSIONMEMORY.md` → `ROLLINGMEMORY.md`, deep notes `persona/memory/*.md`. Canonical catalog: `memory/POLICY_ASSISTANT_AGENT_HARNESS.md`.

---

## Session Start

Run through these steps at the start of every session before taking any action:

1. **Read `MEMORY.md`** — current status, active next step, topic index
2. **Read `IDENTITY.md`** — who you are
3. **Read `SOUL.md`** — how you operate
4. **Read `USER.md`** — who Zach is and how he works
5. **Read the most recent code log** (`../code-log/code-log-YYYYMMDD.md`) — client-facing continuity
6. **Load skill(s)** from `skills/` when a recurring task applies (see Skills Index)
7. **Load `memory/` files** only if the goal matches their “load when” row in `MEMORY.md`
8. **Restate the goal** in one sentence — confirm with Zach if unclear

---

## Session Close

Before ending any session:

1. **Update `MEMORY.md`** — last session closed, verified items (if any), in progress, active next step; add index rows for new `memory/` files
2. **Append `memory/SHIPPED_MILESTONES.md`** when significant work shipped (do not grow MEMORY with changelog bullets)
3. **Update or create the code log:**
   - Read `skills/code-log-entries/SKILL.md` — follow its format and audience rules exactly
   - Run `git log --oneline --format="%H %ad %s" --date=short -10` — use the commit date as the log date when commits exist; otherwise use the session calendar day and note uncommitted work
   - Read the most recent existing code log for prior state and next steps context
   - Write to `../code-log/code-log-YYYYMMDD.md` (not inside `joshua/memory/`)
   - Client-readable bullets only — what was accomplished and why it matters; no file names, no code snippets, no jargon
4. **Update `memory/TODO.md`** — capture new backlog items from the session

**Do not** add “Last Session Closed” sections to this file.

---

## Skills Index

| Skill | Path | Use When |
|-------|------|----------|
| Code Log Entries | `skills/code-log-entries/SKILL.md` | Document or update the session progress log |
| Query Local User Agent Workspace | `skills/query-local-user-agent-workspace/SKILL.md` | Inspect S3-backed agent workspace files for a user |
| README Creation | `skills/readme-creation/SKILL.md` | Write or refactor service READMEs as conceptual guides (anti-drift) |

---
