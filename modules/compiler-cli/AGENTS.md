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
├── tests/               ← end-to-end CLI scripts (NOT in `zig build test`)
│   ├── std_erlang.sh        ← `bp test --target erlang` over libs/std
│   ├── mutual_recursion.sh  ← forward-ref + mutual recursion runs on every backend
│   └── mutual_recursion/    ← fixture project for the script above
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

# End-to-end scripts under tests/ build the CLI + spawn runtimes, so they are
# NOT part of `zig build test` — run them directly:
bash modules/compiler-cli/tests/std_erlang.sh        # stdlib suite on erlang
bash modules/compiler-cli/tests/mutual_recursion.sh  # mutual recursion on every backend
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
