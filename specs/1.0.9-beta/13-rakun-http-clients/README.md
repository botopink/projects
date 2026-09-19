# Front 13 — Rakun HTTP Clients

**Track:** B rakun
**Priority:** medium — a service that cannot call another service is a leaf, and fronts 12, 15 and 21 all assume an outbound call exists
**Target:** erlang (server)
**Wave:** 3
**Depends on:** 01 (`net`), 05 (config), 06 (context), 12 (cache store for cached responses)
**Owns:** `modules/rakun-client/src/**`, `modules/rakun-client/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone
**Reference:** `07-io.md § REST Clients` (WebClient · RestClient · RestTemplate · HTTP Service Interfaces · Configuracao Global · SSRF Protection) · https://docs.spring.io/spring-boot/reference/io/rest-client.html
**Replaces:** `1.0.6-beta/09-rest-client` + `1.0.6-beta/19-web-client-reactive`

---

## Problem

A rakun service has no way to call another HTTP service. `libs/std/src/http.bp` offers exactly one
function — `fetch(url) -> @Future<Response>` (`http.bp:55`) — which does GET only, takes no headers, no
body, no timeout and no method, and whose erlang cell starts `inets` and calls `httpc:request/4`
inline. `modules/rakun-client/` is a `botopink.json` and a `src/root.bp` containing a TODO comment.

The two drafts this replaces described one thing twice. 1.0.6-beta F09 specified `RestClient` — a
fluent blocking builder — over six steps. 1.0.6-beta F19 specified `WebClient` as a separate front with
its own module file, its own builder type and its own spec types, whose entire stated difference was
*"Returns `@Future<T>` (Botopink's async type)"*. Two builders, two type hierarchies and two test files
to express one transport and two terminal operations is a cost with no buyer. Worse, both drafts
assumed a fluent surface botopink cannot express as written — `RestClient.builder().build()` with
bodyless methods declared inside a `type` body (`09-rest-client/README.md` step 1), which is not legal
(`docs.md:567`).

There is also nothing between a service and the network. Spring ships an `InetAddressFilter` for SSRF
protection (`07-io.md § SSRF Protection`) and neither draft mentions it, which means a rakun service
that forwards a user-supplied URL today would happily fetch `http://169.254.169.254/`.

## Current state

- `libs/std/src/http.bp:55` — `pub declare fn fetch(url: string) -> @Future<Response>`; GET only, no headers, no timeout. `http.bp:71` — `fetchStatus`. That is the entire outbound surface in the ecosystem.
- `libs/std/src/http.bp:25-29` — the file's own docblock states BEAM and wasm are out of scope and a caller on those backends fails with a missing-external diagnostic.
- `repository/rakun/modules/rakun-client/src/root.bp` — docblock plus `// Module contents will be added by the respective fronts.`
- `libs/std/src/json.bp:36,45` — `parse` and `stringify` both take and return `string`; there is no structured JSON value, so response decoding in this front stops at the body string.
- `libs/std/src/` has **no socket module at all** — no `net.bp`, no `gen_tcp` wrapper, no TLS surface. Front 01 delivers it and this front is its first consumer; until it lands there is nothing under `fetch` but the one inline `httpc` template.
- No address filter, no connection reuse, no redirect policy anywhere in the tree.

## Mechanism

**One builder, one transport, two terminal operations.** `RestClient` is the only client type. Spring's
`WebClient` is not a second stack here; it is `retrieveFuture()` instead of `retrieve()` on the same
`RequestSpec`, over the same settings, through the same address filter, against the same cache. The
BEAM makes this true rather than convenient: a blocking call is a process that waits, and a process
that waits costs nothing, so there is no reactive stack to justify. Spring's `RestTemplate` is not
ported at all — upstream marks it legacy (`07-io.md § RestTemplate (Legacy)`) and porting a deprecated
API to a new language is work nobody asked for.

