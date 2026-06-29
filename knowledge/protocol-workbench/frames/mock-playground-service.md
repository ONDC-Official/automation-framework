---
id: mock-playground-service
kind: instance
isa: service
part-of: workbench
confidence: high
source: repo automation-mock-playground-service/ (src, CLAUDE.md, docs/decision-flows.md)
changed-by: adr-0004
---

# mock-playground-service (counterparty simulator)

TypeScript/Express service that **simulates the counterparty NP** (buyer or seller) and drives ONDC flows step by step. Host 3031 → container 3000, base path `/mock/playground`. Container/service name `playground-mock-service`. Powered by `@ondc/automation-mock-runner` (generator+validator functions, base64-encoded JS, per step).

## Slots
- np-role: simulates BAP or BPP (npType in session)
- state-model: stateless handlers + cache-materialized flow state; flow state reconstructed per-read by replaying apiList through FlowMapBuilder (no persistent step pointer)
- cache: Redis DB 0 = workbench (WorkbenchCacheService: sessions, transactions, flow status, business data MOCK_DATA::); DB 1 = MockRunner config cache + in-memory MockRunner instances (5-min TTL). Confirmed adr-0025.
- queue: in-memory (dev) or RabbitMQ (prod) for async payload generation + forwarding
- flow-structure: `sequence` (linear DAG of actions) + `extraSequence` (parallel/unsolicited actions, e.g. unsolicited on_status). Full status/phase machine + resolver chain: [[flow-state-machine]].
- form-types: HTML_FORM (third-party URL, fetched+sanitized: rejects iframe/embed/event-handlers/javascript:/multiple-forms), DYNAMIC_FORM (mock-generated), HTML_FORM_MULTI; forms allowed only in sequence, not extraSequence; submit generates submission_id → /flows/proceed
- DYNAMIC_FORM (eKYC) completion: routes through the api-service `/callback` (adr-0052) + a mock idempotency guard (adr-0051). **eKYC RESOLVED / working end-to-end (owner-confirmed, adr-0055).**
- match-key: incoming requests matched to expected step on triplet `action::message_id::timestamp`
- jobs: GENERATE_PAYLOAD_JOB, SEND_TO_API_SERVICE_JOB, API_SERVICE_FORM_REQUEST_JOB (see [[flow-state-machine]])
- recent (adr-0058): a **manual dispatcher** was added (commit f7514ff "add manual dispatcher" + frontend manual-dynamic-form-handler.tsx) alongside a queue race-condition fix — manual step dispatch path. (slot flagged; expand on demand via [[kb-sync-on-diff]].)

## Key endpoints (under /mock/playground)
- POST /flows/new — start a flow (session_id, flow_id, [transaction_id], [inputs])
- POST /flows/proceed — advance (transaction_id, session_id, [inputs], [trigger_extra])
- GET /flows/current-status
- POST /manual/:action — receive a payload forwarded by api-service (counterparty response), validate+save, advance
- GET /forms/:domain/:formId ; POST /forms/:domain/:formId/submit
- DELETE /backdoor/clear-flows?domain=&version=&flowId= — clear config cache to reload flows mid-test

## Relations
- forwards-to → [[api-service]] (SEND_TO_API_SERVICE_JOB)
- loads-flows-from → [[config-service]] (on cache miss; per domain/version/flowId/usecaseId)
- runtime-defined-by → script [[flow-execution]]

## Runtime-observed (adr-0044, live FIS12 2.0.3)
- `POST /mock/playground/flows/new {session_id, flow_id}` ⇒ 200 `{success:true,"Mock Service is now listening for the next action"}`; logs "Expectation created for sessionId..., flowId..., action: search". **Expectation-driven**: it sets the next-action expectation and waits — does NOT persist a transaction to the session yet (session `transactionIds` stays `[]` until a payload actually flows). `/flows/proceed` with an empty/unknown transaction_id ⇒ 500 "No transaction data found".
- session key in Redis DB0 = bare `sessionId` → JSON {transactionIds[], flowMap{}, npType, domain, version, subscriberUrl, env, usecaseId, sessionDifficulty{...}} (TTL 48h). Live difficulty in a UI-created session: `useGateway:false, stopAfterFirstNack:true` (ui-backend TS defaults — differ from the Go plugin `defaultDifficulty`; see [[session-difficulty]]).
- business-data key confirmed: `MOCK_DATA::{transactionId}::{subscriberUrl}` (DB0).

## ⚠ Submodule skew (live stack, adr-0044)
- The running **ui-backend (automation-frontend) is on a STALE version vs this mock**: its `/flow/trigger/:action` controller calls `buildMockBaseURL("trigger/api-service/${action}")` → `/mock/{d}/{v}/trigger/api-service/search`, a route this rewritten mock NO LONGER serves ⇒ **404 → ui-backend 500**. So the UI "trigger search" flow is BROKEN in this stack; the live mock initiates via `/flows/new` + `/manual/:action` (incoming) instead. → owner: Shreyansh (re-pin submodules).

## Overrides / edge points (tester)
- out-of-sequence: no matching step ⇒ warning logged, flow does NOT advance, no ACK. Fix: align flow def with api-service action names.
- config-service down ⇒ first generation for a (domain,version,flow) times out (no fallback). Pre-seed `PLAYGROUND_${sessionId}` in DB 0 for playground.
- generator failure ⇒ flow resets to AVAILABLE / can stick in WORKING; check base64 generator vs txnData fields (bapUri,bppUri,user_inputs).
- session/transaction not found ⇒ 500.
- form submit needs submission_id passed to /flows/proceed.

## Known issue (adr-0047, runtime)
- ui-backend ↔ mock-playground SUBMODULE SKEW: ui-backend POSTs `/mock/{d}/{v}/trigger/api-service/search` but the pinned mock build returns 404 ⇒ ui-backend 500. The UI "trigger search" path is broken in the verified stack; blocks full end-to-end flow runs.

## Open questions
- Exact RabbitMQ topology in prod vs in-memory in dev → owner: Shreyansh
