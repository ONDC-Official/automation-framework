# ONDC

> A comprehensive, protocol-focused introduction to the Open Network for Digital Commerce for developers who are encountering ONDC for the first time.

---

## Table of Contents

- [1. What is ONDC?](#1-what-is-ondc)
    - [1.1 The Problem It Solves](#11-the-problem-it-solves)
    - [1.2 The Core Idea](#12-the-core-idea)
    - [1.3 Real-World Analogy](#13-real-world-analogy)
- [2. Key Concepts & Terminology](#2-key-concepts--terminology)
    - [2.1 Network Participants (NPs)](#21-network-participants-nps)
    - [2.2 BAP and BPP](#22-bap-and-bpp)
    - [2.3 Gateway (BG)](#23-gateway-bg)
    - [2.4 Registry](#24-registry)
    - [2.5 Domains](#25-domains)
- [3. Protocol Architecture](#3-protocol-architecture)
    - [3.1 The Two-Layer Model](#31-the-two-layer-model)
    - [3.2 Beckn Protocol — The Base Layer](#32-beckn-protocol--the-base-layer)
    - [3.3 ONDC Network Extension — The Upper Layer](#33-ondc-network-extension--the-upper-layer)
- [4. How Communication Works](#4-how-communication-works)
    - [4.1 Server-to-Server, Always](#41-server-to-server-always)
    - [4.2 Asynchronous by Design](#42-asynchronous-by-design)
    - [4.3 The Request ↔ Callback Pattern](#43-the-request--callback-pattern)
    - [4.4 ACK / NACK — The Synchronous Handshake](#44-ack--nack--the-synchronous-handshake)
- [5. The Transaction Lifecycle](#5-the-transaction-lifecycle)
    - [5.1 Discovery](#51-discovery)
    - [5.2 Order](#52-order)
    - [5.3 Fulfillment](#53-fulfillment)
    - [5.4 Post-Fulfillment](#54-post-fulfillment)
    - [5.5 Complete API Map](#55-complete-api-map)
- [6. The Context Object](#6-the-context-object)
- [7. Security & Trust](#7-security--trust)
    - [7.1 Digital Signing (Ed25519)](#71-digital-signing-ed25519)
    - [7.2 The Authorization Header](#72-the-authorization-header)
    - [7.3 Verification Flow](#73-verification-flow)
    - [7.4 Encryption (X25519)](#74-encryption-x25519)
- [8. Registry & Onboarding](#8-registry--onboarding)
    - [8.1 What is the Registry?](#81-what-is-the-registry)
    - [8.2 Environments](#82-environments)
    - [8.3 Onboarding Flow (Simplified)](#83-onboarding-flow-simplified)
    - [8.4 Registry Lookup](#84-registry-lookup)
- [9. Network Observability (NO)](#9-network-observability-no)
- [10. Putting It All Together — A Complete Transaction](#10-putting-it-all-together--a-complete-transaction)
- [11. Developer Resources](#11-developer-resources)
- [12. Glossary](#12-glossary)

---

## 1. What is ONDC?

### 1.1 The Problem It Solves

Traditional e-commerce platforms are **monolithic and closed**. If you're a seller on Platform A, your products are only visible to buyers on Platform A. If a buyer uses Platform B, they can never discover you — unless you also integrate with Platform B, and Platform C, and so on.

This creates platform lock-in, stifles competition, and consolidates power with a few dominant aggregators.

### 1.2 The Core Idea

**ONDC (Open Network for Digital Commerce)** is an open, decentralized network backed by the Government of India's Department for Promotion of Industry and Internal Trade (DPIIT). It unbundles the typical e-commerce platform into interoperable components:

- **Buyer applications** (consumer-facing apps) are decoupled from **seller applications** (merchant/provider-facing platforms).
- Any buyer app can discover and transact with any seller app on the network.
- No single entity owns the transaction, the data, or the relationship.

Think of it as **UPI for e-commerce** — just as UPI allowed any bank's app to send money to any other bank's app, ONDC allows any buyer app to purchase from any seller app.

### 1.3 Real-World Analogy

Imagine email. Gmail users can send email to Outlook users because both systems speak SMTP. Neither Google nor Microsoft "owns" the email network. ONDC works similarly — it defines a **shared protocol** (based on Beckn) that all participants speak, enabling interoperability without a central platform.

---

## 2. Key Concepts & Terminology

### 2.1 Network Participants (NPs)

Any entity registered on the ONDC network is a **Network Participant**. Every NP has a unique **subscriber ID** (essentially a domain name like `example-buyer.com`) and is registered in the ONDC **Registry**.

### 2.2 BAP and BPP

These are the two primary roles on the network:

| Role    | Full Name                  | What It Does                                                                                                                             | Examples                                                                    |
| ------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| **BAP** | Beckn Application Platform | The **buyer-side** application. It sends requests on behalf of consumers — searching for products, placing orders, checking status, etc. | A food delivery app, a shopping app, a mobility app                         |
| **BPP** | Beckn Provider Platform    | The **seller-side** application. It responds with catalogs, confirms orders, provides fulfillment updates, etc.                          | A restaurant management system, an inventory platform, a logistics provider |

A single company can operate as both a BAP and a BPP, but they are logically distinct roles with separate subscriber IDs.

### 2.3 Gateway (BG)

The **Beckn Gateway** is an intermediary that handles **discovery** (the `search` flow). When a BAP sends a search request without knowing which BPPs to contact, the Gateway multicasts that request to all relevant BPPs based on criteria like location and domain.

The Gateway is **only** involved during discovery. All subsequent communication (`select`, `init`, `confirm`, etc.) happens **directly** between the BAP and the BPP — peer-to-peer.

### 2.4 Registry

The **Registry** is the trust anchor of the network. It stores the public keys, subscriber IDs, callback URLs, and supported domains of every registered NP. When an NP receives a request, it looks up the sender's public key in the Registry to verify the digital signature.

### 2.5 Domains

ONDC is domain-agnostic at the protocol level, but each vertical (retail, logistics, mobility, financial services, etc.) defines its own **domain code** and domain-specific schema extensions. Examples include `ONDC:RET10` (Grocery), `ONDC:RET11` (Food & Beverage), `ONDC:TRV10` (Mobility), `ONDC:FIS10` (Financial Services), and `ONDC:LOG10` (Logistics).

The protocol layer described in this document remains the same across all domains.

---

## 3. Protocol Architecture

### 3.1 The Two-Layer Model

ONDC's protocol is structured as two distinct layers:

```
┌────────────────────────────────────────────────┐
│       ONDC Network Extension Layer             │
│  (Domain-specific API contracts, policies,     │
│   network rules, IGM, RSF, NO, etc.)           │
├────────────────────────────────────────────────┤
│       Beckn Protocol — Base Layer              │
│  (Core APIs, Core Schema, Communication        │
│   Protocol, Authentication, Domain Taxonomy)   │
└────────────────────────────────────────────────┘
```

### 3.2 Beckn Protocol — The Base Layer

[Beckn](https://becknprotocol.io/) is an open-source, domain-agnostic protocol for decentralized commerce. It defines:

- **Core APIs** — Transaction APIs modeled after the order lifecycle (`search`, `select`, `init`, `confirm`, `status`, `track`, `update`, `cancel`) and their corresponding callbacks (`on_search`, `on_select`, etc.). There are also Supporting APIs for non-transactional operations like `rating` and `support`.
- **Core Schema** — The data model for commerce interactions, specified using OpenAPI 3.x. Defines objects like `Order`, `Item`, `Provider`, `Fulfillment`, `Payment`, `Billing`, etc.
- **Communication Protocol** — The rules governing how APIs are called (async, server-to-server, ACK-based).
- **Authentication** — How participants digitally sign and verify messages.
- **Domain Taxonomy** — A mechanism for adding industry-specific attributes to the core schema.

Beckn is **transport-layer-agnostic**. While HTTP is the most common implementation, the protocol itself doesn't mandate it.

### 3.3 ONDC Network Extension — The Upper Layer

ONDC builds on top of Beckn by adding:

- **Domain-specific API contracts** — Customized schemas and flows for retail, logistics, mobility, financial services, etc.
- **Network policies** — Rules around settlement, grievance management, compliance.
- **IGM (Issue & Grievance Management)** — APIs for raising and resolving issues (`issue`, `on_issue`, `issue_status`, `on_issue_status`).
- **RSF (Reconciliation & Settlement Framework)** — APIs for financial reconciliation between NPs (`recon`, `on_recon`, `settle`, `on_settle`).
- **Network Observability (NO)** — A framework for pushing transaction logs to ONDC for monitoring network health.
- **Registry infrastructure** — ONDC-specific onboarding, environment management, and key exchange.

---

## 4. How Communication Works

### 4.1 Server-to-Server, Always

All communication on the ONDC network is **server-to-server**. The client application (mobile app, web frontend) is never directly involved in protocol-level communication. This means:

- Your BAP's **backend server** talks to the BPP's **backend server**.
- The client-facing UI is entirely decoupled from the protocol layer.
- You're free to render data in any form your product requires.

### 4.2 Asynchronous by Design

**Every transaction API call is asynchronous.** This is a fundamental design decision, not an implementation detail.

When a BAP calls `init` on a BPP, it does **not** wait for the full response in the same HTTP session. Instead:

1. The BPP validates the request and immediately returns a synchronous **ACK** (acknowledgment).
2. The HTTP session closes.
3. After processing (which could take milliseconds or hours), the BPP calls the BAP back on the corresponding **callback API** (`on_init`).

This mirrors real-world commerce — a booking request doesn't guarantee instant confirmation. The async pattern handles this naturally.

### 4.3 The Request ↔ Callback Pattern

Every action API has a paired callback API. The callback is always named with an `on_` prefix:

```
BAP Server                                    BPP Server
    │                                              │
    │──── search ─────────────────────────────────>│
    │<─── ACK (sync response) ────────────────────│
    │                                              │
    │       ... BPP processes the request ...      │
    │                                              │
    │<─── on_search (callback with results) ──────│
    │──── ACK (sync response) ────────────────────>│
    │                                              │
```

The callback is itself an HTTP request from the BPP to the BAP, and the BAP must respond with its own ACK/NACK.

### 4.4 ACK / NACK — The Synchronous Handshake

The synchronous response to every API call is a simple acknowledgment:

**ACK** — "I received your request and it passed basic validation. I'll process it and call you back."

```json
{
    "message": {
        "ack": {
            "status": "ACK"
        }
    }
}
```

**NACK** — "Your request has a problem. Here's the error."

```json
{
    "message": {
        "ack": {
            "status": "NACK"
        }
    },
    "error": {
        "type": "DOMAIN-ERROR",
        "code": "30009",
        "message": "Item not available"
    }
}
```

A NACK means the request will **not** be processed further — there will be no callback.

---

## 5. The Transaction Lifecycle

Every commerce transaction on ONDC follows four stages, each mapped to specific APIs:

### 5.1 Discovery

The buyer searches for products/services. This is the only stage where the **Gateway** may be involved (if the BAP doesn't know which BPPs to target).

```
BAP ──search──> Gateway ──search──> BPP₁, BPP₂, BPP₃ ...
BAP <──on_search── BPP₁
BAP <──on_search── BPP₂
BAP <──on_search── BPP₃
```

The BAP may receive multiple `on_search` callbacks from different BPPs.

### 5.2 Order

Once the buyer has discovered a catalog, they construct an order step by step. This stage is **direct BAP ↔ BPP** — no Gateway involved.

- `select` → `on_select` — Buyer selects items; seller returns a quotation with prices and availability.
- `init` → `on_init` — Buyer provides billing/shipping details; seller initializes the order with payment terms.
- `confirm` → `on_confirm` — Buyer confirms and pays; seller confirms the order.

### 5.3 Fulfillment

The order is being delivered/fulfilled.

- `status` → `on_status` — Check current order status.
- `track` → `on_track` — Get real-time tracking information.
- `update` → `on_update` — Modify the order (e.g., reschedule delivery).
- `cancel` → `on_cancel` — Cancel the order.

### 5.4 Post-Fulfillment

After delivery, the lifecycle may continue with:

- `rating` → `on_rating` — Rate the provider/order.
- `support` → `on_support` — Contact support channels.
- IGM flows (`issue` → `on_issue` → `issue_status` → `on_issue_status`) — For grievance management.

### 5.5 Complete API Map

| Stage                | Action (BAP → BPP) | Callback (BPP → BAP) | Purpose                                           |
| -------------------- | ------------------ | -------------------- | ------------------------------------------------- |
| **Discovery**        | `search`           | `on_search`          | Find products/services                            |
| **Order**            | `select`           | `on_select`          | Get a quotation for selected items                |
|                      | `init`             | `on_init`            | Initialize the order with billing/payment details |
|                      | `confirm`          | `on_confirm`         | Confirm and place the order                       |
| **Fulfillment**      | `status`           | `on_status`          | Check order status                                |
|                      | `track`            | `on_track`           | Get real-time tracking                            |
|                      | `update`           | `on_update`          | Modify an active order                            |
|                      | `cancel`           | `on_cancel`          | Cancel an order                                   |
| **Post-Fulfillment** | `rating`           | `on_rating`          | Submit a rating                                   |
|                      | `support`          | `on_support`         | Request support info                              |
| **IGM**              | `issue`            | `on_issue`           | Raise a grievance                                 |
|                      | `issue_status`     | `on_issue_status`    | Check grievance status                            |
| **RSF**              | `recon`            | `on_recon`           | Financial reconciliation                          |
|                      | `settle`           | `on_settle`          | Settlement                                        |
|                      | `report`           | `on_report`          | Reporting                                         |

---

## 6. The Context Object

Every API request and callback carries a `context` object — the metadata envelope that tells the network _who_, _what_, _where_, and _when_:

```json
{
    "context": {
        "domain": "ONDC:RET10",
        "action": "init",
        "version": "2.0.0",
        "bap_id": "buyer-app.com",
        "bap_uri": "https://buyer-app.com/ondc",
        "bpp_id": "seller-app.com",
        "bpp_uri": "https://seller-app.com/ondc",
        "transaction_id": "txn-uuid-here",
        "message_id": "msg-uuid-here",
        "timestamp": "2024-01-15T10:00:00.000Z",
        "location": {
            "country": { "code": "IND" },
            "city": { "code": "std:080" }
        },
        "ttl": "PT30S"
    }
}
```

Key fields:

- **`domain`** — Which vertical this transaction belongs to.
- **`action`** — The API being called (e.g., `search`, `on_init`).
- **`bap_id` / `bpp_id`** — Subscriber IDs of the buyer and seller apps.
- **`bap_uri` / `bpp_uri`** — The callback URLs where responses should be sent.
- **`transaction_id`** — A unique ID that ties together all API calls within a single end-to-end transaction. Remains constant from `search` through `on_confirm` and beyond.
- **`message_id`** — A unique ID for each individual API call within a transaction.
- **`ttl`** — Time-to-live (ISO 8601 duration) specifying how long the sender will wait before timing out.

---

## 7. Security & Trust

All communication on the ONDC network is cryptographically signed. This ensures **authenticity** (the message came from who it claims), **integrity** (the message wasn't tampered with), and **non-repudiation** (the sender can't deny having sent it).

### 7.1 Digital Signing (Ed25519)

Every NP generates an **Ed25519 signing key pair** during onboarding:

- **Signing Private Key** — Kept secret by the NP. Used to sign outgoing requests.
- **Signing Public Key** — Registered in the ONDC Registry. Used by other NPs to verify incoming requests.

### 7.2 The Authorization Header

Every outgoing API request includes an `Authorization` header with the following structure:

```
Signature keyId="<subscriber_id>|<unique_key_id>|ed25519",
          algorithm="ed25519",
          created="<unix_timestamp>",
          expires="<unix_timestamp>",
          headers="(created)(expires)digest",
          signature="<base64_encoded_signature>"
```

The signature is computed over a signing string that includes:

1. The `created` timestamp.
2. The `expires` timestamp.
3. A **BLAKE-512 digest** of the request body.

### 7.3 Verification Flow

When an NP receives a request:

1. Extract the `keyId` from the `Authorization` header.
2. Parse it into `subscriber_id`, `unique_key_id`, and `algorithm`.
3. Look up the sender's **public key** from the Registry using the `subscriber_id` and `unique_key_id` (via the `/lookup` or `/vlookup` API, or from a cached copy).
4. Verify the Ed25519 signature against the signing string.
5. If verification fails → return a NACK with an unauthorized error.

### 7.4 Encryption (X25519)

In addition to signing, NPs also generate an **X25519 encryption key pair** used during the onboarding challenge-response process. The encryption public key is registered in ASN.1 DER format (base64-encoded) in the Registry.

This is primarily used during the `/subscribe` → `/on_subscribe` handshake with the Registry, where a challenge string must be decrypted using a shared key derived from the NP's private key and ONDC's public key.

---

## 8. Registry & Onboarding

### 8.1 What is the Registry?

The Registry is the **central trust infrastructure** of the ONDC network. It stores:

- Subscriber IDs and their associated metadata.
- Public keys (signing and encryption) for all registered NPs.
- Supported domains and callback URLs.
- NP type (BAP, BPP, BG, etc.).

It does **not** participate in transactions — it only provides lookup and verification services.

### 8.2 Environments

ONDC operates three environments:

| Environment        | Registry URL                | Purpose                            |
| ------------------ | --------------------------- | ---------------------------------- |
| **Staging**        | `staging.registry.ondc.org` | Initial development and testing    |
| **Pre-Production** | `preprod.registry.ondc.org` | Integration testing with other NPs |
| **Production**     | `prod.registry.ondc.org`    | Live transactions with real users  |

Each environment has its own set of keys, endpoints, and policies. Tokens and credentials are **not** interchangeable across environments.

### 8.3 Onboarding Flow (Simplified)

```
┌─────────────┐                              ┌──────────────┐
│  Your NP    │                              │  ONDC        │
│  Server     │                              │  Registry    │
└──────┬──────┘                              └──────┬───────┘
       │                                            │
       │  1. Generate Ed25519 + X25519 key pairs    │
       │                                            │
       │  2. Register on NP Portal, get whitelisted │
       │                                            │
       │  3. Host ondc-site-verification.html       │
       │     at https://<subscriber_id>/             │
       │                                            │
       │  4. POST /subscribe ──────────────────────>│
       │                                            │
       │<──────── POST /on_subscribe ───────────────│
       │     (encrypted challenge string)           │
       │                                            │
       │  5. Decrypt challenge using shared key     │
       │     Return plaintext as sync response ────>│
       │                                            │
       │<──────── 200 OK (registration confirmed) ──│
       │                                            │
```

### 8.4 Registry Lookup

Once registered, any NP can look up another NP's details:

```bash
curl -X POST https://prod.registry.ondc.org/lookup \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_id": "seller-app.com",
    "domain": "ONDC:RET10",
    "type": "BPP"
  }'
```

The response includes the NP's public keys, callback URLs, and registration status.

---

## 9. Network Observability (NO)

Network Observability is ONDC's framework for monitoring the health of the network. All Network Participants are **required** to push transaction logs to the NO API.

Key points:

- **What to push:** All API payloads from `on_search` onwards — both requests and synchronous responses (ACK/NACK), including IGM and RSF flows.
- **When to push:** Same-day, ideally in real-time. There's a buffer until 2:00 AM of T+1 day.
- **How to push:** POST to `https://analytics-api.aws.ondc.org/v1/api/push-txn-logs` with a bearer token obtained from the NP Portal.
- **PII Anonymisation:** Personally Identifiable Information must be anonymised. City and pincode must **not** be anonymised.
- **Automation required:** Log submission must be automated — manual Postman submissions are not acceptable.

The NO payload wraps the original transaction data in a simple envelope:

```json
{
  "type": "<action_name>",
  "data": {
    "context": { ... },
    "message": { ... }
  }
}
```

For synchronous responses, `_response` is appended to the type (e.g., `init_response`).

---

## 10. Putting It All Together — A Complete Transaction

Here's a simplified end-to-end flow of a buyer ordering food through ONDC:

```
 Buyer App (BAP)              Gateway (BG)              Seller App (BPP)
      │                           │                           │
      │ ── search ──────────────> │ ── search ──────────────> │
      │                           │ <── ACK ──────────────── │
      │ <── on_search ──────────────────────────────────────  │
      │                           │                           │
      │ ── select ────────────────────────────────────────>   │
      │ <── ACK ──────────────────────────────────────────    │
      │ <── on_select ────────────────────────────────────    │
      │                                                       │
      │ ── init ──────────────────────────────────────────>   │
      │ <── ACK ──────────────────────────────────────────    │
      │ <── on_init ──────────────────────────────────────    │
      │                                                       │
      │ ── confirm ───────────────────────────────────────>   │
      │ <── ACK ──────────────────────────────────────────    │
      │ <── on_confirm ───────────────────────────────────    │
      │                                                       │
      │ ── status ────────────────────────────────────────>   │
      │ <── on_status (Order picked up) ──────────────────    │
      │ <── on_status (Out for delivery) ─────────────────    │
      │ <── on_status (Delivered) ────────────────────────    │
      │                                                       │

 Throughout this flow, BOTH the BAP and BPP push every
 request + response (including ACKs/NACKs) to the NO API.
```

Note that the Gateway is only involved in the `search` step. Everything from `select` onward is direct BAP ↔ BPP communication.

---

## 11. Developer Resources

| Resource                    | URL                                                                                                                                                           |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **ONDC GitHub (Official)**  | [github.com/ONDC-Official](https://github.com/ONDC-Official)                                                                                                  |
| **Protocol Specs**          | [github.com/ONDC-Official/automation-specifications](https://github.com/ONDC-Official/automation-specifications)                                              |
| **Network Extension Layer** | [github.com/ONDC-Official/protocol-network-extension](https://github.com/ONDC-Official/protocol-network-extension)                                            |
| **Signing & Verification**  | [developer-docs/registry/signing-verification.md](https://github.com/ONDC-Official/developer-docs/blob/main/registry/signing-verification.md)                 |
| **Onboarding Guide**        | [developer-docs/registry/Onboarding of Participants.md](https://github.com/ONDC-Official/developer-docs/blob/main/registry/Onboarding%20of%20Participants.md) |
| **Tech Resources Portal**   | [resources.ondc.org/tech-resources](https://resources.ondc.org/tech-resources)                                                                                |
| **NP Portal**               | [portal.ondc.org](https://portal.ondc.org)                                                                                                                    |

---

## 12. Glossary

| Term               | Definition                                                                      |
| ------------------ | ------------------------------------------------------------------------------- |
| **BAP**            | Beckn Application Platform — the buyer-side application                         |
| **BPP**            | Beckn Provider Platform — the seller-side application                           |
| **BG**             | Beckn Gateway — multicasts search requests during discovery                     |
| **NP**             | Network Participant — any entity registered on the ONDC network                 |
| **Registry**       | Central lookup service storing NP metadata and public keys                      |
| **Context**        | Metadata envelope carried by every API request/callback                         |
| **Transaction ID** | Unique identifier that binds all API calls within a single transaction          |
| **Message ID**     | Unique identifier for an individual API call                                    |
| **ACK**            | Positive acknowledgment — request accepted for processing                       |
| **NACK**           | Negative acknowledgment — request rejected with error details                   |
| **IGM**            | Issue & Grievance Management — APIs for dispute resolution                      |
| **RSF**            | Reconciliation & Settlement Framework — APIs for financial reconciliation       |
| **NO**             | Network Observability — transaction log monitoring framework                    |
| **Ed25519**        | Elliptic curve signing algorithm used for request authentication                |
| **X25519**         | Elliptic curve Diffie-Hellman algorithm used for key exchange during onboarding |
| **Subscriber ID**  | The FQDN-based unique identifier for a Network Participant                      |
| **Beckn**          | The open-source decentralized commerce protocol that ONDC is built on           |

---
