# Front 04 — beam

**Priority:** high — 58 of the 128 comparable fixtures disagree with the other backends, 13 of them
by aborting, and a single guard plus a single fallthrough account for 22 of them
**Depends on:** [`../03-std-surface/README.md`](../03-std-surface/README.md) — B4 and B2 reach
`libs/std/src/primitives.bp`, which no backend front may edit
**Owns:** `src/codegen/beam_asm.zig`, `src/codegen/beam/beam_emitter.zig` ·
`snapshots/codegen/beam/` (278)
**Does not touch:** `src/codegen/erlang.zig`, `src/codegen/beam/erl_ast.zig`,
`src/codegen/beam/erl_emitter.zig` ([`../05-erlang/README.md`](../05-erlang/README.md) — same
directory, different files) · `libs/std/**` ([`../03-std-surface/README.md`](../03-std-surface/README.md))
· `src/codegen/runtime.zig` · `src/codegen/commonJS.zig` · `src/codegen/wat.zig`

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`libs/` or `scripts/`, which are relative to `repository/botopink-lang/`. Every `file:line` is at
HEAD.

---

## Problem

A beam module assembles and runs, and prints a word that is the *name of a variable*:

```
val sum = 1 + 2;
fn main() { @print(sum); }
```

assembles a module with no `sum/0` form and prints `sum`. Nothing fails: the emitter turns an
identifier it cannot resolve into an atom of the same name (`src/codegen/beam_asm.zig:1824`), which
is a value, so the program runs to completion with a wrong answer. The same line is reached by a
closure's free variable (`loop (0..n) { i -> @print(n - i) }` dies with
`badarith [{erlang,'-',[n,0]}]`) and by `self` in a `val`-bound record method (which is also one of
the two modules the loader rejects once every function is exported).

## Current state

