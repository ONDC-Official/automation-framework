---
id: adr-0014
date: 2026-06-26
grill-ref: grill Q4 — authoritative source for "what domains/versions are live"
status: accepted
changes: [automation-specifications, config-service]
---

# "What's live" = branch set; db/config-service is the mirror

## Question / context
What is the authoritative answer source when asked which domains/versions are supported in prod vs non-prod?

## Decision
- Source of truth = the BRANCHES in automation-specifications: `release-eks-*` = live in NP-facing prod; `draft-*` = available in non-prod.
- config-service builds / `/ui/senario` (and the pushed-to-db spec data) are a RUNTIME MIRROR of what's currently deployed for an env — not the source of truth.

## Assumptions & perception
- Owner confirmed: branches = source of truth, db/config-service = runtime mirror (interview).

## KB effect
- frame automation-specifications: "what's live" source-of-truth block; open Qs narrowed to deprecation + draft-env.
- frame config-service: runtime-mirror relation.
- triples: branch-defines-live + config-service-is-mirror facts.
