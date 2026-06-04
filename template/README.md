# Agent harness — {{PROJECT_NAME}}

> Portable coding agent harness · **Full CRY!** (Create → Refactor → Yield)  
> Maintained using [portable-agent-harness](https://github.com/zachxtr/portable-agent-harness)

This folder (`.agents/`) is the **agent harness** for this codebase — structured workspace so the development agent maintains continuity between sessions.

---

## Quick start

1. Open a new chat in your AI-enabled IDE (e.g. Cursor)
2. Add `@.agents/myAgent` as context
3. Send:

> *Hello! Please load context*

The agent reads session procedures, current memory, and the latest code log, then summarizes status and the active next step.

---

## Methodology — Full CRY!

| Pillar | In one line |
|--------|-------------|
| **Create** | Build and experiment fast |
| **Refactor** | Keep code clear and consistent |
| **Yield** | Use the system as first user before stacking more work |

Full treatise: [`myAgent/memory/full-cry-sdlc/Full_CRY_Overview.md`](./myAgent/memory/full-cry-sdlc/Full_CRY_Overview.md)

---

## Agent files

Each agent has five core files under `myAgent/` (or additional agent folders you add):

| File | Scope |
|------|--------|
| `SESSION.md` | Session procedures and harness guide |
| `IDENTITY.md` | Persona |
| `SOUL.md` | Operating principles |
| `USER.md` | Human profile |
| `MEMORY.md` | Current project state — read first every session |

---

## Memory & WIP plans

| Location | Contents |
|----------|----------|
| `myAgent/memory/*.md` | Project topics, conventions, architecture |
| `myAgent/memory/wip_*.md` | CRY work-slice plans (rename `wip_TopicX_work_plan.md` to start) |
| `myAgent/memory/full-cry-sdlc/` | Full CRY! methodology |
| `myAgent/memory/data-experience-journey/` | Data Experience (DX) |
| `myAgent/memory/.archive/` | Retired docs |

---

## Skills

| Skill | Path |
|-------|------|
| Code Log Entries | `myAgent/skills/code-log-entries/SKILL.md` |

---

## Code logs

Progress logs: `code-log/code-log-YYYYMMDD.md` — written for a **non-technical audience** (what was done, why it matters, what's next). No file names or code snippets in bullets.

---

## Folder structure

```
.agents/
├── README.md
├── code-log/
│   └── code-log-YYYYMMDD.md
└── myAgent/
    ├── SESSION.md
    ├── IDENTITY.md
    ├── SOUL.md
    ├── USER.md
    ├── MEMORY.md
    ├── memory/
    └── skills/
```

Session guide: `myAgent/SESSION.md`
