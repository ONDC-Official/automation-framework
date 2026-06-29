---
id: adr-0038
date: 2026-06-28
grill-ref: RUNTIME-VERIFICATION-PROMPT path 3 (router fallback), live FIS12 2.0.3 + workbench-main source
status: accepted
supersedes: adr-0025
changes: [onix-adapter, onix-request-lifecycle]
---

# Router "no-fallback ⇒ 500" is shadowed by the receiver: cookieless call ⇒ 400/412, not 500

## Question / context
KB (adr-0025) claimed a `/mock/` or `/seller/` request without the `mock_url`/`subscriber_url` cookie returns 500 (router has no fallback). Verify live.

## Decision (runtime-observed) — REFUTED at system level
- `ondcWorkbenchReceiver` runs BEFORE `addRoute` (router) and resolves the forward target from CONTEXT, not the cookie: Receiver-BAP→`context.bap_uri`, Receiver-BPP→`context.bpp_uri`, Caller-BAP→`context.bpp_uri` then `?subscriber_url=` query-param fallback, Caller-BPP→`context.bap_uri` (payloadutils.go:73-113). Missing ⇒ BadRequest NACK from the receiver step.
- Live (direct curl, no session): `POST /mock/search` (no bpp_uri/subscriber_url) ⇒ **HTTP 400** `{"ack":NACK,"error.code":"400","message":"bpp_uri is missing in context and subscriber_url query param is also missing"}`. `POST /seller/on_search` (bap_uri present) ⇒ **HTTP 412** "No active expectation found ... as a seller_np" (state-machine, not routing).
- The router's `$.cookies.mock_url`/`subscriber_url` are populated by an UPSTREAM workbench hop via setRequestCookies (utils.go:39+, OUTBOUND). So the router-500-on-missing-cookie is real in code but unreachable for an external cookieless caller — the receiver guards first.

## Assumptions & perception
- Evidence: live POSTs + `docker logs` (failing step = ondcWorkbenchReceiver, module mockTxnCaller / BapTxnReceiver) + payloadutils.go / utils.go source. High confidence.

## KB effect
- onix-adapter: "Resolved (adr-0025)" block revised — receiver-guard model + live 400/412 statuses + outbound-cookie clarification. INDEX router-fallback note updated. Supersedes the adr-0025 router-fallback claim (the cache DB0/DB1 + embedded-mock parts of adr-0025 stand).
