---
id: adr-0057
date: 2026-06-29
grill-ref: owner "lets work on it" — resolve code-answerable open questions
status: accepted
changes: [automation-framework, config-service, recorder-service, backoffice-frontend, form-service, flow-usecase, onix-plugins, onix-server, flow-state-machine, user-management-service]
---

# Resolve 10 code-answerable open questions

## Decision (all code-verified)
1. registry-service: no local image — pure external placeholder (ui-backend JWT verify only).
2. config-service: cache is in-memory only; Redis unused by its code.
3. recorder NO push: env-controlled (NOURL + NOEnabledIn[env]; skip via RECORDER_SKIP_NO_PUSH), not strictly prod-only; fires locally if configured.
4. backoffice db_id 0/1/2: Redis logical DB indices (RedisService.useDb via shared cache lib).
5. form-service vs mock /forms: mock-playground owns /forms locally; external form-service is legacy/fallback (folding into playground).
6. PLAYGROUND-FLOW: runner config read from workbench cache0 key PLAYGROUND_<sessionId>, not config-service.
7. ONIX plugins: cloned fresh per build by api-service-generator (git clone main) + compiled with generated validationpkg — versioned with the build, not the base image.
8. Vault: prod uses keymanager (Vault, VAULT_ROLE_ID/SECRET_ID); local uses simplekeymanager with env/YAML sample keys.
9. extras pairing: 2-deep only (single request→response pair; no A→B→C chain).
10. user-mgmt comments/notes: ui-frontend dedicated API clients → user-management /api/comments+/api/notes, overlaid (by use_case/flow/action/json_path) on config-service guide content.

## Assumptions & perception
- Source: Explore over the relevant submodules (file:line). High confidence. Clears the code-answerable slice of the open-questions backlog; remaining opens are owner-tacit (domains list, ENABLED_DOMAINS process, deploy env for NO/Grafana) or desired ([[desired-by-architect]]).

## KB effect
- 10 frame open-questions converted to resolved facts.
