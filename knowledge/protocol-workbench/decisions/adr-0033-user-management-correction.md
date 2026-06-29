---
id: adr-0033
date: 2026-06-26
grill-ref: deep-dive — automation-user-management (correction)
status: accepted
supersedes: adr-0007
changes: [user-management-service, spec-lifecycle-status, ui-frontend]
---

# user-management = auth + comments/notes (NOT guide content)

## Question / context
Earlier (adr-0007) user-management was described as auth + developer-guide content provider, and the lifecycle-status flag was attributed to it. Deep-dive corrected this.

## Decision
- automation-user-management is a Go/Fiber service doing (1) GitHub OAuth + JWT auth (with a single-use exchange-code cross-domain relay) and (2) a collaborative comments + notes annotation system over flows. DB developer_guide_db {users, exchange_codes, comments, notes}.
- It does NOT serve developer-guide CONTENT. The guide content + the ecosystem lifecycle-status flag (draft/live/to-be-deprecated/deprecated) are served by config-service / protocol specs. Supersedes adr-0007 on this point.

## Assumptions & perception
- Source: Explore over automation-user-management Go source (file:line). High confidence. The lifecycle-flag exact field still to be located in config-service/protocol-spec schema (open).

## KB effect
- user-management-service: rewritten (auth + comments/notes).
- spec-lifecycle-status + ui-frontend: guide content/flag attributed to config-service, comments/notes overlay to user-management.
