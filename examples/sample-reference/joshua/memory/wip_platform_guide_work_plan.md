# WIP — Platform Guide (in-app product reference)

> **Status:** **Implementing** — site map signed off; layout locked (left nav + **Home Dashboard**). Phase A/B in progress in `apps/web`.  
> **Not ground truth for shipped code** until Phase A lands.  
> **Out of scope:** `memory/TODO.md` updates during this WIP; public unauthenticated docs; **Research Guides** content (`/dashboard/guides` today — separate product surface).

---

## Decisions (locked from Zach — 2026-05-31)

| # | Decision |
|---|----------|
| 1 | **Authenticated only** — not on the public marketing site; **separate route tree** from `/dashboard/*` (still requires login). |
| 2 | **Special-topic callouts** — **Done**; topics folded into site map `##` sections (no separate backlog). |
| 3 | **WIP is the working doc** — iterate here; do not depend on TODO backlog edits for this effort. |
| 4 | **Content structure** — **route-following site map** with breadcrumb trails and a categorized TOC (see **Full site map (TOC + filenames)**). Sidebar alignment is a *consequence* of routes, not the organizing principle. |
| 10 | **Layered audiences** — **User** blocks are the base (everyone). **Account-admin** and **Assistant** blocks are **additive** (extra sections), not alternate full-page modes. Regular users never see admin or operational internals. |
| 11 | **Cross-entry** — when a surface is reachable from multiple places, the guide names **Also available from** (same app route, different nav path). |
| 12 | **Static delivery** — all guide pages are **repo markdown** loaded at build time. **No database reads**, no guide-specific API calls, no live sync to app state in v1. Auth gate only (logged-in user). |
| 13 | **Audience rendering** — **User** always on. **Account-admin** when `canAccessAdminArea()`. **Assistant** when **system admin** (`canAccessSystemOperations()`) **or** optional toggle (PA harness). **System admins** get **both** additive layers automatically — no toggles. |
| 16 | **Account admin in guide** — **Account** + **Users** top-level TOC groups (no Admin group); `/dashboard/admin/*` via additive `::: audience account-admin` blocks. **System Operations** remains out of scope. |
| 5 | **Styling** — reuse **public/legal page** visual language (`highlight-*`, brand wordmark, white prose layout) so the guide reads as **Policy Command the product**, not the user’s accent-themed account UI. |
| 6 | **Research Guides** (future rename of today’s `/dashboard/guides` SME marketplace) — **out of scope** for Platform Guide. Different visual language (curated datasets, dashboards). See **Product pairing** below. |
| 7 | **Entry point** — **User menu**, **just above Sign out** — **one row**: **Platform Guide** / **Page Help** (see **Contextual help resolver**). Not a sidebar item; no top-bar Help ▾ in v1. |
| 17 | **URL & code layout** — routes **`/platform-guide`** / **`/platform-guide/:slug`**; in-guide header **Platform Guide**. Repo paths **`pages/platform-guide/`**, **`components/platform-guide/`**, **`content/platform-guide/`**, utils **`platformGuide*.ts`** — aligned with URL, not `faq`. |
| 18 | **Content vibe** — articles read like a **professional product catalog**: marketing polish, feature clarity, scannable structure — not wiki tone, not support-ticket tone, not dev README tone (in **user** blocks). |
| 14 | **Slug = filename** — each article is `{name}.md`; URL `/platform-guide/{name}` (except home: `index.md` → `/platform-guide`). **Slug ≠ dashboard route** — `platformGuideContextMap` maps app paths → filename stem; never name `.md` files after React Router paths. |
| 15 | **Contextual open** — `openPlatformGuide({ contextUrl })` resolves `contextUrl` → article slug (or index fallback); **Page Help** passes current `location.pathname` (+ query if needed). |
| 8 | **Exit / return** — **Back to Dashboard** → **`/dashboard`** (app default). If `?from=` is present and valid, use it instead (optional exact return). **Required** control — no dashboard sidebar on `/platform-guide/*`. |
| 9 | **Shell** — **Standalone route tree** under `src/pages/platform-guide/`, **outside** `/dashboard/*` and **without** `MenuBar`. Auth-gated like the app; visual feel like Privacy/Terms (product docs), not the working dashboard. |
| 19 | **In-guide TOC** — persistent **left navigation menu** (desktop) from manifest; **collapsible drawer** on mobile. Same TOC on index and article pages (not index-only). |
| 20 | **No legacy redirects** — v1 ships **only** approved filename stems; **no** router or manifest redirects for retired slug names. |
| 21 | **Page Help — no match** — resolver opens **`/platform-guide`** (index). No toast in v1. |
| 22 | **Return query params** — support **`from`** and **`context`** on guide URLs; **Back to Dashboard** prefers decoded `from` when present, else `/dashboard`. Plumbing in v1; heavy use TBD. |
| 23 | **Account / Users TOC** — groups **hidden** when viewer lacks `canAccessAdminArea()` (non-admins never see them). |
| 24 | **Site map locked** — master table **signed off 2026-06-02**; **no** further consolidations (Home children, Statutes chapter/section, Policy Profiles, Admin leaves stay separate `.md` rows). |
| 25 | **System admins in guide** — `canAccessSystemOperations()` → **`showAccountAdmin`** and **`showAssistant`** both **true** at render (same auth as System Operations menu). No user-facing toggle required. **System Operations** product surface still **out of scope** for guide articles. |

---

## Purpose

A **Platform Guide** for logged-in users: marketing-quality copy that explains **what the product can do** and **how the pieces connect** — organized like an **old-school site map**: hierarchical routes, breadcrumb context, and a well-categorized TOC.

It is **not** **System Operations** / platform-wide admin. It **is** the map of the working app for normal users **plus**, for **account admins**, the **Billing Accounts** and **Users** areas under `/dashboard/admin/`.

**Route families:** **Introduction** → **Navigation Menus** → **User Profile** → Home → Chat → Bills → Statutes → Library → Policy Profiles → **Account** + **Users** (account-admin only).

**Readers (same pages, layered blocks):**

| Layer | Who | How it applies | What they see |
|-------|-----|----------------|---------------|
| **User** (base) | Every logged-in user | Always rendered | Product language: where to click, what a screen is for. **No** API paths, contracts, or internal service names. |
| **Account-admin** (additive) | `canAccessAdminArea()` — **`account-admin`** or **`system-admin`** | **Auto** from auth; not a user toggle | Extra sections on shared or admin-only articles: billing accounts, seats, user edit, roles, admin token usage, account status. Plain English; still no raw OpenAPI. |
| **Assistant** (additive) | **`canAccessSystemOperations()`** (system admin) **or** optional toggle / PA harness | System admins: **auto** (no toggle). Others: optional **View operational detail** | Extra blocks: skills, dispatch, endpoint families. System admins always see this layer stacked with account-admin when applicable. |

Joshua and the PA harness maintain **one markdown file per slug** with fenced audience blocks; the renderer **union**s visible layers. v1 is static product education.

