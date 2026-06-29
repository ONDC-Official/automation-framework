---
id: flow-state-machine
kind: concept
isa: concept
part-of: mock-playground-service
confidence: high
source: repo mock-playground src/service/flows/* (mapper, pending-step, process-flow, jobs), docs/decision-flows.md
changed-by: adr-0020
---

# Flow state machine (mock-playground)

How the mock computes "what to do next". Stateless-by-design: NO persistent current-step pointer — state = reduce(apiList) + pending-step computation on every read. Core for QA/devs reading flow status.

## Transaction-level status (FlowStatus, Redis FLOW_STATUS_*, TTL 5h)
- AVAILABLE → accepts dispatch · WORKING → locked, incoming matched/appended but no new dispatch · SUSPENDED → halts actOnFlow early.
- Extras have per-step status (EXTRA_FLOW_STATUS_*::stepKey), AVAILABLE↔WORKING.

## Per-step phase status (MappedStep.status — 7 values)
- COMPLETE — executed, saved, not actionable.
- LISTENING — mock awaits inbound call from system-under-test (creates Expectation if step.expect).
- RESPONDING — mock will dispatch a response/unsolicited action.
- WAITING — pending, upstream not done yet.
- INPUT-REQUIRED — like RESPONDING but blocks until user supplies inputs (manual needs {id:actionId}; non-manual needs inputs present).
- PROCESSING — form step, owner=subscriber, flowStatus WORKING.
- WAITING-SUBMISSION — form step, owner≠subscriber, awaits form submission_id.
- Actionable (dispatchable) = {RESPONDING, INPUT-REQUIRED, WAITING-SUBMISSION}. LISTENING only creates Expectations.

## Resolver chain (replay apiList; early winner wins)
1. sequenceResolver — matches strict sequence step (or form type) → COMPLETE, advance cursor.
2. extrasResolver — matches an extraSequence action → resolve placeholder or add COMPLETE + placeholders (parallel, no cursor).
3. missedResolver — fallback classify: BEYOND ("action beyond flow sequence"), OUT_OF_ORDER ("executed out-of-order"), NOT_FOUND ("not found in flow sequence").
- After history consumed, remaining strict steps become pending via buildPendingStep (i===cursor ⇒ immediate next).
- MORE_SEQUENCE: mockSessionData can dynamically extend the strict sequence at runtime.

## Per-step JS logic (mock-runner config) — see [[spec-logic]]
- requirement (runMeetRequirements), generation (generate), validation (validate) are the three config-carried JS functions per step; with L1 they form the spec "logic". save-data → MOCK_DATA is the "session fullness" mechanism (subset defaulted commonly in prod).

## Jobs
- GENERATE_PAYLOAD_JOB → load MockRunner, inject bapUri/bppUri/user_inputs, runMeetRequirements (skippable via SKIP_MEETS_REQUIRMENTS), generate payload, save-data JSONPath → MOCK_DATA, enqueue send. On error → reset status AVAILABLE.
- SEND_TO_API_SERVICE_JOB → POST {API_SERVICE}/{domain}/{version}/mock/{action}. Does NOT reset flowStatus (api-service owns it after processing).
- API_SERVICE_FORM_REQUEST_JOB → POST {API_SERVICE}/{domain}/{version}/form/html-form with form metadata.

## Relations
- part-of → [[mock-playground-service]] ; drives → script [[flow-execution]]
- statuses-gate → dispatch (process-flow.ts)

## Open questions
- RESOLVED (adr-0057): extras pairing is 2-DEEP ONLY — when an extra step completes, extras-resolver creates a placeholder for its single `pair` (one request→response level); it does not chain A→B→C.
