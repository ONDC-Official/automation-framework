# ONDC Protocol Workbench — Architecture Reference

**Audience:** CTO / Engineering Leadership  
**Date:** April 2026  
**Scope:** All repos under the ONDC Automation Framework umbrella

---

## 1. Executive Summary

The Protocol Workbench is a multi-repo, polyglot platform that enables ONDC network participants to **validate, simulate, and certify** their Beckn protocol implementations before going live. It covers the full lifecycle:

| Stage | Tooling |
|---|---|
| Spec authoring (YAML) | `automation-specifications` |
| Code generation from spec | `automation-api-service-generator` + `automation-validation-compiler` |
| Runtime protocol enforcement | `automation-beckn-onix` (Go HTTP server with plugin pipeline) |
| Mock counterparty simulation | `automation-mock-playground-service` |
| Audit / event capture | `automation-recorder-service` (Go gRPC) |
| Session & flow state | Redis via `ondc-automation-cache-lib` |
| Payload / session persistence | `automation-db` (MongoDB + YugabyteDB) |
| Validation reporting | `automation-report-service` |
| Developer UI | `automation-frontend` (React/Vite + Express BFF) |
| Back-office admin | `automation-backoffice` |
| Central config hub | `automation-config-service` |

---

## 2. Repository Map

```
automation-framework/                ← Root monorepo (npm workspaces + Docker Compose)
│
├── [git submodules — shared npm packages]
│   ├── automation-logger/            → publishes @ondc/automation-logger
│   ├── automation-mock-runner/       → publishes @ondc/automation-mock-runner
│   ├── automation-validation-compiler/ → publishes ondc-code-generator
│   │                                    (npm name ≠ directory name; generates TS + Go code)
│   ├── automation-utils/build-tools/ → publishes @ondc/build-tools  (CLI bin: ondc-tools)
│   └── automation-cache/             → README only in this repo.
│                                        ondc-automation-cache-lib is consumed from npm,
│                                        not built locally.
│
├── [git submodules — runtime services]
│   ├── automation-frontend/          → React UI + Express BFF (two workspaces)
│   ├── automation-backoffice/        → Admin React UI + Express backend
│   ├── automation-report-service/    → Validation report engine
│   └── automation-db/                → Dual-database persistence service
│
├── [git submodules — ONIX tooling]
│   ├── automation-api-service-generator/ → Build-time code generator (TypeScript)
│   │                                       npm name: api-service-generator
│   └── automation-beckn-onix/            → Go HTTP server (plugin runtime)
│
├── [local repos in monorepo — not submodules, not in docker-compose.yml]
│   ├── automation-config-service/    → Central YAML config server
│   ├── automation-form-service/      → Dynamic form service (npm name: form-service)
│   └── automation-mock-playground-service/ → Mock NP simulator
│                                            (npm name: ondc-playground-mock-service)
│
└── [deleted from monorepo — replaced by ONIX flow]
    ├── automation-api-service/       ❌ REMOVED — replaced by generated ONIX servers
    └── automation-mock-service/      ❌ REMOVED — replaced by mock-playground-service

Standalone (separate git repos, not in automation-framework):
    automation-recorder-service/      → Go gRPC audit recorder
    automation-specifications/        → Domain YAML spec source
```

---

## 3. Shared Package Dependency Map

These npm packages are the connective tissue of the monorepo. A change to any package requires a local rebuild before consuming services pick it up (changes propagate via symlinks in `node_modules/`).

```
Directory                          Published npm Name                  Consumers
──────────────────────────────────────────────────────────────────────────────────────────
automation-logger/                 @ondc/automation-logger             automation-report-service
                                                                        automation-frontend/backend
                                                                        automation-mock-playground-service
                                                                        automation-form-service

automation-mock-runner/            @ondc/automation-mock-runner        automation-mock-playground-service
                                                                        automation-config-service
                                                                        automation-utils/build-tools (runtime dep)
                                                                        automation-frontend/frontend (client)

automation-validation-compiler/    ondc-code-generator                 automation-api-service-generator
                                   ^^^^^^^^^^^^^^^^^^^                    (build-time — generates
                                   (not @ondc scoped!)                      L0 schemas + L1 TS + Go code)

automation-utils/build-tools/      @ondc/build-tools                   automation-api-service-generator
                                   CLI binary: ondc-tools               automation-specifications CI pipeline
                                   Depends on:                          (parse + validate build.yaml)
                                     @ondc/automation-mock-runner
                                     ondc-code-generator
                                   Peer dep: mongodb (optional)

automation-cache/                  ondc-automation-cache-lib           automation-frontend/backend
                                   (the dir here has only README.md;    automation-backoffice/backend
                                    package is consumed from npm)       automation-report-service
                                                                        automation-form-service
                                                                        automation-api-service-generator
```

