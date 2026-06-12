---
wip:
  topic: TopicX
  phase: design
  updated: {{INSTALL_DATE}}
  # loop: 1          # omit in design; start at 1 on first create
  # next_yield: null # set when entering yield (e.g. "local click path")
---

# WIP: TopicX — CRY work slice

> **Template** — Copy to `memory/wip_<topic>_work_plan.md` (e.g. `wip_auth_refresh_work_plan.md`).  
> Follow `skills/wip-management/SKILL.md` for the Full CRY! WIP cycle.  
> When shipped: append `SHIPPED_MILESTONES.md`, set `phase: shipped`, move to `memory/.archive/`, remove from MEMORY WIP index.

---

## Summary

*(One paragraph: what this slice delivers and why now.)*

---

## Scope

**In**

- *(bullet)*

**Out**

- *(bullet)*

---

## Spec

*(Forward-looking design — describe behavior and contracts as they **will be**. Tables, checklists, file touch lists. No product code in **design** phase.)*

---

## Implementation phases

- [ ] **Design** — scope locked, TODO groomed, spec written
- [ ] **Create** — scaffold and first implementation
- [ ] **Refactor** — sculpt, align `CODING_PRINCIPLES.md`
- [ ] **Yield** — {{USER_WHAT_TO_CALL}} validates as first user
- [ ] **Shipped** — milestones appended, WIP archived

---

## Acceptance / yield

How we know this slice is done *(click path, test, demo, data check)*:

1. *(criterion)*
2. *(criterion)*

---

## Reference

| Doc | Why |
|-----|-----|
| `ARCHITECTURE_CONCEPTS.md` | Stack / domain context |
| `CODING_PRINCIPLES.md` | Conventions for implementation |

---

## Related backlog (`memory/TODO.md`)

Continued or new functionality related to **[TopicX]** may also live in `memory/TODO.md` (Active Backlog, domain concepts, or **Potential new functionality**). This WIP owns scoped implementation; TODO owns cross-cutting and unscoped ideas. Search TODO by topic when grooming — avoid brittle links to specific headings or lines.

---

## History

*(Superseded drafts, investigation logs, retrospectives — not pickup-critical.)*

---

*Do not treat this file as ground truth for production behavior until Yield is complete and the WIP is archived.*
