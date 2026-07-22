# Customizing the harness

## Rename the agent folder

Default folder is `myAgent`. To use a different name at install time:

```bash
./scripts/init.sh --agent joshua /path/to/your-repo
```

Update IDE context to `@.agents/joshua` (or your chosen name).

## Change install path

```bash
./scripts/init.sh --path _dev/agents /path/to/your-repo
```

Keep paths inside harness files relative to `.agents/` (or your chosen root) — see `SOUL.md` § Memory & continuity.

## Multi-agent

Add another agent folder alongside `myAgent/` with the same five-file structure. Agents can share `code-log/`. Document each agent in the installed `README.md`.

## Project memory

| File | Purpose |
|------|---------|
| `memory/ARCHITECTURE_CONCEPTS.md` | Stack, terminology, decisions |
| `memory/CODING_PRINCIPLES.md` | Agreed conventions |
| `memory/TODO.md` | Backlog (Active Backlog, domain concepts, potential, ideas dump) |
| `memory/SHIPPED_MILESTONES.md` | Shipped work archive — not session pickup |
| `memory/wip_*.md` | Active Full CRY! cycles |

## WIP files

- Copy `memory/wip_example-topic.md` → `memory/wip_<topic>.md`
- Follow `skills/wip-management/SKILL.md` for lifecycle and TODO grooming
- WIP YAML: `created` and `updated` only; phase/loop in body **Status**

## Skills

Shipped template includes:

| Skill | Use |
|-------|-----|
| `code-log-entries` | Session progress log |
| `wip-management` | WIP cycle, TODO grooming, archive |
| `readme-creation` | Conceptual service READMEs |

Add more under `myAgent/skills/<skill-name>/SKILL.md` and index them in `SESSION.md`.

Copy optional skills from `examples/sample-reference/joshua/skills/` when useful — they may reference project-specific tooling (e.g. S3 workspace inspection).

## Full CRY! and DX

Always present in a standard install. Do not delete `memory/full-cry-sdlc/` — the harness is built around that methodology. Customize `SOUL.md` coding protocols to match your team.

## Cursor rules (optional)

You can add a Cursor rule (e.g. `@myAgent`) that points agents at `.agents/myAgent/SESSION.md` for session start. The default install uses `@.agents/myAgent` context attachment.
