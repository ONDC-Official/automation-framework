---
id: adr-0009
date: 2026-06-26
grill-ref: verification pass — resolve code-answerable open questions
status: accepted
supersedes: adr-0006
changes: [report-service, generate-report, api-service, validation-layers, ui-frontend, registry-gateway, transaction-session, automation-framework]
---

# Resolve open questions from code (verification pass)

## Question / context
After the seed, several open questions were code-answerable (report format, ENABLED_DOMAINS, registry-service, /ai proxy, test vs full validation path, signing, submodule pins, Redis keyspace). Resolved via a code-grounded Explore pass with file:line evidence.

## Decision (now-true facts)
- **Report output = HTML only.** generateCustomHTMLReport / generateReportHTML return HTML string + flowResults; no pdfkit/puppeteer/json2csv anywhere. (Supersedes the PDF/CSV claim and the conflict flagged in adr-0006.)
- **ENABLED_DOMAINS** (report-service src/utils/constants.ts): ONDC:LOG10 1.2.5; LOG11 1.2.5; FIS10 2.1.0; FIS11 2.0.0; FIS12 2.0.1/2.0.2/2.0.3/2.2.0/2.2.1/2.3.0; FIS13 2.0.1; TRV10 2.1.0; TRV11 2.0.1/2.1.0; TRV13 2.0.1. Not-in-list ⇒ Pramaan delegation.
- **registry-service:8080 = external URL placeholder only** (no local container/image in repo).
- **/ai proxy** = generic forward proxy (aiProxyRoutes /proxy): target from `x-proxy-target` header, SSRF guard (blocks private IPs), forwards Authorization, supports SSE. No built-in LLM/MCP/RAG in workbench — AI is external, client-supplied.
- **test vs full path** (api-service adapter.yaml): `/.../test/` = module standaloneValidator, `stateFullValidations: false`, NO validateSign. `/.../seller/` (BapTxnReceiver) = `stateFullValidations: true` + includes validateSign.
- **Signature verification** is active in the local stack for transaction (buyer/seller) paths via validateSign plugin; skipped on the test/validation-only path.
- **Submodules**: all 9 in detached HEAD pinned to specific commits (.gitmodules says branch=main, but checkouts are pinned, not tracking main).
- **Redis keyspace** (mostly DB0): `transactionId::subscriberUrl` (txn cache), `MOCK_DATA::txn::sub` (business data), `FLOW_STATUS_txn::sub` (TTL 5h), `EXTRA_FLOW_STATUS_txn::sub::stepKey` (TTL 5h), `PLAYGROUND_<sessionId>` (mock-runner config; 5-min in-memory), `<sessionId>` (NP session), `<subscriberUrl>` (subscriber expectations, ~5-min). Recorder shares txn + flow-status keys.

## Assumptions & perception
- Source: Explore agent over report-service, frontend backend, api-service build-output adapter.yaml, submodule git refs, cache code (file:line cited). High confidence.
- Minor unresolved nuance: whether config cache uses Redis DB1 vs DB0 (seed agent said DB1; verify agent saw DB0 default) — low impact, left as light note.

## KB effect
- report-service: confidence high; output=HTML; ENABLED_DOMAINS added; conflict open-Q removed.
- api-service + validation-layers: test vs full path + signing resolved.
- ui-frontend: /ai resolved. registry-gateway: external-only confirmed. transaction-session: keyspace added. automation-framework: submodule pin note.
