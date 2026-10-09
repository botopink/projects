# Front 130 — decorator outputs: a decorator's four places, then module-level `@emit` removed

**Priority:** high · **State:** partial: steps 1–4 on feat (decisions 216, 235, 248); step 5 at 38
of 119 sites (plus `#[schema]`'s 5); step 6 not started; step 10 (353) not started
**Depends on:** decisions 254, 256 for rakun's DI (answered; 256's registry needs `01-checker` step
20) · library tracks for their decorator files · `04-rakun/128` for rakun rows (decision 339)
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
| comptime meta, a typed value keyed by its type (298) | `decl.setMeta(Entity(table: "cities"))`, `decl.addMeta(Index(…))` | `@typeInfo(City).meta(Entity)` → `?Entity`; `metaAll(Index)` → `Index[]` |
| associated type | `decl.addType("Columns", "(id: string)")` | `City.Columns` in type positions, `City.Columns(id: "x")`; imported with its owner | `decorator-type-without-owner`, `decorator-type-name`, `decorator-type-duplicate`, `decorator-type-not-one-type` |
| project reflection | (every top-level declaration a decorator runs over) | `@TypeInfo.all(with: d)` (or a list, decision 235) → `Declared<unknown>[]` (decision 254), `member: "m"` for types (a reference after step 7, 281) | `typeinfo-all-arguments`, `typeinfo-all-not-decorator`, `typeinfo-all-mixed`, `typeinfo-all-needs-member`, `typeinfo-all-private`, `typeinfo-all-imported` |

- **Members.** One `fn` per call, written as in a body; `pub` as the source says; from a field's or
  method's decorator it joins the owning type; parsed into the target's body before re-analysis
  (`comptime.zig` `mergeMembers`). Members closed: a name a record-shaped type neither declares nor
  answers via a field or behavior = `unknown-associated-fn` at the call
  (`reject/decorator_member_unknown`).
- **Meta.** String values; namespace = the decorator's name (typed, keyed by its type after step 8,
  298); describes a top-level `type`, `behavior` or `fn`. Reads answered by the checker, spliced as
  literals. One builtin (decision 248): bare `@typeInfo(T)` = structural `TypeInfo`, comptime only;
  lowercase spelling = `typeinfo-lowercase`.
- **Associated types.** Top-level type `Owner__Name`; `comptime/assoc_types.zig` rewrites every
  `Owner.Name` and adds the importer's import item; a value prints under the owner's path
  (`TypeDecl.displayName`). Only decorators declare one.
- **`@TypeInfo.all`.** Sees every build module not itself reading `@TypeInfo.all`, plus the reader's
  own declarations; a reader is a module whose parse calls `@TypeInfo.all` (a comment or a string
  literal spelling it is none); readers analysed after all others (`orderReaders`), imported by nobody. Order:
  module path (byte order), then declaration order. Entry = `Declared(name, module, meta, value,
  returnTypeName)` (decision 256).

## Done

