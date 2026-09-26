# Decisions the maintainer owes — 1.0.10-beta

**Three open** — front 24's open points 7 and 8, and 129 (type-alias details), below; plus five `01-std` implementation choices to confirm (01std-a…e), three of `00 · 23-std-purity` (23-a…c), five of front 95's (95-a…e), four of `00 · 16-formatter` (16-a…d), track C's (26-a, 27-a, 30-a…e, 31-a), `00 · 04-js` / `05-wasm`'s (0405-a…b) and `00 · 02-erlang` / `03-beam`'s (0203-a…b). Every other question this milestone raised is answered in
[`decisions-taken.md`](./decisions-taken.md) — 91, 92, 93 and 97 by decisions 103 and 104, 99 by 108,
94, 100 and 101 by 113; every number up to 117 is answered — 114 answers the eight seams decision 113 left open, 115 the five points 114 left open, 116 nine more pieces two libraries both run, 117 the nine points 113–116 left, and 118–127 register the maintainer's effect revision (the return type is the annotation, `@Task<T>`, only `@Result` fails, `@Iterator<T>` / `@Stream<T>`, `async { }`, `iter` / `stream` loops, no compatibility mode — front `00 · 24-effects-by-return`), and 128 merges `@Use<C, T>` and `@Component<T>` into `@Component<C, T>`. The next free number is **130**.

This file stays because the fronts will fill it again. A front that meets a question it cannot answer
from the code writes it here rather than guessing, in the shape the others used:

> **Raised by:** `<NN>-<front>` step <k>, <date>
> **Measured.** What was observed, with the command or program that produced it and the file or commit
> that can be re-read.
> **Options.** Each one stated so that choosing between them is possible without reading the code.
> **Recommendation.** One, argued — the default is the most restrictive behaviour, and no configuration
> that bypasses it (decision 67).
> **Blocks.** The step, front or landed work that waits on the answer.

## Front 24 (effects by return) — choices made in implementation, to confirm

Each one was decided by the implementation so the front could land; the maintainer confirms or
reverses it. Numbered `24-a` … so they do not collide with the decision numbering.

### 24-a · The effect codes the diagnostics table does not name (README open point 2)

> **Raised by:** `00 · 24-effects-by-return` step E3, 2026-09-25
> **Measured.** At compiler `86609a66`: `effect-missing-annotation`, `effect-missing-wrapper`,
> `effect-duplicate-annotation`, `effect-on-declare-forbidden` and `effect-on-behavior-method-forbidden`
> have no annotation left to be about; `for-over-fallible-generator` enforced a rule decision 122 deletes;
> the guide spells a `throw` refusal with `effect-try-without-fallible-channel`.
> **Options.** (a) delete the annotation codes, merge `effect-throw-without-fallible-channel` into
> `effect-try-without-fallible-channel`, keep `effect-wrapper-mismatch` for the one mismatch left, keep
> `yield-without-generator` / `generator-loop-closed-scope`; (b) keep a separate `throw` code.
> **Recommendation.** (a), implemented: `comptime/diagnostics.zig` lists the survivors;
> `effect-wrapper-mismatch` now means only "a component's `T` implements `@Context<B>` with a `B` other than
> the `C` it is written with"; `for-over-future-generator` / `for-await-expects-future-generator` are renamed
> `for-over-stream` / `for-await-expects-stream`. The guide's code-less refusals (a component `use`d, `use`
> in a closure, `break :outer` out of a prefixed loop) keep their existing codes (`use-of-non-context-fn`,
> `use-without-context-effect`, `generator-loop-closed-scope`).
> **Blocks.** Nothing — reversible by renaming constants.

### 24-b · `@Task`'s method set (README open point 4)

> **Raised by:** step E1, 2026-09-25
> **Measured.** `builtins.d.bp` had `Future.map` / `flatMap` / `await`; decision 120 says "`.map`,
> `.then` and the like, without an error parameter".
> **Options.** (a) `map` and `then` (the monadic bind under the name the guide uses); (b) add `flatMap` as
> an alias of `then`.
> **Recommendation.** (a), implemented — one spelling per operation (decision 67). `mapError` has nothing to
> map. Neither method is lowered by a backend yet: they are declared (documentation, like the rest of
> `builtins.d.bp`) and a call to them is not type-checked against the declaration until the behavior-method
> registry reads wrappers.
> **Blocks.** std/async (24-c) if it wants a combinator form.

### 24-c · `iter for` / `iter while` as a desugared `loop`, and the label's place (README open point 9)

> **Raised by:** step E2, 2026-09-25
> **Measured.** The README asks for a `GenLoop { kind, loop }` node; the four backends each lower one
> annotated-loop shape (the `loop` of 22-loops).
> **Options.** (a) a new node and a fourth-times-four set of lowerings; (b) parse `iter for (xs) { … }` as
> the prefixed `loop { for (xs) { … }; break; }` it means — decision 125's own equivalence — keeping the
> written keyword in `LoopExpr.prefixedKeyword` for the formatter.
> **Recommendation.** (b), implemented. The label stays where 105 writes it, after the loop keyword:
> `iter loop :l { … }` labels the generator scope (`yield :l`, `break :l v`); `iter for :l (xs) { … }` labels
> the written `for` (so `break :l` / `continue :l` keep their meaning) — `yield :l` there is then
> `yield-label-not-generator`. If the maintainer wants the label of a prefixed `for` to name the generator
> scope too, the parser moves it to the outer node; nothing else changes.
> **Blocks.** Nothing.

### 24-d · The codemod needs the old syntax; E2 refuses it at parse time

