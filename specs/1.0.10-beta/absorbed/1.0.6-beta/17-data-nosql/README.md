# Front 17 — Data Access (NoSQL)

**Priority:** low — services need document/key-value stores
**Depends on:** F05 (data-sql)
**Owns:** `modules/rakun-data/src/nosql/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `modules/rakun-data/src/sql/**`

---

## Problem

Beyond SQL databases, services need document stores (MongoDB), key-value stores (Redis), and search engines (Elasticsearch). Spring Boot provides starters for each.

## Mechanism

Spring Boot NoSQL:
- `spring-boot-starter-data-mongodb` → MongoDB
- `spring-boot-starter-data-redis` → Redis
- `spring-boot-starter-data-elasticsearch` → Elasticsearch
- `MongoTemplate`, `RedisTemplate`, `ElasticsearchTemplate`
- Repository pattern

Rakun will implement:
- **MongoTemplate** → MongoDB operations
- **RedisTemplate** → Redis operations
- **ElasticsearchTemplate** → Elasticsearch operations
- Repository pattern for each

## Steps

### Step 1 — MongoDB

```bp
#[service]
pub type MongoTemplate(
    #[value("spring.mongodb.uri")] uri: string,
) {
    pub fn insert<T>(self: Self, collection: string, doc: T);
    pub fn find<T>(self: Self, collection: string, query: string) -> Array<T>;
    pub fn findById<T>(self: Self, collection: string, id: string) -> ?T;
    pub fn update(self: Self, collection: string, query: string, update: string);
    pub fn delete(self: Self, collection: string, query: string);
}
```

Erlang: use `mongodb` driver.

### Step 2 — Redis

```bp
#[service]
pub type RedisTemplate(
    #[value("spring.redis.host")] host: string,
    #[value("spring.redis.port")] port: i32,
) {
    pub fn get(self: Self, key: string) -> ?string;
    pub fn set(self: Self, key: string, value: string);
    pub fn setEx(self: Self, key: string, value: string, ttl: i32);
    pub fn del(self: Self, key: string);
    pub fn hGet(self: Self, key: string, field: string) -> ?string;
    pub fn hSet(self: Self, key: string, field: string, value: string);
    pub fn lPush(self: Self, key: string, value: string);
    pub fn lPop(self: Self, key: string) -> ?string;
}
```

Erlang: use `eredis` or `eredis_cluster`.

### Step 3 — Elasticsearch

```bp
#[service]
pub type ElasticsearchTemplate(
    #[value("spring.elasticsearch.uris")] uris: string,
) {
    pub fn index<T>(self: Self, index: string, id: string, doc: T);
    pub fn get<T>(self: Self, index: string, id: string) -> ?T;
    pub fn search<T>(self: Self, index: string, query: string) -> Array<T>;
    pub fn delete(self: Self, index: string, id: string);
}
```

Erlang: use HTTP client to call Elasticsearch REST API.

### Step 4 — Repository pattern

```bp
#[repository]
pub type UserRepository(template: MongoTemplate) {
    #[query("{email: $1}")]
    pub fn findByEmail(self: Self, email: string) -> ?User;
}
```

### Step 5 — Module structure

```
modules/rakun-data/
└── src/
    └── nosql/
        ├── mongo_template.bp
        ├── redis_template.bp
        └── elasticsearch_template.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] MongoDB CRUD works
- [ ] Redis get/set/hash/list works
- [ ] Elasticsearch index/search works
- [ ] Repository pattern works for each

## Notes

- MongoDB: `mongodb` (Erlang), `mongodb` (Node.js)
- Redis: `eredis` (Erlang), `ioredis` (Node.js)
- Elasticsearch: HTTP REST API (both targets)
- Reactive variants: separate front
