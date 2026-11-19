#!/usr/bin/env bash
#
# Sets up the ONDC automation workbench for local development on a fresh machine.
# Every service is cloned from GitHub and run natively, and they are wired so that
# buyer (BAP) and seller (BPP) sessions transact with each other through a local
# ONIX api-service. The frontend consumes a local build of the mock-runner lib,
# for Protocol Playground / Studio work. See README.md next to this file.
#
#   scripts/local-workbench/bootstrap.sh [target-dir] [flags]
#
#   target-dir         where to set it up (default ./ondc-workbench)
#   --spec <branch>    automation-specifications branch to build the ONIX api-service
#                      for (default draft-TRV11-2.1.0). One build serves one domain/version.
#   --skip-install     clone and configure only: no npm ci, no Go build, no ONIX build
#   --skip-docker      don't pre-pull Mongo or pre-build the ONIX image (the first
#                      `npm run dev` does it instead, which takes a few minutes)
#
# Branches: automation-frontend at `main-tech`, every other repo at `main`.
# automation-frontend's GitHub default branch is the stale `main`, so it is named.
#
# Safe to re-run: a repo that is already cloned, an .env that already exists and an
# ONIX build that is already generated are all left untouched.
#
# Tested on macOS with Docker Desktop. Linux works with the caveats it prints.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
GIT_BASE="${ONDC_GIT_BASE:-https://github.com/ONDC-Official}" # e.g. git@github.com:ONDC-Official
REPOS="automation-frontend:main-tech
automation-mock-runner-lib:main
automation-mock-playground-service:main
automation-api-service-generator:main
automation-db:main
automation-recorder-service:main
automation-report-service:main"

# One base URL everywhere (mock API_SERVICE_URL, backend API_SERVICE, frontend
# VITE_BASE_URL). Port 80 and a dotted host are deliberate: the mock derives
# bap_id/bpp_id from the host, and the report service rejects host:port ids.
# *.localhost resolves to loopback in Node, curl and Chrome without /etc/hosts edits.
API_BASE="http://workbench.localhost/api-service"
CONFIG_URL="https://dev-workbench.ondc.tech/config-service"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
note() { printf '  \033[2m·\033[0m %s\n' "$*"; }
ok() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() {
	printf '  \033[33m!\033[0m %s\n' "$*"
	WARNINGS="${WARNINGS}  - $*
"
}
die() {
	printf '\n  \033[31m✗ %s\033[0m\n' "$*" >&2
	exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }
usage() { sed -n '3,24p' "$0" | sed 's/^# \{0,1\}//'; }

WARNINGS=""
STEP="startup"
trap 'printf "\n  \033[31m✗ bootstrap stopped during: %s\033[0m\n  Fix the error above and re-run - finished steps are skipped.\n" "$STEP" >&2' ERR

TARGET=""
SPEC="draft-TRV11-2.1.0"
SKIP_INSTALL=0
SKIP_DOCKER=0
while [ $# -gt 0 ]; do
	case "$1" in
	--spec)
		[ $# -ge 2 ] || die "--spec needs a branch name, e.g. --spec draft-TRV11-2.1.0"
		SPEC="$2"
		shift
		;;
	--spec=*) SPEC="${1#--spec=}" ;;
	--skip-install) SKIP_INSTALL=1 ;;
	--skip-docker) SKIP_DOCKER=1 ;;
	-h | --help)
		usage
		exit 0
		;;
	-*) die "unknown flag: $1 (see --help)" ;;
	*) TARGET="$1" ;;
	esac
	shift
done

[ -f "$HERE/workspace/scripts/dev.js" ] || die "workspace/ is missing next to this script - run it from a clone of automation-framework"
TARGET="${TARGET:-$PWD/ondc-workbench}"
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
OS="$(uname -s)"
install_hint() { if [ "$OS" = Darwin ]; then echo "brew install $1"; else echo "$2"; fi; }

# -- 1. toolchain ---------------------------------------------------------------------
STEP="checking the toolchain"
bold "1/7 Toolchain"
for tool in git node npm; do
	have "$tool" || die "$tool is required - $(install_hint "$tool" "install $tool with your package manager")"