- Steps 1–4 — the four places (decision 216), `with:` a list (235), one `@typeInfo` (248), `@TypeInfo.all` (253) — cells `run/decorator_{add_member,set_meta,add_type}`, `modules/decorator_{add_member_import,meta_import,add_type_import}`, `modules/typeinfo_all_{registration,imported,private}`, `run/typeinfo_all_list` and the `reject/decorator_*`, `reject/typeinfo_*` refusals
- Step 5, migrated — std `#[mocks.mock]`; validation `#[validated]`; jhonstart `#[client]`; rakun-data `#[entity]` (20 of 22), `#[entityRepository]` (3), `#[belongsTo]` (2), `#[query]` (1 of 2; the other is not migrated — 313 deletes `#[query]`, rakun 08 step 7); rakun-cache `#[cached]` (2); rakun-hateoas `#[halResource]` (1); jhonstart `#[page]` / `#[layout]` / `#[template]` / `#[defaultView]` registrations (4: meta `seg`, registered by the entry point with `jhRegisterRoutes(@TypeInfo.all(with: page), …)` — onze's `onze_main.bp`, jhonstart's, onze-server's and the blog example's tests)
- Rows found during the migration, closed — a reader found in the parse, not the text (`comptime/typeinfo_all.zig` `reads(program)`, cell `modules/typeinfo_all_spelled_in_string`; onze-cli's `start.bp` writes `@TypeInfo.all` in its generated source); a fn-typed local called at its current binding on erlang (`codegen/erlang.zig`, cell `run/fn_local_rebound_call`, `02-erlang`'s half; jhonstart's `jhRegisterRoutes` binds `val v` in each of its four loops)

## Open

### Step 5 — migrate the remaining sites

Decision 318 shrinks rakun's list before it migrates: `#[service]`, `#[managed]`, the core's `#[repository]`,
`#[restController]`, `#[configuration]` / `#[bean]`, the four transport listeners and `#[httpExchange]` are
deleted by the owning rakun fronts (04 step 8, 13 step 6, 15 step 8), not migrated; only their
replacements are written here in 216's forms.

Member names are the library's (decision 174's note). Remaining `@emit(` at feat: rakun 67 lines,
jhonstart 1 (`#[page]`'s `<X>Params`), validation 5. Rakun rows target post-128 paths
(`04-rakun/README.md` § Order, decision 339): no 130 rakun commit while `04-rakun/128` is open; after it, each a consumer commit under
decision 188, never in a wave with the rakun front owning the file.

| File | Sites | Generated today | New form | Written against |
|---|---|---|---|---|
| rakun `rakun/src/{decorators,autoconfig,config,context}.bp`, `rakun-web/src/convention.bp`, `rakun-data/src/sql/transactional.bp`, `rakun-security/src/method_security.bp` | ~29 | member `T.make()` (`rkSingleton`) on each stereotype; a `#[bean]` method emits `val __rkBeanM_<T>_<m> = rkRegisterBean("<return type>", …)` (`rakun/src/decorators.bp:333-385`); `<T>Tx` proxy + `val __rkTx_<T> = rkRegisterBean(…)` (`transactional.bp:81-82`), `<T>Sec` proxy + `pub fn __rkMake_<T>Sec()` (`method_security.bp:141-142`) | member `T.make()`; the registry built at comptime from `@TypeInfo.all(with: …)`, never keyed by a name string (281, 256; `ctr-q` closed) | 234 (`T.make()`, by-type injection), 254 (catalogue answers `Declared<unknown>[]`; `rkResolve<T>` narrows with `is fn() -> T`), 256 (registry built at comptime at the entry point), 281 (amends 234/256 where they key by a type's name, and `member: "make"`) |
| same files + `lifecycle.bp`, `conditions.bp`, `rakun-data` `entity.bp` / `query.bp` | ~27 | `val __rkScan_<T>`, `__rkBean_`, `__rkLc_`, `__rkEv_`, `__rkImp_`, `__rkExit_`, `__rkAutoQ_`, `__rkCat_`, `__rkChk_`, `__rkEnable_`, `__rkEntityReg_`, `__rkQueryReg_` (load-time registration) | `@TypeInfo.all(with: …)` read at comptime (member by reference, step 7) | 235, 234, 254, 281 |
| `rakun-web/src/convention.bp`, `rakun-app/src/{route_handler,actions}.bp`, `rakun-websocket`, `rakun-scheduling`, `rakun-messaging`, `rakun-cli`, `rakun/src/actuator_api/**` (today `rakun-actuator-api`, moved by 128 step 1), `rakun/src/decorators.bp` routes | ~25 | `val __rkFilter_`/`__rkConverter_`/`__rkCustomizer_`/`__rkCors_`/`__rkAdvice_`/`__rkMiddleware_`/`__rkHandler_<VERB>_`/`__rkRoute_`/`__rkWs_`/`__rkSched_`/`__rkJob_`/`__rkCli_`/`__rkEp_`… | meta (`order`, `media`, `path`, `verb`) + `@TypeInfo.all` at the entry point | 235; 236 for `#[middleware]`'s gate; 234 |
| `rakun-client/src/exchange.bp` | 2 | `pub type Http<T>` + `pub fn http<T>()` | `T.Http` + a factory member | held: behavior member called from another module fails (below) |
| jhonstart `routes.bp` | 1 | `pub fn <X>Params(route)` (the four registrations are done) | none — the page takes no parameter and reads `use params<P>()`, checked by `#[page]` over `Decl.hooks` | 293 (amends 236's `paramsOf`); held: `05-jhonstart/26` step 11 after `01-checker` step 23, and the segment walk inside it is `03-bundled-libs/102` step 3's while 102 is open |
| validation `#[schema]` (`libs/validation/src/decorators.bp`) — `#[validated]` after 306 | 5 | `pub fn parse<T>At`, `parse<T>`, `decode<T>`, `schemaOf<T>` + helpers | members `T.parseAt/parse/decode` (no `schema` — `Schema<T>` is private, 306) | nothing — next; `decode` passes `parse<T>At` as a value (unbound variable on erlang, below), so wrap it in a lambda |

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
      method — not by string; `Declared.value` stays `unknown` (254; `nat-a` answered by 281)

### Step 8 — typed meta, keyed by its type (decision 298)

`Decl.setMeta(value: T)` — one value per type per declaration, a second of the same type refused at
the call —; `Decl.addMeta(value: T)` for what repeats; read `@typeInfo(X).meta(T) -> ?T`,
`@typeInfo(X).metaAll(T) -> T[]`, and `Declared.meta(T)` in `@TypeInfo.all`'s answer. Comptime only
(280 (0)). `setMeta(key: string, value: string)` and `.meta.<decorator>.<key>` go.

- [ ] `builtins.d.bp`: `setMeta`, `addMeta` on `Decl`; `meta`, `metaAll` on `TypeInfo<T>` and `Declared<T>`
      (`comptime t: type`, 280); `DeclaredMeta(key, value)` gone
- [ ] `run/meta_typed` — `#[entity("cities")]` sets `Entity(table: "cities")`, `meta(Entity)?.table ==
      "cities"`; two `#[index]` add two `Index`, `metaAll(Index).length == 2`; `meta(Other)` is `null`
- [ ] `reject/meta_twice` — two `setMeta(Entity(…))` on one declaration, at the second
- [ ] the std and library sites migrated (rakun's `#[entity]` and the stereotypes, jhonstart's `#[page]`)

### Step 9 — a tag is a `@Decl` (decision 302)

A template function hands each annotated tag to its annotations as a `@Decl` and reads back what
they recorded — the same function shape as a declaration's decorator, named by no library (113, 198).

- [ ] `DeclKind` gains `Element`, `Component`; `Decl.component: ?Decl` (a component tag's function);
      a tag's static attributes readable (`decl.attr(name) -> ?string`)
- [ ] `@Expr`/`@ExprCustom` capture: a template function constructs a tag's `@Decl`, calls an annotation
      with it (the `Decorator` of 268, `Decorator.is` for identity), reads `meta(T)` / `metaAll(T)` (298)
- [ ] on a tag `addMember`, `addType` refused at the call; `setMeta` of one type twice refused at the second
- [ ] `run/tag_decl_meta` — an annotation recording `ClassName(names: ["a"])` on a `<div>` read back by the
      template function; the same annotation function also accepted on a declaration

### Step 10 — a template body reads the program's catalogue (decision 353)

A library's template function calls `@TypeInfo.all(with: …)` and gets the catalogue of the program
that expands the call — `styled` finds the application's one `#[theme]` (119 step 1 box 5).

```bp
// styled/src/styled.bp, inside `pub default fn styled(comptime css: @Expr<string>)`
val themes = @TypeInfo.all(with: theme);   // the application's #[theme] declarations
if (themes.length > 1) css.fail("styled: two #[theme] declarations: …");
```

- [ ] a decorator on a `val` runs (356): `DeclKind.Val`, `name`, `returnType` as written; `setMeta`
      legal, `addMember` / `addType` refused at the annotation; the `val` catalogued —
      `run/val_decorator_runs` (`#[mark] pub val one = 1;` fails with the decorator's message)
- [ ] `@TypeInfo.all` in a template function's body answers for the calling program, after every
      module's decorators; the reader is exempt from `typeinfo-all-imported` (256's entry-point
      rule unchanged for every other reader)
- [ ] a `Declared`'s `value` readable at build: a `val` with a `comptime` initializer lifted into the
      template's module as a literal (356), refused at the read otherwise
      (`typeinfo-all-template-value`); a comptime `extendTheme(…)` holding `ThemeValue.Rem(…)`
      evaluates (row 133)
- [ ] the importer of a reader module that breaks the rule gets `typeinfo-all-imported` at the
      import, not `unbound variable '<template>'` at the use (row 134's diagnostic half)
- [ ] `run/template_reads_program_catalogue` — a package's template function counting the importing
      application's `#[theme]` declarations: none, one, two (refused at the second, naming both)

**Gate:** standard (fronts.md § Gate) + std on commonJS and erlang; each library's hook

## Notes

- Every decorator reply is a tagged map; `Declared` / `DeclaredMeta` are prelude records in
  `builtins.d.bp` (134); `DeclaredMeta` goes with step 8 (298).
- Found here, `05-wasm`'s: a function read from a generic record's field, called through an untyped
  local, prints its pointer.
