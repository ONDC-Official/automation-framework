---
id: adr-0045
date: 2026-06-28
grill-ref: RUNTIME-VERIFICATION-PROMPT path 5 (recorder + db), live FIS12 2.0.3
status: accepted
changes: [recorder-service]
---

# Recorder gRPC LogEvent is reachable & validates additionalData live; full write pending a completed flow

## Decision (runtime-observed)
- The api-service network-observability plugin calls recorder gRPC LogEvent per request: a direct seller/mock POST produced (in api-service log) "network-observability: audit dispatch failed: rpc error: code = InvalidArgument desc = subscriber_url is required in additionalData". So the gRPC endpoint (recorder-service:8089) is live, the NO middleware fires per request, and the recorder validates `additionalData.subscriber_url` (InvalidArgument when missing). The audit is non-blocking — the api-service still returned its NACK.
- Full happy-path (txn cache `txn::sub`, dedup messageIds, async db save with UPPERCASE action + stringified reqHeader, FLOW_STATUS 5h TTL) NOT reproduced (no completed transaction — mock skew, adr-0044). Stays code-confirmed (adr-0005), runtime-pending.

## KB effect
- recorder-service: Runtime-observed block added (gRPC reachable + InvalidArgument guard). Full-write verification deferred to a completed flow.
