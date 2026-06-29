---
id: adr-0053
date: 2026-06-29
grill-ref: owner — after a long w2w live-debug session; capture depth + narrowing + MCP proposal + keep-knowledge-updated
status: accepted
changes: [tester-playbook, mcp-runtime-agent, recorder-service, session-difficulty, mock-playground-service]
---

# Capture the real debugging depth, a root-cause-first narrowing playbook, and a runtime-MCP proposal

## Context
A single symptom (`on_confirm` message_id mismatch) was 5+ layers from the root (spec `on_confirm.requirements()` needs `customer_*`, which no saveData populates because the offline flow has no `init`). The whole session was manual redis-cli/docker-logs/curl/base64/build-tools iteration. Owner asked: (a) make the KB reduce this depth, (b) suggest an MCP to access/debug the running instance, (c) record "how to keep knowledge up to date".

## Decision
- Added a **root-cause-first narrowing playbook** to [[tester-playbook]]: for any on_X NACK, FIRST check whether the mock emitted a `buildErrorPayload` (error not message, fresh createGenericContext id) and why generation failed (requirements/generator), BEFORE chasing the protocol-level NACK. An on_X NACK is usually a generation symptom.
- Captured the **full w2w-local fix chain** (TTL, protocolValidations, dynamic-form idempotency, /callback redirect, CORS x-api-key, crypto.randomUUID→uuidv4, message_id echo, on_confirm requirements relax) + **deploy facts** (push-to-db + clear-flows, no api-service rebuild for mock fns; node --check base64; API-step `input` doesn't prompt) in references/w2w-debugging-depth-and-mcp-2026-06-29.md.
- **Proposed an ONDC Workbench Runtime MCP** (service layer over redis/db-service/config-service/docker), headlined by `wb_trace_action(txnId, action)` that correlates api-service NACK + mock generation outcome + decoded requirements/generate in one call. Aligns with adr-0010/adr-0024 (MCP = service layer over raw runtime; read-mostly + explicit writes). Recorded under [[mcp-runtime-agent]].

## Assumptions & perception
- Source: this session's live debugging. High confidence on the chain + deploy facts (all verified live). The MCP is a proposal (not yet built).

## KB effect
- tester-playbook: root-cause-first break-point added. mcp-runtime-agent: concrete runtime-debug tool set proposed. New references doc. Owner asks (keep-updated, MCP) recorded. Reinforces the auto-update-on-fixes practice.
