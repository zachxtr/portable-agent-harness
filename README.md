# Portable Agent Harness

> Maintained by [Data Finn](https://datafinn.com).  
> Implements **[Full CRY!](#methodology--full-cry)** — Create → Refactor → Yield.  
> Licensed under [MIT](./LICENSE).

A structured **agent harness** you install into any repository so your AI coding agent keeps continuity between sessions — persona, procedures, project memory, and methodology before the first message.

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

## Methodology — Full CRY!

| Pillar | In one line |
|--------|-------------|
| **Create** | Build and experiment fast |
| **Refactor** | Keep code clear and consistent |
| **Yield** | Use the system as first user before stacking more work |

Full CRY! ships in every install under `myAgent/memory/full-cry-sdlc/`. Overview: [Full_CRY_Overview.md](./template/myAgent/memory/full-cry-sdlc/Full_CRY_Overview.md)

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

- [Concepts](./docs/concepts.md) — five files, memory layers
- [Customizing](./docs/customizing.md) — paths, agents, skills
- [WIP work plans](./docs/wip-work-plans.md) — CRY slices (`wip_*_work_plan.md`)
- [Upgrading](./docs/upgrading.md) — merging upstream changes

---

## WIP work plans

New installs include `memory/wip_TopicX_work_plan.md` — a template for scoped **Create → Refactor → Yield** units (focused delivery slices). Rename when starting real work; archive after yield.

---

## Contributing

Improvements to the template, docs, and scripts are welcome. Keep `examples/sample-reference/` clearly labeled as reference-only project content.
