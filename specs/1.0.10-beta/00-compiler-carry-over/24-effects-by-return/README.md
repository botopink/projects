# Front 24 — effects by return type: `@Task`, `@Iterator` / `@Stream`, `async { }`, `iter` / `stream`

**Track:** compiler (carry-over item **C-32**)
**Priority:** critical — every effectful body in the compiler, std and the five libraries is written
against this surface.
**Depends on:** decisions [118–128](../../decisions-taken.md#118-the-return-type-is-the-annotation),
amended by [130](../../decisions-taken.md#130-a-failing-render-carries-e--string-the-writers-stay-infallible)
and [131](../../decisions-taken.md#131-no-migration-routine-for-the-effect-change);
[`22-loops`](../22-loops/README.md) (landed).
**Owns:** `libs/std/src/builtins.d.bp` (the effect behaviors) · `ast.zig`'s `EffectKind`, the
`AsyncBlock` node and the prefixed loop (`LoopExpr.generator` / `prefixedKeyword`) ·
`comptime/effect_chain.zig` · `parser/decls.zig`'s refusal of the removed annotations ·
`parser/exprs.zig`'s `async`, `iter`, `stream` prefixes and the `try` / `await` arms ·
`parser/types.zig`'s refusal of the removed wrappers · `comptime/infer.zig`'s effect legality, the
`return` rule, `await` typing, the iterator/factory scan, the loop's generator typing and the `use`
gate · `comptime/diagnostics.zig`'s effect codes · the effect lowering of
`codegen/{commonJS,erlang,beam_asm,wat}.zig` and the name mapping of `codegen/typescript.zig` · the
`async` / `iter` / `stream` printer arms in `format.zig` (a carve-out of
[`16-formatter`](../16-formatter/README.md)) · `docs.md` § Loops, § use, § Effects, § Results,
§ Iterators, § Host bindings and § *Migrating from the effect annotations* · the `tests/language`
effect, generator and loop cells.
**Does not touch:** `lexer.zig` (the three words are contextual, decided in the parser) · the loop
keywords, statements `void`, ranges and labels (22) · `parseImportItem`, `project_graph.zig`,
`libs/std/src/**` beyond `builtins.d.bp`, `async.bp` and `http.bp`
([`23-std-purity`](../23-std-purity/README.md)) · `decisions-*.md` · the language server and
`repository/vscode-extension` (`11-tooling`).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise. The language is written out in full in [`guide.md`](./guide.md); `docs.md` carries the
same text. The decisions are the contract; the guide is the prose and the examples.

---

## The surface

The effect of a function is its return type, written literally. **Only `@Result` fails**: the other
wrappers never fail and carry a `@Result` in the value when they need one.

| Return | The body may write |
|---|---|
| `@Result<T, E>` | `throw` · `try` |
| `@Task<T>` | `await` (and `throw` / `try` when `T` is a `@Result`) |
| `@Component<C, T>` | `use` · `await` (and `throw` / `try` when `T` is a `@Result`) — a hook (any `T`) or a component (`T` implements `@Context<C>`) |
| `@Iterator<T>` | `yield` · `break v` — `for` iterates it in any function |
| `@Stream<T>` | `yield` · `break v` · `await` — `for await` iterates it where there is an await channel |
| — | `async { … }` → `@Task<T>` (or `@Task<@Result<U, E>>` when the block throws or tries) |
| — | `iter loop` / `iter while` / `iter for` → `@Iterator<T>`; `stream loop` / `stream while` / `stream for` → `@Stream<T>` |

- **The level and the fallible channel are two answers.** The level (`use` / `await` / `yield`) comes
  from the outermost wrapper and the chain `@Component ⊃ @Task`, `@Stream ⊃ @Task`, `@Iterator`; the
  fallible channel is "a `@Result` in some layer of the return". `throw` / `try` read only the second.
- **An alias types but does not activate** (`effect-wrapper-behind-alias`).
- **`return`** wraps a plain value through every layer and passes a wrapper-typed one through; a
  `return` that fits two layers is `effect-return-ambiguous-nesting` (decision 119).
- **`await t`** answers the Task's value — a `@Result` when there is one; `try await t` propagates
  (decision 120).
- **Iterator or factory** (decision 123): a body with its own `yield` / `break v` is an iterator; one
  without is a factory that returns an iterator; mixing is `iter-mixed-yield-return`.
- **`for`** hands over the item as is — a `@Result` item needs `try r` or a `case` (decision 122).
- **Closed scopes:** `async { }`, `iter …` and `stream …` start a new capability context, like a
  closure; `return` inside `async { }` leaves the block.

`builtins.d.bp`:

```botopink
pub behavior Context<Base> {}

pub type Result<R, E> { … }
pub behavior Task<T> {
    fn map<R>(self: Self, transform: fn(value: T) -> R) -> Task<R>;
    fn then<R>(self: Self, next: fn(value: T) -> Task<R>) -> Task<R>;
}
pub behavior Component<C, T> extends Task {}

pub type YieldStep<T> { Yield(value: T), Done }
pub behavior Iterator<T>                { fn next(self: Self) -> YieldStep<T>; }
pub behavior Stream<T> extends Task     { fn next(self: Self) -> Task<YieldStep<T>>; }
```

**Backends:**

| Construct | commonJS | erlang / beam / wasm |
|---|---|---|
| `@Result` return | tagged value | tagged value |
| `@Task` / `@Component` return | `async function` | eager Task, `await` = identity |
| `throw` in `@Task<@Result<…>>` | `return {Error: e}` — the Promise resolves, never rejects | answers `Error(e)` |
| `async { }` | `(async () => { … })()` | runs the block in place |
| `@Iterator` with `yield` | `function*` | the generator representation |
| `@Stream` with `yield` | `async function*` | the stream representation |
| factory (`@Iterator` / `@Stream` with no `yield`) | plain function | plain function |
| `iter …` / `stream …` | `(function* () { … })()` / `(async function* () { … })()` | the function's lowering, inline |
| failing `throw` / `try` on a `@Result` item | `yield {Error: e}; return;` | emit `Error(e)` and end |
| `@External` → `@Task<@Result<…>>` | `try { await p } catch (e) { return {Error: …} }` | `{error, R}` → `Error(R)` |
| `@External` → `@Task<T>` | `await p`; a rejection is a fatal failure | as a plain call |

TypeScript: `@Task` → `Promise`, `@Iterator` → `IterableIterator`, `@Stream` → `AsyncGenerator`.

**The removed forms** — the effect annotations, the old wrapper names and `@Iterator<T, E>` — are
located compile errors with a fix-it (decision 127); the list is [`guide.md`](./guide.md) § 9 *Old
names that left*. There is no codemod and no mode that reads them (decision 131).

## Steps

Every step has landed; the open boxes are listed under *Open*.

### Step E1 — the prelude types

- [x] `builtins.d.bp` is the shape under *The surface*; only `Task`, `Component`, `Iterator`,
      `Stream`, `YieldStep` and `Context` are effect names in it
- [x] the prelude compiles on all backends (commonJS, erlang, beam, wasm)
- [x] the `effect_chain.zig` drift test green; `comptime/AGENTS.md` and `libs/std/AGENTS.md` current

### Step E2 — the parser

`async` before `{` → an `AsyncBlock`; `iter` / `stream` before `loop` / `while` / `for` / `for await`
→ the prefixed loop (`iter for (xs) { … }` is the prefixed `loop { for (xs) { … }; break; }`, the
written keyword kept for the formatter); the three words are contextual; `try await x` is
`try (await x)`; `try` and `await` are operands (`total + try r`, `yield try x`); the removed
annotations and wrappers are recognised only to be refused, located.

- [x] every form in [`guide.md`](./guide.md) parses, with `parser/tests/` cases and lossless
      round-trips (`parser/tests/effect_rejections.zig`, `parser/tests/surface.zig`,
      `format/tests/expressions.zig`)
- [x] every removed form raises its code with the fix-it on the annotation / type argument — the
      `reject/` cells of § *Cells*
- [x] `g.iter()`, `val stream = 1`, `http.stream(…)`, `import {async} from "std"` and
      `async.allOf(…)` stay identifiers (`test/contextual_words.bp`, `run/async_block_all_of.bp`)
- [x] `src/parser/AGENTS.md`, `src/format/AGENTS.md` current

### Step E3 — types and effects

The effect mode from the return (118); the fallible channel apart from the level (121); `return`
(119); `await` (120); iterator or factory (123); the inferred `@Result` of `async { }`, `iter` and
`stream` (`gen-infer-conflicting-errors`); the closed scopes; `for` over any `@Iterator` legal in any
function; the hint on the type error when a `@Result` is used as `U` (from an `await` → `try await`,
from a `for` item → `try r`, from an inferred value → the `try` / `throw` that made it one).

- [ ] every ✗ in [`guide.md`](./guide.md) answers exactly the code of § *Diagnostics*, and every
      example without ✗ types — see *Open*
- [x] the *Return and effect mode*, *`@Task` and failure*, *Chain and `use`*, *`async { }`*,
      *Iterators* and *Prefixed loops* cells green on four targets (`run/async_block_all_of` runs on
      commonJS and erlang only — `std/async` has no wasm / beam host)
- [x] the hint in a `reject/` cell's `.expect` for each of the three sources
- [x] `comptime/AGENTS.md` current

### Step E4 — consumption (`for` / `for await`)

- [x] `for` with `try r` propagates, `for` with `case` continues (`run/iterator_result_items.bp`)
- [x] `for await` without an await channel is `effect-await-without-task`
      (`reject/for_await_without_task.bp`)

### Step E5 — the backends

- [x] the *Iterators*, *Streams*, *Host* and *`@Task` and failure* run cells green on four targets by
      running (the host cells and `run/task_throw_resolves_error` are one-host claims, `.targets`
      commonJS / erlang)
- [x] JS: a `throw` in `@Task<@Result<…>>` resolves the Promise with `Error`, never rejects
      (`run/task_throw_resolves_error.bp`, node)
- [x] `CHANGELOG.md` § v1.0.10-beta *2. JavaScript interop*; `codegen/AGENTS.md`'s `-> @Task<T>` and
      host rows

### Step E7 — the libraries

`std/async`: started Tasks — `allOf(Array<@Task<@Result<T, E>>>) -> @Task<@Result<Array<T>, E>>`
(stops at the first `Error`), `all(Array<@Task<T>>) -> @Task<Array<T>>`, `race`; thunks — `runAll`,
`raceOf`, `timeout(thunk, millis) -> @Task<@Result<T, string>>` answering `Error("timeout")`
(decisions-pending 24-g). `io.http.fetch -> @Task<@Result<Response, string>>`. jhonstart, rakun,
emilia, onze and erika are written in the surface.

- [x] `std/async` and `std/http` signatures closed
- [x] `zig build test-libs` green on every row; `scripts/known-red-libs.txt` at its header
- [x] no library under `repository/{jhonstart,rakun,emilia,onze,erika}` or `libs/` spells a removed
      annotation or wrapper

### Step E8 — documentation

- [x] `scripts/check-docs.sh` green; every `docs.md` fence compiles (`zig build test-docs`)
- [x] no front README keeps a "written in the pre-118 model" line
- [x] the removed spellings appear in `specs/1.0.10-beta` only in the record and the removed-names
      table (decision 135):
      `grep -rlE '#\[@(result|future|use|generator|resultGenerator|futureGenerator)\]|@(Future|Use)<|@(Result|Future)Generator' specs/1.0.10-beta --include=*.md --include=*.bp`
      → `specs/1.0.10-beta/00-compiler-carry-over/24-effects-by-return/guide.md` (lines 770–780, § 9
      *Old names that left*, only) and `specs/1.0.10-beta/decisions-taken.md`

## Diagnostics

| Code | When | Fix-it |
|---|---|---|
| `effect-try-without-fallible-channel` | `throw` / `try` with no `@Result` in any layer of the return | `try … catch`, or a `@Result` in the return |
| `effect-await-without-task` | `await` / `for await` without an await channel | a `@Task` return, or `async { }` |
| `use-without-context-effect` | `use` without a `@Component` return | change the return |
| `effect-wrapper-behind-alias` | a capability used under an aliased return | write the wrapper literally |
| `effect-return-ambiguous-nesting` | a `return` that fits two layers | explicit `Ok(…)` |
| `iter-await` | `await` in an `@Iterator` or an `iter …` loop | `@Stream` / `stream …` |
| `iter-mixed-yield-return` | `yield` and `return <iterator>` in one body | pick one |
| `gen-infer-conflicting-errors` | two `E`s in the body of `async { }` / `iter` / `stream` | annotate the `val` |
| `effect-annotation-removed` | a removed effect annotation (guide § 9) | remove it (on a loop: `iter` / `stream`) |
| `effect-type-removed` | a removed wrapper name (guide § 9) | the new name |
| `iterator-error-param-removed` | `@Iterator` with a second type argument | `@Iterator<@Result<T, E>>` |

The rest of the effect codes are in decisions-pending 24-a (`effect-wrapper-mismatch`,
`yield-without-generator`, `generator-loop-closed-scope`, `for-over-stream`,
`for-await-expects-stream`).

## Cells

Each line is a compile cell (✓ types / ✗ the expected code) in `tests/language/{test,reject}/` and,
where it runs, a `run/` cell on the four targets.

**Return and effect mode**
- [x] ✓ `@Result` with `throw`, `try`, `return T`, `return @Result` — `test/effect_return_result`
- [x] ✓ `@Task<@Result<U, E>>`: `return U`, `return @Result`, `return @Task<…>` — `run/task_return_layers`
- [x] ✗ `effect-return-ambiguous-nesting` with `@Result<@Result<…>>` — `reject/effect_return_ambiguous_nesting`
- [x] ✗ `effect-wrapper-behind-alias` — `reject/effect_wrapper_behind_alias`
- [x] ✓ an alias on a function **without** capabilities — `run/effect_alias_passes_value`

**`@Task` and failure**
- [x] ✓ `@Task<T>` with `await` and no `try` — `run/task_await_no_try`
- [x] ✗ `throw` in `@Task<i32>` — `reject/task_throw_without_result`
- [x] ✓ `await t` answers the `@Result`; `try await t` propagates; `try await t catch x` — `run/task_await_result`
- [x] ✗ `try await` in a `@Task<i32>` function — `reject/task_try_await_without_result`
- [x] ✓ JS: a `throw` in `@Task<@Result<…>>` resolves the Promise with `Error` — `run/task_throw_resolves_error` (`.targets commonJS`)

**Chain and `use`**
- [x] ✓ `@Component<C, T>` with `use` + `await`, as a hook and as a component — `run/component_hook_and_component`
- [x] ✓ `@Component<C, @Result<T, E>>` with `try await` — `run/component_result_try_await`
- [x] ✗ `try` in `@Component<ElementBase, Element>` — `reject/component_try_element`
- [x] ✗ `await` under `@Result`; `use` under `@Task`; two bases in one `@Component`; `use` of a component — `reject/await_under_result`, `reject/use_under_task`, `reject/component_two_bases`, `reject/use_of_component`

**`async { }`**
- [x] ✓ in a plain function, passed to `async.allOf` — `run/async_block_all_of` (`.targets commonJS erlang`)
- [x] ✓ without `throw` / `try` → `@Task<T>`; with → `@Task<@Result<U, E>>` — `run/async_block_value_type`
- [x] ✓ `return` leaves the block, not the function — `run/async_block_return`
- [x] ✗ `use` inside `async { }` in a `@Component` function — `reject/async_block_use`
- [x] ✗ `gen-infer-conflicting-errors` — `reject/async_block_conflicting_errors`

**Iterators**
- [x] ✓ `fibonacci`, `firstNegative` — `run/iterator_fibonacci`
- [x] ✓ `@Result` item: `yield try`, `throw` → the last item is `Error`, then `Done` — `run/iterator_result_item`, `run/prefixed_loop_result_item`
- [x] ✓ `for` with `try r` propagates; `for` with `case` continues — `run/iterator_result_items`
- [x] ✓ factory vs iterator — `run/iterator_factory`
- [x] ✗ `throw` with an item that is not a `@Result`; `iter-await`; `iter-mixed-yield-return`; `iterator-error-param-removed` — `reject/iterator_throw_without_result`, `reject/iter_await`, `reject/iter_mixed_yield_return`, `reject/iterator_error_param_removed`

**Streams**
- [x] ✓ `pages` + `for await`, a failure in the middle — `run/stream_pages`
- [x] ✓ `stream loop` with no failure → `@Stream<T>` — `run/stream_loop_no_failure`
- [x] ✗ `for await` without an await channel — `reject/for_await_without_task`

**Prefixed loops**
- [x] ✓ `iter loop` / `iter while` / `iter for` as a `val` and as an argument — `run/prefixed_loop_forms`
- [x] ✓ `break v` ends the sequence — `run/prefixed_loop_break_value`
- [x] ✓ `yield` in an inner `for` feeds the outer `iter`; `yield :label` — `run/prefixed_loop_nearest_scope`
- [x] ✗ `break :outer` crossing the border — `reject/prefixed_loop_break_outer`
- [x] ✓ the contextual words stay identifiers — `test/contextual_words`, `run/async_block_all_of`

**Host**
- [x] ✓ `@External.Node` with `-> @Task<@Result<T, string>>`: a rejected Promise becomes `Error` — `run/host_node_task_result` (`.targets commonJS`)
- [x] ✓ `@External.Erlang` with `{error, R}` becomes `Error(R)` — `run/host_erlang_task_result` (`.targets erlang`)

**Removed forms**
- [x] ✗ each removed annotation gives `effect-annotation-removed` with its fix-it — `reject/effect_annotation_removed_*` (nine cells, three on loops)
- [x] ✗ a removed wrapper name gives `effect-type-removed` with the new name — `reject/effect_type_removed_future`, `…_future_no_error`, `reject/effect_type_removed_use`
- [x] ✗ `@Component<T>` with one argument is a type-arity error — `reject/component_one_type_argument` (`generic-required-arg-missing`)

## Gate

- [x] `zig build test` green; `zig build test-language` green on the four targets with § *Cells*, no
      § *Cells* line in `expected-failures.txt`
- [x] the `effect_chain.zig` drift test green with `builtins.d.bp` at its final shape
- [x] `test-cli`, `test-docs` green
- [ ] `AGENTS.md` of every directory touched, in the same commit as each change — see *Open*

## Open

- **Guide fences (E3, decision 134).** The guide's slips are fixed and compiled fence by fence
  (one program per fence, `botopink check`, jhonstart as a path dependency): 21 ✓ fences type, 16 ✗
  sites answer their code located — `#[layout] … -> Element` answers jhonstart's decision-117
  refusal (`routes.bp`, pinned by jhonstart's `refusals/` projects). Three fences wait for
  `00 · 01-checker`: `try x catch null` into a `?U` (§ 4.2 `currentUser`, § 4.3 `PostPage`, § 7), a
  `null` check whose branch ends in a `noreturn` call (`redirect()`) narrowing what follows (§ 4.3
  `DashboardLayout`), and a component called inside a component's body answering its `T`
  (`Sidebar(…)` / `Counter()`, § 4.3). § 7's server action types against stubs only: rakun has no
  `serverAction` yet. The box ticks when the three type.
- **`AGENTS.md` per commit** (front 24 box 3, the maintainer's call). It holds at the tip; 10 of the
  front's 23 commits updated the nearest `AGENTS.md` in a later commit instead of the same one, and
  the history is not rewritten. The maintainer accepts or not.
- **The JS interop helper.** Whether an `unwrapOrThrow` (a resolved `Error` turned back into a
  rejection, for JavaScript callers) ships, and where — std or the JS runtime — is not decided.
- **Confirmations** in `decisions-pending.md`: 24-a (the effect codes), 24-b (`@Task`'s `map` /
  `then`), 24-c (a prefixed loop's label), 24-e (`try` / `await` as operands), 24-f (`test-libs` from
  a nested worktree), 24-g (`std/async`'s shape).

## Risks

- **Components have no propagation.** A page decides what to show for an error — `try … catch`, a
  `case`, `notFound()`; a library helper (`orNotFound(r)`, an error boundary per layout) is
  jhonstart's to offer.
- **JS interop.** botopink Promises resolve with `Error` on expected failures; JavaScript callers read
  the value (`CHANGELOG.md`).
- **The cost of a `@Result` per item** in large iterators: to measure on erlang and wasm; if it
  weighs, specialise the `Ok` `yield` in the backend.
- **Inference in blocks and loops.** A value silently promoted to `@Result` breaks at its use site;
  the message points at the `try` / `throw` that made it one (E3's hint).
