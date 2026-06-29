# Runtime Verification — Protocol Workbench (2026-06-28)

Live stack: pre-existing `docker compose` deployment, all 18 containers **Up 40h, 0 restarts**, single domain api-service `api-ondcfis12-2-0-3` (**ONDC:FIS12 / 2.0.3**, internal port 7039) behind nginx api-gateway :3032. Reporting-enabled domain. Grill run against the running instance (no rebuild needed).

## Phase 1 — boot observations
- **All KB host-port claims CONFIRMED** (ui 3035, ui-backend 3034, backoffice 5100/5200, mock 3031, report 3000, form 3300, db 5001, config 5556, user-mgmt 8082, jaeger 16686, recorder 8090/8089, pramaan 3005/3006, api-gateway 3032).
- Net-new: **`gamification-db`** (postgres:latest, host 5433) running, not in the KB infra list.
- **No `registry-service` container** → confirms external placeholder; api uses `IN_HOUSE_REGISTRY=http://registry-service:8080/v2.0/`.
- Single bridge net `automation-framework_automation-network`. Redis client census: **11 conns db=0, 1 conn db=1**.
- api-service exposes no host port; reachable only via gateway `/api-service/ONDC:FIS12/2.0.3/...` → `:7039`.

## Phase 2 — 10 paths × status