**Note on version lock-in:** each consuming service pins a specific version in its own `package.json`. For local dev, npm workspaces override those pins with the local `dist/` via symlink — so the **local build always wins** over the npm version.

**Rebuild chain when a library changes:**

```
Edit automation-logger/src/
  └─ npm run build -w automation-logger   (recompiles dist/)
       └─ node_modules/@ondc/automation-logger symlink → updated dist/
            └─ Services using it pick up changes on restart (nodemon / Docker rebuild)

For Go-side code generation (automation-validation-compiler, npm: ondc-code-generator):
  npm run build -w automation-validation-compiler
    └─ Updates the ConfigCompiler library used by api-service-generator
         └─ Rerun api-service-generator to regenerate validationpkg/
              └─ Rebuild the Go binary (npm run build:onix or docker build)
```

**Key dependency chain (transitively):**

```
@ondc/automation-logger ──────► automation-report-service, automation-frontend/backend,
                                 automation-mock-playground-service, automation-form-service

@ondc/automation-mock-runner ─► automation-mock-playground-service, automation-config-service,
                             └─► @ondc/build-tools ─► api-service-generator
                                                       │
ondc-code-generator ──────────► @ondc/build-tools ────┤
                          └───► api-service-generator ◄─┘
                                                       │
                                                       ▼
                                          Generated domain API service
                                          (beckn-onix Go + validationpkg)

ondc-automation-cache-lib ────► all Node services that touch Redis
```

---

## 4. Two Architectures

The Workbench supports two deployment architectures. They share the same UI, persistence, and observability stack but differ in how the API service (protocol enforcer) is built.

---

### 4A. ONIX New Flow — Domain-as-Code Deployment

This is the **production architecture** for deploying a new ONDC domain. Each domain gets its own generated Go binary with domain-specific plugins baked in.

```
╔══════════════════════════════════════════════════════════════╗
║                    BUILD TIME (CI / Local)                    ║
╚══════════════════════════════════════════════════════════════╝

  automation-specifications/
  └── config/<domain>/<version>/
      ├── search.yaml, on_search.yaml, ...
      ├── flows/                      ← flow sequence definitions
      └── x-validations.yaml          ← L1 business rule definitions
             │
             ▼
  ondc-tools parse                     ← CLI from @ondc/build-tools
  (resolves index.yaml + $ref chain)
  └── outputs: build.yaml              (single merged file — schemas, L1 rules, flow defs,
                                        x-supported-actions, x-validations)
             │
             ▼
  ondc-tools validate                  ← zod-schema-validates build.yaml
             │
             ▼
  automation-api-service-generator     (TypeScript; reads build.yaml from
                                        src/config/build.yaml internal path)
  │
  ├── Uses ondc-code-generator (ConfigCompiler)
  │   ├── comp.generateCode(xValidations, "L1-validations")   → TS L1 validators
  │   ├── comp.generateL0Schema()                             → JSON Schemas per action
  │   └── CreateOnixServer()
  │       └── Generates: validationpkg/ (Go package)
  │           └── main-validator.go    ← PerformL1validations(action, payload, config, externalData)
  │                                        returns []ValidationOutput{Type, Valid, Description}
  │
  ├── Generates: schemas/<action>.json  (JSON Schema per ONDC action — for L0 validation)
  │
  ├── Generates: config/
  │   ├── adapter.yaml                 ← module definitions, plugin pipelines, HTTP config
  │   ├── form_router.yaml             ← routes HTML forms → recorder-service
  │   ├── mock_router.yaml             ← routes via subscriber_url cookie
  │   ├── np_router.yaml               ← routes via mock_url cookie
  │   ├── mock_no_config.yaml          ← gRPC config for recording mock calls
  │   └── np_no_config.yaml            ← gRPC config for recording NP calls
  │
  └── Generates: Dockerfile + docker-compose.yml
             │
             ▼
  Docker Build  (npm run build:onix)
  ├── Base image: ghcr.io/ondc-official/automation-beckn-onix:latest
  │   (Go HTTP server binary + 9 pre-compiled .so plugins)
  │
  └── Injected: schemas/, config/, validationpkg/ (compiled into ondcvalidator plugin)
             │
             ▼
  Docker Image pushed → EKS via ArgoCD  (one image per domain×version)
```