done
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
[ "$NODE_MAJOR" -ge 20 ] || die "node $(node -v) is too old - the frontend's Vite 8 needs 20.19+ (22+ recommended)"
[ "$NODE_MAJOR" -ge 22 ] || warn "node $(node -v): Vite 8 runs from 20.19, but 22+ is recommended"
ok "git $(git --version | cut -d' ' -f3), node $(node -v), npm $(npm -v)"

if have go; then ok "$(go version | cut -d' ' -f3)"; else warn "go not found - the recorder cannot be built, and every step after a journey's first fails without it ($(install_hint go 'https://go.dev/dl/'))"; fi
if have redis-server; then ok "redis-server $(redis-server --version | sed 's/.*v=\([^ ]*\).*/\1/')"; else warn "redis-server not found - \`npm run dev\` needs it unless a Redis already listens on 6379 ($(install_hint redis 'apt install redis-server'))"; fi
DOCKER_UP=0
if ! have docker; then
	warn "docker not found - Mongo (automation-db) and the ONIX api-service need it ($(install_hint '--cask docker' 'https://docs.docker.com/engine/install/'))"
elif ! docker compose version >/dev/null 2>&1; then
	warn "docker is installed but \`docker compose\` (v2) is not"
elif ! docker info >/dev/null 2>&1; then
	warn "the Docker daemon is not running - start it, then re-run to pre-build the images"
else
	DOCKER_UP=1
	ok "$(docker --version | cut -d, -f1), compose $(docker compose version --short)"
fi

# -- 2. workspace root ------------------------------------------------------------------
STEP="copying the workspace tooling"
bold "2/7 Workspace → $TARGET"
if [ -f "$TARGET/package.json" ]; then
	note "package.json already there - workspace tooling left untouched"
else
	cp -R "$HERE/workspace/." "$TARGET/"
	ok "package.json + scripts/ (dev.js, monitor, registry stub, lib sync)"
fi

# -- 3. repositories --------------------------------------------------------------------
bold "3/7 Repositories"
for entry in $REPOS; do
	repo="${entry%%:*}"
	branch="${entry#*:}"
	dir="$TARGET/$repo"
	STEP="cloning $repo"
	if [ -d "$dir/.git" ]; then
		note "$repo already cloned (on $(git -C "$dir" rev-parse --abbrev-ref HEAD)) - left as it is"
		continue
	fi
	git clone --quiet --branch "$branch" "$GIT_BASE/$repo.git" "$dir"
	ok "$repo @ $branch $(git -C "$dir" rev-parse --short=9 HEAD)"
done

# -- 4. .env files ------------------------------------------------------------------------
STEP="writing the .env files"
bold "4/7 Environment files"
set_env() { # file key value: replace the key's line, or append it
	node -e '
		const fs = require("fs");
		const [file, key, value] = process.argv.slice(1);
		let text = fs.existsSync(file) ? fs.readFileSync(file, "utf8") : "";
		const line = new RegExp("^" + key + "=.*$", "m");
		text = line.test(text)
			? text.replace(line, () => key + "=" + value)
			: text + (text && !text.endsWith("\n") ? "\n" : "") + key + "=" + value + "\n";
		fs.writeFileSync(file, text);
	' "$1" "$2" "$3"
}
BE_ENV="$TARGET/automation-frontend/backend/.env"
FE_ENV="$TARGET/automation-frontend/frontend/.env"
MOCK_ENV="$TARGET/automation-mock-playground-service/.env"
be_new=0 fe_new=0 mock_new=0
[ -f "$BE_ENV" ] || be_new=1
[ -f "$FE_ENV" ] || fe_new=1
[ -f "$MOCK_ENV" ] || mock_new=1

# Base files from each repo's .env.example (with fresh session secrets), then the
# workbench topology on top - only on files created just now, never on an existing one.
node "$TARGET/scripts/prepare-env.js" >/dev/null
if [ "$be_new" = 1 ] && [ -f "$BE_ENV" ]; then
	set_env "$BE_ENV" API_SERVICE "$API_BASE"
	set_env "$BE_ENV" CONFIG_SERVICE "$CONFIG_URL"
	set_env "$BE_ENV" MOCK_SERVICE "http://localhost:5004/mock"
	ok "automation-frontend/backend/.env"
