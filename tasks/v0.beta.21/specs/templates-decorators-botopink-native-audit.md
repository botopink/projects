# templates-decorators-botopink-native — F0 audit

> Companion to [`templates-decorators-botopink-native.md`](templates-decorators-botopink-native.md). Frozen at meta `feat` 1c38772 / bot-lang `feat` 6b46f55 (2026-06-19). Re-grep if any new template/decorator body lands before F1 starts.

## Method

Exhaustive grep across:
- `repository/botopink-lang/libs/*/src/**/*.bp`
- `repository/botopink-lang/examples/**/*.bp`
- `repository/{emilia,erika,jhonstart,onze,rakun,vscode-extension}/src/**/*.bp`

A template body is any fn whose body executes at comptime via `@Expr<…>` / `@ExprCustom<…>` parameter binding. A decorator body is any fn that consumes the `@Decl` reflection cluster (typically annotated `#[@decorator]` or used as `#[@<name>]` on a target).

## Bodies

| File | Symbol | Kind | Surface used |
|---|---|---|---|
| `repository/botopink-lang/examples/yamlconf/yamlconf.bp` | `conf` | `@Expr` template | `anon-record`, `str-len`, `e.text`, `e.build` |
| `repository/erika/src/erika.bp` | `erika` | `@ExprCustom` template | `anon-record`, `nested-anon-record`, `list-literal`, `str-len`, `str-slice`, `str-eq`, `str-split`, `str-concat`, `string-multiline`, `val-chain`, `cond-if`, `iter-for`, `method-on-record`, `e.parts`, `e.lookup`, `e.build`, `e.failAt`, `e.custom`, `interp-q` |
| `repository/jhonstart/examples/jonhstar/src/jhonstart.bp` | `html` (local) | `@Expr` template | `str-concat`, `cond-if`, `e.parts`, `e.build` |
| `repository/jhonstart/src/html.bp` | `html` | `@ExprCustom` template | `anon-record`, `nested-anon-record`, `list-literal`, `str-len`, `str-slice`, `str-eq`, `str-split`, `str-concat`, `str-trim`, `val-chain`, `cond-if`, `iter-for`, `method-on-record`, `e.parts`, `e.lookup`, `e.build`, `e.failAt`, `e.custom` |
| `repository/onze/src/onze.bp` | `mock` | `@Decl` decorator | `anon-record`, `str-concat`, `cond-if`, `iter-for`, `method-on-record`, `decl.methods`, `decl.name`, `decl.fields`, `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `component` | `@Decl` decorator | `anon-record`, `str-concat`, `cond-if`, `iter-for`, `method-on-record`, `decl.fields`, `decl.name`, `decl.annotations`, `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `service` | `@Decl` decorator | `anon-record`, `str-concat`, `cond-if`, `iter-for`, `method-on-record`, `decl.fields`, `decl.name`, `decl.annotations`, `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `repository` | `@Decl` decorator | `anon-record`, `str-concat`, `cond-if`, `iter-for`, `method-on-record`, `decl.fields`, `decl.name`, `decl.annotations`, `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `controller` | `@Decl` decorator | `anon-record`, `str-concat`, `cond-if`, `iter-for`, `method-on-record`, `decl.fields`, `decl.name`, `decl.annotations`, `decl.kind`, `decl.methods`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `restController` | `@Decl` decorator | `anon-record`, `str-concat`, `cond-if`, `iter-for`, `method-on-record`, `decl.fields`, `decl.name`, `decl.annotations`, `decl.kind`, `decl.methods`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `configuration` | `@Decl` decorator | `anon-record`, `str-concat`, `cond-if`, `iter-for`, `method-on-record`, `decl.fields`, `decl.name`, `decl.annotations`, `decl.kind`, `decl.methods`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `bean` | `@Decl` decorator | `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `inject` | `@Decl` decorator | `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `value` | `@Decl` decorator | `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `route` | `@Decl` decorator | `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `getMapping` | `@Decl` decorator | `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `postMapping` | `@Decl` decorator | `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `putMapping` | `@Decl` decorator | `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `patchMapping` | `@Decl` decorator | `decl.kind`, `decl.fail` |
| `repository/rakun/src/decorators.bp` | `deleteMapping` | `@Decl` decorator | `decl.kind`, `decl.fail` |

20 bodies total: 4 templates + 16 decorators.

## Feature → F-phase

| Feature token | Phase | Notes |
|---|---|---|
| `anon-record` | F1 | `{ k: v, … }`, `CustomNode(…)`, `Span(…)`. Heap-allocated struct in linear memory. |
| `nested-anon-record` | F1 | Anon record as field of another (`CustomNode(span: Span(…))`). Same allocator path; second alloc threaded into outer's field. |
| `opt-null` | F2 | `?T`, `null` literal, `ref: null`. Tag 0/1 + payload. **Audit note**: no body in this audit explicitly uses `?T` in a value position — `ref: null` is the only appearance and it's the static-null encoding. F2 is still required for the `e.lookup(name) -> ?Span` capture method (F6) and for general WAT parity. |
| `list-literal` | F4 | `[a, b, c]` over `(i32 len, …)`. Length-prefixed; element-type implied by inferer. |
| `str-concat` | F3 | `+` between strings. |
| `str-len` | F3 | `.length`. |
| `str-slice` | F3 | `.slice(start, end)`. |
| `str-eq` | F3 | `==` between strings. |
| `str-split` | F3 | `.split(sep)`. Returns list of strings (depends on F4). |
| `str-trim` | F3 | `.trim()` (html.bp lexer). |
| `string-multiline` | F3 | `"""…"""` literals. Lex-time, no codegen difference — same bytes hit the WAT data section as a regular string literal. |
| `val-chain` | base | `val a = …; val b = …;` — base block lowering, no new phase. |
| `cond-if` | base | `if … else …` expression. WAT already supports. |
| `iter-for` | base / F4 | `for x in xs { … }`. Iteration over `list-literal` layout — codegen mostly already present, validated as F4 fixture. |
| `method-on-record` | F1 | `record.method(…)`. Lowering = direct call on the record's pointer, no vtable (templates instantiate one concrete type). |
| `interp-q` | F6 | `q.something(…)` on the @ExprCustom hole arg. Same mechanism as `e.*`. |
| `e.text` / `e.parts` / `e.source` / `e.context` / `e.lookup` / `e.bindings` / `e.build` / `e.custom` / `e.fail` / `e.failAt` | F6 | Capture object methods. Allocated as a heap record in WAT; each method is an exported `__capture_<name>(self, …)` fn. |
| `decl.kind` / `decl.name` / `decl.fields` / `decl.methods` / `decl.returnType` / `decl.annotations` / `decl.fail` / `decl.failAt` | F7 | `@Decl` reflection cluster. JSON-decoded once into a heap record. |
| `throw` / `try-catch` | F5 | Manual unwind protocol (per call-frame `(tag, payload_ptr)` slot). No body in this audit emits an explicit `throw`/`try`, **but** `e.fail` / `e.failAt` / `decl.fail` lower to `__failRaw`, which IS the throw protocol — so F5 is required by F6/F7 even though no template directly uses `throw`. |

## Out of audit set

**No out-of-scope features identified.** No body uses async/await, generators, generic trait dispatch on a non-receiver type, or generic functions with template-call-time-bound type parameters. The fallback-to-JS path in F8/F9 is therefore a safety net for the 1-release-cycle transition, not a load-bearing path for any known body.

## Known comptime gotchas observed (carry-over from `reference_bp_parser_comptime_gotchas`)

Already encoded in current `.bp` bodies — no new lowering work, but the WAT path must preserve them:

- No `?T` value destructuring in template bodies — `.slice(len-1, len).join("")` pattern (instead of `last`/`at`) for "last element of a list" in html.bp / erika.bp.
- No `.at(index)` — loops + counters used instead.
- No shared sibling fn calls across decorator bodies — all helpers inlined inside the decorator. F8/F9 keep this constraint (each template/decorator body is a closed translation unit).
- No comments inside `"""…"""` template bodies (preserved through emitter flattening).
- Anonymous record construction is always literal — no named-record `new`-style constructors anywhere in template bodies.

## Acceptance matrix

The cells below are the byte-equal fixtures each phase must produce. Each row corresponds to a body above; each column = an F-phase. ✓ = body uses the feature and the phase MUST cover it. (blank) = body does not need the feature.

| Body | F1 anon | F1 nested | F2 opt | F3 str | F4 list | F5 throw | F6 cap | F7 decl |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `yamlconf:conf` | ✓ | | | ✓ | | (via e.*) | ✓ | |
| `erika:erika` | ✓ | ✓ | | ✓ | ✓ | (via e.*) | ✓ | |
| `jhonstart:jhonstart:html` | | | | ✓ | | (via e.*) | ✓ | |
| `jhonstart:html` | ✓ | ✓ | | ✓ | ✓ | (via e.*) | ✓ | |
| `onze:mock` | ✓ | | | ✓ | ✓ | (via decl.fail) | | ✓ |
| `rakun:component/service/repository` | ✓ | | | ✓ | ✓ | (via decl.fail) | | ✓ |
| `rakun:controller/restController/configuration` | ✓ | | | ✓ | ✓ | (via decl.fail) | | ✓ |
| `rakun:bean/inject/value/route/*Mapping` (10) | | | | | | (via decl.fail) | | ✓ (kind+fail only) |

F8 + F9 byte-identity acceptance = every body above produces byte-identical `Outcome.code` / `Outcome.custom` via the WAT path vs. v0.beta.20 baseline.
