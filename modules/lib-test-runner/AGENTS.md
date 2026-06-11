# lib-test-runner

> Path: `modules/lib-test-runner/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Package that builds the `botopink-lib-test` executable: the CI gate that runs
every `libs/` project's test suite on each requested backend and aggregates the
results into a lib×target matrix. It **shells out to the installed `botopink`
binary** (`botopink test --target <t>` with `cwd` set to each lib) and touches no
compiler internals — so it carries **no `compiler-core` dependency**. Its job is
discovery + fan-out + aggregation + exit code, nothing the compiler already does.

## Tree

```text
lib-test-runner/
├── AGENTS.md            ← you are here
├── build.zig            ← package build graph + `run` + `test` steps
├── build.zig.zon        ← manifest (no dependencies — self-contained)
└── src/
    ├── main.zig         ← entry: resolve paths/binary → discover → run cells → matrix → exit
    ├── args.zig         ← CLI parsing (Target enum, node alias, =-form, all)  + unit tests
    ├── discovery.zig    ← enumerate libs/*/ with botopink.json, "has tests" probe + unit tests
    ├── runner.zig       ← per-(lib,target) `botopink test` spawn + status classification
    └── matrix.zig       ← Status enum, lib×target matrix render, summary + unit tests
```

## Commands

```bash
# from the workspace root:
zig build test-libs                                   # every lib, commonJS+erlang
zig build test-libs -- --target erlang --lib rakun    # one target, one lib
zig build test-libs -- --target all --strict          # supported targets, strict

# from this package:
zig build               # produce ./zig-out/bin/botopink-lib-test
zig build test          # arg-parsing + discovery + matrix unit tests
```

## CLI surface

```
botopink-lib-test [--target <t>[,<t>…] | --target all] [--lib <name>]
                  [--filter <s>] [--strict] [--bin <path>]
```

- `--target` — repeatable / comma-separated. Accepts `commonJS|erlang|beam|wasm`
  plus the alias `node`→`commonJS`, and both `--target <t>` and `--target=<t>`.
  Default: `commonJS,erlang`. `all` expands to every *supported* target.
- `--lib <name>` — restrict to one lib under `libs/` (default: every lib with a
  `botopink.json`).
- `--filter <s>` — forwarded to `botopink test --filter`.
- `--strict` — treat an unsupported target (beam/wasm) as a **failure** instead of
  a skip (default: skip with `~`, keeping the gate green until those backends run).
- `--bin <path>` — `botopink` binary path. Also read from `BOTOPINK_BIN`; defaults
  to `./zig-out/bin/botopink`, else the bare name `botopink` on `PATH`.

## Matrix legend & exit code

| Symbol | Meaning |
|---|---|
| `✓` | `botopink test` passed |
| `✗` | a red `.bp` test — the **only** status that fails the run |
| `–` | lib has no test blocks (green skip, never a failure) |
| `~` | target not yet runnable (beam/wasm), skipped unless `--strict` |

**Exit non-zero iff at least one cell is `✗`.** A no-tests lib (`–`) and a
skipped-unsupported target (`~`) never redden the gate.

## Design contract

- **Orchestrate, don't reimplement.** Per-lib isolation falls out of spawning a
  child with `cwd = libs/<lib>`: `botopink test` reads that lib's `botopink.json`
  and writes its own `.botopinkbuild/test-out/`. No global-cwd juggling.
- **Unsupported-target detection is child-driven**, not a hard-coded list: the
  runner scans the child's output for `"currently supports only"`. The moment
  `botopink test` learns `beam`/`wasm`, that target stops being skipped here with
  no change — only the default/`all` set widens (`args.Target.supported`).
- **No lib coupling, no core code.** The runner names no specific lib and imports
  nothing from `compiler-core`.

See the root [`AGENTS.md`](../../AGENTS.md) for workspace commands and the
[`modules/AGENTS.md`](../AGENTS.md) package table.
