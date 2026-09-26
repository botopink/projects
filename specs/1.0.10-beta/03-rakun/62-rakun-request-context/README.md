# Front 62 — Rakun Request Context

**Track:** B rakun
**Priority:** critical — nothing on the server can read a cookie or a header today, so authentication in
a layout, theme personalization, draft mode, per-request deduplication and the dynamic-rendering
decision front 60 keys off are all unreachable; fronts 12, 18, 23, 24, 25, 32, 60, 63, 64, 65 and 66
all read what this front writes
**Target:** erlang (server)
**Wave:** 2 — and it must land before `23` (wave 5), because `23` parses `searchParams` and has
to mark the render dynamic through this front
**Depends on:** 01 (`hash`, `io.clock`, `io.random`, `encoding`), 04 (the supervision tree, the connection
process and `rkSetReplyHeader`)
**Owns:** `repository/rakun/src/request_context.bp`, `repository/rakun/src/request_memo.bp`,
`repository/rakun/src/sidecars/rakun_request_context.erl`,
`repository/rakun/test/request_context_test.bp`, `repository/rakun/test/request_memo_test.bp`, and
two `pub mod` lines in `repository/rakun/src/root.bp`
**Does not touch:** `repository/rakun/src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` — frozen for the milestone; and the files owned by 22 · 23 · 24 · 25 · 60 · 63 · 66
**Reference:** `NEXTJS-DOCS.md § 9. Busca de Dados (Fetching)` (Memoização · Reutilizando dados com
`React.cache` · Preloading), `§ 10. Cookies em Server Actions`, `§ 18. Memoização de dados`,
`§ 23. Autenticação`, `§ 26. Referência de Funções` (Data · Cache) ·
<https://nextjs.org/docs/app/api-reference/functions/cookies> ·
<https://nextjs.org/docs/app/api-reference/functions/headers> ·
<https://nextjs.org/docs/app/api-reference/functions/draftMode> ·
<https://nextjs.org/docs/app/api-reference/functions/connection> ·
<https://nextjs.org/docs/app/api-reference/functions/after>

---

## Problem

A rakun handler gets a `Request` value with four methods on it — `param`, `query`, `header`, `body`
(`repository/rakun/src/http.bp:35-43`) — and that value exists only inside the function the router
dispatched to. Nothing else on the server can reach it. A `#[service]` three calls down the stack
cannot see the request. A page rendered by front 23 is not dispatched by the router at all, so it
never receives one. There is no way to set a cookie: `Response` is `(status: i32, body: string)` and
`http.bp` is frozen, so there is no field to put a header in and no `withHeader` to add one.

The consequence is the largest hole in the milestone, and it is not one feature. `§ 23`'s layout auth
guard — `const session = await auth(); if (!session) redirect('/login')` — cannot be written, because
`auth()` reads a session cookie from a component nobody passed a request to. `§ 10`'s
`cookieStore.set('theme', theme)` inside a server action cannot be written. `§ 9`'s "fetches idênticos
no mesmo render são automaticamente memoizados" has no scope to be memoized in, and neither does
`React.cache`, which `§ 18` names as the thing that stops `generateMetadata` and the page from loading
the same record twice. Front 60 cannot decide whether a route is static, because the definition of
dynamic is *this route reached one of these functions*. Front 12's `revalidateTag` already calls
`rkCachePhase()` and there is nothing behind it.

Eleven rows of the Next.js coverage audit trace back to this one absent mechanism: `headers()`,
`cookies()`, `draftMode()`, `connection()`, `after()`, request memoization, `React.cache`, the preload
pattern, `generateMetadata`/page dedup, cookies in server actions, and the request accessors on route
handlers. This front is that mechanism, and it is the only front that builds it.

## Mechanism

### What Next.js does

`cookies()`, `headers()`, `draftMode()` and `connection()` are async functions that return values
bound to the in-flight request without anyone passing a request down (`§ 26` Data). Node has no such
scope naturally, so React and Next build one out of AsyncLocalStorage. Reading any of them opts the
route into dynamic rendering (`§ 6` nota, `§ 11`). `after(fn)` schedules work to run once the response
is sent (`§ 26` Cache). `React.cache(fn)` memoizes a function for the duration of one request and
explicitly does not share across requests (`§ 9`).

### How it maps onto botopink

