---
id: session-difficulty
kind: concept
isa: concept
part-of: ui-frontend
confidence: high
source: repo automation-frontend/backend interfaces/newSessionData.ts (sessionDifficulty) + flow controller
changed-by: adr-0022
---

# Session difficulty (validation strictness knobs)

A per-session settings object (sessionDifficulty / difficulty_cache) that toggles how strict the workbench is during a flow test. Key for QA: it controls which validations are exercised — directly relevant to the [[w2w-testing]] blind spot and reproducing NP-facing strictness.

## Slots (knobs) — full runtime struct, 10 fields (adr-0042; cache/types.go `SessionDifficulty`)
Defaults from workbench receiver.go `defaultDifficulty()` in [brackets]:
- sensitiveTTL [true] — strict timestamp/TTL checking (clock-skew sensitive)
- useGateway [true] — routes `search` to GATEWAY_URL (multicast/translation; see [[registry-gateway]])
- stopAfterFirstNack [false] — halt the flow on the first NACK
- protocolValidations [true] — enable/disable protocol (L1) validations
- timeValidations [true] — enable/disable timestamp validations
- headerValidaton [true] — enable/disable header (signature/auth) validation [sic spelling in code]
- useGzip [false] — gzip request bodies
- encryptionValidation [false, opt-in] — payload encryption validation (NEW vs prior KB)
- useCare [false, opt-in] — routes `issue`/`on_issue` to CARE_URL (NEW)
- useTunnelForFIS [false, opt-in] — routes everything via tunnel for FIS flows (NEW)

## Where set / used
- set at session creation (/scenario form → POST ui-backend /sessions, difficulty_cache); stored in Redis SessionCache (48h)
- influence how ui-backend/api-service apply validations during /flow/trigger + /flow/proceed
- **propagation (adr-0042):** the workbench receiver writes each knob as a same-named **cookie** on the OUTBOUND forwarded request (utils.go setRequestCookies): `protocol_validation`, `header_validation`, `use_gzip`, `encryption_validation`, `use_care`, `use_tunnel_for_fis`, `use_gateway`, plus `ttl_seconds`. The next hop reads these cookies to decide which validations/routes to apply.
- **confirmed live:** `protocol_validation` gates the ondcvalidator L1 step — log on /test/search: "Executing ONDC validation step with protocol_validation header value: true". So protocolValidations=false ⇒ L1 skipped.
- **full cookie set captured live (adr-0048)** on a forwarded mockTxnCaller request: `header_validation=true; protocol_validation=true; use_gzip=false; encryption_validation=false; use_care=false; use_tunnel_for_fis=false` plus `request_owner=buyer_np; ttl_seconds=30; flow_id; session_id; transaction_id; subscriber_url; subscriber_id; usecase_id; mock_url=http://playground-mock-service:3000/mock/ONDC:FIS12/2.0.3/manual; forward_request=true; custom-response-body=<base64 of the ACK>`. (Note `mock_url` is the np_router `$.cookies.mock_url` target — see [[onix-adapter]].)

## Relations
- part-of → [[ui-frontend]] session model
- modulates → [[validation-layers]] (which layers fire) ; relevant-to → [[w2w-testing]], [[persona]] (QA)

## Open questions
- Per-knob→cookie propagation mapped (adr-0042); protocol_validation→L1 gate confirmed live. Still to exhaustively toggle each of the 10 on/off in two live sessions and observe every fire/skip → owner: Shreyansh
