# rakun

> Path: `libs/rakun/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Spec: [`../../tasks/v0.beta.8/specs/rakun.md`](../../tasks/v0.beta.8/specs/rakun.md)

A **Spring-style application framework** for botopink — an IoC container with
constructor dependency injection plus a declarative web layer (`#[restController]`
+ route annotations). **Opt-in, never auto-loaded:** it enters a module's scope
only via `from "rakun"`. **The compiler core knows nothing about rakun** — every
behaviour is plain botopink + a host runtime, on the generic annotation-processor
mechanism (`@Decl` reflection, comptime decorator bodies, `@emit`).

How the wiring works: each component decorator (`decorators.bp`) is a comptime fn
over the annotated record. It `@emit`s, at the application site, (1) a scan
self-registration and (2) a factory `__rkMake_<Type>()` that constructs the record
injecting each field by its own factory; a controller additionally `@emit`s one
route registration per mapped method (reading `decl.methods` + the `#[route]`
prefix). botopink has no top-level mutable state, so the registries those calls
feed — the scan list, the dependency-cycle guard, the router table — live in
`runtime.mjs`, reached through the `#[@external]` declarations in `runtime.bp`.
The emitted code references those runtime fns by name, so a module declaring
components also imports them (`import {service, rkScan, rkEnter, rkDone,
rkRegisterRoute, …} from "rakun"`). The HTTP value types are real emitted code
(`http.bp`); the boundary interfaces stay declaration-only (`rakun.d.bp`).

## Tree

```text
rakun/
├── AGENTS.md          ← you are here
├── docs.md            ← what this lib provides + Spring mapping + loading notes
├── botopink.json      ← package metadata (files: http · runtime · decorators · rakun.d)
├── src/
│   ├── http.bp        ← concrete, emitted: `HttpMethod` enum · `Response` record
│   │                    (builders) · `App` config record
│   ├── runtime.mjs    ← host runtime: the mutable seams (scan list · cycle guard ·
│   │                    config props · router table + dispatch)
│   ├── runtime.bp     ← `#[@external]` decls binding the `runtime.mjs` seams
│   │                    (`rkScan`/`rkEnter`/`rkDone`/`rkProp`/`rkRegisterRoute`/
│   │                    `rkDispatch`/…), relative path resolves from test-out
│   ├── decorators.bp  ← the markers AS comptime decorator fns: placement rules +
│   │                    the DI/router wiring they `@emit`
│   └── rakun.d.bp     ← declaration-only: `Request`/`Context`/`Rakun` boundary
│                        interfaces (no bodies, emit nothing)
└── test/
    ├── di_test.bp     ← placement + component scan
    └── router_test.bp ← DI chain + router dispatch (200 / 404) end to end
```

## Design at a glance

- **IoC container** — components (`#[component]`/`#[service]`/`#[repository]`/
  `#[controller]`/`#[restController]`) are scanned at module load; each gets an
  emitted factory `__rkMake_<Type>()`.
- **Constructor injection** — a dependency is declared as a `record` field and
  resolved **by type** (the factory calls the field type's own factory).
  Immutable-first: no setter/field injection. (`#[value("key")]` property
  injection is a recorded follow-up; v1 injects every field by type.)
- **Cycle detection** — `__rkMake_X` brackets construction with `rkEnter`/`rkDone`;
  a cycle A→B→A raises at first construction. (A *comptime* cycle diagnostic would
  need a whole-graph view no single decorator has — a recorded follow-up.)
- **Web layer** — `#[restController, route(prefix)]` + `#[getMapping(path)]`/… emit
  a `rkRegisterRoute(verb, prefix + path, handler)`; `rkDispatch` matches (verb,
  path) — including `:name` params — and runs the handler over `Request`/`Response`,
  or 404s.
- **Bootstrap** — `Rakun.run(App(port: 8080))` reads the router back and starts the
  server (the real HTTP backing needs `libs/server` to graduate from scaffold; the
  runtime `.mjs` must also be shipped next to the emitted module for a consumer
  build — both recorded follow-ups).

## Conventions

- **`.bp` over `.d.bp`.** Logic lands in real emitted `.bp` (`http.bp`,
  `runtime.bp`'s `declare fn`s, `decorators.bp` bodies). Only the boundary
  interfaces (`Request`/`Context`/`Rakun`) stay declaration-only in `rakun.d.bp`.
- **Host state behind `#[@external]`.** The one mutable seam is `runtime.mjs`; the
  core never sees it. Decorator bodies obey the comptime constraints (no sibling
  calls, `if`-expr, bare-`if` only last, block-lambdas) — see
  [`../../modules/compiler-core/src/comptime/AGENTS.md`](../../modules/compiler-core/src/comptime/AGENTS.md).
- **Imported, not prelude.** Reached via `from "rakun"` — never auto-loaded into
  the type `Env`, no core embed/registry.
- **Tests live here.** rakun's tests are `test { … }` blocks inside its own
  `.bp` files (run by `botopink test`), NOT in the compiler's Zig test suites.
  Wrong-placement *rejection* is covered generically by the compiler's
  annotation-processor suite (a compile-failure can't be a runtime `assert`).
- Keep this file in sync with `docs.md` and the spec in the same change.

## See also

- The spec (intent, steps, test scenarios) → [`../../tasks/v0.beta.8/specs/rakun.md`](../../tasks/v0.beta.8/specs/rakun.md).
- Usage examples → [`../../examples/rakun/`](../../examples/AGENTS.md).
- The server backing F5 depends on → [`../server/AGENTS.md`](../server/AGENTS.md).
