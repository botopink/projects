# compiler-cli/src/cli

> Path: `modules/compiler-cli/src/cli/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../../../AGENTS.md`](../../../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

Per-subcommand implementations and shared helpers for the `botopink` CLI.

## Tree

```text
cli/
├── AGENTS.md          ← you are here
├── docs.md            ← subcommand pipeline + shared helpers reference
├── examples.md        ← `botopink` command recipes
├── build.zig          ← `botopink build`    compile project, write outputs
├── check.zig          ← `botopink check`    type-check, no code emission
├── run.zig            ← `botopink run`      build + execute entry point
├── test_cmd.zig       ← `botopink test`     compile in test mode + run test blocks
├── format_cmd.zig     ← `botopink format`   format / check .bp files
├── new.zig            ← `botopink new`      scaffold a new project
├── clean.zig          ← `botopink clean`    delete out/ + .botopinkbuild/
├── config.zig         ← `botopink.json` loader + target options
├── scanner.zig        ← source-module discovery in `src/`
└── reporter.zig       ← stdout/stderr helpers (status, errors, hints)
```

## Subcommands

| File | Command | Notes |
|---|---|---|
| `build.zig` | `botopink build` | Driver — calls into compiler-core codegen. |
| `check.zig` | `botopink check` | Same pipeline as `build`, stops after type infer. |
| `run.zig` | `botopink run` | After `build`, exec target via `comptime/runtime` helpers. |
| `test_cmd.zig` | `botopink test [--filter <substr>]` | Compiles with `test_mode = true` (test blocks emit as a registry + runner; `main/0` not auto-invoked), writes to `.botopinkbuild/test-out/`, runs each test-containing module via node. commonJS target only (Erlang/WASM pending). |
| `format_cmd.zig` | `botopink format [--check]` | Round-trip stable formatting. |
| `new.zig` | `botopink new <name>` | Drops a project template. |
| `clean.zig` | `botopink clean` | Removes generated artifacts. |

## Shared helpers

| File | Role |
|---|---|
| `config.zig` | Parses `botopink.json` (target, entry module, etc). |
| `scanner.zig` | Walks `src/` and returns modules sorted by path (deterministic). |
| `reporter.zig` | Single source of truth for CLI text — use `reporter.errMsg`, `reporter.info`, etc. |

## Conventions

- Allocator parameters are named `alloc` (never `allocator`).
- Source discovery (`scanner.zig`) must remain deterministic — sort by path.
- All errors and hints must go through `reporter.zig` so output style stays
  consistent (`error: …` / `hint: …`).
