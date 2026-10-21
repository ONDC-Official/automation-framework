# NP Portal Integration Specs

OpenAPI 3.1 contract for the NP portal third-party integration.

## Layout

```
openapi/
  openapi.yaml              # root: info, servers, security, tags, path index
  paths/                    # one file per path (all methods for that path)
  components/
    schemas/                # request/response models
    parameters/             # reusable params (headers, pagination, ...)
    headers/                # reusable response headers
    responses/              # shared error responses (RFC 9457 problem+json)
redocly.yaml                # lint rules
dist/                       # generated — do not edit
```

## Commands

Run `npm install` once inside this folder, then:

| Command                | What it does                                                   |
| ---------------------- | -------------------------------------------------------------- |
| `npm run lint`         | Validate the spec + style rules                                |
| `npm run bundle`       | Single-file `dist/openapi.yaml` / `.json` (share this with the partner) |
| `npm run docs`         | Static HTML reference at `dist/index.html`                     |
| `npm run build`        | lint → bundle → docs                                           |
| `npm run mock`         | Mock server on `:4010` returning the examples in the spec      |
| `npm run mock:dynamic` | Mock server returning randomly generated schema-valid data     |

## Adding an endpoint

1. Create `openapi/paths/<resource>.yaml` (use `paths/health.yaml` as a template).
2. Register it under `paths:` in `openapi/openapi.yaml` (`/orders/{order_id}` → `$ref: paths/orders_{order_id}.yaml`).
3. Put models in `components/schemas/`, reuse `components/responses/*` for errors.
4. Give every request/response an `example` — the mock server and docs depend on them.
5. `npm run build`.
