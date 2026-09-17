# commonJS — the causes, ranked

> Carried from `1.0.2-beta/08-js-bridges/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

15 comparable `b` fixtures abort on commonJS and 17 run and print something else. Of the 17, six are
fixtures where **erlang** is the wrong one and one is an undecided language question, leaving **10**
real commonJS wrong values. Five causes cover all 25 (15 aborts + 10 wrong values); two of the five
are not a commonJS lowering to fix — C1 is `libs/std`'s, C2 is the bridges.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`libs/`, which are relative to `repository/botopink-lang/`. Every `file:line` is at HEAD.

## How the numbers were measured

They are not read off the snapshots — a snapshot's RUN LOG only says what the harness recorded, and
an unparseable module records the same empty log as a program that printed nothing. Each backend's
emitted code was extracted from the snapshot and executed outside the suite:

| Backend | How |
|---|---|
| commonJS | `node --check <module>.js` on every emitted module (syntax), then `node main.js` |
| erlang | `erlc -o . <mod>.erl` per module, then `erl -noshell -eval "main:'_botopink_main'()"` inside a `try … catch C:E:S -> …` so the crash class and stack are visible instead of an empty log |
| beam | `erlc +from_asm` per module, same runner; plus a full-export audit |
| wasm | `wasmtime run <module>.wat` (wasmtime 45), stdout + exit status |

Cross-backend agreement is compared under a **representation mapping**, because erlang and beam
print through `~p`: `<<"x">>` → `x`, `<<>>` → empty, `1.0` → `1`, `[ 2, 4 ]` → `[2,4]`. Comparing the
raw text instead reports **22 extra commonJS fixtures as "wrong"** that differ only in how a string
is rendered. "N fixtures differ" always means N under this mapping.

Label `a` = source without `@print`/`@assert`/`@panic`; `b` = has one and a `fn main`; `c` = has one
but no `fn main`. Of the 131 `b` fixtures, 3 never reach codegen, leaving 128 comparable:

| backend | reproduces erlang | aborts | runs, prints something else | …of which **erlang** is the wrong one |
|---|---|---|---|---|
| commonJS | 96 | 15 | 17 | 6 |
| beam | 70 | 13 | 45 | 3 |
| wasm | 62 | 29 | 37 | 3 |

Coverage (`scripts/snap_audit.sh --mode=coverage`) for commonJS: a/empty 145 · a/nonempty 1 ·
b/missing 3 · b/empty 18 · b/nonempty 110 · c/empty 2 · total 279.

### The six where erlang is wrong and commonJS is right

From [`../02-erlang/causes.md`](../02-erlang/causes.md#erlang-is-not-the-oracle). Do not "fix"
commonJS to match erlang on any of them:

| Fixture | erlang | commonJS | erlang cause |
|---|---|---|---|
| `std_package_order_enum_module_with_type_export` | `-1 less` | `-1 greater` | E6 |
| `narrow_type_guard_if_codegen` | `false` | `true` | E7 |
| `iterator_fromlist_yields_array_items` | `<<>>` | `1,2,3` | an eager `#[@iterator]` list consumed as empty |
| `comptime_block_with_break` | `COMPILE ERROR` | `20` | E5 |
| `endswith_lowers_via_external_beam_single_line_body` | crash | `true` | E3 |
| `destructure_record_val_binding` | crash | the program's value | E1 |

### The one that is a language question

`if_simple_conditional_in_fn_body`: `val r = if (n > 0) { "positive"; };` with no `else` yields
`undefined` on commonJS, `ok` on erlang, `undefined` on beam and `0` on wasm. Four backends, four
answers to a question the language has not answered. It is
[`../06-checker/README.md`](../06-checker/README.md)'s to decide; do not re-record it here.

## The ranked table

| # | Cause | Closes | Owner |
|---|---|---|---|
| C1 | The std string/array methods name `./gleam_stdlib.mjs`, which exists nowhere | **9** (aborts) | the 1.0.2-beta std-surface front — landed |
| C2 | The JS bridges emit JavaScript that does not parse | **8** (6 visible, aborts) | this front — [`bridges.md`](./bridges.md) |
| C3 | `.len` passes through as a property read → `undefined`, and `NaN` in arithmetic | **7** (wrong values) | this front |
| C4 | An enum variant's payload is destructured by the **binding** name, not the declared field name | **2** (wrong values) | this front |
| C5 | `@Result` `case` arms test `.tag === "Ok"` against a `{ ok }` / `{ error }` value | **1** (wrong value) | this front |

Reconciliation: aborts 15 = C1 9 + C2's 6 visible; wrong values 10 = C3 7 + C4 2 + C5 1. C2's two
invisible fixtures abort on erlang too, so the comparison counts them under "reproduces erlang".

## C1 — `./gleam_stdlib.mjs` (9 fixtures) — closed

