# Front 06 — wasm

**Priority:** high — wasm is the only backend the suite never executes, and 29 of its 128 executable
fixtures abort at run time without a single RUN LOG saying so
**Depends on:** [`../03-std-surface/README.md`](../03-std-surface/README.md) — W1's instance-method
and external sub-classes reach `libs/std/src/primitives.bp`, which no backend front may edit
**Owns:** `src/codegen/wat.zig`, `src/codegen/wat/**` · `snapshots/codegen/wasm/` (278)
**Does not touch:** `src/codegen/erlang.zig`, `src/codegen/beam_asm.zig`, `src/codegen/commonJS.zig`
· `libs/std/**` · `src/codegen/runtime.zig` **without agreeing ownership first** — see the note
below, the `executeWat` work needs it and no front in [`../fronts.md`](../fronts.md#ownership)
owns it

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`libs/`, which are relative to `repository/botopink-lang/`. Every `file:line` is at HEAD.

---

## Problem

`executeWat` (`src/codegen/runtime.zig:553`) returns `""`, so wasm is the only backend with **0**
observable RUN LOGs: 128 fixtures that print something record nothing. All 282 `WASM TEXT` blocks
still pass `wasmtime compile`, but since `src/codegen/wat.zig:3038` turned an unlowerable call into
`unreachable` instead of folding it to a constant, loading is no longer the interesting property —
**29 of the 128 executable `b` modules abort at run time**, and 35 more run and print the wrong
value.

## Current state

Measured by running every emitted module under `wasmtime run <module>.wat` (wasmtime 45), recording
stdout and the exit status. The comparison against the other backends uses the representation
mapping recorded in [`causes.md`](./causes.md#how-the-numbers-were-measured).

| Outcome | `b` (128) | `a` (145) |
|---|---|---|
| runs to completion with the value the program means (`a` prints nothing by construction) | 64 | 134 |
| runs to completion, prints the wrong value | 35 | — |
| aborts on `unreachable` from an unresolved call | **27** | 3 |
| aborts on `unreachable` from `@todo` / `@panic` (correct behaviour) | 1 | 8 |
| aborts on an out-of-bounds load | 1 | 0 |

The honest placeholders left in the emitted text:

| Placeholder | Occurrences | Snapshots | of which `b` |
|---|---|---|---|
| `;; unresolved call: <f>/<n>` (now on `unreachable`) | 59 | 38 | 27 |
| `;; lambda` (a lambda as a *value* → `i32.const 0`) | 9 | 9 | 1 |
| `;; cross-module import not linked (wasm single-module)` | 8 | 5 | 3 |
| `;; … (unknown receiver type)` | 6 | 5 | 5 |
| `;; loop over unknown iterable` | 5 | 4 | 3 |
| `;; folded non-numeric literal` | 3 | 3 | 0 |

52 snapshots carry at least one; 32 of them are label `b`. Coverage
(`scripts/snap_audit.sh --mode=coverage`): a/empty 145 · a/nonempty 0 · b/missing 3 · b/empty 128 ·
b/nonempty 0 · c/empty 2 — the 128 `b/empty` are not crashes, they are the 128 fixtures `executeWat`
never ran.

Eleven causes, ranked, are in [`causes.md`](./causes.md). W1 alone accounts for 27 of them and is
the keystone: **`emitWat` is never handed `instance_lowerings`**, so no method call can resolve.

## Mechanism

`codegenEmit` (`src/codegen/wat.zig:174`) calls
`emitWat(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, &cross)`. Every
other backend also passes `ok.instance_lowerings` (`src/codegen/erlang.zig:332`,
`src/codegen/beam_asm.zig:428`). Without that map, wasm has no `emitPrimMethod`, no
`tryEmitPrimAnnotation` and no externals table; `lowerCollectionMethod`
(`src/codegen/wat.zig:3044`) serves exactly two methods, `at/1` and `length/0`, and everything else
falls to `lowerPlainCall`'s `unreachable` at **`src/codegen/wat.zig:3038`** — whose doc comment at
`:3004-3009` still describes the old constant-folding behaviour and is now wrong.

## Steps

### Step 1 — record a wasm abort as a visible block

`src/codegen/runtime.zig` records an empty RUN LOG for any non-zero exit (`:537-542`), so a
`wasm trap: wasm 'unreachable'` would be indistinguishable from a program that ran fine and printed
nothing. Add a `RUNTIME TRAP (wasmtime):` section carrying the trap message, exactly as
`COMPILE ERROR (erlc):` is recorded today (`:507`, `compileFailureLog`).

Do this **first**: it is what makes every later step's result legible, and it is a small change with
no lowering work.

**Ownership:** `src/codegen/runtime.zig` is not owned by any front in
[`../fronts.md`](../fronts.md#ownership), while the same file is where the js-bridges front's
`node --check` gate goes. **Stop and report** to agree the owner before editing it.

**Acceptance:**
- [ ] A trapping wasm module records `RUNTIME TRAP (wasmtime):` plus the message, never an empty log
- [ ] The existing `COMPILE ERROR (erlc):` behaviour is unchanged

### Step 2 — W1: hand the backend `instance_lowerings`

Pass `ok.instance_lowerings` to `emitWat`, then lower each of the seven sub-classes the 27 fixtures
split into — 10 primitive/interface instance `default fn`s, 8 `#[@External.*]` `declare fn`s, 3
interface associated fns / `from "std"` namespace calls, 3 cross-module symbols, 1 named lambda, 1
record inherent method, 1 `join` after an unknown iterable. The breakdown, with the callee names, is
in [`causes.md` § W1](./causes.md#w1--the-backend-is-never-handed-instance_lowerings-27-fixtures).

The external sub-class needs a **decision**, not a lowering: wasm has no host. Pick one — a WASI
import, a compile-time error, or a documented `unreachable` — and record it in
`src/codegen/AGENTS.md`.

Correct the doc comment at `src/codegen/wat.zig:3004-3009` in the same commit: it describes
constant folding that `:3038` no longer does.

**Acceptance:**
- [ ] `emitWat` receives `instance_lowerings`
- [ ] `;; unresolved call:` occurrences drop from 59 to the number the external decision leaves,
      and each remaining one is a shape with no lowering anywhere
- [ ] `src/codegen/wat.zig:3038` is reachable only for such a shape, and its doc comment describes
      what it does now
- [ ] The external decision is written into `src/codegen/AGENTS.md`

### Step 3 — turn `executeWat` on

Only after steps 1 and 2. The condition, what turning it on today would pin, and the mechanics
(`wasmtime run` on the `.wat` text, `runCaptured` plus the existing content-keyed cache, no `aux`
leg, and **not** the erlang early-bail heuristic) are in [`execute-wat.md`](./execute-wat.md).

Bump `HARNESS_VERSION` with it, or a warm cache hides the change.

**Acceptance:**
- [ ] `executeWat` either executes or its doc comment states the deliberate skip and why
- [ ] `HARNESS_VERSION` bumped in the same commit
- [ ] No wasm RUN LOG is accepted while its module is known to print the wrong value

### Step 4 — W2 and W3: a string and a bool reach `@print` as an i32

13 fixtures, one site. `lowerPrintArg` (`src/codegen/wat.zig:2366`) tries `isStringExpr` (`:2367`),
then `isBoolExpr` (`:2372`), then `wasmTypeOf` (`:2377`), then falls to `$__print_i32`
(`:2383-2384`), so an unrecovered type prints the *address*. The fix is not in `lowerPrintArg` — it
is in what `isStringExpr` can prove: a record/tuple field, a `case` result, a `try` result and a
comptime-produced global all need a recovered type.

**Acceptance:**
- [ ] The 10 W2 fixtures print their string (for `if_simple_conditional_in_fn_body`, only the
      string line — see Notes), and the 3 W3 fixtures print `true`/`false`
- [ ] No wasm RUN LOG contains a bare small integer where the program prints a string

### Step 5 — W4, W5, W6: loop comprehensions, comptime globals, `case`

- **W4** (6) — `yield` / `break <v>` must accumulate into a new array blob.
- **W5** (4) — the folded value of a `comptime { … break v; }` never reaches `emitGlobalVal`
  (`src/codegen/wat.zig:1705`), and the global is declared i32 even for an f64 value.
- **W6** (4) — `case` discriminates only numeric and `or`-of-numeric patterns; it needs string
  equality (`$__str_eq` exists) plus a variant-tag test with payload binding.

**Acceptance:**
- [ ] The 14 fixtures listed under W4, W5 and W6 in [`causes.md`](./causes.md) print the value the
      program means
- [ ] A `comptime` f64 global is declared f64

### Step 6 — W7: decide the `@Option` none carrier

`@Option` none is the bare value `0`, indistinguishable from a real `0` (4 fixtures). This is a
**carrier decision, not a bug fix** — owned by [`../09-review-tooling/semantics-decisions.md#decision-3`](../09-review-tooling/semantics-decisions.md#decision-3), which rejects a sentinel and recommends boxing `?T` as an `i32` offset (`0` = null); land W7 on that answer, and state it in
`src/codegen/AGENTS.md` before changing any lowering.

**Acceptance:**
- [ ] The carrier is written into `src/codegen/AGENTS.md`
- [ ] `array_at_lowers_byte_identically_across_backends`, `optional_fn_return_null_path`,
      `narrow_if_null_check_with_print` and `narrow_type_guard_if_codegen` agree with the other
      backends under the representation mapping

### Step 7 — W8…W11: the tail

Field access on an unrecovered receiver (2), `array.slice` returning raw bytes (1), `xs.at` /
`xs.slice` over an empty array reading out of bounds (1 — the only non-`unreachable` trap), and a
non-string operand dropped from a string concat (1, the wasm mirror of the erlang front's E2).

**Acceptance:**
- [ ] Each of the five fixtures prints the value the program means
- [ ] W11 agrees with [`../05-erlang/README.md`](../05-erlang/README.md)'s E2 on what a non-string
      operand renders as

### Step 8 — `Module.externs`: four symbols nothing defines, on a path nothing calls

`Builder.externCall` (`src/codegen/wat/wat_ast.zig:564-569`) lets a module `call` a symbol it does
not define by recording it in `Module.externs` (`:268`), which `declaresCall` (`:319-325`) counts as
declared, so `validateModule` (`:334`) accepts the call. Four symbols use it: `$__emit` (`src/codegen/wat.zig:2428`), `$__compilerError` (`:2435`),
`$__binding_ref` (`:2443`) and `$__str_concat_rt` (`:3634`). The prelude that defined them no longer
exists, and neither does the host it was written for. Evidence, the recommended deletion and the
comment sweep are in [`execute-wat.md`](./execute-wat.md#module-externs--four-symbols-nothing-defines).

This step touches no other backend, changes no snapshot and has no caller to break — **the safest
independent piece of this front**, and the one to hand a second worker.

**Acceptance:**
- [ ] No symbol is callable without a definition, or `Module.externs` is gone
- [ ] 0 references to `wat_runtime` or `wasm3_host` outside a changelog
- [ ] wasm snapshots byte-identical

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] A wasm abort is recorded as `RUNTIME TRAP (wasmtime):` + the message, never as an empty log
- [ ] Every wasm `b` snapshot's RUN LOG is a value that was verified by running the module, or its
      test states the divergence
- [ ] Step 8 lands snapshot-byte-identical
- [ ] The `executeWat` decision, the external-call decision and the `@Option` carrier are recorded
      in `src/codegen/AGENTS.md`
- [ ] Commit on `fix/wasm`; no push, no merge — landing is the maintainer's step

## Blast radius

- **Step 3 creates 128 RUN LOGs that do not exist today.** Every wasm snapshot gains a block, so the
  directory is re-recorded wholesale; nothing else may be touching `snapshots/codegen/wasm/` at the
  time.
- Steps 1 and 3 change `src/codegen/runtime.zig`, which is shared with the js-bridges front's
  `node --check` gate. Neither front owns it — agree first.
- Step 2 is the keystone: 27 fixtures change from an abort to a value, and the 3 label-`a` fixtures
  that abort today (the three `lambda_*`) start loading. No RUN LOG can ever show those three, which
  is the argument for fixing them by construction rather than waiting for a fixture.
- Step 8 touches nothing outside `src/codegen/wat/**` and must land byte-identical.
- W7's carrier decision changes how *every* optional is represented in wasm; it is the one step here
  that can move a fixture that looks unrelated.

## Notes

- **Three fixtures differ because erlang is wrong, not wasm**: `destructure_record_parameter_in_fn`
  and `destructure_record_val_binding` (the erlang front's E1), and `try_with_inline_catch_handler`
  (E4 — wasm's `unreachable` is the right answer for a program that calls `@todo()`). Do not "fix"
  wasm to match them. See
  [`../05-erlang/causes.md`](../05-erlang/causes.md#erlang-is-not-the-oracle).
- **`if_simple_conditional_in_fn_body` is only half this front's.** wasm prints `256 0`: the `256` is
  W2 (the address of `"positive"`), the `0` is the value-less `if`, where the other three backends
  print three other things; the value of a value-less `if` is
  [`../07-checker/README.md`](../07-checker/README.md)'s question. Do not re-record that second line.
- **`isArrayExpr` is deliberately narrow** (`src/codegen/AGENTS.md` §wat), which is why 4 of the 6
  W4 fixtures also carry `;; loop over unknown iterable`. Widening it is part of W4, not a separate
  cleanup.
- **`wasm3` leftovers in `build.zig:17`, `:95`, `config.zig:22-23` and `runtime.zig:548-549`** are
  the hygiene front's, not this one's — step 8 only sweeps the comments inside `src/codegen/wat*`
  and the files listed with it.
