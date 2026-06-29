---
id: run-flow-test
kind: script
confidence: high
source: repo automation-frontend (scenario/flow-testing pages, sessionService, flowController) + downstream
changed-by: adr-0008
---

# Run a flow test (Flow Testing Suite, UI)

End-to-end transaction test from the UI. Primary path for QA and NP developers.

## Entry conditions
- stack running; user knows domain, version, usecase, npType (BAP/BPP), their subscriberUrl, env

## Roles
- NP developer / QA, ui-frontend, ui-backend, config-service, mock-playground-service, api-service, recorder, db-service, report-service

## Scenes (ordered)
1. Session — /scenario form → POST ui-backend /sessions; ui-backend GET config-service /ui/flow (flows) → store session in Redis (48h) → return sessionId.
2. Open — redirect to /flow-testing?sessionId=&subscriberUrl=&role= ; RenderFlows fetches flows + steps.
3. Step — per action: edit payload → POST /flow/trigger/:action?session_id=... → mock-playground-service processes ([[flow-execution]]) ↔ api-service ([[validation-layers]]); recorder captures ([[recording-path]]).
4. Advance — POST /flow/proceed / GET /flow/current-state until flow complete.
5. Report — POST /flow/report → report-service ([[generate-report]]) → HTML report (PASS/FAIL per flow).

## Results
- a completed (or failed) flow run + a downloadable/viewable report; persisted session + payloads.

## Edge points
- session expiry (48h). flow def must match api-service action names (else out-of-sequence).
- new transaction_id for first step, reuse for rest; bap/bpp url must match session.
