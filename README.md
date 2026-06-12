# Portable Agent Harness

> Maintained by [Data Finn](https://datafinn.com).  
> Built on **[Full CRY!](./template/myAgent/memory/full-cry-sdlc/Full_CRY_Overview.md)** — Data Finn's AI-age development methodology (see below).
> Licensed under the MIT open-source [LICENSE](./LICENSE) — the patterns and methodology are freely adaptable for other projects.

A structured **agent harness** you install into any repository so your AI coding agent keeps continuity between sessions including: persona, procedures, project memory, and methodology.

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

## Repository Layout & Folder Structure

| Path | Purpose |
|------|---------|
| [`template/`](./template/) | Sanitized files copied by `init.sh` |
| [`examples/sample-reference/`](./examples/sample-reference/) | Mature real-world reference (not installed) |
| [`scripts/`](./scripts/) | `init.sh`, `validate.sh` |
| [`docs/`](./docs/) | Concepts, customizing, WIP plans, upgrading |
| [`manifest.yaml`](./manifest.yaml) | Required paths and version |


```
.agents/
├── README.md                        ← this file (human-facing)
├── LICENSE                          
├── code-log/                        ← session progress logs
│   └── code-log-YYYYMMDD.md
└── myAgent/                         ← myAgent workspace
    ├── SESSION.md                   ← session start/close procedures and skills index
    ├── IDENTITY.md                  ← who myAgent is
    ├── SOUL.md                      ← how myAgent thinks and operates
    ├── USER.md                      ← about the user (you)
    ├── MEMORY.md                    ← current project state + memory file map
    ├── memory/                      ← topic docs, architecture notes, WIP plans
    │   ├── TODO.md
    │   ├── CODING_PRINCIPLES.md
    │   ├── ARCHITECTURE_CONCEPTS.md
    │   ├── {OTHER_TOPICS}.md
    │   ├── wip_*.md
    │   └── old_*.md
    └── skills/                      ← reusable agent procedures
```


## Install

```bash
git clone https://github.com/zachxtr/portable-agent-harness.git
cd portable-agent-harness
./scripts/init.sh /path/to/your-project
```

- Installs to **`.agents/`** in the target repo (default agent: **`myAgent`**)
- Fails if `.agents/` already exists; use **`--force`** to overwrite
- Validates with `./scripts/validate.sh /path/to/your-project`

Non-interactive example:

```bash
PROJECT_NAME="Acme API" USER_NAME="Alex" USER_WHAT_TO_CALL="Alex" \
  ./scripts/init.sh /path/to/your-project
```

Options: `--path`, `--agent`, `--force` — see `./scripts/init.sh --help`

---

## After install

1. Open a new chat in Cursor (or your AI IDE)
2. Add `@.agents/myAgent`
3. Say: *Please load context*

---


## Documentation

- [Customizing](./docs/customizing.md) — paths, agents, skills
- [WIP work plans](./docs/wip-work-plans.md) — CRY slices (`wip_*_work_plan.md`)
- [Upgrading](./docs/upgrading.md) — merging upstream changes

---

## Contributing

Improvements to the template, docs, and scripts are welcome. Keep `examples/sample-reference/` clearly labeled as reference-only project content.
