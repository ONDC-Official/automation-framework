---
id: adr-0037
date: 2026-06-28
grill-ref: RUNTIME-VERIFICATION-PROMPT path 1 (schema validation test path), live FIS12 2.0.3 stack
status: accepted
changes: [schema-validation, validation-layers, onix-adapter]
---

# Test path is schema+L1 only; returns HTTP 200 for ACK and NACK (not 202)

## Question / context
Verify the UI Schema-Validation / `/test/{action}` path against the running api-service: confirm schema+L1 only (no sign/state), and capture the exact success HTTP status (KB unsure 200 vs 202) and which plugins log.

## Decision (runtime-observed)
- Live `adapter.yaml` (FIS12 2.0.3) module `standaloneValidator`, path `/api-service/ONDC:FIS12/2.0.3/test/`, plugins = schemavalidator + ondcvalidator(`stateFullValidations:false`), steps = `validateSchema → validateOndcPayload` ONLY. No cache/keymanager/signvalidator/workbench. CONFIRMED.
- Success: `POST .../test/search` valid payload ⇒ **HTTP 200** `{"message":{"ack":{"status":"ACK"}}}`. Logs: "Validating schema..." → "Starting L1 validation" → "L1 validation successful" → "Sending Ack". Only module_id=standaloneValidator.
- L1 failure (well-formed context, missing required field) ⇒ **HTTP 200** with `{"message":{"ack":{"status":"NACK"}},"error":{"code":"Bad Request","message":"#### **REQUIRED_PAYMENT_COLLECTED_BY** ... $.message.intent.payment.collected_by must be present ..."}}`. HTTP status decoupled from ACK/NACK.
- Malformed context (missing transaction_id ⇒ nil message_id) ⇒ **HTTP 500** `"Internal server error, MessageID: %!s(<nil>)"` (Go nil-format artifact; panic path).
- L1 gated by request header `protocol_validation` (observed value true) — ties to [[session-difficulty]].

## Assumptions & perception
- Evidence: live POSTs via api-gateway :3032 + `docker logs api-ondcfis12-2-0-3`. High confidence. The 500 is a panic on nil message_id, not a designed status.

## KB effect
- schema-validation script: added Runtime-observed block (status codes, NACK shape, protocol_validation gate). validation-layers: test/seller/buyer/mock chains corrected to live steps; resolved 200-vs-202 ⇒ 200. triples updated.
