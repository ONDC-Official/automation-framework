---
id: adr-0049
date: 2026-06-28
grill-ref: owner-reported "flow stopped working again / select(form) elements missing in UI" — live Gold_Loan_Offline flow
status: accepted
changes: [recorder-service, mock-playground-service, tester-playbook]
---

# Interactive flow dies after ~5 min: txn-cache TTL pinned to 300s (recorder env)

## Symptom
Owner's live UI flow (Gold_Loan_Offline, session ptG4EpA…, txn 494b117a…) reached the `gold_loan_information_form` HTML-FORM step; the form modal rendered EMPTY (only a Submit button) and the flow "stopped working". UI was polling `/flows/current-status` → 500.

## Root cause (runtime-confirmed)
- `getFlowStatusController` and `getFormController` both throw `No transaction data found for transaction ID 494b117a… and subscriber URL …/{buyer,seller}` (`workbench-cache.js:29`). The transaction cache key `transaction_id::subscriber_url` (the apiList) had **expired**.
- That key's TTL = `RECORDER_CACHE_TTL_SECONDS_DEFAULT`. `docker-env/recorder-service.env` pinned it (and `RECORDER_API_TTL_SECONDS_DEFAULT`) to **300s**. So ~5 min after the last write the txn cache vanishes — while `FLOW_STATUS_<key>` (≈5h, observed 16593s) and `MOCK_DATA::…` (-1, no expiry) survive. The HTML-form endpoint reads the (now-missing) txn cache for the buyer subscriber URL ⇒ empty/500.
- The gold-loan form is served by the mock itself: on_search embeds xinput form url `http://host.docker.internal:3031/mock/playground/forms/ONDC:FIS12/gold_loan_information_form/?transaction_id=…&session_id=…` → `getFormController` needs the live txn cache to build it.

## NOT the cause (owner correction)
- `context.bap_id` = `host.docker.internal:3032` (host WITH port) is REQUIRED for local; the on_search `REGEX_CONTEXT_BAP_ID` NACK is expected and NOT the blocker. Do not "fix" bap_id derivation for local.

## Fix applied
- `docker-env/recorder-service.env`: `RECORDER_API_TTL_SECONDS_DEFAULT` and `RECORDER_CACHE_TTL_SECONDS_DEFAULT` 300 → **18000** (5h, matches FLOW_STATUS). `docker compose up -d recorder-service` (env-only, no rebuild). Verify with a fresh flow: the txn cache should persist and the form modal should populate. If the form is still empty WITHIN the TTL window, a second (form-content generation) issue remains.

## KB effect
- recorder-service: txn-cache TTL bug + FLOW_STATUS 5h live-confirmed. tester-playbook: "flow dies / empty form after ~5 min ⇒ recorder TTL" break-point. mock-playground: form served via /forms/ endpoint needing live txn cache.
