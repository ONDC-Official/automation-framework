#!/usr/bin/env bash
# Prepare one or more domain API services for local development.
#
# What this script does:
#   1. Clones automation-specifications into api-service/ (first run)
#      or fetches + checks out the new branch (subsequent runs)
#   2. Parses config/ → build.yaml, validates, then runs api-service-generator
#   3. Stops after build-output/ is ready — Docker build is left to compose
#   4. Writes docker-compose.api.yml that builds from api-service/build-output/
#
# Several branches can run side by side. The first branch builds in api-service/; each
# further branch builds in api-services/<branch>/, a git worktree of the same clone. nginx
# on :3032 routes every /api-service/<domain>/<version>/ and /mock/<domain>/<version>/ to
# its own service.
#
# Usage:
#   ./scripts/build-api-service.sh <spec-branch> [<spec-branch> ...]
#
# Examples:
#   ./scripts/build-api-service.sh draft-FIS12-2.3.0
#   ./scripts/build-api-service.sh release-eks-RET10-1.2.5
#   ./scripts/build-api-service.sh draft-FIS12-2.3.0 draft-FIS14FD-0.1.4
#
# Environment:
#   TOOLING_REF      ref of automation-specifications whose tooling/ pins the tools (origin/main)
#   PWB_TOOLING_DIR  a local tooling/ folder to use instead, e.g. with unreleased tools
#   SPECS_LOCAL      a local automation-specifications checkout; its branches take precedence
#                    over origin's (e.g. an unpushed draft branch, or local commits)
#   PLUGINS_GIT      automation-beckn-plugins repository the generator clones (official repo)
#   PLUGINS_REF      plugins commit or branch (default: PLUGINS_REF in tooling/versions.env)
#
# FD (ONDC:FIS14:FD) branches need FD-capable tools and plugins, which are not released yet:
#   PWB_TOOLING_DIR=<tooling with the FD tools> SPECS_LOCAL=./automation-specifications \
#   PLUGINS_GIT=<local automation-beckn-plugins> PLUGINS_REF=feat/fd-workbench \
#     ./scripts/build-api-service.sh draft-FIS12-2.3.0 draft-FIS14FD-0.1.4
#
# After the script finishes:
#   - Edit api-service/build-output/ to customise generated code
#   - Edit api-service/config/ and re-run this script to regenerate from spec
#
# Build and start the services:
#   docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build

set -euo pipefail

SPECS_REMOTE="https://github.com/ONDC-Official/automation-specifications.git"
# Tool versions come from tooling/ in automation-specifications (versions.env + package-lock.json).
# TOOLING_REF picks another remote ref; PWB_TOOLING_DIR uses a local tooling/ folder instead.
TOOLING_REF="${TOOLING_REF:-origin/main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="$(dirname "$SCRIPT_DIR")"
API_SERVICE_DIR="$FRAMEWORK_DIR/api-service"
EXTRA_SERVICES_DIR="$FRAMEWORK_DIR/api-services"

# ── helpers ──────────────────────────────────────────────────────────────────

info() { echo "  [info]  $*"; }
step() { echo ""; echo "==> $*"; }
warn() { echo "  [warn]  $*" >&2; }
die()  { echo "  [error] $*" >&2; exit 1; }

list_branches() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' RETURN

  echo ""
  echo "Fetching branch list from remote..."
  git clone --bare --quiet "$SPECS_REMOTE" "$tmp_dir" 2>/dev/null

  echo ""
  echo "Available spec branches:"
  echo ""
  git -C "$tmp_dir" branch -r \
    | grep -E "origin/(draft-|release-)" \
    | sed 's|  origin/||' \
    | sort \
    | column
  echo ""
}

# A branch of SPECS_LOCAL (fetched as local/<branch>), or else of origin.
resolve_ref() {
  local branch="$1"
  if [[ -n "${SPECS_LOCAL:-}" ]] && git -C "$API_SERVICE_DIR" rev-parse --verify -q "local/$branch" >/dev/null; then
    echo "local/$branch"
  elif git -C "$API_SERVICE_DIR" rev-parse --verify -q "origin/$branch" >/dev/null; then
    echo "origin/$branch"
  else
    die "Branch '$branch' not found. Run '$0' with no args to list available branches."
  fi
}

# ── arg check ────────────────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <spec-branch> [<spec-branch> ...]"
  list_branches
  exit 1
fi

