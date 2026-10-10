# Front 145 — erika: the database target, `erika-test`, the `;` migration

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/erika/**`
**Depends on:** 144 B-18 (311 / 397: 01-checker s29 and s41, landing) · B-28 (s3)
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `137-erika-sql` s2 | 145 s1 |
| `137-erika-sql` s3 | 145 s1 |
| `137-erika-sql` s4 | 145 s1 |
| `137-erika-sql` s5 | 145 s1 |
| `98-packaging-tail` s1 | 145 s2 |
| `07-residuals` s10 | 145 s3 |

## Steps

### 145 s1 — erika queries a database (137)

#### Step 2 — `QueryContext`, `QueryTable` and the SQL target (397) (was `137-erika-sql` s2)

- [x] `pub behavior QueryContext` in `erika.bp`: running a statement (SQL text and bound parameters) answering
      `@Result<T[], E>`, the error a parameter of the behavior, so erika names no library's error (the exact
      signature in `docs.md`); `pub type QueryTable(name: string, columns: QueryColumn[])` and
      `QueryColumn(field, column)`, the meta a persistence library records on an entity
- [ ] typed parameters (427): `pub type QueryParam { Int, Float, Text, Bool, Bytes, Null }`; `QueryContext<E>` declares
      `runMany<T>(sql, params: QueryParam[], decode)` / `runOne<T>(…) -> @Result<?T, E>` (426) and `run(sql, Array<string>)`
      goes; each hole's variant from the field its column is (`?T` → `Null` or the variant), a `limit` hole `Int`; a hole of
      another type an error at the hole — `reject/erika_hole_type_mismatch`, the recording context's params per variant
- [ ] `query`, erika's template method on every `QueryContext` — `pub fn query<E>(comptime self: @Expr<QueryContext<E>>,
      comptime q: @Expr<string>) -> @Expr<@Result<unknown[], E>>` (397 (3), 415; the template method is `01-checker` step 29's): `self.db.query "select * from User where active = true"`; an `Array<T>`
      source keeps the in-memory form (`erika "…"`, today's fluent pipeline)
- [ ] `from User` names a type, resolved at the call site (`e.lookup`, 112): not imported is an error at the
      token; on a `QueryContext` it reads `q.lookup("User")`'s `@Decl` and its `meta(QueryTable)` at build (415, `01-checker` step 39) — no meta is an error at
      the query ("`User` is not an entity"), a field `User` lacks an error at the field —, and the SQL text with
      `$1…$n` parameters in hole order is built at build from the type's table and columns
- [ ] cells: the SQL text and parameters a recording `QueryContext` receives, for every clause; an entity
      read through two tables' types on one context

#### Step 3 — the number of rows is written (was `137-erika-sql` s3)

- [ ] an answer `?T` requires `limit 1`, an answer `T[]` (or `Array<T>`) refuses it; a mismatch is a
      compile error at the query naming the declared answer (decision 312) — `query` builds `runOne` (`@Result<?Row, E>`)
      under `limit 1`, `runMany` (`@Result<Row[], E>`) otherwise, and the call's type is the built code's (426), with
      `q.note("query answers a list — add limit 1 for ?User")` on the list branch
- [x] in memory `limit n` is `take(n)`; `?T` answers `first()`

#### Step 4 — the grammar grows (was `137-erika-sql` s4)

- [ ] `limit <n>` (a number or a hole), `join <Type> on <a.f> = <b.g>` (inner), the aggregates
      `count(*)`, `sum`, `avg`, `min`, `max` with `group by` — each on both targets, each with a located
      error for its malformed forms (`q.failAt`)
- [x] the erlang cells of this step need no padding: built code is located by its expansion (`01-checker` step 41,
      429), and `erika.bp` builds the pipeline alone
- [ ] the aggregates by 428, one answer in memory and in SQL: `count(f)` on a `?T` field (non-null rows; refused on a
      field that is not optional, naming `count(*)`); `sum` over `i32` / `i64` → `i64`, over `f64` → `f64`, `0` for no rows
      (`coalesce(sum(x), 0)` in the SQL); `avg` over a number → `?f64`, `null` for no rows; the built refusals kept — cells
      over an empty source and a `?T` field on both targets
- [x] the grammar block of `docs.md` rewritten; `examples.md` gains one example per clause

#### Step 5 — the template annotation `#[erika "…"]` (after `01-checker` step 29) (was `137-erika-sql` s5)

- [ ] `erika` used as an annotation on a method (decision 311): the query checked against the
      method's parameters (each `${…}` a parameter, by name and type) and its declared answer (step 3);
      the result recorded as typed meta of the method (298) — the SQL text with its parameter order —
      for a type-level decorator to read (`#[repository]`, rakun 08 step 7)
- [ ] on anything but a method it is an error at the annotation; with `${…}` naming no parameter, the
      ordinary unbound-name error at the hole
- [ ] `run/` cell: a test behavior whose type-level test decorator reads the meta and asserts it

**Gate:** standard (fronts.md § Gate) + `botopink test` in `modules/erika` and `modules/erika-test` on
commonJS and erlang, `botopink build` of `examples/erika-linq`, erika's pre-commit hook green.

### 145 s2 — `erika-test`'s first helper and `erika-linq`'s README (98)

#### Step 1 — `erika-test`'s first helper and `erika-linq`'s README (was `98-packaging-tail` s1)

`modules/erika-test/src/asserts.bp`: `assertRows(loc: SourceLocation, q: Query<T>) ->
@Result<void, string>`, `q.toArray()` one row per line through `snapshots.assertAs(loc, "rows",
text)`; `test/asserts_test.bp`, one accepted snapshot per target-shared file.
`examples/erika-linq/README.md`: the LINQ operators it mirrors; erika has no front this milestone.

- [ ] `zig build test-libs` reads `erika-test · commonJS: pass` and `erika-test · erlang: pass` with
      2 tests; `examples/erika-linq/test/__snapshots__/` absent (example tests are inline)
- [ ] `repository/erika/AGENTS.md` names the helper

### 145 s3 — erika's C-13 migration and C-12 reformat (after 144 B-28)

#### Step 10 — erika's C-13 migration and C-12 reformat (was `07-residuals` s10)

erika has no track: `16-formatter/c13-migrate.py` over erika (28 sites at 1.0.10 — `16-formatter`
step 1 re-counts), then `botopink format` at C-12's rules once `16-formatter` step 6 (decision 345) lands.

- [ ] erika's `;` sites migrated by the script, cells green before/after, `botopink format --check` exit 0; reformat token-identical, idempotent
- [ ] erika's gate (`scripts/git-hooks/pre-commit`: `botopink test` per member, `botopink build` per example) green; `zig build test-libs -- --lib erika` / `--lib erika-linq` green in the meta worktree
