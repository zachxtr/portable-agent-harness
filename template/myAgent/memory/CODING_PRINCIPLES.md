# {{PROJECT_NAME}} Coding Principles

A living reference of agreed conventions. Update as patterns are established. Each entry: **rule**, **rationale**, and a **concrete example** so the agent applies it consistently.

---

## How to use this file

1. Add sections as you and {{USER_WHAT_TO_CALL}} agree on patterns.
2. Prefer one topic per section with a clear heading.
3. Link to `ARCHITECTURE_CONCEPTS.md` for stack-wide decisions; keep this file for day-to-day coding rules.

---

## Example entry (replace with your rules)

### Naming — be explicit in public APIs

**Rule:** Public types and route payloads use names that match domain language, not internal abbreviations.

**Rationale:** Agents and new humans read names cold; clarity beats brevity.

**Example:** Prefer `AlertStatus` over `AS` in anything returned from an API.

---

*(Delete this example section when you add real principles.)*
