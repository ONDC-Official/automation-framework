#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Apply the standard label set to every ONDC-Official automation repo.
# Requires: `gh` CLI authenticated with admin permissions on the org repos.
# ──────────────────────────────────────────────────────────────────────────────
set -uo pipefail

ORG="ONDC-Official"

REPOS=(
  automation-framework
  automation-specifications
  automation-frontend
  automation-backoffice
  automation-config-service
  automation-db
  automation-form-service
  automation-recorder-service
  automation-report-service
  automation-mock-playground-service
  automation-cache
  automation-logger-package
  automation-mock-runner-lib
  automation-validation-compiler
  automation-utils
  automation-api-service-generator
  automation-beckn-onix
)

# Format: name|color|description
LABELS=(
  "tier/specification|5319e7|Tier 1 — Specification and content"
  "tier/platform-service|0075ca|Tier 2 — Platform service"
  "tier/build-tooling|e4592d|Tier 3 — Library or build tool"
  "priority/critical|b60205|Requires immediate attention"
  "priority/high|d93f0b|Should be addressed soon"
  "priority/medium|fbca04|Normal priority"
  "priority/low|0e8a16|Nice to have"
  "type/bug|d73a4a|Something isn't working"
  "type/feature|a2eeef|New feature or enhancement"
  "type/docs|0075ca|Documentation improvement"
  "type/ci|e4e669|CI/CD pipeline change"
  "type/security|b60205|Security issue or improvement"
  "type/question|cc317c|Question or clarification needed"
  "status/needs-triage|ededed|Needs initial review"
  "good-first-issue|7057ff|Good for newcomers"
  "help-wanted|008672|Extra attention needed"
  "auto-bump|c2e0c6|Automated submodule update"
  "auto-sync|c2e0c6|Automated weekly sync"
  "submodule-update|c2e0c6|Submodule pointer change"
  "domain/FIS|fbca04|Financial Services domain"
  "domain/TRV|fbca04|Travel domain"
  "domain/RET|fbca04|Retail domain"
  "domain/logistics|fbca04|Logistics domain"
)

command -v gh >/dev/null 2>&1 || { echo "ERROR: gh CLI is required" >&2; exit 1; }

for repo in "${REPOS[@]}"; do
  echo "=== ${ORG}/${repo} ==="
  for label_def in "${LABELS[@]}"; do
    IFS='|' read -r name color desc <<< "$label_def"
    if gh label create "$name" --repo "${ORG}/${repo}" --color "$color" --description "$desc" --force 2>/dev/null; then
      echo "  + $name"
    else
      echo "  ~ $name (skip — repo missing or no permission)"
    fi
  done
done
