#!/usr/bin/env bash
#
# setup-local.sh — One-shot local environment setup for the Automation Framework.
#
# What it does:
#   1. Detects your OS and installs missing prerequisites (git, docker, docker compose)
#   2. Ensures the Docker daemon is running
#   3. Initializes git submodules (if needed)
#   4. Fills in local dev secrets that are still placeholders
#   5. Builds frontend images and starts the whole stack
#   6. Health-checks every service and prints a pass/fail summary
#
# Usage:
#   ./setup-local.sh                 # full setup + bring-up + health check
#   ./setup-local.sh --no-install    # skip prerequisite installation
#   ./setup-local.sh --skip-build    # don't rebuild frontends (use existing images)
#   ./setup-local.sh --check-only    # only run the health check against a running stack
#   ./setup-local.sh --down          # stop the stack
#   ./setup-local.sh --domain <spec-branch>   # also build+start a domain API service
#   ./setup-local.sh --help
#
set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DO_INSTALL=1
DO_BUILD=1
CHECK_ONLY=0
DO_DOWN=0
DOMAIN_BRANCH=""

# service_name : host_port : protocol(http|tcp) : path
# protocol "tcp" = just check the port accepts a connection (mongo/redis/grpc).
# protocol "http" = curl the path and accept any HTTP response (200/301/302/401/404 all mean "listening").
SERVICES=(
  "mongo:27017:tcp:/"
  "redis:6379:tcp:/"
  "jaeger:16686:http:/"
  "db-service:5001:http:/"
  "config-service:5556:http:/"
  "playground-mock-service:3031:http:/"
  "recorder-service:8090:http:/"
  "report-pramaan-buyer:3005:http:/"
  "report-pramaan-seller:3006:http:/"
  "report-service:3000:http:/"
  "automation-user-management:8082:http:/"
  "form-service:3300:http:/"
  "backoffice-backend:5200:http:/"
  "backoffice-frontend:5100:http:/backoffice-frontend"
  "ui-backend:3034:http:/"
  "ui-frontend:3035:http:/"
)

# ─────────────────────────────────────────────────────────────────────────────
# Pretty logging
# ─────────────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  C_RST=$'\033[0m'; C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_BLU=$'\033[34m'; C_BLD=$'\033[1m'
else
  C_RST=""; C_RED=""; C_GRN=""; C_YEL=""; C_BLU=""; C_BLD=""
fi
step() { echo; echo "${C_BLU}${C_BLD}==> $*${C_RST}"; }
info() { echo "    ${C_RST}$*"; }
ok()   { echo "    ${C_GRN}✔${C_RST} $*"; }
warn() { echo "    ${C_YEL}⚠${C_RST} $*" >&2; }
err()  { echo "    ${C_RED}x${C_RST} $*" >&2; }
die()  { err "$*"; exit 1; }

usage() {
  cat <<'EOF'
setup-local.sh — One-shot local environment setup for the Automation Framework.

What it does:
  1. Detects your OS and installs missing prerequisites (git, docker, docker compose)
  2. Ensures the Docker daemon is running
  3. Initializes git submodules (if needed)
  4. Fills in local dev secrets that are still placeholders
  5. Builds frontend images and starts the whole stack
  6. Health-checks every service and prints a pass/fail summary

Usage:
  ./setup-local.sh                 # full setup + bring-up + health check
  ./setup-local.sh --no-install    # skip prerequisite installation
  ./setup-local.sh --skip-build    # don't rebuild frontends (use existing images)
  ./setup-local.sh --check-only    # only run the health check against a running stack
  ./setup-local.sh --down          # stop the stack
  ./setup-local.sh --domain <spec-branch>   # also build+start a domain API service
  ./setup-local.sh --help
EOF
  exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Arg parsing
# ─────────────────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --no-install) DO_INSTALL=0 ;;
    --skip-build) DO_BUILD=0 ;;
    --check-only) CHECK_ONLY=1 ;;
    --down)       DO_DOWN=1 ;;
    --domain)     DOMAIN_BRANCH="${2:-}"; shift ;;
    -h|--help)    usage ;;
    *) die "Unknown option: $1 (use --help)" ;;
  esac
  shift
