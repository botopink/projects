# Front 63 — Rakun Navigation Signals

**Track:** B rakun
**Priority:** high — server code nested inside a route handler or a server action cannot say "not
found" or "go elsewhere" today, and front 24's own showcase (`revalidatePath` then `redirect`) does
not compile
**Target:** erlang (server)
**Wave:** 6
**Depends on:** 22 (the route table, to validate a redirect target), 62 (the request frame the
outcome is recorded on) — fronts 24 and 25, whose action dispatcher and handler wrapper capture, depend
on this front, `01-std/04-routing-lib` Step 7 (the
vocabulary this front imports — `NavKind`, `NavOutcome`, the four `nav:` reasons and the `n` wire
form, decision 116)
**Owns:** `repository/rakun/src/navigation.bp`,
`repository/rakun/src/sidecars/rakun_navigation.erl`,
`repository/rakun/test/navigation_test.bp`, and one `pub mod` line in `repository/rakun/src/root.bp`
**Does not touch:** `repository/rakun/src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` — frozen for the milestone; `src/file_router.bp` (front 22) and `src/ssr.bp`
(front 23) are read-only here; the signal vocabulary and both codecs are the bundled library
`routing`'s (`libs/routing/src/navigation.bp`, `01-std/04-routing-lib` Step 7), imported here and by
jhonstart fronts 26, 30 and 31
**Reference:** [decision 116](../../decisions-taken.md#116-code-two-libraries-both-run-is-neutral-routing-gains-navigation-and-param-actions-and-validation-are-bundled-libraries-std-writes-json)
rule 1 (the vocabulary is `routing`'s; the throw, the capture and the checks stay here) ·
[decision 117](../../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only) rules 1 and 4 (a page's signals are jhonstart's; rakun's serve server actions and
route handlers) ·
`NEXTJS-DOCS.md § 14. Tratamento de Erros` (Not Found), `§ 23. Autenticação` (Layout com
autenticação), `§ 26. Referência de Funções` (Navegação), `§ 10. Mutação de Dados` ·
<https://nextjs.org/docs/app/api-reference/functions/not-found> ·
<https://nextjs.org/docs/app/api-reference/functions/redirect> ·
<https://nextjs.org/docs/app/api-reference/functions/permanentRedirect>

---

## Problem

Four functions are missing and the same thing is missing from all of them: a way for server code
nested arbitrarily deep inside a route handler or a server action to stop it and replace its outcome.
`notFound()` is what a `[slug]` handler calls when the slug matches nothing; `redirect(path)` is what
`§ 10`'s create-post action calls after the write. Neither exists, and neither can be written by a
consumer, because a return value cannot travel out of a `#[service]` that a dispatcher three frames
up is composing.

A **page**, a layout and a template are not this front's: they are jhonstart's components, and
jhonstart's `notFound` / `redirect` (front 31) are turned into a 404 or a 307 by jhonstart's own
render, before or after the first chunk, on the server and in a client-only app alike (decision 117
rule 1). rakun has no page-level signal.

Today rakun's only shape for "a different response" is a handler returning `Response.notFound()`
(`repository/rakun/src/http.bp:64-66`). That works at the handler's own frame and nowhere below it:
a `#[service]` that discovers the record is gone returns whatever its own signature says. Threading
an "or a redirect" variant through every one of those signatures is the design this front exists to
avoid — it would put a `case` at every call site in an application for a branch that fires on a
fraction of a percent of requests.

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
the response so the client router navigates without a document reload. In botopink the layout and
page half is jhonstart's (decision 117); this front is the route-handler and server-action half.

### How it maps onto botopink

**A signal is a host-level throw, not a returned sentinel.** `rakun_navigation:signal/1` calls
`erlang:throw(Reason)` where `Reason` is a **string beginning `nav:`**, built by `routing`'s
`signalReason` — the exact spellings are in *Step 7* below. The two supervisors — front 24's action
dispatcher and front 25's handler wrapper — bracket the body with a catch that recognizes that prefix
and re-raises anything else unchanged. Front 23's page dispatch has no such catch: a `nav:` reason
out of a page renderer is a failed render (500), because page signals are jhonstart's (decision 117
rule 1).

The reason is a prefixed string rather than a tagged tuple for one concrete reason: **front 31's error
boundaries live in jhonstart, and jhonstart does not import rakun.** A boundary has to be able to tell
a navigation signal from an error it should render, and it has to do that without a dependency on this
package. A plain string with a neutral prefix, whose vocabulary is the bundled library `routing`
(`navigation`: `signalReason`, `signalFromReason`, `isSignalReason`, `signalPrefixes`), is what both
sides import — rakun here, jhonstart in fronts 30 and 31 — and neither names the other (decision 116,
[`contracts.md` § 5b](../../contracts.md)).

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

`captureSignals` runs `body`. If it raises a navigation reason (`isSignalReason`), the outcome is written onto the request frame
(front 62) and `fallback` is returned; anything else is re-raised. `takeSignal()` reads the outcome
and clears it — a signal is consumed once, by whoever is composing the response, so a nested
`captureSignals` cannot hide one from its parent.

It is generic over the body's type for the same reason `rkSingleton<T>` is
(`repository/rakun/src/runtime.bp:47`): the dispatchers compose `HandlerResponse`, `ActionResult` and
`@Future` of either, and should not stringify any of them. Note that it returns `T` rather than a
`#(T, NavOutcome)` tuple deliberately — tuple labels are lost through generic instantiation
(`repository/jhonstart/src/hooks.bp:75-77`), so a two-field return would have to be read positionally
by every consumer. One value out, one frame read, no positional access.

### Where a signal becomes a response

| Raised from | Becomes |
|---|---|
| a route handler | status 404 for `NotFound`; 307 / 308 / 303 with `Location` for a redirect — no boundary rendering, a handler has no `not-found.bp` |
| a server action | the `n` field of front 24's result envelope, written with `routing`'s `signalToWire` and read by jhonstart's client (decision 117 rule 4); on the progressive path, a 303 to the target or a 404 |
| a page renderer (front 23) | not a signal: the request fails with 500. A page's `notFound` / `redirect` are jhonstart's, and jhonstart's render writes their status through the `ChunkWriter`'s `setStatus` / `setHeader` itself, before or after the first chunk (decision 117 rule 1) |

### The action encoding

One wire field, defined by `routing`'s `navigation` module so the two sides run one codec:

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

Both functions are `routing`'s, pure botopink compiled for erlang and commonJS and tested there
(`01-std/04-routing-lib` Step 7). `signalToWire` is what front 24 puts in the envelope (through the
bundled library `actions`); `signalFromWire` is what front 26 calls in the browser. There is one
implementation, imported by both sides — no copy to keep in step.

### Redirect-target validation

`redirect("/login")` with no `/login` route in the table is a 307 to a 404, discovered in production.
The route table exists (front 22), so the check is cheap: a **relative** destination is matched against
the table at the moment of the redirect and a miss raises with the destination named. An **absolute**
destination (one starting with `http://` or `https://`) is not validated — it is not this server's
table — but it is checked against `rakun.navigation.allowedHosts` (front 05), and an off-list host
raises. An open redirect is a security bug, and the restrictive default is an empty allow-list: with
the property unset, only relative destinations are legal. There is no flag that disables the check.

### Target

erlang. The signal, the capture and the status codes all run while a request
is in flight. What crosses to the browser — the reasons and the four-line wire format — is the
bundled library `routing`'s, compiled for both targets; this front imports it and ships no codec of
its own.

**The sidecar module atom is `rakun_navigation`**, not `navigation`: `shipErlSidecars` skips a
qualifier whose atom matches a module this build emitted
(`modules/compiler-cli/src/cli/libs.zig:596`) and rakun emits `rakun/navigation` — basename
`navigation`. Same rule as front 04's `rakun_runtime`.

## Steps

### Step 1 — The signal

`NavKind` and `NavOutcome` are imported from `routing` (`navigation`), not declared here:

```bp
import {navigation: {NavKind, NavOutcome, signalReason}} from "routing";

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
- [ ] An exception that is not a navigation reason passes through `captureSignals` unchanged, with its
      original reason.
- [ ] `takeSignal()` clears: a second call answers `NavKind.None`. `peekSignal()` does not clear.
- [ ] A nested `captureSignals` inside a captured body does not hide the signal from the outer one —
      the inner capture writes the frame, the outer one finds it.
- [ ] `captureSignals` outside a request raises, because there is no frame to record the outcome on
      (front 62's rule, inherited not restated).
- [ ] A signal raised inside a function wrapped by `try … catch` reaches `captureSignals` — this is the
      test that pins "a signal is not an error".

### Step 3 — Signals through `await`

A route handler is `#[@future] fn(req: Request) -> @Future<HandlerResponse>` (front 25) and an action
answers `@Future<ActionResult>` (front 24); whatever they call awaits others. On erlang `@Future`
lowers eagerly, so the signal is raised during the awaited call and propagates as a plain throw.

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
```

These compose a route handler's response and the progressive path of an action. Choosing a page's
not-found boundary is jhonstart's render's (front 31, decision 117), so this front has no boundary
lookup.

**Acceptance:**
- [ ] `statusFor` answers 404, 307, 308, 303 and 200 for the five cases.
- [ ] `locationHeaderFor` answers `null` for `NotFound` and the destination for a redirect.
- [ ] `grep -n "fn boundaryFor" repository/rakun/modules/rakun/src/navigation.bp` is empty.

### Step 5 — A page renderer is not a signal source

**Acceptance:**
- [ ] A page renderer (front 23) that raises `notFound()` before its first write is answered 500 as a
      failed render, not 404; one that raises after its first write fails the request with the status
      already on the wire unchanged. Page signals are jhonstart's (decision 117 rule 1).
- [ ] The same `notFound()` inside a route handler answers 404 and inside an action answers `n: "N"` —
      the test runs the three in one suite so the distinction is asserted, not assumed.

### Step 6 — The action wire format

`signalToWire` / `signalFromWire` are `routing`'s (`01-std/04-routing-lib` Step 7), where the round
trip, the `""` for `None`, the tolerant `garbage → None` and the `R|307|/a|b` remainder rule are
asserted on both targets. This front asserts that it uses them.

**Acceptance:**
- [ ] `signalToWire(takeSignal())` after `captureSignals` around a `redirect("/blog")` answers
      `R|307|/blog`, and after `notFound()` answers `N` — the literals of `routing`'s table.
- [ ] `grep -n "fn signalToWire\|fn signalFromWire" repository/rakun/modules/rakun/src/navigation.bp`
      is empty — the codec is imported, not re-declared.

### Step 7 — The signal-prefix list

The list is `routing`'s (`navigation.signalPrefixes`, decision 116). This front raises the reasons
through `signalReason` and recognises them in `captureSignals` through `isSignalReason`; front 31
matches the same function and front 23's dispatch catches what it raises. Nothing in the milestone
spells a reason by hand.

**The rule a boundary implements, in one sentence:** any raised reason for which `isSignalReason`
answers true is a navigation signal — re-raise it unchanged, never render it, never log it as an
error, never put it in an `error.digest`.

| Raised by | Reason, literally | Status | Boundary behaviour |
|---|---|---|---|
| `notFound()` | `nav:not-found` | 404 | re-raise; the supervisor that owns the call answers it — jhonstart's render for a page (front 30, decision 117), front 24 or 25 for rakun's |
| `redirect(loc)` | `nav:redirect:<loc>` | 307 | re-raise |
| `permanentRedirect(loc)` | `nav:permanent-redirect:<loc>` | 308 | re-raise |
| `redirectWithStatus(loc, 303)` | `nav:see-other:<loc>` | 303 | re-raise |

`<loc>` is the remainder of the string after the third `:`, so a destination containing `:` needs no
escaping. There is no fifth spelling and no numeric status in the reason — the status is a property of
the verb, which is why `permanentRedirect` gets its own prefix rather than a status field a boundary
would have to parse.

**This is not the action wire format**, and the two must not be conflated. The prefix list above is
what crosses a stack frame inside one BEAM process; the four-line format of *Step 6* is what crosses
to the browser in front 24's envelope. Two transports, two artifacts, one module: both are
`routing`'s `navigation`, where the round trip of each and their case-for-case agreement are asserted
on both targets (`01-std/04-routing-lib` Step 7). `takeSignal` reads a frame written from the reason,
and `signalToWire` reads that same `NavOutcome`.

**Acceptance:**
- [ ] `redirect("/login")` raises exactly `signalReason(NavOutcome(kind: NavKind.Redirect, location:
      "/login", status: 307))` — `nav:redirect:/login` — asserted as a literal caught at the host
      boundary, and likewise `nav:not-found`, `nav:permanent-redirect:/new`, `nav:see-other:/done`.
- [ ] `captureSignals` recognises a reason through `routing`'s `isSignalReason` and nothing else:
      `nav:` alone and `boom` are re-raised unchanged with their original reason.
- [ ] `captureSignals` around a raised `nav:teleport:/x` re-raises the error `signalFromReason` gives
      for an unknown verb — a version skew stays loud.
- [ ] `grep -rn '"jhonstart:\|fn signalReason\|fn signalPrefixes\|fn isSignalReason'
      repository/rakun/modules/rakun/src` is empty — the vocabulary is imported, not spelled.

## Examples

- [`examples/navigation-signals-example.bp`](./examples/navigation-signals-example.bp) — the two
  canonical uses on route handlers (front 25): a `[slug]` handler that calls `notFound()` when the
  post is missing, and an account handler that calls `redirect("/login")` when there is no session.
  The page and layout forms (`§ 14`, `§ 23`) are jhonstart's — front 31's and onze front 53's
  examples.
- [`examples/action-redirect-example.bp`](./examples/action-redirect-example.bp) — `§ 10`'s own
  pattern: a server action that writes, revalidates through front 12, and redirects with rakun's
  `redirect`, the outcome travelling back in the action envelope rather than as an HTTP 307.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| There is no bottom/never type, so a function that cannot return still has to declare a return type, and every call site binds a value that is never produced | `val _gone = redirect("/login");` in both examples | declare `-> i32` and bind to an ignored `val` | a `never` return type, so `redirect(...)` is a statement and unreachable code after it is a compile error |

Two gaps front 01 already recorded apply and are cited rather than re-filed: there is no array
destructuring in a binding, so `routing`'s `signalFromWire` splits and indexes with `.at(i)`; and a std module
cannot call another std module, which is why this front takes the route table as a parameter rather
than reaching front 22 through a façade.

## Test plan

`repository/rakun/test/navigation_test.bp`, run by `botopink test --target erlang` from
`repository/rakun/`, and by `zig build test-libs -- --target erlang --lib rakun` in the ecosystem gate.

erlang only. The reasons and the wire format are `routing`'s and are tested there on erlang and
commonJS (`libs/routing/test/navigation_test.bp`); this front declares no `@External.Node` cell, so it
has no commonJS row, and it asserts that what it raises and captures is `routing`'s vocabulary.

What the tests assert, by step: that a signal does not return and carries the right status; that
capture records and clears exactly once, re-raises non-signals, and is not defeated by `try … catch`
or by nesting; that a signal crosses `await`; that status and `Location` are derived correctly; that
a page renderer's raise is a failed render and not a status; and that each verb raises `routing`'s
reason literal.

The vocabulary is the one artifact this front shares with a different repository, and it is not
this front's: `routing` owns it, and front 31's boundary and this front's capture both call
`isSignalReason`.

## Definition of done

- `src/navigation.bp` compiles with no `@External.Node` cell.
- `src/sidecars/rakun_navigation.erl` compiles under `erlc` with `-Werror`, and its atom does not
  collide with a module rakun emits.
- The redirect-validation rule for rakun's `redirect` is written down here once and cited by fronts
  24, 25 and 64 (a page's redirect target is checked by jhonstart, decision 117); the
  four-line wire format and the four `nav:` reasons are `routing`'s (`01-std/04-routing-lib` Step 7)
  and this front imports them.
- No reason is spelled by hand under `repository/rakun/`: the raise goes through `signalReason` and
  the capture through `isSignalReason`.
- An open redirect is impossible without an explicit host allow-list, and there is no property that
  turns the check off.
- `repository/rakun/AGENTS.md` names `navigation.bp` and that its vocabulary is imported from
  `routing`.
- The front's tests are green on its assigned target — here, erlang.

