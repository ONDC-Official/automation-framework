# Local Setup & Codebase Orientation

A working guide for getting Protocol Workbench running on a local machine and
building a real understanding of the nine codebases behind it.

Target domain for this guide: **`draft-FIS12-2.3.0`** (Financial Services — Business Loans
and Loan Against Mutual Funds). Every command below is written for that branch; swap the
branch name to follow a different domain.

Audience: someone who wants to *understand the architecture* and *contribute code*.

---

## 1. What this repository actually is

`automation-framework` contains **no application code**. It is ~880K of Docker Compose
files, environment templates, and shell scripts that orchestrate nine separate
repositories, wired in as git submodules. Cloning this repo without initialising
submodules gives you nine empty directories.

The single most important architectural fact:

> **`automation-specifications` is the source of truth, not the code.**
> A domain spec written in YAML is compiled by `@ondc/build-tools` into a single
> `build.yaml`, which `@ondc/api-service-generator` then turns into a **Go** service:
> a set of compiled plugins plus config, loaded into a Beckn-ONIX server. Everything
> else in the system is infrastructure arranged around that generated service.

Internalising this early saves a lot of confusion. Most of the protocol behaviour you will
want to change lives in YAML, not in application code.

### The pipeline

```
automation-specifications/config/     (YAML spec: paths, flows, validations, attributes)
        │
        │  @ondc/build-tools parse   →  resolves all $ref links
        ▼
    build.yaml                        (single resolved artifact)
        │
        │  @ondc/build-tools validate
        │  @ondc/api-service-generator      (IS_ONIX_ENABLED=true)
        ▼
    api-service/build-output/temp/
        ├── automation-beckn-plugins/  13 Go plugins   (101 .go files)
        ├── validationpkg/             generated Go validators (40 .go files)
        ├── config/adapter.yaml        declarative module/handler/plugin/step pipeline
        └── schemas/ondc_<domain>/     JSON schemas
        │
        │  docker compose build
        │    stage 1: golang:1.25.5      → compiles plugins to .so
        │    stage 2: automation-beckn-onix base image (Debian 13 + Go + server source)
        ▼
    api-<domain>-<version> container   ← behind an nginx gateway on :3032
```

`scripts/build-api-service.sh` drives this entire pipeline end to end.

### The protocol engine is Go, not TypeScript

This is the most important thing to get right about the architecture, and raw file
counts actively mislead here. Counting source files suggests TypeScript dominates
(~600 `.ts`/`.tsx` against 16 `.go` in the recorder). But the **protocol runtime** —
signing, schema validation, context validation, routing, encryption, observability — is
Go, generated per domain and loaded as `.so` plugins into an ONIX server.

The thirteen plugins:

```
router                signer                  signvalidator
schemavalidator       ondc-validator          encryption-middleware
outgoing-encryption-middleware                network-observability
cache                 workbench-main          workbench-keymanager
workbench-callback-redirect
```

The TypeScript services are the **workbench around** that engine — UI, sessions,
reporting, config resolution, mock counterparty. They are not the protocol
implementation.

The server prints its assembled pipeline at startup, and that line is the request
lifecycle in one sentence:

```
Processor steps initialized:
  [ondcWorkbenchReceiver  addRoute  validateSchema
   ondcWorkbenchValidateContext  sign  validateOndcCallSave]
```

Worth knowing: the ONIX base image is Debian 13, ships Go at `/usr/local/go/bin/go`,
**and contains the ONIX server's own source** under `/workspace/app`. Both the plugins
and the server itself are therefore debuggable at source level — see
[`DEBUGGING.md`](./DEBUGGING.md).

---

## 2. The nine codebases

