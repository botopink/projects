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
**Depends on:** 06 · **76 (soft)** — front 07 lands without it; see *Graceful shutdown and draining*
**Owns:** `modules/rakun-web/src/middleware.bp`, `cors.bp`, `error.bp`, `filter.bp`, `convention.bp` · `modules/rakun-web/test/middleware_test.bp`, `cors_test.bp`, `error_test.bp`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen · `modules/rakun-web/src/websocket/**`, which is front 20's · `modules/rakun-web/src/rules/**`, which is front 65's
**Reference:** `04-web.md § Aplicacoes Servlet (Spring MVC)` — Tratamento de Erros, CORS, API Versioning, Container Servlet Embutido · `04-web.md § Graceful Shutdown` · `NEXTJS-DOCS.md § 20. Middleware e Proxy` · <https://docs.spring.io/spring-boot/reference/web/servlet.html> · <https://nextjs.org/docs/app/building-your-application/routing/middleware> · <https://www.rfc-editor.org/rfc/rfc9457>
**Replaces:** `1.0.6-beta/04-web-middleware` + `1.0.7-beta/12-rakun-middleware` (merged)

---

## Why these two were one front

The 1.0.6 draft asked for Spring filters and interceptors. The 1.0.7 draft asked for a Next-style
`middleware.bp` at the project root. Read side by side they describe the same thing from two
directions: something that sees a request before the handler, may answer it instead, may change it,
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
That is the whole difference from the 1.0.7 draft, which proposed a separate invocation inside the SSR
pipeline.

