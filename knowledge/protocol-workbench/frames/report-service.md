---
id: report-service
kind: instance
isa: service
part-of: workbench
asof: 2026-06-26
confidence: high
status: current-snapshot (reporting redesign planned; this documents current code as truth)
source: repo automation-report-service/ (controllers, services/reportService+validationModule+checkPayload+dbService, validations/, templates/, utils/constants.ts) — deep-dive adr-0026
changed-by: adr-0026
---

# report-service (validation report generator)

> Note (asof 2026-06-26): a reporting redesign is planned; this documents the CURRENT code as truth. [[report-pramaan]] is a LEGACY plug (still functional, invoked for non-enabled domains/usecases), not deprecated.

TypeScript service (port 3000) that generates protocol validation reports for a test session. For **enabled domains+usecases** it validates locally and renders an HTML report; otherwise it delegates to the legacy [[report-pramaan]].

## Endpoints
- POST /generate-report?sessionId=&user_id= ; body = flowIdToPayloadIdsMap + flow_summary → HTML report
- POST /callback/:testId (testId = `PW_${sessionId}` or `PW_${sessionId}::${userId}`) — Pramaan async callback: forwards base64 report to db, derives flowMap, writes analytics

## Enabled vs Pramaan branch
- domainVersionKey: `${domain}:${version}` (FIS13 special: `${domain}:${version}:${usecaseId}`)
- if key NOT in ENABLED_DOMAINS → checkPramaanReport (legacy)
- ENABLED_USECASES gate (e.g. TRV11 2.0.0/2.0.1 → ["metro"]; 2.1.0 → ["metro","bus"]) — usecase not allowed → Pramaan
- else → internal validation → HTML

## Internal validation pipeline (enabled)
- config: ReportingConfig.yaml → domains[d].versions[v].usecases?[u] (flows: {flowId:[actions]}, optional_flows, validationModules "path#fn")
- validateActionSequence: dedup window 1s (same action+txn+createdAt); forms (HTML_FORM/DYNAMIC_FORM) skipped (don't consume payloads); lookahead up to 5; skip unsolicited on_status/on_update; early-termination valid after on_confirm / on_status / on_update (and repeat search after on_search for TTL flows)
- per-action: checkPayload → shared contextValidator (required ctx fields, timestamp, country/city) + dynamically-loaded domain validator (validationModules path#fn → version/action file). DomainValidators.{domain}{Action} per action (search…on_issue_status). Returns passed[]/failed[].
- flowResults[flowId] = valid_flow ? PASS : FAIL

## FLOW_ID_MAP (for Pramaan)
- FLOW_ID_MAP[domain][version][usecaseId][workbenchFlowName] = pramaanFlowId; used to build Pramaan tests and reverse-map callback suites. Missing entry ⇒ generateTestsFromPayloads throws.

## Slots
- entry: POST /generate-report?sessionId=&user_id= with body flowIdToPayloadIdsMap, flow_summary
- enabled-domains (src/utils/constants.ts): ONDC:LOG10 1.2.5; LOG11 1.2.5; FIS10 2.1.0; FIS11 2.0.0; FIS12 2.0.1/2.0.2/2.0.3/2.2.0/2.2.1/2.3.0; FIS13 2.0.1; TRV10 2.1.0; TRV11 2.0.1/2.1.0; TRV13 2.0.1 — anything not listed ⇒ Pramaan delegation
- inputs: payloads from db-service /payload/ids; session metadata (domain,version,usecase) from ui-backend /sessions
- validation: loadConfig → validateActionSequence (dedup within 1s window; early-termination allowed only for update/status/track/cancel) → per-domain/action validators (e.g. DomainValidators.fis12Search)
- output: HTML ONLY (generateCustomHTMLReport/generateReportHTML → HTML string + flowResults; client-side download via JS blob). No PDF/CSV anywhere (no pdfkit/puppeteer/json2csv). Saved to db GridFS bucket "reports" (test_id metadata)
- pramaan-delegation: generateTestsFromPayloads → POST PRAMAAN_URL → async callback /callback/:testId (base64 mochawesome JSON); test_id format `PW_${sessionId}`
- otel: full OpenTelemetry instrumentation (otelConfig.ts → jaeger)

## Relations
- reads-payloads-from → [[db-service]]
- delegates-to → [[report-pramaan]] for non-enabled domains
- invoked-by → [[ui-frontend]] (Flow Testing Suite report step)
- defined-by → script [[generate-report]]

## Overrides / edge points (tester)
- domain not enabled + PRAMAAN_URL missing ⇒ error; Pramaan down ⇒ timeout (~30s).
- flowId not in FLOW_ID_MAP ⇒ "No flowId mapping found" (needs map update + redeploy).
- payloads missing ⇒ all-fail report; session metadata missing ⇒ Pramaan fallback.
- callback testId must be PW_${sessionId} or report never stored.

## Edge points (tester)
- domain not enabled + PRAMAAN_URL unset ⇒ error; flowName not in FLOW_ID_MAP ⇒ throws; callback flow_summary missing (not inline, Redis expired) ⇒ analytics incomplete (silent); Pramaan suite.title unmapped ⇒ flow silently absent from flowMap; dedup window hardcoded 1s; no db-service retry; no out-of-order/TTL checks at report time; action_id null ⇒ validator-not-found.

## Resolved (adr-0009, adr-0026)
- Output HTML only. ENABLED_DOMAINS + ENABLED_USECASES confirmed. Internal validators are per-domain/version modules under src/validations/, dispatched via ReportingConfig.yaml validationModules path#fn.

## Open questions
- How a domain gets added to ENABLED_DOMAINS / who authors the local validators (process) → owner: Shreyansh
- (reporting redesign planned — revisit then; skip future specifics per owner)
