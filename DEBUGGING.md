# Debugging Guide

Debug setup for all four target types in Protocol Workbench. Companion to
[`LOCAL_SETUP.md`](./LOCAL_SETUP.md).

Open the workspace first — the launch configs assume it:

```bash
code automation-framework.code-workspace
```

---

## The model

**The Docker stack is your infrastructure.** To debug one service, stop its container
and run it natively. Every launch config binds the **same host port its container
published**, so the rest of the stack keeps working without reconfiguration.

```bash
docker compose stop <service>     # before debugging
docker compose start <service>    # when you're done
```

`.vscode/tasks.json` has *stack: stop one service* / *start one service* tasks with a
service picker, so you can do this from the command palette instead.

Config comes from a `.env.local` in each repo — container DNS names rewritten to
`localhost` host ports. These are ignored via each submodule's `.git/info/exclude`,
so **your submodule trees stay clean and nothing needs committing.**

---

## What's installed

| Piece | Location |
|---|---|
| Launch configs (15) | `.vscode/launch.json` |
| Tasks (Vite servers, stack control) | `.vscode/tasks.json` |
| Multi-root workspace | `automation-framework.code-workspace` |
| Per-service env | `<repo>/.env.local` × 10 |
| Container `--inspect` overlay | `docker-compose.debug.yml` |
| ONIX Delve image | `dockerfiles/api-service-debug.Dockerfile` |
| ONIX Delve driver | `scripts/debug-api-service.sh` |

Required extensions (recommended automatically by the workspace): **Go** (`golang.go`),
**ESLint**, **Prettier**, **YAML**, **Docker**.

---

## Target 1 — TypeScript services

Six configs under the **1-services** group. Each runs the service's real entry point
through `ts-node`/`tsx` with `--transpile-only`, so breakpoints sit directly in `.ts`
source with no build step.

| Config | Port | Stop this container first |
|---|---|---|
| `TS: db-service` | 5001 | `db-service` |
| `TS: config-service` | 5556 | `config-service` |
| `TS: mock-playground` | 3031 | `playground-mock-service` |
| `TS: report-service` | 3000 | `report-service` |
| `TS: ui-backend` | 3034 | `ui-backend` |
| `TS: backoffice-backend` | 5200 | `backoffice-backend` |

Two **compounds** run related services together for tracing a request across a boundary:
*Flow: ui-backend + report-service*, and *Flow: ui-backend + config + mock*.

### The one real limitation

A natively-run service loses its Docker DNS name. Anything calling it as
`http://<service>:<port>` **from inside** the network breaks. Impact by service:

| Service | Called in-network by | Safe to run natively? |
|---|---|---|
| `backoffice-backend` | nobody (browser only) | Yes — easiest |
| `ui-backend` | `report-service`, `form-service` | Mostly |
| `report-service`, `config-service`, `mock` | 1–2 services | Usually |
| `db-service` | **5 services** | No — use Target 2 |

For `db-service`, use the container-attach route below.

---

## Target 2 — Node service inside Docker (`--inspect`)

Keeps the service in the Docker network (DNS intact) and exposes an inspector instead.

```bash
docker compose -f docker-compose.yml -f docker-compose.debug.yml up -d db-service
```

Then run **`Attach: Node :9229`**. Revert with
`docker compose -f docker-compose.yml up -d db-service`.

> One service at a time — they all use 9229.

**Caveat:** these images run compiled `dist/`, so breakpoints need source maps.
`automation-db` and `automation-report-service` have `sourceMap` **absent** from their
`tsconfig.json`. Add `"sourceMap": true` and rebuild before their breakpoints will bind
to `.ts`. (The four other services already have it.)

---

## Target 3 — React frontends

| Config | URL |
|---|---|
| `Web: ui-frontend (Chrome :3035)` | http://localhost:3035 |
| `Web: backoffice-frontend (Chrome :5100)` | http://localhost:5100/backoffice/ |

Each has a `preLaunchTask` that starts Vite on the right port, and
`sourceMapPathOverrides` so breakpoints land in your `.tsx` files. Stop the
corresponding container first — Vite needs the port.

Because these run Vite dev rather than the built bundle, you get HMR: edit a component
and the page updates with breakpoints still attached.

---

## Target 4 — Go

### recorder-service (native, easiest Go target)

Three configs: run the service, debug the current test file, or debug all tests. It's
the only codebase here with meaningful tests (7 files), so the test configs are the
fastest way to step through real logic.

```bash
docker compose stop recorder-service     # frees :8090 and :8089
```

### automation-user-management (Go / Fiber — not what the compose file suggests)

Two surprises worth knowing:

1. **It is a Go service, not Node.** The published image contains exactly one file — a
   21 MB compiled binary named `automation-developer-guide`. No Node runtime, no source.
   A Node `--inspect` config is impossible here.
2. **It has no submodule in this repo.** `docker-compose.yml` consumes the prebuilt image
   `ghcr.io/ondc-official/automation-user-management:dev-0.0.0-3567db7`, so there is
   nothing local to set a breakpoint in until you clone the source yourself.

Source is now cloned at `automation-user-management/` (a plain clone, **not** a submodule —
`.gitmodules` is untouched) and checked out on branch `image-pin` at commit **`3567db7`**,
the exact commit the running image was built from. That matters: debugging `main` against
a binary built from an older commit gives mismatched line numbers.

