# Front 130 — decorator outputs: a decorator's four places, then module-level `@emit` removed

**Priority:** high · **State:** partial: steps 1–4 on feat (decisions 216, 235, 248); step 5 at 34
of 119 sites (plus `#[schema]`'s 5); step 6 not started
**Depends on:** decisions 254, 256 for rakun's DI (answered; 256's registry needs `01-checker` step
20) · library tracks for their decorator files · `04-rakun/128` for rakun rows (`03r-ao`)
**Owns:** `repository/botopink-lang/modules/compiler-core/src/comptime/{reflection,assoc_types,typeinfo_all}.zig`
and the decision-216 parts of `comptime.zig`, `comptime/{infer,env,decorator_eval,diagnostics,transform}.zig`,
`comptime/runtime/prelude.zig`, `parser/exprs.zig` · `libs/std/src/builtins.d.bp`'s `Decl` surface and
`Declared` records (with 134) · `libs/std/src/testing/mocks.bp` · `libs/validation/src/decorators.bp` ·
`docs.md` § Decorators · the `tests/language` cells below · then each library's decorator files (step 5)
**Does not touch:** import resolver (`compiler-cli`, 26), `01-checker`'s checker rows, backends (02–05)

## Goal

A decorator writes four places — member of the annotated type, comptime meta entry, associated
type, project catalogue `@TypeInfo.all` — each travelling with the type to every importer; every
library decorator uses them; `@emit` is a named error.

## Mechanism

| Place | Written in a decorator | Read | Refused |
|---|---|---|---|
| member of the annotated type | `decl.addMember("pub fn fromRow(r: Row) -> Self { … }")` | `City.fromRow(r)`, `c.describe()`; travels with the type | `decorator-member-without-type`, `decorator-member-duplicate`, `decorator-member-not-one-fn` |
| comptime meta, per decorator | `decl.setMeta("table", "cities")` | `@typeInfo(City).meta.entity.table`, `@typeInfo(City).name` — string constants | `decorator-meta-on-member`, `decorator-meta-duplicate`, `typeinfo-unknown-member`, `typeinfo-unknown-declaration`, `typeinfo-meta-missing` |
| associated type | `decl.addType("Columns", "(id: string)")` | `City.Columns` in type positions, `City.Columns(id: "x")`; imported with its owner | `decorator-type-without-owner`, `decorator-type-name`, `decorator-type-duplicate`, `decorator-type-not-one-type` |
| project reflection | (every top-level declaration a decorator runs over) | `@TypeInfo.all(with: d)` (or a list, decision 235) → `Declared<unknown>[]` (decision 254), `member: "m"` for types | `typeinfo-all-arguments`, `typeinfo-all-not-decorator`, `typeinfo-all-mixed`, `typeinfo-all-needs-member`, `typeinfo-all-private`, `typeinfo-all-imported` |

- **Members.** One `fn` per call, written as in a body; `pub` as the source says; from a field's or
  method's decorator it joins the owning type; parsed into the target's body before re-analysis
  (`comptime.zig` `mergeMembers`). Members closed: a name a record-shaped type neither declares nor
  answers via a field or behavior = `unknown-associated-fn` at the call
  (`reject/decorator_member_unknown`).
- **Meta.** String values; namespace = the decorator's name; describes a top-level `type`,
  `behavior` or `fn`. Reads answered by the checker, spliced as literals. One builtin (decision 248):
  bare `@typeInfo(T)` = structural `TypeInfo`, comptime only; lowercase spelling =
  `typeinfo-lowercase`.
- **Associated types.** Top-level type `Owner__Name`; `comptime/assoc_types.zig` rewrites every
  `Owner.Name` and adds the importer's import item; a value prints under the owner's path
  (`TypeDecl.displayName`). Only decorators declare one.
- **`@TypeInfo.all`.** Sees every build module not itself reading `@TypeInfo.all`, plus the reader's
  own declarations; readers analysed after all others (`orderReaders`), imported by nobody. Order:
  module path (byte order), then declaration order. Entry = `Declared(name, module, meta, value,
  returnTypeName)` (decision 256).

## Done

- Steps 1–4 — the four places (decision 216), `with:` a list (235), one `@typeInfo` (248), `@TypeInfo.all` (253) — cells `run/decorator_{add_member,set_meta,add_type}`, `modules/decorator_{add_member_import,meta_import,add_type_import}`, `modules/typeinfo_all_{registration,imported,private}`, `run/typeinfo_all_list` and the `reject/decorator_*`, `reject/typeinfo_*` refusals
- Step 5, migrated — std `#[mocks.mock]`; validation `#[validated]`; jhonstart `#[client]`; rakun-data `#[entity]` (20 of 22), `#[entityRepository]` (3), `#[belongsTo]` (2), `#[query]` (1 of 2); rakun-cache `#[cached]` (2); rakun-hateoas `#[halResource]` (1)

## Open

### Step 5 — migrate the remaining sites

