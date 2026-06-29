---
id: w2w-testing
kind: concept
isa: concept
asof: 2026-06-26
confidence: high
source: interview 2026-06-26 + docs/FAQ.md
changed-by: adr-0019
---

# Workbench-to-workbench (w2w) testing & its blind spot

W2W = both sides of a protocol flow are simulated by the workbench (one instance acting as both, or workbench-instance-A ↔ workbench-instance-B). Key concept for QA/testers and for setting correct expectations.

## What w2w DOES do (not bypassed)
- Can run against the ACTUAL registry and verify the counterparty's signature from the other side (signing is real, not skipped — corrects earlier assumption). See [[signing-security]].
- Validates schema + L1 + context normally.

## The blind spot (why w2w "won't throw errors")
- Both workbench sides share a **base common assumption** that is NOT coded as an explicit validation. Because both conform to the same implicit convention, w2w passes — but a real NP may violate that assumption and it would NOT be caught.
- Consequence: w2w cannot, by itself, surface real NP-integration bugs. The validation gap is implicit-assumption divergence, not relaxed crypto.

## Mitigation (current) + future scope
- Current: also do NP-facing testing and negative / "monkey" testing so real-NP divergences and bypasses are exercised.
- Future scope (desired, adr-0024): a technical solution to convert these implicit assumptions into explicit validations. Approach: owner first builds system knowledge (this KB), then works with agents and/or devs (as bandwidth allows) to build the fix.

## Relations
- testing-mode-of → [[validation-layers]] / [[flow-execution]]
- relevant-to → [[persona]] (QA/end-users)
- contrasts-with → NP-facing testing

## Open questions
- Concrete examples of the implicit assumptions most likely to bite (catalogue for testers)? → owner: Shreyansh
- Shape of the future explicit-validation solution → owner: Shreyansh
