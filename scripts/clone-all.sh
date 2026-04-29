#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Clone all ONDC automation repos into the current directory as standalone
# clones (NOT as submodules). Useful for contributors who want flat layouts.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ORG="https://github.com/ONDC-Official"

REPOS=(
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

echo "Cloning ${#REPOS[@]} repos from ${ORG}…"
fail=0
for repo in "${REPOS[@]}"; do
  if [ -d "$repo" ]; then
    echo "  SKIP: $repo (already exists)"
  elif git clone --quiet "${ORG}/${repo}.git" "$repo"; then
    echo "  CLONE: $repo"
  else
    echo "  FAIL: $repo"
    fail=$((fail + 1))
  fi
done

echo
if [ "$fail" -eq 0 ]; then
  echo "All ${#REPOS[@]} repos cloned successfully."
else
  echo "${fail} repo(s) failed to clone." >&2
  exit 1
fi
