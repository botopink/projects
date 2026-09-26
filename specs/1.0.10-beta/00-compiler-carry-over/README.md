# Front 00 — Compiler Carry-Over

**Track:** compiler
**Priority:** critical — the ecosystem milestone froze the compiler and wrote fifty rows of
[`language-gaps.md`](../language-gaps.md) around it; eleven of those rows bottom out in
an item below, and the first three items are what every server front runs on
**Target:** all four backends; erlang and beam first, because that is where identity and `xs[0]` are wrong
**Wave:** 0
**Depends on:** none — this front is the floor. Inside it the items depend on each other as each
section says; C-01 is the spine
**Owns:** `repository/botopink-lang/modules/compiler-core/src/**` (checker, parser, formatter, the four
emitters), `repository/botopink-lang/modules/compiler-cli/src/cli/{build,run,format_cmd}.zig`,
`repository/botopink-lang/libs/std/**` (the rows named below), `repository/botopink-lang/tests/language/**`,
`repository/botopink-lang/scripts/gate.sh`, and `repository/botopink-lang/modules/language-server/**`
for C-19 — the ownership per item is the 1.0.5 front's, carried in each copied README; two items that
touch one file are sequenced, never merged
**Does not touch:** the five library repositories except where an item names a `libs/std` or reformat
row (C-02, C-14, C-17); the 1.0.10 track fronts under `03-rakun/`, `04-jhonstart/`, `05-emilia/`,
`06-onze/` — they consume what lands here and add nothing to it
**Reference:** [`specs/1.0.5-beta/closure.md`](../../1.0.5-beta/closure.md) (what landed, with evidence) ·
[`specs/1.0.5-beta/decisions-taken.md`](../../1.0.5-beta/decisions-taken.md) (the record every item
implements against — it is **not** copied; links inside the copied deep dives that say
`../decisions-taken.md` resolve there) · [`specs/1.0.5-beta/fronts.md`](../../1.0.5-beta/fronts.md)
(ownership and carve-outs)

---

Every open or in-progress item of 1.0.5-beta, one id each, ordered by what it blocks — plus seven
items that are new fronts rather than carry-over and sit at the end of the table with their own
directories: C-26 and C-27 (the comptime runtimes; the `use` activation), C-28 (the builtins
surface), C-29–C-31 (decisions 102–108: the effect chain, the loops, std purity — in that order) and
C-32 (decisions 118–127: effects by return type, which re-cuts what C-29 and C-30 built).
An item's acceptance is the 1.0.5 front's, condensed; the full text is in the README beside this file
(`<front-dir>/README.md`). Where a `.tasks/*` worktree holds work, the row says which; where each
item stands is `status.md`'s.

## Items