**Not in scope for the guide UI:** live data, “current bill count,” personalized copy, or fetching user settings to tailor guide text.

---

## Product pairing — Platform Guide vs Research Guides

Two complementary surfaces; naming is intentional so neither competes with the other.

| | **Platform Guide** (this effort) | **Research Guides** (future rename of `/dashboard/guides`) |
|---|----------------------------------|-------------------------------------------------------------|
| **What it is** | Built-in platform reference — part of the product, like Privacy/Terms pages | Optional SME modules — marketplace / add-ons |
| **Feel** | Legal-page lineage: white prose, brand wordmark, `highlight-*`, **product catalog** copy | “Curated datasets, stylish dashboards,” distinct visual design |
| **URL (today → target)** | **`/platform-guide/*`** (locked) | `/dashboard/guides` → rename TBD (**Research Guides** working title) |
| **Entry** | User menu: **Platform Guide \| Page Help** | Sidebar / profile “Guides” today — relabel when renamed |
| **Content owner** | Product + engineering (markdown in repo) | Subject-matter experts per module |

**Elevation story for users:** Platform Guide = *how Policy Command works*; Research Guides = *specialized research packs on top*. Ship Guide copy without implying Guides marketplace content lives inside `/platform-guide`.

*Rename of dashboard Guides is a separate initiative — note in MEMORY when scheduled; not blocking Platform Guide v1.*

---

## Content vibe — professional product catalog (goal)

**User-facing articles** should feel like polished **marketing product pages** in a catalog: confident, clear, benefit-led, and structured — the same trust level as public legal/marketing pages, applied to authenticated education.

| Do | Avoid (in `::: audience user`) |
|----|----------------------------------|
| Lead with **what it is** + **why you’d use it** | Dumping UI control lists without context |
| Short **feature → outcome** pairs (“Save to library — revisit this bill from any device”) | Internal codenames, route paths, “click the API” |
| Consistent **taxonomy** (matches site map breadcrumbs) | Wiki voice (“you can also…”, endless see-also) |
| **Scannable** H2/H3, tables for comparisons | Wall-of-text release notes |
| Honest **shipped / coming soon** | Aspirational marketing for backlog |
| Cross-links as **“Related capabilities”** | Jargon-heavy “module interacts with service layer” |

**Assistant** / **account-admin** blocks carry precision; **user** blocks carry the catalog polish.

**Phase D checklist:** read each article aloud — would this sit in a product PDF for a lobbying firm? If it sounds like a dev README or Zendesk article, rewrite.

**Visual parity:** typography and page layout align with Privacy/Terms (`prose`, brand header); Research Guides will look different by design — do not mimic their dashboard cards inside Platform Guide.

---

## Design principles (2026-06-02)

1. **Follow main system routes** — TOC: **Introduction** (`index`, **Assistant**, **Features**) → **Navigation Menus** (four lenses) → **User Profile** → app destinations (Home, Chat, …).
2. **Breadcrumbs in every article** — e.g. `Home → Assistant briefs` at the top of prose; mirrors the site map node.
3. **Left nav TOC** — manifest-driven **left menu** on every guide page (desktop); mobile drawer. **Account** + **Users** groups only when `canAccessAdminArea()` (no Admin group).
4. **Also available from** — when the same route is opened from another nav path (e.g. Bill detail from Chat citation vs Bills index), call it out in a short aside; link to the canonical article once.
5. **PA dispatch, not omniscience** — Chat articles explain **Interpret → worker skill** (legislative search, legislative review, legislative analysis). UI “Save” / “Download” / “Track” = named backend capability the PA can invoke or describe honestly — in **Assistant** blocks only.
6. **Shipped vs backlog** — label aspirational UX as “Coming soon”; never imply Inbox batch clear, Edit & Accept, etc. are live if they are not.
7. **Static pages only** — markdown in git; Vite `import.meta.glob` (or equivalent) at build time. Runtime = auth check + render + client navigation. No guide CMS, no Postgres, no rap-service reads for guide content.
8. **Audience-gated prose** — **User** is always in the DOM. **Account-admin** and **Assistant** sections are omitted entirely unless the viewer qualifies (auth or toggle) — not collapsed with CSS.
9. **Contextual help** — dashboard knows *where you were*; the guide knows *which article to open* — joined only by the resolver map, not by shared slug strings with router paths.
10. **Catalog voice** — user blocks = professional product catalog; see **Content vibe** above.

---

## Full site map (TOC + filenames)

**Signed off — Zach, 2026-06-02.** Do not add rows or rename files without updating this table first.

**Single lock-in table** — manifest order (top → bottom), breadcrumb path, **file** (slug = basename without `.md`). Guide URL `/platform-guide/{stem}`; home = `index.md` → `/platform-guide`. Copy / lens notes live below; **add or rename rows only here**.

| Breadcrumb (folder path) | File (`content/platform-guide/`) | App route (Page Help) | Alias of |
|------|----------------------------------|------------------------|----------|
| Introduction (Platform Guide home) | `index.md` | — |  |
| Introduction → Assistant | `assistant.md` | — |  |
| Introduction → Features | `features.md` | — |  |
| Navigation Menus | `nav-menus.md` | — |  |
| Navigation Menus → Main Menu | `nav-menus-main-menu.md` | — |  |
| Navigation Menus → User Profile Menu | `nav-menus-user-profile-menu.md` | — |  |
| Navigation Menus → Mobile Panel | `nav-menus-mobile-panel.md` | — |  |
| Navigation Menus → Desktop Sidebar | `nav-menus-desktop-sidebar.md` | `/dashboard/bills`, `/dashboard/chat`, `/dashboard/library` |  |
| User Profile | `user-profile.md` | `/dashboard/profile` |  |
| User Profile → Assistant setup & settings | `assistant-settings.md` | `/dashboard/profile/assistant` |  |
| User Profile → Quick actions | `user-profile-quick-actions.md` | `/dashboard/profile/quick-actions` |  |
| User Profile → Share settings | `user-profile-share-settings.md` | `/dashboard/profile/share-settings` |  |
| User Profile → Navigation history | `user-profile-navigation-history.md` | `/dashboard/profile/navigation-history`, `…/sessions` |  |
| User Profile → Token usage | `user-profile-token-usage.md` | `/dashboard/profile/token-usage` |  |
| Home (hub — not in TOC) | `home.md` | `/dashboard/briefs` |  |
| Home → Assistant briefs | `home-assistant-briefs.md` | `/dashboard/briefs` |  |
| Home → Bill tracking | `home-bill-tracking.md` | `/dashboard/briefs` |  |
| Home → Team activity | `home-team-activity.md` | `/dashboard/briefs` |  |
| Chat | `chat.md` | `/dashboard/chat` |  |
| Bills | `bills.md` | `/dashboard/bills` |  |
| Bills → Bill Overview | `bills-details.md` | `/dashboard/bills/:billKey` |  |
| Bills → Document Annotations | `bills-document-annotations.md` | `/dashboard/bills/:billKey/pdf/:documentKey` |  |
| Statutes | `statutes.md` | `/dashboard/statutes` |  |
| Statutes → View chapter | `statutes-view-chapter.md` | `/dashboard/statutes/chapter/:id` |  |
| Statutes → View section | `statutes-view-section.md` | `/dashboard/statutes/section/:id` |  |
| Library | `library.md` | `/dashboard/library`, `…/library/bills`, `…/statutes`, `…/chats`, `…/searches`, `…/documents` |  |
| Policy Profiles | `policy-profiles.md` | `/dashboard/policy-profile` |  |
| Policy Profiles → Create | `policy-profiles-create.md` | `…/policy-profile/create` |  |
| Policy Profiles → Detail | `policy-profiles-detail.md` | `…/policy-profile/:uuid` |  |
| Policy Profiles → Edit | `policy-profiles-edit.md` | `…/policy-profile/:uuid/edit` |  |
| Account → Manage | `admin-accounts.md` | `/dashboard/admin/accounts` |  |
| Account → Create account | `admin-accounts-create.md` | `…/admin/accounts/create` |  |
| Account → Edit account | `admin-accounts-edit.md` | `…/admin/accounts/:accountId/edit` |  |
| Users → Manage | `admin-users.md` | `/dashboard/admin/users` |  |
| Users → Create user | `admin-users-create.md` | `…/admin/users/create` |  |
| Users → Edit user | `admin-users-edit.md` | `…/admin/users/:userId/edit` |  |
| Users → Token usage | `admin-users-token-usage.md` | `…/admin/users/:userId/token-usage` |  |
| Users → Configuration | `admin-users-configuration.md` | `…/admin/users/:userId/configuration` |  |

