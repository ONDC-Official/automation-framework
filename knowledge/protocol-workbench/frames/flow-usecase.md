---
id: flow-usecase
kind: class
isa: concept
confidence: high
source: repo config flows/, mock-playground flow types, config-service
changed-by: adr-0004
---

# Flow & use-case

A **use-case** is a domain scenario (e.g. PERSONAL LOAN, retail order). A **flow** is an ordered sequence of protocol actions realizing part of a use-case, used to drive a test.

## Slots
- flow-def: sequence (linear DAG of SequenceSteps) + optional extraSequence (parallel/unsolicited steps)
- step: action + owner (BAP/BPP) + type (API / HTML_FORM / DYNAMIC_FORM) + stackability + optional inputs + pair action + manual flag
- defined-in: automation-specifications config/flows/ → served by config-service → executed by mock-playground-service (mock-runner config)
- mock-runner-config key: `${domain}::${version}::${flowId}::${usecaseId}` (or PLAYGROUND_${sessionId} for playground)
- step-status: AVAILABLE | WORKING | SUSPENDED (per transaction); extras have per-step status

## Versioning (adr-0016)
- Flows are NOT versioned. Use-cases are generally not versioned either — EXCEPT some domains have been split into a versioned use-case (then the unit is domain+usecase+version). See [[domain-version]].

## Relations
- part-of → [[domain-version]]
- executed-by → [[mock-playground-service]] (script [[flow-execution]])
- validated-by → [[report-service]] (sequence + per-action)

## Open questions
- RESOLVED (adr-0057): usecaseId 'PLAYGROUND-FLOW' is special-cased in config-cache.ts — it reads the runner config from the WORKBENCH cache (cache0) at key `PLAYGROUND_<sessionId>`, NOT from config-service (cache1). So playground flows are session-runtime configs, not db-backed.
