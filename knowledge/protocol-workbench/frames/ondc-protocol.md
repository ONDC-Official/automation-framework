---
id: ondc-protocol
kind: class
isa: concept
confidence: high
source: repo docs/developer-docs + spec config + general ONDC/Beckn
changed-by: adr-0007
---

# ONDC protocol (Beckn-based)

The open network protocol the workbench enables. Async, signed, NP-to-NP message exchange. Actions come in request/callback pairs (search/on_search, select/on_select, init/on_init, confirm/on_confirm, status/on_status, update/on_update, cancel/on_cancel, track/on_track).

## Slots
- roles: BAP (buyer app) ; BPP (seller app) ; BG (Beckn Gateway, search multicast); Registry; NO (network observability). See [[ondc-ecosystem]].
- envelope: { context, message, [error] } ; context carries domain, action, bap_id/uri, bpp_id/uri, transaction_id, message_id, timestamp, ttl, version, location.country/city
- transaction: all messages sharing a transaction_id = one buyer-seller interaction (constant across lifecycle)
- lifecycle stages: discovery (search/on_search) → order (select/init/confirm) → fulfillment (status/track/update/cancel) → post-fulfillment (rating/support); IGM (issue/issue_status); RSF (recon/settle/report)
- async: request → ACK (sync) → callback (async) → ACK; NACK = rejected, no callback
- domains: e.g. ONDC:RET10 (retail), ONDC:FIS12 (financial services), ONDC:TRV11 (travel), LOG10/11 (logistics)
- signing: Ed25519 over BLAKE-512 digest; registry holds public keys (see [[registry-gateway]], [[signing-security]])

## Relations
- defined-in → [[automation-specifications]] (per domain+version)
- enforced-by → [[validation-layers]] / [[api-service]]
- see → [[domain-version]], [[flow-usecase]], [[transaction-session]]

## Open questions
- Beckn vs ONDC layering distinctions worth capturing for architects → owner: Shreyansh
