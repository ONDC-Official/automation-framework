---
id: adr-0036
date: 2026-06-26
grill-ref: deep-dive — automation-logger-package
status: accepted
changes: [logger-package, observability, automation-libraries]
---

# Seed logger-package; confirm Grafana Loki as prod log sink

## Decision
Documented @ondc/automation-logger: Winston singleton, info/error/debug/warning + startTimer, WorkbenchLog schema (correlationId/transactionId/sessionId/subscriberUrl/subscriberId), dev pretty vs prod JSON→Grafana Loki (winston-loki, LOKI_HOST), labels {service,category}, X-Request-ID correlation middleware, OTEL separate (no log↔trace bridge), no child loggers. Confirms Grafana/Loki is the prod log sink (distinct from local docker logs).

## Assumptions & perception
- Source: automation-logger-package src (file:line). High confidence. mock-playground uses its own local logger.

## KB effect
- new frame logger-package; observability (prod→Loki); automation-libraries member linked.
