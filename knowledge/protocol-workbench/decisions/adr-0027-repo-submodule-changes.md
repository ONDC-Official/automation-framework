---
id: adr-0027
date: 2026-06-26
grill-ref: repo re-scan + owner — submodules added, form-service direction
status: accepted
changes: [automation-libraries, user-management-service, form-service, automation-framework]
---

# Repo grew to 14 submodules; form-service folding into playground

## Decision
- Repo now has 14 git submodules (was 9). Added: automation-user-management (was external GHCR image — now source available), automation-utils (incl. build-tools), automation-api-service-generator, automation-mock-runner-lib, automation-logger-package.
- The `@ondc/*` engine packages are therefore now in-repo code (new frame automation-libraries) — closes the prior "external npm internals" gap; deep-dive available on request.
- form-service: owner direction — going forward form handling is integrated into mock-playground-service only; standalone form-service is legacy (no dir in repo).

## Assumptions & perception
- Source: .gitmodules + dir scan (verified) + owner statements (interview). user-management now deep-divable. form-service direction is owner-stated (forward-looking but recorded as current direction, not deep future-scope).

## KB effect
- new frame automation-libraries; user-management-service (submodule, not GHCR); form-service (playground-integrated direction, legacy standalone).
