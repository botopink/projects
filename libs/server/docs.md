# server — server-side interfaces (scaffold)

> Path: `libs/server/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../AGENTS.md`](../AGENTS.md)

A future home for botopink's server-side interfaces — HTTP/socket server
declarations (request routing, response building, connection lifecycle). Today
it is an inert **scaffold**: `botopink.json` claims no files, nothing is embedded
into the compiler, and the type environment does not load it.

## What it will provide (planned)

- HTTP server interfaces — listen/accept, route registration, request/response.
- Socket-level interfaces for lower-level server programs.

## Loading notes

Unlike `libs/std`, this package is **not** `@embedFile`'d into a `prelude.zig`
and is **not** wired into `build.zig`. Wiring it into stdlib loading / the type
`Env` is a deliberate follow-up task, undertaken once it declares real symbols.

## See also

- The embedded standard library → [`../std/docs.md`](../std/docs.md).
- The `.bp` libraries group contract → [`../AGENTS.md`](../AGENTS.md).
