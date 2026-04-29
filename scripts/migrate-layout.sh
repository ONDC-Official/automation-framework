#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# One-shot migration from legacy {services,packages,tools,specs}/* layout to
# the strict prompts.md layout under {specs,services,libs}/automation-<repo>/.
#
# Run this ONCE on a clean working tree. It will:
#   1. git mv each submodule to its new path
#   2. swap .gitmodules → gitmodules.new (the file shipped by Phase 1.1)
#   3. git submodule sync && update --init --recursive
#   4. tidy stale submodule names in .git/modules/
#
# Idempotent: re-running after a successful migration is a no-op.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."
ROOT="$(pwd)"

[ -f .gitmodules ] || { echo "ERROR: not a workbench root" >&2; exit 1; }

# Ensure clean tree (untracked files are fine; staged/unstaged changes are not)
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  echo "ERROR: working tree has uncommitted changes. Commit or stash first." >&2
  exit 1
fi

# Old → New path mappings
# Format: "old_path|new_path"
MAPPINGS=(
  "specs|specs/automation-specifications"
  "services/db|services/automation-db"
  "services/frontend|services/automation-frontend"
  "services/backoffice|services/automation-backoffice"
  "services/report|services/automation-report-service"
  "services/config|services/automation-config-service"
  "services/form|services/automation-form-service"
  "services/mock-playground|services/automation-mock-playground-service"
  "services/recorder|services/automation-recorder-service"
  "packages/cache|libs/automation-cache"
  "packages/logger|libs/automation-logger-package"
  "packages/mock-runner|libs/automation-mock-runner-lib"
  "packages/validation-compiler|libs/automation-validation-compiler"
  "packages/utils|libs/automation-utils"
  "tools/api-service-generator|libs/automation-api-service-generator"
  "tools/beckn-onix|libs/automation-beckn-onix"
)

mkdir -p libs

# Step 1 — Special-case the `specs` rename (cannot move dir into itself)
if [ -d specs ] && [ ! -d specs/automation-specifications ]; then
  echo ">> Renaming specs/ → specs/automation-specifications/ (via tmp)"
  git mv specs _migrate_specs_tmp
  mkdir -p specs
  git mv _migrate_specs_tmp specs/automation-specifications
fi

# Step 2 — Move every other submodule
for mapping in "${MAPPINGS[@]}"; do
  IFS='|' read -r old new <<< "$mapping"
  [ "$old" = "specs" ] && continue                     # already handled
  if [ ! -e "$old" ]; then
    echo "   skip: $old (already moved)"
    continue
  fi
  if [ -e "$new" ]; then
    echo "   skip: $new already exists"
    continue
  fi
  echo ">> $old → $new"
  mkdir -p "$(dirname "$new")"
  git mv "$old" "$new"
done

# Step 3 — Swap in the new .gitmodules
if [ -f gitmodules.new ]; then
  echo ">> Swapping .gitmodules → gitmodules.new"
  mv .gitmodules .gitmodules.preMigration
  mv gitmodules.new .gitmodules
  git add .gitmodules
fi

# Step 4 — Re-sync submodule metadata (the [submodule "<name>"] keys changed)
echo ">> Resyncing submodule metadata"
git submodule sync --recursive
git submodule update --init --recursive

# Step 5 — Optionally rename .git/modules/<old> entries (not strictly required —
# git tolerates stale entries, but cleanliness matters). Uncomment to enable:
#
# rm -rf .git/modules/{specs,services/db,services/frontend,services/backoffice,services/report,services/config,services/form,services/mock-playground,services/recorder,packages,tools,automation-db,automation-frontend,automation-backoffice,automation-report-service,automation-cache,automation-logger,automation-mock-runner,automation-validation-compiler,automation-utils,automation-api-service-generator,automation-beckn-onix}
# git submodule update --init --recursive

# Step 6 — Remove the temporary placeholder workflow if still present
[ -f .github/workflows/test.yml ] && rm -f .github/workflows/test.yml || true

echo
echo "Migration complete. Review with:"
echo "  git status"
echo "  git diff --stat"
echo
echo "Then commit:"
echo "  git add ."
echo "  git commit -m \"feat: migrate to strict prompts.md layout (services/+libs/)\""
