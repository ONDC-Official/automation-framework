# ONDC Registry — Onboarding & Signing FAQ

---

## Table of Contents

1. [Version History](#version-history)
2. [Onboarding Related FAQs](#onboarding-related-faqs)
3. [Key-wise Explanation of the Subscribe Payload](#key-wise-explanation-of-the-subscribe-payload)
4. [Signature & Verification FAQs](#signature--verification-faqs)
5. [FAQs for ONDC Registry Lookup v2.0 API](#faqs-for-ondc-registry-lookup-v20-api)
6. [Additional Resources](#additional-resources)
7. [Common Errors](#common-errors)

---

## Version History

| Version | Date           | Changes                                                                |
| ------- | -------------- | ---------------------------------------------------------------------- |
| 2.0     | 2nd May 2025   | Added FAQs for Lookup V2.0                                             |
| 1.2     | 23rd Jan 2025  | Added FAQs and formatted the document                                  |
| —       | 13th Sept 2024 | Key-wise explanation of the subscribe payload                          |
| —       | 21st Aug 2024  | Refined FAQs, removed invalid questions                                |
| —       | 16th Jun 2024  | Detailed explanation of signing and verification errors                |
| 1.1     | 7th Jun 2024   | Refined FAQs, removed invalid questions                                |
| —       | 4th Mar 2024   | FAQs added based on errors encountered while hitting the subscribe API |
| —       | 4th Jan 2024   | General onboarding process questions added                             |

---

## Onboarding Related FAQs

### What should be used as a `subscriber_id` — an HTTP domain or a text ID?

In ONDC, the `subscriber_id` is a unique identifier assigned to a network participant (such as a buyer app, seller app, or logistics provider) during the onboarding process. It is typically the domain name or endpoint that uniquely identifies the participant within the ONDC network.

**Key characteristics:**

- The default value of `subscriber_id` is the **Fully Qualified Domain Name (FQDN)** of the subscriber (e.g., `ondc.seller.example`), unless specified otherwise by network policy.
- It is used in API requests to identify who is making the call, and appears in the `context` object of ONDC payloads.
- It is linked to authentication — used along with `unique_key_id` (UKID) to sign and verify API requests.
- It is part of the ONDC Registry's Subscriber object, which stores participant details.
- Both `bap_id` (Buyer App) and `bpp_id` (Seller App) in payloads are `subscriber_id`s.

```json
{
    "context": {
        "domain": "nic2004:52110",
        "bap_id": "buyerapp.example.com",
        "bpp_id": "ondc.seller.example",
        "unique_key_id": "1234567890",
        "timestamp": "2023-05-15T10:00:00Z"
    }
}
```

---

### What is the difference between `subscriber_id` and `subscriber_url`?

ONDC uses two distinct identifiers for subscribers. While both identify participants in the network, they serve different purposes:

| Field            | Meaning                                                                                        | Example                             |
| ---------------- | ---------------------------------------------------------------------------------------------- | ----------------------------------- |
| `subscriber_id`  | Unique identifier of the participant (usually a domain). Used for identity and authentication. | `sellerapp.example.com`             |
| `subscriber_url` | The actual base URL (endpoint) where the participant's APIs are hosted and accessible.         | `https://api.sellerapp.example.com` |

**Example:** If a network participant's domain is `ondc.seller.example`, then:

- `subscriber_id` = `ondc.seller.example`
- `subscriber_url` = `https://ondc.seller.example/` (or any sub-route under that domain)

> **Note:** Ensure that the `subscriber_url` includes the `subscriber_id`.

---

### Error: Subscriber ID Not Whitelisted

```json
{
    "message": { "ack": { "status": "NACK" } },
    "error": {
        "type": "POLICY-ERROR",
        "code": "144",
        "path": null,
        "message": "Subscriber Id is not whitelisted in our database"
    }
}
```

**Resolution:** Get your `subscriber_id` whitelisted/approved by ONDC:

- **Staging:** Register on the ONDC Portal and complete your profile to 100%. Then request domain whitelisting via **Home → Environment Access Request**.
- **Pre-Prod:** Submit the required Self Declaration through the portal and raise a whitelisting request via the portal.
- **Production:** After preprod logs are verified and the QA process is completed, raise a whitelisting request through the portal as with other environments.

---

### Error: Domain Verification Failed

```json
{
    "message": { "ack": { "status": "NACK" } },
    "error": {
        "type": "POLICY-ERROR",
        "code": "132",
        "path": null,
        "message": "Domain verification is failed"
    }
}
```

**Cause:** The `request_id` in your subscribe payload does not match the `request_id` signed with your private key. If they do match, the issue may be a mismatch in the signing key pair.

**Resolution:**

- Ensure you use the **same `request_id`** in the subscribe utility code as in the subscribe payload.
- If you have a custom implementation, refer to the official Python, Java, PHP, or Node.js utilities to understand the correct implementation in your language.

---

### Error: `ondc-site-verification` File Not Found

```json
{
    "message": { "ack": { "status": "NACK" } },
    "error": {
        "type": "POLICY-ERROR",
        "code": "132",
        "path": null,
        "message": "ondc-site-verification file is not found"
    }
}
```

**Resolution:**

1. Create an `ondc-site-verification.html` file and host it at the **domain root level**.
    - Example: `https://<subscriber_id>/ondc-site-verification.html`
2. Use the correct HTML formatting as provided in the official documentation.
3. If you have a firewall or IP blocking on your server, whitelist the following IPs:

```
34.131.40.9    34.131.211.247   34.131.201.63   34.131.180.63
34.131.78.219  34.93.10.146     35.200.143.183  34.93.118.120
35.200.183.209 34.93.102.253    35.200.232.136  34.100.170.176
107.178.231.181/32
```

---

### Error: OCSP Failed

```json
{
    "message": { "ack": { "status": "NACK" } },
    "error": {
        "type": "POLICY-ERROR",
        "code": "132",
        "path": null,
        "message": "OCSP failed"
    }
}
```

**Cause:** Your domain does not have a valid SSL certificate that supports OCSP (Online Certificate Status Protocol) validation.

**Resolution:** Obtain a valid SSL certificate for your domain that supports OCSP validation.

---

### How does a subscriber get the Registry's public keys to decrypt information from `on_subscribe`?

The Registry's public keys are provided in the official ONDC documentation (point no. 6).

---

### How do I generate signing and encryption key pairs?

You can use the official key generation utilities provided by ONDC. Refer to the **Key Generation Utilities** section in the documentation.

---

### What is the export format for the public key?

There are two fundamental formats in which Ed25519 and X25519 keys are exported:

- **Raw** — Simply the Base64-encoded raw bytes of the key.
- **PEM** — Typically used by JCA/JCE; this is the Base64-encoded X.509-encoded public key.

If you generate an Ed25519 key pair online, you will generally get it in **raw format**. Both formats are interconvertible. Since raw format is more prevalent, it is recommended for communication with the ONDC registry.

---

### Which algorithm does the BAP use for decrypting the Challenge String?

The **X25519 Key Agreement** algorithm is used to derive a symmetric **AES key** for encryption and decryption between any two parties (including between the registry and participants). This derived AES key is then used to encrypt and decrypt the challenge.

---

### Is `subscriber_id` unique across the network, or is it the `unique_key_id`?

**Both** `subscriber_id` and `unique_key_id` must be unique throughout the network for each Network Participant. Both identifiers need to be unique for each onboarded NP.

---

### Should we validate `bpp_id` or `bap_id` in the context against the Authorization header?

Yes. When a BPP receives a request, if the `bap_id` in the context does not match the `bap_id` in the signature, the BPP **must return a `401 Unauthorized` response**.

---

### What cipher is used to encrypt the challenge?

The encryption uses **AES**, but the AES key is derived using the **X25519 key agreement mechanism**.

Every participant registers two public keys with the registry — one **Ed25519** (signing) and one **X25519** (encryption) — and retains their corresponding private keys.

**Encryption flow:**

1. The Registry uses its own private key and the participant's public key to derive the AES key.
2. The Registry uses this AES key to encrypt the challenge.

**Decryption flow:**

1. The participant uses their own private key and the Registry's public key to re-derive the same AES key.
2. The participant uses this AES key to decrypt the challenge.

---

### If Subscriber A needs Subscriber B's public key, does it need to call the Lookup API?

Yes. Subscriber A must call the **Lookup API** to retrieve Subscriber B's public key and verify their existence in the registry. The Lookup API only returns records with status `SUBSCRIBED` or `WHITELISTED`.

**Why Lookup?**

1. **Public-key cryptography:** Subscriber A needs Subscriber B's public key to verify signatures and ensure the message originates from a trusted source.
2. **Active status check:** The lookup response includes a `status` field. Subscriber A should confirm that Subscriber B's status is `SUBSCRIBED` before proceeding.

**Example cURL:**

```bash
curl --location 'https://prod.registry.ondc.org/v2.0/lookup' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Signature keyId="example-bap.com|bap1234|ed25519", algorithm="ed25519", created="<timestamp>", expires="<timestamp>", headers="(created)(expires)digest", signature="<signature>"' \
  --data '{
    "country": "IND",
    "domain": "ONDC:RET10"
  }'
```

---

### Is the Lookup API mandatory before every API request?

No, the Lookup API does not need to be called before every request. It is a utility to resolve information about another participant — typically their public keys, network roles, or endpoint details — whenever required.

**Recommendation for efficiency:** Cache the public registry dump periodically. Use your local cache for most lookups and fall back to the `v2.0/lookup` API only when the cache is stale or a new participant needs to be resolved.

---

### Why does `subscriber_url` appear as `null` in the registry after subscribing?

The `subscriber_url` shows as `null` when the participant is only whitelisted. It gets populated in the registry once you complete the onboarding by calling the **subscribe API** with your `subscriber_url`. The value provided in that API call will be saved and reflected in the registry.

---

## Key-wise Explanation of the Subscribe Payload

### `ops_no`

| Value | Meaning                         |
| ----- | ------------------------------- |
| `1`   | Buyer App Registration          |
| `2`   | Seller App Registration         |
| `4`   | Buyer & Seller App Registration |

> **Note:** `ops_no` values `3` and `5` are deprecated, as the Seller On Record (SOR) feature in the registry is now obsolete.

---

### `request_id` and `unique_key_id`

Both `request_id` and `unique_key_id` are **distinct random alphanumeric strings or UUIDs** generated by the network participant.

---

### `callback_url`

The `callback_url` is a **relative path** provided during the subscription process that tells ONDC where to send verification callbacks (e.g., `on_subscribe`).

The final callback endpoint is constructed as:

```
https://<subscriber_url>/<callback_url>/on_subscribe
```

**Example:**

| Field                    | Value                                                     |
| ------------------------ | --------------------------------------------------------- |
| `subscriber_id`          | `www.sellerapp.example.com`                               |
| `callback_url`           | `/api/ondc`                                               |
| Final `on_subscribe` URL | `https://www.sellerapp.example.com/api/ondc/on_subscribe` |

---

### `key_pairs`

The network participant must include the `signing_public_key` and `encryption_public_key` in the subscribe payload (generated during the key generation process). They must also specify the validity period using `valid_from` and `valid_until`.

---

### `network_participant`

The `network_participant` array contains a `domains` object specifying the domains to subscribe to. Each whitelisted domain requires a separate entry:

```json
"network_participant": [
  {
    "subscriber_url": "/ret10",
    "domain": "ONDC:RET10",
    "type": "sellerApp",
    "msn": false,
    "city_code": ["*"]
  },
  {
    "subscriber_url": "/ret11",
    "domain": "ONDC:RET11",
    "type": "sellerApp",
    "msn": false,
    "city_code": ["*"]
  }
]
```

---

### `subscriber_url` (within `network_participant`)

This field represents the **relative path** to where your transactional API endpoints are hosted.

**Examples:**

| Endpoint                      | `subscriber_url` |
| ----------------------------- | ---------------- |
| `subscriber_id/api/v1/search` | `/api/v1`        |
| `subscriber_id/ret10/search`  | `/ret10`         |
| Hosted at root level          | `/`              |

Different domains can use different relative paths (e.g., `ONDC:RET10` → `/ret10`, `ONDC:RET11` → `/ret11`). An API versioning approach such as `/api/v1` is also acceptable.

---

## Signature & Verification FAQs

### Common Signature Error Types

#### 1. Auth Header Not Found

**Cause:** API requests are being made without an Authorization header.

**Resolution:** Generate the Authorization header per the ONDC protocol. This involves:

- Signing the request payload using your private key.
- Constructing the header in the correct Authorization format.
- Including the required timestamps and identifiers.

You can also use the **ONDC header generation utility** to simplify this process.

---

#### 2. Authentication Failed

**Cause:** The `unique_key_id` used during subscription does not match the one used in header generation. Alternatively, the `subscriber_id` in the header may not exist in the registry.

**Resolution:** Retrieve the correct `unique_key_id` by calling the Lookup API with your `subscriber_id`. Use the correct `ukId` and `subscriber_id` when generating the Authorization header.

---

#### 3. Invalid Signature

**Cause:** The signature was not created using the private key that corresponds to the public key registered with the ONDC network during subscription.

**Resolution:** Always use the **private key matching the public key you shared during subscription** to create your signature.

---

#### 4. Signature Verification Failed

**Cause:** The decrypted signature does not match the request body payload. This is commonly caused by payload formatting — tools like VS Code may automatically beautify JSON, introducing extra spaces that break the signature.

**Resolution:** **Minify the payload** both during signature generation and before making the API call.

---

#### 5. Signature Is Forged

**Cause:** The signature is not included in the Authorization header in the correct format. This can result from altered key-value pair ordering or extra spaces being added.

**Resolution:** Ensure your Authorization header strictly adheres to the specified format (see the format example in the Common Errors section).

---

#### 6. Algorithm Mismatch

**Cause:** Encryption was not performed using the ONDC-defined method.

**Resolution:** Use the ONDC utility functions exactly as provided. If you prefer a custom implementation, ensure the following:

- Hashing the request body digest uses the **BLAKE2b-512** algorithm.
- Signing the signing string uses the **Ed25519** algorithm.

---

### I'm facing signature verification issues with the Reference Apps or Mock Servers. How do I resolve this?

Check the following common causes:

1. **Payload mismatch:** You may be signing a minified payload but sending a beautified one (or vice versa). The exact bytes of the payload must be identical at signing time and request time.
2. **Escape characters:** Ensure no escape characters are present in the signature in place of spaces.
3. **Timestamp modification:** If you change the `context.timestamp` after generating the signature, the request will receive a NACK. Any modification after signing invalidates the signature.
4. **Wrong credentials:** Verify you are using the correct `subscriber_id` and `unique_key_id` when generating the signature.
5. **Header placement:** Place the signature in the `Authorization` header — **not** in the Bearer Token field.
6. **Stringified signature:** If you generate the signature via an endpoint that returns JSON, the result will be a stringified value with escape characters. Ensure the signature is extracted cleanly and remains unaltered before use.

---

## FAQs for ONDC Registry Lookup v2.0 API

### What is Lookup v2.0?

Lookup v2.0 is an ONDC Registry API that allows participants (BAPs, BPPs, etc.) to securely query network details — such as seller/buyer endpoints, public keys, and `unique_key_id` — using **signed requests**.

---

### How do I access Lookup v2.0?

| Environment | Endpoint                                        |
| ----------- | ----------------------------------------------- |
| Staging     | `https://staging.registry.ondc.org/v2.0/lookup` |
| Pre-Prod    | `https://preprod.registry.ondc.org/v2.0/lookup` |
| Production  | `https://prod.registry.ondc.org/v2.0/lookup`    |

---

### What authentication is required?

All requests must include an Authorization header with:

- A **signature** (Ed25519 algorithm)
- `created` and `expires` timestamps (ISO 8601 UTC format)
- A `digest` (Blake2b hash of the request body)

**Example:**

```bash
curl --location 'https://prod.registry.ondc.org/v2.0/lookup' \
  --header 'Authorization: Signature keyId="example-bap.com|bap1234|ed25519", algorithm="ed25519", created="2024-05-04T12:00:00Z", expires="2024-05-04T12:05:00Z", headers="(created)(expires)digest", signature="<base64_signature>"' \
  --data '{"country": "IND", "domain": "ONDC:RET10"}'
```

---

### How do I generate the signature?

Follow the standard **Signing and Verification Guide**, or use the ready-to-use utilities provided in multiple programming languages (Python, Java, PHP, Node.js).

---

### What parameters are mandatory in the request body?

There are no fixed mandatory parameters. However, you must provide **at least any two** of the following keys:

- `subscriber_id`
- `country`
- `ukId`
- `city`
- `domain`
- `type` (`BAP` or `BPP`)

Providing fewer than two keys will result in an error.

---

### What is the difference between v1.0 and v2.0?

| Feature              | v1.0         | v2.0                                               |
| -------------------- | ------------ | -------------------------------------------------- |
| Authorization header | Not required | **Required**                                       |
| Request signing      | Optional     | **Mandatory**                                      |
| Security             | Basic        | Enforces sender authenticity and payload integrity |

In v2.0, you sign the lookup payload using the **same private key used during onboarding**.

---

### What if my request fails with `401 Unauthorized`?

Check the following:

- Verify the signature format and the `created`/`expires` timestamps.
- Ensure the `digest` matches the request body.
- Confirm that the Ed25519 public key is registered with ONDC.

---

### Where can I find sample signing code?

Refer to the **Reference Utility on GitHub** for signing and verification examples.

---

### What is the purpose of the ONDC Registry Lookup?

It allows a participant to verify another participant's metadata — such as their domain, signing public key, and endpoint — before processing a request.

---

### What data is returned in a lookup response?

| Field                      | Description                          |
| -------------------------- | ------------------------------------ |
| `subscriber_id`            | Unique identifier of the participant |
| `domain`                   | The subscribed domain                |
| `signing_public_key`       | Public key used to verify signatures |
| `callback_urls`            | Registered callback endpoints        |
| `city` and `country` codes | Geographic scope                     |
| `status`                   | e.g., `SUBSCRIBED`, `UNSUBSCRIBED`   |

---

### When should the Lookup API be called?

Before processing any signed request, the receiving participant should perform a lookup to validate:

- Whether the sender is a valid ONDC participant.
- That the public key used for signature verification is current and active.

---

### Can lookup responses be cached?

Yes. Caching lookup responses can significantly improve performance. However, refresh the cache periodically (e.g., every few hours) and perform real-time lookups for critical operations such as order confirmations to ensure data accuracy.

---

## Additional Resources

- [Signing and Verification Process](#)
- [Reference Utility — Signing (GitHub)](#)
- [Lookup API Swagger](#)

---

## Common Errors

### Auth Header Not Found

**Cause:** API requests are being made without an Authorization header.

**Resolution:** Generate the Authorization header per the ONDC protocol, including the signed payload, correct format, and required timestamps. You can also use the **ONDC header generation utility**.

---

### Subscriber Not Found

**Cause:** Invalid signature format, `subscriber_id` not found, presence of backslashes or escape characters in the header, or the `subscriber_id` does not exist in the registry.

**Resolution:** Ensure the header format strictly matches the expected structure with no backslashes, escape characters, or unintended formatting. Verify that the `subscriber_id` exists in the registry with `SUBSCRIBED` status.

**Expected header format:**

```
Signature keyId="buyer-app.ondc.org|207|ed25519",algorithm="ed25519",created="1641287875",expires="1641291475",headers="(created) (expires) digest",signature="fKQWvXhln4UdyZdL87ViXQObdBme0dHnsclD2LvvnHoNxIgcvAwUZOmwAnH5QKi9Upg5tRaxpoGhCFGHD+d+Bw=="
```

---

### Algorithm Mismatch in Header

**Cause:** Invalid format, extra characters, or slashes in the `algorithm` section of the header.

**Resolution:** Verify the header format matches the expected structure exactly — no backslashes or extra characters allowed.

---

### The Request Has Expired

**Cause:** The `expires` timestamp in the signature header has either passed or is incorrectly formatted. Since the expiry timestamp is part of the signed data, modifying it without regenerating the signature will cause verification to fail.

**Resolution:**

- Ensure `created` and `expires` timestamps are correctly set relative to the current time and within the valid window.
- Verify the header format strictly adheres to the expected structure with no extra characters or escape sequences.
- If any timestamp is modified, **regenerate the signature** to maintain integrity.

---

### Header Parsing Failed / Invalid Headers Present

**Cause:** Invalid format, extra characters, or slashes in the `headers` section of the Authorization header.

**Resolution:** Review the header format carefully and ensure there are no extra characters, slashes, or escape sequences.

---

### Signature Verification Failed

**Cause:** Mismatch between the payload and the signing string, often caused by JSON beautification — even if the content is semantically identical, whitespace differences will cause verification to fail.

**Resolution:**

- **Stringify and minify** the JSON before signing.
- The request body sent must be the **exact same payload** that was signed — no beautification, extra spaces, or formatting changes.
- Minified JSON is strongly preferred.

---

_End of Document_