`libs/std/src/primitives.bp` named the file 22 times; it is the Gleam language's runtime, and the
decision was to remove the dependency rather than ship it. The 1.0.2-beta std-surface front removed
it (step 2) together with the on-demand helper mechanism. Re-measure these 9 fixtures before
counting them; what that front left is [`README.md`](./README.md) H2–H4 and H6.

## C2 — the bridges (8 fixtures, 6 visible)

`node --check` over every emitted module finds **12** unparseable snapshots; 8 are label `b`:

| Fixture | Bridge | Visible in the comparison? |
|---|---|---|
| `loop_map_with_break_simple` | JS-1 | yes |
| `loop_even_numbers_with_break` | JS-1 | yes |
| `loop_filter_with_conditional_break` | JS-1 | yes |
| `loop_map_with_break_add_tax` | JS-1 | yes |
| `loop_break_with_value` | JS-1 | yes |
| `throw_inside_case_arm` | JS-1 (the `#[@result]` wrap — erlang's E8) | yes |
| `narrow_else_if_chain_with_null_checks` | JS-1 | **no** — erlang aborts too (E2) |
| `destructure_record_parameter_in_fn` | JS-2 + JS-3 | **no** — erlang aborts too (E1) |

The other 4 are label `a` and invisible to every RUN LOG. Mechanism, build sites and what deleting
each bridge requires are in [`bridges.md`](./bridges.md).

## C3 — `.len` is read as a property (7 fixtures)

`src/codegen/commonJS.zig:2171` — the `identAccess` arm (`:2168`) has no `len` case, so `s.len`
emits `s.len`, which is `undefined` on a JS string or array, and `NaN` once it takes part in
arithmetic. `rg '"len"' src/codegen/commonJS.zig` is empty, while every other backend has the case:
`src/codegen/erlang.zig:3041`, `src/codegen/wat.zig:3111`, `src/codegen/beam_asm.zig:2573`.

| Fixture | commonJS prints (`node main.js` at HEAD) |
|---|---|
| `string_concat_of_two_literals` | `undefined` |
| `string_length_after_concat` | `undefined` |
| `string_len_participates_in_arithmetic` | `NaN` |
| `list_literal_len_reads_length_prefix` | `undefined` |
| `list_literal_of_strings_len` | `undefined` |
| `list_literal_of_records_len` | `undefined` |
| `empty_list_literal_len_is_zero` | `undefined` |

**Fix shape:** map `.len` to `.length` on a string / array receiver. Local.

## C4 — a variant payload destructured by the binding name (2 fixtures)

`src/codegen/commonJS.zig:2957` — `for (fields, 0..) |bb, bi| props[bi] = .{ .key = bb };`, where
`bb` is the *binding*. `Shape.Circle(radius)` builds `{ tag: "Circle", radius }`, and the arm
`Circle(r) ->` emits `const { r } = _s;` — `r` is never a key, so the binding is `undefined`.

| Fixture | commonJS prints (`node main.js` at HEAD) |
|---|---|
| `narrow_case_enum_area_with_print` | `NaN` / `NaN` |
| `narrow_case_option_some_none` | `value: undefined` / `empty` |

**Fix shape:** the prop must carry the declared field as the key and the binding as the value
(`const { radius: r } = _s;`). The positional order comes from the declared field order — erlang
builds it in `collectTypeShapes` (`src/codegen/erlang.zig:2089`); commonJS has no equivalent table
yet, so this is the one C-row that needs a small model addition. Local.

## C5 — `@Result` arms test a tag the value does not have (1 fixture)

`src/codegen/commonJS.zig:2967` — the same `.variant` arm as C4, ten lines down: the arm test is
`_s.tag === "<Variant>"`. `#[@result]` materialises `{ ok: … }` / `{ error: … }`, so the emitted
`fetch` in `narrow_case_result_ok_err_with_print` returns `({ ok: "data" })` and both arms miss —
`node main.js` prints `undefined` twice.

**Fix shape — pick one:** build the arm test against the `ok` / `error` keys (as erlang's
`resultTag`, `src/codegen/erlang.zig:3788`, does), or make `#[@result]` emit `{ tag, … }`. The first
is smaller and keeps `try`/`catch` consistent, since that lowering already tests `"error" in _r`
(`src/codegen/commonJS.zig:2014`). Local.

## Edges

- **C1 lands first, and not here.** `libs/std` is embedded in the global environment, so the
  std-surface front re-records every codegen directory, this front's included.
- **JS-1's `throw_inside_case_arm` and erlang's E8 are one defect.** The `#[@result]` wrap lives in
  the transform pass; whoever takes it re-records commonJS *and* erlang, so it cannot run beside
  either front. Agree the owner first.
- **JS-2's `:2414` and erlang's E5** (`src/codegen/erlang.zig:3625-3633`) are one latent defect in two
  backends. Neither waits for the other, but land both in the same milestone.
- **C4 and C5 edit the same `.variant` arm** (`:2948-2970`). One commit, or C5 rebases on C4.
- **`if_simple_conditional_in_fn_body` is re-recorded by nobody** until the checker front decides
  the value of a value-less `if`.
