#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Pull the latest commit on each submodule's tracked branch and report status.
# Run from the workbench root.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

[ -f .gitmodules ] || { echo "ERROR: not a workbench root (no .gitmodules)" >&2; exit 1; }

echo "Updating all submodules to latest remote…"
git submodule update --init --recursive --remote

echo
echo "=== Current submodule status ==="
git submodule foreach --quiet '
  echo "  $name: $(git rev-parse --short HEAD) ($(git log -1 --format=%s | cut -c1-72))"
'

echo
echo "Run 'git diff' to see what changed."
echo "Commit with: git add . && git commit -m \"chore: update submodules\""
