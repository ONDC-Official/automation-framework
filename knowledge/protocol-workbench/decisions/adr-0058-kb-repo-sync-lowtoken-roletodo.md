---
id: adr-0058
date: 2026-06-29
grill-ref: owner — re-sync to code rebalancing; low-token targeted debug; repo↔diff linkage; desires as role TODOs
status: accepted
changes: [kb-sync-on-diff, knowledge-keep-updated, desired-by-architect, persona, mock-playground-service]
---

# KB purpose (low-token debug), repo↔diff sync, role-targeted desire TODOs

## Decision
- **Low-token targeted debug is the KB's purpose:** frames must point to the exact file:line/mechanism (symptom→location) so an agent debugs specifically instead of reloading full code context. Recorded in [[knowledge-keep-updated]]; exemplar = [[tester-playbook]].
- **Knowledge↔repo linkage + diff-revisit:** every frame's `source:` names its repo+files; new script [[kb-sync-on-diff]] holds the repo→frames map and the procedure to revisit only the mapped frames on a code diff (instead of re-deep-diving). Reconciliation, not re-read.
- **Recent code rebalancing reconciled:** the uncommitted diffs (mock process-flow/form-handlers/generate-response + new manual dispatcher, frontend app.ts CORS + dynamic-form handlers, backoffice sessionController, recorder TTL env) map to adr-0048..0057; added a terse manual-dispatcher pointer to [[mock-playground-service]] (expand on demand).
- **Desires as role-targeted TODOs:** [[desired-by-architect]] items are pick-up-able TODOs surfaced when a product manager / scrum master / developer asks for backlog/next; [[persona]] updated. Never presented as shipped.

## Assumptions & perception
- Owner steer (interview 2026-06-29). git scan showed the dirty files = the documented runtime fixes; no uncaptured major refactor (manual dispatcher flagged for on-demand detail). Kept this turn low-token: reconcile + mechanism, not re-deep-dive.

## KB effect
- new script kb-sync-on-diff (repo map + procedure); knowledge-keep-updated (low-token purpose + diff-revisit); desired-by-architect + persona (role TODOs); mock-playground manual-dispatcher pointer.
