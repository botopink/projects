# The comptime call path at HEAD

Traced 2026-09-20 on `feat` (before the same day's `.tasks/*` merges), file by file. Lines are those
of `repository/botopink-lang/modules/compiler-core/src/` unless the path says otherwise. The path is
the same for a decorator and a template; the two evaluators differ in what they put into the module
and the argument, not in how the runtime is driven.

## 1. One decorator evaluation

| # | Function | Where | What it decides |
|---|---|---|---|
| 1 | `infer.zig` builds a `DeclHandle` for the annotated declaration and calls `decoratorEval.evaluate(arena, io, build_root, dfn, handle, plainArgs, traces)` | `comptime/decorator_eval.zig:72` | `build_root` is ignored (`:82`); `traces` non-null under snapshots |
| 2 | `buildModule(arena, dfn, handle, plainArgs, &unsupported)` | `:228` | builds the `ast.Program` of one `fn` (`:240-241`), `mainForms` (`:236`), `preludeMod.decoratorForms` (`:237`) |
| 3 | `erlang.emitComptimeModule(arena, placeholder_module, program, config)` | `:255` → `codegen/erlang.zig:954` | the ordinary Erlang backend with `em.untyped = comptime_module != null` (`erlang.zig:1043`); `host_enums = {"DeclKind"}`, `host_records = {Span}`, `exports = {main/1}`, `resident = bp_comptime_decorator` (`decorator_eval.zig:242-253`) |
| 4 | `templateEval.argumentTerm(arena, plans)` | `:257` → `template_eval.zig:316` | the `@Decl` handle + annotation args as one `Term` tuple |
| 5 | `crossModule.erlDeclAtom(arena, comptime_owner, .dec, dfn.name, Wyhash(code))` | `:260` → `codegen/crossModule.zig:296` | the module atom `bp@comptime__dec__<name>__<16 hex>` — content-addressed, one per declaration |
| 6 | header rewrite `-module(placeholder)` → `-module(<atom>)` | `:264-266` | the emitter is called with a placeholder name so the hash is over the body |
| 7 | listing for snapshots: `cachedListing` or a second `emitComptimeModule` with `listing = true` | `:272-276` → `template_eval.zig:184`, `:192` | the `COMPTIME ERLANG` section; rendered once per module |
| 8 | `templateEval.ensureModule(arena, io, ".botopinkbuild/tmp/decorator", module, code)` | `:90` → `template_eval.zig:218` | `<dir>/<atom>.erl`; `writeModule` (`:230`) stages `<path>.<nonce>.tmp` and renames |
| 9 | `etf.encode(arena, source.argument)` | `:97` → `comptime/runtime/etf.zig:43` | version byte 131 + minimal tags per `Term` variant |
| 10 | `persistent_erl.evalWithArg(arena, io, path, module, arg)` | `:92` → `comptime/runtime/persistent_erl.zig:509` | see § 3 |
| 11 | `Response` → `parseOutcome(arena, stdout)` | `:113` → `:395` | JSON `{kind: "ok", contributions: […]}` / `{kind: "fail", message, span}` → `Outcome` |
| 12 | transport failure → `transportFailure` | `:100` → `:123` | reads `persistent_erl.lastTransportError()` (`:124`); none → `error.EvalFailed` = "erl/erlc missing", the caller's `PATH` hint |

The module that reaches the node (a real one from `.botopinkbuild/tmp/decorator/`, 18 lines, 816 B):

```erlang
-module(bp@comptime__dec__addhelper__68b14c5703e255d7).
-export([main/1]).
-import(bp_comptime_decorator, [fail/2, failAt/3, compilerError/1, emit/1, '__bp_emitted'/0, '__bp_add'/2, '__bp_len'/2, '__bp_text'/1, '__bp_json'/1]).

addHelper(Decl) ->
    emit('__bp_add'('__bp_add'(<<"pub fn helper_">>, maps:get(name, Decl)), <<"() -> i32 { return 42; }">>)).

main({Arg0}) -> …   % try addHelper(Arg0) … catch → JSON
```

Everything untyped is a call: `+` is `'__bp_add'/2`, `.length` is `'__bp_len'/2`, a field read is
`maps:get/2`. This is what a second lowering (BEAM or wat) has to reproduce.

## 2. One template evaluation

| # | Function | Where | Difference from the decorator |
|---|---|---|---|
| 1 | `templateEval.evaluate(arena, io, build_root, tfn, captures, plainArgs, traces)` | `comptime/template_eval.zig:97` | captures are `template.CapturedExpr`s |
| 2 | `buildModule` | `:504` | `captureToTerm` (`:605`) turns each `@Expr` capture into a `Term` map (`text`, `parts`, `source`, `bindings`, …); `resident = bp_comptime_template` |
| 3 | `emitComptimeModule` | `:530` (compilable), `:550` (listing) | same emitter, template prelude |
| 4 | `ensureModule(…, ".botopinkbuild/tmp/template", …)` | `:114` | directory differs |
| 5 | `persistent_erl.evalWithArg` | `:116` | identical |
| 6 | `parseOutcome` | `:701`, `Reply` at `:691` | kinds `code` / `value` / `capture` / `custom` / `fail` / else `err` |

A real template module (19 lines, 835 B): the body `conf(Q) -> T = text(Q), Port = '__bp_add'(8000,
'__bp_len'(T, length)), … expr({Port, Debug}).` and `main({Arg0}) -> try json:encode('__bp_reply'(conf(Arg0))) catch …`.

## 3. Inside `persistent_erl.zig`

| Step | Zig | Erlang (the server, `persistent_erl.zig:65-164`) |
|---|---|---|
| first request of the process | `ensureSpawned` `:242` → `residentModules` `:206` (server + 2 preludes) → `prepareServer` `:296`: hash `:193`, warm check `:303`, else write 3 `.erl` into `<hash>.<nonce>.tmp` `:320-325`, **spawn `erlc`** `:319`/`:327`, rename `:340` | — |
| | **spawn `erl -noshell -pa <dir> -eval "botopink_comptime_server:start(), halt()."`** `:268-273`; stdin/stdout piped, stderr → `erl.stderr.log` `:266` | `start/0`: `io:setopts(latin1)`, logger → stderr, `loop/0` |
| module not yet loaded in this process (`loaded` set `:502`) | cmd **2** with the `.erl` path `:521` | `compile_then` `:98`: **`compile:file(Path, [binary, return])`** `:99` → `load_then` `:106`: `code:purge` `:107`, `code:load_binary(Mod, "", Beam)` `:108` → reply the atom |
| every call site | cmd **3** `<u16 namelen><module><etf>` `:533-538` | `binary_to_atom`, `binary_to_term`, `safe_call(Mod, [Term])` `:117`: `spawn_monitor`, group leader `standard_error`, `apply(Mod, main, Args)`, `EVAL_TIMEOUT_MS = 10000` `:132` |
| reply | `readFrame` `:364` (cap 16 MiB `:173`) → `requestLocked` classifies by prefix `:470-484` → `Response { ok, compile_error, runtime_error }` `:426` | `write_frame` `:157`: `iolist_to_binary` or `__BP_ERL_RUNTIME_ERROR__:bad_result` |
| transport failure | `kill`, `init_state = 3`, `loaded.clear` `:462-465`; `lastTransportError` `:403` | — |

What stays runtime-independent in this table: the request shape (an atom + an ETF term), the reply
shape (bytes classified as ok / compile / runtime error), the timeout contract, the isolation of the
body's prints. What is BEAM-specific: `code:purge`/`code:load_binary`, `spawn_monitor`,
`binary_to_term`. What is `.erl`-specific: **`compile:file` and the `erlc` warm-up only.**

## 4. Every external process the compiler spawns

| Who | Spawns | When | Why | On the comptime path? |
|---|---|---|---|---|
| `comptime/runtime/persistent_erl.zig:319`, `:327` | `erlc -o <staging> <3 .erl>` | first evaluation per process, cold hash dir | compile the server + 2 preludes | **yes** |
| `comptime/runtime/persistent_erl.zig:268` | `erl -noshell -pa <dir> -eval …` | first evaluation per process | the resident node; `compile:file` runs inside it per declaration | **yes** |
| `codegen/runtime.zig:340`, `:375` | `node -e …` / `node <tmp>.js` | snapshot tests, `execute = true` (`codegen.zig:93`) | commonJS RUN LOG | no (target runtime) |
| `codegen/runtime.zig:419` | `node --check <file>` | after a failed node run | classify a syntax error | no |
| `codegen/runtime.zig:570`, `:597`, `:613` | `erlc -o .` ×2, `erl -noinput -pa . -s <mod> _botopink_main -s init stop` | snapshot tests | erlang RUN LOG | no |
| `codegen/runtime.zig:676`, `:705`, `:718` | `erlc +from_asm -o .` ×2, `erl …` | snapshot tests | beam RUN LOG | no |
| `codegen/runtime.zig:762` | `wasmtime run <mod>.wat` | snapshot tests | wasm RUN LOG | no |
| `modules/compiler-cli/src/cli/run.zig:89` | `node <entry>` / `wasmtime <entry>` (`:76-77`) | `botopink run` | run the user's program | no |
| `modules/compiler-cli/src/cli/run.zig:138`, `:147` | `erlc -o <dir> <all .erl>`, `erl -noshell -pa <dir> -eval "<mod>:main([]), halt()."` | `botopink run --target erlang` | run the user's program | no |
| `modules/compiler-cli/src/cli/test_cmd.zig:279`, `:308` | `node <file>` / `escript <file>` (`:164-165`) | `botopink test` | run the user's tests | no |
| `modules/lib-test-runner/src/runner.zig:60`, `:123` | the CLI, per library | `zig build test-libs` | — | no |
| `modules/bpmp/src/dep/clone.zig:180`, `:195` | `git` | `bpmp install` | dependencies | no |
| `modules/language-server/src/compiler.zig:48-52` | none directly — passes `eval_ctx` to `compileTypesOnly`, which reaches rows 1–2 | every LSP compile with an eval root | template expansion in the editor | **yes, transitively** |

The browser goal needs rows 1, 2 and the LSP's transitive use gone; every other row is the *target's*
VM and stays on a native host.

## 5. What the evaluators are allowed to know

After this front, `decorator_eval.zig` and `template_eval.zig` know: the `ast.Program`, the
`ComptimeModule` config, the argument `Term`, and a `Module` handle `{ atom, listing }`. They call
`runtime.evalWithArg(alloc, io, module, etf_bytes)` and read a `Response`. They do not know whether
the module was assembled to `.beam` or to wasm, or which executor ran it. The `Runtime = enum { erl }`
at `decorator_eval.zig:35` and `template_eval.zig:46` — two copies of a one-variant enum — become one
`ComptimeRuntime` in `runtime/runtime.zig`.
