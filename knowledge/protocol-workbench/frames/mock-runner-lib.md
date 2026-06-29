---
id: mock-runner-lib
kind: instance
isa: component
part-of: automation-libraries
confidence: high
source: repo automation-mock-runner-lib/src/* (adr-0031)
changed-by: adr-0031
---

# mock-runner-lib (@ondc/automation-mock-runner)

The engine that executes the per-step requirement/generation/validation JS — i.e. the runtime realization of [[spec-logic]]. Consumed by [[mock-playground-service]] (NOT by the api-service embedded mock — confirms [[mock-service-embedded]] is separate/static).

## MockRunner API
- constructor(config: MockPlaygroundConfig, skipValidation?) — validates config (ConfigurationError)
- runGeneratePayload(actionId, inputs, extraSessionData?) / runGeneratePayloadWithSession(actionId, sessionData)
- runValidatePayload(actionId, target, extra?) / …WithSession
- runMeetRequirements(actionId) / …WithSession
- generateContext(actionId, action, sessionData?) — version-aware (v1 flat city / v2 nested location.city.code); search omits bpp
- getSessionDataUpToStep(index) — builds session from transaction_history via saveData
- getDefaultStep(api, actionId, formType?); static initSharedRunner, encode/decodeBase64, runGetSave
- returns ExecutionResult {success, result, error, logs[], executionTime, validation{isValid,errors,warnings}}

## Config grammar (MockPlaygroundConfig)
- meta{domain, version, flowId, use_case_id?, flowName?}; transaction_data{transaction_id, latest_timestamp, bap_id?/uri?, bpp_id?/uri?, external_session_data?}
- steps[PlaygroundActionStep]; extra_steps?; transaction_history[]; validationLib, helperLib (base64 shared code)
- PlaygroundActionStep: api, action_id, owner BAP|BPP, responseFor, unsolicited, repeatCount?, mock, examples?
- mock: {generate, validate, requirements, defaultPayload, saveData, inputs{id?,jsonSchema?,sampleData?}, formHtml?}

## Per-step JS functions (base64; the "logic") — see [[spec-logic]]
- generate(defaultPayload, sessionData) → payload (timeout 45s)
- validate(targetPayload, sessionData) → {valid, code, description} (5s)
- meetsRequirements(sessionData) → {valid, code, description} (3s)
- getSave(payload) (3s) for EVAL# save-data
- user_inputs merged into sessionData before generate

## Sandbox (security)
- VM (vm.createContext) + worker-thread pool; whitelisted globals (Math/Date/JSON/Array/Promise/setTimeout 1-45s…)
- BLOCKED: eval, Function, require, process, Buffer, localStorage, Worker, XHR, WebSocket
- fetch only in generate, gated by initSharedRunner allowedFetchBaseUrls (origin + pathname-prefix); CodeValidator AST static analysis (forbidden globals, infinite loops, `with`, return-shape)

## save-data / session fullness
- key `[APPEND#]sessionKey`, value JSONPath or `EVAL#<base64>`; APPEND# concatenates; accumulates across steps (session fullness)

## Helpers (in generate scope)
- getSubscriberUrl, uuidv4, generate6DigitId, currentTimestamp, isoDurToSec, setCityFromInputs, createFormURL, generateConsentHandler (Finvu AA consent, fetch-based)

## Relations
- part-of → [[automation-libraries]] ; engine-of → [[spec-logic]], [[flow-state-machine]] ; used-by → [[mock-playground-service]]
- NOT-used-by → [[mock-service-embedded]]
