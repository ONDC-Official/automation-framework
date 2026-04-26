# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**Protocol Workbench** — an ONDC (Open Network for Digital Commerce) protocol testing and validation framework. Monorepo of TypeScript/Node.js microservices coordinated via Docker Compose, sharing Redis for state and YugabyteDB (PostgreSQL-compatible) for persistence.

## Services & Ports

| Service | Host Port | Internal Port | Description |
|---|---|---|---|
| `automation-api-service` | 3032 | 3000 | Core API: session management, ONDC protocol validation, forwarding |
| `automation-mock-service` | 3031 | 8000 | Mock NP simulator; Swagger UI at `/api-docs` |
| `automation-report-service` | 3000 | 3000 | Validation reporting with domain-specific flow checks |
| `automation-frontend/frontend` | 3035 | 5001 | React/Vite UI |
| `automation-frontend/backend` | 3034 | 5000 | UI backend (Express) |
| `automation-backoffice/frontend` | 5100 | 5001 | Backoffice React/Vite UI (built with `--base=/backoffice/`) |
| `automation-backoffice/backend` | 5200 | 5000 | Backoffice Express backend |
| `automation-db` | 8080 | 8080 | MongoDB (GridFS via Mongoose) + YugabyteDB (TypeORM) |
| Redis | 6379 | 6379 | Shared cache (all services use `RedisService.useDb(0)`) |
| YugabyteDB | 5433 | 5433 | PostgreSQL API; Master UI :7001, TServer UI :9000 |

Access points after `docker-compose up`:
- Automation UI: http://localhost:3035
- Backoffice: http://localhost:5100/backoffice-frontend
- Mock Swagger: http://localhost:3031/api-docs

## Commands

### Full Stack

```bash
# Preferred — handles submodule init, env file checks, and Docker:
./start.sh              # incremental build
./start.sh --rebuild    # force full rebuild
./start.sh --detach     # run in background

# Or directly:
git submodule update --init --recursive
docker-compose up --build
```

### npm Workspaces (Shared Packages)

The root `package.json` declares npm workspaces. Run `npm install` once from the repo root — npm symlinks all `@ondc/*` workspace packages into `node_modules/` so consumer services resolve them locally without hitting the registry.

```bash
# One-time from repo root — installs all workspaces and creates symlinks
npm install

# Build all shared packages before running any service locally
npm run build:packages
# This compiles: automation-cache, automation-logger, automation-mock-runner,
#                automation-validation-compiler (ondc-code-generator)

# Watch mode for shared packages during development
npm run dev:packages
```

Workspace packages and their npm names:
| Directory | npm name | Role |
|---|---|---|
| `automation-cache` | `ondc-automation-cache-lib` | Redis state shared by all services |
| `automation-logger` | `@ondc/automation-logger` | Winston wrapper with Loki shipping |
| `automation-mock-runner` | `@ondc/automation-mock-runner` | Core mock engine: YAML templates, JSONPath, L2 validation |
| `automation-validation-compiler` | `ondc-code-generator` | TypeScript code generator from `build.yaml` (L0 schemas, L1 validators, action selectors) |
| `automation-utils/build-tools` | `@ondc/build-tools` | CLI for the spec pipeline: `parse`, `validate`, `gen-rag-table`, `push-to-db` |

### Individual Services (TypeScript — api, mock, report, db, backoffice/frontend backends)

```bash
cd <service-dir>
npm install
npm run dev     # nodemon + ts-node (watch mode)
npm run build   # tsc + copyfiles for yaml/html/css assets
npm start       # run compiled dist/
```

### Frontend (React/Vite)

```bash
# automation-frontend/frontend  or  automation-backoffice/frontend
npm run dev           # Vite dev server
npm run build         # tsc + vite build
npm run lint          # ESLint
npm run lint:fix      # ESLint with auto-fix
npm run format        # Prettier (frontend only)
npm run format:check  # Prettier check (frontend only)
```

### automation-recorder-service (Go)