> **Raised by:** the codemod thread (`front/24-codemod`, E6), 2026-09-25; resolved on
> `front/24-integration`, 2026-09-26
> **Measured.** `botopink migrate effects` type-checks the OLD program to decide `await` → `try await`
> (and the `for` / `.next()` / `case` review marks). At `86609a66` the parser refuses every removed
> annotation and wrapper (`effect-annotation-removed`, `effect-type-removed`) and stops — there is no AST
> for the old program, and the checker no longer knows `@Future` / `@ResultGenerator` /
> `@FutureGenerator`. Merged as written, four of the codemod's seven unit tests fail (every module
> "does not parse").
> **Options.** (a) the codemod runs from a binary built at `feat` before E2 (its own copy of the old
> parser/checker — about 120 000 lines of `compiler-core/src` — shipped only inside `migrate`); (b) a
> migration-only mode reachable only from `migrate effects`: the parser reads the old annotations and
> wrappers, the checker types them with their pre-front-24 meaning; (c) the codemod rewrites textually
> and leaves `await` → `try await` to the E3.9 type-error hint.
> **Recommendation.** (b), implemented (compiler `9d8331ad`). `comptime.setEffectMigration(files)` is
> called only by `migrate_effects.run` / `migrate` for their own duration and cleared before they return;
> it is thread-local, and no flag of `build` / `check` / `test` or the language server reaches it, so
> every normal compile still refuses the old forms (decision 67 — a unit test pins that the refusal is
> back once the command returns). While it is on: the **parser** (`parser.effect_migration`) drops a
> removed `#[@<effect>]` annotation (on a loop it becomes the `iter` / `stream` prefix) and reads a
> removed wrapper as its new spelling — `@Future<T, E>` → `@Task<@Result<T, E>>`, `@Future<T>` →
> `@Task<T>`, `@Generator<T>` → `@Iterator<T>`, `@ResultGenerator<T, E>` / `@Iterator<T, E>` →
> `@Iterator<@Result<T, E>>`, `@FutureGenerator<T, E>` → `@Stream<@Result<T, E>>`, `@Use<C, T>` →
> `@Component<C, T>`; the **checker** (`infer.effect_migration_files`), only in the files the codemod
> rewrites and the dependencies that still spell the old surface, gives the old meaning — `await` of a
> `@Task<@Result<U, E>>` answers `U`, a `for` / `for await` over a sequence of `@Result<T, E>` binds `T`,
> and `throw` / `try` need no `@Result` layer. The mode is not a second grammar: it is two spellings
> mapped onto the one AST and three relaxations in the checker (≈ 120 lines), and it dies with the
> codemod. Measured: the codemod's snapshots are unchanged, and over the 53 packages of jhonstart,
> rakun, emilia, onze and erika at their pre-front-24 pins its output is byte-identical to the pre-E2
> codemod binary's (`front/24-crosscheck-libs` `b2985088`). Known imprecision: an old
> `@Generator<@Result<T, E>>` / `@Future<@Result<T, E>>` reads like a fallible wrapper, so its `for` /
> `await` would gain a `try` it did not have — none occurs in the five libraries. (a) was the earlier
> recommendation; it is the heavier of the two by three orders of magnitude and leaves two compilers in
> one binary.
> **Blocks.** Nothing — the codemod is merged with its tests green.

### 24-e · `try` and `await` as operands

> **Raised by:** step E2, 2026-09-25
> **Measured.** `total + try r`, `(try batch).length` and `yield try x` are guide spellings; the parser
> only read `try` / `await` at the start of an expression statement, and `yield` took an equality-level
> operand.
> **Options.** Parse them where a primary expression may stand (operand = the next primary, postfix chain
> included), or keep them statement-only and rewrite the guide.
> **Recommendation.** Parse them, implemented. Each backend now propagates a `try` that has no rest of
> the function to nest in: commonJS through `__bp_try` + a per-function guard, erlang through
> `throw({'__bp_try', E})` + a guard, beam by throwing out of a loop's fun to a catch section at the loop's
> call site, wasm as before; inside a sequence whose item is a `@Result`, the failing `try` emits the
> Error as the last item and ends (decision 122).
> **Blocks.** Nothing.

### 24-f · `test-libs` cannot be measured from a worktree nested in the meta checkout

> **Raised by:** step E7, 2026-09-25
> **Measured.** `zig build test-libs` from `.tasks/24-effects-by-return/repository/botopink-lang` sees
> every sibling library twice (`.tasks/…/repository/<lib>` and the main checkout's
> `repository/<lib>`) and every cell except std fails with "`<lib>` is declared by two libraries".
> **Options.** (a) the lib-test-runner stops walking up past the first `repository/` ancestor;
> (b) run `test-libs` only from a non-nested checkout.
> **Recommendation.** (a), as a `lib-test-runner` fix outside this front. Until then front 24's ledger
> lines (`scripts/known-red-libs.txt`, `restricted-targets.txt`) were written from a static reading of
> which libraries spell the pre-118 surface, not from a measured run.
> **Blocks.** The E7 acceptance box "test-libs green on every row".

### 24-g · `std/async`'s shape under a Task that never fails (README open point 3)

> **Raised by:** step E7, 2026-09-25
> **Measured.** At compiler `f3ad584a`, `std/async` had a thunk surface (`allOf`, `settleOf`, `raceOf`,
> `timeout` over `fn() -> @Future<T>`) and a started surface (`all`, `allSettled`, `race` over
> `@Future<T>`), both built on a rejected future being the failure. The guide writes
> `try await async.allOf([fetchUser(1), fetchUser(2)])` — started Tasks whose value is a `@Result` — and
> the `front/24-cells` suite follows it; the `beam_memory_*` cells need unstarted thunks, because an eager
> erlang Task has already run by the time a combinator receives it.
> **Options.** (a) `allOf` over started `@Task<@Result<T, E>>` (stops at the first `Error` in input order)
> plus a thunk surface under other names; (b) `allOf` over thunks, as `01-std/02` wrote it; (c) one
> overloaded `allOf` for both element shapes (the language has no overloading by type).
> **Recommendation.** (a), implemented: **started** — `allOf(Array<@Task<@Result<T, E>>>) ->
> @Task<@Result<Array<T>, E>>`, `all(Array<@Task<T>>) -> @Task<Array<T>>` (both written in botopink over
> `try await` / `await`), `race`; **unstarted** — `runAll(Array<fn() -> @Task<T>>) -> @Task<Array<T>>`
> (spawned per task on erlang, `Promise.all` on node; over `@Result` thunks it is the settled view),
> `raceOf`, `timeout(task, millis) -> @Task<@Result<T, string>>` answering `Error("timeout")` (a `string`,
> as every std error is — no `TimeoutError` type, and a fallible task's own `Error` stays inside the `Ok`).
> `failed(message)` answers `Error(message)` instead of rejecting. `allSettled`, `settleOf`, `unwrapAll`
> and `attempt` are removed: a Task has no rejection to settle. A crash inside a spawned task is
> re-raised (a crash is a bug, decision 120's fatal host failure).
> **Blocks.** `01-std/02-std-async-primitives`, whose README still specifies the thunk-shaped `allOf`.

## Front 01-std (the bundled libraries, `json.decode`) — choices made in implementation, to confirm

Decided by the implementation of `01-std-lib-enablement` Step 13, `04-routing-lib`, `05-actions-lib`
and `06-validation-lib` (worktree `.tasks/01-std-libs`, 2026-09-26) so the fronts could land; the
maintainer confirms or reverses each.

### 01std-a · Where a bundled library is loaded — the CLI and the LSP, not `expandStdImports`

> **Raised by:** `01-std/04-routing-lib` Step 2, 2026-09-26
> **Measured.** The front's *Mechanism* table generalises `expandStdImports` and replaces each `"std"`
> check in compiler-core, `commonJS.zig`, `erlang.zig`, `beam_asm.zig` and `engine.zig` with a lookup.
> `std`'s path through the core is std-specific end to end (`markStdImports`, `env.stdModules`,
> qualified-call gating, the BIF table, synthesised imports), and `beam_asm.zig` is held by fronts 14
> and 18. A declared dependency, on the other hand, already reaches the codegens as ordinary modules
> `<dep>/<stem>` and comes out as `<dep>@<stem>` / `./<dep>/<stem>.js` (decision 109). Implemented:
> `build.zig`'s `bundled_packages` generates `comptime.bundled_packages` (names + embedded `.bp`
> modules); the CLI (`libs.loadDependencies` → `appendBundled`) and the LSP
> (`ProjectGraph.appendBundled`) prepend the embedded modules of every bundled package a module
> imports; `checkImportSources` exempts bundled names; a bundled name in `dependencies` is refused.
> compiler-core names no package but `std`; no codegen file changed; `snapshots/codegen/**` unchanged.
> **Options.** (a) keep it — a non-std bundled package is ordinary code to the core, as decision 115's
> "`routing` is ordinary code to the checker" reads; (b) generalise `expandStdImports` and the std
> checks as the table says, which changes the four codegens and the checker for no observable
> difference today.
> **Recommendation.** (a). The observable contract of Step 2 holds (no `dependencies`, atoms,
> requires, refusal, embedded copy only); the one box it does not tick is the compiler-suite test
> beside `std_package.zig`, replaced by CLI and LSP unit tests.
> **Blocks.** Nothing; `00 · 23-std-purity` step 3 rewrites `stdPkgFilesFromRoot` beside the new
> `bundledPkgFiles` and should keep `std` out of the latter.

