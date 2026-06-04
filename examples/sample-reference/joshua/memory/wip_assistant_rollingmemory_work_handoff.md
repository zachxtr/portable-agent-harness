# WIP — ROLLINGMEMORY.md (SESSIONMEMORY → rolling activity index)

**Renamed (2026-06-03):** `wip_assistant_work_handoff.md` → **`wip_assistant_rollingmemory_work_handoff.md`** — same INTERPRET/handoff section kept below for one doc; product rename target is **`SESSIONMEMORY.md` → `ROLLINGMEMORY.md`** in persona (not implemented yet).

**Status:** Design for review — no code until approved.

---

## Problem (today’s `SESSIONMEMORY.md`)

| Today | Gap |
|--------|-----|
| One `## {chatHistoryId}` block per thread; post-turn deterministic upsert | Only **chats** — not policy profiles, bills, statutes, documents |
| Body wipes when `sessionId` frontmatter ≠ `session.json` | **Login-session-bound** — prior days lost unless distilled to `MEMORY.md` |
| ~8k char trim (oldest turn lines, then blocks) | Size roll exists; not a **multi-entity** activity map |
| Loaded whole into PA prompt when non-empty | Good for routing; weak for “what did I do in the product?” |

v3 is a **cross-thread routing index for one web session**, not **rolling assistant activity** keyed for retrieval and handoff.

---

## INTERPRET context inventory (today)

Ground truth: `InterpretService.ts`, `AgentWorkspaceService.ts`, `AssistantOrchestrator.ts` (loads workspace + recent turns before INTERPRET).

### 1) Datasets in the INTERPRET system prompt

| Prompt section | Source | Included when | Budget / notes |
|----------------|--------|---------------|----------------|
| **User message** | `AssistantRequest.question` | Every turn | Separate `user` message (not in system prompt) |
| **Your identity** | S3 `persona/IDENTITY.md` | `setupComplete` + non-empty | YAML frontmatter → bullet fields + markdown body (`formatAgentFileForPrompt`; `_` keys stripped) |
| **Your purpose** | S3 `persona/SOUL.md` | same | same |
| **Your operating rules** | S3 `persona/WORKSPACE.md` | same | same |
| **About your user** | S3 `persona/USER.md` | same | same |
| **Your long-term memory** | S3 `persona/MEMORY.md` | same | Write cap 8k chars; **full file loaded** at read (no read trim) |
| **Recent conversation history** | Turn JSON for **current** `chatHistoryId` (`loadRecentChatHistory`) | When thread has prior turns | **~20% of `BEDROCK_CONTEXT_WINDOW`** in chars (default window 32,768 → ~26k chars); newest turns first; **no turn-count cap** |
| **This PA session** | S3 `persona/SESSIONMEMORY.md` | `setupComplete` + non-empty body | Full file in prompt; body write cap ~8k; **body wipes on new web `sessionId`** (today) |
| **Active legislative context** | Request: `billKeys`, `statuteKeys`, `workingSession`, `defaultStatuteYear` | When any scope field present | From Focus / client; `formatActiveContext()` |
| **Available skills** | `SkillRegistry.catalogForPrompt()` | Always | XML catalog — base skills: `policy-command-legislative-search`, `policy-command-legislative-review`, `policy-command-legislative-analysis` (names + descriptions; **not callable as tools**) |
| **Conversation title hint** | Synthetic | First turn only (no recent history block) | Asks model to set `conversationTitle` in JSON |
| **INTERPRET instructions** | Static in `InterpretService` | Always | Mode guide, tool docs (if personalized), JSON output schema |

**Not in INTERPRET prompt today (but related):**

| Data | Where it lives | Notes |
|------|----------------|-------|
| `persona/session.json` | Loaded into `AssistantContext.sessionState` | Used for session refresh / SESSIONMEMORY reset — **not injected into INTERPRET text** |
| `legislativeSearchLimit` | `AssistantRequest` | Passed to **worker** discover path after INTERPRET; not in INTERPRET system prompt |
| Turn JSON for **other** threads | S3 `chat-history/` via tool | `get_chat_history(chatHistoryId)` — not preloaded |
| Navigation history | S3 `navigation-history/` via tool | `get_user_activity` — **stub returns empty until S3 wiring complete** (`UserActivityService` Phase 2 TODO) |
| Saved library | S3 `library/saved-*` via tool | `get_user_library` — reads agent-workspace (`getSavedBills`, `getSavedStatutes`, `getSavedChats`, `getSavedSearches`) |
| Policy profile focus / Platform Guide | — | **Not loaded** in INTERPRET today |

