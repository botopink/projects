# Front 02 — erlang

**Priority:** high — erlang is the backend the libraries' CI cells run on
**Depends on:** [`01-checker`](../01-checker/README.md), **per row, not as a front** — see
[Dependencies](#dependencies)
**Owns:** `modules/compiler-core/src/codegen/erlang.zig` ·
`modules/compiler-core/src/codegen/crossModule.zig` · the erlang snapshots under
`modules/compiler-core/snapshots/codegen/<runtime>/erlang/**` · the `KNOWN` notes and new fixtures of
its rows in `modules/compiler-core/src/codegen/tests/**` (a carve-out from
[`07-review-backlog`](../07-review-backlog/README.md))
**Does not touch:** `src/comptime/**`, `src/parser/**` ([`01-checker`](../01-checker/README.md)) ·
`src/codegen/beam_asm.zig`, `src/codegen/beam/**` ([`03-beam`](../03-beam/README.md)) ·
`src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**`
([`04-js`](../04-js/README.md)) · `src/codegen/wat.zig`, `src/codegen/wat/**`
([`05-wasm`](../05-wasm/README.md)) · `modules/compiler-cli/**` · `libs/std/**`

Paths are relative to `repository/botopink-lang/`. Carry-over items: C-03, C-06, C-07, C-09 (R6, R7),
C-24 — see [`../README.md`](../README.md).

---

## Steps

Decision 8 at run time holds on erlang; its named-type half (records, variants, `is Person`, a union
of named types) is carried by [`13-module-identity`](../13-module-identity/README.md) — decision
109's atoms and the identity inside the value.

### Step 1 — the §7 formatter (decision 8 §7) — delivered

One source-shaped formatter: `[1, 2]`, `["a", "b"]`, `#(1, "a")`, `5.0`, `Point(x: 1, y: 2)`,
`Shape.Square(side: 4)`, `Shape.Nothing`, and `Display` consulted, nested too (`[$1, $2]`). Absent
prints `null` (decision 47). `run/tuple_print.bp`, `run/print_formatter.bp` and
`run/display_print.bp` pass.

### Step 2 — `is`, unions, `unknown` — delivered

`x is T` by value (integer ranges, a float that fits, binaries, booleans, tuple arity and each
element); a value entering `unknown` is the value (§11: "erlang: nothing"); `==` with an `unknown`
operand compares numbers by value (§2.3) while two statically-typed operands keep exact equality;
`x is Enum.Variant` tests that variant. What C-07 still asks is under
[Open rows](#open-rows-with-no-numbered-step).

### Step 3 — `case` arms (§5) — delivered

Type-test arms, `..`, `when (…)` guards, the dot shorthand and labelled payloads lower to erlang
`case` clauses and guards. A dotted variant arm matches the bare constructor name, an arm's final
expression is its value, a one-parameter binder arm binds the subject (the three defects
`01-checker` handed over). `A...B` is an inclusive range lowered to guards on a fresh variable
(decision 53, C-06). The one `case` line left, `test/case_arms.bp`, is `01-checker`'s (`1..9` in a
pattern).

### Step 4 — tuple labels (§6 T4)

`row.pop` → `row.1` is resolved by the checker and lowered as an index; the member-access and the
fn-typed-element call paths work on erlang. Left: a labelled tuple that crosses a module boundary,
and `format.zig`'s idea of a labelled tuple, which belongs to the front that owns `src/format.zig`.

**Acceptance:** decision 8 §6's own programs print `5` and `18` on erlang; no emitted erlang carries a
label as an atom key.

- [ ] **The remaining line is the checker's, not this backend's.**
  `test/tuple_labels.bp::§6 T4 a label survives a generic array method` reads `rs.at(0).b`, and
  `rs.at(0)` is `?#(a: i32, b: string)`: `infer.zig`'s label rewrite (`tupleLabelIndex`, recorded in
  `enumSectionRewrites`) runs only on a receiver whose type is the tuple itself, so on the optional
  nothing rewrites `.b` to `._1`, nothing refuses it either, and every backend reads a field by
  name — erlang's `'__bp_field'/2` raises `badarg`, commonJS answers `undefined`. Nothing an emitter
  can do: the index the label names is decided at the written type. Owed by `01-checker` (a label
  read through `?T`, or its refusal)

### Step 5 — a condition loop used as a value — superseded

Decision 105 made `while` / `for` statements and `break v` a generator-scope form; the cell and the
error kind are gone.

### Step 6 — the generator protocol — delivered

An `@Iterator<T>` body driven by bare `yield`s, a collection loop or a condition loop runs; a bare
`break` at a generator's own level ends it (decision 103).

### Step 7 — primitive methods that emit an undefined function — delivered

