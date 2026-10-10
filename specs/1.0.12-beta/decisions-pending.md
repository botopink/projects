# Decisions the maintainer owes — 1.0.12-beta

**80 questions and 6 contradictions are open, and 99 implementation choices await confirmation.**

- An answer goes into [`decisions-taken.md`](./decisions-taken.md) under the next free number (kept
  there only); a lettered id is never renumbered or reused.
- Every recommendation is the most restrictive reading, no configuration bypassing it (decision 67).
- A front meeting a question it cannot answer from the code adds it here: id · title · Measured
  (observed, re-runnable) · Options · Recommendation · Blocks. *Proposed* = raised without an id.

- **Part 1** — what blocks `00-gate`, `01-compiler`, `02-std-and-packaging` and `03-bundled-libs`, by track, then
  those tracks' implementation choices awaiting confirmation.
- **Part 2** — the rest (tracks 04–10, 20, ownership, contradictions that block no 00–03 step).
- **Part 3** — the implementation choices of tracks 04–09.

The Portuguese record (`decisoes-pendentes.md`) follows the same order, with examples for Part 1 and one line per item for
Parts 2 and 3. Answered ids leave this file; `decisions-taken.md` holds the answers and the next free number.

---

## Part 1 — What blocks tracks 00–03

### What blocks now (answer first)

- Nothing blocks now: `388-a` answered by 414.

### 01-compiler

`00-gate` has no open question: 114's steps wait on no decision.

