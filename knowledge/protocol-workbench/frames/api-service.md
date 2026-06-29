---
id: api-service
kind: instance
isa: service
part-of: workbench
confidence: high
source: repo api-service/, scripts/build-api-service.sh, build-output/ plugins
changed-by: adr-0003
---

# api-service (the executable protocol definition)

The domain API service: a **generated** runtime that turns an ONDC spec (a branch of [[automation-specifications]]) into a running validator+responder. This IS "the protocol definition made executable" — for protocol queries, the answer lives in the spec config and is enforced here at runtime. Built on the **beckn-ONIX** adapter (base image `ghcr.io/ondc-official/automation-beckn-onix:latest`) with compiled Go plugins.

## Slots
- generated-by: `@ondc/api-service-generator@1.0.2` (invoked by [[spec-to-runtime]])
- input: `build.yaml` (resolved from spec `config/` via `@ondc/build-tools parse`)
- internal-port: 7039 (ONIX server); external via nginx api-gateway at host 3032
- one-domain-rule: exactly ONE domain+version runs on 3032 at a time; switching = down + rebuild
- service-naming: ONDC:FIS12 / 2.0.3 → container `api-ondcfis12-2-0-3`
- runtime-config: `adapter.yaml` rendered at container start by `docker-entrypoint.sh` (sed-substitutes domain/version/port/redis/urls)
- git-ignored: `api-service/` dir and `docker-compose.api.yml` are generated, not committed

## Endpoints — adapter.yaml modules (see [[onix-adapter]])
- `/.../seller/` BapTxnReceiver (BAP receiver) + `/.../buyer/` BppTxnReceiver (BPP receiver): full chain, `stateFullValidations:true` + validateSign.
- `/.../test/{action}` standaloneValidator: schema + L1 only, no state, no signing (UI Schema Validation Tool).
- `/.../mock/` mockTxnCaller: proxies to mock; OUTBOUND signing (signer).
- `/.../form/html-form` formReceiver + `/.../buyer/callback` callbackReceiver: form/callback handling → recorder /html-form, 302 redirect.
- Full request trace: script [[onix-request-lifecycle]].

## ONIX sub-book
- [[onix-server]] (the beckn-onix server engine — now in-repo) · [[onix-adapter]] (module + routing map, action state machine) · [[onix-plugins]] (Go plugin inventory) · [[signing-security]] (Ed25519/BLAKE-512 + registry/Vault keys) · [[mock-service-embedded]] (api-service's bundled mock vs standalone [[mock-playground-service]]).

## Runtime validation plugin chain (ONIX)
1. SchemaValidator (Go) — JSON-schema validation; cache key `{domain}_{version}_{action}`; reads `build-output/temp/schemas/`. Returns field-path errors. See [[validation-layers]].
2. ONDC-Validator (Go) — L1 contextual rules from `build.yaml#/x-validations`: required fields, enums, regex (e.g. TTL), conditional rules, state deps (async_predecessor, transaction_partner). Stores txn state in Redis for stateful validation.
3. Response generation — on pass, routes to handler / mock-service; returns ACK/NACK.

## Relations
- generated-from → [[automation-specifications]]
- emits-audit-to → [[recorder-service]] (network-observability plugin → gRPC :8089 / http :8090)
- reads-config-from → [[config-service]]
- pushes-spec-to → [[db-service]] (push-to-db at build time)
- fronted-by → nginx api-gateway (3032)

## Resolved (adr-0009, adr-0018)
- test path skips state validation + signing; full seller/buyer path enforces both.
- ONIX boundary: ONIX = adapter that composes a chain of Go plugins per adapter.yaml module. ONIX-core plugins (schema/ondc/sign/cache/router/network-observability) + workbench-generated plugins (workbench-main/keymanager/callback-redirect). See [[onix-plugins]].
