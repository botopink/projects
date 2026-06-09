# TODO — erika

> Live checklist for branch `task/erika` (worktree `.tasks/erika/`).
> Spec (intent, immutable): [`tasks/v0.beta.6/specs/erika.md`](tasks/v0.beta.6/specs/erika.md)

> **Goal**: a C#/LINQ-style query lib as a **pure-`.bp` std module**
> (`libs/std/src/erika.bp`) — a `record Query<T>` over `Array<T>` with fluent
> operators — **plus** an `erika "select … from …"` query-string built as an
> `@Expr` template fn (`q.text()`/`q.lookup()`/`q.build()`), reusing the
> already-shipped expr-templates machinery. **No compiler surface**: only
> `erika.bp` + one line each in `build.zig` (`std_bp_files`), `prelude.zig`, and
> `comptime.zig` (`std_pkg_modules`). Eager + immutable v1.

> **Status: DONE.** 19 inline `test` blocks pass under `botopink test`; `zig build
> test` green; other `libs/*` packages unaffected. Zero compiler-logic surface
> (wiring-only). Deferred items + the one user-facing gap are recorded below.

## F0 — module skeleton + wiring ✅
- [x] `record Query<T> { items }` + `record Grouping<K,V>`; constructors
      (`of`/`range`/`repeat`/`empty`), `toArray`/`toList`
- [x] Wire `build.zig` `std_bp_files` + `prelude.zig` (`erika_mod`) +
      `comptime.zig` `std_pkg_modules`; `import {erika} from "std"` resolves and
      `erika.of(...)` runs (verified in a scratch user project + libs/std tests)
- [x] Constructor spelling locked to **`of`** — `from` is the `import` keyword and
      is rejected as a fn name (`UnexpectedToken`); `of` matches `Pair.of`

## F1 — restriction / projection (fluent) ✅
- [x] `where`, `select` — `cast`/`ofType` skipped (no runtime type tags)
- [~] `selectMany` **deferred to v2**: needs an array/generic return inside a
      function-type parameter (`fn -> Query<U>`/`-> U[]`), which the parser
      rejects (catalogued `fn() -> T[]` gap). Workaround documented in AGENTS.

## F2 — partitioning / ordering (fluent) ✅
- [x] `take`, `skip`, `takeWhile`, `skipWhile`, `reverse`
- [x] `orderBy`, `orderByDescending` (stable insertion sort by projected key via
      generic `<`). `thenBy` → v2 (not needed for v1)

## F3 — set ops / grouping / joining (fluent) ✅
- [x] `distinct`, `distinctBy`, `concat`, `union`, `intersect`, `except`
- [x] `groupBy -> Query<Grouping<K,T>>`; `zip`. `join` → v2 (use `zip`/fluent)

## F4 — aggregation / element / quantifiers (terminals) ✅
- [x] `count`, `countWhere`, `sum`, `min`, `max`, `average`, `aggregate`
      (no arity overloading — JS backend mangles same-named methods → `countWhere`)
- [x] `first`, `firstWhere`, `last`, `single`, `elementAt` → `?T`
- [x] `any`, `anyWhere`, `all`, `contains` → `bool`

## F5 — the `erika "…"` template fn (over `@Expr`) ✅ (in-file)
- [x] `pub fn erika<T>(comptime q: @Expr<string>) -> @Expr<T>` in `erika.bp`
- [x] botopink SQL-subset parser (self-contained, inlined): `select <*|field>
      from <Name> [where <cond>] [order by <field> [asc|desc]]`; `<cond>` =
      `field <op> literal/field` (`== != < <= > >=`, `=`, `<>`, `and`/`or`)
- [x] resolve `from <Name>` via `q.lookup`; unknown collection ⇒ `q.fail`
- [x] build + expand the fluent pipeline; `@Expr<T>` reveals the result type
      (`select *` ⇒ `Array<Row>`; `select field` ⇒ `Array<FieldType>`)
- [x] F5b: multi-field `select a, b` ⇒ clear `q.fail` not-yet (anon records/tuples)
- [x] zero new compiler surface confirmed; gaps recorded (see below)
- [!] **User-facing gap (recorded, NOT fixed — preserves zero-surface):**
      `erika "…"` only resolves where `erika` is a directly in-scope template fn
      (e.g. this module's own tests, which is how it's covered). After
      `import {erika} from "std"` it is `unbound` — the import binds the `erika`
      *namespace* (so `erika.of(...)` works) but not the same-named template fn as
      a value. Fix = small compiler add in `infer.zig markStdImports` /
      `comptime.zig registerStdlib` (bind a std module's same-named template fn
      into the importer's value scope + `templateFns`/`exprParams`). See AGENTS.

## F6 — docs ✅
- [x] `erika` row in `libs/std/src/docs.md` + worked `examples.md` example (fluent
      and `erika "…"` forms); `libs/std/AGENTS.md` updated (tree, roles, tests,
      coverage, + an "erika caveats" section) in the same commit.
      (Note: spec said `libs/std/src/AGENTS.md`; the maintained file is
      `libs/std/AGENTS.md` — a src-level AGENTS.md does not exist.)

## Notes / recorded language+compiler findings (from building erika)
- `from` is a reserved keyword → cannot name a fn (use `of`).
- No arity-based method overloading: same-named methods type-check but the JS
  backend collides them at runtime → distinct names (`countWhere`/`firstWhere`/…).
- `&&`/`||` do **not** parse directly inside `if (...)` — pre-bind to a `val`.
- if-**expression** branch blocks need trailing `;` (`{ x; }`, not `{ x }`).
- if/else where the two branches end in **different-typed** assignments unifies
  the branch types → false "expected bool, got string"; use separate guarded ifs.
- Array/generic return types are rejected inside a **function-type parameter**
  (`fn -> T[]` / `fn -> Foo<U>`) — blocks `selectMany`.
- Optional `if (opt) { x -> … }` does **not** gate on absence at commonJS runtime
  (runs the body even when absent); only its present-case is reliable. `at()` OOB
  + `.unwrapOr(d)` is the safe absence path (used by `single`/element terminals).
- `Array.range`/`Array.repeat` aren't lowered by commonJS → `range`/`repeat`
  recurse; no `i32→f64` cast → `average` takes an `f64` selector.
- The comptime template evaluator (`template_eval.zig`) emits **only** the
  template fn and runs it with `node` over a tiny prelude: method calls lower to
  **native JS** methods (`split`/`slice`/`trim`/`join` ok) but host-helper ops
  (optional `.unwrapOr`, `.append`) are undefined there → the `erika "…"` body is
  self-contained and avoids them.
- `erika.md` spec was dropped into this worktree directly — reconcile on merge.
