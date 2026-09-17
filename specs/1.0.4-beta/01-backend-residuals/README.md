# Front 01 — backend-residuals

**Status:** not started. What the four backend fronts left when they landed on `botopink-lang`
`origin/feat` = `ed15323` (2026-09-17): 01 beam (`a743955`), 02 erlang (`42429dc`), 03 wasm
(`ed15323`), 04 js-bridges (`bd7836c`). Those numbers are retired; this front takes 01 — see
[Delivered by the backend fronts](#delivered-by-the-backend-fronts).

**Priority:** medium — every row below is a fixture pinned `KNOWN` in its test or a named gap; no
backend prints a wrong answer the tree does not say is wrong
**Depends on:** nothing open. [`../05-cli-residuals/`](../05-cli-residuals/README.md) step 2 edits one
`codegenEmit` site in each backend file — sequence it against this front (see
[`../fronts.md`](../fronts.md#conflict-matrix) note 1)
**Owns:** `src/codegen/beam_asm.zig`, `src/codegen/beam/**` · `src/codegen/erlang.zig` (no open row;
held so a follow-up has an owner) · `src/codegen/wat.zig`, `src/codegen/wat/**` ·
`src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**` ·
`src/codegen/runtime.zig` · the `KNOWN` notes of the fixtures below in `src/codegen/tests/**` (carved
out of [`../08-review-backlog/`](../08-review-backlog/README.md)) · `snapshots/codegen/{beam,erlang,wasm,commonJS}/`
**Does not touch:** `src/comptime/**`, `src/parser/**` ([`../06-checker/`](../06-checker/README.md))
· `libs/std/**` (no owner — [`../fronts.md`](../fronts.md#unowned-items)) · `scripts/**`, `build.zig`,
`.github/**` ([`../05-cli-residuals/`](../05-cli-residuals/README.md)) · the rest of the test sources

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

## Problem

Three fixtures are pinned known-wrong on more than one backend, and each backend has a short tail.
None is silent — each test carries a `KNOWN` note naming the backend — but every note is a
cross-backend assertion the suite cannot make yet.

## Current state

Library gate at `ed15323` (`zig build test-libs`): emilia, onze, rakun, std commonJS and std erlang
pass; erika (commonJS + erlang) and jhonstart (commonJS) are known-red, on a `libs/std` defect, not a
backend one ([`../fronts.md`](../fronts.md#unowned-items), first row).

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

The three backends' rows are file-disjoint: steps 1–3 may run as three worktrees. Each fixture's
`KNOWN` note is one comment in a shared test file; the step that closes the last backend on a
fixture deletes the note.

### Step 1 — beam

| # | Row | Acceptance |
|---|---|---|
| BR1 | A local closure reassigning outer vars prints ` 0` — the statement-loop `lists:foldl` threading does not reach a named closure called later | `lambda_a_local_closure_…` prints `<start><a><b> 3` |
| BR2 | Two-parameter `loop (xs, 1..)` prints nothing | `loop_two_parameter_loop_…` prints `a-c` / `140` |
| BR3 | Untyped `+` and float `/` print nothing | `operators_plus_on_untyped_…` prints `abcd` / `5.0` (the erlang family's numeric text) |
| BR4 | **Review, not a fix:** B2 lowers an `@External.Beam` body to `call_ext`, and an `@External.Erlang` template is evaluated **at run time** by a generated `'__bp_erl_eval'/2` — correct, slow | the maintainer keeps it (written in `src/codegen/beam/AGENTS.md` with the cost) or asks for build-time compilation of the template, which then becomes a row here |

### Step 2 — wasm

| # | Row | Acceptance |
|---|---|---|
| WR1 | A local closure reassigning outer vars prints ` 0` | `lambda_a_local_closure_…` prints `<start><a><b> 3` |
| WR2 | `loop (xs, 1..)` ignores the range start (prints `80`) | prints `140` |
| WR3 | Untyped `+` adds two pointers (`520`); a float prints as its i32 bits (`1082480000`) | prints `abcd` / `5` |
| WR4 | `array_zip_via_external_node_template` prints tuple addresses: no printer for an array of tuples. commonJS and erlang spell the value differently, so there is no agreed text yet | decide the text under [decision 1](../08-review-backlog/semantics-decisions.md#decision-1) first, then wasm prints it; the `KNOWN-WRONG` note in `tests/features.zig` goes |
| WR5 | Three unresolved calls left: `List.map` ×2 (`List` exists nowhere) and `new Error` | each is either lowered or listed in `src/codegen/AGENTS.md` as a shape with no lowering anywhere |

### Step 3 — commonJS

| # | Row | Acceptance |
|---|---|---|
| CR1 | `loop (xs, 1..)` ignores the range start (prints `80`) | prints `140` |
| CR2 | `range_open_ended_range` throws at run time | the module runs; an open range used as a value either lowers or is a located compile error |
| CR3 | Four `break`-comprehension fixtures print nothing (reported by the js-bridges landing; a scan of the `b` snapshots at `ed15323` did not re-find them — name them before starting) | each prints the value the program means |
| CR4 | **Not claimed by the js-bridges landing — re-verify first.** The four 1.0.3-beta example rows handed to it: a record method named `print` lowers `d.print()` to `console.log(console.log())`; a behavior `default fn` calling another member fails `self.max is not a function`; an enum method is not attached to variant values (`Shape.Square(4).area is not a function`, [`../EXAMPLES.md`](../EXAMPLES.md) §5); `pair.0` is emitted verbatim and `?T.map` lowers to `Array.prototype.map` | each row runs, or is struck with the commit that closed it |

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

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] No `KNOWN` note left on the three cross-backend fixtures; each RUN LOG verified by running the
      program, on all four backends
- [ ] BR4 answered and written down; CR4 re-verified row by row
- [ ] `src/codegen/AGENTS.md` and the backend's own `AGENTS.md` updated in the same commit as each row
- [ ] Commit on `fix/backend-residuals` (or `fix/backend-residuals-<backend>`); no push, no merge

## Blast radius

- Each row moves its own backend's snapshot directory only. The three cross-backend fixtures move
  one snapshot per backend they close.
- WR4 waits on a text decision and may move commonJS or erlang too, if the agreed spelling is not
  theirs.
- CR4 may add fixtures (the example programs) to `src/codegen/tests/**` — a carve-out from 08 like
  the `KNOWN` notes; name each in the landing note.

## Notes

- **The erlang family's numeric text is intended to diverge**: erlang prints `5.0` where commonJS
  prints `5` (`src/codegen/AGENTS.md`). Do not "fix" it.
- **beam's run-time abort on an unbound name is the backstop, not the fix.** Keep it; the check is
  06 N13's.