#### 4A.1 — The 9 Go Plugins (from automation-beckn-plugins)

Each plugin is a compiled `.so` file loaded at server startup via `pluginManager.root = "./plugins"`:

| Plugin ID | Responsibility |
|---|---|
| `schemavalidator` | Validates request body against generated JSON Schema (L0) |
| `ondcvalidator` | Runs generated `PerformL1validations()` — stateful ONDC protocol rules with Store interface |
| `workbench` | Connects to automation-config-service for session/flow state; validates context, timestamps, flow ordering; sets `subscriber_id` cookie |
| `signvalidator` | Validates `Authorization` Beckn signature header (ed25519) — skippable via `header_validation=false` cookie |
| `signer` | Signs outgoing requests with the workbench's ed25519 private key; generates `Signature keyId=...` header |
| `keymanager` | Stores and retrieves signing key pairs; looks up NP public keys from registry |
| `networkobservability` | Post-response middleware: sends audit event to automation-recorder-service via gRPC `LogEvent` |
| `router` | Determines target URL from YAML routing rules (jsonPath cookie extraction or static URL) |
| `cache` | Shared Redis state between plugins within a single request |

#### 4A.2 — The 5 HTTP Modules per Domain

Defined in `adapter.yaml`, each module is a URL path with a specific plugin pipeline:

```
Module             Path                                              Pipeline Steps
───────────────────────────────────────────────────────────────────────────────────────────
formReceiver       /api-service/{domain}/{version}/form/html-form    addRoute(form_router)
                                                                      → forward to recorder-service

standaloneValidator /api-service/{domain}/{version}/test/            validateSchema (L0)
                                                                      → validateOndcPayload (L1, stateless)

BapTxnReceiver     /api-service/{domain}/{version}/seller/           validateSign
                   (NP callbacks → workbench)                         → workbenchReceive
                                                                      → validateSchema (L0)
                                                                      → validateOndcPayload (L1)
                                                                      → validateOndcCallSave (persist state)
                                                                      → networkobservability (gRPC record)
                                                                      → ACK 200

BppTxnReceiver     /api-service/{domain}/{version}/buyer/            workbenchReceive
                   (workbench → NP)                                   → validateSchema (L0)
                                                                      → validateOndcPayload (L1)
                                                                      → validateOndcCallSave
                                                                      → addRoute (np_router via mock_url cookie)
                                                                      → sign (ed25519)
                                                                      → forward async → mock-playground
                                                                      → networkobservability (gRPC record)

mockTxnCaller      /api-service/{domain}/{version}/mock/             addRoute (mock_router via subscriber_url cookie)
                                                                      → sign → forward (proxy)
```

**Cookie-driven routing:** The frontend BFF injects routing context as cookies per request. No hardcoded service URLs exist in the protocol layer:

| Cookie | Source | Used By |
|---|---|---|
| `subscriber_url` | Session config | mock_router — routes to NP subscriber |
| `mock_url` | Session config | np_router — routes to mock-playground |
| `session_id` | Session creation | workbench, networkobservability |
| `ttl_seconds` | Session config | networkobservability (cache TTL) |
| `header_validation` | Per-request option | signvalidator (can disable) |
| `protocol_validation` | Per-request option | ondcvalidator (can disable) |

---

### 4B. Playground Testing Flow — Runtime Request Path

