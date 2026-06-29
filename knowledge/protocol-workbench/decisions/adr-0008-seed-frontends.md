---
id: adr-0008
date: 2026-06-26
grill-ref: repo exploration — ui-frontend + backoffice
status: accepted
changes: [ui-frontend, backoffice-frontend, schema-validation, run-flow-test]
---

# Seed frontends + UI usage procedures

## Question / context
What can users do via the UI, and how do UI actions reach downstream services?

## Decision
Captured: ui-frontend pages/tools (schema-validation, scenario→flow-testing, playground, developer-guide, auth-header), ui-backend as mediator + its routes, backoffice cache-management UI; plus the schema-validation and run-flow-test procedures.

## Assumptions & perception
- Source: automation-frontend + automation-backoffice src (code-grounded).
- ui-frontend submodule pinned at branch `mofahsan-patch-12-5` (verify vs main).
- /ai proxy purpose unclear — may be the MCP/LLM runtime surface (open question).

## KB effect
- frames ui-frontend, backoffice-frontend; scripts schema-validation, run-flow-test.
