# Front 17 — Std Async Primitives

**Referência Next.js:** [Fetching Data — Parallel](https://nextjs.org/docs/app/getting-started/fetching-data#parallel-data-fetching) · [React use()](https://react.dev/reference/react/use)

**Priority:** medium — async utilities are needed for parallel data fetching
**Depends on:** none
**Owns:** `libs/std/src/async.bp`
**Does not touch:** any other std modules

---

## Problem

Server components need to fetch data in parallel. The std lib has no `Promise.all`, `Promise.allSettled`, or async iterator utilities.

## Current state

- std has basic types and functions
- No async utilities
- `#[@future]` functions can `await` single values
- No way to await multiple futures in parallel

## Mechanism

Add async utilities to std:

```bp
import {async} from "std";

// Parallel execution
val [users, posts] = await async.all([fetchUsers(), fetchPosts()]);

// Race
val first = await async.race([fetchFast(), fetchSlow()]);

// All settled (don't fail fast)
val results = await async.allSettled([fetchA(), fetchB()]);
```

## Exemplos em bp

### Parallel fetching

```bp
#[@future]
pub fn DashboardPage() -> @Future<Element> {
    val [users, posts, stats] = await async.all([
        fetchUsers(),
        fetchPosts(),
        fetchStats(),
    ]);
    return div([renderAll(users, posts, stats)], attrs: []);
}
```

### allSettled

```bp
val results = await async.allSettled([
    fetchFromServiceA(),
    fetchFromServiceB(),
]);
val valid = results.filter({ r -> r.isOk() });
```

## Steps

### Step 1 — async.all

```bp
// libs/std/src/async.bp
#[@future]
pub fn all<T>(futures: @Future<T>[]) -> @Future<T[]> {
    // Wait for all futures to complete
    // Return array of results
}
```

**Acceptance:**
- [ ] `async.all` waits for all futures
- [ ] Returns array of results in order
- [ ] Fails if any future fails

### Step 2 — async.allSettled

```bp
#[@future]
pub fn allSettled<T>(futures: @Future<T>[]) -> @Future<Result<T>[]> {
    // Wait for all futures to complete (success or failure)
    // Return array of results (no fail-fast)
}
```

**Acceptance:**
- [ ] `async.allSettled` waits for all futures
- [ ] Returns results even if some fail
- [ ] Each result is `Ok(value)` or `Err(error)`

### Step 3 — async.race

```bp
#[@future]
pub fn race<T>(futures: @Future<T>[]) -> @Future<T> {
    // Return the first future to complete
}
```

**Acceptance:**
- [ ] `async.race` returns first to complete
- [ ] Other futures are cancelled (or ignored)

### Step 4 — Host runtime

```bp
// sidecars/async.mjs
export async function all(futures) {
    return Promise.all(futures);
}

export async function allSettled(futures) {
    return Promise.allSettled(futures);
}

export async function race(futures) {
    return Promise.race(futures);
}
```

**Acceptance:**
- [ ] JS sidecar implements async utilities
- [ ] Erlang equivalent implemented

### Step 5 — Tests

```bp
test "async.all waits for all futures" {
    val results = await async.all([
        async.delay(100, "a"),
        async.delay(50, "b"),
    ]);
    assert results == ["a", "b"];
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `async.bp` in `root.bp`
- [ ] AGENTS.md updated
- [ ] Commit on `fix/std-async-primitives`

## Blast radius

- New file `async.bp` + sidecar
- No changes to existing std modules
- Server components can use async utilities

## Notes

- `async.all` is like `Promise.all` — fails fast if any fails.
- `async.allSettled` is like `Promise.allSettled` — never fails, returns results.
- `async.race` is like `Promise.race` — returns first to complete.
