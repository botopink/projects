# Decisions the maintainer owes — 1.0.10-beta

**Three open** — front 24's open points 7 and 8, and 129 (type-alias details), below; plus five `01-std` implementation choices to confirm (01std-a…e). Every other question this milestone raised is answered in
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
