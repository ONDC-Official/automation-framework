---
id: adr-0034
date: 2026-06-26
grill-ref: code search — locate lifecycle-status flag field
status: accepted
supersedes: adr-0015
changes: [spec-lifecycle-status, ui-frontend]
---

# Lifecycle-status flag is a frontend placeholder, not data-backed

## Question / context
Sought the exact field carrying the draft/live/deprecated lifecycle flag.

## Decision
- The status exists ONLY as a frontend placeholder: `automation-frontend/.../developer-guide/shared/statusPlaceholders.ts` defines `NavStatus = released | drafted | to-be-deprecated | deprecated`, but `getNavStatus()` is hardcoded to "released" and the override map is empty.
- There is NO backend field: no `x-status`/`x-lifecycle` in BuildConfig.info (build-type.ts), not in StoredBuildMeta/build_meta, not returned by /protocol-specs. A documented seam exists to add `x-lifecycle` end-to-end.
- Refines adr-0015: the "ecosystem lifecycle status flag in the developer guide" is intended/UI-stubbed, not yet implemented. Canonical values are released/drafted (owner's verbal "live/draft").

## Assumptions & perception
- Source: Explore (statusPlaceholders.ts, build-type.ts, schemas.ts, ingest.ts, ProtocolService.ts) file:line. High confidence.

## KB effect
- spec-lifecycle-status: values corrected; marked not-data-backed; seam noted.
- ui-frontend: developer-guide badge = hardcoded placeholder.
