# ONDC Gateway & Registry

> A concise, developer-focused guide to the two core network infrastructure components that every Network Participant interacts with.

---

## Overview

As a Network Participant (NP) developer, you never build the Gateway or the Registry — ONDC operates them. But your application **constantly interacts** with both, so understanding what they do, when your code talks to them, and what to expect back is essential.

In short:

- **Registry** = the phonebook. You look up other NPs here, and other NPs look you up here.
- **Gateway** = the broadcaster. It fans out `search` requests to relevant sellers so buyers don't need to know every BPP on the network.

---

## 1. The Registry

### What It Is

The Registry is ONDC's **trust and identity infrastructure**. It's a centralized lookup service that stores the identity, public keys, and endpoint metadata for every registered NP on the network. Think of it as DNS + a public key directory combined.

### What It Stores (Per NP Entry)

| Field                | What It Means to You                                                                         |
| -------------------- | -------------------------------------------------------------------------------------------- |
| `subscriber_id`      | The NP's unique identifier (FQDN-based, e.g., `seller-app.com`)                              |
| `subscriber_url`     | The base URL where this NP receives protocol callbacks                                       |
| `signing_public_key` | Ed25519 public key — you use this to **verify** signatures on incoming requests from this NP |
| `encr_public_key`    | X25519 encryption public key — used during onboarding challenge-response                     |
| `unique_key_id`      | Key identifier (an NP can have multiple keys)                                                |
| `type`               | Role — `BAP`, `BPP`, or `BG`                                                                 |
| `domain`             | Which domains this NP operates in (e.g., `ONDC:RET10`, `ONDC:TRV11`)                         |
| `status`             | Registration status (`SUBSCRIBED`, `INITIATED`, etc.)                                        |
| `city`               | City codes this NP serves                                                                    |

### When Your Code Talks to the Registry

**1. During Onboarding (`/subscribe` → `/on_subscribe`)**

This is a one-time (per environment) registration flow. Your server calls `/subscribe` with your metadata and public keys. The Registry calls back on `/on_subscribe` with an encrypted challenge. You decrypt it and return the plaintext. If successful, you're registered.

```
Your NP ── POST /subscribe ──────────> Registry
Your NP <── POST /on_subscribe ─────── Registry  (encrypted challenge)
Your NP ── plaintext response ────────> Registry  (sync)
```

**2. During Every Incoming Request (Signature Verification)**

When you receive an API call (e.g., a BAP sends you `/init`), you need to verify the sender's signature. To do that, you need their public key. You get it from the Registry via `/lookup` or `/vlookup`.

```
Incoming request with Authorization header
  → Extract subscriber_id + unique_key_id from keyId
  → POST /lookup to Registry (or use cached key)
  → Get signing_public_key
  → Verify Ed25519 signature
```

**3. During Outgoing Requests (Resolving the Counterparty)**

If you need to find a counterparty's callback URL or verify they're a valid NP, you look them up in the Registry.

### Registry API Endpoints

| Environment    | `/subscribe`                               | `/lookup`                               | `/vlookup`                               |
| -------------- | ------------------------------------------ | --------------------------------------- | ---------------------------------------- |
| **Staging**    | `staging.registry.ondc.org/subscribe`      | `staging.registry.ondc.org/lookup`      | `staging.registry.ondc.org/vlookup`      |
| **Pre-Prod**   | `preprod.registry.ondc.org/ondc/subscribe` | `preprod.registry.ondc.org/ondc/lookup` | `preprod.registry.ondc.org/ondc/vlookup` |
| **Production** | `prod.registry.ondc.org/subscribe`         | `prod.registry.ondc.org/lookup`         | `prod.registry.ondc.org/vlookup`         |

> **Note:** Pre-Prod URLs have the `/ondc/` path prefix. Staging and Production do not.

### `/lookup` vs `/vlookup`

| API        |          Auth Required?           | Purpose                                                                                                |
| ---------- | :-------------------------------: | ------------------------------------------------------------------------------------------------------ |
| `/lookup`  | No (Staging/Pre-Prod), Yes (Prod) | Basic lookup — returns NP entries matching your query filters                                          |
| `/vlookup` |       Yes (signed request)        | Verified lookup — the response itself is signed by the Registry, so you can trust it cryptographically |

**`/lookup` Request Example:**

```bash
curl -X POST https://prod.registry.ondc.org/lookup \
  -H "Content-Type: application/json" \
  -H "Authorization: Signature keyId=\"your-app.com|key123|ed25519\", ..." \
  -d '{
    "subscriber_id": "seller-app.com",
    "domain": "ONDC:RET10",
    "type": "BPP",
    "country": "IND"
  }'
```

### Caching Strategy

You don't want to hit the Registry on every single incoming request. In practice:

- Cache public keys locally, keyed by `subscriber_id` + `unique_key_id`.
- Set a reasonable TTL (commonly a few hours to a day).
- Invalidate and re-fetch on signature verification failure — the NP may have rotated keys.

---

## 2. The Gateway (BG)

### What It Is

