# compiler-core/src/codegen

> Path: `modules/compiler-core/src/codegen/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

Per-target codegen backends. The public façade lives at `../codegen.zig`.

Top-level `test { … }` declarations (`DeclKind.@"test"`) are **skipped by every
backend** in normal `build`/`run` output — they are only collected and emitted
under `botopink test` (`Config.test_mode`): commonJS emits `__bp_test_N`
functions + a `__bp_tests` registry + `__bp_run_tests()` runner; erlang emits
`'__bp_test_N'/0` functions + a `'__bp_run_tests'/1` runner + `main/1` escript
entry. In test mode `assert` lowers to a recoverable per-test failure
(JS: throwing `__bp_assert`; Erlang: `erlang:error({bp_assert, Msg, Loc})`)
and `fn main/0` is not auto-invoked. WASM runner pending.

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
├── wat.zig           ← WebAssembly Text `.wat` emitter (length-prefixed strings w/ `.len`/`.slice`; lambdas/array-loops/stdlib-Result methods are deferred gaps)
├── typescript.zig    ← TypeScript `.d.ts` typedef generator
├── runtime.zig       ← runtime helpers used when executing generated JS/Erlang in tests
├── snapshot.zig      ← snapshot helpers for codegen tests
├── tests.zig         ← barrel: aggregates tests/<feature>.zig for test_root.zig
└── tests/            ← codegen tests, split by feature
    ├── helpers.zig         ← shared harness (`assertJs`/`assertJsError`/`configs`/…)
    ├── js_values.zig       ← val/fn/call/operators/assign/self/comments
    ├── js_aggregates.zig   ← array/tuple/struct/record
    ├── js_control_flow.zig ← case/loop/if/try/throw/catch
    ├── js_comptime.zig     ← comptime folding/specialization/validation
    ├── js_builtins.zig     ← builtin/stdlib/assert
    ├── js_dispatch.zig     ← extension dispatch (implement/interface/delegate)
    ├── js_features.zig     ← lambda/enum/destructure/star/import/range/pipeline/hooks
    └── wat.zig             ← WAT backend codegen
```

## Files

