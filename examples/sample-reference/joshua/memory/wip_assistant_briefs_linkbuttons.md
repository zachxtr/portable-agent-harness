# WIP — Assistant Briefs: clickable links (Team + Tracking)

> **Status:** Planning — implement later.  
> **Not ground truth for shipped code** until Phase 1 lands.  
> **Related TODO:** `memory/TODO.md` — intro bullets as hyperlink buttons; teammate activity opens avatar; accent styling.

---

## Goal

Make **Tracking Updates** and **Team Updates** briefing cards link to real platform destinations — same behavior as `TeamActivity.tsx` (navigate + `pushContext` scroll-back), not plain markdown text.

**In scope:** bill, statute, chat, search, annotated document, policy profile, teammate user header (avatar).  
**Out of scope for v1:** Greeting card links; parsing prose without a structured manifest.

---

## How hard is this?

| Approach | Difficulty | Notes |
|----------|------------|--------|
| **Structured link manifest** alongside LLM markdown (recommended) | **Medium** (~3–5 dev days for Phases 1–2 + avatar) | Keys already exist in source docs; RAP strips them today |
| **Infer keys from streamed markdown only** | **Hard / brittle** | LLM labels (“Bicycles”, “HB 993”) won’t reliably match without server refs |
| **Full structured UI (no markdown bullets)** | **Medium+** | Most reliable UX; bigger visual change |

---

## Current architecture (gap)

### Frontend

- `AssistantBriefing.tsx` — loads three cards via `streamBriefingCard` (NDJSON).
- `BriefingCard.tsx` — renders `content` as `ReactMarkdown` only; no link metadata on `final`.
- `assistantBriefingStore` — `content`, `generatedAt`, `fromCache`; no `links`.

### Backend

- `BriefingController` — streams `token` + `final` (`generatedAt`, `fromCache`).
- `TeamUpdatesBriefingService` / `TrackingUpdatesBriefingService` — collect structured rows, call LLM, cache **`briefing/{team|tracking}/{date}.md`** only.
- `CollectedActivityRow` (team) — has `type`, `userId`, `userName`, `itemLabel`, tags; **missing** `billKey`, `statuteKey`, `chatHistoryId`, `documentPath`, profile `uuid`, etc.
- LLM prompts explicitly say: **do NOT use internal bill keys** in user-visible copy (good for prose; keys must live in parallel manifest).

### Reference implementation (reuse)

`apps/web/src/pages/dashboard/TeamActivity.tsx`:

- `getActivityUrl` — bill detail, statute detail, PDF viewer, etc.
- `handleChatClick`, `handleSearchClick`, `handleActivityItemClick`
- `getActivityRowKey` — unique row id for scroll restore
- `pushContext({ url: '/dashboard/team-activity', title: 'Team Activity', scrollTarget: 'row-…' })`
- `TeamActivityUserCell` + `AccountUserAvatar` for teammate column

**Canonical types:** `apps/web/src/components/dashboard/types.ts` — `ActivityItem`, `SavedBill`, `SavedChat`, etc.

---

## Root constraint

| Layer | Today | Needed |
|-------|--------|--------|
| RAP | Markdown narrative only | **Parallel structured payload** keyed by stable `refId` |
| Cache | `.md` file per day | Co-cache **`{date}.links.json`** (or combined JSON envelope) |
| UI | String markdown | Custom link renderers **or** structured bullet rows + short copy |

Do **not** rely on regex over bold text without a manifest. Labels in markdown should match `itemLabel` strings fed to the LLM (or use `refId` contract — see Phase 2).

---

## Recommended phases

### Phase 1 — Shared navigation utilities (~0.5 day)

Extract from `TeamActivity.tsx` into e.g. `apps/web/src/utils/teamActivityNavigation.ts`:

| Export | Purpose |
|--------|---------|
| `buildActivityUrl(item, type)` | Same rules as `getActivityUrl` |
| `getActivityRowKey(activity)` | Scroll target id |
| `navigateFromBriefs(...)` | `pushContext({ url: '/dashboard/briefs', title: 'Briefs' })` then `navigate` |

Refactor `TeamActivity.tsx` to call shared helpers so Briefs and Team Activity never diverge.

**Back-nav:** Returning from bill/chat/profile should restore Briefs tab (same pattern as team-activity → detail → back).

---

### Phase 2 — Link manifest on briefing API (~1–2 days)

