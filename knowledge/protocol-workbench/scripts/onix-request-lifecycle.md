---
id: onix-request-lifecycle
kind: script
confidence: high
source: repo api-service build-output + automation-beckn-onix server core; runtime-verified (adr-0046)
changed-by: adr-0046
---

# ONIX request lifecycle (one action end-to-end)

How a single protocol action flows through the generated [[api-service]], executed by the [[onix-server]] (std handler step engine). Deepest protocol-runtime trace for architects/devs. Runtime-verified (FIS12 2.0.3).

## Entry conditions
- api-service running for the domain+version; request hits a module path (mock/seller/buyer/test)

## Roles
- caller (UI/mock/NP), ONIX modules+plugins, Redis cache, registry, recorder-service, mock-service

## Scenes (ordered) — receiver path (Bap/BppTxnReceiver)
1. Receive — ondcWorkbenchReceiver: extract context (transaction_id, message_id, action, bap/bpp ids); validate action against state machine (transaction_properties.yaml); store txn in Redis (key transaction_id::subscriber_url); set cookies mock_url/subscriber_url.
2. Route — addRoute (router): resolve destination. Receiver resolves target from context (`bap_uri`/`bpp_uri` by role; caller role falls back to `?subscriber_url=`); the router's `$.cookies.*` are set OUTBOUND by an upstream workbench hop, not the external caller. Missing target ⇒ 400 from the receiver (not a router 500).
3. Schema — validateSchema: body vs ./schemas/ONDC_{DOMAIN}_{VERSION}_{action}.json.
4. L1 — validateOndcPayload: stateful rule validation (stateFullValidations:true) — enums, conditionals, predecessor/successor.
5. Context — ondcWorkbenchValidateContext: bap/bpp id match, message_id format, timestamp window.
6. Sign — validateSign: parse Authorization, lookup sender key via keyManager (registry), check created<now<expires, ed25519.Verify (see [[signing-security]]).
7. Save/audit — validateOndcCallSave: async gRPC to recorder-service (records request/response metadata; non-blocking).
8. Respond — HTTP is decoupled from ACK/NACK (see [[onix-server]]): ACK ⇒ 200 `{ack:ACK}`; schema/L1 NACK ⇒ **200** `{ack:NACK,error}`; sign ⇒ 401; bad-request/missing-target ⇒ 400; state-machine guard (unknown txn) ⇒ 412 "No active expectation found"; malformed ctx (nil message_id) ⇒ 500 panic. Forward to the next hop fires as a post-response hook (async) when ActAsProxy=false.

## Caller path (mockTxnCaller) variant
ondcWorkbenchReceiver → addRoute(mock_router → subscriber_url) → validateSchema → validateContext → SIGN (signer, outbound) → CallSave. Proxies to mock-service / subscriber.

## Async callback
- on_* callbacks arrive as NEW inbound requests on the opposite receiver module (seller↔buyer); no special async queue. Strict action sequencing enforced by the state machine.

## Results
- validated, signed, recorded protocol exchange; txn state in Redis; audit in recorder→db.

## Edge points
- standaloneValidator (test path): steps 1-2,6-7 absent — schema+L1 only, no state, no sign.
- recorder down ⇒ request still ACKs (async audit).
- clock skew ⇒ sign fail. registry unreachable ⇒ key lookup fail.
- same transaction_id to different subscriber_url ⇒ separate cache keys.
