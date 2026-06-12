# {{PROJECT_NAME}} — Agent Harness

> Maintained by [Data Finn](https://datafinn.com).  
> Built on **[Full CRY!](#methodology--full-cry)** — Data Finn's AI-age development methodology (see below).  
> Licensed under the MIT open-source [LICENSE](./LICENSE) — the patterns and methodology are freely adaptable for other projects.

---

## Overview

This folder is the **agent harness** for {{PROJECT_NAME}} — a structured workspace that allows the AI development agent to maintain continuity between sessions, follow consistent procedures, and pick up exactly where work left off.

Think of it as the agent's **onboarding kit and working memory**. Without it, every session starts from zero. With it, the agent knows the project, the people, and the current state of work before the first message is sent.

---

## Methodology — Full CRY!

> **Create without fear, refactor relentlessly, yield to reality** — with aligned principles that keep the AI army pointed at the right target.

**Full CRY!** (Create → Refactor → Yield) is an AI-age development cycle: move fast with an agent army, sculpt the result into clean code, then **use the system as its first user** before stacking more work on a shaky foundation.

| Pillar | In one line |
|--------|-------------|
| **Create** | Build and experiment fast — exploration is cheap when agents can scaffold and rebuild quickly. |
| **Refactor** | Keep code clear and consistent — rename, split, and propagate until it reads like a good essay. |
| **Yield** | Run it locally, click the UI, check the data — validate before the next CREATE cycle. |

This harness encodes Full CRY! in practice: session safeguards, coding protocols in `SOUL.md`, yield checkpoints via code logs, and depth files loaded only when needed. Full treatise (aligned principles, gotchas, origin story): [`myAgent/memory/full-cry-sdlc/Full_CRY_Overview.md`](./myAgent/memory/full-cry-sdlc/Full_CRY_Overview.md).

### Full CRY! WIP cycle

Work runs as a **WIP cycle** on `myAgent/memory/wip_<topic>.md`:

```
design ──▶ create ◀──▶ refactor ◀──▶ yield ──▶ shipped
              └──── loop 1, 2, 3… ────┘
```

**Procedure (agents):** [`myAgent/skills/wip-management/SKILL.md`](./myAgent/skills/wip-management/SKILL.md) — TODO grooming, frontmatter, close-out.

| WIP phase | What happens |
|-----------|----------------|
| **Design** | Scope, architecture, decisions, TODO grooming — **no product code** yet |
| **Create** | Full CRY! Create — scaffold, first implementation (WIP bleeds into code) |
| **Refactor** | Full CRY! Refactor — sculpt, align `CODING_PRINCIPLES.md`, update WIP checkboxes |
| **Yield** | Full CRY! Yield — {{USER_WHAT_TO_CALL}} uses the system as first user; code log + `MEMORY.md` |
| **Shipped** | Append `SHIPPED_MILESTONES.md`, archive WIP, remove from active index |

### TODO.md and WIP cycle

**WIP vs `TODO.md`:** WIP owns scoped implementation; `TODO.md` holds Active Backlog, domain concepts, **Potential new functionality**, and an Ideas dump. As ideas mature, run work sprints using the **wip-management** skill.

```
  CREATE ──bleeds──▶ REFACTOR ──bleeds──▶ YIELD
         ▲               │                   │
         └──── loop ─────┴───────── loop ────┘
                (repeat until prosperous)
                          │
                          ▼
              SHIPPED_MILESTONES + archive WIP
```

| Full CRY! pillar | Harness artifacts |
|------------------|-------------------|
| **Create** | `wip_<topic>.md` (YAML frontmatter + plan); index row in `MEMORY.md` |
| **Refactor** | Code + WIP checkbox updates |
| **Yield** | `code-log/code-log-YYYYMMDD.md`; `MEMORY.md` status |

A WIP is a **draft**. `SHIPPED_MILESTONES.md` and git history are **truth**. The code log is how stakeholders and future sessions see *why* it mattered without reading diffs.

---

## Quick Start

1. Open a new chat in your AI-enabled IDE (e.g. Cursor)
2. Add **`@.agents/myAgent`** (or your renamed agent folder) as context
3. Say **`Please load context`**

The agent runs **Session Start** from `myAgent/SESSION.md` and replies with status + active next step.

---

## Agent Files

Each agent has five core files under `myAgent/` (or additional agent folders you add). Each owns a distinct scope — no overlap.

| File | Scope | Changes |
|------|-------|---------|
| `SESSION.md` | **Procedures** — session start/close, skills index | Occasionally |
| `IDENTITY.md` | **Persona** — who the agent is | Rarely |
| `SOUL.md` | **Operating principles** — how the agent thinks and works | Rarely, intentionally |
| `USER.md` | **Human profile** — who {{USER_WHAT_TO_CALL}} is | As needed |
| `MEMORY.md` | **Current state** — pickup snapshot; first read every session | Every session |

---

## Memory Files

**`MEMORY.md`** — project pickup snapshot (status, next step, topic index). **`SOUL.md`** — operating principles and pointers to methodology subfolders.

| Location | Contents |
|----------|----------|
| `memory/TODO.md` | Active Backlog, domain concepts, Potential new functionality, Ideas dump (YAML frontmatter) |
| `memory/*.md` (root) | Project topics (architecture, conventions) |
| `memory/wip_*.md` | Active work plans — YAML frontmatter (`phase`, `loop`, `next_yield`) |
| `memory/SHIPPED_MILESTONES.md` | Permanent record of shipped work |
| `memory/.archive/` | Retired WIPs and superseded drafts |
| `memory/full-cry-sdlc/` | **Full CRY!** methodology |
| `memory/data-experience-journey/` | Data Experience (DX) |

Session procedures (start/close, skills index): `myAgent/SESSION.md`.

---

## Skills

Reusable agent procedures live in `myAgent/skills/`. Load the relevant skill before performing any recurring task.

| Skill | Path | Use When |
|-------|------|----------|
| Code Log Entries | `myAgent/skills/code-log-entries/SKILL.md` | Writing or updating the session progress log |
| WIP Management | `myAgent/skills/wip-management/SKILL.md` | Full CRY! WIP cycle, TODO grooming, archiving shipped WIPs |

---

## Code Logs

Progress logs live in `code-log/code-log-YYYYMMDD.md`. Written for a **non-technical audience** — what was done, why it matters, what's next. No file names, no code snippets, no jargon.

---

## Folder Structure

```
.agents/
├── README.md                        ← this file (human-facing)
├── LICENSE
├── code-log/                        ← session progress logs
│   └── code-log-YYYYMMDD.md
└── myAgent/                         ← agent workspace
    ├── SESSION.md                   ← session start/close procedures and skills index
    ├── IDENTITY.md                  ← who the agent is
    ├── SOUL.md                      ← how the agent thinks and operates
    ├── USER.md                      ← about {{USER_WHAT_TO_CALL}}
    ├── MEMORY.md                    ← current project state + memory file map
    ├── memory/                      ← topic docs, architecture notes, WIP plans
    │   ├── TODO.md
    │   ├── CODING_PRINCIPLES.md
    │   ├── ARCHITECTURE_CONCEPTS.md
    │   ├── SHIPPED_MILESTONES.md
    │   ├── wip_*.md
    │   └── .archive/
    └── skills/                      ← reusable agent procedures
        ├── code-log-entries/
        │   └── SKILL.md
        └── wip-management/
            └── SKILL.md
```

---

## Adding Agents

The harness supports multiple agents. Add another named folder alongside `myAgent/` with the same five-file structure, scoped to its domain. Agents can share the `code-log/` folder.