else note "backend .env already existed - left untouched"; fi
if [ "$fe_new" = 1 ] && [ -f "$FE_ENV" ]; then
	set_env "$FE_ENV" VITE_BASE_URL "$API_BASE"
	ok "automation-frontend/frontend/.env"
else note "frontend .env already existed - left untouched"; fi
if [ "$mock_new" = 1 ] && [ -f "$MOCK_ENV" ]; then
	set_env "$MOCK_ENV" API_SERVICE_URL "$API_BASE"
	set_env "$MOCK_ENV" CONFIG_SERVICE_URL "$CONFIG_URL"
	ok "automation-mock-playground-service/.env"
else note "mock service .env already existed - left untouched"; fi

# automation-db and the report service ship no example. They, the backend and the
# recorder (dev.js passes it the db's key) must all share one API_SERVICE_KEY.
API_KEY="$(grep -E '^API_SERVICE_KEY=' "$BE_ENV" 2>/dev/null | head -1 | cut -d= -f2- || true)"
if [ -z "$API_KEY" ]; then
	API_KEY="$(node -p 'require("crypto").randomBytes(24).toString("hex")')"
	[ -f "$BE_ENV" ] && set_env "$BE_ENV" API_SERVICE_KEY "$API_KEY"
fi
DB_ENV="$TARGET/automation-db/.env"
if [ ! -f "$DB_ENV" ]; then
	cat >"$DB_ENV" <<EOF
NODE_ENV=development
PORT=5001
SERVICE_NAME=automation-db-local
MONGO_URI=mongodb://127.0.0.1:27017/automation-db
API_SERVICE_KEY=$API_KEY
EOF
	ok "automation-db/.env (Mongo on 27017)"
else note "automation-db .env already existed - left untouched"; fi
REPORT_ENV="$TARGET/automation-report-service/.env"
if [ ! -f "$REPORT_ENV" ]; then
	cat >"$REPORT_ENV" <<EOF
NODE_ENV=development
PORT=5005
SERVICE_NAME=automation-report-local
DATA_BASE_URL=http://localhost:5001
API_SERVICE_KEY=$API_KEY
AUTOMATION_BACKEND=http://localhost:4000
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_USERNAME=
REDIS_PASSWORD=
EOF
	ok "automation-report-service/.env"
else note "report service .env already existed - left untouched"; fi

# -- 5. dependencies ------------------------------------------------------------------------
bold "5/7 Dependencies"
if [ "$SKIP_INSTALL" = 1 ]; then
	note "--skip-install: skipped. Later: npm run setup in $TARGET, then npm ci in automation-db and automation-report-service"
else
	STEP="npm run setup (lib, backend, frontend, mock service + the local lib link)"
	(cd "$TARGET" && npm run setup)
	ok "npm run setup"
	for repo in automation-db automation-report-service automation-api-service-generator; do
		STEP="npm ci in $repo"
		npm --prefix "$TARGET/$repo" ci --no-audit --no-fund
		ok "$repo installed"
	done
	if have go; then
		STEP="building automation-recorder-service"
		mkdir -p "$TARGET/.local/bin"
		(cd "$TARGET/automation-recorder-service" && go build -o "$TARGET/.local/bin/automation-recorder" .)
		ok "recorder built into .local/bin"
	fi
fi

# -- 6. the ONIX api-service build -------------------------------------------------------------
# What dev.js runs as the api-service: automation-api-service-generator/build-output,
# generated for one spec branch, then given the fixes the generator's own output needs
# to run in this topology (its .env lines come out indented, it writes IN_HOUSE_URL
# where the keymanager reads IN_HOUSE_REGISTRY and no REDIS_URL, and its compose file's
# healthcheck sends a HEAD the server fails). The signing keypair is minted here; the
# local registry stub (scripts/local-registry.js) serves its public half.
bold "6/7 ONIX api-service ($SPEC)"
GEN="$TARGET/automation-api-service-generator"
ONIX="$GEN/build-output"
SPECS="$TARGET/.local/specs"
if [ -f "$ONIX/docker-compose.yml" ]; then
	note "build-output already generated - delete it and re-run to rebuild (e.g. for another --spec)"
elif [ "$SKIP_INSTALL" = 1 ]; then
	note "--skip-install: skipped (the generator needs its dependencies)"