#### Backend: extend collected rows

**Team (`TeamUpdatesBriefingService`)** — add fields when building rows:

| Type | Navigation fields |
|------|-------------------|
| `bill` | `billKey`, `stateCode`, `session`, `billNumber` |
| `statute` | `statuteKey` |
| `chat` | `chatHistoryId`, `recordKey` |
| `search` | `sourcePage`, `searchCriteria` |
| `document` | `billKey`, `documentPath`, `recordKey` |
| `policy-profile` | `uuid`, `handle` |
| `user` (header) | `userId`, `firstName`, `lastName` for teammate bullets |

**Tracking (`TrackingUpdatesBriefingService`)** — manifest from portfolio + bill metadata:

| Kind | Fields |
|------|--------|
| Bill | `billKey`, bill number, title, profile name (if profile-linked) |
| Profile | `uuid`, `handle`, title (for “Set Up a Policy Profile” / profile-framed items) |

> **Note:** Tracking today uses library + profile keys + Postgres `updatedAt`, **not** `BillTrackingLog` movement events. Links can still open bill detail; “scroll to bill history” is Phase 4.

#### Stable refs in LLM context

Include `refId` in prompt lines, e.g.:

```text
- [team-3] Finn · bill · updated · "HB 993 • 2026" (title…) · at May 30…
```

Prompt rule: bullet **bold label** should match the quoted `itemLabel` from context (still no raw `fl/2026/…` in prose).

#### NDJSON protocol extension

On `final` (and cache hit path), include links:

```ts
type BriefingLinkKind =
  | 'bill' | 'statute' | 'chat' | 'search' | 'document' | 'policy-profile' | 'user'

type BriefingLink = {
  refId: string
  kind: BriefingLinkKind
  label: string           // text to linkify (bold segment)
  userId?: number
  billKey?: string
  statuteKey?: string
  chatHistoryId?: string
  recordKey?: string
  documentPath?: string
  policyProfileUuid?: string
  searchCriteria?: SavedSearch['searchCriteria']
  sourcePage?: string
}

type BriefingFinalPayload = {
  generatedAt: string
  fromCache: boolean
  links?: BriefingLink[]
}
```

**Cache:** write alongside markdown:

- `briefing/team/{YYYYMMDD}.md`
- `briefing/team/{YYYYMMDD}.links.json`

Same for `tracking`. On cache hit: stream cached md + load links JSON (regenerate links from source if JSON missing — optional fallback for old cache).

**Files:** `BriefingController.ts`, `TeamUpdatesBriefingService.ts`, `TrackingUpdatesBriefingService.ts`, `UserAgentWorkspaceLayout.ts` (cache key helpers if needed).

#### Frontend

| File | Change |
|------|--------|
| `rapApi.ts` | Parse `links` on `final` |
| `assistantBriefingStore.ts` | `links: BriefingLink[]` per card |
| `BriefingCard.tsx` | Accept `links`; render linked markdown or child component |
| `AssistantBriefing.tsx` | Pass `links` into cards |

**Link UI (TODO):** accent-colored text buttons / `LinkPill` variant; teammate **first bullet** = `AccountUserAvatar` + name → team activity or filtered view.

**Linkify strategy (pick one for v1):**

1. **Preprocessor** — replace known `label` strings in markdown with markdown links before `ReactMarkdown` (longest label first).
2. **Custom `components.strong`** — if child text matches a link `label`, wrap in `<button className="text-accent-link">`.
3. **Phase 3** — structured rows instead of parsing.

---

### Phase 3 — Structured bullet UX (optional, ~1 day)

Split card body:

1. Opening line — LLM markdown (unchanged).
2. **Items** — one row per manifest entry: `[LinkPill or avatar+name] + summary` (summary from LLM keyed by `refId`, or single sentence per ref in structured LLM output).

Avoids markdown matching entirely; closest to Team Activity table semantics.

---

### Phase 4 — Tracking + BillTrackingLog + scroll (~1–2 days, after data parity TODO)

When `TrackingUpdatesBriefingService` uses **BillTrackingLog movement** (not bill `updatedAt` / save only):

- Manifest entry includes `objectPath` when present → `buildPdfViewerUrl` (mirror `BillTracking.tsx` `handleRowClick`).
- Else → bill detail route.
- Optional: bill detail `?section=history` or `pushContext` + `scrollTarget` on bill detail page (only if that page supports it).

