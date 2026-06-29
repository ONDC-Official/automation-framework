---
id: automation-specifications
kind: instance
isa: spec-repo
part-of: workbench
confidence: high
source: repo automation-specifications/ + api-service/config/ + build-api-service.sh
changed-by: adr-0003
---

# automation-specifications (the protocol source of truth)

The git repo holding ONDC domain specs and the **authoritative source** of the protocol definition. Each **branch = one domain+version** (e.g. `draft-FIS12-2.0.3`, `release-eks-RET10-1.2.5`, `draft-TRV11-1.0.0`). `build-api-service.sh` clones it into `api-service/` and checks out the requested branch. This is where a protocol querent's answer ultimately lives.

## Branch prefix = target workbench environment (adr-0011, refined adr-0015)
- `draft-*` → dev/QA environment of the workbench.
- `release-eks-*` → NP-facing PRODUCTION environment.
- Promotion `draft-* → release-eks-*` = deploying a spec from dev/QA into the NP-facing prod env.
- ⚠️ Do NOT confuse this branch-prefix "draft" (a DEPLOYMENT ENVIRONMENT) with the ecosystem **lifecycle status** "draft" (see [[spec-lifecycle-status]]). They are orthogonal — an ecosystem-"draft" version can run in prod.

## Spec config structure (`config/` folder, modular YAML with $ref)
- `index.yaml` — root manifest; `info` block: domain, version, x-usecases, x-branch-name, x-reporting
- `specs/openapi.yaml` — full OpenAPI 3.1.0 (paths + components)
- `flows/index.yaml` + `<UseCase>/<FlowId>.yaml` — flow definitions (ordered action sequences)
- `attributes/index.yaml` + `<UseCaseId>.yaml` — field-level metadata per usecase
- `validations/index.yaml` — L1 validation rules (x-validations / _TESTS_ tree)
- `errors/index.yaml` — error codes (code, Event, From, Description)
- `actions/index.yaml` — supportedActions state graph + apiProperties (async_predecessor, transaction_partner)
- `docs/` — markdown merged into x-docs

## Authoring (adr-0028; source: ref:spec-authoring-sop) — see script [[author-new-domain-spec]]
- key authored artifacts: flow, examples, logic, L1 validations (the high-value, well-tested parts). "logic" here = the holistic requirement+generation+validation+L1 that drives journey evolution — see [[spec-logic]].
- openapi.yaml: DERIVED from the base Beckn schema (not hand-authored per domain)
- attributes / tags / enums + definitions: HUMAN input — schematic meaning (semantic intent), NOT ground truth; well-reviewed / cross-referenced in many cases (adr-0030)
- gap/seed: where the base schema lacks info, a human SEED exists in most cases to fill it — this authored semantic layer (and this KB) is most useful exactly at those gaps (adr-0030)
- L1 validations: authored + well-tested
- method: business spec (requirements, statutory, roles Item/Provider/Fulfilment/Order) → technical spec (APIs↔flow, BAP/BPP imperative, unsolicited APIs, role+parameter mapping, Tags Informational/Functional) → encode enums/tags/examples/workflows in YAML

## Slots
- build-artifact: `build.yaml` = fully-resolved single file ($refs merged), validated, fed to generator
- rag-artifact: `generated/raw_table.json` (gen-rag-table) — flattened config for RAG/vector lookup (relevant for MCP runtime agent)
- branch-listing: `./scripts/build-api-service.sh` with no args lists available spec branches from remote
- promotion-gate (draft→release-eks): HUMAN approval + verification (no automated/Pramaan gate). Approvers/owners: spec owner / protocol architect + protocol engineers. (adr-0012)
- CI: spec-workflow.yml + deploy-onix.yaml exist but are **WIP / being finalized** — do NOT treat current CI/CD mechanics as stable truth. (adr-0012)

## Relations
- consumed-by → [[spec-to-runtime]] → produces [[api-service]]
- pushed-to → [[db-service]] (build.yaml + raw_table.json via push-to-db)
- read-by → [[config-service]] (serves spec/flows/actions to UI + mock)

## "What's live" source of truth (adr-0014)
- Authoritative set of supported domains/versions = the BRANCHES in this repo: `release-eks-*` = live in NP-facing prod; `draft-*` = available in non-prod.
- Runtime MIRROR (not source of truth): config-service builds / `/ui/senario` reflect whatever has been pushed-to-db for a given environment. To answer "what's live", read branches; the db/config-service shows what's currently deployed.

## Resolved (adr-0011, adr-0012, adr-0013, adr-0014)
- This repo's branch IS the authoritative spec source. Branch prefix = target workbench environment (draft=non-prod, release-eks=NP-facing prod).
- Promotion draft→release-eks gated by human approval+verification (spec owner / protocol architect + protocol engineers). CI/CD is WIP — out of scope.
- Branch version always in sync with ONDC spec version (cannot diverge); version upgrade ⇒ new branch (see [[domain-version]]).
- "What's live" = branch set; db/config-service is the runtime mirror.

## Open questions
- Finalized deprecation/sunset flow — WIP; lifecycle status flag exists in guide (see [[spec-lifecycle-status]]) → owner: Shreyansh
