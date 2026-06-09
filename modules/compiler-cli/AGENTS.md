# compiler-cli

> Path: `modules/compiler-cli/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`src/cli/examples.md`](src/cli/examples.md)

Package that builds the `botopink` CLI executable. Depends on `compiler-core`.

## Tree

```text
compiler-cli/
├── AGENTS.md            ← you are here
├── build.zig            ← package build graph + `run` + `test` steps
├── build.zig.zon        ← dependency manifest (compiler-core)
└── src/
    ├── AGENTS.md
    ├── docs.md          ← argv parser layout, dispatch flow
    ├── main.zig         ← argv parser, subcommand dispatcher
    └── cli/             ← one file per subcommand + shared helpers
        ├── AGENTS.md
        ├── docs.md      ← subcommand pipeline + shared helpers
        └── examples.md  ← `botopink` command recipes
```

## Commands

```bash
zig build               # produce ./zig-out/bin/botopink
zig build run -- help
zig build run -- version
zig build test          # CLI unit tests (e.g. the generic lib loader)
```

## External libs (generic loader)

`cli/libs.zig` is the driver-side half of the lib-agnostic package mechanism. A
project's `botopink.json` `dependencies: ["<name>", …]` are resolved from disk:
the loader walks up for a `libs/` directory, reads each `libs/<name>/botopink.json`
(`{src, files}`), and feeds the lib's modules into compilation prefixed by name
(`<name>/<module>`). The compiler core never names a lib — it just sees ordinary
`Module[]` and resolves `from "<name>"` through the shared import registry. `std`
is the one embedded exception and is not loaded here.

## CLI behavior contract

- Exit `0` on success, non-zero on command failure.
- All user-facing status/errors must go through `src/cli/reporter.zig`.
- Keep command options aligned with help text in `src/main.zig` and the
  `cli/<cmd>.zig` implementation.

See [`src/AGENTS.md`](src/AGENTS.md) for the dispatch flow and
[`src/cli/AGENTS.md`](src/cli/AGENTS.md) for the per-command list.