SPEC_BRANCHES=("$@")

# ── clone or fetch automation-specifications into api-service/ ───────────────

if [[ ! -d "$API_SERVICE_DIR/.git" ]]; then
  step "Cloning automation-specifications into api-service/"
  git clone "$SPECS_REMOTE" "$API_SERVICE_DIR"
else
  step "Fetching latest from remote"
  git -C "$API_SERVICE_DIR" fetch origin
fi

if [[ -n "${SPECS_LOCAL:-}" ]]; then
  step "Fetching branches from $SPECS_LOCAL as local/*"
  git -C "$API_SERVICE_DIR" fetch --quiet "$(cd "$SPECS_LOCAL" && pwd)" "+refs/heads/*:refs/remotes/local/*"
fi

# ── hide generated files from git status in the specs clone ──────────────────
# Local-only (.git/info/exclude) so the automation-specifications repo is untouched. The
# exclude file is shared by every worktree of the clone.

for pattern in /build.yaml /build-output/ /generated/ /nginx/ /.pwb-tooling/ /node_modules; do
  grep -qxF "$pattern" "$API_SERVICE_DIR/.git/info/exclude" 2>/dev/null \
    || echo "$pattern" >> "$API_SERVICE_DIR/.git/info/exclude"
done

# ── install the pinned tools ─────────────────────────────────────────────────

if [[ -n "${PWB_TOOLING_DIR:-}" ]]; then
  # A local tooling/ folder, e.g. automation-specifications/tooling on an unpushed branch.
  step "Using pinned tools from $PWB_TOOLING_DIR"
  TOOLING_DIR="$(cd "$PWB_TOOLING_DIR" && pwd)"
  [[ -d "$TOOLING_DIR/node_modules" ]] || npm ci --prefix "$TOOLING_DIR" --no-audit --no-fund --loglevel=error
else
  step "Installing pinned tools from $TOOLING_REF:tooling/"
  TOOLING_DIR="$API_SERVICE_DIR/.pwb-tooling"
  git -C "$API_SERVICE_DIR" cat-file -e "${TOOLING_REF}:tooling/package-lock.json" 2>/dev/null \
    || die "No tooling/ at $TOOLING_REF. Set TOOLING_REF to a ref that has it, or PWB_TOOLING_DIR to a local tooling/ folder."
  rm -rf "$TOOLING_DIR"
  mkdir -p "$TOOLING_DIR"
  for f in package.json package-lock.json versions.env; do
    git -C "$API_SERVICE_DIR" show "${TOOLING_REF}:tooling/$f" > "$TOOLING_DIR/$f"
  done
  npm ci --prefix "$TOOLING_DIR" --no-audit --no-fund --loglevel=error
fi
TOOLS="$TOOLING_DIR/node_modules/.bin"
if [[ -f "$TOOLING_DIR/versions.env" ]]; then
  info "$(grep -E '^(BUILD_TOOLS|API_SERVICE_GENERATOR|CODE_GENERATOR)_VERSION=' "$TOOLING_DIR/versions.env" | tr '\n' ' ')"
else
  warn "$TOOLING_DIR has no versions.env; plugins and the ONIX image are not pinned."
fi

pinned() { grep -E "^$1=" "$TOOLING_DIR/versions.env" 2>/dev/null | cut -d= -f2- || true; }
PLUGINS_REF="${PLUGINS_REF:-$(pinned PLUGINS_REF)}"
ONIX_IMAGE="$(pinned ONIX_IMAGE)"
[[ -n "${PLUGINS_GIT:-}" ]] && info "Plugins: $PLUGINS_GIT @ ${PLUGINS_REF:-main}" \
  || info "Plugins: official repository @ ${PLUGINS_REF:-main}"

# Read the canonical db-service key from root .env so it stays in sync with the running stack
_API_SVC_KEY=$(grep '^API_SVC_KEY=' "$FRAMEWORK_DIR/.env" 2>/dev/null | cut -d= -f2 || true)
DB_KEY="${DB_API_KEY:-${_API_SVC_KEY:-local_api_service_key_change_me}}"
DB_URL="${DB_API_BASE_URL:-http://localhost:5001}"

# ── build each branch ────────────────────────────────────────────────────────

DOMAINS=(); VERSIONS=(); SERVICE_NAMES=(); SERVICE_DIRS=(); IS_FD=()

