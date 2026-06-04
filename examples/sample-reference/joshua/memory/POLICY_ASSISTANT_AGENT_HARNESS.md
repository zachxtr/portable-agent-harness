# Policy Command Policy Assistant Agent Harness

The Policy Command Policy Assistant (PA) Agent Harness is a production-grade LLM engagement workflow designed to deliver reliable, consistent interactions with Anthropic LLMs — the user's legislative aide on the platform.

The harness has two jobs: **give the agent the richest possible context at the start of every session**, and **keep the agent from drifting** away from who it is, what it knows, and how it should behave.

> **Note:** The harness is fully operational before a user completes persona setup. When `setupCompletedAt` is not yet set in `persona/setup/config.json`, persona files (`IDENTITY.md`, `SOUL.md`, etc.) are simply omitted from the system prompt — the PA runs on generic context. The harness structure, routing, and write-gate enforcement are in effect from the very first turn.


**How the Harness Works:**

Each Policy Command **user** gets a dedicated S3 folder — their **agent workspace** — that persists across sessions. Within it, the `persona/` subfolder holds everything the PA needs to be a consistent, personalized assistant: who it is, how it operates, what it knows about the user, and what it has learned over time.

The PA is powered by Anthropic Claude. We follow Anthropic's best practice of using plain `.md` files for LLM context — they're human-readable, version-controllable, and map directly to system prompt sections without any parsing layer. The harness loads the right files at the right moments, controls what the LLM can change, and ensures the user stays in control of anything that matters to them.

The sections below define: what files exist and where, how write access is governed, what each file contains, how the PA assembles its prompts, how the agent proposes changes back to the user, and how all of this sequences through a live turn.

---

## Implementation Status (May 2026)

Canonical reference for what is **shipped** vs **planned**. When code and this doc disagree, trust the code — then update this section.

### Shipped

| Area | Status |
| --- | --- |
| Backend harness | Persona read/write, write gates, inbox API, memory review/consolidate, setup finalize, session refresh |
| Setup wizard | Flat `persona/setup/` staging, draft avatar, AI portrait generation, finalize → live persona files |
| Assistant Edit | Tabbed persona editor (My Assistant, About You, Memories), field icons, avatar picker |
| PA presence UI | `AssistantActionBar`, separate Focus/Inbox modals (`AssistantModals`), scope pills, mobile sheet panel 1 |
| Inbox review UI | `AssistantInboxPanel` + `AssistantInboxProposalCard` — accept/reject persona-update cards; pending count on Inbox pill |
| Legislative focus | Global session/year stores + conversation bill/statute pins; shared `AssistantFocusScopePills` |
| Dashboard theming | Per-user `accent-*` via profile Configuration Settings (`ThemePicker`) — separate from fixed `highlight-*` brand teal |

### Planned / polish backlog

| Item | Notes |
| --- | --- |
| Inbox **Edit & Accept** | Cards ship Accept/Reject only — no inline edit before accept yet |
| Inbox batch accept/reject | One-click clear-all not built |
| Accent picker in setup wizard | Profile settings theme picker shipped; wizard step not wired |
| Dreaming | Scheduled consolidate + memory review |
| Response ratings | Thumbs on chat turns / briefs → distillation signals |
| `memory-guide.md` alignment | Product reference doc deferred |

**Removed:** Tabbed `AssistantPanelModal` / `AssistantPanelContext` — replaced May 2026 by separate Focus and Inbox dialogs plus embedded mobile panels. Old phase-letter implementation plan (`wip_PA_AGENT_HARNESS_IMPLEMENTATION_PLAN.md`) retired; this doc is the single harness reference.

---

## File Folder Structure

Every user gets a dedicated agent workspace folder in S3. The `persona/` subfolder within it is the PA's home — all files loaded into the system prompt live here, and all agent writes go here. A separate `_system/agent-persona/` folder holds read-only reference files used during memory maintenance and as product guidance for persona fields; these are never copied into the user workspace.

Files stored in the user's agent workspace (`persona/` folder in S3):

```
persona/
├── setup/                     ← wizard staging [system-managed during onboarding]
│   ├── config.json            ← wizard progress, agent prefs, setupCompletedAt, lastSetup snapshot
│   ├── draft.{ext}            ← in-wizard avatar selection (upload or confirmed AI portrait)
│   ├── draft.json             ← draft metadata: source (upload|ai), traceId, mimeType
│   ├── {dt}__{traceId}__avatar.{ext}                              ← generated portrait artifact
│   └── {dt}__{traceId}__avatar__stripe{id}stripe__tok{n}tok.json ← avatar generation usage record
├── IDENTITY.md              ← who the agent is         [_agent_edit_tier: 2]
├── SOUL.md                  ← how the agent operates   [_agent_edit_tier: 2]
├── USER.md                  ← about the user           [_agent_edit_tier: 2]
├── MEMORY.md                ← long-term curated memory [_agent_edit_tier: 3]
├── WORKSPACE.md             ← operating rules          [_agent_edit_tier: 1]
├── SESSIONMEMORY.md          ← mid-term session memory  [_agent_edit_tier: 3]
├── session.json             ← runtime session state    [system-managed]
├── avatar.{ext}             ← live PA profile photo (jpg/png/webp; not in IDENTITY.md)
├── inbox/
│   └── persona-updates/
│       ├── {dt}__{fileName}__{field}__new__.json    ← pending
│       └── {dt}__{fileName}__{field}__done__.json   ← accepted / rejected / dismissed
└── memory/
    ├── memory-index.json          ← topic map of all memory files [system-managed, on-demand]
    ├── policy-profile-*.md        ← per-topic deep memory    [_agent_edit_tier: 3]
    └── {topic-slug}.md            ← freeform topic notes [_agent_edit_tier: 3]
```

**`persona/setup/` — wizard staging folder**

Setup completion and agent runtime prefs are tracked in `persona/setup/config.json` (`setupCompletedAt`, in-progress `wizard`, `lastSetup` snapshot, and `agent` block). The root `agent-workspace.json` manifest is workspace shell only — the API merges `setupCompletedAt` from `config.json` when serving the workspace manifest to the UI.

During **AssistantCreate**, the wizard persists step values to `config.json` on each continue/back navigation. Avatar selection is staged at `persona/setup/draft.{ext}` + `draft.json` (upload or AI-generated). On **finalize**, `SetupService` writes live persona files and `SetupAvatarService.promoteDraftToAvatar()` copies the draft to `persona/avatar.{ext}` if one was selected. Generated portrait artifacts and tok-flagged usage JSON remain flat in `persona/setup/` for token-usage history drill-down.

Reference files in `_system/agent-persona/` (loaded during specific flows, never copied to user workspace):

| File              | Loaded When          | Purpose                                           |
| ----------------- | -------------------- | ------------------------------------------------- |
| `soul-guide.md`   | Not loaded at runtime | Product reference for SOUL field copy in wizard/edit UI |
| `memory-guide.md` | Memory maintenance   | How to keep `MEMORY.md` clean, what to distill    |

---

## File Access Model

Because the LLM has write access to files in the agent workspace, every persona file carries embedded YAML metadata that controls exactly what the agent can touch. This section defines the three-level access system — file-level agent tiers, field-level protection gates, and the `_` prefix convention for system-internal data that is never exposed to the LLM or the user.

### YAML naming convention

Two naming conventions govern every YAML field across all persona files:

- **`_` prefix** — system-internal. Set at provisioning, never displayed in the UI, never included in LLM output targets or proposals. Covers harness control fields (`_schema`, `_agent_edit_tier`, `_updated`, etc.).  These fields are not displayed, not in LLM output, not proposable - fully system owned.
- **No prefix** — user-facing. Displayed in the management UI. The user can always edit any non-`_` field directly. Agent write access is governed by `_agent_edit_tier` and `_protected`.

### Body content

The markdown body of each file is structured by `##` section headers. The agent reads and writes within sections — it does not treat the body as a monolithic blob. Proposals reference sections by header name. The template file in `_system/agent-persona/` defines the initial section scaffold; the agent maintains that structure when writing.

### File-level agent write gate

The YAML structure supports an `_agent_edit_tier` concept:

| `_agent_edit_tier` | Agent Writes | User Writes | Notes |
| --- | --- | --- | --- |
| **1** — agent-readonly | Never | Direct UI | Agent reads only — no writes, no proposals |
| **2** — agent-writable | Write freely (non-protected fields) / Queue inbox record (`_protected` fields) | Direct UI | `_protected` fields queue as inbox records under `persona/inbox/persona-updates/`; all other fields agent writes directly |
| **3** — agent-owned | Write everything freely | Direct UI (view + edit + clear for MEMORY.md) | No restrictions on agent writes |

### Field-level write gate within Tier 2

The YAML structure supports a `_protected` concept:

In a `_agent_edit_tier: 2` file, fields listed in `_protected` cannot be written directly by the agent — any proposed change is queued as an inbox record for user approval. Fields not in `_protected` are written freely by the agent.

`_protected` also signals the management UI: these fields are always displayed in forms, even when empty.

NOTE: Pending inbox records persist under `persona/inbox/{type}/` as `__new__.json` files. Browser close, logout, or any interruption does not lose them. On login, `syncPendingInbox()` loads pending counts; the **Inbox** pill on `AssistantActionBar` opens the Inbox dialog (desktop/Briefs/Edit) or scrolls to the embedded Inbox card on mobile sheet panel 1.


### Field must have a value

The YAML structure supports a `_required` concept:

Independent of `_agent_edit_tier` and `_protected`. Fields in `_required` must have a value — drives form validation in the management UI and signals to the agent it should always attempt to populate these fields during setup and conversation.

### File Layout & Access Matrix

Write behavior for each tier is defined in the `_agent_edit_tier` table above. `_` prefixed YAML fields are always system-internal regardless of tier.

