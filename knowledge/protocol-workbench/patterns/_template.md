---
id: fm-NNN
kind: failure-mode-pattern
symptom: "<one-line reusable symptom signature>"
confidence: high
source: adr-NNNN (incident detail) — keep this entry reusable, not incident-specific
---

# FM-NNN — <short symptom name>

## Signature
- exact error string(s) / status / where it surfaces (reusable, not a specific txn).

## Quick checks (ordered — each ~1 lookup; stop when one hits)
1. <cheapest discriminating check> → command/log/file → what it tells you.
2. …

## Cause
- the causal chain (mechanism → why it fails), terse + timeless.

## Fix locus
- file:line (or env/config); primary vs secondary.

## Verify
- one command/observation.

## Related
- frames [[...]] · `../LOCATOR.md` row · adr-NNNN
