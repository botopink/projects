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
├── server/            ← server-side interfaces (scaffold)
├── client/            ← client-side interfaces (scaffold)
└── rakun/             ← Spring-style application framework (scaffold)
```

## Packages

| Package | Provides | Embedded in compiler? | AGENTS |
|---|---|---|---|
| `std/` | builtin types, primitives, Array/String, builtins — loaded into the type `Env` at infer time | yes (`modules/compiler-core/src/comptime/stdlib/prelude.zig`, wired in root `build.zig`) | [link](std/AGENTS.md) |
| `server/` | HTTP/socket server-side interfaces | no — inert scaffold | [link](server/AGENTS.md) |
| `client/` | HTTP client / request interfaces | no — inert scaffold | [link](client/AGENTS.md) |
| `rakun/` | Spring-style framework — IoC container, constructor DI, `@[restController]` web layer, `Rakun.run` bootstrap | no — inert scaffold (spec: [`tasks/v0.beta.5`](../tasks/v0.beta.5/specs/rakun.md)) | [link](rakun/AGENTS.md) |

## Conventions

- `.bp` declarations stay declarative — interface/method **signatures only**, no
  bodies. Codegen supplies implementations per target.
- Only `std` is embedded today. `server`/`client`/`rakun` are scaffolds: they are
  not wired into `build.zig` / the compiler-core prelude loader. Embedding a new
  lib into stdlib loading / the type `Env` is a deliberate, separate task.
  (`rakun` is an *application-level* lib — reached via `from "rakun"`, opted into
  per project, never prelude-embedded.)
- Packages are `.bp`-only — no Zig under `libs/`. The embed/loader glue lives
  in `modules/compiler-core/src/comptime/stdlib/prelude.zig`.
- Every directory ships its own `AGENTS.md`; update it in the same change that
  touches the directory's layout or contents.

## See also

- The toolchain that consumes these libs → [`../modules/AGENTS.md`](../modules/AGENTS.md).
- `.bp` language reference (user-facing) → [`../docs.md`](../docs.md).
