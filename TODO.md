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
- [ ] `libs/onze/botopink.json` + `src/` skeleton; `from "onze"` resolves; a trivial
      `test {}` runs under `botopink test`.

## F1 — mock synthesis from `@Decl`
- [ ] `mock(T)` reflects `T`'s methods via `@Decl` and `@emit`s an impl where each
      method records the call (name + args) into the call log, then returns the
      stub-table entry if matched, else the type-default for its return type. Backed
      by a host-cell registry per mock instance.

## F2 — stubbing (`when … thenReturn / thenThrow`)
- [ ] `when(mock.m(args))` captures the recorded call as a stub key; `.thenReturn(v)` /
      `.thenThrow(e)` writes the stub table; a later matching call returns `v` / raises.
      Last stub wins.

## F3 — verification (`verify`, `times`, `never`)
- [ ] `verify(mock).m(args)` asserts ≥1; `verify(mock, times(n))` exactly n;
      `verify(mock, never())` 0. Failure → clear assertion (expected vs actual + calls).

## F4 — argument matchers
- [ ] `any()` / `anyString()` / `eq(v)` match args; a literal arg = exact equality;
      matchers compose across params.

## F5 — docs
- [ ] `libs/onze/AGENTS.md`, `src/AGENTS.md`, `docs.md`: API, comptime synthesis model,
      host-cell state, `from "onze"` import path. Same commit as the code.

## Done gate
- [ ] mock synthesizes every method; unstubbed → type-default; stub returns; verify
      count passes/fails correctly; matchers work. Tests in `libs/onze/*.bp`.
- [ ] `grep -riE "onze" modules/compiler-core/src` returns nothing.

## Notes
- v1: mock signatures + return stubbing + count verification. Out of scope (recorded):
  spies / partial mocks, `thenAnswer`, in-order verification, argument captors.
