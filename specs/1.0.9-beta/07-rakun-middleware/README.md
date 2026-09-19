# Front 07 — The Filter Chain: Middleware, CORS, Problem Details

**Track:** B rakun
**Priority:** high — every cross-cutting concern in track B enters here; without a chain, security, metrics, compression, error shape and API versioning each need their own hook into a frozen dispatcher
**Target:** erlang (server)
**Wave:** 3
**Depends on:** 06
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

`04-web.md § Graceful Shutdown` gives the sequence and the ordering matters more than the timeout:

1. **Readiness goes false first.** A load balancer must stop sending before the socket stops
   accepting, or the drain simply moves the dropped requests to the balancer. Front 76 owns the
   readiness state; front 07 flips it.
2. Stop accepting: close the listening socket, keep every connection process alive.
3. Wait for in-flight requests, up to `rakun.lifecycle.timeout-per-shutdown-phase` (default 20s).
   Past the timeout, the remaining connection processes are killed and counted in the shutdown log.
4. Hand off to front 06's `#[preDestroy]` pass.
5. Stop the node with front 06's exit code.

`rakun.server.shutdown=immediate` skips steps 2 and 3, matching Spring's own escape — and it is the
one place this front has a weakening switch, because "kill it now" is a legitimate operational
request and not a way around a rule.

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
- [ ] `SIGTERM` flips readiness false before the listening socket closes — asserted by a probe request between the two
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
- **11-rakun-actuator** registers the metrics and tracing entry at +100; **76** owns endpoint
  exposure and the readiness state this front flips.
- **20-rakun-websocket** owns `modules/rakun-web/src/websocket/**` and adds no chain entry — an
  upgrade leaves the HTTP chain before the handler.
- **14-rakun-validation** supplies the violation report that the problem-detail entry renders as a
  422.

## Contradictions with fronts.md

1. **`modules/rakun-web/` needs a `botopink.json` and a `src/root.bp`**, and the ownership row lists
   neither. They belong to F07 as the module's first front.
2. **`modules/rakun-web/src/sidecars/rakun_chain.erl`** is not in the row either; it is where the chain
   host cells live, and it must be named or the front cannot ship.
3. The row lists `convention.bp` but not the `middleware.bp` *file* convention's scanner hook, which
   lives in front 22. Front 07 assumes front 22 compiles a root `middleware.bp`; if that is not front
   22's reading, the two need to agree before either lands.

## Definition of done

- [ ] `modules/rakun-web/` exists with a manifest, a root module, the five source files and the chain
      sidecar
- [ ] One chain, two entry points, with the documented order band and a test that asserts the whole
      sequence
- [ ] CORS defaults deny, and `*` with credentials fails at boot
- [ ] Problem details are RFC 9457-shaped, `application/problem+json`, and never carry a raw reason
- [ ] `Accept` and `Accept-Encoding` are both negotiated with q-values; `br` is refused rather than faked
- [ ] No `Server` header by default
- [ ] Shutdown flips readiness, drains, then hands to front 06 — in that order, asserted
- [ ] `repository/rakun/AGENTS.md` documents the order band and the two entry points
- [ ] The front's tests are green on its assigned target
