# Evidence

Every measurement behind the README, with the command and the raw excerpt. Taken 2026-09-20 on
`feat` in `repository/botopink-lang` **before** the merges of `.tasks/{formatter,tooling,
wasm}`; those merges touch `wat.zig`, `infer.zig`, the formatter and 7 snapshots, so line numbers
in `wat.zig` may have drifted by a few lines — re-locate by symbol. Host: Linux, Zig 0.16.0,
OTP 29 / ERTS 17.0.6, node 25.8.0, wasmtime 45.0.0. Paths below are relative to
`repository/botopink-lang/modules/compiler-core/` unless absolute.

## E-1 — the runtime enum, and the two evaluators

```
$ grep -n "pub const Runtime" src/comptime/decorator_eval.zig src/comptime/template_eval.zig
src/comptime/decorator_eval.zig:35:pub const Runtime = enum { erl };
src/comptime/template_eval.zig:46:pub const Runtime = enum { erl };
```

`evaluate` at `decorator_eval.zig:72` / `template_eval.zig:97`; `buildModule` `:228` / `:504`;
`emitComptimeModule` calls `:255` / `:530`+`:550`; `erlDeclAtom` `:260`; `ensureModule` `:90` /
`:114` (def `template_eval.zig:218`, `writeModule` `:230`); `evalWithArg` `:92` / `:116`;
`etf.encode` `:97` / `:121`; `parseOutcome` `:113`→`:395` / `:701`; `transportFailure` `:123` / `:255`.

## E-2 — every external process spawn in the tree

```
$ grep -rn "std.process.spawn\|std.process.run\|std.process.Child\|ChildProcess" --include=*.zig modules build.zig
modules/compiler-cli/src/cli/test_cmd.zig:279:            const result = std.process.run(arena, io, .{
modules/compiler-cli/src/cli/test_cmd.zig:308:        var child = std.process.spawn(io, .{ .argv = argv.items }) catch |err| {
modules/compiler-cli/src/cli/run.zig:89:    var child = std.process.spawn(io, .{ .argv = argv.items }) catch |err| {
modules/compiler-cli/src/cli/run.zig:178:    var child = std.process.spawn(io, .{ .argv = argv }) catch |err| {
modules/compiler-core/src/codegen/runtime.zig:108:    const result = std.process.run(allocator, io, .{
modules/compiler-core/src/codegen/runtime.zig:761:    const result = std.process.run(allocator, io, .{
modules/compiler-core/src/comptime/runtime/persistent_erl.zig:268:            const child = try std.process.spawn(io, .{
modules/compiler-core/src/comptime/runtime/persistent_erl.zig:327:    const compile_result = std.process.run(allocator, io, .{
modules/lib-test-runner/src/runner.zig:60:    const result = std.process.run(arena, io, .{
modules/lib-test-runner/src/runner.zig:123:    const result = std.process.run(arena, io, .{
modules/bpmp/src/commands/install.zig:488:    const result = std.process.run(gpa, testing.io, .{
modules/bpmp/src/dep/clone.zig:180:    var child = try std.process.spawn(io, .{
modules/bpmp/src/dep/clone.zig:195:    const result = try std.process.run(gpa, io, .{ .argv = argv });
modules/bpmp/src/extract.zig:205:    const run_result = std.process.run(testing.allocator, testing.io, .{
```

Literal runtime names (`"erl"`, `"erlc"`, `"escript"`, `"node"`, `"wasmtime"`), spawn sites only:

```
compiler-cli/src/cli/run.zig:76-77        .commonJS => "node",  .wasm => "wasmtime"
compiler-cli/src/cli/run.zig:138          try argv.append(arena, "erlc");
compiler-cli/src/cli/run.zig:147          spawnWait(… &.{ "erl", "-noshell", "-pa", dir, "-eval", eval })
compiler-cli/src/cli/test_cmd.zig:164-165 .commonJS => "node",  .erlang => "escript"
compiler-core/src/codegen/runtime.zig:340,375  "node" …   :419 "node", "--check"
compiler-core/src/codegen/runtime.zig:570,597  "erlc", "-o", "."    :613 "erl", "-noinput", "-pa", ".", "-s", entry, "_botopink_main", "-s", "init", "stop"
compiler-core/src/codegen/runtime.zig:676,705  "erlc", "+from_asm", "-o", "."    :718 "erl" …
compiler-core/src/codegen/runtime.zig:762      "wasmtime", "run", basename
compiler-core/src/comptime/runtime/persistent_erl.zig:269  "erl", "-noshell", "-pa", beam_dir, "-eval", "botopink_comptime_server:start(), halt()."
compiler-core/src/comptime/runtime/persistent_erl.zig:319  "erlc", "-o", staging
```