```bash
docker compose stop automation-user-management     # frees :8082
```

Then run **`Go: user-management / developer-guide (:8082)`**. Verified working — it
connects to the Dockerized Mongo at `localhost:27017` and serves Fiber v2.52.11 with 28
handlers.

Useful breakpoints:

| File | Why |
|---|---|
| `src/routes/routes.go` | All 28 route registrations in one place |
| `src/middleware/auth.go` | JWT gate — where unauthenticated requests get their 401 |
| `src/handlers/auth.go` | GitHub OAuth exchange |
| `src/handlers/comments.go`, `notes.go` | The developer-guide content APIs |

`GET /health` returns **401**, not 200 — it sits behind the auth middleware. That's a good
first breakpoint if you want to watch the middleware chain run.

GitHub OAuth login needs real credentials in `.env.local`
(`GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET`); everything else runs without them.

To follow upstream later: `git -C automation-user-management checkout main`. Expect
drift from the running container if you do.

### ONIX api-service plugins (deepest, most setup)

This is where the actual protocol work happens — signing, schema validation, routing,
context validation. The generated service is **Go**, not TypeScript: 13 plugins
(101 Go files) plus a generated `validationpkg` (40 files), loaded into a Beckn-ONIX
server.

The base image is Debian 13, ships Go, **and includes the ONIX server source** — so
both your plugins and the server itself are debuggable.

```bash
./scripts/debug-api-service.sh          # build + start under Delve on :2345
# VS Code -> "Go: attach ONIX api-service (Delve :2345)"
./scripts/debug-api-service.sh --off    # revert
```

The debug image compiles plugins with `-gcflags "all=-N -l"` (no optimisation, no
inlining) — without that, Delve reports "optimized out" for most locals. The server is
rebuilt with matching flags, since Go plugins require build consistency with their host
binary. Delve is pinned to **v1.27.2** to match your local install; if you upgrade
locally, bump it in `dockerfiles/api-service-debug.Dockerfile`.

Set breakpoints in:
- `api-service/build-output/temp/automation-beckn-plugins/` — the 13 plugins
- `api-service/build-output/temp/validationpkg/` — generated validators

With several branches built side by side (`build-api-service.sh A B`), the debugger runs
the first branch's service, from `api-service/`. Put the branch you want to debug first.
For an FD branch the debug image also builds `fdgate` and `fdtransport`; their sources are
`fd-gate/`, `fd-transport/` and `pkg/fdroute`, `pkg/fdsig` in the plugins folder.

> `build-output/` is **wiped on every spec regeneration** (`rm -rf build-output`).
> Breakpoints survive (they're stored by path), but code edits there do not.

---

## Where to put a breakpoint first

The pipeline the ONIX server prints at startup *is* the request lifecycle:

```
ondcWorkbenchReceiver → addRoute → validateSchema →
ondcWorkbenchValidateContext → sign → validateOndcCallSave
```

Suggested first session, to see a request cross the whole system:

1. Start the stack, run **`TS: ui-backend`**, breakpoint in
   `src/controllers/sessionController.ts` → `createSession`.
2. Create a session in the UI at http://localhost:3035. You'll land in the handler and
   can step into the outbound call to `config-service`.
3. Then `./scripts/debug-api-service.sh` and breakpoint in the `ondc-validator` plugin
   to watch the same transaction get validated on the Go side.

Drive flows headlessly instead of clicking, when you want a repeatable trigger:

```bash
./scripts/flow-automation/start-scenario.sh \
  --base-url http://localhost:3035 \
  --domain ONDC:FIS12 --version 2.3.0 --usecase "BUSINESS LOAN" \
  --flow-id "?" --subscriber-url https://my-np.example.com --dry-run
```

Pass `?` to any of `--domain` / `--version` / `--usecase` / `--flow-id` and the error
lists the valid values.

---

## Jaeger first, debugger second

http://localhost:16686 already traces `ui-backend`, `db-service`, `backoffice-backend`,
and `report-service`. For "which service failed and why", a trace is faster than a
breakpoint. Use the debugger once you know *where* to look.

---

## Troubleshooting

**`EADDRINUSE`** — the container is still running. `docker compose stop <service>`.

**Breakpoint is a hollow circle (unbound)** — you're attached to compiled `dist/`
without source maps. See the caveat in Target 2.

**Service starts then exits immediately** — usually Redis or Mongo. Confirm
`docker compose ps` shows them up; `.env.local` points at `localhost:6379` / `localhost:27017`,
which only resolve while those containers run.

**Calls to `http://registry-service:8080` fail** — expected. That service does not exist
in `docker-compose.yml` at all; see `LOCAL_SETUP.md` §4.1.

**A 500 from `ui-backend`** — often a 4xx from something behind it. Check its log for the
real status before assuming a crash (`LOCAL_SETUP.md` §4.9).

**`dlv` not found in a terminal** — it's at `~/go/bin/dlv`, which is not on your shell
`PATH`. VS Code's Go extension finds it regardless. For terminal use:
`export PATH="$PATH:$(go env GOPATH)/bin"`.

**Go plugin symbols missing on attach** — the debug image wasn't rebuilt. Re-run
`./scripts/debug-api-service.sh`; it forces `--build`.
