---
id: api-service-generator
kind: instance
isa: component
part-of: automation-libraries
confidence: high
source: repo automation-api-service-generator/src/* (adr-0031)
changed-by: adr-0031
---

# api-service-generator (@ondc/api-service-generator)

Generates the ONIX [[api-service]] build-output from build.yaml. The codegen behind [[spec-to-runtime]] step 6.

## ONIX pipeline (CreateOnixServer)
1. generateSchemas — `ondc-code-generator schema -c build.yaml -f json` → temp/schemas/{domain}/{version}/{action}.json
2. clonePlugins — git clone automation-beckn-plugins → temp/ (+ buildplugins.sh)
3. generateL1Validations — `ondc-code-generator xval -l go` → temp/validationpkg (Go)
4. updateGoModPath — rewrite go.mod replace for validationpkg
5. createAdapterConfigs — createAdapterFiles() → adapter.yaml + {form,mock,np}_router.yaml + {mock,np}_no_config.yaml + transaction_properties.yaml
6. copyDockerAndComposeFiles — Dockerfile, docker-entrypoint.sh, docker-compose.yml

## Templated vs static
- TEMPLATED (per build): adapter.yaml, router yamls, no_config middleware (createAdapterFiles, AdapterParams: domain, version, port, redisAddress, configServiceURL, mockServiceURL, recorder http/grpc URLs, transactionProperties)
- STATIC (copied): Dockerfile, docker-entrypoint.sh

## adapter.yaml modules (generated) — see [[onix-adapter]]
formReceiver · standaloneValidator(/test) · callbackReceiverBuyer/Seller(/…/callback) · BapTxnReceiver(/seller) · BppTxnReceiver(/buyer) · mockTxnCaller(/mock). Plugins incl. encryptionmiddleware (receivers) / outgoingencryptionmiddleware (mock caller).

## Docker (ONIX)
- stage1 golang:1.25.5 → buildplugins.sh → plugins/*.so (ondcvalidator, workbench, keymanager, networkobservability, cache, router, schemavalidator, signvalidator, signer, encryption mws)
- stage2 ghcr.io/ondc-official/automation-beckn-onix:latest; CMD ./server --config=./config/adapter.yaml
- docker-entrypoint.sh substitutes domain/version/port/redis/urls at start

## Relations
- part-of → [[automation-libraries]] ; produces → [[api-service]] / [[onix-adapter]] / [[onix-plugins]] ; used-by → [[spec-to-runtime]]
