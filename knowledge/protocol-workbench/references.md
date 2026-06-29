# References

> ⏳ TEMPORARY layer (adr-0062/0063). References are transient inputs/run-reports + **tactical change/diff/release/incident logs**, NOT durable knowledge. (Durable navigation = `LOCATOR.md`; durable failure patterns = `patterns/`.) Lifecycle: `indexed` (registered) → `ingested` (facts folded into frames+ADRs) → **prune**. Once ingested, the reference can be deleted; the durable facts live in frames/triples and the episode in ADRs. Run reports (runtime-verification, w2w-debugging) may be kept briefly as audit, then cleaned. The commit-baseline note is the exception (operational, keep current one). On `kb-sync-on-diff`, drop stale/ingested references.

- id: repo-automation-framework
  title: "automation-framework monorepo (orchestrator + 9 submodules)"
  source: /Users/shreyansh/Desktop/git_workspace/workbench-knowledge/automation-framework
  type: code
  added: 2026-06-26
  status: ingested   # seeded into frames/scripts/triples via adr-0002..0008

- id: dev-docs
  title: "developer-docs (about-ondc, network-observability, ondc-FAQs, registry-gateway)"
  source: automation-framework/docs/developer-docs/
  type: doc
  added: 2026-06-26
  status: indexed    # registry/gateway + NO partially ingested; about-ondc / ondc-FAQs not yet folded in

- id: faq
  title: "Workbench FAQ (troubleshooting)"
  source: automation-framework/docs/FAQ.md
  type: doc
  added: 2026-06-26
  status: ingested   # symptoms folded into per-service edge points

- id: run-locally
  title: "RUN-LOCALLY.md + setup-local.sh + Instructions.md + steps.md"
  source: automation-framework/
  type: doc
  added: 2026-06-26
  status: ingested   # → script local-dev-setup

- id: ondc-registry-spec
  title: "ONDC registry/gateway live endpoints"
  source: prod.registry.ondc.org / staging.registry.ondc.org / preprod.registry.ondc.org
  type: url
  added: 2026-06-26
  status: indexed

- id: spec-authoring-sop
  title: "Determining a new specification for a new domain (owner's old doc)"
  source: references/spec-authoring-sop.md (owner-provided, interview 2026-06-26)
  type: doc
  added: 2026-06-26
  status: ingested   # → script author-new-domain-spec + automation-specifications authoring slots

- id: ondc-ecosystem
  title: "ONDC ecosystem (distilled) — background, registry/gateway ops, FAQ, glossary"
  source: references/ondc-ecosystem.md (from docs/developer-docs about-ondc/ondc-FAQs/registry-gateway)
  type: doc
  added: 2026-06-26
  status: ingested   # → frames ondc-ecosystem, ondc-protocol, registry-gateway, domain-version (adr-0035)

## Ingested ONDC docs (adr-0035)
- dev-docs/about-ondc.md → ingested into [[ondc-ecosystem]] / [[ondc-protocol]]
- dev-docs/ondc-FAQs.md → curated FAQ in references/ondc-ecosystem.md
- dev-docs/registry-gateway.md → ingested into [[registry-gateway]]

## Not yet ingested (parked per owner)
- dev-docs/network-observability.md (72KB) — full NO API schema (UDP/observability parked; registered as reference only)

- [runtime-verification-2026-06-28](references/runtime-verification-2026-06-28.md) — live grill of the 10 paths against the running FIS12 2.0.3 stack (ADRs 0037-0045).

- [w2w-debugging-depth-and-mcp-2026-06-29](references/w2w-debugging-depth-and-mcp-2026-06-29.md) — real debugging depth of the on_confirm saga, root-cause-first narrowing playbook, full w2w-local fix chain, and the ONDC Workbench Runtime MCP proposal (adr-0053).
