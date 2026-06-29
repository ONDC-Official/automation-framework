# Protocol Workbench — Knowledge Book (Master Index)

Date: 2026-06-26 · Goal: A retrieval-ready, multi-persona knowledge book on the ONDC Protocol Workbench runtime and its components — used to train an agent that answers grounded queries with brief reasoning. Code + its runtime behavior are ground truth; this KB supersedes code/README where they disagree.

This is the **master book**. Each component is a frame (a sub-book); runtime procedures are scripts; atomic facts are in `triples.md`; how/why the KB changed is in `decisions/`.

## How to use this book (by persona)  → see [[persona]]

- **NP Developer (UI user)** → [[workbench]] → [[schema-validation]], [[run-flow-test]], [[ui-frontend]], [[validation-layers]]
- **NP Developer (local setup / contributor)** → [[local-dev-setup]], [[automation-framework]], per-service frames
- **Protocol Architect** → [[automation-specifications]], [[api-service]], [[validation-layers]], [[ondc-ecosystem]], [[ondc-protocol]], [[registry-gateway]]
- **API spec / protocol querent** → spec config in [[automation-specifications]] (enforced by [[api-service]], served via [[config-service]], RAG via raw_table.json)
- **Product Manager** → [[workbench]] core tools, [[report-service]], [[persona]]
- **Workbench Developer** → all component frames + [[spec-to-runtime]], [[flow-execution]], [[recording-path]]
- **End users (QA / playground / ONDC use-case authors)** → [[flow-usecase]], [[flow-execution]], [[generate-report]], per-frame "edge points"
- **MCP runtime agent** → triples.md + scripts + raw_table.json RAG

## Purpose & upkeep (read first)
This KB is the **low-token debug layer**: answer from the frame's exact file:line/mechanism (symptom→location) instead of reloading full code. Each frame is linked to its repo+files (`source:`); on any code diff, run [[kb-sync-on-diff]] to revisit only the mapped frames. Maintenance loop: [[knowledge-keep-updated]]. Architecture/layers: `ARCHITECTURE.md`.

## 🧭 Investigating or changing something? Scan `LOCATOR.md` first
The **Locator** (durable, Map layer) maps a concern → candidate **module → flows/methods (file:line) → frame** — scan it to narrow the area, then read only those (the token-reduction path). Reusable symptom→cause→fix **patterns** live in `patterns/` (golden rule: an on_X NACK is usually a mock-generation symptom, not a protocol bug — [[fm-001]]). Tactical change/diff/release/incident logs are **archivable in `references/` (temporary)**, not a permanent layer.

## Live vs desired (read first)
This book documents **live/actual** runtime — code + observed behavior, current release scope. **Desired/aspirational** features (architect wishlist, not built) are quarantined in [[desired-by-architect]] and frames tagged `scope: desired` — never assert these as existing. Frontend: record runtime-proven behavior only (some FE code is legacy). See [[knowledge-keep-updated]].

## Taxonomy (IS-A)

- system
  - [[workbench]] (Protocol Workbench)
- component (part-of workbench)
  - orchestrator
    - [[automation-framework]]
  - service
    - [[api-service]] (generated ONIX protocol runtime)
      - [[onix-server]] · [[onix-adapter]] · [[onix-plugins]] · [[signing-security]] · [[mock-service-embedded]] (ONIX sub-book)
    - [[mock-playground-service]]
    - [[recorder-service]]
    - [[db-service]]
    - [[config-service]]
    - [[report-service]]
    - [[report-pramaan]]
    - [[user-management-service]]
    - [[form-service]]
  - frontend
    - [[ui-frontend]]
    - [[backoffice-frontend]]
  - spec-repo
    - [[automation-specifications]]
  - libraries
    - [[automation-libraries]]
      - [[build-tools]] · [[api-service-generator]] · [[mock-runner-lib]] · [[validation-compiler]] · [[logger-package]]
- concept
  - [[ondc-ecosystem]]
  - [[ondc-protocol]]
  - [[domain-version]]
  - [[spec-lifecycle-status]]
  - [[flow-usecase]]
  - [[transaction-session]]
  - [[validation-layers]]
  - [[spec-logic]]
  - [[w2w-testing]]
  - [[flow-state-machine]]
  - [[session-difficulty]]
  - [[registry-gateway]]
  - [[observability]]
  - [[udp]]
  - [[persona]]
  - [[mcp-runtime-agent]] (scope: desired)
  - [[knowledge-keep-updated]]
  - [[desired-by-architect]] (scope: desired — NOT live)

## Sub-books (component frame groups)

