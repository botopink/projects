# v0.beta.8 — finish the frameworks

> A set with **one focus**: complete what v0.beta.7 started. The core now offers
> **two generic ways a lib extends the language** — embedded sub-language template
> DSLs (`html """…"""`, `erika "…"`) and annotation processors (`@Decl` decorators:
> `rakun`, `onze`) — plus the generic loader. This set closes the last generic gap
> that blocks bare-imported sub-languages cross-module, then ships the client libs on
> both mechanisms and the non-JS backend parity — all lib-side / std-only, **zero new
> framework knowledge in the core**. See [`../AGENTS.md`](../AGENTS.md) for the rules.
> Live progress → [`status.md`](status.md).

## Context — where v0.beta.7 left off

v0.beta.7 made `modules/compiler-core/src/**` lib-agnostic: the annotation-processor
mechanism (`@Decl` reflection + decorator invocation + `@emit`), the generic
`from "<lib>"` loader, the lib-agnostic gate. The lib ports advanced unevenly:

- **erika** — the lib is done (out of `std`, on the loader, ~30 in-file tests), but
  it ships **no runnable example** and the cross-module `erika "…"` form is unbound.
- **rakun** — F3 placement bodies merged; the DI/router/bootstrap **wiring** (F2/F4/F5)
  is still to write.
- **jhonstart** — stood up as a pure client; the `html` DSL (F2) was **deferred**.
- **stdlib-backends-parity** — A1 erlang + A3 inference + the literal-receiver
  parser merged; beam/wasm lowering + Part B codegen tails remain.

All of v0.beta.7 is merged into `feat` and **frozen as history**; this set advances
the unfinished pieces — and adds one **new** lib, `onze` (a Mockito-style mocking
layer for tests), as further proof the generic `@Decl`/`@emit` mechanism carries an
ecosystem lib with zero core changes.

## The principle (carried from v0.beta.7)

- **The core provides a mechanism; the lib defines *and* acts.** No non-std lib name
  enters `compiler-core`. rakun/jhonstart implement every behaviour in `.bp`.
- **`std` may be coupled; other libs may not.** `stdlib-backends-parity` is the one
  spec allowed to touch std/core — it is backend parity, not a framework.
- **Enforced gate:** `grep -riE "rakun|jhonstart|erika" modules/compiler-core/src`
  returns nothing (std exempt) — already shipped as a test in v0.beta.7.

## The shape of the set — two generic mechanisms, their client libs

v0.beta.7 left the core with **two generic ways a lib extends the language**, and
every spec here is either one of those mechanisms' enabler or a client of it:

- **Embedded sub-language template DSLs** — a template fn
  `fn(comptime q: @Expr<string>) -> @Expr<T>` whose string argument is a *mini
  language* (markup, SQL) parsed at comptime and expanded into botopink, with its
  references resolved in the **caller's scope**. `html """…"""` (markup → Element)
  and `erika "…"` (SQL → Query) are **the same mechanism**, sibling DSLs.
- **Annotation processors** — a decorator fn `fn(comptime decl: @Decl, …)` that
  reflects the declaration it annotates and contributes generated code via `@emit`.
  `rakun` (DI/router/bootstrap) and `onze` (mocking) are **the same mechanism**,
  sibling libs.

Both mechanisms need the loader to bind a **bare imported** template-fn / decorator
cross-module — the keystone. Backend parity is the one orthogonal, core-touching
strand. So the six specs group into **keystone → two DSL clients · two
annotation-processor libs · backend**:

| Group | Spec | Slug | Depends on |
|---|---|---|---|
| **keystone** | [generic-loader-binding — bind bare template fns + emit the disk-lib namespace](specs/generic-loader-binding.md) | `generic-loader-binding` | nothing |
| **sub-language DSLs** | [jhonstart-html — `html """…"""` markup → Element tree](specs/jhonstart-html.md) | `jhonstart-html` | [`generic-loader-binding`](specs/generic-loader-binding.md) |
| **sub-language DSLs** | [erika — `erika "…"` SQL DSL + runnable example](specs/erika.md) | `erika` | [`generic-loader-binding`](specs/generic-loader-binding.md) |
| **annotation-processor libs** | [rakun — IoC container + router + bootstrap (F2·F4·F5)](specs/rakun.md) | `rakun` | nothing |
| **annotation-processor libs** | [onze — Mockito-style mocking + verification](specs/onze.md) | `onze` | nothing |
| **backend** | [stdlib-backends-parity — beam/wasm lowering + dispatch + literal-receiver codegen](specs/stdlib-backends-parity.md) | `stdlib-backends-parity` | nothing |