| File | YAML fields | Body sections | `_agent_edit_tier` | `_protected` | `_required` |
| --- | --- | --- | --- | --- | --- |
| `WORKSPACE.md` | `boundaries` | Operating rules prose | 1 | — | — |
| `IDENTITY.md` | `name`, `tone` | `## Catchphrase`, `## Origin Story` | 2 | `[name, tone]` | `[name, tone]` |
| `SOUL.md` | `core_truths`, `tone`, `humor`, `bluntness` | `## Vibe` | 2 | `[core_truths]` | `[core_truths]` |
| `USER.md` | `preferred_name`, `role`, `legislative_focus`, `output_style` | `## Professional Context`, `## Favorites`, `## Notes` | 2 | `[preferred_name]` | `[preferred_name, role]` |
| `MEMORY.md` | — | Long-term memory prose | 3 | — | — |
| `SESSIONMEMORY.md` | `sessionId`, `chatHistoryIds` | `## This Session` prose | 3 | — | `[sessionId]` |
| `memory/memory-index.json` | — | Topic map of all memory files | system-managed | — | — |
| `memory/YYYY-MM-DD-{sessionId}.md` | `date`, `sessionId`, `summary` | Timestamped session log | 3 | — | `[date, sessionId, summary]` |
| `memory/policy-profile-*.md` | — | Policy topic notes | 3 | — | — |
| `memory/{topic-slug}.md` | — | Freeform topic notes | 3 | — | — |

---

## YAML Frontmatter — Universal Contract

Every persona file opens with a YAML frontmatter block that the harness reads before passing the file to the LLM. This block is the machine-readable contract between the service, the LLM, and the management UI — it declares the file's schema version, the agent's write permissions, which fields are user-protected, and which are required. Because it is self-describing, new user-facing fields can be added to any file without changing service code.

```yaml
---
_schema: identity/1                  # file type and version
_agent_edit_tier: 2                  # agent write gate: 1=locked, 2=writable/protected, 3=free
_updated: "2026-05-20T09:30:00Z"     # ISO timestamp — set on every write
_updated_by: "system"                # "system" | "user" | "agent"
_protected: [name, tone]              # user-facing fields that require inbox approval
_required: [name, tone]              # fields that must have a value
---
```

### Field rules

| Field | Set by | Updated by | Notes |
| --- | --- | --- | --- |
| `_schema` | System at provisioning | System only | Version bumps require a platform deploy |
| `_agent_edit_tier` | System at provisioning | System only | Governs agent write access for the whole file |
| `_updated` | Any writer | Any writer | Audit trail |
| `_updated_by` | Any writer | Any writer | `"system"` \| `"user"` \| `"agent"` |
| `_protected` | System at provisioning | System only | Fields requiring inbox approval on batch write; also UI always-visible signal |
| `_required` | System at provisioning | System only | Fields that must have a value — form validation + agent obligation |
| `_` prefixed data fields | System at provisioning | System only | Internal IDs/data — never in UI, never in LLM output |
| All unprefixed fields | Depends on `_agent_edit_tier` | Depends on `_agent_edit_tier` and `_protected` | User-facing; dynamic — new fields require no code change |

### `AgentFileFrontmatter` — TypeScript contract

```typescript
interface AgentFileFrontmatter {
  // Harness control fields — always present, system-managed
  _schema: string;                           // e.g. 'identity/1', 'user/1'
  _agent_edit_tier: 1 | 2 | 3;
  _updated: string;                          // ISO 8601
  _updated_by: 'system' | 'user' | 'agent';
  _protected: string[];                      // Tier 2: fields requiring inbox approval
  _required: string[];                       // fields that must have a value

  // System-internal data fields — _ prefix, never displayed, never in LLM output

  // User-facing fields — no prefix, displayed in UI
  [key: string]: unknown;                    // parsed dynamically
}
```

### Utility functions — `src/utils/AgentFileFrontmatter.ts`

| Function | What it does |
| --- | --- |
| `parseAgentFileFrontmatter(content)` | Extract and parse the YAML block from a file |
| `classifyFrontmatterFields(fm)` | Split into three buckets: `internal` (`_` prefix), `protected`, `editable` |
| `frontmatterToJsonSchema(fm)` | Derive a JSON Schema from `protected` + `editable` fields — used for LLM structured output |
| `serializeAgentFileFrontmatter(fm, body)` | Write updated frontmatter back into the full document |

### Write enforcement — service decision tree

The LLM never writes files directly. All writes pass through this gate:

```
Write requested for file X, field F (or body section S)
         │
         ├── F has _ prefix?  → REJECT. System-internal fields are never agent-written.
         │
         ├── _agent_edit_tier === 1?  → REJECT. Agent reads only.
         │
         ├── _agent_edit_tier === 2?
         │         ├── F in _protected[]?
         │         │      → Queue inbox record → do not write
         │         └── F not in _protected[]?
         │                → Write directly → _updated + _updated_by: "agent"
         │
         └── _agent_edit_tier === 3?
                   → Write directly → _updated + _updated_by: "agent"
```

### Write error handling

File writes are side effects — they never block the user's turn. The response is delivered first; writes happen after. Failures are handled by severity:

| Failure | Severity | Handling |
| --- | --- | --- |
| S3 write fails (Tier 3 memory) | Low | Retry 3× with backoff. If all fail: log + queue for background retry. Turn is never blocked. Agent notes the failure in session memory if it can. |
| S3 write fails (inbox record to `persona/inbox/`) | Medium | Retry 3×. If unrecoverable: surface to user ("I wasn't able to save that suggestion"). Log for investigation. |
| File parse error on read-before-write | High | Log and flag the file. Do not attempt a partial write. If `MEMORY.md` is the affected file, agent proceeds with reduced context and notes the degraded state in session. Fall back to template initialization only if explicitly triggered by `SetupService`. |
| Schema validation failure (LLM output malformed) | Medium | Reject the write entirely — never partially write. Log the malformed output for debugging. |
| Protected field write attempt (`_` prefix or `_protected`) | Low | Rejected silently by the decision tree above. Log only. No user-facing error. |

**Turn continuity:** A failed persona file write does not change the current turn's response. The LLM already produced the answer; the write failure is a background concern. The next turn loads whatever state is currently on S3 — stale if the write failed, correct once a retry succeeds.

**Degraded state:** If a critical file can't be read on startup (e.g. `MEMORY.md` missing or corrupt), the PA notes the reduced context in its system prompt and proceeds. It does not fail the turn.

---

## PA LLM Context Window Management

The PA's ability to "hear" the user — to remember what was said earlier, understand references to past work, and respond with the right context — depends entirely on what fits in the context window and how that budget is allocated. This section defines the memory hierarchy and budget rules that govern every turn.

### Memory hierarchy

The PA has three active memory layers in the prompt, plus operational turn records:

| Layer | Source | Scope | Resets | Budget |
| --- | --- | --- | --- | --- |
| **Long-term** | `MEMORY.md` | Permanent curated facts | Never — maintained by `MemoryMaintenanceService` *(Phase 3: input = turn JSON + SESSIONMEMORY)* | Full file, ~8k chars |
| **Session index** | `SESSIONMEMORY.md` | Current web session (cross-thread) | On new `sessionId` | Full file (~8k body cap) — omitted when empty |
| **Turn transcript** | `ChatTurn` JSON records | This `chatHistoryId` | Rolling — oldest dropped when budget exhausted | **20%** of context window |

**Discontinued (May 2026):** `NOTES.md`, per-turn daily memory writes, and `SESSION.md` startup/closeout checklist.

### Context window budget allocation

On a 200k token model (Claude Sonnet), the effective allocations are:

| Section | Budget | Approx. tokens | Notes |
| --- | --- | --- | --- |
| Persona files (IDENTITY, SOUL, WORKSPACE, USER, MEMORY) | ~10% | ~20k | Fixed per turn — full file content |
| `SESSIONMEMORY.md` | full file | ~10k | Only when non-empty; body capped at ~8k |
| Recent chat history (`ChatTurn` records) | **20%** | ~40k | Budget-only backward fill — **no turn-count cap** |
| Legislative context + skill catalog + routing schema | ~5% | ~10k | Injected only when relevant |
| **Reserved for user message + LLM response** | ~55% | ~110k | Never compressed — the model needs room to think and respond |

Default budget derives from `BEDROCK_CONTEXT_WINDOW` (chars ≈ tokens × 4). Former 5% `NOTES.md` slice reallocated to history.

### How the rolling window works

Chat history is the rolling layer. The service fills the **20%** history budget by loading `ChatTurn` records newest-first and stops when the budget is exhausted. There is **no artificial turn-count cap**.

`SESSIONMEMORY.md` is included in full when non-empty. Post-turn, `SessionMemoryIndexService` **upserts** one `## {chatHistoryId}` block per thread (v3 index: title, questions, outcome, topics, `### Turns` trace lines) — deterministic, no LLM. Body trimmed at ~8k chars (oldest turn lines / blocks dropped first).

### What this means for attentiveness

A user asking "can you summarize the last bill on your original list?" is resolved in priority order:

1. **Recent turns** — verbatim Q/A within the history budget (includes `reasoning` on each turn)
2. **`SESSIONMEMORY.md`** — cross-thread session index when the list was discussed in another conversation this web session
3. **`get_chat_history` tool** — on-demand load of turn JSON for a past `chatHistoryId`
4. **Ask for clarification** — if none of the above have it and the reference predates available records

## Core Persona Files

These are the files loaded into the PA's system prompt on every turn (when `setupComplete`). `WORKSPACE.md` is read-only for the agent. `SESSIONMEMORY.md` is tier-3 and written post-turn by `SessionMemoryIndexService` — the harness owns the write, not the LLM. `MEMORY.md` is not written during chat turns.