### 01std-b · `json.decode` converts a validated numeral through the host's `strtod`

> **Raised by:** `01-std-lib-enablement` Step 13, 2026-09-26
> **Measured.** The language has no text → float conversion and no integer → float one. Scaling the
> digits by powers of ten in botopink is identical on both targets but not correctly rounded
> (`1.7976931348623157e308` came out a different `f64`). `binary_to_float` and `Number` of the same
> canonical `-?D+.D+e-?D+` spelling agree bit for bit and are correctly rounded; overflow is an
> `Error` on both, underflow `0.0` on both.
> **Options.** (a) the grammar in botopink, the conversion through a private cell `numeralValue`
> (implemented; `decode` itself declares no cell); (b) pure botopink, correctly rounded only within
> the fast-path range (≤ 15 significant digits, |exponent| ≤ 22); (c) a `f64.parse` in the language.
> **Recommendation.** (a) now, (c) later — the Step 13 box "`decode` declares no `#[@External]` cell"
> is read as "no parser template"; four private conversion cells remain in `json.bp`
> (`codePointsOf`, `textsOf`, `codepointText`, `numeralValue`).
> **Blocks.** Nothing.

### 01std-c · `routing.pattern`'s empty pattern matches only `/`

> **Raised by:** `01-std/04-routing-lib` Step 8, 2026-09-26
> **Measured.** rakun-web's `matcherMatches("", path)` was true for every path (the Next default for a
> middleware with no `#[matcher]`); `routeMatches` had no such rule. A grammar shared with jhonstart
> should not carry one consumer's default.
> **Options.** (a) `parsePattern("")` is no segments and matches `/` only; rakun-web keeps "empty runs
> everywhere" at its call site (`matcherAdmits`) — implemented; (b) the library's empty pattern
> matches everything.
> **Recommendation.** (a). Leaves the Step 8 box "every `middleware_test.bp` assertion has a line here
> with the same literals" one literal short, by design.
> **Blocks.** Nothing.

### 01std-d · The decorator registry is keyed by bare name — rakun's placement-only `#[validated]` left

