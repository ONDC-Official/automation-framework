# Core Error Codes

> The core ONDC error codes that a Gateway, buyer app, seller app or logistics participant returns when a request cannot be processed.

---

## Overview

When a request fails, the receiver returns a **NACK** with an `error` object carrying one of the codes below. See [ACK / NACK](/developer-guide/docs/about-ondc#44-ack--nack--the-synchronous-handshake) in About ONDC for the response format.

```json
{
    "message": { "ack": { "status": "NACK" } },
    "error": {
        "code": "10001",
        "message": "Invalid Signature"
    }
}
```

Codes are grouped by the participant that returns them:

| Returned by | Codes | Range |
| ----------- | ----- | ----- |
| [Gateway](#gateway) | 3 | 10000–10002 |
| [Buyer App (BNP)](#buyer-app-bnp) | 27 | 20000–27502 |
| [Seller App (SNP)](#seller-app-snp) | 51 | 30000–50008 |
| [Logistics Buyer (LBNP)](#logistics-buyer-lbnp) | 17 | 62501–64002 |
| [Logistics Provider (LSP)](#logistics-provider-lsp) | 32 | 60001–66005 |

Some domains (for example Financial Services, Mobility and Network Services) define **additional domain-specific codes**. Those are listed in the **Error Codes** tab of each use case under Explore by Domain.

---

## Gateway

Returned by the ONDC Gateway.

| Code | Message | Description |
| ---- | ------- | ----------- |
| `10000` | Bad or Invalid request error | Generic bad or invalid request error |
| `10001` | Invalid Signature | Cannot verify signature for request |
| `10002` | Invalid City Code | Valid city code needs to be passed for search |

---

## Buyer App (BNP)

Returned by a Buyer Network Participant (buyer app).

| Code | Message | Description |
| ---- | ------- | ----------- |
| `20000` | Invalid catalog | Catalog refresh is invalid |
| `20001` | Invalid Signature | Cannot verify signature for response |
| `20002` | Stale Request | Cannot process stale request |
| `20003` | Provider not found | Provider not found |
| `20004` | Provider location not found | Provider location not found |
| `20005` | Item not found | Item not found |
| `20006` | Invalid response | Invalid response does not meet API contract specifications |
| `20007` | Invalid order state | Order/fulfillment state is stale or not valid |
| `20008` | Response out of sequence | Callback received prior to ACK for request or out of sequence |
| `20009` | Timeout | Callback received late, session timed out |
| `21001` | Feature not supported | Feature not supported |
| `21002` | Increase in item quantity | Increase in item quantity |
| `21003` | Change in item quote | Change in item quote without change in quantity |
| `22501` | Part Fill Unacceptable | Buyer doesn't accept part fill for the order, wants to cancel the order |
| `22502` | Cancellation unacceptable | Invalid cancellation reason |
| `22503` | Cancellation unacceptable | Updated quote does not match original order value and cancellation terms |
| `22504` | Invalid Fulfillment TAT | Fulfillment TAT is different from what was quoted earlier |
| `22505` | Invalid Cancellation Terms | Cancellation terms are different from what was quoted earlier |
| `22506` | Invalid Terms of Reference | Terms of Reference are different from what was quoted earlier |
| `22507` | Invalid Quote | Quote is invalid as it does not meet the API contract specifications |
| `22508` | Invalid Part Cancel Request | Part cancel request is invalid |
| `22509` | Cancel Return Request | Buyer cancelling return request |
| `23001` | Internal Error | Cannot process response due to internal error, please retry |
| `23002` | Order validation failure | Order validation failure |
| `25001` | Order Confirm Failure | Buyer App cannot confirm order as no response from Seller App |
| `27501` | Terms and Conditions unacceptable | Seller App terms and conditions not acceptable to Buyer App |
| `27502` | Order terminated | Order terminated as Seller App did not accept terms and conditions proposed by Buyer App |

---

## Seller App (SNP)

Returned by a Seller Network Participant (seller app).

| Code | Message | Description |
| ---- | ------- | ----------- |
| `30000` | Invalid request | Invalid request does not meet API contract specifications |
| `30001` | Provider not found | When Seller App is unable to find the provider id sent by the Buyer App |
| `30002` | Provider location not found | When Seller App is unable to find the provider location id sent by the Buyer App |
| `30003` | Provider category not found | When Seller App is unable to find the provider category id sent by the Buyer App |
| `30004` | Item not found | Unable to find details for item, may have been deleted |
| `30005` | Invalid return request | Return reason is invalid |
| `30006` | Offer code invalid | Offer code is not valid anymore |
| `30007` | Offer fulfillment error | Offer cannot be fulfilled at this time |
| `30008` | Location Serviceability error | Pickup location not serviceable by Logistics Provider |
| `30009` | Location Serviceability error | Dropoff location not serviceable by Logistics Provider |
| `30010` | Location Serviceability error | Delivery distance exceeds the maximum serviceability distance |
| `30011` | Order Serviceability error | Delivery Partners not available |
| `30012` | Invalid cancellation reason | Cancellation reason is invalid |
| `30013` | Invalid Fulfillment TAT | Fulfillment TAT is different from what was quoted earlier |
| `30014` | Cancellation unacceptable | Cancellation request is rejected as fulfillment TAT is not breached |
| `30015` | Invalid rating value | When the Seller App receives an invalid value as the rating value in value |
| `30016` | Invalid Signature | Cannot verify signature for request |
| `30017` | Merchant unavailable | Merchant is currently not taking orders |
| `30018` | Invalid Order | Order not found |
| `30019` | Order Confirm Error | Seller App is unable to confirm the order |
| `30020` | Order Confirm Failure | Seller App cannot confirm order as no response from Buyer App |
| `30021` | Merchant Inactive | Merchant is inactive |
| `30022` | Stale Request | Cannot process stale request |
| `30023` | Minimum order value error | Cart value is less than minimum order value |
| `31001` | Internal Error | Cannot process request due to internal error, please retry |
| `31002` | Order validation failure | Order validation failure |
| `31003` | Order processing in progress | Order processing in progress |
| `40000` | Business Error | Generic business error |
| `40001` | Feature not supported | Feature not supported |
| `40002` | Item quantity unavailable | When the Seller App is unable to fulfill the required quantity for items in the order |
| `40003` | Quote unavailable | Quote no longer available |
| `40004` | Payment type not supported | Payment type not supported |
| `40005` | Tracking not enabled | Tracking not enabled for any fulfillment in the order |
| `40006` | Fulfilment agent unavailable | When an agent for fulfilment is not available |
| `40007` | Change in item quantity | Change in item quantity |
| `40008` | Change in quote | Change in quote |
| `40009` | Maximum order qty exceeded | Maximum order qty exceeded |
| `40010` | Expired authorization | Authorization code has expired |
| `40011` | Invalid authorization | Authorization code is invalid |
| `40012` | Minimum order qty required | Minimum order qty required |
| `41001` | Finder fee not acceptable | Buyer finder fee is not acceptable |
| `41002` | Differential weight charges rejected | Differential weight charges rejected |
| `50000` | Policy Error | Generic Policy Error |
| `50001` | Cancellation not possible | When the Seller App is unable to cancel the order due to it's cancellation policy |
| `50002` | Updation not possible | When the Seller App is unable to update the order due to it's updation policy |
| `50003` | Unsupported rating category | When the Seller App receives an entity to rate which is not supported |
| `50004` | Support unavailable | When the Seller App receives an object if for which it does not provide support |
| `50005` | Terms and Conditions unacceptable | Buyer App terms and conditions not acceptable to Seller App |
| `50006` | Order terminated | Order terminated as Buyer App did not accept terms proposed by Seller App |
| `50007` | Fulfillment not found | Fulfillment not found |
| `50008` | Fulfillment cannot be updated | Fulfillment has reached terminal state, cannot be updated |

---

## Logistics Buyer (LBNP)

Returned by a Logistics Buyer Network Participant.

| Code | Message | Description |
| ---- | ------- | ----------- |
| `62501` | Terms and Conditions unacceptable | Logistics Provider terms & conditions not acceptable to Logistics Buyer |
| `62502` | Order terminated | Order terminated as Logistics Provider did not accept terms proposed by Logistics Buyer |
| `62503` | RTO rejected | RTO request rejected as quote does not match the quote provided in catalog |
| `62504` | Differential weight charges rejected | Differential weight charges rejected |
| `62505` | Cancellation terms unacceptable | Logistics Provider cancellation terms not acceptable to Logistics Buyer |
| `62506` | Invalid Fulfillment TAT | Fulfillment TAT is different from what was quoted earlier |
| `62507` | Difference in packaging details | Weight and / or dimensions provided is different from what was originally provided |
| `62508` | Quote difference | Total price is different from what was originally provided |
| `62509` | Invalid Cancellation Terms | Cancellation terms are different from what was quoted earlier |
| `62510` | Expired authorization | Authorization code has expired |
| `62511` | Invalid authorization | Authorization code is invalid |
| `62512` | Pickup status rejected | Pickup auth enabled but not yet complete |
| `62513` | Delivery status rejected | Delivery auth enabled but not yet complete |
| `63001` | Internal Error | Cannot process response due to internal error, please retry |
| `63002` | Order validation failure | Order validation failure |
| `64001` | Feature not supported | Feature not supported |
| `64002` | Order validation failure | Order validation failure |

---

## Logistics Provider (LSP)

Returned by a Logistics Service Provider.

| Code | Message | Description |
| ---- | ------- | ----------- |
| `60001` | Location Serviceability Error | Pickup location not serviceable by Logistics Provider |
| `60002` | Location Serviceability Error | Dropoff location not serviceable by Logistics Provider |
| `60003` | Location Serviceability Error | Delivery distance exceeds the maximum serviceability distance |
| `60004` | Order Serviceability Error | Delivery Partners not available |
| `60005` | Invalid Signature | Cannot verify signature for request |
| `60006` | Invalid Request | Invalid request, not compliant with API contract |
| `60007` | Policy Error | Cancellation not possible because of Logistics Provider policy |
| `60008` | Invalid Fulfillment TAT | Fulfillment TAT is different from what was quoted earlier |
| `60009` | Invalid cancellation request | Cancellation reason is invalid |
| `60010` | Cancellation unacceptable | Cancellation request is rejected as fulfillment TAT is not breached |
| `60011` | Difference in packaging details | Weight and / or dimensions provided is different from what was originally provided |
| `60012` | Tracking not enabled | Tracking not enabled for any fulfillment in the order |
| `61001` | Feature not supported | Feature not supported |
| `61002` | PCC OTP Retrigger Request | Logistics Provider requests Logistics Buyer to retrigger Pickup (PCC) OTP |
| `61003` | DCC OTP Retrigger Request | Logistics Provider requests Logistics Buyer to retrigger Delivery (DCC) OTP |
| `61004` | LSP Requests LBNP for Support Callback | Customer not reachable |
| `61005` | LSP Requests LBNP for Support Callback | Unable to update status (Order-picked,Order-delivered) |
| `61006` | LSP Requests LBNP for Support Callback | Item OOS / system issue |
| `61007` | LSP Requests LBNP for Support Callback | Restaurant is closed |
| `61008` | LSP Requests LBNP for Support Callback | Problem finding or accessing restaurant |
| `61009` | LSP Requests LBNP for Support Callback | Others |
| `61010` | LSP Requests LBNP for Customer Contact | Deferred Request for Customer Contact from Logistics Provider to Logistics Buyer |
| `65001` | Order Confirm Error | Logistics Provider is unable to confirm the order |
| `65002` | Order terminated | Order terminated as Logistics Buyer did not accept terms proposed by Logistics Provider |
| `65003` | Stale Request | Cannot process stale request |
| `65004` | Terms unacceptable | Logistics Buyer terms not acceptable to Logistics Provider |
| `65005` | Invalid fulfillment terms | Immediate delivery fulfillment requires RTS at order confirm |
| `66001` | Internal Error | Cannot process request due to internal error, please retry |
| `66002` | Order validation failure | Order validation failure |
| `66003` | Order processing in progress | Order processing in progress |
| `66004` | Invalid Order | Order not found |
| `66005` | Quote unavailable | Quote no longer available |
