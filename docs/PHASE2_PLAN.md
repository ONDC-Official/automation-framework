# Phase 2 Plan — CI/CD, Developer Experience & Open-Source Hardening

**Status:** Awaiting team lead review and approval  
**Prepared by:** Arun Yadav  
**Prerequisite:** Phase A (path restructure) merged ✅  
**Estimated effort:** 3–5 days  

---

## What Phase 1 (Phase A) Did

- Reorganised all 16 git submodules from a flat `automation-*` root layout into
  `packages/ / services/ / tools/ / specs/`
- Updated `docker-compose.yml`, `start.sh`, `package.json` workspaces to reflect new paths
- Added open-source scaffolding: `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `SECURITY.md`, PR/issue templates, `.gitignore`, per-service docs under `docs/services/`
- **Zero code changed in any submodule repo; all original CI pipelines untouched**

---

## What Phase 2 Will Do

Phase 2 has three independent tracks that can be reviewed and merged separately.

---

### Track 1 — Docker Compose: Add the 4 Missing Services

**Problem:** `services/config`, `services/form`, `services/mock-playground`, and
`services/recorder` were registered as submodules in Phase A but are **not yet in
`docker-compose.yml`**. Running `./start.sh` today does not start them.

**Change:** Add four new service blocks to `docker-compose.yml`:

| Service block | Host port | Image build context | Env file |
|---|---|---|---|
| `automation-config-service` | `5556` | `./services/config` | `docker-env/config-service.env` |
| `automation-form-service` | `5557` | `./services/form` | `docker-env/form-service.env` |
| `automation-mock-playground` | `3031` | `./services/mock-playground` | `docker-env/mock-playground.env` |
| `automation-recorder` | `8089 / 8090` | `./services/recorder` | `docker-env/recorder.env` |

**Also:** Add the four new env files to the `REQUIRED_ENVS` check in `start.sh`.

**Risk:** Low. Additive only. Existing services are untouched.  
**Rollback:** Remove the four blocks from `docker-compose.yml`.

---

### Track 2 — Developer Experience: `.env.example` Files + docker-env Templates

**Problem:** A new contributor cloning this repo cannot run `./start.sh` because all
`docker-env/*.env` files are git-ignored (they contain secrets). There are no
`.env.example` files to show what variables are required.

**Change:** Create two types of example files in `docker-env/`:

```
docker-env/
  api-service.env.example
  automation-backend.env.example
  automation-db.env.example
  back-office.backend.env.example
  mock-service.env.example
  report-service.env.example
  config-service.env.example        ← new (Track 1)
  form-service.env.example          ← new (Track 1)
  mock-playground.env.example       ← new (Track 1)
  recorder.env.example              ← new (Track 1)
```

Each file will:
- List every required variable with a placeholder value (e.g., `DB_PASSWORD=changeme`)
- Include a comment above each variable explaining what it is
- Never contain any real credentials

Also update `LOCAL_SETUP.md` (now at `docs/local-setup.md`) with a `cp` command to
bootstrap env files:
```bash
for f in docker-env/*.env.example; do cp "$f" "${f%.example}"; done
```

**Also:** `services/config` is missing `.env.example` inside the submodule itself —
raise a PR to `automation-config-service` repo to add it (out of scope for this
repo's PR, tracked separately).

**Risk:** Zero. No code changes; documentation and example files only.  
**Rollback:** N/A — no functional impact.

---

### Track 3 — GitHub Actions CI Workflows

**Problem:** There are currently no automated CI checks on this (framework) repo.
Each submodule has its own CI in its own repo, but no workflow guards the
framework-level things: does `docker-compose.yml` parse correctly, do the
`package.json` workspaces resolve, do the docs build?

**Proposed workflows** (all in `.github/workflows/`):

#### 3a. `ci-compose-validate.yml` — Validate docker-compose on every PR
```
Trigger: pull_request (paths: docker-compose.yml, docker-env/**, start.sh)
Steps:
  1. Checkout with submodules: false   (fast — no need to clone sub-repos)
  2. docker compose config             (validates YAML syntax + env references)
  3. bash -n start.sh                  (syntax check the start script)
```
**Why `submodules: false`:** We only need to validate the compose file structure,
not actually build images. Avoids cloning 16 repos on every PR.

#### 3b. `ci-npm-workspaces.yml` — Validate npm workspace graph on every PR
```
Trigger: pull_request (paths: package.json, packages/**/package.json)
Steps:
  1. Checkout with submodules: recursive
  2. npm install --ignore-scripts
  3. npm run build:packages
