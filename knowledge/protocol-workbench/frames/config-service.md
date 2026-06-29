---
id: config-service
kind: instance
isa: service
part-of: workbench
confidence: high
source: repo automation-config-service/ (src, structure.md)
changed-by: adr-0007
---

# config-service (read-through spec/flow config provider)

TypeScript/Express service (port 5556) that serves domain/version-specific protocol config (flows, use-cases, supported actions, reporting flags) to the UI backend and mock-playground-service. Acts as a read-through proxy over [[db-service]] with an in-memory cache.

## Slots
- cache: in-memory, ~1h TTL (SESSION_EXPIRY); Redis declared as dep but unused in code; specs fetched on-demand per request (not at startup)
- depends-on: db-service (AUTOMATION_DB_BASE_URL), redis (declared), jaeger

## Endpoints (route groups)
- /ui/flow (domain,version,usecase) → flows list + descriptions
- /ui/reporting (domain,version) → reporting_enabled boolean
- /ui/senario → available builds (domains/versions/usecases)  [sic: 'senario']
- /mock/flow + /mock/playground (domain,version,usecase,flowId) → flow config (mock-runner format)
- /protocol/specs/{domain}/{version} ; /protocol/builds → delegate to db-service
- /api-service/supportedActions (domain,version) → supportedActions[], apiProperties[]

## Relations
- serves → [[ui-frontend]] (via ui-backend), [[mock-playground-service]]
- reads-from → [[db-service]]
- converts → spec flows → mock-runner config (convertToFlowConfig)
- runtime-mirror-of → [[automation-specifications]] branches: /ui/senario + /protocol/builds reflect what's been pushed-to-db per env, NOT the source of truth for "what's live" (branches are). (adr-0014)

## Runtime-confirmed (adr-0039, live FIS12 2.0.3)
- /ui/senario → 200 `{domain:[{key:ONDC:FIS12, version:[{key:2.0.3, usecase:[GOLD LOAN, PERSONAL LOAN]}]}]}` — mirrors pushed-to-db (single running api-service).
- /ui/flow?...&usecase=PERSONAL LOAN → 200 flows[] with sequence[] (each step: key/type/owner/description).
- /api-service/supportedActions → 200 `{data.supportedActions:{null:[search], search:[on_search], on_search:[select], ...}}` (the transaction_properties state machine, served from db).
- /ui/reporting?domain=ONDC:FIS12&version=2.0.3 → 200 `{data:true}` (reporting enabled).
- config-service itself writes NO Redis keys (in-memory cache confirmed; a test even references "previous Redis implementation" it migrated off). The Redis **DB1** flow-config cache (`{domain}::{version}::{flowId}::{usecase}`, e.g. `ONDC:FIS12::2.0.3::Personal_Loan_Offline::PERSONAL LOAN`, TTL -1) is written by **[[mock-playground-service]]** (sole db=1 client), NOT config-service.

## Overrides / edge points
- db-service down ⇒ axios timeout on fetchSpec; spec-not-found ⇒ 404 bubbles up.
- "Playground deployment not reflecting changes" (FAQ): update config-service AND clear playground cache (mock backdoor clear-flows).

## Open questions
- RESOLVED (adr-0057): config-service cache is purely IN-MEMORY (cacheService.ts: configCache + lastLoadTime, ~1h TTL). Redis is NOT used by config-service code; the docker redis dep is for other services.