### `IDENTITY.md` — `_agent_edit_tier: 2`

Who the agent is. Set during onboarding, user-editable at any time via management screen.

| Field | `_protected` | `_required` | Content |
| --- | --- | --- | --- |
| `name` | Yes | Yes | What the user calls the agent |
| `tone` | Yes | Yes | How the agent comes across — specific, not generic |
| `## Catchphrase` *(body)* | No | No | Signature phrase — agent can develop naturally |
| `## Origin Story` *(body)* | No | No | How the agent came to be — narrative prose |

**Avatar:** stored separately at `persona/avatar.{ext}` — not a YAML field in `IDENTITY.md`. During setup, the wizard stages selection at `persona/setup/draft.{ext}`; finalize promotes it to `persona/avatar.{ext}`. Post-setup, **Assistant Edit** uses `POST /rap/assistant/avatar` and `DELETE /rap/assistant/avatar` for the live profile photo.

**YAML + body split:**
- YAML fields (`name`, `tone`) are templated into the identity block: `"You are {{name}}. {{tone}}"`
- Body sections (`## Catchphrase`, `## Origin Story`) are injected as prose — richer than YAML fields, agent writes within sections

---

### `SOUL.md` — `_agent_edit_tier: 2`

The agent's operating principles and voice. All fields are user-owned — nothing is platform-locked. The user decides what their assistant believes.

```yaml
---
_schema: soul/1
_agent_edit_tier: 2
_updated: ""
_updated_by: "system"
_protected: [core_truths]
_required: [core_truths]
core_truths: |
  Be genuinely helpful, not performatively helpful.
  Have opinions on the work. When something looks off, say so.
  Earn trust through accuracy. When uncertain, say so clearly.
  Distinguish retrieved from inferred — always.
tone: ""
humor: ""
bluntness: ""
---

## Vibe

_(Built during setup and refined over time.)_
```

| Field | `_protected` | `_required` | Content |
| --- | --- | --- | --- |
| `core_truths` | Yes | Yes | Behavioral principles — agent must propose changes, user approves or sets directly |
| `tone` | No | No | Agent writes directly |
| `humor` | No | No | Agent writes directly |
| `bluntness` | No | No | Agent writes directly |
| `## Vibe` *(body)* | No | No | Narrative personality prose — agent writes freely |

**YAML + body split:**
- `core_truths`: templated as a behavioral instruction block in the system prompt. In `_protected` — agent must propose changes, not rewrite silently.
- `tone`, `humor`, `bluntness`: templated as structured personality hints
- Body (`## Vibe`): injected as prose — the agent's full personality narrative

---

### `USER.md` — `_agent_edit_tier: 2`

The agent's model of the user. System-internal account fields use `_` prefix and are never surfaced. Profile fields fill in through setup and conversation.

```yaml
---
_schema: user/1
_agent_edit_tier: 2
_updated: ""
_updated_by: "system"
_protected: [preferred_name]
_required: [preferred_name, role]
preferred_name: "{{USER_NAME}}"
role: ""
legislative_focus: []
output_style: ""
---
```

| Field | `_protected` | `_required` | Content |
| --- | --- | --- | --- |
| `preferred_name` | Yes | Yes | What the agent calls the user — proposal required to change |
| `role` | No | Yes | Professional role — agent fills in as it learns |
| `legislative_focus` | No | No | Issue areas, chambers, committees — agent fills in |
| `output_style` | No | No | Preferred response format — agent fills in |
| Body sections | No | No | Professional Context, Favorites, Notes — built over time |

**YAML + body split:**
- YAML fields are templated into the user context block: `"Your user goes by {{preferred_name}}, a {{role}} focused on {{legislative_focus}}."`
- Body carries rich narrative context the LLM reads for nuance (timezone, working style, notes)

---

### `MEMORY.md` — `_agent_edit_tier: 3`

Long-term curated memory. Agent reads and writes freely. Distilled from turn JSON and SESSIONMEMORY over time — not a raw log. When it exceeds the context budget (~8k chars), detailed material moves to `memory/*.md` and `MEMORY.md` stays as the compact summary layer.

```yaml
---
_schema: memory/1
_agent_edit_tier: 3
_updated: ""
_updated_by: "agent"
_memory_index: "persona/memory/memory-index.json"
---
```

The `_memory_index` field is a `_`-prefixed system pointer — never displayed in the UI, never an LLM write target. It tells the PA where to find the index when it needs to do a detailed memory lookup.

**Detailed memory drill-down pattern:**

The PA uses a three-level lookup rather than loading all memory files blindly:

1. **`MEMORY.md`** (always loaded) — compact curated summary; answers most questions directly
2. **`load_memory_index`** workspace operation — loads `memory-index.json`, a lightweight topic map of all memory files with summaries and topic tags; lets the PA identify which specific file has the detail it needs
3. **`get_chat_history(chatHistoryId)`** — loads turn JSON for another thread when detail is not in session index or history budget

**`memory-index.json` schema** (`MemoryIndex` in `packages/shared/storage-client/src/types/agent-workspace.ts`):

```json
{
  "updatedAt": "2026-05-21T14:00:00Z",
  "files": [
    {
      "key": "accounts/{accountId}/users/{userId}/persona/memory/policy-profile-education-reform.md",
      "summary": "Education reform tracking — SB 456, HB 789",
      "topics": ["education reform", "SB 456", "HB 789"],
      "distilled": false
    },
    {
      "key": "accounts/{accountId}/users/{userId}/persona/memory/2026-homestead-taxes.md",
      "summary": "Homestead exemption research — constitutional amendment timeline",
      "topics": ["homestead", "property tax", "constitutional amendment"],
      "distilled": true
    }
  ]
}
```

`MemoryMaintenanceService` already reads every memory file during distillation — writing/updating the index is a free side-effect of that run. The index is never loaded into the system prompt; it is only accessed on demand via `load_memory_index`.

---

### `WORKSPACE.md` — `_agent_edit_tier: 1`

Static operating rules and operational boundaries. Agent reads only — never writes.

| Field | Content |
| --- | --- |
| `boundaries` | Operational limits — what the agent will and won't do (e.g. don't exfiltrate data, ask before sending external messages) |

**YAML + body split:**
- `boundaries`: templated into the operating rules block of the system prompt
- Body: file system conventions, memory policy, tool guidance, external vs. internal action rules

---

### `SESSIONMEMORY.md` — `_agent_edit_tier: 3`

Cross-thread session index for the current web session. When the user switches `chatHistoryId`, the PA still sees what happened in other conversations today. **Not** a raw transcript — one structured block per thread.

```yaml
---
_schema: session-memory/v3
_agent_edit_tier: 3
_updated: ""
_updated_by: "system"
_required: [sessionId]
sessionId: ""
chatHistoryIds: []
---
```

| Field | `_required` | Content |
| --- | --- | --- |
| `sessionId` | Yes | Web session ID — mismatch with `session.json` resets the body |
| `chatHistoryIds` | No | Conversation threads touched this session |

**Body shape** — one section per thread (`## {chatHistoryId}` is the thread key; no separate Chat ID line):

```markdown
## conv-{id}

Title: Florida bills about cats
Contributors: User, Assistant (User's Assistant)
Started: …
First question: what bills deal with cats?
Last question: overview of the first item
Turns: 2
Bill scope: fl/2026/1004
Topics: cat, cats, feline, …
Last active: 2026-06-02T06:39:51.621Z

### Turns
- req-… · turn 1 · work · policy-command-legislative-search
  Q: what bills deal with cats?
  Outcome: 4 sources · policy-command-legislative-search
- req-… · turn 2 · work · policy-command-legislative-review · get_chat_history
  Q: overview of the first item
  Outcome: 1 source · policy-command-legislative-review
```

Block header = **routing index** (questions, scope, topics). Per-turn trace, skill, and outcome live only under `### Turns`.

**Post-turn write:** `SessionMemoryIndexService.upsertAfterTurn()` — fire-and-forget. Title, questions, and turn lines come from the orchestrator (ALS + turn payload), not a race-prone summary re-read. No LLM.

**Session reset:** same as before — `sessionId` frontmatter mismatch clears body and `chatHistoryIds`.

**Omitted from the prompt when empty.**

---

### `session.json` — system-managed

Runtime session state. Written by the service at login, never by the agent. Not loaded into the LLM system prompt — used by the service layer only.

```json
{
  "sessionId": "kc-session-id",
  "startedAt": "2026-05-21T09:00:00Z",
  "lastActiveAt": "2026-05-21T14:30:00Z",
  "lastMemoryClean": "2026-05-20"
}
```

`lastMemoryClean` is the date of the last successful `MemoryMaintenanceService` run. The service filters `persona/memory/` for files with a date the same or newer than this value and checks if any have `distilled: false` — if none exist, it exits immediately without doing any work.

---

## PA Prompt Assembly

This section defines exactly what is sent to the LLM at each phase of a turn — what goes in the system prompt, what goes in the messages array, and what each call returns. Persona files live entirely in the PA layer (`AssistantContext` ALS) and are never visible to worker agents in the GENERATE phase. Every user-facing response is the product of a dedicated crafting call, not a side-effect of routing.

> **Note:** When `setupCompletedAt` is not yet set, persona files (`IDENTITY.md`, `SOUL.md`, etc.) are omitted from every prompt described below — the PA runs on generic context until setup is complete.

### PA modes and pipeline

INTERPRET is a fast, deterministic classification call — it routes, rewrites the question, and extracts keys. It does not generate user-facing responses. Every user-facing response is produced by a dedicated crafting call.

