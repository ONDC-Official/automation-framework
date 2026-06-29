---
id: adr-0007
date: 2026-06-26
grill-ref: repo exploration — config-service + support services + observability
status: accepted
changes: [config-service, user-management-service, form-service, registry-gateway, observability, ondc-protocol]
---

# Seed config + support services + observability

## Question / context
What do config-service, user-management, form-service, registry/gateway, and the observability stack do at runtime?

## Decision
Captured: config-service read-through provider (in-memory cache, db-service backed); user-management (auth/JWT/OAuth/developer-guide, GHCR image); form-service (form schemas, GHCR image); ONDC registry/gateway concepts (external); observability (Jaeger tracing wired; report-service instrumented; Dozzle/Grafana referenced in docs but not in core compose; Network-Observability prod-only).

## Assumptions & perception
- Source: config-service src + docker-compose + developer-docs (code/doc-grounded).
- config-service Redis dep declared but unused; cache is in-memory.
- user-management & form-service are opaque external images.

## KB effect
- frames config-service, user-management-service, form-service, registry-gateway, observability, ondc-protocol.
