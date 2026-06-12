# WIP work plans (CRY slices)

## What they are

Files named `wip_<topic>_work_plan.md` (or `wip_<topic>.md`) are **scoped work units** in the Full CRY! WIP cycle — a focused alternative to a heavyweight waterfall sprint.

Each WIP captures:

- YAML frontmatter (`phase`, `updated`, optional `loop`, `next_yield`)
- What the slice delivers (summary)
- Scope in/out and forward-looking **spec**
- Implementation phase checkboxes
- **Yield criteria** — how you validate as first user before stacking more work
- **Related backlog** pointer to `TODO.md`

## When to create one

- The active next step in `MEMORY.md` spans multiple sessions
- You need a single doc for design + implementation + yield for one feature or fix
- You want the agent to load depth without bloating `MEMORY.md`

## Template

New installs include `memory/wip_TopicX_work_plan.md`. Copy or rename:

```text
memory/wip_auth_refresh_work_plan.md
```

Set `phase: design` in frontmatter and add a row to `MEMORY.md` § WIP index.

## Lifecycle

```
design ──▶ create ◀──▶ refactor ◀──▶ yield ──▶ shipped
              └──── loop 1, 2, 3… ────┘
```

| Phase | What happens |
|-------|----------------|
| **Design** | Scope, architecture, TODO grooming — **no product code** |
| **Create** | Scaffold and first implementation; WIP bleeds into code |
| **Refactor** | Sculpt, align `CODING_PRINCIPLES.md`, update checkboxes |
| **Yield** | Use the system as first user; code log + `MEMORY.md` |
| **Shipped** | Append `SHIPPED_MILESTONES.md`, archive WIP, remove from WIP index |

**Procedure (agents):** `myAgent/skills/wip-management/SKILL.md`

## WIP vs TODO

- **WIP** — scoped initiative for one effort
- **TODO** — Active Backlog, domain concepts, Potential new functionality, Ideas dump

Do not duplicate the same checklist in both files after grooming.

## Agent rules

- WIP = design draft until shipped — not production ground truth
- Load only when `MEMORY.md` or the task references that WIP
- Do not duplicate WIP content into `SESSION.md`
- Never delete WIPs — move to `memory/.archive/`

See also: [Full CRY! overview](../template/myAgent/memory/full-cry-sdlc/Full_CRY_Overview.md)