| Mode | INTERPRET output | Next step | User-facing response from |
| --- | --- | --- | --- |
| `work` | `skill` selected | Worker skill → ALIGN | ALIGN (tone-aligned worker result) |
| `conversation` | routing only | RESPOND | RESPOND (full PA call with full persona + workspace ops) |
| `clarify` | clarifying question text | — | INTERPRET `directAnswer` (brief, no persona crafting needed) |
| `greeting` | greeting text | — | INTERPRET `directAnswer` (brief, no persona crafting needed) |

**INTERPRET is a routing oracle** — lean, low-temperature, structured JSON only. Generating a full conversational response in the same call blurs two concerns: *what should I do?* and *how should I respond?* Separating them keeps INTERPRET fast and predictable, and ensures every substantive response is crafted by a dedicated call with full persona context. `clarify` and `greeting` are brief enough that a second call isn't justified.

**Setup is not an INTERPRET mode.** It is a user-initiated provisioning flow from the **Assistant Status** card on `/dashboard/profile/assistant/edit` → `/dashboard/profile/assistant/create` (AssistantCreate wizard). It never enters the normal chat pipeline. INTERPRET only runs when `setupComplete = true` and the PA is active.

**Full pipeline by mode:**
```
conversation:  INTERPRET (classify) → RESPOND (PA with full persona + workspace ops)
work:          INTERPRET (classify) → worker skill → ALIGN (tone-align to persona)
clarify:       INTERPRET (classify + directAnswer) → return immediately
greeting:      INTERPRET (classify + directAnswer) → return immediately

setup:         UI wizard → POST /rap/assistant/setup/finalize → SetupService.finalizeSetup()
               (entirely separate from the chat pipeline; no setup LLM turns)
```

### INTERPRET — what is sent

A lean `[system, user]` pair. INTERPRET uses full persona context to make a good routing decision, but has no workspace operations — those belong in RESPOND where they enrich the response.

**System prompt sections:**

| Section | Source | Notes |
| --- | --- | --- |
| `## Your identity` | `IDENTITY.md` | Full file content |
| `## Your purpose` | `SOUL.md` | Full file content |
| `## Your operating rules` | `WORKSPACE.md` | PA boundaries and operating constraints — INTERPRET respects these when routing |
| `## About your user` | `USER.md` | Full file content |
| `## Your long-term memory` | `MEMORY.md` | Full file content |
| `## Recent conversation history` | `ChatTurn` JSON records | **20%** budget, newest-first, no turn cap. Includes `reasoning` (concatenated INTERPRET / ALIGN / RESPOND at save). |
| `## This PA session` | `SESSIONMEMORY.md` (persona/) | Session index — omitted when empty |
| Active legislative context | `billKeys`, `statuteKeys`, `workingSession`, `defaultStatuteYear`, `state` | Injected when present. `state` = jurisdiction (hardcoded `FL` in service today). See `## Legislative focus (UI + request)`. |
| Skill catalog | `SkillRegistry.catalogForPrompt()` | Brief XML summaries for routing |
| Allotment | `UserAllotmentService` | Turns remaining, low-allotment flag |
| Mode decision guide + output schema | Hardcoded | Routing logic and structured JSON output format |

> **Cross-thread references** — turn JSON for this thread first, then `SESSIONMEMORY.md`, then `get_chat_history` for another `chatHistoryId`.


**Messages array:** `[system, user]` — user's message this turn only.

**Returns:** structured JSON — `{ mode, skill, question, wasRewritten, billKeys, statuteKeys, directAnswer?, conversationTitle?, reasoning }`

`directAnswer` is only populated for `clarify` and `greeting`. Setup never reaches INTERPRET.

### RESPOND — assistant worker call (`conversation` mode only)

A dedicated PA crafting call. Full persona context, full workspace operation access, no routing constraints.

**System prompt sections:**

| Section | Source | Notes |
| --- | --- | --- |
| `## Your identity` | `IDENTITY.md` | Full file content |
| `## Your purpose` | `SOUL.md` | Full file content |
| `## Your operating rules` | `WORKSPACE.md` | PA boundaries and operating constraints |
| `## About your user` | `USER.md` | Full file content |
| `## Your long-term memory` | `MEMORY.md` | Full file content |
| `## Recent conversation history` | `ChatTurn` records | Same **20%** budget as INTERPRET |
| `## This PA session` | `SESSIONMEMORY.md` | Omitted when empty |
| Active legislative context | From ALS | `billKeys`, `statuteKeys`, `workingSession`, `defaultStatuteYear`, `state` — carried forward from INTERPRET result |
| INTERPRET summary | From ALS | Mode, rewrite, keys — so RESPOND knows what INTERPRET decided |
| Available workspace operations | See table below | Full access — memory, activity, library |

**Messages array:** `[system, user]` — user's original message.

**Returns:** `{ answer, reasoning, tokens }` — the PA's conversational response and a one-sentence reasoning note. No persona field proposals on chat turns.

### PA workspace operations

Workspace operations are the PA's tool calls — atomic reads and writes against S3 or the database. RESPOND's LLM decides to invoke one; it executes synchronously and returns data inline. Think of them as the PA's direct access to the user's workspace data — no LLM, no pipeline, just a query.

Distinctions from worker skills:

| | Workspace operation | Worker skill |
| --- | --- | --- |
| Has its own LLM call? | No — pure data access | Yes — full LLM execution |
| Execution time | Milliseconds | Seconds |
| Dispatched from | RESPOND (inline, via function calling) | INTERPRET (routing decision) |
| Complexity | Single deterministic read/write | Multi-step: PREPARE → GENERATE → VALIDATE |

**Decision rule: if an operation requires LLM synthesis → worker skill. If it is a data read or write → workspace operation.**

**INTERPRET retrieval tools** (no writes during chat):

| Operation | What it does |
| --- | --- |
| `get_chat_history` | Load turn JSON for another conversation thread by `chatHistoryId` |
| `get_user_activity` | Navigation history, past sessions, bills viewed (DB) |
| `get_user_library` | Saved bills, bookmarks, watchlist, annotated documents (DB) |

`MEMORY.md` and `SESSIONMEMORY.md` are **not** written via INTERPRET tools. Post-turn index upsert and future distillation/review jobs own those writes.

**Planned / legacy (not on INTERPRET registry today):**

| Operation | Status |
| --- | --- |
| `load_memory_index` | Planned |
| `load_topic_memory` | Planned |
| `update_memory` | **Not on chat path** — distillation / review jobs only |

### Candidate PA workspace operations

**Count guidance:** Keep the total list under ~10. Above that, LLM tool selection reliability degrades. One operation per distinct data source or action — group by access pattern, not by feature.

The current 5 operations cover `persona/` memory reads/writes. These candidates extend coverage to the rest of the agent workspace and structured profile data:

| Candidate operation | Data source | What it returns |
| --- | --- | --- |
| `get_policy_profile` | Policy profile storage (S3/DB) | Profile summary: name, handle, focus areas, associated bill/statute count, last updated, recent activity note. **Not** the full raw profile JSON — too large to inject inline. The PA's `memory/policy-profile-{handle}.md` is the agent's notes layer; this operation is the structured data layer. |
| `get_session_notes` | Current session memory (S3) | Running notes for the active session — what was covered earlier in this specific chat before the current turn |
| `list_artifacts` | Agent workspace artifact records (S3) | List of available artifact files (reports, briefs, analyses) with filename, type, created date, and a one-line description from the `.json` metadata record |
| `get_artifact` | Agent workspace (S3) | A specific artifact's `.json` metadata record by filename — surfaces a past report or brief into context |
| `get_pending_inbox` | `persona/inbox/` (S3) | List of pending inbox records — lets the PA acknowledge or reference them conversationally *(candidate)* |

### ALIGN — what is sent

ALIGN runs **only for `work` mode** after the worker produces an answer. It uses a separate, smaller system prompt compared to the other paths.

**System prompt sections:**

| Section | Source | Notes |
| --- | --- | --- |
| Role + hard constraints | Hardcoded | Never alter citations, structure, or facts |
| INTERPRET summary | From ALS | Mode, skill, question, bill/statute keys, rewrite details |
| `## User preferences` | `SOUL.md` + `MEMORY.md` + `USER.md` | The three personalization files only — no identity, no session memory, no chat history |
| Allotment note | ALS | Injected when allotment is low |
| Confidence caveat | ALS | Injected when worker confidence is below threshold |

**Messages array:**

| Slot | Content |
| --- | --- |
| `system` | The ALIGN system prompt above |
| `user` | The raw worker response |

**Returns:** `{ answer, reasoning, tokens }` — tone-aligned response and a 1–2 sentence reasoning note. No persona field proposals on chat turns.

### Worker LLM calls — GENERATE

Workers receive no persona context. They operate in a separate `WorkingContext` (ALS scope):

| Slot | Content |
| --- | --- |
| `system` | `SKILL.md` instructions, built into `WorkerExecutionPlan` by PREPARE |
| `user` | Rewritten question + assembled evidence set |
| Tool results | Previous tool call results (agentic mode only) |

### Current worker skills

Three legislative skills are registered:

| Skill | Purpose |
| --- | --- |
| `policy-command-legislative-analysis` | Deep analysis of a specific bill or statute |
| `policy-command-legislative-search` | Find and filter legislation by topic, keyword, or criteria |
| `policy-command-legislative-review` | Review and compare bill versions, amendments, or related legislation |

### Candidate new worker skills

Each candidate requires LLM synthesis — that's what makes it a skill rather than a workspace operation. Dispatching to a dedicated worker keeps RESPOND focused on the conversational experience and prevents context bloat.

All worker skills follow the `policy-command-*` naming convention. This prefix distinguishes platform-created skills from user or guide-provisioned skills, which may be added by third parties in future.

