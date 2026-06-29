---
id: transaction-session
kind: class
isa: concept
confidence: high
source: repo mock-playground cache types, recorder cache.go, db SessionDetails
changed-by: adr-0004
---

# Transaction, session, message identifiers

The identity model that ties a flow run together across services.

## Slots
- session_id: one NP login/test session; correlates many transactions; in Redis directly; db SessionDetails record; ~48h TTL in ui-backend
- transaction_id: UUID per buyer-seller flow instance; cache key qualified as `${transaction_id}::${subscriber_url}`
- message_id: unique per API call; triplet (action, message_id, timestamp) matches an incoming request to an expected flow step
- subscriber_url: bap_uri/bpp_uri; segregates cache keys (who owns the entry)
- MOCK_DATA::${txn}::${suburl}: business data extracted from prior payloads (save-data JSONPath) + user_inputs
- FLOW_STATUS / EXTRA_FLOW_STATUS keys: per-transaction step status (set by recorder, read by mock)

## Cross-service rule (from FAQ)
- Use a NEW transaction_id when the API is the first step of a flow; reuse the SAME transaction_id for the rest of the flow.
- bap_url/bpp_url in payload must match the one used to create the UI session.

## Relations
- spans → [[mock-playground-service]] (cache DB0), [[recorder-service]] (writes), [[db-service]] (SessionDetails)

## Redis keyspace (adr-0009; mostly DB0)
- `transactionId::subscriberUrl` → TransactionCache
- `MOCK_DATA::txn::sub` → business data (save-data + user_inputs)
- `FLOW_STATUS_txn::sub` → step status (TTL 5h)
- `EXTRA_FLOW_STATUS_txn::sub::stepKey` → extra-step status (TTL 5h)
- `PLAYGROUND_<sessionId>` → mock-runner config (playground; 5-min in-memory)
- `<sessionId>` → NP session ; `<subscriberUrl>` → subscriber expectations (~5-min)
- recorder shares the txn + flow-status keys

## Redis DB indices (adr-0025, confirmed)
- DB0 = workbench data (WorkbenchCacheService: sessions, transactions, MOCK_DATA, flow-status).
- DB1 = MockRunner config cache (MockRunnerConfigCache).
