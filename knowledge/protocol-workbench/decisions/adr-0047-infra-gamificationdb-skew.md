---
id: adr-0047
date: 2026-06-28
grill-ref: reconcile runtime report (2026-06-28) — net-new infra + known bug
status: accepted
changes: [automation-framework, mock-playground-service, tester-playbook]
---

# Record gamification-db + ui-backend↔mock submodule skew (runtime)

## Decision
- Net-new infra container observed live: gamification-db (postgres:latest, host 5433) — added to automation-framework infra list (was undocumented). ~18 containers run.
- Known live bug: ui-backend ↔ mock-playground submodule skew — ui-backend POSTs `/mock/{d}/{v}/trigger/api-service/search`, mock returns 404 ⇒ ui-backend 500; UI "trigger search" broken in the verified stack, blocking full end-to-end flow (so signing-live, recorder happy-path, full mock flow remained runtime-pending in the report).

## Assumptions & perception
- Source: runtime-verification-2026-06-28.md (live stack). The skew is a version-pin mismatch, likely fixable by aligning submodule commits.

## KB effect
- automation-framework: gamification-db + container count.
- mock-playground-service + tester-playbook: skew bug recorded.
