# Front 63 — Rakun Navigation Signals

**Track:** B rakun
**Priority:** high — a server component cannot say "not this page" today, so every `[slug]` route that
can miss has no 404 path, `§ 23`'s layout auth guard cannot redirect, and front 24's own showcase
(`revalidatePath` then `redirect`) does not compile; front 31 renders `not-found.bp` and nothing can
trigger it
**Target:** erlang (server)
**Wave:** 6
**Depends on:** 22 (the route table, to validate a redirect target), 23 (the render pipeline that
unwinds), 62 (the request frame the outcome is recorded on)
**Owns:** `repository/rakun/src/navigation.bp`,
`repository/rakun/src/sidecars/rakun_navigation.erl`,
`repository/rakun/test/navigation_test.bp`, and one `pub mod` line in `repository/rakun/src/root.bp`
**Does not touch:** `repository/rakun/src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` — frozen for the milestone; `src/file_router.bp` (front 22) and `src/ssr.bp`
(front 23) are read-only here; the client-side decoder is front 26's file, not this one's
**Reference:** `NEXTJS-DOCS.md § 14. Tratamento de Erros` (Not Found), `§ 23. Autenticação` (Layout com
autenticação), `§ 26. Referência de Funções` (Navegação), `§ 10. Mutação de Dados` ·
<https://nextjs.org/docs/app/api-reference/functions/not-found> ·
<https://nextjs.org/docs/app/api-reference/functions/redirect> ·
<https://nextjs.org/docs/app/api-reference/functions/permanentRedirect>
**Replaces:** `new` — no front in the three drafts proposed it

---

## Problem

Three functions are missing and the same thing is missing from all three: a way for code nested
arbitrarily deep inside a render to stop the render and replace its outcome. `notFound()` is what a
`[slug]` page calls when the slug matches nothing. `redirect(path)` is what `§ 23`'s dashboard layout
calls when there is no session, and what `§ 10`'s create-post action calls after the write. Neither
exists, and neither can be written by a consumer, because a return value cannot travel out of a
layout that a pipeline three frames up is composing.

Today rakun's only shape for "a different response" is a handler returning `Response.notFound()`
(`repository/rakun/src/http.bp:64-66`). That works for a dispatched handler and works nowhere else:
a layout returns `Element`, a page returns `@Future<Element>`, and a `#[service]` that discovers the
record is gone returns whatever its own signature says. Threading an "or a redirect" variant through
every one of those signatures is the design this front exists to avoid — it would put a `case` at
every call site in an application for a branch that fires on a fraction of a percent of requests.

Front 31 is the other half of the damage. It renders `not-found.bp` at the right boundary and there is
no way to reach that boundary, so its central test would have to fake the condition it is supposed to
catch.

## Current state

- `repository/rakun/src/http.bp:50-73` — `Response.ok/json/created/withStatus/notFound/badRequest`.
  `notFound()` builds a `Response`; it does not unwind anything. The file is frozen.
- `repository/rakun/src/runtime.bp:91-104` — `rkDispatch`/`rkDispatchHttp` return a `Response`. An
  unmatched path answers 404 with an empty body; there is no not-found boundary and no 3xx path.
- `repository/jhonstart/src/router.d.bp:18-28` — `Router` has `push`/`replace` and is declaration-only.
  There is no server-side counterpart of any kind.
- `repository/rakun/src/navigation.bp` does not exist.
- botopink's `try … catch` is `@Result`-shaped: `val n = try parse("42") catch 0;`
  (`docs.md:513-524`). It unwraps an `@Result` produced by a `#[@result]` fn. It does not catch a
  host-level raise, which is the property this front depends on.

## Mechanism

### What Next.js does

`notFound()` and `redirect()` throw a special error that React's rendering machinery recognizes.
`notFound()` unwinds to the nearest `not-found` boundary and sets status 404 (`§ 14`).
`redirect(path)` answers 307 and `permanentRedirect(path)` answers 308 (`§ 26`). Both are legal from a
layout, a page, a route handler and a server action; from an action the redirect is carried back in
the response so the client router navigates without a document reload.

### How it maps onto botopink

