# v0.beta.8 — finish the frameworks

> A set with **one focus**: complete what v0.beta.7 started. The lib-agnostic core
> mechanism landed (annotation-processors + the generic loader); now close the last
> generic gap that blocks bare-import call forms, then finish the two frameworks
> (`rakun` wiring, jhonstart's `html` DSL) and the non-JS backend parity — all
> lib-side / std-only, **zero new framework knowledge in the core**. See
> [`../AGENTS.md`](../AGENTS.md) for the rules. Live progress → [`status.md`](status.md).

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

## Features (v0.beta.8)

Six specs. Only **what can be touched in parallel is a separate spec**: the one
generic core gap (`generic-loader-binding`) is the keystone the `html` DSL and the
cross-module `erika "…"` form wait on; `rakun`, `stdlib-backends-parity`, and the
new `onze` test lib are independent.

| Spec | Slug | Depends on |
|---|---|---|
| [generic-loader-binding — `from "<lib>"` binds bare values + template fns](specs/generic-loader-binding.md) | `generic-loader-binding` | nothing |
| [jhonstart-html — the `html """…"""` DSL → Element tree](specs/jhonstart-html.md) | `jhonstart-html` | [`generic-loader-binding`](specs/generic-loader-binding.md) |
| [erika — finish the port: runnable example + cross-module `erika "…"`](specs/erika.md) | `erika` | [`generic-loader-binding`](specs/generic-loader-binding.md) |
| [rakun — IoC container + router + bootstrap (F2·F4·F5)](specs/rakun.md) | `rakun` | nothing |
| [onze — a Mockito-style mocking + verification lib for tests](specs/onze.md) | `onze` | nothing |
| [stdlib-backends-parity — beam/wasm lowering + dispatch + literal-receiver codegen](specs/stdlib-backends-parity.md) | `stdlib-backends-parity` | nothing |

## DAG (one keystone, two client edges)

```text
generic-loader-binding  ──(binds bare `html`)──►  jhonstart-html
   (compiler-core: import resolver binds bare    │  (libs/jhonstart/html.bp:
    values/fns/template-fns from the disk loader,│   html """…""" → Element tree,
    std-exempt — closes erika "…" + bare html)   │   native-JS-only parser)
                                                 └─►  erika
                                                     (examples/erika-linq + the
                                                      cross-module erika "…" form)

rakun                   (libs/rakun/*.bp + libs/server: DI graph + router + Rakun.run
                         over a real HTTP backing — all lib-side @emit wiring; F3 done)

onze                    (libs/onze/*.bp: Mockito-style mock(T)/when/verify — mock
                         synthesis via @Decl/@emit + host-cell call recorder; pure client)

stdlib-backends-parity  (independent — beam/wasm method lowering + @[external] assoc
                         fns + literal-receiver codegen + ?./snake→camel/wasm runner)
```

`generic-loader-binding` is the keystone: it unblocks jhonstart's bare `html` import
**and** the cross-module `erika "…"` form (both bare template-fn bindings). `rakun`
and `onze` build on the `@Decl`/`@emit` mechanism already in `feat`;
`stdlib-backends-parity` is pure backend work. All strands but the two client edges
are mutually parallel.

## Scope boundaries

- **generic-loader-binding** is generic core work (import resolver / template-fn
  rehydration), std-exempt, no lib name. It is the keystone — land it first.
- **jhonstart-html** is lib-side only: promote `html.d.bp` → `html.bp` with the
  `html """…""" -> @Expr<Element>` body (string authoring surface, Element output),
  native-JS-only comptime parser. No core code; `<Component/>` lookup is a future
  layer.
- **erika** finishes the v0.beta.7 port: the lib itself is done (~30 in-file tests),
  but it ships **no runnable example** and the cross-module `erika "…"` form is
  unbound. This adds `examples/erika-linq/` (a real `from "erika"` consumer) and the
  cross-module SQL form once the keystone binds bare `erika`. Example/docs only, no
  new operators.
- **rakun** writes the F2/F4/F5 wiring in `.bp` via `@emit` (component scan + DI
  graph + cycle diagnostic + router + `Rakun.run`) over a real minimal `libs/server`
  (node first, then erlang). No new core code.
- **onze** is a new pure-`.bp` lib: `mock(T)`/`when`/`verify` built on `@Decl`
  reflection + `@emit` (mock synthesis) and `#[@external]` host cells (the stub
  table + call log). The proof the mechanism handles mocking, not just DI. No core
  code; tests live in `libs/onze/*.bp`.
- **stdlib-backends-parity** is the v0.beta.7 remainder: A1b beam/wasm lowering,
  A2-rest `@[external]` assoc fns, Part B (literal-receiver codegen, snake→camel,
  beam std loading, `?.` beam/wasm, wasm test runner). Stdlib coupling allowed.
- **Library tests live in the library's own `.bp` files** (`botopink test`), never
  in the compiler's Zig suites.