**On the BEAM a request is served by a process, and process-local state is exactly request scope.**
This is the one place in the milestone where BEAM is easier than Node — Node had to invent
AsyncLocalStorage to get what `erlang:put/2` gives away. But "the process dictionary is the request
scope" is one sentence short of correct, and the missing sentence is where the bugs live: a keep-alive
connection process serves many requests in sequence, so process identity is **not** request identity.
A request scope that is implicit in the process is a scope that leaks the previous request's cookies
into the next one.

So the scope is explicit, and it is a **frame** with an **epoch**:

| Step | Who calls it | What happens |
|---|---|---|
| `beginRequest(scope)` | front 04's acceptor (handler), front 23's SSR pipeline (render), front 24's action dispatcher (action), front 07's chain (middleware) | writes one key, `rakun_request`, into the serving process's dictionary: a map holding a fresh monotonic `epoch`, the parsed headers, the parsed cookies, the phase, the dynamic flag (false), the memo table (empty), the deferred-work queue (empty) and the queued `Set-Cookie` lines (empty). Returns the epoch. |
| reads and writes | application code | every accessor takes the epoch it was minted with and compares it to the frame's. A mismatch raises. |
| `endRequest()` | the same caller, always, including on the failure path | returns the queued `Set-Cookie` lines as a `\n`-separated blob, spawns one monitored process per deferred thunk with a **frozen** copy of the frame, then erases the key. |

`beginRequest` over a frame that already exists raises — a nested request scope is a dispatcher bug,
not a feature. `endRequest` with no frame raises. Neither has a lenient mode.

**Reading outside a request is a hard failure.** `headers()` with no frame does not return an empty
map, does not return `null`, and does not consult a default. It raises
`request context is not established — headers() is legal only while a request is in flight`. There is
no `headersOr(default)`, no `rakun.request.lenient` property, and no predicate that lets a caller
branch around it: a predicate is an escape hatch with a different spelling, and this project's
standing rule is that the most restrictive behaviour wins and no knob gets around it. A library that
needs to work both inside and outside a request takes the values as parameters — which is what a
library that does not know whether it is in a request should have been doing anyway.

**The epoch is what makes the keep-alive bug loud.** `cookies()` hands back a `Cookies(epoch)` record.
If that record is captured in a closure and used after `endRequest`, or used from the next request on
the same connection, the epoch no longer matches and the call raises instead of writing a cookie into
somebody else's response. The test for this is the first one in the file.

### The five phases, and what each one permits

```bp
pub type RequestPhase {
    Middleware,
    Render,
    Action,
    Handler,
    After,
}
```

| | `headers()` read | `cookies()` read | `cookies().set/delete` | `after()` | marks dynamic |
|---|---|---|---|---|---|
| `Middleware` | yes | yes | yes | yes | n/a |
| `Render` | yes | yes | **raises** | yes | yes |
| `Action` | yes | yes | yes | yes | n/a |
| `Handler` | yes | yes | yes | yes | yes |
| `After` | yes | yes | **raises** | **raises** | n/a |

A cookie write during render raises rather than warns, because by the time a render is running the
response head may already be on the wire — `§ 10` puts cookie writes in server actions for exactly
this reason. `After` is the frozen copy: the response is gone, so every write is a no-op waiting to
be discovered in production, and raising is the cheaper discovery.

`requestPhase()` reads the frame's phase. Front 12's `rkCachePhase()` reads the same word — that is
one phase, stored once, and front 12's README already assumes it ("the SSR pipeline and the action
dispatcher set a phase on the request process").

### The dynamic marker, and the two modes

Every function in the table above sets `dynamic = true` on the frame when the phase is `Render` or
`Handler`. `connection()` sets it and reads nothing, which is its whole purpose. Front 60 reads
`isDynamic()` after the render to decide whether the output may become a prerendered entry.

The frame carries one more field, `strict`, set only by front 60's build-time prerenderer. With
`strict = false` (the serving path) a dynamic read marks and continues. With `strict = true` it
**raises**, naming the function and the route, which is how `output: 'export'` and
`dynamic = ForceStatic` fail the build rather than silently shipping a page that read a cookie at
build time. `strict` is set by the prerenderer, never by application configuration.

### Cookies out

