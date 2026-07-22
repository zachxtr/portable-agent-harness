# <Service Name> — <One-line purpose>

## Overview

<What it does, who uses it, what it depends on. One short paragraph.>

**How to read this doc:** Architecture and responsibilities here. Config, tuning, and contracts → **Documentation map** at the end.

---

## Architecture

```
<Entry → main parts → output>

Keep it conceptual. No class names, counts, or env defaults.
```

---

## <Main area> *(rename or duplicate as needed)*

<One paragraph per major part of the system.>

| Role / component | Responsibility |
|------------------|----------------|
| `<name>` | `<what it owns>` |

**Design rules:** <Bullets only if there are non-obvious constraints worth preserving.>

---

## Project layout

```
<top-level folders and what they are for>
```

---

## API

<Route prefix, health checks. Group endpoints or point to the controller module.>

---

## Configuration

<Service-level env vars only. Everything else → documentation map.>

---

## Local development

```bash
<how to run>
```

<How to smoke-test.>

---

## Documentation map

| If you need… | Look here |
|--------------|-----------|
| Architecture (this doc) | `<this README>` |
| Config / tuning | `<path>` |
| Implementation | `<path>` |
| Infra / env | `<path>` |

---
