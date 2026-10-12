# Front 144 — machine 1: the checker and the language (lane A, the module-model group)

The steps of [front 144](../README.md) this machine runs: its goal, priority, ownership, order, lanes, the rules the two
machines share and the alias table are the front's README; each step below is as it was there, unchanged. The
other machine's steps are in [`../machine-2-backends-tooling/`](../machine-2-backends-tooling/README.md). A step keeps its id (`B-NN`) wherever it sits.

## Steps

### B-02 — 305: labelled annotation arguments (`fn:`, `op:`, `wasi:`, `keyed:`)

**Repository:** botopink-lang, with consumer commits in rakun, jhonstart, log, validation, onze, markdown (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

The prerequisite of `throws:` (B-03): flags read by label, `inline:` and `throws:` in any order.

**Impacted tests:** new `reject/annotation_label_equals`, `reject/external_fn_unbound`; the hint of
`reject/external_inline_unread`; `parser/tests/**`; `codegen/tests/externals.zig`;
`comptime/tests/infer_decls.zig`; `test-libs --lib std`. **Model:** opus.
**Consumer commits:** rakun (`@BeamMemory`'s `keyed: true`), jhonstart, log, validation, onze, markdown — one
each, in the landing.

#### Step 27 — the compiler's annotations speak botopink (decision 305) (was `01-checker` s27)

- [ ] parser: `label = value` in an annotation's arguments is a located error naming `label:`
      (`reject/annotation_label_equals`); `Annotation.labels` read from `label: value` only;
      `parser/AGENTS.md`'s labelled-argument line rewritten
- [ ] `@External.<Target>(fn: name)` — `name` resolves to a private botopink function of the same module,
      its signature checked against the bound one; a misspelt name is the ordinary unbound-name error at
      the argument (`reject/external_fn_unbound`); renaming the function renames the binding
- [ ] `@External.Wasm(op: "f64.sqrt")` checked against the opcode table (238's check, now on the label);
      `@External.Wasm(wasi: .RandomF64)` — `wasi`'s type is an enum of docs.md's adapter list
- [ ] the old prefixed strings (`"fn:…"`, `"op:…"`, `"wasi:…"`) are no longer recognised: an unlabelled
      string is host code, always; a string starting with one of the old prefixes is a located error
      naming the labelled form (one release, then removed)
- [ ] std's 88 bindings migrated (79 `fn:`, 6 `op:`, 3 `wasi:`), `scripts/` grep cell: no `"fn:` /
      `"op:` / `"wasi:` left in `libs/**`; `docs.md` § External rewritten

#### Step 10 — `label: value` in annotations (decision 305) (was `16-formatter` s10)

- [ ] a labelled annotation argument prints `label: value` (`#[@BeamMemory.Ets(keyed: true)]`,
      `#[@External.Erlang("…", inline: true)]`); `src/format/AGENTS.md`'s "prints `label = value`" row
      rewritten; `format/tests/declarations.zig` cases updated (`assertFormat`, `assertIdempotent`)

#### Step 2 — the text and the migration handed over — part (was `17-beam-memory` s2 box 1)

- [ ] `keyed: true` (decision 305) in every cell and diagnostic of this front; `keyed = true` is the
      parser's located error (`01-checker` step 27)

#### B-02 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-10 — 430: the compiler gaps a library works around today

**Repository:** botopink-lang, with consumer commits in validation, styled, emilia, jhonstart, onze (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

Decision 430: a gap a library front works around opens here, ahead of the steps that would build on the
workaround; the workaround is removed in the fix's landing (a consumer commit) and its `language-gaps.md` row
and Marker index row go (meta CI check 5). Groups by the library that carries the markers:

- **G1 validation** — `Decl.variants` carries a variant's name and not its payload; a static member is not a
  value on erlang; a comptime decorator parameter takes no default; a decorator body whose lambda holds many
  locals overflows the comptime stack; a record spread inside a member a decorator adds loses its spread on
  commonJS; `Decorator` is an unknown type in a package's module; a decorator argument is a raw lexeme;
  `Field` reflects no default; two test modules declaring one type name share it on erlang; std's
  `clock.formatIso8601` answers differently on erlang and commonJS (`decision 497`); the package module namespace
  in type and value position (the box below).
- **G2 styled / emilia** — a method's behavior-typed parameter refuses an implementer; a wrapper's type alias
  cannot implement a behavior; a template function cannot read another expansion's value; a function a
  template body reaches cannot name an enum variant nor build a private record; a decorator body cannot call a
  host function (closes with B-00c); a library's template function cannot read the program's catalogue (B-19,
  130 s10); an imported enum's variant written bare (erlang).
- **G3 jhonstart** — a decorator cannot read whether a `@Component<R>` return's `R` implements `@Renderable`;
  a tag annotation cannot be called by the template function (B-15); template-built code cannot build an inline
  props type; a type alias of `@Component` in a return and `@ExprCustom<View>` (re-measured after 388).
- **G5 onze** — a field marker cannot be read by the library that takes the type.

- [ ] G1, first: two test modules declaring one type name stay two types under `botopink test --target erlang`
      (`language-gaps.md`'s row, validation `test/schema_test.bp`'s marker) — measured repro: validation's
      `test/refine_and_messages_example_test.bp` case "decode runs the type-level rules…" is red on erlang because
      another test module's `Signup` answers `Signup.decode`; it holds 146 s1's typed-member route (430)
- [ ] G1: every row closed by a cell on the four targets; validation's markers removed in the landing (one
      consumer commit); the rows and their Marker index rows gone
- [ ] G2: the same for styled's and emilia's markers
- [ ] G3: the same for jhonstart's markers (after B-15 and 388)
- [ ] G5: the same for onze-content's marker

**Impacted tests:** a `run/` or `reject/` cell per row; the libraries' suites. **Model:** opus for checker rows,
sonnet for a backend row with its repro. **Consumer commits:** validation, styled, emilia, jhonstart, onze.

#### Rows other fronts found — part (was `01-checker` rows box 2)

- [ ] package module namespace in type and value position (`import {report} from "validation"`, then
      `report.X`) as for std modules — exports known only to `comptime.zig`'s `resolveImports`

#### B-10 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-11 — 316: `decl.wrapWith(f)`

**Repository:** botopink-lang, with consumer commits in rakun (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `run/decorator_wraps_function`, its `reject/` cells. **Model:** opus.
**Consumer commits:** rakun — rakun-cache's two `LANGUAGE GAP` markers go; unblocks rakun 12 s5 and the 318
wrappers (04 s8, 08 s7, 12 s6, 13 s6, 15 s8, 19 s7, 79 s4, 91 s2, 93 s4 — in 150).

#### Step 30 — a decorator wraps the function it annotates: `decl.wrapWith(f)` (decision 316) (was `01-checker` s30)

A decorator answers only 216's four outputs today; a free function's decorator has nowhere to put a
proxy (`decorator-member-without-type`). After, it may wrap the function, typed:

```bp
pub fn useCache(comptime decl: @Decl<fn(..) -> string>, comptime ttl: Duration = hours(1)) {
    decl.wrapWith({ call -> cacheThrough(policyFor(decl, ttl), call.args, { -> call.run() }) });
}

#[useCache(ttl: minutes(5))]
pub fn posts() -> string { return loadPosts(); }
```

- [ ] `decl.wrapWith(f)` in `builtins.d.bp` (with 134): `f` receives the call value (the arguments and
      running the original body — spelling decided here, recorded in `docs.md` § Decorators) and answers
      the function's return type; a wrapper whose type does not match the annotated signature
      (`@Decl<fn(..) -> T>`, 280) is an error at the decorator
- [ ] the wrapped function keeps its name, signature and identity for callers (a reference to it is
      the wrapped behaviour); the original body is reachable only through the call value
- [ ] two or more wrappers compose in annotation order, the first written outermost — one cell
- [ ] on a method it wraps that method; on a function or method of another module the wrapper runs
      wherever it is called (the importer sees the wrapped behaviour)
- [ ] a decorator still reads no body (lg2-d) and writes none as a string (281)
- [ ] `run/decorator_wraps_function` (a counting wrapper, a cache wrapper, two composed) on the four
      targets; `reject/` cells for a wrapper of the wrong return type and for `wrapWith` outside a
      function or method decorator
- [ ] `01-checker/examples/decorator-arguments-280.md` example 5 runs (no longer illustrative);
      `language-gaps.md`'s row "A decorator cannot rewrite or wrap the body it annotates" closes once
      its marker (rakun 15's `publish-reliability-example.bp`) is rewritten

#### B-11 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-14 — 359: a spread copies a record's fields

**Repository:** botopink-lang (`--lang`)

**Impacted tests:** `run/record_spread`, `reject/record_spread_*`, `reject/call_spread`. **Model:** opus.
**Consumer commits:** none; heads two critical chains (jhonstart 118 s1 → 26 → 67 → 127 and 118 → 119 → 120).

#### Step 34 — a spread copies a record's fields (decision 359) (was `01-checker` s34)

```bp
val pessoa = Pessoa(...pessoaOld, nome: "Ana");
pub val Contato = Type.pick(Pessoa, .email, .telefone);
val outra = Pessoa(...base, ...contato, nome: n);   // left to right, the later winning
```

- [ ] the parser reads `...expr` at the start of a record constructor's argument; `a...b` stays the
      inclusive range; the formatter prints `...src` (with `01-compiler/16`)
- [ ] the source is the record's type or a 307 type derived from it (`pick`, `omit`, `merge`); any
      other record refused at the `...` naming both types; a `Type.partial` value refused
- [ ] arguments apply left to right; a field without a default supplied by neither a spread nor a
      label is an error at the call; a label written twice stays an error
- [ ] `run/record_spread` on the four targets (a new record, the source unchanged and evaluated once);
      `reject/record_spread_other_type`, `reject/record_spread_partial`, `reject/record_spread_missing_field`
- [ ] a plain function call takes no spread (267): `reject/call_spread`

#### B-14 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-15 — 302: a tag is a `@Decl`

**Repository:** botopink-lang, with consumer commits in jhonstart (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `run/tag_decl_meta`. **Model:** opus. **Consumer commits:** jhonstart (`html.bp`'s marker
goes); unblocks jhonstart's 118 s4–s5 residue and 119.

#### Step 9 — a tag is a `@Decl` (decision 302) (was `130-decorator-outputs` s9)

A template function hands each annotated tag to its annotations as a `@Decl` and reads back what
they recorded — the same function shape as a declaration's decorator, named by no library (113, 198).

- [ ] `DeclKind` gains `Element`, `Component`; `Decl.component: ?Decl` (a component tag's function);
      a tag's static attributes readable (`decl.attr(name) -> ?string`)
- [ ] `@Expr`/`@ExprCustom` capture: a template function constructs a tag's `@Decl`, calls an annotation
      with it (the `Decorator` of 268, `Decorator.same` for identity, 371), reads `meta(T)` / `metaAll(T)` (298)
- [ ] on a tag `addMember`, `addType` refused at the call; `setMeta` of one type twice refused at the second
- [ ] `run/tag_decl_meta` — an annotation recording `ClassName(names: ["a"])` on a `<div>` read back by the
      template function; the same annotation function also accepted on a declaration

#### B-15 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-16 — 280, 307, 308: typed decorator arguments' rest, derived types' rest, `Type.Field<T>`

**Repository:** botopink-lang, with consumer commits in rakun (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `run/field_key_runtime`, `examples/types.bp` on four targets, the seven 280 examples.
**Model:** opus. **Consumer commits:** rakun-data (`orm/entity.bp` to `Type.Field<unknown>`); unblocks validation
125's residue, jhonstart 26 s13 (362), 118.

#### Step 24 — typed comptime decorator arguments, `@Decl<T>`, `Field<T>` (decision 280) (was `01-checker` s24)

The cases are [`examples/decorator-arguments-280.md`](01-checker/examples/decorator-arguments-280.md) — each
example a `run/` cell, its "não compila" lines `reject/` cells. Landed
(botopink-lang; the library halves are separate changes, below).

- [x] a decorator parameter without `comptime` refused at the parameter (`decorator-param-not-comptime`,
      `reject/decorator_param_not_comptime`); a `comptime` parameter takes a default; the decorators of
      the compiler's cells and docs, jhonstart (4), rakun (74, 21 files) and validation (8) migrated
      (the keyword only; std declares none with a further parameter); `botopink check` of every library
      member clean
- [ ] arguments of any type checked at the argument and handed over as values: a function, a `type`,
      an enum variant, a record, an array (`[1, 2]` has length 2); a value not known at comptime
      (`env("X")`) refused at the argument (`decorator-arg-not-comptime`) — built but for the
      function and the `type`, which the body still receives as their name: 364 replaces the box
      with step 35 (every argument an `@Expr<T>`)
- [x] `@Decl<T>` in `builtins.d.bp`; `T` bound from the annotated declaration (type, field, function)
      when the signature uses it, through a pattern too (`@Decl<fn(e: E) -> unknown>`); `@Decl` =
      `@Decl<unknown>`; a declaration not matching the pattern refused at the annotation
      (`reject/decorator_decl_pattern_{mismatch,return}`)
- [ ] `Field<T>` — `Type.Field<T>` in std's `types.bp` (decision 308), not `builtins.d.bp` — (`name`, the
      field's type); `.name` resolved against the expected `T`, a missing field refused at it; variadic
      `..fields: Type.Field<T>[]` (267); `decl.fields` hands out `Type.Field<unknown>` — built but the
      last clause (`decl.fields` is still `builtins.d.bp`'s `Field`, the same shape; `types.bp` gives it
      to `134` step 2)
- [x] `.Name` case-exact for fields and variants (`.custom` against `Custom` is the missing-name error;
      `reject/decorator_variant_case`, `reject/decorator_field_key_case`)
- [ ] the seven examples green on every target where they run; each "não compila" line a `reject/`
      cell with its caret — examples 1–6 green on the four targets
      (`run/decorator_{arguments_check,decl_pattern,type_argument,function_arguments,record_argument,field_keys}`,
      `run/decorator_argument_values`, `modules/decorator_typed_arguments_import`), 19 `reject/` cells
      (`comptime_default_outside_decorator` among them: a `comptime` default outside a decorator); example 1's signature is 406's (`message` first; a field's rule `#[refine]`); example 7
      (`#[onClick(like)]` in a tag) is the html template's (`08-bpp/118`, `05-jhonstart/26`)
- [x] `docs.md` § Decorators documents the four rules; `comptime/AGENTS.md` states how a comptime
      argument reaches the decorator body; `language-gaps.md`'s lg2-f and lg2-i rows marked built (they
      go when their markers do: 125 s7, rakun 04 s6)

#### Step 28 — a derived type: a compile-time function answering a new type (decision 307) (was `01-checker` s28)

`pub val RecipeTitle = Type.pick(Recipe, .title);` — landed
(`comptime/derived_types.zig`): the `val` is rewritten, before the checker, into the record declaration
it answers; `tryResolveTypeManipulationCall` and its bare names are gone. Questions `s28-a`–`s28-d`
(built as their recommendation, confirmed by 421–424).

- [x] `Type.partial`, `Type.required`, `Type.pick`, `Type.omit`, `Type.merge` answered at build, keyed on
      the receiver bound to std's `types.Type` (an alias included); fields as `.title`; a string field
      `derived-type-field-string` naming `.title`; an unknown field the `Type.Field<T>` error at it; a field
      twice, no field, an `omit` leaving none `derived-type-fields`; a non-record source (enum, namespace
      type, primitive, generic record, imported alias) `derived-type-source-not-record`; a field on both
      sides of `merge` `derived-type-merge-duplicate` at the second argument; arity / label
      `derived-type-arguments`; the bare `partial(…)` / `mergeRecords(…)` unbound
- [x] the answer is a new nominal record named after its `val`: usable in every type position,
      constructed, told apart by `is`, printed by its name, exported and imported; a derived or nested
      derivation as source (`Type.merge(Type.merge(A, B), C)`); `AnchorProps` as a parameter type
      (`modules/derived_type_imported`) — the s28 prerequisite of 362
- [x] a decorator on that `val` sees a type declaration (`decl.kind`, `decl.fields`); each field keeps
      the source field's annotations, `partial` makes it `?T` (`run/derived_type_decorated`)
- [x] the call is refused outside a module-level `val` — a body, a `var`, an annotated `val`
      (`derived-type-outside-val`, at the call)
- [x] `run/derived_type_functions`, `run/derived_type_decorated`, `modules/derived_type_imported` on the
      four targets; eleven `reject/derived_type_*` cells; all red on the parent — the derived-record
      row of `language-gaps.md` closes when 125 s5's example runs (its `#[validated]` half is 125's)
- [ ] `Type.keys(Recipe)` is `Type.Field<Recipe>` (decision 308) — the same type, not a copy: not a record
      derivation, not answered
- [ ] a `Type.Field<T>` at run time: stored, passed, compared; `case key { .title -> … }` exhaustive over
      `T`'s fields (a field added to `T` makes a `case` without it an error); `key.name`, `Key.of(text) ->
      ?Key`, `Key.all()` in declaration order — `run/field_key_runtime` on the four targets
- [ ] `decl.fields` as `Type.Field<unknown>` (134 s2's box) — not part of this mechanism (the reflection
      record is `comptime.zig`'s `__Decl__Field`): left to 134 s2

#### Step 2 — declare the rest — part (was `134-builtins-declared` s2 boxes 1, 2, 3, 6)

Left: `?T`'s methods (`map`, `flatMap`, `unwrapOr`) and the builtin `result` namespace
(`result.map/then/unwrap/isOk/isError`), prose in `builtins.d.bp` — under 330 the first leave and the
second is deleted; `Type`'s namespace-type spelling (329), `Type.Field<T>` and `Type.pick` / `Type.omit`.

- [x] the rest declared under 330: `?T` declares no method (its surface is `01-checker` step 31's operators) — the
      `?T` rows (`map`, `flatMap`, `unwrapOr`) leave `infer.zig` `inferResultOptionMethod`; the `result` namespace
      (`inferResultNamespaceCall`) is deleted, not declared; the prose in `builtins.d.bp` goes
- [x] std's `types.bp` spells `pub type Type { … }` — a namespace type, no field list and no value (329): `Type()`
      refused, a `self` function in its body refused
- [ ] `Type` also declares the associated type `Field<T>` inside its body (308, 330), `keys` answering it —
      declared (`pub type Field<T>(name, typeName, annotations)`, `run/std_type_field_associated`);
      `builtins.d.bp`'s `Field` record leaves, `Decl.fields` typed `Type.Field<unknown>[]` — open: the record
      `decl.fields` hands out is the compiler's `__Decl__Field` (`comptime.zig` `decl_reflection_src`, aliased
      `Field` and drift-checked against `builtins.d.bp`'s `Field`), so std's hoisted `Type__Field` has to become
      that record, and rakun-data's `orm/entity.bp` (`fn marked(f: Field, …)`) moves to `Type.Field<unknown>`; `pick` /
      `omit` are declared (Done); the spelling of a `type` answer is fixed here with `01-checker` step 28
- [ ] the four bare names (`partial`, `pick`, `omit`, `mergeRecords`) leave `tryResolveTypeManipulationCall`
      when `01-checker` step 28 keys its resolver on `Type`
- [ ] [`examples/types.bp`](134-builtins-declared/examples/types.bp) — the whole `Type` surface, signatures and results —
      compiles and passes on the four targets; its "does not compile" lines are `01-checker` step 28's
      `reject/` cells; `Type.merge` with a field on both sides is an error, `Type.required` drops every `?`
- [ ] `docs.md` § Builtins generated from or checked against the declarations

#### B-16 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-17 — 277, 376, 354–388: hooks, stages, contexts

**Repository:** botopink-lang, with consumer commits in jhonstart, styled, rakun (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

`decl.hooks`' rest (389, 386), every function's stage (376), the holes known at build (355), the synchronous
component (375), contexts' rest (388's box 4b with jhonstart's renderer, 416, 379 (6), 378 (4) — question
`434-b` on the at-build path). Questions `s23-j`, `04s12-a`, `14s8-a/c/d`.

**Impacted tests:** `run/decl_hooks_*`, `run/stage_*`, `run/hole_any_call_at_build`, `run/context_*`,
`run/component_*`, `run/inject_*`; the commonJS component snapshots. **Model:** opus.
**Consumer commits:** jhonstart (renderer, 414), styled, rakun; unblocks jhonstart 26 s8, s11, rakun 22 s4,
onze 49 s5, emilia 34 s5 box 5 and the eight fronts of 293.

#### Step 23 — the hooks a function reaches, in its `@Decl` (decision 277) (was `01-checker` s23)

`libs/std/src/builtins.d.bp`: `DeclAnnotation` gains `decorator: Decorator`; new `HookUse(hook:
?Declared<unknown>, annotations: DeclAnnotation[], at: string)`, `HookCall(callee:
Declared<unknown>, at: string)`, `HookNode(fn: Declared<unknown>, uses: HookUse[], calls:
HookCall[])`; `Decl` gains `val hooks: HookNode[]`; `extend Decorator { pub fn same(self, other:
Decorator) -> bool; }` (371). The checker (`comptime/infer.zig`, `env.zig`) computes, once per function:
its node — each `use h(…)` written in it (with `h`'s annotations), each call of a `@Component`
function (the calls `html` generates from tags included); `hooks` = that node then every node
reachable through `calls`, breadth-first in body order, each function once; a cycle is an edge
back; a `use` over a function value enters with `hook: null`; a host function gets no node; nodes
shared across the compilation. No backend, no codegen snapshot changes; the compiler names no stage
or library.

Landed (botopink-lang): `comptime/hooks.zig`, the node recorded as `inferFnDecl`
infers a top-level function's body and published to the session (`Reflection.hookFns`); `decl.hooks` computed
for a function one of whose decorators reads it (questions s23-a – s23-f). 371 and 372 landed in
 (botopink-lang): `comptime/decorator_same.zig`, `infer.zig`'s two decorator
phases (questions s23-g – s23-i).

- [x] `run/decl_hooks_direct` — `use session()` (a host hook) → one node, `Page(uses: [session], calls: [])`
      (commonJS, erlang, beam: `session` has no wasm binding)
- [x] `run/decl_hooks_all_nodes` — a page over `UserMenu` → `Avatar`, `Badge` and `Avatar` again: four
      nodes, `Avatar` once, `calls` in body order
- [x] `run/decl_hooks_custom_hook` — `use user()` where `user` uses `session()`: the user's node has
      `user`, `user`'s node has `session`
- [x] `run/decl_hooks_cycle` — `A → B → A`: two nodes, `B`'s call goes back to `A`
- [x] a component named as a value is a reached node (389): `itens.map(Card)`, a `val` or a field holding
      `Card`, a lambda answering a component — `run/decl_hooks_component_value` (`Lista` over `itens.map(Card)`
      reaches `Card`'s `use session()`); a call the checker cannot follow (a parameter called, a method, what
      generic code answers) enters `HookCall(callee: null, at)` (`HookCall.callee: ?Declared<unknown>` in
      `builtins.d.bp`) — `run/decl_hooks_dynamic_call` — landed (`infer.zig`
      `noteComponentValue`, `noteHookCall`), with `01-compiler/134` s6 box 4b
- [x] `run/decl_hooks_function_value` — `use f()` with `f` a parameter → `HookUse(hook: null)`
- [x] `HookUse` carries the `use`'s explicit type arguments (`typeArgs: TypeInfo<unknown>[]` — `use
      params<BlogParams>()` → `[BlogParams]`, its fields with their types), so `#[page]` checks them (293);
      `run/decl_hooks_type_args` (a field's annotations and the methods: s23-f)
- [x] across modules — `modules/decl_hooks_imported`: another module's nodes as it published them, a hook through
      an alias with its own annotations
- [x] `DeclAnnotation` gains `decorator: Decorator` — the declaration's identity, an alias and a namespace resolved
      (every handle's annotations, a field key's included); `HookNode`'s `fn` is `function` (`fn` is reserved, s23-a)
- [x] `modules/decorator_same` (a `modules/` cell: the second package is a path dependency) — `#[srv]` with
      `import {serverOnly as srv} from "web"` → `a.decorator.same(serverOnly)` true; the project's own
      `serverOnly` (`#[local.serverOnly]`) → false (371: `same`, `is` stays a keyword); `reject/decorator_same_not_decorator`
      (`same("serverOnly")`, the mismatch at the argument). `same` is a member of `behavior Decorator` (s23-g); a
      project module's decorator through a namespace is 386 (below)
- [ ] a namespace import registers the module's body-carrying decorators under `<ns>.<name>`, as std's are
      (386): `#[markers.tag]` runs `tag`, `markers.serverOnly` is a `Decorator` value for `same` —
      `modules/decorator_through_namespace` (the meta `tag` sets read back; `same(markers.serverOnly)` true)
- [x] `HookNode.async: bool` (375): `true` when the body writes `await` / `async { … }`, `use`s an asynchronous
      hook or calls an asynchronous component (written `await` or not), calls a host function answering
      `@Task`, or calls what the checker cannot follow (a function value, a method, `hook: null`); a cycle
      asynchronous when any node in it is; published with the module's nodes; `builtins.d.bp` declares the
      field — `run/decl_hooks_async` (a page over a synchronous `Card` and an awaiting `Comments`: `Card`
      `false`, `Comments` and the page `true`), `modules/decl_hooks_async_imported` — landed: `Builder.is_async` / `dynamicCalls`, `noteAsyncCall`, `markHookAsync` before the
      `.hooks` readers; the reading of "cannot follow" and of a host `@Component` is `s23-j`
- [x] a decorator reading `.hooks` runs after the module's bodies (372, provisional): the decorators that
      read no `.hooks` first, then the bodies, then the `.hooks` readers, which may only `setMeta` /
      `fail` — `run/decl_hooks_reads_member` (`#[graph] fn Page() { return
      Account(…).validate(); }` above `#[check] pub type Account`, `validate` added by `#[check]`,
      compiles), `reject/decorator_hooks_output` (`addMember` in a `.hooks` reader, at the call);
      a same-module `@TypeInfo.all` of a reader is `typeinfo-all-hooks-reader` (s23-i,
      `reject/typeinfo_all_hooks_reader`)
- [x] `docs.md` § Decorators documents `decl.hooks` and `HookNode` (`Decorator.same` with 371); `comptime/AGENTS.md`
      states the computation; `language-gaps.md`'s row "A function's `@Decl` does not say which hooks it activates"
      closes

#### Step 36 — every function's stage: `Build`, `Run`, `Any` (decision 376) (was `01-checker` s36)

```bp
fn padAll(n: i32) -> StyledProperty { return styledProperty "padding: --spacing(${n});"; }   // Any
fn agora() -> i64 { return clock.nowMs(); }                                                    // Run
fn campos(comptime t: type) -> string[] { return @typeInfo(t).fields.map({ f -> f.name }); }   // Build
fn cabecalho() -> string { val n = comptime campos(Post); return n.join(",") + agora().toString(); }   // Run
```

- [ ] each function's stage from its resources (376 (1)) and its calls (376 (2)); `use h(…)` takes `h`'s;
      `provide` / `context` `Any`; a host function `Run` unless std (or its library) declares it `Any`;
      `HookNode.stage` published with the module's nodes — `run/stage_of_functions`,
      `modules/stage_imported`
- [ ] `build-and-run` at the second resource, naming the first; a `comptime { … }` block separates them —
      `reject/stage_build_and_run`, `run/stage_comptime_block_in_run`
- [ ] a body that runs at build (decorator, template, `comptime`) calls `Build` / `Any` functions, a
      program's helper included, and refuses a `Run` one at the call (`run-in-build`) —
      `run/decorator_calls_any_helper`, `reject/decorator_calls_run`; `language-gaps.md`'s sibling-fn row
      closes
- [ ] std declares `Any` on its pure host primitives (`string`, `math`), every other host binding `Run`

#### Step 8 — a `styled` literal whose holes are known at build, computed at build (decision 355) (was `14-comptime-on-beam` s8)

```bp
pub val tab4 = styledProperty "tab-size: 4;";
pub val code = styled "${tab4} color: red;";   // styledConstant("s_…", ".s_…{tab-size:4;color:red}")
```

Both open boxes wait on `01-checker` step 36 (every function's stage, not built): which call is `Any`
is the checker's answer. `padAll(2)` also reads styled's context (`use context(StyledContext)`), which
no `comptime` provides — question `14s8-e`.

- [ ] a call of an `Any` function (376) whose arguments are known at build is known at build and computed
      by the comptime runtime — in a hole (`styled "${padAll(2)}"`, `padAll(ESPACO)`) and in a `val`'s
      initializer; a raise refused at the hole (14s8-c); `padAll(n)` with `n` a parameter stays at render —
      `run/hole_any_call_at_build`, `reject/hole_any_call_raises`
- [ ] every expression with build inputs and `Any` functions computed at build wherever it is written (380):
      a body's `val raio = ESPACO * 2 + 4;` emitted as `12`; no step or time budget — a raise an error at the
      expression (`reject/fold_raises_at_build`); `@panic` / `throw` computed only under a written `comptime`
      (`run/fold_keeps_dead_panic`)

#### Step 12 — a synchronous component is a plain `function` (decision 375; after `01-checker` step 23's `HookNode.async`) (was `04-js` s12)

`effectShape`'s `.component => .{ .is_async = true }` (1.0.10's 104 (6)) gives way to the node's mark:

```js
function Card(map, titulo) { … }                       // HookNode.async == false
async function Post(map) { … Card(map, "x") … await Comments(map) … }
```

- [ ] a `@Component` function or hook whose node is synchronous emits `function` (a method, a lambda and a
      `default fn` alike); an asynchronous one `async function`; a call of a synchronous one emits no
      `await`, written or not; a call the checker cannot follow keeps the `await` — landed for a top-level function (`Emitter.fnShape`, `SyncMarks` from `OkData.sync_fns` /
      `sync_calls`, `useHookExpr`, the `.await_` arm); a method, a lambda and a `default fn` have no node and stay
      `async` (`04s12-a`)
- [ ] the TypeScript typedef answers the value, not a `Promise`, for a synchronous one; `tsc-check.sh` green —
      built for a top-level function (`typescript.zig` `fnReturnType`)
- [ ] `run/component_sync_plain_function` (the emitted module holds `function Card(` and `async function
      Post(`) and every `run/context_*` / jhonstart and emilia cell green on commonJS; erlang, beam and wasm
      output unchanged

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified under `node` against
decision 8 §7 · `zig build test-libs` commonJS cells at baseline (jhonstart, emilia, onze, erika)

#### Step 6 — contexts: `@Component<R>`, `use provide` / `use context` (decision 354, replaces 269) (was `134-builtins-declared` s6)

```bp
import {context.createContext} from "std";

pub val themeContext = comptime createContext(Theme(mode: .Light));   // declares Theme's default (378, 379)

fn App() -> @Component<Element> {
    use provide(createContext(Theme(mode: .Dark)));   // for everything App renders below it
    return <Page />;
}

fn Button() -> @Component<Element> {
    val theme = use context(Theme);                    // the nearest Theme above, else the default
    …
}
```

- [x] `@Component<R>`: `@Component<C, R>` a type-arity error naming `@Component<R>`; a component is the
      `@Component<R>` whose `R` implements `@Renderable`, any other `@Component<R>` read with `use` (no `@Hook`: `@Component` is the one wrapper); `@Context<C>` and
      `@getContext` leave `builtins.d.bp` (`context-getcontext-*` codes go with them)
- [x] std declares `Context<T>`, `provide(ctx: Context<T>, value: T)` and `context(ctx: Context<T>) -> T`
      as hooks (`use` only); `use` inside a decorator body, a template body or a `comptime { … }` refused,
      located (354 (3))
- [x] `Decl.hooks` (277) carries each `provide` / `context` with its object, for the frameworks' build check (354 (4)) —
      landed with `01-checker` step 23: `HookUse.context: ?Declared<unknown>`, the `val` that
      declares the context (`run/decl_hooks_context`; the field's name is s23-a)
- [x] measure before the rewrite (388 (6)): onze's blog could not render on the lambda before jhonstart's
      renderer moved (414), so the stand-in is a render of its shape — 25 component calls per page (a root,
      three levels each providing a context, seven leaves each reading it: the blog's `/blog` chain of layouts,
      templates, boundaries and the page), 1 000 renders per batch, the median of 15 batches after 3 to warm
      up, the same source built by botopink-lang `856bbc69` (the hidden map) and by box 4b (one lambda per
      call): erlang 1 829 µs → 1 966 µs (+7.5 %, +5.5 ns a component call), commonJS 462 µs → 755 µs (+63 %,
      +12 ns a component call) — under half a microsecond a page on either target, against a page render that
      escapes and joins its markup; judged acceptable, no question raised
- [x] box 4b, a component is a lambda over a `RenderScope` (388) — landed:
      `comptime/context_lower.zig` rewritten (the map and 374's capture gone), `c.run(scope)` typed by
      `inferComponentRun` (`Component.run` in `builtins.d.bp`), `RenderScope(…)` refused
      (`reject/render_scope_construction`), a function typed by an alias of `@Component` no component body (118,
      `run/component_alias_answers_value`), a bare `try` in a body (`run/component_try_in_body`), 389's edges
      (`run/decl_hooks_component_value`, `run/decl_hooks_dynamic_call`), the renderer-held scope
      `run/render_scope_library` replacing `run/context_host_thunk`; erlang, beam and commonJS green, wasm
      refusing a module the lowering reached at its first component (354-wasm, every component cell's
      `.wasm.expect`), the comptime runtimes 18's (354-comptime); jhonstart 208 / 0 on both rows with
      `05-jhonstart/26` step 14 (414). The box as written: `fn C(…) -> @Component<R>` lowers to a function
      answering `(scope) => …`, a call runs nothing; std's `context` declares the opaque `RenderScope`
      (`RenderScope.root()`) and `c.run(scope)` (the result and the children's scope; a `@Task` for a node 375
      marks asynchronous); `use provide(ctx)` makes the children's scope, `use context(T)` reads the received
      one or the default; `await c` in a body runs `c` with the children's scope — `run/component_is_lambda`
      (`itens.map(Card)` answers lambdas, the template's tree runs them with `Lista`'s scope),
      `run/context_provide_read`, `run/context_nearest_wins`, `run/component_run_root` on erlang, beam,
      commonJS, wasm and both comptime runtimes (handed to 02–05 and 18); the built map lowering
      (`comptime/context_lower.zig`, 374's `lowerHostArg`) replaced, not kept beside it; lands with jhonstart's
      renderer under 414 (`05-jhonstart/26` step 14: boundaries and fills as nodes the renderer runs with the scope —
      the suite back at 207 / 0 on erlang from 173 / 34)
- [x] until box 4b lands, a `@Component` value handed where the parameter's declared type is not a written
      `fn(…) -> @Component<…>` is refused at build (`component-value-to-generic`, naming the template's `for`)
      — never built: box 4b makes it moot (`itens.map(Card)` answers lambdas)
- [ ] every context declares its default, named by its value's type (378, 379): std's `context` module
      answers `createContext(value)`, `provide(ctx)`, `context(T)`, and `Context<T>()` goes; one module-level
      declaration per type (a second refused naming both), found through the catalogue; a read answers the
      nearest context of its type or the declared default on every target (`context-unbound` goes,
      `run/context_default`), a type with no declaration refused at the read (`reject/context_undeclared_type`);
      `comptime createContext(…)` refuses a run-time argument; the codemod over `tests/language` (20 cells),
      `styled`, jhonstart
- [ ] dependency injection over contexts (416): `createContext(value, Behavior)` keys the context by the behavior,
      the value checked to implement it (`reject/context_behavior_not_implemented`); `use inject(T)` builds the record
      `T` from the context of each field's type — provided above, else the declared default, else the field's default,
      else an error at build naming the field (`reject/inject_field_undeclared`); a behavior refused
      (`reject/inject_behavior`) — `run/inject_record`, `run/inject_behavior_keyed`, `run/inject_test_root_fake`
      (a test's root providing a fake) on the four targets; `docs.md` § Contexts
- [ ] a context read known at build (379 (6)): every `createContext` that can reach it of build and of one
      value, or none — computed from the hooks list from the roots; the reading function then `Any` with build
      arguments — `run/context_read_at_build` (`corDoTema()` a constant when `Theme` is never provided),
      `run/context_read_run_time` (a provide from `use request()` keeps it at run time)
- [ ] a `Build` / `Any` component called at build (378 (4)): the comptime runtime runs its lambda with
      `RenderScope.root()` (388; the comptime-runtime half of box 4b), a context answering
      its providers within the tree or its default — `run/comptime_render_component`
      (`comptime renderToString(<Rodape ano={2026} />)` a constant), `reject/component_run_hook_at_build`
- [x] the rules of hooks (357): `use` only at the top level of a `@Component` body —
      `error[use-not-top-level]` inside `if` / `else`, a `case` arm, a loop, a lambda, `try` /
      `catch`, or after a statement that may return early, naming the enclosing construct;
      `reject/use_in_if`, `reject/use_in_loop`, `reject/use_in_lambda`, `reject/use_after_early_return`;
      `run/use_conditional_argument` (`use provide(Ctx, if (c) a else b)` accepted)
- [x] the codemod: `@Component<C, R>` → `@Component<R>`, `implement @Context<C>` → `implement @Renderable`,
      `use @getContext(T)` reported at its line (no mechanical rewrite: the provider is the author's)

#### B-17 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-18 — 311, 415, 426, 429: templates

**Repository:** botopink-lang, with consumer commits in erika, jhonstart (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

The template annotation, the template method, `lookup`, a call typed by its expansion, built code located by
its expansion. Steps 29 and 41 landed (checker-s29, checker-s41); what step 29 leaves stays here, step 41 is done.

**Impacted tests:** `run/template_*`, `reject/template_*`; the drift test (`Expr`'s surface). **Model:** opus.
**Consumer commits:** erika (`erika.bp`'s padding), jhonstart (`html.bp`'s padding); unblocks erika 137 (145 s1),
dbcontext 143 (153).

#### Step 29 — the template annotation `#[f "…"]` (decision 311) (was `01-checker` s29)

`#[erika "select * from User where id = ${id} limit 1"]` on a method is a parse error today: an
annotation is `#[name]` or `#[name(args)]`, and its arguments are comptime values (280), so a hole
naming a parameter cannot be written. After, the template call `f "…"` may be written as an annotation.

- [x] parser: `#[f "…"]` and `#[f """…"""]` (also inside a `#[a, b]` list) — a node of its own beside
      the call form (`Annotation.template`, `parser/tests/decision311.zig`), printed as written (the
      `16-formatter` step 9 cell; inside a list it prints as its own block until that step's box 1)
- [x] checker: `f` resolves to a template function (first parameter `comptime q: @Expr<…>`); any other
      function is a located error at the annotation (`template-annotation-not-template`); `#[f(…)]`
      naming a template function is a located error naming `#[f "…"]` (`template-annotation-call-form`)
- [x] the literal is captured unevaluated, as at a call site; a `${…}` hole resolves in the annotated
      declaration's scope — on a method its parameters, by name and type (an unknown name is the
      ordinary unbound-name error at the hole) —; other names in the module's scope (112)
- [x] the template function receives the annotated declaration's `@Decl` beside `q` — its second
      parameter, `comptime decl: @Decl<…>`; such a function is written only as an annotation
      (`template-annotation-only` at a call, `template-annotation-without-decl` for a template without
      it — question `s29-a` ★) —, recorded in `docs.md` § Template annotations; a function's and a
      method's own `@Decl` carry `params` (`language-gaps.md`'s row "A method's own `@Decl` has no
      parameter list" is closed in the compiler; it goes with its two markers)
- [x] what the function produces goes to 216's four places, as a decorator's (typed meta, 298, for
      erika's query); a method's typed meta is read by its owner's decorator, `m.meta(T)` on a
      `decl.methods` entry, the methods' decorators running first (question `s29-b` ★); a string an
      output carries names a hole by its expression (`s29-c` ★)
- [x] `run/template_annotation` (a method annotation whose meta a type-level decorator reads) on the
      four targets; `reject/` cells for `#[f(…)]` on a template function, a non-template `#[f "…"]` and an
      unknown hole name (`template_annotation_call_form`, `_not_template`, `_unknown_hole`), and for
      `s29-a` (`_without_decl`, `_called`)
- [x] `docs.md` § Decorators and § Template functions document the form (§ Template annotations);
      `comptime/AGENTS.md` states how the literal and the `@Decl` reach the body

- [ ] a template method (397, 415): `comptime self: @Expr<R>` then `comptime q: @Expr<…>` — the receiver the call site's code (`self.text()`)
      is called `value.method "…"` / `value.method """…"""` as `f "…"` is — the literal captured
      unevaluated, `self` the receiver; erika's `QueryContext.query` its first user —
      `run/template_method_call`
- [x] a template call expands wherever an expression may stand (425): a type's method body, a destructuring
      initializer (`val #(n, total) = erika "…";`), a lambda, an argument, a field default (and a function
      parameter's), a `case` arm — `run/template_in_type_method`, `run/template_destructuring_init`,
      `run/template_in_{lambda,argument,field_default,case_arm}`, on the four targets; a call left unexpanded is
      a compiler error (`template-call-unexpanded`), never a run-time `undefined` (no position measured reaches
      it after the fix, so it has no `reject/` cell)

#### Step 39 — a template body reads a declaration through `@Decl` (decision 415) (was `01-checker` s39)

```bp
val decl = q.lookup("User") ?? q.fail("`User` is not in scope");   // ?@Decl, resolved at the call site
val table = decl.meta(QueryTable) ?? q.fail("`User` is not an entity — annotate it with #[entity(…)]");
decl.setMeta(…);                                                    // ❌ the looked-up handle is read-only
```

- [ ] `e.lookup(name)` answers `?@Decl` — `name`, `kind`, `module`, `fields`, `meta(T)`, `metaAll(T)` — of the declaration
      the name resolves to at the call site (112), `null` when none; `setMeta` / `addMeta` / `addMember` / `addType` on it
      refused at the call — `run/template_lookup_decl`, `reject/template_lookup_decl_write`
- [ ] `decl.meta(T)` / `metaAll(T)` answered at build when `T` is data (380); a meta with a run-time `@Expr` field refused at
      the read naming the field — `run/template_lookup_meta`, `reject/template_lookup_meta_expr_field`; `@typeInfo(X).meta(T)`
      in a template body stays `typeinfo-meta-at-build`
- [ ] the looked-up declaration's decorators run before the template body: another module as today, one module ordered
      (372's pattern) — `modules/template_lookup_meta_other_module`, `run/template_lookup_meta_same_module`
- [ ] `docs.md` § Template functions documents `lookup`'s handle; `comptime/AGENTS.md` states the order

#### Step 40 — a template call is typed by the code it built (decision 426) (was `01-checker` s40)

```bp
val n: i32 = erika "select name from cities";     // ❌ expected i32, got Array<string> — compiles today
val nomes = erika "select name from cities";      // nomes: Array<string>
```

- [ ] `finishExpansion` types the call by the expansion: no free `T` survives a template call; the built type is
      checked against the signature's answer (a bound) at the template's `build`, then unified with the expected type
      at the call — `run/template_call_typed_by_expansion`, `reject/template_call_expected_mismatch`,
      `reject/template_build_outside_bound`
- [ ] `q.note(message)` attached to an error reported at the call — `reject/template_note_on_mismatch` (the note
      in the expected text); `docs.md` § Template functions

#### Step 2 — declare the rest — part (was `134-builtins-declared` s2 box 5)

- [ ] `Expr`'s surface for 415 and 426: `lookup(name)` answers `?Decl<unknown>` (the `Binding` record goes), `build<R>`'s
      `R` is the type the built code infers to, `note(message)` declared — the drift test follows

#### B-18 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-20 — 330: the optional operators' rest and their codemod

**Repository:** botopink-lang, with consumer commits in actions, http, log, routing, validation, jhonstart, rakun (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

129 landed (import-129); its steps are done.

**Impacted tests:** `run/optional_*`; the migration script's own check. **Model:** sonnet.
**Consumer commits:** actions, http, log, routing, validation (the 330 codemod, one each); jhonstart, rakun
(129's import rewrite).

#### Step 31 — `?T` by TypeScript's operators, no methods; a type in a type is associated (decision 330) (was `01-checker` s31)

Today `??` and `?.` work; `?.[i]`, `?.(args)` and the postfix `!` do not parse; `?T`'s `map` / `flatMap` /
`unwrapOr` and the `result` namespace work in prose only (`builtins.d.bp` comments); a `type` in a
type's body is a parse error.

- [x] parser: `?.[i]`, `?.(args)` and the postfix `!` (`x!`, `x!.f()`); the prefix `!x` unchanged
- [x] checker: an operator over a value whose type is not `?T` is a located error naming the type (`s?.length()`,
      `s ?? "y"`, `s!` with `s: string`); `?.` over a member answering `?U` is `?U` (flattened); `??` beside
      `&&` / `||` without parentheses is a located error asking for them
- [ ] `x!`: `null` aborts with `value is null — <expr> at <file>:<line>:<col>` — built (`?? @panic(…)`,
      `run/optional_bang_aborts`); commonJS prints the text, erlang and beam abort with it as an Erlang binary
      (the `—` makes it non-latin1), wasm aborts without it: one text on the four targets is the backends'
      panic printing (02, 03, 05)
- [x] `?T` has no methods: `.map`, `.flatMap`, `.unwrapOr` on a `?T` are `unknown method` naming `?.` / `??`; on
      `@Result` they stay; `result.map(…)` and the rest of the namespace are unbound names. A method after a
      `?.` link continues its chain (`e?.key.length()`), as TypeScript's does
- [ ] a migration script (`scripts/codemod-optional-operators.py`, as 129's) rewrites `.unwrapOr(d)` on a `?T` to
      `?? d` and `result.<op>(r, …)` to `r.<op>(…)` in every tree — one commit per repository, before the
      refusals land. Built and run over botopink-lang (std, the five shared libraries, the language suite,
      `examples/`); the five library repositories' migrations are prepared, one per repository
- [x] a `type` declared in a type's body is that type's associated type (the `decl.addType` node, 216):
      `pub type Type { pub type Field<T>(…) { … } }` reads `Type.Field<T>` (308); `reject/` cells for a nested
      type named like a member
- [x] `docs.md` § Operators and § Optionals (07's prose) list the five operators and the five rules
- [ ] wasm: `?.()` over a function answering a plain value is refused (`run/optional_call_operator`'s
      `.wasm.expect`) — the answer has to be boxed (05)
- [ ] erlang, beam, wasm: `recv?.m()` over an absent receiver — `s?.length()` raises `badarg` on erlang and
      beam and answers `8` on wasm (the backends' `?.` method lowering; a method continuing a `?.member` chain
      is right on the four)
- [ ] erlang: `a ?? ns.f()` with a package-module namespace call as the default (std's own
      `os.tmpdir()`) lowers as a method call on `ns`; std reads it into a `val` first

#### B-20 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-21 — 364, 408, 409: `@Expr` hygiene, the typed function expression, the tail value

**Repository:** botopink-lang (`--lang`)

**Impacted tests:** `modules/decorator_member_fn_imported_name`, `run/fn_expr_typed_anywhere`, `run/fn_tail_value`
and its siblings. **Model:** opus. **Consumer commits:** none.

#### Step 37 — the typed function expression in every position (decision 408) (was `01-checker` s37)

```bp
val inc = fn(x: i32) -> i32 { return x + 1; };            // inc: fn(i32) -> i32
xs.map(fn(n: i32) -> string { return n.toString(); });
val f: fn(x: i32) -> i32 = fn(x: string) -> i32 { … };     // ❌ at the expression: expected fn(i32) -> i32
```

- [ ] `fn(x: T, …) -> R { … }` typed where it stands — a `val` / `var`, an argument, a return, `decl.addMember`;
      written types checked against the position's when it has one — `run/fn_expr_typed_anywhere`,
      `reject/fn_expr_typed_mismatch`
- [ ] `fn-expr-typed` and `reject/fn_expr_typed` deleted; `docs.md` § Lambdas and § Decorators rewritten; the
      braced lambda still untyped (328)

#### Step 38 — a body's last expression without `;` is its value (decision 409) (was `01-checker` s38)

```bp
fn inc(x: i32) -> i32 { x + 1 }
fn sign(n: i32) -> i32 { if (n < 0) return -1; n }
val inc = fn(x: i32) -> i32 { x + 1 };
fn bad(x: i32) -> i32 { "a" }           // ❌ expected i32, got string — at "a"
fn semi(x: i32) -> i32 { x + 1; }       // ❌ as today: the body falls off its end
```

- [ ] the parser keeps a body's last expression statement written without `;` as the tail (`ast` flag), in a named
      `fn`, a method, a `fn` expression and a lambda; a braced `if` / `case` / loop at the end stays a statement (16)
- [ ] the checker types the tail against `-> R` (`stmtsMayFallThrough` answers `false` after it); a non-`void` tail in
      a body answering nothing refused at it — `run/fn_tail_value`, `run/method_tail_value`,
      `run/fn_expr_tail_value`, `reject/fn_tail_type_mismatch`, `reject/fn_tail_in_void`
- [ ] every backend returns the tail (erlang the last expression, commonJS a `return`, wasm the block value) —
      the four targets
- [ ] measured first: the bodies in std, `tests/language` and the libraries whose last line has no `;` today,
      the count in this README; `docs.md` § Functions, § Lambdas

#### Step 11 — a body's tail printed as written (decision 409) (was `16-formatter` s11)

- [ ] a body's last expression without `;` (`fn inc(x: i32) -> i32 { x + 1 }`) prints without it, one written with
      `;` keeps it — the printer adds and removes none; a one-line body stays on one line when it fits;
      `format/tests/declarations.zig` cases (`assertFormat`, `assertIdempotent`); the typed `fn` expression (408)
      printed in every position

**Gate:** standard (fronts.md § Gate) + `scripts/format-check.sh` green over every `TREES` tree, a
second pass moves nothing · `zig build test-libs` at baseline after step 3 (every library compiles
under the refusal)

#### B-21 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-23 — 247, 255, 310 and the checker's rows

**Repository:** botopink-lang (`--lang`)

**Impacted tests:** `run/wide_literal_past_js_safe_integer`, `modules/import_two_types_one_name`, the rows' cells.
**Model:** opus. **Consumer commits:** none.

#### Step 18 — numeric literal suffixes (decision 247) — built (`19d59508`, on feat through `49455602`) (was `01-checker` s18)

Kotlin's, lowercase, every numeric type: `1.5f` `f32`, `1.5d` `f64`, `42l` `i64`, `42u` `u32`,
`42ul` `u64`, `42i8`, `42i16`, `42u8`, `42u16`, `42isize`, `42usize`. Uppercase = located error
naming the lowercase; unsuffixed never changes type to fit (`val x: f64 = 1` refused — 209 reversed;
215 stands). Built: the suffix kept in the
number's token (`lexer.zig` `splitNumber`, `numberSuffixType`, `numberBackendText`; hex digits vs
`f`/`d`, exponent, member access on a literal — `parser/tests/decision247.zig`);
`run/numeric_literal_suffixes` (every suffix, a suffixed number pattern);
`reject/number_suffix_{uppercase,unknown,float_on_radix,integer_on_float}`,
`reject/number_exponent_without_digits`, `reject/integer_suffix_out_of_range`,
`reject/number_pattern_{of_another_type,suffix_disagrees}`; the unsuffixed mismatch
`reject/integer_literal_{never_fits_f64,operand_of_f64,beside_float_in_array}`,
`reject/float_literal_never_fits_f32` (`run/integer_literal_fits_f64` deleted); an `l` literal past
2^53 refused on commonJS (`run/wide_literal_past_js_safe_integer.commonJS.expect`); `docs.md` §
Numeric literals.

- [ ] an integer literal past its type's range refused on every target (decision 319): `refuseBeyondJsSafeInteger`
      (`comptime/infer.zig`) deleted, its 247 citation with it; `run/wide_literal_past_js_safe_integer` answers
      the value on the four targets (after `04-js` step 9)
- [ ] `language-gaps.md`'s rows "`f32` has no literal" and "An `i64` has no literal" lose their
      literal half; a cold gate green on `49455602` (no gate has run on the merge)

#### Step 19 — a type application before a member (decision 255 (1)) — built (`6185db3c`, on feat through `49455602`) (was `01-checker` s19)

`Dict<string, unknown>.empty()`: a type name with explicit type arguments followed by `.` or `(` is a
type application (1.0.10 decision 8 §1.3 extended to a type's member); elsewhere `<` is a comparison.
The list goes to the chain's first link (`receiverTypeArgs`); the checker binds the type's parameters
(`applyReceiverTypeArgs`). Built: `run/type_application_static_member` on four targets,
`reject/type_application_{argument_mismatch,argument_count,variant_payload_mismatch,on_a_field}`,
`botopink format` round-trip (`parser/tests/decision255.zig`, `format.zig` `typeArgsDoc`), `docs.md`
§ Generics.

- [ ] a type application through a module namespace (`collections.Dict<K, V>.empty()` — the head is a
      value's name, so the list is a comparison there): built, or refused with a located message

#### Rows other fronts found — part (was `01-checker` rows boxes 1, 3, 4)

- [ ] comptime body diagnostic names the body's file: `infer.zig` (`decoratorError`) passes the
      display path, or locates at the body call for the module's own decorator — asserted in
      `comptime_module.zig`, `decorator_invocation.zig` (from `14-comptime-on-beam` step 1)
- [x] a module is its package plus its path (170, 337): an item with no `from` names one module of
      the importing package by its registry key (`ImportSource.key`, `Module.package` stamped on each
      import as `ImportDecl.ownPackage`), so `a/theme` and `b/theme` are two modules to the checker,
      `crossModule.pick`, every backend (erlang's imported-enum owner), the `.d.ts` and the comptime
      runtime (`block_eval.findType` by module); a dependency's shorthand stays in its package
      (`modules/two_packages_one_module_name`, four targets; from `08-bpp/119` step 1 box 4)
- [ ] two aliased imports of two same-named **types** are legal (310): every backend qualifies a type by
      its module; `modules/import_two_types_one_name` becomes an accept cell on every target (until
      then the refusal is a `language-gaps.md` row)
- [ ] `@External.Wasm` binding read on every target: checker walk over `external_variants` with
      `codegen/wat/host_binding.zig`'s `parse`, so a misspelt `op:` no wasm build reaches is refused
      (from `05-wasm` step 5)
- [x] `infer.zig`'s template memo key appends the whole scope's JSON per call site — O(scope) per
      template call: now `template_eval.memoKey` — the callee, each capture's text with the scope
      entries of its words (decision 237), the plain arguments; 0.034 → 0.002 ms per N=200 call
      (`14-comptime-on-beam` step 2)
- [x] an unsuffixed integer literal is range-checked in the type its position asks for, `i32` with
      nothing asking (247): `val e: i32 = 3000000000` and an unannotated `3000000000` are refused at
      the literal (`reject/integer_literal_unsuffixed_out_of_range`,
      `reject/integer_literal_unsuffixed_default_out_of_range`); `run/i64_full_width`'s
      `@print(4294967296)` is written `4294967296l` (from `04-js` step 9; bugs-sweep)
- [x] the operand of a unary `-` is read as the negative value: `-9223372036854775808l` is `i64`'s
      minimum, `-129` is below `i8`, a negated literal takes its width from the other operand
      (`isIntegerLiteralOperand`), wasm emits a type's minimum as the constant
      (`run/integer_literal_type_minimum`, `reject/integer_literal_below_minimum`; bugs-sweep, bs-b)
- [x] `refuseIntegerOutOfRange` cites 319 (`infer_errors` "cites decision 319"; bugs-sweep)

**Gate:** standard (fronts.md § Gate) + every re-recorded `snapshots/comptime/**` file read for
expected/found orientation; a refusal moving a backend fixture is reported to that backend's front,
never deleted here · `botopink check` of every package of the seven repositories identical to the
parent binary, `zig build test-libs` at baseline (a library that reds gets a migration plan in the
commit)

#### B-23 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [ ] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [ ] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named

### B-55 — whole-package analysis: can two modules of a package import each other? (study, s23-i)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

Measured (the study's prototype stays on its branch, never landed). **Today** the resolver
(`compiler-cli/src/cli/resolver.zig` `orderByDependencies`) sorts a package's modules by their imports and refuses
no cycle: when the sort stalls the leftover modules go out in discovery order and the checker reports an unrelated
`unbound variable` (`a ↔ b`: `error: unbound variable 'base' --> src/b.bp:4:18`), the same on every target; s23-i's
"no import cycle" has no diagnostic of its own. Each module is analysed whole, in order (signatures, 372's plain
decorators, bodies, `.hooks` readers, `registerExports`); a function's signature never depends on its body.

**The design**, if adopted (the question is `decisions-pending.md` B-55-a): the resolver loads the package as one
unit and computes its strongly connected components (the package graph, 512's members and dependencies, stays
acyclic); each declaration is `unresolved → in progress → done`, a `fn` or type done after its header (signature,
plain decorators' members), a `val` without annotation demanded whole, a meta demanded by running its `.hooks`
readers over the bodies it reads; `in progress` met again is a located `dependency loop`. 130-s8-c's step 4 becomes
the general rule; the catalogue demands every listed declaration (353's second compile goes); 14s8-d's option (b)
falls out. What stays refused: a value cycle, a `comptime` depending on itself, a decorator reaching what it
annotates, a `.hooks` reader adding a member, a build-time catalogue listing its own reader.

**Does it solve what opened it:** 130-s8-c yes (a header-only prototype printed `none` for the module analysed
first — meta must be demanded); s23-i partly (the root rule stays or is relaxed, option (b′)); 372's order yes, its
output restriction stays; 14s8-d yes.

**Each backend on a cycle** (real programs, the prototype): erlang and beam correct (a remote call; a module-level
`val` a 0-arity function recomputed at each read); wasm correct (one linked module); commonJS wrong at load —
`const { f } = require(…)` reads a cycle's empty `exports`, a function `undefined` too; hoisted function exports
plus memoised getters for module-level values (checked by hand under node) run it, as would one file per package.

- [x] the design written, with what stays a refusal and what s23-i's root rules become
- [ ] measured on the prototype: the cost on `zig build test` and on the language server's incremental check — on a
      quiet machine
- [x] each backend's answer to a module cycle measured: erlang, beam and wasm correct; commonJS needs hoisted exports
      and lazy values, or one file per package
- [x] the report and the question filed: `decisions-pending.md` B-55-a (adopt, with its steps; or keep the acyclic
      rule with its own located refusal)

### B-56 — `botopink migrate` removed (s23-i)

**Repository:** botopink-lang (`--lang`) · **Model:** haiku

`botopink migrate [--dry-run]` derives a module tree from the `src/` layout for a package without one. s23-i makes the
tree explicit (`src/lib.bp`, or `src/main.bp` with no `lib.bp`) and removes the blind scan, so the command has no use.

- [ ] the command removed: its dispatch in `compiler-cli/src/main.zig`, `cli/migrate.zig`, its tests, its rows in
      `compiler-cli/AGENTS.md` and `cli/AGENTS.md`, and every doc that names it; `botopink migrate` answers the CLI's
      unknown-command error
- [ ] Conformance step (459, 474, 477, 478, 480)

### The module-model group (B-69 … B-76, B-55-a (e)): a file is a module, `src/comptime/` the build layer

After the cache group's Conformance step, and only once B-55's timings pass (B-55-a (e)'s condition; a high cost
returns the question to the maintainer). One rule replaces s23-i's root rules, 419's and 14s8-d's refusals and 353's
second compile: every `.bp` under `src/` is a module named by its path; `mod` / `pub mod` and `lib.bp` / `root.bp`
leave the language; `src/main.bp` is an executable's entry; `src/comptime/` is the build layer, analysed first,
importing only std, dependencies and itself, the one place (with std and dependencies) that declares a decorator or a
template; the program's modules import each other freely, a cycle forming a block (headers before bodies, a
module-level `val` a ref at run time); per block the decorators run over the bodies, then meta and catalogues are
filled; `@TypeInfo.all` is read in any module; `src/internal/` is private to its package; the only order refusal is a
located `dependency loop`. In order:

### B-69 — a file is a module: `mod` / `pub mod` and the root file removed (B-55-a (e) (1), (2), (8))

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** the cache group's Conformance step, B-55

- [ ] the resolver loads every `.bp` under `src/` as a module named by its path (`pages/home.bp` → `pages.home`);
      `src/main.bp` is the entry, imported by no module (refused, located)
- [ ] `mod` / `pub mod` removed from the language: the parser refuses them, located (`` `mod` is gone — every file
      under src/ is a module (B-55-a) ``), the AST node, the formatter and the checker's module-tree walk go;
      `lib.bp` / `root.bp` are ordinary files with no special role, std's included
- [ ] `src/internal/` private to its package: an import of it from another package refused, located
- [ ] until B-71 lands, an import cycle is refused by name, located (`import cycle: src/a.bp imports src/b.bp, which
      imports src/a.bp`), in place of today's `unbound variable`
- [ ] the orphan warning and the blind-scan fallback go (`sources.zig`); `AGENTS.md` (compiler-cli, resolver) updated
- [ ] cells red on the parent: a module by path, `mod` refused, `internal/` refused from outside, the cycle refusal
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-70 — `src/comptime/`, the build layer (B-55-a (e) (3))

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** B-69

- [ ] `src/comptime/` analysed before every other module of the package; it imports only std, dependencies and
      `src/comptime/` (else refused, located)
- [ ] a decorator or a template declared outside `src/comptime/`, std and a dependency refused, located
- [ ] cells red on the parent for both refusals; a decorator from `src/comptime/` applied in a program module
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-71 — blocks: modules importing each other, headers before bodies, `dependency loop` (B-55-a (e) (4), (6))

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** B-70

- [ ] the resolver computes the program's strongly connected components; each block's headers (`fn` signatures, types,
      annotated `val`s) are registered before its bodies; B-69's cycle refusal goes
- [ ] a value needing itself across modules (`pub val x = b.y + 1` / `pub val y = a.x + 1`) refused, located:
      `` dependency loop: `a.x` → `b.y` → `a.x` ``
- [ ] erlang, beam and wasm run a cycle (B-55's measurements); cells: `a.title` ↔ `b.format`, `a.isEven` ↔ `b.isOdd`,
      the value loop refused
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-72 — per block: decorators after the bodies, meta and catalogues filled (B-55-a (e) (5), (6), (7))

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** B-71

- [ ] per block: headers, bodies, every decorator over them, then every `@typeInfo(X).meta(T)` (`T[]`, 130-s8-a) and
      `@TypeInfo.all` of the block filled — 130-s8-c's step 4, per block
- [ ] `@TypeInfo.all` read in any module; a `comptime` needing a meta, a catalogue or a value of its own block before
      its decorators ran refused, located, as a `dependency loop`
- [ ] 419's and 14s8-d's refusals and 353's second compile removed; `typeinfo-meta-hooks-pending` and
      `typeinfo-all-hooks-reader` gone
- [ ] cells: `home.bp` ↔ `blog.bp` each reading the other's `Route`; a catalogue in a page module; the comptime loop
      refused
- [ ] B-60's `.botopinkbuild/analysis/` keys its entries by block (headers, bodies, decorators' meta of a block)
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-73 — commonJS: a module cycle loads (B-55-a (e) (4))

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet · **After:** B-71

- [ ] a module's functions hoisted onto `exports` before any `require`; a module-level `val` a memoised getter
- [ ] B-71's and B-72's cycle cells green on commonJS; a codegen test, red on the parent
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-74 — the language server checks the edited module's block (B-55-a (e))

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet · **After:** B-72

- [ ] an edit re-checks its module's block and the blocks importing it, never the whole package; no `mod` tree read
- [ ] a language-server test: an edit in one module of a cycle reports the other's error
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-75 — std and every library on the module model (B-55-a (e))

**Repository:** botopink-lang and every library (`scripts/worktree-add.sh` full worktree) · **Model:** sonnet ·
**After:** B-70

One mechanical pass, as B-33's codemod: no design choice.

- [ ] std: `libs/std/src/root.bp` and every `mod` / `pub mod` removed; its decorators and templates moved to
      `libs/std/src/comptime/`
- [ ] each library (emilia, erika, jhonstart, onze, rakun, actions, http, log, routing, validation, css, styled, snap,
      json, yaml, markdown, dbcontext, vscode-extension's botopink sources): `src/root.bp` / `src/lib.bp` and every
      `mod` / `pub mod` removed, decorators and templates (`#[route]`, `#[page]`, `html`, `css`, `styled` …) moved to
      `src/comptime/`, private modules to `src/internal/`; each library's gate green
- [ ] the specs and `AGENTS.md` files that name `root.bp`, `lib.bp` or `pub mod` updated
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-76 — the module-model group's Conformance step

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet · **After:** B-69 … B-75

- [ ] botopink-lang's and every library's gate with conformance, cold and warm; every cell green on every target
- [ ] the root `conformance/docs.md` rewritten for the module model (480)
