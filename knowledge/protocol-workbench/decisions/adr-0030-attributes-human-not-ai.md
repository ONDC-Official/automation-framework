---
id: adr-0030
date: 2026-06-26
grill-ref: owner correction — retract "AI-derived" attributes; add gap/seed
status: accepted
supersedes: adr-0028
changes: [automation-specifications, author-new-domain-spec, references]
---

# Attributes/tags/enums are human schematic input (not AI, not ground truth)

## Question / context
adr-0028 recorded attributes as "AI-derived, human-reviewed." Owner retracted this.

## Decision
- Remove all "AI-generated/AI-derived" framing. Attributes, tags, enums + definitions are HUMAN input — schematic meaning (semantic intent), NOT ground truth; well-reviewed / cross-referenced in many cases.
- Gap/seed: where the base (Beckn-derived) schema lacks info, a human SEED exists in most cases to fill it — a key place this authored semantic layer (and this KB) adds value.

## Assumptions & perception
- Owner correction (interview). Supersedes adr-0028's attribute-origin claim only; the rest of adr-0028 (authoring SOP, openapi←Beckn, key artifacts) stands.

## KB effect
- automation-specifications + author-new-domain-spec: attributes/tags/enums = human schematic, not ground truth; gap/seed slot added.
- references/spec-authoring-sop: header corrected (AI claim retracted).
- triples updated.