Depends on: `memory/TODO.md` — Tracking Updates → BillTrackingLog.

---

### Phase 5 — Team brief ↔ policy profile update-log (~1 day)

Team brief currently uses profile **`updatedAt`** for profile rows; **Team Activity** also shows **`policy-profile-event`** rows from update-log.

For parity:

- Extend `collectTeamActivity` with same `listPolicyProfileUpdateLog` / `policyProfileEventToActivityItem` path as `TeamActivity.tsx`.
- Add event rows to manifest (`uuid`, `action`, etc.).
- Align LLM context cap with `TEAM_ACTIVITY_PROFILE_LOG_MS` / row limits.

Depends on: `memory/TODO.md` — Team Updates brief → update-log entries.

---

## Teammate avatar (TODO item)

For bullets like **`Sir Finn`** (teammate header, not an item):

| Behavior | Implementation |
|----------|----------------|
| Show avatar | `AccountUserAvatar` + `userId` from manifest `kind: 'user'` |
| Accent link | `text-accent-link` / button — navigates to Team Activity |
| Optional filter | `/dashboard/team-activity?highlightUser={userId}` + scroll to first matching row (new query + effect in `TeamActivity.tsx`) |

Solo-account bullets (`**Your activity:**`) — no avatar; optional link to own library or team-activity self rows.

---

## What not to do (v1)

- Parse markdown with regex for bill numbers without manifest.
- Put raw `billKey` in LLM user-visible copy (conflicts with current prompts).
- Client-only link logic on cache hits without `.links.json`.
- Assume Tracking links equal “legislative movement” before BillTrackingLog wiring.

---

## Effort summary

| Phase | Effort | Deliverable |
|-------|--------|-------------|
| 1 Shared nav utils | S (~0.5 d) | Briefs back-nav + shared URLs |
| 2 Manifest + cache + linkify | M (~1–2 d) | Clickable team + tracking items |
| 2b Teammate avatar | S–M | TODO fellow-user behavior |
| 3 Structured rows | M (~1 d) | Reliable UX without parse |
| 4 Tracking + movement + scroll | M–L | True tracking-log destinations |
| 5 Team + update-log | M | Profile events like Team Activity |

**Suggested implementation order:** Phase 1 → Phase 2 (Team only) → 2b → Tracking manifest → Phase 5 → Phase 4.

---

## Acceptance criteria (when shipped)

- [ ] Team Updates: bold item labels (or structured rows) navigate to bill, statute, chat, search, PDF, or policy profile.
- [ ] Teammate name/avatar opens Team Activity context (or filtered teammate view).
- [ ] Leaving Briefs for a destination and pressing back restores `/dashboard/briefs` (navigation context).
- [ ] Cached briefs for today still show links (`.links.json` present).
- [ ] Tracking: at minimum bill detail links; movement-aware links after Phase 4.
- [ ] No regression: markdown-only fallback when `links` array empty (old cache).

---

## Key files (checklist)

| Area | Path |
|------|------|
| UI page | `apps/web/src/pages/dashboard/AssistantBriefing.tsx` |
| Card | `apps/web/src/components/dashboard/BriefingCard.tsx` |
| Store | `apps/web/src/stores/session/assistantBriefingStore.ts` |
| API client | `apps/web/src/services/rapApi.ts` |
| Reference | `apps/web/src/pages/dashboard/TeamActivity.tsx` |
| Team brief service | `packages/services/rap-service/src/services/briefing/TeamUpdatesBriefingService.ts` |
| Tracking brief service | `packages/services/rap-service/src/services/briefing/TrackingUpdatesBriefingService.ts` |
| Controller | `packages/services/rap-service/src/controllers/BriefingController.ts` |
| Nav context | `apps/web/src/stores/session/navigationContextStore.ts` |
| Bill tracking click | `apps/web/src/pages/dashboard/BillTracking.tsx` |

---

## Open questions (decide at implementation)

1. Linkify markdown vs Phase 3 structured rows for v1?
2. Teammate click: full Team Activity table vs filtered highlight?
3. Co-cache links JSON vs regenerate manifest on every cache hit (CPU vs consistency)?
4. Tracking v1: bill detail only OK until BillTrackingLog ships?

---

*Update this WIP when phases complete. Promote to MEMORY / code log at session close when shipped.*
