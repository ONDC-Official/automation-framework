---
id: spec-logic
kind: concept
isa: concept
confidence: high
source: interview 2026-06-26
changed-by: adr-0029
---

# Spec "logic" (the core runtime+config that drives a journey)

The owner's sense of "logic" (one of the key authored artifacts, with flow/examples/L1): the **holistic runtime + config that governs how a transaction journey evolves** as its stage advances. Not a single file — it is the interplay of four carried elements + the flow + examples.

## The carried elements (per-step config + runtime; engine = [[mock-runner-lib]])
- **requirement** — `meetsRequirements(sessionData) → {valid,code,description}` (timeout 3s): preconditions/inputs satisfied?
- **generation** — `generate(defaultPayload, sessionData) → payload` (45s): produce the step's payload.
- **validation** — `validate(targetPayload, sessionData) → {valid,code,description}` (5s): check the incoming counterparty payload.
- **L1 validation** — the declarative spec rules (api-service ondc-validator, generated Go from x-validations) = the CORE.
- functions are base64-encoded JS run in a sandboxed VM/worker (no eval/require/process; fetch only in generate, allowlist-gated). See [[mock-runner-lib]].

## Behavior
- journey evolution: as the transaction stage increases, a **subset of validations repeats / accumulates** per stage — derived and governed by L1 + how requirement/generation/validation JS contribute.
- flow: states the **possible journey** — illustrated or operational — which holistically IS the logic.
- examples: illustrative runs of possibility; currently typically **1 branch**, may evolve to cover all branches.
- save-data + reuse: how **mock "session fullness"** is handled (extracted fields chained across steps → MOCK_DATA). A SUBSET must be **defaulted commonly in production** (not per-flow). See [[transaction-session]].

## Relations
- carried-by → [[mock-playground-service]] / mock-runner config (requirement/generation/validation JS) + [[api-service]] (L1) + flow defs ([[flow-usecase]]) + examples
- core → [[validation-layers]] (L1) ; session-state → [[flow-state-machine]] (save-data → MOCK_DATA)
- authored-in → [[automation-specifications]] (see [[author-new-domain-spec]])

## Open questions
- Where the "common production defaults" subset for session fullness is configured → owner: Shreyansh
- Roadmap for examples covering all branches (currently 1) → owner: Shreyansh
