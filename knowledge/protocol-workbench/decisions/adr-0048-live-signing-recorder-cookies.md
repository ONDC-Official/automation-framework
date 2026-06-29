---
id: adr-0048
date: 2026-06-28
grill-ref: RUNTIME-VERIFICATION-PROMPT paths 5/6/10 — self-contained signed mockTxnCaller hop to a capture listener
status: accepted
changes: [signing-security, recorder-service, session-difficulty, onix-adapter]
---

# Live signing + recorder write + difficulty-cookie propagation captured (no flow / no re-pin)

## Method
Pointed the mockTxnCaller `?subscriber_url=` at a host listener (:9099) and POSTed a valid FIS12 search (session_id+flow_id required). The signer signed and forwarded the request to the listener; the NO middleware audited to recorder. Captured the outbound headers + verified Redis/db.

## Decision (runtime-observed) — Paths 6, 5, 10 CONFIRMED live
- **Signing (6):** real `Authorization: Signature keyId="dev.bap.example|27baa06d-…|ed25519",algorithm="ed25519",created="1782634224",expires="1782634524",headers="(created) (expires) digest",signature="EFCq…XODDg=="`. keyId = subscriber_id|unique_key_id|ed25519; Ed25519; 300s created→expires window. api-service logged the matching "Signature generated". Caller pre-sign steps: Validating Transaction History → TTL validations (skipped for non-on_ actions) → Transaction Id Checks → sign → forward (ActAsProxy:true). BLAKE2b-512 digest stays code-confirmed.
- **Recorder+DB (5):** "network-observability: audit event dispatched successfully" (sync). Redis DB0 `txn-sig-2::http://host.docker.internal:9099` = TransactionCache {apiList[{action:search,…,response:{ack:ACK},ttl:30}], latestAction, messageIds:["msg-sig-2"] dedup, sessionId, subscriberType:BPP}, ~300s TTL. db-service record: action **SEARCH** (UPPERCASED), httpStatus 200, reqHeader stringified "{}". FLOW_STATUS_ 5h NOT on a caller-only hop (receiver/full-flow path → pending).
- **Difficulty cookies (10):** full set forwarded as cookies: header_validation, protocol_validation, use_gzip, encryption_validation, use_care, use_tunnel_for_fis + request_owner=buyer_np, ttl_seconds=30, mock_url=…/manual, forward_request=true, custom-response-body=<base64 ACK>, plus flow/session/transaction/subscriber ids.

## Also (Path 2 supporting)
- A historical full w2w flow persisted in db (txn f8f3cfdb): SEARCH→ON_SEARCH→SELECT→ON_SELECT, **all HTTP 200** ⇒ the 7-step receiver chain incl. validateSign passed end-to-end. Boot logs confirm chains: receiver "[ondcWorkbenchReceiver addRoute validateSchema validateOndcPayload ondcWorkbenchValidateContext validateSign validateOndcCallSave]", caller "[… validateSchema ondcWorkbenchValidateContext sign validateOndcCallSave]". (validateSign verifying a fresh inbound signature not separately forced.)

## KB effect
- signing-security / recorder-service / session-difficulty: Runtime-confirmed blocks added. Paths 5/6/10 upgraded to live-confirmed; report + INDEX OQ7 updated.
