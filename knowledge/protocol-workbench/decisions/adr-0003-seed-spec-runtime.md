---
id: adr-0003
date: 2026-06-26
grill-ref: repo exploration — specification → api-service runtime
status: accepted
changes: [api-service, automation-specifications, domain-version, validation-layers, spec-to-runtime]
---

# Seed spec→runtime (the executable protocol definition)

## Question / context
How does an ONDC spec become a running protocol validator, and where does "the protocol definition" live at runtime? (Highest-priority area.)

## Decision
Captured: spec config structure (config/ modular YAML, build.yaml resolved artifact), the build-api-service.sh pipeline (parse→validate→generate via @ondc/api-service-generator@1.0.2→rag-table→push-to-db→nginx+compose), beckn-ONIX runtime with SchemaValidator + ONDC-Validator Go plugins, domain+version model, and validation layers.

## Assumptions & perception
- Source: scripts/build-api-service.sh + api-service/build-output plugins (code-grounded).
- "Protocol definition made executable" = spec config enforced by api-service; queryable via config-service + raw_table.json RAG.
- ONIX adapter boundary vs generated plugins not fully pinned (open question).

## KB effect
- frames api-service, automation-specifications, domain-version, validation-layers; script spec-to-runtime.