Only the last two are on the comptime path. `modules/language-server/src/compiler.zig:48-52` passes
`eval_ctx` to `compileTypesOnly`, reaching them transitively.

## E-3 — the cost, as measured by front 14 (not re-run here — `zig build` is not permitted in this pass)

From `specs/1.0.10-beta/00-compiler-carry-over/14-comptime-on-beam/README.md` § *Landed*, same
machine, OTP 29, `scripts/comptime_bench.sh --n 0,1,10,50,200 --repeat 3 --reps 10 --project
…/erika-linq`, after steps 0–2:

| | before | step 2 |
|---|---:|---:|
| build, N=200 | 6 172 ms | **2 172 ms** |
| ms per evaluation | 29.6 | **9.4** |
| `.erl` modules / bytes at N=200 | 200 / 2 833 290 | **1 / 875** |
| in-node `compile:file`, N=200 | 2 024.9 ms | **3.8 ms** |
| erika-linq build | 1 934 ms | **645 ms** |
| erika-linq erl side (compile + load) | 1 039.3 ms | **49.0 ms** |
| `code:load_binary` per module | ≈ 1.0–1.3 ms | same |
| body (`main`) | 0.05–0.99 ms | same |
| `erl` spawn + server load, once per process | ≈ 145 ms (bare VM 76 ms) | same |
| `erlc +from_asm` vs source on the 14-line module | 1.29 ms → **0.39 ms** | (front 14 E5/E8) |
| `buildModule` compiler-side | 16.1 ms (emitter re-parses `primitives.bp` + `erlang_bifs.d.bp` per emission) | not this front's |

Step 0 re-runs the script and replaces this table.

## E-4 — what one declaration emits today

```
$ ls .botopinkbuild/tmp/template/*.erl | wc -l;  cat .botopinkbuild/tmp/template/*.erl | wc -c
81   251436
$ ls .botopinkbuild/tmp/decorator/*.erl | wc -l; cat .botopinkbuild/tmp/decorator/*.erl | wc -c
102  193887
$ wc -lc .botopinkbuild/tmp/template/bp@comptime__tpl__conf__5ba2d1ae639515c9.erl
19 835
$ head -12 …/bp@comptime__tpl__conf__5ba2d1ae639515c9.erl
-module(bp@comptime__tpl__conf__5ba2d1ae639515c9).
-export([main/1, conf/1]).
-import(bp_comptime_template, [text/1, parts/1, source/1, context/1, bindings/1, lookup/2, ref/1, build/2, custom/3, fail/2, failAt/3, compilerError/1, expr/1, code/1, '__bp_reply'/1, '__bp_add'/2, '__bp_len'/2, '__bp_text'/1, '__bp_json'/1]).

conf(Q) ->
    T = text(Q),
    Port = '__bp_add'(8000, '__bp_len'(T, length)),
    Debug = true,
    expr({Port, Debug}).

main({Arg0}) ->
    try
$ wc -lc .botopinkbuild/tmp/decorator/bp@comptime__dec__addhelper__68b14c5703e255d7.erl
18 816
```

The 183 files span several compiler versions (the directory is never reaped except by `botopink
clean`); the two shown are current-shape (`main/1`, `-import`).

## E-5 — the resident modules and a `.beam`'s chunks

```
$ ls -la .botopinkbuild/tmp/persistent_erl/b8e2d74b59baf508/
botopink_comptime_server.beam 3764   botopink_comptime_server.erl 4583
bp_comptime_decorator.beam    2140   bp_comptime_decorator.erl    1373
bp_comptime_template.beam     3200   bp_comptime_template.erl     2465
```

