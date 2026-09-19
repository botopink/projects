# Front 12 — Rakun Cache

**Track:** B rakun
**Priority:** medium — without it every `#[service]` that reads twice reads twice, and the Next-style render pipeline in fronts 23–25 has nowhere to put a memoized segment
**Target:** erlang (server)
**Wave:** 3
**Depends on:** 01 (`clock`), 03 (content hash), 05 (config), 06 (context), 11 (endpoint host + health registry), 13 (the Redis transport), 18 (session id for the private scope), 62 (per-request context)
**Owns:** `modules/rakun-cache/src/**`, `modules/rakun-cache/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone
**Reference:** `07-io.md § Caching` · `NEXTJS-DOCS.md § 11. Cache` · `NEXTJS-DOCS.md § 12. Revalidação` · https://docs.spring.io/spring-boot/reference/io/caching.html · https://nextjs.org/docs/app/api-reference/directives/use-cache · https://nextjs.org/docs/app/api-reference/functions/revalidateTag
**Replaces:** `1.0.6-beta/08-cache-abstraction` + `1.0.7-beta/13-rakun-cache`

---

## Problem

A rakun service that wants to avoid recomputing something has nowhere to put the result. There is no
cache type, no cache decorator, no store, and no key protocol. `modules/rakun-cache/` exists but holds
exactly two files — `botopink.json` and a `src/root.bp` whose body is the comment *"Module contents
will be added by the respective fronts."* A developer who needs caching today writes a `Dict` field on
a record, discovers records are immutable, and gives up or reaches for a host cell of their own.

The two drafts this front replaces each solved half of it and neither knew about the other. 1.0.6-beta
F08 proposed Spring's declarative surface — `@Cacheable`, `@CacheEvict`, `@CachePut`, a `CacheManager`
over ConcurrentMap or Redis. 1.0.7-beta F13 proposed Next's directive surface — `'use cache'`,
`cacheLife`, `cacheTag`, `revalidateTag`, `revalidatePath` — and explicitly said it *"extends the
existing module from 1.0.6-beta"* without saying how the key spaces, the lifetimes or the eviction
paths relate. Two entry points into two stores is two caches, and two caches that can each hold the
same row is a correctness bug, not a performance feature.

This front is the single store, the single key protocol and the single lifetime model, with both entry
points spelled on top of it. `#[cacheable("products")]` and `cacheThrough(policy, keys, load)` write
the same ETS row under the same key and are invalidated by the same `revalidateTag`.

## Current state

- `repository/rakun/modules/rakun-cache/botopink.json` — package metadata only, `"targets": ["commonJS", "erlang"]`.
- `repository/rakun/modules/rakun-cache/src/root.bp` — a docblock and a TODO comment. No `pub mod` line, no code.
- `repository/rakun/src/runtime.bp:56-66` — the only key/value surface that exists in rakun today is the property store (`rkSetProp`/`rkProp`/`rkPropInt`), which is configuration, not cache: no expiry, no tags, no scope.
- `repository/rakun/src/decorators.bp` — fifteen decorators, none of them `#[cacheable]`. The file is frozen; every decorator this front adds lives in `modules/rakun-cache/src/`.
- `libs/std/src/` has no content-hash module; front 03 delivers it, and this front's key protocol is its first consumer.
- `libs/std/src/time.bp:56,80,92` already has `nowMillis`, `monotonicMillis` and `formatIso8601`. Freshness arithmetic uses the monotonic clock, not the system one, so a clock step does not resurrect an expired entry; front 01 extends that file rather than replacing it.

## Mechanism

Upstream gives two shapes for one idea.

Spring proxies the bean: `@Cacheable("piDecimals")` on a method means the container hands callers a
subclass that consults `CacheManager` before delegating (`07-io.md § Usando Cache`). Next marks the
function: `'use cache'` at the top of a function body means the framework memoizes its result, with
`cacheLife` setting the freshness window and `cacheTag` naming what invalidates it
(`NEXTJS-DOCS.md § 11`).

Neither transfers verbatim. botopink has no proxy generation and no directive-string statement. What it
has is the twin-type trick that `onze` already uses: a comptime decorator reflects a `behavior` and
`@emit`s a *new* type implementing it (`repository/onze/src/onze.bp:196-219` emits
`type MockUserRepo(__id: string) implement UserRepo` plus a `mockUserRepo()` factory). Apply that to
caching and the Spring half falls out with no compiler change:

