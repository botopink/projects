# Front 144 — machine 1: the checker and the language (lane A, the module-model group)

The steps of [front 144](../README.md) this machine runs: its goal, priority, ownership, order, lanes, the rules the two
machines share and the alias table are the front's README; each step below is as it was there, unchanged. The
other machine's steps are in [`../machine-2/144-backends-tooling/`](../../machine-2/144-backends-tooling/README.md). A step keeps its id (`B-NN`) wherever it sits.

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

- [x] `"std:…"` in a template refused on `.JavaScript` / `.Erlang` too, naming `.Wasm(std: …)` (847); `infer.zig`'s `std_` exemption goes;
      cell `external_std_prefix_refused_everywhere` (red on the parent, 305's folder) — landed (a case of 305's `refused` package; no site
      relied on the exemption)

### B-10 — 430: the compiler gaps a library works around today

**Repository:** botopink-lang, with consumer commits in validation, styled, emilia, jhonstart, onze (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

Decision 430: a gap a library front works around opens here, ahead of the steps that would build on the
workaround; the workaround is removed in the fix's landing (a consumer commit) and its `language-gaps.md` row
and Marker index row go (meta CI check 5). Groups by the library that carries the markers:

- **G1 validation** — `compiler.variants(d)` carries a variant's name and not its payload; a static member is not a
  value on erlang; a comptime decorator parameter takes no default; a decorator body whose lambda holds many
  locals overflows the comptime stack; a record spread inside a member a decorator adds loses its spread on
  commonJS; a decorator argument is a raw lexeme;
  `Field` reflects no default; two test modules declaring one type name share it on erlang; std's
  `clock.formatIso8601` answers differently on erlang and commonJS (`decision 497`); the package module namespace
  in type and value position (the box below).
- **G2 styled / emilia** — a method's behavior-typed parameter refuses an implementer; a wrapper's type alias
  cannot implement a behavior (answered by 850: an alias implements nothing, its `R` does); a template function cannot read another expansion's value; a function a
  template body reaches cannot name an enum variant nor build a private record; a decorator body cannot call a
  host function (closes with B-00c); a library's template function cannot read the program's catalogue (by design
  since 665: the application's `#[theme]` is read from the registry its `compiler.init` executor writes, styled's half
  in 150); an imported enum's variant written bare (erlang).
- **G3 jhonstart** — a decorator cannot read whether a `Component<R>` return's `R` implements `Renderable`;
  a tag annotation cannot be called by the template function (B-15); template-built code cannot build an inline
  props type; a type alias of `Component` in a return and a template answering `-> View` (re-measured after 388).
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
- [x] `compiler.variants(d) -> compiler.Variant[]` (name, fields, annotations, section) (848); the prelude mirror; cell
      `compiler_variants_typed_entries`; validation's two markers and their `language-gaps.md` rows in the consumer commit — landed with
      validation's consumer (its markers stay for 146 s3's box over `Variant.fields`; 848-a confirmed as built by 909, cell `compiler_variants_wrapper_entry_order`; `annotations` empty until the parser
      takes an annotation on a variant)
- [ ] `Field` reflects a field's default · question B-10-a
- [x] `clock.formatIso8601` always `.sssZ`: the erlang cell on `{unit, millisecond}` (849); cell `clock_iso8601_millis_always` on commonJS,
      erlang, beam — landed (red on the parent)
- [ ] handed to 146 (their compiler halves built): the comptime parameter default and the raw lexeme (125 s12, s7),
      `#[each("email")]` → `#[each(email)]` (125 s8)
- [ ] G2: the same for rakun-style's and rakun-stylesheet's markers — built: a method's behavior-typed parameter takes an
      implementer (`method_behavior_parameter_implementer`); a template-reached enum variant or private record no
      longer reproduces across a package. Left:
- [x] a bare variant in expression position (`Two(t)`) checks but fails on commonJS, erlang and beam · question B-10-d
- [x] an imported enum's variant by dot-shorthand, the enum not imported (reached through a signature): unbound
      `Mode` on commonJS and erlang (beam and wasm right) — the backends import a type the module reaches only
      through a signature
- [ ] handed to 150 s34: styled's `Sheet.add` half (an API change; `toStyled()` answers a component)
- [ ] waits elsewhere: a template reading another expansion's value (119's design), a decorator body calling a host
      function (B-00c); a library template reading the program's catalogue is overtaken by 665 (the registry read at run
      time, styled's half in 150)