**`setupComplete` gate:** `persona/setup/config.json` has `setupCompletedAt`. Setup wizard is **UI-only** — not an agent operating mode. When false, persona strings are empty and PA tools are not registered; INTERPRET still runs with skill catalog + recent history. *(Code still lists `"setup"` in the JSON schema — legacy; treat as conversation/direct, not a harness mode.)*

### 2) Added when the assistant is personalized (`setupComplete`)

| Capability | Before setup | After setup (personalized) |
|------------|--------------|----------------------------|
| Persona files in prompt | None (empty strings) | `IDENTITY.md`, `SOUL.md`, `USER.md`, `MEMORY.md`, `WORKSPACE.md`, `SESSIONMEMORY.md` |
| **Recent conversation history** | Yes (if thread has turns) | Yes — unchanged |
| **Active legislative context** | Yes (from request) | Yes — unchanged |
| **Skill catalog** | Yes | Yes — unchanged |
| PA retrieval tools | **Not registered** — `tools: []` | Three tools registered (see below) |
| Tool documentation in prompt | Omitted | `get_chat_history`, `get_user_activity`, `get_user_library` descriptions + “do NOT call on every turn” |
| **`conversation` mode** | “Respond conversationally from available context” | Full guidance: memory, session memory, recent history, tools when materially relevant |

Personalization = setup wizard finished (`setupCompletedAt`) — unlocks persona files + PA tools. Not an agent “mode”; users complete setup in the UI before chat gets full context.

### 3) INTERPRET tools and call behavior

**Registry:** Separate PA `ToolRegistry` in `AssistantOrchestrator` (not the worker tool registry).

| Tool | Purpose | Key parameters | Response limits (executor) |
|------|---------|----------------|------------------------------|
| `get_chat_history` | Turn JSON + summary for **another** conversation thread | `chatHistoryId` (required) | Full thread content from S3; error if not found |
| `get_user_activity` | User navigation history (bills, statutes, searches, chats visited) | `mode`: `sessions` (default) \| `entries`; optional `sessionId`, `daysBack`, `limit`, `section` | **S3** `navigation-history/` — **stub empty today**; executor limits: sessions default 20 max 50 · entries default 50 max 100 |
| `get_user_library` | Saved library (bills, statutes, chats, searches, annotations) | optional `type`, `daysBack`, `limit` | **S3** `library/saved-*` · Typed: default 25, max 100 · All types: default 10 per type, max 25 per type |

**When tools are available:** only when `setupComplete === true`.

**Calls per INTERPRET turn:**

| Step | LLM calls | Tool executions |
|------|-----------|-----------------|
| No tools chosen | **1** | 0 |
| Model returns `tool_calls` | **2** (initial + JSON after tool results) | **All** `tool_calls` in the first response, executed **sequentially** |

**Limits:**

| Limit | Value | Applies to INTERPRET? |
|-------|-------|------------------------|
| Tools offered to model | 3 (`get_chat_history`, `get_user_activity`, `get_user_library`) | Yes, when personalized |
| Hard max tool executions per turn | **None enforced** in `InterpretService` | Model may request multiple tools in one turn; all are run |
| `RAP_TOOL_MAX_CALLS` (default **3**) | Worker agentic loop (`AgenticCallExecutor`) | **No** — not wired into INTERPRET |
| `RAP_TOOL_TIMEOUT` (default 60s) | Per-tool executor timeout | Yes (via `ToolRegistry.execute`) |
| INTERPRET output tokens | **2048** max (`INTERPRET_MAX_TOKENS`) | Yes |
| Prompt latency targets (comments) | &lt;400ms no tool · &lt;800ms one tool | Aspirational, not enforced |

**Prompt rules (today):** tools for **other** `chatHistoryId`, navigation, or library — not for replaying the **current** thread (recent history block already has current thread). Rolling memory work should feed index arrays so INTERPRET/tools stop re-parsing markdown for keys.

**Log label:** successful tool use stored as `memoryToolUsed` / `memoryToolResults` on `InterpretResult` (Zach note: rename to `interpret_tools` / `pa_tools` to avoid confusion with `MEMORY.md` / `ROLLINGMEMORY.md`).

---

## Target: `ROLLINGMEMORY.md`

