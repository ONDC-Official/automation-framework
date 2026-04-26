# automation-recorder-service

## Overview

`automation-recorder-service` is a **Go gRPC microservice** that serves as the audit trail writer for Protocol Workbench. Every ONDC API call processed by `automation-beckn-onix` is reported to this service via gRPC after the response is sent. The recorder atomically appends the call to a Redis transaction log (maintaining a complete, ordered history), then asynchronously persists the payload to `automation-db` and the Network Observability endpoint. This two-phase design ensures the Redis log is always up-to-date for real-time reporting while keeping the slow persistence operations off the hot path.

## Role in the Architecture

```
automation-beckn-onix (networkobservability plugin)
    ↓ gRPC LogEvent (port 8089)
automation-recorder-service   ← THIS SERVICE
    ↓ SYNC: Redis WATCH/MULTI/EXEC → append to {txnId}::{subUrl}
    ↓ ASYNC worker pool:
        ├── POST → automation-db (MongoDB + YugabyteDB)
        └── POST → Network Observability endpoint

HTTP (port 8090):
    POST /html-form  ← receives HTML form submissions from beckn-onix formReceiver module
    GET  /health     ← liveness/readiness probe
```

## Ports

| Protocol | Port | Description |
|---|---|---|
| gRPC | `8089` | `AuditService.LogEvent(BytesValue) → Empty` |
| HTTP | `8090` | `/html-form` form submission receiver + `/health` probe |

## Tech Stack

- Language: Go 1.24
- gRPC: google.golang.org/grpc
- Redis: `github.com/redis/go-redis/v9`
- Proto: `google.golang.org/protobuf` (custom `BytesValue` message)

## Key Files

| File | What it does |
|---|---|
| `main.go` | Entry point — starts both the gRPC server (`:8089`) and HTTP server (`:8090`) concurrently |
| `grpc_audit.go` | Implements `AuditService.LogEvent` — the core gRPC handler; parses the incoming `BytesValue`, extracts metadata, calls cache and async logic |
| `cache.go` | Redis WATCH/MULTI/EXEC transaction logic — atomically appends the API call to the `{txnId}::{subUrl}` key with up to 8 optimistic-lock retries |
| `async.go` | Buffered channel + worker pool — receives `LogEvent` data and fans out to `automation-db` and Network Observability via HTTP POST |
| `config.go` | Environment variable loading (via `godotenv`), struct for all runtime config |
| `http_form.go` | HTTP handler for `POST /html-form` — receives form submissions and stores them in Redis |
| `health.go` | HTTP handler for `GET /health` — returns 200 if Redis is reachable |
| `proto/` | Protobuf definitions for `beckn.audit.v1.AuditService` |

## gRPC Message Structure

```protobuf
// LogEvent payload (BytesValue = serialized JSON)
{
  "requestBody":    <ONDC action payload>,
  "responseBody":   <ACK or NACK>,
  "additionalData": {
    "payload_id":       "...",
    "transaction_id":   "...",
    "message_id":       "...",
    "subscriber_url":   "...",
    "action":           "search | select | init | ...",
    "timestamp":        "...",
    "status_code":      200,
    "session_id":       "...",
    "is_mock":          true,
    "ttl_seconds":      3600,
    "req_headers":      { ... }
  }
}
```

## Redis Write Pattern

```
Key: "{transaction_id}::{subscriber_url}"
Value: JSON array of all API calls in this transaction (append-only)

Protocol:
  WATCH key
  GET key  → parse existing array
  Append new call record
  MULTI
  SET key newValue
  EXEC       ← if key changed since WATCH, retry (up to 8 attempts)
```

## External Dependencies (Go)

| Module | Purpose |
|---|---|
| `github.com/redis/go-redis/v9` | Redis client with WATCH/MULTI/EXEC support for optimistic locking |
| `google.golang.org/grpc` | gRPC server and client runtime |
| `google.golang.org/protobuf` | Protobuf message serialization/deserialization |
| `github.com/joho/godotenv` | Loads `.env` file into environment variables at startup |
| `github.com/beckn-one/beckn-onix` | Imports shared types/constants from the beckn-onix package |
| `github.com/alicebob/miniredis/v2` (test) | In-memory Redis mock for unit tests — no external Redis needed for testing |
| `github.com/rs/zerolog` (transitive) | Structured JSON logging |
| `gopkg.in/natefinch/lumberjack.v2` | Log file rotation for on-disk log output |

## Internal Dependencies

| Service | Protocol | Description |
|---|---|---|
| `automation-db` | HTTP POST | Async: persists `Payload` entity (structured) to YugabyteDB and binary payload to MongoDB GridFS |
| Redis | TCP | Sync: writes transaction log key `{txnId}::{subUrl}` |
| Network Observability | HTTP POST | Async: forwards audit events to external observability endpoint |

## Configuration (Environment Variables)

| Variable | Description |
|---|---|
| `GRPC_PORT` | gRPC server port (default: `8089`) |
| `HTTP_PORT` | HTTP server port (default: `8090`) |
| `REDIS_URL` | Redis connection string |
| `DB_SERVICE_URL` | Base URL of `automation-db` service |
| `NETWORK_OBSERVABILITY_URL` | External network observability endpoint |
| `RECORDER_NO_ENABLED_ENVS` | Comma-separated env names where NO push is disabled |
| `RECORDER_DB_ENABLED_ENVS` | Comma-separated env names where DB save is enabled |
| `WORKER_POOL_SIZE` | Number of async worker goroutines (default: `5`) |
| `QUEUE_BUFFER_SIZE` | Async channel buffer size (default: `100`) |

## How to Run

```bash
cd automation-recorder-service
go run .                        # run directly
go build -o automation-recorder # compile binary
```

## How to Run Tests

```bash
go test ./...
# Uses miniredis — no external Redis or gRPC server needed
```

## Notes for Open Source

- The two-phase design (sync Redis write → async DB write) is intentional: `automation-report-service` reads Redis for report generation, so the Redis write must complete before the API response returns. The DB write can be eventually consistent.
- The optimistic lock retry loop (WATCH/MULTI/EXEC × 8) handles concurrent writes for the same `transaction_id` without row-level locking — important when buyer and seller calls arrive simultaneously.
- `miniredis` in tests means the test suite has zero external dependencies — `go test ./...` works on a fresh checkout.