| File | Role |
|---|---|
| `config.zig` | `Config`, `TargetSource` (`commonJS` \| `erlang` \| `beam` \| `wasm`), `ComptimeRuntime`, `TypeDefLang` |
| `moduleOutput.zig` | `Module`, `ModuleOutput`, `GenerateResult` — shared between targets |
| `commonJS.zig` | CommonJS emitter — iterates already-transformed AST. A `@Result` is `{ ok: V } \| { error: E }` (`"error" in _r` test); `__bp_ok`/`__bp_error` construct it for `return`/`throw` in `*fn -> @Result` fns. `try`/`catch` lower to **`"error" in _r` pattern matching** (statement-level for propagation; see [`./docs.md`](docs.md)). Static extension dispatch (F6): `implement`/`extend` blocks emit as namespace objects (`const Sym = { m(self){…} }`, no prototype patching) and activated `obj.m(args)` lowers to `Sym.m(obj, args)` via the loc-keyed `dispatch_rewrites` map. `@[external(node, "module", "symbol")]` fns (F1): the decl lowers to `const { symbol: name } = require("module");`; an external fn with no `node` target errors (`MissingExternalTarget`) when called. **Cross-module linking**: a `CrossModule` index (built once over every module's transformed program in `codegenEmit`) resolves `from "<pkg>"`/multi-module imports to `require("./<path>.js")` of the file that actually emits each name (declaration-only names like rakun decorators emit no `require`), marks imported records/structs as classes so construction emits `new`, and emits `exports.X` only for `pub` types another module imports. A record's no-`self` associated fn (`Response.ok(…)`) emits as a `static` class method |
| `erlang.zig` | Erlang emitter — same shape as `commonJS.zig`. **Records/structs are maps at runtime**: constructor calls lower to `#{field => V, …}` map literals (labeled args use the label, positional args the declared field order — `collectTypeShapes` registry), field access lowers to `maps:get(field, Recv)` (atom-quoted via `atomName`), tuple index `t._N` → `element(N+1, T)`; the invalid `-record(PascalCase, …)` decls are gone (comment only). Qualified enum members `Order.Lt` → the variant atom; payload constructors `Color.Rgb(r, g, b)` → tagged tuple `{'Rgb', R, G, B}` (matches case-arm patterns). **Optional chaining `?.`** guards on `undefined` via an immediate fun (`(fun(undefined) -> undefined; (R) -> maps:get(f, R) end)(Recv)`). Case arms lower list patterns (`[]`/`[X]`/`[First \| Rest]`) and constructor patterns (unit → atom, payload → `{tag, …}` tuple); module-qualified calls (`List.map(…)`) emit remote calls `list:map(…)` with the PascalCase receiver lowercased to a valid module atom. `try`/`catch` → `case … of {ok, V} -> …; {error, E} -> … end`; propagation nests the body tail in the `{ok, V}` arm; an `if` whose then-branch ends in `return` nests the rest of the body in the false arm (`emitEarlyReturnIf` — Erlang has no early return); `__bp_ok`/`__bp_error` construct `{ok, V}`/`{error, E}` for `return`/`throw` in `*fn -> @Result` fns. Static extension dispatch (F6): `implement`/`extend` methods emit as bare local functions keeping `self` as the explicit first param (`swim(Self) -> …`, `keep_self` flag); activated `recv.m(args)` (via `dispatch_rewrites`) and qualified `Sym.m(obj)` (receiver is an extension block name in `ext_names`) both lower to the local call `m(recv, args)` instead of a remote `recv:m/Sym:m` call. `@[external(erlang, "module", "symbol")]` fns (F1): the decl emits nothing (comment only, excluded from `-export`) and calls lower to the remote `module:symbol(Args)` (`externals` map); no `erlang` target → `MissingExternalTarget` when called |
| `beam_asm.zig` | BEAM Assembly `.S` emitter. Full coverage: numerics, locals, calls, decl methods, booleans, assign, throw, strings, `@print`, field access/assign, arrays, tuples, **executable closures** (`emitMakeFun`: `{test_heap, {alloc, [{funs, 1}]}, Live}` + `make_fun3` with a `{x, 0}` dest — `make_fun2` is rejected by `+from_asm` on this OTP; `Live` honours a `min_live` floor so scratch x-registers live across the allocation survive), **fun application (`call_fun`)** for local-bound (`val f = {…}`) and `syntax fn` parameters, case (all patterns **+ `pat if guard` guards** via `emitGuardPre`/`emitGuardPost` — restore subject + fall through on guard failure), **`if`-as-value** (`emitValueIf` — value in `{x,0}`, falls through, no spurious branch `return`), try/catch (`is_tagged_tuple` list form `[{x,0}, N, {atom,Tag}]` on `{ok,_}`/`{error,_}`, expr + stmt), ranges (`lists:seq/2`), pipeline, method calls, **module-qualified remote calls** (`List.map(…)` → `{call_ext, N, {extfunc, list, map, N}}` / `call_ext_last` in tail, with trailing lambdas materialized as fun arguments), **record/struct constructors** (`AppError(code:, msg:)` → `put_map_assoc` building a `#{…}` map keyed by field-name atoms), **`@Result`/`@Option` methods** (`__bp_result_*`/`__bp_option_*` → `lowerResultOptionOp`: a `@Result` is the idiomatic OTP pair `{ok, V}\|{error, E}` and a `@Option` the bare payload or atom `undefined`, mirroring the Erlang backend; `__bp_ok`/`__bp_error` build the pair for `return`/`throw` inside `*fn -> @Result` fns; `map`/`flatMap` apply the closure via `call_fun` and `map` rewraps with `put_tuple2`; `unwrapOr`/`isOk`/`isError` are tag tests — a bare-tail lambda body now returns its value via `emitLambdaBody`), loops, **static extension dispatch (F6)** (`implement`/`extend` methods reserved/emitted/exported as `'<target>_<method>'`; activated `recv.m(args)` via `dispatch_rewrites` → `call '<target>_m'(recv, args)` prepending the receiver; qualified `Sym.m(obj)` where `Sym` is an extension block → `call '<target>_m'(obj, args)` — see `ext_by_name`/`extMangledName`/`lowerExtCall`). **`erlc +from_asm`-correctness invariants** (validated by assembling + running the snapshots): comparisons use only `is_lt`/`is_ge` — BEAM has no `is_gt`/`is_le`, so `>`/`<=` swap operands (`comparisonTestOp`); atoms are quoted when not a valid unquoted atom (`atomName`/`isUnquotedAtom` — PascalCase enum tags `'Circle'`, `.dotIdent`, comptime-specialized `'execute_$0'`, component fns `'Widget'`); `{allocate, N, A}` is followed by `{init_yregs, …}` (`emitFrame`) so GC points never see uninitialised y-slots; `countLocalsRec` counts case-arm + destructure bindings so the frame is sized correctly. **Remaining gaps**: `negation_in_expression` `gc_bif` Live count; and cross-backend cases (also broken on Erlang): `new Error(…)`, `console.log`, cross-module fn imports, `*fn` async/`await`, typed-value method dispatch (`p.parse()`) |
| `wat.zig` | WebAssembly Text `.wat` emitter. Full coverage: numerics, locals, calls, assign, `!x`, null, `@todo`/`@panic`, globals, `_botopink_main`, case, pipeline (`a \|> f` → `call $f`), lambdas, loops, `@print` via WASI `fd_write`. **Aggregates in linear memory** — tuples/arrays/records/enum payloads are contiguous 4-byte slots in the bump heap (a type registry built from `record`/`struct`/`enum` decls distinguishes construction calls from function calls, since codegen is untyped); construction stashes the base in a `$__mem{n}` scratch local, destructuring and `t._N` access load by `offset`; enum payloads are `[tag, …fields]`. **Strings** — literal `+` → `$__str_concat` (`memory.copy`), literal `==`/`!=` → `$__str_eq` (byte loop). `try`/`catch` → `if` on the tag `i32` (payload at `offset=4`). **Static extension dispatch (F6)**: `implement`/`extend` methods emit as linear-memory functions `$<target>_<method>` keeping `self` as a real `i32` param (`emitExtensionMethods`); activated `recv.m(args)` (via `dispatch_rewrites`) and qualified `Sym.m(obj)` lower to `call $<target>_m` pushing the receiver (`lowerDispatchCall`). Caveat: named record-field access inside method bodies is still unsupported (`self.id` → `i32.const 0`), a pre-existing WAT gap affecting all methods, not dispatch. **`@Result`/`@Option` methods** (`__bp_result_*`/`__bp_option_*` → `lowerResultOptionOp`: a `@Result` is a pointer to `[tag, payload]` (tag `0` = Ok, like `try`/`catch`; `__bp_ok`/`__bp_error` allocate the pair for `return`/`throw` in `*fn -> @Result` fns), a `@Option` the bare value with `0` = None; `map`/`flatMap` **inline the closure body** — there are no first-class funs here, so a literal lambda's param binds to a `$_res{n}` local and `map` rewraps via a fresh heap slot; `unwrapOr`/`isOk`/`isError` are tag loads/branches). `wasmtime` runner |
| `typescript.zig` | `.d.ts` typedef generator (optional secondary output). Extension dispatch (F6) needs no call-site rewrite here: `.d.ts` is type-only and `implement`/`extend` blocks are invisible to the binding list, so there are no method-call sites to lower |
| `runtime.zig` | Test-side runtime helpers (executes generated code) |
| `snapshot.zig` | Codegen snapshot harness |
| `tests.zig` | Barrel aggregating `tests/<feature>.zig`; harness in `tests/helpers.zig` (`assertJs`, `assertJsSingle`, `assertJsError`, `configs`) |

## Quick-reference rules

- Emitters are **blind** — they never inspect `ExprKind.comptime_`; the
  transform pass has already resolved everything. Full rationale in
  [`./docs.md`](docs.md).
- `fn main()` triggers an entry-point wrapper (`_botopink_main()` in JS;
  quoted `'_botopink_main'/0` atom in Erlang). The Erlang atom **must**
  be quoted because plain atoms can't start with `_`.
- Erlang module-qualified calls: a PascalCase receiver (`List`) is a module
  reference → emitted as a remote call `list:map(…)` (lowercased via
  `erlangModule`); a lowercase receiver is treated as a value method call and
  left as-is (`isModuleRef` distinguishes them). Arity is the argument count
  (args + trailing lambdas).
- BEAM ASM and WAT backends cover the language broadly and reuse the
  existing comptime runtimes (`erlang` for BEAM, `node` for WASM). BEAM ASM
  still emits `%% unresolved`/`%% unsupported` comments for a few cross-backend /
  separate-feature cases (`new Error`, `console.log`, cross-module imports,
  mutable closure capture across `lists:foreach`, `*fn` async/`await`, Fase 9
  polish) — see the `beam_asm.zig` row above and [`/TODO.md`](../../../../TODO.md).
- `commonJS.emitFnJs` is the one **pub** single-fn emission hook — the
  comptime template evaluator (`comptime/template_eval.zig`) uses it to run
  template bodies in node. `emitJsonString` copies validated escape PAIRS
  verbatim (re-escaping the backslash doubled source escapes — `"\n"` used
  to print a literal `\n`); only real control chars and unescaped quotes
  (multiline content) are escaped.
- Expr templates: template fns (`-> @Expr<…>`) are comptime-only — the
  transform pass substitutes every call site with its expansion
  (`env.templateExpansions`, loc-keyed) and drops the declarations, so
  emitters never see them (nor the `@expr`/`@code` construction builtins,
  which only occur inside template bodies). KNOWN GAP: the typescript
  `.d.ts` emitter still declares template fns (renders `Expr<>`) — needs the
  same drop.
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
