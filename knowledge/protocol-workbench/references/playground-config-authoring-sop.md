# Authoring a `MockPlaygroundConfig`

A complete, standalone guide to writing a `MockPlaygroundConfig` — the object that turns one
ONDC transaction flow into an executable mock. This document covers the execution model, every
field you author, and a set of conventions that make each mock function point clearly at the
**business responsibility** it stands in for, so that both humans and AI can read the config and
reconstruct the flow without running it.

> Audience: people writing configs by hand (or AI agents generating them). Everything you need
> is in this file — no external reference required.

---

## Table of contents

1. [What you are authoring](#1-what-you-are-authoring)
2. [The execution model](#2-the-execution-model)
3. [The config envelope](#3-the-config-envelope)
4. [★ The Business-Responsibility Convention](#4--the-business-responsibility-convention)
5. [Authoring `generate`](#5-authoring-generate)
6. [Authoring `validate`](#6-authoring-validate)
7. [Authoring `meetsRequirements`](#7-authoring-meetsrequirements)
8. [`saveData`: passing state between steps](#8-savedata-passing-state-between-steps)
9. [Robustness rulebook (sandbox + validator)](#9-robustness-rulebook-sandbox--validator)
10. [The helper library](#10-the-helper-library)
11. [AI-readability checklist](#11-ai-readability-checklist)
12. [How a config is run (for testing)](#12-how-a-config-is-run-for-testing)
13. [Common gotchas](#13-common-gotchas)

---

## 1. What you are authoring

A `MockPlaygroundConfig` is **one ONDC transaction flow, modelled as an ordered list of API
calls**. Each entry in `steps[]` represents exactly one message that a participant sends in a
real transaction — a buyer app (`BAP`) sending `search`, a seller app (`BPP`) replying with
`on_search`, and so on.

```
buyer (BAP)            seller (BPP)
   │  search  ─────────────▶ │
   │ ◀───────────── on_search│
   │  select  ─────────────▶ │
   │ ◀───────────── on_select│
   │  init    ─────────────▶ │
   │ ◀──────────────── on_init│
   │  confirm ─────────────▶ │
   │ ◀───────────── on_confirm│
```

Each step carries three small JavaScript functions that encode that message's behaviour:

| Function            | Business question it answers                                             |
| ------------------- | ------------------------------------------------------------------------ |
| `meetsRequirements` | "Are the preconditions for sending/handling this message satisfied yet?" |
| `generate`          | "What payload does this participant put on the wire for this message?"   |
| `validate`          | "Is an incoming payload for this message correct given what we expect?"  |

The config also carries **state plumbing** (`saveData`) that lets a value produced in one step
flow into later steps — exactly mirroring how a real transaction threads a `transaction_id`,
provider id, order id, quote, etc. through its messages.

The whole point: a well-authored config is a **faithful, self-documenting executable spec** of a
transaction. If you follow the conventions in §4, anyone (or any model) can read it top-to-bottom
and explain the flow's business meaning.

---

## 2. The execution model

You are writing code that runs inside a **sandboxed worker**, one function at a time, driven by a
runner. Here is exactly what happens for a step, in order:

### 2.1 Per-step lifecycle

1. **`meetsRequirements(sessionData)`** — a precondition gate. Runs first. If it returns
   `valid: false`, the step is not ready (e.g. "you cannot `select` before `on_search` returned a
   catalog").
2. **`generate(defaultPayload, sessionData)`** — builds the outgoing payload. It receives a
   `defaultPayload` whose **`context` is already filled in for you** (see §2.3) and returns the
   final payload object to put on the wire.
3. **`validate(targetPayload, sessionData)`** — checks an _incoming_ payload (e.g. when the
   counterparty's response arrives) against business expectations. Returns
   `{ valid, code, description }`.
4. **`saveData`** — after a step's payload exists in history, its `saveData` JSONPath map extracts
   values and writes them onto `sessionData` for every later step (see §8).

`generate`, `validate`, and `meetsRequirements` are independent — the runner invokes whichever one
it needs. They never call each other.

### 2.2 How `sessionData` is built

Before any function runs, the runner assembles `sessionData` **cumulatively from all prior
steps**: it walks the `transaction_history` for every step _before_ the current one, applies that
step's `saveData` map to the recorded payload, and merges the results.

So `sessionData` for step _N_ contains everything saved by steps _0 … N-1_. Two extra inputs are
merged on top at call time:

- **`sessionData.user_inputs`** — the per-call `inputs` object (form values, a chosen city, etc.).
  Stored as a **plain object**, exactly as passed.
- **caller-supplied extra data** — shallow-merged onto `sessionData` (used for things like a
  service base URL). Also stored as-is.

> **Critical shape rule.** Values that come from a `saveData` JSONPath are extracted with a
> JSONPath query, which **always returns an array of matches**. A single-node path therefore lands
> as a **length-1 array**, not a scalar:
>
> | `saveData` entry                                   | `sessionData` value                       |
> | -------------------------------------------------- | ----------------------------------------- |
> | `transactionId: "$.context.transaction_id"`        | `["txn-123"]` ← read as `...[0]`          |
> | `providerIds: "$.message.catalog.providers[*].id"` | `["P1","P2","P3"]` ← already a list       |
> | `customValue: "EVAL#<base64>"`                     | whatever the extractor returned (no wrap) |
> | `user_inputs` / caller extras                      | the object/value as-is (no wrap)          |
>
> When a path matches nothing, the value is set to `null`. **Always read defensively** — see §5
> and §9.

### 2.3 `context` is generated for you — do not hand-write it

Before `generate` runs, the runner builds the message `context` and assigns it to
`defaultPayload.context`. You generally only author `defaultPayload.message`. The generated
context is **version-aware**, derived from `meta.version`:

- **v1.x** (major version `1`): flat fields — `country: "IND"`, `city`, `core_version`.
- **v2.x+**: nested — `version`, `location.country.code`, `location.city.code`.

It also fills `domain`, `action`, `timestamp`, `transaction_id`, `message_id`, `bap_id`,
`bap_uri`, and (for non-`search` actions) `bpp_id` / `bpp_uri`, plus `ttl: "PT30S"`.

The `message_id` honours **`responseFor`**: a response step (e.g. `on_select`) whose `responseFor`
points at its request step (`select`) reuses that request's `message_id`, so the request/response
pair correlates — just like real ONDC traffic. The ids (`bap_id`, `transaction_id`, …) are pulled
from `sessionData` first, then `transaction_history`, then `transaction_data`.

**Takeaway for authors:** don't synthesize `context.transaction_id`, `message_id`, or city codes
in `generate` unless you have a specific reason. Read or override them, but the defaults are
already correct. If you do need to set the city from a user input, use the `setCityFromInputs`
helper (§10) so you stay version-correct.

---

## 3. The config envelope

The top-level shape:

```ts
{
  meta:                { domain, version, flowId, config_version?, description?, use_case_id?, flowName? },
  transaction_data:    { transaction_id, latest_timestamp, bap_id?, bap_uri?, bpp_id?, bpp_uri?, external_session_data? },
  steps:               PlaygroundActionStep[],
  extra_steps?:        { steps: PlaygroundActionStep[] },
  transaction_history: TransactionHistoryItem[],
  validationLib:       string,   // present in schema; NOT injected at runtime — leave ""
  helperLib:           string,   // base64; prepended to every generate (see §10)
}
```

### 3.1 `meta`

| Field         | Required | Notes                                                                 |
| ------------- | -------- | --------------------------------------------------------------------- |
| `domain`      | yes      | e.g. `"ONDC:RET11"`. Goes into every `context.domain`.                |
| `version`     | yes      | e.g. `"1.2.0"` or `"2.0.0"`. **Drives the context shape** (v1 vs v2). |
| `flowId`      | yes      | Unique id for this flow.                                              |
| `description` | no       | One-line human/AI summary of the whole flow.                          |
| `use_case_id` | no       | Free-form tag.                                                        |
| `flowName`    | no       | Display name.                                                         |

### 3.2 `transaction_data`

Seed identity for the transaction: `transaction_id` and `latest_timestamp` are required; the
`bap_*` / `bpp_*` ids and uris are the fallbacks used when building `context` if nothing is found
in session/history. `external_session_data` is a free-form bag (e.g. service base URLs) some
helpers read.

### 3.3 `steps[]` — the `PlaygroundActionStep`

```ts
{
  api:          string,        // the ONDC action: "search", "on_search", "select", … or a form api
  action_id:    string,        // unique id within the flow; how you reference this step
  owner:        "BAP" | "BPP", // who sends this message
  responseFor:  string | null, // for a response step, the action_id of the request it answers
  unsolicited:  boolean,       // true if sent without a paired request
  description:  string,        // ← one-line business purpose (see §4)
  repeatCount?: number | null, // ≥ 1; how many times this step repeats in the flow
  mock: {
    generate:       string,                  // base64 of a complete `generate` function
    validate:       string,                  // base64 of a complete `validate` function
    requirements:   string,                  // base64 of a complete `meetsRequirements` function
    defaultPayload: object,                  // starting payload; .context is overwritten at runtime
    saveData:       Record<string,string>,   // JSONPath map (supports APPEND# / EVAL#) — see §8
    inputs:         object,                  // input schema for this step (see §3.4)
    formHtml?:      string,                  // base64 HTML, only for form steps
  },
  examples?: Array<{ name, description?, payload, type: "request" | "response" }>,
  // ↑ you do NOT author this — it is auto-generated by running the config (see §4.2)
}
```

Authoring notes:

- **`action_id`** is your handle for the step and the key for pairing/saving. Make it descriptive
  and unique (`search_0`, `on_search_0`). An `action_id` that contains `#` resolves by its **last**
  `#`-separated segment at runtime (so `GENERATED#1#search_0` → `search_0`); this lets a repeated
  step reuse one definition.
- **`owner`** records who puts the message on the wire. Convention: actions starting with `on_` are
  `BPP` responses; the rest are `BAP` requests.
- **`responseFor`** wires a response back to its request so the `message_id` correlates (§2.3).
- The three functions are stored **base64-encoded** (§9.5).

### 3.4 `inputs`

Declares values a caller supplies for the step (and that surface as `sessionData.user_inputs`):

```json
{
    "id": "city_selection",
    "jsonSchema": {
        "type": "object",
        "properties": { "city_code": { "type": "string" } },
        "required": ["city_code"]
    },
    "sampleData": { "city_code": "std:080" }
}
```

`id` is required once `inputs` is non-empty; `jsonSchema` is required when `id` is set; `sampleData`
is optional example values. Deployment-time validation enforces the first two. A step with no
inputs uses an empty object (`{}`).

---

## 4. ★ The Business-Responsibility Convention

This is the convention that makes a config legible. The mechanics above let a config _run_; the
rules below make it _explain itself_ — so a reviewer, a teammate, or an AI can map every mock
function to the real-world responsibility it represents and even generate documentation from it.

### 4.1 The intent header

**Put a structured header comment at the top of every `generate`, `validate`, and
`meetsRequirements` body.** It states, in business terms, what this function is responsible for.

```
/**
 * STEP <action_id> — <one-line business purpose>
 * ROLE     : BAP|BPP acting as <buyer app | seller app | logistics provider | …>
 * TRIGGER  : <the real-world event that causes this message>
 * READS    : sessionData.<key> — <why it is needed>        (upstream dependencies)
 * PRODUCES : saveData.<key> — <which later step consumes it> (for generate/save steps)
 * ON FAIL  : <what a non-200 / valid:false means in business terms> (validate/meetsRequirements)
 */
```

Include only the lines that apply to the function kind (`PRODUCES` is meaningful where the step
saves data; `ON FAIL` is for `validate` / `meetsRequirements`). Example on a `select` generate:

```js
async function generate(defaultPayload, sessionData) {
    /**
     * STEP select_0 — Buyer adds a chosen item to the cart and asks for a quote.
     * ROLE     : BAP acting as the buyer app.
     * TRIGGER  : Shopper picked a provider+item from the on_search catalog.
     * READS    : sessionData.providerId  — the provider chosen from on_search.
     *            sessionData.itemId       — the item chosen from on_search.
     *            sessionData.user_inputs.quantity — how many units the shopper wants.
     * PRODUCES : (this is a request; its quote echoes back in on_select_0)
     */
    const providerId = sessionData.providerId?.[0];
    const itemId = sessionData.itemId?.[0];
    if (!providerId || !itemId) {
        throw new Error(
            "select_0 requires providerId and itemId from on_search_0",
        );
    }
    defaultPayload.message = {
        order: {
            provider: { id: providerId },
            items: [
                {
                    id: itemId,
                    quantity: { count: sessionData.user_inputs?.quantity || 1 },
                },
            ],
        },
    };
    return defaultPayload;
}
```

### 4.2 Companion rules that make the whole config self-describing

The intent header documents _behaviour_; these rules document _structure_:

- **`step.description` = the one-line business purpose.** Mirror line 1 of the intent header. This
  is the cheapest, highest-leverage piece of documentation — set it on every step.
- **Name `saveData` keys for business meaning, never for JSONPath shape.** The key _is_ the
  documentation of what flows downstream. Prefer `providerId`, `quotedPrice`, `orderId` over
  `value1`, `data`, `x`. A reader should understand the data dependency graph from the key names
  alone.
- **`examples[]` is auto-generated — you do not author it.** Running the config produces the
  canonical request/response payloads and records them on the step as
  `{ name, description?, payload, type: "request" | "response" }`. That is exactly why the two
  rules above matter: the auto-generated examples are only as legible as the `description` and the
  `saveData` key names you wrote. Author those well, run the config, and the examples fill in a
  concrete I/O contract an AI can reason about — without you hand-writing any payloads.

### 4.3 Why this matters

When every step has a description, every function has an intent header, every `saveData` key names
a business concept, and key steps carry examples, the config becomes a **narratable artifact**: a
model can walk `steps[]` in order and produce "the buyer searches → the seller returns a catalog →
the buyer selects item X → …" — including the data dependencies — purely from the config text. That
is the bar to author to.

---

## 5. Authoring `generate`

**Signature & return:** `async function generate(defaultPayload, sessionData)` returning the
**payload object** to send. It must be a complete declaration named exactly `generate`.

`defaultPayload` arrives with `context` already populated (§2.3). Your job is usually to fill in
`defaultPayload.message` from `sessionData` and inputs, then return the payload.

```js
async function generate(defaultPayload, sessionData) {
    /**
     * STEP search_0 — Buyer searches the catalog.
     * ROLE    : BAP acting as the buyer app.
     * TRIGGER : Shopper opened the app and ran a search.
     * READS   : sessionData.user_inputs.city_code — the locality to search in.
     */
    // city_code is version-aware; let the helper write the right context field.
    setCityFromInputs(defaultPayload, sessionData.user_inputs);

    defaultPayload.message = {
        intent: {
            category: { descriptor: { name: "Electronics" } },
            fulfillment: { type: "Delivery" },
        },
    };
    return defaultPayload;
}
```

Rules and good practice:

- **Mutate and return `defaultPayload`.** Keep the generated `context` intact unless you have a
  reason to override a field.
- **Read `sessionData` defensively.** Remember saveData values are arrays (§2.2): use
  `sessionData.providerId?.[0]`, not `sessionData.providerId`. Guard against `null`/missing and
  throw a clear error if a hard dependency is absent — a thrown error surfaces as a failed result
  with your message.
- **Use the default helpers** that are always in scope here (`uuidv4`, `generate6DigitId`,
  `currentTimestamp`, `isoDurToSec`, `setCityFromInputs`, …; see §10).
- **`async` + `await` everything.** If any helper returns a Promise (e.g. an HTTP-backed helper),
  `await` it before putting the result in the payload. Returning a payload that still contains an
  un-awaited Promise fails serialization (see §13, DataCloneError).
- **`user_inputs` is a plain object** (not array-wrapped). Access nested fields with optional
  chaining: `sessionData.user_inputs?.quantity`.

---

## 6. Authoring `validate`

**Signature & return:** `function validate(targetPayload, sessionData)` returning **exactly**
`{ valid: boolean, code: number, description: string }`. Named exactly `validate`. It is **pure** —
no `fetch`, no I/O.

`validate` checks an _incoming_ payload (typically the counterparty's response) against business
expectations and against what you already know from `sessionData`.

```js
function validate(targetPayload, sessionData) {
    /**
     * STEP on_search_0 — Seller returns a catalog of matching providers.
     * ROLE    : validating the BPP's response to search_0.
     * READS   : (none required)
     * ON FAIL : 400 → catalog is empty/malformed, the buyer has nothing to select.
     */
    const providers = targetPayload?.message?.catalog?.providers;
    if (!providers || providers.length === 0) {
        return {
            valid: false,
            code: 400,
            description: "No providers found in catalog",
        };
    }
    return {
        valid: true,
        code: 200,
        description: `Valid catalog with ${providers.length} providers`,
    };
}
```

Good practice:

- **Return all three keys, every branch.** The static validator warns if a returned object is
  missing `valid`, `code`, or `description`, or carries extra keys. Keep every `return` to that
  exact shape.
- **Make `code` and `description` meaningful.** They are business signals: `400` malformed, `404`
  expected entity missing, etc. Write a description a human can act on.
- **Cross-check against `sessionData`** where it matters — e.g. confirm an echoed `transaction_id`
  or `provider id` matches what an earlier step sent (`targetPayload.context.transaction_id ===
sessionData.transactionId?.[0]`). This is where you catch a counterparty that replied about the
  wrong order.
- **Read defensively** with optional chaining; an incoming payload may be anything.

---

## 7. Authoring `meetsRequirements`

**Signature & return:** `function meetsRequirements(sessionData)` returning **exactly**
`{ valid: boolean, code: number, description: string }`. Named exactly `meetsRequirements`. Pure.

This is the **precondition gate**: it answers "can this step legitimately run yet?" purely from the
accumulated `sessionData`.

```js
function meetsRequirements(sessionData) {
    /**
     * STEP select_0 — gate before the buyer can select.
     * READS   : sessionData.providerId, sessionData.itemId — produced by on_search_0.
     * ON FAIL : 428 → the catalog has not arrived; selection is not possible yet.
     */
    if (!sessionData.providerId?.[0] || !sessionData.itemId?.[0]) {
        return {
            valid: false,
            code: 428,
            description: "Search must complete before selection",
        };
    }
    return { valid: true, code: 200, description: "Ready to select items" };
}
```

Good practice:

- Assert the **specific upstream data** the step depends on (named for business meaning, so the
  gate reads like a requirement statement).
- Use a clear `code` for "not ready" (`428 Precondition Required` is a natural fit) and a
  description that names what is missing.
- Keep it cheap and pure — it runs on a tight 3s budget (§9.3).

---

## 8. `saveData`: passing state between steps

`saveData` is a map from a **business-named key** to a **JSONPath** applied to that step's recorded
payload. The extracted values land on `sessionData` for all later steps. This is how a real
transaction's identifiers and quotes thread through the flow.

`saveData` is plain JSON — a flat object of `"key": "value"` strings, **no comments and no
trailing commas**. Example (grouping explained below):

```json
{
    "transactionId": "$.context.transaction_id",
    "latestMessage_id": "$.context.message_id",
    "latestTimestamp": "$.context.timestamp",
    "bapId": "$.context.bap_id",
    "bppId": "$.context.bpp_id",
    "providerId": "$.message.catalog.providers[0].id",
    "itemId": "$.message.catalog.providers[0].items[0].id",
    "APPEND#allItems": "$.message.catalog.providers[*].items[*].id",
    "quotedPrice": "EVAL#<base64 of a getSave extractor>"
}
```

In that example the first five keys save the **context essentials** (so later steps and the
generated context can correlate); the rest save **business state produced by this step**.
`APPEND#allItems` concatenates matches into an array, and `quotedPrice` uses a custom extractor.

Mechanics:

- **Plain JSONPath** (`$.message…`): extracted with a query that **returns an array of matches**.
  Read single-node values as `sessionData.key[0]` downstream (§2.2). Unmatched → `null`.
- **`APPEND#<key>`**: concatenates this step's matches into the existing array under `<key>`
  instead of overwriting — use it to accumulate across repeated steps (e.g. every `on_search`'s
  provider ids).
- **`EVAL#<base64>`**: runs a sandboxed extractor `function getSave(payload) { … }` (base64-encoded
  after the `EVAL#`) and stores its **raw return value** (not array-wrapped). Use this when a value
  needs computation a JSONPath cannot express. The extractor obeys the same sandbox rules (§9) and
  a 3s timeout.
- **Form steps** (`api` of `dynamic_form` / `html_form`): the submitted payload is auto-saved under
  `sessionData.formData[action_id]`, and `sessionData[action_id]` is set to the submission id — you
  do not write `saveData` for these.

Naming reminder (§4.2): the key documents the dependency. `quotedPrice` tells a reader exactly what
a later step will consume; `q1` tells them nothing.

---

## 9. Robustness rulebook (sandbox + validator)

Your functions run in a locked-down VM sandbox and are statically checked before execution. Author
to these constraints so your code is accepted and behaves deterministically.

### 9.1 Structural requirements (static validator)

- Each function must be a **complete, top-level, named function declaration** matching its kind:
  `generate`, `validate`, `meetsRequirements`. A typo'd or missing name is rejected. (You provide a
  whole `function name(...) { … }`, not just a body.)
- `validate` and `meetsRequirements` must **return an object literal** with exactly
  `{ valid, code, description }`. Missing or extra keys produce warnings — keep the shape exact on
  every branch.
- No `with` statements; no obvious infinite loops (`while (true)`, `for (;;)`).

### 9.2 Forbidden APIs

These are rejected statically or absent at runtime:

| Category            | Not allowed                                                                                                              |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Code execution      | `eval`, `Function` (constructor or call)                                                                                 |
| Networking          | `XMLHttpRequest`, `WebSocket`, `Worker`, `SharedWorker`, `importScripts`                                                 |
| Storage             | `localStorage`, `sessionStorage`, `indexedDB`, `webkitStorageInfo`                                                       |
| Prototype tampering | `__proto__`                                                                                                              |
| Node internals      | `require`, `process`, `Buffer`, `module`, `exports`, `__dirname`, `__filename`, `global`, `globalThis` (all `undefined`) |

`fetch` is a special case — see §9.4.

### 9.3 Allowed globals & timeouts

In scope in every function: `Array, Boolean, Date, Error, JSON, Math, Number, Object, Promise,
RegExp, String, Symbol, Map, Set, WeakMap, WeakSet, parseInt, parseFloat, isNaN, isFinite,
encodeURI, encodeURIComponent, decodeURI, decodeURIComponent, setTimeout, clearTimeout,
AbortController, AbortSignal`, and a capturing `console` (`log` / `error` / `warn` / `info`).

`setTimeout` delay is clamped to **1–45000 ms**. Per-kind execution budgets:

| Function            | Timeout |
| ------------------- | ------- |
| `generate`          | 45 s    |
| `validate`          | 5 s     |
| `meetsRequirements` | 3 s     |
| `getSave` (EVAL#)   | 3 s     |

### 9.4 `fetch` (only in `generate`, only allowlisted)

Outbound HTTP is opt-in and scoped:

- Only `generate` ever gets `fetch` (plus `URL`, `URLSearchParams`, `Headers`, `Request`,
  `Response`). `validate`, `meetsRequirements`, and `getSave` are always pure — calling `fetch`
  there throws `fetch is not defined`.
- `fetch` is injected only when the host service has configured an allowlist of base URLs. A
  request must match an allowed entry's origin **and** be a path-segment prefix of it (`/v1` allows
  `/v1` and `/v1/foo` but not `/v10/foo`). Non-allowlisted requests throw
  `fetch blocked: … is not in the configured allowlist`.
- Redirects are blocked (`redirect: "error"`) — call final URLs.
- Pair `fetch` with `AbortController` for a per-request timeout (the helper `generateConsentHandler`
  in §10 shows the pattern). Remember the 45s `generate` budget bounds everything.

### 9.5 Determinism & encoding

- Randomness/time helpers (`uuidv4`, `Math.random`, `Date`) are fine; avoid relying on hidden
  external state so runs are reproducible.
- Functions are stored **base64-encoded**. Encode a complete declaration; do not encode a bare
  body. (The codebase exposes `MockRunner.encodeBase64(src)` / `decodeBase64(b64)` for this; they
  use `TextEncoder`/`TextDecoder` so they work in Node and the browser.)

---

## 10. The helper library

Every `generate` is prefixed with the helper library (`helperLib`, base64) before it runs, so
these functions are **in scope inside `generate`** (not in `validate`/`meetsRequirements`). The
default set:

| Helper                                               | Purpose                                                                     |
| ---------------------------------------------------- | --------------------------------------------------------------------------- |
| `uuidv4()`                                           | RFC 4122 v4 UUID string.                                                    |
| `generate6DigitId()`                                 | 6-digit numeric string in `[100000, 999999]`.                               |
| `currentTimestamp()`                                 | ISO-8601 UTC timestamp.                                                     |
| `isoDurToSec(duration)`                              | ISO-8601 duration (e.g. `"PT1H30M"`) → seconds; `0` if unparseable.         |
| `setCityFromInputs(payload, inputs)`                 | Writes `inputs.city_code` into `payload.context`, version-aware (v1 vs v2). |
| `createFormURL(domain, formId, sessionData)`         | Builds a `/forms/<domain>/<formId>/?…` submission URL from session data.    |
| `getSubscriberUrl(sessionData, type)`                | `"bpp"` → `sessionData.bppUri`; anything else → `sessionData.bapUri`.       |
| `generateConsentHandler(sessionData, { custId, … })` | `async`; POSTs to an AA service (needs a base URL in session + allowlist).  |

Authoring rules for helpers (and for extending `helperLib`):

- **Pass `sessionData` explicitly** to any helper that needs request-scope data. Helpers run at
  script scope — a free-variable reference to `sessionData` does **not** resolve at runtime;
  `sessionData` exists only as a parameter of `generate`. That is why `getSubscriberUrl`,
  `createFormURL`, and `generateConsentHandler` all take it as a parameter.
- Prefer `function` declarations (they hoist, so helper-call order doesn't matter).
- No `require` / `import` inside helpers — only whitelisted globals and sibling helpers are
  available.
- Document each helper with a JSDoc block; the docs travel with the bundled source and reach
  readers unchanged.

---

## 11. AI-readability checklist

Run this before shipping a step. If all of these hold, a model can read your config and document
the flow without executing it:

- [ ] **`meta.description`** summarizes the whole flow in one line.
- [ ] Every step has a **`description`** = its one-line business purpose.
- [ ] Every `generate` / `validate` / `meetsRequirements` body opens with an **intent header**
      (§4.1) naming ROLE / TRIGGER / READS / PRODUCES / ON FAIL as applicable.
- [ ] Every `saveData` key is **named for business meaning**, not JSONPath shape.
- [ ] `responseFor` is set on every response step so request/response pairs are explicit.
- [ ] Run the config so **`examples[]`** auto-populates with real request/response payloads (you
      do not hand-write these — §4.2).
- [ ] `validate` / `meetsRequirements` return the exact `{ valid, code, description }` shape on
      every branch, with meaningful codes and descriptions.
- [ ] `generate` reads `sessionData` defensively (array-aware, `?.`), `await`s async helpers, and
      throws clear errors on missing hard dependencies.
- [ ] No forbidden APIs (§9.2); `fetch` only in `generate` and only against the allowlist.

---

## 12. How a config is run (for testing)

You author the config; a runner executes one function at a time. The entry points you exercise
while testing your config:

| Call                                                       | Runs                                                  |
| ---------------------------------------------------------- | ----------------------------------------------------- |
| `runGeneratePayload(actionId, inputs?, extraSessionData?)` | builds `sessionData` from history, then `generate`.   |
| `runValidatePayload(actionId, targetPayload, extra?)`      | builds `sessionData`, then `validate(targetPayload)`. |
| `runMeetRequirements(actionId)`                            | builds `sessionData`, then `meetsRequirements`.       |
| `*WithSession(actionId, …, sessionData)` variants          | skip history; use a `sessionData` you pass directly.  |

`actionId` resolves by its last `#`-segment (§3.3), so `GENERATED#1#search_0` targets `search_0`.
Every call returns a result object with `success`, the function's `result`, captured `logs`,
`executionTime`, and an `error` (with `name` + `message`) when something failed. Use the `logs`
(your `console.*` output is captured) and `error.message` (your thrown messages) to debug.

`getDefaultStep(api, actionId, formType?)` produces a scaffolded step with template functions
already encoded — a useful starting point for a new step.

---

## 13. Common gotchas

- **`DataCloneError: #<Promise> could not be cloned`** — `generate` returned a payload that still
  contains an un-awaited Promise. Make `generate` `async` and `await` every async helper before
  putting its result in the payload. Nested Promises are not auto-flattened.
- **`fetch is not defined`** — you called `fetch` from `validate`, `meetsRequirements`, or a
  `getSave` extractor. Only `generate` gets `fetch`, and only when an allowlist is configured.
- **`fetch blocked: <url> is not in the configured allowlist`** — the host service did not
  allowlist that origin+path. Call an allowlisted URL.
- **Validator warning "Return object is missing/has unexpected property …"** — your `validate` /
  `meetsRequirements` returned something other than exactly `{ valid, code, description }` on some
  branch. Fix every `return`.
- **`Expected a top-level function declaration named '…'`** — the function name doesn't match the
  kind, or you wrapped it / encoded only a body. Provide a complete `function generate(...) {…}`
  (etc.).
- **A `sessionData` value is an array when you expected a scalar** — saveData JSONPath results are
  always arrays. Read `sessionData.key[0]` for single values; `user_inputs` and caller extras are
  the exceptions (stored as-is).
- **A `sessionData` value is `null`** — its JSONPath matched nothing in the prior payload. Guard
  before use and surface a clear error in `meetsRequirements` / `generate`.