| Repository | Language / stack | Scale | Role |
|---|---|---|---|
| `automation-specifications` | YAML DSL (OpenAPI 3.x + custom `x-` extensions) | 38 files on the FIS12 branch | Source of truth; compiles into the Go protocol engine |
| *(generated)* `api-service/build-output` | **Go** plugins + generated validators, on a Beckn-ONIX server | 101 + 40 `.go` files per domain | The actual protocol engine — signing, validation, routing |
| `automation-frontend` | React 19 + TS + Vite (frontend), TS + Express (backend) | 650 files — largest | Main workbench UI and its BFF |
| `automation-report-pramaan` | Plain JS, Node 16, Mocha/Chai | 830 files, 13 MB | Legacy buyer/seller NP test APIs |
| `automation-report-service` | TypeScript + Express | 404 ts + 111 yaml | Validation engine, per-domain protocol rules |
| `automation-mock-playground-service` | TypeScript + Express | 75 ts | Simulates the counterparty network participant |
| `automation-recorder-service` | Go 1.24 + gRPC + protobuf + Redis | 16 go | Audit event consumer — the only *hand-written* Go service |
| `automation-db` | TypeScript + TypeORM + Mongoose | 36 ts | Spec and session store |
| `automation-backoffice` | TS + Express (backend), React + Vite (frontend) | 34 ts / 16 tsx | Admin console |
| `automation-config-service` | TypeScript + Express | 16 ts — smallest | Config and flow resolution |

Four real languages — **TypeScript** (six services), **React/TSX** (two UIs), **Go**
(the recorder *and* the generated protocol engine), and **plain JavaScript** (pramaan) —
plus YAML used as a domain-specific language, which is the one that matters most.

Do not read the TypeScript file count as "this is a TypeScript system". Go carries the
protocol; TypeScript carries the workbench around it. See §1.

### Shared idiom across the TypeScript services

The six TS backends are near-identical in shape, so learning one teaches you five:

- Express + `src/{routes,controllers,services,middleware,config,types,utils}`
- Redis via `ioredis` / `connect-redis`, Mongo via `mongoose`
- OpenTelemetry auto-instrumentation exporting to Jaeger
- `nodemon` + `ts-node`/`tsx` for `npm run dev`, `tsc` for `npm run build`
- A shared internal package set: `@ondc/automation-logger`, `@ondc/automation-mock-runner`,
  `ondc-automation-cache-lib`

---

## 3. Prerequisites

| Requirement | Why |
|---|---|
| Docker Desktop + Compose v2 | Runs all 16 core services |
| **Rosetta enabled** (Apple Silicon only) | Two images are pinned `platform: linux/amd64` |
| Node 20+ and npm | `npx` drives the spec build tools; native `npm run dev` loops |
| Python 3 with **PyYAML** | `build-api-service.sh` parses `build.yaml` with `python3 -c "import yaml"` |
| `git`, `jq`, `curl` | Submodules; `scripts/flow-automation/start-scenario.sh` needs jq |
| ~10 GB free disk, 8 GB+ RAM | 11 services build from source; images are not small |

Verify in one shot:

```bash
docker info >/dev/null 2>&1 && echo "docker: running" || echo "docker: NOT running"
node --version && python3 -c "import yaml; print('PyYAML', yaml.__version__)" && jq --version
```

PyYAML is an undocumented prerequisite — the build script fails at the "Reading domain and
version" step without it. Install with `pip3 install pyyaml` if missing.

---

## 4. Known issues — read before you start

These are real defects and sharp edges in the repository as it stands. Knowing them up
front prevents hours of debugging things that were never going to work.

### 4.1 `registry-service` does not exist

`.env:15` defines `REGISTRY_SVC=http://registry-service:8080/v2.0/`, and the README port
table lists a Registry Service on port 8080 — but **no such service is defined in
`docker-compose.yml`**. The value is injected into `ui-backend` as `IN_HOUSE_REGISTRY` and
into the generated api-service as both `IN_HOUSE_REGISTRY` and `IN_HOUSE_URL`.

Any code path that calls the in-house registry will fail DNS resolution inside the Docker
network. Expect it; do not debug it as a local mistake.

### 4.2 Apple Silicon and amd64-pinned images

`automation-user-management` and `form-service` are pre-built images pinned to
`platform: linux/amd64`. On arm64 Macs, enable **Docker Desktop → Settings → General →
"Use Rosetta for x86/amd64 emulation"**, or these two will run slowly or fail outright.

These are also the only two services with no source submodule — they are consumed as
published GHCR images and cannot be modified locally.

### 4.3 Submodule pins are not on `main`

`.gitmodules` declares `branch = main` for all nine submodules, but the pinned commits are
on feature branches:

```
automation-backoffice        → feat/logs-api           (2 commits ahead)
automation-config-service    → main-backup-2nd-april  (46 commits ahead)
automation-db                → hot-fix-workflow       (39 commits ahead)
automation-frontend          → mofahsan-patch-12       (5 commits ahead)
automation-report-pramaan    → logistics-changes      (72 commits ahead)
```

