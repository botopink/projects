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
folder of the machine that runs its steps (`machine-1-checker/01-checker/context.md`,
`machine-1-checker/116-bpp-file-format/examples/` …). The steps run in the order written: **first B-00 (434)**,
then the error contract of 431 / 432 (B-01–B-09), then the structural fixes the library fronts wait on
(decision 430: B-10–B-19), then the rest (B-20–B-29).

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
| 1 — the checker and the language | [`machine-1-checker/`](machine-1-checker/README.md) — with the old fronts `01-checker`, `01-compiler`, `116-bpp-file-format`, `129-import-without-from`, `130-decorator-outputs`, `134-builtins-declared`, `139-bigint`, `140-wasm-host` | lane A (B-02, B-10, B-11, B-14 … B-18, B-20, B-21, B-23); the steps this machine had in flight when the front was split — B-22 (its design pass) and B-60 (the cache's level B; B-77 waits on it); B-19, B-24, B-25 and B-27, beside the old fronts whose work they hold (130, 139, 140, 116); then the module-model group (B-55, B-56, B-69 … B-76), in its order |
| 2 — backends, runtimes, std, tooling, the gate | [`machine-2-backends-tooling/`](machine-2-backends-tooling/README.md) — with every other old front's directory (`00-gate`, `02-erlang` … `114-gate-docs-and-ci`) | the rest of B-00 first; lane B but B-19, B-22, B-24, B-25; lane C but B-27; the error contract of 431 / 432 whole (B-01 … B-09, B-03 included); the cache group (B-57 … B-64 save B-60; B-77 once B-60 lands); the structural residue (B-31 … B-54, B-62 … B-68, B-78 … B-81) |

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

## Lanes

Three lanes share the front; two steps run together only when their files are disjoint (fronts.md
§ Conflict rules).

| Lane | Machine | Files | Steps |
|---|---|---|---|
| A — checker | 1 | `comptime/{infer,env,diagnostics,transform}.zig`, `parser/**`, `ast.zig`, `builtins.d.bp` | B-02, B-03, B-10, B-11, B-14, B-15, B-16, B-17, B-18, B-20, B-21, B-23 |
| B — runtimes, backends, std | 2 (B-19, B-22, B-24, B-25 on 1) | `comptime/runtime/**`, `codegen/**`, `libs/std/**`, `modules/{std-wasm,beam-to-wasm}/**` | B-00a–k, B-04–B-08, B-12, B-13, B-19, B-22, B-24, B-25, B-26, B-30 |
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
| B-00a | [2](machine-2-backends-tooling/README.md) | First — `modules/std-wasm`: std's host functions in Zig, compiled to wasm (decision 434) |
| B-00b | [2](machine-2-backends-tooling/README.md) | `modules/beam-to-wasm`: `.beam` bytecode translated to wasm (decision 434) |
| B-00c | [2](machine-2-backends-tooling/README.md) | The comptime driver on wasm for every target (decision 434; amends 84, 341) |
| B-00d | [2](machine-2-backends-tooling/README.md) | The BEAM comptime runtime deleted; one codegen snapshot tree (decision 434) |
| B-00e | [2](machine-2-backends-tooling/README.md) | std-wasm in the user's `--target wasm` output (decision 434 (2)) |
| B-00f | [2](machine-2-backends-tooling/README.md) | `@External.Beam` deleted; `@External.Erlang` binds erlang and beam (decision 437) |
| B-00g | [2](machine-2-backends-tooling/README.md) | `wat_prelude` keeps only representation, operators, output and runtime (decision 442) |
| B-00h | [2](machine-2-backends-tooling/README.md) | A transpiled std-wasm function is one line in a snapshot (decision 446) |
| B-00i | [2](machine-2-backends-tooling/README.md) | The Erlang term library and the OTP functions in std-wasm (decision 450) |
| B-00j | [2](machine-2-backends-tooling/README.md) | The comptime stops calling beam-to-wasm (decision 452); the name `std` reserved (453) |
| B-00k | [2](machine-2-backends-tooling/README.md) | Conformance: the B-00 group's last step (decisions 458, 459) |
| B-01 | [2](machine-2-backends-tooling/README.md) | 431 (1): the effect messages and docs |
| B-02 | [1](machine-1-checker/README.md) | 305: labelled annotation arguments (`fn:`, `op:`, `wasi:`, `keyed:`) |
| B-03 | [2](machine-2-backends-tooling/README.md) | 431 (2): `throws:` on every `@External` variant, checked |
| B-04 | [2](machine-2-backends-tooling/README.md) | 431: std `failure` — `HostError`, `Failure` |
| B-05 | [2](machine-2-backends-tooling/README.md) | 431 (2): each backend wraps a `throws: true` cell |
| B-06 | [2](machine-2-backends-tooling/README.md) | 432: a failing task rejects, on four targets |
| B-07 | [2](machine-2-backends-tooling/README.md) | 431: `attempt`, and the asserts over it |
| B-08 | [2](machine-2-backends-tooling/README.md) | 431: std's hand-written catches become `throws: true` |
| B-09 | [2](machine-2-backends-tooling/README.md) | 431 / 432: the error contract in the docs and the AGENTS files |
| B-10 | [1](machine-1-checker/README.md) | 430: the compiler gaps a library works around today |
| B-11 | [1](machine-1-checker/README.md) | 316: `decl.wrapWith(f)` |
| B-12 | [2](machine-2-backends-tooling/README.md) | 346, 342: `Bytes`, `@embedFile` / `@embedBytes` |
| B-13 | [2](machine-2-backends-tooling/README.md) | 304: a method declared `-> @Result` lowered as a `@Result` on erlang |
| B-14 | [1](machine-1-checker/README.md) | 359: a spread copies a record's fields |
| B-15 | [1](machine-1-checker/README.md) | 302: a tag is a `@Decl` |
| B-16 | [1](machine-1-checker/README.md) | 280, 307, 308: typed decorator arguments' rest, derived types' rest, `Type.Field<T>` |
| B-17 | [1](machine-1-checker/README.md) | 277, 376, 354–388: hooks, stages, contexts |
| B-18 | [1](machine-1-checker/README.md) | 311, 415, 426, 429: templates |
| B-19 | [1](machine-1-checker/README.md) | 216, 281, 298, 353, 356: decorator outputs |
| B-20 | [1](machine-1-checker/README.md) | 330: the optional operators' rest and their codemod |
| B-21 | [1](machine-1-checker/README.md) | 364, 408, 409: `@Expr` hygiene, the typed function expression, the tail value |
| B-22 | [1](machine-1-checker/README.md) | The backends' and the checker's residue rows |
| B-23 | [1](machine-1-checker/README.md) | 247, 255, 310 and the checker's rows |
| B-24 | [1](machine-1-checker/README.md) | 319, 320, 332: numbers and strings exact everywhere |
| B-25 | [1](machine-1-checker/README.md) | 333 (B), 334, 335: the wasm host |
| B-26 | [2](machine-2-backends-tooling/README.md) | 340: the keyed `Dict`'s per-row increment |
| B-27 | [1](machine-1-checker/README.md) | Tooling, std residue, `.bpp` in the toolchain, `json` out of std |
| B-28 | [2](machine-2-backends-tooling/README.md) | The formatter: the `;` after a braced block, C-12, the trailing comma, annotations as written |
| B-29 | [2](machine-2-backends-tooling/README.md) | The gate, CI and the residual sweep |
| B-30 | [2](machine-2-backends-tooling/README.md) | wasm memory managed as erlang's: a heap per process, collected, in std-wasm (decisions 448, 449) |
| B-31 | [2](machine-2-backends-tooling/README.md) | a template whose only part is a float hole is a string on wasm (structural, decision 430) |
| B-32 | [2](machine-2-backends-tooling/README.md) | structural equality at build is iterative; an arithmetic error at build reads as Erlang's (decisions 471, 472) |
| B-33 | [2](machine-2-backends-tooling/README.md) | `@External.Wasm`'s cells as labelled arguments (decision 481) |
| B-34 | [2](machine-2-backends-tooling/README.md) | the BEAM assembler rejects `styled`'s module (structural, decision 430) |
| B-35 | [2](machine-2-backends-tooling/README.md) | `@println` has no wasm lowering (structural, decision 430) |
| B-36 | [2](machine-2-backends-tooling/README.md) | styled's hook red on `feat`: "tab4's class is not a constant of the emitted module" (structural, decision 430) |
| B-37 | [2](machine-2-backends-tooling/README.md) | dependencies from `.botopinkbuild/deps/` first; `bpmp link` (decision 483) |
| B-38 | [2](machine-2-backends-tooling/README.md) | `botopink cell check`: a full run that drops a cell; a `path` dependency inside a cell (found moving rakun'… |
| B-39 | [2](machine-2-backends-tooling/README.md) | a module-level `val` read by the next one is unbound on erlang (structural, decision 430) |
| B-40 | [2](machine-2-backends-tooling/README.md) | a cell's targets are its `botopink.json`'s `"targets"`, never a `targets` file (decision 475 (1)) |
| B-41 | [2](machine-2-backends-tooling/README.md) | a library's abort reads the same on every target (structural, decision 430) |
| B-42 | [2](machine-2-backends-tooling/README.md) | wasm: a cell with a `path` dependency prints nothing; emilia's `arbitrary.bp` does not build (structural, d… |
| B-43 | [2](machine-2-backends-tooling/README.md) | a `Set` of structurally equal records keeps one on every target (decision 210) |
| B-44 | [2](machine-2-backends-tooling/README.md) | wasm prints a lifted `bool` as `1` (structural, decision 430) |
| B-45 | [2](machine-2-backends-tooling/README.md) | erlang: `lib.member()` through a library's default handle is unbound (structural, decision 430) |
| B-46 | [2](machine-2-backends-tooling/README.md) | a decorator body reaches a nested std namespace (`io.random`) (structural, decision 430) |
| B-47 | [2](machine-2-backends-tooling/README.md) | a refusal cell claims the label under the caret (decision 485) |
| B-48 | [2](machine-2-backends-tooling/README.md) | a raise inside a decorator body is located at the raising call (decision 451 (3)) |
| B-51 | [2](machine-2-backends-tooling/README.md) | commonJS prints an `f64` without its `.0` (structural, decision 430) |
| B-52 | [2](machine-2-backends-tooling/README.md) | wasm prints a string field or an awaited string as a number (structural, decision 430) |
| B-53 | [2](machine-2-backends-tooling/README.md) | `@print` of a `@Result` prints the host's form (structural, decision 430) |
| B-54 | [2](machine-2-backends-tooling/README.md) | `botopink format` rewrites an annotation's labelled argument `keyed: true` to `keyed = true` |
| B-55 | [1](machine-1-checker/README.md) | whole-package analysis: can two modules of a package import each other? (study, s23-i) |
| B-56 | [1](machine-1-checker/README.md) | `botopink migrate` removed (s23-i) |
| B-60 | [1](machine-1-checker/README.md) | the code cache, level B: a dependency's analysis on disk in `.botopinkbuild/analysis/` (decision 509 (1); t… |
| B-62 | [2](machine-2-backends-tooling/README.md) | nine cells red on `feat`: a manifest column and a dependency's path |
| B-63 | [2](machine-2-backends-tooling/README.md) | `botopink cell check` runs cells in parallel (`--jobs`) |
| B-64 | [2](machine-2-backends-tooling/README.md) | a module's tests are a unit of their own, on every target (decision 513) |
| B-67 | [2](machine-2-backends-tooling/README.md) | erlang: a library's record imported beside a std record of the same name builds std's (D3) |
| B-68 | [2](machine-2-backends-tooling/README.md) | wasm: a method call on a template's answer does not resolve (D4) |
| B-69 | [1](machine-1-checker/README.md) | a file is a module: `mod` / `pub mod` and the root file removed (B-55-a (e) (1), (2), (8)) |
| B-70 | [1](machine-1-checker/README.md) | `src/comptime/`, the build layer (B-55-a (e) (3)) |
| B-71 | [1](machine-1-checker/README.md) | blocks: modules importing each other, headers before bodies, `dependency loop` (B-55-a (e) (4), (6)) |
| B-72 | [1](machine-1-checker/README.md) | per block: decorators after the bodies, meta and catalogues filled (B-55-a (e) (5), (6), (7)) |
| B-73 | [1](machine-1-checker/README.md) | commonJS: a module cycle loads (B-55-a (e) (4)) |
| B-74 | [1](machine-1-checker/README.md) | the language server checks the edited module's block (B-55-a (e)) |
| B-75 | [1](machine-1-checker/README.md) | std and every library on the module model (B-55-a (e)) |
| B-76 | [1](machine-1-checker/README.md) | the module-model group's Conformance step |
| B-77 | [2](machine-2-backends-tooling/README.md) | `botopink cache`: one place for the caches, parallelism by the machine's pool, no `--cold` / `--jobs` (the… |
| B-78 | [2](machine-2-backends-tooling/README.md) | commonJS writes an `f64` as text with its decimal part: a template hole, `.toString()`, `string + f64` |
| B-79 | [2](machine-2-backends-tooling/README.md) | `botopink run` of a program with no `fn main`: one located error on every target and host (decision 517) |
| B-80 | [2](machine-2-backends-tooling/README.md) | onze-cli's CSS accessors test red under `test-libs` on commonJS and erlang |
| B-81 | [2](machine-2-backends-tooling/README.md) | rakun-data's `#[query]` test red under `test-libs` on erlang |
