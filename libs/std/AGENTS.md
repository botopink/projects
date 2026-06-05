# std

> Path: `libs/std/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`src/examples.md`](src/examples.md)

Botopink standard library. `src/` is **`.bp`-only** (language-neutral source).
The files are embedded as compile-time strings and loaded by `compiler-core`
into the type environment during inference; the embed/loader glue lives in
`modules/compiler-core/src/comptime/stdlib/prelude.zig`, next to its consumer.

## Tree

```text
std/
├── AGENTS.md          ← you are here
├── docs.md            ← how the stdlib reaches the compiler + conventions
├── botopink.json      ← package metadata
├── src/               ← .bp/.d.bp source files only — see src/AGENTS.md
│   ├── primitives.d.bp  ← I32/U32/I64/U64/F32/F64/Bool interfaces
│   ├── array.d.bp       ← generic Array<T> interface
│   ├── string.d.bp      ← String interface
│   ├── builtins.d.bp    ← compiler/runtime builtins (typeOf, sizeOf, panic, …)
│   └── bool.bp          ← `bool` module (`import {bool} from "std"`)
└── test/              ← `.bp` test suite run by `botopink test` — see test/AGENTS.md
    ├── array_test.bp    ← builtin Array<T> behaviour
    └── string_test.bp   ← builtin String behaviour
```

## Testing

`cd libs/std && botopink test` compiles `src/` + `test/` in test mode and
runs every `test { … }` block (declaration `*.d.bp` files are excluded from
compilation — they are type surface only). Coverage status and the gaps that
block fuller suites are catalogued in [`test/AGENTS.md`](test/AGENTS.md).

## Wiring

`comptime/env.zig` calls `inferMod.registerStdlib(&env, gpa)` before each
inference pass. That helper imports the `std_prelude` Zig module
(`modules/compiler-core/src/comptime/stdlib/prelude.zig`) and registers every
embedded `.bp` string into the type `Env`. Each `.bp` file is exposed to that
module as an anonymous import in the root `build.zig` (`std_bp_files` list).

## Conventions

- Keep stdlib signatures backward-compatible whenever possible.
- Any rename or removal must be reflected in the codegen/comptime snapshots
  under [`../../modules/compiler-core/snapshots/`](../../modules/compiler-core/snapshots/AGENTS.md).
- When adding a new `.bp` file, also add it to `std_bp_files` in the root
  `build.zig` **and** add a matching `@embedFile` constant in
  `modules/compiler-core/src/comptime/stdlib/prelude.zig`.
- No Zig in `libs/std/` — loader/glue changes belong in `compiler-core`.
