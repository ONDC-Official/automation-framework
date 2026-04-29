# Security Policy

## Supported Versions

We actively maintain the latest version of Protocol Workbench on the `main` branch. Security fixes are applied to `main` only.

| Version | Supported |
|---|---|
| `main` (latest) | ✅ |
| Older releases | ❌ — upgrade to latest |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

If you discover a security issue — including vulnerabilities in validation logic, authentication bypass, injection risks, or dependency vulnerabilities — please report it privately so we can fix it before public disclosure.

### How to report

Email **PW-support@ondc.org** with the subject line: `[SECURITY] <brief description>`

Include:
- A description of the vulnerability and its potential impact
- Steps to reproduce or a proof-of-concept (where applicable)
- The affected service(s) and version
- Your name/handle for acknowledgment (optional)

### What to expect

- **Acknowledgment within 2 business days**
- **Initial assessment within 5 business days**
- We will keep you informed of progress
- We will credit you in the fix's release notes (unless you prefer to remain anonymous)
- We ask for a **90-day coordinated disclosure window** from the date of the initial report before public disclosure

## Scope

The following are in scope for security reports:

- All services in this monorepo
- Generated code artifacts (Go `validationpkg/`, TypeScript validators)
- Authentication and session management in `automation-backoffice`
- Signature validation logic in `automation-beckn-onix`
- HTML sanitization in `automation-mock-playground-service` (HTML_FORM handling)

The following are out of scope:

- Vulnerabilities in third-party dependencies that have already been publicly disclosed (open a regular issue linking to the CVE instead)
- Denial-of-service via resource exhaustion in a self-hosted setup
- Issues that require physical access to the host machine

## Dependency Vulnerabilities

We run `npm audit` and `go mod` audits in CI. If you find a dependency with a known CVE that has not yet been patched, open a regular GitHub issue referencing the CVE number.
