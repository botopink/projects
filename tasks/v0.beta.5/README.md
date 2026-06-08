# v0.beta.5 — application framework spec set

> A batch of independent specs. See [`../AGENTS.md`](../AGENTS.md) for the rules
> (3-layer model, slug, workflow). Live progress → [`status.md`](status.md)
> (this README carries **no** status column).

## Context — where v0.beta.4 left off

The earlier sets closed the language core: the Gleam-style stdlib, generic
inference, the interface/method redesign, backend parity, and the editor
tooling. With the core stable, v0.beta.5 turns outward — to the first
**application-level** libraries written *in* botopink: a frontend UI framework
and a backend application framework.

## Theme

**Make botopink a viable application language**, on both ends of the stack, with
libraries that are expressed *through* the language's own primitives rather than
bolted on:

- **Frontend — `libs/jhonstart`** (React/Next-style). Components are plain
  functions returning `Element`; hooks are the `@Context<Element, _>` capability
  gated by `use`; data loading is `*fn` + `await`; an optional JSX-like `html`
  authoring DSL reuses `expr-templates` (`@Expr<Element>`) to resolve
  `<Component/>` tags in the caller's scope at compile time. Adds **no new
  compiler features** — it is a consumer.
- **Backend — `libs/rakun`** (Spring-style). Spring made Java the default for
  server apps by pairing a dependency-injection container with a declarative web
  layer. rakun brings that shape to botopink, leaning on the same comptime
  machinery (`@Expr`/`expr-templates`) so wiring is resolved at compile time
  rather than via runtime reflection.

The two are complementary (UI vs. server) and independent — they share only the
language and the "frameworks on primitives" philosophy.

## Features (v0.beta.5)

| Spec | Slug | Depends on |
|---|---|---|
| [jhonstart — React/Next-style UI framework](specs/jhonstart.md) | `jhonstart` | `use-await-prefix`, `async-generators` (compiler prerequisites) |
| [rakun — Spring-style application framework](specs/rakun.md) | `rakun` | nothing (F5 needs `libs/server` backing) |

## Dependency DAG

```text
                  (compiler prerequisites, cross-set)
use-await-prefix ─┐
async-generators ─┼──► jhonstart  ── F0–F3 core (Element · DOM builders · hooks · html DSL)
context-inference ┘                  └─ F4–F5 (SSR · server loaders) gated on async work
   (✅ context-inference, expr-templates already landed)

rakun  ── F0–F4 self-contained (HTTP types · IoC container · annotations · router)
         └─ F5 (bootstrap) ──► libs/server (HTTP backing, scaffold → real: separate task)
```

`jhonstart` itself adds no compiler features — its only real dependencies are the
prefix-operator + async language specs from `tasks/v0.beta.1/`.

## Scope boundaries

- `rakun` ships as a **scaffold** first (declarations only, not prelude-embedded),
  exactly like `libs/server`/`libs/client`. Embedding/compiler wiring is an
  explicit step inside the spec (F5), never implicit.
- Dependency injection is **comptime** (compilation-unit scan), **constructor-only**,
  **singleton-scope** in v1. Prototype/request scopes, AOP, and runtime reflection
  are out of scope.
