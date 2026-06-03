# server

> Path: `libs/server/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

Server-side interfaces for botopink — HTTP/socket server declarations written
in `.bp`. **Scaffold only:** this package is *not* embedded into the compiler
(no `prelude.zig`, no `build.zig` wiring) and declares no symbols yet. It exists
to anchor future server-side library code.

## Tree

```text
server/
├── AGENTS.md          ← you are here
├── docs.md            ← what this lib will provide + loading notes
├── botopink.json      ← package metadata (files: [] — claims nothing yet)
└── src/               ← .bp declarations — see src/AGENTS.md
    └── server.d.bp    ← placeholder declaration file (header only)
```

## Conventions

- Interface declarations stay declarative (no method bodies), like `libs/std`.
- When the first real symbols land, list their `.bp` files in `botopink.json`
  and decide on compiler wiring (a separate, explicit task).