> **Raised by:** `01-std/06-validation-lib` Step 7, 2026-09-26
> **Measured.** In `modules/rakun`, a test importing `{decorators.validated} from "validation"` got
> `unbound variable 'validateProbe'`: `config.bp`'s placement-only `pub fn validated(comptime decl:
> @Decl)` shadowed the imported one package-wide, even under `as`. The same probe in a package with no
> local `validated` passes. `comptime.zig` `resolveImports` looks decorators up in one
> `StringHashMap(FnDecl)` keyed by name.
> **Options.** (a) delete rakun's placement-only marker (implemented — decision 116 rule 5 already says
> never both); (b) key the decorator registry by module and resolve through the import, a checker
> change for `00 · 01-checker`.
> **Recommendation.** (a) for rakun now, and (b) as a checker item: two libraries may not declare a
> same-named decorator today without one silently winning.
> **Blocks.** Nothing here; (b) blocks any two bundled/declared libraries sharing a decorator name.

### 01std-e · `actions.readEnvelope` refuses a `redirect` that disagrees with `n`

> **Raised by:** `01-std/05-actions-lib` Step 3, 2026-09-26
> **Measured.** The spec derives `redirect` from `n` in the writer; the reader was silent. The only
> writer can never produce a disagreeing pair, so one that arrives was not written by it.
> **Options.** (a) refuse it (implemented, decision 67); (b) read `n` and ignore `redirect`.
> **Recommendation.** (a).
> **Blocks.** Nothing.

## Front 23 (`00 · 23-std-purity`) — choices made in implementation, to confirm

Decided by the implementation of steps 3 and 5 (worktree `.tasks/23-std-purity`, 2026-09-26) so the
tree could land; the maintainer confirms or reverses each.

### 23-a · A `collections` constructor is reached through its type leaf, not the module namespace

> **Raised by:** `00 · 23-std-purity` step 3, 2026-09-26
> **Measured.** Decision 111's `Dict.empty()` compiles and runs on commonJS, erlang, beam and wasm
> when `Dict` is imported as a leaf (`import {collections.Dict}` / `collections: {Dict, Set}`).
> After `import {collections} from "std"`, `collections.Dict.empty()` is `unbound variable
> 'collections'` on every target — the checker has no `module.Type.fn()` path; `collections.toInt(…)`
> (a module function) resolves. Every importer written by the sweep (routing, rakun, the compiler's
> tests and cells, `examples/stdlib-tour`) uses the leaf form.
> **Options.** (a) the leaf form is the spelling (implemented; decision 111's own example imports
> `collections: {Dict, Set, Queue}`); (b) teach the checker and the four codegens
> `module.Type.fn()` — the same use-side path decision 110's folder namespace needs.
> **Recommendation.** (a) now, (b) with decision 110 (23 step 6, open): one change covers both.
> **Blocks.** Nothing.

### 23-b · `base64`'s four functions are retired, not aliased

> **Raised by:** `00 · 23-std-purity` step 3, 2026-09-26
> **Measured.** `base64.decode` answered a `string`; its replacement `encoding.base64Decode` answers
> `@Result<string, string>` (front 01 validates before `Buffer.from` truncates), and
> `decodeUrlSafe` → `base64UrlDecode` likewise. No library imported `base64`. `base64.bp` is deleted
> and its four tests are re-spelled over `encoding`'s names at the foot of `encoding.bp` (so std
> stays at 417 tests).
> **Options.** (a) retire the four (implemented — decision 106 and `01-std/modules.md` name the
> replacements); (b) keep `encode`/`decode`/`encodeUrlSafe`/`decodeUrlSafe` in `encoding` as
> string-returning aliases.
> **Recommendation.** (a): two spellings of one codec, one of which hides the refusal, is what front
> 01 removed.
> **Blocks.** Nothing.

### 23-c · Two `botopink test` fixes for a project whose own modules sit in a folder

> **Raised by:** `00 · 23-std-purity` step 3, 2026-09-26
> **Measured.** `botopink test` in `libs/std` after the move: on commonJS every module refused with
> `module 'io/random' requires "./sidecars/random.mjs", but its library 'io' resolves to no package
> directory` (`shipMjsSidecars` reads any `a/b` module name as dependency `a`'s); on erlang twelve
> tests died `{error,undef}` — `test_cmd` wrote a module's type units (`std@io@net@@Socket`) at the
> root of the run, and the runner of `io/net` loads only its own directory and below. A two-module
> scratch (`src/top.bp`, `src/io/rec.bp`, one record each) reproduces the second on any project.
> **Options.** (a) fix both in the CLI (implemented, compiler-cli carve-out: a module whose source
> is in the project's own `src` is the project's; units are written beside the module that declares
> them); (b) keep std flat on disk and nest only the registry keys.
> **Recommendation.** (a). The rules are general — any library with a folder module had both
> defects — and neither touches compiler-core or a snapshot.
> **Blocks.** Nothing.

## Front 02-packaging · 95 (the package cut) — choices made in implementation, to confirm

Decided by `02-packaging/95-ecosystem-package-restructure` (worktree `.tasks/95-packaging`,
2026-09-26) so the relocations could land; the maintainer confirms or reverses each.

### 95-a · Front 95 performs the relocation-only cuts `jhonstart-link` and `rakun-app`

> **Raised by:** `95-ecosystem-package-restructure` steps 5 and 7, 2026-09-26
> **Measured.** `04-jhonstart/modules.md` § 1 puts front 27's `link.bp` / `reconcile.bp` in
> `jhonstart-link`, and `03-rakun/modules.md` § The cut puts fronts 22 and 23 in `rakun-app`; both
> fronts had landed in the core. Front 95's own README listed `jhonstart-link` as "front 27's" and
> said rakun had "nothing left" for it, while its **Owns** line claims "the relocations the cut in
> each library's `modules.md` needs". Nothing in either core imports the moved modules
> (`grep`), so each move is the files plus the import lines it changes: jhonstart 120 → 85 + 35,
> rakun 369 → 310 + 59 on commonJS (367/2 → 308/2 + 59/0 on erlang); `examples/rakun-ssr` prints
> a byte-identical document.
> **Options.** (1) relocate now, as a move with no behaviour; (2) leave both in the core until the
> owning fronts (27's step 4, 22/24) touch them again.
> **Recommendation.** (1) — implemented. The two owning fronts would otherwise make the move in the
> middle of a behaviour change, which is the harder diff to review; `modules.md` § 0 (a) and the
> `fronts.md` rows now name the members.

### 95-b · `rakun-app` inherits the workspace's `targets`

> **Raised by:** `95-ecosystem-package-restructure` step 5, 2026-09-26
> **Measured.** The core it came from declares `["commonJS"]` (a restriction front 04 lifts);
> `03-rakun/modules.md` § Targets says every member is `["erlang"]`, corrected "by the lowest-numbered
> front of each module". The 59 moved tests pass on **both** rows.
> **Options.** (1) no `targets` — inherit `["commonJS", "erlang"]` now and `["erlang"]` when front 04
> changes the workspace root; (2) `["commonJS"]` like the core (an erlang ledger line); (3)
> `["erlang"]` now (a commonJS ledger line, and the node half of `ssr.mjs` untested).
> **Recommendation.** (1) — implemented: both rows are hard cells, no ledger line, and the member
> follows the workspace without an edit.

### 95-c · `erika-test` exists

> **Raised by:** `95-ecosystem-package-restructure`, 2026-09-26
> **Measured.** `02-packaging/README.md` § 2 makes `modules/<lib>-test/` mandatory for every library;
> erika is a workspace since `02-packaging` step 2 and its `AGENTS.md` said the member "waits on
> `01-std` steps 2–3", which have landed. Front 95's table did not list erika.
> **Options.** (1) create it empty now; (2) wait for an erika front.
> **Recommendation.** (1) — implemented: one inline test, 1/1 on both rows.

### 95-d · The onze takeover, prepared: the tag's commit and the orchestrator's first commit

> **Raised by:** `95-ecosystem-package-restructure` step 2, 2026-09-26
> **Measured.** The orchestrator's workspace is an orphan branch `front/95-onze-orchestrator` (no
> history of the mocking library) — seven members, each 1/1 on commonJS and erlang on a copy of
> the tree; the retirement banner is a commit on onze `front/95-packaging` over `feat` `b1e690d`.
> The restricted cells `onze-cli · erlang` and `onze-og · commonJS` need ledger lines that are
> stale (refused) until `repository/onze` is the orchestrator.
> **Options.** Tag `mocking-lib-final` on (1) `b1e690d`, the last code commit, or (2) the banner
> commit. Ledger lines (a) in the compiler commit the takeover's meta bump pins, or (b) now, which
> reds `test-libs` until the takeover.
> **Recommendation.** (1) and (a); the exact commands are in front 95's step 2.

### 95-e · A member importing the core's request context names the module

> **Raised by:** `95-ecosystem-package-restructure` step 5, 2026-09-26
> **Measured.** In `modules/rakun-app/src/ssr.bp`, `import {…, percentDecode, …} from "rakun";`
> is refused: `` `percentDecode` is declared `pub` by `std/encoding` and by `rakun/request_context`,
> and this import does not say which ``. Inside the core the same import (`from "request_context"`)
> named the module. The move writes `from "rakun/request_context"`, which the compiler accepts.
> **Options.** (1) keep the qualified import; (2) rename one of the two `percentDecode`s (decision
> 116 moves rakun's codec to std `encoding`, which would retire the duplicate).
> **Recommendation.** (1) now; (2) is the decision-116 work of rakun front 62, after which the line
> can go back to `from "rakun"` or drop the name.

## Front 16 (formatter) — choices made in implementation, to confirm

Decided by the implementation of `00-compiler-carry-over/16-formatter` (worktree `.tasks/16-formatter`,
compiler `0f0be511`…`7af79f44`, 2026-09-26) so C-12 and C-13 could land; the maintainer confirms or
reverses each. Every number below is measured over scratch copies of the compiler's trees (`libs/std`,
the three bundled libraries, `examples/`) and the five sibling libraries at their pinned commits — 248
`.bp` files — formatted by the parent commit's binary and by the new one.

### 16-a · C-12's argument list is enabled **with** the constructs that enclose it

> **Measured.** Enabled alone (the parked `argument-list.patch`), the list opened ~1 480 of ~2 770
> lists for what followed them (`) != -1;`, `) + "…"`), because the binary expression around them was
> pinned — decision 65's wrong middle. The same happens inside a pinned array literal
> (`[ThemeEntry(` / `…` / `)]`) and after a brace-less `if` condition (`if (absDiff` /
> `    > tolerance) throw "…"`, the condition breaking for the branch that follows it).
> **Options.** (a) Enable the enclosing constructs first, the list after them, one commit each;
> (b) enable the list together with them; (c) keep the list pinned.
> **Chosen: (b)** — (a)'s intermediate commits are each a wrong middle of their own (a binary run
> enabled alone breaks *inside* the still-pinned argument list: `doc.indexOf("."` / `+ a` …), so the
> six trees would be reformatted twice for nothing. One `groupMeasured` each, all-or-nothing, the outer
> deciding first: a **binary run** (one precedence level) breaks before every operator `+4`; a
> **brace-less `if`** puts its branch on the next line `+4` (a bare `else` under an `else` line; an
> `else if` chain breaks at every `else` or at none; a braced `else { … }` stays outside the group);
> the **argument list** takes decision 61 rule 4's shape; the **array, tuple and behavior literals**
> the same. `commaList` (generic, parameter, pattern, import, type lists) and the one-step pipeline
> stay pinned — none of them holds a call.
> **Cost.** 142 files, +20 835 −7 292 (C-13 included); lines past 80 columns 5 973 → 1 840 (the rest are
> strings and comments); lines opening with `)` and going on with an operator 192 → 8. A second pass
> moves nothing, no token or comment is lost, every sibling package `check`s as before and the cells
> run identically (emilia 569, erika 31, jhonstart 120, onze 4, rakun-web 104 — before and after).
> Per sibling: emilia 18 files +12 940 −4 663 (mostly its test assertions: `assert doc.indexOf(…)` /
> `    != -1;`), rakun 47 +4 760 −1 471, jhonstart 19 +784 −231, erika 2 +167 −63, onze 2 +44 −8 —
> **09's reformat, not committed here**; the compiler's own canonical trees are reformatted
> (`44ec5e3a`).
> **Blocks.** 09's reformat of the five libraries; nothing else.

### 16-b · An array literal's open form is one element per line

> **Measured.** Elements written on one source line were kept on one output line. Once the list
> measures width that is not idempotent (the joined line runs past 80, a call inside it breaks, and the
> next pass reads a different layout: 3 files of the corpus moved on a second pass), and it makes the
> output a function of the input's layout, which decision 65 part 2 rules out.
> **Options.** (a) One element per line in the open form; (b) Wadler's `fill` (as many per line as fit).
> **Chosen: (a)** — all-or-nothing, as decision 65 part 1 states for every group; (b) is the middle.
> **Cost.** Part of 16-a's numbers: a long list of short numbers takes one line each.

### 16-c · A trailing comma still opens a list — does it stay?

> **Measured.** An array, tuple, record field list or enum body written with a trailing comma prints
> open even when it fits (Prettier's "magic trailing comma"). That is the output depending on the
> input's layout, which decision 65 part 2 rules out for every construct — but it is the canonical
> form every library is written in, and the broken form now *adds* the comma, so it is stable.
> **Options.** (a) Keep it; (b) ignore the comma: a list that fits is joined, like a hand-broken chain.
> **Recommendation.** (b), by decision 65 part 2 and decision 67 — not implemented here, because it
> reformats every file that writes an open list that fits (a record type's fields among them), which is
> a canonical-form change the maintainer takes, not a front.
> **Blocks.** Nothing.

### 16-d · C-13 stops at "optional": the parser refuses the `;` only after 09 and 12 migrate

> **Measured.** The parser accepts a braced `if` / loop / `case` statement with or without its `;`
> (`a688bfb5`), the formatter prints none (`6c33c6f4`), and the compiler's own trees are migrated
> (`7af79f44`: 213 lines in 27 files, `libs/std`, `examples/`, the three bundled libraries,
> `docs.md`'s fences). Still writing it: `tests/language` **275** sites, and the siblings — rakun
> **454**, jhonstart **40**, erika **28**, onze **1**, emilia **0** (counted by `c13-migrate.py` on
> copies; decision 29's 245 predates rakun's growth). Refusing it now (front 15's parked patch) would
> fail every one of them.
> **Chosen.** Optional until 12 and 09 have run `c13-migrate.py` (or `botopink format`) over their
> trees; then the refusal lands with `blockStatementSemicolon`, narrowed to the braced form
> (`Parser.isBracedBlockStmt` is already the test it needs).
> **Blocks.** Front 15's patch; decision 29's "rejected".

## Track C (jhonstart) — choices made in implementation, to confirm

Decided by the implementation of `04-jhonstart` fronts on `front/04-jhonstart` (worktree
`.tasks/04-jhonstart`, 2026-09-26) so the fronts could land; the maintainer confirms or reverses
each.

### 26-a · Every router cell is dual-target, not `#[@External.Erlang]` only

