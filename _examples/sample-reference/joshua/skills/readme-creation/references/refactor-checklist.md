# Refactor checklist (readme-creation skill)

Use alongside `service-readme-template.md` when slimming an existing README.

## Assess

- [ ] Read current README end-to-end
- [ ] Grep for numbers, defaults, YAML keys, JSON snippets, `platform:`, env defaults
- [ ] List factual mismatches vs current behavior
- [ ] Identify where relocated detail should live (knob map, types, harness — **outside** the README)

## Plan (get approval)

- [ ] Target length band (large service: ~250–320 lines conceptual)
- [ ] Sections: keep / rewrite / cut / add
- [ ] Documentation map rows defined
- [ ] External docs updated in same change if detail moves out

## Execute

- [ ] Match structure in `service-readme-template.md`
- [ ] "How to read this doc" at top
- [ ] Documentation map at end
- [ ] Replace drift tables with role-based tables
- [ ] Pull optional sections from template only where needed; delete the rest

## Verify

- [ ] No tool counts, caps, thresholds, or schemas unless labeled example
- [ ] Documentation map answers every question the old README answered
- [ ] Relocated content not dropped
- [ ] Readable in ~15 minutes as system design

## Anti-patterns to remove

| Remove from README | Relocate to |
|--------------------|-------------|
| Platform key table duplicating knob map | Knob map doc |
| JSON / parser contracts | Phase service or types |
| Method-level pipeline steps | Types + phase modules |
| Per-skill tool counts | Skill config files |
| Filename token grammar | Implementation or ops doc |
| Env defaults beyond port/provider | env template + knob map |