Chunk table, read by a 10-line Python IFF walker over each file:

```
botopink_comptime_server.beam 3764 bytes FOR1 size 3756 | AtU8:593 Code:1426 StrT:0 ImpT:292 ExpT:40 FunT:52 LitT:394 Meta:45 LocT:100 Attr:39 CInf:239 Dbgi:126 Line:198 Type:79
bp_comptime_decorator.beam    2140 bytes FOR1 size 2132 | AtU8:385 Code:585  StrT:0 ImpT:172 ExpT:136 FunT:28 LitT:46  Meta:45 LocT:40  Attr:39 CInf:236 Dbgi:126 Line:147 Type:15
bp_comptime_template.beam     3200 bytes FOR1 size 3192 | AtU8:565 Code:1255 StrT:0 ImpT:148 ExpT:256 FunT:28 LitT:123 Meta:45 LocT:52  Attr:39 CInf:235 Dbgi:126 Line:171 Type:19
```

Fourteen chunks from `erlc`; the loadable minimum is `AtU8 Code StrT ImpT ExpT (FunT) (LitT) Line`.

## E-6 — snapshot counts

```
$ for d in snapshots/codegen/*/; do echo "$d $(ls $d | wc -l)"; done
snapshots/codegen/beam/ 333   commonJS/ 334   erlang/ 334   errors/ 4 (dirs)   wasm/ 333
$ for d in snapshots/codegen/errors/*/; do echo "$d $(ls $d | wc -l)"; done
errors/beam/ 3   errors/commonJS/ 3   errors/erlang/ 3   errors/wasm/ 3
$ find snapshots/codegen -type f | wc -l            → 1346
$ du -sb snapshots/codegen/*
1392160 beam   531326 commonJS   375431 erlang   3280 errors   1387012 wasm      (Σ 3 689 209)
$ ls snapshots/comptime/ast | wc -l; ls snapshots/comptime/errors | wc -l; ls snapshots/comptime/templates | wc -l
202  137  1
$ for d in beam commonJS erlang wasm; do grep -rl 'COMPTIME REPLY' snapshots/codegen/$d | wc -l; done
7 7 7 7
$ grep -rl 'COMPTIME ERLANG' snapshots/comptime | wc -l      → 5   (all under comptime/ast/)
$ grep -rl 'COMPTIME VALUES' snapshots/codegen/beam | wc -l   → 11
$ grep -rl 'RUN LOG' snapshots/codegen/beam | wc -l; grep -rl 'RUN LOG' snapshots/codegen/wasm | wc -l
324 324
```

Directory selection: `src/codegen/snapshot.zig:205` (`"codegen/{s}/{s}"`), `:230`
(`"codegen/errors/{s}/{s}"`); `src/comptime/snapshot.zig:1509` (`"comptime/ast/{s}"`);
`src/comptime/tests/helpers.zig:249` (`"comptime/errors/{s}"`); `src/utils/snap.zig:6` `SNAP_DIR`,
`:46` `checkText`, `:67` `BOTOPINK_SNAP_CREATE`, `:138-207` `compareOrCreate` (`.new` at `:147`,
`:182`; `SnapshotMissing` `:155`; `SnapshotMismatch` `:207`). Harness loop:
`src/codegen/tests/helpers.zig:19-36` `configs`, `:198` `for (configs)`.

History (`git log`, read-only):

```
96ff2030 2026-09-15 refactor(codegen): flatten the snapshot tree to codegen/<target>/
   "Snapshots lived under codegen/<legacy runtime>/<target>/ (node/commonJS, erlang/erlang, beam/beam,
    wasm/wasm), a leftover of the four comptime runtimes kept only to avoid moving files … legacyRuntimeTag is gone.
    Pure move." — 1121 files changed, 8 insertions, 27 deletions; the deleted fn:
      fn legacyRuntimeTag(target) { .commonJS => "node", .erlang => "erlang", .beam => "beam", .wasm => "wasm" }
579ab0d0 2026-09-18 refactor(comptime): one snapshot per test, not four byte-identical copies per slug
   "1079 files (node 337, erlang 337, beam 202, wasm 202, templates 1) … After: 338 files (ast 202, errors 135, templates 1)"
```

