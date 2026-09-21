# Front 78 — rakun Entities and Derived Queries

**Track:** B rakun
**Priority:** high — front 08 delivers a SQL template and a `#[repository]` marker, so every application writes its own row-to-record mapping by hand; that hand-written mapping is the work Spring Data exists to remove, and it is the work people get wrong
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 08 · 14 — front 77 consumes this front's entity metadata for `ddl-auto`
**Owns:** `modules/rakun-data/src/orm/**` · `modules/rakun-data/test/orm/**`
**Does not touch:** `modules/rakun-data/src/datasource.bp` and `src/sql/**` — front 08's, consumed read-only · `modules/rakun-data/src/migration/**` — front 77's · `modules/rakun-data/src/nosql/**` — front 09's · `src/decorators.bp` and the other three frozen files
**Reference:** `05-data.md § JPA e Spring Data JPA` (Entity, Repository, Configuracao JPA), `§ Spring Data JDBC`, `§ Spring Data Envers`, `§ jOOQ` · <https://docs.spring.io/spring-boot/reference/data/sql.html#data.sql.jpa-and-spring-data>
**Replaces:** new — no front in `1.0.6-beta` proposed it

---

## Problem

Front 08 stops at the wire. `Rows` is a column list and a list of string lists; `Row.get(column)`
answers a string, `Row.int(column)` answers an integer, and that is the whole of the type story
(`08-rakun-data-sql/README.md`, *`SqlTemplate` and the fluent client* — which says in as many words
that typed row-to-record mapping is this front's). So a service that wants a `City` writes the
`select`, writes the column list, writes the six `r.get("…")` calls, and writes them again in the
update path with the column names in a different order.

Every part of that is mechanical and every part of it is a place to make a mistake that the compiler
cannot see: a renamed column, a swapped pair of same-typed fields, a `null` read as `""`. Spring Data's
answer is to derive it — the entity declares the mapping once, and the repository declares its queries
by **method name**, with `findByNameAndStateAllIgnoringCase` parsed into SQL
(`05 § Repository`).

That derivation is the single most botopink-shaped feature in the entire Spring surface. Spring does it
with runtime proxies and reflection; here it is a comptime decorator reading a reflected declaration and
emitting a function, which means the SQL exists before the program runs and a method name that does not
parse is a compile error rather than a startup exception.

## Current state

| Piece | Where it is today |
|---|---|
| `SqlTemplate.query/update/single/transaction`, `tryQuery`, `tryUpdate` | front 08, `modules/rakun-data/src/sql/**` |
| `Rows`, `Row(get/int/bool)`, `Param`, `param(name, value)` | front 08 |
| `#[query("…")]` with a real body calling `__rkQuery_<name>()` | front 08 |
| `#[repository]`, `#[transactional]` | front 08 (`#[transactional]` as a type-level proxy emitter) |
| Constraint decorators and the violation report | front 14 |
| Any entity mapping, identity, generated key or relation | none |
| Any derived query | none |
| Any `Page`/`Sort`/`Slice` | none |
| Audit columns or revision history | none |
| Schema generation from entities | front 77 consumes what this front produces; neither exists yet |

## Mechanism

### `#[entity]` — mapping declared once

```bp
#[entity("cities")]
pub type City(
    #[id]
    #[generated]
    id: i32,

    name: string,

    #[column("state_name")]
    state: string,

    #[version]
    revision: i32,
)
```

The decorator is type-level, so it sees `decl.fields` with each field's own `annotations` — the same
reflection `#[component]` already uses to find `#[value]` (`src/decorators.bp:52-53`). From it the
decorator emits a metadata table and a mapper pair:

```bp
pub fn __rkEntity_City_table() -> string;            // "cities"
pub fn __rkEntity_City_columns() -> string;          // "id|name|state_name|revision"
pub fn __rkEntity_City_fromRow(r: Row) -> City;
pub fn __rkEntity_City_params(c: City) -> Param[];
```

Column naming is `camelCase → snake_case` unless `#[column("…")]` overrides it. The conversion is done
in the decorator body, where only native-JS string operations are available — no `charCodeAt`, no `?T`
— so the case test is `"ABCDEFGHIJKLMNOPQRSTUVWXYZ".indexOf(ch) >= 0` over the characters the name
splits into. That is not a trick; it is the shape every comptime string routine in this milestone takes.

Field annotations, in full:

| Annotation | On | Effect |
|---|---|---|
| `#[id]` | one field | Primary key. Exactly one per entity, enforced at comptime |
| `#[generated]` | the id field | Value comes back from the insert; not sent |
| `#[column("name")]` | any field | Override the derived column name |
| `#[version]` | one integer field | Optimistic locking; incremented on update, checked in the `where` |
| `#[createdAt]` / `#[updatedAt]` | one timestamp field each | Audit columns, written by the mapper |
| `#[createdBy]` / `#[updatedBy]` | one string field each | Audit columns, filled from front 10's principal |
| `#[transient]` | any field | Not a column at all |

### Derived queries, and why the decorator is on the type

A repository method's SQL is derived from its **name**, and the derivation has to check the predicate's
placeholder count against the method's parameter list. A method-level `@Decl` exposes no parameter list
— front 08 recorded that gap and had to document the check as absent. A **type-level** `@Decl` does:
`decl.methods[i].params` is `Param[]` on the reflection handle
(`libs/std/src/builtins.d.bp:441-447`). So the derivation lives on a type-level marker that walks the
methods, exactly as `#[restController]` walks them looking for `#[getMapping]`:

```bp
#[repository]                       // front 08's stereotype, unchanged
#[entityRepository("City")]         // this front
pub type CityRepo(sql: SqlTemplate) {
    #[derived]
    pub fn findByNameAndStateAllIgnoringCase(self: Self, name: string, state: string) -> City[] {
        // LANGUAGE GAP: no bodyless method in a `type` body
        return __rkDerived_CityRepo_findByNameAndStateAllIgnoringCase(self.sql, name, state);
    }
}
```

The one-line forwarding body is the shape front 08 already established for `#[query]` and
`__rkQuery_<name>()`; the helper is named `__rkDerived_<Type>_<method>` so the two namespaces cannot
collide. Both exist because a method in a `type` body must have a body
([`language-gaps.md`](../../language-gaps.md)), and a decorator adds declarations rather than rewriting
one.

That gap is worth naming precisely rather than lamenting: with abstract methods in a `type` body, the
line above becomes `#[derived] pub fn findByNameAndState(self: Self, name: string, state: string) -> City[];`
and reads exactly like its upstream. It is one compiler change away, and it is the change that would do
the most for this front's surface.

### The name grammar

```
<prefix> [Distinct] By <predicate> [OrderBy <field> (Asc|Desc)]
```

| Prefix | Produces |
|---|---|
| `findBy` / `findAllBy` | `City[]` |
| `findFirstBy` / `findTopBy` | `?City` |
| `countBy` | `i32` |
| `existsBy` | `bool` |
| `deleteBy` | `i32` (rows affected) |

Predicate terms are joined by `And` or `Or`, left to right with no precedence — the same rule Spring
Data has, and the same reason: a name is not a place to express grouping. Each term is a field name
optionally followed by an operator keyword:

| Keyword | SQL | Parameters |
|---|---|---|
| *(none)* | `= :p` | 1 |
| `Not` | `<> :p` | 1 |
| `GreaterThan` / `LessThan` / `GreaterThanEqual` / `LessThanEqual` | `> < >= <=` | 1 |
| `Between` | `between :a and :b` | 2 |
| `In` / `NotIn` | `in (…)` | 1 (a list) |
| `Like` / `NotLike` / `StartingWith` / `EndingWith` / `Containing` | `like` with the pattern built at run time | 1 |
| `IsNull` / `IsNotNull` | `is null` / `is not null` | 0 |
| `True` / `False` | `= true` / `= false` | 0 |
| `IgnoringCase` (per term) / `AllIgnoringCase` (whole predicate) | wraps both sides in `lower(…)` | unchanged |

The comptime check is the point of the whole design: the sum of the terms' parameter counts must equal
the method's declared parameter count, minus `self` and minus a trailing `Pageable`. A mismatch is a
compile error naming the method, the parsed predicate and both counts. A field name that is not a field
of the named entity is likewise a compile error naming the entity and listing its fields — `findByCiudad`
never reaches a database.

### Paging and sorting

```bp
pub type Sort(field: string, descending: bool)
pub type Pageable(page: i32, size: i32, sort: Sort[])
pub type Page<T>(content: T[], page: i32, size: i32, totalElements: i32) {
    pub fn totalPages(self: Self) -> i32;
    pub fn hasNext(self: Self) -> bool;
}
pub type Slice<T>(content: T[], page: i32, size: i32, hasNext: bool)
```

A method whose last parameter is `Pageable` and whose return is `Page<City>` gets two statements: the
page query with `limit`/`offset`, and the count query with the same `where` and no `order by`. A
`Slice` return gets one statement that fetches `size + 1` rows and reports `hasNext` from the extra —
which is the right default for an infinite scroll and costs nothing, where a count on a large table
costs a scan. Spring offers both for the same reason and this front ships both.

A `Sort` field that is not a column is a run-time failure naming the field, not a string spliced into
the statement: sort fields arrive from query parameters, and splicing one is an injection.

### Relations: explicit joins, no proxies

There is no lazy loading, and therefore no `open-in-view` (`05 § Configuracao JPA` — the property is
out of scope for this port, and this is why). A relation is declared as a join and fetched when the
method says so:

```bp
#[entity("orders")]
pub type Order(
    #[id] #[generated] id: i32,
    #[column("customer_id")] customerId: i32,
    cents: i32,
)

#[belongsTo("Order", "customerId", "Customer", "id")]
pub type OrderWithCustomer(order: Order, customer: Customer)
```

`#[belongsTo]` emits a mapper over the joined row set; a method returning `OrderWithCustomer[]` gets a
statement with the join in it. Nothing is loaded that the method did not ask for, and nothing is loaded
after the connection went back to the pool — the two failure modes lazy loading exists to produce.

The arguments are four strings rather than two types, because a decorator argument cannot name a type:
decorator arguments are ordinary values checked against the signature and there is no type-of-type. The
strings are checked against the emitted entity metadata at comptime, so a typo is still a compile error.

### Writes, and immutability

Records are immutable and there is no assignment to a `self` field
([`language-gaps.md`](../../language-gaps.md)). That is not an obstacle here; it is the correct model for
a row:

```bp
pub fn save(self: Self, c: City) -> City;      // returns a NEW City carrying the generated id
pub fn update(self: Self, c: City) -> City;    // returns a NEW City carrying the incremented version
pub fn delete(self: Self, c: City) -> i32;
```

`save` on an entity with a `#[generated]` id omits the id column from the insert and reads it back
(`returning id` where the driver supports it, a driver-specific last-insert-id query where it does not).
`update` on an entity with a `#[version]` field adds `and revision = :revision` to the `where` and
increments it; zero rows affected is an optimistic-lock failure, raised with the table, the id and both
versions — never silently ignored, because a silent lost update is the bug this column exists to
prevent. Audit columns are filled by the mapper on the way out, not mutated on the caller's record.

### The typed query builder — the jOOQ analogue

Derivation cannot express everything, and the alternative should not be a string. `#[entity]` emits two
sibling values per entity — the table metadata and one column-name constant per field — and the builder
takes those:

```bp
// emitted by #[entity("cities")] on City
pub type CityColumns(id: string, name: string, state: string, population: string)
pub val CityCol = CityColumns(id: "id", name: "name", state: "state_name", population: "population");
pub val CityMeta = EntityMeta(table: "cities", columns: "id|name|state_name|population");
```

```bp
val rows = queryOf(CityMeta)
    .where(CityCol.state, "=", "CA")
    .and(CityCol.name, "like", "San%")
    .orderBy(CityCol.name, false)
    .limit(50)
    .fetch(self.sql);
```

`CityCol.state` is a field read on an emitted record, so a renamed field is a compile error at every
call site rather than a run-time `column does not exist`. That is what jOOQ's generated classes buy
(`05 § jOOQ`), obtained here from the entity declaration instead of from a code-generation step run
against a live database.

They are **sibling values rather than members of `City`** for a mechanical reason: `@emit` splices new
module-level declarations and a decorator cannot add a member to the type it annotates. `City.state` is
therefore not available and `CityCol.state` is; the naming convention is `<Entity>Col` and `<Entity>Meta`,
fixed, so a reader never has to guess it.

### Revision history — optional, per entity

Spring Data Envers keeps a revision table per audited entity (`05 § Spring Data Envers`). Here it is
opt-in on the entity and nowhere else:

```bp
#[entity("cities")]
#[revisions]
pub type City(…)
```

`#[revisions]` emits a second table mapping (`cities_revisions`, the entity's columns plus
`revision_number`, `revision_type` ∈ `insert|update|delete`, `revision_timestamp`, `revision_author`)
and makes every write through the generated repository append a row inside the same transaction as the
write it records. Without the annotation nothing is written and no table is generated — an audit trail
that is on by default is a storage bill nobody agreed to, and one that is written outside the write's
transaction is a trail with holes.

The read surface is three methods that `#[entityRepository]` emits **onto the repository** when its
entity carries `#[revisions]`, so they are typed at the entity rather than taking its name as a string:
`revisionsOf(id) -> Revision<City>[]`, `revisionAt(id, timestamp) -> ?City` and
`revisionNumbers(id) -> i32[]`. A repository whose entity is not audited has none of the three, and
calling one is a compile error rather than an empty list. There is no "restore this revision" operation:
reconstructing a past row is a query, but writing it back is a business decision with its own audit
implications, and the framework should not pretend otherwise.

## Steps

### Step 1 — `#[entity]` and the mapper pair

**Acceptance:**
- [ ] `camelCase` fields map to `snake_case` columns; `#[column("x")]` overrides
- [ ] An entity with no `#[id]`, or with two, is a compile error naming the entity
- [ ] `#[transient]` fields appear in neither the column list nor the params
- [ ] `__rkEntity_<T>_fromRow` and `__rkEntity_<T>_params` round-trip a record: `fromRow(rowOf(params(c))) == c`
- [ ] A `#[version]` field on a non-integer type is a compile error
- [ ] The emitted table name is the decorator's argument, and an entity with an empty table name is a compile error

### Step 2 — the name grammar and its comptime check

**Acceptance:**
- [ ] `findByName` derives `select … from cities where name = :name`
- [ ] `findByNameAndStateAllIgnoringCase` lowers both sides of both terms
- [ ] `findByPopulationBetween` consumes two parameters and a method declaring one is a compile error naming both counts
- [ ] `findByNameIsNull` consumes zero parameters
- [ ] `countBy…` returns `i32`, `existsBy…` returns `bool`, `deleteBy…` returns rows affected
- [ ] `findFirstByStateOrderByNameDesc` produces `order by name desc limit 1` and returns `?City`
- [ ] `findByCiudad` is a compile error naming the entity and listing its fields
- [ ] `And`/`Or` bind left to right with no precedence, asserted against a literal expected statement
- [ ] Every derived statement is asserted against a literal string, not against "contains"

### Step 3 — paging, slicing and sorting

**Acceptance:**
- [ ] A `Pageable` last parameter with a `Page<City>` return produces two statements; the count statement carries the same `where` and no `order by`
- [ ] `Page.totalPages` rounds up and `hasNext` is false on the last page
- [ ] A `Slice<City>` return fetches `size + 1` rows, returns `size`, and reports `hasNext` from the extra
- [ ] `Sort` fields are appended in order, each with its own direction
- [ ] A `Sort` field that is not a column fails at run time naming the field and is never spliced into the statement
- [ ] `size = 0` is refused with a message rather than producing `limit 0`

### Step 4 — writes, identity and optimistic locking

**Acceptance:**
- [ ] `save` on a `#[generated]` id omits the column and returns a record carrying the assigned value
- [ ] `save` on a non-generated id sends the caller's value
- [ ] `update` increments `#[version]` and returns the new record; the caller's record is unchanged
- [ ] `update` with a stale version affects zero rows and raises, naming the table, the id, the expected version and the stored one
- [ ] `delete` returns rows affected and is version-checked when the entity has a `#[version]`
- [ ] `#[createdAt]` is written only on insert; `#[updatedAt]` on both
- [ ] `#[createdBy]`/`#[updatedBy]` take front 10's principal, and are written as `""` outside a request rather than failing

### Step 5 — relations

**Acceptance:**
- [ ] `#[belongsTo]` naming a field that is not a field of the owning entity is a compile error
- [ ] `#[belongsTo]` naming an entity that carries no `#[entity]` is a compile error
- [ ] A method returning the joined record produces one statement with a join, asserted against a literal
- [ ] Nothing is fetched that the method did not name — a test asserts the statement count for a fetch of 100 joined rows is 1
- [ ] A left join is expressible and produces an optional half rather than a fabricated empty record

### Step 6 — the typed query builder

**Acceptance:**
- [ ] `City.state` is an emitted constant and renaming the field breaks every call site at compile time
- [ ] `where`/`and`/`or`/`orderBy`/`limit`/`offset` compose into one statement, asserted against a literal
- [ ] Values go through `Param`, never into the statement text — a test passes `'; drop table cities; --` as a value and asserts the table still exists
- [ ] An operator outside the accepted set is a compile error, not a spliced string
- [ ] The builder and a derived query for the same predicate produce byte-identical SQL

### Step 7 — revision history

**Acceptance:**
- [ ] Without `#[revisions]`, no revision table is generated and no revision row is written
- [ ] With it, insert, update and delete each append exactly one row with the right `revision_type`
- [ ] The revision row is written in the same transaction as the write: a rolled-back write leaves no revision
- [ ] `revisionsOf(id)` returns rows in revision-number order
- [ ] `revisionAt(id, timestamp)` returns the state as of that instant, and the empty optional before the first revision
- [ ] A repository whose entity is not audited has none of the three methods, and calling one is a compile error
- [ ] `revision_author` is front 10's principal, `""` outside a request
- [ ] There is no restore operation, and a test asserts the surface has exactly the three read methods

### Step 8 — metadata for front 77

**Acceptance:**
- [ ] `entityNames()`, `entityTable(entity)`, `entityColumns(table)` and `entityColumnType(table, column)` are exported and cover every `#[entity]` in the build. `entityColumns` is keyed by **table** name, returns the pipe-joined column list, and answers `""` for a table nothing declared — which is how the absence of a revision table is checkable
- [ ] Front 77's `ddl-auto=validate` can detect a missing column, an extra column and a type mismatch from this metadata alone
- [ ] A `#[revisions]` entity contributes its revision table to the same metadata, so `validate` covers it too

## Examples

- [`examples/city-entity-example.bp`](./examples/city-entity-example.bp) — the reference's own `City`
  example carried the whole way: the entity, a derived-query repository, a page, and the typed builder
  for the query derivation cannot express.
- [`examples/audit-and-revisions-example.bp`](./examples/audit-and-revisions-example.bp) — audit
  columns, optimistic locking against a stale write, and revision history opted into on one entity and
  not the other.

## Language gaps

Two rows in [`language-gaps.md`](../../language-gaps.md) bite this front directly and are marked in the
examples. Both are already recorded there; this table names where they land here.

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **No bodyless method in a `type` body** (recorded for 08 · 09; add 78) | `examples/city-entity-example.bp`, every `#[derived]` method | A one-line body forwarding to the emitted `__rkDerived_<Type>_<method>` helper | Abstract methods in a `type` body, filled in by the decorator's emission. For this front it is the difference between `#[derived] pub fn findByNameAndState(…) -> City[];` and the same line plus a forwarder |
| **No assignment to a `self` field** (recorded, no front had needed it) | `examples/audit-and-revisions-example.bp` — `save` and `update` return new records rather than mutating | Return a new value; the generated id and the incremented version come back in the returned record | Either a mutable field form, or the documented statement that records are immutable by design. This front is evidence for the second: immutability is the right model for a row, and the only cost is that the caller must use the return value |

A third gap bites here too and is recorded by front 72, which found it first: **a decorator argument
cannot name a type**. That is why `#[entityRepository("City")]` and
`#[belongsTo("Order", "customerId", "Customer", "id")]` take strings. They are checked against the
emitted entity metadata at comptime, so a typo is still a compile error — the loss is in how the line
reads, not in what it catches. Front 72's table carries the row; this front is a second *Bites* entry
for it.

## Test plan

`modules/rakun-data/test/orm/` — `entity_test.bp`, `derivation_test.bp`, `paging_test.bp`,
`write_test.bp`, `relation_test.bp`, `builder_test.bp`, `revision_test.bp` — run with
`botopink test --target erlang` from `modules/rakun-data/` and in the gate through
`zig build test-libs -- --target erlang`.

**The derivation tests assert literal SQL strings.** Every one of them names a method and the exact
statement it must produce, because "produces valid SQL" is not falsifiable and "equals this string" is.
That also makes the test file the grammar's documentation: the table in *The name grammar* above is
generated from nothing, but every row of it has a test that pins it.

Comptime failures — a wrong parameter count, an unknown field, two `#[id]` fields — are compile errors
and cannot be expressed as a runtime `assert`. They live in the compiler's own annotation-processor
suite, the way front 08 and `repository/rakun/test/di_test.bp:14-16` already record for existing
markers. This front's `.bp` tests assert only what produces a value.

**Every test runs against front 08's ETS arm**, per front 08's rule: a gate that needs PostgreSQL is a
gate that is red on somebody's laptop. The ETS arm must answer enough SQL for the statements these tests
derive, which is exactly the set the derivation tests enumerate — so the coverage of the arm and the
coverage of the grammar are the same list, and neither can drift ahead of the other. Driver-specific
behaviour (`returning id` versus last-insert-id) is covered by a manual check against real PostgreSQL
and MySQL, recorded in the module's README rather than implied by a green run.

This front is erlang-only; the module's manifest declares `"target": "erlang"` and the commonJS cell
reports *skipped*.

## Definition of done

- `#[entity]` maps a record to a table, with id, generated keys, version, audit columns and transients
- Derived queries parse at comptime, check their parameter count against the method's real parameters,
  and produce SQL asserted against literals
- An unknown field or a wrong parameter count is a compile error, not a run-time surprise
- `Page`, `Slice` and `Sort` work, and a sort field is never spliced into a statement
- `save`/`update`/`delete` return new records, and a stale version raises rather than losing an update
- Relations are explicit joins with no lazy loading anywhere
- The typed builder makes a renamed column a compile error at every call site
- Revision history is opt-in per entity, written in the same transaction, with no restore operation
- Front 77 can drive `ddl-auto=validate` from this front's exported metadata
- Both language-gap rows above are reflected in [`language-gaps.md`](../../language-gaps.md) with 78 added
  to their *Bites* column
- The front's tests are green on its assigned target
