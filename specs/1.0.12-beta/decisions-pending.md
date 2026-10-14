# Decisions the maintainer owes — 1.0.12-beta

**116 questions and 6 contradictions are open, and 100 implementation choices await confirmation** (counted from the
entries below: a lettered question, `nat-d` and `nat-f` being headings of their cases; `ctr-*` and `119-a` the
contradictions; a row of a choices table, or a `#####` entry beside it).

- An answer goes into [`decisions-taken.md`](decisions-taken.md) under the next free number (kept
  there only); a lettered id is never renumbered or reused.
- Every recommendation is the most restrictive reading, no configuration bypassing it (decision 67).
- A front meeting a question it cannot answer from the code adds it here: id · title · Measured
  (observed, re-runnable) · Options · Recommendation · Blocks. *Proposed* = raised without an id.

- **Machine 1** — maximum priority: the questions front 144's machine 1 waits on, by step.
- **Machine 2** — maximum priority: the questions front 144's machine 2 waits on, most urgent first. New development is centred on front 164 wasm-gc (s1 → s4, wasmtime-a, wasmgc-a).
- **Front 165** — rakun-workspace: one `rakun` repository, 17 plug-and-play packages (mono-a).
- **Part 1** — what blocks front 144 (`repository/botopink-lang`, decision 433: the open steps of the old tracks
  `00-gate`, `01-compiler`, `02-std-and-packaging`, `03-bundled-libs`), by old track, then those
  tracks' implementation choices awaiting confirmation.
- **Part 2** — the rest (tracks 04–10, 20, ownership, contradictions that block no 00–03 step).
- **Part 3** — the implementation choices of tracks 04–09.

The Portuguese page (`decisoes-pendentes.md`) is this page's direct translation: this English text holds the meaning
(meta `AGENTS.md` § Conventions). Answered ids leave this file; `decisions-taken.md` holds the answers and the next free
number, which is **518**.

---

## Machine 1 — maximum priority (front 144, `machine-1-checker/`)

The questions machine 1's steps wait on (lane A, B-19, B-22, B-23, B-24, B-25, B-27, B-55, B-60, the module-model
group), answered before every other part of this page; in the order of the steps they block.

#### B-02-c · `"std:…"` written on `@External.Node` / `@External.Erlang`: host code, or refused like the other prefixes? (decisions 305, 481; 144 B-02)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): refused on every target, naming the labelled form** — `conformance/docs.md` § Host bindings already says the four prefixed strings are refused at the argument on every target; a string that reads as a cell and runs as host code is the ambiguity 305 removed. Changes: `checkExternalCells` refuses `"std:"` off wasm too; a cell.
- **Measured.** `checkExternalCells` refuses `"std:…"` only on `@External.Wasm`; on Node and Erlang it is host code ("`std:` was only ever a wasm cell").
- **Options.**
  (a) Refused everywhere.
  ```bp
  #[@External.Node("std:hash.contentHash")]   // refused: a `std:` cell is `@External.Wasm`'s
  ```
  (b) Host code off wasm, the text corrected.
  ```bp
  #[@External.Node("std:hash.contentHash")]   // JavaScript source `std:hash.contentHash`
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-02's `std:` row.

#### B-10-a · `Field` reflects a field's default: what is the member called, `default` being a keyword? (decisions 280, 308; 144 B-10 G1)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): `defaultValue: ?@Expr<unknown>`** — the default as the expression written, `null` when none; `default` is a keyword and no field takes a keyword's name. An `@Expr` keeps the default code, never a value computed at build (281).
- **Measured.** `Field` has no default member; validation's marker reads defaults by hand. A field named `default` is a parse error.
- **Options.**
  (a) `defaultValue: ?@Expr<unknown>`.
  ```bp
  for (f in decl.fields) { if (f.defaultValue != null) … }
  ```
  (b) `hasDefault: bool` only.
  ```bp
  for (f in decl.fields) { if (f.hasDefault) … }   // a bool only
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-10's row.

#### B-10-b · `Decl.variants`: what does an entry carry, a section included? (decisions 268, 298; 144 B-10 G1)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): `Variant(name, fields: Field[], annotations, section: ?string)`** — a payload variant lists its fields as `decl.fields` does; a section is not an entry, its variants carry the section's name. One entry per constructible variant.
- **Measured.** `Decl.variants` carries names only, sections listed among them.
- **Options.**
  (a) Typed entries, sections as a field.
  ```bp
  decl.variants[0].fields[0].name   // "amount"
  ```
  (b) As today: names.
  ```bp
  decl.variants[0]   // "Paid" — a name, sections among them
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-10's row.

#### B-10-c · `clock.formatIso8601`: which text is the one answer? (decision 497; 144 B-10 G1)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): always milliseconds, `.sssZ`** — `2026-10-12T20:31:02.000Z` on every target; a fixed width sorts as text and parses back with one rule.
- **Measured.** commonJS answers `.sssZ` always (node's `toISOString`); erlang never writes milliseconds.
- **Options.**
  (a) Always `.sssZ`.
  ```bp
  clock.formatIso8601(t)   // 2026-10-12T20:31:02.000Z
  ```
  (b) Milliseconds only when nonzero.
  ```bp
  clock.formatIso8601(t)   // 2026-10-12T20:31:02Z, .123Z only when nonzero
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-10's row.

#### B-10-d · A bare variant in expression position (`Two(t)`, no enum qualifier): refused or lowered? (144 B-10 G2)
- **Answered (the maintainer, 2026-10-14; awaiting its number in `decisions-taken.md`):** (a), with B-22-a (the same question): a bare variant in expression position is refused at the call, located, naming `E.Two(t)` or `.Two(t)` (the expected type naming the enum); a bare variant stays a `case` pattern's (decision 8). One rule, both questions.
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): refused at the call, located, naming `.Two(t)` or `E.Two(t)`** — `docs.md` already says it is not lowered; the checker accepting what no backend emits is the defect. One spelling: the qualified or the dot form.
- **Measured.** `Two(t)` checks, then fails on commonJS, erlang and beam; `docs.md` calls it unlowered.
- **Options.**
  (a) Refused.
  ```bp
  val m = Two(t);   // refused: write `.Two(t)` or `Mode.Two(t)`
  ```
  (b) Lowered on every target.
  ```bp
  val m = Two(t);   // a Mode, on every target
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-10's row.

#### B-10-e · How does a type alias of `@Component<Styled>` implement a behavior? (144 B-10 G2)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(b): it does not — an alias is its target**: `Styleable` is implemented by `Styled`, and `@Component<Styled>` reaches it through `R`; an alias declares nothing (a second name, not a type). styled's marker is rewritten over `Styled`'s implementation.
- **Measured.** `pub val StyledView = @Component<Styled>` cannot carry `implement`; no spelling exists.
- **Options.**
  (a) An alias with `implement`.
  ```bp
  pub val StyledView = @Component<Styled> implement Styleable;
  ```
  (b) Only the target type implements.
  ```bp
  pub type Styled(…) implement Styleable { … }   // StyledView reaches it
  ```
- **Recommendation.** (b).
- **Blocks.** 144 B-10's row.

#### B-10-f · How does a decorator read whether a `@Component<R>` return's `R` implements `@Renderable`? (decisions 268, 280; 144 B-10 G3)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): through `@typeInfo` of the declared return** — `@typeInfo(decl.returnType).implements(@Renderable)`; `@Decl` stays a declaration's handle and type questions go through `@typeInfo`, the one reflection of a type. Viable: `decl.returnType` as a type value (today a name) and `TypeInfo.implements(B)`. Changes: two members; jhonstart's marker in `client.bp` goes.
- **Measured.** No reflection answers it: `decl.returnType` is the type's name as text, and no member asks whether a type implements a behavior.
- **Options.**
  (a) `@typeInfo` of the return type.
  ```bp
  if (!@typeInfo(decl.returnType).typeArg(0).implements(@Renderable)) decl.fail("…");
  ```
  (b) A member of `@Decl`.
  ```bp
  if (!decl.returnImplements(@Renderable)) decl.fail("…");
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-10 G3's `@Renderable` row.

#### B-10-g · A template declared `-> @ExprCustom<View>` whose built code is an `Element`: is the expansion a `View`? (decisions 275, 276; 144 B-10 G3)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): yes — the expansion is what the template declares** — `html` declared `-> @ExprCustom<View>` answers a `View` (`@Component<Element>`), and a built `Element` is checked against it as a component's body; jhonstart's `renderNode(html …)` and its `-> Element` components move to `View`. A template's declared type is its call's type (426); keeping `Element` at the call would make the declaration decorative. Viable: the built code's check against `View` accepts an `Element` as a component's answer. Changes: jhonstart's components (a consumer commit), a cell.
- **Measured.** With `-> @ExprCustom<View>` every `html` expansion fails `expected Component, got Element`.
- **Options.**
  (a) A `View`.
  ```bp
  fn Card() -> View { html`<div/>` }   // the expansion is a View
  ```
  (b) The call keeps `Element`.
  ```bp
  fn Card() -> Element { html`<div/>` }   // the declared View ignored at the call
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-10 G3's `@ExprCustom<View>` row.

#### B-11-a · `decl.wrapWith(f)`: is the wrapper only a lambda written at the call, or any value of the call type? (decision 316; 144 B-11)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): a lambda written at the call** — `decl.wrapWith({ call -> … })`; any other expression is `decorator-wrap-not-lambda`, located at the argument. It is 370 (2)'s rule for a member function a decorator adds: the code the decorator writes is checked as the program's, never a value computed at build. Viable: as built. Changes: none.
- **Measured.** Built as (a). The call type is internal (`__Decl__Call<A, R>`, one per wrapped function), so a helper returning a wrapper (`cachedCall(cache)`) cannot name its parameter's type; (b) would need that type nameable.
- **Options.**
  (a) A lambda at the call.
  ```bp
  decl.wrapWith({ call -> cachedCall(cache, { -> call.run() }) });   // accepted
  decl.wrapWith(cachedCall(cache));                                  // refused: decorator-wrap-not-lambda
  ```
  (b) Any value of a nameable call type.
  ```bp
  fn cachedCall<A, R>(cache: Cache<R>) -> fn(call: Decl.Call<A, R>) -> R { … }
  decl.wrapWith(cachedCall(cache));                                  // accepted
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-11's wrapper row.

#### B-11-b · May `decl.wrapWith` wrap a generic function or a member of a generic type? (decision 316; 144 B-11)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(b): yes, as a 144 row** — the wrapper is checked against the signature with its type parameters, and the wrapped function stays generic. 316 names no exception for generics, and a cache or a retry is as useful on `fn byId<T>(…)`. Viable: the generated call type takes the function's type parameters. Changes: a cell; `decorator-wrap-generic` goes.
- **Measured.** A generic function or owner is refused today, `decorator-wrap-generic`, located at the decorator.
- **Options.**
  (a) Refused, as built.
  ```bp
  #[counted] fn first<T>(xs: T[]) -> ?T { … }   // refused: decorator-wrap-generic
  ```
  (b) Wrapped, generic.
  ```bp
  #[counted] fn first<T>(xs: T[]) -> ?T { … }   // wrapped; first<i32>, first<string> both counted
  ```
- **Recommendation.** (b).
- **Blocks.** 144 B-11's generic row.

#### B-14-a · `Name(..base, f: v)` (decision 37) beside 359's `Name(...base, f: v)`: does `..` go? (144 B-14)
- **Answered (the maintainer, 2026-10-14; awaiting its number in `decisions-taken.md`):** 529: `..` is the one spelling of "the rest" — a record's construction spreads with `..` (`Name(..base, f: v)`), a tag with `{..p}`, and `...` goes, kept only for the inclusive range; `botopink format` migrates. The reverse of the proposal.
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): `..` goes** — one spelling for copying a record's fields; `Name(..base, …)` is refused, located, naming `...base`, and a codemod rewrites std and the libraries in the step that lands it. Two spellings for one thing is what decision 67 refuses; `...` is 359's, also the tag's (`<Card {...p} />`). Viable: the parser's `..` arm in a constructor's arguments; `grep -rn '(\.\.[a-z]'` over the repositories. Changes: a refusal cell; decision 37 amended.
- **Measured.** Both compile on `feat`: decision 37's `..base` (source limited to a name) and 359's `...src` (any expression of the record's type or a 307 derived type).
- **Options.**
  (a) `..` goes.
  ```bp
  val p = Pessoa(...old, nome: "Ana");   // the one form
  val q = Pessoa(..old, nome: "Ana");    // refused: write `...old`
  ```
  (b) Both stay.
  ```bp
  val p = Pessoa(...old, nome: "Ana");
  val q = Pessoa(..old, nome: "Ana");    // same record
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-14's `..` row.

#### B-14-b · In which order are a spread's source and the labelled values evaluated? (decision 359 (3), (6); 144 B-14)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): in the order written** — every argument, a spread's source included, is evaluated left to right as written, once; the fields then apply left to right, the later winning (359 (3)). A call's arguments evaluate in the order written everywhere else; a spread is no exception. Viable: `infer.inferRecordSpread` binds every argument with a side effect to a local in written order, not the source alone. Changes: a cell whose source and a labelled value both print.
- **Measured.** A source that is not a name is bound once before the call, so it is evaluated before every labelled value, even one written before it: `Pessoa(nome: say("n"), ...make())` prints `make` then `n`.
- **Options.**
  (a) Written order.
  ```bp
  val p = Pessoa(nome: say("n"), ...make());   // prints n, then make
  ```
  (b) The sources first, then the labelled values (as built).
  ```bp
  val p = Pessoa(nome: say("n"), ...make());   // prints make, then n
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-14's order row.

#### B-14-c · A type derived from a `Type.partial` type, and `Type.required`: may they be a spread's source? (decisions 307, 359 (2), 422; 144 B-14)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): a type derived from a partial is a partial** — `Type.pick` / `omit` / `merge` of a `Type.partial` type are refused as a source like the partial itself; `Type.required(Type.partial(R))` is derived from `R` and accepted. A partial's fields may be absent, which 359 (2) refuses; deriving again keeps that. Viable: `derived_types` records `derivedPartial` per type, so it carries through `pick` / `omit` / `merge`, and `required` clears it with its source's lineage. Changes: two cells.
- **Measured.** `pick` / `omit` / `merge` of a partial derive from the partial type only, not from its source, so they are refused as other records; `Type.required` has no lineage, so its value is refused too.
- **Options.**
  (a) A derived partial is a partial; `required` restores the source.
  ```bp
  pub val Patch = Type.partial(Pessoa);
  pub val Nome = Type.pick(Patch, .nome);
  pub val Full = Type.required(Patch);
  Pessoa(...nome, idade: 3);   // refused: a partial's fields may be absent
  Pessoa(...full);             // accepted
  ```
  (b) As built: both refused as records of another type.
  ```bp
  Pessoa(...nome, idade: 3);   // refused: `Nome` is not `Pessoa`
  Pessoa(...full);             // refused: `Full` is not `Pessoa`
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-14's lineage row.

#### B-15-a · How does a template body build a tag's `@Decl` and run its annotation? (decision 302; 144 B-15)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): `q.tagDecl(kind, name, attrs)` and `q.annotate(decl, at: Span)`, as built** — the capture (`q`) builds the handle and runs the annotation written at a span of its own text, resolved in the caller's scope with its arguments checked there; the annotation's text is read from the span, never passed as a string (281). Both live on the capture because only it knows the caller's scope and text. Viable: as built (the run stops with `need`, the compiler runs the annotation, the body runs again with the answer). Changes: none.
- **Measured.** Built as (a); `jhonstart`'s `html` uses it (`#[isRaw]` records `RawBody`).
- **Options.**
  (a) On the capture.
  ```bp
  val d = q.tagDecl(.Element, "div", attrs);
  q.annotate(d, at: ann.span);
  val names = d.metaAll(ClassName);
  ```
  (b) Free functions in std's `template` namespace.
  ```bp
  val d = template.tagDecl(q, .Element, "div", attrs);
  template.annotate(q, d, ann.span);
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-15's spelling row.

#### B-15-b · Does a template body's `Binding` carry its `Decorator`, for `Decorator.same`? (decisions 268, 302, 371; 144 B-15)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(b): no — meta is read by type** — a template body tells annotations apart by the meta they record (`d.meta(RawBody)`), as 302 says; `Binding` carries no `Decorator`, and B-15's box naming `Decorator.same` is dropped. One way to identify what an annotation did, by its typed answer, not by which function it was. Viable: as built. Changes: the box's text.
- **Measured.** `Binding` (a looked-up name in a template body) has no `Decorator`; `html` reads meta by type.
- **Options.**
  (a) `Binding.decorator`.
  ```bp
  if (b.decorator?.same(isRaw)) { … }
  ```
  (b) By meta type.
  ```bp
  if (d.meta(RawBody) != null) { … }
  ```
- **Recommendation.** (b).
- **Blocks.** 144 B-15's `Decorator.same` row.

#### B-15-c · May an annotation read the meta an earlier annotation recorded on the same declaration or tag? (decisions 298, 302; 144 B-15)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): no, as built** — inside a decorator, `decl.meta(T)` is refused; a declaration's meta is read by the code that consumes it (`@typeInfo(X).meta(T)`, a template body over `d.meta(T)`), after every annotation ran. Annotations then do not depend on their written order. Viable: as built. Changes: none.
- **Measured.** `d.meta(T)` on a decorator's own `@Decl` parameter is refused.
- **Options.**
  (a) Refused inside a decorator.
  ```bp
  pub fn raw(comptime decl: @Decl) { decl.meta(ClassName); }   // refused
  ```
  (b) Read, in annotation order.
  ```bp
  pub fn raw(comptime decl: @Decl) { if (decl.meta(ClassName) != null) decl.fail("…"); }
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-15's meta-read row.

#### B-16-a · A field key at run time: what are its `typeName`, its `annotations` and its printed form? (decision 308; 144 B-16)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): a run-time key is its name** — at run time `Type.Field<T>` carries `name` only; `key.typeName` and `key.annotations` are build-time members, refused outside a decorator or template body (`field-key-build-only`), and `@print(key)` prints `.name`. Annotations are `Decorator` values, which exist only at build; a run-time copy would be a second, partial truth. Viable: the run-time record keeps one field; the checker refuses the two members by stage. Changes: a refusal cell; `field_key_runtime` prints a key.
- **Measured.** As built, a run-time key holds `typeName` as the checker spells it and `annotations: []`; `@print(key)` prints the whole record. The cells use only `name`, `==`, `case`, `of`, `all`.
- **Options.**
  (a) Its name only.
  ```bp
  val k = Recipe.Key.of("title") ?? .title;
  @print(k);           // .title
  k.annotations;       // refused at run time: field-key-build-only
  ```
  (b) The whole record, as built.
  ```bp
  @print(k);           // Field(name: "title", typeName: "string", annotations: [])
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-16's run-time key row.

#### B-16-b · `Type.keys(R)` on an annotated `val`: refused? (decisions 307, 308; 144 B-16)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): refused** — `#[x] pub val K = Type.keys(R)` is `derived-type-arguments` at the annotation: `Type.keys` names an existing type (an alias), not a new declaration, so there is nothing for a decorator to annotate; a derived record (`pick`, `omit`, …) stays annotatable. Viable: as built. Changes: none.
- **Measured.** Built as (a).
- **Options.**
  (a) Refused.
  ```bp
  #[validated] pub val K = Type.keys(Recipe);   // refused: an alias is not a new type
  ```
  (b) Accepted, the decorator seeing `Recipe`'s keys type.
  ```bp
  #[validated] pub val K = Type.keys(Recipe);   // decl.kind == .Alias
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-16's annotated-`val` row.

#### B-17-a · A body that runs at build calls a host function with a build form: allowed? (decisions 376 (4), (5), 341, 434, 451 (3), 452; 144 B-17)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): a host function with a build form (`std:` cell, `@External.Wasm` `fn:`) is `Any`; run-in-build refuses only the others**, replacing `comptime-host-cell-unavailable` with 376's message. 434/452 made exactly these callable at build; 376 written before them would undo it.
- **Measured.** `decorator_host_cells`, `comptime_std_host_function`, `comptime_random_seeded`, `decorator_random_seeded_commonjs` call host functions with a wasm form at build and pass; 376 as written refuses them.
- **Options.**
  (a) A build form makes it `Any`.
  ```bp
  comptime { random.seeded(1).next() }   // accepted: random has a std: cell
  ```
  (b) 376 as written.
  ```bp
  comptime { random.seeded(1).next() }   // refused: a Run function at build
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-17's row.

#### B-17-b · How is a function's stage written? (decision 376 (4); 144 B-17)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): `#[@Stage.Any]`, as built** — `pub type Stage { Build, Run, Any }` in `builtins.d.bp`; only `Any` is written (Build and Run follow from resources), so `#[@Stage.Build]` / `#[@Stage.Run]` are refused as unknown annotations.
- **Measured.** Built as (a); std's `math` host functions carry it.
- **Options.**
  (a) `#[@Stage.Any]`.
  ```bp
  #[@Stage.Any] pub declare fn sqrt(x: f64) -> f64;
  ```
  (b) `#[pure]`.
  ```bp
  #[pure] pub declare fn sqrt(x: f64) -> f64;
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-17's row.

#### B-17-c · What is the `Build` resource: a read of a comptime parameter, or any `@typeInfo`? (decisions 364, 376 (1); 144 B-17)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): a read of a comptime `@Decl` / `@Expr` parameter**; `@typeInfo(NamedType)` is a build constant, folded, not a resource. Otherwise every `main` that reads a type's meta becomes `Build` and cannot run.
- **Measured.** Built as (a); `comptime t: type` is refused (364).
- **Options.**
  (a) A comptime parameter.
  ```bp
  fn main() { @print(@typeInfo(User).fields.length) }   // Any: a constant
  ```
  (b) Any `@typeInfo`.
  ```bp
  fn main() { @print(@typeInfo(User).fields.length) }   // Build: refused at run
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-17's row.

#### B-17-d · Does a stage follow declarations only? (decision 376 (2); 144 B-17)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): yes** — a call's stage is the called declaration's; a method call or a call through a function value adds nothing (`Any`); a run body that calls a comptime-`@Expr` function and reads the clock is `build-and-run`, as 376 writes.
- **Measured.** Built as (a).
- **Options.**
  (a) Declarations only.
  ```bp
  fn main() { val f = clock.now; f() }   // Any: a function value adds nothing
  ```
  (b) Function values too.
  ```bp
  fn main() { val f = clock.now; f() }   // Run: the value's declaration counted
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-17's row.

#### B-17-e · A raise while folding an expression at build: always a build error? (decision 380 (2); 144 B-17)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): yes, as 380 (2) writes — once the comptime runtime's primitives answer as the targets do** (that row first); until then folding stays limited to what the runtime answers right, so no wrong answer becomes a build error.
- **Measured.** As built only arithmetic errors (badarith) are build errors; any other raise leaves the hole to render.
- **Options.**
  (a) Every raise a build error, after the runtime row.
  ```bp
  val h = "${parse("x")}";   // build error: the raise named
  ```
  (b) Arithmetic errors only.
  ```bp
  val h = "${parse("x")}";   // left to run
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-17's row.

#### B-17-f · Which `Any` function does 380 fold at build? (decisions 376, 380; 144 B-17)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): as built** — an `Any` function that writes no `@panic` / `@todo` / `throw`, no `@print`, no module `var`, no function-value call and no method of a declared type; its calls through other such functions fold too.
- **Measured.** Built as (a) (`hole_any_call_at_build`, `hole_any_call_raises`).
- **Options.**
  (a) As built.
  ```bp
  fn shout(s: string) -> string { s.toUpper() }   // folded
  ```
  (b) Every `Any` function.
  ```bp
  fn logShout(s: string) -> string { @print(s); s.toUpper() }   // folded too
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-17's row.

#### B-17-g · Where does a context read find a default declared in a module it neither imports nor reaches through its type? (decisions 378, 379; 144 B-17)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): in the type's own module or a module already analysed; otherwise refused at the read, naming the type** — a default is found where the program can see it, never by a whole-program search.
- **Measured.** Not built; Step 6 waits on it.
- **Options.**
  (a) The type's module or one analysed, else refused.
  ```bp
  use context<Theme>();   // refused: no default for Theme visible here
  ```
  (b) Any module of the program.
  ```bp
  use context<Theme>();   // the default found in any module
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-17's row.

#### B-17-h · math's `op:`-only host functions at build: given `std:` cells? (decisions 452, 481; 144 B-17)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): yes — one `std:` binding cell per function in std-wasm** (`floor`, `abs`, `trunc`, `sqrt`, `minF`, `maxF`), so the comptime runtime answers them and they fold (380); an opcode has no host form at build otherwise.
- **Measured.** They are refused at build (452) and no longer treated as foldable.
- **Options.**
  (a) A `std:` cell each.
  ```bp
  val r = "${math.sqrt(16.0)}";   // computed at build
  ```
  (b) Run time only.
  ```bp
  val r = "${math.sqrt(16.0)}";   // computed at run time
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-17's row.

#### B-17-i · Confirm `Context<T>(contextValue)` and a context lowered to its plain value at run time (decisions 378, 379; 144 B-17)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): as built** — std's `Context<T>` holds `contextValue: T`; at run time a context is its plain value, so an `f64` / `i64` context crosses wasm's scope as any value.
- **Measured.** Built as (a).
- **Options.**
  (a) As built.
  ```bp
  pub val Theme = createContext(Light);   // at run time: the value Light
  ```
  (b) A record kept at run time.
  ```bp
  pub val Theme = createContext(Light);   // at run time: Context(contextValue: Light)
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-17's row.

#### B-17-j · Contexts keyed by the type's declared name or by its module and name? (decisions 310, 379; 144 B-17)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): by module and name** — two same-named types of two packages are two types (310), so they are two contexts; styled's sheet keys still match across packages because they name one type, styled's.
- **Measured.** Built keyed by the declared name: two same-named types of two packages share a key and hit `context-declared-twice`.
- **Options.**
  (a) By module and name.
  ```bp
  import {a.Theme as A}; import {b.Theme as B};   // two contexts
  ```
  (b) By the declared name, as built.
  ```bp
  import {a.Theme as A}; import {b.Theme as B};   // refused: context-declared-twice
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-17's row.

#### B-17-m · A type implementing a behavior only through an extension block: a value of that behavior? (decisions 379, 416; 144 B-17)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(b): refused, as built** — an extension block (`Sym implement B for T`) adds methods where the block is visible; it does not make `T` a `B` value for a parameter, a return or a context, since no backend dispatches a behavior call to the block. The strictest reading; accepting it would mean behavior dispatch to the block's methods on four targets.
- **Measured.** Refused everywhere (contexts and `B`-typed parameters); a probe accepting it aborted on commonJS, erlang and beam, and wasm refused it.
- **Options.**
  (a) Accepted, dispatched to the block.
  ```bp
  Sym implement Shape for Circle { … }
  fn draw(s: Shape) { … }  draw(Circle(r: 1));   // accepted
  ```
  (b) Refused.
  ```bp
  draw(Circle(r: 1));   // refused: Circle does not implement Shape
  ```
- **Recommendation.** (b).
- **Blocks.** 144 B-17's extension-block row.

#### 04s12-a · A `@Component` method, lambda or `default fn` has no hooks node (375 (2), 04-js step 12)
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **(c), and a type may be a component — every form behaves and is called as a `fn` component.** (1) A method, a lambda or a `default fn` answering `@Component<R>` lowers as a top-level component: a lambda over the `RenderScope` (388) answering its tree and its children's scope, with `use provide` / `use context` / `await` in its body, marked by its own body (s23-j); calling it only makes the lambda and marks no caller. (2) A type implementing `Component<R>` is a component: its fields are its props and its `render(self) -> R` is its body — `type Menu(items: string[]) implement Component<Element> { fn render(self: Self) -> Element { val t = use context(Theme); return <ul class={t.cls}>…</ul>; } }` — written and called as `fn Menu(items: string[]) -> @Component<Element>` is: `<Menu items={["a", "b"]}/>`, the same lowering `(props) => (scope) => …`, the same marks. The scope is never a field (388 (5): nothing captured; the renderer hands it at each run, a `Suspense` fill included). (3) Each has its own hooks node, and a method's or a type's node enters `decl.hooks` (277 amended: a method call followed through its receiver's type), so a decorator sees `Menu`'s hooks as it sees `fn App`'s. **(2) in detail** (the maintainer, 2026-10-12): a type implementing `Component<R>` is sugar for a `fn` component. Its fields are the parameters — defaults, optionals, `children`, generics as in a `fn`, immutable — and its `fn render(self: Self) -> @Component<R>` is the body, `self` reading the fields and the type's helper methods. `X(fields…)` and `<X …/>` answer the component (the lambda `(props) => (scope) => …`), never a record, so a caller cannot tell the two forms apart. The same lowering on commonJS, erlang, beam and wasm, the same `.d.ts` (`export declare function X(props: {…}): Component<R>`), the same marks (s23-j: a `render` with `await` is asynchronous), the same `decl.hooks` for decorators (`#[page] type` and `#[page] fn` interchangeable), the same comptime (434-b). Hooks only in `render`; a helper method not answering `@Component` is an ordinary function. Refused, located: `implement Component` with no `render`; a `render` of another signature; a `RenderScope` field (388 (5)); a `use` outside `render`; `X.render()` called directly (`call the component, not its body: <X …/> or X(…)`). **(2) amended — a component's props are one record** (the maintainer, 2026-10-12): a component, `fn` or type, takes its props as one record parameter, never a list of parameters. `type MenuProps(items: string[], title: string = "Menu");` — then `fn Menu(props: MenuProps) -> @Component<Element> { val t = use context(Theme); return <nav class={t.cls}><h2>{title}</h2><ul>{items.map({ i -> <li>{i}</li> })}</ul></nav>; }`, or the same component as a type: `type Menu(props: MenuProps) implement Component<Element> { fn render(self: Self) -> @Component<Element> { …<h2>{self.title}</h2><ul>{self.items.map({ i -> self.item(i) })}</ul>… } fn item(self: Self, i: string) -> Element { return <li>{i}</li>; } }` (`item` does not answer `@Component`: an ordinary helper). The record's fields are in scope: bare in the `fn` body (`title`, `items`), on `self` in `render` and the helpers (`self.title`, `self.items`); `props` names the whole record. Defaults, optionals, `children` and generics are the record's, written once on `MenuProps`. A caller never builds the record: the attributes are its fields — `<Menu items={["a", "b"]}/>` (`title` taking its default), `<Menu items={["a", "b"]} title="Principal"/>`, `<Layout view={ { -> <Menu items={xs}/> } }/>` (inside a lambda prop alike) — and the compiler builds the `MenuProps` from them, checked field by field as a record construction is (a missing field, an unknown attribute, a wrong type: located on the attribute). A component with no props takes no parameter (`fn App() -> @Component<Element>`). The lowering is unchanged — `(props) => (scope) => …`, `props` the record — and the `.d.ts` names it: `export declare function Menu(props: MenuProps): Component<Element>`, `MenuProps` exported beside it. Refused, located: a component with more than one parameter, or whose one parameter is not a record type (`a component takes its props as one record: type MenuProps(…); fn Menu(props: MenuProps)`).
- **Measured.** 04-js step 12 asks a method, a lambda and a `default fn` to follow the mark "alike", but 277's
  nodes are the module's top-level functions only. Built: each stays an `async function` / `async` arrow on
  commonJS, and a call of one keeps its `await` (a call the checker cannot follow, s23-j (1)).
- **Options.** (a) As built. (b) The checker marks every `@Component` body — a method, a `default fn`, a lambda —
  by 375's rule (a node of its own, not listed in `decl.hooks`), commonJS emits each by its mark:
  ```bp
  type Menu(items: string[]) { fn render(self: Self) -> @Component<Element> { return Element(…); } }
  // (a): `async render(map) {…}`, `await menu.render(map)`; (b): `render(map) {…}`, no `await`
  ```
  (c) (b), and a method's node enters `decl.hooks` (277 amended: a method call followed through its receiver's
  type).
- **Recommendation.** (b): the rule is the body's, wherever the body is written; (c) changes what a `.hooks`
  reader sees and is 277's question.
- **Blocks.** 04-js step 12 box 1's method, lambda and `default fn`.

#### 434-b · The render-resident and at-build paths under one wasm comptime runtime (434, 378 (4))
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **Every library runs at build on the wasm comptime runtime (434), jhonstart first; a function only Erlang or Node can run is a located error there.** (1) A host cell (`@External.Erlang` / `@External.Node`) reached at build runs through its wasm form — a botopink body (`#[@External.Wasm(fn: …)]`) or a std-wasm export (`std:`, 481) — so `comptime renderToString(<Rodape ano={2026} />)` answers one string for every target. (2) Each library gives its pure cells (escape, formatting, parsing — logic written in Erlang or JS for convenience) a wasm form: jhonstart's renderer (`jhonstart_render.erl`) first, for 144 B-17, then every library front (145–162) in a step of its own. (3) A function with no wasm form — 100% Erlang or Node, or a real host effect (network, database, fs, process) — reached by a `comptime` is refused at build, located, naming the cell: `error: `Rodape` reaches jhonstart_render:escape/1, which has no wasm form — it cannot run at build (give it a botopink body, or remove `comptime`)`. No translation stands in for a missing wasm form at build (no beam-to-wasm fallback), and never the target's VM (c). The build's target does not narrow this: a `comptime` runs on wasm whatever `--target` is, so an erlang build reaching an `@External.Erlang`-only cell at build is refused as a commonJS build is. The comptime's reading is otherwise unchanged (388 (4): `RenderScope.root()`).
- **Measured.** 84 sent a comptime evaluation to the target's VM, so an erlang build rendered a `Build` / `Any` component at build on the BEAM (`render_resident`'s erl step) and a commonJS build on wat. 378 (4) asks the comptime runtime to run a component's lambda with `RenderScope.root()` (388) — `comptime renderToString(<Rodape ano={2026} />)`; 134 step 6's last box (144 B-17). Under 434 the only runtime is wasm, and jhonstart's renderer on the BEAM is a sidecar (`jhonstart_render.erl`).
- **Options.**
  (a) The renderer runs at build on wasm only: jhonstart's render path reached at build is botopink (or std-wasm), its Erlang cell translated by beam-to-wasm where it has no botopink body; the answer is one string for every target.
  ```bp
  val footer = comptime renderToString(<Rodape ano={2026} />);   // "<footer>2026</footer>" on the four targets
  ```
  (b) A component is rendered at build only when every function it reaches has a botopink or std-wasm body; one reaching an Erlang cell is refused at the `comptime`, naming the cell.
  ```text
  error: `Rodape` reaches jhonstart_render:escape/1, which has no wasm body — it renders at run time (remove `comptime`)
  ```
  (c) Keep the target's VM for at-build rendering alone (a BEAM step inside the compile for erlang/beam builds).
