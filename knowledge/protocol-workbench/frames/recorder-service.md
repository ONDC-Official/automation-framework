---
id: recorder-service
kind: instance
isa: service
part-of: workbench
confidence: high
source: repo automation-recorder-service/ (Go: main.go, async.go, cache.go, grpc_audit.go, side_effects.go, http_form.go, proto/)
changed-by: adr-0005
---

# recorder-service (audit + transaction recorder)

Go service that records protocol audit events emitted by the api-service network-observability plugin, writes transaction state to Redis (sync) and persists payloads to [[db-service]] + pushes logs to Network Observability (async).

## Slots
- ports: gRPC 8089, HTTP 8090, GET /health
- grpc-api: `beckn.audit.v1.AuditService/LogEvent` (proto/audit.proto); takes BytesValue audit event
- audit-event-fields: requestBody, responseBody, additionalData {payload_id, transaction_id, subscriber_url, action, timestamp, ttl_seconds, cache_ttl_seconds, status_code, is_mock, session_id, message_id, api_name}
- sync-write: Redis key `transaction_id::subscriber_url` (trimmed) → TransactionCache JSON (apiList, latestAction, latestTimestamp, messageIds[dedup]); atomic WATCH/EXEC, 8 retries; NOT_FOUND if key missing
- async-jobs: queue (size 1000, 2 workers, drop-on-full), 15s/job — (a) push logs to Network-Observability `/v1/api/push-txn-logs`; (b) save payload to db-service
- http-form: POST /html-form appends FORM entry to txn cache atomically (transaction_id, subscriber_url, form_action_id, [submissionId], [error])
- flow-status-keys: sets `FLOW_STATUS_<key>` (TTL 5h) and `EXTRA_FLOW_STATUS_<key>::action` if txn cache exists. **Confirmed live (adr-0049):** `FLOW_STATUS_<txn>::…/buyer` & `…/seller` both present with ~16593s (≈5h) TTL.
- feature-flags: RECORDER_SKIP_NO_PUSH, RECORDER_SKIP_DB_SAVE, RECORDER_CACHE_TTL_SECONDS_DEFAULT, RECORDER_API_TTL_SECONDS_DEFAULT (0=no expiry per code).
- ⚠ **txn-cache TTL bug (adr-0049):** the txn cache `transaction_id::subscriber_url` (the apiList the UI's `current-status` + the mock `/forms/…` endpoint read) is written with `RECORDER_CACHE_TTL_SECONDS_DEFAULT`. Local `docker-env/recorder-service.env` pinned it (and `RECORDER_API_TTL_SECONDS_DEFAULT`) to **300s** ⇒ after ~5 min the txn cache expires (while FLOW_STATUS 5h + MOCK_DATA -1 survive), so `getFlowStatusController`/`getFormController` throw "No transaction data found for transaction ID … and subscriber URL …" ⇒ HTTP 500, UI flow dies / HTML-form modal renders empty. **Fix:** raise both to 18000 (5h, match FLOW_STATUS) or 0. Restart recorder (env-only, no rebuild). Owner ran an interactive Gold-Loan flow that broke this way.
- session-fallback-id: sha256(transaction_id::subscriber_url) when creating session in db

## DB payload shape (POST db-service /api/sessions/payload)
messageId, transactionId, payloadId, action(UPPERCASED), bppId, bapId, reqHeader(JSON string), jsonRequest, jsonResponse, httpStatus, flowId, sessionDetails{sessionId}

## Relations
- receives-audit-from → [[api-service]] (network-observability plugin)
- writes-cache → Redis (DB 0, same keyspace as [[mock-playground-service]])
- persists-to → [[db-service]] (async, best-effort)
- pushes-logs-to → Network-Observability (prod analytics-api; see [[observability]]) → probable feed into [[udp]] (network-wide real-time analytics)

## Runtime-observed (adr-0045, live FIS12 2.0.3)
- api-service network-observability plugin DOES call the recorder gRPC `LogEvent` live: a direct seller/mock POST (no session) triggered "network-observability: audit dispatch failed: rpc error: code = InvalidArgument desc = subscriber_url is required in additionalData" in the api-service log — i.e. the gRPC endpoint is reachable and validates `additionalData.subscriber_url` (rejects with InvalidArgument when absent). Confirms the api-service→recorder gRPC link + the NO middleware fires per request (non-blocking; the main NACK still returned).
- **Full happy-path NOW confirmed (adr-0048):** a signed mockTxnCaller hop (txn `txn-sig-2`) drove a successful synchronous LogEvent. Observed:
  - Redis DB0 txn cache key = `txn-sig-2::http://host.docker.internal:9099` (`transaction_id::subscriber_url`) → `{apiList:[{action:search, entryType:API, messageId, payloadId, realTimestamp, response:{ack:ACK}, timestamp, ttl:30}], flowId, latestAction:search, latestTimestamp, messageIds:["msg-sig-2"] (dedup array), referenceData:{}, sessionId, subscriberType:BPP}`. Key had a **~300s TTL** in this run (env sets a cache TTL, not the 0=no-expiry default).
  - Async db save (db-service `/payload/transaction/txn-sig-2`): `action:"SEARCH"` (**UPPERCASED** ✓), httpStatus 200, `reqHeader:"{}"` (**stringified JSON** ✓ — empty because the curl-origin inbound carried no headers; the Authorization is on the OUTBOUND forward, which is not the recorded inbound reqHeader).
  - `FLOW_STATUS_`/`EXTRA_FLOW_STATUS_` (5h) NOT written on a caller-only hop — those appear on the receiver / full-flow path; runtime-pending there.

## Overrides / edge points (tester)
- Redis down ⇒ sync LogEvent fails (gRPC error). recorder down ⇒ nothing recorded, txn cache goes stale.
- db-service down ⇒ savePayloadToDB fails silently (async); cache still updated; backoffice can't query history.
- verify writes: `redis-cli GET "txnid::suburl"`; `GET db:5001/payload/transaction/:txnId` (x-api-key).
- duplicate message_id ⇒ deduped in messageIds[].

## Open questions
- RESOLVED (adr-0057): NO push is env-controlled, not strictly prod-only — sendLogsToNO fires when NOURL is set AND NOEnabledIn[env] true (skipped if RECORDER_SKIP_NO_PUSH or NOURL empty). Same mechanism local + prod; locally it's exercised if configured (adr-0048 saw "audit event dispatched successfully").
