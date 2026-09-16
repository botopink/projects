# Front 05 — erlang

**Priority:** high — three of its ten defects are *silent wrong answers*, and erlang was the oracle
the previous milestone's cross-backend comparison trusted
**Depends on:** [`../03-std-surface/README.md`](../03-std-surface/README.md) — E3 is an annotation in
`libs/std/src/primitives.bp`, which no backend front may edit
**Owns:** `src/codegen/erlang.zig` (the **typed** path), `src/codegen/beam/erl_ast.zig`,
`src/codegen/beam/erl_emitter.zig` · `snapshots/codegen/erlang/` (279)
**Does not touch:** `src/codegen/erlang.zig`'s `untyped` branch
([`../01-comptime-dispatch/README.md`](../01-comptime-dispatch/README.md) — **same file**, so this
front and that one are sequenced, not parallel) · `src/codegen/beam_asm.zig`,
`src/codegen/beam/beam_emitter.zig` ([`../04-beam/README.md`](../04-beam/README.md)) · `libs/std/**`
· `src/codegen/commonJS.zig`

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`libs/`, which are relative to `repository/botopink-lang/`. Every `file:line` is at HEAD.

---

## Problem

Two of these programs print an answer, exit 0, and the answer is wrong:

```
fn isString(x: ?string) -> x is string { if (x) { s -> return true; }; return false; }
```

emits `case X of undefined -> undefined; S -> true; _ -> ok end, false.` — the `case` value is
thrown away and `false` is returned unconditionally. And a `case` arm naming a variant of an
**imported** enum emits `case O of Lt -> …; Gt -> …` with the variants unquoted, so the first arm
binds anything and matches: the program means `greater` and prints `less`.

Six more fixtures abort, and one emits a module `erlc` rejects outright.

## Current state

