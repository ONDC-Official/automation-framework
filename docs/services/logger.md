# automation-logger

## Overview

`automation-logger` is a shared npm package (`@ondc/automation-logger`) that provides a standardized, structured logging interface for all Node.js services in the Protocol Workbench. It wraps Winston with Loki shipping support, console colorization, and a consistent log format so every service produces uniform, queryable logs.

## Role in the Architecture

This is a **foundational shared library** — every Node.js service that writes logs imports this package. It is a git submodule compiled at the workspace root. Changes to this package require a rebuild (`npm run build -w automation-logger`) before consuming services pick them up.

**Consumers:**
- `automation-report-service`
- `automation-frontend/backend`
- `automation-mock-playground-service`
- `automation-form-service`
- `automation-db`

## npm Package Name

`@ondc/automation-logger` — version `1.1.0`

## Tech Stack

- Language: TypeScript → compiled to `dist/`
- Runtime: Node.js ≥ 18

## Key Modules

| Module | Path | What it does |
|---|---|---|
| `index.ts` | `src/index.ts` | Entry point — exports `createLogger()` factory and `Logger` type |
| `winston/` | `src/winston/` | Winston transport configuration: console (colorized via `cli-color`) + Loki HTTP transport |
| `middleware/` | `src/middleware/` | Express request-logging middleware built on top of the logger |
| `workflow-utils/` | `src/workflow-utils/` | Utility helpers for structured log context (transaction ID, session ID tagging) |
| `types/` | `src/types/` | TypeScript interfaces for log options and transport config |

## External Dependencies

| Package | Purpose |
|---|---|
| `winston` | Core logging framework — transports, log levels, formatting |
| `winston-loki` | Winston transport that ships log lines to Grafana Loki via HTTP push |
| `cli-color` | Colorizes console output for human-readable local dev logs |
| `axios` | HTTP client used internally by the Loki transport to push log batches |
| `dotenv` | Reads `LOKI_URL`, `LOG_LEVEL`, and `SERVICE_NAME` from `.env` at startup |

## Internal Dependencies

None — this package has no dependencies on other workspace packages.

## Configuration (Environment Variables)

| Variable | Default | Description |
|---|---|---|
| `LOKI_URL` | — | Grafana Loki push endpoint (e.g., `http://loki:3100/loki/api/v1/push`) |
| `LOG_LEVEL` | `info` | Minimum log level (`debug`, `info`, `warn`, `error`) |
| `SERVICE_NAME` | — | Label added to every Loki log line for filtering by service |

## How to Build

```bash
cd automation-logger
npm install
npm run build       # compiles TypeScript → dist/

# Watch mode during development
npm run dev         # tsc --watch
```

## How to Use in a Service

```typescript
import { createLogger } from "@ondc/automation-logger";

const logger = createLogger({ serviceName: "my-service" });
logger.info("Server started", { port: 3000 });
logger.error("Unhandled error", { err });
```

## Notes for Open Source

- The Loki transport is opt-in via `LOKI_URL`. If not set, logs go to console only.
- `winston-loki` uses HTTP chunked batching — no Promtail agent is required.
- The `cli-color` colorization is disabled automatically when `NODE_ENV=production` or when stdout is not a TTY.
