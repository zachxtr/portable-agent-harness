# Policy Command Coding Principles

A living reference of agreed architectural and coding conventions. Updated as patterns are established during development. Each entry records the rule, the rationale, and a concrete example so a new dev (or Joshua) can apply it consistently.

---

## Type Placement — Where Do Interfaces and Types Live?

**Rule:** Types belong in `types/<domain>.ts` if they cross a service boundary. Types stay in their service file if they are internal implementation details.

**Decision criteria:**

| Condition | Where |
| --- | --- |
| Returned by an API endpoint | `types/<domain>.ts` |
| Consumed by a controller | `types/<domain>.ts` |
| Imported by more than one service | `types/<domain>.ts` |
| Frontend will ever see this shape | `types/<domain>.ts` |
| Only used within a single service or as a call param | Inside the service file |

**In `rap-service`:**
- `types/assistant.ts` is the single source of truth for all PA layer API contracts. If the controller or the frontend SDK will consume it, it lives here.
- `types/` has a barrel `index.ts` — all files re-export from there, so the whole package's public types are importable from a single entry point.

**Examples:**
- `PersonaProfile`, `PersonaProfileFile` — returned by `GET /rap/assistant/profile` → `types/assistant.ts`
- `PendingProposalRecord`, `ProposalActionResult` — returned by `/rap/assistant/proposals` endpoints → `types/assistant.ts`
- `ProposalCandidate`, `RejectedProposalHint`, `AssistantRequest`, `AssistantResponse` → `types/assistant.ts`
- `AssistantContext` — internal turn pipeline state, never serialized to JSON → stays in `AgentWorkspaceService.ts`

**Anti-pattern to avoid:** Defining an interface in a service file because it's "close to the implementation" when that type is also returned from a controller route or consumed by another service. Types that escape a file belong in `types/`.

---

## TypeScript Strictness — Don't Over-Type Internal Handoffs

**Rule:** Avoid duplicating backend JSON shapes as strict frontend interfaces (or vice versa) when the same team owns both sides and the data is passthrough display/state — not a stable public API contract.

**When strict typing earns its keep:**
- Values that must be exact to avoid bugs (route segments, enums sent in URLs, discriminated unions that drive control flow)
- Types in `types/<domain>.ts` that define a real service boundary consumed by multiple packages or external clients
- Public SDK / OpenAPI contracts where drift breaks consumers you don't control

**When loose typing is fine:**
- UI reads JSON from your own backend and renders it (inventory blobs, manifest viewers, audit logs)
- `axios` response → React state → modal with `Record<string, unknown>` and `String()` at render time
- Request/response wrapper interfaces that mirror every backend field — especially optional metadata that changes as ops features evolve

**Examples applied:**
- `BackupPhaseName` / `RestorePhaseName` — kept as small unions (typo in URL path is costly)
- `BackupInventory` — one loose interface; phase details as `Record<string, unknown>`, not a field-by-field copy of `BackupInventoryService`
- Manifest GET endpoints — `name: string`, return `response.data` untyped; backend whitelist validates the name
- Restore failure rows — `Record<string, unknown>[]` in the table viewer, not a shared `RestoreFailureRecord` DTO synced across repo

**Anti-pattern to avoid:** Maintaining parallel TypeScript interfaces on frontend and backend for the same JSON payload "for completeness." When the backend adds a field, two files must change; when someone forgets, TS gives false confidence while runtime still works. Prefer one source of truth (backend `types/` or the actual JSON) and loose consumption on the display side.

**Rationale:** Strict typing is overhead where context is already shared ("left hand to right hand"). Use TS where it prevents real mistakes — not as documentation that duplicates known shapes.

---

## Comments — Current Purpose Only, No Historical Context

**Rule:** Comments describe what the code does and why, from the perspective of a new developer seeing it for the first time today. Never document what the code used to do, what was removed, or why something changed.

**Examples of what to avoid:**
```typescript
// Previously this handled X, but we moved that to Y
// Removed: legacy migration path (no production data)
// Note: this was refactored from AgentWorkspaceProvisionService
```

**What good comments look like:**
- File-level JSDoc explains the file's current purpose and architecture role
- Method comments explain non-obvious intent, trade-offs, or constraints
- Inline comments only where the code itself cannot convey the reasoning

**Rationale:** Legacy comments create noise that misleads new devs into thinking removed functionality still matters. If a decision needs context, capture it in an ADR or the architectural design doc — not in a code comment.

---

## Naming — Call Things What They Are

**Rule:** Names should reflect current purpose and scope, not historical origin or where something used to live.

**Examples applied:**
- `AgentWorkspaceProvisionService` → `WorkspaceProvisionService` (moved out of `assistant/`; it's infrastructure-level provisioning, not PA-specific setup)
- `SetupService` (inside `assistant/`) — owns PA persona provisioning (finalize + session refresh)
- `SESSIONNOTES.md` → `SESSIONMEMORY.md` — renamed to reflect what it actually is (mid-term memory, not notes)
- `AssistantIntentBuilder` → `WorkerIntentBuilder` — renamed when the intent became clear it builds worker dispatch intents, not general assistant intents

**Anti-pattern:** Keeping a misleading name because renaming is inconvenient. Misleading names are a permanent tax on every dev who reads the code.

---

## HTTP JSON — camelCase at Service Boundaries

**Rule:** All HTTP request and response JSON uses camelCase field names across Policy Command.

| Layer | Convention |
| --- | --- |
| `core-service`, `rap-service` HTTP responses | camelCase |
| `storage-client` persisted records (`ChatTurnRecord`, etc.) | camelCase |
| `apps/web` types | camelCase |
| Internal LLM pipeline artifacts (`WorkerResponse`, `ValidateResult`) | snake_case OK — never sent to clients |

**Rationale:** One shape from backend to browser. No per-client normalizers. Internal pipeline types can keep snake_case where they never cross the wire.

**Example:** `AssistantResponse` uses `confidenceScore`, `totalTime`, `tokensUsed.total` — not `confidence_score`, `total_time`, `tokens_used.total_tokens`.

---

## Legacy Support — Ask Before Adding

**Rule:** Do not add backward-compatibility shims, alias maps, migration fallbacks, or "until X is done" legacy paths in application code unless the user explicitly approves that approach.

**Examples of what requires approval first:**
- Mapping retired enum values to new ones (e.g. `user-basic` → `user`)
- Dual-read or dual-write during a data migration
- Feature flags or branches that preserve old behavior "just in case"
- Comments or constants framed as temporary legacy support

**What to do instead:**
- Make the breaking change aligned with current architecture (Keycloak, storage keys, API contracts)
- Call out migration work that must happen outside the codebase (Keycloak admin, one-time scripts, deploy ordering)
- If legacy support is genuinely needed, present the tradeoff and wait for approval before coding it

**Rationale:** Unapproved legacy paths hide incomplete migrations, accumulate permanent complexity, and contradict the "current purpose only" comment standard. Data and identity migrations belong in ops/admin steps — not silent UI fallbacks.

---
