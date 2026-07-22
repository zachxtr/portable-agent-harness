# Agent Memory

> **Pickup snapshot** — what is true *now*. Procedures → `SESSION.md`. Operating frameworks → `SOUL.md`. Project depth → topic index below.

**Last updated:** 2026-07-22 (session close — Adventures Phase A)

---

## Current status

**Landing page verified in AWS production** — `https://mycoreimagination.com`, landing-only mode (`enable_fullstack = false`). Web app on ECS EC2 behind public ALB in **us-east-1**.

**Web app MCI shell largely in place** — main nav, Library (books/chats/annotations), **My Contacts** (teammates table, contact details, sharing), admin Catalog, SYSTEM Books create/edit/index, legislative SYSTEM pages removed. **Dashboard dark mode** shipped (theme picker, profile-backed accent — no cross-user localStorage leak).

**Adventures Phase A shipped (2026-07-22)** — list + sidebar, New Adventure wizard (manual CRUD, no Generate), edit cards, entry points (index, catalog detail, focus modal). **`quest.handle`** on embedded quest for @short-name labels. Focus modal: New Adventure pill, discovery limit on chat title, Defaults + Quest sections removed.

**Home briefing cards (2026-07-21)** — Greetings, Adventure Recap, and Activity refactored for clearer roles. Card-specific system leads scope factual sources.

**Activity dashboard (2026-07-21)** — page loads saved books, chats, and annotations only.

**Companion UX (2026-07-21)** — avatar regen, create wizard defaults, Memory tab editable.

**Library (2026-07-21)** — annotation rows per owner; reading progress shipped.

**Teammates Stat cards (2026-07-21)** — companion-lens projection; Stat card grid; reading over shoulder.

**Chat Phase 1 partial** — book focus, streaming chat, citation pipeline, turn companion avatars (incl. `accountId = 0` fix). Further chat/quest/companion work → `memory/TODO.md` Active Backlog.

**core-service is up.** RAP builds after adventure/quest-history type fixes.

**Git HEAD:** `feb9ec9` (2026-07-22) — session close; clean working tree.

---

## Active next step

**Smoke-test Adventures Phase A in Docker** — create → edit → list with catalog book; optional guide; verify focus modal + catalog CTA.

**Then (pick one):** `wip_web-app-mci.md` **Phase 3** legislative cleanup · `wip_sign-out-goodbye.md` backdrop layout review · `wip_dynamic-book-covers.md` Phase 1 spike.

---

## In progress / known gaps

- Full stack not deployed — RDS, Keycloak, core/rap/indexing Fargate, OpenSearch gated by `enable_fullstack`
- Quest Guide orchestrator, quest play UI (Phase C) — not started
- RAP legislative skills and persona copy not yet MCI domain — see `.archive/wip_rap-service-mci.md`
- Legislative UI remnants — policy-profile routes, Briefs backend, deprecated focus store fields
- `ChatTurnRecord` still uses `bookKeys[]` on turns — target `scope.items` with `ChatItemRef`
- Focus modal book picker inside modal (not only catalog link) — see `memory/TODO.md` Active Backlog

> **Backlog only in TODO.md** — do not list `TODO.md` Potential items here unless actively in flight.

---

## Topic index

> **Load on demand** — only open indexed files when the task needs them.

### Topic types

| Type | Location | Purpose |
|------|----------|---------|
| **Framework** | `memory/<name>/` subfolders | Transferable process (Full CRY!, DX). Stable — not session-clean targets. |
| **Reference** | `memory/*.md` at root | Lookup (shipped history, UI tokens, ops). Not pickup. |
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
| `memory/ARCHITECTURE_CONCEPTS.md` | Stack layers, keys, patterns; §10 Chat vs Agent | Architecture, cross-layer work |
| `memory/SKILL_VARIABLES.md` | SKILL.md platform knobs | Tuning discovery / worker skills |

### Reference (not pickup)

| Path | Summary | Load when |
|------|---------|-----------|
| `memory/SHIPPED_MILESTONES.md` | Archived shipped work | “When did X ship?” — not session start |
| `memory/OPS_BEDROCK.md` | Bedrock regions, avatar models | Local Docker / avatar / LLM env issues |

### WIP (drafts — not ground truth)

| Path | Summary | Load when |
|------|---------|-----------|
| `memory/wip_sign-out-goodbye.md` | Sign-out — hero active companion + backdrop portraits | Logout UX, AuthContext, RAP briefing |
| `memory/wip_dynamic-book-covers.md` | Dynamic book covers — 3-layer shell + presets | Book cover UI, Create/Edit Books |
| `memory/wip_web-app-mci.md` | Web shell cleanup — Adventures Phase A shipped | Dashboard nav, catalog, library |
| `memory/wip_public-domain-erotic-romantic-literature.md` | Public-domain reading list (content reference) | Catalog curation, content sourcing |

### Archive (`memory/.archive/`)

Completed and superseded WIPs. Load from `memory/.archive/` only when a task needs a specific retired doc.

---

## Do not put in this file

- Full CRY! or DX treatises → framework subfolders (see `SOUL.md`)
- Stack layer diagram → `ARCHITECTURE_CONCEPTS.md`
- Shipped feature changelog → `memory/SHIPPED_MILESTONES.md`
- Session narrative / changelog bullets → code log + `SHIPPED_MILESTONES.md`
- UI token tables → `memory/UI_TOKENS.md`
- Bedrock / container ops → `memory/OPS_BEDROCK.md`
- Harness layout → `../README.md`; session procedures → `SESSION.md`

*Update at session close: status, active next step, in progress list, and index rows for new **project** or **WIP** files at `memory/` root only.*
