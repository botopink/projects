# Front 130 — decorator outputs

**Priority:** high — every framework writes its wiring through decorators, and the one output they
had (`@emit`) produced code nobody else could name.
**Depends on:** decision 216 (the four places, built in order); `00-gate` landed.
**Owns:** `repository/botopink-lang/modules/compiler-core/src/comptime/{reflection,assoc_types,typeinfo_all}.zig`
and the decision-216 parts of `comptime.zig`, `comptime/{infer,env,decorator_eval,diagnostics,transform}.zig`,
`comptime/runtime/prelude.zig`, `parser/exprs.zig` · `libs/std/src/builtins.d.bp` (the `Decl` surface and
the `Declared` records) · `libs/std/src/testing/mocks.bp` · `libs/validation/src/decorators.bp` ·
`docs.md` § Decorators · the `tests/language` cells named below · then each library's decorator files
(step 5).
**Does not touch:** the import resolver (front 129), the checker rows of `01-checker`, the backends
(02/03/04/05).

---

## Problem

A decorator (a `comptime` fn whose first parameter is `@Decl`) had one output, `@emit("…")`, which
spliced loose source into the annotated declaration's module. Measured at the open: emitted code is
never exported (even `pub`), an emitted `val` is not seen by the module's own source, so libraries
emit `fn __rk…` functions called only by other generated code and register each declaration with a
module-level `val __rkScan_X = rkScan("X")` evaluated at load. 119 `@emit` call sites in the
libraries: rakun 109, jhonstart 6, std 2, validation 2.

## Current state — the four places (steps 1–4, built)

| Place | Written in a decorator | Read | Refused |
|---|---|---|---|
| member of the annotated type | `decl.addMember("pub fn fromRow(r: Row) -> Self { … }")` | `City.fromRow(r)`, `c.describe()`; travels with the type to every importer | `decorator-member-without-type` (from a `fn`'s decorator), `decorator-member-duplicate`, `decorator-member-not-one-fn` |
| comptime meta, per decorator | `decl.setMeta("table", "cities")` | `@typeInfo(City).meta.entity.table`, `@typeInfo(City).name` — string constants | `decorator-meta-on-member`, `decorator-meta-duplicate`, `typeinfo-unknown-member`, `typeinfo-unknown-declaration`, `typeinfo-meta-missing` |
| associated type | `decl.addType("Columns", "(id: string)")` | `City.Columns` in type positions, `City.Columns(id: "x")`, `City.Size.Large`; imported with its owner (alias too) | `decorator-type-without-owner`, `decorator-type-name`, `decorator-type-duplicate`, `decorator-type-not-one-type` |
| project reflection | (every top-level declaration a decorator runs over) | `@TypeInfo.all(with: d)` → `Declared<T>[]`; `member: "m"` for types | `typeinfo-all-arguments`, `typeinfo-all-not-decorator`, `typeinfo-all-mixed`, `typeinfo-all-needs-member`, `typeinfo-all-private`, `typeinfo-all-imported` |

Choices recorded under decision 216 (the spellings are the decision's):

- **Members.** One `fn` per call (an associated fn or a method), written as in the body; its `pub`
  is what the source says. From a field's or a method's decorator it joins the owning type. Parsed
  into the target's body before the re-analysis (`comptime.zig` `mergeMembers`), so inference, the
  exports and the four backends see a hand-written member.
- **Meta.** Values are strings; the namespace is the decorator's own name (`entity`, never the
  `orm.entity` an annotation spells); meta describes a top-level `type`, `behavior` or `fn`. A read
  is answered by the checker and spliced as a literal; tooling that runs no decorator reads `""`.
  **One builtin** (decision 248): `@typeInfo(T)` used as a value is the older structural answer
  (the `TypeInfo` record), folded in; the lowercase `@typeinfo(…)` / `@typeinfo.all(…)` is
  `typeinfo-lowercase` where it is written, naming `@typeInfo`. The structural value has no
  run-time lowering (a bare `@typeInfo(City)` printed is `function typeInfo/1 undefined` on erlang),
  as before the fold — it is a comptime value only.
- **Associated types.** Declared as the top-level type `Owner__Name` (`pub` when the owner is), not
  the `__Owner__Name` of an enum section, which the backends read as "a section of the enum
  `Owner`" and tag with the outer enum's module (measured: `Greeter.Mock` on erlang was
  `undef`). `comptime/assoc_types.zig` rewrites every `Owner.Name` on the parsed program and adds
  the import item an importer needs; a value prints under the owner's path (`City.Columns(…)`,
  `City.Size.Small` — `TypeDecl.displayName`, read by every backend's display). Only a decorator
  declares one (no hand-written nested type).
