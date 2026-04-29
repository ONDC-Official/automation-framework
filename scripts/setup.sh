#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# ONDC Automation Workbench — first-time setup
# Initialises submodules, sets up the local-dev .env, and prints next steps.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

# Resolve repo root regardless of where the script is invoked from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

info "ONDC Automation Workbench — Setup"
echo

# Prerequisites
command -v git >/dev/null 2>&1     || error "git is required"
command -v docker >/dev/null 2>&1  || error "docker is required"
docker compose version >/dev/null 2>&1 || error "docker compose v2 plugin is required"
[ -f .gitmodules ] || error "Run this script from the workbench root (no .gitmodules found)"

info "Initialising submodules (this may take a few minutes the first time)…"
git submodule update --init --recursive
success "Submodules initialised"

info "Aligning each submodule with its tracked branch…"
git submodule foreach --quiet '
  branch=$(git config -f $toplevel/.gitmodules submodule.$name.branch || echo main)
  echo "  $name → $branch"
  git fetch origin "$branch" --quiet || true
  git checkout "$branch" --quiet || true
  git pull --ff-only --quiet || true
'
success "Submodules aligned"

# Local dev env file
if [ ! -f local-dev/.env ]; then
  cp local-dev/.env.example local-dev/.env
  success "Created local-dev/.env from template (review and adjust if needed)"
else
  warn "local-dev/.env already exists — skipped"
fi

echo
success "Setup complete!"
cat <<'EOF'

Next steps:
  cd local-dev
  docker compose up                                     # build from source
  docker compose -f docker-compose.images.yml up -d     # use published images
  ../scripts/health-check.sh                            # verify services

The workbench will be available at http://localhost:3000
EOF
