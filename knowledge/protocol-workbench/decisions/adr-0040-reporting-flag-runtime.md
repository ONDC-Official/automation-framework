---
id: adr-0040
date: 2026-06-28
grill-ref: RUNTIME-VERIFICATION-PROMPT path 7 (reporting), live FIS12 2.0.3
status: accepted
changes: [report-service, config-service]
---

# FIS12 2.0.3 is reporting-enabled at runtime; report-service ships per-domain/action validators

## Decision (runtime-observed) — CONFIRMED (enabled half)
- config-service /ui/reporting?domain=ONDC:FIS12&version=2.0.3 ⇒ 200 `{data:true}` — FIS12 2.0.3 IS a reporting-enabled domain (matches KB triple).
- report-service env: PRAMAAN_URL=http://report-pramaan-buyer:3005/runtest, PRAMAAN_ENVIRONMENT=local, analyticsAPI=https://pramaan.ondc.org/beta/analytics-api, NO_URL=https://analytics-api-staging.aws.ondc.org/.
- report-service contains per-domain/version/action validator modules: /app/dist/validations/{DOMAIN}/{VERSION}/{Action}.js (e.g. ONDC:FIS12/2.3.0/OnConfirm.js, ONDC:FIS10/2.1.0/confirm.js) — the per-action re-validators of [[validation-layers]] layer 4.
- NOT yet observed end-to-end: actual HTML+analytics write on a completed flow, and the non-enabled→Pramaan delegation + /callback/PW_<sessionId> path (needs a live flow / a non-enabled domain build). Logged as remaining.

## KB effect
- report-service / config-service: reporting-enabled flag for FIS12 2.0.3 runtime-confirmed; per-action validator dir noted. Full report-write path remains to verify via a flow.
