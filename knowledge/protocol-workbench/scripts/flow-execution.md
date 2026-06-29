---
id: flow-execution
kind: script
confidence: high
source: repo automation-mock-playground-service (process-flow.ts, flow-controller, incoming-request-controller, jobs)
changed-by: adr-0004
---

# Flow execution (mock-playground dispatch)

How the mock simulates the counterparty and advances a flow step by step. Core runtime for QA/workbench-devs.

## Entry conditions
- a session exists in Redis (DB0) with flowConfigs; config-service reachable (or PLAYGROUND_${sessionId} pre-seeded)

## Roles
- caller (ui-backend / tester), mock-playground-service, MockRunner, queue, api-service, subscriber-under-test, recorder, config-service

## Scenes (ordered)
1. Start — POST /flows/new {session_id, flow_id, [transaction_id], [inputs]} → load session, flow, build TransactionCache stub → actUponFlow.
2. Determine next — actOnFlowService: fetch FlowStatus (AVAILABLE/WORKING/SUSPENDED), MOCK_DATA business cache, extra statuses; replay apiList via FlowMapBuilder resolver chain (sequenceResolver → extrasResolver → missedResolver) → compute sequence.next + extras.next as MappedSteps with phase status (COMPLETE/LISTENING/RESPONDING/WAITING/INPUT-REQUIRED/PROCESSING/WAITING-SUBMISSION). See [[flow-state-machine]].
3. Dispatch — for each eligible target set status WORKING; if FORM → API_SERVICE_FORM_REQUEST_JOB; else GENERATE_PAYLOAD_JOB. Handle INPUT-REQUIRED (manual needs {id}, form needs submission_id), LISTENING/expect.
4. Generate — job: get MockRunner (config-cache → config-service on miss), load txn data + user_inputs + bapUri/bppUri, runMeetRequirements, mockRunner.generate(actionId) → payload; save-data JSONPath → MOCK_DATA; enqueue SEND_TO_API_SERVICE_JOB; append to apiList.
5. Forward — payload sent to api-service, which delivers to subscriber-under-test.
6. Receive — POST /manual/:action (counterparty/api-service response): match step on action::message_id::timestamp; run step mock.validate; if next is HTML_FORM, fetch+sanitize+resolve form HTML; set status AVAILABLE; → actUponFlow again.
7. Proceed — POST /flows/proceed {transaction_id, session_id, [inputs], [trigger_extra]} repeats 2-6 until no actionable steps.

## Results
- a recorded sequence of API/FORM entries per transaction; flow PASS/FAIL determinable by report-service.

## Edge points
- out-of-sequence ⇒ "no matching step", no advance.
- generator failure ⇒ reset AVAILABLE / stuck WORKING.
- config-service down ⇒ first generation times out.
- trigger_extra must target an AVAILABLE, counterparty-owned extra key.
- backdoor clear-flows reloads cached flow config.