## E-7 — `beam_asm.zig` has no comptime path

```
$ grep -n -i 'ComptimeModule\|untyped' src/codegen/beam_asm.zig | head
245:fn condLoopJumpHasValue(body: []const ast.Stmt, comptime kind: std.meta.Tag(ast.JumpExprOf(.untyped))) bool {
1408:    /// The run-time primitive dispatch shims some untyped call site reached,
1441:    /// One `'__bp_prim_<callee>'/<argc + 1>` run-time dispatch shim an untyped
…   (0 × ComptimeModule)
$ sed -n '911,915p' src/codegen/beam_asm.zig
pub fn codegenEmit(alloc, outputs: []ComptimeOutput, config) !ArrayListUnmanaged(ModuleOutput)
$ sed -n '1,4p' src/codegen/beam_asm.zig
/// BEAM Assembly (`.S`) codegen backend.
/// Emits the textual format produced by `erlc +to_asm <file>.erl`, which
/// `erlc +from_asm <file>.S` can re-assemble back to a `.beam`.
$ grep -n "erlc\|beam_lib\|code:load\|compile:forms" src/codegen/beam_asm.zig | wc -l   → 3 (all comments about +from_asm)
```

`beam_emitter.zig` write functions (the `.S` model): `Operand` `:27`, `writeLiteral` `:226`,
`writeMove` `:233`, `writeModuleForm` `:271`, `writeExports` `:278`, `writeAttributes` `:290`,
`writeLabels` `:295`, `writeLabel` `:300`, `writeFunctionHeader` `:305`, `writeFuncInfo` `:312`,
`writeLine` `:321`, `writeMoveOp` `:326`, `writeJump` `:334`, `writeReturn` `:341`, `writeAllocate`
`:346`, `writeDeallocate` `:351`, `writeInitYregs` `:356`, `writeTest` `:367`, `writeTestHeap` `:377`,
`writeTestHeapAlloc` `:383`, `writeGcBif` `:391`, `writeBif` `:402`, `writeCall` `:424`, `writeTry`
`:446`, `writeTryEnd` `:451`, `writeTryCase` `:456`, `writeCallFun` `:461`, `writeMakeFun3` `:468`,
`writePutList` `:475`, `writePutTuple2` `:484`, `writeGetTupleElement` `:494`. `erlang.zig`:
`ComptimeModule` `:452`, `Resident` `:487`, `UnsupportedMethod` `:481`, `emitComptimeModule` `:954`,
`em.untyped = comptime_module != null` `:1043`.

## E-8 — `wat.zig`: untyped input, one host import, 22 static-gap carriers

```
$ grep -c 'ast.TypedExpr\|ExprOf(.typed)\|TypedStmt' src/codegen/wat.zig   → 0
$ grep -c 'ExprOf(.untyped)\|ast.Expr\b' src/codegen/wat.zig             → 65
$ grep -n 'untyped' src/codegen/wat.zig | head -3
576:    // ── type registry (codegen is untyped, so we recover record/enum layout
592:    /// a fn whose return type is a record). Codegen is untyped so this map is a
616:    /// inference. The one piece of type information this untyped backend is
$ grep -n '(import ' src/codegen/wat.zig src/codegen/wat/*.zig
src/codegen/wat/wat_emitter.zig:51:    try w.print("  (import \"{s}\" \"{s}\" (func ${s}", …
src/codegen/wat/wat_emitter.zig:310:  (import "wasi_snapshot_preview1" "fd_write" …   (a test)
$ sed -n '65,70p' src/codegen/wat/wat_prelude.zig
pub const fd_write_import = ast.Import{ .module = "wasi_snapshot_preview1", .name = "fd_write", … };
$ awk '/pub const HelperGroup = enum/,/};/' src/codegen/wat/wat_ast.zig | grep -c '^\s*[a-z_0-9]*,'   → 42
$ grep -n 'self.note(\|self.noteF(\|emitC(zero\|emitCf(.drop' src/codegen/wat.zig
1466 unsupported param destructure pattern      2642 field assign (unknown receiver type)
2675 unsupported destructure pattern            2923 unknown variant
2943 unsupported pipeline rhs                   2959 range
2987 continue outside a loop                    2996 unsupported expr: {s}
3330 builtin stub                               3559, 3650 map/flatMap needs a literal closure on WASM
3679 None — propagate absence                   3715 unsupported Result/Option op: {s}
3966 unknown variant pattern                    4203 array spread not lowered
4351 extra argument ignored                     6522 §10: a search that never breaks has no value
6529 decision 52: it has not broken yet         6558 loop over unknown iterable
7150 none equals no value                       7209 unsupported binary op for {s}
   (22 sites; `:1236` is `noteF`'s own body)
$ grep -c 'json' src/codegen/wat.zig → 0;  'put_map\|map literal' → 0;  'closure' → 27;  'Dict' → 6 (:937, :3351-3352, :4303, :5796, :5808 — "no lowering here")
```

