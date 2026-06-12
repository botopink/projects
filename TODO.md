# TODO — package-default-dsl

> Task branch `task/package-default-dsl` · spec
> [`tasks/v0.beta.14/specs/package-default-dsl.md`](tasks/v0.beta.14/specs/package-default-dsl.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on:** the parser layer already on `feat` (`593af55`): `pub default fn`
> (`FnDecl.isDefault`) + `import pkg` namespace forms (`ImportDecl.package`).

Goal: `pub default mod erika;` (declarable in ANY module, not root-only) +
`pub default fn` (the handler) + `import erika` so the `erika "…"` package-handle
DSL resolves to the package's default fn — replacing the name-matching `pub fn erika`.

## F0 — parser: `pub default mod`
- [ ] `pub default mod Name;` parses at any module top level (`ModDecl.isDefault`;
      mirror `checkDefaultFn`/`FnDecl.isDefault`). No root-only restriction.
- [ ] Validation: at most one `pub default mod` + one `pub default fn` per package
      (duplicate is the error, NOT the location).

## F1 — resolver: `import pkg` binds the package default
- [ ] `import pkg` / `import pkg from "pkg"` locate the package's `pub default mod`
      + its `pub default fn` (wherever in the package they're declared), and bind
      `pkg` → that fn (internal = local call, external = cross-module call).
- [ ] `import pkg, { a, b }` binds the default AND the named items.

## F2 — inference: `<pkg> "…"` resolves to the bound default
- [ ] A tagged `pkg "…"` / `pkg """…"""` where `pkg` is an imported package
      resolves to the bound `pub default fn`, via the existing `@Expr`/
      `@ExprCustom` template path.

## F3 — codegen ×3
- [ ] Emit the default fn once; lower `pkg "…"` per backend (local vs cross-module).

## F4 — migrate erika + example
- [ ] `libs/erika/root.bp`: `pub default mod erika;` + `pub default fn` (drop the
      name-matching `pub fn erika`); `examples/erika-linq` → `import erika;`.
      All erika tests + the example green.

## Done gate
- [ ] `pub default mod erika;` parses at any module top level (not root-only); a
      duplicate default mod/fn in one package errors; `import erika` forms parse;
      `erika "select …"` + `erika """ … """` produce the same result as today on commonJS.
- [ ] `zig build && zig build test` green; erika lib tests + `examples/erika-linq` green.