> **Raised by:** `04-jhonstart/26-jhonstart-router` Step 2 / Step 4, 2026-09-26 (landed with jhonstart `2bb6fd9`)
> **Measured.** A called erlang-only cell reds the commonJS compile of the core member at its call
> site (`` `__jhRoutePath` has no `#[@External.<Target>(…)]` for the node backend ``); the core is
> compiled on both rows. The five reads, `fill`, `navigate` and `lastNavigation` therefore carry a
> `#[@External.Node("./router_runtime.mjs", …)]` twin.
> **Options.** (a) dual-target cells, one assertion set on both rows (landed); (b) move the router
> to an erlang-only member, which the core's render (front 30) then imports across a target split.
> **Recommendation.** (a). Leaves two boxes of the README unticked by design: "all five cells are
> `#[@External.Erlang]`; none is `#[@External.Node]`" and "`__jhNavigate` is the only dual-target
> cell in the file".
> **Blocks.** Nothing.

### 31-a · `notFound()` / `redirect(url)` raise; a boundary captures the raise through one host cell

> **Raised by:** `04-jhonstart/31-jhonstart-error-boundaries` Step 3, 2026-09-26
> **Measured.** A page, layout or template is a `-> @Component<ElementBase, Element>` body and
> cannot `throw` (decision 121), so the README's `notFound();` statement form needs the call itself
> to raise; `throw notFound();` inside a `@Result` thunk must keep working. botopink's `try … catch`
> unwraps a `@Result` only, so no `.bp` code can observe a raise.
> **Options.** (a) the two functions raise the `routing` reason through a jhonstart host cell
> (`__jhRaise`, `signal_runtime.mjs` / `jhonstart_signal.erl`), typed `-> string`, and the boundary
> runs its child through `__jhCapture`, which answers a raise as `Error(reason)` — implemented;
> (b) the functions return the reason and a component returns a "signalling tree" the render
> inspects; (c) a `never` type (the language gap front 63 records).
> **Recommendation.** (a): the same statement works in a page, a layout, a template and a thunk, a
> crashing component is caught like one that answered `Error`, and the render (front 30) needs the
> same capture for its page thunks. `notFoundReason()` / `redirectReason(url)` answer the reason
> without raising, for a caller that wants it as a value.
> **Blocks.** Nothing.

