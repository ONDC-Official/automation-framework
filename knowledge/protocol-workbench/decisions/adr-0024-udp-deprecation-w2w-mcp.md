---
id: adr-0024
date: 2026-06-26
grill-ref: grill — UDP, deprecation scope, w2w-fix approach, MCP accessibility
status: accepted
changes: [udp, spec-lifecycle-status, w2w-testing, mcp-runtime-agent, observability, recorder-service]
---

# Grill: UDP concept, deprecation out of scope, w2w-fix approach, MCP accessibility lean

## Decision
- **UDP** (new concept frame): all transaction logs are pushed in real time to UDP to build network-wide intelligence/analytics. Captured firmly at concept level; concept + some pieces in place, much unknown — do not over-specify. Probable feed = recorder Network-Observability push.
- **Deprecation/sunset: OUT OF SCOPE** for now (was WIP). Lifecycle-status flag values still recorded; retire flow not documented.
- **W2W fix**: desired; approach = owner builds system knowledge (this KB) first, then works with agents and/or devs as bandwidth allows.
- **MCP accessibility lean**: to assist a testing NP, prefer the SERVICE LAYER (ui-backend, backoffice, db-service REST) over RAW DB — APIs enforce auth, encapsulate logic, survive schema changes; raw DB couples to schema/SOP and bypasses transforms. Raw DB only read-only for analytics not exposed via API.

## Assumptions & perception
- Owner statements (interview): UDP firm-at-concept; deprecation out of scope; w2w fix later via agents/devs; asked for a recommendation on testing-NP accessibility (Claude recommended service layer; owner to confirm direction).

## KB effect
- new frame udp; observability + recorder link to udp.
- spec-lifecycle-status: deprecation out of scope.
- w2w-testing: fix approach.
- mcp-runtime-agent: accessibility lean slot.
