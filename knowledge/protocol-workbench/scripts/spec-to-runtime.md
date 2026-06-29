---
id: spec-to-runtime
kind: script
confidence: high
source: repo scripts/build-api-service.sh + build-output
changed-by: adr-0003
---

# Spec → runtime (build-api-service.sh)

How an ONDC spec branch becomes a running protocol validator+responder ([[api-service]]). Highest-value procedure for architects and workbench devs. Engines: [[build-tools]] (parse/validate/rag/push-to-db) + [[api-service-generator]] (codegen → ONIX).

## Entry conditions
- core stack up (db-service running so push-to-db works); a target spec branch chosen (e.g. draft-FIS12-2.3.0)

## Roles
- developer (runs script), automation-specifications (spec), @ondc/build-tools, @ondc/api-service-generator, db-service, nginx api-gateway, ONIX server

## Scenes (ordered)
1. Args — `./scripts/build-api-service.sh <spec-branch>` (no arg ⇒ lists branches from remote).
2. Clone/fetch — clone automation-specifications into `api-service/` (first run) or fetch + `git checkout -B local-spec origin/<branch>`.
3. Parse — `npx @ondc/build-tools parse -i config -o build.yaml` (resolves all $ref into one file).
4. Validate — `npx @ondc/build-tools validate -i build.yaml`.
5. Read identity — extract info.domain + info.version → normalize to service name (api-ondcfis12-2-0-3).
6. Generate — `npx @ondc/api-service-generator@1.0.2` (env IS_ONIX_ENABLED, PORT=7039, CONFIG_SERVICE_URL, MOCK_SERVER_URL, RECORDER_*). Produces build-output/ (temp/schemas/, temp/config/ adapter.yaml etc., temp/automation-beckn-plugins/ Go source, Dockerfile, docker-entrypoint.sh).
7. RAG table — `npx @ondc/build-tools gen-rag-table -i build.yaml -o generated` → generated/raw_table.json.
8. Push to DB — `npx @ondc/build-tools push-to-db -f build.yaml -t generated/raw_table.json -u http://localhost:5001 -k <API_SVC_KEY>` (non-blocking; warns on 4xx/5xx).
9. nginx config — write api-service/nginx/default.conf (routes /api-service/{d}/{v}/* → :7039 ; /mock/{d}/{v}/* → playground-mock-service:3000 ; / → :7039).
10. Compose overlay — write docker-compose.api.yml (api-gateway nginx 3032:80 aliased `api-service` + domain container building from build-output/).
11. Update .env — set API_SVC=http://api-service:80/api-service.
12. Build+run — `docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build`. At start, docker-entrypoint.sh sed-renders adapter.yaml (domain/version/port/redis/urls); ONIX listens :7039.

## Branches of work
- Edit generated code only (no spec change): edit build-output/ → rebuild (skip scenes 2-11).
- Edit spec config: edit api-service/config/ → re-run script (regenerates).
- Switch domain: `... down` → re-run script for new branch → `... up -d --build`.

## Results
- api-service for one domain+version reachable at localhost:3032; spec pushed to db; raw_table.json available for RAG.

## Edge points
- api-service/ and docker-compose.api.yml are git-ignored (ephemeral).
- only one domain on 3032 at a time.
- push-to-db needs db-service up first.
