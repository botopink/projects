# Front 07 — The Filter Chain: Middleware, CORS, Problem Details

> **Amended 2026-09-21, on landing (rakun `3243f4b`, `modules/rakun-web` 0 → 83/0 on both rows).**
> Steps 1, 2, 3, 3b and 4 landed. Three deviations, each **forced** and each measured; two judgement
> calls upheld; one step re-routed.
>
> **Forced — `#[order("-100")]`, not `#[order(-100)]`.** A negative integer literal does not parse as
> a decorator argument: `#[mark(20)]` compiles, `#[mark(-20)]` reds `this token cannot appear here ·
> unexpected ``20``` with the caret on the **digits**. Every order in this front's band below zero was
> therefore unwritable. The marker takes a `string` and parses it through front 05's `toI32`; when
> the parser accepts the sign, the parameter becomes `n: i32` and the `toI32(` wrapper is deleted and
> nothing else in the library moves. Filed as `00 · 15-language-surface` step 4b.
>
> **Forced — `Filter.handle(self, req: WebRequest, chain: Chain)`, not `Request`.** A method on a
> host-supplied `behavior` does not dispatch on erlang (`{badkey,param}` / `{badfun, …}` — front 04's
> own two core reds), and a chain that cannot read a header cannot do CORS. The chain carries its own
> `WebRequest` built from the same scalars, reading through front 62's
> `headerLookup`/`headerNames`/`headerPresent`.
>
> **Forced — the erlang-only host cells in § Test plan.** There is no per-file target gate: `botopink
> test` compiles every `test/*.bp` on both rows and the only whitelist is per-**lib**. Both host
> halves ship, as fronts 06, 26 and 28 already do.
>
> **Corrected after measurement — `withHeaders` takes `#(string, string)[]`.** It shipped as a flat
> `["name","value",…]` array on the reasoning that a decorator argument cannot carry a tuple-array
> literal. That reasoning was borrowed from the `#[crossOrigin]` row and does not apply:
> `withHeaders` is a free function and is never written inside an annotation. Measured: the
> tuple-array **parameter type**, the **array literal of pair literals** and the **`.0`/`.1` reads**
> all compile and answer correctly on both rows. The pair type makes *a name with no value*
> **unrepresentable**, where the flat form could only refuse an odd-length array at run time — so
> that `@panic` and its cell are gone. `#[crossOrigin("https://a.test", "GET,POST")]` keeps its
> comma-joined strings; there the rule is real.
>
> **Upheld — a preflight from a disallowed origin answers 403 + `Vary: Origin`**, not a bare 204.
> The spec pins the no-route case and the allowed case and not this one; 403 is decision 67's
> reading.
>
> **Upheld — the matcher refuses `*`, `(`, `[`, `?`, `{`** with a message naming front 65, rather
> than guessing a semantics front 65 has not defined. It executes exactly the three forms both
> READMEs use in their own examples.
>
> **Re-routed — step 10's graceful shutdown is *not* blocked on front 76.** Front 76's
> `readinessDrained()` is the soft half this spec says to land without. The hard half — "close the
> listening socket, keep connection processes alive" — is `rakun_runtime.erl`'s socket, in
> `modules/rakun/`, which is **front 04's**. Front 07 established the distinction rather than
> reaching across, and step 10 now belongs to front 04.
>
> **Steps 5–9 not reached**, each with what it needs: 5 wants file IO from `src/` plus step 6's
> `Accept` branch (its resolution order is already fixed in `convention.bp`); 6 wants a
> `MessageConverter` behavior, a q-value parser and a media-type registry, with no blocker; 7 wants
> step 6's registry first; 8 and 9 have no blocker.

