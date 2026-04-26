# automation-db

## Overview

`automation-db` is the **dual-database persistence service** for Protocol Workbench. It provides a REST API over two storage backends: **MongoDB** (via Mongoose + GridFS) for storing large binary payloads and uploaded files, and **YugabyteDB** (PostgreSQL-compatible, via TypeORM) for structured records like API call logs (`Payload` entity) and session metadata (`SessionDetails` entity). All other services that need to persist data call this service's HTTP API rather than connecting to the databases directly.

## Role in the Architecture

```
automation-recorder-service  ──► POST /payload     → automation-db ← THIS SERVICE
automation-frontend/backend  ──► POST /session      →   ├── MongoDB (GridFS via Mongoose)
automation-backoffice/backend──► GET  /payloads     →   └── YugabyteDB (TypeORM, port 5433)
```

## Default Port

`8080` (host and container)

## Tech Stack

- Language: TypeScript + Node.js
- Framework: Express 4
- ORM: TypeORM (YugabyteDB/PostgreSQL)
- ODM: Mongoose (MongoDB GridFS)
- Database 1: YugabyteDB (PostgreSQL-compatible, port 5433)
- Database 2: MongoDB (port 27017)

## Key Modules

| Module | Path | What it does |
|---|---|---|
| `index.ts` | `src/index.ts` | Entry point — connects to both databases, starts Express server |
| `data-source.ts` | `src/data-source.ts` | TypeORM DataSource config — connects to YugabyteDB, lists entities, enables `synchronize: true` in dev |
| `entity/` | `src/entity/` | TypeORM entities: `Payload` (API call record) and `SessionDetails` (session metadata) |
| `repositories/` | `src/repositories/` | TypeORM repository wrappers for each entity |
| `controllers/` | `src/controllers/` | Request handlers for each route |
| `routes/` | `src/routes/` | Route definitions: `/payload`, `/session`, `/files` namespaces |
| `services/` | `src/services/` | Business logic: payload storage coordination, GridFS file upload/download |
| `config/` | `src/config/` | Database connection factories for MongoDB and YugabyteDB |
| `middleware/` | `src/middleware/` | Request logging, error handling, `multer` file upload middleware |
| `utils/` | `src/utils/` | Response formatting helpers, query builder utilities |
| `migration/` | `src/migration/` | TypeORM migration files — run with `npm run migration:run` |

## TypeORM Entities

### `Payload`
Stores a record for each ONDC API call:

| Column | Type | Description |
|---|---|---|
| `id` | UUID | Primary key |
| `transactionId` | string | ONDC transaction ID |
| `messageId` | string | ONDC message ID |
| `action` | string | ONDC action (search, select, init, …) |
| `subscriberUrl` | string | NP subscriber URL |
| `sessionId` | string | Protocol Workbench session ID |
| `requestBody` | JSONB | Full request payload |
| `responseBody` | JSONB | Full response payload |
| `statusCode` | int | HTTP status code |
| `timestamp` | timestamp | When the call occurred |

### `SessionDetails`
Stores session configuration:

| Column | Type | Description |
|---|---|---|
| `sessionId` | UUID | Primary key |
| `domain` | string | ONDC domain code |
| `version` | string | Protocol version |
| `config` | JSONB | Full session configuration object |
| `createdAt` | timestamp | Session creation time |

## External Dependencies

| Package | Purpose |
|---|---|
| `express` | HTTP server framework |
| `typeorm` | ORM for YugabyteDB (PostgreSQL) — entity mapping, migrations, repository pattern |
| `pg` | PostgreSQL driver used by TypeORM to connect to YugabyteDB |
| `reflect-metadata` | Required by TypeORM for decorator-based entity definitions |
| `mongoose` | ODM for MongoDB — schema definition, GridFS file storage |
| `mongodb` | MongoDB Node.js driver (used directly for GridFS streaming) |
| `multer` | Multipart form-data parser — handles binary file upload requests |
| `body-parser` | JSON/urlencoded request body parsing |
| `lodash` | Data transformation utilities in service layer |
| `@opentelemetry/sdk-node` | OpenTelemetry SDK for distributed tracing and metrics |

## Internal Dependencies

| Package | Role |
|---|---|
| `@ondc/automation-logger` | Structured logger with Loki transport |
| `@ondc/build-tools` | CLI utilities used in migration scripts |

## Configuration (Environment Variables)

| Variable | Description |
|---|---|
| `PORT` | HTTP server port (default: `8080`) |
| `DB_HOST` | YugabyteDB host |
| `DB_PORT` | YugabyteDB PostgreSQL port (default: `5433`) |
| `DB_USERNAME` | YugabyteDB username |
| `DB_PASSWORD` | YugabyteDB password |
| `DB_NAME` | YugabyteDB database name (default: `my_app`) |
| `MONGO_URI` | MongoDB connection string (e.g., `mongodb://localhost:27017/automation`) |

## Database Migrations

TypeORM migrations are used for schema changes to the YugabyteDB entities. In development, `synchronize: true` in `data-source.ts` auto-syncs schema — disable this in production.

```bash
cd automation-db
npm run migration:generate   # generate migration from entity changes
npm run migration:run        # apply pending migrations
npm run migration:revert     # revert last migration
```

## How to Run

```bash
cd automation-db
npm install
npm run dev     # nodemon + ts-node (watch mode)
npm run build   # tsc → dist/
npm start       # node dist/index.js
```

## API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/payload` | POST | Store a new API call record (TypeORM + optional MongoDB GridFS for large bodies) |
| `/payloads` | GET | Query stored payloads by `session_id`, `transaction_id`, or `action` |
| `/session` | POST | Create or update a session record |
| `/session/:id` | GET | Retrieve session config |
| `/files` | POST | Upload a binary file to MongoDB GridFS |
| `/files/:id` | GET | Download a file from MongoDB GridFS |
| `/health` | GET | Liveness probe |

## Notes for Open Source

- YugabyteDB is PostgreSQL-compatible — you can substitute a standard PostgreSQL instance by changing the TypeORM connection driver. No code changes required.
- MongoDB is used exclusively for binary/large-document storage (GridFS). If your use case does not involve large file uploads, MongoDB can be omitted and the `files` endpoints disabled.
- `synchronize: true` is set in `data-source.ts` for development convenience — always disable it in production and use proper migrations instead.
