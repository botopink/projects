# Front 18 — comptime runtimes: BEAM direct, WAT, and the browser build

**Track:** compiler (carry-over item **C-26**; absorbs and extends **C-20**)
**Priority:** high — every `botopink build` of a project with one template or one decorator spawns
`erl` (`src/comptime/runtime/persistent_erl.zig`; `erlc` left the run-time path with decision 83, step 1c
landed); a browser has neither, so
the compiler cannot run where the language's own playground, docs and the `commonJS`/`wasm` targets'
users are. This front is what makes compiler-core hostable on wasm: the comptime path stops needing
a process it can spawn. It also closes C-20 (decision 24: *no Erlang source in the compile path*)
by going one step past it — no Erlang *compiler* in the compile path either.
**Depends on:** C-01 for **step 1 only** — the module atom a `.beam` carries in its `AtU8` table and
`{module, …}` header is the one `crossModule.erlDeclAtom` (`src/codegen/crossModule.zig:296`) mints,
and C-01 re-shapes that atom. Steps 0, 2, 3 (selector), 4 (layout) and 5 (browser) do **not**
depend on C-01: the wat runtime names no atom, the layout is a harness change, and the browser build
ships the wat runtime alone.
**Owns:** `src/comptime/runtime/**` (landed: `server_source.zig`, `render_resident.zig`, the cmd-4
path in `persistent_erl.zig`, `persistent_wat.zig`, `wat/`, `runtime.zig` the dispatcher, `parity.zig`,
`reply_order.zig`; remaining: the `persistent_beam.zig` rename) · `src/codegen/beam/beam_file.zig` +
`opcodes.zig` + `gen_opcodes.sh` (landed) · the comptime half of `src/codegen/beam_asm.zig` (the
untyped lowering mode, remaining) · the binary emitter `src/codegen/wat/wasm_binary_emitter.zig`
(landed) ·
`src/codegen/snapshot.zig` + `src/comptime/snapshot.zig` + `src/utils/snap.zig` (directory
selection) · `snapshots/codegen/**` (the re-layout, all 1 346 files) · root `build.zig` (the
`render-resident` + `erlc` step and the `compiler-web` wasm build, landed) · `modules/compiler-web/**` (landed) · `modules/wasm3/**` (re-vendored) · `scripts/comptime_bench.sh`
**Does not touch:** the run-time halves of `beam_asm.zig`, `erlang.zig`, `wat.zig`, `commonJS.zig`
(C-01, C-06, C-07 own them; this front adds a *mode*, never edits a typed lowering) · the five
library repositories · `src/comptime/eval.zig` (Zig-folded `COMPTIME VALUES`, runtime-independent) ·
`src/comptime/infer.zig`

---

## Problem

Reproducible on this machine (OTP 29, ERTS 17.0.6, zig 0.16.0, 2026-09-20):

```
$ cd <project with one template>; botopink build --target commonJS
# spawns:  erlc -o .botopinkbuild/tmp/persistent_erl/<hash>.<nonce>.tmp  botopink_comptime_server.erl bp_comptime_template.erl bp_comptime_decorator.erl
#          erl -noshell -pa .botopinkbuild/tmp/persistent_erl/<hash> -eval "botopink_comptime_server:start(), halt()."
# then, per declaration:  compile:file/2 + code:load_binary/3 inside that erl; per call site: <module>:main(<term>)
```

Without `erl`/`erlc` on `PATH` the first evaluation fails as `error.PersistentErlNotFound`
(`persistent_erl.zig:331`) → `error.EvalFailed` → the caller's hint names `PATH`
(`decorator_eval.zig:124`, `template_eval.zig:256`). A JavaScript build, whose *target* needs no
BEAM, cannot compile a program that uses one decorator. A browser has no `erl`, no `erlc`, no
process spawn — today's compiler cannot run there at all, and nothing in the tree builds it for
`wasm32` (`build.zig`: no `wasm32`, no `freestanding`, no `wasi`; `modules/wasm3/` does not exist).

## Current state

Measured at `feat`, 2026-09-20, before the `.tasks/{formatter,tooling,wasm}` merges; every command and raw
excerpt in [`evidence.md`](./evidence.md), the call path in [`current-path.md`](./current-path.md).

