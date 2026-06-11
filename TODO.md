# TODO — Front A: core-language test coverage (v0.beta.13)

**Branch**: `task/v13-core` (from `origin/feat` @ eac9313)
**Spec**: `tasks/v0.beta.13/specs/front-a-core.md`
**Front territory** (edit ONLY here): `modules/compiler-core/src/**/tests/*.zig` +
`modules/compiler-core/snapshots/**`. File-disjoint from Fronts B (`task/v13-libs`) and
C (`task/v13-tooling`) — they never touch these files.
**Status**: net-new gaps closed; A6 + a few items recorded as out-of-territory/limitations

> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test
> (no `--no-verify`). Goal: turn each `[gap]` in the spec into a `[have]` (add the test)
> or record it as a product limitation. No production behaviour change expected.

## Areas (see front-a-core.md for the tagged scenarios + examples)

- [x] A1 effects — net-new: effect marker on a record method; compound
      `@Future<@Result<T,E>>`; two-markers-on-one-fn conflict (error snap); `#[@external]`
      with no target for the active backend → `MissingExternalTarget`. beam/wasm eager-lowering
      snapshots are auto-covered by the existing 4-backend `assertJsSingle` effect tests.
- [x] A2 errors-result-option — net-new: `@Result` as a record field; `?.`→Option resolved by
      `unwrapOr`; `val x = try f()` binds the unwrapped Ok; throw of an enum error variant
      unifies with `E`. beam/wasm try snapshots auto-covered by the 4-backend codegen tests.
- [x] A3 pattern-matching — net-new: wildcard makes a partial (string) case exhaustive; case
      over int/string literal scrutinees; nested record destructuring binds inner fields (via the
      leading-non-ident payload form — identifier-first nesting is a parser limitation, noted
      in-test); case-as-val vs trailing type-check identically.
- [x] A4 generics-recursion-context — net-new: generic record at two concrete types; recursion
      through a generic data type; generic return inferred from usage; inline `test {}` in a
      generic module resolves (closes the historic `.generic` gap); 3-layer @Context stays
      Element-based.
- [x] A5 extension-dispatch — net-new: implement-for-primitive + dispatch; chained extension
      calls; inherent wins over a same-name implemented method; two imported libs activating the
      same method → cross-module ambiguity (custom multi-module test). codegen/{erlang,beam,wasm}
      cross-module dispatch stays a known limitation (LOCAL-only).
- [~] A6 module-system — parser `[have]`s already exist. The net-new resolve/visib/build gaps
      (3+-level nesting, sibling same-name, pub-mod type re-export, circular mod, orphan) all
      need the **filesystem module resolver** in the CLI/driver, not compiler-core → out of
      Front-A territory (belongs to Front C).
- [x] A7 expr-templates — net-new: hole captures a bare variable reference; empty template
      handled gracefully; splice type-error reports at the splice site (not the def); nested
      template (body builds a call to another template fn) expands end-to-end; two invocations
      expand independently.
- [x] A8 backends-parity — net-new snapshots (all 4 backends): two-hole string interpolation;
      record `==` vs array `==` (snapshot exposes equality is *backend-defined* — `===` ref-eq on
      node/wasm, `=:=` structural on erlang/beam; no special structural record `==`). `Array.range`
      host-external stays open (limitation).  ·  execution (run/*) is Front C

## Done means
`zig build test` green with the new Zig `test {}` / `.snap.md` added; every A-front `[gap]`
closed or recorded. Then integrate into `feat` via a throwaway `.tasks/_integrate-v13-core`.