**Track:** B rakun
**Priority:** high — every cross-cutting concern in track B enters here; without a chain, security, metrics, compression, error shape and API versioning each need their own hook into a frozen dispatcher
**Target:** erlang (server)
**Wave:** 3
**Depends on:** 06 · `01-std/04-routing-lib` Step 8 (the `:param` grammar, `pattern`) · `01-std/01-std-lib-enablement` (the problem-detail body, std's JSON writers) · **76 (soft)** — front 07 lands without it; see *Graceful shutdown and draining*
**Owns:** `modules/rakun-web/src/middleware.bp`, `cors.bp`, `error.bp`, `filter.bp`, `convention.bp` · `modules/rakun-web/test/middleware_test.bp`, `cors_test.bp`, `error_test.bp`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen · `modules/rakun-web/src/websocket/**`, which is front 20's · `modules/rakun-web/src/rules/**`, which is front 65's
**Reference:** decision 116 rules 3 and 9 (std writes the JSON; `routing` owns the `:param` grammar) · `04-web.md § Aplicacoes Servlet (Spring MVC)` — Tratamento de Erros, CORS, API Versioning, Container Servlet Embutido · `04-web.md § Graceful Shutdown` · `NEXTJS-DOCS.md § 20. Middleware e Proxy` · <https://docs.spring.io/spring-boot/reference/web/servlet.html> · <https://nextjs.org/docs/app/building-your-application/routing/middleware> · <https://www.rfc-editor.org/rfc/rfc9457>

---

## One chain, two entry points

Spring's filters and interceptors and a Next-style `middleware.bp` at the project root describe the
same thing from two directions: something that sees a request before the handler, may answer it instead, may change it,
and sees the response on the way out.

They are not two mechanisms and must not become two. If `middleware.bp` were its own pipeline, a
request would pass through two orderings, a CORS header could be set in one and overwritten in the
other, and "does my filter run before the middleware" would have no answer. **There is one chain.**
Spring's `#[filter]` components and Next's `middleware.bp` are two *entry points* that register into
it, at different default orders, and the merged front says which is which.

| Entry point | Registers as | Default order | Suits |
|---|---|---|---|
| `#[filter]` on a component | one chain entry per component, ordered by `#[order(N)]` | `0` | reusable concerns owned by the framework or a library: CORS, compression, metrics, security |
| `#[middleware]` on `pub fn middleware` in `middleware.bp` | one chain entry | `-50` — after the built-ins, before the application's own filters | the application's own request gate: auth redirects, rewrites, locale |

Both receive `(req, chain)`, both may short-circuit, both see the response. The examples show the same
redirect written each way, which is the honest way to make the claim checkable.

## Problem

rakun's request path is: match a route, call the handler, write what it returns
(`runtime.mjs:188-196`). Nothing else happens. There is no place to put anything that is not a route
handler, and the frozen bootstrap (`src/bootstrap.bp:33-35`) hardcodes the dispatcher, so nothing can
be wrapped from outside either.

The consequences are concrete. A browser cannot call a rakun API from another origin, because no CORS
header is ever set. An error is a raw `500` with the reason as the body (`runtime.mjs:222-224`) — no
content type, no structure, and RFC 9457 has been the expected shape since 2023. There is no way to
add a request id, time a request, or refuse one before the handler runs. And `Response` is
`(status, body)` with no header field and no builder (`src/http.bp:45-73`), so even a filter that
wanted to set a header had nowhere to put it until front 04's per-request accumulator.

Shutdown is the least visible and the most expensive: a `SIGTERM` today drops in-flight requests. A
rolling deploy loses the requests in flight at every instance, every time.

## Current state

| Piece | Where | State |
|---|---|---|
| Request path | `runtime.mjs:188-196`; front 04's `dispatch_http/5` | match, call, write — no hook of its own |
| The one seam | front 04's `rakun_chain:run/6` branch in `dispatch_http/5` | front 04 delivers it; front 07 is the module it names |
| Reply headers | front 04's `rkSetReplyHeader`/`rkReplyHeaders` | delivered by 04, first consumed here |
| `Response` | `src/http.bp:45-73` — `ok/json/created/withStatus/notFound/badRequest` | frozen; **no** `withHeader`, no fluent builder |
| CORS | — | none |
| Error shape | 500 with the raw reason as the body | none |
| `#[filter]`, `#[order]`, `#[controllerAdvice]`, `#[exceptionHandler]` | — | none |
| `middleware.bp` convention | — | none |
| Content negotiation | — | none; every handler builds its own string |
| Graceful shutdown | — | none |
| `modules/rakun-web/` | — | the directory does not exist |

## Mechanism

### The chain

```bp
pub behavior Filter {
    fn handle(self: Self, req: Request, chain: Chain) -> Response;
}

pub type Chain(index: i32) {
    pub fn next(self: Self, req: Request) -> Response {
        return rkChainNext(self.index + 1, req);
    }
}
```

Entries live in an ordered ETS table keyed by `{Order, Seq}`, so ties break by registration order and
the table is walked, not rebuilt, per request. `rkChainNext(i, req)` runs entry *i*, or the route
handler when *i* is past the end. A filter that does not call `chain.next(req)` short-circuits, which
is how a security filter answers 401 without the handler ever running.

`#[filter]` is a type-level decorator, so it sees `decl.name` and `decl.annotations` and emits:

```bp
val __rkFilter_CorsFilter = rkRegisterFilter("CorsFilter", -100, { req, chain -> __rkMake_CorsFilter().handle(req, chain) });
```

The order comes from `#[order(-100)]` stacked above it, read out of `decl.annotations` exactly the way
`#[restController]` reads `#[route]` today (`decorators.bp:151`). Negative is early, positive is late,
and the built-ins occupy a documented band:

| Order | Entry |
|---|---|
| −400 | request id |
| −300 | security (front 10) |
| −250 | URL rules: redirects, rewrites, `basePath` (front 65) |
| −200 | CORS |
| −150 | API version resolution |
| −100 | problem-detail / error boundary |
| −50 | `middleware.bp` |
| 0 | application filters, default |
| +100 | metrics and tracing (front 11) |
| +200 | compression |
| +300 | server identification |

Compression is late on purpose: it must see the final body, including one an error handler produced.

### Where the chain hooks in

Front 04's `dispatch_http/5` calls `rakun_chain:run/6` when the module is loaded and the handler
directly when it is not. That branch is the entire integration surface. rakun-web ships
`modules/rakun-web/src/sidecars/rakun_chain.erl`; an application that does not depend on rakun-web
pays one `function_exported/3` per request and gets today's behaviour exactly.

### The `middleware.bp` convention

Next's `middleware.ts` is a file at the project root exporting `middleware` and an optional `config`
(`NEXTJS-DOCS.md § 20`). rakun's is `middleware.bp` exporting a `#[middleware]`-decorated function:

```bp
// middleware.bp, at the project root
#[middleware]
#[matcher("/dashboard/:path*")]
pub fn middleware(req: Request, chain: Chain) -> Response {
    val token = req.header("authorization");
    return if (token == "") Next.redirect("/login") else chain.next(req);
}
```

The decorator does the registration. The *file name* is a convention front 22's scanner honours — it
compiles `middleware.bp` whether or not it is named in a `pub mod` line — but the registration path is
the decorator, so there is one mechanism and the file convention is a discovery rule on top of it.

`#[matcher(...)]` restricts the entry to matching paths. **The `:param` grammar is the bundled library
`routing`'s** (`pattern`: `parsePattern`, `matchPattern`, `patternProblem` — `01-std/04-routing-lib`
Step 8, decision 116): a literal segment, `:param` and a trailing `:param*`, anything else refused by
name, parsed once at startup. The landed matcher (`modules/rakun-web/src/middleware.bp:60-110`,
`checkMatcher` / `matcherMatches`) and the CORS preflight's `routeMatches`
(`modules/rakun-web/src/filter.bp:545-565`) are the two copies that grammar replaces; both become
calls into `pattern` and are deleted. Globs and the negative-lookahead form of §20's example stay
front 65's rule engine, which front 07 executes; front 07 defines no pattern syntax of its own.

