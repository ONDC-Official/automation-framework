---
id: spec-lifecycle-status
kind: class
isa: concept
asof: 2026-06-26
confidence: medium
source: interview 2026-06-26
changed-by: adr-0015
---

# Spec lifecycle status (ecosystem versioning)

A lifecycle/maturity status attached to a domain+version (an **ONDC ecosystem-versioning** concept), tracked by a **flag in the developer guide**. This is DISTINCT from the branch-prefix environment — do not conflate the two senses of "draft".

## The two "draft"s (disambiguation)
- **Branch prefix** (`draft-*` vs `release-eks-*`) = which workbench DEPLOYMENT ENVIRONMENT the spec targets. `draft-*` = dev/QA env; `release-eks-*` = NP-facing prod env. See [[automation-specifications]].
- **Lifecycle status** (this frame) = the ecosystem maturity of the spec VERSION itself, independent of where it's deployed.

## Slots
- values (frontend NavStatus): released | drafted | to-be-deprecated | deprecated (owner's verbal "live/draft" ≈ released/drafted)
- ⚠️ NOT YET DATA-BACKED (adr-0034): the status is a FRONTEND PLACEHOLDER in [[ui-frontend]] developer-guide (`statusPlaceholders.ts`). `getNavStatus()` is hardcoded to "released"; the override map is empty. There is NO backend field — no `x-status`/`x-lifecycle` in the spec `info` schema, not in `build_meta` ([[build-tools]]), not in any [[config-service]]/[[db-service]] API response.
- planned seam: add `x-lifecycle` to BuildConfig.info → ingest into build_meta → return via /protocol-specs → read in getNavStatus. (not built)
- meaning: "ecosystem versioning" maturity of that spec version (intended)
- orthogonal-to-env: an ecosystem-"draft" version can be present even in PROD ("draft in prod")
- granularity (intended): primarily domain+version; domain+usecase+version where a domain was split into a versioned usecase (flows never versioned). See [[domain-version]]. (adr-0016)
- deprecation-process: OUT OF SCOPE for now (owner steer, adr-0024) — the status flag exists (incl. to-be-deprecated/deprecated values) but the retire flow is intentionally not being documented yet

## Relations
- tags → [[domain-version]]
- surfaced-in → [[ui-frontend]] developer-guide
- distinct-from → branch-prefix environment ([[automation-specifications]])

## Resolved (adr-0034)
- The flag is currently a frontend-only placeholder (NavStatus), not data-backed. Earlier "flag in the guide, served by config-service" was aspirational, not implemented.

## Open questions
- If/when x-lifecycle gets implemented (the seam) → owner: Shreyansh
- (Deprecation/sunset flow: OUT OF SCOPE for now — adr-0024)