- `#[cached]` on a `behavior` reflects `decl.methods`, reads each method's `#[cacheable(name)]` /
  `#[cacheEvict(name, allEntries)]` annotation from `m.annotations` exactly as `#[restController]`
  reads `#[getMapping]` (`repository/rakun/src/decorators.bp:155-166`), and `@emit`s
  `type Cached<Name>(inner: <Name>) implement <Name>` whose every cacheable method is
  `cacheThrough(...)` around `self.inner.<method>(…)` and whose every evicting method calls the store
  after delegating.
- The twin becomes the injected implementation through machinery that already ships: a
  `#[configuration]` type with a `#[bean] pub fn catalog(self: Self) -> ProductCatalog` returning
  `cachedProductCatalog(self.real)`. `#[configuration]` emits `__rkMake_ProductCatalog()` from the
  bean's return type (`repository/rakun/src/decorators.bp:186-190`), so every component that declares
  a `catalog: ProductCatalog` field gets the caching twin. That is Spring's proxy bean, built out of
  rakun's existing DI.

The Next half is the same store reached directly. `cacheThrough(policy, keys, load)` is the primitive;
`cachePolicy(scope, name, life, tags)` is the value the directive would have carried. The transparent
directive itself is a language gap (below) — a decorator cannot replace the body it annotates — so the
example writes the combinator and marks the line.

### Providers: exactly two

| Provider | Key | Backing | Use |
|---|---|---|---|
| **ETS** | `rakun.cache.type=ets` | `ets:new(rakun_cache_<name>, [set, public, named_table])`, one table per cache name, owned by rakun's supervisor so a crashing worker does not take the table with it | local to one node |
| **Redis** | `rakun.cache.type=redis` | Front 13's client against `rakun.cache.redis.url`; values stored as strings with a server-side TTL | shared across the cluster |

That is the whole provider set, and it is short on purpose. Spring detects nine providers in order —
Generic, JCache, Hazelcast, Infinispan, Couchbase, Redis, Caffeine, Cache2k, Simple
(`07-io.md § Provedores Suportados`). Seven of them have no BEAM meaning: JCache is a JSR-107 Java SPI,
Hazelcast and Infinispan are JVM clustering products that duplicate what OTP distribution already does,
Caffeine and Cache2k are JVM in-process caches whose job ETS does natively, Couchbase is a database
driver rather than a cache provider, and Generic/Simple are the JVM's way of saying "whatever bean you
registered". Porting them would mean writing JVM shims and calling it parity. They are not omitted by
oversight; they are declined, and this paragraph is the record of that decision.

**Mnesia was considered for the distributed provider and rejected.** It replicates for free across a
BEAM cluster, which is the attractive half, but it has no TTL: an expiring cache on Mnesia needs a
sweeper process, a table schema, and a disk/RAM copy decision per node, which turns a cache into a
persistence concern. Redis expires rows itself. If a zero-dependency distributed cache is wanted later
it is a third provider under the same protocol, not a change to this front.

### Scopes

One protocol, three scopes, chosen by `CacheScope`:

| Scope | Next spelling | Provider | Shared across | Keyed on |
|---|---|---|---|---|
| `CacheScope.Shared` | `'use cache'` | the configured provider | the provider's reach | namespace + key parts |
| `CacheScope.Remote` | `'use cache: remote'` | always Redis, whatever the default provider is | the cluster | namespace + key parts |
| `CacheScope.Private` | `'use cache: private'` | ETS, in a per-session partition | nothing — one session only | session id + namespace + key parts |

`CacheScope.Private` takes the session id from the per-request context (front 62) and mixes it into the
key before hashing. A private entry written under one session id is unreachable under another; the
test asserts that, because a private cache that leaks is the worst bug in this front.

### The key protocol

`cacheKey(namespace, parts)` joins the parts with a separator that cannot occur in a part, prefixes the
namespace, and hashes the result with front 03's content hash. Keys are therefore fixed-width,
provider-independent, and identical for the two entry points — which is what makes "one store" true
rather than aspirational.

### Lifetimes

`CacheLife(stale, revalidate, expire)`, all in seconds, with the six named profiles from
`NEXTJS-DOCS.md § 11. cacheLife` and an inline constructor:

