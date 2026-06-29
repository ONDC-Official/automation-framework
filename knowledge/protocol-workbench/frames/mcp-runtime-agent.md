---
id: mcp-runtime-agent
kind: instance
isa: concept
scope: desired
asof: 2026-06-26
confidence: low
source: interview 2026-06-26 (future scope)
changed-by: adr-0010
---

# MCP runtime support agent (future scope)

A planned MCP server that exposes the Protocol Workbench RUNTIME for a support agent — and the consumer this knowledge book is partly built to train. Future scope; mechanism not finalized.

## Slots
- status: future scope (not yet built)
- data-sources: workbench runtime data exposed via MCP — e.g. service logs, runtime state; some services may later expose their own MCP support features
- knowledge-source: this KB (frames/triples/scripts) + spec raw_table.json (RAG candidate)
- NOT: not the ui-frontend `/ai/proxy` (that is a generic forward proxy, unrelated)
- behavior-target: grounded answers with brief reasoning; same truth to all personas (no access restrictions)
- accessibility-lean (adr-0024): to assist a testing NP, prefer the SERVICE LAYER — ui-backend (/flow validate/trigger/proceed/current-state, sessions+difficulty, reports), backoffice (cache inspect/edit/clear), db-service REST (payloads/sessions/analytics, x-api-key) — over RAW DB. Service APIs enforce auth, encapsulate logic, and survive schema changes; raw DB couples to Mongo schema/SOP and bypasses transforms (uppercasing, sha256 session ids, GridFS). Raw DB only read-only for analytics not exposed via an API.

## Proposed runtime-debug tool set (owner-requested 2026-06-29, adr-0053)
Motivated by long manual live-debug sessions (redis-cli/docker-logs/curl/base64/build-tools). A read-mostly service-layer MCP with explicit write tools:
- **`wb_trace_action(txnId, action)`** — headline; correlates api-service NACK reason + mock generation outcome (success vs buildErrorPayload + error.code + "Requirements not met" description) + decoded requirements/generate for the step, in ONE call (collapses ~20 manual steps).
- `wb_logs(service, sinceSec, grep, correlationId)` ; `wb_redis(pattern|key, db)` (sessions/MOCK_DATA/txn-cache/FLOW_STATUS/form_completed/redirection_url + TTLs) ; `wb_db_payloads(txnId)` ; `wb_flow_status(sessionId, txnId)` (both w2w partitions) ; `wb_mock_fn(...,fn,decode)` (base64-decode requirements/generate/validate/saveData) ; `wb_deploy_flow(flowId)` (parse/validate/node-check/push-to-db/clear-flows) ; `wb_difficulty(sessionId)`.
Full proposal: `references/w2w-debugging-depth-and-mcp-2026-06-29.md`. Consistent with the service-layer lean below.

## Relations
- consumes → [[workbench]] runtime + this KB
- serves → [[persona]] (all personas)

## Open questions
- Which services will expose MCP support features first? → owner: Shreyansh
- Transport/discovery + how runtime logs are surfaced via MCP → owner: Shreyansh
