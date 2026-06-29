---
id: adr-0052
date: 2026-06-28
grill-ref: owner insight "auto-close should be a /callback function, not within the form" — eKYC DYNAMIC_FORM modal hang (release-eks-tech frontend)
status: accepted
changes: [mock-playground-service, run-flow-test]
---

# Applied: dynamic-form success routes completion through the api-service /callback

## Problem
release-eks-tech frontend opens the eKYC DYNAMIC_FORM in a tab and polls `form_completed:{UI session}` (written ONLY by the api-service /callback). The mock's `getSuccessHtml` (form-handlers.ts) rendered a static "Form Submitted" page that just `window.close()`d the tab — it never navigated to /callback, so `form_completed` was never written and the modal hung ~600s (Poll #N/300). Owner correctly identified: the auto-close should be a /callback function, not handled within the form.

## Fix (form-handlers.ts)
- `handleFormSubmitService` dynamic_form branch: build `callbackUrl = `${sessionData.subscriberUrl}/callback`` and pass it to `getSuccessHtml`. The form session's subscriberUrl path (e.g. /buyer) matches the `redirection_url:{path}` key the frontend wrote, which maps to the UI session — so the callbackredirect middleware writes `form_completed:{UI session}` and 302-redirects.
- `getSuccessHtml(submissionID, callbackUrl?)`: the success page now navigates via `window.location.replace(callbackUrl)` (global `finish()`), countdown 2s, "Continue" button → finish(); falls back to `window.close()` if no callbackUrl.
- Built + deployed playground-mock-service (tsc clean; built JS contains finish/callback). 

## Why it routes correctly (cross-session)
Form runs on the BAP/counterparty session (subscriberUrl …/buyer); UI drives the BPP session (…/seller). `redirection_url:/…/buyer` → UI session. `${subscriberUrl}/callback` = …/buyer/callback → middleware strips /callback → looks up redirection_url:/…/buyer → writes form_completed:{UI session}.

## Verification status
- Build clean, mock healthy. **End-to-end pass needs a FRESH flow**: reach eKYC → submit → success page redirects to /callback → form_completed written → modal closes → flow advances to on_status. If a flow uses a side whose redirection_url key is absent, the callback 404s (fallback: window.close) — watch for that.

## KB effect
- mock-playground/run-flow-test: dynamic-form completion now callback-based (matches HTML/redirect forms). Stacks with adr-0049 (TTL), adr-0050/protocolValidations-off, adr-0051 (idempotency guard).