build_branch() {
  local spec_branch="$1" dir="$2" ref
  ref=$(resolve_ref "$spec_branch")

  # ── checkout the spec branch ───────────────────────────────────────────────

  step "Checking out spec branch: $spec_branch ($ref)"
  if [[ "$dir" == "$API_SERVICE_DIR" ]]; then
    git -C "$dir" checkout -B local-spec "$ref"
  elif [[ -e "$dir/.git" ]]; then
    git -C "$dir" checkout -B "local-spec-$spec_branch" "$ref"
  else
    mkdir -p "$(dirname "$dir")"
    git -C "$API_SERVICE_DIR" worktree add -B "local-spec-$spec_branch" "$dir" "$ref"
  fi
  info "${dir#"$FRAMEWORK_DIR"/}/ is now on: $spec_branch"

  cd "$dir"
  # The generator's scripts run ./node_modules/.bin/ondc-code-generator from the working
  # directory, so linking the pinned tools here pins the code generator as well.
  ln -sfn "$TOOLING_DIR/node_modules" node_modules

  # ── parse config/ → build.yaml ─────────────────────────────────────────────

  step "Parsing config/"
  "$TOOLS/ondc-tools" parse -i config -o build.yaml

  # ── validate ───────────────────────────────────────────────────────────────

  step "Validating build.yaml"
  "$TOOLS/ondc-tools" validate -i build.yaml

  # ── read domain + version ──────────────────────────────────────────────────

  step "Reading domain and version"
  local domain version is_fd
  read -r domain version is_fd < <(python3 -c "import yaml; d=yaml.safe_load(open('build.yaml')); print(d['info']['domain'], d['info']['version'], 'x-fd-routes' in d)")
  info "Domain: $domain | Version: $version$([[ "$is_fd" == True ]] && echo " | FD route table: yes")"

  local domain_norm version_norm service_name i
  domain_norm=$(echo "$domain" | tr '[:upper:]' '[:lower:]' | tr -d ':')
  version_norm=$(echo "$version" | tr '.' '-')
  service_name="api-${domain_norm}-${version_norm}"
  for i in "${!SERVICE_NAMES[@]}"; do
    [[ "${SERVICE_NAMES[$i]}" != "$service_name" ]] \
      || die "$spec_branch and ${SPEC_BRANCHES[$i]} are both $domain $version; build them one at a time."
  done

  # ── generate ONIX build output ─────────────────────────────────────────────

  step "Generating ONIX build output (pinned api-service-generator)"

  # Remove stale build-output so the generator starts clean
  rm -rf build-output

  IS_ONIX_ENABLED=true \
  PORT=7039 \
  REDIS_HOST=redis \
  REDIS_PORT=6379 \
  REDIS_PASSWORD= \
  CONFIG_SERVICE_URL=http://config-service:5556 \
  MOCK_SERVER_URL=http://playground-mock-service:3000 \
  RECORDER_SERVICE_HTTP_URL=http://recorder-service:8090 \
  RECORDER_SERVICE_GRPC_URL=recorder-service:8089 \
  PLUGINS_GIT="${PLUGINS_GIT:-}" \
  PLUGINS_REF="$PLUGINS_REF" \
    "$TOOLS/ondc-api-service-generator" --config ./build.yaml

  [[ -d build-output ]] || die "Generator did not produce build-output/ directory."
  if [[ "$is_fd" == True && ! -f build-output/temp/config/fd_routes.yaml ]]; then
    die "$spec_branch is an FD branch, but the generator wrote no fd_routes.yaml; it needs an FD-capable api-service-generator (see PWB_TOOLING_DIR)."
  fi

  info "build-output/ is ready at: ${dir#"$FRAMEWORK_DIR"/}/build-output/"

  # ── generate RAG table ─────────────────────────────────────────────────────

  step "Generating RAG table"
  "$TOOLS/ondc-tools" gen-rag-table -i build.yaml -o generated

  # ── push spec data to local db-service ─────────────────────────────────────

  step "Pushing spec data to local db-service"
  local push_output exit_code status
  push_output=$("$TOOLS/ondc-tools" push-to-db \
      -f build.yaml \
      -t generated/raw_table.json \
      -u "$DB_URL" \
      -k "$DB_KEY" 2>&1) && exit_code=0 || exit_code=$?

  if echo "$push_output" | grep -qE "HTTP Status: [45][0-9][0-9]"; then
    status=$(echo "$push_output" | grep "HTTP Status:" | awk '{print $3}')
    warn "push-to-db returned HTTP $status — set DB_API_KEY env var or update api-service-common.env, then re-run."
  elif [[ $exit_code -ne 0 ]]; then
    warn "push-to-db failed — db-service may not be running yet. Re-run after 'docker compose up -d'."
  else
    info "Spec data pushed to db-service."
  fi

  DOMAINS+=("$domain"); VERSIONS+=("$version"); SERVICE_NAMES+=("$service_name")
  SERVICE_DIRS+=("${dir#"$FRAMEWORK_DIR"/}"); IS_FD+=("$is_fd")
  cd "$FRAMEWORK_DIR"
}

