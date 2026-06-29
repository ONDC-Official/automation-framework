---
id: automation-framework
kind: instance
isa: orchestrator
part-of: workbench
confidence: high
source: repo automation-framework (docker-compose.yml, .env, docker-env/, scripts/)
changed-by: adr-0002
---

# automation-framework (orchestrator)

The monorepo root. Owns the Docker Compose stack, the single source-of-truth `.env` of inter-service URLs, the per-service env files, and the `build-api-service.sh` script that produces a domain api-service. Pins 9 submodules to tested commits.

## Slots
- network: single docker bridge `automation-network`; internal DNS = container name
- env-source-of-truth: root `.env` defines all inter-container hostnames/URLs; each service's compose `environment:` maps these to service-specific var names
- shared-auth: `API_SVC_KEY` used as `x-api-key` across db-service, recorder, config, etc. (rotating it requires restarting all services)
- submodule-count: 16 (grew from 9; now incl. user-management + engine libs build-tools/api-service-generator/mock-runner-lib/logger + validation-compiler + beckn-plugins). form-service folding into playground (no dir). See [[automation-libraries]].
- submodule-pinning: all 9 checked out at specific commits (detached HEAD), NOT tracking main, despite .gitmodules branch=main (adr-0009)
- infra-containers: mongo:6 (27017), redis:7-alpine (6379), jaeger all-in-one:1.57.0 (16686/4317/4318), gamification-db postgres (host 5433, runtime-observed adr-0047). ~18 containers live.
- frontend-build: VITE_* vars baked at build time → frontends must be rebuilt to change URLs
- domain-api: optional, additive overlay via `docker-compose.api.yml` (generated). Core stack runs without it.

## Canonical internal service URLs (from .env)
- MOCK_SVC = http://playground-mock-service:3000/mock
- DB_SVC = http://db-service:5001
- CONFIG_SVC = http://config-service:5556
- API_SVC = http://api-service:80/api-service (nginx gateway; set by build-api-service.sh)
- REPORT_SVC = http://report-service:3000
- UI_BACKEND_SVC = http://ui-backend:5000
- REGISTRY_SVC = http://registry-service:8080/v2.0/  (external placeholder; not created by core compose)
- PRAMAAN_BUYER_SVC = http://report-pramaan-buyer:3005 ; PRAMAAN_SELLER_SVC = http://report-pramaan-seller:3005
- USER_MGMT_SVC = http://automation-user-management:8082
- RECORDER_HTTP_SVC = http://recorder-service:8090 ; RECORDER_GRPC_SVC = recorder-service:8089

## Host port map (localhost)
ui-frontend 3035 · ui-backend 3034 · backoffice-frontend 5100 · backoffice-backend 5200 · mock 3031(→3000) · report-service 3000 · form-service 3300 · db-service 5001 · config-service 5556 · user-management 8082 · registry 8080(external) · jaeger 16686 · recorder 8090/8089 · pramaan buyer 3005 / seller 3006 · domain api-gateway 3032

## Startup ordering (depends_on, creation order only — not readiness)
mongo/redis/jaeger → db-service → config-service → mock(playground) → recorder → pramaan(buyer/seller)/report-service → ui-backend/backoffice-backend → frontends. user-management→mongo, form-service→redis run in parallel.

## Relations
- runs → all component services
- builds-domain-service-via → script [[spec-to-runtime]]
- setup-via → script [[local-dev-setup]]

## Overrides
- depends_on semantics: only orders container creation, NOT readiness → services may crash if a dependency isn't accepting connections yet. `setup-local.sh` adds TCP/HTTP health probes (180s timeout). [tester edge point]

## Open questions
- RESOLVED (adr-0057): no local registry-service image anywhere — REGISTRY_SVC/IN_HOUSE_REGISTRY (8080) is a pure external placeholder, used only by ui-backend for JWT token verification (registryServices.ts).