`zero` carrier defined `:56`; `emitC` `:1205`, `note` `:1231`, `noteF` `:1235`; `codegenEmit` `:125`.

## E-9 — what the 183 on-disk comptime modules use

`grep -l <pattern> .botopinkbuild/tmp/{template,decorator}/*.erl | wc -l` over 183 files:

```
maps:get 159   maps: 159   lists:map|foldl|foreach|filter 54   lists: 128   string: 129
binary:|byte_size 5   fun( 141   case  161   '__bp_prim_ 14   '__bp_add' 183   '__bp_len' 183
json: 183   io_lib|integer_to_binary|float_to_binary 131   unicode: 0
iolist_to_binary|list_to_binary 131   erlang: 161   try 183   <<" 183   #{ 183   throw( 125
lookup(|parts(|source(|context(|bindings(|ref( 67   custom( 59   build( 73   emit( 80
spawn 0   receive 0   ets 0
```

## E-10 — wasm3 and the WAT runtime, in history

```
$ ls modules/                         → bpmp compiler-cli compiler-core language-server lib-test-runner   (no wasm3)
$ grep -rln "wasm3" . --include=*.zig --include=*.md --include=*.sh --include=*.zon
./modules/compiler-core/src/comptime/tests/AGENTS.md          (":21 the four-runtime architecture collapsed in v0.beta.21 (wasm3-unified-runtime)")
./.zig-cache/o/*/cimport.zig  ×4                               (236 m3_/M3 symbols in one — the deleted vendoring's translate-c output)
$ git log --oneline -S"wasm3" -- build.zig modules vendor
2997a5bc docs(hygiene): erase the removed WAT runtime's leftovers (09 step 2, group A)      2026-09-17
6cd0b70d feat(runtime): executeWat runs wasmtime; wasm RUN LOGs are real (step 3)             2026-09-17
181ae2be fix(wat): delete Module.externs, emitFnWat and the wat_runtime surface
720072eb refactor(comptime): fold comptime vals in Zig without erl
caa7377d Remove wasm3 vendored module and WAT runtime files                                   2026-06-29
   "Delete modules/wasm3/ (~40 C sources), wasm3_host.zig, wasm.zig, wat_to_wasm.zig, and wat_runtime.zig.
    Remove all wasm3.link calls from build.zig. Stub out executeWat … Remove evaluateWat() from template_eval.zig and decorator_eval.zig."
f64c7ede Switch comptime eval to persistent erl subprocess
c2587300 add AtomVM module and comptime runtime host layer
```

Front 14 `history.md:17`: "wasm3 + a WAT prelude, `modules/wasm3/` (≈ 40 C sources) + `wat_runtime.zig` /
`wat_to_wasm.zig` — until 2026-06-27 — ~160 lines of inline WAT for a bump allocator, `fd_write`,
descriptor walkers". `specs/1.0.4-beta/09-hygiene/wat-runtime.md` swept its comments; `config.zig:20-24`
still says the `comptimeRuntime` field was removed.

## E-11 — OS-dependent `std` in compiler-core (tests excluded)

