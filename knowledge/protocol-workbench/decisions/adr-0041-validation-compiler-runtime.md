---
id: adr-0041
date: 2026-06-28
grill-ref: RUNTIME-VERIFICATION-PROMPT path 9 (validation-compiler ↔ plugin), live FIS12 2.0.3
status: accepted
changes: [validation-compiler, onix-plugins]
---

# L1 failures route through generated validationpkg.PerformL1validations — confirmed live

## Decision (runtime-observed) — CONFIRMED
- ondc-validator plugin (ondcvalidator.go:49) calls `validationpkg.PerformL1validations(endpoint, payloadData, …)`; the save variant at :107 `PerformL1validationsSave`. The validationpkg is the generated L1 artifact from [[validation-compiler]].
- Live L1 failure on /test/search (missing required field) ⇒ NACK `error.code:"Bad Request"`, message `#### **REQUIRED_PAYMENT_COLLECTED_BY**\n\n- $.message.intent.payment.collected_by must be present ...` with a developer-guide URL. Logs: "Starting L1 validation" → "L1 validation completed with error count: N" → on fail "Step validateOndcPayload failed"; on pass "L1 validation successful". Contextual regexes printed live (TTL `^P(?=\d|T\d)(\d+Y)?...`, timestamp, domain/uri patterns).
- Error shape: CODE token (UPPER_SNAKE, e.g. REQUIRED_PAYMENT_COLLECTED_BY) + JSONPath of the offending field.

## KB effect
- validation-compiler / onix-plugins: chain x-validations→validationpkg→ondc-validator confirmed at runtime; error-code+JSONPath shape recorded. Confidence stays high.
