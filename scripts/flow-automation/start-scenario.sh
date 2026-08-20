#!/usr/bin/env bash
#
# start-scenario.sh — headless Workbench scenario testing.
#
# Reproduces exactly what the Scenario Testing UI does on its two clicks:
#   1. POST /sessions          (the "Create a new Session" form)
#   2. POST /flow/new          (the "Start" button on a flow card)
#   3. PUT  /sessions?...      (marks the flow active so the UI opens on it)
#
# No auth is involved on any of those endpoints — the session id is the
# express-session id minted by the POST itself.
#
# Usage: start-scenario.sh --help
#
set -euo pipefail

# ── exit codes ────────────────────────────────────────────────────────────────
readonly EX_USAGE=1     # bad/missing flags, missing dependency
readonly EX_INVALID=2   # domain/version/usecase/flow-id not found upstream
readonly EX_SESSION=3   # session creation failed
readonly EX_FLOW=4      # flow start failed
readonly EX_INPUTS=5    # a step needs inputs we were not given
readonly EX_TIMEOUT=6   # --drive gave up waiting

BASE_URL=""
API_BASE=""
DOMAIN=""
VERSION=""
USECASE=""
FLOW_ID=""
SUBSCRIBER_URL=""
NP_TYPE="BAP"
ENVIRONMENT="PRE-PRODUCTION"
USER_ID=""
INPUTS_FILE=""
DRY_RUN=0
JSON_OUT=0
TIMEOUT=60
DRIVE=0
DRIVE_TIMEOUT=900
POLL_INTERVAL=5
START_INPUTS="{}"   # from --inputs-file, for the flow's first step
STEPS_JSON="{}"     # from --inputs-file, keyed per step, used by --drive

usage() {
    cat <<'EOF'
start-scenario.sh — create a Workbench scenario session and start a flow, headlessly.

Required:
  --base-url URL          Workbench base URL, e.g. https://workbench.ondc.tech
  --domain DOMAIN         e.g. ONDC:RET11
  --version VERSION       e.g. 1.2.5
  --usecase USECASE       e.g. "F&B"
  --flow-id FLOW_ID       exact flow id, e.g. "SELECT FLOW"
  --subscriber-url URL    your NP subscriber URL (the np-id)

Optional:
  --np-type BAP|BPP       role you are testing as        (default: BAP)
  --env ENV               environment                    (default: PRE-PRODUCTION)
  --user-id ID            associates the session with a user
  --inputs-file FILE      values to feed the flow's input steps; see below
  --drive                 don't stop after starting — keep polling and answer every
                          input step until the flow completes
  --drive-timeout SECONDS give up driving after this long (default: 900)
  --poll-interval SECONDS how often to poll while driving   (default: 5)
  --api-base URL          override the backend base (default: <base-url>/backend-ui,
                          falling back to <base-url> for local dev)
  --timeout SECONDS       per-request timeout            (default: 60)
  --dry-run               validate inputs, create nothing
  --json                  print a single JSON result on stdout instead of prose
  -h, --help              this message

--inputs-file format (either shape is accepted):

  {"inputs": ..., "json_path_changes": ...}          # the first step only

  {"start": {"inputs": ..., "json_path_changes": ...},
   "steps": {                                        # later steps, --drive only
     "<actionId>":   {"inputs": ..., "json_path_changes": ...},
     "<actionType>": {"inputs": ...}                 # fallback if no actionId match
   }}

Everything under "inputs"/"json_path_changes" is passed through verbatim; the shape
is flow- and step-specific. Run without a value once and the error prints the exact
config the step is asking for.

Exit codes:
  0 ok  1 usage  2 invalid domain/version/usecase/flow-id
  3 session creation failed  4 flow start failed
  5 a step needs inputs that were not supplied  6 --drive timed out

Example:
  start-scenario.sh --base-url https://workbench.ondc.tech \
    --domain ONDC:RET11 --version 1.2.5 --usecase "F&B" \
    --flow-id "BUYER INSTRUCTIONS AND ADDRESS UPDATE FLOW" \
    --subscriber-url https://my-np.example.com --np-type BAP
EOF
}

# Progress goes to stderr so --json keeps stdout machine-parseable.
log()  { [[ $JSON_OUT -eq 1 ]] || printf '%s\n' "$*" >&2; }
warn() { printf 'warning: %s\n' "$*" >&2; }

