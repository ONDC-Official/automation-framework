---
id: adr-0063
date: 2026-06-29
grill-ref: owner — "navigator is very tactical, is it necessary or archivable like references?"
status: accepted
supersedes: adr-0062
changes: [LOCATOR, patterns, references, INDEX, ARCHITECTURE, kb-sync-on-diff]
---

# Split Navigator: durable Locator + patterns; tactical logs archivable

## Question / context
Owner observed the Navigator (as built — a change-log absorbing diffs/releases/incidents) is tactical. Is it necessary, or archivable like references?

## Decision (owner-confirmed)
- The layer was two things glued together. Split:
  - **Durable & necessary:** the **Locator** (concern → module → flows/methods file:line → frame) → promoted to a top-level durable `LOCATOR.md` (Map layer); and reusable **failure-mode patterns** → kept in `patterns/` (renamed from navigator; `bug-*` → `fm-*`).
  - **Tactical & archivable:** change/diff/release/incident logs → NOT a permanent layer; archivable in `references/` (temporary), with the durable lesson promoted to a frame + ADR (+ a reusable pattern if applicable).
- Removed the "Navigator change-log" framing. Updated INDEX (scan LOCATOR first), ARCHITECTURE, references policy, tester-playbook + kb-sync pointers, and the skill deliverables.

## Assumptions & perception
- Supersedes adr-0062 (Navigator). Locator is diff-maintained (durable nav); patterns are durable reuse; tactical specifics are prunable. No durable content lost (relocated).

## KB effect
- new LOCATOR.md; navigator/ → patterns/ (fm-*); references = temporary incl. tactical logs; INDEX/ARCHITECTURE/kb-sync/skill updated.