| Candidate skill | Purpose | Trigger |
| --- | --- | --- |
| `policy-profile-report` | Generate a periodic change summary or brief from a policy profile — associated bills, statutes, and agent working notes | User asks for "weekly report", "what changed", "policy brief" on a profile |
| `workspace-activity-brief` | Summarize recent user activity across sessions, library, and chat history into a structured digest | User asks "what have I been working on", "summarize last week" |

NOTE: Artifact output (PDF + `.json` metadata record) is a planned future capability for these skills. Not in scope until file creation and the `__artifact__` pattern are implemented. See global `TODO.md` for the artifact design. The `list_artifacts` and `get_artifact` workspace operations are correspondingly deferred.

---

## User-Gated Updates — Assistant Inbox

The PA learns from sessions — but the user stays in control. Protected persona field changes are **never** applied during chat turns. Instead, batch review (`MemoryReviewService`) or future dreaming queues inbox records: current value, proposed value, and plain-language reason. The user accepts or rejects in the **Inbox** dialog (`AssistantInboxPanel`).

**Not per-turn:** ALIGN and RESPOND answer only. Learning runs separately via consolidate, scan, or scheduled dreaming.

Inbox records persist immediately as `__new__.json` under `persona/inbox/{type}/`. Pending counts sync on login; the **Inbox** row on `AssistantActionBar` (Briefs, Chat, Assistant Edit) opens the modal.

### Inbox record sources

| Source | When | Example |
| --- | --- | --- |
| **Memory review** | User clicks **Review and learn** on Memories tab, or dreaming *(planned)* | Recent activity surfaces a durable preference → queue Assistant Settings field change to inbox |
| **Direct write** | Non-protected Tier 2 field during batch review | Agent writes editable field immediately; no inbox record |

Per-turn ALIGN/RESPOND **do not** queue inbox records.

### UX flow

```
User triggers scan (Memories tab) or dreaming (planned)
         ↓
MemoryReviewService LLM reads SESSIONMEMORY.md + recent turn JSON
         ↓
PersonaWriteService.writeField() — protected → persona/inbox/{type}/__new__.json
         ↓
syncPendingInbox() — counts by type on AssistantActionBar
         ↓
User clicks Inbox pill on AssistantActionBar → Inbox dialog (or embedded Inbox card on mobile sheet)
         ↓
Each card: field path, current → proposed, reason, trigger label
         ↓
Accept → write persona file → rename to __done__.json (outcome: accepted)
Reject → rename to __done__.json (outcome: rejected)
```

### Inbox record shape (persona-updates)

Payload fields: `fileName`, `field`, `currentValue`, `proposedValue`, `reason`. Envelope: `AssistantInboxRecord` in `storage-client/types/agent-inbox.ts`. Type is the folder slug (e.g. `persona-updates`); lifecycle is in the filename (`__new__.json` → `__done__.json`).

### Key UX principles

- **Never block the chat.** Inbox queues outside the turn pipeline.
- **Show the diff.** Current value → proposed value, not just the new value.
- **Show the reason.** Without the why, users accept or reject blindly.
- **Batch.** Multiple items reviewed together in one modal.
- **Label the trigger.** e.g. `memory-review`, `dreaming` — context matters.
- **Single inbox entry point.** `AssistantActionBar` Inbox pill — not duplicated on Memories tab.

---

## Pipeline Sequencing — Turn Lifecycle

This section traces the full lifecycle of a single turn through the RAP service — from the incoming HTTP request to the written `ChatTurn` record — showing exactly where persona files are loaded, where each LLM call fires, and when file writes occur. The pipeline varies by mode: `work` dispatches to a legislative worker skill; `conversation` dispatches to the PA's own RESPOND call; `clarify` and `greeting` return immediately from INTERPRET.

Persona files live entirely in the PA layer (`AssistantContext` ALS).

### `work` mode

```
POST /api/v1/assistant/chat
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│  PHASE 1 — INTERPRET  (PA LLM call #1)                  │
│                                                         │
│  AssistantOrchestrator establishes AssistantContext     │
│  WorkspaceService loads persona files + chat history    │
│  LLM: classify intent, select skill, rewrite question   │
│  → returns { mode:"work", skill, question, keys }       │
└────────────────────────┬────────────────────────────────┘
                         │ AssistantIntent
                         ▼
┌─────────────────────────────────────────────────────────┐
│  PHASES 2–5 — WORKER SKILL HARNESS                      │
│                                                         │
│  WorkerAgent establishes WorkingContext (separate ALS)  │
│  Persona files NOT visible — SKILL.md only              │
│  PREPARE → ASSEMBLE → GENERATE → VALIDATE               │
└────────────────────────┬────────────────────────────────┘
                         │ ValidatedResponse
                         ▼
┌─────────────────────────────────────────────────────────┐
│  PHASE 6 — ALIGN  (PA LLM call #2)                      │
│                                                         │
│  System prompt: soul + memory + userProfile only        │
│  LLM: tone-align worker result to user preferences      │
│  → returns { answer, reasoning }                        │
│  Service: write ChatTurn → upsert SESSIONMEMORY index   │
└─────────────────────────────────────────────────────────┘
```

### `conversation` mode

```
POST /api/v1/assistant/chat
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│  PHASE 1 — INTERPRET  (PA LLM call #1)                  │
│  → returns { mode:"conversation", question, keys }      │
└────────────────────────┬────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│  PHASE 2 — RESPOND  (PA LLM call #2)                    │
│  Full persona context; answers only — no proposals      │
│  → returns { answer, reasoning, tokens }                  │
│  Service: write ChatTurn → upsert SESSIONMEMORY index   │
└─────────────────────────────────────────────────────────┘
```

### `clarify` / `greeting` modes

INTERPRET returns a `directAnswer` directly. No second call. These are brief responses where persona crafting doesn't add meaningful value and the latency cost isn't justified. 

### Update trigger map

| Trigger | When | File(s) | Tier | Mechanism |
| --- | --- | --- | --- | --- |
| User triggered setup | AssistantCreate wizard → `POST /rap/assistant/setup/finalize` | `IDENTITY.md`, `SOUL.md`, `USER.md`, `persona/setup/config.json` (+ optional `avatar.{ext}` promoted from draft) | 2 | Provisions `persona/` folder, seeds templates, sets `setupCompletedAt` + `agent` in `config.json` |
| Batch memory review | User-triggered scan or dreaming *(planned)* | Tier 2 protected fields | 2 | `POST /rap/assistant/memory/review` → inbox queue |
| Session index write | Post-turn (`firePostTurnSideEffects`) | `SESSIONMEMORY.md` | 3 | `SessionMemoryIndexService` — deterministic upsert, no LLM |
| Memory distill | User **Distill memory** *(disabled until Phase 3 turn-JSON pipeline)* | `MEMORY.md` | 3 | `POST /rap/assistant/memory/consolidate` |
| Dreaming | Background job *(planned)* | Same as consolidate + scan | 3/2 | Scheduled — not yet implemented |
| Login session refresh | Login (`syncOnLogin`) | `session.json`, `SESSIONMEMORY.md` (reset on new sessionId) | — | `SetupService.refreshSession()` + frontmatter mismatch reset |

### LLM writes by phase

| Phase | LLM | Writes persona files? | Mechanism |
| --- | --- | --- | --- |
| INTERPRET | PA LLM | No — classify and route only | N/A |
| GENERATE | Worker LLM | No — persona files not in scope | N/A |
| ALIGN | PA LLM | Tone-align only — no persona proposals | N/A |
| RESPOND | PA LLM | Answer only — no persona proposals | N/A |
| Memory review | Batch LLM (user-triggered) | Tier 2 via inbox; Tier 3 direct | `POST /rap/assistant/memory/review` |
| Dreaming | Background LLM *(planned)* | Same as memory review | Scheduled `memory/review` + consolidate |

---

## Agent Learning System

The PA improves through three loops at different timescales. **Chat turns answer the user only** — learning and adaptation run separately so INTERPRET, ALIGN, and RESPOND stay focused.

> **Implementation status (May 2026):** Post-turn `SessionMemoryIndexService` upsert runs after every turn. **Distill memory** reads turn JSON + SESSIONMEMORY. **Review and learn** is user-triggered from the Memories tab. Inbox review UI is live (`AssistantInboxPanel` + accept/reject cards); Edit-before-accept and batch actions are backlog.

### Per turn — remember (cheap, automatic)

After every turn (`firePostTurnSideEffects`):

- Write `ChatTurn` JSON (canonical transcript) including `reasoning` — concatenated at save: `INTERPRET: … ALIGN: … RESPOND: …` (only phases that ran; see `buildTurnReasoning()`)
- Upsert `persona/SESSIONMEMORY.md` block for this `chatHistoryId` via `SessionMemoryIndexService`

No LLM calls. No persona profile changes. No inbox items.

ALIGN (`work` mode) tone-aligns worker output only. RESPOND (`conversation` mode) answers from persona context only. Neither returns `proposals[]`.

### Session — distill memory (user-triggered or first turn of day)

**Distill memory** (`POST /rap/assistant/memory/consolidate`) — reads turn JSON + SESSIONMEMORY and merges into `MEMORY.md`.

`MEMORY.md` is loaded into INTERPRET and RESPOND — primary channel for learned context on future turns.

### Adapt — review and learn (user-triggered or dreaming)

**Review and learn** (`POST /rap/assistant/memory/review`) starts `MemoryReviewService` in the background (fire-and-forget). Same immediate `{ accepted: true }` response — refresh the page or check **Inbox** for results.

When the job runs:
1. Read `SESSIONMEMORY.md` + recent turn JSON (recent activity)
2. LLM scan for durable preference signals (explicit or repeated)
3. Route each through `PersonaWriteService.writeField()` — protected fields → `persona/inbox/persona-updates/` as `__new__.json` (Assistant Settings suggestions)
4. User accepts/rejects via **Inbox** on `AssistantActionBar` → Inbox dialog (`AssistantInboxPanel`)

