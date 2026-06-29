# Triples — atomic facts (subject — relation — object)

> Triples = atomic, TIMELESS facts for retrieval. Incident/debugging narrative (root-cause chases, session/txn ids, dated fixes) lives in `decisions/` ADRs + `references/` reports, NOT here.

## System / structure
workbench — isa — system
workbench — orchestrated-by — automation-framework
workbench — hosted-at — workbench.ondc.tech
workbench — core-tool — schema-validation-tool
workbench — core-tool — flow-testing-suite
workbench — core-tool — playground
automation-framework — isa — orchestrator
automation-framework — submodule-count — 9
automation-framework — external-image — user-management-service
automation-framework — external-image — form-service
automation-framework — network — automation-network
automation-framework — env-source-of-truth — root .env
automation-framework — shared-auth-key — API_SVC_KEY (x-api-key)

## Components part-of workbench
api-service — part-of — workbench
automation-specifications — part-of — workbench
mock-playground-service — part-of — workbench
recorder-service — part-of — workbench
db-service — part-of — workbench
config-service — part-of — workbench
report-service — part-of — workbench
report-pramaan — part-of — workbench
user-management-service — part-of — workbench
form-service — part-of — workbench
ui-frontend — part-of — workbench
backoffice-frontend — part-of — workbench

## Ports (host)
ui-frontend — port — 3035
ui-backend — port — 3034
backoffice-frontend — port — 5100
backoffice-backend — port — 5200
mock-playground-service — port — 3031 (container 3000)
report-service — port — 3000
form-service — port — 3300
db-service — port — 5001
config-service — port — 5556
user-management-service — port — 8082
registry-service — port — 8080 (external placeholder)
jaeger — port — 16686
recorder-service — port — 8090 http / 8089 grpc
report-pramaan-buyer — port — 3005
report-pramaan-seller — port — 3006
api-gateway — port — 3032 (nginx → ONIX 7039)

## Internal URLs
mock-playground-service — internal-url — http://playground-mock-service:3000/mock
db-service — internal-url — http://db-service:5001
config-service — internal-url — http://config-service:5556
api-service — internal-url — http://api-service:80/api-service
report-service — internal-url — http://report-service:3000
recorder-service — grpc-url — recorder-service:8089

## Infra
mongo — image — mongo:6
redis — image — redis:7-alpine
jaeger — image — jaegertracing/all-in-one:1.57.0
redis — used-by — mock-playground-service (DB0 workbench, DB1 config)
redis — used-by — recorder-service (txn cache, flow status)
mongo — used-by — db-service (Payload, SessionDetails, reports GridFS)
mongo — used-by — user-management-service (developer_guide)
mongo — used-by — report-pramaan (port 27019)

## Spec / protocol runtime
automation-specifications — is — authoritative spec source
automation-specifications — branch-equals — one domain+version
automation-specifications — branch-prefix-maps-to — workbench environment
draft-branch — targets-env — dev/QA workbench env
release-eks-branch — targets-env — NP-facing production
spec-lifecycle-status — values — draft | live | to-be-deprecated | deprecated
spec-lifecycle-status — carried-by — developer-guide flag
spec-lifecycle-status — orthogonal-to — branch-prefix environment
spec-lifecycle-status — note — ecosystem-draft version can run in prod
domain-version — tagged-with — spec-lifecycle-status
deprecation-flow — status — not finalized (WIP)
versioning-unit — primary — domain+version
versioning-unit — exception — domain+usecase+version (split-usecase domains)
flow — is-versioned — no
usecase — is-versioned — no (except split-usecase domains)
version-scheme — format — Major.Minor.Fix
version-fix — means — protocol-miss correction (mandatory enum add, flow-miss fix; no new capability)
version-minor — means — additive: new flow / new call-to-action enums + branching / new domain functionality (protocol extension)
version-major — means — drastic change to protocol, network architecture, API payload, etc.
spec-promotion — means — draft → release-eks (working env → prod env)
spec-promotion — gated-by — human approval + verification
spec-promotion — approved-by — spec owner / protocol architect / protocol engineers
spec-cicd — status — WIP (spec-workflow.yml, deploy-onix.yaml not finalized)
branch-version — always-in-sync-with — ONDC official spec version (cannot diverge)
spec-version-upgrade — produces — new branch (not in-branch bump)
branch-commit — has-no-correlation-with — spec version
domain — coexists-as — multiple version branches concurrently
release-eks-branches — define — what's live in prod (source of truth)
draft-branches — define — what's available in non-prod
config-service — is-runtime-mirror-of — pushed-to-db specs per env (not source of truth)
whats-live-query — answer-from — automation-specifications branch set
spec-config — produces — build.yaml (via @ondc/build-tools parse)
build.yaml — consumed-by — @ondc/api-service-generator@1.0.2
generator — produces — api-service build-output (schemas, adapter.yaml, beckn plugins, Dockerfile)
api-service — base-image — ghcr.io/ondc-official/automation-beckn-onix:latest
api-service — internal-port — 7039
api-service — validates-via — schemavalidator-plugin
api-service — validates-via — ondc-validator-plugin
ondc-validator-plugin — rules-source — build.yaml x-validations
build.yaml — rag-artifact — generated/raw_table.json
spec-to-runtime — pushes — build.yaml + raw_table.json to db-service
domain-version — single-active-on — port 3032