**What it is:** A **short-term memory index** — not a transcript, not long-term facts. Compact cards + frontmatter key arrays that **point at past work** in Policy Command (chat id, bill key, profile uuid, doc path). Turn JSON stays source of truth for verbatim Q/A; `MEMORY.md` stays durable curated facts.

**Analogy:** Navigation history for the assistant — “what you touched recently” so INTERPRET can route follow-ups (“item 6 on that list”, “the AHCA chat Tuesday”) without re-fetching everything.

| Layer | File / store | Role |
|-------|----------------|------|
| **In-thread** | Turn JSON (`chat-history/`) | Full Q/A for **current** conversation |
| **Rolling index** | `ROLLINGMEMORY.md` | Cross-time **pointers** + last-active metadata |
| **Long-term** | `MEMORY.md` + `memory/*.md` | Distilled facts that survive rolling eviction |

**Matilda alignment:** Platform Guide = *how the system works*; rolling memory = *what you did*; `MEMORY.md` = *what matters long-term*.

---

## YAML contract (size caps — not retention days)

**No `retentionDays`.** Window is bounded by **total file size** (`maxBodyChars`), not calendar expiry.

### Prune rules (decided)

1. **`maxBodyChars`** — primary cap on the whole file (body + frontmatter arrays stay in sync with cards).
2. **`minEntries: 1` per entity type** — always keep **at least one card** per type that has ever appeared (chat, policy_profile, bill, statute, document). Each type’s survivor is a **back-reference anchor** (“you did work here once”) even after heavy browsing.
3. **Eviction beyond mins** — drop the **globally oldest** card by `Last active:` across **all types**. Not per-type numeric caps (no 25 bills / 8 profiles split).
4. **`oldestEntryAt`** — ISO timestamp of the oldest card still in the file after prune (for UI / debug / “memory since …”).

```yaml
---
_schema: rolling-memory/1
_agent_edit_tier: 3
_updated: ""
_updated_by: "system"

# ── Index arrays (machine keys — tools / prompt; deduped on upsert) ──
chatHistoryIds: []
policyProfileUuids: []    # handle lives on the card body, not in frontmatter
billKeys: []
statuteKeys: []
documentKeys: []          # stable doc id or objectPath — pick one convention in impl

# ── Size budget (tunable later in Memories UI) ──
maxBodyChars: 12000
minEntries:
  chat: 1
  policy_profile: 1
  bill: 1
  statute: 1
  document: 1

# ── Window metadata ──
oldestEntryAt: ""         # ISO — Last active of oldest card still present after prune
sessionId: ""              # current web session (annotate / group; does NOT wipe body)
_required: [oldestEntryAt]
---
```

**Index array rules**

- On **upsert**: append key to the matching array if new; refresh card `Last active:` (move-to-front in body ordering optional; eviction uses timestamp not section order).
- On **prune** (over `maxBodyChars`):
  1. Build candidate set = all cards except those that are the **sole remaining card** for their type (protected by `minEntries`).
  2. Remove **globally oldest** `Last active:` from candidates; repeat until under budget.
  3. Remove evicted keys from frontmatter arrays; recompute `oldestEntryAt`.
- **Policy profiles:** frontmatter **`policyProfileUuids` only**. Card body carries `Handle:` + `Uuid:` (or handle as `###` header for readability) — one source of truth for the uuid→handle link on the card.
- Arrays = **machine index**; markdown body = human/agent-readable cards (same keys in headers).

---

## Body shape (short sections)

```markdown
## Chats

### conv-1780522163808-kv7ft2u6i
Title: AHCA bills list
Last active: 2026-06-03T14:22:00Z
Scope: fl/2026/SB560
Topics: AHCA, child welfare
Last Q: summarize item 6
Turns: 4 · Last outcome: 1 source · legislative-review

### Turns
(optional — current chatHistoryId only; trim oldest lines here first)

## Policy profiles

### {policy-profile-uuid}
Handle: healthcare-2026
Last active: …
Note: Created profile; linked HB 543

## Bills

### fl/2026/SB560
Last active: …
From: conv-… · Opened PDF

## Statutes
…

## Documents
…
```

- Harness keeps chat cards enough for INTERPRET (“6th item on that list”) — scope + last Q; full turn trace only for **active** thread optional.
- User/agent may edit card prose (tier 3).

---

## Who writes what

