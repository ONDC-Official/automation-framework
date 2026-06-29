---
id: adr-0015
date: 2026-06-26
grill-ref: grill Q5 — deprecation; owner disambiguated the two senses of "draft"
status: accepted
supersedes: adr-0011
changes: [automation-specifications, domain-version, ui-frontend, spec-lifecycle-status]
---

# Disambiguate "draft": branch-env vs ecosystem lifecycle status

## Question / context
Asked how versions are deprecated. Owner clarified that "draft" was being used in two distinct senses, and that deprecation is not finalized.

## Decision
- **Branch prefix** `draft-*` = the dev/QA workbench DEPLOYMENT ENVIRONMENT (refines adr-0011's "non-prod (dev/staging)" to dev/QA); `release-eks-*` = NP-facing prod env.
- **Ecosystem lifecycle status** is a SEPARATE concept: a domain+version carries a status flag (draft | live | to-be-deprecated | deprecated) in the **developer guide**. This is "ecosystem versioning" maturity, orthogonal to deployment env — an ecosystem-"draft" version can run in PROD ("draft in prod").
- **Deprecation/sunset flow is NOT finalized (WIP)**; the status flag exists but the retire process is undefined.

## Assumptions & perception
- Owner: branch-draft = dev/QA env; the draft/live/deprecated flag in the guide is ecosystem versioning; deprecation not finalized (interview).
- Supersedes adr-0011 only on the draft-semantics framing (which conflated branch-env with maturity); the branch-prefix→environment mapping itself stands.

## KB effect
- new frame spec-lifecycle-status (concept) with the disambiguation.
- automation-specifications: draft-* refined to dev/QA; explicit warning vs lifecycle status.
- domain-version: lifecycle-status slot.
- ui-frontend: developer-guide carries the status flag.
- triples: status values/carrier/orthogonality; deprecation WIP.