## Data flow
api-service — emits-audit-to — recorder-service (gRPC LogEvent)
recorder-service — sync-writes — redis txn cache
recorder-service — async-persists — db-service
recorder-service — async-pushes — network-observability (prod)
config-service — reads-from — db-service
config-service — serves — mock-playground-service
config-service — serves — ui-frontend
mock-playground-service — forwards-to — api-service
mock-playground-service — loads-flows-from — config-service
report-service — reads-payloads-from — db-service
report-service — delegates-to — report-pramaan (non-enabled domains)
ui-backend — calls — api-service
ui-backend — calls — mock-playground-service
ui-backend — calls — config-service
ui-backend — calls — report-service
ui-backend — calls — db-service
ui-backend — auth-via — user-management-service

## Protocol concepts
ondc-protocol — role — BAP (buyer)
ondc-protocol — role — BPP (seller)
ondc-protocol — role — BG (gateway, search multicast)
ondc-protocol — action-pair — search/on_search
transaction_id — qualifies-cache-key — transaction_id::subscriber_url
message_id — match-triplet — action::message_id::timestamp
session_id — ttl — 48h (ui-backend)
flow-status — values — AVAILABLE | WORKING | SUSPENDED
registry — role — identity + public key directory
gateway — routes — search only

## Key match / cache
recorder-service — cache-key — transaction_id::subscriber_url
recorder-service — flow-status-key — FLOW_STATUS_<key> (TTL 5h)
mock-playground-service — business-cache-key — MOCK_DATA::txn::suburl
mock-playground-service — mockrunner-config-key — domain::version::flowId::usecaseId

