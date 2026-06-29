---
id: spec-authoring-sop
title: "Determining a new specification for a new domain (owner's old doc)"
source: owner-provided document (interview 2026-06-26)
type: doc
added: 2026-06-26
status: ingested
---

# Stored reference: authoring a new domain specification

Owner's framing (high level): the KEY authored artifacts are **flow, examples, logic, and L1 validations**. `openapi.yaml` is the base schema spec **derived from the base Beckn schema**. **Attributes / tags / enums + definitions are HUMAN input — schematic meaning, not ground truth; well-reviewed/cross-referenced in many cases.** Where the base lacks info, a human seed fills the gap in most cases. L1 validations are well tested. (Note: an earlier "AI-derived" framing was retracted by the owner — adr-0030.)

## Business Specifications
1. Identify Business Requirements — flow of transaction; recommended flow; all parameters of transaction.
2. Identify Statutory Requirements — transaction flow; parameters of transaction.
3. Identify Roles/Players/Elements — what is sold (Item); who sells (Provider); how received (Fulfilment: when/where).

## Technical Specifications
1. Identify the APIs — APIs↔business flow; required APIs; map flow→APIs (recommended flow); determine BAP & BPP imperative of flow; determine allowed unsolicited APIs; extra business flow (revalidate flows until 0).
2. Role mapping — contract roles↔business roles: Item↔commodity/service sold; Provider↔person/org providing; Fulfilment↔how/when/where/byWhom provisioned; Order↔purchase order/invoice/transaction agreement.
3. Parameter mapping — schema attributes↔business terms; identify Tag & Tag Groups (Informational = carry info of parent object lacking a first-class field; Functional/Operational = carry an operation + elements to transmit); identify value patterns/illustration; extra business attributes (revalidate until 0).
4. Identify the Parent/Core line of Business — if present, revalidate elements against the core; if not, find existing spec in same business sector; if multiple, extract common elements and revalidate per-spec outputs.
5. Determine all illustration — various recommended business flows; usage of mandatory/optional tags; illustrative use of attributes + recommended standards.

## Elements authored/updated in the specification YAML
- Enums
- Tags
- Examples/Illustration
- Business-specific workflows + descriptions
