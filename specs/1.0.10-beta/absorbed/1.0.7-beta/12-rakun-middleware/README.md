# Front 12 — Rakun Middleware

**Referência Next.js:** [Middleware](https://nextjs.org/docs/app/building-your-application/routing/middleware) · [Proxy](https://nextjs.org/docs/app/getting-started/proxy)

**Priority:** high — middleware intercepts requests for auth, logging, redirects
**Depends on:** F09 (rakun-ssr-pipeline), F14 (rakun-file-routing)
**Owns:** `repository/rakun/src/middleware.bp`
**Does not touch:** `runtime.bp`, `ssr.bp`, `file_router.bp`, `actions.bp`, `route_handler.bp`

---

## Problem

Requests need to be intercepted for authentication, logging, redirects, rewrites, and header manipulation. Next.js uses `middleware.ts` at the project root. Rakun needs an equivalent.

## Current state

- Rakun has `#[filter]` decorators (from 1.0.6-beta F04) for controller-level middleware
- No project-wide middleware convention
- No `middleware.bp` file convention

## Mechanism

Introduce `middleware.bp` file convention:
- Single file at project root (or `app/middleware.bp`)
- Exports a `middleware` function that receives `Request` and returns `Response` or `NextResponse`
- Runs before every request (SSR and API)
- Can redirect, rewrite, modify headers, set cookies

```bp
// middleware.bp
import {Request, Response, NextResponse} from "rakun";

#[@future]
pub fn middleware(request: Request) -> @Future<Response> {
    val token = request.cookie("session");
    if (token == null && request.path().startsWith("/dashboard")) {
        return NextResponse.redirect("/login");
    };
    return NextResponse.next();
}
```

## Exemplos em bp

### Middleware de autenticação

```bp
// middleware.bp
#[@future]
pub fn middleware(request: Request) -> @Future<Response> {
    val token = request.header("Authorization");
    if (request.path().startsWith("/dashboard") && token == "") {
        return NextResponse.redirect("/login");
    };
    return NextResponse.next();
}

pub val config = MiddlewareConfig(matcher: ["/dashboard/*"]);
```

## Steps

### Step 1 — NextResponse type

```bp
// src/middleware.bp
pub type NextResponse {
    pub fn next() -> Response {
        return Response(status: 200, body: "");  // Continue to handler
    }

    pub fn redirect(url: string) -> Response {
        return Response(status: 307, body: "").withHeader("Location", url);
    }

    pub fn rewrite(url: string) -> Response {
        return Response(status: 200, body: "").withHeader("X-Rewrite", url);
    }
}
```

**Acceptance:**
- [ ] `NextResponse` type with `next()`, `redirect()`, `rewrite()`
- [ ] Returns `Response` with appropriate status/headers

### Step 2 — Middleware detection

The SSR pipeline checks for `middleware.bp` and invokes it before routing:

```bp
// In ssr.bp
#[@future]
pub fn handleRequest(path: string, request: Request) -> @Future<Response> {
    // Run middleware first
    val middlewareResponse = await invokeMiddleware(request);
    if (middlewareResponse.status == 307) {
        return middlewareResponse;  // Redirect
    };
    if (middlewareResponse.hasHeader("X-Rewrite")) {
        path = middlewareResponse.getHeader("X-Rewrite");
    };
    // Continue to route matching
    // ...
}
```

**Acceptance:**
- [ ] Middleware runs before route matching
- [ ] Can short-circuit with redirect
- [ ] Can rewrite the path

### Step 3 — Middleware matcher

Configure which paths the middleware runs on:

```bp
// middleware.bp
pub val config = MiddlewareConfig(
    matcher: ["/dashboard/*", "/api/*"],
);
```

**Acceptance:**
- [ ] Middleware only runs on matched paths
- [ ] Wildcard patterns work

### Step 4 — Tests

```bp
test "NextResponse.redirect produces 307" {
    val res = NextResponse.redirect("/login");
    assert res.status == 307;
    assert res.getHeader("Location") == "/login";
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `middleware.bp` in place
- [ ] SSR pipeline integration works
- [ ] AGENTS.md updated
- [ ] Commit on `fix/rakun-middleware`

## Blast radius

- New file `middleware.bp`
- SSR pipeline updated to invoke middleware
- No breaking changes to existing routes

## Notes

- Middleware runs on every request (unless matcher excludes it).
- Middleware is async because it may need to check auth (DB, external service).
- Middleware can set cookies, modify headers, redirect, rewrite.
