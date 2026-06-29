---
id: knowledge-keep-updated
kind: concept
isa: concept
confidence: high
source: interview 2026-06-29 + grill-me-kb method
changed-by: adr-0054
---

# Keeping the knowledge book up to date

The practice for keeping this KB current as the workbench changes (owner-asked 2026-06-29). The KB only stays valuable if every confirmed fix/mechanism/runtime observation is written back.

## Purpose: low-token targeted debug (adr-0058)
- The KB exists so an agent debugs SPECIFICALLY — symptom → exact file:line/mechanism → fix — instead of reloading full code context every time. Optimize frames for this: terse, pointer-rich (file:line, "to debug X look at Y", symptom→location), not prose dumps. The [[tester-playbook]] narrowing playbook is the exemplar.
- Knowledge ↔ code linkage: every frame names its repo+files in `source:`; on any code diff, run script [[kb-sync-on-diff]] to revisit the mapped frames and update only what changed.

## Slots (the write-back loop)
- trigger: after EVERY confirmed fix, mechanism, or runtime observation (code change, deploy gotcha, live behavior).
- write-back (3 parts): update the relevant **frame** slot to the new truth + add an atomic **triple** + append an **ADR** in `decisions/` (next number; `supersedes:` if it overturns a prior belief). Keep every frame reachable from INDEX.
- **triples hygiene (adr-0060):** `triples.md` holds only ATOMIC, TIMELESS facts (current system behavior/mechanism). Incident/debugging narrative — root-cause chases, session/txn ids, dated "fix-applied" steps — goes in the **ADR** + a `references/` run report, NEVER as triples. A durable mechanism a debug session surfaces is fine (phrased timelessly); the episode is not.
- correction rule: when correcting a belief, explicitly record the WRONG assumption so it is not re-derived (e.g. "an on_X NACK is NOT a message_id bug — it's a mock-generation symptom"; "local bap_id port is REQUIRED, do not 'fix' it").
- ground truth: code + observed runtime; the derived KB supersedes code/README where they disagree.
- **live vs desired (adr-0056):** keep ACTUAL/live knowledge (runtime-proven, current scope, aligned to the actual release + live code) strictly separate from DESIRED/aspirational features (architect wishlist, not built). Desires go in [[desired-by-architect]] or carry `scope: desired` in frontmatter — never asserted as existing. Knowledge can be idealized; FEATURE SCOPE must match live code. (KB versioning deferred.)
- **frontend = runtime-proven only (adr-0056):** some frontend code is legacy/dead (e.g. stale `trigger/api-service/:action` route, crypto.randomUUID TODO). Record frontend behavior only when observed at runtime; do not document a code path's mere presence as actual behavior.
- runtime loop: a separate Claude Code session runs `RUNTIME-VERIFICATION-PROMPT.md` (memory pointer `CLAUDE.md`) against the live stack and writes frames+ADRs back; this Cowork session reconciles them.
- reduce future depth: capture root-cause-first narrowing (see [[tester-playbook]]) and deploy facts so the next debug is a few steps, not dozens.

## Proposed tooling
- a runtime-debug MCP (wb_trace_action, wb_logs, wb_redis, …) to collapse the manual redis/docker/curl iteration — see [[mcp-runtime-agent]].

## Relations
- governs → the whole KB ; supports → [[mcp-runtime-agent]], [[tester-playbook]], [[w2w-testing]]
- full write-back example: `references/w2w-debugging-depth-and-mcp-2026-06-29.md`

## Open questions
- Build the runtime-debug MCP so the write-back loop is semi-automated → owner: Shreyansh
