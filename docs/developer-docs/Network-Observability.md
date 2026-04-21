# [PROD] Network Observability API — Schema & Process

---

## Table of Contents

- [What is Network Observability (NO)?](#what-is-network-observability-no)
- [What is a Bearer Token?](#what-is-a-bearer-token)
- [When and What to Share with NO?](#when-and-what-to-share-with-no)
- [Schema for Pushing Logs on Network Observability API in Prod Environment](#schema-for-pushing-logs-on-network-observability-api-in-prod-environment)
- [Retail, Logistics, Financial Services, Gift Cards & Mobility Examples](#retail-logistics-financial-services-gift-cards--mobility-examples)
- [IGM Examples](#1-igm-examples)
- [RSF Examples](#rsf-examples)
- [Error Payload Examples as per the API Contract](#error-payload-examples-as-per-the-api-contract)
- [Error Payload Examples for 4xx or 5xx Errors Outside the API Contract](#error-payload-examples-for-any-4xx-or-5xx-errors-apart-from-the-api-contract)
- [Schema Validation Error (To Be Released Soon)](#schema-validation-error-to-be-released-soon)
- [FAQs](#faqs)

---

## What is Network Observability (NO)?

Network Observability is a [framework](https://ondc-static-website-media.s3.ap-south-1.amazonaws.com/ondc-website-media/downloads/governance-and-policies/ONDC%20-%20White%20Paper%20-%20Strengthening%20the%20Health%20and%20Growth%20of%20India%E2%80%99s%20E-commerce%20in%20an%20open%20network%20-%20Sept%202023.pdf) designed to observe the business and technical health of the network and uncover actionable insights. Its core objective is to enhance interoperability, transparency, and trust among network/ecosystem participants on the ONDC network by enabling them to develop self-correction capabilities and evolve to scale.

---

## What is a Bearer Token?

A Bearer Token is a type of token used for authorization. In the context of Network Observability, a bearer token serves as an identifier. The bearer token for a Network Participant (NP) is linked to a **subscriber ID** and the **NP type**, and is **domain-agnostic**.

For example:

- If an NP has 2 different subscriber IDs — one as a Buyer NP and one as a Seller NP — there will be **2 tokens** associated with that NP.
- If a Buyer/Seller NP has 3 different subscriber IDs, there will be **3 tokens** associated with that NP.

---

## When and What to Share with NO?

Once a Network Participant is subscribed to the **Production Registry**, the NP can generate the bearer token from the **NP Portal** under **Configuration Settings**. This bearer token is then used to push transaction logs to the NO API.

> **Important:** This bearer token is valid only for the **Production** stage.

### What to Share

The Network Participant must share the transaction JSON from **`on_search` onwards** — that is, both the request and response payloads for every API call: `on_search`, `select`, `on_select`, `init`, `on_init`, and so on. This includes **IGM APIs** from **`issue` onwards** — i.e., `issue`, `on_issue`, `issue_status`, and `on_issue_status` — along with **ACKs and NACKs** for each request and response.

> **This must be an automated process from the NP's end and NOT a manual submission of logs to the NO API through Postman.**

### Additional Requirements

- All Buyer and Seller Network Participants are also requested to share all **unsolicited calls** that they receive/respond to for various APIs.
- Buyer and Seller Applications must **anonymise the Personally Identifiable Information (PII)** in each API.
- **City and Pincode must NOT be anonymised** in the JSON.
- All Network Participants are also requested to share **ACKs and NACKs** for each request and response.

### Compliance

NO requirements are **policy-mandatory** to ensure compliance with the ONDC [notification](https://ondc-static-website-media.s3.ap-south-1.amazonaws.com/ondc-website-media/downloads/notifications/ONDC_Notification_Network_Observability_on_ONDC_Network_14June2023.pdf).

### API Endpoint

| Property | Value |
|----------|-------|
| **Base URL** | `https://analytics-api.aws.ondc.org` |
| **API Endpoint** | `https://analytics-api.aws.ondc.org/v1/api/push-txn-logs` |

---

## Schema for Pushing Logs on Network Observability API in Prod Environment

The schema for pushing logs to Network Observability is described below for various domains and use cases. The Postman collection can be found [here](https://drive.google.com/file/d/1VbWWaPMqBn7XPVvgEZ3Ph9rU7VffpGZj/view?usp=drive_link).

---

## Retail, Logistics, Financial Services, Gift Cards & Mobility Examples

### `/init` (Request)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| init         | No              | `init`                 |

```json
{
  "type": "init",
  "data": {
    "context": {
      "ttl": "PT5S",
      "city": "std:080",
      "action": "init",
      "bap_id": "buyerapp.com",
      "bpp_id": "sellerapp.com",
      "domain": "nic2004:52110",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_uri": "https://sellerapp.com/ondc",
      "country": "IND",
      "timestamp": "2023-07-13T13:38:11.687Z",
      "message_id": "1689255491687805",
      "core_version": "1.1.0",
      "transaction_id": "59079540_txn"
    },
    "message": {
      "order": {
        "items": [
          {
            "id": "16448638_50703576",
            "quantity": {
              "count": 1
            },
            "fulfillment_id": "705dad78-e7d5-4a92-8b09-2c9bc8a442f3"
          }
        ],
        "billing": {
          "name": "Pampapathi",
          "phone": "8861728010",
          "address": {
            "city": "Bengaluru",
            "name": "Pampapathi",
            "state": "Karnataka",
            "country": "IND",
            "building": "Shree pg",
            "locality": "Shivagange layout, Shiva Ganga Layout, Mahadevapura",
            "area_code": "560048"
          },
          "created_at": "2023-07-13T13:38:11.687Z",
          "updated_at": "2023-07-13T13:38:11.687Z"
        },
        "provider": {
          "id": "975967",
          "locations": [
            {
              "id": "975967"
            }
          ]
        },
        "fulfillments": [
          {
            "id": "705dad78-e7d5-4a92-8b09-2c9bc8a442f3",
            "end": {
              "contact": {
                "phone": "8861728010"
              },
              "location": {
                "gps": "12.989441871643066,77.69075012207031",
                "address": {
                  "city": "Bengaluru",
                  "name": "Pampapathi",
                  "state": "Karnataka",
                  "country": "IND",
                  "building": "Shree pg",
                  "locality": "Shivagange layout, Shiva Ganga Layout, Mahadevapura",
                  "area_code": "560048"
                }
              }
            },
            "type": "Delivery",
            "tracking": false
          }
        ]
      }
    }
  }
}
```

> **Note:** The `type` field corresponds to the API action name. The `data` object reflects the actual transaction payload.

---

### `/init` (Synchronous Response)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| init         | Yes             | `init_response`        |

```json
{
  "type": "init_response",
  "data": {
    "context": {
      "ttl": "PT5S",
      "city": "std:080",
      "action": "init",
      "bap_id": "buyerapp.com",
      "bpp_id": "sellerapp.com",
      "domain": "nic2004:52110",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_uri": "https://sellerapp.com/ondc",
      "country": "IND",
      "timestamp": "2023-07-13T13:38:11.687Z",
      "message_id": "1689255491687805",
      "core_version": "1.1.0",
      "transaction_id": "59079540_txn"
    },
    "message": {
      "ack": {
        "status": "ACK"
      }
    }
  }
}
```

> **Note:** The synchronous response always contains the `context` object from the original request.

---

### `/on_init` (Request)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| on_init      | No              | `on_init`              |

```json
{
  "type": "on_init",
  "data": {
    "context": {
      "ttl": "PT30S",
      "city": "std:022",
      "action": "on_init",
      "bap_id": "buyerapp.com",
      "bpp_id": "sellerapp.com",
      "domain": "nic2004:52110",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_uri": "https://sellerapp.com/ondc",
      "country": "IND",
      "timestamp": "2023-07-13T18:26:58.701Z",
      "message_id": "1688545618700",
      "core_version": "1.1.0",
      "transaction_id": "59079540_txn"
    },
    "message": {
      "order": {
        "id": "O1",
        "items": [
          {
            "id": "28896054_97286916",
            "quantity": {
              "count": 1
            },
            "fulfillment_id": "69480353-e6ba-4b55-8915-29d8487e2b24"
          }
        ],
        "quote": {
          "ttl": "P1D",
          "price": {
            "value": "221.8",
            "currency": "INR"
          },
          "breakup": [
            {
              "item": {
                "price": {
                  "value": "134.4",
                  "currency": "INR"
                }
              },
              "price": {
                "value": "134.4",
                "currency": "INR"
              },
              "title": "Spicy Aloo Crunch Burger __ Choco Mud Pie (Save Rs.20 Extra)",
              "@ondc/org/item_id": "28896054_97286916",
              "@ondc/org/title_type": "item",
              "@ondc/org/item_quantity": {
                "count": 1
              }
            },
            {
              "price": {
                "value": "8.4",
                "currency": "INR"
              },
              "title": "Tax",
              "@ondc/org/item_id": "28896054_97286916",
              "@ondc/org/title_type": "tax"
            },
            {
              "price": {
                "value": "79",
                "currency": "INR"
              },
              "title": "Delivery Charge",
              "@ondc/org/item_id": "69480353-e6ba-4b55-8915-29d8487e2b24",
              "@ondc/org/title_type": "delivery"
            }
          ]
        },
        "state": "Created",
        "billing": {
          "name": "User",
          "phone": "9306971443",
          "address": {
            "city": "Mumbai",
            "name": "Lokhandwala Township, Kandivali East",
            "state": "Maharashtra",
            "country": "INDIA",
            "building": "Centrium Mall",
            "locality": "Centrium Mall",
            "area_code": "400101"
          },
          "created_at": "2023-07-13T18:26:46.819Z",
          "updated_at": "2023-07-13T18:26:46.819Z"
        },
        "payment": {
          "type": "ON-ORDER",
          "params": {
            "amount": "121.82",
            "currency": "INR"
          },
          "status": "PAID",
          "collected_by": "BAP",
          "@ondc/org/settlement_details": [
            {
              "bank_name": "HDFC Bank",
              "branch_name": "DLF Galleria, Gurgaon, 122009",
              "settlement_type": "neft",
              "settlement_phase": "sale-amount",
              "settlement_ifsc_code": "HDFC00011",
              "settlement_counterparty": "seller-app",
              "settlement_bank_account_no": "543"
            }
          ],
          "@ondc/org/buyer_app_finder_fee_type": "percent",
          "@ondc/org/buyer_app_finder_fee_amount": "5"
        },
        "provider": {
          "id": "11813667",
          "locations": [
            {
              "id": "11813667"
            }
          ]
        },
        "fulfillments": [
          {
            "id": "69480353-e6ba-4b55-8915-29d8487e2b24",
            "end": {
              "person": {
                "name": "User"
              },
              "contact": {
                "phone": "7306971443"
              },
              "location": {
                "gps": "19.196517944335938,72.86885685058789",
                "address": {
                  "city": "Mumbai",
                  "name": "Lokhandwala Township, Kandivali East",
                  "state": "Maharashtra",
                  "country": "INDIA",
                  "building": "Centrium Mall",
                  "locality": "Centrium Mall",
                  "area_code": "400101"
                }
              },
              "instructions": {
                "name": "Instructions to merchant"
              }
            },
            "type": "Delivery",
            "tracking": false
          }
        ]
      }
    }
  }
}
```

---

### `/on_init` (Synchronous Response)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| on_init      | Yes             | `on_init_response`     |

```json
{
  "type": "on_init_response",
  "data": {
    "context": {
      "ttl": "PT30S",
      "city": "std:022",
      "action": "on_init",
      "bap_id": "buyerapp.com",
      "bpp_id": "sellerapp.com",
      "domain": "nic2004:52110",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_uri": "https://sellerapp.com/ondc",
      "country": "IND",
      "timestamp": "2023-07-13T18:26:58.701Z",
      "message_id": "1688545618700",
      "core_version": "1.1.0",
      "transaction_id": "59079540_txn"
    },
    "message": {
      "ack": {
        "status": "NACK"
      }
    },
    "error": {
      "type": "DOMAIN-ERROR",
      "code": "30009"
    }
  }
}
```

---

## 1. IGM Examples

> **Note:** The `type` field for IGM APIs takes values such as `issue`, `issue_response`, `on_issue`, `on_issue_response`, `issue_status`, `issue_status_response`, `on_issue_status`, and `on_issue_status_response`. For synchronous responses (ACK/NACK), `_response` is used as a suffix. For example, the synchronous response for `/issue` uses the type value `issue_response`.

### `/issue` (Request)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| issue        | No              | `issue`                |

```json
{
  "type": "issue",
  "data": {
    "context": {
      "domain": "ONDC:RET10",
      "country": "IND",
      "city": "std:080",
      "action": "issue",
      "core_version": "1.0.0",
      "bap_id": "buyerapp.com",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_id": "sellerapp.com",
      "bpp_uri": "https://sellerapp.com/ondc",
      "transaction_id": "T1",
      "message_id": "M1",
      "timestamp": "2023-01-15T10:00:00.469Z",
      "ttl": "PT30S"
    },
    "message": {
      "issue": {
        "id": "I1",
        "category": "ITEM",
        "sub_category": "ITM04",
        "complainant_info": {
          "person": {
            "name": "Sam Manuel"
          },
          "contact": {
            "phone": "9879879870",
            "email": "sam@yahoo.com"
          }
        },
        "order_details": {
          "id": "4597f703-e84f-431e-a96a-d147cfa142f9",
          "state": "Completed",
          "items": [
            {
              "id": "18275-ONDC-1-9",
              "quantity": 1
            }
          ],
          "fulfillments": [
            {
              "id": "Fulfillment1",
              "state": "Order-delivered"
            }
          ],
          "provider_id": "P1"
        },
        "description": {
          "short_desc": "Issue with product quality",
          "long_desc": "product quality is not correct. facing issues while using the product",
          "additional_desc": {
            "url": "https://buyerapp.com/additonal-details/desc.txt",
            "content_type": "text/plain"
          },
          "images": [
            "http://buyerapp.com/addtional-details/img1.png",
            "http://buyerapp.com/addtional-details/img2.png"
          ]
        },
        "source": {
          "network_participant_id": "buyerapp.com/ondc",
          "type": "CONSUMER"
        },
        "expected_response_time": {
          "duration": "PT2H"
        },
        "expected_resolution_time": {
          "duration": "P1D"
        },
        "status": "OPEN",
        "issue_type": "ISSUE",
        "issue_actions": {
          "complainant_actions": [
            {
              "complainant_action": "OPEN",
              "short_desc": "Complaint created",
              "updated_at": "2023-01-15T10:00:00.469Z",
              "updated_by": {
                "org": {
                  "name": "buyerapp.com::ONDC:RET10"
                },
                "contact": {
                  "phone": "9450394039",
                  "email": "buyerapp@interface.com"
                },
                "person": {
                  "name": "John Doe"
                }
              }
            }
          ]
        },
        "created_at": "2023-01-15T10:00:00.469Z",
        "updated_at": "2023-01-15T10:00:00.469Z"
      }
    }
  }
}
```

> **Note:** The `data` object reflects the actual transaction payload.

---

### `/issue` (Synchronous Response)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| issue        | Yes             | `issue_response`       |

```json
{
  "type": "issue_response",
  "data": {
    "context": {
      "domain": "ONDC:RET10",
      "country": "IND",
      "city": "std:080",
      "action": "issue",
      "core_version": "1.0.0",
      "bap_id": "buyerapp.com",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_id": "sellerapp.com",
      "bpp_uri": "https://sellerapp.com/ondc",
      "transaction_id": "T1",
      "message_id": "M1",
      "timestamp": "2023-01-15T10:00:00.469Z",
      "ttl": "PT30S"
    },
    "message": {
      "ack": {
        "status": "ACK"
      }
    }
  }
}
```

> **Note:** The synchronous response always contains the `context` object.

---

### `/on_issue` (Request)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| on_issue     | No              | `on_issue`             |

```json
{
  "type": "on_issue",
  "data": {
    "context": {
      "domain": "ONDC:RET10",
      "country": "IND",
      "city": "std:080",
      "action": "on_issue",
      "core_version": "1.0.0",
      "bap_id": "buyerapp.com",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_id": "sellerapp.com",
      "bpp_uri": "https://sellerapp.com/ondc",
      "transaction_id": "T1",
      "message_id": "M1",
      "timestamp": "2023-01-15T10:10:00.142Z"
    },
    "message": {
      "issue": {
        "id": "I1",
        "issue_actions": {
          "respondent_actions": [
            {
              "respondent_action": "PROCESSING",
              "short_desc": "Complaint is being processed",
              "updated_at": "2023-01-15T10:10:00.142Z",
              "updated_by": {
                "org": {
                  "name": "sellerapp.com/ondc::ONDC:RET10"
                },
                "contact": {
                  "phone": "9450394140",
                  "email": "respondentapp@respond.com"
                },
                "person": {
                  "name": "Jane Doe"
                }
              },
              "cascaded_level": 1
            }
          ]
        },
        "created_at": "2023-01-15T10:00:00.469Z",
        "updated_at": "2023-01-15T10:10:00.142Z"
      }
    }
  }
}
```

---

### `/on_issue` (Synchronous Response)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| on_issue     | Yes             | `on_issue_response`    |

```json
{
  "type": "on_issue_response",
  "data": {
    "context": {
      "domain": "ONDC:RET10",
      "country": "IND",
      "city": "std:080",
      "action": "on_issue",
      "core_version": "1.0.0",
      "bap_id": "buyerapp.com",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_id": "sellerapp.com",
      "bpp_uri": "https://sellerapp.com/ondc",
      "transaction_id": "T1",
      "message_id": "M1",
      "timestamp": "2023-01-15T10:10:00.142Z"
    },
    "message": {
      "ack": {
        "status": "NACK"
      }
    },
    "error": {
      "type": "DOMAIN-ERROR",
      "code": "30009"
    }
  }
}
```

---

### `/issue_status` (Request)

| Request Name  | Is it ACK/NACK? | `type` Value in Request |
|---------------|:---------------:|------------------------|
| issue_status  | No              | `issue_status`         |

```json
{
  "type": "issue_status",
  "data": {
    "context": {
      "domain": "ONDC:RET10",
      "country": "IND",
      "city": "std:080",
      "action": "issue_status",
      "core_version": "1.0.0",
      "bap_id": "buyerapp.com",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_id": "sellerapp.com",
      "bpp_uri": "https://sellerapp.com/ondc",
      "transaction_id": "T1",
      "message_id": "M2",
      "timestamp": "2023-01-15T10:30:00.469Z",
      "ttl": "PT30S"
    },
    "message": {
      "issue_id": "I1"
    }
  }
}
```

---

### `/issue_status` (Synchronous Response)

| Request Name  | Is it ACK/NACK? | `type` Value in Request    |
|---------------|:---------------:|----------------------------|
| issue_status  | Yes             | `issue_status_response`    |

```json
{
  "type": "issue_status_response",
  "data": {
    "context": {
      "domain": "ONDC:RET10",
      "country": "IND",
      "city": "std:080",
      "action": "issue_status",
      "core_version": "1.0.0",
      "bap_id": "buyerapp.com",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_id": "sellerapp.com",
      "bpp_uri": "https://sellerapp.com/ondc",
      "transaction_id": "T1",
      "message_id": "M2",
      "timestamp": "2023-01-15T10:30:00.469Z",
      "ttl": "PT30S"
    },
    "message": {
      "ack": {
        "status": "ACK"
      }
    }
  }
}
```

---

### `/on_issue_status` (Request)

| Request Name     | Is it ACK/NACK? | `type` Value in Request |
|------------------|:---------------:|------------------------|
| on_issue_status  | No              | `on_issue_status`      |

```json
{
  "type": "on_issue_status",
  "data": {
    "context": {
      "domain": "ONDC:RET10",
      "country": "IND",
      "city": "std:080",
      "action": "on_issue_status",
      "core_version": "1.0.0",
      "bap_id": "buyerapp.com",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_id": "sellerapp.com",
      "bpp_uri": "https://sellerapp.com/ondc",
      "transaction_id": "T1",
      "message_id": "M2",
      "timestamp": "2023-01-15T10:31:00.523Z"
    },
    "message": {
      "issue": {
        "id": "I1",
        "issue_actions": {
          "respondent_actions": [
            {
              "respondent_action": "PROCESSING",
              "short_desc": "Complaint is being processed",
              "updated_at": "2023-01-15T10:10:00.142Z",
              "updated_by": {
                "org": {
                  "name": "sellerapp.com::ONDC:RET10"
                },
                "contact": {
                  "phone": "9450394140",
                  "email": "respondentapp@respond.com"
                },
                "person": {
                  "name": "Jane Doe"
                }
              },
              "cascaded_level": 1
            },
            {
              "respondent_action": "RESOLVED",
              "short_desc": "Complaint resolved",
              "updated_at": "2023-01-15T10:31:00.523Z",
              "updated_by": {
                "org": {
                  "name": "sellerapp.com::ONDC:RET10"
                },
                "contact": {
                  "phone": "9450394140",
                  "email": "respondentapp@respond.com"
                },
                "person": {
                  "name": "Jane Doe"
                }
              },
              "cascaded_level": 1
            }
          ]
        },
        "created_at": "2023-01-15T10:00:00.469Z",
        "updated_at": "2023-01-15T10:31:00.523Z",
        "resolution_provider": {
          "respondent_info": {
            "type": "TRANSACTION-COUNTERPARTY-NP",
            "organization": {
              "org": {
                "name": "sellerapp.com::ONDC:RET10"
              },
              "contact": {
                "phone": "9059304940",
                "email": "email@resolutionproviderorg.com"
              },
              "person": {
                "name": "resolution provider org contact person name"
              }
            },
            "resolution_support": {
              "chat_link": "http://chat-link/respondent",
              "contact": {
                "phone": "9949595059",
                "email": "respondantemail@resolutionprovider.com"
              },
              "gros": [
                {
                  "person": {
                    "name": "Sam D"
                  },
                  "contact": {
                    "phone": "9605960796",
                    "email": "email@gro.com"
                  },
                  "gro_type": "TRANSACTION-COUNTERPARTY-NP-GRO"
                }
              ]
            }
          }
        },
        "resolution": {
          "short_desc": "Refund to be initiated",
          "long_desc": "For this complaint, refund is to be initiated",
          "action_triggered": "REFUND",
          "refund_amount": "100"
        }
      }
    }
  }
}
```

---

### `/on_issue_status` (Synchronous Response)

| Request Name     | Is it ACK/NACK? | `type` Value in Request        |
|------------------|:---------------:|--------------------------------|
| on_issue_status  | Yes             | `on_issue_status_response`     |

```json
{
  "type": "on_issue_status_response",
  "data": {
    "context": {
      "domain": "ONDC:RET10",
      "country": "IND",
      "city": "std:080",
      "action": "on_issue_status",
      "core_version": "1.0.0",
      "bap_id": "buyerapp.com",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_id": "sellerapp.com",
      "bpp_uri": "https://sellerapp.com/ondc",
      "transaction_id": "T1",
      "message_id": "M2",
      "timestamp": "2023-01-15T10:31:00.523Z"
    },
    "message": {
      "ack": {
        "status": "ACK"
      }
    }
  }
}
```

---

## RSF Examples

For RSF (Reconciliation & Settlement Framework), the NP must submit all APIs — `recon`, `on_recon`, `settle`, `on_settle`, `report`, `on_report` — along with their subsequent synchronous responses.

> **Note:** The `type` field for RSF APIs takes values such as `recon`, `recon_response`, `on_recon`, `on_recon_response`, `settle`, `settle_response`, `on_settle`, `on_settle_response`, `report`, `report_response`, `on_report`, `on_report_response`, and so on. For synchronous responses (ACK/NACK), `_response` is used as a suffix. For example, the synchronous response for `/recon` uses the type value `recon_response`.

### `/recon` (Request)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| recon        | No              | `recon`                |

```json
{
  "type": "recon",
  "data": {
    "context": {
      "domain": "ONDC:NTS10",
      "location": {
        "country": {
          "code": "IND"
        },
        "city": {
          "code": "*"
        }
      },
      "version": "2.0.0",
      "action": "recon",
      "bap_id": "collector-app.com",
      "bap_uri": "https://collector-app.com/ondc/1.0/",
      "bpp_id": "receiver-app.com",
      "bpp_uri": "https://receiver-app.com/ondc/",
      "transaction_id": "bd73a366-aebb-4144-9314-808dda82c7e6",
      "message_id": "941ef6d7-d74d-4411-ac06-a05469c0f9ac",
      "timestamp": "2024-05-07T06:36:50.897Z",
      "ttl": "P1D"
    },
    "message": {
      "orders": [
        {
          "id": "order-1234",
          "amount": {
            "currency": "INR",
            "value": "300.00"
          },
          "settlements": [
            {
              "id": "settlement-id-456",
              "payment_id": "pymnt-1",
              "status": "PENDING",
              "amount": {
                "currency": "INR",
                "value": "100.00"
              },
              "commission": {
                "currency": "INR",
                "value": "10.00"
              },
              "withholding_amount": {
                "currency": "INR",
                "value": "10.00"
              },
              "tcs": {
                "currency": "INR",
                "value": "10.00"
              },
              "tds": {
                "currency": "INR",
                "value": "10.00"
              },
              "updated_at": "2024-05-07T07:36:50.897Z"
            },
            {
              "id": "settlement-id-789",
              "payment_id": "pymnt-2",
              "status": "SETTLED",
              "amount": {
                "currency": "INR",
                "value": "100.00"
              },
              "commission": {
                "currency": "INR",
                "value": "10.00"
              },
              "withholding_amount": {
                "currency": "INR",
                "value": "10.00"
              },
              "tds": {
                "currency": "INR",
                "value": "10.00"
              },
              "tcs": {
                "currency": "INR",
                "value": "10.00"
              },
              "settlement_ref_no": "utr-1234",
              "updated_at": "2024-05-07T06:36:50.897Z"
            },
            {
              "id": "settlement-id-112",
              "payment_id": "pymnt-3",
              "status": "TO-BE-INITIATED",
              "amount": {
                "currency": "INR",
                "value": "100.00"
              },
              "commission": {
                "currency": "INR",
                "value": "10.00"
              },
              "withholding_amount": {
                "currency": "INR",
                "value": "10.00"
              },
              "tds": {
                "currency": "INR",
                "value": "10.00"
              },
              "tcs": {
                "currency": "INR",
                "value": "10.00"
              },
              "updated_at": "2024-05-07T06:36:50.897Z"
            }
          ]
        }
      ]
    }
  }
}
```

> **Note:** The `data` object reflects the actual transaction payload of that API.

---

### `/recon` (Synchronous Response)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| on_recon     | Yes             | `recon_response`       |

```json
{
  "type": "recon_response",
  "data": {
    "context": {
      "domain": "ONDC:NTS10",
      "location": {
        "country": {
          "code": "IND"
        },
        "city": {
          "code": "*"
        }
      },
      "version": "2.0.0",
      "action": "recon",
      "bap_id": "collector-app.com",
      "bap_uri": "https://collector-app.com/ondc/1.0/",
      "bpp_id": "receiver-app.com",
      "bpp_uri": "https://receiver-app.com/ondc/",
      "transaction_id": "bd73a366-aebb-4144-9314-808dda82c7e6",
      "message_id": "941ef6d7-d74d-4411-ac06-a05469c0f9ac",
      "timestamp": "2024-05-07T06:36:50.897Z",
      "ttl": "P1D"
    },
    "message": {
      "ack": {
        "status": "ACK"
      }
    }
  }
}
```

> **Note:** The synchronous response always contains the `context` object.

---

### `/on_recon` (Request)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| on_recon     | No              | `on_recon`             |

```json
{
  "type": "on_recon",
  "data": {
    "context": {
      "domain": "ONDC:NTS10",
      "location": {
        "country": {
          "code": "IND"
        },
        "city": {
          "code": "*"
        }
      },
      "version": "2.0.0",
      "action": "on_recon",
      "bap_id": "collector-app.com",
      "bap_uri": "https://collector-app.com/ondc/1.0/",
      "bpp_id": "receiver-app.com",
      "bpp_uri": "https://receiver-app.com/ondc/",
      "transaction_id": "bd73a366-aebb-4144-9314-808dda82c7e6",
      "message_id": "941ef6d7-d74d-4411-ac06-a05469c0f9ac",
      "timestamp": "2024-05-07T06:36:51.897Z",
      "ttl": "P1D"
    },
    "message": {
      "orders": [
        {
          "id": "order-1234",
          "amount": {
            "currency": "INR",
            "value": "310.00"
          },
          "recon_accord": false,
          "settlements": [
            {
              "id": "settlement-id-456",
              "payment_id": "pymnt-1",
              "status": "PENDING",
              "amount": {
                "currency": "INR",
                "value": "120.00",
                "diff_value": "20.00"
              },
              "commission": {
                "currency": "INR",
                "value": "10.00",
                "diff_value": "0.00"
              },
              "withholding_amount": {
                "currency": "INR",
                "value": "10.00",
                "diff_value": "0.00"
              },
              "tcs": {
                "currency": "INR",
                "value": "10.00",
                "diff_value": "0.00"
              },
              "tds": {
                "currency": "INR",
                "value": "10.00",
                "diff_value": "0.00"
              },
              "updated_at": "2024-05-07T07:36:51.897Z"
            },
            {
              "id": "settlement-id-789",
              "payment_id": "pymnt-2",
              "status": "SETTLED",
              "amount": {
                "currency": "INR",
                "value": "100.00"
              },
              "commission": {
                "currency": "INR",
                "value": "10.00"
              },
              "withholding_amount": {
                "currency": "INR",
                "value": "10.00"
              },
              "tds": {
                "currency": "INR",
                "value": "10.00"
              },
              "tcs": {
                "currency": "INR",
                "value": "10.00"
              },
              "settlement_ref_no": "utr-1234",
              "updated_at": "2024-05-07T06:36:51.897Z"
            },
            {
              "id": "settlement-id-112",
              "payment_id": "pymnt-3",
              "status": "TO-BE-INITIATED",
              "amount": {
                "currency": "INR",
                "value": "90.00",
                "diff_value": "10.00"
              },
              "commission": {
                "currency": "INR",
                "value": "10.00",
                "diff_value": "0.00"
              },
              "withholding_amount": {
                "currency": "INR",
                "value": "10.00",
                "diff_value": "0.00"
              },
              "tds": {
                "currency": "INR",
                "value": "10.00",
                "diff_value": "0.00"
              },
              "tcs": {
                "currency": "INR",
                "value": "10.00",
                "diff_value": "0.00"
              },
              "updated_at": "2024-05-07T06:36:51.897Z"
            }
          ]
        }
      ]
    }
  }
}
```

> **Note:** The `data` object reflects the actual transaction payload of that API.

---

### `/on_recon` (Synchronous Response)

| Request Name | Is it ACK/NACK? | `type` Value in Request  |
|--------------|:---------------:|--------------------------|
| on_recon     | Yes             | `on_recon_response`      |

```json
{
  "type": "on_recon_response",
  "data": {
    "context": {
      "domain": "ONDC:NTS10",
      "location": {
        "country": {
          "code": "IND"
        },
        "city": {
          "code": "*"
        }
      },
      "version": "2.0.0",
      "action": "on_recon",
      "bap_id": "collector-app.com",
      "bap_uri": "https://collector-app.com/ondc/1.0/",
      "bpp_id": "receiver-app.com",
      "bpp_uri": "https://receiver-app.com/ondc/",
      "transaction_id": "bd73a366-aebb-4144-9314-808dda82c7e6",
      "message_id": "941ef6d7-d74d-4411-ac06-a05469c0f9ac",
      "timestamp": "2024-05-07T06:36:51.897Z",
      "ttl": "P1D"
    },
    "message": {
      "ack": {
        "status": "ACK"
      }
    }
  }
}
```

> **Note:** The synchronous response always contains the `context` object.

---

## Error Payload Examples as per the API Contract

This section covers error payloads for errors defined within the API contract — whether they appear in the request payload or in the synchronous response payload during a NACK.

> **Note:** The `type` field takes values such as `init`, `init_response`, `on_init`, `on_init_response`, and so on for other actions. For synchronous responses (ACK/NACK), `_response` is used as a suffix. For example, the synchronous response for `/init` uses the type value `init_response`.

### `/init` (Request)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| init         | No              | `init`                 |

```json
{
  "type": "init",
  "data": {
    "context": {
      "ttl": "PT5S",
      "city": "std:080",
      "action": "init",
      "bap_id": "buyerapp.com",
      "bpp_id": "sellerapp.com",
      "domain": "nic2004:52110",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_uri": "https://sellerapp.com/ondc",
      "country": "IND",
      "timestamp": "2023-07-13T13:38:11.687Z",
      "message_id": "1689255491687805",
      "core_version": "1.1.0",
      "transaction_id": "59079540_txn"
    },
    "message": {
      "order": {
        "items": [
          {
            "id": "16448638_50703576",
            "quantity": {
              "count": 1
            },
            "fulfillment_id": "705dad78-e7d5-4a92-8b09-2c9bc8a442f3"
          }
        ],
        "billing": {
          "name": "Pampapathi",
          "phone": "8861728010",
          "address": {
            "city": "Bengaluru",
            "name": "Pampapathi",
            "state": "Karnataka",
            "country": "IND",
            "building": "Shree pg",
            "locality": "Shivagange layout, Shiva Ganga Layout, Mahadevapura",
            "area_code": "560048"
          },
          "created_at": "2023-07-13T13:38:11.687Z",
          "updated_at": "2023-07-13T13:38:11.687Z"
        },
        "provider": {
          "id": "975967",
          "locations": [
            {
              "id": "975967"
            }
          ]
        },
        "created_at": "",
        "updated_at": "",
        "fulfillments": [
          {
            "id": "705dad78-e7d5-4a92-8b09-2c9bc8a442f3",
            "end": {
              "contact": {
                "phone": "8861728010"
              },
              "location": {
                "gps": "12.989441871643066,77.69075012207031",
                "address": {
                  "city": "Bengaluru",
                  "name": "Pampapathi",
                  "state": "Karnataka",
                  "country": "IND",
                  "building": "Shree pg",
                  "locality": "Shivagange layout, Shiva Ganga Layout, Mahadevapura",
                  "area_code": "560048"
                }
              }
            },
            "type": "Delivery",
            "tracking": false
          }
        ]
      }
    }
  }
}
```

> **Note:** The `data` object reflects the actual transaction payload.

---

### `/init` (Synchronous Response)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| init         | Yes             | `init_response`        |

```json
{
  "type": "init_response",
  "data": {
    "context": {
      "ttl": "PT5S",
      "city": "std:080",
      "action": "init",
      "bap_id": "buyerapp.com",
      "bpp_id": "sellerapp.com",
      "domain": "nic2004:52110",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_uri": "https://sellerapp.com/ondc",
      "country": "IND",
      "timestamp": "2023-07-13T13:38:11.687Z",
      "message_id": "1689255491687805",
      "core_version": "1.1.0",
      "transaction_id": "59079540_txn"
    },
    "message": {
      "ack": {
        "status": "NACK"
      }
    },
    "error": {
      "type": "DOMAIN-ERROR",
      "code": "20000",
      "message": "appropriate error message"
    }
  }
}
```

> **Note:** The synchronous response always contains the `context` object.

---

### `/on_init` (Request)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| on_init      | No              | `on_init`              |

```json
{
  "type": "on_init",
  "data": {
    "context": {
      "ttl": "PT30S",
      "city": "std:022",
      "action": "on_init",
      "bap_id": "buyerapp.com",
      "bpp_id": "sellerapp.com",
      "domain": "nic2004:52110",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_uri": "https://sellerapp.com/ondc",
      "country": "IND",
      "timestamp": "2023-07-13T18:26:58.701Z",
      "message_id": "1688545618700",
      "core_version": "1.1.0",
      "transaction_id": "59079540_txn"
    },
    "message": {
      "order": {
        "id": "O1",
        "items": [
          {
            "id": "28896054_97286916",
            "quantity": {
              "count": 1
            },
            "fulfillment_id": "69480353-e6ba-4b55-8915-29d8487e2b24"
          }
        ],
        "quote": {
          "ttl": "P1D",
          "price": {
            "value": "221.8",
            "currency": "INR"
          },
          "breakup": [
            {
              "item": {
                "price": {
                  "value": "134.4",
                  "currency": "INR"
                }
              },
              "price": {
                "value": "134.4",
                "currency": "INR"
              },
              "title": "Spicy Aloo Crunch Burger __ Choco Mud Pie (Save Rs.20 Extra)",
              "@ondc/org/item_id": "28896054_97286916",
              "@ondc/org/title_type": "item",
              "@ondc/org/item_quantity": {
                "count": 1
              }
            },
            {
              "price": {
                "value": "8.4",
                "currency": "INR"
              },
              "title": "Tax",
              "@ondc/org/item_id": "28896054_97286916",
              "@ondc/org/title_type": "tax"
            },
            {
              "price": {
                "value": "79",
                "currency": "INR"
              },
              "title": "Delivery Charge",
              "@ondc/org/item_id": "69480353-e6ba-4b55-8915-29d8487e2b24",
              "@ondc/org/title_type": "delivery"
            }
          ]
        },
        "state": "Created",
        "billing": {
          "name": "magicpin User",
          "phone": "7306971443",
          "address": {
            "city": "Mumbai",
            "name": "Lokhandwala Township, Kandivali East",
            "state": "Maharashtra",
            "country": "INDIA",
            "building": "Centrium Mall",
            "locality": "Centrium Mall",
            "area_code": "400101"
          },
          "created_at": "2023-07-13T18:26:46.819Z",
          "updated_at": "2023-07-13T18:26:46.819Z"
        },
        "payment": {
          "type": "ON-ORDER",
          "params": {
            "amount": "121.80000000000001",
            "currency": "INR"
          },
          "status": "PAID",
          "collected_by": "BAP",
          "@ondc/org/settlement_details": [
            {
              "bank_name": "HDFC Bank",
              "branch_name": "DLF Galleria, Gurgaon, 122009",
              "settlement_type": "neft",
              "settlement_phase": "sale-amount",
              "settlement_ifsc_code": "HDFC00011",
              "settlement_counterparty": "seller-app",
              "settlement_bank_account_no": "543"
            }
          ],
          "@ondc/org/buyer_app_finder_fee_type": "percent",
          "@ondc/org/buyer_app_finder_fee_amount": "5"
        },
        "provider": {
          "id": "11813667",
          "locations": [
            {
              "id": "11813667"
            }
          ]
        },
        "created_at": "2023-07-13T18:26:58.701Z",
        "updated_at": "2023-07-13T18:26:58.701Z",
        "fulfillments": [
          {
            "id": "69480353-e6ba-4b55-8915-29d8487e2b24",
            "end": {
              "person": {
                "name": "magicpin User"
              },
              "contact": {
                "phone": "7306971443"
              },
              "location": {
                "gps": "19.196517944335938,72.86885685058789",
                "address": {
                  "city": "Mumbai",
                  "name": "Lokhandwala Township, Kandivali East",
                  "state": "Maharashtra",
                  "country": "INDIA",
                  "building": "Centrium Mall",
                  "locality": "Centrium Mall",
                  "area_code": "400101"
                }
              },
              "instructions": {
                "name": "Instructions to merchant"
              }
            },
            "type": "Delivery",
            "tracking": false
          }
        ]
      }
    },
    "error": {
      "type": "DOMAIN-ERROR",
      "code": "20000",
      "message": "appropriate error message"
    }
  }
}
```

---

### `/on_init` (Synchronous Response)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| on_init      | Yes             | `on_init_response`     |

```json
{
  "type": "on_init_response",
  "data": {
    "context": {
      "ttl": "PT30S",
      "city": "std:022",
      "action": "on_init",
      "bap_id": "buyerapp.com",
      "bpp_id": "sellerapp.com",
      "domain": "nic2004:52110",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_uri": "https://sellerapp.com/ondc",
      "country": "IND",
      "timestamp": "2023-07-13T18:26:58.701Z",
      "message_id": "1688545618700",
      "core_version": "1.1.0",
      "transaction_id": "59079540_txn"
    },
    "message": {
      "ack": {
        "status": "ACK"
      }
    }
  }
}
```

---

## Error Payload Examples for any 4xx or 5xx Errors Apart from the API Contract

This section describes the NO schema for any errors — specifically **4xx and 5xx** — encountered by an NP while calling the system of the counterparty NP. These are errors that fall **outside** the standard API contract error definitions.

> **Note:** The `type` field takes values such as `init`, `init_response`, `on_init`, `on_init_response`, and so on for other actions. For synchronous responses (ACK/NACK), `_response` is used as a suffix. The `error.type` value is set to `TECH-ERROR`, and the `error.code` can take any 4xx or 5xx status code (e.g., `401`, `500`).

### `/init` (Request)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| init         | No              | `init`                 |

```json
{
  "type": "init",
  "data": {
    "context": {
      "ttl": "PT5S",
      "city": "std:080",
      "action": "init",
      "bap_id": "buyerapp.com",
      "bpp_id": "sellerapp.com",
      "domain": "nic2004:52110",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_uri": "https://sellerapp.com/ondc",
      "country": "IND",
      "timestamp": "2023-07-13T13:38:11.687Z",
      "message_id": "1689255491687805",
      "core_version": "1.1.0",
      "transaction_id": "59079540_txn"
    },
    "message": {
      "order": {
        "items": [
          {
            "id": "16448638_50703576",
            "quantity": {
              "count": 1
            },
            "fulfillment_id": "705dad78-e7d5-4a92-8b09-2c9bc8a442f3"
          }
        ],
        "billing": {
          "name": "Pampapathi",
          "phone": "8861728010",
          "address": {
            "city": "Bengaluru",
            "name": "Pampapathi",
            "state": "Karnataka",
            "country": "IND",
            "building": "Shree pg",
            "locality": "Shivagange layout, Shiva Ganga Layout, Mahadevapura",
            "area_code": "560048"
          },
          "created_at": "2023-07-13T13:38:11.687Z",
          "updated_at": "2023-07-13T13:38:11.687Z"
        },
        "provider": {
          "id": "975967",
          "locations": [
            {
              "id": "975967"
            }
          ]
        },
        "created_at": "",
        "updated_at": "",
        "fulfillments": [
          {
            "id": "705dad78-e7d5-4a92-8b09-2c9bc8a442f3",
            "end": {
              "contact": {
                "phone": "8861728010"
              },
              "location": {
                "gps": "12.989441871643066,77.69075012207031",
                "address": {
                  "city": "Bengaluru",
                  "name": "Pampapathi",
                  "state": "Karnataka",
                  "country": "IND",
                  "building": "Shree pg",
                  "locality": "Shivagange layout, Shiva Ganga Layout, Mahadevapura",
                  "area_code": "560048"
                }
              }
            },
            "type": "Delivery",
            "tracking": false
          }
        ]
      }
    },
    "error": {
      "type": "TECH-ERROR",
      "code": "4xx",
      "message": "appropriate error message"
    }
  }
}
```

> **Note:** The `error.type` value is set to `TECH-ERROR`. The `error.code` can take any 4xx or 5xx status code (e.g., `401`).

---

### `/on_init` (Request)

| Request Name | Is it ACK/NACK? | `type` Value in Request |
|--------------|:---------------:|------------------------|
| on_init      | No              | `on_init`              |

```json
{
  "type": "on_init",
  "data": {
    "context": {
      "ttl": "PT30S",
      "city": "std:022",
      "action": "on_init",
      "bap_id": "buyerapp.com",
      "bpp_id": "sellerapp.com",
      "domain": "nic2004:52110",
      "bap_uri": "https://buyerapp.com/ondc",
      "bpp_uri": "https://sellerapp.com/ondc",
      "country": "IND",
      "timestamp": "2023-07-13T18:26:58.701Z",
      "message_id": "1688545618700",
      "core_version": "1.1.0",
      "transaction_id": "59079540_txn"
    },
    "message": {
      "order": {
        "id": "O1",
        "items": [
          {
            "id": "28896054_97286916",
            "quantity": {
              "count": 1
            },
            "fulfillment_id": "69480353-e6ba-4b55-8915-29d8487e2b24"
          }
        ],
        "quote": {
          "ttl": "P1D",
          "price": {
            "value": "221.8",
            "currency": "INR"
          },
          "breakup": [
            {
              "item": {
                "price": {
                  "value": "134.4",
                  "currency": "INR"
                }
              },
              "price": {
                "value": "134.4",
                "currency": "INR"
              },
              "title": "Spicy Aloo Crunch Burger __ Choco Mud Pie (Save Rs.20 Extra)",
              "@ondc/org/item_id": "28896054_97286916",
              "@ondc/org/title_type": "item",
              "@ondc/org/item_quantity": {
                "count": 1
              }
            },
            {
              "price": {
                "value": "8.4",
                "currency": "INR"
              },
              "title": "Tax",
              "@ondc/org/item_id": "28896054_97286916",
              "@ondc/org/title_type": "tax"
            },
            {
              "price": {
                "value": "79",
                "currency": "INR"
              },
              "title": "Delivery Charge",
              "@ondc/org/item_id": "69480353-e6ba-4b55-8915-29d8487e2b24",
              "@ondc/org/title_type": "delivery"
            }
          ]
        },
        "state": "Created",
        "billing": {
          "name": "magicpin User",
          "phone": "7306971443",
          "address": {
            "city": "Mumbai",
            "name": "Lokhandwala Township, Kandivali East",
            "state": "Maharashtra",
            "country": "INDIA",
            "building": "Centrium Mall",
            "locality": "Centrium Mall",
            "area_code": "400101"
          },
          "created_at": "2023-07-13T18:26:46.819Z",
          "updated_at": "2023-07-13T18:26:46.819Z"
        },
        "payment": {
          "type": "ON-ORDER",
          "params": {
            "amount": "121.80000000000001",
            "currency": "INR"
          },
          "status": "PAID",
          "collected_by": "BAP",
          "@ondc/org/settlement_details": [
            {
              "bank_name": "HDFC Bank",
              "branch_name": "DLF Galleria, Gurgaon, 122009",
              "settlement_type": "neft",
              "settlement_phase": "sale-amount",
              "settlement_ifsc_code": "HDFC00011",
              "settlement_counterparty": "seller-app",
              "settlement_bank_account_no": "543"
            }
          ],
          "@ondc/org/buyer_app_finder_fee_type": "percent",
          "@ondc/org/buyer_app_finder_fee_amount": "5"
        },
        "provider": {
          "id": "11813667",
          "locations": [
            {
              "id": "11813667"
            }
          ]
        },
        "created_at": "2023-07-13T18:26:58.701Z",
        "updated_at": "2023-07-13T18:26:58.701Z",
        "fulfillments": [
          {
            "id": "69480353-e6ba-4b55-8915-29d8487e2b24",
            "end": {
              "person": {
                "name": "magicpin User"
              },
              "contact": {
                "phone": "7306971443"
              },
              "location": {
                "gps": "19.196517944335938,72.86885685058789",
                "address": {
                  "city": "Mumbai",
                  "name": "Lokhandwala Township, Kandivali East",
                  "state": "Maharashtra",
                  "country": "INDIA",
                  "building": "Centrium Mall",
                  "locality": "Centrium Mall",
                  "area_code": "400101"
                }
              },
              "instructions": {
                "name": "Instructions to merchant"
              }
            },
            "type": "Delivery",
            "tracking": false
          }
        ]
      }
    },
    "error": {
      "type": "TECH-ERROR",
      "code": "5xx",
      "message": "appropriate error message"
    }
  }
}
```

> **Note:** The `error.type` value is set to `TECH-ERROR`. The `error.code` can take any 4xx or 5xx status code (e.g., `500`).

---

## Schema Validation Error (To Be Released Soon)

### Purpose

The purpose of introducing schema validation errors in the NO API is to assist Network Participants (NPs) in ensuring that transaction logs submitted to the Network Observability (NO) API are well-formed and schema-compliant, thereby reducing downstream errors and manual resolution efforts.

### Validation Principles

- Requests must adhere to the defined JSON schema for each API.
- Mandatory fields must be present and correctly typed.
- Enum values must follow the prescribed set.
- Only allowed fields should be included in the payload.

### Error Types and Response Codes

There are 3 main types of responses that will be received:

- **400x** — for any error in the payload
- **200** — for successful submission of logs
- **200 with 2001 warning** — indicating the logs are successfully submitted but may contain additional, unnecessary information

#### Error Codes (4000 Series)

| Code | Type | Message | Description | Path |
|------|------|---------|-------------|------|
| `4001` | `REQUIRED_FIELD` | `Invalid value: missing required key` | A mandatory field is not present in the request | Describes the actual path of the error |
| `4002` | `INVALID_DATA_TYPE` | `Invalid value: invalid type` | Field value does not match the expected data type | Describes the actual path of the error |
| `4003` | `INVALID_ENUM_VALUE` | `Invalid value: <field_value>, Allowed values as per action are: <valid_enum_values>` | Field value is not one of the allowed enumeration values | Describes the actual path of the error |
|        |                    | `Invalid value: <field_value>, Allowed values are: <valid_enum_values>` | | |

#### Warning Codes (2000 Series)

| Code | Type | Message | Description | Path |
|------|------|---------|-------------|------|
| `2001` | `EXTRA_FIELD` | `Payload contains an extra field: <field_name>` | Extra fields present in the request | Describes the actual path of the error |

---

### 1. Required Field Missing

Ensures all mandatory fields are present as per the defined NO schema.

- **Fields checked:** `type`, `data`, `data.context`, `data.context.action`
- **Error Code:** `4001`
- **Type:** `REQUIRED_FIELD`
- **Message:** `Invalid value: missing required key`
- **Path:** `type`, `data`, `data.context`, `data.message`, `data.context.action`

**Example Request Payload:**

```json
{
  "type": "confirm"
}
```

**Example Response Payload:**

```json
{
  "errors": [
    {
      "message": "Invalid value: missing required key",
      "error_code": 4001,
      "path": "data",
      "error_description": "REQUIRED_FIELD"
    }
  ]
}
```

---

### 2. Invalid Data Type

Verifies that the data provided in each field matches the expected type (e.g., `string`, `object`).

- **Fields checked:** `type`, `data`, `data.context`, `data.context.action`
- **Error Code:** `4002`
- **Type:** `INVALID_DATA_TYPE`
- **Message:** `Invalid value: invalid type`
- **Path:** `type`, `data`, `data.context`, `data.message`, `data.context.action`

**Example Request Payload:**

```json
{
  "type": "confirm",
  "data": {
    "context": "xyz"
  }
}
```

**Example Response Payload:**

```json
{
  "errors": [
    {
      "code": 4002,
      "type": "INVALID_DATA_TYPE",
      "message": "Invalid value: invalid type",
      "path": "data.context"
    }
  ]
}
```

---

### 3. Invalid Enum Value

Validates that the `type` or `action` field does not contain a value outside the allowed enumerations.

#### Case 1: `type` Does Not Match the Expected Value for `action`

- **Condition:** If `data.context.action` is `X`, then `type` must be either `X` or `X_response`.
- **Fields checked:** `type`
- **Error Code:** `4003`
- **Type:** `INVALID_ENUM_VALUE`
- **Message:** `Invalid value: <type_value>, Allowed values as per action are: <valid_enum_values>`
- **Path:** `type`

**Example Request Payload:**

```json
{
  "type": "confirmm",
  "data": {
    "context": {
      "location": {
        "country": { "code": "IND" },
        "city": { "code": "std:011" }
      },
      "domain": "ONDC:TRV11",
      "timestamp": "2025-02-05T04:58:11.562Z",
      "bap_id": "buyer.com",
      "transaction_id": "aa888108-f940-49b6-bcf0-6dc16d65af8b",
      "message_id": "4e36be46-9228-4892-a330-069ce5395fec",
      "version": "2.0.1",
      "action": "confirm",
      "bap_uri": "https://buyer.com",
      "bpp_id": "seller.com",
      "bpp_uri": "https://seller.com",
      "ttl": "PT30S"
    },
    "message": {
      "intent": {
        "fulfillment": {
          "stops": [
            {
              "type": "START",
              "location": { "descriptor": { "code": "NOIDA_SECTOR_37" } }
            },
            {
              "type": "END",
              "location": { "descriptor": { "code": "AIIMS" } }
            }
          ],
          "vehicle": {
            "category": "BUS",
            "variant": null,
            "registration": null
          }
        },
        "payment": {
          "collected_by": "BAP",
          "tags": [
            {
              "descriptor": { "code": "BUYER_FINDER_FEES" },
              "display": false,
              "list": [
                {
                  "descriptor": { "code": "BUYER_FINDER_FEES_PERCENTAGE" },
                  "value": "0.00"
                }
              ]
            },
            {
              "descriptor": { "code": "SETTLEMENT_TERMS" },
              "display": false,
              "list": [
                {
                  "descriptor": { "code": "DELAY_INTEREST" },
                  "value": "0.00"
                },
                {
                  "descriptor": { "code": "STATIC_TERMS" },
                  "value": "https://api.example-bap.com/booking/terms"
                }
              ]
            }
          ]
        }
      }
    }
  }
}
```

**Example Response Payload:**

```json
{
  "errors": [
    {
      "error_code": 4003,
      "message": "Invalid value: confirmm, Allowed values as per action are: confirm, confirm_response",
      "path": "type",
      "error_description": "INVALID_ENUM_VALUE"
    }
  ]
}
```

---

#### Case 2: `type` Not in the Master List of Enums

- **Condition:** `type` is not part of the predefined valid values [list](https://docs.google.com/spreadsheets/d/1MNT2wyRhPiZL38wClUhfPPLHnLHRhPRGVYF_xN5sXw4/edit?usp=sharing).
- **Fields checked:** `type`
- **Error Code:** `4003`
- **Type:** `INVALID_ENUM_VALUE`
- **Message:** `Invalid value: <type_value>, Allowed values are: <valid_enum_values>`
- **Path:** `type`

**Example Request Payload:**

```json
{
  "type": "con_firm",
  "data": {
    "context": {
      "location": {
        "country": { "code": "IND" },
        "city": { "code": "std:011" }
      },
      "domain": "ONDC:TRV11",
      "timestamp": "2025-02-05T04:58:11.562Z",
      "bap_id": "buyer.com",
      "transaction_id": "aa888108-f940-49b6-bcf0-6dc16d65af8b",
      "message_id": "4e36be46-9228-4892-a330-069ce5395fec",
      "version": "2.0.1",
      "action": "con_firm",
      "bap_uri": "https://buyer.com",
      "bpp_id": "seller.com",
      "bpp_uri": "https://seller.com",
      "ttl": "PT30S"
    },
    "message": {
      "intent": {
        "fulfillment": {
          "stops": [
            {
              "type": "START",
              "location": { "descriptor": { "code": "NOIDA_SECTOR_37" } }
            },
            {
              "type": "END",
              "location": { "descriptor": { "code": "AIIMS" } }
            }
          ],
          "vehicle": {
            "category": "BUS",
            "variant": null,
            "registration": null
          }
        },
        "payment": {
          "collected_by": "BAP",
          "tags": [
            {
              "descriptor": { "code": "BUYER_FINDER_FEES" },
              "display": false,
              "list": [
                {
                  "descriptor": { "code": "BUYER_FINDER_FEES_PERCENTAGE" },
                  "value": "0.00"
                }
              ]
            },
            {
              "descriptor": { "code": "SETTLEMENT_TERMS" },
              "display": false,
              "list": [
                {
                  "descriptor": { "code": "DELAY_INTEREST" },
                  "value": "0.00"
                },
                {
                  "descriptor": { "code": "STATIC_TERMS" },
                  "value": "https://api.example-bap.com/booking/terms"
                }
              ]
            }
          ]
        }
      }
    }
  }
}
```

**Example Response Payload:**

```json
{
  "errors": [
    {
      "error_code": 4003,
      "message": "Invalid value: con_firm, Allowed values are: cancel, catalog_rejection, confirm, init, issue, issue_status, on_cancel, on_confirm, on_init, on_issue, on_issue_status, on_select, on_status, on_update, select, status, receiver_recon, on_receiver_recon, update, search, on_search, recon, on_recon, report, on_report, settle, on_settle, track, on_track, info, on_info, cancel_response, catalog_rejection_response, confirm_response, init_response, issue_response, issue_status_response, on_cancel_response, on_confirm_response, on_init_response, on_issue_response, on_issue_status_response, on_select_response, on_status_response, on_update_response, select_response, status_response, receiver_recon_response, on_receiver_recon_response, update_response, search_response, on_search_response, recon_response, on_recon_response, report_response, on_report_response, settle_response, on_settle_response, track_response, on_track_response, info_response, on_info_response",
      "path": "type",
      "error_description": "INVALID_ENUM_VALUE"
    }
  ]
}
```

---

#### Case 3: `data.context.action` Not in the Master List of Enums

- **Condition:** `data.context.action` is not part of the predefined valid values [list](https://docs.google.com/spreadsheets/d/1MNT2wyRhPiZL38wClUhfPPLHnLHRhPRGVYF_xN5sXw4/edit?usp=sharing).
- **Fields checked:** `data.context.action`
- **Error Code:** `4003`
- **Type:** `INVALID_ENUM_VALUE`
- **Message:** `Invalid value: <action_value>, Allowed values are: <valid_enum_values>`
- **Path:** `data.context.action`

**Example Request Payload:**

```json
{
  "type": "confirm",
  "data": {
    "context": {
      "location": {
        "country": { "code": "IND" },
        "city": { "code": "std:011" }
      },
      "domain": "ONDC:TRV11",
      "timestamp": "2025-02-05T04:58:11.562Z",
      "bap_id": "buyer.com",
      "transaction_id": "aa888108-f940-49b6-bcf0-6dc16d65af8b",
      "message_id": "4e36be46-9228-4892-a330-069ce5395fec",
      "version": "2.0.1",
      "action": "con_firm",
      "bap_uri": "https://buyer.com",
      "bpp_id": "seller.com",
      "bpp_uri": "https://seller.com",
      "ttl": "PT30S"
    },
    "message": {
      "intent": {
        "fulfillment": {
          "stops": [
            {
              "type": "START",
              "location": { "descriptor": { "code": "NOIDA_SECTOR_37" } }
            },
            {
              "type": "END",
              "location": { "descriptor": { "code": "AIIMS" } }
            }
          ],
          "vehicle": {
            "category": "BUS",
            "variant": null,
            "registration": null
          }
        },
        "payment": {
          "collected_by": "BAP",
          "tags": [
            {
              "descriptor": { "code": "BUYER_FINDER_FEES" },
              "display": false,
              "list": [
                {
                  "descriptor": { "code": "BUYER_FINDER_FEES_PERCENTAGE" },
                  "value": "0.00"
                }
              ]
            },
            {
              "descriptor": { "code": "SETTLEMENT_TERMS" },
              "display": false,
              "list": [
                {
                  "descriptor": { "code": "DELAY_INTEREST" },
                  "value": "0.00"
                },
                {
                  "descriptor": { "code": "STATIC_TERMS" },
                  "value": "https://api.example-bap.com/booking/terms"
                }
              ]
            }
          ]
        }
      }
    }
  }
}
```

**Example Response Payload:**

```json
{
  "errors": [
    {
      "error_code": 4003,
      "message": "Invalid value: con_firm, Allowed values are: cancel, catalog_rejection, confirm, init, issue, issue_status, on_cancel, on_confirm, on_init, on_issue, on_issue_status, on_select, on_status, on_update, select, status, receiver_recon, on_receiver_recon, update, search, on_search, recon, on_recon, report, on_report, settle, on_settle, track, on_track, info, on_info",
      "path": "data.context.action",
      "error_description": "INVALID_ENUM_VALUE"
    }
  ]
}
```

---

### 4. Extra Fields in Request

Warns NPs when their payload includes fields that are not expected by the schema.

- **Fields checked:** Any attributes other than `type` and `data`
- **Warning Code:** `2001`
- **Type:** `EXTRA_FIELD`
- **Warning Message:** `Payload contains an extra field: <field_name>`
- **Path:** `<field_name>`
- **Success Code:** `200`
- **Message:** `Successful`

**Example Request Payload:**

```json
{
  "type": "confirm",
  "image": "img1",
  "data": {
    "context": {
      "location": {
        "country": { "code": "IND" },
        "city": { "code": "std:011" }
      },
      "domain": "ONDC:TRV11",
      "timestamp": "2025-02-05T04:58:11.562Z",
      "bap_id": "buyer.com",
      "transaction_id": "aa888108-f940-49b6-bcf0-6dc16d65af8b",
      "message_id": "4e36be46-9228-4892-a330-069ce5395fec",
      "version": "2.0.1",
      "action": "con_firm",
      "bap_uri": "https://buyer.com",
      "bpp_id": "seller.com",
      "bpp_uri": "https://seller.com",
      "ttl": "PT30S"
    },
    "message": {
      "intent": {
        "fulfillment": {
          "stops": [
            {
              "type": "START",
              "location": { "descriptor": { "code": "NOIDA_SECTOR_37" } }
            },
            {
              "type": "END",
              "location": { "descriptor": { "code": "AIIMS" } }
            }
          ],
          "vehicle": {
            "category": "BUS",
            "variant": null,
            "registration": null
          }
        },
        "payment": {
          "collected_by": "BAP",
          "tags": [
            {
              "descriptor": { "code": "BUYER_FINDER_FEES" },
              "display": false,
              "list": [
                {
                  "descriptor": { "code": "BUYER_FINDER_FEES_PERCENTAGE" },
                  "value": "0.00"
                }
              ]
            },
            {
              "descriptor": { "code": "SETTLEMENT_TERMS" },
              "display": false,
              "list": [
                {
                  "descriptor": { "code": "DELAY_INTEREST" },
                  "value": "0.00"
                },
                {
                  "descriptor": { "code": "STATIC_TERMS" },
                  "value": "https://api.example-bap.com/booking/terms"
                }
              ]
            }
          ]
        }
      }
    }
  }
}
```

**Example Response Payload:**

```json
{
  "message": "Successful",
  "warnings": [
    {
      "code": 2001,
      "type": "EXTRA_FIELD",
      "message": "Payload contains an extra field: image",
      "path": "image"
    }
  ]
}
```

---

### Success Response

A request will be successfully ingested by the system if it passes all the validation checks mentioned above. In such cases, the request will receive an **HTTP 200** response with the following payload:

```json
{
  "message": "Successful"
}
```

---

### Notes for Implementation

- The NO API does **not** perform deep business logic validation — only schema-level checks.
- Validate JSON before transmission using static schema validators.
- Keep `type` and `action` values tightly aligned with ONDC protocol specifications.

---

## FAQs

**Q: As a Buyer NP, do I have to share data related to Seller-side APIs (e.g., `on_select`, `on_init`, `on_confirm`, `on_status`, `on_update`, `on_cancel`) to NO?**

Yes. As a Network Participant, all API data must be pushed to NO regardless of whether it originates from the Seller side or the Buyer side.

---

**Q: When does an NP push data to NO?**

The data must be pushed to NO on the same day. A transaction occurring on day T should be pushed on day T itself. However, there is a buffer of **2 hours** past the end of day T (i.e., until 2:00 AM of T+1 day). It is advisable to push data in **real time**.

---

**Q: Does the NP have to share synchronous responses?**

Yes. NPs must share both the request payload and the synchronous responses (ACK/NACK/errors). For example, for the `init` API, both the Buyer NP and the Seller NP involved in that transaction must share the `init` request payload (sent by the Buyer NP) as well as the synchronous response (ACK/NACK/error returned by the Seller App).

---

**Q: Does the NO API have schema validation functionality during log submission?**

No. Currently, the NO API does not validate the schema at the time of receiving data on the endpoint.

---

**Q: What response is received from the NO API when logs are pushed?**

The Network Observability API responds with an **HTTP 200** response.

---

**Q: How is this token different from the Preprod NO Token shared during Preprod stage testing?**

The Preprod Token is valid **only** during the Preprod stage and for the Preprod NO API endpoint. The Preprod token will not work for the Prod NO API, and vice versa. The Preprod NO and Prod NO have **different endpoints**.