```

#### 3c. `ci-submodule-sync.yml` — Warn when a submodule drifts behind its remote
```
Trigger: schedule (weekly, Monday 09:00 UTC)
Steps:
  1. git submodule update --remote --dry-run
  2. If any submodule is behind: open a GitHub Issue (or post a comment)
     listing which ones need updating
```
This replaces the manual task of checking whether sub-repos have released
new commits that the framework repo hasn't pinned yet.

**Risk:** Low. Workflows run in GitHub Actions sandboxes; they cannot modify
any submodule repo. Worst case a workflow fails noisily — no production impact.  
**Rollback:** Delete the workflow files.

---

## What Phase 2 Does NOT Do

| Out of scope | Reason |
|---|---|
| Modify any submodule repo's code | Each sub-repo owns its own CI and codebase |
| Change any service's port or env variable name | Breaking change — separate RFC |
| Inline submodule code into the framework repo (Phase B) | Requires team agreement on ownership model |
| Add Changesets / npm publish automation | Packages are not yet published to npm registry |
| Kubernetes / Helm / ArgoCD manifests | Separate infra repo concern |

---

## Risk Summary

| Track | Risk level | Reversible? | Affects running setup? |
|---|---|---|---|
| 1 — Add missing services to compose | Low | Yes — remove 4 blocks | No (additive) |
| 2 — `.env.example` files | Zero | N/A | No |
| 3 — GitHub Actions workflows | Low | Yes — delete yml files | No (sandbox only) |

---

## Validation Checklist (before merging)

- [ ] `docker compose config` passes with no errors after Track 1 changes
- [ ] `./start.sh --help` shows no errors
- [ ] `npm install && npm run build:packages` succeeds from repo root
- [ ] All 16 `git submodule status` entries show clean (no `-` prefix)
- [ ] CI workflows appear in GitHub Actions tab and trigger correctly on a test PR
- [ ] A new contributor can follow `docs/local-setup.md` to bootstrap env files
      and run `./start.sh` without additional guidance

---

## Files That Will Change in Phase 2

```
docker-compose.yml                  ← Track 1: 4 new service blocks
start.sh                            ← Track 1: 4 new env file checks
docker-env/*.env.example (×10)      ← Track 2: new example files
docs/local-setup.md                 ← Track 2: bootstrap instructions updated
.github/workflows/
  ci-compose-validate.yml           ← Track 3a
  ci-npm-workspaces.yml             ← Track 3b
  ci-submodule-sync.yml             ← Track 3c
```

No submodule repository will be modified. No production deployment will be affected.

---

## Open Questions for Team Lead

1. **docker-env secrets** — Are the current `docker-env/*.env` files already in
   `.gitignore`? (They are.) Should we add a pre-commit hook that blocks accidental
   commit of real env files, or is the gitignore sufficient?

2. **CI runner** — Does the org have self-hosted GitHub Actions runners for the
   `ci-npm-workspaces.yml` job (submodule checkout can be slow on large repos),
   or should we use `ubuntu-latest` with caching?

3. **Submodule update cadence** — The weekly drift-check workflow (3c) will open
   GitHub Issues automatically. Who should be assigned/notified?

4. **Phase B decision** — When is the right time to evaluate inlining submodule
   code directly into this repo? This removes the two-repo contributor friction
   but requires a one-time migration agreement with each sub-repo team.
