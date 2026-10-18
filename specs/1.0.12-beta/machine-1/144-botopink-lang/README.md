# Front 144 — botopink-lang: every open step that changes the compiler, std and the toolchain

**Priority:** maximum — the one front that edits `repository/botopink-lang` (decision 433). Its first
group, comptime on wasm (decision 434), was **the first thing the milestone did**, before any other
step of any front; it is done but for B-00c's last box, the seventh step of the conformance order (fronts.md
§ Execution order).
**Repository:** botopink-lang — worktree `--lang` (a step with consumer commits: a full worktree, the library halves
each a commit in its library, rule 10)
**Model:** by step (each group names its own, `AGENTS.md` § Which model a thread runs on); opus for a group that
designs or changes semantics
**Depends on:** nothing open — the fronts in flight when 434 was taken have landed (checker-s41, checker-s29,
render-scope-388, bigint-139, comptime-14, import-129, typed-member-395's compiler half).
**Owns:** all of `repository/botopink-lang` — `modules/{compiler-core,compiler-cli,language-server,
lib-test-runner,bpmp,manifest,test-shard}/**`, the new `modules/std-wasm/**` and `modules/beam-to-wasm/**`
(434), `libs/std/**`, `scripts/**`, `tests/language/**`, `docs.md`, `docs/**`, `.github/workflows/**`,
`build.zig` — plus the consumer commits each step names, one per library repository (decision 188), unless
that library's front holds the same files (then the step names a handed-over row in that front).
**Does not touch:** a library repository beyond the consumer commits its steps name; the meta repository.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

Every open box of the steps (now in the two machines' folders, § Machines) was moved verbatim from the old track fronts; the tag after each `####` heading names
where it was; each old front's goal, mechanism and topic files sit in a subdirectory named after it, in the
folder of the machine that runs its steps (`machine-1/144-checker/01-checker/context.md`,
`machine-1/144-checker/116-bpp-file-format/examples/` …). The steps run in the order written: **first B-00 (434)**,
then the error contract of 431 / 432 (B-01–B-09), then the structural fixes the library fronts wait on
(decision 430: B-10–B-19), then the rest (B-20–B-29).

**New development is centred on front 164 wasm-gc (the maintainer, 2026-10-14):** `machine-2/144-backends-tooling/164-wasm-gc/` — s1 (wasmtime, the
engine), s2 (WasmGC codegen), s3 (std-wasm in botopink and `.wat`), s4 (Conformance) — the second front that edits
botopink-lang (amends 433). It owns the wasm target, the comptime runtime, std-wasm, beam-to-wasm and
compiler-web; a step of this front that reaches them waits on 164 s2 and never edits them. The old model's steps are
withdrawn here (B-30's open boxes, B-25's steps 9 and 11, the linear-memory rows). Machine 1's steps continue in
their own order.

## First — comptime on wasm (decision 434)

The maintainer: "a primeira coisa: deixar de usar o beam em comptime, deixando só o wasm com essa função". Every
target's comptime evaluation moves to the wasm runtime; the erlang and beam targets are unchanged. Eleven steps, in
the order below, before any other step of this front or any other front. **The group is done but for B-00c's last
box**: each library repository's own hook run on this compiler — `scripts/gate.sh libs`, the seventh step of the
conformance order (fronts.md § Execution order).

| Step | What | Model |
|---|---|---|
| B-00a | `modules/std-wasm/`: std's host functions in Zig, compiled to wasm, served to the comptime runtime | opus, then sonnet |
| B-00b | `modules/beam-to-wasm/`: a standalone utility, any `.beam` translated to wasm module by module, on std-wasm (OTP and BIFs), nothing of botopink; an unconverted call refused located (decisions 435, 438) | opus |
| B-00c | the comptime driver on wasm for every target; a host function reached at build answers by its `std:` cell, else its `fn:` cell, else is refused (452: the comptime never calls beam-to-wasm, never runs an Erlang cell) | opus |
| B-00d | the BEAM comptime runtime deleted; `snapshots/codegen/{beam,wat}/<target>/` → `snapshots/codegen/<target>/` | sonnet |
| B-00e | std-wasm linked into the `--target wasm` output, replacing the `wat_prelude` helpers and `wasi:` bindings it implements | opus |
| B-00f | `@External.Beam` deleted: `@External.Erlang` binds erlang and beam, `@External.Beam` refused located (decision 437) | sonnet |
| B-00h | wasm codegen snapshots show a transpiled std-wasm function as one line with its hash (decision 446) — before B-00g | sonnet |
| B-00g | `wat_prelude` split: only representation, operators, output and the language runtime stay; std's helpers move to std-wasm, `bigint` to Zig (442); Unicode case mapping (443); `std:` std's alone (445) | opus |
| B-00i | the Erlang term library (`rt.zig`) and the OTP functions move into std-wasm; `bp_wat_rt.wasm` goes; beam-to-wasm reads std-wasm's OTP table (decision 450) — before B-30 | opus |
| B-00j | the comptime stops calling beam-to-wasm: a host function answers by `std:` or `fn:`, never an Erlang cell; `cells.zig` and the Erlang-cell translation deleted from compiler-core (decision 452); the package name `std` reserved (453) | sonnet |
| B-00k | **Conformance** — the B-00 group's last step (459): the suite green, the group's changes analysed against the cells, the cells written, the missing ones proposed | opus |

## The cache group — B-57 … B-64 (decisions 508–513)

**Goal:** a gate as fast as its dependencies allow, without trusting a stored answer about what it tests. Measured on
2026-10-12, a quiet machine: one emilia cell (`alpha`) takes ~21 s on erlang — ~19 s compiling ~4100 `.erl` modules,
~3400 of them dead copies of `Token`'s formatters — and a hello world 0.3 s; emilia's gate with conformance ~48 min.

**The plan:** one code cache, the CLI's, for every target, holding only dependencies (509); no test result cached
(510); a cell named after its directory (511); a workspace declaring what its members share, every
`conformance/modules/` one, so a library's cells share one dependency closure and one cache (512); a gate run without
conformance takes no lock (508, landed in the meta `scripts/gate.sh`; botopink-lang's in B-29 step J).

**Order:** B-57 (the dead copies) and B-63 (`cell check` in parallel) → B-58 (the manifest's inherited dependencies, the workspaces, level A of the code
cache, the closure key) → B-59 (the result store removed) and B-60 (level B, after its invariant is proved) → B-64 (a module's tests a unit of their own), beside B-60 and before B-60's S4 · B-61
(cell names) beside any of them. Lane B holds B-57, lane C B-58 to B-61. After its Conformance step comes the module-model group (B-69 … B-76, B-55-a (e)), this front's continuation; beside it resume the steps paused for the cache group — B-24's Conformance step, B-39, B-41, B-43, B-51, B-52 (B-55, a study, and B-56 run beside the group). The group closes with its Conformance step:
emilia's, rakun's, onze's and botopink-lang's gates measured with conformance, cold and warm, against the numbers
above, and every cell green on every target.

## Machines

The front runs on two machines, each with its own coordinator, gate pool and main checkout (the maintainer,
2026-10-12). Each machine's steps live in its own folder; a step keeps its id and its text wherever it sits.

| Machine | Folder | Lanes and groups |
|---|---|---|
| 1 — the checker and the language | [`machine-1/144-checker/`](../../machine-1/144-checker/README.md) — with the old fronts `01-checker`, `01-compiler`, `116-bpp-file-format`, `129-import-without-from`, `130-decorator-outputs`, `134-builtins-declared`, `139-bigint`, `140-wasm-host` | lane A (B-02, B-10, B-11, B-14 … B-18, B-20, B-21, B-23); the steps this machine had in flight when the front was split — B-22 (its design pass) and B-60 (the cache's level B; B-77 waits on it); B-19, B-24, B-25 and B-27, beside the old fronts whose work they hold (130, 139, 140, 116); then the module-model group (B-55, B-56, B-69 … B-76), in its order |
| 2 — backends, runtimes, std, tooling, the gate | [`machine-2/144-backends-tooling/`](../../machine-2/144-backends-tooling/README.md) — with every other old front's directory (`00-gate`, `02-erlang` … `114-gate-docs-and-ci`) | the rest of B-00 first; lane B but B-19, B-22, B-24, B-25; lane C but B-27; the error contract of 431 / 432 whole (B-01 … B-09, B-03 included); the cache group (B-57 … B-64 save B-60; B-77 once B-60 lands); the structural residue (B-31 … B-54, B-62 … B-68, B-78 … B-81, B-87, B-88, B-90 … B-96) |

**The rules the two machines share:**

1. **One `feat`.** Each machine lands its own steps on botopink-lang's `feat`, fast-forward only, rebased onto
   `origin/feat` right before the push; `feat` is the only place the two meet.
2. **Specs.** A coordinator ticks the boxes and moves the `status.md` lines of its own machine's steps only. A
   decision takes the next free number of `decisions-taken.md`; when both machines take one, the second push
   conflicts and that coordinator renumbers — a number is never reused. New questions go to
   `decisions-pending.md` the same way.
3. **A conflict in snapshots alone** is resolved by recording them again on the rebased tree and reading the diff,
   never by hand.
4. **A file both lanes touch** (`comptime.zig`, `codegen.zig`, `conformance/docs.md`, the AGENTS files): the one who
   lands second rebases and keeps both sides.
5. **After a pull that brings compiler changes**, each machine rebuilds its main checkout's compiler
   (`zig build -Doptimize=ReleaseSafe`): the libraries' gates run that binary.
6. **The module-model group reaches everything** (std, every library, the CLI): once machine 1 opens B-69, machine 2
   opens no new step that edits `libs/std/**` or a library until B-75 lands.
7. **B-00 first:** machine 2 closes B-00's last boxes before machine 1 opens lane A.
8. Each machine's memory is its own: a coordinator keeps its threads within its pool (`scripts/gate.sh status`) and
   never more compiler builds at once than its memory holds.
9. **The builtins group (decision 575) is next on both machines** (the maintainer, 2026-10-17): B-136 (machine 1) opens
   now; B-137 and B-138 (machine 2) open as soon as B-136 lands, 165 s10 (machine 1) after B-138, B-139 after 165 s10 (decision 605: it removes `@emit` / `@code` / `@expr` with `builtins.d.bp`), B-140 (machine 1) after B-139. Until B-140 lands no other new step opens on either machine — what is already
   open finishes; the module-model group (rule 6) opens after it. The group edits `libs/std/**`, every backend and every
   library, so rule 6's exclusivity holds for it from B-136 on. The group's threads commit with `--no-verify`
   (the maintainer, 2026-10-17 — the exception to `scripts/thread-rules.md`, stated in each prompt), after their own
   reached checks; one full gate (`scripts/gate.sh --cold` with conformance, on each machine's main checkout) runs at the
   group's end, before B-140's landing closes it.

## Lanes

Three lanes share the front; two steps run together only when their files are disjoint (fronts.md
§ Conflict rules).

| Lane | Machine | Files | Steps |
|---|---|---|---|
| A — checker | 1 | `comptime/{infer,env,diagnostics,transform}.zig`, `parser/**`, `ast.zig`, `builtins.d.bp` | B-02, B-03, B-10, B-11, B-14, B-15, B-16, B-17, B-18, B-20, B-21, B-23 |
| B — runtimes, backends, std | 2 (B-19, B-22, B-24, B-25 on 1) | `codegen/**` but `codegen/wat/**`, `libs/std/**` (`comptime/runtime/**`, `codegen/wat/**`, `modules/{std-wasm,beam-to-wasm}/**` are front 164's) | B-00a–k, B-04–B-08, B-12, B-13, B-19, B-22, B-24, B-25, B-26 (B-30 closed, superseded by 164) |
| C — tooling, docs, gate | 2 (B-27 on 1) | `compiler-cli/**`, `language-server/**`, `format.zig`, `docs.md`, `scripts/**`, workflows | B-01, B-09, B-27, B-28, B-29 |

B-00 runs alone (it moves the comptime pipeline every other step's cells run through); after it the
lanes open in order, at most six worktrees across the milestone (fronts.md § Execution order).

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `18-comptime-runtimes` s3 | B-00d |
| `05-wasm` s5 | B-00e |
| `97-std-dedupe` s11 | B-00e |
| `01-checker` s42 box 3 | B-01 |
| `01-checker` s27 | B-02 |
| `16-formatter` s10 | B-02 |
| `17-beam-memory` s2 box 1 | B-02 |
| `01-checker` s42 box 1 | B-03 |
| `97-std-dedupe` s18 box 1 | B-04 |
| `01-checker` s42 box 2 | B-05 |
| `04-js` s13 | B-06 |
| `134-builtins-declared` s2 box 4 | B-06 |
| `97-std-dedupe` s18 boxes 2, 3 | B-07 |
| `01-checker` rows box 2 | B-10 |
| `01-checker` s30 | B-11 |
| `01-checker` s32 | B-12 |
| `01-checker` s33 | B-12 |
| `14-comptime-on-beam` s6 | B-12 |
| `02-erlang` s14 | B-13 |
| `01-checker` s34 | B-14 |
| `130-decorator-outputs` s9 | B-15 |
| `01-checker` s24 | B-16 |
| `01-checker` s28 | B-16 |
| `134-builtins-declared` s2 boxes 1, 2, 3, 6 | B-16 |
| `01-checker` s23 | B-17 |
| `01-checker` s36 | B-17 |
| `14-comptime-on-beam` s8 | B-17 |
| `04-js` s12 | B-17 |
| `134-builtins-declared` s6 | B-17 |
| `01-checker` s29 | B-18 |
| `01-checker` s39 | B-18 |
| `01-checker` s40 | B-18 |
| `134-builtins-declared` s2 box 5 | B-18 |
| `130-decorator-outputs` s5 | B-19 |
| `130-decorator-outputs` s6 | B-19 |
| `130-decorator-outputs` rows | B-19 |
| `130-decorator-outputs` s7 | B-19 |
| `130-decorator-outputs` s8 | B-19 |
| `130-decorator-outputs` s10 | B-19 |
| `01-checker` s31 | B-20 |
| `01-checker` s37 | B-21 |
| `01-checker` s38 | B-21 |
| `16-formatter` s11 | B-21 |
| `01-checker` open | B-22 |
| `01-checker` s6 | B-22 |
| `04-js` s6 | B-22 |
| `12-language-tests` s2 | B-22 |
| `01-checker` s13 | B-22 |
| `03-beam` s1 | B-22 |
| `02-erlang` rows box 1 | B-22 |
| `04-js` rows | B-22 |
| `05-wasm` rows | B-22 |
| `97-std-dedupe` compiler residuals | B-22 |
| `01-checker` s18 | B-23 |
| `01-checker` s19 | B-23 |
| `01-checker` rows boxes 1, 3, 4 | B-23 |
| `139-bigint` open | B-24 |
| `04-js` s9 | B-24 |
| `97-std-dedupe` s13 | B-24 |
| `97-std-dedupe` s14 | B-24 |
| `97-std-dedupe` s15 | B-24 |
| `140-wasm-host` s4 | B-25 |
| `140-wasm-host` s5 | B-25 |
| `140-wasm-host` s6 | B-25 |
| `97-std-dedupe` s17 | B-25 |
| `05-wasm` s9 | B-25 |
| `04-js` s11 | B-25 |
| `17-beam-memory` s1 | B-26 |
| `116-bpp-file-format` s0 | B-27 |
| `116-bpp-file-format` s2 | B-27 |
| `116-bpp-file-format` s3 | B-27 |
| `116-bpp-file-format` s4 boxes 1, 2 | B-27 |
| `116-bpp-file-format` s5 | B-27 |
| `116-bpp-file-format` gate | B-27 |
| `01-checker` s22 | B-27 |
| `26-cli-tooling` s9 | B-27 |
| `26-cli-tooling` rows | B-27 |
| `23-std-purity` s1 | B-27 |
| `23-std-purity` s2 | B-27 |
| `24-effects-by-return` s1 | B-27 |
| `24-effects-by-return` s2 | B-27 |
| `24-effects-by-return` s3 | B-27 |
| `142-data-formats` s1 boxes 1, 2 | B-27 |
| `20-snap` s1 | B-27 |
| `97-std-dedupe` s4 residue | B-27 |
| `97-std-dedupe` s6 | B-27 |
| `97-std-dedupe` gate | B-27 |
| `98-packaging-tail` s2 | B-27 |
| `98-packaging-tail` s3 | B-27 |
| `16-formatter` s1 | B-28 |
| `16-formatter` s2 | B-28 |
| `16-formatter` s3 | B-28 |
| `16-formatter` s4 | B-28 |
| `16-formatter` s5 | B-28 |
| `16-formatter` s6 | B-28 |
| `16-formatter` s7 | B-28 |
| `16-formatter` s9 | B-28 |
| `114-gate-docs-and-ci` s3 | B-29 |
| `114-gate-docs-and-ci` s7 | B-29 |
| `114-gate-docs-and-ci` s8 box 1 | B-29 |
| `18-comptime-runtimes` s1 | B-29 |
| `12-language-tests` s1 | B-29 |
| `07-residuals` s1 | B-29 |
| `07-residuals` s2 | B-29 |
| `07-residuals` s4 | B-29 |
| `07-residuals` s8 | B-29 |
| `07-residuals` s9 | B-29 |

## Steps

Where each step is (its machine's folder holds its whole text).

| Step | Machine | Title |
|---|---|---|
| B-00a | [2](../../machine-2/144-backends-tooling/README.md) | First — `modules/std-wasm`: std's host functions in Zig, compiled to wasm (decision 434) |
| B-00b | [2](../../machine-2/144-backends-tooling/README.md) | `modules/beam-to-wasm`: `.beam` bytecode translated to wasm (decision 434) |
| B-00c | [2](../../machine-2/144-backends-tooling/README.md) | The comptime driver on wasm for every target (decision 434; amends 84, 341) |
| B-00d | [2](../../machine-2/144-backends-tooling/README.md) | The BEAM comptime runtime deleted; one codegen snapshot tree (decision 434) |
| B-00e | [2](../../machine-2/144-backends-tooling/README.md) | std-wasm in the user's `--target wasm` output (decision 434 (2)) |
| B-00f | [2](../../machine-2/144-backends-tooling/README.md) | `@External.Beam` deleted; `@External.Erlang` binds erlang and beam (decision 437) |
| B-00g | [2](../../machine-2/144-backends-tooling/README.md) | `wat_prelude` keeps only representation, operators, output and runtime (decision 442) |
| B-00h | [2](../../machine-2/144-backends-tooling/README.md) | A transpiled std-wasm function is one line in a snapshot (decision 446) |
| B-00i | [2](../../machine-2/144-backends-tooling/README.md) | The Erlang term library and the OTP functions in std-wasm (decision 450) |
| B-00j | [2](../../machine-2/144-backends-tooling/README.md) | The comptime stops calling beam-to-wasm (decision 452); the name `std` reserved (453) |
| B-00k | [2](../../machine-2/144-backends-tooling/README.md) | Conformance: the B-00 group's last step (decisions 458, 459) |
| B-01 | [2](../../machine-2/144-backends-tooling/README.md) | 431 (1): the effect messages and docs |
| B-02 | [1](../../machine-1/144-checker/README.md) | 305: labelled annotation arguments (`fn:`, `op:`, `wasi:`, `keyed:`) |
| B-03 | [2](../../machine-2/144-backends-tooling/README.md) | 431 (2): `throws:` on every `@External` variant, checked |
| B-04 | [2](../../machine-2/144-backends-tooling/README.md) | 431: std `failure` — `HostError`, `Failure` |
| B-05 | [2](../../machine-2/144-backends-tooling/README.md) | 431 (2): each backend wraps a `throws: true` cell |
| B-06 | [2](../../machine-2/144-backends-tooling/README.md) | 432: a failing task rejects, on four targets |
| B-07 | [2](../../machine-2/144-backends-tooling/README.md) | 431: `attempt`, and the asserts over it |
| B-08 | [2](../../machine-2/144-backends-tooling/README.md) | 431: std's hand-written catches become `throws: true` |
| B-09 | [2](../../machine-2/144-backends-tooling/README.md) | 431 / 432: the error contract in the docs and the AGENTS files |
| B-10 | [1](../../machine-1/144-checker/README.md) | 430: the compiler gaps a library works around today |
| B-11 | [1](../../machine-1/144-checker/README.md) | 316: `decl.wrapWith(f)` |
| B-12 | [2](../../machine-2/144-backends-tooling/README.md) | 346, 342: `Bytes`, `@embedFile` / `@embedBytes` |
| B-13 | [2](../../machine-2/144-backends-tooling/README.md) | 304: a method declared `-> @Result` lowered as a `@Result` on erlang |
| B-14 | [1](../../machine-1/144-checker/README.md) | 359: a spread copies a record's fields |
| B-15 | [1](../../machine-1/144-checker/README.md) | 302: a tag is a `@Decl` |
| B-16 | [1](../../machine-1/144-checker/README.md) | 280, 307, 308: typed decorator arguments' rest, derived types' rest, `compiler.Field<T>` |
| B-17 | [1](../../machine-1/144-checker/README.md) | 277, 376, 354–388: hooks, stages, contexts |
| B-18 | [1](../../machine-1/144-checker/README.md) | 311, 415, 426, 429: templates |
| B-19 | [1](../../machine-1/144-checker/README.md) | 216, 281, 298, 353, 356: decorator outputs |
| B-20 | [1](../../machine-1/144-checker/README.md) | 330: the optional operators' rest and their codemod |
| B-21 | [1](../../machine-1/144-checker/README.md) | 364, 408, 409: `@Expr` hygiene, the typed function expression, the tail value |
| B-22 | [1](../../machine-1/144-checker/README.md) | The backends' and the checker's residue rows |
| B-23 | [1](../../machine-1/144-checker/README.md) | 247, 255, 310 and the checker's rows |
| B-24 | [1](../../machine-1/144-checker/README.md) | 319, 320, 332: numbers and strings exact everywhere |
| B-25 | [1](../../machine-1/144-checker/README.md) | 333 (B), 334, 335: the wasm host |
| B-26 | [2](../../machine-2/144-backends-tooling/README.md) | 340: the keyed `Dict`'s per-row increment |
| B-27 | [1](../../machine-1/144-checker/README.md) | Tooling, std residue, `.bpp` in the toolchain, `json` out of std |
| B-28 | [2](../../machine-2/144-backends-tooling/README.md) | The formatter: the `;` after a braced block, C-12, the trailing comma, annotations as written |
| B-29 | [2](../../machine-2/144-backends-tooling/README.md) | The gate, CI and the residual sweep |
| B-30 | [2](../../machine-2/144-backends-tooling/README.md) | wasm memory as erlang's, a heap per process in std-wasm (448, 449, 522) — closed as superseded by group wasm-gc (wasmgc-a): its built boxes stay, its open boxes withdrawn |
| B-31 | [2](../../machine-2/144-backends-tooling/README.md) | a template whose only part is a float hole is a string on wasm (structural, decision 430) |
| B-32 | [2](../../machine-2/144-backends-tooling/README.md) | structural equality at build is iterative; an arithmetic error at build reads as Erlang's (decisions 471, 472) |
| B-33 | [2](../../machine-2/144-backends-tooling/README.md) | `@External.Wasm`'s cells as labelled arguments (decision 481) |
| B-34 | [2](../../machine-2/144-backends-tooling/README.md) | the BEAM assembler rejects `styled`'s module (structural, decision 430) |
| B-35 | [2](../../machine-2/144-backends-tooling/README.md) | `@println` has no wasm lowering (structural, decision 430) |
| B-36 | [2](../../machine-2/144-backends-tooling/README.md) | styled's hook red on `feat`: "tab4's class is not a constant of the emitted module" (structural, decision 430) |
| B-37 | [2](../../machine-2/144-backends-tooling/README.md) | dependencies from `.botopinkbuild/deps/` first; `bpmp link` (decision 483) |
| B-38 | [2](../../machine-2/144-backends-tooling/README.md) | `botopink cell check`: a full run that drops a cell; a `path` dependency inside a cell (found moving rakun'… |
| B-39 | [2](../../machine-2/144-backends-tooling/README.md) | a module-level `val` read by the next one is unbound on erlang (structural, decision 430) |
| B-40 | [2](../../machine-2/144-backends-tooling/README.md) | a cell's targets are its `botopink.json`'s `"targets"`, never a `targets` file (decision 475 (1)) |
| B-41 | [2](../../machine-2/144-backends-tooling/README.md) | a library's abort reads the same on every target (structural, decision 430) |
| B-42 | [2](../../machine-2/144-backends-tooling/README.md) | wasm: a cell with a `path` dependency prints nothing; emilia's `arbitrary.bp` does not build (structural, d… |
| B-43 | [2](../../machine-2/144-backends-tooling/README.md) | a `Set` of structurally equal records keeps one on every target (decision 210) |
| B-44 | [2](../../machine-2/144-backends-tooling/README.md) | wasm prints a lifted `bool` as `1` (structural, decision 430) |
| B-45 | [2](../../machine-2/144-backends-tooling/README.md) | erlang: `lib.member()` through a library's default handle is unbound (structural, decision 430) |
| B-46 | [2](../../machine-2/144-backends-tooling/README.md) | a decorator body reaches a nested std namespace (`io.random`) (structural, decision 430) |
| B-47 | [2](../../machine-2/144-backends-tooling/README.md) | a refusal cell claims the label under the caret (decision 485) |
| B-48 | [2](../../machine-2/144-backends-tooling/README.md) | a raise inside a decorator body is located at the raising call (decision 451 (3)) |
| B-51 | [2](../../machine-2/144-backends-tooling/README.md) | commonJS prints an `f64` without its `.0` (structural, decision 430) |
| B-52 | [2](../../machine-2/144-backends-tooling/README.md) | wasm prints a string field or an awaited string as a number (structural, decision 430) |
| B-53 | [2](../../machine-2/144-backends-tooling/README.md) | `@print` of a `@Result` prints the host's form (structural, decision 430) |
| B-54 | [2](../../machine-2/144-backends-tooling/README.md) | `botopink format` rewrites an annotation's labelled argument `keyed: true` to `keyed = true` |
| B-55 | [1](../../machine-1/144-checker/README.md) | whole-package analysis: can two modules of a package import each other? (study, s23-i) |
| B-56 | [1](../../machine-1/144-checker/README.md) | `botopink migrate` removed (s23-i) |
| B-60 | [1](../../machine-1/144-checker/README.md) | the code cache, level B: a dependency's analysis on disk in `.botopinkbuild/analysis/` (decision 509 (1); t… |
| B-62 | [2](../../machine-2/144-backends-tooling/README.md) | nine cells red on `feat`: a manifest column and a dependency's path |
| B-63 | [2](../../machine-2/144-backends-tooling/README.md) | `botopink cell check` runs cells in parallel (`--jobs`) |
| B-64 | [2](../../machine-2/144-backends-tooling/README.md) | a module's tests are a unit of their own, on every target (decision 513) |
| B-67 | [2](../../machine-2/144-backends-tooling/README.md) | erlang: a library's record imported beside a std record of the same name builds std's (D3) |
| B-68 | [2](../../machine-2/144-backends-tooling/README.md) | wasm: a method call on a template's answer does not resolve (D4) |
| B-69 | [1](../../machine-1/144-checker/README.md) | a file is a module: `mod` / `pub mod` and the root file removed (B-55-a (e) (1), (2), (8)) |
| B-70 | [1](../../machine-1/144-checker/README.md) | `src/comptime/`, the build layer (B-55-a (e) (3)) |
| B-71 | [1](../../machine-1/144-checker/README.md) | blocks: modules importing each other, headers before bodies, `dependency loop` (B-55-a (e) (4), (6)) |
| B-72 | [1](../../machine-1/144-checker/README.md) | per block: decorators after the bodies, meta and catalogues filled (B-55-a (e) (5), (6), (7)) |
| B-73 | [1](../../machine-1/144-checker/README.md) | commonJS: a module cycle loads (B-55-a (e) (4)) |
| B-74 | [1](../../machine-1/144-checker/README.md) | the language server checks the edited module's block (B-55-a (e)) |
| B-75 | [1](../../machine-1/144-checker/README.md) | std and every library on the module model (B-55-a (e)) |
| B-76 | [1](../../machine-1/144-checker/README.md) | the module-model group's Conformance step |
| B-77 | [2](../../machine-2/144-backends-tooling/README.md) | `botopink cache`: one place for the caches, parallelism by the machine's pool, no `--cold` / `--jobs` (the… |
| B-78 | [2](../../machine-2/144-backends-tooling/README.md) | commonJS writes an `f64` as text with its decimal part: a template hole, `.toString()`, `string + f64` |
| B-79 | [2](../../machine-2/144-backends-tooling/README.md) | `botopink run` of a program with no `fn main`: one located error on every target and host (decision 517) |
| B-80 | [2](../../machine-2/144-backends-tooling/README.md) | onze-cli's CSS accessors test red under `test-libs` on commonJS and erlang |
| B-81 | [2](../../machine-2/144-backends-tooling/README.md) | rakun-data's `#[query]` test red under `test-libs` on erlang |
| B-82 | [164](../../machine-2/144-backends-tooling/164-wasm-gc/README.md) | moved to front 164 wasm-gc, s1 |
| B-83 | [164](../../machine-2/144-backends-tooling/164-wasm-gc/README.md) | moved to front 164 wasm-gc, s2 |
| B-84 | [164](../../machine-2/144-backends-tooling/164-wasm-gc/README.md) | moved to front 164 wasm-gc, s3 |
| B-85 | [164](../../machine-2/144-backends-tooling/164-wasm-gc/README.md) | moved to front 164 wasm-gc, s4 |
| B-86 | [2](../../machine-2/144-backends-tooling/README.md) | the catalogue across packages (`@TypeInfo.all` reaching a dependency's declarations) and the lib-agnostic gate's list `rakun|query` (front 165 s4, mono-a) |
| B-87 | [2](../../machine-2/144-backends-tooling/README.md) | erlang: a `var` reassigned inside a nested arm reaches a `defer` late (539) |
| B-88 | [2](../../machine-2/144-backends-tooling/README.md) | a jump from a block or a `case` arm reaches its loop or generator on commonJS and erlang (541 (2)) |
| B-89 | [2](../../machine-2/144-backends-tooling/README.md) | beam: emilia's module refused by the BEAM assembler (`test_heap`, an implementation limit) — every emilia cell red on beam |
| B-90 | [2](../../machine-2/144-backends-tooling/README.md) | commonJS: an unmarked raise is `crash`, and `abort_text_panic` (546, 535) |
| B-91 | [2](../../machine-2/144-backends-tooling/README.md) | `import-of-failed-module` names the failed module's file as the diagnostics label does (545) |
| B-92 | [2](../../machine-2/144-backends-tooling/README.md) | a raise at build: a module's own template located, no frame for a call never entered (532) |
| B-93 | [2](../../machine-2/144-backends-tooling/README.md) | commonJS: a positional pattern on an imported variant lowered against another package's same-named variant (`Text(value)` → `$0`) |
| B-94 | [2](../../machine-2/144-backends-tooling/README.md) | erlang and beam: `Bytes.length` read as a property is a text length |
| B-95 | [2](../../machine-2/144-backends-tooling/README.md) | beam: a field read on a type the module does not declare answers the whole record |
| B-96 | [2](../../machine-2/144-backends-tooling/README.md) | an ambient behavior as a parameter type (539 (6)) |
| B-97 | [2](../../machine-2/144-backends-tooling/README.md) | beam: a `Declared`'s field read in a dependency answers the whole record (front 165 s5) |
| B-98 | [1](../../machine-1/144-checker/README.md) | a `.bp` and a `.d.bp` of one stem in a package's `files` are one module written twice (front 165 s5) |
| B-99 | [1](../../machine-1/144-checker/README.md) | a library's catalogue read at the caller: `rakun.boot()` with no argument answering the program's `@TypeInfo.all` (front 165 s5, mono-a) |
| B-100 | [2](../../machine-2/144-backends-tooling/README.md) | the tooling reads the libraries at their new homes: rakun's workspace, `query` (front 165 s8) |
| B-101 | [2](../../machine-2/144-backends-tooling/README.md) | commonJS: a `case` no arm matches answers `undefined` instead of raising `crash` (535, 546) |
| B-102 | [2](../../machine-2/144-backends-tooling/README.md) | erlang: an external template's Erlang-escaped quote loses its backslash |
| B-103 | [2](../../machine-2/144-backends-tooling/README.md) | erlang and beam: `try … catch` contains a `host` raise — only `attempt` may (431, 546; front 165) |
| B-104 | [2](../../machine-2/144-backends-tooling/README.md) | `continue :outer` is not read (541 (2)) |
| B-105 | [2](../../machine-2/144-backends-tooling/README.md) | beam: a loop's label is ignored (541 (2)) |
| B-106 | [2](../../machine-2/144-backends-tooling/README.md) | erlang: a value `if` whose branch reassigns a `var` is refused by erlc (539, 541) |
| B-107 | [2](../../machine-2/144-backends-tooling/README.md) | `Index` and `Slice` are ambient (decision 63) but not as `Display` and `Closeable` are |
| B-108 | [2](../../machine-2/144-backends-tooling/README.md) | `scripts/tsc-check.sh` red on botopink-lang's own cells: a `.d.ts` naming `Declared`, the `conformance/test/` project suites |
| B-112 | [2](../../machine-2/144-backends-tooling/README.md) | `test-analysis-equivalence` reads rakun's conformance by feature (548, front 165 s9) |
| B-113 | [2](../../machine-2/144-backends-tooling/README.md) | `botopink cell check` keeps a cell's path inside its workspace, so one root manifest serves (548) |
| B-114 | [2](../../machine-2/144-backends-tooling/README.md) | commonJS: an `f64` passed as a type parameter is written the JS engine's way (521) |
| B-115 | [2](../../machine-2/144-backends-tooling/README.md) | commonJS: the generic calls B-114's print shape does not reach — a fn value, another module, a generic method (521) |
| B-116 | [2](../../machine-2/144-backends-tooling/README.md) | the body markers `iter`, `async`, `async iter`, `component`; the `@` types renamed into std; a failure a `Result` in the value's layer (553) |
| B-117 | [2](../../machine-2/144-backends-tooling/README.md) | `botopink check` of a project of refused decorator markers peaks at 8 GB |
| B-118 | [2](../../machine-2/144-backends-tooling/README.md) | beam: an `iter loop` as a lambda's tail aborts |
| B-119 | [2](../../machine-2/144-backends-tooling/README.md) | commonJS: an adopted behavior `default fn … -> @Task` is emitted without `async` |
| B-120 | [2](../../machine-2/144-backends-tooling/README.md) | commonJS: a contextual variant `.Term` as an argument of a namespace call is emitted bare |
| B-121 | [2](../../machine-2/144-backends-tooling/README.md) | beam: a user function named `run` or `size` is taken for a std binding |
| B-122 | [2](../../machine-2/144-backends-tooling/README.md) | beam: `.toString()` on a tuple is `unresolved_method` |
| B-123 | [1](../../machine-1/144-checker/README.md) | a `//` comment between statements of a `case` arm block is a parse error |
| B-124 | [2](../../machine-2/144-backends-tooling/README.md) | beam: an Erlang host template with a binary pattern other than a fixed-size unsigned segment is refused |
| B-125 | [1](../../machine-1/144-checker/README.md) | a `//` comment after a block's tail expression is a parse error |
| B-126 | [2](../../machine-2/144-backends-tooling/README.md) | std: an `FsError` carries its own text, `message()` (decision 563) |
| B-127 | [2](../../machine-2/144-backends-tooling/README.md) | `botopink check` cold: the analysis arena and a decorator's trace listing kept for the session |
| B-128 | [2](../../machine-2/144-backends-tooling/README.md) | erlang, beam, wasm: a generator runs its whole body at the call (105, 125) |
| B-129 | [2](../../machine-2/144-backends-tooling/README.md) | the gate's job budget counts 768 MiB a job; the commit hook alone runs a 31 GB machine out of memory |
| B-130 | [2](../../machine-2/144-backends-tooling/README.md) | std: `json`, `regex` and `process` answer their own error enums (486) |
| B-131 | [2](../../machine-2/144-backends-tooling/README.md) | wasm: three `std_decorator_*` cells read `std/testing/mocks.bp` a line off |
| B-132 | [2](../../machine-2/144-backends-tooling/README.md) | `botopink cell check`: a target's exclusion probe copies the cell without its workspace's literal entries |
| B-133 | [2](../../machine-2/144-backends-tooling/README.md) | erlang, beam: a generator nobody closes outlives its creator |
| B-134 | [2](../../machine-2/144-backends-tooling/README.md) | erlang: a generator of only literal `yield`s is a list and replays |
| B-135 | [2](../../machine-2/144-backends-tooling/README.md) | erlang, beam: an `iter` loop's captured `var` is a copy after an outer write |
| B-136 | [1](../../machine-1/144-checker/README.md) | the keyword `compiler` and the behavior `Compiler`; `comptime` / `syntax` on a parameter, no `Expr<T>` type, `-> syntax T`, the tree rule; `type<T>`; the codemod over std and conformance (decision 575 (3)–(5)) |
| B-137 | [2](../../machine-2/144-backends-tooling/README.md) | `compiler.init`: a decorator's run-time code in the program's init list, before `main`, on every target; `@emit` and `@code` removed after 165 s10 (decision 575 (3), (8)) |
| B-138 | [2](../../machine-2/144-backends-tooling/README.md) | `external` as one std function over `Implementation`; `compiler.implement`; `declare-without-implementation`; the backends read `Implementation` alone; `print` / `println` / `debug` by their cells (decision 575 (6)) |
| B-139 | [2](../../machine-2/144-backends-tooling/README.md) | no `.d.bp`; no `#[builtin]` / `@name` (606): the prelude types and behaviors into `primitives.bp`, `print` (`io.terminal`) and `panic` (`failure`) imported, `typeInfo` / `embed` / `external` members of `compiler` (`embed` the link only, 607), `compiler.Info<T>` in `types.bp`'s `Type` (the utilities) and `compiler.bp`'s `Field<T>` / `Info<T>` (624, 630); the removed builtins (decision 575 (1), (2), (7), (8), 606) |
| B-140 | [1](../../machine-1/144-checker/README.md) | `Type` in botopink in `types.bp`, its records `compiler.Field<T>` / `compiler.Info<T>` in `compiler.bp` (624, 630): `compiler.Field<T>(name, type, annotations)`, `compiler.record` / `fields` / `optional` / `required` (decision 575 (5), (7)) |
| B-141 | [2](../../machine-2/144-backends-tooling/README.md) | wasm: `join` on an optional meta's list, a coalesced list's `join`, `map(Card)` in an imported module (found by B-136's `setMeta` migration) |
| B-142 | [2](../../machine-2/144-backends-tooling/README.md) | wasm: a generator in a linear-memory module (and `@Stream`) runs its whole body at the call (decision 105) |
| B-143 | [2](../../machine-2/144-backends-tooling/README.md) | commonJS: `push` on an array mutates every binding that holds it — a `val` copy of a `var`, a caller's argument — where erlang rebinds the `var` and leaves the value alone (decisions 447 (2), 448 (2), 547) |
| B-144 | [2](../../machine-2/144-backends-tooling/README.md) | erlang / beam: a namespace member's chained call (`query.of(…).where(…).select(…).toArray()`) dispatches `toArray()` on the `Query` record — `bp_unsupported_method join`; query's cell `generic_loader_binding` red on erlang and beam, query's feat CI red on it |
| B-145 | [1](../144-checker/README.md) | an annotation `#[name]` that names no decorator (unbound, or a namespace such as `#[check]` naming a module) is dropped silently — no refusal, empty output |
| B-146 | [1](../144-checker/README.md) | checker: a decorator body reading `compiler.catalogue` / `find` fails every importer (`typeinfo-all-imported`, against 551); `.Variant` in an annotation argument refused as a type mismatch; `v is fn() -> T` / `v is T` in a generic body (found by 165 s5) |
| B-147 | [2](../../machine-2/144-backends-tooling/README.md) | erlang / beam: `m.make().run(s)` emits `run/2 undefined`; `await f().make()` in a component body never runs it; on beam a `for` lambda loop loses a module and `registry.find(n)?.name ?? d` answers the default (found by 165 s5) |
| B-148 | [2](../../machine-2/144-backends-tooling/README.md) | the primitive widths are types (`pub type i32 implement Signed`), a behavior a contract with no cell; the host cells on the types, the backends' hand-written chains replaced by the `implement` clauses (decision 617) — after B-139, before B-140 |
| B-149 | [2](../../machine-2/144-backends-tooling/README.md) | no code from text: the typed AST (`Node` and its kinds) in `compiler.bp`, `compiler.ast(node) -> anyvalue` in place of `compiler.build(text)`, `compiler.buildType(name, fields)` over `compiler.Field<unknown>[]` (decision 625) — after B-137's tail |
| B-150 | [2](../../machine-2/144-backends-tooling/README.md) | wasm: a type's method as a record-constructor argument resolves to the module's same-named `fn` (`init_executor_handle_not_module_name`, 613) — after B-142 |
| B-152 | [1](../144-checker/README.md) | checker: a function's type parameter bound by a parameter, never by the return type alone — `type-parameter-unbound` (decision 668); std's 13 and the cells' 11 sites migrated, the libraries' 41 listed for their fronts |
| B-109 | [2](../../machine-2/144-backends-tooling/README.md) | beam: a `continue :label` under an in-frame loop inside a fun-walked loop, and two labels continued from one loop |
| B-110 | [2](../../machine-2/144-backends-tooling/README.md) | an unknown generic type name is accepted unchecked (`Bogus<i32, i32>`) |
| B-111 | [2](../../machine-2/144-backends-tooling/README.md) | a `val` annotation naming an unknown type: `type mismatch`, located at the statement |
