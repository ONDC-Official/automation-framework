# The Protocol

**[Beckn](https://www.youtube.com/watch?v=gefmygtzZR8&t=1s)** is an open protocol that allows local businesses across any industry to be discovered and engaged by any beckn-enabled application. **Beckn protocol** is a collection of open specifications consisting of protocol APIs, message formats, network design and reference architectures to allow any two entities to execute commercial transactions without being on the same platform.

**ONDC** has provided the network extension layer over the Beckn Protocol (base layer). Over the base layer, the network extension layer comprises **model specifications** customised to the ONDC context that have been adopted in order to facilitate transactions over the network. For a detailed understanding of the ONDC network architecture, please refer to our [Video](https://drive.google.com/file/d/1WuHCc59C45LClpbiIPomPMuTeClRZw7h/view).

### Protocol Architecture

#### The Two-Layer Model

ONDC's protocol is structured as two distinct layers:

```mermaid
block-beta
    columns 1
    block:ext
        columns 3
        extTitle["<b>ONDC Network Extension Layer</b>: rules and services for the ONDC network"]:3
        e1["Domain API contracts"] e2["Network policies"] e3["IGM"]
        e4["RSF"] e5["Network Observability"] e6["Registry"]
    end
    space
    block:beckn
        columns 3
        bTitle["<b>Beckn Protocol</b>: the open base layer"]:3
        b1["Core APIs"] b2["Core schema"] b3["Communication protocol"]
        b4["Authentication"] b5["Domain taxonomy"] space
    end
    ext -- "builds on" --> beckn
    style ext fill:#0081cc14,stroke:#0081cc,stroke-width:1.5px
    style beckn fill:#64748b14,stroke:#64748b,stroke-width:1.5px
    style extTitle fill:none,stroke:none
    style bTitle fill:none,stroke:none
```

#### Beckn Protocol — The Base Layer

[Beckn](https://becknprotocol.io/) is an open-source, domain-agnostic protocol for decentralized commerce. It defines:

- **Core APIs** — Transaction APIs modeled after the order lifecycle (`search`, `select`, `init`, `confirm`, `status`, `track`, `update`, `cancel`) and their corresponding callbacks (`on_search`, `on_select`, etc.). There are also Supporting APIs for non-transactional operations like `rating` and `support`.
- **Core Schema** — The data model for commerce interactions, specified using OpenAPI 3.x. Defines objects like `Order`, `Item`, `Provider`, `Fulfillment`, `Payment`, `Billing`, etc.
- **Communication Protocol** — The rules governing how APIs are called (async, server-to-server, ACK-based).
- **Authentication** — How participants digitally sign and verify messages.
- **Domain Taxonomy** — A mechanism for adding industry-specific attributes to the core schema.

Beckn is **transport-layer-agnostic**. While HTTP is the most common implementation, the protocol itself doesn't mandate it.

#### ONDC Network Extension — The Upper Layer

ONDC builds on top of Beckn by adding:

- **Domain-specific API contracts** — Customized schemas and flows for retail, logistics, mobility, financial services, etc.
- **Network policies** — Rules around settlement, grievance management, compliance.
- **IGM (Issue & Grievance Management)** — APIs for raising and resolving issues (`issue`, `on_issue`, `issue_status`, `on_issue_status`).
- **RSF (Reconciliation & Settlement Framework)** — APIs for financial reconciliation between NPs (`recon`, `on_recon`, `settle`, `on_settle`).
- **Network Observability (NO)** — A framework for pushing transaction logs to ONDC for monitoring network health.
- **Registry infrastructure** — ONDC-specific onboarding, environment management, and key exchange.

See [API Reference](/developer-guide/docs/api-reference) for every API endpoint and its payload.

### How a Transaction Works

#### The Ground Rules

Every transaction on ONDC follows the same rules, whatever the domain:

- **Server-to-server:** the buyer app's backend (BAP) talks to the seller app's backend (BPP). The user's phone or browser never calls the network directly.
- **Asynchronous:** every request gets an immediate HTTP response, `ACK` (accepted) or `NACK` (rejected). The actual result comes later, as a separate request back to the sender, called a **callback**. Its name is the request's name with an `on_` prefix: `select` is answered by `on_select`.
- **Signed:** every request and callback carries an `Authorization` header signed by the sender. The receiver checks it against the sender's public key in the Registry before doing anything else.
- **Tracked:** every call carries a `context` with the same `transaction_id` for the whole transaction, and a `message_id` that links each request to its callback.
- **Logged:** both apps push every request and response to ONDC's [Network Observability](/developer-guide/docs/network-observability) service.

#### The Transaction at a Glance

Every transaction moves through the same stages. Each box is a request and its callback.

```mermaid
flowchart LR
    subgraph D["<b>1 · Discovery</b>"]
        direction TB
        d1["search → on_search<br/><small>through the Gateway;<br/>catalogs from many sellers</small>"]
    end
    subgraph O["<b>2 · Order</b>"]
        direction TB
        o1["select → on_select<br/><small>quote</small>"] --> o2["init → on_init<br/><small>final quote and terms</small>"] --> o3["confirm → on_confirm<br/><small>order created</small>"]
    end
    subgraph F["<b>3 · Fulfillment</b>"]
        direction TB
        f1["status → on_status<br/><small>also sent unsolicited</small>"] ~~~ f2["track → on_track"]
    end
    subgraph P["<b>4 · After the order</b>"]
        direction TB
        p1["update → on_update<br/>cancel → on_cancel"] ~~~ p2["rating → on_rating<br/>support → on_support"] ~~~ p3["issue → on_issue <small>(IGM)</small><br/>recon → on_recon <small>(RSF)</small>"]
    end
    D -- "then direct,<br/>BAP ⇄ BPP" --> O --> F --> P
    style D fill:#f59e0b14,stroke:#f59e0b,stroke-width:1.5px
    style O fill:#0081cc14,stroke:#0081cc,stroke-width:1.5px
    style F fill:#0081cc14,stroke:#0081cc,stroke-width:1.5px
    style P fill:#0081cc14,stroke:#0081cc,stroke-width:1.5px
```

#### One Order, Start to Finish

The walk-through below follows one Grocery order (`ONDC:RET10`), from search to delivery. Other domains use the same pattern, with their own steps and states; the use case's **API Walkthrough** under Explore by Domain shows the exact flow for each.

**Step 0 — Before the first call.** Both apps are registered in the ONDC Registry, with a subscriber ID, a subscriber URL and public keys. To call or verify another app, each one looks up the other's URL and public key in the Registry (and caches it).

**Step 1 — Search (BAP → Gateway → BPPs).** The user searches for "atta" in Bengaluru. The BAP creates a new `transaction_id` and a `message_id`, and sends `search` to the **Gateway** with `context.city: "std:080"` and the item, category or location in `message.intent`. The Gateway answers `ACK`, adds its own `X-Gateway-Authorization` signature, and forwards the `search` to every seller app registered for that domain and city. Each seller app checks both signatures and answers the Gateway with `ACK`.

**Step 2 — Catalogs (BPPs → BAP).** Each seller app with matching items sends `on_search` **directly to the BAP's** `bap_uri`, not through the Gateway. It carries the same `transaction_id` and `message_id`, its own `bpp_id` and `bpp_uri`, and its catalog in `message.catalog`. The BAP answers each one with `ACK` and shows the merged results to the user. From now on the BAP knows which seller app to talk to, and every call goes **directly** between the two apps.

**Step 3 — Select (BAP → BPP).** The user adds items to the cart. The BAP sends `select` to the chosen seller app's `bpp_uri`, with a **new** `message_id`, the provider, items and quantities, and the delivery location. The seller app answers `ACK`, then sends `on_select` with the same `message_id`: a **quote** with the price breakup (items, delivery, packing, taxes) and the delivery options available.

**Step 4 — Init (BAP → BPP).** The user checks out. The BAP sends `init` with the billing details, the delivery address and contact, and the payment method. The seller app answers with `on_init`: the final quote, the payment terms (who collects the payment, settlement details), and the cancellation terms.

**Step 5 — Payment.** For a prepaid order collected by the buyer app, the user now pays inside the BAP. For cash on delivery, nothing is paid yet.

**Step 6 — Confirm (BAP → BPP).** The BAP sends `confirm` with the order ID, the full order, and the payment status and transaction reference. The seller app answers with `on_confirm`: the order in state **`Created`**, with its fulfillment in state **`Pending`**. The order now exists on both sides.

**Step 7 — Fulfillment updates (BPP → BAP, unsolicited).** As the order moves, the seller app sends `on_status` **without being asked**, each time with a new `message_id` and the same `transaction_id`. First the seller accepts the order (order **`Accepted`**). Then the fulfillment moves through **`Packed`**, **`Agent-assigned`**, **`Order-picked-up`** and **`Out-for-delivery`** while the order is **`In-progress`**, and finally **`Order-delivered`**, when the order becomes **`Completed`**. See [Order and Fulfillment States](#order-and-fulfillment-states). At any time the BAP can also ask with `status` → `on_status`, or get live tracking with `track` → `on_track`.

**Step 8 — Changes after the order.** If the order changes, the same pattern applies:

- The buyer cancels: `cancel` → `on_cancel`, with a reason code; the seller app returns the cancelled order and any refund.
- The seller app cancels, for example when an item is out of stock: it sends `on_cancel` unsolicited.
- A return, a partial cancellation or a change of address: `update` → `on_update`, and the seller app may later send unsolicited `on_update` calls as the change progresses.

**Step 9 — After delivery.** The user can rate the order (`rating` → `on_rating`) or ask for support (`support` → `on_support`). If something went wrong, the BAP raises an issue (`issue` → `on_issue`) and follows it until it is resolved and closed; see Issue and Grievance Management in the [API Reference](/developer-guide/docs/api-reference).

**Step 10 — Settlement.** The app that collected the payment settles with the other according to the terms agreed in `on_init`. Where the Reconciliation and Settlement Framework applies, the apps reconcile with `recon` → `on_recon`.

#### The Whole Flow

The diagram shows every call from `search` to the last `on_status` of one order, with the synchronous `ACK` for each. Solid arrows are requests and callbacks; dashed arrows are the `ACK` responses.

```mermaid
sequenceDiagram
    autonumber
    participant BAP as Buyer App (BAP)
    participant GW as Gateway
    participant BPP as Seller App (BPP)

    rect rgba(59, 130, 246, 0.08)
    Note over BAP,BPP: Discovery (new transaction_id)
    BAP->>GW: search (intent, context.city)
    GW-->>BAP: ACK
    GW->>BPP: search (adds X-Gateway-Authorization)
    BPP-->>GW: ACK
    BPP->>BAP: on_search (catalog), sent directly to bap_uri
    BAP-->>BPP: ACK
    end

    rect rgba(16, 185, 129, 0.08)
    Note over BAP,BPP: Order (direct between BAP and BPP)
    BAP->>BPP: select (items, quantity, delivery location)
    BPP-->>BAP: ACK
    BPP->>BAP: on_select (quote and delivery options)
    BAP-->>BPP: ACK
    BAP->>BPP: init (billing, delivery address, payment method)
    BPP-->>BAP: ACK
    BPP->>BAP: on_init (final quote, payment and cancellation terms)
    BAP-->>BPP: ACK
    Note over BAP: User pays (prepaid order)
    BAP->>BPP: confirm (order ID, order, payment status)
    BPP-->>BAP: ACK
    BPP->>BAP: on_confirm (order Created, fulfillment Pending)
    BAP-->>BPP: ACK
    end

    rect rgba(245, 158, 11, 0.08)
    Note over BAP,BPP: Fulfillment (unsolicited on_status, each with a new message_id)
    BPP->>BAP: on_status (order Accepted), unsolicited
    BAP-->>BPP: ACK
    BPP->>BAP: on_status (Packed, order In-progress), unsolicited
    BAP-->>BPP: ACK
    BPP->>BAP: on_status (Agent-assigned), unsolicited
    BAP-->>BPP: ACK
    BAP->>BPP: status (order_id)
    BPP-->>BAP: ACK
    BPP->>BAP: on_status (Order-picked-up)
    BAP-->>BPP: ACK
    BPP->>BAP: on_status (Out-for-delivery), unsolicited
    BAP-->>BPP: ACK
    BPP->>BAP: on_status (Order-delivered, order Completed), unsolicited
    BAP-->>BPP: ACK
    end
```

- Every request and callback is signed with an `Authorization` header and carries the same `transaction_id`.
- A request and its callback share a `message_id` (for example `select` and `on_select`, or `status` and the `on_status` that answers it). Each unsolicited `on_status` has a new one.
- The Gateway takes part only in `search`. Every call after `on_search` goes directly between the two apps.
- The other post-order calls (`track`, `update`, `cancel`, `rating`, `support`, `issue`) follow the same request, `ACK`, callback pattern.

#### Order and Fulfillment States

An order has two states that move together: the **order** state (`order.state`) and the state of each **fulfillment** (`fulfillments[].state.descriptor.code`). The diagrams show them for a delivery order in Retail (`ONDC:RET10` 1.2.5); other domains use their own values, listed in each use case's API Walkthrough.

**Order state:**

```mermaid
stateDiagram-v2
    direction LR
    state "Created" as Created
    state "Accepted" as Accepted
    state "In-progress" as InProgress
    state "Completed" as Completed
    state "Cancelled" as Cancelled
    [*] --> Created: on_confirm
    Created --> Accepted: on_status
    Accepted --> InProgress: on_status (Packed)
    InProgress --> Completed: on_status (Order-delivered)
    Created --> Cancelled: on_cancel
    Accepted --> Cancelled: on_cancel
    InProgress --> Cancelled: on_cancel
    classDef done fill:#22c55e1f,stroke:#22c55e,stroke-width:1.5px
    classDef stop fill:#ef44441f,stroke:#ef4444,stroke-width:1.5px
    class Completed done
    class Cancelled stop
```

**Fulfillment state** (delivery):

```mermaid
stateDiagram-v2
    direction LR
    state "Pending" as P
    state "Packed" as PK
    state "Agent-assigned" as AA
    state "Order-picked-up" as PU
    state "Out-for-delivery" as OD
    state "Order-delivered" as D
    state "Cancelled" as X
    state "RTO-Initiated" as RI
    state "RTO-Delivered" as RD
    state "RTO-Disposed" as RX
    [*] --> P: on_confirm
    P --> PK
    PK --> AA
    AA --> PU
    PU --> OD
    OD --> D
    P --> X: cancelled before pickup
    PK --> X
    OD --> RI: cancelled after pickup
    RI --> RD: returned to the seller
    RI --> RX: disposed of
    classDef done fill:#22c55e1f,stroke:#22c55e,stroke-width:1.5px
    classDef stop fill:#ef44441f,stroke:#ef4444,stroke-width:1.5px
    classDef rto fill:#f59e0b1a,stroke:#f59e0b,stroke-width:1.5px
    class D done
    class X stop
    class RI,RD,RX rto
```

| Stage | Sent in | Order state | Fulfillment state |
| --- | --- | --- | --- |
| Order placed | `on_confirm` | `Created` | `Pending` |
| Seller accepts the order | `on_status` | `Accepted` | `Pending` |
| Packed, agent assigned, picked up, on the way | `on_status` | `In-progress` | `Packed` → `Agent-assigned` → `Order-picked-up` → `Out-for-delivery` |
| Delivered | `on_status` | `Completed` | `Order-delivered` |
| Cancelled | `on_cancel`, then `on_status` | `Cancelled` | `Cancelled`; after pickup, `RTO-Initiated` → `RTO-Delivered` or `RTO-Disposed` (return to origin) |

#### Identifiers Through the Transaction

```mermaid
flowchart LR
    subgraph T["<b>transaction_id T1</b>: the same in every call of the order"]
        direction LR
        M1["<b>message_id m1</b><br/>search<br/>on_search × many"] --> M2["<b>m2</b><br/>select<br/>on_select"] --> M3["<b>m3</b><br/>init<br/>on_init"] --> M4["<b>m4</b><br/>confirm<br/>on_confirm<br/><small>order.id set</small>"] --> M5["<b>m5</b><br/>on_status<br/><small>unsolicited</small>"] --> M6["<b>m6</b><br/>status<br/>on_status"]
    end
    style T fill:#0081cc0f,stroke:#0081cc,stroke-width:1.5px
    classDef unsol fill:#f59e0b1a,stroke:#f59e0b,stroke-width:1.5px
    class M5 unsol
```

A request and its callback share one `message_id`; an unsolicited callback gets its own. `bpp_id` and `bpp_uri` are known from `on_search` onwards.

| Identifier | Created by | Stays the same |
| --- | --- | --- |
| `transaction_id` | BAP, on `search` | In every call of the transaction, from `search` to the last post-order call. |
| `message_id` | The sender of each request | Between a request and its callback (`select` and `on_select`). Each unsolicited `on_status`, `on_update` or `on_cancel` has a new one. |
| `bpp_id`, `bpp_uri` | BPP, in `on_search` | In every call with that seller app after `on_search`. |
| Order ID | Set in `confirm` | In every post-order call, as `order.id` or `order_id`. |

#### When Something Goes Wrong

| Situation | What Happens |
| --- | --- |
| The request is invalid (bad signature, wrong `context`, schema error) | The receiver answers `NACK` with an `error`. There is **no** callback; the sender must fix the request and send it again with a new `message_id`. |
| The request is valid, but cannot be fulfilled (for example, an item is out of stock) | The receiver answers `ACK`, then sends the callback with an `error` (for example `on_select` with a domain error code). |
| No callback arrives within the request's `ttl` | The sender treats the request as timed out. |

```mermaid
flowchart LR
    S["Request arrives"] --> V{"Signature, context<br/>and schema valid?"}
    V -- "no" --> N(["<b>NACK</b> with error<br/><small>no callback: fix the request and<br/>resend it with a new message_id</small>"]):::bad
    V -- "yes" --> A(["<b>ACK</b>"]):::ok
    A --> B{"Can it be<br/>fulfilled?"}
    B -- "yes" --> CB["<b>Callback with the result</b><br/><small>on_select, on_init, ...</small>"]:::ok
    B -- "no" --> CE["<b>Callback with an error</b><br/><small>for example on_select with<br/>a domain error code</small>"]:::warn
    A -. "no callback within ttl" .-> T["<b>Timed out</b><br/><small>on the sender's side</small>"]:::warn
    classDef ok fill:#22c55e1f,stroke:#22c55e,stroke-width:1.5px
    classDef bad fill:#ef44441f,stroke:#ef4444,stroke-width:1.5px
    classDef warn fill:#f59e0b1a,stroke:#f59e0b,stroke-width:1.5px
```

See [Core Error Codes](/developer-guide/docs/error-codes) for the error codes.

### Start your ONDC journey

Sign up or sign in on the [ONDC Portal](https://portal.ondc.org) to register as a Network Participant and begin your ONDC journey.

### Subscription Process

To enroll in the ONDC network, Network Participants (NP) must be added to the registry. The steps for an NP to onboard onto the ONDC Registry (Pre-Production, Production) are outlined as follows:

#### 1. Pre-Production Registry
- Obtain whitelisting for the subscriber ID.
- NP Portal invokes Admin APIs
- Keys are not validated upfront
- Direct subscription allowed
- DNS TXT record NOT required

#### 2. Production Registry
Participants will have to:
1. Generate DNS TXT record
2. Host DNS record
3. Portal will call admin subscription API

> **Note:** Steps involving DNS TXT record apply only to the Production environment. Pre-Production supports direct subscription without DNS validation.

```mermaid
flowchart TD
    A["<b>1 · Generate key pairs</b><br/><small>Ed25519 for signing, X25519 for encryption</small>"] --> B["<b>2 · Sign up on the ONDC Portal</b><br/><small>subscriber details and public keys</small>"]
    B --> C{"Which registry?"}
    C -- "Pre-Production" --> P1
    C -- "Production" --> Q1
    subgraph PRE["<b>Pre-Production</b>"]
        P1["Subscriber ID whitelisted"] --> P2["Portal calls the admin APIs<br/><small>direct subscription, no DNS TXT record</small>"]
    end
    subgraph PROD["<b>Production</b>"]
        Q1["Generate a DNS TXT record"] --> Q2["Host it on your domain"] --> Q3["Portal calls the admin<br/>subscription API"]
    end
    P2 --> D[("<b>Listed in the Registry</b><br/><small>other apps can look you up</small>")]:::reg
    Q3 --> D
    style PRE fill:#0081cc0f,stroke:#0081cc,stroke-width:1.5px
    style PROD fill:#22c55e0f,stroke:#22c55e,stroke-width:1.5px
    classDef reg fill:#8b5cf61a,stroke:#8b5cf6,stroke-width:1.5px
```

### Signing and Verification

When communicating over HTTP using Beckn APIs, the subscribers need to authenticate themselves to perform transactions with other subscribers. Due to the commercial nature of the transactions, every request/callback pair is considered to be a "contract" between two parties. Therefore, it is imperative that all requests and callbacks are digitally signed by the sender and subsequently verified by the receiver.

How every request is signed and checked:

```mermaid
sequenceDiagram
    participant S as Sender (BAP or BPP)
    participant R as Registry
    participant V as Receiver
    S->>S: Hash the body (BLAKE-512) and sign created, expires, digest (Ed25519 private key)
    S->>V: Request + Authorization header (keyId = subscriber_id|unique_key_id|ed25519)
    V->>R: lookup (subscriber_id, unique_key_id), or use cached key
    R-->>V: Sender's signing public key
    V->>V: Rebuild the signing string from the received body and verify the signature
    alt Signature valid and not expired
        V-->>S: ACK
    else Invalid or expired
        V-->>S: NACK (invalid signature)
    end
```

Use the [Signing & Verification](/developer-guide/auth-tools) tab to create and verify headers, with the header format and reference code.

---

## Terminology

| Term | Definition |
| ---- | ---------- |
| **Beckn Protocol** | Open-source, decentralized commerce protocol providing core specifications, message formats, and transaction APIs. |
| **ONDC Network Extension Layer** | Domain-specific API contracts, policies, and network rules configured on top of the Beckn Protocol base layer. |
| **Network Participant (NP)** | Any registered entity (buyer application, seller application, or gateway) on the ONDC network. |
| **Registry** | Central trust repository storing participant metadata, public keys, subscriber IDs, and callback URLs. |
| **Pre-Production Registry** | Testing and staging registry environment allowing direct subscription without DNS ownership validation. |
| **Production Registry** | Live registry environment that requires DNS TXT record verification and portal administration to enroll participants. |
| **Subscriber ID** | Unique FQDN-based identifier assigned to an NP to identify its transactions on the network. |
| **DNS TXT Record** | Domain Name System text record hosted on the participant's domain to verify ownership during production onboarding. |
| **Signing and Verification** | Cryptographic authentication where HTTP requests and callbacks are digitally signed by the sender and validated by the receiver. |
| **Subscriber** | A registered network participant authorized to transact on the ONDC network using verified keys and endpoints. |
