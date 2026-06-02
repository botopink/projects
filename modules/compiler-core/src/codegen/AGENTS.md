# compiler-core/src/codegen

> Path: `modules/compiler-core/src/codegen/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

Per-target codegen backends. The public façade lives at `../codegen.zig`.

## Tree

```text
codegen/
├── AGENTS.md         ← you are here
├── docs.md           ← design notes: blind emitters, entry-point convention
├── examples.md       ← `.bp` → JS / Erlang side-by-side
├── config.zig        ← Config / TargetSource (commonJS|erlang|beam|wasm) / ComptimeRuntime / TypeDefLang
├── moduleOutput.zig  ← shared types: Module, ModuleOutput, GenerateResult
├── commonJS.zig      ← CommonJS emitter (blind: iterates transformed AST)
├── erlang.zig        ← Erlang emitter (blind)
├── beam_asm.zig      ← BEAM Assembly `.S` emitter (complete — 0 unsupported across 162 snapshots)
├── wat.zig           ← WebAssembly Text `.wat` emitter (complete — 0 unsupported across 162 snapshots)
├── typescript.zig    ← TypeScript `.d.ts` typedef generator
├── runtime.zig       ← runtime helpers used when executing generated JS/Erlang in tests
├── snapshot.zig      ← snapshot helpers for codegen tests
└── tests.zig         ← `assertJs`, `assertJsSingle`, `assertJsError`, …
```

## Files

| File | Role |
|---|---|
| `config.zig` | `Config`, `TargetSource` (`commonJS` \| `erlang` \| `beam` \| `wasm`), `ComptimeRuntime`, `TypeDefLang` |
| `moduleOutput.zig` | `Module`, `ModuleOutput`, `GenerateResult` — shared between targets |
| `commonJS.zig` | CommonJS emitter — iterates already-transformed AST. `try`/`catch` lower to `Ok`/`Error` **tag pattern matching** (statement-level for propagation; see [`./docs.md`](docs.md)) |
| `erlang.zig` | Erlang emitter — same shape as `commonJS.zig`. `try`/`catch` → `case … of {ok, V} -> …; {error, E} -> … end`; propagation nests the body tail in the `{ok, V}` arm |
| `beam_asm.zig` | BEAM Assembly `.S` emitter — **0 unsupported across 162 snapshots.** Full coverage: numerics, locals, calls, decl methods, booleans, assign, throw, strings, `@print`, field access/assign, arrays, tuples, lambdas (`make_fun2`), case (all patterns), try/catch (`is_tagged_tuple` on `{ok,_}`/`{error,_}`), pipeline, method calls, loops (stub). `erlc +from_asm` validated |
| `wat.zig` | WebAssembly Text `.wat` emitter — **0 unsupported across 162 snapshots.** Full coverage: numerics, locals, calls, assign, `!x`, null, `@todo`/`@panic`, globals, `_botopink_main`, case/pipeline/destructuring/lambdas/loops/strings as numeric stubs, `@print` as nop. `try`/`catch` → `if` on the tag `i32` (payload at `offset=4`) in linear memory. `wasmtime` runner |
| `typescript.zig` | `.d.ts` typedef generator (optional secondary output) |
| `runtime.zig` | Test-side runtime helpers (executes generated code) |
| `snapshot.zig` / `tests.zig` | Codegen test harness |

## Quick-reference rules

- Emitters are **blind** — they never inspect `ExprKind.comptime_`; the
  transform pass has already resolved everything. Full rationale in
  [`./docs.md`](docs.md).
- `fn main()` triggers an entry-point wrapper (`_botopink_main()` in JS;
  quoted `'_botopink_main'/0` atom in Erlang). The Erlang atom **must**
  be quoted because plain atoms can't start with `_`.
- All public functions use `alloc: std.mem.Allocator` (not `allocator`).
- BEAM ASM and WAT backends are complete (0 unsupported across 162
  snapshots each). They reuse the existing comptime runtimes (`erlang`
  for BEAM, `node` for WASM). See [`/TODO.md`](../../../../TODO.md) for
  optional future improvements.

For the `.bp` → target translation gallery see
[`./examples.md`](examples.md); for the full API surface and snapshot
format see [`./docs.md`](docs.md).