**Do not run `git submodule update --remote` until you have a working baseline.** It will
move every submodule to upstream `main`, which is not the combination these compose files
and env templates were tested against. The README suggests it for the two frontends —
treat that as a deliberate later step, not part of first-time setup.

To return to the tested baseline at any point:

```bash
git submodule update --init --force
```

### 4.4 `build-api-service.sh` mutates tracked files

It rewrites the committed `.env` in place:

```bash
sed -i '' 's|^API_SVC=.*|API_SVC=http://api-service:80/api-service|' "$FRAMEWORK_DIR/.env"
```

Two consequences:

- Your git tree becomes dirty after every run. This is expected, not a mistake.
- `.env` currently ships as `API_SVC=http://host.docker.internal:3032/api-service`, the
  setting for running the api-service natively outside Docker. The script overwrites that
  with the in-network nginx address. If you want the native loop back (§8), restore it by
  hand.

The `sed -i ''` form is BSD/macOS syntax and will fail on GNU sed (Linux). Use
`sed -i` there if you ever run this on a Linux box.

### 4.5 Committed private keys

`README.md` and `docker-env/api-service-common.env` contain live Ed25519 signing and X25519
encryption **private** keys, labelled "SAMPLE FOR TESTING". They are valid keypairs sitting
in a public repository.

Fine for local work. Generate your own before anything touches a real network, and never
reuse these as a network-participant identity. Treat them as public knowledge.

### 4.6 Two clones of `automation-specifications`

This one reliably confuses newcomers. There are two separate working copies of the same
repository:

| Path | Branch | Contents | Git-tracked here? |
|---|---|---|---|
| `automation-specifications/` | `main` | `README.md`, `DEPLOY.md` only — CI workflow docs | Yes, as a submodule |
| `api-service/` | `local-spec` (from `draft-FIS12-2.3.0`) | The actual `config/` spec tree | No, gitignored |
| `api-services/<branch>/` | `local-spec-<branch>` | Further branches built side by side (§6), as git worktrees of `api-service/` | No, gitignored |

The submodule on `main` has **no `config/` directory** — spec content only exists on the
~60 `draft-*` / `release-*` branches. `build-api-service.sh` makes its own clone into
`api-service/`.

**Edit `api-service/config/`, never the submodule.**

### 4.7 Near-zero test coverage and no test gate in CI

| Repository | Test files | Tests run in CI? |
|---|---|---|
| `automation-recorder-service` (Go) | 7 | No |
| `automation-mock-playground-service` | 2 | **Yes** — deploy gated on `npm test` |
| `automation-frontend/frontend` | 2 | No |
| `automation-config-service` | 1 | No |
| `automation-db`, `automation-report-service`, both backends, backoffice frontend | **0** | No |

Across all nine repositories there are 21 GitHub Actions workflows. Twenty of them are
deploy-only; `automation-mock-playground-service/.github/workflows/deploy.yml` is the sole
workflow that runs tests before shipping.

**Implication for contributing:** there is effectively no automated safety net. Verify
changes by running flows end to end (§6) and reading Jaeger traces, not by trusting CI.
`automation-recorder-service` is the one codebase where you can write a change and have
existing tests tell you whether you broke something.

There are also no `CONTRIBUTING.md` files and no shared lint or format standard —
ESLint/Prettier configs exist only in `automation-frontend/frontend`,
`automation-backoffice/frontend`, and `automation-mock-playground-service`. Only
`automation-frontend` has git hooks (husky).

### 4.8 GHCR pulls fail with `denied` if you have stale ghcr.io credentials

`docker compose up` aborts the **entire** stack with:

```
Image ghcr.io/ondc-official/automation-user-management:... Error error from registry: denied
Error response from daemon: error from registry: denied
```

This is almost always a local credential problem, not a permissions problem. Both images are
**public** — an anonymous token request against `ghcr.io/v2/ondc-official/<image>/manifests/<tag>`
returns HTTP 200. But if `~/.docker/config.json` holds a stale or expired `ghcr.io` entry,
Docker sends those credentials and GHCR rejects the authenticated request outright rather
than falling back to anonymous access.

Fix:

