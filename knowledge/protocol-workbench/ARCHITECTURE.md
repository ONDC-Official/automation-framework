# Protocol Workbench Knowledge — Architecture (purpose-layered)

Designed around the real expectations: **low-token targeted work** (debug AND change), **multi-persona**, **kept current on code diffs**, **live vs desired** separated.

## Token-reduction model (the core idea)
When an issue is reported or a change is planned, the area-of-change narrows to a few **flows / methods / modules** of code. The KB exists so an agent **scans first to find those**, then reads only them — instead of loading the whole codebase. The **Navigator/Locator** is that scan surface.

## Layers (one physical book; cross-links are the value)
1. **MAP** (`INDEX.md`) — orientation: taxonomy, persona routing, repo→frames map, live-vs-desired rule.
2. **LOCATOR** (`LOCATOR.md`, durable, part of MAP) — scan-first map: concern → candidate module → flows/methods (file:line) → frame. The token-reduction surface. + **PATTERNS** (`patterns/`, durable) — reusable symptom→cause→fix failure-mode entries (`fm-*`). NOTE: tactical change/diff/release/incident logs are NOT a permanent layer — they're **archivable in REFERENCES** (temporary). (The earlier "Navigator/diagnostics change-log" was too tactical; only the Locator + reusable patterns are durable.)
3. **COMPONENTS** (`frames/`) — per-component mechanism reference, ground-truth + file:line. Drilled into from the Navigator only when needed.
4. **RUNTIME/FLOW** (`scripts/`) — end-to-end procedures (request lifecycle, flow engine, recording, spec→runtime).
5. **SPEC/PROTOCOL** — authoring, lifecycle, spec-logic, validation rules, ONDC ecosystem.
6. **OPERATIONS** — local setup, deploy (push-to-db + clear-flows), env knobs, environment gotchas.
7. **BACKLOG / DESIRED** (`desired-by-architect`) — role-targeted TODOs; never asserted as live.
8. **DECISIONS** (`decisions/`) — ADR log (why/history). Durable.
9. **REFERENCES** (`references/`) — ⏳ TEMPORARY inputs + run reports. indexed → ingested → **prune** (commit-baseline excepted).

## Why low-token
- Work enters NAVIGATOR → Locator narrows to a few files/frames → read only those.
- Bug entries pre-compute the causal chain (one lookup, no multi-frame reload).
- Component frames stay terse + pointer-rich (drill-down, not first-read).

## Persona → entry layer
Developer → Navigator → Components. Senior Dev → + Runtime/Flow + review. Architect → Spec + Runtime + Components + Decisions + Desired. Tester / QA Lead → Navigator + Operations + coverage (validation-layers/w2w/tester-playbook). PM/Scrum → Desired + Map. Product Owner → Map capabilities + Spec/ecosystem + Desired roadmap.

## Upkeep
On a confirmed change/fix: durable mechanism → COMPONENTS frame + triple; episode → ADR; the work item (feature/release/diff/bug) → a NAVIGATOR entry + refresh its Locator row. `kb-sync-on-diff` on code diffs regenerates diff-summaries and revisits mapped frames. References get pruned once ingested.
