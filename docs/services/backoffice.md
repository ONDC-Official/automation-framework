# automation-backoffice

## Overview

`automation-backoffice` is the **admin interface** for Protocol Workbench. It provides a back-office React UI and Express backend for managing sessions, users, unit tests, and administrative operations that are not part of the developer-facing testing flow. Back-office operators use this to review sessions, manage user access, inspect persisted payloads, and run administrative workflows.

The backoffice is a full-stack workspace with two sub-projects:
- `frontend/` — React/Vite admin UI
- `backend/` — Express API backend

## Default Ports

| Sub-service | Host Port | Container Port |
|---|---|---|
| Frontend | `5100` | `5001` |
| Backend | `5200` | `5000` |

Access: `http://localhost:5100/backoffice-frontend`

## Tech Stack

- Frontend: React + Vite + TypeScript (built with `--base=/backoffice/`)
- Backend: TypeScript + Express 4 + Node.js
- Session storage: Redis (via `connect-redis` + `ioredis`)
- Auth: JWT (`jsonwebtoken`) + cookie-based session (`express-session`)

---

## Backend

### Key Modules

| Module | Path | What it does |
|---|---|---|
| `index.ts` | `src/index.ts` | Entry point — starts Express server, connects to Redis |
| `app.ts` | `src/app.ts` | Express app factory — mounts middleware, routes, session store |
| `routes/` | `src/routes/` | Route definitions: `/sessions`, `/users`, `/payloads`, `/unit-tests` |
| `controllers/` | `src/controllers/` | Request handlers for each resource |
| `services/` | `src/services/` | Business logic — session management, user CRUD, payload queries |
| `middleware/` | `src/middleware/` | JWT auth middleware, request logging, error handling |
| `yamlConfig/` | `src/yamlConfig/` | YAML-based admin config (user roles, feature flags) |
| `interfaces/` | `src/interfaces/` | TypeScript interfaces for all data models |
| `constants/` | `src/constants/` | Shared constant values: error codes, Redis key patterns |

### External Dependencies (Backend)

| Package | Purpose |
|---|---|
| `express` | HTTP server framework |
| `ioredis` | Redis client — manages user sessions and cached state |
| `connect-redis` | Redis-backed session store for `express-session` |
| `express-session` | Cookie-based session management |
| `jsonwebtoken` | JWT issuance and verification for admin auth |
| `cookie-parser` | Parses `Authorization` cookies from incoming requests |
| `cors` | Enables cross-origin requests from the backoffice frontend |
| `js-yaml` | Parses admin config YAML files |
| `lodash` | Data transformation utilities |
| `archiver` | ZIP archive creation for bulk payload download |
| `uuid` | Generates unique IDs for admin operations |
| `winston` | Structured logging |
| `winston-loki` | Ships logs to Grafana Loki |
| `ondc-automation-cache-lib` | Reads session and transaction state from Redis |
| `@opentelemetry/sdk-node` | OpenTelemetry SDK for distributed tracing and metrics |

### Internal Dependencies (Backend)

| Package | Role |
|---|---|
| `ondc-automation-cache-lib` | Reads `sessionDetails:{sid}` and other state keys from Redis |

---

## Frontend

### Key Modules

| Module | Path | What it does |
|---|---|---|
| `main.tsx` | `src/main.tsx` | React entry point — renders `<App />` into DOM |
| `App.tsx` | `src/App.tsx` | Root component — router, global layout |
| `components/` | `src/components/` | Reusable UI components: tables, forms, modals, status badges |
| `pages/` (via `App.tsx`) | `src/components/` | Full-page views: Sessions, Payloads, Users, Unit Tests |
| `context/` | `src/context/` | React context providers: auth context, session context |
| `hooks/` | `src/hooks/` | Custom React hooks: `useSession`, `usePagination`, `useAuth` |
| `config/` | `src/config/` | Base URL config, API client setup |
| `docs/` | `src/docs/` | Embedded documentation pages rendered in the UI |

### Build Notes

The Vite build uses `--base=/backoffice/` so all asset URLs are prefixed with `/backoffice/`. This allows the backoffice frontend to be served at a subpath (`/backoffice-frontend/`) behind the same reverse proxy as the main UI.

---

## Configuration (Environment Variables)

### Backend

| Variable | Description |
|---|---|
| `PORT` | HTTP server port (default: `5000`) |
| `REDIS_URL` | Redis connection string |
| `JWT_SECRET` | Secret key for JWT signing/verification |
| `SESSION_SECRET` | Secret for `express-session` cookie signing |
| `CORS_ORIGIN` | Allowed frontend origin (e.g., `http://localhost:5100`) |
| `LOKI_URL` | Grafana Loki push endpoint |

### Frontend

| Variable | Description |
|---|---|
| `VITE_API_BASE_URL` | Base URL of the backoffice backend |

---

## How to Run

### Backend

```bash
cd automation-backoffice/backend
npm install
npm run dev     # nodemon + ts-node
npm run build   # tsc + copyfiles → dist/
npm start       # node dist/index.js
```

### Frontend

```bash
cd automation-backoffice/frontend
npm install
npm run dev     # Vite dev server
npm run build   # tsc + vite build (with --base=/backoffice/)
npm run lint    # ESLint
```

## Notes for Open Source

- The `--base=/backoffice/` Vite build flag means the frontend static assets are designed to be served at a path prefix, not the root. Configure your reverse proxy to serve the `dist/` output at `/backoffice-frontend/`.
- JWT and session auth in the backoffice is separate from the main Protocol Workbench developer flow — the backoffice has its own auth layer intended for internal admin users.
- `archiver` provides ZIP download of bulk payload exports — this is an admin convenience feature for downloading all API call logs from a session as a ZIP file.