**What `@Future` does and does not mean here.** `@Future<T>` lowers **eagerly** on erlang —
`libs/std/src/http.bp:16-18` — so `retrieveFuture()` is not a concurrent call. It is the same blocking
request with a different return shape, which is exactly why it costs one method rather than a second
stack. A service that wants two upstream calls to overlap does not get it from `@Future`; it gets it
from front 02, which parallelises **unstarted** tasks (`Array<fn() -> @Future<T>>`). Any README, test
name or comment in this module that implies otherwise is wrong and is a review failure.

**The chain, and why it is records rather than interfaces.** Each step is a record with methods
returning a new record, which is the shape botopink actually has. No bodyless method sits in a `type`
body; every abstraction that needs one is a `behavior`.

```
RestClient.builder() -> RestClientBuilder -> .build() -> RestClient
RestClient.get(path) -> RequestSpec -> .header(n,v) -> .cached(...) -> .retrieve() -> ClientResponse
                                                                   -> .retrieveFuture() -> @Future<ClientResponse>
```

**The transport is front 01, not a private host cell.** rakun-client declares no socket, TLS or DNS
cell of its own. It assembles a method, an absolute URL, a header list, a body and a timeout, hands
them to `net` from front 01, and maps what comes back onto `ClientResponse`. The milestone rule is
explicit about this — *"a front that needs a primitive asks front 01 for it"* — and the payoff is that
the address filter below sits in exactly one place instead of once per caller.

**Global settings, and per-client overrides.** Spring configures every client at once
(`spring.http.clients.connect-timeout`, `.read-timeout`, `.redirects` — `07-io.md § Configuracao Global
de HTTP Clients`) and lets a builder override. Same here:

| Key | Default | Effect |
|---|---|---|
| `rakun.http.clients.connect-timeout-millis` | `2000` | TCP connect deadline |
| `rakun.http.clients.read-timeout-millis` | `1000` | Response deadline after connect |
| `rakun.http.clients.redirects` | `dont-follow` | `follow` \| `dont-follow`. Defaulting to not following is the restrictive choice: a followed redirect is a second request to an address the caller never named, and the address filter has to re-run on it. |
| `rakun.http.clients.max-redirects` | `3` | Only read when redirects are followed |

A builder call — `.connectTimeout(ms)`, `.readTimeout(ms)`, `.redirects("follow")` — overrides for that
client only. There is no key that disables a timeout; `0` is rejected at boot.

### SSRF protection — the address filter

Every connect goes through it, and there is no way around it.

Spring's version is an opt-in bean: `InetAddressFilter.of("192.168.1.0/24").andNot(...)`
(`07-io.md § SSRF Protection`). Opt-in is the wrong default for a control whose absence is a
vulnerability, and the project's standing rule is the most restrictive behaviour with no knob to get
around it. So the rakun filter is on, always, and it denies by default:

1. The URL's host is resolved to addresses before connect.
2. Every resolved address is checked against the deny set first, then the allow set.
3. The deny set always contains loopback (`127.0.0.0/8`, `::1/128`), link-local (`169.254.0.0/16`,
   `fe80::/10` — this is the cloud metadata endpoint), private unicast (`10.0.0.0/8`,
   `172.16.0.0/12`, `192.168.0.0/16`, `fc00::/7`), unspecified and multicast. These entries cannot be
   removed by configuration.
4. `rakun.http.clients.allow` is a CIDR list that re-admits addresses the built-in deny set would
   refuse — the only way to reach a private address, and it is written by an operator, per range,
   never by an application flag.
5. `rakun.http.clients.deny` narrows further and is applied after the allow list.
6. The check runs again on every redirect hop, against the redirect target's resolved addresses, and
   the connection is made to the address that was checked — not re-resolved afterwards, which is the
   DNS-rebinding hole.

There is no `rakun.http.clients.ssrf.enabled`. A front that wants one has found a design error.

### Response caching