```bash
docker logout ghcr.io
```

Confirm the images are public before assuming you need a token:

```bash
tok=$(curl -s "https://ghcr.io/token?scope=repository:ondc-official/automation-form-service:pull" | jq -r .token)
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $tok" \
  https://ghcr.io/v2/ondc-official/automation-form-service/manifests/dev-1.0.0-7792084
# 200 = public, your local credentials are the problem
```

After logging out, a bare `docker pull` of either image fails differently:

```
no matching manifest for linux/arm64/v8 in the manifest list entries
```

That is expected — both images are **amd64-only**. `docker compose` handles it via the
`platform: linux/amd64` key. Only a manual pull needs the flag:

```bash
docker pull --platform linux/amd64 ghcr.io/ondc-official/automation-form-service:dev-1.0.0-7792084
```

### 4.9 `ui-backend` returns 500 for downstream 4xx

`POST /sessions` with an invalid body returns **500**, not 400. The downstream service
correctly replies `400 {"message":"domain, version, usecase are required"}`, but
`createSessionService` lets the axios error propagate uncaught, so the client sees a server
error for what is a client mistake. See `automation-frontend/backend/src/services/sessionService.ts`
and `controllers/sessionController.ts`.

Worth knowing when debugging: **a 500 from `ui-backend` often means a 4xx from something
behind it.** Check the container log for the real status before assuming a crash.

### 4.10 Miscellaneous

- `automation-recorder-service` has a **23 MB compiled Go binary** (`automationrecorder`)
  committed to the repository — it accounts for essentially all of that submodule's size.
- `automation-report-pramaan` builds on `node:16-alpine`, which is past end of life.
- `docker-compose.yml` declares the obsolete `version: "3.8"` key; Compose v2 warns and
  ignores it. Harmless.
- Only one domain api-service can run at a time — port 3032 is fixed.

---

## 5. Phase 1 — Get a baseline running

Bring up the core stack **without** the api-service first. The api-service is entirely
optional and additive; including it in a first run doubles the failure surface for no gain.

```bash
# 1. Fetch all nine codebases at their pinned commits
git submodule update --init

# 2. Start Docker (enable Rosetta first on Apple Silicon)
open -a Docker

# 3. Build — 11 services compile from source, so the first run is slow (20–40 min)
docker compose build

# 4. Clear any stale GHCR credentials (see 4.8) — otherwise `up` aborts
docker logout ghcr.io

# 5. Start all 16 services
docker compose up -d
docker compose ps
```

### Verifying

| Service | URL |
|---|---|
| Workbench UI | http://localhost:3035 |
| UI Backend | http://localhost:3034 |
| Backoffice | http://localhost:5100/backoffice |
| Backoffice Backend | http://localhost:5200 |
| Mock Service | http://localhost:3031 |
| Report Service | http://localhost:3000 |
| Form Service | http://localhost:3300 |
| DB Service | http://localhost:5001 |
| Config Service | http://localhost:5556 |
| User Management | http://localhost:8082 |
| **Jaeger UI** | http://localhost:16686 |

**Jaeger is the highest-value debugging tool in this stack.** OpenTelemetry
auto-instrumentation is wired into most TypeScript services, so you get distributed traces
of cross-service calls without configuring anything. When a flow misbehaves, open Jaeger
before opening a log file.

Useful commands while getting green:

```bash
docker compose logs -f ui-backend          # follow one service
docker compose ps --format 'table {{.Name}}\t{{.Status}}'
docker compose build --no-cache <service>  # after fixing a broken build
docker compose down                        # stop (add -v to wipe mongo/redis volumes)
```

---

## 6. Phase 2 — One domain, end to end (FIS12 2.3.0)

`docker compose up -d` from Phase 1 must already be running — the build script pushes spec
data to `db-service` and will warn if it cannot reach it.

```bash
# List all available spec branches (~60 of them)
./scripts/build-api-service.sh

# Build the FIS12 2.3.0 service
./scripts/build-api-service.sh draft-FIS12-2.3.0

# Start it alongside the running core stack
docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build
```

The api-service lands on **http://localhost:3032**, behind a generated nginx gateway that
replicates production routing (`/mock/ONDC:FIS12/2.3.0/*` → playground,
`/api-service/ONDC:FIS12/2.3.0/*` → the generated service).