| Fact | Value | Where |
|---|---|---|
| comptime runtimes | **one**, `erl` — `pub const Runtime = enum { erl }` twice | `decorator_eval.zig:35`, `template_eval.zig:46` |
| external processes on the comptime path | `erlc` (warm-up, once per resident-source hash) and `erl` (once per compiler process) | `persistent_erl.zig:319`, `:268` |
| what one declaration emits today | one `.erl` per declaration: **835 B / 19 lines** (template), **816 B / 18 lines** (decorator) — the lowered body, `-import` of the resident prelude, `main/1` | `.botopinkbuild/tmp/{template,decorator}/*.erl`, E-4 |
| what the node does with it | `compile:file(Path, [binary, return])` → `code:purge` → `code:load_binary` → `spawn_monitor` `main/1` | `persistent_erl.zig:99`, `:107-108`, `:118` |
| what that costs | `compile:file` **3.8 ms** for the whole N=200 build, ≈ 47 ms on `erika-linq` (12 distinct declarations); `code:load_binary` ≈ 1.0 ms; the body 0.05–0.99 ms; `erl` spawn + server load ≈ 145 ms once per process | front 14 § *Landed*, `scripts/comptime_bench.sh` |
| the resident glue | 3 Erlang **source** modules compiled by `erlc` at warm-up: server 4 583 B, `bp_comptime_template` 2 465 B, `bp_comptime_decorator` 1 373 B → `.beam` 3 764 / 3 200 / 2 140 B | `.botopinkbuild/tmp/persistent_erl/<hash>/`, E-5 |
| a loadable `.beam` needs | `FOR1`/`BEAM` + chunks `AtU8 Code StrT ImpT ExpT FunT LitT Line` (+ optional `Meta LocT Attr CInf Dbgi Type`) | E-5, [`beam-file-format.md`](./beam-file-format.md) |
| `.S` → `.beam` in Zig today | **nothing** — `beam_asm.zig` renders text for `erlc +from_asm` (`:3-4`); `runtime.zig:676` spawns `erlc +from_asm` for the target's RUN LOG | `beam_asm.zig:1-19`, `beam/beam_emitter.zig` |
| `beam_asm.zig`'s input | typed `ComptimeOutput` (`:913`); **0** occurrences of `ComptimeModule`/untyped mode | E-7 |
| `wat.zig`'s input | untyped `ast.Expr` — 65 uses, 0 `TypedExpr` ("codegen is untyped", `:576`, `:592`, `:616`) | E-8 |
| host imports a `wat.zig` module needs | **exactly one**: `wasi_snapshot_preview1.fd_write` (`wat/wat_prelude.zig:65`); every other helper is synthesised (42 `HelperGroup`s) | E-8 |
| `wat.zig` constructs it cannot lower | **22** carrier sites (`note`/`noteF`/`emitC(zero, …)`): the full table in [`wat-runtime.md`](./wat-runtime.md) § 4 | E-8 |
| what the 183 on-disk comptime modules use | `maps:get` 159 · `case` 161 · `fun(` 141 · `string:` 129 · `lists:` 128 · JSON reply 183 · `try`/`throw` 183/125 · `'__bp_add'`/`'__bp_len'` 183 | E-9 |
| snapshot directories | `codegen/{beam 333, commonJS 334, erlang 334, wasm 333, errors/{beam,commonJS,erlang,wasm} 3 each}` = **1 346 files, 3.69 MB**; `comptime/{ast 202, errors 137, templates 1}` | E-6 |
| snapshots that can differ per runtime | **33**: 7 per `codegen/<target>` (28) + 5 in `comptime/ast/` — the ones with `COMPTIME ERLANG`/`COMPTIME REPLY`; `COMPTIME VALUES` (11 in `codegen/beam`) are Zig-folded | E-6 |
| how the harness picks the directory | `codegen/{targetSource}/{slug}` (`codegen/snapshot.zig:205`), `codegen/errors/{targetSource}/{slug}` (`:230`); `comptime/ast/{slug}` (`comptime/snapshot.zig:1509`) | — |
| the layout's history | `codegen/<runtime>/<target>/` existed until 2026-09-15 as a **legacy 1:1 tag** (`node/commonJS`, `beam/beam`, …), never a cross product; flattened when `legacyRuntimeTag` was deleted | E-6 |
| wasm3 | vendored as `modules/wasm3/` (≈ 40 C sources) + `wat_runtime.zig` + `wat_to_wasm.zig` until 2026-06-29, then deleted; only `.zig-cache` `cimport.zig` leftovers remain (236 `m3_`/`M3` symbols) | E-10 |
| OS-dependent `std` in compiler-core | `std.process`/`std.fs`: 3 files (`codegen/runtime.zig`, `comptime/runtime/persistent_erl.zig`, `utils/snap.zig`); `std.Io.Dir.cwd`: + `comptime/template_eval.zig`; `std.Thread`: `erlang.zig:240` (`yield`), tests | E-11 |
| toolchains CI installs | OTP 28 (`erlef/setup-beam`), wasmtime, node; windows allowed to fail | `.github/workflows/test.yml:60-101` |

### Landed since (compiler `feat`, 2026-09-20 — steps 0, 1a, 1c)

