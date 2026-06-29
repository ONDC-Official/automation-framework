---
id: adr-0062
date: 2026-06-29
grill-ref: owner — diagnostics too narrow; broaden to feature/release/diff/bug + better name; references temporary; token-reduction = scan-to-narrow
status: accepted
supersedes: adr-0061
changes: [navigator, INDEX, references, ARCHITECTURE, knowledge-keep-updated]
---

# Rename Diagnostics → Navigator (localization + change); references temporary

## Question / context
Owner: "diagnostics" is too narrow (fix-only). The same growing layer covers feature / release / commit-diff / bug, is updated on diffs, and its summaries are regenerated. The token-reduction goal: when an issue/change arises, the area narrows to a few flows/methods/modules — scan the knowledge first to find them. Also: references should be temporary/cleaned; Operations + Backlog layers are good.

## Decision
- Renamed `diagnostics/` → **`navigator/`** (entries `d-NNN` → `bug-NNN`; links repointed). Navigator = scan-first **Locator** (concern → module → flows/methods file:line → frame) + typed change entries (**bug · feature · release · diff-summary**), regenerated on commit diffs. Supersedes adr-0061's "diagnostics" framing.
- Locator is the token-reduction surface: scan first, read only the narrowed files. Entry template generalized to a typed change-unit.
- **References are TEMPORARY** (indexed → ingested → prune); policy noted in references.md + ARCHITECTURE + knowledge-keep-updated. Run reports = short-lived audit; commit-baseline excepted.
- Layered architecture documented in `knowledge/protocol-workbench/ARCHITECTURE.md` (relocated from the root, which proved non-persistent this session). INDEX + tester-playbook + kb-sync point to Navigator.
- Skill deliverables updated (grill-me-kb-skill-updated/SKILL.md + GRILL-ME-KB-IMPROVEMENTS.md): purpose layers, Navigator/Locator, references-temporary.

## Assumptions & perception
- One physical book; Navigator is the one new folder. Bug entries seeded; feature/release/diff entries use the template as that work occurs.

## KB effect
- navigator/ (renamed, broadened) + Locator; references temp policy; ARCHITECTURE.md; INDEX/skill updates.
