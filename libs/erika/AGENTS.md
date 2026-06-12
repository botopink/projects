# erika

> Path: `libs/erika/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)
> Spec: [`../../tasks/v0.beta.7/specs/erika.md`](../../tasks/v0.beta.7/specs/erika.md)

A **C#/LINQ-style query library** for botopink — a fluent, eager, immutable
`record Query<T>` over `Array<T>`, plus an `erika "…"` SQL-subset **template fn**
that expands (at comptime) to the same fluent pipeline. It is **pure botopink**:
zero compiler surface, no decorators, no host backing. erika is the proof that
the generic `from "<lib>"` loader works for an ordinary (non-framework) external
package, exactly as `rakun` is the proof for a decorator-driven one.

**Not std.** erika shipped *inside* `std` in v0.beta.6 only to dodge the per-lib
import machinery rakun then needed. v0.beta.7 replaced that with one generic
loader, so erika graduated to its own package: it is reached **only** through
`import {…} from "erika"` — no `std_pkg_files` entry, no `@embedFile`, no
`modules/compiler-core` mention (the lib-agnostic gate in `build.zig` covers
`erika` too).

## Tree

```text
erika/
├── AGENTS.md          ← you are here
├── docs.md            ← what this lib provides + the grammar + loading notes
├── examples.md        ← both forms (fluent + `erika "…"`), runnable
├── botopink.json      ← package metadata (files: ["root.bp", "erika.bp"])
└── src/
    ├── root.bp        ← module-tree root: `pub default mod erika;` (public +
                         DEFAULT surface — the `import erika` handle)
    └── erika.bp       ← the whole lib: `record Query<T>` + `Grouping<K,V>` +
                         constructors + the `pub default fn erika` template fn
                         (lexer + parser + dual lowering) + 29 tests
