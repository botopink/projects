# Front 04 — Web Middleware, CORS & Error Handling

**Priority:** high — production web services need middleware chains, CORS, and standardized error responses
**Depends on:** F03 (context-api)
**Owns:** `modules/rakun-web/src/middleware.bp`, `modules/rakun-web/src/cors.bp`, `modules/rakun-web/src/error.bp`, `modules/rakun-web/src/filter.bp`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

Rakun's web layer is bare-bones: route matching + handler execution. There is no:
- Middleware/filter chain (intercept requests before/after handlers)
- CORS support (cross-origin requests fail)
- Standardized error handling (RFC 9457 Problem Details)
- Request/response transformation pipeline

Production services need all of these for security, observability, and client compatibility.

## Current state

- Router matches `(verb, path)` and calls handler directly
- No pre/post processing hooks
- CORS headers not set (cross-origin requests blocked by browsers)
- Errors return raw 500 with no structured body
- No way to add authentication, logging, rate limiting, etc.

## Mechanism

Spring Boot's filter chain:
- `Filter` interface: `doFilter(request, response, chain)`
- Filters execute in order, can short-circuit or modify request/response
- CORS: `@CrossOrigin` or global `CorsConfiguration`
- Error handling: `@ControllerAdvice` + `@ExceptionHandler`, or RFC 9457

Rakun will implement:
- **Filter chain** via `#[filter]` decorator and `FilterChain` type
- **CORS** via `#[crossOrigin]` decorator and global config
- **Error handling** via `#[controllerAdvice]` + `#[exceptionHandler]`
- **RFC 9457** via `ProblemDetail` type and auto-conversion

## Steps

### Step 1 — Filter interface and chain

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

Runtime maintains ordered list of filters:
```js
const filters = []; // [{ order, filter }]

export function registerFilter(order, filter) {
    filters.push({ order, filter });
    filters.sort((a, b) => a.order - b.order);
}
```

**Acceptance:**
- [ ] `Filter` behavior defined
- [ ] `FilterChain` type defined
- [ ] Filters can be registered with order
- [ ] Chain executes filters in order

### Step 2 — @filter decorator

```bp
#[filter]
#[order(1)]
pub type LoggingFilter {
    pub fn doFilter(self: Self, request: Request, response: Response, chain: FilterChain) -> Response {
        print("Request: " + request.path);
        val result = chain.doFilter(request);
        print("Response: " + result.status);
        return result;
    }
}
```

Implementation:
```bp
pub fn filter(comptime decl: @Decl) {
    @emit("val __rkFilter_" + decl.name + " = rkRegisterFilter(" + /* order */ "1, __rkMake_" + decl.name + "());");
    if (decl.kind != DeclKind.Type) decl.fail("#[filter] must annotate a type");
}
```

**Acceptance:**
- [ ] `#[filter]` registers type as filter
- [ ] `#[order(N)]` sets execution order
- [ ] Filter's `doFilter` called for every request
- [ ] Filter can modify request before passing to chain
- [ ] Filter can modify response after chain returns

### Step 3 — CORS support

```bp
#[crossOrigin(origins: ["https://example.com"], methods: ["GET", "POST"])]
#[restController]
pub type MyController { }
```

Global CORS config:
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

Implementation: CORS filter adds headers:
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

**Acceptance:**
- [ ] `#[crossOrigin]` on controller sets CORS headers
- [ ] Global `CorsConfiguration` applies to all controllers
- [ ] Preflight OPTIONS requests handled
- [ ] Non-allowed origins rejected

### Step 4 — Error handling with @controllerAdvice

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

Implementation: decorator scans for `#[exceptionHandler]` methods and registers them:
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

**Acceptance:**
- [ ] `#[controllerAdvice]` registers exception handlers
- [ ] `#[exceptionHandler("Type")]` catches exceptions of that type
- [ ] Handler's `Response` returned instead of 500
- [ ] Multiple handlers for different exception types

### Step 5 — RFC 9457 Problem Details

```bp
pub type ProblemDetail(
    type: string,        // URI reference
    title: string,       // short human-readable summary
    status: i32,         // HTTP status code
    detail: string,      // human-readable explanation
    instance: string,    // URI reference for specific occurrence
)

// Auto-convert ProblemDetail to JSON response
#[exceptionHandler("NotFoundException")]
pub fn handleNotFound(self: Self, ex: NotFoundException) -> ProblemDetail {
    return ProblemDetail(
        type: "https://example.com/problems/not-found",
        title: "Resource Not Found",
        status: 404,
        detail: ex.message,
        instance: ex.path,
    );
}
```

Response:
```json
{
    "type": "https://example.com/problems/not-found",
    "title": "Resource Not Found",
    "status": 404,
    "detail": "User 'alice' not found",
    "instance": "/api/users/alice"
}
```

**Acceptance:**
- [ ] `ProblemDetail` type defined
- [ ] Returning `ProblemDetail` from handler auto-converts to JSON
- [ ] Content-Type: `application/problem+json`
- [ ] `spring.mvc.problemdetails.enabled=true` equivalent

### Step 6 — Built-in filters

Provide common filters out of the box:
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

**Acceptance:**
- [ ] `RequestIdFilter` adds/propagates request ID
- [ ] `LoggingFilter` logs request method, path, status, duration
- [ ] `TimingFilter` adds `X-Response-Time` header
- [ ] Filters can be enabled/disabled via config

### Step 7 — Module structure

Create `modules/rakun-web/`:
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

**Acceptance:**
- [ ] `rakun-web` module compiles
- [ ] All tests pass on commonJS and Erlang
- [ ] Example app uses `rakun-web` features

## Gate

- [ ] `botopink test --target commonJS` green
- [ ] `botopink test --target erlang` green
- [ ] Filter chain executes in order
- [ ] CORS headers set correctly
- [ ] Exception handlers catch and transform errors
- [ ] Problem Details response format correct

## Blast radius

- **New module** `rakun-web` — no changes to rakun-core
- **Runtime** gains filter chain, exception handler registry
- **Decorators** gain `#[filter]`, `#[crossOrigin]`, `#[controllerAdvice]`, `#[exceptionHandler]`
- **Example app** can use middleware, CORS, error handling

## Notes

- Filter order: negative = early (CORS, logging), positive = late (compression, etc.)
- CORS preflight (OPTIONS) handled automatically
- Exception handlers: exact type match for now (no inheritance)
- Problem Details: opt-in via config (default off for backward compat)
- Built-in filters: enabled by default, can be disabled via config
