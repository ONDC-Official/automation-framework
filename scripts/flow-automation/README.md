# `start-scenario.sh`

Runs a Workbench scenario test from the command line — creates the session and starts the
flow for you, with no browser involved.

## Prerequisites

`bash`, `curl`, and `jq`.

```bash
brew install jq        # macOS
apt-get install jq     # Debian/Ubuntu
```

## Quick start

```bash
./scripts/start-scenario.sh \
  --base-url https://workbench.ondc.tech \
  --domain ONDC:RET11 \
  --version 1.2.5 \
  --usecase "F&B" \
  --flow-id FULL_CATALOG \
  --subscriber-url https://my-np.example.com \
  --np-type BAP
```

On success it prints the session id, the transaction id, and a URL you can open to watch
the run:

```
Flow started.

  session id     : SwiVv2Yv5O_57eR41beUav2_8TbgDYNY
  transaction id : ac26926a-610e-4421-af43-1c781c6d74f4
  flow           : FULL_CATALOG
  subscriber url : https://my-np.example.com (BAP)
  open           : https://workbench.ondc.tech/flow-testing?sessionId=...&role=BAP
```

The flow is now armed and waiting for traffic from your subscriber URL.

## Options

| Flag                        | Required | Default            | Notes                                                                         |
| --------------------------- | -------- | ------------------ | ----------------------------------------------------------------------------- |
| `--base-url URL`          | ✅       | —                 | e.g.`https://workbench.ondc.tech`                                           |
| `--domain DOMAIN`         | ✅       | —                 | e.g.`ONDC:RET11`                                                            |
| `--version VERSION`       | ✅       | —                 | e.g.`1.2.5`                                                                 |
| `--usecase USECASE`       | ✅       | —                 | quote it — many contain spaces or`&`                                       |
| `--flow-id FLOW_ID`       | ✅       | —                 | exact id, quote it                                                            |
| `--subscriber-url URL`    | ✅       | —                 | your NP's subscriber URL                                                      |
| `--np-type BAP\|BPP`       |          | `BAP`            | the role**you** are testing as                                          |
| `--env ENV`               |          | `PRE-PRODUCTION` |                                                                               |
| `--user-id ID`            |          | —                 | tags the session with a user                                                  |
| `--inputs-file FILE`      |          | —                 | see[Flows that need inputs](#flows-that-need-inputs)                           |
| `--drive`                 |          |                    | keep going after the start — answer every input step until the flow finishes |
| `--drive-timeout SECONDS` |          | `900`            | how long`--drive` keeps trying                                              |
| `--poll-interval SECONDS` |          | `5`              | how often`--drive` checks for work                                          |
| `--api-base URL`          |          | auto               | override the backend URL                                                      |
| `--timeout SECONDS`       |          | `60`             | per-request timeout                                                           |
| `--dry-run`               |          |                    | validate everything, create nothing                                           |
| `--json`                  |          |                    | one JSON object on stdout instead of prose                                    |
| `-h`, `--help`          |          |                    |                                                                               |

## Finding valid values

You don't need to look them up — pass anything and the error tells you what's valid at that
level:

```bash
$ ./scripts/start-scenario.sh --base-url https://workbench.ondc.tech \
    --domain ONDC:RET11 --version 1.2.5 --usecase "F&B" \
    --flow-id "?" --subscriber-url https://my-np.example.com --dry-run

ERROR [validate-flow]: Unknown flow-id '?' for ONDC:RET11 1.2.5 / F&B. Available flows:
  - BUYER INSTRUCTIONS AND ADDRESS UPDATE FLOW
  - BUYER_CANCEL
  - FULL_CATALOG
  ...
```

The same works for `--domain`, `--version`, and `--usecase`. Add `--dry-run` while you're
hunting so nothing gets created.

## Checking your arguments first

`--dry-run` validates every argument and exits without creating a session:

```bash
./scripts/start-scenario.sh ... --dry-run
```

## Flows that need inputs

Some flows can't start without data — typically when Workbench is the side that has to send
the first call (e.g. you're `BPP`, so Workbench acts as the buyer and needs to know which
items to select). The script exits `5` and shows you exactly what's required:

```
ERROR [start-flow]: flow "ORDER_FLOW" requires inputs and was NOT started.
  required input fields:
    - ret11_nestedSelect

  Re-run with --inputs-file FILE, where FILE looks like:
    {"inputs": { "<field-name>": "<value>" }, "json_path_changes": {}}

  Full input config:
  [ ... full JSON schema for the field ... ]
```

Write a file matching that schema and pass it:

```bash
cat > inputs.json <<'EOF'
{
  "inputs": { "...": "..." },
  "json_path_changes": {}
}
EOF

./scripts/start-scenario.sh ... --inputs-file inputs.json
```

Both `inputs` and `json_path_changes` are sent through as-is; `json_path_changes` is optional.
The shape of `inputs` differs per flow — always read the config the error prints.

## Running the whole flow: `--drive`

Without `--drive`, the script arms the flow and exits. Any later step that needs a form filled
in will sit and wait for a human to open the session URL.

With `--drive`, the script stays attached: it watches the run and answers each input step as it
comes up, exiting when the flow completes.

```bash
./scripts/start-scenario.sh \
  --base-url https://workbench.ondc.tech \
  --domain ONDC:RET11 --version 1.2.5 --usecase "F&B" \
  --flow-id ORDER_FLOW \
  --subscriber-url https://my-np.example.com \
  --inputs-file inputs.json \
  --drive
```

Steps that need no data are advanced automatically. Steps that do need data are looked up in
the `steps` section of your `--inputs-file`:

```json
{
  "start": { "inputs": { "city_code": "std:011" } },
  "steps": {
    "select_1":   { "inputs": { "...": "..." }, "json_path_changes": {} },
    "on_confirm": { "inputs": { "...": "..." } }
  }
}
```

Keys are matched against the step's `actionId` first, then its `actionType` — so a single
`"select"` entry can cover every `select` in the flow, while `"select_1"` targets just that one.
`start` is what the flow needs to begin (the same thing the flat `{"inputs": ...}` shape means).

**You don't have to guess the keys.** Run it once and let it stop at the first step it can't
answer — the error names the step and prints the exact config it wants:

```
ERROR [drive]: step "Select items" needs inputs and none were supplied.
  actionId   : select_1
  actionType : select

  Add it under "steps" in --inputs-file:
    {"steps": {"select_1": {"inputs": { ... }}}}

  Config this step is asking for:
  [ ... full JSON schema ... ]
```

Fill that in, re-run, and repeat until the flow completes.

Notes:

- Nothing happens until your NP sends its first call — `--drive` waits for it and says so.
- If the flow hasn't finished within `--drive-timeout` (default 15 min) the script exits `6`.
  The session stays live, so you can open the URL and carry on by hand.
- `--drive` reports `stepsAnswered` in `--json` mode.

## Exit codes

| Code  | Meaning                                                                          |
| ----- | -------------------------------------------------------------------------------- |
| `0` | Flow started (or completed, with`--drive`)                                     |
| `1` | Bad or missing arguments, or`jq`/`curl` not installed                        |
| `2` | Invalid domain / version / usecase / flow id, or the flow is blocked (see below) |
| `3` | Session creation failed                                                          |
| `4` | Flow start failed                                                                |
| `5` | A step needs inputs you didn't supply — add them to`--inputs-file`            |
| `6` | `--drive` timed out before the flow completed                                  |

## Common failures

**"Another session is already waiting for … on this subscriber URL"** (exit `2`) — one flow at
a time per subscriber URL. Finish or abandon the other run, wait ~5 minutes for it to lapse, or
point `--subscriber-url` somewhere else.

**"did not start … http status: 500"** (exit `4`) — almost always the same cause as above, just
detected later. Same fixes.

**"Could not reach the Workbench backend under …"** (exit `2`) — check `--base-url`, or pass
`--api-base` if you're running against a non-standard deployment.

## Scripting it

`--json` puts a single object on stdout and keeps all progress output on stderr:

```bash
result=$(./scripts/start-scenario.sh ... --json 2>/dev/null)
echo "$result" | jq -r '.sessionId'
```

Success:

```json
{
  "ok": true,
  "sessionId": "SwiVv2Yv5O_57eR41beUav2_8TbgDYNY",
  "transactionId": "ac26926a-610e-4421-af43-1c781c6d74f4",
  "flowId": "FULL_CATALOG",
  "domain": "ONDC:RET11",
  "version": "1.2.5",
  "usecase": "F&B",
  "subscriberUrl": "https://my-np.example.com",
  "npType": "BAP",
  "url": "https://workbench.ondc.tech/flow-testing?sessionId=...",
  "driveStatus": "not-driven"
}
```

With `--drive`, `driveStatus` is `"completed"` and a `stepsAnswered` count is included.

Failure — same non-zero exit code as above, plus:

```json
{
  "ok": false,
  "stage": "start-flow",
  "message": "Flow 'FULL_CATALOG' did not start ...",
  "status": 500,
  "response": "{\"message\":\"Internal Server Error\"}"
}
```

## Scope

The script starts the flow, and with `--drive` answers its input steps until it completes.
It does not generate reports — open the printed session URL for that.
