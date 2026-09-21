# Front 08 — Cache Abstraction

**Priority:** medium — services need caching for performance
**Depends on:** F03 (context-api)
**Owns:** `modules/rakun-cache/src/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

Rakun has no caching abstraction. Services that need to cache results must implement their own caching logic. Spring Boot provides `spring-boot-starter-cache` with declarative caching via `@Cacheable`, `@CacheEvict`, `@CachePut`.

## Current state

- No caching abstraction
- No cache decorators
- No cache managers
- Services implement caching manually (if at all)

## Mechanism

Spring Boot Cache:
- `@Cacheable("cacheName")` → cache method result
- `@CacheEvict("cacheName")` → evict cache entries
- `@CachePut("cacheName")` → update cache
- `CacheManager` → manages cache instances
- Supports: ConcurrentMap, Caffeine, Redis, EhCache, Hazelcast

Rakun will implement:
- **@cacheable** → cache method result
- **@cacheEvict** → evict entries
- **@cachePut** → update cache
- **CacheManager** → manages caches
- In-memory + Redis backends

## Steps

### Step 1 — Cache abstraction

```bp
// cache.bp
pub behavior Cache {
    fn get(self: Self, key: string) -> ?string;
    fn put(self: Self, key: string, value: string);
    fn evict(self: Self, key: string);
    fn clear(self: Self);
    fn name(self: Self) -> string;
}

pub behavior CacheManager {
    fn getCache(self: Self, name: string) -> Cache;
    fn getCacheNames(self: Self) -> Array<string>;
}
```

**Acceptance:**
- [ ] `Cache` behavior defined
- [ ] `CacheManager` behavior defined
- [ ] Interface is backend-agnostic

### Step 2 — In-memory cache

```bp
#[component]
pub type ConcurrentMapCacheManager {
    pub fn getCache(self: Self, name: string) -> Cache {
        return ConcurrentMapCache(name: name);
    }
}

pub type ConcurrentMapCache(name: string) {
    pub fn get(self: Self, key: string) -> ?string {
        return rkCacheGet(self.name, key);
    }
    pub fn put(self: Self, key: string, value: string) {
        rkCachePut(self.name, key, value);
    }
    pub fn evict(self: Self, key: string) {
        rkCacheEvict(self.name, key);
    }
    pub fn clear(self: Self) {
        rkCacheClear(self.name);
    }
}
```

Runtime (ETS table per cache):
```erlang
cache_get(CacheName, Key) ->
    case ets:lookup({rakun_cache, CacheName}, Key) of
        [{_, Value}] -> Value;
        [] -> undefined
    end.
```

**Acceptance:**
- [ ] In-memory cache stores/retrieves values
- [ ] TTL support (configurable per cache)
- [ ] Max size support (LRU eviction)
- [ ] Works on both targets

### Step 3 — @cacheable decorator

```bp
#[service]
pub type UserService(repo: UserRepository) {
    #[cacheable("users")]
    pub fn findById(self: Self, id: i32) -> ?User {
        return self.repo.findById(id);
    }
}
```

Implementation:
```bp
pub fn cacheable(comptime decl: @Decl, cacheName: string) {
    @emit("pub fn " + decl.name + "(self: Self, " + /* params */ ") -> " + /* return type */ " { val _key = rkCacheKey(\"" + decl.name + "\", [" + /* args */ "]); val _cached = rkCacheGet(\"" + cacheName + "\", _key); if (_cached != null) return _cached; val _result = /* original body */; rkCachePut(\"" + cacheName + "\", _key, _result); return _result; }");
}
```

**Acceptance:**
- [ ] `#[cacheable("name")]` caches method result
- [ ] Cache key generated from method name + arguments
- [ ] Cached value returned on subsequent calls
- [ ] Method not called when cache hit

### Step 4 — @cacheEvict decorator

```bp
#[service]
pub type UserService(repo: UserRepository) {
    #[cacheEvict("users")]
    pub fn updateUser(self: Self, id: i32, user: User) -> User {
        return self.repo.update(id, user);
    }

    #[cacheEvict("users", allEntries: true)]
    pub fn deleteAll(self: Self);
}
```

**Acceptance:**
- [ ] `#[cacheEvict("name")]` evicts entry by key
- [ ] `allEntries: true` clears entire cache
- [ ] Eviction happens after method execution
- [ ] Works with `#[cacheable]`

### Step 5 — @cachePut decorator

```bp
#[service]
pub type UserService(repo: UserRepository) {
    #[cachePut("users")]
    pub fn updateUser(self: Self, id: i32, user: User) -> User {
        return self.repo.update(id, user);
    }
}
```

**Acceptance:**
- [ ] `#[cachePut("name")]` updates cache with result
- [ ] Method always called (unlike `@cacheable`)
- [ ] Cache updated with return value

### Step 6 — Redis cache

```bp
#[component]
pub type RedisCacheManager(
    #[value("spring.redis.host")] host: string,
    #[value("spring.redis.port")] port: i32,
) {
    pub fn getCache(self: Self, name: string) -> Cache {
        return RedisCache(name: name, host: self.host, port: self.port);
    }
}
```

**Acceptance:**
- [ ] Redis cache stores/retrieves values
- [ ] TTL support
- [ ] Serialization (JSON)
- [ ] Works on both targets

### Step 7 — Module structure

```
modules/rakun-cache/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── cache.bp
│   ├── concurrent_map_cache.bp
│   ├── redis_cache.bp
│   └── decorators.bp
└── test/
    ├── cache_test.bp
    └── decorators_test.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] `#[cacheable]` caches method results
- [ ] `#[cacheEvict]` evicts entries
- [ ] `#[cachePut]` updates cache
- [ ] In-memory cache works
- [ ] Redis cache works

## Notes

- Cache key: method name + serialized arguments
- TTL: configurable per cache (default: no expiry)
- Max size: configurable (default: unlimited)
- Serialization: JSON for Redis, identity for in-memory
- Future: add Caffeine (high-performance in-memory)
