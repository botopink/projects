# Front 130 — decorator outputs: a decorator's four places, then module-level `@emit` removed

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s9 → B-15 · s5 → B-19 · s6 → B-19 · rows → B-19 · s7 → B-19 · s8 → B-19 · s10 → B-19. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high · **State:** partial: steps 1–4 on feat (decisions 216, 235, 248); step 5 at 38
of 119 sites (plus `#[schema]`'s 5); step 6 not started; step 8 (298, 370 (1)): typed meta, its reads and
`@Expr<T>` fields built, the library migration open; step 10 (353): the catalogue answered for the expanding program, the importer's diagnostic, the cells; open: `value` at build (`119-e`)
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
| comptime meta, a typed value keyed by its type (298) | `decl.setMeta(Entity(table: "cities"))`, `decl.addMeta(Index(…))` | `@typeInfo(City).meta(Entity)` → `?Entity`; `metaAll(Index)` → `Index[]`; `d.meta(Entity)` on a catalogue entry | `decorator-meta-not-record`, `decorator-meta-field-type`, `decorator-meta-expr-arg`, `decorator-meta-twice`, `decorator-meta-on-member`, `typeinfo-meta-type`, `typeinfo-meta-several`, `typeinfo-meta-expr-elsewhere`, `typeinfo-meta-hooks-pending`, `typeinfo-meta-at-build` |
| associated type | `decl.addType("Columns", "(id: string)")` | `City.Columns` in type positions, `City.Columns(id: "x")`; imported with its owner | `decorator-type-without-owner`, `decorator-type-name`, `decorator-type-duplicate`, `decorator-type-not-one-type` |
| project reflection | (every top-level declaration a decorator runs over) | `@TypeInfo.all(with: d)` (or a list, decision 235) → `Declared<unknown>[]` (decision 254), `member: "m"` for types (a reference after step 7, 281) | `typeinfo-all-arguments`, `typeinfo-all-not-decorator`, `typeinfo-all-mixed`, `typeinfo-all-needs-member`, `typeinfo-all-private`, `typeinfo-all-imported` |

- **Members.** One `fn` per call, written as in a body; `pub` as the source says; from a field's or
  method's decorator it joins the owning type; parsed into the target's body before re-analysis
  (`comptime.zig` `mergeMembers`). Members closed: a name a record-shaped type neither declares nor
  answers via a field or behavior = `unknown-associated-fn` at the call
  (`reject/decorator_member_unknown`).
- **Meta.** A typed value keyed by its record type (298, step 8): the record's constructor written at
  the call, each field data or `@Expr<T>` (370 (1), spliced where read), written back as the
  constructor where it is read; the string form (values under the decorator's name) stands until the
  library migration; describes a top-level `type`, `behavior`, `fn` or `val`. Reads answered by the checker, spliced as
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

## Notes

- Every decorator reply is a tagged map; `Declared` / `DeclaredMeta` are prelude records in
  `builtins.d.bp` (134); `DeclaredMeta` goes with step 8 (298).
- Found here, `05-wasm`'s: a function read from a generic record's field, called through an untyped
  local, prints its pointer.
