---
id: persona
kind: class
isa: concept
confidence: high
source: interview 2026-06-26 (scope brief)
changed-by: adr-0001
---

# Personas (who queries this book)

The agent trained on this book serves multiple personas; answers should be grounded with brief reasoning and routed to the right frames/scripts.

## Personas + entry points
- NP-developer-UI: uses workbench via UI → [[schema-validation]], [[run-flow-test]], [[ui-frontend]], [[validation-layers]]
- NP-developer-local: sets up local instance / contributes → [[local-dev-setup]], [[automation-framework]], per-service frames
- protocol-architect: runtime definitions & restrictions → [[automation-specifications]], [[api-service]], [[validation-layers]], [[ondc-protocol]], [[registry-gateway]]
- api-spec-querent: "what does the protocol say?" → spec config in [[automation-specifications]], enforced by [[api-service]]; read at runtime via [[config-service]]
- product-manager: capabilities & decisions → [[workbench]] core tools, [[report-service]], persona scripts
- workbench-developer: build features → all component frames + runtime scripts + [[recording-path]]
- end-user-qa: testing protocol, coverage, break points → [[validation-layers]], [[w2w-testing]], [[flow-execution]], [[generate-report]], per-service "edge points"
- end-user-ondc-usecase: define use cases & test → [[flow-usecase]], [[automation-specifications]], playground
- mcp-runtime-agent: programmatic runtime support agent — see [[mcp-runtime-agent]] (future scope)
- product-manager / scrum-master / developer (backlog): when these roles ask "what's next / backlog / what to build", surface [[desired-by-architect]] items as role-targeted TODOs (never as shipped). (adr-0058)
- debugging role (QA/dev): use the low-token targeted path — symptom → [[tester-playbook]] narrowing → exact file:line/mechanism in the mapped frame, not a full code reload.

## Access policy (adr-0010)
- NO per-persona restrictions: every persona receives the same grounded truth; only framing/entry-point differs. Agent answers with brief reasoning.

## Role profiles (for the workbench-kb skill, adr-0059) — human or agent
- **Developer (coder)** → goal: build/fix a component fast. Entry: the component frame + [[tester-playbook]] narrowing + [[kb-sync-on-diff]]. Behavior: answer from exact file:line/mechanism (low-token), don't reload full code.
- **Senior Developer** (detail feature, code review, feature test scope) → component frames + [[spec-logic]] + [[validation-layers]] + [[flow-state-machine]]; review against ground truth; scope tests via [[tester-playbook]] + [[w2w-testing]].
- **Architect** (design/feature/dev/deploy/devops/functionality/review) → [[spec-to-runtime]], [[onix-server]], [[automation-libraries]], [[ondc-ecosystem]], [[validation-layers]], decisions/ ADR history; deploy via [[local-dev-setup]]; design backlog in [[desired-by-architect]].
- **Tester** → [[tester-playbook]], [[validation-layers]], [[w2w-testing]], [[session-difficulty]], [[flow-state-machine]], [[generate-report]]; break-points + coverage.
- **Project Manager / Scrum Master** → [[workbench]] capabilities + [[desired-by-architect]] role-TODO backlog + this frame; surface TODOs, status.
- **Product Owner** → [[workbench]] core tools/capabilities + [[ondc-ecosystem]] + outcomes ([[generate-report]]); desired roadmap (not as shipped).
- **QA Lead** → coverage model in [[validation-layers]] + [[w2w-testing]] + [[tester-playbook]] + [[generate-report]]; coverage strategy + gaps.
- Cross-cutting: never present [[desired-by-architect]] items as live; frontend = runtime-proven only.

## Relations
- navigates → [[workbench]] and INDEX persona guide
