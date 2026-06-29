---
id: adr-0055
date: 2026-06-29
grill-ref: owner — eKYC resolved; FLOW_STATUS/validateSign gap was temporary
status: accepted
changes: [mock-playground-service, mock-service-embedded]
---

# eKYC dynamic-form resolved; runtime-pending #2 was temporary

## Decision
- eKYC DYNAMIC_FORM completion is RESOLVED / working end-to-end (owner-confirmed) via the api-service `/callback` redirect (adr-0052) + mock idempotency guard (adr-0051).
- The earlier runtime-pending items (FLOW_STATUS_ 5h key on a full receiver hop; validateSign verifying a fresh inbound signature) were a TEMPORARY gap caused by the blocked full flow; with flows now completing they are exercised — closed.
- Resolved the mock-service-embedded open question: ONIX mockTxnCaller proxies to the standalone mock-playground-service (live mock_url = playground-mock-service:3000/.../manual, adr-0048) ⇒ the embedded static mock is legacy / not used at runtime.

## Assumptions & perception
- Owner confirmation (interview). Frontend was re-pinned to main but main still carries legacy bits; the mock-side fixes are the effective ones.

## KB effect
- mock-playground-service: eKYC resolved note. mock-service-embedded: legacy/not-runtime confirmed. INDEX OQ7 updated.
