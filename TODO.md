# TODO — mutual-recursion  (inference / regression · Wave 1)

> Task branch `task/mutual-recursion` · spec
> [`tasks/v0.beta.9/specs/mutual-recursion.md`](tasks/v0.beta.9/specs/mutual-recursion.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on: nothing.** **F0 already resolved** — this spec only closes the regression gap.

> Verified 2026-06-10 on `feat`: forward refs + true mutual recursion (`isEven ⇄ isOdd`)
> type-check on commonJS/erlang/beam/wasm and run on commonJS; a genuine unbound name
> still errors. The binding pre-pass already landed (with the jhonstart renderer work).

## F0 — confirm + lock in (a BEAM codegen fix WAS needed)
- [x] Regression test added: `isEven ⇄ isOdd` (forward ref + mutual recursion).
      - **Run + assert** (`.bp` run-test): `modules/compiler-cli/tests/mutual_recursion{,.sh}`
        — `botopink test` asserts the result on commonJS + erlang; the script also
        assembles the BEAM `.S` (`erlc +from_asm`) and asserts `main:main() == true`.
      - **All-backend codegen guard** (in `zig build test`):
        `codegen/tests/js_control_flow.zig` (snapshots commonJS/erlang/beam/wasm).
      - Type-check + unbound-name guards already existed in
        `comptime/tests/infer_decls.zig` + `infer_errors.zig`.
- [x] Runs confirmed on **all four** backends (each asserts the result):
      commonJS ✓, erlang ✓, beam ✓ (`true`), wasm ✓ (`main()` → `1`).
- [x] A backend run DID reveal codegen bugs — fixed all:
      - **BEAM** (`codegen/beam_asm.zig` `emitIf`): an else-less `if` statement
        ended in `move undefined`+`return.`, turning the recursive tail call into
        dead code (`isEven(10)` → atom `undefined`). False branch now falls
        through. 9 BEAM snapshots regenerated (same dead-code removal).
      - **wasm** (`codegen/wat.zig`): two unrelated gaps that blocked the run —
        `true`/`false` lowered to an undefined `global.get $true` (→ `i32.const
        1`/`0`), and the entrypoint wrapper didn't `drop` a value-returning
        `main` (invalid wasm). 9 wasm snapshots regenerated; the logical-operator
        wasm tests now actually execute under wasmtime in the harness.

## Done gate
- [x] regression test green; `a() calls b() declared later` type-checks + runs.
- [x] a genuine unbound name still errors (diagnostics unchanged).
- [x] `zig build && zig build test` green.