**Legend:** **Alias of** — shortcut `.md` file; canonical copy in that file (`canonicalSlug` in manifest = other file’s stem). Empty = canonical page. **App route** — Page Help / `platformGuideContextMap` target (→ filename stem; lens pages may use `#section-id`). TOC **`group` / `subGroup`** from breadcrumb prefixes (see **Site map — authoring notes**).

**When to use `##` vs a separate `.md` row (Zach):**

| Rule | Meaning |
|------|---------|
| **Separate row + file** | App has a **defined route** (`/dashboard/profile/quick-actions`, `…/assistant`, etc.) → own guide article. |
| **`##` on parent file** | UI block on **that route’s page**, no dedicated URL → heading only; **no table row**, no extra `.md`. |

Applies across the site map (Navigation Menus lenses, profile token/history **sub-UI**, etc.).

| File | `##` sections in that file |
|------|----------------------------|
| `nav-menus-main-menu.md` | Remember collapse · Destinations · Policy Profiles list · Admin items (when shown) |
| `nav-menus-user-profile-menu.md` | Avatar & account header · Platform Guide / Page Help · Sign out |
| `nav-menus-mobile-panel.md` | Action sheet · Page panel · Assistant panel (link **`assistant.md`** § Action bar, no duplicate copy) |
| `nav-menus-desktop-sidebar.md` | Bills sidebar · Chat history / controls · Library filters |
| `user-profile.md` | Platform theme (`ThemePicker` on profile index — same route as hub) |
| `user-profile-navigation-history.md` | Sessions (by date) · Timeline |
| `user-profile-token-usage.md` | AI generation (popup) · Usage period · Download · Subscription overview · Usage blocks |
| `chat.md` | Assistant action bar (link **`assistant.md`** § Action bar) · New chat · Chat history · Save to library · Turns · Cited sources · Download turn as PDF · Copy turn response · Save as PDF · Shared content |
| `assistant.md` | Policy Assistant and worker skills · Action bar · Inbox · Focus |
| `features.md` | Tags · Collaborative workspace · Policy profiles (feature) · Tokens & AI · Realtime bill tracking · **Research & analysis** |
| `bills.md` | Index · Download results · Save to library · Search · Filter / find · Bill tracking |
| `bills-details.md` | Tracking log · Overview & history · Versions · Annotations |
| `bills-document-annotations.md` | Viewer · Annotation tools · Save to library (when on PDF route) |
| `statutes.md` | Index (tree view) · Find |
| `library.md` | Saved bills · Saved statutes · Saved chats · Saved searches · Annotated documents |

**Home:** TOC shows **Assistant briefs**, **Bill tracking**, **Team activity** only (`home.md` is hub / Page Help default, `hideFromToc`). `/dashboard/briefs` → **`home.md`** via context map priority when needed.

**Chat:** `/dashboard/chat` → `chat.md` only (all chat UI = `##` on that file).

**Bills:** `/dashboard/bills` → `bills.md`. `/dashboard/bills/:billKey` → `bills-details.md`. `/dashboard/bills/:billKey/pdf/:documentKey` → `bills-document-annotations.md`.

**Statutes:** `/dashboard/statutes` → `statutes.md`. Chapter/section routes → `statutes-view-chapter.md`, `statutes-view-section.md`.

**Library:** All library tab routes → **`library.md`** (`##` per tab; index often redirects to bills — say so in hub).

**Introduction:** **`assistant.md`** and **`features.md`** — concept hubs (no app route); subtopics are **`##` only**. **`features.md` § Policy profiles** = product feature; app sidebar **Policy Profiles** → **`policy-profiles.md`**.

**User Profile:** one `.md` per routed profile page; **Platform theme** only → `##` on `user-profile.md`.

**Page Help (summary):** Map each **App route** column in the master table → filename stem; optional `#section-id` for `##` targets. **No match** → `/platform-guide` (index). **No legacy slug redirects** in v1.

### Zach IA updates (table — 2026-06)

Captured from your pass on the master table:

| Change | Notes |
|--------|--------|
| **Introduction** | `index.md` home; **`assistant.md`** + **`features.md`** concept hubs — subtopics **`##` only** (see sections table). |
| **Navigation Menus** | Dropped separate **`nav-menus-shared`** row for now — fold shared behavior into **`nav-menus.md`** hub and/or lens pages. |
| **User Profile** | **Own route = own `.md`** (assistant, quick actions, share, navigation history, token usage). **Platform theme** only → `##` on `user-profile.md` (same route as profile index). Nav/history + token **pages** keep separate files; **their** sub-UI = `##` on those files. |
| **Chat** | One route → **`chat.md`** only; all chat UI topics = **`##`**. |
| **Bills** | Index route → **`bills.md`** (`##`); detail route → **`bills-details.md`** (`##`). Two files, not twelve. |
| **Statutes** | Index route → **`statutes.md`** (`##` Index · Find); chapter/section routes → own `.md` each. |
| **Library** | Tab routes share **`library.md`** — one file, **`##`** per tab. |
| **Slug = file** | One column; URL = `/platform-guide/{stem}`. |
| **No further consolidations** | Home briefs children, Statutes chapter/section, Policy Profiles, Admin — **keep separate rows** (Zach sign-off). |

---

## Audience layers (user + account-admin + assistant)

One article, **stacked** visibility — not three mutually exclusive “modes.”

### Render rules

