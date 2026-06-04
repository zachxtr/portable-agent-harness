---
name: readme-creation
description: Create or refactor service and package README files as conceptual architecture guides — not tuning runbooks. Use when the user asks to write, update, slim down, or review a README; when README content duplicates config, env defaults, or code constants; or when onboarding docs need a documentation map and anti-drift structure.
---

# README Creation (Conceptual Guide Pattern)

Write READMEs that stay accurate as code changes. **Architecture and responsibilities in the README; values and contracts elsewhere.**

**Start here:** `references/service-readme-template.md` — dummy sections and tone to copy.  
**Refactor pass:** `references/refactor-checklist.md` — assess, plan, execute, verify.

---

## When to load this skill

- New service or package needs a README
- Existing README is long, stale, or mixes knobs with architecture
- User asks for a "conceptual guide" or "anti-drift" doc pass
- Review found README listing tool counts, defaults, JSON schemas, or file-by-file type tables

**Not for:** worker runtime `SKILL.md` files (agentskills.io — use Cursor `create-skill`). **Not for:** client code logs (use `code-log-entries` skill).

---

## One doc, one job

| Document | Owns | Update when |
|----------|------|-------------|
| **README.md** | What the system is, how parts relate, design rules, where to look | Architecture or responsibility boundaries change |
| **Knob map / variable doc** | Semantics, defaults in code, tuning workflow | Loader, phase behavior, or platform keys change |
| **Config / SKILL files** | Live tuned values | Tuning sessions |
| **Source types & phase modules** | Contracts, caps, parsers | Implementation changes |
| **Harness / ops docs** | Agent behavior, storage queries, runbooks | Ops or harness changes |

**README rule:** If it is a number, default, schema field, env default, or "currently set to X" → **link in the documentation map, don't duplicate.**

---

## What belongs in a README

**Keep (stable concepts)** — see template sections:

- Overview + "How to read this doc"
- Architecture diagram (conceptual)
- One or more **named areas** (role tables — not config dumps)
- Project layout (folder roles)
- API (compact)
- Configuration (service env only)
- Local development
- **Documentation map**
- **Optional sections** block in template — copy rows out, delete the rest

**Remove or relocate** — full list in `references/refactor-checklist.md`:

- Tool counts, chunk caps, inventory limits
- YAML/JSON contracts duplicating other docs
- Method chains and struct field names in gate tables
- Filename patterns with token grammar

---

## Workflow (always follow)

Joshua standing rule: **present a plan and wait for approval** before editing READMEs unless the user explicitly says "approve" or "go ahead."

1. **Assess** — grep for drift; note relocations (`references/refactor-checklist.md`)
2. **Plan** — target length, section changes, map rows, success criteria
3. **Execute** — fill from `references/service-readme-template.md`; relocate detail in same change
4. **Verify** — checklist in `references/refactor-checklist.md`

---

## README vs worker SKILL.md

| File | Audience | Content |
|------|----------|---------|
| **Service README** | Human maintainers | Architecture, responsibilities, documentation map |
| **Worker SKILL.md** | Runtime agent | Frontmatter, instructions, platform tuning |

Do not put service architecture in a worker SKILL file. Optional README beside a skill folder is for humans only — not a substitute for the service README.

---

## Skill references

| File | Use |
|------|-----|
| `references/service-readme-template.md` | Section order, placeholder copy, documentation map pattern |
| `references/refactor-checklist.md` | Slim-down workflow, anti-patterns, verify checklist |

Keep this skill self-contained: extend **references/** when the process evolves — avoid pointing the skill body at repo-specific README paths.