done

command_exists() { command -v "$1" >/dev/null 2>&1; }

# ─────────────────────────────────────────────────────────────────────────────
# OS detection
# ─────────────────────────────────────────────────────────────────────────────
OS=""; DISTRO=""; PKG=""
detect_os() {
  case "$(uname -s)" in
    Darwin) OS="macos"; PKG="brew" ;;
    Linux)
      OS="linux"
      if [ -r /etc/os-release ]; then . /etc/os-release; DISTRO="${ID:-}"; fi
      if command_exists apt-get;   then PKG="apt"
      elif command_exists dnf;     then PKG="dnf"
      elif command_exists yum;     then PKG="yum"
      elif command_exists pacman;  then PKG="pacman"
      elif command_exists zypper;  then PKG="zypper"
      else PKG="unknown"; fi
      ;;
    *) die "Unsupported OS: $(uname -s). Use Docker Desktop manually." ;;
  esac
  info "OS: ${OS}${DISTRO:+ ($DISTRO)}, package manager: ${PKG}"
}

SUDO=""
need_sudo() { [ "$(id -u)" -ne 0 ] && command_exists sudo && SUDO="sudo"; }

# ─────────────────────────────────────────────────────────────────────────────
# Prerequisite installers
# ─────────────────────────────────────────────────────────────────────────────
pkg_install() {
  # pkg_install <pkg...>
  case "$PKG" in
    brew)   brew install "$@" ;;
    apt)    $SUDO apt-get update -qq && $SUDO apt-get install -y "$@" ;;
    dnf)    $SUDO dnf install -y "$@" ;;
    yum)    $SUDO yum install -y "$@" ;;
    pacman) $SUDO pacman -Sy --noconfirm "$@" ;;
    zypper) $SUDO zypper install -y "$@" ;;
    *) return 1 ;;
  esac
}

ensure_brew() {
  command_exists brew && return 0
  warn "Homebrew not found. Installing Homebrew (needed to install Docker on macOS)…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || die "Homebrew install failed. Install it from https://brew.sh and re-run."
  # make brew available in this shell
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [ -x /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"
}

ensure_git() {
  command_exists git && { ok "git present ($(git --version | awk '{print $3}'))"; return; }
  [ "$DO_INSTALL" -eq 1 ] || die "git missing and --no-install set."
  step "Installing git"
  [ "$OS" = "macos" ] && ensure_brew
  pkg_install git || die "Could not install git automatically."
  ok "git installed"
}

ensure_docker() {
  if command_exists docker; then ok "docker present ($(docker --version | awk '{print $3}' | tr -d ,))"; else
    [ "$DO_INSTALL" -eq 1 ] || die "docker missing and --no-install set."
    step "Installing Docker"
    if [ "$OS" = "macos" ]; then
      ensure_brew
      info "Installing Docker Desktop via Homebrew (this is a large download)…"
      brew install --cask docker || die "Docker Desktop install failed. Get it from https://docker.com/products/docker-desktop"
      ok "Docker Desktop installed — launching it…"
      open -a Docker || true
    else
      info "Installing Docker Engine via get.docker.com convenience script…"
      need_sudo
      curl -fsSL https://get.docker.com -o /tmp/get-docker.sh || die "Could not download Docker install script."
      $SUDO sh /tmp/get-docker.sh || die "Docker Engine install failed."
      $SUDO usermod -aG docker "$USER" 2>/dev/null || true
      $SUDO systemctl enable --now docker 2>/dev/null || true
      warn "You were added to the 'docker' group — you may need to log out/in for non-sudo docker to work."
    fi
  fi

  # Compose plugin
  if docker compose version >/dev/null 2>&1; then
    ok "docker compose present ($(docker compose version --short 2>/dev/null))"
  elif command_exists docker-compose; then
    warn "Only legacy 'docker-compose' found. The v2 plugin ('docker compose') is recommended."
  else
    [ "$DO_INSTALL" -eq 1 ] || die "docker compose plugin missing and --no-install set."
    step "Installing docker compose plugin"
    case "$PKG" in
      apt) pkg_install docker-compose-plugin || warn "Install docker-compose-plugin manually." ;;
      dnf|yum) pkg_install docker-compose-plugin || warn "Install docker-compose-plugin manually." ;;
      *) warn "Install the docker compose v2 plugin for your distro." ;;
    esac
  fi
}

