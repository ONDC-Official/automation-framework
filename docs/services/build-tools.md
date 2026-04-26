# automation-utils / build-tools

## Overview

`automation-utils/build-tools` is the **ONDC spec pipeline CLI**, published as `@ondc/build-tools` (binary: `ondc-tools`). It is the command-line driver that transforms raw YAML spec files (`automation-specifications/config/`) into the compiled `build.yaml` that feeds all downstream code generators and services. It also provides a library API (`./store`) for ingesting spec data into MongoDB for discovery and search. This tool runs in CI/CD for every domain spec change, and locally when developing new ONDC domain specs.

## Role in the Architecture

```
automation-specifications/config/<domain>/<version>/
        ↓  ondc-tools parse
build.yaml   (single resolved, merged spec file)
        ↓  ondc-tools validate
validation errors / ok
        ↓  automation-api-service-generator reads build.yaml
generated domain API service (Go + TypeScript)
```

It is also the entry point for the `make-onix` workflow that generates the full beckn-onix config and Docker artifacts.

## npm Package Name

`@ondc/build-tools` — version `0.0.20`  
Binary: `ondc-tools`  
Node.js ≥ 20 required.

## Tech Stack

- Language: TypeScript (ESM), compiled to `dist/`
- Test framework: Jest (ESM mode via `NODE_OPTIONS='--experimental-vm-modules'`)
- CLI framework: `commander`

## Key Modules

| Module | Path | What it does |
|---|---|---|
| `index.ts` | `src/index.ts` | CLI entry point — registers all `ondc-tools` subcommands via `commander` |
| `lib.ts` | `src/lib.ts` | Library entry point — exports `store` API for MongoDB ingestion |
| `commands/merge.ts` | `src/commands/merge.ts` | `ondc-tools parse` — resolves `$ref` chain in `config/` YAMLs, merges into single `build.yaml` |
| `commands/validate.ts` | `src/commands/validate.ts` | `ondc-tools validate` — Zod-validates `build.yaml` structure and semantic rules |
| `commands/make-onix.ts` | `src/commands/make-onix.ts` | `ondc-tools make-onix` — end-to-end pipeline: parse → validate → generate ONIX server |
| `commands/push-to-db.ts` | `src/commands/push-to-db.ts` | `ondc-tools push-to-db` — ingests spec data into MongoDB for discovery |
| `commands/gen-rag-table.ts` | `src/commands/gen-rag-table.ts` | `ondc-tools gen-rag-table` — generates RAG (retrieval-augmented generation) lookup table for LLM tooling |
| `commands/gen-markdowns.ts` | `src/commands/gen-markdowns.ts` | `ondc-tools gen-markdowns` — generates human-readable Markdown docs from `build.yaml` |
| `commands/gen-change-logs.ts` | `src/commands/gen-change-logs.ts` | `ondc-tools gen-change-logs` — diffs two `build.yaml` versions to produce a changelog |
| `store/` | `src/store/` | Library module: MongoDB ingestion helpers (used by `push-to-db` and as a library by external consumers) |
| `validations/` | `src/validations/` | Zod schemas for `build.yaml` structure validation |
| `types/` | `src/types/` | TypeScript interfaces for `build.yaml`, flow definitions, action schemas |
| `lib/` | `src/lib/` | Shared utilities: YAML loader, JSON pointer resolver, diff engine |
| `errors/` | `src/errors/` | Custom error classes with structured error output for CI |

## CLI Commands

```bash
# Parse: resolve $ref chain → single build.yaml
ondc-tools parse -i config/ -o build.yaml

# Validate: check build.yaml against Zod schema
ondc-tools validate -i build.yaml

# Full pipeline: parse → validate → generate ONIX
ondc-tools make-onix -i config/ -o build-output/

# Push spec to MongoDB
ondc-tools push-to-db -i build.yaml --uri mongodb://...

# Generate RAG table for LLM tooling
ondc-tools gen-rag-table -i build.yaml -o rag-table.json

# Generate Markdown docs
ondc-tools gen-markdowns -i build.yaml -o docs/

# Generate changelog between two versions
ondc-tools gen-change-logs -i old.yaml -j new.yaml -o changelog.md
```

## External Dependencies

| Package | Purpose |
|---|---|
| `commander` | CLI argument parsing and subcommand registration |
| `yaml` | YAML parsing and serialization (v2 — handles YAML 1.2 spec fully) |
| `zod` | Runtime validation of `build.yaml` structure |
| `json-pointer` | RFC 6901 JSON Pointer implementation for schema `$ref` resolution |
| `mongodb` (peer, optional) | MongoDB driver for `push-to-db` command — optional peer dependency |

## Internal Dependencies

| Package | Role |
|---|---|
| `@ondc/automation-mock-runner` | Used at runtime in the `make-onix` workflow to validate mock config generation |
| `ondc-code-generator` | Core code generator — `make-onix` calls `ConfigCompiler` to generate Go + TS artifacts |

## How to Build

```bash
cd automation-utils/build-tools
npm install
npm run build    # tsc → dist/

# Development (no build needed with tsx)
npm run dev      # npx tsx src/index.ts <command>
```

## How to Run Tests

```bash
npm test
# Requires: NODE_OPTIONS='--experimental-vm-modules' (Jest ESM mode)

# Run a single test file:
NODE_OPTIONS='--experimental-vm-modules' npx jest tests/store/ingest.test.ts
```

## Notes for Open Source

- Node.js 20+ is required (not 18) because the tool uses ESM native imports and the `--experimental-vm-modules` Jest flag relies on Node 20+ stability.
- `mongodb` is an optional peer dependency — only needed if you run `push-to-db`. The CLI works without it for all other commands.
- The `gen-rag-table` command produces a JSON lookup table that maps ONDC action + domain + field → description, intended for feeding into LLM-based developer tooling. It is not used in the runtime Protocol Workbench stack.
- In the CI/CD pipeline (`deploy-eks.yml`), this tool runs as `ondc-tools parse` and `ondc-tools validate` on every `draft-*` branch push in `automation-specifications`.