| What | Where | Decision |
|---|---|---|
| the `.beam` container writer: `Module → Function → Instr { op: Op, args } → Arg` (`u i atom nil x y f literal ext list alloc line`), `assemble(alloc, module)` → `FOR1`/`BEAM` with `AtU8 Code StrT ImpT ExpT FunT LitT Line`; `beam_lib` accepts it, `code:load_binary/3` loads it | `src/codegen/beam/beam_file.zig` | 83, 86 |
| the opcode table, **generated** from OTP 28.0's `genop.tab` (184 opcodes, `otp_release = 28`, `stable_floor = 24`); `Op.emittable()` = not obsolete and `since <= 24` — **118** of 184; regenerated only when the pin moves, cross-checked against the installed `beam_opcodes` | `src/codegen/beam/opcodes.zig`, `gen_opcodes.sh` | 86 |
| **cmd 4** — `<u16 BE namelen><module><beam bytes>` → `code:purge` + `code:load_binary/3`, reply the atom; `evalBeamWithArg` sends it; cmd 1/2 (`compile:file`) stay while generated modules are still `.erl` | `src/comptime/runtime/persistent_erl.zig`, `server_source.zig` | — |
| the three resident modules are `.beam` bytes **embedded** in the compiler: `zig build` runs `render_resident` on the host (writes `botopink_comptime_server.erl` from `server_source.source`, `bp_comptime_template.erl` and `bp_comptime_decorator.erl` from `prelude.modules`), runs `erlc +deterministic -o <out>`, hands the `.beam`s to compiler-core as anonymous imports; `persistent_erl.zig` `@embedFile`s them (`resident_beams`) and the spawn is `erl -noshell -eval <bootstrap>`, one cmd-4 frame per module over stdin. `prepareServer`, the `erlc` warm-up and the hashed `-pa` directory are gone; `.botopinkbuild/tmp/persistent_erl/` holds only `erl.stderr.log` | `server_source.zig`, `render_resident.zig`, root `build.zig` (`render-resident`, `erlc_run`) | 83 |
| the floor: the bootstrap refuses an `erl` below OTP 28 before any module is loaded (`__BP_ERL_BELOW_FLOOR__` naming both releases → `error.PersistentErlBelowFloor`); a `.beam` compiled by a newer `erlc` than the machine's `erl` is refused as `__BP_ERL_LOAD_ERROR__` + `badfile`; neither configurable | `persistent_erl.zig` (`bootstrap_eval`) | 86, 67 |
| measured after 1c (`comptime_bench.sh`, wiped `.botopinkbuild`): N=10 build 441 → 288 ms, N=200 1 666 → 1 491 ms, erika-linq 627 → 464 ms; in-node `compile:file` unchanged (generated modules are still `.erl` until 1b) | the landing commit | — |
| **step 5, the build half** (`front/18-comptime-runtimes` `ed32ae82`, not merged): `zig build compiler-web` builds compiler-core for `wasm32-wasi` into `zig-out/web/` — ReleaseSmall **2.64 MB / 813 KB gzip / 48 s**, Debug 15.8 MB / 16 s (the native Debug CLI: 80 MB) — beside `glue.js` (a WASI shim serving `fd_write`/`clock_*`/`random_get`/`environ_*`/`fd_fdstat_get` and refusing by name the other 22 imports `std.Io`'s vtable declares; `Botopink.Compiler`; the Worker protocol) and `index.html`. `comptime/runtime/runtime.zig` (`can_spawn`, `active: ?ComptimeRuntime`) folds `persistent_erl.zig` and the RUN LOG executors out on wasm — the Debug build's DWARF file table names neither, nor `utils/snap.zig` — and both evaluators refuse a decorator or a template there with a located diagnostic naming the missing runtime, until step 2. One source change outside the gates: `erlang.zig`'s prelude spin lock yields with `spinLoopHint` (`Thread.yield` is glibc's `sched_yield` on wasi). `zig build test-web` (`tests/smoke.js`: four targets, a rendered diagnostic, the refusal, the Worker protocol under an emulated scope, the page's resource list) + the same step in `test.yml` | `modules/compiler-web/**`, `comptime/runtime/runtime.zig`, `codegen.zig`, `codegen/erlang.zig`, root `build.zig`, `.github/workflows/test.yml` | 67 |
| `comptime_bench.sh --project` builds a **workspace member** (front 14's finding: it carried `path:` deps only, and erika-linq is `{ "erika": { "workspace": true } }` since erika became a workspace): the nearest ancestor `botopink.json` declaring `workspaces` is copied (no `.git`/`.botopinkbuild`/`out`) and the member built inside it; a member with no enclosing workspace is refused by name. erika-linq builds again (906 ms, one comptime module, `--repeat 1`) | `scripts/comptime_bench.sh`, `scripts/AGENTS.md` (`front/18-comptime-runtimes` `9515a2d4`) | — |
| **step 2, the binary emitter** (`80a19bf7`): `codegen/wat/wasm_binary_emitter.zig` renders the `wat_ast.Module` to the binary format (every name resolved to an index; an unknown name, operator or numeral refused); `emitWat` returns text and binary (`GenerateResult.wasm`); `executeWat` runs the **binary** under wasmtime, so all 321 wasm RUN LOGs are the binary emitter's answer — equal, none re-recorded; the browser page runs the wasm target's output | `codegen/wat/wasm_binary_emitter.zig`, `wat.zig` (`emitWat`'s return), `moduleOutput.zig`, `codegen/runtime.zig` (`executeWat`), `modules/compiler-web/**` | — |
| **step 2, the wat runtime** (`1b1b34de`): the generated Erlang text parsed (`wat/erl_parse.zig`), lowered with its prelude to one `wat_ast` module (`wat/lower.zig`), linked into the embedded term library (`wat/rt.zig` → `bp_wat_rt.wasm`, `wat/link.zig`) and run on wasm3 in-process (`persistent_wat.zig`, `modules/wasm3/` re-vendored); `runtime.zig` the dispatcher both evaluators call, with `parity`; reply JSON read in sorted key order (`reply_order.zig`, 33 `COMPTIME REPLY` sections re-recorded, key order only) | `comptime/runtime/**`, `template_eval.zig`/`decorator_eval.zig` (the call), `trace.zig` (the order), `codegen/tests/helpers.zig` (`generate` under parity), root `build.zig`, `modules/wasm3/**` | 84 |
| **step 3, decision 84** (`96948082`): `codegen.generateWith` selects `Config.comptime_runtime orelse of(target)` for its comptime pass — commonJS/wasm on wat, erlang/beam on beam, no target (the LSP) on beam; no flag | `codegen.zig`, `codegen/config.zig`, `comptime/runtime/runtime.zig` | 84 |

**CI consequence.** `erlc` (OTP 28+) is now a dependency of *building* the compiler: every workflow
that runs `zig build` — the release cross-builds included — installs OTP 28 (`erlef/setup-beam`,
`brew` on macOS) before it, as `test.yml` already did. A user's machine needs `erl` only.

## Mechanism

One evaluation, function by function (full trace with every line in
[`current-path.md`](./current-path.md)):

```
infer.zig ──► decorator_eval.evaluate (:72) / template_eval.evaluate (:97)
                │ buildModule (:228 / :504)
                │   erlang.emitComptimeModule (codegen/erlang.zig:954; em.untyped = true at :1043)
                │   crossModule.erlDeclAtom → bp@comptime__{dec,tpl}__<name>__<16 hex>   (the module key)
                │   argumentTerm → Term  ──► etf.encode (runtime/etf.zig:43)      (the call-site data)
                │ ensureModule (template_eval.zig:218) → .botopinkbuild/tmp/{decorator,template}/<atom>.erl
                ▼
persistent_erl.evalWithArg (:509)
   ensureSpawned (:242): prepareServer (:296) → erlc ×1 → spawn erl (:268)
   cmd 2 (once per atom per process): compile:file + code:load_binary  → the atom      (server :83, :98-109)
   cmd 3 (every call site):           <module>:main(binary_to_term(Arg))  → iodata     (server :86-91, :117)
   frames: <u32 BE len><cmd:u8><payload>  ⇄  <u32 BE len><payload | __BP_ERL_COMPILE_ERROR__: | __BP_ERL_RUNTIME_ERROR__:>
                ▼
Response { ok | compile_error | runtime_error } (:426)  ──► parseOutcome (template_eval.zig:701 / decorator_eval.zig:395)
   JSON {kind: code|value|custom|capture|fail|ok|error, …}  ──► Outcome
```

What the runtime **returns** is JSON text produced in the node by the resident `'__bp_reply'/1`
(`prelude.zig:73`) and OTP's `json:encode/1`; what it **receives** is ETF bytes decoded by
`binary_to_term/1`. Neither side of that protocol mentions Erlang source — only the middle does
(`compile:file`). That is the seam every step below keeps.

**Where the request and the code disagree, stated plainly:**

1. *"Turn `persistent_erl.zig` into `persistent_beam.zig`, emitting `.beam` instead of `.erl`."*
   `persistent_erl.zig` is 701 lines of which the `.erl`-specific part is **13** (`compile_then`,
   `:98-104`, and the `erlc` warm-up, `:319-338`). The rest — the child's lifecycle (`:242-284`),
   the frame protocol (`:351-422`), `safe_call`'s timeout and group-leader isolation (`:117-136`),
   the `loaded` set (`:502`), the transport-error contract every caller reads (`:403`) — is exactly
   what a `.beam` path still needs, because a `.beam` still runs on a BEAM VM. So "transform" means:
   **replace the emission and the load command, keep the transport**. The rename is real
   (`persistent_beam.zig`), the deletion of `persistent_erl.zig` is an acceptance line, and the
   diff is the 13 lines plus a new load command — not a rewrite.
2. *"Emit the `.beam` directly."* Two things are missing, and the assembler is the smaller one.
   `beam_asm.zig` lowers **typed** programs and has no comptime mode (E-7; front 14 measured the
   untyped mode at 1 500–2 500 LOC, C-20). A comptime body is untyped by construction
   (`'__bp_add'(8000, '__bp_len'(T, length))` dispatches at run time). Step 1 therefore has two
   halves — (a) the untyped lowering mode of `beam_asm.zig` (this is C-20 verbatim) and (b) the
   `.S` model → `.beam` container encoder — and (b) without (a) has nothing to assemble.
3. *"No `erl` on the comptime path" and the three resident modules.* The server and both
   preludes were Erlang source compiled by `erlc` once per hash (`:296-346`). **Closed by
   decision 83, landed**: the three are compiled by `erlc` at `zig build` and embedded as bytes
   (*Landed since*, above); `erlc` is a build-time dependency of the compiler and leaves every
   user's machine.
4. *"The same for wat."* `wat.zig` is untyped already (E-8) — good — but its value model is
   **static**: an `i32` is a number or a pointer by the emitter's knowledge, never by a tag. A
   comptime body needs run-time typed values (`'__bp_add'` is number-or-string at run time;
   `maps:get` in 159 of 183 modules). So `persistent_wat.zig` is not "run wat.zig's output": it runs
   the comptime module's **Erlang text**, parsed and lowered over a tagged heap — the same program
   the BEAM runs — as [`wat-runtime.md`](./wat-runtime.md) describes.
5. *"Doubling the snapshot count."* Of 1 346 codegen files, **28** can differ between runtimes; the
   other 1 318 pairs are byte-identical by construction (the RUN LOG is the *target's* runtime,
   `COMPTIME VALUES` is Zig). The tree was collapsed for that reason twice (2026-09-15,
   2026-09-18). **Decision 85: the tree is doubled as asked**; step 4 implements it and turns the
   redundancy into the parity test.

## Steps

### Step 0 — measure at HEAD — LANDED (the bench with step 1, the counts and the timing on 2026-09-25)

Re-derive every row of *Current state* in the front's worktree before touching code; the numbers in
this README are the 2026-09-20 baseline and drift.

**Acceptance:**
- [x] `scripts/comptime_bench.sh --n 0,10,200 --repeat 3 --project ../../repository/erika/examples/erika-linq`
      run — the baseline (`2788be9f`) and the post-1c columns are in the landing commit and in *Landed since*
- [x] the counts of E-6 (snapshots), E-8 (wat carriers), E-9 (body census) re-run by the commands
      given there; any drift written down — [`evidence.md`](./evidence.md) E-15 (1 346 → 1 382 codegen
      files, 22 carriers and 33 `COMPTIME REPLY` unchanged, 29 on-disk modules)
- [x] `zig build test` from a cold cache timed once (`time zig build test`), the number recorded —
      **2 m 42 s** with the runtime cache cold, E-15

### Step 1 — the `.beam` path: the load command, the container, the residents, the untyped lowering

Three parts; **1a and 1c are landed, 1b remains** (it is the 1 500–2 500 LOC the front's weight
sits in, and it waits on `.tasks/module-identity` — C-01 — for the module atom).

**1a — the load command that takes bytes — LANDED.** **cmd 4**: payload
`<u16 BE namelen><module><beam bytes>`, action `code:purge(Mod), {module, Mod} = code:load_binary(Mod, "", Beam)`,
reply the atom; `evalBeamWithArg` sends it, and the inline test assembles `main(X) -> X.` with
`beam_file` and runs it through the node. Remaining in 1a: `evalWithArg` switching to cmd 4 for a
generated module (needs 1b's bytes), after which `ensureModule`/`writeModule`
(`template_eval.zig:218-243`) are dead, `compile_then` and cmd 1/2 are deleted, and the file is
renamed `persistent_beam.zig`.

**1b — the untyped lowering mode of `beam_asm.zig` — REMAINING** (C-20's body). `codegenEmit` (`beam_asm.zig:911`)
gains a sibling `emitComptimeModule(alloc, module, program, ComptimeModule)` with the same
`ComptimeModule` config `erlang.zig:452` takes: `host_enums`, `host_records`, `exports`, `resident`
(the `-import` becomes `call_ext` into `bp_comptime_template`/`bp_comptime_decorator`),
`unsupported_method`. Untyped arithmetic lowers to `call_ext` of the resident `'__bp_add'/2`,
`'__bp_len'/2`, `'__bp_text'/1`, `'__bp_json'/1`; method calls to `'__bp_prim_<callee>'` shims as
`erlang.zig` does. The `.erl` path stays as the per-declaration fallback while this half is
incomplete; the fallback rate is the progress metric (front 14 step 3 acceptance, kept).

**1c — the container, the opcode table and the residents — LANDED.** `src/codegen/beam/beam_file.zig`
writes `FOR1`/`BEAM` with `AtU8`, `Code`, `StrT`, `ImpT`, `ExpT`, `FunT`, `LitT`, `Line` from its
own instruction model (`Module → Function → Instr → Arg`, one `Arg` variant per compact-term operand
kind of `beam_asm.erl`'s `encode_arg/2`); the adapter from `beam_emitter.zig`'s `Operand`/`Dest`/
`TestOp`/`GcBif`/`Callee` is 1b's, and is a mapping (`## Adapter` in the file header). Chunk by
chunk in [`beam-file-format.md`](./beam-file-format.md). The opcode table is decision 86 as taken:
one generated table pinned to **OTP 28** (`opcodes.zig`, 184 opcodes), the emitter restricted to
`Op.emittable()` — the **118** stable since OTP 24 and not obsolete — a `beam_lib` validation in the
test, and a refusal below the floor at spawn. The three resident modules are decision 83 as taken:
`.beam` bytes compiled by `erlc` at `zig build` and embedded (*Landed since*). What `erl` still
does: `code:load_binary/3` and `main/1` — the VM, not the compiler.

**Bench to beat** (front 14, post-step-2): erika-linq erl side **49.0 ms** (compile 47 + load 1);
target ≤ **3 ms** (load only, 12 declarations × ≈ 0.25 ms — a `.beam` of 800 B loads faster than
the 1.0 ms measured for source-compiled ones, to be measured); N=200 build 2 172 ms → the same
minus 3.8 ms compile; **ms per evaluation stays ≈ 9.4** because 16.1 ms of each `buildModule` is
the emitter re-parsing its preludes (front 14 § *Landed*) — not this front's, reported.

**Acceptance:**
- [ ] `persistent_erl.zig` **deleted**; `persistent_beam.zig` holds the transport unchanged
      (`readFrame`/`sendFrame`/`safe_call` tests green, byte-for-byte the same frames) — after 1b
- [x] `beam_lib:info/1` and `beam_lib:chunks/2` accept an assembled module; `code:load_binary/3`
      loads it through cmd 4 (`main(X) -> X.` fixture) — 1a/1c
- [ ] `main/1` answers the **33** `COMPTIME REPLY` sections byte-identically from assembled bytes — 1b
- [x] no `erlc` on any user's machine: the three residents are embedded, `prepareServer` is gone,
      `erl` below OTP 28 is refused with both releases named — 1c (decisions 83, 86)
- [ ] no `.erl` written under `.botopinkbuild/tmp/{template,decorator}/` for a lowered declaration;
      `botopink clean` unchanged
- [ ] `COMPTIME ERLANG` sections become `COMPTIME BEAM ASSEMBLY` (33 files), classified as a rename
- [ ] the fallback count recorded (N of 39 template + 33 decorator bodies still on `.erl`)
- [ ] `scripts/comptime_bench.sh` re-run; erika-linq erl side ≤ 3 ms once the fallback count is 0
- [ ] `scripts/beam_export_audit.sh` still 295/295
- [ ] **remaining, not this front's:** the per-emission prelude re-parse in `emitErlangModule`
      (`collectPrimErlangDispatch`, `loadAutoImportedBifsFromPrelude` — 16.1 ms of every `buildModule`,
      front 14 § *Landed*) keeps front 14 step 2's per-evaluation budget (≤ 1 ms/eval, N=200 ≤ 600 ms)
      unmet at 9.4 ms/eval whatever this front's lowering does; the memo belongs in the shared body of
      `02-erlang`'s `emitErlangModule`, outside this front's `ComptimeModule` carve-out

### Step 2 — `persistent_wat.zig`: comptime bodies on wasm3, in-process — LANDED (`80a19bf7` binary emitter, `1b1b34de` runtime)

Specified in [`wat-runtime.md`](./wat-runtime.md). Decision 84 makes this the runtime of every
build whose target is `commonJS`, `typescript` or `wasm`, and of the client half of a split project
— not a test-only artefact. The summary:

- **One program.** The wat runtime lowers **the Erlang text `emitComptimeModule` already produced** —
  the program the BEAM runtime compiles — not the botopink AST a second time, so the two runtimes
  can only disagree through a BIF implemented twice. `comptime/runtime/wat/erl_parse.zig` reads the
  text back (all 420 comptime modules on disk parse); `lower.zig` lowers it and the prelude it
  imports to one `wat_ast` module over tagged terms; `link.zig` splices that into the term library.
- **The term library** (`wat/rt.zig`) is Zig compiled at `zig build` for `wasm32-freestanding` (MVP)
  and embedded (`bp_wat_rt.wasm`): Erlang terms on linear memory, one arena per evaluation,
  exceptions as a pending class/reason tested after every call, the BIFs with the BEAM's error
  reasons, `json:encode` byte-compatible with OTP's.
- **Encodings.** ETF in (`etf.zig`'s bytes, decoded by `rt_etf_decode`); `json:encode` bytes out,
  read in canonical key order on both runtimes (`reply_order.zig`: the BEAM iterates atom keys in
  atom-table order, an accident of load order).
- **Executor.** wasm3 in-process (`persistent_wat.zig`, re-vendored `modules/wasm3/`); the linked
  module imports nothing, so a body's prints stay in its own memory. The browser build runs the same
  module on the page's engine behind `bp_host` imports (step 5). Binary wasm comes from
  `codegen/wat/wasm_binary_emitter.zig`.
- **Refusals.** A construct the lowering cannot take (`self/0`, `apply/3`, a BIF outside the table) is
  a compile error naming it — never a zero value. Refusal count over every fixture and the five
  libraries: 0. What `rt.zig` does not do yet (`~p`'s 80-column wrapping, Unicode case mapping, tail
  calls, bignums) is listed in `wat-runtime.md` § 7.

**Acceptance:**
- [x] `persistent_wat.zig` runs every one of the 33 `COMPTIME REPLY` fixtures and answers
      byte-identically to `persistent_beam.zig`; a fixture it refuses names the construct, and the
      refusal count is recorded — every codegen fixture's every evaluation runs on both runtimes
      (`helpers.generate` under `runtime.parity`): **0 disagreements, 0 refusals**; the five sibling
      libraries' commonJS cells, measured with an instrumented build: 242 evaluations of 56 modules,
      0 disagreements (`persistent_beam` is still `persistent_erl.zig` until step 1b). "Byte-identically"
      holds in **canonical key order** (`reply_order.zig`): a reply is `json:encode` of a map and the
      BEAM iterates atom keys in atom-table order — which modules the node loaded first — so both
      runtimes' replies are now read with sorted keys (the 33 `COMPTIME REPLY` sections re-recorded,
      key order only; a map lifted by `@expr` takes that order as its label order)
- [x] no process is spawned on the wat path (`strace -f -e execve botopink build` shows none) — one
      `execve`, botopink's own, for `--target commonJS` and `--target wasm` (`96948082`, step 3)
- [ ] `modules/wasm3/build.zig` builds on linux-gnu, macos, windows (the CI matrix) — linux-gnu green;
      the matrix runs after the push
- [x] the body's prints land in the captured buffer, never on the compiler's stdout — the linked module
      imports nothing; `io:format` writes a buffer in its own memory (`rt_printed`)

### Step 3 — the runtime selector, and no flag — LANDED `96948082` (decided: 84)

**Decision 84: the comptime runtime follows the target's VM, beam by default.** A build whose
target is `erlang` or `beam` evaluates comptime on the BEAM runtime; a build whose target is
`commonJS`, `typescript` or `wasm` evaluates it on the WAT runtime (wasm3); when no target decides,
the default is **beam**; in the client/server split of a project, server modules use beam and
client modules use wat. No flag, no build option — the runtime is a property of the target
(decision 67). One enum, one place:

```zig
// src/comptime/runtime/runtime.zig
pub const ComptimeRuntime = enum { beam, wat };
pub fn of(target: ?Target) ComptimeRuntime   // erlang | beam | null → .beam; commonJS | typescript | wasm → .wat
pub fn evalWithArg(alloc, io, runtime: ComptimeRuntime, module: Module, arg: []const u8) !Response  // dispatches
```

`decorator_eval.zig` and `template_eval.zig` call the dispatcher with `of(build.target)` (a
split project passes the module's half); `Module` carries `{ atom, beam: ?[]const u8, wasm: ?[]const u8, listing }`
and the evaluator asks for the one the runtime wants. On a wasm-hosted compiler (step 5) `.beam`
is unreachable by construction (`if (builtin.cpu.arch.isWasm())` folds it out), which agrees with
84: a browser compiles for the client targets. **No CLI flag** (`--comptime-runtime`); the parity
harness calls both runtimes directly on a native build and needs no option to do so.

**Invariant, as a test:** `src/comptime/runtime/parity.zig` runs every comptime fixture under both
runtimes on a native build and asserts `Response` equality byte-for-byte — the doubled snapshot
tree of step 4 is the recorded form of the same assertion.

**Acceptance:**
- [x] `grep -rn "comptime-runtime\|comptime_runtime" modules/compiler-cli/src build.zig` → 0 (no flag, no build option) —
      `Config.comptime_runtime` exists for the harness's doubled tree; null for every driver
- [x] `botopink build --target erlang` / `beam` of a project with one decorator spawns `erl`; `--target commonJS` / `wasm` spawns nothing (`strace -f -e execve`); a project with no target uses beam —
      14 `erl` execs for erlang/beam, one execve (botopink's) for commonJS/wasm with the expansion in `out/`.
      The CLI always has a target (a manifest without one is commonJS); the no-target compilation is
      the language server's type pass, which stays on beam
- [x] `parity.zig` green on linux; a deliberate divergence (a prelude helper edited in one runtime)
      fails it with both replies printed — and the codegen harness asserts parity on every fixture
- [x] `decorator_eval.zig`/`template_eval.zig` import neither `persistent_beam` nor `persistent_wat` —
      both call `runtime.evalWithArg` (the `.erl` staging and the transport reading moved there)

### Step 4 — the snapshot re-layout — REMAINING (decided: 85)

**Decision 85: the tree is doubled as asked** — `snapshots/codegen/{beam,wat}/{beam,commonJS,erlang,errors,wasm}/`,
the existing files moved into `beam/` by `git mv`, `wat/` recorded once and audited pair by pair,
the harness asserting pair equality. Specified in [`snapshot-layout.md`](./snapshot-layout.md). The rule: **directory =
`codegen/<comptime runtime>/<target>/<slug>`**, errors at `codegen/<runtime>/errors/<target>/<slug>`,
i.e. `snapshots/codegen/{beam,wat}/{beam,commonJS,erlang,errors,wasm}`. It is a change in
`codegen/snapshot.zig:205` and `:230` (a `{s}/` segment from `ComptimeRuntime`), plus the harness
loop in `codegen/tests/helpers.zig:198` running `configs × runtimes`, not a `mv`.

- migration: `git mv snapshots/codegen/{beam,commonJS,erlang,wasm,errors} snapshots/codegen/beam/` —
  1 346 files, byte-identical, proven by hash as the 2026-09-18 collapse was;
- first recording of `wat/`: `BOTOPINK_SNAP_CREATE=1` once, then every `wat/<t>/<slug>` compared to
  `beam/<t>/<slug>` by `scripts/snap_audit.sh --mode=runtime-parity`; a difference is a defect in
  one runtime and the audit exits 1 — never accepted;
- the harness runs the suite twice; the RUN LOG executors are content-cached
  (`runtime.zig:244`), so the second pass pays codegen, not `node`/`erl`/`wasmtime` — measured in
  step 0's timing, expected ≈ 1.5×, to be recorded;
- `comptime/ast/` (5 files with `COMPTIME ERLANG`) follows the same rule for the 5, not for the 197
  others (`snapshot-layout.md` § 6 — the AST is runtime-independent; 85's answer for `codegen/`
  applies to the 5 exchanges).

**Acceptance:**
- [ ] `ls snapshots/codegen/beam/* snapshots/codegen/wat/* | wc -l` = 2 × 1 346, every pair equal
      except the 28 with a comptime section, and those equal on their `COMPTIME REPLY`
- [ ] `scripts/snap_audit.sh` and `scripts/beam_export_audit.sh` read the new tree; `backendOf`
      recognises `codegen/<runtime>/<target>`
- [ ] `BOTOPINK_SNAP_TRACE` run: traced = on disk, 0 orphans, 0 unrecorded
- [ ] `codegen/tests/AGENTS.md:24` and `codegen/AGENTS.md` name the new path

### Step 5 — the browser build — LANDED in part: the build, the glue, the demo; its comptime half waits on step 2

Specified in [`browser-build.md`](./browser-build.md). `zig build compiler-web` builds
`src/root.zig`'s API (`codegen.generate` takes sources in and gives text out) for `wasm32-wasi` —
the target is fixed in root `build.zig`, `-Dtarget` is not read — into `zig-out/web/`.
`comptime/runtime/runtime.zig` decides at compile time what the host carries: `can_spawn`
(`!builtin.cpu.arch.isWasm()`) and `active: ?ComptimeRuntime`, `.beam` where a process can be
spawned and **null** on wasm, so `persistent_erl.zig` is never analysed there and both evaluators
refuse a decorator or template with a located diagnostic. When step 2's wat runtime exists, `active`
on wasm becomes `.wat` and its executor is a host import (`bp_host.run_module(ptr, len, arg_ptr,
arg_len) → reply`, not built yet) that `glue.js` serves with `WebAssembly.instantiate`. The compiler
needs from its host: source bytes (handed in, no fs walk), a clock (WASI `clock_time_get`),
stdout/stderr (`fd_write`), randomness (`random_get`), and **no** process spawn. The `RUN LOG`
executors (`codegen/runtime.zig`) are not built for wasm (`codegen.generateWith` refuses `execute`
there, `error.NoExecutorOnThisHost`).

Demo: `modules/compiler-web/` — `index.html` + `glue.js` + the built `botopink.wasm`; a `.bp` with a
decorator **and** a template is compiled to `commonJS` and to `wasm`, and the `wasm` output is
instantiated and run in the same page.

**Acceptance:**
- [ ] `zig build compiler-web` green on the CI matrix — linux green (the target is fixed in `build.zig`, `-Dtarget` is not
      read; the `test-web` step is in `test.yml`, the matrix run follows the push); recorded: ReleaseSmall
      **2.64 MB · 813 KB gzip · 48 s**, Debug 15.8 MB · 16 s, the native Debug CLI 80 MB (budget ≤ 8 MB / ≤ 2.5 MB gzip: held)
- [ ] the demo compiles the decorator+template program with **no network request after load**
      (DevTools network tab empty after `botopink.wasm` and `glue.js`); its `COMPTIME REPLY` equals
      the native one — the page references `glue.js` and `botopink.wasm` only (pinned by `tests/smoke.js`, not
      yet watched in a browser); the `COMPTIME REPLY` is the located refusal until step 2's `persistent_wat.zig`;
      the `wasm` output **is** instantiated and run in the page since `80a19bf7` (the binary beside the
      `.wat`, `glue.js` `run`, pinned by `tests/smoke.js`: `hello, web` from the binary)
- [x] `grep -rn "std.process\|std.fs\." src/` reaches only files excluded from the wasm build — non-test hits are
      `codegen/runtime.zig`, `comptime/runtime/persistent_erl.zig`, `utils/snap.zig`, `render_resident.zig` and
      `beam_file.zig`'s tests; the Debug wasm's DWARF file table names none of them, and `template_eval.zig`'s
      `ensureModule`/`writeModule` (`std.Io.Dir.cwd`) sit behind the `active == null` refusal

## Gate

- [ ] `zig build test` from a **cold** runtime cache green in this front's worktree, under both
      runtimes (the doubled tree), and `parity.zig` green
- [ ] `scripts/gate.sh --cold` green (test-bpmp, beam export audit, test-cli, test-libs,
      test-language)
- [ ] `scripts/comptime_bench.sh` re-run at every step; the table appended to `evidence.md`
- [ ] no `erl`, `erlc`, `escript`, `node`, `wasmtime` spawned on the comptime path of a native
      build under the wat runtime (`strace -f -e execve`), and none anywhere in the wasm build
- [x] every workflow that runs `zig build` installs OTP 28 first (`erlc` is a build-time dependency
      since 1c; `test.yml` had it, `release.yml` gains the same `erlef/setup-beam` / `brew` pair)
- [ ] `AGENTS.md` updated in the same commit for `src/comptime/`, `src/comptime/runtime/`,
      `src/codegen/`, `src/codegen/beam/`, `src/codegen/wat/`, `src/codegen/tests/`, `snapshots/`
      (if it has one), `modules/wasm3/`, root `AGENTS.md` (the layout), `scripts/`;
      `meta:architecture.md`'s "O que roda onde" table names both runtimes
- [ ] Commit on `front/18-comptime-runtimes`; no push, no merge — landing is the maintainer's step

## Blast radius

| What moves | Size | How to sequence |
|---|---:|---|
| every codegen snapshot path | 1 346 files → `beam/…`, + 1 346 recorded under `wat/…` | one commit, `git mv` proven by hash, before any content change |
| the snapshot edits `.tasks/wasm` (6 `codegen/wasm/*.snap.md`) and `.tasks/tooling` (1 LSP snapshot) held at measurement time, now in `feat` | 7 files | if any worktree survives, its snapshot edits are re-applied under `beam/` by path rewrite, then the layout commit |
| C-01 (`.tasks/identity`): owns `beam_asm.zig` and `erlang.zig` wholesale and re-records ≈ 318 cells | the same files as step 1b | step 1b waits for C-01 (the *Depends on* line); steps 2–5 do not |
| C-06 / C-07 (`beam_asm.zig` patterns, `wat.zig` `A...B`) | same emitters, run-time halves | additive mode only on this side; conflicts are textual, not semantic |
| scripts naming the tree: `scripts/snap_audit.sh:41,120,134-141,496`, `scripts/beam_export_audit.sh:9,48`, `scripts/AGENTS.md:232` | 3 files | in the layout commit |
| docs naming the tree: `codegen/tests/AGENTS.md:24,49`, `codegen/AGENTS.md:1272,1453,1858` | 2 files | in the layout commit |
| `scripts/comptime_bench.sh` | its E-2 harness compiles `.erl` files from `.botopinkbuild/tmp/` (`comptime_modules`) — after step 1 there are none | gains a `--runtime` column that times `code:load_binary` of `.beam` bytes and wasm3 instantiation |
| `modules/language-server/src/compiler.zig:48-52` | passes `eval_ctx` → the LSP spawns `erl` today too; inherits the dispatcher for free | none |
| CI | OTP 28 before every `zig build` (1c, landed — release cross-builds included); the wasm build job; `wasm3` compiles on the three runners | 1c done; the rest in step 2 |
| `.botopinkbuild/tmp/{template,decorator}/` | 183 stale `.erl` files on this machine (445 KB) | `botopink clean` already removes them |

## Notes

- **What is deliberately not done.** The erlang and beam *run-time* targets still need `erl`:
  `runtime.zig:508-718` runs the *user's program* for the RUN LOG, `cli/run.zig:138-147` and
  `cli/test_cmd.zig:164-165` run it for the user — that is the target's VM, out of scope, and
  the browser demo compiles to those targets without running them. `node` and `wasmtime` likewise
  stay for the commonJS/wasm targets' RUN LOG and `botopink run` on a native host. This front
  removes runtimes from the **comptime** path only.
- **C-20 is absorbed.** Its body is step 1b verbatim (untyped mode of `beam_asm.zig`, host records,
  `main/1`, fallback rate); step 1c goes past it (`.beam` instead of `.S` + `erlc +from_asm`), which
  front 14's option B costed as "≈ 0.4 ms per declaration" and declined for build time — the
  reason it is worth it now is not time, it is that `erlc` leaves the compile path and the
  assembler is the same code the wasm build needs to have no external tool. Its acceptance lines
  are kept above.
- **What of the 2026-06 "wasm3 unified runtime" is revived, and what is not.** Revived: wasm3
  embedded in-process as *a* comptime executor, the binary emitter, the host-import surface served
  from Zig. Not revived: "wasm3 replaces all runtimes" — BEAM stays (the maintainer's request names
  both, and the BEAM runtime is the reference semantics the wat runtime is checked against); the
  earlier design's hand-written inline WAT prelude (≈ 160 lines) is replaced by `wat_prelude.zig`'s
  built nodes; and the reasons it was deleted (`history.md` of front 14: AtomVM's stdlib/stdout/
  Windows blockers, the four-runtime snapshot explosion) are answered here by the parity test and
  by question 3, not ignored.
- **The 13 lines.** The honest size of "turn `persistent_erl` into `persistent_beam`" is a new load
  command and the deletion of `compile_then`; the front's weight is the two lowering modes (1b, 2)
  and the two encoders (1c, the binary emitter).

## Questions — answered

The four questions this front raised are decisions [83](../../decisions-taken.md#83-the-resident-comptime-modules-are-beam-bytes-embedded-at-build-time)
(Q1: the residents are `erlc`-compiled at `zig build` and embedded — option (c), landed),
[84](../../decisions-taken.md#84-the-comptime-runtime-follows-the-targets-vm--beam-by-default)
(Q2: the runtime follows the target's VM, beam by default — (c) with the default flipped to beam),
[85](../../decisions-taken.md#85-the-snapshot-tree-is-doubled-as-asked) (Q3: doubled as asked — (a))
and [86](../../decisions-taken.md#86-opcodes-pinned-to-otp-28-with-the-stable-subset) (Q4: one table
pinned to OTP 28, the subset stable since OTP 24, a `beam_lib` validator, a refusal below the floor —
(a)+(c), landed). The measurements and options are in the decisions' entries; nothing here is open.
