# Assistant streaming — plan for approval

**Status:** Approved — implemented

---

## Summary

We already stream worker answers (muted italic in the pending bubble). Gaps are quiet phases (INTERPRET, ALIGN) and discover leaking JSON. This plan adds **`progress` status lines** on the same pipe, routes all output through **`TurnStream`** in the orchestrator, and keeps the UI users already like (**Thinking…** button, muted pre-final stream).

---

## Problem (today)

| Issue | Cause |
|-------|--------|
| Dead air before worker tokens | No wire events during INTERPRET |
| Dead air after worker tokens | No wire events during ALIGN |
| Raw JSON in chat (discover) | Summarizer LLM streamed directly to client |
| `preview_start` / `isPreviewMode` | Work-only special case; same UX achievable with `progress` + `token` |
| Worker → client passthrough | Controller forwards worker `onToken` with no orchestrator gate |

**What already works:** Work-mode GENERATE streaming (agentic/direct), NDJSON + flush, pending bubble UX.

---

## The pipe

**One HTTP response.** One JSON object per line. Orchestrator decides content; controller writes and flushes.

| `type` | Payload | When | UI |
|--------|---------|------|-----|
| `start` | `traceId` | Request accepted | — |
| `progress` | `step`, `label` | Orchestrator enters a phase (see below) | Wire-first; bubble stays dots until `token` |
| `token` | `delta` | User-facing answer text | Muted gray italic in pending bubble |
| `clear` | — | Reset answer buffer (if we replace streamed draft) | Clear pending text; **not needed in v1** if `final` alone replaces |
| `final` | full `AssistantResponse` | Turn complete | Normal markdown turn + sources |
| `error` | message | Failure | Toast + clear pending |

**Two mid-turn payloads:** `progress` = status bar; `token` = answer typing. Same pipe, different `type`.

### Progress steps (orchestrator only — not worker PREPARE/ASSEMBLE)

| `step` | Label | When |
|--------|-------|------|
| `review` | Reviewing request… | INTERPRET |
| `work` | Working… or `Dispatching worker: {SkillRegistry display name}…` | Recall lookup; entire `workerAgent.run()` |
| `finalize` | Reviewing response… | ALIGN, RESPOND, clarify, direct wrap |

Worker internal phases (PREPARE, ASSEMBLE, VALIDATE) stay in logs — no separate wire lines.

**Tone:** Factual system status. Skill names OK. No “your …” personalization.

### Example — work / review turn

```
User clicks Send
│
├─ start
├─ progress  "Reviewing request…"
├─ progress  "Dispatching worker: Legislative Review…"
├─ token     "**Summary of Florida…"     ← GENERATE (muted italic)
├─ token     …
├─ progress  "Reviewing response…"     ← ALIGN (muted text stays on screen)
└─ final     { answer, sources, … }
```

**Discover:** Same `progress` lines; `token` only **after** formatted bill list (not summarizer JSON).  
**Conversation:** `review` → `finalize` → `token` → `final` (no `work` unless recall).

---

## Design

### TurnStream (orchestrator gate)

```ts
export type ProgressStep = 'review' | 'work' | 'finalize';

export interface TurnStream {
  progress(step: ProgressStep, label: string): void;
  token(delta: string): void;
  clear(): void;
}

export const LABELS = {
  review:   'Reviewing request…',
  work:     'Working…',
  finalize: 'Reviewing response…',
} as const;

export function workLabelForSkill(skillSlug: string): string {
  return `Dispatching worker: ${SkillRegistry.toDisplayName(skillSlug)}…`;
}
```

Controller maps `TurnStream` → NDJSON. Orchestrator is the **only** emitter of `progress` and `token`.

### When to emit `token`

