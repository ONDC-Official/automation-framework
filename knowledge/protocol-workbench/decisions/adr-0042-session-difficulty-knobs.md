---
id: adr-0042
date: 2026-06-28
grill-ref: RUNTIME-VERIFICATION-PROMPT path 10 (session difficulty), workbench-main source + live /test log
status: accepted
changes: [session-difficulty]
---

# SessionDifficulty has 10 knobs (3 net-new); each propagates as a cookie; protocol_validation→L1 confirmed live

## Decision (source + runtime)
- Runtime struct `cache.SessionDifficulty` (types.go) = 10 bools: sensitiveTTL, useGateway, stopAfterFirstNack, protocolValidations, timeValidations, headerValidaton[sic], useGzip, **encryptionValidation, useCare, useTunnelForFIS** (last three were absent from the KB).
- Defaults (receiver.go defaultDifficulty): sensitiveTTL=true, useGateway=true (search→GATEWAY_URL), stopAfterFirstNack=false, protocolValidations=true, timeValidations=true, headerValidaton=true, useGzip=false, encryptionValidation=false (opt-in), useCare=false (opt-in, issue/on_issue→CARE_URL), useTunnelForFIS=false (opt-in).
- Propagation: workbench receiver sets each knob as a same-named cookie on the OUTBOUND forwarded request (utils.go setRequestCookies): protocol_validation, header_validation, use_gzip, encryption_validation, use_care, use_tunnel_for_fis, use_gateway + ttl_seconds + flow_id/session_id/transaction_id/subscriber_url/subscriber_id/usecase_id/request_owner.
- Confirmed live: protocol_validation gates the ondcvalidator L1 step (log "Executing ONDC validation step with protocol_validation header value: true" on /test/search). protocolValidations=false ⇒ L1 skipped.

## Assumptions & perception
- Source: workbench-main cache/types.go, receiver.go:164-176, utils.go:39+. Live: api-service /test log. High confidence on struct/defaults/propagation. Exhaustive per-knob on/off behavior across all 10 in two live sessions NOT run (would need full flow harness) — logged as remaining open.

## KB effect
- session-difficulty: 3 knobs added, defaults added, cookie-propagation + protocol_validation→L1 gate added; open question narrowed.
