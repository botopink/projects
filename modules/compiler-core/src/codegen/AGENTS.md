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
├── beam_asm.zig      ← BEAM Assembly `.S` emitter (broad coverage; a few cross-backend gaps remain — see row below)
├── wat.zig           ← WebAssembly Text `.wat` emitter (complete — 0 unsupported across 164 snapshots)
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
| `commonJS.zig` | CommonJS emitter — iterates already-transformed AST. `try`/`catch` lower to `Ok`/`Error` **tag pattern matching** (statement-level for propagation; see [`./docs.md`](docs.md)). Static extension dispatch (F6): `implement`/`extend` blocks emit as namespace objects (`const Sym = { m(self){…} }`, no prototype patching) and activated `obj.m(args)` lowers to `Sym.m(obj, args)` via the loc-keyed `dispatch_rewrites` map |
| `erlang.zig` | Erlang emitter — same shape as `commonJS.zig`. Case arms lower list patterns (`[]`/`[X]`/`[First \| Rest]`) and constructor patterns (unit → atom, payload → `{tag, …}` tuple); module-qualified calls (`List.map(…)`) emit remote calls `list:map(…)` with the PascalCase receiver lowercased to a valid module atom. `try`/`catch` → `case … of {ok, V} -> …; {error, E} -> … end`; propagation nests the body tail in the `{ok, V}` arm |
| `beam_asm.zig` | BEAM Assembly `.S` emitter. Full coverage: numerics, locals, calls, decl methods, booleans, assign, throw, strings, `@print`, field access/assign, arrays, tuples, case (all patterns **+ `pat if guard` guards**, via `emitGuardPre`/`emitGuardPost`), `if`-as-value (`emitValueIf` — produces the value in `{x,0}` and falls through, no spurious `return`), try/catch (`is_tagged_tuple` list form `[{x,0}, N, {atom,Tag}]` on `{ok,_}`/`{error,_}`, expr + stmt), ranges (`lists:seq/2`), pipeline, method calls, **module-qualified remote calls** (`List.map(…)` → `{call_ext, N, {extfunc, list, map, N}}` / `call_ext_last` in tail), **record/struct constructors** (`AppError(code:, msg:)` → `put_map_assoc` map keyed by field-name atoms). **`erlc +from_asm`-correctness invariants** (all validated by assembling+running the snapshots): comparisons use only `is_lt`/`is_ge` (no `is_gt`/`is_le` — `comparisonTestOp` swaps operands); atoms are quoted when not a valid unquoted atom (`atomName`/`isUnquotedAtom` — PascalCase enum tags `'Circle'`, `.dotIdent`, comptime-specialized `'execute_$0'`, component fns `'Widget'`); `{allocate, N, A}` is followed by `{init_yregs, …}` (`emitFrame`) so GC points don't see uninitialised y-slots; `countLocalsRec` counts case-arm + destructure bindings so the frame is big enough. **Known gaps** (the `make_fun2`/`call_fun` lambda+loop path emits `make_fun2` but `+from_asm` rejects it — no `FunT` lambda-table chunk is written, so closures/loops don't yet assemble; this is the live Fase-6 continuation), `negation_in_expression` `gc_bif` Live count, and cross-backend items also broken on Erlang: `new Error`, `console.log`, cross-module imports, `*fn` async/`await`, `@Result`/`@Option` methods (`__bp_*`), typed-value method dispatch (`p.parse()`). See [`/TODO.md`](../../../../TODO.md). |
| `wat.zig` | WebAssembly Text `.wat` emitter. Full coverage: numerics, locals, calls, assign, `!x`, null, `@todo`/`@panic`, globals, `_botopink_main`, case, pipeline (`a \|> f` → `call $f`), lambdas, loops, `@print` via WASI `fd_write`. **Aggregates in linear memory** — tuples/arrays/records/enum payloads are contiguous 4-byte slots in the bump heap (a type registry built from `record`/`struct`/`enum` decls distinguishes construction calls from function calls, since codegen is untyped); construction stashes the base in a `$__mem{n}` scratch local, destructuring and `t._N` access load by `offset`; enum payloads are `[tag, …fields]`. **Strings** — literal `+` → `$__str_concat` (`memory.copy`), literal `==`/`!=` → `$__str_eq` (byte loop). `try`/`catch` → `if` on the tag `i32` (payload at `offset=4`). `wasmtime` runner |
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
- Erlang module-qualified calls: a PascalCase receiver (`List`) is a module
  reference → emitted as a remote call `list:map(…)` (lowercased via
  `erlangModule`); a lowercase receiver is treated as a value method call and
  left as-is (`isModuleRef` distinguishes them). Arity is the argument count
  (args + trailing lambdas).
- BEAM ASM and WAT backends cover the language broadly and reuse the
  existing comptime runtimes (`erlang` for BEAM, `node` for WASM). BEAM ASM is
  held to an **`erlc +from_asm`-correctness** bar — valid opcodes, quoted atoms,
  GC-safe frames (`init_yregs`), correct y-slot counts — so emitted `.S`
  actually assembles and runs (snapshots carry a RUN LOG). It still can't
  assemble closures/loops (`make_fun2` needs a `FunT` lambda-table chunk that
  isn't written yet — the live Fase-6 continuation) and emits `%% unresolved`/
  `%% unsupported` for cross-backend cases (`new Error`, `console.log`,
  cross-module imports, `*fn` async/`await`, `@Result`/`@Option` methods) — see
  the `beam_asm.zig` row above and [`/TODO.md`](../../../../TODO.md).
- `use` hooks (F8): `use` is a transparent prefix; `val`/`var` does the binding.
  CommonJS maps hooks to React (`state`→`useState`, `memo`→`useMemo`, …) via the
  `use`+Capitalize convention (`writeHookName`); `memo`/`effect`/`callback` get an
  inferred dependency array — the reactive names (bound by earlier hooks, tracked
  in `Emitter.hook_state`) the lambda reads, via `identInExpr`. Erlang/BEAM/WAT
  lower `use` transparently (the call result lands in a binding/slot). Phantom
  `@Context` base structs (`isPhantomContextStruct`: implements `@Context`, no
  members) emit no runtime code; the `.d.ts` erases `@Context<B, R>` to `R`.

For the `.bp` → target translation gallery see
[`./examples.md`](examples.md); for the full API surface and snapshot
format see [`./docs.md`](docs.md).