```bash
cd automation-recorder-service
go run .                        # run directly
go build -o automation-recorder # compile binary
go test ./...                   # all tests (uses miniredis, no external deps needed)
docker-compose up --build       # Docker
```

### automation-utils/build-tools (CLI)

```bash
cd automation-utils/build-tools
npm run dev          # run with tsx (no build needed): npx tsx src/index.ts <cmd>
npm run build        # compile TypeScript → dist/
npm run typecheck    # type-check without emitting
npm test             # Jest + ESM (NODE_OPTIONS='--experimental-vm-modules')
npm run test:watch
npm run test:coverage

# Run a single test file:
NODE_OPTIONS='--experimental-vm-modules' npx jest tests/store/ingest.test.ts

# Use dev mode to avoid rebuilding during development:
npx tsx src/index.ts parse -i ../automation-specifications/config -o ./build.yaml
```

### Database Migrations (automation-db — YugabyteDB/TypeORM entities)

```bash
cd automation-db
npm run migration:generate   # generate from entity changes (Payload, SessionDetails)
npm run migration:run        # apply migrations
npm run migration:revert     # revert last migration
```

Note: `synchronize: true` is set in `data-source.ts`, so schema is auto-synced in dev. The MongoDB connection (GridFS) is configured separately via `MONGO_URI`.

### Tests

```bash
# automation-report-service — mocha on TRV11 validators
cd automation-report-service
npm test    # mocha -r ts-node/register src/validations/trv11/2.0.1/*.ts

# automation-config-service — Jest
cd automation-config-service
npm test              # jest
npm run test:watch
npm run test:coverage

# automation-utils/build-tools — Jest + ESM
cd automation-utils/build-tools
npm test
NODE_OPTIONS='--experimental-vm-modules' npx jest tests/store/ingest.test.ts  # single file

# automation-recorder-service — Go
cd automation-recorder-service
go test ./...
```

## Architecture

### Request Flow

1. **Frontend** (`automation-frontend`) — user triggers a flow test or schema validation
2. **automation-api-service** — orchestrates sessions, forwards ONDC API calls; the public route `/:action` pipelines through: signature validation → L0 schema (AJV + JSON Schema) → L1 custom rules (`x-validations.yaml`) → forward to mock; the private route `/api-service/mock/:action` handles responses coming back from the mock
3. **automation-mock-service** — simulates the counterparty NP; `flow-mapping-service.ts` tracks which flow step is active (LISTENING / RESPONDING / INPUT-REQUIRED / WAITING-SUBMISSION); responds to flow triggers via `/trigger` and `/manual` routes
4. **automation-report-service** — reads transaction data from Redis, runs domain-specific validators, returns structured reports
5. **automation-db** — persists data to both **MongoDB** (GridFS via Mongoose, for payloads/files) and **YugabyteDB** (TypeORM, for `Payload` and `SessionDetails` entities)

### Validation Layers (automation-api-service)

- `src/validations/L0-schemas/` — JSON Schema files per ONDC action (search, select, init, confirm, …)
- `src/validations/L0-validations/` — AJV-based schema validators, one file per action
- `src/validations/L1-validations/` — ONDC-specific rule validators; `index.ts` dispatches to per-action files in `api-tests/`; rules are driven by `x-validations.yaml` in `automation-config-store`

### Mock Response Generation (automation-mock-service)

Mock responses are entirely YAML-driven under `src/config/mock-config/<DOMAIN>/<USECASE>/<VERSION>/`:

```
factory.yaml          ← registry mapping action_id → action + default YAML file
action-selector (generated TS)  ← evaluates conditions, picks the correct code variant
<action>/default.yaml ← static ONDC response template
<action>/save-data.yaml  ← JSONPath extractions from incoming request, stored in Redis
<action>/inputs.yaml  ← fields the user must fill in (for INPUT-REQUIRED steps)
```