ensure_docker_running() {
  step "Checking Docker daemon"
  if docker info >/dev/null 2>&1; then ok "Docker daemon is running"; return; fi
  if [ "$OS" = "macos" ]; then
    info "Starting Docker Desktop…"; open -a Docker >/dev/null 2>&1 || true
  else
    need_sudo; $SUDO systemctl start docker 2>/dev/null || true
  fi
  info "Waiting for Docker daemon (up to 120s)…"
  for i in $(seq 1 60); do
    docker info >/dev/null 2>&1 && { ok "Docker daemon is running"; return; }
    sleep 2
  done
  die "Docker daemon did not become ready. Start Docker Desktop manually and re-run."
}

# Pick the compose command
COMPOSE="docker compose"
pick_compose() { docker compose version >/dev/null 2>&1 || COMPOSE="docker-compose"; }

# ─────────────────────────────────────────────────────────────────────────────
# Repo prep
# ─────────────────────────────────────────────────────────────────────────────
init_submodules() {
  step "Checking git submodules"
  if [ ! -f .gitmodules ]; then warn "No .gitmodules — skipping."; return; fi
  local empty=0
  while read -r path; do
    [ -z "$path" ] && continue
    [ -z "$(ls -A "$path" 2>/dev/null)" ] && empty=1
  done < <(git config -f .gitmodules --get-regexp path 2>/dev/null | awk '{print $2}')
  if [ "$empty" -eq 1 ]; then
    info "Some submodules are empty — initializing…"
    git submodule update --init --recursive || die "Submodule init failed."
    ok "Submodules initialized"
  else
    ok "All submodules already populated"
  fi
}

rand_hex() { openssl rand -hex "${1:-32}" 2>/dev/null || head -c "${1:-32}" /dev/urandom | xxd -p | tr -d '\n'; }

fill_secrets() {
  step "Filling local dev secrets (only if still placeholders)"
  local touched=0
  _sub() { # _sub <file> <KEY> <value>
    [ -f "$1" ] || return 0
    if grep -q "^$2=.*change_me" "$1" 2>/dev/null; then
      # portable in-place sed
      sed -i.bak "s|^$2=.*|$2=$3|" "$1" && rm -f "$1.bak"
      touched=1; info "set $2 in $(basename "$1")"
    fi
  }
  _sub ".env" "API_SVC_KEY" "$(rand_hex 24)"
  _sub "docker-env/automation-user-management.env" "JWT_SECRET" "$(rand_hex 32)"
  _sub "docker-env/ui-backend.env" "SESSION_SECRET" "$(rand_hex 32)"
  _sub "docker-env/ui-backend.env" "ADMIN_PASSWORD" "$(rand_hex 12)"
  _sub "docker-env/backoffice-backend.env" "SESSION_SECRET" "$(rand_hex 32)"
  if [ "$touched" -eq 0 ]; then ok "No placeholder secrets to fill"; else ok "Secrets filled"; fi
  if grep -rq "GITHUB_CLIENT_ID=.*change_me" docker-env/ 2>/dev/null; then
    warn "GitHub OAuth (GITHUB_CLIENT_ID/SECRET) left as placeholder — optional, only needed for GitHub login."
  fi
}

