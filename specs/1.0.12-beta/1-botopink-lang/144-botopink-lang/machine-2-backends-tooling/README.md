# Front 144 — machine 2: backends, runtimes, std, tooling and the gate (lanes B and C, the cache group)

The steps of [front 144](../README.md) this machine runs: its goal, priority, ownership, order, lanes, the rules the two
machines share and the alias table are the front's README; each step below is as it was there, unchanged. The
other machine's steps are in [`../machine-1-checker/`](../machine-1-checker/README.md). A step keeps its id (`B-NN`) wherever it sits.

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

Every target's comptime evaluation runs on the wasm runtime (wasm3 in-process, `persistent_wat.zig`,
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
fresh wasm3 environment, parse and load of the linked module, `persistent_wat.zig`; BEAM: frame round
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

Stage split of the N=200 build (E-2, ms per evaluation), before → after: wat `instance` (fresh
wasm3 environment, runtime, parse, load) 0.336 → 0.035 (the kept instance's reset), `run` (bp_init
through the reply, wasm3's lazy compile included) 0.374 → 0.111, `module` 0.218 → 0.165 (no
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

- [ ] `effect-try-without-fallible-channel`'s message names `try … catch` and `throws: true`; `docs.md` § Results, § Host bindings

#### B-01 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-03 — 431 (2): `throws:` on every `@External` variant, checked

**Repository:** botopink-lang (`--lang`)

`builtins.d.bp`'s External variants gain `throws: bool = false`; `refuseThrowsReturn` (`throws: true` only on
`@Result<…, failure.HostError>` or `@Task` of one); `ast.externalRefOf` trims every bool flag. Questions
`decision 487`, `decision 488`.

**Impacted tests:** new `reject/external_throws_return`; `comptime/tests/effect_{future,generator}.zig`;
`infer_decls` drift. **Model:** opus. **Consumer commits:** none (B-08 carries them).

#### Step 42 — a host binding that throws answers a `@Result` (decision 431) — part (was `01-checker` s42 box 1)

```bp
#[@External.Node("JSON.parse($0)", throws: true), @External.Erlang("json:decode($0)", throws: true)]
declare fn jsParse(s: string) -> @Result<Json, HostError>;
val doc = try jsParse(texto);                      // a JS SyntaxError / an erlang raise is Error(HostError(…))
```

- [ ] `throws: true` on every `@External` variant, a `bool` at the last position (as `inline:`); refused unless the
      declared return is `@Result<…, HostError>` or `@Task<@Result<…, HostError>>` — `reject/external_throws_return`

#### B-03 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-04 — 431: std `failure` — `HostError`, `Failure`

**Repository:** botopink-lang (`--lang`)

**Impacted tests:** `test-libs --lib std`; `run/std_failure_attempt` (with B-07). **Model:** sonnet. Question
`decision 492` (the kinds). **Consumer commits:** none.

#### Step 18 — `failure`: `HostError`, `Failure`, `attempt` (decision 431; with `01-checker` step 42) — part (was `97-std-dedupe` s18 box 1)

- [ ] `libs/std/src/failure.bp`: `pub type HostError(message: string, kind: string)`, `pub type Failure(message: string,
      kind: string)` (`panic` / `host` / `crash`), `pub fn attempt<T>(f: fn() -> T) -> @Result<T, Failure>` and its `@Task`
      form — a cell per target; `root.bp` gains `pub mod failure;`

#### B-04 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-05 — 431 (2): each backend wraps a `throws: true` cell

**Repository:** botopink-lang (`--lang`)

commonJS: a sync binding in a `try/catch` answering `{ok}` / `{error: HostError(e.message, kind)}`, a `@Task`
binding's rejection a `HostError` rejection, `__bp_host_task` only under `throws: true` (`decision 490`); erlang and
beam: `try … catch Class:Reason` building `HostError` (`decision 489`); wasm: the `wasi:` adapter's error, `throws:`
refused on `op:` / `fn:` (`decision 491`). Consequence of 431 + 432, recorded (no question): a `throws: true` `@Task`
binding on commonJS rejects with `HostError(e.message, e.name)`.

**Impacted tests:** new `run/external_throws_host_error` (four targets); `run/host_node_task_result` rewritten;
the host-task JS snapshots; the erlang / beam columns (`run/host_erlang_task_result` unchanged). **Model:** opus
for the shape, sonnet per backend. **Consumer commits:** none.

#### Step 42 — a host binding that throws answers a `@Result` (decision 431) — part (was `01-checker` s42 box 2)

