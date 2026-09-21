# Front 19 — WebClient (Reactive)

**Priority:** low — services need reactive HTTP client
**Depends on:** F09 (rest-client)
**Owns:** `modules/rakun-client/src/webclient.bp`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `modules/rakun-client/src/rest.bp`

---

## Problem

`RestClient` (Front 09) is blocking. Services that need non-blocking HTTP calls (especially in reactive pipelines) need a reactive client. Spring Boot provides `WebClient` for reactive HTTP.

## Mechanism

Spring Boot WebClient:
- `WebClient.create()` → reactive HTTP client
- Returns `Mono<T>` / `Flux<T>`
- Non-blocking, async
- Built on Reactor

Rakun will implement:
- **WebClient** → reactive HTTP client
- Returns `@Future<T>` (Botopink's async type)
- Non-blocking, async

## Steps

### Step 1 — WebClient type

```bp
// webclient.bp
pub type WebClient {
    baseUrl: string,
    defaultHeaders: Dict<string, string>,
}

pub type WebClientBuilder {
    pub fn baseUrl(self: Self, url: string) -> WebClientBuilder;
    pub fn defaultHeader(self: Self, name: string, value: string) -> WebClientBuilder;
    pub fn build(self: Self) -> WebClient;
}
```

### Step 2 — Reactive methods

```bp
pub type WebClient {
    pub fn get(self: Self) -> RequestHeadersUriSpec;
    pub fn post(self: Self) -> RequestHeadersUriSpec;
}

pub type ResponseSpec {
    pub fn bodyToFuture<T>(self: Self, type: T) -> @Future<T>;
    pub fn bodyToFlux<T>(self: Self, type: T) -> @Future<Array<T>>;
}
```

Usage:
```bp
val userFuture = webClient.get()
    .uri("/users/{id}", [id])
    .retrieve()
    .bodyToFuture(User);

// userFuture is @Future<User> — non-blocking
```

### Step 3 — Implementation

Uses `std.http.fetch` wrapped in `@Future`:
```bp
pub fn bodyToFuture<T>(self: Self, type: T) -> @Future<T> {
    return @Future({
        val response = std.http.fetch(self.url, self.options);
        return json.parse(response.body);
    });
}
```

Erlang: use `httpc` (non-blocking) or `gun` (async HTTP client).

### Step 4 — Module structure

```
modules/rakun-client/
└── src/
    └── webclient.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] WebClient makes non-blocking HTTP calls
- [ ] Returns `@Future<T>`
- [ ] Works on both targets

## Notes

- Uses `@Future` (Botopink's async type)
- Non-blocking on Erlang via `httpc` async mode
- Reactor/Flux: not available in Botopink (use `@Future` + `@Iterator` instead)
- For streaming: `@Future<Array<T>>` or `@Iterator<T>`