The developer testing flow — a tester uses the UI to simulate a full ONDC transaction end-to-end.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         TESTER'S BROWSER                            │
└────────────────────────────┬────────────────────────────────────────┘
                             │ HTTP :3035
                             ▼
                  ┌─────────────────────┐
                  │  automation-frontend │
                  │  frontend (React)    │◄── automation-config-service
                  └──────────┬──────────┘    GET /protocol/available-builds
                             │ REST           GET /ui/flow/{domain}/{version}
                             ▼
                  ┌─────────────────────┐
                  │  automation-frontend │
                  │  backend (Express)   │
                  │  :3034               │
                  │  • Sets cookies:     │
                  │    subscriber_url    │
                  │    mock_url          │
                  │    session_id        │
                  │    ttl_seconds       │
                  └──────┬──────┬───────┘
                         │      │
        /buyer/ or /seller/ path│  /mock/playground/ path
                         │      │
                         ▼      ▼
   ┌───────────────────────┐  ┌─────────────────────────────────────┐
   │  automation-beckn-onix│  │  automation-mock-playground-service  │
   │  Go HTTP Server :3032  │  │  TypeScript/Express :3031            │
   │                        │  │                                      │
   │  Per-request pipeline  │  │  Flow State Machine (Redis DB0+DB1)  │
   │  (see §4A.2)           │  │  Status: STARTED → WORKING →         │
   │                        │  │          SUSPENDED → COMPLETED       │
   │  workbenchReceive ─────┼──┼─► automation-config-service          │
   │  (GET /ui/flow)        │  │    GET /mock/{domain}/{version}       │
   │                        │  │                                      │
   │  validateSchema (L0)   │  │  Job Queue:                          │
   │  validateOndcPayload   │  │  GENERATE_PAYLOAD_JOB                │
   │  (L1 generated Go)     │  │  └── @ondc/automation-mock-runner    │
   │                        │  │      (generates ONDC payload)        │
   │  forward ──────────────┼──┼◄── SEND_TO_API_SERVICE_JOB           │
   │  (to mock via          │  │    (POST to /buyer/ or /seller/)      │
   │   np_router cookie)    │  │                                      │
   │                        │  │  HTML_FORM / DYNAMIC_FORM steps:     │
   │  networkobservability ─┼──┼─► API_SERVICE_FORM_REQUEST_JOB       │
   │  gRPC LogEvent ────────┼──┼──────────────────┐                   │
   └───────────────────────┘  └──────────────────┼───────────────────┘
                                                  │ gRPC :8089
                                                  ▼
                                   ┌──────────────────────────────┐
                                   │  automation-recorder-service  │
                                   │  Go gRPC                      │
                                   │                               │
                                   │  1. SYNC: Redis WATCH/MULTI   │
                                   │     atomic update             │
                                   │     Key: {txnId}::{subUrl}    │
                                   │     Appends API call to log   │
                                   │                               │
                                   │  2. ASYNC (worker pool):      │
                                   │     POST → automation-db      │
                                   │     POST → network observ.    │
                                   └──────────────┬───────────────┘
                                                  │ HTTP
                                                  ▼
                                   ┌──────────────────────────────┐
                                   │  automation-db :8080          │
                                   │  ├─ MongoDB (GridFS/Mongoose) │
                                   │  │  large payload blobs       │
                                   │  └─ YugabyteDB (TypeORM)      │
                                   │     Payload + SessionDetails  │
                                   └──────────────────────────────┘

     (tester requests report)
           │
           ▼
  automation-report-service :3000
     │ Reads Redis: {txnId}::{subUrl}  (written by recorder-service)
     │ Runs domain-specific validators
     │ src/validations/<domain>/<version>/
     └─► HTML validation report → browser
```

#### 4B.1 — automation-mock-playground-service: Dual Redis Architecture

```
Redis DB0 (WorkbenchCacheService)       Redis DB1 (ConfigCacheService)
────────────────────────────────        ──────────────────────────────
{txnId}::{subUrl}                       mock-runner configs per domain
  transactional event log               (cached from automation-config-service)
sessionDetails:{sid}
flowStates:{sid}
  current sequence step
  step status
  session data (JSONPath extracted)
