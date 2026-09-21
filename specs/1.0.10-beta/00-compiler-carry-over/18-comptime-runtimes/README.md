# Front 18 — comptime runtimes: BEAM direct, WAT, and the browser build

**Track:** compiler (carry-over item **C-26**; absorbs and extends **C-20**)
**Priority:** high — every `botopink build` of a project with one template or one decorator spawns
`erl` and `erlc` (`src/comptime/runtime/persistent_erl.zig:268`, `:319`); a browser has neither, so
the compiler cannot run where the language's own playground, docs and the `commonJS`/`wasm` targets'
users are. This front is what makes compiler-core hostable on wasm: the comptime path stops needing
a process it can spawn. It also closes C-20 (decision 24: *no Erlang source in the compile path*)
by going one step past it — no Erlang *compiler* in the compile path either.
**Depends on:** C-01 for **step 1 only** — the module atom a `.beam` carries in its `AtU8` table and
`{module, …}` header is the one `crossModule.erlDeclAtom` (`src/codegen/crossModule.zig:296`) mints,
and C-01 re-shapes that atom. Steps 0, 2, 3 (selector), 4 (layout) and 5 (browser) do **not**
depend on C-01: the wat runtime names no atom, the layout is a harness change, and the browser build
ships the wat runtime alone.
**Owns:** `src/comptime/runtime/**` (new `persistent_beam.zig`, `persistent_wat.zig`, the
dispatcher that replaces the two `Runtime = enum { erl }` at `decorator_eval.zig:35` /
`template_eval.zig:46`) · the comptime half of `src/codegen/beam_asm.zig` (the `.S` model →
`.beam` assembler, `src/codegen/beam/beam_file.zig`) and of `src/codegen/wat.zig` (the dynamic-term
lowering mode and the binary emitter `src/codegen/wat/wasm_binary_emitter.zig`) ·
`src/codegen/snapshot.zig` + `src/comptime/snapshot.zig` + `src/utils/snap.zig` (directory
selection) · `snapshots/codegen/**` (the re-layout, all 1 346 files) · root `build.zig` (the wasm
build of compiler-core) · `modules/wasm3/**` (re-vendored) · `scripts/comptime_bench.sh`
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

Measured at `feat`, 2026-09-20, before the `.tasks/*` merges of the same day; every command and raw
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
   preludes are Erlang source compiled by `erlc` once per hash (`:296-346`). A `.beam` path for
   generated modules leaves those three as the last `erlc` call. Closing that is question 1 below.
4. *"The same for wat."* `wat.zig` is untyped already (E-8) — good — but its value model is
   **static**: an `i32` is a number or a pointer by the emitter's knowledge, never by a tag. A
   comptime body needs run-time typed values (`'__bp_add'` is number-or-string at run time;
   `maps:get` in 159 of 183 modules). So `persistent_wat.zig` is not "run wat.zig's output": it is a
   **dynamic-term mode** of `wat.zig` over a tagged heap, specified in
   [`wat-runtime.md`](./wat-runtime.md).
5. *"Doubling the snapshot count."* Of 1 346 codegen files, **28** can differ between runtimes; the
   other 1 318 pairs are byte-identical by construction (the RUN LOG is the *target's* runtime,
   `COMPTIME VALUES` is Zig). The tree was collapsed for that reason twice (2026-09-15,
   2026-09-18). Step 4 implements the request as asked and turns the redundancy into the parity
   test; question 3 offers the alternative.

## Steps

### Step 0 — measure at HEAD

Re-derive every row of *Current state* in the front's worktree before touching code; the numbers in
this README are the 2026-09-20 baseline and drift.

**Acceptance:**
- [ ] `scripts/comptime_bench.sh --n 0,10,200 --repeat 3 --project ../../repository/erika/examples/erika-linq`
      run and its table pasted into [`evidence.md`](./evidence.md) § E-3 as the front's baseline
