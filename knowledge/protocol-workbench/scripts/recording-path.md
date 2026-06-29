---
id: recording-path
kind: script
confidence: high
source: repo recorder-service (grpc_audit, cache, side_effects, async) + db routes
changed-by: adr-0005
---

# Recording path (audit → cache + DB)

How a protocol exchange is captured and persisted. Lets QA/devs verify "did my call land".

## Entry conditions
- api-service handled an action; network-observability plugin emits an audit event

## Roles
- api-service (NO plugin), recorder-service, Redis, db-service, Network-Observability (prod)

## Scenes (ordered)
1. Emit — api-service NO plugin calls recorder gRPC `LogEvent` (:8089) with audit event (request/response + additionalData).
2. Sync cache — recorder updateTransactionAtomically: Redis key `transaction_id::subscriber_url`, append API entry to apiList, dedup messageIds, WATCH/EXEC (8 retries). NOT_FOUND if key absent.
3. Flow status — set FLOW_STATUS_<key> (TTL 5h) + EXTRA_FLOW_STATUS_<key>::action if txn cache exists.
4. Async push (best-effort) — enqueue: (a) sendLogsToNO → POST NO /v1/api/push-txn-logs (skip if RECORDER_SKIP_NO_PUSH); (b) savePayloadToDB → check/create session (sha256 fallback id) then POST db /api/sessions/payload (skip if RECORDER_SKIP_DB_SAVE).
5. Form — POST recorder /html-form appends FORM entry to txn cache (same atomic pattern).

## Results
- live transaction state in Redis; durable payloads + sessions in MongoDB (via db-service).

## Verify
- `redis-cli GET "txnid::suburl"` → apiList JSON.
- `GET db:5001/payload/transaction/:txnId` (x-api-key) → persisted payload.
- `GET db:5001/api/sessions/:sessionId` → SessionDetails.

## Edge points
- Redis down ⇒ LogEvent gRPC error. db down ⇒ async save fails silently, cache still ok.