```

#### 4B.2 — Form Steps

Two special step types outside the normal ONDC action pipeline:

| Type | Owner | Processing |
|---|---|---|
| `DYNAMIC_FORM` | Mock service generates the form | submission_id sent via `API_SERVICE_FORM_REQUEST_JOB` |
| `HTML_FORM` | External party's API response embeds form URL | Mock fetches HTML, runs security scan (blocks iframes, event handlers, javascript: URLs), rewrites relative action URLs, stores in session |

---

## 5. automation-config-service — Central Config Hub

Every runtime service depends on this for configuration. It is the single source of truth at runtime.

```
REST Endpoint                              Served From
─────────────────────────────────────────────────────────────────────
GET /ui/flow/{domain}/{version}            config/<domain>/<version>/flow/
GET /ui/reporting/{domain}/{version}       config/<domain>/<version>/reporting/
GET /ui/senario/{domain}/{version}         config/<domain>/<version>/scenarios/
GET /protocol/spec/:domain/:version        automation-specifications build outputs
GET /protocol/available-builds             all domain×version combinations
GET /mock/{domain}/{version}               mock runner payload templates
GET /api-service/{domain}/{version}        validation rules for api-service
```

**Consumers and purpose:**

| Consumer | What it fetches | When |
|---|---|---|
| beckn-onix workbench plugin | flow/session state config | per-request |
| mock-playground-service | flow definitions, payload templates | on flow start |
| automation-frontend/backend | available domains/versions | on session create |
| automation-report-service | domain reporting config | on report generation |

---

## 6. automation-recorder-service — Audit Trail (Go)

Sits as a post-response hook inside beckn-onix via the `networkobservability` plugin.

```
beckn-onix  →  gRPC: beckn.audit.v1.AuditService/LogEvent
               Payload (BytesValue):
               {
                 requestBody:    ONDC action payload
                 responseBody:   ACK / NACK
                 additionalData: {
                   payload_id, transaction_id, message_id,
                   subscriber_url, action, timestamp,
                   status_code, session_id, is_mock,
                   ttl_seconds, req_headers
                 }
               }

recorderServer.LogEvent()
  │
  ├─ Sync: Redis WATCH → GET → append action → SET  (8-attempt optimistic lock)
  │        Key: "{transaction_id}::{subscriber_url}"
  │        Stores: chronological list of all API calls in the transaction
  │
  └─ Async worker pool (configurable queue + workers):
       ├─ POST → automation-db  (MongoDB + YugabyteDB)
       └─ POST → network observability endpoint

HTTP endpoint (separate listener):
  POST /html-form  ← receives HTML form submissions from formReceiver module
```

---

## 7. automation-report-service — Validation Engine

```
GET /report?session_id=...
  │
  ├─ Reads Redis key: "{txnId}::{subUrl}"  (written by recorder-service)
  │
  ├─ Domain dispatch:
  │   src/validations/<domain>/<version>/
  │
  ├─ Shared validators (src/validations/shared/):
  │   contextValidator → baseValidator → commonValidations → domainValidator → formValidations
  │
  └─ Returns: { flow, actions: [{ action, errors[], warnings[] }] }

Supported domains:
  ONDC:TRV10, ONDC:TRV11, ONDC:TRV13
  ONDC:FIS10, FIS11, FIS12, FIS13
  ONDC:LOG10, LOG11
  nic2004:60232
```

---

## 8. Data Persistence

```
Store              Key / Entity              Owner                  Purpose
────────────────────────────────────────────────────────────────────────────────────
Redis DB0          {txnId}::{subUrl}         recorder-service       Live transaction log
                   sessionDetails:{sid}      frontend-backend       Session metadata
                   flowStates:{sid}          mock-playground        Flow state machine
Redis DB1          mock config               mock-playground        Config cache

MongoDB            GridFS files              automation-db          Binary payloads, uploads
YugabyteDB         Payload entity            automation-db          Structured API call records
(PostgreSQL        SessionDetails entity     automation-db          Session persistence
 port 5433)

Migrations: TypeORM (automation-db/src/migration/) — npm run migration:generate/run/revert
```

---

## 9. Observability

```
All Node.js services
  └─ @opentelemetry/sdk-node
       ├─ Traces → Jaeger (via OTLP HTTP exporter)
       └─ Metrics → Prometheus (via @opentelemetry/exporter-prometheus)