- **Recommendation.** (b) now — no at-build answer that depends on a translation not proved; (a) once beam-to-wasm covers the renderer's cells; never (c), which 434 removes.
- **Blocks.** 144 B-17 (134 step 6's 378 (4) box); nothing in B-00.

#### B-18-a · How is a template method found: by a name in the call site's scope, or through the receiver's type? (decisions 397, 415; 144 B-18)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): by a name in the call site's scope, as built** — `value.method "…"` resolves `method` as a template whose `self` takes the receiver, local or imported; nothing reaches a library's template without an import, as for every other name. A receiver's type never imports code by itself. Changes: 145's example imports `query`.
- **Measured.** Built as (a); 145's example writes `self.db.query """…"""` with no import of `query`.
- **Options.**
  (a) A name in scope.
  ```bp
  import {query} from "erika";
  self.db.query """select …"""
  ```
  (b) Through the receiver's type.
  ```bp
  self.db.query """select …"""   // erika's query found through Db, no import
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-18's lookup row; 145's example.

#### B-18-b · Confirm B-18's surface: `q.note`'s text, `bindings()` as `Decl[]`, `@Decl.module` on every handle (decisions 415, 426; 144 B-18)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): as built** — a note is appended to the mismatch line as `— note: …`, so a cell's `refused` line pins it; `bindings()` answers `Decl[]` and `Binding.ref()` goes with the `Binding` record (one handle, the `@Decl`); every `@Decl` carries `module`, not only a looked-up one.
- **Measured.** Built as (a).
- **Options.**
  (a) As built.
  ```bp
  // error: type mismatch: expected User, got Order — note: the query selects from orders
  ```
  (b) A note on its own line, `Binding` kept beside `Decl`.
  ```bp
  // error: type mismatch: expected User, got Order
  //   note: the query selects from orders
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-18's surface row.

#### B-19-a · Where is a type error inside a decorator's member or associated-type source located? (decisions 216, 281; 144 B-19)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): at the annotation that added it** (`#[maker]`), as `decorator-member-duplicate` is, with the decorator's `addMember` / `addType` call named in the message — the program's reader sees where the code came from; the decorator's author sees which call wrote it.
- **Measured.** The diagnostic points past the file's last line (the member's source has no span in the program).
- **Options.**
  (a) At the annotation, the call named.
  ```bp
  #[maker] pub type City(name: string)   // error here: in the member `make` that `maker`'s addMember wrote
  ```
  (b) At the `addMember` argument in the decorator's module.
  ```bp
  decl.addMember("make", fn() -> Self { … })   // error here, in the library
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-19's row 3.

#### B-19-b · `@TypeInfo.all(member: …)` by reference: what is written, and what does a type that does not conform do? (decisions 256, 281; 144 B-19 step 7)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): `member: Factory.make`, a behavior's associated fn; a catalogued type must `implement Factory`, and one that does not is refused at the query, naming it** — a reference is checked, a string was not (281); conformance by declaration, not by a matching name.
- **Measured.** `member: "make"` is a string today.
- **Options.**
  (a) Implementers only, refused otherwise.
  ```bp
  pub behavior Factory { fn make() -> Self; }
  @TypeInfo.all(with: entity, member: Factory.make)   // refused: `City` does not implement Factory
  ```
  (b) Any type declaring a matching associated fn; others skipped.
  ```bp
  @TypeInfo.all(with: entity, member: Factory.make)   // City skipped
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-19 step 7.

#### B-21-a · A lambda's last expression written with `;`: still its value? (decision 409; 144 B-21)
- **Answered (the maintainer, 2026-10-14; awaiting its number in `decisions-taken.md`):** 525-a (1): a lambda answers its last expression written without `;` (409, 525); `{ x -> x + 1; }` answers nothing — after `botopink format` removes, once, the `;` of every existing lambda's last expression statement. The reverse of the proposal.
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(b): keep it the value, for lambdas and untyped `fn(x) { … }` only** — 409's tail rule binds the bodies with a written return type (`fn`, method, typed `fn` expression); a lambda has no written return, its value has always been its last statement, and the formatter has always ended that line with `;`. Reading 409 strictly there means a codemod over 3,800 lambda bodies (std 180, `conformance/` 207, rakun 1855 …) for no rule a lambda gains. Viable: as built. Changes: 409's text names the bodies it binds.
- **Measured.** No named `fn`, method or typed `fn`-expression body ends without `;` anywhere; lambda bodies ending with `;` are std 180, `conformance/` 207, examples 5, emilia 373, erika 79, jhonstart 288, onze 372, rakun 1855, actions 12, http 7, log 20, routing 13, validation 389, css 3, styled 55, markdown 20.
- **Options.**
  (a) Strict: with `;` a lambda's last expression is a statement.
  ```bp
  xs.map({ x -> x + 1; })   // answers void: write `{ x -> x + 1 }`
  ```
  (b) A lambda's last statement is its value, `;` or not.
  ```bp
  xs.map({ x -> x + 1; })   // answers x + 1, as today
  ```
- **Recommendation.** (b).
- **Blocks.** 144 B-21's lambda row.

#### B-21-b · A method with no `->`: when is a non-`void` tail refused? (decisions 409, 06 C9; 144 B-21)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): only when the method has no valued `return`** — a method with no `->` infers its return from its `return`s (06 C9); with none it answers nothing and a non-`void` tail there is refused at it; with a valued `return`, the tail is one more of its answers, typed with them. Viable: the checker reads the body's valued `return`s before the tail. Changes: a cell.
- **Measured.** B-21's thread reported (a); its Conformance step measured `feat` refusing a non-`void` tail next to a valued `return` too, in a method and in a free fn — (b) as built.
- **Options.**
  (a) Refused only without a valued `return`.
  ```bp
  fn m(self: Self) { if (self.x) return 1; 2 }   // answers i32
  fn n(self: Self) { 2 }                          // refused: a value in a body answering nothing
  ```
  (b) Always refused without `->`.
  ```bp
  fn m(self: Self) { if (self.x) return 1; 2 }   // refused: write `-> i32`
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-21's method row.

#### B-21-c · Does the formatter print a `case` arm block's last expression as written? (decision 409; 144 B-21)
- **Answered (the maintainer, 2026-10-14; awaiting its number in `decisions-taken.md`):** 525 and 525-a (3): the formatter removes, once, the last `;` of a `case` arm used as a value and the arm's `break <value>`, making the arm's tail its value; elsewhere it prints a block's last expression as written (409's formatter rule).
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): yes — as written, like a body's tail** — the printer adds and removes no `;` anywhere (409's formatter rule), an arm block included; one rule for every block.
- **Measured.** The formatter adds `;` to a `case` arm block's last expression; 409's text covers function bodies.
- **Options.**
  (a) As written.
  ```bp
  case s { Circle(r) -> { val d = r * 2; d } }   // printed as written
  ```
  (b) `;` added in arms.
  ```bp
  case s { Circle(r) -> { val d = r * 2; d; } }
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-21's arm row.

#### B-22-a · A bare variant constructor in an expression (`Num(4)` for `Value.Num(4)`)
- **Answered (the maintainer, 2026-10-14; awaiting its number in `decisions-taken.md`):** (a), with B-10-d (the same question): refused, located, naming the qualified form — `` `Num` is a variant of `Value` — write `Value.Num(4)` ``; `Value.Num(4)` and `val c: Value = .Num(4)` stay; a bare variant stays a `case` pattern's (decision 8).
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): a bare variant constructor in an expression is refused, located, naming the qualified form** — `val a = Num(4);` is `` `Num` is a variant of `Value` — write `Value.Num(4)` ``; `Value.Num(4)` and `val c: Value = .Num(4)` (the expected type names the enum) stay the two legal forms; a bare variant stays a `case` pattern's (decision 8, the subject fixes the enum). Refuse over accept (67): today `check` passes and commonJS, erlang and beam fail at run time (`Num is not defined`, `function 'Num'/1 undefined`, `{unresolved_call,'Num',1}`) while wasm prints an address — four wrong answers; (b) would add a fourth spelling to every backend. Viable: `infer.zig` `registerEnum` binds the bare name (`env.bind(v.name, ctorType)`, `noteVariantClaim`), and `refuseAmbiguousVariant` refuses two claimants — the single-claimant call path becomes the refusal for a non-pattern use, the pattern path kept; one refusal cell. Changes: `conformance/docs.md` § type — enums; two defects to file beside it: on wasm an unannotated `val b = Value.Num(4); @print(b)` prints an address, and `"${b}"` of a payload variant prints `[object Object]` / an erlang tuple / an address by target (no printer for a variant in a template; the 01-compiler row in `status.md` names the enum half).
- **Measured.** The checker admits `val v = Num(4);` for `type Value { Num(n: i32), … }`; erlang, beam and commonJS then fail on an unbound `Num` at run time (`conformance/docs.md` § type — enums records the defect today). Decision 8's pattern rule allows a bare variant in a `case` pattern, where the subject fixes the enum; an expression has no subject.
- **Options.**
  (a) Refused, located, naming the qualified form; the leading-dot `.Num(4)` with an expected type stays legal.
  ```bp
  val a = Num(4);          // error: `Num` is a variant of `Value` — write `Value.Num(4)`
  val b = Value.Num(4);    // legal
  val c: Value = .Num(4);  // legal, the expected type names the enum
  ```
  (b) Legal: every backend lowers the bare constructor to the variant's.
  ```bp
  val a = Num(4);          // Value.Num(4) on every target
  ```
- **Recommendation.** (a) — the strictest reading: refuse over accept, the qualified form and the leading-dot form kept; a bare variant stays a `case` pattern's (decision 8).
- **Blocks.** The checker row and the three backends' failure; `conformance/docs.md` § type — enums.

#### B-22-b · How does a value of an enum section print? (144 B-22; `docs.md` § Sections of an enum)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): the leaf's whole path, as written** — `@print(Token.Color.White)` writes `Token.Color.White` on every target; a name at two levels (`Token.After` and `Token.Layout.Break.After`) stays two texts. One text for a value on every target (434 (5)), and no internal name (`_inner`, `__Token__Color`) in a program's output. Viable: each backend's printer for an enum value reads the section path the checker already resolves. Changes: a cell `enum_section_value_print` on the four targets; `docs.md` § Sections of an enum.
- **Measured.** `val t = Token.Color.White; @print(t)`: commonJS, erlang and beam print `Token.Color(_inner: __Token__Color.White)` (the section's wrapper record and its internal enum name), wasm an address. No cell states the answer.
- **Options.**
  (a) The leaf's whole path.
  ```bp
  val t = Token.Color.White;
  @print(t);   // Token.Color.White
  ```
  (b) The leaf's name alone.
  ```bp
  val t = Token.Color.White;
  @print(t);   // White
  ```
- **Recommendation.** (a) — the path tells two leaves of one name apart, and it is the text the program wrote.
- **Blocks.** 144 B-22's enum-section row; status.md's 05-wasm row.

#### B-22-d · A bare name inside a multi-subject arm: a binding, or refused like a name alone? (144 B-22)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): refused, as a name alone is** — `docs.md` says a name alone is not a pattern, and the braced form already refuses it inside a multi-subject arm; the arrow form follows: `_` for any, a pattern to bind. One rule for every arm. Changes: `case_multi_subject_patterns` rewritten with patterns.
- **Measured.** The arrow form binds `Shape.Square(side), m -> …` and `_, y -> …` (`case_multi_subject_patterns` pins it); the braced form refuses the same arm.
- **Options.**
  (a) Refused.
  ```bp
  case s, n { Shape.Square(side), m -> side + m; }   // refused: `m` is a name alone
  ```
  (b) A binding.
  ```bp
  case s, n { Shape.Square(side), m -> side + m; }   // m binds n
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-22's multi-subject row.

#### B-23-a · Decision 310: does a type of this module beside an aliased import of a same-named type count as two modules? (decision 310; 144 B-23)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): yes** — `type T` declared here and `import {other.T as U}` are two types, legal under 310 like two imports: the alias is the program's name for the other module's type, and identity is by module. Refusing it would make 310 depend on where a declaration sits. Viable: with 310's module-qualified identity (B-23's open row), nothing more. Changes: a cell beside `import_two_types_one_name`.
- **Measured.** Today the checker and the four backends name a type by its declared name, so both forms collide (`import-name-collision` for two imports); 310 is open.
- **Options.**
  (a) Two types.
  ```bp
  import {shapes.Box as ShapeBox};
  pub type Box(v: i32)
  val a = Box(v: 1);  val b = ShapeBox(w: 2);   // accepted, two types
  ```
  (b) Refused: a local type and an alias of a same-named type collide.
  ```bp
  import {shapes.Box as ShapeBox};   // refused: `Box` is declared in this module
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-23's 310 row.

#### B-23-b · A raise in the module's own template: located at the call site, or at the call that raised? (decision 451 (3); 144 B-23)
- **Answered (the maintainer, 2026-10-14; awaiting its number in `decisions-taken.md`):** B-48-a: at the call that raised, inside the template body, in its own file (451 (3)), with every call of the chain as a `called from` line down to the program's use of the template — one rule for every comptime body, the module's own template included. As proposed.
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): at the call that raised, inside the template's body, as a decorator in the same module is (451 (3))** — one rule for every comptime body; another module's template already names its file and line. Changes: the cells that pin such a raise move their location.
- **Measured.** Another module's template names `src/tpl.bp:3:5` (`template_raise_names_body_file`); the module's own template is reported at the call site with no line in its body.
- **Options.**
  (a) At the raising call.
  ```bp
  // error at 4:9 in the template's body — while `shout` ran the template's body
  ```
  (b) At the call site, as built.
  ```bp
  // error at the call `shout "x"`
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-23's template-raise row.

#### B-25-a · Confirm B-25's wasm gate adapters and the cells left unbound (decisions 334, 335 (3); 144 B-25)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): as built** — `.GateNew`, `.GateOpen`, `.GateAwait` (a gate is a pending task no host answers; opening it drops each pending wait's timer); std's test-only cells (`monoMillis`, `hostTarget`, `newCounter`, `countUp`, `countOf`, `panicOf`) stay unbound on wasm until `botopink test` runs wasm (335 (3)), so 334's "twelve cells" are `async`'s user-facing ones.
- **Measured.** Built as (a); `std_async_on_every_target` green on four targets and both hosts.
- **Options.**
  (a) As built.
  ```bp
  @External.Wasm(wasi: .GateNew)
  ```
  (b) The test cells bound too, now.
  ```bp
  @External.Wasm(wasi: .GateNew)   // and countUp, countOf … bound on wasm
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-25's adapter row.

#### B-25-b · `fetch`'s surface before `io/http` binds on wasm: `Request`, `HttpError`, the old `fetch(url)` (decisions 334, 393; 144 B-25)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): std fixes it in 144 first, `fetch(url)` removed in the same commit** — `fetch(req: Request) -> @Task<@Result<Response, HttpError>>`, `Request(method, url, headers, body: ?Bytes)`, `HttpError { NotAllowedOnHost, Network(message: string), Timeout }`; the call sites (std, `http`) migrate in the landing (one spelling, 67).
- **Measured.** std has only `fetch(url) -> @Result<Response, string>`; no `Request` or `HttpError` exists.
- **Options.**
  (a) The typed surface, the old form removed.
  ```bp
  val r = await fetch(Request(method: .Get, url: u, headers: [], body: null));
  ```
  (b) The typed surface beside `fetch(url)`.
  ```bp
  val r = await fetch(u);   // still accepted
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-25's `io/http` rows (steps 4, 5, 6, 17).

#### B-25-c · log's two wasm markers: a host value per name and `wasi:filesystem`, or 405's interim in log? (decisions 334, 405; 144 B-25)
- **Answered (the maintainer, 2026-10-14; awaiting its number in `decisions-taken.md`):** Neither: fs-a supersedes both markers — `io.fs` gains wasm bindings (`wasi:filesystem`, `needs: [.Filesystem]`), so log's file cells call `io.fs` on wasm as on every target, no adapter of log's own and no interim; on the browser host the call is refused at the call (fs-a). 156's two markers are removed.
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): 405's interim in log now** — the file cells bound to a `fn:` that reaches no file on wasm, located refusal at use; the host-value-per-name adapter and `wasi:filesystem` wait for a decision of their own. No B-25 box and no decision fixes either adapter's shape.
- **Measured.** log's two markers name both needs; neither adapter exists.
- **Options.**
  (a) 405's interim.
  ```bp
  @External.Wasm(fn: noFileOnWasm) fn appendLine(path: string, line: string)
  ```
  (b) Both adapters designed in 144 now.
  ```bp
  @External.Wasm(wasi: .FileAppend) fn appendLine(path: string, line: string)
  ```
- **Recommendation.** (a).
- **Blocks.** 156's wasm markers.

#### B-27-a · A `.bpp` header declaration written after a statement: moved or refused? (decisions 199, 212; 144 B-27)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): refused at the declaration, located, naming the statement before it** — the header reads top to bottom as written; a declaration after a statement would run in an order the file does not show. Changes: a refusal cell; the unfold stops moving it.
- **Measured.** The unfold moves it after the function, its location mapped back.
- **Options.**
  (a) Refused.
  ```bp
  val n = props.count;
fn label() -> string { … }   // refused: a declaration after a statement
  ```
  (b) Moved, as built.
  ```bp
  val n = props.count;
fn label() -> string { … }   // moved to module level
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-27's unfold row.

#### B-27-b · How does an importer spell a `.bpp` file whose name is not an identifier (`not-found.bpp`)? (decisions 199, 289; 144 B-27)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): it does not — such a file is a route's leaf, read by the router by path, never imported; importing it is refused naming the file** — a module name is an identifier everywhere else.
- **Measured.** No importer spelling exists; `not-found.bpp` is jhonstart's convention.
- **Options.**
  (a) Not importable.
  ```bp
  import {not-found};   // refused: `not-found.bpp` is read by the router, not imported
  ```
  (b) A quoted path.
  ```bp
  import "not-found" as NotFound;
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-27's `not-found.bpp` row.

#### B-27-c · 97 s6 under decision 506's answer (c): what are its boxes? (decision 506; 144 B-27)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): the step is rewritten to (c)'s std half, its (a) / (b) boxes removed** — the coordinator writes it from 506 (c)'s text at the next spec pass; this question records that the step as written cannot be built.
- **Measured.** 506 answered (c); 97 s6's boxes are written for (a) and (b).
- **Options.**
  (a) Rewritten to (c).
  ```bp
  // 97 s6: (c)'s std half
  ```
  (b) Kept as written.
  ```bp
  // 97 s6: under (a) … under (b) …
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-27's 97 s6.

#### 116-a · The prelude module's own `import {bpp} from "std"` (decision 361 × 270) (*proposed*)
- **Answered (the maintainer, 2026-10-12; awaiting its number in `decisions-taken.md`):** **(f), a sixth option: the prelude is the items marked `#[bpp.htmlPrelude]` where they are declared, one by one.** A marked `pub val` / `pub fn` / `pub type` of a module the package's root (s23-i) reaches through `pub mod` only — the root itself included — is in the prelude: a `.bpp` sees it by its plain name without importing (`#[bpp.htmlPrelude] pub fn Card(…)` in `src/components.bp`, `pub mod components;` in the root, `<Card/>` in a `.bpp`). The root re-exports nothing for it. A `pub` item without the marker is the library's API, not the prelude. Imports are private — the `import {bpp} from "std";` each marked module needs included — so none reaches a `.bpp`. No name is shadowed: two marked items of one name, or a `.bpp` that declares or imports a name the prelude already gives, is refused, located, naming both places (`` `Card` is already in the prelude (src/components.bp:4) — rename one ``). Refused, located: the marker on an item without `pub`, on a `mod`, in a module reached through a private `mod` (`` `X` is marked for the prelude but `internal` is a private mod — make it `pub mod` or drop the mark ``), or on an item re-exporting another package's item (242). `src/prelude.bp` and its `pub val prelude = bpp.Prelude()` go. Front 116 lists a package's prelude — every item, its name and where it is declared — by `botopink prelude` and in the language server (a `.bpp` name's origin on hover). Amends 361 and 270. **Under B-55-a (e)** (2026-10-12): the prelude is any marked `pub` item outside `src/internal/`; there is no root to reach it from.
- **Measured** (front 116 step 1). 361 puts the prelude's marker in the prelude
  module — `#[bpp.htmlPrelude] pub val prelude = bpp.Prelude();` — so the module must import std's
  `bpp` (jhonstart's `src/prelude.bp` now ends `import {bpp} from "std"; #[bpp.htmlPrelude] pub val
  prelude = bpp.Prelude();`). 270 says "that module's imports are the prelude" and refuses, at the
  line, "an item of another package (242)". Read together, the marker's own import is both a prelude
  item (every `.bpp` file would resolve `bpp` through it) and a refused line. Step 1 checks only that
  the module holds imports and its marker; the prelude scope and its refusals are step 2's.
- **Options.**
  (a) The import of std's `bpp` (or a leaf of it) is the marker's, not the prelude's: left out of the
  item list handed to `compiler-core`, and exempt from 242's refusal — every other `from "std"` item
  in a prelude stays refused:
  ```bp
  // src/prelude.bp
  import {element.Element};          // a prelude item
  import {bpp} from "std";           // the marker's import — not a prelude item, not refused
  #[bpp.htmlPrelude]
  pub val prelude = bpp.Prelude();
  // Card.bpp: `bpp.Prelude()` in its header is `unbound variable 'bpp'`
  ```
  (b) The marker's import is a prelude item like any other: a `.bpp` file resolves `bpp` without
  importing it, and 242's refusal exempts std:
  ```bp
  // Card.bpp header: `val p = bpp.Prelude();` compiles through the prelude
  ```
  (c) 242 stands for the prelude: a prelude module may import nothing from another package, so the
  marker is spelled through a path the language does not have today (a qualified annotation with no
  import, `#[std.bpp.htmlPrelude]`), a parser and checker change:
  ```bp
  #[std.bpp.htmlPrelude]
  pub val prelude = Prelude();   // `Prelude` unbound: (c) needs a qualified constructor too
  ```
- **Recommendation.** (a): the prelude stays the package's own modules (242), and the one import the
  marker needs reaches no `.bpp` file.
- **Blocks.** 116 step 2's prelude box (the item list and its refusals); nothing in step 1.

#### s23-a · Two field names of decision 277's records (contradiction with the reserved words)
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **(a), as built.** `HookNode(function: Declared<unknown>, uses: HookUse[], calls: HookCall[])` and `HookUse(…, context: ?Declared<unknown>)`, read `n.function.name` and `u.context.name` by a decorator at build; 277's `fn` is a reserved word and is not a field name.
- **Measured.** 277 writes `HookNode(fn: Declared<unknown>, …)`; every keyword is reserved in every position
  (`reserved-word-as-name`: `type N(fn: string)` is refused at the field). 354 (4) asks `Decl.hooks` to carry each
  `provide` / `context` "with its object" and names no field. Built (`01-checker` step 23): `HookNode(function:
  Declared<unknown>, uses: HookUse[], calls: HookCall[])` and `HookUse(…, context: ?Declared<unknown>)`, read
  `n.function.name` and `u.context.name` (`run/decl_hooks_context` prints `App: std/context.provide(main.ThemeContext)`).
- **Options.** (a) As built: `n.function`, `u.context`. (b) `n.decl` / `u.target`: `n.decl.name`, `u.target.name`.
  (c) `n.of` / `u.object`: `n.of.name`, `u.object.name`.
- **Recommendation.** (a): the words the decisions use for them, no exception to the reserved words.
- **Blocks.** Nothing — built as (a); a rename touches `builtins.d.bp`, `comptime.zig`'s mirror, `hooks.zig` and the cells.

#### s23-g · Where `Decorator.same` is declared (371's `extend Decorator { … }` does not parse)
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **(a), as built.** `pub behavior Decorator { fn same(self: Self, other: Decorator) -> bool; }` in `builtins.d.bp`, mirrored in `comptime.zig`'s `decl_reflection_src`; 371's anonymous `extend Decorator { … }` reads as this member, and `a.decorator.same(serverOnly)` is unchanged.
- **Measured.** 371 writes `extend Decorator { pub fn same(self, other: Decorator) -> bool; }` in `builtins.d.bp`. An
  `extend` is always named (`'extend' needs a name`, `parser.zig` `reportAnonImplExtendError`), `builtins.d.bp` is
  parsed by the drift test (`comptime/builtins.zig` `collectTypes`), and that test holds a builtin type's instance
  methods inside its declaration. Built and landed: a member of the behavior, mirrored in
  `comptime.zig`'s `decl_reflection_src` — `pub behavior Decorator { fn same(self: Self, other: Decorator) -> bool; }`;
  `a.decorator.same(serverOnly)` reads the same either way.
- **Options.** (a) As built: `pub behavior Decorator { fn same(self: Self, other: Decorator) -> bool; }`. (b) A named
  extension: `pub DecoratorIdentity extend Decorator { fn same(self: Self, other: Decorator) -> bool; }`, the drift
  test taught to read an `extend`'s methods into its target. (c) The parser takes an anonymous `extend Decorator { … }`
  in `builtins.d.bp` only.
- **Recommendation.** (a): no exception to the parser for one file, and the drift test already holds it.
- **Blocks.** Nothing — built as (a).

#### B-55-a · Whole-package analysis: may two modules of a package import each other? (s23-i, 372, 419, 130-s8-c, 14s8-d)
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **(e), a counter-proposal: a file is a module, and the build has a layer of its own.** (1) Every `.bp` under `src/` is a module of the package, its path its name (`pages.home`, `comptime.route`); no `lib.bp`, no `mod` / `pub mod`. (2) `src/main.bp` is an executable's entry (`pub fn main()`), imported by no module; a library has none. (3) `src/comptime/` is the build layer: analysed before every other module of the package, it imports only std, dependencies and `src/comptime/` itself (else refused, located); a decorator or a template is declared only there, in std or in a dependency (else refused, located). (4) The program's modules import each other freely: modules importing each other form a block (a strongly connected component); a block's headers (`fn` signatures, types, annotated `val`s) are registered before its bodies; at run time a module-level `val` is a ref, a memoised getter (commonJS hoists its functions onto `exports` before any `require`). (5) Per block: headers, bodies, then every decorator over them (the build layer is already compiled), then every `@typeInfo(X).meta(T)` and catalogue of the block is filled — 130-s8-c's step 4, per block. (6) The only order refusal is `dependency loop`, located: a value needing itself across modules (`pub val x = b.y + 1` / `pub val y = a.x + 1`), or a `comptime` needing a meta, a catalogue or a value of its own block before its decorators ran. (7) `@TypeInfo.all` is read in any module. (8) `src/internal/` is private to its package; every other `pub` item is the package's API. (9) The prelude (116-a) is any marked `pub` item outside `internal/`. Replaces s23-i's root rules (`lib.bp`, `mod`, the catalogue in the root), 419's and 14s8-d's refusals and 353's second compile; B-56 stands. The cost on `zig build test` and on the language server is measured before the implementation steps; a high cost returns the question to the maintainer.
- **Measured.** Today the resolver sorts a package's modules by their imports and each module is analysed whole before its importers (372's three phases, then `registerExports`); a cycle is not refused by name — the parent reports an unrelated `unbound variable` (`error: unbound variable 'base' --> src/b.bp:4:18` for `a ↔ b`). A function's signature never depends on its body (an omitted return type is `void`). A prototype (144 B-55, not landed) orders a cycle as one strongly connected component and registers its modules' headers (signatures, types, annotated values) before their bodies: the maintainer's `a.title` ↔ `b.format` / `b.header` and `a.isEven` ↔ `b.isOdd` run on erlang, beam and wasm; `pub val x = b.y + 1` / `pub val y = a.x + 1` is refused, located: ``dependency loop: `a.x` → `b.y` → `a.x` ``. Headers alone are not enough: `home.bp` and `blog.bp` importing each other, each `#[route]`-decorated and reading the other's `@typeInfo(X).meta(Route)`, print `none` for the module analysed first — the meta must be demanded, its decorator run on demand. commonJS's `const { f } = require(…)` answers `undefined` for a function and a value of a `require` cycle (`TypeError: title is not a function`); hoisting the functions onto `exports` before any `require` and making module-level values memoised getters runs the cycle correctly (checked by hand under node). The cost on `zig build test` and on the language server's check is not measured yet.
- **Options.**
  (a) Keep the acyclic rule, with its own refusal: the resolver names the cycle, located, in place of `unbound variable`; 419, 130-s8-c (b′)'s step 4, s23-i's root rules and 14s8-d's refusal stay.
  ```text
  error: import cycle: src/a.bp imports src/b.bp, which imports src/a.bp — modules of a package import each other acyclically
  ```
  (b) Adopt whole-package on-demand analysis, keeping s23-i's root rules: modules of a package import each other freely; a declaration is analysed when something needs it (a `fn` or type by its header, a `val` whole, a meta by running its decorators over the bodies it reads); the only refusal is a `dependency loop`; 130-s8-c's step 4 becomes the general rule, 419 and 14s8-d's refusal go, 353's second compile goes; `@TypeInfo.all` stays in `lib.bp` (or `main.bp` without `lib.bp`) and no module imports the root. Steps: (i) the resolver's components and an `import-cycle` refusal until (ii)–(iv) land; (ii) a package `Env`, lazy imports, header and body states; (iii) a `val` demanded whole, `dependency loop`; (iv) plain decorators in the header; (v) meta on demand (`.hooks` readers); (vi) the catalogue on demand; (vii) 14s8-d; (viii) commonJS's hoisted exports and lazy values; (ix) the language server checks the edited module's component and its importers.
  ```bp
  // src/a.bp
  import {b.format};
  pub fn title(x: string) -> string { return format(x) + "!"; }
  // src/b.bp
  import {a.title};
  pub fn format(x: string) -> string { return x.toUpper(); }
  pub fn header() -> string { return title("hi"); }        // "HI!"
  // src/c.bp, src/d.bp
  pub val x = d.y + 1;   pub val y = c.x + 1;   // error: dependency loop: c.x needs d.y, which needs c.x
  ```
  (b′) As (b), with s23-i's root rules relaxed: `@TypeInfo.all` read in any module and any module may import the root; a catalogue whose value the build needs inside a declaration it lists (or one its hooks reach) is the `dependency loop`.
  ```bp
  // src/pages/index.bp
  pub val pages = @TypeInfo.all(with: route);                 // a run-time value: answered after every #[route]
  pub val nav = comptime renderNav(@TypeInfo.all(with: route)); // in a #[route] page: dependency loop
  ```
- **Recommendation.** (b) — one rule (a dependency loop) in place of four order-dependent refusals, and an answer that no longer depends on which module the resolver placed first; s23-i's root rules kept (decision 67's strictest reading, and the tidy tree they were chosen for) until a front needs (b′). Until (b)'s step (ii) lands, (a)'s located refusal replaces today's `unbound variable`.
- **Blocks.** Nothing built depends on it; 144 B-55's follow-up steps, 130-s8-c's step 4 and s23-i's catalogue rule are written against the answer.

