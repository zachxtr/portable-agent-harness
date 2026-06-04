# Upgrading the harness

There is no automatic merge yet. Treat upstream harness updates like any shared template:

## Safe to replace from upstream

- `SESSION.md` structure (review diffs first — you may have local standing rules)
- New skills under `skills/` you do not have
- Full CRY! / DX docs under `memory/full-cry-sdlc/` and `memory/data-experience-journey/`

## Never overwrite blindly

- `MEMORY.md` — your pickup snapshot
- `USER.md`, `IDENTITY.md` — your profiles
- `memory/ARCHITECTURE_CONCEPTS.md`, `CODING_PRINCIPLES.md`, `TODO.md`
- Active `wip_*.md` and `code-log/`

## Suggested workflow

1. Run `git diff` or compare release notes from [portable-agent-harness](https://github.com/zachxtr/portable-agent-harness)
2. Copy changed template files into a branch
3. Manually merge into `.agents/` preserving your project sections
4. Run `./scripts/validate.sh /path/to/your-repo`

## Re-install

`./scripts/init.sh --force` **deletes** the entire `.agents/` tree. Only use on a fresh project or with a backup.
