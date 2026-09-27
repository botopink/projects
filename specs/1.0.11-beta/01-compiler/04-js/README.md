# Front 04 — js

**Priority:** medium — commonJS is the default target and nearly done: one dead site, one template
marker, one binding shape and two measurements are what is left.
**Depends on:** `00-gate` (nothing of this front's files is a gate item) · `01-checker` step 5
(01c-d decides whether step 4 exists) and step 6 (the `throw`-in-arm typed AST) · maintainer
decisions 0405-c (step 2), 24-h (step 5, a decision only) · 0405-b to confirm (landed).
**Owns:** `modules/compiler-core/src/codegen/commonJS.zig` · `src/codegen/typescript.zig` ·
`src/codegen/js/**` · the commonJS snapshots under `snapshots/codegen/<runtime>/commonJS/**` and
`snapshots/codegen/<runtime>/errors/commonJS/**` (each carrying the TypeScript typedef of the same
program — there is no `typescript/` directory) · its fixtures in a per-backend test file
(`codegen/tests/commonjs.zig`, created if absent) · `scripts/tsc-check.sh` (step 3, new) · the cells
its steps add
**Does not touch:** `src/comptime/**`, `src/parser/**` (01, 14, 18) · `erlang.zig`, `crossModule.zig`,
`beam/{erl_ast,erl_emitter}.zig` (02) · `beam_asm.zig`, `beam/**` (03) · `wat.zig`, `wat/**` (05) ·
`modules/compiler-cli/**` (26) · `libs/std/**` (the std track) · `scripts/gate.sh` (25 — step 3's
script is called from it by a one-line carve-out named in the commit)

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| the one `@block` IIFE site | `04-js/README.md` · `00/README.md` | § Step 8 · § C-09, R7's box |
| `$stringify` in a Node template | `15-language-surface/surface-gaps.md` | § Still open, last row |
| `tsc --noEmit` as a gate; `42.toString()` | `00/README.md` | § C-18, last box |
| the redeclared binding lowered twice | `language-gaps.md` | row 34 (the commonJS half) |
| `unwrapOrThrow` | `24-effects-by-return/README.md` | § Open, "The JS interop helper" |

## Problem

| Row | Program | commonJS answers |
|---|---|---|
| step 8 | `@block { 1 + 2 }` | `(() => {(1 + 2);})()` — prints `null`; decision 2 (01's R7) now refuses the value form, so the site has no producer to count |
| `$stringify` | `#[@External.Node("$stringify($0)")] declare fn f(x: i32) -> string;` | `PrimOpStringifyUnsupported` (`comptime/primOpTemplate.zig`, the commonJS ctx); erlang accepts the same template |
| row 34 | `var n: i32 = 1; n = n + 1; var n: i32 = 10;` | `SyntaxError: Identifier 'n' has already been declared` (erlang answers `10`) |
| C-18 | every emitted `.d.ts` | passes `tsc --noEmit --strict --lib es2022 --module commonjs` when run by hand through `npx -p typescript`; nothing in the tree runs it |
| C-18 | `42.toString()` | prints `42` (verified by the audit) — no script pins it |

## Current state

Every 1.0.10 step but 8 is delivered; the 1.0.10 status rows for commonJS (a multi-subject
`case`, an enum implementing a behavior, an imported fn as a value) closed with their cells
(`run/case_multi_subject_patterns`, `run/enum_implements_behavior`, `modules/imported_fn_as_value`
pass on `--target all`). Measured at the open.

## Mechanism

| Row | Deciding site | What it decides |
|---|---|---|
| step 8 | `commonJS.zig`'s `@block` arm builds an IIFE for a block in value position (classified in `src/codegen/js/AGENTS.md`; the other IIFE sites are genuine) | dead since 01's R7 |
| `$stringify` | `comptime/primOpTemplate.zig` expands the marker per backend ctx; the commonJS ctx has no `$stringify` arm (the marker serves the compiler's own primitive templates) | a user template reaching it is refused by kind |
| row 34 | `buildValDecl` emits `const` / `let` per binding by its written name; two bindings in one function body emit two declarations | a JS syntax error |

## Steps

### Step 1 — the dead `@block` IIFE site

Measure the producers over the commonJS snapshots (0 expected after 01's R7), delete the site;
the commonJS snapshots are otherwise byte-identical; `src/codegen/js/AGENTS.md` records the
deletion beside the classification of the IIFE sites that stay.

**Acceptance:**
- [ ] 0 producers written in `js/AGENTS.md`; the site deleted; `snapshots/codegen/*/commonJS/**` byte-identical

### Step 2 — `$stringify` in an `@External.Node` template (0405-c)

Per 0405-c's answer: (a) a user template writing `$stringify` is a located diagnostic at the
template naming the marker, on every target (the refusal is `primOpTemplate.zig`'s — 01's file by
directory; the row is this front's, the one-arm edit a named carve-out in the commit); (b) the
commonJS ctx lowers it as `__bp_show($0)`.

**Acceptance:**
- [ ] `reject/external_template_stringify_marker` ((a)) or `run/external_template_stringify` printing the same text on commonJS and erlang ((b))

### Step 3 — `tsc --noEmit` as a script, and `42.toString()` pinned

`scripts/tsc-check.sh` runs `tsc --noEmit --strict --lib es2022 --module commonjs` over every
non-empty `.d.ts` the suite emits (from a scratch build of `examples/**` and the `modules/` cells),
through `npx -p typescript`, and refuses when `npx` is absent (no silent skip — decision 67; the
gate's dependency list gains `node` with `npx`, which `node` ships). Called from `scripts/gate.sh`
as a stage (25's file, one line).

**Acceptance:**
- [ ] `scripts/tsc-check.sh` green on the tree; a planted `.d.ts` defect reds it
- [ ] `run/number_method_call` — `@print(42.toString())` prints `42` on four targets

### Step 4 — the redeclared binding (row 34, after 01c-d)

Under 01c-d (a) nothing lowers here — 01 refuses the program; this front's cell pins that a
shadowing `val` in an inner block still emits a scoped `const`. Under (b), a rebinding in one
body is a fresh JS binding (a renamed `const`, `n$1`), and `run/binding_rebound_in_body` prints `10`.

**Acceptance:**
- [ ] `run/inner_block_shadowing` prints the inner and outer values on four targets; under (b) the rebinding cell too

### Step 5 — `unwrapOrThrow` (24-h, a decision)

Per 24-h's answer: (a) nothing ships — `CHANGELOG.md`'s sentence stands; (b) a std function (the
std track's); (c) a runtime prelude helper (this front's, `js/**`).

**Acceptance:**
- [ ] the answer's id recorded in `src/codegen/js/AGENTS.md`; under (c) a fixture whose RUN LOG rejects

### Step 6 — the `throw`-in-arm lowering (after 01 step 6)

Once the typed AST marks a `throw` in a `case` arm as the enclosing function's, this backend emits
`return {Error: e}` from the arm (not the arm's value). Verified by 01's cell
`run/throw_in_case_arm_result`; this front re-records the fixture it touches.

**Acceptance:**
- [ ] `run/throw_in_case_arm_result` green on commonJS; `isError()` true on the throw path

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] every re-recorded RUN LOG **verified by running the program** under `node`, checked against decision 8 §7
- [ ] every emitted module passes `node --check`; `scripts/tsc-check.sh` green
- [ ] `zig build test-libs` commonJS cells at baseline (jhonstart, emilia, onze, erika)
- [ ] `src/codegen/AGENTS.md` and `src/codegen/js/AGENTS.md` in the same commit as each step
- [ ] Commit on `fix/04-js`; no push, no merge

## Blast radius

Step 1 moves nothing (byte-identical is the acceptance). Step 2 (a) reds any library template
writing `$stringify` — measured at the open: none (`grep -rn 'stringify(' repository/*/modules
--include=*.bp` finds only `json.stringify` calls, not the marker). Step 4 (b) would move every
commonJS snapshot with a rebinding — none exists in the suite. Step 6 moves the fixtures with a
`throw` in an arm (few).

## Notes

- **`typescript.zig` cannot be separated from `commonJS.zig`** for snapshot purposes: the typedef
  is a section of the commonJS snapshot.
- **This front moves only commonJS snapshots.** If a change here moves erlang, beam or wasm
  snapshots, something crossed a boundary — stop and report.
- The 1.0.10 README's step 5 last box (jhonstart's "always name the module" rule deletable) is the
  jhonstart track's; 09's pointer sweep notes it.
- `pattern-binding.md` moved to [`../03-beam/`](../03-beam/pattern-binding.md): its open half is
  beam's.
