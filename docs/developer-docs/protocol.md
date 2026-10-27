# The Protocol

**[Beckn](https://www.youtube.com/watch?v=gefmygtzZR8&t=1s)** is an open protocol that allows local businesses across any industry to be discovered and engaged by any beckn-enabled application. **Beckn protocol** is a collection of open specifications consisting of protocol APIs, message formats, network design and reference architectures to allow any two entities to execute commercial transactions without being on the same platform.

**ONDC** has provided the network extension layer over the Beckn Protocol (base layer). Over the base layer, the network extension layer comprises **model specifications** customised to the ONDC context that have been adopted in order to facilitate transactions over the network. For a detailed understanding of the ONDC network architecture, please refer to our [Video](https://drive.google.com/file/d/1WuHCc59C45LClpbiIPomPMuTeClRZw7h/view).

### Subscription Process

To enroll in the ONDC network, Network Participants (NP) must be added to the registry. The complete process is documented [here](https://github.com/ONDC-Official/developer-docs/blob/main/registry/Onboarding%20of%20Participants.md). The steps for an NP to onboard onto the ONDC Registry (Staging/Pre Production, Production) are outlined as follows:

#### 1. Staging / Pre-Production Registry
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

> **Note:** Steps involving DNS TXT record apply only to the Production environment. Staging/Pre-Prod support direct subscription without DNS validation.

### Signing and Verification

When communicating over HTTP using Beckn APIs, the subscribers need to authenticate themselves to perform transactions with other subscribers. Due to the commercial nature of the transactions, every request/callback pair is considered to be a "contract" between two parties. Therefore, it is imperative that all requests and callbacks are digitally signed by the sender and subsequently verified by the receiver.

The complete process is documented [here](https://github.com/ONDC-Official/developer-docs/blob/main/registry/signing-verification.md).