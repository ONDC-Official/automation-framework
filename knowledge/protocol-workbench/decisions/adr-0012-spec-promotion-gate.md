---
id: adr-0012
date: 2026-06-26
grill-ref: grill Q2 — what gates draft→release-eks promotion, who approves
status: accepted
changes: [automation-specifications]
---

# Spec promotion gate = human approval; CI/CD is WIP

## Question / context
What gates the draft→release-eks (prod) promotion of a spec, and who approves?

## Decision
- Promotion is gated by **human approval + verification** — no automated or Pramaan-based gate. (Pramaan certifies NPs, not specs.)
- Owners/approvers: spec owner / protocol architect + protocol engineers.
- The CI/CD workflows (spec-workflow.yml, deploy-onix.yaml) exist but are **WIP / being finalized**; their current mechanics are explicitly out of scope and should not be recorded as stable truth.

## Assumptions & perception
- Owner stated the gate is human approval + verification and that CI/CD is mid-finalization (interview).
- So the KB documents the human governance, not the (volatile) pipeline.

## KB effect
- frame automation-specifications: promotion-gate + approver-roles slots; CI flagged WIP; open Qs narrowed.
- triples: promotion gated-by / approved-by; spec-cicd status WIP.
