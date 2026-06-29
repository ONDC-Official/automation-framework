---
id: onix-plugins
kind: class
isa: concept
part-of: api-service
confidence: high
source: repo api-service/build-output/temp/automation-beckn-plugins/*
changed-by: adr-0018
---

# ONIX plugins (inventory)

The Go plugins composed by [[onix-adapter]] into each module's chain. Source is `automation-beckn-plugins/` (in-repo); each plugin compiles via buildplugins.sh (`go build -buildmode=plugin` → `{name}.so`) and is loaded by the ONIX server's pluginManager (root ./plugins). ONIX-core plugins are common to all ONIX deployments; workbench-* are generated/custom for the workbench.

> The beckn-ONIX SERVER CORE (request pipeline / std handler / plugin manager) is now IN-REPO as `automation-beckn-onix` → see [[onix-server]] (deep-dived adr-0046). It loads these plugins' `.so` via plugin manager and runs them as the module step chains.

## ONIX-core
- schemavalidator — L0 JSON-schema validation against `./schemas/ONDC_{DOMAIN}_{VERSION}_{action}.json`; reject malformed → BadReqErr.
- ondc-validator — L1 rule validation (cross-field, enums, conditional, state). Flag `stateFullValidations` toggles predecessor/successor checks. See [[validation-layers]].
- signvalidator — verify inbound Ed25519 signature (see [[signing-security]]).
- signer — generate outbound Ed25519 signature (mockTxnCaller).
- cache — Redis (redis:6379) session/transaction/subscriber cache.
- router — HTTP path → destination URL mapping (np/mock/form routers); jsonPath extraction; actAsProxy.
- network-observability (middleware) — async gRPC/HTTP audit to [[recorder-service]]; non-blocking.

## Workbench-generated
- workbench-main (ondcWorkbench) — core receiver: extract transaction_id/message_id/action, validate against state machine (transaction_properties.yaml), store txn in Redis, set mock_url/subscriber_url cookies. Steps: WorkbenchReceiver, ValidateContext, CallSave.
- workbench-keymanager — own keys from env (SIGNING_PRIVATE/PUBLIC, ENCR_*, SUBSCRIBER_ID, UNIQUE_KEY_ID); counterparty keys via registry lookup (IN_HOUSE_REGISTRY / preprod.registry.ondc.org/v2.0/).
- workbench-callback-redirect (middleware) — /callback: mark form complete in Redis, 302 redirect to workbench.
- encryption-middleware + outgoing-encryption-middleware — built (.so) but NOT referenced in the current adapter.yaml (payloads not encrypted in this config).
- full set (12, all → .so): cache, router, schemavalidator, ondcvalidator, signvalidator, signer, networkobservability, workbench(main), keymanager, callbackredirect, encryptionmiddleware, outgoingencryptionmiddleware. adapter.yaml plugin ids map 1:1 to these.

## Relations
- composed-by → [[onix-adapter]]
- audit → [[recorder-service]] ; keys → [[registry-gateway]]

## Open questions
- RESOLVED (adr-0057): plugins are cloned FRESH per spec build by [[api-service-generator]] (clonePlugins: `git clone --branch main` automation-beckn-plugins) and compiled with the generated validationpkg — versioned with the build, not pinned into the ONIX base image.
