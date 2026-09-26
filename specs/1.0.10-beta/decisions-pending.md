# Decisions the maintainer owes — 1.0.10-beta

**None open.** Implementation choices wait for the maintainer to confirm or reverse them: five of
front 24's (24-a…c, 24-f…g), five `01-std` ones (01std-a…e), three of `00 · 23-std-purity` (23-a…c),
five of front 95's (95-a…e), two of `00 · 16-formatter` (16-a…b), track C's (26-a, 27-a, 30-a…e, 31-a),
`00 · 04-js` / `05-wasm`'s (0405-b) `00 · 02-erlang` / `03-beam`'s (0203-a…b), track D's (05emilia-a…h) and `libs-external-methods`' (lem-a…f). Every question
this milestone raised is answered in [`decisions-taken.md`](./decisions-taken.md) — up to 128 as
before; 129 the type-alias details, 130 front 24's open point 8 (a failing render's `E`), 131 its open
point 7 and 24-d (no migration routine), 132 and 133 the formatter's 16-d and 16-c, 134 and 135 front
24's two documentation boxes, 136 24-e reversed (`try` / `await` only where an expression begins), 137 the empty record
(`type X()`), 138 0405-a reversed (a negative index counts from the end). The next free number is **139**.

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
> **Measured.** The prelude's async wrapper had `map` / `flatMap` / `await`; decision 120 says "`.map`,
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
> **Measured.** Before front 24, `std/async` had a thunk surface (`allOf`, `settleOf`, `raceOf`,
> `timeout` over thunks of the old fallible wrapper) and a started surface (`all`, `allSettled`, `race`),
> both built on a rejected task being the failure. The guide writes
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

## Track D (`05-emilia`) — choices made in implementation, to confirm

Each was implemented with the recommended option on `front/05-emilia`; a different answer is a
local change in the named front.

### 05emilia-a. The filter reader is an inline chain, not `var(--tw-filter)` (front 42)

> **Raised by:** `42-emilia-filters` step 4, 2026-09-26
> **Measured.** The spec's reader `filter:var(--tw-filter)` needs `--tw-filter` defined somewhere.
> `extendTheme` panics on a name in none of `Ns`'s nineteen prefixes, and `--tw-` is in none
> (front 45 met the same wall). Even as a `:root` rule it would not compose: a custom property's
> `var()`s are substituted on the element that declares it, so `:root`'s `--tw-filter` would read
> `:root`'s (unset) families and every element would inherit that empty result. Upstream v4
> (`utilities.ts`, `cssFilterValue`) writes the chain into every utility:
> `filter: var(--tw-blur, ) var(--tw-brightness, ) … var(--tw-drop-shadow, )`.
> **Options.** (a) Inline upstream's chain, spelled once by `filterChain()` / `backdropFilterChain()`.
> (b) Add a `Tw` namespace to `Ns` so `--tw-filter` is a theme entry — it still would not compose.
> **Recommendation.** (a) — implemented, emilia `5711732`; the step-4 box is marked superseded.

### 05emilia-b. The backdrop section is `BackdropFilter`, not `Backdrop` (front 42)