A primitive method's `#[@External.Node]` spelling resolves to the method it spells
(`primNodeAliasIn`, `decisions-pending.md` 0203-a), so `toUpperCase` / `toLowerCase` run on erlang
and beam. The audit over every method `primitives.bp` declares on the primitive behaviors found one
method no backend answers, `Array.unique` (its untyped prelude body's `unwrapOr`), written into
`src/codegen/AGENTS.md` § Primitive methods with its reason.

### Step 8 — a method on an associated fn's result — delivered

`Array.range(0, 3).map({ x -> x + 1 })` emits no `'__bp_prim_map'` and prints `[1, 2, 3]` on erlang
and beam (`array_range/2` is emitted locally).

### Step 9 — the block-as-value lowering decision 2 leaves dead

Waits on C-09's R7 ([`01-checker`](../01-checker/README.md) step 8): until decision 2 is enforced — a
block is a statement, its value comes from `break` — erlang's tail-`case` block-as-value lowering
still has producers. Then delete it.

**Acceptance:** the lowering is gone; the erlang snapshots are otherwise byte-identical (a diff
outside the deleted shape is a bug found); `src/codegen/AGENTS.md` records the deletion. The twins
are each their own front's: commonJS's one `@block` IIFE site ([`04-js`](../04-js/README.md) step 8);
beam and wasm have none to delete.

### Step 10 — the prelude memo in `emitErlangModule` — delivered

`emitErlangModule` parses the embedded `primitives.bp` and `erlang_bifs.d.bp` preludes once per
process (`prelude_cache`).

### Rows no step named — delivered

A variant's labelled payload claims its declared slot; a `return` inside a loop body leaves the
function; a top-level `fn` named as a value is its fun; a function-typed field of an imported record
is applied; a `@Result` op's fun does not capture the program's own names; a non-ASCII string
literal is its UTF-8 bytes (`\x{HH}` per byte); `try` inside a `while` body propagates; a std module
compiled as a dependency keeps its default-fn shims.

### Open rows with no numbered step

- **Decision 8's tails (C-07)** — §4.1's truth table answered by each §4.2 form on erlang and beam,
  and §11's "erlang: nothing" pinned by a fixture; the tuple / `..` / type-pattern fixtures this
  front added get beam and wasm twins.
- **C-06's bookkeeping** — every moved RUN LOG verified by running the program; the `KNOWN` notes in
  `src/codegen/tests/**` that explained the decision-55 cells go with those cells (C-30 re-specified
  them).
- **JS-4's erlang twin** — `val Circle(r) = s;` checks, and erlang does not compile it:
  `variable 'R' is unbound` (`destructPatternExpr` binds nothing for a `.ctor` pattern). See
  [`04-js/pattern-binding.md`](../04-js/pattern-binding.md).
- **A method after a `?.` link** — `run/optional_chain_method.bp`: `es.at(9)?.key.length() ?? 42`
  raises `{bp_unsupported_method, <<"length">>, 0, undefined}` in `'__bp_prim_length'/1`: the method
  after the `?.` link is called on the absent value instead of being skipped.
- [ ] **A `@Result` method inside a closure** (handed over by `01-std/01-std-lib-enablement`). Not
  reproduced as first written — `xs.map({ x -> half(x).unwrapOr(0) })`, `o.unwrapOr(x)` over a
  captured `?i32` and over a captured `var` all run on erlang. What does reproduce is a **prelude**
  `default fn` body (`Array.unique`'s `prev.unwrapOr(x)`), which no inference ever typed — it fails on
  all four backends, recorded in `src/codegen/AGENTS.md`. The original report: `table.filter({ s ->
  unquote(quote(s)).unwrapOr("<err>") != s })` compiled to `unwrapOr/2 undefined` on erlang (and
  `….unwrapOr is not a function` on commonJS); the same call in a named function was fine.
- **`status.md` § Pending** carries the erlang rows still open, each with its repro.

## Dependencies

This front shares **no source file and no snapshot directory** with
[`01-checker`](../01-checker/README.md) or with the other three backends. What it shares with 01 is
the typed AST, so each open row depends on the **01 step** that feeds it:

| This front's row | Needs from 01 |
|---|---|
| step 4 (a label read through `?T`) | the label rewrite on an optional receiver, or its refusal |
| step 9 (dead lowering) | step 8's R7 |
| JS-4's erlang twin | nothing — R5 landed |

`crossModule.zig` is shared with [`13-module-identity`](../13-module-identity/README.md) by subject:
every module-atom and layout decision in it is 13's (decision 109).

## Not this front's — reassign

The `modules/two_modules`, `modules/mod_tree` and `modules/std_import` cells, and an imported
host-backed `declare fn` (`pub mod host; import { up } from "host";`), once failed under
`botopink run --target erlang` with `undefined function <module>:<fn>/N` while the emitted erlang was
correct: `run` compiled only `out/main.erl` and never loaded the sibling modules the build emitted
beside it. That is a CLI defect (`modules/compiler-cli/src/cli/run.zig`,
[`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md)), not a codegen one; the cells
pass today.

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree — not green, and not for this front's
  reason: its `test-libs` stage reads the libraries of the MAIN checkout (a worktree cannot
  initialise its own — two copies collide by name), and rakun and jhonstart there had moved to a
  newer std than the front's branch, so their cells failed on both targets at `build`. Every other
  stage was run on its own, green
- [x] every re-recorded RUN LOG **verified by running the program** — each moved RUN LOG compared
  block by block and the program run under `botopink run`; nothing bulk-accepted
- [ ] `zig build test-libs` green — every non-rakun/jhonstart cell passes, no `known-red-libs.txt`
  line added; `jhonstart-counter · erlang` moved `build` → `0` and is banked in
  `scripts/restricted-targets.txt`; see the gate box for the environmental reds
- [x] `src/codegen/AGENTS.md` and `src/codegen/erlang.zig`'s own notes updated in the same commit as each row
- [x] Commit on a branch; no push, no merge — `front/02-03-erlang-beam`

## Notes

- **Erlang is not the oracle.** Where two backends disagree, the assertion is what the program means
  under decision 8, not what erlang prints.
- **This front moves only erlang snapshots.** If a change here moves a `snapshots/comptime/**` file,
  something crossed into [`01-checker`](../01-checker/README.md)'s territory — stop and report.
- **`botopink build --target erlang` never invokes `erlc`** — a build that passes proves the text was
  emitted, not that it compiles. Run `--target erlang` before every commit.
