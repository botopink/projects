# Front 11 — Rakun Route Handlers

**Referência Next.js:** [Route Handlers](https://nextjs.org/docs/app/getting-started/route-handlers) · [route.js](https://nextjs.org/docs/app/api-reference/file-conventions/route)

**Priority:** high — route handlers are API endpoints (like Next.js route.ts)
**Depends on:** F09 (rakun-ssr-pipeline)
**Owns:** `repository/rakun/src/route_handler.bp`
**Does not touch:** `runtime.bp`, `ssr.bp`, `file_router.bp`, `actions.bp`, `http.bp`

---

## Problem

Next.js has `route.ts` files for API endpoints (GET, POST, etc.) alongside page files. Rakun already has REST controllers, but needs a file-based route handler convention that lives in the `app/` directory.

## Current state

- Rakun has `#[restController]` + `#[getMapping]` decorators for API endpoints
- No file-based convention for route handlers
- Route handlers and pages are separate concepts

## Mechanism

Introduce `route.bp` file convention:
- `route.bp` in a route segment defines HTTP method handlers
- Handlers receive `Request` and return `Response`
- Coexists with `page.bp` in the same segment (but not at the same level)

```bp
// app/api/posts/route.bp
import {Request, Response} from "rakun";

#[@future]
pub fn GET(request: Request) -> @Future<Response> {
    val posts = await db.post.findAll();
    return Response.json(posts);
}

#[@future]
pub fn POST(request: Request) -> @Future<Response> {
    val body = await request.json();
    val post = await db.post.create(body);
    return Response.created(post);
}
```

## Exemplos em bp

### GET handler

```bp
// app/api/posts/route.bp
#[@future]
pub fn GET(request: Request) -> @Future<Response> {
    val posts = await db.post.findAll();
    return Response.json(json.stringify(posts));
}
```

### POST handler

```bp
#[@future]
pub fn POST(request: Request) -> @Future<Response> {
    val body = await request.json();
    val post = await db.post.create(body);
    return Response(status: 201, body: json.stringify(post));
}
```

## Steps

### Step 1 — Route handler convention

Document the `route.bp` convention:
- Exports `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS` functions
- Each receives `Request` and returns `Response`
- File router (F14) detects `route.bp` files and registers them

**Acceptance:**
- [ ] Convention documented
- [ ] File router integration (F14) will wire it up

### Step 2 — Route handler detection

The file router scans for `route.bp` files and registers them as API endpoints:

```bp
// In file_router.bp
pub fn scanRouteHandlers(appDir: string) {
    // Find all route.bp files
    // Register each with the appropriate HTTP method
}
```

**Acceptance:**
- [ ] `route.bp` files are detected
- [ ] HTTP methods are registered

### Step 3 — Request/Response integration

Route handlers use rakun's existing `Request` and `Response` types:

```bp
pub fn GET(request: Request) -> @Future<Response> {
    val id = request.param("id");
    val post = await db.post.findById(id);
    if (post == null) {
        return Response.notFound();
    };
    return Response.json(post);
}
```

**Acceptance:**
- [ ] Route handlers can access request params, query, headers, body
- [ ] Route handlers can return JSON, text, redirects

### Step 4 — Coexistence with pages

A route segment can have either `page.bp` OR `route.bp`, not both:
- `page.bp` → HTML response (SSR)
- `route.bp` → API response (JSON, etc.)

```
app/
├── blog/
│   ├── page.bp          # /blog → HTML
│   └── [slug]/
│       └── page.bp      # /blog/:slug → HTML
└── api/
    └── posts/
        └── route.bp     # /api/posts → JSON
```

**Acceptance:**
- [ ] File router enforces mutual exclusivity
- [ ] Clear error if both `page.bp` and `route.bp` exist

### Step 5 — Tests

```bp
test "route.bp files are detected" {
    // Mock file system with route.bp
    // Verify handlers are registered
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `route_handler.bp` in place
- [ ] File router integration works
- [ ] AGENTS.md updated
- [ ] Commit on `fix/rakun-route-handlers`

## Blast radius

- New file `route_handler.bp`
- File router updated to detect `route.bp` files
- No breaking changes to existing controllers

## Notes

- Route handlers are the file-based equivalent of `#[restController]`.
- They coexist with controllers — you can use either pattern.
- Route handlers are async because they may need to fetch data.
