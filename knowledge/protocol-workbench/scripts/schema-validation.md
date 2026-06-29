---
id: schema-validation
kind: script
confidence: high
source: repo automation-frontend (schema-validation page, flowController.validatePayload) + api-service
changed-by: adr-0008
---

# Schema Validation (UI tool)

NP UI user pastes a payload and checks it against the spec. No flow/session needed.

## Entry conditions
- a domain api-service is running on 3032; payload has context.domain + context.version + action

## Roles
- NP developer, ui-frontend, ui-backend, api-service

## Scenes (ordered)
1. Paste — user pastes JSON in Monaco editor on /schema-validation.
2. Submit — POST ui-backend /flow/validate/:action with full payload.
3. Route — ui-backend extracts domain/version from context → POST api-service `/{domain}/{version}/test/{action}`.
4. Validate — api-service runs schema + L1 validators (see [[validation-layers]]).
5. Show — errors returned as field paths/messages → rendered as inline editor decorations + collapsible panel; or success.

## Results
- pass/fail with per-field errors; user fixes and re-tests.

## Runtime-observed (adr-0037, FIS12 2.0.3, live)
- api-service module = `standaloneValidator` (adapter.yaml path `/api-service/{d}/{v}/test/`); plugins = schemavalidator + ondcvalidator(`stateFullValidations:false`); steps = **validateSchema → validateOndcPayload** ONLY (no cache/keymanager/sign/workbench-receiver/state).
- **HTTP status is decoupled from ACK/NACK**: success ⇒ `200 {"message":{"ack":{"status":"ACK"}}}`; L1/schema failure with a well-formed context ⇒ **also `200`** but `{"message":{"ack":{"status":"NACK"}},"error":{"code":"Bad Request","message":"#### **CODE** ... JSONPath ..."}}`. (Resolves the old 200-vs-202 question: it is **200**, never 202.)
- malformed context (e.g. missing `transaction_id` ⇒ message_id nil) ⇒ **`500`** `"Internal server error, MessageID: %!s(<nil>)"` (Go nil-format artifact) — a panic path, not the normal NACK.
- L1 runs only when request header `protocol_validation: true` (default); log: "Executing ONDC validation step with protocol_validation header value: true" — this header is the [[session-difficulty]] protocolValidations knob.

## Edge points
- missing context.domain/version ⇒ ui-backend 400 (before api-service); malformed context reaching api-service ⇒ 500 (above).
- api-service down ⇒ 500.
- last payloads cached in localStorage.
