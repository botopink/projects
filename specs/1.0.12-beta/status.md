# Status — 1.0.12-beta

**Date:** 2026-10-11 (reorganized by repository, decision 433; the conformance order, decisions 457–480) · **Base** (each repository's `feat`): botopink-lang `11bde540` (135 s0: the snap library — 391, 402, 407) · rakun `d609f8c` · jhonstart `50514f1` · emilia `9c3e24a`
· onze `783af40` · erika `8f88482` · vscode-extension `f041865`

**Fronts with open work:** 25, in three tiers (decision 433) — the old tracks' 72 fronts keep their numbers
and `## Done`; their open steps live in the fronts below. **144 B-00 (434) is done but for its last box, the seventh step of the
conformance order (L1, [`fronts.md`](fronts.md) § Execution order).**

| Tier | Partial | Not started | No open step left |
|---|---|---|---|
| Maximum | 144 botopink-lang (B-00 done but its last box) | — | — |
| High | 145 erika · 146 validation · 148 styled · 149 jhonstart · 150 rakun · 154 emilia · 155 http · 156 log · 158 markdown · 162 onze | 151 json · 152 yaml · 153 dbcontext · 157 routing · 161 vscode-extension | 147 css · 159 actions · 160 snap (consumer commits only) |
| Medium | 163 meta-ci · 135 snap (coordination) | 136 cardume · 105 i18n · 107 release · 98 packaging tail | — |

**Gate:** `scripts/gate.sh --cold` green on botopink-lang `576c8d17` (batch 3: every stage; test-libs
123 passed, 0 failed; language tests 2431 passed, 0 failed) — 7m54s wall against the 7m30s budget
under load 16–20, so 114 step 7 (≤ 450 s on an idle machine) stays open, measured in 163 s9. botopink-lang's
GitHub CI still owes a green run on `feat` (114 step 3).

Each line: `front/step — what is left · blocker`. Lanes: **L1** finish what is on `feat` · **L2**
the libraries' critical path · **L3** ready to open now · **L4** later, in the order of
[`fronts.md`](fronts.md) § Execution order · **L5** blocked on a decision · **Done** landed on `feat`. A lane
holds only open lines (`- [ ]`); a line that lands moves to Done in the landing commit. Inside a lane the lines are
grouped by tier and front (433); a line keeps its old id, which the front's alias table resolves.

## L1 — finish what is already on `feat`

### First — the conformance order ([`fronts.md`](fronts.md) § Execution order), and B-00's close

In order; the step gate (460, B-29 step G) and the hook's `--no-conformance` (470) have landed (Done).

- [ ] 144 B-29 step H — every box landed (the in-process boxes, `examples/` into cells and deleted, `generic-loader-binding` erika's cell, B-00k's per-target cells); left: the step's Conformance · nothing
- [ ] 163 s8 last boxes — a green `test.yml` run on `feat` for every library (dependency closure fixed; jhonstart's cells green on commonJS, erlang and beam, wasm waits on B-38); the workflow's dependency step held to one text by `gate.sh check` · nothing
- [ ] 163 s9 — the measurements, at the end: every gate and the conformance suite timed on a quiet machine (no step in between measures) · the ninth step of the conformance order, after 163 s8
- [ ] 163 s12 — `scripts/land-check.py`, the coordinator's check before a landing (484) · nothing
- [ ] 163 s6 — a language tour (`botopink/tour`) generated from `botopink-lang/conformance/`, nothing duplicated · after 144 B-29 step I

### 144 — the cache group (B-57 … B-64, decisions 508–513): worked now, beside the conformance order

- [ ] 144 B-63 — `botopink cell check --jobs <N>` landed (cells in parallel, report in the cells' order); left: a library's `scripts/gate.sh --jobs` and botopink-lang's `test-conformance` handing their share to `cell check` (469; `runner-standalone.sh`, one text in 17 libraries), emilia's `conformance/` measured with `--jobs 1` and the default, the Conformance step · nothing
- [ ] 144 B-60 — level B on disk: a dependency's analysis in `.botopinkbuild/analysis/` by closure key + the checker's sources; `test-analysis-equivalence` (cold vs from disk, byte for byte) in `test-cli`; doubt discards; one entry per dependency and target (`<package>.bpa`, std per module), no size bound; the design confirmed by the maintainer — the whole analysed output and a journal of the registries, encoded generically over the Zig types; S0–S2, S4 (code) and the review landed; `test-analysis-equivalence` over the libraries landed; 514/515 (every command keeps a dependency's `.d.bp`), `test` reading and writing CODE and the hook's hit / miss tests landed; the cold measurement and the Conformance step open (509 (1), 514, 515) · question B-60-a (a broken dependency `.d.bp` under `build`)
- [ ] 144 B-77 — `botopink cache` (clean, status): level A to `.botopinkbuild/build/`; parallelism from the machine's pool inside botopink; `--cold` and `--jobs` go; scripts keep only `--staged` / `--no-conformance`; worktree rule 4b goes (468, 469, 473, 509, 225) · after B-60
- [ ] 144 B-78 — commonJS writes an `f64` as text with its decimal part (a template hole, `.toString()`, `string + f64`) through `@print`'s helper, `float_text_everywhere` green; left: a float commonJS cannot type (an imported record's `f64` field) still loses its `.0`, the Conformance step; contradicts decision 441's last sentence · question B-78-a
- [ ] 144 B-79 — `botopink run` of a program with no `fn main` refused before running, located at the entry module, one message on every target and host (517), cell `run_without_main` green; left: the Conformance step · nothing
- [ ] 144 B-64 — a module's tests a unit of their own on every target (`__test__@…`), the production unit the same under `build`, `run`, `test`, privates through a reserved export, `botopink test` on wasm (513) landed; left: the Conformance step · nothing
- [ ] 144 cache group Conformance — emilia's, rakun's, onze's and botopink-lang's gates measured with conformance, cold and warm; every cell green on every target · after B-64
- [ ] 144 B-55 — study: whole-package analysis — designed, the cycle run on every backend, question B-55-a filed; the timings left, on a quiet machine · beside the cache group (a study; it changes nothing)
- [ ] 144 B-56 — `botopink migrate` removed: the command, `cli/migrate.zig`, its tests and docs (s23-i) — removed; left: the Conformance step · nothing

### 144 — the module-model group (B-69 … B-76, B-55-a (e)): after the cache group's Conformance step and B-55's timings

- [ ] 144 B-69 — a file is a module: `mod` / `pub mod` and the root file removed; `src/internal/` private; an import cycle refused by name until B-71 · after the cache group's Conformance step, B-55
- [ ] 144 B-70 — `src/comptime/`, the build layer: analysed first, its own imports only; decorators and templates declared there · after B-69
- [ ] 144 B-71 — blocks: modules importing each other, headers before bodies, `dependency loop` · after B-70
- [ ] 144 B-72 — per block: decorators after the bodies, meta and catalogues filled; the catalogue in any module; 419, 14s8-d and 353's second compile go · after B-71
- [ ] 144 B-73 — commonJS: a module cycle loads (hoisted exports, memoised getters) · after B-71
- [ ] 144 B-74 — the language server checks the edited module's block · after B-72
- [ ] 144 B-75 — std and every library on the module model: root file and `mod` removed, decorators and templates in `src/comptime/` · after B-70
- [ ] 144 B-76 — the group's Conformance step · after B-69 … B-75

### 144 — after the cache group's Conformance step: the steps paused on 2026-10-12

Each resumes on `feat` once the cache group has landed, one commit at a time.

- [ ] 144 B-24 Conformance — the group's last step: numbers and strings exact everywhere (319, 320, 332), its cells and `docs.md` · after the cache group's Conformance step

### 144 — after B-00: what B-00k found, and wasm memory

- [ ] 144 B-33 — `@External.Wasm`'s cells as labels (481) landed: the checker reads `fn:`, `op:`, `wasi:`, `std:`, the prefixed strings refused (four cells), std rewritten by the codemod, no prefixed cell left in a library; left: the Conformance step · nothing
- [ ] 163 s11 — a library task holds its repository alone (483), on B-37's `bpmp link` and tiers · nothing
- [ ] 154 s5 — emilia's `conformance/docs.md` against its cells: four places where the text and the code disagree · nothing
- [ ] 150 s26 — rakun's `conformance/docs.md` against its cells: ten places where the text and the code disagree, each decided · nothing
- [ ] 144 B-30 (448, 449) — measured (`codegen/wat/AGENTS.md`) and `std-wasm/src/heap.zig` landed (a heap per process, copying collection, not wired yet); left: `alloc` out of `wat_prelude` with the codegen's roots, beam-to-wasm on the process heap, the exhaustion trap, a bounded long-running cell · question B-30-a

### 144 botopink-lang

- [ ] 114 s3 — botopink-lang `test.yml` green on GitHub on `feat` · the `libs` job was red on `94a9c3ef` on Node 20 (`fs.globSync`, five `std·commonJS` `fs.glob` tests, needs Node 22) — fixed in botopink-lang `6d95d8fc` (both Node installs at 22); the box stays open until a green run is read
- [ ] 114 s7 — a cold gate recorded on the current tip, ≤ 450 s, exit-check counts re-derived · runs in 163 s9 (the measurements at the end of the conformance order, a quiet machine)
- [ ] 134 — `registerStdlib` now runs the associated-type rewrite on std modules (`comptime.zig`, landed with batch 8 for `Type.Field<T>`): owner 01-checker · none
- [ ] 140 (334) — steps 1–3 and 6's loader landed (botopink-lang `56d4bc29`); step 4 landed: `@Task` a resumable state machine over the scheduler on both hosts (392), the `wasi:delay` / `race` / `race_of` / `spawn_all` adapters checked by shape (393), one adapter list (394), `run/wasm_host_async` and three task cells green on four targets and both hosts, the cost in the README; open: `@Component` bodies (504), `fetch`'s records, the binary component encoding, std's `External.Wasm` declaration without `host` · then 97 s17 (`io/http`, `async` on wasm: `run/wasm_host_http`, `async_block_all_of`'s wasm column) · questions 502 ★, 504, 505 ★
- [ ] 05-wasm s9 · 04-js s11 (333 (B), later) — a prebuilt wasm library merged into the module; no user yet
- [ ] 139 (332) — steps 1–5 landed: the `n` literal, `primitives.bp`'s `behavior BigInt` (`of`, `parse`, `toString`, `toI64`, `toF64`), erlang/beam the VM's integer, commonJS `BigInt` (`.d.ts` `bigint`, `tsc-check.sh` green), wasm's `bigint` helper group (≈ 2.9 KB, linked only when used), `run/bigint_arithmetic` one `.out` on the four targets; 501 (a) ★ built (no `unknown`, `is` or `comptime` over a `bigint`), 139-b ★ · lands through the coordinator; then 97 s15 (`Decimal`, `Json`'s `Int` / `BigInt` / `Dec`) · 125's bind rule; open: wasm's union row
- [ ] 01-checker s18 — numeric literal suffixes (247): built on feat (`49455602`); left: the two `language-gaps.md` literal halves, a cold gate · the `l` literal rule on every target (319)
- [ ] 01-checker s24 — typed comptime decorator arguments, `@Decl<T>`, `Field<T>` (`Type.Field<T>`, 308) and `.name` (280; cases in `01-checker/examples/decorator-arguments-280.md`) · then 125 s7, the `nat-*` rewrites
- [ ] 01-checker s22 — the `.bpp` prelude scope (270) · 116 hands the prelude list
- [ ] 01-checker rows — the comptime body's file, a package's module namespace, two aliased same-named types (310), `@External.Wasm` read on every target · none
- [ ] 04-js s9 rest — `Json`'s exact `i64` (332: 139, then 97 s15) · the explicit conversions (97 s13's std surface)
- [ ] 04-js s10 row — string reads cost +24 % against the 10 % target (`js/AGENTS.md`) · none
- [ ] 05-wasm s5 — the rest of std on wasm: heap growth, `pow`, astral `contentHash`, `encoding` / `querystring` family cells, the `wat/AGENTS.md` limits row done; left: `json` on wasm and its cell · 97 s15 (336)
- [ ] 01-checker row — a `case` over `Dog | Cat` whose arms are constructor patterns (`Dog(name: n, breed: b) { … } Cat(lives: l, name: n) { … }`) is refused `` `case` on 'Dog | Cat' is not exhaustive: missing member(s) Dog, Cat ``; with a `_` arm it compiles and runs right · none
- [ ] 01-checker row — `.Filled(null) { … }` before `.Filled(item: i) { … }` is refused `unreachable case arm (Slot): variant 'Filled' is already covered`: the coverage reads `null` in a payload as a binder (the backends test it since backend-bugs-2 patch 03) · none
- [ ] 05-wasm row — `val t = Token.Color.White; @print(t)` prints an address on wasm and `Token.Color(_inner: __Token__Color.White)` on the other three (the binder over a field-read subject, a `?f64` field holding `null`, a local `?Place`, `R(q: .Here)` landed with 144 B-22) · question B-22-b
- [ ] 01-compiler row — an enum value interpolated (`"${t}"`) differs on every target: `[object Object]` on commonJS, the variant atom (`language_tests@main@@Target__v__top`) on erlang and beam, the ordinal on wasm · none
- [ ] 02-erlang · 04-js row — a leading-dot variant (written, or a field default) of an enum the consumer does not import (`Anchor(href: "/y", target: .Bottom)` with only `Anchor` imported): commonJS `ReferenceError: Target is not defined`, erlang `variable 'Target' is unbound`; beam and wasm right — the import closure · batch 17 (module identity, every backend's import closure)
- [ ] 01-compiler row — an `l`-suffixed literal inside a `case` arm keeps its suffix in the generated code: `Ok(s) -> @print(s.mtime > 1577836800000l)` is a JS `SyntaxError`, an `erlc` syntax error and `illegal integer` on beam (the same literal in a plain function is fine) · none
- [ ] 01-compiler row — `conformance/test/expr_sugar.bp` red on `feat`: erlang does not compile it, beam fails two pipe assertions (found by B-29 step H's full run) · none
- [ ] 01-checker row — importing std `failure` brings `HostErrorName`'s variant `Error` into scope as a bare name: `Error(x)` is then refused `callee-not-a-function` (found by B-05) · none
- [ ] 01-checker row — `import {failure.HostError}` alone: reading `e.name` fails `unknown type 'HostErrorName'` (a field's type not reachable without its module) (found by B-05) · none
- [ ] 144 B-28 step 2 — the `;` migration: emilia, jhonstart, onze and botopink-lang at 0 on `feat`; rakun's 4 sites after 150 s29; then step 3 (the parser refuses it) · 150 s29
- [ ] 05-wasm row — onze's blog (67 modules) does not build on wasm (found measuring B-30) · none
- [ ] 14 row — `located_errors`' "a raise … is located at the call that raised" fails when run filtered beside other wat / wasm / comptime tests, alone and in the full suite it passes (shared state between tests) · none
- [ ] 03-beam row — std's `unicode_test` does not assemble on beam: `Internal consistency check failed … {unassigned,{y,6}}` (baseline 106c84b3; std's declared targets are commonJS and erlang) · none
- [ ] 12 s1 box 2 — `--cold` with the pre-existing tool set · 114 s7
- [ ] 14 s8 rest — an `Any` call with build arguments and every build-known expression computed at build (376, 380) · 01-checker s36 (stages, not built); `comptime padAll(2)` now reaches styled's `use context` · 14s8-e
- [ ] 14 s6 342 — `@embedFile` / `@embedBytes` (144 B-12 steps 33 and 6) · question B-12-b; `Bytes` built (B-12 step 32)
- [ ] 17 s2 — the `@BeamMemory` text and the migration handed over · 07 s6 · the rakun track
- [ ] 26 s9 — a dependency's sidecars and imports answer as its own build does · none
- [ ] 130 s5 — the remaining decorator sites (38 of 119 done, plus `#[schema]`'s 5) · rakun's DI on 01 s20 · rakun sites under the 130↔128 rule (decision 339) · rakun-client's on the behavior-member gap (ctr-q closed: the table built at comptime, 281, 256)
- [ ] 130 s10 rest — `value` read at build (353); a decorator on a `val` runs and the `val` is catalogued, its build value lifted (356) · row 133 → 119 s1 box 5 · 34 s3 · 119 s4
- [ ] 130 s6 — module-level `@emit` removed · 130 s5 · `#[schema]`'s free functions → members of the type (306; `T.parse(…)`, 327)
- [ ] 134 s2 — `Decl.fields` as `Type.Field<unknown>`, `examples/types.bp` · 01-checker s28 (`Type` a namespace type, `Type.Field<T>` declared, `Type.pick` / `omit` declared with the variadic; `result` deleted and `?T` methodless — done)
- [ ] 03-beam row — `x?.m()` over an IMPORTED enum's method calls the variant's atom as a module: `doc.field("src")?.str()` on std `Json` is `undef` `'std@json@@Json__v__str':str/1` (a local enum and erlang are right; the written `?.` call's loc records no instance lowering, the payload link's does — `ast.optional_synthetic_col`) · none
- [ ] 01-checker s31 — `?T` by `??`, `?.`, `?.[]`, `?.()`, `x!` (330); the migration script before the refusals
- [ ] 134 s6 — contexts (354), rules of hooks (357): landed — `@Component<R>` / `@Renderable`, std `context`, `use` refused outside a render tree, `use-not-top-level`, the codemod and the libraries migrated; the hidden map runs on erlang, beam, commonJS, and 388's lambda over a `RenderScope` replaces it (landed, with 26 s14); `Decl.hooks` landed with `01-checker` s23 (277); left: the rest of the lowerings · 02–05, 18
- [ ] 07-residuals s8 — the lib-agnostic gate names every library: the test-file comments reworded; the other owners' comments, then the `-w` pattern · 02 and the other owners landed (s3, s5–s7, s12, s13 done)
- [ ] 07-residuals s1, s2, s4 — the codegen and comptime report waves, three renames · 02–05 landed · 01 landed
- [ ] 07-residuals s9 · s10 · s11 — `->` arms · erika's C-13 migration · the pointers' sweep (last) · C-14 · 16 s1–2 · every library merged
- [ ] 97 s2 residue — the library repositories' `Json` accessor copies (botopink-lang's `libs/` is std alone, clean): validation `derived.bp` `membersOf`, `formats.bp` `isObject` · 125 s2 residue · rakun `jwt.bp`, `autoconfig_registry.bp` · 04-rakun
- [ ] 97 s3 · s5 residue — rakun's `parseDuration`, `skewOf` and four retry loops as "consume std" rows · no 04-rakun front carries them yet
- [ ] 97 s4 residue — the full `test-libs` count against its last record (138: 125 passed) · the cold gate; the engine half is done: no `-test` member has its own, and `test-libs --lib std` plus the seven `-test` members read 12 passed, 0 failed, 1 without tests, 3 restrictions audited
- [ ] 97 s11 — std on wasm, group 3 (230) · `io/http`, `async` through 140 + s17 (334) · `testing/mocks` in module memory when tests run on wasm (335), 503
- [ ] 97 s13 rest — `io/clock`'s `formatIso8601` / `toCivil` / `offsetMinutes` past ECMAScript's time range · `497` · `Json`'s `i64` as its digits (332, s15) · `496` (`abs` of the minimum)

### 146 validation

- [ ] 146 s3 — three API halves from 144 B-10: a comptime parameter's default, an argument read as a value (125 s12, s7), `#[each(email)]` (125 s8) · nothing
- [ ] 125 s4–s12 residue — `#[tag]`'s refusal and `#[wireName]` (`Decl.variants` gap) · the type-level `#[check]` (its message and rule through 395's typed member: validation's patch held on erlang's decode case, 144 B-10 G1 — 146 s1), `#[map]` / `#[tryMap]` / `#[codec]`, signature refusals (01-checker s24) · `Type`'s derived types (01-checker s28, 134 s4) · reflection by `@typeInfo(T).fields` and 298

### 155 http

- [ ] 104 s5 — the consumer sweep · 04, 65, 79, 12, 19, 22, `08-bpp/123`, 49, 51 landed (188)

### 156 log

- [ ] 106 s2 — consumers: 17's and 26 s4's boxes; rakun-web's `problem_digest` commit · 65 landed
- [ ] 106 s3 — built on erlang, beam and commonJS (log `2c5f568`: per-name levels, consoleSink, fanOut, rotating fileSink, captureRuntimeReports); left: the wasm column — the sink slot and the file cells have no wasm binding (two `language-gaps.md` rows, 140), std's `json` / `io/clock` on wasm (97 s15), the four file cells' wasm `fn:` bindings (405: `fileSink` an `Error` on wasm)

### Across fronts — a decision's sites in several fronts

- [ ] decision 281 (references, not strings) — rakun 04 s6, 08 s4, 12 s4 · 130 s7 · 125 s11 · 120 s6 · 127 s5 · 126 s4 · 26 s9 · 53 s7 · each after 01-checker s24
- [ ] decision 282 (a role in the decorator) — 117 s6 · 53 s8 · 51 s8 · 121 s8 · after 01-checker s24
- [ ] decision 285 (the toolchain knows `bpp`, `html`, the prelude) — 116 s2 · 117 s1 · rakun 22 s7 · 26 s10
- [ ] decision 290 (no segment config; `revalidate`, `dynamicParams` in `#[page]`) — rakun 22 s8 · 26 s10 · 53 s9
- [ ] decision 291 (`use request()` / `use response()`; no `isPrerendered`) — 122 s1, s3 · 26 s8, s10 · 120 s4
- [ ] decision 292 (`#[reload]`, `#[history]`, navigation hooks, `ScriptStrategy`) — 126 s1–2 · 50 s10
- [ ] decision 293 (`use params<P>()`, `use pageData<D>()`; no page parameter) — 26 s11 · 01-checker s23 (type args) · 117 s7 · 53 s10 · 120 s7 · 121 s9 · 122 s4 · 123 s5
- [ ] decision 294 (`Cookie<T>` declared once; `use cookieValue(decl)`, `cookieSetter`) — 104 s6 · 26 s12 · 123 · 127 · 53
- [ ] decision 295 (atoms: cardume's `Atom<T>` (296), `use local` / `use atomSetter`; middleware `@Component<Response>`, the request the root context `RequestContext` (354)) — 104 s6 · 123 s7 · 127 · 26 s12 · 53
- [ ] decision 298 (typed meta keyed by type: `setMeta(v)`, `meta(T)`) — 130 s8 built (botopink-lang `856bbc69`: `setMeta(v)` / `addMeta(v)`, `meta(T)` / `metaAll(T)`, `@Expr<T>` fields; 385 — an `@Expr` field read elsewhere — and 395 — a typed member reading its type's meta — on feat, botopink-lang `9bfbed18`); left: the libraries' migration, the string form's removal · 26 s8 · rakun 08
- [ ] decision 299 (`#[config("…")]` typed records; 03r-b reversed) — rakun 04 s7 · 08 · 13 · 15 · 88
- [ ] decision 300 (typed theme entries, one `#[theme]`; the mechanism `styled`'s, the values emilia's — 338) — 119 s1 · 34 s3
- [ ] decision 301 (`#[styled(..)]`, `jhonstart-styled`'s since 338; emilia's tokens through `#[emilia(..)]` since 369) — 119 s4 · 53 s12 · after 34 s1 for the build-time sheet
- [ ] decision 338 (CSS in three layers — the repositories `css` and `styled`, emilia over `styled`; `jhonstart-styled`, `use` of a scoped style; `"bpp": {"default", "style"}`; the header with no opening `---` and one `--- style ---` section; `jhonstart-emilia` deleted) — 119 s1–5 · 116 s1, s2, s5, s6 · 34 s3, s5 · 124 (scaffold manifest)
- [ ] decision 354 (`@Component<R>`; contexts — `Context<T>`, `use provide` / `use context`, only in a render tree, checked at build through `Decl.hooks`, stage markers, the island seam, the render scope of 388; answers 134-f) — 134 s6 · 01-checker · 02–05 · 18 · codemod · 26 · rakun 128 · 119 s1 box 4 · 120 · 34 s5
- [ ] decision 357 (rules of hooks: `use` only at a `@Component` body's top level — never in `if`, a loop, a lambda, `try`, after an early return; every `use` runs on every call, its arguments always given) — 134 s6 · 01-checker · 24 (guide § use) · every library body with a `use`
- [ ] decision 359 (spread: `Pessoa(...old, nome: n)` and `<Card {...p} featured />`, the source the record's type or a 307 derived type, left to right, complete at build) — the record half landed (144 B-14: parser, formatter, checker, the four targets, five cells); left: the tag half · 118 s1; questions B-14-a, B-14-b, B-14-c (144 B-14)
- [ ] decision 360 (slots as Astro's: `<Slot />`, `<Slot name="x">fallback</Slot>`, a child `#[slot("x")]`, transfer, `use hasSlot("x")`, `Slot` / `slot` jhonstart functions with `comptime` parameters (302); never props; 193's `children` field goes) — 118 s4 · 130 s9 · 26 (`Slot`, `hasSlot`, prelude) · 01-checker · 120
- [ ] decision 361 (std's module `bpp`: `#[bpp.html]`, `#[bpp.htmlPrelude]`, `#[bpp.style]`, `#[bpp.stylePrelude]`; `jhonstart-styled` merged into the core; `"bpp": "jhonstart"`) — 116 s1 (the std module, the manifest, the roles) · 119 s2–5 (in the core) · 26 · onze · 124
- [ ] decision 362 (26 rewrites the native builders into props form in place, with the 78 hand-written callers; no second builder per tag) — 26 s13 · after 26 s0, 01-checker s28 and the props-filling lowering
- [ ] decision 363 (a browser-only cell is `#[clientOnly]`, no erlang twin; a server `Link` styled by `data-jh-pending`) — 27 s1–3 · 26 (island cells) · 120 · 126
- [ ] decision 364 (every `comptime` parameter is `comptime x: @Expr<T>` — decorators, annotations, templates, functions, builtins: passed on to outputs, `.value` read at build for data, a function or a type never run at build) — 01-checker s35 (built; 384, a library member's names resolved where written, on feat, botopink-lang `9bfbed18`) · 130 · 125 s7 · 281's ten fronts · the codemod over std, builtins, jhonstart, rakun, validation (done; cardume when it exists)
- [ ] decision 365 (a deferred `after()` failure through the core's logger is 17's step 4, not 128's) — rakun 17 s4 · after 128
- [ ] decisions 388, 389, 414 (a `@Component` at run time is a lambda over an opaque `RenderScope`, the render library runs it — replaces 354 (8), 374, 387; a component named as a value is a reached node, a value the checker cannot follow an edge with `callee: null`; boundaries and fills are nodes the renderer runs with the scope) — 134 s6 measurement and box 4b, 01-checker s23's 389 box and `05-jhonstart/26` step 14 landed as one change set (botopink-lang and jhonstart; erlang, beam, commonJS green, wasm refused at the first component — 354-wasm; jhonstart 208 / 0 on both rows); left: the other lowerings and wasm · 02–05, 18 · 119 s2–3
- [ ] decision 375 (`HookNode.async`; commonJS emits a synchronous component as a plain `function`) — 01-checker s23 and 04-js s12 (top-level functions): landed; open `s23-j`, `04s12-a`
- [ ] decision 302 (a tag's annotation = a decorator: `@Decl`, no return, meta) — 130 s9 · 118 s5 · 119 · 120 · 126
- [ ] decision 303 (an action answers `@Result<T, ActionError>`; no `ActionOutcome`) — 127 s1–s3
- [ ] decision 304 (a store answers `@Result<T, StoreError>`; no `try*` twin, no raise) — rakun 08 s6 · 09 s6 · 65 s4
- [ ] decisions 311–313 (`declare fn` in a `type` is host-only; the template annotation `#[f "…"]`; erika queries a database — `from User`, holes bound, `limit 1` against `?T`; a repository is `#[repository] behavior` with `#[erika "…"]` or `#[nativeQuery("…")]`, `#[query]` goes) — 01-checker s29: the template annotation landed ( parser, checker, holes, `decl.params`, a method's typed meta read by its owner — `s29-a`/`s29-b` ★; `run/template_annotation`, `modules/template_annotation_imported`, five `reject/` cells; 425: a template call expands in a method body, a destructuring initializer, a field or parameter default — six `run/template_in_*` cells), the template method (397, 415) open · 16 s9 (the list form waits on box 1) · 137 · rakun 08 s7 · 130 s5
- [ ] decision 308 (`Field<T>` is `Type.Field<T>` in std; `Type.keys(T)`; a field key at run time) — 01-checker s24, s28 · 134 s2
- [ ] decision 307 (a derived type is a comptime function answering a new type: `pub val RecipeTitle = Type.pick(Recipe, .title);`, `Type` in std) — 01-checker s28 · 134 s2 · 125 s5
- [ ] decision 306 (`#[schema]` becomes `#[validated]`, the type is the only public schema; `Schema<T>` private; value-only forms become field markers) — 125 s12 · 121 s10 · 117 s8 · 127 s5

## L2 — the libraries' critical path

### 144 botopink-lang

- [ ] 01-checker — decision 8 §6 T7 warns between two elements of one array literal, where no type is written: `[#("a", linkDir), #("b", formsDir)]` says "the variable `formsDir` fills the element labeled `linkDir`" (the first element's T1 labels taken as the written type; `comptime/infer.zig` `warnTupleLabelMismatch` via `unifyAt`); still hit by onze-cli `build.bp` (the static-tree list), `create.bp:187` · none

### 150 rakun

- [ ] 150 s25 — three timing tests (`rakun-data` devtools watcher, `rakun` 503 over max-connections, `rakun-messaging` dlq) red under the gate's load, green alone: a controlled clock, never a real sleep · std's test clock source if missing (a gap row)

- [ ] rakun-messaging — one erlang test failed once in the pre-commit gate under load 26 (90 passed, 1 failed; the hook log did not name it) — not reproduced: 39 runs at c0e991c, 91 passed, 0 failed each, under load 21–74 (up to four copies of the suite side by side, rakun-websocket's beside them, CPU hogs) and once pinned to a third of one core; every runtime test ends in under 0.5 s against its 2–3 s bounds even starved, so no bound is near. Candidates left: the three fixed windows followed by a positive assertion (`ack: auto settles a Done once`, `ack: batch settles …`, 200 ms; `jms: a queue send reaches one of two …`, 300 ms) and the seven `build_test.bp` cells (a compiler run each, comptime `EVAL_TIMEOUT_MS` 10 s wall clock). The hook prints only the tail of a red member's log, so the next red names nothing either · the failing test's name (a red log kept whole)
- [ ] 103 — the action secret from rakun-app's `#[config("rakun.actions")]` record, not `rkProp` · rakun 04 s7 (299; no `#[config]` record in rakun yet)
- [ ] 130 ↔ 128 — 128 does not wait on 130; no 130 rakun commit while 128 is open; after it, each is a decision-188 consumer commit · decision 339
- [ ] rakun group A (W4–W5) — 04 (s1 the tag epoch on `feat`, rakun `d609f8c`; s2 on) · 74 · 08 (s1 after 04 s4) · 15 · 79 · 81 · 93 · 73 · 19 s1 · 128 landed
- [ ] rakun group B (W5–W7) — 13 · 12 (19 s1) · 22 (04 s5) · 17 (13 s2) · 11 (22) · 65 · 09 (19 s1, 13) · 91 (15) · 92 (74, 15) · the A step each names
- [ ] rakun group C (W8) — 88 (81, 93, 92, 04 s4, 73) · 19 s2–5 (15 s1, 04 s4) · group B
- [ ] rakun-websocket — `rakun_websocket.erl`'s `handshake/10` writes 101 before `run/4` registers the session, so a caller that reads the sessions right after the handshake can find none; register first, then answer 101 (a sidecar change, not a test bound) · 128 landed

### 154 emilia

- [ ] emilia on `styled` first (decision 350) — 34 s5: the two text boxes and the class box done (367: `e_` + `contentHash` of the class's rules, fixture `e_f51c2501`, every reader re-recorded — not landed yet); boxes 1–3, 6 wait on 34-d (a family answering `StyledProperty` does not compile), box 4 on 34-e, 34-f and 119 s4, box 5 on emilia: `comptime className(…)` cannot evaluate on the comptime runtime (wasm alone since 434; `contentHash` at comptime, 01-compiler/14 s6/s8) — `className` still reaches `register`, which has no `@External.Wasm` (369's run-time API leaving) — the two toolchain rows (a nested-section enum value at comptime, emilia's dispatcher at comptime) landed in botopink-lang `856bbc69`, box 8 on box 1 — 119 s1's two open boxes (a component with no run-time hook computed at build; the theme mechanism, 300) → 34 s5 (emilia over `styled`, output byte-identical) → 34 s2 (the five families in `styled`'s literal) · through 352 / 354 (registration by `use context(StyledSheet)`, 379), 134 s6 (box 4), box 5 on `01-compiler/130` s10 (353, row 134) — measured on `d7c71405`, see L5 (`css` done, `styled` landed)

### 136 cardume (medium)

- [ ] 138 rest — the `cardume` submodule · `botopink/cardume` holds its scaffold

## L3 — ready to open now

### 144 botopink-lang

- [ ] 129 s1–4 (337) — built, patches landing with the coordinator: `mod m;` binds the namespace `m` (the walk, `private-module`, re-export by `val` and by `type` as one declaration, `redundant-module-import`); the shorthand `import {x};` refused (`shorthand-import`, fix written; `outsideShorthandReach` and the resolver's bare-name edge deleted); `docs.md` § Modules / § Imports; the language server follows the namespace; migrated: botopink-lang (the suite, six compiler-core tests), rakun 389 items in 39 files, jhonstart 9 in 4 — a consumer patch per library (188); 138 s3 already landed

### 148 styled

- [ ] 148 s3 — `Sheet.add` over what `toStyled()` answers, a component (144 B-10 G2) · nothing

### 149 jhonstart

- [ ] 27 s2 box 2 — `use linkStatus()` outside `#[client]` refused · 26 s8 (`#[clientOnly]`, `src/stage.bp`) on 01-checker s23 (`Decl.hooks`)

### 151 json · 152 yaml · 158 markdown

- [ ] 142 (396) — `json`, `yaml`, `markdown`, one repository each: s0 done (the three repositories scaffolded, submodules), s1 std's `json.bp` out with the six consumers' imports, s2 `yaml` (rakun's reader its seed; 121 s3), s3 `markdown` (reader moved, tree of its own, onze-content maps it to `Element` — patches await landing; open: the page's own component per node) · s1–2's rakun commits after 128

### 153 dbcontext

- [ ] 143 (398) — `dbcontext`, botopink's JPA over erika: s0 done (`botopink/dbcontext` scaffolded, a submodule); s1 entities and `DbContext` over a `Driver`, s2 `#[repository]` / `#[query "…"]` / `#[nativeQuery]`, s3 rakun-data over it · 137 s2 · 01-checker s29 · s3 after 128

### 150 rakun

- [ ] 150 s29 — `decl.wrapWith` in rakun (144 B-11, 316): the publish-retry example as `#[retryable(policy)]`, its marker and the gap row gone; the 318 wrappers build on it · nothing
- [ ] 150 s28 — two consumer rows from 144: `rakun_runtime.erl`'s keyed counters to `counts.bump(k, n)` (B-26, 340); `tryQuery`'s stale comment removed (B-13, 304) · nothing
- [ ] 150 s29 — two `#[query]` methods of one name in one module build: `query.bp`'s registration `val` named per method name collides on erlang (found by 144 B-81) · question B-81-a

### 163 meta-ci (medium)

- [ ] 141 (`10-specs`) — steps 0–5 done (`decisions-taken.md`'s 26 amended rows stated as in force, the central files, tracks 04, 06–09, the examples; F10 for 384, 385); left: step 6, the rule that keeps the specs from drifting · `141-a`

## L4 — later

The `(W<n>)` marks are the old waves, kept as relative order; the order in force is [`fronts.md`](fronts.md) § Execution order.

- [ ] 164 cli — a new library repository `botopink/cli` (decision 506): typed commands, style and prompts over std's new CLI primitives (144 B-27); the repository and its front open after the 144 front · after 144 B-27

### 144 botopink-lang

- [ ] 26 (W3) — the core: s0 merges `jhonstart-html`, s1–6 · 118 landed · 102 s3 `routes.bp` · s5: 29-a (reduced: `registerRouteStarters` + `globals.starters`) · s8: 01's hooks capability, ctr-l (only the record) (s7 is 135's)
- [ ] 116 (W5 at the earliest) — the `.bpp` file kind · 118 · 26 s0 · 01-compiler/26 · with 01-checker s22 · s6: 293
- [ ] 16 s2–4, s7 — the `;` migration and refusal, C-12's reformat, C-11 · s2: each library track runs the script (sites on `feat`: rakun 4, jhonstart 26, erika 0, onze 183, emilia 2) · s3 last, after every tree is migrated · s1 (the re-count), s5 (165), s6 (166/243/345, the trailing comma alone decides) and s9 (286) landed
- [ ] 18 s1, s3 — the CI matrix, the bench's close row (s2, s4, s5, s3's evaluation budget done) · s1: the maintainer's push
- [ ] 23 — the import cells and LSP snapshots, the confirmations · 23-b, std-c (23-a moot, 23-c → 317)
- [ ] 24 — the guide as one program, the confirmations, the per-item cost · 24-c, 24-g (24-a → 431, 24-b → 432) · rakun's `serverAction`

### 145 erika

- [ ] 137 (`04-rakun`) — erika's database target: holes, `QueryContext` / `QueryTable` (397), `self.db.query "…"`, the grammar, `#[erika "…"]` · s5 and s2's template method: 01-checker s29

### 149 jhonstart

- [ ] 118 (W1) — the template language, tag annotations (278), `prelude.bp`, the node type: what it builds alone is done (s0–6's parts, 351's html-side rules, 338's `<style>` refusal); left, each on another front: s1's component spread (359) — the record spread landed (144 B-14), s1 open now; s4's slots (360) and s5's 302 arm · 130 s9 (a tag's `@Decl`); s6's `-> @ExprCustom<View>` and the `@Component` alias · 01-checker; the `@ExprCustom` LSP snapshot · 01-compiler/26; native props · 26 s13 (362). 26 s0 and 119 s2 need nothing more of it; ctr-r closed: 118 goes first, org-3 holds
- [ ] 27 s1 box 2 (W7) — the route-kind flag read · 22
- [ ] 67 (W4) — the DOM-side forms boxes, the wire names handed in · 26 · 103 s2 · 67-a (only the record) (s4 needs only 103 s2)
- [ ] 119 s2–5 (W3) — `jhonstart-styled`: the style section, `use`, run-time holes, `#[styled(..)]`, the one sheet; `jhonstart-emilia` deleted (338) · s1 · s2: 118, 26 · s5: 34 s5
- [ ] 120 (W8) — hydration strategies as `#[client…]` / `#[serverDefer]` annotations (278), server islands · 118 · s1: 26 s8 (`clientOnly`) · 119 · 117 · 26 · 22 · 49 · 50
- [ ] 122 (W9) — page-side status and headers, `rewrite`, `site` · 26 · 49 · 102 · 118 · 120
- [ ] 126 (W9) — view transitions, `#[transition…]` annotations (278) · 27 · 118 · 120

### 150 rakun

- [ ] 123 (W7) — `locals`, `sequence`, `actionContext` · 04 · 65 (s1 box 3: 08-j closed → 295/296, `use local(atom)`, the store `rakun-cardume`'s)
- [ ] 127 (W10) — actions typed by a schema · 125 s6 · 103 · 22 · 67 · 49 · 117 · 120 · 126 · s4: 123

### 154 emilia

- [ ] 34 s3 — Tailwind's theme values over `styled`'s mechanism (338); the theme always declared (358) · 119 s1 · 34 s5

### 162 onze

- [ ] 162 s12 — onze-content's field marker as a type decorator over `decl.fields` (306; 144 B-10 G5) · nothing
- [ ] 49 s2–5 (W3 → W7) — query, headers, dispatcher; the digest's sink; the public root; the dynamic mark · 102 s3 · s3: 26 s4 + 17 · s4: 65 s1 · s5: 22 s4 · 49-e
- [ ] 50 s2–7, s9 (W3 → W8) — `dev`, `prerender/`, the signal, `bin/onze`, the bundler tail, the defaults table; the `@/` alias gone (218) · 102 s3 · s2: 50-b · s4, s7: 506 · s5: 71 s2 · s6: 27 s1
- [ ] 51 s2–6 (W7) — single flight and the route, the prop table, the metrics generator, the OG defaults · 22 · s4: 52-a
- [ ] 71 s1–2 (W3) · s3–4 (W7) · s5 (W10) — ERTS copy and `bin/onze`; shutdown over real cells and static export; the four gate boxes over the blog · 49 s6 · s3: 11, 04, 81 · s4: 22 · s5: 50, 53
- [ ] 53 (W8) — the blog's `alias` gone, the acceptance script's second half, the browser · 49 · 50 · 51 · 71 s1–4 · 26 · 27 · 67 · 22 · 12 · 65 · 135 s5 (the runner) · s6: 50-b
- [ ] 117 (W7) — `.bpp` / `.md` app files, `staticPaths`, `paginate`, partials · 102 · 22 · 49 · 50 · 121 s1–2 · s1: 293
- [ ] 121 s3–6 (W9) · s7 (W10) — frontmatter, collections, references and RSS, `.md` pages; the blog reads Markdown · s3: 142 s2 (396's `yaml`) · s6: 118, 117 · s7: 53
- [ ] 124 s1–4 (W10) · s5 (W11) — the commands, the config keys, the `.bpp` scaffold (08-h closed → 285, 224) · every other 08 front · s5: 116, 53
- [ ] 135 s5 (W7) — onze: the E2E runner (five harness functions), the release tree as a path table, 107's README names the two snapshots · 390, 391 (s0 first) · before 53 s2–6

### 136 cardume (medium)

- [ ] 136 (`09-cardume`) — cardume: the core, `rakun-cardume`, `jhonstart-cardume` · `botopink/cardume` to be created and pushed · 26 · 120 · 125 · atm-c · s8: atm-d

### 105 i18n (medium)

- [ ] 105 (W9) — bundled `i18n` · 104 s5 · 22 · 26 · 03r-q confirmed

### 107 release (medium)

- [ ] 107 (W9) — bundled `release` · 07-g · 71 · 81

### 98 packaging tail (medium)

- [ ] 98 (W11) — packaging checked everywhere · every library track's `-test` and README steps · s3: 507 · s4 done: `subdir` (344)

### 135 snap (medium)

- [ ] 135 s1–4 (W11, last) — std's `mocks.verify` message; rakun-test's `assertResponse`; jhonstart's `AGENTS.md` paragraph; emilia-test's `assertClassName` / `assertCss` (they replace 97 s7, 19 s6, 26 s7, 33 s1/3/4, 50 s8, 51 s7) · 390, 391 (s0 first: the `snap` library) · s4: 34 landed

### Across fronts — a decision's sites in several fronts

- [ ] decision 321 (qualified beans: `#[qualifier("label")]`, `ctx.resolveNamed(Type, "label")`, `resolveNamed(Type)` the primary, labels checked at build) — 130 s5 · rakun 04 s6
- [ ] decision 320 (string index: codepoints on every target; erlang leaves `string:length/1`; commonJS native when no surrogate pair) — 97 s14 boxes 2–3 (04-js s10, 02-erlang s15 done)
- [ ] decision 319 (`i64` is 64-bit on every target; commonJS a number below 2^53, a `BigInt` above; literal refused past the type's range everywhere; 176, 264 amended) — 04-js s9's rest · 01-checker s18 and its literal rows · 97 s13
- [ ] decision 318 (one decorator per role, rakun's names: `#[component]`, `#[repository]` on a behavior, `#[provides]`, `#[httpClient]`, `#[listen(dest)]`, `#[controller]`, wrappers; closes 130-c, erk-c) — 130 s5 · rakun 04 s8 · 08 s7 · 12 s6 · 13 s6 · 15 s8 · 19 s7 · 79 s4 · 91 s2 · 93 s4
- [ ] decisions 315, 316 (no module annotation; a decorator wraps its function, `decl.wrapWith`, typed) — 01-checker s30 · rakun 12 s5 · 15's example

## L5 — blocked on a decision

Full text in [`decisions-pending.md`](decisions-pending.md); confirmations (1.0.10 choices) in its
last section. Open: 88 questions, 6 contradictions, 100 implementation choices (the counts live at the top of
`decisions-pending.md`).

**First — what blocks now** (`decisoes-pendentes.md` Parte 1, "O que trava agora", set by the maintainer 2026-10-09), in order:
- [ ] 05w-i → 333 (A): 97 s16 · 05w-j → 336: 97 s15

**Then — the error contract and comptime on wasm** (raised 2026-10-10, 433 / 434; each step also waits on B-00):
- [ ] 434-b — the at-build render path on one wasm runtime · 144 B-17

**Then — the botopink shape** (raised 2026-10-04):
- [ ] nat-d6…d9 — case by case (283; nat-d1 → 303, nat-d2 → 304, nat-d3 and nat-d4 → 306, nat-d5 → 307): `nav:` strings (26, 53), lifecycle (rakun 04), `use use…` (53), erika's LINQ names (98)
- [ ] nat-f2…f4 — case by case (284): `onze.json` keys (124), `files`/`workspaces` (98), `ONZE_PUBLIC_` (50, 53)

Then:
- [ ] 07-g — 107 whole
- [ ] 03r-ab — 09 s5 (and the scope of s1–4) · only the record
- [ ] 03r-ae — 79 s3
- [ ] 03r-af — 73 s3
- [ ] 03r-ak — 81 s3
- [ ] 03r-al — 15 s5
- [ ] 03r-am — 19 s3–4
- [ ] 03r-an — 92 s2 (boxes 1, 3)
- [ ] 67-a — 67 s1–3 · 53's write path · only the record
- [ ] 50-b — 50 s2 · 53 s6
- [ ] erk-b — `#[documentQuery]` under 313 (09 s4) 
- [ ] lg2-b … lg2-u — none opens a front; each opens a step when answered: 01-checker (q — reduced); the rakun boxes that name them — 13 · 65 · 92 (b), 22 (q) · answered: a (346 → 01 s32), e (347), j (343), o (342), w (341) → 14 s6, v (344) → 26 s6 / 98 s4 / 73, f, i (280), k (216, 253), r (311–313), t (314), m (315), c (316); g has no subject under 281
- [ ] C-14 — 07-residuals s9 (a 1.0.10 id)
- [ ] confirmations a step waits on — 49-e (49 s2) · 52-a (51 s4) · 29-a (26 s5; reduced: `registerRouteStarters` + `globals.starters`) · 03r-q (105) · 23-b, std-c (23; 23-a moot, 23-c → 317) · 24-c, 24-g (24; 24-g also 97 s5's surface; 24-a → 431, 24-b → 432)
- [ ] ctr-l — 26 s8's refusal list (only the record) · ctr-v — 34 / 33 opening before 118 (only the record) · ctr-w — 09 s3
- [ ] ctr-o — lem-c · ctr-p — 04's readers · 104 s5
- [ ] lg2-s — module-graph reflection

Closed on 9 Oct (no longer pending): 08-h → 285, 224 · 08-j → 295 · lg2-g → 281 · ctr-q → 281, 256 · ctr-m (= lg2-s) · ctr-n · ctr-r · 111-c → 228 · 03r-b (reversed), 03r-d → 299 · 95-e · 03r-o → 290 · 05emilia-h → 206 · 68-c → 280, 281. `#[schema]`'s free functions → 306 (ctr-u); `not-found.bpp` (213 against 221) → 289. own-a blocks nothing (`fronts.md` § Ownership's provisional rule).

## Done — landed on `feat`

Each line landed; a front's README keeps only its open steps. Grouped by front, in the lanes' order.

### 144 botopink-lang

- [x] 144 B-02 (305) — annotations speak botopink: `label = value` refused naming `label:` (`annotation_label_equals`); `fn: name` resolved to a private function on every target, a misspelt one the unbound-name error (`external_fn_unbound`), renamed with it; `op:` / `wasi:` checked by one rule with `fn:`; the old prefixed strings refused naming the labelled form (`external_prefixed_fn_refused`); no prefixed string left in `libs/**` (a scan `zig build test` runs); the formatter prints `label: value`; `keyed: true` everywhere; no library used the old forms — its Conformance step open
- [x] 144 B-10 (part; 430) — two modules declaring one type name keep two types on erlang (`two_modules_one_type_name`, `two_test_modules_one_type_name`); an associated fn named without a call a function value (`associated_fn_as_value`); a method's behavior-typed parameter takes an implementer; a `Decorator` parameter takes a decorator's name; a package's module as a namespace in type and value position (`package_module_namespace`); validation's four markers and their gap rows gone — left: `Decl.variants`' payload, `Field`'s default, `formatIso8601`, a bare variant, a wrapper alias's behavior (questions B-10-a … B-10-e), the dot-shorthand enum on commonJS / erlang, G3; handed: 146 s3, 148 s3, 162 s12
- [x] 144 B-15 (302) — a tag is a `@Decl`: `DeclKind.Element` / `Component`, `decl.component`, `decl.attr(name)`; a template builds a tag's handle (`q.tagDecl`), runs its annotation (`q.annotate`) and reads `meta` / `metaAll`; `addMember` / `addType` / `@emit` on a tag refused (`tag-annotation-output`), a second `setMeta` of one type refused (`tag_decl_meta`, `tag_annotation_add_member`, `tag_annotation_meta_twice`, `type_named_like_decl_kind`); jhonstart's `html` over it, its marker and the gap row gone — left: questions B-15-a, B-15-b, B-15-c, `mapSpanToLoc`'s one-line literal, its Conformance step
- [x] 144 B-22 (part) — `String.parseInt` / `parseFloat` answer on wasm, a `@Result` holds an `f64` / `i64` whole (`string_parse_float_every_target`, `result_wide_payloads`); a catch-all binder over a record on wasm (`case_catch_all_binder_record`); a record field named `tag` prints as a field on commonJS (`record_field_named_tag`); a std module-level `var` on erlang no longer reproduces (`module_var_in_dependency`); `format-check.sh` green for std — left: `case_value_union` (its design pass), the enum section (question B-22-b), the imported enum variant on wasm, `expr_sugar`'s pipes on erlang / beam, the bare-name arm, `Float.toString`'s text
- [x] 144 B-23 (part; 247, 255, 319) — a literal past its type's range refused on every target, `wide_literal_past_js_safe_integer` the value on four; a type application through a namespace (`collections.Dict<string, i32>.empty()`, `type_application_through_namespace`, `_mismatch`); a comptime body's diagnostic names its file (`decorator_raise_names_body_file`); `@External.Wasm`'s `op:` / `wasi:` types read on every target (`external_wasm_op_type_on_every_target`, `external_wasm_adapter_signature_on_every_target`; `external_wasm_task_adapter_shape` now refused on every target); the literal halves of two `language-gaps.md` rows gone — left: 310 (a type's identity by module, question B-23-a), the cold gate in its Conformance step
- [x] 144 B-16 (part; 308, 359) — `Type.keys(T)` names `Type.Field<T>`; a field key at run time stored, passed, compared, `case` exhaustive over `T`'s fields, `.name`, `K.of(text)`, `K.all()` (`field_key_runtime`, `field_key_case_missing`, `field_key_unknown_field`, `type_keys_outside_val`); a derived type's lineage by declared name, an import alias followed (`record_spread_import_alias`, B-14's row) — left: builtins' `Field` out with validation's and rakun-data's migration (built, with `docs.md` § Builtins held to the declarations by a test the hook runs; lands once B-81 is green — rakun's hook is red on it), `examples/types.bp` (question B-14-a), `docs.md` § Builtins checked, questions B-16-a, B-16-b
- [x] 144 B-11 (316) — `decl.wrapWith({ call -> … })`: `call.args` and `call.run()`, typed against `@Decl<fn(…) -> R>` and the new `fn(..) -> R`; the function keeps its name and identity, the body behind a private `__bp_wrapped_<f>`; wrappers compose first-written outermost, on methods, across modules (`decorator_wraps_function`, `decorator_wrap_wrong_return`, `decorator_wrap_outside_function`, `decorator_any_params_outside_decl`); 280's example 5 in the `@Expr` form; rakun's half is 150 s29 — left: questions B-11-a, B-11-b, its Conformance step
- [x] 144 B-01 (part) — `effect-try-without-fallible-channel` names `try … catch` and `result: true`; the reference § Results, § Host bindings — its Conformance step open
- [x] 144 B-13 — a method declared `-> @Result` already lowered as a `@Result` on every target (`result_method_throw`, `behavior_method_result_typed`, `behavior_method_result_chained`); no code change; rakun's stale comment is 150 s28 — its Conformance step open
- [x] 144 B-26 (340) — `Dict.bump`; `counts = counts.bump(k, n)` on a keyed var as `ets:update_counter/4` on erlang and beam, `beam_memory_ets_keyed_bump`; rakun's registry is 150 s28 — its Conformance step open
- [x] 144 B-81 — rakun-data's `#[query]` red on erlang: the cause is rakun's (a registration `val` named per method name, colliding since B-39), filed as 150 s29; no compiler change
- [x] 144 B-04 (431) — std `failure`: `HostErrorName`, `HostError(message, kind, name, detail)`, `Failure` (489, 492), `std_failure_types` on four targets; `attempt` is B-07's — its Conformance step open
- [x] 144 B-03 (431) — `result: true` on every `@External` variant, labelled, any order (487); only on `@Result<…, HostError>` / `@Task` of one, std's `HostError` by identity (488); refused beside `op:` / `fn:` (491) — its Conformance step open
- [x] 144 B-12 step 32 (346) — the `Bytes` primitive on the four targets: `fromUtf8` / `toUtf8`, length, slice, concatenation, `encoding`'s bridges, a host cell taking and answering `Bytes`, eleven `bytes_*` cells; steps 33 and 6 (`@embedFile` / `@embedBytes`) wait on question B-12-b · questions B-12-a, B-12-b
- [x] 144 B-05 (431, 489, 490) — a `result: true` binding answers `Error(HostError(…))` for every way its host fails on commonJS, erlang and beam; wasm has nothing to wrap; `external_result_host_error` on four targets; std `fetch` over a private `result: true` binding; 126's flagless conversion kept until B-07 (jhonstart's `__jhTryTask`) — its Conformance step open
- [x] 14 row — an unseeded draw at build is refused as 456's plain text at the raising call, no Erlang term, the comptime and decorator forms alike (`comptime_random_unseeded`, `comptime_random_float_unseeded`, `decorator_random_float_unseeded`)
- [x] 05-wasm row — a generic method's return bound at the call on wasm: `.join` over a library's `toArray()` resolves and prints text (`generic_method_array_join`); `generic-loader-binding` builds and its tests pass on wasm
- [x] 144 B-29 step J — botopink-lang's `scripts/gate.sh` takes one total of jobs (`--jobs <N>`, default the machine's) split among its stages, no gate lock (`scripts/AGENTS.md`); `--no-conformance` stays the hook's gate; a library's `test-out` is already a per-run directory, removed after (468, 469, 508) — its Conformance step open
- [x] 144 B-80 — onze-cli's CSS accessors test: the cause is the library's — its app is created as `styled`, a package of jhonstart's closure, and the build refuses two packages of one name; handed to 162 s11, the compiler unchanged
- [x] 144 B-39, B-41, B-43, B-51, B-52 — a module-level `val` read by the next one bound on erlang; a library's abort worded alike on every target; a `Set` of structurally equal records keeping one on commonJS and wasm; commonJS printing an `f64` with its `.0`; wasm printing a string field or an awaited string as text — each step's Conformance step open
- [x] 144 B-31, B-44, B-53, B-54 — a float-hole template a `string` on wasm; a lifted `bool` printed `true` / `false` on wasm; `@print` of a `@Result` as `Ok(…)` / `Error(…)`; the formatter keeping an annotation's `label: value` — each step's Conformance step open
- [x] 144 B-62, B-67, B-68 — the nine cells red on `feat` green; erlang building a library's record beside a std record of the same name; wasm resolving a method call on a template's answer — each step's Conformance step open
- [x] 144 B-32 — structural equality at build iterative (`comptime same(2000000)` answers `true`), a `badarith` at build located in Erlang's words (471, 472) — its Conformance step open
- [x] 144 B-38 — a worker that leaves no verdict is a FAIL; the dropped cell did not reproduce — its Conformance step open
- [x] 144 B-48 — a raise inside a decorator or comptime body travels with its location: only this module's calls are located (an imported helper's raise lands on the local call, an imported decorator's raise at the annotation, a template expansion's calls not located) — its Conformance step open
- [x] 144 B-22 (part) — `throw` in a `case` arm of a `@Result` fn on every target (`throw_in_case_arm_result`), a `val` binding a nested constructor and a spread-only list on every target (`val_nested_ctor_pattern`, `val_spread_only_list_pattern`; wasm and beam included), the four rows once filed under `04-js` fixed (`module_val_call_init`, `point_ctor_rest_in_case`, `block_partial_return`, `block_return_is_block_value`) — its Conformance step open
- [x] 144 B-28 (part) — the one-line trailing lambda (165) and annotations printed as written (286) — its Conformance step open
- [x] 114 — `codegen/runtime.zig`'s own `test` blocks run: the file and ten more are reached by the test barrels
- [x] 144 B-58 — the code cache, level A: a dependency's `.erl` → `.beam` / `.S` → `.beam` by content (`cache/erlcheck`, `cache/beam` removed), the closure key, a workspace's dependencies inherited (512), every `conformance/modules/` a workspace (botopink-lang, emilia, erika, jhonstart, rakun); the three manifest-refusal cells removed (a manifest's refusals are `modules/manifest`'s unit tests); emilia's `conformance/` 189 s cold, 164 s warm (from ~48 min before the group) — its Conformance step the group's
- [x] 144 B-59 — the result store removed (510); the backend-partition audit its own gate stage — its Conformance step the group's
- [x] 144 B-65 — every emitter reads its package closure's index (`crossModule.Scopes.forModule`); `test-closure-invariant` green on erlang, beam and wasm; rakun's six rakun-web cells run on beam too — its Conformance step the group's
- [x] 144 B-66 — commonJS reads the same closure scope; `test-closure-invariant` green on every target — its Conformance step the group's
- [x] 144 B-57 — erlang and beam: an imported section enum's inner enums emitted once, by the declaring module; emilia's `alpha` cell 4106 → 706 modules on both targets, `run` 23.9 s → 13.8 s (erlang), 7.2 s → 4.0 s (beam); a codegen test per backend — its Conformance step the group's
- [x] 144 B-61 — a cell's package name is its directory's name (511): a one-off script filled the 148 of botopink-lang's cells that differed (146 were `language_tests`); `package_named_std` is the cell `std`; the name check is the manifest's (512 (1), B-58)
- [x] 144 B-50 — beam: a member call through a library's default handle lowers to a call into the library; `default_handle_member` green on beam, a beam codegen test — its Conformance step open
- [x] 144 B-49 — std's commonJS sidecars ship from the compiler's embedded copy — its Conformance step open
- [x] **144 B-00a → B-00k (434, 437, 442, 446, 450, 452, 459)** — comptime on wasm only, the first thing the milestone did: `modules/std-wasm` (std's host functions in Zig), `modules/beam-to-wasm` (`.beam` to wasm), the comptime driver on wasm for every target, the BEAM comptime runtime deleted and `snapshots/codegen/<target>/` one tree, std-wasm in the `--target wasm` output, `@External.Beam` deleted (437), `wat_prelude` keeping only representation, operators, output and runtime (442); B-00b a standalone `.beam` → wasm utility on std-wasm (435, 438) · landed: B-00a, B-00d, B-00f (437), B-00h (446); B-00b for 435's subset, a foreign `.beam` and standalone (438), the utility whole (the comptime does not call it, 452); B-00c (452: a host function at build answers by `std:` or `fn:`), its last box open — the line below; B-00e (440, 441: std-wasm transpiled into the wasm program, the `std:` binding, std-wasm's text, sizes in `wat/AGENTS.md`); B-00g (442, 443, 445, 447, 451: std's helpers and `bigint` in std-wasm, Unicode case mapping, `std:` std's alone, a frame past the stack's floor traps, the seeded random std-wasm's and refused unseeded at comptime); B-00j (452, 453, 455, 456: the comptime answers by `std:` or `fn:`, never an Erlang cell; the name `std` reserved; `random.float` std-wasm's); B-00i (450: the Erlang terms and OTP functions are std-wasm's, `bp_wat_rt.wasm` gone); B-00k (459: the group's Conformance step — four cells, the table in the README) — **the B-00 group is done**: B-00c's last box closed by the seventh step of the conformance order, every library's own gate green with conformance on this compiler (`scripts/gate.sh libs`, 17 of 17)
- [x] 144 B-29 step I — the language reference is `conformance/docs.md`, every example a cell (90 new) or `text`; `docs.md`, `docs/` and README's example removed; `test.yml` runs `scripts/gate.sh --cold` with conformance — its Conformance step open; five new cells red until B-51 and B-52
- [x] 144 B-42 — wasm: a fold lambda's string accumulator resolves its methods (`join/1`); emilia's 79 cells green on their declared targets, wasm refusing each on a host binding (`raisedBy`) — its Conformance step open; the sixth step of the conformance order done
- [x] 144 B-38 — a cell's `path` dependency and dependency tiers resolve from the cell's own directory, from any working directory — its Conformance step open
- [x] 144 B-45 — erlang: a member call through a library's default handle reaches the library — its Conformance step open; the example's move into erika after the 144 front
- [x] 144 B-34 — beam: a closure's free-name walk binds an `if` binding in its then-branch only (styled's `spliced`); jhonstart's 18 cells green on commonJS, erlang and beam — its Conformance step open
- [x] 144 B-35 — wasm lowers `@println` as `@print` with its newline; erika's two cells green on every target — its Conformance step open
- [x] 144 B-47 — a refusal `.snap` claims the label under the caret (`label <text>`, 485): 82 refusal cells carry one, the four caret-label cells green — its Conformance step open
- [x] 144 B-46 — a failed decorator run checks its body with the module's std imports bound; the decorator `random.float()` cell refused unseeded (451, 456) — its Conformance step open
- [x] 144 B-40 — a cell's targets in its `botopink.json` (`"targets"`), a `targets` file refused (475 (1)); jhonstart's, rakun's and emilia's cells on it — its Conformance step open
- [x] 144 B-29 step H2 — `tests/language` is `conformance/`: 943 cells, each with its manifest (narrowing in `"targets"`, a `targets` file refused), the suites in `conformance/test/`, test-cli's language half and the examples as cells; the gate's conformance stage is `zig build test-conformance`
- [x] 163 s10 — each repository's `decisions-taken.md` generated from the meta one by Binds (`scripts/decisions-split.py`, `gate.sh check` 6); a row binding no mappable repository stays in the meta one
- [x] 163 s7 + s8 — `scripts/gate.sh` in every repository (byte-identical across the libraries, CI check 4), the hook `--no-conformance`, the conformance stage only where a cell exists; the meta `scripts/gate.sh` runs the five checks (the workflow calls it) and orchestrates (`run`, `tasks`, `libs`, `status`, a job pool); each library's `test.yml` runs `bpmp install` then `scripts/gate.sh`
- [x] 144 B-37 — a `git` dependency resolves from `BOTOPINK_LIB_ROOTS`, then `<project>/.botopinkbuild/deps/` (and a workspace root's), then the walk-up; `bpmp link` links a checkout's repositories, nothing cloned (483) — its Conformance step open
- [x] 144 B-36 — styled's hook red on `feat`: its stage read 354 (8)'s hidden context argument, which decision 388 dropped; fixed in styled
- [x] 144 B-29 step G — one job budget (cold gate alone 12m27 → ~10m30, warm 1m35) and the step gate of decision 460 (a `front/*` branch runs the cells its change reaches: a one-backend step 4m32 against the full gate's 10m20)
- [x] 114 s6 box 1 — vscode-extension workflow installs the compiler's OTP 28 (vscode-extension `f041865`)
- [x] 114 s6 box 2 — vscode-extension's workflow green on `feat` (`f041865`)
- [x] 114 — the runtime cache never stores a run not ended by its own exit: `RunStatus.interrupted` (a signal, a stop, an `erl` that printed its break handler's banner and halted 0) is never recorded nor cached, wasm included; `HARNESS_VERSION` `6-own-exit` drops older entries (`tests/runtime_scratch.zig` "never cached"; bugs-sweep patch 01, bs-c)
- [x] 114 — `result_store.sh` no longer reads a sibling checkout: `check-docs.sh`'s default library roots are this checkout's `libs/` and every sibling under `repository/` holding a `botopink.json` (vscode-extension's included), each hashed whole into every key; `--lib-root` replaces them and the test names its own (bugs-sweep patch 02; the gate's cost of it: bs-d)
- [x] 114 s8 boxes 1–2 — 133's emitted modules byte-identical, measured; rakun's `test.yml` glibc comment says 2.35
- [x] 114 s8 box 3 — emilia `test.yml`'s jhonstart checkout removed (its own emilia patch, after 06-emilia/33 s2)
- [x] 114 — the four other libraries' `test.yml` stale glibc 2.38 comment says 2.35 (emilia `b3d877e`, erika `44aef93`, jhonstart `0ba3c55`, onze `d6664c8`)
- [x] 01-compiler — the node floor is 22 (std's `fs.glob` calls `fs.globSync`): `codegen/AGENTS.md`'s `toReversed` note, and the `node ≥` rows of `AGENTS.md`, `README.md` and `docs.md` (bugs-sweep patch 09)
- [x] **01-checker s21 (priority, 331)** — every `comptime` runs on the comptime runtime (the wasm runtime alone since 434), never on the target; the same value on the four targets; a declared function's reference lifted; rakun `beans()` green unchanged; a decorator body's helper building another module's record (`block_eval.typesReached`)
- [x] 134 s4 (267) — the variadic parameter `..name: T[]` and the print builtins declared with it; 134 s6 (269) — `@getContext(T)` answers `Component<T, T>`, refused outside `use`; 134 s2 — `Type.pick` / `Type.omit` declared (no cell calls them yet: 01-checker s28) · botopink-lang `56d4bc29`
- [x] 01-compiler — a string template in a method body (a type's, an enum's, a behavior's `default fn`) reached every backend's `stringTemplate => unreachable`: the method-body walk desugars it, and runs whatever the maps hold (`run/template_in_type_method`, four targets; bugs-sweep patch 04)
- [x] 01-compiler — a type's associated fn is arity-checked: a short call filled from the declared defaults, a labelled one reordered, any other count refused at the call (`reject/associated_fn_too_many_arguments`, `reject/associated_fn_missing_argument`, `run/associated_fn_of_type_default`; bugs-sweep patch 05, bs-a)
- [x] 97 s16 (333 (A), first) — `unicode.normalize` in botopink on the four targets over `unicode_tables.bp`, generated by `zig build gen-unicode` from Unicode 17.0.0; every line of `NormalizationTest.txt` green on commonJS, erlang and beam; `run/std_unicode_on_every_target` one `.out` (its `.wasm.expect` gone) · `97-s16-a` (where the tables live)
- [x] 01-checker s21 part — every body `comptime` `eval.zig` folds is folded by the checker (`foldBodyComptime`), so no backend meets it (`run/comptime_block_in_body`, four targets); the runtime box is the priority row above (331)
- [x] 01-checker s23 — `Decl.hooks`: every reachable node, annotations with their `Decorator` (277), each `provide` / `context` with its context (134 s6 box 3, 354 (4)) — landed, eight cells; `Decorator.same` (371) and the `.hooks` readers' phase (372) landed (five cells; s23-g – s23-i) · then 26 s8, 49 s5, 22 s4
- [x] 01-checker s25 — the anonymous default `pub default fn (…)` and `pub default Name;` (289); the formatter arm handed to 16
- [x] 01-checker s26 — a `comptime` parameter taking a value or a type (`Atom<T> | type T`, 297); 280 (0)'s `comptime-arg-not-known`
- [x] 01-checker s19–s20 — type application and `comptime <expr>` (255): on feat (`49455602`)
- [x] 01-checker rows — the `@block` tail refusal, the `$stringify` parser refusal (239), `primitive-type-name-taken`, T17, row 33 re-measured (refused at the alias); a type reached twice through `@TypeInfo.all` and an import accepted
- [x] 01-checker row — the template memo key is O(text) (`template_eval.memoKey`, 237)
- [x] 01-checker rows — a partially returning `@block` is `block-tail-value` (`reject/block_partial_return`); a decorator body's `decl.nope` is the checker's unknown field, located in the body (`reject/decorator_{body,helper}_unknown_field`); the two diagnostics teaching retired spellings corrected
- [x] 01-checker rows (319) — an unsuffixed literal is range-checked in the type its position asks for (`i32` with nothing asking, 247); the operand of a unary `-` is read as the negative value, so each signed minimum is written as itself (wasm emits it as the constant, `negatedMinimum`) and a negated literal takes its width from the other operand; the refusal cites 319 (`reject/integer_literal_*`, `run/integer_literal_type_minimum`, `infer_errors` "cites decision 319"; `run/i64_full_width`'s `@print(4294967296)` written `4294967296l`; bugs-sweep patch 07, bs-b)
- [x] 04-js s1 — the `@block` tail form refused before commonJS (01's `block-tail-value`); the IIFE serves the two shapes left
- [x] 04-js s2 — `$stringify` in a template (164, 239); `render`'s arm and `emitStringify*` deleted
- [x] 04-js s8 — an integer that leaves its type aborts (264): on feat (`48a096ea`)
- [x] 04-js s9 (319) — `i64` / `u64` / `isize` / `usize` a number below 2^53 and a `BigInt` past it: every operation through the prelude helpers, literals, host templates and `.d.ts` as `number | bigint`, the cost within 10 %, `run/i64_full_range` on the four targets
- [x] 04-js s10 (320) — a string index counts codepoints on commonJS: the five reads through prelude helpers, host templates in codepoints, `run/string_index_of_codepoints` one `.out` for the four targets
- [x] 04-js row — an immediately invoked plain arrow or `function` is not a closure for the self-tail-call scan (`NameScan.immediateBody`): the `??` IIFE keeps the loop, std `path.resolveAll` / `applyPieces` loop again (two `std_package` snapshots re-recorded; bugs-sweep patch 03)
- [x] 05-wasm s1 box 1 · s3 box 2 — `Array.unique` keeps the first occurrence (`run/array_unique`); C-07's cells on wasm as `run/is_truth_table` (`run/unknown_stores_nothing` struck — §11 is a cost, no program prints a difference)
- [x] 05-wasm s8 — overflow for `u32`/`u64` and the narrow integer types on wasm (264)
- [x] 05-wasm — an `@block`'s `return` is the block's value (decision 2), `run/block_return_is_block_value`
- [x] 05-wasm rows — `_` in a variant payload, a nested variant pattern (`run/variant_payload_wildcard_and_nested`); unsigned compare and divide (`run/unsigned_compare_and_divide`); `u64`'s unsigned overflow checks and printing, an unannotated `u64` literal or sum keeps its type, radix literals to `u64`'s top
- [x] 05-wasm row — a nested record field read through a generic record and concatenated is the field's text: `recordTypeOfExpr` reads a field declared as a type parameter (`data: D` of `Route<P, D>`) as the record the receiver's type argument names (`recvTypeArg`); `route.data.title` printed `<h1>332</h1>` on wasm (`run/generic_record_nested_field_concat`; backend-bugs patch 01)
- [x] 04-js row — a record field named by a JS reserved word (`type Tag(class: string)`): a record's and a payload variant's constructor parameters and a variant factory's arguments are bindings (`class_`), the property keeps the name, so construction, a read, a destructuring, a pattern, an update and the `.d.ts` agree; wasm types a destructured record binder by its field (`class + "#"` printed an address) — `run/record_field_reserved_word` (backend-bugs-2 patch 01)
- [x] 04-js · 05-wasm row — a labelled record pattern (`Dog(name: n, breed: b)`, swapped, `..`, positional, nested, a literal field, a guard): commonJS tests the record's class (`variantTest`; it tested `tag` and the `case` printed `null`); on wasm a binder read off a record pattern carries the field's declared type, so `"${a ?? 0}"` over `?i32` unboxes (it printed the box's address) — `run/case_record_labelled_fields` (backend-bugs-2 patch 02). erlang and beam were right on every shape tried, a record imported from a sibling module included
- [x] 02-erlang · 03-beam · 04-js · 05-wasm row — `null` (and `true` / `false`) written as a record field's pattern is a literal: the parser keeps it out of the `fields` shape (`isPlainBinder`), and erlang tests `undefined`, beam `is_eq_exact` on it, commonJS `== null`, wasm `eqz` (bound as a name `null` it matched anything; commonJS was a `SyntaxError`) — `run/case_record_field_null` (backend-bugs-2 patch 03)
- [x] 05-wasm row — a `case` over a union of records whose arm binds the record it names (`DogB { d -> … }`): the binder is that record (`arm_record`), not the union subject's type (`d.name` printed an address) — `run/case_record_union_binder` (backend-bugs-2 patch 04)
- [x] 03-beam · 04-js · 05-wasm row — an enum field prints `Target.Top`, as erlang did: a leading-dot field default (`target: Target = .Top`) is injected qualified by the field's enum (`transform.injectedDefault`; commonJS read `Top`, a `ReferenceError`, beam the atom `'Top'`); wasm prints a field of an enum with a payload variant and an optional field by the value's header / the payload's shape (`fieldShape`), and `@print` of a name or field declared as such an enum by its header (`payloadEnumOfName`; both printed an address) — `modules/imported_enum_field`, two wasm descriptor snapshots re-recorded (backend-bugs-2 patch 05)
- [x] 05-wasm rows — `?u64`'s `toString` and a `u64` record field print unsigned; a `u64` tuple slot holds its 8-byte cell — already on `feat` (batch 6, `c6483b21`): `run/optional_u64_to_string`, `run/u64_record_field_print`, `run/u64_tuple_slot` green on the four targets at `106c84b3`
- [x] 02-erlang s4 — `run/array_unique` (C-35), four targets
- [x] 02-erlang s5 box 2 — a decorator body carrying `\u{…}` (cell: 14 s7)
- [x] 02-erlang s7 — C-07's erlang tails as `run/is_truth_table`; `run/unknown_stores_nothing` struck (§11 is a cost, no program prints a difference)
- [x] 02-erlang s10 — the block-as-value lowering (R7): the valueless tail refused by the checker, a `return` the block's fun cannot answer last throws to the block's own guard
- [x] 02-erlang row — an `@block` with a `return` (or in value position) that reassigns an enclosing `var`: every `return` answers `{V, Group}` and the call site rebinds the group (`valueBlockExpr`; `run/block_value_reassigns_enclosing_var`, a `for`'s `return` in `tests/erlang.zig`; bugs-sweep patch 06)
- [x] 03-beam row — a `return` from a `for` inside an `@block` is the block's value: a loop's fun throws `{'__bp_return', V}` (apart from a `try`'s `'__bp_try'`), and `guardLoopCall` answers it into the `@block` of its frame (`answerLoopThrow`, `inBlockExit`); beam answered `7` for `700`. wasm's `blockReturnValue` reads a `return` written in the body before one inside a loop (a string block over a `for` printed an address) — `run/block_for_return_is_block_value` (backend-bugs patch 02)
- [x] 02-erlang s12 · 03-beam s7 — one `math` on every OS (263): on feat (`a443f52d`)
- [x] 02-erlang s13 · 03-beam s8 — an integer that leaves its type aborts (264): on feat (`48a096ea`)
- [x] 02-erlang s15 · 97 s14 box 1 (320) — erlang and beam count codepoints: the emitters and std's Erlang templates read the codepoint list (`run/string_index_of_codepoints`, combining-mark and astral rows)
- [x] 03-beam s9 — a lambda a `case` arm answers is the arm's value (`language-gaps.md` row 28 deleted); an `@block`'s `return` is the block's value; an in-frame loop's head keeps a forward entry under `beam_jump`
- [x] 03-beam row — a variant name declared by two enums with different fields binds the payload on a positional pattern: `beam_asm` registers an imported enum's name (`modules/variant_positional_payload_same_name`)
- [x] 03-beam row — a `case` no arm matches raises `case_clause` (`run/case_no_arm_matches_raises`)
- [x] 03-beam s2 box 1 — C-07's `run/` cells on beam (`run/is_truth_table`)
- [x] 14 s2 slope — ≤ 1 ms/eval on both runtimes (wat 0.5, BEAM 0.6–0.7): kept wasm3 instance, argument-only trace listing, O(text) memo key, the bench's stage split
- [x] 14 s8 boxes 1–3, 5 — a hole's build value (`Part.known` / `Part.value`), the lifted record imported, `comptime` over an expansion; `styled "${tab4} color: red;"` emitted `styledConstant` (`run/styled_holes_known_at_build`, styled's `repository-stages.sh`)
- [x] 14 s8 imported `val`, `contentHash` — a hole naming an imported `val` known at build written at build (the export carries its value, `modules/hole_imported_val_known_at_build`); `comptime hash.contentHash(…)` on the four targets (T19, `run/comptime_std_host_function`)
- [x] 14 s6 341, 343 — a decorator's host function travels with its runtime's cell (std's renamed beside it), refused at the call when a cell its package's `targets` need is missing; a decorator writing a module-level `var` refused at the write (`run/decorator_host_cells`, `modules/decorator_imported_host_function`, `modules/decorator_host_cell_targets`, `reject/decorator_host_cell_missing`, `reject/decorator_writes_module_var`, `reject/typeinfo_all_duplicate_at_entry`)
- [x] 14 s7 — a `comptime/tests` fixture for a `\u{…}` decorator body
- [x] 26 s2 box 3 — measured: rakun's `orm_host.bp` workaround deletable (move to `src/orm/host.bp`; rakun-data 128 passed) — the deletion is a rakun-track row (L2)
- [x] 26 s3 — only a direct dependency is importable (T4, 242): located refusal, `modules/transitive_package_import`
- [x] 26 s4 — `build` and `test` print checker warnings
- [x] 26 s6 — the `subdir` resolver half · decision 344
- [x] 26 s7 — `build.zig`'s `test-docs` comment
- [x] 26 s8 — 206's residuals: the LSP reports `module-import-with-from` and `unresolved import source`; a package importing itself by name refused (309), std's three sources migrated
- [x] 26 row — the LSP makes the 309 refusal: the package name from the nearest manifest, through `engine.importDiagnostics` to the resolver
- [x] 130 s10 part — `@TypeInfo.all` in a template body answers for the calling program (353): the oracle session, the importer's `typeinfo-all-imported` at the handle, `typeinfo-all-template-value`
- [x] 134 s2 part — `@is` refused (322); the drift test walks the mirrored types and `@Result`'s methods (declared); std `Type` (`keys`, `partial`, `required`, `merge`)
- [x] 01-checker s31 row — on commonJS, `x?.m()` over an enum method (`doc.field("src")?.str()` on std `Json`) is the static call guarded around a receiver evaluated once (`optEnumCall`); the owner is read at the checker's link loc (`ast.optional_synthetic_col`) — `run/optional_enum_method_call` (backend-bugs patch 03)
- [x] 134 s5 — the `Decorator` type for `with:` (268)
- [x] 97 s1 residue — `bindInt`'s `i32` through std: `parseInt`, then `toI32()` inside the range; past it a `typeMismatch` (it aborted); `parseI32` deleted (validation)
- [x] 97 s13 box 1 but three — `fs.stat` (`bigint: true`), `async`'s `millisAsFloat` / `wholeMillis`, `clock`'s `wide` (`toI64()`) and `largestExactMillis` (a literal) in 319's canonical form: `run/std_io_i64_canonical`
- [x] 97 s13 boxes 3–5 — `parseInt` exact over `i64`; `min` / `max` / `abs` / `clamp` / `isEven` / `isOdd` past 2^53 on commonJS; `toI32()` … `toF64()` on `Integer`, aborting when the value does not fit (wasm halves: 05-wasm rows)
- [x] 97 s12 — `unicode.fromCodepoint` a `fn:` over `String.fromCodepoint` on all four targets (with `powBody`, `fn:` transcendentals, code-point `contentHash`)
- [x] 97 row — an embedded std module that does not lex or parse is printed located at its `libs/std/src/<module>.bp` file and the build stops with `EmbeddedStdRefused` (was `compilation failed` / `UnexpectedToken`; `parseEmbeddedStd`, `comptime/tests/located_errors.zig`; bugs-sweep patch 08)
- [x] 01-checker — a module is its package plus its path (170, 337): two packages' `theme` modules no longer collide (`modules/two_packages_one_module_name`, four targets); jhonstart's core on `styled` compiles `jhonstart-emilia` on both rows — unblocks 119 s1 box 4 and 34 s5 (front `pkg-module-collision`)
- [x] **first:** `01-checker` s41 (429) — template-built code located by its expansion (`ast.Loc` carries the expansion id; every loc-keyed plan reads the pair; a diagnostic maps to the literal): landed in botopink-lang, erika and jhonstart — `run/template_two_alike_expansions`, `run/template_default_arg_two_expansions` green on four targets and red on the parent on erlang, `reject/template_built_code_diagnostic_located`; erika's and jhonstart's padding dropped, their gates green · lands as one compiler commit and one consumer commit each; 137 s4's erlang cells are free
- [x] 14 s2 rest — N=200 ≤ 600 ms on the BEAM runtime: moot, closed by decision 434 (no BEAM comptime runtime is left; the wat runtime's slope is the line above)

### 146 validation

- [x] 125 s0 residue — the `f32` and `url.parse` platform facts as tests
- [x] 125 s2 residue — the examples as suite cases, the 2 000-deep test, the refusal test, `schemas.bp`'s accessors
- [x] 125 s3 — checks and formats (39 `surface.md` rows)
- [x] 125 s4–s12 — enums, unions, tuples, dicts, sets; object policy; coercion and `T.bind`; messages and locales; `T.encode`, codecs, `#[each]` / `#[check(rule)]` (a field's `#[refine(rule)]` since 406) / `#[preprocess]`; error views and `T.jsonSchema()`; `#[schema]` folded into `#[validated]` (327's members, `derived` private, `#[validated(transparent)]`) — validation 246 / 0 on erlang and commonJS; consumer patches rakun (375 / 0) and onze-content (714 / 0) — validation, rakun and onze land as patches (hooked)

### 162 onze

- [x] 162 s11 — onze-cli's CSS accessors test creates its app as `cssapp`, not `styled` (a package of jhonstart's closure); onze-cli's tests green on commonJS and erlang (from 144 B-80)
- [x] 114 — onze-cli `start_test.bp` asks the OS for each server's port (`freePort`, a listener on port 0) instead of 43101/43102; both cells green run side by side (onze-wave patch 05, lands with the coordinator)
- [x] 121 s1–2 — Markdown to `Element` in `onze-content` (onze `584f64a`, on `feat`): 714 / 714 on both rows at onze `05b7005`
- [x] 49 s1 · s6 — `config.bp` / `types.bp` on std's `Json` methods (`isString` stays — `49-g`); the six `onze-test` group stubs (onze-wave patch 02)
- [x] 50 s1 — `onze-cli` / `onze-bundler` read std's `Json` methods; no local `membersOf` / `itemsOf` / `textOf` (onze-wave patch 03)
- [x] 51 s1 — `onze-og` reads integers with std's `parseInt`; no `intOf` (malformed text still `0` — `51-a`) (onze-wave patch 04)

### 150 rakun

- [x] 128 (W3) — the nine merges, alone in rakun: 25 members → 16, 1 819 tests before and after, every starter and example building (rakun `00d4fcc`…`343a55c`, eleven commits)
- [x] rakun-websocket `test/limits_test.bp:48` — the 1013 test read `rkWsSessionIds()` before the connection had registered its session (101 is written before `run/4` inserts the row: 19 of 200 handshakes under load 31 found none, so every frame went to no one and the close code was 0), then slept 3 s for the close; it now waits on the session's row and on its close-log entry (test-side Erlang helpers; chores patch, rakun test file only, rebase after 128) — 7 runs green under load 20–37 beside rakun-messaging's suite
- [x] rakun track — removed the workarounds the compiler made deletable (patches in review: each repro green on the pinned compiler; rakun-data 181, rakun-messaging 131): rakun-data `rows.bp`'s `longOf` (C2 fixed), `runtime.bp`'s row-89 named fn (row 28 fixed), `orm_host.bp` → `src/orm/host.bp` (26 s2) · `04-rakun` RX-14
- [x] rakun track — latent `i32` clocks widened to `i64` (rakun 442, actuator 103, data 181, mail 32, messaging 131): `migration_host.cellNowMs`, the test-only monotonic `nowMs` in `rakun-mail`, `rakun-rsocket` and `tls_listener_test`, `Duration.millis` · `04-rakun` RX-15
- [x] rakun track — stale `__rkMake_` text in rakun's `AGENTS.md` · `04-rakun` RX-16
- [x] rakun track — the server test measures `Content-Length` in bytes (320's follow-up) · `04-rakun` RX-17

### 157 routing

- [x] 102 s1–2 — `conventions.bp` and the segment helpers in `libs/routing` (re-implemented)
- [x] 102 s3 (W2) — consumers, one commit per member: rakun-app and rakun-hateoas (rakun de85b3d), jhonstart `routes.bp` (`#[page]` → `segment.paramNamesOf`, jhonstart 6b368ec), onze-cli, onze-bundler and onze (onze 3c25410; `classifyAppFile` and `patternOfSegment` gone) · decision 323

### 159 actions

- [x] 103 s1 — `id.bp` (`deriveActionId`, `isActionId`) in `libs/actions` (re-implemented)
- [x] 103 s2 (W2) — consumers: rakun-app `actions.bp` (`actionId` deleted, 324), jhonstart-forms `form.bp` (`isActionId`)

### 163 meta-ci (medium)

- [x] 138 — the five new repositories carry Node 22 and the glibc 2.35 note (actions 5b78ce8, http fe75240, log 220cfe2, routing 7e6a24f, validation bf0610f); their first CI run reads after this push
- [x] 138 (decision 326) — actions, http, log, routing, validation are repository/<pkg> submodules (history kept); the compiler embeds std alone (botopink-lang 541336e3); rakun, jhonstart, onze declare them
- [x] 138 rest — doc comments say "shared library" where they said "bundled library" (jhonstart, onze, routing, validation; rakun's starter-web `root.bp:3` rewritten: `validation` is declared by rakun core, the starter lists it nowhere); emilia, erika, jhonstart and onze `test.yml` on Node 22 with the `fs.globSync` note; onze-cli `build.bp:165`'s two T7 warnings gone at their cause — the `extraDeps` list is built in place, no variable lends its name as a label (chores patches, land with the coordinator; jhonstart 204+15, onze-bundler 42, onze-cli 31, routing 82, validation 246 passed, 0 failed, on commonJS and erlang)
- [x] 138 rest, rakun — "shared library" doc comments in rakun's sources, the four formerly non-canonical files included (after 128)

### 149 jhonstart

- [x] 27 s1 box 1 · s2 boxes 1, 3 · s3 — the reconcile driver (`applyTransition` over `DomOps`, question 27-b ★), `use linkStatus()` in a `#[client]` component (363), `data-jh-pending`, the example (jhonstart `b25e959`)

### 154 emilia

- [x] 33 s2 — `emilia-card` emilia-only, the fifteen example READMEs (s1, s3, s4 are 135's)

### 160 snap

- [x] 135 s0 (391) — the `snap` library: scaffolded and a submodule (`repository/snap`), `botopink.json`, the engine and std's four `.snap` moved in, std's `String.normalizeNewlines` / `trimTrailingNewlines` / `firstDifferingLine` and `fs.mkdirRecursive` (402), jhonstart and onze importing from `snap`, `contracts.md` § 7 — landed (botopink-lang `11bde540`, snap `30ee7f5`, jhonstart `d47fffc`, onze `b6b0e0d`; every `.snap` byte-identical); the old import keeps the plain unknown-module error, the pointer documentation (407) · none; 135 s1–5 write through it
