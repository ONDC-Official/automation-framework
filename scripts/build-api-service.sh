#!/usr/bin/env bash
# Prepare a domain API service for local development.
#
# What this script does:
#   1. Clones automation-specifications into api-service/ (first run)
#      or fetches + checks out the new branch (subsequent runs)
#   2. Parses config/ → build.yaml, validates, then runs api-service-generator
#   3. Stops after build-output/ is ready — Docker build is left to compose
#   4. Writes docker-compose.api.yml that builds from api-service/build-output/
#
# Usage:
#   ./scripts/build-api-service.sh <spec-branch>
#
# Examples:
#   ./scripts/build-api-service.sh draft-FIS12-2.3.0
#   ./scripts/build-api-service.sh release-eks-RET10-1.2.5
#
# After the script finishes:
#   - Edit api-service/build-output/ to customise generated code
#   - Edit api-service/config/ and re-run this script to regenerate from spec
#
# Build and start the service:
#   docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build

set -euo pipefail

GENERATOR_VERSION="1.0.2"
SPECS_REMOTE="https://github.com/ONDC-Official/automation-specifications.git"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="$(dirname "$SCRIPT_DIR")"
API_SERVICE_DIR="$FRAMEWORK_DIR/api-service"

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

# ── arg check ────────────────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <spec-branch>"
  list_branches
  exit 1
fi

SPEC_BRANCH="$1"

# ── clone or fetch automation-specifications into api-service/ ───────────────

if [[ ! -d "$API_SERVICE_DIR/.git" ]]; then
  step "Cloning automation-specifications into api-service/"
  git clone "$SPECS_REMOTE" "$API_SERVICE_DIR"
else
  step "Fetching latest from remote"
  git -C "$API_SERVICE_DIR" fetch origin
fi

# ── checkout the spec branch ─────────────────────────────────────────────────

step "Checking out spec branch: $SPEC_BRANCH"
git -C "$API_SERVICE_DIR" checkout -B local-spec "origin/$SPEC_BRANCH" \
  || die "Branch '$SPEC_BRANCH' not found. Run '$0' with no args to list available branches."

info "api-service/ is now on: $SPEC_BRANCH"

cd "$API_SERVICE_DIR"

# ── parse config/ → build.yaml ───────────────────────────────────────────────

step "Parsing config/"
npx -y @ondc/build-tools@latest parse -i config -o build.yaml

# ── validate ─────────────────────────────────────────────────────────────────

step "Validating build.yaml"
npx -y @ondc/build-tools@latest validate -i build.yaml

# ── read domain + version ────────────────────────────────────────────────────

step "Reading domain and version"
DOMAIN=$(python3 -c "import yaml; d=yaml.safe_load(open('build.yaml')); print(d['info']['domain'])")
VERSION=$(python3 -c "import yaml; d=yaml.safe_load(open('build.yaml')); print(d['info']['version'])")
info "Domain: $DOMAIN | Version: $VERSION"

DOMAIN_NORM=$(echo "$DOMAIN" | tr '[:upper:]' '[:lower:]' | tr -d ':')
VERSION_NORM=$(echo "$VERSION" | tr '.' '-')
SERVICE_NAME="api-${DOMAIN_NORM}-${VERSION_NORM}"

# ── generate ONIX build output ───────────────────────────────────────────────

step "Generating ONIX build output (api-service-generator@$GENERATOR_VERSION)"

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
  npx -y "@ondc/api-service-generator@${GENERATOR_VERSION}" --config ./build.yaml

[[ -d build-output ]] || die "Generator did not produce build-output/ directory."

info "build-output/ is ready at: api-service/build-output/"

# ── generate RAG table ───────────────────────────────────────────────────────

step "Generating RAG table"
npx -y @ondc/build-tools@latest gen-rag-table -i build.yaml -o generated

# ── push spec data to local db-service ───────────────────────────────────────

step "Pushing spec data to local db-service"
DB_KEY="${DB_API_KEY:-D33A76D111B4BDFCB96A2AC34B85E}"
DB_URL="${DB_API_BASE_URL:-http://localhost:5001}"

PUSH_OUTPUT=$(npx -y @ondc/build-tools@latest push-to-db \
    -f build.yaml \
    -t generated/raw_table.json \
    -u "$DB_URL" \
    -k "$DB_KEY" 2>&1) && EXIT_CODE=0 || EXIT_CODE=$?

if echo "$PUSH_OUTPUT" | grep -qE "HTTP Status: [45][0-9][0-9]"; then
  STATUS=$(echo "$PUSH_OUTPUT" | grep "HTTP Status:" | awk '{print $3}')
  warn "push-to-db returned HTTP $STATUS — set DB_API_KEY env var or update api-service-common.env, then re-run."
elif [[ $EXIT_CODE -ne 0 ]]; then
  warn "push-to-db failed — db-service may not be running yet. Re-run after 'docker compose up -d'."
else
  info "Spec data pushed to db-service."
fi

# ── write docker-compose.api.yml ─────────────────────────────────────────────

step "Writing $FRAMEWORK_DIR/docker-compose.api.yml"

cat > "$FRAMEWORK_DIR/docker-compose.api.yml" <<EOF
# Auto-generated by scripts/build-api-service.sh
# Domain:  $DOMAIN
# Version: $VERSION
# Branch:  $SPEC_BRANCH
#
# Build and start:
#   docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build
#
# Rebuild after editing api-service/build-output/ (no full regen):
#   docker compose -f docker-compose.yml -f docker-compose.api.yml build $SERVICE_NAME
#   docker compose -f docker-compose.yml -f docker-compose.api.yml up -d $SERVICE_NAME
#
# Regenerate from spec after editing api-service/config/:
#   ./scripts/build-api-service.sh $SPEC_BRANCH

version: "3.8"

services:
  ${SERVICE_NAME}:
    build:
      context: ./api-service/build-output
      dockerfile: Dockerfile
    container_name: ${SERVICE_NAME}
    # Port 3032 matches API_SERVICE URL used by ui-backend and playground-mock-service.
    # The 'api-service' alias lets other containers reach this regardless of domain/version.
    ports:
      - "3032:7039"
    env_file:
      - ./docker-env/api-service-common.env
    networks:
      automation-network:
        aliases:
          - api-service
    depends_on:
      - redis
      - config-service
      - db-service
      - recorder-service
      - jaeger
    restart: unless-stopped

networks:
  automation-network:
    driver: bridge
EOF

info "Written: docker-compose.api.yml (service: $SERVICE_NAME)"

# ── done ─────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done: $DOMAIN $VERSION"
echo ""
echo "  Working directory:  api-service/"
echo "    api-service/config/        ← edit spec, then re-run this script"
echo "    api-service/build-output/  ← edit generated code, then rebuild"
echo ""
echo "  Before starting, fill in secrets:"
echo "    docker-env/api-service-common.env"
echo ""
echo "  Build and start:"
echo "    docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build"
echo ""
echo "  API endpoint: http://localhost:3032"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
