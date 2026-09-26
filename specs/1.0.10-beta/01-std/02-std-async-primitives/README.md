# Front 02 — Std Async Primitives

**Track:** A std
**Priority:** high — a server-rendered page that issues three reads one after another is three round
trips deep before it renders its first byte
**Target:** both — std is the floor under both halves
**Owns:** `src/async.bp` — at the pure root (decision 106): combinators over `@Task`, no I/O of its own
**Does not touch:** every other std module, including `io/http.bp` — this front adds combinators over
`@Task`, it does not change what produces one
**Reference:** `NEXTJS-DOCS.md § 9. Busca de Dados (Fetching)` · [Fetching Data — parallel](https://nextjs.org/docs/app/getting-started/fetching-data) · [`Promise.all`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all) · [Erlang processes](https://www.erlang.org/doc/system/ref_man_processes.html) · decisions 120 and 121 (a Task never fails) · `decisions-pending.md` 24-g (the module's shape)

---

## Problem

`await` waits for one thing. A server component that needs the user, their posts and the site-wide
stats writes three `await`s and pays for all three serially — the shape Next.js documents as the
thing not to do.

`@Task<T>` **lowers eagerly on the erlang backend**: a `-> @Task` fn is a plain function, `await` is
identity, and a Task is a value that has already run (`codegen/erlang.zig`, the `@Task — eager
lowering` arm; `io/http.bp` says the same for `http.fetch`). By the time an `Array<@Task<T>>` reaches
a combinator on erlang, every element has already run, in list order, serially. A surface over
started Tasks therefore buys no concurrency on erlang — the target every server front compiles for —
so the module also takes **unstarted tasks**.

## The module

`src/async.bp`, `import {async} from "std";`. A Task never fails (decision 120): a fallible operation
is `@Task<@Result<T, E>>`, `await` answers the `@Result`, and `try await` propagates it.

```bp
// instruments
pub declare fn delay<T>(millis: i32, value: T) -> @Task<T>
pub fn failed<T>(message: string) -> @Task<@Result<T, string>>
pub fn errorText<T>(settled: @Result<T, string>) -> string          // the Error side, "" for Ok

// started tasks — concurrent on commonJS, already run on erlang
pub fn allOf<T, E>(tasks: Array<@Task<@Result<T, E>>>) -> @Task<@Result<Array<T>, E>>
pub fn all<T>(tasks: Array<@Task<T>>) -> @Task<Array<T>>
pub declare fn race<T>(tasks: Array<@Task<T>>) -> @Task<T>

// unstarted tasks — concurrent on both targets
pub fn runAll<T>(tasks: Array<fn() -> @Task<T>>) -> @Task<Array<T>>
pub declare fn raceOf<T>(tasks: Array<fn() -> @Task<T>>) -> @Task<T>
pub fn timeout<T>(task: fn() -> @Task<T>, millis: i32) -> @Task<@Result<T, string>>
```

**Started tasks — `allOf`, `all`, `race`** take `Array<@Task<…>>`, the shape a caller writes
(`async.allOf([fetchUser(1), fetchUser(2)])`). On commonJS each Task is a live Promise and the call
only waits. On erlang the module is honest rather than concurrent: `allOf` / `all` read values in
order and `race` answers **element zero** rather than the fastest. No server front may depend on
`race`'s timing. `allOf` answers the values in input order or the **first** `Error` in input order;
`allOf([])` answers `Ok([])`.

**Unstarted tasks — `runAll`, `raceOf`, `timeout`** take `fn() -> @Task<T>` thunks. Nothing has run
when the combinator receives them, so the erlang cell `spawn`s one process per task and gathers the
replies by index, and the commonJS cell calls each thunk into `Promise.all` / `Promise.race` — real
concurrency on both targets. `runAll` answers values in input order; over `@Task<@Result<…>>` thunks
each slot holds its task's own `@Result`, so `runAll` of fallible tasks is the settled view. Every
erlang reply is tagged with a `make_ref()` unique to the call, so an expired `timeout` task or a
`raceOf` loser that answers later cannot land in a later combinator's gather in the same process.
A task that crashes is re-raised, not left to block the gather.

**`timeout(task, millis)`** answers `Ok(value)` inside the budget and `Error("timeout")` past it,
expressed over `raceOf` and `delay`. A task over a `@Result` keeps its own failure inside the `Ok`
(`Ok(Error(e))`): the budget and the task's outcome are two answers and neither hides the other.
There is no fallback parameter — the caller's `unwrapOr` is the fallback.

**No cancellation.** `raceOf`'s losers and `timeout`'s expired task keep running to completion.

**`race([])` and `raceOf([])`** are programming errors, fatal on both targets
(`async.race: empty task list`, `async.raceOf: empty task list`) rather than blocking forever.

Everything host-side is a `declare fn` with one cell per target, in the `io/fs.bp` shape; there is no
sidecar. A root module may not import from `io/`, so the module keeps its own private monotonic-clock
cell for its tests.

## Examples

- [`examples/parallel-fetch-example.bp`](./examples/parallel-fetch-example.bp) — a server-rendered
  dashboard that issues three reads together, renders without the optional widgets when they are
  down, and puts a budget on a slow dependency.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No array destructuring in a binding — `val [a, b, c] = xs;` does not parse | every `allOf`/`runAll` call site reading its results | `val a = xs.at(0).unwrapOr(…);` per element | destructuring patterns in `val`/`var` bindings, at least for arrays and tuples |
| `@Task<T>` lowers eagerly on the erlang backend | the started surface — `all` is a map, `race` is element zero | take unstarted `fn() -> @Task<T>` thunks and `spawn` them in the host cell | a lazy `@Task` lowering on erlang, or a `@Task<T>` type that is explicitly unstarted on both targets |
| No cancellation | `raceOf`'s losers and `timeout`'s expired task keep running | leave them running and document it | a cancellation token threaded through a `@Task` body, or `@Task.cancel` |

## Test plan

Inline `test` blocks at the foot of `src/async.bp`, run by `botopink test --target commonJS` and
`--target erlang` from `libs/std/`, and by `zig build test-libs`. `await` works directly inside a
`test` block. Three kinds of assertion:

- **Results and order** — `allOf`, `all` and `runAll` answer input order, not completion order;
  `allOf` stops at the first error in input order; `runAll` of fallible tasks keeps each `@Result`
  in its slot. Deterministic on both targets.
- **Elapsed time** — `runAll` of three delayed tasks completes in roughly the longest one's time.
  The only assertion that can tell concurrency from a sequential map; the budget is about double
  the longest task.
- **Documented divergence** — `race` is asserted as fastest-wins on commonJS and element zero on
  erlang, so a backend change that makes erlang lazy reds a test and forces the docblock to change.

`async` is not snapshotted (`../test-snap.md`): an elapsed-time budget is a `<`, never a literal.

## Delivered

The front's steps (`delay` and the skeleton, the started surface, the unstarted surface, `timeout`,
the export line) hold, re-spelled over `@Task` by front 24 step E7; `allSettled` and `settleOf` left
with 24-g — a Task has no failure to settle, and a `@Result` element is the settled outcome. The
inline tests name each behaviour: `delay` answers its value, takes at least the requested time and
binds `T` to a record as well as to a string; `failed` answers an `Error` value and does not reject;
`allOf` answers input order, stops at the first error and answers no values for no tasks; `all`
answers input order; `race` is fastest on commonJS and element zero on erlang; `runAll` answers
input order, runs concurrently and keeps a fallible task's `@Result` in its slot; `raceOf` answers
the fastest task and drops a loser's answer; `timeout` answers `Ok` inside the budget, `Error
timeout` past it, and an expired task cannot corrupt a later answer.

## Definition of done

- `src/async.bp` exists with both surfaces, and the module docblock states the erlang divergence at
  the top rather than in a footnote.
- The unstarted surface is demonstrably concurrent on both targets by an elapsed-time assertion.
- No server front in this milestone is left depending on the started surface's `race`.
- `pub mod async;` appears in `src/root.bp`; `libs/std/AGENTS.md` names `async.bp`.
- Every `// LANGUAGE GAP:` marker in the example appears in the table above.
- The front's tests are green on both targets.