for i in "${!SPEC_BRANCHES[@]}"; do
  if [[ $i -eq 0 ]]; then
    build_branch "${SPEC_BRANCHES[$i]}" "$API_SERVICE_DIR"
  else
    build_branch "${SPEC_BRANCHES[$i]}" "$EXTRA_SERVICES_DIR/${SPEC_BRANCHES[$i]}"
  fi
done

# ── generate nginx routing config ────────────────────────────────────────────

step "Generating api-service/nginx.conf"

mkdir -p "$API_SERVICE_DIR/nginx"
NGINX_CONF="$API_SERVICE_DIR/nginx/default.conf"

{
  echo "# Auto-generated by scripts/build-api-service.sh"
  for i in "${!SERVICE_NAMES[@]}"; do
    echo "# Domain: ${DOMAINS[$i]}  Version: ${VERSIONS[$i]}"
  done
  cat <<'NGINXEOF'
#
# Replicates live nginx routing for local Docker dev, per domain and version:
#   /mock/<domain>/<version>/*        → playground /mock/playground/* (prefix stripped)
#   /api-service/<domain>/<version>/* → that domain's api-service (full path preserved)
#   /*                                → the first domain's api-service (direct)

server {
    listen 80;
NGINXEOF

  for i in "${!SERVICE_NAMES[@]}"; do
    domain="${DOMAINS[$i]}"; version="${VERSIONS[$i]}"; service="${SERVICE_NAMES[$i]}"
    if [[ "${IS_FD[$i]}" == True ]]; then
      cat <<NGINXEOF

    # FD bodies may be up to 8 MiB (the FD protocol's limit).
    location /mock/${domain}/${version}/ {
        proxy_pass         http://playground-mock-service:3000/mock/playground/;
        client_max_body_size 8m;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
    }

    # FD signatures cover (request-target), so the path must reach the service exactly as the
    # participant sent it: proxy_pass without a URI forwards the raw request URI.
    location /api-service/${domain}/${version}/ {
        proxy_pass         http://${service}:7039;
        client_max_body_size 8m;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
    }
NGINXEOF
    else
      cat <<NGINXEOF

    # Mock/playground routing: strip domain+version prefix, forward to playground
    location /mock/${domain}/${version}/ {
        proxy_pass         http://playground-mock-service:3000/mock/playground/;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
    }

    # ONDC protocol routing: full path preserved (api-service handles its own prefix)
    location /api-service/${domain}/${version}/ {
        proxy_pass         http://${service}:7039/api-service/${domain}/${version}/;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
    }
NGINXEOF
    fi
  done

  cat <<NGINXEOF

    # Direct requests → api-service
    location / {
        proxy_pass         http://${SERVICE_NAMES[0]}:7039;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
    }
}
NGINXEOF
} > "$NGINX_CONF"

info "Written: api-service/nginx/default.conf"

# ── update API_SVC in root .env to point to nginx ────────────────────────────

step "Updating API_SVC in root .env → http://api-service:80/api-service"
if [[ -f "$FRAMEWORK_DIR/.env" ]]; then
  sed -i '' 's|^API_SVC=.*|API_SVC=http://api-service:80/api-service|' "$FRAMEWORK_DIR/.env"
  info "API_SVC updated"
else
  warn "$FRAMEWORK_DIR/.env not found; API_SVC not updated"
fi

# ── write docker-compose.api.yml ─────────────────────────────────────────────

step "Writing $FRAMEWORK_DIR/docker-compose.api.yml"