Node.js services → winston-loki / pino-loki → Loki → Grafana

beckn-onix (Go)
  └─ OpenTelemetry Go SDK
       Per-step metrics in HandlerMetrics:
       ├─ SignatureValidationsTotal    (label: status)
       ├─ SchemaValidationsTotal       (label: schema_version, status)
       └─ RoutingDecisionsTotal        (label: target_type)

automation-monitoring/
  Prometheus + Grafana + Loki + Alertmanager
  Loki Docker driver: grafana/loki-docker-driver:latest
```

---

## 10. Local Development

**Build order matters** — workspace packages have TypeScript `prepare` scripts that depend on each other:

```bash
# Step 1: install without triggering any prepare scripts
npm install --ignore-scripts

# Step 2: build shared packages in dependency order
npm run build -w automation-logger                 # → @ondc/automation-logger
npm run build -w automation-mock-runner            # → @ondc/automation-mock-runner
npm run build -w automation-validation-compiler    # → ondc-code-generator
npm run build -w automation-utils/build-tools      # → @ondc/build-tools (bin: ondc-tools)

# Shortcut for steps 1+2:
npm run setup

# Step 3: run the stack
./start.sh              # validates env files, then docker-compose up
./start.sh --rebuild    # force full Docker rebuild

# ONIX tooling
npm run build:onix       # builds beckn-onix Docker image locally
                         # (tag: automation-beckn-onix:local,
                         #  uses Dockerfile.adapter-with-plugins)
npm run build:generator  # builds api-service-generator
```

**⚠ Current docker-compose.yml state (April 2026):**
- Still references `./automation-api-service` and `./automation-mock-service` (both directories removed from the repo) — these blocks must be commented out or the directories restored before `docker compose up` succeeds.
- MongoDB is not declared but required by `automation-db` — run separately or add to compose.
- `automation-config-service`, `automation-form-service`, `automation-mock-playground-service`, `automation-recorder-service`, `automation-beckn-onix` are present as directories but **not yet wired into compose** — run standalone.

See `LOCAL_SETUP.md` for full setup instructions and current workarounds.

**Port map (intended final state):**

| Service | Host Port | URL / Protocol |
|---|---|---|
| Frontend UI | 3035 | http://localhost:3035 |
| Frontend Backend | 3034 | — |
| API Service (generated ONIX server, per domain) | 3032 | — |
| Mock Playground | varies per `.env` | — |
| Report Service | 3000 | — |
| Backoffice Frontend | 5100 | http://localhost:5100/backoffice-frontend |
| Backoffice Backend | 5200 | — |
| automation-db | 8080 | — |
| Config Service | 5556 (default) | — |
| Recorder Service | 8089 (gRPC), 8090 (HTTP) | gRPC |
| Redis | 6379 | — |
| YugabyteDB | 5433 | PostgreSQL |
| YugabyteDB Master UI | 7001 | http://localhost:7001 |
| MongoDB | 27017 | — |

---

## 11. Full System Architecture Diagram

```
  ┌─────────────────────────────────────────────────────────────────────────┐
  │                          DEVELOPER BROWSER                              │
  └──────────────────────────────┬──────────────────────────────────────────┘
                                 │ :3035
                    ┌────────────▼────────────┐
                    │  automation-frontend     │
                    │  frontend (React/Vite)   │
                    └────────────┬────────────┘
                                 │ REST
                    ┌────────────▼────────────┐
                    │  automation-frontend     │◄── automation-config-service
                    │  backend (Express BFF)   │    (domain list, flow config,
                    │  :3034                   │     available builds)
                    └──────┬───────────┬───────┘
                           │           │
                   /buyer/ │           │ /mock/playground/
                  /seller/ │           │
                           ▼           ▼
     ┌─────────────────────────┐  ┌──────────────────────────────────────┐
     │  automation-beckn-onix  │  │  automation-mock-playground-service   │
     │  Go HTTP Server :3032   │  │  TypeScript/Express :3031             │
     │                         │  │                                       │
     │  5 HTTP modules:        │  │  Flow State Machine                   │
     │  • formReceiver         │  │  ├─ Redis DB0: txn/session state      │
     │  • standaloneValidator  │  │  └─ Redis DB1: config cache           │
     │  • BapTxnReceiver       │  │                                       │
     │  • BppTxnReceiver       │  │  Job Queue (RabbitMQ / in-memory):    │
     │  • mockTxnCaller        │  │  GENERATE_PAYLOAD_JOB                 │
     │                         │  │  └─ @ondc/automation-mock-runner      │
     │  9 .so plugins:         │  │  SEND_TO_API_SERVICE_JOB              │
     │  schemavalidator (L0)   │  │  └─ POST → beckn-onix /buyer|seller/  │
     │  ondcvalidator  (L1) ◄──┼──┼─ Generated validationpkg (Go)         │
     │  workbench      ────────┼──┼─► automation-config-service           │
     │  signvalidator          │  │  API_SERVICE_FORM_REQUEST_JOB         │
     │  signer                 │  │                                       │
     │  keymanager             │  └──────────────────────────────────────┘
     │  networkobservability───┼──────────────────────────┐
     │  router                 │                          │ gRPC :8089
     │  cache                  │                          ▼
     └─────────────────────────┘        ┌─────────────────────────────┐
                                        │  automation-recorder-service │
                                        │  Go gRPC                     │
                                        │                              │
                                        │  Sync → Redis                │
                                        │  {txnId}::{subUrl}           │
                                        │                              │
                                        │  Async pool →                │
                                        └──────────────┬──────────────┘
                                                       │ HTTP
                                                       ▼
                                        ┌──────────────────────────────┐
                                        │  automation-db :8080          │
                                        │  MongoDB (GridFS/Mongoose)    │
                                        │  YugabyteDB (TypeORM) :5433  │
                                        └──────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────┐
  │  Redis :6379                                                          │
  │  DB0: {txnId}::{subUrl} — full transaction log (recorder writes)     │
  │       sessionDetails:{sid} — session metadata                        │
  │       flowStates:{sid} — mock flow state machine                     │
  │  DB1: mock-runner config cache                                        │
  └──────────────────────────────────────────────────────────────────────┘

  automation-report-service :3000
  └─ Reads Redis {txnId}::{subUrl} → runs domain validators → HTML report

  automation-backoffice :5100/:5200
  └─ Admin session/user/unit-test management
