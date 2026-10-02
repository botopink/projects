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
| comptime meta, per decorator | `decl.setMeta("table", "cities")` | `@typeinfo(City).meta.entity.table`, `@typeinfo(City).name` — string constants | `decorator-meta-on-member`, `decorator-meta-duplicate`, `typeinfo-without-member`, `typeinfo-unknown-member`, `typeinfo-unknown-declaration`, `typeinfo-meta-missing` |
| associated type | `decl.addType("Columns", "(id: string)")` | `City.Columns` in type positions, `City.Columns(id: "x")`, `City.Size.Large`; imported with its owner (alias too) | `decorator-type-without-owner`, `decorator-type-name`, `decorator-type-duplicate`, `decorator-type-not-one-type` |
| project reflection | (every top-level declaration a decorator runs over) | `@typeinfo.all(with: d)` → `Declared<T>[]`; `member: "m"` for types | `typeinfo-all-arguments`, `typeinfo-all-not-decorator`, `typeinfo-all-mixed`, `typeinfo-all-needs-member`, `typeinfo-all-private`, `typeinfo-all-imported` |

Choices recorded under decision 216 (the spellings are the decision's):

- **Members.** One `fn` per call (an associated fn or a method), written as in the body; its `pub`
  is what the source says. From a field's or a method's decorator it joins the owning type. Parsed
  into the target's body before the re-analysis (`comptime.zig` `mergeMembers`), so inference, the
  exports and the four backends see a hand-written member.
- **Meta.** Values are strings; the namespace is the decorator's own name (`entity`, never the
  `orm.entity` an annotation spells); meta describes a top-level `type`, `behavior` or `fn`. A read
  is answered by the checker and spliced as a literal; tooling that runs no decorator reads `""`.
  `@typeinfo` (lower case) sits beside the older structural `@typeInfo(T)` — see Open questions.
- **Associated types.** Declared as the top-level type `Owner__Name` (`pub` when the owner is), not
  the `__Owner__Name` of an enum section, which the backends read as "a section of the enum
  `Owner`" and tag with the outer enum's module (measured: `Greeter.Mock` on erlang was
  `undef`). `comptime/assoc_types.zig` rewrites every `Owner.Name` on the parsed program and adds
  the import item an importer needs; a value prints under the owner's path (`City.Columns(…)`,
  `City.Size.Small` — `TypeDecl.displayName`, read by every backend's display). Only a decorator
  declares one (no hand-written nested type).
- **`@typeinfo.all`.** Answers a `Declared<T>(name, module, meta: DeclaredMeta[], value: T)` array:
  `value` is the function itself, or for a type a thunk `{ -> T.<member>() }`; one kind per query.
  **What it sees:** every module of the build — the root package, its dependencies, std — that does
  not itself read `@typeinfo.all`, plus the reader's own declarations. A reader is analysed after
  every other module (`orderReaders`) and imported by nobody. **Order:** module path (byte order),
  then declaration order. A declaration of another module is reached through an import the answer
  adds, so it is `pub`.

Measured on `front/130-decorator-outputs` (botopink-lang): `zig build` green; `zig fmt --check
modules` green; `scripts/format-check.sh` green; `zig build test` green; `zig build
test-docs` 96/96; `tests/language/run.sh --target all` **1567 passed, 0 failed** (1515 at the open +
52 new cells); std `botopink test` 442/442 on commonJS and on erlang; `validation` green on both of
its targets; rakun core `botopink test --target erlang` 374/374.

Cells (all four targets where they run):
`run/decorator_add_member`, `modules/decorator_add_member_import`, `run/decorator_set_meta`,
`modules/decorator_meta_import`, `run/decorator_add_type`, `modules/decorator_add_type_import`,
`modules/typeinfo_all_registration`; refusals `reject/decorator_add_member_{on_fn,duplicate,not_one}`,
`reject/typeinfo_{meta_missing,without_member,unknown_declaration}`,
`reject/decorator_meta_{duplicate,on_member}`,
`reject/decorator_add_type_{duplicate,not_one,without_owner,name}`,
`reject/typeinfo_all_{mixed,needs_member,not_decorator,arguments}`,
`modules/typeinfo_all_{imported,private}` (by `<target>.expect`).

## Steps

### Step 5 — migrate the 119 sites

