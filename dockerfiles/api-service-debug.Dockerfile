# Debug build of the generated ONIX api-service.
#
# Differs from api-service/build-output/Dockerfile in three ways:
#   1. Plugins are compiled with -gcflags "all=-N -l" (no optimisation, no
#      inlining) so Delve can map frames to source and show real variables.
#   2. Delve is installed into the runtime image (the ONIX base is Debian 13
#      and already ships Go at /usr/local/go/bin/go, so this is cheap).
#   3. The server runs under `dlv exec --headless` on :2345 instead of directly.
#
# Build context is api-service/build-output/ — the same as the normal build.
# Kept in dockerfiles/ rather than build-output/ because the generator wipes
# build-output/ on every regeneration (rm -rf build-output).
#
# Driven by: scripts/debug-api-service.sh

# ── Stage 1: plugins, built for debugging ────────────────────────────────────
FROM golang:1.25.5 AS plugin-builder

WORKDIR /temp
COPY temp/ .

WORKDIR /temp/automation-beckn-plugins

# -N disables optimisation, -l disables inlining. Without these, Delve shows
# "optimized out" for most locals and breakpoints land on the wrong lines.
# Go plugins must be built with flags consistent with the host binary, so the
# server is rebuilt with the same flags in stage 2.
ENV GOFLAGS="-gcflags=all=-N -l"

RUN chmod +x buildplugins.sh && ./buildplugins.sh /plugins

# ── Stage 2: ONIX server + Delve ─────────────────────────────────────────────
FROM ghcr.io/ondc-official/automation-beckn-onix:latest

WORKDIR /workspace/app

ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"
ENV GOFLAGS="-gcflags=all=-N -l"
ENV GOCACHE=/tmp/.gocache
ENV GOPATH=/root/go

# Delve, pinned to match the host install (dlv 1.27.2) so the remote-attach
# client and server speak the same API version. If you upgrade your local dlv,
# bump this to match.
RUN go install github.com/go-delve/delve/cmd/dlv@v1.27.2

# Rebuild the server unoptimised so its frames are debuggable too, and so the
# build flags match the plugins above. The base image ships full source.
RUN if [ -f go.mod ] && [ -d cmd ]; then \
      go build -gcflags="all=-N -l" -o server ./cmd/... 2>/dev/null \
      || echo "[debug-image] server rebuild skipped; using shipped binary"; \
    fi

COPY --from=plugin-builder /plugins ./plugins
COPY temp/schemas  ./schemas
COPY temp/config   ./config

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 7039 2345

# --continue + --accept-multiclient: the server starts immediately and keeps
# running when the debugger detaches, so the stack stays usable either way.
# Drop --continue if you need to break before initialisation.
ENTRYPOINT ["dlv", "exec", "./server", \
            "--headless", \
            "--listen=:2345", \
            "--api-version=2", \
            "--accept-multiclient", \
            "--continue", \
            "--log", \
            "--"]
CMD ["--config=./config/adapter.yaml"]
