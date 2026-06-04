# WIP work plans (CRY slices)

## What they are

Files named `wip_<topic>_work_plan.md` are **scoped work units** in the Full CRY! cycle — a focused alternative to a heavyweight waterfall sprint.

Each WIP captures:

- What the slice delivers (summary)
- Which CRY phase you are in (Create / Refactor / Yield)
- Scope in/out
- **Yield criteria** — how you validate as first user before stacking more work
- Tasks and open questions

## When to create one

- The active next step in `MEMORY.md` spans multiple sessions
- You need a single doc for design + implementation + yield for one feature or fix
- You want the agent to load depth without bloating `MEMORY.md`

## Template

New installs include `memory/wip_TopicX_work_plan.md`. Copy or rename:

```text
memory/wip_auth_refresh_work_plan.md
```

## Lifecycle

1. **Create** — explore and build; WIP tracks tasks and questions
2. **Refactor** — clean up after the slice works
3. **Yield** — run locally, click UI, verify data; meet acceptance criteria
4. **Ship** — update `MEMORY.md`, code log, `TODO.md`; move WIP to `memory/.archive/`

## Agent rules

- WIP = design draft until Yield is complete — not production ground truth
- Load only when `MEMORY.md` or the task references that WIP
- Do not duplicate WIP content into `SESSION.md`

See also: [Full CRY! overview](../template/myAgent/memory/full-cry-sdlc/Full_CRY_Overview.md)
