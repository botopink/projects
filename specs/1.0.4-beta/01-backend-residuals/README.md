# Front 01 — backend-residuals

**Delivered** 2026-09-17 on `botopink-lang` `feat`, steps 1–4 — merges `00b8975` (beam), `4eadb70`
(wasm), `dbe2863` (commonJS), `b4cf700` (step 4, decision 1a on commonJS, erlang and wasm). The three
cross-backend fixtures below print what the program means on all four backends and carry no `KNOWN`
note any more. This front took 01 from the four backend fronts that landed at `ed15323` — see
[Delivered by the backend fronts](#delivered-by-the-backend-fronts).

**Owned:** `src/codegen/beam_asm.zig`, `src/codegen/beam/**` · `src/codegen/erlang.zig` ·
`src/codegen/wat.zig`, `src/codegen/wat/**` · `src/codegen/commonJS.zig`,
`src/codegen/typescript.zig`, `src/codegen/js/**` · `src/codegen/runtime.zig` · the `KNOWN` notes of
the fixtures below in `src/codegen/tests/**` (carved out of
[`../08-review-backlog/`](../08-review-backlog/README.md)) ·
`snapshots/codegen/{beam,erlang,wasm,commonJS}/`

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`libs/` or `scripts/`, which are relative to `repository/botopink-lang/`. Test line numbers were read
at `ed15323`; re-locate by test name.

---

## Delivered by the backend fronts

Each landing ran `scripts/gate.sh --cold` green.

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
| 3 commonJS | `dbe2863` | CR1 loop start, CR2 open range as the lazy `__bp_range_from`, CR3 struck (already printing since JS-1), CR4: a record method named `print`, enum methods on variant values, primitive-interface host members, interface defaults as class methods, `pair.0` |
| 4 print text | `b4cf700` | PR1 commonJS, PR2 erlang, PR4 wasm (was WR4): arrays `[a,b]`, tuples `#(a,b)`, nested strings quoted with source escapes, under [decision 1a](../08-review-backlog/semantics-decisions.md#decision-1a); wasm string literals now store unescaped bytes. PR3 (beam) was folded into the decision-8 formatter |

One row of step 6 landed early, outside this front: **D8-6**, `loop (condition)` lowered on all four
backends and commonJS's call-shaped `while` special case deleted, came with 06's G0
(`c51aadd`, merge `13f61fa`).

## The three cross-backend fixtures — closed

| Fixture | Test | The program means |
|---|---|---|
| `lambda_a_local_closure_reassigning_outer_vars_threads_them_out` | `tests/control_flow.zig` ~`:188` | `<start><a><b> 3` |
| `loop_two_parameter_loop_threads_reassigned_vars_out` | `tests/control_flow.zig` ~`:158` | `a-c`, then `140` |
| `operators_plus_on_untyped_operands_and_division_of_floats` | `tests/values.zig` ~`:361` | `abcd`, then `5` |

The erlang lowering was the model for all three: closure threading (`70b9236`),
`lists:enumerate(Start, Xs)` for an indexed loop, and operand-proven `+` with `__bp_add/2` for an
untyped operand. **Erlang is still not the oracle** — the value in "the program means" is the
assertion; see [`measurement.md`](./measurement.md#erlang-is-not-the-oracle).

## Measurements

Library gate at `b4cf700` (`zig build test-libs`): every cell passes, no known-red line.
`beam_export_audit.sh` assembles every module (302/302 after step 1's 295/295 baseline moved with the
surface cutover).

## Gate

- [x] Steps 1–3: `scripts/gate.sh --cold` green in each worktree and on `feat` after each merge
- [x] No `KNOWN` note left on the three cross-backend fixtures; each RUN LOG verified by running the
      program, on all four backends
- [x] BR4 answered (→ the beam template row, carried); CR4 re-verified row by row
- [x] Step 4: decision 1a's acceptance; every re-recorded RUN LOG checked against the rule
- [x] `src/codegen/AGENTS.md` and the backend's own `AGENTS.md` updated in the same commit as each row

## What it left, and where

The run-time half of [decision 8](../08-review-backlog/decision-8-language.md) was written as one
step across four backends. 1.0.5-beta splits it **one front per backend**, so a re-recorded RUN LOG
carries one reason.

| Residual | Owner in 1.0.5-beta |
|---|---|
| **BR5** — beam lowers an `@External.Erlang` template to direct BEAM code at build time instead of `'__bp_erl_eval'/2` (the maintainer answered BR4: beam stops evaluating templates at run time). A partial, untested start was kept in the `.tasks/beam-templates` worktree, branch `fix/beam-templates` | `03-beam` |
| **D8-1** `x is T` by value (§4) · **D8-2** `unknown` and unions at run time (§2, §3) · **D8-3** `case` arms (§5) · **D8-4** `row.label` lowered as an index (§6) | `02-erlang` · `03-beam` · `04-js` · `05-wasm`, one row per backend |
| **D8-5 — the formatter** (§7): one derived formatter per type, source-shaped (`[1, 2]`, `#(1, "a")`, `Point(x: 1, y: 2)`, `f64` always `5.0`), `Display` honoured when nested. It replaces the decision-1a printers on commonJS, erlang and wasm and gives beam its first (absorbs PR3). 21 of the language suite's 54 expected failures name it | `02-erlang` · `03-beam` · `04-js` · `05-wasm` |
| **JS-4's codegen half** — once the checker's N11 lands, a `ctor` destructuring lowers to a real JS test-plus-destructure and `Pattern.match` goes ([`pattern-binding.md`](./pattern-binding.md)) | `04-js`, after `01-checker` N11 |
| The **block-as-value lowerings** left dead in all four backends once the checker enforces decision 2 (the erlang tail `case`, beam's `make_fun3`, commonJS's IIFE, wasm's `;; lambda`) | `02-erlang` · `03-beam` · `04-js` · `05-wasm`, after `01-checker` N6 |
| **commonJS: a sibling-module import inside a dependency is emitted as `require("../module")`** — the five libraries worked around it by naming the sibling module in the import (emilia `d14310c`, jhonstart `2aefaf5`) | `04-js` |
| A `wrong-output` row of the 1.0.1-beta snapshot review that survives re-derivation in the backend files | `07-review-backlog`, registered against the backend front |

## Routed out during the milestone — closed

| Item | Closed by |
|---|---|
| E8 — the `#[@result]` wrap into each arm | carried: `01-checker` N10 (not landed) |
| `scripts/beam_export_audit.sh` in the gate and CI | 05 step 6 (j), `0a18e07` |
| Stale `wasm3` / `wat_runtime` comments in files the wasm front did not own | 09 step 2, `2997a5b` |
| `libs/std`: `String.split("")` and the `builtins.d.bp` `@print` doc | std-split `c8c2541` |
| `libs/std`: `Array.chunked` / `sliding` written with `while` | 06 G0, `cab0bf7` — both are `loop (0..n)` now |

The checker rows this front handed over (N5, N6, N10–N15) are in
[`../06-checker/`](../06-checker/README.md); the ones that did not land are carried from there.

## Notes

- **The erlang family's numeric text is intended to diverge**: erlang prints `5.0` where commonJS
  prints `5` (`src/codegen/AGENTS.md`). Do not "fix" it.
- **beam's run-time abort on an unbound name is the backstop, not the fix.** It is still in place;
  the check is the checker's N13, carried.