#### B-60-a · A dependency's `.d.bp` that does not check: does `build` refuse it as `check` now does? (decisions 514, 515; 144 B-60)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): every command refuses it** — `build`, `run`, `test` and `cell check` stop on a dependency's `.d.bp` with an error, as `check` does since 514/515 made the module set one; one module set, one answer (67: refuse over accept). Viable: `check.zig` renders every module's errors; `build` drops a failure in a declaration file alone — that branch becomes the refusal. Changes: a cell (a dependency whose `.d.bp` names an unknown type) refused on every command.
- **Measured.** Since 514/515 `check`, `test` and `cell check` keep a dependency's `.d.bp` modules as `build` and `run` do. `check` renders and fails on any module's error, so a dependency whose `.d.bp` does not check fails `check`; `build` ignores a failure in a declaration file alone and builds.
- **Options.**
  (a) Every command refuses a dependency's `.d.bp` that does not check.
  ```bp
  // deps/shapes/src/shapes.d.bp
  pub declare fn area(r: Rectt) -> f64;   // unknown type
  ```
  `botopink check` and `botopink build` both: `error: unknown type 'Rectt' --> deps/shapes/src/shapes.d.bp:2:25`.
  (b) `check` follows `build`: a failure in a dependency's declaration file alone is ignored by every command.
  ```bp
  // deps/shapes/src/shapes.d.bp
  pub declare fn area(r: Rectt) -> f64;   // unknown type
  ```
  `botopink check` and `botopink build` both succeed; the error appears only where `area` is called.
- **Recommendation.** (a) — the strictest reading: a broken declaration is an error wherever it is read, and the two commands answer one module set alike.
- **Blocks.** Nothing today; the cell and `build`'s branch.

## Machine 2 — maximum priority (front 144, `machine-2-backends-tooling/`)

