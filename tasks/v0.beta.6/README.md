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
- **Re-aimed (the new direction) — specs only, implementation deferred to a new
  set.** rakun's interim foundation hard-codes `rakun` in the core; that is the
  **coupling to remove**. The keystone replacing it is
  [`annotation-processors`](specs/annotation-processors.md): decorators become
  **custom comptime functions** (written in the lib, invoked by the core over a
  generic `@Decl` reflection handle) and `from "<lib>"` resolves through one
  **generic package loader**. rakun is then re-specified as a *client* of that
  mechanism. The reference F2/F3 implementation stays on the `task/rakun` branch.

## Features (v0.beta.6)

Most specs are **independent** and ran in parallel as separate `task/<slug>`
branches. The one real edge is the new direction: **`rakun` now depends on
`annotation-processors`** (it is re-specified as a client of that mechanism).
The originally-listed seven landed as generic work; `annotation-processors` is
the eighth, added by the direction shift and **pending** (a new set executes it).

| Spec | Slug | Depends on |
|---|---|---|
| [stdlib-backends-and-tooling — finish backends + dispatch + editor tooling](specs/stdlib-backends-and-tooling.md) | `stdlib-backends-and-tooling` | v0.beta.4 carryover (JS path done) |
| [cross-module-codegen — concrete types across the package boundary](specs/cross-module-codegen.md) | `cross-module-codegen` | nothing (commonJS done) |
| [annotation-processors — decorators as custom comptime functions (de-rakun the core)](specs/annotation-processors.md) | `annotation-processors` | comptime eval + expr-templates |
| [rakun — comptime DI container + router + bootstrap, **on annotation-processors**](specs/rakun.md) | `rakun` | [`annotation-processors`](specs/annotation-processors.md) |
| [jhonstart-language-gaps — record/array ergonomics](specs/jhonstart-language-gaps.md) | `jhonstart-language-gaps` | nothing |
| [implement-completeness — `implement` parses & codegens in every form](specs/implement-completeness.md) | `implement-completeness` | nothing |
| [mutual-recursion — forward references between top-level fns](specs/mutual-recursion.md) | `mutual-recursion` | nothing |
| [erika — LINQ-style query lib + `erika "…"` query-string (`@Expr`)](specs/erika.md) | `erika` | nothing (pure `.bp` std module; `erika "…"` built on `@Expr`) |

## Independent specs (no cross-spec ordering)

```text
stdlib-backends-and-tooling   (Part A backends · Part B backend-parity · Part C editor)

cross-module-codegen          (commonJS landed; erlang/beam/wasm parity)

annotation-processors    ── P0 generic package loader (de-rakun the core) · P1 recognition + arg
                            validation · P2 comptime invocation + @Decl reflection · P3 wiring (DI + router)
rakun  ──(needs)──►  annotation-processors
                              F2 IoC container · F3 annotation args · F4 router
                              F5 Rakun.run ──► libs/server (HTTP backing)
                              (built on annotation-processors; F5 boots F2–F4)

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

The cross-spec ordering is now the direction shift: **`rakun` is built on
`annotation-processors`**. The old internal ordering (`rakun-bootstrap` after
`rakun-ioc-web`) stays folded into the `rakun` spec — its F5 phase boots what
F2–F4 build, on one `task/rakun` branch over the same `libs/rakun/src/*.bp`
files.

## Scope boundaries

- **annotation-processors** is the keystone of the direction shift: it deletes
  the interim rakun foundation from the core (`registerRakunLib`,
  `markRakunImports`, `rakunExports`/`rakunTypeDecls`, `expandRakunImports`,
  `rakun_pkg_modules`, `isRakunPkgPath`, the `rakun.d.bp`/`http.bp` embeds, the
  `validateRakun*` passes) and replaces it with a generic package loader +
  decorator-as-comptime-fn protocol over a `@Decl` reflection handle. **Gate:**
  `grep -ri "rakun" modules/compiler-core/src` returns nothing. Spec is written;
  implementation is a **new set**.
- **rakun**: constructor injection only, singleton scope only — no prototype/
  request scopes, AOP, or runtime reflection. Wiring stays **comptime**, now
  expressed as lib-side decorator bodies on `annotation-processors` (not core
  passes). The spec's F5 (bootstrap) is its only leg needing a real HTTP backing
  (`libs/server`, scaffold → real, node first then erlang); it boots the F2–F4
  container/router.
- **Residual coupling debt (for the new set, not this consolidation).** Two
  lib-specific footprints remain in the core and must be removed by the new
  tasks: (1) the **rakun foundation** listed above (already on `feat` from
  v0.beta.5) — removed by `annotation-processors` P0; (2)
  `modules/compiler-core/src/comptime/tests/jhonstart.zig` — a jhonstart-named
  test in the compiler is a layering violation (see `jhonstart.md`), to be folded
  into the generic `effects.zig`/`templates.zig` + context-inference scenarios.
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
