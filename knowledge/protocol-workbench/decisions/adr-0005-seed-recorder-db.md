---
id: adr-0005
date: 2026-06-26
grill-ref: repo exploration — recorder-service + automation-db
status: accepted
changes: [recorder-service, db-service, recording-path]
---

# Seed recording + persistence path

## Question / context
How are protocol exchanges captured and persisted?

## Decision
Captured: recorder gRPC LogEvent audit interface, sync Redis txn-cache write (atomic WATCH/EXEC, message dedup), async best-effort DB save + Network-Observability push, flow-status keys, http /html-form; and db-service collections/routes (Payload, SessionDetails, reports GridFS, x-api-key auth).

## Assumptions & perception
- Source: recorder-service Go files + automation-db TS (code-grounded).
- Postgres config present but unused; MongoDB is the active store.
- NO push likely prod-only (open question).

## KB effect
- frames recorder-service, db-service; script recording-path; cache-key triples.
