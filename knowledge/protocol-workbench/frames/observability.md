---
id: observability
kind: instance
isa: concept
confidence: high
source: repo docker-compose.yml (jaeger), report-service otelConfig, docs/developer-docs/network-observability.md, FAQ
changed-by: adr-0007
---

# Observability (tracing, logs, Network Observability)

## Slots
- tracing: Jaeger all-in-one:1.57.0 (UI 16686; OTLP gRPC 4317 / HTTP 4318); TRACE_URL=http://jaeger:4318/v1/traces
- instrumented: report-service (full OTel NodeSDK + auto-instrumentation); config-service declares jaeger dep but not instrumented in code
- logs: each service → stdout/stderr; `docker compose logs -f <svc>`. In PROD, Node services ship JSON logs to **Grafana Loki** via [[logger-package]] (winston-loki, LOKI_HOST) — confirms Grafana is the prod log sink. Dozzle/Loki/Grafana not in core local docker-compose.
- Network-Observability (NO): prod analytics endpoint https://analytics-api.aws.ondc.org/v1/api/push-txn-logs; per-subscriber bearer token; recorder pushes here (prod). Local stack has no NO. This push is the probable on-ramp to [[udp]] (network-wide real-time analytics).

## Relations
- traces-from → all instrumented services
- logs-pushed-by → [[recorder-service]] (to NO, prod)

## Overrides / edge points (tester: where to look)
- live flow logs: mock-service first, then api-service, then recorder (FAQ debugging order)
- traces: Jaeger UI search by service name
- FAQ note: Dozzle/Grafana mentioned for hosted env, not local compose.

## Open questions
- Which env actually runs Dozzle/Grafana? (hosted dev?) → owner: Shreyansh
