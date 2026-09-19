# Front 05 — Data Access (SQL)

**Priority:** high — services need database access
**Depends on:** F03 (context-api)
**Owns:** `modules/rakun-data/src/sql/**`, `modules/rakun-data/src/datasource.bp`, `modules/rakun-data/src/repository.bp`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

Rakun has no data access layer. Services that need to persist data have no abstraction for:
- DataSource (connection pool)
- JDBC-style operations
- Repository pattern
- Transaction management

Spring Boot provides `spring-boot-starter-data-jpa`, `spring-boot-starter-jdbc`, etc. Rakun needs equivalent for Erlang/BEAM.

## Current state

- No data access abstractions
- No database drivers
- No connection pooling
- No transaction management
- Example app uses in-memory arrays

## Mechanism

Spring Boot's data access:
- `DataSource` → connection pool (HikariCP)
- `JdbcTemplate` → low-level SQL
- `@Repository` → Spring Data repositories
- `@Transactional` → declarative transactions

Rakun will implement:
- **DataSource** → connection pool (Erlang: `poolboy` or `epgsql` pool)
- **SqlTemplate** → low-level SQL operations
- **@repository** → already exists, enhance with query methods
- **@transactional** → declarative transactions

## Steps

### Step 1 — DataSource abstraction

```bp
// datasource.bp
pub behavior DataSource {
    fn getConnection(self: Self) -> @Result<Connection, string>;
    fn close(self: Self);
}

pub behavior Connection {
    fn execute(self: Self, sql: string, params: Array<string>) -> @Result<i32, string>;
    fn query(self: Self, sql: string, params: Array<string>) -> @Result<Array<Row>, string>;
    fn close(self: Self);
}
```

PostgreSQL implementation:
```bp
// postgres_datasource.bp
#[component]
pub type PostgresDataSource(
    #[value("spring.datasource.url")] url: string,
    #[value("spring.datasource.username")] username: string,
    #[value("spring.datasource.password")] password: string,
) {
    pub fn getConnection(self: Self) -> @Result<Connection, string> {
        // use epgsql (Erlang PostgreSQL driver)
    }
}
```

**Acceptance:**
- [ ] `DataSource` behavior defined
- [ ] `Connection` behavior defined
- [ ] PostgreSQL implementation connects
- [ ] Connection pool reuses connections

### Step 2 — SqlTemplate

```bp
// sql_template.bp
#[service]
pub type SqlTemplate(dataSource: DataSource) {
    pub fn query(self: Self, sql: string, params: Array<string>) -> @Result<Array<Row>, string> {
        val conn = self.dataSource.getConnection();
        val result = conn.query(sql, params);
        conn.close();
        return result;
    }

    pub fn update(self: Self, sql: string, params: Array<string>) -> @Result<i32, string> {
        val conn = self.dataSource.getConnection();
        val result = conn.execute(sql, params);
        conn.close();
        return result;
    }
}
```

Usage:
```bp
#[service]
pub type UserRepository(template: SqlTemplate) {
    pub fn findById(self: Self, id: i32) -> @Result<?User, string> {
        val rows = self.template.query("SELECT * FROM users WHERE id = $1", [id.toString()]);
        return rows.map({ r -> mapRow(r) });
    }
}
```

**Acceptance:**
- [ ] `SqlTemplate` executes queries
- [ ] Parameters bound correctly (prevent SQL injection)
- [ ] Connections returned to pool after use
- [ ] Works on both targets

### Step 3 — @repository enhancement

Existing `#[repository]` decorator works, but add query methods:

```bp
#[repository]
pub type UserRepository(template: SqlTemplate) {
    #[query("SELECT * FROM users WHERE id = $1")]
    pub fn findById(self: Self, id: i32) -> @Result<?User, string>;

    #[query("SELECT * FROM users WHERE email = $1")]
    pub fn findByEmail(self: Self, email: string) -> @Result<?User, string>;

    #[query("INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id")]
    pub fn save(self: Self, name: string, email: string) -> @Result<i32, string>;
}
```

Implementation: `#[query]` decorator generates method body:
```bp
pub fn query(comptime decl: @Decl, sql: string) {
    @emit("pub fn " + decl.name + "(self: Self, " + /* params */ ") -> @Result<" + /* return type */ ", string> { return self.template.query(\"" + sql + "\", [" + /* args */ "]); }");
}
```

**Acceptance:**
- [ ] `#[query("SQL")]` generates method body
- [ ] Parameters bound from method arguments
- [ ] Return type mapped from `Row` to domain type
- [ ] Works for SELECT, INSERT, UPDATE, DELETE

