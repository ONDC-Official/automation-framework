---
id: validation-compiler
kind: instance
isa: component
part-of: automation-libraries
confidence: high
source: repo automation-validation-compiler/ + api-service-generator scripts + ondc-validator plugin (adr-0032)
changed-by: adr-0032
---

# validation-compiler (= ondc-code-generator)

The compiler that turns spec `x-validations` into runnable validators + the RAG table. Its package name IS `ondc-code-generator` (automation-validation-compiler/package.json `name`), so "ondc-code-generator" and "the validation compiler" are the SAME engine.

## Slots
- CLI: `ondc-code-generator` with subcommands `xval` and `schema` (used by [[build-tools]] gen-rag-table and [[api-service-generator]])
- xval -l go → Go `validationpkg` (the L1 validators) → imported by the [[onix-plugins]] `ondc-validator` plugin, run as `validationpkg.PerformL1validations(endpoint, payload, …)`
- xval -l rag_table → `raw_table.json` (per-action validation metadata, the RAG artifact)
- schema → per-action JSON schemas (L0) for the schemavalidator plugin
- source caveat: the in-repo source is v0.0.1 (TS generation only); the published CLI (v0.8.7, with go/rag modes) is what the build scripts actually invoke — the full CLI layer is not in this source tree

## Chain (the protocol's enforceable rules become code)
x-validations (build.yaml) → ondc-code-generator xval -l go → validationpkg (Go) → ondc-validator plugin → enforced at ONIX runtime ([[onix-request-lifecycle]]).

## Relations
- part-of → [[automation-libraries]] ; produces → validationpkg + raw_table.json + L0 schemas
- consumed-by → [[api-service]]/[[onix-plugins]] (ondc-validator), [[build-tools]] (rag), [[api-service-generator]]

## Open questions
- Full xval grammar / how x-validations rules map to generated Go (published-CLI internals not in source) → owner: Shreyansh
