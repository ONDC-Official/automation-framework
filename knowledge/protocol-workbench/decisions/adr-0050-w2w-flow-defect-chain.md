---
id: adr-0050
date: 2026-06-28
grill-ref: owner ran live Gold_Loan_Offline w2w flow (BPP session) — chain of defects diagnosed from session+logs
status: accepted
changes: [recorder-service, session-difficulty, mock-playground-service, run-flow-test, tester-playbook]
---

# w2w flow testing fails through a chain of defects (TTL, local-bap-id L1, DYNAMIC_FORM submission_id)

## Context
Owner's interactive Gold_Loan_Offline flow kept breaking. Diagnosed three stacked, independent causes (none is "bap_id is wrong" — the port-bearing local bap_id is REQUIRED).

## Findings
1. **Recorder txn-cache TTL = 300s (FIXED).** `docker-env/recorder-service.env` pinned RECORDER_CACHE_TTL_SECONDS_DEFAULT/RECORDER_API_TTL_SECONDS_DEFAULT=300 ⇒ the `txnId::subUrl` apiList cache expired after ~5 min ⇒ `current-status`/`/forms/` 500 "No transaction data found" ⇒ flow + form modal dead. Raised to 18000 (5h); recorder restarted. (adr-0049)
2. **Protocol Validation vs local bap_id (WORKAROUND).** With `protocolValidations:true`, the api-service L1 NACKs on_search on REGEX_CONTEXT_BAP_ID (local bap_id host.docker.internal:3032 has a port). NACK ⇒ no BPP catalog/form-url saved ⇒ HTML form modal empty. Workaround: set difficulty `protocolValidations:false` (UI "Protocol Validation" toggle). Then search/on_search/select/on_select ACK and the HTML_FORM (gold_loan_information_form) populates.
3. **DYNAMIC_FORM submission_id defect (FRONTEND bug, not config).** Ekyc_details_form is a DYNAMIC_FORM. `dynamic-form-handler.tsx:156-166` sends a **temporary random** `submission_id` (explicit TODO: "replace with actual submission_id from /form/check-completion once backend returns it from the Redis form_completed key"). The mock proceed (`process-flow.ts:319-351`) requires `inputs.submission_id` (presence only) → stores it via addFormSubmissionId → enqueues API_SERVICE_FORM_REQUEST_JOB with that id. The random id doesn't correlate the real submission ⇒ step advances INPUT-REQUIRED→PROCESSING but **stalls** (never reaches on_status); UI shows "Form complete but failed to proceed." Also note input field is named `form_submission_id` while proceed wants `submission_id` — a naming inconsistency.

## Answer to "how does a BPP progress"
With the current pinned frontend/mock, HTML_FORM steps work but DYNAMIC_FORM steps (eKYC) cannot reliably complete in w2w — incomplete feature. Needs a code fix (frontend to send the real submission_id from form-completion; or mock to use the latest stored submission for the step) or re-pinned compatible submodules. Same submodule-skew theme as adr-0044.

## KB effect
- recorder-service/session-difficulty/mock-playground/run-flow-test/tester-playbook: w2w defect chain + DYNAMIC_FORM bug recorded. Owner correction: local bap_id port is required; never "fix" it.
