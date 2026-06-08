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

**Completion, not new direction.** Finish what the earlier sets proved out:

- **Strand 1 — backends & tooling (carryover).** The other backends
  (erlang/beam/wasm) for the established method lowering + dispatch stragglers +
  inference correctness (Part A); the backend-parity F1–F6 still open from
  v0.beta.3 (Part B); editor-experience F0–F5 (Part C).
- **Strand 2 — application frameworks.** Bring cross-module codegen to backend
  parity, give rakun its comptime DI container / router / bootstrap, and land the
  language ergonomics jhonstart's API needs.

## Features (v0.beta.6)

| Spec | Slug | Depends on |
|---|---|---|
| [stdlib-backends-and-tooling — finish backends + dispatch + editor tooling](specs/stdlib-backends-and-tooling.md) | `stdlib-backends-and-tooling` | v0.beta.4 carryover (JS path done) |
| [cross-module-codegen — concrete types across the package boundary](specs/cross-module-codegen.md) | `cross-module-codegen` | nothing (commonJS done) |
| [rakun-ioc-web — comptime DI container + router](specs/rakun-ioc-web.md) | `rakun-ioc-web` | nothing (rakun foundation in feat) |
| [rakun-bootstrap — `Rakun.run` + real HTTP backing](specs/rakun-bootstrap.md) | `rakun-bootstrap` | `rakun-ioc-web` |
| [jhonstart-language-gaps — record/array ergonomics](specs/jhonstart-language-gaps.md) | `jhonstart-language-gaps` | nothing |

## Dependency DAG

```text
stdlib-backends-and-tooling   (Part A backends · Part B backend-parity · Part C editor)

cross-module-codegen          (commonJS landed; erlang/beam/wasm parity)

rakun-ioc-web  ── F2 IoC container · F3 annotation args · F4 router
       └────────► rakun-bootstrap  ── F5 Rakun.run ──► libs/server (HTTP backing)

jhonstart-language-gaps  ── G1 fn-typed fields · G2 anon record types
                            G3 fn() -> T[] · G4 Children coercion
```

## Scope boundaries

- **rakun**: constructor injection only, singleton scope only — no prototype/
  request scopes, AOP, or runtime reflection. Wiring stays **comptime**.
- **cross-module-codegen** mirrors the commonJS behaviour already in `feat`;
  `new` is an emitted-JS detail, never botopink source. wasm may defer if
  single-module — record the limit rather than fake it.
- **jhonstart-language-gaps** are *language* features (general), merely surfaced
  by jhonstart. jhonstart's own F4–F5 (SSR/loaders) stay gated on the async
  specs in `tasks/v0.beta.1/`, out of this set.
- Tests for libraries live in the library's own `.bp` files (`botopink test`),
  not in the compiler's Zig suites.
