---
id: tester-playbook
kind: script
confidence: high
source: synthesis of all component frames + FAQ (adr-0023)
changed-by: adr-0023
---

# Tester break-points & coverage playbook

One place for QA / ONDC test authors / workbench devs: where things break, how to verify, and what the workbench does NOT catch. Synthesizes per-component edge points.

> For a SPECIFIC live symptom: scan `../LOCATOR.md` (where to look) then the matching `patterns/fm-*` (cause + fix locus + verify) — the low-token fast path. This playbook is the broader coverage/break-point reference behind those.

## Coverage model (what is / isn't validated)
- Validated: schema (L0), L1 contextual rules, flow sequence, signature (txn path), report-time re-validation. See [[validation-layers]].
- NOT validated: business logic beyond schema; sequence/signature on the TEST path; idempotency at validator; encryption (unwired).
- [[session-difficulty]] knobs (protocolValidations, timeValidations, headerValidaton, sensitiveTTL, useGateway, stopAfterFirstNack, useGzip) toggle strictness — a "passing" test may just have validations disabled. Always confirm difficulty settings.
- [[w2w-testing]] BLIND SPOT: w2w shares implicit assumptions not coded as explicit validations → real-NP divergences won't surface. Mitigate with NP-facing + negative/monkey testing.

## Debugging order (FAQ) — "flow not proceeding"
1. mock-service logs → did it forward to api-service?
2. api-service logs → received? validation result?
3. recorder logs → DB/cache writes happening?
4. inspect cache: Transaction_Session_data / MOCK_DATA has what the next step needs?
5. reproduce with Postman/playground using the NP's raw payload.
- Logs: `docker compose logs -f <svc>` (mock first). Traces: Jaeger 16686. (Dozzle/Grafana only in hosted env.)

## Break-points by area
- **Orchestration**: depends_on orders creation not readiness → services may crash if a dep isn't up; allow settle / use setup-local.sh --check-only. Only ONE domain on 3032.
- **api-service / ONIX**: test path skips state+signing (can pass invalid sequences); clock skew > created/expires ⇒ sign fail; registry unreachable ⇒ key lookup fail; same transaction_id + different subscriber_url ⇒ separate cache keys; recorder down ⇒ request still ACKs (async audit). See [[onix-request-lifecycle]].
- **mock-playground**: out-of-sequence ⇒ "no matching step", no advance (align flow def with api-service action names); generator failure ⇒ reset AVAILABLE / stuck WORKING (check base64 generator vs txnData fields); config-service down ⇒ first generation times out (no axios timeout — can hang); MockRunner 5-min TTL reload; SUSPENDED race (incoming may save before suspension check); forms need submission_id on /flows/proceed; forms only in sequence not extraSequence; backdoor clear-flows to reload config. See [[flow-state-machine]].
- **recorder/db**: Redis down ⇒ gRPC LogEvent fails; db down ⇒ async save fails silently (cache still ok); duplicate message_id deduped; action UPPERCASED + reqHeader stringified in db; missing/invalid x-api-key ⇒ 403; GridFS orphan risk on partial report save.
- **config-service**: db down ⇒ axios timeout; spec-not-found ⇒ 404; "playground changes not reflecting" ⇒ update config-service AND mock backdoor clear-flows.
- **report-service** (⚠️ under redesign): domain not in ENABLED_DOMAINS ⇒ Pramaan delegation (PRAMAAN_URL missing ⇒ error; Pramaan down ⇒ ~30s timeout); flowId not in FLOW_ID_MAP ⇒ "No flowId mapping found"; callback testId must be PW_${sessionId}; payloads missing ⇒ all-fail report.
- **ui**: missing context.domain/version ⇒ 400 on validate; session expiry 48h; expectation expiry 5min; new transaction_id for first step, reuse for rest; bap/bpp url must match the session; /ai/proxy blocks private IPs (SSRF).
- **backoffice**: /sessions/updatedb + POST /sessions + /sessions/logs have NO auth; admin/admin + hardcoded JWT secret (local insecure).

## Known live issues (runtime, adr-0047)
- ui-backend↔mock submodule skew: UI "trigger search" ⇒ mock 404 ⇒ ui-backend 500 (full flow blocked). gamification-db (postgres 5433) runs but isn't in the documented infra list.
- HTTP codes (test path): ACK & schema/L1 NACK both 200; sign 401; missing target 400; unknown txn 412; malformed ctx 500. See [[onix-server]].

## Verify writes (cheat sheet)
- cache: `redis-cli GET "txnid::suburl"` → apiList; `redis-cli GET "FLOW_STATUS_txnid::suburl"`; `redis-cli KEYS "*::*"`
- payload: `curl -H "x-api-key:$KEY" db:5001/payload/transaction/:txnId` ; logs `/payload/logs/:txnId`
- session: `curl -H "x-api-key:$KEY" db:5001/api/sessions/:sessionId`
- report: `GET db:5001/report/:PW_sessionId` → base64 html

## Negative / coverage tests to add (gaps)
- omit each required context field; wrong enum/domain; bad TTL regex; out-of-order action on test vs txn path; future-timestamp signature; expired session/expectation; mock_url cookie absent; recorder/db/redis down mid-flow; duplicate message_id; w2w implicit-assumption violations (real-NP emulation / monkey tests).

## Relations
- consolidates → [[validation-layers]], [[w2w-testing]], [[session-difficulty]], [[flow-state-machine]], [[onix-request-lifecycle]], [[recording-path]], [[generate-report]] and per-component "edge points"
- persona → [[persona]] (end-user-qa, workbench-developer)

## Root-cause-first: an on_X NACK is usually a mock-generation symptom (2026-06-29, adr-0053)
When `on_X` NACKs (message_id mismatch / sequence / sign), CHECK GENERATION BEFORE the protocol symptom — the symptom is 5+ layers from the root. Order:
1. Is the sent payload a **buildErrorPayload**? (`error` instead of `message`; `error.code` = `REQUIREMENTS_NOT_MET`/`REQUIREMENTS_CHECK_ERROR`/gen error; message_id is a fresh `createGenericContext` uuid). If yes → generation FAILED; the NACK reason is a red herring.
2. mock logs for the GENERATE_PAYLOAD_JOB: `Requirements not met for action` (requirements.js valid:false; `description` names the missing field) | `Mock payload generation failed`/`Syntax Error at line N` (generator.js threw — broken base64 fn). `REQUIREMENTS_CHECK_ERROR` = the fn threw (syntax); `REQUIREMENTS_NOT_MET` = ran & returned false.
3. Decode `mock.requirements`/`generate` from config-service `/mock/playground`; list `sessionData.*` it reads; grep flow `saveData` for those keys. A required field with NO saveData source = the bug (e.g. on_confirm `customer_*` with no `init` step in an offline flow).
4. Only then chase the protocol NACK. NB MockRunner echoes message_id from `sessionData.latestMessage_id` (most-recent — drifts with interleaving unsolicited on_status and across w2w MOCK_DATA partitions); only on_search/on_init/on_confirm are message_id-validated (async_predecessor).
- Deploy a flow-fn fix: edit base64 fn → `node --check` it → `build-tools parse/validate/push-to-db` → `clear-flows` + del DB1 key. NO api-service rebuild. See `references/w2w-debugging-depth-and-mcp-2026-06-29.md` for the full chain + runtime-MCP proposal.