> One spec per **parallel-touchable unit** (Eric's granularity rule): `html` and
> `erika` share a *mechanism* but live in disjoint libs (`libs/jhonstart` vs
> `libs/erika`), so they stay separate specs — mutually parallel once the keystone
> lands. Same for `rakun`/`onze`.

## DAG — keystone feeds the two sub-language DSLs; everything else is parallel

```text
                          ┌─►  jhonstart-html   (html """…""" markup → Element tree)
generic-loader-binding  ──┤      embedded sub-language DSLs — same template-fn
  (binds the bare         └─►  erika            mechanism, caller-scope resolution
   template fn so               (erika "…" SQL → Query; + runnable example)
   `foo "…"` works
   cross-module; emits     · · · · · · · · · · · · · · · · · · · · · · · · · · · ·
   the disk-lib            rakun   (DI graph + router + Rakun.run; @Decl/@emit)
   namespace object)       onze    (mock(T)/when/verify; @Decl/@emit + host cells)
                              └ annotation-processor libs — mechanism already in feat

                           stdlib-backends-parity   (beam/wasm + Part B; core/std)
```

The only edges are `generic-loader-binding → {jhonstart-html, erika}` — the two
embedded sub-language DSLs both need their bare `foo "…"` template fn bound
cross-module. The annotation-processor libs (`rakun`, `onze`) build on the
`@Decl`/`@emit` mechanism already in `feat`; `stdlib-backends-parity` is core/std
backend work. Everything but those two edges runs in parallel.

## Scope boundaries

**Keystone**
- **generic-loader-binding** — generic core work (import resolver / template-fn
  rehydration + disk-lib namespace codegen), std-exempt, no lib name. Land it first:
  it is what makes a bare-imported `foo "…"` sub-language work cross-module.

**Sub-language DSLs** (template fns; built on expr-templates + the keystone)
- **jhonstart-html** — promote `html.d.bp` → `html.bp`:
  `html """…""" -> @Expr<Element>` (triple-quoted markup authoring surface, Element
  output), lowercase tags resolved to builders **in the caller's scope**, native-JS
  -only comptime parser. Lib-side only; `<Component/>` lookup is a future layer.
- **erika** — finish the port to the **same bar**: `erika "…"` / `erika """…"""`
  SQL sub-language resolving its collection in the caller's scope, plus the missing
  runnable `examples/erika-linq/`. The lib (Query<T> + the SQL template) is done;
  example/docs + the cross-module binding only, no new operators.

**Annotation-processor libs** (decorator fns; built on `@Decl`/`@emit`, in `feat`)
- **rakun** — the F2/F4/F5 wiring in `.bp` via `@emit` (component scan + DI graph +
  cycle diagnostic + router + `Rakun.run`) over a real minimal `libs/server` (node
  first, then erlang). No new core code.
- **onze** — new pure-`.bp` lib: `mock(T)`/`when`/`verify` via `@Decl` reflection +
  `@emit` (mock synthesis) and `#[@external]` host cells (stub table + call log).
  Proof the mechanism handles mocking, not just DI.

**Backend** (the one core/std-touching strand)
- **stdlib-backends-parity** — v0.beta.7 remainder: A1b beam/wasm lowering, A2-rest
  `@[external]` assoc fns, Part B (literal-receiver codegen, snake→camel, beam std
  loading, `?.` beam/wasm, wasm test runner). Stdlib coupling allowed.

- **Library tests live in the library's own `.bp` files** (`botopink test`), never
  in the compiler's Zig suites.
