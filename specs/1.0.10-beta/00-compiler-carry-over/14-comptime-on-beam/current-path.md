> Carried from `specs/1.0.5-beta/14-comptime-on-beam/current-path.md`, status at carry (2026-09-20): steps 0–2 landed (`bef762be`); step 3 is C-20, after C-01 (decisions 24 and 62)

# The comptime path today, end to end

Traced at `botopink-lang` `0e5ff66` (2026-09-17). Paths are relative to
`repository/botopink-lang/modules/compiler-core/`. Line numbers drift — re-locate by symbol;
[`../13-module-identity/`](../13-module-identity/README.md) already cites
`template_eval.zig:329-343` where this file reads `:315-345`.

---

## 1. The call path

```
botopink build / check / test          modules/compiler-cli/src/cli/build.zig
  └─ comptime.analyzeSource(…, eval_ctx = { io, build_root })      comptime.zig:1163-1180
       ├─ pass 1 — infer.invokeDecorators(env, program)            comptime/infer.zig:2365
       │    └─ decoratorEval.evaluate(…)                           comptime/infer.zig:2341
       │         (contributions parsed and merged, then pass 2 re-infers with
       │          invocation disabled — comptime.zig:329-350)
       └─ pass 2 — infer …
            └─ expandTemplateCallViaRuntime(…)                     comptime/infer.zig:3412
                 ├─ memo lookup (env.templateEvalCache)            comptime/infer.zig:3447-3472
                 └─ templateEval.evaluate(…)                       comptime/infer.zig:3475
```

`env.templateEval` is a `TemplateEvalCtx { io, build_root }` (`comptime/env.zig:198-201`,
`:385`). It is **optional**: the language server may compile types-only without it
(`comptime.zig:1163-1180`). The CLI always supplies it.

