# automation-api-service-generator

## Overview

`automation-api-service-generator` is a **build-time TypeScript tool** that reads a compiled spec file (`build.yaml`) and generates a complete, deployable ONDC domain API service. The generated service is a Go HTTP server (beckn-onix) bundled with domain-specific JSON Schemas, TypeScript L1 validators (compiled to Go), and YAML routing/adapter configuration — all ready to be built into a Docker image and deployed to EKS.

This tool is the bridge between ONDC spec authoring (YAML) and a running enforcement service. You run it once per domain×version; it produces all the boilerplate so developers never hand-write validation logic.

## Role in the Architecture

This is a **CI/CD build-time tool** — it runs during the spec pipeline, not at service runtime.

```
automation-specifications/ build.yaml
        ↓
automation-api-service-generator   ← THIS TOOL
        ↓
build-output/automation-api-service/
  ├── schemas/<action>.json         ← L0 JSON Schemas
  ├── config/adapter.yaml           ← beckn-onix module + plugin pipeline config
  ├── config/form_router.yaml       ← form submission routing rules
  ├── config/mock_router.yaml       ← mock NP routing rules
  ├── config/np_router.yaml         ← NP routing rules
  ├── validationpkg/main-validator.go  ← Generated Go L1 validator
  └── Dockerfile + docker-compose.yml
```

The output is then Docker-built using the `automation-beckn-onix` base image.

## Tech Stack

- Language: TypeScript (ESM), compiled to `dist/`
- Runtime: Node.js ≥ 18

## Key Modules

| Module | Path | What it does |
|---|---|---|
| `index.ts` | `src/index.ts` | Entry point — reads `build.yaml`, orchestrates all generators |
| `config/build.yaml` | `src/config/build.yaml` | The compiled spec that the generator reads (replaced per domain run) |
| `config/validations/` | `src/config/validations/` | Validation rule processing helpers |
| `config/L1-custom-validations/` | `src/config/L1-custom-validations/` | Pre-defined L1 rule templates for common ONDC patterns |
| `go-template/` | `src/go-template/` | Go source code templates for `validationpkg/` generation |
| `go-template/create-onix/` | `src/go-template/create-onix/` | Generates `adapter.yaml` and all beckn-onix YAML config files |
| `go-template/onix-config-templates/` | `src/go-template/onix-config-templates/` | Mustache templates for each YAML config file type |
| `utils/` | `src/utils/` | File I/O helpers, path resolution, template rendering |
| `workflow-utils/` | `src/workflow-utils/` | Orchestration helpers — coordinates the generation sequence |

## External Dependencies

| Package | Purpose |
|---|---|
| `ondc-code-generator` (dev) | Core code generation library (`ConfigCompiler`) — generates L0 schemas, L1 TS validators, and Go `validationpkg` |
| `@apidevtools/json-schema-ref-parser` | Resolves `$ref` chains in JSON Schema files before embedding in generated output |
| `js-yaml` | Parses and emits YAML for config files (`adapter.yaml`, router configs) |
| `jsonpath` | Extracts values from `build.yaml` to drive conditional config generation |
| `lodash` | Deep-clone and merge operations on config objects |
| `fs-extra` | Recursive directory creation and atomic file write for generated output |
| `axios` | Fetches remote schema dependencies if referenced by URL |
| `dotenv` | Reads `OUTPUT_DIR` and other generation-time env vars |
| `ondc-automation-cache-lib` | Redis client — used in the generated service's runtime code (injected as a template dependency) |
| `ondc-crypto-sdk-nodejs` | ONDC ed25519 signing library — included in generated service runtime code |
| `winston-loki` | Logging transport — included in generated service runtime code |
| `concurrently` (dev) | Runs `tsc --watch` and `nodemon` together during development |

## Internal Dependencies

| Package | Role |
|---|---|
| `ondc-code-generator` | **Core compiler** — the generator delegates all code generation to `ConfigCompiler` from this package |

## How to Build

```bash
cd automation-api-service-generator
npm install
npm run build    # tsc → dist/

# Development mode (watch + nodemon)
npm run dev
```

## How to Run (Generate a Domain Service)

```bash
# 1. Place the compiled build.yaml for the target domain into src/config/build.yaml
cp /path/to/build.yaml src/config/build.yaml

# 2. Run the generator
node dist/index.js

# Output lands in build-output/automation-api-service/

# 3. Build the Docker image
cd build-output/automation-api-service
docker build -t my-domain-api-service .
```

## Output Structure

The generated `build-output/automation-api-service/` is a self-contained, runnable project:

```
build-output/automation-api-service/
  schemas/                  ← one JSON Schema file per ONDC action
  config/
    adapter.yaml            ← beckn-onix module definitions + plugin pipeline
    form_router.yaml
    mock_router.yaml
    np_router.yaml
    mock_no_config.yaml
    np_no_config.yaml
  validationpkg/
    main-validator.go       ← Go package: PerformL1validations(action, payload, config, externalData)
  Dockerfile
  docker-compose.yml
```

## Notes for Open Source

- The generator is **idempotent** — running it twice on the same input produces identical output.
- `ondc-code-generator` is a dev dependency because code generation happens at build time only; the generated artifacts (not the generator) ship in the Docker image.
- The Go `validationpkg` is compiled into the `ondcvalidator` plugin of beckn-onix — it does not run as a separate process.
