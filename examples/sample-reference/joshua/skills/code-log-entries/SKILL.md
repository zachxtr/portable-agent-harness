---
name: code-log-entries
description: "Maintain the Policy Command development code log. Use when the user asks to document, update, or create a code log entry. Writes client-readable progress summaries into dated markdown files under code-log/. Each session entry captures what was completed, what is in progress, and what the next steps are — in plain language suitable for a non-technical audience."
license: MIT — Copyright © 2026 Data Finn (datafinn.com)
compatibility: Policy Command codebase. Requires access to code-log/ and git history.
allowed-tools: read_file write_file shell_command glob
---

## Description

Manages the Policy Command development progress log. Produces dated session entries readable by both the client and the agent (as session memory). Does not write technical developer notes — those belong in git commits and developer docs.

## Instructions

**When to use this skill:**
- User says "update the code log", "document this session", "add to the log", or similar
- At the end of a work session to capture what was accomplished
- At the start of a session to read prior state and establish context

---

**Step 1 — Check git history for today's commits**

Run the following to see what was actually pushed today:

```bash
git -C <repo-root> log --oneline --format="%H %ad %s" --date=short -10
```

Use the commit date as the log file date. Note each commit hash and message — reference the most relevant ones in the entry so the log is traceable to source. Do NOT list file names in the log entry; the commit diff is the authoritative file record.

---

**Step 2 — Determine the correct file**

- File lives at: `_dev/code-agents/code-log/code-log-YYYYMMDD.md` (relative to repo root)
- If the file exists → append a new `## Session` section
- If the file does not exist → create directory if needed, then create it using the structure below

---

**Step 3 — Read prior log for context**

Before writing, read the most recent existing code log to understand current state, what was in progress, and what the next steps were. This is your memory between sessions.

---

**Step 4 — Write the session entry**

Use this structure:

```
## Session: <short descriptive title>

**Date:** YYYY-MM-DD
**Commits:** `abcd1234` — message, `efgh5678` — message

### Completed
- <outcome bullet — plain language, non-technical audience>
- <outcome bullet>

### In Progress  _(omit section if nothing is in progress)_
- <what was started but not finished>

### Next Steps
- <what happens next session>
```

---

**Audience rules (strictly enforced):**

- Write for a **non-technical reader**, not a developer
- Each bullet describes **what** was accomplished and **why it matters** — never **how**
- **No file lists, error messages, code snippets, or technical jargon** — GitHub has the file diff; this log is for human progress tracking
- Good: "Set up the development agent harness — Joshua can now maintain context between sessions"
- Bad: "Created WAKEUP.md, IDENTITY.md, SOUL.md, USER.md, MEMORY.md in _dev/code-agents/joshua/"
- Commit hashes in the header are fine — they are a traceability link, not content
- Aim for **3–8 bullets** per section — group small fixes into single outcome bullets

---

**File header (for new files only):**

```markdown
# Policy Command Code Log — YYYY-MM-DD

> Development progress log for Policy Command. Maintained by Data Finn (datafinn.com). Each session captures completed work, current progress, and next steps in language suitable for both stakeholders and development agents.
```

---

**Retroactive entries:**

If documenting work from a prior session, use the date from git history, not today. If a log file for that date already exists, append to it. Add `(documented retroactively on YYYY-MM-DD)` to the session date line.

**One file per calendar day.** Multiple sessions on the same day → multiple `## Session` sections in the same file, in chronological order.

## Gotchas

- Never assume today's date is the correct log date — always verify with `git log`
- Do not put technical detail in the client-visible bullets — it belongs in git commits
- Do not create a new file if one already exists for that date — always append
- Do not list file names in the log — GitHub has the diff; this log is for human progress tracking
- The code log is also agent memory — read it at session start, not just session end