### Step 4 — Connection pooling

Use `poolboy` (Erlang) or generic-pool (Node.js):

```bp
#[configuration]
pub type DataSourceConfig {
    #[bean]
    pub fn dataSource(self: Self) -> DataSource {
        return PostgresDataSource(
            url: self.url,
            username: self.username,
            password: self.password,
            poolSize: 10,
        );
    }
}
```

Config:
```yaml
spring:
  datasource:
    url: postgresql://localhost:5432/mydb
    username: user
    password: secret
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
```

**Acceptance:**
- [ ] Connection pool created at startup
- [ ] Connections reused across requests
- [ ] Pool size configurable
- [ ] Idle connections closed

### Step 5 — @transactional

```bp
#[service]
pub type UserService(repo: UserRepository) {
    #[transactional]
    pub fn createUser(self: Self, name: string, email: string) -> @Result<User, string> {
        val id = self.repo.save(name, email);
        self.repo.saveAudit(id, "created");  // same transaction
        return self.repo.findById(id);
    }
}
```

Implementation: decorator wraps method in transaction:
```bp
pub fn transactional(comptime decl: @Decl) {
    @emit("pub fn " + decl.name + "(self: Self, " + /* params */ ") -> " + /* return type */ " { return rkTransactional({ -> /* original body */ }); }");
}
```

Runtime:
```js
export function transactional(fn) {
    const conn = dataSource.getConnection();
    conn.beginTransaction();
    try {
        const result = fn(conn);
        conn.commit();
        return result;
    } catch (e) {
        conn.rollback();
        throw e;
    } finally {
        conn.close();
    }
}
```

**Acceptance:**
- [ ] `#[transactional]` wraps method in transaction
- [ ] Success → commit
- [ ] Exception → rollback
- [ ] Nested `@transactional` joins existing transaction
- [ ] Works on both targets

### Step 6 — MySQL support

Add MySQL driver alongside PostgreSQL:

```bp
#[component]
pub type MySqlDataSource(
    #[value("spring.datasource.url")] url: string,
    #[value("spring.datasource.username")] username: string,
    #[value("spring.datasource.password")] password: string,
) {
    pub fn getConnection(self: Self) -> @Result<Connection, string> {
        // use mysql-otp (Erlang MySQL driver)
    }
}
```

Auto-detect driver from URL:
```bp
pub fn createDataSource(url: string) -> DataSource {
    if (url.startsWith("postgresql://")) return PostgresDataSource(url);
    if (url.startsWith("mysql://")) return MySqlDataSource(url);
    panic("Unsupported database: " + url);
}
```

**Acceptance:**
- [ ] MySQL driver connects
- [ ] Auto-detection from URL works
- [ ] Both PostgreSQL and MySQL tested

### Step 7 — Module structure

Create `modules/rakun-data/`:
```
modules/rakun-data/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── datasource.bp
│   ├── sql_template.bp
│   ├── postgres_datasource.bp
│   ├── mysql_datasource.bp
│   └── transactional.bp
└── test/
    ├── datasource_test.bp
    ├── sql_template_test.bp
    └── transactional_test.bp
```

**Acceptance:**
- [ ] `rakun-data` module compiles
- [ ] All tests pass on commonJS and Erlang
- [ ] Example app uses `rakun-data` with PostgreSQL

## Gate

- [ ] `botopink test --target commonJS` green
- [ ] `botopink test --target erlang` green
- [ ] PostgreSQL connection works
- [ ] MySQL connection works
- [ ] `SqlTemplate` executes queries
- [ ] `#[query]` generates method bodies
- [ ] `#[transactional]` commits/rollbacks correctly
- [ ] Connection pool reuses connections

## Blast radius

- **New module** `rakun-data` — no changes to rakun-core
- **Dependencies** — `epgsql`, `mysql-otp` (Erlang), `pg`, `mysql` (Node.js)
- **Runtime** gains transaction management
- **Decorators** gain `#[query]`, `#[transactional]`
- **Example app** can use PostgreSQL/MySQL

## Notes

- Connection pool: `poolboy` (Erlang), `generic-pool` (Node.js)
- Drivers: `epgsql` + `mysql-otp` (Erlang), `pg` + `mysql` (Node.js)
- Transaction propagation: REQUIRED (default), REQUIRES_NEW, NESTED — start with REQUIRED only
- No ORM in this front (Spring Data JPA equivalent is a separate front)
- SQL injection prevention: parameterized queries only (no string concatenation)
- Future: add `rakun-data-jpa` for ORM-like experience
