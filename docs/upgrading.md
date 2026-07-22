# Upgrading the harness

There is no automatic merge yet. Treat upstream harness updates like any shared template.

## v0.2.0 (from v0.1.0)

If you installed before v0.2.0, consider these changes:

| Area | v0.1 | v0.2 |
|------|------|------|
| WIP naming | `wip_*_work_plan.md` | `wip_<topic>.md` |
| WIP YAML | ad hoc | `created` / `updated` only; phase in body |
| Shipped record | optional / manual | `memory/SHIPPED_MILESTONES.md` |
| TODO | simple backlog | tiered frontmatter + sections |
| Skills | `code-log-entries` only | + `wip-management`, `readme-creation` |
| SESSION | inline harness guide | "Where depth lives" + WIP close-out steps |

**Suggested migration:**

1. Copy new skills from upstream `template/myAgent/skills/` (`wip-management`, `readme-creation`)
2. Merge `SESSION.md` — preserve your standing rules; add WIP close-out and skills index rows
3. Add `memory/SHIPPED_MILESTONES.md` if missing
4. Rename active WIPs: `wip_foo_work_plan.md` → `wip_foo.md`; move phase/status into body
5. Optionally adopt tiered `TODO.md` frontmatter from upstream template
6. Run `./scripts/validate.sh /path/to/your-repo` after manual merge

## Safe to replace from upstream

- `SESSION.md` structure (review diffs first — you may have local standing rules)
- New skills under `skills/` you do not have
- Full CRY! / DX docs under `memory/full-cry-sdlc/` and `memory/data-experience-journey/`
- Installed `README.md` methodology sections (WIP cycle)

## Never overwrite blindly

- `MEMORY.md` — your pickup snapshot
- `USER.md`, `IDENTITY.md` — your profiles
- `memory/ARCHITECTURE_CONCEPTS.md`, `CODING_PRINCIPLES.md`, `TODO.md` (content)
- Active `wip_*.md` and `code-log/`
- `memory/SHIPPED_MILESTONES.md` (your shipped history)

## Suggested workflow

1. Run `git diff` or compare release notes from [portable-agent-harness](https://github.com/zachxtr/portable-agent-harness)
2. Copy changed template files into a branch
3. Manually merge into `.agents/` preserving your project sections
4. Run `./scripts/validate.sh /path/to/your-repo`

## Re-install

`./scripts/init.sh --force` **deletes** the entire `.agents/` tree. Only use on a fresh project or with a backup.
