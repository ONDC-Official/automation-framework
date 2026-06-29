---
id: domain-version
kind: class
isa: concept
confidence: high
source: repo build-api-service.sh, spec config info block
changed-by: adr-0003
---

# Domain + version

A domain (e.g. `ONDC:FIS12`) at a specific spec version (e.g. `2.0.3`) is the unit of protocol the workbench runs. One spec branch = one domain+version = one api-service instance.

## Version-number semantics: Major.Minor.Fix (adr-0017)
- **Fix** (patch): protocol-miss corrections with no new capability. E.g. adding a value-only enum that has operational impact but is NOT operationally optional; correcting a flow miss (e.g. payment link shown in on_confirm instead of on_init). No new functionality — just bringing the spec in line.
- **Minor**: additive new capability — a new flow, new enums that carry a call-to-action and enable flow branching, or entirely new domain functionality added to the protocol as an extension.
- **Major**: drastic change — the protocol itself, network architecture, API payload shape, and many other elements change substantially.

## Versioning granularity (adr-0016)
- Primary unit = **domain + version**.
- Exception: some domains have been split into a **use-case** that is itself versioned → unit becomes **domain + usecase + version** in those cases.
- Use-cases and flows are NOT independently versioned today (only the above split-usecase case carries a version).

## Slots
- branch-naming: `draft-<DOMAIN>-<version>` (non-prod env) or `release-eks-<DOMAIN>-<version>` (NP-facing prod env); prefix = target workbench environment (adr-0011)
- domain-code pattern: `ONDC:XYZ##` (3 letters + 2 digits). Examples: RET10 grocery, RET11 F&B, RET12 gen-merch, TRV10 mobility, FIS10 financial, LOG10 logistics (see [[ondc-ecosystem]])
- service-name-norm: lowercase, strip ':' from domain, replace '.'→'-' in version → e.g. api-ondcfis12-2-0-3
- usecases: a domain+version contains x-usecases (e.g. GOLD LOAN, PERSONAL LOAN for FIS12; search/order for retail)
- single-active: only one domain+version on host port 3032 at a time
- version-sync: the branch's version ALWAYS equals the actual ONDC/protocol spec version — it CANNOT diverge (adr-0013)
- versioning-rule: a protocol/spec version upgrade ⇒ a NEW branch. Never a version bump within an existing branch.
- commit-vs-version: commits within a branch (and workbench file versions) have NO correlation to the spec version; the branch name (domain+version) is the thing in sync with the real spec version
- coexistence: multiple versions of a domain run concurrently (e.g. several FIS12 versions enabled) — each its own branch
- lifecycle-status: each domain+version also carries an ecosystem-versioning status (draft | live | to-be-deprecated | deprecated) via a developer-guide flag — distinct from branch-prefix env. See [[spec-lifecycle-status]].

## Relations
- realized-by → [[api-service]]
- contains → [[flow-usecase]]
- source → [[automation-specifications]]

## Open questions
- Canonical current list of supported domains+versions → owner: Shreyansh