## Validation layers
validation-layers — layer1 — schema (api-service)
validation-layers — layer2 — L1 contextual (api-service ondc-validator)
validation-layers — layer3 — flow sequence (mock + report)
validation-layers — layer4 — report validators (report-service)
validation-layers — not-checked — idempotency at validator
api-service — test-path-module — standaloneValidator (stateFullValidations:false, no validateSign)
api-service — txn-path-module — BapTxnReceiver (seller, BAP) / BppTxnReceiver (buyer, BPP)
api-service — caller-module — mockTxnCaller (mock path, outbound signing)
api-service — form-module — formReceiver + callbackReceiver
api-service — signature-verification — validateSign (active locally on txn path only)
onix-adapter — part-of — api-service
onix-adapter — defines — modules + plugin chains + routing
onix-adapter — action-state-machine — transaction_properties.yaml
onix-adapter — routing-by — cookies (mock_url, subscriber_url) via jsonPath
onix-plugins — core — schemavalidator, ondc-validator, signvalidator, signer, cache, router, network-observability
onix-plugins — workbench-generated — workbench-main, workbench-keymanager, workbench-callback-redirect
signing-security — algorithm — Ed25519 over BLAKE-512 digest
signing-security — own-keys-from — env (SIGNING_PRIVATE/PUBLIC, ENCR_*)
signing-security — counterparty-keys-from — registry lookup
mock-service-embedded — part-of — api-service
mock-service-embedded — distinct-from — mock-playground-service
api-service — receiver-chain — ondcWorkbenchReceiver→addRoute→validateSchema→validateOndcPayload→validateContext→validateSign→validateOndcCallSave
w2w-testing — modes — same-instance both sides | instance-A↔instance-B
w2w-testing — signing — real (actual registry + signature verify, not bypassed)
w2w-testing — blind-spot — implicit common assumption not coded as explicit validation
w2w-testing — mitigation — NP-facing + negative/monkey testing
w2w-testing — explicit-validation-fix — future scope
flow-state-machine — txn-status — AVAILABLE | WORKING | SUSPENDED
flow-state-machine — step-phase — COMPLETE|LISTENING|RESPONDING|WAITING|INPUT-REQUIRED|PROCESSING|WAITING-SUBMISSION
flow-state-machine — actionable-phases — RESPONDING, INPUT-REQUIRED, WAITING-SUBMISSION
flow-state-machine — resolver-chain — sequenceResolver → extrasResolver → missedResolver
flow-state-machine — jobs — GENERATE_PAYLOAD_JOB, SEND_TO_API_SERVICE_JOB, API_SERVICE_FORM_REQUEST_JOB
flow-state-machine — stateless — no persistent step pointer (reduce apiList)
db-service — entity — Payload | SessionDetails | Report(GridFS) | User
db-service — spec-collections — META/FLOWS/ATTRIBUTES/DOCS/VALIDATIONS/CHANGELOG (by domain+version)
db-service — analytics — flowSummary(MANDATORY/OPTIONAL/REPORTABLE) + flowMap(PASS/FAIL)
session-difficulty — knobs — sensitiveTTL,useGateway,stopAfterFirstNack,protocolValidations,timeValidations,headerValidaton,useGzip
ui-frontend — external-dep — OSRM (routing), Nominatim (geocoding)
ui-frontend — auth-header-tool — BLAKE2b-512 + Ed25519
signing-security — digest — BLAKE2b-512 (not BLAKE2s)
backoffice — db-switch — Redis logical DB via /sessions/updatedb?db_id
backoffice — security — admin/admin + hardcoded JWT secret (local, insecure)
session — env-values — STAGING | PRE-PRODUCTION | LOGGED-IN
session — ttl — 48h ; expectation-ttl — 5min
udp — receives — all transaction logs in real time
udp — purpose — network-wide intelligence / analytics
udp — fed-by — recorder-service network-observability push (probable)
udp — maturity — concept + some pieces; many unknowns
mock-service-embedded — is — older static mock (fixtures, not 100% config-driven)
mock-service-embedded — config-shared-with-playground — no (separate/forked)
mock-playground-service — is — config-driven engine (@ondc/automation-mock-runner)
onix-router — fallback — none (500 error if routing cookie absent)
mock-playground — redis-db0 — workbench data ; redis-db1 — MockRunner config cache
mcp-runtime-agent — accessibility-lean — service layer (ui-backend/backoffice/db REST) over raw DB
spec-deprecation — scope — out of scope (for now)
w2w-fix — approach — owner builds KB → then agents/devs
automation-framework — submodule-count — 14 (was 9)
automation-libraries — member — automation-utils (build-tools = @ondc/build-tools)
automation-libraries — member — automation-api-service-generator
automation-libraries — member — automation-mock-runner-lib (@ondc/automation-mock-runner)
automation-libraries — member — automation-logger-package
user-management-service — is — git submodule (was external GHCR image)
form-service — direction — folding into mock-playground-service (standalone legacy)
report-service — enabled-key — domain:version (FIS13: domain:version:usecase)
report-service — usecase-gate — ENABLED_USECASES (TRV11 metro/bus)
report-service — flow-result — valid_flow ? PASS : FAIL
report-service — internal-validators — per-domain/version modules via ReportingConfig.yaml validationModules
report-pramaan — status — legacy plug (functional, not deprecated)
report-pramaan — callback — /callback/PW_${sessionId}, mochawesome suiteHasFailure → PASS/FAIL
report-service — flow-id-map — domain→version→usecase→flowName→pramaanFlowId
spec-authoring — key-artifacts — flow, examples, logic, L1 validations
openapi.yaml — derived-from — base Beckn schema
spec-attributes — origin — human input (schematic meaning, NOT ground truth; well-reviewed/cross-referenced)
spec-tags-enums — origin — human input (schematic meaning, not ground truth)
spec-seed — fills — gaps where base schema lacks info (exists in most cases)
L1-validations — quality — well-tested
spec-authoring — method — business spec → technical spec → YAML (enums/tags/examples/workflows)
build-tools — commands — parse, validate, gen-rag-table, push-to-db, gen-change-logs, gen-markdowns, gen-knowledge-book, polish
build-tools — validates-via — Zod BuildConfig + semantic (usecases, flow-configs via mock-runner)
build-tools — ingest-collections — build_meta/docs/flows/attributes/validations/changelog/validation_table
build.yaml — schema — openapi+info+paths+components+x-attributes+x-validations+x-errorcodes+x-supported-actions+x-flows+x-docs
api-service-generator — produces — schemas + adapter.yaml + go validationpkg + plugins + docker
api-service-generator — onix-base — ghcr.io/ondc-official/automation-beckn-onix:latest
mock-runner-lib — fn-generate — generate(defaultPayload,sessionData)→payload (45s)
mock-runner-lib — fn-validate — validate(target,sessionData)→{valid,code,description} (5s)
mock-runner-lib — fn-requirements — meetsRequirements(sessionData)→{valid,code,description} (3s)
mock-runner-lib — sandbox — VM + worker threads; no eval/require/process; fetch allowlist-gated (generate only)
mock-runner-lib — savedata — [APPEND#]key = JSONPath | EVAL#base64
mock-runner-lib — used-by — mock-playground-service
mock-runner-lib — not-used-by — mock-service-embedded (confirms static/older)
validation-compiler — aka — ondc-code-generator (automation-validation-compiler)
validation-compiler — xval-go — produces validationpkg (consumed by ondc-validator plugin)
validation-compiler — xval-rag — produces raw_table.json
ondc-validator-plugin — imports — validationpkg (PerformL1validations)
beckn-plugins — count — 12 (.so via buildplugins.sh, loaded by ONIX pluginManager)
beckn-onix-server-core — location — external repo automation-beckn-onix v1.5.0 (NOT in monorepo)
encryption-middleware — status — built but unwired in current adapter.yaml
user-management-service — role — GitHub OAuth + JWT auth + comments/notes annotation
user-management-service — db — developer_guide_db {users, exchange_codes, comments, notes}
user-management-service — not — developer-guide content provider
developer-guide-content — served-by — config-service / protocol specs
spec-lifecycle-status — flag-in — config-service / protocol specs (not user-management)
spec-lifecycle-status — values — released | drafted | to-be-deprecated | deprecated (frontend NavStatus)
spec-lifecycle-status — data-backed — NO (frontend placeholder; getNavStatus hardcoded "released")
spec-lifecycle-status — seam — add x-lifecycle to BuildConfig.info → build_meta → API → getNavStatus (not built)
ondc — is — open decentralized commerce network (Beckn-based, DPIIT India)
ondc — role — BAP | BPP | BG(gateway) | Registry | NO(network observability)
ondc — lifecycle — discovery → order → fulfillment → post-fulfillment + IGM + RSF
ondc — gateway — multicasts search only; optional (peer-to-peer if BPPs known)
ondc — registry — /subscribe,/on_subscribe(X25519 challenge),/lookup v1/v2,/vlookup; lookup-only
ondc — domain-code — ONDC:XYZ## (RET10 grocery, RET11 F&B, TRV10 mobility, FIS10 financial, LOG10 logistics)
ondc — NO-push — all payloads from on_search + sync responses, PII anonymized except city/pincode, automated
automation-framework — submodule-count — 16 (incl. validation-compiler, beckn-plugins)
logger-package — is — @ondc/automation-logger (Winston singleton)
logger-package — prod-sink — Grafana Loki (winston-loki, LOKI_HOST)
logger-package — correlation — X-Request-ID middleware
observability — prod-log-sink — Grafana Loki (via logger-package)
onix-server — is — automation-beckn-onix (server core, now in-repo)
onix-server — handler-type — std only (modules differ by steps/plugins/role)
onix-server — step-engine — linear, short-circuit on first error
onix-server — plugin-load — .so via plugin.Open → Lookup("Provider")
onix-server — ack — HTTP 200 {ack:ACK}
onix-server — nack-codes — schema 200 / sign 401 / bad-request 400 / not-found 404 / workbench-HTTP err.Code (412) / panic 500
onix-server — async-forward — post-response hook (ActAsProxy=false) + custom-response-body cookie
onix-server — keyset-from — Vault (AppRole) with cache fallback
api-service — http-status — decoupled from ACK/NACK (200 for both ACK and schema/L1 NACK)
api-service — malformed-ctx — 500 panic (nil message_id)
api-service — unknown-txn — 412 "No active expectation found"
automation-framework — infra — +gamification-db (postgres host 5433, runtime-observed)
ui-backend — known-bug — mock submodule skew: /mock/trigger 404 ⇒ ui-backend 500 (UI trigger broken)
session-difficulty — knob-count — 10 (incl encryptionValidation, useCare, useTunnelForFIS)
session-difficulty — propagation — each knob → same-named cookie OUTBOUND
router-fallback — runtime — receiver guard 400/412 (not router 500)
knowledge-keep-updated — loop — confirmed fix ⇒ frame slot + triple + ADR (note wrong assumption)
mock-fn-deploy — via — build-tools push-to-db + clear-flows (no api-service rebuild)
runtime-mcp — proposed — wb_trace_action + service-layer debug tools (not built)
mockTxnCaller — proxies-to — mock-playground-service (embedded mock = legacy/not runtime)
kb — separates — live/actual vs desired (scope: desired) features
desired-by-architect — holds — runtime-MCP, x-lifecycle, w2w-fix, all-branch-examples, deprecation, UDP, reporting-redesign
kb-rule — frontend — runtime-proven only (some FE code is legacy)
kb-rule — feature-scope — must align actual release + live code
config-service — cache — in-memory only (Redis unused by its code)
backoffice — db-switch — Redis logical DB index (RedisService.useDb)
form-serving — owned-by — mock-playground /forms locally (form-service legacy/external)
playground-flow — config-from — workbench cache0 PLAYGROUND_<sessionId> (not config-service)
onix-plugins — versioning — cloned per build by generator (not pinned to base image)
onix-keymanager — local — simplekeymanager env keys ; prod — keymanager Vault
extras-pairing — depth — 2-deep only (single pair, no A→B→C)
user-management — comments-notes — FE clients → /api/comments,/api/notes overlaid on guide content
recorder-NO-push — gate — env (NOURL + NOEnabledIn[env]; RECORDER_SKIP_NO_PUSH)
kb — purpose — low-token targeted debug (symptom→file:line, not full code reload)
kb-frame — linked-to — its repo+files (source); diff ⇒ revisit via kb-sync-on-diff
desired-by-architect — surfaced-as — role TODO for product/scrum/dev (never as shipped)
kb — commit-baseline — framework main @ 0e849ea + 17 submodule SHAs (2026-06-29)
kb-sync-on-diff — diff-base — references/kb-commit-baseline-2026-06-29.md
persona — role-profiles — Developer, SeniorDev, Architect, Tester, PM/Scrum, ProductOwner, QALead
workbench-kb-skill — seed-at — workbench-kb-skill-seed/SKILL.md (role-routed)
grill-me-kb — improvements — GRILL-ME-KB-IMPROVEMENTS.md (skill recs from this session)
spec-logic — comprises — requirement + generation + validation + L1 validation
spec-logic — core — L1 validation
spec-logic — governs — journey evolution (validation subset repeats as stage increases)
spec-logic — per-step-js — requirement(meet-requirements), generation(generate), validation(validate)
flow — is — possible journey (illustrated or operational)
examples — coverage — currently ~1 branch (may expand to all branches)
save-data-reuse — handles — mock session fullness
session-fullness — production — a subset defaulted commonly (not per-flow)
report-service — output-format — HTML only (no PDF/CSV)
report-service — enabled-domain — ONDC:LOG10 1.2.5
report-service — enabled-domain — ONDC:LOG11 1.2.5
report-service — enabled-domain — ONDC:FIS10 2.1.0
report-service — enabled-domain — ONDC:FIS11 2.0.0
report-service — enabled-domain — ONDC:FIS12 (2.0.1/2.0.2/2.0.3/2.2.0/2.2.1/2.3.0)
report-service — enabled-domain — ONDC:FIS13 2.0.1
report-service — enabled-domain — ONDC:TRV10 2.1.0
report-service — enabled-domain — ONDC:TRV11 (2.0.1/2.1.0)
report-service — enabled-domain — ONDC:TRV13 2.0.1
report-service — non-enabled-domain-routes-to — report-pramaan
registry-service — status — external placeholder (no local container)
ui-frontend — ai-proxy — generic SSRF-guarded forward proxy (x-proxy-target), no built-in LLM/MCP
automation-framework — submodules-pinned — detached HEAD specific commits (not main)
redis — key — transactionId::subscriberUrl (txn cache, DB0)
redis — key — MOCK_DATA::txn::sub (business data)
redis — key — FLOW_STATUS_txn::sub (TTL 5h)
redis — key — EXTRA_FLOW_STATUS_txn::sub::stepKey (TTL 5h)
redis — key — PLAYGROUND_sessionId (mock-runner config)
test-path — module — standaloneValidator (steps: validateSchema, validateOndcPayload)
test-path — http-status — 200 on ACK and on NACK; 500 only on malformed-context panic (nil message_id)
test-path — nack-shape — {message.ack.status:NACK, error.code:"Bad Request", error.message:"#### **CODE** + JSONPath"}
test-path — l1-gate — request header protocol_validation:true (default) enables L1
seller-path — module — BapTxnReceiver (7-step chain incl validateSign); buyer-path — module — BppTxnReceiver
mock-caller-path — module — mockTxnCaller (schema only, NO L1, outbound sign)
gamification-db — container — postgres:latest on host 5433 (net-new, not in core compose KB list)
router — fallback — no default URL fallback, but receiver guards routing input first (payloadutils.go)
route-target-source — inbound — context.bap_uri/bpp_uri by role; caller role falls back to ?subscriber_url= query param
mock-path-no-cookie — http-status — 400 NACK "bpp_uri is missing ... subscriber_url query param is also missing"
seller-path-no-txn — http-status — 412 NACK "No active expectation found for transaction ID ... as a seller_np"
workbench-cookies — direction — set OUTBOUND by setRequestCookies (utils.go); carry session+difficulty knobs to next hop
config-service — redis-writes — none (in-memory cache); DB1 flow-config cache owned by mock-playground-service
redis — key — {domain}::{version}::{flowId}::{usecase} (DB1 flow-config cache, mock-playground, TTL -1)
config-service — /ui/reporting — ONDC:FIS12/2.0.3 ⇒ {data:true} (reporting enabled)
config-service — /api-service/supportedActions — returns transaction_properties state machine (null→search→on_search→...)
ondc-validator — invokes — validationpkg.PerformL1validations (ondcvalidator.go:49)
l1-error-shape — CODE(UPPER_SNAKE) + JSONPath of offending field (e.g. REQUIRED_PAYMENT_COLLECTED_BY $.message.intent.payment.collected_by)
report-service — validators — /app/dist/validations/{DOMAIN}/{VERSION}/{Action}.js (per-action layer-4 re-validators)
session-difficulty — knobs — 10 (sensitiveTTL,useGateway,stopAfterFirstNack,protocolValidations,timeValidations,headerValidaton,useGzip,encryptionValidation,useCare,useTunnelForFIS)
session-difficulty — defaults — sensitiveTTL/useGateway/protocolValidations/timeValidations/headerValidaton=true; rest=false
session-difficulty — propagation — each knob → same-named cookie on outbound forwarded request (utils.go)
session-difficulty — protocol_validation — gates ondcvalidator L1 step (confirmed live)
session-difficulty — useGateway — routes search to GATEWAY_URL; useCare → issue/on_issue to CARE_URL; useTunnelForFIS → all via tunnel
ui-backend — submodule-skew — calls stale trigger/api-service/:action ⇒ 404 on current mock ⇒ UI flow-trigger broken (live)
mock — /flows/new — expectation-driven: creates expectation, "listening", no txn persisted until payload flows
seller-path — state-guard — unknown txn on /seller/on_search ⇒ 412 "No active expectation found ... as a seller_np" (out-of-sequence ⇒ no advance, confirmed live)
recorder — grpc-LogEvent — reachable live; rejects missing additionalData.subscriber_url with InvalidArgument
recorder — NO-middleware — fires per request, non-blocking (audit failure doesn't block the NACK)
session-key — redis — bare sessionId (DB0, TTL 48h) holds {transactionIds,flowMap,npType,domain,version,subscriberUrl,env,usecaseId,sessionDifficulty}
ui-backend — session-difficulty-defaults — TS: useGateway=false, stopAfterFirstNack=true (differ from Go defaultDifficulty)
signing — live-authorization — keyId="<sub_id>|<ukid>|ed25519",algorithm=ed25519,headers="(created) (expires) digest" (captured live)
signing — created-expires-window — 300s (created→expires)
recorder — db-save — action UPPERCASED, reqHeader stringified "{}", httpStatus 200
recorder — flow-status — FLOW_STATUS_ 5h NOT written on caller-only hop (receiver/full-flow path only)
recorder — txn-cache-ttl — RECORDER_CACHE_TTL_SECONDS_DEFAULT (local was 300s ⇒ flow dies after 5min; raised to 18000)
gold-loan-form — source — on_search xinput url = http://…:3031/mock/playground/forms/ONDC:FIS12/gold_loan_information_form/?transaction_id&session_id (mock self-serves form; needs live txn cache)
local-bap-id — required — host.docker.internal:3032 (WITH port) is intentional for local; on_search REGEX_CONTEXT_BAP_ID NACK expected, NOT a bug (owner)
local-flow-fix — protocol-validation-off — set sessionDifficulty.protocolValidations=false (UI "Protocol Validation" toggle) so local bap_id (host:port) isn't NACKed on on_search → catalog/form data saves → HTML-form populates
difficulty-ui — protocol-validation — toggle present in difficulty-cards.tsx (default true); NOT in skipItems, so user-visible

## Durable debug mechanisms (incident detail → adr-0048..0053 + references/w2w-debugging-depth-and-mcp-2026-06-29.md)
api-service — async-predecessor-check — message_id==predecessor enforced only on on_search/on_init/on_confirm (others null)
mock-playground — transaction_history — unpopulated (len 0) ⇒ MockRunner Priority2 dead; message_id echo relies on latestMessage_id (drifts with unsolicited on_status / w2w cross-side)
dynamic-form — completion — needs api-service /callback writing form_completed:{session} (via redirection_url:{path}→sessionId); HTML/redirect forms use it
secure-context — http://host.docker.internal is NOT secure ⇒ crypto.randomUUID/subtle unavailable; use http://localhost or https
api-step-input — config-service synthesizes UI input only for FORM steps; an API step's input: is ignored (no prompt without a form step)
local-bap-id — host.docker.internal:3032 (WITH port) is required for local; on_search REGEX_CONTEXT_BAP_ID NACK is expected, not a bug
local-w2w-recipe — recorder TTL 18000 + sessionDifficulty.protocolValidations=false (durable local-run prerequisites)
debug-heuristic — an on_X NACK is usually a mock-generation symptom (buildErrorPayload); check generation before the protocol NACK — see [[tester-playbook]]
mock-fn-deploy — build-tools push-to-db + clear-flows (no api-service rebuild for mock functions)
runtime-mcp — DESIRED (not built): wb_trace_action + service-layer debug tools — see [[desired-by-architect]]

## KB architecture / diagnostics
kb — layers — MAP, DIAGNOSTICS, COMPONENTS, RUNTIME/FLOW, SPEC, OPERATIONS, DESIRED, DECISIONS
navigator — entry-shape — signature → quick-checks → cause → fix-locus(file:line) → verify → related
navigator — seeded — d-001 on_X-NACK; d-002 flow-dies/empty-form; d-003 dynamic-form-stall; d-004 http-status-decode; d-005 ui-trigger-404; d-006 local-frontend-gotchas
debug-fast-path — rule — enter diagnostics first; load component frames only on drill-down
upkeep — after-debug — leave a diagnostics entry (single-lookup next time)
references — lifecycle — TEMPORARY: indexed → ingested → prune (run reports = short audit)
locator — is — durable scan-first map: concern → module → flows/methods(file:line) → frame (token reduction)
patterns — is — durable reusable failure-mode entries (patterns/fm-*)
tactical-logs — are — archivable in references (change/diff/release/incident; not a permanent layer)
kb-debug-fast-path — scan — LOCATOR.md first, then patterns/fm-*, then frame
