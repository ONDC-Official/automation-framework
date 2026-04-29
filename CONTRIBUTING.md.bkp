# Contributing to ONDC Protocol Workbench

Thank you for taking the time to contribute. Protocol Workbench is an open ONDC project — contributions from network participants, developers, and the broader Beckn community are what keep it useful.

This guide covers everything you need to know to raise a good PR.

---

## Table of Contents

- [Ways to Contribute](#ways-to-contribute)
- [Before You Start](#before-you-start)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Making Changes](#making-changes)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Contribution Areas](#contribution-areas)
- [Code Standards](#code-standards)
- [Getting Help](#getting-help)

---

## Ways to Contribute

You don't have to write code to contribute:

| Type | How |
|---|---|
| Report a bug | [Open a bug report](https://github.com/ONDC-Official/automation-framework/issues/new?template=bug_report.yml) |
| Request a feature | [Open a feature request](https://github.com/ONDC-Official/automation-framework/issues/new?template=feature_request.yml) |
| Request a new ONDC domain | [Open a domain spec request](https://github.com/ONDC-Official/automation-framework/issues/new?template=domain_request.yml) |
| Improve documentation | Edit any `*.md` file and open a PR |
| Add a domain validator | See [Adding a Domain Validator](#adding-a-domain-validator) |
| Fix a bug | Comment on the issue to claim it, then open a PR |
| Review a PR | Review open PRs and leave constructive feedback |

---

## Before You Start

1. **Search existing issues first.** Someone may have already raised the same bug or feature request.
2. **For significant changes, open an issue first.** Discuss the approach before writing code — this avoids wasted effort.
3. **One logical change per PR.** A PR that does 3 things is hard to review and hard to revert if one thing breaks.

---

## Development Setup

### Prerequisites

| Tool | Version | Required for |
|---|---|---|
| Node.js | ≥ 18 (≥ 20 for build-tools) | All TypeScript services |
| Go | 1.24+ | `automation-recorder-service`, `automation-beckn-onix` |
| Docker + Docker Compose v2 | Latest | Full stack |
| Git | Any recent | Submodule support |

### 1. Fork and clone

```bash
# Fork first on GitHub, then:
git clone https://github.com/<your-username>/automation-framework.git
cd automation-framework
git remote add upstream https://github.com/ONDC-Official/automation-framework.git
```

### 2. Initialise submodules

```bash
git submodule update --init --recursive
```

### 3. Install and build shared packages

The shared packages (`automation-logger`, `automation-mock-runner`, `automation-validation-compiler`, `automation-utils/build-tools`) must be compiled before any service can run. They depend on each other in a specific order.

```bash
npm run setup
# This runs: npm install --ignore-scripts && npm run build:packages
```

### 4. Configure environment

Copy the example env files for the services you are working on:

```bash
# Root-level services
cp docker-env/example.env docker-env/api-service.env
# (or copy .env.example from each service directory)
```

See `LOCAL_SETUP.md` for the complete environment setup guide.

### 5. Run the service you are working on

```bash
# Example: working on automation-report-service
cd automation-report-service
npm run dev
```

Or bring up the full stack:

```bash
./start.sh
```

---

## Project Structure

```
automation-framework/
├── automation-logger/          shared npm: @ondc/automation-logger
├── automation-mock-runner/     shared npm: @ondc/automation-mock-runner
├── automation-validation-compiler/  shared npm: ondc-code-generator
├── automation-utils/build-tools/    shared npm: @ondc/build-tools (CLI: ondc-tools)
├── automation-cache/           README only — ondc-automation-cache-lib from npm
│
├── automation-frontend/        React UI (frontend/) + Express BFF (backend/)
├── automation-backoffice/      Admin UI (frontend/) + Express backend (backend/)
├── automation-report-service/  Validation report engine
├── automation-db/              MongoDB + YugabyteDB persistence service
│
├── automation-api-service-generator/  Build-time Go code generator
├── automation-beckn-onix/      Go HTTP server + 9 plugins (protocol enforcer)
│
├── automation-config-service/  Central runtime config hub
├── automation-form-service/    HTML form renderer
├── automation-mock-playground-service/  Mock NP simulator
├── automation-recorder-service/  Go gRPC audit writer
│
└── automation-specifications/  YAML domain specs (submodule, separate repo)
```

For a deeper explanation of how these fit together, read `ARCHITECTURE.md`.

---

## Making Changes

### Shared packages

If you change a shared package (`automation-logger`, `automation-mock-runner`, etc.), rebuild it before testing the consuming service:

```bash
npm run build -w automation-logger
# Then restart the consuming service
```

### Domain validators (automation-report-service)

Validators live at `src/validations/<domain>/<version>/`. Each file exports a validator function. Tests use Mocha:

```bash
cd automation-report-service
npm test
```

### Adding a domain validator

1. Create `src/validations/ONDC:<DOMAIN>/<VERSION>/index.ts`
2. Export the five-step validator chain: `contextValidator → baseValidator → commonValidations → domainValidator → formValidations`
3. Register the domain in `src/controllers/reportController.ts`
4. Add Mocha tests alongside the validator file
5. Update `ALL_Readme/automation-report-service.md` to list the new domain

### Generated files

Files under `*/generated/` and `automation-api-service-generator/build-output/` are machine-generated. **Do not edit them by hand.** Run the generator instead:

```bash
# For TypeScript generated files (action selectors, L2 validators):
npm run build -w automation-validation-compiler
cd automation-api-service-generator && node dist/index.js

# For Go validationpkg/:
npm run build:generator && npm run build:onix
```

### Go services (`automation-recorder-service`, `automation-beckn-onix`)

```bash
go test ./...   # tests use miniredis — no external Redis needed
go build ./...
```

---

## Submitting a Pull Request

1. **Create a branch from `main`** — never commit directly to `main`.
   ```bash
   git checkout -b fix/trv11-select-validation
   # or: feat/add-fis14-validator, docs/update-setup-guide
   ```

2. **Write your changes.** Keep commits focused — one commit per logical unit of change.

3. **Run tests locally** before opening a PR:
   ```bash
   # TypeScript services
   npm test --if-present -w automation-report-service
   npm run lint --if-present -w automation-mock-playground-service

   # Go services
   cd automation-recorder-service && go test ./...
   ```

4. **Push your branch and open a PR** against `main`.

5. **Fill in the PR template** completely — reviewers will ask for missing information.

6. **Respond to review comments.** PRs are reviewed within a few business days.

### PR naming convention

```
<type>(<scope>): <short description>

type:   fix | feat | docs | refactor | test | chore | ci
scope:  report-service | mock-runner | recorder | beckn-onix | config-service | ...

Examples:
  fix(report-service): correct TRV11 fulfillment type validation
  feat(mock-runner): add conditional step support for FIS14
  docs(setup): fix broken docker-compose step in LOCAL_SETUP.md
```

---

## Contribution Areas

### High-impact, good for first-time contributors

- **Domain validators** — adding or improving validators in `automation-report-service/src/validations/`
- **Documentation fixes** — typos, outdated commands, broken links in any `*.md` file
- **`.env.example` files** — services that are missing them
- **Test coverage** — adding Mocha/Jest tests for existing validator logic

### For experienced contributors

- **New mock YAML templates** — adding ONDC domain configs in `automation-config-service/src/config/`
- **Go plugin improvements** — changes to the 9 beckn-onix plugins
- **CI workflow improvements** — `.github/workflows/`
- **Build pipeline** — `automation-api-service-generator`, `automation-validation-compiler`

### ONDC domain experts

- **Spec corrections** — raise issues or PRs against `automation-specifications` (separate repo)
- **Validation rule review** — review PRs touching `x-validations.yaml` files and L1 validator generation

---

## Code Standards

### TypeScript

- TypeScript 5.x strict mode — all new files must have `strict: true`
- No `any` types unless absolutely unavoidable (add a comment explaining why)
- No comments that describe *what* the code does — only *why* (non-obvious constraints, workarounds)
- Run `npm run lint` before committing

### Go

- `gofmt` formatted — run `gofmt -w .` before committing
- `go vet ./...` must pass
- Table-driven tests preferred
- No external dependencies added without discussion in an issue first

### General

- No committed `.env` files or secrets — use `.env.example` with placeholder values
- Generated files are not hand-edited — regenerate from source
- Backward-incompatible changes to shared packages need a major version bump and migration notes

---

## Getting Help

- **GitHub Issues** — bugs, features, domain requests
- **GitHub Discussions** — questions, ideas, implementation discussions
- **Email** — PW-support@ondc.org for anything that doesn't fit above

If you are unsure whether something is a good contribution, open a Discussion first. We'd rather have a conversation than have you spend time on something that won't merge.
