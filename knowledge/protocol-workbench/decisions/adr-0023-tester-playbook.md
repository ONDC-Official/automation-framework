---
id: adr-0023
date: 2026-06-26
grill-ref: deliverable — consolidated tester break-points playbook
status: accepted
changes: [tester-playbook]
---

# Build consolidated tester playbook

## Decision
Synthesized every edge/failure point + coverage gap across all components into one QA-oriented script: coverage model, FAQ debugging order, break-points by area, verify-writes cheat sheet, and a negative-test gap list. Highlights the difficulty-knob and w2w blind-spot caveats so "passing" is interpreted correctly.

## Assumptions & perception
- Pure synthesis of existing KB frames/FAQ (no new code facts). High confidence; report-service section flagged volatile (under redesign).

## KB effect
- new script tester-playbook linking all relevant frames/scripts.