Next's legacy caching form is `fetch(url, { next: { revalidate: 3600 } })`
(`NEXTJS-DOCS.md § 11. Modelo anterior`). It lands here, and it lands on front 12's store rather than a
second cache inside the client:

```bp
client.get("/products").revalidate(3600).retrieve()
client.get("/products").cached("upstream-products", cacheLife("hours"), ["products"]).retrieve()
```

`.revalidate(n)` is `.cached(<derived name>, cacheLifeOf(0, n, n), [])`. The cache key is
`cacheKey(name, [method, absoluteUrl, bodyHash])`, so two calls that differ only in a header share a
row and two that differ in the body do not. Only `retrieve()` and `retrieveFuture()` on a request whose
method is GET or HEAD may be cached; `.cached(...)` on a POST raises at the call, because a cached
mutation is a bug that only shows up in production.

### HTTP Service Interfaces

Spring's `@HttpExchange` turns a Java interface into a generated client (`07-io.md § HTTP Service
Interfaces`), imported by group and configured under
`spring.http.serviceclient.<group>.base-url`. In botopink that is the same comptime twin-type
mechanism front 12 uses for `#[cached]` and `onze` uses for `#[mock]`: a decorator reflects a
`behavior` and `@emit`s a type implementing it.

```bp
#[httpExchange("echo")]
pub behavior EchoService {
    #[getExchange("/users/:id")]
    fn user(self: Self, id: string) -> string;

    #[postExchange("/echo")]
    fn echo(self: Self, body: string) -> string;
}
```

emits `type HttpEchoService(client: RestClient) implement EchoService` plus
`pub fn httpEchoService() -> EchoService`, whose client is built from the group's configuration:
`rakun.http.serviceclient.echo.base-url`, `.connect-timeout-millis`, `.read-timeout-millis`. Path
parameters are substituted by name from the method's own parameter names, which is why `:id` and the
parameter `id` must agree — a mismatch fails at comptime with a located message rather than producing
a URL with a literal `:id` in it.

### Target

erlang. Every cell is `#[@External.Erlang]` or, preferably, nothing at all — the transport is front
01's and the cache is front 12's.

## Steps

### Step 1 — Settings, responses and the builder

```bp
pub type HttpClientSettings(
    connectTimeoutMillis: i32,
    readTimeoutMillis: i32,
    redirects: string,
    maxRedirects: i32,
)

pub type ClientResponse(status: i32, body: string, headersJson: string) {
    pub fn isOk(self: Self) -> bool {
        val ok = if (self.status < 200) { false } else { self.status < 300 };
        return ok;
    }
}

pub type RestClientBuilder(
    baseUrl: string,
    headers: Array<#(string, string)>,
    settings: HttpClientSettings,
) {
    pub fn baseUrl(self: Self, url: string) -> RestClientBuilder {
        return RestClientBuilder(baseUrl: url, headers: self.headers, settings: self.settings);
    }

    pub fn defaultHeader(self: Self, name: string, value: string) -> RestClientBuilder {
        return RestClientBuilder(baseUrl: self.baseUrl, headers: self.headers.append([#(name, value)]), settings: self.settings);
    }

    pub fn build(self: Self) -> RestClient {
        return RestClient(baseUrl: self.baseUrl, headers: self.headers, settings: self.settings);
    }
}
```

**Acceptance:**
- [ ] `RestClient.builder()` starts from the global settings, so a client built with no calls already carries the configured timeouts.
- [ ] Each builder method returns a new value and leaves the receiver unchanged — two clients built from one builder do not share headers.
- [ ] A settings value of `0` for either timeout is refused at boot with the key named.
- [ ] There is no bodyless method in any `type` body in this module.

### Step 2 — The request chain and the two terminal operations

