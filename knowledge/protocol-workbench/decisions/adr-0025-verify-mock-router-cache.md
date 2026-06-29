---
id: adr-0025
date: 2026-06-26
grill-ref: re-verification — embedded mock, router fallback, config-cache DB
status: accepted
supersedes: adr-0018
changes: [mock-service-embedded, onix-adapter, transaction-session, mock-playground-service]
---

# Verify: embedded mock is the older static mock; router has no fallback; cache DB0/DB1

## Question / context
Owner unsure about the embedded mock and asked to re-verify the code-answerable items.

## Decision
- **Embedded mock (api-service/mock-service) is NOT the config-driven playground engine.** It is a separate, STATIC config/fixtures directory (per-action .ts fixtures, no MockRunner/package). mock-config is NOT shared with mock-playground-service — separate/forked. Confirms owner's recollection ("old mock, not 100% config-driven"). Supersedes adr-0018's portrayal of the embedded mock as a config-driven generator engine.
- **Router fallback: none.** jsonPath routes (np_router $.cookies.mock_url, mock_router $.cookies.subscriber_url) return a 500 error when the cookie is absent/empty (router.go ~349-355) — no static fallback.
- **Config-cache Redis DB indices: DB0 = workbench data, DB1 = MockRunner config cache** (container wiring: cacheService0→WorkbenchCacheService, cacheService1→MockRunnerConfigCache).

## Assumptions & perception
- Source: Explore over api-service/mock-service, mock-playground container/config-cache, router.go (file:line). High confidence on (2)(3); (1) confirmed static-vs-config-driven, but whether the embedded mock is still used at runtime / what ONIX mockTxnCaller proxies to is left open.

## KB effect
- mock-service-embedded: rewritten as older static mock; confidence low; new open Qs.
- onix-adapter: router fallback resolved.
- transaction-session + mock-playground-service: DB0/DB1 confirmed.
