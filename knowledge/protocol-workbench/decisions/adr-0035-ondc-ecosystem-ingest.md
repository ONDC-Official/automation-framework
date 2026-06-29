---
id: adr-0035
date: 2026-06-26
grill-ref: owner — scan ONDC docs, make a reference doc, then upgrade KB
status: accepted
changes: [ondc-ecosystem, ondc-protocol, registry-gateway, domain-version, references]
---

# Ingest ONDC ecosystem background + FAQ

## Decision
Scanned docs/developer-docs (about-ondc, ondc-FAQs, registry-gateway), wrote a distilled reference (references/ondc-ecosystem.md), then ingested:
- new frame ondc-ecosystem (what ONDC is, open-network model, Beckn layering, roles incl Registry+NO, domain code pattern, FAQ pointer).
- ondc-protocol: lifecycle stages (discovery/order/fulfillment/post-fulfillment + IGM/RSF), async ACK/NACK, context fields, Registry/NO roles.
- registry-gateway: /subscribe+/on_subscribe (X25519 challenge), lookup v1/v2, vlookup, caching, X-Gateway-Authorization, env URLs, gateway-optional.
- domain-version: ONDC:XYZ## code pattern + examples.

## Assumptions & perception
- Source: ONDC reference docs (ecosystem-level, may lag live ONDC). network-observability.md left as indexed-only (UDP/observability parked per owner). The "FAQ repo" the owner mentioned resolved to docs/developer-docs/ondc-FAQs.md (no separate FAQ submodule present).

## KB effect
- ondc-ecosystem frame + reference; enrichments to ondc-protocol/registry-gateway/domain-version; references.md updated.