| Source | Emit? | How |
|--------|-------|-----|
| Worker agentic/direct GENERATE | Yes | Orchestrator relay into worker GENERATE (not direct controller passthrough) |
| Worker discover | After compose | Orchestrator chunks `DiscoveryFormatter` output; **no** relay to `DiscoverySummarizer` |
| ALIGN / RESPOND | v1: optional chunk after parse | LLM returns JSON — do not stream raw; **v1: rely on worker stream + `final`** for work mode |
| Recall / clarify / direct | Yes | Chunk final answer text |

**Work mode (approved UX):** Stream during worker GENERATE (keep bill-summary behavior). Emit `progress/finalize` during ALIGN. **`final` is authoritative** — replaces pending with aligned answer + sources. No `clear` + re-stream in v1 unless preview ≠ final becomes a visible problem.

### UI — pending bubble

- **Send button:** **Thinking…** (static)
- **Pending bubble:** one **muted italic** preview line — progress labels until first `token`, then answer stream in the same slot; frozen through ALIGN (no swapping back to progress once tokens land)
- **`final`:** authoritative markdown turn + sources
- **Remove:** `preview_start`, `isPreviewMode` (same look via pending + tokens)
- **`onProgress`:** updates `pendingAssistantProgress` → `streamProgressLabel` on pending `ChatMessage`

---

## What we ARE doing

1. Add `TurnStream` + shared `AssistantStreamEvent` types
2. Emit `progress` at orchestrator phase boundaries (all modes)
3. Include skill display name in `work` label when dispatching worker
4. Route worker answer bytes through orchestrator relay (not controller passthrough)
5. Fix discover: no summarizer JSON on the wire
6. Remove `preview_start` / fake end-of-turn token bursts where `final` suffices
7. Keep muted streaming + Thinking… button
8. Remove stale Phase 6 stub comments

---

## What we are NOT doing

- Second HTTP connection or WebSocket
- Worker PREPARE / ASSEMBLE / GENERATE as separate `progress` lines
- Streaming INTERPRET, summarizer, or ALIGN/RESPOND LLM raw output
- “Your …” personalized status copy
- Progress labels on the Send button
- Rewriting ALIGN/RESPOND prompts for live token stream (later if needed)
- Changing worker pipeline architecture

---

## Implementation (~8 files)

| # | Task | Files |
|---|------|--------|
| 1 | `TurnStream` + event types | `TurnStream.ts`, `types/assistant.ts`, web `rapApi.ts` / `chat.ts` |
| 2 | Controller wires `TurnStream` | `AssistantController.ts` |
| 3 | Orchestrator `progress()` + relay | `AssistantOrchestrator.ts` |
| 4 | Discover: drop summarizer `onToken` | `DiscoverySummarizer.ts`, `GenerateService.ts` |
| 5 | Web: `onProgress`, drop preview mode | `chat/index.tsx`, `ChatMessage.tsx`, `rapApi.ts` |
| 6 | Cleanup | Remove `StreamCallbacks` / `preview_start` / unused `onClear` if unused |

---

## Approval checklist

- [x] **One pipe** — `progress` + `token` + `final`; no second stream
- [x] **Three progress steps** — review / work / finalize; skill name on dispatch
- [x] **Keep worker GENERATE streaming** — muted italic in bubble (review turn UX)
- [x] **Keep Thinking…** — progress on wire only for v1 UI
- [x] **`final` authoritative** — aligned answer + sources; no v1 clear/re-stream
- [x] **Discover fix** — formatted list only, never summarizer JSON
- [x] Approved — implemented

---

## Reference

| Concern | Path |
|---------|------|
| NDJSON endpoint | `controllers/AssistantController.ts` |
| Emit points | `services/assistant/AssistantOrchestrator.ts` |
| Worker / GENERATE | `services/workers/WorkerAgent.ts`, `services/generate/` |
| Discover bug | `services/generate/DiscoverySummarizer.ts` |
| Skill display names | `services/SkillRegistry.ts` |
| Briefing (good pattern) | `services/briefing/GreetingBriefingService.ts` |
| Web | `apps/web/src/services/rapApi.ts`, `pages/dashboard/chat/` |
