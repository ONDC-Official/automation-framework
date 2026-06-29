---
id: automation-libraries
kind: class
isa: component
part-of: workbench
asof: 2026-06-26
confidence: medium
source: repo .gitmodules + dir scan (adr-0027)
changed-by: adr-0027
---

# Automation libraries (engine packages, now submodules)

The `@ondc/*` engine packages that were previously external npm deps are now **git submodules** in the monorepo — their source is available for deep-dive. These are the engines behind spec-build, code-gen, mock generation, and logging.

## Members (submodule → role → frame)
- **automation-utils/build-tools** → `@ondc/build-tools` → [[build-tools]] (parse/validate/rag/push-to-db; build.yaml schema; ingest collections)
- **automation-api-service-generator** → `@ondc/api-service-generator` → [[api-service-generator]] (build.yaml → ONIX build-output)
- **automation-mock-runner-lib** → `@ondc/automation-mock-runner` → [[mock-runner-lib]] (the [[spec-logic]] execution engine)
- **automation-validation-compiler** → `ondc-code-generator` → [[validation-compiler]] (x-validations → Go validationpkg + RAG table + L0 schemas)
- **automation-beckn-plugins** → the ONIX runtime Go plugins ([[onix-plugins]]); beckn-onix server core is a SEPARATE external repo
- **automation-logger-package** → `@ondc/automation-logger` → [[logger-package]] (Winston structured logging; prod → Grafana Loki)
- automation-utils may also hold shared helpers beyond build-tools.

## Slots
- repo-status: 14 total submodules now (was 9) — these 5 + [[user-management-service]] added.
- deep-dive: not yet extracted to frames; available on request (closes the prior "external npm internals" gap).

## Relations
- powers → [[spec-to-runtime]], [[api-service]], [[mock-playground-service]], [[db-service]]

## Status
- Deep-dived: build-tools, api-service-generator, mock-runner-lib (adr-0031); validation-compiler + beckn-plugins (adr-0032); logger-package (adr-0036). Not yet: beckn-onix server core (external repo).

## Open questions
- automation-logger-package internals (low priority) → owner: Shreyansh
- beckn-onix server core (external automation-beckn-onix repo) — request if deeper ONIX-engine detail wanted → owner: Shreyansh
