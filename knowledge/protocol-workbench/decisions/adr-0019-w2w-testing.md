---
id: adr-0019
date: 2026-06-26
grill-ref: grill — w2w leniency / signing bypass hypothesis
status: accepted
changes: [w2w-testing, signing-security, validation-layers, persona]
---

# W2W testing: signing is real; blind spot is implicit assumptions

## Question / context
Hypothesized that workbench-to-workbench flows "don't throw errors" because signing/validation is relaxed. Owner corrected this.

## Decision
- W2W can run against the ACTUAL registry and verify the other side's signature — signing is NOT bypassed. W2W modes: one instance as both sides, or instance-A↔instance-B.
- The reason w2w rarely errors: both sides share a base common assumption that is NOT coded as an explicit validation; both conform, so it passes — but a real NP may violate it and it won't be caught.
- Mitigation today: NP-facing + negative/"monkey" testing. A technical solution to make those implicit assumptions explicit validations is future scope.

## Assumptions & perception
- Owner correction (interview): supersedes my "signing relaxed in w2w" guess. The gap is implicit-assumption divergence, not crypto leniency.

## KB effect
- new frame w2w-testing.
- signing-security: open Q resolved (w2w not a bypass).
- validation-layers: w2w blind-spot note.
- persona: QA pointer to w2w-testing.
- triples: w2w facts.
