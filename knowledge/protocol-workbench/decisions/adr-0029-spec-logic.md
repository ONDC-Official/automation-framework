---
id: adr-0029
date: 2026-06-26
grill-ref: grill Q2 — what "logic" means among the key authored artifacts
status: accepted
changes: [spec-logic, automation-specifications, flow-state-machine, author-new-domain-spec]
---

# Define spec "logic" as the journey-evolution core

## Decision
Owner clarified "logic" (a key authored artifact alongside flow/examples/L1) is the holistic runtime+config that governs how a journey evolves as the transaction stage increases — a validation subset repeating/accumulating per stage. It comprises four carried elements: requirement (meet-requirements JS), generation (generator JS), validation (validate JS), and L1 validation (the core). Flow = the possible journey (illustrated/operational); examples = illustrative branches (currently ~1, may grow to all); save-data + reuse = mock "session fullness" (a subset must be defaulted commonly in production).

## Assumptions & perception
- Owner interview. Ties the mock-runner per-step JS trio (requirement/generation/validation) + L1 + flow + examples + save-data into one concept.

## KB effect
- new frame spec-logic; automation-specifications + flow-state-machine + author-new-domain-spec cross-linked; triples.