```

---

## 12. Domain Coverage

| Domain | Versions | Mock Config | Report Validators |
|---|---|---|---|
| ONDC:TRV11 (METRO, BUS) | 2.0.0, 2.0.1, 2.1.0 | ✅ | ✅ |
| ONDC:TRV10 | — | ✅ | ✅ |
| ONDC:TRV13 | — | — | ✅ |
| ONDC:FIS10–FIS13 | — | — | ✅ |
| ONDC:LOG10–LOG11 | — | — | ✅ |
| nic2004:60232 | — | — | ✅ |

---

## 13. Key Design Principles

1. **Spec-as-code:** All ONDC validation rules live in YAML (`automation-specifications`), not in service code. Adding a new domain requires only new YAML + a CI run — no service code changes.

2. **Generated enforcement:** The Go `PerformL1validations()` function is machine-generated from YAML rules via `automation-validation-compiler`. This eliminates human translation errors from spec to code.

3. **Plugin-pipeline architecture:** beckn-onix executes validation as a composable sequence of steps. Disabling a validation step (e.g., `protocol_validation=false` cookie) requires no code change — only config.

4. **Audit-first:** Every API call (mock or real) is recorded to Redis atomically by `automation-recorder-service` before the response returns. The report service has a complete, ordered event log without polling or re-fetching.

5. **Cookie-driven routing:** No hardcoded service URLs in the protocol enforcement layer. The frontend BFF injects routing context as cookies, allowing one beckn-onix binary to serve many sessions with different target endpoints simultaneously.

6. **Dual Redis DBs:** Separating transactional state (DB0) from mock configuration cache (DB1) prevents config cache churn from invalidating live transaction data.

7. **Build-time domain isolation:** Each domain×version produces a separate Docker image. One domain's L1 validation update never risks another domain's runtime behavior.