### `Next`, and why the sentinel is status 0

`Response` is frozen at `(status, body)` and has no header builder, so a middleware's three outcomes —
continue, redirect, rewrite — cannot all be expressed as an ordinary response.

```bp
pub type Next {
    pub fn pass() -> Response;                    // continue the chain
    pub fn redirect(url: string) -> Response;     // 307 + Location
    pub fn permanentRedirect(url: string) -> Response;  // 308
    pub fn rewrite(path: string) -> Response;     // same URL, different handler
}
```

`pass()` and `rewrite()` return `Response(status: 0, body: "")`. Zero is not a valid HTTP status, so it
is a safe in-band sentinel; the chain interprets it and it never reaches the wire. `rewrite` records
the new path through a process-local signal (`rkChainSignal`) rather than smuggling it in a header, so
nothing leaks to the client. `redirect` sets `Location` through front 04's accumulator and returns a
real 307.

`Next.pass()` rather than `Next.next()`: `Chain` already has `next`, and two `next`s a line apart
would be a reading hazard. Calling `chain.next(req)` and calling `Next.pass()` are the same outcome —
the first from inside a filter that wants the response back, the second from a middleware that does
not.

### `withHeader`: the response-header surface, and replace-by-name

`Response` is frozen at `(status, body)` with no header field and no builder (`src/http.bp:45-73`),
and front 04's `rkSetReplyHeader/2` is a per-request accumulator, not something a caller composes
with. Fronts 18 (session cookies), 21 (HAL `Content-Type` and `Link`) and 62 (`endRequest`) all need a
composable one, so front 07 provides it and [`contracts.md`](../../contracts.md) §5c records it as this
front's deliverable:

```bp
pub fn withHeader(res: Response, name: string, value: string) -> Response;
pub fn withHeaders(res: Response, pairs: #(string, string)[]) -> Response;
```

`withHeader` writes through `rkSetReplyHeader/2` and returns the same `Response` unchanged, so it
chains without a new record type and without touching the frozen one. Name matching is
**case-insensitive**, per RFC 9110 §5.1.

**The semantics are replace-by-name, and every caller must know it.** A second `withHeader` with the
same name replaces the first; it does not append, and the chain never emits two lines for one name.
That is right for `Content-Type`, `Location`, `Cache-Control` and every other single-valued header,
and it is wrong for exactly two: `Set-Cookie` and `Vary`.

- **`Set-Cookie`** is the one header where a replace would lose data, so it is not routed through
  `withHeader` at all. Front 62's `endRequest` returns its cookies as a **list of lines**, which the
  chain writes verbatim, one `Set-Cookie:` per element. A front that tries to set a cookie through
  `withHeader` sets one cookie and silently drops the rest — so `withHeader("Set-Cookie", …)` is a
  **boot-time rejection** naming the list API instead.
- **`Vary`** is merged rather than replaced: the CORS entry adds `Origin`, the compression entry adds
  `Accept-Encoding`, and both must survive. `withHeader("Vary", …)` therefore unions the
  comma-separated token set, which is the one documented exception to replace-by-name.

### CORS

```bp
pub type CorsPolicy(
    allowedOrigins: string[],
    allowedMethods: string[],
    allowedHeaders: string[],
    exposedHeaders: string[],
    allowCredentials: bool,
    maxAgeSeconds: i32,
)
```

Configured globally through `#[provides]`-ing a `CorsPolicy`, or per controller with
`#[crossOrigin("https://example.com", "GET,POST")]` — comma-joined strings rather than array
arguments, because a decorator argument is a raw lexeme typed by the signature
(`builtins.d.bp:447-451`) and an array literal there is unverified.