| Trigger | Writer | Updates |
|---------|--------|---------|
| Post-turn (today) | `SessionMemoryIndexService` → rename **`RollingMemoryIndexService`** | Chat card + `chatHistoryIds[]` |
| Bill/statute detail or PDF open | Nav hook → rolling upsert (S3 write path) | `billKeys[]` / `statuteKeys[]` |
| Policy profile create / major update | Profile API / agent-workspace write path | `policyProfileUuids[]` + profile card (handle on body) |
| Library save / annotation | Library paths under `library/saved-*` | `documentKeys[]` |
| Login / session refresh | Prune by **count/chars only**; refresh `sessionId`; **no body wipe** | Recompute `oldestEntryAt` |
| Distill / clean memory | `MemoryMaintenanceService` | Facts → `MEMORY.md` + `memory/*.md`; optional rolling trim |

---

## PA prompt + UI (later)

1. Recent turns (history budget)  
2. `ROLLINGMEMORY.md` when non-empty (cross-time activity + index arrays for tools)  
3. `get_chat_history` only for **other** `chatHistoryId` (see INTERPRET section below)

**Memories UI (TODO):** Rolling (editable) | Long-term `MEMORY.md` | deep `memory/*.md`  
**Chat panel:** rolling first; “Add to context” on a card.

---

## Migration phases (review order)

1. **Rename + dual-read** — S3 `persona/ROLLINGMEMORY.md`; read legacy `SESSIONMEMORY.md` if missing; accept `_schema: session-memory/v3` chat blocks while migrating.
2. **Frontmatter** — index arrays + `maxBodyChars` + `minEntries: 1` per type + global oldest eviction; stop session-id **body wipe**.
3. **Chat path** — port `SessionMemoryIndexService` trim/evict to update arrays + `oldestEntryAt`.
4. **Entity writers** — bill, statute, profile, document upserts.
5. **Distill + memory-index** — read rolling arrays + cards; update harness + `memory-guide.md`.
6. **UI** — Memories tab + chat drawer.

**Open for Zach (before code)**

- [ ] `maxBodyChars` default (12k OK?)  
- [ ] `### Turns` — all threads vs active thread only?  
- [ ] Hard S3 rename vs one-release dual-key  
- [ ] `documentKeys` — uuid vs `objectPath` canonical  
- [ ] Phase 1 scope: rename + arrays + no session wipe + chat-only writes?

---

## References (rolling memory)

- `packages/services/rap-service/src/services/assistant/InterpretService.ts` — INTERPRET prompt assembly + tools
- `packages/services/rap-service/src/services/assistant/AgentWorkspaceService.ts` — persona load + `setupComplete` gate
- `packages/services/rap-service/src/services/assistant/AssistantOrchestrator.ts` — recent history budget + PA tool registry
- `packages/services/rap-service/src/services/assistant/SessionMemoryIndexService.ts`
- `packages/services/rap-service/src/agent-templates/_system/agent-persona/SESSIONMEMORY.md`
- `.dev/code-agents/joshua/memory/POLICY_ASSISTANT_AGENT_HARNESS.md` — session index section
- `.dev/code-agents/joshua/memory/TODO.md` — ROLLINGMEMORY notes ~L294–304
- Nav history pattern: `packages/shared/storage-client/src/types/navigation-history.ts` — S3 `navigation-history/` layout
- Agent-workspace layout: `packages/shared/storage-client/src/UserAgentWorkspaceLayout.ts` — `library/`, `chat-history/`, `persona/`

---

# WIP — PA work handoff (INTERPRET → worker dispatch)

**Problem:** Follow-ups in the **current** chat replay prior turns via `get_chat_history` + conversation mode instead of dispatching workers. JSON parse fails when the model answers in prose after tools.

**Repro:** `conv-1780522163808-kv7ft2u6i` (AHCA search → “6th item” → “full summary” stub → only works after explicit `SB560`).

---

## What works today

| Turn | Question | Expected | Actual |
|------|----------|----------|--------|
| 1 | Topic search (AHCA) | `work` + `legislative-search` | OK — discover, sources |
| 2 | “6th item on your list” | `work` + `legislative-review` (`fl/2026/560`) | `get_chat_history` → parse fail → conversation replay |
| 3 | “full summary of the bill” | `work` + `legislative-review` | parse fail → one-line stub, no worker |
| 4 | “summarize bill SB560” | `work` + `legislative-review` | OK — explicit bill number |

Turn 1 search is fine. Breakage is **in-thread follow-ups** without a named bill.

---

## Root cause

