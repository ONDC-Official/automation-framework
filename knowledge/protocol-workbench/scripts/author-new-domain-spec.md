---
id: author-new-domain-spec
kind: script
confidence: medium
source: ref:spec-authoring-sop + interview 2026-06-26
changed-by: adr-0028
---

# Author a new domain specification (SOP)

How a protocol architect determines/authors a new domain (or version) spec for [[automation-specifications]]. Key authored artifacts = flow, examples, logic, L1 validations; schema is derived. (source: ref:spec-authoring-sop)

## Entry conditions
- a new domain (or version) needed; base Beckn schema available

## Roles
- protocol architect / spec owner / protocol engineers; AI (attribute derivation); human reviewer

## Scenes (ordered)
1. Business spec — identify business requirements (flow, recommended flow, all txn parameters), statutory requirements, and roles/elements (Item=what's sold, Provider=who sells, Fulfilment=how/when/where received).
2. Identify APIs — map business flow → APIs; pick required APIs; set the recommended flow; determine BAP/BPP imperative per step; determine allowed unsolicited APIs; iterate until no "extra business flow" remains.
3. Role mapping — contract roles ↔ business roles (Item/Provider/Fulfilment/Order).
4. Parameter mapping — schema attributes ↔ business terms; identify Tags & Tag Groups (Informational vs Functional/Operational); value patterns/illustrations; iterate until no "extra business attribute" remains.
5. Anchor to core LOB — revalidate against the parent/core line of business; reuse common elements from sibling specs.
6. Illustrations — recommended business flows; mandatory/optional tag usage; attribute usage standards + examples.
7. Author the YAML — encode enums, tags, examples/illustration, business workflows + descriptions into config/ (flows/, attributes/, validations/, actions/, errors/, docs/); openapi.yaml derived from base Beckn schema; attributes AI-derived + human-reviewed; L1 validations authored + well-tested.
8. Build/validate — build-tools parse+validate → build.yaml (see [[spec-to-runtime]]).

## Derivation notes (what is authored vs derived)
- openapi.yaml: DERIVED from base Beckn schema (not hand-written per domain).
- attributes / tags / enums + definitions: HUMAN input — schematic meaning, NOT ground truth; well-reviewed/cross-referenced in many cases.
- gap/seed: where the base schema has no info, a human seed exists in most cases to fill the gap (a key place this semantic layer + KB add value).
- flows / examples / logic / L1 validations: the core HUMAN-authored, well-tested artifacts. "logic" = requirement+generation+validation JS + L1 governing journey evolution (see [[spec-logic]]); examples currently ~1 branch (may grow to all branches).

## Results
- a domain+version config/ ready to build into an [[api-service]]; in sync with the ONDC/Beckn spec version.

## Open questions
- Tooling that does the AI attribute derivation (where it lives) → owner: Shreyansh
- Review gate for attributes (when human review is required vs not) → owner: Shreyansh
