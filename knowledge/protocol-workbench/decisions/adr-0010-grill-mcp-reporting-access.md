---
id: adr-0010
date: 2026-06-26
grill-ref: grill — Pramaan routing, MCP agent, access policy
status: accepted
changes: [report-service, report-pramaan, generate-report, persona, mcp-runtime-agent]
---

# Grill answers: reporting volatility, MCP scope, access policy

## Question / context
Asked owner about Pramaan local-vs-external routing, the MCP runtime agent's integration/data source, and per-persona access restrictions.

## Decision
- **Reporting (report-service + report-pramaan) is under active redesign** — functional now but being re-architected. Keep reporting knowledge ABSTRACT; treat specific routing/format details as volatile (asof 2026-06-26), not stable truth. Do NOT over-specify Pramaan local-vs-external routing.
- **MCP runtime support agent (future scope)**: will have access to the workbench RUNTIME and its data sources exposed via MCP (e.g. logs); some services may later expose their own MCP support features. It is NOT the ui-frontend /ai/proxy. Capture as a future-scope goal, not current behavior.
- **Access policy: no per-persona restrictions** — every persona gets the same grounded truth; only framing/entry-point differs. Agent answers with brief reasoning.

## Assumptions & perception
- Owner stated reporting module is mid-redesign → its frames should carry a volatility flag and lower emphasis.
- MCP is future scope; integration mechanism not finalized.

## KB effect
- report-service/report-pramaan/generate-report: add `status: under-redesign (asof 2026-06-26)` volatility note.
- persona: record no-restriction policy; mcp-runtime-agent future-scope.
- new frame mcp-runtime-agent.