```ts
// apps/web/src/contexts/AuthContext.tsx
const { canAccessAdminArea, canAccessSystemOperations } = useAuth();

type PlatformGuideAudienceContext = {
  showUser: true;
  showAccountAdmin: boolean;
  showAssistant: boolean;
};

// Build context (Phase B):
const isSystemAdmin = canAccessSystemOperations();
const showAccountAdmin = canAccessAdminArea(); // true for account-admin AND system-admin
const showAssistant =
  isSystemAdmin || assistantDetailToggle; // PA harness: force assistantDetailToggle = true

// Visible blocks = user
//   ∪ (account-admin if showAccountAdmin)
//   ∪ (assistant if showAssistant)
```

| Layer | Gating | User-facing control |
|-------|--------|---------------------|
| `user` | Always (logged in) | None — default experience |
| `account-admin` | `canAccessAdminArea()` at render time | **None** — not a toggle regular users can enable |
| `assistant` | `canAccessSystemOperations()` **or** `assistantDetailToggle` | **System admins:** always on. **Others:** optional **View operational detail** toggle (hidden for regular users) |

**System admin** = role `system-admin` / permission `CAN_ACCESS_SYSTEM_OPERATIONS` (same gate as System Operations in `MenuBar`). They receive **account-admin + assistant** blocks on every article that defines them — no extra clicks.

**Account-admin** explains **account** vs **user** admin routes (MenuBar **Billing Accounts** / **Users**), roles (`user` vs `account-admin`), billing/seat concepts, per-user token usage in admin — still product copy, not system-ops runbooks.

### Content matrix

| Concern | User | + Account-admin | + Assistant |
|---------|------|-----------------|-------------|
| Wording | “Save to library” | “As account admin, you can open any user’s token usage from Users → …” | Endpoint family, worker skill IDs |
| `/dashboard/admin/*` | N/A or “contact your account admin” | Full admin site map leaves | Admin APIs if needed for PA |
| API paths / contracts | **Hidden** | **Hidden** (unless friendly label) | Shown in assistant blocks |
| System Operations sidebar | Out of scope | Out of scope | Out of scope |

### Authoring (markdown)

````markdown
::: audience user
You can save this bill to your library from the index or detail page.
:::

::: audience account-admin
From **Users**, open a teammate’s profile to view their token usage or configuration. Account admins manage seats and roles for this billing account only — not other accounts on the platform.
:::

::: audience assistant
**Operation:** library save — `POST` …/library/bills (see core-service). Admin user list: core-service account users API. Worker: none for save; …
:::
````

Shared intro (optional, no fence) — breadcrumb context visible to all layers.

Implementation (Phase B): remark pass or custom component for `::: audience user | account-admin | assistant`; filter with `PlatformGuideAudienceContext`. PA harness passes `{ showAssistant: true }` (and `showAccountAdmin` when doc is admin-related).

**Header UX (v1):**

| Viewer | Account-admin blocks | Assistant blocks | Header |
|--------|----------------------|------------------|--------|
| Regular user | — | — | No audience toggles |
| Account admin (not system) | Auto | Toggle **View operational detail** (off by default) | Optional badge: *Including account admin topics* |
| **System admin** | Auto | **Auto** | Optional badge only; **no** assistant toggle (both layers always on) |

---

## Policy Assistant audience (additive)

The PA (**Matilda** in harness terms) does **not** carry every product tool in her system prompt. She **dispatches** to operational parts of the platform:

| Layer | Role in guide copy |
|-------|------------------|
| **PA (Interpret)** | Understands intent, Focus, persona; routes to the right worker or explains UI. |
| **Worker skills** | Legislative search, legislative review, legislative analysis — evidence-backed retrieval and analysis. |
| **Services / APIs** | What happens when the user clicks Save, Track, Download, etc. |

**Per-article pattern (template):**

- **`::: audience user`** — what you see and why you’d use it; **Related routes**; **Also available from** when applicable.
- **`::: audience account-admin`** — only when this page (or a related admin route) applies; admin nav paths, roles, billing-account scope.
- **`::: audience assistant`** — operations, skills, services; API notes **only here**.
- Shared intro (optional) — breadcrumb context; no internals.

Canonical PA behavior: `memory/POLICY_ASSISTANT_AGENT_HARNESS.md`, `packages/services/rap-service/README.md`. Auth: `useAuth().canAccessAdminArea()`, `canAccessSystemOperations()`; roles in `apps/web/src/types/auth.ts` (`account-admin`, `system-admin`).

---

## Static delivery (no runtime data)

| Yes | No (v1) |
|-----|---------|
| Markdown files in `apps/web/src/content/platform-guide/` | Guide content from database |
| Build-time or client static import of `.md` strings | rap-service / core-service endpoints for guide pages |
| `UserProtectedRoute` — must be logged in | Personalizing copy from user profile or workspace |
| `canAccessAdminArea()` → **account-admin** blocks; `canAccessSystemOperations()` → **assistant** blocks (and account-admin via system perms) | Storing role in guide markdown |
| Client-side TOC/search over manifest | Server-side render per request with user context |

Content freshness = **deploy** (or dev hot reload). When features ship, update markdown in the same PR when possible (Phase E maintainability).

---

## UI actions → system operations

Document saves and primary buttons as **capabilities**, not mystery UI:

| User affordance (examples) | Operational truth (assistant blocks should name) |
|----------------------------|-------------------------------------|
| Save to library (bill, statute, chat, search) | Library persist API / saved-item type |
| Bill tracking toggle / tracking log | `BillTrackingLog`, scraper-driven updates vs user save |
| Download results / turn PDF | Export or PDF generation path |
| Chat turn / trace details | Turn log, trace IDs, subscription/token linkage |
| Token usage download / period picker | Usage API, billing period, Stripe subscription overview |
| Cited source → View bill / statute / PDF | Navigation to detail routes + document viewer |

Exact names come from code during the copy pass; document them in **`::: audience assistant`** blocks only. User blocks stay plain English (“your library,” “tracking updates,” “token usage”).

---

## Platform concepts (introduction layer)

The **index** (`index.md`) should teach cross-cutting ideas before users dive into route-mirrored sections. **v1 concept copy lives in two hub files** (no extra slug files):

| Concept | Canonical article | Section |
|---------|-------------------|---------|
| Agent workspace, persona, memory boundaries | **`features.md`** | **§ Collaborative workspace** (and cross-links from **`assistant.md`**) |
| Policy Assistant, worker skills, action bar | **`assistant.md`** | **§ Policy Assistant and worker skills** · **§ Action bar** |
| Inbox & Focus | **`assistant.md`** | **§ Inbox** · **§ Focus** |
| Tags, tokens, realtime tracking, bill research via chat | **`features.md`** | matching **`##`** rows in site map; **§ Research & analysis** for “ask better questions” workflow |

### Your agent workspace (copy targets)

Every Policy Command user has a **private agent workspace** — persistent cloud storage scoped to their account. It is not the dashboard UI or PostgreSQL library rows; it is the **assistant’s durable home** for personality, memory, conversation artifacts, and operating rules.

**Platform Guide should explain (user-facing, not S3 key jargon):**