Measured by extracting each snapshot's `BEAM ASM` block, assembling it with `erlc +from_asm` per
module and running `erl -noshell -eval "main:'_botopink_main'()"` inside a `try … catch C:E:S -> …`
so the crash class and stack are visible instead of an empty log. Cross-backend agreement is
compared under the representation mapping recorded in
[`causes.md`](./causes.md#how-the-numbers-were-measured) — comparing raw text instead reports
fixtures as differing when only the rendering of a string differs.

| Measure | Value |
|---|---|
| snapshots | 278 |
| comparable `b` fixtures (source has `@print`/`@assert`/`@panic` **and** a `fn main`) | 128 |
| reproduce the value the program means | 70 |
| abort | 13 |
| run and print something else | 45 |
| …of those 58, the ones where **erlang** is the wrong backend, not beam | 3 |
| `COMPILE ERROR` blocks in a RUN LOG | 0 |
| modules rejected by the loader once every function is exported | 2 of 269 |
| coverage (`scripts/snap_audit.sh --mode=coverage`) | a/empty 145 · a/nonempty 0 · b/missing 3 · b/empty 18 · b/nonempty 110 · c/empty 2 |

`b/missing` is the same three slugs on every backend — programs that never reach codegen
(`narrow_and_condition_field_access`, `narrow_assert_pattern_with_print`,
`string_slice_without_end_arg_slices_to_source_length`). They are frontend gaps and belong to
[`../07-checker/README.md`](../07-checker/README.md).

Twelve causes cover 55 of the 58 disagreements; the other 3 are fixtures where erlang is wrong.
The ranked table, with the fixtures each cause closes, is [`causes.md`](./causes.md). What is left
of the hand-written `.S` preamble is [`emitter.md`](./emitter.md).

## Mechanism

`src/codegen/beam_asm.zig:1824` — `try beamEmitter.writeMove(self.out, Term.atomOf(n), 0);` — is
the fallthrough after the `reg_map` lookup (`:1792`), the comptime-value lookup (`:1804`) and
`crossOwnerOf` (`:1812`). It invents a value instead of failing, so every unresolved identifier
becomes a silent wrong answer.

Three different absences reach it, and one of them is upstream of the line: `:514` and `:562` emit a
named top-level `val`'s 0-arity function only `if (!has_main_0 …)`, so **any module with a
`fn main()` never gets one** and every read of that `val` falls through to `:1824`. Full trace in
[`causes.md` § B1](./causes.md#b1--an-unresolvable-identifier-becomes-an-atom-22-fixtures).

## Steps

### Step 1 — B1: resolve identifiers, then make `:1824` fail loudly

Three sub-fixes, then the guard rail:

1. **Top-level `val`** — drop the `!has_main_0` guard at `:514`/`:562` and reserve, export and emit
   every **named** top-level `val` as a 0-arity function. `topValForms` (`src/codegen/erlang.zig:2240`)
   is the model: only `_`-named synthetic statements stay ordered inside `_botopink_main`.
2. **Closure free variables** — the lambda lowering starts a fresh `reg_map`; make it carry the
   enclosing frame.
3. **`self`** — thread it as a real parameter, so `'Counter_inc'` is not emitted at arity 0 with
   `{move, {atom, self}, {x,0}}` where a map is required.

Then change `:1824` to emit a `%% unresolved identifier` note and abort, so a fourth absence is a
failure rather than a printed word.

**Acceptance:**
- [ ] The 22 fixtures in [`causes.md` § B1](./causes.md#b1--an-unresolvable-identifier-becomes-an-atom-22-fixtures)
      print the value the program means
- [ ] `rg 'atomOf\(n\)' src/codegen/beam_asm.zig` finds no move in the identifier fallthrough
- [ ] A fixture with an unresolvable identifier fails the compile instead of printing a word
- [ ] `field_assign_self_field_update` assembles with every function exported (step 7)

### Step 2 — B2: `declare fn` externals

Eight fixtures return a local function that answers `ok`. Resolve to the `@External.Erlang` form
where one exists — a BEAM `call_ext` to the same `{module, symbol}` — and otherwise fail the
lowering loudly.

**Acceptance:**
- [ ] The eight `external_*` fixtures listed in [`causes.md` § B2](./causes.md#the-ranked-table)
      print their host value, not `ok`
- [ ] A `declare fn` with no resolvable target fails the lowering with a diagnostic

### Step 3 — B3: string `+` and interpolation

Six visible fixtures (plus two hidden behind an erlang abort) lower a string `+` to the arithmetic
`{gc_bif, '+', …}` on two binaries. Build a binary instead, as `stringConcatNode`
(`src/codegen/erlang.zig:1996`) does.

**Sequence:** [`../05-erlang/README.md`](../05-erlang/README.md)'s E2 first. E2 gives each segment
the type its own operand proves; port that decision here in the same wave, or beam inherits E2's
`badarg` on a non-string operand.

**Acceptance:**
- [ ] `string_concat_of_two_literals`, `string_interpolation_lowers_to_concat`,
      `string_length_after_concat`, `reserved_word_identifiers`, `builtin_print_with_variable`,
      `narrow_early_return_with_print` print the concatenated string
- [ ] `narrow_case_option_some_none` and `narrow_else_if_chain_with_null_checks` — hidden today
      because erlang aborts on them too — print a non-string operand correctly

### Step 4 — B4: primitive and interface instance methods

28 snapshots carry at least one `%% unresolved method call` marker across 20 distinct method names;
8 of them show as a wrong value. The marker means the receiver was left in `{x,0}` and the call was
dropped. Extend the annotation / template path documented in `src/codegen/AGENTS.md`
§Primitive methods.

**Acceptance:**
- [ ] 0 `%% unresolved method call` markers under `snapshots/codegen/beam/`, or each remaining one
      names a method with no lowering anywhere and is listed in `src/codegen/AGENTS.md`
- [ ] The eight fixtures in [`causes.md` § B4](./causes.md#the-ranked-table)
      print the value the program means

### Step 5 — B5: record and interface literals

`%% unsupported: record literal` (6 occurrences) and `%% unsupported: interface literal` (2). beam
already builds a declared `record` through `put_map_assoc`; an anonymous literal needs the same.

**Acceptance:**
- [ ] `anon_record_let_bound_then_field_read_by_name`, `nested_anon_record_chained_field_read`,
      `interface_literal_basic`, `interface_literal_with_fields` print their fields
- [ ] 0 `%% unsupported: record literal` / `%% unsupported: interface literal` markers

### Step 6 — B6…B9, B11, B12: one fixture each

The indexed-loop fun arity (B6), the comprehension's `lists:map`/`lists:filtermap` choice (B7), the
`@Result` `case` arm that prints the whole tuple (B8), the register staging clobber (B9), the
`if`-with-binding on a nullable that prints nothing (B11) and the cross-module record construction
abort (B12). Mechanism and deciding line for each are in [`causes.md`](./causes.md).

**Acceptance:**
- [ ] Each of the six fixtures prints the value the program means
- [ ] B9's `stdlib_associated_fn_namespace_injected` assembles under step 7's audit with every
      function exported

### Step 7 — `scripts/beam_export_audit.sh`

Two register bugs are invisible in the tree because the recorded modules carry a narrow
`{exports, …}` form and `erlc +from_asm` drops unexported functions before validating them.
Rewriting each snapshot's exports to name every `{function, …}` form and assembling gives **269
modules assembled, 2 rejected** — see [`causes.md` § the full-export audit](./causes.md#the-full-export-audit).
Ship that rewrite as a script so the narrow exports form cannot hide a rejection again.

**Ownership note:** `scripts/**` belongs to the CLI + gate front in
[`../fronts.md`](../fronts.md#ownership). Land the script here, but wiring it into the gate is that
front's commit — stop and report rather than editing `build.zig` or a workflow.

**Acceptance:**
- [ ] `scripts/beam_export_audit.sh` assembles 269/269
- [ ] The script fails, with the rejected function and its reason, when a staging bug is
      reintroduced

### Step 8 — the `.S` preamble through the emitter

Nine writer calls in `emitBeamAsm` (`src/codegen/beam_asm.zig:603-617`) write the module preamble by
hand. Give `src/codegen/beam/beam_emitter.zig` `writeModuleForm` / `writeExports` /
`writeAttributes` / `writeLabels` and call them. Details, and the three calls that stay, are in
[`emitter.md`](./emitter.md).

**Sequence:** land step 7 first, so "snapshots byte-identical" is checked against a fully validated
tree; and land [`../05-erlang/README.md`](../05-erlang/README.md)'s `erl_ast` cleanup before this,
since both are inside `src/codegen/beam/`.

**Acceptance:**
- [ ] 9 writer calls gone from `emitBeamAsm`; the 3 in the `#[@External.Beam]` passthrough remain
      and are named in `src/codegen/beam/AGENTS.md` as the exception
- [ ] Beam snapshots byte-identical

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `scripts/beam_export_audit.sh` assembles 269/269
- [ ] beam `b/empty` = 0 — every `b` snapshot's RUN LOG is a real value, or the divergence is
      stated in its test
- [ ] `src/codegen/AGENTS.md` and `src/codegen/beam/AGENTS.md` updated in the same commit as the
      step that changes them
- [ ] Commit on `fix/beam`; no push, no merge — landing is the maintainer's step

## Blast radius

- `snapshots/codegen/beam/` only. No other snapshot directory moves: every step edits
  `beam_asm.zig` or `beam_emitter.zig`.
- Step 1 alone moves **23** snapshots that today print a top-level `val`'s name as an atom (21 label
  `b`, 2 label `a`), plus the two fixtures that reach `:1824` through a closure free variable and
  through `self`.
- Step 8 is a refactor: it must land byte-identical. A diff there is a bug found, and it moves into
  step 1–6's table rather than being re-recorded.
- Step 3 changes nothing outside beam, but it must not land before E2, or the two backends disagree
  on what a non-string operand of a string `+` renders as.

## Notes

- **Do not "fix" beam to match erlang on three fixtures.** `throw_inside_case_arm`,
  `destructure_record_parameter_in_fn` and `destructure_record_val_binding` differ because erlang is
  wrong — beam is already right. See
  [`../05-erlang/causes.md`](../05-erlang/causes.md#erlang-is-not-the-oracle).
- **B10 is not this front's.** `if_simple_conditional_in_fn_body` — a value-less `if` — yields
  `undefined` on commonJS, `ok` on erlang, `undefined` on beam and `0` on wasm: four backends, four
  answers to a question the language has not answered. It is
  [`../07-checker/README.md`](../07-checker/README.md)'s; do not re-record it here.
- **B7's expected value is also unsettled.** `loop_break_with_value` declares
  `fn find(arr) -> i32` and returns a list. Fix the `lists:filtermap` shape, but settle the return
  type in the checker front before re-recording the value.
- **B1 is a model change before it is a local fix.** "A named top-level `val` is a 0-arity function"
  is a decision about the beam module's shape, not a patch to the identifier path; write it into
  `src/codegen/AGENTS.md` with the step.
