---
id: user-management-service
kind: instance
isa: service
part-of: workbench
confidence: high
source: repo automation-user-management/ (Go/Fiber: main.go, src/) — deep-dive adr-0033
changed-by: adr-0033
---

# automation-user-management (auth + comments/notes)

Go/Fiber service (port 8082, container default 8080), now a git submodule. Two jobs: (1) GitHub OAuth + JWT auth; (2) a collaborative **comments + notes** annotation system over flows. It does NOT serve developer-guide content (that's [[config-service]]/protocol specs — corrected adr-0033).

## Slots
- db: MongoDB `developer_guide_db` (compose: developer_guide); collections users, exchange_codes, comments, notes
- auth: GitHub OAuth (scopes read:user, user:email) → JWT HS256 {user_id,email,username,avatar_url, exp +8h}; secret JWT_SECRET; Bearer token
- exchange-code: cross-domain token relay — OAuth callback stores a single-use code (exchange_codes, 5-min TTL) → POST /auth/exchange → JWT (lets the frontend on another origin obtain the token)

## Endpoints
- GET / (health: service "automation-developer-guide") ; GET /login → GitHub ; GET /auth/github/callback ; POST /auth/exchange {code}→{token} ; GET /auth/api/me (Bearer)
- /api/comments (GET list by use_case_id/flow_id/action_id/json_path/parent; GET /:id +replies; POST; PUT /:id; PUT /:id/resolve; DELETE) — threaded via parent_comment_id, resolved flag, creator-only edit/delete
- /api/notes (GET/POST/PUT/:id/DELETE) — like comments, no threading

## Data model
- users: login, name, avatar_url, email (upsert by email on OAuth)
- comments/notes: use_case_id, flow_id, action_id, json_path, comment|note, [parent_comment_id], resolved, created_by, timestamps — anchored to a flow/action/JSONPath location (annotation overlay)

## Relations
- called-by → [[ui-frontend]] (login, /auth/api/me, comments/notes CRUD)
- distinct-from → [[config-service]] (which serves the actual developer-guide content + lifecycle-status flag)

## Open questions
- RESOLVED (adr-0057): the ui-frontend has dedicated API clients (developerGuideCommentsApiClient / NotesApiClient, base VITE_DEVELOPER_GUIDE_BACKEND_URL) that call user-management `/api/comments` + `/api/notes`; the FE overlays these (keyed by use_case_id/flow_id/action_id/json_path) on the config-service-served guide content.
