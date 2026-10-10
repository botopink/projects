# Front 153 — dbcontext: botopink's JPA over erika (398)

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/dbcontext/**`; rakun-data's entity, repository and native-query code moving out (s3, consumer commit)
**Depends on:** 145 s1 (137 s2) · 144 B-18 (01-checker s29)
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `143-dbcontext` s1 | 153 s1 |
| `143-dbcontext` s2 | 153 s2 |
| `143-dbcontext` s3 | 153 s3 |

## Steps

### 153 s1 — entities and the context (143 s1)

#### Step 1 — entities and the context (was `143-dbcontext` s1)

- [ ] `entity(name)` and `column(name)`: record erika's `QueryTable(name, columns)` and
      `dbcontext`'s own entity meta (298); a field's column its name unless `column` says otherwise
- [ ] `behavior Driver` (running a statement — SQL text, bound parameters as erika's `QueryParam[]` (427) — and answering rows by column
      name, the error a parameter of the behavior) and `DbContext(driver: Driver) implement QueryContext`
      (erika's, 397): `self.db.query "…"` runs on it, one context for every entity
- [ ] rows decoded into the declared answer by column name; a `?T` answer meeting more than one row is the
      `single()` panic naming the statement (304); cells over a recording `Driver` on erlang and commonJS

### 153 s2 — repositories (143 s2)

#### Step 2 — repositories (was `143-dbcontext` s2)

- [ ] `repository` annotates only a `behavior` (318): it reads each method's query meta and
      generates `Users.Sql(ctx: DbContext) implement Users` and `Users.of(ctx)`; on anything but a behavior
      an error at the annotation; a method with neither query annotation an error at the method
- [ ] `#[query "…"]` — a template annotation (311, `01-checker` step 29) in erika's grammar: the query
      checked against the entity's `QueryTable` at build, its SQL and parameters recorded as typed meta; a
      `?T` answer requires `limit 1` (312)
- [ ] `#[nativeQuery("…")]`: the driver's SQL as a comptime string, verbatim; `:name` placeholders
      matched by name to the method's parameters (an unanswered placeholder or an unused parameter an error
      at the annotation); the leading-keyword (SELECT, INSERT, UPDATE, DELETE, WITH, CALL) and
      quote-next-to-placeholder checks of rakun's `#[query]`
- [ ] `Users.mock()` (`#[mocks.mock]`) on the same behavior; `reject/` cells for a `?T` without `limit 1`, a
      field the entity lacks, a placeholder no parameter answers

### 153 s3 — rakun-data over dbcontext (143 s3)

#### Step 3 — rakun-data over dbcontext (after `04-rakun/128`) (was `143-dbcontext` s3)

- [ ] rakun-data's drivers (PostgreSQL, ETS) implement `dbcontext`'s `Driver`; the container registers
      `DbContext` and each generated repository by type (234) — 08 step 7's boxes
- [ ] rakun-data's `#[entity]` mapping, `#[repository]`, `#[nativeQuery]`, `#[query]`, the `<m>Sql()` members
      and `rkRegisterQuery` deleted there, its sites importing `from "dbcontext"` (one commit, 188)
- [ ] `dbcontext`'s `AGENTS.md` states the one consumer as the maintainer's exception to 115 (398 (4))

**Gate:** standard (fronts.md § Gate) + `botopink test` green on both targets in `repository/dbcontext`;
rakun-data's suite green after step 3