- [ ] each backend wraps the cell (commonJS `try/catch`, a rejected Promise; erlang and beam `try … catch Class:Reason`;
      wasm the `wasi:` adapter's error) — handed to 02–05 —, `run/external_throws_host_error` on the four targets

#### B-05 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-06 — 432: a failing task rejects, on four targets

**Repository:** botopink-lang, with consumer commits in jhonstart, rakun (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

- [ ] erlang and beam end a failing task's process with `{error, E}`; the wasm scheduler settles the task with
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

- [ ] a `@Task<@Result<T, E>>` lowers to an `async function` whose `Error(e)` / `throw e` rejects with `e` and whose success
      resolves with the bare `T`; `await` under `try` / `case` reads a rejection as `Error(e)`; the `.d.ts` names `E` —
      `run/task_result_rejects`, `run/task_result_caught_by_js` (a JS caller's `try/catch`), the `snapshots/codegen` that
      print `{ Ok }` / `{ Error }` for a task re-recorded
- [ ] `js/AGENTS.md`'s 179 row (no `unwrapOrThrow`) rewritten for 432

#### Step 2 — declare the rest — part (was `134-builtins-declared` s2 box 4)

- [ ] `Task`'s surface for 432: `map`, `then` on every `@Task<T>`; `mapError`, `catch` on `@Task<@Result<T, E>>` (a
      second declaration over the nested form); no `flatMap` — the drift test follows

#### B-06 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-07 — 431: `attempt`, and the asserts over it

**Repository:** botopink-lang, with consumer commits in jhonstart (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

Then jhonstart's `__jhTryValue` / `__jhTryTask` go, in jhonstart's consumer commit (its renderer, 388 / 414, landed). Questions `decision 493`,
`decision 494`; wasm `decision 491`.

**Impacted tests:** `run/std_failure_attempt`; `run/std_asserts_host_cell_on_wasm`; the 82 files calling
`throws` / `throwsWith` / `tryCatch`. **Model:** sonnet. **Consumer commits:** jhonstart (the `__jhTry*`
replacement).

#### Step 18 — `failure`: `HostError`, `Failure`, `attempt` (decision 431; with `01-checker` step 42) — part (was `97-std-dedupe` s18 boxes 2, 3)

- [ ] `testing.asserts`' `throws` / `throwsWith` over `attempt`, the private `tryCatch` cell gone; jhonstart's
      `__jhTryValue` / `__jhTryTask` replaced by `attempt` in `05-jhonstart/26` step 14 (a consumer row below)
- [ ] `run/std_failure_attempt` (a panic, a host raise, a value) on the four targets; `libs/std/AGENTS.md`'s table

#### B-07 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-08 — 431: std's hand-written catches become `throws: true`

**Repository:** botopink-lang, with consumer commits in onze, rakun, snap, validation, jhonstart, log, http, routing (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

std's hand-written try/catch templates are boundaries by hand (fs 11 Node + 2 Erlang, json 3+3, encoding 1+3,
hash 1+1, regex 1, async 3, primitives 1, http 1, process 1, clock 1, asserts 1+1 — measured on botopink-lang
`feat`); a binding that raises without catching is a crash under 431 (2). Questions `decision 486`, `decision 495`.
Sequence with 142 s1 (`json` leaves std, B-27).

- [ ] every std binding that catches by hand declares `throws: true` and answers `@Result<T, failure.HostError>`,
      or maps `HostError` into the typed error a decision names (`HttpError` 393 / 335, `StoreError` 304,
      `ActionError` 303), per `decision 486`; no hand-written `try` / `catch` template left in `libs/std/src`
- [ ] every binding that raises without catching audited: `throws: true`, or documented in its module as
      promising no raise (`decision 495`); the list in `libs/std/AGENTS.md`

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

- [ ] `Bytes` in `builtins.d.bp` / `primitives.bp`: an immutable byte sequence; `Bytes.fromUtf8(s: string)
      -> Bytes`; `b.toUtf8()` answering `@Result` (an `Error` on invalid UTF-8)
- [ ] no conversion between `string` and `Bytes` without those calls: a string literal where `Bytes` is
      expected, and `Bytes` where `string` is, are located mismatches (`reject/` cells)
- [ ] a host cell may take and answer `Bytes`; the lowering is each backend's (an Erlang binary, a
      `Uint8Array` on commonJS, a buffer in wasm memory — 02–05), one `run/bytes_round_trip` cell on the
      four targets
- [ ] the rest of the surface (length, slice, concatenation, `encoding`'s bridges) written in the step's
      commit under 67; `docs.md` § Primitives (07's prose) and `language-gaps.md`'s byte row point here

#### Step 33 — `@embedFile` / `@embedBytes` checked (decision 342) (was `01-checker` s33)

- [ ] `@embedFile(comptime path: string) -> string` and `@embedBytes(comptime path: string) -> Bytes` in
      `builtins.d.bp`, callable in any context; a `path` not known at compile time is 280 (0)'s error at
      the argument; an absolute path or one leaving the package (`..`) refused at the argument (`reject/`
      cells); the read itself is `14-comptime-on-beam` step 6's

#### Step 6 — files at compile time (decision 342) (was `14-comptime-on-beam` s6)

- [ ] 342: `@embedFile` / `@embedBytes` read the file relative to the `botopink.json` of the package that
      wrote the path (the application's for a decorator annotating its declarations; the member's in a
      workspace); a missing file, or a non-UTF-8 one for `@embedFile`, is a compile error at the call; the
      content hash enters the cell's cache key (with 26 for watch and the LSP); `rakun ws generate`'s
      checked-in `.bp` can go (rakun 93). Waits on `01-checker` (the builtins' declaration in
      `builtins.d.bp` and their checking) and 346 (`Bytes`, not built); this front's half is the
      package root on `Module` and the read at the call

**Gate:** standard (fronts.md § Gate) + `scripts/snap_audit.sh --mode=runtime-parity` green, every
re-recorded listing classified, `COMPTIME REPLY` byte-identical at every step ·
`scripts/beam_export_audit.sh` green (comptime listings included)

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

- [ ] `run/` cell: a method `-> @Result<i32, string>` with `return 1`, `throw "x"` and `try other()` answers `{ok, 1}`, `{error, "x"}` and the propagated error — same as the module-level fn cell
- [ ] the same cell on js (no change expected; asserted)
- [ ] a behavior method (`KeyValueStore.get`) declared `-> @Result` dispatches and wraps the same

#### B-13 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-19 — 216, 281, 298, 353, 356: decorator outputs

**Repository:** botopink-lang, with consumer commits in rakun, jhonstart, validation, styled (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `tests/language` `@emit` cells (become `reject/`), `run/meta_*`, `run/template_reads_program_catalogue`.
**Model:** opus. **Consumer commits:** rakun (the remaining `@emit` sites, typed meta — each a decision-188
commit after the owning rakun step), jhonstart (`#[page]`, `#[client]`), validation, styled (the catalogue).

#### Step 5 — migrate the remaining sites (was `130-decorator-outputs` s5)

Decision 318 shrinks rakun's list before it migrates: `#[service]`, `#[managed]`, the core's `#[repository]`,
`#[restController]`, `#[configuration]` / `#[bean]`, the four transport listeners and `#[httpExchange]` are
deleted by the owning rakun fronts (04 step 8, 13 step 6, 15 step 8), not migrated; only their
replacements are written here in 216's forms.

Member names are the library's (decision 174's note). Remaining `@emit(` at feat — a closed list
(373: no front writes a new site, the count only shrinks): rakun 67 lines, jhonstart 1 (`#[page]`'s
`<X>Params`), validation 1. Rakun rows target post-128 paths
(`04-rakun/README.md` § Order, decision 339): no 130 rakun commit while `04-rakun/128` is open; after it, each a consumer commit under
decision 188, never in a wave with the rakun front owning the file.

| File | Sites | Generated today | New form | Written against |
|---|---|---|---|---|
| rakun `rakun/src/{decorators,autoconfig,config,context}.bp`, `rakun-web/src/convention.bp`, `rakun-data/src/sql/transactional.bp`, `rakun-security/src/method_security.bp` | ~29 | member `T.make()` (`rkSingleton`) on each stereotype; a `#[bean]` method emits `val __rkBeanM_<T>_<m> = rkRegisterBean("<return type>", …)` (`rakun/src/decorators.bp:333-385`); `<T>Tx` proxy + `val __rkTx_<T> = rkRegisterBean(…)` (`transactional.bp:81-82`), `<T>Sec` proxy + `pub fn __rkMake_<T>Sec()` (`method_security.bp:141-142`) | member `T.make()`; the registry built at comptime from `@TypeInfo.all(with: …)`, never keyed by a name string (281, 256; `ctr-q` closed) | 234 (`T.make()`, by-type injection), 254 (catalogue answers `Declared<unknown>[]`; `rkResolve<T>` narrows with `is fn() -> T`), 256 (registry built at comptime at the entry point), 281 (amends 234/256 where they key by a type's name, and `member: "make"`) |
| same files + `lifecycle.bp`, `conditions.bp`, `rakun-data` `entity.bp` / `query.bp` | ~27 | `val __rkScan_<T>`, `__rkBean_`, `__rkLc_`, `__rkEv_`, `__rkImp_`, `__rkExit_`, `__rkAutoQ_`, `__rkCat_`, `__rkChk_`, `__rkEnable_`, `__rkEntityReg_`, `__rkQueryReg_` (load-time registration) | `@TypeInfo.all(with: …)` read at comptime (member by reference, step 7) | 235, 234, 254, 281 |
| `rakun-web/src/convention.bp`, `rakun-app/src/{route_handler,actions}.bp`, `rakun-websocket`, `rakun-scheduling`, `rakun-messaging`, `rakun-cli`, `rakun/src/actuator_api/**` (today `rakun-actuator-api`, moved by 128 step 1), `rakun/src/decorators.bp` routes | ~25 | `val __rkFilter_`/`__rkConverter_`/`__rkCustomizer_`/`__rkCors_`/`__rkAdvice_`/`__rkMiddleware_`/`__rkHandler_<VERB>_`/`__rkRoute_`/`__rkWs_`/`__rkSched_`/`__rkJob_`/`__rkCli_`/`__rkEp_`… | meta (`order`, `media`, `path`, `verb`) + `@TypeInfo.all` at the entry point | 235; 236 for `#[middleware]`'s gate; 234 |
| `rakun-client/src/exchange.bp` | 2 | `pub type Http<T>` + `pub fn http<T>()` | `T.Http` + a factory member | held: behavior member called from another module fails (below) |
| jhonstart `routes.bp` | 1 | `pub fn <X>Params(route)` (the four registrations are done) | none — the page takes no parameter and reads `use params<P>()`, checked by `#[page]` over `Decl.hooks` | 293 (amends 236's `paramsOf`); held: `05-jhonstart/26` step 11 after `01-checker` step 23, and the segment walk inside it is `03-bundled-libs/102` step 3's while 102 is open |
| validation `#[schema]` (`libs/validation/src/decorators.bp`) — `#[validated]` after 306 | 5 | `pub fn parse<T>At`, `parse<T>`, `decode<T>`, `schemaOf<T>` + helpers | members `T.parseAt/parse/decode` (no `schema` — `Schema<T>` is private, 306) | nothing — next; `decode` passes `parse<T>At` as a value (unbound variable on erlang, below), so wrap it in a lambda |

- [ ] each library's hook green on this compiler; `grep -rn '@emit(' --include=*.bp repository/`
      answers only `tests/language` cells about `@emit` itself

#### Step 6 — remove module-level `@emit` (was `130-decorator-outputs` s6)

`@emit` a named error everywhere (message lists the four places); `tests/language` `@emit` cells
become `reject/` cells; `docs.md`'s "Decided, not yet implemented" row leaves; `language-gaps.md`
closes **An emitted `pub val` is visible to other emitted code only** (T15) and **No comptime
reflection over the project** (declaration half; the `@project()` manifest half is not 216's).

- [ ] the refusal and the cells; the two `language-gaps.md` rows closed

#### Rows found during the migration (open, not 216's places) (was `130-decorator-outputs` rows)

- [ ] a `behavior`'s associated `default fn` called through the behavior from another module
      (`Shape.unit()` with `import {shapes.Shape}`): unknown erlang module on erlang/beam, run-time
      error on commonJS, refusal on wasm — members do not travel with a behavior as with a type
      (holds `rakun-client`'s two sites)
- [ ] an associated fn read as a value (`apply(City.make, …)`) is an unbound variable on erlang
- [ ] a member's / associated type's diagnostic is located past the file's last line (member source
      placed after the module's lines) and names `City__Columns`, not `City.Columns`
- [ ] a decorator imported from another module whose body builds a record private to its module fails
      at the evaluator (`call to undefined function Entity/1`): `block_eval.typesReached` finds an imported
      decorator's types through the export registry only — string meta and typed meta alike (found by
      step 8; `01-checker` step 21 owns `block_eval.zig`)

#### Step 7 — references, not strings (decision 281) (was `130-decorator-outputs` s7)

- [ ] `@TypeInfo.all(with: …, member: "make")` (256) names the member by reference — an interface's
      method — not by string; `Declared.value` stays `unknown` (254; `nat-a` answered by 281)

#### Step 8 — typed meta, keyed by its type (decision 298) (was `130-decorator-outputs` s8)

`Decl.setMeta(value: T)` — one value per type per declaration, a second of the same type refused at
the call —; `Decl.addMeta(value: T)` for what repeats; read `@typeInfo(X).meta(T) -> ?T`,
`@typeInfo(X).metaAll(T) -> T[]`, and `Declared.meta(T)` in `@TypeInfo.all`'s answer. Comptime only
(280 (0)). `setMeta(key: string, value: string)` and `.meta.<decorator>.<key>` go.

Built (see § Done): the typed surface, its reads, the catalogue's and 370 (1)'s `@Expr<T>` fields. The
string form stands beside it until the last box: rakun's sites wait on `04-rakun/128` (decision 339),
and `Declared.meta` / `TypeInfo<T>.meta` stay `DeclaredMeta[]` fields until then (the typed reads are
calls the checker answers, so the two coexist).

- [x] `builtins.d.bp`: `setMeta(v)`, `addMeta` on `Decl`; `meta(T)`, `metaAll(T)` on `@typeInfo(X)` and
      on a `Declared<T>` entry, answered by the checker (`TypeInfo<T>`'s and `Declared<T>`'s `meta` fields
      keep the string form until the box below)
- [x] `run/meta_typed` — `#[entity("cities")]` sets `Entity(table: "cities")`, `meta(Entity)?.table ==
      "cities"`; two `#[index]` add two `Index`, `metaAll(Index).length == 2`; `meta(Other)` is `null`
- [x] `reject/meta_twice` — two `setMeta(Entity(…))` on one declaration, at the second (annotation)
- [x] a meta record may hold `@Expr<T>` fields (370 (1)): `decl.addMeta(Check(message: message, rule:
      rule))` built in the reading program with each expression spliced where it was written —
      `run/meta_expr_field` (the reader calls `rule` and evaluates `message` at run time, on the four
      targets)
- [ ] the std and library sites migrated (rakun's `#[entity]` and the stereotypes, jhonstart's `#[page]`
      and `#[client]`), then `setMeta(key, value)`, `.meta.<decorator>.<key>` and `DeclaredMeta(key,
      value)` gone (`Declared.meta` / `TypeInfo<T>.meta` the typed reads only)
- [ ] a meta field of a record type, a `Type.Field<T>` (364 (2)'s data family) or a tuple: refused
      today (`decorator-meta-field-type`); rebuilding one where the meta is read needs its names in the
      reader's scope (an `@Expr<T>` field carries such a value as written)
- [x] an `@Expr<T>` meta field read in another module resolves its names where the annotation wrote them
      (385): each module publishes its scope (`Reflection.scopes`, `comptime/written_names.zig`), and the
      reader binds every name the annotation's arguments wrote under an unspellable alias, a private one
      exported as `templatePrivateKey` (the annotation's module shares its privates, `pub` for the
      backends only); `typeinfo-meta-expr-elsewhere` gone — `modules/meta_expr_read_elsewhere` runs
      (`main` reads `signup`'s `Check` and calls its private `passwordsMatch`, its own `passwordsMatch`
      and `hint` not captured; the `@TypeInfo.all` route the same through `d.metaAll(Note)`, a non-generic
      record — a generic one through an entry is `130-s8-d`) on the four targets
- [x] a typed member reads its own type's typed meta (395): pre-comptime, `@typeInfo(T).metaAll(Check)` with `T`
      the decorator's type parameter accepted and typed `Check<T>[]` in the decorator's body, the body checked
      against it; post-comptime, the member rendered into the annotated type's module with `T` spelled as the
      type, the read answered and the member checked again; `comptime @typeInfo(X).metaAll(T)` is the checker's
      answer (no comptime runtime), `for (comptime …)` parses — `run/member_reads_own_meta` (`#[validated]` over
      two `#[check]`s: `validate()` runs both rules, the list a build constant under `comptime`) on the four
      targets; `typeinfo-unknown-declaration` no longer raised for a bound type parameter
- [x] questions `130-s8-a` → 418, `130-s8-c` → 419, `130-s8-d` → 420 (`130-s8-b` → 385, `130-s8-e` → 395): one type set and added, a `.hooks` reader's typed meta read in its module, a generic record through a
      catalogue entry

#### Step 10 — a template body reads the program's catalogue (decision 353) (was `130-decorator-outputs` s10)

A library's template function calls `@TypeInfo.all(with: …)` and gets the catalogue of the program
that expands the call — `styled` finds the application's one `#[theme]` (119 step 1 box 5).

```bp
// styled/src/styled.bp, inside `pub default fn styled(comptime css: @Expr<string>)`
val themes = @TypeInfo.all(with: theme);   // the application's #[theme] declarations
if (themes.length > 1) css.fail("styled: two #[theme] declarations: …");
```

- [x] a decorator on a `val` runs (356): `DeclKind.Val`, `name`, `returnType` as written; `setMeta`
      legal, `addMember` / `addType` refused at the annotation; the `val` catalogued —
      `reject/val_decorator_runs` (`#[mark] pub val one = 1;` fails with the decorator's message; a
      refusal is target-independent, so a `reject/` cell) and `run/val_decorator_catalogue`
- [x] `@TypeInfo.all` in a template function's body answers for the calling program, after every
      module's decorators; the reader is exempt from `typeinfo-all-imported` (256's entry-point
      rule unchanged for every other reader)
- [ ] a `Declared`'s `value` readable at build: a `val` with a `comptime` initializer lifted into the
      template's module as a literal (356), refused at the read otherwise
      (`typeinfo-all-template-value`); a comptime `extendTheme(…)` holding `ThemeValue.Rem(…)`
      evaluates (row 133)
- [x] the importer of a reader module that breaks the rule gets `typeinfo-all-imported` at the
      import, not `unbound variable '<template>'` at the use (row 134's diagnostic half)
- [ ] `run/template_reads_program_catalogue` (one and two built as `modules/template_reads_program_catalogue`, `modules/template_catalogue_two_themes`; none still answers an empty catalogue — 358's refusal open) — a package's template function counting the importing
      application's `#[theme]` declarations: none (refused, 358), one, two (refused at the second, naming both)

**Gate:** standard (fronts.md § Gate) + std on commonJS and erlang; each library's hook

#### B-19 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-24 — 319, 320, 332: numbers and strings exact everywhere

**Repository:** botopink-lang, with consumer commits in rakun, jhonstart, onze (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

`bigint`'s rest (139 landed as bigint-139; its two open boxes) then `Decimal` and `Json`'s numbers. Questions `decision 496`, `decision 497`,
`decision 500` (whether 142 s1 goes first and the `Int` / `BigInt` / `Dec` arms land in the json repository).

**Impacted tests:** `run/json_numbers_exact`, `run/i64_*`, the clock cells. **Model:** sonnet, opus for 139's
checker half. **Consumer commits:** rakun (3 files), jhonstart (2), onze (2) — the `Json` `case` arms.

#### Open (was `139-bigint` open)

- [ ] decision 501's alternatives, if the maintainer answers (b) or (c): `is bigint` by value range, a
      `bigint` in `unknown`, compile-time `bigint` in the folder and the comptime runtimes (14 · 18)
- [ ] wasm: a `bigint` member of a union (`lowerAsUnknown` refuses it located, "has no `bigint` in a
      union yet"; erlang, beam and commonJS run it) — a `05-wasm` row

**Gate:** standard (fronts.md § Gate) + `zig build test-language` (the four targets) and
`scripts/tsc-check.sh`.

#### Step 9 — `i64`, `u64`, `isize`, `usize`: a number, a `BigInt` past 2^53 (decision 319) (was `04-js` s9)

Today these four lower to JS numbers and 264's check bounds them at ±(2^53−1)
(`ArithKind.rangeExactDouble`): `9007199254740991l + 1l` aborts on commonJS and answers on the other
three targets. After, they keep the full range at a low cost: a value within ±(2^53−1) stays a JS
`number`, a value beyond it is a `BigInt`, always in that canonical form.

```js
function i64add(a, b) {
  if (typeof a === "number" && typeof b === "number") {
    const r = a + b;
    if (Number.isSafeInteger(r)) return r;        // the common case: today's cost
  }
  return norm(BigInt(a) + BigInt(b));             // promoted; checked against ±2^63, back to number when it fits
}
```

- [x] lowering: every operation on the four types (`+ - * / %`, unary `-`, the compound assignments,
      comparisons) through a prelude helper with the number fast path; the slow path computes in
      `BigInt`, aborts past −2^63 … 2^63 − 1 / 0 … 2^64 − 1 (`__bp_int`), and answers the canonical form;
      a literal is a number when safe, else `123…n`; `rangeExactDouble` deleted
- [ ] canonical form kept by every producer (operations, literals, conversions, `Json`, host templates)
      — operations and literals done; `Json` waits on 332 (`139`, then `02/97` step 15's `Json` integer); std's `Math.min`/`max`/`abs` cells and
      `Integer`'s `default fn`s (`isEven`, `clamp`) throw a `TypeError` on a `BigInt` (97 step 13):
      `==` stays `===`, a `Dict` / `Set` keyed by `i64` keys by value — one cell each across the 2^53 edge
- [ ] conversions explicit and exact (no `toF64()` / `toI32()` is declared anywhere yet — std surface first):
      widening `i32 → i64` is free (already canonical); `@print` and string interpolation print the digits
      (no `n`)
- [x] a Node host template taking or answering one of the four types sees `number | bigint` (canonical);
      the emitted `.d.ts` types them `number | bigint`; `scripts/tsc-check.sh` green
- [x] cost measured: a loop of i64 additions below 2^53 within 10% of today's `int_check` build (the
      number recorded in `js/AGENTS.md`)
- [x] `run/i64_full_range` (`9007199254740991l + 1l`, `9223372036854775807l`, `-9223372036854775808l`, the
      `u64` top, a value crossing back below 2^53, an overflow past each bound) answers alike on the four
      targets; `run/int_overflow_mul_i64` re-recorded — commonJS now aborts where the others do
      — the minimum is written `-9223372036854775807l - 1l` (the checker refuses
      `-9223372036854775808l`: the literal's digits are past `i64`, a `01-checker` row); the `u64` half is
      `run/int_overflow_add_u64_max`, red on wasm only (prints the top as `-1`, traps on
      `18446744073709551614ul + 1ul`; a `05-wasm` row)
- [ ] `docs.md` § Integer overflow's commonJS paragraph rewritten (handed to `07-residuals`, owner of the prose)

#### Step 13 — std over the hybrid `i64` on commonJS (decision 319; with `04-js` step 9) (was `97-std-dedupe` s13)

- [ ] `io/clock`'s `formatIso8601`, `toCivil` and `offsetMinutes` given an epoch past ECMAScript's
      time range (every `BigInt` epoch): question `decision 497`; `parseDuration`'s 2^53 − 1 bound after
      319: `decision 498`; `fs.stat`'s `mtime` resolution (ms on Node, s × 1000 on erlang): `decision 499`
- [ ] `Json`: an `i64` written as its digits (the read half is step 15's `Int` node, 332)
      (`9223372036854775807l` round-trips on commonJS through `Int`)
- [x] `string.parseInt()` answers `Error` only past the `i64` range (176 as amended by 319):
      `run/string_parse_int_i64_range` on commonJS, erlang and beam; wasm's half is `05-wasm`'s
      (`stringSlice0/2` unresolved, pinned by `.wasm.expect`)
- [x] `min` / `max` / `abs` / `clamp` and `Integer`'s `isEven` / `isOdd` answer past 2^53 on commonJS
      (the numeric tower is patched on `BigInt.prototype` too — a carve-out in `04-js`'s
      `commonJS.zig` `prototypeAssign`; std's Node forms take either kind):
      `run/i64_number_methods_past_js_safe`; wasm refuses an `i64` receiver (`05-wasm` row);
      `abs` of the minimum is question `decision 496`
- [x] the explicit conversions `toI32()`, `toI64()`, `toU32()`, `toU64()`, `toF64()` declared on
      `Integer`, aborting when the value does not fit, never rounding: `run/integer_conversions_exact`,
      `run/integer_conversion_to_i32_aborts`, `run/integer_conversion_to_f64_inexact_aborts` on
      commonJS, erlang and beam; wasm has no row for them (`05-wasm`, pinned by `.wasm.expect`)

#### Step 14 — erlang counts codepoints, not grapheme clusters (decision 320) (was `97-std-dedupe` s14)

`primitives.bp`'s Erlang templates for `length`, `at`, `slice`, `indexOf`, `lastIndexOf` call
`string:length/1` / `string:slice/3`, which count grapheme clusters: `"e\u{301}".length` is 1 on erlang
and beam, 2 on wasm.

- [x] the five templates count codepoints (`unicode:characters_to_list/1`, re-encoded with
      `unicode:characters_to_binary/1`; the slice helpers normalise bounds as the Node forms do), on
      erlang and beam; `02-erlang` step 15's cell green there; `libs/std/AGENTS.md` § One unit
- [ ] std's Node templates for the five take and answer codepoint indices (`04-js` step 10's helpers)
- [ ] `docs.md` § Strings states the unit — codepoints on every target — handed to `07-residuals` (the prose)

#### Step 15 — `Decimal` and `Json`'s numbers as Jackson reads them (decision 332; after `01-compiler/139`) (was `97-std-dedupe` s15)

- [ ] `Decimal` in std (`math/decimal.bp` or the module the front names): an unscaled `bigint` and a
      `scale`; `add`, `sub`, `mul` exact; `div(b, scale:, rounding:)` with `Rounding { Up, Down, Ceiling,
      Floor, HalfUp, HalfDown, HalfEven, Unnecessary }` (Java's `RoundingMode`; `Unnecessary` aborts when
      rounding is needed); `compare`; `==` by numeric value (`1.0 == 1.00`); `toString()` plain with its
      scale (`"1.00"`, never `1E+2`); `parse(text) -> @Result<Decimal, string>`
- [ ] `Json`: `Num(value: f64)` replaced by `Int(value: i64)`, `BigInt(value: bigint)`, `Dec(value: Decimal)`,
      chosen by the numeral; readers `num() -> ?f64`, `i64() -> ?i64`, `bigint() -> ?bigint`,
      `decimal() -> ?Decimal`, `isNumber()`, `isIntegral()` (exact or `null`, never coerced); `encode` writes
      the digits and the plain decimal text; std's tests `decodesTo("9007199254740993", Int(value: 9007199254740993))`
- [ ] `json.parse` and `json.stringify` deleted with their Node / Erlang templates (336); their one caller (`tests/language/run/std_json_on_every_target.bp`)
      rewritten to `decode` / `encode`; `json` compiles on wasm under both hosts with no host cell
- [ ] the 13 files with a `case` over `Json` (std 6, rakun 3, jhonstart 2, onze 2) gain the arms, one commit per
      repository; `run/json_numbers_exact` one `.out` for the four targets

#### B-24 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-25 — 333 (B), 334, 335: the wasm host

**Repository:** botopink-lang, with consumer commits in log (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

After B-00e (std-wasm in the wasm output may absorb some `wasi:` bindings these steps write). Questions
`decision 502`, `decision 504`, `decision 505`, `decision 503`. Unblocks log 106 s3 (the wasm column; G4: a wasm binding cannot reach the
file system, cannot keep a value across calls; the wasm backend does not lower a context).

**Impacted tests:** `run/wasm_host_*`, `run/std_io_http_on_every_target`, `run/std_async_on_every_target`,
`run/wasm_library_binding`. **Model:** opus. **Consumer commits:** log (its two wasm markers).

#### Step 4 — `@Task` on `wasi` (was `140-wasm-host` s4)

- [ ] `@Component` bodies (375's mark) as state machines — decision 504 (recommended: every `@Component` a
      state machine on wasm); today they stay eager and an `await` of a task there runs the ready tasks,
      trapping on both hosts when the task still waits on the host
- [ ] `fetch`'s `Request` / `Response` in the compiler's layout (393), with `wasi:http` (`io/http`, `02/97`
      step 17)
- [ ] `async_block_all_of` gains the wasm column (`.targets` widened) — waits on std's `async` bindings
      (`02/97` step 17: `std/async` is refused on wasm for want of `delay`, `race`, `raceOf`)

#### Step 5 — the cells (was `140-wasm-host` s5)

Waits on `02/97` step 17 (`io/http`'s and `async`'s wasm bindings).

- [ ] `run/wasm_host_http` (a request to a local HTTP double, its status and body) under wasmtime; the
      commonJS and erlang answers equal
- [ ] `05-wasm`'s `wat/AGENTS.md` § Where this backend refuses to answer loses `io/http` and `async`

#### Step 6 — the `browser` profile (with 3–5, never after) (was `140-wasm-host` s6)

- [ ] `fetch`'s JavaScript implementation in the loader (394), with `io/http`
- [ ] parity: std's check refuses a cell bound on one host only (std's, `02/97` step 17); `test-libs` runs
      the wasm column on both hosts once `botopink test` runs wasm (335 (3)) — `test-language`'s does (§ Done)

**Gate:** standard (fronts.md § Gate) + `zig build test-language` with wasmtime's component support and
`zig build test-libs` (std's wasm column).

#### Step 17 — `io/http` and `async` bound to the `wasi` host (decision 334; after `01-compiler/140` steps 1–4) (was `97-std-dedupe` s17)

- [ ] `io/http`'s `fetch` binds `@External.Wasm(host: .Wasi, wasi: .HttpOutgoing)` and the `browser` host's JS `fetch`;
      the request and response mapped by each adapter; on `browser` a forbidden header or a `Set-Cookie` read answers
      `HttpError.NotAllowedOnHost(…)` naming it (335 (1)); `run/std_io_http_on_every_target` against a local double
- [ ] `async`'s twelve cells bind on `wasi` (`delay` on the monotonic clock, `race` / `raceOf` on pollables, the
      gate cells as pollables) and on `browser` (the same adapters, 394), through 392's scheduler; `RetryPolicy` / `nextDelay` unchanged;
      `run/std_async_on_every_target` asserts results and answer order only — never effect interleaving (335 (2))
- [ ] the `browser` bindings of both modules in the same commit (334: a cell bound on both hosts or neither)

#### Step 9 — a prebuilt wasm library merged into the module (decision 333 (B); no user yet, after step 5) (was `05-wasm` s9)

- [ ] `@External.Wasm(module: .<Library>, fn: "<export>")` — a fourth form beside `op:`, `fn:`, `wasi:` (238); the
      library named from the package's wasm manifest (version, hash); an unknown library, a missing export or a
      signature with a type that cannot cross is a located error at the annotation
- [ ] the glue generated per binding: `string` copied in as UTF-8 through the library's allocator export, the
      answer read back and freed; numbers and `bool` passed as values; `?T` of them as the library's null
      convention named in the manifest; no pointer reaches botopink code
- [ ] the merge: the library's functions, memory and data folded into the emitted module (the binary emitter is
      front 18's — a named carve-out), one `.wasm` out; `wasmtime` and the WAT comptime runtime run it
- [ ] `run/wasm_library_binding`: a test fixture library (a small `.wasm` built for the cell — a string and a number
      across) called from wasm and from commonJS, one answer; the size the merge adds recorded in `wat/AGENTS.md`

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified under wasmtime and
compared with commonJS's · no new RUN LOG answers at exit 0 a value another backend answers
differently · `RUNTIME TRAP` fixtures re-read: still impossible on wasm, or fixed

#### Step 11 — the same wasm library from commonJS (decision 333 (B); after `05-wasm` step 9) (was `04-js` s11)

- [ ] a binding with `@External.Wasm(module: …)` and no `@External.Node` lowers on commonJS to the same
      library: the module instantiates the package's `.wasm` once (synchronously, from its bytes beside the
      emitted `.js`) and calls it through the same glue
- [ ] the emitted package ships the `.wasm` next to its `.js`; `tsc-check.sh` green; `run/wasm_library_binding`
      one answer on commonJS and wasm

#### B-25 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-26 — 340: the keyed `Dict`'s per-row increment

**Repository:** botopink-lang, with consumer commits in rakun (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `run/beam_memory_ets`. **Model:** sonnet. Question `17-c`. **Consumer commits:** rakun
(`rakun_runtime.erl`'s registry, through 150).

#### Step 1 — the per-row increment (box 4, decision 340) (was `17-beam-memory` s1)

- [ ] std's `Dict.bump(key, by) -> Dict<K, V>` (integer `V`, an absent key counts from 0) is
      `insert(key, (at(key) ?? 0) + by)` on any `Dict`; on a keyed var `counts = counts.bump(k, n)`
      lowers to `ets:update_counter(T, k, n, {k, 0})` on erlang and beam — a `run/beam_memory_ets`
      cell with concurrent bumps of one key losing none; `counts.insert(k, (counts.at(k) ?? 0) + n)`
      stays refused (no pattern recognised); `docs.md`'s `keyed` sentence names `bump`

#### B-26 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-27 — Tooling, std residue, `.bpp` in the toolchain, `json` out of std

**Repository:** botopink-lang, with consumer commits in jhonstart and the `json` consumers (through 151) (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

116's botopink-lang half (the vscode-extension box is 161's) with 01-checker step 22's prelude scope;
26 s9; std purity (23) and effects by return (24 — 24-a answered by 431, 24-b by 432; 24-c, 24-g open); std's
snapshot message (135 s1); 97's residues; 98's script and its `docs/botopink-json.md` lines; 142 s1's std half
(the json front, 151, carries the consumers). Questions `116-a/b/c`, `23-b`, `std-c`, `24-c`, `24-g`, `decision 506`,
`decision 507`.

**Impacted tests:** `tests/language/modules/bpp_*`, compiler-cli, language-server, lib-test-runner;
`tests/cli_contract.sh`; `scripts/check-packaging.sh`; `test-libs`. **Model:** opus for 116, sonnet for the rest.
**Consumer commits:** jhonstart (`#[bpp.html]` with 26 s0), the six `json` consumers through 151.

#### Step 0 — Measure what the unfold stands on (was `116-bpp-file-format` s0)

- [ ] `tests/language/modules/` cell: a package's `pub default fn` over `comptime template:
      @Expr<string>`, imported `import t from "<package>";`, called with a literal from a consumer,
      on every target the language suite runs
- [ ] decision 199's header rule over every `.bpp` under `specs/1.0.12-beta/*/*/examples/`: each
      header item listed as declaration (`import`, `type`, `pub`) or statement (`val`, `use`);
      every unnamed item (`if`, expression statement, private `fn`, `test`, decorated
      declaration) listed with its file
- [ ] a module hand-assembled as the unfold would: a header-line type error and one inside the
      literal each reported at the `.bpp` line

#### Step 2 — The unfold (was `116-bpp-file-format` s2)

- [ ] the return type is read from the default function's signature (decision 275): the fixture
      package's `@ExprCustom<i32>` gives `-> i32`; jhonstart's gives `-> @Component<Element>`
      for a header with and without `use` / `await`; the toolchain spells no type name
- [ ] `tests/language/modules/bpp_*`: fixture package whose default function is **not**
      jhonstart's (answers the literal's length) — `.bpp` with `type Props` unfolds to
      `pub default fn (props: Props)`, without to `pub default fn ()`, no header = all
      literal; fixture served unchanged (proof the toolchain knows no library)
- [ ] the file's grammar (212, 338): the header from the first line to the first separator line;
      `---` → markup to the end of the file; `--- style ---` → style section closed by `---`, then
      markup; no separator line → markup only (a markup-only file compiles)
- [ ] a first line `---` refused at line 1: `error: the header starts on the first line; a .bpp has
      no opening ---`
- [ ] each refused at its line: a `--- style ---` after the markup; a second style section; an
      unclosed style section (at its `--- style ---` line)
- [ ] the style section unfolds to `use <style> """<the section>""";` after the header's
      statements, before `return html """…""";`, with `import <style> from "<bpp.style>";` binding
      no name the header can reach — § Mechanism's `Props(title)` example unfolds as spelled there
- [ ] fixture style package (not `jhonstart-styled`) whose default function answers something
      trivial (the section's length): a `.bpp` with a style section compiles onto it unchanged —
      the toolchain knows no library for the style section either
- [ ] a diagnostic inside the style section reported at its `.bpp` line, like the markup's
- [ ] the default function anonymous (289): `import {components.PostCard};` binds `PostCard` in the
      importer, an alias another name; a file name that is no identifier (`not-found.bpp`) unfolds;
      `decl.name` is the file name; `page.bpp` whose header imports and writes `#[page(…)]` compiles
- [ ] declarations at module level, statements in the body in order; a statement reads `props`
- [ ] a decorator on the header's last line, before the separator line, annotates the function
      (221 (1)); without one the function carries none — no decorator from the file name, no
      `bppKinds` read (285)
- [ ] `X.bp` beside `X.bpp`, and `.bpp` with no key — each refused with § Mechanism's message
- [ ] prelude (270): fixture with `prelude.bp` — markup-only `.bpp` compiles; module and emitted
      code import only used items; header name beats prelude's; `prelude.bp` holding a `fn`, another
      package's item or an activation refused at its line. The scope (`compiler-core`: last scope, import-item list) is
      `01-compiler/01-checker`'s, handed by this front
- [ ] `grep -riE 'rakun|jhonstart|erika|emilia|onze'` over `modules/compiler-core/src` and the
      edited `compiler-cli` files is empty

#### Step 3 — The extension in every tool's list (was `116-bpp-file-format` s3)

- [ ] every § Mechanism site reads one shared list instead of spelling `.bp`
- [ ] `botopink build`, `check`, `run`, `test` over a `.bpp` project; test runner discovers a
      `test` declared in a header
- [ ] `mod x;` resolves `x.bp`, then `x.bpp`, then `x/mod.bp`

#### Step 4 — The span mapping and the editor — part (was `116-bpp-file-format` s4 boxes 1, 2)

- [ ] header-line type error and a `failAt` in the markup reported at their `.bpp` line and
      column by `botopink check` and the language server
- [ ] hover, go-to-definition in the header; default function's overlay served as the markup's
      tokens — the extension ships no grammar of the file

#### Step 5 — The formatter (was `116-bpp-file-format` s5)

- [ ] `botopink format` rewrites a badly indented header as a module, leaves every byte of the style
      section and the markup unchanged; `format --check` fails on the header, passes the style
      section and the markup
- [ ] `scripts/format-check.sh` walks `.bpp` files — header under the gate's format stage like any `.bp`

#### Gate additions (was `116-bpp-file-format` gate)

**Gate:** standard (fronts.md § Gate), in `repository/botopink-lang` and `repository/vscode-extension`, plus:
- [ ] `zig build test-libs`: every library green — no existing `.bp` file changes meaning
- [ ] `docs.md` § Modules documents `.bpp`, every fence compiled by `zig build test-docs`

#### Step 22 — the prelude scope (decision 270) (was `01-checker` s22)

`compiler-core` takes, with a module, a list of import items (`element.Element`,
`elements.article`, aliases allowed) as the module's **last scope**: only for names the module does
not bind (declared or imported names never reach it). An item becomes an ordinary import (`import
{elements.article} from "<package>"`) in the transformed program and emitted code **only when a
name resolves through it**; unused items emit nothing. Names no library — `08-bpp/116` hands it
`prelude.bp` items for a `.bpp` file and owns the `.bpp` refusals (non-`import` `prelude.bp` line,
item of another package, an activation, default function's name bound by the header).

- [ ] `comptime/tests` fixture: module handed `[element.Element, elements.article]` naming only
      `article` — transformed program imports `elements.article`, not `Element`; a self-declared
      name resolves to its own declaration; nothing in `src/` names a library
- [ ] `src/comptime/AGENTS.md` states the scope order

#### Step 9 — a dependency's sidecars and imports answer as its own build does (was `26-cli-tooling` s9)

- [ ] a transitive dependency's sidecar ships: a project outside the rakun workspace depending on a
      member by `path` failed `build` with "`rakun_actuator` / `rakun_probes` is not a sidecar of
      this project" — `libs.sidecarOwner` asked only the project's direct `dependencies`, then the
      roots by name; it now walks the closure the build resolved (`closureOwner`) ·
      `tests/cli_contract.sh` "a dependency of a path dependency", `libs.zig` unit test
- [ ] a dependency's module importing a package it does not declare is decision 242's located
      `unresolved import source` (at the dependency's file), not `unbound variable` —
      `libs.loadOne` runs `resolver.checkSources` against the dependency's own manifest ·
      `modules/dependency_imports_undeclared_package`, four targets

**Gate:** standard (fronts.md § Gate) + `zig build test-cli`, `test-bpmp`, `test-vscode` green;
language-server tests green with new snapshots · `zig build test-libs` at baseline (rakun's members
exercise every sidecar path)

#### Rows other fronts found (was `26-cli-tooling` rows)

- [ ] `botopink check` / `build` print a type error's message and box but not its hint: the
      `PersistentTerm` write (`infer.zig`'s hint names `#[@BeamMemory.Ets]`) and
      `std-unsupported-on-target` carry one and the terminal shows none; a parse error's
      `= hint:` line prints (measured by `07` step 6; `docs.md` § `@BeamMemory` cites the hint)

#### Step 1 — the gate's rows (was `23-std-purity` s1)

`zig build test-language` green on four targets with the import cells (`modules/import_alias_on_type`,
`import_std_type_through_module`, `import_std_folder_namespace`, `import_type_closure*`,
`import_type_alias`); language-server tests with the `project_graph.zig` cells (one `lsp/` snapshot
per import spelling).

- [ ] `run.sh --target all` green on the `modules/import_*` cells — measured, the box ticked
- [ ] `grep -l 'import {' modules/language-server/snapshots/lsp/*.snap.md` lists one snapshot per spelling (dotted, grouped, `*`, `as`, a folder leaf); missing ones added
- [ ] the five `AGENTS.md` name the tree and the grammar; `docs.md` § imports / § std verified against the grammar (07 places any correction)

#### Step 2 — the confirmations (was `23-std-purity` s2)

23-b (`base64` retired) and std-c (namespace rewrite): each confirmed or reversed; a reversal opens a
step in the owner (01 for std-c). 23-c is confirmed (317).

- [ ] the three ids in `../../decisions-taken.md` with their numbers, or a reversal's step named —
      23-c confirmed (317); 23-b and std-c open

#### Step 1 — every guide fence compiles as one program (E3, decision 134) (was `24-effects-by-return` s1)

`botopink check` over `guide.md`, jhonstart as path dependency: ✓ fences type, ✗ sites answer their
code located; § 7's server action types against rakun's `serverAction` once shipped (stubs until
then, named as stubs in the report). E3's three checker rows landed in 01
(`run/try_catch_null_and_noreturn_narrowing`, `run/component_call_renders`).

- [ ] `scripts/check-docs.sh` runs the guide as one program and is green
- [ ] § 7 against the real `serverAction`, or the stub named with the rakun front that replaces it

#### Step 2 — the confirmations (was `24-effects-by-return` s2)

24-a (effect codes), 24-b (`@Task`'s `map` / `then`), 24-c (prefixed loop's label), 24-g
(`std/async`'s shape) confirmed or reversed; 24-h answered (decision 179, replaced by 432).

- [ ] the four ids in `../../decisions-taken.md`; a reversal's step named in the owning front — 24-a → 431 (checked `@Result`; 24-b → 432, the failing task;
      `throws: true` and `attempt` are `01-checker` step 42 and `02/97` step 18)

#### Step 3 — the cost of a `@Result` per item (was `24-effects-by-return` s3)

`@Iterator<@Result<T, E>>` of 10⁵ items consumed by `for` with `try r`, on erlang and wasm, vs the
same loop over `@Iterator<T>`; if the `Ok` wrap weighs, the backend specialises the `Ok` `yield` — a
row for 02 and 05, not edited here.

- [ ] the two ratios in this README with the program and the machine; a row filed in 02 / 05 if either exceeds 1.5×

#### Step 1 — `json` leaves std — part (was `142-data-formats` s1 boxes 1, 2)

- [ ] `libs/std/src/json.bp` moves whole to `repository/json` (history kept as 138 did): the `Json` type
      and its methods, `parse`, `decode`, `stringify`, `quote`, `unquote`, `array`, `object`, the host
      cells and their tests; std's `root.bp` loses `pub mod json;`; `grep -rn "json" libs/std/src` names
      no module (comments aside)
- [ ] `import {json} from "std"` is an unknown-module error naming the `json` library

#### Step 1 — std (390) (was `20-snap` s1)

- [ ] `mocks.verify`'s message pinned with `throwsWith` on both targets (§ 1, CONVERT)
- [ ] `libs/std/AGENTS.md`: the inline literals and the four `__snapshots__/` path-rule files are the evidence

#### Step 4 residue — the engine under every `-test` member (was `97-std-dedupe` s4 residue)

- [ ] `zig build test-libs` reads every member's row at its previous count (the last recorded whole run, 138's gate: 125 passed) — read on the next cold gate. Measured for std and the seven `-test` members: `std`, `emilia-test`, `erika-test`, `jhonstart-test`, `onze-test` pass on commonJS and erlang, `jhonstart-dom-test` on commonJS, `rakun-test` on erlang, `rakun-starter-test` compiles (no tests); 12 passed, 0 failed, 1 without tests, 3 restrictions audited

#### Step 6 — conditional on `decision 506`: `io.process` signals and a line reader (was `97-std-dedupe` s6)

(a): `process.onSignal`, `process.forwardSignals(child)`, `io.stdin.readLine()`. (b), recommended:
onze 50's boxes take their (b) shape.

- [ ] under (a): a spawned child receives the `SIGTERM` sent to its parent, asserted on both
      targets with a child that prints on the signal; `readLine` answers a line without its newline
- [ ] under (b): `libs/std/AGENTS.md` states std has no signal or TTY surface and why

#### Gate additions (was `97-std-dedupe` gate)

**Gate:** standard (fronts.md § Gate) + `botopink test` and `botopink test --target erlang` green in
`libs/std`, `libs/actions`, `libs/validation`
- [ ] steps 0–5, 8–10 landed before this gate was recorded: one cold `zig build test` and a full
      `zig build test-libs` on feat with them in, recorded here

#### Step 2 — the packaging check, as a script (was `98-packaging-tail` s2)

`repository/botopink-lang/scripts/check-packaging.sh`: § Mechanism's four checks over
`repository/*`, non-zero exit naming each failing path. Calling it from `gate.sh` is the gate's call.

- [ ] main checkout after the library steps land: exit 0; one README removed: exit 1 naming it; one
      `-test` member emptied: exit 1 naming it
- [ ] `docs/botopink-json.md` § Examples states the README and helper rules, links the script

#### Step 3 — front 95 closed as a confirmation (was `98-packaging-tail` s3)

Under `decision 507` (1): one `repository/onze` entry in `.gitmodules`, workspace `onze`, eight members with
`files`, listed by `zig build test-libs`; `mocking-lib-final` already resolves. Only the
`docs/botopink-json.md` line to write.

- [ ] `git -C repository/onze rev-parse mocking-lib-final` resolves; `git submodule status
      repository/onze` is the orchestrator's commit; `docs/botopink-json.md` says in one line the
      orchestrator repository carries the mocking library as tagged history

#### B-27 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-28 — The formatter: the `;` after a braced block, C-12, the trailing comma, annotations as written

**Repository:** botopink-lang, with consumer commits in every library repository (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `format/tests/**`, `scripts/format-check.sh` over every tree. **Model:** sonnet; haiku for
the migration runs. **Consumer commits:** every library repository (the `;` migration, then the C-12 reformat —
one per repository; erika's is 145 s3).

#### Step 1 — re-count the siblings' `;` sites (was `16-formatter` s1)

`c13-migrate.py --dry-run` (add if absent: print sites, write nothing) over
`repository/{rakun,jhonstart,erika,onze,emilia}/**/*.bp`; 1.0.10: rakun 454, jhonstart 40, erika 28,
onze 1.

- [ ] a count per library, with the command, in this README

#### Step 2 — the migration in each tree (the tracks run it) (was `16-formatter` s2)

Each track runs it at the end of its last thread in that tree (07 for erika); verified per the
script's docstring — changed lines differ only by a deleted `;`, `botopink format` before/after
byte-identical, cells green before and after.

- [ ] the five trees at 0 sites (step 1's command re-run answers 0)

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

- [ ] one `assertFormat` case per list kind, both spellings; the six trees measured before and after; `src/format/AGENTS.md` states the rule
- [ ] 345 in the printer: a list without the trailing comma stays on one line past the width, and one written
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
    @External.Node(fn: mixBody),
    @External.Erlang(fn: mixBody),
    @External.Beam(fn: mixBody),
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

- [ ] `feat`'s GitHub pipeline green after the step landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the step's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the step's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the step changes, its runs on `feat` since
      the step's base, green or each red named

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
- [ ] `reject/` cells checked in process by a compiler-core test that reads `tests/language/reject/*.bp` and its
      `.expect` (message line and `line:col`), no `botopink` process per cell
- [ ] single-file `run/` cells compiled in process and run on the four targets through the snapshot executors
      (`executeJavaScript`, `executeErlang`, `executeBeamAsm`, `executeWat`) and their runtime cache, each `.out`
      byte for byte; a `.targets` narrowing still audited against the host-binding refusal
- [x] the language half of `test-cli` becomes cells (decision 457's shape): `backend_exec.sh`'s programs (numeric —
      `55` on the four targets —, records with enum / `case` / lambda, the multi-folder `mod` / `pub mod` package)
      and `mutual_recursion.sh`'s forward reference and `isEven` ↔ `isOdd`; `test_tooling.sh`'s semantics of
      `assert cond, "msg"` and of `try` in a `test` block as `test/` cells. The scripts keep what is the CLI's
      contract (`cli_contract.sh`, `test_tooling.sh`'s `--filter` / totals / `*.snap.new` listing,
      `result_store.sh`, `backend_exec.sh`'s `wasm --invoke main`); every assertion of today has a home — none lost
- [ ] botopink-lang's `examples/` becomes cells (decisions 457, 461): `hello`, `stdlib-tour` (its `test {}` blocks
      a `test/` suite), `modules` (the `mod` / `pub mod` tree) and `yamlconf` (the labelled tuple and the located
      `cfg.server.prot` refusal) as cells with their checked output, landing in `conformance/modules/<name>/` with the move (decision 466: no mirror,
      the `botopink/conformance` repository deleted, 467); `generic-loader-binding` (three `from "erika"` forms — a
      library, not the language) moves to `repository/erika/examples/` as a consumer commit (rule 10);
      `examples/` deleted; `test-libs.sh`, `tsc-check.sh`, `backend_exec.sh`, `cli_contract.sh`,
      `comptime_bench.sh` and `format-check` pointed at the cells or a fixture of their own, no check lost (458)
- [ ] the per-target cells the B-00 group's audit left waiting on `snapshot/targets/` (B-00k): float text
      (`"${5.0}"`, `1.0e21`, `1.0e-7` — commonJS departs), `trim` keeping a NBSP, the final sigma (commonJS `ς`),
      `NaN` / `Infinity` (erlang and beam abort), and an unseeded `random.float()` reached from a decorator body
- [ ] `modules/` projects and `test/` suites stay on the CLI (`botopink run` / `botopink test --json`): they are the
      manifest, module-loading and library-resolution path; the runner's `--self-test` unchanged

#### B-29 step H Conformance (decisions 459, 474, 477, 478, 479, 480) — the step's last box group

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the step's other boxes have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the step landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the step's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the step's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the step changes, its runs on `feat` since
      the step's base, green or each red named
- [ ] what the move left: `generic-loader-binding` into erika once B-45 lands; the decorator `random.float()` cell once
      B-46 lands; the reds B-43 and B-44 found

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

- [ ] `feat`'s GitHub pipeline green after the step landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the step's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the step's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the step changes, its runs on `feat` since
      the step's base, green or each red named

#### Step J — botopink-lang's gate drops the lock and takes a total of jobs (decisions 468, 469)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

After the step gate of decision 460 lands (both change `scripts/gate.sh`). The pool itself is the meta repository's
(163 s7); this gate knows nothing of it.

- [ ] `scripts/gate.sh` takes one total of jobs (a leading argument; default the machine's, as step G computes) and
      splits it among its stages as today; the gate lock removed (`scripts/AGENTS.md` § Gate lock rewritten)
- [ ] `--no-conformance` stays: the commit hook's gate (470, step I), never a verdict
- [ ] a library's `test-out` written under a per-run directory and removed after (botopink-lang's `test-libs` writes
      into the linked siblings)

#### B-29 step J Conformance (decisions 459, 474, 477, 478, 479, 480) — the step's last box group

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the step's other boxes have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the step landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the step's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the step's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the step changes, its runs on `feat` since
      the step's base, green or each red named

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

- [ ] `scripts/check-docs.sh`'s header says `check` is target-independent (`:63`, `:76`): it is not
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
only `#[@External.Erlang(…), @External.Node(…)]`. `src/comptime/tests/infer_decls.zig:147` `"infer:
implement block is invisible to the binding list"` names a gone behaviour (`implement` blocks
appear, read from `OkData.transformed.decls`).

A fourth, found by step 5: `src/codegen/tests/wat.zig`'s `"wat: print ---- a record and a
variant have no printed form yet, so they trap"` — all four backends print §7's text now.

- [ ] the three tests named for what they assert; snapshots (codegen: one per target per runtime tree; comptime: one) `git mv`ed in the same commit, byte-identical
- [ ] `scripts/snap_audit.sh --mode=orphans` after the rename: 0 orphans, 0 unrecorded

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

### B-32 — structural equality at build is iterative; an arithmetic error at build reads as Erlang's (decisions 471, 472)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (both decisions fix the design)

Found by B-00k: `comptime same(2000000)` traps (wasm3 stack overflow) on every target; a float division by zero at
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

### B-33 — `@External.Wasm`'s cells as labelled arguments (decision 481)

**Repository:** botopink-lang, and every library with an `@External.Wasm` cell (a full worktree) · **Model:** opus (a
codemod tied to a new rule)

Today std writes the cells as prefixed strings (50 `"fn:…"`, 28 `"std:…"`, 6 `"op:…"`); 305 already made them labels.

- [ ] the checker reads `fn: <identifier>` (resolved, typed), `op: "<opcode>"`, `wasi: .<Adapter>`, `std: "<module>.<fn>"`
      (checked against std-wasm's `exports` and the declaration's types); a prefixed string refused, located, naming
      the labelled form — `reject/` cells for each
- [ ] a codemod rewrites every cell in std and the libraries; every `.out`, RUN LOG and snapshot otherwise unchanged
- [ ] `docs.md` and the `AGENTS.md` files name only the labelled forms
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-34 — the BEAM assembler rejects `styled`'s module (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a backend bug with a measured repro)

Found moving jhonstart's examples into its `conformance/` (463): every jhonstart cell is refused on beam with
`the OTP compiler refused the emitted program — nothing to run`; the BEAM assembler rejects the `styled` module
(`make_fun3 … {unassigned,{y,3}}`). commonJS and erlang answer.

- [x] the beam emitter assigns the register `make_fun3` reads; `styled` assembles; jhonstart's 18 `conformance/` cells
      green on beam — red on the parent, green after
- [x] the cheap test the hook runs that would have caught it (a beam export-audit or codegen snapshot case, 478)
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-35 — `@println` has no wasm lowering (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a backend gap with a measured repro)

Found moving erika's examples into its `conformance/` (463): `the wasm backend has no lowering for the builtin
`@println``. Its two cells answer on commonJS, erlang and beam.

- [x] `@println` lowered on wasm as `@print` is, with its newline; erika's `conformance/` cells green on wasm — red on
      the parent, green after; a codegen snapshot case (478)
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-36 — styled's hook red on `feat`: "tab4's class is not a constant of the emitted module" (structural, decision 430)

**Repository:** styled (front 148's) · **Model:** opus

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
- [ ] Conformance step (459, 474, 477, 478, 480)

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
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-39 — a module-level `val` read by the next one is unbound on erlang (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`val a = X(); val b = f(a.m())` at module level emits an erlang module that refers to `a` unbound; the OTP compiler
refuses it (found in rakun's `constraint` cell, which registers inside `main` instead).

- [x] a cell red on the parent: two module-level `val`s, the second reading the first, on every target
- [x] the erlang emission binds the first before the second reads it; the cell green on every target
- [ ] Conformance step (459, 474, 477, 478, 480)

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
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-41 — a library's abort reads the same on every target (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

emilia's `theme-unknown-namespace` cell aborts with `emilia theme: '--gutter' is in no known namespace` on commonJS;
erlang and beam word the same abort differently, so the cell cannot claim its `stderr` in `output/` (458: no departure
for a defect).

- [x] the abort's text measured on each target; the library's message reaches stderr unchanged on every target (the
      runtime's frame around it the same, or none); the cell's `stderr` claim in `output/`, green on every target
- [x] a compiler-core test red on the parent (a `@panic` with a library's message, every backend)
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-42 — wasm: a cell with a `path` dependency prints nothing; emilia's `arbitrary.bp` does not build (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

Found moving emilia's reference (79 cells): on wasm, any cell with a `path` dependency prints nothing, a bare
`@print("hello")` included; emilia's `arbitrary.bp` does not build on wasm (`join/1` does not resolve).

- [x] a cell red on the parent for each: a `path` dependency and a `@print` on wasm; a module calling `join` from a
      dependency on wasm
- [x] both fixed; emilia's 79 cells green on wasm, or each refused on a host binding it lacks (a departure, 475)
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-43 — a `Set` of structurally equal records keeps one on every target (decision 210)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`stdlib-tour`'s Set test keeps 3 members on commonJS where two are structurally equal (2 on erlang); the same on wasm.

- [x] a cell red on the parent: a `Set` of records, two structurally equal, its size on every target
- [x] commonJS and wasm compare members structurally (210); the cell and `test/stdlib-tour` green on every target
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-44 — wasm prints a lifted `bool` as `1` (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

The `yamlconf` cell prints `1` on wasm where every other target prints `true`.

- [x] a cell red on the parent: a `bool` that crosses a host value printed on wasm
- [x] wasm prints `true` / `false`; `yamlconf` green on wasm
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-45 — erlang: `lib.member()` through a library's default handle is unbound (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`erika.of(…)` in the `generic-loader-binding` example fails on erlang: `variable 'Erika' is unbound`; it blocks the
example's move into erika's `conformance/`.

- [x] a cell red on the parent: a local `path` library whose default handle's member is called, on every target
- [x] the erlang lowering binds the handle (`default_handle_member` green on erlang; beam is B-50)
- [ ] `examples/generic-loader-binding` moves into `erika/conformance/` as a cell on every target (an erika change, after the 144 front)
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-46 — a decorator body reaches a nested std namespace (`io.random`) (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** opus (the comptime's module environment)

A decorator body calling `random.float()` fails at build: `unbound variable '__bp_ns_io_random'`; the B-00k cell of
`random.float` at build cannot be written.

- [x] a cell red on the parent: a decorator body calling a function of a nested std namespace
- [x] the comptime's environment holds the nested namespaces; the `random.float()` cell written (refused unseeded at
      build, decision 447, or the seeded answer)
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-47 — a refusal cell claims the label under the caret (decision 485)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

- [x] the `.snap` format reads and writes `label <text>` after `at` in a refusal file (refused elsewhere, located);
      `cell check` compares it and `cell new` writes it when the compiler prints a label beside the caret
- [x] CLI tests red on the parent: a label that changes, a label that disappears, a `label` record in an output file
- [x] `case_bare_name_arm`, `case_constant_pattern`, `reserved_word_field_name` and `reserved_word_param_name` claim
      their whole refusal and label, green; every other refusal cell whose caret carries a label gains its record
- [ ] `conformance/docs.md` states the record (with B-29 step I, which writes that file; `conformance/AGENTS.md` states it today)
- [ ] Conformance step (459, 474, 477, 478, 480)

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

- [ ] Conformance step (459, 474, 477, 478, 480)

### B-51 — commonJS prints an `f64` without its `.0` (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`math.abs(0.0 - 1.0)` prints `1` (`import_module_paths`) and an `f64` out of a `case` prints `2` (`enum_declaration`) on
commonJS; the same backend prints `1024.0` elsewhere, and every other target `1.0` / `2.0`.

- [x] the two cells green on commonJS; an `f64` reaching `@print` through a std call or a `case` keeps its `.0`
- [x] a codegen test the hook runs, red on the parent
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-52 — wasm prints a string field or an awaited string as a number (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`generic_fn_and_type` prints `Tree.Leaf(value: 280)` for a generic record's string field; `async_block_both` prints
`2922` for `ana2`; `task_result_await` prints `Hello, 292` for `Hello, ana`.

- [x] the three cells green on wasm: a string reaching a generic field or crossing an `await` prints as text
- [x] a codegen test the hook runs, red on the parent
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-53 — `@print` of a `@Result` prints the host's form (structural, decision 430)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`@print(Ok(81))` prints `{ ok: 81 }` on commonJS, `{ok,81}` on erlang and a number on wasm; the reference says a value
prints the way the source writes it.

- [x] a cell red on the parent: `@print` of `Ok(…)` and `Error(…)` on every target, the source's form
- [x] every backend prints a `@Result` as `Ok(81)` / `Error(…)`
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-54 — `botopink format` rewrites an annotation's labelled argument `keyed: true` to `keyed = true`

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`#[@BeamMemory.Ets(keyed: true)]` comes back from the formatter as `keyed = true`; the reference and 305 write the
labelled form.

- [x] the formatter keeps an annotation's labelled arguments as written (`label: value`); a format test red on the parent
- [ ] Conformance step (459, 474, 477, 478, 480)

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
- [ ] a float commonJS cannot type (an imported record's `f64` field) still loses its `.0`
- [ ] Conformance step (459, 474, 477, 478, 480)

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
- [ ] the refusal in `run.zig` (and the wat component emitter where a module without `main` exports no
      `wasi:cli/run`), one message on every target and host; a unit test the hook runs (478)
- [ ] a cell: a package with no `fn main` refused by `run` on every target
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-80 — onze-cli's CSS accessors test red under `test-libs` on commonJS and erlang

**Repository:** botopink-lang (`--lang`), or onze when the cause is the library's · **Model:** sonnet

Found landing B-24 (2026-10-12): `zig build test-libs` fails onze-cli's test at `test/build_test.bp:140` (the CSS
accessors) on commonJS and erlang, the same with `libs/std` at `feat`'s — older than B-24. The cause is found first:
a compiler defect is fixed here; a library's is a row of onze's front (162) and this step closes pointing at it.

- [ ] the cause found (compiler or library), named in this box
- [ ] fixed where it belongs; `test-libs` green for onze-cli on every target
- [ ] Conformance step (459, 474, 477, 478, 480), when the fix is the compiler's

### B-81 — rakun-data's `#[query]` test red under `test-libs` on erlang

**Repository:** botopink-lang (`--lang`), or rakun when the cause is the library's · **Model:** sonnet

Found landing B-24 (2026-10-12): `zig build test-libs` fails rakun-data's test at `test/sql_build_test.bp:148` (the
`#[query]` decorator) on erlang, the same with `libs/std` at `feat`'s — older than B-24. The cause is found first: a
compiler defect is fixed here; a library's is a row of rakun's front (150) and this step closes pointing at it.

- [ ] the cause found (compiler or library), named in this box
- [ ] fixed where it belongs; `test-libs` green for rakun-data on erlang
- [ ] Conformance step (459, 474, 477, 478, 480), when the fix is the compiler's

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
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-63 — `botopink cell check` runs cells in parallel (`--jobs`)

**Repository:** botopink-lang (`--lang`), and the libraries' shared runner (`runner-standalone.sh`, one text) ·
**Model:** sonnet

Measured on 2026-10-12: `botopink cell check <lib>/conformance` checks one cell after another on one core (one
`botopink` process at ~80 % of a core, the machine's load 1.3 of 16); a library's gate calls it once over its whole
`conformance/`, so emilia's 79 cells on three targets run in a row.

- [ ] `cell check` runs its cells (and a cell's targets) on a pool of `--jobs <N>` (default the machine's, as
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

- [ ] every target emits a module's production unit always and its test unit (`__test__` prefix, 513 (1)) only under
      `botopink test` of the package under test; a dependency's test units never emitted
- [ ] the production unit always carries the reserved export of its private functions and module-level `val`s (513
      (2)); a test reading either runs on every target; one test runner at the entry; every library's tests green
      unchanged
- [ ] a test the hook runs per target, red on the parent: a module's production bytes equal under `build` and `test`
- [ ] the code cache (B-58) serves a dependency's production unit to `build`, `run` and `test` alike
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-67 — erlang: a library's record imported beside a std record of the same name builds std's (D3)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

`import {items.Queue} from "shelf"` beside `import {collections} from "std"` builds `Queue(…)` as
`{std@collections@@Queue, …}` on erlang; the program dies with `function_clause` in `shelf@items:describe`. commonJS
and beam print the right answer. A wrong program, found by `test-closure-invariant`'s `crowded` consumer.

- [x] a cell red on the parent (the two imports, a print of the record and a call into the library); green on every
      target
- [x] the construction names the imported type's owner; an erlang codegen test
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-68 — wasm: a method call on a template's answer does not resolve (D4)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet

`val built = shelf "built"` (the template answers `Label`) then `built.size.toString()` is refused on wasm: "the
wasm backend cannot resolve the call `toString/0`"; the other targets run it.

- [x] a cell red on the parent; the call resolved on wasm, the cell green on every target
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-30 — wasm memory managed as erlang's: a heap per process, collected, in std-wasm (decisions 448, 449)

**Repository:** botopink-lang (`--lang`)

After the B-00 group, B-00i included (the collection knows the terms' layout, 450). botopink's values are immutable; on erlang each process's heap is collected and released
when it dies. The wasm target's bump heap never frees; this step gives the wasm target and beam-to-wasm's translated
code erlang's model, implemented in `modules/std-wasm/src/heap.zig` (449).

- [ ] measured first: how far a program grows without collection — a long loop building strings, a request loop of
      a server, onze's pages on wasm — recorded in `codegen/wat/AGENTS.md` before any design is written
- [ ] `modules/std-wasm/src/heap.zig`: a heap per process (a `@Task`; a BEAM process in translated code), `alloc` on
      the current process's heap, collection by copying the live values (no write barrier but on the mutable cells
      a `var` holds), a value copied between heaps as an erlang message is, a heap released whole when its process
      ends; unit, property and stress tests in Zig; in std-wasm's `program` table, no comptime face
- [ ] `alloc` leaves `wat_prelude` (449 (2)); the wasm codegen names its roots (the task's frames, the scheduler's
      queues, the cells) at each collection point; a program that allocates nothing renders byte for byte as before
- [ ] beam-to-wasm (449 (3)): translated code allocates on the current process's heap; `test_heap` / `allocate` are
      collection points with their live registers as roots; beam-to-wasm still imports std-wasm alone (438)
- [ ] a run that exhausts memory traps, never answers with damaged data; std-wasm's frames stay on the one stack (447)
- [ ] every `run/` cell's `.out` on wasm unchanged; a long-running cell whose memory stays bounded where the bump heap
      grew without limit; `modules/std-wasm/AGENTS.md` names std-wasm botopink's wasm runtime (std, stack, heap)

**Impacted tests:** wasm `run/` cells, `@Task` cells first; wasm RUN LOG snapshots (re-read); `modules/std-wasm` and
`modules/beam-to-wasm` unit tests; `test-libs` wasm column. **Model:** opus (a design the decision leaves to
measurement). **Consumer commits:** none.

#### B-30 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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
