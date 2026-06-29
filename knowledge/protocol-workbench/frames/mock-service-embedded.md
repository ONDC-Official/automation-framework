---
id: mock-service-embedded
kind: instance
isa: service
part-of: api-service
asof: 2026-06-26
confidence: low
source: repo api-service/mock-service/ + verification vs automation-mock-playground-service (adr-0025)
changed-by: adr-0025
---

# Embedded mock-service (api-service/mock-service) — the OLDER mock

A separate, **static** mock config/fixtures directory bundled under [[api-service]]. Verified (adr-0025): this is NOT the same engine as [[mock-playground-service]] and is NOT 100%-config-driven — it is the older mock (per-action TypeScript fixtures, pre-generated), distinct from the config-driven playground. Do NOT conflate the two.

## Slots (verified)
- form: a static `config/mock-config/` directory of per-action `.ts` fixtures (e.g. search.ts, select.ts); NOT a package.json project / running MockRunner engine.
- config-sharing: NOT shared with mock-playground-service — separate/forked.
- contrast: [[mock-playground-service]] = fully config-driven via `@ondc/automation-mock-runner` + config-service; this embedded mock = static fixtures (older approach).

## Relations
- part-of → [[api-service]]
- distinct-from (NOT shared) → [[mock-playground-service]]

## Resolved (adr-0055, runtime)
- ONIX mockTxnCaller proxies to the **standalone [[mock-playground-service]]**, NOT this embedded mock: the live `mock_url` cookie = `http://playground-mock-service:3000/mock/ONDC:FIS12/2.0.3/manual` (adr-0048). ⇒ the embedded static mock is **legacy / not exercised at runtime**.
