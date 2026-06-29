# W2W debugging depth, narrowing playbook & runtime-MCP proposal (2026-06-29)

Captured after a long live-debug session on the Gold_Loan_Offline w2w flow. Goal: make the next session reach the root cause in a few steps instead of dozens, and propose tooling (MCP) to collapse the manual `redis-cli`/`docker logs`/`curl` iteration.

## The actual depth that was required (and why it was deep)
A single user-visible symptom — **`on_confirm` NACK: "message_id mismatch between confirm and on_confirm"** — was **5+ layers away** from its root cause. The chase, in order, with the dead-ends marked:

1. `message_id mismatch` (api-service `ondcWorkbenchValidateContext`, contextvalidator.go:142). ← symptom
2. ✗ assumed message_id *echo* bug → `latestMessage_id` (most-recent) vs the specific predecessor.
3. ✗ `MockRunner` Priority-2 (`transaction_history.find(responseFor)`) — **dead** (transaction_history never populated by mock-playground).
4. ✗ w2w MOCK_DATA partitioning (`MOCK_DATA::txn::{buyer|seller}`) — real but a *secondary* trigger; implemented an echo fix in `generate-response.ts` (correct, but not the blocker).
5. ✓ **ROOT:** `on_confirm` generation was returning a **`buildErrorPayload`** (it has `error` instead of `message`, and a **fresh** message_id from `createGenericContext`) because **`requirements()` (`meetsRequirements`) returned `valid:false`** — `Missing customer_name in sessionData`.
6. ✓ **ROOT-of-root (spec):** `on_confirm.requirements()` demands `customer_name/phone/email`, normally captured at `init` via `saveData`; **this flow has no `init`/`on_init`** (offline journey) and **no step's `saveData` populates the customer fields** → requirement can never pass.

**The lesson:** an `on_X` NACK with a fresh/wrong `message_id` is almost always a **downstream symptom of the mock emitting an error payload**, not a message_id bug. The message_id only gets set on the *happy* generation path.

## Narrowing playbook — check generation BEFORE the symptom
When an `on_X` (or any mock-sent action) NACKs, resolve in this order (each step is one lookup):
1. **Is the sent payload an error payload?** Look at the action's payload `error.code` (`REQUIREMENTS_NOT_MET` / `REQUIREMENTS_CHECK_ERROR` / mock-gen error) and whether it has `error` instead of `message`. If yes → the mock generation FAILED; the NACK reason (sequence/sign/message_id) is a red herring.
2. **Why did generation fail?** mock logs for the action's GENERATE_PAYLOAD_JOB: `Requirements not met for action` (→ requirements.js returned valid:false; the `description` names the missing field) or `Mock payload generation failed` (→ generator.js threw; `Syntax Error at line N` = a broken base64 function). `REQUIREMENTS_CHECK_ERROR` = the requirements function itself threw (often a syntax error), distinct from `REQUIREMENTS_NOT_MET` (ran and returned false).
3. **What does requirements/generate need vs what saveData provides?** Decode `mock.requirements`/`mock.generate` (base64) from config-service `/mock/playground`; list the `sessionData.*` it reads; grep the flow's `saveData` for those keys. A required field with no `saveData` source = the bug (this flow: `customer_*` with no `init`).
4. **Only if generation is clean**, chase the protocol-level NACK (message_id echo, sequence/state, signature) — and remember MockRunner echoes `message_id` from `sessionData.latestMessage_id` (most-recent), which drifts with interleaving unsolicited `on_status` and across w2w MOCK_DATA partitions.

## Full w2w-local fix chain delivered this session (so it isn't re-derived)
1. **recorder txn-cache TTL** 300s→18000s (`docker-env/recorder-service.env`) — flow died after ~5 min ("No transaction data found"). (adr-0049)
2. **Protocol Validation off** (session difficulty) — local `bap_id` (`host.docker.internal:3032`) fails `REGEX_CONTEXT_BAP_ID`; with it on, `on_search` NACKs → empty form. (adr-0050)
3. **dynamic-form idempotency guard** (`process-flow.ts`) — frontend's placeholder `submission_id` re-proceed corrupted the real submission. (adr-0051)
4. **dynamic-form → /callback redirect** (`form-handlers.ts getSuccessHtml`) — form completion now writes `form_completed:{session}` so the polling modal closes. (adr-0052)
5. **CORS `x-api-key` dev-gated** (ui-backend `app.ts`) — release-eks-tech frontend sends it; allow-listed behind `NODE_ENV==="development"`.
6. **`crypto.randomUUID` → `uuidv4`** (frontend, 3 files) — `host.docker.internal` is a non-secure context; `randomUUID` is undefined there.
7. **message_id echo** (`generate-response.ts`) — resolve the specific predecessor's id from per-action history across both partitions (secondary; correct).
8. **`on_confirm` requirements relaxed** (spec) — `customer_*` guards `if(false)` because the offline flow has no `init` to capture them; seller uses default-payload customer. (deployed via `build-tools parse/validate/push-to-db` + `clear-flows`; NO api-service rebuild — mock functions only)

