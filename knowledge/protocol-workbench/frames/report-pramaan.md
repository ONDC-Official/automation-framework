---
id: report-pramaan
kind: instance
isa: service
part-of: workbench
asof: 2026-06-26
confidence: high
status: legacy-plug (functional, not deprecated)
source: repo automation-report-pramaan/ + report-service pramaanCallbackController/payloadUtils — adr-0026
changed-by: adr-0026
---

# report-pramaan (NP conformance test runner)

> Status (asof 2026-06-26): LEGACY plug — still functional, invoked by report-service for non-enabled domains/usecases, NOT deprecated. Reporting redesign planned; document current code as truth.

Two parallel Node.js services that run **mocha-based conformance test suites** over NP payloads and emit mochawesome JSON. "Pramaan" (प्रमाण = proof/certificate) is ONDC's NP certification concept; NPs must pass Pramaan before go-live. report-service calls these for non-locally-validated domains.

## Slots
- services: report-pramaan-buyer (host 3005, tests BAP conformance) ; report-pramaan-seller (host 3006, tests BPP conformance) — both container port 3005/internal 5063|5055
- engine: mocha test suites per usecase (Retail, Airline, Intercity, Investment, RetailINVL...), versioned; mochawesome JSON output
- test-input: givenTest flow config {id, flow:[{action,test}]}; maps actions→logs→test functions (search/select/init/confirm/cancel/track/update/info/...)
- pass-criteria: action request/response schema validation + custom context/message checks
- db: own MongoDB (compose port 27019) storing test metadata + results
- built-via: pramaan.Dockerfile (node:16-alpine) from monorepo root; ARG SERVICE_DIR selects buyer/seller dir

## Relations
- invoked-by → [[report-service]] (PRAMAAN_URL, async)
- callback → report-service /callback/:testId with base64 mochawesome
- defined-by → script [[generate-report]] (pramaan branch)

## Callback contract (adr-0026)
- report-service POSTs tests to PRAMAAN_URL (body: id=subscriber_id, version, domain, environment=Preprod, type, tests[{flow_id,transaction_id}], test_id=PW_${sessionId}); Pramaan runs mocha → mochawesome → POSTs base64 to report-service /callback/:testId; suiteHasFailure(suite) → FAIL else PASS, reverse-mapped via FLOW_ID_MAP.

## Open questions
- Revisit when reporting redesign lands (legacy until then) → owner: Shreyansh