**Each evaluation is a single request.** `strace` counts 400 `readv` for 200 call sites — two per
request, one request per site ([`evidence.md` E6](./evidence.md#e6--where-the-wall-clock-goes)).
The two passes do not double-evaluate: pass 1 runs decorators, pass 2 runs templates, and pass 1's
traces are carried forward rather than re-produced (`comptime.zig:347-350`).

## 2. Building the module

`templateEval.evaluate` (`comptime/template_eval.zig:82`) and `decoratorEval.evaluate`
(`comptime/decorator_eval.zig:64`) are the same shape:

| Step | Template | Decorator |
|---|---|---|
| host glue as `erl_ast.Form`s | `hostForms` `:180` — 19 functions | `hostForms` `:134` — 6 functions |
| the evaluated data as a `Term` | `captureToTerm` `:372` (the capture map) | `handleToTerm` `:250` (the `@Decl` handle) |
| lower the body + glue to Erlang **source** | `buildModule` `:315` → `erlang.emitComptimeModule` (`codegen/erlang.zig:695`) | `buildModule` `:211` → the same |
| name the module | `template_<16 hex of Wyhash(code)>` `:340` | `decorator_<16 hex>` `:238` |
| write it | `writeModule(… ".botopinkbuild/tmp/template" …)` `:99` | `writeModule(… ".botopinkbuild/tmp/decorator" …)` `:82` |
| run it | `persistent_erl.evalDetailed(arena, io, path)` `:101` | the same `:84` |
| read the reply | `parseOutcome` — JSON `{kind, …}` | `parseOutcome` — JSON `{kind, contributions\|message\|span}` |

`emitComptimeModule` is the ordinary Erlang backend with one flag flipped:
`em.untyped = comptime_module != null` (`codegen/erlang.zig:777`). Untyped mode is what makes a
comptime body compile at all without inference having run over it — `+` becomes `'__bp_add'/2`,
`.len`/`.length`/`.size` becomes `'__bp_len'/2`, a method call nothing answers goes through
`untypedPrimCallNode` (`erlang.zig:5084`) and, failing that, is recorded in
`ComptimeModule.unsupported_method` so the evaluator can report a located diagnostic instead of
letting `erl_lint` say `{undefined_function, …}`.

**The module is rendered twice.** `buildModule` emits the compilable module, then re-emits with
`config.listing = true` and only the last host form, for the trace the snapshots print
(`template_eval.zig:333-338`, `decorator_eval.zig:231-236`). `infer.zig:3475` / `:2341` pass
`&env.comptimeTraces` unconditionally, so the second render always happens.

`writeModule` (`template_eval.zig:125-137`) creates the directory, writes to
`<path>.<random hex>.tmp` and renames it into place — so two compiler processes sharing a working
directory never read a partial file. `build_root` is accepted and discarded (`:92` `_ = build_root;`):
the artefacts land under the **current working directory**, not the build root.

## 3. What the generated module looks like

295 lines for the smallest realistic template
([`evidence.md` E4](./evidence.md#e4--every-call-site-compiles-the-same-program-again)):

| Part | lines | changes per call site? |
|---|---:|---|
| the lowered template body | 7 | no |
| 19 fixed host functions | 54 | no |
| `main/0` — the capture as a literal map | 230 | **yes, and only this** |

The host functions are the capture API (`text/1`, `parts/1`, `source/1`, `context/1`,
`bindings/1`, `lookup/2`, `ref/1`), the result constructors (`build/2`, `custom/3`, `expr/1`,
`code/1`), the failure throws (`fail/2`, `failAt/3`, `compilerError/1`), the reply encoder
(`'__bp_reply'/1`) and the untyped helpers (`'__bp_add'/2`, `'__bp_len'/2`, `'__bp_text'/1`,
`'__bp_json'/1` — `erlang.zig:630`, `comptime_helper_forms`). They are **byte-identical in every
template module the compiler has ever produced**.

`main/0` wraps the call in `try … catch` and answers `json:encode/1` of one of five shapes —
`code`, `value`, `capture`, `custom`, `fail`/`error` (`template_eval.zig:11-17`).

## 4. The runtime

`comptime/runtime/persistent_erl.zig` — one `erl` per Zig process, spawned lazily.

| Thing | Where | Detail |
|---|---|---|
| server source | `:41-136` | `botopink_comptime_server`, a `-eval`'d receive loop |
| server build | `prepareServer` `:234-274` | `erlc -o <staging> <server>.erl` `:255-257`, staged and renamed into `.botopinkbuild/tmp/persistent_erl/<server_hash>/` — `server_hash` is the Wyhash of the server source `:153-156`, so a warm directory skips `erlc` entirely |
| spawn | `ensureSpawned` `:187-226` | `erl -noshell -pa <hash dir> -eval botopink_comptime_server:start(), halt().` `:211` |
| protocol | `:7-11` | `<u32 BE len><cmd:u8><path>` up, `<u32 BE len><payload>` down; **cmd 1 is the only command** |
| the eval | `:64-80` | `compile:file(Path, [binary, return])` → `code:load_binary(Mod, "", Beam)` → `safe_call(Mod)` |
| isolation | `safe_call` `:89-108` | a monitored process with `standard_error` as its group leader and a 10 s budget (`eval_timeout_ms` `:139`) |
| stdout discipline | `:53-58` | `io:setopts(standard_io, [{encoding, latin1}])`, default logger handler moved to `standard_error`; stray bytes on stdout are caught as an over-cap frame (`max_frame_len` = 16 MiB `:145`) |
| failure | `request` `:375-404` | a transport error kills the child and marks the singleton broken; the next request respawns, the failed one is not retried |

**Nothing is cached on the erl side.** Every request is a fresh `compile:file`, even for a module
the node compiled a moment ago; `code:load_binary` replaces the previous version and nothing is
ever purged (no `code:purge/1` anywhere in the file), so a long-lived process accumulates loaded
modules — recorded by [`../13-module-identity/`](../13-module-identity/README.md) (1.0.4-beta's front 16)
as an unowned residual.

The Zig side does memoize: `env.templateEvalCache` (`infer.zig:3447-3472`, `:3558`), keyed by
callee name + capture texts + scope JSON + plain-arg sources, and **skipped** for a holed template
or an `@ExprCustom` return. It is per `Env`, so it does not survive a compiler process, and
identical texts at two sites hit it — 200 identical call sites cost one evaluation
([`evidence.md` E1](./evidence.md#e1--the-comptime-path-costs-25-ms-per-evaluation-linearly)).

## 5. What it costs

Per evaluation, ≈ 25 ms, of which ([`evidence.md` E2, E3, E6](./evidence.md#e2)):

| | ms | what it is |
|---|---:|---|
| `compile:file` in the node | 8 – 52 | the Erlang front end over a program that is the same every time |
| `code:load_binary` | ≈ 1.0 – 1.3 | replacing a module that differs from the last one in a data literal |
| `Mod:main()` | **0.05 – 0.24** | **the comptime body actually running** |
| the frame protocol | ≈ 0.4 | two writes, two reads |
| compiler side | ≈ 15 (295-line module) | rendering the module twice, building the `Term`, staging and renaming the file, parsing the JSON |
| once per compiler process | ≈ 145 | `erl` spawn + server load (bare VM floor: 76 ms) |

On `repository/erika/examples/erika-linq`: **942 ms** of `compile:file` and **0.99 ms** of body, in
a 1 593 ms build.

## 6. What is left behind

`.botopinkbuild/tmp/template/*.erl` and `.botopinkbuild/tmp/decorator/*.erl` are never deleted:
`repository/erika` holds 52 template modules where one build writes 12
([`evidence.md` E13](./evidence.md#e13--what-is-left-on-disk)). `.botopinkbuild/tmp/persistent_erl/`
holds one directory per server-source hash plus `erl.stderr.log` (truncated at each spawn,
`:161`).

## 7. The dependency surface

| Consumer | Needs | Even for `--target commonJS`? |
|---|---|---|
| **the comptime evaluator** | `erl` + `erlc` (`persistent_erl.zig:211`, `:256`) | **yes** — a template or a decorator in the program makes a JavaScript build fail without them ([`evidence.md` E7](./evidence.md#e7--a-template-makes-a-javascript-build-depend-on-erlang)) |
| the snapshot harness | `erlc`, `erlc +from_asm`, `erl -noinput` (`codegen/runtime.zig:545,565,638,660,581,673`) | no — test-time only |
| `botopink run` / `test` on erlang or beam | `escript` (`cli/run.zig:68`, `cli/test_cmd.zig:160`) | no — the user asked for that target |

Only the first row is this front's. Removing it would let a commonJS/wasm user build a program with
templates and decorators without OTP installed — **if** the evaluation can also *run* without a
BEAM VM, which is a different question ([`options.md`](./options.md)).
