---
id: local-dev-setup
kind: script
confidence: high
source: repo RUN-LOCALLY.md, README, Instructions.md, setup-local.sh
changed-by: adr-0002
---

# Local dev setup

Run the full workbench stack locally. For NP devs setting up / contributors.

## Entry conditions
- Docker Desktop running with ≥6GB RAM (8 recommended), 4 CPUs; git

## Roles
- developer, docker compose, setup-local.sh, 9 submodules

## Scenes (ordered)
1. Get code — clone monorepo; `git submodule update --init` (pins tested commits). (`--remote --merge` to pull latest frontend submodules.)
2. Secrets — docker-env/* prefilled in this repo; replace any *_change_me (GitHub OAuth optional).
3. Build frontends — `docker compose build ui-frontend backoffice-frontend` (VITE vars baked at build).
4. Start — `docker compose up -d` (~10-20 min first run; ~16 containers).
5. Verify — `docker compose ps` / `logs -f`; or `./setup-local.sh --check-only` health table.
6. Open — UI http://localhost:3035 ; Backoffice http://localhost:5100/backoffice-frontend ; admin creds in docker-env/ui-backend.env.
7. (Optional) domain api-service — see script [[spec-to-runtime]].

## One-shot
- `./setup-local.sh` (detects OS, installs deps, starts daemon, fills secrets, builds, launches, health-checks). Modes: --no-install, --check-only, --domain <branch>, --down, --help.

## Results
- full local workbench running; api-service optional/additive.

## Edge points
- depends_on orders creation not readiness; allow services to settle before opening UI.
- only one domain on 3032.
