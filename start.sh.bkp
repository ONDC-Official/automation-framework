#!/bin/bash
set -e

# ── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; exit 1; }

# ── parse flags ───────────────────────────────────────────────────────────────
REBUILD=false
DETACH=false
for arg in "$@"; do
  case $arg in
    --rebuild|-r) REBUILD=true ;;
    --detach|-d)  DETACH=true  ;;
    --help|-h)
      echo ""
      echo -e "${BOLD}Usage:${RESET} ./start.sh [options]"
      echo ""
      echo "  (no flags)   Start all services (build only changed layers)"
      echo "  --rebuild    Force a full rebuild of all Docker images"
      echo "  --detach     Run in background (detached mode)"
      echo "  --help       Show this help"
      echo ""
      exit 0
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║        Protocol Workbench — ONDC         ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ── 1. Check Docker is running ────────────────────────────────────────────────
info "Checking Docker..."
docker info > /dev/null 2>&1 || error "Docker is not running. Please start Docker Desktop and try again."
success "Docker is running."

# ── 2. Check docker compose ───────────────────────────────────────────────────
if docker compose version > /dev/null 2>&1; then
  COMPOSE="docker compose"
elif docker-compose version > /dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  error "docker compose / docker-compose not found. Please install Docker Compose."
fi
success "Docker Compose found."

# ── 3. Init submodules ────────────────────────────────────────────────────────
info "Checking git submodules..."
if git submodule status | grep -q '^-'; then
  info "Initialising missing submodules..."
  git submodule update --init --recursive
  success "Submodules initialised."
else
  success "All submodules present."
fi

# ── 4. Verify required env files ─────────────────────────────────────────────
info "Checking env files in docker-env/..."
REQUIRED_ENVS=(
  "docker-env/api-service.env"
  "docker-env/mock-service.env"
  "docker-env/report-service.env"
  "docker-env/automation-backend.env"
  "docker-env/back-office.backend.env"
  "docker-env/automation-db.env"
  "services/frontend/frontend/docker.env"
)
MISSING=false
for f in "${REQUIRED_ENVS[@]}"; do
  if [[ ! -f "$f" ]]; then
    warn "Missing: $f"
    MISSING=true
  fi
done
if $MISSING; then
  error "One or more env files are missing. Check docker-env/ and automation-frontend/frontend/docker.env."
fi
success "All env files present."

# ── 5. Build & start ──────────────────────────────────────────────────────────
COMPOSE_ARGS=""
if $REBUILD; then
  COMPOSE_ARGS="--build --force-recreate"
  info "Starting all services (full rebuild)..."
else
  COMPOSE_ARGS="--build"
  info "Starting all services (incremental build)..."
fi
if $DETACH; then
  COMPOSE_ARGS="$COMPOSE_ARGS -d"
fi

echo ""
$COMPOSE up $COMPOSE_ARGS

# ── 6. Print URLs (only when detached) ───────────────────────────────────────
if $DETACH; then
  echo ""
  echo -e "${BOLD}Services are running:${RESET}"
  echo -e "  ${GREEN}Automation UI${RESET}       →  http://localhost:3035"
  echo -e "  ${GREEN}Backoffice UI${RESET}       →  http://localhost:5100/backoffice-frontend"
  echo -e "  ${GREEN}Config Service${RESET}      →  http://localhost:5556"
  echo -e "  ${GREEN}Mock Playground${RESET}     →  http://localhost:3031"
  echo -e "  ${GREEN}Report Service${RESET}      →  http://localhost:3000"
  echo -e "  ${GREEN}DB Service${RESET}          →  http://localhost:8080"
  echo -e "  ${GREEN}YugabyteDB UI${RESET}       →  http://localhost:7001"
  echo ""
  echo -e "  Run ${CYAN}docker compose logs -f${RESET} to follow logs."
  echo -e "  Run ${CYAN}docker compose down${RESET} to stop."
  echo ""
fi
