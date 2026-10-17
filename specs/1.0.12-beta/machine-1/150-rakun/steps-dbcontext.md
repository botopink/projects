# 150 rakun — the open steps of the former front 153 (dbcontext: botopink's JPA over erika (398))

Front 153 was refiled under 150 rakun by 165 s8: its open steps are 150 s48 … s51, in the workspace
package `rakun-data` (`rakun/modules/rakun-data/`, 165's table); its context folders moved into `machine-1/150-rakun/`. A step
here edits `rakun/modules/rakun-data/` (and what its text names), in lane "data" of `fronts.md` § Ownership; a done step stays in `status.md` Done.

**Depends on:** 145 s1 (137 s2) · 144 B-18 (01-checker s29)

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `143-dbcontext` s1 | 150 s48 |
| `143-dbcontext` s2 | 150 s49 |
| `143-dbcontext` s3 | 150 s50 |
| `153 s1` | 150 s48 |
| `153 s2` | 150 s49 |
| `153 s3` | 150 s50 |
| `153 Conformance` | 150 s51 |

## Steps

### 150 s48 — entities and the context (143 s1)

**Repository:** rakun (`--repo rakun`) · **Model:** sonnet

#### Step 1 — entities and the context (was `143-dbcontext` s1)

- [ ] `entity(name)` and `column(name)`: record erika's `QueryTable(name, columns)` and
      `dbcontext`'s own entity meta (298); a field's column its name unless `column` says otherwise
- [ ] `behavior Driver` (running a statement — SQL text, bound parameters as erika's `QueryParam[]` (427) — and answering rows by column
      name, the error a parameter of the behavior) and `DbContext(driver: Driver) implement QueryContext`
      (erika's, 397): `self.db.query "…"` runs on it, one context for every entity
- [ ] rows decoded into the declared answer by column name; a `?T` answer meeting more than one row is the
      `single()` panic naming the statement (304); cells over a recording `Driver` on erlang and commonJS

### 150 s49 — repositories (143 s2)

**Repository:** rakun (`--repo rakun`) · **Model:** sonnet

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

### 150 s50 — rakun-data over dbcontext (143 s3)

**Repository:** rakun (`--repo rakun`), and the consumer commits it names in their repositories (a full worktree, decision 188) · **Model:** sonnet

#### Step 3 — rakun-data over dbcontext (after `04-rakun/128`) (was `143-dbcontext` s3)

- [ ] rakun-data's drivers (PostgreSQL, ETS) implement `dbcontext`'s `Driver`; the container registers
      `DbContext` and each generated repository by type (234) — 08 step 7's boxes
- [ ] rakun-data's `#[entity]` mapping, `#[repository]`, `#[nativeQuery]`, `#[query]`, the `<m>Sql()` members
      and `rkRegisterQuery` deleted there, its sites importing `from "rakun-data"` (one commit, 188)
- [ ] `dbcontext`'s `AGENTS.md` states the one consumer as the maintainer's exception to 115 (398 (4))

**Gate:** standard (fronts.md § Gate) + `botopink test` green on both targets in `repository/rakun/modules/rakun-data`;
rakun-data's suite green after step 3

### 150 s51 — Conformance of the former front 153 (decision 465)

**Repository:** rakun (`--repo rakun`) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `rakun/conformance/rakun-data/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can