1. **INTERPRET replay guidance** — “use `get_chat_history`” + “don’t re-dispatch for replay” steers away from workers for list picks and summaries.
2. **Prose after tools** — second INTERPRET call returns markdown (`Item 6 from that AHCA list is…`) not JSON → `conversation` fallback.
3. **Wrong tool for same thread** — `get_chat_history` on **current** `chatHistoryId` while rolling `chatHistoryTurns` already has turn 1; should use in-thread context + worker.
4. **`chat_history` sources** — cites same conv id; honest replay label but not a true “other chat.”

**Log snippet (turn 2):**

```
memory tools: ["get_chat_history"]
JSON parse failed — raw: "Item 6 from that AHCA list is: **SB 560: Child Welfare**..."
→ conversation mode (no worker)
```

---

## Fix directions (priority order)

### A — JSON contract after memory tools (primary)

- After `get_chat_history` (any PA tool), second INTERPRET call **must** return JSON only.
- On parse fail: **one retry** with strict “JSON only, no prose” reminder.
- Log full raw output in `assistant.txt` on failure (already partial in rap logs).

**Files:** `InterpretService.ts`

### B — Never `get_chat_history` for current thread

- If `chatHistoryId` arg === `request.chatHistoryId`, reject or no-op tool; use rolling history instead.
- INTERPRET prompt: `get_chat_history` only for **other** `chatHistoryId` values (`ROLLINGMEMORY` / `chatHistoryIds[]` / user-named prior thread).

**Files:** `GetChatHistoryExecutor.ts` or `InterpretService.ts`, INTERPRET system prompt

### C — Parse-fail safety net → `work`

Heuristic when JSON parse fails but intent is clear:

- “item N” / “Nth on (your) list” + recent `work` search in thread → `legislative-review` with bill key from list position N.
- “full summary” / “summarize the bill” + bill in recent turns → `legislative-review` with resolved key.
- Explicit bill number → already works; keep.

**Files:** new small `interpretParseFailRecovery.ts`, `AssistantOrchestrator` or `InterpretService`

### D — INTERPRET prompt tightening

- **Replay** = different conversation only (user asks about Tuesday’s chat, rolling index points elsewhere).
- **Depth on current thread** = always `work` (list item pick, bill summary, compare, PDF-level pull).
- Do not treat “pull item 6” as replay.

**Files:** `InterpretService.ts` (mode decision guide)

---

## Shipped (related, 2026-06-03)

- **`chat_history` sources** — conversation replay turns; `buildChatHistorySources`, injected `[CITE: n]`, Chat LinkPill.
- **Progress label cycling dots** — `ProgressStatusText` in pending bubble.
- **Download hidden until stream complete** — `ChatMessage`: `streamingDownloadRow` requires `!isStreaming`.
- **Citation scroll-back** — expand Sources + `highlightElement` on return from bill/PDF (`chatScrollRestore`, `pendingSourceScrollTarget`).

---

## Test plan (after A–D)

1. New chat: AHCA search → 10 bills.
2. “pull the 6th item” → `work` + review SB560, document sources (not conversation + `chat_history` only).
3. “full summary please” → full review answer, no stub.
4. Separate conv: “what did we discuss in [other conv id]?” → may use `get_chat_history` + `chat_history` source (other id only).

---

## References (INTERPRET)

- Bicycle replay: `conv-1780517819415-yp5fw13qw`
- AHCA handoff: `conv-1780522163808-kv7ft2u6i`
- `packages/services/rap-service/src/services/assistant/InterpretService.ts`
- `packages/services/rap-service/src/services/assistant/chatHistorySources.ts`

---

## Zach thoughts

- What are we calling **“memory tools”** in logs? PA tools are not only memory — consider renaming log label to `interpret_tools` or `pa_tools` so it’s not confused with `ROLLINGMEMORY` / `MEMORY.md`.
- Rolling index arrays should be what INTERPRET/tools use instead of re-parsing markdown for `chatHistoryId` / bill keys.

Compare what we are doing for each of the briefs and what data they get

Consider what datasets we are working with here as well as align to the tools that are avialble

Consider what work skills are needed for the assistant at this point.  

Consider what detailed memory files we will have and support and HOW we will do that...  

Should get folks useing the system first so those TODOs are more important past a clean ROLLINGMEMMORY.md file.  

Should we replace the persona/session.json be replaced with the YMAL frontmatter of the new ROLLINGMEMORY.md file?  fits... 

what should go in memory.md vs rollingmemory.md?  