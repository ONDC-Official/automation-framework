---
id: adr-0018
date: 2026-06-26
grill-ref: deep-dive — api-service / beckn-ONIX internals
status: accepted
changes: [onix-adapter, onix-plugins, signing-security, mock-service-embedded, onix-request-lifecycle, api-service, validation-layers]
---

# Seed ONIX internals sub-book

## Question / context
Deepen the protocol runtime (api-service) to the last bit: adapter modules, plugin chain, signing, mock generation, request lifecycle.

## Decision
Captured the ONIX runtime as a sub-book under api-service:
- onix-adapter: 6 modules (formReceiver, standaloneValidator/test, BapTxnReceiver/seller, BppTxnReceiver/buyer, callbackReceiver, mockTxnCaller/mock), each path + ordered plugin chain + flags; np/mock/form routers; action state machine (transaction_properties.yaml); cookie/jsonPath routing.
- onix-plugins: ONIX-core (schema/ondc/sign/signer/cache/router/network-observability) vs workbench-generated (workbench-main/keymanager/callback-redirect); encryption-middleware present but unwired.
- signing-security: Ed25519 over BLAKE-512; Authorization header; own keys from env, counterparty from registry lookup.
- mock-service-embedded: api-service's bundled mock vs standalone mock-playground-service; class/generator/default/save-data + action-factory pattern.
- onix-request-lifecycle script: end-to-end receiver + caller paths, async callback, edge points.

## Assumptions & perception
- Source: Explore over build-output adapter.yaml + plugins (file:line cited). Structure high-confidence; some response/ACK specifics inferred (script marked confidence medium).
- Paths illustrated for FIS12/2.0.3; structure generalizes per spec.

## KB effect
- new frames onix-adapter, onix-plugins, signing-security, mock-service-embedded; new script onix-request-lifecycle.
- api-service: module list corrected (Bap=seller, Bpp=buyer, mockTxnCaller=mock, form/callback) + ONIX sub-book links; ONIX-boundary open Q resolved.
- validation-layers: per-module enforcement + signing algorithm.
- triples: adapter/plugins/signing/mock facts.
