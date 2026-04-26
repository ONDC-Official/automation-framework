# automation-mock-runner

## Overview

`automation-mock-runner` is a shared npm library (`@ondc/automation-mock-runner`) that provides the **core mock payload generation engine** for Protocol Workbench. Given an ONDC action and a set of YAML templates, it resolves JSONPath expressions, applies conditional logic, validates outputs against JSON Schema, and returns a fully formed ONDC-compliant response payload. It is the brain behind the mock service's ability to generate realistic counterparty responses without manual payload crafting.

## Role in the Architecture

This is a **build-time and runtime shared library**. It is used:
- At **runtime** inside `automation-mock-playground-service` to generate mock payloads step-by-step during a flow test.
- At **runtime** inside `automation-config-service` to resolve and serve mock runner config to clients.
- At **build time** inside `@ondc/build-tools` (the spec pipeline CLI) when generating flow definitions.
- In the **browser** — the library also compiles to a browser bundle (`webpack.config.js`) for client-side use in `automation-frontend/frontend`.

## npm Package Name

`@ondc/automation-mock-runner` — version `1.3.45`

## Tech Stack

- Language: TypeScript → compiled to `dist/`
- Runtime: Node.js ≥ 18, also runs in browser (via webpack bundle)
- Test framework: Jest

## Key Modules

| Module | Path | What it does |
|---|---|---|
| `index.ts` | `src/index.ts` | Public API — exports `MockRunner`, `runMock()`, and all types |
| `lib/` | `src/lib/` | Core mock engine: payload templating, JSONPath resolution, conditional evaluation |
| `lib/configHelper.ts` | `src/lib/configHelper.ts` | Loads and validates mock YAML config files per domain/version |
| `lib/MockRunner.ts` | `src/lib/MockRunner.ts` | Orchestrates the full mock generation flow: extract → transform → validate → emit |
| `lib/runners/` | `src/lib/runners/` | Pluggable runner strategies (default, conditional, multi-step) |
| `lib/validators/` | `src/lib/validators/` | AJV-based JSON Schema validators for output verification |
| `lib/worker/` | `src/lib/worker/` | Web Worker wrapper for browser-side async execution |
| `lib/utils/` | `src/lib/utils/` | JSONPath evaluation, deep merge, template substitution helpers |
| `lib/types/` | `src/lib/types/` | TypeScript interfaces: `MockConfig`, `RunnerInput`, `RunnerOutput` |

## External Dependencies

| Package | Purpose |
|---|---|
| `ajv` | JSON Schema validator — validates generated payloads against ONDC schemas |
| `jsonpath` | JSONPath query engine — extracts values from incoming requests to inject into responses |
| `uuid` | Generates `message_id`, `transaction_id`, and other ONDC UUID fields |
| `zod` | Runtime type validation for `MockConfig` structure at load time |
| `acorn` / `acorn-walk` | JavaScript AST parser used to safely evaluate conditional expressions in YAML templates |
| `terser` | Minifies generated helper JS before embedding into browser bundle |
| `base-64` | Base64 encode/decode for binary fields in ONDC payloads |

## Internal Dependencies

None — this package has no dependencies on other workspace packages. It is a leaf library.

## Configuration

Mock runner config is passed as a `MockConfig` object at runtime. In the playground service, this config is fetched from `automation-config-service` (`GET /mock/{domain}/{version}`) and cached in Redis DB1.

**YAML config structure (per domain/version):**
```
mock-config/<DOMAIN>/<USECASE>/<VERSION>/
  factory.yaml          ← maps action_id → action + default YAML file
  <action>/default.yaml ← static ONDC response template
  <action>/save-data.yaml  ← JSONPath extractions stored in Redis
  <action>/inputs.yaml  ← user input fields for INPUT-REQUIRED steps
```

## How to Build

```bash
cd automation-mock-runner
npm install
npm run build       # clean + tsc → dist/

# Build browser bundle
# (webpack produces browser-dist/ for use by automation-frontend/frontend)
npm run build:watch # tsc --watch for development
```

## How to Run Tests

```bash
npm test            # Jest
npm run test:coverage
```

## Notes for Open Source

- The library is fully self-contained — it does not make HTTP calls or connect to Redis. All I/O is handled by the consuming service.
- The browser bundle (`public/`) is pre-built and committed; consumers (frontend) import it as a script tag or ESM import.
- `acorn` is used instead of `eval()` to safely execute conditional logic embedded in YAML templates. Expressions are statically analyzed before execution.
