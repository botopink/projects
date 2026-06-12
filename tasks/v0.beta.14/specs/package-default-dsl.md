# package-default-dsl — `pub default mod` + `pub default fn` + `import pkg`

**Slug**: package-default-dsl
**Depends on**: the parser layer already landed on `feat` (commit `593af55`):
`pub default fn` (`FnDecl.isDefault`) and the `import pkg [, { … }] [from "…"]`
namespace forms (`ImportDecl.package`). This spec adds **`pub default mod`** and
the resolver + codegen that make the three work together.
**Files**: `modules/compiler-core/src/parser/decls.zig`,
`modules/compiler-core/src/parser.zig`, `modules/compiler-core/src/ast.zig`,
`modules/compiler-core/src/comptime/infer.zig`, the module resolver
(`modules/compiler-cli/src/cli/sources.zig` / `libs.zig`), and the three codegen
emitters.
**Touches docs**: `modules/compiler-core/src/parser/AGENTS.md`,
`modules/compiler-core/src/comptime/AGENTS.md`, `modules/compiler-core/src/codegen/AGENTS.md`.
**Status**: pending.

## Goal

Let a package declare a *default module* and a *default function* that power the
package-handle DSL. Declarable at **any module's top level** (not restricted to
`root.bp`):

```bp
// any module in the erika package
pub default mod erika;        // the package's default module
pub default fn query(...) { } // the default handler the `erika "…"` DSL calls
```

Consumers bind the package by name and use the DSL:

```bp
import erika;                 // internal (same package) — binds `erika`
import erika from "erika";    // external (another package) — binds `erika`
import erika, { Query };      // package binding + named items

val rows = erika "select name from cities where pop >= 5";
val more = erika """ … multi-line … """;
```

`erika "…"` already parses to a tagged call `erika(<string>)` (parser
`exprs.zig:1021`); today it only resolves if a function literally named `erika`
is in scope. The new contract: **`import erika` binds the `erika` package's
`pub default fn` (wherever in the package it's declared) under the name `erika`**,
so the existing tagged-call + `@Expr`/`@ExprCustom` template machinery resolves it
unchanged.

`pub default mod erika;` names *which* module of the package carries that
`pub default fn` (the default surface), and is the thing `import erika` resolves
to. It may appear at **any module's top level** — there is no root-only
restriction (the package's build aggregates the declaration wherever it lives). A
package has at most one default module and one default handler fn; a second of
either in the same package is the only error to diagnose.

## Steps

### F0 — parser: `pub default mod`
- [ ] `pub default mod Name;` parses at **any module's top level** (no root-only
      restriction). `pub mod` / `mod Name;` parse today via `parseModDecl`; add the
      `default` modifier (mirror `checkDefaultFn` / `FnDecl.isDefault`):
      `ModDecl.isDefault`.
- [ ] `pub default fn` already parses anywhere (`FnDecl.isDefault`, on `feat`); keep
      it unrestricted too.
- [ ] Validation: at most one `pub default mod` and one `pub default fn` per
      package (a duplicate is the error — NOT the location).

### F1 — resolver: `import pkg` binds the package default
- [ ] When loading a package referenced by `import pkg` / `import pkg from "pkg"`,
      locate the package's `pub default mod` and its `pub default fn` (wherever
      in the package they are declared),
      and bind the name `pkg` (`ImportDecl.package`) to that fn. Internal
      (`import pkg`, same package, local call) vs external (`from "pkg"`,
      cross-module call) must both resolve.
- [ ] `import pkg, { a, b };` binds `pkg` (the default) AND the named items.

### F2 — inference: the `<pkg> "…"` DSL resolves to the bound default
- [ ] A tagged call `pkg "…"` (or `pkg """…"""`) where `pkg` names an imported
      package resolves its callee to the bound `pub default fn`, reusing the
      `@Expr<string>` / `@ExprCustom<T>` template path the current `erika "…"`
      uses (`registerImportedTemplateFn`, the comptime-eval constraints).

### F3 — codegen ×3
- [ ] Emit the package default fn once (in the package's default module) and lower
      `pkg "…"` to the right call on commonJS / erlang / beam (internal = local,
      external = the owner module's emitted symbol — reuse the cross-module index).

### F4 — migrate the reference lib
- [ ] Convert `libs/erika` to declare `pub default mod erika;` + `pub default fn`
      in `root.bp` instead of the name-matching `pub fn erika`, and update the
      `examples/erika-linq` consumer to `import erika;`. Keep all erika tests +
      the example green on commonJS (and erlang where it already compiles).

## Test scenarios

```
parser  ---- `pub default mod erika;` parses at any module top level (not root-only)
parser  ---- a 2nd `pub default mod` / `pub default fn` in one package is an error
parser  ---- `import erika;` / `import erika from "erika";` / `import erika, { Q };`
resolve ---- `import erika` binds the package's `pub default fn` as `erika`
run     ---- `erika "select …"` and `erika """ … """` produce the same result as the
             current name-matching template fn (commonJS reference)
```

## Notes

- `pub default mod` / `pub default fn` may be declared in **any** module of a
  package (no root-only restriction). A package has at most one default module and
  one default handler fn — enforce uniqueness, not location.
- No new runtime surface: this is a cleaner *declaration + binding* for the DSL
  that already works via `pub fn <pkgname>` + `import { <pkgname> } from "<pkg>"`.
- Memory: the `pub default fn` / `import pkg` parser layer is on `feat`
  (`593af55`); the package-DSL design came from the `stdlib-backends-parity`
  session (see `backends-parity-tail.md` item **P**).
