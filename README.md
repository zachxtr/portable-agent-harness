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
| `memory/*.md` (root) | Project topics (TODO, architecture, PA harness, WIPs) |
| `memory/full-cry-sdlc/` | **Full CRY!** methodology — [overview above](#methodology--full-cry); full doc in folder |
| `memory/data-experience-journey/` | Data Experience (DX) |
| `memory/.archive/` | Retired — do not reference |

Session procedures and the full harness guide: `joshua/SESSION.md`.

---

## Skills

Reusable agent procedures live in `joshua/skills/`. Load the relevant skill before performing any recurring task.

| Skill | Path | Use When |
|-------|------|----------|
| Code Log Entries | `skills/code-log-entries/SKILL.md` | Writing or updating the session progress log |
| Query Local User Agent Workspace | `skills/query-local-user-agent-workspace/SKILL.md` | Inspecting S3-backed agent workspace files for a user |
| README Creation | `skills/readme-creation/SKILL.md` | Writing or refactoring service READMEs as conceptual architecture guides |

## Folder Structure

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
        ├── code-log-entries/        ← included agent procedure
        │   └── SKILL.md
        └── readme-creation/         ← example procedure...
            ├── SKILL.md
            └── references/
                ├── service-readme-template.md
                └── refactor-checklist.md
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
- [WIP work plans](./docs/wip-work-plans.md) — CRY slices (`wip_*_work_plan.md`)
- [Upgrading](./docs/upgrading.md) — merging upstream changes

---

## Contributing

Improvements to the template, docs, and scripts are welcome. Keep `examples/sample-reference/` clearly labeled as reference-only project content.