| Profile | stale | revalidate | expire |
|---|---|---|---|
| `seconds` | 30 | 1 | 60 |
| `minutes` | 300 | 60 | 3600 |
| `hours` | 300 | 3600 | 86400 |
| `days` | 300 | 86400 | 604800 |
| `weeks` | 300 | 604800 | 2592000 |
| `max` | 300 | 2592000 | 31536000 |

`cacheLifeOf(stale, revalidate, expire)` is the custom form. Spring's TTL
(`spring.cache.redis.time-to-live`) maps onto `expire`; Spring has no `stale` window, so a
Spring-configured cache gets `stale = 0` and never serves stale.

### Per-cache configuration, and the global kill switch

One knob decides whether the layer exists at all, and it doubles as Spring's `spring.cache.type=none`
and Next's `cacheComponents` opt-in:

| Key | Default | Effect |
|---|---|---|
| `rakun.cache.type` | `none` | `none` \| `ets` \| `redis`. `none` makes every `cacheThrough` call its loader and every `#[cached]` twin delegate straight through. |
| `rakun.cache.names` | empty | The caches created at boot. A cache not listed here is created on first use with the defaults below. |
| `rakun.cache.<name>.type` | inherits | Per-cache provider override. |
| `rakun.cache.<name>.ttl-seconds` | `3600` | The `expire` a policy gets when it does not carry one. |
| `rakun.cache.<name>.max-entries` | `10000` | Entry cap. `0` means unbounded, and an unbounded cache on a long-lived node is a memory leak with a nicer name. |
| `rakun.cache.<name>.eviction` | `lru` | `lru` \| `lfu` \| `ttl-only`. What is discarded when `max-entries` is reached. |
| `rakun.cache.redis.url` | unset | Required when any provider resolves to `redis`; boot fails if it is missing. |

Spring's escape hatch is the same shape — `spring.cache.type=none` (`07-io.md § Desabilitando Cache`),
per-cache names (`spring.cache.cache-names`), a per-provider TTL — so a reader coming from
`application.properties` recognises every row.

### The customizer hook

Spring lets an application adjust the manager after auto-configuration with a
`CacheManagerCustomizer` bean (`07-io.md § Customizando`). The rakun shape is a behavior registered as
an ordinary bean:

```bp
pub behavior CacheCustomizer {
    fn customize(self: Self, name: string, settings: CacheSettings) -> CacheSettings;
}
```

The manager folds every registered customizer over the resolved `CacheSettings` before creating a
cache, in bean-registration order. A customizer may tighten a setting or loosen it; what it may not do
is re-enable a cache that `rakun.cache.type=none` turned off — the kill switch is checked after the
fold, not before, so no application bean can defeat it.

### Revalidation, and where each verb is legal

`revalidateTag` marks matching entries stale — a subsequent read returns the stale value and schedules
a refresh. `updateTag` expires them now, so a read later in the *same* request sees the write
(read-your-own-writes). `revalidatePath` invalidates by rendered URL. Legality is enforced, not
documented: the SSR pipeline and the action dispatcher set a phase on the request process,
`rkCachePhase()` reads it, and a verb called in the wrong phase raises with a located message.

| Verb | Server action | Route handler | During render |
|---|---|---|---|
| `revalidateTag` | legal | legal | raises |
| `revalidatePath` | legal | legal | raises |
| `updateTag` | legal | raises | raises |

### Target

Everything here runs while a request is in flight, so everything here is erlang. The module declares no
`@External.Node` cell; its host cells are `#[@External.Erlang]` over ETS, the Redis client and the
phase word in the request process dictionary.

## Steps

### Step 1 — The store, the scopes and the key protocol

```bp
pub type CacheScope {
    Shared,
    Remote,
    Private,
}

pub type CacheLife(stale: i32, revalidate: i32, expire: i32)

pub type CachePolicy(
    scope: CacheScope,
    name: string,
    life: CacheLife,
    tags: Array<string>,
)

pub fn cachePolicy(scope: CacheScope, name: string, life: CacheLife, tags: Array<string>) -> CachePolicy {
    return CachePolicy(scope: scope, name: name, life: life, tags: tags);
}

pub fn cacheKey(namespace: string, parts: Array<string>) -> string {
    return namespace + ":" + contentHash(parts.join("\u{1f}"));
}
```