The defaults are the restrictive ones: no origin is allowed until one is named, `*` with
`allowCredentials: true` is **rejected at boot** rather than silently downgraded, and a preflight for
a route that does not exist answers 404 and not a permissive 204. A `OPTIONS` preflight is answered by
the CORS entry without reaching the handler.

### RFC 9457 problem details, and what an "exception" is here

botopink has no exception hierarchy. `throw` is legal only where the return carries a `@Result` and produces
an `Error(e)` **value**, not a raise (`libs/std/src/builtins.d.bp:52-54`); `try … catch` works over
`@Result` and nothing else. So a type-keyed `#[exceptionHandler("NotFoundException")]` has nothing to catch.

What exists on the BEAM is a raise, and rakun-web gives it one shape:

```bp
pub type ProblemDetail(
    typeUri: string,
    title: string,
    status: i32,
    detail: string,
    instance: string,
)

// raises {rakun_problem, Tag, Detail} — caught by the error entry
pub declare fn raiseProblem(tag: string, detail: string) -> void;
```

`#[controllerAdvice]` is a type-level decorator; `#[exceptionHandler("order.not-found")]` is a
method-level placement marker, and the advice does the wiring, because a method `@Decl` carries no
owner (see front 06's gap table). The tag is a string, not a type name, and the README says so rather
than pretending otherwise.

The error entry sits at order −100 with a `try`/`catch` around `chain.next(req)`:

- a tagged raise → the matching handler's `ProblemDetail`, serialized as `application/problem+json`
  with std's `json.quote` / `json.object` (decision 116 — the landed private `jsonEscape`,
  `modules/rakun-web/src/error.bp:131`, escapes no control character but `\n` `\r` `\t` and is
  deleted);
- an untagged raise → a 500 problem detail carrying a correlation digest, with the full reason logged
  under that digest (front 17) and **never** in the body;
- a handler-returned `Response` → passed through untouched unless
  `rakun.web.problemdetails.enabled=true`, in which case a bare 4xx/5xx with an empty body is filled
  in with the standard problem shape for that status.

`typeUri` defaults to `about:blank` per RFC 9457 §4.2.1, `title` to the status reason phrase, and
`instance` to the request path.

### Static error pages

When nothing produced a response and no advice matched, the error entry looks for
`<rakun.web.error-path>/404.html`, then `<…>/4xx.html`, then `<…>/5xx.html` — the resolution order of
`04-web.md § Paginas de Erro Customizadas`. A client that sent `Accept: application/json` gets the
problem detail regardless; the static page is for a browser.

### Content negotiation

```bp
pub behavior MessageConverter {
    fn mediaType(self: Self) -> string;
    fn canWrite(self: Self, typeName: string) -> bool;
    fn write(self: Self, value: string) -> string;
    fn canRead(self: Self, typeName: string) -> bool;
    fn read(self: Self, body: string) -> string;
}
```

`#[messageConverter]` registers one. The registry is keyed by media type and consulted twice: on the
way in, to decode a request body by `Content-Type`; on the way out, to pick an encoding from `Accept`
by q-value, falling back to the first registered converter that can write. JSON ships in the box;
`text/plain` ships as the identity converter. An `Accept` that matches nothing answers 406.

The converters take and return `string` because botopink has no runtime type descriptor to dispatch
on: a handler already returns a `Response` whose body is a string, so the converter's real job is
choosing the media type and the shape, not serializing an arbitrary value. This is a narrowing of
Spring's `HttpMessageConverter` and the README says which part is missing and why.

### `WebCustomizer`

```bp
pub behavior WebCustomizer {
    fn customize(self: Self, reg: WebRegistry);
}
```

`#[webCustomizer]` on a component registers it; every customizer runs once at boot, in `#[order]`
order, and `WebRegistry` exposes `addConverter`, `addCorsMapping`, `addFilter` and `addFormatter`.
This is Spring's `WebMvcConfigurer` (`04-web.md § Personalizando MVC`) and it exists so an application
can add to the chain without a decorator on every piece.

### API versioning

