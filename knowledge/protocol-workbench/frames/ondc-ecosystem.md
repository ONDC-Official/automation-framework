---
id: ondc-ecosystem
kind: concept
isa: concept
confidence: high
source: ref:ondc-ecosystem (docs/developer-docs about-ondc, ondc-FAQs, registry-gateway)
changed-by: adr-0035
---

# ONDC ecosystem (context the workbench operates in)

Background for PMs/architects/NP devs: what ONDC is and the network the workbench simulates/validates. The workbench is a testing/enablement layer ON this ecosystem; [[ondc-protocol]] is the on-the-wire protocol, this frame is the network/business framing.

## Slots
- definition: Open Network for Digital Commerce — open, decentralized commerce network (DPIIT/India). Unbundles closed platforms into interoperable BAP (buyer) + BPP (seller). "UPI for e-commerce."
- model: server-to-server, async-first (ACK+callbacks), Ed25519 non-repudiation; UI decoupled from protocol
- layering: Beckn (base protocol) + ONDC extension (domain contracts, IGM, RSF, Network Observability, registry)
- roles: BAP, BPP, BG (gateway, discovery only), Registry (identity/keys, lookup-only), NO (network observability), NP (any participant). One company can be BAP+BPP with separate subscriber ids.
- lifecycle stages: discovery → order → fulfillment → post-fulfillment, plus IGM (grievance) + RSF (settlement). See [[ondc-protocol]].
- domains: code `ONDC:XYZ##` — RET10 grocery, RET11 F&B, RET12 gen-merch, TRV10 mobility, FIS10 financial, LOG10 logistics. See [[domain-version]].
- FAQ + glossary: see ref:ondc-ecosystem (subscriber_id vs subscriber_url, ops_no, whitelisting, NO push rules, lookup v1/v2, etc.)

## Relations
- context-for → [[workbench]] ; on-the-wire → [[ondc-protocol]] ; infra → [[registry-gateway]]
- NO push → [[observability]] / [[recorder-service]]

## Open questions
- (network-observability.md full schema registered as reference, not ingested — UDP/observability parked per owner)
