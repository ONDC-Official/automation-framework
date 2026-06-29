---
id: adr-0032
date: 2026-06-26
grill-ref: verify — ondc-code-generator/validation-compiler + beckn-plugins
status: accepted
changes: [validation-compiler, onix-plugins, build-tools, automation-libraries]
---

# ondc-code-generator = validation-compiler; beckn-onix core is external

## Decision
- `ondc-code-generator` IS automation-validation-compiler (package name). Same engine: `xval -l go` → Go validationpkg (consumed by ondc-validator plugin, PerformL1validations); `xval -l rag_table` → raw_table.json; `schema` → L0 JSON schemas. (In-repo source v0.0.1 is TS-only; published CLI v0.8.7 has go/rag modes — full CLI not in source tree.)
- automation-beckn-plugins (in-repo) = 12 ONIX plugins, each compiled to .so by buildplugins.sh, loaded by ONIX pluginManager. adapter.yaml ids map 1:1. encryption + outgoing-encryption mws built but unwired.
- The beckn-ONIX SERVER CORE is NOT in this repo — separate `github.com/ONDC-Official/automation-beckn-onix` v1.5.0 (go.mod replace). Plugins only here.

## Assumptions & perception
- Source: Explore over automation-validation-compiler, automation-beckn-plugins, adapter.yaml, ondc-validator (file:line). High confidence. Server-core internals require the external repo.

## KB effect
- new frame validation-compiler; onix-plugins (build/load + server-core-external note); build-tools open Q resolved; automation-libraries members updated.
