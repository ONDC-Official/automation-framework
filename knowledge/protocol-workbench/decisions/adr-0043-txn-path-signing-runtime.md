---
id: adr-0043
date: 2026-06-28
grill-ref: RUNTIME-VERIFICATION-PROMPT paths 2 (transaction chain) + 6 (signing), live FIS12 2.0.3
status: accepted
changes: [onix-adapter, validation-layers, signing-security]
---

# Transaction chain + state-guard confirmed; validateSign/Authorization live capture pending

## Decision (runtime + config)
- Path 2 chain: live adapter.yaml BapTxnReceiver (`/seller/`) steps = ondcWorkbenchReceiver → addRoute → validateSchema → validateOndcPayload → ondcWorkbenchValidateContext → validateSign → validateOndcCallSave; ondcvalidator `stateFullValidations:true`. EXACT match to KB. BppTxnReceiver (`/buyer/`) symmetric.
- State-guard CONFIRMED live: `POST /seller/on_search` for an unknown txn ⇒ HTTP 412 NACK "No active expectation found for transaction ID ... as a seller_np" — out-of-sequence / no-active-expectation ⇒ no advance (this is the runtime form of "out-of-sequence ⇒ no matching step").
- validateSign plugin is configured on both receiver chains; signer on mockTxnCaller (outbound). A real inbound signature verification firing + a captured Authorization header were NOT observed this run (no completed signed transaction — flow dispatch blocked by mock submodule skew, adr-0044). Algorithm/keyId (Ed25519 over BLAKE2b-512, keyId `id|ukid|ed25519`, keys via IN_HOUSE_REGISTRY) stay code-confirmed (adr-0018).

## KB effect
- onix-adapter/validation-layers: 412 state-guard recorded; chain re-confirmed live. signing-security: validateSign config-confirmed, live Authorization capture pending. Confidence unchanged (config high, live-sign pending).
