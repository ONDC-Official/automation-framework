---
id: adr-0061
date: 2026-06-29
grill-ref: owner — are frames deep enough for low-token debug? re-architect freely; multi-book ok
status: accepted
changes: [diagnostics, INDEX, tester-playbook, kb-sync-on-diff, knowledge-keep-updated]
---

# Add a symptom-indexed Diagnostics book; layer the KB by purpose

## Question / context
Owner asked whether the component frames are deep enough that similar debugging is low-token, and invited a free re-architecture (multi-book allowed).

## Assessment
Frames have good MECHANISM depth (file:line) but are organized by component, so debugging a new issue still loads 4-6 frames + re-derives the causal chain (proved with the on_confirm chase) — medium-token. The missing layer is a symptom-indexed DIAGNOSTIC layer with pre-computed causal chains.

## Decision
- Re-cast the KB as purpose LAYERS (one physical book, cross-links preserved): MAP (INDEX) · **DIAGNOSTICS (new)** · COMPONENTS (frames) · RUNTIME/FLOW (scripts) · SPEC/PROTOCOL · OPERATIONS · DESIRED/BACKLOG · DECISIONS (ADRs+reports). Design in `../../KB-ARCHITECTURE.md`.
- Built the **Diagnostics book** `diagnostics/`: symptom-indexed INDEX + `_template.md` + d-001..d-006 (on_X NACK, flow-dies/empty-form, dynamic-form stall, HTTP-status decode, UI-trigger 404, local frontend gotchas). Each entry is self-contained (signature → ordered quick-checks → cause → fix locus file:line → verify → related) so debug is ONE lookup, no component-frame reload.
- Wired: INDEX leads with the diagnostics fast-path; tester-playbook points to it; kb-sync-on-diff + knowledge-keep-updated require leaving a diagnostics entry after every real debug.

## Assumptions & perception
- One physical book (not separate repos) keeps `[[ ]]` cross-links working; DIAGNOSTICS is the one new folder. Seeded from adr-0048..0053; grows per recurring symptom.

## KB effect
- new diagnostics/ book (8 files); INDEX fast-path; playbook + sync + keep-updated hooks; KB-ARCHITECTURE.md design doc.
