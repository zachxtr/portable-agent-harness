# Policy Command Agent Memory

> **Pickup snapshot** — what is true *now*. Procedures → `SESSION.md`. Operating frameworks → `SOUL.md`. Project depth → topic index below.

**Last updated:** 2026-06-04

---

## Current status

**Last session closed:** 2026-06-04 — Joshua harness memory restructure: lean `MEMORY.md`, `SESSION.md` harness guide (framework vs project `memory/`), `SOUL.md` → **Full CRY!** + DX subfolders, stack layers → `ARCHITECTURE_CONCEPTS.md`; reference files for shipped history, UI tokens, Bedrock ops. Committed: `eee441f2`. Log: `code-log/code-log-20260604.md`.

**Verified recently:** Focus **Top Results Shown** (5/10/20) — manual QA passed (2026-06-03).

**Last code log:** `code-log/code-log-20260604.md`

---

## Active next step

1. **Smoke-test pickup** — new chat, `@.dev/code-agents/joshua`, “load context”; confirm lean MEMORY + SESSION guide (no changelog noise). Harness committed (`eee441f2`).
2. **Rolling memory Phase 1** — when approved, per `memory/wip_assistant_rollingmemory_work_handoff.md`.
3. Then Platform Guide · Briefs parity — `memory/TODO.md`.

---

## In progress / known gaps

- **Rolling memory (`ROLLINGMEMORY.md`)** — design reviewed; **no code yet** (`memory/wip_assistant_rollingmemory_work_handoff.md`)
- **Platform Guide** — WIP complete; not implemented (`memory/wip_platform_guide_work_plan.md`)
- **Briefs clickable links** — not implemented (`memory/wip_assistant_briefs_linkbuttons.md`)
- Inbox Edit & Accept / batch actions — polish backlog
- Accent picker in assistant setup wizard — not wired
- `memory-guide.md` alignment deferred (PA product doc)
- PdfViewer yield testing across entry points — recommended before wider use
- Team Updates brief — still profile timestamps, not update-log
- Briefs data parity — Tracking → BillTrackingLog; Team → `TeamActivity.tsx` feed
- Discovery precision tuning — cross-corpus merge / `effectiveQuery`
- Prod Bedrock rerank — `bedrock:Rerank` AccessDenied on ECS task role
- document-scraping → indexing-service fan-out during collection
- Unused skill knobs on discover-mode search skills

---

## Topic index

Load depth files **only when** the task needs them. **SOUL.md** is the primary pointer for framework subfolders at session start.

### Topic types

| Type | Location | Purpose |
|------|----------|---------|
| **Framework** | `memory/<name>/` subfolders | Transferable process (Full CRY!, DX). Stable — not session-clean targets. |
| **Project** | `memory/*.md` at root | Policy Command backlog, architecture, PA harness, conventions. |
| **Reference** | `memory/*.md` at root | Lookup/archive (shipped history, UI tokens, ops). Not pickup. |
| **WIP** | `memory/wip_*.md` | Design drafts — not ground truth until shipped. |
| **Archive** | `memory/.archive/` | Retired docs — historical only. |

### Framework (see also `SOUL.md`)

| Path | Summary | Load when |
|------|---------|-----------|
| `memory/full-cry-sdlc/Full_CRY_Overview.md` | **Full CRY!** — Create, Refactor, Yield | Process, session pacing, SDLC |
| `memory/data-experience-journey/DATA_EXPERIENCE_JOURNEY.md` | Data Experience (DX) — data journey | Tracing data through the stack |

### Project

| Path | Summary | Load when |
|------|---------|-----------|
| `memory/TODO.md` | Engineering + product backlog | Prioritizing, planning |
| `memory/CODING_PRINCIPLES.md` | Agreed conventions and patterns | Writing or reviewing code |
| `memory/ARCHITECTURE_CONCEPTS.md` | Stack layers, keys, patterns; §10 Chat vs PA | Architecture, cross-layer work |
| `memory/POLICY_ASSISTANT_AGENT_HARNESS.md` | PA persona files, prompts, tiers | PA, INTERPRET, rolling memory, inbox |
| `memory/SKILL_VARIABLES.md` | SKILL.md platform knobs | Tuning discovery / worker skills |

### Reference (not pickup)

| Path | Summary | Load when |
|------|---------|-----------|
| `memory/SHIPPED_MILESTONES.md` | Archived shipped work | “When did X ship?” — not session start |
| `memory/UI_TOKENS.md` | `highlight-*` / `accent-*` / `annot-*` | UI theming changes |
| `memory/OPS_BEDROCK.md` | Bedrock regions, avatar models | Local Docker / avatar / LLM env issues |

### WIP (drafts — not ground truth)

| Path | Summary | Load when |
|------|---------|-----------|
| `memory/wip_assistant_rollingmemory_work_handoff.md` | `SESSIONMEMORY` → `ROLLINGMEMORY`; migration | Rolling memory implementation |
| `memory/wip_platform_guide_work_plan.md` | Platform Guide routes + content | Platform Guide build |
| `memory/wip_assistant_briefs_linkbuttons.md` | Briefs card deep links | Briefs UI work |
| `memory/wip_data_collection_pipeline.md` | Collection / ingestion architecture | Scraper / indexing pipeline |

### Archive (`memory/.archive/`)

Superseded WIPs and legacy drafts. Do not treat as current — use `SHIPPED_MILESTONES.md` or git history if needed.

---

## Do not put in this file

- Full CRY! or DX treatises → framework subfolders (see `SOUL.md`)
- Stack layer diagram → `ARCHITECTURE_CONCEPTS.md`
- Shipped feature changelog → `memory/SHIPPED_MILESTONES.md`
- UI token tables → `memory/UI_TOKENS.md`
- Bedrock / container ops → `memory/OPS_BEDROCK.md`
- Harness file catalog and load rules → `SESSION.md` § Joshua harness guide
- Session procedures → `SESSION.md`

*Update at session close: status, active next step, in progress list, and index rows for new **project** files at `memory/` root only.*
