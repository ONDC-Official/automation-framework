---
id: adr-0039
date: 2026-06-28
grill-ref: RUNTIME-VERIFICATION-PROMPT path 8 (config-service), live FIS12 2.0.3
status: accepted
changes: [config-service]
---

# config-service endpoints reflect pushed-to-db; in-memory cache confirmed (DB1 cache is mock-playground's)

## Decision (runtime-observed) — CONFIRMED
- /ui/senario, /ui/flow, /api-service/supportedActions, /ui/reporting all 200 and reflect the single pushed build (FIS12 2.0.3, GOLD LOAN + PERSONAL LOAN). supportedActions returns the transaction_properties state machine (null→search→on_search→select→…).
- config-service writes NO Redis keys (in-memory cache; test references migrating off a "previous Redis implementation"). Redis client census: 11 on db=0, 1 on db=1. The DB1 flow-config cache (`{domain}::{version}::{flowId}::{usecase}`, TTL -1) is owned by mock-playground-service (sole db=1 client), reconciling the prior "config-cache DB1" note with "config-service in-memory".

## Assumptions & perception
- Evidence: live curls to :5556 + `redis-cli CLIENT LIST` + source grep. High confidence.

## KB effect
- config-service: Runtime-confirmed block added (DB1 owner = mock-playground; in-memory cache stands).