Rejected inbox items (`__done__.json` with `outcome: rejected`) are loaded during review so the same field is not re-suggested.

Dreaming *(planned)* — scheduled/triggered run of the same consolidate + review pipeline.

### Response ratings *(planned)*

Thumbs up/down on chat turns and Assistant Brief responses. Will feed distillation quality signals, not per-turn persona proposals.

### How learning signals reach the PA

| Signal | How it reaches the LLM | When |
| --- | --- | --- |
| Accepted inbox items | Written to Tier 2 persona files → loaded every turn | After user accepts |
| `MEMORY.md` | Always in INTERPRET + RESPOND | After consolidate |
| Daily / session logs | On-demand tools; source for batch review | Not in every turn prompt |
| Dreaming outputs | Via `MEMORY.md` and policy profile files | Background |
| Response ratings | *(planned)* | TBD |

---

## Setup Service

The Setup Service provisions a user's PA persona after first-run wizard completion — completely outside the normal chat pipeline. It is triggered when the user finishes **AssistantCreate** (`/dashboard/profile/assistant/create`), not by INTERPRET classification, and is the only path to setting `setupCompletedAt` (written to `persona/setup/config.json`).

Until setup completes, the PA operates with no persona context (`setupCompletedAt` is null) — persona files are omitted from every system prompt and the PA runs on generic context.

### Entry points (web)

| Surface | Route / action |
| --- | --- |
| First-time setup | **Complete setup** on `AssistantActionBar` / menu → `/dashboard/profile/assistant/create` |
| Post-setup management | **Assistant Settings** → `/dashboard/profile/assistant/edit` (`AssistantEdit.tsx`) |
| Completed users hitting create | Redirect to edit (unless `?restart=1`) |
| Re-run setup | **Re-run setup** link → `/dashboard/profile/assistant/create?restart=1` — prefill from `lastSetup`, overwrites persona files on finalize |

Chat-based setup (`POST /rap/assistant/setup` turn loop) and `setup-guide.md` are **removed**. Persona file writes during finalize do not spend chat allotment tokens; AI avatar generation during the wizard does spend tokens (logged to `persona/setup/`).

### API flow

```
AssistantCreate wizard
  → PUT /rap/assistant/setup/draft          — persist step values + lastStep on each navigation
  → GET /rap/assistant/setup/config          — resume wizard; read lastSetup for re-run prefill
  → [Avatar step] AssistantAvatarPickerModal:
        PUT /rap/assistant/setup/avatar/draft   — save upload or confirmed AI portrait to persona/setup/draft.{ext}
        POST /rap/assistant/setup/avatar        — generate one AI portrait (optional reference photo); artifact + usage JSON flat in persona/setup/
        GET/DELETE …/setup/avatar/draft         — read or clear staged draft
  → POST /rap/assistant/setup/finalize { collectedFields, aboutDraft, assistantDraft, userName }
        → SetupService.finalizeSetup()        — write IDENTITY, SOUL, USER, templates, session.json, config.json
        → SetupAvatarService.promoteDraftToAvatar() — copy persona/setup/draft.{ext} → persona/avatar.{ext} if present
  → Complete step → navigate to Assistant Edit (Memories tab) or Chat
```

Post-setup avatar changes on **Assistant Edit** use `POST /rap/assistant/avatar` and `DELETE /rap/assistant/avatar` directly against `persona/avatar.{ext}` — not the setup draft endpoints.

This flow is separate from `POST /rap/assistant`. It does not go through `AssistantOrchestrator`, does not run INTERPRET, and does not write `ChatTurn` records.

### Wizard steps (AssistantCreate)

| Step | Collects | Maps to |
| --- | --- | --- |
| About You | preferred name, role, output style, legislative focus, professional context, favorites | `USER.md` |
| Identity | assistant name, tone, catchphrase, origin story | `IDENTITY.md` |
| Soul | core truths, humor, bluntness, vibe | `SOUL.md` |
| Avatar | upload, AI portrait, or skip | `persona/setup/draft.{ext}` → promoted to `persona/avatar.{ext}` on finalize |
| Review | read-only summary + avatar preview → **Create Assistant** | calls finalize |
| Complete | success screen — CTA to Memories tab or Chat | — |

Wizard state persists across sessions via `persona/setup/config.json` (`wizard.lastStep`, `wizard.about`, `wizard.assistant`). Required before finalize: `identity.name`, `user.preferred_name`, `user.role`, `soul.core_truths`, `soul.humor`, `soul.bluntness`. Avatar is optional — user can skip and add later in Assistant Settings.

### What gets written (finalize)

| File | Source | How seeded |
| --- | --- | --- |
| `IDENTITY.md` | Wizard fields | `name`, `tone` in frontmatter; `## Catchphrase`, `## Origin Story` body sections |
| `SOUL.md` | Wizard fields | `core_truths`, `humor`, `bluntness` in frontmatter; `## Vibe` body |
| `USER.md` | Wizard + account data | `preferred_name`, `role`, `legislative_focus`, `output_style`; Professional Context + Favorites in body |
| `WORKSPACE.md` | Template copy | Copied verbatim from `_system/agent-persona/WORKSPACE.md` |
| `SESSIONMEMORY.md` | Template copy | Copied verbatim from `_system/agent-persona/SESSIONMEMORY.md` |
| `MEMORY.md` | Empty | Initialised on first setup only — preserved on re-setup |
| `session.json` | Service-written | New `sessionId`, `startedAt`, `lastMemoryMaintenance` |
| `persona/setup/config.json` | Service-written | `setupCompletedAt`, `lastSetup` snapshot; wizard draft cleared |
| `avatar.{ext}` | Wizard draft (optional) | Promoted from `persona/setup/draft.{ext}` when user selected one |

### Re-setup

Users with `setupCompletedAt` set are redirected to **Assistant Edit** if they open the create URL without `?restart=1`. **Re-run setup** (`?restart=1`) reopens the wizard prefilled from `lastSetup`, then on finalize overwrites `IDENTITY.md`, `SOUL.md`, and `USER.md`, re-copies template files, resets `session.json`, and preserves `MEMORY.md`. Persona field edits without re-running the wizard happen on **Assistant Edit**.

### Session refresh

`POST /rap/assistant/session/refresh` → `SetupService.refreshSession()` — new `sessionId` on login, preserves `lastMemoryMaintenance` and `lastMemoryReview`.

---

## Assistant Management Screen

The management screen is the user's direct control panel for their PA — the only place outside of conversation where they can read and edit persona files. It maps to `apps/web/src/pages/dashboard/profile/AssistantEdit.tsx`. First-time setup uses `AssistantCreate.tsx` at `/dashboard/profile/assistant/create`. Every non-`_` field is surfaced on edit; system-internal fields are never shown.

Shared UI lives in `apps/web/src/components/assistant/`:

| Component | Role |
| --- | --- |
| `AssistantActionBar` | PA presence shell — avatar/name, date, scope pills, nav pills (New Chat / Inbox / Manage Focus); Briefs, Chat (inline below composer), Assistant Edit |
| `AssistantModals` / `useAssistantModals()` | Separate portaled **Focus** and **Inbox** dialogs — opened from action bar pills |
| `AssistantFocusPanel` | Focus settings content (platform, session, year, chat/bill/statute pins) |
| `AssistantInboxPanel` | Loads inbox API, renders proposal cards |
| `AssistantInboxProposalCard` | Accept/reject card for `persona-updates` inbox type |
| `AssistantAvatarPickerModal` | Upload + optional reference photo + single AI portrait generate/regenerate |
| `AssistantSetupAvatarSection` | Avatar step shell in the setup wizard |
| `AssistantSetupReview` | Read-only review summary before finalize |
| `PersonaFieldLabel` + `TextInput` / `TextArea` / `SelectInput` | Shared field chrome across Create and Edit |
| `SetupAvatarArtifactModal` | Token usage drill-down for setup avatar generation runs |

### Page layout (`AssistantEdit.tsx`)

1. **Page header** — title + back link
2. **`AssistantActionBar`** — same PA presence panel as Briefs and Chat (see `## PA Presence`)
3. **Assistant Status** — setup/personalization badge, created/updated timestamps, workspace version, agent model config
4. **Assistant Settings** — tabbed persona editor (locked until personalization completes)

Until `setupCompletedAt` is set, the settings tabs are disabled with the message *"Complete your assistant setup to unlock persona settings."* CTAs across the app use **Complete setup** / **Complete your assistant setup** for first run and **Re-run setup** when already complete.

### Field icons

On **About You** and **My Assistant** tabs (Create and Edit), each field label may show:

| Icon | Meaning |
| --- | --- |
| Sparkles (accent) | **Living field** — assistant may update from conversation |
| Lock (gray) | **Protected field** — assistant changes require inbox approval |

Legend text appears below the tab description on both pages.

### Tab 1 — "My Assistant" → `IDENTITY.md` + `SOUL.md`

| Field | Source | Input type |
| --- | --- | --- |
| Assistant name | `IDENTITY.md` → `name` | Text input (protected — lock icon) |
| Avatar | `persona/avatar.{ext}` | `AssistantAvatarPickerModal` → `POST/DELETE /rap/assistant/avatar` |
| Tone | `IDENTITY.md` → `tone` | Select from preset tone options (protected — lock icon) |
| Catchphrase | `IDENTITY.md` → `## Catchphrase` body | Textarea (living) |
| Origin story | `IDENTITY.md` → `## Origin Story` body | Textarea (living) |
| Core truths | `SOUL.md` → `core_truths` | Textarea — prefilled from platform baseline (protected — lock icon) |
| Humor | `SOUL.md` → `humor` | Select: Low / Medium / High (living) |
| Bluntness | `SOUL.md` → `bluntness` | Select: Low / Medium / High (living) |
| Vibe | `SOUL.md` → `## Vibe` body | Textarea (living) |