`#[matcher(...)]` restricts the entry to matching paths. **The matcher grammar is front 65's**
(`/:path*`, globs, the negative-lookahead form from §20's own example), compiled once at startup.
Front 07 executes what front 65 compiles; it defines no pattern syntax of its own, and the two
READMEs say so in the same words.

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

botopink has no exception hierarchy. `throw` is legal only inside a `#[@result]` function and produces
an `Error(e)` **value**, not a raise (`libs/std/src/builtins.d.bp:52-54`); `try … catch` works over
`@Result` and nothing else. So `#[exceptionHandler("NotFoundException")]` as the 1.0.6 draft wrote it
has nothing to catch.

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

- a tagged raise → the matching handler's `ProblemDetail`, serialized as `application/problem+json`;
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
- [ ] `modules/rakun-web/` compiles and its tests run under `botopink test --target erlang`
- [ ] With rakun-web absent from a build, request handling is byte-identical to front 04's
- [ ] Three filters with orders −10, 0, 10 run in that order on the way in and the reverse on the way out
- [ ] Two filters with the same order run in registration order
- [ ] A filter that does not call `chain.next` short-circuits and the handler never runs
- [ ] A filter may read the response the chain returned and answer a different one
- [ ] `#[filter]` on a non-type fails at comptime with a located message

### Step 2 — `middleware.bp` and `Next`

**Acceptance:**
- [ ] `#[middleware]` on `pub fn middleware(req, chain)` registers one entry at order −50
- [ ] It runs after the built-in entries and before an application `#[filter]` with default order
- [ ] `Next.redirect("/login")` answers 307 with `Location: /login` and the handler never runs
- [ ] `Next.permanentRedirect` answers 308
- [ ] `Next.rewrite("/other")` reaches `/other`'s handler with the original URL unchanged in `req.path`
- [ ] `Next.pass()` and `chain.next(req)` produce identical responses for the same request
- [ ] The status-0 sentinel never appears on the wire under any of the above
- [ ] `#[matcher("/dashboard/:path*")]` restricts the entry; a non-matching path skips it entirely
- [ ] Two `#[middleware]` functions in one build fail at boot naming both — there is one middleware entry point

### Step 3b — `withHeader`

**Acceptance:**
- [ ] `withHeader(res, "X-A", "1")` produces exactly one `X-A: 1` on the wire
- [ ] Two `withHeader` calls with the same name, in any case spelling (`x-a` and `X-A`), produce one line carrying the second value
- [ ] `withHeaders` applies a list in order, with the same replace-by-name rule between its own entries
- [ ] The returned `Response` is the one passed in — `withHeader(res, …).status == res.status` and `.body == res.body`
- [ ] `withHeader(res, "Vary", "Origin")` after the compression entry set `Accept-Encoding` yields one `Vary` line carrying both tokens, deduplicated
- [ ] `withHeader(res, "Set-Cookie", …)` fails at boot naming front 62's list API — it never silently sets one cookie
- [ ] A list of three cookie lines from front 62's `endRequest` is written as three `Set-Cookie` lines
- [ ] A front that sets no header produces the same bytes as today

### Step 3 — CORS

**Acceptance:**
- [ ] With no policy, no CORS header is ever set
- [ ] A simple request from an allowed origin gets `Access-Control-Allow-Origin` echoing that origin, not `*`
- [ ] A request from a non-allowed origin gets no CORS header and the handler still runs
- [ ] An `OPTIONS` preflight is answered by the CORS entry with `Allow-Methods`, `Allow-Headers` and `Max-Age`, and the handler does not run
- [ ] A preflight for a path with no route answers 404
- [ ] `allowCredentials: true` with `allowedOrigins: ["*"]` fails at boot naming the combination
- [ ] `Vary: Origin` is set whenever the response depends on the origin
- [ ] `#[crossOrigin]` on a controller overrides the global policy for that controller's routes only

### Step 4 — Problem details and advice

**Acceptance:**
- [ ] `raiseProblem("order.not-found", "no order 42")` with a matching `#[exceptionHandler]` answers that handler's `ProblemDetail`
- [ ] The response content type is `application/problem+json`
- [ ] An unmatched raise answers 500 with `about:blank`, a digest, and no reason text in the body
- [ ] The digest appears in the log line for the same request
- [ ] Two advice types both contribute; a tag registered twice fails at boot naming both
- [ ] `rakun.web.problemdetails.enabled=true` fills an empty-bodied 404 from `Response.notFound()` with the standard shape; with it off, the body stays empty
- [ ] A handler's own `Response` with a body is never rewritten

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
| There is no typed raise and no user-visible catch of one. `throw` is legal only inside `#[@result]` and yields an `Error(e)` **value** (`builtins.d.bp:52-54`); `try … catch` works over `@Result` alone. So an exception handler cannot key on a type. | `examples/filter-chain-example.bp` — `raiseProblem("order.not-found", …)` and `#[exceptionHandler("order.not-found")]` key on a string tag | A host-declared raise plus a string tag, matched in the chain's `try`/`catch` | A typed raise (`throw` outside `#[@result]`) with `catch` binding by type, which would make `#[exceptionHandler(NotFoundError)]` the obvious spelling |
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
- **14-rakun-validation** supplies the violation report that the problem-detail entry renders as a
  422.

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

- [ ] `modules/rakun-web/` exists with a manifest, a root module, the five source files and the chain
      sidecar
- [ ] One chain, two entry points, with the documented order band and a test that asserts the whole
      sequence
- [ ] `withHeader`/`withHeaders` ship, replace by name case-insensitively, merge `Vary`, and refuse `Set-Cookie`
- [ ] CORS defaults deny, and `*` with credentials fails at boot
- [ ] Problem details are RFC 9457-shaped, `application/problem+json`, and never carry a raw reason
- [ ] `Accept` and `Accept-Encoding` are both negotiated with q-values; `br` is refused rather than faked
- [ ] No `Server` header by default
- [ ] Shutdown awaits front 76's `readinessDrained()`, drains, then hands to front 06 — in that order,
      asserted by two recorded timestamps
- [ ] `repository/rakun/AGENTS.md` documents the order band and the two entry points
- [ ] The front's tests are green on its assigned target

## Carried from 1.0.6-beta F04 web-middleware

Material present in `specs/1.0.6-beta/04-web-middleware/README.md` and absent from the text above. Code is verbatim; prose is quoted. *superseded by* marks a conscious replacement.

### 1. Filter/chain surface and the registration runtime (1.0.6 Step 1, Step 2)

```bp
// filter.bp
pub behavior Filter {
    fn doFilter(self: Self, request: Request, response: Response, chain: FilterChain) -> Response;
}

pub type FilterChain {
    pub fn doFilter(self: Self, request: Request) -> Response {
        // call next filter or handler
    }
}
```

```js
const filters = []; // [{ order, filter }]

export function registerFilter(order, filter) {
    filters.push({ order, filter });
    filters.sort((a, b) => a.order - b.order);
}
```

```bp
pub fn filter(comptime decl: @Decl) {
    @emit("val __rkFilter_" + decl.name + " = rkRegisterFilter(" + /* order */ "1, __rkMake_" + decl.name + "());");
    if (decl.kind != DeclKind.Type) decl.fail("#[filter] must annotate a type");
}
```

| 1.0.6 | above |
|---|---|
| `Filter.doFilter(request, response, chain)` | `Filter.handle(req, chain)` |
| `FilterChain.doFilter(request)` | `Chain.next(req)` |
| `rkRegisterFilter(order, instance)` | `rkRegisterFilter(name, order, { req, chain -> … })` |
| `request.withHeader(...)` (request mutation) | none — `withHeader` above is response-side only |
| `response.withHeader(...)` (method) | `withHeader(res, name, value)` (free fn) |

- Acceptance: "Filter can modify request before passing to chain" — no request-side header/attribute mutation exists above; a filter can only pass the `Request` it received or short-circuit.
- superseded by: *The chain* (ordered ETS table keyed `{Order, Seq}`; no response argument on the way in).

### 2. Global CORS via `#[configuration]`/`#[bean]`, and the CORS filter order (1.0.6 Step 3)

```bp
#[crossOrigin(origins: ["https://example.com"], methods: ["GET", "POST"])]
#[restController]
pub type MyController { }
```

```bp
#[configuration]
pub type CorsConfig {
    #[bean]
    pub fn corsConfiguration(self: Self) -> CorsConfiguration {
        return CorsConfiguration(
            allowedOrigins: ["https://example.com"],
            allowedMethods: ["GET", "POST", "PUT", "DELETE"],
            allowedHeaders: ["Content-Type", "Authorization"],
        );
    }
}
```

```bp
#[filter]
#[order(-100)]  // early in chain
pub type CorsFilter(config: CorsConfiguration) {
    pub fn doFilter(self: Self, request: Request, response: Response, chain: FilterChain) -> Response {
        val origin = request.header("Origin");
        if (self.config.isAllowed(origin)) {
            response = response.withHeader("Access-Control-Allow-Origin", origin);
            // add other CORS headers
        }
        return chain.doFilter(request);
    }
}
```

superseded by: *CORS* — `CorsPolicy` (adds `exposedHeaders`, `allowCredentials`, `maxAgeSeconds`) provided through `#[provides]`; `#[crossOrigin("https://example.com", "GET,POST")]` with comma-joined strings (*Language gaps*, row 3); CORS sits at −200 in the order band, −100 is the error boundary. `CorsConfiguration.isAllowed(origin)` has no named counterpart.

### 3. Exception handlers keyed on a type name (1.0.6 Step 4)

```bp
#[controllerAdvice]
pub type GlobalExceptionHandler {
    #[exceptionHandler("NotFoundException")]
    pub fn handleNotFound(self: Self, ex: NotFoundException) -> Response {
        return Response.status(404).body(ex.message);
    }

    #[exceptionHandler("ValidationException")]
    pub fn handleValidation(self: Self, ex: ValidationException) -> Response {
        return Response.status(400).body(ex.errors.join(", "));
    }
}
```

```bp
pub fn controllerAdvice(comptime decl: @Decl) {
    decl.methods.forEach({ m ->
        m.annotations.forEach({ a ->
            if (a.name == "exceptionHandler") {
                val exType = a.args[0];
                @emit("val __rkExceptionHandler_" + decl.name + "_" + m.name + " = rkRegisterExceptionHandler(\"" + exType + "\", { ex -> __rkMake_" + decl.name + "()." + m.name + "(ex) });");
            }
        });
    });
}
```

- Acceptance: "Handler's `Response` returned instead of 500" · "Multiple handlers for different exception types".
- superseded by: *RFC 9457 problem details, and what an "exception" is here* — tags are strings (`raiseProblem(tag, detail)`), handlers return `ProblemDetail`, and `Response.status(404).body(…)` is not on the frozen `Response` (`ok/json/created/withStatus/notFound/badRequest` only). The advice-walks-`decl.methods` emission shape is what *`#[controllerAdvice]` is a type-level decorator … the advice does the wiring* describes without code; `rkRegisterExceptionHandler` is not named above.

### 4. Problem-detail wire sample and field name (1.0.6 Step 5)

```bp
pub type ProblemDetail(
    type: string,        // URI reference
    title: string,       // short human-readable summary
    status: i32,         // HTTP status code
    detail: string,      // human-readable explanation
    instance: string,    // URI reference for specific occurrence
)
```

```json
{
    "type": "https://example.com/problems/not-found",
    "title": "Resource Not Found",
    "status": 404,
    "detail": "User 'alice' not found",
    "instance": "/api/users/alice"
}
```

- Acceptance: "`spring.mvc.problemdetails.enabled=true` equivalent" → `rakun.web.problemdetails.enabled` above.
- Field `type` is `typeUri` above; the JSON member on the wire must still be `type` (RFC 9457 §3.1) — the serializer mapping is not stated above.

### 5. Built-in filters (1.0.6 Step 6, Notes)

- `RequestIdFilter` — adds `X-Request-Id` header
- `LoggingFilter` — logs request/response
- `TimingFilter` — adds `X-Response-Time` header

```bp
#[filter]
#[order(-200)]
pub type RequestIdFilter {
    pub fn doFilter(self: Self, request: Request, response: Response, chain: FilterChain) -> Response {
        val requestId = request.header("X-Request-Id");
        if (requestId == "") {
            requestId = generateUuid();
        }
        val result = chain.doFilter(request.withHeader("X-Request-Id", requestId));
        return result.withHeader("X-Request-Id", requestId);
    }
}
```

- Acceptance: "`RequestIdFilter` adds/propagates request ID" · "`LoggingFilter` logs request method, path, status, duration" · "`TimingFilter` adds `X-Response-Time` header" · "Filters can be enabled/disabled via config".
- Notes: "Built-in filters: enabled by default, can be disabled via config".
- Coverage above: the order band has "request id" at −400 with no header name, no honour-incoming rule and no echo-on-response rule (`X-Request-Id` appears only in `examples/filter-chain-example.bp`; 17-rakun-logging stores the id via front 62). A per-request access-log line (method, path, status, duration) and an `X-Response-Time` header are in no 1.0.9 rakun front (75 ships the `http.server.requests` timer, no header). A per-filter enable/disable key set is not defined.

### 6. Module layout (1.0.6 Step 7)

```
modules/rakun-web/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── filter.bp
│   ├── cors.bp
│   ├── error.bp
│   └── builtin_filters.bp
└── test/
    ├── filter_test.bp
    ├── cors_test.bp
    └── error_test.bp
```

- Acceptance: "All tests pass on commonJS and Erlang" · "Example app uses `rakun-web` features".
- superseded by: **Owns** (`middleware.bp`, `convention.bp` instead of `builtin_filters.bp`; `middleware_test.bp` instead of `filter_test.bp`; sidecar `src/sidecars/rakun_chain.erl`) and *Test plan* (erlang-only, commonJS cell *skipped*). Wiring `examples/rakun` to rakun-web is not an acceptance item above.

## Carried from 1.0.7-beta F12 rakun-middleware

Source: `specs/1.0.7-beta/12-rakun-middleware/README.md`, `specs/1.0.7-beta/examples-bp.md § F12`, and
the `middleware.bp` snippet of `examples-bp.md § F22`. Items below are absent from the 1.0.9 text
above; items the merge already covers elsewhere are listed at the end with the front that holds them.

### Reference rows

| 1.0.7 reference | 1.0.9 status |
|---|---|
| `[Proxy](https://nextjs.org/docs/app/getting-started/proxy)` (header, line 3) | Cited only in `examples/middleware-convention-example.bp`; the README header lists `routing/middleware` and `NEXTJS-DOCS.md § 20`. 65 covers the proxy/rewrite content |

### Requirements and API names (quoted)

| # | 1.0.7 item | Where in 1.0.7 | Note |
|---|---|---|---|
| 1 | `pub type NextResponse { pub fn next() -> Response { return Response(status: 200, body: ""); } pub fn redirect(url: string) -> Response { return Response(status: 307, body: "").withHeader("Location", url); } pub fn rewrite(url: string) -> Response { return Response(status: 200, body: "").withHeader("X-Rewrite", url); } }` — the `NextResponse` name and a status-200 empty body as the continue sentinel | Step 1 | superseded by: 07 § `Next`, and why the sentinel is status 0 ("Zero is not a valid HTTP status, so it is a safe in-band sentinel") |
| 2 | Rewrite carried as a response header: `if (middlewareResponse.hasHeader("X-Rewrite")) { path = middlewareResponse.getHeader("X-Rewrite"); };` in `handleRequest(path, request)` "In ssr.bp" | Step 2 | superseded by: 07 § `Next` ("`rewrite` records the new path through a process-local signal (`rkChainSignal`) rather than smuggling it in a header, so nothing leaks to the client") |
| 3 | "The SSR pipeline checks for `middleware.bp` and invokes it before routing" — `val middlewareResponse = await invokeMiddleware(request); if (middlewareResponse.status == 307) { return middlewareResponse; };`; Gate "SSR pipeline integration works"; Blast radius "SSR pipeline updated to invoke middleware" | Step 2, Gate, Blast radius | superseded by: 07 § The `middleware.bp` convention ("That is the whole difference from the 1.0.7 draft, which proposed a separate invocation inside the SSR pipeline") |
| 4 | `pub val config = MiddlewareConfig(matcher: ["/dashboard/*", "/api/*"]);` — a `config` value beside `middleware`; acceptance "Middleware only runs on matched paths · Wildcard patterns work" | Step 3 | superseded by: 07 § The `middleware.bp` convention (`#[matcher("/dashboard/:path*")]` stacked on the fn) — the grammar (path globs, `:param`, `:path*`, negative lookahead) is 65 § `config.matcher`. A list of several matchers on one entry is not stated in 07 or 65 — open row |
| 5 | Location: "Single file at project root (or `app/middleware.bp`)" | Mechanism | superseded by: 22 Step 5 ("A `middleware.bp` at the **project root** — beside `botopink.json`, not under `appDir`") |
| 6 | Signature `#[@future] pub fn middleware(request: Request) -> @Future<Response>`; Note "Middleware is async because it may need to check auth (DB, external service)." | Mechanism, Notes | 07 pins `pub fn middleware(req: Request, chain: Chain) -> Response` (sync). Not explicitly rejected; on erlang `@Future<T>` lowers eagerly (23 § Mechanism), so the async marker carries nothing on the target 07 compiles for |
| 7 | "Runs before every request (SSR and API)" / acceptance "Middleware runs before route matching" | Mechanism, Step 2 | 07 § Where the chain hooks in: the chain runs inside `dispatch_http/5` for every request; a `Next.rewrite` re-targets the handler (Step 2 acceptance). Whether the chain runs *before* or *after* 22's `matchPath` is not stated in 07 — open row |
| 8 | `Response.withHeader("Location", url)` as a **method** on `Response`; test `res.getHeader("Location") == "/login"` and `middlewareResponse.hasHeader("X-Rewrite")` | Steps 1, 2, 4 | 07 § `withHeader`: free fn `withHeader(res, name, value)` over a frozen `Response`; header reads in tests go through `rkReplyHeaderValue` / `rkReplyHeadersContain` (examples). No `getHeader`/`hasHeader` on `Response` |
| 9 | "Tests pass on commonJS + erlang" | Step 4 | 07 § Test plan: erlang only; the commonJS cell reports *skipped* |
| 10 | Gate: "Commit on `fix/rakun-middleware`" | Gate | Branch-naming convention; 1.0.9 fronts name no branch |
| 11 | Logging middleware — `val start = nowMillis(); val response = NextResponse.next(); val duration = nowMillis() - start; print(request.method() + " " + request.path() + " — " + duration.toString() + "ms");` | `examples-bp.md § F12 · Middleware de logging` | No 07 example times a request; the metrics entry is +100 (11/75). Carried in the example file |

### Example material (quoted from `examples-bp.md § F12` and `§ F22 · middleware.bp`)

Carried verbatim to [`examples/next-response-middleware-carried-example.bp`](./examples/next-response-middleware-carried-example.bp): the auth middleware (redirect for `/dashboard`, JSON 401 for `/api/`), the logging middleware, and the F22 session-cookie gate. The auth redirect with a matcher is covered by [`examples/middleware-convention-example.bp`](./examples/middleware-convention-example.bp); the 401-for-API branch, the timing/`print` middleware and the `request.cookie("session")` accessor are not.

| 1.0.7 example | 1.0.9 counterpart |
|---|---|
| `import {Request, Response, NextResponse} from "rakun";` | `import {Filter, Chain, Next} from "rakun-web"; import {middleware, matcher} from "rakun-web";` |
| `return Response(status: 401, body: "{\"error\":\"Unauthorized\"}");` from middleware for `/api/*` | 07 § The chain: a filter that does not call `chain.next` short-circuits ("how a security filter answers 401"); 10 registers at −300 |
| `request.cookie("session")` | 62 Step 3 `cookies().get("session")`; 18 § Problem records that `request.cookie` "does not exist on a frozen interface" |
| `request.method()` / `request.path()` / `request.header("Authorization")` | `req.path`, `req.header("authorization")` (07 examples); `HttpMethod` on `Request` (`http.bp:12-20`) |

### Covered elsewhere (not carried)

- "Can redirect, rewrite, modify headers, set cookies" → 07 Step 2 (`Next.redirect`/`Next.rewrite`), 07 § `withHeader`, 62 phase table (`Middleware` row: `cookies().set/delete` yes).
- "Middleware runs on every request (unless matcher excludes it)." → 07 Step 2 acceptance ("a non-matching path skips it entirely").
- `NextResponse.redirect` → 307 + `Location` → 07 Step 2 acceptance.
- "Rakun has `#[filter]` decorators (from 1.0.6-beta F04)" → 07 § Why these two were one front.