# fail <exit-code> <stage> <message> [http-status] [response-body]
fail() {
    local code="$1" stage="$2" msg="$3" status="${4:-}" body="${5:-}"
    if [[ $JSON_OUT -eq 1 ]]; then
        jq -n --arg stage "$stage" --arg message "$msg" \
              --arg status "$status" --arg body "$body" \
              '{ok: false, stage: $stage, message: $message}
               + (if $status == "" then {} else {status: ($status | tonumber)} end)
               + (if $body   == "" then {} else {response: $body} end)'
    else
        printf 'ERROR [%s]: %s\n' "$stage" "$msg" >&2
        [[ -n $status ]] && printf '  http status: %s\n' "$status" >&2
        [[ -n $body   ]] && printf '  response:    %s\n' "$body" >&2
    fi
    exit "$code"
}

need_value() {
    [[ $# -ge 2 && -n ${2:-} ]] || { printf 'ERROR: %s requires a value\n\n' "$1" >&2; usage >&2; exit $EX_USAGE; }
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base-url)       need_value "$1" "${2:-}"; BASE_URL="$2";       shift 2 ;;
        --api-base)       need_value "$1" "${2:-}"; API_BASE="$2";       shift 2 ;;
        --domain)         need_value "$1" "${2:-}"; DOMAIN="$2";         shift 2 ;;
        --version)        need_value "$1" "${2:-}"; VERSION="$2";        shift 2 ;;
        --usecase)        need_value "$1" "${2:-}"; USECASE="$2";        shift 2 ;;
        --flow-id)        need_value "$1" "${2:-}"; FLOW_ID="$2";        shift 2 ;;
        --subscriber-url) need_value "$1" "${2:-}"; SUBSCRIBER_URL="$2"; shift 2 ;;
        --np-type)        need_value "$1" "${2:-}"; NP_TYPE="$2";        shift 2 ;;
        --env)            need_value "$1" "${2:-}"; ENVIRONMENT="$2";    shift 2 ;;
        --user-id)        need_value "$1" "${2:-}"; USER_ID="$2";        shift 2 ;;
        --inputs-file)    need_value "$1" "${2:-}"; INPUTS_FILE="$2";    shift 2 ;;
        --timeout)        need_value "$1" "${2:-}"; TIMEOUT="$2";        shift 2 ;;
        --drive-timeout)  need_value "$1" "${2:-}"; DRIVE_TIMEOUT="$2";  shift 2 ;;
        --poll-interval)  need_value "$1" "${2:-}"; POLL_INTERVAL="$2";  shift 2 ;;
        --drive)          DRIVE=1;    shift ;;
        --dry-run)        DRY_RUN=1;  shift ;;
        --json)           JSON_OUT=1; shift ;;
        -h|--help)        usage; exit 0 ;;
        *) printf 'ERROR: unknown argument: %s\n\n' "$1" >&2; usage >&2; exit $EX_USAGE ;;
    esac
done

# ── preflight ─────────────────────────────────────────────────────────────────
for dep in curl jq; do
    command -v "$dep" >/dev/null 2>&1 || {
        printf 'ERROR: %s is required but not installed.\n' "$dep" >&2
        exit $EX_USAGE
    }
done