The Beckn Gateway is a **search multicast router**. Its single job is to take a `search` request from a BAP and fan it out to all BPPs that are relevant based on the search context (domain, city, etc.).

### Why It Exists

Without the Gateway, a BAP sending a search request would need to:

1. Know every BPP on the network.
2. Maintain an up-to-date list of which BPPs serve which domains and cities.
3. Send the search request to each one individually.

The Gateway eliminates this burden. The BAP sends **one** search request to the Gateway, and the Gateway handles the fan-out.

### When Your Code Talks to the Gateway

**If you're a BAP:**

You send `search` to the Gateway instead of individual BPPs. That's it. The Gateway is **only** involved in the `search` → `on_search` flow. Everything from `select` onward goes **directly** to the BPP, using the `bpp_id` and `bpp_uri` you received in the `on_search` callback.

```
         search flow (via Gateway)
BAP ──search──> Gateway ──search──> BPP₁
                         ──search──> BPP₂
                         ──search──> BPP₃

BPP₁ ──on_search──> BAP  (direct, not via Gateway)
BPP₂ ──on_search──> BAP
BPP₃ ──on_search──> BAP

         everything after search (direct)
BAP ──select──> BPP₂   (direct, using bpp_uri from on_search)
BPP₂ ──on_select──> BAP
...
```

**If you're a BPP:**

You receive `search` requests from the Gateway. The `context` object tells you who the original BAP is (`bap_id`, `bap_uri`). You process the search and send `on_search` **directly back to the BAP** (not to the Gateway).

> The Gateway also adds its own signature via the `X-Gateway-Authorization` header. Your BPP should verify this header against the Gateway's public key (looked up from the Registry) in addition to verifying the BAP's `Authorization` header.

### What the Gateway Does NOT Do

- It does **not** participate in `select`, `init`, `confirm`, `status`, or any other API — only `search`.
- It does **not** store or cache catalog data.
- It does **not** route `on_search` callbacks — BPPs send those directly to the BAP.
- It does **not** handle payments, fulfillment, or grievances.
- It is **not** a proxy or middleware for ongoing transactions.

### Gateway Authorization

When the Gateway forwards a `search` request to a BPP, the request carries **two** authorization headers:

| Header                    | Signed By           | Purpose                                                |
| ------------------------- | ------------------- | ------------------------------------------------------ |
| `Authorization`           | The originating BAP | Proves the search request came from a legitimate BAP   |
| `X-Gateway-Authorization` | The Gateway         | Proves the Gateway legitimately forwarded this request |

As a BPP developer, you should verify **both** signatures.

---

## 3. How They Work Together

```
                    ┌──────────────┐
                    │   Registry   │
                    │              │
                    │  • Identity  │
                    │  • Pub Keys  │
                    │  • Lookup    │
                    └──────┬───────┘
                           │
              lookup/verify│on every request
                           │
       ┌───────────────────┼───────────────────┐
       │                   │                   │
 ┌─────┴─────┐      ┌─────┴─────┐      ┌─────┴─────┐
 │    BAP    │      │  Gateway  │      │    BPP    │
 │           │      │   (BG)    │      │           │
 │  Buyer    │      │  Search   │      │  Seller   │
 │  Side     │      │  Fan-out  │      │  Side     │
 └─────┬─────┘      └─────┬─────┘      └─────┬─────┘
       │                   │                   │
       │── search ────────>│── search ────────>│
       │                   │                   │
       │<──────────── on_search ───────────────│  (direct)
       │                                       │
       │── select ────────────────────────────>│  (direct)
       │<──────────── on_select ───────────────│
       │                                       │
       │        ... rest of lifecycle ...       │
```

The Registry is the **always-on background service** — your code hits it for key lookups and verification. The Gateway is the **one-time fan-out for search** — your code interacts with it briefly at the start of a transaction, and then never again for that transaction.

---

## 4. Common Pitfalls

**Registry:**

- **Forgetting to cache keys** — Hitting `/lookup` on every request adds latency and can get you rate-limited.
- **Not handling key rotation** — If signature verification fails, re-fetch the key from the Registry before returning a NACK. The NP may have rotated keys.
- **Mixing environment credentials** — Staging keys don't work in Pre-Prod. Pre-Prod tokens don't work in Prod. Each environment is completely isolated.
- **Pre-Prod URL path difference** — Pre-Prod uses `/ondc/lookup` while Staging and Prod use `/lookup`. This catches people during environment migration.

**Gateway:**

- **Sending non-search APIs to the Gateway** — Only `search` goes through the Gateway. Sending `select` or `init` to the Gateway will fail.
- **Sending `on_search` back to the Gateway** — BPPs must send `on_search` directly to the BAP's `bap_uri`, not back to the Gateway.
- **Ignoring `X-Gateway-Authorization`** — As a BPP, verify both the BAP signature (`Authorization`) and the Gateway signature (`X-Gateway-Authorization`).
- **Assuming a single `on_search` response** — A BAP may receive `on_search` callbacks from multiple BPPs for a single search. Your code should handle accumulating results over a window defined by the `ttl` in the context.

---
