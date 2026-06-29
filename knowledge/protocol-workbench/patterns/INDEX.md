# Failure-mode patterns (durable, low-token debug)

Reusable symptom → cause → fix patterns. Each entry is self-contained (signature → ordered quick-checks → cause → fix locus file:line → verify). Durable knowledge, NOT an incident log — a specific incident's detail belongs in an ADR + (briefly) `references/`; only the reusable pattern lives here. To find WHERE a concern lives in code first, use `../LOCATOR.md`.

## Golden rule
An `on_X`/callback NACK is usually a **mock-generation symptom**, not a protocol bug — check generation first ([[fm-001]]).

## Patterns
- [[fm-001]] — on_X / callback NACK (message_id mismatch / out-of-sequence / fresh id) → generation symptom
- [[fm-002]] — flow stops after ~5 min · current-status/forms 500 "No transaction data found" · empty HTML form
- [[fm-003]] — DYNAMIC_FORM (eKYC) submitted but flow won't advance · modal hangs
- [[fm-004]] — decode an api-service response status (200-NACK / 400 / 412 / 401 / 500)
- [[fm-005]] — UI "trigger search" does nothing · ui-backend 500 · mock 404
- [[fm-006]] — local cloud-frontend gotchas (CORS preflight · crypto.randomUUID · cross-origin)

## Upkeep
After a real investigation, add/refresh a pattern here ONLY if it's reusable; put the incident specifics in an ADR (and a short `references/` report, prunable). New entries use `_template.md`.