**A signal is a host-level throw, not a returned sentinel.** `rakun_navigation:signal/1` calls
`erlang:throw(Reason)` where `Reason` is a **string beginning `jhonstart:`** — the exact spellings are
in *Step 7* below. The render supervisor — front 23's pipeline, front 24's action dispatcher, front
25's handler wrapper — brackets the body with a catch that recognizes that prefix and re-raises
anything else unchanged.

The reason is a prefixed string rather than a tagged tuple for one concrete reason: **front 31's error
boundaries live in jhonstart, and jhonstart does not import rakun.** A boundary has to be able to tell
a navigation signal from an error it should render, and it has to do that without a dependency on this
package. A literal prefix both sides can match on a plain string is the cheapest arrangement that does
not create that dependency, and it is fixed by [`contracts.md` § 5b](../../contracts.md).

Choosing a throw over a returned sentinel is the whole design, and it buys three things a sentinel
cannot. It composes through nested calls without changing one signature. It composes through
`await`, which on erlang is identity over an eagerly-lowered `@Future`
(`libs/std/src/http.bp:17-19`), so a signal raised inside an awaited server component reaches the
pipeline the same way a synchronous one does. And it cannot be swallowed by application code by
accident: botopink's `try … catch` unwraps an `@Result` and nothing else, so
`val x = try loadPost(slug) catch fallback;` around a function that calls `notFound()` lets the signal
straight through. That last property is asserted by a test, not assumed — it is the difference between
a signal and an error, and it is the reason this front does not need a comptime lint saying "do not
catch a signal": there is no construct that catches one.

**Nothing is returned, and the type system is told so.** `notFound()` and `redirect(path)` are
declared `-> i32` and never produce a value; a caller writes `val _gone = redirect("/login");` and the
binding is never reached. botopink has no bottom type, so this is the honest spelling and it is the
one the examples use.

### The capture side

```bp
pub fn captureSignals<T>(body: fn() -> T, fallback: T) -> T
pub fn takeSignal() -> NavOutcome
```

`captureSignals` runs `body`. If it raises a nav tuple, the outcome is written onto the request frame
(front 62) and `fallback` is returned; anything else is re-raised. `takeSignal()` reads the outcome
and clears it — a signal is consumed once, by whoever is composing the response, so a nested
`captureSignals` cannot hide one from its parent.

It is generic over the body's type for the same reason `rkSingleton<T>` is
(`repository/rakun/src/runtime.bp:47`): the pipeline composes `Element`, `@Future<Element>` and
`Response` bodies and should not stringify any of them. Note that it returns `T` rather than a
`#(T, NavOutcome)` tuple deliberately — tuple labels are lost through generic instantiation
(`repository/jhonstart/src/hooks.bp:75-77`), so a two-field return would have to be read positionally
by every consumer. One value out, one frame read, no positional access.

### Where a signal becomes a response

| Raised from | Becomes |
|---|---|
| a layout or a page, before the first byte | status 404 and the nearest `not-found.bp` for `NotFound`; status 307/308 with `Location` for a redirect |
| a layout or a page, after the first byte is flushed | the status is already on the wire and cannot change: the pipeline appends an in-stream navigation instruction to the payload and closes the stream. This case is tested, not documented. |
| a route handler | the same status codes, with no boundary rendering — a handler has no `not-found.bp` |
| a server action | a field in front 24's result envelope, consumed by front 26's client router |

### The action encoding

One wire field, defined here so the two sides cannot disagree:

```
""            no signal
"N"           notFound
"R|307|/login"  redirect
"R|308|/new"    permanentRedirect
```

```bp
pub fn signalToWire(out: NavOutcome) -> string
pub fn signalFromWire(wire: string) -> NavOutcome
```

Both functions are pure botopink and both are tested here. `signalToWire` is what front 24 puts in the
envelope; `signalFromWire` is what front 26 calls in the browser. This front compiles only for erlang
— the browser copy is front 26's file — so the shared artifact is the format and the round-trip test,
which is why the format is four lines long and carries no JSON.

### Redirect-target validation

`redirect("/login")` with no `/login` route in the table is a 307 to a 404, discovered in production.
The route table exists (front 22), so the check is cheap: a **relative** destination is matched against
the table at the moment of the redirect and a miss raises with the destination named. An **absolute**
destination (one starting with `http://` or `https://`) is not validated — it is not this server's
table — but it is checked against `rakun.navigation.allowedHosts` (front 05), and an off-list host
raises. An open redirect is a security bug, and the restrictive default is an empty allow-list: with
the property unset, only relative destinations are legal. There is no flag that disables the check.

