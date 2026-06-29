---
id: adr-0004
date: 2026-06-26
grill-ref: repo exploration — mock-playground flow execution
status: accepted
changes: [mock-playground-service, flow-usecase, transaction-session, flow-execution]
---

# Seed flow execution (counterparty simulation)

## Question / context
How does the mock simulate the counterparty and advance a flow step by step?

## Decision
Captured: mock-playground-service role, MockRunner generator/validator model, cache-materialized flow state (replay apiList), sequence vs extraSequence, form types, the /flows + /manual + backdoor endpoints, and the flow/use-case + transaction/session identity model.

## Assumptions & perception
- Source: automation-mock-playground-service src + CLAUDE.md + docs/decision-flows.md (code-grounded).
- Flow state has no persistent step pointer — reconstructed per read (notable design fact).

## KB effect
- frame mock-playground-service, flow-usecase, transaction-session; script flow-execution.
