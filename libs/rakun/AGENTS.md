# rakun

> Path: `libs/rakun/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Spec: [`../../tasks/v0.beta.5/specs/rakun.md`](../../tasks/v0.beta.5/specs/rakun.md)

A **Spring-style application framework** for botopink — an IoC container with
constructor dependency injection plus a declarative web layer (`@[restController]`
+ route annotations). **Scaffold only:** this package is *not* embedded into the
compiler (no `prelude.zig`, no `build.zig` wiring) and declares no committed
symbols yet (`botopink.json` lists `files: []`). It exists to anchor the design
authored in the v0.beta.5 spec.

## Tree

```text
rakun/
├── AGENTS.md          ← you are here
├── docs.md            ← what this lib will provide + Spring mapping + loading notes
├── botopink.json      ← package metadata (files: [] — claims nothing yet)
└── src/               ← .bp declarations
    └── rakun.d.bp     ← declarative surface (HTTP types · Context · App · Rakun)
```

## Design at a glance

- **IoC container** — components (`@[component]`/`@[service]`/`@[repository]`/
  `@[controller]`) are managed singletons; `Context.get<T>()` resolves them.
- **Constructor injection** — a dependency is declared as a `record` field and
  resolved **by type**. Immutable-first: no setter/field injection.
- **Comptime wiring** — discovery + DI graph resolution happen at compile time
  over the compilation unit (reuses the `@Expr`/`expr-templates` machinery), not
  via runtime reflection.
- **Web layer** — `@[restController, route(prefix)]` + `@[get|post|put|patch|delete(path)]`
  map routes to handler methods over `Request`/`Response`.
- **Bootstrap** — `Rakun.run(App(port: 8080))` scans → wires → builds the router →
  starts the server (the last leg needs `libs/server` to graduate from scaffold).

## Conventions

- Interface declarations stay declarative (no method bodies), like `libs/std`'s
  `.d.bp` files. Codegen / comptime supply implementations.
- **Imported, not prelude.** This lib is reached via `from "rakun"` — it is never
  auto-loaded into the type `Env`. App authors opt in per project.
- When the first real symbols land, list their `.bp`/`.d.bp` files in
  `botopink.json` and decide compiler wiring (a separate, explicit task — spec F5).
- Keep this file in sync with `docs.md` and the spec in the same change.

## See also

- The spec (intent, steps, test scenarios) → [`../../tasks/v0.beta.5/specs/rakun.md`](../../tasks/v0.beta.5/specs/rakun.md).
- Usage examples → [`../../examples/rakun/`](../../examples/AGENTS.md).
- The server backing F5 depends on → [`../server/AGENTS.md`](../server/AGENTS.md).
