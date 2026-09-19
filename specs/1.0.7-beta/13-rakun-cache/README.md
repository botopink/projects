# Front 13 — Rakun Cache

**Referência Next.js:** [Caching](https://nextjs.org/docs/app/getting-started/caching) · [Revalidating](https://nextjs.org/docs/app/getting-started/revalidating) · [use cache](https://nextjs.org/docs/app/api-reference/directives/use-cache)

**Priority:** medium — caching improves performance for expensive operations
**Depends on:** F10 (rakun-server-actions)
**Owns:** `repository/rakun/modules/rakun-cache/src/**`
**Does not touch:** `runtime.bp`, `ssr.bp`, `file_router.bp`, `actions.bp`, `middleware.bp`

---

## Problem

Data fetching can be expensive. Caching reduces latency and server load. Next.js has `'use cache'`, `cacheLife`, `cacheTag`, `revalidateTag`, `revalidatePath`. Rakun needs an equivalent caching layer.

## Current state

- Rakun has `rakun-cache` module from 1.0.6-beta (F08) with basic `@Cacheable`
- No `'use cache'` directive equivalent
- No tag-based revalidation
- No cache lifetime profiles

## Mechanism

Introduce `#[cache]` decorator and cache functions:
- `#[cache]` marks a function as cacheable
- `cacheLife(profile)` sets cache lifetime
- `cacheTag(tag)` tags cached data for revalidation
- `revalidateTag(tag)` invalidates by tag
- `revalidatePath(path)` invalidates by path

```bp
#[cache]
#[@future]
pub fn getPosts() -> @Future<Post[]> {
    cacheLife("hours");
    cacheTag("posts");
    return await db.post.findAll();
}

// In a server action
#[serverAction]
#[@future]
pub fn createPost(formData: FormData) -> @Future<void> {
    await db.post.create(formData);
    revalidateTag("posts");
}
```

## Exemplos em bp

### Cache com cacheLife

```bp
#[cache]
#[@future]
pub fn getProducts() -> @Future<Product[]> {
    cacheLife("hours");
    cacheTag("products");
    return await db.product.findAll();
}
```

### Revalidação on-demand

```bp
#[serverAction]
#[@future]
pub fn updateProduct(formData: FormData) -> @Future<void> {
    await db.product.update(formData.get("id"));
    revalidateTag("products");
}
```

## Steps

### Step 1 — #[cache] decorator

```bp
// modules/rakun-cache/src/cache.bp
pub fn cache(comptime decl: @Decl) {
    if (decl.kind != DeclKind.Fn) decl.fail("#[cache] must annotate a function");
    // Emit caching wrapper
    @emit("val __rakun_cached_" + decl.name + " = rkCacheWrap(\"" + decl.name + "\", " + decl.name + ");");
}
```

**Acceptance:**
- [ ] `#[cache]` decorator compiles
- [ ] Can be applied to async functions

### Step 2 — cacheLife profiles

```bp
pub type CacheLifeProfile {
    Seconds,    // stale: 30s, revalidate: 1s, expire: 1min
    Minutes,    // stale: 5min, revalidate: 1min, expire: 1h
    Hours,      // stale: 5min, revalidate: 1h, expire: 1d
    Days,       // stale: 5min, revalidate: 1d, expire: 1w
    Weeks,      // stale: 5min, revalidate: 1w, expire: 30d
    Max,        // stale: 5min, revalidate: 30d, expire: 1y
}

pub fn cacheLife(profile: string) {
    // Set cache lifetime for the current cached function
    rkSetCacheLife(profile);
}
```

**Acceptance:**
- [ ] Predefined profiles: seconds, minutes, hours, days, weeks, max
- [ ] Custom profiles supported

### Step 3 — cacheTag and revalidation

```bp
pub fn cacheTag(tag: string) {
    rkAddCacheTag(tag);
}

pub fn revalidateTag(tag: string) {
    rkInvalidateCacheTag(tag);
}

pub fn revalidatePath(path: string) {
    rkInvalidateCachePath(path);
}
```

**Acceptance:**
- [ ] `cacheTag` tags cached data
- [ ] `revalidateTag` invalidates by tag
- [ ] `revalidatePath` invalidates by path

### Step 4 — Cache storage

```bp
// modules/rakun-cache/src/cache.mjs (sidecar)
const cache = new Map();
const tags = new Map(); // tag -> Set<cacheKey>

export function cacheWrap(name, fn, life) {
    return async function(...args) {
        const key = name + JSON.stringify(args);
        if (cache.has(key)) {
            const entry = cache.get(key);
            if (!isExpired(entry, life)) return entry.value;
        }
        const value = await fn(...args);
        cache.set(key, { value, timestamp: Date.now() });
        return value;
    };
}

export function invalidateTag(tag) {
    const keys = tags.get(tag) || new Set();
    keys.forEach(key => cache.delete(key));
    tags.delete(tag);
}
```

**Acceptance:**
- [ ] Cache stores values with timestamps
- [ ] Expiration works based on profile
- [ ] Tag-based invalidation works

### Step 5 — Tests

```bp
test "cacheLife profiles are defined" {
    assert cacheLifeProfile("hours").revalidate == 3600;
}

test "revalidateTag invalidates cached data" {
    // Cache some data with tag
    // Revalidate tag
    // Verify data is re-fetched
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `rakun-cache` module complete
- [ ] Integration with server actions works
- [ ] AGENTS.md updated
- [ ] Commit on `fix/rakun-cache`

## Blast radius

- New module `rakun-cache` (extends existing module from 1.0.6-beta)
- Server actions can trigger revalidation
- No breaking changes to existing cache decorators

## Notes

- Cache is in-memory by default (per-instance). Future: Redis/external cache.
- Cache keys include function name + arguments.
- Tag-based revalidation is more flexible than path-based.
