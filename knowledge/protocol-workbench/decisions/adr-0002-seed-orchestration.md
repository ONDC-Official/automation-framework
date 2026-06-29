---
id: adr-0002
date: 2026-06-26
grill-ref: repo exploration — orchestration layer
status: accepted
changes: [automation-framework, local-dev-setup]
---

# Seed orchestration layer from code

## Question / context
How does the stack wire together at runtime?

## Decision
Captured docker-compose stack: services, host/internal ports, dependency graph, root `.env` as URL source-of-truth, API_SVC_KEY shared auth, infra (mongo/redis/jaeger), VITE build-time injection, and the local-dev-setup procedure.

## Assumptions & perception
- Source: docker-compose.yml, docker-compose.api.yml, docker-env/*, scripts/, setup-local.sh (Explore agent, code-grounded).
- `depends_on` orders container creation only, not readiness (key tester caveat).
- registry-service:8080 referenced but not created by core compose — treated as external/unknown (open question).

## KB effect
- frame automation-framework; script local-dev-setup; port/url triples.
