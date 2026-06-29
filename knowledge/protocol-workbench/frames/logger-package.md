---
id: logger-package
kind: instance
isa: component
part-of: automation-libraries
confidence: high
source: repo automation-logger-package/src/* (adr-0036)
changed-by: adr-0036
---

# logger-package (@ondc/automation-logger)

Shared Winston-based structured logger used across the Node services.

## Slots
- API: singleton `AutomationLogger.getInstance()` (default export); methods info/error/debug/warning(message, ...args); error(message, meta?, error?) unpacks Axios/Error; startTimer()→Profiler.done()
- log schema (WorkbenchLog): correlationId(req), transactionId?, sessionId?, subscriberUrl?, subscriberId?, message, error?{message,stack}
- formats: dev = colorized pretty (util.inspect); prod = JSON for Grafana **Loki** (winston-loki transport, LOKI_HOST)
- defaultMeta.labels: {service: SERVICE_NAME, category: "automation-framework"}; level = LOG_LEVEL (default info)
- correlation middleware: getCorrelationIdMiddleware() — X-Request-ID header (or nanoid), sets req.correlationId, echoes header
- OTEL: separate (consumer apps init OpenTelemetry → TRACE_URL/Jaeger); logger does NOT bridge logs↔traces
- no child loggers (singleton)

## Relations
- part-of → [[automation-libraries]] ; used-by → ui-backend + most Node services (mock-playground uses its own local logger)
- prod logs → Grafana Loki (LOKI_HOST); traces → Jaeger (see [[observability]])

## Notes
- Confirms Grafana/Loki IS the prod log sink (via this logger), distinct from local docker logs — relevant to the earlier "where are logs" question.
