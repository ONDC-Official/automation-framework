---
id: adr-0051
date: 2026-06-28
grill-ref: fix applied for the eKYC DYNAMIC_FORM stall (adr-0050 finding) + frontend re-pinned to main
status: accepted
changes: [mock-playground-service, run-flow-test]
---

# Applied: DYNAMIC_FORM idempotency guard (mock) + frontend re-pinned to main

## Change
- **Mock fix** (`automation-mock-playground-service/src/service/flows/process-flow.ts`, `dispatchTarget`): added an idempotency guard BEFORE `setFlowStatus`. For FORM_TYPES steps, if a real form submission already exists in the session (`formSubmissions[`${txn}_${actionId}`].submission_id`) AND the caller's `inputs.submission_id` differs, the proceed is a no-op (returns ''). This neutralises the frontend's redundant placeholder-id re-proceed (which had overwritten the real submission + re-enqueued a bogus API_SERVICE_FORM_REQUEST_JOB, stranding eKYC at PROCESSING). HTML_FORM is unaffected (it passes the real id back, so provided===stored). Must run before setFlowStatus so a no-op doesn't leave the step WORKING.
- **Frontend re-pinned** to origin/main `1adff1e` (2026-06-28, by owner) and rebuilt (ui-frontend + ui-backend). NOTE: main still carries the dynamic-form `crypto.randomUUID` TODO and the stale `trigger/api-service/:action` backend route — so the mock-side guard is what actually fixes eKYC; the frontend update is for main's other 28 commits.
- Rebuilt + recreated playground-mock-service, ui-frontend, ui-backend. All healthy.

## Verification status
- Builds clean (tsc in container), containers healthy. **End-to-end eKYC pass requires a FRESH flow run** (the prior txn was left corrupted by manual proceeds). Expected: eKYC advances INPUT-REQUIRED → on_status instead of "Form complete but failed to proceed."

## KB effect
- mock-playground/run-flow-test: DYNAMIC_FORM fix recorded. Pairs with the prerequisites — recorder TTL 18000 (adr-0049) + Protocol Validation off for local bap_id (adr-0050).
