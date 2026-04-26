# Running automation-framework Locally — E2E Approach

## Overview

The automation-framework is a **monorepo** combining git submodules (for shared packages and services), npm workspaces (for local linking of shared packages), and a single `docker-compose.yml` that orchestrates the full stack.

Running it locally follows four phases:

1. **Clone & init** — pull the repo and all submodules
2. **Build shared packages** — compile the local npm workspaces in the correct order
3. **Configure env** — provide per-service `.env` files under `docker-env/`
4. **Start the stack** — run `./start.sh` which validates env files and brings up Docker Compose

---

## Current State — Important Context

Before following the steps, understand the **current repo state**:

| Item | State |
|---|---|
| `automation-api-service/` directory | **Deleted** from the monorepo (replaced by the new ONIX flow) |
| `automation-mock-service/` directory | **Deleted** from the monorepo (replaced by `automation-mock-playground-service`) |
| `docker-compose.yml` | Still references the two deleted dirs → **will fail** at `docker compose build` unless fixed |
| `docker-env/*.env` files | ✅ All 6 required files are already present |
| `automation-frontend/frontend/docker.env` | ⏳ **Missing** — required by `start.sh` |
| `automation-config-service`, `automation-form-service`, `automation-mock-playground-service`, `automation-recorder-service`, `automation-beckn-onix`, `automation-api-service-generator` | Present as directories but **not wired into `docker-compose.yml`** |
| MongoDB | Not in `docker-compose.yml` — required by `automation-db` |

**Implication:** running `./start.sh` as-is will fail. See Step 5 below for the two options (patch compose vs. run services individually).

---

## Prerequisites

- **Node.js** v18+ (v20+ for `automation-utils/build-tools`)
- **Docker** + Docker Compose v2
- **Git** with submodule support
- **Go** 1.24+ (only if running `automation-recorder-service` or building `automation-beckn-onix` from source)
- **MongoDB** — either run separately or add to compose (see Step 4)

---

## Step 1 — Clone and Initialise Submodules

```bash
git clone https://github.com/ONDC-Official/automation-framework.git
cd automation-framework
git submodule update --init --recursive
```

This pulls all submodules. Current submodules (11 total):

| Submodule | Purpose |
|---|---|
| `automation-logger` | Shared npm package `@ondc/automation-logger` |
| `automation-mock-runner` | Shared npm package `@ondc/automation-mock-runner` |
| `automation-validation-compiler` | Shared npm package **`ondc-code-generator`** (note: npm name differs from dir name) |
| `automation-utils/build-tools` | Shared npm package `@ondc/build-tools` (CLI: `ondc-tools`) |
| `automation-cache` | README only — `ondc-automation-cache-lib` is consumed from npm, not built locally |
| `automation-frontend` | React UI + Express BFF (two workspaces: `backend/` and `frontend/`) |
| `automation-backoffice` | Admin UI + Express backend |
| `automation-report-service` | Validation report engine |
| `automation-db` | Dual-DB persistence (MongoDB + YugabyteDB) |
| `automation-api-service-generator` | Build-time Go code generator for ONIX |
| `automation-beckn-onix` | Go HTTP server runtime (with 9 `.so` plugins) |

---

## Step 2 — Build Shared npm Packages

The monorepo uses **npm workspaces** — shared packages are symlinked into `node_modules/` so every service resolves them locally without npm publish.

**Why ordered building is required:** `@ondc/build-tools` depends on `@ondc/automation-mock-runner` and `ondc-code-generator`. Its `prepare` script runs `tsc` which imports those — if their `dist/` folders don't exist yet at install time, `tsc` fails.

```bash
npm run setup
```

This runs:
1. `npm install --ignore-scripts` — install dependencies without triggering `prepare` scripts
2. `npm run build:packages` — compile in dependency order:
   ```
   automation-logger
     → automation-mock-runner
       → automation-validation-compiler   (publishes as ondc-code-generator)
         → automation-utils/build-tools    (publishes as @ondc/build-tools)
   ```

> **Re-run only when** you change source inside a shared package. Service code changes don't require re-running setup.

---

## Step 3 — Environment Files

`docker-env/` already contains 6 files:

```
docker-env/
  api-service.env           ✅ present
  mock-service.env          ✅ present
  report-service.env        ✅ present
  automation-backend.env    ✅ present
  back-office.backend.env   ✅ present
  automation-db.env         ✅ present
```

**Still missing (required by `start.sh`):**

```
automation-frontend/frontend/docker.env   ⏳ create this
```

Create it with at minimum:
```
VITE_API_URL=http://localhost:3034
VITE_REPORT_URL=http://localhost:3000
```

(Check `automation-frontend/frontend/` for an `.env.example` if present, or ask the team for the reference values.)

**Verify existing env values** — because `api-service.env` / `mock-service.env` reference services (`automation-api-service`, `automation-mock-service`) whose directories have been removed, the URLs inside those env files likely need updating to point to whatever replaces them.

---

## Step 4 — MongoDB

`docker-compose.yml` does not include MongoDB, but `automation-db` requires it. Two options:

**Option A — Run separately:**
```bash
docker network create automation-network 2>/dev/null || true

docker run -d \
  --name mongodb \
  --network automation-network \
  -p 27017:27017 \
  mongo:6
```

Set in `docker-env/automation-db.env`:
```
MONGO_URI=mongodb://mongodb:27017/automation
```

**Option B — Add to `docker-compose.yml`:**
```yaml
  mongodb:
    image: mongo:6
    container_name: mongodb
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
    networks:
      - automation-network
```
(Also add `mongo_data:` under the `volumes:` section.)

---

