# automation-report-service

## Overview

`automation-report-service` is the **validation report engine** for Protocol Workbench. Given a `session_id`, it reads the full transaction history from Redis (written by `automation-recorder-service`), runs it through a domain-specific validation pipeline, and returns a structured report listing every error and warning for each API call in the flow. This is what a developer sees when they click "View Report" in the UI — a clear breakdown of which ONDC protocol rules passed or failed, and why.

## Role in the Architecture

```
Developer (via UI) → GET /report?session_id=...
        ↓
automation-report-service   ← THIS SERVICE
    ↓ reads Redis: {txnId}::{subUrl}   (written by recorder-service)
    ↓ domain dispatch → src/validations/<domain>/<version>/
    ↓ runs validator chain:
        contextValidator → baseValidator → commonValidations → domainValidator → formValidations
    ↓ returns { flow, actions: [{ action, errors[], warnings[] }] }
```

## Default Port

`3000` (host and container)

## Tech Stack

- Language: TypeScript + Node.js
- Framework: Express 4
- Test framework: Mocha (domain validators) + Jest (unit tests)

## Key Modules

| Module | Path | What it does |
|---|---|---|
| `index.ts` | `src/index.ts` | Entry point — starts Express server |
| `routes/` | `src/routes/` | Route definitions: `GET /report`, `GET /validate` |
| `controllers/` | `src/controllers/` | Request handlers — fetches Redis data, dispatches to domain validator |
| `services/` | `src/services/` | Report generation orchestration — merges validator outputs into final report |
| `utils/` | `src/utils/` | Redis key construction helpers, error formatting, flow ordering |
| `validations/shared/` | `src/validations/shared/` | Shared validator logic reused across all domains: context, base, common, form validators |
| `validations/ONDC:TRV11/` | `src/validations/ONDC:TRV11/` | TRV11 (transit — metro/bus) domain validators per version (2.0.0, 2.0.1, 2.1.0) |
| `validations/ONDC:TRV10/` | `src/validations/ONDC:TRV10/` | TRV10 domain validators |
| `validations/ONDC:TRV13/` | `src/validations/ONDC:TRV13/` | TRV13 domain validators |
| `validations/ONDC:FIS10-13/` | `src/validations/ONDC:FIS1*/` | Financial services domain validators (FIS10, FIS11, FIS12, FIS13, FIS14) |
| `validations/ONDC:LOG10-11/` | `src/validations/ONDC:LOG1*/` | Logistics domain validators (LOG10, LOG11) |
| `validations/nic2004:60232/` | `src/validations/nic2004:60232/` | Retail domain validators |
| `validations/trv11/` | `src/validations/trv11/` | Legacy TRV11 validators (mocha test target) |
| `middleware/` | `src/middleware/` | Request logging, error handling, CORS |
| `types/` | `src/types/` | TypeScript interfaces: `ValidationError`, `ValidationReport`, `FlowAction` |
| `config/` | `src/config/` | Optional YAML config for domain-specific display names and rule categories |
| `templates/` | `src/templates/` | HTML report template (rendered server-side for browser view) |

## Validator Chain (per domain)

Each domain validator runs in sequence, and results are merged:

1. **contextValidator** — Validates `context` fields (domain, version, country, city, action, core version, bap_id, bpp_id, timestamps)
2. **baseValidator** — Common structural checks (message ID uniqueness, transaction ID consistency, TTL)
3. **commonValidations** — ONDC-wide business rules that apply across domains (provider catalog rules, fulfillment types)
4. **domainValidator** — Domain-specific rules unique to the vertical (TRV11: transit seat/pass rules; FIS: KYC flow rules; etc.)
5. **formValidations** — Validates form submission steps (HTML_FORM and DYNAMIC_FORM data integrity)

## Supported Domains

| Domain Code | Description | Versions with Validators |
|---|---|---|
| `ONDC:TRV11` | Public transit (metro, bus) | 2.0.0, 2.0.1, 2.1.0 |
| `ONDC:TRV10` | Cab/ride-hailing | ✅ |
| `ONDC:TRV13` | Air travel | ✅ |
| `ONDC:FIS10` | Loan / credit | ✅ |
| `ONDC:FIS11` | Insurance | ✅ |
| `ONDC:FIS12` | Mutual funds | ✅ |
| `ONDC:FIS13` | Investments | ✅ |
| `ONDC:FIS14` | Credit card | ✅ |
| `ONDC:LOG10` | Logistics (on-network) | ✅ |
| `ONDC:LOG11` | Logistics (off-network) | ✅ |
| `nic2004:60232` | Retail / grocery | ✅ |

## External Dependencies

| Package | Purpose |
|---|---|
| `express` | HTTP server framework |
| `ondc-automation-cache-lib` | Redis client — reads `{txnId}::{subUrl}` transaction logs |
| `js-yaml` | Parses domain-specific reporting config YAML files |
| `lodash` | Deep comparison and transformation utilities in validators |
| `joi` | Schema validation for report request parameters |
| `axios` | Fetches supplementary data from `automation-config-service` for reporting config |
| `prom-client` | Prometheus `/metrics` endpoint for report generation latency and error counts |
| `winston` | Structured logging |
| `winston-loki` | Ships logs to Grafana Loki |
| `@cucumber/cucumber` | BDD test runner (used for integration scenario tests) |
| `mocha` | Unit test runner for domain validator functions |
| `@opentelemetry/sdk-node` | OpenTelemetry SDK for distributed tracing |

## Internal Dependencies

| Package | Role |
|---|---|
| `ondc-automation-cache-lib` | Reads Redis keys written by `automation-recorder-service` |
| `@ondc/automation-logger` | Structured logger with Loki transport |

## Configuration (Environment Variables)

| Variable | Description |
|---|---|
| `PORT` | HTTP port (default: `3000`) |
| `REDIS_URL` | Redis connection string (must point to DB0 where transaction logs live) |
| `CONFIG_SERVICE_URL` | Base URL of `automation-config-service` for reporting config |
| `LOKI_URL` | Grafana Loki push endpoint |
| `OTEL_EXPORTER_JAEGER_ENDPOINT` | Jaeger OTLP endpoint |

## How to Run

```bash
cd automation-report-service
npm install
npm run dev     # nodemon + ts-node
npm run build   # tsc + copyfiles → dist/
npm start       # node dist/index
```

## How to Run Tests

```bash
npm test
# Runs mocha on src/validations/trv11/2.0.1/*.ts
# These are unit tests for individual TRV11 validator functions
```

## API

### `GET /report`

| Parameter | Type | Description |
|---|---|---|
| `session_id` | query | Session ID to generate report for |
| `transaction_id` | query | (Optional) Filter to a specific transaction |

Response:
```json
{
  "flow": "METRO_B2B",
  "actions": [
    {
      "action": "search",
      "errors": [{ "code": "CTX001", "message": "Missing bap_id in context" }],
      "warnings": []
    }
  ]
}
```

## Notes for Open Source

- Domain validators are isolated per `src/validations/<domain>/<version>/` — adding a new domain requires only creating a new directory with the validator chain, and no changes to the core service code.
- The `shared/` validators are intentionally generic — they handle fields that every ONDC domain shares. Domain-specific quirks go into the domain subdirectory only.
- The Mocha tests in `src/validations/trv11/2.0.1/` are validator unit tests, not service integration tests — they test the pure validation functions directly without an HTTP server.
