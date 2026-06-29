---
id: form-service
kind: instance
isa: service
part-of: workbench
confidence: medium
asof: 2026-06-26
source: repo docker-compose.yml + docker-env/form-service.env + owner (adr-0027)
changed-by: adr-0027
---

# form-service

External image (port 3300), form schemas for test-scenario setup. **Direction (owner, adr-0027): going forward, form handling is integrated into [[mock-playground-service]] only** — the standalone form-service is being phased out (no submodule / dir present in repo). Treat standalone form-service as legacy; current/forward form lifecycle lives in the playground mock ([[flow-state-machine]] form types).

## Slots
- env: MOCK_SERVICE_URL (MOCK_SVC), BACKEND_URL (UI_BACKEND_SVC), depends-on redis
- role: dynamic form schemas/handling for flows that require form input (relates to mock HTML_FORM/DYNAMIC_FORM)

## Relations
- bridges → [[mock-playground-service]], [[ui-frontend]]

## Open questions
- RESOLVED (adr-0057): the standalone form-service (3300) is still wired in docker-compose (external image) but mock-playground-service OWNS form serving locally via its own `/forms` routes (form-controller). form-service is the external/legacy fallback — consistent with "folding into playground".
