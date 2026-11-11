# The Protocol

**[Beckn](https://www.youtube.com/watch?v=gefmygtzZR8&t=1s)** is an open protocol that allows local businesses across any industry to be discovered and engaged by any beckn-enabled application. **Beckn protocol** is a collection of open specifications consisting of protocol APIs, message formats, network design and reference architectures to allow any two entities to execute commercial transactions without being on the same platform.

**ONDC** has provided the network extension layer over the Beckn Protocol (base layer). Over the base layer, the network extension layer comprises **model specifications** customised to the ONDC context that have been adopted in order to facilitate transactions over the network. For a detailed understanding of the ONDC network architecture, please refer to our [Video](https://drive.google.com/file/d/1WuHCc59C45LClpbiIPomPMuTeClRZw7h/view).

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

### Signing and Verification

When communicating over HTTP using Beckn APIs, the subscribers need to authenticate themselves to perform transactions with other subscribers. Due to the commercial nature of the transactions, every request/callback pair is considered to be a "contract" between two parties. Therefore, it is imperative that all requests and callbacks are digitally signed by the sender and subsequently verified by the receiver.

See [Auth Tools](/developer-guide/auth-tools) for the signing and verification process, the header format and reference code.

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
