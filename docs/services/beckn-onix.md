# automation-beckn-onix

## Overview

`automation-beckn-onix` is the **runtime protocol enforcement server** — a production-grade Go HTTP server that acts as a middleware adapter between ONDC buyers and sellers. It validates incoming API payloads against JSON Schemas (L0) and ONDC business rules (L1), signs/verifies ed25519 signatures, routes requests to the correct counterparty, and records every API call to the audit trail via gRPC. The server is entirely configuration-driven: each domain×version gets its own generated YAML config and compiled Go plugin, with no code changes required to add a new domain.

## Role in the Architecture

`automation-beckn-onix` is the **central enforcement layer** for every ONDC protocol call:

```
Frontend BFF (/buyer/ or /seller/)
        ↓
automation-beckn-onix   ← THIS SERVICE
  Plugin pipeline per module:
    schemavalidator → ondcvalidator → workbench → signvalidator → signer → keymanager → router → cache → networkobservability
        ↓
Mock Playground Service  or  Real NP
```

It exposes **5 HTTP modules** per deployed domain, each with a distinct plugin pipeline:

| Module | Path | Pipeline |
|---|---|---|
| `formReceiver` | `/api-service/{domain}/{version}/form/html-form` | Route form to recorder-service |
| `standaloneValidator` | `/api-service/{domain}/{version}/test/` | L0 schema + L1 validation (stateless) |
| `BapTxnReceiver` | `/api-service/{domain}/{version}/seller/` | Verify sig → session → L0 → L1 → record → ACK |
| `BppTxnReceiver` | `/api-service/{domain}/{version}/buyer/` | Session → L0 → L1 → route → sign → forward → record |
| `mockTxnCaller` | `/api-service/{domain}/{version}/mock/` | Route → sign → forward (proxy to mock) |

## Default Port

`3032` (host) → `3032` (container)

## Tech Stack

- Language: Go 1.25+
- Plugin system: compiled `.so` shared libraries loaded at startup
- Configuration: YAML (`adapter.yaml`, router configs, schema files)
- Secrets: HashiCorp Vault (optional) or file-based key storage

## Key Modules (Go Packages)

| Package | Path | What it does |
|---|---|---|
| `cmd/` | `cmd/` | Entry point — loads config, registers plugins, starts HTTP listener |
| `core/` | `core/` | Plugin manager, request pipeline executor, module registry |
| `pkg/` | `pkg/` | Shared utilities: YAML config loader, plugin interfaces, telemetry |

## The 9 Go Plugins (`.so` files)

Each plugin is a compiled shared library loaded at server startup from `./plugins/`. They are pre-compiled and shipped in the base Docker image.

| Plugin | Responsibility |
|---|---|
| `schemavalidator` | Validates request body against the generated JSON Schema for that ONDC action (L0 validation) |
| `ondcvalidator` | Runs the generated `PerformL1validations()` Go function — stateful ONDC protocol rules |
| `workbench` | Connects to `automation-config-service` for session/flow state; validates context fields, timestamps, flow ordering; sets `subscriber_id` cookie |
| `signvalidator` | Validates the `Authorization` header Beckn ed25519 signature; can be skipped via `header_validation=false` cookie |
| `signer` | Signs outgoing requests with the workbench's ed25519 private key; generates `Signature keyId=...` header |
| `keymanager` | Stores and retrieves ed25519 signing key pairs; looks up NP public keys from the ONDC registry |
| `networkobservability` | Post-response hook: sends the full API call (request + response + metadata) to `automation-recorder-service` via gRPC `LogEvent` |
| `router` | Determines the target URL from YAML routing rules — reads cookies (`subscriber_url`, `mock_url`) to select route |
| `cache` | Provides shared Redis state between plugins within a single request (scoped to request lifecycle) |
| `otelsetup` | (Optional) Wires OpenTelemetry SDK for metrics/traces export to Prometheus and Jaeger |

## External Dependencies (Go)

