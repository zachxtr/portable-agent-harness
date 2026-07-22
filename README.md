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

This harness encodes Full CRY! in practice: session safeguards, coding protocols in `SOUL.md`, yield checkpoints via code logs, and depth files loaded only when needed. Full treatise (aligned principles, gotchas, origin story): [Full CRY! overview](./template/myAgent/memory/full-cry-sdlc/Full_CRY_Overview.md).

### Full CRY! WIP cycle

Work runs as a **WIP cycle** on `myAgent/memory/wip_<topic>.md`:

```
design ──▶ create ◀──▶ refactor ◀──▶ yield ──▶ shipped
              └──── loop 1, 2, 3… ────┘
```

**Procedure (agents):** [`myAgent/skills/wip-management/SKILL.md`](./template/myAgent/skills/wip-management/SKILL.md) — TODO grooming, archive, close-out.

| WIP phase | What happens |
|-----------|----------------|
| **Design** | Scope, architecture, decisions, TODO grooming — **no product code** yet |
| **Create** | Full CRY! Create — scaffold, first implementation (WIP bleeds into code) |
| **Refactor** | Full CRY! Refactor — sculpt, align `CODING_PRINCIPLES.md`, update WIP checkboxes |
| **Yield** | Full CRY! Yield — user validates as first user; code log + `MEMORY.md` |
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

Each WIP file is a "control procedure" with living **requirements** that drive implementation of the produced **product**. 

Think **Total Quality Management (TQM)** and **Plan–Do–Check–Act**: documented procedures govern continuous improvement, and outcomes are verified before the next cycle. **Key Performance Indicators (KPIs)** here are slice-level signals — not dashboards — documented and checked in the harness files the WIP cycle produces. Examples:
- **Yield criteria met** — the user validated the slice as first user before stacking more work
- **Phase and loop** — design → create ↔ refactor ↔ yield progress in the WIP Status section
- **Checklist completion** — spec tasks closed in the active WIP body
- **Milestones shipped** — entries appended to `SHIPPED_MILESTONES.md` when a cycle closes

`SHIPPED_MILESTONES.md`, code logs, git commit histories, and the compiled running **source code** demonstrate a _baseline_ and the _improvements_ gained. Archived WIP files preserve context for stakeholders and future build sessions.

WIP files use **minimal YAML** (`created`, `updated` only). Phase and loop live in the **body Status** section — see the wip-management skill.

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
| `memory/*.md` (root) | Project topics (architecture, conventions, shipped history) |
| `memory/wip_*.md` | Active work plans — dates-only YAML; phase/loop in body Status |
| `memory/.archive/` | Retired WIPs and superseded drafts |
| `memory/full-cry-sdlc/` | **Full CRY!** methodology — [overview above](#methodology--full-cry) |
| `memory/data-experience-journey/` | Data Experience (DX) |

Session procedures (start/close, skills index): `myAgent/SESSION.md`.

---

## Skills

Reusable agent procedures live in `myAgent/skills/`. Load the relevant skill before performing any recurring task. **WIP Management** is the canonical WIP lifecycle and TODO grooming procedure.

| Skill | Path | Use When |
|-------|------|----------|
| Code Log Entries | `skills/code-log-entries/SKILL.md` | Writing or updating the session progress log |
| WIP Management | `skills/wip-management/SKILL.md` | Full CRY! WIP cycle, TODO grooming, archiving shipped WIPs |
| README Creation | `skills/readme-creation/SKILL.md` | Writing or refactoring service READMEs as conceptual architecture guides |

Optional project-specific skills (e.g. storage/workspace inspection) can be copied from [`examples/sample-reference/`](./examples/sample-reference/).

---

## Code Logs

Progress logs live in `code-log/code-log-YYYYMMDD.md`. Written for a **non-technical audience** — what was done, why it matters, what's next. No file names, no code snippets, no jargon.

---

## Adding Agents

The harness supports multiple agents. Each agent gets its own named folder alongside `myAgent/` with the same five-file structure, scoped to their domain. Agents can share the `code-log/` folder.

| Agent | Purpose (example) |
|-------|-------------------|
| `geovani/` | Documentation agent — maintains READMEs and system concept docs |
| `jane/` | Security review agent — auth flows, IAM policies, vulnerability patterns |

---

## Folder Structure

```
.agents/
├── README.md                        ← installed copy (human-facing)
├── LICENSE
├── code-log/                        ← session progress logs
│   └── code-log-YYYYMMDD.md
└── myAgent/                         ← default agent workspace
    ├── SESSION.md                   ← session start/close procedures and skills index
    ├── IDENTITY.md                  ← persona
    ├── SOUL.md                      ← operating principles
    ├── USER.md                      ← human profile
    ├── MEMORY.md                    ← current project state + memory file map
    ├── memory/
    │   ├── TODO.md
    │   ├── SHIPPED_MILESTONES.md
    │   ├── CODING_PRINCIPLES.md
    │   ├── ARCHITECTURE_CONCEPTS.md
    │   ├── wip_*.md                 ← active WIPs (dates-only YAML; status in body)
    │   └── .archive/                ← shipped / retired WIPs
    └── skills/
        ├── code-log-entries/
        ├── wip-management/
        └── readme-creation/
```

---

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

## Repository layout

| Path | Purpose |
|------|---------|
| [`template/`](./template/) | Sanitized files copied by `init.sh` |
| [`examples/sample-reference/`](./examples/sample-reference/) | Mature real-world reference (not installed) |
| [`scripts/`](./scripts/) | `init.sh`, `validate.sh` |
| [`docs/`](./docs/) | Concepts, customizing, WIP plans, upgrading |
| [`manifest.yaml`](./manifest.yaml) | Required paths and version |

---

## Documentation

- [Customizing](./docs/customizing.md) — paths, agents, skills
- [WIP work plans](./docs/wip-work-plans.md) — Full CRY! WIP cycle (`wip_<topic>.md`)
- [Upgrading](./docs/upgrading.md) — merging upstream changes (v0.1 → v0.2)

---

## Contributing

Improvements to the template, docs, and scripts are welcome. Keep `examples/sample-reference/` clearly labeled as reference-only project content.
