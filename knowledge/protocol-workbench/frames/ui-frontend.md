---
id: ui-frontend
kind: instance
isa: frontend
part-of: workbench
confidence: high
source: repo automation-frontend/ (frontend + backend src)
changed-by: adr-0008
---

# ui-frontend (main Automation UI)

> ⚠ Frontend = runtime-proven only (adr-0056): some frontend code is legacy/dead (stale `trigger/api-service/:action` route → 404; `crypto.randomUUID` non-secure-context TODO). Treat code presence ≠ live behavior; record only what's observed at runtime. See [[knowledge-keep-updated]].

The primary workbench UI (host 3035) + its backend (ui-backend, host 3034 / container 5000). The backend is the mediator between the browser and all downstream services. This is the surface most personas (NP UI users, PMs, QA, playground users) touch.

## Slots
- frontend-stack: React/Vite (Monaco editor for payloads); URLs baked via VITE_* at build
- ui-backend role: orchestrates calls to api-service (validate), mock (trigger/proceed), config (flows), report, db (history/sessions), user-management (auth)
- session: created in Redis, ~48h expiry; localStorage tracks recent sessions

## Pages / tools
- /home — entry (LEARN / BUILD / SHIP paths)
- /schema-validation — Schema Validation Tool (paste JSON → validate). Script [[schema-validation]]
- /scenario → /flow-testing — Flow Testing Suite (session form → step-by-step flow → report). Script [[run-flow-test]]
- /playground — free-form MockRunner flow building
- /developer-guide — protocol docs tree (domain/version/usecase → flows/actions/validations) served by [[config-service]]/protocol specs; renders a status badge (released/drafted/to-be-deprecated/deprecated) that is currently a HARDCODED frontend placeholder (statusPlaceholders.ts, getNavStatus), not data-backed — see [[spec-lifecycle-status]]; collaborative comments/notes overlay via [[user-management-service]]
- /auth-header — build signed ONDC auth headers (crypto util)
- /db-back-office, /framework-health, /history

## ui-backend route groups (port 3034 → container 5000)
- /sessions: POST create (+ /playground PLAYGROUND_ key), GET/PUT, /expectation POST|DELETE (5min TTL), /transaction GET, /clearFlow DELETE
- /flow: /validate/:action → api-service `/{d}/{v}/test/{action}`; /trigger/:action → mock; /proceed, /current-state, /new → mock; /report → report-service; /actions; /customFlow, /custom-flow, /examples; **/route → OSRM (external map routing), /geocode → Nominatim (external)** [net-new external deps]; /external-form
- /config: /flows, /senarioFormData, /reportingStatus → config-service
- /db: payload/report/sessions/user/flows/subscriber-urls → db-service (some token-gated)
- /auth: GitHub OAuth (/github, /callback), /api/me, /logout, /generate-keys, /subscribe (POST/PATCH/DELETE), /lookup → registry
- /seller: /on_search, /upload-images, /onboard-with-images
- /reports, /guide, /dev-guide (/spec/:domain/:version, /available-builds → config-service), /ai (proxy), /health, /user (scenario prefs)

## Session model + difficulty
- session in Redis SessionCache (48h): flowMap, npType, domain, version, subscriberUrl, env (STAGING|PRE-PRODUCTION|LOGGED-IN), flowConfigs (from config-service), activeFlow/Step, sessionDifficulty. See [[session-difficulty]].

## Auth-header tool
- builds/verifies ONDC signature: BLAKE2b-512 digest + Ed25519; keyId `{subscriber_id}|{unique_key_id}|ed25519`; exact-byte payload (no re-stringify); standard base64; code samples (Python/Node/Go/Java/PHP). See [[signing-security]].

## Relations
- calls → [[api-service]], [[mock-playground-service]], [[config-service]], [[report-service]], [[db-service]], [[user-management-service]]
- auth-via → [[user-management-service]] + registry

## Overrides / edge points
- missing context.domain/version in payload ⇒ 400 on validate.
- session expiry (48h) ⇒ need new session.
- core validation/flow testing work WITHOUT login; OAuth only for profile/subscription.

## Resolved (adr-0009)
- `/ai/proxy` (aiProxyRoutes) is a GENERIC forward proxy: target from `x-proxy-target` header, SSRF guard (blocks private IPs), forwards Authorization, supports SSE. No built-in LLM/MCP/RAG — any AI is external + client-supplied. (So an MCP runtime agent would be an external consumer, not baked into the workbench.)
- All 9 submodules are pinned to specific commits (detached HEAD), not tracking `main`.

## Open questions
- Is the `/ai/proxy` the intended integration point for the planned MCP runtime support agent? → owner: Shreyansh
