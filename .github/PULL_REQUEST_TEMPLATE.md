## What does this PR do?

<!-- One clear sentence. What problem does it solve or what does it add? -->

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that changes existing behavior)
- [ ] Documentation update
- [ ] Refactor (no behavior change, code quality improvement)
- [ ] CI / tooling change

## Affected service(s)

<!-- Check all that apply -->
- [ ] `automation-report-service`
- [ ] `automation-mock-playground-service`
- [ ] `automation-recorder-service`
- [ ] `automation-beckn-onix`
- [ ] `automation-config-service`
- [ ] `automation-db`
- [ ] `automation-form-service`
- [ ] `automation-frontend`
- [ ] `automation-backoffice`
- [ ] `automation-logger` (shared package)
- [ ] `automation-mock-runner` (shared package)
- [ ] `automation-validation-compiler` (shared package)
- [ ] `automation-utils/build-tools` (shared package)
- [ ] `automation-api-service-generator`
- [ ] Other: ___________

## Related issue

Closes #<!-- issue number -->

## How was this tested?

<!-- Describe how you verified the change works. What did you run? -->

- [ ] Unit tests pass (`npm test` / `go test ./...`)
- [ ] Lint passes (`npm run lint`)
- [ ] Type check passes (`npm run type-check` / `tsc --noEmit`)
- [ ] Tested end-to-end locally against the full stack
- [ ] If shared package changed: rebuilt with `npm run build -w <package>` and verified consumers

## Checklist

- [ ] No `.env` files or secrets committed
- [ ] No hand-edited generated files (files under `*/generated/` or `build-output/`)
- [ ] If shared package changed: downstream consumers still build and pass tests
- [ ] Documentation updated if behavior changed (service README in `ALL_Readme/`, `ARCHITECTURE.md`, `LOCAL_SETUP.md`)
- [ ] If new ONDC domain added: domain listed in `automation-report-service` README

## Screenshots / logs (if relevant)

<!-- Attach screenshots of UI changes, or paste relevant log output for bug fixes -->
