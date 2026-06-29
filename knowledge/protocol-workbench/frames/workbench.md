---
id: workbench
kind: instance
isa: system
confidence: high
source: interview 2026-06-26 + repo automation-framework
changed-by: adr-0001
---

# Protocol Workbench

The ONDC Protocol Workbench: a universal framework to enable, validate, and experience ONDC open-network protocol implementations. Lets a Network Participant (NP) test API payloads and run end-to-end NP-to-NP flows against a simulated counterparty.

## Slots
- purpose: protocol experience + enablement + API validation + real-world scenario simulation for ONDC NPs
- hosted-instance: https://workbench.ondc.tech/home (prod); dev-automation.ondc.org (dev)
- support-contact: PW-support@ondc.org
- deployment: Docker Compose stack (~16-18 containers) orchestrated by [[automation-framework]]
- repo-model: monorepo (automation-framework) + 9 git submodules + 2 external GHCR images
- core-tools: Schema Validation Tool; Flow Testing Suite; Playground
- ground-truth-note: derived KB supersedes code+README where they disagree (per owner)

## Core tools (user-facing)
- Schema Validation Tool → validates a pasted/uploaded API payload against the ONDC spec for a domain+version+action. See script [[schema-validation]].
- Flow Testing Suite → simulates end-to-end buyer↔seller transactions step by step. See script [[run-flow-test]].
- Playground → free-form flow building via MockRunner. See [[ui-frontend]].

## Relations
- orchestrated-by → [[automation-framework]]
- exposes-protocol-via → [[api-service]]
- protocol-source → [[automation-specifications]]
- simulates-counterparty-via → [[mock-playground-service]]
- records-via → [[recorder-service]]
- persists-via → [[db-service]]
- reports-via → [[report-service]] and [[report-pramaan]]
- serves-config-via → [[config-service]]
- ui → [[ui-frontend]], [[backoffice-frontend]]

## Components (part-of workbench)
9 submodule services + orchestrator + externals — see INDEX taxonomy and per-component frames.

## Open questions
- Confirm prod vs dev URL set and which env this KB primarily documents → owner: Shreyansh