```bp
pub type RequestSpec(
    client: RestClient,
    method: string,
    path: string,
    body: string,
    headers: Array<#(string, string)>,
    cacheName: string,
    cacheLifeSeconds: i32,
    cacheTags: Array<string>,
) {
    pub fn header(self: Self, name: string, value: string) -> RequestSpec { … }
    pub fn retrieve(self: Self) -> ClientResponse { … }
}

#[@future]
pub fn retrieveFuture(spec: RequestSpec) -> @Future<ClientResponse>
```

**Acceptance:**
- [ ] `retrieve` and `retrieveFuture` on the same `RequestSpec` produce the same status, body and headers against the same stub server.
- [ ] `retrieveFuture` is declared `#[@future]` and returns `@Future<ClientResponse>`; the marker and the wrapper go together (`tests/language/reject/result_without_wrapper.bp` covers the inverse).
- [ ] Two `retrieveFuture` calls issued before either is awaited do **not** overlap on erlang, and the test that measures it asserts that rather than the opposite — the concurrency story is front 02's.
- [ ] A non-2xx response is returned, not raised — the caller decides, via `isOk()`.
- [ ] A read timeout produces a `ClientResponse` with status `-1` and the reason in the body, matching the shape `libs/std/src/http.bp` already uses for a failed erlang fetch.
- [ ] `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD` and `OPTIONS` all reach the transport with the right verb.

### Step 3 — The address filter

```bp
pub type AddressPolicy(allow: Array<string>, deny: Array<string>)

pub fn addressAllowed(policy: AddressPolicy, addr: string) -> bool
```

**Acceptance:**
- [ ] A request to `http://127.0.0.1/`, `http://169.254.169.254/`, `http://10.0.0.1/`, `http://192.168.1.1/` and `http://[::1]/` is refused with status `-1` and a message naming the blocked address, with no socket opened.
- [ ] Adding `10.0.0.0/8` to `rakun.http.clients.allow` admits `10.0.0.1` and still refuses `169.254.169.254`.
- [ ] A hostname whose DNS answer contains one public and one private address is refused.
- [ ] A 302 to a private address is refused even when the original host was public.
- [ ] There is no configuration key, builder method or environment variable in this module that turns the filter off. A grep for `ssrf` in the module finds documentation and tests, never a flag.

### Step 4 — Response caching over front 12

```bp
pub fn cached(spec: RequestSpec, name: string, life: CacheLife, tags: Array<string>) -> RequestSpec
pub fn revalidate(spec: RequestSpec, seconds: i32) -> RequestSpec
```

**Acceptance:**
- [ ] A second `retrieve()` on a cached GET within the freshness window does not reach the transport.
- [ ] `revalidateTag` on one of the request's tags makes the next `retrieve()` reach the transport.
- [ ] `.cached(...)` or `.revalidate(...)` on a POST raises with the method named.
- [ ] With `rakun.cache.type=none`, every cached request reaches the transport and nothing is stored.
- [ ] Two requests differing only in a request header share a cache row; two differing in body do not.

### Step 5 — `#[httpExchange]`

**Acceptance:**
- [ ] `#[httpExchange("echo")]` on a behavior emits a type implementing it plus a `http<Name>()` factory, and the factory's client is configured from `rakun.http.serviceclient.echo.*`.
- [ ] A `:param` in an exchange path with no matching method parameter name fails at comptime with both names in the message.
- [ ] `#[getExchange]` / `#[postExchange]` / `#[putExchange]` / `#[patchExchange]` / `#[deleteExchange]` on anything but a method fail with a located message.
- [ ] A method whose return type is not `string` fails with a message pointing at the missing JSON value model rather than emitting something that cannot work.
- [ ] Two groups configured with different base URLs produce two clients that do not share settings.

### Step 6 — Health indicator

A client group registers an indicator with front 11's health registry: UP when a `HEAD` against the
group's base URL answers inside the connect timeout, DOWN naming the group and the reason otherwise.
It is opt-in per group via `rakun.http.serviceclient.<group>.health-check=true`, because probing a
partner's API on every health scrape is rude, and the default is false.

