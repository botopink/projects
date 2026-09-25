# Front 02 — Std Async Primitives

**Track:** A std
**Priority:** high — a server-rendered page that issues three reads one after another is three round
trips deep before it renders its first byte
**Target:** both — std is the floor under both halves
**Wave:** 0
**Depends on:** none
**Owns:** `src/async.bp` — at the pure root (decision 106): combinators over `@Future`, no I/O of its own
**Does not touch:** every other std module, including `io/http.bp` — this front adds combinators over
`@Future`, it does not change what produces one. `src/root.bp` belongs to front 01; this front hands
it the line `pub mod async;` and lands first. `00-compiler-carry-over/23-std-purity` moves nothing of
this front's.
**Reference:** `NEXTJS-DOCS.md § 9. Busca de Dados (Fetching)` · [Fetching Data — parallel](https://nextjs.org/docs/app/getting-started/fetching-data) · [`Promise.all`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all) · [`Promise.allSettled`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/allSettled) · [Erlang processes](https://www.erlang.org/doc/system/ref_man_processes.html)

---

## Problem

`await` in botopink waits for one thing. A server component that needs the user, their posts and the
site-wide stats writes three `await`s and pays for all three serially, which is the shape Next.js
documents as the thing not to do. There is no `all`, no `allSettled`, no `race`, no timeout and no
delay anywhere in std.

`@Future<T>` **lowers eagerly on the erlang backend** — `libs/std/src/http.bp:16-18`: "Erlang is
eager: `@Future<T>` resolves to `T` in the eager-lowering arm documented in `codegen/erlang.zig`, so
the caller's `await fetch(url)` is identity on that backend." By the time an `Array<@Future<T>>`
reaches an `all` on erlang, every element has already run, in list order, serially. `all` over it is
a map over finished values; `race` over it answers the first element rather than the fastest; a
timeout over it cannot fire. On erlang — the target every server front in this milestone compiles
for — a surface over started futures buys nothing. The primary surface therefore takes **unstarted
tasks**, not started futures.

## Current state

- **No `async.bp`.** `libs/std/src/root.bp:13-36` lists twenty-four modules and none of them is it.
- **`@Future<T>` exists and works.** `#[@future]` marks the function, `await` unwraps inside it
  (`docs.md:530`; real use at `repository/emilia/src/emilia.bp:62-65`), and `await` is legal directly
  inside a `test` block (`emilia.bp:475-480`).
- **The only std producer of a future is `http.fetch`** (`http.bp:55`). `emilia.flush()` is the only
  other one in the workspace.
- **Node keeps the Promise live across `await`** (`http.bp:41-43`), so the commonJS lowering has real
  concurrency available to it.
- **Erlang does not.** `http.bp:16-18`, quoted above. There is no `Task`, no `async/await`
  scheduler, and no cancellation surface anywhere in the language.

## Mechanism

Two surfaces, and the README is explicit about which one a server front may rely on.

**The task surface — `allOf`, `raceOf`, `settleOf` — takes `Array<fn() -> @Future<T>>`.** Because the
elements are unstarted, the erlang cell can start them: `spawn` one process per task, tag each by
index, gather the replies into the original order. That is real BEAM concurrency, it is what the
platform is good at, and it is what the server half of this milestone needs. The commonJS cell calls
each thunk and hands the resulting Promises to `Promise.all`. Same semantics, both targets, actually
concurrent on both.

**The future surface — `all`, `allSettled`, `race` — takes `Array<@Future<T>>`** and exists for
parity with the JavaScript the client half is written against. On commonJS it is `Promise.all` and
friends. On erlang it is honest rather than concurrent: `all` is the identity map, `allSettled` wraps
each already-resolved value in `Ok`, and `race` answers element zero. The module docblock says so and
the tests assert it, because a primitive whose guarantee silently differs by target is worse than one
that does not exist.

The split is not cosmetic: `race` on the future surface has no timing meaning on erlang and no server
front may depend on one. `raceOf` on the task surface does, because the tasks are unstarted when
`raceOf` receives them.

Two supporting functions round it out. `delay(millis, value)` is the test instrument — without a
future that takes a known amount of time, none of the combinators above can be tested for ordering.
`timeout(task, millis)` answers `@Result<T, string>` rather than failing, so a slow dependency
degrades a page instead of taking it down; it is built on `raceOf` over the task and a `delay`.

Everything here is a `declare fn` with one cell per target, in the `fs.bp` shape. There is no sidecar
`.mjs`: std ships exactly one (`src/sidecars/random.mjs`), for a case where the template genuinely
could not carry the state. These templates can.

## Steps

### Step 1 — `delay` and the module skeleton

The instrument first, because nothing after it is testable without a future of known duration.

```bp
//// std/async — combinators over `@Future<T>`.
////
//// Two surfaces. `allOf`/`raceOf`/`settleOf` take UNSTARTED tasks and are
//// concurrent on both targets. `all`/`allSettled`/`race` take started futures,
//// are concurrent on commonJS, and are sequential on erlang because
//// `@Future<T>` lowers eagerly there (`libs/std/src/http.bp:16-18`).

#[@future]
#[@External.Node("""new Promise(__r => setTimeout(() => __r($1), $0))""")]
#[@External.Erlang("""(fun(__M, __V) -> timer:sleep(__M), __V end)($0, $1)""")]
pub declare fn delay<T>(millis: i32, value: T) -> @Future<T>;

// The second instrument: a future that fails. `settleOf` and `timeout` cannot
// be tested without one, and a test that reaches an unreachable host to get a
// failure is a test that fails on a laptop with no network.
#[@future]
#[@External.Node("""Promise.reject(new Error($0))""")]
#[@External.Erlang("""erlang:error($0)""")]
pub declare fn failed<T>(message: string) -> @Future<T>;
```

**Acceptance:**
- [ ] `await delay(20, "x")` answers `"x"` on both targets
- [ ] the call takes at least 20 monotonic milliseconds on both targets
- [ ] `delay` type-checks with `T` bound to a record as well as to a `string`
- [ ] `failed("down")` inside a `settleOf` answers an `Error` element rather than taking the suite down, on both targets

### Step 2 — `allOf`, the concurrent form

```bp
// Run every task concurrently and answer their results in the ORDER OF THE
// INPUT, not the order they finished. Fails the whole call if any task fails —
// `Promise.all` semantics, and the right default for a page that cannot render
// without all of its data.
#[@future]
#[@External.Node("""Promise.all($0.map(__f => __f()))""")]
#[@External.Erlang("""(fun(__Ts) -> __Me = self(), __N = length(__Ts), lists:foreach(fun(__I) -> spawn(fun() -> __Me ! {__I, (lists:nth(__I, __Ts))()} end) end, lists:seq(1, __N)), [receive {__I, __V} -> __V end || __I <- lists:seq(1, __N)] end)($0)""")]
pub declare fn allOf<T>(tasks: Array<fn() -> @Future<T>>) -> @Future<Array<T>>;
```

The erlang cell's collection loop receives by index, so a task that finishes first does not take
another task's slot. A task that never answers blocks the gather — that is what `timeout` in step 5
is for.

**Acceptance:**
- [ ] `allOf` of three tasks delaying 60, 20 and 40 ms answers `["a", "b", "c"]` in input order on both targets
- [ ] the whole call completes in under 120 ms on both targets — proving it did not run them serially
- [ ] `allOf([])` answers `[]` rather than blocking
- [ ] a task that throws fails the call on both targets, and the error reaches the caller's `catch`

### Step 3 — `settleOf` and `raceOf`

```bp
// Never fails. Each element is an `@Result<T, string>`, so a page can render the
// widgets that answered and omit the ones that did not.
#[@future]
pub declare fn settleOf<T>(tasks: Array<fn() -> @Future<T>>) -> @Future<Array<@Result<T, string>>>;

// The first task to ANSWER, not the first in the list. The losers are left
// running — there is no cancellation surface in botopink (see Language gaps).
#[@future]
pub declare fn raceOf<T>(tasks: Array<fn() -> @Future<T>>) -> @Future<T>;
```

**Acceptance:**
- [ ] `settleOf` of one succeeding and one failing task answers a two-element array with one `Ok` and one `Error`, in input order, on both targets
- [ ] `settleOf` never propagates a failure to its caller
- [ ] `raceOf` of tasks delaying 80 and 10 ms answers the 10 ms one on both targets — the assertion the future-surface `race` cannot make
- [ ] `raceOf([])` answers an error rather than blocking forever

### Step 4 — the future surface, with its erlang behaviour written down

```bp
// `Promise.all` parity for the client half. On erlang the futures have already
// resolved by the time this is called, in list order: the result is correct and
// the concurrency is absent. Use `allOf` on the server.
#[@future]
#[@External.Node("""Promise.all($0)""")]
#[@External.Erlang("""$0""")]
pub declare fn all<T>(futures: Array<@Future<T>>) -> @Future<Array<T>>;
```

**Acceptance:**
- [ ] `all` answers results in input order on both targets
- [ ] `allSettled` answers one `@Result` per input on both targets and never fails
- [ ] `race` answers the fastest on commonJS and element zero on erlang, and BOTH behaviours are asserted by the test file rather than one being treated as a bug
- [ ] the module docblock states the erlang divergence, and each of the three functions repeats it in its own comment

### Step 5 — `timeout`

```bp
// `Ok(value)` when the task answered inside the budget, `Error("timeout")` when
// it did not. The task keeps running; the caller stops waiting.
#[@future]
pub fn timeout<T>(task: fn() -> @Future<T>, millis: i32, fallback: T) -> @Future<@Result<T, string>>;
```

**Acceptance:**
- [ ] a 10 ms task under a 100 ms budget answers `Ok`
- [ ] a 200 ms task under a 50 ms budget answers `Error("timeout")` in roughly 50 ms, on both targets
- [ ] the timed-out task's later completion does not corrupt the caller's answer
- [ ] `timeout` is expressed over `raceOf` + `delay` rather than a third host cell

### Step 6 — export line and docs

`pub mod async;` handed to front 01 (which owns `src/root.bp`), and the `libs/std/AGENTS.md` tree
listing gains `async.bp`. The module stays at the root of the tree in `../modules.md`.

**Acceptance:**
- [ ] `import {async} from "std";` resolves from a consumer package — `async` is not a keyword
      (`modules/compiler-core/src/lexer.zig:721-767`), so the module name is legal
- [ ] `libs/std/AGENTS.md` names the file in the same commit that adds it
- [ ] front 01's `root.bp` commit carries the line

## Examples

- [`examples/parallel-fetch-example.bp`](./examples/parallel-fetch-example.bp) — a server-rendered
  dashboard that issues three reads together, degrades when an optional widget is down, and puts a
  budget on a slow dependency.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No array destructuring in a binding — `val [a, b, c] = xs;` does not parse | every `all`/`allOf` call site reading its results | `val a = xs.at(0).unwrapOr(…);` per element | destructuring patterns in `val`/`var` bindings, at least for arrays and tuples |
| `@Future<T>` lowers eagerly on the erlang backend | the whole future surface — `all` is a map, `race` is element zero, `timeout` cannot fire | take unstarted `fn() -> @Future<T>` tasks and `spawn` them in the host cell | a lazy `@Future` lowering on erlang, or a `@Task<T>` type that is explicitly unstarted on both targets |
| No cancellation | `raceOf`'s losers and `timeout`'s expired task keep running | leave them running and document it | a cancellation token threaded through `#[@future]`, or `@Future.cancel` |
| A generic parameter typed `Array<fn() -> @Future<T>>` is unverified | `allOf`, `settleOf`, `raceOf` signatures | if it does not check, drop to `Array<fn() -> T>` and lose the future element type | pin fn-typed elements inside a generic array in the inference tests |

## Test plan

Inline `test` blocks at the bottom of `src/async.bp`, the way every std module does it, run by
`botopink test --target commonJS` and `--target erlang` from `libs/std/`, and by `zig build
test-libs` as part of the ecosystem gate. `await` works directly inside a `test` block
(`repository/emilia/src/emilia.bp:475-480`), so no harness wrapper is needed.

The tests assert three kinds of thing, and the middle one is what makes this front falsifiable:

- **Results and order** — `allOf` of three different delays answers input order; `settleOf` answers
  one element per input with the failures in place. Deterministic on both targets.
- **Elapsed time** — `allOf` of 60/20/40 ms tasks completes in under 120 ms. This is the only
  assertion that can tell concurrency from a sequential map, so it is the one that has to exist. It
  is wall-clock and therefore the flakiest test in track A; the budget is set at roughly double the
  longest task rather than at the theoretical minimum.
- **Documented divergence** — the future surface's `race` is asserted as fastest-wins on commonJS and
  first-element on erlang. The suite encodes the difference so that a future backend change that
  makes erlang lazy fails a test and forces the docblock to be updated, rather than silently making
  the documentation wrong.

## Definition of done

- `src/async.bp` exists with both surfaces, and the module docblock states the erlang divergence at
  the top rather than in a footnote.
- `allOf` is demonstrably concurrent on both targets by an elapsed-time assertion.
- No server front in this milestone is left depending on the future surface's `race`.
- `pub mod async;` is handed to front 01 and appears in `src/root.bp`.
- `libs/std/AGENTS.md` names `async.bp`.
- Every `// LANGUAGE GAP:` marker in the example appears in the table above.
- The front's tests are green on its assigned target — here, both.
