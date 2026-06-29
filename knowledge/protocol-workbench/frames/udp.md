---
id: udp
kind: concept
isa: concept
asof: 2026-06-26
scope: desired
confidence: low
source: interview 2026-06-26 (concept-level, firm) + recorder/network-observability
changed-by: adr-0024
---

# UDP — real-time transaction-log analytics platform

UDP is the destination to which **all transaction logs are pushed in real time** to build **network-wide intelligence / analytics** across ONDC. Captured firmly at the concept level: the concept and some pieces are in place, but much is still unknown / evolving — do NOT over-specify mechanics.

## Slots (concept-level, firm)
- purpose: real-time push of all transaction logs → network-wide intelligence & analytics
- scope: network-wide (across NPs), not workbench-local
- maturity: concept + some pieces in place; many unknowns (treat specifics as not-yet-known)
- likely-feed: the recorder-service Network-Observability push (→ analytics endpoint) is the probable on-ramp — see [[recording-path]] / [[observability]] (relationship to confirm)

## Relations
- fed-by → [[recorder-service]] (transaction logs) / [[observability]] (NO push)
- produces → network-wide analytics/intelligence

## Open questions
- Full name / acronym expansion of "UDP" → owner: Shreyansh
- Exact pipeline (recorder/NO → UDP?), schema, real-time transport, and where intelligence surfaces → owner: Shreyansh (evolving)
