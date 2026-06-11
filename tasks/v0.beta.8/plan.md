# v0.beta.8 — working notes

One focus: **finish the frameworks.** v0.beta.7 left the core with **two generic
ways a lib extends the language** — embedded sub-language template DSLs
(`fn(comptime q: @Expr<string>) -> @Expr<T>`: `html """…"""`, `erika "…"`) and
annotation processors (`fn(comptime decl: @Decl, …)` + `@emit`: `rakun`, `onze`).
This set closes the last generic gap (bare-imported sub-languages cross-module),
ships the client libs on both mechanisms, and finishes the non-JS backend parity.
Still: `std` is the one coupled exception, every other lib is a pure `.bp` client.

## Why this set (from the v0.beta.7 consolidation, 2026-06-10)

All five v0.beta.7 tasks merged into `feat` and froze. Three left a tail:
- **rakun** — only F3 (decorator placement) landed; the DI/router/bootstrap wiring
  (F2/F4/F5, all `@emit`) is unwritten.
- **jhonstart** — F2 (the `html` DSL) was deferred behind two generic gaps.
- **stdlib-backends-parity** — erlang + inference + the literal-receiver parser
  landed; beam/wasm + Part B codegen remain.

Plus the one generic gap both erika and jhonstart recorded: the disk loader binds a
lib's namespace but not its **bare** imported symbols.

## Two mechanisms, grouped — and the granularity rule (Eric)

> "separe em spec diferentes só aquilo que pode ser tocado em paralelo"

The six specs group into the keystone + the two mechanism families + the backend:

- **keystone — generic-loader-binding** = the one generic core gap (import resolver
  / template-fn rehydration), `Depends on: nothing`. It binds a bare-imported
  template fn cross-module, so `foo "…"` works — the enabler for **both** embedded
  sub-language DSLs at once.

- **embedded sub-language DSLs** (template fns, built on expr-templates + keystone):
  - **jhonstart-html** — `html """…"""` markup → Element, lib-side in
    `libs/jhonstart/html.bp`. One edge to the keystone.
  - **erika** — `erika "…"` SQL → Query (same mechanism) + the missing runnable
    `examples/erika-linq/`. One edge to the keystone. The lib is done; this finishes
    the *port*.
  - Same mechanism, **disjoint libs** → two specs (the granularity rule); mutually
    parallel once the keystone lands.

- **annotation-processor libs** (`@Decl` decorators + `@emit`, mechanism in `feat`):
  - **rakun** — F2/F4/F5 DI/router/bootstrap wiring. `Depends on: nothing`.
  - **onze** — new Mockito-style mocking lib. `Depends on: nothing`.
  - Same mechanism, disjoint libs (`libs/rakun` vs `libs/onze`) → two specs, parallel.

- **backend — stdlib-backends-parity** — codegen emitters + stdlib regions of
  inference, the one core/std-touching strand. `Depends on: nothing`.

Six specs, two DAG edges (the two DSLs onto the keystone). Everything else parallelizes.

## generic-loader-binding  (keystone)

`from "<lib>"` resolves the lib and binds its namespace (`Lib.member`), but a bare
`import {html} from "jhonstart"` leaves bare `html` unbound — only `jhonstart.html`
resolves. Same gap blocks `erika "…"`. Fix is generic: bind each named import into
value scope (values, fns, **template fns** via `registerImportedTemplateFn`) — the
disk-loader mirror of the same-project import path (and of `registerImportedDecorator`).
Std already binds bare imports; this brings disk-loaded libs to parity. No lib name
in core.

## jhonstart-html  (sub-language DSL)

**Eric's model (2026-06-10):** the authoring surface is the triple-quoted string
template abandoned in the old `jonhstar` example —
`val page = html """<div><p>${name}</p></div>"""` — and `html` expands it into an
**Element tree**:

```bp
pub fn html(comptime template: @Expr<string>) -> @Expr<Element> { @todo() }
```

Input `@Expr<string>` (the `"""…"""` markup), output `@Expr<Element>` (the
`div`/`p`/`text` builder pipeline); lowercase tags → builders, `${…}` holes splice
the caller's typed expression as a child. The two v0.beta.7 blockers: the bare-import
binding is closed by `generic-loader-binding`; the markup parser is written with
native-JS-only comptime ops (no `?T`/Option — the eval has no Option runtime). If the
native-only parser proves infeasible, the recorded fallback is a generic
`comptime-eval-option` core spec — not opened unless needed. `<Component/>` lookup is
a future layer. Lib-side only, zero core.

## erika  (the sibling sub-language DSL)

Same mechanism as `html`, different mini-language. The lib is complete
(`libs/erika/src/erika.bp`, ~30 in-file tests for the `Query<T>` fluent layer + the
`erika "…"` SQL template), but the **port** isn't finished: there is no
`examples/erika-*` runnable project (every other lib has one), and the cross-module
`erika "…"` form is unbound (the in-lib tests pass because they share the module's
comptime scope; a consumer's bare `erika` needs generic-loader-binding). `erika "…"`
is an embedded SQL sub-language that, exactly like `html`, resolves its references
(the queried collection) in the caller's scope. This ships `examples/erika-linq/` —
a real `from "erika"` consumer with the fluent pipeline (works today, bare `of`
import) + the SQL form (after the keystone) + tests — and re-points `examples.md` at
it. No new operators; if a gap surfaces, fix it in `libs/erika/*.bp`.

## rakun  (annotation-processor lib)

The mechanism + F3 placement bodies are in `feat`. This set writes the wiring those
same decorators contribute, all `.bp` via `@emit`:
- **F2** component scan → DI graph (fields→edges) → topo-sorted singleton `val`s;
  cycle → `@compilerError`; `#[bean]` factories + `#[value]` props.
- **F4** controller walks `decl.methods`, reads `#[getMapping]` from
  `method.annotations`, `@emit`s the router table (+ `route` prefix, `:param`).
- **F5** `Rakun.run` `@emit`s the boot over a real minimal `libs/server` (node first,
  then erlang) — scan → instantiate singletons → register router → listen.
Port the *behaviour* from the preserved core-coupled `task/rakun` reference (`feb96f0`),
never the Zig.

## onze  (annotation-processor lib — the rakun sibling)

A new ecosystem lib: Mockito for botopink tests. `mock(T)` reflects `T`'s methods
via `@Decl` and `@emit`s a stub implementation that records each call and returns
the stub-table entry (or a type-default). `when(m.x()).thenReturn(v)` writes the
stub table; `verify(m, times(n)).x()` reads the call log; `any()`/`eq(v)` are arg
matchers. The recorder/stub-table is the one mutable seam — held behind
`#[@external]` host cells (a JS `Map`; erlang equivalent), which is fine for a test
lib (the *core* learns nothing). v1 = mock signatures + return stubbing + count
verification; spies / `thenAnswer` / in-order / captors are recorded follow-ups.
Pure `.bp` client, zero core code — the proof the mechanism carries mocking, not
just DI/router.

## stdlib-backends-parity  (backend)

v0.beta.7 remainder. A1b: port the erlang method lowering to `beam_asm.zig`/`wat.zig`;
extend `std_erlang.sh` parity (the erika LINQ blockers — structural equality, option
chaining, `case…of` — are the long pole). A2-rest: `@[external]` associated fns +
host modules. Part B: literal-receiver **codegen** (parser already in `feat`),
snake→camel dispatch, beam std loading, `?.` on beam/wasm, the wasm test runner.
Backend parity only — `commonJS`/`erlang` are the reference; record limits rather
than fake them.