bring_up() {
  if [ "$DO_BUILD" -eq 1 ]; then
    step "Building frontend images (ui-frontend, backoffice-frontend)"
    $COMPOSE build ui-frontend backoffice-frontend || die "Frontend build failed."
    ok "Frontends built"
  fi
  step "Starting the stack ($COMPOSE up -d)"
  $COMPOSE up -d || die "docker compose up failed."
  ok "Stack started"

  if [ -n "$DOMAIN_BRANCH" ]; then
    step "Building domain API service: $DOMAIN_BRANCH"
    ./scripts/build-api-service.sh "$DOMAIN_BRANCH" || die "build-api-service.sh failed."
    $COMPOSE -f docker-compose.yml -f docker-compose.api.yml up -d --build || die "API service start failed."
    ok "Domain API service started ($DOMAIN_BRANCH)"
    SERVICES+=("api-service:3032:http:/")
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Health checks
# ─────────────────────────────────────────────────────────────────────────────
tcp_up()  { (exec 3<>"/dev/tcp/127.0.0.1/$1") >/dev/null 2>&1 && { exec 3>&- 3<&-; return 0; }; return 1; }
http_up() { curl -s -o /dev/null -m 4 -w "%{http_code}" "http://127.0.0.1:$1$2" 2>/dev/null | grep -qE '^[1-5][0-9][0-9]$'; }

health_check() {
  step "Health-checking services (waiting up to 180s for each to come up)"
  printf "    %-30s %-10s %s\n" "SERVICE" "PORT" "STATUS"
  printf "    %-30s %-10s %s\n" "-------" "----" "------"
  local fail=0 deadline=$(( $(date +%s) + 180 ))
  for entry in "${SERVICES[@]}"; do
    IFS=':' read -r name port proto path <<< "$entry"
    local up=1
    while [ "$(date +%s)" -lt "$deadline" ]; do
      if [ "$proto" = "tcp" ]; then tcp_up "$port" && { up=0; break; }
      else http_up "$port" "$path" && { up=0; break; }; fi
      sleep 3
    done
    if [ "$up" -eq 0 ]; then
      printf "    %-30s %-10s ${C_GRN}UP${C_RST}\n" "$name" "$port"
    else
      printf "    %-30s %-10s ${C_RED}DOWN${C_RST}\n" "$name" "$port"
      fail=$((fail+1))
    fi
  done
  echo
  step "Container states"
  $COMPOSE ps 2>/dev/null || true
  echo
  if [ "$fail" -eq 0 ]; then
    ok "All ${#SERVICES[@]} services responded. Open the UI at ${C_BLD}http://localhost:3035${C_RST}"
    [ -f docker-env/ui-backend.env ] && info "Admin login: admin / $(grep '^ADMIN_PASSWORD=' docker-env/ui-backend.env | cut -d= -f2)"
    return 0
  else
    err "$fail service(s) did not respond. Inspect logs with:  $COMPOSE logs -f <service>"
    return 1
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
main() {
  echo "${C_BLD}Automation Framework — local setup${C_RST}"
  detect_os
  pick_compose

  if [ "$DO_DOWN" -eq 1 ]; then
    step "Stopping the stack"; $COMPOSE down; ok "Stopped"; exit 0
  fi

  if [ "$CHECK_ONLY" -eq 1 ]; then
    health_check; exit $?
  fi

  if [ "$DO_INSTALL" -eq 1 ]; then
    step "Checking / installing prerequisites"
    ensure_git
    ensure_docker
  else
    info "Skipping prerequisite installation (--no-install)"
    command_exists docker || die "docker not found and --no-install set."
  fi
  ensure_docker_running
  pick_compose

  init_submodules
  fill_secrets
  bring_up
  health_check
  exit $?
}
main
