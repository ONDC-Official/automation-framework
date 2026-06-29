---
id: adr-0026
date: 2026-06-26
grill-ref: deep-dive — report-service (Pramaan as legacy plug, code as truth)
status: accepted
supersedes: adr-0010
changes: [report-service, report-pramaan, generate-report]
---

# Deep-dive report-service; Pramaan = legacy plug

## Decision
Documented report-service current code as truth (raised confidence high): /generate-report + /callback/:testId; ENABLED_DOMAINS + ENABLED_USECASES + domainVersionKey (FIS13 special); internal pipeline (ReportingConfig.yaml → validateActionSequence 1s-dedup/lookahead/early-termination → checkPayload → shared contextValidator + dynamically-loaded per-domain/version validators); flowResults=valid_flow PASS/FAIL; FLOW_ID_MAP; legacy Pramaan delegation + mochawesome callback parsing (suiteHasFailure, reverse-map); GridFS + analytics write-back.

## Assumptions & perception
- Owner: deep-dive reporting, treat Pramaan as a legacy plug (functional, NOT deprecated), reporting redesign planned (skip future specifics). Supersedes adr-0010's "keep abstract/volatile" stance for report-service/report-pramaan — now documented in full as current truth, with a light "redesign planned" note.

## KB effect
- report-service: confidence high; full pipeline, branch logic, validators, FLOW_ID_MAP, callback, edge points.
- report-pramaan: legacy-plug status; callback contract.