**Acceptance:**
- [ ] `cacheKey("p", ["a", "b"])` and `cacheKey("p", ["a\u{1f}b"])` differ — the separator cannot be forged from a part.
- [ ] The same `(namespace, parts)` produces the same key on two runs of the same binary.
- [ ] `CacheScope.Private` keys built under two different session ids differ, and neither read returns the other's value.
- [ ] Every host cell in the module is `#[@External.Erlang]`; a grep for `External.Node` under `modules/rakun-cache/src` returns nothing.

### Step 2 — Lifetimes

```bp
pub fn cacheLife(profile: string) -> CacheLife {
    val out = case profile {
        "seconds" -> CacheLife(stale: 30, revalidate: 1, expire: 60);
        "minutes" -> CacheLife(stale: 300, revalidate: 60, expire: 3600);
        "hours" -> CacheLife(stale: 300, revalidate: 3600, expire: 86400);
        "days" -> CacheLife(stale: 300, revalidate: 86400, expire: 604800);
        "weeks" -> CacheLife(stale: 300, revalidate: 604800, expire: 2592000);
        "max" -> CacheLife(stale: 300, revalidate: 2592000, expire: 31536000);
        _ -> CacheLife(stale: 0, revalidate: 60, expire: 3600);
    };
    return out;
}

pub fn cacheLifeOf(stale: i32, revalidate: i32, expire: i32) -> CacheLife {
    return CacheLife(stale: stale, revalidate: revalidate, expire: expire);
}
```

**Acceptance:**
- [ ] The six profiles return exactly the table above.
- [ ] An entry older than `revalidate` but younger than `stale + revalidate` is returned AND scheduled for refresh.
- [ ] An entry older than `expire` is not returned, whatever its `stale` window.
- [ ] An unknown profile name falls back to a one-hour expiry rather than raising — a typo must not take the server down.
- [ ] A policy that carries no explicit `expire` inherits `rakun.cache.<name>.ttl-seconds`.

### Step 3 — `cacheThrough`, the provider switch and the kill switch

```bp
pub fn cacheThrough(policy: CachePolicy, keys: Array<string>, load: fn() -> string) -> string {
    val enabled = rkCacheEnabled(policy.name);
    if (!enabled) {
        return load();
    };
    val key = cacheKey(policy.name, keys);
    val hit = rkCacheLookup(scopeTag(policy.scope), policy.name, key);
    val cached = hit.unwrapOr("");
    if (cached != "") {
        return cached;
    };
    val fresh = load();
    val _w = rkCachePut(scopeTag(policy.scope), policy.name, key, fresh, policy.life.expire, policy.tags);
    return fresh;
}
```

**Acceptance:**
- [ ] With `rakun.cache.type=none`, the loader runs on every call and the store stays empty — for `cacheThrough`, for `cacheFn` and for every `#[cached]` twin.
- [ ] With a provider set, a second call with the same keys does not run the loader.
- [ ] Two calls with different keys both run the loader.
- [ ] A `CacheScope.Remote` policy reaches Redis even when the default provider is `ets`.
- [ ] `max-entries` is honoured: the `max-entries + 1`-th distinct key evicts one entry under the configured policy and the cache's size stops growing.
- [ ] A registered `CacheCustomizer` changes the settings a cache is created with, and cannot re-enable a cache the kill switch disabled.

### Step 4 — `#[cached]`, `#[cacheable]`, `#[cacheEvict]`

```bp
#[cached]
pub behavior ProductCatalog {
    #[cacheable("products")]
    fn productJson(self: Self, id: string) -> string;

    #[cacheEvict("products", true)]
    fn reprice(self: Self, id: string, body: string) -> string;
}
```

`#[cached]` reflects the behavior and `@emit`s the twin plus a `cachedProductCatalog(inner)` factory,
mirroring `onze`'s `#[mock]`. `#[cacheable]` and `#[cacheEvict]` enforce placement and carry the cache
name; the type-level decorator does every emit, because that is the only shape that sees all the
methods at once.