- **Spec / protocol runtime**: [[automation-specifications]] · [[api-service]] · [[domain-version]] · [[spec-lifecycle-status]] · [[spec-logic]] · [[validation-layers]] · scripts [[spec-to-runtime]], [[author-new-domain-spec]]
- **ONIX internals (api-service)**: [[onix-server]] · [[onix-adapter]] · [[onix-plugins]] · [[signing-security]] · [[mock-service-embedded]] · script [[onix-request-lifecycle]]
- **Flow & simulation**: [[mock-playground-service]] · [[flow-state-machine]] · [[flow-usecase]] · [[transaction-session]] · script [[flow-execution]]
- **Persistence & recording**: [[recorder-service]] · [[db-service]] · script [[recording-path]]
- **Config**: [[config-service]]
- **Reporting**: [[report-service]] · [[report-pramaan]] · script [[generate-report]]
- **Frontends & UI usage**: [[ui-frontend]] · [[backoffice-frontend]] · [[session-difficulty]] · scripts [[schema-validation]], [[run-flow-test]]
- **Support & infra**: [[user-management-service]] · [[form-service]] · [[registry-gateway]] · [[observability]] · [[udp]] · script [[local-dev-setup]]
- **Engine libraries (now submodules)**: [[automation-libraries]] · [[build-tools]] · [[api-service-generator]] · [[mock-runner-lib]] · [[validation-compiler]] · [[logger-package]] (+ [[onix-plugins]])
- **ONDC ecosystem (background)**: [[ondc-ecosystem]] · [[ondc-protocol]] · [[registry-gateway]] · [[domain-version]]

## Scripts (procedures)

- [[spec-to-runtime]] — build-api-service.sh: spec branch → running api-service
- [[onix-request-lifecycle]] — one protocol action end-to-end through ONIX
- [[flow-execution]] — mock-playground step-by-step flow dispatch
- [[recording-path]] — audit → Redis cache + MongoDB
- [[schema-validation]] — UI Schema Validation Tool
- [[run-flow-test]] — UI Flow Testing Suite end-to-end
- [[generate-report]] — validation / Pramaan reporting
- [[local-dev-setup]] — run the stack locally
- [[tester-playbook]] — QA break-points, coverage gaps, verify-writes cheat sheet
- [[author-new-domain-spec]] — SOP for authoring a new domain specification
- [[kb-sync-on-diff]] — keep the KB synced to code (repo→frames map, diff→revisit)

## Resolved from code (adr-0009)
registry-service = external placeholder · report output = HTML only · ENABLED_DOMAINS list confirmed · /test path skips state+signing, txn path enforces both · signing active locally on txn path · /ai = generic forward proxy (no built-in LLM/MCP) · submodules pinned to commits · Redis keyspace mapped.

## Decided by owner (adr-0010)
Reporting module is under active redesign → keep [[report-service]]/[[report-pramaan]] abstract/volatile. · MCP runtime agent ([[mcp-runtime-agent]]) is future scope, consumes workbench runtime+logs via MCP (not /ai/proxy). · No per-persona access restrictions — same grounded truth to all.

## Spec lifecycle (captured adr-0011..0015)
Branch = authoritative spec source · prefix = deployment env (draft-=dev/QA, release-eks-=NP-facing prod) · promotion = human approval+verification by spec owner/protocol architect/engineers (CI/CD WIP, out of scope) · branch version always in sync with ONDC spec, upgrade=new branch · "what's live"=branch set, config-service/db=runtime mirror · ecosystem lifecycle status flag (draft/live/to-be-deprecated/deprecated) in developer guide, orthogonal to env. See [[spec-lifecycle-status]].

## Decided / resolved recently
Deprecation → OUT OF SCOPE (adr-0024). [[udp]] captured at concept level (adr-0024). MCP accessibility lean = service layer over raw DB (adr-0024). Embedded mock = older static mock, not shared with playground (adr-0025). Router has no *default* fallback, but the receiver guards routing input first ⇒ cookieless call ⇒ 400/412 NACK, not 500 (adr-0038 revises adr-0025). Config-cache DB0/DB1 confirmed.

## Open questions — need owner (tacit / process / product knowledge)

1. [[udp]] — full name/acronym + pipeline (recorder/NO → UDP?), schema, where intelligence surfaces (evolving).
2. Network-Observability + Dozzle/Grafana — which environment actually exercises them (prod/hosted only)?
3. W2W blind spot: catalogue of implicit assumptions most likely to bite (future explicit-validation fix planned).
4. Is the embedded static mock still used at runtime / what does ONIX mockTxnCaller proxy to ([[mock-service-embedded]] vs [[mock-playground-service]])?
5. Confirm MCP agent accessibility direction (service layer recommended).
6. (minor) exact developer-guide lifecycle-flag field name.
7. **Live-stack submodule skew (adr-0044):** running ui-backend calls the stale mock route `trigger/api-service/:action` (404) ⇒ UI flow-trigger historically broken; frontend re-pinned to main (adr-0051) but main still carries the stale route + crypto.randomUUID TODO — the mock-side fixes are what made eKYC work. (Signing [6], recorder write [5], difficulty cookies [10] CONFIRMED live — adr-0048; eKYC dynamic-form RESOLVED — adr-0051/0052/0055; the earlier FLOW_STATUS/validateSign-fresh-inbound gap was **temporary**, now exercised by completed flows.) → owner: Shreyansh

## Desired (architect — NOT live)
See [[desired-by-architect]]: runtime-debug MCP (active interest), x-lifecycle backing, w2w explicit-validation fix, all-branch examples, deprecation flow, UDP, reporting redesign. These are wishlist, not current behavior.

## Provenance
Seeded from repo (code = ground truth) via ADRs [[adr-0001]]..[[adr-0008]] in `decisions/`. References in `references.md`.
