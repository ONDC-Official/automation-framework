---
id: desired-by-architect
kind: concept
isa: concept
scope: desired
confidence: high
source: interview 2026-06-29
changed-by: adr-0056
---

# Desired by architect (NOT in live code)

The bucket of **desired / aspirational** features and mechanisms — architect wishlist that is NOT in the current live release. Kept explicitly separate from the live KB so the agent never presents a desire as actual behavior.

## Role-targeted TODOs (adr-0058)
These are pick-up-able TODOs. When a **product manager / scrum master / developer** asks "what's next / backlog / what could we build", surface the items below as TODOs (with the linked frame for context). For all other roles, mention them only if asked. Never present as shipped. Each item below is a TODO candidate; tag an owner-role when one is known.

## Convention (live vs desired)
- **Live/actual** (default for all other frames): runtime-proven, current scope, aligned to the actual release + live code. The agent answers feature questions from this.
- **Desired** (this bucket + frames tagged `scope: desired`): wanted but not built. The *knowledge/understanding* may be idealized, but the **feature scope must match live code** — so desires live here, clearly labeled, never asserted as existing.
- Versioning of the KB itself is deferred (treat current as "live" for now).

## Desired items (each links to where it's discussed)
- **Runtime-debug MCP** — `wb_trace_action` + service-layer tools over redis/db/config-service/docker to collapse manual debugging. See [[mcp-runtime-agent]]. (owner: build next — item under active interest.)
- **x-lifecycle backing** — make the developer-guide status flag (released/drafted/to-be-deprecated/deprecated) data-driven (build.yaml info → build_meta → API → getNavStatus). Currently a hardcoded frontend placeholder. See [[spec-lifecycle-status]].
- **W2W explicit-validation fix** — turn the implicit shared assumptions into explicit validations so w2w surfaces real-NP divergences. See [[w2w-testing]].
- **Spec examples covering all branches** — examples currently illustrate ~1 branch. See [[spec-logic]].
- **Deprecation/sunset flow** — out of scope for now; status values exist but the retire flow is undefined. See [[automation-specifications]].
- **UDP** — real-time transaction-log network intelligence; concept-level, pieces in place, much unknown. See [[udp]].
- **Reporting redesign** — report-service/report-pramaan are being re-architected ([[report-service]], [[report-pramaan]] documented as current snapshot).

## Relations
- separate-from → all live frames ; governs-classification → [[knowledge-keep-updated]]

## Open questions
- As each desire ships, move it from here into the live frame + ADR (and flip `scope`).
