# `local-workbench`

Sets up the whole workbench on your own machine for development. Every service is
cloned from GitHub and runs natively, with one command to start it all. Buyer (BAP)
and seller (BPP) sessions transact with each other through a local ONIX api-service,
so scenario flows run end to end without any hosted environment. The only remote
service used is the dev config-service.

This differs from the root `docker-compose.yml`: the services run from source, so
you can edit, restart and debug them. The frontend also uses a local build of
`automation-mock-runner-lib`, so a change to the lib can be tested in the UI.

## Prerequisites

| Tool | Why |
|---|---|
| git, Node 22+ (20.19 minimum), npm | everything |
| Docker Desktop (or Docker Engine + compose v2) | Mongo for automation-db, and the ONIX api-service image |
| Go | builds automation-recorder-service |
| Redis (`redis-server` on PATH) | backend sessions, the api-service, the recorder |

```bash
brew install node go redis && brew install --cask docker    # macOS
```

## Quick start

```bash
git clone https://github.com/ONDC-Official/automation-framework.git
./automation-framework/scripts/local-workbench/bootstrap.sh ~/ondc-workbench

cd ~/ondc-workbench
npm run dev
```

The first run takes a while: it does seven `npm ci`s, a Go build, generates the
api-service, and builds a `linux/amd64` image. Re-running the bootstrap skips
everything that is already done.

| Flag | |
|---|---|
| `--spec <branch>` | `automation-specifications` branch to build the api-service for. Default `draft-TRV11-2.1.0`. |
| `--skip-install` | Clone and configure only. |
| `--skip-docker` | Don't pre-build images; the first `npm run dev` builds them. |

Set `ONDC_GIT_BASE=git@github.com:ONDC-Official` to clone over SSH.

## What you get

```
ondc-workbench/
├── package.json, scripts/            orchestration (no dependencies of its own)
├── automation-frontend/              @ main-tech  backend :4000, Vite :5173
├── automation-mock-runner-lib/       @ main       installed into the frontend and mock service
├── automation-mock-playground-service/ @ main     :5004
├── automation-api-service-generator/ @ main       build-output/ = the ONIX api-service, :80
├── automation-db/                    @ main       :5001 (Mongo in docker, :27017)
├── automation-recorder-service/      @ main       gRPC :8089, HTTP :8090
└── automation-report-service/        @ main       :5005
```

`npm run dev` starts all of it, with prefixed logs, and one Ctrl-C stops everything.
It also starts Redis (:6379), a stub registry (:5010) and a monitor at
**http://localhost:4400**. The monitor shows every request between services and every
log line, grouped by transaction. Flags: `--no-workbench`, `--no-monitor`, `--no-mock`,
`--frontend-only`. Other root scripts: `npm run sync:lib` after a lib change, `npm test`
and `npm run build`.

## Running a loop

1. Open http://localhost:5173/scenario and enter subscriber URL `https://testing`.
   This creates a seller session and a buyer session.
2. Start the flow in the **BAP** tab first, then in the BPP tab.
3. Click "Stop flow", then "Generate Report".

## How it is wired

- **One api-service URL:** `http://workbench.localhost/api-service`. It is used by the
  mock (`API_SERVICE_URL`), the backend (`API_SERVICE`) and the frontend
  (`VITE_BASE_URL`). Port 80 and a dotted host are required: the mock derives
  `bap_id`/`bpp_id` from that host, and the report rejects `host:port` ids.
  `*.localhost` resolves to loopback without editing `/etc/hosts`.
- **One build, one domain/version:** the api-service is generated for a single spec
  branch. A session for any other domain/version gets a 404 on every call. To switch,
  delete `automation-api-service-generator/build-output` and re-run with `--spec`.
- **Fresh signing keypair:** the bootstrap mints one for the api-service.
  `scripts/local-registry.js` answers every registry lookup with its public key, so
  signatures verify offline. It is not a real ONDC key.
- **Fixes to the generated output:** the generator's output is adjusted so it runs in
  this topology. The `.env` is un-indented and gets `IN_HOUSE_REGISTRY` and `REDIS_URL`.
  The compose file gets `extra_hosts`, a GET healthcheck, and the `ONIX_*` overrides
  the monitor uses.
- **The recorder is required:** it writes each transaction's `apiList`. Without it,
  every step after the first fails context validation.

## Linux

The script handles the `host.docker.internal` mapping. You need to do two things
yourself:

- allow port 80: `sudo sysctl net.ipv4.ip_unprivileged_port_start=80`
- run Redis so containers can reach it over the docker bridge (`--protected-mode no`)
