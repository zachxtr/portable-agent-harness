# {{PROJECT_NAME}} Architecture Concepts

Canonical reference for what this system is, how it is structured, and cross-cutting decisions. Load when working across layers, onboarding, or scoping unfamiliar areas.

---

## Reading order

| Need | Doc |
|------|-----|
| Local dev setup | *(add path or section)* |
| Coding conventions | `CODING_PRINCIPLES.md` |
| Active tasks | `TODO.md` |
| Active CRY slice | matching `wip_*.md` |

---

## What this project does

*(One paragraph: purpose, users, core outcome.)*

---

## Software architecture layers

Describe your stack top to bottom. Example skeleton:

```
┌─────────────────────────────────────────────────────────────┐
│                     APPLICATION LAYER                       │
│  UI / UX                                                    │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      SERVICES LAYER                         │
│  APIs, workers, business logic                                │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                       CLIENTS LAYER                         │
│  Shared SDKs, DB clients, external integrations             │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                   INFRASTRUCTURE LAYER                      │
│  Databases, object storage, auth, cloud services            │
└─────────────────────────────────────────────────────────────┘
```

| Layer | Examples in this repo |
|-------|----------------------|
| Application | *(fill in)* |
| Services | *(fill in)* |
| Clients | *(fill in)* |
| Infrastructure | *(fill in)* |

---

## Core concepts & terminology

| Term | Meaning |
|------|---------|
| *(term)* | *(definition)* |

---

## Key decisions

*(ADR-style bullets: decision, why, date optional.)*

---

_Expand this file as the system grows. Keep the opening summary current._
