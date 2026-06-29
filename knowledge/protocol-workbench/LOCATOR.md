# Locator — scan this first (concern → where to look)

Durable navigation map (Map layer). When an issue is reported or a change is planned, the area-of-change narrows to a few **modules → flows/methods**. Scan this table, open only the named frame(s)/files — that's the token-reduction path. Diff-maintained: when a module changes, verify its row. (Reusable failure patterns: `patterns/`. Tactical incident/diff/release logs are archivable → `references/`.)

| Concern / symptom area | Candidate module → flows/methods (file) | Frame | Pattern |
|---|---|---|---|
| validation / NACK / error code | api-service ONIX `ondc-validator` (validationpkg.PerformL1validations); schemavalidator; rules from build.yaml x-validations | [[validation-layers]] · [[onix-plugins]] · [[validation-compiler]] | — |
| HTTP status (200-NACK/400/412/500) | ONIX response builder (response.go); std-handler step chain (stdHandler.go) | [[onix-server]] | [[fm-004]] |
| routing / forward / cookies | router plugin (router.go); ondcWorkbench receiver sets cookies; np/mock/form_router.yaml | [[onix-adapter]] | — |
| signing / auth header | sign/validateSign steps; keymanager (simple=local / Vault=prod) | [[signing-security]] | — |
| flow won't advance / status / forms | mock-playground `process-flow.ts` (dispatchTarget/actOnFlowService); resolvers (sequence/extras/missed); form-handlers.ts | [[flow-state-machine]] · [[mock-playground-service]] | [[fm-002]] [[fm-003]] |
| message_id / payload generation | mock-runner-lib generate/validate/meetsRequirements/saveData; echo via latestMessage_id; generate-response.ts | [[spec-logic]] · [[mock-runner-lib]] | [[fm-001]] |
| TTL / cache expiry / recording | recorder cache.go (txn cache), side_effects.go (NO push), env TTL; redis keys | [[recorder-service]] · [[transaction-session]] | [[fm-002]] |
| persistence / payloads / sessions | db-service entities + routes (Payload/SessionDetails/Report/User) | [[db-service]] | — |
| flow/usecase config served | config-service /ui/flow,/mock/flow,/ui/reporting (in-memory cache) | [[config-service]] | — |
| report pass/fail / Pramaan | report-service reportService/validationModule/checkPayload; FLOW_ID_MAP; ENABLED_DOMAINS | [[report-service]] · [[report-pramaan]] | — |
| UI flow / difficulty / dynamic-form | automation-frontend /flow routes; sessionDifficulty; dynamic-form handlers (FE = runtime-proven only) | [[ui-frontend]] · [[session-difficulty]] | [[fm-005]] [[fm-006]] |
| spec authoring / build / codegen | build-tools (parse/validate/push-to-db); api-service-generator; validation-compiler (xval) | [[build-tools]] · [[api-service-generator]] · [[validation-compiler]] | — |
| spec rules / lifecycle / versioning | automation-specifications config/; spec-logic; domain+version | [[automation-specifications]] · [[spec-logic]] · [[domain-version]] | — |
| run / deploy / env / setup | local-dev-setup; deploy = push-to-db + clear-flows; docker-env knobs | [[local-dev-setup]] · [[kb-sync-on-diff]] | — |

Golden rule: an `on_X`/callback NACK is usually a **mock-generation symptom**, not a protocol bug — check generation first ([[fm-001]]).
