# Front 04 — js

**Priority:** medium — commonJS is the default target and nearly done: one dead site, one template
marker, one binding shape and two measurements are what is left.
**Depends on:** `00-gate` (nothing of this front's files is a gate item) · `01-checker` step 5
(decision 152: 01c-d answered (a), so step 4 is a cell only) and step 6 (the `throw`-in-arm typed
AST) · the checker refusing `@block`'s tail form (step 1) · decisions 164 (0405-c, step 2) and 179
(24-h, step 5) · 0405-b to confirm (landed).
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
| step 8 | `@block { 1 + 2 }` | `(() => {(1 + 2);})()` — prints `null`; the checker still accepts the tail form (step 1's measurement) |
| `$stringify` | `#[@External.Node("$stringify($0)")] declare fn f(x: i32) -> string;` | `PrimOpStringifyUnsupported` (`comptime/primOpTemplate.zig`, the commonJS ctx); erlang accepts the same template |
| row 34 | `var n: i32 = 1; n = n + 1; var n: i32 = 10;` | `SyntaxError: Identifier 'n' has already been declared` (erlang answers `10`) |
| C-18 | every emitted `.d.ts` | `scripts/tsc-check.sh` (gate stage 11) holds it — step 3 |
| C-18 | `42.toString()` | `run/number_method_call` pins it — step 3 |

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

**Measured** (recorded in `src/codegen/js/AGENTS.md` § The IIFE build sites): the site has
producers. One fixture writes it (`js: block ---- @block builtin`, snapshot
`block_block_builtin`), no `.bp` in the checkout does, and three shapes check:
`val a = @block { return 3; }` → `3` (every path returns — C1, a value); `@block { … };` in
statement position → runs (the IIFE scopes the block's `return`s); `val a = @block { 1 + 2 };` →
`null` — `comptime/infer.zig` `inferBuiltinCallReturnType` types a block by its tail expression,
which decision 2 refuses. The first two keep the IIFE genuine; the third is the dead lowering,
and its producer is the checker's. The site stays until the checker refuses the tail form; then
nothing here moves (the IIFE serves the other two).

**Acceptance:**
- [x] the producers measured and written in `js/AGENTS.md`
- [ ] `@block { 1 + 2 }` refused by the checker (01's file) — the tail-form lowering then has no producer

### Step 2 — `$stringify` in an `@External.Node` template (0405-c)

Decision 164 (0405-c answered (a)): a user template writing `$stringify` is a located diagnostic at
the template naming the marker, on every target; the documented markers are `$self`, `$N`, `$args`.

**Measured.** No one-arm edit in `primOpTemplate.zig` gives that refusal: `render` runs at codegen,
per backend, after `botopink check` has passed, with no location (commonJS answers the bare
`PrimOpStringifyUnsupported`, erlang and beam print `42`), and it cannot tell a user template from
std's own — `primitives.bp`'s `Array.join` Erlang template writes `$stringify(__E)` and must keep
working. The located refusals of a template marker live in the parser
(`parser/template_markers.zig` refuses `$self` and an out-of-range `$N` as
`template-self-marker` / `template-marker-out-of-range`, `parser.zig` `ParseErrorType`,
`print.zig`'s message), which is `parser/**` — 01's, owned by the running checker thread.
**Options.** (a) 01 adds a third kind there (`template-stringify-marker`) with an exemption for the
embedded prelude's parse (a parser flag the prelude parse sites set), and this front adds the
`reject/` cell; (b) the std track rewrites `Array.join`'s Erlang template without the marker, and the
refusal has no exemption at all. **Recommendation.** (b) then (a) without the flag — the most
restrictive: one rule for every template, std's included; the marker then has no user left and
`primOpTemplate.zig`'s arm can go with it.

**Acceptance:**
- [ ] `reject/external_template_stringify_marker` — refused at the template, naming the marker, on every target

### Step 3 — `tsc --noEmit` as a script, and `42.toString()` pinned

`scripts/tsc-check.sh` runs `tsc --noEmit --strict --lib es2022 --module commonjs` over every
non-empty `.d.ts` the suite emits (from a scratch build of `examples/**` and the `modules/` cells),
through `npx -p typescript`, and refuses when `npx` is absent (no silent skip — decision 67; the
gate's dependency list gains `node` with `npx`, which `node` ships). Called from `scripts/gate.sh`
as a stage (25's file, one line).

`scripts/tsc-check.sh` builds every project under `examples/` and every `tests/language/modules`
cell that runs on commonJS (a `commonJS.expect` or a `"targets"` list without commonJS is the only
exclusion) with `--typescript`, and runs `tsc` 7.0.2 (pinned, through `npx`) over each build's
non-empty `.d.ts`; it is gate stage 11 and a step of CI's `test` job. Three typedef defects it
found are fixed in `typescript.zig` (type-only imports, inferred generic names, enum sections —
`src/codegen/AGENTS.md`, the `typescript.zig` row).

**Acceptance:**
- [x] `scripts/tsc-check.sh` green on the tree (62 projects); a planted `.d.ts` defect (`array<number>`) reds it
- [x] `run/number_method_call` — `@print(42.toString())` prints `42` on four targets

### Step 4 — the redeclared binding (row 34, after 01c-d)

Decision 152 answered (a): nothing lowers here — 01 refuses the program; this front's cell pins
that a shadowing `val` in an inner block still emits a scoped `const`.

**Measured.** commonJS emits the scoped `const` and prints the inner and the outer value; the other
three do not: erlang's `erlc` refuses the module (`variable 'N@1' unsafe in 'case'`, `variable
'Label@1' is unbound`), beam fails the assembler's consistency check (`{unassigned,{y,2}}`), and
wasm prints the inner value where the outer one is read (`inner inner`, `pick(true)` answers `2`).
The program: `val n = 1; if (flag) { val n = 2; @print(n); } return n;` and a `for` body
shadowing an outer `val label`. A four-target cell is red on three backends that are 02's, 03's
and 05's, so it is not added here; 01's step 5 names the same cell.

**Acceptance:**
- [ ] `run/inner_block_shadowing` prints the inner and outer values on four targets (after 02, 03, 05 lower it)

### Step 5 — `unwrapOrThrow` (24-h, a decision)

Per 24-h's answer: (a) nothing ships — `CHANGELOG.md`'s sentence stands; (b) a std function (the
std track's); (c) a runtime prelude helper (this front's, `js/**`).

Decision 179 answered (a): nothing ships; a JavaScript caller reads the tagged value.

**Acceptance:**
- [x] the answer's id recorded in `src/codegen/js/AGENTS.md` (§ What the prelude does not ship)

### Step 6 — the `throw`-in-arm lowering (after 01 step 6)

Once the typed AST marks a `throw` in a `case` arm as the enclosing function's, this backend emits
`return {Error: e}` from the arm (not the arm's value). Verified by 01's cell
`run/throw_in_case_arm_result`; this front re-records the fixture it touches.

**Acceptance:**
- [ ] `run/throw_in_case_arm_result` green on commonJS; `isError()` true on the throw path

### Step 7 — a `default fn` body lowered without the checker (from 02-std-and-packaging/97)

The checker does not type a behavior's `default fn` body, so commonJS lowers it with no per-call
answer from inference. Two things are known without one, and the backend reads them
(`src/codegen/AGENTS.md` § A `default fn` body is lowered untyped): in a prototype patch of a
primitive behavior `self` is that primitive, so a call on `self` lowers as on a typed receiver
(`self.length()` is the property, `self.at(0)` the prelude helper); and a bare `Ok(v)` /
`Error(e)` is the `{ ok }` / `{ error }` object, as erlang and beam build their tuple. A call on any
other receiver of such a body stays untyped — 02's C-35 (the typing of these bodies on every
backend).

**Acceptance:**
- [x] `js: primitive behavior default fn ---- a call on self lowers as on the declared receiver` and `---- Ok(v) and Error(e) build the @Result` (`codegen/tests/commonjs.zig`) green; red before
- [x] `Array.first` / `Array.unique` answer `null` past the end (12 commonJS snapshots × 2 runtimes re-recorded, every moved line checked by script)

## Gate

- [x] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] every re-recorded RUN LOG **verified by running the program** under `node`, checked against decision 8 §7
- [ ] every emitted module passes `node --check`; `scripts/tsc-check.sh` green (the script is green; `node --check` not measured)
- [ ] `zig build test-libs` commonJS cells at baseline (jhonstart, emilia, onze, erika)
- [x] `src/codegen/AGENTS.md` and `src/codegen/js/AGENTS.md` in the same commit as each step
- [ ] Commit on `fix/04-js`; no push, no merge

## Blast radius

Step 1 moves nothing (byte-identical is the acceptance). Step 2 (a) reds any library template
writing `$stringify` — measured: none in the libraries; std's `primitives.bp` writes it once
(`Array.join`'s Erlang template, step 2's Options). Step 4 (b) would move every
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
