---
id: build-tools
kind: instance
isa: component
part-of: automation-libraries
confidence: high
source: repo automation-utils/build-tools/src/* (adr-0031)
changed-by: adr-0031
---

# build-tools (@ondc/build-tools)

CLI + library that turns the spec `config/` into `build.yaml`, validates it, generates the RAG table, and ingests specs into MongoDB. The toolchain behind [[spec-to-runtime]] step 2-8.

## Commands
- parse (alias merge): resolve all $ref in config/ → single build.yaml
- validate: (1) Zod schema check (2) semantic pipeline — validate-usecases (every x-flows.usecase + x-attributes use_case_id ∈ info.x-usecases) + validate-flow-configs (each x-flows.config passes validateConfigForDeployment from [[mock-runner-lib]])
- gen-rag-table: → generated/raw_table.json (per-action validation metadata)
- push-to-db: gzip build.yaml + raw_table.json → POST {db}/protocol-specs/specs (x-api-key)
- gen-change-logs (diff old/new build.yaml), gen-markdowns, gen-knowledge-book + polish (LLM-assisted doc/attribute drafting tools — drafts only; human review = truth)

## build.yaml schema (Zod BuildConfig)
- openapi: "3.x.x"; info{title?, domain, version, x-usecases[], x-branch-name?, x-reporting}
- security, paths, components (OpenAPI passthrough)
- x-attributes[] (usecase-keyed; leaf _description: {required, usage, info, owner, type, enums?, enumrefs?, tags?}; tags hierarchical)
- x-validations (opaque L1 rules), x-errorcodes [{Event,Description,From,code}]
- x-supported-actions {supportedActions: action→string[], apiProperties: action→{async_predecessor, transaction_partner}}
- x-flows[] {type:"playground", id, usecase, config(MockPlaygroundConfig), tags, description, meta?}, x-docs{slug→md}

## raw_table.json (RAG)
- per-action ValidationTableAction {action, codeName, numLeafTests, rows[{rowType group|leaf, name, group, scope, description, skipIf, errorCode, successCode}]}

## Ingest collections (MongoDB, SHA-256 hash-skip)
- build_meta (domain,version uniq), build_docs (domain,version,slug), build_flows (domain,version,usecase,flowId), build_attributes (domain,version,useCaseId), build_validations (domain,version), build_changelog (domain,fromVersion,toVersion), build_validation_table (domain,version)

## Relations
- part-of → [[automation-libraries]] ; used-by → [[spec-to-runtime]], [[automation-specifications]] ; writes → [[db-service]]

## Resolved (adr-0032)
- `ondc-code-generator` = [[validation-compiler]] (automation-validation-compiler, package name `ondc-code-generator`). gen-rag-table calls its `xval -l rag_table`.
