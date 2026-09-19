# Front 09 — REST Client

**Priority:** medium — services need to call other services
**Depends on:** F03 (context-api)
**Owns:** `modules/rakun-client/src/rest.bp`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

Rakun has no HTTP client abstraction. Services that need to call other APIs must use low-level `std.http.fetch` directly. Spring Boot provides `RestTemplate`, `RestClient`, and `WebClient`.

## Current state

- `std.http.fetch` available but low-level
- No fluent API
- No automatic serialization/deserialization
- No error handling abstraction
- No retry/timeout configuration

## Mechanism

Spring Boot REST clients:
- `RestTemplate` → classic blocking client
- `RestClient` → fluent API (newer)
- `WebClient` → reactive (out of scope here)

Rakun will implement `RestClient` (fluent, blocking):
```bp
val response = RestClient.create()
    .get()
    .uri("https://api.example.com/users/{id}", id)
    .retrieve()
    .body(User);
```

## Steps

### Step 1 — RestClient type

```bp
// rest.bp
pub type RestClient {
    baseUrl: string,
    defaultHeaders: Dict<string, string>,
    timeout: i32,
}

pub type RestClientBuilder {
    pub fn baseUrl(self: Self, url: string) -> RestClientBuilder;
    pub fn defaultHeader(self: Self, name: string, value: string) -> RestClientBuilder;
    pub fn timeout(self: Self, millis: i32) -> RestClientBuilder;
    pub fn build(self: Self) -> RestClient;
}

pub type RequestHeadersUriSpec {
    pub fn uri(self: Self, url: string, params: Array<string>) -> RequestHeadersSpec;
}

pub type RequestHeadersSpec {
    pub fn header(self: Self, name: string, value: string) -> RequestHeadersSpec;
    pub fn retrieve(self: Self) -> ResponseSpec;
}

pub type ResponseSpec {
    pub fn body<T>(self: Self, type: T) -> T;
    pub fn status(self: Self) -> i32;
}
```

**Acceptance:**
- [ ] Fluent API defined
- [ ] Builder pattern for configuration
- [ ] URI template with params

### Step 2 — HTTP methods

```bp
pub type RestClient {
    pub fn get(self: Self) -> RequestHeadersUriSpec;
    pub fn post(self: Self) -> RequestHeadersUriSpec;
    pub fn put(self: Self) -> RequestHeadersUriSpec;
    pub fn delete(self: Self) -> RequestHeadersUriSpec;
    pub fn patch(self: Self) -> RequestHeadersUriSpec;
}
```

**Acceptance:**
- [ ] All HTTP methods supported
- [ ] Each returns fluent spec

### Step 3 — Request/Response serialization

```bp
pub type ResponseSpec {
    pub fn body<T>(self: Self, type: T) -> @Result<T, string>;
}

// Usage:
val user = client.get()
    .uri("/users/{id}", [id])
    .retrieve()
    .body(User);
```

Implementation: use `std.json.parse` for deserialization.

**Acceptance:**
- [ ] JSON response deserialized to type
- [ ] JSON request body serialized from type
- [ ] Content-Type header set automatically

### Step 4 — Error handling

```bp
pub type RestClientException(
    status: i32,
    body: string,
    message: string,
)

pub type ResponseSpec {
    pub fn onStatus(self: Self, status: i32, handler: fn(Response) -> @Result<void, string>) -> ResponseSpec;
}
```

**Acceptance:**
- [ ] Non-2xx responses throw exception
- [ ] Custom error handlers can be registered
- [ ] Error includes status, body, message

### Step 5 — Interceptors

```bp
pub behavior ClientHttpRequestInterceptor {
    fn intercept(self: Self, request: HttpRequest, next: fn(HttpRequest) -> HttpResponse) -> HttpResponse;
}

val client = RestClient.builder()
    .interceptor(LoggingInterceptor())
    .build();
```

**Acceptance:**
- [ ] Interceptors can modify request
- [ ] Interceptors can modify response
- [ ] Multiple interceptors chain

### Step 6 — Module structure

```
modules/rakun-client/
├── botopink.json
├── src/
│   ├── root.bp
│   └── rest.bp
└── test/
    └── rest_test.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] GET/POST/PUT/DELETE work
- [ ] JSON serialization/deserialization works
- [ ] Error handling works
- [ ] Interceptors work

## Notes

- Uses `std.http.fetch` under the hood
- Blocking only (WebClient/reactive is separate front)
- Timeout: configurable (default: 30s)
- Retry: not in this front (add later)
