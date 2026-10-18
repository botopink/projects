# Front 144 — machine 2: backends, runtimes, std, tooling and the gate (lanes B and C, the cache group)

The steps of [front 144](../README.md) this machine runs: its goal, priority, ownership, order, lanes, the rules the two
machines share and the alias table are the front's README; each step below is as it was there, unchanged. The
other machine's steps are in [`../machine-1/144-checker/`](../../machine-1/144-checker/README.md). A step keeps its id (`B-NN`) wherever it sits.

**Order on this machine (the maintainer, 2026-10-14):** the B-00 group (done but its last box); new development is centred on
**front 164 wasm-gc** (`164-wasm-gc/`), which this machine runs and which owns the wasm target, the comptime runtime and std-wasm from here
on — a step of this machine that reaches them waits on 164 s2; then the rest in the order written. B-30 is closed
as superseded by 164.

## The pipeline state read by the Conformance steps (474, 477, 478)

botopink-lang's `feat` pipeline ran to the end once decision 528 gave each pushed commit its own run (before it, every run
was cancelled by the next push). Its runs since the groups' bases were red on: the `refused` fixture of `cli_contract.sh`
(after `import-of-failed-module`), `external_wasm_wasi_unknown` (518's `.Attempt` adapter), `test/std_process_import`'s
stale narrowing (518's STD-001 at the call), `scripts/tsc-check.sh` (`Bytes`, `Context`, `Children` in the `.d.ts`), and
`format-check.sh` before 524. Each was fixed at once; the cheap tests: `cli_contract.sh` and the cells are the hook's own
stages, skipped only under the B-60 exception's `--no-verify`; the `.d.ts` one gained `codegen/tests/dts_compiler_types.zig`.
The first run green end to end — `scripts/gate.sh` with conformance, every cell on every target it declares — is the
commit that fixed `tsc-check`; it holds every group below whose boxes 3 and 4 are ticked.

## Steps
### B-00a — First — `modules/std-wasm`: std's host functions in Zig, compiled to wasm (decision 434)

**First thing the milestone does** (434), with B-00b–B-00e. A new module `repository/botopink-lang/modules/std-wasm/`
implements std's host functions directly in Zig, compiled to wasm and served to the comptime runtime — what
341's host cells call at build — so a std function reached at comptime needs no per-binding `@External.Wasm`
cell. Measure first which ones comptime reaches today.

- [x] measured: every std function a comptime evaluation reaches today (the decorator, template and `comptime`
      cells of `tests/language`, `comptime/tests/**`, every library repository's build — `hash.contentHash`,
      `unicode`, `string`, `json` …), each with its host cell per runtime; the list in `modules/std-wasm/AGENTS.md`
- [x] `modules/std-wasm/` scaffolded: a `build.zig` step compiling it to the `.wasm` the comptime runtime links,
      root `AGENTS.md` and `build.zig` naming it, a Zig unit test per function
- [x] each listed function implemented and served to the wat comptime runtime; one answer for every target:
      a comptime result is std-wasm's answer, whatever `--target` says (434 (3))

**Impacted tests:** `modules/std-wasm` unit tests (new); `comptime/tests/**`; `runtime/wat/**` tests.
**Model:** opus for the shape; sonnet per function once it lands. **Consumer commits:** none.

### B-00b — `modules/beam-to-wasm`: `.beam` bytecode translated to wasm (decision 434)

A new module `repository/botopink-lang/modules/beam-to-wasm/`: a standalone utility, `.beam` in, wasm out (decision
438, amending 435). It takes any `.beam` — erlc's output of a botopink cell or sidecar, or a module any BEAM compiler
produced (Erlang, Elixir, Gleam …) — and translates it to wasm, whole module by module, following the calls between
the modules it is given. Its one dependency is std-wasm, which serves the BIFs and OTP functions; an OTP function
std-wasm lacks, or an opcode it does not convert, is a located refusal. It knows nothing of botopink the language: no
AST, manifest, `bpmp` or diagnostic type — botopink's comptime is one caller, handing it the `.beam` of the cells it
reaches and reporting its refusal at the call site.

- [x] measured: every `@External.Erlang` / `@External.Beam` cell and `.erl` sidecar a comptime evaluation
      reaches today (std, rakun, jhonstart, erika, styled, emilia …), with the opcodes and OTP calls each uses —
      the list in `modules/beam-to-wasm/AGENTS.md`
- [x] `modules/beam-to-wasm/` scaffolded: the `.beam` chunk reader, the measured opcode subset lowered to wasm,
      the BIFs bound to std-wasm; a Zig unit test per opcode family
- [x] a call or opcode it does not convert refused at the call site, naming the function, the module and what is
      missing — `reject/comptime_beam_call_not_converted`
- [x] each measured cell answers at comptime through the translation, `COMPTIME REPLY` byte-identical to the
      BEAM runtime's answer on the parent
- [x] whole modules (438): the `.beam` files it is given translated module by module, a call from one to another
      followed; each OTP function they reach served by std-wasm or refused located — the utility's half; botopink's
      comptime does not call it (452)
- [x] a `.beam` botopink did not generate (an Erlang module compiled by `erlc` outside botopink, as a fixture)
      translated and run: the utility reads bytecode, never the source language
- [x] standalone: `modules/beam-to-wasm` imports Zig's `std` and std-wasm only — no `compiler-core`, `manifest` or
      `bpmp` — checked in `build.zig`'s module graph

**Impacted tests:** `modules/beam-to-wasm` unit tests (new); `comptime/tests/decorator_eval*`, the host-cell
tests comptime-14 adds. **Model:** opus. **Consumer commits:** none (a sidecar that needs an opcode outside the
subset is a row here, never a library workaround).

### B-00c — The comptime driver on wasm for every target (decision 434; amends 84, 341)

Every target's comptime evaluation runs on the wasm runtime (wasmtime in-process, `persistent_wat.zig`,
`runtime/wat/**`). A host function reached at build resolves, in order: the std-wasm implementation, else the
beam-to-wasm translation of its `@External.Erlang` cell, else its `@External.Wasm` cell; none → refused at the
call. An Erlang cell beam-to-wasm does not convert is refused at the call, its `fn:` cell not tried (decision 439). The erlang and beam targets are unchanged — only the comptime runtime moves; `erl`
/ `erlc` stay needed for those targets' own tests, never for compiling. comptime-14 built 341's host cells on the BEAM runtime
(a decorator's Erlang cell): that code is transitional, deleted in B-00d; 434 amends 341 to this order.

- [x] `comptime/runtime` selects the wat runtime for every `--target`; a compile spawns no `erl` (a build with
      no `erl` on `PATH` compiles a decorator-, template- and `comptime`-bearing project on all four targets)
- [x] the resolution order in force (452, amending 434 (4)): a host function reached at build answers by its `std:`
      cell, else its `fn:` cell, else is refused at the call naming both — `reject/comptime_host_cell_unavailable`
- [x] an Erlang cell never runs at build (452; 439 no longer applies — no Erlang cell is translated):
      `reject/comptime_expression_erlang_cell_never_runs`; the fall-through B-00c built removed
- [x] every decorator, template and `comptime` cell of `tests/language` green on the four targets with one
      `COMPTIME REPLY`; every library repository's hook green on this compiler

**Impacted tests:** `comptime/tests/**`; the codegen runtime listings; `tests/language` decorator / template /
`comptime` cells on four targets; every library's hook. **Model:** opus. **Consumer commits:** none expected; a
library cell that changes answer is a row here.

### B-00d — The BEAM comptime runtime deleted; one codegen snapshot tree (decision 434)

`persistent_beam.zig`, `runtime/beam/**`, the persistent `erl` spawn, `render_resident`'s erl step and
`runtime.parity`'s BEAM half go — never a persistent Erlang process of any kind. The BEAM host cells
comptime-14 built for 341 are transitional and are deleted here. The codegen snapshots lose the comptime-runtime
level: `snapshots/codegen/{beam,wat}/<target>/` becomes `snapshots/codegen/<target>/`, every target's snapshots
kept. 18's audit of the doubled tree pair by pair (its § Mechanism) and 14 step 2's BEAM budget are moot.

- [x] the BEAM comptime runtime and its tests deleted; `zig build test` green with no `erl` started by a compile
- [x] `modules/compiler-core/snapshots/codegen/{beam,wat}/<target>/` moved to `snapshots/codegen/<target>/`
      (`git mv`, byte-identical); `src/codegen/snapshot.zig` and `src/utils/snap.zig` select the one directory;
      every `AGENTS.md` naming the two trees and `07-residuals`' rename note rewritten; the erlang and beam
      targets' snapshots and tests unchanged
- [x] `scripts/snap_audit.sh --mode=runtime-parity` and every "under both runtimes" gate clause retired; root
      `AGENTS.md` ("`erl`/`erlc` must be on `PATH`" — for the erlang/beam targets' tests only), `compiler-core`,
      `comptime`, `codegen` `AGENTS.md`, `docs.md` and the meta `architecture.md` say comptime runs on wasm only
- [x] the wat runtime's limits (`limit 1`…`4`, the core-module subset, `i64` overflow) stated as the only
      runtime's limits in `runtime/wat/AGENTS.md`

**Impacted tests:** the whole `snapshots/codegen/**` tree (moved, not re-recorded); `comptime/tests/**`; the
runtime-parity audit (deleted). **Model:** sonnet — every cell green before and after is the oracle.
**Consumer commits:** none.

#### Step 3 — the bench table, and the evaluation's cost (was `18-comptime-runtimes` s3)

`scripts/comptime_bench.sh` re-run (14 step 2), table recorded here at milestone open and close, on
the runner's machine, load noted. Runtime evaluation = largest remaining per-evaluation stage (wat:
the engine's instance, parse and load of the linked module, `persistent_wat.zig`; BEAM: frame round
trip — 45 % / 29 % of an N=200 build before decision 237).

| Row | Date | Machine, load (1 min, before → after) | Target (runtime) | N=0 build | N=10 | N=200 | ms/eval 10→200 |
|---|---|---|---|---|---|---|---|
| open | 2026-10-09 | dev box, 16 threads, Debug `zig-out/bin/botopink`, load 56.7 → 77.6 | commonJS (wat) | 582 ms | 574 ms | 1045 ms | 2.5 |
| open | 2026-10-09 | same run | erlang (BEAM) | 1007 ms | 1509 ms | 1907 ms | 2.1 |
| before (14 s2) | 2026-10-09 | dev box, 16 threads, Debug, load 5.6 → 5.3 | commonJS (wat) | 304 ms | 356 ms | 570 ms | 1.1 |
| before (14 s2) | 2026-10-09 | same run | erlang (BEAM) | 514 ms | 652 ms | 771 ms | 0.6 |
| before (14 s2) | 2026-10-09 | same machine, load ≈ 6 | beam (BEAM) | 397 ms | 580 ms | 690 ms | 0.6 |
| after (14 s2) | 2026-10-09 | dev box, 16 threads, Debug, load 8.9 → 8.2 | commonJS (wat) | 304 ms | 344 ms | 443 ms | 0.5 |
| after (14 s2) | 2026-10-09 | same run | beam (BEAM) | 442 ms | 583 ms | 712 ms | 0.7 |
| after (14 s2) | 2026-10-09 | same run | erlang (BEAM) | 533 ms | 675 ms | 782 ms | 0.6 |

Stage split of the N=200 build (E-2, ms per evaluation), before → after: wat `instance` (a fresh
engine instance, runtime, parse, load) 0.336 → 0.035 (the kept instance's reset), `run` (bp_init
through the reply, the engine's compile included) 0.374 → 0.111, `module` 0.218 → 0.165 (no
Erlang listing per call), `memo_key` 0.034 → 0.002, total 1.02 → 0.39; BEAM `frame` ≈ 0.1 per
evaluation after the first (the first carries the node's spawn, 112 ms idle), total 0.92 with the
spawn.

`scripts/comptime_bench.sh --no-build --target <t> --n 0,10,200 --repeat 3`, min of three builds.
The load (other worktrees' gates) makes the slope an upper bound; re-measure on an idle runner.
E-2 is the in-compiler stage split (`runtime/stages.zig`), one more build of the largest N.

- [ ] a table with the open's row (above); the close's row added by the last front to land


**Gate:** standard (fronts.md § Gate) + `zig build compiler-web` and `test-web` green within budget
(the "under both runtimes" clause and the runtime-parity audit retired with the BEAM comptime
runtime, 434)

### B-00e — std-wasm in the user's `--target wasm` output (decision 434 (2))

std-wasm is linked into the wasm target's output too, replacing the `wat_prelude` helpers and the `wasi:`
bindings it implements — after the comptime switch (B-00c). The std-on-wasm steps it absorbs move here.

- [x] the wasm target transpiles std-wasm into the program (440 (2)): its functions decoded from `std_wasm.wasm`
      into `wat_ast`, one module; each `wat_prelude` helper and `wasi:` binding it implements leaves the prelude and
      the binding list; a wasm program prints std-wasm's text (441) — each `run/` cell whose wasm `.out`
      changes (float interpolation, `toString`, exponent forms, `trim`) re-read one by one, the other targets' unchanged
- [x] the `std:` binding (440 (3)): `#[@External.Wasm("std:<module>.<function>")]` on each std function std-wasm
      implements, serving the wasm codegen and the comptime; `stdWasmSymbol`'s implicit name match removed; a `std:`
      naming no export, or with other types, refused at the annotation; the `fn:` bodies it replaces deleted
- [x] the size an emitted module gains or loses measured (a hello world, onze's blog page, std's test module)
      and recorded in `wat/AGENTS.md`

**Impacted tests:** every wasm `RUN LOG` snapshot (re-read, not bulk-accepted); `run/std_*` cells on wasm;
`test-libs --lib std` wasm column. **Model:** opus. **Consumer commits:** none.

### B-00f — `@External.Beam` deleted; `@External.Erlang` binds erlang and beam (decision 437)

The beam target reads a declaration's `@External.Erlang` cell; `@External.Beam` is refused at the annotation.

- [x] `@External.Beam` is a located error at the annotation naming `@External.Erlang`
      (`` `@External.Beam` binds no host — the beam target reads `@External.Erlang` ``); a `reject` fence in `docs.md`
- [x] std's 31 `@External.Beam` cells deleted (`libs/std/src/**`); the 4 assembly cells of `primitives.bp` leave only their
      `@External.Erlang` pair; `grep -rn '@External.Beam' libs ../*/src` empty outside the refusal's test
- [x] `hostFnBinding.zig`'s `beam` reads `External.Erlang` only; `beam_asm.zig`'s `External.Beam` assembly read deleted;
      `inline = true` accepted on `External.Erlang` alone; `docs.md` (§ host functions, `fn:` on every target) and the
      codegen `AGENTS.md` files name one BEAM annotation
- [x] every beam `RUN LOG` and `run/` cell's `.out` unchanged

**Impacted tests:** `codegen/tests/externals.zig`, `features.zig`, `std_package.zig`; beam codegen snapshots (re-read);
`beam_export_audit`; `test-libs --lib std` beam column; `test-docs`. **Model:** sonnet (437 fixes the design).
**Consumer commits:** none (no library writes `@External.Beam`).

### B-00h — A transpiled std-wasm function is one line in a snapshot (decision 446)

Before B-00g, so the helpers B-00g moves into std-wasm do not grow every wasm snapshot that links them.

- [x] the wasm codegen snapshot's module text writes each function transpiled from `std_wasm.wasm` as one line
      `;; std:<module>.<function> — from std_wasm.wasm (sha256 <12 hex>)`, its body omitted; the snapshot helper
      (`codegen/snapshot.zig`) does it, never the emitter — `botopink build --target wasm` still writes the whole `.wat`
- [x] the binary the RUN LOG runs unchanged; every RUN LOG byte-identical
- [x] the nine snapshots B-00e grew back to their size before it plus one line per linked function (re-read, not
      bulk-accepted); a change in one std-wasm function changes one line in each snapshot that links it (a test)

**Impacted tests:** wasm codegen snapshots that link std-wasm; `codegen/tests/wat.zig`. **Model:** sonnet (446 fixes
the design). **Consumer commits:** none.

### B-00g — `wat_prelude` keeps only representation, operators, output and runtime (decision 442)

After B-00e (std-wasm transpiled into the program, its `std:` binding, 441's text). `codegen/wat/wat_prelude.zig`
keeps what defines a value's representation or talks to the host; what only computes over values is Zig.

- [x] every helper 442 (2) lists for std leaves `wat_prelude`: implemented in `modules/std-wasm` (Zig unit tests per
      function), bound by `#[@External.Wasm("std:…")]` on its std declaration (`primitives.bp` and the std modules),
      transpiled into the program where called; the `HelperGroup` members and their `wat_ast` nodes deleted
      — a helper the codegen picks by type (`joinInts` / `joinFloats` / `joinStrings`) sits in std-wasm's `program`
      table with no `std:` cell (454)
- [x] case mapping over all of Unicode in std-wasm (443): `toUpper` / `toLower` bound by `std:`, `$__str_case`
      deleted, the comptime's limit 3 gone; `run/` cells with non-ASCII letters (`é`, `ß`, `Σ`) on the four targets,
      each place JS and OTP differ measured and answered as OTP on wasm
- [x] `std:` refused outside `libs/std` (445), at the annotation, naming std's function — a `reject/` cell
- [x] `bigint` (`bn_*`) leaves `wat_prelude` for Zig beside std-wasm, its limbs internal; Zig unit tests and a
      property test against a reference (carry, `divmod`, text round-trip); the codegen calls it by pointer
- [x] the seeded random (451): its stream in std-wasm, bound by `std:` on `io/random.bp`'s `seed` / `seededFloat`; an
      unseeded draw through `env.bp_random_f64`, linked to `$__wasi_random_f64`; at comptime a seeded draw answers
      and an unseeded one is refused at the call — a `reject/` cell
- [x] transpiled Zig uses the program's `$__alloc` and the codegen's string / array layout — no second heap, no
      second stack pointer; a module that calls no moved helper renders byte for byte as before
      — 447: `$__std_sp` the one stack, std-wasm's frames only (no botopink value on it); laid out or checked so an
      overflow traps, never writes over data or heap (a test drives one past its end); its size the deepest frame
      path the program links
- [x] what stays is exactly 442 (1): `alloc`, `mem_eq`, `box_*`, `arr_at_box`, `arr_new`, `arr_push`, `arr_at`,
      `str_concat`, `str_eq`, `str_slice`, `int_chk`, `u64_chk`, `*_range_chk`, `i32_abs` / `min` / `max`, the print
      family (the number's text from std-wasm, the I/O here), the `@Task` scheduler, `unknown`, `assert_fail`; the
      rule of 442 (3) written in `codegen/wat/AGENTS.md`
- [x] every wasm `.out` and RUN LOG unchanged except where 441 changes the text; the size an emitted module gains
      or loses measured (a hello world, a `bigint` program, onze's blog page) and recorded in `codegen/wat/AGENTS.md`

**Impacted tests:** every wasm RUN LOG snapshot (re-read, never bulk-accepted); `run/` cells on wasm, `bigint_*`
first; `test-libs` wasm column; `modules/std-wasm` unit tests. **Model:** opus. **Consumer commits:** none.

#### Step 5 — the rest of std on wasm (decisions 262, 241) (was `05-wasm` s5)

`unicode` builds and runs on wasm: `fromCodepoint`, `firstCodepointOrZero` and `codepoints` are
`fn:` bodies, `normalize` std's botopink normalizer (`02/97` step 16, decision 333 (A)), and
`run/std_unicode_on_every_target` has one `.out` for the four targets. `json.parse` /
`json.stringify` have no `@External.Wasm`. `run/std_module_imports_std_module`
keeps its `.wasm.expect`, `run/std_template_host_fns_across_modules` and
`run/std_default_fn_in_a_std_module` their `.targets`, though `encoding` now binds every cell on wasm.
The limits table of `wat/AGENTS.md` still carries the one-page row.

- [ ] `botopink build --target wasm` in `libs/std` refuses only group 3's modules (`json` waits on
      `02/97` step 15 (336); `unicode` builds)
- [ ] a `run/` cell per remaining module family on four targets, the commonJS answers — `json` drops
      its `.wasm.expect` once `02/97` step 15 (336) lands (`encoding`, `querystring`, `unicode` done)
- [ ] `wat/AGENTS.md` § Where this backend refuses to answer lists only group 3 (the limits table's
      one-page row is gone)
- [ ] the bindings this step adds written in 305's form — `@External.Wasm(fn: name)`, `op: "…"`,
      `wasi: .Adapter` — never the prefixed string: the parser refuses `fn: name` until `01-checker`
      step 27, so `unicode`'s two new bindings are prefixed strings that step migrates

#### Step 11 — std on wasm, group 3 (decision 230) (was `97-std-dedupe` s11)

Modules whose wasm build is not a compiler question (groups 1, 2 are `01-compiler/05-wasm` step 5):
`io/http` (`fetch`), `async` (`gateHandle`), `testing/mocks` (`pushMatcher`), `testing/asserts`
(`canonical`, decision 146). Per module: (a) out of a wasm build — manifest or module refuses wasm
with a located message, recorded as the design; or (b) restructured so no host cell is reachable.

- [ ] `io/http` and `async` build on wasm through step 17 (334, 335); `testing/mocks` keeps its located refusal on wasm
      until `botopink test` runs the wasm column, then its registry moves to the module's memory (335 (3)); `testing/asserts` per
      `decision 503` — each refusing module refuses with a located message, recorded in `libs/std/AGENTS.md` as the design

### B-01 — 431 (1): the effect messages and docs

**Repository:** botopink-lang (`--lang`)

431's clause (1) is built in code (`effect-try-without-fallible-channel` absorbs `throw`'s code, no implicit
`try`, `for-over-stream` / `for-await-expects-stream`); left: the two messages (`infer.zig`
`fallibleChannelRefusal`, `error.zig`) and the docs. 24-a is answered by 431 and 24-b by 432 (B-27 records them).

**Impacted tests:** `reject/try_in_lambda_without_result.expect`; the comptime error snapshots naming the code.
**Model:** haiku. **Consumer commits:** none.

#### Step 42 — a host binding that throws answers a `@Result` (decision 431) — part (was `01-checker` s42 box 3)

- [x] `effect-try-without-fallible-channel`'s message names `try … catch` and `result: true` (490's name for 431's `throws: true`); the reference (`conformance/docs.md`) § Results, § Host bindings

#### B-01 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

The group's changes against the cells (B-01, B-03 … B-06; box 3, written once for the five):

| Behaviour (decision) | Cells |
|---|---|
| `effect-try-without-fallible-channel` names `try … catch` and `result: true` (431 (1), 490) | `throw_outside_result`, `try_in_plain_fn`, `task_throw_without_result`, `task_try_await_without_result`, `component_try_element`, `throw_in_generator`, `try_in_generator`, `try_in_lambda_without_result`, `iterator_throw_without_result` |
| `result:` on every `@External` variant, a labelled bool in any order, beside `inline:` (487, 490) | `external_result_return_accepted` |
| a bare positional `true` / `false` refused at the argument (487) | `external_flag_bare_bool_refused` |
| a `result:` that is not a bool refused (487) | `external_result_not_bool` |
| `result: true` only on `@Result<…, HostError>` / `@Task<@Result<…, HostError>>` (431 (2), 490) | `external_result_return`, `external_result_task_plain_value`; on a behavior method the comptime error snapshot only |
| `HostError` is std's `failure.HostError` by module identity (488) | `external_result_own_host_error`, `external_result_return_accepted` |
| std's own path import of `failure.HostError` counts (488) | `codegen/tests/std_package.zig` only — a cell cannot import std's sibling by path |
| `result:` beside `fn:` / `op:` refused (491) | `external_result_on_fn_cell`, `external_result_on_wasm_op_cell` |
| std `failure`: `HostErrorName`, `HostError`, `Failure` (489, 492) | `std_failure_types` |
| a sync `result: true` binding answers `Ok` / `Error(HostError)` on commonJS, erlang and beam; wasm wraps nothing (431 (2), 489, 490, 491) | `external_result_host_error` |
| an erlang `exit` is `HostErrorName.Exit` (489) | `external_result_erlang_exit` |
| host methods wrapped the same way (490) | `external_result_host_method` |
| a `result: true` `@Task` binding's rejection or raise is `Error(HostError)` (431, 432) | `external_result_host_error`, `host_node_task_result`, `external_result_host_method` |
| std `io/http`'s `fetch` over a private `result: true` binding (486) | none — a row |
| a failing task rejects on commonJS and reads back through `await` on every target (432) | `task_result_rejects`, `task_throw_resolves_error`, `task_async_block_in_lambda`, `task_lambda_result_unannotated` |
| a JS caller's `try` / `catch`; a dropped failing task is no unhandled rejection (432) | `task_result_caught_by_js` |
| the `.d.ts` declares `Promise<T>` under `@throws {E}` (432) | none — a row |
| std/async `runAll` / `raceOf` / `race` over a failing task (432) | none — a row (`std_async_on_every_target` covers `allOf` only) |


### B-03 — 431 (2): `throws:` on every `@External` variant, checked

**Repository:** botopink-lang (`--lang`)

`builtins.d.bp`'s External variants gain `throws: bool = false`; `refuseThrowsReturn` (`throws: true` only on
`@Result<…, failure.HostError>` or `@Task` of one); `ast.externalRefOf` trims every bool flag. Questions
`decision 487`, `decision 488`.

**Impacted tests:** new `modules/external_result_return`, `modules/external_result_return_accepted`; `comptime/tests/effect_{future,generator}.zig`;
`infer_decls` drift. **Model:** opus. **Consumer commits:** none (B-08 carries them).

#### Step 42 — a host binding that throws answers a `@Result` (decision 431) — part (was `01-checker` s42 box 1)

```bp
#[@External.JavaScript("JSON.parse($0)", throws: true), @External.Erlang("json:decode($0)", throws: true)]
declare fn jsParse(s: string) -> @Result<Json, HostError>;
val doc = try jsParse(texto);                      // a JS SyntaxError / an erlang raise is Error(HostError(…))
```

- [x] `result: true` (490's name for `throws: true`) on every `@External` variant, a labelled `bool` read in any order
      (487); refused unless the declared return is `@Result<…, HostError>` or `@Task<@Result<…, HostError>>`, std's
      `failure.HostError` by identity (488), and beside an `op:` / `fn:` cell (491) — `modules/external_result_return`,
      the accepted shapes `modules/external_result_return_accepted`

#### B-03 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-04 — 431: std `failure` — `HostError`, `Failure`

**Repository:** botopink-lang (`--lang`)

**Impacted tests:** `test-libs --lib std`; `run/std_failure_attempt` (with B-07). **Model:** sonnet. Question
`decision 492` (the kinds). **Consumer commits:** none.

#### Step 18 — `failure`: `HostError`, `Failure`, `attempt` (decision 431; with `01-checker` step 42) — part (was `97-std-dedupe` s18 box 1)

- [x] `libs/std/src/failure.bp`: `HostErrorName`, `pub type HostError(message, kind, name, detail)` (489),
      `pub type Failure(message: string, kind: string)` (`panic` / `host` / `crash`, 492) — `modules/std_failure_types`
      on the four targets; `root.bp` gains `pub mod failure;`; `attempt` and its `@Task` form are B-07's

#### B-04 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-05 — 431 (2): each backend wraps a `throws: true` cell

**Repository:** botopink-lang (`--lang`)

commonJS: a sync binding in a `try/catch` answering `{ok}` / `{error: HostError(e.message, kind)}`, a `@Task`
binding's rejection a `HostError` rejection, `__bp_host_task` only under `throws: true` (`decision 490`); erlang and
beam: `try … catch Class:Reason` building `HostError` (`decision 489`); wasm: the `wasi:` adapter's error, `throws:`
refused on `op:` / `fn:` (`decision 491`). Consequence of 431 + 432, recorded (no question): a `throws: true` `@Task`
binding on commonJS rejects with `HostError(e.message, e.name)`.

**Impacted tests:** new `modules/external_result_host_error` (four targets); `run/host_node_task_result` rewritten;
the host-task JS snapshots; the erlang / beam columns (`run/host_erlang_task_result` unchanged). **Model:** opus
for the shape, sonnet per backend. **Consumer commits:** none.

#### Step 42 — a host binding that throws answers a `@Result` (decision 431) — part (was `01-checker` s42 box 2)

- [x] each backend wraps a `result: true` cell: commonJS `__bp_host_result` / `__bp_host_result_task` (a throw, a
      rejection, a throw before the Promise), erlang and beam `try … of … catch Class:Reason:Stack` (an `{error, R}`
      answer an `Error` too), host methods the same; `HostError` per 489; wasm wraps nothing (no `wasi:` adapter fails,
      `result:` refused on `op:` / `fn:`) — `modules/external_result_host_error` on the four targets,
      `host_node_task_result` rewritten; std `io/http`'s `fetch` over a private `result: true` binding (486). A
      `result: true` `@Task` on commonJS resolves to `{error: HostError}` until B-06 makes it reject (432)

#### B-05 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-06 — 432: a failing task rejects, on four targets

**Repository:** botopink-lang, with consumer commits in jhonstart, rakun (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

- [x] erlang and beam end a failing task's process with `{error, E}`; the wasm scheduler settles the task with
      the error — `run/task_result_rejects` on the four targets

**Impacted tests:** new `run/task_result_rejects`, `run/task_result_caught_by_js`; `run/task_throw_resolves_error`
inverted (it resolves `Error` today); `run/component_result_try_await`, `run/task_await_result`; the JS task
snapshots; the drift test in `comptime/builtins.zig`. **Model:** opus (fable if opus fails once — highest risk
against 388's commonJS async lowering). **Consumer commits:** jhonstart (`render.bp` / `streaming.bp` awaits),
rakun (task callers) — measured in the step.

#### Step 13 — a failing task rejects (decision 432) (was `04-js` s13)

```js
async function buscar(id) { if (id <= 0) throw HttpError.BadId; return await http_get(…); }   // not { Error: … }
```

- [x] a `@Task<@Result<T, E>>` lowers to an `async function` whose `Error(e)` / `throw e` rejects with `e` and whose success
      resolves with the bare `T`; `await` under `try` / `case` reads a rejection as `Error(e)`; the `.d.ts` names `E` —
      `run/task_result_rejects`, `run/task_result_caught_by_js` (a JS caller's `try/catch`), the `snapshots/codegen` that
      print `{ Ok }` / `{ Error }` for a task re-recorded
- [x] `js/AGENTS.md`'s 179 row (no `unwrapOrThrow`) rewritten for 432 — the lowering is a function answering a
      marked Promise (`__bp_task`; an `await` that may meet a failing task reads it through `__bp_await`), the `.d.ts`
      `Promise<T>` under `@throws {E}`; `conformance/modules/task_result_rejects` (four targets),
      `task_result_caught_by_js` (commonJS), `task_throw_resolves_error` inverted; jhonstart and rakun needed no change

#### Step 2 — declare the rest — part (was `134-builtins-declared` s2 box 4)

- [x] `Task`'s surface by decision 523: `map`, `then`, `mapError` and `catch` withdrawn (a call refused, `task_method_refused`), composition by an `async` block (`task_compose_by_async_block`), `task_throw_resolves_error` renamed `task_failure_rejects`

#### B-06 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-07 — 431: `attempt`, and the asserts over it

**Repository:** botopink-lang, with consumer commits in jhonstart (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

Then jhonstart's `__jhTryValue` / `__jhTryTask` go, in jhonstart's consumer commit (its renderer, 388 / 414, landed). Questions `decision 493`,
`decision 494`; wasm `decision 491`.

**Impacted tests:** `run/std_failure_attempt`; `run/std_asserts_host_cell_on_wasm`; the 82 files calling
`throws` / `throwsWith` / `tryCatch`. **Model:** sonnet. **Consumer commits:** jhonstart (the `__jhTry*`
replacement).

#### Step 18 — `failure`: `HostError`, `Failure`, `attempt` (decision 431; with `01-checker` step 42) — part (was `97-std-dedupe` s18 boxes 2, 3)

- [x] `failure.attempt<T>(f: fn() -> T) -> @Result<T, Failure>` and its `@Task` form on the four targets; on wasm by
      exception handling, its binding declaring `needs: [.Exceptions]`, the host handed the flags the program's
      `botopink.needs` section names; `needs:` outside `WasmNeed` refused; STD-001 at the call (518) —
      `std_failure_attempt`, `std_failure_attempt_task`, `external_wasm_needs_unknown`, `std_unsupported_refused_at_the_call`
- [x] decision 126's flagless `__bp_host_task` conversion removed (490): B-05 kept it because jhonstart's
      `__jhTryTask` relies on it — it goes with jhonstart's `attempt` consumer commit below
- [x] `testing.asserts`' `throws` / `throwsWith` over `attempt`, the private `tryCatch` cell gone; jhonstart's
      `__jhTryValue` / `__jhTryTask` replaced by `attempt` in `05-jhonstart/26` step 14 (a consumer row below)
- [x] `std_failure_attempt` (a panic, a host raise, a value) on the four targets; `libs/std/AGENTS.md`'s table

#### B-07 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

  | Behaviour (decision) | Cells |
  |---|---|
  | `attempt`: a value is `Ok`, a `@panic` is `panic` (431, 492) | `std_failure_attempt` |
  | a host raise is `host`, its erlang message `~tp` (492, 527) | `std_failure_attempt_host` |
  | an unmarked raise is `crash` (527 (1), 546) | `std_failure_attempt_crash` |
  | `@todo` and `x!` over null are `panic` (492) | `std_failure_attempt_abort_kinds` |
  | an integer overflow, a division by zero are `panic` (492, 527 (3)) | `int_division_by_zero_is_panic` — wasm traps (164 s2c) |
  | a failing `assert` is `panic` (527 (2)) | `assert_failure_is_panic` |
  | `attemptTask` (494) | `std_failure_attempt_task` |
  | `asserts.throws` / `throwsWith` over `attempt` (493) | `std_asserts_throws_over_attempt` |
  | `needs:` outside `WasmNeed` refused (518 (1)) | `external_wasm_needs_unknown`; the two other `needs:` refusals wait on 518-a |
  | STD-001 at the call (518 (4)) | `std_unsupported_refused_at_the_call`, `std_unsupported_names_the_call`, `std_asserts_host_cell_on_wasm` |
  | `attempt` at build (518, 543) | `comptime_attempt_at_build` |
  | `try … catch` catches only the operand's `Error` (431, B-103) | `try_catch_host_raise_propagates` |
  | the uncaught abort's text (535) | `abort_text_host`, `abort_text_panic`, `abort_text_crash` |
  | 126's flagless task conversion retired (490) | `host_node_task_result` |

### B-08 — 431: std's hand-written catches become `throws: true`

**Repository:** botopink-lang, with consumer commits in onze, rakun, snap, validation, jhonstart, log, http, routing (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

std's hand-written try/catch templates are boundaries by hand (fs 11 Node + 2 Erlang, json 3+3, encoding 1+3,
hash 1+1, regex 1, async 3, primitives 1, http 1, process 1, clock 1, asserts 1+1 — measured on botopink-lang
`feat`); a binding that raises without catching is a crash under 431 (2). Questions `decision 486`, `decision 495`.
Sequence with 142 s1 (`json` leaves std, B-27).

- [x] every std binding that catches by hand declares `throws: true` and answers `@Result<T, failure.HostError>`,
      or maps `HostError` into the typed error a decision names (`HttpError` 393 / 335, `StoreError` 304,
      `ActionError` 303), per `decision 486`; no hand-written `try` / `catch` template left in `libs/std/src`
- [x] every binding that raises without catching audited: `throws: true`, or documented in its module as
      promising no raise (`decision 495`); the list in `libs/std/AGENTS.md` — built with `result: true` (490); `json`,
      `regex` and `process` answer `HostError` until their enums (B-130); `encoding`'s decoders `EncodingError`,
      `clock.parseIso8601` `ClockError`, `io.fs` through `FsError`; cell `std_host_error_variants`
- [x] the consumer commits: rakun — `rakun-service/src/rules.bp` (`regex.compile` answers `@Result<Regex, HostError>`;
      it takes down every package that imports rakun-service), `rakun-ssr/src/assets/preprocess.bp` and
      `rakun-cli/src/cli.bp` (`io.process.run`'s `Error` is `HostError`); log — `test/formats_test.bp`
      (`io.clock.parseIso8601`'s `Error` is `ClockError`); each library's gate green on `feat`'s compiler

**Impacted tests:** `test-libs --lib std`; every library's suite (≈330 call sites change error type).
**Model:** opus for the policy, haiku for the codemod. **Consumer commits:** onze (158 sites), rakun (121),
snap (17), validation (17), jhonstart (12), log (5), http (1), routing (1) — one per repository, in the landing.

#### B-08 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-09 — 431 / 432: the error contract in the docs and the AGENTS files

**Repository:** botopink-lang (`--lang`)

- [ ] `docs.md` § Results, § Host bindings, § Effects state 431 and 432 as one contract (`throws: true`,
      `HostError`, `Failure`, `attempt`, a failing task rejects); `libs/std/AGENTS.md`'s `failure` row; each
      backend's `AGENTS.md` names its wrap

**Impacted tests:** `zig build test-docs`. **Model:** haiku. **Consumer commits:** none.

#### B-09 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-12 — 346, 342: `Bytes`, `@embedFile` / `@embedBytes`

**Repository:** botopink-lang (`--lang`)

**Impacted tests:** `run/bytes_round_trip`, the `reject/` cells; the embed cells. **Model:** opus.
**Consumer commits:** none here; unblocks rakun 13, 15, 22, 91, 92, 93 (`rakun ws generate`'s checked-in `.bp`),
http 104, validation 125, rakun 127.

#### Step 32 — a `Bytes` primitive (decision 346) (was `01-checker` s32)

Today no primitive, std type or literal holds bytes (`val b: Bytes = "a";` mismatches everywhere) and
every host cell marshals through `string`.

- [x] `Bytes` in `primitives.bp` (as `bigint`, no declaration in `builtins.d.bp`): an immutable byte sequence;
      `Bytes.fromUtf8(s: string) -> Bytes`; `b.toUtf8()` answering `@Result<string, string>` (an `Error` on invalid UTF-8)
- [x] no conversion between `string` and `Bytes` without those calls: `modules/bytes_string_literal`,
      `modules/bytes_where_string_expected`
- [x] a host cell may take and answer `Bytes` (an Erlang binary, a `Uint8Array` on commonJS, a buffer in wasm
      memory): `modules/bytes_round_trip` on the four targets
- [x] the rest of the surface — length, slice and `b[a..e]`, concatenation, `==` / `!=`, `encoding`'s four bridges —
      with its cells (`bytes_*`); `docs.md` § Primitives; `language-gaps.md`'s byte row closed in the compiler. The
      restrictive readings it took (no widening to `unknown`, so `@print(b)` is refused; no `is` or type pattern; no
      `comptime` value; no ordering; `+` with a string and a template hole refused) — question B-12-a

#### Step 33 and Step 6 — `@embed(comptime path) -> Asset` (decisions 519, 520)

- [x] `@embed(comptime path)` declared and checked as a `Build` builtin, `Asset` (`path`, `bytes`, `size`, `hash`,
      `text()`) a compiler type; a call known at build computed where written; an argument not known at build, an
      absolute path, a `..` segment, a missing file, `text()` on non-UTF-8 bytes and `compiler-web`'s missing reader
      refused, located — `embed_path_absolute`, `embed_path_outside_package`, `embed_file_missing`,
      `embed_text_not_utf8`, `embed_path_not_known`
- [x] read by the writing package's `botopink.json` (a path through a `comptime` parameter in the caller's package),
      through a reader the CLI and the LSP hand the compiler; embedded on the four targets (an Erlang binary, a JS
      `Uint8Array`, a wasm data segment); a `Bytes` value at build a build constant (520) — `embed_text_file`,
      `embed_binary_file`, `embed_through_comptime_param`, `bytes_comptime`
- [ ] every file read joins B-60's closure key: a file under `src/` moves it today (`test-analysis-equivalence`); a
      file outside `src/` does not — the key records no read made at build (B-60's design)
- [ ] `@embed` through a `comptime` parameter of a decorator or template body: refused `comptime-arg-not-known` —
      the wasm comptime runtime has no host import to read a file

#### B-12 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-13 — 304: a method declared `-> @Result` lowered as a `@Result` on erlang

**Repository:** botopink-lang (`--lang`)

**Impacted tests:** the `run/` cell of the step, erlang and commonJS. **Model:** sonnet (a measured repro).
**Consumer commits:** none; unblocks rakun 08 s6, 09 s6, 65 s4.

#### Step 14 — a method declared `-> @Result` is lowered as a `@Result` (decision 304) (was `02-erlang` s14)

Measured by rakun (`rakun-data/src/sql/template.bp`, comment above `tryQuery`): on erlang a **method**
declared `-> @Result` is lowered as a plain function — a `throw` in it escapes as a raise and a returned
value is not wrapped in `{ok, V}` — while a module-level fn is lowered correctly.

- [x] `run/` cell: a method `-> @Result<i32, string>` with `return 1`, `throw "x"` and `try other()` answers `{ok, 1}`, `{error, "x"}` and the propagated error — same as the module-level fn cell
- [x] the same cell on js (no change expected; asserted)
- [x] a behavior method (`KeyValueStore.get`) declared `-> @Result` dispatches and wraps the same
      Measured on `feat`: already lowered right on every target — `result_method_throw` (a record's and an enum's
      method: `return`, `throw`, `try`, pass-through), `behavior_method_result_typed` and `behavior_method_result_chained`
      green on commonJS, erlang, beam and wasm; no code change. rakun's `tryQuery` comment is stale (150 s28)

#### B-13 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

| Behaviour (decision) | Cells |
|---|---|
| a record's and an enum's method `-> @Result`: `return`, `throw`, `try`, pass-through (304) | `result_method_throw` |
| a behavior method `-> @Result` through a behavior-typed parameter, `default fn` included (304) | `behavior_method_result_dispatch` (a pin), `template_method_call` |
| a behavior method answers its declared type | `behavior_method_result_typed`, `behavior_method_result_chained` |


### B-26 — 340: the keyed `Dict`'s per-row increment

**Repository:** botopink-lang, with consumer commits in rakun (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `run/beam_memory_ets`. **Model:** sonnet. Question `17-c`. **Consumer commits:** rakun
(`rakun_runtime.erl`'s registry, through 150).

#### Step 1 — the per-row increment (box 4, decision 340) (was `17-beam-memory` s1)

- [x] std's `Dict.bump(key, by) -> Dict<K, V>` (integer `V`, an absent key counts from 0) is
      `insert(key, (at(key) ?? 0) + by)` on any `Dict`; on a keyed var `counts = counts.bump(k, n)`
      lowers to `ets:update_counter(T, k, n, {k, 0})` on erlang and beam — a `run/beam_memory_ets`
      cell with concurrent bumps of one key losing none; `counts.insert(k, (counts.at(k) ?? 0) + n)`
      stays refused (no pattern recognised); `docs.md`'s `keyed` sentence names `bump`
      Cell `beam_memory_ets_keyed_bump` (two processes, one key, none lost); a non-integer `V` refused; rakun's
      registry to `bump` is 150 s28

#### B-26 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

| Behaviour (decision) | Cells |
|---|---|
| `counts = counts.bump(k, n)` on a keyed var is one atomic `ets:update_counter`, an absent key from 0 (340) | `beam_memory_ets_keyed_bump` |
| `Dict.bump` on any `Dict` is `insert(key, (at(key) ?? 0) + by)` (340) | `dict_bump` |
| `bump` on a keyed `Dict` of non-integer rows refused (340) | `beam_memory_ets_keyed_bump_non_integer` |
| a `bump` whose key or amount reads the var is the recompose refusal (340, 168) | `beam_memory_ets_keyed_bump_reads_itself` |
| the written-out increment stays refused (340) | `beam_memory_ets_keyed_read_modify_write` (a pin), `beam_memory_ets_keyed_recompose` |
| `bump` on a plain `Dict` of non-integer `V` | none — question B-26-a |


### B-28 — The formatter: the `;` after a braced block, C-12, the trailing comma, annotations as written

**Repository:** botopink-lang, with consumer commits in every library repository (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `format/tests/**`, `scripts/format-check.sh` over every tree. **Model:** sonnet; haiku for
the migration runs. **Consumer commits:** every library repository (the `;` migration, then the C-12 reformat —
one per repository; erika's is 145 s3).

#### Step 1 — re-count the siblings' `;` sites (was `16-formatter` s1)

`c13-migrate.py --dry-run` (add if absent: print sites, write nothing) over
`repository/{rakun,jhonstart,erika,onze,emilia}/**/*.bp`; 1.0.10: rakun 454, jhonstart 40, erika 28,
onze 1.

- [x] a count per library, with the command, in this README
      Counted on `feat` (dry run, nothing written): rakun 4, jhonstart 26, erika 0, onze 183, emilia 2 — every `.bp`
      under `repository/<lib>/`, examples and `conformance/` included; command, from the meta root:
      `find repository/<lib> -name '*.bp' -print0 | xargs -0 python3 c13-migrate.py --dry-run` (`--dry-run` added to
      the script by this step: it prints each site and writes nothing)

#### Step 2 — the migration in each tree (the tracks run it) (was `16-formatter` s2)

Each track runs it at the end of its last thread in that tree (07 for erika); verified per the
script's docstring — changed lines differ only by a deleted `;`, `botopink format` before/after
byte-identical, cells green before and after.

- [ ] every tree at 0 sites (step 1's command re-run): emilia, jhonstart, onze and botopink-lang (its 64, all in 45
      `conformance/` cells) at 0 on `feat`; the other thirteen libraries and vscode-extension had none; rakun's 4 wait
      on 150 s30 (its hook red on `sql_build_test.bp:148`)

#### Step 3 — the parser refuses the `;` (was `16-formatter` s3)

The patch narrowed to `isBracedBlockStmt` (`;` after a braced `if` / loop / `case` statement =
`blockStatementSemicolon`, located at the `;`, message naming the closing brace), rebased on 01's
parser rows. Reds every `.bp` still writing it — hence last.

- [ ] `reject/braced_block_trailing_semicolon` — the code and the caret at the `;`
- [ ] `zig build test`, `test-libs`, `test-language` green; no parser snapshot moves but the new error fixture's
- [ ] `docs.md`'s row moves from "optional" to "refused"; `src/parser/AGENTS.md` in the same commit

#### Step 4 — the siblings' reformat at C-12's rules (after step 6, decision 345) (was `16-formatter` s4)

Once step 6 lands each track runs `botopink format` on its tree; this front measures copies first
(token-identical, idempotent, cells equal; the hunk counts measured under 16-a — emilia 18 files,
rakun 47, jhonstart 19, erika 2, onze 2 — re-derived under 345: lists written open without a
trailing comma now join).

- [ ] the copies' measurement in this README; the tracks' commits; `botopink format --check` exit 0 in every member of every library

#### Step 5 — the one-line trailing lambda (decision 165) (was `16-formatter` s5)

A fitting one-expression trailing-lambda body prints on one line, arrow or not; today rule 3 stops at
`arrow_when_empty` (`format.zig` `fmtLambdaAt`): `h1 { "my blog" }` takes three lines. Canonical form
into `src/format/AGENTS.md` first; own commit after step 6.

- [x] `h1 { "my blog" }` round-trips on one line; `assertFormat` / `assertIdempotent` / `assertLossless` cases; movement per tree measured and reported to the tracks

#### Step 6 — the trailing comma alone decides (decisions 166, 243, 345) (was `16-formatter` s6)

Every delimited list (generics, parameters, patterns, imports, types, arrays, record fields, enum
bodies, call arguments, tuples) with a `,` after its last element prints one per line and keeps the
comma; without it the list prints on one line whatever its width, and a list written open without
the comma is joined (345). No width rule opens a list: 16-a's `groupMeasured` leaves the argument
list and the array / tuple literals (a binary run and a brace-less `if` keep it), 16-b's open array
goes. One-step pipeline: no comma, horizontal.

- [x] one `assertFormat` case per list kind, both spellings; the six trees measured before and after; `src/format/AGENTS.md` states the rule
- [x] 345 in the printer: a list without the trailing comma stays on one line past the width, and one written
      open without it joins (`assertFormat` cases); 16-a's `groupMeasured` kept only for the binary run and the
      brace-less `if`; 16-b's open array removed

#### Step 7 — C-11's boxes closed (was `16-formatter` s7)

`{ -> 42 }` / `calcular(fator: 2) { a, b -> a + b }` as trailing lambdas parse
(`run/loop_one_line_body`); `examples/jhonstart-app` clause struck (files not in this tree);
`builtins.d.bp` in `TREES` and green.

- [ ] the C-11 boxes ticked with the measurement, or the residual named

#### Step 9 — annotations printed as written (decision 286) (was `16-formatter` s9)

Today the printer splits `#[a, b]` into one `#[…]` per annotation (`src/format/AGENTS.md` § canonical
rewrites; `format/tests/helpers.zig` expects the split). After, both forms survive formatting
untouched — separate blocks stay separate, a list stays a list — and a list breaks by decision
166/243's trailing comma.

```bp
#[check("As senhas não batem", passwordsMatch, at: .confirm)]
#[check("Esse nome já é usado", noReusedHandle)]
pub type Account(…)                     // stays two blocks

#[
    compiler.external(.Erlang("math:fmod($0, $1)"), .JavaScript("$0 % $1")),
    serverOnly,
]
fn mix(…) -> …                          // stays one list, one per line (trailing comma)
```

- [x] `#[a]` / `#[b]` round-trips as two blocks, `#[a, b]` as one list; with a trailing comma the
      list prints one per line; `assertFormat`, `assertIdempotent`, `assertLossless` cases for a
      function, a type, a field, a method, a loop and a mix of builtin (`@`) and custom annotations
- [x] the template annotation (decision 311) prints as written: `#[erika "…"]` and `#[erika """…"""]`
      round-trip unchanged, alone and inside a list (`01-checker` step 29 adds the node) — alone:
      built (`format/tests/declarations.zig` "template annotation"); inside a list it prints as its
      own block, as every list does, until box 1
- [x] a comment between two blocks, or inside an open list, stays where it was written;
      `helpers.zig`'s containment note and `src/format/AGENTS.md`'s canonical-rewrite line rewritten
- [x] the order is kept: a parser snapshot of `Decl.annotations` before and after formatting is equal
- [x] the trees of `scripts/format-check.sh` measured: no file moves but the lists the old split had
      broken up (reported to the tracks)

#### B-28 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-29 — The gate, CI and the residual sweep

**Repository:** botopink-lang, with consumer commits in emilia, jhonstart, rakun (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

- [ ] `codegen/runtime.zig`'s own `test` blocks run: `codegen/tests.zig` imports the file (`runtimeTrapLog`,
      `compileFailureLog`, the duplicate-atom refusals found by `-Dtest-filter`) — from status.md L1

**Impacted tests:** `scripts/gate.sh --cold`; botopink-lang `test.yml` / `release.yml` on GitHub; the snapshot
reports. **Model:** haiku for the sweeps, sonnet for the cold gate. **Consumer commits:** emilia, jhonstart, rakun
(07 s9, `->` arms, if C-14 removes them).

#### Step G — one job budget for the gate (measured 2026-10-11)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

Measured on the tip of the B-00 group, one cold gate alone on the 16-core machine: **12m27s wall, 5680 CPU-s**,
load rising from 4.7 to 26 — the gate's own doing. The serial head is `zig build` ReleaseSafe 3m17 (820 CPU-s)
then `zig build test` 1m52; the side-by-side stages are `test-language` 9m02 (1468 CPU-s), `test-libs` 8m21
(2540 CPU-s), `test-cli` 4m42 (273 CPU-s), each sizing its own pool to the whole machine — three pools of ~16 jobs
on 16 cores. 5680 CPU-s fit in ~6 min on 16 cores. A warm (`--staged`) gate measured 9m37. A shared `.zig-cache`
does not help: compiler-core is one Zig module, recompiled whole on any change (the main checkout's warm cache
still took 3m17).

- [x] one job budget for the whole gate: the side-by-side stages (`test-libs`, `test-language`, `test-cli`,
      `test-docs`, `tsc-check`, `test-web`) draw from one pool sized to the machine (CPUs, bounded by memory), never
      a pool each; the order of each stage's report unchanged
- [x] `zig build test` (Debug) runs beside `zig build -Doptimize=ReleaseSafe` instead of after it, when the
      machine has the memory for both; a red in either still stops the gate before the side-by-side stages
- [x] the step gate (decision 460): on a `front/*` branch the hook runs formatting, the build, `zig build test`,
      `test-cli`, and the `test-language` cells and `test-libs` libraries the staged change reaches by the backend
      partition (249) — a shared file reaches all; on `feat` and at a front's Conformance step the full gate; the
      branch decides, no flag or variable; measured: a one-backend step's gate time against the full gate's.
      Since decision 470 the hook's step gate runs without the conformance cells (`--no-conformance`), and the full
      gate with conformance is `feat`'s GitHub pipeline, which a front's Conformance step reads (477)
- [x] measured again, one gate alone: cold and warm wall times and CPU-s per stage recorded in
      `scripts/AGENTS.md` § Where the gate's time goes, against this step's numbers; no stage, cell or check
      dropped and no verdict changed (decision 67)

Measured after (one gate alone, load < 3 at start): cold 10m24 / 10m36 (4616 / 4665 CPU-s), warm 1m35 (419 CPU-s);
split 8 / 4 / 1 / 1 by the stages' measured CPU share. Still over the 7m30 cold budget: a job is about two runnable
threads (the `botopink` child and its `erl` / `node`), so load still peaks near 28–30; `test-language` (7m12) is the
pole and runs alone for its last ~1.5 min. Under heavier splits rakun's timing tests went red (`rakun·erlang` 503
over max-connections, `rakun-messaging·erlang` dlq, `rakun-data·erlang` devtools watcher: 1 red in 4 cold runs at
8 / 4 / 1 / 1) — a 150-rakun row (150 s25). What remains: step H.

#### B-29 step G Conformance (decisions 459, 474, 477, 478, 479, 480) — the step's last box group

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the step's other boxes have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the step landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the step's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the step's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the step changes, its runs on `feat` since
      the step's base, green or each red named

| Behaviour (decision) | Test |
|---|---|
| one job budget split 50 / 30 / 10 %, at least 1 each | `cli_contract.sh` § the gate (`pool_share`) |
| `zig build test` beside the ReleaseSafe build, a red stopping the gate | read from `gate.sh` — no cheap test runs a gate in the hook |
| the step gate on a `front/*` branch, the full gate elsewhere (460) | `cli_contract.sh` (`gate-mode.sh`) |
| what a step reaches through the backend partition (249) | `cli_contract.sh` § the gate, seven cases |

#### Step H — `tests/language` cells run in process where no CLI path is under test (after step G)

**Repository:** botopink-lang, and erika for `generic-loader-binding` (a full worktree) · **Model:** opus (which cells still need the CLI is a judgement)

`test-language` is the gate's critical path (9m02 cold alone, 2707 jobs, 1468 CPU-s): a `botopink` process per cell
per target, then `node` / `escript` / `wasmtime`. compiler-core's tests check thousands of cases and ~1400 snapshots
in process in 327 CPU-s. The cells stay the language's description — the same `.bp`, `.out`, `.expect` files, in
botopink-lang, landing in the compiler's commit (red on the parent, green after); only how they run changes.

- [x] `tests/language/` becomes `conformance/` (decision 466) and every cell is in decision 457's shape: `<cell>/src/<module>.bp`, `snapshot/output/<module>.snap` (one answer
      for every target), `snapshot/targets/<target>/<module>.snap` (a target's departure only), `targets` (when
      narrowed) — `run/`, `reject/` and `modules/` migrated by a codemod, each cell's claims byte for byte the same
      (every `.out`, `.exit`, `<target>.expect`, `<target>.stderr`, `.targets` mapped, none lost)
- [x] `botopink cell new <path>` and `botopink cell check <cell|directory>` (decision 464) in `compiler-cli`, over
      compiler-core's executors: run on every declared target, compare with `snapshot/output/` and
      `snapshot/targets/`, a mismatch a `.snap.new` candidate and exit 1, a new cell's candidates by agreement /
      majority / one per target; no update flag; CLI contract cases in `cli_contract.sh`
- [x] every cell has its own `botopink.json` (decision 475 (1)): `botopink cell new` writes one, `botopink cell check`
      refuses a cell without one, the migration writes one per cell (its `name`, its `"targets"` from today's
      `.targets` sidecar, its path dependencies); an answer that names the package (an erlang atom, a host template)
      measured and re-read cell by cell, never bulk-accepted
- [x] no `botopink` process per cell (464 (5), 475 (2): one `.snap` reader, `botopink cell check`): `cell check`
      takes several paths and checks many cells in one process, an arena per cell; `--jobs N` hands the cells out in
      shares, a share whose process dies re-checked cell by cell; `conformance/run.sh` gives its pool the same shares.
      Every claim of today checked the same way — a refusal's message, `line:col` and label (485), output, `abort`,
      `stderr`, `no-final-newline`, both wasm hosts, every narrowing audit; 1085 cells before and after
- [x] a cell's program stays a process of its runtime (`node`, `erl`, `wasmtime`): the snapshot executors answer from
      a stored result (510 forbids it), merge stdout and stderr, and run one module rather than a cell's project —
      written in `conformance/AGENTS.md` § What runs in process
- [x] the language half of `test-cli` becomes cells (decision 457's shape): `backend_exec.sh`'s programs (numeric —
      `55` on the four targets —, records with enum / `case` / lambda, the multi-folder `mod` / `pub mod` package)
      and `mutual_recursion.sh`'s forward reference and `isEven` ↔ `isOdd`; `test_tooling.sh`'s semantics of
      `assert cond, "msg"` and of `try` in a `test` block as `test/` cells. The scripts keep what is the CLI's
      contract (`cli_contract.sh`, `test_tooling.sh`'s `--filter` / totals / `*.snap.new` listing,
      `result_store.sh`, `backend_exec.sh`'s `wasm --invoke main`); every assertion of today has a home — none lost
- [x] botopink-lang's `examples/` becomes cells (decisions 457, 461): `hello`, `stdlib-tour` (a `test/` suite),
      `modules` and `yamlconf` in `conformance/` (decision 466: no mirror, 467); the scripts pointed at the cells or a
      fixture of their own, no check lost — `tsc-check.sh` and `format-check` still check `generic-loader-binding`
      while it is here
- [x] `generic-loader-binding` (three `from "query"` forms — a library, not the language) moves to erika as a
      consumer commit (rule 10), then `examples/` deleted; its tests pass on the four targets
- [x] the per-target cells the B-00 group's audit left waiting on `snapshot/targets/` (B-00k): float text
      (`"${5.0}"`, `1.0e21`, `1.0e-7` — commonJS departs), `trim` keeping a NBSP, the final sigma (commonJS `ς`),
      `NaN` / `Infinity` (erlang and beam abort), and an unseeded `random.float()` reached from a decorator body
- [x] `test/` suites stay on the CLI (`botopink test --json`), the runner's `--self-test` unchanged; `modules/` projects
      are cells checked in process by `cell check`
#### B-29 step H Conformance (decisions 459, 474, 477, 478, 479, 480) — the step's last box group

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the step's other boxes have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the step landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the step's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the step's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the step changes, its runs on `feat` since
      the step's base, green or each red named
- [ ] what the move left: the decorator `random.float()` cell once B-46 lands; the reds B-43 and B-44 found
      (`generic-loader-binding` is erika's cell `conformance/modules/generic_loader_binding`)

| Behaviour (decision) | Test |
|---|---|
| `conformance/` in 457's shape | every cell, `cell check`; the codemod's audit |
| `cell new` / `cell check` (464), a manifest per cell (475 (1)), narrowings audited | `cli_contract.sh` § botopink cell |
| many cells in one process, in shares (464 (5), 475 (2)) | `cli_contract.sh` (same bytes for any `--jobs`), `cell.zig` unit tests |
| a share whose process dies is re-checked cell by cell | `cell.zig` unit test of its input only — a row |
| the language half of `test-cli` and `examples/` as cells | `tail_recursive_sum`, `record_enum_case_lambda`, `mutual_recursion_forward_reference`, `assert_message_aborts`, `test/assert_and_try.bp`, `hello`, `modules`, `yamlconf`, `yamlconf_unknown_label`, `test/stdlib-tour`; erika's `generic_loader_binding` |
| B-00k's per-target answers | `float_text_at_run_time`, `string_trim_keeps_nbsp`, `string_lower_final_sigma`, `float_nan_infinity_words`, `decorator_random_float_unseeded` |

#### Step I — the reference into `conformance/`; one gate for hook, CI and hand (decisions 461, 462, 466)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After step H (the cells in `conformance/`).

- [x] each of `docs.md`'s 141 botopink fences becomes a cell in `conformance/modules/` (or names an existing one):
      the 89 compiled-only and 13 `body` with their output, the 24 `project` as multi-module cells, the 15 `reject`
      with their refusal — red on the parent, green after
- [x] the reference written in `conformance/docs.md` (the index, the text no cell owns) and
      `conformance/modules/<cell>/docs.md` beside each cell (462); `docs.md`, `docs/` (the manifest schema) and the
      language part of `README.md` moved there — no copy left; `test-docs` checks that every reference names a cell
- [x] `scripts/gate.sh --no-conformance` (470): the commit hook's gate — every stage but the conformance cells;
      the GitHub pipeline runs `scripts/gate.sh` with them on `feat`, which a front's Conformance step reads (477);
      conformance runs locally only to reproduce a red
- [x] `.github/workflows/test.yml` calls `scripts/gate.sh` with conformance on a push to `feat` (477: a front's
      Conformance step reads that run), not its own list of stages
- [x] `AGENTS.md` (§ Conventions' "README.md and docs.md stay in sync", § Local gate) rewritten for `conformance/`

#### B-29 step I Conformance (decisions 459, 474, 477, 478, 479, 480) — the step's last box group

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the step's other boxes have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the step landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the step's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the step's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the step changes, its runs on `feat` since
      the step's base, green or each red named

| Behaviour (decision) | Test |
|---|---|
| each reference names a cell or a suite (461) | `check-docs.sh` and its self-test (`zig build test-docs`) |
| a cell the reference names has a `docs.md` quoting it (462) | `check-docs.sh`'s new rule and self-test case |
| `gate.sh --no-conformance` is the hook's gate; `test.yml` runs it with conformance (470, 477) | read from `runner-standalone.sh`; the pipeline (box 1) |

#### Step J — botopink-lang's gate drops the lock and takes a total of jobs (decisions 468, 469)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

After the step gate of decision 460 lands (both change `scripts/gate.sh`). The pool itself is the meta repository's
(163 s7); this gate knows nothing of it.

- [x] `scripts/gate.sh` takes one total of jobs (a leading argument; default the machine's, as step G computes) and
      splits it among its stages as today; the gate lock removed (`scripts/AGENTS.md` § Gate lock rewritten)
- [x] `--no-conformance` stays: the commit hook's gate (470, step I), never a verdict
- [x] a library's `test-out` written under a per-run directory and removed after (botopink-lang's `test-libs` writes
      into the linked siblings)

#### B-29 step J Conformance (decisions 459, 474, 477, 478, 479, 480) — the step's last box group

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the step's other boxes have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the step landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the step's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the step's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the step changes, its runs on `feat` since
      the step's base, green or each red named

| Behaviour (decision) | Test |
|---|---|
| one total of jobs, `--jobs <N>` positive (468, 469) | `cli_contract.sh` § the gate (`--jobs 0`, `--jobs=many`, a bare `--jobs`) |
| the total split among the stages | `pool_share` |
| no gate lock (508) | read from `gate.sh` |
| a library's `test-out` per run, removed after | `cli_contract.sh`, `test_tooling.sh`, `runner.zig` |

#### Step 3 — the windows row is hard or absent (decision 158) (was `114-gate-docs-and-ci` s3)

Row deleted until capture normalises CRLF/separators (known gap, `../../status.md`). To restore: run
the `test` job on windows, list failing snapshots by cause (CRLF in stdout; `\` in paths); if
normalisable in `modules/compiler-core/src/codegen/tests/helpers.zig` without touching an emitter,
do it and restore the row hard with every ubuntu stage (`erlef/setup-beam` supports windows).
- [ ] botopink-lang `test` workflow green on GitHub on `feat`, every row (fixes on feat: test-web
      wasm32, `test-libs.sh`/`run.sh` under macOS bash 3.2 / BSD `xargs`, `pool.sh` without GNU
      `timeout`, macOS `/private/var`). Last run on `94a9c3ef` (2026-10-09): both `test` rows green;
      job `libs` red on one cell, `std·commonJS` — five `fs.glob` tests (`libs/std/src/io/fs.bp:382`,
      `:387`, `:398`, `:411`, `:426`): the commonJS body matches a segment with `fs.globSync`
      (Node 22+) and both jobs installed Node 20, where it throws and the walk answers `[]`. Fix in
      `test.yml`: both Node installs at 22, the floor std's bodies name
- [ ] (only with a windows runner) drift measured, capture normalised, row restored hard — else row
      stays deleted, gap carried

#### Step 7 — a cold gate recorded on the current tip (was `114-gate-docs-and-ci` s7)

No cold verdict on any tree containing `gate-integration-7…14`; no ~7m30s cold run recorded (133's
last full cold: 9m31s, loaded). A time measurement: it runs in 163 s9, the measurements at the end of the
conformance order (fronts.md § Execution order), on a quiet machine — no step before it spends time measuring.
- [ ] `scripts/gate.sh --cold` green on botopink-lang `feat`, every sibling library at its `feat`
      tip; record tip, each stage's count vs `--list` plan, wall clock, CPU-s, machine load
- [ ] wall clock ≤ 450 s on 16 cores, or the over-budget line recorded as printed (yellow — decision 265)
- [ ] `../README.md` § Exit check counts updated to this run's output

#### Step 8 — the gate's other residue — part (was `114-gate-docs-and-ci` s8 box 1)

- [x] (moot: `check-docs.sh` now only checks that each `<!-- example: … -->` names a cell; the claim is gone) `scripts/check-docs.sh`'s header says `check` is target-independent (`:63`, `:76`): it is not
      since decision 167 — `#[@BeamMemory…]` checks under an erlang manifest and is refused under the
      harness's `commonJS` one, so `docs.md` § `@BeamMemory` is a `project` fence with an erlang
      `botopink.json` (from `07` step 6); the comment says the manifest's target is read

#### Step 1 — the CI matrix (the maintainer's, after the push) (was `18-comptime-runtimes` s1)

`test.yml` jobs: `../../00-gate/README.md` § Rules 5, 13 (decisions 231, 158); `release.yml`'s `zig
build -Doptimize=ReleaseSafe -Dtarget=${{ matrix.zigtarget }}` on its five rows.

- [ ] every row green on the CI after the milestone's first push; a red row is a step of this front
      (runner-specific fix in `build.zig` or a workflow), never a skipped row

#### Step 1 — `--cold` with the pre-existing tool set (box 2) (was `12-language-tests` s1)

Suite half holds: `env -i HOME=… LANG=C.UTF-8 PATH=/usr/bin:/bin:<wasmtime>` runs four targets green
(node, erl, erlc, wasmtime — no zig), stated in `AGENTS.md` § The targets.

- [ ] `scripts/gate.sh --cold` green on a runner with the pre-existing tool set (the landing run)

#### Step 1 — wave A: the codegen reports (3.1, 3.2, 3.4, 3.5, and 3.3's `:70`) (was `07-residuals` s1)

A column re-derived once its backend front landed (multi-column rows: after the last). Non-`ok` row:
re-derive at HEAD (decisions turn `uncertain` into verdicts), then fix the test (`wrong-test`,
`weak`, `duplicate`, `skip-undocumented`) or register the `wrong-output`. Tests named *"lowers
byte-identically across backends"* hold or take decision 1's name.

**Acceptance (per report):**
- [ ] every non-`ok` row re-derived at HEAD and closed: fixed, registered (snapshot name, owning front's README) or struck with a reason
- [ ] the two stale beam `null` rows struck (`codegen-control_flow.md:196`, the `{atom,nil}` half of `codegen-features.md:211`)
- [ ] status line appended to the report: columns covered, re-derivation date
- [ ] `scripts/snap_audit.sh --mode=review` after the batch: every struck row `ok` or absent from seeded verdicts

#### Step 2 — wave B: the comptime reports (3.7–3.10) (was `07-residuals` s2)

After `01-checker`. Snapshots render inferred types: "JSON does not show the type" `weak` rows
gradeable. Batches landing in `comptime/infer.zig` conflict: one worker, one batch at a time.

**Acceptance:** as step 1, per report, plus:
- [ ] no `src/comptime/tests/**` rename breaks a `comptime/errors/` pair (identical pair = `duplicate` row; dedup = rename)

#### Step 4 — three mis-named tests (was `07-residuals` s4)

`src/codegen/tests/externals.zig:55`, `:67` named for an unimplemented equivalence (`template
equivalent to @external(target, template)`, `mixed with @external() in one decl`); both bodies use
only `#[@External.Erlang(…), @External.JavaScript(…)]`. `src/comptime/tests/infer_decls.zig:147` `"infer:
implement block is invisible to the binding list"` names a gone behaviour (`implement` blocks
appear, read from `OkData.transformed.decls`).

A fourth, found by step 5: `src/codegen/tests/wat.zig`'s `"wat: print ---- a record and a
variant have no printed form yet, so they trap"` — all four backends print §7's text now.

- [x] the three tests (and the fourth, `wat.zig`'s) named for what they assert; snapshots (codegen: one per target per runtime tree; comptime: one) `git mv`ed in the same commit, byte-identical
- [x] `scripts/snap_audit.sh --mode=orphans` after the rename: 0 orphans, 0 unrecorded

#### Step 8 — the lib-agnostic gate names every library (handed by `08-bpp`) (was `07-residuals` s8)

`build.zig`'s lib-agnostic gate greps `modules/compiler-core/src` for `rakun|jhonstart|erika` only;
`onze`, `emilia` occur in compiler-core comments (`codegen/erlang.zig`, `grep -n 'onze\|emilia'` —
02's file). Reword after 02 lands, then widen the pattern (`build.zig` is `26-cli-tooling`'s —
one-line carve-out named in the commit).

- [ ] `grep -riIwE 'rakun|jhonstart|erika|onze|emilia' modules/compiler-core/src` empty; gate pattern names all five

Measured 2026-10-08: the two test-file sites (`codegen/tests/control_flow.zig`, `dispatch.zig`)
reworded; the rest sits in files this front does not own — `ast.zig`, `comptime.zig`,
`module.zig`, `codegen/{erlang,commonJS,beam_asm}.zig`, `codegen/AGENTS.md`,
`codegen/js/AGENTS.md`, `comptime/{env,infer,transform}.zig`, `comptime/AGENTS.md`, `format.zig`,
`format/AGENTS.md`, `format/tests/{comments,declarations}.zig` — each a comment edit after its owner
lands. The pattern needs `-w`: without it `onze` matches `nonzero` (`commonJS.zig`'s
`isNonzeroLiteral`, test sources), so the gate would red on code.

#### Step 9 — decision 8 §5.1's `->` arms (C-14) (was `07-residuals` s9)

`pattern -> value;` arms remain in emilia, jhonstart, rakun (erika none); `test/case_arrow_arms.bp`
is the transition guard beside `test/case_arms.bp`. Needs the maintainer's word before any rewrite;
each track rewrites its own tree.

- [ ] maintainer's answer recorded; if removed, §5.1 arms rewritten in emilia, jhonstart, rakun by the tracks, cells green; `docs.md` § Case re-measured for both forms

#### B-29 (rest) Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-00i — The Erlang term library and the OTP functions in std-wasm (decision 450)

After B-00g, before B-30 (whose collection needs the terms' layout). `comptime/runtime/wat/rt.zig` (the term
representation and the OTP functions and BIFs it serves) moves into `modules/std-wasm`; one wasm runtime remains.

- [x] `modules/std-wasm/src/term.zig` (atoms, tuples, lists, maps, binaries) and `otp/*.zig` (`lists`, `maps`,
      `string`, `erlang:` BIFs) hold what `rt.zig` holds, with Zig unit tests; `rt.zig` deleted
- [x] allocation is the caller's (450 (5)): the comptime's arena when the comptime calls a term function, the
      current process's heap in translated code
- [x] the comptime runtime links `std_wasm.wasm`; `bp_wat_rt.wasm` and its `build.zig` step gone (the compiler-web
      build too); every `COMPTIME REPLY` byte-identical
- [x] beam-to-wasm imports std-wasm's OTP table (no caller-passed table); it still imports std-wasm alone (438)
- [x] one face per function: `string:titlecase` and any other function with a face in both deleted from one side
- [x] `modules/std-wasm/AGENTS.md` names its two value representations (the codegen's typed layout, the Erlang
      terms), each in its own file; `comptime/runtime/wat/AGENTS.md` and `modules/beam-to-wasm/AGENTS.md` updated

**Impacted tests:** `comptime` tests (every `COMPTIME REPLY`), `modules/std-wasm` and `modules/beam-to-wasm` unit
tests, `test-web`, decorator/template/comptime cells of `tests/language`. **Model:** opus. **Consumer commits:** none.

### B-00j — The comptime stops calling beam-to-wasm (decision 452); the name `std` reserved (453)

After B-00g. beam-to-wasm stays a standalone utility that knows only std-wasm; nothing in botopink calls it.

- [x] a host function reached at build answers by its `std:` cell, else its `@External.Wasm("fn:…")` cell; none →
      `comptime-host-cell-unavailable` naming both; an `@External.Erlang` cell never runs at build
- [x] `comptime/runtime/wat/cells.zig` and `host_cells.zig`'s `erlangCellOf` / `callingCell` deleted; compiler-core
      imports nothing of `modules/beam-to-wasm` (`build.zig` wires it to its own tests only)
- [x] `reject/comptime_beam_call_not_converted*` become `comptime-host-cell-unavailable` cells (renamed, their
      `.expect` re-read); `comptime-beam-call-not-converted` leaves `diagnostics.zig`
- [x] `docs.md` (§ host functions at compile time), `comptime/AGENTS.md`, `comptime/runtime/wat/AGENTS.md` and
      `modules/beam-to-wasm/AGENTS.md` say beam-to-wasm is standalone and unused by botopink; every `COMPTIME REPLY`
      unchanged
- [x] a package named `std` that is not the bundled `libs/std` refused at its manifest (453) — a CLI contract case
      and an LSP diagnostic; the bundled std still builds as itself
- [x] `str_slice` and `mem_eq` deleted from `wat_prelude` (455); `codegen/wat/AGENTS.md`'s staying list without them
- [x] `random.float()` bound by `std:random.float` (456): the host's entropy in a wasm program, 451's refusal at
      comptime — the unseeded `float()` cell refuses with it, never `comptime-host-cell-unavailable`

**Impacted tests:** `comptime` host-cell tests, `tests/language` reject and decorator cells, `test-docs`.
**Model:** sonnet (452 fixes the design). **Consumer commits:** none.

### B-00k — Conformance: the B-00 group's last step (decisions 458, 459)

After B-00i. The B-00 group changed what the language answers on wasm and at comptime: one comptime runtime (434),
std-wasm's text on wasm (441: `5.0`, `1.0e21`, a NBSP kept by `trim`), Unicode case mapping (443: `É`, `STRASSE`,
the final sigma), `NaN` / `Infinity` words (444), refusals (`std:` outside std 445, the package name `std` 453, an
unseeded draw at build 451 / 456, an Erlang cell never run at build 452, `@External.Beam` 437), a stack overflow that
traps (447).

- [x] the whole `tests/language` suite green on every target it declares; no cell edited to match the compiler
- [x] the table of the group's behaviour changes (the list above, measured) against the cells that cover each, in
      this README
- [x] the cells each uncovered behaviour calls for, in decision 457's shape, red on the group's base (before
      B-00a) and green on its tip
- [x] the missing cells found beyond the group's change proposed as rows

| Behaviour (decision) | Cells |
|---|---|
| one comptime runtime, one answer on every target (434 (5)) | `run/comptime_text_one_answer`, `run/comptime_random_seeded`, `run/decorator_host_cells`, `run/comptime_std_host_function` |
| std-wasm's text in a wasm program (441), `trim` keeping a NBSP | at comptime `run/comptime_text_one_answer`; at run time pinned only in `codegen/tests/wat.zig` — a per-target answer waits on step H's `snapshot/targets/` |
| Unicode case mapping, OTP's answer (443) | `run/string_case_unicode`, `run/comptime_text_one_answer` (the final sigma at comptime) |
| `NaN` / `Infinity` words on wasm (444) | `codegen/tests/wat.zig` only — waits on step H |
| `std:` outside std refused (445) | `reject/external_wasm_std_outside_std` |
| the package name `std` reserved (453) | `modules/package_named_std` |
| an unseeded draw at build refused (451, 456); a seeded one the same every build | `reject/comptime_random_unseeded`, `reject/comptime_random_float_unseeded`, `run/comptime_random_seeded` |
| an `@External.Erlang` cell never run at build (452) | `run/comptime_erlang_cell_never_runs_at_build`, `reject/comptime_expression_erlang_cell_never_runs`, `reject/comptime_host_cell_unavailable{,_erlang_only}` |
| `@External.Beam` refused (437) | `reject/external_beam_removed` |
| a std-wasm frame past the stack's end traps (447) | not reachable from botopink code; `codegen/tests/wat.zig` |

`run/comptime_erlang_cell_ignored_fn_serves` cannot tell its Erlang cell from its `fn:` body (green on the group's base
too); `run/comptime_erlang_cell_never_runs_at_build` is the cell that does.

**Model:** opus. **Consumer commits:** none.

### B-31 — a template whose only part is a float hole is a string on wasm (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a backend bug with a measured repro)

Found by B-00k, present before the B-00 group: on wasm `val s = "${5.0}"; @print(s + "!")` emits invalid wasm
(`type mismatch: expected f64, found i32`) and `val xs: string[] = ["${2.5}", "a"]` is refused ("cannot place a float
in this array"); erlang and commonJS answer `5.0!` / the array. 441's `"${5.0}"` works on wasm only passed straight to
`@print`.

- [x] a template is a `string` on wasm whatever its parts — a single float hole included
- [x] `run/interpolation_single_float_hole`: a `val`, an array element and a concatenation, four targets, red on the
      parent on wasm, green after (458)

#### B-31 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

| Behaviour (decision) | Cells |
|---|---|
| a template is a `string` on wasm whatever its parts, a lone float hole included (430) | `interpolation_single_float_hole` |


### B-32 — structural equality at build is iterative; an arithmetic error at build reads as Erlang's (decisions 471, 472)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (both decisions fix the design)

Found by B-00k: `comptime same(2000000)` traps (a stack overflow) on every target; a float division by zero at
build prints the raw `{error,badarith}`.

- [x] std-wasm's term equality and term order walk an explicit work list, no recursion (471): `comptime same(2000000)`
      answers `true` on the four targets — `run/comptime_deep_structure_equality`, red on the parent, green after
- [x] a `badarith` at build is `comptime-badarith: an error occurred when evaluating an arithmetic expression — <the
      expression> (division by zero)` at the expression's `line:column` (472) —
      `reject/comptime_float_division_by_zero`, red on the parent, green after
- [x] every `COMPTIME REPLY` otherwise unchanged

#### B-32 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [x] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

| Behaviour (decision) | Cells |
|---|---|
| structural equality at build is iterative (471) | `comptime_deep_structure_equality`; term order in std-wasm's `term.zig` tests |
| a float or integer division by zero at build is `comptime-badarith … (division by zero)`, located (472) | `comptime_float_division_by_zero`, `comptime_integer_division_by_zero` |
| `%` by zero and a nested division name no cause | none — question B-32-a |


### B-33 — `@External.Wasm`'s cells as labelled arguments (decision 481)

**Repository:** botopink-lang, and every library with an `@External.Wasm` cell (a full worktree) · **Model:** opus (a
codemod tied to a new rule)

Today std writes the cells as prefixed strings (50 `"fn:…"`, 28 `"std:…"`, 6 `"op:…"`); 305 already made them labels.

- [x] the checker reads `fn: <identifier>` (resolved, typed), `op: "<opcode>"`, `wasi: .<Adapter>`, `std: "<module>.<fn>"`
      (checked against std-wasm's `exports` and the declaration's types); a prefixed string refused, located, naming
      the labelled form — `reject/` cells for each
- [x] a codemod rewrites every cell in std and the libraries; every `.out`, RUN LOG and snapshot otherwise unchanged
- [x] `docs.md` and the `AGENTS.md` files name only the labelled forms
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | each prefixed string refused, naming the labelled form (481) | `external_wasm_prefixed_fn_refused`, `_op_refused`, `_wasi_refused`, `_std_refused`, `external_node_prefixed_op_refused` |
  | `fn:` resolved in the module and type-checked | `external_fn_unbound`, `external_wasm_op_and_fn`, `external_fn_body_every_target`, `external_wasm_fn_cell_signature` |
  | a value of the wrong kind, a label outside the four, a second cell, an unknown opcode or adapter | `external_wasm_fn_cell_string`, `external_wasm_op_cell_not_string`, `external_wasm_wasi_cell_not_enum`, `external_wasm_std_cell_not_string`, `external_wasm_unknown_label`, `external_wasm_two_cells`, `external_wasm_op_unknown`, `external_wasm_wasi_unknown` |
  | opcode and adapter signatures; `std:` outside std refused | `external_wasm_op_type_on_every_target`, `external_wasm_adapter_signature_on_every_target`, `external_wasm_task_adapter_shape`, `external_std_binding_refused`, `external_wasm_std_outside_std` |

### B-34 — the BEAM assembler rejects `styled`'s module (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a backend bug with a measured repro)

Found moving jhonstart's examples into its `conformance/` (463): every jhonstart cell is refused on beam with
`the OTP compiler refused the emitted program — nothing to run`; the BEAM assembler rejects the `styled` module
(`make_fun3 … {unassigned,{y,3}}`). commonJS and erlang answer.

- [x] the beam emitter assigns the register `make_fun3` reads; `styled` assembles; jhonstart's 18 `conformance/` cells
      green on beam — red on the parent, green after
- [x] the cheap test the hook runs that would have caught it (a beam export-audit or codegen snapshot case, 478)
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a closure's free-name walk binds an `if` binding in its then-branch only; beam assembles (430) | `component_loop_await_accumulates`, `if_binding_before_loop_closure` |

### B-35 — `@println` has no wasm lowering (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a backend gap with a measured repro)

Found moving erika's examples into its `conformance/` (463): `the wasm backend has no lowering for the builtin
`@println``. Its two cells answer on commonJS, erlang and beam.

- [x] `@println` lowered on wasm as `@print` is, with its newline; erika's `conformance/` cells green on wasm — red on
      the parent, green after; a codegen snapshot case (478)
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | `@println` lowered on wasm as `@print`, its line ended (430) | `println_every_target` |

### B-36 — styled's hook red on `feat`: "tab4's class is not a constant of the emitted module" (structural, decision 430)

**Repository:** rakun (150's styled section) · **Model:** opus

The cause was styled's: its `repository-stages.sh` read the calls in 354 (8)'s form, a hidden context map first
(`undefined` / `null`, `BpContextMap__`); decision 388 made a component a lambda over its `RenderScope` and dropped that
argument. The compiler's output is the intended one, so no compiler-core test can catch it.

- [x] the cause found and fixed where it lives: styled's stage reads the class and the rules as the calls' literals, no
      hidden argument; styled's hook green
- [x] the cheap test (478): none in botopink-lang — the check that catches a lowering change reaching every library is
      the libraries' own stages run against the compiler change, which is 163 s7's `scripts/gate.sh libs`

### B-37 — dependencies from `.botopinkbuild/deps/` first; `bpmp link` (decision 483)

**Repository:** botopink-lang (`--lang`) · **Model:** opus (it changes the library resolution of 143)

- [x] `libs.zig`: a `git` dependency resolves first from `<project>/.botopinkbuild/deps/<name>/`, then the walk-up as a
      fallback; `BOTOPINK_LIB_ROOTS` first when set; the language server the same (`manifest.findCacheRoot` / roots)
- [x] `bpmp link [<checkout>]`: `.botopinkbuild/deps/<name>` → `<checkout>/repository/<name>` for each dependency of
      every manifest of the project (a workspace's members included); a missing local repository named, never guessed
- [x] tests: a project with only `.botopinkbuild/deps/` links resolves; a link wins over the walk-up; CLI contract cases
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a `git` dependency from `.botopinkbuild/deps/` first, `BOTOPINK_LIB_ROOTS` first, the walk-up as fallback; `bpmp link` (483) | `cli_contract.sh`, `project_graph` and manifest tests — a cell names `path` dependencies only |

### B-38 — `botopink cell check`: a full run that drops a cell; a `path` dependency inside a cell (found moving rakun's reference)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

- [x] (a worker that leaves no verdict is a FAIL; the drop was not reproduced — the pipeline's runs confirm every cell
      is reported) `botopink cell check conformance/` over rakun's 35 cells reported 34 in two runs of three, a different cell
      missing each time (each passes alone): every cell found is reported, a cell that cannot run is a red naming it,
      never absent; a CLI test with a directory of cells counts them
- [x] a cell's `{"path": "…"}` dependency relative to the cell fails, because the cell runs from a scratch copy: the
      check resolves it against the cell's own directory (or, after B-37, the cell's `.botopinkbuild/deps/`), so a
      library's cells drop their per-cell `deps/` workspaces of symlinks; the scratch copy (which skips hidden
      directories today) inherits the project's dependency tiers, `.botopinkbuild/deps/` included
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | every cell found is reported; a cell with no verdict is a red naming it | `cli_contract.sh` |
  | a cell's `path` dependency resolves against its own directory | `local_dependency`, `decorator_same`, the 69 cells with `deps/…` |

### B-39 — a module-level `val` read by the next one is unbound on erlang (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`val a = X(); val b = f(a.m())` at module level emits an erlang module that refers to `a` unbound; the OTP compiler
refuses it (found in rakun's `constraint` cell, which registers inside `main` instead).

- [x] a cell red on the parent: two module-level `val`s, the second reading the first, on every target
- [x] the erlang emission binds the first before the second reads it; the cell green on every target
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a module-level `val` read by the next one is bound, `_`-prefixed names included (430) | `module_val_reads_module_val`, `val_runs_at_module_load`, `module_init_order` |

### B-40 — a cell's targets are its `botopink.json`'s `"targets"`, never a `targets` file (decision 475 (1))

**Repository:** botopink-lang, then jhonstart and rakun (a full worktree) · **Model:** sonnet

`botopink cell check` / `cell new` read and write `<cell>/targets`; decision 475 (1) puts a cell's narrowing in its own
manifest, as any project's.

- [x] `cell.zig` reads the cell's `botopink.json` `"targets"` through the manifest module (absent → every target);
      the refusals kept (an unknown target, one named twice, an empty list, a list naming every target narrows nothing)
- [x] a `<cell>/targets` file is refused, located, naming the move into `botopink.json` (67) — no fallback reading it
- [x] `botopink cell new` writes the narrowing into the manifest; CLI tests and `cli_contract.sh` rows red on the parent
- [x] `conformance/docs.md`, `AGENTS.md` and `docs.md` name the manifest field, not the file
- [x] jhonstart's 18 and rakun's 35 cells moved: the file's targets into `botopink.json`, the file deleted; each
      library's hook green
- [x] emilia's 79 cells declare beam too: beam builds them, so leaving it out fails the audit (475 (1))
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a cell's targets are its manifest's `"targets"`, with its refusals (475 (1)) | the 43 narrowed cells |
  | a `targets` file refused; `cell new` writes the manifest | `cli_contract.sh` |

### B-41 — a library's abort reads the same on every target (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

emilia's `theme-unknown-namespace` cell aborts with `emilia theme: '--gutter' is in no known namespace` on commonJS;
erlang and beam word the same abort differently, so the cell cannot claim its `stderr` in `output/` (458: no departure
for a defect).

- [x] the abort's text measured on each target; the library's message reaches stderr unchanged on every target (the
      runtime's frame around it the same, or none); the cell's `stderr` claim in `output/`, green on every target
- [x] a compiler-core test red on the parent (a `@panic` with a library's message, every backend)
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a library's `@panic` message reaches stderr unchanged on every target (430) | `panic_library_message` |
  | every abort writes stderr only | the `int_overflow_*` cells |
  | a non-panic run-time abort on erlang and beam reads `Class:Reason` | none — question B-41-a |

### B-42 — wasm: a cell with a `path` dependency prints nothing; emilia's `arbitrary.bp` does not build (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

Found moving emilia's reference (79 cells): on wasm, any cell with a `path` dependency prints nothing, a bare
`@print("hello")` included; emilia's `arbitrary.bp` does not build on wasm (`join/1` does not resolve).

- [x] a cell red on the parent for each: a `path` dependency and a `@print` on wasm; a module calling `join` from a
      dependency on wasm
- [x] both fixed; emilia's 79 cells green on wasm, or each refused on a host binding it lacks (a departure, 475)
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a `fold` lambda's string accumulator chains `split` / `join` on wasm (430) | `fold_split_join_lambda` |
  | a program with a `path` dependency prints on wasm, the dependency's module linked whole (430) | `dependency_prints_with_fold_join` |
  | a dependency function wasm cannot lower and the program never calls | none — question B-42-a |

### B-43 — a `Set` of structurally equal records keeps one on every target (decision 210)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`stdlib-tour`'s Set test keeps 3 members on commonJS where two are structurally equal (2 on erlang); the same on wasm.

- [x] a cell red on the parent: a `Set` of records, two structurally equal, its size on every target
- [x] commonJS and wasm compare members structurally (210); the cell and `test/stdlib-tour` green on every target
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | `Set` membership is `==`: structurally equal records are one member on every target (210) | `set_record_dedup`, `test/stdlib-tour` |

### B-44 — wasm prints a lifted `bool` as `1` (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

The `yamlconf` cell prints `1` on wasm where every other target prints `true`.

- [x] a cell red on the parent: a `bool` that crosses a host value printed on wasm
- [x] wasm prints `true` / `false`; `yamlconf` green on wasm
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | wasm prints a lifted `bool` as `true` / `false` (430) | `global_tuple_bool_field`, `yamlconf` |

### B-45 — erlang: `lib.member()` through a library's default handle is unbound (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`erika.of(…)` in the `generic-loader-binding` example fails on erlang: `variable 'Erika' is unbound`; it blocks the
example's move into erika's `conformance/`.

- [x] a cell red on the parent: a local `path` library whose default handle's member is called, on every target
- [x] the erlang lowering binds the handle (`default_handle_member` green on erlang; beam is B-50)
- [ ] `examples/generic-loader-binding` moves into `erika/conformance/` as a cell on every target (an erika change, after the 144 front)
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | `lib.member()` through a library's default handle reaches its module (430) | `default_handle_member` |

### B-46 — a decorator body reaches a nested std namespace (`io.random`) (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** opus (the comptime's module environment)

A decorator body calling `random.float()` fails at build: `unbound variable '__bp_ns_io_random'`; the B-00k cell of
`random.float` at build cannot be written.

- [x] a cell red on the parent: a decorator body calling a function of a nested std namespace
- [x] the comptime's environment holds the nested namespaces; the `random.float()` cell written (refused unseeded at
      build, decision 447, or the seeded answer)
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a decorator body reaches a nested std namespace (430) | `decorator_nested_std_namespace` |
  | `random.float()` in a decorator body refused unseeded at build (447, 451 (3), 456) | `decorator_random_float_unseeded` |

### B-47 — a refusal cell claims the label under the caret (decision 485)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

- [x] the `.snap` format reads and writes `label <text>` after `at` in a refusal file (refused elsewhere, located);
      `cell check` compares it and `cell new` writes it when the compiler prints a label beside the caret
- [x] CLI tests red on the parent: a label that changes, a label that disappears, a `label` record in an output file
- [x] `case_bare_name_arm`, `case_constant_pattern`, `reserved_word_field_name` and `reserved_word_param_name` claim
      their whole refusal and label, green; every other refusal cell whose caret carries a label gains its record
- [x] `conformance/docs.md` states the record (with B-29 step I, which writes that file; `conformance/AGENTS.md` states it today)
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the reference states each re-recorded refusal's rule; boxes 1, 2 and 5: § The pipeline state; boxes 1, 2 and 5 read `feat`'s pipeline (question B-29-a)
  | Behaviour (decision) | Cells |
  |---|---|
  | a refusal `.snap` claims `label <text>` after its `at` (485) | the 82 refusal cells the step re-recorded; `cell_snap.zig` unit tests |
  | a misplaced, repeated or output-file `label` record is malformed (485) | `cell_snap.zig` unit tests only |
  | four cells claim their whole refusal and label | `case_bare_name_arm`, `case_constant_pattern`, `reserved_word_field_name`, `reserved_word_param_name` |

### B-48 — a raise inside a decorator body is located at the raising call (decision 451 (3))

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`decorator_random_float_unseeded` is refused at the annotation that runs the decorator (`#[drawn]`), and
`comptime_random_float_unseeded` at the `comptime` expression; 451 (3) locates the refusal at the call.

- [x] both cells claim the location of the raising call (`io.random.float()`), red on the parent
- [x] a raise inside a decorator or comptime body is located at the call that raised, the annotation or the
      `comptime` expression named as the frame that ran it

The step's current scope: the location travels with the raise, and only this module's calls are located — an
imported helper's raise lands on the local call, an imported decorator's raise at the annotation, and a template
expansion's calls are not located.

- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a raise in a decorator body located at the call that raised (451 (3)) | `decorator_random_float_unseeded` |
  | the innermost call of this module wins (a helper the body calls) | `decorator_helper_raise_located` |
  | a raise in a `comptime` located at the call | `comptime_random_float_unseeded`, `typeinfo_all_duplicate_at_entry` |
  | a hole known at build that raises refused at the call (355, 451 (3)) | `hole_known_at_build_raises` |
  | an imported helper's or an imported decorator's raise | `decorator_raise_names_body_file`; the answer — question B-48-a |
  | a template expansion's calls are not located | none — a row |

### B-51 — commonJS prints an `f64` without its `.0` (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`math.abs(0.0 - 1.0)` prints `1` (`import_module_paths`) and an `f64` out of a `case` prints `2` (`enum_declaration`) on
commonJS; the same backend prints `1024.0` elsewhere, and every other target `1.0` / `2.0`.

- [x] the two cells green on commonJS; an `f64` reaching `@print` through a std call or a `case` keeps its `.0`
- [x] a codegen test the hook runs, red on the parent
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | commonJS keeps an `f64`'s `.0` through a module-handle call or a `case` payload (430) | `import_module_paths`, `enum_declaration`; a codegen test |

### B-52 — wasm prints a string field or an awaited string as a number (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`generic_fn_and_type` prints `Tree.Leaf(value: 280)` for a generic record's string field; `async_block_both` prints
`2922` for `ana2`; `task_result_await` prints `Hello, 292` for `Hello, ana`.

- [x] the three cells green on wasm: a string reaching a generic field or crossing an `await` prints as text
- [x] a codegen test the hook runs, red on the parent
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | wasm prints a string in a generic field or out of an `await` as text (430) | `generic_fn_and_type`, `async_block_both`, `task_result_await`; a codegen test |

### B-53 — `@print` of a `@Result` prints the host's form (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`@print(Ok(81))` prints `{ ok: 81 }` on commonJS, `{ok,81}` on erlang and a number on wasm; the reference says a value
prints the way the source writes it.

- [x] a cell red on the parent: `@print` of `Ok(…)` and `Error(…)` on every target, the source's form
- [x] every backend prints a `@Result` as `Ok(81)` / `Error(…)`
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | `@print` of a `@Result` writes `Ok(…)` / `Error(…)` on every target (430) | `print_result` |
  | a template hole writes `@print`'s text for every value | none — question B-53-a |

### B-54 — `botopink format` rewrites an annotation's labelled argument `keyed: true` to `keyed = true`

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`#[@BeamMemory.Ets(keyed: true)]` comes back from the formatter as `keyed = true`; the reference and 305 write the
labelled form.

- [x] the formatter keeps an annotation's labelled arguments as written (`label: value`); a format test red on the parent
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | the formatter keeps an annotation's `label: value` (305) | a format test (a cell checks answers, not layout) |

### B-77 — `botopink cache`: one place for the caches, parallelism by the machine's pool, no `--cold` / `--jobs` (the maintainer, 2026-10-12)

**Repository:** botopink-lang (`--lang`) and every library (the runner) · **Model:** sonnet · **After:** B-60

botopink knows cells and workspaces only — never a conformance suite, a hook or a CI; what to run and when is its
callers' (`scripts/gate.sh`, CI). Its build infrastructure gets a section of its own, `botopink cache`, and the flags
that exposed it go.

- [ ] **one place:** level A moves from 225's cache root to `.botopinkbuild/build/` beside level B's
      `.botopinkbuild/analysis/` (B-60), at the workspace's root
- [ ] **parallelism is botopink's:** `cell check` (and `test`, B-64) takes jobs from the machine's pool — the fixed
      directory and formula of 468 / 473, moved from `scripts/gate.sh` into botopink — and reports in the units'
      order; `--jobs` goes (no configuration, 67)
- [ ] **`--cold` goes** from `build`, `run`, `test` and `cell check`; `test-analysis-equivalence` uses the compiler's
      internal API
- [ ] **`botopink cache`**, its own section: `botopink cache clean` (empties `.botopinkbuild/build/` and
      `.botopinkbuild/analysis/`), `botopink cache status` (what each level holds and the machine pool's
      occupancy — what a measurement waits on); `botopink --help` lists it apart from the language's commands
- [ ] **the scripts keep only the hook's flags:** botopink-lang's and the meta's `scripts/gate.sh` and the 17
      libraries' runner lose their cache logic (`--cold`, deleting `runtime-cache` and the libraries' caches) and the
      pool; `--staged` and `--no-conformance` stay (`gate.sh` alone decides whether `botopink cell check
      conformance/` runs); the three runner files stay byte-identical (CI check 4)
- [ ] the worktree rule 4b (no `--cold` in a `--repo` / `--lang` worktree) and its line in `scripts/thread-rules.md`
      removed, and `AGENTS.md` updated (meta, compiler-cli)
- [ ] a test in `test-cli`: no string `"conformance"` in the CLI's code (comments aside)
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-78 — commonJS writes an `f64` as text with its decimal part: a template hole, `.toString()`, `string + f64`

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

commonJS wrote an `f64` in text as the JS engine does (`5`, `1e21`); erlang, beam, wasm and commonJS's own `@print`
(since B-51) write `5.0`, `1.0e21`. The change shares `@print`'s helper. It contradicts decision 441's last sentence
("commonJS keeps the JS engine's text; whether it adopts std-wasm's is a later question") and **waits on question
B-78-a** (`decisions-pending.md`): if the answer is to keep the engine's text, the change is reverted.

- [x] a template hole, `.toString()` and `string + f64` write the `f64` with its decimal part (`5.0`, `1.0e21`) through
      `@print`'s helper; the cell `float_text_everywhere`
- [x] a float commonJS cannot type (an imported record's `f64` field, a generic method's answer) keeps its `.0` (521)
- [x] Conformance step (459, 474, 477, 478, 480) — a string method through `?.` answers std-wasm's text (cell
      `optional_chain_string_text`); an `f64` inside a generic body is B-114

### B-79 — `botopink run` of a program with no `fn main`: one located error on every target and host (decision 517)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

Measured (2026-10-12), `botopink run` of a package whose entry module declares no `fn main`: wasm on wasi (wasmtime)
answered `no exported instance named wasi:cli/run`, wasm on the browser host (node) and commonJS exited 0 running
nothing, erlang and beam failed with a raw `error:undef`. Decision 517: the CLI refuses before running, located at the
package's entry module, naming that it declares no `fn main` — the same message on commonJS, erlang, beam and wasm
under both hosts. The two `conformance/test/` suites that showed it (`module_var_self_registration_test`,
`stdlib-tour`) are `botopink test` suites, not cells; `botopink test` does not run on wasm, and a cell sweep does not
check `conformance/test/`.

- [x] measured: the five answers above
- [x] the refusal in `run.zig` (and the wat component emitter where a module without `main` exports no
      `wasi:cli/run`), one message on every target and host; a unit test the hook runs (478)
- [x] a cell: a package with no `fn main` refused by `run` on every target
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | `run` of a package with no `fn main` refused at the entry module, one message on every target and both wasm hosts (517) | `run_without_main`; a `run.zig` unit test |

### B-80 — onze-cli's CSS accessors test red under `test-libs` on commonJS and erlang

**Repository:** botopink-lang (`--lang`), or onze when the cause is the library's · **Model:** sonnet

Found landing B-24 (2026-10-12): `zig build test-libs` fails onze-cli's test at `test/build_test.bp:140` (the CSS
accessors) on commonJS and erlang, the same with `libs/std` at `feat`'s — older than B-24. The cause is found first:
a compiler defect is fixed here; a library's is a row of 150's onze section and this step closes pointing at it.

- [x] the cause found (compiler or library), named in this box — the library's: the test creates its app with
      `create styled`, so the app package is named `styled`, and jhonstart depends on the `styled` library
      (`jhonstart/modules/jhonstart/botopink.json`); the build refuses two packages named `styled` in one workspace,
      on every target. The compiler is right
- [x] fixed where it belongs — handed to 150's onze section as its former 162 s11 (the test's app renamed); `test-libs` green for
      onze-cli is that step's box
- [x] Conformance step — none: the fix is not the compiler's

### B-81 — rakun-data's `#[query]` test red under `test-libs` on erlang

**Repository:** botopink-lang (`--lang`), or rakun when the cause is the library's · **Model:** sonnet

Found landing B-24 (2026-10-12): `zig build test-libs` fails rakun-data's test at `test/sql_build_test.bp:148` (the
`#[query]` decorator) on erlang, the same with `libs/std` at `feat`'s — older than B-24. The cause is found first: a
compiler defect is fixed here; a library's is a row of rakun's front (150) and this step closes pointing at it.

- [x] the cause found: the library's. `rakun-data/src/sql/query.bp`'s `#[query]` emits a module-level
      `val __rkQueryReg_<method>`, named by the method alone, so two `find` methods on two types of one module emit
      the same name twice (`function '__rkQueryReg_find'/0 already defined` on erlang). It built while a `_`-prefixed
      module-level `val` emitted no function; B-39 made it an ordinary binding, which is the language's rule
- [x] fixed where it belongs: rakun's, 150 s30; no compiler change
- [x] Conformance step: none — the fix is not the compiler's

### B-82 … B-85 — moved to front 164 wasm-gc (2026-10-14)

The wasm-gc group is a front of its own in this machine’s folder, **run by this machine**: [`164-wasm-gc/README.md`](164-wasm-gc/README.md) — s1 (B-82,
wasmtime), s2 (B-83, WasmGC codegen), s3 (B-84, std-wasm in botopink and `.wat`), s4 (Conformance). Nothing of it
stays here; B-30 is closed as superseded by it.

### B-86 — the catalogue across packages, the lib-agnostic gate's list (front 165 s4; the maintainer, 2026-10-14)

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** nothing; 165 s5 waits on it

- [x] `@TypeInfo.all` reaches the declarations of the program's dependencies: a dependency's analysis exports its
      catalogue, level B (B-60) stores it with the entry, the program's catalogue is the union; a cell: a dependency's
      `#[m]`-annotated declaration listed by the program — what rakun's `rakun.boot()` discovers modules with (mono-a)
- [x] the lib-agnostic gate of `zig build test` refuses `rakun|query` in `compiler-core/src` (was `rakun|jhonstart|erika`)
- [x] the reference: § Decorators, the catalogue's reach

### B-100 — the tooling reads the libraries at their new homes (front 165 s8)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet · **Lands with:** 165 s8's pointer commit

botopink-lang's tooling names the former repositories' paths: `test-analysis-equivalence` and the cold cells of
`build.zig` read cells of jhonstart, rakun and emilia under `conformance/modules/`; `scripts/tsc-check.sh` reads
erika's `generic_loader_binding` beside it (`../erika`, `repository/query`); `scripts/test-libs.sh` and comments list
the six repositories. After 165, those cells are rakun's `conformance/<package>/` (rakun-bpp, rakun-stylesheet, rakun)
and query's `conformance/modules/` (`repository/query`).

- [x] every path and list names rakun's workspace and `query`; no former repository's name left in the tooling
- [x] `zig build test-analysis-equivalence` green in the meta checkout after 165 s8; `scripts/tsc-check.sh` green on
      std, the libraries and query's cell — its reds on botopink-lang's own cells are B-108's

### B-97 — beam: a `Declared`'s field read in a dependency answers the whole record

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a backend bug with a measured repro)

Found by 165 s5: a dependency's function reading a field of a `Declared<unknown>` the program hands it — `d.name`
directly, through a function, inside `map` or `for` — answers the whole `Declared` record on beam (in rakun's boot,
`{badmatch,{…Declared…}}`); erlang answers the field. Repro, a program and one dependency `lib`:

```bp
// lib/src/root.bp
pub fn mark(comptime decl: @Decl) { decl.setMeta("k", decl.name); }
pub fn show(all: Declared<unknown>[]) { @print(all.map({ d -> d.name }).join(",")); }
// src/main.bp
import {mark, show} from "lib";
#[mark] pub fn one() -> string { return "1"; }
pub fn main() { show(@TypeInfo.all(with: mark)); }      // erlang: one · beam: the record
```

B-95's cause (`Declared` is the compiler's record, which the dependency does not declare: `'__bp_field'/2`). B-95's fix
covers only `Asset` and `SourceLocation`: read through the value's tag, it regressed the comptime builtins that are maps
at run time (`@Decl`). The general fix needs the emitter to know which imported records are tagged tuples.

- [x] a `Declared`'s field read anywhere answers the field on beam; a cell on every target
- [ ] rakun's `conformance/rakun/boot_modules` green on beam (a 150 consumer row)

### B-93 — commonJS: a positional pattern lowered against another package's same-named variant

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a backend bug with a measured repro)

Found by 165 s2: in one commonJS program that loads both `markdown` (`MdNode`'s variants `Text`, `List`, `Table`,
`Row`, `Image`) and rakun-stylesheet (its `Token` sections hold variants of the same names), a bare positional pattern
`Text(value)` on `MdNode` reads the field as `$0` (the other variant's positional layout) instead of `value`; writing
the label (`Text(value: value)`) answers, `MdNode.Text(value)` does not. Repro: rakun's `rakun-ssr` with `config`,
`integration` and `content` in one root.

- [x] a pattern's field layout is the matched type's own variant, whatever other variant shares its name; a cell: two
      packages with a same-named variant of different shapes, a positional pattern on each, on every target
- [ ] rakun-ssr's `src/content/element.bp` patterns back to the positional form (a 150 consumer row)

### B-89 — beam: emilia's module refused by the BEAM assembler (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a backend bug with a measured repro)

Every `conformance/modules/` cell of emilia on `feat` (79 cells, `conformance/emilia/` once in rakun, front 165) is
refused on beam: `the OTP compiler refused the emitted program — nothing to run`. The assembler stops at emilia's
module-level tables (`everySpacingToken/0`, `front38TextLeaves/0`, `layoutLeaves/0`, `outlineLeaves/0`,
`ringLeaves/0`, …): `An implementation limit was reached … Instruction: {test_heap,3,1}`. commonJS and erlang answer.

- [x] the beam emitter splits or builds a large literal table within the assembler's limits; emilia's module assembles
      — a table counts its widest element's y-slots, not their sum (a 1100-row table assembled)
- [ ] every emilia cell green on beam (`botopink cell check conformance/` in rakun) — emilia's `botopink.json` lists
      commonJS and erlang only, so its cells read beam once rakun's emilia adds the target (a 165 consumer row); on
      `2481d61c7` emilia's module (`rakun-stylesheet`, its `#[@External]` migrated by hand) assembles, and a 5000-row
      table with a 14-way `.append` chain runs on beam — nothing left in botopink-lang
- [x] a unit test the hook runs: a module with a literal table past the limit assembles (478)

### B-87 — erlang: a `var` reassigned inside a nested arm reaches a `defer` late (decision 539, amended)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

539's amendment reads a deferred expression when it runs. erlang carries a `var` the rest of the block reassigns in the
process dictionary, written after each statement: a reassignment inside a nested arm reaches it only after the outer
statement, so an arm that panics or throws hands the defer the old value
(`var f = "a"; defer @print(f); if (c) { f = "b"; @panic("x") }` prints `a`).

- [x] the cell above, red on erlang (beam checked the same), green after
- [x] the reassignment written where it happens, inside the arm
- [x] erlc's "unused variable" warning on a defer body that rebinds a `var` (cell `defer` 4) gone

### B-88 — a jump from a block or a `case` arm reaches its loop or generator on commonJS and erlang (decision 541 (2))

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

541 (2) makes a block a scope of the enclosing function: `await`, `yield`, `break` and `continue` in it reach the
function and the loop. The bare forms landed on commonJS, erlang and beam; these are unbuilt or unmeasured.

- [x] `break :outer` / `continue :outer` from a `case` arm's block to an outer loop — cell
      `block_jump_label_reaches_loop`, green on commonJS and erlang; every target ignored the label, from a plain `if`
      too. Left: `continue :outer` is not parsed (B-104); beam (B-105) and wasm (164 s2c) red
- [ ] `yield` in a block inside a lambda generator reaches the lambda, the nearest function — cell
      `block_yield_in_lambda_generator`, the lambda an `iter { -> … }` (decision 553) — after B-116 piece (i)
- [x] `return` inside a yielding arm returns from the enclosing generator on commonJS (the `function*` delegation) —
      cell `case_arm_return_in_yielding_arm`, green on commonJS, erlang and beam; wasm red (164 s2c)
- [ ] every refusal printed `error[<code>]: <message>` (decision 557): the checker's code printed by the one printer,
      the 577 cell refusals written `error: <code>: …` rewritten in that commit, `block-break-value` among them

### B-90 — commonJS: an unmarked raise is `crash`, and `abort_text_panic` (decisions 546, 535, 527 (1))

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

527 (1) and 546 make the failure kind exact on every target and an unmarked raise `crash`. 546 reads "commonJS keeps
wrapping every such call (492)", but commonJS wraps nothing: its `attempt` reads every raise that is not a panic as
`host`, and so does its abort guard.

- [x] a call of a binding declared outside std without `result: true` wrapped on commonJS (the `host` mark); the
      `attempt` / `attemptTask` Node forms and the abort guard read an unmarked raise as `crash`
- [x] `std_failure_attempt_crash` widened to commonJS; a cell `abort_text_crash` on commonJS (a raise from emitted
      code: a mistyped binding's value whose method call raises)
- [x] a cell `abort_text_panic` (`@panic`'s text, `panic: <message>`) on every target, out on wasm until 164 s2c's box
      lands

### B-101 — commonJS: a `case` no arm matches answers `undefined` instead of raising `crash` (decisions 535, 527 (1), 546)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

A `case` whose subject matches no arm raises `{case_clause, V}` on erlang and beam — `crash` under `attempt` and at the
abort guard (535: "`crash: <reason>` for a failing match"). On commonJS the `case` lowering emits the arms' `if`s with
no fall-through: a `case` value answers `undefined`, a statement `case` runs on. `std_failure_attempt_crash` raises on
commonJS only because its Node form answers `null` and the first arm's tag read faults — node's `TypeError`, recorded as
a `snapshot/targets/commonJS/` departure, which 458 forbids for a defect.

- [x] the commonJS `case` lowering ends in a throw read as `crash` by `attempt`, `attemptTask` and the abort guard; its
      text the engine's, the cells claiming the kind alone (decision 556)
- [x] `case_no_arm_matches_raises` widened to commonJS with a Node form answering a tagged value no variant is
      (`({ tag: "Square" })`, so no engine fault masks the gap); `output/` claims `stderr crash:` — red on the parent
- [x] `std_failure_attempt_crash`: the same Node form, its `snapshot/targets/commonJS/` deleted, `show` printing
      `f.kind` alone (556) — red on the parent

### B-102 — erlang: an external template's Erlang-escaped quote loses its backslash

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a backend bug with a measured repro)

The erlang emitter unescapes an `@External.Erlang` template a second time (the bound wrappers of 546's host mark), after the lexer has already processed the
string's escapes: every `\` before `"` is dropped. A template holding an Erlang string literal with an escaped quote,
`re:run(__B, "q=\"([^\"]+)\"", …)`, is emitted as `"q="([^"]+)""`, which erlc refuses (`adjacent string literals
without intervening white space`). Hit by rakun-mail's `test/compose_test.bp`. Repro:

```bp
#[@External.Erlang("""(fun(__B) -> case re:run(__B, "q=\\"([^\\"]+)\\"", [{capture, all_but_first, binary}, global]) of {match, __Ms} -> [__X || [__X] <- __Ms]; _ -> [] end end)($0)""")]
declare fn quoted(text: string) -> string[];
pub fn main() { @println(quoted("a q=\"x\" b").length().toString()); }   // 1 on erlang and beam; erlc refused it
```

- [x] the template emitted as the lexer answered it, an Erlang-escaped quote kept; a cell with an escaped quote inside
      an Erlang string literal of an external template, red on erlang today (beam never rendered it twice)
- [ ] rakun-mail's `compose_test` compiles on erlang (a 150 consumer row)

### B-103 — erlang and beam: `try … catch` contains a `host` raise (decisions 431 (2), (3), 546)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a backend bug with a measured repro)

431: `try e catch f` handles a `@Result` on the spot; a raise that does not arrive as one — an unannounced host raise —
is contained by `attempt` alone. On erlang and beam the `try … catch` lowering ends in `error:_TryR0 -> {error,
_TryR0}`, so since 546 marks a library binding's raise as `error:{bp_host, _}` every such raise inside the operand is
read as the `Error` arm. Found by 165 (rakun's navigation signal, `rakun-app/test/navigation_test.bp`: "a signal inside
try … catch still reaches the capture"). Repro:

```bp
#[@External.Erlang("""erlang:throw($0)""")]
declare fn sig(r: string) -> i32;
fn load(s: string) -> @Result<string, string> { val _n = sig("nav:x"); return s; }
pub fn main() { val v = try load("a") catch "fallback"; @print(v); }   // prints fallback; a host raise is the answer
```

- [x] `try … catch` catches only its operand's `Error`; a `host`, `panic` or `crash` raise inside it propagates, on
      every target — a cell red on erlang and beam today (commonJS measured)
- [x] rakun-app's `navigation_test` signal-through-`try` test back, its `// LANGUAGE GAP` marker gone (a 150 consumer
      row)

### B-104 — `continue :outer` is not read (decision 541 (2); docs § Loops)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`conformance/docs.md` § Loops puts a label on `continue` as on `break`, and 541 (2) sends a `continue` to an outer loop
from a block; the parser reads `continue` alone (no `:label`, the AST's `continue` carries none), so `continue :outer`
is a parse error on every target and B-88's cell could pin `break :outer` only.

- [x] `continue :label` parsed and carried in the AST, the label checked as `break :label`'s is (`break-label-unbound`,
      `generator-loop-closed-scope`)
- [x] `continue :outer` from a nested loop's body and from a `case` arm's block reaches the named loop — cell
      `block_jump_label_continue_reaches_loop`, red on every target, green on commonJS and erlang after (beam B-105,
      wasm 164 s2c)
- [x] the formatter prints the label on `continue` as on `break`

### B-105 — beam: a loop's label is ignored (decision 541 (2))

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

B-88 landed `break :outer` from a block or a `case` arm's block on commonJS and erlang. beam's emitter (`beam_asm.zig`,
not the erlang one) reads no label: a jump to the named loop's exit, and a throw out of a `foldl` fun where the loop is
one.

- [x] cell `block_jump_label_reaches_loop` green on beam
- [x] `continue :outer` on beam once B-104 lands

### B-106 — erlang: a value `if` whose branch reassigns a `var` is refused by erlc (decisions 539, 541)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a backend bug with a measured repro)

B-87 threads a `var` a value `case`'s arm reassigns; a value `if` is not threaded:
`var f = "a"; val r = if (c) { f = "b"; 1 } else { 0 }; @print(f)` fails erlc with `unsafe variable`.

- [x] the value `if` threads a reassigned `var` as the value `case` does; a cell, red on erlang, green on every target

### B-107 — `Index` and `Slice` are ambient (docs § indexing, decision 63) but not as `Display` and `Closeable` are

**Repository:** botopink-lang (`--lang`) · **Model:** opus (the checker)

B-96 keeps the ambient behaviors in a list of two in the compiler. The reference names four: `Index<K, V>` and
`Slice<V>` "ambient like `Display`", and 539 (6) reads "the compiler names no std type". Today `fn f(m: Index<i32,
i32>)` is `unknown type`, and an `implement Index<…>` with no `at` is accepted while one of `Closeable` with no `close`
is refused.

- [x] the ambient set is what `builtins.d.bp` declares and no compiler rule reads (`Annotation`, `Decorator`,
      `Renderable` each have their own) — `Display`, `Closeable`, `Index`, `Slice`; cells `ambient_index_parameter`,
      `ambient_index_implement_missing_method`, red today
- [x] the compiler's comment on the ambient set no longer cites `<T: Closeable>` (no such syntax)
### B-108 — `scripts/tsc-check.sh` red on botopink-lang's own cells

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

Found running B-100's check on `feat`: std, the libraries and query's cell pass; botopink-lang's own projects do not.
`conformance/modules/declared_field_read_other_module` (B-97's cell): `lib/root.d.ts` names `Declared` without
declaring or importing it (`TS2304: Cannot find name 'Declared'`). Every `conformance/test/*` project suite
(`behavior_host_dispatch`, `bodyless_fn`, `external_host`, `external_markers`, `mocks_decorator_double`,
`mocks_handwritten_double`, `module_init`, …): the walk builds it as a program and the build answers `no source
files found in src/` — a project suite holds `test/` alone.

- [x] a `.d.ts` that names a compiler type (`Declared`, and the other records the compiler splices) declares it or
      imports it; the cell checked by `tsc`
- [x] the walk builds a project suite the way `botopink test` does (its `test/` modules), or reads it by what it holds;
      no suite left out by name
- [x] `scripts/tsc-check.sh` green on `feat`, read from `test.yml` on GitHub

### B-109 — beam: a `continue :label` under an in-frame loop inside a fun-walked loop, and two labels continued from one loop

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

B-105 lowers a loop's label on beam by a jump inside a frame and a throw out of a fun. Two shapes are left: a
`continue :outer` aimed at a loop walked by a fun but written under an in-frame `while` inside it is not lowered, and
when one inner loop continues two enclosing labels only the first is guarded.

- [x] both shapes in a cell (`block_jump_label_continue_nested_shapes`), red on beam today, green on every target but
      wasm (164 s2c)

### B-110 — an unknown generic type name is accepted unchecked (`fn f(m: Bogus<i32, i32>)`)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

A bare unknown type name is refused `unknown type`; the same name with type arguments is accepted and never checked:
`fn f(m: Bogus<i32, i32>)` compiles on every target. Found by B-107.

- [x] a parameter, field, return and `val` annotation naming an unknown generic type refused `unknown type` at the
      name — a refusal cell, accepted today

### B-111 — a `val` annotation naming an unknown type: `type mismatch`, located at the statement

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`val m: Bogus = 1` reads `type mismatch: expected Bogus, got i32` instead of `unknown type 'Bogus'`, and B-110's
`val m: Bogus<i32> = …` refusal points at the `val` statement, not at the name: a `val` annotation carries no location
of its own.

- [x] a `val` annotation carries its location; a bare unknown name in it refused `unknown type` at the name, and the
      generic form's refusal (cell `unknown_generic_type_val`) moved to the name — a refusal cell, red today

### B-112 — `test-analysis-equivalence` reads rakun's conformance by feature (decision 548, front 165 s9)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

165 s9 regrouped rakun's cells as `conformance/<package>/<feature>/<cell>/`, each feature directory the workspace of its
cells. `modules/compiler-cli/tests/analysis_equivalence.sh` still reads `conformance/<package>/botopink.json` and
`conformance/<package>/<cell>`, and `build.zig`'s comment names the same roots.

- [x] the script reads each cell at its feature directory, with the feature's manifest; `zig build
      test-analysis-equivalence` green in the meta checkout

### B-113 — `botopink cell check` keeps a cell's path inside its workspace (decision 548, front 165 s9)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`cell check` copies a cell to `<scratch>/<basename>` and writes the workspace manifest beside it with the same member
globs (`cell.zig`'s copy, the manifest's `workspaceOf` / `listsMember` matching only `<dir>/*` children). A root whose
members are `<package>/*` or `*/*` lists the cell in place but not its flat copy: the cell answers `unresolved import
source "rakun"`. So rakun's suite carries one manifest per feature instead of one root.

- [x] the copy keeps the cell's path relative to the workspace root, so a nested member glob finds it; a cell (a
      workspace with `group/*` members, a cell two levels down) red today — `cli_contract.sh`'s fixture
      `tests/cell-workspace/` (a workspace itself, it cannot be a member of `conformance/modules/`: workspaces do not
      nest, and as a cell there it refused every in-place build of the suite, `tsc-check.sh` red)
- [x] rakun's feature manifests folded into one `conformance/botopink.json` (a 150 consumer row; 165 s9's box): the
      copy's manifest lists the cell alone (`soleMember`), so a root of several entries builds; the fixture's second
      entry (`second/group/*`) red before, green after; `analysis_equivalence.sh` reads the root manifest

### B-114 — commonJS: an `f64` passed as a type parameter is written the JS engine's way (decision 521)

**Repository:** botopink-lang (`--lang`) · **Model:** opus (a design: JS cannot tell an `f64` from an integer at run time)

521 writes an `f64` as std-wasm's text on commonJS wherever it differs from the engine's. Inside a generic body the
type is gone: `fn show<T>(x: T) -> string { return "${x}"; }` called with `4.0` answers `4` on commonJS, `4.0` on
erlang, beam and wasm; `@print(x)` and `"v=" + x` the same. Found by B-78's Conformance step.

- [x] an `f64` reaching a generic body as `T` is written `4.0` on commonJS (the type's shape handed in, or the body
      specialised per call) — a cell red on commonJS today, green on the four targets: a top-level generic fn whose
      body writes a `T` as text takes one hidden trailing `__bp_ty_<T>` per type parameter, the print shape of the
      type each direct call binds (`"f"`, `["[", "f"]`); the `T` values and the `.d.ts` unchanged, a caller that
      leaves it out (host, TypeScript, a fn value, another module) gets the engine's text —
      `generic_float_text`, `generic_float_record_text`

### B-115 — commonJS: the generic calls B-114's print shape does not reach (decision 521)

**Repository:** botopink-lang (`--lang`) · **Model:** opus (a design: the shape crosses a value or a module)

B-114 hands a top-level generic fn the print shape of each type parameter at a direct call in its own module. Three
calls still write an `f64` bound to `T` the JS engine's way on commonJS (`2` for `2.0`):

- [ ] a generic fn passed as a value (`xs.map(show)`): the host callback's extra arguments (the index) land in the
      hidden slot — a cell red on commonJS today
- [ ] a call into a generic fn of another module — a cell red on commonJS today
- [ ] a generic method's type parameters (`Dict<K, V>.display` through `collections.shown`) — a cell red on commonJS
      today
- [ ] a tuple held in a type-parameter slot is printed as a tuple (`Box(value: #(1, 2))`, `id(#(3, "x"))` answers
      `#(3, "x")`; today `[1, 2]`, `[3, "x"]`) — found by 164 s2's tuple subtype; a cell on every target

### B-117 — `botopink check` of a project of refused decorator markers peaks at 8 GB

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

validation's `test/refusal_test.bp` ("every marker on a field type it cannot check is a located compile error") writes
one module per validation marker, each with the marker on a field type it cannot check, and runs `botopink check .`
over them: the process peaks at about 8.2 GB with `feat`'s compiler (measured 2026-10-15), and while it runs with other
gates the machine runs out of memory. Each module answers one refusal; nothing in the project needs that memory.

- [x] the cause measured and fixed: every decorator call kept its generated module, its encoded argument, its reply and
      an erased copy of the decorator's reach in the session arena, and a wasm build kept its arena per module — now
      scratch freed per call; the check 8.5 GB → 1.3 GB cold (0.9 GB warm), its output the same; the unit test
      "decorator invocation: a call holds its trace and outcome only, not the scratch it ran from" (478)

### B-118 — beam: an `iter loop` as a lambda's tail aborts

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

Found by B-116 P1: a lambda whose tail expression is an `iter loop { … }` aborts on beam (`function_clause`); commonJS,
erlang and wasm answer the generator. B-116's marked lambda writes `return <block>;` to step around it.

- [x] an `iter loop` as a lambda's tail answers its generator on beam — a cell on every target, red on beam today —
      `lambda_tail_iter_loop`

### B-119 — commonJS: an adopted behavior `default fn … -> @Task` is emitted without `async`

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

Found by B-116 P1: a type adopting a behavior's `default fn` that answers `@Task<T>` and awaits gets a non-`async` JS
function, which Node refuses ("await is only valid in async functions"); erlang, beam and wasm answer.

- [x] the adopted default body is emitted `async` on commonJS — a cell on every target, red on commonJS today —
      `behavior_default_awaits`

### B-120 — commonJS: a contextual variant `.Term` as an argument of a namespace call is emitted bare

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

Found by B-27 step 6: `process.onSignal(.Term, h)` (`process` an imported std namespace) emits a bare `Term`, which
Node refuses ("Term is not defined"); erlang and beam resolve the variant from the parameter's type. The std cells
write `process.Signal.Term`.

- [ ] `.Variant` as an argument of a namespace-qualified call resolved from the parameter's type on commonJS — a cell on
      every target, red on commonJS today

### B-121 — beam: a user function named `run` or `size` is taken for a std binding

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

Found by B-27 step 6: on beam a program's own `fn run(…)` is refused "`run` has no #[@External.<Target>] for the beam
backend", and a program's `fn size(…)` answers `null`; commonJS and erlang call the user's function.

- [ ] (staged, cell `user_fn_named_like_std`; the cause: `externalDeclFor` answered the std host declaration before
      the program's own fn; `size` answering `null` did not reproduce) — landing once the hook is green (165 s10)
- [ ] a user function named like a std binding (`run`, `size`) is the user's on beam — a cell on every target, red on
      beam today

### B-122 — beam: `.toString()` on a tuple is `unresolved_method`

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

Found by B-27 step 6: `#(1, 2).toString()` aborts on beam with `unresolved_method`; commonJS and erlang print the
tuple.

- [ ] a tuple's `toString()` on beam answers the text `@print` writes (`#(1, 2)`, `tuple_print`'s answer) — cell
      `tuple_to_string`, red on beam on the parent; staged, landing once the hook is green (165 s10)
- [ ] commonJS: a tuple's `toString()` answers `#(1, 2)`, not JavaScript's `Array.toString` (`1,2`) — the same cell
- [ ] wasm: a tuple's `toString()` resolves (today `cannot resolve the call toString/0`) — the same cell

### B-124 — beam: an Erlang host template with a binary pattern other than a fixed-size unsigned segment is refused

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

Found by B-27 step 6: an `#[@External.Erlang("""…""")]` template matching `<<_/binary>>` or `<<"lit", X/binary>>`
compiles on erlang and is refused on beam; std's templates were rewritten without such patterns.

- [ ] beam accepts the binary patterns an Erlang host template writes — `X/binary` and a literal prefix already did; a
      sized `X:N/binary`, `little` and `signed` whole-byte integers, and a literal prefix followed by an integer field
      (beam answered `0` where erlang answers `121`) — cell `host_template_binary_patterns`, red on beam on the parent;
      staged, landing once the hook is green (165 s10)
- [ ] a `utf8` segment and `binary-unit:N` (`<<A:4/binary-unit:8>>` does not parse) — still refused on beam

### B-126 — std: an `FsError` carries its own text (decision 563)

**Repository:** botopink-lang (`--lang`), then a consumer commit in snap and in rakun · **Model:** sonnet (563 fixes
every text)

563 (540-c (a)) gives `FsError` its text in std, so no library writes a `case` over its seven variants.

- [x] `pub fn message(self: FsError) -> string` in `libs/std/src/io/fs.bp`, one text per variant as 563 lists them
      (`not found: <path>`, … `not UTF-8: <path> at byte <offset>`, `<path>: <message>`); a cell on every target, one
      `FsError` of each variant, the seven texts the same everywhere — `fs_error_message` on commonJS, erlang and beam
      (wasm with `io.fs`, 164 s3), `message` a method of `FsError`
- [x] snap (`src/root.bp`) and rakun-ssr (`src/content/collections.bp`) delete their local `fsText` and write
      `e.message()`; every answer of both the same

### B-127 — `botopink check` cold: the analysis arena and a decorator's trace listing kept for the session

**Repository:** botopink-lang (`--lang`) · **Model:** opus (the traces feed the code cache's entries)

Left by B-117: validation's refused-marker project still peaks at 1.3 GB cold. About 800 MB is the analysis arena of std
and validation (lexer tokens and parse trees kept for the whole session), and each decorator call keeps a listing of
about 1.7 MB in its trace, which also feeds the code cache (`analysis_entry`, level B).

- [x] a module's tokens freed after its parse, a trace's listing built when the cache needs it; that check under 1 GB
      cold, its output and every cache entry the same; B-117's unit test's bound tightened to match — 1.38 GB → 0.92 GB
      cold; a trace keeps the module's name, argument and reply, the wat build cache the module's Erlang text, a listing
      lowered again when a snapshot or the code cache reads it (question B-127-a)

### B-128 — erlang, beam, wasm: a generator runs its whole body at the call (decisions 105, 125)

**Repository:** botopink-lang (`--lang`) · **Model:** opus (the eager scopes are the erlang and wasm lowerings' design)

105 makes a generator's body lazily evaluated, one step per `next`, and 125 keeps it (the prefixed loop *is* the
iterator); `conformance/docs.md` § Iterators and streams says each `next` runs the body up to the next `yield`.
commonJS does so. erlang (`codegen/erlang.zig`'s `GenScope`: "a generator is the list of its items, collected while the
body runs"), beam and wasm run the whole body at the call — a print before and after a `yield` comes out at once, and an
endless `iter loop` cannot be consumed. Found by B-116 P1.

- [x] a generator's body runs one step per item asked for on every target — a cell with a print before and after the
      first `yield` on each form (an `iter fn`, an `iter loop`, a marked lambda) and an endless generator taken by
      `take(3)`, red on erlang, beam and wasm today, green on commonJS
      — erlang and beam: each generator a process (`codegen/beam/gen_runtime.zig`, one text for both) that waits for a
      request before it starts and at every `yield`; `generator_body_lazy` green on commonJS, erlang and beam
- [x] wasm: a generator's body a resumable state machine as a `@Task`'s (392), each `yield` a suspension point; `for`,
      `.next()` and the iterator methods step it; `generator_body_lazy`, `generator_handle_stateful` (B-134) and
      `generator_captured_var_shared` (B-135) green on wasm — in a GC module (`wat/AGENTS.md` § Generators as state
      machines); a module that falls back to linear memory is B-142

### B-133 — erlang, beam: a generator nobody closes outlives its creator

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

B-128 makes a generator a process; one abandoned (a `next()` by hand, an unfinished `map` / `filter` / `drop` chain) waits
until the node halts, with an open io device if it reads a file. No library creates one today; a rakun handler reading
`f.lines()` per request would leak one per request.

- [x] the generator monitors its creator and exits when it dies; a unit test over the helper text or an
      `erlang:processes()` count

### B-134 — erlang: a generator of only literal `yield`s is a list and replays

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`isPlainYieldGenerator`'s typed path in `erlang.zig` keeps a body of literal `yield`s a list: a second `for` over the
same handle prints its items again (commonJS: once), and `next()` on a non-local receiver never advances (105, 553).

- [x] a generator handle is stateful whatever its body; cell `generator_handle_stateful` (a second `for` over an
      exhausted handle, both forms), red on erlang and wasm today — green on commonJS, erlang and beam; wasm with
      B-128's wasm half

### B-135 — erlang, beam: an `iter` loop's captured `var` is a copy after an outer write

**Repository:** botopink-lang (`--lang`) · **Model:** opus (the lowering of captured variables)

105 captures the enclosing scope's variables as a closure, one variable both ways. B-128's `GenCell` re-reads the cell
only before a later statement of the same sequence; an outer write ends the tracking, and a read inside a nested block or
lambda after the loop reads the pre-loop value.

- [x] every read and write of a captured name after the loop goes through the cell; cell
      `generator_captured_var_shared` — green on commonJS, erlang and beam (`GenCell`: a `make_ref()` bound before
      the loop, every read `erlang:get`, every write `erlang:put`, nested blocks and lambdas included, the name bound to
      the cell's last value when its sequence ends); wasm with B-128's wasm half

### B-129 — the gate's job budget counts 768 MiB a job; the commit hook alone runs a 31 GB machine out of memory

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (measured; the budget's numbers only)

`scripts/gate.sh` § job budget sizes the side-by-side stages by `pool_default_jobs` (`scripts/lib/pool.sh`): one job a
CPU, bounded by `MemAvailable / 768 MiB`, then 50 % / 30 % / 10 % to test-libs, test-conformance and tsc-check. On a
31 GB machine that is ~10 test-libs jobs, while one library build measures 1–2.5 GB, and test-web's wasm compile of
`compiler-web` (~7 GB) runs beside them uncounted: the commit hook alone, with nothing else running, drops
`MemAvailable` to 0–1 GB (measured 2026-10-16 on a commit of 144 B-126).

- [x] the budget bounded by each stage's measured peak (a test-libs job ~2.5 GiB, a conformance job's, test-web's compile
      counted before the pools are sized, or run apart from them); the hook on a 31 GB machine never below 3 GB available;
      the numbers in § job budget's comment measured, and a unit-level check of `pool_default_jobs`' arithmetic

      — `pool_budget_jobs` (`scripts/lib/pool.sh`): the largest total whose estimated peak (test-web and test-cli
      counted first, 11.2 GiB; a test-libs job 3.7, a conformance job 1.0, a tsc job 0.75 GiB) fits MemAvailable less
      3 GiB; checked in `cli_contract.sh`
- [ ] the hook on a 31 GB machine measured alone on the pool, MemAvailable sampled over its run: its minimum at or above
      3 GB
### B-130 — std: `json`, `regex` and `process` answer their own error enums (decision 486)

**Repository:** botopink-lang (`--lang`), then the consumer commits · **Model:** sonnet · **After:** 164 s3's per-call
refusal on wasm (518 (4))

B-08 left `json.parse` / `stringify` / `unquote`, `regex.compile` and `process.run` answering `HostError`: a public body
over a binding with no wasm cell makes wasm refuse the whole module today, so `JsonError`, `RegexError` and
`ProcessError` wait for wasm to refuse only the call reached.

- [ ] the three enums declared, each failure the current bindings handle a named variant (486 (4)), `Host(HostError)` the
      rest; a cell on every target per module; the consumers' calls updated
- [ ] `io.process`'s `rawOnSignal` / `rawSpawn` / `rawKill` and `io.terminal`'s raw cells (B-27 step 6) still classify the
      host's failure by hand into the `kind|message` text `ProcessError` / `TerminalError` read: written `result: true`,
      `HostError` mapped into those enums in std (486 (2))

### B-131 — wasm: three `std_decorator_*` cells read `std/testing/mocks.bp` a line off

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

Found by B-127 on `feat`'s compiler: `std_decorator_leaf_import`, `std_decorator_through_namespace` and
`std_decorator_unknown_through_handle` fail on wasm with a location in `std/testing/mocks.bp` shifted by a line; the other
targets answer.

- [x] the three cells green on wasm, the location the source's — the cause named (a std source edit the wasm path reads
      stale, or the location's own arithmetic) — the departures' recorded lines, stale after B-08 and B-126 moved
      `std/testing/mocks.bp`; re-recorded; no compiler change

### B-132 — `botopink cell check`: a target's exclusion probe copies the cell without its workspace's literal entries

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

rakun's `conformance/rakun-service/filter-chain/{cors,filter_chain,middleware,problem_details,response_headers}` and
`tls/web_tls` fail on `feat`: for commonJS and wasm, which their `targets` exclude, `cell check` builds the cell in a
scratch copy to read the refusal, and that copy's manifest names the literal workspace entry `rakun`
(`deps/rakun/botopink.json`) without copying it — `workspaces entry "rakun": … does not exist`. The cells' own targets
answer.

- [x] the probe's copy carries every literal workspace entry the cell's manifest names (or reads the refusal in place); the
      six cells green; a fixture in `cli_contract.sh`'s cell-workspace tests with a literal entry and an excluded target
      — the copy keeps a symlink to a directory outside the cell as a symlink (rakun's `deps/rakun-service` had become
      a directory whose own manifest the compiler read); fixture `excluded_target_literal_entry`; two of the cells also
      wrote their lambda's tail with `;` (541), fixed in rakun

### B-116 — the body markers: `iter`, `async`, `async iter`, `component` (decision 553)

**Repository:** botopink-lang (`--lang`), then a consumer commit per library · **Model:** opus for (i) and (iii),
sonnet for (ii)

553 moves what admits `yield`, `await` and `use` from the return type to a marker before `fn` and a lambda's brace,
writes the return type whole under its marker's name (`Iter<T, R>`, `Async<T>`, `AsyncIter<T, R>`, `Component<R>`),
and puts every failure in a `Result` in the value's layer. Three pieces, in order, each one landing per repository:

- [ ] (i) the markers: parsed before `fn` and before a lambda's brace (`async { … }` and `iter loop { … }` stay the
      block forms); the checker admits `yield` / `await` / `use` by the marker and refuses the keyword without it, the
      hint naming it; `marker-type-mismatch`; a marked lambda checked against its expected type (147); a codemod adds
      the marker wherever a body writes the keyword, the `@` types kept; every cell answers the same; a refusal cell
      per refusal — P1 landed: the markers parsed, printed and checked, a marked lambda checked against its expected
      type and lowered through the block forms, `marker-type-mismatch`, `marker-without-arrow`,
      `marker-lambda-without-expected-type`, `marker-on-declaration`, `component-lambda-not-lowered` (B-116-a … g and
      B-116-i built as recommended, B-116-a decided by 570, B-116-b by 571, B-116-c by 572, B-116-d by 573, B-116-e by 574; cells `marker_*`); a body's tail `await e` / `try e` is its value (537); nothing
      of today's forms refused yet. Left: P2 the codemod over botopink-lang, P3 one landing per library — each also marking
      every `-> @Task` / `-> @Component` body that compiles specially today without a keyword (570) —, P4 the
      keyword without its marker refused, and an unmarked `-> @Task<T>` / `-> @Component<R>` body returning the bare
      value refused as a type mismatch, the hint naming the marker and `Async.resolve` (570)
- [x] (i) the codes renamed (573): `effect-await-without-task` → `await-without-async`, `yield-without-generator` →
      `yield-without-iter`, `use-without-context-effect` → `use-without-component`, each hint naming the marker; no alias;
      every cell, snapshot and `docs.md` citing them updated in the same landing; `iter-await` and the `marker-*` codes kept
- [x] (i) a `component` lambda lowered (574): `component { -> … }` against its expected type compiles as a `component fn`
      (the component-fn path, captures carried) on commonJS, erlang, beam and wasm; `component-lambda-not-lowered`
      deleted; cells: one bound to a typed `val`, one passed to a typed parameter, rendered, one answer everywhere — `component_lambda_typed_val`,
      `component_lambda_typed_param`; lowered through `lowerComponentBody` (question B-116-k)
- [ ] (i) decision 584: a lambda's marker inside the brace, before the parameters (`{ async x -> … }`, `{ iter -> … }`,
      `{ async iter x -> … }`, `{ component -> … }`), `async {` always the block, the trailing form admitted; a marked
      lambda's body a function body (`return v` the `R`, a top-level `continue` and `break v` refused), `docs.md`'s
      `iter loop` equivalence dropped; `async fn f()` with no return type refused `marker-type-mismatch`; the formatter
      migrates the 7 `marker_*` cells; 574's example rewritten
- [ ] (ii) the types: `@Iterator` → `Iter`, `@Task` → `Async`, `@Stream` → `AsyncIter`, `@Component` → `Component`,
      `@Result` → `Result`, declared in std's `.bp`; `Async.resolve(v: T) -> Async<T>` (570); `comptime/effect_chain.zig` reduced to what the markers need; a
      codemod over botopink-lang and every library; every cell the same
- [ ] (iii) what is new: an iterator's `R` (`return v`; `next()` answering `Step.Item(T)` / `Step.Done(R)`), a failure in
      `R` ending the iteration (`for x in try xs`), `Component<Result<R, E>>` the one component that throws — on
      commonJS, erlang and beam, wasm through 164; `io.fs`'s `lines()` / `chunks()` answering
      `AsyncIter<…, Result<void, FsError>>`; new cells red on the parent, green after
- [ ] Conformance (459) — with a cell for the unmarked forms whose tail `await e` / `try e` P1 made the body's value
      (`fn f() -> @Task<i32> { await g() }`, a bare `async { await g() }`, which answered null on commonJS)

### B-91 — `import-of-failed-module` names the failed module's file as the diagnostics label does (decision 545)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

545's file comes from the reflection's source paths: a dependency's module reads `src/client.bp` while its own
diagnostics label it `a/client.bp`, ambiguous with two dependencies both holding `src/`. The path is the label the
failed module's own diagnostics print.

- [x] `imported_declaration_error_location`: `b/b.snap` answers `(a/client.bp)`, `main.snap` `(b/b.bp)` — red today,
      green after; a program module's cells (`(src/shapes.bp)`) unchanged

### B-92 — a raise at build: a module's own template located, and no frame for a call never entered (decision 532)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

- [x] a raise inside a module's own template is located at the call in its body, with the use as `from` (532: "no
      call of an expansion is left unlocated") — cell `template_own_raise_located`, red today
- [x] a call's frame is pushed after its receiver and arguments are evaluated: `foo(1 / 0)` frames no `foo`;
      `hole_any_call_raises` loses its `from src/main.bp:47:12` (`(a / b).toString()`, a call never entered)

### B-94 — erlang and beam: `Bytes.length` read as a property is a text length

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`b.length` on a `Bytes` lowers to `string:length/1` on erlang and beam: a `badarg` on bytes that are not UTF-8, and a
character count on bytes that are. std's `io/fs.bp` calls `b.length()` to avoid it.

- [x] a cell: `b.length` of a `Bytes` holding a byte ≥ 0x80 answers its byte count, red on erlang and beam today
- [x] std's `io/fs.bp` back to the property where it chose the call to avoid the defect

### B-95 — beam: a field read on a type the module does not declare answers the whole record

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

On beam a field read on a value whose type the module does not declare (std reading `Asset.path`, `Asset` being the
compiler's record) lowers to `'__bp_field'/2`, which answers the whole record. std reads `Asset`'s fields through two
host cells (`assetPath`, `assetHandle`) to avoid it.

- [x] a cell: a field read on an imported record the module does not declare, red on beam today — on the four targets
- [x] std's two host cells removed, `Asset`'s fields read directly — `assetPath` removed; the memory handle
      `{mem, bytes, counters}` stays a host cell (`memoryHandle`), a value only the host builds

The fix reads the field through the value's own tag for the records the compiler splices (`Asset`,
`SourceLocation`); a general one regressed the comptime builtins that are maps at run time (`@Decl`) — B-97's.

### B-96 — an ambient behavior as a parameter type (decision 539 (6))

**Repository:** botopink-lang (`--lang`) · **Model:** opus (the checker)

539 (6): `Closeable` is "a plain behavior for generic code". It is ambient in `builtins.d.bp` (as `Display`), but
`fn f(c: Closeable)` is refused `unknown type`, and a type's inline `implement Closeable` is not checked against it.

- [x] an ambient behavior names a parameter type (`fn f(c: Closeable)`) — cell `ambient_behavior_parameter`; the
      language has no bound on a type parameter, so `<T: Closeable>` is no form
- [x] an inline `implement` of an ambient behavior checked against its declaration — a refusal cell
- [x] `builtins.d.bp`'s comment on `Closeable` true

Left: `Index` and `Slice`, ambient too (B-107).

### B-62 — nine cells red on `feat`: a manifest column and a dependency's path

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

Found landing B-61 (2026-10-12), red with `feat`'s own compiler from the main checkout: `bpp_html_missing`,
`bpp_html_twice`, `bpp_key_not_a_dependency`, `bpp_key_object_form`, `bpp_prelude_twice` locate their refusal at
`botopink.json:1:223` where the accepted snapshot says the column of the `bpp` key; `bpp_prelude_holds_declaration`
and `bpp_role_not_pub` likewise; `dependency_imports_itself_with_from` and `dependency_imports_undeclared_package`
print a dependency's file as `../../../conformance/modules/<cell>/deps/…` where the accepted answer is `deps/…`.

- [x] each cause measured (which landing moved the column and the path; the accepted answer is the language's —
      a location relative to the cell, the column of the key that is refused); the fix in the compiler, the cells
      green unchanged
- [x] a test the hook runs for each, red on the parent
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a refusal in a cell's manifest keeps the refused key's column | `bpp_html_missing`, `bpp_html_twice`, `bpp_prelude_twice`, `bpp_prelude_holds_declaration`, `bpp_role_not_pub` |
  | a dependency's file prints as `deps/…` | `dependency_imports_itself_with_from`, `dependency_imports_undeclared_package` |
  | a `path` dependency that leaves the cell | none — a row |

### B-63 — `botopink cell check` runs cells in parallel (`--jobs`)

**Repository:** botopink-lang (`--lang`), and the libraries' shared runner (`runner-standalone.sh`, one text) ·
**Model:** sonnet

Measured on 2026-10-12: `botopink cell check <lib>/conformance` checks one cell after another on one core (one
`botopink` process at ~80 % of a core, the machine's load 1.3 of 16); a library's gate calls it once over its whole
`conformance/`, so emilia's 79 cells on three targets run in a row.

- [x] `cell check` runs its cells (and a cell's targets) on a pool of `--jobs <N>` (default the machine's, as
      decision 468 counts it); the report in the cells' order, the same lines as today
- [ ] a library's `scripts/gate.sh --jobs <N>` hands its share to `cell check` (469); botopink-lang's
      `test-conformance` the same
- [ ] a test the hook runs: two cells checked at once, their report in order; emilia's `conformance/` measured
      with `--jobs 1` and the default
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-64 — a module's tests are a unit of their own, on every target (decision 513)

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** B-58, B-59 · runs beside B-60 and lands before B-60's S4

Today `botopink test` compiles a module's `test` blocks into the module itself (`'__bp_test_0'/0` … inside
`-module(emilia@spacing)`), so one module's production code differs between `build` and `test` and the code cache
cannot serve both.

- [x] every target emits a module's production unit always and its test unit (`__test__` prefix, 513 (1)) only under
      `botopink test` of the package under test; a dependency's test units never emitted
- [x] the production unit always carries the reserved export of its private functions and module-level `val`s (513
      (2)); a test reading either runs on every target; one test runner at the entry; every library's tests green
      unchanged
- [x] a test the hook runs per target, red on the parent: a module's production bytes equal under `build` and `test`
- [x] the code cache (B-58) serves a dependency's production unit to `build`, `run` and `test` alike
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a module's production bytes equal under `build` and `test`; only the package under test has a test unit (513) | `codegen/tests/test_units.zig` |
  | a test reads private functions and module-level `val`s (513 (2)) | `test/module_init.bp`, every `test/*.bp`; `test_tooling.sh` on four targets |
  | a dependency's tests never run | `test_tooling.sh` |
  | `conformance/test/` suites on wasm | none — a row |

### B-67 — erlang: a library's record imported beside a std record of the same name builds std's (D3)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

`import {items.Queue} from "shelf"` beside `import {collections} from "std"` builds `Queue(…)` as
`{std@collections@@Queue, …}` on erlang; the program dies with `function_clause` in `shelf@items:describe`. commonJS
and beam print the right answer. A wrong program, found by `test-closure-invariant`'s `crowded` consumer.

- [x] a cell red on the parent (the two imports, a print of the record and a call into the library); green on every
      target
- [x] the construction names the imported type's owner; an erlang codegen test
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a library record imported beside a std namespace's type of the same name builds the imported one on erlang (430) | `import_record_beside_std_record_of_same_name` |

### B-68 — wasm: a method call on a template's answer does not resolve (D4)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`val built = shelf "built"` (the template answers `Label`) then `built.size.toString()` is refused on wasm: "the
wasm backend cannot resolve the call `toString/0`"; the other targets run it.

- [x] a cell red on the parent; the call resolved on wasm, the cell green on every target
- [x] Conformance step (459, 474, 477, 478, 480) — boxes 3 and 4: the table below, the cells' `docs.md`, `conformance/docs.md`; boxes 1, 2 and 5: § The pipeline state
  | Behaviour (decision) | Cells |
  |---|---|
  | a method call on a package template's answer resolves on wasm (430) | `template_answer_method` |

### B-30 — wasm memory managed as erlang's: a heap per process, collected, in std-wasm (decisions 448, 449)

**Repository:** botopink-lang (`--lang`)

After the B-00 group, B-00i included (the collection knows the terms' layout, 450). botopink's values are immutable; on erlang each process's heap is collected and released
when it dies. The wasm target's bump heap never frees; this step gives the wasm target and beam-to-wasm's translated
code erlang's model, implemented in `modules/std-wasm/src/heap.zig` (449).

- [x] measured first, recorded in `codegen/wat/AGENTS.md` § How far a program grows without collection: a string loop
      ~68 B per iteration, a request loop ~727 B per request (~335 as `@Task`s), a page render ~17.6 KiB per page, all
      linear; running out already traps in `$__alloc`; onze's blog does not build on wasm, so a page of its shape
      stands in
- [x] `modules/std-wasm/src/heap.zig`: a heap per process over one pool, `alloc` on the current heap, minor and major
      copying collections with no recursion, a write barrier on mutable cells, a copy between heaps as an erlang
      message, a heap released whole, exhaustion traps; unit, property and stress tests; in the `program` table as
      `heap.*`, no comptime face; not wired into the codegen yet. Its design points — question B-30-a
- [~] withdrawn (the maintainer, 2026-10-14, wasmgc-a): `alloc` never leaves `wat_prelude` for `heap.zig` — the program's
      memory is the host's collector, group wasm-gc (B-82 … B-85); until B-83 lands a wasm program allocates as today
      (a bump heap, exhaustion a trap, 448 (4)), a known limit of a long task written in the reference
- [x] beam-to-wasm (449 (3)): translated code allocates on the current process's heap; `test_heap` / `allocate` are
      collection points with their live registers as roots; beam-to-wasm still imports std-wasm alone (438)
- [x] a run that exhausts memory traps, never answers with damaged data; std-wasm's frames stay on the one stack (447)
- [~] withdrawn with box 3: the bounded long-running cell is B-83's; `heap.zig` and `modules/beam-to-wasm` stay
      untouched until B-84 deletes them

**Impacted tests:** wasm `run/` cells, `@Task` cells first; wasm RUN LOG snapshots (re-read); `modules/std-wasm` and
`modules/beam-to-wasm` unit tests; `test-libs` wasm column. **Model:** opus (a design the decision leaves to
measurement). **Consumer commits:** none.
- [x] a message copy detects a cycle (522 (5′)): `heap.copy` marks each mutable cell under the walk, answers `error.Cycle`
      with nothing written; the located `message contains a cycle` cell waits on box 3's sends · question B-30-b

The step is closed as superseded: its built boxes (the measurement, `heap.zig`, beam-to-wasm's terms, the trap, the cycle) stay as landed; question B-30-b's answer has no effect. Its Conformance step is none — the group's is B-85.

### B-137 — `compiler.init`: a decorator's run-time code in the program's init list (decision 575 (3), (8))

**Repository:** botopink-lang (`--lang`) · **Model:** opus (every backend) · **After:** B-136; its last box after 165 s10

- [ ] decision 576 (7), (15): `Declared<T>`, `DeclaredMeta`, `DeclaredTypedMeta` and the run-time `@TypeInfo.all` removed with `compile` in: each run-time catalogue cell (`typeinfo_all_*`, comptime_expand_boot's run-time half) registers through its marker's `compiler.init`, its answer kept
- [x] `compile(syntax executor: fn())`: the executor compiled beside the annotated declaration; each target emits a
      module's init function and the program's init list, run once before `main` — modules in dependency order,
      declarations in source order, calls in order; a library module's executors run in the program that imports it;
      any number per declaration
- [x] cells: one executor on commonJS, erlang, beam and wasm; the order across two modules and a dependency; an
      executor from a library's decorator; `compiler-output-outside-decorator`
      (`compile_executor_before_main`, `compile_init_order_modules`, `compile_executor_from_library`,
      `compile_output_outside_decorator`)
- [x] decision 616: the modifier `expr` renamed `syntax` at every site (std, the cells; `-> syntax T`; the refusal codes;
      `parser/syntax_params.zig`, `comptime/syntax_param.zig`); `compiler.bp` written with every member's arrival as 616 lists
      them (`syntax` for a tree, `comptime` for a build value), `compiler_surface.zig`'s table a mirror and its unit test
      checking name and arrival; the libraries' sites in their fronts
- [x] decision 615: `compiler.compile` renamed `compiler.init` at every site (std, the cells, `conformance/docs.md`, the
      AGENTS.md); the cells `compile_executor_*` → `init_executor_*`, `compile_init_order_modules` → `init_order_modules`,
      `compile_output_outside_decorator` → `init_output_outside_decorator`; rakun's and query's sites in 165 s10
- [ ] decision 642: the fold extended to every tree (`addMember` member, `wrapWith` wrapper), `syntax-captures-build` gone
      everywhere; a `syntax` parameter takes the argument as written (`compiler.name(x)` in a member answers `"x"`); only a
      `comptime` parameter given a run-time value refused (`compiler-arg-at-run-time`); cells `member_reads_compiler_name`,
      `wrapper_reads_compiler_name`, `member_names_its_parameter`
- [x] decision 614: a `compiler.*` call inside an executor evaluated at build and spliced as its answer, `syntax-captures-build`
      withdrawn — `compile_executor_captures_build` rewritten as `init_executor_reads_compiler` (`out home`); a
      `compiler.*` argument that is a run-time value of the executor refused, `compiler-arg-at-run-time`
      (`init_executor_compiler_arg_at_run_time`); `addMember` / `wrapWith` trees keep the refusal (question b137-c);
      612's `compiler.name` a `string`, `syntax-has-no-name` (cell `compiler_name_of_lambda`; question b137-d)
- [x] an executor is checked against `fn()` as any argument is (decision 409): a lambda whose tail answers a value is
      refused at the tail with 409's refusal, a named executor (or an `syntax` handed on) of type `fn() -> X` at the
      argument; the executor's statements render as written (no tail erasure); reject cells `compile_executor_answers`
      (`compiler.init({ -> count() })` refused at `count()`) and `compile_executor_named_answers`
      (`compiler.init(count)` at `count`)
- [x] the init order of executors and a module's own body: one list, source order, an executor's declarations right
      after its annotated declaration (decision 580); cell `compile_executor_module_val_order`
      (`["second", "first", "later", "own"]`); a handle inside an executor is its declaration at run time, typed (581 (2)),
      cells `compile_executor_handle_typed`, `compile_executor_handle_mistyped`
- [x] decision 613: `decl` inside an executor is the annotated declaration spliced as code and bound to it, on every kind —
      a type `Users` (`decl.make()`), a method `Users.make`, a behavior, a field `Config.db` —, the checker's ordinary rules
      on the result (`Users` where a value is expected refused with the checker's text at the annotation); never the bare
      name resolved in the module; cells `init_executor_handle_on_type`, `_on_method`, `_on_type_as_value`;
      `_handle_not_module_name` with B-150 (its wasm answer)
- [x] `compiler.catalogue` renamed `compiler.find` (581 (3)), every site, docs and AGENTS included — after B-136's final
      package (its catalogue cells)
- [ ] moved into B-139 by decision 605: `@emit`, `@code` and `@expr` removed with `builtins.d.bp` (`unknown-builtin`), the emit
      splice paths of `commonJS.zig` / `erlang.zig` deleted, the 32 `emit` cells, the 3 `conformance/test/` suites and
      the compiler-cli fixture rewritten over `compile` or removed, each stated — after 165 s10

Oracle: the cells; `test-libs` on the main checkout's rakun after 165 s10.

### B-138 — `external` as one function over `Implementation`; a `declare fn` names its sources (decision 575 (6))

**Repository:** botopink-lang (`--lang`), then the consumer commits (165 s10) · **Model:** opus (every backend and every
library at once; `fable` if opus fails once) · **After:** B-136; its wasm half (`wat.zig`'s `checkHostBindings`,
`host_cells.zig`) after 164 s3 — handed to 164 or landed after it, never beside

- [x] `libs/std/src/external.bp`: `Implementation` with `Wasm`'s cells spelled whole (`WasiAdapter`, `WasmHost` enums
      beside `WasmNeed`), `external` variadic; `compiler.implement` (`implementation-twice`, `implement-with-body`)
- [x] the checker reads a declaration's `Implementation` metas into `FnDecl.implementations` after its annotations ran;
      `infer.zig`'s `external_variants`, `ast.translateExternalCells`, `ExternalRef`, `validateExternalAnnotation`'s
      shape checks, `scanDeclareFnExternal` (commonJS, erlang) and the commonJS prelude fallback go; the table checks —
      `fn:` (`hostFnBinding.zig`), `op:`, `std:` (454), `wasi:`, `result:` (`refuseResultReturn`), `host:` twice, 516 —
      stay over the value, located at the annotation; every backend reads `implementations`
- [x] `declare-without-implementation` at the declaration (top-level, a type's, static); `declare-in-behavior`;
      `DelegateDecl` and both delegate parse paths deleted (an unannotated `declare fn` is a `FnDecl`); `#[@Host]`
      deleted; `bodyless_method_without_binding`'s answer moves from the call to the declaration (its snapshots stated)
- [x] the codemod `#[@External.X(…)]` → `#[@external(.X(…))]`, several annotations of one declaration merged into one,
      every cell's labels kept: std (268 sites) and `conformance/` (158) here, the libraries by 165 s10 (~1740)
- [x] cells: `declare_without_implementation` (three shapes), `declare_in_behavior`, `implementation_twice`,
      `implement_with_body`, a library-defined source annotation (`external_library_source_annotation`); the ~12
      `external_*` shape cells answer the enum constructor's texts, each stated
- [x] `compiler.implement(.Erlang(…))`: the dot shorthand takes `implement`'s parameter type `Implementation` (587; under
      579 an ordinary method's parameter) — cell `external_library_source_dot_shorthand` (`#[bif("lists")]` whose body
      writes `.Erlang(module + ":reverse($0)")`, four targets, `out [3, 2, 1]`); `external_library_source_annotation`
      keeps `Implementation.Erlang(…)`, which stays legal
- [x] a library's `compiler.implement` survives the module's re-analysis: the loss is the fallback text-splice path of
      `comptime.zig` (two `@emit` calls making one declaration: `parseAndMergeContributions` answers null and
      `analyzeSource` re-analysed with a fresh env), the contributions now carried into it — cell
      `external_library_source_beside_emit_split`, red on the parent; on the merged path no shape loses one, and
      `external_library_source_beside_{member,wrap,emit}` stay as regression oracles (green before the fix); the
      `@emit` cells rewritten with B-139 (605)
- [x] a variant constructor called with labels and defaults left out — `Implementation.Wasm(op: "f64.floor")` (an
      `op:` cell takes no `result:`, 491) and a user enum — answers one value on erlang, beam, commonJS and wasm (`planLabelledCall` always plans;
      `defaultInjections` read by every backend, wasm verified) — cells `enum_variant_labelled_defaults` (four targets)
      and `enum_variant_labelled_reorder`
- [x] `?unknown` admits a function value (`body: reverseBody`) — cell `optional_unknown_takes_function`;
      `decoratorArgNotKnownAt` treats a variant constructor as known — cell `decorator_arg_variant_constructor`; the
      formatter prints an annotation whose arguments end in a trailing comma one per line — cell
      `format_annotation_trailing_comma` (a `botopink format` round-trip cell beside `primitives.bp`'s own layout)
- [ ] decisions 618, 619: `Implementation.Node` renamed `JavaScript`; the `Typescript` variant removed (0 sites; the
      `.typescript` row of `parser/implementations.zig` and every reader); `.Node(` → `.JavaScript(` at every std and cell
      site (654 in all with the libraries', theirs in their fronts); `external_variants`, `translateExternalCells`, the
      readers; the enum in `conformance/docs.md` § `declare fn`; `"typings": true` in `botopink.json` switches the `.d.ts`
      emission beside `botopink build --typescript`, either turning it on (619, 620; `manifest`, `main.zig`,
      `compiler-cli/AGENTS.md`, `conformance/docs.md`)
- [ ] decision 617: `implement-with-body` on every bodied declaration, a behavior's `default fn` included — the exemption
      `ImplDecl.isDefault` goes, `implement_with_body` gains the behavior case; `primitives.bp`'s bodies-with-cells are
      B-146's to redistribute, so this box lands with B-146
- [ ] decision 621: only `template` positional in a cell; a second unlabelled argument refused at the argument naming the
      label (`external-field-unlabelled`); `conformance/docs.md` § `declare fn`; cells `external_flag_bare_bool_refused`
      (the text, on `.JavaScript`) and `external_flag_bare_fn_refused` (`.Erlang("…", f)`)
- [ ] decision 610: `body:` on `Erlang`, `JavaScript`, `Wasm` alone, `template` optional only beside it; the refusals
      `external-body-not-a-fn` (not a bare identifier naming a private bodied `fn` with the declaration's types),
      `external-source-empty` (neither `template` nor a cell), `external-all-bodies` (every source a `body:` — write the
      bodied `fn`), each at its argument or the annotation; `conformance/docs.md` § `declare fn` writes the cell's rule
      beside `op:` / `std:` / `wasi:`'s; the 117 `body:` sites re-read for `external-all-bodies`; cells
      `external_body_not_a_fn`, `external_source_empty`, `external_all_bodies`
- [ ] (box 4) `print` bound by its cell on erlang, beam and commonJS, as `io/terminal.bp`'s declaration (606; `println` and
      `debug` are removed there): its `declare fn` carries `.Erlang(…)` / `.JavaScript(…)`; `erlang.zig`, `beam_asm.zig`, `commonJS.zig` dispatch no builtin by
      the names `print` / `println` / `debug` — a grep gate in `zig build test` over `modules/compiler-core/src/codegen`
      (decision 67, like the lib-agnostic gate) and cell `print_bound_by_cells` (four targets; wasm's row red until 164
      s3 lands `.Wasm(std: "print")`)
      — landed on the three backends with the grep gate (`wat.zig` allow-listed until 164 s3), `print` / `println` /
      `debug` still declared in `builtins.d.bp`; left: the declaration's move to `io/terminal.bp` (B-139 box 2) and the
      cell `print_bound_by_cells`
- [ ] `print` on wasm by `.Wasm(std: "print" | "println" | "debug")`: a row of 164 s3 (this step's header: the wasm half
      after 164 s3, never beside), `print_bound_by_cells`'s wasm answer its oracle
- [x] the codemod's misses: `modules/compiler-cli/tests/{cli_contract,test_tooling,closure_invariant}.sh`, the fixture
      `modules/compiler-cli/tests/cell/departs`, `scripts/test-libs.sh`, `cli/{libs,test_cmd}.zig` still write
      `#[@External.X(…)]` — rewritten, with the fixtures `cell/narrowed`, `closure_invariant/hosted`,
      `cell-workspace/group/excluded_target_literal_entry`; `cli_contract.sh`, `test_tooling.sh`, `closure_invariant.sh` green
- [ ] the exemptions `Env.declarationFile` (`.d.bp`) and std `types.bp`'s `Type` (the utilities) and `compiler.bp`'s `Field<T>` / `Info<T>` (624, 630) from `declare-without-implementation` deleted
      when B-139 and B-140 land (scaffolding, no decision); the decorator-marker exemption goes by decision 604 (a marker is `fn x(syntax decl: unknown) {}`; cells `declare_without_implementation_decorator`, `decorator_marker_empty_body`)

Oracle: the 158 `external_*` cells; every library's hook on this compiler; the cold gate.

### B-139 — no `.d.bp`; the prelude and the imported std functions; every builtin in its std module (decisions 575 (1), (2), (7), (8), 606)

**Repository:** botopink-lang (`--lang`), then rakun's consumer commit (165 s10) · **Model:** opus (std's bodies and the
cells' answers decide language versus defect; the file kind's removal is mechanical) · **After:** B-138

- [x] the file kind: `manifest`'s `DECLARATION_EXT` / `isDeclarationFile` / the `.d.bp`-first strip order,
      `Module.declaration` and every reader (`cli/{libs,diagnostics,bpp,resolver,scanner,check,test_cmd,config,
      format_cmd}.zig`, `language-server/src/{server,project_graph,project_index}.zig`, `lib-test-runner/src/
      discovery.zig`), `format-staged.sh`, the codemod scripts' extension lists, `cli_contract.sh`; a file still ending
      in `.d.bp` is a module named `x.d`; the cells `local_dependency` (`shapes.bp`) and `files_one_module_twice` (one
      file listed twice; its snapshot and `docs.md` stated)
      — `Env.declarationFile` kept as `Env.compilerBodies` (the prelude, the reflection cluster, `types.bp`'s `Type` (the utilities) and `compiler.bp`'s `Field<T>` / `Info<T>` (624, 630)) until the
      modules dissolve; `builtins.d.bp` / `builtins_fns.d.bp` are std modules `builtins.d` / `builtins_fns.d` until then
- [ ] no `#[builtin]`, no `@name` (606): the types and behaviors `builtins.d.bp` declares (`Result`, `Task`, `Component`, `Renderable`,
      `Iterator`, `Stream`, `Future`, `Use`, `Display`, `Closeable`, `Index`, `Slice`, `Annotation`, `Decorator`) move into
      `primitives.bp` with their bodies — the prelude, bare everywhere, a local declaration shadowing a prelude name —; the
      two functions stay, imported, inside std too: `print` in `io/terminal.bp`, `panic` in `failure.bp`; `println`, `todo`,
      `debug`, `src` removed (shortcuts, or `compiler.src`); `typeInfo` (answering `compiler.Info<T>`, the record in `types.bp`'s `Type` (the utilities) and `compiler.bp`'s `Field<T>` / `Info<T>` (624, 630)),
      `embed` (the link only: `Link` in `compiler.bp`, `Asset(link)` in `asset.bp` importing `compiler` and `io.fs`, `open()` the `File`, when by the `comptime` at the read, 607) and `external` (`Compiler.implement` folded in; `Implementation` in `compiler.bp`,
      `external.bp` gone) are members of `compiler`, written under `comptime` in a run-time body; every std decorator
      written `#[name]` — `#[compiler.external(…)]`, an annotation `#[compiler.m(…)]` calling `m` on the annotated
      declaration —, `use`, `future`, `generator`, `resultGenerator`, `Stage`, `BeamMemory` imported — a keyword collision
      (`use`) is a question; `Env.registerBuiltins`' `@` names,
      `prelude.zig`'s two embeds and the type mirrors of `comptime.zig` (`type_info_src`, `yield_step_src`, …) go — std's modules
      are parsed as std's (`registerStdlib` over the modules, `stdlibFnDecls` from them so `expandTrailingDefaults` finds `panic`'s
      default); the drift tests of `comptime/builtins.zig`, `effect_chain.zig`, `infer_decls.zig` read the modules or die; the
      codemod over every cell and every library — `@name` → `name` + the import, `@println` / `@todo` → `print(…, "\n")` /
      `panic(…)`, `@typeInfo` → `comptime compiler.typeInfo`, `@embed(p)` → `comptime Asset(compiler.embed(p))` with its reads over `File`, `@TypeInfo` →
      `compiler.Info`, `#[@external` → `#[compiler.external`, `#[@name` → `#[name` —, one commit per repository, after 165 s10's
- [ ] decisions 624, 630: `Field<T>` and `Info<T>` declared in `compiler.bp` — `compiler.Field<T>` / `compiler.Info<T>`, the 27
      std and cell files respelled in the codemod commit —; `types.bp` kept, `Type`'s five utilities as statics (628) importing
      `compiler`; `import {types.Type}` unchanged
- [ ] the modules: `Result` in `primitives.bp` with its five bodies, 118's shape kept per target, keyed to that declaration
      (609; the backends' inline lowering and the `methods` rows go; no `result.bp`); `compiler.bp` self-contained and first
      (608: `SourceLocation`, `Link`, `Implementation`, `DeclKind`, `Decorator`, `Annotation`, the handle records; no
      `reflection.bp`; `Declared*` goes with B-137's box 0; `primitives.bp` imports `compiler`; a unit test over
      `stdModuleOrder`),
      `asset.bp` (`Asset(link: Link)` with `open()` over `io.fs`, 607; `Asset.bytes` / `size` / `hash` / `text()`, `File.ofBytes`'s
      embedded copy, `openAsset`, `embed-text-not-utf8`, `embed-text-not-at-build`, `embed-open-needs-fs` go; the `embed_*` /
      `fs_asset_*` cells rewritten or removed), `print` in `io/terminal.bp`, `panic` in `failure.bp` (606), the effect
      wrappers and the ambient behaviors in the modules that own them — each declaration's reference prose moved to its
      module's section of `conformance/docs.md`, the prelude's to § Prelude (606 (5))
- [ ] removed: `module` (the cell `builtin_module_not_lowered` goes), `trap`, `field`, `TypeOf`, `makeRecord`,
      `RecordField`, `RecordKeys`, `comptimeError`, `compilerError` — their `infer.zig` arms, table rows and docs
- [ ] `libs/std/botopink.json`, `build.zig`, `analysis_entry.zig`, `test_warmup.zig`; `libs/std/AGENTS.md`,
      `compiler-cli/AGENTS.md`, `conformance/AGENTS.md`, `conformance/docs.md` (§ Builtins → § Prelude and § `compiler`, the manifest table), every
      cell `docs.md` and comment naming `builtins.d.bp`; `scripts/decisions-split.py` untouched
- [ ] cells: a prelude name bare in a program and shadowed by a local declaration; `print` imported from `io.terminal` and
      `panic` from `failure`, each on four targets; `@print` / `@Result` refused as unknown names; `Result`'s methods on
      four targets; an `Asset` read on four targets with `text()` at run time (a non-UTF-8 file an `FsError`); `#[compiler.external(…)]` on a `declare fn`, `comptime Asset(compiler.embed(…))`
      read at build and at run time, `comptime compiler.typeInfo` in a run-time body; `compiler.SourceLocation` imported by a program; the std order
      over `stdModuleOrder` (608)

Open: nothing on the maintainer — b139-a answered by decision 608 (`compiler.bp` first, no `reflection.bp`), b139-b by 609
(118's shape kept, `Result` in `primitives.bp`), b139-c by 606 (`print` in `io/terminal.bp`), b139-d answered by decision 605 (`emit` / `code` / `syntax` removed here, after 165 s10). The file kind (box 1) and
B-138's box 4 run first; the prelude move, the imports, the codemod and the modules after B-136's final package.

Oracle: the whole suite; `test-docs`; the cold gate.

### B-141 — wasm: a method on an optional's list, a coalesced list and a module's map over a component

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (each defect has a measured repro and the language's answer
is the other targets') · **After:** nothing — the builtins group's closure (§ Machines rule 9: its full gate must be green)

B-136's migration of the string `setMeta` to typed meta records found three wasm defects; commonJS, erlang and beam answer
each. Backend code only: no std, no `decorator_*` / `template_*` / `comptime_*` cell, no library.

- [x] `@typeInfo(X).meta(T)?.list.join(",")` resolves `join/1` on wasm; cell `meta_list_method_on_optional`
- [x] `(@typeInfo(X).meta(T)?.list ?? []).join(",")` answers `a,b` on wasm (it answered `296,304`: the element type
      was lost across `??`); cell `meta_list_coalesced_method`
- [x] `[1, 2].map(Card)` in a module another module imports resolves `map/1` on wasm (a lifted lambda of a linked
      module was lowered with the importer's lowerings: any primitive method in an imported component); cell
      `array_map_component_imported`; `decl_hooks_dynamic_call` on a typed `Graph` meta record, its `Page` and `Graph`
      in `src/pages.bp` (the same-module read is 419's `typeinfo-meta-hooks-pending`), its call locations now
      `@pages:…`, the graph kept

### B-142 — wasm: a generator in a linear-memory module runs its whole body at the call (decision 105)

**Repository:** botopink-lang (`--lang`) · **Model:** opus (the linear-memory lowering's design) · **After:** the
builtins group (§ Machines rule 9)

B-128 made a generator lazy in a WasmGC module; a module that falls back to linear memory still collects every item at
the call, against 105. It falls back for `@Result` items (decision 122's sugar), a `defer` in a generator body, a
`yield :l` naming an enclosing generator scope, an item type the backend cannot tell, a method over a handle other than
`for` / `.next()` / `toArray` / `take` / `drop` / `map` / `filter`, and `g.toArray()` printed directly. `@Stream` is eager
on wasm too.

- [ ] a generator's body one step per item in a linear-memory module, or the module never falls back for it (164 s2's
      WasmGC whole); a cell per fallback cause with a print before and after the first `yield`, red on wasm today,
      green on commonJS, erlang and beam
- [ ] `@Stream` on wasm one step per item, the same cell shape

### B-143 — commonJS: `push` mutates the array every binding holds, not the `var` it was called on (decisions 447 (2), 448 (2), 547)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet · **After:** B-138's box 4 (both edit `commonJS.zig`); B-137's
oracle, so the builtins group's closure (§ Machines rule 9)

A botopink value is immutable; a `var` is the one mutable cell, rebound (447 (2), 448 (2), 547; docs § Arrays: "an
array method answers a value and leaves its receiver alone, on every target"). std's `push` is a pure Erlang cell
(`($0 ++ [$1])`, `primitives.bp`) and `erlang.zig`'s `receiverMutation` lowers a statement `v.push(x)` on a `var` to a
rebinding of `v`, so `val seen = names();` keeps the list of its moment. The `.JavaScript("push")` cell is JavaScript's in-place
push: on commonJS `seen` and a caller's argument grow with the `var`. `compile_executor_module_val_order` passed on the
parent on commonJS for that reason alone, blind to 580.

- [x] commonJS lowers a statement `v.push(x)` as erlang does: the `var` `v` — a module `var` or a mutable local —
      rebound to a new array (`v = [...v, x]` or the equivalent), the old array untouched; a `push` whose receiver is
      no `var` keeps its lowering and the value, as on erlang (its refusal is no part of this step)
- [x] cell `array_push_rebinds_var` (four targets): a module `var xs: string[] = [];` with `fn add(s)` pushing;
      `val before = all();` then `add("b")`, `@print(before)` then `@print(all())` → `out ["a"]`, `out ["a", "b"]`; and
      inside a `fn`, `var ys = [1]; val snap = ys; ys.push(2); @print(snap); @print(ys);` → `out [1]`, `out [1, 2]` —
      red on the parent on commonJS, green on erlang and beam
- [x] `compile_executor_module_val_order` widened so it sees 580 on commonJS too: `val before = names();` written
      above `#[registered] pub fn own()`, printed first → `out ["second", "first", "later"]` before the four names —
      red on the parent on commonJS

- [x] `pop` on a `var` rebound on commonJS as on erlang and beam (the popped value and the shrunk array together);
      a cell where a `val` copy of the `var` keeps its length; the `.JavaScript` cells of `shift`, `unshift`, `splice`, `sort`
      and `reverse` checked for the same aliasing

Six commonJS codegen snapshots read `x = x.concat([v])`.

Oracle: the two cells on commonJS, erlang, beam and wasm.

### B-144 — erlang / beam: a chained call on a namespace member dispatches on the wrong receiver

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

Found by machine 1's 165 s10 gate: query's cell `generic_loader_binding`
(`query/conformance/modules/generic_loader_binding`, `botopink run --target erlang`) crashes
`{bp_unsupported_method,<<"join">>,1,{query@query@@Query,[4,16,36]}}`: in
`query.of(…).where(…).select(…).toArray()`, `toArray()` hands back the `Query` record and `join` is called on it.
commonJS runs it.

- [ ] the chain answers the array on erlang and beam as on commonJS; a botopink-lang cell holding the shape, red on the parent

### B-150 — wasm: a type's method handed as a record-constructor argument resolves to the module's same-named `fn`

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro) · **After:** B-142 (both edit the wasm backend)

Found by B-137's cell `init_executor_handle_not_module_name` (613). `Entry(name: "make", make: Users.make)` inside a
function, where the module also declares `pub fn make()`, stores the module's `make` on wasm: `e.make()` prints
`module make`, commonJS, erlang and beam `users made`. `val f: fn() -> string = Users.make;` is right on wasm.

- [ ] `Users.make` as a constructor argument is the type's method on wasm; the cell `init_executor_handle_not_module_name`
      (four targets, red on the parent on wasm) and a plain-program cell beside it

### B-147 — erlang / beam defects found by 165 s5

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (measured; repros in rakun's `AGENTS.md`)

- [ ] erlang: `m.make().run(s)` (a method call on a value a static call answers) emits `run/2 undefined`
- [ ] erlang: `await f().make()` in a component body never runs the component (binding it to a typed `val` first works)
- [ ] beam: a `for` lambda loop loses a module (rakun loops by index), and `registry.find("store")?.name ?? "none"` answers `none` where the entry exists

### B-148 — the primitive widths are types; a behavior is a contract and carries no cell (decision 617)

**Repository:** botopink-lang (`--lang`) · **Model:** opus (std's bodies and the backends' dispatch decide language versus defect) · **After:** B-139 (which moves the prelude into `primitives.bp`) · **Before:** B-140

Today every declaration of `libs/std/src/primitives.bp` is a behavior: `Number`, `Integer extends Number`, `Signed`, `Float` are contracts, and the widths are empty behaviors (`behavior I32 extends Signed {}`, `I64`, `U32`, `U64`, `F32`, `F64`); `infer.zig` maps `i32` to `I32`, and each backend writes the chain `I32 → Signed → Integer → Number` by hand (`erlang.zig` `prim_iface_chain`, `commonJS.zig` `numeric`, `wat.zig` `prelude_names`, `beam_asm.zig`). Twenty members carry a body and cells on one declaration (`default fn isEven` with `.JavaScript(…)`), the body the fallback of the targets without a cell.

- [ ] decision 639: a module declaring `i32` / `i64` / `u32` / `u64` / `f32` / `f64` / `bool` / `string` / `bigint` refused at the name,
      `primitive-type-redeclared` (a literal's type is not shadowed; every other prelude name shadows as 606 (1)); cell
      `primitive_type_redeclared`
- [ ] `pub type i32 implement Signed { … }` and its siblings declared in `primitives.bp` (`bool`, `string`, `Bytes`, `BigInt`, `Array<T>`, `Pair<A, B>`, `Function` as 617 (1) applies); the six empty behaviors go; `infer.zig`'s width table and the four backends' chains replaced by a read of the `implement` clauses — one resolution, from the text
- [ ] decision 641: the primitive types lowercase (`bool`, `string`, `bigint`, `bytes`, `array<T>`), `String` / `Bool` / `BigInt` / `Bytes` /
      `Array` dissolved into them, their statics on the type with their cells (`string.fromCodepoint`, `array.range`, `bytes.fromUtf8`);
      the 2,500 sites respelled by codemod (std and the cells here, the libraries in their fronts); cells `primitive_static_on_type`,
      `primitive_contract_dissolved`
- [ ] every behavior of the file holds signatures and `default fn` bodies only — no `#[compiler.external(…)]` on a behavior member (refused there, `external-on-behavior`, at the annotation); the 87 cells move to `declare fn` members of the types, `Self` concrete; a member one target runs in botopink and another in the host uses 610's `.Wasm(body: f)` on the type
- [ ] a type overriding a contract's `default fn` by declaring the member itself, with or without cells; the override checked against the contract's signature
- [ ] decision 628 (window: 640 (4) — rakun's and query's one-line commits land with it, machine 1 told the hash): a behavior's member without `self` is a static written `fn` (with a body, the behavior's own; without, provided by each implementor); `default` on it refused `default-on-static`; the 56 `default fn` without `self` (std 10, the cells 44) drop `default` by codemod, the libraries' in their fronts; `conformance/docs.md`'s "associated `default fn`" rewritten
- [ ] `implement-with-body` on a behavior's `default fn` (617 (4)): the B-138 box above lands here
- [ ] every cell of `tests/language` green on four targets before and after — the answers of the primitives do not change, only where their code is written; `conformance/docs.md` § Primitives rewritten (the widths as types, the contracts, where host code lives); `libs/std/AGENTS.md`
- [ ] cells: `primitive_width_is_a_type` (`i32` in a type position and `implement Signed` read), `external_on_behavior` refused, `primitive_default_fn_overridden` (a width's own cell beside the contract's body, four targets), `implement_with_body` with the behavior case

Oracle: the whole suite on four targets; `test-libs`; the cold gate.

### B-149 — no code from text: the typed AST and `compiler.ast` (decision 625)

**Repository:** botopink-lang (`--lang`) · **Model:** opus (the node vocabulary and the cells' answers decide language versus defect) · **After:** B-137's tail (616's arrivals) · **Before:** 165 s11

Today a template's body answers code as a string — `compiler.build(code)` after concatenating botopink source (113 sites: the template cells; rakun-bpp's `html.bp` generator, 1,400 lines) — and `Type.pick` / `omit` / `partial` / `required` / `merge` write a record's text for `compiler.buildType(text)` (23 sites). Decision 625: code enters the compiler written (a `syntax` parameter, a template text) or as the typed AST, never as a string.

- [ ] the `Node` records in `compiler.bp`, one per kind the parser's `ast.Expr` has that a template may answer (`Call`, `Name`, `Lit`, `List`, `Arg`, `Lambda`, `Record`, `Field`, `If`, `Case`, …) — the vocabulary measured off the parser and written in `conformance/docs.md` § `compiler.ast`; a kind no template needs is not exposed
- [ ] `fn ast(self: Self, comptime node: Node) -> anyvalue`: the tree checked and lowered where the call stands (426 (1)); an ill-formed tree (an `Arg` outside a `Call`, a `Name` nothing binds) refused at the `ast` call naming the node
- [ ] **P1b, `code.bp`** (637, 625 (4)): the std module whose template `code` turns code written with `${…}` holes into the AST, a hole a build value (a literal) or a `syntax` value (spliced as written); `compiler.holes(syntax t: string) -> unknown[]`, the caller's holes as `syntax` values; `Syntax(e)` the node `code` emits for a `syntax` hole (638), the 8 receiver-by-text cells over `code`; the 11 hole cells and every template cell rewritten over `code` in P2 — no `Hole(index)` node
- [ ] `compiler.build(source: string)` removed — `compiler_surface.zig`, the readers, 578 (3)'s text in `docs.md`; the 14
      `decorator_add_type*` cells written `compiler.addType("Columns", type(id: string))` (640 (2)); `compiler.ast` admitted in a
      decorator body with a cell (640 (3)); the builders' surface, `mocks.bp` and `build_type_from_fields` are this step's, `Type`'s
      bodies and `derived_types.zig`'s reduction B-140's (640 (1)); `buildType(self, comptime name: string, comptime fields: compiler.Field<unknown>[], comptime implements: anytype[] = []) -> anytype` and `buildTypeInline(self, comptime fields: compiler.Field<unknown>[]) -> anytype` (629), the record-text form gone
- [ ] the std bodies: `Type.pick` / `omit` / `partial` / `required` / `merge` over `buildType(name, fields)`, `mocks.bp`'s type over `implements:`; the template cells rewritten over `compiler.ast` (`bpp_*`'s `deps/markup`, `template_*`); `compiler.text(t)` unchanged
- [ ] cells: `template_answers_ast` (four targets), `ast_ill_formed_refused`, `build_type_from_fields`, `compiler_build_removed` (refused as an unknown member)
- [ ] after it, 165 s11 (machine 1): rakun-bpp's `html.bp` and rakun-style over `code` / `compiler.ast`

Oracle: the template cells on four targets; `test-libs`; the cold gate.
