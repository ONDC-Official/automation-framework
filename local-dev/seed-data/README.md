# Seed data

Optional seed data for local-dev runs. Drop files here and reference them
from a service-specific Docker volume mount in `docker-compose.override.yml`.

Examples of what you might place here:

- `recorder/sessions.json` — pre-recorded ONDC API sessions for the recorder service to replay
- `mock-playground/responses/` — mock response payloads for stubbed endpoints
- `report/fixtures.json` — sample log fixtures used to seed the report service

Files in this directory are gitignored by default — see `../.gitignore`.
