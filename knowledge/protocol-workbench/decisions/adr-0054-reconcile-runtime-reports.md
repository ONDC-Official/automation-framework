---
id: adr-0054
date: 2026-06-29
grill-ref: reconcile the 2 runtime reports (2026-06-28 verification + 2026-06-29 w2w-debugging) into the KB
status: accepted
changes: [knowledge-keep-updated, mcp-runtime-agent, tester-playbook]
---

# Reconcile runtime reports; add knowledge-keep-updated frame; fix reference links

## Decision
- Read + reconciled the two runtime reports and ADRs 0048-0053 (live signing/recorder/cookies, txn-cache TTL bug, w2w defect chain, dynamic-form idempotency + /callback fixes, debugging-depth + MCP proposal). The runtime session had already written these back into the frames cleanly.
- Created the missing [[knowledge-keep-updated]] frame (referenced by adr-0053 / the w2w report) capturing the write-back loop the owner asked about; linked it from INDEX.
- Fixed two `[[w2w-debugging-depth-and-mcp-2026-06-29]]` links (a reference doc, not a frame) → plain `references/…` paths.

## Assumptions & perception
- The two reports + ADRs 0048-0053 are owner-verified live work; treated as ground truth. Remaining runtime-pending items are tracked as open questions (FLOW_STATUS on full-flow hop; validateSign on fresh inbound; eKYC fresh-flow verification).

## KB effect
- new frame knowledge-keep-updated; INDEX link; reference-link fixes; triples.
