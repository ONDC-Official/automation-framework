---
id: db-service
kind: instance
isa: service
part-of: workbench
confidence: high
source: repo automation-db/ (src: index.ts, entity/, routes/, controllers/, middleware/api-key.ts)
changed-by: adr-0005
---

# db-service (automation-db, persistence API)

TypeScript service (port 5001) fronting **MongoDB**. Single source of truth for: persisted protocol payloads, session metadata, protocol specs (pushed at build time), and reports (GridFS). All routes require `x-api-key` = API_SVC_KEY.

## Slots
- backing-store: MongoDB (mongo:27017); collections Payload, SessionDetails, Report, User + @ondc/build-tools spec collections; reports binary in GridFS bucket "reports"
- postgres: config present (DB_HOST/USER/...) but not actively used in index.ts
- indexes: created at startup (createIndexes)

## Entities (src/entity/)
- Payload: messageId, transactionId, flowId, payloadId(unique), action, bppId, bapId, reqHeader(JSON string), jsonRequest(obj), jsonResponse(obj), httpStatus, action_id, sessionId(required, indexed) + timestamps. Flat.
- SessionDetails: sessionId(req), npType(req), sessionType(req), version, npId, domain, usecaseId, userId; flows[{id, status PENDING|COMPLETED, payloads[]}]; flowSummary Record<cat,{total,completed}> (cats MANDATORY/OPTIONAL/REPORTABLE); flowMap Record<flowId,PASS|FAIL>; reportExists(bool).
- Report: test_id(unique), user_id(indexed), file_id(GridFS ObjectId), total_tests, passed_tests, flow_summary. HTML binary in GridFS.
- User: githubId(unique), participantId, sessionIds[].

## Spec storage (resolves earlier open Q — adr-0021)
- Specs live in MongoDB collections written by [[build-tools]] ingest: build_meta, build_docs, build_flows, build_attributes, build_validations, build_changelog, build_validation_table (keys: domain+version [+slug/usecase/flowId/useCaseId/fromVersion-toVersion]); SHA-256 hash-skip on build_meta.
- Write: POST /protocol-specs/specs (gzip'd YAML, Zod-validated → 422 on error; skipped if content hash unchanged).
- Read: GET /protocol-specs/specs/{domain}/{version}?include=meta,flows,docs&usecase=&flowId=&tag= ; GET /protocol-specs/builds.

## Key routes (all require x-api-key)
- /api/sessions (GET all; POST create [also adds to User.sessionIds]; /upsert; /:id GET/PUT/DELETE; /check/:id; /filter?np_type&np_id&domain&version [+reportExists]; /flows/:id PUT|POST; /:id/analytics POST; /payload/:id GET; /payload POST; /subscriber-urls/:userId)
- /payload (GET; /:id; /transaction/:txnId; /logs/:txnId; POST; /ids POST; /stored/:domain/:version/:action/:page paginated; PUT/DELETE)
- /report (GET all; /:testId → {test_id, data: base64 html}; /user/:userId; POST /:testId?userId [HTML or mochawesome→rendered])
- /protocol-specs (POST /specs; GET /builds; GET /specs/:domain/:version)

## Analytics
- POST /api/sessions/:id/analytics writes flowSummary + flowMap (merge: flowMap keys override, flowSummary replace; sets reportExists=true). Written by report-service; read by ui-backend/backoffice.

## Relations
- written-by → [[recorder-service]] (payloads/sessions), [[spec-to-runtime]] (specs at build)
- read-by → [[config-service]] (specs/flows/builds), [[report-service]] (payloads), [[backoffice-frontend]] (cache/session inspection), [[ui-frontend]] (history)

## Overrides / edge points
- db down ⇒ recorder async save fails silently; reports/history unavailable; live flow still runs (cache in Redis).
- missing/invalid x-api-key ⇒ rejected by api-key middleware.

## Resolved (adr-0021)
- Specs live in MongoDB build-tools collections (META/FLOWS/ATTRIBUTES/DOCS/VALIDATIONS/CHANGELOG) keyed by domain+version.
