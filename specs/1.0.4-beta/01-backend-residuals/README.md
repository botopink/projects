# Front 01 — backend-residuals

**Status:** steps 1–4 **delivered** 2026-09-17 on `botopink-lang` `feat` — merges `00b8975` (beam),
`4eadb70` (wasm), `dbe2863` (commonJS), `b4cf700` (step 4, decision 1a on commonJS, erlang and wasm);
see [Delivered by this front](#delivered-by-this-front). **Open, after
[`../06-checker/`](../06-checker/README.md):** step 5 (BR5) and step 6 (decision 8 at run time, which
absorbs PR3). This front took 01 from the four backend fronts that landed at `ed15323` — see
[Delivered by the backend fronts](#delivered-by-the-backend-fronts).

**Priority:** medium — every open row below is a fixture pinned `KNOWN` in its test or a named gap; no
backend prints a wrong answer the tree does not say is wrong
**Depends on:** [`../06-checker/`](../06-checker/README.md) landed, for steps 5 and 6
([`../fronts.md`](../fronts.md#conflict-matrix) note 1)
**Owns:** `src/codegen/beam_asm.zig`, `src/codegen/beam/**` · `src/codegen/erlang.zig` (no open row;
held so a follow-up has an owner) · `src/codegen/wat.zig`, `src/codegen/wat/**` ·
`src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**` ·
`src/codegen/runtime.zig` · the `KNOWN` notes of the fixtures below in `src/codegen/tests/**` (carved
out of [`../08-review-backlog/`](../08-review-backlog/README.md)) · `snapshots/codegen/{beam,erlang,wasm,commonJS}/`
**Does not touch:** `src/comptime/**`, `src/parser/**` ([`../06-checker/`](../06-checker/README.md))
· `libs/std/**` (no owner — [`../fronts.md`](../fronts.md#unowned-items)) · `scripts/**`, `build.zig`,
`.github/**` · the rest of the test sources

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`libs/` or `scripts/`, which are relative to `repository/botopink-lang/`. Test line numbers were read
at `ed15323`; re-locate by test name.

---

## Delivered by the backend fronts

Not to redo. Each landing ran `scripts/gate.sh --cold` green.

| Front | Merge | Delivered |
|---|---|---|
| 01 beam | `a743955` | B1 every identifier resolved (top-level `val`s as 0-arity fns, closure captures, `self` as a parameter; an unbound name aborts at run time `{unresolved_identifier, N}`), B2 externals, B3 string `+`, B4 primitive/interface methods through the interface chain with on-demand default fns, B5 record/interface literals, B6–B9, B11, B12, `scripts/beam_export_audit.sh` 290/290, the `.S` preamble through the emitter, decision 1, decision 4 (`{bp_assert, Msg, Loc}`), register clobbering fixed generally, statement loop/`forEach` reassigning outer vars via `lists:foldl`, imported/std enum tag tests, `Signed.abs` |
| 02 erlang | `42429dc` | E1 map patterns, E2 `__bp_text/1`, E4 `try`/`catch`, E5 comptime block `break` value + the 7 value `raw` sites, E6 imported enum variants quoted, E7 narrowed `return` nesting, decision 1 (`__bp_print/1`, typed and comptime paths), decision 4, erika 7b (two-parameter `loop` via `lists:enumerate`), closure var threading (jhonstart), the std erlang reds, operand-proven `+` / `__bp_add`, float `/`, `Signed.abs` on `i32`, step 8 (one host-template `Expr.r(` left, documented), step 9 |
| 03 wasm | `ed15323` | `RUNTIME TRAP (wasmtime):` block, W1 `instance_lowerings` (unresolved calls 59 → 3: `List.map` ×2, `new Error`), host-backed `declare fn` traps by decision, **`executeWat` executes** (`wasmtime run`, `HARNESS_VERSION = "3-wasm-runs"`), W2–W11 (W7 per decision 3), `Module.externs` / `emitFnWat` deleted, decision 4. 143 wasm snapshots gained a real RUN LOG: 97 match commonJS and erlang, 26 are right where another backend is wrong, 9 trap by decision or `@todo` |
| 04 js-bridges | `bd7836c` | `COMPILE ERROR (node --check):` block, C3–C5, JS-1 (statement `if`/loops, loop-as-value IIFE, `return case`), JS-2, JS-3, JS-5, JS-6 (bare `throw` rejected on all backends), `while` lowering (std commonJS green), `pub` template externals export a function, on-demand helpers in `js/js_prelude.zig` (`charAt` → null out of range), `externals.zig` fixtures off `gleam_stdlib.mjs`, `.d.ts` without dangling template imports, every pub enum and record exported, decision 4 |

## Delivered by this front

| Step | Merge | Delivered |
|---|---|---|
| 1 beam | `00b8975` | BR1 closure threading, BR2 `loop (xs, 1..)`, BR3 operand-proven `+` (`'__bp_add'/2`) and float `/`; BR4 reviewed — `'__bp_erl_eval'/2` and its measured cost (~50× a direct call) in `src/codegen/beam/AGENTS.md`; `beam_export_audit.sh` 295/295 |
| 2 wasm | `4eadb70` | WR1 closure captures, WR2 loop index start, WR3 untyped string `+` and float text, WR5 (`Ok`/`Err`/`new Error` build the Result pair; `List.map` listed in `src/codegen/AGENTS.md` as a shape no backend lowers) |
| 4 print text | `b4cf700` | PR1 commonJS, PR2 erlang, PR4 wasm (was WR4): arrays `[a,b]`, tuples `#(a,b)`, nested strings quoted with source escapes, under [decision 1a](../08-review-backlog/semantics-decisions.md#decision-1a) — **superseded by decision 8 §7** (the formatter of step 6); wasm string literals now store unescaped bytes. PR3 (beam) absorbed by step 6 |
| 3 commonJS | `dbe2863` | CR1 loop start, CR2 open range as the lazy `__bp_range_from`, CR3 struck (already printing since JS-1), CR4: a record method named `print`, enum methods on variant values, primitive-interface host members, interface defaults as class methods, `pair.0` — `?T.map` inside a record method body → 06 |

The three cross-backend fixtures below print what the program means on all four backends; their
`KNOWN` notes are gone.

## Problem

Three fixtures are pinned known-wrong on more than one backend, and each backend has a short tail.
None is silent — each test carries a `KNOWN` note naming the backend — but every note is a
cross-backend assertion the suite cannot make yet.

## Current state

Library gate at `b4cf700` (`zig build test-libs`): every cell passes, no known-red line.
`beam_export_audit.sh` assembles every module (302/302).

### The three cross-backend fixtures

| Fixture | Test | The program means | commonJS | erlang | beam | wasm |
|---|---|---|---|---|---|---|
| `lambda_a_local_closure_reassigning_outer_vars_threads_them_out` | `tests/control_flow.zig` ~`:188` | `<start><a><b> 3` | right | right | ` 0` | ` 0` |
| `loop_two_parameter_loop_threads_reassigned_vars_out` | `tests/control_flow.zig` ~`:158` | `a-c`, then `140` | `80` | right | prints nothing | `80` |
| `operators_plus_on_untyped_operands_and_division_of_floats` | `tests/values.zig` ~`:361` | `abcd`, then `5` | right | right (`5.0`, intended) | prints nothing | `520`, `1082480000` |

The erlang lowering is the model for all three: closure threading (`70b9236`), `lists:enumerate(Start,
Xs)` for an indexed loop, and operand-proven `+` with `__bp_add/2` for an untyped operand. **Erlang is
still not the oracle** — the value in "the program means" is the assertion; see
[`measurement.md`](./measurement.md#erlang-is-not-the-oracle).

## Steps

Steps 1–4 are delivered — [Delivered by this front](#delivered-by-this-front). Steps 5 and 6 both
edit `beam_asm.zig` and open after 06: run them in sequence, or step 6's commonJS/erlang/wasm rows
beside step 5.

### Step 4 — the text of arrays and tuples (decision 1a) — delivered

Delivered as `b4cf700` for PR1, PR2, PR4; PR3 moves to step 6. Kept for the record.

[Decision 1a](../08-review-backlog/semantics-decisions.md#decision-1a): `[e1,e2]`, `#(e1,e2)`, a
nested string quoted, on every backend. The rows touch every backend file and may run as one
worktree or one per backend; `src/codegen/runtime.zig` is not needed (the text is the program's).

| # | Row | Acceptance |
|---|---|---|
| PR1 | commonJS: `@print` of an array or a tuple goes through an on-demand prelude helper instead of `console.log`'s own text (`[ 1, 'a' ]`) | the decision's fixtures print their text under node |
| PR2 | erlang: `__bp_print/1` renders lists and tuples by the rule instead of `~p` (`[{1,<<"a">>}]`) | the same fixtures under `erl` |
| PR3 | beam: the same `__bp_print/1` change | the same fixtures; `beam_export_audit.sh` still assembles every module |
| PR4 (was WR4) | wasm: a printer for arrays of tuples (and nested strings), type-directed in `wat_prelude.zig` | `array_zip_via_external_node_template` prints `[#(1,"a"),…]`; its `KNOWN-WRONG` note in `tests/features.zig` goes |

**Blast radius:** every snapshot whose RUN LOG prints an array or a tuple, on all four backends —
measure before starting; each re-recorded RUN LOG is checked against the rule, not bulk-accepted.

### Step 5 — `@External.Erlang` templates compiled at build time on beam (BR4 answered)

**Moved after [`../06-checker/`](../06-checker/README.md)** (maintainer, 2026-09-17): a performance row
that blocks no correctness work. A partial, untested start is kept in the `.tasks/beam-templates` worktree (branch `fix/beam-templates`).

The maintainer answered BR4: beam stops evaluating `@External.Erlang` templates at run time.

| # | Row | Acceptance |
|---|---|---|
| BR5 | beam lowers an `@External.Erlang` template to direct BEAM code at build time (the erlang backend already renders the same template to source; reuse that rendering or a shared template walker, do not add a second template language) instead of `'__bp_erl_eval'/2` | no `'__bp_erl_eval'` left in any beam snapshot, or each remaining use named with the reason in `src/codegen/beam/AGENTS.md`; RUN LOGs unchanged; `beam_export_audit.sh` assembles every module |

### Step 6 — decision 8 at run time (after 06)

[Decision 8](../08-review-backlog/decision-8-language.md) moves every backend once 06 has typed it.
Runs **after [`../06-checker/`](../06-checker/README.md)** and before 12.

| # | Row |
|---|---|
| D8-1 | `x is T` by value on the four backends (§4): numeric ranges, integral floats converted, constructors, tuple arity; wasm reads the box tag |
| D8-2 | `unknown` and unions at run time (§2, §3): wasm boxes a value entering them (the `?T` box generalised); equality with numbers by value when an operand is `unknown` |
| D8-3 | `case` arms (§5): type tests, `..`, guards |
| D8-4 | `row.label` → positional access (§6) — resolved by the checker, lowered as an index |
| D8-5 | **The formatter** (§7): one derived formatter per type, source-shaped (`[1, 2]`, `#(1, "a")`, `Point(x: 1, y: 2)`, `f64` always `5.0`), `Display` honoured when nested; replaces the decision-1a printers on commonJS, erlang and wasm and gives beam its first (absorbs PR3) |
| D8-6 | commonJS's `while` special case deleted (§10); `loop (condition)` lowered on all four |

Every re-recorded RUN LOG is checked against §7; the snapshots recorded under decision 1a are
re-recorded once, here.

## Routed out

Found by the backend fronts, owned elsewhere.

| Item | Found by | Goes to |
|---|---|---|
| E8 — the `#[@result]` wrap into each arm; decided in `comptime/transform.zig`, re-records erlang **and** commonJS | erlang | [`../06-checker/`](../06-checker/README.md#step-0--rows-added-in-104-beta) N10 |
| JS-4 — a pattern in binding position (`val Circle(r) = s` parses but is unbound; `assert x is Some(n)` does not parse). The commonJS half — deleting `Pattern.match` — follows the checker: [`pattern-binding.md`](./pattern-binding.md) | js-bridges | 06 N11; the codegen half in [`../fronts.md`](../fronts.md#unowned-items) |
| `loop_break_with_value`'s declared `-> i32` returning a list (wasm prints an address) | beam, wasm | 06 N12 |
| `if_simple_conditional_in_fn_body` and every value-less `if` (old B10) | beam, wasm, js-bridges | 06 N6 (decision 2) |
| An unbound name aborts beam at run time instead of failing the check | beam | 06 N13 |
| A comptime array folded as a number literal — beam aborts `{unlowered_comptime_value, …}` | beam | 06 N5 |
| `run {…}` / `use effect {…}` arity mismatches | beam | 06 N14 |
| Inference records no lowering for a method on an associated fn's result (erlang falls back to runtime dispatch) | erlang | 06 N15 |
| `scripts/beam_export_audit.sh` in the gate and CI | beam | [`../05-cli-residuals/`](../05-cli-residuals/README.md) step 6 (j) |
| Stale `wasm3` / `wat_runtime` comments in files the wasm front did not own; test comments citing retired front numbers | wasm, all | [`../09-hygiene/`](../09-hygiene/README.md) step 2 and notes |
| `libs/std`: `String.split("")`, the `builtins.d.bp` `@print` doc, `Array.chunked` / `sliding` | erlang | [`../fronts.md`](../fronts.md#unowned-items) |

## Gate

- [x] Steps 1–3: `scripts/gate.sh --cold` green in each worktree and on `feat` after each merge
- [x] No `KNOWN` note left on the three cross-backend fixtures; each RUN LOG verified by running the
      program, on all four backends
- [x] BR4 answered (→ step 5); CR4 re-verified row by row
- [ ] Step 4: decision 1a's acceptance; every re-recorded RUN LOG checked against the rule
- [ ] Step 5: no run-time template evaluation left on beam, RUN LOGs unchanged
- [ ] `src/codegen/AGENTS.md` and the backend's own `AGENTS.md` updated in the same commit as each row
- [ ] Commit on `fix/backend-residuals-<step>`; no push, no merge

## Blast radius

- Step 4 moves all four codegen snapshot directories — every RUN LOG that prints an array or a tuple.
- Step 5 moves `snapshots/codegen/beam/` (the `.S` text); RUN LOGs stay.
- Either step may add fixtures to `src/codegen/tests/**` — a carve-out from 08 like the `KNOWN`
  notes; name each in the landing note.

## Notes

- **The erlang family's numeric text is intended to diverge**: erlang prints `5.0` where commonJS
  prints `5` (`src/codegen/AGENTS.md`). Do not "fix" it.
- **beam's run-time abort on an unbound name is the backstop, not the fix.** Keep it; the check is
  06 N13's.
