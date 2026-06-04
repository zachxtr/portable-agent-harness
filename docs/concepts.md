# Harness concepts

## What this is

The portable agent harness is an **onboarding kit and working memory** for an AI coding agent in your repository. Without it, every session starts cold. With it, the agent loads persona, procedures, project state, and methodology before the first task.

The harness **implements [Full CRY!](../template/myAgent/memory/full-cry-sdlc/Full_CRY_Overview.md)** — Create → Refactor → Yield — in file structure and session protocol.

## Five core files (per agent)

| File | Scope |
|------|--------|
| `SESSION.md` | **Procedures** — session start/close, harness guide, skills index |
| `IDENTITY.md` | **Persona** — who the agent is |
| `SOUL.md` | **Operating principles** — how the agent works; pointers to Full CRY! and DX |
| `USER.md` | **Human profile** — who you are and how you work |
| `MEMORY.md` | **Pickup snapshot** — status, next step, topic index (read first every session) |

## Memory layers

```
SESSION.md (how)
    → MEMORY.md (what now)
        → memory/*.md (depth)
        → memory/<framework>/ (Full CRY!, DX — stable)
        → memory/wip_*.md (CRY work slices)
    → skills/*/SKILL.md (recurring tasks)
    → code-log/ (human-readable session narrative)
```

## Install location

Default: **`.agents/`** at the repository root, with agent folder **`myAgent/`**.

IDE context example: `@.agents/myAgent`
