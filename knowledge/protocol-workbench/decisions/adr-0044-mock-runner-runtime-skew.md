---
id: adr-0044
date: 2026-06-28
grill-ref: RUNTIME-VERIFICATION-PROMPT path 4 (mock-runner + redis), live FIS12 2.0.3
status: accepted
changes: [mock-playground-service, flow-execution]
---

# Mock-runner runtime confirmed (expectation-driven, dual cache); ui-backend↔mock SUBMODULE SKEW breaks UI trigger

## Decision (runtime-observed)
- Job chain names CONFIRMED (mock CLAUDE.md + code): GENERATE_PAYLOAD_JOB, SEND_TO_API_SERVICE_JOB, API_SERVICE_FORM_REQUEST_JOB; in-memory queue (dev) / RabbitMQ (prod); dual Redis — DB0 WorkbenchCache (sessions/txn/business), DB1 ConfigCache (mock-runner config).
- Live: `POST /mock/playground/flows/new {session_id, flow_id:Personal_Loan_Offline}` ⇒ 200 "listening for the next action"; log "Expectation created ... action: search". Expectation-driven — does NOT persist a transaction until a payload flows (session transactionIds stays []). `/flows/proceed` empty txn ⇒ 500 "No transaction data found".
- Redis keys CONFIRMED live: session = bare `sessionId` (DB0, TTL 48h, holds sessionDifficulty); `MOCK_DATA::{txn}::{subscriberUrl}` (DB0); DB1 config cache `{domain}::{version}::{flowId}::{usecase}`. FLOW_STATUS_/EXTRA_FLOW_STATUS_/txn:: (5h TTL) NOT seen this run (no completed dispatch) — those are recorder-written (adr-0005), pending a completed flow.
- **SUBMODULE SKEW (net-new):** running ui-backend calls `trigger/api-service/${action}` → `/mock/{d}/{v}/trigger/api-service/search`, a route the rewritten mock no longer serves ⇒ 404 → ui-backend 500. The UI "trigger search" path is BROKEN in this stack; mock now uses /flows/new + /manual/:action (incoming receiver). Owner: re-pin submodules.

## Assumptions & perception
- Evidence: live curls to mock :3031 + redis-cli + docker logs + source (flowRoutes.ts, request-types.ts, flowController.ts:91). High confidence. Could not drive a clean BAP search end-to-end due to the skew → Paths 2(sign)/5(write)/6 left runtime-pending.

## KB effect
- mock-playground-service: Runtime-observed + Submodule-skew blocks added. flow-execution: needs a volatility note (UI trigger route stale). New Open question (re-pin ui-backend).
