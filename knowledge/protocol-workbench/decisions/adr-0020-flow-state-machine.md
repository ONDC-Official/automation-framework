---
id: adr-0020
date: 2026-06-26
grill-ref: deep-dive — mock-playground flow engine
status: accepted
changes: [flow-state-machine, mock-playground-service, flow-execution, flow-usecase]
---

# Seed mock-playground flow state machine

## Decision
Captured the engine: transaction status (AVAILABLE/WORKING/SUSPENDED), 7 per-step phase statuses, actionable set, the sequence→extras→missed resolver chain (stateless replay, no persistent pointer), missed classification, MORE_SEQUENCE dynamic injection, the 3 job types, and form types (HTML_FORM/DYNAMIC_FORM/HTML_FORM_MULTI).

## Assumptions & perception
- Source: Explore over mock-playground src/service/flows/* + decision-flows.md (file:line). High confidence.

## KB effect
- new frame flow-state-machine; mock-playground-service + flow-execution enriched (resolver chain, jobs, phases).
- triples: status/phase/resolver/jobs.
