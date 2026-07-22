# Portable Coding Agent Harness

> Maintained by [Data Finn](https://datafinn.com) as part of development services.  
> Built on **[Full CRY!](#methodology--full-cry)** — Data Finn's AI-age development methodology (see below).
> Licensed under the MIT open-source [LICENSE](./LICENSE) — the patterns and methodology are freely adaptable for other projects.

---

## Overview

This folder is the **agent harness** for the project codebase — a structured workspace that allows the AI development agent (Joshua) to maintain continuity between sessions, follow consistent procedures, and pick up exactly where work left off.

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

This harness encodes Full CRY! in practice: session safeguards, coding protocols in `SOUL.md`, yield checkpoints via code logs, and depth files loaded only when needed. Full treatise (aligned principles, gotchas, origin story): [`joshua/memory/full-cry-sdlc/Full_CRY_Overview.md`](./joshua/memory/full-cry-sdlc/Full_CRY_Overview.md).

### Full CRY! WIP cycle

Work runs as a **WIP cycle** on `joshua/memory/wip_<topic>.md`:

```
design ──▶ create ◀──▶ refactor ◀──▶ yield ──▶ shipped
              └──── loop 1, 2, 3… ────┘
```

**Procedure (agents):** [`joshua/skills/wip-management/SKILL.md`](./joshua/skills/wip-management/SKILL.md) — TODO grooming, frontmatter, close-out.

| WIP phase | What happens |
|-----------|----------------|
| **Design** | Scope, architecture, decisions, TODO grooming — **no product code** yet |
| **Create** | Full CRY! Create — scaffold, first implementation (WIP bleeds into code) |
| **Refactor** | Full CRY! Refactor — sculpt, align `CODING_PRINCIPLES.md`, update WIP checkboxes |
| **Yield** | Full CRY! Yield — Zach uses the system as first user; code log + `MEMORY.md` |
| **Shipped** | Append `SHIPPED_MILESTONES.md`, archive WIP, remove from active index |


### TODO.md and WIP cycle

**WIP vs `TODO.md`:** WIP owns scoped implementation; `TODO.md` holds Active Backlog, domain concepts, **Potential new functionality**, and an Ideas dump. As ideas mature do work sprints using the **wip-management** skill with myAgent.

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
2. Type **`@joshua`** (Cursor rule) and say **`hello`** or **`load context`**
   - Optional: also attach **`@.agents/joshua`** if you want the harness folder in explicit context
3. Joshua runs **Session Start** from `joshua/SESSION.md` and replies with status + active next step

**One-liner:** `hello @joshua `

---

## Agent Files

Each agent has five core files. Each owns a distinct scope — no overlap.

| File | Scope | Changes |
|------|-------|---------|
| `SESSION.md` | **Procedures** — session start sequence, session close checklist, and skills index. What the agent does and when. | Occasionally |
| `IDENTITY.md` | **Persona** — who the agent is. Name, role, origin story, and character. Static facts about the agent itself. | Rarely |
| `SOUL.md` | **Operating principles** — how the agent thinks and works. Core truths, development philosophy, coding protocols, and vibe. | Rarely, intentionally |
| `USER.md` | **Human profile** — who the user is. Background, working style, and preferences. | As needed |
| `MEMORY.md` | **Current state** — active project status and the authoritative map of memory files. First read every session. | Every session |

---

## Memory Files

**`MEMORY.md`** — project pickup snapshot (status, next step, topic index). **`SOUL.md`** — operating principles and pointers to methodology subfolders.

| Location | Contents |
|----------|----------|
| `memory/TODO.md` | Active Backlog, domain concepts, Potential new functionality, Ideas dump (YAML frontmatter) |
| `memory/*.md` (root) | Project topics (architecture, Agent harness, conventions) |
| `memory/wip_*.md` | Active work plans — YAML frontmatter (`phase`, `loop`, `concept`) |
| `memory/.archive/` | Retired WIPs and superseded drafts |
| `memory/full-cry-sdlc/` | **Full CRY!** methodology — [overview above](#methodology--full-cry) |
| `memory/data-experience-journey/` | Data Experience (DX) |

Session procedures (start/close, skills index): `joshua/SESSION.md`.

---

## Skills

Reusable agent procedures live in `joshua/skills/`. Load the relevant skill before performing any recurring task. Active `wip_*.md` files carry YAML frontmatter (`phase`, `loop`, `concept`) — **WIP Management** is the canonical schema and grooming procedure.

| Skill | Path | Use When |
|-------|------|----------|
| Code Log Entries | `skills/code-log-entries/SKILL.md` | Writing or updating the session progress log |
| WIP Management | `skills/wip-management/SKILL.md` | Full CRY! WIP cycle, TODO grooming, archiving shipped WIPs |
| Query Local User Agent Workspace | `skills/query-local-user-agent-workspace/SKILL.md` | Inspecting S3-backed agent workspace files for a user |
| README Creation | `skills/readme-creation/SKILL.md` | Writing or refactoring service READMEs as conceptual architecture guides |

---

## Code Logs

Progress logs live in `code-log/code-log-YYYYMMDD.md`. Written for a **non-technical audience** — what was done, why it matters, what's next. No file names, no code snippets, no jargon.

---

## Adding Agents

The harness supports multiple agents. Each agent gets its own named folder alongside `joshua/` with the same five-file structure, scoped to their domain. Agents can share the `code-log/` folder.

| Agent | Purpose |
|-------|---------|
| `geovani/` | Documentation agent — maintains READMEs and system concept docs |
| `jane/` | Security review agent — focuses on auth flows, IAM policies, and vulnerability patterns |

---

## Folder Structure

```
.agents/
├── README.md                        ← this file (human-facing)
├── LICENSE                          
├── code-log/                        ← session progress logs
│   └── code-log-YYYYMMDD.md
└── joshua/                          ← Joshua's workspace
    ├── SESSION.md                   ← session start/close procedures and skills index
    ├── IDENTITY.md                  ← who Joshua is
    ├── SOUL.md                      ← how Joshua thinks and operates
    ├── USER.md                      ← about Zach
    ├── MEMORY.md                    ← current project state + memory file map
    ├── memory/                      ← topic docs, architecture notes, WIP plans
    │   ├── TODO.md
    │   ├── CODING_PRINCIPLES.md
    │   ├── ARCHITECTURE_CONCEPTS.md
    │   ├── {OTHER_TOPICS}.md
    │   ├── wip_*.md                 ← active WIPs (frontmatter: phase, loop)
    │   └── .archive/                ← shipped / retired WIPs
    └── skills/                      ← reusable agent procedures
        ├── code-log-entries/
        │   └── SKILL.md
        ├── wip-management/
        │   └── SKILL.md
        ├── query-local-user-agent-workspace/
        │   └── SKILL.md
        └── readme-creation/
            ├── SKILL.md
            └── references/
                ├── service-readme-template.md
                └── refactor-checklist.md
```

---
