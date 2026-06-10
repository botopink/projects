# v0.beta.8 — working notes

One focus: **finish the frameworks.** v0.beta.7 made the core lib-agnostic and
shipped the generic mechanism; this set closes the last generic gap and completes
the work that mechanism enabled — rakun's wiring, jhonstart's `html` DSL, the
non-JS backend parity. Still: `std` is the one coupled exception, every other lib
is a pure `.bp` client.

## Why this set (from the v0.beta.7 consolidation, 2026-06-10)

All five v0.beta.7 tasks merged into `feat` and froze. Three left a tail:
- **rakun** — only F3 (decorator placement) landed; the DI/router/bootstrap wiring
  (F2/F4/F5, all `@emit`) is unwritten.
- **jhonstart** — F2 (the `html` DSL) was deferred behind two generic gaps.
- **stdlib-backends-parity** — erlang + inference + the literal-receiver parser
  landed; beam/wasm + Part B codegen remain.

Plus the one generic gap both erika and jhonstart recorded: the disk loader binds a
lib's namespace but not its **bare** imported symbols.

## Granularity rule applied (Eric)

> "separe em spec diferentes só aquilo que pode ser tocado em paralelo"

- **generic-loader-binding** = the one generic core gap (import resolver), its own
  spec, `Depends on: nothing`. Keystone — it unblocks the bare-import call form for
  every non-std lib at once (`erika "…"`, jhonstart's `html "…"`).
- **jhonstart-html** waits on it (bare `html`), then does lib-side-only work in
  `libs/jhonstart/html.bp`. One real edge.
- **erika** (added 2026-06-10) waits on the same keystone (cross-module `erika "…"`),
  then ships a runnable `examples/erika-linq/` consumer + docs. The lib itself is
  done; this finishes the *port*. One real edge, shared keystone with jhonstart-html.
- **rakun** is independent — the mechanism + F3 are already in `feat`, so its F2/F4/F5
  wiring needs no new core. `Depends on: nothing`.
- **onze** (added 2026-06-10) is a new pure-`.bp` lib on the same `@Decl`/`@emit`
  mechanism — a separate spec because it touches a disjoint lib (`libs/onze/`), and
  `Depends on: nothing` since the mechanism + loader are in `feat`.
- **stdlib-backends-parity** is genuinely parallel (codegen emitters + stdlib regions
  of inference). `Depends on: nothing`.

Six specs, two DAG edges (both onto the keystone). Everything else parallelizes.

## generic-loader-binding

`from "<lib>"` resolves the lib and binds its namespace (`Lib.member`), but a bare
`import {html} from "jhonstart"` leaves bare `html` unbound — only `jhonstart.html`
resolves. Same gap blocks `erika "…"`. Fix is generic: bind each named import into
value scope (values, fns, **template fns** via `registerImportedTemplateFn`) — the
disk-loader mirror of the same-project import path (and of `registerImportedDecorator`).
Std already binds bare imports; this brings disk-loaded libs to parity. No lib name
in core.

## jhonstart-html

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

## rakun

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

## erika

The lib is complete (`libs/erika/src/erika.bp`, ~30 in-file tests for the `Query<T>`
fluent layer + the `erika "…"` SQL template), but the **port** isn't finished: there
is no `examples/erika-*` runnable project (every other lib has one), and the
cross-module `erika "…"` form is unbound (the in-lib tests pass because they share
the module's comptime scope; a consumer's bare `erika` needs generic-loader-binding).
This ships `examples/erika-linq/` — a real `from "erika"` consumer with the fluent
pipeline (works today) + the SQL form (after the keystone) + tests — and re-points
`examples.md` at it. No new operators; if a gap surfaces, fix it in `libs/erika/*.bp`.

## onze

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

## stdlib-backends-parity

v0.beta.7 remainder. A1b: port the erlang method lowering to `beam_asm.zig`/`wat.zig`;
extend `std_erlang.sh` parity (the erika LINQ blockers — structural equality, option
chaining, `case…of` — are the long pole). A2-rest: `@[external]` associated fns +
host modules. Part B: literal-receiver **codegen** (parser already in `feat`),
snake→camel dispatch, beam std loading, `?.` on beam/wasm, the wasm test runner.
Backend parity only — `commonJS`/`erlang` are the reference; record limits rather
than fake them.