## Step 5 — Start the Stack

**⚠ As-is, `docker-compose.yml` references two deleted directories** (`./automation-api-service` and `./automation-mock-service`) and will fail to build. Choose one of these paths:

### Option A — Patch the compose file (recommended for now)

Comment out or remove the `automation-api-service` and `automation-mock-service` blocks in `docker-compose.yml`, then:

```bash
./start.sh              # incremental build
./start.sh --rebuild    # full rebuild
./start.sh --detach     # background
```

The stack will come up with: UI frontend+backend, backoffice frontend+backend, report-service, automation-db, redis, yugabyte.

For the protocol enforcement layer, see Step 6 (ONIX flow).

### Option B — Run the new services individually

The services not yet in `docker-compose.yml` can be run on their own:

```bash
# Terminal 1 — Config service (required by mock-playground + beckn-onix workbench plugin)
cd automation-config-service && npm install && npm run dev

# Terminal 2 — Mock playground (replaces old mock-service)
cd automation-mock-playground-service && npm install && npm run dev

# Terminal 3 — Form service
cd automation-form-service && npm install && npm run dev

# Terminal 4 — Recorder service (Go)
cd automation-recorder-service && go run .
```

Each reads its own `.env` from the service root (see each service's `.env.example`).

---

## Step 6 — Generate & Run an ONIX Server for a Domain

The old `automation-api-service` is being replaced per-domain by a generated Go server built on `automation-beckn-onix`. This is a separate pipeline.

```bash
# 6a — Build the generator tooling (one-time)
npm run build:generator     # compiles automation-api-service-generator
npm run build:onix          # builds automation-beckn-onix Docker image locally
                            # (tag: automation-beckn-onix:local, from Dockerfile.adapter-with-plugins)

# 6b — Produce build.yaml for a specific domain
cd automation-specifications
git checkout draft-<DOMAIN>-<VERSION>     # e.g. draft-RET18-1.2.5

node ../automation-utils/build-tools/dist/index.js parse \
  -i config -o build.yaml

node ../automation-utils/build-tools/dist/index.js validate \
  -i build.yaml

# 6c — Generate the domain-specific API service
# NOTE: api-service-generator reads build.yaml from a hardcoded internal path.
#       Copy your generated build.yaml into its expected location first.
cp build.yaml ../automation-api-service-generator/src/config/build.yaml

cd ../automation-api-service-generator
node dist/index.js
# Output: build-output/automation-api-service/
#   - schemas/                  (L0 JSON Schemas)
#   - validationpkg/            (generated Go L1 validations)
#   - config/adapter.yaml       (beckn-onix module + plugin pipelines)
#   - config/*_router.yaml      (routing rules)
#   - config/*_no_config.yaml   (networkobservability gRPC config)
#   - Dockerfile + docker-compose.yml
#   - .env

# 6d — Run the generated domain server
cd build-output/automation-api-service
docker compose up --build
```

Available build-tools CLI commands (`@ondc/build-tools` binary `ondc-tools`):
- `parse` — merge `config/` dir + `$ref` → single `build.yaml`
- `validate` — zod-schema-validate a `build.yaml`
- `gen-change-logs` — generate change logs
- `gen-rag-table` — generate RAG retrieval table
- `push-to-db` — MongoDB ingestion of build artifacts
- `gen-markdowns` — generate markdown docs
- `make-onix` — **not implemented** (placeholder; use api-service-generator directly)

---

## Step 7 — Verify

Once the stack is up:

| Service | URL |
|---|---|
| Automation UI | http://localhost:3035 |
| Backoffice UI | http://localhost:5100/backoffice-frontend |
| UI Backend | http://localhost:3034 |
| Report Service | http://localhost:3000 |
| automation-db | http://localhost:8080 |
| YugabyteDB Master UI | http://localhost:7001 |
| YugabyteDB TServer UI | http://localhost:9000 |
| Generated ONIX server (per domain) | port defined in its `.env` |
| Mock Playground (standalone) | http://localhost:3000 (or its `PORT`) |
| Recorder Service (Go) | gRPC :8089, HTTP :8090 |

---

## Status Summary

| Step | Status |
|---|---|
| Submodules present (11) | ✅ Initialised |
| Workspace naming conflict fixed (duplicate `"name": "backend"`) | ✅ Done |
| Build ordering fixed — `npm run setup` script added | ✅ Done |
| All submodules synced to latest `main` | ✅ Done |
| 6 env files in `docker-env/` | ✅ Present |
| `automation-frontend/frontend/docker.env` | ⏳ Missing — create it |
| `docker-compose.yml` references two deleted dirs | ❌ Must patch (remove api-service + mock-service blocks, or restore them) |
| MongoDB added to compose or run separately | ⏳ Pending |
| New services (config, form, mock-playground, recorder, beckn-onix) in compose | ❌ Not wired — run standalone |
| ONIX per-domain generation integrated into `start.sh` | ⏳ Pending |
| End-to-end test run | ⏳ Pending |

---

## Summary — Short Version

The local setup approach:

1. `git submodule update --init --recursive` — pull all code
2. `npm run setup` — build shared packages in order
3. Patch `docker-compose.yml` (remove deleted `automation-api-service` + `automation-mock-service` blocks) and add MongoDB
4. Create `automation-frontend/frontend/docker.env`
5. `./start.sh` — bring up the UI, report-service, backoffice, and data layer
6. For domain-specific API service, run the ONIX generation pipeline (Step 6) separately and `docker compose up` inside its `build-output/`
7. For mock testing, run `automation-mock-playground-service` + `automation-config-service` + `automation-recorder-service` standalone on the same network