Before starting, review `docker-env/api-service-common.env` and replace the committed
sample keys (§4.5) if you intend to do anything beyond local experimentation.

### What FIS12 2.3.0 contains

Two use cases, both in `DRAFT` status:

- **BUSINESS LOAN** — 11 flows, including account-aggregator and file-upload variants,
  foreclosure, missed EMI, pre-part payment, dedupe check, and master search
- **LAMF LOAN** (Loan Against Mutual Funds) — 3 flows, including single-redirection credit
  line with MFC

Spec surface, all on the `draft-FIS12-2.3.0` branch:

| File | Lines | What it defines |
|---|---|---|
| `config/specs/openapi.yaml` | 3,814 | Paths and components — the protocol surface |
| `config/validations/index.yaml` | 3,526 | `x-validations` — the protocol rules |
| `config/flows/index.yaml` | 257 | Flow manifest, one file per flow under `flows/<use-case>/` |
| `config/actions/index.yaml` | 148 | `x-supported-actions` |
| `config/index.yaml` | 33 | Root manifest — everything else hangs off `$ref`s here |

Start with `config/index.yaml`. It is 33 lines and it maps the entire DSL.

This branch also ships its own AI-assisted review tooling —
`.claude/skills/review-flow-config/` and `.github/instructions/flow-config.instructions.md` —
which is effectively the missing contributor guide for writing flow configs. Read it before
you write your first flow.

### Running a flow headlessly

```bash
./scripts/flow-automation/start-scenario.sh \
  --base-url http://localhost:3035 \
  --domain ONDC:FIS12 --version 2.3.0 \
  --usecase "BUSINESS LOAN" \
  --flow-id "?" \
  --subscriber-url https://my-np.example.com \
  --dry-run
```

Passing `?` for any of `--domain`, `--version`, `--usecase`, or `--flow-id` makes the error
message enumerate the valid values at that level. `--dry-run` validates without creating
anything. Add `--drive` to have the script answer each input step until the flow completes.

This script is also the best available documentation of the UI backend's real API contract —
it reproduces exactly what the Scenario Testing UI does (`POST /sessions`, `POST /flow/new`,
`PUT /sessions`). Read it when you need to know how the frontend talks to the backend.

### Iteration loops

```bash
# Changed generated code in api-service/build-output/ — no spec change
docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build

# Changed the spec in api-service/config/ — full regeneration
./scripts/build-api-service.sh draft-FIS12-2.3.0
docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build

# Switching domains
docker compose -f docker-compose.yml -f docker-compose.api.yml down
./scripts/build-api-service.sh draft-RET10-1.2.5
docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build
```

Note that regenerating deletes `build-output/` wholesale (`rm -rf build-output`). Any
hand-edits to generated code are lost on every spec regeneration — an important constraint
when deciding whether a fix belongs in the spec or in the generator.

### Several domains side by side

Pass more than one branch to run several domains at once:

```bash
./scripts/build-api-service.sh draft-FIS12-2.3.0 draft-RET10-1.2.5
docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build
```

- The first branch builds in `api-service/`, as before. Each further branch builds in
  `api-services/<branch>/`, a git worktree of the same clone, with its own `config/` and
  `build-output/`.
- Each branch gets its own service (`api-<domain>-<version>`) in `docker-compose.api.yml`.
- The nginx gateway on :3032 routes `/api-service/<domain>/<version>/` and
  `/mock/<domain>/<version>/` to the right service; `/` still goes to the first one.
- Two branches of the same domain and version can't run together; the script stops.
- `scripts/debug-api-service.sh` debugs the first branch's service.

### FD (`ONDC:FIS14:FD`)

FD addresses REST resources rather than Beckn's `POST /<action>`, so an FD branch builds an
FD-specific service: modules `issuer/`, `investor-app/` and `mock/`, the FD-only plugins
`fdgate` and `fdtransport`, and a route table in `build-output/temp/config/fd_routes.yaml`.
Its nginx route forwards the request URI unchanged, because FD signatures cover the path,
and allows bodies up to 8 MiB.

The FD-capable tools and plugins are not released yet. Until they are, point the script at
local builds of them:

```bash
PWB_TOOLING_DIR=<tooling folder with the FD-capable build-tools, code generator and api-service-generator> \
SPECS_LOCAL=./automation-specifications \
PLUGINS_GIT=<local automation-beckn-plugins> PLUGINS_REF=feat/fd-workbench \
  ./scripts/build-api-service.sh draft-FIS12-2.3.0 draft-FIS14FD-0.1.4
```

- `SPECS_LOCAL` supplies a branch that isn't on GitHub yet (`draft-FIS14FD-0.1.4`).
- `PLUGINS_GIT` and `PLUGINS_REF` choose the plugins the generator clones. Unset,
  `PLUGINS_REF` comes from `tooling/versions.env`.
- The tools are FD-only additions: they generate the same output as the released tools for
  every Beckn branch (checked with `automation-specifications/tooling/golden/golden.sh`), so
  a Beckn branch can be built alongside with them.

---

## 7. Phase 3 — Reading the code

Do **not** read repository by repository. Nine codebases in four languages, read linearly,
is weeks of low-retention work. Follow one transaction through the system instead; the
architecture explains itself that way.

Suggested order — each layer motivates the next:

**1. `api-service/config/` → `api-service/build-output/temp/`**
The highest-leverage hour in the entire codebase, and the one place the whole design
becomes obvious. Read in this order:

1. `config/index.yaml` (33 lines) — the root manifest; every `$ref` from here maps the DSL
2. one flow file from `config/flows/BUSINESS_LOAN/` — what a flow declaration looks like
3. `build-output/temp/config/adapter.yaml` — what that spec became: modules, handlers,
   plugins, and the ordered `steps` list per route
4. `build-output/temp/automation-beckn-plugins/ondc-validator/` — a plugin actually
   implementing one of those steps in Go

Diffing declared intent against generated output teaches you more about this system than
any other single activity. Note step 3 is **not** an Express app — it is the ONIX
adapter config that wires Go plugins into a request pipeline.

**2. `automation-config-service`** — 16 TypeScript files, the smallest service. Warms you up
on the shared Express/Redis/OpenTelemetry idiom that five other services repeat verbatim.

**3. `automation-db`** — 36 files. Where specs and sessions are persisted. Read
`src/entity/` and `src/routes/` and you have the data model. Note it carries both TypeORM
(`pg`) and Mongoose (`mongodb`) dependencies while running against Mongo — some of that is
vestigial.

**4. `automation-mock-playground-service`** — 75 files, and the best-engineered codebase
here: dependency injection container, `zod` validation, structured `pino` logging, real
tests, ESLint + Prettier, and a genuine README. If you want a model for what "good" looks
like in this org, this is it.

**5. `automation-report-service`** — `src/validations/<domain>/` holds the protocol rules as
executable code, including `ONDC:FIS12/`. Compare these against
`config/validations/index.yaml` from the spec to understand which rules are declarative and
which are hand-written.

**6. `automation-recorder-service`** — 16 Go files, self-contained, with a clear README and
seven test files. The only hand-written Go repo (the api-service Go is generated). Fully independent of the rest; read it whenever you want a change of pace.
It consumes audit events over gRPC and performs three side effects (Redis cache update
synchronously; log push and DB save asynchronously).

**7. `automation-frontend`** — 650 files, by far the largest. Read the `backend/` BFF first
(22 dependencies, straightforward Express), then approach `frontend/` feature by feature,
driven by whatever you clicked in Phase 2. Never front to back. Notable: React 19, Radix UI,
`@rjsf` for schema-driven forms, `@xyflow/react` for flow visualisation, Monaco for editing.

**8. `automation-backoffice`** — small and conventional. Read when you need admin behaviour.

**9. `automation-report-pramaan`** — 830 plain-JS files on end-of-life Node 16. Legacy.
Read only when something specifically forces you there.

---

## 8. Phase 4 — The contribution loop

Once you are editing rather than reading, stop rebuilding containers for every change.

A full debug environment — VS Code launch configs for all four target types, per-service
`.env.local` files, and Delve wiring for both Go targets — is set up and documented in
[`DEBUGGING.md`](./DEBUGGING.md). The summary:

**Hybrid setup:** leave infrastructure and peripheral services in Docker, and run the one
service you are working on natively for hot reload and a real debugger.

```bash
# Keep everything except the service you're changing
docker compose up -d
docker compose stop config-service

# Run it natively — every TS service has a dev script
cd automation-config-service
npm install
npm run dev
```

