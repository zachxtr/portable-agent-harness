# WIP work plans (Full CRY! cycle)

## What they are

Files named `memory/wip_<topic>.md` are **scoped work units** in the Full CRY! cycle — a focused alternative to a heavyweight waterfall sprint.

Each WIP captures:

- What the slice delivers (summary)
- Which phase you are in (design → create ↔ refactor ↔ yield → shipped)
- Scope in/out
- **Yield criteria** — how you validate as first user before stacking more work
- Tasks and open questions

**Canonical procedure:** [`template/myAgent/skills/wip-management/SKILL.md`](../template/myAgent/skills/wip-management/SKILL.md)

## File shape

### YAML frontmatter (minimal)

Dates only on new files:

```yaml
---
created: 2026-06-25
updated: 2026-06-25
---
```

### Body

- **Status** — phase, loop, next step (human pickup)
- **Product direction** — locked decisions
- **Spec / checklists** — forward-looking plan
- **Open questions**
- **User's Thoughts** — raw capture section (see skill)

Phase and loop belong in the **body**, not in YAML.

## When to create one

- The active next step in `MEMORY.md` spans multiple sessions
- You need a single doc for design + implementation + yield for one feature or fix
- You want the agent to load depth without bloating `MEMORY.md`

## Template

New installs include `memory/wip_example-topic.md`. Copy or rename:

```text
memory/wip_auth_refresh.md
```

Add a row to `MEMORY.md` § WIP index when the WIP becomes active.

## Lifecycle

1. **Design** — scope, architecture, TODO grooming; no product code
2. **Create** — explore and build; WIP tracks tasks and questions
3. **Refactor** — clean up after the slice works; align `CODING_PRINCIPLES.md`
4. **Yield** — run locally, click UI, verify data; meet acceptance criteria
5. **Ship** — append `SHIPPED_MILESTONES.md`, archive to `memory/.archive/`, groom `TODO.md`, update `MEMORY.md`

## WIP vs TODO

| `wip_<topic>.md` | `TODO.md` |
|------------------|-----------|
| One scoped initiative | Cross-cutting backlog, domain notes, ideas dump |
| Checkboxes for **this** effort | Actionable items not tied to one WIP |

Do not duplicate the same checklist in both files.

## Agent rules

- WIP = design draft until shipped — not production ground truth
- Load only when `MEMORY.md` or the task references that WIP
- Do not duplicate WIP content into `SESSION.md`
- Never delete WIPs — archive only

See also: [Full CRY! overview](../template/myAgent/memory/full-cry-sdlc/Full_CRY_Overview.md)
