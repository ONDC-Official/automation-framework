---
id: adr-0028
date: 2026-06-26
grill-ref: grill (authoring spec) + owner-provided SOP doc
status: accepted
changes: [automation-specifications, author-new-domain-spec, references]
---

# Ingest spec-authoring SOP; correct authoring hypothesis

## Question / context
How is a new domain spec authored? Owner provided an old SOP doc and key framing.

## Decision
Registered the doc as reference spec-authoring-sop (status: ingested) and folded it into a new script author-new-domain-spec + automation-specifications authoring slots. Corrected my Q1 hypothesis:
- openapi.yaml is DERIVED from the base Beckn schema (not authored from ONDC published spec per domain).
- attributes + definitions are AI-derived, human-reviewed in some cases (not hand-authored).
- the key human-authored, well-tested artifacts are flow, examples, logic, L1 validations.
- method = business spec (requirements/statutory/roles) → technical spec (API↔flow mapping, BAP/BPP imperative, unsolicited APIs, role+parameter+Tag mapping) → encode enums/tags/examples/workflows in YAML.

## Assumptions & perception
- Source: owner doc (ref:spec-authoring-sop) + interview. Doc is older; treat the methodology as durable, tooling specifics (AI derivation) as open.

## KB effect
- new script author-new-domain-spec; automation-specifications authoring section; references.md entry; triples.
