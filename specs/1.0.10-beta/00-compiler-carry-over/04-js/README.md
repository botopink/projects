# Front 04 — js

**Priority:** high — commonJS is the default target, the one every `botopink new` project runs
**Depends on:** [`01-checker`](../01-checker/README.md), **per row, not as a front** — see
[Dependencies](#dependencies)
**Owns:** `modules/compiler-core/src/codegen/commonJS.zig` ·
`modules/compiler-core/src/codegen/typescript.zig` · `modules/compiler-core/src/codegen/js/**` ·
the commonJS snapshots under `modules/compiler-core/snapshots/codegen/<runtime>/commonJS/**` (each
carrying the TypeScript typedef of the same program) · the `KNOWN` notes and new fixtures of its rows
in `modules/compiler-core/src/codegen/tests/**` (a carve-out from
[`07-review-backlog`](../07-review-backlog/README.md))
**Does not touch:** `src/comptime/**`, `src/parser/**` ([`01-checker`](../01-checker/README.md)) ·
`src/codegen/erlang.zig`, `src/codegen/crossModule.zig` ([`02-erlang`](../02-erlang/README.md)) ·
`src/codegen/beam_asm.zig`, `src/codegen/beam/**` ([`03-beam`](../03-beam/README.md)) ·
`src/codegen/wat.zig`, `src/codegen/wat/**` ([`05-wasm`](../05-wasm/README.md)) ·
`modules/compiler-cli/**` · `libs/std/**`

Paths are relative to `repository/botopink-lang/`. Carry-over items: C-06, C-07, C-09 (R5, R7,
`adder(3)(4)`), C-18 — see [`../README.md`](../README.md).

There is **no `snapshots/codegen/<runtime>/typescript/` directory**: the TypeScript output is a
section inside each commonJS snapshot, so `typescript.zig` and `commonJS.zig` are one front.

---

## Steps

Decision 8 at run time holds on commonJS; its named-type half is carried by
[`13-module-identity`](../13-module-identity/README.md) (decision 5's class per declaration, a
subclass per variant).

### Step 1 — the §7 formatter — delivered

`@print(5.0)` prints `5.0` (the `f64` is known at the print site through `__bp_print_as`'s shape
descriptor), `[1, 2]`, `#(1, "a")`, `Point(x: 1, y: 2)`, `Shape.Square(side: 4)`, `Shape.Nothing`,
and `Display` consulted, nested too. JavaScript's `undefined` — what `?.` on an absent receiver and
an `if` with no `else` answer — prints `null` (decision 47, `decisions-pending.md` 0405-b).
`run/tuple_print.bp`, `run/print_formatter.bp` and `run/display_print.bp` pass.

### Step 2 — decision 8 at run time: `is`, unions, `unknown`, `case` arms, labels

| # | Row | State |
|---|---|---|
| D1 | `x is T` by value — `typeof` + `Number.isInteger` + range for the integer types, any number for `f64`, `Array.isArray` + arity + each element for a tuple; `x is Enum.Variant` tests the enum's class and the variant's tag | delivered |
| D2, D3 | `unknown` stores nothing extra (§11); `==` with an `unknown` operand compares numbers by value (§2.3): `val u: unknown = 2.0; u == 2` → `true` | delivered |
| D4 | `case` arms (§5): type tests, `..`, `when (…)` guards, the dot shorthand, labelled payloads; a dotted variant arm matches, an arm's final expression is its value (and no arm falls through to the next), a one-parameter binder arm binds the subject | delivered |
| D5 | tuple labels → positional (§6 T4) | **open — not this backend's**, below |

**D5, open** — `test/tuple_labels.bp::§6 T4 a label survives a generic array method`: the label in
`rs.at(0).b` reaches the backend unresolved (the checker resolves a label to `_N` only at the
written type), and decision 45 says a member access on the `?T` that `at` answers is a check
error — both halves are `01-checker`'s (C-18). The `expected-failures.txt` line names `04 step 2`.

### Step 3 — `break <value>` — superseded

Decision 105: `break v` exists only in a generator scope, and no loop answers `[v]` (C-30).

### Step 4 — `==` on tuples — delivered

`==` on tuples is structural (`__bp_eq`): `#(1, "a") == #(1, "a")` → `true`, `… == #(1, "b")` →
`false`; labels take no part (§6 T5, T6). `test/tuple_equality.bp` passes.

### Step 5 — the sibling-module `require` — delivered

A `mod` sibling imported without a `from` clause requires its own path — `require("./leaf.js")` in a
project, `require("../tree/leaf.js")` from `tree/api.js` inside a dependency.

- [x] the repro (`src/leaf.bp: pub type Leaf(v: i32)`, `src/main.bp: pub mod leaf; import { Leaf };
  @print(Leaf(v: 7).v);`) runs under node and prints `7`
- [x] the same shape inside a dependency (a `libs/<name>` project with a `files` manifest) runs and
  prints `7`
- [x] a fixture in `src/codegen/tests/**` pins both (`features.zig` `a sibling module imported with no
  from requires its own path`, needles for both shapes), with the RUN LOG in
  `tests/language/modules/sibling_import_in_a_dependency` — green on all four targets
- [ ] the workaround rule in `repository/jhonstart/AGENTS.md` ("always name the module") can be
  deleted — the deletion itself is [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)'s

### Step 6 — the `.d.ts` and the JavaScript agree — delivered

| # | Row | Today |
|---|---|---|
| T1 | a unit variant | the `.js` and the `.d.ts` agree on its shape |
| T2 | no botopink primitive name in the `.d.ts` | `i32` / `f64` → `number`, `bool` → `boolean`, `?T` → `T \| null`, `#(A, B)` → `[A, B]` |
| T3 | decision 8's types | `unknown` → `unknown`, `A \| B` → `A \| B` |

What makes every emitted `.d.ts` pass `tsc --noEmit --strict --lib es2022 --module commonjs`, each
module's `.d.ts` laid out at its module path: an import is relative to the module's own path, one
`import` per owning file (`CrossModule.picked`) and each name bound once — a std module is
`import * as dict from "./std/dict"`, a std symbol `import { empty as newDict } from "./std/dict"`;
an activated `implement` is not imported; type parameters are declared (`Dict<K, V>`,
`empty<K, V>()`, `fold<A>(…)`); `Self` is the declaring type; a function type names its parameters
(`(acc: A, key: K, value: V) => A`); a dropped decorator is not declared; `@Result<T, E>` is
`{ ok: T } | { error: E }`, the shape every module builds. `tsc` is not in the checkout (it runs
through `npx -p typescript`), so this gate is a measurement, not a script.

### Step 7 — JS-4: a botopink pattern as a JS binding target — delivered

`val Circle(r) = s;` is `const { r } = s;`; a nested constructor is a nested object pattern;
`Pattern.match`, `MatchPattern` and `writeMatchPattern` are deleted. The contract and the open
erlang/beam twins are in [`pattern-binding.md`](./pattern-binding.md).

### Step 8 — the block-as-value IIFE lowering — waits on R7

Of the IIFE build sites in `commonJS.zig`, exactly **one** is a block as a value — `@block { body }`
(classified in `src/codegen/js/AGENTS.md`); the others are genuine (a lambda, a `return case`, an
optional chain). Today `@block { 1 + 2 }` still type-checks and lowers to `(() => {(1 + 2);})()`,
printing `null`.

**Acceptance:** once [`01-checker`](../01-checker/README.md) step 8's R7 enforces decision 2, the
dead site is gone and the commonJS snapshots are otherwise byte-identical.

### Rows no step named — delivered

The optional-binding `if` and `?.` agree about absence (`o.inner?.v ?? 9` → `9`); `42.toString()` is
emitted `(42).toString()`; `adder(3)(4)` calls the result of a call (`calleeExpr`, C-09's commonJS
half; `test/curried_call.bp`); `Array.at` goes through `__bp_array_at` — `null` out of range, a
negative index counting from the end (decision 139, which reversed 0405-a); a labelled argument claims its slot; a
method's effect is its own; a context body that awaits is async; a `case` arm whose name is both a
`type` and a variant tests both; a behavior literal's `self` method is called on the literal; the
test runner reads `globalThis.process`, so `import {io.process} from "std"` does not shadow Node's
global; `\"` in an `@External.Node` template, `await` inside an `if` / `else` of a `-> @Task<T>` body,
a `try` inside a `while`, a leading-dot variant and a function-valued record field all answer right.

### Open rows with no numbered step

- **`run/map_record_field_length.bp`** (the commonJS half of [`05-wasm`](../05-wasm/README.md) step
  9's `map` row) — `ks.at(...)?.length is not a function`, exit 1: with nothing between
  `es.map({ e -> e.key })` and `ks.at(0)?.length()` the element type is unresolved at the rename of
  `.length`.
- **`status.md` § Pending** carries further commonJS rows, each with its repro: an `if` block that
  `await`s without returning, in a `@Task` body, is lowered into a non-`async` arrow (and the test
  runner then prints no summary for the module yet counts it as run); a single-target
  `#[@External.<Target>]` refuses at the call on the other target (shared with `01-checker`); front
  23's shapes shared with `02-erlang` (a function-valued record field called through the record, a
  local shadowing an imported `pub fn`, `xs.at(i).unwrapOr(…)` inside a generic function).

## Dependencies

| This front's row | Needs from [`01-checker`](../01-checker/README.md) |
|---|---|
| step 2 D5 | a label read through `?T` resolved, or refused (C-18, decision 45) |
| step 8 | step 8's R7 |

## Gate

- [x] `scripts/gate.sh --cold` green in this front's worktree — stage by stage (a worktree nested in
  the meta checkout cannot run `test-libs` whole: it sees every sibling twice, `decisions-pending.md`
  24-f — so `test-libs` ran from a scratch workspace holding copies of the libraries)
- [x] every re-recorded RUN LOG **verified by running the program** under node, and checked against
  decision 8 §7
- [x] every emitted module still passes `node --check`; every non-empty `.d.ts` passes `tsc --noEmit`
- [x] `zig build test-libs` green — the libraries' commonJS cells still pass
- [x] `src/codegen/AGENTS.md` and `src/codegen/js/AGENTS.md` updated in the same commit as each row
- [x] Commit on a branch; no push, no merge — `front/04-05-js-wasm` (both fronts in one worktree)

## Notes

- **`typescript.zig` cannot be separated from `commonJS.zig`** for snapshot purposes: the typedef is
  a section of the commonJS snapshot, not a directory of its own.
- **This front moves only commonJS snapshots.** If a change here moves the erlang, beam or wasm
  snapshots, something crossed a boundary — stop and report.
