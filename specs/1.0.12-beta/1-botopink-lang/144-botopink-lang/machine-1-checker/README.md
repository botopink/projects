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

- [x] parser: `label = value` in an annotation's arguments is a located error naming `label:`
      (`reject/annotation_label_equals`); `Annotation.labels` read from `label: value` only;
      `parser/AGENTS.md`'s labelled-argument line rewritten
- [x] `@External.<Target>(fn: name)` — `name` resolves to a private botopink function of the same module,
      its signature checked against the bound one; a misspelt name is the ordinary unbound-name error at
      the argument (`reject/external_fn_unbound`); renaming the function renames the binding
- [x] `@External.Wasm(op: "f64.sqrt")` checked against the opcode table (238's check, now on the label);
      `@External.Wasm(wasi: .RandomF64)` — `wasi`'s type is an enum of docs.md's adapter list
- [x] the old prefixed strings (`"fn:…"`, `"op:…"`, `"wasi:…"`) are no longer recognised: an unlabelled
      string is host code, always; a string starting with one of the old prefixes is a located error
      naming the labelled form (one release, then removed)
- [x] std's 88 bindings migrated (79 `fn:`, 6 `op:`, 3 `wasi:`), `scripts/` grep cell: no `"fn:` /
      `"op:` / `"wasi:` left in `libs/**`; `docs.md` § External rewritten

#### Step 10 — `label: value` in annotations (decision 305) (was `16-formatter` s10)

- [x] a labelled annotation argument prints `label: value` (`#[@BeamMemory.Ets(keyed: true)]`,
      `#[@External.Erlang("…", inline: true)]`); `src/format/AGENTS.md`'s "prints `label = value`" row
      rewritten; `format/tests/declarations.zig` cases updated (`assertFormat`, `assertIdempotent`)

#### Step 2 — the text and the migration handed over — part (was `17-beam-memory` s2 box 1)

- [x] `keyed: true` (decision 305) in every cell and diagnostic of this front; `keyed = true` is the
      parser's located error (`01-checker` step 27)

#### B-02 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named
      — the conformance suite green on `feat` locally (1909 cells, no red B-02's); no `test` run green since the base:
      each failed at `format-check` on other steps' cells (B-22's, B-12's, B-04's, erika's moved cell — fixed — and B-17's
      `stage_imported`, `stage_of_functions`, open) or was superseded; every `tag` run green. Box 1 closes on the next
      green `test` run.

| B-02 change | Cells |
|---|---|
| `label = value` refused at the label, naming `label:` | `annotation_label_equals`, `annotation_label_equals_decorator` |
| labels read from `label: value` only | the `beam_memory_*` cells, `external_inline_unread`, the `decorator_arg*` cells, `annotation_unknown_family` |
| `fn: name` on every target, checked against the declaration | `external_fn_body_every_target`, `external_method_local`, `external_wasm_host_binding`, `external_wasm_host_twice` |
| a misspelt `fn:` is the unbound-name error | `external_fn_unbound` |
| prefixed `"fn:…"` refused on Node / Erlang | `external_prefixed_fn_refused`, `external_erlang_prefixed_fn_refused` |
| prefixed `"op:…"` / `"wasi:…"` off wasm name the wasm cell | `external_node_prefixed_op_refused` |
| prefixed strings on `@External.Wasm` (481) | `external_wasm_prefixed_{fn,op,wasi,std}_refused` |
| the formatter prints `label: value`; the LSP rename; no prefixed string in `libs/**` | no cell: `format/tests/declarations.zig`, `language-server/src/tests/rename.zig`, the `build.zig` scan |

- [ ] `"std:…"` on `@External.Node` / `Erlang`: host code (as built) or refused like the other prefixes · question B-02-c

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

- [x] G1, first: two test modules declaring one type name stay two types under `botopink test --target erlang`
      (`language-gaps.md`'s row, validation `test/schema_test.bp`'s marker) — measured repro: validation's
      `test/refine_and_messages_example_test.bp` case "decode runs the type-level rules…" is red on erlang because
      another test module's `Signup` answers `Signup.decode`; it holds 146 s1's typed-member route (430)
- [ ] G1: every row closed by a cell on the four targets; validation's markers removed in the landing (one
      consumer commit); the rows and their Marker index rows gone
      — built: a static member as a value (`associated_fn_as_value`), the spread in an added member and the many
      locals (pins `decorator_member_record_update`, `decorator_lambda_many_locals`), a `Decorator` parameter taking
      a decorator's name (`decorator_argument_decorator_name`); validation's four markers and their rows gone. Left:
- [ ] `Decl.variants`' entries carry a variant's payload fields and annotations · question B-10-b
- [ ] `Field` reflects a field's default · question B-10-a
- [ ] `clock.formatIso8601` one text on erlang and commonJS (497) · question B-10-c
- [ ] `Decorator` an unknown type in a package's module: validation's last marker of it rewritten over
      `decorator_argument_decorator_name`'s rule, or the row re-measured
- [ ] handed to 146 (their compiler halves built): the comptime parameter default and the raw lexeme (125 s12, s7),
      `#[each("email")]` → `#[each(email)]` (125 s8)
- [ ] G2: the same for styled's and emilia's markers — built: a method's behavior-typed parameter takes an
      implementer (`method_behavior_parameter_implementer`); a template-reached enum variant or private record no
      longer reproduces across a package. Left:
- [ ] a bare variant in expression position (`Two(t)`) checks but fails on commonJS, erlang and beam · question B-10-d
- [x] an imported enum's variant by dot-shorthand, the enum not imported (reached through a signature): unbound
      `Mode` on commonJS and erlang (beam and wasm right) — the backends import a type the module reaches only
      through a signature
- [ ] a wrapper's type alias implementing a behavior (`StyledView implement Styleable` over `@Component<Styled>`) ·
      question B-10-e
- [ ] handed to 148: styled's `Sheet.add` half (an API change; `toStyled()` answers a component)
- [ ] waits elsewhere: a template reading another expansion's value (119's design), a decorator body calling a host
      function (B-00c), a library template reading the program's catalogue (B-19)