```
std.process.            9 sites / 3 files:  codegen/runtime.zig  comptime/runtime/persistent_erl.zig  utils/snap.zig
std.fs.                 9 / 3:  the same three
std.Thread              4 / 3:  codegen/erlang.zig:240 (yield)  comptime.zig:442 (comment)  persistent_erl.zig (tests)
std.Io.Dir.cwd         27 / 4:  the three + comptime/template_eval.zig
std.posix               1 / 1:  utils/snap.zig:127
std.heap.page_allocator 8 / 4:  erlang.zig:230  persistent_erl.zig  template_eval.zig  comptime.zig
std.time.               2 / 2:  runtime.zig  persistent_erl.zig
io.random               3 / 3:  runtime.zig  persistent_erl.zig  template_eval.zig
```

`build.zig`: `grep -n 'wasm32\|freestanding\|wasi' build.zig` → 0; `libcResolvedTarget` `:398-407`
(glibc 2.38 pin for linux-gnu only); `test` step `:134`; `test-libs` `:296`; `test-backends` `:353`.

## E-12 — not verified in this pass

- **Suite wall time.** The coordinator's "~17 s" for `zig build test` is not in `AGENTS.md`,
  `modules/compiler-core/AGENTS.md`, `src/codegen/tests/AGENTS.md` or `scripts/AGENTS.md` (grep for
  `s\b` timings finds only `scripts/AGENTS.md:212` "tens of seconds inside erl" for `test-libs`). Not
  measured: `zig build` was not run in this pass. Step 0 measures it.
- **Native binary size.** `zig-out/` is absent in this checkout.
- **Zig 0.16 `std.Io` on `wasm32-wasi`.** Not attempted; recorded as step 5's first task.
- **`beam_asm.zig` line numbers after the `.tasks/wasm` merge** — the merge touched `wat.zig`, not
  `beam_asm.zig`; `wat.zig` lines above may have moved.
- **OTP `json:encode` float format on the 33 fixtures** — none of the 7 codegen `COMPTIME REPLY`
  samples inspected carries a float; not exhaustively checked.

## E-13 — toolchain on this host, and CI's

```
$ command -v erl erlc escript node wasmtime wasm-tools wat2wasm zig
/usr/bin/erl  /usr/bin/erlc  /usr/bin/escript  …/node  ~/.wasmtime/bin/wasmtime  MISSING  MISSING  /usr/local/bin/zig
$ erl -noshell -eval 'io:format("OTP ~s ERTS ~s~n",[erlang:system_info(otp_release), erlang:system_info(version)]), halt().'
OTP 29 ERTS 17.0.6
$ zig version → 0.16.0     node --version → v25.8.0     wasmtime --version → wasmtime 45.0.0
```

`.github/workflows/test.yml:60-101`: `erlef/setup-beam@v1` with `otp-version: '28'` (linux),
`brew install erlang` (macos), wasmtime from the GitHub release tarball; windows-2022 allowed to fail.

## E-14 — worktrees at measurement, and after

```
$ git worktree list                                  (before)
…/repository/botopink-lang  d55a3b87 [feat]
…/.tasks/beammem    [fix/beam-memory]     …/.tasks/ecosystem [fix/index-behaviors]   …/.tasks/formatter [fix/fits]
…/.tasks/identity   [fix/identity-halves] …/.tasks/tooling   [fix/tooling-step5]     …/.tasks/wasm      [fix/wasm-patterns]
$ per worktree: git status --short | grep -c snapshots/
wasm 6 (codegen/wasm/loop_*.snap.md)   tooling 1 (language-server/snapshots/lsp/completion_decorator_record)   others 0
```

Same day, later: `formatter`, `tooling`, `wasm` committed as-is, merged `--no-ff` into `feat`
(`d55a3b87..56369e55`, gate green at the tip, pushed to `origin/feat`), worktrees removed;
`beammem` (compile error in `infer.zig:2870`, `comptime.types` has no `typeToString`), `ecosystem`
(8 snapshot mismatches) and `identity` (7 mismatches, all `codegen/erlang/external_*`) left in place
with their changes staged and uncommitted because their pre-commit hooks failed.