Measured by extracting each snapshot's `ERLANG` block, compiling it with `erlc -o . <mod>.erl` per
module and running `erl -noshell -eval "main:'_botopink_main'()"` inside a `try … catch C:E:S -> …`,
so the crash class and stack are visible instead of an empty log. Cross-backend agreement uses the
representation mapping recorded in [`causes.md`](./causes.md#how-the-numbers-were-measured).

| Measure | Value |
|---|---|
| snapshots | 279 |
| comparable `b` fixtures | 128 |
| fixtures that abort | 6 |
| modules that do not compile | 1 (`comptime_block_with_break`) |
| fixtures that print a wrong value **silently** | 3 (E6, E7, E8) |
| `COMPILE ERROR` blocks left in a RUN LOG | 1 — the only one in the tree |
| `Ast.Expr.r(` in `erlang.zig` | 13 |
| coverage (`scripts/snap_audit.sh --mode=coverage`) | a/empty 146 · a/nonempty 0 · b/missing 3 · b/empty 6 · b/nonempty 122 · c/empty 2 |

Eight causes cover all ten defects, one fixture each except E1 and E2 — the table with every
deciding line is [`causes.md`](./causes.md). The `Ast.Expr.r("")` inventory, what each site stands
for and which are output bugs rather than shape concerns, is [`raw-rows.md`](./raw-rows.md).

**Seven fixtures found erlang to be the wrong backend**, four of them silently. Anyone comparing
backends must read
[`causes.md` § erlang is not the oracle](./causes.md#erlang-is-not-the-oracle) before writing an
assertion.

## Mechanism

The three silent ones share a shape: a construct is lowered into a position where its value is
discarded or its name is not quoted, and erlang has no diagnostic for either.

- **E6** — `enum_variants` is populated from the module's own decls, and `collectImportedTypes`
  carries an imported record's fields but not an imported enum's variants, so an imported variant
  name lowers as a fresh variable, which matches anything.
- **E7** — a binding-form `if` goes through `condNode`/`mutatingExpr` instead of
  `earlyReturnIfExpr`, which is what nests the rest of the body in the false arm; the `case` is
  emitted as a statement and its value dropped.
- **E8** — the `#[@result]` wrap is applied to the whole `case` instead of to each non-jumping arm,
  so a throwing arm becomes `{ok, {error, …}}` and `isOk()` answers `true`.

## Steps

### Step 1 — E1: a record destructuring is a map pattern, not a tuple

`destructPatternExpr` (`src/codegen/erlang.zig:2857-2868`), deciding line **`:2867`**
`return .{ .tuple = items.items };`. The `.names` arm must build `.map` with `exact = true` —
`src/codegen/beam/erl_ast.zig:130-135` already carries `MapField.exact` for `:=` — i.e.
`#{name := Name}`; `.tuple_` keeps the tuple. Reached from `fnForms` (params), `stmtExpr` `:2905`
(`val`) and `propagateTryExpr` `:2837`.

**Acceptance:**
- [ ] `destructure_record_val_binding` and `destructure_record_parameter_in_fn` run and print the
      destructured fields, matching commonJS, beam and wasm
- [ ] No `{badmatch, #{…}}` or `function_clause` in any erlang RUN LOG

### Step 2 — E2: a string `+` segment gets the type its own operand proves

`concatSegments` (`src/codegen/erlang.zig:2002-2021`), deciding line **`:2020`** — the segment type
is the constant `"binary"`. Give each segment `binary` when `isStringExpr(e)` (`:2026`) and
otherwise a stringify: `formatNode` (`:3592`) already builds
`iolist_to_binary(io_lib:format("~p", [E]))`, or `integer_to_binary/1` for an integer operand.

**Sequence:** [`../04-beam/README.md`](../04-beam/README.md)'s B3 is the same defect on the other
backend and must port this decision. Land erlang first.

**Acceptance:**
- [ ] `narrow_case_option_some_none` and `narrow_else_if_chain_with_null_checks` print the
      non-string operand instead of raising `badarg`
- [ ] A fixture interpolates an `i32`, a `bool` and a record into a string on all four backends

### Step 3 — E4: `@todo()` inside a `#[@result]` fn

`try fetch() catch 0` lowers to a `case`, which cannot catch a raise, and `@todo()` emits
`erlang:error({todo, …})`. Wrap the propagating `case` in a real `try … catch error:E` — that
matches what `throw` already does and is the smaller of the two shapes.

**Acceptance:**
- [ ] `try_with_inline_catch_handler` runs the catch arm
- [ ] The behaviour is the same on commonJS and beam; wasm's `unreachable` is accepted as the
      correct answer for a program that calls `@todo()`

### Step 4 — E5 and the seven value `raw` sites

A comptime block drops every statement before its `break`:
`val result = comptime { val x = 10; break x * 2; };` emits `result() -> (X * 2).` →
`main.erl:6:6: variable 'X' is unbound`, the one `COMPILE ERROR` block left in the tree. The value
is already folded (`COMPTIME VALUES: ct_0 → 20`), so making `topValForms` (`:2240`) read
`comptime_vals` for a `comptime` val is the smaller fix — exactly what commonJS does
(`const result = 20;`).

Then give a real node to all seven `Ast.Expr.r("")` sites that stand in for a missing value —
`:2308`, `:3174`, `:3175`, `:3176`, `:3184`, `:3628`, `:3632`. Each renders as nothing, which is how
the bare-`break` bug produced a syntactically broken module before it was fixed. Inventory in
[`raw-rows.md`](./raw-rows.md).

**Acceptance:**
- [ ] 0 `COMPILE ERROR` blocks under `snapshots/codegen/erlang/`
- [ ] `comptime_block_with_break` prints `20`
- [ ] No `Ast.Expr.r("")` left in a value position (7 sites)

### Step 5 — E6: an imported enum's variants

`collectImportedTypes` must carry an imported enum's variants, so a `case` pattern naming one is
quoted as an atom instead of lowered as a variable.

**Acceptance:**
- [ ] `std_package_order_enum_module_with_type_export` prints `-1 greater`, matching commonJS
- [ ] beam, which reproduces the same bug, is checked against the same fixture
      ([`../04-beam/README.md`](../04-beam/README.md))

### Step 6 — E7: a `return` inside a narrowed `if` arm

Route the binding-form `if` through `earlyReturnIfExpr`, which nests the rest of the body in the
false arm, instead of `condNode`/`mutatingExpr`. The dead `_ -> ok` clause goes with it.

**Acceptance:**
- [ ] `narrow_type_guard_if_codegen` prints `true`
- [ ] No erlang snapshot emits a `_ -> ok` clause after a narrowed `if`

### Step 7 — E8: the `#[@result]` wrap goes **into** each arm

`return case s { Ok -> 1; Fail -> throw "failed"; }` emits
`{ok, case S of 'Ok' -> 1; 'Fail' -> {error, <<"failed">>} end}`, so a throwing arm becomes
`{ok, {error, …}}` and `isOk()` answers `true`. Push the wrap into each non-jumping arm.

**This step is not an erlang-only change.** The wrap decision lives in the transform pass, and
commonJS spells the same defect as `return return ({ error: … })`, a SyntaxError — the JS-1 row of
[`../08-js-bridges/README.md`](../08-js-bridges/README.md). Fixing the wrap once re-records
**both** snapshot directories, so it cannot run beside the js-bridges front, and it needs a file
neither front owns. **Stop and report** to agree the owner before starting it.

**Acceptance:**
- [ ] `throw_inside_case_arm` prints `true false`, matching beam
- [ ] `node --check` passes for the commonJS module of the same fixture
- [ ] No emitted erlang carries `{ok, {error, …}}`

### Step 8 — the `raw` rows: unreachable fallbacks and the pre-spelled call head

Byte-identical. Four unreachable fallbacks (`:2967`, `:2977`, `:3537`, `:3768`) return
`Ast.Expr.r("")` and must return an error or assert; `headCall` (`:3667-3669`) wraps an
already-spelled head in `Ast.Expr.r` at `:3668` and has **11** callers. Detail and the replacement
node per head shape in [`raw-rows.md`](./raw-rows.md).

**Acceptance:**
- [ ] `Ast.Expr.r(` in `erlang.zig` is 1 — the host template text at `:1566` — and
      `src/codegen/beam/AGENTS.md` documents why that one stays
- [ ] Erlang and beam snapshots byte-identical

### Step 9 — dead scaffolding and per-call allocation

Byte-identical cleanups left from the `Term` / `erl_ast` migration: three verbatim-text variants
with no producer, per-variable allocation on `this.alloc`, constant number leaves spelled as
strings, and the `$stringify(…)` wrapper written as template text — the last two writer calls in the
file. Table in [`raw-rows.md`](./raw-rows.md#dead-scaffolding-and-per-call-allocation).

**Sequence:** this deletes variants from `src/codegen/beam/erl_ast.zig` and `erl_emitter.zig`;
[`../04-beam/emitter.md`](../04-beam/emitter.md) adds methods to `beam_emitter.zig` in the same
directory. Land erlang first.

**Acceptance:**
- [ ] The three dead variants and their four render arms are gone; builds clean
- [ ] No per-variable allocation on `this.alloc` in `erlang.zig`
- [ ] 0 writer calls in `erlang.zig`
- [ ] Erlang and beam snapshots byte-identical

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] 0 `COMPILE ERROR` blocks under `snapshots/codegen/erlang/`; erlang `b/empty` = 0
- [ ] E6, E7 and E8 each have a fixture whose RUN LOG is the value the *program* means,
      cross-checked against commonJS and beam
- [ ] Steps 8 and 9 land snapshot-byte-identical
- [ ] `src/codegen/AGENTS.md` and `src/codegen/beam/AGENTS.md` updated in the same commit as the
      step that changes them
- [ ] Commit on `fix/erlang`; no push, no merge — landing is the maintainer's step

## Blast radius

- Steps 1–6 move `snapshots/codegen/erlang/` only.
- **Step 7 moves `snapshots/codegen/commonJS/` too** — the wrap is in the transform pass. It is the
  one step here that is not file-local to this front.
- Steps 8 and 9 touch `src/codegen/beam/`, which the beam front also has files in; they are
  byte-identical, so the risk is a drifted re-record of `snapshots/codegen/beam/`, not a semantic
  change.
- E2 changes what every interpolated non-string renders as. beam inherits it (B3), so the two
  fronts must agree on the stringify shape before either re-records.
- **Fixing erlang invalidates comparisons made against it.** Seven fixtures were compared against a
  backend that was wrong; after this front lands, re-check any assertion in another front that was
  written as "matches erlang".

## Notes

- **Erlang is not the oracle.** The 1.0.1-beta measurement assumed it was. Every cross-backend
  assertion must be written against the *program's* expected output. The seven fixtures are listed
  in [`causes.md`](./causes.md#erlang-is-not-the-oracle).
- **E3 is not a codegen gap at all.** `libs/std/src/primitives.bp:143` annotates
  `#[@External.Erlang("string", "suffix")]`, and `string:suffix/2` is a function OTP never had — it
  answers `undef`. It belongs to [`../03-std-surface/README.md`](../03-std-surface/README.md);
  the fixture it breaks is `endswith_lowers_via_external_beam_single_line_body`.
- **E5 has a latent twin on commonJS** at `src/codegen/commonJS.zig:2405-2415`, unreached only
  because the decl-level path folds first. It is the js-bridges front's JS-2 audit row; fixing it
  there does not wait for a fixture.
- **The value of a value-less `if` is not decided here.** `if_simple_conditional_in_fn_body` prints
  `ok` on erlang and three other things elsewhere; it is
  [`../07-checker/README.md`](../07-checker/README.md)'s.
- `src/codegen/erlang.zig` is shared with the comptime-dispatch front, which owns the `untyped`
  branch of the same `Emitter`. Per [`../fronts.md`](../fronts.md#conflict-matrix) they are
  sequenced, never parallel.
