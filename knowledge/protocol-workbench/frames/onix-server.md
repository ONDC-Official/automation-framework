---
id: onix-server
kind: instance
isa: component
part-of: api-service
confidence: high
source: repo automation-beckn-onix/ (cmd/adapter, core/module, pkg/plugin, pkg/response) — adr-0046
changed-by: adr-0046
---

# onix-server (automation-beckn-onix — the ONIX server core)

The beckn-ONIX server engine that runs the generated [[onix-adapter]] config + compiled [[onix-plugins]]. Previously external; now in-repo as `automation-beckn-onix` (base image `ghcr.io/ondc-official/automation-beckn-onix`). This is the `./server --config adapter.yaml` runtime.

## Boot (cmd/adapter/main.go)
- initConfig (load+validate adapter.yaml) → InitLogger → plugin.NewManager (load .so) → initAppPlugins (OtelSetup) → newServer (HTTP mux + register modules) → listen on http.port; graceful shutdown. `/health` auto-registered.

## Handlers & step engine (core/module)
- ONLY handler type = **`std`** (HandlerTypeStd). Modules differ by their `steps` list + `plugins` + `role` (bap/bpp/gateway/registery) + type, NOT by handler class. (So "BapTxnReceiver / mockTxnCaller" etc. are all std handlers with different step lists.)
- StdHandler.ServeHTTP: inject X-Module-Name/X-Role → buffer body into StepContext → run steps linearly, **short-circuit on first error** → restore body → route or ACK.
- Step interface: `Run(ctx *StepContext) error`. Built-in steps: validateSchema, validateSign, sign, addRoute, validateOndcPayload, validateOndcCallSave, ondcWorkbenchReceiver, ondcWorkbenchValidateContext (+ custom plugin steps via mgr.Step()).
- Cookie feature-flags read by steps: `header_validation=false` skips validateSign; `protocol_validation=false` skips validateOndcPayload (see [[session-difficulty]]).

## Plugin manager (pkg/plugin)
- loads `.so` from pluginManager.root via Go `plugin.Open` → `Lookup("Provider")` → cast to typed provider; dependency-injects cache/registry/vault. `RemoteRoot` zip can be unzipped to root at boot.

## Response model (pkg/response) — confirms runtime
- ACK ⇒ **HTTP 200** `{"message":{"ack":{"status":"ACK"}}}`.
- NACK ⇒ body `{ack:NACK, error}`, HTTP code by error type: schema/Beckn ⇒ **200**; sign ⇒ **401**; bad request ⇒ **400**; not found ⇒ **404**; WorkbenchErr behavior=NACK ⇒ **200**, behavior=HTTP ⇒ err.Code (e.g. **412** no active expectation); panic/other ⇒ **500**.
- Panic path: nil/malformed message_id ⇒ `500 "Internal server error, MessageID: %!s(<nil>)"`.

## Routing & async (stdHandler)
- ctx.Route==nil ⇒ ACK. ActAsProxy=true ⇒ synchronous reverse-proxy to URL (or publish to queue). ActAsProxy=false ⇒ register **post-response hook** (forward fires AFTER the client gets its response); `custom-response-body` cookie (base64 JSON, set by workbench) lets the workbench inject a custom ACK body.

## Signing & keys (steps + keymanager)
- sign: km.Keyset(subscriberID) → signer.Sign (BLAKE2-512 + Ed25519, created/+5min) → Authorization header. validateSign: km.LookupNPKeys(subID,keyID) → verify. Keyset sourced from **Vault** (AppRole: VAULT_ROLE_ID/VAULT_SECRET_ID), cache fallback; public keys via registry. See [[signing-security]].

## Relations
- runs → [[onix-adapter]] + [[onix-plugins]] ; part-of → [[api-service]] ; lifecycle → [[onix-request-lifecycle]]

## Open questions
- RESOLVED (adr-0057): two keymanager plugins exist — `keymanager` (Vault, needs VAULT_ROLE_ID/SECRET_ID) for PROD, and `simplekeymanager` (inline env/YAML keys: signingPrivateKey, encrPrivateKey) for LOCAL. Local uses the env sample keys, not Vault.
