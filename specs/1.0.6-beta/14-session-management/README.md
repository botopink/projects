# Front 14 — Session Management

**Priority:** low — services need session management for stateful interactions
**Depends on:** F04 (web-middleware)
**Owns:** `modules/rakun-session/src/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `modules/rakun-web/src/**`

---

## Problem

Rakun has no session management. Services that need stateful interactions (shopping carts, user sessions) must implement their own session storage. Spring Boot provides `spring-boot-starter-session` with support for Redis, JDBC, Hazelcast.

## Mechanism

Spring Boot Session:
- `@EnableRedisHttpSession` → Redis-backed sessions
- `@EnableJdbcHttpSession` → JDBC-backed sessions
- Session stored outside application (distributed)
- Session ID in cookie

Rakun will implement:
- **Session** type
- **SessionRepository** behavior
- In-memory + Redis backends
- Session cookie management

## Steps

### Step 1 — Session abstraction

```bp
// session.bp
pub type Session(
    id: string,
    attributes: Dict<string, string>,
    createdAt: i64,
    lastAccessedAt: i64,
    maxInactiveInterval: i32,  // seconds
)

pub behavior SessionRepository {
    fn createSession(self: Self) -> Session;
    fn save(self: Self, session: Session);
    fn findById(self: Self, id: string) -> ?Session;
    fn deleteById(self: Self, id: string);
}
```

### Step 2 — In-memory session repository

```bp
#[component]
pub type InMemorySessionRepository {
    pub fn createSession(self: Self) -> Session {
        return Session(
            id: generateUuid(),
            attributes: Dict.empty(),
            createdAt: time.nowMillis(),
            lastAccessedAt: time.nowMillis(),
            maxInactiveInterval: 1800,  // 30 minutes
        );
    }
}
```

### Step 3 — Redis session repository

```bp
#[component]
pub type RedisSessionRepository(
    #[value("spring.redis.host")] host: string,
    #[value("spring.redis.port")] port: i32,
) {
    pub fn createSession(self: Self) -> Session { }
    pub fn save(self: Self, session: Session) { }
    pub fn findById(self: Self, id: string) -> ?Session { }
    pub fn deleteById(self: Self, id: string) { }
}
```

### Step 4 — Session filter

```bp
#[filter]
#[order(-50)]
pub type SessionFilter(repo: SessionRepository) {
    pub fn doFilter(self: Self, request: Request, response: Response, chain: FilterChain) -> Response {
        val sessionId = request.cookie("SESSION");
        val session = if (sessionId != "") self.repo.findById(sessionId) else null;
        // attach session to request context
        return chain.doFilter(request);
    }
}
```

### Step 5 — Module structure

```
modules/rakun-session/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── session.bp
│   ├── in_memory_repo.bp
│   ├── redis_repo.bp
│   └── session_filter.bp
└── test/
    └── session_test.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] Session created/stored/retrieved
- [ ] Session ID in cookie
- [ ] Expired sessions cleaned up
- [ ] Redis backend works

## Notes

- Session ID: UUID
- Cookie: `SESSION` (configurable)
- Expiry: configurable (default 30 min)
- Distributed: Redis for multi-instance
