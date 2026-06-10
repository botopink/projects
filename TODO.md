# TODO — onze  (annotation-processor lib · Wave 1)

> Task branch `task/onze` · spec
> [`tasks/v0.beta.8/specs/onze.md`](../../tasks/v0.beta.8/specs/onze.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on: nothing** — the `@Decl`/`@emit` mechanism + loader are in `feat`.
> Start now. Sibling of `rakun` (same mechanism, disjoint lib).
>
> New pure-`.bp` lib, **zero** core code. Mockito for botopink tests:
> `mock(T)`/`when`/`verify`. Mock state behind `#[@external]` host cells.

## F0 — stand up the lib
- [x] `libs/onze/botopink.json` + `src/` skeleton; `from "onze"` resolves; `test {}`
      blocks run under `botopink test` (7 tests green in `test/onze_test.bp`).

## F1 — mock synthesis from `@Decl`
- [x] `#[mock]` reflects the interface's methods via `@Decl` and `@emit`s a
      `record MockXxx implement Xxx` (each method records the call + returns the
      stub-or-type-default through `onzeInvoke`) plus a `mockXxx()` factory. Backed by
      a host-cell registry keyed per mock instance (`onze.mjs`).
      **Works + type-checks under `botopink build`** (see `examples/mock_synthesis.bp`).
      ⚠ The `botopink test` pipeline does not yet splice `@emit` (core test-mode gap —
      it runs decorator *placement* validation but drops emitted decls), so the runtime
      tests use the explicit mock shape `#[mock]` emits. Tracked in `libs/onze/AGENTS.md`.

## F2 — stubbing (`when … thenReturn / thenThrow`)
- [x] `when(mock.m(args))` captures the recorded call (with matchers) as the stub key;
      `.thenReturn(v)` / `.thenThrow(msg)` writes the stub table; a later matching call
      returns `v` / host-raises. Last stub wins.

## F3 — verification (`verify`, `times`, `never`)
- [x] `verify(mock, atLeastOnce()).m(args)` asserts ≥1; `verify(mock, times(n))` exactly
      n; `verify(mock, never())` 0. Failure → clear assertion (expected vs actual +
      recorded calls). Uniform 2-arg form (no fn overloading / default params in botopink).

## F4 — argument matchers
- [x] `eq(v)` / `anyInt()` / `anyString()` match args; a literal arg = exact equality;
      matchers compose across params. (Generic `any<T>()` can't produce a per-type dummy
      — typed `anyXxx()` instead; extend per type.)

## F5 — docs
- [x] `libs/onze/AGENTS.md`, `src/AGENTS.md`, `docs.md`: API, comptime synthesis model,
      host-cell state, `from "onze"` import path, status table. Parent `libs/AGENTS.md`
      updated. Same commit as the code.

## Done gate
- [x] mock synthesizes every method (under `build`); unstubbed → type-default; stub
      returns; verify count passes/fails correctly; matchers work. Tests in
      `libs/onze/test/onze_test.bp` (7 green under `botopink test`).
- [x] `grep -riE "onze" modules/compiler-core/src` returns nothing.

## Notes
- v1: mock signatures + return stubbing + count verification. Out of scope (recorded):
  spies / partial mocks, `thenAnswer`, in-order verification, argument captors.
- **Carried gap (core, not onze):** `@emit` contributions are spliced under `build`
  but dropped under `botopink test` (test_mode). When that lands, swap the explicit
  mocks in `test/onze_test.bp` for `#[mock]` and the synthesis is testable end to end.
- **Parser/comptime gotchas hit:** `if` is an expression (needs `else`, `;` bodies);
  bare `if {…}` only as a block's last statement; decorator bodies can't call sibling
  fns; `//` comments with quotes/backticks inside a closure break the lexer; `==` on
  arrays is JS reference equality (compare with `.join`). Recorded in `src/AGENTS.md`.
