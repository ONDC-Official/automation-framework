---
id: kb-commit-baseline-2026-06-29
title: "KB commit baseline — framework + all submodules (2026-06-29)"
source: git rev-parse / submodule status (live repo)
type: note
added: 2026-06-29
status: indexed
---

# KB commit baseline (2026-06-29)

This KB (knowledge/protocol-workbench/, ADRs through adr-0058) is anchored to these commits. Use as the diff base for [[kb-sync-on-diff]]: anything newer ⇒ revisit the mapped frames.

- framework-root: `0e849ea0203fb1a119c6b7ef58ec9315c856657a` (branch main)
- captured: 2026-06-28T19:56Z

## Submodules (`+` = checkout ahead of the recorded index, i.e. carries local runtime fixes)
- automation-api-service-generator: 393e08cf8f00
- automation-backoffice: 9d23bc0c9f51
- automation-beckn-onix: b6ff07dcbad6
- automation-beckn-plugins: 3104a565026a
- automation-config-service: +693e81cac5f
- automation-db: +9e2d73eed83
- automation-frontend: +d2ee0986b79
- automation-logger-package: 23f5a297301a
- automation-mock-playground-service: +b2a1cfdb600
- automation-mock-runner-lib: d0ca455d026f
- automation-recorder-service: +ea7d6b11677
- automation-report-pramaan: +dbbe0bbee79
- automation-report-service: +074d637eaa0
- automation-specifications: +bba1d928762
- automation-user-management: ff585b8eb2e4
- automation-utils: 853400196668
- automation-validation-compiler: bc5b4610c622

## Note
The `+`-marked submodules carry the 2026-06-28/29 local runtime fixes (mock idempotency + /callback + manual dispatcher, frontend CORS + dynamic-form, recorder TTL env, etc.) reconciled via adr-0048..0058. When these land as real commits, re-baseline here.