- **`@TypeInfo.all`.** Answers a `Declared<T>(name, module, meta: DeclaredMeta[], value: T)` array:
  `value` is the function itself, or for a type a thunk `{ -> T.<member>() }`; one kind per query.
  **What it sees:** every module of the build — the root package, its dependencies, std — that does
  not itself read `@TypeInfo.all`, plus the reader's own declarations. A reader is analysed after
  every other module (`orderReaders`) and imported by nobody. **Order:** module path (byte order),
  then declaration order. A declaration of another module is reached through an import the answer
  adds, so it is `pub`.

Measured on `front/130-decorator-outputs` (botopink-lang): `zig build` green; `zig fmt --check
modules` green; `zig build test` green; `zig build test-docs` 101/101; `tests/language/run.sh
--target all` **2067 passed, 0 failed**; `zig build test-libs` green for rakun-data, rakun-cache,
rakun-hateoas, rakun-security and rakun-client (erlang, their one target).

Cells (all four targets where they run):
`run/decorator_add_member`, `modules/decorator_add_member_import`, `run/decorator_set_meta`,
`modules/decorator_meta_import`, `run/decorator_add_type`, `modules/decorator_add_type_import`,
`modules/typeinfo_all_registration`; refusals `reject/decorator_add_member_{on_fn,duplicate,not_one}`,
`reject/typeinfo_{meta_missing,unknown_declaration,lowercase}`, `reject/typeinfo_all_lowercase`,
`reject/decorator_meta_{duplicate,on_member}`,
`reject/decorator_add_type_{duplicate,not_one,without_owner,name}`,
`reject/typeinfo_all_{mixed,needs_member,not_decorator,arguments}`, `reject/decorator_member_unknown`, `run/typeinfo_all_list`, `reject/typeinfo_all_list_twice`,
`modules/typeinfo_all_{imported,private}` (by `<target>.expect`).

## Steps

### Step 5 — migrate the 119 sites