`rakun.web.apiversion.default=1.0.0` plus one of `rakun.web.apiversion.use.header=X-Version`,
`.use.query=v` or `.use.path-segment=1`. The version entry resolves it into the request scope (front
06's `Request` scope, read by front 62), and a route registered for an older version answers with a
`Deprecation` and a `Sunset` header when the configuration declares one. An unparsable or unknown
version is a 400 problem detail naming the versions that do exist.

### Compression and server identification

`Accept-Encoding` is parsed with q-values. rakun compresses with `gzip` and `deflate` — both are
`zlib` in erts, always present. **Brotli is refused, not faked**: there is no `br` implementation in
OTP, so `rakun.server.compression.algorithms` naming `br` fails at boot with a message saying a NIF
would be required. Compression applies above `rakun.server.compression.min-response-size` (default
2048 bytes) and only to media types in `rakun.server.compression.mime-types` (text, JSON, XML,
JavaScript, CSS by default). `Vary: Accept-Encoding` is always set when a body could have been
compressed, whether or not it was.

Server identification inverts Next's default. `poweredByHeader` is `true` upstream; rakun sends **no**
`Server` header unless `rakun.server.server-header` is set, because a version string in a response is
information a client never needs and an attacker sometimes does. The house rule is the most
restrictive default with no knob to weaken it silently — here the knob only makes it louder.

### Graceful shutdown and draining

`04-web.md § Graceful Shutdown` gives the sequence, and the ordering matters more than the timeout.
**Shutdown is one call spanning two fronts**, recorded in [`contracts.md`](../../contracts.md) §5c: front
76 owns the readiness state, front 07 owns the drain, and neither re-implements the other's half.

1. **Front 07 awaits front 76's `readinessDrained()`.** That call flips readiness false and returns
   after `rakun.lifecycle.pre-drain-period` (default 5000 ms) — long enough for a load balancer to
   observe the probe and stop sending. Front 07 does not implement the wait, does not read the
   readiness state, and does not own the period; it awaits the call and nothing else. Front 76 does not
   drain.
2. Stop accepting: close the listening socket, keep every connection process alive.
3. Wait for in-flight requests, up to `rakun.lifecycle.timeout-per-shutdown-phase` (default 20s). Past
   the timeout, the remaining connection processes are killed and counted in the shutdown log.
4. Hand off to front 06's `#[preDestroy]` pass.
5. Stop the node with front 06's exit code.

Steps 1 and 2 are in that order for the only reason that matters: a balancer must stop sending before
the socket stops accepting, or the drain simply moves the dropped requests to the balancer.

**The dependency is soft, so front 07 can land first.** Front 76 depends on fronts 11 and 10 and
arrives later, so `readinessDrained()` is declared by front 07 as a host cell that is a **no-op
returning immediately** when `code:ensure_loaded(rakun_probes)` fails — the same
`function_exported/3` shape front 04 uses for the chain seam. With front 76 absent the sequence is
steps 2–5 and the shutdown tests still assert their own half; with front 76 present the pre-drain
period is honoured and the ordering test below becomes meaningful. What front 07 must never do is grow
its own readiness flag to fill the gap.

`rakun.server.shutdown=immediate` skips steps 1, 2 and 3, matching Spring's own escape — and it is the
one place this front has a weakening switch, because "kill it now" is a legitimate operational request
and not a way around a rule.

## Steps

### Step 1 — `modules/rakun-web/` and the chain

Create the module (`botopink.json` with `"target": "erlang"`, `src/root.bp`), the chain table, the
`Filter` behavior, `Chain`, `#[filter]`, `#[order]`, and `rakun_chain:run/6`.

**Acceptance:**
- [x] `modules/rakun-web/` compiles and its tests run under `botopink test --target erlang` — held: `count.sh modules/rakun-web erlang` 104/0
- [x] With rakun-web absent from a build, request handling is byte-identical to front 04's — held: `modules/rakun/src/sidecars/rakun_runtime.erl` `dispatch_http/5` — `rakun_chain:run/6` absent → the direct `handle/6` call (code; no cell reaches it)
- [x] Three filters with orders −10, 0, 10 run in that order on the way in and the reverse on the way out — held: `test/middleware_test.bp` "three filters at -10, 0 and 10 run in that order in and the reverse out"
- [x] Two filters with the same order run in registration order — held: `test/middleware_test.bp` "two entries at the same order run in registration order"
- [x] A filter that does not call `chain.next` short-circuits and the handler never runs — held: `test/middleware_test.bp` "a filter that does not call chain.next short-circuits…"
- [x] A filter may read the response the chain returned and answer a different one — held: `test/middleware_test.bp` "a filter may read the response the chain returned…"
- [x] `#[filter]` on a non-type fails at comptime with a located message — held: `src/convention.bp` `filter` — `decl.fail("#[filter] must annotate a type")` (code; a compile failure has no cell)

### Step 2 — `middleware.bp` and `Next`

**Acceptance:**
- [x] `#[middleware]` on `pub fn middleware(req, chain)` registers one entry at order −50 — held: `test/decorators_test.bp` "#[middleware] registers one entry at -50 with its matcher"
- [x] It runs after the built-in entries and before an application `#[filter]` with default order — held: `test/middleware_test.bp` "it runs after a built-in and before an application filter"
- [x] `Next.redirect("/login")` answers 307 with `Location: /login` and the handler never runs — held: `test/middleware_test.bp` "redirect answers 307 with Location…"
- [x] `Next.permanentRedirect` answers 308 — held: `test/middleware_test.bp` "permanentRedirect answers 308"
- [x] `Next.rewrite("/other")` reaches `/other`'s handler with the original URL unchanged in `req.path` — held: `test/middleware_test.bp` "rewrite reaches the other handler with the original URL unchanged"
- [x] `Next.pass()` and `chain.next(req)` produce identical responses for the same request — held: `test/middleware_test.bp` "pass() and chain.next(req) produce identical responses"
- [x] The status-0 sentinel never appears on the wire under any of the above — held: `test/middleware_test.bp` "the status-0 sentinel never reaches the wire"
- [x] `#[matcher("/dashboard/:path*")]` restricts the entry; a non-matching path skips it entirely — held: `test/middleware_test.bp` "a non-matching path skips the entry entirely"
- [x] the matcher and the CORS preflight both go through `routing`'s `matchPattern`; `grep -rn "fn matcherMatches\|fn routeMatches\|fn checkMatcher" modules/rakun-web/src` is empty — held: `src/middleware.bp` `matcherAdmits` and `src/filter.bp` `routeAdmits` call `matchPattern`; the grep is empty
- [x] Two `#[middleware]` functions in one build fail at boot naming both — there is one middleware entry point — held: `test/middleware_test.bp` "two #[middleware] functions fail naming both"

### Step 3b — `withHeader`

**Acceptance:**
- [x] `withHeader(res, "X-A", "1")` produces exactly one `X-A: 1` on the wire — held: `test/middleware_test.bp` "one call produces exactly one line"
- [x] Two `withHeader` calls with the same name, in any case spelling (`x-a` and `X-A`), produce one line carrying the second value — held: `test/middleware_test.bp` "a second call with the same name in any case spelling replaces the first"
- [x] `withHeaders` applies a list in order, with the same replace-by-name rule between its own entries — held: `test/middleware_test.bp` "a pair list applies in order with the same replace rule"
- [x] The returned `Response` is the one passed in — `withHeader(res, …).status == res.status` and `.body == res.body` — held: `test/middleware_test.bp` "the returned Response is the one passed in"
- [x] `withHeader(res, "Vary", "Origin")` after the compression entry set `Accept-Encoding` yields one `Vary` line carrying both tokens, deduplicated — held: `test/middleware_test.bp` "Vary is unioned, deduplicated, not replaced"
- [x] `withHeader(res, "Set-Cookie", …)` fails at boot naming front 62's list API — it never silently sets one cookie — held: `test/middleware_test.bp` "Set-Cookie is refused by name…" (refusal names `writeCookies(blob)`)
- [x] A list of three cookie lines from front 62's `endRequest` is written as three `Set-Cookie` lines — held: `test/middleware_test.bp` "three lines from endRequest are written as three Set-Cookie lines"
- [x] A front that sets no header produces the same bytes as today — held: `test/middleware_test.bp` "a front that sets none produces no head at all"

### Step 3 — CORS

**Acceptance:**
- [x] With no policy, no CORS header is ever set — held: `test/cors_test.bp` "with no policy, no CORS header is ever set"
- [x] A simple request from an allowed origin gets `Access-Control-Allow-Origin` echoing that origin, not `*` — held: `test/cors_test.bp` "a simple request from an allowed origin echoes that origin…"
- [x] A request from a non-allowed origin gets no CORS header and the handler still runs — held: `test/cors_test.bp` "a non-allowed origin gets no CORS header and the handler still runs"
- [x] An `OPTIONS` preflight is answered by the CORS entry with `Allow-Methods`, `Allow-Headers` and `Max-Age`, and the handler does not run — held: `test/cors_test.bp` "an allowed preflight answers 204…" + "max-age, allowed headers and exposed headers…"
- [x] A preflight for a path with no route answers 404 — held: `test/cors_test.bp` "a preflight for a path with no route answers 404"
- [x] `allowCredentials: true` with `allowedOrigins: ["*"]` fails at boot naming the combination — held: `test/cors_test.bp` "the wildcard with credentials fails at boot naming the combination"
- [x] `Vary: Origin` is set whenever the response depends on the origin — held: `test/cors_test.bp` asserts `Vary: Origin` on allowed, refused and preflight responses
- [x] `#[crossOrigin]` on a controller overrides the global policy for that controller's routes only — held: `test/decorators_test.bp` "#[crossOrigin] registers a mapping keyed by the #[route] prefix" + `test/cors_test.bp` "a mapping applies to its controller's paths and to no others"

### Step 4 — Problem details and advice

**Acceptance:**
- [x] `raiseProblem("order.not-found", "no order 42")` with a matching `#[exceptionHandler]` answers that handler's `ProblemDetail` — held: `test/error_test.bp` "a tagged raise with a matching handler answers that handler's ProblemDetail"
- [x] The response content type is `application/problem+json` — held: `test/error_test.bp` "a problem response carries application/problem+json"
- [ ] A `detail` carrying U+0001 and a `"` yields a body std's `json.decode` answers `Ok` for; `grep -n "fn jsonEscape" modules/rakun-web/src/error.bp` is empty
- [x] An unmatched raise answers 500 with `about:blank`, a digest, and no reason text in the body — held: `test/error_test.bp` "an unmatched tagged raise answers 500 with about:blank, a digest, and no reason"
- [x] The digest appears in the log line for the same request — held: `test/error_test.bp` "the digest in the body is the digest in the log line"
- [x] Two advice types both contribute; a tag registered twice fails at boot naming both — held: `test/error_test.bp` "two advice types both contribute" + "a tag registered twice fails naming both owners"
- [x] `rakun.web.problemdetails.enabled=true` fills an empty-bodied 404 from `Response.notFound()` with the standard shape; with it off, the body stays empty — held: `test/error_test.bp` "problemdetails.enabled fills an EMPTY-bodied 404 and leaves it empty when off"
- [x] A handler's own `Response` with a body is never rewritten — held: `test/error_test.bp` "a handler's own 4xx WITH a body is never rewritten, property or not"

### Step 5 — Static error pages

**Acceptance:**
- [ ] A 404 with `Accept: text/html` and an `error/404.html` present serves that file
- [ ] With only `error/4xx.html` present, a 404 serves it
- [ ] `Accept: application/json` serves the problem detail even when the page exists
- [ ] A missing page directory is not an error; the problem detail is served

### Step 6 — Content negotiation

**Acceptance:**
- [ ] `Accept: application/json` selects the JSON converter; `text/plain` selects the identity one
- [ ] `Accept: application/json;q=0.5, text/plain;q=0.9` selects `text/plain`
- [ ] `Accept: */*` selects the first registered converter that can write
- [ ] An `Accept` matching nothing answers 406
- [ ] A request body with `Content-Type: application/json` reaches the handler decoded by the JSON converter
- [ ] `#[messageConverter]` registers an application converter and it wins for its media type

### Step 7 — `WebCustomizer`

**Acceptance:**
- [ ] A `#[webCustomizer]` component's `customize` runs once at boot
- [ ] Two customizers run in `#[order]` order
- [ ] A converter, a CORS mapping and a filter added from a customizer all take effect
- [ ] A customizer that raises fails the boot naming the component

### Step 8 — API versioning

**Acceptance:**
- [ ] `use.header=X-Version` resolves the version from that header
- [ ] `use.path-segment=1` resolves `/v2/users` to version `2` and matches the route as `/users`
- [ ] A request with no version gets `apiversion.default`
- [ ] An unknown version answers 400 naming the known versions
- [ ] A deprecated version's response carries `Deprecation` and `Sunset`

### Step 9 — Compression and server identification

**Acceptance:**
- [ ] `Accept-Encoding: gzip` on a 4 KB JSON response yields a gzipped body with `Content-Encoding: gzip` and a correct `Content-Length`
- [ ] `Accept-Encoding: deflate` yields deflate
- [ ] `Accept-Encoding: gzip;q=0, deflate` yields deflate
- [ ] A 100-byte response is not compressed
- [ ] An `image/png` response is not compressed
- [ ] `Vary: Accept-Encoding` is set on every compressible response, compressed or not
- [ ] Configuring `br` fails at boot with a message naming the missing NIF
- [ ] No `Server` header is sent by default; setting `rakun.server.server-header` sends exactly that value

### Step 10 — Graceful shutdown

**Acceptance:**
- [ ] `SIGTERM` awaits front 76's `readinessDrained()` before closing the listening socket
- [ ] **One run records two timestamps — when readiness went false, and when the socket stopped accepting — and asserts the first is strictly earlier than the second by at least `rakun.lifecycle.pre-drain-period`** ([`contracts.md`](../../contracts.md) §5c)
- [ ] Front 07 contains no readiness flag of its own; the state is read from front 76 or not at all
- [ ] With front 76 absent, `readinessDrained()` returns immediately and steps 2–5 still run in order
- [ ] A request in flight at `SIGTERM` completes and its response reaches the client
- [ ] A new connection after `SIGTERM` is refused
- [ ] A request still running at the timeout is killed and counted in the shutdown log line
- [ ] Front 06's `#[preDestroy]` pass runs after the drain, not before
- [ ] `rakun.server.shutdown=immediate` skips the drain

## Examples

- [`examples/filter-chain-example.bp`](./examples/filter-chain-example.bp) — the Spring entry point:
  a request-id filter, a controller advice mapping a tagged problem to RFC 9457, per-controller CORS,
  and the handler that raises.
- [`examples/middleware-convention-example.bp`](./examples/middleware-convention-example.bp) — the
  Next entry point: `middleware.bp` with a matcher, an auth redirect and a rewrite, plus the same
  redirect written as a `#[filter]` so the two forms can be compared line for line.

## Language gaps

The milestone register is [`language-gaps.md`](../../language-gaps.md); the rows below are this front's entries in it, and the cross-front wire formats they touch are in [`contracts.md`](../../contracts.md).

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| There is no typed raise and no user-visible catch of one. `throw` is legal only where the return carries a `@Result` and yields an `Error(e)` **value** (`builtins.d.bp:52-54`); `try … catch` works over `@Result` alone. So an exception handler cannot key on a type. | `examples/filter-chain-example.bp` — `raiseProblem("order.not-found", …)` and `#[exceptionHandler("order.not-found")]` key on a string tag | A host-declared raise plus a string tag, matched in the chain's `try`/`catch` | A typed raise (`throw` with no `@Result` in the return) with `catch` binding by type, which would make `#[exceptionHandler(NotFoundError)]` the obvious spelling |
| A decorator cannot wrap the body it annotates (`decorators.bp:48-240`). `#[filter]` therefore registers a component rather than decorating a function in place, and `#[exceptionHandler]` is wired by the type-level `#[controllerAdvice]` rather than by itself. | both examples | Type-level decorator does the wiring; method-level marker checks placement | `decl.wrapBody(…)`, shared with fronts 06, 08 and 10 |
| A decorator argument is a raw lexeme typed by the decorator's signature (`builtins.d.bp:447-451`); an array literal in that position is unverified. | `examples/filter-chain-example.bp`, `#[crossOrigin("https://example.com", "GET,POST")]` | Comma-joined strings, split by the decorator | Typed list arguments in an annotation, so `#[crossOrigin(origins: ["…"], methods: ["GET"])]` reads as it does upstream |

## Test plan

`modules/rakun-web/test/middleware_test.bp`, `cors_test.bp` and `error_test.bp`, run with
`botopink test --target erlang` from `modules/rakun-web/`, and in the gate through
`zig build test-libs -- --target erlang`. The module's own `botopink.json` declares
`"target": "erlang"` and `"targets": ["erlang"]`, so the commonJS cell reports *skipped* rather than
red — this is a server module and there is nothing for the client row to run.

Ordering is the property most worth testing and the easiest to test badly. `middleware_test.bp`
registers filters that append their name to an ETS list on the way in and on the way out, then asserts
the whole sequence as one string — `a>b>c|handler|c<b<a` — rather than asserting each filter ran. A
reordering that per-filter tests would miss shows up immediately.

Shutdown is the one case needing a live socket: the test starts a listener on an ephemeral port, holds
a request open with a handler that waits on a message, sends the shutdown, releases the handler, and
asserts both that the held request completed and that a connection attempted in between was refused.

Because the front is erlang-only, none of this runs on the commonJS row, and the `middleware.bp`
convention has no client half — front 27's `Link` prefetch reads the route table, not the chain.

## Adjacent fronts

- **65-rakun-url-rules** *defines* matchers, redirects, rewrites, `basePath` and `trailingSlash`;
  front 07 *executes* them as a chain entry at order −250. Front 07 invents no pattern syntax.
- **63-rakun-navigation-signals** consumes the redirect and rewrite outcomes this chain produces.
- **62-rakun-request-context** reads the request scope this chain populates (request id, resolved API
  version, negotiated media type). Front 07 writes it and defines no accessor.
- **10-rakun-security-auth** registers at order −300 and is the first entry that can answer 401.
- **11-rakun-actuator** registers the metrics and tracing entry at +100.
- **76-rakun-actuator-security-probes** owns the readiness state and `readinessDrained()`; front 07
  awaits it and owns the drain. One call, two fronts, neither re-implementing the other
  ([`contracts.md`](../../contracts.md) §5c).
- **18-rakun-session**, **21-rakun-hateoas** and **62-rakun-request-context** are the consumers of
  `withHeader` ([`contracts.md`](../../contracts.md) §5c); front 62's `endRequest` returns `Set-Cookie` as
  a list of lines because `withHeader` replaces by name.
- **20-rakun-websocket** owns `modules/rakun-web/src/websocket/**` and adds no chain entry — an
  upgrade leaves the HTTP chain before the handler.
- The bundled library `validation` (`01-std/06-validation-lib`, formerly front 14's
  `rakun-validation`) supplies the violation report that the problem-detail entry renders as a 422.

## Contradictions with fronts.md

1. **Resolved:** `modules/rakun-web/botopink.json` and `src/root.bp` belong to **F07**, the
   lowest-numbered front in that module. F20 appends its `pub mod websocket;` line and F65 its
   `pub mod rules;`, in front-number order, reordering nothing.
2. **Resolved:** the chain host cells live in `modules/rakun-web/src/sidecars/rakun_chain.erl`, per the
   now-mandated `src/sidecars/rakun_<name>.erl` form.
3. The row lists `convention.bp` but not the `middleware.bp` *file* convention's scanner hook, which
   lives in front 22. Front 07 assumes front 22 compiles a root `middleware.bp`; if that is not front
   22's reading, the two need to agree before either lands.

## Definition of done

- [x] `modules/rakun-web/` exists with a manifest, a root module, the five source files and the chain
      sidecar — held: `modules/rakun-web/botopink.json`, `src/root.bp`, `src/{filter,error,middleware,cors,convention}.bp`, `src/sidecars/rakun_chain.erl`
- [x] One chain, two entry points, with the documented order band and a test that asserts the whole
      sequence — held: `test/middleware_test.bp` "the order band is one table and every built-in sits in it"
- [x] `withHeader`/`withHeaders` ship, replace by name case-insensitively, merge `Vary`, and refuse `Set-Cookie` — held: `test/middleware_test.bp` withHeader/withHeaders/Vary/Set-Cookie cells
- [x] CORS defaults deny, and `*` with credentials fails at boot — held: `test/cors_test.bp` "the default denies every origin" + "the wildcard with credentials fails at boot…"
- [x] Problem details are RFC 9457-shaped, `application/problem+json`, and never carry a raw reason — held: `test/error_test.bp` "the defaults are RFC 9457's" + "…no reason" + "application/problem+json"
- [ ] `Accept` and `Accept-Encoding` are both negotiated with q-values; `br` is refused rather than faked
- [ ] No `Server` header by default
- [ ] Shutdown awaits front 76's `readinessDrained()`, drains, then hands to front 06 — in that order,
      asserted by two recorded timestamps
- [x] `repository/rakun/AGENTS.md` documents the order band and the two entry points — held: `repository/rakun/AGENTS.md` § The filter chain (order band table, two entry points)
- [x] The front's tests are green on its assigned target — held: `count.sh modules/rakun-web erlang` 104/0