{
  echo "# Auto-generated by scripts/build-api-service.sh"
  for i in "${!SERVICE_NAMES[@]}"; do
    echo "# ${DOMAINS[$i]} ${VERSIONS[$i]}  (branch ${SPEC_BRANCHES[$i]}, ${SERVICE_DIRS[$i]}/)"
  done
  cat <<EOF
#
# Build and start:
#   docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build
#
# Rebuild after editing <dir>/build-output/ (no full regen):
#   docker compose -f docker-compose.yml -f docker-compose.api.yml build <service>
#   docker compose -f docker-compose.yml -f docker-compose.api.yml up -d <service>
#
# Regenerate from spec after editing <dir>/config/:
#   ./scripts/build-api-service.sh ${SPEC_BRANCHES[*]}

version: "3.8"

services:
  # nginx acts as the API gateway — exposed on port 3032 with 'api-service' alias.
  # It replicates live nginx routing: strips /{domain}/{version} prefixes and
  # routes mock/* requests to playground, ONDC protocol requests to api-service.
  api-gateway:
    image: nginx:alpine
    container_name: api-gateway
    ports:
      - "3032:80"
    volumes:
      - ./api-service/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      automation-network:
        aliases:
          - api-service
    depends_on:
EOF
  for service in "${SERVICE_NAMES[@]}"; do
    echo "      - ${service}"
  done
  echo "      - playground-mock-service"
  echo "    restart: unless-stopped"

  for i in "${!SERVICE_NAMES[@]}"; do
    domain="${DOMAINS[$i]}"; version="${VERSIONS[$i]}"; service="${SERVICE_NAMES[$i]}"
    domain_norm=$(echo "$domain" | tr '[:upper:]' '[:lower:]' | tr -d ':')
    version_norm=$(echo "$version" | tr '.' '-')
    cat <<EOF

  ${service}:
    build:
      context: ./${SERVICE_DIRS[$i]}/build-output
      dockerfile: Dockerfile
EOF
    if [[ "${IS_FD[$i]}" == True && -n "$ONIX_IMAGE" ]]; then
      cat <<EOF
      args:
        # FD plugins load only into the ONIX build they were compiled against.
        ONIX_IMAGE: "${ONIX_IMAGE}"
EOF
    fi
    cat <<EOF
    container_name: ${service}
    # Not exposed externally — traffic comes in via api-gateway (nginx)
    env_file:
      - ./docker-env/infra.env
      - ./docker-env/api-service-common.env
    environment:
      # Alias translations — canonical names from root .env resolved at compose load time
      CONFIG_SERVICE_URL:        \${CONFIG_SVC}
      DATA_BASE_URL:             \${DB_SVC}
      MOCK_SERVER_URL:           \${MOCK_SVC}
      IN_HOUSE_REGISTRY:         \${REGISTRY_SVC}
      IN_HOUSE_URL:              \${REGISTRY_SVC}
      RECORDER_SERVICE_HTTP_URL: \${RECORDER_HTTP_SVC}
      RECORDER_SERVICE_GRPC_URL: \${RECORDER_GRPC_SVC}
      API_SERVICE_KEY:           \${API_SVC_KEY}
      # Domain-specific — injected per build
      DOMAIN:         "$domain"
      DOMAIN_VERSION: "$version"
      VERSION:        "$version"
      SERVICE_NAME:   "automation-api-service-local-${domain_norm}-${version_norm}"
    networks:
      - automation-network
    depends_on:
      - redis
      - config-service
      - db-service
      - recorder-service
      - jaeger
    restart: unless-stopped
EOF
  done

  cat <<EOF

networks:
  automation-network:
    driver: bridge
EOF
} > "$FRAMEWORK_DIR/docker-compose.api.yml"

info "Written: docker-compose.api.yml (nginx gateway + services: ${SERVICE_NAMES[*]})"

# ── done ─────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for i in "${!SERVICE_NAMES[@]}"; do
  echo "  Done: ${DOMAINS[$i]} ${VERSIONS[$i]}  →  ${SERVICE_DIRS[$i]}/  (service ${SERVICE_NAMES[$i]})"
done
echo ""
echo "  Working directories:"
for i in "${!SERVICE_NAMES[@]}"; do
  echo "    ${SERVICE_DIRS[$i]}/config/        ← edit spec, then re-run this script"
  echo "    ${SERVICE_DIRS[$i]}/build-output/  ← edit generated code, then rebuild"
done
echo ""
echo "  Before starting, fill in secrets:"
echo "    docker-env/api-service-common.env"
echo ""
echo "  Build and start:"
echo "    docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build"
echo ""
echo "  API endpoint: http://localhost:3032"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
