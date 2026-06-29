---
id: adr-0022
date: 2026-06-26
grill-ref: deep-dive — frontends (ui + backoffice)
status: accepted
changes: [ui-frontend, backoffice-frontend, session-difficulty, signing-security]
---

# Seed frontend depth + session difficulty + auth-header

## Decision
Captured ui-backend full route groups (incl. external deps OSRM/Nominatim under /flow), session model + env values, the auth-header crypto tool (BLAKE2b-512+Ed25519, keyId format), backoffice cache-DB switching + hardcoded-cred security caveats, and a new session-difficulty concept (validation-strictness knobs).

## Assumptions & perception
- Source: Explore over automation-frontend + automation-backoffice (file:line). High confidence.
- session-difficulty knobs are tester-critical (control which validations fire) → tie to w2w blind spot.
- Clarified digest is BLAKE2b-512 (refines signing-security wording).

## KB effect
- ui-frontend: route groups, external deps, session model, auth-header.
- backoffice-frontend: db-switch + security caveats.
- new frame session-difficulty; signing-security digest clarified.
- triples: difficulty knobs, external deps, env values, backoffice security.
