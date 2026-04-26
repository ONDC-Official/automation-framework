# automation-cache

## Overview

`automation-cache` is the **shared Redis state library** for Protocol Workbench, published as `ondc-automation-cache-lib` on npm. It provides a unified Redis client wrapper (`RedisService`) that all Node.js services use for reading and writing transactional state, session data, and flow state. Using a single shared library ensures consistent key naming conventions, serialization format, and Redis database selection across all services.

## Role in the Architecture

This is a **foundational shared library** — it is the connective tissue between all stateful services. Every Node.js service that reads or writes to Redis imports this package rather than managing Redis connections directly.

```
All Node.js services
    ↓ import ondc-automation-cache-lib
    ↓ RedisService.useDb(0)  ← at startup
    ↓ Redis DB0: transactional state
        {txnId}::{subUrl}        ← transaction log (written by recorder-service)
        sessionDetails:{sid}     ← session config (written by frontend-backend)
        flowStates:{sid}         ← flow state machine (written by mock-playground)
```

**Consumers:**
- `automation-frontend/backend`
- `automation-backoffice/backend`
- `automation-report-service`
- `automation-form-service`
- `automation-api-service-generator` (runtime code of generated services)

## npm Package Name

`ondc-automation-cache-lib` — consumed from npm (this directory contains only documentation; the package is published separately)

## Redis Key Patterns

| Key Pattern | Owner | Description |
|---|---|---|
| `{transaction_id}::{subscriber_url}` | `automation-recorder-service` | Full chronological API call log for a transaction |
| `sessionDetails:{session_id}` | `automation-frontend/backend` | Session configuration (domain, version, NP URLs, TTL) |
| `flowStates:{session_id}` | `automation-mock-playground-service` | Current step, flow status, and extracted data for each active flow |

## Redis Database Usage

| DB | Used by | Contents |
|---|---|---|
| DB0 | All services | Transactional state, session data, flow state |
| DB1 | `automation-mock-playground-service` only | Mock runner config cache (per domain×version, fetched from config-service) |

## How Services Initialize

Every service calls `RedisService.useDb(0)` exactly once at startup:

```typescript
import { RedisService } from "ondc-automation-cache-lib";

// In service startup (index.ts)
await RedisService.useDb(0);
```

After this call, all `RedisService` methods operate on DB0 for that process.

## Notes for Open Source

- The `automation-cache/` directory in this monorepo contains only a README. The actual source code is in a separate repository and published to npm. This mirrors the pattern for external library dependencies — you consume the published package, not the source.
- All services pin a specific version in their `package.json`. In local development, npm workspaces do NOT override this with a local build (unlike other workspace packages) because there is no local source to build from.
- Redis DB0 vs DB1 separation is intentional: the mock-playground service uses DB1 for its config cache to prevent cache churn from interfering with live transaction data in DB0. No other service touches DB1.