### Target

erlang. The signal, the capture, the boundary selection and the status codes all run while a request
is in flight. The one artifact that crosses is the four-line wire format above, and this front ships
only the server half of it; front 26 owns the browser half and cites this section for the grammar.

**The sidecar module atom is `rakun_navigation`**, not `navigation`: `shipErlSidecars` skips a
qualifier whose atom matches a module this build emitted
(`modules/compiler-cli/src/cli/libs.zig:596`) and rakun emits `rakun/navigation` — basename
`navigation`. Same rule as front 04's `rakun_runtime`.

## Steps

### Step 1 — The signal

```bp
pub type NavKind {
    None,
    NotFound,
    Redirect,
}

pub type NavOutcome(
    kind: NavKind,
    location: string,
    status: i32,
)

pub fn notFound() -> i32
pub fn redirect(location: string) -> i32
pub fn permanentRedirect(location: string) -> i32
pub fn redirectWithStatus(location: string, status: i32) -> i32
```

`redirectWithStatus` exists for 303, which is what a POST-then-GET action wants and what 307 gets
wrong; the accepted set is 303, 307 and 308 and anything else raises.

**Acceptance:**
- [ ] `notFound()` never returns: the statement after it does not execute, asserted by a counter that
      stays at its initial value.
- [ ] `redirect("/login")` produces `NavOutcome(kind: NavKind.Redirect, location: "/login", status: 307)`.
- [ ] `permanentRedirect("/new")` produces status 308.
- [ ] `redirectWithStatus("/x", 302)` raises, naming the accepted set.
- [ ] `redirect("/nowhere")` with no matching route in the table raises, naming `/nowhere`.
- [ ] `redirect("https://example.com/")` raises with `rakun.navigation.allowedHosts` unset, and
      succeeds with `example.com` on the list.
- [ ] `redirect("//evil.example")` is treated as absolute — the protocol-relative form is the classic
      open-redirect bypass and it is checked against the same list.

### Step 2 — Capture

```bp
pub fn captureSignals<T>(body: fn() -> T, fallback: T) -> T
pub fn takeSignal() -> NavOutcome
pub fn peekSignal() -> NavOutcome
```

**Acceptance:**
- [ ] `captureSignals({ -> notFound(); }, 0)` answers `0` and `takeSignal().kind` is `NavKind.NotFound`.
- [ ] `captureSignals({ -> 7; }, 0)` answers `7` and `takeSignal().kind` is `NavKind.None`.
- [ ] An exception that is not a nav tuple passes through `captureSignals` unchanged, with its
      original reason.
- [ ] `takeSignal()` clears: a second call answers `NavKind.None`. `peekSignal()` does not clear.
- [ ] A nested `captureSignals` inside a captured body does not hide the signal from the outer one —
      the inner capture writes the frame, the outer one finds it.
