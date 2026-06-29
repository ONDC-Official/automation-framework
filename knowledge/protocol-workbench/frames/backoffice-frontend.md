---
id: backoffice-frontend
kind: instance
isa: frontend
part-of: workbench
confidence: high
source: repo automation-backoffice/ (frontend + backend src)
changed-by: adr-0008
---

# backoffice-frontend (admin cache manager)

Operator/admin UI (host 5100, path /backoffice-frontend) + backend (host 5200 / container 5000). Used by ONDC infra admins to inspect/edit/delete cached transaction state across services. Absent from the main README.

## Slots
- purpose: cache inspection + management for API/Mock/Report service caches
- db-switch: POST /sessions/updatedb?db_id= switches active Redis logical DB (db_id 0/1/2 ≈ API/Mock/Report)
- auth: POST /auth/login (admin/admin hardcoded in authController; JWT secret hardcoded "your_secret_key", 1h expiry) — ⚠️ local-only, insecure; frontend stores userData in localStorage
- ⚠️ /sessions/updatedb + /sessions POST + /sessions/logs have NO token middleware (only /sessions GET/PUT/DELETE + /sessions/all do)

## Backend routes
- GET /sessions/all (token) → all subscriber IDs
- GET /sessions?subscriber_url= (token) → cache entry ; PUT update ; DELETE delete
- POST /sessions (no auth) ; POST /sessions/updatedb?db_id= (no auth) ; GET /sessions/logs/:transactionId (no auth)
- POST /auth/login

## Relations
- reads/writes → [[db-service]], Redis cache (via [[mock-playground-service]] keyspace), [[report-service]]
- persona → ONDC infra admin/operator

## Open questions
- RESOLVED (adr-0057): db_id 0/1/2 map directly to Redis LOGICAL DB indices (switchCacheDb → RedisService.useDb(db_id) via the shared ondc-automation-cache-lib) — not service-specific stores.
