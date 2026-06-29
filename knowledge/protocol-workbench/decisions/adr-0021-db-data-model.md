---
id: adr-0021
date: 2026-06-26
grill-ref: deep-dive — recorder/DB data model
status: accepted
changes: [db-service]
---

# Seed DB data model + resolve spec storage

## Decision
Captured db-service entities (Payload, SessionDetails, Report/GridFS, User) with full fields; the full route surface (sessions/payload/report/protocol-specs); analytics (flowSummary cats + flowMap PASS/FAIL); and resolved that specs live in MongoDB @ondc/build-tools collections (META/FLOWS/ATTRIBUTES/DOCS/VALIDATIONS/CHANGELOG) keyed by domain+version.

## Assumptions & perception
- Source: Explore over automation-db src (entity/controllers/routes/repositories) + recorder Go (file:line). High confidence. Recorder write model already captured in adr-0005; this adds the db side + spec storage.

## KB effect
- db-service: entities, routes, spec collections, analytics; spec-storage open Q resolved.
- triples: entities, spec-collections, analytics.
