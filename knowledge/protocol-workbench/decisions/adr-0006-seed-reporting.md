---
id: adr-0006
date: 2026-06-26
grill-ref: repo exploration — report-service + report-pramaan
status: accepted
changes: [report-service, report-pramaan, generate-report]
---

# Seed reporting + Pramaan

## Question / context
How does a session's payloads become a pass/fail report, and what is Pramaan's role?

## Decision
Captured: report-service generate-report flow (enabled-domain local validation → HTML report; non-enabled → Pramaan delegation with async callback), and report-pramaan buyer/seller mocha test runners producing mochawesome JSON.

## Assumptions & perception
- Source: report-service src + report-pramaan (code-grounded), confidence medium.
- CONFLICT flagged: frontend agent said report output is PDF/CSV; report-service code shows HTML(base64)+mochawesome. Recorded report-service code as more authoritative; left open question for owner.
- ENABLED_DOMAINS list (LOG10/11, FIS10/11/12 v2.0.2) needs confirmation.

## KB effect
- frames report-service, report-pramaan; script generate-report; both carry open questions.