You will need to point the native process at the Docker network's exposed ports —
`REDIS_HOST=localhost`, `MONGO_URI=mongodb://localhost:27017/...`, and the `localhost:<port>`
forms of sibling services rather than their container names. The `API_SVC=http://host.docker.internal:3032`
line already in `.env` (§4.4) is the established seam for the reverse direction: containers
reaching a natively-run api-service.

### Per-repository commands

| Repository | Dev | Build | Test | Lint |
|---|---|---|---|---|
| `automation-db` | `npm run dev` | `npm run build` | — | — |
| `automation-config-service` | `npm run dev` | `npm run build` | `npm test` (jest) | — |
| `automation-mock-playground-service` | `npm run dev` | `npm run build` | `npm test` | `npm run lint` |
| `automation-report-service` | `npm run dev` | `npm run build` | `npm test` (trv11 only) | — |
| `automation-frontend/frontend` | `npm run dev` | `npm run build` | `npm test` | `npm run lint` |
| `automation-frontend/backend` | `npm run dev` | `npm run build` | — | — |
| `automation-backoffice/backend` | `npm run dev` | `npm run build` | — | — |
| `automation-backoffice/frontend` | `npm run dev` | `npm run build` | — | `npm run lint` |
| `automation-recorder-service` | `go run .` | `go build` | `go test ./...` | `go vet ./...` |
| `automation-report-pramaan/*` | `npm run dev` | — | — | — |

### Submodule mechanics

Each submodule is an independent repository with its own history and pull requests. A change
inside one is **not** captured by committing in `automation-framework`:

```bash
cd automation-config-service
git checkout -b fix/my-change        # detached HEAD by default — always branch first
# ... edit, commit, push, open a PR against that repo ...

cd ..
git add automation-config-service    # records the new pinned commit
git commit -m "chore: bump config-service pin"
```

Submodules check out in **detached HEAD** state. Create a branch before your first commit or
the work is easy to lose.

### Where a change belongs

A recurring judgement call, and worth getting right:

| Symptom | Usually belongs in |
|---|---|
| Wrong protocol rule, flow step, or error code for a domain | `automation-specifications/config/` — the spec |
| Every generated service has the same bug | `@ondc/api-service-generator` (external package) |
| Validation logic beyond what the DSL expresses | `automation-report-service/src/validations/` |
| Counterparty simulation behaviour | `automation-mock-playground-service` |
| UI behaviour | `automation-frontend/frontend` |
| Audit, tracing, or cache side effects | `automation-recorder-service` |

Edits to `api-service/build-output/` are **always** temporary — regeneration wipes them
(§6). Use them to test a hypothesis, then push the real fix upstream into the spec or the
generator.

### Before opening a pull request

With no CI test gate on eight of the nine repositories (§4.7), self-verification is the job:

1. Run the affected service natively and exercise it directly.
2. Run a full FIS12 flow via `start-scenario.sh --drive` and confirm it still completes.
3. Read the Jaeger trace for that flow — it surfaces failures that logs alone hide.
4. Run whatever tests do exist (`go test ./...` for the recorder; `npm test` for
   mock-playground, config-service, frontend).
5. For spec changes, use the `review-flow-config` skill shipped on the spec branch (§6).

---

## 9. Quick reference

```bash
# Baseline
git submodule update --init
docker compose build && docker compose up -d

# Add the FIS12 domain service
./scripts/build-api-service.sh draft-FIS12-2.3.0
docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build

# Run a flow headlessly
./scripts/flow-automation/start-scenario.sh --base-url http://localhost:3035 \
  --domain ONDC:FIS12 --version 2.3.0 --usecase "BUSINESS LOAN" \
  --flow-id "?" --subscriber-url https://my-np.example.com --dry-run

# Reset to the tested submodule baseline
git submodule update --init --force

# Full teardown including data volumes
docker compose -f docker-compose.yml -f docker-compose.api.yml down -v
```

**Gitignored, safe to delete and regenerate:** `api-service/`, `api-services/`,
`docker-compose.api.yml`. Remove a side-by-side branch with
`git -C api-service worktree remove api-services/<branch>`.

**Tracked, and modified by tooling:** `.env` (rewritten by `build-api-service.sh`).
