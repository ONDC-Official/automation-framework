---
id: adr-0046
date: 2026-06-28
grill-ref: deep-dive — automation-beckn-onix server core (added to repo)
status: accepted
changes: [onix-server, onix-request-lifecycle, onix-adapter, onix-plugins, api-service, signing-security]
---

# Seed ONIX server core; reconcile lifecycle with runtime

## Decision
Deep-dived automation-beckn-onix (now in-repo) → new frame onix-server: boot sequence, the single `std` handler + step engine (Step.Run, linear short-circuit), plugin manager (.so Provider pattern, RemoteRoot zip), the response model (ACK 200; NACK HTTP code by error type — schema 200, sign 401, bad-request 400, not-found 404, WorkbenchErr behavior NACK 200 / HTTP err.Code e.g. 412, panic 500), post-response async hooks + custom-response-body cookie, header/role injection, and Vault-backed keymanager.
- Reconciled onix-request-lifecycle to the runtime truth (HTTP codes, receiver-guard target resolution, async post-response) and bumped it to high confidence.
- Updated onix-adapter (all modules run on std handler; async post-response), onix-plugins (server core now in-repo), api-service (sub-book +onix-server), signing-security (Vault keyset).

## Assumptions & perception
- Source: Explore over automation-beckn-onix cmd/core/pkg (file:line) + runtime ADRs 0037/0038/0043. High confidence. Vault wiring local-vs-prod = open.

## KB effect
- new frame onix-server; lifecycle/adapter/plugins/api-service/signing reconciled.
