# Protocol Workbench — Claude Code memory

This repo contains BOTH the ONDC Protocol Workbench source (this monorepo) and a knowledge book about its runtime (now vendored at `knowledge/protocol-workbench/`).

- **Code (ground truth):** this repo — orchestrator (`docker-compose.yml`, `dockerfiles/`, `scripts/`, `docker-env/`) + submodules grouped as:
  - `services/` — deployable services: `automation-db`, `automation-config-service`, `automation-recorder-service`, `automation-report-service`, `automation-report-pramaan`, `automation-mock-playground-service`, `automation-user-management`, `automation-backoffice`, `automation-beckn-onix`, `automation-frontend` (ui).
  - `packages/` — engine libraries: `automation-utils` (`build-tools` = `@ondc/build-tools`), `automation-api-service-generator`, `automation-mock-runner-lib`, `automation-validation-compiler` (= `ondc-code-generator`), `automation-beckn-plugins`, `automation-logger-package`, `automation-specifications`.
  - `api-service/` — generated/temp working dir (git-ignored), produced by `scripts/build-api-service.sh`; NOT a submodule.
- **Knowledge book:** `knowledge/protocol-workbench/` — start at `INDEX.md`. It is a retrieval-ready KB (frames = components/concepts, scripts = runtime procedures, `triples.md` = atomic facts, `decisions/` = ADR history of how/why the KB changed, `references/` = stored sources).

## Operating rules (when working in this repo)
1. **Load the KB first:** read `knowledge/protocol-workbench/INDEX.md` and the relevant frames before answering or changing anything.
2. **Code + observed runtime are ground truth; the derived KB supersedes code/README where they disagree.** If you observe runtime behavior that contradicts a frame, update the frame to the new truth AND write a superseding ADR (never edit a past ADR).
3. **KB conventions** (keep edits consistent):
   - Frame = `frames/{slug}.md` with frontmatter (`id, kind, isa, part-of, confidence, source, changed-by: adr-NNNN`) + terse Slots/Relations/Open-questions. Record only what's new/overridden; link concepts with `[[slug]]`.
   - Script = `scripts/{slug}.md` (entry conditions, roles, ordered scenes, results, edge points).
   - Every KB change ⇒ append an ADR `decisions/adr-NNNN-{slug}.md` (NNNN = one more than the highest existing file in `decisions/` — list the dir to find it) with: grill-ref, decision, assumptions, KB effect; set `supersedes:` when it overturns an earlier ADR.
   - Add atomic facts to `triples.md`; ensure every frame/script is reachable from `INDEX.md`.
4. **Don't guess.** If a fact needs runtime observation you can't perform, log it as an Open question (owner: Shreyansh) or ask the user to run a command and paste the output.
5. **Low-token debug:** answer from the frame's exact file:line/mechanism (symptom→location); don't reload full code context when the KB already points there. Frames are terse + pointer-rich.
6. **Sync on diff:** after any code change, run `scripts/kb-sync-on-diff.md` — find the changed submodule, revisit only its mapped frames, update slot+triple+ADR. Keep live/actual separate from `scope: desired` features ([[desired-by-architect]]); surface desires as role TODOs (product/scrum/dev) only. Frontend = runtime-proven only.

> **Layout note:** submodules were regrouped under `services/` and `packages/` (previously flat at repo root). KB frames/scripts refer to submodules by *repo name* (e.g. "repo automation-frontend/"), which remains valid; only the on-disk monorepo path changed.