| Id | Item | Origin | Priority | Blocks | Partial work |
|---|---|---|---|---|---|
| [C-01](#c-01--the-types-identity-in-the-value-and-one-module-per-type) | The type's identity in the value, and one BEAM module per `type` | 13 halves 2–3 (steps 8–19); decisions 21, 22, 23, 5 | **critical** | `is`, unions and `case` over named types on erlang/beam/wasm; §7 printing on three backends (02/03/05 F2–F4); C-07, C-10, C-17, C-20; today `Person(…) == Vec(…)` is `true` on erlang | halves 2 and 3 landed on `feat`; the acceptance list below is the record to tick |
| [C-02](#c-02--an-index-is-a-method-call) | An index is a method call: `Index`/`Slice`, the rewrite, and beam's silent `.length` | decision 63 (amended); 01 handover 15; 09 rows 1–4; 08's paragraph; decision 62's beam defect; 12's cell | **critical** | 1.0.9 gap "`xs[0]` silently drops the index on the BEAM backend — every server front"; `d["k"]` on every backend; `xs[0]` typing as `void` in the LSP | landed — the `libs/std` half and the checker rewrite (`xs[k]` is `xs.at(k)`, no `codegen/**` touched); residual: `xs[0]` still types `void` at a `val` binding |
| [C-03](#c-03--a-wrapper-per-host-bound-std-declare-fn) | A wrapper per host-bound std `declare fn` on erlang and beam | decision 64; 17 step 3b's acceptance; 09's `beam.bp` header | **critical** | `std@erlang:self()` is `undef`; 17's every read/write lowering; 1.0.9 gap "a std module cannot call another std module" | erlang half landed (run fixture `erlang.node()`); beam wrapper wired for a plain `module:symbol` target by 17 step 5 (`run/std_erlang_node` passes on beam); templates and `@External.Beam` bodies still unwrapped |
| [C-04](#c-04--trailing-defaults-are-applied) | Trailing defaults are applied at the call site | 01 step 7 (N1, N2); `trailing-defaults.md` | **high** | 1.0.9 gap "declared parameter defaults are never applied — every front"; `s.slice(1)` after C-02; jhonstart's 22 `attrs: []` paddings | none |
| [C-05](#c-05--module-level-var-and-the-beammemory-carrier) | Module-level `var`, `val` refused on assignment, `@BeamMemory` validated | 17 steps 0–3; 15's held-back grammar; decisions 28, 38, 41, 48, 49, 51 | **high** | C-10; rakun's `runtime.mjs` (96 of 231 lines, 13 of 16 `@External.Node` declarations are registry code); 1.0.9's "module-level `pub val` of a user type" row | landed (steps 0–3; a module `var` prints `2` on node and wasmtime) — steps 4–8 remain C-10 |
| [C-06](#c-06--decision-53-at-run-time) | Decision 53 at run time: `1...9` matches on erlang, beam and wasm. Decisions 52 and 55 (the exhausted loop is `null`; a value `break` ends a collection loop) are superseded by decision 105 — C-30 re-specifies their cells | 02 step 3 residual and "no step" rows; 03 step 3; 04 step 3; 05 steps 2/4 | **high** | the `run/case_range_value.bp` lines; a program that agrees on four backends and is wrong on all four | wasm's half landed (3 lines deleted, 6 RUN LOGs moved) and accepted by running |
| [C-07](#c-07--decision-8s-run-time-tails-on-erlang-and-beam) | Decision 8's run-time tails on erlang and beam: `is` by value, `unknown`, §2.3 `==`, tuple/`..`/type patterns on beam, `, ` on erlang | 02 steps 1 F1, 2; 03 step 3 D1–D4; 04 step 2 D2/D3; 05 step 2 D1–D3 | **high** | the erlang cells of every library that writes `is`; beam's `case` over a tuple | none; after C-01 for the named-type half |
| [C-08](#c-08--the-parser-gaps-that-are-inference-side) | The parser gaps that are inference-side: `if (a && b)`, `_` as binder, decision 54's `null` arm, decisions 11 and 12 | 01 step 10; decision 54; 15's handover | **high** | 1.0.9 gap "`if (a && b)` does not parse in condition position" (fronts 53, 60); the decided `?T` pattern surface | none |
| [C-09](#c-09--the-residual-checker-rows-and-their-backend-consumers) | The residual checker rows R1/R2/R4–R9, and what they unblock: JS-4, `Array.range(…).map`, the dead block-as-value lowerings | 01 step 8; 04 steps 7, 8; 02 steps 8, 9; decision 2 (R7) | **high** | `val Circle(r) = s` reds; `Array.range(0, 3).map(…)` is `undef` on erlang; three N25 diagnostics; `curried_call.bp` | none |
| [C-10](#c-10--beammemory-steps-48) | `@BeamMemory`'s three modes on erlang and beam, the registered ETS owner, docs, cells, rakun's migration | 17 steps 4–8; decisions 39, 40, 42, 43 layer 2, 50 | **medium** | rakun's registry code on the BEAM; decision 17 | steps 4–5 landed (erlang and beam, three modes, the owner, the refusals, the cells); `keyed = true` not lowered (refused on the BEAM), `docs.md` part 2 and rakun's migration open |
| [C-11](#c-11--format---check-over-the-whole-project-with-a-caller) | `format --check` over the whole project, structurally exempting `reject/**`, called by a gate — and the two parse defects in its way | decision 66; 09 step 1; 10's `format_cmd.zig`; 15's trailing lambda; 01 step 11 / 08's `await` | **medium** | 14 of 27 project directories red over 18 files and nothing says so; three `examples/jhonstart-app` files `botopink format` refuses; 1.0.9's formatter reds | none |
| [C-12](#c-12--the-formatter-measures-width) | The formatter measures width: `fits` fixed with every group pinned, then the method chain | decision 65; 16's next row; the comment column; step 6's residual rows | **medium** | every `group` renders flat; rakun `runtime.bp:13`'s comment column; 09's reformat after each construct | landed (both planned commits in one); measured: 0 hunks outside the chain rule across six trees, 29 chains opened |
| [C-13](#c-13--the-optional--and-the-braced-blocks-trailing-) | The optional `;`: parser first, printer second, 245 sites third | decisions 29, 60; 15's parked patch; 16 step 6; 12, `libs/std`, 09 migrate | **medium** | every `if`/`loop`/`case` statement in the ecosystem carries a `;` the language does not want | `15-language-surface/decision-29-parser-half.patch` (uncommittable alone) |
| [C-14](#c-14--decision-8-in-the-sources) | Decision 8 in the sources: `Self<…>`, the five `= []` bindings, `Dict implements Display`, the libraries' `case` arms and section paths | 01 step 11 rest; 09 step 3 (N28) | **medium** | `tests/language/test/case_sections.bp`; emilia's 27 section annotations | none |
| [C-15](#c-15--generics-carry-all-their-arguments) | A written generic type carries all its arguments; `Self<T>` | 01 step 6 (N18, §1.1/§1.2) | **medium** | two `reject/` cells; the `Box(value: 1).map` → `Box<string>` rule | none |
| [C-16](#c-16--the-language-suites-residual-cells) | The language suite's residual cells and its tally | 12 steps 4.2–4.4; decision 59 (b); cells for 63–66; the `modules/*` cells of 66 | **medium** | nothing compiles-side; the suite's own claims | landed (`259916e1`, `ca477dec`) and **verified by running at `f58fd392`** (2026-09-25): 4.2–4.4 exist and pass on all four targets, 553 / 42 / 0; the verification found six unlisted beam failures, now listed and handed to 03 |
| [C-17](#c-17--the-libraries-erlang-cells-after-identity) | Every library's erlang cell re-run after C-01, and `beam.bp`'s header re-spelled | 09 step 4; decision 43's correction | **medium** | the libraries' CI on the target they ship | none; after C-01 |
| [C-18](#c-18--decided-checker-rows-with-no-step) | Decided checker rows with no step: 44, 45, 47, 57, 31, 9; the document corrections of 1, 2, 10, 25, 32; 04's `tsc` gate and `42.toString()` | 01 rows; decisions named; 04 step 6 gate | **medium** | `optional<i32>` reaches the checker; `x?.f` on a `?T` has no diagnostic naming `?.`; `any` still parses | none |
| [C-19](#c-19--the-declaration-name-builders-spell-the-103-surface) | The declaration-name builders spell the 1.0.3 surface | 11 step 5 | **low** — ready to land | one LSP snapshot line; 07 step 3's last `uncertain` row | landed |
| [C-20](#c-20--the-comptime-module-reaches-the-node-as-beam-assembly) | The comptime module reaches the node as BEAM assembly | 14 step 3; decisions 24, 62 | **low** | nothing measurable (≈ 39 ms of 645); the principle | none; after C-01 |
| [C-21](#c-21--every-error-names-its-file) | Every error names its file: the `.withLoc` sweep | 01 step 9; `blast-radius.md` | **low** — land last | 113 error snapshots without a file name, 22 without a box | none |
| [C-22](#c-22--the-review-backlog) | The review backlog: waves A and B, the `uncertain` rows, two renames, the audit script | 07 steps 1–5; 06's handovers | **low** | the 1.0.1-beta reports' residual rows; `snap_audit.sh:501` | none |
| [C-23](#c-23--the-hygiene-sweeps) | The hygiene sweeps left in other fronts' files | 08 steps 2.1, 3.1, 6 | **low** | nothing; 14 stale `primitives.d.bp` comments, the `@external(<target>, …)` comments in six owners' files, four test-file sites, ten files `zig fmt --check` reds, the transport-error test — each site in [`08-hygiene`](./08-hygiene/README.md#open) | `docs.md`, the links and the libraries' `AGENTS.md` done on `front/sweep-docs` |
| [C-24](#c-24--br5-as-its-own-spec) | BR5 — the beam backend compiles `@External.Erlang` templates at build time — as its own spec | 03 step 1; decision 62 | **low** | `base64:encode` 0.113 → 5.722 µs per call through `'__bp_erl_eval'` (50.6×) | `wip/br5-beam-templates` (836-line Erlang lexer+parser, does not build) |
| [C-25](#c-25--the-unowned-residuals) | The unowned residuals: bare-name export collisions, the comptime server's purge, front 10's stash | 13 step 6; 10 step 1's housekeeping | **low** | two libraries exporting `pub fn get` collide silently | none |
| [C-26](./18-comptime-runtimes/README.md) | Comptime runtimes: `persistent_erl.zig` → `persistent_beam.zig` (a `.beam` emitted directly, no `.erl`), `persistent_wat.zig` on wasm3, one runtime selector, `snapshots/codegen/{beam,wat}/<target>` (the suite recorded twice), and compiler-core built to wasm running 100 % in the browser | the maintainer's request of 2026-09-20; absorbs C-20 (14 step 3); decisions 24, 62 | **high** | the compiler on the web; `erl` off the comptime path; every comptime snapshot's directory | `18-comptime-runtimes/` (spec); nothing in code |
| [C-27](./19-use-activation/README.md) | The `use` activation: hooks and components (`val c = use state(0)`, the static-prefix rule, the hook and component wrappers of decision 102 — one `@Component<C, T>` under decision 128), destructuring from a `use`, the boundary directives' spelling, and the lowering contract per backend — the grant itself is decision 104's and C-29's | the maintainer's request; `language-gaps.md`'s `use` rows; jhonstart fronts 26–32 · 67 · 94; decisions 87, 88, 96, 102, 104 | **high** | every jhonstart hook and component | `19-use-activation/`: documentation, the static prefix, the transparent lowering and the cells landed; step 3 (tuple destructuring) remains |
| [C-28](./20-builtins-surface/README.md) | The builtins surface: `builtins.d.bp` agreeing with itself and with `ast.zig`, decision 95's chain as `comptime/effect_chain.zig`, decision 96's one anchor per body; amended by decisions 102–104 and 108, which C-29 lands | the maintainer's review of `builtins.d.bp`; decisions 95, 96, 98 | **high** | every front that writes an effect, a hook or an indexable type reads this file | `20-builtins-surface/`: closed — every step and the gate, `builtins.d.bp` parses and formats |
| [C-29](./21-effect-chain/README.md) | The effect chain: `@Context<Base>` as the owner marker only; one grant of `use` (decisions 89 and 90 revoked); three generator wrappers over one `YieldStep` (`Iterator`, `Iterable`, `IteratorStep`, `Yield`, `C`, `R` leave); `getContext`; the jhonstart sweep (36 annotations, 24 wrappers) — landed on `feat`, its spelling re-cut by C-32 | decisions [102](../decisions-taken.md#102-contextbase-is-the-context-owner-marker-only-use-answers-usec-t-or-componentt), [103](../decisions-taken.md#103-a-generators-prefix-is-the-level-it-extends-generatort--resultgeneratort-e--futuregeneratort-e), [104](../decisions-taken.md#104-only-use-grants-use--decisions-89-and-90-revoked), [108](../decisions-taken.md#108-getcontex--getcontext); questions 91–93, 97, 99 | **critical** | every hook, component and generator; C-30 (an annotated `loop` answers its wrapper); jhonstart's 36 + 24 sites; ≈ 400 source lines, ≈ 250 snapshots | `21-effect-chain/` (spec); after C-28, one `EffectKind` value per commit |
| [C-30](./22-loops/README.md) | Loops: `loop { }` · `while (…) { }` · `for (…) { x -> }` · `for await`; the annotated `loop { … }` as a lazy generator expression (`iter loop` / `stream loop` under C-32); `yield` / `break v` only in a generator scope; no loop answers `[v]`; the rakun (231 `loop (`, 2 `break v`) and jhonstart (12) rewrite | decision [105](../decisions-taken.md#105-three-loop-keywords-and-generator-loop-is-a-generator-scope); `docs.md:1400`, `:1014`; supersedes C-06's decision-52/55 rows | **high** | every loop in every library; C-06's `run/loop_*` cells; `while` as a lexer keyword | `22-loops/` (spec); after C-29 |
| [C-31](./23-std-purity/README.md) | Std purity: a pure root · `io/` · `testing/`; `collections`, `hash`, `encoding` fused; a root module refused from importing `io/`; the embedded std following `pub mod io;`; the import tree `import {a: {b: {c}}, x.y.z, e.t.r*}` with the leaf bound and `as` honoured | decisions [106](../decisions-taken.md#106-std-in-three-categories-a-pure-root-io-and-testing), [107](../decisions-taken.md#107-import-a-dotted-path-and-a-braced-group-are-one-tree-and-only-the-leaf-enters-scope); `language-gaps.md`'s alias row; decision 71 amended in path | **high** | every `from "std"` line; the LSP's project graph; `build.zig`'s `stdPkgFilesFromRoot` | `23-std-purity/` (spec); after C-29 and after `01-std`'s fronts 01/02/03 merge |
| [C-32](./24-effects-by-return/README.md) | Effects by return type: the wrapper in the return is the annotation (the six effect annotations leave); `@Task<T>` replaces the fallible future and never fails; only `@Result` fails (`@Task<@Result<T, E>>`, `@Iterator<@Result<T, E>>`); `@Iterator<T>` / `@Stream<T>` over `YieldStep<T>`, iterator or factory; `async { }`; `iter` / `stream` before `loop` / `while` / `for`; the host rows; no compatibility mode and no codemod (decision 131); the library sweeps and the spec examples | decisions [118–127](../decisions-taken.md#118-the-return-type-is-the-annotation); supersedes parts of 95, 98, 102–105, 114, 117 | **critical** | every effectful body in the compiler, std and the libraries; the examples of 60 library fronts and `02-packaging`; ≈ 885 source, ≈ 160 std, ≈ 930 snapshot matches | `24-effects-by-return/` (spec, with `guide.md`); after C-29 merges or closes and C-30 (landed); alone among the surface fronts |
| [C-33](./25-gate-perf/README.md) | Gate performance: the same checks in less wall clock — the shell runners (`tests/language/run.sh`, `scripts/check-docs.sh`) on `botopink-lib-test`'s bounded pool, the independent stages of `scripts/gate.sh` side by side with each stage's output one block in order, then `test-libs`' CPU and `zig build test`'s cold runtime cache | `00 · gate-perf` step 1 (the lib-test pool); decision 67 (no check skipped to be fast) | high | every landing's gate; nothing in the language | `25-gate-perf/` (spec); runners and scripts only, beside every compiler front |

**What the 1.0.9 gaps map to.** `xs[0]` on the BEAM → C-02 · declared defaults never applied → C-04 ·
`if (a && b)` in condition position → C-08 · a std module cannot call another std module (a bare
import of an external symbol is `undefined` at run time) → C-03 is the erlang half; the commonJS route
is unverified and may be its own row · module-level `pub val` of a user type / module-level state →
C-05 · sidecar module atoms colliding silently with emitted basenames → C-25 (the collision check of
13 half 1 covers emitted modules; extending it to `shipErlSidecars` is the row) · the formatter's reds
→ C-11, C-12. The rest of `language-gaps.md` (bitwise operators, a byte type, decorator bodies, `@Decl`
source location, `never`, record update, the import alias, …) has **no 1.0.5 origin** and needs its own
front in this milestone; it is not carried here so that this front stays what it is — the compiler
work that was already specified, measured and half-built.

---

## C-01 — The type's identity in the value, and one module per type

**Origin:** 13-module-identity halves 2 and 3 — steps 8–13 (policy 3, spelled out in
[`13-module-identity/policy-3-module-per-type.md`](./13-module-identity/policy-3-module-per-type.md) §9)
and steps 14–19 (the atom inside the value); decisions 21 (T2, the tagged tuple), 22 (13 designs the
boxed value for every backend, wasm included), 23 (a behavior emits nothing), 5 (on JS the
prototype *is* the identity, so half 3 has nothing to do there beyond step 19's unit variant).
**Priority:** critical — every `is`, union `case` and per-type print on erlang and beam has nothing to
test until a value knows its declaration; today two records with the same fields are `==` on erlang.
02 and 03's tails (C-07), 14's step 3 (C-20), 17's modes (C-10) and 09's erlang re-run (C-17) all
stand behind it, which is why decision 62 released it before the backends closed.
**Partial work:** steps 8–19 landed (`cbd5f1ec`, `a8087490`, audited `def58473`/`e2da8408`); the
comptime atom's file half of step 5 landed with 01 (`89ac5cdf`). `.tasks/identity` (`fix/identity-halves`) holds C-03. Half 1
(`ModuleId`, `erlDeclAtom`, the collision check, the flat layout, the runner) is in `feat`; step 7 (the
`-pa` runner) was closed by it.
**Depends on:** C-03 lands first in the same file (it is one predicate; sequencing it avoids a
re-record on top of a re-record); 01's N19–N22 for steps 17–18 are landed.
**Blast radius, measured:** 188 cells for half 2 (94 erlang + 94 beam); half 3 under T2 is 66 erlang
+ 73 beam — **354 cell-writes over 210 distinct files, 144 written twice**, the milestone's largest
movement. Zero RUN LOGs should move in steps 14–16; a RUN LOG that moves is a defect found, verified by
running. 142 new atoms ecosystem-wide; +0.372 ns per `call_ext`.
**Acceptance** (from the front's README and policy 3 §9). Re-verified 2026-09-26 by `01-checker`
against `13-module-identity/README.md`, whose every box but one is ticked with its commit (halves
2–3 audited at `def58473` and `e2da8408`); the language suite at `ffe2db69` runs the identity cells
green (799 / 28 / 0, no `13 step` line left). The last piece of 13's half 1 — the comptime atom
naming its file — is 01's compiler `89ac5cdf`:
- [x] a fixture emitting two files per `.bp` on erlang; commonJS output byte-identical (step 8)
- [x] two types in one file both declaring `greet/1` compile and both run on erlang and beam;
      `recordMethodAtom`, `record_method_collisions`, `isRecordMethodCollision`, `interfaceAssocAtom`
      **deleted, not bypassed** (steps 9–10)
- [ ] a behavior consumed by three modules has exactly one emitted copy; `libs/std` green on erlang and
      beam (step 10); an imported type's method links to `<package>@<path>@@<Decl>` (decision 109) and executes (step 11);
      `beam_export_audit.sh` green at its new total (step 12) — **all but the first clause hold**
      (`13-module-identity/README.md` half 2, audited `def58473`); the one-copy clause is answered
      by decision 23 (a behavior emits nothing, so its associated fn is copied per consumer) and
      reopens only with that decision
- [x] the 188 classified: which gained a module, which local call became `call_ext`, which RUN LOG
      changed — none should (step 13)
- [x] `typeAtom`/`variantAtom` with unit tests and the `__v__` decoder clause; two declarations
      rendering the same atom is a located diagnostic (step 14)
- [x] two types with identical fields are `!=`, executed; two enums sharing a variant name both `case`,
      executed; an imported type constructed in a consumer carries the **owner's** atom; the erlang and
      beam cells re-recorded and classified one by one (steps 15–16)
- [x] `x is Point`, `x is Option.Some(v)`, `case` over `Person | Car` with no `_` — cells on erlang and
      beam, their `expected-failures.txt` lines gone (3 `13 step 15/17` lines today); erlang, beam and
      commonJS agree (step 17)
- [x] `@print(Point(x: 1, y: 2))` → `Point(x: 1, y: 2)`, `@print(Shape.Circle(radius: 4))` →
      `Shape.Circle(radius: 4)` on erlang and beam, `Display` consulted, nested too — the six
      `run/{display_print,print_formatter,type_identity_print}.bp` lines of 02/03/05 gone (step 18) —
      one wasm line stays, `wasm | run/display_print.bp`, re-attributed to `05-wasm` (the record
      prints; the nested `Display` text is wasm's own)
- [x] the invariant as a test, one cell per backend: two values carry the same identity iff they were
      built by the same declaration
- [x] `scripts/gate.sh --cold` green; `test-libs` at baseline; `AGENTS.md` of `src/codegen/` updated

## C-02 — An index is a method call

**Origin:** decision 63 as amended 2026-09-19 — `xs[k]` **is** `xs.at(k)`, `xs[a..b]` is
`xs.slice(a, b)`, `xs[1..]` is `xs.slice(1, null)`; two ambient behaviors `Index<K, V>` and `Slice<V>` in
`builtins.d.bp`; the type is whatever the method answers. Six rows: 09's four (`builtins.d.bp`,
`Array`, `string` with `charAt` → `at`, `Dict` with `lookup` → `at`), 01's rewrite in
`comptime/transform.zig`, 08's `docs.md` paragraph. Plus decision 62's third defect — **beam swallows
`.length` on an index or slice receiver, exit 0** (03) — and 12's `index_an_index_past_the_end_answers_zero`
cell rewritten to `null`.
**Priority:** critical — `language-gaps.md`'s last row: "`xs[0]` silently drops the index on the BEAM
backend — every server front" works around it with `.at(i)`; and the LSP walks `xs[0]` as `void`.
**Partial work:** `.tasks/ecosystem` (`fix/index-behaviors`), uncommitted: the two behaviors declared,
`Dict … implement Index<K, V>`, `lookup` → `at` across `dict.bp`/tests/`stdlib-tour`/the `std_import`
cell, `charAt` → `at` in `primitives.bp` and the JS prelude helper, `AGENTS.md`s. It records why `Array`
and `string` name their conformance in a comment: `parseBehaviorDecl` reads only `extends`, and the
separate `implement … for` block requires the methods in its own body. **Not** in the tree: the
`transform.zig` rewrite, so nothing in it can be verified by running until 01's half lands.
**Depends on:** nothing — "none of the six rows waits on front 13" (decision 63). Order inside: the
rewrite and the renames land together or the rename first as a pure rename (≈ 83 snapshots carry
`lookup`, classified as a rename).
**Acceptance:**
- [ ] `xs[0]` types as `?T` (what `at` answers) — the LSP hover no longer says `void`; `t[0]` on a tuple
      stays the checker's special case, constant index, one type per position
- [ ] `d["k"]` on a `Dict` reaches `Dict.at` on all four backends (decision 46 dissolves into this);
      absent is `null` (decision 47), one exit point
- [ ] a library type answering `at`/`slice` is indexable with no compiler change — a fixture with a
      user `Matrix`
- [ ] `[1, 2, 3][1..].length` prints `2` on beam, not silence with exit 0; the `beam | run/index_expression.bp`
      line gone
- [ ] the `Array`/`string` conformance is checked rather than commented once `behavior … implement`
      parses, or the limit is a named row here
- [ ] `docs.md` carries the paragraph; `libs/std/AGENTS.md` the table (already written in the worktree)

## C-03 — A wrapper per host-bound std `declare fn`

**Origin:** decision 64 (a) and (i): the erlang backend emits a wrapper function and export per `pub`
host-bound std `declare fn`, so `out/erl/std@beam.erl` and `out/erl/std@erlang.erl` stop being
attribute-only files and `std@erlang:self()` / `std@beam:pdPut/2` stop being `undef`; `std/beam` stays
its own module. Lands as a row of 02 or 13, whichever holds `erlang.zig` — 13 during halves 2–3.
Plus decision 43's correction: `libs/std/src/beam.bp`'s header carries three stale spellings
(`out/std/beam.erl`, `-module(beam).`, `beam:pdPut(Slot, Slot)`) to re-spell as `out/erl/std@beam.erl`,
`-module(std@beam).`, `std@beam:pdPut(T, T)`.
**Priority:** critical — small, and it is the route from `@BeamMemory`'s layer 2 to layer 1 (17 step 3b's
third acceptance bullet, every read/write lowering of C-10) and the erlang half of the 1.0.9 gap "a
std module cannot call another std module".
**Partial work:** `.tasks/identity` (`fix/identity-halves`), uncommitted, +34 −9: `erlang.zig`'s
`externalWrapperNeeded(f)` is now `f.isPub and f.isExternal() and f.body.len == 0` — it no longer asks
the bare-import route, which is why a *qualified* call died — two call sites updated (export list, form
emission); `beam_asm.zig` gains `hostDeclareWrapperNeeded(f)` **declared and not wired**. No fixture, no
re-record, no `AGENTS.md`.
**Depends on:** nothing.
**Acceptance:**
- [ ] `import { erlang } from "std"` then `erlang.self()` runs under `erl` on erlang and beam — a fixture
      whose RUN LOG is the value run, not the emitted text
- [x] 17 step 3b's guarded-init and owner shapes ~~byte-compared and~~ re-run under `erl` — 17's
      box: the shapes are layer 2's, run by `run/beam_memory_*` on erlang and beam
- [ ] `out/erl/std@beam.erl` exports the ten primitives; the same on beam through the wired helper
- [ ] the bare-import route (`import { self } from "std/erlang"` → `undefined` on commonJS, per
      `language-gaps.md`) measured on each backend; fixed here if it is the same predicate, otherwise
      its own row with the measurement
- [ ] `beam.bp`'s header re-spelled; `AGENTS.md` of `src/codegen/` in the same commit; gate green

## C-04 — Trailing defaults are applied

**Origin:** 01 step 7 — N1 (a call may omit a trailing parameter that declares a default; the checker
fills it in `transform.zig`, so the backends see a complete call) and N2 (a missing required argument
is still an arity error). Deep dive: [`01-checker/trailing-defaults.md`](./01-checker/trailing-defaults.md).
**Priority:** high — `language-gaps.md`: "declared parameter defaults are never applied — *every
front*; this is why every jhonstart call spells `attrs:`, and why `LayoutProps` is one record rather
than three parameters"; after C-02, `s.slice(1)` is the open-ended slice only if `end: ?i32 = null` is
applied.
**Partial work:** none. `libs/std/AGENTS.md` records the limit ("pass both bounds").
**Depends on:** nothing.
**Acceptance:**
- [ ] a free `fn`, a record constructor and an instance method accept an omitted trailing default;
      `P(y: 2)` checks and `x` is `0` at run time on all four backends
- [ ] a missing *required* argument still reds with the arity message (D3)
- [ ] `test/fn_defaults.bp` passes on commonJS and erlang — its two `01 step 7` lines gone, the header
      recounted from the file
- [ ] jhonstart's 22 `attrs: []` paddings deletable — measured, not necessarily deleted here (09's tree)

## C-05 — Module-level `var`, and the `@BeamMemory` carrier

**Origin:** 17 steps 0–3 (decision 50's scope for 1.0.5): `var` parses at module level; assigning to a
`val` is a located error naming `var` (decision 38), in a `fn` and at module level; commonJS
`buildValDecl` emits `let`, wasm `emitGlobalVal` sets `.mutable`; `#[@BeamMemory.<member>]` is
validated — three members, the `keyed` argument, `keyed` only on a `Dict` (decisions 41, 51). The
formatter's `var` arm travels in the same commit (decision 48); the two `infer.zig` diagnostics are a
carve-out of 01 granted once its step 4 committed (decision 49 — met at `d55a3b87`). 15 measured the
grammar ("trivial; the semantics are the `@BeamMemory` design") and left it to this front.
**Priority:** high — the annotation's carrier; without it C-10 cannot open, and `val hits = 0;`
reassigned passes `check` and then throws on node, does not compile on erlang, does not validate on
wasm. Decision 38's ecosystem cost is measured at 0 assignments to a `val`.
**Partial work:** `.tasks/beammem` (`fix/beam-memory`), uncommitted, +382 −12 across 11 files: the
parser arm and `parseValDecl` (`.mutable`), annotations on a `ValDecl` with **recorded argument
labels** (`Annotation.labels`, so `keyed = true` keeps its name — beyond the spec, and the formatter
uses it), a `jsonStringify` that omits the defaults so no parser snapshot moves, `refuseValAssign`,
`validateMemoryAnnotations` with decision 41's texts verbatim, `fmtValDecl`, `let` on commonJS,
`.mutable` on wasm; 3 parser + 2 format + 9 infer tests. `todo.md` has every box unticked.
**Depends on:** nothing.
**Acceptance:**
- [x] `var hits: i32 = 0;` and `#[@BeamMemory.Ets] var …` parse; `val x = 0; x = 1;` is a located error
      naming `var`, in a `fn` and at module level (`8146d2b6`); `expectError` cases (`37342d95`, which
      also moved the annotated-shorthand refusal onto the annotation); **two** parser snapshot
      re-records, not none — `external_keyword_argument_form` and
      `qualified_enum_variant_with_inline_true_flag` gained the `labels` array the parser now keeps
      (17's step 1 row)
- [x] a module `var` prints `2` on node and under wasmtime — run at `4fe1747e` (17's step 0) and pinned
      by `tests/language/run/module_var.bp`; a `val` stays `const` / an immutable global; **no**
      commonJS/wasm cell re-recorded (none writes a module `var`)
- [ ] unknown member → located error naming `ProcessDict`, `Ets`, `PersistentTerm`; unknown argument →
      names `keyed`; `keyed` on a scalar or a `List<T>` → "needs a keyed container" (`8146d2b6`); a
      `reject/` cell per diagnostic **in** the suite (`3cd77667`: five `beam_memory_*` plus the two
      `val_assign_*` of decision 38, with `run/module_var` and `test/beam_memory_noop` beside them)
- [x] the formatter round-trips `#[@BeamMemory.Ets(keyed = true)] var d: Dict<string, i32> = …` —
      `assertLossless` in `src/format/tests/declarations.zig` (`8146d2b6`, decision 48's arm)
- [x] the migration count — **not** in `8146d2b6`'s message; carried by `37342d95`'s and by 17's step 0
      row (447 bare-name assignments over 212 files, 447 to a `var`, 0 to a `val`); `AGENTS.md` of
      `src/parser/`, `src/comptime/`, `src/format/`, `src/codegen/` in `8146d2b6`; gate green at both

## C-06 — Decision 53 at run time

**Origin:** **53** — `A...B` is the inclusive range pattern, `..` the exclusive slice; the `1...9` arm
never matches on erlang (`{'', 1, 9}`, one line from fixed in 02's `patternNode`) and always on beam;
wasm's arm (`rangeBound` in `wat.zig`; a string bound has no wasm ordering yet and answers `0`) is
landed and accepted by running. Decisions **52** (a condition loop that never breaks answers `null`)
and **55** (`break <value>` in a collection loop contributes its value and ends the loop) are
**superseded by decision 105**: `while` and `for` are statements (`void`) and `break v` exists only in
a generator scope, so neither has a landing — C-30 re-specifies `run/loop_condition_no_break.bp`, the
three `run/loop_*_break_*` cells and `test/loop_collection.bp::§10`, and their `expected-failures.txt`
lines go with the re-specification.
**Priority:** high — the `run/case_range_value.bp` lines, and a pattern that answers differently on
each backend.
**Depends on:** nothing; 03's tuple/`..`/type-pattern reading (C-07) shares `beam_asm.zig`'s pattern
code — sequence them.
**Acceptance:**
- [x] `run/case_range_value.bp`'s five probes answer per decision 53 on erlang, beam and wasm; the
      three lines gone — re-verified 2026-09-26 on `front/02-03-erlang-beam`: the cell passes on
      erlang and beam (`run.sh --only`), no `case_range_value` line is left in `expected-failures.txt`
- [ ] every moved RUN LOG verified by running the program; the header recounted from the file; the
      `KNOWN` notes in `src/codegen/tests/**` that explain the decision-55 cells deleted by C-30 with
      the cells they explain

## C-07 — Decision 8's run-time tails on erlang and beam

**Origin:** what 02 and 03 (and the unverified half of 04/05) still owe decision 8 once a value knows
its type: 02 step 1 F1 (`, ` as §7's separator, nested strings quoted — its own commit, before 13's
rows) and step 2 D1–D3 (`is` by value, `unknown` stores nothing, §2.3 `==` — `2.0 == 2` is `true` with
an `unknown` operand and exact otherwise); 03 step 3 D1–D3 and the rest of D4 (a tuple pattern
prepends an empty tag, `..` is never read, a primitive type pattern binds instead of guarding —
`beam_asm.zig` and `wat.zig` read neither `PatternShape` nor `Pattern.rest`; 02's `fe87db51` is the
model fix); 04 step 2 D2/D3 and 05 step 2 D1–D3, which no commit names. F2–F4 (record, variant,
`Display` text) are C-01's step 18 and are not repeated here.
**Priority:** high — the named-type half is behind C-01; the primitive half (`is i32`, tuple patterns,
`, `) is not, and the four `test/case_*.bp` cells that pass 20 of 20 on erlang have no beam twin.
**Partial work:** none.
**Depends on:** C-01 for anything that tests a named type; C-06 shares beam's pattern code.
**Acceptance:**
- [x] `run/tuple_print.bp` passes on erlang (F1); `run/type_identity_{unknown,union}.bp` and
      `test/case_unknown.bp` pass on erlang after C-01 — re-verified 2026-09-26 (the two identity
      cells live under `test/`): 11 tests of the five cells pass on erlang, and `run/tuple_print`,
      `print_formatter`, `display_print`, `type_identity_print`, `type_identity_equality`,
      `case_values`, `case_range_value` pass on beam
- [ ] every `tests/language` cell naming §2, §4, §5, §6 runs by hand on beam and matches its `.out`,
      each with a beam fixture whose RUN LOG is the value run; the tuple/`..`/type-pattern fixtures
      02 added have beam and wasm twins
- [ ] §4.1's truth table answered by each §4.2 form on erlang and beam; §11's "erlang: nothing" pinned
- [x] 02 step 7 settled: `test/string_case_conversion.bp` run on erlang — the line deleted (compiler
      `31b5d2bf`; the host spelling resolves to the method it spells, `decisions-pending.md` 0203-a)

## C-08 — The parser gaps that are inference-side

**Origin:** 01 step 10 — the five parser gaps that live in `parser/{decls,exprs,patterns}.zig` by named
site: `if (a && b)` (only the `prec.equality` site in an `if` condition widens), `_` as an `if` binder,
`assert e is P;` (deleted with its three tests), `<Pattern> as <name>` (decision 11: delete the form and its three tests), unnamed variant payloads
(decision 12: a located diagnostic naming the field form); and decision 54's spelling — `case x { null
{ … } v { … } }` — which **does not parse** ("a parser row as well as a checker one"), with `.Some(v)` /
`.None` on a `?T` becoming a located error.
**Priority:** high — `language-gaps.md`: "`if (a && b)` does not parse in condition position — a
compound boolean must be bound first" (fronts 53, 60); and the decided `?T` pattern surface has no
parse today, so `run/optional_null_pattern.bp` stands on all four backends.
**Partial work:** none.
**Depends on:** nothing; shares `parser/exprs.zig` with 15's sites by name (see `fronts.md` note 17).
**Acceptance:**
- [ ] `if (a && b) { … }` parses; `if (x) |_| { … }` parses; `assert e is P;` deleted with its tests or
      parsing, the choice recorded in `residual-rows.md`; an unnamed payload declaration reds naming
      `Variant(field: T)`
- [ ] `case x { null { … } v { … } }` parses and types: `run/optional_null_pattern.bp` passes on all
      four, `reject/optional_variant_pattern.bp` rejected for its own reason — five lines gone
- [ ] `reject/case_arity_without_rest.bp` rejected with a caret (the `..` arity rule)
- [ ] 19 parser snapshots stay; new ones classified; no existing snapshot re-recorded

## C-09 — The residual checker rows and their backend consumers

**Origin:** 01 step 8, the rows of [`01-checker/residual-rows.md`](./01-checker/residual-rows.md) still
open — R1 (the declaration-name builders spell deleted surfaces — see C-19 for the LSP half), R2 (an
import needs the whole type closure), R4 (a behavior-typed field rejects its implementer), **R5** (a
pattern in binding position: `val Circle(r) = s;` binds `r: i32`), **R6** (a lowering for a method on an
associated-fn result: `Array.range(0, 3).map(…)` is `undef` on erlang), **R7** (decision 2 not
enforced: the block-as-value lowerings are dead — 03 measured 0 producers, 04 one, 05 zero), R8
(`type` as a value), R9 (the three N25 diagnostics: `reject/{two_effect_markers,val_assert_after_catch,wrapper_without_annotation}.bp`);
and the `01 handover 15` typing of `adder(3)(4)` (`test/curried_call.bp` ×2). What each unblocks: 04
step 7 (JS-4 — `Pattern.match`'s eight build sites go, [`04-js/pattern-binding.md`](./04-js/pattern-binding.md)),
02 step 8, 02 step 9 and 04 step 8's one dead IIFE site.
**Priority:** high — eight `expected-failures.txt` lines and four backend rows wait on it; R5 is what a
library writes the day it destructures a variant.
**Partial work:** none.
**Depends on:** nothing.
**Acceptance:**
- [ ] `val Circle(r) = s;` binds `r`, runs on all four backends; `buildPattern` unreachable from
      `buildParam`/`buildDestructPattern` on JS, `MatchPattern`/`writeMatchPattern` deleted, snapshots
      byte-identical; the failure behaviour of a bare `val <Pattern> = e` written down
- [ ] `Array.range(0, 3).map({ x -> x + 2 })` prints `[2, 3, 4]` on erlang, no `'__bp_prim_map'`
- [ ] R7: a note to the four backends naming the lowerings that became dead; the erlang tail-`case`
      lowering and the one JS IIFE site deleted, snapshots byte-identical — **checker half landed** (compiler `ddeb887f`; the note is in `01-checker/README.md` step 8); the deletions are 02's and 04's files
- [ ] the three N25 cells rejected each for its own reason, with a caret; `test/curried_call.bp`
      passes on commonJS and erlang
- [x] R1, R2, R4, R8 each reds or checks as `residual-rows.md` states, with a cell — R2 `modules/import_type_closure`, R4 and R8 checker tests (landed earlier on this front), R1 by deletion (`ddeb887f`)

## C-10 — `@BeamMemory` steps 4–8

**Origin:** 17 steps 4–8, which decision 50 made "a spec for the milestone after 13":
[`17-beam-memory/design.md`](./17-beam-memory/design.md) — the three modes on erlang (step 4:
`ProcessDict`, `Ets`, `PersistentTerm`; the **registered owner process** of decision 39, because
`-on_load` runs in a temporary process and an ETS table created there dies with it — five request
processes × three increments read `0` without the owner, `3, 6, 9, 12, 15` with it; `+=` under `Ets` is
`ets:update_counter` for `i32`/`i64` and refused otherwise, decision 40; a `-on_load` `Form` in
`erl_ast.zig`), the same in assembly (step 5), the docs text with decision 42's "no warning" for
`keyed` unwritten (step 6, to 08), one cell per mode per BEAM target plus a `reject/` per diagnostic
(step 7, to 12), and rakun's migration — 96 of `runtime.mjs`'s 231 lines, 13 of 16 `@External.Node`
declarations are registry maintenance this removes rather than ports (step 8, to 09 under decision 17).
**Priority:** medium — high value, but it cannot open before C-05 (the carrier) and C-01 (it owns
`erlang.zig`/`beam_asm.zig` wholesale until then) and C-03 (the route to layer 1).
**Partial work:** layer 1 (`libs/std/src/beam.bp`, ten primitives, no `.zig`) is in `feat`.
**Depends on:** C-01, C-03, C-05.
**Acceptance:**
- [x] per-mode fixtures compiled with `erlc`, run with `erl`, RUN LOG = the printed value; the `Ets`
      five-request fixture reads `15`
- [x] a `PersistentTerm` write after load is a located error hinting `Ets(keyed = true)` (on a `Dict`;
      `Ets` otherwise); `-on_load` carries the put (the reload re-run is design §5(a)'s measurement,
      not re-run here)
- [x] `+=` under `Ets` on a non-integer refused with the recomposition diagnostic; the initialiser rule
      is `isComptimeExpr()` plus the literal path, not purity — and no `Dict` can satisfy it yet (no
      `Dict` literal; `comptime dict.empty()` does not fold)
- [x] beam fixtures byte-compared against erlang's *behaviour*; `{attributes, [{on_load, …}]}` emitted
      and the `.S` loads
- [ ] `docs.md` one paragraph per mode; the cells; rakun's migration written as line ranges

## C-11 — `format --check` over the whole project, with a caller

**Origin:** decision 66 (a): `format --check` scans every `.bp` **and** `.d.bp` of a project, nested
projects included, gated on the parse defects; `tests/language/reject/**` is exempt *structurally* —
one arm in `format_cmd.zig` (10's file), never a skip list (decisions 34, 67); and a **caller**: today
`scripts/gate.sh` runs only `zig fmt --check`, the pre-commit hook names neither, no workflow does —
"a widened scan that nothing invokes is a wider silence". Gated on two parse defects: the trailing
lambda's one-line body (`arrow_when_empty` — 15's parser surface; why `botopink format` refuses three
committed `examples/jhonstart-app` files and why 16's rule 3 stops there) and `await` as a method name
in `libs/std/src/builtins.d.bp:116` (01 step 11 / 08).
**Priority:** medium — 14 of 27 project directories red over 18 files today and nothing says so; the
1.0.9 fronts' formatter reds are this.
**Partial work:** none.
**Depends on:** nothing.
**Acceptance:**
- [ ] `{ -> 42 }` / `calcular(fator: 2) { a, b -> a + b }` as a trailing lambda parse; the three
      `examples/jhonstart-app` files format; `arrow_when_empty` gone from `format.zig`
- [ ] `builtins.d.bp` formats (`await` resolved as a method name or renamed, the choice recorded)
- [x] `botopink format --check` in a project directory walks nested `botopink.json` trees and every
      `.d.bp`; `tests/language/reject/**` skipped by the directory's name, no configuration;
      `src/format/AGENTS.md:111` corrected
- [x] a gate stage calls it — `scripts/gate.sh`, the hook, CI — and the 27 directories are green or
      each red is a row somewhere
- [ ] the three `tests/language/modules/*` cells formatted (C-16's row)

## C-12 — The formatter measures width

**Origin:** decision 65 — `fits` stops at the first `concat` and answers "fits" for any non-negative
budget, so every `group` renders flat (rule 4 routed around it with `Doc.widthChoice`). Staging: fix
the predicate first with **every group pinned flat** — a commit that changes no file, proven by
formatting the six trees with both binaries — then enable one construct at a time, the method chain
first, its canonical form written into `src/format/AGENTS.md` and `docs.md` *before* it is turned on:
all-or-nothing per group, root on the statement's line, every call on its own line `+4` from the
statement, a hand-broken chain that fits is joined (output a pure function of content). Then the
comment column 09 handed over (rakun `runtime.bp:13` — a continuation line aligned under the first
re-emitted at column 0; the trivia fields need a recorded column), step 6's residual layout rows
(counted at four by `fronts.md`, not enumerated — re-derive against 09's 861-line reformat), and the
labelled tuple after 01 types it.
**Priority:** medium — 442 lines past 80 columns across 8 184, 263 of them fixable (44 chains); no
correctness at stake, but every reformat 09 makes after each construct is a commit across six trees.
**Partial work:** `.tasks/formatter` (`fix/fits`), uncommitted, +367 −19: the measuring `fits` with its
own stack, `groupMeasured`, the method-chain construct, 137 lines of tests, and the chain's canonical
form already in `format/AGENTS.md` — i.e. both planned commits in one tree. `todo.md` unticked.
**Depends on:** nothing; 09 reformats after each construct.
**Acceptance:**
- [x] commit 1: the six trees (nested example projects included) byte-identical before and after;
      `format --check` answers exactly what it answered; tests for the predicate on a hand-built group
- [x] commit 2: a chain that fits is one line (what follows on the line counted — 80 stays, 81
      breaks); one that does not puts every call on its own line, `+4`, never aligned under the
      receiver; a hand-broken chain that fits is joined; `assertFormat`/`assertIdempotent`/`assertLossless`
      cases; the per-tree movement measured against the 44 predicted; the other eight constructs pinned
- [x] the comment column recorded and printed; rakun `runtime.bp:13` round-trips — compiler `0f0be511`
      (`Doc.markColumn` / `alignToMark`; a top-level comment records its `loc`); rakun's `dcf1938` revision
      round-trips at lines 10-15. And the argument list is enabled with the constructs that enclose it
      (`7146d402`, 16's `decisions-pending.md` 16-a)
- [ ] gate green, reported verbatim

## C-13 — The optional `;`, and the braced block's trailing `;`

**Origin:** decision 29 (c) — no `;` after a **braced** `if`/`loop`/`case` statement — re-ordered by
decision 60 (b): the parser accepts the `;` as optional first, as its own landing (15,
`semicolonPolicy`); then the printer stops emitting it (16 step 6's row); then the 245 sites migrate
(`libs/std` 51, `tests/language` 44, erika 78, rakun 31, jhonstart 35, examples/CLI 5, onze 1). 15's
parser half is written and parked as
[`15-language-surface/decision-29-parser-half.patch`](./15-language-surface/decision-29-parser-half.patch)
(76 lines, `isBlockShapedStmt` + `blockStatementSemicolon`, against `109f6c9`) — uncommittable alone
because rejecting the `;` rejects `libs/std`'s embedded prelude and every compile fails.
**Priority:** medium — no program is wrong today; the ecosystem writes a token the language does not
want, and the formatter cannot pick a side until the parser accepts both.
**Partial work:** the patch.
**Depends on:** nothing; strictly ordered inside (parser → printer → migration).
**Acceptance:**
- [x] the parser accepts `if (…) { … }` with and without `;`, no snapshot re-recorded (strictly accepting)
      — compiler `a688bfb5`, `Parser.isBracedBlockStmt` (a loop and a `case` too; the closing brace is the test)
- [x] the formatter prints the braced form without `;`, idempotent, lossless — compiler `6c33c6f4`
- [ ] the 245 sites migrated one tree per commit (12, `libs/std`, then 09's five siblings), each tree's
      cells green before and after; `docs.md`'s row moved from "decided, not implemented" — **the
      compiler's trees done** (`7af79f44`: `libs/std`, `examples/`, the bundled libraries, `docs.md`'s
      fences, 213 lines; `docs.md`'s row now says "optional"); left: `tests/language` 275, rakun 454,
      jhonstart 40, erika 28, onze 1 — `16-formatter/c13-migrate.py`; then the parser refuses the `;`

## C-14 — Decision 8 in the sources

**Origin:** 01 step 11's remainder — 16 declarations write bare `Self` where `Self<…>` is required,
five `= []` bindings need an annotation, `Dict<K, V>` implements `Display`; and 09 step 3 — every `case`
arm in the five libraries rewritten to `Pattern { body }` (emilia 31 sites, onze 6, jhonstart 1), and
emilia's 27 section annotations become path names (`TokenText` → `Token.Text`) once 01's N28 lands
(`test/case_sections.bp`, 01 step 4 (d)).
**Priority:** medium — the libraries compile today; this is the surface the documents write, made true
in the trees that teach it.
**Partial work:** none.
**Depends on:** C-15 for `Self<…>`; 01 step 4 (d) for the section paths (part of C-08's parser work or
its own row).
**Acceptance:**
- [x] no bare `Self` in a generic declaration in `libs/std` or `examples/**`; the five bindings
      annotated; `Dict` prints through `Display`; `zig build test`, `test-libs`, `test-language` green — `01-checker` compilers `bdbbeae6`, `e7f1af11`, `a91e21f9`
- [ ] no `pattern -> value;` arm in any library `.bp`; `test/case_sections.bp` passes (its lines
      deleted by 01, not here) before emilia's rewrite starts; every library's cell and examples green
      after each rewrite

## C-15 — Generics carry all their arguments

**Origin:** 01 step 6 — N18, decision 8 §1.1 (`fn get(b: Box)` reds "needs 1 type argument"; bare
`Self` inside `type Box<T>` reds naming `Self<T>`) and §1.2's A1 rule (`Point(x: 1).map` reds,
`Box(value: 1).map` answers `Box<string>`).
**Priority:** medium — two `reject/` cells (`generic_missing_argument.bp`, `self_without_argument.bp`)
and the rule C-14's `Self<…>` sweep enforces.
**Partial work:** none.
**Depends on:** nothing.
**Acceptance:**
- [x] the two `reject/` cells rejected for their own reason; the A1 rule pinned by a `test/` cell — compiler `e7f1af11`; the A1 rule is pinned by a checker test (`infer_errors.zig` `generics: …`) rather than a `test/` cell, which is front 12's to add
- [x] `libs/std` and the examples compile under the rule (the sweep is C-14) — the `libs/std` half of C-14's sweep landed with it; erika's 39 sites landed in erika `fc4bf55`

## C-16 — The language suite's residual cells

**Origin:** 12 steps 4.2 (a local-dependency `modules/` cell: `pub default mod`/`fn`, a `.d.bp` via
`files`, `@ExprCustom`), 4.3 (`@panic`/`@todo`: stdout plus a non-zero exit), 4.4 ("no external target
for the active backend") — none evidenced by a commit; decision 59 (b)'s tally emitted by `run.sh`
rather than kept by hand in the header; cells for decisions 63–66; `index_an_index_past_the_end_answers_zero`
rewritten a third time (to `null`, `?T`); the three `tests/language/modules/*` cells decision 66 hands
this front.
**Priority:** medium — the suite is the milestone's evidence; a claim the suite does not make is a
claim.
**Partial work:** landed at `259916e1` + `ca477dec` (`fix/language-cells`), and **verified at
`f58fd392` on 2026-09-25 by front 12** (`ls tests/language/modules/` answers `local_dependency`
among nine; `run/panic_aborts`, `run/todo_aborts` with `.exit`; `run/external_erlang_only` with two
`.<target>.expect`) — [`12-language-tests/README.md`](./12-language-tests/README.md) § Landed —
2026-09-25 has the table. The `index_an_index_past_the_end_answers_zero` named in Origin is a
`src/codegen/tests` fixture, not a cell of the suite; the suite's statement is
`run/index_past_the_end_is_null.bp`, renamed when C-02 landed.
**Depends on:** C-02 for the index cell's new answer; C-11 for the formatted cells.
**Acceptance:**
- [x] `zig build test-language` green with the new cells on every declared target; every added
      `expected-failures.txt` line names an existing row here; `AGENTS.md`'s "cannot be tested" list
      loses the covered entries — 553 / 42 / 0 at `f58fd392`; the list keeps only `@typeInfo` /
      `@makeRecord` / `partial` / `omit` / `pick`
- [x] `run.sh` prints the tally; the header stops carrying a number a human recounts
- [x] a cell per decision 63–66 — 63 `run/index_*`, 64 `run/std_erlang_node`, 66 the three
      `modules/*` cells formatted; 65 is a sentence, since the formatter writes text and the suite
      runs programs (`AGENTS.md` § Notes)

## C-17 — The libraries' erlang cells after identity

**Origin:** 09 step 4 — C-01 changes the erlang/BEAM module atom's shape again (per-type modules) and
what `run --target erlang` loads; every library's erlang cell executes that output. Plus 09 step 5's
remainder (erika, jhonstart, onze `AGENTS.md` re-derived).
**Priority:** medium — the libraries' CI runs on erlang; a red here is a red in 1.0.9's tracks.
**Partial work:** none.
**Depends on:** C-01.
**Acceptance:**
- [ ] `zig build test-libs` re-run after C-01: no cell worse than before
- [ ] each library's own gate (examples included) re-run on `--target erlang`
- [ ] any new red registered against C-01, not fixed here; sibling commits pushed and the meta
      pointers bumped in the same sweep

## C-18 — Decided checker rows with no step

**Origin:** decisions answered in 1.0.5 that name 01 and have no step: **44** (`optional<i32>` refused
with the `?T` diagnostic), **45** (a member access on a `?T` is an error naming `?.` — the owner of
`test/tuple_labels.bp::§6 T4`, which passes `check` and should not), **47** (absent has one spelling,
`null` — the `array_at` helper on every backend), **57** (a `warnings` list on the `Env`, rendered like
a `TypeError`), **31** (`any` deleted — it still parses and checks; `erlang.bp`/`beam.bp` need a host
vocabulary first), **9** (`Array.unique` rewritten in `libs/std` to avoid a method call on an optional
inside a `default fn`); the document corrections the record is silent on — **1** (`@AsyncIterator<T>`),
**2** (`?T` only), **10** (the `@code` annotation renamed), **25** (`is` does not bind), **32** (no
`Option.Some` value names); and 04's two unverified rows — the `tsc --noEmit` gate over every
non-empty `.d.ts` (no `tsc` in the checkout when 04 closed) and `42.toString()` emitting
`__bp_print(42.toString())` on node.
**Priority:** medium — each is small; together they are the difference between the record and the tree.
**Partial work:** none.
**Depends on:** nothing.
**Acceptance:**
- [x] `optional<i32>` and `x?.f` on a `?T` each a located error with the decided text; a cell each — compiler `4dd24965` (`x.f` on a `?T` is the error, `x?.f` the spelling; `Option<i32>` refused alike); `reject/member_of_optional` and `comptime/tests/infer_errors.zig` `decision 44:` (the annotation diagnostic has its unit test; a `reject/` cell for 44 is front 12's to add)
- [ ] an out-of-range read prints `null` on all four backends, one cell; `tuple_labels.bp::§6 T4` reds
      at `check`
- [x] `Env.warnings` exists and one warning renders (the always-false `is` of 01 step 3 is the first) — compiler `bdbbeae6`: `OkData.warnings`, rendered by `botopink check` under `warning:`; §1.4's `[]` birth is the second writer. `build` / `test` / the LSP do not print them yet
- [ ] `any` gone from the grammar, `erlang.bp`/`beam.bp` re-spelled, or the row re-decided with the
      measurement
- [x] `Array.unique` answers on both backends, a `libs/std` test — compiler `6cb3ef93` (decision 9 (b): the body rewritten; `test/primitives_gaps_test.bp` `array unique drops consecutive duplicates`, commonJS and erlang)
- [ ] the five documents corrected; `tsc --noEmit` green over every `.d.ts`; `42.toString()` runs on node

## C-19 — The declaration-name builders spell the 1.0.3 surface

**Origin:** 11 step 5 — `buildRecordDeclName`, `buildInterfaceDeclName`, `buildEnumDeclName` in
`comptime/infer.zig` still spell `record { … }` / `interface { … }` / `enum { … }`, which the LSP
renders inside a decorator body; one snapshot line (`completion_decorator_record.snap.md:17`) is the
whole blast radius, measured. Strikes 07 step 3's last `uncertain` row.
**Priority:** low — but **ready**: land it at the opening.
**Partial work:** `.tasks/tooling` (`fix/tooling-step5`), uncommitted, +39 −42: the three builders
share one generic-parameter renderer and print `type Name<G>(…)`, `behavior Name<G> { … }`, `type Name<G>
{ … }`; the snapshot re-recorded.
**Depends on:** nothing.
**Acceptance:**
- [x] `grep -rn 'record {' modules/language-server/snapshots/lsp/` returns nothing
- [x] hover, completion, signature help and inlay hints print the 1.0.3 surface for `type`/`behavior`
      — one LSP snapshot each, read (11's Landed — 2026-09-25); signature help over a `type`
      constructor was **null**, `engine.recordCtorSignature` answers it
- [x] gate green; `AGENTS.md` of `src/comptime/` in the same commit; 07's row struck — the builders
      landed as `f952bfc6` without their `AGENTS.md` lines; `front/11-tooling` carries them

## C-20 — The comptime module reaches the node as BEAM assembly

**Origin:** 14 step 3 — the per-declaration comptime module goes to the resident node as `.S`
(`erlc +from_asm`) instead of Erlang source, so no Erlang source is in the compile path (decision 24:
the principle governs, every step happens; decision 62: after 13). What it needs, from
[`14-comptime-on-beam`](./14-comptime-on-beam/README.md): an untyped lowering
mode in `beam_asm.zig` (`+` → `'__bp_add'`, `.length` → `'__bp_len'`, located `unsupported_method`),
the host records without declarations (`Span`, `CustomNode`, `Binding`, `Source`, `Context`, …), a
`main/1` entry, `writeModule` writing `<module>.S`, the `.erl` path kept as a per-declaration fallback
whose rate is the progress metric. Blocker, measured: `beam_asm.zig` (6 401 lines) has 0 untyped sites
and the typed backend already dies `{unresolved_method, toUpper, 1}` on `"a b".split(" ").map({ x ->
x.toUpper() })` — in a comptime body every receiver is untyped.
**Priority:** low — ≈ 39 ms of a 645 ms build; 2–4 weeks; "the only stage whose size is a guess".
**Partial work:** none.
**Depends on:** C-01 (owns `beam_asm.zig` wholesale until then).
**Acceptance:**
- [ ] erika's single compile 47.3 → ≤ 12 ms; every `COMPTIME REPLY` byte-identical; `COMPTIME ERLANG`
      → `COMPTIME BEAM ASSEMBLY`; `beam_export_audit.sh` green; no `.erl` written for a lowered
      declaration; the fallback count recorded (N of 39 template + 33 decorator bodies)

## C-21 — Every error names its file

**Origin:** 01 step 9 — the `.withLoc` sweep: every `TypeError` located, none unlocated from
`unify.zig`, `effect-missing-wrapper` at the return type, the error snapshot's box names its file.
Blast radius re-measured at `d55a3b87`: 135 error snapshots, 113 needing a file name, 22 a box — half
the README's. Deep dive: [`01-checker/blast-radius.md`](./01-checker/blast-radius.md).
**Priority:** low — "land this **last**": it re-records every error snapshot and any checker row that
lands after it re-records them again.
**Partial work:** none.
**Depends on:** every other 01 row here (C-02, C-04, C-08, C-09, C-14, C-15, C-18).
**Acceptance:**
- [ ] 0 unlocated `TypeError`; every error snapshot's box names its file; the re-records read one by
      one, source-only diffs apart from output diffs

## C-22 — The review backlog

**Origin:** 07, never started — wave A: the per-backend residual rows of the 1.0.1-beta reports 3.1
(168 open), 3.2 (87), 3.4 (99), 3.5 (66) and 3.3's `:70`, each re-derived at HEAD and fixed, registered
or struck (two stale beam `null` rows named); wave B: reports 3.7–3.10 (48 + 59 + 40 + 78) after 06
step 2 — met; step 3: the last `uncertain` row (C-19 closes it); step 4: the two `externals.zig`
test renames (`:53`, `:65`, byte-identical, 0 orphans); step 5: `snap_audit.sh`'s dead per-backend arm
at `:501` (downgraded by 06: the classifier did not break). Plus 06's `infer_decls.zig:143` rename and
08 step 6's five comment sites in these files.
**Priority:** low — no program is wrong; the reports' status lines are.
**Partial work:** none. Wave A's commonJS and wasm columns are re-derivable now; erlang and beam after
C-01/C-07.
**Depends on:** C-01, C-07 for the erlang/beam columns.
**Acceptance:**
- [ ] every non-`ok` row of each report re-derived at HEAD; a status line appended per report;
      `--mode=review` re-run; the renames by `git mv`; the dead arm gone; `scripts/AGENTS.md` updated

## C-23 — The hygiene sweeps

**Origin:** 08's open items — every site, by owner, is in
[`08-hygiene` § Open](./08-hygiene/README.md#open): 14 comments naming `primitives.d.bp` (the file is
`primitives.bp`), the comments that teach `@external(<target>, …)` / `@[external(…)]` as current,
four comments in `codegen/tests/**` naming a moved owner or a changed lowering, ten `.zig` files
`zig fmt --check` reds on an untouched base, and the test that a comptime transport failure reaches
the user's diagnostic.
**Priority:** low — comments and one test. Each sweep lands after the owner of the swept file, one
commit per file.
**Partial work:** `docs.md` § *Decided, not yet implemented* re-derived and the documents' links
fixed (`front/sweep-docs`).
**Depends on:** the owner of each file (`01-checker`, `02-erlang`, `11-tooling`, C-22, C-26).
**Acceptance:**
- [ ] `08-hygiene`'s five open boxes

## C-24 — BR5 as its own spec

**Origin:** 03 step 1 — the beam backend compiles `@External.Erlang` templates at build time instead
of evaluating Erlang source through `'__bp_erl_eval'` at run time; struck from 1.0.5 by decision 62
because the block is structural: nothing in this compiler parses Erlang, and the parked attempt is an
836-line Zig lexer+parser that no longer builds (`wip/br5-beam-templates`, on `440a1d3e`). Cost
re-measured: `base64:encode` 0.113 → 5.722 µs per call, 50.6×; it moves 11 `.S` texts and no RUN LOG.
**Priority:** low — a spec, not a row: options (parse Erlang in Zig; emit a `.erl` sidecar per template
and compile it beside the `.S`; restrict templates on beam to what `std/erlang`'s BIF table names),
each costed, one recommended.
**Partial work:** the branch.
**Depends on:** C-01 (the emitter is 13's until then).
**Acceptance:**
- [x] superseded by landing it (compiler `8333aaab`, `front/02-03-erlang-beam`): the structural block
      — nothing in the compiler read Erlang — went away with front 14's `comptime/runtime/wat/erl_parse.zig`
      and `comptime/runtime/beam/lower.zig`, which BR5 reuses; no beam snapshot carries
      `'__bp_erl_eval'`, the refused-construct residue and the re-measured cost are in
      `src/codegen/beam/AGENTS.md`, the choice in `decisions-pending.md` 0203-b. The parked
      `wip/br5-beam-templates` branch (an 836-line second Erlang parser) is obsolete — the maintainer's
      to delete

## C-25 — The unowned residuals

**Origin:** 13 step 6's residuals, which `fronts.md` says live in `decisions-pending.md` and do not:
`CrossModule.exports` is keyed by bare symbol name, so two libraries exporting `pub fn get` collide
silently (and `language-gaps.md`'s toolchain row — a sidecar `.erl` whose atom matches an emitted
module is skipped by `shipErlSidecars` and the program dies `undefined function` — is the same class,
one predicate away from the collision check 13 half 1 built); the comptime server never purges a
loaded module (`persistent_erl.zig`, no `code:purge/1`) and never deletes
`.botopinkbuild/tmp/{template,decorator}/*.erl`. And 10's housekeeping: `stash@{0}` (front 20 defect A,
an obsolete subset of `feat`) is still in the main checkout's stash list.
**Priority:** low — none reproduces in the tree today; each is a silent failure waiting for the second
library that exports `get`.
**Partial work:** none.
**Depends on:** nothing.
**Acceptance:**
- [ ] two libraries exporting the same bare name in one build is a located error; a sidecar whose atom
      an emitted module already owns is a build error, not a skip
- [ ] a re-evaluated declaration is purged before reload, or the row says why not; `botopink clean`
      removes the comptime `.erl` scratch
- [ ] the stash dropped