else
	STEP="fetching automation-specifications @ $SPEC"
	rm -rf "$SPECS"
	git clone --quiet --depth 1 --branch "$SPEC" "$GIT_BASE/automation-specifications.git" "$SPECS" ||
		die "no spec branch '$SPEC' - see: git ls-remote --heads $GIT_BASE/automation-specifications.git"
	STEP="building build.yaml from the spec's config/"
	(cd "$SPECS" && npx -y @ondc/build-tools@latest parse -i config -o build.yaml)
	cp "$SPECS/build.yaml" "$GEN/src/config/build.yaml"
	ok "build.yaml from $SPEC"

	STEP="reading the spec's domain and version"
	SPEC_INFO="$(node -e '
		const yaml = require(process.argv[1]);
		const info = yaml.load(require("fs").readFileSync(process.argv[2], "utf8")).info;
		console.log(info.domain + " " + info.version);
	' "$GEN/node_modules/js-yaml" "$SPECS/build.yaml")"
	DOMAIN="${SPEC_INFO% *}"
	VERSION="${SPEC_INFO#* }"
	[ -n "$DOMAIN" ] && [ -n "$VERSION" ] || die "could not read info.domain / info.version from $SPECS/build.yaml"
	SERVICE_NAME="$(printf 'onix-%s_%s' "$DOMAIN" "$VERSION" | tr ':.' '__' | tr '[:upper:]' '[:lower:]')"

	STEP="minting the workbench signing keypair"
	# ed25519 in the libsodium layout the ONDC SDKs use: private = seed || public.
	KEYS="$(node -e '
		const crypto = require("crypto");
		const { privateKey, publicKey } = crypto.generateKeyPairSync("ed25519");
		const seed = Buffer.from(privateKey.export({ format: "jwk" }).d, "base64url");
		const pub = Buffer.from(publicKey.export({ format: "jwk" }).x, "base64url");
		console.log([Buffer.concat([seed, pub]).toString("base64"), pub.toString("base64")].join(" "));
	')"
	SIGN_PRIVATE="${KEYS% *}"
	SIGN_PUBLIC="${KEYS#* }"
	UKID="local-$(node -p 'require("crypto").randomBytes(4).toString("hex")')"

	STEP="generating the ONIX api-service for $DOMAIN $VERSION"
	note "generating for $DOMAIN $VERSION (clones the beckn plugins and code-generates validations; a few minutes)..."
	(cd "$GEN" && npm run build --silent &&
		env IS_ONIX_ENABLED=true DOMAIN="$DOMAIN" VERSION="$VERSION" PORT=80 \
			SUBSCRIBER_ID=workbench.localhost UKID="$UKID" \
			SIGN_PRIVATE_KEY="$SIGN_PRIVATE" SIGN_PUBLIC_KEY="$SIGN_PUBLIC" \
			IN_HOUSE_REGISTRY=http://host.docker.internal:5010/ REDIS_USERNAME= REDIS_PASSWORD= \
			CONFIG_SERVICE_URL="$CONFIG_URL" MOCK_SERVER_URL=http://host.docker.internal:5004/mock \
			RECORDER_SERVICE_HTTP_URL=http://host.docker.internal:8090 \
			RECORDER_SERVICE_GRPC_URL=host.docker.internal:8089 \
			npm start)
	[ -f "$ONIX/Dockerfile" ] || die "the generator produced no build-output/Dockerfile"

	STEP="applying the workbench fixes to build-output"
	cat >"$ONIX/.env" <<EOF
SUBSCRIBER_ID=workbench.localhost
UNIQUE_KEY_ID=$UKID
SIGNING_PRIVATE=$SIGN_PRIVATE
SIGNING_PUBLIC=$SIGN_PUBLIC
IN_HOUSE_REGISTRY=http://host.docker.internal:5010/
IN_HOUSE_URL=http://host.docker.internal:5010/
REDIS_URL=host.docker.internal:6379
REDIS_PASSWORD=
REDIS_USERNAME=
PORT=80
SERVICE_NAME=$SERVICE_NAME
DOMAIN=$DOMAIN
DOMAIN_VERSION=$VERSION
EOF
	# The container listens on the same port it is published on, because it proxies to
	# the workbench.localhost URLs it hands out. The ONIX_* overrides are what dev.js
	# sets when the monitor fronts it; the defaults give the plain setup.
	cat >"$ONIX/docker-compose.yml" <<'EOF'
