## Summary

<!-- Brief description of what this PR does. Link the related issue if any. -->

## Type

- [ ] Submodule update (auto-bump)
- [ ] Documentation change
- [ ] Local-dev tooling (docker-compose, scripts, .env.example)
- [ ] CI/CD workflow change
- [ ] Architecture / ADR
- [ ] Other: ___

## Affected components

<!-- Check all that apply -->
- [ ] `specs/automation-specifications`
- [ ] `services/automation-frontend`
- [ ] `services/automation-backoffice`
- [ ] `services/automation-config-service`
- [ ] `services/automation-db`
- [ ] `services/automation-form-service`
- [ ] `services/automation-recorder-service`
- [ ] `services/automation-report-service`
- [ ] `services/automation-mock-playground-service`
- [ ] `libs/automation-beckn-onix`
- [ ] `libs/automation-mock-runner-lib`
- [ ] `libs/automation-validation-compiler`
- [ ] `libs/automation-utils`
- [ ] `libs/automation-cache`
- [ ] `libs/automation-logger-package`
- [ ] `libs/automation-api-service-generator`
- [ ] Cross-cutting / parent-repo only

## Related issue

Closes #<!-- issue number -->

## How was this tested?

<!-- Describe how you verified the change works. What did you run? -->

- [ ] `cd local-dev && docker compose up` builds and boots cleanly
- [ ] `./scripts/health-check.sh` passes
- [ ] If submodule pointer moved: downstream `notify-parent.yml` payload was verified

## Checklist

- [ ] No `.env` files or secrets committed
- [ ] No hardcoded internal URLs or credentials introduced
- [ ] Documentation updated (README / ARCHITECTURE / SELF-HOSTING / ADR) if behavior changed
- [ ] If a new submodule was added: present in `.gitmodules`, `local-dev/docker-compose.yml`, `clone-all.sh`, `health-check.sh`
- [ ] If a new ONDC domain was added: listed in `docs/adding-a-new-domain.md` and the architecture matrix

## Screenshots / logs (if relevant)

<!-- Attach screenshots of UI changes, or paste relevant log output for bug fixes -->
