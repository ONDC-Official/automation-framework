---
id: adr-0017
date: 2026-06-26
grill-ref: grill — Major.Minor.Fix version-number semantics
status: accepted
changes: [domain-version]
---

# Version-number semantics: Major.Minor.Fix

## Question / context
What do the three parts of a spec version number mean?

## Decision
- Fix (patch): protocol-miss corrections, no new capability — e.g. adding a value-only enum with operational impact but not operationally optional; correcting a flow miss (payment link in on_confirm instead of on_init).
- Minor: additive new capability — new flow, new enums with call-to-action enabling flow branching, or new domain functionality as a protocol extension.
- Major: drastic change — protocol, network architecture, API payload, and many elements change substantially.

## Assumptions & perception
- Owner-provided definitions with examples (interview). Maps to ONDC spec version since branch version is in sync with ONDC (see [[domain-version]] adr-0013).

## KB effect
- domain-version: version-number-semantics block.
- triples: version-scheme + per-level meaning.