**Acceptance:**
- [ ] `#[cacheable]` on anything but a method fails with a located message.
- [ ] Annotations written on a `behavior`'s method signatures reach `#[cached]` as `m.annotations`. If the reflection does not carry them, this front stops and files it rather than working around it.
- [ ] The emitted twin implements the behavior: a field declared `catalog: ProductCatalog` accepts it.
- [ ] A method with no cache annotation is delegated unchanged and never touches the store.
- [ ] `#[cacheEvict(name, true)]` clears the whole cache after the method returns; `#[cacheEvict(name, false)]` removes only the key built from the method's arguments.
- [ ] Eviction runs *after* the delegate returns, so a delegate that raises leaves the cache alone.

### Step 5 — Tags, and the three revalidation verbs

```bp
pub fn revalidateTag(tag: string) -> i32 {
    val phase = rkCachePhase();
    if (phase == "render") {
        @panic("revalidateTag is not legal during render — call it from a server action or a route handler");
    };
    return rkCacheMarkStale(tag);
}

pub fn updateTag(tag: string) -> i32 {
    val phase = rkCachePhase();
    if (phase != "action") {
        @panic("updateTag is legal only inside a server action");
    };
    return rkCacheExpireNow(tag);
}

pub fn revalidatePath(path: string) -> i32 {
    val phase = rkCachePhase();
    if (phase == "render") {
        @panic("revalidatePath is not legal during render");
    };
    return rkCacheMarkStale("path:" + path);
}
```

**Acceptance:**
- [ ] The legality table above is a test with six cells, not a paragraph.
- [ ] After `updateTag("t")`, a read in the same request runs the loader.
- [ ] After `revalidateTag("t")`, the next read returns the previous value and the refresh runs; the read after that returns the new value.
- [ ] An entry carrying two tags is invalidated by either.

### Step 6 — The function-wrapping entry point

Next's `unstable_cache(fn, keys, {tags, revalidate})` wraps a function instead of marking it. It maps
onto the same primitive with no new machinery:

```bp
pub fn cacheFn(name: string, keys: Array<string>, life: CacheLife, tags: Array<string>, load: fn() -> string) -> string {
    return cacheThrough(cachePolicy(CacheScope.Shared, name, life, tags), keys, load);
}
```

**Acceptance:**
- [ ] `cacheFn` and an equivalent `cacheThrough` call produce the same key and share the same row.
- [ ] `cacheFn` honours the kill switch.

### Step 7 — Granularity

The directive is legal at three granularities upstream and all three are reachable here: data level
(a function that loads), UI level (a function that renders a fragment), and file level (every export of
a module). The first two are the same call at a different place in the stack. The third has no botopink
spelling and is a language gap; the nearest valid form is a module-level `val` holding the default
policy.

**Acceptance:**
- [ ] A data-level and a UI-level cache over the same underlying data hold two rows, not one, and `revalidateTag` on a shared tag invalidates both.
- [ ] The module-level fallback policy is picked up by a `cacheThrough` in the same module that passes no policy of its own.

### Step 8 — The `caches` endpoint and the health indicator

Two deliverables that this front defines and front 11 hosts.

```bp
pub type CacheEntryCount(name: string, provider: string, entries: i32)

// GET  /actuator/caches        -> every configured cache, its provider and its size
// DELETE /actuator/caches/{name} -> clear one cache
// DELETE /actuator/caches      -> clear all
pub fn cachesEndpoint(req: Request) -> Response

// Registered with front 11's health registry under the id "cache".
// UP when every configured provider answers; DOWN naming the first that does not.
pub fn cacheHealth() -> HealthReport
```

The endpoint is a write surface — `DELETE /actuator/caches` empties every cache on the node — so it
sits behind front 11's access control with no separate opt-out of its own. Front 11 decides who may
reach `/actuator`; this front does not get a second answer.

**Acceptance:**
- [ ] `GET /actuator/caches` lists every cache named in `rakun.cache.names` plus every cache created on first use, with its provider and entry count.
- [ ] `DELETE /actuator/caches/{name}` empties exactly that cache and returns 204; an unknown name returns 404.
- [ ] Both routes are refused with front 11's standard response when the caller is not authorized, and there is no configuration key in this module that changes that.
- [ ] `cacheHealth()` reports DOWN with the provider named when Redis is configured and unreachable, and UP when the provider is `ets`.

## Examples