The questions that hold a step of machine 2 (backends, runtimes, std, tooling, the gate), answered with machine 1's
before every other part of this page; most urgent first: B-07-a holds a commit already built, B-29-a every
Conformance step, the rest one step each but 17-c, which holds nothing built (B-26's surface stands until widened).
Machine 1's B-60-a holds machine 2's B-77 too.

#### 521-a · An `f64` that reaches commonJS's text only through a generic `T` loses its `.0` (decision 521; 144 B-78)
- **Proposed (sonnet, 2026-10-14; awaiting the maintainer):** **(a): a generic body that writes a `T` as text receives the text function of its type argument** — the call site, which knows `T`, hands the body a hidden `show` for it (as the checker already specialises per call); one JS body per function kept.
- **Measured.** Since 521 commonJS writes an `f64` as std-wasm does (`5.0`, `1.0e21`) wherever the checker knows it is an `f64`. A float reaching only a type parameter — `Box<T>(value: 2.0)` printed, `fn show<T>(v: T) { "${v}" }` called with `3.0` — prints `2` / `3`: a JS number carries no `f64` / integer distinction, and one JS body serves every `T`. erlang, beam and wasm print `2.0` / `3.0`.
- **Options.** (a) A hidden text function per type parameter used as text, passed at the call. (b) A boxed `f64` on commonJS (an object or a tagged number), everywhere — a cost on every float. (c) Specialise every generic body by its type arguments on commonJS.
- **Recommendation.** (a) — the cost lands only where a generic writes a `T` as text.
- **Blocks.** The 04-js row (a float through a generic `T`); one text for a value on every target (434 (5)).

#### 529-a · What `..` as the one spread leaves open (decisions 529 (3), 359, 37; 144)
- **Proposed (sonnet, 2026-10-14; awaiting the maintainer):** **(a) for each:** (1) no migration tool — no library writes a `...` call-site spread today (jhonstart's one `{...pairs}` is a tag spread the compiler does not implement yet); (2) 37's refusal of a non-name base is gone: 359 (6) allows any source expression, evaluated once (`record_update_base_not_a_name` answers `out 1`); (3) an enum variant's `..` update stays refused as `call-spread` (359's enum-variant row); (4) the dead decision-37 update path in `infer.zig` is deleted.
- **Measured.** 529 (3) landed: `..src` is the record spread, `...src` as a spread is `spread-dot-dot-dot` naming `..`, the formatter prints `..`, botopink-lang migrated. Merging the two spread forms moved three answers: `record_update_base_not_a_name` (a refusal under 37) now answers `out 1` under 359 (6); `Subject.Animal(..alice)` is `call-spread` (it was a type mismatch); two refusal carets moved one column (the shorter `..`). The parser refuses `...`, so the formatter cannot read an old `...` spread to migrate it.
- **Options.** Each point (a) as proposed or (b): (1) the parser keeps reading `...` for one release, the formatter rewriting it; (2) 37's restriction kept under 359; (3) an enum variant's update allowed; (4) the old path kept.
- **Recommendation.** (a) — 359 is the later rule, no library needs the old spelling.
- **Blocks.** Nothing built; `record_update_base_not_a_name`'s answer.

#### 529-b · What a record parameter `..props: R` leaves open (decision 529 (2); 144)
- **Proposed (sonnet, 2026-10-14; awaiting the maintainer):** **(a) for each:** (1) a record parameter beside a variadic refused (`record-param-variadic`) — positional variadic arguments and labelled fields clash; (2) a default on the record parameter refused (`record-param-default`) — `R`'s own field defaults are the defaults; (3) positions count the other parameters: in `fn f(a, ..p: R, b)`, `f(1, 2, x: 3)` passes `2` to `b`; (4) methods and associated functions take a record parameter as functions do (a later step builds it); (5) a generic `R` (`..p: Props<T>`) is legal, its fields typed by the call.
- **Measured.** 529 (2) landed for plain function calls: `..props: R` is an ordinary parameter of type `R`; the checker rewrites a call's labels naming `R`'s fields, and a `..src` spread, into one `R(…)` construction; four refusals 529 names have cells. Built beyond 529 and to confirm: (1) and (2) above; (3) is how positions are read today; methods and associated functions are not rewritten yet; a generic `R` parses and is untested.
- **Options.** Each point (a) as proposed or (b) its opposite.
- **Recommendation.** (a) — the strictest readings where 529 is silent, and the same rule for every callable.
- **Blocks.** A record parameter on a method; nothing built otherwise.

#### 543-a · What front 164 s1 (wasmtime) leaves open (decision 543)
- **Proposed (opus, 2026-10-14; awaiting the maintainer):** **(1) Winch with the cache** — a cold compile 315 ms against Cranelift's ~1000 ms, a run 37 against 33 ms; (2) the CLI and the LSP call `interrupt()` on SIGINT, so a runaway body ends as a located error; (3) `attempt` at build catches what it catches in a wasm program — an integer division by zero traps there, so it is excluded at build too (one answer, 434 (5)); (4) the compiled-module cache is reaped by B-77's `botopink cache`.
- **Measured.** s1 landed on wasmtime v49 with Cranelift and the compiled-module cache (warm 48 ms, cold 1.0–1.3 s for 12 builds); Winch was not one of 543's two options; no SIGINT handler is installed (Ctrl-C ends the process; `interrupt()` exists, nothing calls it); `attempt` at build also catches an integer division by zero, which traps in a wasm program; the cache has no reaping until B-77.
- **Options.** Each point (a) as proposed or (b): (1) keep Cranelift; (2) no handler; (3) keep catching at build; (4) a size bound now.
- **Recommendation.** (a) for each.
- **Blocks.** Nothing built.

#### 539-a · `throw` and a propagating `try` inside a `defer` body: refused or allowed? (decision 539 (5); 144)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(c): refuse a `throw` and a `try` that propagates, located (`defer-throw`, `defer-try`); a `try … catch` handled inside the body stays** — 539 (5)'s reason is "cannot leave the path", and a throw leaves it: in `finally` / `after` the deferred error replaces the error being propagated, masking it silently. Zig refuses `try` in a `defer`, Swift refuses throwing.
- **Measured.** 539 landed on every target with `return`, `break` / `continue` out of the body, `yield` and `await` refused; a `throw` or a propagating `try` in the body compiles, and its error replaces the block's own on commonJS, erlang and beam.
- **Options.** (a) Refuse both forms, `catch` included. (b) Allow: the deferred error replaces the block's (today, undocumented). (c) As proposed.
- **Recommendation.** (c).
- **Blocks.** Nothing built; two refusal cells once answered.

#### 539-b · Does a `defer` add `.exceptions` to the program's `needs`? (decisions 539 (3), 518; 164)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(a): a function holding a `defer` adds `.exceptions`** — 518 (2) gathers what the program reaches; a `defer`'s lowering reaches the panic tag exactly as `attempt` does, with no annotation, so 518 (3) holds.
- **Measured.** On wasm with exceptions off a panic traps and the block's defers do not run; erlang and node run the defer before an uncaught panic ends the process. The cell `defer @print("x"); @panic("y")` in `main` answers `x` then the abort on every target but wasm.
- **Options.** (a) A function holding a `defer` adds `.exceptions`. (b) Only when `attempt` is also reached (today). (c) A `defer` refused on wasm when nothing adds `.exceptions`.
- **Recommendation.** (a) — one answer on every target (434 (5)).
- **Blocks.** The cell above, red on wasm until it lands (164 s2b).

#### 537-a · `catch` over a left side that is not a bare `try e` (decision 537; 144)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(a): `catch` delimits a try region** — every `try` in its left side is caught by it, on every backend (the checker reads the region as the fallible channel; the backends wrap the left side); it is the reading 537's own example asserts, and it makes `x.a + try f() catch 0` mean one thing.
- **Measured.** `try e catch h` folds into one `tryCatch`; any other left side (`(try await t) + 1 catch 0`, 537's example) parses as 537 says, but its inner `try` is checked against the function's channel: refused `effect-try-without-fallible-channel` without a `@Result` channel, and with one the `try` propagates to the function and the `catch` is reached by nothing. 537 fixes the parse, not what `catch` catches.
- **Options.** (a) As proposed. (b) Refuse a `catch` whose left side is not `try e` / `try await e`, "parenthesise the `try`" — against 537's "no refusal remains". (c) Keep as built and document that `catch` binds only a leading `try`.
- **Recommendation.** (a); cell `catch_region_covers_left_side`.
- **Blocks.** A 144 row (the checker and four backends), machine 2.

#### 537-b · `??`'s precedence against 537's parenthetical (decisions 537 (2), 28, 330)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(b): keep `??` tight; 537 (2) amended to "`catch` is the infix of the lowest precedence, below `??`"** — no program changes meaning, and 330's parenthesisation rule already covers the one ambiguous neighbour.
- **Measured.** 537 gives `catch` "`??`'s precedence, below every arithmetic operator", but `??` is the tightest binary level (decision 28), refused beside `&&` / `||` (330). std relies on it: `libs/std/src/hash.bp` (`h.at(2 * i) ?? 0 * 65536.0 + …`), `io/random.bp` (`64 + b.at(6) ?? 0 % 16`). The build made `catch` the lowest and left `??` alone.
- **Options.** (a) `??` moves to `catch`'s level, with a formatter rewrite parenthesising every `??` beside an arithmetic operator. (b) As proposed. (c) `??` at `||`'s level (JS), `catch` below it — the same migration as (a).
- **Recommendation.** (b).
- **Blocks.** Nothing built; 537's text only.

#### 541-a · When the lambda-`;` migration leaves the formatter (decision 541)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(a): the rewrite kept under an explicit `botopink format --migrate 541`, removed once every repository under `repository/` and every open branch is migrated** — a branch rebased past the rule without the migration gets the silent `void` 541 was written to prevent, and `feat`'s formatter cannot repair it.
- **Measured.** The migration lived in one botopink-lang commit and left at the next, which made the rule take effect; the libraries are migrated with a binary built at the first. vscode-extension, cardume, open branches and user code have no migration in `feat`'s compiler.
- **Options.** (a) As proposed. (b) As built: the coordinator runs the migration binary over every branch at its rebase, the rule written in `fronts.md`. (c) The rewrite re-added unconditionally until 524's reformats land.
- **Recommendation.** (a); (b) acceptable if the binary is kept and the rule written down.
- **Blocks.** Every library landing across the rule; 524's reformats.

#### 541-b · An untyped `fn(x) { x * 2; }`: still its value? (decisions 541 (1), 409; 144)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(a): 409 strict — an untyped `fn` expression answers nothing with `;`, the lambda's rule** — one rule for every unwritten return type.
- **Measured.** 409: "in every body … a `fn` expression and a lambda … with `;` it is a statement"; 541 reversed B-21-a's option (b), which grouped lambdas and untyped `fn(x) { … }` together. The cell `lambda_last_statement_semicolon` (line 5, `out 8` for `dbl(4)`) and `conformance/docs.md` § Lambdas assert the untyped `fn` expression keeps the value, citing 409; the compiler keeps it (the discard runs for a lambda only).
- **Options.** (a) As proposed; the cell's line becomes a refusal or moves to a cell `fn_expr_untyped_semicolon`. (b) Keep as built; 541 amended to name the exception.
- **Recommendation.** (a).
- **Blocks.** `lambda_last_statement_semicolon` line 5; `docs.md` § Lambdas.

#### 544-a · wasmtime's collector and cycles: what the wasm target is specified against (decision 544; 164 s2)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(a): the codegen breaks its own cycles (a settled task drops its waiters and frame), the gate pins the wasmtime CLI version beside the C API's, and 544's "the host's collector follows cycles" is amended to "the host's collector; a cycle a program builds may live until exit on wasmtime until its collector follows cycles"** — node and the browser collect cycles; wasmtime is the only host that does not yet.
- **Measured.** wasmtime v45 (the machine's CLI, not pinned): the default collector is DRC, which "cannot currently collect cycles; they will leak until the store is dropped". wasmtime v49 (the pinned C API, s1): the default is the copying collector, documented "still under construction and not yet functional". 544 rests s2's "no cycle to detect" on the host following cycles.
- **Options.** (a) As proposed. (b) The codegen detects cycles itself (a cycle collector over GC references — what 544 removed). (c) The wasm target waits for a wasmtime whose collector follows cycles before s2 lands its tasks (P4).
- **Recommendation.** (a).
- **Blocks.** 164 s2's bounded-memory cell (P6); nothing before it.

#### 535-a · A float division by zero on erlang and beam: `crash: badarith` or `panic`? (decisions 535, 527 (3), 492, 444; 144)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(a): float `/` on erlang and beam checked like the integer one, `panic: division by zero: / on f64 at <file>:<l>:<c>`** — one shape for every division by zero; the departure (444: commonJS and wasm answer `Infinity`) is then only in aborting.
- **Measured.** 535 cites `panic: division by zero`; 492 lists "a division by zero" under `panic`; 527 (3) checks only the integer one. `float_nan_infinity_words`'s erlang and beam departures now claim `stderr crash: badarith` — the compiler's answer (an unmarked `badarith`), not one a decision fixes.
- **Options.** (a) As proposed. (b) Keep `crash: badarith` — 527 (3) is integer-only. (c) Literally `panic: division by zero`, a third message shape.
- **Recommendation.** (a).
- **Blocks.** The two departure snapshots stay provisional; a 144 row once answered.

#### 535-b · Where the commonJS abort text lives: the runner's guard or the emitted program (decision 535)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(b): the entry module (the one with `main`, never a library module — a global `process.on` in a library is a side effect) emits the handler; the runner's guard kept for the browser's `.mjs`** — 535 is about what the program writes; one mechanical regeneration of the commonJS codegen snapshots.
- **Measured.** 535 landed on commonJS as a `node --import` guard that `botopink run` and the tests hand to node; the emitted `main.js` is unchanged, and a hand-run `node main.js` prints node's own report. erlang's guard is the runner's too, but an erlang build has no self-contained entry; a commonJS program has one and is run by node outside botopink.
- **Options.** (a) The runner's guard only, as landed. (b) As proposed. (c) Both.
- **Recommendation.** (b).
- **Blocks.** Nothing; the `abort_text_*` cells answer the same.

#### 532-a · The `from <file>:<line>:<col>` record extends 475 (2) (decisions 532, 475)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(a): 475 (2) amended with `from`, the header unchanged** — older cells are unaffected: the record appears only where frames exist.
- **Measured.** 475 (2) lists the `.snap` records exhaustively; 532's build added `from` (after `at` / `label`, innermost first, compared exactly) in the cell format and `conformance/docs.md`. 13 cells carry `from` lines; the header is still `botopink-cell 1`.
- **Options.** (a) As proposed. (b) `botopink-cell 2`. (c) The frames folded into the message.
- **Recommendation.** (a).
- **Blocks.** Nothing landed; 475's text.

#### 533-a · `comptime-badarith` names the whole expression while the caret is at the operator (decisions 533, 472)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(b): the message names the dividing operation's source (`6 / (3 - 3)`, `a / b`), text and caret agreeing; the `from` lines give the `comptime`** — low stakes.
- **Measured.** 472 reads "the operation and place"; after 533 the place is the operator but the backticked text is the `comptime`'s whole expression (`1 + 6 / (3 - 3) * 2`, `ratio(6, 0)`): `comptime_nested_division_by_zero`, `comptime_division_by_zero_in_helper`, `hole_any_call_raises`.
- **Options.** (a) The `comptime`'s text, as landed. (b) As proposed. (c) No backticked text.
- **Recommendation.** (b).
- **Blocks.** Nothing.

## Front 165 — rakun-workspace (the maintainer, 2026-10-14)

#### mono-a · One `rakun` repository: a workspace of 17 plug-and-play packages; erika outside as `query` (decisions 326, 338, 391, 398, 433, 512; front 165)
- **Answered (the maintainer, 2026-10-14; awaiting its number in `decisions-taken.md`):** rakun, erika's consumers, emilia, styled, jhonstart, onze and dbcontext become one repository, `botopink/rakun`, a botopink workspace (512): one directory per package under `modules/`, the package named by its directory, each with its own `botopink.json`, `src/`, tests and `AGENTS.md`, the cells under `conformance/<package>/`, one version and tag, one gate, hook and CI. The packages, by layer (each depending on lower layers only, a cycle refused): `rakun` (core) · `rakun-data` (dbcontext + rakun-data) · `rakun-restclient` (rakun-client) · `rakun-style` (styled) · `rakun-bpp` (jhonstart, -html, -link, -forms, -test, -dom-test) · `rakun-stylesheet` (emilia, jhonstart-emilia) · `rakun-service` (rakun-web, rakun-actuator) · `rakun-scheduling` · `rakun-session` · `rakun-cache` · `rakun-security` · `rakun-websocket` · `rakun-metrics` · `rakun-messaging` · `rakun-mail` · `rakun-app` · `rakun-ssr` (onze and its eight). erika stays a repository of its own, renamed `query` (a pure typed-query DSL; front 145 continues as `query`); `css`, `actions`, `routing`, `validation`, `snap`, `markdown`, `http`, `log`, `json`, `yaml` stay external. The `rakun-starter-*` go; each `*-test` becomes its package's `testing/` module. **Plug-and-play:** adding a package to `botopink.json` is all a program does — a package declares its contribution at its root (`#[rakun.module] pub fn … -> Module`), `rakun.boot()` discovers every module of the program's dependencies through the catalogue, orders them by layer and starts them with their defaults and the program's typed overrides (`#[rakun.config]`); everything resolves at build (a thing contributed twice, a required package absent: build errors naming them), no run-time discovery. Needs 144 B-86: `@TypeInfo.all` reaching a dependency's declarations (its catalogue exported with its analysis, level B storing it). History kept by `git subtree add`; the six repositories archived; the six fronts' open steps refiled under 150 (front 165 s8). Amends 326 (the libraries as repositories), 338, 391, 398 (dbcontext as a repository of its own), 433 (one front per repository: rakun's is 150, with lanes by layer).
- **Context.** Raised by the maintainer, 2026-10-14: seven repositories for one web platform, 40 thin packages and starters to combine them; names (erika, emilia, jhonstart, onze) saying nothing of the role.


#### B-86-a · The lib-agnostic gate's `query`, and the catalogue's reach across packages (144 B-86, front 165 s4)
- **Proposed (opus, 2026-10-14; awaiting the maintainer):** (1) the gate refuses `rakun` in any case anywhere in `compiler-core/src`, and `query` only as a package — the import source `"query"` or the handle `import query`; (2) `jhonstart` leaves the gate's list, as the box says; (3) a dependency's catalogue entry has `module` = `<package>/<module>` (`plugin/root`), and a transitive dependency's declarations are listed too — built so, pinned by `modules/typeinfo_all_dependency_declarations`.
- **Measured.** `grep -riIE 'rakun|query' modules/compiler-core/src` matches about 111 lines: `query` is the catalogue's own word (`Query`, "a template body's query"). `@TypeInfo.all` already listed every module of the build, the dependencies included, and level B's journal already stores `declared` and `meta`: the new cell is green on the parent, on every target, cold and from level B. The reference says "every module of the build", while decision 242 lets a program import only its direct dependencies. Order and collisions follow the existing rule (module path, then declaration order; the key is module and name).
- **Options.** (1)(a) ★ `query` as a package only: `! grep -rIE '"query"|import query\b'`; (b) the word `query` anywhere, the catalogue's vocabulary renamed. (2)(a) ★ `jhonstart` out of the list (the box); (b) kept until 165 s2 renames it. (3)(a) ★ `<package>/<module>`, the transitive dependencies listed; (b) only the direct dependencies listed (242's import rule).
  ```bp
  #[m] pub fn hello() -> string { "plugin" }   // in package plugin, module root
  // the program: @TypeInfo.all(with: m) lists { module: "plugin/root", name: "hello" }
  ```
- **Recommendation.** (a) for each: (1) refuses every package spelling without renaming the language's own word; (2) is the box's text; (3) is what `rakun.boot()` needs — a module contributed by a package two layers down is discovered.
- **Blocks.** Nothing — built as (a); 165 s5 reads (3).


#### 165-a · Where the joined packages' rows of the version set live (decision 113; front 165 s2)
- **Measured.** rakun's `version_set.bp` holds one row per package of the rakun family; its test compares every manifest with the table. After 165 s1 the workspace holds 21 joined packages (erika, emilia, styled, jhonstart, onze and their `*-test` / sub-packages) with no row: a row naming `onze` in rakun's core `src` breaks decision 113's grep (rakun's core names no consumer), so the test reads only the `rakun*` manifests.
- **Options.** (a) ★ None until s2: after the rename every package is `rakun-*`, the rows are written then, and the filter goes. (b) A version set outside the core (a workspace-level file the gate reads), every member a row now.
- **Recommendation.** (a): s2 renames every package to a `rakun-*` name, so the rows need no exception; one version for the workspace (the README) makes the table one row per package at s2.
- **Blocks.** Nothing before s2; s2 writes the rows.


#### 165-b · Three packages outside 165's table: `onze-server`, `jhonstart-dom-test`, `rakun-cli` (front 165 s2)
- **Measured.** 165 s2 folded every package of the table but three. `onze-server` needs `rakun` (erlang-only) while `rakun-ssr` builds for commonJS too (its CLI runs on node): folded, 21 commonJS reds (`rkReqLive` has no External for the node backend) — the language has no per-module target or per-target dependency. `jhonstart-dom-test`'s externals are node-only while `rakun-bpp` builds for erlang. `rakun-cli` is in no row of the table. Built: the three stay packages of their own (`onze-server` depending on `rakun-ssr`, `rakun-app`, `rakun-service`; `jhonstart-dom-test` on `rakun-bpp`).
- **Options.** (a) ★ Three packages named in the table: `rakun-ssr-server` (was `onze-server`), `rakun-bpp-dom-test` (was `jhonstart-dom-test`), `rakun-cli` as it is, each its row with its targets. (b) A language feature first — a module's or a dependency's target set — and the three folded into `rakun-ssr`, `rakun-bpp` (a 144 step).
- **Recommendation.** (a): a package is the unit of a target set today; three named rows keep 165's rule (every package a `rakun-*` name, one row each) without a new language feature.
- **Blocks.** Nothing; the names move in s5's second box or s7.

## Part 1 — What blocks tracks 00–03

### 01-compiler

`00-gate` has no open question: 114's steps wait on no decision.

#### s29-a · How a template annotation receives the annotated declaration, and whether it is also a call-site template (311)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built** — a template function that declares `comptime decl: @Decl` as its second parameter is an annotation only (`#[query "…"]`): called as `query "…"` it is `template-annotation-only`, and a template without that parameter is never an annotation (`template-annotation-without-decl`). The signature says which form a function takes, so no call site meets a handle it cannot have, and 398 already writes the two uses as two functions (`#[query "…"]` in dbcontext, `self.db.query "…"` in erika) — one spelling per thing; (b)'s `?@Decl` and (c)'s `q.decl()` each make one function answer two forms. Viable, built: `member_fn.zig` `isTemplateAnnotation` / `isTemplateAnnotationParams`, `infer.zig` `checkTemplateAnnotations` and the call refusal, cells `template_annotation`, `template_annotation_called`, `template_annotation_without_decl` (comptime on wasm, one answer on the four targets). Changes: 311 (2)'s "one function is both the template and the annotation" is amended to "a template function is one or the other"; under 14s8-a (e) the annotation's `${…}` holes are the template's own grammar, each name spliced into the built member and resolved in the annotated declaration's scope (311), so `template_annotation`'s `q.parts()` read is rewritten by the step that lands 14s8-a (e).
- **Measured.** 311 leaves the `@Decl`'s spelling to `01-checker` step 29 and says "one function is both
  the template and the annotation (`erika "…"` and `#[erika "…"]`)". A template function is called with
  its literal alone (`f "…"`), so a declared `@Decl` parameter has no argument at a call site; 398 has
  since split the two uses into two functions (dbcontext's `#[query "…"]`, erika's
  `self.db.query "…"` template method), so no library writes one function for both. Built: the handle
  is the second parameter, `fn query(comptime q: @Expr<string>, comptime decl: @Decl) -> @Expr<string>`
  (`member_fn.isTemplateAnnotation`); such a function is written only as an annotation — `query "…"`
  is `template-annotation-only` at the call (`reject/template_annotation_called`) — and a template
  without the parameter at `#[f "…"]` is `template-annotation-without-decl`
  (`reject/template_annotation_without_decl`); the value the body returns is not used.
- **Options.** (a) ★ The `@Decl` is a declared second parameter, and a function that declares it is
  annotation-only: `fn query(comptime q: @Expr<string>, comptime decl: @Decl) -> @Expr<string> { … }`
  with `#[query "select …"] fn find(…)`, and `val x = query "select 1";` refused. (b) The same parameter
  as `?@Decl`, `null` at a call site, one function for both:
  `fn erika(comptime q: @Expr<string>, comptime decl: ?@Decl) -> @Expr<Q> { if (decl != null) decl.setMeta(…); return q.build(…); }`.
  (c) No parameter: the handle is a capture method, `q.decl()` answering `?@Decl`.
  (a) example:
  ```bp
  fn query(comptime q: @Expr<string>, comptime decl: @Decl) -> @Expr<string> { … }
  #[query "select * from users where id = ${id}"]
  fn find(id: i32) -> string { … }
  val x = query "select 1";      // template-annotation-only
  ```
  (b) example:
  ```bp
  fn erika(comptime q: @Expr<string>, comptime decl: ?@Decl) -> @Expr<Q> {
      if (decl != null) decl.setMeta(…);
      return q.build(…);
  }
  ```
  (c) example:
  ```bp
  fn erika(comptime q: @Expr<string>) -> @Expr<Q> { val d = q.decl(); … }
  ```
- **Recommendation.** (a): the signature says which form a function takes, a call site never meets a
  handle it cannot have, and 398 already writes the two forms as two functions; (b) if a library must
  serve both forms from one name.
- **Blocks.** Nothing — built as (a) (`01-checker` step 29).

#### s29-b · How an owner's decorator reads a method's typed meta (313)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built, read as 130-s8-a now spells it** — the owner's decorator reads `m.meta(Query)` on a `decl.methods` entry and gets `Query[]` (`[]` when none); `metaAll` goes. The read stands where the owner already walks its methods, typed by the record (298), and 130-s8-a's one read (always a list) replaces the `?T` / `metaAll` pair; (b) is not viable today (`inferTypeinfoRead` answers only `.name` and the string meta, and a method's meta is not published to `TypeInfo` — s23-f (b) first); (c) redoes the template's work in every owner. Viable: `infer.zig` `inferMethodMetaRead` (types `?T` today), `runtime/prelude.zig` `__bp_methodMeta` / `__bp_methodMetaAll`, `builtins.d.bp`'s `Method`, cell `template_annotation`. Changes: the `T[]` read is one 144 step of its own (130-s8-a's, before B-72, whose box already names `T[]`): `inferMethodMetaRead` and `inferTypedMetaRead` answer `T[]`, the two prelude helpers become one, `metaAll`, `typeinfo-meta-several` and `typeinfo-meta-repeated` leave `builtins.d.bp`, `typed_meta.zig`, `expr_param.zig`, `transform.zig` and `typeinfo_all.zig`, decision 418's and 298's texts are amended alike; a defect to file until then: `m.meta(T)` over several added values silently answers the first (`__bp_methodMeta` takes the head) where `@typeInfo(X).meta(T)` refuses.
- **Not viable (fable, 2026-10-12):** (b) — `inferTypeinfoRead` answers only `.name` and the string meta, and a method's meta is not published to `TypeInfo`; it needs s23-f (b)'s methods on `TypeInfo` first.
- **Measured.** 313 has `#[erika "…"]` / `#[query "…"]` and `#[nativeQuery(…)]` record "typed meta of
  the method (298)", and `#[repository]` on the behavior "reads each method's meta"; step 29's cell asks
  for "a method annotation whose meta a type-level decorator reads". Before: typed meta on a method was
  `decorator-meta-on-member`, an owner's decorators ran before its methods', and a `decl.methods` entry
  carried name, parameters, return type and annotations only. Built: a type's or a behavior's methods'
  decorators run before the owner's; a method's `decl.setMeta(v)` / `decl.addMeta(v)` is kept for its
  owner (one value per type and method, `decorator-meta-twice`); the owner's body reads
  `m.meta(Query)` (`?Query`) / `m.metaAll(Query)` (`Query[]`) on a `decl.methods` entry, `Query`
  written by its declared name (`run/template_annotation`). A field's decorator still records no meta;
  string meta (216 (2)) on a method stays refused.
- **Options.** (a) ★ As built: `for (decl.methods) { m -> val q = m.meta(Query); … }` in
  `#[repository]`. (b) The method's meta through the reflection of the owner, at build:
  `@typeInfo(Users).method("find").meta(Query)`, the order of decorators unchanged. (c) No method meta:
  the owner's decorator re-reads the method's annotation literal from `m.annotations[i].args[0]` and
  parses it itself.
  (a) example:
  ```bp
  fn repository(comptime decl: @Decl) {
      for (decl.methods) { m -> val q = m.meta(Query); … }
  }
  ```
  (b) example:
  ```bp
  val q = @typeInfo(Users).method("find").meta(Query);
  ```
  (c) example:
  ```bp
  val sql = m.annotations[0].args[0];   // "\"select …\"" — every owner redoes the template's work
  ```
- **Recommendation.** (a): the read is where the owner's decorator already walks its methods, typed as
  `@typeInfo(X).meta(T)` is, and a member's facts exist before its owner reads them; (c) duplicates the
  template's work in every owner.
- **Blocks.** Nothing — built as (a); `04-rakun/137` and `143`'s `#[repository]` read it.

#### 130-s8-a · One record type both set and added on a declaration; `meta(T)` over added values (298)
- **Answered (the maintainer, 2026-10-12; awaiting its number in `decisions-taken.md`):** **One read, always a list: `meta(T) -> T[]`.** `@typeInfo(X).meta(T)` and a catalogue entry's `d.meta(T)` answer every value of type `T` recorded on the declaration, in recording order — `[]` when none, one element for a type set once (`@typeInfo(Home).meta(Route)` is `[Route("/", "GET")]`), several for a repeated one. `metaAll`, the `?T` answer of `meta` and the read refusals `typeinfo-meta-several` / `typeinfo-meta-repeated` go. The writing side keeps its two verbs: `setMeta(v)` records a type at most once on a declaration (a second `setMeta`, or an `addMeta` beside it, is `decorator-meta-twice` at the annotation that recorded it) and `addMeta(v)` records one that repeats.
- **Measured.** Built: a type is held once (`decl.setMeta(v)`) or repeats (`decl.addMeta(v)`) on a
  declaration, never both — a second `setMeta` of a type, or an `addMeta` beside a `setMeta` of it, is
  `decorator-meta-twice` at the annotation that recorded it (`reject/meta_twice`). `@typeInfo(X).meta(T)`
  answers `null` or the one value, and over several is `typeinfo-meta-several` at the read
  (`reject/meta_several`); `metaAll(T)` answers a set-once value as a one-element array. 298 names
  `setMeta` "one value per type" and `addMeta` "what repeats", not the two together. On a catalogue
  entry `d.meta(T)` answers the first value (the read is run-time code over any entry).
- **Options.** (a) As built: `decl.setMeta(Entity(…)); decl.addMeta(Entity(…));` is `decorator-meta-twice`
  at the second; `meta(Index)` over two `Index` is `typeinfo-meta-several`. (b) A type recorded with
  `addMeta` is read only with `metaAll` — `meta(Index)` refused even over one `Index`
  (`typeinfo-meta-repeated`). (c) The two mix: `setMeta` holds one value among the added ones, and
  `meta(T)` answers the set one.
  (a) example:
  ```bp
  decl.setMeta(Entity(table: "a"));
  decl.addMeta(Entity(table: "b"));            // decorator-meta-twice
  @typeInfo(City).meta(Index)                  // typeinfo-meta-several with two Index
  ```
  (b) example:
  ```bp
  @typeInfo(City).meta(Index)                  // typeinfo-meta-repeated, even with one Index
  ```
  (c) example:
  ```bp
  decl.setMeta(Entity(table: "a")); decl.addMeta(Entity(table: "b"));   // meta(Entity) == "a"
  ```
- **Recommendation.** (a): a key with two meanings at once is refused where it is written; (b) if a
  reader must not depend on how many decorators added a type.
- **Blocks.** Nothing — built as (a).

#### 130-s8-c · A typed meta read of a declaration a `.hooks` reader of this module annotates (298, 372)
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **(b′), provisional until 144 B-55: a step 4 in every module.** A typed meta read `@typeInfo(X).meta(T)` is typed where it stands (`T[]`, 130-s8-a) and answers the whole meta. In another module the import of `X` guarantees it: the resolver finishes `X`'s module, its `.hooks` readers (372) included, before its importer. In `X`'s own module the read is a pending value filled in a step 4, after the module's `.hooks` readers — s23-i's root step, now every module's. Only a read whose value is needed at build before that step (a `comptime`, a same-module decorator's argument, a template expansion) is refused, located, naming the decorator and asking for the read from a module that imports `X`. Replaces `typeinfo-meta-hooks-pending`. If B-55's whole-package analysis is adopted, this becomes its general on-demand rule. **Under B-55-a (e)** (2026-10-12): the step 4 is per block of modules importing each other.
- **Measured.** Built: decision 372 runs a decorator that reads `.hooks` after the module's bodies, and
  answers a string meta read of its declaration in the module afterwards (`answerDeferredMetaReads`). A
  typed read is an expression typed where it stands (its constructors, `@Expr` fields), so it is refused
  in that module before the reader ran: `typeinfo-meta-hooks-pending` at the read; another module reads
  it after the whole module ran.
- **Options.** (a) As built: `@typeInfo(Page).meta(Route)` in `Page`'s module, `#[route]` reading
  `.hooks`, is `typeinfo-meta-hooks-pending`. (b) Deferred like the string read: typed as `?Route` at the
  read, the value written and typed when the reader ran — a type error in an `@Expr` field then located
  in the second phase.
  (a) example:
  ```bp
  // #[route] reads .hooks
  @typeInfo(Page).meta(Route)   // typeinfo-meta-hooks-pending in Page's module
  ```
  (b) example:
  ```bp
  @typeInfo(Page).meta(Route)   // answered after #[route]
  ```
- **Recommendation.** (a).
- **Blocks.** Nothing — built as (a); `05-jhonstart/26`'s `#[page]` reads its meta from the entry point.

#### 130-s8-d · A generic meta record read through a catalogue entry (298)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Already answered: decision 420** ((a), as built). Close by removing the entry; when 130-s8-a's `T[]` lands, 420's `metaAll(Check)` reads `meta(Check)` — the rule (a generic record is read through `@typeInfo(X)`, never through a catalogue entry) does not change.
- **Measured.** Built: `d.metaAll(T)` on a `@TypeInfo.all` entry calls a function of the reading module
  typed for `T` (`declared__metaAll__<T>`, `typed_meta.withMetaHelper`); a generic one cannot be written
  unapplied (`Check` of `Check<T>`), and a generic reader loses `T` on wasm. `d.metaAll(Check)` is
  `typeinfo-meta-type` at the argument (`reject/meta_catalogue_generic`); `@typeInfo(X).metaAll(Check)`
  reads it (`run/meta_expr_field`). The entries of one catalogue may hold `Check<Signup>` and
  `Check<Login>`.
- **Options.** (a) As built. (b) The read writes the arguments, `d.metaAll(Check<Signup>)`, and answers
  the values recorded with exactly those. (c) The read answers `Check<unknown>[]`, its fields typed
  through `unknown`.
  (a) example:
  ```bp
  for (@TypeInfo.all(with: mark)) { d -> d.metaAll(Check) }   // typeinfo-meta-type
  ```
  (b) example:
  ```bp
  d.metaAll(Check<Signup>)
  ```
  (c) example:
  ```bp
  d.metaAll(Check)              // Check<unknown>[]
  ```
- **Recommendation.** (a).
- **Blocks.** Nothing — built as (a).

#### s28-a · An imported source's field default that names a binding of its module (307)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Already answered: decision 421** ((a), as built). Close by removing the entry.
- **Measured.** Built: `Type.omit(Link, .href)` over an imported `Link(…, rel: string = defaultRel())`
  copies the field without its default — the rule `registerExports` applies to an imported function's
  parameter (`infer.isClosedDefault`): a literal, `true` / `false`, `null`, a sign, an array or tuple of
  those travels, anything else does not — so `NoHref(target: null)` is the missing-field refusal at the
  call (copying it made erlc fail: `function defaultRel/0 undefined`). An enum default (`= .Blank`) is not
  closed either.
- **Options.** (a) As built: the default does not travel, the field is supplied at every construction.
  (b) The derivation is refused at the call naming the field (`derived-type-default-not-closed`).
  (c) The default travels, the deriving module calling the source module's function (an implicit import).
  (a) example:
  ```bp
  val NoHref = Type.omit(Link, .href);
  val n = NoHref(target: null);           // error at the call: `rel` is missing
  ```
  (b) example:
  ```bp
  val NoHref = Type.omit(Link, .href);    // derived-type-default-not-closed: `rel`
  ```
- **Recommendation.** (a): no implicit import, no silent value; (b) if a derived type must keep every default.
- **Blocks.** Nothing — built as (a).

#### s28-b · `Type.required` over a field with a `null` default (307)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Already answered: decision 422** ((a), as built). Close by removing the entry.
- **Measured.** Built: `required` takes the `?` off each field and drops a `null` default with it
  (`description: ?string = null` → `description: string`, supplied at every construction); any other
  default stays.
- **Options.** (a) As built. (b) Refused at the call, naming the field. (c) The `null` default stays and
  the field is refused at the constructor when omitted.
  (a) example:
  ```bp
  val Full = Type.required(Recipe);   // description: string, without a default
  ```
- **Recommendation.** (a): "every `?` goes" (types.bp), a `null` cannot type a non-optional field.
- **Blocks.** Nothing — built as (a).

#### s28-c · What a derived type takes besides the fields (307)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Already answered: decision 423** ((a), as built). Close by removing the entry.
- **Measured.** Built: the derived record holds the fields only — the source's methods, `implement`
  clauses and type-level annotations do not come (`Type.pick(Recipe, .title)` has no `Recipe` method);
  the `val`'s own annotations go on the type. Decision 307 names "the source fields' markers" only.
- **Options.** (a) As built: fields and their annotations. (b) The methods whose bodies read only kept
  fields come too. (c) The `implement` clauses come, refused when a member they need is gone.
  (a) example:
  ```bp
  val T = Type.pick(Recipe, .title);   // T(title: string), without Recipe's methods
  ```
- **Recommendation.** (a): a derived type is data; behaviour is written on it.
- **Blocks.** Nothing — built as (a).

#### s28-d · A generic record or an imported alias as the source (307)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Already answered: decision 424** ((a), as built). Close by removing the entry.
- **Measured.** Built: refused at the argument (`derived-type-source-not-record`): a record with type
  parameters (`Type.pick(Box, .item)` — `T` unbound), and an imported type alias (its target is named in
  its own module's scope). A local alias of a record is that record.
- **Options.** (a) As built. (b) A type application as the source, `Type.pick(Box<i32>, .item)`, the
  fields substituted. (c) An imported alias followed through its module.
  (a) example:
  ```bp
  val P = Type.pick(Box, .item);        // Box<T>: refused
  ```
  (b) example:
  ```bp
  val P = Type.pick(Box<i32>, .item);   // P(item: i32)
  ```
- **Recommendation.** (a) until a front needs (b) or (c).
- **Blocks.** Nothing — built as (a).


#### ctr-o · Decision 146 against confirmation `lem-c`
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Confirm `lem-c`, and read 146 with it as one rule** — a host cell with no binding for the target (a free `declare fn` or a type's `declare fn`) may be declared; any bodied function, free or method, whose body reaches it is refused for that target at the call expression inside that body, whether or not anything calls that function. The two texts name one behaviour: 146's "at its declaration, called or not" is the function refused by its own body, `lem-c`'s "where it is called" is where the caret stands; refusing the type's declaration would forbid a type declared once for several targets, and nothing runs silently either way (67). Viable, built: `codegen/hostMethods.zig` `missingAt`, called at the call in `commonJS.zig`, `erlang.zig`, `beam_asm.zig` and `wat.zig`; every bodied function is emitted, so the call fails called or not; cells `bodyless_method_without_binding`, `external_method_erlang_only`, `external_wrapper_keeps_refusal`, `std_asserts_host_cell_on_wasm`; `conformance/docs.md` already states both. Changes: 146's row and `lem-c` restated as the one rule above (no code); two 144 rows to file: on wasm a behavior method with type parameters is emitted only when reached (`wat.zig`), so 146 is not held there; `hostMethods.binds(.wasm)` is hard-coded `false`, so a type method carrying an `@External.Wasm(fn:` / `std:)` cell is refused on wasm against `docs.md`.
- **Rules.** 146: a function whose body reaches a host function with no binding for the target "is refused at its declaration, called or not". `lem-c` (built, to confirm): a host method with no binding "is refused where it is CALLED" — refusing the declaration was the option not taken; 311 keeps the same at the call.
- **Recommendation.** Confirm `lem-c` for a bodyless host declaration (a type declared once still compiles for a target its method lacks); state that 146 governs any bodied function, free or method, reaching one; `docs.md` says both.
- **Blocks.** `lem-c`'s confirmation.

#### s23-j · What 375's mark counts as "cannot follow", and a host `@Component`
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **A component is never asynchronous because of its children.** A component is a function answering its tree (an array of nodes, 388); composing another component — a value received included — only puts its lambda in the tree. 375's `async` mark counts the component's own body only: `await`, `async { }`, an asynchronous hook, a host call answering `@Task` / `@Component` (items 2–5 as built). A marked component answers a Promise of its tree (a state machine on wasm, 140-e (d)); every other answers its tree directly. **The root is always asynchronous:** a `#[page]`'s render (and `renderToString`) walks the tree and awaits only the marked lambdas. The transitive mark (`subtreeAsync`: a component using, directly or not, a marked one; a component received as a value counted from the argument at each use, an unknown value counted asynchronous) is computed at build as an optimisation only, readable by decorators: false, a `#[page]` renders without streaming and a `Suspense` emits its child directly, with no fallback; without it the renderer finds out while descending, with the same answer. Item 1 as built (a call through a function value or a method answering `@Component` marks the node) goes. Amends 504 (140-e): its renderer reads this build-time `subtreeAsync` where it is known, and finds out while descending only for an unknown value.
- **Measured.** Built and landed (`infer.zig` `noteAsyncCall`, `finishHookNode`,
  `markHookAsync`): (1) a call of a function value or a method makes the node asynchronous only when the call's
  type resolves to `@Component<R>` or stays an open type variable — `xs.length()`, a record constructor and a
  method answering `string` do not (s23-d's, answered by 389: "a `@Component` called through a function value or a method");
  (2) a `use` of a host hook and a call of a host function answering `@Component` count as a host answering
  `@Task` (`Component<R> extends Task`) — `run/decl_hooks_direct`'s `Page` (`use session()`, `declare fn
  session() -> @Component<string>`) is `async`; (3) a call of a botopink function answering `@Task` with no
  written `await` does not count (`val t = loadComments();` keeps a Task value); (4) an `await` or `async { … }`
  written inside a lambda in the body counts for the node (the node holds its lambdas, 277); (5) a target with
  no published node (a declaration the session did not publish) is asynchronous.
- **Options.** (a) As built. (b) Any call of a function value or a method makes the node asynchronous, whatever
  it answers:
  ```bp
  fn Card(xs: string[]) -> @Component<Element> { val n = xs.length(); return Element(text: n.toString()); }
  // (a): Card sync, `function Card(map, xs)`; (b): Card async — every component reading a method is async
  ```
  (c) A host answering `@Component` is synchronous (only a host answering `@Task` is named):
  ```bp
  declare fn session() -> @Component<string>;        // #[@External.Node("""Promise.resolve("alice")""")]
  fn Page() -> @Component<Element> { val u = use session(); … }
  // (c): Page sync, `const u = session()` — a Promise where a string is read
  ```
- **Recommendation.** (a): a mark that is never false where commonJS needs an `await`, and true no wider than
  the types say.
- **Blocks.** Nothing — built as (a).

#### s23-c · What a reached declaration's `Declared` holds in a decorator body
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(b), and the meta read typed** — in a decorator body a reached declaration's `value` (`h.hook.value`, `c.callee.value`, `n.function.value`) is refused at the read, located (`decl-hooks-value: a reached function is no value at build`), as a template body's catalogue `value` is (`typeinfo-all-template-value`); its meta is read typed — `h.hook.meta(Route)` → `Route[]` (298, 130-s8-a), answered at build when `Route` is data and refused naming the run-time field otherwise (415 (3), 380) — never the `<decorator>.<key>` string list. Refuse over accept (67): a `null` typed as the function hides that nothing is there, and 364 (3) already says a function has no value at build; strings carrying a decorator's facts are 216 (2)'s legacy, which `builtins.d.bp` itself marks as going. Viable: the template-body refusal in `infer.zig` (guarded by `env.inTemplateFn`) widened to a decorator body, one id in `diagnostics.zig`; `hooks.zig` `declaredTerm` builds the term (it writes `value` as `undefined` and the string `meta`, and writes no `typedMeta` key today, so a direct `typedMeta` read likely fails at run time — a 144 row); the typed read follows `meta_read_at_build`'s rule for data. Changes: `Declared.meta: DeclaredMeta[]` leaves with the string meta; the comment on `Declared` in `builtins.d.bp`; one refusal cell.
- **Measured.** `HookUse.hook`, `HookCall.callee` and `HookNode.function` are `Declared<unknown>`. Built: `value` is
  `null` (no function of the program runs while it compiles, 364 (3)), and `meta` is every entry the declaration's
  decorators set so far, keyed `<decorator>.<key>` (`DeclaredMeta(key: "route.path", value: "/about")`). A template
  body's read of a catalogue entry's `value` is refused (`typeinfo-all-template-value`).
- **Options.** (a) As built: `h.value == null` is `true`; `h.meta` lists `route.path`. (b) `h.value` refused at the read
  in a decorator body, as in a template body (`decl-hooks-value: a reached function is no value at build`); `meta` as
  (a). (c) (b), and `meta` holds only the entries of the decorator reading the list (`path`), as a catalogue entry
  holds `d`'s.
- **Recommendation.** (b): refuse > accept; a `null` that type-checks as the function hides that nothing is there.
- **Blocks.** Nothing — built as (a).

#### s23-f · A type argument's `TypeInfo` in a `HookUse`
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **(b), typed.** A `TypeInfo` carries every field's annotations and the type's methods, as `decl.fields` / `decl.methods` give them (`t.fields[0].annotations` lists `#[validated]`); the build session publishes each module's type declarations, so no empty list means "not carried". A field's, a parameter's and a return's type stops being `typeName: string` / `returnType: string` and is a `TypeInfo<unknown>`, with `kind: TypeKind` (`Record`, `Enum`, `Primitive`, `Array`, `Optional`, `Tuple`, `Fn`, `Task` …) and `args: TypeInfo<unknown>[]` (`Array<string>` → `[string]`, `?i32` → `[i32]`), all declared in std (`builtins.d.bp`, mirrored in `comptime.zig`'s `type_info_src`): `Field(name, type, annotations)`, `Param(name, type)`, `Method(name, params, returnType: ?TypeInfo<unknown>, annotations)`. An annotation's arguments stay read through the typed meta (s29-b).
- **Measured.** Built: `typeArgs` gives the type's name, its declaring module (`""` for a primitive or std's), and a
  record's fields as `Field(name, typeName, annotations: [])` — `params<main.BlogParams(slug: string, id: i32)>`;
  `methods` is `[]` and a field's annotations are not carried (the checker of an importing module holds the type's
  shape, not its declaration). 293 reads the field names and types.
- **Options.** (a) As built. (b) Every field's annotations and the type's methods, as `decl.fields` / `decl.methods`
  give them — `t.fields[0].annotations` lists `#[validated]` — the session publishing each module's type
  declarations.
- **Recommendation.** (b): the record is `TypeInfo`'s, and an empty list that means "not carried" is a lie.
- **Blocks.** Nothing for 293.

#### s23-i · A catalogue of a `.hooks` reader read in the reader's own module (372)
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **(d), a fourth option: the catalogue is read only in the package's root.** (1) `@TypeInfo.all` is read only in the package's root (`main.bp` for a binary, `root.bp` for a library); in any other module it is refused, located, naming the root (``@TypeInfo.all` is read only in the package's root (src/main.bp) — move it there`). (2) No module of the package imports from its root — refused, located (`src/pages/home.bp imports from the package's root (src/main.bp) — the root imports the package, never the reverse`) — so the resolver analyses the root after every module its `mod` tree declares. (3) In the root, catalogues are answered after its own `.hooks` readers ran (a step 4 after 372's three), so a declaration decorated in the root itself carries its meta too. No catalogue is answered before what it lists: every entry carries its whole meta. Replaces `typeinfo-all-hooks-reader`. A framework receives the catalogue from the application's root as an argument (`jhonstart.serve(@TypeInfo.all(with: page))`), never reads it itself. **Every package with sources has a root** (the maintainer, 2026-10-12): a package whose `botopink.json` has sources declares `src/root.bp` (a library) or `src/main.bp` (a binary), and the resolver follows the `mod` tree from it; the deprecated blind scan goes — a package with sources and no root is refused, located, naming the missing file. A manifest with no sources (a workspace's `"workspaces"`, a fixture's dependency manifest) needs no root. `onze/examples/scaffold` moves its `root.bp` to `src/root.bp` or its manifest names where its root is — front 150's choice (the onze section, 150 s59 … s71); `json`, `yaml` and `dbcontext` are born with `src/root.bp`. Measured on every library's `feat`: every other package with sources already has one. **`root.bp` declares the tree, `main.bp` is the entry** (the maintainer, 2026-10-12; amends this answer's root rule): `mod` / `pub mod` are declared only in `src/root.bp` and in a folder's `mod.bp` — never in `src/main.bp` nor in any other module (refused, located: `declare the module tree in src/root.bp`). `src/root.bp` is not mandatory: a package with no module but its entry (a one-file program) has only `src/main.bp`; a package with modules has `src/root.bp`; a library has `src/root.bp` and no `main.bp`. `src/main.bp` holds `pub fn main()`, is declared by no `mod`, imports the package as a consumer, is imported by no module, and is analysed after the whole tree and `root.bp`. No module of the tree imports `root.bp`. `@TypeInfo.all` is read in `root.bp` or `main.bp` and refused, located, in any other module. The prelude (116-a) is reached from `root.bp`. **`src/lib.bp`, as Rust's `lib.rs`** (the maintainer, 2026-10-12; amends the two rules above): the package's root is named `src/lib.bp` — `root.bp` is renamed everywhere (std's, every library's, the resolver's, the docs' — by the step that lands it, by hand or a one-off script); `botopink migrate` is removed (its command, `cli/migrate.zig`, its tests and docs; 144 B-56) — and `src/main.bp` may declare `mod` / `pub mod` when the package has no `lib.bp`, as Rust's `main.rs`: a package with only `main.bp` has its tree there; with `lib.bp`, `lib.bp` holds the tree and `main.bp` declares no `mod` (refused, located: `declare the module tree in src/lib.bp`) and uses the package as a consumer. Every rule above that names the root reads `lib.bp`, or `main.bp` when there is no `lib.bp` (the catalogue, 116-a's prelude, no module of the tree importing it). Whole-package analysis allowing two modules to import each other is front 144 B-55's study; until it lands, no import cycle between modules. **Superseded by B-55-a (e)** (the maintainer, 2026-10-12): a file is a module, with no `lib.bp` and no `mod`; the catalogue is read in any module; what stands here is the mandatory entry `src/main.bp` for an executable.
- **Measured.** 372 runs a `.hooks` reader after the module's bodies. `@TypeInfo.all(with: graph)` written in the
  module of `#[graph] pub fn Page` is answered when the module is re-analysed, from the meta set so far: the parent
  binary printed `Page 1` (`d.meta.length`), and with the readers moved after the bodies the answer would print
  `Page 0` — the meta silently missing. Built: refused, `typeinfo-all-hooks-reader` at `graph` in `with:`
  (`reject/typeinfo_all_hooks_reader`). A catalogue in another module (an entry point — `@TypeInfo.all` readers are
  analysed after every other module) carries the reader's meta; `@typeInfo(Page).meta.graph.count` in the same module
  is answered after the reader ran.
- **Options.** (a) As built: the same-module query refused at the decorator's name. (b) The answer's meta of a
  same-module reader filled after the reader ran, as a `@typeInfo(X).meta` read is — `@TypeInfo.all(with: graph)`
  prints `Page 1` in `Page`'s module. (c) A `.hooks` reader's meta never appears in a catalogue entry (`meta: []`
  everywhere), read only through `@typeInfo(X).meta`.
- **Recommendation.** (a) until a front needs the same-module catalogue; (b) is the complete answer.
- **Blocks.** Nothing — built as (a).

#### 14s8-a · How a template reads a hole's build value (355; `01-compiler/14` step 8 box 1)
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **(e), a fifth option: the hole is the sub-language's, not the language's.** A template receives its literal's raw text (`@Expr<string>`, `q.text()`) — written `css "…"` or `css """…"""`, both alike, neither interpolated by the language inside a template call — parses it with its own grammar, its holes' syntax included (`{expr}`, as jhonstart's `html` does), and answers botopink code through `q.build(code)` / `q.custom(tree, code)`. A template never reads a hole's value: the hole's expression is spliced into the generated code (`css "padding: {gap};"` → `"padding: " + cssValue(gap) + ";"`), and the checker types it in the caller's scope, refusing at the user's hole through the `CustomNode` span (`cssValue(true)`: `expected Length | string, got bool` at `{true}`). Computing at build is the compiler's, by 355 / 376: a call of an `Any` function with known arguments is folded at build (`card` becomes `"padding: 8px; margin: 1.5rem;"`), else it runs at render (`badge(size)`). `Part.Interp`, `known` and `hole.value` leave the template API; the templates reading `q.parts()` today (styled, emilia …) parse their text instead. `"${x}"` in an ordinary string keeps interpolating.
- **Measured.** Box 1 was written as `e.lookup(name)` answering a `val`'s build value. A `${…}` hole adds no word to the capture (237), so `lookup` cannot reach `tab4` in `styled "${tab4} color: red;"`, and 355's holes known at build include a literal and a `comptime`, which have no name. Built and landed: each `Interp` part of `q.parts()` carries `known` (bool) and `value` (the build value as data, a record its fields; `null` when computed at render). `builtins.d.bp` still declares `Part.Interp(hole: Expr<string>, span)`; the part a body reads carries `code`, `known`, `value` (field reads on `Part` are not checked today), so a value of the wrong shape fails the template at run time: `styled "${whole} margin: 0;"` with `whole = styled "color: red;"` (a `Styled` where a declaration stands) is `{error,{badkey,declarations}}` at the literal, where the computed call refused it as `type mismatch: expected StyledProperty, got Styled`.
- **Options.** (a) As built: `for (q.parts()) { p -> if (p.kind == "Interp" && p.known) built = built + p.value; }`; `p.value` is `null` for a hole computed at render. (b) `q.lookup(p.code)` answers `Binding(name, kind, value)` for a hole that names a `val`: `val b = q.lookup(p.code); if (b?.value != null) …` — a literal or a `comptime` hole is never known. (c) 364's `@Expr<T>.value` on each hole: `if (p.known) built = built + p.hole.value;`, `.value` of a hole not known at build an error at the read, located — one spelling with every other `comptime` parameter, the hole typed `@Expr<T>`.
- **Recommendation.** (c) — one spelling, typed, a read of an unknown value refused (decision 67); (a) stands until `01-checker` s24 builds `@Expr.value`, and either way `Part` in `builtins.d.bp` (02's) declares what the part carries.
- **Blocks.** Nothing — built as (a).

#### 14s8-c · A hole known at build whose value raises there
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **(a), by 14s8-a (e).** A hole's expression is spliced into the generated code; when the compiler folds it at build (355 / 376) and it raises, the build is refused at the user's hole, located — never deferred to render.
- **Measured.** A hole known at build is evaluated on the comptime runtime as a `comptime` is (331). Built: a raise is refused at the hole — `pub val boom = raising "x"; pub val read = quote "${boom}";` (`raising` building `crash("x")`, which `@panic`s) is ``this hole is known at build (decision 355) and its value raised there: the comptime block raised: {error,{panic,<<"crash: x">>}}`` at `${boom}` (`reject/hole_known_at_build_raises`).
- **Options.** (a) Refused at the hole (as built). (b) The hole is computed at render (`known` false): `read` builds, and the program raises when it reads `boom`.
- **Recommendation.** (a) — fail > warn, at build rather than at run time.
- **Blocks.** Nothing — built as (a).

#### 14s8-d · A `comptime` reaching a function declared after it that holds a template call
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a) until 144 B-72, then obsolete by B-55-a (e)** — the refusal stands as built; B-55-a (e) (5) analyses every body of a block before its decorators and its `comptime` values, so a function declared after the `comptime` is already expanded when the `comptime` runs, and the refusal goes with 419's (B-72's box). (b)'s "infer the reached bodies first" is what the block model gives in general; a one-module version (`sameLoweredFn`'s precedent in `infer.zig`) would be the same step done twice. Viable: `block_eval.zig` `expandedFn` / `unexpandedTemplateCall`, cell `comptime_template_call_declared_after`; B-72 removes them. Changes: none now; `cep-a` (the section-path twin, `comptime_section_path_declared_after`) goes in the same B-72 box, which names 14s8-d only and should name both.
- **Measured.** A function's template calls are expanded when its body is inferred; a `comptime` carries the expansions (`block_eval.zig` `expandedFn`). A function declared after the `comptime` has none yet. Built: refused at the `comptime` — `pub val early = comptime late();` above `fn late() -> string { return tag "b"; }` is ``the comptime reaches the template call `tag` at 14:12 in `late`, which is not expanded where the comptime runs — declare `late` before the `comptime` in this module`` (`reject/comptime_template_call_declared_after`).
- **Options.** (a) Refused, naming the call and the remedy (as built). (b) The checker infers the body of every function a `comptime` reaches before the `comptime` is evaluated, so the order of declarations does not matter.
- **Recommendation.** (a) until (b) is built by `01-checker`; (b) refuses nothing a program needs.
- **Blocks.** Nothing — built as (a).

#### 14s8-e · A `comptime` reaching a component that reads a context (`comptime padAll(2)`)
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **`use` exists only in a `@Component` body, and a hook is a `@Component<R>` — so a `comptime` or a hole never reaches one.** (1) A hook is a component answering a value: `pub fn usePad(n: i32) -> @Component<StyledProperty> { val cfg = use context(StyleConfig); return padAll(n, cfg); }`, read in a component with `val p = use usePad(2);` (`use` runs it with the body's scope and answers `R`). (2) `use` written in a function that does not answer `@Component<R>` is refused at the `use`, located (`use` is allowed only in a component's body — `padAll` answers `StyledProperty`). (3) Calling a component or a hook without `use` only makes its lambda (504), so a loose expression never runs a `use`; only the renderer runs one — at build too, with `RenderScope.root()`, where `use context` reads the declared default (388 (4)). (4) A context is declared and read as 354 (2) spells it — `pub val styleContext = comptime createContext(StyleConfig(unit: 4));`, read by its value's type `use context(StyleConfig)`, provided by `use provide(createContext(StyleConfig(unit: 5)))` — and its value is immutable (no `var` field; one that has is refused, located), so reading its default at build is safe. (5) styled keeps its functions pure, the config a parameter (`padAll(n, cfg: StyleConfig = StyleConfig(unit: 4))`), computed at build in a hole or a `comptime`; a component reads `StyleConfig` with `use context(StyleConfig)` or uses the hook `use usePad(2)`. Today's `use context(StyleConfig); sheet.add(…)` goes: rules travel as data (`StyledProperty(className, rule)`), collected where they are used (355 / 377).
- **Measured.** Step 8's box read `comptime padAll(2).rules` as refused at `.contentHash(…)`; with
  `contentHash` carried (step 6, 341) the run now reaches styled's `styledPropertyComputed`, whose body
  is `val sheet = use context(StyledContext); … sheet.add(sheet.layer, …)` — a `comptime` has no render
  tree (354 (3)), so nothing provides `StyledContext`, and the run stopped at ``the comptime block calls
  `.add(…)` with 2 argument(s) at 144:11, which no primitive type … provides`` (botopink-lang, styled `feat`). 376 (3) makes `context` `Any`, and 355 / 376 (5) compute
  `styled "${padAll(2)}"` at build — yet at build there is no provider to read.
- **Options.** (a) ★ A `comptime` (or a hole computed at build) that reaches a `use` in a function it
  carries is refused at the `comptime`, naming the `use` and its function: ``the comptime reaches `use
  context.context(…)` at 139:17 in `__bp_tpl_styled_styled__propertyComputed`, and a `comptime` runs with
  no render tree: nothing provides what the `use` reads (decision 354 (3))`` (`reject/comptime_reaches_use`); `padAll(2)` stays at render until styled reads no
  context on that path. (b) The build provides each context's declared default (`StyledContext`'s), so
  `comptime padAll(2)` computes with the default sheet and its registration is dropped:
  `val p = comptime padAll(2);` answers `StyledProperty(className: "s_…", …)` and no sheet holds the
  rule. (c) A hole naming a call that reaches a `use` is never known at build (376's `Any` excludes a
  function reaching a `use context`): `styled "${padAll(2)}"` is computed at render, as today.
- **Recommendation.** (a) — refuse rather than answer with a provider nobody wrote (67); (c) is what
  01-checker step 36's stage gives once it lands, and agrees with (a).
- **Blocks.** Nothing — built as (a) (`block_eval.useReached`); step 8's `Any`-call box reads it.

#### 414-a · A component call in a body: rendered (128) or the lambda (414's example)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Answered by 504 and by s23-j's answer: a call in a body makes the lambda** — `val inner = notFoundLevel(chain, i, route, page);` in a component body is the unrun `@Component<Element>`, placed in the tree (`ErrorBoundaryNode(child: inner)`) and run by the renderer with the scope its parent answered; only a written `await c` runs `c` in the body (388 (4)); a field read on an unawaited value stays the checker's refusal. 504: "calling a component only makes its lambda, only the renderer runs it", "`<main>{view()}</main>` stores `view()`'s lambda"; s23-j: "composing another component only puts its lambda in the tree"; (b)'s "renders where read as `R`" is weaker and infers intent from the use. Viable: `infer.zig` `inferComponentCall` (the `await` splice through `env.indexRewrites`) and its call site go, `noteAsyncCall` and `context_lower.zig` follow; jhonstart's renderer on feat already writes every run as `await` and holds its children as thunks (`ErrorBoundaryNode.child: fn() -> @Component<Element>`, which becomes `child: @Component<Element>` under 504 and lg2-n); commonJS, erlang and beam today, wasm with 144 B-25 step 4 (whose box still reads the pre-504 recommendation). Changes: 144 B-17's hooks box takes the splice removal and rewrites the two cells that encode 128's render-on-call (`component_call_renders`, `component_call_awaited`; `component_is_lambda` stands); the entry closes as (b) in 504's wording.
- **Measured.** 128's chain, kept by 388 (4) ("inside a component body `await c` runs `c` with the body's
  children scope"), renders a component call written in a component body: the checker splices `await` around
  it (`inferComponentCall`), so `val inner = notFoundLevel(chain, i, route, page);` RUNS `notFoundLevel` with
  the children's scope and `inner` is its `Element`. 414's example writes the same line with the comment "the
  lambda, not run". Built and landed: the splice stands; a body gets an unrun component value
  by naming the function (`itens.map(Card)`) or through a lambda — jhonstart's `ErrorBoundaryNode` /
  `NotFoundBoundaryNode` hold `child: fn() -> @Component<Element>` (`{ -> notFoundLevel(…) }`), as
  `suspense.Boundary` already did.
- **Options.** (a) As built: a call in a body renders; a value is a name or a lambda:
  ```bp
  fn caughtBelow(…) -> @Component<Element> {
      return nodePlaceholder(TreeNode.Errors(ErrorBoundaryNode(id: …, child: { -> notFoundLevel(chain, i, route, page) }, …)));
  }
  ```
  (b) A call in a body makes the lambda wherever its value is not read as `R`, and renders only where the
  checker reads it as `R` (a field read, an argument typed `R`) — `val inner = notFoundLevel(…);` a lambda,
  `inner.tag` refused without `await`:
  ```bp
  val inner = notFoundLevel(chain, i, route, page);          // @Component<Element>, not run
  return ErrorBoundaryNode(id: …, child: inner, …);
  ```
- **Recommendation.** (a): one rule for a call in a body (128, unchanged by 388), no inference of intent from
  the use; (b) changes what every body's `val x = Card(…)` means.
### 02-std-and-packaging

#### 97-s16-a · Where `unicode`'s generated tables live
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a) now; under B-55-a (e) the file is `libs/std/src/internal/unicode_tables.bp`** — until 144 B-75 the flat private sibling stands as landed; when the module model lands (B-69: a file is a module named by its path, `mod` goes, `src/internal/` is private to its package) the generated tables move to `src/internal/`, `unicode.bp` writes `import {internal.unicode_tables as tables};`, and residual 11 closes structurally — an import of std's `internal/` from another package is refused, located. (b) is obsolete under (e) (no `mod`, no folder children to declare); the privacy a `mod` could not give the folder gives (67: structural, no list). Viable: `resolver.zig`'s `mod` resolution and `build.zig` `collectStdModules` today; B-69's `internal/` box and B-75's std move (`collectStdModules` walks the tree instead of reading `mod` lines; the generator `libs/std/tools/unicode-gen` writes the new path). Changes: none now; a defect to file until B-69: `import {unicode_tables} from "std"` compiles (`resolver.zig` checks visibility only inside the importing package).
- **Not viable (fable, 2026-10-12):** (b) — obsolete under B-55-a (e): there is no `mod` and no folder child to declare once a file is a module named by its path.
- **Measured.** `02/97` step 16 names `libs/std/src/unicode/tables.bp`. The module tree resolves a `mod Name;` only to `Name.bp` or `Name/mod.bp` in the declaring file's directory (`compiler-cli/src/cli/resolver.zig`, `build.zig` `collectStdModules`), so a file module `unicode.bp` has no children: `unicode/tables.bp` is unreachable unless `unicode` becomes a folder, and a folder index holds `mod` lines only and makes `unicode` a namespace (`unicode.normalize` would become `unicode.<sub>.normalize`, decision 110). Landed: a flat sibling `libs/std/src/unicode_tables.bp`, `mod unicode_tables;` (private) in `root.bp`, `import {unicode_tables as tables};` in `unicode.bp`. The registry does not honour the `mod`'s privacy: a consumer's `import {unicode_tables} from "std"` resolves (97's compiler residual 11).
- **Options.** (a) ★ As landed — a flat private sibling:
  ```bp
  // root.bp
  pub mod unicode;
  mod unicode_tables;
  // unicode.bp
  import {unicode_tables as tables};
  ```
  (b) A file module may declare children in the folder of its own name (Rust 2018's `unicode.rs` + `unicode/tables.rs`) — a resolver and `build.zig` change, `01-compiler/26`:
  ```bp
  // unicode.bp
  mod tables;            // → libs/std/src/unicode/tables.bp
  import {unicode.tables};
  ```
  (b) in the `unicode/mod.bp` form:
  ```bp
  // libs/std/src/unicode/mod.bp
  mod tables;
  pub fn normalize(s: string, form: Form) -> string { … tables.ccc(cp) … }
  ```
- **Recommendation.** (a): no compiler change, one module more in the registry; residual 11 makes the privacy real whichever is chosen.
- **Blocks.** Nothing (a move of one generated file and the generator's output path under (b)).

#### nat-f3 · `files` and `workspaces` in `botopink.json` (98)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **`files` goes with B-69 / B-75; `workspaces` stays (512)** — what a consumer may import is derived from the tree: every module under `src/` outside `src/internal/` (B-55-a (e) (8)); a manifest that writes `files` is refused, located, naming `src/internal/` as the one way to keep a module private; `workspaces` keeps listing a workspace's members (512 (1)–(5): shared dependencies and targets, a cell workspace per `conformance/modules/`). Two spellings of what ships (a list and the tree) would be two ways to say one thing, and a list that forgets a module ships a silently incomplete library (67); 270's reliance on `files` is already gone with 116-a (f) and (e) (9) (the prelude is any marked `pub` item outside `internal/`); (b)'s `#![internal]` has no spelling (315) — the folder is its spelling. Viable after B-69: `compiler-cli/src/cli/libs.zig` loads a dependency from `manifest.files` today and `manifest/src/root.zig` `shipsNothing` refuses a library without it, so both read the tree instead; `code_cache.zig` keys the closure by the tree's files already (509 (3)); std's three ambient files (`primitives.bp`, `builtins.d.bp`, `builtins_fns.d.bp`), listed in std's `files` today, are the compiler's own and keep a fixed place in `libs/std`, not a manifest key. Changes: until B-69 (a) stands as built; the entry's `docs/botopink-json.md` citations are stale (the manifest is documented in `modules/manifest/AGENTS.md`), and "a workspace refuses `dependencies`" is reversed by 512 (2).
- **Not viable (fable, 2026-10-12):** (c) — `workspaces` is a member list (`modules/*`, `examples/*`, `*`) that no code can derive.
- **Measured.** `files` lists, relative to `src`, the modules a consumer may import; a library without it ships nothing (`docs/botopink-json.md:52`). `workspaces` lists members; a manifest with it is a workspace and refuses `src`, `files`, `entry`, `dependencies` (`:159-170`) — the two never share a file (`98-packaging-tail/README.md:27`). 270 relies on `files` (the prelude `src/prelude.bp` is listed there).
- **Options.** (a) Both kept — packaging, not code. (b) `files` derived from `pub` modules (an internal module marked in code — `#![internal]` has no spelling since 315), 270 reworded; `workspaces` kept. (c) Both derived.
- **Recommendation.** (a): what ships is a packaging fact, and 270 already relies on it.
- **Blocks.** 98.

#### nat-d9 · LINQ's names in erika beside std's (98)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), read with 312: the grammar is erika's one public spelling over an array, std's methods the other; the LINQ-named fluent `Query<T>` becomes erika's private lowering target** — `erika "select name from xs where active order by name"` (312: one grammar, two targets) and std's `xs.filter(…)`, `map`, `flatMap`, `unique` are the two ways to compute over an array; the 35 public methods of `Query<T>` (`where`, `select`, `selectMany`, `orderByDescending`, `toList`, …) leave the public API, kept private as what the template builds into; erika adds no fluent operator beside std's (137's context already says so). One way to write each thing: today `xs.filter(p)`, `erika.of(xs).where(p)` and `erika "select * from xs where …"` are three spellings of one read, two of them LINQ's names for std's methods (170: std takes the natural name, a library's copy goes). Viable today, erika only: `erika/modules/erika/src/erika.bp` (the `Query<T>` methods become private `fn`s, the template's pipeline lowering keeps calling them), `erika-test` and `examples/erika-linq` rewritten to the grammar. Changes: a 145 step (a rename and a visibility pass, no compiler change); (b) and (c) keep two public models of one thing against 283's case-by-case reading.
- **Measured.** `98-packaging-tail/README.md:47-51`; `erika.bp`: `where`, `select`, `selectMany`, `orderByDescending`, `toList`; erika is eager — every operator materializes a new array (`erika.bp:5`); std has `filter`, `map`, `flatMap`, `unique` (217).
- **Options.** (a) std's names (`filter`, `map`), erika adding only what std lacks (`groupBy`, the aggregates). (b) LINQ's names — erika's identity is LINQ. (c) As is.
- **Recommendation.** none from this review: erika's purpose decides (b) is a fair reading.
- **Blocks.** 98 (erika).

### 03-bundled-libs

#### ctr-p · Confirmation `std-a` against confirmation `03r-e`
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Confirm `std-a`; `03r-e` lapses, and rakun's own readers go with it** — a query component or a cookie chunk whose escape is malformed or decodes to a control character is refused: `querystring.parse` / `parseForm` answer `Error` (std, already so), `http.cookie.parse` / `get` answer the chunk as absent while the refused chunk still claims its name (196, 181); nothing is kept "as written". Refuse over accept (67), one reader per header (196): rakun-app's `queryDict` already reads queries through `querystring.parse` with `try`, so the query half of `03r-e` is dead; its cookie half lives only in rakun's five readers (`request_context.bp` `decodeComponent`, `csrf.bp` `cookieValue`, `session_cookie.bp` `cookieFromHeader`, `i18n.bp` `cookieFrom`, `exchanges.bp` `sessionIdOf`), which 196 deletes. Viable: `libs/std/src/querystring.bp` and `repository/http/src/cookie.bp` exist and refuse as said; rakun declares no dependency on `http` yet — the adoption is 150's "consume http" step (rakun 04 step 5). Changes: Part 3's `03r-e` row is reversed by this confirmation; two 150 rows to file: `cookieFromHeader` takes the last duplicate against 181 / 348 (first wins), and the five readers disagree on one header.
- **Rules.** `std-a`: `querystring.parse` / `parseForm` "refuse … an escape that decodes to a control character", and rakun's `splitQuery` moves onto them. `03r-e`: a cookie or query component that would decode to a control character "stays exactly as written". 196 moves rakun's cookie readers into `http`.
- **Recommendation.** Confirm `std-a`; `03r-e` lapses when rakun reads queries via `querystring` and cookies via `http`.
- **Blocks.** rakun 04's readers; 104's consumer sweep.

#### 396-a · onze-content: "a node rendered by a component of the page's own where the page asks"
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), in onze-content, typed by 504's tree** — `toElementWith(doc: MdDoc, render: fn(node: MdNode, kids: Node) -> ?Node) -> Element` beside `toElement`: the page's function sees each node with its already-rendered children and answers the node to place — a tag, a component value (`<MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo>` is the unrun lambda the renderer runs, 504) or `null` for the default element; `Item`, `Row` and `Cell` are nodes too, offered by their parents, and a tight list's paragraphs keep their `tight` rendering when the hook answers `null`. One function, one typed `case` over `MdNode`'s kinds (281: the kind is the variant, never a string), nothing per kind to keep in step with the tree ((b)'s 21-field record); (c) stays available but reproduces the default mapping's bookkeeping in every page. Viable today: `onze/modules/onze-content/src/element.bp` (`toElement`, `blockElement`, `inlineElement`, `itemElement`, `tableElement`, `rowElement` thread the hook; `markdown/src/markdown.bp`'s `MdNode` is public); jhonstart's `Node` is the union a hole accepts (223, 191) and a component value in it is 504's. Changes: 142 step 3's second box; the entry's "markdown's `toElement`" is onze-content's (396 (3): markdown names no framework).
- **Measured.** 142 step 3 built `element.toElement(doc: MdDoc) -> Element` (every `MdNode` to one fixed element, as the old `toElement`); 396 (3) and the step's box say a page may render a node with a component of its own, and fix no form. Components are functions of a props record (192/193), `Element`s are values.
- **Options.** (a) `toElementWith(doc, render: fn(node: MdNode, kids: Array<Element>) -> ?Element)` — one function, `null` keeps the default element, the page matches the node kinds it wants (`Heading`, `Link`, `CodeBlock`, …). (b) A record of optional per-kind functions, `Components(heading: ?fn(depth, id, kids) -> Element, link: ?fn(href, title, kids) -> Element, …)`, one field per node kind. (c) Walk `MdDoc` in the page and call `toElement` for the nodes it does not render (no hook; the tree is public).
  (a) example:
  ```bp
  val page = toElementWith(doc, { node, kids -> case node { Heading(depth, id, _) -> <MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo>, _ -> null } });
  ```
  (b) example:
  ```bp
  val page = toElementWith(doc, Components(heading: { depth, id, kids -> <MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo> }));
  ```
- **Recommendation.** (a): one reading, no field per kind to keep in step with the tree; (c) needs no code and is available today.
- **Blocks.** `142` step 3's second box (only the hook; the default mapping is built).

#### 07-g · OTP release rendering
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as a repository `botopink/release`** — one library of pure renderers (`.rel`, `vm.args`, `sys.config`, the boot script, the Dockerfile and the systemd unit) written in botopink for every target, imported by `rakun-cli` and `onze-release` (242); each keeps only what is its own (rakun's actuator paths and cookie env, onze's `assembleRelease` process run). Two consumers meet 115's test, and 326 makes a new shared package a repository, never a compiler-bundled one; (b) cannot serve onze-release (no erlang target); (c) keeps two renderers whose bytes already differ (`.rel`'s `kernel` / `stdlib` versions, `vm.args`' flags), two answers for one release. Viable: `rakun/modules/rakun-cli/src/release/release.bp` (`renderRel`, `renderVmArgs`, `bootScript`, `renderDockerfile`, `renderSystemdUnit` are pure text; `renderSysConfig` calls the Erlang host `rkRelTerm` and needs the `.bp` term writer 107 s1's first box asks for) and `onze/modules/onze-release/src/otp.bp`; the meta `.gitmodules`, § Layout and CI check 4 carry the repository as they carry `json` / `yaml`. Changes: 107 opens as written (its s1 reproduces both rows byte for byte from one renderer); the entry's `rakun-release` is `rakun-cli` since 187.
- **Not viable (fable, 2026-10-12):** (b) — a CLI feature cannot serve onze-release, which has no erlang target.
- **Measured.** `rakun-release/release.bp` (into `rakun-cli` under 187) and `onze-release/otp.bp` render the same `.rel` / `vm.args` / `sys.config` / boot script / Dockerfile; onze cannot reuse rakun's (rakun erlang-only, onze-release also commonJS).
- **Options.** (a) A bundled `release` of pure renderers. (b) A `botopink` CLI feature (02). (c) Leave both.
- **Recommendation.** (a); the CLI may adopt the package later.
- **Blocks.** `107-release` (a conditional front: answer it or defer 107).

### Implementation choices of tracks 00–03

Each implemented with its recommended option; the maintainer confirms or reverses (a reversal is a
local change in the named place). Full 1.0.10 text under the same id in
[`../1.0.10-beta/decisions-pending.md`](../1.0.10-beta/decisions-pending.md).

#### 01-compiler (28)

| Id | Choice implemented | Where |
|---|---|---|
| 01c-a | A comptime module's atom is `bp@comptime@<owner path>__tpl__<decl>__<hash>` | comptime |
| 01c-b | A section leaf takes the leading-dot shorthand where the position's type is that section; with no expectation refused naming its section | checker |
| ck2-a | `@module()` refused at the call (`builtin-not-lowered`) until a rule says what a module value is | `builtins.d.bp` · `reject/builtin_module_not_lowered` |
| ck2-b | A section member may share a name with a top-level variant of the same enum (path and position type tell them apart); a variant declared twice at one level is `enum-variant-duplicate` | `modules/enum_section_leaf_beside_variant` |
| ck2-d | A label in a call of a function value is `label-on-function-value` | `reject/label_on_function_value` |
| ck2-e | A std decorator is reached via its module handle (`#[<handle>.<fn>]`); a leaf import of one is `std-decorator-leaf-import`; `#[<handle>.<not a decorator>]` is `unknown-annotation`; the handle is still needed after 216 (`mocks.mock`'s `addType` / `addMember` text names `mocks.invoke`, `testing/mocks.bp:212-220`), while 282/289 already leaf-import other libraries' decorators | checker |
| rc3-b | `unknown` is the host vocabulary's spelling where `any` was (tested with `is` before use) | `run/host_unknown_parameter` |
| rc3-c | Assigning a narrowed `var` checks against its declared type and ends the narrowing | `reject/narrow_ends_at_assignment` |
| 0405-b | commonJS's `__bp_show` prints `undefined` as `null` | commonJS prelude |
| onze F7 | Integer `/` integer truncates toward zero and is an integer on every target (`7.0 / 2.0` stays `3.5`); `docs.md:961-963` already states it | `run/integer_division_truncates` |
| lem-a | A host method is a real method of its type whose body is the binding, never inlined at the call site | `codegen/hostMethods.zig` |
| lem-b | `inline: true` (305's spelling; code still writes `inline = true` until 01-checker step 27) on a type method's `External.Erlang` / `Beam` accepted, changes nothing (refusing it is 01-checker's to add; recommended: refuse) | `run/external_method_local` |
| lem-c | A host method with no binding for the target refused where called (`MissingExternal` naming `Type.method`); wasm refuses every host method; an untyped receiver fails at run time (`ctr-o`) | `hostMethods.missingAt` |
| lem-d | One name per operation on every type (`Listener.port/accept/close`, `Socket.recv/send/close/peer`, `TlsListener.port/accept`, `TlsSocket.recv/send/close`, `Regex.matches`); constructors stay module functions | `io.net` · `regex` |
| lem-e | Private helpers taking a type stay free (`tlsEchoOnce`, `rkvPush`, `putMessageSource`, `messageSourceOr`) | std · `validation` |
| lem-f | commonJS adopts a host-built record into its class (`__bp_adopt`) directly and through `?T`, arrays and a `@Result`'s ok side, not through `@Task` | `run/external_method_on_host_record` |
| cep-a | A section path (`.Pad.All.8`) in a function of this module declared after the `comptime` that reaches it has no rewrite yet (the body is inferred later), so (a) the `comptime` is refused naming the path, its `line:col` and the function — "declare `later` before the `comptime` in this module" — as 14 step 8 refuses a template call there; (b) would infer such a function ahead of the `comptime`, inside the body being inferred. Recommended: (a) | `block_eval.unresolvedSectionPath` · `reject/comptime_section_path_declared_after` |
| cep-b | A local decorator's function that writes a section path (`fn fallback() -> Tok { return .Pad.All.8; }`) is inferred ahead of the run, once, as 371 infers one writing `same` (`infer.sameLoweredFn`), and carried rewritten; (b) would refuse the decorator at the annotation naming the path. Recommended: (a) — no remedy exists for (b) but moving the function to another module | `infer.sameLoweredFn` · `run/comptime_decorator_section_value` |
| cep-c | A comptime module's record is its untagged map, so (a) `v is Rule` and an arm naming a record test its declared keys — `is_map(V) andalso is_map_key(selector, V) andalso is_map_key(decl, V)` — and a record of another type with those keys answers `true`; (b) carry the type in the map (`#{'__bp_type' => 'Rule', selector => …}`), a change of every comptime term the evaluators read and reply; (c) refuse `is` / a record arm on the comptime runtime where two carried records share their keys. Recommended: (c), the strictest; (a) implemented, no cell has two such records | `codegen/erlang.zig` `untypedRecordTest` · `run/comptime_record_pattern` |
| 388-b | `c.run(scope)` answers `@Task<Rendered<R>>` for every component (375's mark is not in the type), declared on `builtins.d.bp`'s `Component<R>`; std's `context` declares `pub type Rendered<R>(value: R, scope: RenderScope)` and `pub type RenderScope(frames: unknown)`, its construction refused outside std (`render-scope-construction`) since botopink has no private constructor | `infer.inferComponentRun` · std `context` · `run/component_run_root`, `reject/render_scope_construction` |
| 388-c | 388 (4)'s "outside every body a value runs with `c.run(RenderScope.root())`" read as what `await c` means there: an `await` of a component value in a plain function, `main`, a test or a lambda runs it with `RenderScope.root()`; (b) would refuse it, naming `c.run(RenderScope.root())` — every test and `main` that awaits a component would be rewritten | `context_lower.zig` · `run/component_run_root` |
| 139-b | `bigint`'s surface is `primitives.bp`'s `behavior BigInt`, beside every other primitive's methods, and not a `type bigint` in `builtins.d.bp` as the front's README first said: the parser refuses a `self` method in a field-less `type` (`namespace-type-self`), and a static `declare fn` there is an `@`-builtin row of `builtins.zig`. `bigint.of(n)` / `bigint.parse(text)` are associated host primitives of decision 262's form (`String.fromCodepoint`'s), written through the type's own name (the checker renames the receiver `BigInt`); `BigInt.of(n)` types too, as `String.fromCodepoint` does. (b) would teach the parser and the drift test a primitive `type` with methods | `primitives.bp` · `infer.inferPrimitiveStaticCall` |
| 388-d | The wasm backend refuses a module the scope lowering reached, at its first component (`the wasm backend does not lower a component yet`), until 05's lowering: every component cell is a `.wasm.expect` (32 cells; `run/decl_hooks_*` among them, which ran on wasm under 354's map) | `wat.zig` `refuseScopeLowering` · `language-gaps.md` 354-wasm |
| 388-e | A body that keeps a bare `try` runs the statements after its last `use provide` as an inner closure, whose answer (the value, or the error the `try` returns early) is the result; every other body answers `rendered(v, kids)` at each `return` | `context_lower.zig` `lowerComponentBody` · `run/component_try_in_body` |
| 389-a | A declared function whose own return is no `@Component` answering one through its type arguments (`first<T>(cards)`) is 389's "what generic code answers": an edge with `callee: null`, the node asynchronous, no synchronous mark on the call | `infer.noteHookCall` · `run/decl_hooks_dynamic_call` |
| s29-c | A template annotation's outputs name a hole by its expression as written (the part's `code` placeholder `__bp_hole_q_0` becomes `id` in a recorded meta or member source); `q.fail` / `q.failAt` / `decl.fail` and a `lookup` of a name not in the text are reported at the annotation (the literal has no span map there); its `DeclAnnotation.args` is the literal as written; `decl.params` lists `self` | `infer.unplaceholderContributions` · `decorator_eval.annotationPlans` · `run/template_annotation` |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 01c-a:** confirm as a name and cache key only: the scheme (`__tpl__`, and `__dec__` for a decorator) lives in `template_eval.zig` `ownerId` and `decorator_eval.zig`, read by `crossModule.erlDeclAtom` / `decodeAtom`; the comptime module is still written as Erlang text that `runtime/wat/erl_parse.zig` and `lower.zig` lower to wasm (434) — the Where's "comptime" is that path, no BEAM runtime.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 01c-b:** confirm (369's and 382's reading of a leading-dot path under an expected section type; not re-measured).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — ck2-a:** confirm (cell `builtin_module_not_lowered`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — ck2-b:** confirm (cell `enum_section_leaf_beside_variant`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — ck2-d:** confirm (cell `label_on_function_value`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — ck2-e:** reverse to one rule for every package (386): a std decorator is imported as a library's is — by leaf (`import {testing.mocks.mock} from "std"`, written `#[mock]`) or through its namespace (`#[mocks.mock]`) — and `std-decorator-leaf-import` goes; `#[<handle>.<not a decorator>]` stays `unknown-annotation`. Two import rules for one kind of thing is what 386 removed for libraries; `#[mocks.mock]`'s text naming `mocks.invoke` is a message to fix, not a reason. Viable: `infer.zig` `registerStdDecorators`; cells `std_decorator_leaf_import` (becomes a run cell), `std_decorator_unknown_through_handle`, `std_decorator_through_namespace`.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — rc3-b:** confirm (cell `host_unknown_parameter`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — rc3-c:** confirm the rule; the cell `narrow_ends_at_assignment` now pins an optional-read refusal (`v is read off an optional ?Node — write ?.v`), not an assignment ending a narrowing — a 144 row: the cell is re-measured and rewritten to its claim (458 (2)).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 0405-b:** confirm (`codegen/js/js_prelude.zig` `__bp_show`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — onze F7:** confirm (cell `integer_division_truncates`; the text is `conformance/docs.md` § operators now).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-a:** confirm (`codegen/hostMethods.zig`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-b:** reverse to the recommendation: `inline: true` on a type method's `@External.Erlang` is refused at the annotation, located — an accepted flag that changes nothing is a lie (67); the checker already refuses an unread `inline` on `Node` / `Wasm` / `Typescript` (`infer.zig` `refuseUnreadInline`) and `hasExternalInline` is read only by the primitive dispatch, so the refusal is one more arm there; 144 B-02's step 27 takes it, the cell `external_method_local` rewritten from `inline = true` into a refusal cell.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-c:** confirm, as `ctr-o`'s one rule (`hostMethods.missingAt`); the wasm arm `binds(.wasm)` hard-coded `false` is `ctr-o`'s 144 row.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-d:** confirm (`libs/std/src/io/net.bp`; `regex.bp` `Regex.matches`); a 144 std row to weigh: the free `regex.matches(pattern, input)` beside `Regex.matches` is a second spelling of one test.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-e:** confirm; amend the Where: `tlsEchoOnce` is std's (`io/net.bp`), `rkvPush`, `putMessageSource` and `messageSourceOr` are `validation`'s (`src/binding.bp`, `src/messages.bp`) since 326.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-f:** confirm (`js_prelude.zig` `__bp_adopt`; cell `external_method_on_host_record`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — cep-a:** confirm until 144 B-72, which removes it with 14s8-d's refusal (one box for both; `block_eval.unresolvedSectionPath`, cell `comptime_section_path_declared_after`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — cep-b:** confirm (`infer.sameLoweredFn`; cell `comptime_decorator_section_value`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — cep-c:** (c), the recommendation, as a 144 row: on the comptime runtime a record is still an untagged map (the comptime module is Erlang text lowered to wasm; `erlang.zig` `untypedRecordTest`, `is_map_key` served by std-wasm's term library) and `v is Rule` tests keys, so two comptime records sharing their keys answer `true` for each other — a silently wrong answer (67). Proposed: `is` and a record arm on a comptime value are refused, located, where two records carried into that comptime module share one key set, until the comptime carries the type ((b), the complete answer, on a measured need); the check sits where the module is emitted (`erlang.zig` `emitComptimeModule` knows the records it carries). Viable today; a refusal cell beside `comptime_record_pattern`.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 388-b:** confirm (`infer.inferComponentRun`; std `context.bp` `RenderScope` / `Rendered`; cells `render_scope_construction`, `component_run_root`); under s23-j's answer an unmarked component answers its tree directly at run time and `await` on it is a no-op (375 (3)) — the type `@Task<Rendered<R>>` stays sound because `await` is always legal.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 388-c:** confirm (`context_lower.zig` `bpScopeRoot__`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 139-b:** confirm (501; `primitives.bp` `behavior BigInt`, `infer.inferPrimitiveStaticCall`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 388-d:** confirm until 144 B-25 step 4 (504: composition by data on wasm); amend the count: 38 cells carry a `snapshot/targets/wasm/main.snap` departure "does not lower a component" (the `.wasm.expect` form left with 457), all leaving with B-25 (458: a departure never records a defect — these are the `language-gaps.md` row 354-wasm, which B-25 closes).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 388-e:** confirm (`context_lower.zig` `lowerComponentBody`; cell `component_try_in_body`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 389-a:** confirm (`infer.noteHookCall`; cell `decl_hooks_dynamic_call`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — s29-c:** confirm (`infer.unplaceholderContributions`, `decorator_eval.annotationPlans`; cell `template_annotation`); the `__bp_hole_q_0` placeholder is rewritten by the step that lands 14s8-a (e) (s29-a).

##### 24-c · `iter for` / `iter while` are a prefixed `loop` (*implemented as (a)*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built** — sugar over the prefixed `loop`, the label naming the written `for` (`LoopExprOf.prefixedKeyword`, `yield-label-not-generator`; cells `iter_loop_and_for`, `yield_label_loop`): the equivalence 125 writes, no new backend node (four lowerings to keep in agreement would be (b)'s cost for nothing). Viable, built; no change.
- **Measured.** The front's README asked for a new node `GenLoop { kind, loop }`; but each of the four backends already lowers one form of annotated loop (22-loops' `loop`), and decision 125 itself says `iter for (xs) { … }` means `iter loop { for (xs) { … }; break; }`. The parser reads it so and keeps the written keyword in `LoopExpr.prefixedKeyword`, for the formatter to give it back. The label stays where decision 105 writes it, after the loop's word.
  Today:
  ```bp
  iter for (xs) { x -> yield x * 2; }      // read as: iter loop { for (xs) { x -> yield x * 2; }; break; }
  iter loop :l { yield :l 1; }             // the label names the generator
  iter for :l (xs) { x -> break :l; }      // the label names the written `for`
  iter for :l (xs) { x -> yield :l x; }    // error[yield-label-not-generator]
  ```
- **Options.** (a) ★ Syntactic sugar over the prefixed `loop`; the label of `iter for :l` names the `for` (so `break :l` / `continue :l` keep their usual meaning).
  ```bp
  iter for :l (xs) { x -> if (x < 0) { continue :l; }; yield x; }   // continue of the `for`
  ```
  (b) A new `GenLoop` node, with a lowering of its own in each of the four backends — the same source, four more paths to keep in agreement.
  ```bp
  iter for (xs) { x -> yield x * 2; }      // becomes GenLoop { kind: For, loop: … } down to the backend
  ```
  (c) As (a), but the label of a prefixed `for` also names the generator — the parser only moves the label to the outer node.
  ```bp
  iter for :l (xs) { x -> yield :l x; }    // compiles: `:l` is the generator's scope
  ```
- **Recommendation.** (a). It is the equivalence decision 125 already writes, with no new backend.
- **Blocks.** Nothing (`01-compiler/24` step 2's confirmations).

##### 23-b · `base64`'s four functions retired, not aliased (*implemented as (a)*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built** — the four retired; `encoding.base64Decode` / `base64UrlDecode` answer `@Result` (`libs/std/src/encoding.bp`, `base64.bp` gone): no alias hiding a refusal (67). Viable, built; no change.
- **Measured.** `base64.decode` answered a `string`; its replacement `encoding.base64Decode` answers `@Result<string, string>` because front 01 validates the input before `Buffer.from` truncates it (likewise `decodeUrlSafe` → `base64UrlDecode`). No library imported `base64`. `base64.bp` was deleted and its four tests rewritten with the `encoding` names (std keeps 417 tests). Decision 106 and `01-std/modules.md` already name the replacements.
  Today:
  ```bp
  val s = try encoding.base64Decode(text);     // @Result<string, string>: validates before decoding
  base64.decode(text)                          // no longer exists
  ```
- **Options.** (a) ★ Retire the four (`encode` / `decode` / `encodeUrlSafe` / `decodeUrlSafe`).
  ```bp
  val raw = try encoding.base64UrlDecode(token);
  ```
  (b) Keep the four in `encoding` as aliases answering `string` (they hide the refusal).
  ```bp
  val s = encoding.decode("not base64!");   // answers a truncated string, no error
  ```
- **Recommendation.** (a). Two spellings of one codec, one of them hiding the refusal, is what front 01 removed.
- **Blocks.** Nothing (`01-compiler/23` step 2's confirmations).

#### 02-std-and-packaging (10)

| Id | Choice implemented | Where |
|---|---|---|
| 01std-a | A bundled library loaded by CLI and LSP (`appendBundled`), not `expandStdImports`; compiler-core names no package but `std` | `build.zig` `bundled_packages` |
| 01std-c | `routing.pattern`'s empty pattern matches only `/`; rakun-web keeps "empty runs everywhere" at its call site (`matcherAdmits`) | `routing` |
| 01std-e | `actions.readEnvelope` refuses a `redirect` disagreeing with `n` | `actions` |
| std-a | `querystring.parse` / `parseForm` answer `@Result`, refuse a malformed escape, non-UTF-8 and a control character raw or decoded; `stringify` refuses a control character; `parse` is RFC 3986 (`+` stays), `parseForm` the form flavour (`ctr-p`) | `libs/std/src/querystring.bp` |
| std-b | `fs.exists` follows a symbolic link (dangling link is `false`) | `io/fs.bp` |
| 95-a | Front 95 relocated `jhonstart-link` and `rakun-app` as moves with no behaviour | jhonstart · rakun |
| 95-b | `rakun-app` declares its own `"targets": ["erlang"]`, as all 36 rakun manifests do (option (b); 1.0.10's "inherits the workspace" is not what the code does) | `rakun-app` manifest |
| 95-c | `erika-test` exists | erika |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 01std-a:** confirm the rule (compiler-core names no package but `std`: `comptime.zig` `bundledPackage`); amend the row: the bundled set is `std` alone since 326 (`build.zig` `bundled_packages`), and `appendBundled` no longer exists (it survives only in `compiler-cli/src/cli/AGENTS.md` and `language-server/AGENTS.md`, two stale lines for 144).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 01std-c:** confirm (`routing/src/pattern.bp`; `rakun-web/src/middleware.bp` `matcherAdmits`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 01std-e:** confirm (`actions/src/envelope.bp` `readEnvelope`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — std-a:** confirm (`libs/std/src/querystring.bp`); its cookie counterpart is `ctr-p`'s.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — std-b:** confirm (`libs/std/src/io/fs.bp` `exists`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 95-a:** confirm (both members exist).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 95-b:** reverse under 512 (3): `targets` is inherited from the workspace and a member writes it only to narrow; rakun's 31 identical `["erlang"]` lists (the "36" is stale) go in 150's manifest sweep, the workspace manifest keeping the one declaration — one place for one fact.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 95-c:** confirm (`erika/modules/erika-test`).

##### 24-g · The shape of `std/async` with a Task that never fails (*implemented as (a)*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built** — `allOf` / `all` / `race` over started tasks, `runAll` / `raceOf` / `timeout` over thunks, `failed(message)`; each form has one name (67), and the guide and 24's suite already write it; 432 later made a `@Task<@Result<T, E>>` reject, which changes no name here. Viable, built: `libs/std/src/async.bp` (the module has since grown `Gate`, `delay`, `RetryPolicy`, `retry`). Changes: none; the `beam_memory_*` note (an erlang task runs eagerly) is lg2-b's defect, not this choice's.
- **Measured.** Before front 24, `std/async` had a surface of thunks (`allOf`, `settleOf`, `raceOf`, `timeout`) and one of already-started Tasks (`all`, `allSettled`, `race`), both built on "rejected Task = failure". Now a Task never fails (decisions 120 and 121): the error goes INSIDE, `@Task<@Result<T, E>>`. The guide writes `try await async.allOf([fetchUser(1), fetchUser(2)])` — already-started Tasks whose value is a `@Result` — and front 24's suite follows the guide; the `beam_memory_*` cells, though, need unstarted thunks, because on erlang an eager Task has already run when the combinator receives it. The implementation gave the guide's form the name `allOf` and the thunks other names.
  Today:
  ```bp
  val users = try await async.allOf([fetchUser(1), fetchUser(2)]);   // started Tasks of @Result: stops at the first Error
  val xs = await async.runAll([{ -> work(1) }, { -> work(2) }]);     // thunks: this is where the concurrency is
  val r = await async.timeout({ -> slow() }, 100);                   // timed out → Error("timeout"), a string
  ```
- **Options.** (a) ★ Started: `allOf`, `all`, `race`; unstarted: `runAll`, `raceOf`, `timeout`; `failed(message)` answers `Error(message)`; `allSettled`, `settleOf`, `unwrapAll` and `attempt` were removed (there is no rejection to "settle"). A crash inside a task is re-raised.
  ```bp
  val users = try await async.allOf([fetchUser(1), fetchUser(2)]);
  async.allSettled([…])          // no longer exists
  ```
  (b) `allOf` over thunks, as the README of `01-std/02` wrote it — the guide's example is rewritten with thunks.
  ```bp
  val users = try await async.allOf([{ -> fetchUser(1) }, { -> fetchUser(2) }]);
  ```
  (c) One `allOf` overloaded for both element forms — needs overloading by type, which the language does not have.
  ```bp
  async.allOf([fetchUser(1)])            // started
  async.allOf([{ -> fetchUser(1) }])     // thunks — same name, another signature
  ```
- **Recommendation.** (a). It follows the guide and front 24's suite, and each form has one name.
- **Blocks.** Nothing — the README of `01-std/02-std-async-primitives` (1.0.10) already specifies `allOf` over started Tasks (`02/97` step 5 — the `RetryPolicy` built on `std/async`, a residue — and `01-compiler/24` step 2).

##### std-c · Decision 110's folder namespace is a rewrite of the parsed program (*implemented as (a)*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a) until B-69, which decides the folder's fate** — the rewrite stands (`comptime/std_namespace.zig`); under B-55-a (e) (1) a module is named by its path and nothing says a folder is a value, so B-69 states one rule for `import {io} from "std"`: proposed, the leaf form `import {io.fs} from "std"` is the one way and a folder is not importable (one spelling, and no rewrite that can miss a member — `io.nope.f()` today is `unbound variable 'io'`, a diagnostic that names nothing); (b)'s namespace type is not needed then. Viable: B-69 (the resolver's module naming) and the deletion of `std_namespace.zig`. Changes: a box in B-69; decision 110's folder namespace amended by it.
- **Measured.** Decision 110 allows `import {io} from "std"` and then `io.fs.readText(…)`. The implementation (`comptime/std_namespace.zig`) rewrites the already-read program to the leaf forms the checker and the four backends already lower: `io.fs.f()` becomes the namespace of `io/fs` (the item `io.fs as __bp_ns_io_fs` is added), and `collections.Dict` becomes `Dict`. Only the modules reached are imported. Limits: a missing member is `unbound variable 'io'`; a module declaring its own top-level `Dict` keeps `collections.Dict` unrewritten (refused all the same); a local named like the folder (`fn f(io: …)`) is not told apart from it. (23-a's alternative came in through here.)
  Today:
  ```bp
  import {io} from "std";
  io.fs.readText(path)       // rewritten to the leaf import `io.fs`; only the modules reached are imported
  io.nope.f()                // unbound variable 'io'
  ```
- **Options.** (a) ★ The rewrite: one file, no backend touched.
  ```bp
  import {collections} from "std";
  val d = collections.Dict.empty();   // runs on the four targets
  ```
  (b) A namespace type in the checker and a lowering of `a.b.f()` in the four backends, so the diagnostic names the folder.
  ```bp
  io.nope.f()                // error: std folder `io` has no module `nope`
  ```
- **Recommendation.** (a). (b) only if the diagnostic naming the folder is wanted.
- **Blocks.** Nothing (`01-compiler/23` step 2's confirmations); a reversal opens a step in `01-checker`.

#### Choices made by the 00-gate threads and the consolidation (5)

| Id | ★ implemented | Where |
|---|---|---|
| 111-b | the beam sidecar loader is emitted only when the build binds a host function (13 snapshots changed); the erlang backend follows the same rule (`buildBindsErlangHost`) | botopink-lang `codegen/beam_asm.zig` |
| 113-a | a target `botopink test` cannot run (wasm today — it runs commonJS, erlang and beam) is `NOT RUNNABLE` and fails `test-libs`, as `fronts.md` § Gate item 3 requires | `scripts/test-libs.sh` |
| 113-b | the restriction audit matches the refusal by its text (alternative, recommended: give the refusal an id — 07-residuals) | `lib-test-runner` |
| 110-b | the count history left `tests/language/AGENTS.md` | `tests/language/AGENTS.md` |
| 112-a | `format-check`'s `TREES` holds `examples` as one entry plus `modules/manifest/tests` | `scripts/format-check.sh` |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 111-b:** confirm; amend the name: the erlang side is `codegen/crossModule.zig` `bindsErlangHost` (the beam side `beam_asm.zig` `bindsBeamHost` / `buildBindsBeamHost`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 113-a:** confirm as built (`scripts/test-libs.sh` counts `skipped_unsupported` as NOT RUNNABLE and fails; `test_cmd.zig` refuses `.wasm` only); two stale lines for 144: the script's legend still says "(beam, wasm)", and the wasm column of `botopink test` is B-25 / 97 s11's.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 113-b:** reverse to the alternative: the refusal gets an id (`host-binding-missing`, beside 334 (3)'s `std-unsupported-on-target`) and the audit matches the id, never the text (`lib-test-runner/src/runner.zig` `HOST_BINDING_MARK`) — a reworded message would silently pass the audit (67). 510 does not touch it (the audit spawns a build, no store).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 110-b:** obsolete: `tests/language/` left with 466 (conformance in-tree); the file does not exist.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 112-a:** confirm as it now is: `TREES=(examples libs/std modules/compiler-cli/tests modules/manifest/tests conformance)` — `examples` one entry; amend the row.

#### 03-bundled-libs (4)

| Id | Choice implemented | Where |
|---|---|---|
| 106-b | `log.consoleSink` writes one line per record on standard output through `@print` on every target (not node's `console.error` / `console.warn`, not OTP `logger`) — the one stream a wasm program also writes; `defaultSink` keeps the host's logger | `repository/log/src/sink.bp` |
| 106-c | `log.fileSink` rotates as OTP `logger_std_h` does, written once in botopink over four cells: after a write leaves the file at `maxBytes` or more, the file becomes `<path>.0`, each archive moves one up, `<path>.<maxFiles - 1>` is deleted, `maxFiles` 0 deletes the file; a failed host call raises; rakun's total size cap stays rakun's (folded into `maxFiles`) | `repository/log/src/logfile.bp` |
| 106-d | Per-name levels: `Threshold { From(level), Off }`, `Levels(root, names)`, the longest dotted prefix set wins; an empty name, an empty segment and a name set twice are refused (an `Error` when a sink is built, a panic when resolved); groups and run-time overrides are the framework's (it rebuilds the `Levels` and installs a sink again) | `repository/log/src/levels.bp` |
| 106-e | `log.captureRuntimeReports()` observes and never handles: BEAM a primary `logger` filter on the `otp` domain that hands the event on unchanged (OTP's own handler still prints it), node `uncaughtExceptionMonitor` (node still exits; `unhandledRejection` arrives as its origin under node's default mode), records of the logger `runtime` with `report.kind` (and node's stack under `error.stack_trace`), wasm a no-op binding | `repository/log/src/reports.bp` |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 106-b:** confirm (`log/src/sink.bp` `consoleSink`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 106-c:** confirm the rotation; amend "a failed host call raises": under 431 / 486 / 495 the four file cells (`appendLine`, `fileBytes`, `moveFile`, `removeFile`) carry `result: true` and `fileSink` / `appendRotating` answer `Error` of `log`'s own error enum, never a raise — 144 B-08's audit names the cells, 156 takes the consumer change.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 106-d:** confirm (`log/src/levels.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 106-e:** confirm (`log/src/reports.bp`; its wasm cell is already `fn: captureNothing`, 481).

#### Choices made by the bugs-sweep thread (4)

| Id | ★ implemented | Where |
|---|---|---|
| bs-a | A type's associated fn is called as a std module's fn is (`planQualifiedCall`): a short call is filled from the declared defaults, a labelled one reordered, any other count is the arity error. `fn of(x: string, y: string = "d")` — (a) ★ `Bag.of("p")` is `Bag.of("p", "d")`; (b) refuse the short call, `'of' expects 2 argument(s), got 1` (before, every count but the exact one fell to a fallback that checked nothing and filled nothing) | `infer.zig` `associatedCallReturnType` · `run/associated_fn_of_type_default` |
| bs-b | An unsigned type takes no negated literal: `val x: u32 = -1;` — (a) ★ refused at the literal, ``the literal `-1` does not fit `u32` (at least 0)``; (b) accepted, and 264's run-time check aborts at the negation (`-0` is accepted either way) | `infer.zig` `refuseIntegerOutOfRange` |
| bs-c | An `erl` that printed its break handler's banner (`BREAK: (a)bort …`) is an interrupted run even though it exits 0 (SIGINT, then EOF on stdin halts the emulator with status 0): never stored in the runtime cache — the one place the harness reads the output, and only to decide not to cache. (a) ★ the banner marks it `.interrupted`; (b) spawn `erl +Bi` (SIGINT ignored): the run completes and is genuine, but a hung run then outlives Ctrl-C until the 2-minute timeout | `codegen/runtime.zig` `classifyEnd` |
| bs-d | `scripts/check-docs.sh --lib-root <dir>` replaces the default library roots; the harness test names its own. The gate keeps the default, which hashes every sibling package whole — `repository/vscode-extension` carries a `botopink.json`, so a symbolic link in its `node_modules` makes every docs check `never stored` in the meta checkout (a cost, never a verdict). (a) ★ as is; (b) the default roots take only a package with a `src` (vscode-extension's manifest is `{ "name", "version" }`); (c) the tree hash skips `node_modules` | `scripts/check-docs.sh` · `modules/compiler-cli/tests/result_store.sh` |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — bs-a:** confirm (`infer.zig` `planQualifiedCall` / `associatedCallReturnType`; the cell is `associated_fn_of_type_default`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — bs-b:** confirm (`infer.zig` `refuseIntegerOutOfRange`; the message now cites 319).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — bs-c:** confirm the classification (`codegen/runtime.zig` `classifyEnd`); the cache it guards — the harness's content-keyed runtime-output cache of compiler-core's snapshot tests, which short-circuits an `erl` / `node` run on a hit — is what 510 forbids read literally ("every test runs on every check"): proposed, that cache goes (a 144 row), subject to the maintainer confirming 510 reaches compiler-core's own tests; bs-c then has no object.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — bs-d:** obsolete: `check-docs.sh` takes no `--lib-root` (its options are `--doc`, `--list`, `--self-test`; it checks that `<!-- example: … -->` references name existing cells, 461), and the result store and `result_store.sh` left with 510.

#### Other tracks' choices a 00–03 step waits on

| Id | Choice implemented | Where |
|---|---|---|
| 03r-q | Locale routing lives in `rakun-app/src/i18n.bp`; no `rakun-i18n` member | 22 |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-q:** confirm (`rakun-app/src/i18n.bp`; no `rakun-i18n` member).

---

## Part 2 — The rest

### Priority — the botopink shape (`nat-*`)

#### nat-d · A second model of what the language has — case by case (decision 283)
No general rule (283): each case below is its own question, (a) the language's own, (b) both — the foreign one a thin layer over the native — or (c) as is.

#### nat-d6 · `throw "nav:not-found"` beside `noreturn` (53)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), typed: `notFound() -> noreturn`, `redirect(url) -> noreturn`, the signal a `NavOutcome` value, caught by type, never by a `nav:` prefix** — jhonstart's two signals raise `NavOutcome` (`NotFound`, `Redirect(url)`) through its one host cell (`__jhRaise` carrying the value: an `Error` holding it on commonJS, `error({jhonstart_nav, Outcome})` on erlang) and answer `noreturn`, so `throw notFound();`, a bare `notFound();` and `val s: string = if (c) "a" else notFound();` all check (lg2-l: the code already has `noreturn` as the bottom type); a boundary reads the caught value with `case` over `NavOutcome` (`renderNotFound` catches `NotFound` only, `renderErrorBoundary` re-raises any `NavOutcome`, 414 (2)); an action redirects by its `@Result` — `ActionError` gains `Redirect(url: string)` (303 amended; 303 See Other on the wire), no raise. 281 (a code fact never travels as a string), 67 (the boundary matches a type, a misspelt prefix cannot slip), and `isSignalReason`'s string test goes; (b) keeps the string under a wrapper; (c) keeps `-> string` for a value never produced. Viable now: `jhonstart/modules/jhonstart/src/error_boundary.bp` (`__jhRaise`, `notFound`, `redirect`, `__jhCapture`), `signal_runtime.mjs` / `jhonstart_signal.erl`, rakun-app's `navigation.bp` (`rkNavSignal`, `-> i32`), `actions`' `ActionError`; measured on feat that a `declare fn raise(reason) -> noreturn` host cell checks and runs on commonJS and erlang. Changes: `language-gaps.md`'s "navigation signals do not return `noreturn`" row closes (its text is stale: `throw notFound();` already checks); `31-a` (Part 3) becomes `-> noreturn`; wasm follows the cells' wasm form (B-25); once `attempt` lands (B-07) the boundaries' host try is 431's, the `NavOutcome` still read by type.
- **Measured.** A signal is a host-raised `nav:`-prefixed string (`contracts.md` § 5b); jhonstart's `notFound()` / `redirect()` declare `-> string`, rakun's `-> i32` (`jhonstart/src/error_boundary.bp:180-189`, `rakun-app/src/navigation.bp:47-55`); `isSignal` → `isSignalReason` by prefix; `boundaries-example.bp:89-91` (a `throw` inside `-> @Result`, an `Error` value by 118, not a raise); `server-action-example.bp:79` `val _gone = redirect(…)`.
- **Rules.** 303: an action answers `@Result<T, ActionError>` and `throw e` there is `Error(e)`; `ActionError` has `NotFound` but no redirect case — the answer must also say how an action redirects.
- **Options.** (a) `fn notFound() -> noreturn`, boundaries matching the `NavOutcome` type. (b) The string signal kept under a typed wrapper. (c) As is.
- **Recommendation.** (a). With lg2-l and lg2-h.
- **Blocks.** `05-jhonstart/26`, `07-onze/53`; lg2-l, lg2-h, 31-a.

#### nat-d7 · Lifecycle annotations beside interfaces (rakun 04)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), on a `Decl.implements` the compiler owes** — `type Cache(…) implement Lifecycle { fn start(self: Self) { … } fn stop(self: Self) { … } }`, `pub behavior Lifecycle { fn start(self: Self); fn stop(self: Self); }` declared by rakun's core; `#[component]` reads the type's `implement` clauses from its `@Decl` and registers the two calls; `#[postConstruct]` / `#[preDestroy]` go (318 (8): rakun speaks botopink, no Spring name). A behavior is the language's own shape for a contract (311 (1)), typed and checked at the declaration (a missing `stop` is the checker's error, not a marker nobody read), and one way to say it. Not viable today: `Decl` (`builtins.d.bp` `behavior Decl<T>`) exposes `kind`, `name`, `fields`, `variants`, `methods`, `returnType`, `annotations`, `hooks`, `params` and no `implements` — a 144 row: `Decl.implements: TypeInfo<unknown>[]` (s23-f's typed shape), mirrored in `comptime.zig`'s `decl_reflection_src`; rakun 04 pauses on it and keeps (c)'s markers (`rakun/src/lifecycle.bp`, `context.bp`'s `rkRegisterLifecycle` over `decl.methods`) as its nearest form, marked a language gap. Changes: the 144 row, then rakun 04's step.
- **Not viable (fable, 2026-10-12):** (a) and (b) today — `Decl` exposes no `implements`; both wait on the `Decl.implements` row above (until then (c) is the nearest form, a language gap).
- **Measured.** `context-lifecycle-example.bp:66,72`: `#[postConstruct]`, `#[preDestroy]`.
- **Options.** (a) `implement Lifecycle { fn start(self); fn stop(self) }`. (b) Both. (c) As is.
- **Recommendation.** (a).
- **Blocks.** rakun 04.

#### nat-d8 · A `use…` hook name under `use` (53)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): `use actionState(createPost, initial)`; a hook whose name starts with `use` is refused at its declaration** — a hook is a function answering `@Component<R>` and is read with `use h(…)` (354 (1)), so `use useX(…)` spells the verb twice; the checker refuses a `@Component`-answering declaration named `use<Upper…>`, located (`hook-name-use-prefix: a hook is read with use — name it actionState`). One spelling (67), and 281 already fixes the argument (the action by reference). Viable: jhonstart-forms' `actionState(actionId: string, initial)` exists (`form.bp`; its first parameter becomes the action reference under 281 — a step of 150's jhonstart section, 150 s36 … s47); the refusal goes with the `use` diagnostics in `comptime/diagnostics.zig` and `infer.zig`'s `.useHook` arms (today `use useThing(2)` passes `check`), one refusal cell. Changes: 53's example rewrites `use useActionState(…)` to `use actionState(…)`; one 144 row for the refusal.
- **Measured.** `new-post-form-example.bp:118`: `use useActionState("createPost", actionState(""))` — jhonstart exports no `useActionState`; jhonstart-forms' hook is `actionState(actionId: string, initial)` (`form.bp:182`).
- **Rules.** 281 already settles the argument: the action is passed as a reference (`createPost`), never a string — in the example and in `actionState`'s signature. Only the hook's name is open.
- **Options.** (a) `use actionState(createPost, initial)`; a hook named `use…` refused. (b) Both names. (c) As is.
- **Recommendation.** (a).
- **Blocks.** `07-onze/53`'s examples.

#### nat-f · Configuration in JSON — case by case (decision 284)
`botopink.json` as clean as possible, configuration allowed where it makes sense (284); `"bpp"` stays, an object since 338 (`{"default": "<package>", "style": …}`). Each case below is its own question.

#### nat-f2 · `onze.json`'s `trailingSlash`, `redirects`, `markdown`, `allowedRedirects` (124, 08-h)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as one typed record** — `onze.json` keeps its keys (284; 271 fixes `trailingSlash`, `redirects`, `markdown`, `islands`, `site`), read at build into one `OnzeConfig` record whose fields are the typed options onze's code already has (`UrlRules`, `MarkdownOptions`, `IslandProps`, `allowedRedirects: string[]`): an unknown key, a wrong kind, an unknown variant or a bad value is an error naming the file, the key path and the expected type (49-c's refusals, typed), 299's precedent in onze's own loader. Configuration is allowed there (284) and the build checks it as it would code; (b) would move what 271 / 272 / 224 placed in `onze.json` and leave two homes for one fact. Viable today: `onze/modules/onze/src/config.bp` `loadConfig` / `applyKey` / `configKeys` (hand-written, typed; `allowedRedirects` exists, the other four are added there); 299's `#[config]` binder is not built in rakun, so nothing is copied; the line in the file is "subject to" the `json` library's `decode` exposing a path's position — until then the error names the key path. Changes: 124 step 1 (the four keys) and 50 / 53 read `OnzeConfig`; `islands` joins `configKeys` (224 names it, the code lacks it).
- **Not viable (fable, 2026-10-12):** (a) through 299's `#[config]` binder — it is not built in rakun; the proposal uses onze's own typed loader instead.
- **Measured.** `onze.json` is read and validated by `loadConfig` whenever the CLI resolves the project, `onze build` included (`onze-cli/src/resolve.bp:48-50`); an unknown key is refused (49-c) without a line. Only `allowedRedirects` exists (`onze/src/config.bp:192-193`); `trailingSlash`, `redirects`, `markdown` are 124's planned keys (`124-bpp-cli/README.md:67-69`), which 08-h already writes; all four restate options onze's code types (`url_rules`, `MarkdownOptions`, `app(allowedRedirects:)`). Precedent: 299 (typed record bound from a file, errors naming file, line and expected type).
- **Options.** (a) Kept in `onze.json`, read into the typed record at build as 299 does, a wrong key or value an error at its line in the file. (b) A typed record in the app's code (`pub val config = OnzeConfig(trailingSlash: .Never, …)`), no JSON. (c) As is.
- **Recommendation.** (a) — configuration is allowed there (284); the build checks it as code would, as 299 does for rakun.
- **Blocks.** 124; 08-h; `07-onze/49`, `50`.

#### nat-f4 · The `ONZE_PUBLIC_` prefix on environment variables (53, `contracts.md`)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(b): the declaration says it — `#[publicEnv] pub val apiUrl = env.read("API_URL");` — and the `ONZE_PUBLIC_` prefix goes** — a value the browser may see is declared once, typed, marked where it is read; the bundler inlines the build's value of a marked `val` into the client bundle and refuses, located, any `env.read` reached from a `#[client]` component that is not such a `val` (`env-non-public` kept, its message naming the marker). A fact carried by a naming convention of the environment is a string rule the code never states (281's spirit; 67: a forgotten prefix is a located error either way, but the marker is checked where the author wrote it, not where the operator named a variable); (c)'s list in `onze.json` is a second home for a code fact. Viable: `onze/modules/onze-bundler/src/refusal.bp` (`env-non-public`, `env-dynamic`, `env-vars`, `env-write`) and `scan.bp` already find a client module's `env.read`; `config.bp` `isPublicEnvName` / `publicEnvPrefix` go; `publicEnv` is a decorator on a `val` (356: it runs and the `val` is catalogued) recording `PublicEnv(name)` typed meta, which the bundler reads from the scan (it scans source today) or from `@TypeInfo.all(with: publicEnv)` at the app's root. Changes: 50 / 53 and `contracts.md` § env; the examples' `ONZE_PUBLIC_*` names become plain names under the marker.
- **Measured.** A variable reaches client code only when its name starts with `ONZE_PUBLIC_` (Next's `NEXT_PUBLIC_`). A missing prefix is not silent: the bundler refuses at build a client module's `env.read("X")` without it, naming the variable (`env-non-public`, `onze-bundler/src/refusal.bp:13-14`; `contracts.md:440-442`). What remains is a stage fact (186) carried by a naming convention the environment must follow (`client-island-example.bp:41`).
- **Options.** (a) Kept. (b) The declaration says it — `#[publicEnv] val apiUrl = env.read("API_URL")`, its use from a `#[client]` component checked at comptime (186); a marker of its own, since `#[clientVisible]` is 278's hydration annotation; 299's `#[env("…")]` the precedent in a record. (c) A list of public variables in `onze.json`.
- **Recommendation.** (b).
- **Blocks.** `07-onze/50`, `53`; `contracts.md`.

### 01-compiler — the language

#### lg2-b · What `@Task<T>` means on the BEAM
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Answered by 392: a `@Task<T>` starts when it is made and runs to its first `await` on every target — on erlang and beam a process per task; the eager lowering is a defect** — two `async.delay(300, …)` made before either is awaited take ~300 ms, as on commonJS (392 (1): "node's Promise, erlang's process per task, and wasm alike"; 432 already ends "the task's process" with `{error, E}`). Re-measured on feat: commonJS 301 ms, erlang 603 ms, beam 603 ms — `codegen/erlang.zig` ("@Task — eager lowering") and `beam_asm.zig` still run the body where it is made, and `async.bp`'s header still says so. (1) contradicts 392's text, (3) adds a second mechanism beside `@Task`. Viable: a process per `-> @Task` body on erlang / beam (`spawn` + a mailbox the `await` receives from, as `runAll` / `raceOf` already do per thunk in `async.bp`), the eager fast path kept only where the checker proves no `await` can observe the difference — a 144 step with the repro above as its cell. Changes: `language-gaps.md`'s "`@Task<T>` lowers eagerly on erlang" row and `async.bp`'s header close with it; rakun's rows that cite lg2-b read 392.
- **Measured.** On erlang and beam a Task body runs to completion where created: two `async.delay(300, …)` created before either is awaited take ≥ 600 ms (under 600 ms on commonJS).
- **Options.** (1) A Task promises the value, nothing about when its body runs; concurrency = `std/async`'s explicit process per unstarted thunk, documented. (2) A scheduler behind `@Task` on the BEAM (a process per Task, `await` a receive). (3) `spawn` / `join` in the language.
- **Recommendation.** (1) — the restrictive reading of 1.0.10's 120.
- **Blocks.** The row; rakun 02, 23, 25, 28, 30, 60.

#### lg2-d · A decorator that reads the body it annotates
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(1), already the rule by 316 and 403** — a decorator never reads the body it annotates (316: "a decorator never reads the body (lg2-d) nor writes one as a string"); what it may do to a body is `decl.wrapWith(f)`, typed (316, 144 B-11); rakun 83's saga stays a value pairing each step with its compensation. Refuse over a statement API nobody checks; (2) and (3) would make a decorator's output depend on how a body is written. Viable: nothing to build — `Decl` has no `body` (`builtins.d.bp`), the read is `unknown field 'body' on type 'Decl'` at the read (measured on feat). Changes: the entry closes as documentation of 316; `language-gaps.md`'s row becomes by design.
- **Measured.** `decl.body` is the checker's `unknown field 'body' on type 'Decl'`, located at the read in the decorator body (`01-checker`'s decorator-body row; it was `{error,{badkey,body}}` at the annotation); the handle carries kind, name, fields, variants, methods, return type, annotations.
- **Options.** (1) No statement access. (2) A read-only statement tree on `@Decl`. (3) A body-walking comptime API.
- **Recommendation.** (1); rakun 83's saga stays a value pairing each step with its compensation.
- **Blocks.** The row; rakun 83.

#### lg2-h · Raising and catching by type
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(1), already the rule by 431 / 486 / 489 / 490** — an error is a `@Result`'s `E`: a typed error is an enum matched with `case` in the `catch` body (`try load(p) catch { e -> case e { NotFound(path) -> …; … } }`), a host failure arrives as `HostError` under `result: true` and a std module maps it into its own enum (486); no `catch` arm per type, no typed host exception. Measured on feat: `catch { e: NotFound -> … }` does not parse, the `case` form checks and runs on commonJS and erlang. Viable: nothing to build. Changes: the entry closes as documentation of 431; `language-gaps.md`'s "No typed raise and no catch by type" row becomes by design; rakun 07 / 31 / 63 write `case`.
- **Measured.** `try load(p) catch { e: NotFound -> … }` does not parse; a `@Result<T, E>`'s error is typed by `E`, read with `case` in the `catch` body; a host exception is not an `E`.
- **Options.** (1) An error is a `@Result`'s `E` (1.0.10's 121): a typed error is an enum matched with `case`. (2) A `catch` arm per type. (3) Typed host exceptions.
- **Recommendation.** (1) — the row becomes documentation of 121.
- **Blocks.** The row; rakun 07, 31, 63.

#### lg2-l · Whether `noreturn` is a bottom type
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(2), as the code already has it: `noreturn` is the bottom type, and a `noreturn` body must not fall through** — a `noreturn` call fits any position (`val s: string = notFound();`, `throw notFound();`, an `if` branch), ends its path (`stmtsAlwaysExit` / `callNeverReturns` narrow after it), and a function declared `-> noreturn` whose body can complete is refused at the declaration, located. Measured on feat: `unify.zig` ("`noreturn` is the one-way bottom type"), cells `builtin_noreturn_any_position` and `try_catch_null_and_noreturn_narrowing` pin (2) on the four targets; (1) would break both cells for no gain — a value position a `noreturn` fills is never produced, so nothing is silently wrong, and it is what lets the signals be `-> noreturn` (nat-d6). Viable: built; the fall-through check is one more use of `stmtsAlwaysExit` on a `-> noreturn` body (`infer.zig`). Changes: a 144 row for the defect (`fn bad(c: bool) -> noreturn { if (c) { @panic("x"); } }` compiles and returns); the entry's Measured and `language-gaps.md`'s two `noreturn` lines are stale.
- **Measured.** `fn notFound() -> noreturn { raise("…"); }` ends the path on commonJS and erlang, but `throw notFound();` in a `@Result` body and `val s: string = notFound();` mismatch → jhonstart's `notFound()` / `redirect()` declare `-> string` (`error_boundary.bp:180-188`); front 53's example writes `val _gone = redirect(…)` (`server-action-example.bp:79`); onze's blog app calls `notFound();` as a statement. `@panic` / `@todo` are `noreturn`; a branch ending in a `noreturn` call already narrows — may be confirmed de facto.
- **Options.** (1) `noreturn` unifies with nothing: a call to it is a statement ending its path; the signals become `-> noreturn` called as statements (in a page: `fn() -> View`, `use params<P>()`). (2) `noreturn` is the bottom type, fits any position.
- **Recommendation.** (1).
- **Blocks.** The row; jhonstart's signals (63, `31-a`); rakun's navigation tests.

#### lg2-n · A thunk coerced into `Node`
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(1): no thunk coercion — a deferred child is a component value, never a `fn() -> Element`** — `Node` takes an array, an `Element`, a `string` and a component value (191, 223, 504: the tree holds the unrun lambda `view()` makes); a boundary's deferred child is typed `child: @Component<Element>` (414's nodes), not `fn() -> @Component<Element>` as jhonstart writes today. Three coercions the compiler knows and nothing inferred from a lambda's shape (67); under 388 a component already is the deferred form, so a thunk is a second spelling of it. Viable: `infer.zig` `childrenCoercion` (`Children`, array, `string`, `@Renderable`) stays; measured on feat `show({ -> "x" })` is `expected Children, got function`. Changes: jhonstart's `ErrorBoundaryNode` / `NotFoundBoundaryNode` / `suspense.Boundary` `child` fields drop the thunk with 414-a's landing (B-17, 149).
- **Measured.** `show({ -> "x" })` against `fn show(children: Children)` (`Node` under 223) mismatches.
- **Options.** (1) No thunk coercion: a deferred child is a named field of the boundary. (2) `fn() -> Element` coerces into `Node`.
- **Recommendation.** (1): compiler-known coercions stay three (array, `Element`, `string`).
- **Blocks.** The row; jhonstart 30.

#### lg2-p · Cancellation
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(1): no cancellation; a losing racer and an expired timeout run to completion and their results are dropped** — the contract is the result and the order of answers (335 (2)), never the interleaving; `raceOf` / `timeout` document it. Nothing to build, nothing to get wrong (67); (2) tokens and (3) a kill path add a mechanism no front has measured a need for, and a kill path on erlang (unlinked `spawn` in `async.bp`) would need its commonJS twin (`AbortController`) to keep one answer. Viable: as built (`libs/std/src/async.bp`; measured on feat: the loser prints after the winner on commonJS, erlang and beam). Changes: none; revisited on a measured need (a handle answered by `raceOf`, one spelling on every target).
- **Measured.** `std/async` has no cancel handle; a losing racer and an expired timeout run to completion.
- **Options.** (1) None: losing work completes, result discarded, documented. (2) Explicit cancellation tokens. (3) Linked processes with a kill path on the BEAM.
- **Recommendation.** (1), in step with `lg2-b` (1).
- **Blocks.** The row; rakun 02.

#### lg2-s · Module-graph reflection
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(1): no module-graph reflection; onze-bundler keeps `importsOf`, a scan that fails loudly** — `Decl` has no `imports`, and (2) is not viable: there is no module-level `@Decl` to carry one (315: no module-level annotation). The bundler reads what the compiler already resolves when a front needs it — a `botopink` CLI output of the module graph (B-69's resolver names every module by path), never a comptime reflection over modules (216 (4)'s catalogue answers declarations, not modules). Viable: `onze/modules/onze-bundler/src/scan.bp` `importsOf`, `graph.bp` `loadModules`; measured on feat `decl.imports` is `unknown field 'imports' on type 'Decl'`. Changes: `status.md` lists `ctr-m (= lg2-s)` as closed on 9 Oct and lg2-s as open in the same section — one of the two lines goes with this answer.
- **Not viable (fable, 2026-10-12):** (2) — there is no module-level `@Decl` to carry an `imports` field (315: no module-level annotation).
- **Measured.** `decl.imports` is the checker's unknown field of `Decl`, at the read (was `badkey` at the annotation); `onze-bundler/src/graph.bp` reads imports with `importsOf`, a textual scan.
- **Options.** (1) None: `importsOf` stays a textual scan that fails loudly. (2) An `imports` field on a module-level `@Decl`.
- **Recommendation.** (1); its old argument ("in step with `lg2-k`") fell with 216.
- **Blocks.** The row; onze 68 (client bundle).

#### lg2-u · An expression-position decorator outside markup
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(1): outside markup, expression-level work is a call** — `traced(compute())`; a tag's annotation is the one expression-position decorator (278, 302, 369), and a `#[theme]` registration is a decorator on a `val` (356, 300's wait on lg2-u is over). A decorator without a `@Decl` to act on has no output place (216); (2) would run user code in the eval script for a value, two ways to write a call. Viable: as built (`val x = #[deco] 1;` is refused); a 144 row for the message: the parser reports `loop-annotation-not-generator` with the `iter` / `stream` hint for a plain expression (`parser/exprs.zig` `parseAnnotatedLoopExpr`) — a refusal of its own, naming the call form.
- **Measured.** `val x = #[deco] 1;` refused (`loop-annotation-not-generator`). Emilia front 48's markup case is answered: a tag annotation is a decorator (278, 302), and emilia reaches markup as `<h1 #[styled(…)]>` (301). Left: a decorator on an ordinary expression.
- **Options.** (1) None: outside markup, expression-level work is a call (`traced(compute())`). (2) Expression-position decorators run in the eval script (`#[traced] compute()`).
- **Recommendation.** (1).
- **Blocks.** The row (emilia 48's markup case covered by 301).

### 02-std-and-packaging

#### std-e · Test lifecycle hooks
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): no lifecycle hook; a test body calls its reset helper** — nothing implicit runs around a `test` (67), every `test` block reads whole, and 513's test unit holds `test` blocks only. (b) runs a module function the test never names and (c) adds grammar for what a call already says. Viable: as built (no `#[before]` / `beforeEach` in std, `lib-test-runner` or the libraries); the counts in the entry are stale — `resetChain()` is called 77 times across rakun (31 in rakun-web), `rkAppReset` 20, `resetTables` 13, `installDocument` 19. Changes: `language-gaps.md`'s "No test lifecycle hooks" row becomes by design.
- **Measured.** Library tests reset state by hand at the top of the body: rakun-web's `resetChain()` 77×, `rkAppReset(…)` 20×, `resetTables(…)` 14×, among others; rakun-test's `resetSingletons` / `resetContext` only in its own `context_test.bp`; jhonstart-dom-test's `installDocument(…)` 11×.
- **Options.** (a) None: a test body calls its reset helper. (b) `#[before]` / `#[after]` on a module-level fn the runner calls around every `test`. (c) `beforeEach { … }` blocks in the grammar.
- **Recommendation.** (a): nothing implicit runs around a test.
- **Blocks.** The `language-gaps.md` row "No test lifecycle hooks".

### 03-bundled-libs

#### 07-b · Does "one library, several divergent copies" also justify a package?
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): 115's "two or more libraries" stays the only test** — a duplicate inside one library goes to std when generic, else to that library's core; rakun's five cookie readers are already 196's case (`http.cookie`, consumed by rakun and onze-server). A second test would admit a package for one consumer by counting its copies (115's exception is the maintainer's, stated per case: 396 (4), 398 (3)). Viable: `repository/http/src/cookie.bp` exists; rakun's adoption is 150's step (no rakun manifest depends on `http` yet). Changes: none.
- **Measured.** rakun has four divergent `Cookie:` readers inside itself (`request_context.bp`, `csrf.bp`, `rakun-app/i18n.bp`, `session_cookie.bp`; 196, front 104). The cookie and q-value copies already qualify under 115's test (onze consumes them too).
- **Options.** (a) 115's "two or more libraries" stays the only test. (b) Add the divergence test.
- **Recommendation.** (a): a single-library duplicate goes to std or the owning library's core.
- **Blocks.** Nothing; the rule for the next candidate (front 104's `http` exists; rakun adopts it in its step 5).

#### 07-h · Bundled, or a separate shared repository
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Already answered: decision 326** — the shared libraries are repositories of their own (`botopink/<pkg>`, a submodule at `repository/<pkg>`), ordinary dependencies declared in `botopink.json` (242; a git dependency may name a `subdir`, 344), the compiler embedding std alone (`build.zig` `bundled_packages`); (a)'s "versioned with the compiler, no `dependencies` entry" is the state 326 ended. Measured on feat: `routing`, `actions`, `validation` are git dependencies of rakun, jhonstart and onze members; `http` and `log` have no dependant yet. Close by removing the entry.
- **Measured.** Wires both frameworks must agree on byte for byte ship with the compiler that embeds them; a separate repository = a git dependency, constrained by 242 (only a direct dependency importable); a member of a repository installs by `subdir` (344).
- **Options.** (a) Bundled — versioned with the compiler, no `dependencies` entry. (b) A shared `botopink/common` repository with its own cadence.
- **Recommendation.** (a).
- **Blocks.** Nothing waits; the track is cut as (a).


### 04-rakun

#### erk-b · `#[documentQuery]` under 313 (*proposed*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), with its own generator: rakun-data-nosql's `#[documentRepository]` over a `behavior` whose methods carry `#[documentQuery("…")]`** — the same shape as 313 (a `behavior`, one annotation per method recording typed meta, a generator producing the implementation and the by-type registration), the filter an ordinary string handed to the store verbatim as `#[nativeQuery]` hands SQL (`:name` placeholders matched by name against the parameters, an error at the annotation when one is unmatched); not dbcontext's `#[repository]`, whose generator emits SQL runners and refuses a method it does not know (313: "a method with neither annotation is an error"). One repository shape for every store, no second model (283); (b) an erika document target waits on a measured need; (c) is the shape 313 deleted. Viable as a library decorator (216, 311 (1): a generator on a behavior, as `#[mocks.mock]`): a new `rakun-data/src/nosql/` module (`root.bp`'s `pub mod nosql;` until B-75) — nothing of 09 exists on feat (no `DocumentStore`, no `nosql.url`; `documentQuery` is one comment in `sql/query.bp`), and dbcontext is an empty scaffold, so 09 step 4 opens after 143 lands the shape to copy. Changes: 09's README names `#[documentRepository]`; the entry's "09 step 4" is `2-libraries/150-rakun/09-rakun-data-nosql`.
- **Not viable (fable, 2026-10-12):** (a) through dbcontext's `#[repository]` — its generator emits SQL runners and refuses a method it does not know (313); dbcontext is an empty scaffold on feat; (b) — no erika document target exists.
- **Measured.** 09 step 4: `#[documentQuery("…")]` follows `#[query]`'s shape — a member of the repository type answering the template verbatim. 313 deletes that shape for SQL: a repository is a `#[repository] behavior`, its methods carrying `#[erika "…"]` or `#[nativeQuery("…")]`. erika's grammar is SQL's; a document store's filter is JSON (`$in`, `$gt`, …).
- **Options.** (a) The same shape: a document repository is a `#[repository] behavior` whose methods carry `#[documentQuery("…")]`, an ordinary string handed to the store as `#[nativeQuery]` hands SQL to the driver (`:name` placeholders matched against the parameters, escaped by `bind`). (b) erika gains a document target — the same `select … where …` lowered to the store's filter. (c) As is: a member of the type.
- **Recommendation.** (a) now — one repository shape for every store; (b) when a measured need asks for it.
- **Blocks.** 09 step 4.

#### 03r-ab · Front 09's binary-protocol stores
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), confirm — the record only** — 09 ships `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://` and `https://` with the behavior suite against all four in the gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` are recognised schemes whose boot refusal names the driver (step 5; 160: an in-process double or a `deferred.md` row, never a fallback to ETS). Refuse over a silent substitute (67); the Elasticsearch arm reaches HTTP through a core extension point, never a `rakun-data → rakun-client` edge (`ctr-w`, 185). Viable: nothing of 09 is on feat (`rakun.nosql.url` does not exist; the one URL-selected store is `rakun.datasource.url` in `rakun-data/src/datasource.bp`, whose unknown-scheme refusal — "whose scheme no arm serves — accepted: …" — and `sql_datasource_test.bp` are the pattern step 5's cells copy). Changes: none; 09 follows (a) as written.
- **Measured.** The store is selected by `rakun.nosql.url`. MongoDB, Neo4j, Cassandra, Couchbase are byte protocols (`Bytes` is 346's, not yet built) needing OTP drivers a sidecar cannot load; ETS and Mnesia are in the VM; Redis is RESP over `gen_tcp`; Elasticsearch is HTTP + JSON. 09's README is already written to (a): the former steps 4 and 7 are step 5's refusal cells plus one `deferred.md` row each — only the record is missing.
- **Options.** (a) 09 ships `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://`, `https://` with the behavior suite against all four in the gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` are recognised schemes whose boot refusal names the driver (step 5). (b) Four protocol clients in Erlang sidecars, a front each. (c) Defer 09.
- **Recommendation.** (a): never a fallback to ETS under a Mongo URL; the Elasticsearch arm without a `rakun-client` edge (`ctr-w`; 09 step 3 still goes through it). The front already follows (a).
- **Blocks.** 09 step 5 (the refusal cells).

#### 03r-ae · SAML 2.0 ACS
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(b) now: the three ACS boxes go and `saml2/` keeps 501 under a `deferred.md` row; (a) when a front measures a need** — a feature answering 501 is absent, not half-built, and nothing is marked passed that does not run (67, 160); never (c). (a)'s ~300 lines of exc-c14n over `xmerl` in a new `rakun-security/src/sidecars/rakun_saml2.erl` (as `rakun_ws.erl` uses `xmerl_scan`) is viable, erlang-only (03r-a), when 79 is staffed; 150 is partial with 79 unopened, so the honest record is the deferral. Viable: `rakun-security/src/saml2/saml2.bp` answers 501 today (`oauth2_test.bp` asserts it); no `rakun_saml2.erl` exists. Changes: 79 step 3's three boxes become one `deferred.md` row.
- **Measured.** Verifying an IdP signature needs Exclusive XML Canonicalisation, which neither OTP's `xmerl` nor std provides; `saml2/saml2.bp` answers 501.
- **Options.** (a) exc-c14n over `xmerl`'s tree in `src/sidecars/rakun_saml2.erl` (~300 lines), the three boxes closed by a fixture signed with a checked-in key. (b) Retire the SP: the three boxes go, `saml2/` keeps 501 with a `deferred.md` row. (c) Leave them open.
- **Recommendation.** (a) if 79 is staffed this milestone, else (b); never (c).
- **Blocks.** 79 step 3.

#### 03r-af · The seven unbuilt example projects
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): retire the seven; the three on disk gain a `README.md` each** — `examples/` holds `rakun`, `rakun-container`, `rakun-ssr` (none with a README), and every member's contract is asserted by its own tests (390 (5): a value nothing verifies becomes a plain test, not an example). An example that never ran is a promise the gate cannot keep (67); (b) is seven fronts for no measured reader. Viable: three files; the workspace manifest already lists `examples/*`. Changes: 73 step 3; the 1.0.10 list is a closed record.
- **Measured.** `examples/` holds `rakun`, `rakun-container`, `rakun-ssr` (gate cells); `rest-service`, `secured-api`, `blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit` never started; every member's contract asserted by its own tests.
- **Options.** (a) Retire the seven (1.0.10 example list a closed record; the three on disk gain a `README.md` each). (b) Build them, one front each, after every member front. (c) Build `rest-service` only.
- **Recommendation.** (a).
- **Blocks.** 73 step 3.

#### 03r-ak · CycloneDX validation
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a′): validate the SBOM against the checked-in CycloneDX 1.5 schema with the vendored validator 399 already fixed, in the test only — not a hand-written walker** — `release_test.bp` runs `process.run("node", ["test/tools/check-schema.js", <document>])` over `test/release/fixtures/bom-1.5.schema.json`, as `repository/validation/test/json_schema_test.bp` does with Ajv's standalone 2020 build (399: vendored under `test/tools/`, version and hash in `AGENTS.md`, never shipped); `ok` or the validator's error list fails the test; no network. One validator in the ecosystem, not a second ~120-line one implementing a subset of JSON Schema (67: a subset that passes a document the real schema would refuse is a silent pass); (b) weakens the box, (c) is a std feature nobody else needs. Viable: `rakun-cli/test/release/release_test.bp` (the SBOM test asserts `bomFormat`, `specVersion`, `components` by name today; no `fixtures/` yet), std's `io.process.run` (rakun's CLI already calls it); node on rakun's CI rows as on validation's. Changes: 81 step 3's box names 399's tool; the entry's `release_test.bp:168` is stale.
- **Not viable (fable, 2026-10-12):** (c) — std has no JSON-schema validator, and 399 fixed the vendored one for tests.
- **Measured.** The box asks for validation against a checked-in CycloneDX 1.5 schema, no network; std has no JSON-schema validator; `release_test.bp:168` asserts fields by name (`rakun-cli/test/release/` after 128).
- **Options.** (a) `release_test.bp` walks the SBOM against `test/release/fixtures/bom-1.5.schema.json`'s `required`, `type`, `enum` and local `$ref`s (~120 lines), as 81 step 3 already reads. (b) Amend the box to the field-by-field list. (c) A `json.schema` in std.
- **Recommendation.** (a).
- **Blocks.** 81 step 3.

#### 03r-al · Kafka producer transactions against the in-process broker
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): confirm — the record, and the wiring** — 83's outbox relay publishes through `withProducerTransaction` on the in-process broker (sends held, released on commit, dropped on a raise; `read_committed` sees nothing after an abort); the real-broker run is a `deferred.md` row (160). Viable: `rakun-messaging/src/reliability/transaction.bp` `withProducerTransaction` (tested in `transaction_test.bp`); the outbox (`rakun-data/src/tx/outbox.bp` `publishAfterCommit`, `relayTick(ds, publisher)`) takes a publisher function and does not go through it yet — the edge `rakun-messaging → rakun-data` exists, so the glue is rakun-messaging's publisher handed to `relayTick`, 15 step 5's first box. Changes: none to the plan; the entry's `transaction.bp:39` is `:54`.
- **Measured.** `rakun-messaging/src/reliability/transaction.bp:39` provides `withProducerTransaction(prefix, body)` (sends held, released on commit, dropped on a raise; `read_committed` reader tested in `transaction_test.bp`). 15 step 5 is already written for (a): four boxes (outbox path through `withProducerTransaction`, no outbox row; nothing visible to `read_committed` after an abort; the path in the log; one `deferred.md` row for a real broker). Only the record is missing.
- **Options.** (a) 83's outbox path publishes through `withProducerTransaction` on the in-process broker; real-broker run a `deferred.md` row. (b) Delete step 5's broker boxes. (c) Leave step 5 open until a real Kafka is in the gate.
- **Recommendation.** (a).
- **Blocks.** 15 step 5 (the record only; the front follows (a)).

#### 03r-am · Where the broker and scheduler doubles live
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(c): the doubles live in `rakun-test`, reaching the registries only through the core's hooks — no edge to rakun-messaging, nothing to measure** — `rkOnReset("broker-double", …)` (`rakun/src/runtime.bp`) and a listener-names term the core owns are the seam; `rakun-test` keeps depending on `rakun` alone and `rakun-messaging`'s tests depend on `rakun-test` (no cycle: the manifest has no test-only scope — none exists in `modules/manifest` — so (a)'s measurement would only find the cycle). 185's rule (the core defines the extension point); 19 step 3 then runs `container_test.bp` through the double. Viable: `rkOnReset` exists; no `broker_double` / `task_double` exists in rakun (`rakun-test`'s manifest already describes "the broker double" it does not hold). Changes: 19 steps 3–4 written for (c); the entry's `runtime.bp:215` is `:232`.
- **Measured.** `rakun-test` depends on `rakun` only; no `rakun-messaging/test/*.bp` imports `rakun-test` today, but 19 step 3 makes `container_test.bp` run through the double — with the double in `rakun-test` that is `rakun-test → rakun-messaging` beside `rakun-messaging (tests) → rakun-test`, a package cycle unless the loader honours test scope (not verified). `rkOnReset(name, reset)` (`rakun/src/runtime.bp:215`).
- **Options.** (a) Measure: add the edge and `container_test.bp`'s import; if `botopink test` refuses the cycle, the doubles live beside the module they double (`rakun-messaging/src/broker_double.bp` + `rakun_messaging_fixture.erl`, `rakun-scheduling/src/task_double.bp`) and `rakun-test` documents them. (b) Take the edge, assuming the rule landed. (c) The doubles in `rakun-test`, reaching the registries only through core hooks (`rkOnReset("broker-double", …)`, the listener-names term).
- **Recommendation.** (a), with (c)'s shape either way.
- **Blocks.** 19 steps 3 and 4.

#### 03r-an · RSocket's WebSocket transport after decision 187 (*proposed*, raised as R92-1)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(b): a core extension point keyed by a transport enum — `rkRegisterTransport(.WebSocket, mount)`; `rakun-websocket` plugs in** — the core declares `enum Transport { Tcp, Tls, WebSocket }` and a registry in `rakun/src/runtime.bp`; RSocket in `rakun-messaging` asks the registry for the configured transport and refuses the boot naming the member to add when none registered it; `rakun.rsocket.server.transport` reads into the enum through 299's typed config. 185 (no member-to-member edge for what is optional; `rakun-messaging` does not depend on `rakun-websocket` today and (a) would load its tree for every messaging consumer); 281 / 299: the transport is a variant, not the string the code compares. Viable: `rakun-messaging/src/rsocket/rsocket.bp` refuses `transport == "websocket"` and speaks `tcp://` only; no registry or enum exists — 92 step 2's first and third boxes build them (the registry pattern of `rkOnReset`). Changes: the entry's `rakun-rsocket/src/rsocket.bp:69` is `rakun-messaging/src/rsocket/rsocket.bp` (187).
- **Not viable (fable, 2026-10-12):** (a) — a `rakun-messaging → rakun-websocket` edge loads the websocket tree for every messaging consumer, which 185 forbids for what is optional.
- **Measured.** R92-1 mounts the transport via `rakun-websocket`'s `#[wsEndpoint]`; after 187 RSocket lives in `rakun-messaging` → the edge would load `rakun-websocket`'s tree (security, data) for every messaging consumer; today the WebSocket transport is refused at boot (`rakun-rsocket/src/rsocket.bp:69`, TCP only).
- **Options.** (a) Take the edge `rakun-messaging → rakun-websocket`. (b) The core defines a transport extension point `rakun-websocket` plugs into (185's rule), keyed by the transport enum's variant (`rkRegisterTransport(.WebSocket, …)` — 299 types the config, 281 no string). (c) Retire the WebSocket transport: R92-1's two boxes and R92-7's `ws://` / `wss://` arms deleted, TCP and TLS only, a `deferred.md` row.
- **Recommendation.** (b).
- **Blocks.** 92 step 2's first and third boxes.

#### 04-a · The tag epoch's lifetime, type and empty tag (*implemented as (a), awaits confirmation*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built — confirm** — an epoch only grows (`rkResetContext` leaves the tags table), `i64`, and `""` is refused in `rkBumpTag` / `rkTagEpoch` (`rakun: a tag is a non-empty string (rkBumpTag)`). A version counter never goes back, so no stored epoch meets a later state; `i64` has no reachable edge; an empty tag is a caller's bug, refused (67). Viable, built: `rakun/src/runtime.bp` (`rkTagEpoch` / `rkBumpTag -> i64`), `rakun_runtime.erl` (`tag_epoch/1`, `bump_tag/1` over `ets:update_counter`, `check_tag`, `reset_context/0` leaving `?TAGS`). Changes: none.
- **Measured.** 185 puts the per-tag epoch in the core (04 step 1): `rkBumpTag(tag)` bumps it, `rkTagEpoch(tag)` reads it, `rakun-client` stores the epochs of a response's tags beside it and treats a changed one as a miss (13 step 1), `rakun-cache`'s three verbs bump (12 step 3). 185 does not say whether `rkResetContext` (the test seam that drops registrations and runs every `rkOnReset` hook) clears the epochs, which integer type they are, or what an empty tag is. Every other counter in `src/runtime.bp` is `i32` (`rkBuildCount`, `rkScannedCount`); a BEAM counter does not wrap, so an `i32` past `2^31 - 1` would be a value outside its type.
- **Options.** (a) An epoch only grows: `rkResetContext` leaves the table; `i64`; `""` refused in both cells (`rakun: a tag is a non-empty string (rkBumpTag)`), located by the raise:
  ```bp
  val _b = rkBumpTag("t");        // 1
  val _r = rkResetContext();
  assert rkTagEpoch("t") == 1;    // a response stored at epoch 1 before the reset stays stale after the next bump (2)
  val _x = rkBumpTag("");         // raises: rakun: a tag is a non-empty string (rkBumpTag)
  ```
  (b) `rkResetContext` clears the epochs (a test starts at 0 for every tag); a client cache that outlives the reset can meet its stored epoch again — a stale hit:
  ```bp
  // stored beside a response: epoch 1
  val _r = rkResetContext();      // epochs back to 0
  val _b = rkBumpTag("t");        // 1 again — the stored 1 matches, the stale response is served
  ```
  (c) (a)'s lifetime, `i32` like the other counters, and `""` an ordinary tag:
  ```bp
  val e: i32 = rkBumpTag("");     // 1 — the empty tag is a tag
  ```
- **Recommendation.** (a): a version counter never goes back, so no stored epoch can match a later state; `i64` has no reachable edge; an empty tag is a caller's bug, refused (decision 67).
- **Blocks.** nothing — built as (a); (b) or (c) would be a few lines in `rakun_runtime.erl` and `runtime.bp` before 13 and 12 consume it.

### 05-jhonstart

#### 27-b · The driver's inputs: where the markup comes from, and who sets `data-jh-pending` (*proposed* ★)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built — confirm** — six functions, the driver asynchronous, `replaceDepth(nav) = nav.shared - 1`; `markPending` sets and clears `data-jh-pending` (363 (4): the client router sets it, CSS styles it); a failed markup clears the mark, replaces nothing and answers the error. Every README box asserted without a DOM, over a recording `DomOps`; (b) and (c) move a box into onze 53's browser or make the entry fetch. Viable, built: `jhonstart/modules/jhonstart-link/src/reconcile.bp` (`DomOps` with `markup`, `replaceSubtree`, `startIslands`, `mountCount`, `scrollTo`, `markPending`; `applyTransition(current, target, dom) -> @Task<@Result<Navigation, string>>`). Changes: none; `07-onze/50` step 6 supplies the six (its `onze dev` still refuses).
- **Measured** (front 27 step 1 box 1 and step 2 box 3). The README fixes
  `applyTransition(current, target, dom: DomOps) -> Navigation` and `DomOps` as four functions
  (`replaceSubtree(depth, html)`, `startIslands(depth)`, `mountCount(name)`, `scrollTo`). Two of its
  own boxes do not fit that shape: `replaceSubtree` takes the target's `html`, and neither
  `RouterState` nor the four functions supply one (the driver is pure, it cannot fetch); and step 2
  asks that "the client router sets `data-jh-pending` on the active link and clears it when the
  transition ends", asserted "over a recording `DomOps`" — no function of the four can set it.
  `scrollTo` has no stated argument. Two readings of the depth were possible too: `sharedDepth`
  answers 2 for `/blog` → `/blog/[slug]` (the keys `/`, `/blog` agree), while the README's box
  expects `replaceSubtree(1, …)`.
- **Options.**
  (a) ★ Six functions, the driver asynchronous; the depth is the deepest shared segment, whose
  CHILDREN are replaced (built, `jhonstart-link` 46 / 0 on both rows):
  ```bp
  pub type DomOps(
      markup: fn(href: string) -> @Task<@Result<string, string>>,   // route cache or fetch
      replaceSubtree: fn(depth: i32, html: string) -> void,
      startIslands: fn(depth: i32) -> void,
      mountCount: fn(name: string) -> i32,
      scrollTo: fn(depth: i32) -> void,
      markPending: fn(href: string, pending: bool) -> void,          // data-jh-pending
  )
  pub fn applyTransition(current: RouterState, target: RouterState, dom: DomOps)
      -> @Task<@Result<Navigation, string>>
  // /blog → /blog/x: pending /blog/x on | markup /blog/x | replace 1 … | start 1 | scroll 1 | pending /blog/x off
  // replaceDepth(nav) = nav.shared - 1 — never below 0, so the root layout is never replaced
  ```
  (b) The README's four functions, the markup a parameter, the pending mark the runtime's
  (`link_runtime.mjs` sets it on click, clears it on `popstate`) — step 2's box is then asserted only
  in onze 53's browser, not over a recording `DomOps`:
  ```bp
  pub fn applyTransition(current: RouterState, target: RouterState, html: string, dom: DomOps) -> Navigation
  ```
  (c) The README's four functions with `replaceSubtree(depth, href)` — the entry looks the markup up
  itself — and the pending mark inside the entry's `replaceSubtree`; the driver stays synchronous:
  ```bp
  dom.replaceSubtree(1, "/blog/x");   // the entry: fetch, mark, replace, clear
  ```
- **Recommendation.** (a): every box of the README is asserted without a DOM, a failed markup is a
  located error that clears the mark and replaces nothing, and the entry (`07-onze/50` step 6)
  supplies plain functions.
- **Blocks.** Nothing — (a) is built; `07-onze/50` step 6 supplies the six functions.

#### 67-a · Where the DOM-side forms boxes are asserted
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): `fake_dom.mjs` gains `<form>`, `<input>`, `FormData` and `submit`; the five boxes are asserted in `jhonstart-dom-test/test/forms_dom_test.bp` now, and again in onze 53's browser** — a box asserted only in a browser run no gate holds is unasserted (160, 67); (c) adds a dependency for what a few hundred lines of fake give. Viable: `jhonstart/modules/jhonstart-dom-test/src/fake_dom.mjs` (no form, no `FormData`, no `submit` today), `test/dom_test.bp` the pattern; org-6: 67 owns the file it adds, `fake_dom.mjs` edited by one front at a time. Changes: 67 steps 1–3 as written; one decision row records it (the front's header claims an answer no decision has).
- **Measured.** `fieldError` after `__jhFormState`, in-place re-render on `ok: false`, two forms' `pending`, optimistic commit / roll-back read `document` and `FormData`; `botopink test` has no DOM; `jhonstart-dom-test` (`fake_dom.mjs`, commonJS only) already serves the render's browser half. Front 67's header says "`67-a` answered", but no decision records it — still open.
- **Options.** (a) Extend `fake_dom.mjs` with `<form>`, `<input>`, `FormData`, `submit`; assert the five boxes (1.0.10's 3a, 3b, 4, 5) in `jhonstart-dom-test/test/forms_dom_test.bp` now, and again in onze 53's browser. (b) Only in onze 53's browser. (c) A real DOM library as a dev dependency.
- **Recommendation.** (a).
- **Blocks.** 67 steps 1–3 (written for (a)); onze 53's write path.

### 06-emilia

### 07-onze

#### 50-b · What `onze dev` does on a change
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): `onze dev` is `build` then `start`, looped over a file watcher — one code path, the bytes `start` serves** — a change rebuilds and restarts the node (1–3 s per edit); island state is lost either way (Fast Refresh a non-goal). (b)'s hot load and (c)'s fallback add a second path whose equivalence with `start` nothing proves (67); (b) returns when (a) measures too slow on the blog. Viable: `onze-cli/src/start.bp` (`erl -noshell -pa … -eval …`), `onze-bundler/src/rebuild.bp` (the invalidation, kept for the client half); `onze dev` returns 2 today (`main.bp`) and no watcher exists — the watcher is std's `fs` on commonJS / erlang with 506's `io.process.spawn` / `forwardSignals` for the child; 50 step 2 builds it. Changes: 50 step 6's "reloads the changed modules" becomes a restart; 53 step 6.
- **Not viable (fable, 2026-10-12):** (b) and (c) — the hot-load path is not written, and nothing proves its equivalence with the bytes `start` serves.
- **Measured.** `onze build` compiles the server to BEAM (`server/beam/`), `onze start` runs `erl -noshell -pa <outDir>/server/beam -eval …` (50-a); `onze-bundler/src/rebuild.bp` computes invalidated modules; the BEAM can `code:load_file/1`; UI registry and route table fill at module load (decision 140): a reloaded page re-registers, a new route file needs `onze_routes.bp` regenerated and the table rebuilt.
- **Options.** (a) Restart the node on every change (`build` + `start` looped over a file watcher — same bytes as `start`, 1–3 s per edit). (b) Hot-load changed modules; regenerate and reload `onze_routes` when the app tree changes. (c) (b), falling back to (a) when a convention file changed. Browser island state lost either way (Fast Refresh a non-goal, `07-onze/reference-holes.md` § 29).
- **Recommendation.** (a): one code path, the same bytes `start` serves; (b) later, if (a) measures too slow on the blog.
- **Blocks.** 50 step 2; 53 step 6.

#### 49-g · `isString` — onze's own, or std's `Json`
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(b), in `json`: `Json.isString()` beside `isObject`; onze deletes its own** — one reader per question, in the library that owns `Json` (396: the `json` library takes std's `json.bp` whole; on feat the type is still std's because 142 step 1 has not moved it, so the method lands in std under 97 and travels with the move). (c) is a diagnostic text as a type test, never. Viable: `libs/std/src/json.bp` (`isObject`'s `case` is the shape), then `onze/modules/onze/src/config.bp` `isString` and `types.bp`'s import go. Changes: a one-line follow-up in onze after the std line lands.
- **Measured.** 49 step 1 moved `onze/src/config.bp` and `types.bp` onto std's `Json` methods
  (`members`, `field`, `str`, `items`, `isObject`, `kindName`); std has no string test, so
  `config.bp` keeps one `pub fn isString(v: Json) -> bool` (a `case` over `Str`), imported by
  `types.bp`. The step's grep (`membersOf`, `strOf`, `isObject`, `kindName`) is empty; its
  Mechanism line also names `isString`.
- **Options.** (a) Keep onze's `isString` — `if (isString(v) == false) throw wrongKind(…)`.
  (b) std adds `pub fn isString(self: Self) -> bool` to `Json` (97's surface), onze deletes its
  own — `if (v.isString() == false) throw wrongKind(…)`. (c) Read through `kindName` —
  `if (v.kindName() != "a string") throw …` (a diagnostic text as a type test).
- **Recommendation.** (b): one reader per question, in std, beside `isObject`; (c) never.
- **Blocks.** nothing; under (b), a one-line follow-up in `config.bp` / `types.bp` after 97.

#### 51-a · A malformed integer in a metrics sidecar or a gradient angle
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(b): refuse — `parseMetrics(…) -> @Result<FontMetrics, string>` answers `Error("<family> <weight>: line 3: \"9x0\" is not an integer")`, and `gradientOf` answers its "not a two-stop linear gradient" value for a non-integer angle** — a malformed input is refused, never read as zero (67; 299's precedent: `rkPropInt("12abc") == 12` was reversed). Viable: `onze-og/src/metrics.bp` (`Error(_) -> 0` at three `parseInt` sites) and `svg.bp` `gradientOf`; the call sites and `og_test.bp`. Changes: 51's `og_test.bp` boxes.
- **Measured.** 51 step 1 replaced `onze-og`'s two `intOf` cells with std's `string.parseInt()`;
  the old cells answered `0` for text that is not an integer, and so do the call sites now
  (`case t.parseInt() { Ok(n) -> n.toI32(); Error(_) -> 0; }` — `metrics.bp` `parseMetrics`,
  `svg.bp` `gradientOf`). A sidecar line `ascent 9x0` reads as `ascent 0`;
  `linear-gradient(9.5deg,#a,#b)` draws at 0°. An integer past `i32` now aborts (`toI32`).
- **Options.** (a) Keep `0`. (b) Refuse: `parseMetrics(…) -> @Result<FontMetrics, string>`
  answers `Error("<family> <weight>: line 3: \"9x0\" is not an integer")`, and `gradientOf`
  answers its "not a two-stop linear gradient" value (`#(-1, "", "")`) for an angle that is not
  an integer.
- **Recommendation.** (b) — decision 67: a malformed input is refused, never read as zero.
- **Blocks.** nothing today; (b) is an `og_test.bp` change owned by 51.

### 08-bpp

#### 116-b · Are the roles checked on a project with no `.bpp` file? (*proposed* ★)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built — confirm** — the roles are checked whenever the key is present; a key that cannot be honoured is refused where it is written, before a file depends on it (67, 361 (4)). Viable, built: `compiler-cli/src/cli/libs.zig` (`if (project.bpp) checkBppRoles`), `bpp.zig` `checkPackage`, cell `bpp_html_missing` (no `.bpp` file, refused at the key). Changes: none; one decision row.
- **Measured** (front 116 step 1). 361 (4): "the key on a project with no `.bpp` accepted". Implemented:
  the key is accepted, and the roles of the package it names are still checked on every
  `build` / `check` / `run` / `test` (`compiler-cli/src/cli/bpp.zig`, called from
  `libs.loadDependencies`) — `tests/language/modules/bpp_html_missing` has no `.bpp` file and is
  refused at the key. Today `"bpp": "jhonstart"` is such a project's refusal until
  `05-jhonstart/26` step 0 moves `html` (and its `#[bpp.html]`) from `jhonstart-html` into the core.
- **Options.**
  (a) ★ The roles are checked whenever the key is present:
  ```text
  { "bpp": "jhonstart" }, no .bpp file, the core marks no #[bpp.html]
  error: "bpp" names "jhonstart", and no declaration of it carries #[bpp.html] — …   (at the key)
  ```
  (b) The roles are checked only when the project has a `.bpp` file; the key alone is never refused
  past `manifest.parse` (a dependency, a string):
  ```text
  { "bpp": "jhonstart" }, no .bpp file → builds; the first Card.bpp added → the error above
  ```
- **Recommendation.** (a): a key that cannot be honoured is refused where it is written, before a file
  depends on it (decision 67).
- **Blocks.** Nothing — (a) is built; (b) would remove one call.

#### 116-c · A decorator on a module `var` (decision 356 names a `val`) (*proposed* ★)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built — confirm** — a user decorator on a module `var` is refused at the annotation; refusing loses nothing a library needs, and (b) / (c) can be added without breaking a program (356 names a `val`: a `var` has no build value). Viable, built: `infer.zig` (the refusal), cell `val_decorator_on_var`. Changes: the cell's `docs.md` still says "question 116-c open"; one decision row.
- **Measured** (01-compiler/130 step 10 box 1). Before 356 every user decorator
  on a module binding was dropped silently. 356 makes one on a `val` run (`DeclKind.Val`). A module
  `var` is the same AST node (`ValDecl.mutable`); built: a user decorator on a `var` is refused at the
  annotation, `` `#[mark]` annotates the module `var` `count`, and a decorator runs on a `val`, never on
  a `var` `` (`tests/language/reject/val_decorator_on_var`); `#[@BeamMemory.…]` is untouched.
- **Options.**
  (a) ★ Refused at the annotation (built):
  ```bp
  #[mark]
  var count = 1;   // error at `mark`: … a decorator runs on a `val`, never on a `var`
  ```
  (b) It runs like a `val`'s, kind `DeclKind.Val`, and the `var` is catalogued:
  ```bp
  #[mark]
  var count = 1;   // mark runs; @TypeInfo.all(with: mark) answers `count`
  ```
  (c) It runs with its own kind, `DeclKind.Var`, so a decorator can tell the two apart:
  ```bp
  fn mark(comptime decl: @Decl) { if (decl.kind == DeclKind.Var) decl.fail("…"); }
  ```
- **Recommendation.** (a) until a use is measured: refusing loses nothing a library needs today, and
  (b) or (c) can be added without breaking a program.
- **Blocks.** Nothing.

### 09-cardume

#### atm-c · An atom's `T` across the server/browser seam (*proposed*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(b), with `#[clientOnly]` on the atom's declaration as the one spelling** — any `T` may be an atom; an island's read set is checked at build over its hooks (277: `use atomValue(x)` edges), and an atom an island reads whose `T` is not encodable (`#[validated]`'s `encode`, 327, or a type 294 accepts) must be declared `#[clientOnly] pub val draft = atom(…);` — 278's one function with one meaning, on a declaration as 186 puts it on a hook — else an error at the island's `use` naming the atom and `T`; no `clientAtom(…)`. Restrictive where it crosses, free elsewhere (354 (6) states the seam for contexts and leaves atoms to this question); (a) forbids a DOM handle in any atom, (c) finds out at run time. Viable only with cardume: `repository/cardume` does not exist (296, 136 step 0) and rakun / jhonstart have no request-local atoms yet; the check needs `HookUse` to carry the `use`'s declaration argument (the atom `val`) — subject to 277's `HookUse` gaining it (a 144 row if B-17 does not), else the island's read set is unknowable at build. Changes: 136 step 6 written for (b); 282 reads `#[clientOnly]` on a `val`.
- **Not viable (fable, 2026-10-12):** every option today — `repository/cardume` does not exist (136 step 0); the proposal binds 136 step 6 when it opens.
- **Measured.** The server seeds the values an island read into its payload (136 step 6); a value crossing must be encodable — after 306, a `#[validated]` type's `encode` member (`T.encode(v)`, 327; another library takes `T` only with `@typeInfo(T).meta(Validated)`), or one of the `T`s 294 accepts for a cookie (string, number, `bool`, enum, one-field record); some state is browser-only by nature (a DOM handle, a function).
- **Options.** (a) Every atom's `T` encodable, checked where the atom is declared. (b) Any `T`; an island's read set checked at build — a non-encodable atom an island reads must be declared client-only (`clientAtom(…)`, or 278's `#[clientOnly]` extended to declarations, 282). (c) Any `T`, refused only at run time.
- **Recommendation.** (b): restrictive where it matters (what crosses), free elsewhere.
- **Blocks.** 136 step 6.

#### atm-d · Which atom effects ship (*proposed*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): no atom effect in the first cut** — the store lands first; `persistLocal` / `syncSearchParam` are their own step after a measured need, one function per concern (281: a key is the declaration, never a string). Viable: nothing to build; cardume has no code yet (136). Changes: 136 step 8 deferred.
- **Not viable (fable, 2026-10-12):** (b) and (c) today — cardume has no code; the proposal is (a), nothing to build.
- **Measured.** Recoil's atom effects persist or sync an atom (localStorage, URL, a server push); none exists here.
- **Options.** (a) None in the first cut. (b) `persistLocal("cart")` only. (c) `persistLocal` and a search-param sync (`syncSearchParam("tab")`).
- **Recommendation.** (a): land the store first; effects as their own step after a measured need.
- **Blocks.** 136 step 8.

### 10-specs

#### 141-a · How a decision that retires a spelling keeps the specs from drifting (*proposed*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): the decision's commit rewrites the retired spelling in `specs/<current>/**` and adds its row to 141's `inventory.md`; `land-check.py` (484 (4), 163 s12) adds one check — a decision row that amends or replaces N is red while a spelling N retires is still written outside a closed milestone and the alias tables** — the drift is born in the decision's commit, so it is closed there; (b)'s allow-list excuses lines (67) and cannot tell a sentence that states a rule from one that names what it removes; (c) lets a front read the retired form for a milestone. Viable: no tool for (a); the check is a few lines in `scripts/land-check.py` (not written yet — 163 s12 is open), reading the row's own words for the spelling it retires (the row names both forms, 141's inventory the files). Changes: 141 step 6 and 163 s12's box.
- **Measured.** 354 retired `@Component<C, R>`; the compiler refuses it and 134's codemod rewrote the libraries (`01-compiler/134` step 6 boxes 1, 6), but about 280 spec lines in 71 files still write retired spellings (`10-specs/141-specs-sweep/inventory.md`, nine families), and 25 rows of `decisions-taken.md` still state the text an amendment replaced. Nothing ties a decision to the spec lines it retires.
- **Options.** (a) The commit that writes such a decision also rewrites the class S lines of `specs/<current>/**` that write the old form, and adds its row to 141's `inventory.md` — a duty of whoever writes the decision, no tool. (b) A meta CI check 6: a list of retired spellings and the files allowed to name them, red on any other hit — a list that excuses lines, which decision 67's spirit refuses, and a check that cannot tell an S line from an R line. (c) Nothing: 141's sweep re-runs at each milestone close.
- **Examples.** A decision retiring `Context<T>()` for `createContext(value)` (379): (a) its commit also rewrites `08-bpp/119/README.md`'s `pub val StyledContext = Context<StyledSheet>();` to `comptime createContext(StyledSheet.missing())` and adds an F1 row to `inventory.md` — `grep -rn 'Context<StyledSheet>()' specs/1.0.12-beta` is empty when it lands; (b) `scripts/retired-spellings.txt` gains `Context<[A-Z][A-Za-z]*>\(\)` with `01-compiler/134/README.md` allowed, and check 6 turns red on the 119 line until someone rewrites it — and stays green on a box that names the form as what it removes only because that file is on the list; (c) the 119 line keeps `Context<StyledSheet>()` until the milestone closes, and a front opening 119 meanwhile reads the retired form.
- **Recommendation.** (a): the drift is born in the decision's commit, so it is closed there; (b) only if (a) is measured failing.
- **Blocks.** 141 step 6.

#### Overtaken by a later decision (front 141 step 5)

Listed for the maintainer, not closed here; each keeps its own entry and id.

| Id | Overtaken by | Closing recommended |
|---|---|---|

### From the maintainer's Portuguese record (`decisoes-pendentes.md`)

#### 07-i (revision) · Whether 163's ban on repeated names in bundled packages survives 170's alias
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): still banned — a new bundled package picks a name std and the frameworks do not export** — 170's alias serves a program's own collisions, not the ecosystem's naming; one name for one thing across packages reads the same in every module (67), and `http`'s `cookie`, `actions`' `id.deriveActionId` already chose free names. Viable: nothing to build. Changes: 163's "until the toolchain line closes" becomes a standing rule; none in code.
- **Measured.** 163 bans a bundled package exporting a name std or a framework exports "until the toolchain line closes"; 170 (an import naming its module is never ambiguous; alias when both are needed) closes it.
- **Options.** (a) Still banned: a new bundled package picks a non-colliding name (`http`'s `cookie` module, `actions`' `id.deriveActionId`). (b) Ban lifted: natural names, importers alias.
- **Recommendation.** (a).
- **Blocks.** Nothing; 102, 103 and 104 already chose free names.

### 20-snap

### Ownership

#### own-a · Who owns the test runners (*proposed*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a) as 433 already cuts it: botopink-lang's runners are 144's, the meta `scripts/**` 163's** — `fronts.md` § Ownership states it ("144 holds them; the meta `scripts/**` are 163's"); a step that edits a runner names it in its commit; (b)'s 114 and (a)'s 07-residuals are inside 144 since 433 (1). Viable: the rule is in force; `fronts.md`'s open item still lists `tests/language/run.sh`, which left with 466. Changes: the open item closes; the entry's `fronts.md:55-59` is § Ownership.
- **Measured.** `scripts/{gate.sh,test-libs.sh,lib/pool.sh}` (beyond 114's budget lines), `tests/language/run.sh` (beyond 12's report), `modules/test-shard/**`, `modules/lib-test-runner/**`, the meta `scripts/**` were owned by `25-gate-perf`, 113, 115, 133, all closed (`fronts.md` § Ownership, open item). Provisional rule there (`fronts.md:55-59`) = option (c): an editing front names the carve-out in its commit; no two open fronts edit the same file. No open step edits a runner: 07-residuals step 12 "edits no runner", 114 step 5's budget lines are already 114's, 114 step 7 only runs the gate.
- **Options.** (a) `01-compiler/07-residuals`, which already holds 25's open step (the per-cell dependency compile). (b) `00-gate/114`, the gate's residue. (c) none: each front names a carve-out per commit (today's provisional rule, kept).
- **Recommendation.** (a): one owner, the front that inherited 25's open step.
- **Blocks.** Nothing today; the provisional rule (c) holds until answered.

### Contradictions that block no 00–03 step

#### ctr-l · Decision 186's third refusal against decision 202
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Drop 186's third refusal** — under 202 no page declares itself prerendered, so "a `#[serverOnly]` hook in a page that declares itself prerendered" has no case: `#[page]` refuses a `#[serverOnly]` hook inside a `#[client]` component and a `#[clientOnly]` hook outside one, and renders per request a page whose hooks reach `#[serverOnly]` (186, 202, 277). Viable: 26's context already lists the two refusals only (`2-libraries/150-rakun/26-jhonstart-router/context.md`). Changes: 186's row loses its third refusal; the entry's `README.md:58-59,182-183` is that context file.
- **Rules.** 186 refuses "a `#[serverOnly]` hook in a page that declares itself prerendered (`08-g`)". 202: "No declaration … no `pub val prerender` … no way to force". A page is `pub fn blog() -> View` reading `use cookie(sessionCookie)` (293, 294): rendered per request, no error.
- **Recommendation.** Drop 186's third refusal: under 202 no page declares itself prerendered. `05-jhonstart/26` step 8 already lists the two refusals only (`README.md:58-59,182-183`); only 186's row is pending.
- **Blocks.** Nothing in the fronts; the record.

#### ctr-v · Decision 189 (org-3) against emilia's fronts opening before 118
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Record it: a comments-only carve-out is taken by the owning front; 118 keeps the code lines** — org-3 sequences code carve-outs, and emilia's bracket lines are comments (today only in `emilia/AGENTS.md`, `README.md`, `conformance/docs.md` and a cell's comment: `attributes.bp` / `emilia.bp` hold none, and `emilia-card` no longer exists). Viable: nothing to build. Changes: 189's org-3 row gains the sentence; the entry's file lines are stale.
- **Rules.** org-3: 118's carve-outs land before the owning front opens. `06-emilia/34` step 1 and `33` step 2 open now; emilia's `[class]={…}` lines (`attributes.bp:30,32,36`, `emilia.bp:185,202`) and `emilia-card/src/main.bp:5`'s `[emilia]={…}` are comments only, reworded by those fronts.
- **Recommendation.** Record that a comments-only carve-out is taken by the owning front; 118 keeps the code lines (its own tests, `jhonstart-emilia`'s bridge test, `document-shell`). The fronts already follow it (118 § Does not touch, 34 step 1, `fronts.md:49`); only org-3's row is pending.
- **Blocks.** Nothing in the fronts; the record.

#### ctr-w · Front 09's Elasticsearch arm against decision 185
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **The Elasticsearch arm reaches HTTP through a core extension point (185), never a `rakun-data → rakun-client` edge; answered with `03r-ab`'s arm list** — `rakun-data` depends on `rakun` and `rakun-actuator` only today and no arm exists, so nothing is undone. Viable: the core's registry pattern (`rkOnReset`; `03r-an`'s transport registry), or std's `io/http` directly, as 65's relay does. Changes: 09 step 3 written against it.
- **Rules.** 185: an optional capability goes through a core extension point, "no member-to-member edge". `04-rakun/09` § Open point: the Elasticsearch arm over `rakun-client` adds a `rakun-data → rakun-client` edge every data consumer loads.
- **Recommendation.** The arm reaches HTTP via a core extension point (or `httpc` directly, as 65's relay does), not a `rakun-client` edge; answered with `03r-ab`'s arm list.
- **Blocks.** 09 step 3.


#### 119-a · Step 1's grep box against CI check 4's byte-identical hook
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): the box greps the package's own text — `{src,test,botopink.json}` of `css` and `styled`** — the hook is one text owned by the gate (CI check 4), `AGENTS.md` and `decisions-taken.md` name the neighbours by design (338's layering), and `css`'s `{src,test,botopink.json}` is empty today; `styled`'s is not (`src/styled.bp` and `test/styled_example_test.bp` name emilia's `flush()` and jhonstart's render in comments) — 150 s32 rewords those two comments (338 (2): `styled` names no jhonstart and no emilia). Viable: a grep. Changes: 119 step 1's box; the entry's "line 31" is `runner-standalone.sh:45`, and `css/AGENTS.md` does hold `emilia` (by design).
- **Rules.** 119 step 1 and its gate: `grep -rn "bpp\|jhonstart\|emilia" repository/css repository/styled` empty (338). CI check 4 (meta `AGENTS.md` § CI): `scripts/git-hooks/lib/runner-standalone.sh` byte-identical across every library repository — and its line 31 reads `# one-at-a-time gate printed. Front 115 of 1.0.11-beta measured emilia's`, so the grep finds it in `repository/css` (and will in `repository/styled`). `src/`, `test/`, `AGENTS.md` and the manifest hold none of the three names.
- **Options.** (a) The box greps the package's own text: `grep -rn "bpp\|jhonstart\|emilia" repository/css/{src,test,botopink.json} repository/styled/{src,test,botopink.json}` — empty today for `css`. (b) The shared hook's comment drops the name, in every library repository at once (check 4), a change none of 119's repositories owns.
- **Recommendation.** (a): the box measures what the package knows; the hook is one text owned by the gate.
- **Blocks.** Only ticking 119 step 1's grep box.

---

## Part 3 — Implementation choices of tracks 04–09

### 04-rakun (21)

| Id | Choice implemented | Where |
|---|---|---|
| 03r-a | Every rakun manifest is `["erlang"]`; a built erlang program ships and loads its `.erl` sidecars (ledger half moot under 153) | every member |
| 03r-c | Front 05's readers stay botopink (`config.bp`); no `rakun_config.erl`; under 299 they feed the `#[config]` records | 04 |
| 03r-e | A cookie or query component std refuses, or that would decode to a control character, stays as written (`decodeComponent`) (`ctr-p`) | 04 |
| 03r-f | A cache key is `namespace + ":" + hash.strongCacheKey(parts)` | 12 |
| 03r-g | A private-scope read with no session runs the loader, stores nothing | 12 |
| 03r-h | A twin's key is `[method, args…]`; `#[cacheEvict(name, false)]` evicts it under every `#[cacheable(name)]` reader | 12 |
| 03r-i | Redis cache provider reuses rakun-session's RESP wire (`rkSessRedis`); `revalidateTag` deletes; unreachable Redis runs the loader uncached (health DOWN) | 12 |
| 03r-j | Outside a request `revalidateTag` / `revalidatePath` legal, `updateTag` raises; global `rakun.cache.type=none` disables every cache whatever its own type | 12 |
| 03r-k | Every messaging arm runs on the in-process broker (`transport=memory`); a real address without it refuses the boot naming the driver | 15 |
| 03r-l | A listener container is named after its destination (`#[amqpListener("orders")]` → `rakun.messaging.listener.orders.*`, `#[streamListener("audit-stream", "@next")]` → `listener.audit-stream.*`); Redis defaults to ack-mode `none` (explicit `auto` / `manual` on Redis refuses the boot). Key spellings follow 299 (`ackMode` or `#[key("ack-mode")]`) | 15 · `markers.bp:90,103` · `container.bp:125` |
| 03r-m | Inside a server action `revalidatePath` / `revalidateTag` expire at once; outside, stale-then-fresh | 12 · 22 |
| 03r-n | A JSON-RPC argument is a form-encoded field list, read in order into one form | 22 |
| 03r-p | A slot belongs to the nearest layout at or above its shortest entry; a conflict is two pages of one slot at one URL | 22 |
| 03r-r | Starters name sibling members `{ "workspace": true }` | 73 |
| 03r-s | OTLP pushed as HTTP/JSON (`json:encode` in `rakun_metrics.erl`) | 17 |
| 03r-t | Front 76's keys under `rakun.management.*`, in one `management.bp` plus the `rakun_probes` sidecar | 11 |
| 03r-u | Liveness group admits only `livenessState`, `ping`, `diskSpace`; any other name refuses the boot | 11 |
| 03r-v | Typed query builder's operator is the enum `Op` (`Eq`, `Ne`, `Lt`, `Gt`, `Le`, `Ge`, `Like`): `queryOf(City.entityMeta()).where(City.columns().state, Op.Eq, "CA")`; the column as `Type.Field<City>` (308) is a separate question | 08 · `orm/query.bp:84-115` |
| 03r-w | OAuth2's explicit endpoints are `OAuth2Provider` fields (`authorizationUri`, `tokenUri`, `userinfoUri`, `jwksUri`); client credentials are `withClientToken(id, call)`, retrying once on 401 | 79 · 13 |
| 03r-x | Outbox relay claims by conditional `UPDATE` (a crashed relay's claims return via `reclaimStale`); saga and 2PC coordinators persist every transition and resume at boot (`resumeSagas`, `recover2pc`); job store claims triggers and takes over leases the same way | 15 |
| 04-a | The core's tag epoch only grows (`rkResetContext` leaves it), is `i64`, and the empty tag is refused in `rkBumpTag` / `rkTagEpoch` | 04 step 1 · `rakun/src/runtime.bp`, `rakun_runtime.erl` |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-a:** confirm the erlang-only rule; under 512 (3) the 27 member, 8 starter and 3 example manifests repeating `"targets": ["erlang"]` drop it (the workspace declares it once) — with `95-b`, 150's manifest sweep.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-c:** confirm (`rakun/src/config.bp`, no `rakun_config.erl`); 299's `#[config]` records are not built yet (`#[configurationProperties]` and `rkProp*` remain) — rakun 04 s7.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-e:** reversed by `ctr-p`: nothing stays "as written"; `decodeComponent` goes with the readers 196 deletes.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-f:** confirm (`rakun-cache/src/cache.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-g:** confirm (`cache.bp`: a private row without a session runs the loader, stores nothing).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-h:** confirm (`cache.bp` `cacheMethod`, `cacheEvictAll`, `cacheEvictKeys`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-i:** confirm; the Redis wire is still `rakun-session`'s `rkSessRedis` imported by `rakun-cache` — a member-to-member edge 185 moves into the core when a front touches it.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-j:** confirm (`cache.bp`: `rakun.cache.type=none` beats every cache; `updateTag` outside an action panics).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-k:** confirm (`rakun-messaging/src/container.bp` accepts `memory` only, refuses naming the driver).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-l:** amend under 318 (5): one listener, `#[listen(orders)]` on a method of a `#[component]`, the destination declared once and typed (`pub val orders = Destination<OrderPlaced>("order-events")`), the container named after that destination (`rakun.messaging.listener.<destination>.*`), Redis's ack mode `none` enforced, the keys read through 299's typed config (`ackMode` / `#[key("ack-mode")]`); on feat `markers.bp` still declares `#[amqpListener]`, `#[kafkaListener]`, `#[redisListener]`, `#[streamListener]`, `#[listener]` and reads `rkProp(listenerKey(…))` — 15's step for 318.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-m:** confirm (`cache.bp`'s action-phase text).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-n:** confirm (`rakun-app/src/actions.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-p:** confirm (`rakun-app/src/file_router.bp`, `slotOf`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-r:** confirm (`starters/rakun-starter/botopink.json` `"workspace": true`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-s:** confirm (`rakun_metrics.erl` `otlp_*_json`, `json:encode`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-t:** confirm (`rakun-actuator/src/management.bp`, `rakun_probes.erl`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-u:** confirm (`management.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-v:** confirm as the state on feat (`rakun-data/src/orm/query.bp` `Op`, `queryOf`, `City.columns()`); superseded in direction by 312 / 397 / 398: the typed builder leaves rakun-data when erika's `self.db.query "…"` and dbcontext land (137, 143), one query language — the `Type.Field<City>` column question (308) is moot then.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-w:** confirm (`rakun-security/src/oauth2/provider.bp`; `client_credentials.bp` `withClientToken`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-x:** confirm (`tx/outbox.bp` `reclaimStale`, `saga.bp` `resumeSagas`, `twopc.bp` `recover2pc`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 04-a:** confirm (the entry above).

### 05-jhonstart (9)

| Id | Choice implemented | Where |
|---|---|---|
| 26-a (jhonstart) | Every router cell dual-target (a `router_runtime.mjs` twin). Id shared with 01-compiler's `26-a`, decision 242 | core |
| 29-a | What 281 leaves: the island starter table is the registry's `globals.starters`, filled per route by `registerRouteStarters(pattern, load)` (a route pattern is a URL, a string under 281); a second loader for one route fails. The per-name `registerStarter(name, start)` goes — 281 builds the starter table at comptime (`@TypeInfo.all(with: client)`, 120 step 6, 53 step 7) | core · 26 step 5 (its `docs.md` row still names `registerStarter`) |
| 30-b | `RenderPlugin` is a record of async functions; `payload` answers `Array<#(key, json)>`; `chunk(id)` runs in the boundary's own process | `streaming.bp` |
| 30-c | `render` / `renderStream` / `App` in `streaming.bp`; `compose` takes the page as a thunk, runs the layouts first — `compose(chain, { -> Page() })`; today's `route: PageContext` parameter goes with 293, the page is `fn() -> View` (276) | `streaming.bp` · `render.bp:341` |
| 30-d | `Suspense(Boundary(id, fallback, child))` registers its boundary with the render via one host cell; the page returns only the tree (`-> View`) | `suspense.bp:19-34` |
| 30-e | The segment record is `UiSegment` | core |
| 30-f | `app(…, lang = "en")`: one checked language per app. The check becomes decision 180's BCP 47 subset once 105 replaces `isLangTag` with `i18n.wellFormedTag`; a per-request `PageInput.lang` from rakun-app's existing `htmlLang()` stays additive | core · `streaming.bp:197-204` · 105 |
| 30-g | Browser half asserted in the commonJS-only member `jhonstart-dom-test` over `fake_dom.mjs` | `jhonstart-dom-test` |
| 31-a | `notFound()` / `redirect(url)` raise via one host cell (`__jhRaise`); a boundary captures via `__jhCapture`; `notFoundReason()` / `redirectReason(url)` answer the reason without raising. They declare `-> string` until `noreturn` fits a value position — waits on nat-d6 and lg2-l (if nat-d6 is (a), they become `-> noreturn`) | core · `error_boundary.bp:118-187` |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 26-a (jhonstart):** confirm (`router_runtime.mjs` beside `router.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 29-a:** confirm the reduced choice (`registerRouteStarters` + `globals.starters`); the per-name `registerStarter` is still declared in `client.bp` — it goes with 281's comptime starter table (26 step 5, 120 step 6), a 149 row.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-b:** confirm (`plugin.bp` `RenderPlugin`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-c:** confirm the thunk (`render.bp` `compose(chain, route: PageContext, page: fn() -> @Component<Element>)`); the `route: PageContext` parameter is still there — it leaves with 293 (26 step 11), when the signature becomes `compose(chain, { -> Page() })`.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-d:** confirm (`suspense.bp` `Boundary`, `__jhPushBoundary`); its `child: fn() -> @Component<Element>` becomes `@Component<Element>` under 504 / lg2-n.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-e:** confirm (`routes.bp` `UiSegment`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-f:** confirm (`streaming.bp` `app(…, lang = "en")`, `isLangTag`; 105's `i18n` repository does not exist yet).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-g:** confirm (`jhonstart-dom-test`, `fake_dom.mjs`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 31-a:** amend under `nat-d6` (a) and `lg2-l`: `notFound()` / `redirect(url)` become `-> noreturn`, raising a typed `NavOutcome`; `notFoundReason()` / `redirectReason(url)` stay; `isSignalReason` goes.

### 06-emilia (9)

| Id | Choice implemented | Where |
|---|---|---|
| 05emilia-a | Filter reader is upstream's inline chain (`filterChain()`, `backdropFilterChain()`), not `var(--tw-filter)` | 42 |
| 05emilia-b | The backdrop section is `BackdropFilter` | 42 |
| 05emilia-c | `drop-shadow-none` follows upstream (`--tw-drop-shadow: ` and the reader) | 42 |
| 05emilia-d | Snap strictness is the fallback `var(--tw-scroll-snap-strictness, proximity)` | 46 |
| 05emilia-f | `--inset-shadow-*` entries drop upstream's leading `inset` | 41 |
| 05emilia-g | `space-*` / `divide-*` follow upstream's selector and reverse-aware margins | 35 · 40 |
| 05emilia-i | `--tw-*` transform variables are `@property` blocks with upstream's `properties` layer — `translate-*`, `skew-*` and `scale-*` (`--tw-scale-*`) alike | 45 · 54 · 56 |
| 05emilia-j | A selector-list modifier (`marker:`, `selection:`) is a list of one-`&` variants | 34 · 56 |
| 05emilia-k | Negative half step is `spacingNegHalf(n)`; `spacingHalf` refuses a negative `n` | 54 |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-a:** confirm (`emilia.bp` `filterChain`, `backdropFilterChain`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-b:** confirm (`BackdropFilter` in `emilia.bp`, `tokens.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-c:** confirm (`emilia.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-d:** confirm (`tokens.bp` / `emilia.bp` `--tw-scroll-snap-strictness`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-f:** confirm (`theme.bp` `--inset-shadow-*`; the leading-`inset` detail not re-verified).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-g:** confirm (`emilia.bp` `space-*` / `divide-*`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-i:** confirm (`@property` blocks in `emilia.bp`, `tokens.bp`, `output.bp`; the layer name not re-read).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-j:** confirm (`emilia.bp` `selectionVariants`, `tokens.bp` `Selection`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-k:** confirm (`spacing.bp` `spacingNegHalf`; `spacingHalf` refuses a negative `n`).

### 07-onze (9)

| Id | Choice implemented | Where |
|---|---|---|
| 49-a | The core's suites render via its own `describe*` over `snapshots.assertAs`; `onze-test`'s helpers are thin wrappers | onze core |
| 49-c | `onze.json` refuses an unknown key, a duplicate, a wrong kind, a port outside `1..65535`, a non-string `allowedRedirects` entry | `config.bp` |
| 49-e | The rakun half of the boot is the erlang member `onze-server` | 49 step 2 |
| 50-a | `onze build` stages a server main, compiles it to BEAM; `onze start` runs it with `erl` — as amended: `start` calls front 71's `bin/onze` once it exists | 50 · 71 step 2 |
| 52-a | Font-metrics table has five transcribed rows; its generator is owed | 51 step 4 |
| 53-a | The blog's sources under `src/` (`appDir: "src/app"`) | 53 |
| 68-a | A client-manifest field escapes `%`, `\|`, LF and CR only | bundler |
| 68-d | The styleMap is evaluated by a probe compiled into both packages (`emilia-hash-split`, `emilia-unevaluated`) — moot once 34 step 1 and 119 step 4 land (301: `#[styled]` tokens are comptime, the class and rule computed at build over std's `contentHash`); holds until then | bundler |
| 69-a | onze-assets keeps `AssetRoot`; onze-server converts it to rakun-web's `StaticRoot` | assets · server |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 49-a:** confirm the own `describe*`; amend the engine: the suites write through `snap`'s `assertAs` (391; `import {assertAs} from "snap"`, a git dependency in `onze/botopink.json`), not std's `snapshots`.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 49-c:** confirm (`onze/src/config.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 49-e:** confirm (`onze-server`, erlang).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 50-a:** confirm (`onze-cli/src/start.bp` runs `erl -noshell …`; `bin/onze` waits on 71).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 52-a:** confirm (`onze-assets/src/font_metrics.bp`, five rows; the generator owed).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 53-a:** confirm (`examples/blog/onze.json` `appDir: "src/app"`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 68-a:** confirm (`onze-bundler/src/manifest.bp` `escapeField`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 68-d:** confirm until 34 s1 / 119 s4 land (the probe and its snapshot still exist).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 69-a:** confirm (`onze-assets/src/assets.bp` `AssetRoot`; `onze-server/src/server.bp` `staticRootOf`).
