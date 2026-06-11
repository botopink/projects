# libs/

> Path: `libs/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Code written **in** botopink — the language's `.bp` libraries, kept separate
from the Zig/TS toolchain under [`../modules/`](../modules/AGENTS.md). The
dependency arrow runs one way: `modules/compiler-core` consumes `libs/std`; a
lib never depends on the toolchain's internals.

Each library is a package with its own `botopink.json` and `AGENTS.md`, mirroring
the shape of `std/`.

## Tree

```text
libs/
├── AGENTS.md          ← you are here
├── std/               ← standard library (embedded prelude + interfaces)
├── server/            ← framework-agnostic HTTP backing (real node-`http`, `from "server"`)
├── client/            ← client-side interfaces (scaffold)
├── rakun/             ← Spring-style application framework (real, `from "rakun"`)
├── jhonstart/         ← React/Next-style UI framework (scaffold)
├── erika/             ← C#/LINQ-style query lib (pure `.bp`, reached via `from "erika"`)
└── onze/              ← Mockito-style mocking + verification for tests (pure `.bp`, `from "onze"`)
```

## Packages

| Package | Provides | Embedded in compiler? | AGENTS |
|---|---|---|---|
| `std/` | builtin types, primitives, Array/String, builtins — loaded into the type `Env` at infer time | yes (`modules/compiler-core/src/comptime/stdlib/prelude.zig`, wired in root `build.zig`) | [link](std/AGENTS.md) |
| `server/` | framework-agnostic HTTP backing — node-`http` server (`serverServe`/`serverStop`) behind `#[@external]` | no — reached via `from "server"` (real; rakun's transport) | [link](server/AGENTS.md) |
| `client/` | HTTP client / request interfaces | no — inert scaffold | [link](client/AGENTS.md) |
| `rakun/` | Spring-style framework — IoC container, constructor DI, singleton scope, `#[bean]`/`#[value]`, `#[restController]` web layer, `Rakun.run` bootstrap | no — reached via `from "rakun"` (real; spec: [`tasks/v0.beta.11`](../tasks/v0.beta.11/specs/rakun.md)) | [link](rakun/AGENTS.md) |
| `jhonstart/` | React/Next-style UI: components, `@Context<Element,_>` hooks, DOM builders, the `html` DSL, Next-style routing/SSR | no — inert scaffold (reached via `from "jhonstart"`) | [link](jhonstart/AGENTS.md) |
| `erika/` | C#/LINQ-style fluent `Query<T>` + an `erika "…"` SQL-subset template fn — pure `.bp`, zero compiler surface | no — reached via `from "erika"` (generic loader; spec: [`tasks/v0.beta.7`](../tasks/v0.beta.7/specs/erika.md)) | [link](erika/AGENTS.md) |
| `onze/` | Mockito-style mocking: `#[mock]` synthesizes a stub from an interface (`@Decl`+`@emit`), `when`/`verify`/matchers; host-bound call log + stub table — pure `.bp`, zero compiler surface | no — reached via `from "onze"` (generic loader; spec: [`tasks/v0.beta.8`](../tasks/v0.beta.8/specs/onze.md)) | [link](onze/AGENTS.md) |

## Conventions

- `.bp` declarations stay declarative — interface/method **signatures only**, no
  bodies. Codegen supplies implementations per target.
- Only `std` is embedded today. `client` is still a scaffold; `server` and `rakun`
  are real **application-level** libs reached via `from "server"` / `from "rakun"`,
  opted into per project, never prelude-embedded or wired into `build.zig`.
  Embedding a lib into stdlib loading / the type `Env` is a deliberate, separate task.
- `erika` is a real (non-scaffold) **application-level** lib too — fully
  implemented in `.bp`, reached via `from "erika"` through the generic external-lib
  loader (`compiler-cli/src/cli/libs.zig`), never embedded. It is the reference
  client for that loader on an ordinary, non-framework package.
- Packages are `.bp`-only — no Zig under `libs/`. The embed/loader glue lives
  in `modules/compiler-core/src/comptime/stdlib/prelude.zig`.
- Every directory ships its own `AGENTS.md`; update it in the same change that
  touches the directory's layout or contents.

## See also

- The toolchain that consumes these libs → [`../modules/AGENTS.md`](../modules/AGENTS.md).
- `.bp` language reference (user-facing) → [`../docs.md`](../docs.md).