Front 04's `rkSetReplyHeader/2` replaces by name, so it can carry one `Set-Cookie` and no more. This
front therefore queues fully-serialized `Set-Cookie` values on the frame and hands the list back from
`endRequest()`; the dispatcher appends each one to the response as a separate header line. Cookie
serialization (`Path`, `Domain`, `Max-Age`, `HttpOnly`, `Secure`, `SameSite`, and the percent-encoding
of the value through front 01's `encoding.percentEncode`) is pure botopink in `request_context.bp`, so
it is unit-testable without a socket. The private codec in `request_context.bp`
(`percentEncode` / `hexValue` / `percentDecode`) is deleted for std: std's `encoding`
(`percentEncode`, `percentDecode`, `formParse`, `formStringify`) is the one percent and form codec,
used by rakun here and by jhonstart's router on the other side of the same payload (decision 116).

### Draft mode

`draftMode()` is a signed cookie, `__rakun_draft`, whose value is `token + "." + signature` with
`signature = hash.hmacSha256Base64Url(secret, token)` (front 01, under `hash` per decision 106) and `token = random.secureToken(16)` (`io.random`).
`isEnabled()` recomputes the signature and compares with `hash.equalsConstantTime`; a forged or
truncated cookie is simply not enabled, and the comparison is constant-time because the alternative is
a signing oracle. The secret is `rkProp("rakun.draft.secret")` (front 05); an empty secret makes
`enable()` raise at the first call rather than issuing an unsigned bypass cookie.

Enabling draft mode marks the request dynamic and instructs front 60 to bypass its prerendered entry.
That is the only coupling between the two fronts, and it is one boolean on the frame.

### Deferred work

`after(work)` pushes a thunk onto the frame. `endRequest()` spawns each with `spawn_monitor`, handing
the child a frozen copy of the frame under phase `After`. A child that raises is logged through front
17 with the request id and never reaches the client — the response is already written. A child that
never terminates is not this front's problem to solve, but it is this front's problem to *bound*: the
sidecar sets `rakun.request.after.timeout` (default 30 000 ms) and kills a child that outlives it,
logging the kill. The Erlang function is `rakun_request_context:defer/1`, not `after/1`, because
`after` is a reserved word in Erlang's `receive` and `try` forms.

### Per-request memoization

`memoize(key, load)` is the `React.cache` analogue and simultaneously the "identical fetches in one
render are memoized" rule from `§ 9` and the `generateMetadata`/page dedup from `§ 18`. One table per
frame; a miss runs `load` and stores; a hit returns the stored value. It is generic over the loaded
type the way `rkSingleton<T>` already is (`repository/rakun/src/runtime.bp:47`), so the caller keeps
its own type instead of stringifying.

`preload(key, load)` is `§ 9`'s preload pattern. **It cannot be built on `@Task`.** On erlang
`@Task<T>` lowers eagerly — `libs/std/src/http.bp:17-19` says so in as many words: "Erlang is eager:
`@Task<T>` resolves to `T` in the eager-lowering arm", so `await` is identity and a future is a
value that has already been computed. `preload` therefore spawns a BEAM process and stores a pending
marker holding the child's pid; a later `memoize` with the same key waits on that child's monitor
rather than starting a second load. Front 02's async primitives take **unstarted** tasks
(`Array<fn() -> @Task<T>>`) for the same reason, and a caller who wants several preloads in flight
should reach for them rather than calling `preload` in a loop.

The three cases a caller can produce within one request, stated so the sidecar has nothing left to
decide:

| Frame holds, for this key | `memoize(key, load)` does |
|---|---|
| nothing | runs `load`, stores the value, answers it |
| a resolved value (a previous `memoize`, or a `preload` whose child finished) | answers the stored value; `load` is not called and not evaluated |
| a pending marker (a `preload` whose child is still running) | waits on that child's monitor, stores the result, answers it; `load` is not called |

A value stored by a resolved `@Task` is stored **after** the eager lowering has already run it, so
there is no third state where the frame holds an unresolved future. That is a simplification the BEAM
target gives away, and this front takes it rather than modelling a promise it cannot observe.

### Target

Everything here runs while a request is in flight, so everything here is erlang. The module declares
no `@External.Node` cell. Its host cells are `#[@External.Erlang]` over the process dictionary and
`spawn_monitor`; the parsing, serialization and phase logic are pure botopink and are tested as such.

**The sidecar module atom cannot be `request_context`.** `shipErlSidecars` skips any qualifier whose
atom matches a module this build emitted (`modules/compiler-cli/src/cli/libs.zig:596`), and rakun
emits `rakun/request_context` — basename `request_context`. The file is
`src/sidecars/rakun_request_context.erl` and the atom is `rakun_request_context`, for the same reason
front 04's host module is `rakun_runtime`.

## Steps

### Step 1 — The frame: begin, end, epoch

```bp
pub type RequestScope(
    id: string,
    phase: RequestPhase,
    method: string,
    path: string,
    query: string,
    headersWire: string,
    strict: bool,
)

pub fn beginRequest(scope: RequestScope) -> i64
pub fn endRequest() -> string
pub fn setPhase(phase: RequestPhase) -> i32
pub fn requestPhase() -> RequestPhase
pub fn requestId() -> string
pub fn requestEpoch() -> i64
```

`headersWire` is `name\tvalue` lines, `\n`-separated, names already lowercased by the dispatcher.
Cookies are parsed out of the `cookie` header by this front, not passed separately.

**Acceptance:**
- [ ] `beginRequest` returns an epoch strictly greater than the previous call's on the same process.
- [ ] `requestPhase()` with no frame raises, and the message contains `request context is not established`.
- [ ] `beginRequest` called twice with no intervening `endRequest` raises, naming the path of the
      outer scope.
- [ ] `endRequest` with no frame raises.
- [ ] After `endRequest`, `requestEpoch()` raises — the key is erased, not blanked.
- [ ] Two sequential requests on one process see different epochs, and a `Cookies` handle minted in
      the first raises when used in the second. This is the keep-alive test and it is the first one
      in the file.
- [ ] `setPhase(RequestPhase.Action)` is visible to `requestPhase()` and to front 12's
      `rkCachePhase()` in the same process, asserted through front 12's own verb.

### Step 2 — `headers()`

```bp
pub type Headers(epoch: i64) {
    pub fn get(self: Self, name: string) -> ?string
    pub fn has(self: Self, name: string) -> bool
    pub fn names(self: Self) -> string[]
}

pub fn headers() -> Headers
```

`get` lowercases the name before lookup. A repeated header is joined with `", "`, which is what
RFC 9110 §5.3 says a recipient may do and what front 04's dispatcher already does for the query
string's repeated keys.

**Acceptance:**
- [ ] `headers().get("User-Agent")` and `headers().get("user-agent")` answer the same value.
- [ ] `headers().get("x-absent")` answers `null`, not `""` — this is the one place the front
      deliberately differs from `Request.header`, which is frozen at plain `string`.
- [ ] A header sent twice answers both values joined with `", "`.
- [ ] `headers()` in phase `Render` sets `isDynamic()`; in phase `Action` it does not.
- [ ] `headers()` in a `strict` frame raises, and the message names `headers` and the request path.
- [ ] `headers()` with no frame raises.

### Step 3 — `cookies()`

```bp
pub type CookieAttrs(
    path: string,
    domain: string,
    maxAge: i32,
    httpOnly: bool,
    secure: bool,
    sameSite: string,
)

pub fn cookieDefaults() -> CookieAttrs
pub fn serializeCookie(name: string, value: string, attrs: CookieAttrs) -> string

pub type Cookies(epoch: i64) {
    pub fn get(self: Self, name: string) -> ?string
    pub fn has(self: Self, name: string) -> bool
    pub fn names(self: Self) -> string[]
    pub fn set(self: Self, name: string, value: string, attrs: CookieAttrs) -> i32
    pub fn delete(self: Self, name: string) -> i32
}

pub fn cookies() -> Cookies
```

`cookieDefaults()` is `path="/"`, `domain=""`, `maxAge=0`, `httpOnly=true`, `secure=true`,
`sameSite="Lax"` — the restrictive end of every axis, because a default that has to be tightened is a
default that ships untightened. `delete` queues the same cookie with `Max-Age=0` and an empty value.

**Acceptance:**
- [ ] `cookies().get("theme")` reads a value out of the `cookie` request header, percent-decoded.
- [ ] A cookie header with no `=`, with a trailing `;`, and with spaces around the separator all parse
      without raising and without inventing entries.
- [ ] `serializeCookie("s", "a b", cookieDefaults())` answers
      `s=a%20b; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax` — asserted as a literal, because
      this string goes on the wire.
- [ ] `cookies().set(...)` in phase `Render` raises, and the message says a cookie may be set from a
      server action, a route handler or middleware.
- [ ] Two `set` calls for different names produce two lines in `endRequest()`'s blob; two `set` calls
      for the same name produce one, the later value.
- [ ] `cookies().delete("session")` produces a line with `Max-Age=0`.
- [ ] A `Cookies` handle used after `endRequest` raises rather than writing anywhere.

### Step 4 — `draftMode()` and `connection()`

```bp
pub type DraftMode(epoch: i64) {
    pub fn isEnabled(self: Self) -> bool
    pub fn enable(self: Self) -> i32
    pub fn disable(self: Self) -> i32
}

pub fn draftMode() -> DraftMode
pub fn connection() -> i32
pub fn isDynamic() -> bool
pub fn markDynamic(reason: string) -> i32
pub fn dynamicReason() -> string
```

`markDynamic` is the seam front 23 calls when a page reads `searchParams` (`§ 6` nota) and front 60
calls when it wants the reason recorded in the prerender report. `dynamicReason()` answers `""` when
the render is still static, and otherwise the name of the first function that made it dynamic — which
is what turns "this page is not being prerendered" from a mystery into a line of build output.

**Acceptance:**
- [ ] `draftMode().isEnabled()` is false with no cookie, false with a cookie whose signature does not
      verify, and true only for a cookie this server issued.
- [ ] A draft cookie whose signature is one character short answers false and does not raise.
- [ ] `enable()` with `rakun.draft.secret` unset raises, naming the property.
- [ ] `enable()` queues a `Set-Cookie` with `HttpOnly`, `Secure` and `SameSite=Lax`, and marks the
      request dynamic.
- [ ] `connection()` sets `isDynamic()` and `dynamicReason() == "connection"`.
- [ ] `dynamicReason()` names the **first** function to mark, not the last.
- [ ] `isDynamic()` is false for a render that touched none of them.

### Step 5 — `after()`

```bp
pub fn after(work: fn() -> i32) -> i32
```

**Acceptance:**
- [ ] Work registered with `after` has not run when `endRequest` is called, and has run within the
      test's wait budget afterwards.
- [ ] The deferred process can read `headers()` and `cookies().get(...)` — the frozen copy carries
      them — and `requestPhase()` answers `RequestPhase.After`.
- [ ] `cookies().set(...)` inside deferred work raises.
- [ ] `after(...)` inside deferred work raises.
- [ ] A deferred function that raises does not affect the response, and the failure is reported once
      to front 17 with the request id.
- [ ] A deferred function still running after `rakun.request.after.timeout` is killed, and the kill is
      logged.
- [ ] Deferred work outlives the frame: `requestEpoch()` in the parent process raises while the child
      is still running.

### Step 6 — `request_memo.bp`

```bp
pub fn memoKey(name: string, parts: Array<string>) -> string
pub fn memoize<T>(key: string, load: fn() -> T) -> T
pub fn preload<T>(key: string, load: fn() -> T) -> i32
pub fn memoHits() -> i32
pub fn memoMisses() -> i32
```

`memoKey` joins the parts with a separator that cannot occur in one and prefixes the name, the same
shape front 12's `cacheKey` uses — the difference is that this one does not hash, because a
request-scoped table is small and a readable key is worth more than a fixed width here.

**Acceptance:**
- [ ] Two `memoize` calls with one key run the loader once and answer the same value; `memoHits()` is
      1 and `memoMisses()` is 1. The second call does not evaluate its `load` argument at all — the
      loader increments an ETS counter and the counter reads 1.
- [ ] The same holds when the loader returns `@Task<T>`: the eager
      erlang lowering means the first call stores a value, so the second call is the resolved-value
      row of the table above and never re-runs it.
- [ ] Two requests with the same key run the loader twice — a memo that survives a request is a cache,
      and caches belong to front 12.
- [ ] `preload(k, load)` followed by `memoize(k, load)` runs the loader once, and the `memoize` call
      returns the preloaded value rather than starting a second load.
- [ ] `memoize` called while a `preload` for that key is still running blocks until the child answers
      and then returns the child's value — the pending row of the table, asserted with a loader that
      sleeps through `clock.sleep`.
- [ ] A loader that raises does not poison the key: the next `memoize` with that key runs it again.
- [ ] `memoize` outside a request raises.

### Step 7 — The dispatcher contract

This front owns no dispatcher. It owns the contract four of them must honour, and the contract is
three lines:

```bp
val epoch = beginRequest(RequestScope(
    id: random.uuidV4(),
    phase: RequestPhase.Handler,
    method: "GET",
    path: "/api/posts",
    query: "page=2",
    headersWire: wire,
    strict: false,
));
val body = runHandler();
val setCookies = endRequest();
```

**Acceptance:**
- [ ] `endRequest` runs on the failure path too — a handler that raises still tears the frame down,
      asserted by a second request on the same process seeing a clean frame.
- [ ] The `Set-Cookie` blob splits on `\n` into whole header values, and a cookie value containing a
      newline is impossible because `serializeCookie` percent-encodes it.
- [ ] `grep -n "fn percentEncode\|fn percentDecode\|fn hexValue" src/request_context.bp` is empty —
      the codec is std's `encoding`.
- [ ] Fronts 23, 24, 25 and 07 each call `beginRequest` with the phase their table row names; the
      assertion lives in this front's test as a table of phase-to-permission, so those fronts inherit
      it rather than restating it.

## Examples

- [`examples/request-context-example.bp`](./examples/request-context-example.bp) — the developer's
  view: a layout auth guard that reads a session cookie, a server action that writes a theme cookie
  and defers an analytics write, and a route handler that reads a header. One scenario carried
  through, matching `§ 23`'s own example.
- [`examples/request-memo-example.bp`](./examples/request-memo-example.bp) — the `React.cache`
  analogue: one `getPost` used by both `generateMetadata` and the page, loading once, plus the preload
  pattern from `§ 9`.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied (`tests/language/expected-failures.txt`, `docs.md:502-505`), so `cookies().set(name, value)` cannot fall back to `cookieDefaults()` and every call site repeats it | `request-context-example.bp`, every `.set(...)` call | pass `cookieDefaults()` explicitly, or a record built from it | apply a declared default at the call site when the argument is omitted |
| A record field cannot be assigned (`self.field = x` appears nowhere in the real libs and every record is immutable), so the frame cannot be a botopink value and must live in the host process dictionary | the whole `Mechanism` — every accessor is a host cell rather than a method on a `RequestFrame` record | keep the frame in `rakun_request_context.erl` and pass an epoch | a mutable binding form, or an explicit `@Cell<T>` builtin |

Three gaps front 01 already recorded are load-bearing here and are cited rather than re-filed: there is
no byte/binary type, so the signed draft cookie marshals through `string` at the host boundary; a std
module cannot call another std module, which is why this front imports `hash` and `encoding`
directly instead of reaching them through one façade; and there is no array destructuring in a binding, so every wire blob is
parsed with `split` and indexed with `.at(i)`.

## Test plan

`repository/rakun/test/request_context_test.bp` and `repository/rakun/test/request_memo_test.bp`, run
by `botopink test --target erlang` from `repository/rakun/`, and by
`zig build test-libs -- --target erlang --lib rakun` in the ecosystem gate.

This front is erlang-only. The commonJS row compiles the module — every host cell carries only an
`@External.Erlang` form, so a commonJS build emits calls into nothing — which means `botopink.json`'s
`targets` must not claim commonJS for these two modules and the commonJS cell of the gate must not run
them. The absence of a JS row is not a coverage hole: there is no browser request scope to test, and a
Node implementation would be a second mechanism to keep in step with the first for no consumer.

What the tests assert, grouped as the steps: frame lifecycle and epoch discipline (including the
keep-alive reuse case); header lookup, case-folding and repetition; cookie parsing, serialization as a
literal string, phase legality and queue de-duplication; draft-mode signature verification including
the forged and truncated cases; the dynamic marker and its first-reason rule; deferred work's
isolation, failure reporting and timeout; and memoization's hit/miss counts, per-request lifetime,
preload single-flight and non-poisoning on failure.

The "read outside a request raises" family is a runtime raise, not a compile error, so every one of
those cases **is** expressible as a test and every one of them is written — that is the point of
choosing a raise over a silent default.

## Definition of done

- `src/request_context.bp` and `src/request_memo.bp` compile with no `@External.Node` cell.
- `src/sidecars/rakun_request_context.erl` compiles under `erlc` with `-Werror`, and its module atom
  does not collide with any module rakun emits.
- The phase-to-permission table in *Mechanism* is written down here once and cited by fronts 12, 23,
  24, 25, 60, 63, 64, 65 and 66 rather than re-derived.
- Every accessor raises outside a request, and there is no property, flag, parameter or predicate that
  changes that.
- `repository/rakun/AGENTS.md` names `request_context.bp`, `request_memo.bp`, the frame key and the
  epoch rule.
- The front's tests are green on its assigned target — here, erlang.