| Module | Purpose |
|---|---|
| `github.com/santhosh-tekuri/jsonschema/v6` | JSON Schema validation engine for L0 schema checking |
| `golang.org/x/crypto` | ed25519 cryptographic operations for Beckn signature sign/verify |
| `github.com/zenazn/pkcs7pad` | PKCS#7 padding for AES-based key wrapping in `keymanager` |
| `gopkg.in/yaml.v3` | YAML parsing for all config files (`adapter.yaml`, router configs) |
| `github.com/redis/go-redis/v9` | Redis client used by the `cache` plugin for per-request state sharing |
| `github.com/hashicorp/vault` (via deps) | Optional secrets backend for key management |
| `go.opentelemetry.io/` (via otelsetup) | OpenTelemetry Go SDK for metrics and distributed tracing |
| `github.com/beorn7/perks` | Prometheus histogram utilities for RED metrics |

## Internal Dependencies

| Dependency | How it's used |
|---|---|
| `validationpkg/` (generated Go) | The `ondcvalidator` plugin dynamically links against this generated package at compile time. It contains the `PerformL1validations()` function specific to a domain×version |
| `schemas/*.json` (generated) | Loaded at startup by `schemavalidator` plugin from the `schemas/` directory |
| `config/adapter.yaml` (generated) | Master config — defines all HTTP modules, plugin pipelines, and plugin configuration |
| `automation-config-service` | The `workbench` plugin calls this at runtime to fetch session/flow state |
| `automation-recorder-service` | The `networkobservability` plugin sends gRPC `LogEvent` to this service after every request |

## Cookie-Driven Routing

No hardcoded service URLs exist in the protocol layer. The frontend BFF injects routing context as HTTP cookies per request:

| Cookie | Set by | Used by |
|---|---|---|
| `subscriber_url` | Frontend backend | `router` plugin (`mock_router`) — routes to NP subscriber |
| `mock_url` | Frontend backend | `router` plugin (`np_router`) — routes to mock-playground |
| `session_id` | Frontend backend | `workbench`, `networkobservability` plugins |
| `ttl_seconds` | Frontend backend | `networkobservability` (cache TTL for transaction log) |
| `header_validation` | Per-request option | `signvalidator` — set to `false` to disable signature check |
| `protocol_validation` | Per-request option | `ondcvalidator` — set to `false` to disable L1 validation |

## How to Build

```bash
# Build the Docker image (with all plugins compiled in)
cd automation-framework
npm run build:onix
# Tag: automation-beckn-onix:local
# Uses: Dockerfile.adapter-with-plugins

# Or build the base binary directly
cd automation-beckn-onix
go build ./cmd/...
```

## Configuration

All config files are generated by `automation-api-service-generator` and placed in `config/` before the Docker build. The main config is `config/adapter.yaml`:

```yaml
modules:
  - id: BapTxnReceiver
    path: /api-service/{domain}/{version}/seller/
    steps:
      - id: validateSign
        plugin: signvalidator
      - id: workbenchReceive
        plugin: workbench
      # ...
plugins:
  schemavalidator:
    schemasDir: ./schemas
  ondcvalidator:
    configDir: ./config
```

## Observability

- Prometheus metrics on `/metrics` (per-module RED metrics, signature validation counts, routing decisions)
- OpenTelemetry traces exported via OTLP HTTP to Jaeger
- Structured JSON logs (zerolog)

## Notes for Open Source

- The base Docker image (`ghcr.io/ondc-official/automation-beckn-onix:latest`) ships with all 9 plugins pre-compiled. Domain-specific code (`validationpkg/`, `schemas/`, `config/`) is injected at image build time, not runtime.
- Adding a new ONDC domain requires: (1) authoring YAML in `automation-specifications`, (2) running `automation-api-service-generator`, (3) Docker build. No changes to this repo are needed.
- The `beckn-onix` upstream is the open Beckn community project; this fork (`automation-beckn-onix`) adds ONDC-specific plugins and the Protocol Workbench adapter modules.
