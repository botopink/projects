# TODO — package-default-dsl

> Task branch `task/package-default-dsl` · spec
> [`tasks/v0.beta.14/specs/package-default-dsl.md`](tasks/v0.beta.14/specs/package-default-dsl.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on:** the parser layer already on `feat` (`593af55`): `pub default fn`
> (`FnDecl.isDefault`) + `import pkg` namespace forms (`ImportDecl.package`).

Goal: `pub default mod erika;` (declarable in ANY module, not root-only) +
`pub default fn` (the handler) + `import erika` so the `erika "…"` package-handle
DSL resolves to the package's default fn — replacing the name-matching `pub fn erika`.

## F0 — parser: `pub default mod` ✅
- [x] `pub default mod Name;` parses at any module top level (`ModDecl.isDefault`;
      `checkDefaultMod` mirrors `checkDefaultFn`; `parseModDecl` reads the modifier).
      No root-only restriction. Parser tests in `parser/tests/imports.zig`.
- [x] Validation: at most one `pub default mod` + one `pub default fn` per package
      (duplicate is the error, NOT the location) — `validateUniqueDefaults`
      (`infer.zig`, both inference entry points); error snapshots in `infer_errors.zig`.

## F1 — resolver: `import pkg` binds the package default ✅
- [x] `import pkg` / `import pkg from "pkg"` locate the package's `pub default mod`
      + its `pub default fn` (wherever declared in the package), and bind `pkg` → that
      fn. `registerExports` pairs them per package (`pkgKey`) and aliases the handler
      under the handle (value-export table + `template_registry`); `resolveImports`
      binds `u.package`. Internal + external both resolve (template fn = no
      cross-module call at codegen).
- [x] `import pkg, { a, b }` binds the default AND the named items (the brace list
      flows through the existing import loop).

## F2 — inference: `<pkg> "…"` resolves to the bound default ✅
- [x] A tagged `pkg "…"` / `pkg """…"""` resolves to the bound `pub default fn` via
      the existing `@Expr`/`@ExprCustom` template path (`registerImportedTemplateFn`
      + the value-type bind make `env.lookup`/`env.templateFns.get` succeed).

## F3 — codegen ×3 ✅
- [x] No codegen change needed: the default fn is a template fn, expanded at the
      call site at comptime — it never reaches any backend. All 3 backends type-check
      the example; commonJS runs it.

## F4 — migrate erika + example ✅
- [x] `libs/erika/src/root.bp`: `pub mod erika;` → `pub default mod erika;` (one decl
      = tree edge + default marker); `erika.bp`'s template fn → `pub default fn erika`;
      `botopink.json` ships `root.bp` so the `pub default mod` reaches consumers;
      `examples/erika-linq` → `import erika, {of} from "erika"`. The handler keeps the
      name `erika` so `generic-loader-binding`'s namespace form (`erika.of`) stays
      green (the alias is keyed by handle, not fn name — name independence is real,
      just not exercised by this lib). erika lib (commonJS), erika-linq (9), and
      generic-loader-binding (3) all green.

## Done gate ✅
- [x] `pub default mod erika;` parses at any module top level (not root-only); a
      duplicate default mod/fn in one package errors; `import erika` forms parse;
      `erika "select …"` + `erika """ … """` produce the same result as today on commonJS.
- [x] `zig build && zig build test` green; erika lib tests + `examples/erika-linq` green.
      (erlang erika reds are pre-existing `Query<T>` method codegen gaps — backends-parity scope.)
