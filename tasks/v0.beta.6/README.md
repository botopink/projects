# v0.beta.6 — finish what's left (backends · tooling · frameworks)

> A batch of independent specs. See [`../AGENTS.md`](../AGENTS.md) for the rules
> (3-layer model, slug, workflow). Live progress → [`status.md`](status.md)
> (this README carries **no** status column).

## Context — where v0.beta.4 + v0.beta.5 left off

Two strands converge here:

- **v0.beta.4** (`tasks/v0.beta.4/specs/carryover.md`) drove the stdlib-interface
  migration's **JS path** to completion — every primitive's instance methods
  (`Array`/`Bool`/numeric tower/`String`) and the associated functions
  (`Pair.of`, `Function.compose`) run on node. What's left is the *other*
  backends, the dispatch stragglers, and the editor tooling.
- **v0.beta.5** turned botopink outward to its first application libraries —
  `libs/jhonstart` (frontend) and `libs/rakun` (backend). Their **foundations**
  landed (`from "rakun"` + a real emitted `http.bp`, `#[decorator]` resolution,
  the commonJS cross-module codegen leg) and the build surfaced the **gaps**: the
  rest of the cross-module codegen, rakun's container/web/bootstrap semantics,
  and the language ergonomics jhonstart needs.

## Theme

**The lib-agnostic core.** This set opened as *completion* work (finish backends,
tooling, and the v0.beta.5 frameworks). Building the frameworks out surfaced a
direction shift, set by Eric (2026-06-08):

> `modules/compiler-core/src/**` **must know zero libraries.** A framework
> (rakun, jhonstart, erika) is a pure-`.bp` lib built on **generic** compiler
> mechanisms — never as Zig passes that name a lib.

So the work split in two:

- **Landed (generic, lib-agnostic) — merged into `feat`.** The pieces that are
  pure language/stdlib/tooling and carry no lib knowledge: cross-module codegen
  parity (erlang/beam/wasm), the four jhonstart **language** gaps + the
  `implement`/`mutual-recursion` completeness fixes (generic features merely
  *surfaced* by jhonstart), `erika` (a pure-`.bp` std module + a **data-driven**
  std package registry, so the core names no individual std module), and the
  editor tooling + the `s.contains`→`includes` dispatch.
- **Re-aimed (the new direction) — advanced to [v0.beta.7](../v0.beta.7/).**
  rakun's interim foundation hard-codes `rakun` in the core; that is the
  **coupling to remove**. The keystone replacing it,
  [`annotation-processors`](../v0.beta.7/specs/annotation-processors.md)
  (decorators as **custom comptime fns** the lib both *defines and acts* on, over
  a generic `@Decl` handle + a generic package loader), and the rakun re-spec as
  its *client*, **moved to the v0.beta.7 set** — that is where they execute. The
  reference F2/F3 implementation stays on the `task/rakun` branch.

## Features (v0.beta.6)

These specs ran in parallel as separate `task/<slug>` branches and **landed in
`feat`** (generic, lib-agnostic work). The lib-coupled strand
(`annotation-processors` + `rakun`) **advanced to [v0.beta.7](../v0.beta.7/)** —
it is not listed here.

| Spec | Slug | Depends on |
|---|---|---|
| [stdlib-backends-and-tooling — finish backends + dispatch + editor tooling](specs/stdlib-backends-and-tooling.md) | `stdlib-backends-and-tooling` | v0.beta.4 carryover (JS path done) |
| [cross-module-codegen — concrete types across the package boundary](specs/cross-module-codegen.md) | `cross-module-codegen` | nothing (commonJS done) |
| [jhonstart-language-gaps — record/array ergonomics](specs/jhonstart-language-gaps.md) | `jhonstart-language-gaps` | nothing |
| [implement-completeness — `implement` parses & codegens in every form](specs/implement-completeness.md) | `implement-completeness` | nothing |
| [mutual-recursion — forward references between top-level fns](specs/mutual-recursion.md) | `mutual-recursion` | nothing |
| [erika — LINQ-style query lib + `erika "…"` query-string (`@Expr`)](specs/erika.md) | `erika` | nothing (pure `.bp` std module; `erika "…"` built on `@Expr`) |

> **Advanced to v0.beta.7:** [`annotation-processors`](../v0.beta.7/specs/annotation-processors.md)
> (the lib-agnostic-core keystone) and [`rakun`](../v0.beta.7/specs/rakun.md)
> (its client). See [`../v0.beta.7/README.md`](../v0.beta.7/README.md).

## Independent specs (no cross-spec ordering)

```text
stdlib-backends-and-tooling   (Part A backends · Part B backend-parity · Part C editor)

cross-module-codegen          (commonJS landed; erlang/beam/wasm parity)

annotation-processors + rakun ── advanced to v0.beta.7 (the lib-agnostic core)

jhonstart-language-gaps  ── G1 fn-typed fields · G2 anon record types
                            G3 fn() -> T[] · G4 Children coercion
implement-completeness   ── G5 array field in struct-implement body
                            G6 generic iface in `implement … for` · G7 struct-implement codegen bug
mutual-recursion         ── forward refs between top-level fns (renderToString ⇄ renderChildren)

erika                    ── F0 skeleton+wiring · F1 where/select · F2 take/skip/orderBy
                            F3 distinct/groupBy/zip · F4 aggregate/first/any
                            F5 `erika "…"` query string via @Expr template fn · F6 docs
                            (pure .bp std module over Array<T>; eager v1)
```

The lib-agnostic-core strand (`annotation-processors` → `rakun`) and its residual
coupling debt (the rakun foundation + `tests/jhonstart.zig`) moved to
[v0.beta.7](../v0.beta.7/) — that set owns the direction and its gate.

## Scope boundaries

- **cross-module-codegen** mirrors the commonJS behaviour already in `feat`;
  `new` is an emitted-JS detail, never botopink source. wasm may defer if
  single-module — record the limit rather than fake it.
- **jhonstart-language-gaps** are *language* features (general), merely surfaced
  by jhonstart. jhonstart's own F4–F5 (SSR/loaders) stay gated on the async
  specs in `tasks/v0.beta.1/`, out of this set.
- **implement-completeness** + **mutual-recursion** were surfaced going deeper on
  jhonstart (attaching `@Context` to `Element`, writing the recursive renderer) —
  G5/G6/G7 + the forward-reference gap, continuing the G1–G4 numbering. G7 is a
  *correctness bug* (an inline `struct implement` value's fields are dropped at
  runtime), latent because that form was only ever typecheck-tested. The shipped
  jhonstart V1 already sidesteps all of these (`record … implement @Context`,
  array-arg builders, an inlined recursive walk), so they unblock the *next*
  jhonstart phase rather than the current green core.
- **erika** is the most isolated spec: a pure-`.bp` std module (`libs/std/src/
  erika.bp`) plus two one-line wiring additions (`build.zig`, `prelude.zig`). The
  `erika "…"` query string is an `@Expr` template fn reusing the *already-shipped*
  expr-templates machinery — **no** `parser`/`comptime`/`codegen` edits, so it
  never collides with the language-gap specs. Multi-field projection is deferred
  *inside erika* (a future version), **not** borrowed from `jhonstart-language-
  gaps`'s G2 — erika waits on nothing.
- Tests for libraries live in the library's own `.bp` files (`botopink test`),
  not in the compiler's Zig suites.
