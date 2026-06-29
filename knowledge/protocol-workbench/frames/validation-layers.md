---
id: validation-layers
kind: class
isa: concept
confidence: high
source: repo api-service build-output plugins + config/validations + report-service
changed-by: adr-0003
---

# Validation layers (what gets checked, where)

The workbench validates protocol payloads at multiple points. Knowing which layer catches what is key for QA/testers and for answering "why did my payload fail".

## Layers
1. Schema (api-service SchemaValidator plugin) — structure, types, required fields, formats (uuid, date-time) against generated JSON schema for `{domain}_{version}_{action}`.
2. L1 / contextual (api-service ONDC-Validator plugin) — from spec `x-validations`: required context fields (domain, action, bap_id, message_id, transaction_id, timestamp, ttl, version), enums, regex (e.g. TTL pattern), conditional rules (e.g. bpp_id required on on_search but not search), state deps (async_predecessor, transaction_partner).
3. Flow/sequence (mock-playground-service + report-service) — is this action expected next in the flow? matched on triplet `action::message_id::timestamp`. Out-of-sequence ⇒ no matching step.
4. Report validators (report-service, enabled domains) — per-domain/action validators re-validate persisted payloads to produce pass/fail.

## Path-dependent enforcement (adr-0009; runtime-confirmed adr-0037)
- `/test/{action}` path (standaloneValidator): schema + L1 ONLY — `stateFullValidations: false`, no `validateSign`. Live steps = validateSchema → validateOndcPayload. Returns **HTTP 200 for both ACK and NACK** (NACK carries `error.code`+JSONPath); 500 only on a malformed-context panic (nil message_id). L1 gated by `protocol_validation` request header (default true).
- `/{d}/{v}/seller/` transaction path (BapTxnReceiver) + `/buyer/` (BppTxnReceiver): adds sequence/state validation + `validateSign`. Live 7-step chain = ondcWorkbenchReceiver → addRoute → validateSchema → validateOndcPayload → ondcWorkbenchValidateContext → validateSign → validateOndcCallSave; `stateFullValidations:true`.
- `/{d}/{v}/mock/` caller path (mockTxnCaller): validateSchema but **NO validateOndcPayload (L1)**; signs outbound (`sign`, not validateSign). Steps = ondcWorkbenchReceiver → addRoute → validateSchema → ondcWorkbenchValidateContext → sign → validateOndcCallSave.

## W2W coverage blind spot (adr-0019)
- Workbench-to-workbench flows pass because both sides share an implicit common assumption NOT coded as an explicit validation; real NP divergences won't surface. Mitigate with NP-facing + negative/monkey testing. See [[w2w-testing]].

## NOT validated (edge/coverage gaps for testers)
- business logic beyond schema structure
- cross-action temporal ordering on the TEST path (only enforced on the transaction path)
- signature on the TEST path (verified on transaction path via validateSign; active in local stack)
- idempotency / message_id dedup at validator level (recorder dedups in cache, not validator)

## Relations
- enforced-by → [[api-service]], [[mock-playground-service]], [[report-service]]
- rules-source → [[automation-specifications]] (validations/index.yaml, actions/index.yaml)

## Resolved (adr-0009, adr-0018)
- Signature verification (validateSign) IS active locally on the transaction path; skipped on the test path. Algorithm Ed25519 over BLAKE-512 digest; keys via registry/env — see [[signing-security]].
- Layer enforcement is per adapter.yaml module; full chain order in [[onix-adapter]] / [[onix-request-lifecycle]].
