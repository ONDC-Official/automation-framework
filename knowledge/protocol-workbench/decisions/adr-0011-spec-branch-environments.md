---
id: adr-0011
date: 2026-06-26
grill-ref: grill — "what do you want to understand about spec lifecycle" → owner answer on source + branch prefixes
status: accepted
changes: [automation-specifications, domain-version]
---

# Spec source is the branch; prefix = workbench environment

## Question / context
Asked the owner about spec origin and what `draft-*` vs `release-eks-*` branch prefixes mean.

## Decision
- The `automation-specifications` branch IS the authoritative source of the protocol definition (confirmed; not merely derived).
- The branch prefix denotes the target **workbench environment**, not just maturity:
  - `draft-*` → non-prod (dev/staging) environment.
  - `release-eks-*` → NP-facing PRODUCTION environment.
- Promotion `draft → release-eks` = promoting a spec into the NP-facing prod env.

## Assumptions & perception
- Owner confirmed my hypothesis on source + that release = NP-facing prod (interview).
- Still open: the exact gate for promotion (validation/Pramaan/review/sign-off) and which non-prod env `draft-*` maps to (dev vs staging).

## KB effect
- frame automation-specifications: authoritative-source + branch→environment slots; open Qs narrowed.
- frame domain-version: branch-naming slot annotated with environment.
- triples: source + branch-prefix→env facts.
