---
id: signing-security
kind: concept
isa: concept
part-of: api-service
confidence: high
source: repo signvalidator.go, signer.go, workbench-keymanager/keymanger.go
changed-by: adr-0018
---

# Signing & security (ONIX)

How the workbench verifies and produces ONDC request signatures. Relevant to architects and NP devs debugging auth failures.

## Slots
- algorithm: Ed25519 signature over BLAKE2b-512 digest of the body (BLAKE2b, NOT BLAKE2s). Exact payload bytes (no parse→re-stringify); standard base64 (not url-safe); LF newlines.
- auth-header: `Signature keyId="<subscriber_id>|<unique_key_id>|ed25519",algorithm="ed25519",created="<unix>",expires="<unix>",headers="(created) (expires) digest",signature="<base64>"` (UI auth-header tool generates this; see [[ui-frontend]])
- signing-string: `(created): {ts}\n(expires): {ts}\ndigest: BLAKE-512={digest}`
- inbound (signvalidator): parse header → lookup sender public key via keyManager → check created<now<expires → ed25519.Verify. Enabled on Bap/BppTxnReceiver.
- outbound (signer): hash body, build signing string, ed25519 sign with own private key, base64 → Authorization header. Used by mockTxnCaller.
- own-keys: keymanager `Keyset(subscriberID)` sourced from **Vault** (AppRole VAULT_ROLE_ID/VAULT_SECRET_ID) with cache fallback; env (SIGNING_PRIVATE/PUBLIC, ENCR_*, SUBSCRIBER_ID, UNIQUE_KEY_ID) as the sample/local source. (adr-0046)
- counterparty-keys: registry lookup POST {registry}/lookup (subscriber_id + uniqueKeyID); default preprod.registry.ondc.org/v2.0/ or IN_HOUSE_REGISTRY
- NOT-enabled: test path (standaloneValidator) skips signing; encryption-middleware not wired

## Runtime-confirmed (adr-0048, live FIS12 2.0.3)
- Captured a REAL outbound `Authorization` from the mockTxnCaller signer (pointed `?subscriber_url=` at a capture listener): `Signature keyId="dev.bap.example|27baa06d-d91a-486c-85e5-cc621b787f04|ed25519",algorithm="ed25519",created="1782634224",expires="1782634524",headers="(created) (expires) digest",signature="EFCq…XODDg=="`. keyId = `subscriber_id|unique_key_id|ed25519` ✓, algorithm ed25519 ✓, 300s created→expires window (created 1782634224 → expires 1782634524) ✓.
- api-service log: "Generating signature for signing string: (created): 1782634224 …" → "Signature generated: EFCq…" (value matches the header). Steps before sign: "Validating Transaction History" → TTL validations ("Skipping TTL validation for non-on_ action: search") → "Running Transaction Id Checks" → sign → forward (ActAsProxy:true) → NO audit "dispatched successfully".
- BLAKE2b-512 digest stays code-confirmed (not exposed in the header line; no separate Digest header sent).

## Relations
- enforced-by → [[onix-plugins]] (signvalidator/signer)
- keys-from → [[registry-gateway]]

## Edge points (tester)
- clock skew > created/expires window ⇒ legit requests fail (no explicit skew tolerance).
- registry unreachable ⇒ counterparty key lookup fails ⇒ signature verify fails.

## Resolved (adr-0019)
- W2W is NOT a signing bypass: a workbench side can use the ACTUAL registry and verify the other side's signature. The w2w testing gap is implicit-assumption divergence, not relaxed crypto — see [[w2w-testing]].
