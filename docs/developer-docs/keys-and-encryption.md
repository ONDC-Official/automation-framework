# Keys & Encryption

> The two key pairs every Network Participant registers on the ONDC Portal, their formats, and — for use cases that require it — how data is encrypted between participants.

---

## Overview

Every Network Participant (NP) holds **two key pairs**:

| Key pair | Algorithm | Used for |
| --- | --- | --- |
| **Signing keys** | Ed25519 | Signing every request and callback, and verifying the counterparty's signature. See [Auth Tools](/developer-guide/auth-tools). |
| **Encryption keys** | X25519 | Encrypting data between two NPs, **only in use cases whose specification requires it** ([section 3](#3-encryption-between-nps)). |

Both public keys are registered on the [ONDC Portal](https://portal.ondc.org) and stored in the ONDC Registry. Counterparty keys are fetched from the Registry using the **lookup** and **vlookup** APIs — see [Registry & Gateway](/developer-guide/docs/registry-gateway). Private keys always stay with the NP.

---

## 1. Key Formats

| Key | Size | Format |
| --- | --- | --- |
| Ed25519 public key | 32 bytes | Raw binary, Base64 encoded |
| Ed25519 private key | 32 bytes | Raw binary — keep secret |
| X25519 public key | 32 bytes | **ASN.1 DER** encoded, Base64 encoded |
| X25519 private key | 32 bytes | Raw binary — keep secret |

> **Tip:** A Base64 ASN.1 DER-encoded X25519 public key always starts with `MCowBQYDK2VuAyEA`. If your encryption public key does not, it is probably in raw format.

---

## 2. Key Generation

Both key pairs are generated the same way:

1. **Generate a random key pair** using a cryptographically secure random number generator.
2. **Export the keys:**
    - Ed25519 — keep both keys as raw binary (Base64 encode the public key for sharing).
    - X25519 — keep the private key as raw binary; encode the public key in **ASN.1 DER** format.

| Algorithm | Specification |
| --- | --- |
| Ed25519 | [RFC 8032](https://datatracker.ietf.org/doc/html/rfc8032) |
| X25519 | [RFC 7748](https://datatracker.ietf.org/doc/html/rfc7748) |

For language-specific code, use a cryptographic library that supports Ed25519 and X25519 (for example libsodium bindings).

### Key Usage

| Key | Used by you | Used by the counterparty |
| --- | --- | --- |
| Ed25519 private key | Sign every request and callback you send | — |
| Ed25519 public key | — | Verify your signatures (fetched from the Registry) |
| X25519 private key | Derive the shared key with a counterparty (only when encryption is required) | — |
| X25519 public key | — | Derive the same shared key with you (fetched from the Registry) |

Public keys are verified by the Registry before they are stored.

---

## 3. Encryption Between NPs

> **Only if your use case requires it.** Regular Beckn API calls are signed, not encrypted, and none of the use cases under **Explore by Domain** currently requires encryption. Check the use case's specification before implementing anything in this section.

### 3.1 Shared Key Derivation

Two NPs derive the **same shared key** independently using the X25519 Diffie-Hellman key exchange — no secret is ever sent over the network.

| Step | NP1 (sender) | NP2 (receiver) |
| --- | --- | --- |
| 1 | Fetch NP2's encryption public key from the Registry | Fetch NP1's encryption public key from the Registry |
| 2 | `DiffieHellman(NP1 private key, NP2 public key)` | `DiffieHellman(NP2 private key, NP1 public key)` |
| Result | `sharedKey` | the same `sharedKey` |

NP1 side (Node.js):

```javascript
// Calculate the shared secret key using Diffie-Hellman
const sharedKey = crypto.diffieHellman({
  privateKey: MC4CAQEwBQYDK2VuBCIEIMCU0uKQ36pRs4d9Jm0aUD9Pn6qq+747AY2Kv4UhE/94,
  publicKey: MCowBQYDK2VuAyEA2qqMXULrFHhJCJEI38WnTtwojAtf9cZ3BsUid5Goah4=,
});
```

NP2 side (Node.js):

```javascript
// Calculate the shared secret key using Diffie-Hellman
const sharedKey = crypto.diffieHellman({
  privateKey: MC4CAQEwBQYDK2VuBCIEICDWXCT+/VoLE8TJ5nYbtGv5vI+sqXBtdYgrBMjD73Vz,
  publicKey: MCowBQYDK2VuAyEAmb/MUSKXvtgsPJuEQUM/imlDJ7oe9uPL/m4ta9e8Z1o=,
});
```

> The keys above are illustrative values. In code, pass key objects created with `crypto.createPrivateKey` / `crypto.createPublicKey` from the DER-encoded keys.

The shared key is then used with **AES-GCM**:

```text
encryptedString = Encrypt(data, sharedKey)      // NP1
decryptedString = Decrypt(data, sharedKey)      // NP2
```

### 3.2 What Gets Encrypted

The same key exchange and AES-GCM encryption apply to three scopes. They differ only in **how much** of the data is encrypted.

| Scope | What is encrypted | Use when |
| --- | --- | --- |
| **Field-level** | Specific sensitive attributes | Intermediaries need to read or validate the rest of the payload |
| **Payload** | The whole `message` body | The entire message is sensitive; only `context` must stay readable |
| **Blob** | An opaque object (document, image, credential) | Large or binary data must travel without being interpreted by the network |

#### Field-Level Encryption

Only the identified fields are encrypted; the rest of the payload stays in plaintext.

Example — NP1 encrypts the `token` inside an `authorization` object, and NP2 decrypts it to read the token:

```json
"authorization": {
  ...
  "token": "U2FsdGVkX1/gV/2wQx83uKkQdDpNPTq8+75IUZziK17qxdmBvsVT+KfQ==",
  "valid_to": "2024-03-23T23:59:59.999Z",
  "status": "UNCLAIMED"
}
```

#### Payload Encryption

The complete `message` JSON is serialized and encrypted as one unit. `context` stays in plaintext for routing and audit.

```json
{
    "context": {
        "domain": "ONDC:FIS13",
        "country": "IND",
        "city": "std:080",
        "action": "confirm",
        "core_version": "2.1.0",
        "bap_id": "buyer-app.ondc.org",
        "bap_uri": "https://buyer-app.ondc.org/protocol/v1",
        "bpp_id": "seller-app.ondc.org",
        "bpp_uri": "https://seller-app.ondc.org/protocol/v1",
        "transaction_id": "123e4567-e89b-12d3-a456-426614174000",
        "message_id": "123e4567-e89b-12d3-a456-426614174001",
        "timestamp": "2024-03-23T18:25:43.511Z"
    },
    "message": "U2FsdGVkX19KkzY1Fz+q2nZ4wXyQ3cVJ0mKkH9b+3l0=....."
}
```

NP2 decrypts `message` with the shared key to rebuild the original message body. The full procedure is in [section 3.3](#33-api-payload-encryption--step-by-step).

#### Blob Encryption

The blob is treated as an opaque byte stream. It can be embedded inline or referenced through a secure URI.

```json
{
    "content_type": "multipart/octet-stream",
    "encrypted_data": "U2FsdGVkX18R4Z6u7nKx3rDq8yP4KpW1zZkZ+M4="
}
```

NP2 decrypts `encrypted_data` with the shared key to get the original binary content.

### 3.3 API Payload Encryption — Step by Step

When payload encryption applies to a use case:

- The entire `message` body is encrypted — no field is readable without decryption.
- `context` stays in plaintext for network routing and audit.
- New fields added to `message` in future are encrypted automatically, with no implementation changes.

> **Note:** The receiver must decrypt `message` **before** schema validation and ACK/NACK. This adds a small processing step to the synchronous response.

#### Cryptographic Primitives

| Primitive | Role |
| --- | --- |
| X25519 / Diffie-Hellman | Shared secret derivation |
| AES-256-GCM | Symmetric payload encryption |
| Base64 | Binary-to-string encoding for JSON transport |

#### Keys Involved

| Key | Held By | Purpose |
| --- | --- | --- |
| `NP1_enc_private_key` | NP1 | Shared key derivation |
| `NP2_enc_public_key` | Registry | Shared key derivation (fetched by NP1) |
| `NP2_enc_private_key` | NP2 | Shared key derivation |
| `NP1_enc_public_key` | Registry | Shared key derivation (fetched by NP2) |

#### NP1 — Sender

**Step 1 · Derive the shared key**

```text
np2_enc_public_key = registry.fetchEncryptionPublicKey(np2_id)

sharedKey = DiffieHellman(
    privateKey = NP1_enc_private_key,
    publicKey  = np2_enc_public_key
)
```

**Step 2 · Encrypt the message body**

```text
serialized = JSON.stringify(messageBody)

iv = randomBytes(12)                          // fresh IV per API call

{ ciphertext, authTag } = AES_GCM.encrypt(
    plaintext = serialized,
    key       = sharedKey,
    iv        = iv
)

encrypted_message = Base64.encode(iv + ciphertext + authTag)
```

**Step 3 · Send the request**

```json
{
    "context": {
        "domain": "ONDC:FIS13",
        "country": "IND",
        "city": "std:080",
        "action": "confirm",
        "core_version": "2.1.0",
        "bap_id": "buyer-app.ondc.org",
        "bap_uri": "https://buyer-app.ondc.org/protocol/v1",
        "bpp_id": "seller-app.ondc.org",
        "bpp_uri": "https://seller-app.ondc.org/protocol/v1",
        "transaction_id": "123e4567-e89b-12d3-a456-426614174000",
        "message_id": "123e4567-e89b-12d3-a456-426614174001",
        "timestamp": "2024-03-23T18:25:43.511Z"
    },
    "message": "<Base64( iv + ciphertext + authTag )>"
}
```

#### NP2 — Receiver

**Step 4 · Derive the shared key**

```text
np1_enc_public_key = registry.fetchEncryptionPublicKey(np1_id)

sharedKey = DiffieHellman(
    privateKey = NP2_enc_private_key,
    publicKey  = np1_enc_public_key
)
```

**Step 5 · Decrypt the message body**

```text
rawBytes = Base64.decode(encrypted_message)

iv         = rawBytes[0:12]
authTag    = rawBytes[-16:]
ciphertext = rawBytes[12:-16]

TRY:
    decrypted = AES_GCM.decrypt(
        ciphertext = ciphertext,
        key        = sharedKey,
        iv         = iv,
        authTag    = authTag       // integrity verified automatically
    )
    messageBody = JSON.parse(decrypted)

CATCH IntegrityError  → NACK("Payload integrity check failed")
CATCH DecryptionError → NACK("Decryption failed — key mismatch or malformed payload")
```

**Step 6 · Validate the schema and respond**

```text
if NOT schema.validate(context.action, messageBody):
    → NACK("Schema validation failed")

processAction(context.action, messageBody)
→ ACK()
```

#### End-to-End Flow

```text
NP1 (Sender)                                    NP2 (Receiver)
─────────────────────────────────────────────────────────────────
1. Fetch NP2 enc public key (registry)
2. Derive sharedKey via DiffieHellman
3. JSON.stringify(messageBody)
4. Generate random IV (12 bytes)
5. AES_GCM.encrypt → Base64 encode
6. POST { context (plaintext), message (encrypted) }
                                                7.  Fetch NP1 enc public key (registry)
                                                8.  Derive sharedKey via DiffieHellman
                                                9.  Base64.decode → split iv / ciphertext / authTag
                                                10. AES_GCM.decrypt → verify authTag
                                                11. JSON.parse → messageBody
                                                12. schema.validate → ACK or NACK
                                                13. processAction
```

### 3.4 Form Encryption & Signing

Form payloads are **encrypted and signed**: the whole form body is encrypted with the shared key, and a signature over the **encrypted** payload proves who sent it. The receiver verifies the signature first, then decrypts.

#### Cryptographic Primitives

| Primitive | Role |
| --- | --- |
| X25519 / Diffie-Hellman | Shared secret derivation |
| AES-256-GCM | Symmetric payload encryption |
| Ed25519 | Payload signing & verification |
| BLAKE-512 | Digest generation before signing |
| Base64 | Binary-to-string encoding for transport |

#### Keys Involved

| Key | Held By | Purpose |
| --- | --- | --- |
| `NP1_enc_private_key` | NP1 | Shared key derivation |
| `NP2_enc_public_key` | Registry | Shared key derivation (fetched by NP1) |
| `NP1_sign_private_key` | NP1 | Signing the encrypted payload |
| `NP1_sign_public_key` | Registry | Signature verification (fetched by NP2) |

#### NP1 — Sender

**Step 1 · Derive the shared key**

```text
np2_enc_public_key = registry.fetchEncryptionPublicKey(np2_id)

sharedKey = DiffieHellman(
    privateKey = NP1_enc_private_key,
    publicKey  = np2_enc_public_key
)
```

**Step 2 · Encrypt the form payload**

```text
serialized = JSON.stringify(formData)

nonce = randomBytes(12)                        // fresh IV per submission

{ ciphertext, authTag } = AES_GCM.encrypt(
    plaintext = serialized,
    key       = sharedKey,                     // decoded from base64
    iv        = nonce
)

payload = {
    encrypted_data : Base64.encode(ciphertext),
    hmac           : Base64.encode(authTag),
    nonce          : Base64.encode(nonce)
}

encrypted_payload = Base64.encode(JSON.stringify(payload))
```

**Step 3 · Sign the encrypted payload**

Signing follows the same method as Beckn API request signing (see [Auth Tools](/developer-guide/auth-tools)), applied to `encrypted_payload`.

**3a. Generate the digest** of `encrypted_payload` using BLAKE-512:

```text
digest = Base64.encode( BLAKE512( encrypted_payload ) )
```

**3b. Build the signing string** from `created`, `expires` and the digest:

```text
signing_string = "(created): {created_unix_ts}\n(expires): {expires_unix_ts}\ndigest:BLAKE-512={digest}"
```

**3c. Sign the signing string** with the NP's Ed25519 signing private key:

```text
signature = Ed25519.sign(
    data       = signing_string,
    privateKey = NP1_sign_private_key
)

encoded_signature = Base64.encode(signature)
```

**3d. Set the Authorization header:**

```text
Authorization: Signature
  keyId="{subscriber_id}|{unique_key_id}|ed25519",
  algorithm="ed25519",
  created="{created_unix_ts}",
  expires="{expires_unix_ts}",
  headers="(created) (expires) digest",
  signature="{encoded_signature}"
```

**Step 4 · Submit the form**

Send `context` in plaintext, the `encrypted_payload` in the body, and the signature in the `Authorization` header.

**Request body:**

```json
{
  "context": {
    "action": "search",
    "bap_id": "fis.test.bap.io",
    "bap_uri": "https://fis.test.bap.io/",
    "domain": "ONDC:FIS13",
    "location": {
      "country": {
        "code": "IND"
      },
      "city": {
        "code": "*"
      }
    },
    "message_id": "385e3fb7-61e6-49a7-acbc-8ac05f934d4d",
    "timestamp": "2023-07-24T05:39:31.700Z",
    "transaction_id": "c04a04ee-d892-400f-bbe6-479a43b4448a",
    "ttl": "PT24H",
    "version": "2.0.1"
  },
  "encrypted_payload": "<encrypted_payload from Step 2>"
}
```

**Authorization header:**

```text
Signature keyId="buyer-app.ondc.org|207|ed25519",algorithm="ed25519",created="1641287875",expires="1641291475",headers="(created) (expires) digest",signature="fKQWvXhln4UdyZdL87ViXQObdBme0dHnsclD2LvvnHoNxIgcvAwUZOmwAnH5QKi9Upg5tRaxpoGhCFGHD+d+Bw=="
```

> `context` is always plaintext. `encrypted_payload` carries the secured form data. The signature travels in the `Authorization` header, not in the request body.

#### NP2 — Receiver

**Step 5 · Verify the signature**

> Always verify the signature **before** decrypting.

```text
np1_sign_public_key = registry.fetchSigningPublicKey(np1_id)

// Extract fields from the Authorization header
auth        = parseAuthorizationHeader(request.headers["Authorization"])
created     = auth.created
expires     = auth.expires
signature   = auth.signature

digest = Base64.encode( BLAKE512( encrypted_payload ) )

signing_string = "(created): {created}\n(expires): {expires}\ndigest:BLAKE-512={digest}"

isValid = Ed25519.verify(
    data      = signing_string,
    signature = Base64.decode(signature),
    publicKey = np1_sign_public_key
)

if NOT isValid → REJECT("Signature verification failed")
```

**Step 6 · Derive the shared key**

```text
np1_enc_public_key = registry.fetchEncryptionPublicKey(np1_id)

sharedKey = DiffieHellman(
    privateKey = NP2_enc_private_key,
    publicKey  = np1_enc_public_key
)
```

**Step 7 · Decrypt the form payload**

```text
payloadJSON = JSON.parse(Base64.decode(encrypted_payload))

ciphertext = Base64.decode(payloadJSON.encrypted_data)
authTag    = Base64.decode(payloadJSON.hmac)
nonce      = Base64.decode(payloadJSON.nonce)

decrypted = AES_GCM.decrypt(
    ciphertext = ciphertext,
    key        = sharedKey,
    iv         = nonce,
    authTag    = authTag
)

formData = JSON.parse(decrypted)
```

**Step 8 · Validate and process**

```text
validate(formData)
preProcess(formData)
```

#### End-to-End Flow

```text
NP1 (Sender)                                    NP2 (Receiver)
─────────────────────────────────────────────────────────────────
1. Fetch NP2 enc public key (registry)
2. Derive sharedKey via DiffieHellman
3. JSON.stringify(formData)
4. Generate random nonce (12 bytes)
5. AES_GCM.encrypt → { encrypted_data, hmac, nonce } → Base64 encode
6. BLAKE512(encrypted_payload) → construct signing string
7. Ed25519.sign → Base64 encode → Authorization header
8. POST { context, encrypted_payload } + Authorization header
                                                9.  Fetch NP1 sign public key (registry)
                                                10. Ed25519.verify → REJECT if invalid
                                                11. Fetch NP1 enc public key (registry)
                                                12. Derive sharedKey via DiffieHellman
                                                13. Base64.decode → { encrypted_data, hmac, nonce }
                                                14. AES_GCM.decrypt → verify authTag
                                                15. JSON.parse → formData
                                                16. validate & preProcess
```

---

## 4. Best Practices

- Keep private keys secure and protect them from unauthorized access.
- Use a strong, cryptographically secure random number generator for key generation.
- Use a **fresh 12-byte IV** for every encryption — never reuse an IV with the same key.
- Use the correct encoding for each key type: raw for Ed25519 keys and X25519 private keys, ASN.1 DER for X25519 public keys.
