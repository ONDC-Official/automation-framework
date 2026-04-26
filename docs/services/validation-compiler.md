# automation-validation-compiler

## Overview

`automation-validation-compiler` is a shared npm package (`ondc-code-generator`) that **generates TypeScript and Go source code from a compiled ONDC spec (`build.yaml`)**. It is a pure code-generation library — it takes structured YAML as input and emits production-ready validator source files. This enables the "spec-as-code" principle: adding a new ONDC domain requires only new YAML, and the enforcement logic is machine-generated without manual coding.

## Role in the Architecture

This is a **build-time library** consumed exclusively during the code generation pipeline:

```
build.yaml  →  ondc-code-generator  →  TS L1 validators + JSON Schemas + Go validationpkg/
```

It is used by:
- `automation-api-service-generator` — calls `ConfigCompiler` to generate the full API service output.
- `@ondc/build-tools` — uses it during `ondc-tools validate` and `make-onix` commands.

Generated artifacts (not edited by hand):
- `generated/action-selector/` — TypeScript files that pick the correct YAML variant per condition
- `generated/default-selector/` — TypeScript files for default payload selection
- `generated/L2-validations/` — TypeScript L2 domain-specific business rule validators
- `validationpkg/` (inside the generated ONIX server) — Go package with `PerformL1validations()` function

## npm Package Name

`ondc-code-generator` — version `0.0.1` (Note: npm name is not `@ondc`-scoped)

## Tech Stack

- Language: TypeScript → compiled to `dist/`
- Runtime: Node.js ≥ 18

## Key Modules

| Module | Path | What it does |
|---|---|---|
| `index.ts` | `src/index.ts` | Exports `ConfigCompiler` class and public generation API |
| `services/` | `src/services/` | Orchestration layer — coordinates generator calls and file output |
| `generator/config-compiler.ts` | `src/generator/config-compiler.ts` | Main compiler class: parses `build.yaml`, dispatches to sub-generators |
| `generator/generators/` | `src/generator/generators/` | Per-output generators: L0 schema, L1 TS validators, Go `validationpkg`, action selectors |
| `generator/validators/` | `src/generator/validators/` | Validates `build.yaml` structure before code generation begins |
| `constants/` | `src/constants/` | Shared constants: ONDC action names, reserved keys, schema field mappings |
| `types/` | `src/types/` | TypeScript interfaces for `build.yaml` schema, generator input/output contracts |
| `utils/` | `src/utils/` | Template rendering helpers, file write utilities, path resolution |

## External Dependencies

| Package | Purpose |
|---|---|
| `mustache` | Template engine — renders `.mustache` templates for Go and TypeScript output files |
| `js-yaml` | Parses `build.yaml` (YAML input) into JavaScript objects |
| `@apidevtools/json-schema-ref-parser` | Resolves `$ref` pointers in JSON schemas before embedding in generated code |
| `jsonpath` | Extracts nested values from `build.yaml` for conditional logic generation |
| `json-schema` | JSON Schema utilities used when generating L0 validator files |
| `chevrotain` | Parser toolkit — used to parse custom expression syntax in `x-validations` rules |
| `marked` | Converts markdown doc strings from YAML to HTML/JSDoc in generated code |
| `prettier` | Auto-formats generated TypeScript output to match project code style |
| `winston` | Internal logging during code generation runs |
| `chalk` | Colorizes CLI output during generation (success/warning/error) |
| `fs-extra` | Enhanced `fs` — recursive directory creation, JSON write, copy operations |
| `json-to-yaml-ref` | Converts generated JSON Schema back to YAML-with-$ref for compact output |

## Internal Dependencies

None — this is a leaf package with no workspace dependencies.

## How to Build

```bash
cd automation-validation-compiler
npm install
npm run build   # tsc → dist/

# Development with file watch
npm run dev     # nodemon (restarts on src/ changes)
```

## How to Use (as a library)

```typescript
import { ConfigCompiler } from "ondc-code-generator";

const compiler = new ConfigCompiler(buildYaml);
compiler.generateCode(xValidations, "L1-validations");  // → TypeScript L1 validators
compiler.generateL0Schema();                             // → JSON Schemas per action
compiler.createOnixServer(outputDir);                    // → Go validationpkg/
```

## Notes for Open Source

- All output files are **deterministic** — running the generator twice on the same input produces identical output. This makes generated files safe to commit and diff.
- The `chevrotain`-based parser handles `x-validations` rule expressions like `$.context.domain == "ONDC:TRV11"` — these are NOT evaluated with `eval()`.
- `mustache` templates for Go code live in `src/generator/generators/` as `.mustache` files — these are the primary customization points if you want to change the shape of generated Go code.
