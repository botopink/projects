# rakun

> Path: `libs/rakun/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Spec: [`../../tasks/v0.beta.5/specs/rakun.md`](../../tasks/v0.beta.5/specs/rakun.md)

A **Spring-style application framework** for botopink — an IoC container with
constructor dependency injection plus a declarative web layer (`#[restController]`
+ route annotations). **Opt-in, never auto-loaded:** embedded for the compiler
(`prelude.zig` + both `build.zig`s) but it enters a module's scope only via
`from "rakun"`. The HTTP layer is **real, emitted code** (`http.bp`, pulled in as
the `rakun/http` package module on import); the decorators and runtime-boundary
interfaces stay declaration-only (`rakun.d.bp`).

## Tree

```text
rakun/
├── AGENTS.md          ← you are here
├── docs.md            ← what this lib provides + Spring mapping + loading notes
├── botopink.json      ← package metadata (files: http.bp + rakun.d.bp)
└── src/
    ├── http.bp        ← concrete, emitted: `HttpMethod` enum · `Response` record
    │                    (builders) · `App` config record (the `rakun/http` module)
    └── rakun.d.bp     ← declaration-only: decorator markers · `Request`/`Context`/
                         `Rakun` boundary interfaces (no bodies, emit nothing)
```

## Design at a glance

- **IoC container** — components (`#[component]`/`#[service]`/`#[repository]`/
  `#[controller]`) are managed singletons; `Context.get<T>()` resolves them.
- **Constructor injection** — a dependency is declared as a `record` field and
  resolved **by type**. Immutable-first: no setter/field injection.
- **Comptime wiring** — discovery + DI graph resolution happen at compile time
  over the compilation unit (reuses the `@Expr`/`expr-templates` machinery), not
  via runtime reflection.
- **Web layer** — `#[restController, route(prefix)]` + `#[get|post|put|patch|delete(path)]`
  map routes to handler methods over `Request`/`Response`.
- **Bootstrap** — `Rakun.run(App(port: 8080))` scans → wires → builds the router →
  starts the server (the last leg needs `libs/server` to graduate from scaffold).

## Conventions

- **`.bp` over `.d.bp`.** Anything implementable lands in `http.bp` as real,
  emitted code (`Response.ok(...)` has a body). Only true markers (decorators)
  and runtime-boundary interfaces (`Request`/`Context`/`Rakun`) stay in
  `rakun.d.bp` — declaration-only, like `libs/std`'s `.d.bp` files.
- **Imported, not prelude.** Reached via `from "rakun"` — never auto-loaded into
  the type `Env`. `http.bp` is compiled + emitted as the `rakun/http` package
  module only when a project imports it; `rakun.d.bp` is registered for inference
  only (`comptime.zig registerRakunLib` / `infer.zig markRakunImports`).
- **Tests live here.** rakun's tests are `test { … }` blocks inside its own
  `.bp` files (run by `botopink test`), NOT in the compiler's Zig test suites.
- Keep this file in sync with `docs.md` and the spec in the same change.

## See also

- The spec (intent, steps, test scenarios) → [`../../tasks/v0.beta.5/specs/rakun.md`](../../tasks/v0.beta.5/specs/rakun.md).
- Usage examples → [`../../examples/rakun/`](../../examples/AGENTS.md).
- The server backing F5 depends on → [`../server/AGENTS.md`](../server/AGENTS.md).