| Idea | What to say |
|------|-------------|
| **What it is** | Your assistant’s long-lived folder: who it is, what it knows about you, what it remembers, and logs of serious work (chats, briefs, setup). |
| **Persona** | Files like identity, soul, user profile, long-term memory, and session memory — loaded when setup is complete so every turn starts with consistent context. |
| **What the assistant can access** | **Always (when set up):** persona files, session memory index, active Focus (bills/statutes/session). **On demand during chat:** other chat threads, navigation history, your library (saved bills, bookmarks, annotations). **Via worker skills:** legislative search, bill review, analysis — deeper retrieval with evidence, not guessed answers. |
| **What stays in the database vs workspace** | Library saves, bill tracking, policy profiles, team activity — largely DB + profile folders; the assistant **reaches** them through workspace operations and Focus, not by magic. |
| **What the assistant does not freely do** | Boundaries from `WORKSPACE.md`: no political positioning, no leaking your data, ask before external/destructive actions; ordinary chat does **not** silently rewrite long-term memory (Inbox / Distill / explicit edits). |
| **You stay in control** | Inbox proposals for persona changes; Memories tab for distill; **`assistant-settings.md`** for IDENTITY/SOUL/USER; token usage tied to workspace turn logs. |

**Write here:** `features.md` § Collaborative workspace — link from `index.md`, **`assistant.md`**, **`assistant-settings.md`**, `chat.md`.

**Canonical source for copy accuracy:** `memory/POLICY_ASSISTANT_AGENT_HARNESS.md`, `packages/services/rap-service/src/agent-templates/_system/agent-persona/WORKSPACE.md`, `AgentWorkspaceService.ts` (always-loaded keys).

### Inbox and Focus (copy targets)

Two companion controls on the **Assistant action bar** (Chat, Briefs, Assistant Settings) — not buried in profile menus.

**Focus** — working context (platform, session, statute year, scope pills). **Inbox** — approval queue for persona proposals (not ordinary chat). **Write here:** `assistant.md` § Inbox · § Focus. **`chat.md`** stays operational (“how to chat”) with short pointers to those sections.

**Canonical source:** `memory/POLICY_ASSISTANT_AGENT_HARNESS.md` (Inbox §, Focus/UI table), `memory/ARCHITECTURE_CONCEPTS.md` §10, `AssistantFocusPanel.tsx`, `AssistantInboxPanel.tsx`, `assistantFocusStore`, `SKILL_VARIABLES.md` (`activeFocus`).

### Research & analysis (copy targets — `features.md`)

**§ Research & analysis** — how to use **Chat** to dig into a bill (concept/feature layer, not a duplicate of `chat.md` UI steps).

| Idea | What to say |
|------|-------------|
| **Lead** | *The better the question, the better AI can be* — specificity beats vague asks. |
| **Workflow** | Open or cite a bill → set **Focus** if needed → ask targeted questions (summary, fiscal impact, sponsors, compare versions, “what changed in committee”). |
| **Good questions** | Name the bill section, session, or comparison you care about; say what decision you’re supporting. |
| **What the assistant does** | Routes to worker skills when needed (search, review, analysis) — link **`assistant.md`** § Policy Assistant and worker skills; operational clicks stay in **`chat.md`**. |
| **Cross-links** | `chat.md`, `bills-details.md`, **`assistant.md`** § Focus; optional pointer to **Policy profiles** research workflow when shipped. |

---

## Site map — authoring notes