Migrated (34 of 119, plus `#[schema]`'s 5 that landed since the open — see below):

- std `#[mocks.mock]` → `<Name>.Mock` + `<Name>.mock()`; validation `#[validated]` →
  `v.validate()` + `T.constraints()` (rakun's `#[configurationProperties]` boot check moved with
  it); jhonstart `#[client]` → the meta `component` (`@typeInfo(X).meta.client.component`).
- rakun-data `#[entity]` (20 of 22) → meta `@typeInfo(T).meta.entity.{table,columns}`, the
  associated type `T.Columns`, the members `T.columns()`, `T.entityMeta()`, `T.fromRow(r)`,
  `T.params(c)`, `T.insert/update/delete(sql, c)` with their `…In(tx, …)` twins, `T.byId(sql, id)`,
  and under `#[revisions]` `T.revisionsOf/revisionAt/revisionNumbers` + `T.revisionMeta()`; the two
  left are its registrations (`val __rkEntityReg_`, `__rkEntityRevReg_`).
- rakun-data `#[entityRepository]` (3) → `<Repo>.<m>Sql()`, `<Repo>.<m>CountSql()`,
  `<Repo>.<m>Derived(sql, …)`; `#[belongsTo]` (2) → `<R>.sql()`, `<R>.fromRow(r)`; `#[query]` (1 of
  2) → `<Repo>.<m>Sql()` (its registration `val __rkQueryReg_` left). Two `#[query]` methods of one
  name on two types of one module are now two members and build (the old refusal was the shared
  helper name's erlc collision).
- rakun-cache `#[cached]` (2) → the associated type `<Name>.Cached(inner: …)`; the factory
  `cached<Name>(inner)` is gone, the constructor is the factory.
- rakun-hateoas `#[halResource]` (1) → the method `v.toHal(links)`.

Each member is library-chosen naming (decision 174's note): the old suffix becomes the member's
name, the parameters unchanged.

**A type's members are closed** (built with the migration). `infer.zig`'s type-qualified call
refuses a name a record-shaped type neither declares nor answers through a field or an implemented
behavior: `unknown-associated-fn` at the call (`reject/decorator_member_unknown`, `docs.md`
§ Decorators). Without it the migration lost two refusals that an unbound emitted name used to give:
`T.revisionsOf(…)` on an entity without `#[revisions]` and a `#[belongsTo]` naming a non-entity.

Remaining, by site, and what each is written against:

| File | Sites | Generated today | New form | Written against |
|---|---|---|---|---|
| rakun `rakun/src/decorators.bp`, `rakun-web/src/convention.bp`, `rakun/src/autoconfig.bp`, `rakun/src/config.bp`, `rakun/src/context.bp`, `rakun-data/src/sql/transactional.bp`, `rakun-security/src/method_security.bp` | ~29 | `pub fn __rkMake_<T>()` (singleton factory, the injection contract), `<T>Tx` / `<T>Sec` proxies built on it | member `T.make()` or the context | decision 234: `T.make()` + `rkResolve("<Field type>")`, the context filled at boot through `@TypeInfo.all` (235) — **held on `dec-e`** (below): the boot's query cannot be typed |
| same files + `lifecycle.bp`, `conditions.bp`, `rakun-data` `entity.bp` / `query.bp` | ~27 | `val __rkScan_<T>`, `__rkBean_`, `__rkLc_`, `__rkEv_`, `__rkImp_`, `__rkExit_`, `__rkAutoQ_`, `__rkCat_`, `__rkChk_`, `__rkEnable_`, `__rkEntityReg_`, `__rkQueryReg_` (load-time registration) | `@TypeInfo.all(…, member: "register")` at rakun's boot | decision 235 (built) + 234: the boot's catalogue |
| `rakun-web/src/convention.bp`, `rakun-app/src/{route_handler,actions}.bp`, `rakun-websocket`, `rakun-scheduling`, `rakun-messaging`, `rakun-cli`, `rakun-actuator-api`, `rakun/src/decorators.bp` routes | ~25 | `val __rkFilter_`/`__rkConverter_`/`__rkCustomizer_`/`__rkCors_`/`__rkAdvice_`/`__rkMiddleware_`/`__rkHandler_<VERB>_`/`__rkRoute_`/`__rkWs_`/`__rkSched_`/`__rkJob_`/`__rkCli_`/`__rkEp_`… | meta (`order`, `media`, `path`, `verb`) + `@TypeInfo.all` at the entry point | 235 (built); 236 for `#[middleware]`'s gate; 234 (each handler resolves its owner through the context) |
| `rakun-client/src/exchange.bp` | 2 | `pub type Http<T>` + `pub fn http<T>()` | `T.Http` + a factory member | held: a behavior's member called from another module fails on all four backends (below) |
| jhonstart `routes.bp` | 5 | `val __jhPage_X = jhPage(seg, …)` (+ layout/template/default), `pub fn <X>Params(route)` | meta `seg` + `@TypeInfo.all(with: page)` | 235 (built); 236 for `<X>Params` (`paramsOf(seg, route)`); the readers are onze's generated entry points and jhonstart's tests (62 annotations across jhonstart and onze) |
| validation `#[schema]` (`libs/validation/src/decorators.bp`) | 5 | `pub fn parse<T>At`, `parse<T>`, `decode<T>`, `schemaOf<T>` + helpers | members `T.parseAt/parse/decode/schema` | nothing — next; `decode` passes `parse<T>At` as a value, and an associated fn read as a value is an unbound variable on erlang (`City.make` passed to a `fn(string) -> City`), so it wraps it in a lambda |

**Found during the migration** (open, not 216's places): a `behavior`'s associated `default fn`
called through the behavior from another module (`Shape.unit()` with `import {shapes.Shape}`) is
an unknown erlang module on erlang/beam, a run-time error on commonJS and a refusal on wasm — the
member does not travel with a behavior the way it travels with a type; an associated fn read as a
value (`apply(City.make, …)`) is an unbound variable on erlang; a member's or associated type's
diagnostic is located past the file's last line (the member source is placed after the module's
lines) and names the type as `City__Columns`, not `City.Columns`.

**Acceptance:** each library's hook green on this compiler; `rtk grep '@emit(' --include=*.bp` in
`repository/` answers only `tests/language` cells about `@emit` itself.

### Step 6 — remove module-level `@emit`

After step 5: `@emit` is a named error everywhere (its message lists the four places); the
`tests/language` cells about `@emit` become `reject/` cells; `docs.md`'s "Decided, not yet
implemented" row leaves; `language-gaps.md` closes **An emitted `pub val` is visible to other
emitted code only** and **No comptime reflection over the project** (its declaration half — the
manifest half of that row, a `@project()` read, is not 216's).

## Gate

- [ ] `zig build test` from a cold runtime cache, green
- [ ] `tests/language/run.sh --target all` green; std on commonJS and erlang; each library's hook
- [ ] `AGENTS.md` of every directory touched, in the same commit

## Blast radius

Every decorator reply changed shape (tagged maps): two codegen snapshots re-recorded on each runtime
(their `COMPTIME REPLY`). The `Decl` handle gained three methods; `Declared` / `DeclaredMeta` are
new prelude records. `#[mocks.mock]` and `#[validated]` changed their consumers' spellings (std,
validation and rakun's config check, migrated together).

## Decisions answered for step 5

- **236** (`dec-a`, the README's question 1) — a function's decorator writes no per-function code:
  `#[page]` records `decl.setMeta("seg", "[slug]")` and jhonstart writes
  `paramsOf(@typeInfo(BlogPost).meta.page.seg, route)` once by hand; rakun's `#[middleware]` gate
  the same way. No fifth place.
- **235** (`dec-b`, question 4) — `@TypeInfo.all(with: [a, b, c])` takes a list: one answer in the
  one order, a declaration carrying two of the listed decorators once. **Built**: `typeinfo_all.zig`
  (`with:` one decorator or a non-empty list, no spread; a name listed twice is
  `typeinfo-all-arguments`; the entry's `meta` is what every listed decorator set), cells
  `run/typeinfo_all_list` and `reject/typeinfo_all_list_twice`, `docs.md` § Decorators.
- **234** (`dec-d`) — a constructor-injected field resolves through the context by the type's
  name: a stereotyped type's factory is its member `T.make()`, a field `clock: Clock` is
  `rkResolve("Clock")`, the boot fills the context from `@TypeInfo.all(with: [stereotypes…],
  member: "make")` and `@TypeInfo.all(with: provides)` / the `#[bean]` methods; `__rkMake_<T>`
  goes; two providers are the context's rule (`#[qualifier]`, `#[primary]`); a missing bean is a
  boot failure.

- **248** (`dec-c`) — one reflection builtin, `@typeInfo`. **Built**: `@typeInfo(X).name` /
  `.meta.<d>.<k>` / `@TypeInfo.all(…)`, a bare `@typeInfo(T)` is the structural `TypeInfo`, the
  lowercase spelling `typeinfo-lowercase` (`reject/typeinfo_lowercase`,
  `reject/typeinfo_all_lowercase`, a docs-check in `docs.md` § Decorators); compiler, std, jhonstart
  and rakun renamed.

## Open questions (beyond 216)

1. **`dec-e` — how the boot registers beans whose types differ** (`decisions-pending.md`). An
   `@TypeInfo.all` answer is one array literal, so every `value` has one type; decision 234's
   `@TypeInfo.all(with: [stereotypes…], member: "make")` over two types whose `make()` returns
   `Self` is `type mismatch: expected Mailer, got Orders`, and `@TypeInfo.all(with: provides)` the
   same for two providers of different types. Options: a second member `T.register() -> i32` with
   `#[provides]` folded into `#[bean]` methods of a `#[configuration]` (recommended), or a compiler
   label `each: f` applying a generic function per entry. Until it is answered nothing fills the
   context `rkResolve("<Field type>")` reads, so rakun's 29 `__rkMake_` emit sites stay.
2. **wasm: a function read from a generic record's field and called through an untyped local prints
   its pointer** (`Box<T>(value: T)` alone, independent of 216) — `typeinfo_all_registration` calls
   through a typed local; the gap belongs to `05-wasm`.
