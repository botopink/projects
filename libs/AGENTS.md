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
└── client/            ← client-side interfaces (scaffold)
```

## Packages

| Package | Provides | Embedded in compiler? | AGENTS |
|---|---|---|---|
| `std/` | builtin types, primitives, Array/String, builtins — loaded into the type `Env` at infer time | yes (`libs/std/src/prelude.zig`, wired in root `build.zig`) | [link](std/AGENTS.md) |
| `server/` | HTTP/socket server-side interfaces | no — inert scaffold | [link](server/AGENTS.md) |
| `client/` | HTTP client / request interfaces | no — inert scaffold | [link](client/AGENTS.md) |

## Conventions

- `.bp` declarations stay declarative — interface/method **signatures only**, no
  bodies. Codegen supplies implementations per target.
- Only `std` is embedded today. `server`/`client` are scaffolds: they carry no
  `prelude.zig` and are not wired into `build.zig`. Embedding a new lib into
  stdlib loading / the type `Env` is a deliberate, separate task.
- Every directory ships its own `AGENTS.md`; update it in the same change that
  touches the directory's layout or contents.

## See also

- The toolchain that consumes these libs → [`../modules/AGENTS.md`](../modules/AGENTS.md).
- `.bp` language reference (user-facing) → [`../docs.md`](../docs.md).