missing=()
[[ -n $BASE_URL       ]] || missing+=("--base-url")
[[ -n $DOMAIN         ]] || missing+=("--domain")
[[ -n $VERSION        ]] || missing+=("--version")
[[ -n $USECASE        ]] || missing+=("--usecase")
[[ -n $FLOW_ID        ]] || missing+=("--flow-id")
[[ -n $SUBSCRIBER_URL ]] || missing+=("--subscriber-url")
if [[ ${#missing[@]} -gt 0 ]]; then
    printf 'ERROR: missing required argument(s): %s\n\n' "${missing[*]}" >&2
    usage >&2
    exit $EX_USAGE
fi

case "$NP_TYPE" in
    BAP|BPP) ;;
    *) printf 'ERROR: --np-type must be BAP or BPP (got: %s)\n' "$NP_TYPE" >&2; exit $EX_USAGE ;;
esac

for pair in "--timeout:$TIMEOUT" "--drive-timeout:$DRIVE_TIMEOUT" "--poll-interval:$POLL_INTERVAL"; do
    [[ ${pair#*:} =~ ^[0-9]+$ ]] || { printf 'ERROR: %s must be a whole number of seconds\n' "${pair%%:*}" >&2; exit $EX_USAGE; }
done
(( POLL_INTERVAL > 0 )) || { printf 'ERROR: --poll-interval must be at least 1\n' >&2; exit $EX_USAGE; }

if [[ -n $INPUTS_FILE ]]; then
    [[ -f $INPUTS_FILE ]] || { printf 'ERROR: --inputs-file not found: %s\n' "$INPUTS_FILE" >&2; exit $EX_USAGE; }
    jq -e 'type == "object"' "$INPUTS_FILE" >/dev/null 2>&1 \
        || { printf 'ERROR: --inputs-file must be a JSON object: %s\n' "$INPUTS_FILE" >&2; exit $EX_USAGE; }
    # Two accepted shapes: {start, steps} for the full form, or a bare
    # {inputs, json_path_changes} which means "the first step only".
    if jq -e 'has("start") or has("steps")' "$INPUTS_FILE" >/dev/null; then
        START_INPUTS=$(jq -c '.start // {}' "$INPUTS_FILE")
        STEPS_JSON=$(jq -c '.steps // {}' "$INPUTS_FILE")
    else
        START_INPUTS=$(jq -c '.' "$INPUTS_FILE")
    fi
fi

if [[ $DRIVE -eq 0 ]] && [[ $(jq -r 'length' <<<"$STEPS_JSON") != "0" ]]; then
    warn "--inputs-file has a \"steps\" section but --drive was not passed; later steps will not be answered"
fi

# The UI strips trailing slashes off the subscriber URL before creating the session
# (pages/scenario/index.tsx createAndOpenSession) — a trailing slash there produces
# double-slashed callback URLs downstream.
BASE_URL="${BASE_URL%"${BASE_URL##*[!/]}"}"
SUBSCRIBER_URL="${SUBSCRIBER_URL%"${SUBSCRIBER_URL##*[!/]}"}"

# ── http helper ───────────────────────────────────────────────────────────────
# Every call funnels through here. Sets HTTP_STATUS and HTTP_BODY.
# api <METHOD> <url> [curl args...]
HTTP_STATUS=""
HTTP_BODY=""
api() {
    local method="$1" url="$2"; shift 2
    local raw
    # --write-out appends the status on its own trailing line; -sS keeps curl quiet
    # but still lets transport errors through to stderr.
    if ! raw=$(curl -sS --max-time "$TIMEOUT" -X "$method" "$url" \
                    -w $'\n%{http_code}' "$@" 2>/dev/null); then
        HTTP_STATUS="000"
        HTTP_BODY=""
        return 1
    fi
    HTTP_STATUS="${raw##*$'\n'}"
    HTTP_BODY="${raw%$'\n'*}"
    return 0
}

# ── resolve the API base ──────────────────────────────────────────────────────
# Prod serves the backend under <base>/backend-ui (the value baked into the SPA's
# VITE_BACKEND_URL); a local dev backend answers bare on its own port.
probe_api_base() {
    local candidate
    for candidate in "$1/backend-ui" "$1"; do
        if api GET "$candidate/config/senarioFormData" && [[ $HTTP_STATUS == "200" ]]; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

if [[ -z $API_BASE ]]; then
    log "→ resolving API base under $BASE_URL ..."
    if ! API_BASE=$(probe_api_base "$BASE_URL"); then
        fail $EX_INVALID "api-base" \
            "Could not reach the Workbench backend under $BASE_URL (tried $BASE_URL/backend-ui and $BASE_URL). Check --base-url, or pass --api-base explicitly."
    fi
else
    API_BASE="${API_BASE%"${API_BASE##*[!/]}"}"
fi
log "  API base: $API_BASE"

# ── step 1: validate domain / version / usecase ───────────────────────────────
log "→ validating domain / version / usecase ..."
api GET "$API_BASE/config/senarioFormData" \
    || fail $EX_INVALID "validate" "Request to $API_BASE/config/senarioFormData failed (network/timeout)."
[[ $HTTP_STATUS == "200" ]] \
    || fail $EX_INVALID "validate" "Could not fetch scenario form data." "$HTTP_STATUS" "$HTTP_BODY"

FORM_DATA="$HTTP_BODY"
jq -e '.domain | type == "array"' <<<"$FORM_DATA" >/dev/null 2>&1 \
    || fail $EX_INVALID "validate" "Unexpected scenario form data shape from $API_BASE/config/senarioFormData." "$HTTP_STATUS" "$HTTP_BODY"

if ! jq -e --arg d "$DOMAIN" '.domain[] | select(.key == $d)' <<<"$FORM_DATA" >/dev/null; then
    valid=$(jq -r '[.domain[].key] | join(", ")' <<<"$FORM_DATA")
    fail $EX_INVALID "validate" "Unknown domain '$DOMAIN'. Available domains: $valid"
fi

if ! jq -e --arg d "$DOMAIN" --arg v "$VERSION" \
        '.domain[] | select(.key == $d) | .version[] | select(.key == $v)' <<<"$FORM_DATA" >/dev/null; then
    valid=$(jq -r --arg d "$DOMAIN" '[.domain[] | select(.key == $d) | .version[].key] | join(", ")' <<<"$FORM_DATA")
    fail $EX_INVALID "validate" "Unknown version '$VERSION' for domain '$DOMAIN'. Available versions: $valid"
fi

if ! jq -e --arg d "$DOMAIN" --arg v "$VERSION" --arg u "$USECASE" \
        '.domain[] | select(.key == $d) | .version[] | select(.key == $v) | .usecase[] | select(. == $u)' \
        <<<"$FORM_DATA" >/dev/null; then
    valid=$(jq -r --arg d "$DOMAIN" --arg v "$VERSION" \
        '[.domain[] | select(.key == $d) | .version[] | select(.key == $v) | .usecase[]] | join(", ")' <<<"$FORM_DATA")
    fail $EX_INVALID "validate" "Unknown usecase '$USECASE' for $DOMAIN $VERSION. Available usecases: $valid"
fi
log "  domain/version/usecase ok"

# ── step 2: validate the flow id ──────────────────────────────────────────────
log "→ validating flow id ..."
api GET "$API_BASE/config/flows" -G \
    --data-urlencode "domain=$DOMAIN" \
    --data-urlencode "version=$VERSION" \
    --data-urlencode "usecase=$USECASE" \
    || fail $EX_INVALID "validate-flow" "Request to $API_BASE/config/flows failed (network/timeout)."
[[ $HTTP_STATUS == "200" ]] \
    || fail $EX_INVALID "validate-flow" "Could not fetch flows for $DOMAIN $VERSION / $USECASE." "$HTTP_STATUS" "$HTTP_BODY"

FLOWS="$HTTP_BODY"
jq -e '.data.flows | type == "array"' <<<"$FLOWS" >/dev/null 2>&1 \
    || fail $EX_INVALID "validate-flow" "Unexpected flows response shape." "$HTTP_STATUS" "$HTTP_BODY"

if ! jq -e --arg f "$FLOW_ID" '.data.flows[] | select(.id == $f)' <<<"$FLOWS" >/dev/null; then
    valid=$(jq -r '.data.flows[].id | "  - " + .' <<<"$FLOWS")
    fail $EX_INVALID "validate-flow" "$(printf "Unknown flow-id '%s' for %s %s / %s. Available flows:\n%s" \
        "$FLOW_ID" "$DOMAIN" "$VERSION" "$USECASE" "$valid")"
fi
log "  flow id ok"

# ── step 2b: flow permission ──────────────────────────────────────────────────
# Mirrors canStartFlow() in FlowRunAccordion: when we are the BAP and the flow's
# first step is one Workbench expects to receive, another live session may already
# hold that expectation on this subscriber URL. Without this check the failure
# surfaces later as an opaque 500 from /flow/new. Checked before session creation
# so a blocked run leaves no orphan session behind.
FIRST_ACTION=$(jq -r --arg f "$FLOW_ID" \
    '.data.flows[] | select(.id == $f) | .sequence[0] | if (.expect == true) then (.type // .key // "") else "" end' \
    <<<"$FLOWS")

if [[ $NP_TYPE == "BAP" && -n $FIRST_ACTION ]]; then
    log "→ checking flow permission for '$FIRST_ACTION' on the subscriber URL ..."
    if api GET "$API_BASE/sessions/flowPermission" -G \
            --data-urlencode "action=$FIRST_ACTION" \
            --data-urlencode "subscriber_url=$SUBSCRIBER_URL" \
       && [[ $HTTP_STATUS == "200" ]]; then
        if [[ $(jq -r '.valid // true' <<<"$HTTP_BODY") == "false" ]]; then
            reason=$(jq -r '.message // "no reason given"' <<<"$HTTP_BODY")
            fail $EX_INVALID "flow-permission" \
                "Cannot start '$FLOW_ID' right now: $reason. Another session is already waiting for '$FIRST_ACTION' on this subscriber URL — expectations expire after ~5 minutes, or use a different subscriber URL."
        fi
        log "  permission ok"
    else
        warn "flow permission check did not answer (http $HTTP_STATUS) — continuing anyway"
    fi
fi

# ── dry-run stop point ────────────────────────────────────────────────────────
if [[ $DRY_RUN -eq 1 ]]; then
    if [[ $JSON_OUT -eq 1 ]]; then
        jq -n --arg apiBase "$API_BASE" --arg domain "$DOMAIN" --arg version "$VERSION" \
              --arg usecase "$USECASE" --arg flowId "$FLOW_ID" \
              --arg subscriberUrl "$SUBSCRIBER_URL" --arg npType "$NP_TYPE" --arg env "$ENVIRONMENT" \
              '{ok: true, dryRun: true, apiBase: $apiBase, domain: $domain, version: $version,
                usecase: $usecase, flowId: $flowId, subscriberUrl: $subscriberUrl,
                npType: $npType, env: $env}'
    else
        cat <<EOF
Dry run — all inputs validated, nothing created.

  api base       : $API_BASE
  domain         : $DOMAIN
  version        : $VERSION
  usecase        : $USECASE
  flow id        : $FLOW_ID
  subscriber url : $SUBSCRIBER_URL
  np type        : $NP_TYPE
  env            : $ENVIRONMENT
EOF
    fi
    exit 0
fi

# ── step 3: create the session ────────────────────────────────────────────────
log "→ creating session ..."
# difficulty_cache mirrors what the UI sends. The backend currently ignores it and
# applies its own defaults, but we keep parity in case that changes.
session_payload=$(jq -n \
    --arg subscriberUrl "$SUBSCRIBER_URL" \
    --arg domain "$DOMAIN" \
    --arg version "$VERSION" \
    --arg usecaseId "$USECASE" \
    --arg npType "$NP_TYPE" \
    --arg env "$ENVIRONMENT" \
    --arg userId "$USER_ID" \
    '{subscriberUrl: $subscriberUrl, domain: $domain, version: $version,
      usecaseId: $usecaseId, npType: $npType, env: $env,
      difficulty_cache: {stopAfterFirstNack: true, timeValidations: true,
                         protocolValidations: true, useGateway: true, headerValidaton: true}}
     + (if $userId == "" then {} else {userId: $userId} end)')

api POST "$API_BASE/sessions" -H "Content-Type: application/json" --data-binary "$session_payload" \
    || fail $EX_SESSION "create-session" "Request to $API_BASE/sessions failed (network/timeout)."
[[ $HTTP_STATUS == "201" ]] \
    || fail $EX_SESSION "create-session" "Session creation failed." "$HTTP_STATUS" "$HTTP_BODY"

SESSION_ID=$(jq -r '.sessionId // empty' <<<"$HTTP_BODY")
[[ -n $SESSION_ID ]] \
    || fail $EX_SESSION "create-session" "Session creation returned no sessionId." "$HTTP_STATUS" "$HTTP_BODY"
log "  session id: $SESSION_ID"

# ── step 4: confirm the flow made it into the session ─────────────────────────
# The session's flowConfigs come from the config service at creation time; this
# catches drift between the /config/flows check above and the session itself.
log "→ verifying flow is present in the session ..."
api GET "$API_BASE/sessions" -G --data-urlencode "session_id=$SESSION_ID" \
    || fail $EX_SESSION "verify-session" "Could not read back session $SESSION_ID (network/timeout)."
[[ $HTTP_STATUS == "200" ]] \
    || fail $EX_SESSION "verify-session" "Could not read back session $SESSION_ID." "$HTTP_STATUS" "$HTTP_BODY"

if ! jq -e --arg f "$FLOW_ID" '.flowConfigs | has($f)' <<<"$HTTP_BODY" >/dev/null 2>&1; then
    present=$(jq -r '(.flowConfigs // {}) | keys | join(", ")' <<<"$HTTP_BODY" 2>/dev/null || echo "<none>")
    fail $EX_SESSION "verify-session" \
        "Flow '$FLOW_ID' is not in session $SESSION_ID. Flows in the session: $present"
fi
log "  flow present"

# ── step 5: start the flow ────────────────────────────────────────────────────
new_uuid() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    elif [[ -r /proc/sys/kernel/random/uuid ]]; then
        cat /proc/sys/kernel/random/uuid
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import uuid; print(uuid.uuid4())'
    else
        return 1
    fi
}

TRANSACTION_ID=$(new_uuid) \
    || fail $EX_FLOW "start-flow" "No way to generate a uuid (need uuidgen, /proc/sys/kernel/random/uuid, or python3)."

log "→ starting flow (transaction $TRANSACTION_ID) ..."
flow_payload=$(jq -n \
    --arg session_id "$SESSION_ID" \
    --arg flow_id "$FLOW_ID" \
    --arg transaction_id "$TRANSACTION_ID" \
    '{session_id: $session_id, flow_id: $flow_id, transaction_id: $transaction_id}')

# Merge the caller's start inputs / json_path_changes over the base body.
flow_payload=$(jq -n --argjson base "$flow_payload" --argjson extra "$START_INPUTS" \
    '$base + ($extra | {inputs, json_path_changes} | with_entries(select(.value != null)))')

api POST "$API_BASE/flow/new" -H "Content-Type: application/json" --data-binary "$flow_payload" \
    || fail $EX_FLOW "start-flow" "Request to $API_BASE/flow/new failed (network/timeout)."
if [[ ! $HTTP_STATUS =~ ^2 ]]; then
    hint=""
    # The mock service keeps per-subscriber-URL state; a flow already armed on this
    # URL makes it 500 with a bare "Internal Server Error" and no further detail.
    [[ $HTTP_STATUS =~ ^5 ]] && hint=" This is usually another flow already armed on '$SUBSCRIBER_URL' — finish or abandon it (expectations lapse after ~5 minutes), or use a different subscriber URL."
    fail $EX_FLOW "start-flow" \
        "Flow '$FLOW_ID' did not start (session $SESSION_ID).$hint" "$HTTP_STATUS" "$HTTP_BODY"
fi

FLOW_RESPONSE="$HTTP_BODY"

# A flow that needs inputs answers 2xx with an `inputs` form config instead of
# starting — the UI opens a form here, so headless cannot proceed without values.
if jq -e '(.inputs // []) | length > 0' <<<"$FLOW_RESPONSE" >/dev/null 2>&1; then
    if [[ $JSON_OUT -eq 1 ]]; then
        jq -n --arg sessionId "$SESSION_ID" --arg flowId "$FLOW_ID" \
              --argjson inputs "$(jq '.inputs' <<<"$FLOW_RESPONSE")" \
              '{ok: false, stage: "start-flow", message: "Flow requires inputs and was not started. Re-run with --inputs-file.",
                sessionId: $sessionId, flowId: $flowId, requiredInputs: $inputs}'
    else
        {
            printf 'ERROR [start-flow]: flow "%s" requires inputs and was NOT started.\n' "$FLOW_ID"
            printf '  session id: %s\n' "$SESSION_ID"
            printf '  required input fields:\n'
            jq -r '.inputs[] | "    - " + ((.name // .type // "?") | tostring)' <<<"$FLOW_RESPONSE" 2>/dev/null \
                || printf '    (could not parse field names)\n'
            printf '\n  Re-run with --inputs-file FILE, where FILE looks like:\n'
            printf '    {"inputs": { "<field-name>": "<value>" }, "json_path_changes": {}}\n\n'
            printf '  Full input config:\n'
            jq '.inputs' <<<"$FLOW_RESPONSE"
        } >&2
    fi
    exit $EX_INPUTS
fi

# Some mock responses are 200-with-success:false; surface that rather than claiming success.
if jq -e 'has("success") and (.success == false)' <<<"$FLOW_RESPONSE" >/dev/null 2>&1; then
    msg=$(jq -r '.message // "no message"' <<<"$FLOW_RESPONSE")
    fail $EX_FLOW "start-flow" "Flow start was rejected: $msg" "$HTTP_STATUS" "$FLOW_RESPONSE"
fi
log "  flow started"

# ── step 6: mark the flow active (best effort) ────────────────────────────────
# Purely so the session page opens on this flow, exactly as the UI does after Start.
# session_id goes in the URL rather than via -G: curl's -G would fold --data-binary
# into the query string and send an empty body.
active_payload=$(jq -n --arg flowId "$FLOW_ID" '{activeFlow: $flowId, activeStep: 1}')
encoded_session=$(jq -rn --arg s "$SESSION_ID" '$s | @uri')
if ! api PUT "$API_BASE/sessions?session_id=$encoded_session" \
        -H "Content-Type: application/json" --data-binary "$active_payload" \
    || [[ ! $HTTP_STATUS =~ ^2 ]]; then
    warn "could not mark '$FLOW_ID' as the active flow (http $HTTP_STATUS) — the flow is running regardless"
fi

# ── step 7: drive the rest of the flow (--drive) ──────────────────────────────
# Mirrors what the session page does while it is open: poll the mapped flow, and
# whenever a step is waiting on input, answer it. Steps whose input config is empty
# are auto-submitted (the UI does the same); steps with a real form need a matching
# entry under "steps" in --inputs-file.
DRIVE_STATUS="not-driven"
DRIVE_TX=""
STEPS_ANSWERED=0

# jq program that picks the step to answer, mirroring MappedFlow/index.tsx:196.
# Sequence steps win over extras; the first sequence step is the flow's own trigger
# and is never a target. `_extraKey` is set only for extra steps, which advance via
# `trigger_extra` rather than a plain proceed.
readonly TARGET_JQ='
  ([ .sequence // [] | to_entries[] | select(.key != 0) | .value
     | select(.status == "INPUT-REQUIRED"
           or (.status == "WAITING-SUBMISSION"
               and ((.input // []) | any(.type == "MANUAL_DYNAMIC_FORM")))) ] | first) as $seq
  | ([ (.extraSteps // [])[] | select(.status == "INPUT-REQUIRED") ] | first) as $extra
  | if   $seq   != null then $seq   + {_extraKey: null}
    elif $extra != null then $extra + {_extraKey: $extra.actionId}
    else empty end'

drive_flow() {
    local started=$SECONDS
    local tx="" last_sig="" waited_msg=0 state target forced
    local action_id action_type label conf_len extra_key sig entry proceed_payload

    while (( SECONDS - started < DRIVE_TIMEOUT )); do
        # The real transaction id is the one on the session: for a flow the
        # counterparty initiates, it comes off their payload, not the id we sent.
        if [[ -z $tx ]]; then
            if api GET "$API_BASE/sessions" -G --data-urlencode "session_id=$SESSION_ID" \
               && [[ $HTTP_STATUS == "200" ]]; then
                tx=$(jq -r --arg f "$FLOW_ID" '.flowMap[$f] // empty' <<<"$HTTP_BODY")
            fi
            if [[ -z $tx ]]; then
                (( waited_msg )) || { log "  waiting for the first payload on $SUBSCRIBER_URL ..."; waited_msg=1; }
                sleep "$POLL_INTERVAL"
                continue
            fi
            DRIVE_TX="$tx"
            log "  transaction: $tx"
        fi

        if ! api GET "$API_BASE/flow/current-state" -G \
                --data-urlencode "session_id=$SESSION_ID" \
                --data-urlencode "transaction_id=$tx" \
           || [[ $HTTP_STATUS != "200" ]]; then
            sleep "$POLL_INTERVAL"
            continue
        fi
        state="$HTTP_BODY"

        if jq -e '(.sequence | length) > 0 and (all(.sequence[]; .status == "COMPLETE"))' \
             <<<"$state" >/dev/null 2>&1; then
            DRIVE_STATUS="completed"
            return 0
        fi

        # The session page also nudges a RESPONDING step flagged force_proceed
        # (MappedFlow/index.tsx:265). Without this a driven flow stalls on one.
        forced=$(jq -r '([.sequence[] | select(.status == "RESPONDING")] | first) as $r
                        | if ($r != null and $r.force_proceed == true) then ($r.actionId // "-") else "" end' \
                    <<<"$state" 2>/dev/null || true)
        if [[ -n $forced && "force:$forced" != "$last_sig" ]]; then
            log "  → $forced: force-proceeding"
            if api POST "$API_BASE/flow/proceed" -H "Content-Type: application/json" \
                    --data-binary "$(jq -n --arg s "$SESSION_ID" --arg t "$tx" \
                        '{session_id: $s, transaction_id: $t}')" \
               && [[ $HTTP_STATUS =~ ^2 ]]; then
                last_sig="force:$forced"
            fi
            sleep "$POLL_INTERVAL"
            continue
        fi

        target=$(jq -c "$TARGET_JQ" <<<"$state" 2>/dev/null || true)
        if [[ -z $target ]]; then
            sleep "$POLL_INTERVAL"
            continue
        fi

        action_id=$(jq -r '.actionId // ""'   <<<"$target")
        action_type=$(jq -r '.actionType // ""' <<<"$target")
        label=$(jq -r '.label // .actionType // .actionId // "?"' <<<"$target")
        extra_key=$(jq -r '._extraKey // ""'  <<<"$target")
        conf_len=$(jq -r '(.input // []) | length' <<<"$target")

        # The backend keeps reporting a step as INPUT-REQUIRED for a poll or two after
        # we answer it; don't resubmit the same step in the same status.
        sig="$action_id|$(jq -r '.status' <<<"$target")"
        if [[ $sig == "$last_sig" ]]; then
            sleep "$POLL_INTERVAL"
            continue
        fi

        if [[ $conf_len == "0" ]]; then
            entry='{}'
            log "  → $label: no input needed, advancing"
        else
            # actionId first, then actionType so one entry can cover a repeated action.
            entry=$(jq -c --arg id "$action_id" --arg type "$action_type" \
                        '.[$id] // .[$type] // empty' <<<"$STEPS_JSON")
            if [[ -z $entry ]]; then
                if [[ $JSON_OUT -eq 1 ]]; then
                    jq -n --arg sessionId "$SESSION_ID" --arg tx "$tx" --arg flowId "$FLOW_ID" \
                          --arg actionId "$action_id" --arg actionType "$action_type" \
                          --arg label "$label" --argjson step "$target" \
                          --arg url "$BASE_URL/flow-testing?sessionId=$SESSION_ID" \
                          '{ok: false, stage: "drive", message: "Step needs inputs that were not supplied.",
                            sessionId: $sessionId, transactionId: $tx, flowId: $flowId,
                            step: {actionId: $actionId, actionType: $actionType, label: $label},
                            requiredInputs: ($step.input // []), url: $url}'
                else
                    {
                        printf 'ERROR [drive]: step "%s" needs inputs and none were supplied.\n' "$label"
                        printf '  actionId   : %s\n' "$action_id"
                        printf '  actionType : %s\n' "$action_type"
                        printf '\n  Add it under "steps" in --inputs-file:\n'
                        printf '    {"steps": {"%s": {"inputs": { ... }}}}\n\n' "$action_id"
                        printf '  Config this step is asking for:\n'
                        jq '.input' <<<"$target"
                        printf '\n  Or answer it by hand at: %s\n' "$SESSION_URL_HINT"
                    } >&2
                fi
                exit $EX_INPUTS
            fi
            log "  → $label: submitting supplied inputs"
        fi

        # Extra steps advance with `trigger_extra`; sequence steps with a plain proceed.
        proceed_payload=$(jq -n --arg s "$SESSION_ID" --arg t "$tx" --arg k "$extra_key" \
            --argjson entry "$entry" \
            '{session_id: $s, transaction_id: $t,
              inputs: ($entry.inputs // {}),
              json_path_changes: ($entry.json_path_changes // {})}
             + (if $k == "" then {} else {trigger_extra: $k} end)')

        if ! api POST "$API_BASE/flow/proceed" -H "Content-Type: application/json" \
                --data-binary "$proceed_payload" \
           || [[ ! $HTTP_STATUS =~ ^2 ]]; then
            warn "step '$label' did not accept the submission (http $HTTP_STATUS): $HTTP_BODY"
        else
            STEPS_ANSWERED=$((STEPS_ANSWERED + 1))
            last_sig="$sig"
        fi

        sleep "$POLL_INTERVAL"
    done

    DRIVE_STATUS="timed-out"
    return 1
}

# Same URL the UI opens after session creation (pages/scenario/index.tsx).
encoded_sub_hint=$(jq -rn --arg u "$SUBSCRIBER_URL" '$u | @uri')
SESSION_URL_HINT="$BASE_URL/flow-testing?sessionId=$SESSION_ID&subscriberUrl=$encoded_sub_hint&role=$NP_TYPE"

if [[ $DRIVE -eq 1 ]]; then
    log "→ driving the flow (timeout ${DRIVE_TIMEOUT}s, polling every ${POLL_INTERVAL}s) ..."
    if drive_flow; then
        log "  flow completed ($STEPS_ANSWERED step(s) answered)"
    else
        fail $EX_TIMEOUT "drive" \
            "Gave up after ${DRIVE_TIMEOUT}s — the flow did not complete. $STEPS_ANSWERED step(s) were answered; session $SESSION_ID is still live at $SESSION_URL_HINT"
    fi
fi

# ── report ────────────────────────────────────────────────────────────────────
encoded_sub=$(jq -rn --arg u "$SUBSCRIBER_URL" '$u | @uri')
SESSION_URL="$BASE_URL/flow-testing?sessionId=$SESSION_ID&subscriberUrl=$encoded_sub&role=$NP_TYPE"

# Once traffic arrives the session's own transaction id supersedes the one we sent.
REPORT_TX="${DRIVE_TX:-$TRANSACTION_ID}"

if [[ $JSON_OUT -eq 1 ]]; then
    jq -n --arg sessionId "$SESSION_ID" --arg transactionId "$REPORT_TX" \
          --arg flowId "$FLOW_ID" --arg url "$SESSION_URL" \
          --arg domain "$DOMAIN" --arg version "$VERSION" --arg usecase "$USECASE" \
          --arg subscriberUrl "$SUBSCRIBER_URL" --arg npType "$NP_TYPE" \
          --arg driveStatus "$DRIVE_STATUS" --argjson stepsAnswered "$STEPS_ANSWERED" \
          '{ok: true, sessionId: $sessionId, transactionId: $transactionId, flowId: $flowId,
            domain: $domain, version: $version, usecase: $usecase,
            subscriberUrl: $subscriberUrl, npType: $npType, url: $url,
            driveStatus: $driveStatus}
           + (if $driveStatus == "not-driven" then {} else {stepsAnswered: $stepsAnswered} end)'
else
    if [[ $DRIVE_STATUS == "completed" ]]; then
        printf '\nFlow completed (%s step(s) answered).\n\n' "$STEPS_ANSWERED"
    else
        printf '\nFlow started.\n\n'
    fi
    cat <<EOF
  session id     : $SESSION_ID
  transaction id : $REPORT_TX
  flow           : $FLOW_ID
  subscriber url : $SUBSCRIBER_URL ($NP_TYPE)
  open           : $SESSION_URL
EOF
fi