- [ ] `captureSignals` outside a request raises, because there is no frame to record the outcome on
      (front 62's rule, inherited not restated).
- [ ] A signal raised inside a function wrapped by `try … catch` reaches `captureSignals` — this is the
      test that pins "a signal is not an error".

### Step 3 — Signals through `await`

A page is `#[@future] fn(route: PageContext) -> @Future<Element>` (front 22), and a server component
awaits others. On erlang `@Future` lowers eagerly, so the signal is raised during the awaited call and
propagates as a plain throw.

**Acceptance:**
- [ ] `captureSignals` around a body that `await`s a `#[@future]` function which calls `notFound()`
      records the signal.
- [ ] The same holds two levels of `await` deep.
- [ ] The value bound by `await` is never used, asserted by a body whose next statement increments a
      counter that stays at zero.

### Step 4 — Response composition

```bp
pub fn statusFor(out: NavOutcome) -> i32
pub fn locationHeaderFor(out: NavOutcome) -> ?string
pub fn boundaryFor(out: NavOutcome, table: RouteEntry[], pattern: string) -> ?RouteEntry
```

`boundaryFor` walks front 22's table for the nearest `N` entry at or above `pattern`, which is the
`not-found.bp` front 31 renders.

**Acceptance:**
- [ ] `statusFor` answers 404, 307, 308 and 200 for the four cases.
- [ ] `locationHeaderFor` answers `null` for `NotFound` and the destination for a redirect.
- [ ] `boundaryFor` on `/blog/[slug]` finds `not-found.bp` registered at `/blog` before the one at `/`.
- [ ] `boundaryFor` with no `N` entry anywhere answers `null`, and the pipeline's documented behaviour
      for that case is a bare 404 body — stated here so front 31 does not have to guess.

### Step 5 — The streaming case

**Acceptance:**
- [ ] A signal raised before the first flush sets the status.
- [ ] A signal raised after the first flush does **not** change the status — the response is already
      200 — and instead appends the wire form of the outcome to the stream, which front 26's router
      consumes as a client-side navigation.
- [ ] The test asserts both the unchanged status and the appended instruction, in one run, because
      asserting only one of them is how this bug ships.

### Step 6 — The action wire format

```bp
pub fn signalToWire(out: NavOutcome) -> string
pub fn signalFromWire(wire: string) -> NavOutcome
```

**Acceptance:**
- [ ] `signalFromWire(signalToWire(out))` equals `out` field by field for all four cases — never with
      `==` on a record containing an array, and there is no array here for exactly that reason.
- [ ] `signalToWire(NavOutcome(kind: NavKind.None, ...))` answers `""`.
- [ ] `signalFromWire("garbage")` answers `NavKind.None` rather than raising: a malformed field
      arriving from the network is a client that must not be able to crash a render.
- [ ] `signalFromWire("R|307|/a|b")` answers a location of `/a|b` — the destination is the remainder
      of the line, not the third field, so a `|` in a path round-trips.

### Step 7 — The signal-prefix list

This front owns the list. Front 31 matches it, front 23 catches it, and nothing else in the milestone
may add a spelling to it.

**The rule a boundary implements, in one sentence:** any raised reason that is a string beginning
`jhonstart:` is a navigation signal — re-raise it unchanged, never render it, never log it as an
error, never put it in an `error.digest`.

| Raised by | Reason, literally | Status | Boundary behaviour |
|---|---|---|---|
| `notFound()` | `jhonstart:not-found` | 404 | re-raise; front 23 selects `not-found.bp` |
| `redirect(loc)` | `jhonstart:redirect:<loc>` | 307 | re-raise |
| `permanentRedirect(loc)` | `jhonstart:permanent-redirect:<loc>` | 308 | re-raise |
| `redirectWithStatus(loc, 303)` | `jhonstart:see-other:<loc>` | 303 | re-raise |

`<loc>` is the remainder of the string after the third `:`, so a destination containing `:` needs no
escaping. There is no fifth spelling and no numeric status in the reason — the status is a property of
the verb, which is why `permanentRedirect` gets its own prefix rather than a status field a boundary
would have to parse.

**This is not the action wire format**, and the two must not be conflated. The prefix list above is
what crosses a stack frame inside one BEAM process; the four-line format of *Step 6* is what crosses
to the browser in front 24's envelope. Two transports, two artifacts, one source of truth: `takeSignal`
reads a frame written from the prefix string, and `signalToWire` reads that same `NavOutcome`. The test
below is what keeps them from drifting.

```bp
pub fn signalReason(out: NavOutcome) -> string
pub fn signalFromReason(reason: string) -> NavOutcome
pub fn isSignalReason(reason: string) -> bool
pub fn signalPrefixes() -> string[]
```

`signalPrefixes()` answers the four literals with their `<loc>` placeholders stripped —
`["jhonstart:not-found", "jhonstart:redirect:", "jhonstart:permanent-redirect:",
"jhonstart:see-other:"]` — so front 31's test can assert against this function rather than against a
copy of the table.

**Acceptance:**
- [ ] `signalReason` answers each of the four literals exactly, asserted as literal strings.
- [ ] `signalFromReason(signalReason(out))` equals `out` field by field for all four cases, and for a
      location containing `:` and `/`.
- [ ] `signalReason(signalFromReason(r)) == r` for each of the four literals — the round trip is
      asserted in both directions, because only one direction is what lets a spelling drift.
- [ ] **The list and the wire format agree:** for each of the four cases,
      `signalToWire(signalFromReason(reason))` equals the *Step 6* literal for that case. This is the
      one test that ties the two artifacts together and it names both literals inline.
- [ ] `signalPrefixes()` has exactly four entries, and every entry is a prefix of some
      `signalReason(...)` output — asserted by construction, so adding a fifth verb without adding its
      prefix fails.
- [ ] `isSignalReason("jhonstart:not-found")` is true; `isSignalReason("jhonstart:")` is **false** —
      the bare prefix is not a signal, and treating it as one would swallow an error whose message
      happens to start that way.
- [ ] `isSignalReason("boom")` is false, and `captureSignals` re-raises it unchanged with its original
      reason.
- [ ] `signalFromReason("jhonstart:teleport:/x")` raises, naming the unknown verb: an unrecognized
      `jhonstart:` reason is a version skew between rakun and jhonstart, and silently rendering it as
      an error is how that skew stays invisible.
- [ ] Front 31's boundary test asserts the same four literals through `signalPrefixes()`, and this
      front's *Definition of done* requires that it does.

## Examples

- [`examples/navigation-signals-example.bp`](./examples/navigation-signals-example.bp) — the two
  canonical uses side by side: a `[slug]` page that calls `notFound()` when the post is missing
  (`§ 14`), and a dashboard layout that calls `redirect("/login")` when there is no session (`§ 23`).
- [`examples/action-redirect-example.bp`](./examples/action-redirect-example.bp) — `§ 10`'s own
  pattern: a server action that writes, revalidates through front 12, and redirects, with the outcome
  travelling back in the action envelope rather than as an HTTP 307.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| There is no bottom/never type, so a function that cannot return still has to declare a return type, and every call site binds a value that is never produced | `val _gone = redirect("/login");` in both examples | declare `-> i32` and bind to an ignored `val` | a `never` return type, so `redirect(...)` is a statement and unreachable code after it is a compile error |

Two gaps front 01 already recorded apply and are cited rather than re-filed: there is no array
destructuring in a binding, so `signalFromWire` splits and indexes with `.at(i)`; and a std module
cannot call another std module, which is why this front takes the route table as a parameter rather
than reaching front 22 through a façade.

## Test plan

`repository/rakun/test/navigation_test.bp`, run by `botopink test --target erlang` from
`repository/rakun/`, and by `zig build test-libs -- --target erlang --lib rakun` in the ecosystem gate.

erlang only. The wire format's browser half lives in front 26 and is tested there against the same
four strings, which are written out in *Step 6* of this README so the two test files assert the same
literals rather than two derivations of them. That split is deliberate: this front declares no
`@External.Node` cell, so it has no commonJS row, and a format shared by two fronts is safer pinned to
literals in one README than to a shared implementation neither owns.

What the tests assert, by step: that a signal does not return and carries the right status; that
capture records and clears exactly once, re-raises non-signals, and is not defeated by `try … catch`
or by nesting; that a signal crosses `await`; that status, `Location` and boundary selection are
derived correctly; that a post-flush signal degrades instead of lying about the status; that the wire
format round-trips, including a destination containing `|`; and that the four signal-prefix literals
round-trip in both directions and agree with the wire format case for case.

The prefix list is the one artifact this front shares with a different repository. Front 31's test
asserts it through `signalPrefixes()` and this front's test asserts the literals — two files, one
source, and a fifth verb added without a prefix reds both.

## Definition of done

- `src/navigation.bp` compiles with no `@External.Node` cell.
- `src/sidecars/rakun_navigation.erl` compiles under `erlc` with `-Werror`, and its atom does not
  collide with a module rakun emits.
- The four-line wire format, the four signal-prefix literals and the redirect-validation rule are
  written down here once and cited by fronts 23, 24, 25, 26, 31 and 64 rather than re-derived.
- Front 31's boundary test asserts the prefix list through `signalPrefixes()` rather than through a
  copy of it, and a fifth verb added here without a prefix fails that test.
- An open redirect is impossible without an explicit host allow-list, and there is no property that
  turns the check off.
- `repository/rakun/AGENTS.md` names `navigation.bp`, the nav tuple and the wire format.
- The front's tests are green on its assigned target — here, erlang.
