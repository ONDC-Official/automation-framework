---
id: adr-0056
date: 2026-06-29
grill-ref: owner — separate live/actual knowledge from desired features; frontend runtime-proven only
status: accepted
changes: [desired-by-architect, knowledge-keep-updated, mcp-runtime-agent, udp, ui-frontend, INDEX]
---

# Live-vs-desired separation + frontend runtime-proven-only

## Decision
- Introduce an explicit split: **live/actual** knowledge (runtime-proven, current release scope) is the default; **desired/aspirational** features (architect wishlist, not built) are quarantined in a new [[desired-by-architect]] bucket and/or `scope: desired` frontmatter — never asserted as existing. The *understanding* may be idealized, but **feature scope must align to the actual release + live code**. KB versioning deferred (treat current as live).
- Moved into the desired bucket: runtime-debug MCP ([[mcp-runtime-agent]], scope:desired), UDP ([[udp]], scope:desired), x-lifecycle backing ([[spec-lifecycle-status]]), w2w explicit-validation fix ([[w2w-testing]]), all-branch examples ([[spec-logic]]), deprecation flow, reporting redesign.
- **Frontend = runtime-proven only:** some FE code is legacy/dead (stale trigger route, crypto.randomUUID TODO); record only observed runtime behavior, not code presence. Noted in [[ui-frontend]] + [[knowledge-keep-updated]].

## Assumptions & perception
- Owner steer (interview 2026-06-29): "be particular to live desired knowledge and desired feature differently"; MCP is desired-by-architect (and an active build interest). Frontend has legacy code ⇒ stick to runtime proof.

## KB effect
- new frame desired-by-architect; scope:desired on mcp-runtime-agent + udp; convention in knowledge-keep-updated + INDEX header; ui-frontend frontend-legacy warning.