All slugs, files, and URLs: **[Full site map](#full-site-map-toc--filenames)** table only.

### Navigation Menus (four lenses)

| Lens (`subGroup`) | What the user sees | Code touchpoints |
|-------------------|-------------------|------------------|
| **Main Menu** | Persistent app nav — Home, Chat, Bills, … | `MenuBar` left column, `sidebarCollapsed`, Policy Profiles expand |
| **User Profile Menu** | Avatar dropdown | Profile routes, **Platform Guide / Page Help**, sign out — not profile *pages* |
| **Mobile Panel** | On-the-go action sheet | `MobileActionSheet` — page panel (0) + assistant panel (1) |
| **Desktop Sidebar** | Page column beside content | One page; **`##`** per screen (Bills, Chat, Library) |

**Paired lenses:** Page-context copy lives in **`##`** sections on **`nav-menus-desktop-sidebar`**; **`nav-menus-mobile-panel`** **`## Page panel`** points here (same content, different shell). **`## Assistant panel`** links **`assistant.md`** § Action bar — no duplicate persona/worker copy.

**Shared menu behavior** (scroll-restore, collapse): document in **`nav-menus.md`** hub and/or lens `##` sections — **no** `nav-menus-shared.md` file. See `memory/ARCHITECTURE_CONCEPTS.md` § Navigation context.

**Manifest / in-guide TOC:** Four lens files + `nav-menus` hub — no child files for menu `##` sections. User Profile: one manifest entry per **routed** `.md`; `##`-only blocks (Platform theme on index) are not separate TOC leaves.

### Hub pages

Rows marked hub in copy (`nav-menus`, `home`, `chat`, …): overview + children listed in **left nav TOC**. **Admin** group: `requiresAccountAdmin: true` — **omitted from TOC** when `!canAccessAdminArea()` (no stub hub for non-admins).

### Out of scope (v1)

Research Guides (`/dashboard/guides`), System Operations, public routes. **In scope:** `admin` / `admin-*` slugs via `account-admin` audience; MenuBar labels **Billing Accounts** / **Users**.

---

## Routes & auth — standalone (not under dashboard)

**Yes — a separate `src/pages/platform-guide/` tree is simpler and matches the “different feel” goal.** Platform Guide should not reuse `MenuBar`; it is a **protected doc site** inside the same SPA, sibling to `/dashboard/*` (like `/privacy` is public and sibling to dashboard).

### URL shape (recommended)

```
/platform-guide           → index (introduction + TOC)
/platform-guide/:slug     → article (markdown body)
```

- Repo folder **`pages/platform-guide/`** matches public URL **`/platform-guide`** (locked; distinct from future **Research Guides** on `/dashboard/guides`).

### `App.tsx` wiring (pattern)

Mirror **public** routes block (no `MenuBar`), but wrap with **`UserProtectedRoute`**:

```tsx
{/* Platform Guide — authenticated, no dashboard MenuBar */}
<Route
  path='/platform-guide/*'
  element={
    <UserProtectedRoute>
      <PlatformGuideApp />   {/* nested Routes: index + :slug */}
    </UserProtectedRoute>
  }
/>
```

- `PlatformGuideApp` (or `pages/platform-guide/index.tsx` router shell) owns layout + nested routes — **not** nested under `/dashboard/*`.
- Unauthenticated → existing redirect to `/login` (same as dashboard).
- **No** `AssistantModalsProvider`, **no** `DashboardThemeProvider`, **no** accent CSS — naturally “Policy Command product” not “my workspace.”

### Why this is easier

| Approach | Pros | Cons |
|----------|------|------|
| **Guide inside `MenuBar`** | One less route block | Sidebar competes with doc TOC; accent theme leaks; hard to feel “outside the app” |
| **Standalone protected routes** (chosen) | Clear mental model; dedicated left nav + **Home Dashboard**; no action sheet | Own mobile drawer (not dashboard sheet) |

### Layout (`PlatformGuideLayout` — full-page guide shell)

**Simple left-menu + main page** (Zach). No dashboard `MenuBar`; **no mobile action sheet** on guide routes (contrast with dashboard `MobileActionSheet`).

| Concern | Approach |
|---------|----------|
| **Chrome** | Fixed **left column** (~256px desktop): brand, **Home Dashboard**, expandable **TOC tree**; **main column** = prose (`<Outlet />`). |
| **Brand** | Wordmark at top of left column (→ `/platform-guide` index). |
| **Return to app** | **Home Dashboard** button directly **below the logo** (primary exit) → decode **`?from=`** when present and safe, else **`/dashboard`**. Label: **Home Dashboard** (not buried in header). |
| **TOC** | Below Home Dashboard: **expandable tree** (`PlatformGuideToc`) — groups/subgroups from manifest; chevron expand/collapse like dashboard sidebar patterns. Same tree on index + articles. |
| **Mobile** | Same left nav as dashboard: **overlay drawer** + hamburger on main column (`lg:hidden`); **no** bottom action sheet, no Focus/Inbox chrome. |
| **Typography** | `prose` + `highlight-*` links; zero `accent-*` / `btn-accent`. |
| **Body background** | `useEffect` white on `html`/`body` like `Privacy.tsx`. |
| **Audience (header)** | Optional **View operational detail** toggle in main column header for non–system-admin; system admins get both layers without toggle (decision #25). |

**File layout:**

```
apps/web/src/pages/platform-guide/
  PlatformGuideApp.tsx              # <Routes> for index + :slug
  PlatformGuideIndexPage.tsx
  PlatformGuideArticlePage.tsx
apps/web/src/components/platform-guide/
  PlatformGuideLayout.tsx           # header, Back to Dashboard, TOC slot, outlet
  PlatformGuideToc.tsx
apps/web/src/content/platform-guide/   # markdown source of truth
apps/web/src/utils/
  platformGuideContent.ts
  platformGuideManifest.ts
  platformGuideContextMap.ts
  platformGuideAudience.ts
  resolvePlatformGuideSlug.ts
  openPlatformGuide.ts
```

---

## Navigation (logged-in)

### Open Platform Guide (entry)

**Primary (v1):** `MenuBar.tsx` — **user profile dropdown**, bottom section (`border-t` block), **immediately above Sign out** (and above Install PWA when shown).

**Help row — single menu line, two links** (one `flex` row above Sign out; same padding as Token Usage / Share Settings):

| Link | Action |
|------|--------|
| **Platform Guide** | `navigate('/platform-guide')` — site map home / TOC |
| **Page Help** | `openPlatformGuide({ contextUrl: location.pathname + location.search })` — resolver picks article (see below) |

**Layout (draft):** one row with leading `QuestionMarkCircleIcon` (or `AcademicCapIcon`), then inline text links separated by `/` or `·`:

`Platform Guide` / `Page Help`

Both are `<button>` or `<a>` with `highlight-*` on hover; clicking either closes the menu (`setUserMenuOpen(false)`) then navigates.

**Page Help** is **muted or disabled** when already on `/platform-guide/*` (nowhere contextual to return from). If resolver has **no match**, open **`/platform-guide`** (index) — no toast in v1.

**Labels locked:** menu **Platform Guide** / **Page Help**; in-guide header **Platform Guide** (same name family).

Placement reference — insert **before** Sign out in the “Bottom actions” block (~line 1091 in `MenuBar.tsx`).

**Not v1:** sidebar item for Platform Guide; top-bar **Help ▾** dropdown; Landing footer link.

**Optional later:** duplicate general link on Profile → Quick Actions; per-page **?** icon in page headers calling the same `openPlatformGuide`.

---

## Contextual help resolver (Page Help)

**Problem:** Users want help for *this screen*, but guide **filenames** are product names, not React Router paths. Map `/dashboard/bills/:billId` → `bills-details.md` (use `#tracking-log` etc.), not a file named after the param.

**Approach:** A static, build-time **`platformGuideContextMap`** (separate from human TOC titles) lists **app route patterns → article slug**. The web app calls one helper; the guide reads an optional query param and lands on the resolved slug.

### Data model (`platformGuideContextMap.ts`)

```ts
type PlatformGuideContextRule = {
  /** React Router–style pattern, e.g. /dashboard/bills/:billId */
  pattern: string;
  /** Site-map slug — NOT required to mirror pattern segments */
  slug: string;
  /** Lower = higher priority when multiple rules match (optional; default array order) */
  priority?: number;
  /** Notes for authors — Assistant audience only in registry UI */
  note?: string;
};

export const platformGuideContextMap: PlatformGuideContextRule[] = [ /* ordered */ ];
```

| Field | Purpose |
|-------|---------|
| `pattern` | Match `contextUrl` pathname (use existing path-to-regexp or React Router `matchPath`) |
| `slug` | Target article under `/platform-guide/:slug` |
| `priority` / **array order** | Tie-break when several patterns match the same URL |

**One guide article per app route (default):** e.g. `/dashboard/chat` → `chat.md` only; use `#section-id` if Page Help should scroll to a `##`. **Multiple patterns → one file stem:** allowed. **Multiple manifest slugs → one route:** allowed when intentional (e.g. **Home** — four articles, one `/dashboard/briefs`; set explicit **`priority`** so Page Help picks one default slug).

**One route → multiple article slugs:** resolver returns **one** winner:

| Strategy | Recommendation |
|----------|----------------|
| **First match in map** (after sorting by `priority`, then file order) | **Default for v1** — deterministic, easy to reason about in code review |
| Newest markdown `mtime` | Possible v1.1 — surprising in CI; only if we auto-generate map from front matter `contextRoutes: []` |

Zach lean: *“top 1, order not important”* → implement **explicit priority + stable sort**; document the ordered list in Assistant registry view so authors see conflicts.

**No match:** navigate to **`/platform-guide`** (index). Preserve **`?from=`** and **`?context=`** on the URL when opening Page Help (plumbing v1; product use of `context` TBD).

### Web helper (`openPlatformGuide`)

```ts
// apps/web/src/utils/openPlatformGuide.ts
openPlatformGuide({
  contextUrl?: string;   // default: window.location.pathname + search
  slug?: string;         // bypass resolver when caller already knows slug
  returnTo?: string;     // optional: encode for Back to Dashboard / return label
});
```

1. If `slug` provided → `/platform-guide/${slug}`.
2. Else `resolvePlatformGuideSlug(contextUrl)` using `platformGuideContextMap`.
3. Navigate with optional query, e.g. `/platform-guide/chat?from=${encodeURIComponent(contextUrl)}&context=…` (optional `#save-to-library`) so **Back to Dashboard** can restore the calling screen when `from` is set.

**Static:** resolver is pure functions + in-memory map — **no API call**.

### Platform Guide app boot

On `PlatformGuideArticlePage` / `PlatformGuideIndexPage` mount:

- Read **`?from=`** (return URL for **Back to Dashboard**) and **`?context=`** (opaque caller context — reserved; light use in v1).
- If navigated via resolver, slug is already in the path; query params are for **return wayfinding** / future tooling.

### Assistant-only: route registry view

In **Assistant** audience (or a dedicated manifest page `platform-guide-route-registry` linked only from Assistant TOC):

| Column | Content |
|--------|---------|
| App pattern | `/dashboard/chat`, `/dashboard/bills/:billId`, … |
| Resolves to slug | `chat`, `bills-details`, … |
| Article title | From manifest |
| Conflicts | Other rules with same pattern (highlight duplicates) |
| Orphans | Patterns with no markdown stub yet; slugs with no patterns |

This is the **authoring surface** for “what SHOULD resolve when **Page Help** is hit” — not something users maintain in prose.

Optional: generate registry table from `platformGuideContextMap.ts` at build time into a markdown appendix for PA workspace sync.

### Per-page “Help” in dashboard (later)

Same helper from bill detail header, chat composer, etc.:

```ts
openPlatformGuide({ contextUrl: location.pathname + location.search });
```

No duplicate resolver logic in each page.

### Relationship to site map

| Layer | Names |
|-------|--------|
| **Site map / TOC** | Human breadcrumbs, `home-assistant-briefs`, etc. |
| **platformGuideContextMap** | Machine mapping from app URLs → slug |
| **Also available from** (prose) | User-facing cross-links; optional duplicate of map entries for reading flow |

When adding a new dashboard route, ship **either** a new guide article **or** extend an existing pattern in `platformGuideContextMap` — both in the same PR when possible.

### Return to dashboard / platform (exit)

Standalone Platform Guide **has no sidebar** — **Back to Dashboard** is the primary return path (not optional).

| Control | Behavior |
|---------|----------|
| **Home Dashboard** (primary) | Top of **left column**, below logo — → **`?from=`** when present, else **`/dashboard`**. |
| **Wordmark** | → `/platform-guide` (guide home). |
| **Browser back** | Returns to last dashboard page if user came from menu link — fine as secondary. |
| **Re-open app** | User menu link only exists **on** dashboard routes; after Back, menu works as today. |

**Optional v1.1:** `pushContext` when leaving dashboard for the guide so Back restores exact prior URL (`/dashboard/bills/...`).

**Mobile:** Hamburger opens **TOC drawer only** (same overlay pattern as dashboard sidebar); **no** `MobileActionSheet`.

---

## Content — markdown in repo

One file per **site map slug** (see table above). Hub pages summarize children; leaves use **`::: audience user`** and, where needed, **`account-admin`** / **`assistant`** blocks (see **Audience layers**).

```
apps/web/src/content/platform-guide/
  index.md
  assistant.md                       # ## worker skills, action bar, inbox, focus
  features.md                      # ## tags, workspace, policy profiles (feature), tokens & AI, bill tracking, research & analysis
  nav-menus.md
  user-profile.md                    # ## Platform theme (index route only)
  assistant-settings.md            # /dashboard/profile/assistant
  user-profile-quick-actions.md
  user-profile-share-settings.md
  user-profile-navigation-history.md   # ## Sessions, Timeline
  user-profile-token-usage.md            # ## AI generation, period, download, subscription, blocks
  home.md
  home-assistant-briefs.md
  home-bill-tracking.md
  home-team-activity.md
  chat.md                         # ## action bar, new chat, history, save, turns, citations, PDF, shared, …
  bills.md                          # ## index affordances
  bills-details.md                  # ## tracking log, overview, versions, annotations
  bills-document-annotations.md     # PDF annotation viewer route
  statutes.md                      # ## index tree view, find
  statutes-view-chapter.md
  statutes-view-section.md
  library.md                         # ## saved bills, statutes, chats, searches, annotated documents
  policy-profiles.md
  policy-profiles-*.md
  admin.md
  admin-accounts*.md
  admin-users*.md
  nav-menus-main-menu.md          # ## Remember collapse, Destinations, …
  nav-menus-user-profile-menu.md  # ## Avatar, Platform Guide / Page Help, Sign out
  nav-menus-mobile-panel.md       # ## Action sheet, Page panel, Assistant panel
  nav-menus-desktop-sidebar.md    # ## Bills, Chat, Library
```

**Manifest (`platformGuideManifest.ts`):** each entry includes `slug`, `title`, `breadcrumb[]`, `group`, `subGroup?` (TOC nest under Introduction or Navigation Menus), `parentSlug?`, `canonicalSlug?`, `alsoFrom?: string[]`.

**Context map (`platformGuideContextMap.ts`):** `pattern`, `slug`, optional `priority`, `note` — **not** duplicated in every markdown file (optional front matter `contextRoutes` later for codegen). See **Contextual help resolver**.

**Per-article layout:**

- Render `breadcrumb` as clickable trail (parent slugs link up).
- Optional **Also available from** callout when `alsoFrom` is set (typically inside **user** block).
- **Audience toggle** in `PlatformGuideLayout` → filters markdown before render.

**Loader:** Vite `import.meta.glob` for `*.md` → map slug to raw string at build time; **no fetch to backend for body text**. Render with **`react-markdown`** (+ `remarkGfm`; custom component or remark pass for `::: audience`).

**Front matter (recommended v1):** YAML `title`, `breadcrumb`, `group`, `order`, `canonicalSlug`, `alsoFrom` — can mirror manifest if we generate manifest from front matter later.

**Tone:** **Professional product catalog** in user blocks (see **Content vibe**); accurate to **shipped** UX; operational truth in assistant blocks per **UI actions → system operations**.

---

## UI components (new)

| Piece | Responsibility |
|-------|----------------|
| `pages/platform-guide/PlatformGuideApp.tsx` | Nested `Routes` under `/platform-guide/*` |
| `pages/platform-guide/PlatformGuideIndexPage.tsx` | Intro prose in main column; shares **left nav TOC** with articles |
| `pages/platform-guide/PlatformGuideArticlePage.tsx` | Loads slug from static map; filters markdown by audience; 404 → index or “not found” |
| `components/platform-guide/PlatformGuideLayout.tsx` | Left column: logo, **Home Dashboard**, tree TOC; main: optional assistant toggle, `<Outlet />` |
| `components/platform-guide/platformGuideAudience.ts` | `filterMarkdownByAudience()`; `showAccountAdmin` ← `canAccessAdminArea()`; `showAssistant` ← `canAccessSystemOperations()` \|\| toggle |
| `components/platform-guide/PlatformGuideToc.tsx` | **Left nav menu** from manifest; filters Admin group when `!canAccessAdminArea()` |
| `content/platform-guide/*.md` | Source of truth copy |
| `utils/platformGuideManifest.ts` | Site map: slug, title, breadcrumb[], group, parent, canonicalSlug, alsoFrom |
| `utils/platformGuideContextMap.ts` | App route patterns → article slug (Page Help) |
| `utils/resolvePlatformGuideSlug.ts` | Pure resolver + tests |
| `utils/openPlatformGuide.ts` | Navigate to guide home or resolved slug + optional `from` query |

---

## Implementation phases

### Phase 0 — Site map completion (current)

- [x] Zach sign-off on **Full site map** master table (**2026-06-02**).
- [x] Open questions **2–8** locked (see **Decisions**).
- [ ] Code walk: every **App route** column → real React route + param names (`:billKey`, etc.).
- [ ] Draft **`platformGuideContextMap`** from table (include Home **priority** rules; PDF → `bills-document-annotations`).
- [ ] Fill **UI actions → system operations** for Chat, Bills, Library, Token usage (assistant blocks).

### Phase A — Content skeleton + manifest

- [x] `platformGuideManifest.ts` from approved site map.
- [x] Stubs: 40 `.md` files under `content/platform-guide/` (`features.md` includes **Research & analysis**).
- [ ] Richer catalog copy pass (Phase D).

### Phase B — Routes + rendering

- [x] `PlatformGuideLayout` (logo, **Home Dashboard**, tree TOC; mobile drawer, no action sheet).
- [x] `PlatformGuideApp`, index + article pages, `platformGuideContent` glob loader, audience filter.
- [x] `App.tsx`: `/platform-guide/*` + `UserProtectedRoute` (outside `MenuBar`).

### Phase C — Entry + exit navigation

- [x] `MenuBar` user menu: **Platform Guide** / **Page Help** (Page Help disabled on guide routes).
- [x] `platformGuideContextMap`, `resolvePlatformGuideSlug`, `openPlatformGuide`.
- [x] **Home Dashboard** → `?from=` or `/dashboard`; audience wiring per decision #25.
- [ ] (Optional later) Profile Quick Actions link; per-page **?** icons.

### Phase D — Copy pass + cross-links

- Fill remaining stubs; breadcrumb + **Also available from** on every leaf.
- **Catalog pass** on all `::: audience user` blocks — product catalog polish checklist in **Content vibe**.
- Wire **UI actions → system operations** per section from code.
- Pull accurate details from shipped UI (Focus, update log, ThemePicker, BillTrackingLog vs save, trace/turn modals).

### Phase E — Agent maintainability (later)

- Note in Joshua `MEMORY.md` / skill: update `content/platform-guide/` markdown when shipping user-visible features.
- No auto-sync pipeline in v1.

---

## Technical notes

- **Static only:** all guide HTML comes from bundled markdown strings — **zero guide-specific DB or API calls** for content.
- **`react-markdown`** already in `apps/web`; reuse `remarkGfm` for tables; add audience container handling.
- **Search (later):** client-side filter across manifest titles; still no server index in v1.
- **Deep links:** `/platform-guide/assistant-settings` (and any slug) shareable inside org; still auth-gated.
- **Route guard:** `/platform-guide/*` must stay **sibling** to `/dashboard/*`, not child — prevents accidental `MenuBar` wrap.
- **SEO:** N/A (authenticated).

---

## Acceptance criteria (v1)

- [ ] User menu shows **one row**: **Platform Guide** / **Page Help** (above Sign out).
- [ ] **Platform Guide** opens `/platform-guide`; **Page Help** resolves dashboard URL → slug via `platformGuideContextMap`.
- [ ] User-facing copy passes **product catalog** tone (Phase D checklist).
- [ ] Platform Guide renders **without** dashboard sidebar or `MenuBar` top bar.
- [ ] **Back to Dashboard** → **`/dashboard`**, or **`?from=`** when set.
- [ ] **Left nav TOC** visible on index and articles (desktop); Admin group hidden for non–account-admins.
- [ ] Index + articles: Introduction (`index`, Assistant, Features) → Navigation Menus → User Profile → Home → … → Admin (admin group gated).
- [ ] Every row in **Site map** table has a stub with **breadcrumb** + `user` blocks; admin slugs also have `account-admin` blocks.
- [ ] **Account-admin** blocks visible only when `canAccessAdminArea()`; not exposed via a user toggle.
- [ ] **System admins** (`canAccessSystemOperations()`) see **account-admin + assistant** blocks automatically (no assistant toggle).
- [ ] **Account admins** (non-system) see account-admin blocks automatically; assistant blocks only when **View operational detail** is on.
- [ ] Regular users never see account-admin or assistant content in the DOM.
- [ ] No backend fetch for guide body.
- [ ] Guide pages do not call DB or product APIs for copy (auth gate only).
- [ ] Hub pages list children; cross-entry pages include **Also available from**.
- [ ] `assistant.md` § Policy Assistant and worker skills explains PA → three worker skills; § Inbox · § Focus are canonical for those concepts; `features.md` § Collaborative workspace for workspace concept; **`features.md` § Research & analysis** teaches bill deep-dive via chat (“better questions → better AI”); `chat.md` points to `assistant.md` / `features.md` where needed.
- [ ] Page Help **no match** opens index (no toast).
- [ ] **No** legacy slug redirects in router or manifest.
- [ ] Unknown slug shows friendly fallback (link to index).
- [ ] No public `/platform-guide` without auth; no Research Guides marketplace content mixed in.

---

## Decisions — final review (Zach, 2026-06-02)

| # | Topic | Resolution |
|---|--------|------------|
| 1 | URL / menu naming | **Locked:** `/platform-guide`, menu **Platform Guide / Page Help**. |
| 2 | **Back to Dashboard** | **`/dashboard`** default; **`?from=`** overrides when present. |
| 3 | In-guide navigation | **Left menu TOC** on index + articles (desktop); mobile drawer. *(Not “index-only TOC” — the guide has its own left nav, separate from dashboard `MenuBar`.)* |
| 4 | File layout | Flat `content/platform-guide/{stem}.md`; **`##`** for sub-areas on the **same** route only (per site map table). |
| 5 | Legacy slugs | **None** in v1 — no redirects for retired names. |
| 6 | Page Help **no match** | Open **`/platform-guide`** (index). |
| 7 | Query params | **`from`** + **`context`** supported; Back prefers `from`; usage of `context` TBD. |
| 8 | Admin TOC | **Hidden** when `!canAccessAdminArea()`. |
| 9 | Research Guides rename | **Deferred** — not blocking v1. |

Also locked: **site map table** (master TOC + filenames); **no** further file consolidations.

---

## Next steps (implementation)

1. **Phase 0 code walk** — validate **App route** column against `App.tsx` / route config; note Home Page Help **priority**.
2. **Draft `platformGuideContextMap`** — one ordered rule list from the table; document multi-slug routes (Home, Library).
3. **Phase A** — `platformGuideManifest.ts` + markdown stubs for every table row (~42 files).
4. **Phase B–C** — shell, left TOC, auth, menu entry, resolver, Back behavior.

---

*Zach sign-off on site map **2026-06-02**; open questions **2–8** locked same session. Promote to MEMORY / code log when Phase A ships.*