Recurring meta-pattern: **release-eks-tech / cloud-targeted builds fight a local `host.docker.internal` setup** (secure-context, CORS, host mismatch, submodule skew). In real EKS (HTTPS, real domain) none of these bite.

## Deploy facts (so deploys aren't re-discovered)
- Flow-config (requirements/generate/validate/saveData/input) changes deploy via **`build-tools push-to-db`** → db-service → config-service → mock; then **`DELETE /mock/playground/backdoor/clear-flows`** + del DB1 key. **No api-service rebuild** for mock-function changes.
- `build-api-service.sh` re-clones the spec from the **GitHub remote** — local-only edits to `api-service/config` must be built with parse/validate/push-to-db **directly** (don't re-run the full script, it overwrites).
- **Always `node --check`** an edited base64 mock function before push (a stray brace → `REQUIREMENTS_CHECK_ERROR` / `Syntax Error at line N`).
- **API-step `input` does NOT prompt**: config-service only synthesizes UI `input` for FORM steps (`form_submission_id`). To collect data at a non-form step you need a form step or a config-service change — a step-level `input:` in the flow YAML is ignored by `/mock/flow`.

## Proposed: ONDC Workbench Runtime MCP (collapse the manual iteration)
The whole session was manual `redis-cli` / `docker logs` / `curl db-service` / `curl config-service` / base64-decode / `build-tools`. An MCP server over the running stack would let the agent narrow in 1–2 tool calls. Suggested tools:
- **`wb_trace_action(txnId, action)`** ← highest value. One call returns: the api-service validation result + NACK reason, the mock generation outcome (success vs error-payload + which `error.code`), the `Requirements not met` description if any, and the decoded `requirements`/`generate` for that step. Collapses ~20 manual steps to one.
- `wb_logs(service, sinceSec, grep, correlationId)` — filtered docker logs (mock / api-ondcfis12 / ui-backend / recorder), strips the Health-metrics noise.
- `wb_redis(pattern|key, db)` — sessions, `MOCK_DATA::`, txn cache (`txn::sub` apiList), `FLOW_STATUS_`, `form_completed:`, `redirection_url:`; with TTLs.
- `wb_db_payloads(txnId)` — db-service `/payload/transaction/{txnId}` (action UPPERCASED, messageId, jsonRequest/Response, reqHeader).
- `wb_flow_status(sessionId, txnId)` — `/flows/current-status` per-step status + payloads, both w2w partitions.
- `wb_mock_fn(domain, version, usecase, flowId, actionId, fn)` — fetch + **base64-decode** a step's `requirements`/`generate`/`validate`/`saveData` from `/mock/playground`.
- `wb_deploy_flow(flowId)` — parse → validate → (node --check each edited fn) → push-to-db → clear-flows, with the gotchas baked in.
- `wb_difficulty(sessionId)` — read/patch session-difficulty knobs (Protocol/Header Validation) for local w2w.

Caveat (per [[mcp-runtime-agent]] / adr-0010): keep it a **service layer over the runtime** (redis/db/config-service/docker), read-mostly, with the few write tools (`clear-flows`, `push-to-db`, difficulty-patch) explicit.

## Owner asks recorded (2026-06-29)
- **"How do we keep the knowledge up to date?"** → answer in [[knowledge-keep-updated]] / the auto-update-on-fixes feedback memory: write back a frame slot + triple + ADR after every confirmed fix/mechanism, and explicitly note the *wrong* assumption when correcting one (so it isn't re-derived). This session's chain + the narrowing playbook above are that write-back.
- **MCP for runtime debug** → proposal above; user explicitly wants an MCP that can access/debug the running instance, motivated by the depth of recent change sessions.