Note: `SOUL.md` frontmatter includes a `tone` YAML field in the schema, but the current UI collects presentation tone on `IDENTITY.md` only.

---

### Tab 2 — "About You" → `USER.md`

| Field | Source | Input type |
| --- | --- | --- |
| Preferred name | `USER.md` → `preferred_name` | Text input (protected — lock icon) |
| Role | `USER.md` → `role` | Text input (living) |
| Legislative focus | `USER.md` → `legislative_focus` | Comma-separated text → stored as array (living) |
| Output style | `USER.md` → `output_style` | Select: Bullets / Narrative / Dense citations / Concise (living) |
| Professional context | `USER.md` → `## Professional Context` body | Textarea (living) |
| Favorites | `USER.md` → `## Favorites` body | Textarea (living) |

`_userId`, `_accountId`, `_organization` are never shown — `_` prefix fields are system-internal.

---

### Tab 3 — "Memories" → `MEMORY.md`

| Capability | Notes |
| --- | --- |
| **Maintenance** section | **Distill memory** + **Review and learn** — distill session logs; scan recent activity for Assistant Settings suggestions → inbox |
| View MEMORY.md | Read-only textarea — raw file content |
| Clear all memory | Confirmation required — assistant rebuilds from future sessions and distillation |
Inbox review is **not** duplicated on this tab — use the `AssistantActionBar` Inbox pill above.

Until `setupCompletedAt` is set, the settings tabs are disabled with the message *"Complete personalization to unlock assistant settings."* Personalization state and CTAs are surfaced on the **Assistant Status** card on this page — not in the user menu or action bar (see `## PA Presence → Navigation`).

---

## PA Presence — AssistantActionBar & Focus/Inbox modals

The PA is a **collaborative team member** in the UI — present from first login, whether or not the user has personalized persona files. Personalization changes *who* is speaking, not *whether* the assistant exists.

`AssistantModalsProvider` wraps dashboard routes in `App.tsx` so Focus and Inbox dialogs are available app-wide via `useAssistantModals()`.

### Design intent

- **AssistantActionBar** — presence card: avatar/name, date, legislative scope pills (`AssistantScopePills`), optional token-warning pill, nav pills (New Chat / Inbox / Manage Focus). Uses per-user `accent-*` left border (`border-l-accent-500`) on `primary-50` background.
- **AssistantModals** — two separate dialogs (**Focus**, **Inbox**), not a tabbed shell. Opening one closes the other.
- **MobileActionSheet** — every user-facing page with a mobile sheet: **panel 0** = page sidebar; **panel 1** = `AssistantActionBar` (nav pills hidden) + embedded Inbox card + embedded Focus card.
- Inbox remains an open channel — new card `type` strings without a global enum.

### Relationship to Assistant Briefs

| Surface | Role |
| --- | --- |
| Briefs page | Read surface — greeting, tracking, team briefing cards |
| AssistantActionBar | Compact presence + scope pills + Focus/Inbox openers |
| Focus / Inbox modals | Edit legislative focus + review inbox items |

### Surfaces

| Location | Component | Notes |
| --- | --- | --- |
| Briefs | `AssistantActionBar` (`default`) | Top of page; pills open modals |
| Chat (all breakpoints) | `AssistantActionBar` inline below `ChatInput` | Composer-adjacent; not duplicated in desktop sidebar |
| Chat mobile | `MobileActionSheet` panel 1 | ActionBar + embedded Inbox + Focus |
| Bills, Library, Statutes, Policy Profiles, etc. | Same mobile sheet pattern | Nav header = current section; swipe to Assistant |
| Assistant Edit | `AssistantActionBar` + **Assistant Status** | Setup CTAs on status card only |

### AssistantActionBar layout

**Row 1:** `AssistantAvatar` or sparkles + display name · today's date

**Row 2 — scope pills (`AssistantScopePills`):**

| Pill | Display | Action |
| --- | --- | --- |
| State | **Florida (FL)** (read-only label) | Opens Focus dialog |
| Session | Working bill session year | Opens Focus dialog |
| Chat / Bill / Statute | Accent `LinkPill`s when pins set (`AssistantFocusScopePills`) | Navigate to target or clear pin |

Optional **Usage** warn pill when token allotment is exhausted or low.

**Row 3 — nav pills** (hidden when `showNavPills={false}` on mobile sheet panel 1):

| Pill | Action |
| --- | --- |
| New Chat | Clears session + focus (chat page) or navigates to `/dashboard/chat` |
| Inbox | Opens Inbox dialog; `subTopic` shows pending count when > 0 |
| Manage Focus | Opens Focus dialog |

**Personalization CTAs** — only on **Assistant Status** on Assistant Edit, not on the action bar.

### Desktop vs mobile

| | Desktop / Briefs / Edit | Mobile sheet (panel 1) |
| --- | --- | --- |
| Focus / Inbox | Separate portaled dialogs via `useAssistantModals()` | Embedded `AssistantFocusPanel` + `AssistantInboxPanel` cards under action bar |
| Nav pills | Shown on action bar | Hidden (`showNavPills={false}`) — Inbox/Focus are always visible as cards |
| New Chat | Header pill on action bar | Same (when nav pills shown) or via page sidebar on chat |
| Sheet header | N/A | Panel 0: `{nav icon} {Bills\|Chat\|…}` · **Assistant** → ; Panel 1: **Sparkles + Assistant** |

### Implementation map

| Component | Path | Role |
| --- | --- | --- |
| `AssistantModalsProvider` | `App.tsx` | Global dialog host |
| `AssistantModals` / `useAssistantModals()` | `components/assistant/AssistantModals.tsx` | Focus + Inbox dialog state |
| `AssistantActionBar` | `components/assistant/AssistantActionBar.tsx` | PA presence shell |
| `AssistantScopePills` | `components/assistant/AssistantScopePills.tsx` | State/Session + focus scope pills on action bar |
| `AssistantFocusScopePills` | `components/assistant/AssistantScopePills.tsx` | Chat/Bill/Statute accent pills — shared by action bar and focus panel |
| `AssistantFocusPanel` | `components/assistant/AssistantFocusPanel.tsx` | Platform, session, year, pins |
| `AssistantInboxPanel` | `components/assistant/AssistantInboxPanel.tsx` | Inbox list + resolve actions |
| `AssistantInboxProposalCard` | `components/assistant/AssistantInboxProposalCard.tsx` | Persona-update accept/reject card |
| `MobileActionSheet` | `components/layout/MobileActionSheet.tsx` | Dual panel; `getMobileNavContext()` headers |
| `assistantFocusStore` | `stores/session/assistantFocusStore.ts` | Bill/statute pins for next message |
| Web utils | `apps/web/src/utils/assistant/` | `focus`, `inbox`, `persona`, `setupDraft` |

---

## Legislative focus (UI + request)

Legislative focus is split intentionally: **global defaults** (persist, follow the user everywhere) vs **conversation pins** (what this chat thread is about right now).

### Store split

```
┌─────────────────────────────────────────────────────────────────┐
│  GLOBAL DEFAULTS (localStorage, user-scoped, cross-tab)         │
│                                                                 │
│  workingSessionStore.currentSession     →  "2026"               │
│  workingStatuteStore.currentYear        →  "2025" (FL statutes) │
│                                                                 │
│  Edited in: Assistant Focus tab, Bills/Statutes filters, etc.   │
│  Sent on every chat as: workingSession, defaultStatuteYear      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  CONVERSATION PINS (in-memory, assistantFocusStore)             │
│                                                                 │
│  billKey    →  e.g. "fl/2026/218"  (0 or 1 today; API arrays)   │
│  statuteKey →  e.g. "fl/2025/752.011"                           │
│                                                                 │
│  Set from: Bill/Statute detail nav, chat response keys, restore   │
│  Shown in: AssistantActionBar scope pills, Focus panel rows        │
│  Sent as: billKeys[], statuteKeys[] on POST /assistant/chat       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  PLATFORM (not a store today)                                   │
│  platformState / state  →  hardcoded "fl" in rap-service ALS     │
│  Focus tab shows "Florida (FL)" read-only                       │
└─────────────────────────────────────────────────────────────────┘
```

| Store / field | Persistence | Scope | Purpose |
| --- | --- | --- | --- |
| `workingSessionStore` | `localStorage` per user | App-wide | Which FL **bill session** bills search and INTERPRET use for ambiguous bill numbers |
| `workingStatuteStore` | `localStorage` per user | App-wide | Which **statute book year** default statute lookups use |
| `assistantFocusStore` | None (session tab memory) | UI + next chat send | Optional **bill** and **statute section** pinned for the active conversation |
| `ChatHistory.lastBillKeys` / `lastStatuteKeys` | Server (conversation record) | Per thread | On page load, first pin restored into `assistantFocusStore` |

**Not the same as `assistantWorkspaceStore`** — that holds PA manifest, inbox counts, persona summary, and sessionStorage-backed workspace sync. Focus stores do not live in `agent-workspace.json`.

### Chat request payload (web → rap-service)

From `chat/index.tsx` on each send:

```ts
{
  billKeys:    contextBillKey    ? [contextBillKey]    : undefined,
  statuteKeys: contextStatuteKey ? [contextStatuteKey] : undefined,
  workingSession:     currentSession,      // workingSessionStore
  defaultStatuteYear: defaultStatuteYear,  // workingStatuteStore
}
```

INTERPRET injects these into `formatActiveContext()` (`PromptTransformers`). INTERPRET may return resolved `billKeys` / `statuteKeys`; chat page updates pins and persists keys on the turn record.

### UI surfaces

