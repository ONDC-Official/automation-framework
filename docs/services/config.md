# automation-config-service

## Overview

`automation-config-service` is the **central configuration hub** for the Protocol Workbench at runtime. Every other service — the mock playground, the protocol enforcement server (beckn-onix), the frontend, and the report service — calls this service to fetch domain-specific configuration: flow definitions, validation rules, available domain×version builds, mock payload templates, and UI rendering config. It acts as a single source of truth so that adding a new ONDC domain (by updating YAML files) is immediately reflected across all consumers without redeployment.

## Role in the Architecture

```
automation-frontend/backend  ──► GET /protocol/available-builds
automation-beckn-onix        ──► GET /api-service/{domain}/{version}  (workbench plugin)
automation-mock-playground   ──► GET /mock/{domain}/{version}
automation-report-service    ──► GET /ui/reporting/{domain}/{version}
```

All consumers call this service at runtime. It reads YAML files from its `config/` directory (populated from `automation-specifications`) and serves them as structured JSON.

## Default Port

`5556` (configurable via `PORT` env var)

## Tech Stack

- Language: TypeScript + Node.js
- Framework: Express 4
- Test framework: Jest

## Key Modules

| Module | Path | What it does |
|---|---|---|
| `index.ts` | `src/index.ts` | Entry point — starts Express server, registers routes |
| `app.ts` | `src/app.ts` | Express app factory — mounts middleware and routers |
| `routes/` | `src/routes/` | Route definitions: `/protocol`, `/ui`, `/mock`, `/api-service` namespaces |
| `controllers/` | `src/controllers/` | Request handlers — reads config files, transforms, and responds |
| `services/configService.ts` | `src/services/configService.ts` | Loads and caches YAML config files from `config/<domain>/<version>/` |
| `services/cacheService.ts` | `src/services/cacheService.ts` | In-memory LRU cache for loaded configs (avoids repeated file I/O) |
| `services/dbService.ts` | `src/services/dbService.ts` | Optional persistence integration for config metadata |
| `config/` | `src/config/` | Loaded YAML configs by domain/version; also includes RETeB2B test configs |
| `middleware/` | `src/middleware/` | Request logging, error handling, CORS |

## API Endpoints

| Endpoint | Method | Response | Consumed by |
|---|---|---|---|
| `/protocol/available-builds` | GET | List of all deployed domain×version combinations | Frontend BFF |
| `/protocol/spec/:domain/:version` | GET | Compiled `build.yaml` for the domain | CI tooling |
| `/ui/flow/{domain}/{version}` | GET | Flow step definitions for the UI | Frontend, beckn-onix workbench plugin |
| `/ui/reporting/{domain}/{version}` | GET | Reporting config (validation categories, display names) | Report service |
| `/ui/scenario/{domain}/{version}` | GET | Available test scenarios/use cases | Frontend |
| `/mock/{domain}/{version}` | GET | Mock runner YAML config (payload templates, save-data, inputs) | Mock playground service |
| `/api-service/{domain}/{version}` | GET | Validation rules and flow config for the API service | beckn-onix workbench plugin |

## External Dependencies

| Package | Purpose |
|---|---|
| `express` | HTTP server framework |
| `js-yaml` | Parses YAML config files into JavaScript objects |
| `json-schema-ref-parser` | Resolves `$ref` links within YAML configs before serving |
| `lodash` | Deep-merge and transformation utilities |
| `axios` | Fetches remote config dependencies if referenced by URL |
| `cors` | Enables cross-origin requests from the frontend (same Docker network in prod, different origins in dev) |
| `connect-redis` | Redis-backed session store (optional, for stateful config endpoints) |
| `dotenv` | Reads `PORT`, `REDIS_URL`, `CONFIG_DIR` env vars |
| `@ondc/automation-mock-runner` | Used to validate mock config structure before serving |
| `@opentelemetry/sdk-node` | OpenTelemetry SDK for traces and metrics |
| `jest` | Test runner for service-level tests |

## Internal Dependencies

| Package | Role |
|---|---|
| `@ondc/automation-mock-runner` | Validates mock config YAML structure at load time |

## Configuration (Environment Variables)

| Variable | Default | Description |
|---|---|---|
| `PORT` | `5556` | HTTP server port |
| `CONFIG_DIR` | `src/config` | Root directory for domain config files |
| `REDIS_URL` | — | Optional Redis URL for session state |
| `OTEL_EXPORTER_JAEGER_ENDPOINT` | — | Jaeger OTLP endpoint for distributed traces |

## How to Run

```bash
cd automation-config-service
npm install
npm run dev     # nodemon + ts-node (watch mode)
npm run build   # tsc + copyfiles → dist/
npm start       # node dist/index.js
```

## How to Run Tests

```bash
npm test          # Jest
npm run test:watch
npm run test:coverage
```

## Notes for Open Source

- Config files in `src/config/<domain>/<version>/` are the primary customization point. The service is domain-agnostic — it serves whatever YAML it finds.
- The `json-schema-ref-parser` step happens at serve time, not startup, so adding a new YAML file does not require a restart in development.
- In the Docker deployment, `automation-specifications` build outputs are volume-mounted or baked into the image so the config service always reflects the latest deployed spec.
