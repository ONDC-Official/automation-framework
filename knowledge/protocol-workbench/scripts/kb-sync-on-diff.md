---
id: kb-sync-on-diff
kind: script
confidence: high
source: interview 2026-06-29 (knowledge↔repo linkage + diff-revisit)
changed-by: adr-0058
---

# Keep the KB synced to code (diff → revisit)

Each frame is linked to the repo + code it documents (its `source:`). Whenever a submodule changes, revisit the frames that map to it and update only what changed. Goal: the KB stays the **low-token debug layer** — answers point to the exact file/mechanism so an agent debugs specifically instead of reloading full code context.

## Entry conditions
- a code diff in one or more submodules (PR merged, local fix, refactor / "rebalancing")
- diff base = the commit baseline in `references/kb-commit-baseline-2026-06-29.md` (framework main @ 0e849ea + pinned submodule SHAs). Anything newer than the baseline ⇒ revisit. Re-baseline that file when fixes land as real commits.

## Procedure
1. Find changed submodules + files: `git -C automation-framework submodule foreach 'git status --short; git log --oneline -3'` (or `git diff --stat`).
2. For each changed submodule, list the frames that document it (repo→frames map below) — or `grep -rl "<submodule-name>" frames/`.
3. Re-verify only the slots touched by the diff; update the frame, add a triple, append an ADR (supersede if it overturns a fact). Note the wrong/old behavior when correcting.
4. If the diff adds a NET-NEW mechanism, add a slot (not a re-deep-dive). Keep frames terse + pointer-rich (file:line, symptom→location).
5. Re-check INDEX reachability.

## Repo → frames map (revisit targets)
- automation-framework → [[automation-framework]], [[automation-libraries]]
- automation-beckn-onix → [[onix-server]]; automation-beckn-plugins → [[onix-plugins]], [[signing-security]]
- automation-api-service-generator → [[api-service-generator]], [[onix-adapter]]; automation-validation-compiler → [[validation-compiler]]; automation-utils/build-tools → [[build-tools]]
- api-service (generated) → [[api-service]], [[onix-adapter]], [[mock-service-embedded]] · script [[spec-to-runtime]], [[onix-request-lifecycle]]
- automation-mock-runner-lib → [[mock-runner-lib]], [[spec-logic]]
- automation-mock-playground-service → [[mock-playground-service]], [[flow-state-machine]] · script [[flow-execution]]
- automation-recorder-service → [[recorder-service]] · script [[recording-path]]
- automation-db → [[db-service]]; automation-config-service → [[config-service]]
- automation-report-service → [[report-service]]; automation-report-pramaan → [[report-pramaan]] · script [[generate-report]]
- automation-frontend → [[ui-frontend]], [[session-difficulty]] · scripts [[schema-validation]], [[run-flow-test]]
- automation-backoffice → [[backoffice-frontend]]; automation-user-management → [[user-management-service]]
- automation-specifications → [[automation-specifications]], [[domain-version]], [[spec-lifecycle-status]], [[spec-logic]] · script [[author-new-domain-spec]]
- automation-logger-package → [[logger-package]]
- docker-env/* + docker-compose → [[automation-framework]] (env knobs e.g. recorder TTL), [[session-difficulty]]

## Locator + patterns upkeep
- On a module change: verify its `LOCATOR.md` row still points to the right files/frame (this is the durable navigation; keep it current first).
- After a real investigation: durable mechanism → frame+triple; reusable symptom→fix → a `patterns/fm-*` entry (only if reusable); the incident episode → an ADR (+ a short, prunable `references/` report). Tactical change/diff/release logs are archivable in references, NOT a permanent layer.

## Results
- KB reflects current code; debug stays targeted (symptom→file:line) and low-token.

## Notes
- Recent rebalancing (2026-06-28/29 runtime fixes: mock process-flow/form-handlers/generate-response, frontend app.ts CORS + dynamic-form handlers + manual dispatcher, backoffice sessionController, recorder TTL env) is already reconciled via adr-0048..0057. Frontend = runtime-proven only ([[ui-frontend]]).