| Surface | Session / year | Bill / statute pins |
| --- | --- | --- |
| **AssistantFocusPanel** | Dropdowns | `AssistantFocusScopePills` per row or "None" |
| **AssistantActionBar** | State + Session pills (open Focus dialog) | Accent scope pills when pins set |
| **Chat page** | Implicit via stores on send | Scope pills on inline action bar below composer |

Policy profiles in Focus are **deferred** (future A2).

---

## Turn eval logs (`assistant.txt`)

After each turn, `AssistantOrchestrator.writeTurnLogs()` writes one eval-oriented log beside the conversation (worker log is separate). Used for baseline vs personalized comparisons and scope debugging.

**Path:** `chat-history/{chatHistoryId}/{traceId}__assistant.txt`

**Sections (in order):**

| Section | Content |
| --- | --- |
| `timestamp` | ISO time |
| `EVAL SUMMARY` | traceId, mode, skill, setupComplete, legislative scope (platform, session, year, bill/statute keys), tokens, duration, align delta flag |
| `PERSONA LOADED` | Per-file status (identity, soul, user, memory, session notes) |
| `INTERPRET` | Captured prompt + structured result |
| `ALIGN` / `RESPOND` / `DIRECT` | Mode-specific prompt + output (work gets ALIGN + worker raw vs aligned) |
| `recentChatHistory` | Truncated turn snippets |
| `allotment` | Allotment flags and active guide ids |

Sections truncate at ~65k chars. `platformState` is seeded as `fl` in ALS at turn start.

---


### Inbox — assistant records

Inbox records are **cards** in `AssistantInboxPanel`. `AssistantActionBar` shows pending count on the Inbox pill; clicking opens the Inbox dialog (desktop/Briefs/Edit) or the embedded Inbox card on mobile sheet panel 1.

**Storage:** `persona/inbox/{type}/` — type is the folder slug (e.g. `persona-updates`). Filename carries record identity + lifecycle only:

```
persona/inbox/persona-updates/{dt}__{fileName}__{field}__new__.json
→ on resolve →
persona/inbox/persona-updates/{dt}__{fileName}__{field}__done__.json
```

**JSON envelope** (`AssistantInboxRecord` in `storage-client/types/agent-inbox.ts`):

| Field | Purpose |
| --- | --- |
| `status` | `pending` while `__new__`; outcome when `__done__` |
| `createdAt` / `resolvedAt` | Timestamps |
| `trigger` | align, respond, dreaming, … |
| `payload` | Type-specific body — for `persona-updates`, `PersonaUpdatePayload` |

**API:** `GET /rap/assistant/inbox`, `POST /rap/assistant/inbox/resolve` `{ inboxKey, action: accept \| reject }`

**First type:** `persona-updates` — protected persona field changes. Future types: `memory-review`, `brief-ready`, … — counts and cards use the API `type` string directly.

**Modal design (shipped vs planned):**

| Element | Status |
| --- | --- |
| Proposal card with field path, current → proposed diff, reason | Shipped (`AssistantInboxProposalCard`) |
| Accept / Reject per card | Shipped |
| Trigger label | Shipped (`inboxTriggerLabel`) |
| Scrollable list in dialog | Shipped |
| Edit before accepting | Planned |
| Batch accept/reject | Planned |

**Proposal card example:**

```
┌─────────────────────────────────────────────────────────────┐
│  Suggested from your conversation                           │
│                                                             │
│  Your assistant noticed you prefer bullet summaries over    │
│  narrative prose when reviewing bill analyses.              │
│                                                             │
│  output_style:  ""  →  "bullet summaries, concise"          │
│                                                             │
│  [Accept]   [Edit & Accept]   [Reject]                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Notes

Engineering decisions and cross-references to related packages. These are facts about the current implementation — not design goals.

**Context window management** — budget slicing for history and session memory is implemented in `AssistantOrchestrator`. The rationale for embedding history in the system prompt rather than as a messages array (higher attention weight on Claude, simpler budgeting, format control) is documented in `packages/shared/ai-client/README.md → Architecture Design`.

**Chat message format** — `ChatMessage.role` follows the OpenAI/Anthropic standard. All provider-specific translation (Bedrock Converse API separates system messages, uses typed content blocks) is handled in `BedrockClient.toBedrockMessages()` — the rest of the codebase is provider-agnostic.

---

## Open Questions

Items are either **RESOLVED** (answer agreed) or **OPEN** (needs design decision).
---

### RESOLVED

**Assistant inbox storage**
Records live under `persona/inbox/{type}/`. Lifecycle in filename: `__new__.json` → `__done__.json`. Outcome (`accepted` / `rejected`) in JSON body. Type is the folder, not the filename.

**Rejected inbox items retained for audit**
Yes — `__done__.json` files persist under `persona/inbox/{type}/`. Rejected records are loaded during batch review so the same field is not re-suggested.

**Agent receives summary of recent rejections**
No — rejections are **not** loaded per chat turn. `loadRecentRejections()` runs only during `MemoryReviewService` batch scan.

**Session refresh and greeting**

Session state is stored in `persona/session.json`, refreshed on login via `POST /rap/assistant/session/refresh` (`SetupService.refreshSession()`). A new `sessionId` resets `SESSIONMEMORY.md` when frontmatter mismatches. **GreetingBriefingService** (dashboard greeting card) and INTERPRET `greeting` mode handle session open — there is no separate `SESSION.md` checklist file.

**`preferred_name` seeded from account at provisioning**
Yes — default from account display name in the AssistantCreate About You step. User can change before finalize and anytime on Assistant Edit.

**Unfinished inbox items — browser close, logout**
No separate staging needed. Inbox records persist as `__new__.json` under `persona/inbox/{type}/`. On login, `syncPendingInbox()` refreshes counts; **Inbox** pill on `AssistantActionBar` opens the Inbox dialog.

**Inbox card component — placement**
Inbox cards in `AssistantInboxPanel` (`components/assistant/`). `AssistantActionBar` on Briefs, Chat, and Assistant Edit is the sole inbox entry point. Records in `persona/inbox/{type}/`.

**Pass legislative session state into active legislative context**
`state` added to the active legislative context block in both the INTERPRET and RESPOND system prompt tables. Currently hardcoded to `FL` in the service. Multi-state and national support is a future engineering task — the field is in place.

**Management screen = `AssistantEdit.tsx`**
Captured in the `## Assistant Management Screen` section intro. `AssistantEdit.tsx` is post-setup management; `AssistantCreate.tsx` is first-run setup only.

**Setup as a user-initiated entry point**
`setup` is not an INTERPRET mode. Personalization starts from the **Assistant Status** card on **Assistant Settings** (`/dashboard/profile/assistant/edit`) → wizard at `/dashboard/profile/assistant/create` → `POST /rap/assistant/setup/finalize` → `SetupService.finalizeSetup()`. User menu is fixed nav to Assistant Settings only. Chat setup turns and `setup-guide.md` removed. Normal chat pipeline only runs when `setupComplete = true`.

**PA presence — user menu vs action bar**
User menu (`MenuBar`): fixed `SparklesIcon` + **Assistant Settings** → `/dashboard/profile/assistant/edit`. No setup-state branching. Personalization CTAs and **Assistant Status** detail live on `AssistantEdit` only. See `## PA Presence`.

**Chat history — architecture (May 2026)**
**20%** context window budget — load as many turns as fit, most recent first, oldest dropped. **No turn-count cap.** Turn JSON includes full Q/A and concatenated `reasoning`. Worker agents receive **no** chat history or memory files — INTERPRET must rewrite questions self-contained.

**Sessions that are never explicitly logged out**
`session.json` stores `lastMemoryMaintenance` (date of last successful distill run). `MemoryMaintenanceService` scans turn JSON since that timestamp — exits cleanly with no work if nothing new to distill.

**Inbox persists and surfaces on AssistantActionBar**
Inbox records written to `persona/inbox/{type}/` immediately. `AssistantActionBar` Inbox pill shows pending count and opens the Inbox dialog. See `## PA Presence`.

**Batch learning — no per-turn proposals**
ALIGN and RESPOND answer only. Persona adaptation runs via `MemoryReviewService` (user-triggered scan or dreaming). Rejections loaded during batch scan only, not per chat turn.

**Dynamic field catalog via `frontmatterToJsonSchema()`**
`frontmatterToJsonSchema()` reads loaded Tier 2 files for batch review LLM schema. Not used on chat turns.

**Persist session memory and display on Briefs dashboard**
The Briefs dashboard read path for memory files (`MEMORY.md`, topic notes) is still open — see `OPEN — Worker Skills & Artifacts`.

**Session memory write — location in code**
Hook is in `rap-service/src/services/workers/WorkerAgent.ts` at `ChatTurn` creation. Read-modify-write: read existing file, append new timestamped line, re-summarize full body to update `summary` YAML field, write back. Frontmatter `summary` is always current; full body required for distillation and recall.

**Session startup/closeout and dreaming**
`memory-maintenance` skill runs on both startup and explicit closeout. Uses `lastMemoryClean` in `session.json` to filter for new files only — exits immediately if nothing to process. Dreaming (background consolidation) is planned; references throughout the doc now note it as such.

**PA learning system — broader design**
Dedicated `## Agent Learning System` section. Three loops: per-turn logging (no LLM), batch consolidate + scan, and dreaming (planned). Response ratings are a planned fourth input.

**Worker skill file artifacts** *(deferred)*
Out of scope until file creation and the `__artifact__` pattern are implemented — users can't upload files and the PA doesn't create files yet. `list_artifacts` and `get_artifact` candidate workspace operations are deferred for the same reason. See global `TODO.md` for artifact pattern spec.

**Write gate error handling**
`### Write error handling` subsection added after the write enforcement decision tree. Five failure modes by severity (S3 write, parse error, schema validation, protected field attempt), turn continuity principle (writes never block a response), degraded state handling for missing files on startup.

---