- [ ] G3: the same for jhonstart's markers (after B-15 and 388) — built: template-built code builds an inline props
      type (`template_builds_inline_props`; jhonstart's two html test markers and the row gone). Left:
- [ ] a decorator reads whether a `@Component<R>` return's `R` implements `@Renderable` · question B-10-f
- [ ] `html` declared `-> @ExprCustom<View>` (`View = @Component<Element>`): every expansion fails `expected
      Component, got Element` · question B-10-g
- [ ] G5: the same for onze-content's marker — no compiler change: decision 306 makes it a type decorator over
      `decl.fields` (121 step 10), handed to 162

**Impacted tests:** a `run/` or `reject/` cell per row; the libraries' suites. **Model:** opus for checker rows,
sonnet for a backend row with its repro. **Consumer commits:** validation, styled, emilia, jhonstart, onze.

#### Rows other fronts found — part (was `01-checker` rows box 2)

- [x] package module namespace in type and value position (`import {report} from "validation"`, then
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
pub fn useCache(comptime decl: @Decl<fn(..) -> string>, comptime policy: @Expr<CachePolicy>) {
    decl.wrapWith({ call -> cacheThrough(policy, call.args, { -> call.run() }) });
}

#[useCache(policyFor("posts", minutes(5)))]
pub fn posts() -> string { return loadPosts(); }
```

- [x] `decl.wrapWith(f)` in `builtins.d.bp` (with 134): `f` receives the call value (the arguments and
      running the original body — spelling decided here, recorded in `docs.md` § Decorators) and answers
      the function's return type; a wrapper whose type does not match the annotated signature
      (`@Decl<fn(..) -> T>`, 280) is an error at the decorator
- [x] the wrapped function keeps its name, signature and identity for callers (a reference to it is
      the wrapped behaviour); the original body is reachable only through the call value
- [x] two or more wrappers compose in annotation order, the first written outermost — one cell
- [x] on a method it wraps that method; on a function or method of another module the wrapper runs
      wherever it is called (the importer sees the wrapped behaviour)
- [x] a decorator still reads no body (lg2-d) and writes none as a string (281)
- [x] `run/decorator_wraps_function` (a counting wrapper, a cache wrapper, two composed) on the four
      targets; `reject/` cells for a wrapper of the wrong return type and for `wrapWith` outside a
      function or method decorator
- [x] `01-checker/examples/decorator-arguments-280.md` example 5 runs (no longer illustrative);
      `language-gaps.md`'s row "A decorator cannot rewrite or wrap the body it annotates" closes once
      its marker (rakun 15's `publish-reliability-example.bp`) is rewritten — example 5 runs in the
      `@Expr` form above (a value argument is `@Expr`, 370; the wrapper a lambda); the marker's rewrite is
      150's (`#[retryable(policy)]` on `issue` over `decl.wrapWith`), its row there
- [ ] the wrapper is a lambda written at the call (`decorator-wrap-not-lambda`), or any value of the call
      type · question B-11-a
- [ ] a generic function or owner is refused (`decorator-wrap-generic`) · question B-11-b

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

- [x] the parser reads `...expr` at the start of a record constructor's argument; `a...b` stays the
      inclusive range; the formatter prints `...src` (with `01-compiler/16`)
- [x] the source is the record's type or a 307 type derived from it (`pick`, `omit`, `merge`); any
      other record refused at the `...` naming both types; a `Type.partial` value refused
- [x] arguments apply left to right; a field without a default supplied by neither a spread nor a
      label is an error at the call; a label written twice stays an error
- [x] `run/record_spread` on the four targets (a new record, the source unchanged and evaluated once);
      `reject/record_spread_other_type`, `reject/record_spread_partial`, `reject/record_spread_missing_field`
- [x] a plain function call takes no spread (267): `reject/call_spread`
- [x] a source whose type is an import alias of a derived type is refused: the lineage is matched by the type's
      name, so `import {Contato as C}` then `Pessoa(...c, …)` with `c: C` does not reach `Contato`'s source — follow
      the alias; one cell
- [ ] `..base` (decision 37) beside 359's `...src` · question B-14-a
- [ ] a source that is not a name is evaluated before the labelled values, even one written after it · question B-14-b
- [ ] `Type.pick` / `omit` / `merge` of a `Type.partial` type, and `Type.required`: their lineage · question B-14-c

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

- [x] `DeclKind` gains `Element`, `Component`; `Decl.component: ?Decl` (a component tag's function);
      a tag's static attributes readable (`decl.attr(name) -> ?string`)
- [x] `@Expr`/`@ExprCustom` capture: a template function constructs a tag's `@Decl`, calls an annotation
      with it (the `Decorator` of 268, `Decorator.same` for identity, 371), reads `meta(T)` / `metaAll(T)` (298)
- [x] on a tag `addMember`, `addType` refused at the call; `setMeta` of one type twice refused at the second
- [x] `run/tag_decl_meta` — an annotation recording `ClassName(names: ["a"])` on a `<div>` read back by the
      template function; the same annotation function also accepted on a declaration
- [ ] the template side's spelling: `q.tagDecl(kind, name, attrs)` builds the handle, `q.annotate(decl, at: Span)`
      runs the annotation written at a span of the template's text · question B-15-a
- [ ] `Decorator.same` inside a template body: a looked-up name's `Binding` carries no `Decorator` (meta read by
      type works, 302) · question B-15-b
- [ ] `d.meta(T)` on a decorator's own `@Decl` parameter is refused, so an annotation cannot read what an earlier
      one recorded on the same tag · question B-15-c
- [ ] `template.mapSpanToLoc` places a span of a one-line `"""…"""` literal two columns early (the capture has
      `multiline=false`) — found by B-15

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

**Repository:** botopink-lang, with consumer commits in rakun, validation (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

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
- [x] `Type.keys(Recipe)` is `Type.Field<Recipe>` (decision 308) — the same type, not a copy: not a record
      derivation, not answered
- [x] a `Type.Field<T>` at run time: stored, passed, compared; `case key { .title -> … }` exhaustive over
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
      `omit` are declared (Done); the spelling of a `type` answer is fixed here with `01-checker` step 28; builtins' `Field` leaves in this step, no alias kept: validation's `decorators.bp` (`Array<Field>`) and
      rakun-data's `orm/entity.bp` migrate to `Type.Field<unknown>` as its consumer commits (rule 10)
- [ ] a field key's `typeName`, `annotations` and printed form at run time · question B-16-a
- [ ] `Type.keys` on an annotated `val` refused (`derived-type-arguments`, as built) · question B-16-b
- [x] the four bare names (`partial`, `pick`, `omit`, `mergeRecords`) leave `tryResolveTypeManipulationCall`
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
- [x] a namespace import registers the module's body-carrying decorators under `<ns>.<name>`, as std's are
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

- [x] each function's stage from its resources (376 (1)) and its calls (376 (2)); `use h(…)` takes `h`'s;
      `provide` / `context` `Any`; a host function `Run` unless std (or its library) declares it `Any`;
      `HookNode.stage` published with the module's nodes — `run/stage_of_functions`,
      `modules/stage_imported`
- [x] `build-and-run` at the second resource, naming the first; a `comptime { … }` block separates them —
      `reject/stage_build_and_run`, `run/stage_comptime_block_in_run`
- [ ] a body that runs at build (decorator, template, `comptime`) calls `Build` / `Any` functions, a
      program's helper included, and refuses a `Run` one at the call (`run-in-build`) —
      `run/decorator_calls_any_helper`, `reject/decorator_calls_run`; `language-gaps.md`'s sibling-fn row
      closes
- [ ] std declares `Any` on its pure host primitives (`string`, `math`), every other host binding `Run`

- [ ] a run-in-build body calling a host function that has a build form (`std:`, `@External.Wasm` `fn:`): `Any`, or
      376 as written (`decorator_host_cells`, `comptime_std_host_function`, `comptime_random_seeded` change) · question B-17-a
- [ ] the spelling `#[@Stage.Any]`, `pub type Stage { Build, Run, Any }` in `builtins.d.bp` · question B-17-b
- [ ] the `Build` resource is a read of a comptime `@Decl` / `@Expr` parameter; `@typeInfo(NamedType)` a build constant · question B-17-c
- [ ] a stage follows declarations only (a method, a function value add nothing); a run body calling a comptime-`@Expr`
      function and reading the clock is build-and-run · question B-17-d
- [x] a `comptime x: @Expr<string>` function called at run time whose body uses `x.value` as a receiver
      (`names.value.split(",")`) emits an unbound variable on commonJS and erlang — found by B-17

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

- [x] a template method (397, 415): `comptime self: @Expr<R>` then `comptime q: @Expr<…>` — the receiver the call site's code (`self.text()`)
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

- [x] `e.lookup(name)` answers `?@Decl` — `name`, `kind`, `module`, `fields`, `meta(T)`, `metaAll(T)` — of the declaration
      the name resolves to at the call site (112), `null` when none; `setMeta` / `addMeta` / `addMember` / `addType` on it
      refused at the call — `run/template_lookup_decl`, `reject/template_lookup_decl_write`
- [x] `decl.meta(T)` / `metaAll(T)` answered at build when `T` is data (380); a meta with a run-time `@Expr` field refused at
      the read naming the field — `run/template_lookup_meta`, `reject/template_lookup_meta_expr_field`; `@typeInfo(X).meta(T)`
      in a template body stays `typeinfo-meta-at-build`
- [x] the looked-up declaration's decorators run before the template body: another module as today, one module ordered
      (372's pattern) — `modules/template_lookup_meta_other_module`, `run/template_lookup_meta_same_module`
- [x] `docs.md` § Template functions documents `lookup`'s handle; `comptime/AGENTS.md` states the order

#### Step 40 — a template call is typed by the code it built (decision 426) (was `01-checker` s40)

```bp
val n: i32 = erika "select name from cities";     // ❌ expected i32, got Array<string> — compiles today
val nomes = erika "select name from cities";      // nomes: Array<string>
```

- [x] `finishExpansion` types the call by the expansion: no free `T` survives a template call; the built type is
      checked against the signature's answer (a bound) at the template's `build`, then unified with the expected type
      at the call — `run/template_call_typed_by_expansion`, `reject/template_call_expected_mismatch`,
      `reject/template_build_outside_bound`
- [x] `q.note(message)` attached to an error reported at the call — `reject/template_note_on_mismatch` (the note
      in the expected text); `docs.md` § Template functions

#### Step 2 — declare the rest — part (was `134-builtins-declared` s2 box 5)

- [x] `Expr`'s surface for 415 and 426: `lookup(name)` answers `?Decl<unknown>` (the `Binding` record goes), `build<R>`'s
      `R` is the type the built code infers to, `note(message)` declared — the drift test follows

- [ ] a template method found only by a name in the call site's scope (as built), or reached through the receiver's type
      with no import (`self.db.query`, 145's example) · question B-18-a
- [ ] the surface B-18 chose: `q.note` appended as `— note: …`; `bindings()` answers `Decl[]`, `Binding.ref()` gone;
      `@Decl.module` on every handle · question B-18-b

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

### B-19 — 216, 281, 298, 353, 356: decorator outputs

**Repository:** botopink-lang, with consumer commits in rakun, jhonstart, validation, styled (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `tests/language` `@emit` cells (become `reject/`), `run/meta_*`, `run/template_reads_program_catalogue`.
**Model:** opus. **Consumer commits:** rakun (the remaining `@emit` sites, typed meta — each a decision-188
commit after the owning rakun step), jhonstart (`#[page]`, `#[client]`), validation, styled (the catalogue).

#### Step 5 — migrate the remaining sites (was `130-decorator-outputs` s5)

Decision 318 shrinks rakun's list before it migrates: `#[service]`, `#[managed]`, the core's `#[repository]`,
`#[restController]`, `#[configuration]` / `#[bean]`, the four transport listeners and `#[httpExchange]` are
deleted by the owning rakun fronts (04 step 8, 13 step 6, 15 step 8), not migrated; only their
replacements are written here in 216's forms.

Member names are the library's (decision 174's note). Remaining `@emit(` at feat — a closed list
(373: no front writes a new site, the count only shrinks): rakun 67 lines, jhonstart 1 (`#[page]`'s
`<X>Params`), validation 1. Rakun rows target post-128 paths
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

- [ ] each library's hook green on this compiler; `grep -rn '@emit(' --include=*.bp repository/` — validation's sites migrated (private members, `T.parseAt` passed as a value); left: jhonstart's 1 (after B-17, `05-jhonstart/26` s11), rakun's 67 (after 318's deletions in 150: 04 s8, 13 s6, 15 s8)
      answers only `tests/language` cells about `@emit` itself

#### Step 6 — remove module-level `@emit` (was `130-decorator-outputs` s6)

`@emit` a named error everywhere (message lists the four places); `tests/language` `@emit` cells
become `reject/` cells; `docs.md`'s "Decided, not yet implemented" row leaves; `language-gaps.md`
closes **An emitted `pub val` is visible to other emitted code only** (T15) and **No comptime
reflection over the project** (declaration half; the `@project()` manifest half is not 216's).

- [ ] the refusal and the cells; the two `language-gaps.md` rows closed

#### Rows found during the migration (open, not 216's places) (was `130-decorator-outputs` rows)

- [x] a `behavior`'s associated `default fn` called through the behavior from another module
      (`Shape.unit()` with `import {shapes.Shape}`): unknown erlang module on erlang/beam, run-time
      error on commonJS, refusal on wasm — members do not travel with a behavior as with a type
      (holds `rakun-client`'s two sites)
- [x] an associated fn read as a value (`apply(City.make, …)`) is an unbound variable on erlang
- [ ] a member's / associated type's diagnostic is located past the file's last line (member source
      placed after the module's lines) and names `City__Columns`, not `City.Columns`
      — the type named by its owner's path landed (`assoc_type_named_by_owner_in_diagnostic`); the location · question B-19-a
- [x] a decorator imported from another module whose body builds a record private to its module fails
      at the evaluator (`call to undefined function Entity/1`): `block_eval.typesReached` finds an imported
      decorator's types through the export registry only — string meta and typed meta alike (found by
      step 8; `01-checker` step 21 owns `block_eval.zig`)

#### Step 7 — references, not strings (decision 281) (was `130-decorator-outputs` s7)

- [ ] `@TypeInfo.all(with: …, member: "make")` (256) names the member by reference — an interface's
      method — not by string; `Declared.value` stays `unknown` (254; `nat-a` answered by 281)
- [ ] `member:`'s reference: its spelling, whether a catalogued type must `implement` the behavior, refused or
      skipped at the query · question B-19-b

#### Step 8 — typed meta, keyed by its type (decision 298) (was `130-decorator-outputs` s8)

`Decl.setMeta(value: T)` — one value per type per declaration, a second of the same type refused at
the call —; `Decl.addMeta(value: T)` for what repeats; read `@typeInfo(X).meta(T) -> ?T`,
`@typeInfo(X).metaAll(T) -> T[]`, and `Declared.meta(T)` in `@TypeInfo.all`'s answer. Comptime only
(280 (0)). `setMeta(key: string, value: string)` and `.meta.<decorator>.<key>` go.

Built (see § Done): the typed surface, its reads, the catalogue's and 370 (1)'s `@Expr<T>` fields. The
string form stands beside it until the last box: rakun's sites wait on `04-rakun/128` (decision 339),
and `Declared.meta` / `TypeInfo<T>.meta` stay `DeclaredMeta[]` fields until then (the typed reads are
calls the checker answers, so the two coexist).

- [x] `builtins.d.bp`: `setMeta(v)`, `addMeta` on `Decl`; `meta(T)`, `metaAll(T)` on `@typeInfo(X)` and
      on a `Declared<T>` entry, answered by the checker (`TypeInfo<T>`'s and `Declared<T>`'s `meta` fields
      keep the string form until the box below)
- [x] `run/meta_typed` — `#[entity("cities")]` sets `Entity(table: "cities")`, `meta(Entity)?.table ==
      "cities"`; two `#[index]` add two `Index`, `metaAll(Index).length == 2`; `meta(Other)` is `null`
- [x] `reject/meta_twice` — two `setMeta(Entity(…))` on one declaration, at the second (annotation)
- [x] a meta record may hold `@Expr<T>` fields (370 (1)): `decl.addMeta(Check(message: message, rule:
      rule))` built in the reading program with each expression spliced where it was written —
      `run/meta_expr_field` (the reader calls `rule` and evaluates `message` at run time, on the four
      targets)
- [ ] the std and library sites migrated (rakun's `#[entity]` and the stereotypes, jhonstart's `#[page]`
      and `#[client]`), then `setMeta(key, value)`, `.meta.<decorator>.<key>` and `DeclaredMeta(key,
      value)` gone (`Declared.meta` / `TypeInfo<T>.meta` the typed reads only)
- [ ] a meta field of a record type, a `Type.Field<T>` (364 (2)'s data family) or a tuple: refused
      today (`decorator-meta-field-type`); rebuilding one where the meta is read needs its names in the
      reader's scope (an `@Expr<T>` field carries such a value as written)
      — tuple and `Type.Field<T>` fields rebuilt where read, a generic meta record keyed by its parameter
      (`meta_field_tuple_and_field_key`); left: record-typed fields (the nested record aliased into the reader, as 385)
- [x] an `@Expr<T>` meta field read in another module resolves its names where the annotation wrote them
      (385): each module publishes its scope (`Reflection.scopes`, `comptime/written_names.zig`), and the
      reader binds every name the annotation's arguments wrote under an unspellable alias, a private one
      exported as `templatePrivateKey` (the annotation's module shares its privates, `pub` for the
      backends only); `typeinfo-meta-expr-elsewhere` gone — `modules/meta_expr_read_elsewhere` runs
      (`main` reads `signup`'s `Check` and calls its private `passwordsMatch`, its own `passwordsMatch`
      and `hint` not captured; the `@TypeInfo.all` route the same through `d.metaAll(Note)`, a non-generic
      record — a generic one through an entry is `130-s8-d`) on the four targets
- [x] a typed member reads its own type's typed meta (395): pre-comptime, `@typeInfo(T).metaAll(Check)` with `T`
      the decorator's type parameter accepted and typed `Check<T>[]` in the decorator's body, the body checked
      against it; post-comptime, the member rendered into the annotated type's module with `T` spelled as the
      type, the read answered and the member checked again; `comptime @typeInfo(X).metaAll(T)` is the checker's
      answer (no comptime runtime), `for (comptime …)` parses — `run/member_reads_own_meta` (`#[validated]` over
      two `#[check]`s: `validate()` runs both rules, the list a build constant under `comptime`) on the four
      targets; `typeinfo-unknown-declaration` no longer raised for a bound type parameter
- [x] questions `130-s8-a` → 418, `130-s8-c` → 419, `130-s8-d` → 420 (`130-s8-b` → 385, `130-s8-e` → 395): one type set and added, a `.hooks` reader's typed meta read in its module, a generic record through a
      catalogue entry

#### Step 10 — a template body reads the program's catalogue (decision 353) (was `130-decorator-outputs` s10)

A library's template function calls `@TypeInfo.all(with: …)` and gets the catalogue of the program
that expands the call — `styled` finds the application's one `#[theme]` (119 step 1 box 5).

```bp
// styled/src/styled.bp, inside `pub default fn styled(comptime css: @Expr<string>)`
val themes = @TypeInfo.all(with: theme);   // the application's #[theme] declarations
if (themes.length > 1) css.fail("styled: two #[theme] declarations: …");
```

- [x] a decorator on a `val` runs (356): `DeclKind.Val`, `name`, `returnType` as written; `setMeta`
      legal, `addMember` / `addType` refused at the annotation; the `val` catalogued —
      `reject/val_decorator_runs` (`#[mark] pub val one = 1;` fails with the decorator's message; a
      refusal is target-independent, so a `reject/` cell) and `run/val_decorator_catalogue`
- [x] `@TypeInfo.all` in a template function's body answers for the calling program, after every
      module's decorators; the reader is exempt from `typeinfo-all-imported` (256's entry-point
      rule unchanged for every other reader)
- [ ] a `Declared`'s `value` readable at build: a `val` with a `comptime` initializer lifted into the
      template's module as a literal (356), refused at the read otherwise
      (`typeinfo-all-template-value`); a comptime `extendTheme(…)` holding `ThemeValue.Rem(…)`
      evaluates (row 133)
      — strings, numbers, `bool`, `null` and arrays / tuples of them read at build (`template_reads_val_build_value`,
      `template_val_value_not_comptime`); left: record and variant values (row 133, the template-body gap of `language-gaps.md`)
- [x] the importer of a reader module that breaks the rule gets `typeinfo-all-imported` at the
      import, not `unbound variable '<template>'` at the use (row 134's diagnostic half)
- [x] `run/template_reads_program_catalogue` (one and two built as `modules/template_reads_program_catalogue`, `modules/template_catalogue_two_themes`; none still answers an empty catalogue — 358's refusal open) — a package's template function counting the importing
      application's `#[theme]` declarations: none (refused, 358), one, two (refused at the second, naming both)

**Gate:** standard (fronts.md § Gate) + std on commonJS and erlang; each library's hook

#### B-19 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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
- [x] `x!`: `null` aborts with `value is null — <expr> at <file>:<line>:<col>` — built (`?? @panic(…)`,
      `run/optional_bang_aborts`); commonJS prints the text, erlang and beam abort with it as an Erlang binary
      (the `—` makes it non-latin1), wasm aborts without it: one text on the four targets is the backends'
      panic printing (02, 03, 05)
- [x] `?T` has no methods: `.map`, `.flatMap`, `.unwrapOr` on a `?T` are `unknown method` naming `?.` / `??`; on
      `@Result` they stay; `result.map(…)` and the rest of the namespace are unbound names. A method after a
      `?.` link continues its chain (`e?.key.length()`), as TypeScript's does
- [x] a migration script (`scripts/codemod-optional-operators.py`, as 129's) rewrites `.unwrapOr(d)` on a `?T` to
      `?? d` and `result.<op>(r, …)` to `r.<op>(…)` in every tree — one commit per repository, before the
      refusals land. Built and run over botopink-lang (std, the five shared libraries, the language suite,
      `examples/`); the five library repositories' migrations are prepared, one per repository
- [x] a `type` declared in a type's body is that type's associated type (the `decl.addType` node, 216):
      `pub type Type { pub type Field<T>(…) { … } }` reads `Type.Field<T>` (308); `reject/` cells for a nested
      type named like a member
- [x] `docs.md` § Operators and § Optionals (07's prose) list the five operators and the five rules
- [x] wasm: `?.()` over a function answering a plain value is refused (`run/optional_call_operator`'s
      `.wasm.expect`) — the answer has to be boxed (05)
- [x] erlang, beam, wasm: `recv?.m()` over an absent receiver — `s?.length()` raises `badarg` on erlang and
      beam and answers `8` on wasm (the backends' `?.` method lowering; a method continuing a `?.member` chain
      is right on the four)
- [x] erlang: `a ?? ns.f()` with a package-module namespace call as the default (std's own
      `os.tmpdir()`) lowers as a method call on `ns`; std reads it into a `val` first

#### B-20 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell of
      `tests/language` (`conformance/` once B-29 step H lands) on every target it declares; a red reproduced locally,
      fixed at once (430), pushed again; no cell edited to match the compiler
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named
      — the suite green on `feat` locally (1939 cells); B-20's own red fixed: `recv?.m()` over a record's or an enum's
      method guarded on wasm and commonJS (`optional_enum_method_absent_receiver`, `optional_record_method_absent_receiver`,
      two hook tests); five cells added; no `test` run green since the base — 18 cancelled by the next push, the one
      finished red at format-check on B-27's `bpp_*` cells. Box 1 closes on the next completed green `test` run.

| B-20 change | Cells |
|---|---|
| `?.[i]`, `?.(args)`, postfix `!` | `optional_operators`, `optional_call_operator`, `optional_bang_aborts`, `optional_bang_in_lambda` |
| an operator over a never-null value refused; `??` beside `&&` / `||` | `optional_operator_never_null`, `nullish_never_null`, `bang_never_null`, `nullish_beside_logical` |
| `?T` has no methods; a method continues a `?.` chain | `optional_has_no_methods`, `option_expect_removed`, `result_namespace_removed`, `optional_chain_method`, `optional_chain_record_fields` |
| wasm `?.()` answering a plain value | `optional_call_plain_answers`, `nullish_optional_call_default` |
| `recv?.m()` over an absent receiver | `optional_method_absent_receiver`, `optional_enum_method_call`, `optional_enum_method_absent_receiver`, `optional_record_method_absent_receiver` |
| `a ?? ns.f()`; wasm `f64` function values; an `if` with a `null` arm | `nullish_default_namespace_call`, `optional_float_function_value`, `fn_value_float_argument`, `optional_if_null_initializer` |

- [ ] `val t: Sort<Book> = Sort(by: .title)`: a field key under an annotation is refused where `Sort<Book>(by: .title)`
      resolves — found by B-19
- [ ] wasm: `std_decorator_leaf_import`, `std_decorator_through_namespace`, `std_decorator_unknown_through_handle` red on
      `feat` — "`canonical` has no wasm external" at std's `testing/asserts.bp` — found by B-19
- [ ] wasm: `pub fn main() {}`, a module nothing calls and a dependency: `compilation failed UndefinedCall` — found by B-27
- [ ] a field read after a `?.` call link (`p(true)?.me().x`) is refused while a method there is accepted
      (`find(0)?.str().length()`); TypeScript continues the chain for both — one rule — found by B-20's Conformance step

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

- [x] `fn(x: T, …) -> R { … }` typed where it stands — a `val` / `var`, an argument, a return, `decl.addMember`;
      written types checked against the position's when it has one — `run/fn_expr_typed_anywhere`,
      `reject/fn_expr_typed_mismatch`
- [x] `fn-expr-typed` and `reject/fn_expr_typed` deleted; `docs.md` § Lambdas and § Decorators rewritten; the
      braced lambda still untyped (328)

#### Step 38 — a body's last expression without `;` is its value (decision 409) (was `01-checker` s38)

```bp
fn inc(x: i32) -> i32 { x + 1 }
fn sign(n: i32) -> i32 { if (n < 0) return -1; n }
val inc = fn(x: i32) -> i32 { x + 1 };
fn bad(x: i32) -> i32 { "a" }           // ❌ expected i32, got string — at "a"
fn semi(x: i32) -> i32 { x + 1; }       // ❌ as today: the body falls off its end
```

- [x] the parser keeps a body's last expression statement written without `;` as the tail (`ast` flag), in a named
      `fn`, a method, a `fn` expression and a lambda; a braced `if` / `case` / loop at the end stays a statement (16)
- [x] the checker types the tail against `-> R` (`stmtsMayFallThrough` answers `false` after it); a non-`void` tail in
      a body answering nothing refused at it — `run/fn_tail_value`, `run/method_tail_value`,
      `run/fn_expr_tail_value`, `reject/fn_tail_type_mismatch`, `reject/fn_tail_in_void`
- [x] every backend returns the tail (erlang the last expression, commonJS a `return`, wasm the block value) —
      the four targets
- [x] measured first: the bodies in std, `tests/language` and the libraries whose last line has no `;` today,
      the count in this README; `docs.md` § Functions, § Lambdas — no named `fn`, method or `fn`-expression body
      ends without `;`; lambda bodies do: std 180, `conformance/` 207, examples 5; emilia 373, erika 79, jhonstart
      288, onze 372, rakun 1855, actions 12, http 7, log 20, routing 13, validation 389, css 3, styled 55, markdown 20
- [ ] a lambda's (and an untyped `fn(x) { … }`'s) last expression written with `;`: still its value as today, or a
      statement as 409 reads, with the codemod the counts above measure · question B-21-a
- [ ] a non-`void` tail in a method with no `->` that infers its return from its `return`s (06 C9): refused only when
      no valued `return` exists, as built · question B-21-b
- [ ] an `implement` method still needs `;` on every statement: the printer drops its `-> R` — found by B-21

#### Step 11 — a body's tail printed as written (decision 409) (was `16-formatter` s11)

- [x] a body's last expression without `;` (`fn inc(x: i32) -> i32 { x + 1 }`) prints without it, one written with
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
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named
      — the suite green on `feat` locally but for `fn_value_float_argument`'s stale wasm departure (B-20's); eleven
      cells added, red on the base; no `test` run completed since the base — each cancelled by the next push. Box 1
      closes on the next completed green `test` run.

| B-21 change | Cells |
|---|---|
| 408: a typed `fn` expression in a val / var / argument / return, a record field, an array | `fn_expr_typed_anywhere`, `fn_expr_typed_in_record_field` |
| 408: written types checked against the position | `fn_expr_typed_mismatch`, `fn_expr_typed_field_mismatch` |
| 408: a `decl.addMember` member; beam's closure | `decorator_member_fn_tail`, `lambda_last_statement_semicolon` |
| 409: a named fn's, a method's, a `fn` expression's, a lambda's tail | `fn_tail_value`, `method_tail_value`, `fn_expr_tail_value`, `fn_expr_tail_semicolon` |
| 409: a tail after a loop's return, an `if` chain, a `case` arm block, at comptime, under `@Result` | `fn_tail_after_loop_return`, `fn_tail_if_else_chain`, `fn_tail_case_arm_block`, `fn_tail_comptime`, `fn_tail_result` |
| 409: the tail checked; a value in a body answering nothing; a void tail | `fn_tail_type_mismatch`, `fn_tail_in_void`, `method_tail_in_void`, `fn_tail_void_call` |
| the formatter's tail | no cell: `format/tests/declarations.zig` |

- [ ] the formatter adds `;` to a `case` arm block's last expression (409 covers function bodies) · question B-21-c

### B-22 — The backends' and the checker's residue rows

**Repository:** botopink-lang (`--lang`)

Each row re-measured at the step that takes it. The `throw` in a `case` arm (01 s6, 04 s6, 12 s2) lands as one
cell on four targets.

**Impacted tests:** `run/throw_in_case_arm_result`, `run/val_*_pattern`, one cell per row. **Model:** sonnet for
a backend row with its repro, opus for a checker row. **Consumer commits:** none (std's workarounds in 97's
§ Compiler residuals go in the landing).

#### Open (was `01-checker` open)

Steps 6, 10, 13 all touch `infer.zig`/`parser/**`: one commit per step, serial.

#### Step 6 — `throw` in a `case` arm under `@Result` (box 3) (was `01-checker` s6)

Checker keeps the fn's fallible channel in an arm's block; erlang, wasm, beam answer `Error` on the
`throw` path, commonJS refuses at codegen (`JumpInValuePosition`, `04-js` step 6). Cell lands with 04.

- [x] `run/throw_in_case_arm_result` — `return case v { Num(n) -> g(n); _ -> throw "x"; }` under
      `-> @Result<i32, string>`: `isError()` true on the throw path, four targets

#### Step 6 — `throw` in a `case` arm (after `01-checker` step 6) (was `04-js` s6)

Typed AST marks the arm's `throw` as the enclosing function's (today `JumpInValuePosition` at
codegen); the arm emits `return {Error: e}`.

- [x] `run/throw_in_case_arm_result` green on commonJS; `isError()` true on the throw path

#### Step 2 — the owner rule for the area fronts' cells (box 1) (was `12-language-tests` s2)

Owner rule: `../README.md` § Rules (`tests/language/AGENTS.md` § Who adds a cell). Every listed cell
exists at feat but one (`run/array_unique` landed with `02-erlang` step 4 and `05-wasm` step 1,
green on four targets):

| Cell | Front | Row |
|---|---|---|
| `run/throw_in_case_arm_result` | `01-checker` step 6 (`04-js` step 6) | row 29 |

- [x] `run/throw_in_case_arm_result` exists at the close and passes on every target it declares

**Gate:** standard (fronts.md § Gate) + `tests/language/AGENTS.md` updated in the same commit as any
cell or owner-row change

#### Step 13 — JS-4's two checker gaps (was `01-checker` s13)

`val [..rest] = xs;` binds `rest`; irrefutable `val Pair(Circle(r), n) = p;` accepted. Checker half
works (refusal lifted, commonJS/beam answer); erlang binds a lone spread (`Rest = Xs`,
`run/list_pattern_spread_alone`); wasm refuses nested (`05-wasm` row). Re-measure erlang's nested
constructor; keep the nested refusal until wasm lowers it. Contract: `../03-beam/pattern-binding.md`.

- [x] `run/val_spread_only_list_pattern` prints `rest`'s length; `run/val_nested_ctor_pattern`
      prints `r` and `n` — four targets

#### Step 1 — the checker's two binding shapes on beam (box 3) (was `03-beam` s1)

Lowering in (`emitPatternDestruct`); with the checker refusal lifted beam prints `val Pair(Circle(r),
n) = p` as `3 4`, nested one-variant enums as `7 x 9`, `val [..rest] = [1, 2, 3]`'s length as `3`.

- [x] `run/val_nested_ctor_pattern` and `run/val_spread_only_list_pattern` (`01-checker` step 13)
      pass on beam

**Gate:** standard (fronts.md § Gate) + `scripts/beam_export_audit.sh` assembles every module before
and after each step · every re-recorded RUN LOG verified by running (`erlc +from_asm` + `erl`)

#### Rows found by other fronts — part (was `02-erlang` rows box 1)

- [x] the same `@block` reassignment with a `return` in the block, or in value position: every
      `return` answers `{V, Group}` and the call site rebinds the group (`valueBlockExpr`;
      `run/block_value_reassigns_enclosing_var`, a `for`'s `return` in `tests/erlang.zig`; bugs-sweep)

- [x] std module's module-level `var` lowers to `std@beam` on erlang, not imported by the module
      (from `05-wasm` step 5; re-measure)

#### Rows found by other fronts (was `04-js` rows)

- [x] module with a module-level `val` initialised by a call (`val t = "a b".split(" ")`) fails a
      commonJS build with a bare `TypeError` when any of its functions calls `Float.floor` (from
      `05-wasm` step 5, comptime path; re-measure, name the owner)
- [x] `Point(x: 0, ..)` in a `case` answers `null` on commonJS (from `02-erlang`; re-measure)
- [x] an `@block` whose `return` is valued on some paths and that falls through to a tail on
      another checks: `val a = @block { if (c) return 3; 4 };` answers `null` on commonJS on the
      fall-through path and `4` (the tail) on erlang, beam and wasm — decision 2 gives that path no
      value, so the checker refuses it (owner `01-checker`; found by step 1)
- [x] `return` inside an `@block` in value position leaves the enclosing function on beam and wasm:
      `pub fn main() { val b = @block { return 5; }; @print(b); @print(7); }` prints nothing there,
      `5` and `7` on commonJS and erlang (C1: the block owns its `return`s; owners `03-beam`,
      `05-wasm`; found by step 1)
- [x] `??` lowering defeats the self-tail-call loop: `a ?? b` lowers to an IIFE
      (`(() => { const __bp_nullish = a; if (__bp_nullish != null) … })()`) whose body reads the
      function's parameters, so `NameScan` (`commonJS.zig`, closure_only) counts a closure capture and
      the `while (true)` rewrite is refused. std `path.bp` `resolveAll(segments, i, state)`
      (`val seg = segments.at(i) ?? "";` then `return resolveAll(segments, i + 1, next);`) recursed in a
      loop before 330's migration (`.unwrapOr("")` lowered to `((_o) => …)(arg)`, its argument outside
      the arrow) and now recurses one JS frame per segment — stack depth on deep inputs (found by
      checker-330's integration; snapshot `std_package_a_root_module_importing_from_io_is_refused_at_the_item`)
      — an immediately invoked plain arrow or `function` is scanned in the caller's zone
      (`NameScan.immediateBody`); `resolveAll` / `applyPieces` loop again, the two snapshots re-recorded
      (bugs-sweep)

#### Rows found by other fronts (was `05-wasm` rows)

Each re-measured at the step that takes it; a holding row traps or is refused by name.

- [x] `Array.range` / `Array.repeat` recurse per element through a spread (`primitives.bp`), O(n²)
      memory — `Array.repeat(0, 128)` exhausts the page; bodies double an array instead (std's file;
      limits table's open row)
- [x] from `01-checker`: element read of a union array (`run/array_literal_union_elements`), program-declared
      `default fn` of a primitive (`test/program_primitive_behavior_extends_std`, green on four targets), `?.b` on
      an absent element (`es.at(3)?.a ?? 0` prints `0` on wasm)
- [ ] union of primitives a `case` produces (`test/case_value_union`) prints an address on wasm: the wasm backend
      has no inferred type for a case value whose arms bind — a design pass of its own
- [ ] `case_value_union`'s representation on wasm: each arm boxed as a union array element (150, 8 §11) · question B-22-c
- [ ] a bare name inside a multi-subject arm (`Shape.Square(side), m -> …`) binds, against `docs.md`'s "a name alone is not a
      pattern" · question B-22-d
- [x] nested constructor in a `val` binding (`val Pair(Circle(r), n) = p;`) refused on wasm —
      `01-checker` step 13's `run/val_nested_ctor_pattern` needs it lowered (each binding off its
      field's slot, as the one-level form)
- [x] function read from a generic record's field, called through an untyped local, prints its
      pointer (`Box<T>(value: T)`; `modules/typeinfo_all_registration` uses a typed local — from
      `130-decorator-outputs`)
- [x] `@print` of a generic record prints a field typed by a type parameter as a word:
      `Q(items: [7])` over `Q<T>(items: Array<T>)` prints `Q(items: 308)`, `B(v: "s")` prints
      `B(v: 292)` at exit 0 (one descriptor per declaration, not per instantiation) — found by step 5
- [x] a primitive `default fn` from `primitives.bp` reached on wasm (`"1.5".parseFloat()`) is refused: its
      location is the caller's line now; left, the lowering — `stringSlice0` / `stringSlice1`, `stringIsDigits`,
      `stringToInteger`, `stringToFloat` and `stringNumeralRefused` have no wasm binding and need std-wasm functions,
      one answering a `@Result` — found by step 5
- [x] commonJS prints a generic record as `Box.t(…)` (`@print(Box(value: 1))` over `Box<T>(value: T)`) — found by
      B-14; one cell on the four targets
- [x] a `case` arm with a catch-all binder over a record value is lowered wrongly on commonJS and wasm — found by
      B-14; re-measured with its cell
- [ ] a value of an enum section (`val t = Token.Color.White; @print(t)`): commonJS, erlang and beam print
      `Token.Color(_inner: __Token__Color.White)`, wasm an address · question B-22-b
- [x] an imported enum's variant with a payload prints as a number on wasm (`@print(AMode.Slow(2))` printed
      `8764`, `AMode` from another module) — found by B-23
- [x] `test/expr_sugar.bp`'s pipes red on erlang and beam on `feat` (three cases; red on the base too) — found by
      B-22
- [x] a bare name as a catch-all arm (`k -> k + 1`) is accepted by the checker, which `docs.md` says is not a
      pattern; commonJS then fails `k is not defined` — refused at the arm, located — found by B-22
- [ ] `Float.toString` differs across targets: `9007199254740992.0` against `9.007199254740992e15`, `1200.0` against
      `1.2e3` on commonJS — one text on every target (decision 441, with B-78) — found by B-22
- [x] wasm: calling an `f64`-taking function bound out of an optional (`if (h) { g -> g(3.0) }`,
      `halver(true)?.(3.0)`) refused "would narrow this `f64` value to an `i32` slot" — found by B-20
- [x] wasm: `val n: ?i32 = if (c) 3 else null` reads as `0` when absent (`n ?? -1` prints `0`) — found by B-20

#### Compiler residuals — met here, worked around in std, owned elsewhere (was `97-std-dedupe` compiler residuals)

| # | What | Reproduction | Owner |
|---|---|---|---|
| 1 | commonJS emits `Ok(x)` / `Error(e)` of a `primitives.bp` `default fn` as written — `ReferenceError: Ok is not defined` | `return Ok(1);` in a new `default fn` of `behavior String`, called from a scratch project (`Ok`/`Error` are never constructors, 208/303: re-measure with `return 1;` / `throw e`) | commonJS emitter |
| 2 | same body: commonJS emits `self.length()` as written (`self.length is not a function`); erlang emits `opt.unwrapOr(d)` as undefined `unwrapOr/2` | `val x = self.split(".").at(0).unwrapOr("");` / `self.length()` there | both emitters |
| 3 | erlang lowers a method on a LOCAL of such a body through a lookup another module's text changes: `exponent.startsWith("+")` → bare `startsWith(Exponent, <<"+">>)`, `function startsWith/2 undefined` | `parseFloat`'s first body + the three code-point index tests appended to `test/primitives_test.bp` | erlang emitter |
| 4 | a TYPE imported from a sibling (`import {RetryPolicy} from "reliability/policy"`) resolves to std's same-named type when the module also imports the std module declaring it (`import {async} from "std"`): `` `RetryPolicy` has no parameter named `initialMs` `` | dependency with `reliability/policy.bp` (`pub type RetryPolicy(initialMs: i32, …)`) and `reliability/dispatch.bp` importing it beside `{async}` | `01-compiler/01-checker` (import fix covers functions) |
| 5 | no record built through a std namespace: `async.RetryPolicy(3, 100, 2.0, 1000)` is `this "std" module has no such public function`; leaf import works | `import {async} from "std";` + that call | `01-compiler/01-checker` |
| 6 | consumer outside the checkout cannot import `io/random` on commonJS: `module 'std/io/random' requires "./sidecars/random.mjs", but its library 'std' resolves to no package directory` | `import {io.random} from "std"` in a package under `/tmp` | **unowned**; proposed `01-compiler/26-cli-tooling` (bundled-package resolution) |
| 7 | `nextDelay(policy, 1).unwrapOr(0)` is `type mismatch: expected i32, got i64` — a literal widens to `i64` as argument and field, not as `unwrapOr`'s default | that expression | `01-compiler/01-checker` |
| 8 | erlang `[[1, 2], [3]].join("+")` prints bytes `\x01\x02+\x03` (element taken as iolist); beam prints `[1,2]+[3]` | that expression | `01-compiler/02-erlang` (`primJoin`'s template) |
| 10 | beam lowers an or-pattern of enum variants to no test: `case f { C \| D -> true; _ -> false }` answers `false` for `C` on beam, `true` on the other three (`unicode.normalize` writes one arm per form) | `type Form { A, B, C, D }` and that `case` over `Form.C` | `01-compiler/03-beam` |
| 11 | the embedded std registry carries no module visibility: `mod unicode_tables;` (private in `root.bp`) is importable by a consumer, `import {unicode_tables} from "std"` | that import from a scratch package | `01-compiler/26-cli-tooling` (`build.zig`'s registry) |

Residual 4 breaks nothing today (no rakun module naming `RetryPolicy` imports `std/async`); a rakun
step meets it if it imports both before deleting its copy.

#### B-22 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

- [x] an integer literal past its type's range refused on every target (decision 319): `refuseBeyondJsSafeInteger`
      (`comptime/infer.zig`) deleted, its 247 citation with it; `run/wide_literal_past_js_safe_integer` answers
      the value on the four targets (after `04-js` step 9)
- [x] `language-gaps.md`'s rows "`f32` has no literal" and "An `i64` has no literal" lose their
      literal half
- [ ] a cold gate green over the literal's change — B-23's Conformance step runs it (`feat`'s pipeline with
      conformance)

#### Step 19 — a type application before a member (decision 255 (1)) — built (`6185db3c`, on feat through `49455602`) (was `01-checker` s19)

`Dict<string, unknown>.empty()`: a type name with explicit type arguments followed by `.` or `(` is a
type application (1.0.10 decision 8 §1.3 extended to a type's member); elsewhere `<` is a comparison.
The list goes to the chain's first link (`receiverTypeArgs`); the checker binds the type's parameters
(`applyReceiverTypeArgs`). Built: `run/type_application_static_member` on four targets,
`reject/type_application_{argument_mismatch,argument_count,variant_payload_mismatch,on_a_field}`,
`botopink format` round-trip (`parser/tests/decision255.zig`, `format.zig` `typeArgsDoc`), `docs.md`
§ Generics.

- [x] a type application through a module namespace (`collections.Dict<K, V>.empty()` — the head is a
      value's name, so the list is a comparison there): built, or refused with a located message

#### Rows other fronts found — part (was `01-checker` rows boxes 1, 3, 4)

- [x] comptime body diagnostic names the body's file: `infer.zig` (`decoratorError`) passes the
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
      then the refusal is a `language-gaps.md` row) — its own work: a type's identity by module throughout the checker
      and the four backends, which name a type by its declared name alone today; whether a type of this
      module beside an aliased import of a same-named type counts is question B-23-a
- [x] `@External.Wasm` binding read on every target: checker walk over `external_variants` with
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

### B-24 — 319, 320, 332: numbers and strings exact everywhere

**Repository:** botopink-lang, with consumer commits in rakun, jhonstart, onze (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

`bigint`'s rest (139 landed as bigint-139; its two open boxes) then `Decimal` and `Json`'s numbers. Questions `decision 496`, `decision 497`,
`decision 500` (whether 142 s1 goes first and the `Int` / `BigInt` / `Dec` arms land in the json repository).

**Impacted tests:** `run/json_numbers_exact`, `run/i64_*`, the clock cells. **Model:** sonnet, opus for 139's
checker half. **Consumer commits:** rakun (3 files), jhonstart (2), onze (2) — the `Json` `case` arms.

#### Open (was `139-bigint` open)

- [ ] decision 501's alternatives, if the maintainer answers (b) or (c): `is bigint` by value range, a
      `bigint` in `unknown`, compile-time `bigint` in the folder and the comptime runtimes (14 · 18)
- [ ] wasm: a `bigint` member of a union (`lowerAsUnknown` refuses it located, "has no `bigint` in a
      union yet"; erlang, beam and commonJS run it) — a `05-wasm` row

**Gate:** standard (fronts.md § Gate) + `zig build test-language` (the four targets) and
`scripts/tsc-check.sh`.

#### Step 9 — `i64`, `u64`, `isize`, `usize`: a number, a `BigInt` past 2^53 (decision 319) (was `04-js` s9)

Today these four lower to JS numbers and 264's check bounds them at ±(2^53−1)
(`ArithKind.rangeExactDouble`): `9007199254740991l + 1l` aborts on commonJS and answers on the other
three targets. After, they keep the full range at a low cost: a value within ±(2^53−1) stays a JS
`number`, a value beyond it is a `BigInt`, always in that canonical form.

```js
function i64add(a, b) {
  if (typeof a === "number" && typeof b === "number") {
    const r = a + b;
    if (Number.isSafeInteger(r)) return r;        // the common case: today's cost
  }
  return norm(BigInt(a) + BigInt(b));             // promoted; checked against ±2^63, back to number when it fits
}
```

- [x] lowering: every operation on the four types (`+ - * / %`, unary `-`, the compound assignments,
      comparisons) through a prelude helper with the number fast path; the slow path computes in
      `BigInt`, aborts past −2^63 … 2^63 − 1 / 0 … 2^64 − 1 (`__bp_int`), and answers the canonical form;
      a literal is a number when safe, else `123…n`; `rangeExactDouble` deleted
- [ ] canonical form kept by every producer (operations, literals, conversions, `Json`, host templates)
      — operations and literals done; `Json` waits on 332 (`139`, then `02/97` step 15's `Json` integer); std's `Math.min`/`max`/`abs` cells and
      `Integer`'s `default fn`s (`isEven`, `clamp`) throw a `TypeError` on a `BigInt` (97 step 13):
      `==` stays `===`, a `Dict` / `Set` keyed by `i64` keys by value — one cell each across the 2^53 edge
- [ ] conversions explicit and exact (no `toF64()` / `toI32()` is declared anywhere yet — std surface first):
      widening `i32 → i64` is free (already canonical); `@print` and string interpolation print the digits
      (no `n`)
- [x] a Node host template taking or answering one of the four types sees `number | bigint` (canonical);
      the emitted `.d.ts` types them `number | bigint`; `scripts/tsc-check.sh` green
- [x] cost measured: a loop of i64 additions below 2^53 within 10% of today's `int_check` build (the
      number recorded in `js/AGENTS.md`)
- [x] `run/i64_full_range` (`9007199254740991l + 1l`, `9223372036854775807l`, `-9223372036854775808l`, the
      `u64` top, a value crossing back below 2^53, an overflow past each bound) answers alike on the four
      targets; `run/int_overflow_mul_i64` re-recorded — commonJS now aborts where the others do
      — the minimum is written `-9223372036854775807l - 1l` (the checker refuses
      `-9223372036854775808l`: the literal's digits are past `i64`, a `01-checker` row); the `u64` half is
      `run/int_overflow_add_u64_max`, red on wasm only (prints the top as `-1`, traps on
      `18446744073709551614ul + 1ul`; a `05-wasm` row)
- [ ] `docs.md` § Integer overflow's commonJS paragraph rewritten (handed to `07-residuals`, owner of the prose)

#### Step 13 — std over the hybrid `i64` on commonJS (decision 319; with `04-js` step 9) (was `97-std-dedupe` s13)

- [ ] `io/clock`'s `formatIso8601`, `toCivil` and `offsetMinutes` given an epoch past ECMAScript's
      time range (every `BigInt` epoch): question `decision 497`; `parseDuration`'s 2^53 − 1 bound after
      319: `decision 498`; `fs.stat`'s `mtime` resolution (ms on Node, s × 1000 on erlang): `decision 499`
- [ ] `Json`: an `i64` written as its digits (the read half is step 15's `Int` node, 332)
      (`9223372036854775807l` round-trips on commonJS through `Int`)
- [x] `string.parseInt()` answers `Error` only past the `i64` range (176 as amended by 319):
      `run/string_parse_int_i64_range` on commonJS, erlang and beam; wasm's half is `05-wasm`'s
      (`stringSlice0/2` unresolved, pinned by `.wasm.expect`)
- [x] `min` / `max` / `abs` / `clamp` and `Integer`'s `isEven` / `isOdd` answer past 2^53 on commonJS
      (the numeric tower is patched on `BigInt.prototype` too — a carve-out in `04-js`'s
      `commonJS.zig` `prototypeAssign`; std's Node forms take either kind):
      `run/i64_number_methods_past_js_safe`; wasm refuses an `i64` receiver (`05-wasm` row);
      `abs` of the minimum is question `decision 496`
- [x] the explicit conversions `toI32()`, `toI64()`, `toU32()`, `toU64()`, `toF64()` declared on
      `Integer`, aborting when the value does not fit, never rounding: `run/integer_conversions_exact`,
      `run/integer_conversion_to_i32_aborts`, `run/integer_conversion_to_f64_inexact_aborts` on
      commonJS, erlang and beam; wasm has no row for them (`05-wasm`, pinned by `.wasm.expect`)

#### Step 14 — erlang counts codepoints, not grapheme clusters (decision 320) (was `97-std-dedupe` s14)

`primitives.bp`'s Erlang templates for `length`, `at`, `slice`, `indexOf`, `lastIndexOf` call
`string:length/1` / `string:slice/3`, which count grapheme clusters: `"e\u{301}".length` is 1 on erlang
and beam, 2 on wasm.

- [x] the five templates count codepoints (`unicode:characters_to_list/1`, re-encoded with
      `unicode:characters_to_binary/1`; the slice helpers normalise bounds as the Node forms do), on
      erlang and beam; `02-erlang` step 15's cell green there; `libs/std/AGENTS.md` § One unit
- [ ] std's Node templates for the five take and answer codepoint indices (`04-js` step 10's helpers)
- [ ] `docs.md` § Strings states the unit — codepoints on every target — handed to `07-residuals` (the prose)

#### Step 15 — `Decimal` and `Json`'s numbers as Jackson reads them (decision 332; after `01-compiler/139`) (was `97-std-dedupe` s15)

- [ ] `Decimal` in std (`math/decimal.bp` or the module the front names): an unscaled `bigint` and a
      `scale`; `add`, `sub`, `mul` exact; `div(b, scale:, rounding:)` with `Rounding { Up, Down, Ceiling,
      Floor, HalfUp, HalfDown, HalfEven, Unnecessary }` (Java's `RoundingMode`; `Unnecessary` aborts when
      rounding is needed); `compare`; `==` by numeric value (`1.0 == 1.00`); `toString()` plain with its
      scale (`"1.00"`, never `1E+2`); `parse(text) -> @Result<Decimal, string>`
- [ ] `Json`: `Num(value: f64)` replaced by `Int(value: i64)`, `BigInt(value: bigint)`, `Dec(value: Decimal)`,
      chosen by the numeral; readers `num() -> ?f64`, `i64() -> ?i64`, `bigint() -> ?bigint`,
      `decimal() -> ?Decimal`, `isNumber()`, `isIntegral()` (exact or `null`, never coerced); `encode` writes
      the digits and the plain decimal text; std's tests `decodesTo("9007199254740993", Int(value: 9007199254740993))`
- [ ] `json.parse` and `json.stringify` deleted with their Node / Erlang templates (336); their one caller (`tests/language/run/std_json_on_every_target.bp`)
      rewritten to `decode` / `encode`; `json` compiles on wasm under both hosts with no host cell
- [ ] the 13 files with a `case` over `Json` (std 6, rakun 3, jhonstart 2, onze 2) gain the arms, one commit per
      repository; `run/json_numbers_exact` one `.out` for the four targets

#### B-24 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-25 — 333 (B), 334, 335: the wasm host

**Repository:** botopink-lang, with consumer commits in log (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

After B-00e (std-wasm in the wasm output may absorb some `wasi:` bindings these steps write). Questions
`decision 502`, `decision 504`, `decision 505`, `decision 503`. Unblocks log 106 s3 (the wasm column; G4: a wasm binding cannot reach the
file system, cannot keep a value across calls; the wasm backend does not lower a context).

**Impacted tests:** `run/wasm_host_*`, `run/std_io_http_on_every_target`, `run/std_async_on_every_target`,
`run/wasm_library_binding`. **Model:** opus. **Consumer commits:** log (its two wasm markers).

#### Step 4 — `@Task` on `wasi` (was `140-wasm-host` s4)

- [ ] `@Component` bodies (375's mark) as state machines — decision 504 (recommended: every `@Component` a
      state machine on wasm); today they stay eager and an `await` of a task there runs the ready tasks,
      trapping on both hosts when the task still waits on the host
- [ ] `fetch`'s `Request` / `Response` in the compiler's layout (393), with `wasi:http` (`io/http`, `02/97`
      step 17)
- [x] `async_block_all_of` gains the wasm column (`.targets` widened) — waits on std's `async` bindings
      (`02/97` step 17: `std/async` is refused on wasm for want of `delay`, `race`, `raceOf`)

#### Step 5 — the cells (was `140-wasm-host` s5)

Waits on `02/97` step 17 (`io/http`'s and `async`'s wasm bindings).

- [ ] `run/wasm_host_http` (a request to a local HTTP double, its status and body) under wasmtime; the
      commonJS and erlang answers equal
- [x] `05-wasm`'s `wat/AGENTS.md` § Where this backend refuses to answer loses `io/http` and `async`

#### Step 6 — the `browser` profile (with 3–5, never after) (was `140-wasm-host` s6)

- [ ] `fetch`'s JavaScript implementation in the loader (394), with `io/http`
- [ ] parity: std's check refuses a cell bound on one host only (std's, `02/97` step 17); `test-libs` runs
      the wasm column on both hosts once `botopink test` runs wasm (335 (3)) — `test-language`'s does (§ Done)

**Gate:** standard (fronts.md § Gate) + `zig build test-language` with wasmtime's component support and
`zig build test-libs` (std's wasm column).

#### Step 17 — `io/http` and `async` bound to the `wasi` host (decision 334; after `01-compiler/140` steps 1–4) (was `97-std-dedupe` s17)

- [ ] `io/http`'s `fetch` binds `@External.Wasm(host: .Wasi, wasi: .HttpOutgoing)` and the `browser` host's JS `fetch`;
      the request and response mapped by each adapter; on `browser` a forbidden header or a `Set-Cookie` read answers
      `HttpError.NotAllowedOnHost(…)` naming it (335 (1)); `run/std_io_http_on_every_target` against a local double
- [x] `async`'s twelve cells bind on `wasi` (`delay` on the monotonic clock, `race` / `raceOf` on pollables, the
      gate cells as pollables) and on `browser` (the same adapters, 394), through 392's scheduler; `RetryPolicy` / `nextDelay` unchanged;
      `run/std_async_on_every_target` asserts results and answer order only — never effect interleaving (335 (2))
- [ ] the `browser` bindings of both modules in the same commit (334: a cell bound on both hosts or neither) — `async` bound on both hosts; `io/http` waits on question B-25-b

#### Step 9 — a prebuilt wasm library merged into the module (decision 333 (B); no user yet, after step 5) (was `05-wasm` s9)

- [ ] `@External.Wasm(module: .<Library>, fn: "<export>")` — a fourth form beside `op:`, `fn:`, `wasi:` (238); the
      library named from the package's wasm manifest (version, hash); an unknown library, a missing export or a
      signature with a type that cannot cross is a located error at the annotation
- [ ] the glue generated per binding: `string` copied in as UTF-8 through the library's allocator export, the
      answer read back and freed; numbers and `bool` passed as values; `?T` of them as the library's null
      convention named in the manifest; no pointer reaches botopink code
- [ ] the merge: the library's functions, memory and data folded into the emitted module (the binary emitter is
      front 18's — a named carve-out), one `.wasm` out; `wasmtime` and the WAT comptime runtime run it
- [ ] `run/wasm_library_binding`: a test fixture library (a small `.wasm` built for the cell — a string and a number
      across) called from wasm and from commonJS, one answer; the size the merge adds recorded in `wat/AGENTS.md`

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified under wasmtime and
compared with commonJS's · no new RUN LOG answers at exit 0 a value another backend answers
differently · `RUNTIME TRAP` fixtures re-read: still impossible on wasm, or fixed

#### Step 11 — the same wasm library from commonJS (decision 333 (B); after `05-wasm` step 9) (was `04-js` s11)

- [ ] a binding with `@External.Wasm(module: …)` and no `@External.Node` lowers on commonJS to the same
      library: the module instantiates the package's `.wasm` once (synchronously, from its bytes beside the
      emitted `.js`) and calls it through the same glue
- [ ] the emitted package ships the `.wasm` next to its `.js`; `tsc-check.sh` green; `run/wasm_library_binding`
      one answer on commonJS and wasm

- [ ] the adapter names `.GateNew` / `.GateOpen` / `.GateAwait`, and std's test-only cells (`monoMillis`, `hostTarget`, the
      counters) left unbound on wasm until `botopink test` runs wasm (335 (3)) · question B-25-a
- [ ] `fetch`'s surface: `Request`, `HttpError` and the migration from `fetch(url)` · question B-25-b
- [ ] log's two markers: a wasm adapter keeping one host value per name, `wasi:filesystem` · question B-25-c
- [x] wasm: `async.retry(policy, { -> … })` refused — nothing at the call binds the type parameters `retry`'s body
      needs (the lambda's answer type not read) — found by B-25 — bound from the argument's answer type (`generic_thunk_result_binds`)
- [x] beam: a tuple holding a function value fails `invalid_store` (`val p = #(g, 2); p.0("abc")`) — found by B-21's
      Conformance step
- [x] wasm: in `#(g, h)`, calling a string-answering `h` prints a number — found by B-21's Conformance step
- [x] wasm: `op.run(5).toString()` on a function-typed field inside `for (ops) { op -> … }`: "cannot resolve the call
      `toString/0`" — found by B-21's Conformance step
- [x] a type implementing a behavior imported from another module does not adopt the behavior's instance `default fn`s
      (`Sq(n: 3).twice()` is "'twice' is not declared in any behavior implemented for 'Sq'") — found by B-19
      — adopted, extended behaviors included (`behavior_default_adopted_across_modules`); a generic behavior's not yet
- [x] wasm: the explicit conversions (`pause.toI32()`) have no wasm lowering, so `async.retry` still stops there — found by B-25
- [ ] Step 9's manifest key, the library's ABI (a position-independent side module, as std-wasm, or a standalone module)
      and the glue (strings in and out, freeing, `?T`'s null) · question B-25-d
- [ ] erlang: DebugAllocator reports a leak in `erlang.zig`'s `closeTypeUnit` under `cell check` — found by B-25

#### B-25 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

### B-27 — Tooling, std residue, `.bpp` in the toolchain, `json` out of std

**Repository:** botopink-lang, with consumer commits in jhonstart and the `json` consumers (through 151) (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

116's botopink-lang half (the vscode-extension box is 161's) with 01-checker step 22's prelude scope;
26 s9; std purity (23) and effects by return (24 — 24-a answered by 431, 24-b by 432; 24-c, 24-g open); std's
snapshot message (135 s1); 97's residues; 98's script and its `docs/botopink-json.md` lines; 142 s1's std half
(the json front, 151, carries the consumers). Questions `116-a/b/c`, `23-b`, `std-c`, `24-c`, `24-g`, `decision 506`,
`decision 507`.

**Impacted tests:** `tests/language/modules/bpp_*`, compiler-cli, language-server, lib-test-runner;
`tests/cli_contract.sh`; `scripts/check-packaging.sh`; `test-libs`. **Model:** opus for 116, sonnet for the rest.
**Consumer commits:** jhonstart (`#[bpp.html]` with 26 s0), the six `json` consumers through 151.

#### Step 0 — Measure what the unfold stands on (was `116-bpp-file-format` s0)

- [ ] `tests/language/modules/` cell: a package's `pub default fn` over `comptime template:
      @Expr<string>`, imported `import t from "<package>";`, called with a literal from a consumer,
      on every target the language suite runs
- [ ] decision 199's header rule over every `.bpp` under `specs/1.0.12-beta/*/*/examples/`: each
      header item listed as declaration (`import`, `type`, `pub`) or statement (`val`, `use`);
      every unnamed item (`if`, expression statement, private `fn`, `test`, decorated
      declaration) listed with its file
- [ ] a module hand-assembled as the unfold would: a header-line type error and one inside the
      literal each reported at the `.bpp` line

#### Step 2 — The unfold (was `116-bpp-file-format` s2)

- [ ] the return type is read from the default function's signature (decision 275): the fixture
      package's `@ExprCustom<i32>` gives `-> i32`; jhonstart's gives `-> @Component<Element>`
      for a header with and without `use` / `await`; the toolchain spells no type name
- [ ] `tests/language/modules/bpp_*`: fixture package whose default function is **not**
      jhonstart's (answers the literal's length) — `.bpp` with `type Props` unfolds to
      `pub default fn (props: Props)`, without to `pub default fn ()`, no header = all
      literal; fixture served unchanged (proof the toolchain knows no library)
- [ ] the file's grammar (212, 338): the header from the first line to the first separator line;
      `---` → markup to the end of the file; `--- style ---` → style section closed by `---`, then
      markup; no separator line → markup only (a markup-only file compiles)
- [ ] a first line `---` refused at line 1: `error: the header starts on the first line; a .bpp has
      no opening ---`
- [ ] each refused at its line: a `--- style ---` after the markup; a second style section; an
      unclosed style section (at its `--- style ---` line)
- [ ] the style section unfolds to `use <style> """<the section>""";` after the header's
      statements, before `return html """…""";`, with `import <style> from "<bpp.style>";` binding
      no name the header can reach — § Mechanism's `Props(title)` example unfolds as spelled there
- [ ] fixture style package (not `jhonstart-styled`) whose default function answers something
      trivial (the section's length): a `.bpp` with a style section compiles onto it unchanged —
      the toolchain knows no library for the style section either
- [ ] a diagnostic inside the style section reported at its `.bpp` line, like the markup's
- [ ] the default function anonymous (289): `import {components.PostCard};` binds `PostCard` in the
      importer, an alias another name; a file name that is no identifier (`not-found.bpp`) unfolds;
      `decl.name` is the file name; `page.bpp` whose header imports and writes `#[page(…)]` compiles
- [ ] declarations at module level, statements in the body in order; a statement reads `props`
- [ ] a decorator on the header's last line, before the separator line, annotates the function
      (221 (1)); without one the function carries none — no decorator from the file name, no
      `bppKinds` read (285)
- [ ] `X.bp` beside `X.bpp`, and `.bpp` with no key — each refused with § Mechanism's message
- [ ] prelude (270): fixture with `prelude.bp` — markup-only `.bpp` compiles; module and emitted
      code import only used items; header name beats prelude's; `prelude.bp` holding a `fn`, another
      package's item or an activation refused at its line. The scope (`compiler-core`: last scope, import-item list) is
      `01-compiler/01-checker`'s, handed by this front
- [ ] `grep -riE 'rakun|jhonstart|erika|emilia|onze'` over `modules/compiler-core/src` and the
      edited `compiler-cli` files is empty

#### Step 3 — The extension in every tool's list (was `116-bpp-file-format` s3)

- [ ] every § Mechanism site reads one shared list instead of spelling `.bp`
- [ ] `botopink build`, `check`, `run`, `test` over a `.bpp` project; test runner discovers a
      `test` declared in a header
- [ ] `mod x;` resolves `x.bp`, then `x.bpp`, then `x/mod.bp`

#### Step 4 — The span mapping and the editor — part (was `116-bpp-file-format` s4 boxes 1, 2)

- [ ] header-line type error and a `failAt` in the markup reported at their `.bpp` line and
      column by `botopink check` and the language server
- [ ] hover, go-to-definition in the header; default function's overlay served as the markup's
      tokens — the extension ships no grammar of the file

#### Step 5 — The formatter (was `116-bpp-file-format` s5)

- [ ] `botopink format` rewrites a badly indented header as a module, leaves every byte of the style
      section and the markup unchanged; `format --check` fails on the header, passes the style
      section and the markup
- [ ] `scripts/format-check.sh` walks `.bpp` files — header under the gate's format stage like any `.bp`

#### Gate additions (was `116-bpp-file-format` gate)

**Gate:** standard (fronts.md § Gate), in `repository/botopink-lang` and `repository/vscode-extension`, plus:
- [ ] `zig build test-libs`: every library green — no existing `.bp` file changes meaning
- [ ] `docs.md` § Modules documents `.bpp`, every fence compiled by `zig build test-docs`

#### Step 22 — the prelude scope (decision 270) (was `01-checker` s22)

`compiler-core` takes, with a module, a list of import items (`element.Element`,
`elements.article`, aliases allowed) as the module's **last scope**: only for names the module does
not bind (declared or imported names never reach it). An item becomes an ordinary import (`import
{elements.article} from "<package>"`) in the transformed program and emitted code **only when a
name resolves through it**; unused items emit nothing. Names no library — `08-bpp/116` hands it
`prelude.bp` items for a `.bpp` file and owns the `.bpp` refusals (non-`import` `prelude.bp` line,
item of another package, an activation, default function's name bound by the header).

- [ ] `comptime/tests` fixture: module handed `[element.Element, elements.article]` naming only
      `article` — transformed program imports `elements.article`, not `Element`; a self-declared
      name resolves to its own declaration; nothing in `src/` names a library
- [ ] `src/comptime/AGENTS.md` states the scope order

#### Step 9 — a dependency's sidecars and imports answer as its own build does (was `26-cli-tooling` s9)

- [ ] a transitive dependency's sidecar ships: a project outside the rakun workspace depending on a
      member by `path` failed `build` with "`rakun_actuator` / `rakun_probes` is not a sidecar of
      this project" — `libs.sidecarOwner` asked only the project's direct `dependencies`, then the
      roots by name; it now walks the closure the build resolved (`closureOwner`) ·
      `tests/cli_contract.sh` "a dependency of a path dependency", `libs.zig` unit test
- [ ] a dependency's module importing a package it does not declare is decision 242's located
      `unresolved import source` (at the dependency's file), not `unbound variable` —
      `libs.loadOne` runs `resolver.checkSources` against the dependency's own manifest ·
      `modules/dependency_imports_undeclared_package`, four targets

**Gate:** standard (fronts.md § Gate) + `zig build test-cli`, `test-bpmp`, `test-vscode` green;
language-server tests green with new snapshots · `zig build test-libs` at baseline (rakun's members
exercise every sidecar path)

#### Rows other fronts found (was `26-cli-tooling` rows)

- [ ] `botopink check` / `build` print a type error's message and box but not its hint: the
      `PersistentTerm` write (`infer.zig`'s hint names `#[@BeamMemory.Ets]`) and
      `std-unsupported-on-target` carry one and the terminal shows none; a parse error's
      `= hint:` line prints (measured by `07` step 6; `docs.md` § `@BeamMemory` cites the hint)

#### Step 1 — the gate's rows (was `23-std-purity` s1)

`zig build test-language` green on four targets with the import cells (`modules/import_alias_on_type`,
`import_std_type_through_module`, `import_std_folder_namespace`, `import_type_closure*`,
`import_type_alias`); language-server tests with the `project_graph.zig` cells (one `lsp/` snapshot
per import spelling).

- [ ] `run.sh --target all` green on the `modules/import_*` cells — measured, the box ticked
- [ ] `grep -l 'import {' modules/language-server/snapshots/lsp/*.snap.md` lists one snapshot per spelling (dotted, grouped, `*`, `as`, a folder leaf); missing ones added
- [ ] the five `AGENTS.md` name the tree and the grammar; `docs.md` § imports / § std verified against the grammar (07 places any correction)

#### Step 2 — the confirmations (was `23-std-purity` s2)

23-b (`base64` retired) and std-c (namespace rewrite): each confirmed or reversed; a reversal opens a
step in the owner (01 for std-c). 23-c is confirmed (317).

- [ ] the three ids in `../../decisions-taken.md` with their numbers, or a reversal's step named —
      23-c confirmed (317); 23-b and std-c open

#### Step 1 — every guide fence compiles as one program (E3, decision 134) (was `24-effects-by-return` s1)

`botopink check` over `guide.md`, jhonstart as path dependency: ✓ fences type, ✗ sites answer their
code located; § 7's server action types against rakun's `serverAction` once shipped (stubs until
then, named as stubs in the report). E3's three checker rows landed in 01
(`run/try_catch_null_and_noreturn_narrowing`, `run/component_call_renders`).

- [ ] `scripts/check-docs.sh` runs the guide as one program and is green
- [ ] § 7 against the real `serverAction`, or the stub named with the rakun front that replaces it

#### Step 2 — the confirmations (was `24-effects-by-return` s2)

24-a (effect codes), 24-b (`@Task`'s `map` / `then`), 24-c (prefixed loop's label), 24-g
(`std/async`'s shape) confirmed or reversed; 24-h answered (decision 179, replaced by 432).

- [ ] the four ids in `../../decisions-taken.md`; a reversal's step named in the owning front — 24-a → 431 (checked `@Result`; 24-b → 432, the failing task;
      `throws: true` and `attempt` are `01-checker` step 42 and `02/97` step 18)

#### Step 3 — the cost of a `@Result` per item (was `24-effects-by-return` s3)

`@Iterator<@Result<T, E>>` of 10⁵ items consumed by `for` with `try r`, on erlang and wasm, vs the
same loop over `@Iterator<T>`; if the `Ok` wrap weighs, the backend specialises the `Ok` `yield` — a
row for 02 and 05, not edited here.

- [ ] the two ratios in this README with the program and the machine; a row filed in 02 / 05 if either exceeds 1.5×

#### Step 1 — `json` leaves std — part (was `142-data-formats` s1 boxes 1, 2)

- [ ] `libs/std/src/json.bp` moves whole to `repository/json` (history kept as 138 did): the `Json` type
      and its methods, `parse`, `decode`, `stringify`, `quote`, `unquote`, `array`, `object`, the host
      cells and their tests; std's `root.bp` loses `pub mod json;`; `grep -rn "json" libs/std/src` names
      no module (comments aside)
- [ ] `import {json} from "std"` is an unknown-module error naming the `json` library

#### Step 1 — std (390) (was `20-snap` s1)

- [ ] `mocks.verify`'s message pinned with `throwsWith` on both targets (§ 1, CONVERT)
- [ ] `libs/std/AGENTS.md`: the inline literals and the four `__snapshots__/` path-rule files are the evidence

#### Step 4 residue — the engine under every `-test` member (was `97-std-dedupe` s4 residue)

- [ ] `zig build test-libs` reads every member's row at its previous count (the last recorded whole run, 138's gate: 125 passed) — read on the next cold gate. Measured for std and the seven `-test` members: `std`, `emilia-test`, `erika-test`, `jhonstart-test`, `onze-test` pass on commonJS and erlang, `jhonstart-dom-test` on commonJS, `rakun-test` on erlang, `rakun-starter-test` compiles (no tests); 12 passed, 0 failed, 1 without tests, 3 restrictions audited

#### Step 6 — conditional on `decision 506`: `io.process` signals and a line reader (was `97-std-dedupe` s6)

(a): `process.onSignal`, `process.forwardSignals(child)`, `io.stdin.readLine()`. (b), recommended:
onze 50's boxes take their (b) shape.

- [ ] under (a): a spawned child receives the `SIGTERM` sent to its parent, asserted on both
      targets with a child that prints on the signal; `readLine` answers a line without its newline
- [ ] under (b): `libs/std/AGENTS.md` states std has no signal or TTY surface and why

#### Gate additions (was `97-std-dedupe` gate)

**Gate:** standard (fronts.md § Gate) + `botopink test` and `botopink test --target erlang` green in
`libs/std`, `libs/actions`, `libs/validation`
- [ ] steps 0–5, 8–10 landed before this gate was recorded: one cold `zig build test` and a full
      `zig build test-libs` on feat with them in, recorded here

#### Step 2 — the packaging check, as a script (was `98-packaging-tail` s2)

`repository/botopink-lang/scripts/check-packaging.sh`: § Mechanism's four checks over
`repository/*`, non-zero exit naming each failing path. Calling it from `gate.sh` is the gate's call.

- [ ] main checkout after the library steps land: exit 0; one README removed: exit 1 naming it; one
      `-test` member emptied: exit 1 naming it
- [ ] `docs/botopink-json.md` § Examples states the README and helper rules, links the script

#### Step 3 — front 95 closed as a confirmation (was `98-packaging-tail` s3)

Under `decision 507` (1): one `repository/onze` entry in `.gitmodules`, workspace `onze`, eight members with
`files`, listed by `zig build test-libs`; `mocking-lib-final` already resolves. Only the
`docs/botopink-json.md` line to write.

- [ ] `git -C repository/onze rev-parse mocking-lib-final` resolves; `git submodule status
      repository/onze` is the orchestrator's commit; `docs/botopink-json.md` says in one line the
      orchestrator repository carries the mocking library as tagged history

#### B-27 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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

- [x] the command removed: its dispatch in `compiler-cli/src/main.zig`, `cli/migrate.zig`, its tests, its rows in
      `compiler-cli/AGENTS.md` and `cli/AGENTS.md`, and every doc that names it; `botopink migrate` answers the CLI's
      unknown-command error
- [ ] Conformance step (459, 474, 477, 478, 480)

### B-60 — the code cache, level B: a dependency's analysis on disk in `.botopinkbuild/analysis/` (decision 509 (1); the maintainer, 2026-10-12)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

Level B skips analysing an unchanged library (~0.8 s a cell on emilia's `alpha`; ~15–20 s of ~164 s warm over
emilia's 79 cells with `--jobs`). **The maintainer's choice:** each dependency's analysis — its checked interface
(types, exports), its decorators' meta and its generated code per target — is written to the project's
`.botopinkbuild/analysis/` (beside 483's `.botopinkbuild/deps/`; a workspace's members share its root's) under the
dependency's closure key, and read back by later invocations, a restart and a CI job that keeps the directory
included. **One entry per dependency and target** (std's per module): an entry for a new key replaces the
dependency's previous one, so nothing is stored twice and the directory needs no size bound; switching back to an
older version analyses it again. `.botopinkbuild/` is never tracked by git; a CI job keeps it between runs keyed by
the lockfile and the compiler's version. Not taken: nothing; sharing within one invocation only; a warm server holding it in memory. Safe by the
closure invariant (B-65, B-66): a library's analysis and code are the same under every consumer.

**What guards against a wrong answer** (the risk of a disk format is that it forgets a field, or falls behind the
checker, and answers a wrong program silently):

1. **The key** is 509 (3)'s closure key — the package's files by content, its dependencies' keys (Merkle), the
   target, the compiler's backend partition — **and the hash of the checker's and the format's own sources**: any
   change to what an entry holds, or how, gives every entry a new key; no version number to remember.
2. **`test-analysis-equivalence`** in `test-cli`: for libraries and consumers (jhonstart, rakun, emilia and
   `closure_invariant.sh`'s), the output built with `--cold` and the output built reading `.botopinkbuild/analysis/`
   compared byte for byte on every target — a field the format forgets fails the gate.
3. **Doubt discards:** an entry that does not read back whole (truncated, a checksum that differs, a key it does not
   carry) is deleted and the dependency analysed again — never used in part. Writes are atomic (a temporary file
   renamed), so parallel invocations and `--jobs` workers never read half an entry.
4. **Entries are immutable;** what a consumer instantiates (a generic, a `comptime`, a template expansion) stays in the
   consumer's own code, never in a dependency's entry.
5. **Never cached:** the package under test (509 (1)) and a test's result (510).
6. **Starting from nothing is `botopink cache clean`** (B-77); the group's Conformance step measures after it (cold)
   and again (warm) and compares.

**The design** (confirmed by the maintainer, 2026-10-12). A consumer reads more than an interface: each dependency
module's whole analysed output (`ComptimeOutput.ok`) and what its analysis and `registerExports` leave in the session
— the five registries (types, type declarations, templates, decorators, extensions), the default DSL and the
reflection catalogue (the decorators' meta). The entry stores exactly that and is decoded back into the same
in-memory structures, so the checker and the four emitters read what they read today.

- **An entry** (`<name>.bpa`): one file per package and target, a hit only when every module of the package hits;
  std one file per module. Sections: META (package, module paths in order, wasm host, whether a module reads the
  catalogue, each module's std imports), STRINGS, then per module ANALYSIS (the analysed output without
  `bindings[].typedExpr` and `custom_ast`: the transformed AST with bodies, bindings with their types, `type_ids`,
  `dispatch_rewrites`, `instance_lowerings`, warnings, …), JOURNAL (what the module added to or replaced in the
  registries, the default DSL and the catalogue, replayed in order on load) and CODE (the module's own unit on the
  target; on commonJS the `.d.ts` always). The AST is stored because the checker receives templates, decorators and
  carried `pub fn`s with their bodies, and wasm links its dependencies' bodies.
- **What a consumer instantiates** (generics, `comptime` calls, template expansions, per-callee templates, wasm's
  lowering of linked bodies) is never in an entry: the entry holds the AST, the result exists only in the
  consumer's code (guard 4). The entry is encoded right after the dependency's analysis, before codegen rewrites a
  `declare fn` in place.
- **The encoding:** binary, generic over the Zig types (`@typeInfo`): every field of every type is written unless
  named in a short skip list, so a new field is never forgotten silently; maps by sorted key, so the bytes are
  deterministic; pointers through an identity table, so shared nodes and type variables stay shared. A header
  (magic, the key, the payload's length and SHA-256, a section table); no version number. The encoder and decoder
  live in `compiler-core/src`, inside the compiler key; wherever they sit, the key hashes their files.
- **The directory:** `<workspace root>/.botopinkbuild/analysis/<target>/<package>.bpa` and
  `…/<target>/std/<module>.bpa` (`io@fs.bpa` for `std/io/fs`); `wasm` and `wasm.browser` are separate targets, so a
  cell running both hosts never thrashes. Two packages of one name in the workspace's closure (two members, or a
  member and a dependency) are a located error, never one entry silently replacing the other.
- **The key:** 509 (3)'s closure key, which now also hashes the effective manifest (after 512's inheritance) and the
  wasm host; std's is the module path, the target, the host and the compiler key (std's bytes are inside it).
- **Never stored:** a package with a module that reads `@TypeInfo.all` or expands a template that queries the
  catalogue — its answer depends on the whole program.
- **Before B-64:** `botopink test` reads a dependency's analysis from the entry and emits its code again (dependencies
  are still emitted in test mode); `build`, `run` and `cell check` read the code too.
- **Readers:** `build`, `run`, `test`, `cell check` and `check`; the language server not until B-74.
- **`binds_erlang_host`** (`crossModule.Scopes`) is computed from the module's closure, not the whole program, and
  the case joins `test-closure-invariant`.
- **Later, after the measurement:** dropping from erlang, beam and commonJS entries the bodies no registry carries.

- [x] the invariant's test: `zig build test-closure-invariant` (`closure_invariant.sh`) builds one library under two
      consumers and compares its output byte for byte on every target; green since B-65 and B-66
- [x] the test joins `test-cli`
- [x] the design reported before it is built and confirmed by the maintainer (above)
- [x] S0 — the key (effective manifest, wasm host, std's keys; the format's files hashed wherever they sit), the paths,
      the header, the atomic replace, discard on doubt, `clean`, the duplicate package name as a located error; unit
      tests; no change of behaviour
- [x] S1 — the generic encoder and decoder; a round trip, and emitting from the decoded outputs equal to emitting from
      the live ones, over std and the invariant's fixture; the entries' sizes reported; no change of behaviour
- [x] S2 — the journal and the hit / miss hooks in `compileOnce`; std per module, every other package per package;
      `build`, `run`, `test`, `cell check` and `check` read them; the catalogue readers never stored; guards 3–6
      (the duplicate-name cell is in)
- [x] `binds_erlang_host` from the closure, and the case in `test-closure-invariant`
- [x] S4 — the code section, and the four emitters skip a dependency module whose code the entry holds (`test` emits
      it again until B-64)
- [x] the review of S0–S4: a hit is a dependency's module alone, never one of the package under test at the same
      path; an entry for another module set is a miss; the entry carries no source text
- [x] decisions 514, 515: `check`, `test` and `cell check` keep a dependency's `.d.bp` modules as `build` and `run`
      do — one module set, one entry; `check` of `local_dependency` green (its dependency's `.d.bp` declares `Rect`)
- [x] `botopink test` reads and writes level B CODE as `build` does, now that B-64 landed; a test unit never stored
- [x] `test-analysis-equivalence` in `test-cli` over jhonstart, rakun and emilia (cold, writing, reading; byte for byte)
- [x] `test-analysis-equivalence` in `test-cli` (guard 2), red on a format that drops a field (a test that drops one
      on purpose)
- [x] tests the hook runs: an unchanged library is not analysed again across invocations; a changed file (by
      content), a changed checker source or another target analyses it again; a truncated entry is discarded
- [ ] measured (B-61's quiet machine): emilia's conformance and one cell repeated, cold and warm, without and with
      level B; the directory's size
- [ ] Conformance step (459, 474, 477, 478, 480)
- [ ] under the module-model group (B-71, B-72) an entry becomes a block's; noted there

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