> **Raised by:** `42-emilia-filters` step 3, 2026-09-26
> **Measured.** `Backdrop(inner: Token[])` is front 34's `::backdrop` modifier, a top-level payload
> variant; a section head of the same name is the collision emilia's `AGENTS.md` records as silently
> breaking the variant's payload projection.
> **Options.** (a) `BackdropFilter` (upstream's property name). (b) Rename front 34's modifier.
> **Recommendation.** (a) — implemented; `BackdropRaw` keeps the spec's name.

### 05emilia-c. `drop-shadow-none` follows upstream (front 42)

> **Raised by:** `42-emilia-filters` step 2, 2026-09-26
> **Measured.** `TAILWIND_CSS_DOCS.md § 13.1` prints `filter: drop-shadow(none)`, which is not valid
> CSS (`drop-shadow()` takes a shadow). Upstream's `staticUtility('drop-shadow-none')` writes
> `--tw-drop-shadow: ` and the reader.
> **Options.** (a) Upstream's form. (b) The reference's string.
> **Recommendation.** (a) — implemented, the reference form asserted absent. `blur-none` keeps the
> reference's `filter:none`, which is valid CSS.

### 05emilia-d. The snap strictness default is a fallback, not a theme entry (front 46)

> **Raised by:** `46-emilia-interactivity` step 6, 2026-09-26
> **Measured.** The step asks front 54's theme to carry `--tw-scroll-snap-strictness`; `extendTheme`
> refuses any `--tw-` name (05emilia-a). Upstream registers the variable with `@property` and the
> initial value `proximity`.
> **Options.** (a) `scroll-snap-type:x var(--tw-scroll-snap-strictness, proximity)` — front 39's
> `cssVarOr`. (b) A `Tw` namespace in `Ns`.
> **Recommendation.** (a) — implemented, emilia `7004c96`: a lone `Snap.Type.X` snaps by proximity,
> a `Snap.Strictness` token in the same class overrides it.

### 05emilia-e. `fullTheme()` rides on `fullOptions()`, not `defaultOptions()` (front 56, decision 80)

> **Raised by:** `56-emilia-cascade-and-output`, decision 80, 2026-09-26
> **Measured.** Decision 80 says `defaultOptions()` carries `fullTheme()`. `defaultOptions()` is in
> `output.bp`; `fullTheme()` composes entries functions that live in `emilia.bp`, and `emilia.bp`
> imports `output.bp` — the reverse import is a module cycle.
> **Options.** (a) `fullOptions()` in `emilia.bp` = `withTheme(defaultOptions(), fullTheme())`, and
> `flush()` renders with it; `defaultOptions()` stays the palette-free baseline. (b) Move every
> front's entries function into `theme.bp` — five fronts' data in front 54's file.
> **Recommendation.** (a) — implemented, emilia `bd53968`; a test fails on any undefined `var(--…)`
> in a flushed document, with `defaultTheme()` as the control that must leave some undefined.

### 05emilia-f. `--inset-shadow-*` entries drop upstream's leading `inset` (front 41)

> **Raised by:** `56-emilia-cascade-and-output` (`fullTheme`), 2026-09-26
> **Measured.** Front 41 emits the reference's `box-shadow:inset var(--inset-shadow-xs)`; upstream's
> `theme.css` values already start with `inset`, so the pair would render `inset inset …` — not CSS.
> **Options.** (a) Entries without the keyword (`effectEntries()`). (b) Upstream's values, and front
> 41 emits `box-shadow:var(--inset-shadow-*)` — moves a landed front's pinned output.
> **Recommendation.** (a) — implemented; the rendered shadow equals upstream's.

### 05emilia-g. `space-*` / `divide-*` against upstream (fronts 35, 40)

> **Raised by:** the track-D audit, front 35 step 4, 2026-09-26
> **Measured.** Upstream `utilities.ts` writes `space-x-*` as `:where(& > :not(:last-child))` with
> `--tw-space-x-reverse:0` and both logical margins read through it; emilia writes
> `& > :not(:last-child)` (higher specificity) and the end margin only, so `Space.XReverse` sets a
> variable nothing reads. `divide-*` calls the same `siblingSelector()`.
> **Options.** (a) Align both fronts to upstream in one change (selector, reverse-aware margins).
> (b) Keep emilia's form and document it.
> **Recommendation.** (a) — implemented later in the same pass, emilia `15465ed`: both fronts'
> pinned output and the two examples that assert a spaced or divided list moved together.

### 05emilia-h. Sibling modules never import `from "emilia"`; `named()` lives in `emilia.bp` (fronts 55, 57, 58, 59)

> **Raised by:** `59-emilia-custom-utilities-and-variants` step 5, 2026-09-26
> **Measured.** A sibling module importing `from "emilia"` (the default module `emilia.bp`) passes
> `botopink test` in `modules/emilia/` and fails in every consumer: `unbound variable 'flushWith'`
> in `emilia/preflight.bp` when `examples/emilia-cascade` compiles emilia as a dependency. Front 59's
> step 5 wants `emilia.bp` untouched, but `named()` needs the host cell, and a host cell cannot be
> imported across modules either.
> **Options.** (a) Siblings import `tokens`/`theme`/`output`/each other only; `named()` and the
> read-only `lookupRule` cell live in `emilia.bp`, and each front's rendering tests sit under its
> banner there. (b) Fix the resolver first (a compiler change — not this track's).
> **Recommendation.** (a) — implemented, emilia `76da9fb`; the resolver defect is a compiler finding.

## `libs-external-methods` (host functions as methods of their owner) — choices made in implementation, to confirm

Implemented on `front/libs-external-methods` (worktree `.tasks/libs-external-methods`, 2026-09-26),
compiler `3630b648` + `612280ac`, std `8086c7ea`.

### lem-a · A host method is a real method whose body is the binding, never inlined at the call site

> **Measured.** At `f011850c` a `declare fn` with `#[@External.*]` inside a `type` body parsed and
> checked, and no backend emitted it (erlang `undef`, commonJS `… is not a function`, beam panicked
> in `lowerIdentAccess`, wasm wrote an invalid module).
> **Options.** (a) every backend emits the method as a function of the type (class member, exported
> function of the type's module) whose body is the binding over its own parameters — the wrapper a
> `pub` module-level `declare fn` already gets — so `sock.recv(n)` stays an ordinary method call and
> a method on an imported type is answered by its owner (decision 21) with no new call-site path —
> **implemented** (`codegen/hostMethods.zig`); (b) additionally render the binding inline at a call
> site in the owning module, as a module-level template is.
> **Recommendation.** (a): one lowering, one frame more per call. (b) is an optimisation with a
> second path to keep in agreement on four backends.

### lem-b · `inline = true` on a method's `External.Erlang` / `External.Beam` changes nothing

> **Measured.** `inline` opts a PRIMITIVE behavior's method out of the dispatch table so a
> hand-coded shape keeps emitting; a user type has neither the table nor a hand-coded shape.
> **Options.** (a) accept it (the checker's `refuseUnreadInline` rules still apply) and lower the
> method the same way — **implemented**, pinned by `run/external_method_local`'s `times`; (b) refuse
> it on a type-body method as a switch nothing reads (decision 67's reading of front 20 F9).
> **Recommendation.** (b) is the restrictive reading and is `01-checker`'s to add; (a) until then.

### lem-c · A method with no binding is refused where it is CALLED; wasm refuses every host method

> **Measured.** A module-level host function is refused at its call site (06 C13); a type is
> declared once and may be compiled for a backend its method has no binding for.
> **Options.** (a) the method is not emitted and a call through a receiver inference typed
> (`InstanceLowering.type_`) is refused with `MissingExternal` naming `Type.method` —
> **implemented** (`hostMethods.missingAt`, `CrossModule.host_methods`); (b) refuse the
> declaration itself on that backend. On wasm (a) refuses even an `External.Wasm` binding, where a
> module-level one lowers to `unreachable`; the index is keyed by the TYPE NAME, so two modules
> declaring one `Type.method` keep the first walked.
> **Recommendation.** (a); the wasm asymmetry resolves the day wasm has a host (both then refuse
> or both lower). An untyped receiver (no `.type_` lowering) is not refused and fails at run time as
> any unknown method does.

### lem-d · The names the collapse chose

> **Measured.** `io.net` had one free function per type and operation; `regex` had
> `runCompiled(r, input)` because `matches(pattern, input)` held the name.
> **Options.** (a) one name per operation on every type — `Listener.port/accept/close`,
> `Socket.recv/send/close/peer`, `TlsListener.port/accept`, `TlsSocket.recv/send/close`,
> `Regex.matches` — **implemented**; (b) keep the old names as methods (`l.listenerPort()`,
> `r.runCompiled(s)`).
> **Recommendation.** (a): the prefixes named the owner, which the receiver now does. Constructors
> (`listen`, `connect`, `tlsListen`, `tlsConnect`, `regex.compile`) stay module functions.

### lem-e · What stayed free although it takes a type

> **Measured.** `io.net`'s private `tlsEchoOnce(listener, length)` (a test instrument); `validation`'s
> private `rkvPush(v: Violation)`, `putMessageSource(source)` and `messageSourceOr(fallback)` (a
> process-global store, not an operation on the value); every other std host function takes
> primitives, `any` host terms or builtin types (`@Task`), and `routing` / `actions` declare none.
> **Options.** (a) keep them free — **implemented**: a method is exported from its type's module on
> erlang and beam, so a private helper would join the type's public surface; (b) move them too.
> **Recommendation.** (a).

### lem-f · commonJS adopts a host-built record into its class

> **Measured.** A host answer declared as a record stayed a plain object on commonJS — fields read,
> methods absent (`regex.compile(p).map({ r -> r.matches(s) })`: `r.matches is not a function`),
> printed as `%O`. erlang has adopted maps since decision 21 (`adoptHostResult`).
> **Options.** (a) `__bp_adopt(v, C, path)` gives the answer the class's prototype — directly,
> through `?T`, an array, an `@Result`'s ok side — at the owner's call site, in the exported
> template wrapper and in a host method's body — **implemented** (compiler `612280ac`, pinned by
> `run/external_method_on_host_record`); `@Task` is not looked through, and a `(module, symbol)`
> alias another module imports bypasses it; (b) require templates to build the class
> (`new Regex(…)`).
> **Recommendation.** (a): (b) makes a template name an emitted class, and `docs.md` already
> promised the adoption on every backend. beam still adopts no host map (`external_host_record`'s
> `.targets`) — a `03-beam` row.
