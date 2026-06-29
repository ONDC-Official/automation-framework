# Run the Automation Framework Locally — Step-by-Step

This guide is tailored to the current state of your repo. The repo is already prepared:

- ✅ All 9 submodules are initialized and checked out at pinned commits
- ✅ Local dev secrets filled in (`.env`, `docker-env/*`) — no `_change_me` left except GitHub OAuth (optional, see Step 5)
- ✅ `docker-compose.yml` validated: all env files, build contexts, and Dockerfiles resolve

You just need Docker Desktop running and a few commands in your **Mac Terminal**. (These cannot be run for you — they execute on your machine, not in this session.)

---

## Fastest path: the one-shot script

A `setup-local.sh` script in this folder does everything below automatically — detects your OS, installs any missing prerequisites (git, Docker, Compose), starts the Docker daemon, fills secrets, builds and launches the stack, then health-checks every service and prints a pass/fail table.

```bash
cd ~/Desktop/git_workspace/workbench-knowledge/automation-framework
chmod +x setup-local.sh
./setup-local.sh
```

Other modes:
```bash
./setup-local.sh --no-install     # skip installs (deps already present)
./setup-local.sh --check-only     # just health-check a running stack
./setup-local.sh --domain draft-FIS12-2.3.0   # also build a domain API service
./setup-local.sh --down           # stop the stack
./setup-local.sh --help
```

On macOS the script installs Docker Desktop via Homebrew if missing; you may be prompted for your password (sudo) and, on first install, may need to confirm Docker Desktop's startup once in the GUI. Prefer the manual steps below if you'd rather control each step yourself.

---

## 0. Prerequisites (one-time)

1. **Docker Desktop** installed and running. Install: https://docs.docker.com/get-docker/
2. Give Docker enough resources — this stack runs ~16 containers. In Docker Desktop → Settings → Resources, allocate at least **6 GB RAM** (8 GB recommended) and 4 CPUs.
3. Verify Docker works:
   ```bash
   docker --version
   docker compose version
   ```

Git and the submodules are already handled — you don't need to clone or run `git submodule update`.

---

## 1. Go to the framework directory

```bash
cd ~/Desktop/git_workspace/workbench-knowledge/automation-framework
```

---

## 2. Build the frontend images, then start the whole stack

The two frontends inject build-time variables, so they're built explicitly first:

```bash
docker compose build ui-frontend backoffice-frontend
docker compose up -d
```

First run pulls base images and builds ~12 services from source — expect **10–20 minutes**. Subsequent runs are cached and fast.

Watch progress / logs:
```bash
docker compose ps          # status of all containers
docker compose logs -f     # tail all logs (Ctrl-C to stop tailing)
```

Wait until the core services show `running`/healthy before opening the UIs.

---

## 3. Open the app

| Service | URL |
|---|---|
| **Automation UI (main)** | http://localhost:3035 |
| UI Backend | http://localhost:3034 |
| **Backoffice Frontend** | http://localhost:5100/backoffice-frontend |
| Backoffice Backend | http://localhost:5200 |
| Mock Service | http://localhost:3031 |
| Report Service | http://localhost:3000 |
| Form Service | http://localhost:3300 |
| DB Service | http://localhost:5001 |
| Config Service | http://localhost:5556 |
| User Management | http://localhost:8082 |
| Registry Service | http://localhost:8080 |
| Jaeger (tracing UI) | http://localhost:16686 |
| Domain API Service (optional, Step 4) | http://localhost:3032 |

**Admin login** (UI backend) — credentials I generated for you:
- Username: `admin`
- Password: see `docker-env/ui-backend.env` → `ADMIN_PASSWORD`

---

## 4. (Optional) Run a domain API service

Each ONDC domain/version (FIS12, RET10, TRV11, …) is a separate, optional API service. The core stack above runs fine without it. To add one:

```bash
# Core stack must already be up (Step 2) — db-service needs to be running.

# List available spec branches:
./scripts/build-api-service.sh

# Build a specific domain (example):
./scripts/build-api-service.sh draft-FIS12-2.3.0

# Secrets for the api-service are already filled in:
#   docker-env/api-service-common.env  (sample keys present)

# Start the api-service alongside the running stack:
docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build
```

Reachable at http://localhost:3032. Only one domain service can run on that port at a time.

**Switch domains:**
```bash
docker compose -f docker-compose.yml -f docker-compose.api.yml down
./scripts/build-api-service.sh draft-RET10-1.2.5
docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build
```

> `api-service/` and `docker-compose.api.yml` are git-ignored and created by the script.

---

## 5. (Optional) Enable GitHub login

GitHub OAuth is the only secret left as a placeholder, in `docker-env/automation-user-management.env`. It's only needed if you want GitHub sign-in; the admin username/password login works without it. To enable:

1. Create an OAuth app at https://github.com/settings/developers
   - Authorization callback URL: `http://localhost:8082/auth/github/callback`
2. Put the values in `docker-env/automation-user-management.env`:
   ```
   GITHUB_CLIENT_ID=...
   GITHUB_CLIENT_SECRET=...
   ```
3. Restart that service:
   ```bash
   docker compose up -d --build automation-user-management
   ```

---

## Useful commands

```bash
# Stop everything (keeps data volumes)
docker compose down

# Stop AND wipe mongo/redis data
docker compose down -v

# Rebuild + restart one service after a code change in its submodule
docker compose up -d --build <service-name>

# Pull latest frontend code, then rebuild
git submodule update --remote --merge
docker compose build ui-frontend backoffice-frontend
docker compose up -d ui-frontend backoffice-frontend

# Follow logs for a single service
docker compose logs -f ui-backend
```

---

## Troubleshooting

- **Port already in use** → something else is on that port (e.g. 3000, 27017). Stop it, or change the host port mapping in `docker-compose.yml`.
- **A service keeps restarting** → `docker compose logs <service>` to see why; usually a dependency (mongo/redis/db-service) wasn't ready yet — give it a minute or `docker compose up -d` again.
- **Out of memory / builds killed** → raise Docker Desktop's RAM allocation (Step 0.2).
- **Frontend shows blank / wrong API URL** → frontends bake URLs at build time; rebuild them: `docker compose build ui-frontend backoffice-frontend && docker compose up -d ui-frontend backoffice-frontend`.
- **`automation-user-management` or `form-service` fails to pull** → these come from `ghcr.io/ondc-official/...`; ensure you have internet access (no GitHub auth needed for public images).