- [ ] the counts of E-6 (snapshots), E-8 (wat carriers), E-9 (body census) re-run by the commands
      given there; any drift written down
- [ ] `zig build test` from a cold cache timed once (`time zig build test`), the number recorded —
      the suite time this front doubles is not in any `AGENTS.md` today (E-12)

### Step 1 — `persistent_beam.zig`: the `.beam` assembler in Zig

Three parts, in this order, each landable alone.

**1a — the load command that takes bytes.** Add **cmd 4** to the server: payload
`<u16 BE namelen><module><beam bytes>`, action `code:purge(Mod), {module, Mod} = code:load_binary(Mod, "", Beam)`,
reply the atom. `evalWithArg` sends cmd 4 instead of cmd 2 when the caller hands it `.beam` bytes.
No file is written: `ensureModule`/`writeModule` (`template_eval.zig:218-243`) become dead for this
path. `compile_then` (`:98-104`) and cmd 1/2 are deleted once nothing calls them (the file's own
tests at `:573-613` drive cmd 1 — they move to a `.beam` fixture assembled by 1c).

**1b — the untyped lowering mode of `beam_asm.zig`** (C-20's body). `codegenEmit` (`beam_asm.zig:911`)
gains a sibling `emitComptimeModule(alloc, module, program, ComptimeModule)` with the same
`ComptimeModule` config `erlang.zig:452` takes: `host_enums`, `host_records`, `exports`, `resident`
(the `-import` becomes `call_ext` into `bp_comptime_template`/`bp_comptime_decorator`),
`unsupported_method`. Untyped arithmetic lowers to `call_ext` of the resident `'__bp_add'/2`,
`'__bp_len'/2`, `'__bp_text'/1`, `'__bp_json'/1`; method calls to `'__bp_prim_<callee>'` shims as
`erlang.zig` does. The `.erl` path stays as the per-declaration fallback while this half is
incomplete; the fallback rate is the progress metric (front 14 step 3 acceptance, kept).

**1c — the container.** `src/codegen/beam/beam_file.zig`: takes the instruction model
`beam_emitter.zig` already spells (`Operand`, `Dest`, `TestOp`, `GcBif`, `CallKind`, `Callee` —
`:27-160`) and writes `FOR1`/`BEAM` with `AtU8`, `Code`, `StrT`, `ImpT`, `ExpT`, `FunT`, `LitT`,
`Line`. Chunk by chunk in [`beam-file-format.md`](./beam-file-format.md), with the opcode table
pinned to one OTP release and validated by loading. What `erl` still does: `code:load_binary/3` and
`main/1` — the VM, not the compiler.

**Bench to beat** (front 14, post-step-2): erika-linq erl side **49.0 ms** (compile 47 + load 1);
target ≤ **3 ms** (load only, 12 declarations × ≈ 0.25 ms — a `.beam` of 800 B loads faster than
the 1.0 ms measured for source-compiled ones, to be measured); N=200 build 2 172 ms → the same
minus 3.8 ms compile; **ms per evaluation stays ≈ 9.4** because 16.1 ms of each `buildModule` is
the emitter re-parsing its preludes (front 14 § *Landed*) — not this front's, reported.

**Acceptance:**
- [ ] `persistent_erl.zig` **deleted**; `persistent_beam.zig` holds the transport unchanged
      (`readFrame`/`sendFrame`/`safe_call` tests green, byte-for-byte the same frames)
- [ ] `beam_lib:info/1` and `beam_lib:chunks/2` accept every assembled module; `code:load_binary/3`
      loads it; `main/1` answers the **33** `COMPTIME REPLY` sections byte-identically
- [ ] no `.erl` written under `.botopinkbuild/tmp/{template,decorator}/` for a lowered declaration;
      `botopink clean` unchanged
- [ ] `COMPTIME ERLANG` sections become `COMPTIME BEAM ASSEMBLY` (33 files), classified as a rename
- [ ] the fallback count recorded (N of 39 template + 33 decorator bodies still on `.erl`)
- [ ] `scripts/comptime_bench.sh` re-run; erika-linq erl side ≤ 3 ms once the fallback count is 0
- [ ] `scripts/beam_export_audit.sh` still 295/295

### Step 2 — `persistent_wat.zig`: comptime bodies on wasm3, in-process

Specified in [`wat-runtime.md`](./wat-runtime.md). The summary:

- **Lowering.** `wat.zig` gains a *dynamic-term mode* (`ComptimeModule` config, `em.dynamic = true`)
  in which every value is a pointer to a tagged term on the linear-memory heap — the same eight
  variants `beam/term.zig` and `etf.zig` have (`atom binary integer float boolean nil list tuple
  map`). `'__bp_add'`, `'__bp_len'`, `maps:get`, `lists:*`, `string:*` become prelude helpers over
  that heap; a comptime body's text-mode listing (`COMPTIME WAT`) is the `.wat` of that module.
- **Encoding in: ETF, unchanged.** The argument bytes `etf.encode` already produces are copied into
  the module's memory and decoded by a prelude `$__etf_decode` into tagged terms. One encoder
  (`etf.zig`, pinned to OTP's byte vectors) serves both runtimes; a JSON/CBOR argument would be a
  second encoder that loses the atom/binary/tuple distinction the bodies rely on
  (`maps:get(name, Decl)` keys are atoms).
- **Encoding out: JSON text, identical to `'__bp_reply'/1`'s.** A prelude `$__bp_reply` +
  `$__json_encode` write the same bytes OTP's `json:encode` writes for the same term, so
  `parseOutcome` (`template_eval.zig:701`, `decorator_eval.zig:395`) is shared verbatim and neither
  evaluator knows which runtime ran.
- **Executor.** wasm3 embedded from a re-vendored `modules/wasm3/` (`build.zig` exporting `link`,
  `exposeHeaders`, `wasm3_srcs`, `wasm3_cflags` as it did before its deletion); host import
  `fd_write` served from Zig into a captured buffer (the body's prints go where `erl.stderr.log`
  went), plus `bp_host.now`/`bp_host.random` only if a body needs them (today: none — E-9 shows
  no `erlang:now`/`rand` use). wasm3 takes **binary** wasm: `src/codegen/wat/wasm_binary_emitter.zig`
  renders the same `wat_ast` model to the binary format (text stays for snapshots; no text re-parse).
- **Gap closure.** The 22 carriers of E-8 are static-mode gaps; in dynamic mode each construct is
  either lowered to a helper call or **refused with the located diagnostic** `unsupported_method`
  already produces for the erlang path (`erlang.zig:481`) — never a zero placeholder. Table in
  `wat-runtime.md` § 4.

**Acceptance:**
- [ ] `persistent_wat.zig` runs every one of the 33 `COMPTIME REPLY` fixtures and answers
      byte-identically to `persistent_beam.zig`; a fixture it refuses names the construct, and the
      refusal count is recorded
- [ ] no process is spawned on the wat path (`strace -f -e execve botopink build` shows none)
- [ ] `modules/wasm3/build.zig` builds on linux-gnu, macos, windows (the CI matrix)
- [ ] the body's prints land in the captured buffer, never on the compiler's stdout

### Step 3 — the runtime selector, and no flag

One enum, one place:

```zig
// src/comptime/runtime/runtime.zig
pub const ComptimeRuntime = enum { beam, wat };
pub const active: ComptimeRuntime = if (builtin.cpu.arch.isWasm()) .wat else build_options.comptime_runtime;
pub fn evalWithArg(alloc, io, module: Module, arg: []const u8) !Response  // dispatches
```

`decorator_eval.zig` and `template_eval.zig` call the dispatcher; `Module` carries
`{ atom, beam: ?[]const u8, wasm: ?[]const u8, listing }` and the evaluator asks for the one the
active runtime wants. **No CLI flag** (`--comptime-runtime`): decision 67 forbids a knob that
changes which checker runs a body, and the runtime is a property of the **host** — a browser can
only run wat, a native binary can run both — and of the **build**, not of the user's invocation.
The build option exists only so the test harness can build both and so the maintainer can flip the
native default once (question 2); it is not read at run time.

**Invariant, as a test:** `src/comptime/runtime/parity.zig` runs every comptime fixture under both
runtimes on a native build and asserts `Response` equality byte-for-byte — the doubled snapshot
tree of step 4 is the recorded form of the same assertion.

**Acceptance:**
- [ ] `grep -rn "comptime-runtime\|comptime_runtime" modules/compiler-cli/src` → 0 (no flag)
- [ ] `parity.zig` green on linux; a deliberate divergence (a prelude helper edited in one runtime)
      fails it with both replies printed
- [ ] `decorator_eval.zig`/`template_eval.zig` import neither `persistent_beam` nor `persistent_wat`

### Step 4 — the snapshot re-layout

Specified in [`snapshot-layout.md`](./snapshot-layout.md). The rule: **directory =
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
  others: question 3.

**Acceptance:**
- [ ] `ls snapshots/codegen/beam/* snapshots/codegen/wat/* | wc -l` = 2 × 1 346, every pair equal
      except the 28 with a comptime section, and those equal on their `COMPTIME REPLY`
- [ ] `scripts/snap_audit.sh` and `scripts/beam_export_audit.sh` read the new tree; `backendOf`
      recognises `codegen/<runtime>/<target>`
- [ ] `BOTOPINK_SNAP_TRACE` run: traced = on disk, 0 orphans, 0 unrecorded
- [ ] `codegen/tests/AGENTS.md:24` and `codegen/AGENTS.md` name the new path

### Step 5 — the browser build

Specified in [`browser-build.md`](./browser-build.md). `zig build -Dtarget=wasm32-wasi
compiler-web` builds `src/root.zig`'s API (`codegen.generate` takes sources in and gives text out —
`codegen.zig:44`) with `persistent_beam` compiled out (`if (runtime.active == .beam)` is comptime-false
on wasm) and the wat runtime's executor replaced by a host import `bp_host.run_module(ptr, len,
arg_ptr, arg_len) → reply` that the JS glue serves with `WebAssembly.instantiate`. The compiler
needs from its host: source bytes (handed in, no fs walk), a clock (WASI `clock_time_get`),
stdout/stderr (`fd_write`), randomness (`random_get`, for the scratch nonces — or none, since
nothing is written), and **no** process spawn. The `RUN LOG` executors (`runtime.zig`) are not
built for wasm (`execute = false`, `codegen.zig:93`).

Demo: `modules/compiler-web/` — `index.html` + `glue.js` + the built `botopink.wasm`; a `.bp` with a
decorator **and** a template is compiled to `commonJS` and to `wasm`, and the `wasm` output is
instantiated and run in the same page.

**Acceptance:**
- [ ] `zig build -Dtarget=wasm32-wasi compiler-web` green on the CI matrix; the artefact size and
      the build time recorded (budget: ≤ 8 MB uncompressed, to be measured against the native CLI)
- [ ] the demo compiles the decorator+template program with **no network request after load**
      (DevTools network tab empty after `botopink.wasm` and `glue.js`); its `COMPTIME REPLY` equals
      the native one
- [ ] `grep -rn "std.process\|std.fs\." src/` reaches only files excluded from the wasm build

## Gate

- [ ] `zig build test` from a **cold** runtime cache green in this front's worktree, under both
      runtimes (the doubled tree), and `parity.zig` green
- [ ] `scripts/gate.sh --cold` green (test-bpmp, beam export audit, test-cli, test-libs,
      test-language)
- [ ] `scripts/comptime_bench.sh` re-run at every step; the table appended to `evidence.md`
- [ ] no `erl`, `erlc`, `escript`, `node`, `wasmtime` spawned on the comptime path of a native
      build under the wat runtime (`strace -f -e execve`), and none anywhere in the wasm build
- [ ] `AGENTS.md` updated in the same commit for `src/comptime/`, `src/comptime/runtime/`,
      `src/codegen/`, `src/codegen/beam/`, `src/codegen/wat/`, `src/codegen/tests/`, `snapshots/`
      (if it has one), `modules/wasm3/`, root `AGENTS.md` (the layout), `scripts/`;
      `meta:architecture.md`'s "O que roda onde" table names both runtimes
- [ ] Commit on `fix/comptime-runtimes-<step>`; no push, no merge — landing is the maintainer's step

## Blast radius

| What moves | Size | How to sequence |
|---|---:|---|
| every codegen snapshot path | 1 346 files → `beam/…`, + 1 346 recorded under `wat/…` | one commit, `git mv` proven by hash, before any content change |
| `.tasks/wasm` (6 modified `codegen/wasm/*.snap.md`) and `.tasks/tooling` (1 LSP snapshot) at measurement time; being merged into `feat` on 2026-09-20 | 7 files | land the merges first (in progress); if any worktree survives, its snapshot edits are re-applied under `beam/` by path rewrite, then the layout commit |
| C-01 (`.tasks/identity`): owns `beam_asm.zig` and `erlang.zig` wholesale and re-records ≈ 318 cells | the same files as step 1b | step 1b waits for C-01 (the *Depends on* line); steps 2–5 do not |
| C-06 / C-07 (`beam_asm.zig` patterns, `wat.zig` `A...B`) | same emitters, run-time halves | additive mode only on this side; conflicts are textual, not semantic |
| scripts naming the tree: `scripts/snap_audit.sh:41,120,134-141,496`, `scripts/beam_export_audit.sh:9,48`, `scripts/AGENTS.md:232` | 3 files | in the layout commit |
| docs naming the tree: `codegen/tests/AGENTS.md:24,49`, `codegen/AGENTS.md:1272,1453,1858` | 2 files | in the layout commit |
| `scripts/comptime_bench.sh` | its E-2 harness compiles `.erl` files from `.botopinkbuild/tmp/` (`comptime_modules`) — after step 1 there are none | gains a `--runtime` column that times `code:load_binary` of `.beam` bytes and wasm3 instantiation |
| `modules/language-server/src/compiler.zig:48-52` | passes `eval_ctx` → the LSP spawns `erl` today too; inherits the dispatcher for free | none |
| CI | the wasm build job; `wasm3` compiles on the three runners | added in step 2 |
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

## Questions for decisions-pending.md

### Q1. Do the three resident modules (server, two preludes) also stop being Erlang source?

**Measured.** After step 1 the only `erlc` call left is `prepareServer` (`persistent_erl.zig:319`)
compiling `botopink_comptime_server.erl` (4 583 B, hand-written: `receive`, `spawn_monitor`,
binary matching, `logger`), `bp_comptime_template.erl` (2 465 B) and `bp_comptime_decorator.erl`
(1 373 B), both rendered from `erl_ast` forms (`prelude.zig:73`, `:173`). Once per hash, cached;
≈ 145 ms once per compiler process including the `erl` spawn.
**Options.** (a) Keep `erlc` for the three, once per hash — `erlc` stays a compile-time dependency.
(b) Assemble the two preludes with step 1's untyped BEAM mode (they are `erl_ast` forms, so the
same lowering) and hand-write the server in the `.S` model (`beam_emitter.zig` already spells
`receive`-free code; the server needs `receive`/`spawn_monitor`/`try` instructions the model lacks:
≈ 120 lines of model) — no `erlc` anywhere. (c) Ship the three `.beam`s as bytes embedded in the
compiler binary, produced by `erlc` at `zig build` time — `erlc` becomes a *build*-time dependency
of the compiler, gone from every user's machine; the bytes are OTP-release-specific
(`beam_asm` output loads on the release that made it and later ones).
**Recommendation.** (b) for the preludes (same code as 1b, no new dependency), (c) for the server
until the `.S` model has `receive` — then (b) for it too. (a) is the status quo and contradicts
decision 24's principle at the last 3 files.
**Blocks.** Step 1c's "no `erlc` on the path" acceptance.

### Q2. Which runtime does a native build use by default once parity is proven?

**Measured.** The wat runtime spawns nothing and needs no toolchain; the beam runtime needs `erl`
(≈ 145 ms once per process) and is the reference semantics. Today every commonJS/wasm build of a
project with a decorator needs `erl` for nothing but that decorator.
**Options.** (a) `beam` native, `wat` in the browser — the request's literal shape; `erl` stays
required for every native build. (b) `wat` everywhere; `beam` kept for the parity test and the
`--target erlang/beam` builds only (their target VM is present anyway). (c) `wat` by default, `beam`
when the target is erlang/beam — the runtime follows the target's VM, still no flag.
**Recommendation.** (c): a JavaScript build no longer depends on Erlang; an Erlang build already
has the VM and keeps the reference runtime; the choice is a property of the build target, which is
what decision 67 allows (structural, not a knob). (a) leaves the dependency the front exists to
remove; (b) makes the reference runtime a test-only artefact.
**Blocks.** Step 3's `active` expression and the CLI's `PATH` hint text.

### Q3. Double the whole tree, or only the snapshots that can differ?

**Measured.** 1 346 codegen files; **28** carry a `COMPTIME ERLANG`/`COMPTIME REPLY` section; the
other 1 318 are runtime-independent (RUN LOG = target VM, `COMPTIME VALUES` = Zig fold). The tree
was flattened on 2026-09-15 and the four byte-identical comptime copies collapsed on 2026-09-18 for
exactly this redundancy ("four files per review row for every renderer fix").
**Options.** (a) The request as written: `codegen/{beam,wat}/{5 dirs}`, 2 692 files, 1 318
byte-identical pairs, the harness asserting pair equality (the parity test recorded on disk). (b)
`codegen/<target>/<slug>` unchanged; the per-runtime sections live in
`codegen/comptime/{beam,wat}/<slug>` (28 + 28 files), the rest written once. (c) (a) for the 28 and
(b)'s single copy for the rest, under the requested directory names (`wat/<t>/` holds only the 7
that can differ) — the tree the maintainer named, without the 1 318 copies.
**Recommendation.** (a), because it is what was asked and its cost is mechanical (one `git mv`,
pair-equality checked by the audit, a renderer fix re-records two files); if the two-files-per-row
cost is what 2026-09-18's collapse was about, (c) keeps the names and drops the copies.
**Blocks.** Step 4's layout commit.

### Q4. Which OTP release pins the opcode table?

**Measured.** This machine OTP 29; CI OTP 28 (`test.yml:76`); the `.beam` chunk set has been stable
since OTP 20 but `Code` opcodes are per-release (`beam_opcodes.erl` regenerated every release,
front 14 option B). A module assembled with only opcodes ≤ the oldest supported release loads on
every later one.
**Options.** (a) Pin to OTP 28's table (CI's floor), refuse to run on older with a diagnostic. (b)
Pin to the release found at run time (`erlang:system_info(otp_release)` via cmd 0), one table per
release shipped. (c) Emit only the opcode subset stable since OTP 24 (`beam_asm.zig` already
restricts itself: `:6286` notes `make_fun3` for current `+from_asm`).
**Recommendation.** (a) with (c)'s subset — one table, one validator run (`beam_lib`) in the
test, a clear refusal below the floor; (b) is a knob in disguise.
**Blocks.** Step 1c.
