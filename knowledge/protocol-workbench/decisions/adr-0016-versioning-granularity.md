---
id: adr-0016
date: 2026-06-26
grill-ref: grill Q6 — status/versioning granularity (domain+version vs usecase/flow)
status: accepted
changes: [domain-version, spec-lifecycle-status, flow-usecase]
---

# Versioning granularity: domain+version, with split-usecase exception

## Question / context
Is the versioning / lifecycle-status unit domain+version, or finer (usecase/flow)?

## Decision
- Primary versioned unit = domain + version.
- Exception: some domains have been broken into a use-case that is itself versioned → unit becomes domain + usecase + version in those cases.
- Use-cases and flows are NOT independently versioned today (only the split-usecase case carries a version). Flows are never versioned.
- The lifecycle-status flag applies at whichever versioned unit applies.

## Assumptions & perception
- Owner: "primarily domain and version; usecase or flow as of today are not versioned; in some cases the domain has been broken to usecase and versioned" (interview). "as of today" → may evolve.

## KB effect
- domain-version: versioning-granularity block.
- spec-lifecycle-status: granularity slot.
- flow-usecase: versioning note.
- triples: versioning-unit + flow/usecase not-versioned facts.