```

## Module tree (`root.bp`) + the package handle

`src/root.bp` is the explicit module-tree root: `pub default mod erika;` declares
the single public module AND marks it the package's DEFAULT module (the
`import erika` handle), so the package builds from the tree, not a deprecated
blind `src/` scan. A consumer reaches the named items via `import {…} from "erika"`
(the generic `from "<lib>"` loader), and binds the SQL DSL with `import erika`
(package-default-dsl): the handle `erika` resolves to the package's
`pub default fn erika`, so a bare `erika "…"` tagged call expands through the
ordinary template path. (The driver keys the alias by the *handle*, not the fn
name, so a handler need not share the lib's name; this lib keeps the name `erika`
so the generic-loader namespace form `erika.of(…)` still resolves through it.)
Both `root.bp` and `erika.bp` are listed in `botopink.json` `files` — the
`pub default mod` declaration only reaches consumers if its module ships.

## Design at a glance

- **`record Query<T> { items: Array<T> }`** — every operator returns a *new*
  `Query<U>` over a freshly materialized array (eager + immutable, like `sets`).
  Terminals return scalars, `?T`, or `Array<T>`.
- **Constructors** are top-level `pub fn` (`of`/`range`/`repeat`/`empty`). `from`
  is the import keyword and cannot name a function, so the wrapper is `of`.
- **No arity overloading** (the JS backend mangles same-named methods), so the
  predicate variants are spelled out: `count`/`countWhere`, `first`/`firstWhere`,
  `any`/`anyWhere`.
- **`erika "…"`** is a template fn returning **`@ExprCustom<T>`**: it captures a
  SQL-subset string as `@Expr<string>` and runs a real three-stage front-end at
  comptime — ① a char-by-char **lexer** (`q.text()` → `Token[]`, every token
  span-aware), ② a recursive-descent-style **parser** (tokens → a `SelectStmt`
  value; the `where` clause is split into `or`-of-`and`-of-comparison groups so
  the `or < and < comparison` precedence is structural), then ③/④ **dual lowering**
  of the *same* parse. Grammar:
  `select <* | f1[, f2…]> from <Name> [where <cond>] [order by <field> [asc|desc]]`.
  The single-line `erika "…"` and triple-quoted multi-line `erika """ … """` forms
  are equivalent — the lexer treats newlines/tabs as ordinary token boundaries, so
  layout is free (the `html """…"""` sibling).
- **Lowering ③ → `@Expr<T>` (the executable pipeline).** Walks the `SelectStmt`
  into unqualified fluent source
  (`of(Name).where({row -> …}).orderBy(…).select(…).toArray()`) and splices it via
  `q.build(...)`. Behaviour is **byte-for-byte the same** as the pre-refactor
  scanner (single-field projection unwraps, multi-field → `record {…}`, `*` →
  `toArray()`, `=`→`==`, `<>`→`!=`, `and`→`&&`, `'x'`→`"x"`), so runtime/codegen
  across all backends is unchanged and the ~30 in-file + `examples/erika-linq`
  tests stay green.
- **Lowering ④ → `CustomNode` for tooling (sublanguage-lsp).** Walks the same
  tokens into a generic reference tree: keywords → `keyword`, idents
  (projected fields / source / columns) → `property`, string/number literals →
  `string`/`number`, comparison/logical ops (`= <> < <= > >= and or`) →
  `operator`. The source node carries `ref` (the `q.lookup` binding) so the LSP
  resolves hover/go-to-def to its declaration. Spans are byte offsets into
  `q.text()`, assigned by the lexer (no `indexOf`/`cursor` recovery any more). An
  unknown collection — or a malformed condition (a dangling operator) — aborts
  with `q.failAt(span, …)` ranged at the offending token, not the whole template.

## Conventions

- **Pure `.bp`, zero core surface.** The only compiler dependency is the
  *generic* loader; erika adds no Zig and is named nowhere in `compiler-core`.
- **Imported, never prelude.** Reached via `from "erika"` — the CLI's generic
  loader (`compiler-cli/src/cli/libs.zig`) resolves `dependencies: ["erika"]` to
  `libs/erika/src/erika.bp` as the `erika/erika` package module. No per-lib
  registry, no embed.
- **Tests live here.** 25 `test { … }` blocks inside `src/erika.bp`, run by
  `botopink test` from this directory — not in the compiler's Zig suites. The
  cross-module consumer story lives in [`examples/erika-linq/`](../../examples/erika-linq/)
  (`botopink test` green there too).
- Keep this file, `docs.md`, `examples.md`, and the spec in sync in the same
  change that touches the lib.

## Comptime-eval constraint (why the `erika "…"` parser is written the way it is)

The `erika "…"` body runs at comptime in `template_eval.zig`: the evaluator emits
**only the template fn itself** (over a *minimal* `node` prelude that defines just
`Span` / `CustomNode`) and runs it. This shapes the whole front-end:

- **No sibling calls, no named-record constructors.** Only `erika` is emitted, so
  the lexer/parser/lowering are all **inlined** in one fn body (helpers are local
  closures, `val f = { … }`), and the private SQL "AST" is modelled with
  **anonymous `record { … }`** values (which lower to plain JS object literals) —
  a named `record Token {…}` would emit `new Token(…)`, undefined in the eval.
- **Native-JS ops only:** `split` / `join` / `slice` / `map` / `filter` / `append`
  / `+` / `==`, plus array `.length` (a *property*). Host-helper-backed ops are
  **undefined** in the eval script (they fail the expansion as a terse "parse
  error") — notably optional `.at(i).unwrapOr(…)`, so positional access into a
  small token list is a counter `loop (toks) { t, idx -> }` (the two-param form
  binds the **index**), and "optional" `where`/`order` are 0-length-list sentinels.
- **`string.length()`** (a method needing a JS-property rename) does **not** exist
  in the bare prelude — use `s.split("").length` (an array property) for a
  string's length (`sqlLen`).
- **No comments inside a closure/loop body** (`{ x -> … }`) — they parse as an
  unexpected token; keep comments at fn-body level.
- **A lambda's last statement must be an implicit-return expr** (identifier /
  call / record / binary), **not a bare `if`** — assign the `if` to a `val` and
  end the closure with that `val` (e.g. `cmpCode` / `operandCode`).

Two language-wide parser quirks the body works around (both confirmed while
landing erika-query-ast):

- A top-level binary boolean **directly inside an `if (…)` condition fails to
  parse** (e.g. `if (a && b)`). Extract the compound to a `val` first, then
  `if (theVal)`.
- **`(expr).method()` fails to parse** — a parenthesized expression followed by a
  method call. Bind it to a `val` first (`val padded = sql + " "; padded.split("")`).

One **comptime type-checker** quirk (not a parse error) also shaped the lexer:
appending **records from three-plus branchy `toks.append([record {…}])` sites**
mis-unifies the array element and reports `type mismatch: expected string, got
array`. The lexer therefore emits every token through a **single** `append` site
(the `pending` flush), classifying the kind there rather than at distinct
per-kind sites.

## Status (v0.beta.8)

- **Fluent layer** — complete; all ops covered by tests.
- **`selectMany` (flatMap)** — **landed.** Selector typed `fn(item: T) -> Array<U>`;
  unblocked by `fn() -> T[]` in a function-type parameter (gap **G3**, landed in `feat`).
- **Multi-field projection** (`select a, b`) — **landed.** Two-or-more fields project
  an anonymous structural `record { a: row.a, b: row.b }` per row; unblocked by
  anonymous record types (gap **G2**, landed in `feat`). A single field projects
  the bare column; `*` returns whole rows. Commas may be attached (`a, b`) or
  spaced (`a , b`) — the lexer treats each as its own token regardless.
- **Real lexer + parser + dual lowering** (`erika-query-ast`, v0.beta.11) —
  **landed.** The old `split`/`join` + `mode` scanner is replaced by a char-by-char
  lexer (`Token[]` with real spans), a parser producing a `SelectStmt` value (the
  `where` clause an `or`-of-`and`-of-comparison tree, so precedence is structural),
  and two lowerings off the same parse: ③ the executable `@Expr<T>` pipeline
  (behaviour identical to before) and ④ the `CustomNode` reference tree. New tests
  cover `and`/`or`/precedence/`<>` (`where precedence is or over and over
  comparison`, …); `q.failAt` at the offending token is implemented but not
  asserted in a `.bp` test (a malformed query would abort that module's compile) —
  the generic failAt-at-span path is covered by the sublanguage-lsp Zig fixtures.
- **Cross-module `erika "…"` (package handle)** — **landed (v0.beta.8, package
  binding v0.beta.14).** A consumer binds the package with `import erika, {of}
  from "erika"`: `erika` is the package handle (`ImportDecl.package`) and resolves
  to the package's `pub default fn query` (`package-default-dsl`), so
  `erika "select …"` (and the triple-quoted multi-line form) expand in a consumer
  module, resolving the collection in the caller's comptime scope. The driver
  (`comptime.zig`) aliases the handler under the handle and `resolveImports` binds
  it — generic, not erika-aware. (Before v0.beta.14 the consumer named the fn
  directly, `import {erika} from "erika"`, relying on a `pub fn erika` whose name
  matched the lib; that name-matching `pub fn` is now dropped.) Exercised by
  [`examples/erika-linq/`](../../examples/erika-linq/) and
  [`examples/generic-loader-binding/`](../../examples/generic-loader-binding/).
  Still zero core surface here: the binding is generic loader work, not erika-aware.

### Recorded gaps

- **`erika "…"` resolves only `val` collections, not `var`.** The template reads
  the caller's *comptime* scope snapshot, which captures immutable `val` bindings
  only, so `erika "select … from listas"` where `listas` is a `var` does not
  resolve. The **fluent** form (`of(listas)` / `erika.of(listas)`) is an ordinary
  runtime call and queries any `var` or `val` array (covered by the
  `select over a var listas …` tests). Making the string form see `var`s is
  comptime scope-snapshot work in core — out of scope here.
- **Interpolated queries** (`erika "… where age >= ${min}"` via `q.parts()`
  Text/Interp) — the next extension, unchanged from v0.beta.6. Record, don't build.
- **`average`** takes an `f64` selector (no `i32 → f64` cast exists); `range` /
  `repeat` build their arrays by **recursion** (the `Array.range`/`Array.repeat`
  producers aren't lowered by the commonJS backend).

## See also

- The spec (intent, steps, test scenarios) → [`../../tasks/v0.beta.7/specs/erika.md`](../../tasks/v0.beta.7/specs/erika.md).
- The generic loader erika is a client of → [`../../modules/compiler-cli/src/cli/libs.zig`](../../modules/compiler-cli/src/cli/AGENTS.md).
- The decorator-driven sibling client → [`../rakun/AGENTS.md`](../rakun/AGENTS.md).
