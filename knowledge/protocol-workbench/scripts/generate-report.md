---
id: generate-report
kind: script
confidence: high
source: repo automation-report-service + report-pramaan
changed-by: adr-0009
---

# Generate report (validation / Pramaan)

Turn a session's recorded payloads into a pass/fail report.

## Entry conditions
- payloads persisted in db (via recorder); session metadata present; API_SERVICE_KEY set

## Roles
- tester/ui-backend, report-service, db-service, report-pramaan (for non-enabled domains)

## Scenes (ordered)
1. Request — POST report-service /generate-report?sessionId=&user_id= body {flowIdToPayloadIdsMap, flow_summary}.
2. Fetch — payloads from db /payload/ids; session metadata (domain,version,usecase) from ui-backend /sessions.
3. Branch — if domain:version in ENABLED_DOMAINS → local validation; else → Pramaan delegation.
   3a. Local — loadConfig → validateActionSequence (1s dedup; early-termination only update/status/track/cancel) → per-action validators → generateCustomHTMLReport.
   3b. Pramaan — generateTestsFromPayloads → POST PRAMAAN_URL → buyer/sellerNPTestAPI run mocha → mochawesome JSON → callback report-service /callback/PW_${sessionId}.
4. Store — save report to db GridFS (bucket "reports"), record flow_summary/flowMap.

## Results
- HTML report (enabled domains) or mochawesome-derived result rendered to HTML (Pramaan); per-flow PASS/FAIL. Output is HTML only (no PDF/CSV).

## Edge points
- domain not enabled + PRAMAAN_URL missing ⇒ error; Pramaan down ⇒ timeout ~30s.
- flowId not in FLOW_ID_MAP ⇒ "No flowId mapping found".
- callback testId must be PW_${sessionId}.