- [ ] G3: the same for rakun-bpp's markers (after B-15 and 388) — built: template-built code builds an inline props
      type (`template_builds_inline_props`; rakun-bpp's two html test markers and the row gone). Left:
- [x] a decorator reads whether a `Component<R>` return's `R` implements `Renderable` — overtaken by 804 (2) (851); `client.bp`'s marker and
      its `language-gaps.md` rows go in 165 s10
- [ ] `html` declared `-> View` (`View = Component<Element>`, its tree through `compiler.custom`): every expansion fails `expected
      Component, got Element` — 852: an alias of `Component` in a return erased (`alias_erase.zig`'s kept position goes); cell
      `component_return_alias_erased` (red on the parent); `html`'s `-> View` answers `Component<Element>` once 809 (7) lands — no rule over `Element`
- [ ] G5: the same for rakun-ssr's content marker — no compiler change: decision 306 makes it a type decorator over
      `compiler.fields(decl)` (121 step 10), handed to 150 s70

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
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named
      — the suite green on `feat` locally; a namespace read only in a decorator argument was unbound — fixed, a unit test in
      `mod_namespace.zig`; one cell added (`decorator_argument_decorator_alias`). Box 1 closes on the next completed green
      `test` run.

| B-10 change | Cells |
|---|---|
| two modules declaring one type name stay two types | `two_modules_one_type_name`, `test/two_test_modules_one_type_name` |
| an associated fn named without a call is a value | `associated_fn_as_value` |
| a record update in an added member; many locals (pins) | `decorator_member_record_update`, `decorator_lambda_many_locals` |
| a method's behavior-typed parameter takes an implementer | `method_behavior_parameter_implementer` |
| a `Decorator` / `Decorator[]` parameter | `decorator_argument_decorator_name`, `decorator_argument_decorator_alias` |
| a dependency's module as a namespace | `package_module_namespace` |
| a leading-dot variant of an enum never named; template-built inline props | `dot_shorthand_enum_not_imported`, `template_builds_inline_props` |


### B-11 — 316: `decl.wrapWith(f)`

**Closed by decision 714:** `compiler.wrapWith` is removed — no library used it; behaviour around a function is a proxy type the decorator builds or a function around the call. The 13 `decorator_wrap*` / `*_wrap_with` cells and the `decorator-wrap-*` refusals go with B-139's codemod; nothing below is built further.

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

Nothing open here: the wrapper's two questions are overtaken by 714 — `compiler.wrapWith` is removed, behaviour
around a function is a proxy type the decorator builds or a function written around the call.

#### B-11 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After the group's other steps have landed on `feat`; it holds back no front that builds on them (479).

- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named
      — the suite green on `feat` locally but for three `std_decorator_*` wasm cells (B-27's, a B-22 row); four cells
      added; no `test` run green since the base (cancelled by the next push, or red at format-check on others' cells).

Nothing open here: the pipeline box is overtaken by 714 — `wrapWith` is removed and its cells go with B-139's codemod.

| B-11 change | Cells |
|---|---|
| `wrapWith`, composition, a method, an importer | `decorator_wraps_function` |
| a call in the same module, the function as a value, its recursive call | `decorator_wraps_function_value` |
| a wrapper reading a decorator body's local | `decorator_wrap_captures` |
| the lambda-only wrapper (B-11-a), generics refused (B-11-b) | `decorator_wrap_not_lambda`, `decorator_wrap_generic` |
| the wrong return, outside a function, `fn(..)` outside `@Decl` | `decorator_wrap_wrong_return`, `decorator_wrap_outside_function`, `decorator_any_params_outside_decl` |

- [x] proposed cells: a `declare fn` wrapped (`decorator-wrap-without-function`); a generic owner type
      — `decorator_wrap_declare_fn`, `decorator_wrap_generic_owner`

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
- [x] `..base` (decision 37) beside 359's `...src` · question B-14-a — closed: 37's update path is closed and `...` is refused (864)
- [ ] decision 715: every argument evaluated in the order written, the spread's source where it stands, once; a spread copies field values only, the record's methods its type's — `record_spread_evaluation_order` re-recorded, `record_spread_copies_values_only`
- [x] `Type.pick` / `omit` / `merge` of a `Type.partial` type, and `Type.required`: their lineage · decision 600, (b) as built; the two cells' comments renamed in B-140

#### B-14 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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
      — the suite green on `feat` locally (1999 cells); three B-14 defects fixed (an overridden label typed and evaluated,
      an untyped lambda parameter as a source, `?T` named as written), each with a unit test; eleven cells added. Box 1
      closes on the next completed green `test` run.

| B-14 change | Cells |
|---|---|
| `...src`, left to right, defaults, a generic record | `record_spread` |
| a derived type across modules, through an import alias | `record_spread_across_modules`, `record_spread_import_alias` |
| a spread nested; a call source evaluated once | `record_spread_nested`, `record_spread_call_source` |
| the evaluation order (B-14-b as built); an overridden label typed and evaluated | `record_spread_evaluation_order`, `record_spread_overridden_label_type` |
| `..base` beside `...src` (B-14-a as built) | `record_spread_beside_record_update` |
| other type, optional, a derived partial, `required` (B-14-c as built), a partial | `record_spread_other_type`, `record_spread_optional`, `record_spread_derived_partial`, `record_spread_required`, `record_spread_partial` |
| a missing field, a label twice, a positional argument, a plain call | `record_spread_missing_field`, `record_spread_label_twice`, `record_spread_positional_argument`, `call_spread` |

### B-15 — 302: a tag is a declaration handle

**Repository:** botopink-lang, with consumer commits in jhonstart (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `run/tag_decl_meta`. **Model:** opus. **Consumer commits:** jhonstart (`html.bp`'s marker
goes); unblocks jhonstart's 118 s4–s5 residue and 119.

#### Step 9 — a tag is a declaration handle (decision 302) (was `130-decorator-outputs` s9)

A template function hands each annotated tag to its annotations as a `@Decl` and reads back what
they recorded — the same function shape as a declaration's decorator, named by no library (113, 198).

- [x] `DeclKind` gains `Element`, `Component`; `Decl.component: ?Decl` (a component tag's function);
      a tag's static attributes readable (`decl.attr(name) -> ?string`)
- [x] `@Expr`/`@ExprCustom` capture: a template function constructs a tag's `@Decl`, calls an annotation
      with it (the `Decorator` of 268, `Decorator.same` for identity, 371), reads `meta(T)` / `metaAll(T)` (298)
- [x] on a tag `addMember`, `addType` refused at the call; `setMeta` of one type twice refused at the second
- [x] `run/tag_decl_meta` — an annotation recording `ClassName(names: ["a"])` on a `<div>` read back by the
      template function; the same annotation function also accepted on a declaration
- [ ] the template side's spelling moves to `compiler` (636, as overtaken by 576 (2) and 616): `compiler.tagDecl(kind:
      DeclKind, name: string, syntax attrs: unknown)` builds the handle, `compiler.annotate(syntax d: unknown, at: Span)`
      runs the annotation written at a span of the template's text — neither on a capture nor in a `template` namespace
- [ ] `compiler.meta(d, T)` on a decorator's own declaration handle (`syntax d: unknown`) is refused, so an annotation cannot read what an earlier
      one recorded on the same tag · question B-15-c
- [ ] `template.mapSpanToLoc` places a span of a one-line `"""…"""` literal two columns early (the capture has
      `multiline=false`) — found by B-15

#### B-15 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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
      — the suite green on `feat` locally (no red B-15's); six cells added, `docs.md` for B-15's four; `conformance/docs.md`
      § A tag is a `@Decl`. Box 1 closes on the next completed green `test` run.

| B-15 change | Cells |
|---|---|
| `tagDecl` / `annotate` / `metaAll` / `attr` / `component` | `tag_decl_meta`, `tag_decl_meta_read` |
| `tag-annotation-output` | `tag_annotation_add_member`, `tag_annotation_add_type`, `tag_annotation_string_meta` |
| `decorator-meta-twice` on a tag | `tag_annotation_meta_twice` |
| an annotation naming nothing / no decorator | `tag_annotation_unknown_name`, `tag_annotation_not_decorator` |
| `decl.meta(T)` inside an annotation (B-15-c) | `tag_annotation_reads_meta` |
| a type named like a `DeclKind` variant | `type_named_like_decl_kind` |

- [x] proposed cell: `@emit` on a tag (`tag-annotation-output`)
      — `tag_annotation_emit`

### B-16 — 280, 307, 308: typed decorator arguments' rest, derived types' rest, `compiler.Field<T>`

**Repository:** botopink-lang, with consumer commits in rakun, validation (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `run/field_key_runtime`, `examples/types.bp` on four targets, the seven 280 examples.
**Model:** opus. **Consumer commits:** rakun-data (`orm/entity.bp` to `compiler.Field<unknown>`); unblocks validation
125's residue, jhonstart 26 s13 (362), 118.

#### Step 24 — typed comptime decorator arguments, `syntax decl: T`, `Field<T>` (decision 280) (was `01-checker` s24)

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
      with step 35 (every argument a `syntax x: T`)
- [x] `@Decl<T>` in `builtins.d.bp`; `T` bound from the annotated declaration (type, field, function)
      when the signature uses it, through a pattern too (`@Decl<fn(e: E) -> unknown>`); `@Decl` =
      `@Decl<unknown>`; a declaration not matching the pattern refused at the annotation
      (`reject/decorator_decl_pattern_{mismatch,return}`)
- [ ] `Field<T>` — `compiler.Field<T>` in std's `types.bp`'s `Type` (the utilities) and `compiler.bp`'s `Field<T>` / `Info<T>` (624, 630) (decision 308), not `builtins.d.bp` — (`name`, the
      field's type); `.name` resolved against the expected `T`, a missing field refused at it; variadic
      `..fields: compiler.Field<T>[]` (267); `compiler.fields(d)` hands out `compiler.Field<unknown>` (576 (8)) — built
      but the last clause, which is B-140's (the record `compiler.Field<T>` in `compiler.bp`, 598, 624, 630)
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
      `derived-type-field-string` naming `.title`; an unknown field the `compiler.Field<T>` error at it; a field
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
- [x] `Type.keys(Recipe)` is `compiler.Field<Recipe>` (decision 308) — the same type, not a copy: not a record
      derivation, not answered
- [x] a `compiler.Field<T>` at run time: stored, passed, compared; `case key { .title -> … }` exhaustive over
      `T`'s fields (a field added to `T` makes a `case` without it an error); `key.name`, `Key.of(text) ->
      ?Key`, `Key.all()` in declaration order — `run/field_key_runtime` on the four targets
- [ ] `compiler.fields(d)` handing out `compiler.Field<unknown>` (576 (8)) — not part of this mechanism: B-140's box

#### Step 2 — declare the rest — part (was `134-builtins-declared` s2 boxes 1, 2, 3, 6)

Left: `?T`'s methods (`map`, `flatMap`, `unwrapOr`) and the builtin `result` namespace
(`result.map/then/unwrap/isOk/isError`), prose in `builtins.d.bp` — under 330 the first leave and the
second is deleted; `Type`'s namespace-type spelling (329), `compiler.Field<T>` and `Type.pick` / `Type.omit`.

- [x] the rest declared under 330: `?T` declares no method (its surface is `01-checker` step 31's operators) — the
      `?T` rows (`map`, `flatMap`, `unwrapOr`) leave `infer.zig` `inferResultOptionMethod`; the `result` namespace
      (`inferResultNamespaceCall`) is deleted, not declared; the prose in `builtins.d.bp` goes
- [x] std's `types.bp`'s `Type` (the utilities) and `compiler.bp`'s `Field<T>` / `Info<T>` (624, 630) spells `pub type Type { … }` — a namespace type, no field list and no value (329): `Type()`
      refused, a `self` function in its body refused
- [ ] the field record is `compiler.Field<T>` in `compiler.bp` (624, 630) — not an associated type of `Type`, no
      `.d.bp` record (575 (1); `decl_reflection_src` went with `Decl<T>`, 576 (7)), no run-time key (599): the record
      `compiler.fields(d)` hands out (576 (8)) is B-140's box; validation's `decorators.bp` (`Array<Field>`) and
      rakun-data's `orm/entity.bp` (`fn marked(f: Field, …)`) migrate to `compiler.Field<unknown>` as its consumer
      commits (rule 10)
- [x] a field key at run time — removed by decision 599 (no use outside the compiler's cells): `Type.keys`, `Field.of`, `Field.all`, the five `field_key_*` / `type_keys_*` cells and `docs.md`'s paragraph go in B-140; the build-time `.field` argument (280 example 6) stays
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
      `run/decl_hooks_type_args` (a field's annotations and the methods: decision 726)
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
      `.hooks` readers; the reading of "cannot follow" and of a host `Component` is decision 725
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
fn padAll(n: i32) -> StyledProperty { return styledProperty @`padding: --spacing(${n});`; }   // Any
fn agora() -> i64 { return clock.nowMs(); }                                                    // Run
fn campos(comptime t: anytype) -> string[] { return compiler.typeInfo(t).fields.map({ f -> f.name }); }   // Build
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

- [x] a stage follows declarations only (a method, a function value add nothing); a run body calling a comptime-`@Expr`
      function and reading the clock is build-and-run · decision 720 (a): only what is written at the call counts, a `syntax` argument of any origin
      type-checked once; a Run function reached through a value while the build executes is `run-in-build` at that call, located — cell `run_in_build_through_value`
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

- [x] a call of an `Any` function (376) whose arguments are known at build is known at build and computed
      by the comptime runtime — in a hole (`styled "${padAll(2)}"`, `padAll(ESPACO)`) and in a `val`'s
      initializer; a raise refused at the hole (14s8-c); `padAll(n)` with `n` a parameter stays at render —
      `run/hole_any_call_at_build`, `reject/hole_any_call_raises`
- [ ] every expression with build inputs and `Any` functions computed at build wherever it is written (380):
      a body's `val raio = ESPACO * 2 + 4;` emitted as `12`; no step or time budget — a raise an error at the
      expression (`reject/fold_raises_at_build`); `panic` / `throw` computed only under a written `comptime`
      (`run/fold_keeps_dead_panic`)
      — built and measured, not landed: it moves ~26 snapshots, breaks `component_call_*` and `context_sheet_registers`, and the comptime runtime answers some primitives wrongly (`1000.toI64()` raises `integer_overflow`) — after that row, questions B-17-e, B-17-f

#### Step 12 — a synchronous component is a plain `function` (decision 375; after `01-checker` step 23's `HookNode.async`) (was `04-js` s12)

`effectShape`'s `.component => .{ .is_async = true }` (1.0.10's 104 (6)) gives way to the node's mark:

```js
function Card(map, titulo) { … }                       // HookNode.async == false
async function Post(map) { … Card(map, "x") … await Comments(map) … }
```

- [ ] a `component fn` or hook whose node is synchronous emits `function` (a method, a lambda and a
      `default fn` alike); an asynchronous one `async function`; a call of a synchronous one emits no
      `await`, written or not; a call the checker cannot follow keeps the `await` — landed for a top-level function (`Emitter.fnShape`, `SyncMarks` from `OkData.sync_fns` /
      `sync_calls`, `useHookExpr`, the `.await_` arm); a method, a lambda and a `default fn` have no node and stay
      `async` (`04s12-a`)
      — methods done (`component_method_sync`: marked by their own body, a synchronous one an arrow called with no `await`); lambdas already were; `default fn` and enum methods left, and 04s12-a's redesign (type components, props as one record)
- [ ] the TypeScript typedef answers the value, not a `Promise`, for a synchronous one; `tsc-check.sh` green —
      built for a top-level function (`typescript.zig` `fnReturnType`)
- [ ] `run/component_sync_plain_function` (the emitted module holds `function Card(` and `async function
      Post(`) and every `run/context_*` / jhonstart and emilia cell green on commonJS; erlang, beam and wasm
      output unchanged
      — jhonstart's gate green with conformance; emilia's four beam cells (OTP "implementation limit") and rakun's `rakun-data` test and two workspace cells red the same on the compiler before B-17

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified under `node` against
decision 8 §7 · `zig build test-libs` commonJS cells at baseline (jhonstart, emilia, onze, erika)

#### Step 6 — contexts: `Component<R>`, `use provide` / `use context` (decision 354, replaces 269) (was `134-builtins-declared` s6)

```bp
import {context.createContext} from "std";

pub val themeContext = comptime createContext(Theme(mode: .Light));   // declares Theme's default (378, 379)

component fn App() -> Component<Element> {
    val dark = comptime createContext(Theme(mode: .Dark));
    use provide(dark);                                 // for everything App renders below it
    return <Page />;
}

component fn Button() -> Component<Element> {
    val theme = use context(themeContext);             // the nearest Theme above, else the default
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
- [x] every context declares its default, named by its value's type (378, 379): std's `context` module
      answers `createContext(value)`, `provide(ctx)`, `context(T)`, and `Context<T>()` goes; one module-level
      declaration per type (a second refused naming both), found through the catalogue; a read answers the
      nearest context of its type or the declared default on every target (`context-unbound` goes,
      `run/context_default`), a type with no declaration refused at the read (`reject/context_undeclared_type`);
      `comptime createContext(…)` refuses a run-time argument; the codemod over `tests/language` (20 cells),
      `styled`, jhonstart
      — `createContext(v)` / `provide(ctx)` / `context(T)` keyed by the type's name, one declaration per type, a default found
      in the reading module or an analysed one (B-17-g's narrow reading); 4 cells added, 3 removed, 22 rewritten; styled's
      and jhonstart's commits landed
- [x] dependency injection over contexts (416): `createContext(value, Behavior)` keys the context by the behavior,
      the value checked to implement it (`reject/context_behavior_not_implemented`); `use inject(T)` builds the record
      `T` from the context of each field's type — provided above, else the declared default, else the field's default,
      else an error at build naming the field (`reject/inject_field_undeclared`); a behavior refused
      (`reject/inject_behavior`) — `run/inject_record`, `run/inject_behavior_keyed`, `run/inject_test_root_fake`
      (a test's root providing a fake) on the four targets; `docs.md` § Contexts
      — `use inject(R)`, `createContext(value, Behavior)` (`inject_record`, `inject_behavior_keyed`, `inject_test_root_fake`,
      `inject_field_undeclared`, `inject_behavior`, `context_behavior_not_implemented`)
- [ ] a context read known at build (379 (6)): every `createContext` that can reach it of build and of one
      value, or none — computed from the hooks list from the roots; the reading function then `Any` with build
      arguments — `run/context_read_at_build` (`corDoTema()` a constant when `Theme` is never provided),
      `run/context_read_run_time` (a provide from `use request()` keeps it at run time)
      — waits on step 8's folding everywhere (decision 721; question B-17-f): a cell cannot tell a build value from a run one until then
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

- [x] the comptime runtime's primitives answer as the targets do (`1000.toI64()` raises `integer_overflow` at build) —
      found by B-17
      — `toI64`'s bounds were the cause (`comptime_primitives_at_build`); math's `op:`-only functions no longer fold (decision
      764); `@Result` methods refused at build
- [ ] rakun-stylesheet: four beam cells fail with OTP's "implementation limit"; rakun: two workspace cells red — older than B-17,
      found by its library gate run
- [ ] math's `op:`-only functions (`sqrt`, `floor`, `abs`, `trunc`, `minF`, `maxF`) given a `std:` cell each in std-wasm beside their opcode so they fold at build · decision 764 (a); cell `comptime_math_folds`; the six exports are machine 2's (164)
- [ ] `Context<T>(contextValue)` and a context lowered to its plain value at run time · question B-17-i
- [ ] contexts keyed by the type's declared name, so two same-named types of two packages share one key · decision 635
- [x] `@Result` methods (`unwrapOr` …) refused at build by the comptime runtime — found by B-17
      — run at build (`comptime_result_methods`)
- [x] `comptime createContext(0l)` fails: the `l` suffix reaches the comptime module — found by B-17
      — stripped where the comptime module is written, put back after (`comptime_wide_literal`)
- [x] `createContext(value, B)`'s implements check reads only the direct `implements` clause; a type implementing `B`
      through `extends` or an extension block is refused — found by B-17
      — the checker's one answer, `extends` included (`context_behavior_implemented_indirectly`)
- [ ] a type implementing `B` only through an extension block (`Sym implement B for T`) as a `B` value · question B-17-m
- [x] wasm: `map` / `flatMap` on a `@Result<i64>` at run time answers garbage — found by B-17
      — `result_i64_map_flat_map`
- [x] wasm: a behavior method named `find` called on a value read through a context answers `0` — found by B-17
      — the value's behavior method first (`context_behavior_method_find`)
- [x] at build, a function value passed as an argument (`r.flatMap(half)`) is unbound — found by B-17
      — `fun f/A` in the comptime module (`comptime_function_value_argument`)
- [ ] `use memo({ -> createContext(…) })`: std's `memo<T>(make: fn() -> T) -> Component<T>`, computed on the first render, kept per instance, never recomputed · decision 755 (a); an instance is the value one component call makes, one slot per `use memo` position (771); cells `context_provide_made_at_run_time`, `memo_computed_once_per_instance`
- [ ] `compiler.src()` in a decorator body answers the annotated declaration's location (718) — legal, never a route · decision 734 (a); cell `decorator_compiler_src_is_declaration_location`
- [ ] an optional function-typed `comptime` argument tested with `rule == null` as any `?T`; 411's `expr-value-of-function` gone · decision 735 (a); cell `comptime_optional_fn_tested_against_null` replaces `no_null_test_of_optional_fn_expr`
- [ ] `type<T>` in a `comptime` parameter's union, `source is type<T>` in the body (`comptime source: Atom<T> | type<T>`) · decision 736 (a); cell `comptime_value_or_type_union`
- [ ] a raise other than an arithmetic error while folding is a build error at the expression, the target's message (380 (2)) · decision 721 (a); after the runtime-exactness line above; cells `fold_raise_is_build_error` (index, conversion, missing key, a `panic` inside an `Any` function), `fold_dead_branch_panic_stays` (380 (3))
- [ ] what "Any" is foldable for 380 (no raise, print, module `var`, function-value call or declared type's method) · question B-17-f
- [x] a context is read through a context value the reader imports, `use context(themeContext)` — never a bare type name —, matched to the provider by the context's type, the handle's default when none (decisions 722, 723); `use provide(ctx)` alone, a body making its own with `comptime createContext(…)` or `use memo({ -> createContext(…) })`; `use context(<Type>)` refused at the argument, naming the form; the 51 sites of std, the cells and rakun rewritten (rakun's in 165 s10); cells `context_read_by_value`, `context_provide_made_in_body`

#### B-17 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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
      — the suite green on `feat` locally (2307); two B-17 reds fixed (`test-docs` — `scripts/check-docs.sh` catches it and
      now runs before every push; an enum in a comptime-lifted record field, `comptime_enum_in_record`); five cells; every
      B-17 cell referenced. Box 1 closes on the next completed green `test` run (B-81's red first).

| B-17 change | Cells |
|---|---|
| a namespace import's decorators (386) | `decorator_through_namespace` |
| every function's stage (376) | `stage_of_functions`, `stage_imported`, `stage_build_and_run`, `stage_comptime_block_in_run` |
| an `Any` call known at build (355, 380) | `hole_any_call_at_build`, `hole_any_call_raises`, `styled_holes_known_at_build` |
| a method / `default fn` / enum method marked by its body (375) | `component_method_sync`, `component_default_fn_sync` |
| the comptime primitives; a suffixed literal and `@Result` at build | `comptime_primitives_at_build`, `comptime_wide_literal`, `comptime_result_methods`, `comptime_enum_in_record` |
| contexts by type with a default (378, 379) | `context_default`, `context_default_imported`, `context_undeclared_type`, `context_declared_twice`, `context_declared_twice_across_modules`, `context_enum_default` |
| injection (416) | `inject_record`, `inject_behavior_keyed`, `inject_test_root_fake`, `inject_field_undeclared`, `inject_behavior`, `context_behavior_not_implemented`, `inject_default_imported`, `inject_not_record_enum` |

- [x] `context-not-declared` for a behavior proposes `createContext(Repository(…))`, which a behavior cannot take: it names
      `createContext(value, Repository)`; then the cell `context_behavior_undeclared` — found by B-17's Conformance step
- [ ] 943: `HookUse` carries the declaration handle of a module-level `val` argument for every hook (`use atomValue(x)` as `use context(ctx)`, 839) — only if the list carries it for `use context` alone today; the island's read set is read off it

### B-18 — 311, 415, 426, 429: templates

**Repository:** botopink-lang, with consumer commits in erika, jhonstart (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

The template annotation, the template method, `lookup`, a call typed by its expansion, built code located by
its expansion. Steps 29 and 41 landed (checker-s29, checker-s41); what step 29 leaves stays here, step 41 is done.

**Impacted tests:** `run/template_*`, `reject/template_*`; the drift test (`Expr`'s surface). **Model:** opus.
**Consumer commits:** erika (`erika.bp`'s padding), jhonstart (`html.bp`'s padding); unblocks erika 137 (145 s1),
dbcontext 143 (150 s48).

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

#### B-18 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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
      — the suite green on `feat` locally; B-18's own defect fixed: `x.greet "…"` where the receiver's type declares
      `greet` refused `template-call-unexpanded` (`template_method_own_method`, a unit test in `tests/templates.zig`); six
      cells added. Box 1 closes on the next completed green `test` run.

| B-18 change | Cells |
|---|---|
| a template method | `template_method_call`, `template_method_own_method`, `template_method_receiver_mismatch`, `template_method_not_in_scope` |
| `lookup` → `?Decl` and its members; writes refused | `template_lookup_decl`, `template_lookup_decl_members`, `template_lookup_decl_write`, `template_lookup_decl_wrap_with` |
| `bindings()` as `Decl[]`; `module` on every `@Decl` | `template_bindings_decls`, `decorator_decl_module` |
| meta at build, the order, hooks pending | the `template_lookup_meta*` cells |
| a call typed by its expansion, the bound, the note | `template_call_typed_by_expansion`, `template_call_expected_mismatch`, `template_build_outside_bound`, `template_note_on_mismatch` |

- [x] a receiver whose type implements a behavior method named like the template method (`hasInherentMethod` counts
      inherent methods only); a refusal cell for `template-call-unexpanded`
      — fixed (`receiverHasMethod`, `template_method_behavior_method`); `template-call-unexpanded` is a backstop no program
      reaches — a unit test pins it, not a cell
- [x] the backstop's unit test for `template-call-unexpanded`
      — in `tests/templates.zig`, a local's call let through
- [x] a local or a parameter named like a template function does not hide it (`fn run(shout: fn(string) -> string) {
      shout("x") }`, `val shout = …; shout("a")` run the template) — found by B-14's Conformance step
      — the nearest binding wins (`template_name_shadowed_by_local`)
- [x] a template function taken as a value (`val f = shout;`) compiles, then aborts on node and BEAM, erlc rejects it, wasm
      calls it unbound — refused at the reference — found by B-14's Conformance step
      — refused at the reference, `template-function-value` (`template_function_value`)
- [x] a module-level `val g = { -> shout "x" }; g()` prints a fun on beam and `256` on wasm — found by B-14's Conformance step
      — any module-level lambda `val` applied on beam and wasm (`template_in_module_val_lambda`)

### B-19 — 216, 281, 298, 353, 356: decorator outputs

**Repository:** botopink-lang, with consumer commits in rakun, jhonstart, validation, styled (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

**Impacted tests:** `tests/language` `@emit` cells (become `reject/`), `run/meta_*`, `run/template_reads_program_catalogue`.
**Model:** opus. **Consumer commits:** rakun (the remaining `@emit` sites, typed meta — each a decision-188
commit after the owning rakun step), jhonstart (`#[page]`, `#[client]`), validation, styled (the catalogue).

#### Step 5 — migrate the remaining sites (was `130-decorator-outputs` s5)

Nothing open here: the migration is overtaken by 605 — every `@emit` site became a registration in a `compiler.init`
executor, a typed `addMember` or a template text handed to `addType` (rakun's and jhonstart's in 165 s10, validation's
here), and no catalogue is read at build (665).

#### Step 6 — remove module-level `@emit` (was `130-decorator-outputs` s6)

Nothing open here: the removal is overtaken by 605 — `@emit`, `@code` and `@expr` leave with `builtins.d.bp` in B-139
(machine 2), its `emit` cells rewritten over `compiler.init` or removed there.

#### Rows found during the migration (open, not 216's places) (was `130-decorator-outputs` rows)

- [x] a `behavior`'s associated `default fn` called through the behavior from another module
      (`Shape.unit()` with `import {shapes.Shape}`): unknown erlang module on erlang/beam, run-time
      error on commonJS, refusal on wasm — members do not travel with a behavior as with a type
      (holds `rakun-client`'s two sites)
- [x] an associated fn read as a value (`apply(City.make, …)`) is an unbound variable on erlang
- [x] a member's / associated type's diagnostic is located at the annotation that added the code (decision 567), the
      member named by its owner's path (`assoc_type_named_by_owner_in_diagnostic`), the decorator's `addMember` /
      `addType` call as the called-from frame, one error per failing annotation
      (`decorator_member_type_error_at_annotation`, `decorator_assoc_type_error_at_annotation`,
      `decorator_output_error_one_per_annotation`)
- [x] a decorator imported from another module whose body builds a record private to its module fails
      at the evaluator (`call to undefined function Entity/1`): `block_eval.typesReached` finds an imported
      decorator's types through the export registry only — string meta and typed meta alike (found by
      step 8; `01-checker` step 21 owns `block_eval.zig`)

#### Step 7 — references, not strings (decision 281) (was `130-decorator-outputs` s7)

- [x] decision 564: a decorator's `@Decl<B>` names the behavior its declarations implement — `#[d]` on a type not
      implementing `B` refused at the annotation, an imported decorator bringing its behavior from its own module;
      `@TypeInfo.all(with: d)` answers `Declared<B>[]` (the behavior a multi-decorator query shares, else `unknown`); a
      behavior's function on an entry's `value` refused outside a 562 expansion; `member:` still accepted beside it,
      botopink-lang's cells migrated (`decorator_decl_behavior_not_implemented`, `typeinfo_all_behavior_typed`,
      `typeinfo_all_behavior_shared`, `typeinfo_all_behavior_none_shared`,
      `typeinfo_all_behavior_call_outside_expansion`)
- [x] the call emitted direct inside an expansion (`UsersModule.make().start()`) — withdrawn by decision 581 (a registry is
      written by the decorator's executor; no expanded `boot`); 564-a closed by 664, 564-b and 564-c by 665 (no catalogue
      at build)

Nothing open here: `member:` is overtaken by 665 — `compiler.find` leaves `compiler.bp` with `member:` in B-137 (564 →
576 (1), 665).

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
- [ ] a meta field of a record type, a `compiler.Field<T>` (364 (2)'s data family) or a tuple: refused
      today (`decorator-meta-field-type`); rebuilding one where the meta is read needs its names in the
      reader's scope (a field filled from a `syntax` carries such a value as written)
      — tuple and `compiler.Field<T>` fields rebuilt where read, a generic meta record keyed by its parameter
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
- [x] the importer of a reader module that breaks the rule gets `typeinfo-all-imported` at the
      import, not `unbound variable '<template>'` at the use (row 134's diagnostic half)
- [x] `run/template_reads_program_catalogue` (one and two built as `modules/template_reads_program_catalogue`, `modules/template_catalogue_two_themes`; none still answers an empty catalogue — 358's refusal open) — a package's template function counting the importing
      application's `#[theme]` declarations: none (refused, 358), one, two (refused at the second, naming both)

Nothing open here: a `Declared`'s `value` read at build is overtaken by 665 — no catalogue is read at build; the
`#[theme]` decorator's `compiler.init` executor registers its theme, a second refused at init, and a template emits code
reading that registry at run time (353 → 665, 576 (7)).

**Gate:** standard (fronts.md § Gate) + std on commonJS and erlang; each library's hook

#### B-19 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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
      — the suite green on `feat` locally (no red B-19's); every landed change has its cell. Box 1 closes on the next
      completed green `test` run.

| B-19 change | Cells |
|---|---|
| an imported behavior's associated `default fn`; a type adopting its defaults | `behavior_associated_fn_imported`, `behavior_default_adopted_across_modules` |
| wasm reads a function value's record | `associated_fn_value_answers_record` |
| an imported decorator builds its private record | `decorator_imported_builds_private_record` |
| the catalogue: no theme; a comptime `val`'s build value | `template_catalogue_no_theme`, `template_reads_val_build_value`, `template_val_value_not_comptime` |
| an associated type named by its owner; tuple / field-key meta | `assoc_type_named_by_owner_in_diagnostic`, `meta_field_tuple_and_field_key` |


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
      `pub type Type { pub type Field<T>(…) { … } }` reads `compiler.Field<T>` (308); `reject/` cells for a nested
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

- [x] `val t: Sort<Book> = Sort(by: .title)`: a field key under an annotation is refused where `Sort<Book>(by: .title)`
      resolves — found by B-19
      — the annotation pins the constructor's type parameters (`field_key_under_annotation`)
- [x] wasm: `std_decorator_leaf_import`, `std_decorator_through_namespace`, `std_decorator_unknown_through_handle` red on
      `feat` — "`canonical` has no wasm external" at std's `testing/asserts.bp` — found by B-19
      — std's `mocks` reaches no other std module again (a private `raisedText` cell), a hook test in `tests/wat.zig`
- [x] wasm: `pub fn main() {}`, a module nothing calls and a dependency: `compilation failed UndefinedCall` — found by B-27
      — an empty body is a function that does nothing (`fn_empty_main`, `fn_empty_body_call`)
- [x] wasm: an untyped lambda typed only by its expected `fn(Pessoa) -> Pessoa` cannot place a field two records share
      (`p.nome`, `..p`: "cannot place `.nome`") — found by B-14's Conformance step
      — a lambda argument typed by its declared parameter (`lambda_param_shared_field`)
- [x] a field read after a `?.` call link (`p(true)?.me().x`) is refused while a method there is accepted
      (`find(0)?.str().length()`); TypeScript continues the chain for both — one rule — found by B-20's Conformance step
      — it continues the chain, as a method does (`optional_chain_field_after_call`); `a?.b.c` too

### B-21 — 364, 408, 409: `syntax` hygiene, the typed function expression, the tail value

**Repository:** botopink-lang (`--lang`)

**Impacted tests:** `modules/decorator_member_fn_imported_name`, `run/fn_expr_typed_anywhere`, `run/fn_tail_value`
and its siblings. **Model:** opus. **Consumer commits:** none.

#### Decision 583 — every function typed where it is written

- [x] a lambda nothing types refused `lambda-untyped`, located, the hint naming the typed form and the `val` annotation;
      328's inference from later calls removed with its tests; the 69 cells migrated (the inference cells become refusal
      cells); one migration commit per library (rakun 16, query 13, std 5 sites), by hand; `docs.md` § Lambdas
      — built as: `lambda-untyped` also for a module-level `val` and a parameterless lambda; 328's inference code stays, an
      immediately called fn expression and an argument of a free type parameter still reach it; rakun's and query's sites migrated, std's five not recorded as done

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
- [x] decision 622: every function writes its return type, `-> void` included; a `fn` without `->` refused at its name
      (`fn-return-missing`); 06 C9's inference from the `return`s removed; the ~2,360 arrow-less functions (1,927 in the
      cells, 1,485 of them `main`; 8 in std) gain `-> void` or their type by codemod, the libraries' in their fronts; cells
      `fn_return_missing`, the tail cells respelled; `conformance/docs.md` § Functions and § `.bpp`
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
- [x] the shortform `fn f(x: T) R` (a type with no `->`) refused `fn-return-missing` at the name, the hint naming `-> R`; the parser's
      `arrowOmitted` branch removed (decisions 622, 846); cell `fn_return_without_arrow` (reject; red on the parent) — landed (no std, cell
      or library site wrote the shortform)
- [x] `botopink format` over the shortform drops its type (`fn f(x: i32) R {` printed `fn f(x: i32) {`): the formatter refuses what the
      parser refuses (`fn-return-missing`) instead of rewriting it; a `format/tests` case — landed (`format.zig`'s `firstReturnMissing`; the file left
      untouched, exit 1)


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
- [~] union of primitives a `case` produces (`test/case_value_union`) prints an address on wasm — superseded by group
      wasm-gc (B-83): a union value is a reference to any GC type; the cell is B-83's
- [ ] a bare name inside a multi-subject arm (`Shape.Square(side), m -> …`) binds, against `docs.md`'s "a name alone is not a
      pattern" · decision 602: refused `case-bare-name-arm` in both forms; `case_multi_subject_patterns` rewritten, `case_multi_subject_bare_name`
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
- [ ] a value of an enum section (`val t = Token.Color.White; terminal.print(t)`): commonJS, erlang and beam print
      `Token.Color(_inner: __Token__Color.White)`, wasm an address · decision 601: the leaf's whole path, `Token.Color.White`, on four targets
- [x] an imported enum's variant with a payload prints as a number on wasm (`@print(AMode.Slow(2))` printed
      `8764`, `AMode` from another module) — found by B-23
- [x] `test/expr_sugar.bp`'s pipes red on erlang and beam on `feat` (three cases; red on the base too) — found by
      B-22
- [x] a bare name as a catch-all arm (`k -> k + 1`) is accepted by the checker, which `docs.md` says is not a
      pattern; commonJS then fails `k is not defined` — refused at the arm, located — found by B-22
- [ ] `1000.toF64()` printed `1000.0` on commonJS, `1.0e3` on erlang and wasm (with B-78) — found by B-17
- [ ] `Float.toString` differs across targets: `1200.0` on commonJS, `1.2e3` on erlang, beam and wasm; `9007199254740992.0` on
      commonJS and wasm, `9.007199254740992e15` on erlang and beam — one text on every target (decision 441, with B-78) — found by B-22
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
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named
      — the suite green on `feat` locally (2003); B-22's two reds were format-check's (`scripts/format-check.sh` catches
      them); every landed row has its cell, thirteen cells named in `conformance/docs.md`; the completed `test` runs since
      the base red on others' stages (format, B-60's `code_cache.sh`). Box 1 closes on the next completed green `test` run.
- [ ] `enum_section_value_print` (decision 601); one cell over `Float.toString`'s values (B-78)
- [x] 926: `hook-name-use-prefix` — a `Component<R>`-answering declaration named `use[A-Z]…` refused at its name; cell `hook_name_use_prefix_refused`, four targets, red on the parent — landed for a `fn` declaration
- [x] 926 / 929 on the other declaration forms: a method, a `default fn` and a typed lambda named or typed so (`use[A-Z]…` answering
      `Component<R>`, `-> noreturn`) are refused as a `fn` is; cells beside 926's and 929's, red on the parent — landed (a method and a `default fn` for both; a typed
      `fn(…) -> noreturn` for 929 — a lambda has no name for 926)
- [ ] 926 / 929 on a method of an `implement` / `extend` block (checked by another path than `inferTypeMethods`); a cell each, red
      on the parent
- [x] 929: `noreturn-falls-through` — a `-> noreturn` body that can complete refused at its name (`stmtsAlwaysExit`); cell `noreturn_body_falls_through_refused`, four targets, red on the parent — landed for a `fn` declaration (the other forms: the box above)
- [ ] 950: `for x in xs { … }` / `for await x in s { … }` / `for x in try xs` the one loop spelling (parser, checker, four backends); `for (xs) {` refused `for-parenthesised`; `botopink format` rewrites the old form; std and the cells migrated in the same commit, each library in its own; `docs.md` § Loops; cells `for_in_loop`, `for_parenthesised_refused`, red on the parent
- [x] 951: a `?T`'s non-null arm is `_`, its value read `x!`; the binder arm `case-bare-name-arm`; `docs.md` § case's row and the cells written with the binder rewritten; cell `case_optional_bare_name_refused`, red on the parent — landed (markdown's two sites and rakun's two tests respelled)

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
      — run on `feat` in the main checkout: green to `test-cli`, red at `test-libs` on `rakun-data`'s `#[query]` (B-81) and a
      `rakun-cache` timing test (150 s31); closes when both are green

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
- [x] two aliased imports of two same-named **types** are legal (310): every backend qualifies a type by
      its module; `modules/import_two_types_one_name` becomes an accept cell on every target (until
      then the refusal is a `language-gaps.md` row) — its own work: a type's identity by module throughout the checker
      and the four backends, which name a type by its declared name alone today; whether a type of this
      module beside an aliased import of a same-named type counts is decision 603 (two types)
      — built: the checker keys an aliased type by its alias, erlang / beam / wasm follow, names unchanged with one type
      per name; `import_two_types_one_name` accepted on four targets, one alias alone too; the two-packages row falls with
      it. A local type beside an aliased import stays `import-name-collision` today — decision 603 accepts it (cell
      `import_alias_beside_local_type`; `decorator_member_type_same_name` re-read). Left:
- [x] a std type in the pair (`import {collections.Dict as D} from "std"` beside an aliased `Dict`) still refused
      — legal (`import_std_type_beside_aliased_type`); an un-aliased non-std type beside an aliased std one stays refused
- [x] an imported function's signature renamed through a namespace call (`m.f()`), an imported template function and
      decorator support, as it is for a plain import by name
      — `import_two_types_one_name_reached_indirectly`
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
- [x] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [x] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape, red on the group's base and green on its tip; the missing ones proposed as rows
- [x] the reference updated (480): the `docs.md` of each cell written or whose answer changed, and the root reference
      (`docs.md` until B-29 step I moves it to `conformance/docs.md`)
- [x] the pipeline's state in the step's report (474): each repository the group changes, its runs on `feat` since
      the group's base, green or each red named
      — the suite green on `feat` locally (1267 cells, every `test/` suite); no red B-23's; two pins (`import_two_types_one_name_unaliased`,
      `own_type_beside_aliased_type_import`); seven `docs.md`. Box 1 closes on the next completed green `test` run.

| B-23 change | Cells |
|---|---|
| a literal past its range on every target (319) | `wide_literal_past_js_safe_integer`, the `integer_literal_*` refusals |
| a type application through a namespace | `type_application_through_namespace`, `type_application_through_namespace_mismatch` |
| `@External.Wasm` read on every target | `external_wasm_op_type_on_every_target`, `external_wasm_adapter_signature_on_every_target`, `external_wasm_task_adapter_shape` |
| a comptime body's file | `decorator_raise_names_body_file` |
| 310 | `import_two_types_one_name`, `import_two_enums_one_name`, `import_same_type_name_two_packages_one_aliased`, `import_std_type_beside_aliased_type`, `import_two_types_one_name_reached_indirectly`; pins `import_two_types_one_name_unaliased`, `own_type_beside_aliased_type_import` |

- [x] proposed: a template body's raise naming its file (only `decorator_invocation.zig` pins it)
      — a defect: another module's template named no file; fixed (`template_raise_names_body_file`)
- [ ] a raise in the module's own template located at the call that raised, as a decorator's (451 (3)) · question B-23-b
- [x] decision 603 for a std type: a local type beside an aliased import of a same-named std type (`import {Dict as D} from "std"` beside `type Dict(…)`) is two types — cell `own_type_beside_std_type_import` flipped to accept. Today it stays `import-name-collision`: a std type keeps its declared name in the checker, std's signatures resolve `Dict` by that name, and the backends treat std's `Dict` as a builtin shape, so keying it by its alias needs a rename of std's declarations and signatures (what `registerRenamedImportedType` does for a non-std import) · model: opus · landed (`own_type_beside_std_type_import` answers the two types; an unaliased std leaf beside a local type stays `import-name-collision`)
- [ ] an imported value's method answer or field typed by the owner's `Tag` resolves to the importer's own `type Tag(…)`
      (`unknown field 'label' on type 'Tag'`): types are matched by name, against 603's identity (module + name); a cell (an
      importer declaring its own `Tag` beside a `shop.bp` whose method answers `shop`'s `Tag`), red on the parent — the mechanism
      (the maintainer, 2026-10-21): every type declaration gets a unique id the compiler writes, as Zig names an anonymous struct
      `struct__0014`, carried by the type and marked on its values, so two same-named types of two modules (`type_0015`, `type_3232`)
      never meet — the checker compares ids, never names; a name stays the program's spelling (603: module + name)

### B-24 — 319, 320, 332: numbers and strings exact everywhere

**Repository:** botopink-lang, with consumer commits in rakun, jhonstart, onze (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

`bigint`'s rest (139 landed as bigint-139; its two open boxes) then `Decimal` and `Json`'s numbers. Questions `decision 496`, `decision 497`,
`decision 500` (whether 142 s1 goes first and the `Int` / `BigInt` / `Dec` arms land in the json repository).

**Impacted tests:** `run/json_numbers_exact`, `run/i64_*`, the clock cells. **Model:** sonnet, opus for 139's
checker half. **Consumer commits:** rakun (3 files), jhonstart (2), onze (2) — the `Json` `case` arms.

#### Open (was `139-bigint` open)

- [ ] decision 501's alternatives, if the maintainer answers (b) or (c): `is bigint` by value range, a
      `bigint` in `unknown`, compile-time `bigint` in the folder and the comptime runtimes (14 · 18)
- [~] wasm: a `bigint` member of a union (`lowerAsUnknown` refuses it) — superseded by group wasm-gc (B-83): `unknown`
      is a reference to any GC type, a `bigint` among them; the cell is B-83's

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
      widening `i32 → i64` is free (already canonical); `print` and string interpolation print the digits
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
      scale (`"1.00"`, never `1E+2`); `parse(text) -> Result<Decimal, string>`
- [ ] `Json`: `Num(value: f64)` replaced by `Int(value: i64)`, `BigInt(value: bigint)`, `Dec(value: Decimal)`,
      chosen by the numeral; readers `num() -> ?f64`, `i64() -> ?i64`, `bigint() -> ?bigint`,
      `decimal() -> ?Decimal`, `isNumber()`, `isIntegral()` (exact or `null`, never coerced); `encode` writes
      the digits and the plain decimal text; std's tests `decodesTo("9007199254740993", Int(value: 9007199254740993))`
- [ ] `json.parse` and `json.stringify` deleted with their Node / Erlang templates (336); their one caller (`tests/language/run/std_json_on_every_target.bp`)
      rewritten to `decode` / `encode`; `json` compiles on wasm under both hosts with no host cell
- [ ] the 13 files with a `case` over `Json` (std 6, rakun 3, rakun-bpp 2, rakun-ssr 2) gain the arms, one commit per
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

- [x] `@Component` bodies (375's mark) as state machines — decision 504 (recommended: every `@Component` a
      state machine on wasm); today they stay eager and an `await` of a task there runs the ready tasks,
      trapping on both hosts when the task still waits on the host
      — the render scope typed through std's `context` slots on wasm (`scope_carry.zig`), a state machine only for a body that
      awaits (`component_awaits_host_task`); 33 component cells gain wasm, five narrowed by their host binding; std's marker
      and the gap row gone
- [x] a template call inside a template's built code is never expanded (node / BEAM abort, erlc refuses, wasm cannot
      resolve it; `net_new_nested_template_call_inside_a_template_body`) — found by the template-name rows
      — expanded in turn (`template_call_in_built_code`)
- [x] a local named like a module function with comptime parameters has its arguments stripped by the name-based
      transform — found by the template-name rows
      — the local keeps its arguments (`comptime_fn_name_shadowed_by_local`)
- [x] `feat` red: four codegen `use … is a plain call` snapshots quote std's `context.bp` comment changed with B-25's
      marker; `std_json_on_every_target`'s wasm departure no longer refuses — re-recorded / removed at once
      — re-recorded; the two stale std/json wasm departures removed
- [x] wasm: a component body with a bare `try` runs its tail as an inner closure that stays a plain lambda, so a
      host-pending task awaited in it traps — found by B-25
      — the tail's closure a state machine when it awaits (`component_try_then_awaits_host_task`)
- [x] wasm: an `f64` / `i64` provided or rendered through the scope is refused (it does not fit one slot) — found by B-25
      — it crosses as its cell's address (`context_wide_number_through_scope`)
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

- [ ] `io/http`'s `fetch` binds `#[compiler.external(.Wasm(host: .Wasi, wasi: .HttpOutgoing))]` and the `browser` host's JS `fetch`;
      the request and response mapped by each adapter; on `browser` a forbidden header or a `Set-Cookie` read answers
      `HttpError.NotAllowedOnHost(…)` naming it (335 (1)); `run/std_io_http_on_every_target` against a local double
- [x] `async`'s twelve cells bind on `wasi` (`delay` on the monotonic clock, `race` / `raceOf` on pollables, the
      gate cells as pollables) and on `browser` (the same adapters, 394), through 392's scheduler; `RetryPolicy` / `nextDelay` unchanged;
      `run/std_async_on_every_target` asserts results and answer order only — never effect interleaving (335 (2))
- [ ] the `browser` bindings of both modules in the same commit (334: a cell bound on both hosts or neither) — `async` bound on both hosts; `io/http` on decision 623's surface

#### Steps 9 and 11 — a prebuilt wasm library (decision 333 (B)) — withdrawn as written (was `05-wasm` s9, `04-js` s11)

- [~] withdrawn: both steps were a linear-memory design (the library's memory and data folded into the module, strings
      as pointer and length through `alloc` / `free` exports, the WAT comptime runtime running it). Under group wasm-gc
      (B-83) a prebuilt library's ABI is GC references and its glue is none; `@External.Wasm(module: …)` and
      `run/wasm_library_binding` return as a question of their own once B-83 lands. Nothing of them is built.

- [ ] the adapter names `.GateNew` / `.GateOpen` / `.GateAwait`, and std's test-only cells (`monoMillis`, `hostTarget`, the
      counters) left unbound on wasm until `botopink test` runs wasm (335 (3)) · question B-25-a
- [x] decision 623: `fetch(req: Request) -> Task<Result<Response, HttpError>>`, `Request(method, url, headers = [], body = null)`,
      `HttpError { NotAllowedOnHost, Network(message), Timeout }`; `fetch(url)` removed in the same commit, std's and `http`'s
      call sites migrated; cells `http_fetch_request`, `http_fetch_url_removed`
- [x] log's two markers — superseded by fs-a: `io.fs` binds `wasi:filesystem` on wasm, log calls it; 156's markers removed
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
- [~] Step 9's manifest key, ABI and glue — withdrawn as written (a linear-memory ABI); under group wasm-gc a prebuilt
      library's ABI is GC references, a question of its own once B-83 lands; steps 9 and 11 wait on it
- [ ] erlang: DebugAllocator reports a leak in `erlang.zig`'s `closeTypeUnit` under `cell check` — found by B-25

#### B-25 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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
      — the suite green on `feat` locally (2020); B-25's red (the four snapshots) caught by `zig build test`; the table below.
      Box 1 closes on the next completed green `test` run.

| B-25 change | Cells |
|---|---|
| std's `async` on both wasm hosts | `std_async_on_every_target`, `async_block_all_of` |
| a function-typed parameter binds type parameters from its argument | `generic_thunk_result_binds` |
| components on wasm (504) | `component_awaits_host_task`, 33 component cells with wasm |
| a `try` tail awaiting; a wide number through the scope | `component_try_then_awaits_host_task`, `context_wide_number_through_scope` |

- [x] proposed: a `?f64` / `?i64` through a context; `try … catch` then an await in a component; the gates under `browser`
      — pins `context_optional_wide_number_through_scope`, `component_try_catch_then_awaits_host_task`; `browser` already runs
      every wasm cell beside `wasi` (`std_async_on_every_target` pins the gates)

### B-27 — Tooling, std residue, `.bpp` in the toolchain, `json` out of std

**Repository:** botopink-lang, with consumer commits in jhonstart and the `json` consumers (through 151) (rule 10) — a full worktree; a library half that its own front holds is handed over as a row

- [ ] decision 672: 541's lambda-`;` rewrite kept as `botopink format --migrate 541`, explicit; a landing's rebase across the rule runs it first; removed once every repository and every open branch is migrated, stated
116's botopink-lang half (the vscode-extension box is 161's) with 01-checker step 22's prelude scope;
26 s9; std purity (23) and effects by return (24 — 24-a answered by 431, 24-b by 432; 24-c, 24-g open); std's
snapshot message (135 s1); 97's residues; 98's script and its `docs/botopink-json.md` lines; 142 s1's std half
(the json front, 151, carries the consumers). Questions `116-a/b/c`, `23-b`, `std-c`, `24-c`, `24-g`, `decision 506`,
`decision 507`.

**Impacted tests:** `tests/language/modules/bpp_*`, compiler-cli, language-server, lib-test-runner;
`tests/cli_contract.sh`; `scripts/check-packaging.sh`; `test-libs`. **Model:** opus for 116, sonnet for the rest.
**Consumer commits:** jhonstart (`#[bpp.html]` with 26 s0), the six `json` consumers through 151.

#### Step 0 — Measure what the unfold stands on (was `116-bpp-file-format` s0)

- [x] `tests/language/modules/` cell: a package's `pub default fn` over `comptime template:
      @Expr<string>`, imported `import t from "<package>";`, called with a literal from a consumer,
      on every target the language suite runs
- [x] decision 199's header rule over every `.bpp` under `specs/1.0.12-beta/*/*/examples/`: each
      header item listed as declaration (`import`, `type`, `pub`) or statement (`val`, `use`);
      every unnamed item (`if`, expression statement, private `fn`, `test`, decorated
      declaration) listed with its file
- [x] a module hand-assembled as the unfold would: a header-line type error and one inside the
      literal each reported at the `.bpp` line

#### Step 2 — The unfold (was `116-bpp-file-format` s2)

- [x] the return type is read from the default function's signature (decision 275): the fixture
      package's `@ExprCustom<i32>` gives `-> i32`; jhonstart's gives `-> @Component<Element>`
      for a header with and without `use` / `await`; the toolchain spells no type name
- [x] `tests/language/modules/bpp_*`: fixture package whose default function is **not**
      jhonstart's (answers the literal's length) — `.bpp` with `type Props` unfolds to
      `pub default fn (props: Props)`, without to `pub default fn ()`, no header = all
      literal; fixture served unchanged (proof the toolchain knows no library)
- [x] the file's grammar (212, 338): the header from the first line to the first separator line;
      `---` → markup to the end of the file; `--- style ---` → style section closed by `---`, then
      markup; no separator line → markup only (a markup-only file compiles)
- [x] a first line `---` refused at line 1: `error: the header starts on the first line; a .bpp has
      no opening ---`
- [x] each refused at its line: a `--- style ---` after the markup; a second style section; an
      unclosed style section (at its `--- style ---` line)
- [ ] the style section unfolds to `use <style> """<the section>""";` after the header's
      statements, before `return html """…""";`, with `import <style> from "<bpp.style>";` binding
      no name the header can reach — § Mechanism's `Props(title)` example unfolds as spelled there
      — built; its success cell waits on the gap of a template answering `-> Component<T>` (852; the fixture's template answers `-> Component<i32>` building `{ _ -> n }`)
- [ ] fixture style package (not `jhonstart-styled`) whose default function answers something
      trivial (the section's length): a `.bpp` with a style section compiles onto it unchanged —
      the toolchain knows no library for the style section either
      — waits on 852 (B-162)
- [ ] a diagnostic inside the style section reported at its `.bpp` line, like the markup's
      — waits on 852 (B-162)
- [x] the default function anonymous (289): `import {components.PostCard};` binds `PostCard` in the
      importer, an alias another name; a file name that is no identifier (`not-found.bpp`) unfolds;
      `decl.name` is the file name; `page.bpp` whose header imports and writes `#[page(…)]` compiles
- [x] declarations at module level, statements in the body in order; a statement reads `props`
- [x] a decorator on the header's last line, before the separator line, annotates the function
      (221 (1)); without one the function carries none — no decorator from the file name, no
      `bppKinds` read (285)
- [x] `X.bp` beside `X.bpp`, and `.bpp` with no key — each refused with § Mechanism's message
- [ ] prelude (270): fixture with `prelude.bp` — markup-only `.bpp` compiles; module and emitted
      code import only used items; header name beats prelude's; `prelude.bp` holding a `fn`, another
      package's item or an activation refused at its line. The scope (`compiler-core`: last scope, import-item list) is
      `01-compiler/01-checker`'s, handed by this front
      — waits on question 116-a
- [ ] `grep -riE 'rakun'` and `query` as a package (`"query"`, `import query`) over `modules/compiler-core/src` and the
      edited `compiler-cli` files is empty
      — `libs.zig` and `resolver.zig` name libraries today; the unfold's code names none

#### Step 3 — The extension in every tool's list (was `116-bpp-file-format` s3)

- [x] every § Mechanism site reads one shared list instead of spelling `.bp`
      — resolver, libs, scanner, format and the lib-test runner read `manifest.SOURCE_EXTENSIONS`; the language server's sites too (project index, project graph, the engine's paths)
- [ ] `botopink build`, `check`, `run`, `test` over a `.bpp` project; test runner discovers a
      `test` declared in a header
      — build / check / run proven by the cells; a `test` declared in a header not pinned
- [x] `mod x;` resolves `x.bp`, then `x.bpp`, then `x/mod.bp`

#### Step 4 — The span mapping and the editor — part (was `116-bpp-file-format` s4 boxes 1, 2)

- [x] header-line type error and a `failAt` in the markup reported at their `.bpp` line and
      column by `botopink check` and the language server
      — `botopink check` and `build` report the `.bpp` line; the language server too (an open `.bpp` compiled as its unfolded module, positions mapped back; `tests/bpp.zig`, five `lsp/bpp_*` snapshots)
- [x] hover, go-to-definition in the header; default function's overlay served as the markup's
      tokens — the extension ships no grammar of the file
      — hover and go-to-definition in the header mapped back; the markup overlay not exercised by a test

#### Step 5 — The formatter (was `116-bpp-file-format` s5)

- [x] `botopink format` rewrites a badly indented header as a module, leaves every byte of the style
      section and the markup unchanged; `format --check` fails on the header, passes the style
      section and the markup
- [x] `scripts/format-check.sh` walks `.bpp` files — header under the gate's format stage like any `.bp`

#### Gate additions (was `116-bpp-file-format` gate)

**Gate:** standard (fronts.md § Gate), in `repository/botopink-lang` and `repository/vscode-extension`, plus:
- [ ] `zig build test-libs`: every library green — no existing `.bp` file changes meaning
      — 123 passed, 1 failed: `rakun-data` on erlang, the `#[query]` red older than B-27 (B-81); closes when B-81 does
- [x] `docs.md` § Modules documents `.bpp`, every fence compiled by `zig build test-docs`

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

- [x] a transitive dependency's sidecar ships: a project outside the rakun workspace depending on a
      member by `path` failed `build` with "`rakun_actuator` / `rakun_probes` is not a sidecar of
      this project" — `libs.sidecarOwner` asked only the project's direct `dependencies`, then the
      roots by name; it now walks the closure the build resolved (`closureOwner`) ·
      `tests/cli_contract.sh` "a dependency of a path dependency", `libs.zig` unit test
- [x] a dependency's module importing a package it does not declare is decision 242's located
      `unresolved import source` (at the dependency's file), not `unbound variable` —
      `libs.loadOne` runs `resolver.checkSources` against the dependency's own manifest ·
      `modules/dependency_imports_undeclared_package`, four targets

**Gate:** standard (fronts.md § Gate) + `zig build test-cli`, `test-bpmp`, `test-vscode` green;
language-server tests green with new snapshots · `zig build test-libs` at baseline (rakun's members
exercise every sidecar path)

#### Rows other fronts found (was `26-cli-tooling` rows)

- [x] `botopink check` / `build` print a type error's message and box but not its hint: the
      `PersistentTerm` write (`infer.zig`'s hint names `#[@BeamMemory.Ets]`) and
      `std-unsupported-on-target` carry one and the terminal shows none; a parse error's
      `= hint:` line prints (measured by `07` step 6; `docs.md` § `@BeamMemory` cites the hint)

#### Step 1 — the gate's rows (was `23-std-purity` s1)

`zig build test-language` green on four targets with the import cells (`modules/import_alias_on_type`,
`import_std_type_through_module`, `import_std_folder_namespace`, `import_type_closure*`,
`import_type_alias`); language-server tests with the `project_graph.zig` cells (one `lsp/` snapshot
per import spelling).

- [x] `run.sh --target all` green on the `modules/import_*` cells — measured, the box ticked
- [ ] `grep -l 'import {' modules/language-server/snapshots/lsp/*.snap.md` lists one snapshot per spelling (dotted, grouped, `*`, `as`, a folder leaf); missing ones added
      — one per spelling but `*`, whose only spelling is refused
- [x] the five `AGENTS.md` name the tree and the grammar; `docs.md` § imports / § std verified against the grammar (07 places any correction)

#### Step 2 — the confirmations (was `23-std-purity` s2)

23-b (`base64` retired) and std-c (namespace rewrite): each confirmed or reversed; a reversal opens a
step in the owner (01 for std-c). 23-c is confirmed (317).

- [ ] the three ids in `../../../decisions-taken.md` with their numbers, or a reversal's step named —
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

- [ ] the four ids in `../../../decisions-taken.md`; a reversal's step named in the owning front — 24-a → 431 (checked `Result`; 24-b → 432, the failing task;
      `throws: true` and `attempt` are `01-checker` step 42 and `02/97` step 18)

#### Step 3 — the cost of a `Result` per item (was `24-effects-by-return` s3)

`Iter<Result<T, E>>` of 10⁵ items consumed by `for` with `try r`, on erlang and wasm, vs the
same loop over `Iter<T>`; if the `Ok` wrap weighs, the backend specialises the `Ok` `yield` — a
row for 02 and 05, not edited here.

- [ ] the two ratios in this README with the program and the machine; a row filed in 02 / 05 if either exceeds 1.5×

#### Step 1 — `json` leaves std — part (was `142-data-formats` s1 boxes 1, 2)

- [ ] `libs/std/src/json.bp` moves whole to `repository/json` (history kept as 138 did): the `Json` type
      and its methods, `parse`, `decode`, `stringify`, `quote`, `unquote`, `array`, `object`, the host
      cells and their tests; std's `root.bp` loses `pub mod json;`; `grep -rn "json" libs/std/src` names
      no module (comments aside)
- [ ] `import {json} from "std"` is an unknown-module error naming the `json` library

#### Step 1 — std (390) (was `20-snap` s1)

- [x] `mocks.verify`'s message pinned with `throwsWith` on both targets (§ 1, CONVERT)
- [x] `libs/std/AGENTS.md`: the inline literals and the four `__snapshots__/` path-rule files are the evidence

#### Step 4 residue — the engine under every `-test` member (was `97-std-dedupe` s4 residue)

- [ ] `zig build test-libs` reads every member's row at its previous count (the last recorded whole run, 138's gate: 125 passed) — read on the next cold gate. Measured for std and the seven `-test` members: `std`, `emilia-test`, `erika-test`, `jhonstart-test`, `onze-test` pass on commonJS and erlang, `jhonstart-dom-test` on commonJS, `rakun-test` on erlang, `rakun-starter-test` compiles (no tests); 12 passed, 0 failed, 1 without tests, 3 restrictions audited

#### Step 6 — decision 506 (c)'s std half: `io.stdin`, `io.terminal`, `io.process` signals and `spawn` (was `97-std-dedupe` s6)

std gains a CLI's host primitives (506 (1)); the `cli` library (`botopink/cli`) and onze's use of it (506 (2), (3)) are
other repositories' steps.

- [x] `io.stdin`: `readLine() -> @Task<?string>` (the line without its newline, `null` at end of input), `isTTY()`
      — and `readChunk() -> @Task<?string>`, the byte-level read `keys()` is built on; `std_io_stdin_eof`
- [x] `io.terminal`: `stdoutIsTTY()`, `size() -> ?#(i32, i32)`, `setRaw(on)`, `keys() -> Stream<Key>`
      — `keys()` written `@Stream<Key>` (553's types not in std yet), with a pure `parseKey`; `std_io_terminal_not_a_tty`;
      on erlang / beam `keys()` lazy since B-128 (855), raw mode reads Linux's `/proc` and `stty` (856)
- [x] `TerminalError.Unsupported`; `setRaw` `Error(Unsupported)` and `size()` `null` off Linux on erlang / beam, `os:type()` tested first;
      `libs/std/AGENTS.md` says it; no cell runs off Linux (856) — landed (`std_io_terminal_not_a_tty`'s exhaustive `case` gained the arm)
- [x] `io.process`: `enum Signal { Int, Term, Hup, Winch }`, `onSignal(s, f)`, `spawn(cmd, args) -> @Result<Child,
      ProcessError>` with `Child.wait()`, `kill(s)`, `forwardSignals()` — a spawned child receives the `SIGTERM` sent to
      its parent, asserted with a child that prints on the signal
- [x] errors typed by module (431-a); every cell the same on commonJS, erlang and beam; a located refusal on wasm
      — `std_io_signal_handlers`, `std_io_process_spawn`, `std_io_process_forward_signals`; `.Int` on erlang / beam
      answers `Unsupported` (question B-27-g1), a child's stdio on erlang is a pipe (question B-27-g3)

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
      — `scripts/check-packaging.sh` written; exits 1 today naming 23 example members without a README and 4 `-test` members without a helper — exit 0 after the library steps; it checks the helper's `assert<Subject>(loc: SourceLocation` signature (snapshots moved to `snap`, 391)
- [ ] `docs/botopink-json.md` § Examples states the README and helper rules, links the script
      — the rules are in `conformance/docs.md` § Examples and `-test` members (`docs/botopink-json.md` became it)

#### Step 3 — front 95 closed as a confirmation (was `98-packaging-tail` s3)

Under `decision 507` (1): one `repository/onze` entry in `.gitmodules`, workspace `onze`, eight members with
`files`, listed by `zig build test-libs`; `mocking-lib-final` already resolves. Only the
`docs/botopink-json.md` line to write.

- [x] `git -C repository/onze rev-parse mocking-lib-final` resolves; `git submodule status
      repository/onze` is the orchestrator's commit; `docs/botopink-json.md` says in one line the
      orchestrator repository carries the mocking library as tagged history

- [x] a `.bpp` declaration written after a statement refused at the declaration, naming the statement before it
      (decision 552); the unfold stops moving it — `bpp_declaration_after_statement`
- [x] decision 561's backtick identifier: the lexer's token (an empty one refused), every name position the parser
      takes, each backend's collision-free mapping, diagnostics in the backtick form; `not-found.bpp` imported as
      `` import {pages.`not-found` as NotFound}; `` and without an alias — cells, one per position and per target
      — `backtick_name_{binding,parameter,function,type,field,module_segment,import_item,in_diagnostic,empty,line_break}`,
      `bpp_not_found_aliased`, `bpp_not_found_unaliased`; open: B-27-d (the formatter's plain spelling); B-27-e answered by 853 and 890, B-27-f by 854 (as built)
- [x] the duplicate-module message names 109's fold and the pair is refused on every target at the top of `codegen.emit`, `duplicate_decl`
      too (853, 890); cell `module_atom_pair_refused` (`not_found.bp` + `not-found.bpp`), four targets, red on the parent by its text on
      commonJS and wasm — landed (`crossModule.pairFaults`; red on the parent)

#### B-27 Conformance — the group's last step (decisions 459, 474, 477, 478, 479, 480)

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
      — the suite green on `feat` locally; B-27's format-check red (the `bpp_*` deps) fixed; no cell missing for a landed
      box. Box 1 closes on the next completed green `test` run.

| B-27 change | Cells |
|---|---|
| a `.bpp` unfolds | `bpp_unfold_props`, `bpp_unfold_without_props`, `bpp_decorator_last_line` |
| the grammar's refusals | `bpp_first_line_separator`, `bpp_style_after_markup`, `bpp_second_style_section`, `bpp_style_unclosed`, `bpp_beside_bp`, `bpp_declaration_after_statement` |
| diagnostics at the `.bpp` line | `bpp_diagnostics_located`, `template_fail_at_column_on_open_line` |
| the hint, one extension list, the header formatter, packaging, the language server | no cell: `tests/cli_contract.sh`, `scripts/check-packaging.sh`, `lsp/bpp_*` snapshots |

- [x] proposed: a `test` declared in a `.bpp` header found by the test runner, a `conformance/test/` suite (with step 3)
      — pin `conformance/test/bpp_header_test`
- [x] `conformance/modules/bpp_unfold_props/out/` (built `.js`) is tracked: removed, and `out/` ignored — with `optional_enum_method_imported`'s


### B-123 — a `//` comment between statements of a `case` arm block is a parse error

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

Found by B-27 step 6: a line comment between two statements inside a `case` arm's block is refused "this token cannot
appear here" on every target; a comment between statements of a function body is accepted.

- [x] a `//` comment between the statements of a `case` arm block parses, and the formatter keeps it —
      `case_arm_block_comment`; both arm block forms read through the shared block body

### B-125 — a `//` comment after a block's tail expression is a parse error

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

Found by B-123: a line comment after a bare tail expression with no `;` (`a` then `// last` then `}`) is refused "this
token cannot appear here", in a function body and in every block form.

- [x] a comment between a block's tail expression and its `}` parses, the tail stays the block's value on every backend, and the formatter keeps it (`block_tail_comment`)

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
the general rule (353's second compile goes; no catalogue is read at build, 665); 14s8-d's option (b) falls out. What
stays refused: a value cycle, a `comptime` depending on itself, a decorator reaching what it annotates, a `.hooks`
reader adding a member.

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
      — `tests/cli_contract.sh` C8: `migrate` and `migrate --dry-run` answer `unknown command: migrate`, `src/` untouched
      (red on the base); no doc names the command; the pipeline's next completed green `test` run left

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
- [ ] measured (B-61's quiet machine): rakun-stylesheet's conformance and one cell repeated, cold and warm, without and with
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
module-level `val` a ref at run time); per block the decorators run over the bodies, then their meta is filled (no
catalogue is read at build, 665); `src/internal/` is private to its package; the only order refusal is a located
`dependency loop`. In order:

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
- [ ] decision 582: `import {a.b}` always binds the namespace `b`, callable as the module's default (`namespace-not-a-value`
      without one); `module-item-collision` for an item and a module of one name; `import pkg;` ≡ `import {pkg} from "pkg"`,
      the package's default that of `src/<pkg>.bp`; `expandImports` (`default_fn.zig`) and the "prefix symbol wins" rule
      go; cells: the callable namespace on four targets, the two refusals; `docs.md` § Imports
- [ ] Conformance step (459, 474, 477, 478, 480)
- [x] a folder is not importable: `import {io} from "std"` / `import {collections} from "std"` refused, located, naming the leaf; `comptime/std_namespace.zig` deleted; cell `folder_import_refused` (decision 919, 110 (2) amended) — landed (`folder-import`, the leaves in the hint;
      `std_namespace.zig` keeps 111's module-namespace rewrite, its folder half removed — the file goes once that rewrite moves to
      `mod_namespace.zig`; `collections` is a module, not a folder, so nothing refuses it)
- [x] an import of another package's `src/internal/` refused, located, std's included (`import {internal.unicode_tables} from "std"`); cell `std_internal_import_refused` (decision 913)

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

- [ ] per block: headers, bodies, every decorator over them, then every `compiler.typeInfo(X).meta(T)` (`?T`; `metaAll` the
      list, 727) of the block filled — 130-s8-c's step 4, per block (592 (5))
- [ ] a `comptime` needing a meta or a value of its own block before its decorators ran refused, located, as a
      `dependency loop` (592 (5), (6), 728)
- [ ] 419's and 14s8-d's refusals and 353's second compile removed; `typeinfo-meta-hooks-pending` and
      `typeinfo-all-hooks-reader` gone
- [ ] cells: `home.bp` ↔ `blog.bp` each reading the other's `Route`; the comptime loop refused
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
- [ ] each library (rakun-stylesheet, query, rakun-bpp, rakun-ssr, rakun, actions, http, log, routing, validation, css, rakun-style, snap,
      json, yaml, markdown, rakun-data, vscode-extension's botopink sources): `src/root.bp` / `src/lib.bp` and every
      `mod` / `pub mod` removed, decorators and templates (`#[route]`, `#[page]`, `html`, `css`, `styled` …) moved to
      `src/comptime/`, private modules to `src/internal/`; each library's gate green
- [ ] the specs and `AGENTS.md` files that name `root.bp`, `lib.bp` or `pub mod` updated
- [ ] Conformance step (459, 474, 477, 478, 480)
- [x] `libs/std/src/unicode_tables.bp` moves to `src/internal/unicode_tables.bp`, `unicode.bp` writes `import {internal.unicode_tables as tables};`, the generator's output path with it (decision 913)

### B-76 — the module-model group's Conformance step

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet · **After:** B-69 … B-75

- [ ] botopink-lang's and every library's gate with conformance, cold and warm; every cell green on every target
- [ ] the root `conformance/docs.md` rewritten for the module model (480)

### B-98 — a `.bp` and a `.d.bp` of one stem in a package's `files` are one module written twice

**Repository:** botopink-lang (`--lang`) · **Model:** opus

Found by 165 s5: once a program using package `rakun` was refused for any reason, every dependency module reported
"`Module` is declared `pub` by `rakun/rakun` and by `rakun/rakun`". Measured: a module named like its package is one
module; the cause is `files` listing `rakun.bp` beside rakun's empty `rakun.d.bp` — both strip to the stem `rakun`, load
as two modules of one path, and `crossModule.buildIn` counts both.

- [x] two `files` entries of one stem refused at the second ("`"files" lists p.bp and p.d.bp, one module (`p`) written
      twice — keep one of the two files`"), as `x.bp` beside `x.bpp` and `x/mod.bp` already are; a dependency
      manifest's refusal printed relative to the working directory — cells `files_one_module_twice` (red on the
      parent) and `module_named_like_its_package`; a manifest unit test · question B-98-a (refuse or merge)

### B-99 — a library's catalogue read at the caller: `rakun.boot()` (mono-a)

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** B-86 · decision 551

165's plug-and-play spells `rakun.boot()` in the program's `main`: a library function whose body reads
`@TypeInfo.all(with: rakun.module)` and `@TypeInfo.all(with: rakun.config)` **of the program it is called from**,
judged at build (the start order, the two build errors). Measured: a library function's `@TypeInfo.all` is the
library's own build; a template needs at least one argument and takes only literal strings; a catalogue spelled
inside the code a template builds (`e.build("… @TypeInfo.all …")`) answers empty; a namespace-qualified template call
(`rakun.plan "…"`) is refused ("expected Expr, got string"); one `@TypeInfo.all` cannot mix functions and vals
(`typeinfo-all-mixed`). The nearest form today, `boot(plan "app", @TypeInfo.all(with: plug.module),
@TypeInfo.all(with: plug.config))`, puts the catalogue in the program's hands.

- [x] decision 551's form: a `comptime` parameter whose default is a `@TypeInfo.all(…)` query answered for the program
      the call is compiled in (353's collect / answer / staleness / level-B paths; the names resolved in the declaring
      module; legal only in the package's root; the explicit arguments still accepted)
- [x] a cell: a library's `boot()` with no argument listing the program's `#[m]` declarations of every package
      (`typeinfo_all_default_at_caller`; the refusal `typeinfo_all_default_outside_root`, the explicit override
      `typeinfo_all_default_override`)

- [x] decision 562: a function whose every parameter is `comptime` and whose body reads one's `.value` is expanded at
      its call site (one run-time parameter → never expanded, 376 (1) as before: `Stage.Build`, `build-and-run`) — its
      loops, conditions, `val`s and build-data reads run at build; each statement reaching a run-time value emitted at
      the call site in order, build-known parts as constants; a loop bound or condition needing a run-time value refused
      `run-in-build` at it; a `.value` read no longer makes an all-`comptime` function `Stage.Build`; a field, a string
      hole or an element of a run-time variable passed refused `comptime-arg-not-known` (`comptime_expand_boot`, three
      modules started in `meta` order on every target, the order read from the program's output;
      `comptime_expand_banner`, `comptime_expand_constant_at_build`, `comptime_expand_condition_run_time`,
      `comptime_expand_runtime_argument`; the `stage_*` cells give their `Build` function a run-time parameter)
- [x] an expanded function from another module: its types (private ones included), private functions and namespace
      imports resolved as in its module in the emitted code, a caller's own type of the same name refused
      `import-name-collision` at the call; a refusal in that code located in the declaring module, the call as its
      called-from frame (`comptime_expand_library_names`, `comptime_expand_library_type_error`)
- [x] `d.value` in an expanded body — withdrawn by decision 581: 576 (7) removed `Declared<T>` and `.value`; a handle inside
      an executor is its declaration at run time, typed (B-137's cell `compile_executor_handle_typed`)

Nothing open here: the caller's catalogue is overtaken by 664 and 665 — a framework's `boot` is a plain function over the
run-time registry, `pub fn boot(modules: Module[] = registry.modules()) -> App`; B-99-c is closed by 694 (no catalogue
default), B-99-e by 695 (the caller's argument, as built).

### B-136 — the keyword `compiler`, `comptime` / `syntax` on a parameter, `type<T>` (decision 575 (3), (4), (5); 576; 577; 578)

**Repository:** botopink-lang (`--lang`), then the consumer commits (165 s10 for the libraries) · **Model:** opus (the
decision's first build; its cells' answers decide language versus defect) · **After:** nothing — opens now (§ Machines
rule 9)

The first step of the builtins group: a build-time body talks to the compiler through one keyword, and a parameter's
modifier says how its argument arrives. Every later step of the group writes its std bodies against this.

- [x] the keyword `compiler` (lexer, parser): in a body that runs at build — a decorator, a template, a function called
      at build, a `comptime` block — the `Compiler` of that point, the annotated declaration in a decorator, the call
      site elsewhere; a `Build` resource (376 (1)); `compiler-at-run-time` in a run-time-only body; never a parameter
- [x] `libs/std/src/compiler.bp`: the behavior `Compiler` with the members 575 (3) lists but `compile`, `implement`,
      `setBuiltin`, `embed`, `record`, `fields`, `optional`, `required` (B-137 … B-140's); a unit test holds the
      compiler's table of members to the file; `comptime.zig`'s `decl_reflection_src` mirror, `Decl<T>` and `Declared<T>` go (576 (7)); `addMember` keeps only 370 (2)'s typed form (`decorator-member-not-one-fn` goes)
- [x] `comptime x: T` holds the value (364 (4) reverted); `syntax x: T` the tree, opaque; a decorator's first `syntax` the
      annotated declaration, checked against the parameter's type (280 (2)); `-> syntax T` a template's return, spliced
      at the call; an `syntax` argument to an `syntax` parameter hands its tree on; `@Expr<T>`, `.value`, `@expr` go
- [x] the tree rule: run-time code (resolved where written, 384), `syntax` (spliced), `comptime` (parameters and the
      body's `val`s, literals); `syntax-captures-build` (withdrawn by 614: `compiler.*` inside a tree is folded at build); `syntax-call-outside-syntax`
- [x] `type<T>` parsed in a type position and bound by a type argument; `type T` goes at its seven sites;
      `@typeInfo(city)` with a value refused; `type(` / `type {` unchanged
- [x] the parameter modifier `syntax` goes (the maintainer, 2026-10-17): the keyword, `ParamModifier.syntax`, the post-colon `syntax` of a parameter and the `FnType` form kept only for it; `syntax` holds its meaning; no `.bp` writes it; `syntax` is an ordinary name after it
- [x] decision 576: `Expr<E>`, `@Expr`, `Decl`, `@Decl` removed whole; the `Expr` members and the template model (`parts`, `source`, `context`, `lookup`, `bindings`, `build`, `note`, `fail` with a span, `tagDecl`, `annotate`, a declaration handle's reads) as `compiler.*`; `@ExprCustom<T>` → `-> syntax T` with `compiler.custom(ast)`; `Span`, `Part`, `Source`, `ExprContext`, `CustomNode` in `compiler.bp`; the codemod's rewrites (576 (6)); the cells of 275, 302, 415, 426 unchanged but for the spelling
- [x] decision 576 (8)–(12): the other declaration reads as `compiler.<r>(d)`; `compiler.addMeta` / `wrapWith`; a decorator is a function whose first parameter is `syntax`; the string `setMeta(key, value)` and its readers removed, std's and `conformance/`'s sites on typed meta records by hand; a meta field written `@Expr<T>` written `T`
- [x] decision 579: `compiler` not a keyword — `#[builtin] pub default declare val compiler: Compiler;`, the default of `compiler.bp`; `import {compiler} from "std";` outside std, `import {compiler};` inside; the rules read off the binding; `compiler-escapes`; the codemod adds the imports
- [x] decision 579's rest: `import {compiler};` is std's `compiler` only when the importing package is std — another package's own module named `compiler` is that module (resolved where the package is known, not by spelling); std's `compiler.bp` left out of a program's run-time output (no run-time code); a local named `compiler` in a module that imports it shadows the import, as any binding does
- [x] decision 578: no `-> expr`; a template is marked by its `syntax q: string` first parameter (after an `expr self` receiver for a template method) and returns `T`, `anyvalue` or `anytype`; the bare `type` renamed `anytype`; `compiler.build -> anyvalue`, `compiler.buildType -> anytype`; `anyvalue-outside-template`; the codemod's respellings
- [x] decision 577: the template text `` @`…` `` (lexer: multi-line, raw, `` \` `` its one escape); a template takes it alone and is called only as `` name @`…` `` or `` #[name @`…`] ``; any other call `syntax-call-outside-syntax`; any other template signature `template-signature`; `Part` / `compiler.parts` removed; the codemod's rewrite, the rest by hand
- [x] decision 576 (7), (15): `compiler.catalogue` answers declaration handles read at build through `compiler.*` (comptime_expand_boot, typeinfo_all_duplicate_at_entry, template_reads_program_catalogue's `named=` line restored); the hooks model's `fn` / `callee` / `context` handles — `Declared<T>` and the run-time `@TypeInfo.all` go in B-137
- [x] decision 576 (13): `compiler.bp`'s types imported, no prelude names; the codemod adds the imports
- [x] the codemod (`scripts/codemod/`): `comptime x: @Expr<T>` → `comptime x: T` where the body reads only `.value`
      (the read dropped), `syntax x: T` where it hands `x` on or reads its syntax (`.text()` → `compiler.text(x)`,
      `.fail(m)` → `compiler.fail(m, at: x)`); `@expr(v)` → `v` with `-> syntax T`; `comptime decl: @Decl` →
      `syntax decl: unknown`, `decl.name` → `compiler.name(decl)` (a `string`, 612), `decl.fail(m)` → `compiler.fail(m, at: decl)`,
      `decl.setMeta` / `addMember` / `addType` / `wrapWith` → `compiler.*`; run over std and `conformance/` here, over
      the libraries by 165 s10 (482 parameters, 605 `.value` reads, 29 `@expr`, 7 `type T` measured on 2026-10-16)
- [x] cells: a decorator with the three parameter kinds, read at build and spliced; `-> expr` template; a `type<T>`
      parameter; the three refusals; every `decorator_*` / `template_*` / `comptime_*` cell's answer unchanged but for
      the spellings the codemod rewrites, each stated
- [x] `conformance/docs.md` § Decorators, § Templates, § Builtins rewritten to the new spelling; the compiler's
      `AGENTS.md` files

Oracle: `zig build test`; the cells; `scripts/gate.sh libs` on the main checkout once 165 s10 lands.

### B-145 — an annotation that names no decorator is dropped silently

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro; the code is the step's)

Found by decision 582's build: a bare `#[name]` whose `name` resolves to no decorator — unbound (`#[nope]`), or a
namespace (`#[check]` where `check` is a module) — is dropped without a word and the program builds; `unknown-annotation`
covers only the `#[@Family]` forms.

- [x] such an annotation is refused at the annotation, located, naming what `name` is (nothing, a namespace, a value);
      a refusal cell per kind, red on the parent; no library site measured to rely on the silence (each found, listed)
- [x] `#[m.missing]` through a `pub mod` namespace is refused too: a `pub mod` publishes no export list to the checker today, so only an imported module's missing segment is refused (`annotation_dotted_missing_in_import`) — closed: the `pub mod` namespace is retired (592 (1))

### B-146 — three checker defects found by 165 s5

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (measured; repros in rakun's `AGENTS.md`)

- [x] a decorator body that reads `compiler.catalogue(with: …)` (`compiler.find` after B-137's package) makes every importer of its module fail `typeinfo-all-imported`; only a template body is exempt, yet 551 says a catalogue read in a dependency answers for that dependency alone — a cell red on the parent
- [x] `#[m(lifecycle: .Manual)]`: the dot shorthand in an annotation argument whose parameter is an enum is refused as a type mismatch (`Lifecycle.Manual` passes) — a cell red on the parent
- [x] decision 667: `v is T` with `T` a type parameter refused at the test · decision 757 (a): a copy per type argument, `t` the type inside it — the run-time test function built in its place is replaced; cell `comptime_type_token_handed_on`
- [ ] decision 758: `t: type<T>` without `comptime` is a run-time type value (603's identity, as 631's `Field`), one function, `t` handed on as any value, `x is t` at run time by the literal test's rules; `is-type-parameter`'s message names both forms; cells `type_token_run_time_value`, `type_token_handed_on_run_time`; the backends' value and `is` helper are machine 2's half (its README § After the group), `is-type-parameter`, naming the parameter and the way out; `v is t` with `comptime t: type<T>` the concrete test in the specialised copy (417) — cells `is_type_parameter_refused`, `is_comptime_type_parameter` on four targets; and the sibling defect: in a generic body `v is fn() -> T` makes the caller's `T` `unknown` — a cell red on the parent
- [x] an imported generic function called with an explicit type argument (`resolve<Box>(…)`) is refused "`resolve` takes no type arguments, 1 given" — found by B-146; a cell red on the parent
- [x] a decorator argument's enum value read at build by its bare type name: with a second same-named enum anywhere in the program (another dependency or the annotating module), `#[kit.m(lifecycle: .Manual)]` checks and the decorator body runs with the wrong variant (`Eager`) — `decoratorArgValue` re-reads the argument as source and `blockEval.typesReached` resolves types by name; the value must carry the parameter's type identity (module + name, 603) — a cell with two `Lifecycle` enums red on the parent

### B-152 — a type parameter is bound by a parameter, never by the return type alone (decision 668)

**Repository:** botopink-lang (`--lang`) · **Model:** opus (a checker rule reaching std, the cells and every library) · **After:** B-146 (667's `is-type-parameter` and its cells share the generic-body analysis)

- [x] (decision 757 (a): the copy per type argument makes the token known at build, so `async.failed` and `type_parameter_bound_by_token` go green with it) the checker: a function's, a method's or a lambda's type parameter that occurs in no parameter's type — directly, inside a type (`Array<T>`, `fn(T) -> R`, `Self<T>`), or as `comptime t: type<T>` — is refused at the declaration, located, `type-parameter-unbound`, naming the parameter; the return type is never a binding site; cells `type_parameter_unbound` (reject), `type_parameter_bound_by_token` (`failed(comptime t: type<T>)` on four targets), `type_parameter_bound_in_lambda_type`
- [x] std's 13 sites (668's list) migrated: a `comptime t: type<T>` where the caller names the type, `Self<Array<E>>` where the receiver carries it, `unknown` where no type is meant; `conformance/docs.md` § Generics states the rule
- [x] botopink-lang's 11 cell sites migrated, each stated; the libraries' 41 sites listed by file for 165 s10 (rakun, its cells), 145 (query) and 146 (validation) — the gap rows filed, the migrations theirs

- [ ] a body copied per type argument into the calling module (757) reaches the std functions it uses without the caller importing them (`print` in a copied body today needs the caller's import); cell `comptime_type_token_copy_uses_std`
- [ ] a caller's type method that hands its `comptime t: type<T>` on to an imported function gets that function's copy too; cell `comptime_type_token_handed_on_from_method`

Oracle: the cells; `zig build test`; `test-libs` once the libraries' sites are migrated.
- [x] `compiler.meta(d, M)` / `compiler.metaAll(d, M)` the one spelling (decision 840): the parser's `<M>` rewrite removed, `compiler.meta<M>(d)`
      the ordinary missing-argument refusal; 30 std and cell sites respelled, rakun's 11 listed for 165 s10; cell `compiler_meta_called_as_declared`
      (run, four targets; red on the parent) — landed (the cell under `compiler_meta_called_as_declared-840/cells/meta_called_as_declared`,
      a template reading both; rakun's sites listed in 165 s10)
- [x] a refused cell for `compiler.meta<M>(d)` (the ordinary missing-argument refusal, 840), red on 840's parent — landed
      (`'meta' expects 2 argument(s), got 1`, the `arityMismatch` every call gets; case `meta_generic_spelling` under 840's `refused/`)


### B-153 — a template answering `Component<X>` refused as built outside its bound

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (a measured repro)

Found by 150 s34: `pub default fn styled(syntax css: string) -> Component<Styled>` whose built code calls `fn mk() -> Component<Styled>` is refused at every call `template-build-outside-bound: styled built code of type Styled, outside its answer Component` (`finishExpansionBuilt` compares the declared answer with the built code's unwrapped type). Written through an alias (`StyledView = Component<Styled>`) the check was skipped; 661 removes the alias.

- [x] a template's built code of type `Component<X>` is inside an answer `Component<X>`; the bound compares the declared answer with the built code's type as written — a cell red on the parent, and a refusal cell for a real mismatch (`Component<Y>`)

### B-159 — a top-level `comptime { … }` block (decision 788)

**Machine:** 2 (the `compiler.load` chain, 785) · **Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** nothing

Decision 788: a module may hold top-level `comptime { … }` blocks — build bodies run once per build in the order written; a
function whose every parameter is `comptime` is called there and expanded at the call (139), no `comptime fn` form.

- [x] the parser takes `comptime { … }` at module level; the checker types it as a build body (`compiler.*`, `val`s known at build,
      calls expanded at build, `print`), a run-time effect `run-in-build`; it declares nothing outside itself
- [x] the blocks run in the order written, the modules in their build order; each `compiler.init` registered there runs at program
      start in that order (632)
- [x] a `print` reached there is written to stdout as the build phase's output (789 (2) — the CLI's own messages to stderr)
- [x] cell `module_comptime_block` (788): two blocks, an expanded `fn f(comptime n: string) -> void` called from each, their
      build prints and their init bodies' run prints in order, on every target
      — built as: the block rewritten by the parser into a decorator with an anchor `val`, so it runs on the decorator build-body
      machinery and `compiler.init` is that decorator's executor; a private function whose every parameter is `comptime` and that
      writes `compiler.init` expanded at each call and left out of the program; `setMeta` / `addMeta` / `addMember` / `addType` /
      `implement` in a block refused `compiler-output-outside-decorator`; a build body's `print` (it never worked before) goes to
      stdout as the build's output, kept by the level-B cache and replayed on a cached build, the CLI's own messages on stderr; the
      build lines asserted in `comptime/tests/comptime_blocks.zig` until B-160 records them
- [x] a refusal inside a block names it as `comptime`, not the decorator it is rewritten into (`__bp_comptime_<k>`)
      — built as: "the `comptime` block raised"; cell `block_refusal_names_comptime` (788's directory)
- [x] a `return` or a `throw` inside a block refused, located (793 (1)) — built as `comptime-block-exit` at the statement; cell
      `block_return_refused`, the `throw` and a lambda's `return` in unit tests
- [x] a block in a library package runs in the build of the package that uses it, in 660's level order (793 (2)) — already true;
      cell `library_block_level_order`
- [x] a `pub` function whose every parameter is `comptime`, called from another module's block, expanded at the call (793 (3)) — today
      refused `compiler-output-outside-decorator` in its own module; the expansion runs in the parser over the module's own functions; a
      design step: the `fable` plan is written (the expansion in `analyzeSource` after the imports resolve, the function leaving its own
      module's program); its open points answered by 808
      — built as: the call expanded in `analyzeSource` after the imports resolve and before inference, the body copied with 562's
      Copier (its names aliased), its `compiler.init` the block's executor; cell `block_calls_other_module_pub` (793's directory)
- [x] 808: such a function expanded wherever it is called — in its own module type-checked with `compiler.init` typed `void` and
      left out of the program; a run-time call (`main`, another module's function) and a `comptime { … }` inside a function body
      write the executor's body where the call is; only a top-level block makes it a program-start init; a decorator body's call
      still refused; cell `comptime_init_at_call_site` (the order `antes`, the case, `depois`; a call under an `if` not taken)
      — built as: `compiler.init(f)` typed `void` in such a function, which leaves the program, `pub` included; a run-time call and a
      body `comptime { … }` write the executor's body in place; a call from a decorator, a template or a value-answering `comptime`
      refused `compiler-output-outside-decorator` at the call; cells in `comptime_init_at_call_site-808/` (`run/`, `refused/`,
      `cells/init_at_call_other_module`), the build lines in `comptime/tests/comptime_blocks.zig`; 615's
      `init_output_outside_decorator` rewritten with a run-time parameter, its refusal unchanged
- [x] a function whose every parameter is `comptime` is expanded at its call also when its body only forwards a parameter to another
      such function (`fn twice(comptime n: string) -> void { inner(n); inner(n + "!"); }`; 562: never specialised, no run-time body) —
      today `transform.zig` `trySpecializeCall` copies it (`hooks.isExpandedFn` misses a body that only forwards), erlang refusing the
      build (`inner/1` undefined) and wasm the call; cell `comptime_parameter_call_expanded-562/cells/expanded_fn_forwards_parameter`,
      red on the parent, green on the four targets
      — built as: `comptime.zig` leaves out of the transform's `fn_decls` every function `isExpandedFn` answers for on the body the
      checker reads (the transform's copy had its `.value` reads erased), at both sites that build it
- [x] a function-body `comptime { … }`'s `print` is one build line per build also in a module that holds a top-level `comptime` block
      (788 (2), 793 (5), 789 (1)): the spliced re-analysis must not run it again (and, checked with it, the top-level block's own `print`
      and `compiler.init` registration); unit test `body_block_prints_once_beside_top_level_block` in `comptime/tests/comptime_blocks.zig`,
      red on the parent
      — built as: `Env.buildRuns` records each `comptime` node's output range and `keepPassOneTraces` drops from the second pass each run
      the first already printed, matched by text one for one; the top-level block's `print` and `compiler.init` were not re-run
- [x] 808's refusal at the call from a template's body and under a value-answering `comptime` (575 (3), 376 (2)) gets its cases
      (458 (2)): `comptime_init_at_call_site-808/refused/src/cases/init_at_call_from_template` and `init_at_call_in_value_comptime`
      — built as: both already refused at the call on the four targets; the cases and their snapshots added
- [x] a cached build replays the build output (793 (4)) — a unit test in `level_b.zig` (a dependency read back from the cache replays
      its block's output), no cell: `cell check` records no build line (796)
- [x] a `comptime { print(…) }` inside a function body writes its print as build output (793 (5)) — a unit test (796); a `void`
      block leaves nothing in the program
- [x] cell `module_comptime_block_rules` (793): the cases of (1) and (2); (4) and (5) unit tests (796), (3) with its box
- [x] the language server on an expanded private function (hover, go-to), which leaves the parsed program — hover built, go-to
      already worked; tests for both

### B-158 — `compiler.load(path)` answers a file's refusals at build (decisions 780, 782, 783)

**Machine:** 2 (decision 785 — machine 1 does not open it) · **Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** nothing

Decisions 780, 782, 786: `load(comptime path: string) -> Result<Module, Refused>` (786; was `Result<void, Diagnostic[]>`), a `Build` member of `Compiler`, compiles a file
of the package at build as the entry of a package of its own and answers `Ok` when it compiles, `Error` its refusals (never
empty), read with `try … catch` / `try` (783) — never through `attempt`; no `compiler.snapshot`.

- [x] `compiler.bp`: `Diagnostic(code, message, file, line, column, label: ?string)` and `load` in `Compiler`; its row in
      `parser/compiler_surface.zig`'s table, held by `comptime/tests/compiler_members.zig` (616)
- [x] the handler beside `inferEmbedBuiltin` (`comptime/infer.zig`): `embed`'s path rules and reader, `load-no-reader` on a
      build with no reader; a path refused at the argument as `load-path-absolute`, `load-path-outside-package`,
      `load-file-missing`, a file that loads itself `load-cycle` (codes no decision names — chosen with the build)
- [x] the loaded file registered as a build input (519): level B's key covers files under a library's `src/`, a loaded file
      outside `src/` is not in it
      — built as: a dependency's reader records every path it reads, written `<pkg>.inputs` beside its level-B entry, and the next
      key hashes those files by content (`code_cache.closureKeyReading`); a test beside `@embed`'s in `analysis_equivalence.zig`
- [x] the nested compile (`comptimeMod.compile`, as `comptime/tests/located_errors.zig` runs it) captured — never through the
      CLI's reporter — and guarded against re-entering std's one-time initialisation (`comptime.zig`'s init-once caches)
- [x] the loaded file is its own package's entry for the build's target: its `mod` tree beside it, the caller's manifest, never the
      caller's module graph; a path outside the package, absolute or missing is refused at the argument, located
- [x] cells `compiler_load_answers_diagnostics` (780), `compiler_load_answers_result` (782) and `compiler_load_try_catch` (783,
      the refusals handled by `try … catch` and propagated by `try`), front 166's shape: a refused
      file's `code`, `message`, `line`, `column`, `label` printed from `try comptime compiler.load(…) catch { ds -> … }` (783); a file that compiles answers `Ok`; the
      refusals on every target · green on erlang, commonJS and wasm; the three answer cells red on beam (the `try … catch` defect below)
- [x] beam refuses `try f() catch { e -> … };` over a `Result<void, E>` (`get_tuple_element` `bad_type`), with or without
      `compiler.load`; the three answer cells green on beam · fixed (`beam_try_catch_result_void`)
- [x] 595 (7) enforced: a `catch` with no `try` in its region is refused `try-region-cannot-fail` (today `f() catch …` compiles,
      and `fs_file_defer_close` relies on it — rewritten with `try`); then the cell of 783's refusal (`comptime compiler.load(…)
      catch …` with no `try`)
- [x] 786: `load` answers `Result<Module, Refused>` — `Module(name, path, target)`, `Refused(module: Module, diagnostics:
      Diagnostic[])`; `compiler.bp`, the surface table and its test, the handler, the three `compiler_load_*` cells' readers
      (`catch { r -> … r.diagnostics … }`) and cell `compiler_load_answers_module` (786: `name`, `path` and `target` printed, and a
      refused file's `r.module.path`)
      — built as: `target: Target`, the prelude's enum (`Node`, `Typescript`, `Erlang`, `Beam`, `Wasm`), added to the std modules'
      reflection source and spliced as a private enum into a module that loads (the prelude enum has no run-time declaration), a
      beam build answering `Target.Beam`; the cell prints that the `Ok` and `Refused` modules carry the same target, the variant
      itself held by a unit test (a per-target value has no place in a cell); green on the four targets, beam included
- [x] a module that declares its own `Target` and loads sees `Target.<V>` resolve to its own type and is refused — the spliced enum
      under a name no source can write; a cell, red on the parent
      — stale since 805 (4) removed the spliced enum; cell `compiler_load_own_target_type` (786's directory) proves it, four targets
- [x] 787: `Module.run()` — `fn run(self) -> Result<void, Failure>` on the `Ok` side (`Error` when the loaded `main` crashes); a
      loaded package whose `run` a `compiler.init` body calls is compiled into the program as a package of its own (its `mod` tree,
      its own dependencies) and its `main` called at that point; one no `run` reaches stays out; `run` outside an init body and a
      loaded file with no `main` refused, located; cell `compiler_load_module_run` (787: the init body's prints around the loaded
      `main`'s, and a crashing `main` answered `Error`, on every target) · after the 786 box; a design step — the `fable` plan's open points answered by
      792 (`Error(Failure)` on a `main`'s `Error`, the body run at `run()`, `Module` opaque, three codes)
      — built as: `compiler.load` also in a top-level `comptime` block and a decorator body, the captured `Module` written into the
      init body; `m.run()` answered by the checker (`run-outside-init`, `run-module-refused`, `load-no-main` at the call; a receiver
      not traced to a loaded `Module` is `run-outside-init`); the program compiled again with each file a `run()` reaches as package
      `bp_load__<path>` until none is new; commonJS requires the loaded package at the call, erlang and beam run its inits first; a
      `Module(…)` written by hand refused `module-construction`; a second `run()` runs `main` again and the body once; cells
      `compiler_load_module_run`, `run_outside_init`, `load_no_main` (787) and `module_run_body_at_run`, `module_run_twice`,
      `run_in_called_function`, `run_module_refused`, `module_construction` (792), green on commonJS, erlang and beam; wasm in
      B-155
- [x] `compiler.bp` declares `fn run(self) -> Result<void, Failure>` on `Module`: a method signature of an imported type resolves its
      names in the importer, so `Failure` is unknown there and `run` is answered by the checker; cell
      `imported_type_method_signature_resolves_in_owner` (a type whose method returns a type only its own module imports, called
      from an importer), red on the parent; then `compiler.bp` writes the signature
      — built as: `compiler.bp` declares `pub fn run(self: Self) -> Result<void, RunFailure>` (806), the checker's lowering unified with
      it (`declaredModuleRun`); the cell passes on the parent too — an imported user type already brings its signature's types; the
      failure is std's alone (below)
- [ ] a std type's field or method naming a type its module imports from another std module is `unknown type` (`infer.zig`
      `markStdImports` looks only among the module's own declarations); no std module does it today; a unit test, red on the parent
- [x] a local alias of the captured `Module` in the init body (`val m2 = m; m2.run()`) runs `main`: today `load.receiverPath` knows
      only the spliced load, and the alias is refused `run-outside-init`, a code 792 (4) gives to a place; a receiver still not traced
      to a loaded file refused under a code of its own; cell `run_on_module_alias`, red on the parent
      — built as: `load.zig`'s `withRunImports` runs an alias pass first, a `val` bound to a traced receiver (the spliced load, a
      `Refused`'s `.module`, another alias) rewritten to it, a `var` or a lambda parameter of the name hiding it; an untraced receiver
      refused `run-module-untraced` (a code no decision names — chosen with the build)
- [x] 789 (4)'s `val mod = try comptime compiler.load(…) catch { r -> compiler.init({…}); return; };` inside an expanded
      `runCase(comptime name)` takes the branch at build: the expander copies a `try … catch` as run-time code and a `return` ends its
      walk, so the `Ok` path stops too; `Error` → the handler's statements then stop, `Ok` → bind and go on; cell
      `comptime_load_try_catch_return_in_expansion` (a `fine` and a `broken` case), red on the parent — B-157 Piece 5's `main.bp`
      shape waits on it
      — built as: the expander is the parser's (`parser/comptime_blocks.zig`, 788), which expanded no body that leaves early;
      `liftCatchReturns` rewrites a top-level `[val x =] try e catch { r -> …; return; }` into `case e { Ok(x) -> { the rest }
      Error(r) -> { the handler } }`, so the body expands and the load is answered at build; the cell writes `val loaded`, `mod`
      being a reserved word (`reserved-word-as-name`); the case's build print is not recorded until 796's build records
- [x] decision 806: `run()` answers `Result<void, RunFailure>` (std's `RunFailure(kind: type { Failed, Abort }, message: string)`,
      `Failure` unchanged); nothing of the loaded package propagates (cell `module_run_contains_body_failure`); each `run()` re-initialises
      the package — `val`s, `var`s, body, executors — alike on every target, commonJS dropping its `require` entry, erlang and beam re-running
      `'_botopink_init'/0` whole; cell `module_run_twice_body` (a `_` statement, an executor and a `var` in the loaded file, `run()` twice)
      — built as: `run()` rewritten to a spliced `__bp_run(…)`, std's `attempt` over the loaded root's `__bp_loaded_main` (now
      `Result<void, string>`); commonJS drops the package's directory from the `require` cache, erlang and beam erase a loaded module's
      cached `val`s and ProcessDict `var`s before its init, wasm's loaded init has no run-once guard and sets each `var` from its
      declaration; std declares `pub type RunFailureKind { Failed, Abort }` for the field, an inline `type { … }` in a field being refused
- [x] erlang and beam: a loaded package's ETS and PersistentTerm `var`s are not reset at a second `run()` (806 (3)); a case in
      `module_run_twice_body`, red on the parent
      — built as: the loaded module's init empties a keyed `Ets` var and puts its seed rows back, and puts its `PersistentTerm` vars
      on each run (no longer by `-on_load` for a loaded module); cell `module_run_twice_beam_memory` (806's directory, erlang and beam)
- [ ] an inline enum in a record field — 806's `RunFailure(kind: type { Failed, Abort }, message: string)` — is refused by the parser
      ("write `anytype`"); std writes a named `RunFailureKind` meanwhile; a cell, red on the parent, then std writes the field inline
      — decision 832: the parser admits `type(…)` / `type { … }` in a record field beside a named type (both the language);
      `inline_types.zig` hoists it as `Bp__<Owner>__<field>`, 207's parameter type renamed `Bp__<fn>__<param>` (snapshots re-recorded);
      a return, a `val` annotation, a behavior member, a variant payload stay `inline-type-outside-parameter`, a nested one
      `inline-type-nested`; cells `inline_type_in_field_named_by_owner` (four targets, a cross-package `.Failed` in a `case`, two identical
      inline types two types, the nested one refused)
- [x] the comptime runtime refuses a `catch` binding inside an init lambda that shares its name with an outer `case` arm's binding
      (`Error(r) -> compiler.init({ -> try … catch { r -> … } })`: "the wat runtime does not take variable `R` used before it is
      bound"); a cell, red on the parent
      — built as: `member_fn.zig`'s Binder counts a `catch { r -> … }` binder and an `if (x) { b -> … }` binding as the executor's
      own, so an outer `r` is no longer spliced in; cell `init_executor_binder_shadows_local` (575's directory, four targets)
- [x] `botopink test` leaves a loaded file and its `mod` tree out of the package as `botopink build` does
      — built as: the `compiler.load` calls of `test/` modules scanned with `src/`'s (one helper for both), `build` and `check`
      unchanged; suite `conformance/test/compiler_load_in_a_test_suite/` (red on the parent, green on the four targets)
- [x] an aliased imported type in the signature of a function declared after its caller is refused `type mismatch: expected
      <Alias>, got <Type>`; a cell, red on the parent (the loaded module's helper is placed first to avoid it)

Oracle: the cell; `zig build test`. The suite's use of it (a `refused/` package as one program) is a later decision (780 (4)).

### B-165 — a record parameter on every callable; a `defer` body cannot fail (decisions 864, 866)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (the decisions fix every answer) · **After:** nothing

- [x] decision 864: `recordParamCalleeParams` reaches a method and an associated function; `rewriteRecordUpdate`'s name-only refusal
      deleted; cells `record_param_on_method`, `record_param_on_associated` (red on the parent), `record_param_generic`,
      `record_param_variadic_refused`, `record_param_default_refused` — landed (the cells under `record_param_every_callable-864/`, `run` and
      `refused`; `record_param_generic` written over `i32`, the wasm row below)
- [ ] wasm: a generic record parameter with a `string` field aborts (`fn show<T>(..p: Props<T>)` called `show(value: "x", label: "s")`);
      `record_param_generic` widened to the `string` field once green; red on wasm
- [x] decision 866: `refuseInDefer` gains `throw` and `try` (595's region check); cells `defer_refuses_throw`, `defer_refuses_try`
      (refused, red on the parent), `defer_try_catch_inside` (run); `defer_try_and_throw_propagate` removed — landed (cases of
      `modules/defer/`; `enterDefer` clears the try region)

Oracle: the cells, red on the parent; `zig build test`.

### B-164 — `comptime var`, a variable of the build (decision 807)

**Repository:** botopink-lang (`--lang`) · **Model:** opus (a declaration form across the parser, the checker, the comptime runtime and
every backend) · **After:** B-163's resolved program (the final value is folded there)

- [ ] the parser and the formatter: `comptime var name: T = v;` at module level; elsewhere refused as a misplaced modifier
- [ ] the checker: a run-time write refused `comptime-var-written-at-run`; a write from another package's build code refused
      `comptime-var-foreign-write`; `pub` read by importers
- [ ] the comptime runtime: one cell per variable across the build, written by blocks, decorators, templates and build-expanded
      functions in 660's level order and source order; the final value written as code into the resolved program (798) and the `.bpr`
      (805); a value that cannot be written (a host handle, an `Async` in flight) refused `comptime-var-not-writable` at the variable;
      the cached build keeping the final value (793 (4))
- [ ] cells on four targets: `comptime_var_build_variable` (two `#[get(…)]` incrementing a counter, `main` printing `2`), the three
      refusals, a `pub comptime var` read by an importer, the value equal after a cached build

Oracle: the cells red on the parent; `zig build test`.

### B-162 — a component call is its lambda; `use` resolves a component; the component model (decisions 791, 804, 809–821)

**Repository:** botopink-lang (`--lang`), then rakun for `NodeChildren` (165) · **Model:** opus (a semantic rule over every backend) · **After:** nothing

Decision 791: a call of a component only makes its lambda, in a component body too; a component is rendered by the tree (a
node's child, run from its `render()`) or resolved by `use c`, only inside a component body; `await` only over a call answering
`Async<T>`, in an `async` or a component body. 804 (2) removed `Renderable`: the language knows no tree node; the component model is
809's and 815–821's, below.

- [x] the call: `inferComponentCall` (`comptime/infer.zig`) stops typing a component call `R` and awaiting it in a component
      body; `val x: Component<Prop> = mk(2);` in a body written `-> Component<string>` accepted on every target (the 661-a
      repro, red on the parent); `context_lower.zig`'s and `env.zig`'s comments that cite the rendering rewritten — unblocks 150 s34
      — built as: a component call makes its lambda in a component body too, the implicit render in `inferComponentCall` removed;
      cells `component_call_lambda_in_body`, `component_resolved_by_use_or_tree`
- [x] `use c` over a component in a component body runs it with the body's children scope and answers its `R`; a `use` of a
      component outside a component body refused as a hook's is (553, 722); 410's rules of hooks for both; cells, the refusal one
      located
      — built as: cells `component_use_in_body` and the refusal outside a body
- [x] `await c` over a `Component<R>` refused at the `await`, located, `await-component`, naming `use c` or `c` as a child; the
      sites that awaited a component (std, the cells, jhonstart's `val tree = await view(props)`) measured and rewritten with
      `use` or as children, the libraries' listed for their fronts
      — built as: `await-component` at the `await`; cells `await_component_in_body`, `await_component_at_root`; every cell that awaited a
      component rewritten (`use` in a component body; `c.run(RenderScope.root())` in `main`, tests and plain functions); the
      library sites are filed in 150 s34 and 165 s11
- [x] 553's cells: `component_call_renders` with its children typed as a node or a component, `component_call_awaited` rewritten
      with `use`; the cell `component_resolved_by_use_or_tree` (791)
      — built as: the two cells follow 791, `component_resolved_by_use_or_tree` added
- [x] decision 804, first: a `fable` plan over the six `isComponentType` sites of `infer.zig` (the component body's flag, the `use`
      operand, `await-component`, `decl.hooks`, the children coercion) and 410's, 416's and 791 (3)'s rules, once no component / hook split
      exists; its open points filed as questions
      — done: the pieces are P1 the checker without the split (804-a, 804-b), P2 `Renderable` out, P3 the type form's `compose`,
      P4 `Children` retired (804-c), P5 rakun-style's list of components (804-d, 165 s11)
- [ ] decision 804 (1), (2): a type component's `render` renamed `compose` (the refusals with it, cell `component_compose_entry`) — (1) landed, its lowering since replaced by `implement Composable<Element>` with a `component fn compose` (809 (2), 828): cells `component_compose_entry` and its five refusals (question 804-e); (2) unblocked by 812 (809-c, which replaced 804-a; 804-b overtaken by 809; the split rests on `Renderable` alone), its codemod written;
      `Renderable` out of `primitives.bp`, the prelude's wrapper names and the language server's list; every `implement Renderable`
      dropped by codemod (std, the cells; rakun's sites in 165's commit)
- [ ] decision 804 (4) (its `NodeChild` respelled by 809 (7)): rakun-bpp's `NodeChild = Component<Element>`, `NodeChildren = NodeChild[]`, `Element`'s
      `children: NodeChildren` (165's commit in rakun; the cell `children/cells/children_for_walk` rewritten over `children: El[]` as
      `component_compose_entry-804/cells/children_array_walk`, `modules/children/` removed, 857); the compiler-known `Children` and its coercions retired here

- [x] `use view @`a`` (`use` over a template call) is not expanded and reaches the backends as `view/1`; a cell, red on the parent
- [x] a field read or a method call on a behavior-typed value (`Component<P>`, `Async<string>`) — `c.zzz` — is accepted silently; refused at the name, located; a cell, red on the parent
- [x] returning a `Component<R>` from a body that answers `R` (`return mk(1)`) is accepted where the types differ; it is a type mismatch; a cell, red on the parent
- [x] decision 810: `v is X<T>` accepted when `X<T>` is a member of `v`'s type with `T` bound through it (tested by `X`'s identity);
      narrowing by the flow (`else`, after a branch that leaves, a `var` until assigned); `case` type patterns over generic types,
      exhaustive over a union (`non-exhaustive`, naming the member); std's `resolve` written with them; cell
      `union_narrowing_flow_and_case` (the three forms, the forgotten member refused at its use and at the `case`), four targets
      — built as: the cells under `union_narrowing_flow_and_case-810/` (`run`, `refused`); a behavior marked at run time on every target
      (commonJS `prototype.__bp_b_<B>`, erlang / beam `'__bp_behaviors'/0` and `'__bp_implements'/2`); a `case` arm over a behavior an `if` chain;
      the code `non-exhaustive` prefixed on every exhaustiveness refusal, five answers re-recorded, cell `non_exhaustive_code` red on the parent (858); `is Async<unknown>` on commonJS only (823 settles the rest); the key unqualified (831, below)
- [x] decision 831 (810-c): a behavior's identity qualified by its module — the lowering carries `<package>@<path>@@<B>` with the declared name
      (`infer.zig`'s `behaviorDeclaredName` gains the owner path; `crossModule` indexes every `pub behavior`, not only one with a default fn);
      erlang / beam `'__bp_behaviors'/0` and commonJS `__bp_b_<atom>` emit the atom, wasm keys `behavior_impls` by it; marks follow `extends`
      (the checker's `behaviorReaches` chain) and an import alias; cell `behavior_identity_by_module` (two same-named behaviors of two modules,
      an aliased import, a subtype's mark), four targets, red on the parent — landed (`TypeDecl.behaviorMarks` from `infer.behaviorMarksOf`, each backend
      writing `crossModule.behaviorAtom`; an aliased behavior import stored under its alias, so `is` through it answers; `crossModule`'s
      index of every `pub behavior` not needed by this design)
- [ ] decisions 815–821, the component model as it stands (one box; each decision's cell written against this text):
      (1) `Composition<T> = fn(scope: Scope, key: Place) -> T | Async<T>` (815, 819); a one-parameter lambda, `{ _ -> v }` or
      `{ scope -> … }`, a `Composition` without hooks (815 (2), 819 (4)) — admitted by 888's trailing-parameter rule, cell `lambda_omits_trailing_parameters` (written `{ _ -> v }` as 888 (1) spells it); `_` a lambda parameter bound to nothing, any number of times (895); a function answering a member of a union fits where one answering
      the union is expected (returns only); `x.compose()` refused outside std's `resolve`; `{ component -> … }` refused where a `Component<T>`
      is expected, `component-lambda-not-component` (817 (3))
      (2) std's `Place` (a call's number and the item's, or a key: `Place.none()`, `Place.key(k)`, `Place.index(i)` (884, 891), `with`; the stamp's item half recording whether a body or a plain function counted it (891)) and `Scope` (`Scope.root()`,
      `scope.childAt(key)`, the parent's cell keeping `place → cell`, a place not met in a render dropped, a repeated place among siblings
      failing `key-duplicate`); every `component` body's lowering opening `scope.childAt(stamped.with(key))` (819 (1), 820 (2));
      `resolve<T>(c, scope, key)`
      (3) the stamp (820, 821): each written call answering a component — a `component fn`, a `Composable`'s constructor, a `component`
      lambda, a plain function answering one (the outer stamp wins) — and each function answering a component named as a value
      (`itens.map(Card)`) stamps its place, numbered within the nearest `component` body with the lambdas written in it, the item's counter
      in that body's cell and reset at each of its renders; a plain function's calls numbered within it, its counter reset at each entry;
      `use c` and the root pass `Place.none()`; the renderer's child list and `all` pass `Place.index(i)` (884, 891), an index filling a missing or a plain function's item half and keeping a body's count as it keeps a key; a value made outside every component body takes the root's place
      (4) every `use` that answers a value (a hook or a component) a call with a child cell at its place; `use provide` / `context` /
      `inject` taking none, the node's own cell holding its contexts alone, `memo`'s slot its own child cell's (818 (1)); a reused cell's
      contexts taken anew from the parent, only its hooks' slots kept (817 (5)); the render library keeping a mounted root, a root closed by its owner on the BEAM, else by its process (824); 771's `slot()`
      lowering (`hooks.bp`) removed (816)
      (5) `#[key(e)]` before an expression answering a `Component<T>` (818 (3)): the parser admits an annotation before an expression
      (`parseAnnotations` takes loop statements only today); `#[key]` before an expression answering no `Component<T>` refused, the code
      the builder's; `key-type` for a record or a function key
      — cells: `composition_function_again` (815), `hooks_state_by_tree_place` (816: a parent's re-render keeps a child's count,
      `if … A() else B()` resets, a type form keeps state), `cells_by_place_and_identity` (817: a reused cell reads the parent's new theme),
      `identity_by_call_and_key` (818: a branch change resets, a keyed reordered list keeps each item, `Mostra([1])` and `Mostra(["a"])` at
      two sites keep two cells), `composition_takes_its_place` (819: `if … Painel() else Login()` never shares, a keyed list called by hand
      keeps each item's, a repeated key fails), `place_written_by_the_call` (820: `val h = Header(); … use h` keeps `Header()`'s cell, a
      `Card(…)` keeps its state, a list reversed after it is made keeps each item's, a hand `Place.key` equals `#[key(…)]`),
      `place_numbered_in_component_body` (821: an unkeyed `map` keeps one cell per item, two lambdas' calls in one list never collide,
      `linha(a)` and `linha(b)` two cells, `itens.map(Card)` one cell per item); four targets
- [ ] decision 811: the `opaque` type modifier (`[pub] opaque type X(…)`, before `type`): the constructor written only in `X`'s own
      methods (`opaque-construction`), the fields read only there (`opaque-field`), a method without `pub` private to the module, of every type
      (814, 859: `method-not-pub` replacing `opaque-method`, `primitives.bp`'s methods `pub` by codemod, a behavior's implemented member
      exempt, an extension block of another module needing `pub` (886), an added member and `pub val length` `pub` (887); cell `method_private_to_module`, red on the parent); (`Composition<T>` is not opaque — 815); `Scope` opaque (`render-scope-construction` goes); cells, four targets
      — the modifier landed: `opaque` contextual before `type` (`opaque-construction`, `opaque-field`, `opaque-method`, `opaque-not-record`),
      cells under `opaque_type_modifier-811/cells/` (811-a answered by 829, as built; 811-b by 859); `Scope` opaque is B-162 P1's
- [x] decisions 859, 887 (811-b): a method without `pub` private to its module for every type, `method-not-pub` at the call naming the type,
      the method and its module (`opaque-method` gone); a behavior member the type implements and the lowering's marked calls exempt;
      `primitives.bp`'s members and their `comptime.zig` mirrors written `pub`, `.d.ts` the `pub` methods only; a member `addMember` adds `pub`
      — landed (cells `method_private_to_module-859/cells/` and `added_member_is_pub-887/cells/`; no library site reached; 886 landed with
      B-148; 859 (3)'s `Fn.of` names no declaration, `Module.of` stays without `pub` (830 (1)); question 859-a answered by 894)
- [x] decision 830 (811-c): the opaque checks' `byLowering` read from a mark on the call node (`opaque_types.zig`, `load.zig`), the 3,000,000
      line range gone; `reserved-name` at a call of a `__bp_` name (`reserved_names.zig`); cell `lowering_call_marked` (a program calling
      `__bp_load_module` refused, an adopted default body building an opaque type refused), red on the parent — landed (`CallExpr.lowering`;
      cells `lowering_call_marked`, red on the parent, and `adopted_default_builds_opaque`, a guard: the default body is refused at its own line on the parent too)
- [x] 811 (4) (with B-158's owner): `Module` opaque, made by a method without `pub` `compiler.load` lowers to, `mod.name()` /
      `mod.path()` for the fields; the cells and libraries that read `mod.name` / `mod.path` respelled
- [ ] ~~791-d (narrowing a union child)~~ — answered by 810; what stays is the run-time
      test: `k is Component<unknown>` is accepted but answers false on erlang — 809 (6) needs `is Composable<unknown>`, `is Async<unknown>`
      and `is fn(Scope) -> …` answering on the four targets; a cell, red on the parent
      — partly landed with 810: a behavior's identity and a function type answer on the four targets
      (`is_behavior_identity_run_time`); `is Async<unknown>` answers on the four targets (823; wasm landed with 164 s2)
- [ ] decision 823: `is Async<unknown>` answers whether the value is a task — erlang and beam `false` for every value (an `Async<T>` there is
      its settled `T`; what the backends emit today, now the rule); commonJS `instanceof Promise` (built); wasm a `ref.test` over `$task`,
      164 s2's row, landed; cell `is_async_answers_a_task` (a settled and a pending task `true` on commonJS,
      `false` on erlang and beam, `run` over a marked and an unmarked component answering on every target)
- [x] decision 809, first: a `fable` plan over 809 against what B-162 built (804 (1)'s rewrite of the type form into a record and a
      `component fn`, the `isComponentType` sites, `context_lower.zig`'s scope handling, std's `context.bp`); its open points filed as
      questions
      — done: P1 `Scope`, the three names, `resolve`, the run-time tests and `Renderable` out (after 810; 809-b, 809-e, 809-f, 809-i); P2 the type form
      respelled, `component_types.zig` removed (809-h); P3 a returned component resolved (809-c); P4 `Children` (804-c); P6 rakun (809-d, 804-d, 809-g)
- [ ] 809 (1), (5): `primitives.bp`'s compiler section declares `Composition<T>`, `Composable<T>` and `Component<T>` (826; `Scope` and `Place` in
      `context.bp`), the parser's wrapper names gaining `Composition` and losing `Renderable`, the checker's `Component` sites reading the
      three names nominally; cell `component_names_in_prelude`;
      `implement Component<…>` refused naming `Composable`; a `T` that is a `Composition`, a `Composable`, a `Component` or an `Async`
      refused where written; cells
- [ ] 809 (2), (3): the type form `implement Composable<R>` with `component fn compose(self: Self) -> Composition<R>`, the marker required
      (refused without it), `Card(…)` a value of the type; `component fn` lowering to a `Composition`; 804 (1)'s cells respelled; the codes
      828's: `implement-component-not-composable`, `component-compose-unmarked`, `component-scope-field`, `component-compose-called`,
      `component-arg-is-component`; `component-compose-missing` and `component-use-outside-compose` removed (58's and `use-without-component`);
      the cells of `component_compose_entry-804/cells/` re-recorded, `component_types.zig` and its codes removed; cell `composable_refusal_codes`
- [ ] 809 (4): a component body answering a `Component<T>` resolves it with a child cell (816 (6)) before it returns (`return div([…])`,
      `return Card(…)` with no `use`); cell, four targets
- [ ] 809 (6): std's `resolve<T>(c: Component<T>, scope: Scope, key: Place) -> T | Async<T>` (819), awaiting nothing inside, the one way a
      component runs (`use c`, an `await` only where the hooks list marks the node; the root); `x.compose()` refused outside std's `resolve`
      (815); std's `pub async fn run<T>(c: Component<T>, scope: ?Scope = null) -> Async<T>` (822: `resolve` with `Place.none()`, awaited only when
      it answers an `Async`; 825: with no scope it makes `Scope.root()` and closes it by `defer root.close()` (539)), every
      `await c.run(RenderScope.root())` respelled `await run(c)` by codemod (66 cells; rakun's
      roots in 165's commit); `run` reads `is Async<unknown>` (823), on wasm after 164 s2's `$task` test; typed by 810; cell `component_root_run`
- [ ] decision 827: std's `component fn all<T>(cs: Component<T>[]) -> Component<T[]>` lowered at the `use` (its cell at the `use`'s place,
      each entry `resolve(cs[i], scope, Place.index(i))` (884, 891), the answer an `Async<T[]>` only when an entry's is, 823's test);
      cell `use_all_resolves_a_list` (a keyed list keeps each item's count, a mixed sync / async list, four targets)
- [ ] 809 (8), (9): `RenderScope` → `Scope` (opaque, `root()` / `childAt(key)`, 819), a mutable cell over a persistent map keyed by the
      context's key type; `use provide` replacing its cell's map, `use context` reading the map received at entry; a `Composition`
      answers its value alone (`Rendered` goes); the hooks' state in cells (816, the box above); on erlang and beam the tree one process-dictionary entry per root,
      `root.close()` (`Closeable`, marking the root closed on the four targets, `scope-closed` after it, 825; off a root `scope-not-root`, 896) and `scope.detach()` (824; a seed whose tree starts per reading process and carries its start's ref into each cell, the cells failing `scope-closed` after that process's `close()`, the seed starting anew, no entry left, 897);
      cells `scope_tree_lives_with_its_process`, `root_closed_by_run` (a request on the BEAM leaves no `{bp_scope, _}` entry), `scope_close_off_root` (896), `detached_root_is_a_seed` (897);
      the codemod over std, the cells and the libraries (rakun's sites in 165's commit); 812: `use c` with a child cell at its place (818, 821),
      `return c` resolved with a child cell (816 (6)), `use provide` in the order written, `context-provide-after-render` removed; cell
      `use_child_cell_provide_in_order`
- [ ] 809 (7) (rakun, 165's commit): rakun-bpp's builders `component fn`s answering `Component<Element>`, `NodeChild = Component<Element>`,
      the renderer resolving every child; replaces the 804 (4) box's `NodeChild = Element | Component<Element>`; 813: a ready `Element`
      enters through `{ _ -> e }` (815; `{ component -> … }` refused, 817 (3)), the resolved tree a record of its own (`Rendered(tag, attrs, children: Rendered[])` in the
      decision's example), what `rakun-bpp-dom-test` inspects

Oracle: the cells, red on the parent; `zig build test`; rakun's gate for the `NodeChildren` box.
- [x] the cells `async_marked_by_hooks_list-375/cells/component_method_sync` and `component_default_fn_sync` abort on feat since B-116 P4 · fixed: a component method's marker goes with its lowered return (`context_lower.zig`); the answers unchanged
- [ ] the iterator helpers (596) on `Iter` / `AsyncIter` are exempt from the behavior-member check until B-128 declares them in `primitives.bp`; the exemption goes then
- [ ] decision 894 (859-a): the `.d.ts` declares, beside a type's `pub` methods, every method without `pub` that implements a member of a behavior the type's own `implement` clause names (`typescript.zig` `record` and the enum's methods read the declaration's `implement` list and each behavior's members through `crossModule`; an extension block's member and the lowering's marked calls stay out); test `codegen/tests/dts_behavior_member.zig` beside `dts_skips_templates.zig` (a non-`pub` `toStyled` under `implement Styled` declared, a plain non-`pub` method not, a block-supplied member not); no cell
- [ ] decision 895 (b162-lambda-underscore): `_` as a lambda parameter — `hasLambdaParams`, `hasLambdaBodyAhead` and the lambda's parameter list (`parser/exprs.zig`) take `.underscore` beside `.identifier`, a marked lambda the same; `_` bound to nothing (a read unresolved, never `binding-redeclared`); lowered as 888 (2)'s unnamed parameter in its position (commonJS a reserved-space name, erlang `_`, wasm by position); the formatter prints `_`; cell `lambda_underscore_parameter` (`{ _, _ -> v }` under `fn(Scope, Place) -> T`, `{ _ -> 1 }` under `fn(i32) -> i32`, `{ _, x -> x }`, a read of `_` refused), four targets, red on the parent
- [ ] 908: the seven cells carrying a `render(c, scope)` helper (388's `component_is_lambda`, `component_run_root`, `render_scope_library`; 574's `component_lambda_typed_param`, `component_lambda_typed_val`; 791's `component_resolved_by_use_or_tree`; 584's `marker_lambda_brace_component`) rewritten so the children are resolved inside the providing body (`use c`, or `c(scope, Place.none())` / `resolve(c, scope, key)` in a `{ scope -> … }` lambda), their answers kept; the helper gone

### B-156 — a function with a `syntax` expression parameter is expanded at its call (decision 719)

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** B-146

Decision 719 generalises the template (578): a function whose parameter is `syntax` is expanded where it is called — `syntax q: string` takes a template text `` @`…` `` as today, a `syntax` parameter of any other type takes the expression written between the parentheses of an ordinary call. The body is a build body (575 (4): the `syntax` value opaque, read by `compiler.*` or spliced), returning a type, `anyvalue` or `anytype`.

- [x] the checker admits `syntax` on a non-`string` parameter of a function that returns a type, `anyvalue` or `anytype`; a call to it with ordinary parentheses is expanded at the call as a template call is — the body evaluated at build with the argument captured as code, the answer's code spliced where the call stands and typed there (638); `compiler.source(value)` is the call's file, line and column, `compiler.text(value)` the expression as written
- [x] a `syntax q: string` parameter still takes a template text only: `markup("…")` stays `syntax-call-outside-syntax` (575 (4)); a `syntax` expression parameter given a template text is refused the same way, the message naming the form the parameter takes
- [x] a function with a `syntax` expression parameter and a run-time return type (`-> void`, `-> i32`) is refused at the declaration, located, naming 578 (2)'s three returns — a build body returns code, never a value · built as only `anyvalue` / `anytype` accepted, question 719-a
- [x] a decorator's `syntax decl` is untouched (576, 716); a template method's `syntax self: R` receiver is untouched (578 (1))
- [x] cells `syntax_fn_expanded_at_call` (snap's shape: `matches(syntax value: unknown) -> anyvalue` splicing `compiler.source(value)` into a run-time call, the file and line printed at the test's line), `syntax_fn_text_of_expression` (`assert(a == b)` printing `a == b`), `syntax_fn_string_param_needs_template_text` (reject), four targets; `conformance/docs.md` § Templates renamed to cover both forms · `compiler.source`'s file is the module path as built, question 719-b
- [x] `compiler.source(value).file` is the file relative to the package root (`src/main.bp`), never the module path; `builtins.d.bp`'s comment corrected · decision 756 (a); cell `syntax_fn_source_file_is_path` (`src/main.bp:20`)
- [x] snap's `matches` rewritten in this shape by front 160's step (landed); front 166's snap drafts promote on it (s4)
- [x] a `syntax` function called through its module — `snap.matches(x)` after `import {snap} from "snap"` — is not expanded and is refused "expected Expr, got string"; a call through the module's qualified name expands as the bare call does; a cell, red on the parent (found by front 160; snap's README and AGENTS still show that form)

Oracle: the cells; `zig build test`.
- [x] decision 841: `-> T` on a `syntax` expression function is code of type `T`, `-> void` included; `template-signature` no longer reads the
      return; `syntax_fn_run_time_return` rewritten as a run cell (red on the parent) — landed (the cell under `719/cells/`, four targets; its
      `log` takes `(label: string, syntax e: i32) -> void`, question 841-a, answered by 907: the use decides, a box below)
- [x] a `syntax` expression function's `code` tree naming an imported std function (`return code @`print(${text})`` with `print` imported) is
      refused "unbound variable 'print' … in `log`'s tree", `-> anyvalue` too; a cell, red on the parent — landed for std's `print` / `panic`
      (`applyAstHygiene` applies the writer's std calls, 669; cell `syntax_fn_code_names_imported_std_function`)
- [ ] every name of a tree a template or a `syntax` function builds resolves in the writer's module (170, 578), not only std's
      `print` / `panic`: the writer's own imports and its module's declarations, private ones (859) included, reached from the caller's
      module the way 830's marked lowering reaches `Module.of`. query's grammar (145, decision 914) needs it: its expansion spliced into
      the caller names `of` and `Query<T>`'s methods, which 914 makes private; a cell (a library template naming its module's private
      function, called from another package), red on the parent
- [x] 907: the use decides — `#[f]` applies a function whose first parameter is `syntax` as a decorator, `f(e)` expands any function with a `syntax` parameter at the call; `isSyntaxExprFn` goes (`ast.zig`), each use checked by its own rules against the one declared type; cell `syntax_fn_use_decides_kind` (`log(syntax e: unknown) -> void` annotated on a `val` and called on an expression, four targets, red on the parent); `syntax_fn_run_time_return` keeps its shape; B-69's home rule (592 (3)) reads the kind, a `syntax` function declared in `src/comptime/`

### B-154 — checker defects found by front 166's drafts (166 s3, css)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet (measured repros; the cells decide) · **After:** B-146

Front 166's decision cells are written as drafts before they compile; the first ones that do are the oracle. css's drafts (166 s3) measured: — landed (`parser/syntax_use.zig` reads each module's uses; a function used both ways is
      copied for its calls; cell `syntax_fn_use_decides_kind-907`); left: a use from another module waits on B-69's home rule (907 (4)),
      so an imported `log(syntax e: unknown) -> void` is not yet expanded at `log(x)`; question 907-a

- [x] a function value does not widen to an optional function type: `Cfg(scoper: scopeA1)` with the field `scoper: ?fn(string) -> string` is refused `type mismatch: expected ?function, got function` — a value of `T` is a value of `?T` for every `T`, a function type included (330); cell `optional_function_field_from_fn_value` (four targets), red on the parent; markdown's 330 draft meets the same (166 s3, markdown)
- [x] in a nested pattern a bare nullary variant binds a variable instead of matching the variant: `Error(NotAllowedOnHost)` and `Error(Timeout)` as `case` arms over a `Result<T, HttpError>` — erlang warns `variable 'NotAllowedOnHost' is unused`, commonJS takes the first arm for every error; at the top of a `case` the bare variant matches (std's `Method.verb`); a bare name inside a pattern that resolves to a nullary variant of the matched type is that variant (154's rule for expression position, applied to patterns), a binder only when no variant has the name; cell `nested_pattern_nullary_variant` (four targets), red on the parent (166 s3, http's 623 draft)
- [x] a dotted variant with a payload in an annotation argument is refused: `#[load(.Lazy(afterMs: 5))]` against a parameter typed by
      the decorator's enum says nothing tells which type declares `.Lazy` — the parameter's declared type tells it, as for a nullary
      `.Eager` (587, 603); cell `annotation_argument_dot_variant_payload`, red on the parent (found by B-146)
- [x] a dotted variant passed to a function another module declares is `unbound variable`: `phase.describe(.Slow)` with
      `pub fn describe(p: Phase) -> string` in `phase` — the parameter's declared type resolves it (587); cell
      `dot_variant_argument_imported_fn` (four targets), red on the parent (found by B-146)
- [x] a refusal naming two generic types prints each with its arguments: `template-build-outside-bound` for `Component<Other>`
      against `-> Component<Styled>` prints both as `Component` (`typeLabelAlloc` drops the arguments); the snapshot of
      `template_build_outside_bound_component` rewritten with the two full types (found by B-153)
- [x] a `case` whose arms cover a variant through its nested payloads is exhaustive: `case j { Run(Fast) -> …; Run(Slow) -> …; Stop -> … }`
      is reported missing `Run` (`checkCaseExhaustiveness` counts no nested payload); cell `case_exhaustive_nested_variants`, red on the
      parent (found by B-154)

Oracle: the cells; `zig build test`. A draft that a later 166 s3 lands names its defect as a box here (checker) or as a 164 row (comptime on wasm, machine 2).

### B-140 — `Type` in botopink in `types.bp`, its records `compiler.Field<T>` / `compiler.Info<T>` in `compiler.bp` (624, 630): `compiler.buildType`, `fields`, `optional`, `required` (decision 575 (5), (7); 578)

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** B-139

- [ ] decision 669: the names in a built type's fields and implements resolve in the module that calls `buildType` / `buildTypeInline` (the decorator's), as every tree a decorator writes; an annotation argument in the annotation's module (206); `compiler.lookup` the one way to the caller's names — cells `built_type_names_decorator_module`, `built_type_host_name_unbound`; rakun's qualified names dropped in 165 s11
- [ ] decision 670: any `-> anytype` function builds a type, std's five the first of them — the callee resolved through the import graph, no std list in the checker; `anytype-outside-type-val`; cells `derived_type_library_builder`, `derived_type_program_builder`, `anytype_outside_type_val`
- [ ] decision 671: a field's default travels into every derived type and resolves where it was written (669), `defaultValue` always the default as written; `isClosedDefault` and the non-closed refusal removed, the target exporting what a default reaches; cells `derived_type_default_travels`, `derived_type_default_module_val`, `derived_type_default_across_packages`, `imported_field_default_not_derived` rewritten
- [x] the run-time field key removed (decision 599): `Type.keys`, `Field.of` / `all`, the run-time `compiler.Field<T>` value, five cells, `docs.md`'s paragraph; `partial` / `required` / `merge` / `pick` / `omit` stay, written over `compiler.fields` + `compiler.buildType` (599 (3))
- [ ] `compiler.Field<T>(name: string, type: type, annotations: DeclAnnotation[], defaultValue: ?anyvalue)` (decision 598: the default as written, `null` when none; cells `typeinfo_field_default_value`, `typeinfo_field_default_none`) — `typeName` goes; a `type` value is
      lowered as its name on every target; `typeInfo(T).fields` and `compiler.fields(d)` hand out `compiler.Field<unknown>` (308, 576 (8))
- [ ] `compiler.fields`, `compiler.optional` / `required` (a field, its source kept), `compiler.buildType` over the record's text (307's naming by
      the binding `val`; `derived-type-outside-val`, `derived-type-cycle`, `record-field-duplicate`; defaults and
      markers from the source, 423); `comptime/derived_types.zig` reduced to the record's materialisation and the two
      `val` rules; `partial` / `required` / `merge` / `pick` / `omit`, `keys`, `Field.of` / `all` written in `types.bp`'s `Type` (the utilities) and `compiler.bp`'s `Field<T>` / `Info<T>` (624, 630)
- [ ] decision 578: `compiler.record` gone — the derived types are built from `compiler.fields(T)` with `compiler.buildTypeInline(fields)`, a structure and never text (629 (1)) (defaults and annotations as written, 423; 307's three refusals over the built type); `compiler.Field<T>`'s `type: anytype`; the string `addType` → `compiler.addType(name, compiler.buildType(…))`
- [x] decision 631: a `Field<T>` crossing to run time is `Field(Owner, "name")` and the owner compares by identity; cells `meta_field_tuple_and_field_key`, `meta_field_build_member_at_run_time`, `meta_field_compared_by_owner` (599's own cell module removed: all five of its cases were the removed cells)
- [ ] `return Field<T>;` — a type written as a value where `type` is expected (the parser point of 575 (7))
- [ ] decision 576 (14): the typed `compiler.addType(name, compiler.buildType(…))`; std's `mock(T)` of `testing/mocks.bp` (644); the string `addMember` / `addType`, `decorator-member-not-one-fn` and decorator_add_member_not_one removed; the libraries' sites (165)
- [ ] a unit test holds `conformance/docs.md` § Prelude to the names `primitives.bp` declares and each imported std function's row to its module's declaration (606): a row per name, its declaration as written, its rule — B-16's builtins-`Field` work is superseded by this step and was not landed
- [ ] cells: the twelve derived-type cells unchanged; `record_field_duplicate`; `merge`'s duplicate located at the
      second argument; a `type` value printed; `RecipeKey.all()` at run time, computed at build

Oracle: the derived-type cells; `test-libs`.
