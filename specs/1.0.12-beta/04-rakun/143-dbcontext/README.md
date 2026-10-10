# Front 143 — dbcontext: botopink's JPA over erika — entities, the context, repositories (decision 398)

**Priority:** high — rakun-data's repositories (08 step 7) stand on it · **State:** step 0 done
(`botopink/dbcontext` scaffolded, a submodule); steps 1–3 open
**Depends on:** decision 398 · `137` step 2 (erika's `QueryContext`, `QueryTable`, `query`, 397) ·
`01-compiler/01-checker` step 29 (the template annotation `#[dbcontext.sql "…"]` and the template method) ·
step 3's rakun commit: `04-rakun/128` landed (decision 339)
**Owns:** `repository/dbcontext/**` (decision 326's rule) · in rakun-data, the code that moves here
(`#[entity]`'s mapping, `#[repository]`, `#[nativeQuery]`, `#[query]`'s checks, the row decoding) and
its deletion there (step 3, one commit, 188)
**Does not touch:** erika (`QueryContext`, `QueryTable`, the grammar are 137's) · rakun-data's drivers,
container registration, `#[transactional]` and `/actuator/sql` (08 step 7's)

## Goal

Decision 398: the persistence layer is a library of its own over erika — erika the query language,
`dbcontext` the entities, the context and the repositories, rakun-data the drivers and the container.

```bp
import {dbcontext, dbcontext.DbContext} from "dbcontext";

#[dbcontext.entity("usuarios")]
pub type User(id: i32, nome: string, #[dbcontext.column("ativo")] active: bool)

#[dbcontext.repository]
behavior Users {
    #[dbcontext.sql "select * from User where id = ${id} limit 1"]            // erika's grammar
    fn find(self: Self, id: i32) -> @Result<?User, StoreError>;

    #[dbcontext.nativeQuery("select * from usuarios where nome ilike :q")]     // the driver's SQL
    fn search(self: Self, q: string) -> @Result<User[], StoreError>;
}

type Relatorio(db: DbContext) {
    fn ativos(self: Self) -> @Result<User[], StoreError> {
        return self.db.query "select * from User where active = true";        // 397
    }
}
```

## Open

### Step 0 — the repository

- [x] `botopink/dbcontext` scaffolded on `feat`, its default branch (the shared hooks byte-identical,
      `.gitignore` naming `*.snap.new` / `*.snap.md.new`, `AGENTS.md` naming `core.hooksPath`); a
      submodule, with its `.gitmodules` entry, `AGENTS.md` § Layout row and CI check 4's list in that commit

### Step 1 — entities and the context

- [ ] `dbcontext.entity(name)` and `dbcontext.column(name)`: record erika's `QueryTable(name, columns)` and
      `dbcontext`'s own entity meta (298); a field's column its name unless `column` says otherwise
- [ ] `behavior Driver` (running a statement — SQL text, bound parameters — and answering rows by column
      name, the error a parameter of the behavior) and `DbContext(driver: Driver) implement QueryContext`
      (erika's, 397): `self.db.query "…"` runs on it, one context for every entity
- [ ] rows decoded into the declared answer by column name; a `?T` answer meeting more than one row is the
      `single()` panic naming the statement (304); cells over a recording `Driver` on erlang and commonJS

### Step 2 — repositories

- [ ] `dbcontext.repository` annotates only a `behavior` (318): it reads each method's query meta and
      generates `Users.Sql(ctx: DbContext) implement Users` and `Users.of(ctx)`; on anything but a behavior
      an error at the annotation; a method with neither query annotation an error at the method
- [ ] `#[dbcontext.sql "…"]` — a template annotation (311, `01-checker` step 29) in erika's grammar: the query
      checked against the entity's `QueryTable` at build, its SQL and parameters recorded as typed meta; a
      `?T` answer requires `limit 1` (312)
- [ ] `#[dbcontext.nativeQuery("…")]`: the driver's SQL as a comptime string, verbatim; `:name` placeholders
      matched by name to the method's parameters (an unanswered placeholder or an unused parameter an error
      at the annotation); the leading-keyword (SELECT, INSERT, UPDATE, DELETE, WITH, CALL) and
      quote-next-to-placeholder checks of rakun's `#[query]`
- [ ] `Users.mock()` (`#[mocks.mock]`) on the same behavior; `reject/` cells for a `?T` without `limit 1`, a
      field the entity lacks, a placeholder no parameter answers

### Step 3 — rakun-data over dbcontext (after `04-rakun/128`)

- [ ] rakun-data's drivers (PostgreSQL, ETS) implement `dbcontext`'s `Driver`; the container registers
      `DbContext` and each generated repository by type (234) — 08 step 7's boxes
- [ ] rakun-data's `#[entity]` mapping, `#[repository]`, `#[nativeQuery]`, `#[query]`, the `<m>Sql()` members
      and `rkRegisterQuery` deleted there, its sites importing `from "dbcontext"` (one commit, 188)
- [ ] `dbcontext`'s `AGENTS.md` states the one consumer as the maintainer's exception to 115 (398 (4))

**Gate:** standard (fronts.md § Gate) + `botopink test` green on both targets in `repository/dbcontext`;
rakun-data's suite green after step 3