- [`examples/cacheable-service-example.bp`](./examples/cacheable-service-example.bp) — the Spring entry point: a `#[cached]` behavior, its real implementation, and the `#[bean]` that makes the caching twin the injected one.
- [`examples/use-cache-example.bp`](./examples/use-cache-example.bp) — the Next entry point over the same store: shared, private and remote scopes, profiles, tags, and the three revalidation verbs from a mutation.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A decorator cannot replace or wrap the body of the declaration it annotates. `@Decl` is read-only and `@emit` appends new module-level declarations only, so a transparent `'use cache'` / `#[useCache]` on a plain function is not expressible. | `examples/use-cache-example.bp`, every `cacheThrough` call | Write the combinator in the body: `cacheThrough(policy, keys, { -> load() })`. For methods, the `#[cached]` behavior twin avoids the gap entirely. | `decl.replaceBody(src)`, or an `@emit` whose output shadows the annotated declaration |
| botopink has no module-level annotation, so a file-level directive (`'use cache'` as the first line of a file) has no spelling. | `examples/use-cache-example.bp`, the module-level policy | A module-level `val` holding the default `CachePolicy`, read by every combinator in the module. | An inner attribute at module scope, e.g. `#![useCache]` |
| Declared parameter defaults are never applied, so a decorator cannot have an optional argument. Spring writes `@CacheEvict("users")` and `@CacheEvict(value = "users", allEntries = true)` from one annotation. | `#[cacheEvict("products", true)]` in both examples | Pass every argument explicitly, always. | Apply declared defaults at call sites (`docs.md:502-505`) |

## Test plan

`modules/rakun-cache/test/` on the **erlang** target, invoked as
`zig build test-libs -- --target erlang --lib rakun` from `repository/botopink-lang/`, and as
`botopink test --target erlang` from `repository/rakun/`.

| File | Asserts |
|---|---|
| `test/key_test.bp` | Key determinism, separator forgery, scope partitioning, private-scope isolation across two session ids |
| `test/life_test.bp` | The six profiles' exact numbers, the stale window, expiry precedence over stale, per-cache TTL inheritance |
| `test/store_test.bp` | Hit/miss, `rakun.cache.type=none` in both positions, ETS and Redis round trip, `max-entries` eviction under each policy, the customizer fold |
| `test/decorators_test.bp` | `#[cached]` twin synthesis, delegation of unannotated methods, eviction ordering, placement failures |
| `test/revalidate_test.bp` | The six legality cells, `updateTag` read-your-own-writes, `revalidateTag` stale-then-fresh, multi-tag invalidation |
| `test/endpoint_test.bp` | `caches` listing and clearing, 404 on an unknown name, refusal when unauthorized, `cacheHealth()` UP and DOWN |

There is no commonJS row. This front is server-only by the milestone's target split, and a green
commonJS cell would assert nothing that the erlang cell does not already assert — it would only make
the front look twice as tested as it is. The Redis path is exercised against a live Redis when
`RAKUN_TEST_REDIS_URL` is set and reports a *skipped* cell otherwise; the ETS path has no such escape
and always runs.

## Out of scope

- **Persistent or write-behind caching** — a cache that survives a node restart is a database. Front 08 owns storage.
- **JCache, Hazelcast, Infinispan, Couchbase, Caffeine, Cache2k** — declined with reasons in *Providers* above, not deferred.
- **Static regeneration** (`export const revalidate`, ISR) — this front holds values; deciding that a whole route is prerendered and regenerated is the static/dynamic switch, which the Next.js audit allocates elsewhere.
- **Metrics on hit rate** — front 75 owns metrics export; this front exposes the counters it keeps and stops there.

## Definition of done

- `modules/rakun-cache/src/root.bp` declares the module tree and the TODO comment is gone.
- One store, reachable by both entry points, proven by a test that writes through `#[cacheable]` and reads through `cacheThrough` on the same key.
- Exactly two providers ship, both named in `AGENTS.md`, and the declined seven are listed there with the reason.
- The revalidation legality table is enforced at runtime and tested in all six cells.
- `rakun.cache.type` defaults to `none` and turning it on changes behaviour without any source edit.
- The `caches` endpoint and the `cache` health indicator are registered with front 11 and refused when unauthorized.
- Every `// LANGUAGE GAP:` marker in the examples appears in the table above.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the module's surface in the same commit.
- The front's tests are green on erlang.