Member names are the library's (decision 174's note). Remaining `@emit(` at feat: rakun 80 lines,
jhonstart 5, validation 5. Rakun rows target post-128 paths (`04-rakun/README.md` § Order, `03r-ao`
(a)): no 130 rakun commit while `04-rakun/128` is open; after it, each a consumer commit under
decision 188, never in a wave with the rakun front owning the file.

| File | Sites | Generated today | New form | Written against |
|---|---|---|---|---|
| rakun `rakun/src/{decorators,autoconfig,config,context}.bp`, `rakun-web/src/convention.bp`, `rakun-data/src/sql/transactional.bp`, `rakun-security/src/method_security.bp` | ~29 | `pub fn __rkMake_<T>()` (singleton factory), `<T>Tx` / `<T>Sec` proxies on it | member `T.make()`; context filled at boot | 234 (`T.make()` + `rkResolve("<Field type>")`), 254 (catalogue answers `Declared<unknown>[]`; `rkResolve<T>` narrows with `is fn() -> T`), 256 (registry built at comptime at the entry point as one `Dict<string, unknown>`) |
| same files + `lifecycle.bp`, `conditions.bp`, `rakun-data` `entity.bp` / `query.bp` | ~27 | `val __rkScan_<T>`, `__rkBean_`, `__rkLc_`, `__rkEv_`, `__rkImp_`, `__rkExit_`, `__rkAutoQ_`, `__rkCat_`, `__rkChk_`, `__rkEnable_`, `__rkEntityReg_`, `__rkQueryReg_` (load-time registration) | `@TypeInfo.all(…, member: "register")` at rakun's boot | 235, 234, 254 |
| `rakun-web/src/convention.bp`, `rakun-app/src/{route_handler,actions}.bp`, `rakun-websocket`, `rakun-scheduling`, `rakun-messaging`, `rakun-cli`, `rakun/src/actuator_api/**` (today `rakun-actuator-api`, moved by 128 step 1), `rakun/src/decorators.bp` routes | ~25 | `val __rkFilter_`/`__rkConverter_`/`__rkCustomizer_`/`__rkCors_`/`__rkAdvice_`/`__rkMiddleware_`/`__rkHandler_<VERB>_`/`__rkRoute_`/`__rkWs_`/`__rkSched_`/`__rkJob_`/`__rkCli_`/`__rkEp_`… | meta (`order`, `media`, `path`, `verb`) + `@TypeInfo.all` at the entry point | 235; 236 for `#[middleware]`'s gate; 234 |
| `rakun-client/src/exchange.bp` | 2 | `pub type Http<T>` + `pub fn http<T>()` | `T.Http` + a factory member | held: behavior member called from another module fails (below) |
| jhonstart `routes.bp` | 5 | `val __jhPage_X = jhPage(seg, …)` (+ layout/template/default), `pub fn <X>Params(route)` | meta `seg` + `@TypeInfo.all(with: page)` | 235; 236 (`paramsOf(@typeInfo(BlogPost).meta.page.seg, route)` once by hand); readers: onze's generated entry points, jhonstart's tests |
| validation `#[schema]` (`libs/validation/src/decorators.bp`) | 5 | `pub fn parse<T>At`, `parse<T>`, `decode<T>`, `schemaOf<T>` + helpers | members `T.parseAt/parse/decode/schema` | nothing — next; `decode` passes `parse<T>At` as a value (unbound variable on erlang, below), so wrap it in a lambda |

- [ ] each library's hook green on this compiler; `grep -rn '@emit(' --include=*.bp repository/`
      answers only `tests/language` cells about `@emit` itself

### Step 6 — remove module-level `@emit`

`@emit` a named error everywhere (message lists the four places); `tests/language` `@emit` cells
become `reject/` cells; `docs.md`'s "Decided, not yet implemented" row leaves; `language-gaps.md`
closes **An emitted `pub val` is visible to other emitted code only** (T15) and **No comptime
reflection over the project** (declaration half; the `@project()` manifest half is not 216's).

- [ ] the refusal and the cells; the two `language-gaps.md` rows closed

### Rows found during the migration (open, not 216's places)

- [ ] a `behavior`'s associated `default fn` called through the behavior from another module
      (`Shape.unit()` with `import {shapes.Shape}`): unknown erlang module on erlang/beam, run-time
      error on commonJS, refusal on wasm — members do not travel with a behavior as with a type
      (holds `rakun-client`'s two sites)
- [ ] an associated fn read as a value (`apply(City.make, …)`) is an unbound variable on erlang
- [ ] a member's / associated type's diagnostic is located past the file's last line (member source
      placed after the module's lines) and names `City__Columns`, not `City.Columns`

### Step 7 — references, not strings (decision 281)

- [ ] `@TypeInfo.all(with: …, member: "make")` (256) names the member by reference — an interface's
      method — not by string; `Declared.value` stays `unknown` (254) until `nat-a`'s registry shape

**Gate:** standard (fronts.md § Gate) + std on commonJS and erlang; each library's hook

## Notes

- Every decorator reply is a tagged map; `Declared` / `DeclaredMeta` are prelude records in
  `builtins.d.bp` (134).
- Found here, `05-wasm`'s: a function read from a generic record's field, called through an untyped
  local, prints its pointer.