services:
  onix-server:
    platform: linux/amd64
    build:
      context: .
      dockerfile: Dockerfile
    container_name: "api-service-${SERVICE_NAME}"
    # Defaults reproduce the plain setup; scripts/dev.js overrides them when the
    # workbench monitor runs in front (publish on 127.0.0.1:8080, self-calls via the host).
    ports:
      - "${ONIX_PUBLISH:-${PORT}}:${PORT}"
    volumes:
      - ./temp/config:/app/temp/config:ro
    env_file:
      - .env
    extra_hosts:
      - "workbench.localhost:${ONIX_SELF_HOST:-127.0.0.1}"
    environment:
      MOCK_SERVER_URL: "${ONIX_MOCK_SERVER_URL:-http://host.docker.internal:5004/mock}"
      RECORDER_SERVICE_GRPC_URL: "${ONIX_RECORDER_GRPC_URL:-host.docker.internal:8089}"
      RECORDER_SERVICE_HTTP_URL: "${ONIX_RECORDER_HTTP_URL:-http://host.docker.internal:8090}"
      IN_HOUSE_REGISTRY: "${ONIX_REGISTRY_URL:-http://host.docker.internal:5010/}"
    networks:
      - onix-network
    restart: unless-stopped
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "wget -q -O /dev/null http://localhost:$${PORT:-3000}/health || exit 1",
        ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  onix-network:
    driver: bridge
EOF
	if [ "$OS" = Linux ]; then
		# Docker Desktop provides host.docker.internal; Docker Engine on Linux does not.
		awk '{ print } /^[[:space:]]*extra_hosts:[[:space:]]*$/ && !done { print "      - \"host.docker.internal:host-gateway\""; done = 1 }' \
			"$ONIX/docker-compose.yml" >"$ONIX/docker-compose.yml.tmp"
		mv "$ONIX/docker-compose.yml.tmp" "$ONIX/docker-compose.yml"
	fi
	ok "build-output for $DOMAIN $VERSION, with a fresh signing keypair (ukid $UKID)"
fi

# -- 7. docker images -----------------------------------------------------------------------
bold "7/7 Docker images"
if [ "$SKIP_DOCKER" = 1 ]; then
	note "--skip-docker: skipped. The first \`npm run dev\` pulls Mongo and builds the ONIX image instead"
elif [ "$DOCKER_UP" = 0 ]; then
	note "Docker is not available - skipped (re-run once it is, or let \`npm run dev\` do it)"
else
	STEP="pulling mongo:7"
	docker pull --quiet mongo:7 >/dev/null
	ok "mongo:7"
	if [ -f "$ONIX/docker-compose.yml" ]; then
		STEP="building the ONIX api-service image"
		note "building the ONIX api-service image (linux/amd64; a few minutes, longer under emulation)..."
		(cd "$ONIX" && docker compose build)
		ok "ONIX api-service image built"
	fi
fi

# -- local networking checks ---------------------------------------------------------------------
STEP="final checks"
if ! node -e 'require("dns").lookup("workbench.localhost", (e, a) => process.exit(!e && /^(127\.|::1$)/.test(a) ? 0 : 1))'; then
	warn "workbench.localhost does not resolve to loopback here - add '127.0.0.1 workbench.localhost' to /etc/hosts"
fi
if [ "$OS" = Linux ]; then
	unpriv="$(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null || echo 1024)"
	[ "$unpriv" -le 80 ] || warn "Linux: the api-service (or the monitor in front of it) binds port 80 - run: sudo sysctl net.ipv4.ip_unprivileged_port_start=80"
	warn "Linux: containers reach the host over the docker bridge, not loopback - Redis must accept those clients (run your own with --protected-mode no) for ONIX to connect"
fi

bold "Done."
if [ -n "$WARNINGS" ]; then
	printf '\n  \033[33mThings to sort out:\033[0m\n%s' "$WARNINGS"
fi
cat <<EOF

  Next:
    cd "$TARGET"
    npm run dev       # Redis, mock, backend, Vite, the workbench and the monitor - Ctrl-C stops all

    UI        http://localhost:5173
    Monitor   http://localhost:4400
    Loop      /scenario, subscriber URL https://testing; start the flow in the BAP tab first
EOF
