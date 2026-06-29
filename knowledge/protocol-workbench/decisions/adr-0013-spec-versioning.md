---
id: adr-0013
date: 2026-06-26
grill-ref: grill Q3 — versioning rule, divergence from ONDC version
status: accepted
changes: [domain-version]
---

# Spec version always in sync with ONDC; upgrade = new branch

## Question / context
When is a new version/branch cut, and can the workbench's version diverge from ONDC's official spec version?

## Decision
- The branch's domain+version is ALWAYS in sync with the actual ONDC/protocol spec version — it cannot diverge.
- A protocol/spec version upgrade always produces a NEW branch; there is never an in-branch version bump.
- Commits within a branch (and workbench file versions) have no correlation to the spec version — only the branch name is the authoritative version pointer.
- Multiple versions of a domain coexist concurrently, each on its own branch.

## Assumptions & perception
- Owner confirmed hypothesis and explicitly stated version "cannot diverge" and is "always in sync" (interview).

## KB effect
- frame domain-version: version-sync, versioning-rule, commit-vs-version, coexistence slots.
- triples: in-sync / upgrade=new-branch / no-correlation / coexistence facts.