#### s35-d · An ordinary function's argument not known at build
- **Measured.** Built: 364's "refused only where `.value` reads it" holds for a decorator (an unread
  argument is accepted, `run/decorator_expr_unread_argument`); an ordinary function's `comptime`
  argument stays known at build whatever the body does (`comptime-arg-not-known`, 297's rule) — its body
  is run-time code, `n.value` the specialised value.
- **Options.** (a) As built. (b) The decorator rule for every function: `fn tag(comptime n: @Expr<i32>,
  x: i32) -> i32 { return x; }` accepts `tag(k, 1)` with `k` a local.
- **Recommendation.** (a): a run-time function's `comptime` parameter is its specialisation.
- **Blocks.** Nothing — built as (a).

#### 130-s8-a · One record type both set and added on a declaration; `meta(T)` over added values (298)
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
- **Recommendation.** (a): a key with two meanings at once is refused where it is written; (b) if a
  reader must not depend on how many decorators added a type.
- **Blocks.** Nothing — built as (a).

#### 130-s8-c · A typed meta read of a declaration a `.hooks` reader of this module annotates (298, 372)
- **Measured.** Built: decision 372 runs a decorator that reads `.hooks` after the module's bodies, and
  answers a string meta read of its declaration in the module afterwards (`answerDeferredMetaReads`). A
  typed read is an expression typed where it stands (its constructors, `@Expr` fields), so it is refused
  in that module before the reader ran: `typeinfo-meta-hooks-pending` at the read; another module reads
  it after the whole module ran.
- **Options.** (a) As built: `@typeInfo(Page).meta(Route)` in `Page`'s module, `#[route]` reading
  `.hooks`, is `typeinfo-meta-hooks-pending`. (b) Deferred like the string read: typed as `?Route` at the
  read, the value written and typed when the reader ran — a type error in an `@Expr` field then located
  in the second phase.
- **Recommendation.** (a).
- **Blocks.** Nothing — built as (a); `05-jhonstart/26`'s `#[page]` reads its meta from the entry point.

#### 130-s8-d · A generic meta record read through a catalogue entry (298)
- **Measured.** Built: `d.metaAll(T)` on a `@TypeInfo.all` entry calls a function of the reading module
  typed for `T` (`declared__metaAll__<T>`, `typed_meta.withMetaHelper`); a generic one cannot be written
  unapplied (`Check` of `Check<T>`), and a generic reader loses `T` on wasm. `d.metaAll(Check)` is
  `typeinfo-meta-type` at the argument (`reject/meta_catalogue_generic`); `@typeInfo(X).metaAll(Check)`
  reads it (`run/meta_expr_field`). The entries of one catalogue may hold `Check<Signup>` and
  `Check<Login>`.
- **Options.** (a) As built. (b) The read writes the arguments, `d.metaAll(Check<Signup>)`, and answers
  the values recorded with exactly those. (c) The read answers `Check<unknown>[]`, its fields typed
  through `unknown`.
- **Recommendation.** (a).
- **Blocks.** Nothing — built as (a).

#### s28-a · An imported source's field default that names a binding of its module (307)
- **Measured.** Built: `Type.omit(Link, .href)` over an imported `Link(…, rel: string = defaultRel())`
  copies the field without its default — the rule `registerExports` applies to an imported function's
  parameter (`infer.isClosedDefault`): a literal, `true` / `false`, `null`, a sign, an array or tuple of
  those travels, anything else does not — so `NoHref(target: null)` is the missing-field refusal at the
  call (copying it made erlc fail: `function defaultRel/0 undefined`). An enum default (`= .Blank`) is not
  closed either.
- **Options.** (a) As built: the default does not travel, the field is supplied at every construction.
  (b) The derivation is refused at the call naming the field (`derived-type-default-not-closed`).
  (c) The default travels, the deriving module calling the source module's function (an implicit import).
- **Recommendation.** (a): no implicit import, no silent value; (b) if a derived type must keep every default.
- **Blocks.** Nothing — built as (a).

#### s28-b · `Type.required` over a field with a `null` default (307)
- **Measured.** Built: `required` takes the `?` off each field and drops a `null` default with it
  (`description: ?string = null` → `description: string`, supplied at every construction); any other
  default stays.
- **Options.** (a) As built. (b) Refused at the call, naming the field. (c) The `null` default stays and
  the field is refused at the constructor when omitted.
- **Recommendation.** (a): "every `?` goes" (types.bp), a `null` cannot type a non-optional field.
- **Blocks.** Nothing — built as (a).

#### s28-c · What a derived type takes besides the fields (307)
- **Measured.** Built: the derived record holds the fields only — the source's methods, `implement`
  clauses and type-level annotations do not come (`Type.pick(Recipe, .title)` has no `Recipe` method);
  the `val`'s own annotations go on the type. Decision 307 names "the source fields' markers" only.
- **Options.** (a) As built: fields and their annotations. (b) The methods whose bodies read only kept
  fields come too. (c) The `implement` clauses come, refused when a member they need is gone.
- **Recommendation.** (a): a derived type is data; behaviour is written on it.
- **Blocks.** Nothing — built as (a).

#### s28-d · A generic record or an imported alias as the source (307)
- **Measured.** Built: refused at the argument (`derived-type-source-not-record`): a record with type
  parameters (`Type.pick(Box, .item)` — `T` unbound), and an imported type alias (its target is named in
  its own module's scope). A local alias of a record is that record.
- **Options.** (a) As built. (b) A type application as the source, `Type.pick(Box<i32>, .item)`, the
  fields substituted. (c) An imported alias followed through its module.
- **Recommendation.** (a) until a front needs (b) or (c).
- **Blocks.** Nothing — built as (a).

#### ctr-o · Decision 146 against confirmation `lem-c`
- **Rules.** 146: a function whose body reaches a host function with no binding for the target "is refused at its declaration, called or not". `lem-c` (built, to confirm): a host method with no binding "is refused where it is CALLED" — refusing the declaration was the option not taken; 311 keeps the same at the call.
- **Recommendation.** Confirm `lem-c` for a bodyless host declaration (a type declared once still compiles for a target its method lacks); state that 146 governs any bodied function, free or method, reaching one; `docs.md` says both.
- **Blocks.** `lem-c`'s confirmation.

#### 17-c · What else names a `keyed: true` var
- **Measured.** Built: only `counts.at(k)` (`ets:lookup`) and `counts = counts.insert(k, v)` (`ets:insert`); everything else (`counts[k]`, `hasKey`, `delete`, `size()`, passing it on) refused at the identifier; a keyed var is never `pub`. 1.0.5's 63: an index answers `V` and fails on an absent key; `at` answers `?V` (`null`).
- **Options.** (a) The two forms, as built, and `counts = counts.bump(k, n)` (340). (b) (a) plus `counts[k]` with 63's meaning (`ets:lookup`, `V`, failure on a missing row). (c) (b) plus `hasKey` (`ets:member`) and `delete` (`ets:delete`), each a new `std/beam` primitive.
- **Recommendation.** (a).
- **Blocks.** Nothing — the built surface stands until widened.

#### s23-j · What 375's mark counts as "cannot follow", and a host `@Component`
- **Measured.** Built (`front/ctx-async-374-375`, `infer.zig` `noteAsyncCall`, `finishHookNode`,
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

#### 04s12-a · A `@Component` method, lambda or `default fn` has no hooks node (375 (2), 04-js step 12)
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

#### s23-a · Two field names of decision 277's records (contradiction with the reserved words)
- **Measured.** 277 writes `HookNode(fn: Declared<unknown>, …)`; every keyword is reserved in every position
  (`reserved-word-as-name`: `type N(fn: string)` is refused at the field). 354 (4) asks `Decl.hooks` to carry each
  `provide` / `context` "with its object" and names no field. Built (`01-checker` step 23): `HookNode(function:
  Declared<unknown>, uses: HookUse[], calls: HookCall[])` and `HookUse(…, context: ?Declared<unknown>)`, read
  `n.function.name` and `u.context.name` (`run/decl_hooks_context` prints `App: std/context.provide(main.ThemeContext)`).
- **Options.** (a) As built: `n.function`, `u.context`. (b) `n.decl` / `u.target`: `n.decl.name`, `u.target.name`.
  (c) `n.of` / `u.object`: `n.of.name`, `u.object.name`.
- **Recommendation.** (a): the words the decisions use for them, no exception to the reserved words.
- **Blocks.** Nothing — built as (a); a rename touches `builtins.d.bp`, `comptime.zig`'s mirror, `hooks.zig` and the cells.

#### s23-c · What a reached declaration's `Declared` holds in a decorator body
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
- **Measured.** Built: `typeArgs` gives the type's name, its declaring module (`""` for a primitive or std's), and a
  record's fields as `Field(name, typeName, annotations: [])` — `params<main.BlogParams(slug: string, id: i32)>`;
  `methods` is `[]` and a field's annotations are not carried (the checker of an importing module holds the type's
  shape, not its declaration). 293 reads the field names and types.
- **Options.** (a) As built. (b) Every field's annotations and the type's methods, as `decl.fields` / `decl.methods`
  give them — `t.fields[0].annotations` lists `#[validated]` — the session publishing each module's type
  declarations.
- **Recommendation.** (b): the record is `TypeInfo`'s, and an empty list that means "not carried" is a lie.
- **Blocks.** Nothing for 293.

#### s23-g · Where `Decorator.same` is declared (371's `extend Decorator { … }` does not parse)
- **Measured.** 371 writes `extend Decorator { pub fn same(self, other: Decorator) -> bool; }` in `builtins.d.bp`. An
  `extend` is always named (`'extend' needs a name`, `parser.zig` `reportAnonImplExtendError`), `builtins.d.bp` is
  parsed by the drift test (`comptime/builtins.zig` `collectTypes`), and that test holds a builtin type's instance
  methods inside its declaration. Built (`front/decl-hooks-371-372`): a member of the behavior, mirrored in
  `comptime.zig`'s `decl_reflection_src` — `pub behavior Decorator { fn same(self: Self, other: Decorator) -> bool; }`;
  `a.decorator.same(serverOnly)` reads the same either way.
- **Options.** (a) As built: `pub behavior Decorator { fn same(self: Self, other: Decorator) -> bool; }`. (b) A named
  extension: `pub DecoratorIdentity extend Decorator { fn same(self: Self, other: Decorator) -> bool; }`, the drift
  test taught to read an `extend`'s methods into its target. (c) The parser takes an anonymous `extend Decorator { … }`
  in `builtins.d.bp` only.
- **Recommendation.** (a): no exception to the parser for one file, and the drift test already holds it.
- **Blocks.** Nothing — built as (a).

#### s23-i · A catalogue of a `.hooks` reader read in the reader's own module (372)
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
- **Measured.** Box 1 was written as `e.lookup(name)` answering a `val`'s build value. A `${…}` hole adds no word to the capture (237), so `lookup` cannot reach `tab4` in `styled "${tab4} color: red;"`, and 355's holes known at build include a literal and a `comptime`, which have no name. Built (`front/fourteen-s8`): each `Interp` part of `q.parts()` carries `known` (bool) and `value` (the build value as data, a record its fields; `null` when computed at render). `builtins.d.bp` still declares `Part.Interp(hole: Expr<string>, span)`; the part a body reads carries `code`, `known`, `value` (field reads on `Part` are not checked today), so a value of the wrong shape fails the template at run time: `styled "${whole} margin: 0;"` with `whole = styled "color: red;"` (a `Styled` where a declaration stands) is `{error,{badkey,declarations}}` at the literal, where the computed call refused it as `type mismatch: expected StyledProperty, got Styled`.
- **Options.** (a) As built: `for (q.parts()) { p -> if (p.kind == "Interp" && p.known) built = built + p.value; }`; `p.value` is `null` for a hole computed at render. (b) `q.lookup(p.code)` answers `Binding(name, kind, value)` for a hole that names a `val`: `val b = q.lookup(p.code); if (b?.value != null) …` — a literal or a `comptime` hole is never known. (c) 364's `@Expr<T>.value` on each hole: `if (p.known) built = built + p.hole.value;`, `.value` of a hole not known at build an error at the read, located — one spelling with every other `comptime` parameter, the hole typed `@Expr<T>`.
- **Recommendation.** (c) — one spelling, typed, a read of an unknown value refused (decision 67); (a) stands until `01-checker` s24 builds `@Expr.value`, and either way `Part` in `builtins.d.bp` (02's) declares what the part carries.
- **Blocks.** Nothing — built as (a).

#### 14s8-c · A hole known at build whose value raises there
- **Measured.** A hole known at build is evaluated on the comptime runtime as a `comptime` is (331). Built: a raise is refused at the hole — `pub val boom = raising "x"; pub val read = quote "${boom}";` (`raising` building `crash("x")`, which `@panic`s) is ``this hole is known at build (decision 355) and its value raised there: the comptime block raised: {error,{panic,<<"crash: x">>}}`` at `${boom}` (`reject/hole_known_at_build_raises`).
- **Options.** (a) Refused at the hole (as built). (b) The hole is computed at render (`known` false): `read` builds, and the program raises when it reads `boom`.
- **Recommendation.** (a) — fail > warn, at build rather than at run time.
- **Blocks.** Nothing — built as (a).

#### 14s8-d · A `comptime` reaching a function declared after it that holds a template call
- **Measured.** A function's template calls are expanded when its body is inferred; a `comptime` carries the expansions (`block_eval.zig` `expandedFn`). A function declared after the `comptime` has none yet. Built: refused at the `comptime` — `pub val early = comptime late();` above `fn late() -> string { return tag "b"; }` is ``the comptime reaches the template call `tag` at 14:12 in `late`, which is not expanded where the comptime runs — declare `late` before the `comptime` in this module`` (`reject/comptime_template_call_declared_after`).
- **Options.** (a) Refused, naming the call and the remedy (as built). (b) The checker infers the body of every function a `comptime` reaches before the `comptime` is evaluated, so the order of declarations does not matter.
- **Recommendation.** (a) until (b) is built by `01-checker`; (b) refuses nothing a program needs.
- **Blocks.** Nothing — built as (a).

#### 140-d · How a task adapter is spelled: 393's `wasi: .Delay` against 238's one string
- **Measured.** 393 writes `#[@External.Wasm(wasi: .Delay)]`; 238's closed vocabulary (and every std
  binding today) is one string, `#[@External.Wasm("wasi:random_f64")]`, and `builtins.d.bp` declares
  `Wasm(template: string)` (+ step 2's `host:`). Built (front 140 step 4): the string form — `"wasi:delay"`,
  `"wasi:race"`, `"wasi:race_of"`, `"wasi:spawn_all"` in `host_binding.zig`'s one list, checked by shape at
  the annotation (`run/external_wasm_task_adapter_shape`).
- **Options.** (a) ★ 238's one string: `#[@External.Wasm("wasi:delay")]`, adapter names in the list's
  snake_case. (b) 393's spelling: a labelled enum argument `#[@External.Wasm(wasi: .Delay)]` beside the
  string forms — a second spelling of the same binding, a `builtins.d.bp` change and a checker arm.
- **Recommendation.** (a) — one spelling for a binding; 393's example reads as `"wasi:delay"`.
- **Blocks.** Nothing — built as (a); `02/97` step 17 writes std's bindings in the chosen spelling.

#### 140-e · An `await` of a task inside a `@Component` body on wasm (392 (2) against 375 (3))
- **Measured.** 392 (2): "a function 375 marks asynchronous compiles to a resumable state machine". Built: a
  `-> @Task` function, a method answering one and an `async { }` block are state machines; a `@Component`
  body stays eager (as 375 (2) left wasm), because a component value has one representation for every caller:
  375 (3) keeps `await` legal on a synchronous component (a no-op) and a component reached through a function
  value (`slot.view(c)`) is awaited without the caller knowing which it is — a task's address and an
  `Element` are both one `i32` word, not told apart at run time. An `await` of a TASK in a component body
  runs the ready tasks until it settles (`$__task_block_on`) and traps, on both hosts, when the task still
  waits on the host (`run/effect_context_await`, `component_call_awaited` and the other component cells
  pass on both hosts).
- **Options.** (a) Every `@Component` on wasm is a state machine answering a task — a synchronous one
  settles when made; `await` / `use` of a component always reads a task (what commonJS did before 375's code
  half). (b) Only the components 375 marks are state machines; a call through a function value is
  asynchronous (375's conservative answer), so a synchronous component passed as a value must be wrapped in
  a settled task where it becomes a value. (c) As built: components eager, an `await` of a host-pending task
  there traps.
- **Recommendation.** (a) — one representation of `@Component<R>` on wasm, no trap; 375's mark stays a
  commonJS optimisation. Not built: it changes every component cell's lowering on wasm (front 140 step 4,
  a follow-up thread).
- **Blocks.** 140 step 4 box 1 for `@Component` bodies; nothing else (no cell awaits a host task in a
  component).

#### 140-f · A call before an `await` in the same statement, on wasm (392 (2))
- **Measured.** A state machine resumes an `await` by entering its statement again, reading back what it
  passed (conditions, `case` subjects, loop starts are kept in the frame) and skipping the statements
  before it; an operand evaluated before the `await` in its own statement runs again. Built: a call there is
  refused at the `await` — `@print(pair(label("x"), await answer(21)))` is ``the wasm backend resumes an
  `await` by entering its statement again, and a call evaluated before it in that statement would run
  twice`` at `21:29` (`run/task_await_after_call_refused_on_wasm`, `wasm.expect`); commonJS, erlang and beam
  run it. Constructors and `Ok`/`Error` (an allocation) are not counted as calls.
- **Options.** (a) ★ Refused where written (as built): `val l = label("x"); @print(pair(l, await answer(21)));`
  builds everywhere. (b) The backend binds each operand evaluated before an `await` to a frame local
  (A-normal form), so the statement runs as written: `pair(label("x"), await answer(21))` → `label("x")`
  stored, then the `await`.
- **Recommendation.** (a) now — never a call run twice, the refusal located; (b) when a program needs it.
- **Blocks.** Nothing.

### 02-std-and-packaging

#### 110-a · `testing.asserts` on wasm under the strict rule (146)
- **Measured.** A wasm program importing `testing.asserts` is refused: 4 of its 27 functions reach host cells with no wasm binding (`deepEquals → canonical`, `matches → regexMatches`, `throws`/`throwsWith → tryCatch`); uses: throwsWith ~290, throws 4, deepEquals 2, matches 1; 140 files import the module.
- **Rules.** 230: front 110 closes on "a std module wasm cannot build is a located refusal"; `02/97` step 11 offers (a) out of a wasm build or (b) restructured, a question per module. 146's last clause ("`testing.asserts` is restructured so nothing without a wasm binding is reachable from it on wasm") asks for (2)/(3); answering (1) amends it.
- **Options.** (1) ★ As is: not importable on wasm. (2) The four move to their own module; the other 23 import on wasm (changes decision 74's API). (3) The three cells gain wasm versions (a regex engine in the wasm prelude; a catchable `@panic`).
- **Recommendation.** (1) now; (2) if wasm must run asserts.
- **Blocks.** Nothing in the gate; "std compiles on wasm" (05-wasm step 5, 97 step 11).

#### 97-s13-a · `abs()` of an integer type's minimum (264, 319)
- **Measured.** `fn lo64() -> i64 { return -9223372036854775807l - 1l; }` then `@print(lo64().abs())` prints `9223372036854775808` on commonJS, erlang and beam — a value outside `i64`; `lo32().abs()` (`-2147483647 - 1`) prints `2147483648`, outside `i32`; wasm refuses the `i64` call (its integer methods are `i32`'s). `abs` is a host call (`erlang:abs`, `Math.abs` / a `BigInt` negation), not one of 264's operators, so no range check runs. `Signed` declares one `abs` for `I32` and `I64` together, so a template does not know the width.
- **Options.** (a) ★ `abs` aborts past its type as unary `-` does (`integer overflow: abs on i64`): `abs` moves from `Signed` to `I32` and `I64`, each with its own bound in its forms (`lo64().abs()` aborts on every target). (b) As is: `abs` answers the mathematical value even outside the type (`lo64().abs()` is `9223372036854775808` typed `i64`). (c) `abs` answers the unsigned type (`i64.abs() -> u64`; `lo64().abs()` is `9223372036854775808ul`).
- **Recommendation.** (a): a value outside its declared type never exists (264), and the cost is two declarations.
- **Blocks.** Nothing in the gate; the `abs` half of `02/97` step 13 (the cell `run/i64_number_methods_past_js_safe` stays off the minimum).

#### 97-s13-b · `io/clock` given an epoch past ECMAScript's time range (319)
- **Measured.** `formatIso8601`, `toCivil` and `offsetMinutes` take an `i64` epoch and their Node forms build a `Date`, whose range is ±8.64 × 10^15 ms (years −271821 … 275760). Every `BigInt` epoch (past 2^53 − 1) is outside it. `clock.toCivil(8640000000000001l).year` prints `NaN` on commonJS and `275760` on erlang; `clock.offsetMinutes(8640000000000001l)` `NaN` / `-180`; `clock.toCivil(9007199254740993l)` throws `TypeError: Cannot convert a BigInt value to a number` on commonJS; `clock.formatIso8601(8640000000000000l)` answers `+275760-09-13T00:00:00.000Z` on commonJS and aborts on erlang (`calendar:system_time_to_rfc3339` is `badarg` past year 9999). 319 asks a Node template to take `number | bigint`; what it answers for these epochs is not written.
- **Options.**
  (a) One domain on every target, refused past it: the epochs RFC 3339 writes, 0000-01-01T00:00:00Z … 9999-12-31T23:59:59.999Z (−62167219200000 … 253402300799999); the three abort past it, naming the value, on every target.
  ```bp
  clock.toCivil(253402300800000l);   // aborts on every target: clock.toCivil: 253402300800000 is outside 0000-01-01 … 9999-12-31
  ```
  (b) Every `i64` epoch answers, the same on every target: a botopink civil body (days from civil, Hinnant's algorithm) replaces `Date` and `calendar`; `formatIso8601` writes a five-digit year with a sign, as `Date` does.
  ```bp
  @print(clock.toCivil(9007199254740993l).year);   // 287396 on every target
  ```
  (c) ★ As is: each host's range and answer (`NaN` fields on commonJS, a date on erlang).
  ```bp
  @print(clock.toCivil(8640000000000001l).year);   // NaN on commonJS, 275760 on erlang
  ```
- **Recommendation.** (a): no target answers `NaN` or a date another target refuses, and RFC 3339 — the text `formatIso8601` and `parseIso8601` promise — has four-digit years.
- **Blocks.** The three templates of `02/97` step 13's `io/clock` row (the rest of the row landed: the readings are `number`s by construction, `wide` / `largestExactMillis` botopink).

#### 97-s13-c · `clock.parseDuration`'s 2^53 − 1 bound after 319
- **Measured.** `parseDuration` refuses a duration past 2^53 − 1 ms (`"9007199254740992ms"` is `… is out of range`) because "the two targets do not count alike" past it — true before 319, false after it: an `i64` is exact to 2^63 − 1 on every target, and `"9223372036854775807ms"` would answer the same digits on commonJS, erlang and beam.
- **Options.**
  (a) ★ Keep the bound: a duration is handed on as a timer delay or a JSON number, both `f64`, and past 2^53 it is no longer exact there.
  ```bp
  clock.parseDuration("9007199254740992ms");   // Error("clock.parseDuration: \"9007199254740992ms\" is out of range")
  ```
  (b) The bound is `i64`'s: the count past 2^63 − 1 / unit is out of range.
  ```bp
  clock.parseDuration("9007199254740992ms");   // Ok(9007199254740992)
  clock.parseDuration("106751991168d");        // Error(… is out of range) — past 2^63 − 1 ms
  ```
- **Recommendation.** (a): the narrower range refuses more, and no caller measured needs a duration past 285 426 years.
- **Blocks.** Nothing; `largestExactMillis`'s comment names the question.

#### 97-s13-d · `fs.stat`'s `mtime` resolution
- **Measured.** The Node form answers `mtime` in whole milliseconds (`mtimeNs` floored), the erlang form in whole seconds × 1000 (`file:read_file_info/2` with `{time, posix}` has no sub-second field): a file written at …`.734` reads `…734` on commonJS and `…000` on erlang and beam.
- **Options.**
  (a) One value on every target: the Node form floors to whole seconds too.
  ```bp
  fs.stat("five.txt")   // mtime: 1760000000000 on every target
  ```
  (b) ★ Milliseconds where the host has them (as is).
  ```bp
  fs.stat("five.txt")   // mtime: 1760000000734 on commonJS, 1760000000000 on erlang
  ```
  (c) `FileStat.mtime` becomes whole seconds (`mtimeSeconds: i64`), the unit every host gives.
  ```bp
  fs.stat("five.txt")   // mtimeSeconds: 1760000000 on every target
  ```
- **Recommendation.** (a): the same file answers the same value on every target; (c) renames a public field for the same result.
- **Blocks.** Nothing; `run/std_io_i64_canonical` prints only `mtime > 2020-01-01`.

#### 97-s16-a · Where `unicode`'s generated tables live
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
- **Recommendation.** (a): no compiler change, one module more in the registry; residual 11 makes the privacy real whichever is chosen.
- **Blocks.** Nothing (a move of one generated file and the generator's output path under (b)).

#### std-d · `io.process` signals and a TTY reader
- **Measured.** `io/process.bp` neither registers nor forwards a signal; std has no TTY line reader; `onze start` waits on `process.run` → `SIGTERM` leaves the node running; `onze create` without `--yes` has no prompt to fall back to.
- **Options.** (a) `process.onSignal(name, fn)`, `process.forwardSignals(child)`, `io.stdin.readLine()` — three host cells on two targets. (b) No std change: `onze start` execs the node (71's `bin/onze` is PID 1); `onze create` without `--yes` refused naming the flags it needs.
- **Recommendation.** (b).
- **Blocks.** onze 50 steps 4 and 7; 97 step 6 (conditional).

#### 95-f · The onze takeover — amend decision 79
- **Measured.** `repository/onze` is the orchestrator's workspace, built on tag `mocking-lib-final` in the same history and remote — not decision 79's orphan branch; nothing archived or renamed; the name resolves only to the orchestrator's members.
- **Options.** (1) Confirm the tree: a new decision amends 79 — the old library lives as the tagged history of the same repository. (2) Rewrite the remote to an orphan branch, archive the old history (every checkout re-clones).
- **Recommendation.** (1).
- **Blocks.** `02/98` step 3 ("front 95 closed as a confirmation"), written under (1).

#### nat-f3 · `files` and `workspaces` in `botopink.json` (98)
- **Measured.** `files` lists, relative to `src`, the modules a consumer may import; a library without it ships nothing (`docs/botopink-json.md:52`). `workspaces` lists members; a manifest with it is a workspace and refuses `src`, `files`, `entry`, `dependencies` (`:159-170`) — the two never share a file (`98-packaging-tail/README.md:27`). 270 relies on `files` (the prelude `src/prelude.bp` is listed there).
- **Options.** (a) Both kept — packaging, not code. (b) `files` derived from `pub` modules (an internal module marked in code — `#![internal]` has no spelling since 315), 270 reworded; `workspaces` kept. (c) Both derived.
- **Recommendation.** (a): what ships is a packaging fact, and 270 already relies on it.
- **Blocks.** 98.

#### nat-d9 · LINQ's names in erika beside std's (98)
- **Measured.** `98-packaging-tail/README.md:47-51`; `erika.bp`: `where`, `select`, `selectMany`, `orderByDescending`, `toList`; erika is eager — every operator materializes a new array (`erika.bp:5`); std has `filter`, `map`, `flatMap`, `unique` (217).
- **Options.** (a) std's names (`filter`, `map`), erika adding only what std lacks (`groupBy`, the aggregates). (b) LINQ's names — erika's identity is LINQ. (c) As is.
- **Recommendation.** none from this review: erika's purpose decides (b) is a fair reading.
- **Blocks.** 98 (erika).

### 03-bundled-libs

#### ctr-p · Confirmation `std-a` against confirmation `03r-e`
- **Rules.** `std-a`: `querystring.parse` / `parseForm` "refuse … an escape that decodes to a control character", and rakun's `splitQuery` moves onto them. `03r-e`: a cookie or query component that would decode to a control character "stays exactly as written". 196 moves rakun's cookie readers into `http`.
- **Recommendation.** Confirm `std-a`; `03r-e` lapses when rakun reads queries via `querystring` and cookies via `http`.
- **Blocks.** rakun 04's readers; 104's consumer sweep.

#### 396-a · onze-content: "a node rendered by a component of the page's own where the page asks"
- **Measured.** 142 step 3 built `element.toElement(doc: MdDoc) -> Element` (every `MdNode` to one fixed element, as the old `toElement`); 396 (3) and the step's box say a page may render a node with a component of its own, and fix no form. Components are functions of a props record (192/193), `Element`s are values.
- **Options.** (a) `toElementWith(doc, render: fn(node: MdNode, kids: Array<Element>) -> ?Element)` — one function, `null` keeps the default element, the page matches the node kinds it wants (`Heading`, `Link`, `CodeBlock`, …). (b) A record of optional per-kind functions, `Components(heading: ?fn(depth, id, kids) -> Element, link: ?fn(href, title, kids) -> Element, …)`, one field per node kind. (c) Walk `MdDoc` in the page and call `toElement` for the nodes it does not render (no hook; the tree is public).
- **Recommendation.** (a): one reading, no field per kind to keep in step with the tree; (c) needs no code and is available today.
- **Blocks.** `142` step 3's second box (only the hook; the default mapping is built).

#### 07-g · OTP release rendering
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
| 24-a | Annotation-only effect codes deleted; `effect-throw-without-fallible-channel` merges into `effect-try-without-fallible-channel`; `effect-wrapper-mismatch` only for a component whose `T` implements `@Context<B>` with `B` other than its `C`; `for-over-stream` / `for-await-expects-stream` are the renamed generator codes | `comptime/diagnostics.zig` |
| 24-b | `@Task`'s methods are `map` and `then`; no `flatMap` alias | `builtins.d.bp` |
| 24-c | `iter for` / `iter while` parse as prefixed `loop { for (…) { … }; break; }` (keyword kept in `LoopExpr.prefixedKeyword`); `iter loop :l` labels the generator scope, `iter for :l` the written `for` | parser |
| 23-b | `base64`'s four functions retired, not aliased; `encoding.base64Decode` / `base64UrlDecode` answer `@Result` | `libs/std/src/encoding.bp` |
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
| 388-d | The wasm backend refuses a module the scope lowering reached, at its first component (`the wasm backend does not lower a component yet`), until 05's lowering: every component cell is a `.wasm.expect` (32 cells; `run/decl_hooks_*` among them, which ran on wasm under 354's map) | `wat.zig` `refuseScopeLowering` · `language-gaps.md` 354-wasm |
| 388-e | A body that keeps a bare `try` runs the statements after its last `use provide` as an inner closure, whose answer (the value, or the error the `try` returns early) is the result; every other body answers `rendered(v, kids)` at each `return` | `context_lower.zig` `lowerComponentBody` · `run/component_try_in_body` |
| 389-a | A declared function whose own return is no `@Component` answering one through its type arguments (`first<T>(cards)`) is 389's "what generic code answers": an edge with `callee: null`, the node asynchronous, no synchronous mark on the call | `infer.noteHookCall` · `run/decl_hooks_dynamic_call` |

#### 02-std-and-packaging (10)

| Id | Choice implemented | Where |
|---|---|---|
| 24-g | `std/async`: started `allOf` over `@Task<@Result<T, E>>` (stops at the first `Error` in input order), `all`, `race`; unstarted `runAll`, `raceOf`, `timeout(task, millis) -> @Task<@Result<T, string>>` (`Error("timeout")`); `failed(message)` answers `Error`; `allSettled`, `settleOf`, `unwrapAll`, `attempt` removed | `libs/std/src/async.bp` |
| 01std-a | A bundled library loaded by CLI and LSP (`appendBundled`), not `expandStdImports`; compiler-core names no package but `std` | `build.zig` `bundled_packages` |
| 01std-c | `routing.pattern`'s empty pattern matches only `/`; rakun-web keeps "empty runs everywhere" at its call site (`matcherAdmits`) | `routing` |
| 01std-e | `actions.readEnvelope` refuses a `redirect` disagreeing with `n` | `actions` |
| std-a | `querystring.parse` / `parseForm` answer `@Result`, refuse a malformed escape, non-UTF-8 and a control character raw or decoded; `stringify` refuses a control character; `parse` is RFC 3986 (`+` stays), `parseForm` the form flavour (`ctr-p`) | `libs/std/src/querystring.bp` |
| std-b | `fs.exists` follows a symbolic link (dangling link is `false`) | `io/fs.bp` |
| std-c | Decision 110's folder namespace is a rewrite of the parsed program | `comptime/std_namespace.zig` |
| 95-a | Front 95 relocated `jhonstart-link` and `rakun-app` as moves with no behaviour | jhonstart · rakun |
| 95-b | `rakun-app` declares its own `"targets": ["erlang"]`, as all 36 rakun manifests do (option (b); 1.0.10's "inherits the workspace" is not what the code does) | `rakun-app` manifest |
| 95-c | `erika-test` exists | erika |

#### Choices made by the 00-gate threads and the consolidation (5)

| Id | ★ implemented | Where |
|---|---|---|
| 111-b | the beam sidecar loader is emitted only when the build binds a host function (13 snapshots changed); the erlang backend follows the same rule (`buildBindsErlangHost`) | botopink-lang `codegen/beam_asm.zig` |
| 113-a | a target `botopink test` cannot run (wasm today — it runs commonJS, erlang and beam) is `NOT RUNNABLE` and fails `test-libs`, as `fronts.md` § Gate item 3 requires | `scripts/test-libs.sh` |
| 113-b | the restriction audit matches the refusal by its text (alternative, recommended: give the refusal an id — 07-residuals) | `lib-test-runner` |
| 110-b | the count history left `tests/language/AGENTS.md` | `tests/language/AGENTS.md` |
| 112-a | `format-check`'s `TREES` holds `examples` as one entry plus `modules/manifest/tests` | `scripts/format-check.sh` |

#### 03-bundled-libs (4)

| Id | Choice implemented | Where |
|---|---|---|
| 106-b | `log.consoleSink` writes one line per record on standard output through `@print` on every target (not node's `console.error` / `console.warn`, not OTP `logger`) — the one stream a wasm program also writes; `defaultSink` keeps the host's logger | `repository/log/src/sink.bp` |
| 106-c | `log.fileSink` rotates as OTP `logger_std_h` does, written once in botopink over four cells: after a write leaves the file at `maxBytes` or more, the file becomes `<path>.0`, each archive moves one up, `<path>.<maxFiles - 1>` is deleted, `maxFiles` 0 deletes the file; a failed host call raises; rakun's total size cap stays rakun's (folded into `maxFiles`) | `repository/log/src/logfile.bp` |
| 106-d | Per-name levels: `Threshold { From(level), Off }`, `Levels(root, names)`, the longest dotted prefix set wins; an empty name, an empty segment and a name set twice are refused (an `Error` when a sink is built, a panic when resolved); groups and run-time overrides are the framework's (it rebuilds the `Levels` and installs a sink again) | `repository/log/src/levels.bp` |
| 106-e | `log.captureRuntimeReports()` observes and never handles: BEAM a primary `logger` filter on the `otp` domain that hands the event on unchanged (OTP's own handler still prints it), node `uncaughtExceptionMonitor` (node still exits; `unhandledRejection` arrives as its origin under node's default mode), records of the logger `runtime` with `report.kind` (and node's stack under `error.stack_trace`), wasm a no-op binding | `repository/log/src/reports.bp` |

#### Choices made by the bugs-sweep thread (4)

| Id | ★ implemented | Where |
|---|---|---|
| bs-a | A type's associated fn is called as a std module's fn is (`planQualifiedCall`): a short call is filled from the declared defaults, a labelled one reordered, any other count is the arity error. `fn of(x: string, y: string = "d")` — (a) ★ `Bag.of("p")` is `Bag.of("p", "d")`; (b) refuse the short call, `'of' expects 2 argument(s), got 1` (before, every count but the exact one fell to a fallback that checked nothing and filled nothing) | `infer.zig` `associatedCallReturnType` · `run/associated_fn_of_type_default` |
| bs-b | An unsigned type takes no negated literal: `val x: u32 = -1;` — (a) ★ refused at the literal, ``the literal `-1` does not fit `u32` (at least 0)``; (b) accepted, and 264's run-time check aborts at the negation (`-0` is accepted either way) | `infer.zig` `refuseIntegerOutOfRange` |
| bs-c | An `erl` that printed its break handler's banner (`BREAK: (a)bort …`) is an interrupted run even though it exits 0 (SIGINT, then EOF on stdin halts the emulator with status 0): never stored in the runtime cache — the one place the harness reads the output, and only to decide not to cache. (a) ★ the banner marks it `.interrupted`; (b) spawn `erl +Bi` (SIGINT ignored): the run completes and is genuine, but a hung run then outlives Ctrl-C until the 2-minute timeout | `codegen/runtime.zig` `classifyEnd` |
| bs-d | `scripts/check-docs.sh --lib-root <dir>` replaces the default library roots; the harness test names its own. The gate keeps the default, which hashes every sibling package whole — `repository/vscode-extension` carries a `botopink.json`, so a symbolic link in its `node_modules` makes every docs check `never stored` in the meta checkout (a cost, never a verdict). (a) ★ as is; (b) the default roots take only a package with a `src` (vscode-extension's manifest is `{ "name", "version" }`); (c) the tree hash skips `node_modules` | `scripts/check-docs.sh` · `modules/compiler-cli/tests/result_store.sh` |

#### Other tracks' choices a 00–03 step waits on

| Id | Choice implemented | Where |
|---|---|---|
| 03r-q | Locale routing lives in `rakun-app/src/i18n.bp`; no `rakun-i18n` member | 22 |

---

## Part 2 — The rest

### Priority — the botopink shape (`nat-*`)

#### nat-d · A second model of what the language has — case by case (decision 283)
No general rule (283): each case below is its own question, (a) the language's own, (b) both — the foreign one a thin layer over the native — or (c) as is.

#### nat-d6 · `throw "nav:not-found"` beside `noreturn` (53)
- **Measured.** A signal is a host-raised `nav:`-prefixed string (`contracts.md` § 5b); jhonstart's `notFound()` / `redirect()` declare `-> string`, rakun's `-> i32` (`jhonstart/src/error_boundary.bp:180-189`, `rakun-app/src/navigation.bp:47-55`); `isSignal` → `isSignalReason` by prefix; `boundaries-example.bp:89-91` (a `throw` inside `-> @Result`, an `Error` value by 118, not a raise); `server-action-example.bp:79` `val _gone = redirect(…)`.
- **Rules.** 303: an action answers `@Result<T, ActionError>` and `throw e` there is `Error(e)`; `ActionError` has `NotFound` but no redirect case — the answer must also say how an action redirects.
- **Options.** (a) `fn notFound() -> noreturn`, boundaries matching the `NavOutcome` type. (b) The string signal kept under a typed wrapper. (c) As is.
- **Recommendation.** (a). With lg2-l and lg2-h.
- **Blocks.** `05-jhonstart/26`, `07-onze/53`; lg2-l, lg2-h, 31-a.

#### nat-d7 · Lifecycle annotations beside interfaces (rakun 04)
- **Measured.** `context-lifecycle-example.bp:66,72`: `#[postConstruct]`, `#[preDestroy]`.
- **Options.** (a) `implement Lifecycle { fn start(self); fn stop(self) }`. (b) Both. (c) As is.
- **Recommendation.** (a).
- **Blocks.** rakun 04.

#### nat-d8 · A `use…` hook name under `use` (53)
- **Measured.** `new-post-form-example.bp:118`: `use useActionState("createPost", actionState(""))` — jhonstart exports no `useActionState`; jhonstart-forms' hook is `actionState(actionId: string, initial)` (`form.bp:182`).
- **Rules.** 281 already settles the argument: the action is passed as a reference (`createPost`), never a string — in the example and in `actionState`'s signature. Only the hook's name is open.
- **Options.** (a) `use actionState(createPost, initial)`; a hook named `use…` refused. (b) Both names. (c) As is.
- **Recommendation.** (a).
- **Blocks.** `07-onze/53`'s examples.

#### nat-f · Configuration in JSON — case by case (decision 284)
`botopink.json` as clean as possible, configuration allowed where it makes sense (284); `"bpp"` stays, an object since 338 (`{"default": "<package>", "style": …}`). Each case below is its own question.

#### nat-f2 · `onze.json`'s `trailingSlash`, `redirects`, `markdown`, `allowedRedirects` (124, 08-h)
- **Measured.** `onze.json` is read and validated by `loadConfig` whenever the CLI resolves the project, `onze build` included (`onze-cli/src/resolve.bp:48-50`); an unknown key is refused (49-c) without a line. Only `allowedRedirects` exists (`onze/src/config.bp:192-193`); `trailingSlash`, `redirects`, `markdown` are 124's planned keys (`124-bpp-cli/README.md:67-69`), which 08-h already writes; all four restate options onze's code types (`url_rules`, `MarkdownOptions`, `app(allowedRedirects:)`). Precedent: 299 (typed record bound from a file, errors naming file, line and expected type).
- **Options.** (a) Kept in `onze.json`, read into the typed record at build as 299 does, a wrong key or value an error at its line in the file. (b) A typed record in the app's code (`pub val config = OnzeConfig(trailingSlash: .Never, …)`), no JSON. (c) As is.
- **Recommendation.** (a) — configuration is allowed there (284); the build checks it as code would, as 299 does for rakun.
- **Blocks.** 124; 08-h; `07-onze/49`, `50`.

#### nat-f4 · The `ONZE_PUBLIC_` prefix on environment variables (53, `contracts.md`)
- **Measured.** A variable reaches client code only when its name starts with `ONZE_PUBLIC_` (Next's `NEXT_PUBLIC_`). A missing prefix is not silent: the bundler refuses at build a client module's `env.read("X")` without it, naming the variable (`env-non-public`, `onze-bundler/src/refusal.bp:13-14`; `contracts.md:440-442`). What remains is a stage fact (186) carried by a naming convention the environment must follow (`client-island-example.bp:41`).
- **Options.** (a) Kept. (b) The declaration says it — `#[publicEnv] val apiUrl = env.read("API_URL")`, its use from a `#[client]` component checked at comptime (186); a marker of its own, since `#[clientVisible]` is 278's hydration annotation; 299's `#[env("…")]` the precedent in a record. (c) A list of public variables in `onze.json`.
- **Recommendation.** (b).
- **Blocks.** `07-onze/50`, `53`; `contracts.md`.

### 01-compiler — the language

#### lg2-b · What `@Task<T>` means on the BEAM
- **Measured.** On erlang and beam a Task body runs to completion where created: two `async.delay(300, …)` created before either is awaited take ≥ 600 ms (under 600 ms on commonJS).
- **Options.** (1) A Task promises the value, nothing about when its body runs; concurrency = `std/async`'s explicit process per unstarted thunk, documented. (2) A scheduler behind `@Task` on the BEAM (a process per Task, `await` a receive). (3) `spawn` / `join` in the language.
- **Recommendation.** (1) — the restrictive reading of 1.0.10's 120.
- **Blocks.** The row; rakun 02, 23, 25, 28, 30, 60.

#### lg2-d · A decorator that reads the body it annotates
- **Measured.** `decl.body` is the checker's `unknown field 'body' on type 'Decl'`, located at the read in the decorator body (`01-checker`'s decorator-body row; it was `{error,{badkey,body}}` at the annotation); the handle carries kind, name, fields, variants, methods, return type, annotations.
- **Options.** (1) No statement access. (2) A read-only statement tree on `@Decl`. (3) A body-walking comptime API.
- **Recommendation.** (1); rakun 83's saga stays a value pairing each step with its compensation.
- **Blocks.** The row; rakun 83.

#### lg2-h · Raising and catching by type
- **Measured.** `try load(p) catch { e: NotFound -> … }` does not parse; a `@Result<T, E>`'s error is typed by `E`, read with `case` in the `catch` body; a host exception is not an `E`.
- **Options.** (1) An error is a `@Result`'s `E` (1.0.10's 121): a typed error is an enum matched with `case`. (2) A `catch` arm per type. (3) Typed host exceptions.
- **Recommendation.** (1) — the row becomes documentation of 121.
- **Blocks.** The row; rakun 07, 31, 63.

#### lg2-l · Whether `noreturn` is a bottom type
- **Measured.** `fn notFound() -> noreturn { raise("…"); }` ends the path on commonJS and erlang, but `throw notFound();` in a `@Result` body and `val s: string = notFound();` mismatch → jhonstart's `notFound()` / `redirect()` declare `-> string` (`error_boundary.bp:180-188`); front 53's example writes `val _gone = redirect(…)` (`server-action-example.bp:79`); onze's blog app calls `notFound();` as a statement. `@panic` / `@todo` are `noreturn`; a branch ending in a `noreturn` call already narrows — may be confirmed de facto.
- **Options.** (1) `noreturn` unifies with nothing: a call to it is a statement ending its path; the signals become `-> noreturn` called as statements (in a page: `fn() -> View`, `use params<P>()`). (2) `noreturn` is the bottom type, fits any position.
- **Recommendation.** (1).
- **Blocks.** The row; jhonstart's signals (63, `31-a`); rakun's navigation tests.

#### lg2-n · A thunk coerced into `Node`
- **Measured.** `show({ -> "x" })` against `fn show(children: Children)` (`Node` under 223) mismatches.
- **Options.** (1) No thunk coercion: a deferred child is a named field of the boundary. (2) `fn() -> Element` coerces into `Node`.
- **Recommendation.** (1): compiler-known coercions stay three (array, `Element`, `string`).
- **Blocks.** The row; jhonstart 30.

#### lg2-p · Cancellation
- **Measured.** `std/async` has no cancel handle; a losing racer and an expired timeout run to completion.
- **Options.** (1) None: losing work completes, result discarded, documented. (2) Explicit cancellation tokens. (3) Linked processes with a kill path on the BEAM.
- **Recommendation.** (1), in step with `lg2-b` (1).
- **Blocks.** The row; rakun 02.

#### lg2-s · Module-graph reflection
- **Measured.** `decl.imports` is the checker's unknown field of `Decl`, at the read (was `badkey` at the annotation); `onze-bundler/src/graph.bp` reads imports with `importsOf`, a textual scan.
- **Options.** (1) None: `importsOf` stays a textual scan that fails loudly. (2) An `imports` field on a module-level `@Decl`.
- **Recommendation.** (1); its old argument ("in step with `lg2-k`") fell with 216.
- **Blocks.** The row; onze 68 (client bundle).

#### lg2-u · An expression-position decorator outside markup
- **Measured.** `val x = #[deco] 1;` refused (`loop-annotation-not-generator`). Emilia front 48's markup case is answered: a tag annotation is a decorator (278, 302), and emilia reaches markup as `<h1 #[styled(…)]>` (301). Left: a decorator on an ordinary expression.
- **Options.** (1) None: outside markup, expression-level work is a call (`traced(compute())`). (2) Expression-position decorators run in the eval script (`#[traced] compute()`).
- **Recommendation.** (1).
- **Blocks.** The row (emilia 48's markup case covered by 301).

### 02-std-and-packaging

#### std-e · Test lifecycle hooks
- **Measured.** Library tests reset state by hand at the top of the body: rakun-web's `resetChain()` 77×, `rkAppReset(…)` 20×, `resetTables(…)` 14×, among others; rakun-test's `resetSingletons` / `resetContext` only in its own `context_test.bp`; jhonstart-dom-test's `installDocument(…)` 11×.
- **Options.** (a) None: a test body calls its reset helper. (b) `#[before]` / `#[after]` on a module-level fn the runner calls around every `test`. (c) `beforeEach { … }` blocks in the grammar.
- **Recommendation.** (a): nothing implicit runs around a test.
- **Blocks.** The `language-gaps.md` row "No test lifecycle hooks".

### 03-bundled-libs

#### 07-b · Does "one library, several divergent copies" also justify a package?
- **Measured.** rakun has four divergent `Cookie:` readers inside itself (`request_context.bp`, `csrf.bp`, `rakun-app/i18n.bp`, `session_cookie.bp`; 196, front 104). The cookie and q-value copies already qualify under 115's test (onze consumes them too).
- **Options.** (a) 115's "two or more libraries" stays the only test. (b) Add the divergence test.
- **Recommendation.** (a): a single-library duplicate goes to std or the owning library's core.
- **Blocks.** Nothing; the rule for the next candidate (front 104's `http` exists; rakun adopts it in its step 5).

#### 07-h · Bundled, or a separate shared repository
- **Measured.** Wires both frameworks must agree on byte for byte ship with the compiler that embeds them; a separate repository = a git dependency, constrained by 242 (only a direct dependency importable); a member of a repository installs by `subdir` (344).
- **Options.** (a) Bundled — versioned with the compiler, no `dependencies` entry. (b) A shared `botopink/common` repository with its own cadence.
- **Recommendation.** (a).
- **Blocks.** Nothing waits; the track is cut as (a).


### 04-rakun

#### 137-a · The bound parameters of `QueryContext.run` (397 (1))
- **Measured.** `erika.bp` declares `fn run<T>(self: Self<E>, sql: string, params: Array<string>) -> @Result<Array<T>, E>`; rakun-data's `SqlTemplate` binds `string[]` (`sql/template.bp`). `val ps: unknown[] = [1, "a"]` is `type mismatch: expected i32, got string` (re-run with any binary).
- **Options.** (a) `Array<string>`, each hole's text: `ctx.run("select * from users where id = $1", ["7"])`. (b) A `QueryParam` variant (`Int`, `Text`, `Bool`, `Null`) built by the hole's lowering: `ctx.run(sql, [QueryParam.Int(7)])`; the template does not know a hole's type, so every hole goes through a generic `param(v)`. (c) `unknown[]` — refused today.
- **Recommendation.** (a): the only form that types today and the one the drivers already take; (b) when a driver needs the type.
- **Blocks.** 137 step 2 (the SQL target), 143 s1 (`DbContext` implementing it).

#### 137-c · How the query learns its declared answer (312, step 3)
- **Measured.** `val n: i32 = erika "select name from cities";` is accepted: the call is typed by the template's free `T`, the expansion is checked apart and never unified with it (`infer.zig` `finishExpansion` skips a `typeVar` bound). Today the query decides: `limit 1` answers `?T`, anything else an array.
- **Options.** (a) The compiler unifies the expansion's type with the expected type: `val u: ?User = erika "select * from users"` is then `expected ?User, got Array<User>`. (b) The template reads the expected type (`q.expected()`) and fails itself: `erika: an answer ?User requires 'limit 1'`. (c) The annotation form of step 29 carries the method's declared answer, the body form stays as it is.
- **Recommendation.** (a): one rule for every template, no new template API.
- **Blocks.** 137 step 3's first box.

#### 137-d · A template call in a `type` method body and as a destructuring initializer (311, 397 (3))
- **Measured.** `type Filter(minAge: i32) { pub fn names(self: Self) -> string { return dbl "ab"; } }` with a local `pub fn dbl(comptime q: @Expr<string>) -> @Expr<string>` runs `dbl is not defined` (commonJS) / `function dbl/1 undefined` (erlang): the call is never expanded. `val #(n, total) = erika "…";` is `erika is not defined`. The same call in a top-level `fn` or `test` expands.
- **Options.** (a) A compiler fix inside `01-checker` step 29 (a template call expands wherever an expression may stand). (b) A separate compiler row; step 29's template method waits on it. (c) Leave: write the query in a function.
- **Recommendation.** (a) — `self.db.query "…"` is a call inside a type method.
- **Blocks.** 137 step 2's template method; the README's `${self.minAge}` example; 143.

#### 137-e · The restrictions of aggregates in erika's grammar (312, step 4)
- **Measured.** Built: `count` takes only `*` (`count(pop)` is a located error), `sum` takes an `i32` field (the existing `Query.sum`), `avg` an `f64` field, `min` / `max` answer `?F`; an aggregate without `group by` takes neither `order by` nor `limit` and answers one value (a tuple for several); a field beside an aggregate needs `group by` on it; with `group by` the selected fields are the group field and `order by` names it; `select *` with `group by` is refused.
- **Options.** (a) As built. (b) `count(f)` allowed (counts every row: no nulls in memory). (c) `order by` / `limit` allowed on a scalar aggregate (no effect).
- **Recommendation.** (a): the most restrictive reading; (b) and (c) add forms that mean nothing in memory.
- **Blocks.** Nothing (built); the SQL side of step 4 follows the same rules.

#### 137-f · Padding the built code of an `erika "…"` expansion (language-gaps row "Two template expansions in one module share the locations of their built code")
- **Measured.** Without padding, three `erika-test` cells (`group by …`) and two `erika-linq` cells (`select label from boxes where w = h …`) are red on erlang only: `row.w` is lowered `erlang:length(Row)` and `row.region` the same, because the lambdas of two expansions sit at the same locations of their built strings and share a loc-keyed plan. commonJS is green. With `q.build(pad + code)`, `pad` the newlines and spaces that start the code at the literal's own line and column (`q.source()`, as `html.bp` does), all 6 cells are green on both targets.
- **Options.** (a) Keep the padding in `erika.bp` (one `// LANGUAGE GAP` marker, indexed) until the compiler locates built code by its expansion. (b) Drop `group by` (and any query meeting another in a module) until then. (c) Site-unique lambda names — measured: it fixes `erika-test` and breaks `erika-linq`'s two cells.
- **Recommendation.** (a): the form the gaps file already names, removed with the row.
- **Blocks.** Nothing once (a) is kept; 137 step 4's erlang cells without it.

#### erk-b · `#[documentQuery]` under 313 (*proposed*)
- **Measured.** 09 step 4: `#[documentQuery("…")]` follows `#[query]`'s shape — a member of the repository type answering the template verbatim. 313 deletes that shape for SQL: a repository is a `#[repository] behavior`, its methods carrying `#[erika "…"]` or `#[nativeQuery("…")]`. erika's grammar is SQL's; a document store's filter is JSON (`$in`, `$gt`, …).
- **Options.** (a) The same shape: a document repository is a `#[repository] behavior` whose methods carry `#[documentQuery("…")]`, an ordinary string handed to the store as `#[nativeQuery]` hands SQL to the driver (`:name` placeholders matched against the parameters, escaped by `bind`). (b) erika gains a document target — the same `select … where …` lowered to the store's filter. (c) As is: a member of the type.
- **Recommendation.** (a) now — one repository shape for every store; (b) when a measured need asks for it.
- **Blocks.** 09 step 4.

#### 03r-ab · Front 09's binary-protocol stores
- **Measured.** The store is selected by `rakun.nosql.url`. MongoDB, Neo4j, Cassandra, Couchbase are byte protocols (`Bytes` is 346's, not yet built) needing OTP drivers a sidecar cannot load; ETS and Mnesia are in the VM; Redis is RESP over `gen_tcp`; Elasticsearch is HTTP + JSON. 09's README is already written to (a): the former steps 4 and 7 are step 5's refusal cells plus one `deferred.md` row each — only the record is missing.
- **Options.** (a) 09 ships `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://`, `https://` with the behavior suite against all four in the gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` are recognised schemes whose boot refusal names the driver (step 5). (b) Four protocol clients in Erlang sidecars, a front each. (c) Defer 09.
- **Recommendation.** (a): never a fallback to ETS under a Mongo URL; the Elasticsearch arm without a `rakun-client` edge (`ctr-w`; 09 step 3 still goes through it). The front already follows (a).
- **Blocks.** 09 step 5 (the refusal cells).

#### 03r-ae · SAML 2.0 ACS
- **Measured.** Verifying an IdP signature needs Exclusive XML Canonicalisation, which neither OTP's `xmerl` nor std provides; `saml2/saml2.bp` answers 501.
- **Options.** (a) exc-c14n over `xmerl`'s tree in `src/sidecars/rakun_saml2.erl` (~300 lines), the three boxes closed by a fixture signed with a checked-in key. (b) Retire the SP: the three boxes go, `saml2/` keeps 501 with a `deferred.md` row. (c) Leave them open.
- **Recommendation.** (a) if 79 is staffed this milestone, else (b); never (c).
- **Blocks.** 79 step 3.

#### 03r-af · The seven unbuilt example projects
- **Measured.** `examples/` holds `rakun`, `rakun-container`, `rakun-ssr` (gate cells); `rest-service`, `secured-api`, `blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit` never started; every member's contract asserted by its own tests.
- **Options.** (a) Retire the seven (1.0.10 example list a closed record; the three on disk gain a `README.md` each). (b) Build them, one front each, after every member front. (c) Build `rest-service` only.
- **Recommendation.** (a).
- **Blocks.** 73 step 3.

#### 03r-ak · CycloneDX validation
- **Measured.** The box asks for validation against a checked-in CycloneDX 1.5 schema, no network; std has no JSON-schema validator; `release_test.bp:168` asserts fields by name (`rakun-cli/test/release/` after 128).
- **Options.** (a) `release_test.bp` walks the SBOM against `test/release/fixtures/bom-1.5.schema.json`'s `required`, `type`, `enum` and local `$ref`s (~120 lines), as 81 step 3 already reads. (b) Amend the box to the field-by-field list. (c) A `json.schema` in std.
- **Recommendation.** (a).
- **Blocks.** 81 step 3.

#### 03r-al · Kafka producer transactions against the in-process broker
- **Measured.** `rakun-messaging/src/reliability/transaction.bp:39` provides `withProducerTransaction(prefix, body)` (sends held, released on commit, dropped on a raise; `read_committed` reader tested in `transaction_test.bp`). 15 step 5 is already written for (a): four boxes (outbox path through `withProducerTransaction`, no outbox row; nothing visible to `read_committed` after an abort; the path in the log; one `deferred.md` row for a real broker). Only the record is missing.
- **Options.** (a) 83's outbox path publishes through `withProducerTransaction` on the in-process broker; real-broker run a `deferred.md` row. (b) Delete step 5's broker boxes. (c) Leave step 5 open until a real Kafka is in the gate.
- **Recommendation.** (a).
- **Blocks.** 15 step 5 (the record only; the front follows (a)).

#### 03r-am · Where the broker and scheduler doubles live
- **Measured.** `rakun-test` depends on `rakun` only; no `rakun-messaging/test/*.bp` imports `rakun-test` today, but 19 step 3 makes `container_test.bp` run through the double — with the double in `rakun-test` that is `rakun-test → rakun-messaging` beside `rakun-messaging (tests) → rakun-test`, a package cycle unless the loader honours test scope (not verified). `rkOnReset(name, reset)` (`rakun/src/runtime.bp:215`).
- **Options.** (a) Measure: add the edge and `container_test.bp`'s import; if `botopink test` refuses the cycle, the doubles live beside the module they double (`rakun-messaging/src/broker_double.bp` + `rakun_messaging_fixture.erl`, `rakun-scheduling/src/task_double.bp`) and `rakun-test` documents them. (b) Take the edge, assuming the rule landed. (c) The doubles in `rakun-test`, reaching the registries only through core hooks (`rkOnReset("broker-double", …)`, the listener-names term).
- **Recommendation.** (a), with (c)'s shape either way.
- **Blocks.** 19 steps 3 and 4.

#### 03r-an · RSocket's WebSocket transport after decision 187 (*proposed*, raised as R92-1)
- **Measured.** R92-1 mounts the transport via `rakun-websocket`'s `#[wsEndpoint]`; after 187 RSocket lives in `rakun-messaging` → the edge would load `rakun-websocket`'s tree (security, data) for every messaging consumer; today the WebSocket transport is refused at boot (`rakun-rsocket/src/rsocket.bp:69`, TCP only).
- **Options.** (a) Take the edge `rakun-messaging → rakun-websocket`. (b) The core defines a transport extension point `rakun-websocket` plugs into (185's rule), keyed by the transport enum's variant (`rkRegisterTransport(.WebSocket, …)` — 299 types the config, 281 no string). (c) Retire the WebSocket transport: R92-1's two boxes and R92-7's `ws://` / `wss://` arms deleted, TCP and TLS only, a `deferred.md` row.
- **Recommendation.** (b).
- **Blocks.** 92 step 2's first and third boxes.

#### 04-a · The tag epoch's lifetime, type and empty tag (*implemented as (a), awaits confirmation*)
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
- **Measured** (front 27 step 1 box 1 and step 2 box 3, `front/jhonstart-27`). The README fixes
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
- **Measured.** `fieldError` after `__jhFormState`, in-place re-render on `ok: false`, two forms' `pending`, optimistic commit / roll-back read `document` and `FormData`; `botopink test` has no DOM; `jhonstart-dom-test` (`fake_dom.mjs`, commonJS only) already serves the render's browser half. Front 67's header says "`67-a` answered", but no decision records it — still open.
- **Options.** (a) Extend `fake_dom.mjs` with `<form>`, `<input>`, `FormData`, `submit`; assert the five boxes (1.0.10's 3a, 3b, 4, 5) in `jhonstart-dom-test/test/forms_dom_test.bp` now, and again in onze 53's browser. (b) Only in onze 53's browser. (c) A real DOM library as a dev dependency.
- **Recommendation.** (a).
- **Blocks.** 67 steps 1–3 (written for (a)); onze 53's write path.

### 06-emilia

### 07-onze

#### 50-b · What `onze dev` does on a change
- **Measured.** `onze build` compiles the server to BEAM (`server/beam/`), `onze start` runs `erl -noshell -pa <outDir>/server/beam -eval …` (50-a); `onze-bundler/src/rebuild.bp` computes invalidated modules; the BEAM can `code:load_file/1`; UI registry and route table fill at module load (decision 140): a reloaded page re-registers, a new route file needs `onze_routes.bp` regenerated and the table rebuilt.
- **Options.** (a) Restart the node on every change (`build` + `start` looped over a file watcher — same bytes as `start`, 1–3 s per edit). (b) Hot-load changed modules; regenerate and reload `onze_routes` when the app tree changes. (c) (b), falling back to (a) when a convention file changed. Browser island state lost either way (Fast Refresh a non-goal, `07-onze/reference-holes.md` § 29).
- **Recommendation.** (a): one code path, the same bytes `start` serves; (b) later, if (a) measures too slow on the blog.
- **Blocks.** 50 step 2; 53 step 6.

#### 49-g · `isString` — onze's own, or std's `Json`
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

#### 116-a · The prelude module's own `import {bpp} from "std"` (decision 361 × 270) (*proposed*)
- **Measured** (front 116 step 1, `front/decision-361`). 361 puts the prelude's marker in the prelude
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

#### 116-b · Are the roles checked on a project with no `.bpp` file? (*proposed* ★)
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
- **Measured** (`front/decision-361`, 01-compiler/130 step 10 box 1). Before 356 every user decorator
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
- **Measured.** The server seeds the values an island read into its payload (136 step 6); a value crossing must be encodable — after 306, a `#[validated]` type's `encode` member (`T.encode(v)`, 327; another library takes `T` only with `@typeInfo(T).meta(Validated)`), or one of the `T`s 294 accepts for a cookie (string, number, `bool`, enum, one-field record); some state is browser-only by nature (a DOM handle, a function).
- **Options.** (a) Every atom's `T` encodable, checked where the atom is declared. (b) Any `T`; an island's read set checked at build — a non-encodable atom an island reads must be declared client-only (`clientAtom(…)`, or 278's `#[clientOnly]` extended to declarations, 282). (c) Any `T`, refused only at run time.
- **Recommendation.** (b): restrictive where it matters (what crosses), free elsewhere.
- **Blocks.** 136 step 6.

#### atm-d · Which atom effects ship (*proposed*)
- **Measured.** Recoil's atom effects persist or sync an atom (localStorage, URL, a server push); none exists here.
- **Options.** (a) None in the first cut. (b) `persistLocal("cart")` only. (c) `persistLocal` and a search-param sync (`syncSearchParam("tab")`).
- **Recommendation.** (a): land the store first; effects as their own step after a measured need.
- **Blocks.** 136 step 8.

### 10-specs

#### 141-a · How a decision that retires a spelling keeps the specs from drifting (*proposed*)
- **Measured.** 354 retired `@Component<C, R>`; the compiler refuses it and 134's codemod rewrote the libraries (`01-compiler/134` step 6 boxes 1, 6), but about 280 spec lines in 71 files still write retired spellings (`10-specs/141-specs-sweep/inventory.md`, nine families), and 25 rows of `decisions-taken.md` still state the text an amendment replaced. Nothing ties a decision to the spec lines it retires.
- **Options.** (a) The commit that writes such a decision also rewrites the class S lines of `specs/<current>/**` that write the old form, and adds its row to 141's `inventory.md` — a duty of whoever writes the decision, no tool. (b) A meta CI check 6: a list of retired spellings and the files allowed to name them, red on any other hit — a list that excuses lines, which decision 67's spirit refuses, and a check that cannot tell an S line from an R line. (c) Nothing: 141's sweep re-runs at each milestone close.
- **Examples.** A decision retiring `Context<T>()` for `createContext(value)` (379): (a) its commit also rewrites `08-bpp/119/README.md`'s `pub val StyledContext = Context<StyledSheet>();` to `comptime createContext(StyledSheet.missing())` and adds an F1 row to `inventory.md` — `grep -rn 'Context<StyledSheet>()' specs/1.0.12-beta` is empty when it lands; (b) `scripts/retired-spellings.txt` gains `Context<[A-Z][A-Za-z]*>\(\)` with `01-compiler/134/README.md` allowed, and check 6 turns red on the 119 line until someone rewrites it — and stays green on a box that names the form as what it removes only because that file is on the list; (c) the 119 line keeps `Context<StyledSheet>()` until the milestone closes, and a front opening 119 meanwhile reads the retired form.
- **Recommendation.** (a): the drift is born in the decision's commit, so it is closed there; (b) only if (a) is measured failing.
- **Blocks.** 141 step 6.

#### Overtaken by a later decision (front 141 step 5)

Listed for the maintainer, not closed here; each keeps its own entry and id.

| Id | Overtaken by | Closing recommended |
|---|---|---|
| 24-a (confirmation, 01-compiler) — its last clause, "`effect-wrapper-mismatch` only for a component whose `T` implements `@Context<B>` with `B` other than its `C`" | 354: the base parameter and the marker `@Context<C>` went, and `effect-wrapper-mismatch` with them (`01-compiler/134` step 6 box 1) | confirm 24-a's other clauses and drop the last one as moot |

### From the maintainer's Portuguese record (`decisoes-pendentes.md`)

#### 07-i (revision) · Whether 163's ban on repeated names in bundled packages survives 170's alias
- **Measured.** 163 bans a bundled package exporting a name std or a framework exports "until the toolchain line closes"; 170 (an import naming its module is never ambiguous; alias when both are needed) closes it.
- **Options.** (a) Still banned: a new bundled package picks a non-colliding name (`http`'s `cookie` module, `actions`' `id.deriveActionId`). (b) Ban lifted: natural names, importers alias.
- **Recommendation.** (a).
- **Blocks.** Nothing; 102, 103 and 104 already chose free names.

### 20-snap

### Ownership

#### own-a · Who owns the test runners (*proposed*)
- **Measured.** `scripts/{gate.sh,test-libs.sh,lib/pool.sh}` (beyond 114's budget lines), `tests/language/run.sh` (beyond 12's report), `modules/test-shard/**`, `modules/lib-test-runner/**`, the meta `scripts/**` were owned by `25-gate-perf`, 113, 115, 133, all closed (`fronts.md` § Ownership, open item). Provisional rule there (`fronts.md:55-59`) = option (c): an editing front names the carve-out in its commit; no two open fronts edit the same file. No open step edits a runner: 07-residuals step 12 "edits no runner", 114 step 5's budget lines are already 114's, 114 step 7 only runs the gate.
- **Options.** (a) `01-compiler/07-residuals`, which already holds 25's open step (the per-cell dependency compile). (b) `00-gate/114`, the gate's residue. (c) none: each front names a carve-out per commit (today's provisional rule, kept).
- **Recommendation.** (a): one owner, the front that inherited 25's open step.
- **Blocks.** Nothing today; the provisional rule (c) holds until answered.

### Contradictions that block no 00–03 step

#### ctr-l · Decision 186's third refusal against decision 202
- **Rules.** 186 refuses "a `#[serverOnly]` hook in a page that declares itself prerendered (`08-g`)". 202: "No declaration … no `pub val prerender` … no way to force". A page is `pub fn blog() -> View` reading `use cookie(sessionCookie)` (293, 294): rendered per request, no error.
- **Recommendation.** Drop 186's third refusal: under 202 no page declares itself prerendered. `05-jhonstart/26` step 8 already lists the two refusals only (`README.md:58-59,182-183`); only 186's row is pending.
- **Blocks.** Nothing in the fronts; the record.

#### ctr-v · Decision 189 (org-3) against emilia's fronts opening before 118
- **Rules.** org-3: 118's carve-outs land before the owning front opens. `06-emilia/34` step 1 and `33` step 2 open now; emilia's `[class]={…}` lines (`attributes.bp:30,32,36`, `emilia.bp:185,202`) and `emilia-card/src/main.bp:5`'s `[emilia]={…}` are comments only, reworded by those fronts.
- **Recommendation.** Record that a comments-only carve-out is taken by the owning front; 118 keeps the code lines (its own tests, `jhonstart-emilia`'s bridge test, `document-shell`). The fronts already follow it (118 § Does not touch, 34 step 1, `fronts.md:49`); only org-3's row is pending.
- **Blocks.** Nothing in the fronts; the record.

#### ctr-w · Front 09's Elasticsearch arm against decision 185
- **Rules.** 185: an optional capability goes through a core extension point, "no member-to-member edge". `04-rakun/09` § Open point: the Elasticsearch arm over `rakun-client` adds a `rakun-data → rakun-client` edge every data consumer loads.
- **Recommendation.** The arm reaches HTTP via a core extension point (or `httpc` directly, as 65's relay does), not a `rakun-client` edge; answered with `03r-ab`'s arm list.
- **Blocks.** 09 step 3.


#### 119-a · Step 1's grep box against CI check 4's byte-identical hook
- **Rules.** 119 step 1 and its gate: `grep -rn "bpp\|jhonstart\|emilia" repository/css repository/styled` empty (338). CI check 4 (meta `AGENTS.md` § CI): `scripts/git-hooks/lib/runner-standalone.sh` byte-identical across every library repository — and its line 31 reads `# one-at-a-time gate printed. Front 115 of 1.0.11-beta measured emilia's`, so the grep finds it in `repository/css` (and will in `repository/styled`). `src/`, `test/`, `AGENTS.md` and the manifest hold none of the three names.
- **Options.** (a) The box greps the package's own text: `grep -rn "bpp\|jhonstart\|emilia" repository/css/{src,test,botopink.json} repository/styled/{src,test,botopink.json}` — empty today for `css`. (b) The shared hook's comment drops the name, in every library repository at once (check 4), a change none of 119's repositories owns.
- **Recommendation.** (a): the box measures what the package knows; the hook is one text owned by the gate.
- **Blocks.** Only ticking 119 step 1's grep box.

---

## Part 3 — Implementation choices of tracks 04–09

### 04-rakun (22)

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
