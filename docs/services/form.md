# automation-form-service

## Overview

`automation-form-service` is a lightweight Express service that **renders and processes dynamic HTML forms** for Protocol Workbench flow steps that require user input. When an ONDC flow step is of type `HTML_FORM` or `DYNAMIC_FORM`, the form is served by this service, rendered via EJS templates, and submitted back into the flow pipeline. It bridges the gap between static protocol flows and steps that need a developer to provide real-world data (e.g., entering a phone number, selecting a seat, or confirming a KYC form).

## Role in the Architecture

```
automation-mock-playground-service
    ↓ DYNAMIC_FORM step: generates form definition
    ↓ forwards to form-service
automation-form-service   ← THIS SERVICE
    ↓ renders HTML form (EJS template)
    ↓ user submits form
    ↓ POST → automation-beckn-onix /form/html-form
    ↓ → automation-recorder-service /html-form (gRPC-HTTP bridge)
```

It also reads and serves form state from Redis (via `ondc-automation-cache-lib`), so it knows which session a form belongs to and can validate the submission context.

## Default Port

Configurable via `PORT` env var (typically served behind beckn-onix `formReceiver` module)

## Tech Stack

- Language: TypeScript + Node.js
- Framework: Express 4
- Template engine: EJS
- Test framework: Jest

## Key Modules

| Module | Path | What it does |
|---|---|---|
| `index.ts` | `src/index.ts` | Entry point — starts Express server, connects to Redis |
| `routes/` | `src/routes/` | Route definitions: `GET /form/:session_id/:step_id`, `POST /form/submit` |
| `controllers/` | `src/controllers/` | Request handlers — fetches form config from Redis, renders EJS template |
| `services/` | `src/services/` | Form resolution logic — reads form definition from Redis, validates submission |
| `config/` | `src/config/` | Static form definitions and YAML config for known form types |
| `types/` | `src/types/` | TypeScript interfaces: `FormDefinition`, `FormField`, `FormSubmission` |
| `utils/` | `src/utils/` | URL construction helpers, field validation utilities |

## External Dependencies

| Package | Purpose |
|---|---|
| `express` | HTTP server framework |
| `ejs` | Template engine — renders dynamic form HTML from field definitions |
| `js-yaml` | Parses form definition YAML files from `src/config/` |
| `ondc-automation-cache-lib` | Redis client — reads form state and session data keyed by `session_id` |
| `axios` | Forwards form submission data to `automation-recorder-service` |
| `cors` | Enables cross-origin requests (forms may be embedded in iframes from different origins) |
| `copyfiles` | Copies `.yaml`, `.html`, `.css` assets to `dist/` during build (these are not compiled by TypeScript) |
| `dotenv` | Reads `PORT`, `REDIS_URL`, `RECORDER_URL` env vars |

## Internal Dependencies

| Package | Role |
|---|---|
| `@ondc/automation-logger` | Structured logger with Loki transport |
| `ondc-automation-cache-lib` | Reads form definitions and session state from Redis |

## Configuration (Environment Variables)

| Variable | Description |
|---|---|
| `PORT` | HTTP server port |
| `REDIS_URL` | Redis connection string (DB0 — same instance as all other services) |
| `RECORDER_URL` | Base URL of `automation-recorder-service` HTTP endpoint for form submission forwarding |

## How to Run

```bash
cd automation-form-service
npm install
npm run dev     # ts-node-dev (watch mode)
npm run build   # tsc + copyfiles → dist/ (copies yaml/html/css)
npm start       # node dist/index.js
```

## Form Step Flow

1. Mock playground encounters an `HTML_FORM` or `DYNAMIC_FORM` step in the flow.
2. It stores the form definition in Redis under a session-scoped key.
3. The form URL (pointing to this service) is embedded in the ONDC API response payload.
4. The developer's browser opens the form via beckn-onix's `formReceiver` module.
5. This service fetches the form definition from Redis, renders it via EJS.
6. The developer fills and submits the form.
7. The submission is forwarded to `automation-recorder-service` which stores it in the transaction log.

## Notes for Open Source

- EJS is used instead of React/Vite because form pages are served as server-rendered HTML that must work without any JavaScript build pipeline — they are opened directly in a browser from an ONDC callback URL.
- The `copyfiles` build step is important: EJS templates (`.html`), YAML configs, and CSS files live in `src/` but must be copied to `dist/` since TypeScript only transpiles `.ts` files.
- Form definitions are session-scoped and time-limited — they are stored in Redis with the session TTL, so stale form URLs naturally expire.