`generated/action-selector/`, `generated/default-selector/`, and `generated/L2-validations/` are TypeScript files produced by `ondc-code-generator` (`automation-validation-compiler`) — **do not edit by hand**.

### Report Service Domain Validators

Located at `src/validations/<domain>/<version>/`. Supported domains:

```
ONDC:TRV10, ONDC:TRV11, ONDC:TRV13
ONDC:FIS10–FIS13
ONDC:LOG10–LOG11
nic2004:60232
```

Shared logic (context, base, common, form, domain validators) lives in `src/validations/shared/`.

### automation-specifications Pipeline (Domain → Running Service)

`automation-specifications` is a git submodule. Each domain lives on its own `draft-<DOMAIN>-<VERSION>` branch with a `config/` folder. The CI/CD pipeline (`deploy-eks.yml`) does:

```
config/ ($ref-linked YAMLs)
  → @ondc/build-tools parse        → build.yaml  (single resolved file)
  → @ondc/build-tools validate     → schema + semantic checks
  → @ondc/api-service-generator    → build-output/  (generated Node.js API service)
  → docker build ./build-output    → image pushed to GHCR
  → automation-iac values.yaml     → ArgoCD deploys to EKS
```

To run this pipeline locally (on any `draft-*` branch):

```bash
cd automation-specifications
git checkout draft-RET18-1.2.5   # any draft-* branch

# Use the locally built binary
node ../automation-utils/build-tools/dist/index.js parse -i config -o build.yaml
node ../automation-utils/build-tools/dist/index.js validate -i build.yaml

# Generate the API service (requires ~/automation-api-service-generator built)
node ~/automation-api-service-generator/dist/index.js --config ./build.yaml
# Output lands in build-output/automation-api-service/

cd build-output/automation-api-service && npm install && npm run dev
```

### automation-recorder-service (Go)

Standalone gRPC microservice that intercepts ONDC audit events from the beckn-onix network-observability plugin.

- **gRPC** on `:8089` — `AuditService.LogEvent(BytesValue) -> Empty`
- **HTTP** on `:8090` — `POST /html-form`, `GET /health`

On each `LogEvent`: synchronously updates Redis transaction cache via WATCH/MULTI/EXEC (up to 8 retries), then asynchronously (buffered channel + worker pool) pushes logs to Network Observability and saves payload to automation-db. NO push and DB save can be disabled per environment via `RECORDER_NO_ENABLED_ENVS` / `RECORDER_DB_ENABLED_ENVS`.

### State / Cache

All session and flow state flows through Redis via the `ondc-automation-cache-lib` npm package (submodule at `automation-cache/`). Each service calls `RedisService.useDb(0)` at startup.

Redis key patterns:
```
{transaction_id}::{subscriber_url}   — TransactionCache (full API history + flow state)
sessionDetails:{session_id}          — session config cache
flowStates:{session_id}              — current flow state per flow
```

### Observability (`automation-monitoring/`)

Prometheus + Grafana + Loki (log aggregation via `winston-loki` / `pino-loki`) + Alertmanager. Services use OpenTelemetry (`@opentelemetry/sdk-node`). To enable Loki log shipping, install the Loki Docker driver:

```bash
docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
```

Then add logging config to each service in `docker-compose.yml`:

```yaml
logging:
  driver: loki
  options:
    loki-url: "http://loki:3100/loki/api/v1/push"
```

## Environment

- Docker: `docker-env/` holds per-service `.env` files — `api-service.env`, `mock-service.env`, `report-service.env`, `automation-backend.env`, `back-office.backend.env`, `automation-db.env`; the frontend reads `automation-frontend/frontend/docker.env`
- `start.sh` validates that all required env files are present before starting
- `automation-db` needs `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`, `DB_NAME` (YugabyteDB) and `MONGO_URI` (MongoDB)
- YugabyteDB database `my_app` is created automatically by `scripts/init-db.sh` on first container start
- Node.js v18+ (v20+ for `automation-utils/build-tools`); TypeScript 5.x; Go 1.24 (recorder service)
