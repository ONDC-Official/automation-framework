---
id: ondc-ecosystem
title: "ONDC ecosystem background, registry/gateway ops, FAQ, glossary (distilled)"
source: docs/developer-docs/{about-ondc.md, ondc-FAQs.md, registry-gateway.md}
type: doc
added: 2026-06-26
status: ingested   # → frames ondc-ecosystem, ondc-protocol, registry-gateway, domain-version
---

# ONDC ecosystem (distilled reference)

## What ONDC is
Open Network for Digital Commerce — an open, decentralized commerce network (DPIIT-backed, India). Unbundles closed platforms into interoperable buyer-side (BAP) and seller-side (BPP) participants. Analogy: "UPI for e-commerce / SMTP for email." Server-to-server protocol layer, decoupled from any client UI; async-first (ACK + callbacks); Ed25519 signing for non-repudiation, X25519 for onboarding key exchange.

Layering: **Beckn protocol** (base: core APIs, schemas, auth, comms rules, domain taxonomy) + **ONDC extension** (domain contracts, IGM, RSF, Network Observability, registry infra).

## Network roles
- BAP (Beckn Application Platform) — buyer-side; sends search/select/init/confirm; receives on_* callbacks.
- BPP (Beckn Provider Platform) — seller-side; catalogs, quotes, order confirmations, fulfillment updates.
- BG (Beckn Gateway) — multicasts `search` to relevant BPPs by domain/city; discovery ONLY.
- Registry — identity + key directory (subscriber ids, Ed25519+X25519 public keys, callback URLs, domains, status). Lookup-only; not in transactions.
- NO (Network Observability) — receives all payloads from on_search onward + sync responses; network health.
- NP = any registered participant. One company can be both BAP & BPP with separate subscriber ids.

## Transaction lifecycle (ecosystem)
- Discovery: search/on_search (via Gateway; on_search returns direct to BAP).
- Order: select/on_select → init/on_init → confirm/on_confirm (direct BAP↔BPP).
- Fulfillment: status/on_status, track/on_track, update/on_update, cancel/on_cancel.
- Post-fulfillment: rating/on_rating, support/on_support.
- IGM (grievance): issue/on_issue → issue_status/on_issue_status.
- RSF (settlement): recon/on_recon, settle/on_settle, report/on_report.
- Async: request → ACK (sync) → callback (async) → ACK. NACK = rejected, no callback.
- Context envelope: domain, action, version, bap_id/uri, bpp_id/uri, transaction_id (constant across lifecycle), message_id (per call), timestamp, ttl, location.country/city.

## Signing / auth (concept)
- Ed25519 sign body (BLAKE-512 digest); Authorization header keyId=`subscriber_id|unique_key_id|ed25519`, created/expires (ISO8601), digest, base64 sig.
- Verify: keyId → registry lookup sender public key → Ed25519 verify. Validate context.bap_id == keyId subscriber (else 401).
- Minify JSON at sign AND send (beautification breaks the signature).
- X25519: onboarding challenge only (AES via key agreement to decrypt /on_subscribe challenge).

## Registry & Gateway ops
- /subscribe (register: public keys, valid_from/until, domains, callback_url) → /on_subscribe (registry returns encrypted challenge; NP decrypts via X25519→AES, returns plaintext).
- /lookup: v1.0 optional auth; v2.0 mandatory SIGNED request. /vlookup: always signed, registry signs response (cryptographically trustworthy).
- Gateway delivers `search` to BPP with TWO auth headers: Authorization (BAP) + X-Gateway-Authorization (Gateway) — BPP verifies both, replies on_search direct to BAP.
- Caching: cache lookup by subscriber_id+unique_key_id, TTL hours-days, refresh on sig failure / for critical ops.
- Env URLs: staging.registry.ondc.org/lookup · preprod.registry.ondc.org/ondc/lookup · prod.registry.ondc.org/lookup. Keys NOT interchangeable across envs.

## Domains
- Code pattern `ONDC:XYZ##` (3 letters + 2 digits). Examples: RET10 grocery, RET11 F&B, RET12 general merch, TRV10 mobility, FIS10 financial services, LOG10 logistics. Each domain adds schema extensions; protocol version e.g. 2.0.0.

## Curated FAQ (ecosystem/operational)
- subscriber_id = FQDN identity; subscriber_url = where APIs are hosted (must include the id).
- ops_no in /subscribe: 1=BAP, 2=BPP, 4=both (3 & 5 deprecated).
- whitelisting required before /subscribe (ONDC Portal, profile 100%, env access request).
- "Domain verification failed" ⇒ request_id mismatch between payload and the one signed.
- public keys: raw base64 (preferred) or PEM.
- /on_subscribe challenge: AES via X25519 key agreement.
- signature fails on semantically-identical payload ⇒ JSON whitespace; minify both sides.
- call /lookup before processing a signed request (cache with TTL; refresh on sig failure).
- validate context.bap_id vs Authorization keyId ⇒ else 401.
- /lookup v2.0 mandatory signed (vs v1.0 optional).
- NO push: all payloads from on_search onward + sync responses incl IGM/RSF; anonymize PII except city & pincode; automated (no manual Postman); same-day with T+1 02:00 cutoff buffer.
- Gateway optional: if you know target BPPs you can search them peer-to-peer.

## Glossary
subscriber_id, unique_key_id (UKID), transaction_id (constant per txn), message_id (per call), domain, context, ACK/NACK, IGM, RSF, NO, Ed25519, X25519, Beckn, BG, NP.