Migrated (5 of 119): std `#[mocks.mock]` → `<Name>.Mock` + `<Name>.mock()`; validation
`#[validated]` → `v.validate()` + `T.constraints()` (rakun's `#[configurationProperties]` boot check
moved with it, its hook green); jhonstart `#[client]` → the meta `component`
(`@typeinfo(X).meta.client.component`, its hook green). Remaining, by site:

| File | Sites | Generated today | New form |
|---|---|---|---|
| rakun `rakun/src/decorators.bp`, `rakun-web/src/convention.bp`, `rakun/src/autoconfig.bp`, `rakun/src/config.bp`, `rakun-data/src/sql/transactional.bp`, `rakun-security/src/method_security.bp` | ~16 | `pub fn __rkMake_<T>()` (singleton factory) | member `T.make()` |
| same files + `rakun/src/context.bp`, `lifecycle.bp`, `conditions.bp` | ~25 | `val __rkScan_<T>`, `__rkBean_`, `__rkLc_`, `__rkEv_`, `__rkImp_`, `__rkExit_`, `__rkAutoQ_`, `__rkCat_`, `__rkChk_`, `__rkEnable_` (load-time registration) | member `T.register()` + `@typeinfo.all(with: component, member: "register")` at rakun's boot |
| `rakun-web/src/convention.bp`, `rakun-app/src/{route_handler,actions}.bp`, `rakun-websocket`, `rakun-scheduling`, `rakun-messaging`, `rakun-cli`, `rakun-actuator-api`, `rakun/src/decorators.bp` routes | ~25 | `val __rkFilter_`/`__rkConverter_`/`__rkCustomizer_`/`__rkCors_`/`__rkAdvice_`/`__rkMiddleware_`/`__rkHandler_<VERB>_`/`__rkRoute_`/`__rkWs_`/`__rkSched_`/`__rkJob_`/`__rkCli_`/`__rkEp_`… | meta (`order`, `media`, `path`, `verb`) + `@typeinfo.all` at the entry point; a `#[middleware]` / route function is its own `value` |
| `rakun-data/src/orm/{entity,repository}.bp`, `sql/query.bp` | ~29 | `pub fn __rkEntity_<T>_<op>`, `__rkJoin_`, `__rkDerivedCount_`, `__rkQuery_`, `pub type <T>Columns`, `val __rkEntityReg_`/`__rkQueryReg_` | members (`City.fromRow(r)`), associated types (`City.Columns`), meta (`table`), registrations as above |
| `rakun-cache/src/cached.bp`, `rakun-client/src/exchange.bp`, `rakun-hateoas/src/hal.bp`, `transactional`, `method_security` | ~8 | `pub type Cached<T>` / `Http<T>` twins, `pub fn cached<T>()` / `http<T>()` | associated type `T.Cached` / `T.Http` + member factory |
| jhonstart `routes.bp` | 5 | `val __jhPage_X = jhPage(seg, …)` (+ layout/template/default), `pub fn <X>Params(route)` | meta `seg` + `@typeinfo.all(with: page)` passed to jhonstart's registration; `<X>Params` has no place (open question 1) |

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

## Open questions (beyond 216)

1. **A function's decorator has no place for per-function code.** jhonstart's `#[page]` writes
   `pub fn <Page>Params(route)` and rakun's `#[middleware]` a gate lambda; a `fn` has no members,
   so neither has a home among the four places. Options: (a) pages become types, (b) the helper
   becomes generic library code fed by meta, (c) a fifth place. Recommendation (b).
2. **`@typeinfo` beside `@typeInfo`.** Two builtins differing by case; the older `@typeInfo(T)`
   (structural `TypeInfo`) has no library caller. Recommendation: retire `@typeInfo`, or fold its
   structural answer into `@typeinfo(T)`.
3. **wasm: a function read from a generic record's field and called through an untyped local prints
   its pointer** (`Box<T>(value: T)` alone, independent of 216) — `typeinfo_all_registration` calls
   through a typed local; the gap belongs to `05-wasm`.
4. **One query answers one decorator.** rakun's stereotypes (`#[component]`, `#[service]`,
   `#[repository]`, `#[controller]`, `#[filter]`, …) are one kind of thing — a managed singleton —
   under several decorators, so its boot would write one `@typeinfo.all` per stereotype. Options:
   (a) one query per decorator (today); (b) `with: [service, repository, …]`, the union in one
   order; (c) a stereotype decorator delegates to one shared marker the query names.
   Recommendation (a) for 216's migration, (b) only if rakun's boot measures it worth a rule.
