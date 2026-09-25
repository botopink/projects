# Decisions the maintainer owes — 1.0.10-beta

**None open.** Every question this milestone raised is answered in
[`decisions-taken.md`](./decisions-taken.md) — 91, 92, 93 and 97 by decisions 103 and 104, 99 by 108,
94, 100 and 101 by 113; every number up to 117 is answered — 114 answers the eight seams decision 113 left open, 115 the five points 114 left open, 116 nine more pieces two libraries both run, 117 the nine points 113–116 left, and 118–127 register the maintainer's effect revision (the return type is the annotation, `@Task<T>`, only `@Result` fails, `@Iterator<T>` / `@Stream<T>`, `async { }`, `iter` / `stream` loops, no compatibility mode — front `00 · 24-effects-by-return`), and 128 merges `@Use<C, T>` and `@Component<T>` into `@Component<C, T>`. The next free number is **129**.

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

> **Raised by:** the codemod thread (`front/24-codemod`, E6), 2026-09-25
> **Measured.** `botopink migrate effects` type-checks the OLD program to decide `await` → `try await`.
> At `86609a66` the parser refuses every removed annotation and wrapper (`effect-annotation-removed`,
> `effect-type-removed`) and stops — there is no AST for the old program, and the checker no longer
> knows `@Future` / `@ResultGenerator` / `@FutureGenerator`.
> **Options.** (a) the codemod runs from a binary built at `feat` before E2 (its own build of the old
> parser/checker, shipped only inside `migrate`); (b) a migration-only lenient mode in the parser
> (record the annotation / old wrapper, report the refusal as a diagnostic, keep parsing) and the old
> wrappers' typing reachable only from `migrate`; (c) the codemod rewrites textually and leaves
> `await` → `try await` to the E3.9 type-error hint.
> **Recommendation.** (a) — decision 67 wants no mode that accepts the old forms, and a mode reachable
> only through `migrate` is still a second grammar to maintain. Not implemented in this front: the
> refusal path stops at the first old form.
> **Blocks.** Merging `front/24-codemod` into `front/24-effects-by-return` (its tests type-check the old
> surface).

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