### 27-a · A browser cell in a two-target member is dual-target, its erlang twin answering the server's truth

> **Raised by:** `04-jhonstart/27-jhonstart-link` Step 4 and `29-jhonstart-client-directive` Step 4, 2026-09-26 (`modules.md` § 0 (b) / § 4's unsettled `jhonstart-link` row)
> **Measured.** A CALLED `#[@External.Node]`-only cell reds the erlang compile at its caller; both
> `jhonstart-link` and the core declare both targets, and `linkStatus()` / `propsFor()` call theirs.
> **Options.** (a) dual-target cells — `link_runtime.mjs` + `sidecars/jhonstart_link.erl`,
> `island_runtime.mjs` + `sidecars/jhonstart_island.erl` — whose erlang twins answer what is true on
> a server (no link in flight, nothing prefetched, nothing hydrated, no props) — implemented;
> (b) a wrapper nothing on erlang calls (impossible for a hook a server render calls); (c) a
> commonJS-only member for the cells (splits `link.bp` in two).
> **Recommendation.** (a). Leaves the Step 4 boxes "every cell in the file is `#[@External.Node]`;
> there is no `#[@External.Erlang]` cell" of fronts 27 and 29 unticked by design.
> **Blocks.** Nothing.

### 30-a · The globals are read through `globals()`, not three module-level `pub val`s

> **Raised by:** `04-jhonstart/30-jhonstart-streaming` Step 7, 2026-09-26
> **Measured.** A `pub val globals = Globals(…)` imported from a sibling module is `undefined` on
> commonJS (`Cannot read properties of undefined (reading 'payload')`) and an unbound variable on
> erlang (compiler `f011850c`) — the `language-gaps.md` row "`pub val` of a user record type is
> unexercised", now measured. Three flat `pub val payload / fill / signal` would shadow front 26's
> `fill` in a consumer's flat `import {…} from "jhonstart"`.
> **Options.** (a) `pub fn globals() -> Globals` and `alias(name)` over the registry — implemented;
> (b) three `pub val`s of `string` with non-clashing names (`payloadGlobal`, …).
> **Recommendation.** (a): one spelling (`globals().fill`) for the render, `render.mjs` and onze's
> entry; revisit when a `pub val` of a record crosses modules.
> **Blocks.** Nothing.

### 30-b · `RenderPlugin` is a record of async functions; `chunk` runs where the boundary resolved

> **Raised by:** `04-jhonstart/30-jhonstart-streaming` Step 6 / Step 9, 2026-09-26
> **Measured.** An `Array<RenderPlugin>` of two different types implementing a `behavior` does not
> type (`type mismatch: expected Rec, got Quiet`). On erlang each streamed boundary resolves in its own
> process, and emilia's stylesheet is per process, so a `chunk(id)` called by the render's process
> never sees what the boundary registered.
> **Options.** (a) `RenderPlugin(name, head, chunk, close, payload)` as a record of functions,
> `payload` answering `Array<#(key, json)>` (`[]` for "nothing", one pair otherwise) instead of
> `?#(…)`, and `chunk(id)` called in the boundary's own process right after it rendered —
> implemented; (b) the `behavior` shape once heterogeneous behavior arrays type.
> **Recommendation.** (a). The four moments and their order are the README's; only where `chunk`
> executes moves, and the fill still carries its CSS first.
> **Blocks.** Nothing.

### 30-c · `render` / `renderStream` / `App` live in `streaming.bp`; `compose` takes the page as a thunk

> **Raised by:** `04-jhonstart/30-jhonstart-streaming` Steps 4 and 8, 2026-09-26
> **Measured.** `resolve` needs `render.bp`'s walker and the entries need `resolve` — the same file
> pair importing each other. A layout must run before the page for "a layout's redirect means the
> page is never called", so `compose` cannot take a rendered `page: Element`.
> **Options.** (a) the walker, `compose`, the payload and the document in `render.bp`; `Chunk` /
> `resolve` / `fillHtml`, `Response`, `PageInput`, `App`, `render` / `renderStream` in
> `streaming.bp`; `compose(chain, route, page: fn() -> @Component<…>)` running layouts first over a
> placeholder child — implemented; (b) one larger module.
> **Recommendation.** (a). The flat `from "jhonstart"` surface is unchanged. `PageInput` also gains
> `metadata: Array<Metadata>` / `viewports: Array<Viewport>` (the segments' resolved exports,
> root-first) so the render merges front 32's head itself.
> **Blocks.** Nothing.

### 30-d · `Suspense` registers its boundary with the render

> **Raised by:** `04-jhonstart/30-jhonstart-streaming` Step 1, 2026-09-26
> **Measured.** An `Element` has no field that can carry the thunk, so the render cannot find a
> hand-written boundary in the tree it composed.
> **Options.** (a) `Suspense(b)` pushes `b` into the per-render state (`render.mjs` /
> `jhonstart_render`) as it writes the hole — implemented; (b) a page returns its boundaries beside
> its tree.
> **Recommendation.** (a). Leaves the Step 1 box "`Suspense` reaches no host cell" unticked by design.
> **Blocks.** Nothing.

### 30-e · The segment record is `UiSegment`

> **Raised by:** `04-jhonstart/30-jhonstart-streaming` Step 4, 2026-09-26
> **Measured.** The bundled `routing` also exports `Segment` (its `segment` module); a consumer's
> `import {Segment} from "jhonstart"` is then refused as ambiguous.
> **Options.** (a) `UiSegment`, with `segment(pattern)` / `with*` / `segmentFor` — implemented;
> (b) keep `Segment` and require consumers to name the module.
> **Recommendation.** (a).
> **Blocks.** Nothing.

## Front 00 · 04-js / 05-wasm — choices made in implementation, to confirm

Decided by the implementation on `front/04-05-js-wasm` (worktree `.tasks/04-05-js-wasm`, 2026-09-26);
the maintainer confirms or reverses each.

### 0405-a · `Array.at` with a negative index is out of range on commonJS

> **Raised by:** `04-js`, C-18's commonJS half (decision 47), 2026-09-26
> **Measured.** Native `Array.prototype.at` answers `undefined` past the end and counts a negative
> index from the back (`[10, 20, 30].at(-1)` → `30`). wasm's `$__arr_at` and commonJS's own
> `__bp_string_char_at` answer absence for a negative index; `String.at(-1)` is `null` on commonJS.
> **Options.** (a) `__bp_array_at(xs, i)` answers `null` for any `i` outside `0..len` — one rule for
> both readers and every backend that has a bounds test; (b) keep the native negative reading and only
> map `undefined` to `null`.
> **Recommendation.** (a), implemented: the language documents no negative index, and a program that
> means "the last element" on one backend and "absent" on another is the divergence decision 67 refuses.
> **Blocks.** Nothing.

### 0405-b · The empty value `?.` answers on commonJS still prints `undefined`

> **Raised by:** `04-js` / `05-wasm`, decision 47, 2026-09-26
> **Measured.** wasm prints every empty `?T` as `null` now (`$__print_null`), and commonJS's
> `Array.at` answers `null`. Two commonJS shapes still produce JS's other none: `choose(false)?.kind`
> (native `?.`) and an `if` with no `else` used as a value (`val r = if (n > 0) { "positive"; };`),
> and both print `undefined` — `snapshots/codegen/*/commonJS/{optional_fn_return_null_path,if_simple_conditional_in_fn_body}`,
> where wasm now prints `null`.
> **Options.** (a) `__bp_show` prints `undefined` as `null` — one branch in the §7 printer, which is
> written into every module that prints, so the prelude text of every such commonJS snapshot moves
> (163 per tree); (b) lower `?.` and the else-less `if` to produce `null`, which moves every `?.` site.
> **Recommendation.** (a), as its own commit: the printer is where the spelling is decided, and it
> leaves `== null` (already loose on this backend) untouched. Implemented (compiler `d798775b`):
> 196 commonJS snapshots per tree gained the one prelude line, and the two RUN LOGs above read `null`.
> **Blocks.** Nothing now — commonJS and wasm both print absence as `null`; erlang and beam are C-18's.

## Fronts 00 · 02-erlang / 03-beam — choices made in implementation, to confirm

Implemented on `front/02-03-erlang-beam` (worktree `.tasks/02-03-erlang-beam`, 2026-09-26).

### 0203-a · A primitive method's host spelling (`toUpperCase`) answers on erlang and beam

> **Measured.** `tests/language/test/string_case_conversion.bp` writes `"abc".toUpperCase()`; the
> method's name is `toUpper`, and `toUpperCase` is its `#[@External.Node(…)]` spelling. The checker
> accepts **any** method name on a primitive receiver (`"x".fooBar()` checks), commonJS answers
> because the name is JavaScript's own, wasm already answers both spellings (`$__str_case`), and
> erlang emitted `toUpperCase/1 undefined`.
> **Options.** (a) erlang and beam resolve a `#[@External.Node("<name>")]` spelling to the method it
> spells, after every other lowering missed — **implemented** (`primNodeAliasIn`, compiler
> `31b5d2bf`), so the four backends agree; (b) the checker refuses a method no primitive behavior
> declares, the cell is rewritten to `toUpper`, and the alias leaves erlang, beam and wasm.
> **Recommendation.** (b) is the restrictive reading (decision 67) and is `01-checker`'s; until it
> lands, (a) keeps the four backends giving one answer instead of three. Choosing (b) deletes
> `primNodeAliasIn` and its two call sites.

### 0203-b · A template the BEAM lowering refuses keeps the run-time `'__bp_erl_eval'/2`

> **Measured.** BR5 (compiler `8333aaab`) compiles every `@External.Erlang` template at build time
> through the comptime runtime's reader and lowering; no beam snapshot carries `'__bp_erl_eval'`.
> `lower.zig` refuses `receive`, `!`, the old `catch Expr`, `try … of` and `try … after`, and by
> text at most 6 of `libs/std`'s 159 templates carry one (`async.allOf`/`raceOf`, `encoding`'s
> percent-decode, one `json` reader, `http.get`, `process`'s run).
> **Options.** (a) such a template keeps the run-time evaluator, named in `beam/AGENTS.md` —
> **implemented**; (b) refuse it at build time on beam (a located error naming the construct), so
> those six std functions stop compiling on beam until (c); (c) teach `lower.zig` the five
> constructs (a `front 14`/`18` row — the comptime runtime would gain them too).
> **Recommendation.** (c), and (a) until it lands: decision 67 argues for (b), but (b) turns
> programs that run correctly today into build errors for a construct the compiler, not the
> program, cannot yet lower.

## Open

### `botopink migrate` beside `botopink migrate effects` (front 24, open point 7)

> **Raised by:** `00 · 24-effects-by-return` step E6, 2026-09-25
> **Measured.** At compiler `82e32e36`, `botopink migrate` (`modules/compiler-cli/src/cli/migrate.zig`)
> derives the explicit module tree — it prepends `pub mod X;` to `root.bp` / `main.bp` / `mod.bp` —,
> takes only `--dry-run` and refuses any positional: `botopink migrate src --dry-run` exits 1
> (`tests/cli_contract.sh` row C8). Front 24's README and guide name the effect codemod
> `botopink migrate effects`, which is a positional C8 refuses.
> **Options.** (a) `migrate` alone keeps its module-tree meaning; `effects` is a subcommand,
> recognised only as the first argument, so `migrate --dry-run effects` stays a usage error and C8
> holds unchanged. (b) The module tree moves to `migrate modules` and a bare `migrate` becomes a
> usage error listing the subcommands. (c) A bare `migrate` runs every migration.
> **Recommendation.** (a) — implemented on `front/24-codemod`, compiler `ba529e09` (`main.zig`, `parseMigrateEffectsOpts`;
> contract row C8b). Nothing that works today changes meaning, and a word in first position cannot be
> mistaken for the positional C8 refuses. (b) is the tidier surface but breaks a documented command
> for no gain in this milestone; (c) makes one command rewrite two unrelated things — the most
> restrictive reading of decision 67 is that each rewrite is asked for by name.
> **Blocks.** Nothing: E6 ships (a). The answer decides how E8's `docs.md` presents the command, and
> whether a later front renames the module-tree form to (b).

### Front 24 open point 8 — the error a failing render carries, and whether the writers stay infallible

> **Raised by:** `00-compiler-carry-over/24-effects-by-return` step E7 (rakun's half), 2026-09-25
>
> **Measured.** Decision 117 item 1 says `renderStream` "resolves when the response is closed, and a
> failed render (rule 1's target check, a plugin's `close`) is the future's error". Under decision
> 120 a `@Task` has no error, and decision 121's note leaves the `E` and the writers' shape to this
> step. Decision 120 already respells the pieces around it: `RenderPlugin.close` →
> `@Task<@Result<void, string>>`, `ChunkWriter.write` / `close` and `PageRenderer` → `@Task<void>`,
> jhonstart's `Response.write` / `close` → `@Task<void>`. In `repository/rakun` at `feat` `f67c1e8`
> none of `ChunkWriter`, `PageRenderer`, `page(pattern, render)` or `servePage` exists yet (they are
> rakun front 23 step 1's, specified in `03-rakun/23-rakun-ssr-pipeline/README.md:78-86`); the
> render code that does exist — `ssr.bp`'s `render`, `document`, `renderAll`, `missingPage` and the
> host `rkSsrAll` — neither throws nor tries (`grep -nE 'throw|try ' modules/rakun/src/ssr.bp`
> over their bodies finds nothing; a miss is the status 404, not an error), so the E7 sweep moved
> each `@Future<T>` to `@Task<T>` with no `@Result`.
>
> **Options.**
> - **(a)** `E = string`, the writers infallible. `renderStream(…) -> @Task<@Result<void, string>>`;
>   `PageRenderer = fn(req: Request, out: ChunkWriter) -> @Task<@Result<void, string>>`, so onze's
>   boot closure stays `return ui.renderStream(…)`; `ChunkWriter.write` / `close` and
>   `Response.write` / `close` stay `@Task<void>` as decision 120 spells them. rakun's dispatch
>   answers an `Error(msg)` like an untagged raise of the renderer: 500 when nothing was written,
>   otherwise the response is closed; the message goes to the log under a correlation digest and
>   never on the wire (rakun-web's rule). A write after `close` and `setStatus` / `setHeader`
>   after the first `write` keep failing the request (a raise, decision 67) — they are misuse, not
>   an outcome. `servePage` stays `@Task<i32>` (the status written).
> - **(b)** A typed error, `RenderError { TargetRefused(target: string), PluginClose(plugin: string,
>   detail: string), … }`, instead of `string`. Stricter to match on, but `RenderPlugin.close` is
>   already `@Result<void, string>` by decision 120, so (b) re-opens that too, and jhonstart would
>   own a type rakun has to name in `PageRenderer` — the dependency decision 114 item 5 forbids.
> - **(c)** `renderStream` stays `@Task<void>` and a failed render raises (the request answers 500).
>   Keeps every signature as decision 120 wrote it, but drops the value decision 117 promised and
>   makes the failure uncatchable from `.bp` code (a raise is not catchable, `rakun-web/src/error.bp`).
> - **(d)** The writers become fallible too, `write: fn(string) -> @Task<@Result<void, string>>`,
>   so a peer that went away is a value. Every chunk then needs a `try await`, and a vanished peer
>   is not something the renderer can act on — rakun already owns the socket and closes it.
>
> **Recommendation.** (a). It is what decision 120's respelling implies (the one fallible piece of
> the pipeline, a plugin's `close`, is already `@Result<void, string>`, so the render that forwards
> it carries the same `E`), it keeps rakun ignorant of jhonstart's types (decision 114 item 5), and
> it is the strict reading of "a failed render is the future's error": the failure is a value the
> dispatch must handle, and its handling is fixed (500 / close, digest in the log) with no switch
> to put the message on the wire (decision 67). The writers stay infallible because their failures
> are misuse (a raise) or the transport's (rakun's), never the renderer's to handle.
>
> **Blocks.** rakun front 23 step 1 (`ChunkWriter`, `PageRenderer`, `servePage`); jhonstart front 30
> (`renderStream`'s signature); onze front 49 (the boot closure); the E8 respelling of
> `03-rakun/23-rakun-ssr-pipeline/README.md:78-99`. Nothing in `repository/rakun` at `f67c1e8`
> waits on it — no code there spells these types yet.

## 129. The type-alias details decision 118 leaves open

> **Raised by:** `24-type-alias` (the alias declaration decision 118 rule 1 presupposes), 2026-09-25
> **Measured.** Decision 118 rule 1 writes `pub type Parser<T> = @Result<T, ParseError>;` and rules
> that an alias types a function without activating its effect; nothing decides the declaration's
> edges. The compiler at the `front/24-type-alias` commit implements the restrictive reading of each
> (parser: `parser/decls.zig` `parseTypeAliasDecl`; checker: `comptime/infer.zig` `expandTypeAlias`
> / `checkTypeAliasDecl`; tests: `parser/tests/type_alias.zig`, `comptime/tests/type_alias.zig`).
> **Options.**
> 1. *A bare generic alias* (`x: Parser` for `type Parser<T> = …`): (a) refused, `type-alias-arity`
>    — implemented; (b) read as `Parser<fresh>` the way a bare generic `type` is.
> 2. *A parameter default* (`type P<T = i32> = …`): (a) refused at the parse,
>    `type-alias-generic-default` — implemented; (b) allowed, with decision 8's trailing-default rule.
> 3. *An annotation on the alias* (`#[deprecated] type Id = i32;`): (a) refused,
>    `type-alias-annotated` — implemented; (b) carried like a `type`'s annotations.
> 4. *`as` on an imported alias* (`import {Parser as P}`): (a) refused like any type,
>    `import-alias-on-type` — implemented, since decision 110's checker-local type alias has not
>    landed; (b) allowed once 110 lands for types, because an alias has no emitted identity at all.
> 5. *An alias taking the name of a type in scope*: (a) refused, `type-alias-name-taken` —
>    implemented; (b) the alias shadows.
> 6. *A return alias of a wrapper in the backends*: the backends see `-> Parser<i32>` unexpanded
>    (so none lowers it as an effect) and every other alias expanded (`comptime/alias_erase.zig`).
>    No alternative is proposed; recorded so the effect front reads the same position.
> **Recommendation.** (a) for 1–5: each is the most restrictive reading (decision 67), and each can be
> relaxed later without breaking a program that compiles today. For 4, revisit together with 110.
> **Blocks.** Nothing — the alias ships with the (a) readings; front `24-effects-by-return` reads
> `Env.aliasedWrapper` for `effect-wrapper-behind-alias`.
