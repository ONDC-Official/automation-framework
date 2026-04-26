# automation-mock-playground-service

## Overview

`automation-mock-playground-service` is the **mock counterparty NP (Network Participant) simulator** for Protocol Workbench. It plays the role of the other side in an ONDC transaction — if a developer is testing a buyer app, the mock service acts as the seller; if testing a seller app, it plays the buyer. It drives a full flow state machine step-by-step, generating ONDC-compliant response payloads via the `@ondc/automation-mock-runner` library and sending them to the API service in sequence.

## Role in the Architecture

```
Developer (via UI)
    ↓ trigger flow step
automation-frontend/backend
    ↓ POST /mock/playground/{action}
automation-mock-playground-service   ← THIS SERVICE
    ↓ generates response payload
    ↓ POST /buyer/ or /seller/
automation-beckn-onix (ONIX server)
    ↓ validate + record
```

The mock service maintains a **flow state machine** per session:

```
STARTED → WORKING → SUSPENDED (INPUT-REQUIRED) → WORKING → COMPLETED
```

Two Redis databases are used:
- **DB0** (`WorkbenchCacheService`): Transactional state — `{txnId}::{subUrl}`, `sessionDetails:{sid}`, `flowStates:{sid}`
- **DB1** (`ConfigCacheService`): Mock runner config cache — fetched from `automation-config-service` and cached per domain×version

## Default Port

Configurable via `PORT` env var (typically `3031`)

## Tech Stack

- Language: TypeScript (CommonJS), Node.js
- Framework: Express 5
- Queue: RabbitMQ (`amqplib`) with in-memory fallback
- Test framework: Jest

## Key Modules

| Module | Path | What it does |
|---|---|---|
| `index.ts` | `src/index.ts` | Entry point — initializes Redis connections, queue, starts Express server |
| `server.ts` | `src/server.ts` | Express app factory — mounts middleware, registers routes |
| `routes/` | `src/routes/` | Route definitions: `/mock/playground/`, `/trigger`, `/manual`, `/status` |
| `controllers/` | `src/controllers/` | Request handlers for trigger, manual input, and status endpoints |
| `service/flows/` | `src/service/flows/` | Flow orchestration logic — manages state transitions, step sequencing |
| `service/jobs/` | `src/service/jobs/` | Job implementations: `GENERATE_PAYLOAD_JOB`, `SEND_TO_API_SERVICE_JOB`, `API_SERVICE_FORM_REQUEST_JOB` |
| `service/backdoor-service.ts` | `src/service/backdoor-service.ts` | Internal service for direct state inspection/override (debugging) |
| `service/forms/` | `src/service/forms/` | Handles HTML_FORM and DYNAMIC_FORM step types |
| `service/cache/` | `src/service/cache/` | Redis client wrappers: `WorkbenchCacheService` (DB0) and `ConfigCacheService` (DB1) |
| `queue/InMemoryQueue.ts` | `src/queue/InMemoryQueue.ts` | In-memory job queue — used when RabbitMQ is not available |
| `queue/RabbitMQ.ts` | `src/queue/RabbitMQ.ts` | RabbitMQ-backed job queue — used in production for durable job processing |
| `queue/IQueueService.ts` | `src/queue/IQueueService.ts` | Queue interface — implementations are swappable (in-memory vs RabbitMQ) |
| `container/` | `src/container/` | Dependency injection container — wires services, queue, cache at startup |
| `middlewares/` | `src/middlewares/` | Request logging, error handling, Zod validation middleware |
| `types/` | `src/types/` | TypeScript interfaces: `FlowState`, `SessionData`, `JobPayload`, `StepConfig` |
| `utils/` | `src/utils/` | HTML security scanner (blocks iframes/JS), URL rewriter for HTML_FORM steps |
| `constants/` | `src/constants/` | Flow step type names, job type names, Redis key patterns |
| `errors/` | `src/errors/` | Custom error classes for flow and session errors |
| `env.ts` | `src/env.ts` | Zod-validated environment variable schema — fails fast on missing config |

## Form Step Types

Two special flow step types are outside the normal ONDC action pipeline:

| Type | Description |
|---|---|
| `DYNAMIC_FORM` | Mock service generates the form itself; submission ID is forwarded via `API_SERVICE_FORM_REQUEST_JOB` |
| `HTML_FORM` | External party's API response embeds a form URL; mock fetches HTML, runs security scan (blocks iframes, event handlers, `javascript:` URLs), rewrites relative action URLs, stores in session |

## External Dependencies

| Package | Purpose |
|---|---|
| `express` | HTTP server framework (v5) |
| `ioredis` | Redis client — manages DB0 (transactional) and DB1 (config cache) connections |
| `amqplib` | RabbitMQ AMQP client for durable job queuing |
| `axios` | HTTP client — sends generated payloads to the ONIX API service |
| `cheerio` | HTML parser — used in the security scanner to inspect and sanitize HTML_FORM content |
| `jsonpath` | JSONPath query engine for extracting values from incoming ONDC payloads |
| `zod` | Runtime validation for environment variables and request bodies |
| `pino` / `pino-http` / `pino-pretty` | Structured JSON logging (faster than Winston for high-throughput) |
| `pino-loki` | Ships pino logs to Grafana Loki |
| `prom-client` | Prometheus metrics endpoint (`/metrics`) |
| `ejs` | Template engine for rendering dynamic form HTML |
| `dotenv` | Reads env vars from `.env` |

## Internal Dependencies

| Package | Role |
|---|---|
| `@ondc/automation-logger` | Structured logger with Loki transport |
| `@ondc/automation-mock-runner` | **Core mock engine** — generates ONDC-compliant response payloads from YAML templates |

## Configuration (Key Environment Variables)

| Variable | Description |
|---|---|
| `PORT` | HTTP server port |
| `REDIS_URL` | Redis connection string (DB0 for transactional state) |
| `REDIS_CONFIG_URL` | Redis connection string for DB1 (config cache) |
| `RABBITMQ_URL` | RabbitMQ connection string (optional — falls back to in-memory queue) |
| `API_SERVICE_URL` | Base URL of the ONIX API service (e.g., `http://automation-beckn-onix:3032`) |
| `CONFIG_SERVICE_URL` | Base URL of `automation-config-service` (e.g., `http://automation-config-service:5556`) |
| `LOKI_URL` | Grafana Loki push endpoint |

## How to Run

```bash
cd automation-mock-playground-service
npm install
npm run dev      # nodemon + tsx (watch mode)
npm run build    # tsc → dist/
npm start        # node dist/index.js
```

## How to Run Tests

```bash
npm test
npm run test:cov     # with coverage
npm run type-check   # tsc --noEmit
```

## Notes for Open Source

- The RabbitMQ queue is optional. Set `RABBITMQ_URL` to enable it; otherwise the in-memory queue runs automatically.
- The HTML security scanner in `utils/` strips any `<iframe>`, inline event handlers (`onclick=`, etc.), and `javascript:` URLs from externally fetched HTML forms before displaying them to the user — this is a deliberate XSS protection measure.
- The Zod-validated `env.ts` means the service will fail to start rather than silently running with missing config — making misconfiguration errors obvious in CI.
