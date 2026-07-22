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

### Full CRY! WIP cycle

Work runs as a **WIP cycle** on `myAgent/memory/wip_<topic>.md`:

```
design ──▶ create ◀──▶ refactor ◀──▶ yield ──▶ shipped
              └──── loop 1, 2, 3… ────┘
```

**Procedure (agents):** [`myAgent/skills/wip-management/SKILL.md`](./myAgent/skills/wip-management/SKILL.md)

| WIP phase | What happens |
|-----------|----------------|
| **Design** | Scope, architecture, decisions — **no product code** yet |
| **Create** | Scaffold, first implementation |
| **Refactor** | Sculpt, align `CODING_PRINCIPLES.md` |
| **Yield** | User validates; code log + `MEMORY.md` |
| **Shipped** | Append `SHIPPED_MILESTONES.md`, archive WIP |

WIP files use **dates-only YAML** (`created`, `updated`). Phase and loop live in the **body Status** section.

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
| `myAgent/memory/TODO.md` | Active Backlog, domain concepts, potential, ideas dump |
| `myAgent/memory/*.md` (root) | Project topics, conventions, shipped history |
| `myAgent/memory/wip_*.md` | Active WIPs — copy `wip_example-topic.md` to start |
| `myAgent/memory/full-cry-sdlc/` | Full CRY! methodology |
| `myAgent/memory/data-experience-journey/` | Data Experience (DX) |
| `myAgent/memory/.archive/` | Retired WIPs |

---

## Skills

| Skill | Path | Use When |
|-------|------|----------|
| Code Log Entries | `myAgent/skills/code-log-entries/SKILL.md` | Session progress log |
| WIP Management | `myAgent/skills/wip-management/SKILL.md` | WIP cycle, TODO grooming, archive |
| README Creation | `myAgent/skills/readme-creation/SKILL.md` | Service README conceptual guides |

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
    │   ├── TODO.md
    │   ├── SHIPPED_MILESTONES.md
    │   ├── wip_*.md
    │   └── .archive/
    └── skills/
        ├── code-log-entries/
        ├── wip-management/
        └── readme-creation/
```

Session guide: `myAgent/SESSION.md`
