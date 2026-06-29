---
id: adr-0001
date: 2026-06-26
grill-ref: scope brief — "detailed runtime KB for Protocol Workbench, multi-persona, multi-book"
status: accepted
changes: [INDEX, persona, workbench]
---

# Initialize Protocol Workbench knowledge book

## Question / context
Owner wants a retrieval-ready KB on the ONDC Protocol Workbench runtime to train a multi-persona agent (NP devs, architects, PMs, QA, ONDC use-case authors, MCP runtime agent). Empty KB at start.

## Decision
- Single master book `knowledge/protocol-workbench/` with one frame per component (component sub-books grouped under a shared taxonomy in INDEX) + scripts for runtime procedures + triples for fast lookup.
- Persona-routing guide lives in INDEX and [[persona]].
- Master INDEX is the navigation root for all personas.

## Assumptions & perception
- Owner stated: CODE + its runtime behavior are ground truth; READMEs may be stale; derived KB supersedes both (interview).
- One framework-level book suffices now; split a component into its own book only if it grows large (defer).

## KB effect
- created INDEX.md, frames/workbench, frames/persona.