| # | Path | Status | Evidence (terse) |
|---|------|--------|------------------|
| 1 | Schema validation (test) | **CONFIRMED** | `standaloneValidator` = schema+L1 only (adapter.yaml); ACK ⇒ **HTTP 200** `{ack:ACK}`; L1 fail ⇒ **also 200** `{ack:NACK, error.code:"Bad Request"+JSONPath}`; malformed ctx (nil msgid) ⇒ **500**. Resolves 200-vs-202 ⇒ **200**. L1 gated by `protocol_validation` header. |
| 2 | Transaction chain | **CONFIRMED** | adapter.yaml + boot log "Processor steps initialized [ondcWorkbenchReceiver addRoute validateSchema validateOndcPayload ondcWorkbenchValidateContext validateSign validateOndcCallSave]". **Historical full flow** persisted in db (SEARCH→ON_SEARCH→SELECT→ON_SELECT, all HTTP 200) ⇒ chain incl. validateSign passed e2e. Out-of-seq live: `/seller/on_search` unknown txn ⇒ **412**. (validateSign verifying a fresh inbound sig not separately forced.) |
| 3 | Router fallback (500) | **REFUTED** | No router 500: `ondcWorkbenchReceiver` guards first. `/mock/search` no target ⇒ **400** "bpp_uri … subscriber_url query param … missing"; `/seller/on_search` ⇒ **412**. Routing target = `context.bap_uri/bpp_uri` + `?subscriber_url=` fallback (payloadutils.go). Cookies set OUTBOUND, not by external caller. |
| 4 | Mock-runner + Redis | **CONFIRMED (mostly) + SKEW found** | Jobs GENERATE_PAYLOAD_JOB/SEND_TO_API_SERVICE_JOB/API_SERVICE_FORM_REQUEST_JOB; dual cache DB0/DB1. Live: `/flows/new` ⇒ "Expectation created … action: search". Keys live: session=bare `sessionId` (48h), `MOCK_DATA::{txn}::{sub}`, DB1 `{d}::{v}::{flow}::{usecase}`. **ui-backend↔mock submodule skew** breaks UI trigger (404). FLOW_STATUS 5h = pending. |
| 5 | Recorder + DB | **CONFIRMED (live)** | Signed caller hop (txn-sig-2) ⇒ "audit event dispatched successfully"; Redis `txn-sig-2::<sub_url>` = TransactionCache {apiList, messageIds[dedup], subscriberType:BPP, ttl} (~300s TTL); db record action **SEARCH** (UPPERCASED), http 200, reqHeader stringified `{}`. FLOW_STATUS 5h only on receiver/full-flow hop (pending). All 115 persisted reqHeaders are `{}` (recorder doesn't persist inbound Authorization). |
| 6 | Signing | **CONFIRMED (live)** | Captured real `Authorization: Signature keyId="dev.bap.example\|27baa06d…\|ed25519",algorithm="ed25519",created/expires (300s),headers="(created) (expires) digest",signature="EFCq…"`; api-service "Signature generated" matches. keyId = sub_id\|ukid\|ed25519, Ed25519 ✓. BLAKE2b-512 digest stays code-confirmed. |
| 7 | Reporting | **CONFIRMED (enabled half)** | `/ui/reporting FIS12 2.0.3` ⇒ `{data:true}`. report-service ships per-action validators `/app/dist/validations/{D}/{V}/{Action}.js`; PRAMAAN_URL/analyticsAPI/NO_URL set. Non-enabled→Pramaan delegation + callback = pending. |
| 8 | Config-service | **CONFIRMED** | `/ui/senario`, `/ui/flow`, `/api-service/supportedActions` (state machine null→search→on_search→…), `/ui/reporting` all 200, mirror pushed-to-db. config-service writes **no** Redis (in-memory); DB1 cache owned by mock-playground. |
| 9 | Validation-compiler ↔ plugin | **CONFIRMED** | ondc-validator (ondcvalidator.go:49) → `validationpkg.PerformL1validations`. Live L1 error: `REQUIRED_PAYMENT_COLLECTED_BY` + JSONPath `$.message.intent.payment.collected_by`; x-validations regexes printed (TTL `^P(?=\d|T\d)…`). |
| 10 | Session difficulty | **CONFIRMED (live)** | `SessionDifficulty` = **10 knobs** (KB had 7; +encryptionValidation, useCare, useTunnelForFIS). Full cookie set captured live on a forwarded request (header_validation/protocol_validation/use_gzip/encryption_validation/use_care/use_tunnel_for_fis + request_owner/mock_url/ttl_seconds/custom-response-body). `protocol_validation`→L1 gate confirmed live. ui-backend(TS) vs Go default divergence noted. |

## ACK/NACK status codes (test path, live)
- ACK ⇒ `200 {"message":{"ack":{"status":"ACK"}}}`
- L1/schema NACK (well-formed ctx) ⇒ `200 {"message":{"ack":{"status":"NACK"}},"error":{"code":"Bad Request","message":"#### **CODE** … JSONPath"}}`
- Malformed ctx (nil message_id) ⇒ `500 "Internal server error, MessageID: %!s(<nil>)"`
- Routing/state NACKs: `/mock/` no target ⇒ 400; `/seller/` unknown txn ⇒ 412.

## Redis keyspace (live)
- DB0: bare `sessionId` (48h, holds sessionDifficulty), `MOCK_DATA::{txn}::{subscriberUrl}`, `consoleLogs:{sessionId}`, subscriber-url keys. (txn:: / FLOW_STATUS_ / EXTRA_FLOW_STATUS_ absent this run — TTL-expired; no completed flow.)
- DB1 (config cache, mock-playground): `ONDC:FIS12::2.0.3::Personal_Loan_Offline::PERSONAL LOAN`, `…::Gold_Loan_Offline::GOLD LOAN` (TTL -1).

## Self-contained signing capture (paths 5/6/10, no flow / no re-pin)
Pointed the `mockTxnCaller` `?subscriber_url=` at a host listener (:9099) + `session_id`+`flow_id`; the signer signed and forwarded a valid search. This captured the live Authorization header, the difficulty cookie set, and drove a successful recorder LogEvent (txn `txn-sig-2`) — closing paths 5/6/10 without touching the broken UI trigger.

## Misbehaving services
- **ui-backend ↔ mock-playground submodule skew**: ui-backend POSTs `/mock/{d}/{v}/trigger/api-service/search` → mock 404 → ui-backend 500. UI "trigger search" is broken in this stack. Blocked the full end-to-end flow ⇒ paths 2(sign)/5(write)/6 left runtime-pending.

## Frames / ADRs changed
- Frames: schema-validation, validation-layers, onix-adapter, config-service, session-difficulty, mock-playground-service, recorder-service; INDEX (router note + open-question 7).
- ADRs added: **0037** (test-path 200/NACK), **0038** (router receiver-guard, supersedes 0025 router claim), **0039** (config-service runtime), **0040** (reporting flag), **0041** (validation-compiler runtime), **0042** (session-difficulty 10 knobs), **0043** (txn chain + signing), **0044** (mock-runner runtime + submodule skew), **0045** (recorder gRPC runtime), **0048** (live signing + recorder write + difficulty cookies). (0046/0047 are owner-added: onix-server-core, infra/gamification-db+skew.)
- triples.md: +~30 atomic facts.
