---
id: registry-gateway
kind: instance
isa: concept
confidence: high
source: repo docs/developer-docs/registry-gateway.md + docker-compose REGISTRY_SVC
changed-by: adr-0007
---

# ONDC Registry & Gateway (network infra concepts)

External ONDC network components the workbench interacts with conceptually. Important for architects and protocol querents.

## Registry (external)
- role: identity + public-key directory for all NPs; sign/verify keys; lookup-only (not in transactions)
- /subscribe (register: Ed25519+X25519 public keys, valid_from/until, domains, callback_url) → /on_subscribe (registry returns encrypted challenge; NP decrypts via X25519→AES key agreement, returns plaintext)
- /lookup: v1.0 optional auth; v2.0 mandatory SIGNED request. /vlookup: always signed; registry signs response
- caching: by subscriber_id+unique_key_id, TTL hours-days, refresh on sig failure / critical ops
- urls: staging.registry.ondc.org/lookup · preprod.registry.ondc.org/ondc/lookup · prod.registry.ondc.org/lookup (keys NOT interchangeable across envs)

## Gateway (Beckn Gateway, external)
- role: multicast router for `search` ONLY (filter by domain/city); BAP→one search→Gateway fans out to relevant BPPs; BPP→on_search directly to BAP
- all other actions (select/init/confirm/...) bypass Gateway
- BPP receives search with TWO headers: Authorization (BAP) + X-Gateway-Authorization (Gateway) — verifies both
- optional: if BAP knows target BPPs it can search them peer-to-peer (Gateway = discovery convenience)

## Local placeholder
- REGISTRY_SVC = http://registry-service:8080/v2.0/ — referenced in .env but NOT created by core docker-compose (no submodule). Likely external or a mock; 8080 listed in README port table.

## Relations
- referenced-by → [[ui-frontend]] (auth/subscribe), [[ondc-protocol]]

## Resolved (adr-0009)
- registry-service:8080 is an EXTERNAL URL placeholder only — no local container/image exists in the repo. The core stack does not provide a local registry.
