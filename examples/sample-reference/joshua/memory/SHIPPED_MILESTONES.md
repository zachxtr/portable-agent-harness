# Shipped milestones (archive)

Historical record of major shipped work. **Not** session pickup context — read `MEMORY.md` for current status. Append here at session close when something significant ships; do not duplicate into `MEMORY.md`.

---

## Harness (Joshua agent)

### 2026-06-04

- Lean `MEMORY.md` pickup snapshot + topic index (Framework / Project / Reference / WIP / Archive)
- `SESSION.md` Joshua harness guide; `SOUL.md` points to Full CRY! + DX subfolders; stack layers in `ARCHITECTURE_CONCEPTS.md`
- Reference split: `SHIPPED_MILESTONES.md`, `UI_TOKENS.md`, `OPS_BEDROCK.md`; DX moved to `data-experience-journey/`

---

## 2026-06-03

- Chat Response card — turn-level collapsible shell; copy in bubble; Sources / Show Details when expanded
- Chat PDF export — conversation title on turn PDFs; `PolicyCommandChat_{traceId}.pdf`; shared citation markers
- Legislative search top results — Focus 5/10/20; `legislativeSearchLimit`; discover `maxReturned` + dual-corpus cap (**QA verified**)
- Assistant Edit profile load — `buildPersonaSummaryFromProfile` / `normalizePersonaProfile` fix

## 2026-06-01

- Toggle Policy Profile — modal rename; chips toggle link/unlink
- Chat history — teammates see library-saved chats only (`savedLibraryOnlyUserIds`)

## 2026-05-30

- RAP agentic harness — evidence-free forced synthesis removed; grounded finalize
- Worker pipeline `response_mode` — search=discover, review=direct, analysis=agentic
- Platform bill discovery — `discoverBills()` + discover ASSEMBLE + template GENERATE
- Statute discovery + `activeFocus` — merge-and-rank; PA focus wired INTERPRET → worker
- RAP README canonical; briefing cards plumbing; Joshua doc cleanup; `SKILL_VARIABLES.md`
- System pages UI load audit — Indexing S3 stats storm fixed (`04bbb12b`)
- Assistant Focus — New Chat pill; policy profile allies/opponents UI hidden (API kept)

## 2026-05-29

- Policy profiles — list, update log v1, routing by UUID, forms, detail layout
- Add to policy profile modal fixes; library list cards; actions panel spacing; secondary buttons
- Team Activity — policy profile update-log rows

## 2026-05-28

- Accent palette simplified; ThemePicker; Team Activity row keys; PdfViewer sidebar UX

## 2026-05-27

- Assistant Focus UX — `AssistantModals`, scope pills, composer `AssistantActionBar`, mobile sheet
- Inbox review UI; Bill detail / Statute UI LinkPill cleanup

## Earlier (through 2026-05)

- PA persona read/write endpoints; setup wizard + AI avatar (Bedrock Stability us-west-2)
- Phase G — Assistant Profile page; dashboard `highlight-*` / `accent-*` theming
- PDF viewer architecture; user profile on login; library chips; token usage avatar rows
- Legislative search smoke (real bill IDs in prod sample)
