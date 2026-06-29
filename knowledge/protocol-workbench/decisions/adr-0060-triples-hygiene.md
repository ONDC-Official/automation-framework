---
id: adr-0060
date: 2026-06-29
grill-ref: owner — "why do I see the triplets of my debugging session?"
status: accepted
changes: [triples, knowledge-keep-updated]
---

# Triples hygiene: remove debugging-session narrative from triples.md

## Question / context
Owner noticed debugging-session facts in triples.md. By design, triples = pure, atomic, timeless current-truth for retrieval; the runtime/debug session had written its incident journal (the on_confirm root-cause chase with session/txn ids, the dated dynamic-form "fix-applied" play-by-play, "reconciled-by adr-…", dated statuses) into it.

## Decision
- triples.md holds only ATOMIC, TIMELESS facts. Removed ~50 episodic/incident lines (the 391-437 journal + scattered dated/this-run entries). The incident detail already lives in adr-0048..0053 + references/w2w-debugging-depth-and-mcp-2026-06-29.md — its correct home.
- Kept the durable MECHANISMS the debug surfaced, rephrased timelessly, under a "Durable debug mechanisms" subsection (async-predecessor check scope, transaction_history-unpopulated echo behavior, dynamic-form /callback completion, secure-context crypto limitation, api-step input not promptable, local bap_id/TTL prerequisites, deploy mechanism, the on_X-NACK heuristic → tester-playbook, runtime-MCP as desired).
- Added a header rule to triples.md + the triples-hygiene principle to [[knowledge-keep-updated]].

## Assumptions & perception
- triples.md 437 → 388 lines; no durable fact dropped (relocated/retained). Recommend folding this rule into the grill-me-kb skill (GRILL-ME-KB-IMPROVEMENTS.md).

## KB effect
- triples.md curated; knowledge-keep-updated triples-hygiene slot.