**Acceptance:**
- [ ] With the key set, the indicator appears in front 11's report under `httpClient.<group>`.
- [ ] With it unset, the group contributes no indicator and the scrape makes no outbound request.

## Examples

- [`examples/rest-client-example.bp`](./examples/rest-client-example.bp) — a `#[service]` that calls a partner API through a configured client: the builder, both terminal operations, and a cached GET.
- [`examples/http-exchange-example.bp`](./examples/http-exchange-example.bp) — the declarative form: a `#[httpExchange]` behavior and the generated client wired in by a `#[bean]`.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| There is no structured JSON value in std — `json.parse` and `json.stringify` both take and return `string` (`libs/std/src/json.bp:36,45`) — so a typed `body(User)` in Spring's sense cannot be expressed. | `examples/rest-client-example.bp`, every `ClientResponse.body` read | Return the body as `string` and let the caller shape it, or reflect the target record with a comptime decorator and `@emit` a field-by-field decoder. | A `JsonValue` sum type in std with `parse -> @Result<JsonValue, string>` — front 01's `encoding` is where it would live |
| Declared parameter defaults are never applied, so the builder cannot have optional arguments the way `RestClient.Builder` does. | Every builder method in both examples | One method per setting, each taking every argument. | Apply declared defaults at call sites (`docs.md:502-505`) |
| There is no byte or binary type — host cells marshal through `string` — so a response body that is not UTF-8 text (an image, a protobuf frame, a gzip stream) cannot be represented. Recorded by front 01; repeated here because this front is where it bites first. | `ClientResponse.body` in both examples | Restrict clients to text media types and refuse a binary `content-type` with a named error rather than returning mojibake. | A `bytes` primitive with `string` conversions at the edges |

## Test plan

`modules/rakun-client/test/` on the **erlang** target, via
`zig build test-libs -- --target erlang --lib rakun`.

| File | Asserts |
|---|---|
| `test/builder_test.bp` | Builder immutability, settings inheritance, zero-timeout refusal |
| `test/request_test.bp` | Every verb, header assembly, URL joining, `retrieve` and `retrieveFuture` agreement, timeout shape |
| `test/ssrf_test.bp` | The five blocked address families, the allow-list widening, the mixed-DNS case, the redirect hop, and a grep asserting the module contains no disabling flag |
| `test/cache_test.bp` | Hit/miss, tag invalidation, POST refusal, kill-switch passthrough, key sensitivity |
| `test/exchange_test.bp` | Twin synthesis, path-parameter mismatch, placement failures, per-group configuration |

Outbound tests run against a stub server started in the test process — an `inets` `httpd` on an
ephemeral port — so no test depends on the network. The SSRF tests need no server at all: the filter
refuses before connect, which is the property being asserted.

There is no commonJS row; this front is server-only by the milestone's target split.

## Out of scope

- **`RestTemplate`** — upstream marks it legacy; there is no reason to port a deprecated API to a new language.
- **SOAP / `WebServiceTemplate`** (`07-io.md § Web Services (SOAP)`) — front 93.
- **RSocket** (`06-messaging.md § RSocket`) — front 92.
- **A connection pool** — the BEAM's answer is a supervised worker per destination, and that belongs with front 04's runtime rather than in a client library.
- **Typed response decoding** — blocked on a JSON value model; named in *Language gaps*.

## Definition of done

- One `RestClient` type, two terminal operations, and no second builder anywhere in the module.
- The transport is front 01's `net`; a grep for `httpc`, `gun`, `ssl:` or `gen_tcp` under `modules/rakun-client/src` finds nothing.
- The address filter is unconditional, denies the six built-in families, and has no off switch.
- Cached responses live in front 12's store, keyed by front 12's protocol.
- `#[httpExchange]` generates a working client for a configured group.
- Every `// LANGUAGE GAP:` marker in the examples appears in the table above.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the module's surface in the same commit.
- The front's tests are green on erlang.
