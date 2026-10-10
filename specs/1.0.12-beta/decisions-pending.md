# Decisions the maintainer owes — 1.0.12-beta

**75 questions and 8 contradictions are open, and 92 implementation choices await confirmation.**

- An answer goes into [`decisions-taken.md`](./decisions-taken.md) under the next free number (kept
  there only); a lettered id is never renumbered or reused.
- Every recommendation is the most restrictive reading, no configuration bypassing it (decision 67).
- A front meeting a question it cannot answer from the code adds it here: id · title · Measured
  (observed, re-runnable) · Options · Recommendation · Blocks. *Proposed* = raised without an id.

- **Part 1** — what blocks `00-gate`, `01-compiler`, `02-std-and-packaging` and `03-bundled-libs`, by track, then
  those tracks' implementation choices awaiting confirmation.
- **Part 2** — the rest (tracks 04–09, 20, ownership, contradictions that block no 00–03 step).
- **Part 3** — the implementation choices of tracks 04–09.

The Portuguese record (`decisoes-pendentes.md`) follows the same order, with examples for Part 1 and one line per item for
Parts 2 and 3. Answered ids leave this file; `decisions-taken.md` holds the answers and the next free number.

---

## Part 1 — What blocks tracks 00–03

### What blocks now (answer first)

Nothing open: 138-a answered (337).

### 01-compiler

`00-gate` has no open question: 114's steps wait on no decision.

#### s24-b · Example 1's `#[check]` puts defaulted parameters before `message`
- **Measured.** `01-checker/examples/decorator-arguments-280.md` example 1 declares `check<T>(comptime decl:
  @Decl<T>, comptime rule: ?fn(v: T) -> bool = null, comptime at: ?Type.Field<T> = null, comptime message: string,
  comptime code: Code = .Custom)`. Decision 244 (`01-checker` step 17) refuses a defaulted parameter followed by a
  required one at the parse, for every function (`fn-param-default-trailing-only`) — the declaration does not
  compile, so `#[check(passwordsMatch, at: .confirm, message: "…")]` and the function form `#[check(message: "…")]`
  cannot be written as the example writes them. Step 24's cells declare `message` first.
- **Options.** (a) 244 holds: `message` first — `check<T>(comptime decl: @Decl<T>, comptime message: string,
  comptime rule: ?fn(v: T) -> bool = null, comptime at: ?Type.Field<T> = null, comptime code: Code = .Custom)`,
  used `#[check("As senhas não batem", passwordsMatch, at: .confirm)]` and `#[check("A senha não pode conter o
  nome")]`; the example is rewritten. (b) A decorator may put a default before a required parameter, the required
  one then always given by label — the example compiles as written; amends 244 for decorators only. (c) `message`
  takes a default (`= ""`) — `#[check(passwordsMatch, at: .confirm)]` is a check with no text.
- **Recommendation.** (a): one parameter rule for every function (244); the example follows it.
- **Blocks.** 125 s7 (`#[check]`'s signature in `repository/validation`); the example file's text.

#### lg2-q · `@Decl`'s source location
- **Measured.** `decl.loc.file` is the checker's unknown field of `Decl`, at the read (was `badkey` at the annotation). 289 and 290 already write option (1): a route file's decorator carries the route (`#[page("blog/[slug]", paths: allPosts)]`), the page reads its segments by hook (293), takes no parameter and returns `View` (275, 276). An anonymous default's `decl.name` is the file name (289), not its path.
- **Options.** (1) None: the app-relative segment is an explicit decorator argument (`#[page("blog/[slug]")] pub fn BlogPost() -> View`). (2) A `loc` field on `@Decl` (`@src()`'s `SourceLocation`).
- **Recommendation.** (1): a decorator's output never depends on where its file sits; 289/290 are written so.
- **Blocks.** The row; rakun 22 (the `#[page("…")]` examples already follow (1)).

#### ctr-o · Decision 146 against confirmation `lem-c`
- **Rules.** 146: a function whose body reaches a host function with no binding for the target "is refused at its declaration, called or not". `lem-c` (built, to confirm): a host method with no binding "is refused where it is CALLED" — refusing the declaration was the option not taken; 311 keeps the same at the call.
- **Recommendation.** Confirm `lem-c` for a bodyless host declaration (a type declared once still compiles for a target its method lacks); state that 146 governs any bodied function, free or method, reaching one; `docs.md` says both.
- **Blocks.** `lem-c`'s confirmation.

#### 17-c · What else names a `keyed: true` var
- **Measured.** Built: only `counts.at(k)` (`ets:lookup`) and `counts = counts.insert(k, v)` (`ets:insert`); everything else (`counts[k]`, `hasKey`, `delete`, `size()`, passing it on) refused at the identifier; a keyed var is never `pub`. 1.0.5's 63: an index answers `V` and fails on an absent key; `at` answers `?V` (`null`).
- **Options.** (a) The two forms, as built, and `counts = counts.bump(k, n)` (340). (b) (a) plus `counts[k]` with 63's meaning (`ets:lookup`, `V`, failure on a missing row). (c) (b) plus `hasKey` (`ets:member`) and `delete` (`ets:delete`), each a new `std/beam` primitive.
- **Recommendation.** (a).
- **Blocks.** Nothing — the built surface stands until widened.

#### 134-g · A `@Component` function value handed to generic code (354 (8))
- **Measured.** The hidden context map (built, `comptime/context_lower.zig`) is the first parameter of every function whose type answers `@Component<R>`, and a call passes it when the checker types the call as `@Component<R>`. Generic code does not know it holds one: `items.map(Card)` (`map<U>(f: fn(T) -> U)`, `U` = `@Component<Element>`) calls `f(x)` with one argument — erlang and beam fail `badarity`, commonJS hands `Card` an `undefined` map and the item in the map's place. Code that names the type (`render: fn(props: P) -> @Component<Element>`, jhonstart's routes and layouts) is lowered right.
- **Options.** (a) Refused at compile time: a `@Component` function value (named or a lambda) passed where the parameter's declared type is not a written `fn(…) -> @Component<…>` — `items.map(Card)` is `component-value-to-generic` at `Card`; write `for (items) { i -> … Card(i) … }` or a parameter typed `fn(T) -> @Component<Element>`. (b) The value is wrapped where it is passed, closing over the map in scope there: `items.map(Card)` passes `{ x -> Card(<map at this call>, x) }` — the component sees the context of the place it was handed over, not of the place generic code calls it. (c) Nothing: such a call is undefined behaviour.
- **Recommendation.** (a) — refuse > accept (decision 67); (b) silently changes where a context is read.
- **Blocks.** 134 step 6 box 4's generic case (the named and typed cases are built).

#### 134-h · `use` as the right operand of `&&` / `||` / `??` (357 (1))
- **Measured.** 357 (1) names `if` / `else`, a `case` arm, a loop, a lambda, `try` / `catch` and an early return; it does not name the short-circuit operators, whose right operand runs on some calls only (`ready && use state(0)`, `cached ?? use load()`). Built: refused — ``use-not-top-level: `use` inside the right operand of `&&` `` at the `use` of `val n = ready && use flag();`.
- **Options.** (a) Refused (as built), 357 (2)'s "never under a condition": `val n = ready && use flag();` is `use-not-top-level`; written `val f = use flag(); val n = ready && f;`. (b) Accepted: only the listed constructs refuse — `val n = ready && use flag();` builds, and `flag` runs on the calls where `ready` holds.
- **Recommendation.** (a).
- **Blocks.** Nothing — built as (a).

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

#### s23-b · `Decorator.is(other)` — `is` is a keyword (contradiction)
- **Measured.** 277 declares `extend Decorator { pub fn is(self, other: Decorator) -> bool; }` and reads
  `a.decorator.is(serverOnly)`. `is` is a keyword: `fn is(self, …)` and `a.is(b)` do not parse (`unexpected `is``),
  nor does any keyword as a method name (`type`, `case`, `in`, `as`, `match`, `loop` measured). Separately, a
  decorator's name written in a decorator body (`serverOnly`) lowers on the comptime runtime as an unbound
  variable, so whichever form is chosen the compiler writes the name's identity there. Built: every
  `DeclAnnotation` carries `decorator` (the declaration's identity — an alias and a namespace resolved); the
  comparison is not built.
- **Options.** (a) `is` admitted as a method name after `.` and in a declaration: `if (a.decorator.is(serverOnly)) …`.
  (b) A name that is no keyword: `if (a.decorator.same(serverOnly)) …` (`extend Decorator { pub fn same(self,
  other: Decorator) -> bool; }`). (c) `==` on two `Decorator`s, no method: `if (a.decorator == serverOnly) …`.
- **Recommendation.** (b): one reserved-word rule with no exception; a method states the identity comparison.
- **Blocks.** `01-checker` step 23 box `run/decorator_is_identity`; `05-jhonstart/26` step 8 (`#[page]` / `#[client]`
  testing a hook's markers).

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

#### s23-d · A `@Component` called through a function value or a method
- **Measured.** `HookCall.callee` is `Declared<unknown>`, not optional. Built: a call whose callee names no
  declaration — a parameter (`fn Page(render: fn() -> @Component<Element>) { val r = render(); … }`), a local, a
  method (`menu.render()`) — enters no `HookCall`; a `use` over one enters with `hook: null` (277).
- **Options.** (a) As built: `Page`'s node has `calls: []`. (b) `HookCall(callee: ?Declared<unknown>, at)`, such a
  call entered with `callee: null`, reaching nothing — `Page`'s node has `calls: [HookCall(callee: null, at:
  "main:3:13")]`, so a reader sees an edge it cannot follow (a `use`'s rule). (c) Refused at build in a function whose
  list a decorator reads: `val r = render();` is `hooks-dynamic-call` at the call.
- **Recommendation.** (b): what the reader cannot see is reported, as `hook: null` is; the reader decides (277: a
  `use` with `hook: null` makes a page per-request).
- **Blocks.** Nothing — built as (a).

#### s23-e · A function whose list a decorator reads is checked before its module's decorator outputs exist
- **Measured.** Decorators run before bodies; `decl.hooks` needs the bodies of the function and of this module's
  functions it reaches. Built: when a decorator reads `.hooks` (its body or a function it reaches —
  `hooks.readsMember`), the module's imports and `val`s are inferred, then those bodies, where the decorator runs. A
  body naming what a decorator of the same module `@emit`s is refused there as an unbound name — `#[graph] fn Page()
  { return generatedTitle(); }` beside `#[gen] fn x()` emitting `generatedTitle` fails on `generatedTitle`, and
  compiles when no decorator of the module reads `.hooks`.
- **Options.** (a) As built: refused, at the name. (b) A decorator reading `.hooks` runs after the module's bodies are
  inferred (a further analysis in `comptime.zig`, its outputs spliced by one more), so the example compiles.
  (c) A decorator reading `.hooks` may only `setMeta` / `fail`: `emit`, `addMember`, `addType` refused in it
  (`decorator-hooks-output`), so it runs after the bodies with no second splice.
- **Recommendation.** (b): (a) refuses a program for the order the compiler runs in, not for what it says.
- **Blocks.** Nothing in the cells; `05-jhonstart/26` step 8 if `#[page]` emits what its page names.

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

#### 14s8-a · How a template reads a hole's build value (355; `01-compiler/14` step 8 box 1)
- **Measured.** Box 1 was written as `e.lookup(name)` answering a `val`'s build value. A `${…}` hole adds no word to the capture (237), so `lookup` cannot reach `tab4` in `styled "${tab4} color: red;"`, and 355's holes known at build include a literal and a `comptime`, which have no name. Built (`front/fourteen-s8`): each `Interp` part of `q.parts()` carries `known` (bool) and `value` (the build value as data, a record its fields; `null` when computed at render). `builtins.d.bp` still declares `Part.Interp(hole: Expr<string>, span)`; the part a body reads carries `code`, `known`, `value` (field reads on `Part` are not checked today), so a value of the wrong shape fails the template at run time: `styled "${whole} margin: 0;"` with `whole = styled "color: red;"` (a `Styled` where a declaration stands) is `{error,{badkey,declarations}}` at the literal, where the computed call refused it as `type mismatch: expected StyledProperty, got Styled`.
- **Options.** (a) As built: `for (q.parts()) { p -> if (p.kind == "Interp" && p.known) built = built + p.value; }`; `p.value` is `null` for a hole computed at render. (b) `q.lookup(p.code)` answers `Binding(name, kind, value)` for a hole that names a `val`: `val b = q.lookup(p.code); if (b?.value != null) …` — a literal or a `comptime` hole is never known. (c) 364's `@Expr<T>.value` on each hole: `if (p.known) built = built + p.hole.value;`, `.value` of a hole not known at build an error at the read, located — one spelling with every other `comptime` parameter, the hole typed `@Expr<T>`.
- **Recommendation.** (c) — one spelling, typed, a read of an unknown value refused (decision 67); (a) stands until `01-checker` s24 builds `@Expr.value`, and either way `Part` in `builtins.d.bp` (02's) declares what the part carries.
- **Blocks.** Nothing — built as (a).

#### 14s8-b · Which holes are known at build (355)
- **Measured.** Built narrowest: a string, number, `true` / `false` or `null` literal; a `comptime`; a non-`var` `val` of the same module whose initializer is known at build; a template call, already expanded, whose every argument is known at build. Computed at render: an array or tuple literal (`${[1, 2]}`), a record constructor call with literal arguments (`${Point(x: 1, y: 2)}`), a field read (`${tab4.rules}`), any other call, a parameter or a local — and, until 14 step 8's open box, a `val` another module exports (`import {tab4} from "tokens"; styled "${tab4}"`), the same CSS either way.
- **Options.** (a) As built: `styled "${tab4} color: red;"` is a constant, `styled "${[a, b].join(" ")};"` is computed. (b) (a) plus array and tuple literals and constructor calls whose elements are known at build: `styled "grid-template-areas: ${areas};"` with `pub val areas = ["a", "b"].join(" ");` is still computed (a call), `pub val p = Pad(n: 4);` read by a template is known. (c) (b) plus any call to a function whose arguments are known at build, run at build.
- **Recommendation.** (a) — 355 names literals, `comptime` values and `val`s; (c) runs user code at build where no `comptime` says so (364 (3)).
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

#### 140-a · What a pending `@Task` is on wasm (front 140 step 4)
- **Measured.** wasm lowers `@Task<T>` as `T`: `await` is identity and `async { … }` runs its block where it is written (`wat.zig`, `asyncBlock`, "the eager `@Task`"); erlang's `race` answers the head of the list (`hd(__Fs)`), its `raceOf` one process per thunk. 334 (4) asks `@Task` on `wasi` to "run to completion when awaited, blocking on its pollable" and `race` to answer "the first pollable ready"; with `@Task<T>` = `T` there is no pollable to wait on, and `delay` would block where it is called. 335 (2) makes results the contract. A body that awaits inside (`async { await delay(30, ()); "a" }`) cannot be suspended on a single-threaded run-to-completion host.
- **Options.** (1) A host-made task (`delay`, `fetch`) is a box `{pollable, value}`, every other task stays eager; `await` blocks on the pollable; `race` polls the boxes and answers the first ready, an eager one being ready. `race([delay(30, "a"), delay(10, "b")])` is `"b"` on the four targets; `raceOf([{ -> async { await delay(30, ()); "a" } }, { -> delay(10, "b") }])` is `"a"` on wasm (the first thunk blocks 30 ms) and `"b"` on node. (2) Every `@Task` is lazy — a thunk plus an optional pollable, run when awaited; `async { }` runs at its `await`; `race` runs operands in order until one is a pending pollable. Same divergence for a body that awaits inside. (3) (1), and on wasm `race` / `raceOf` take host-made tasks only: an operand that runs botopink code first (`raceOf` itself, a `race` over an `async` block) is `std-unsupported-on-target … on host 'wasi'` at the call — `race([delay(30, "a"), delay(10, "b")])` builds, `raceOf([…])` does not.
- **Recommendation.** (3) — a program whose answer could differ between hosts does not build (335 (2), decision 67).
- **Blocks.** Front 140 steps 4 and 5 (`run/wasm_host_async`), the JSPI half of step 6; `02/97` step 17 (`async`'s wasm bindings).

#### 140-b · How std binds a task-typed host function on wasm
- **Measured.** Decision 238's `wasi:` adapters take numeric slots only (`host_binding.zig` `Slot`: `i32`, `i64`, `f32`, `f64`, `bool`); `async.delay<T>(millis: i32, value: T) -> @Task<T>` and `io/http.fetch(req: Request) -> @Task<@Result<Response, HttpError>>` have generic and record types, which no adapter signature spells.
- **Options.** (1) Numeric adapters only (`wasi: .SleepMillis` `(i32) -> void`, `wasi: .HttpSend` over handles), std writing `delay` / `fetch` as `fn:` bodies over them — `#[@External.Wasm(fn: delayBody)] … fn delayBody<T>(millis: i32, value: T) -> @Task<T> { sleepMillis(millis); return value; }` (an eager body: blocks where called, so 140-a (1)'s box cannot be made by std). (2) An adapter's signature may name `@Task<T>` and a generic `T` (`wasi: .Delay` `(i32, T) -> @Task<T>`), checked by shape at the annotation, the compiler making the pollable box — `#[@External.Wasm(wasi: .Delay)] pub declare fn delay<T>(millis: i32, value: T) -> @Task<T>;`. (3) Records cross as the compiler's layout (`Request`, `Response` read by an adapter) — needed by `fetch` under (2) as well.
- **Recommendation.** (2) with (3) for `fetch` alone: each adapter's signature in docs.md's list, every other shape refused at the annotation.
- **Blocks.** Front 140 steps 4–5; `02/97` step 17.

#### 140-c · What a `browser` binding names
- **Measured.** 334 (3) gives `@External.Wasm` `host: .Browser`, 238/305 three forms (`op:`, `fn:`, `wasi:`), none a JavaScript import. Built (step 6): the `browser` loader serves the module's two preview 1 imports (`fd_write`, `random_get`) in JavaScript, so a `wasi:` adapter without `host:` already runs on both hosts (`std/io/random`'s three run under node through the loader).
- **Options.** (1) A fourth form `js: .Adapter` for `host: .Browser`, a second documented list, the loader carrying each adapter's JavaScript — `#[@External.Wasm(js: .Fetch, host: .Browser)]` beside `#[@External.Wasm(wasi: .HttpOutgoing, host: .Wasi)]`. (2) One adapter list for both hosts: each `wasi:` adapter has a preview 2 implementation (the component's adapter) and a JavaScript one (the loader), so `#[@External.Wasm(wasi: .HttpOutgoing)]` serves both and `host:` is written only where the hosts truly differ. (3) Unlabelled JavaScript text on a `.Browser` binding (host code, as `@External.Node`).
- **Recommendation.** (2): one closed list, parity by construction ("bound on both hosts or on neither").
- **Blocks.** Front 140 step 6 (`fetch`, `setTimeout` on `browser`); `02/97` step 17.

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

#### 08-f · Where Markdown and YAML live
- **Measured.** No Markdown code anywhere; one YAML-subset reader, in rakun's `config.bp`; `03-bundled-libs` sends config readers to std "when a second consumer appears".
- **Options.** (a) Both in a new member `onze-content`. (b) Markdown in `onze-content`; YAML in std as `yaml`, rakun's reader deleted by rakun's front. (c) A bundled `markdown` package.
- **Recommendation.** (b): frontmatter is YAML's second consumer; Markdown has one (115). Until std's `yaml` lands, 121 step 3 reads frontmatter with its own copy and deletes it then.
- **Blocks.** 121 step 3; a row for `02/97`.

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

#### snap-a · The snapshot maps — retired; the snapshots that exist or that a contract reads stay (replaces `01std-f`, `03r-ag`, `30-h`, `05emilia-m`, `53-b`)
- **Measured.** The nine maps carried from 1.0.10 (history under `../1.0.11-beta/`; re-evaluated case by case in [`20-snap/README.md`](./20-snap/README.md)) hold 473 cases plus helper tables: 27 obsolete (renamed, deleted or changed by decisions 186, 194, 200, 218, 34 step 2, 50-a, or deferred by `03r-ad`); 418 verified today by a named inline test or an existing `.snap` (e.g. `emilia.bp:10615` `tokenDeclarations(.Border.Rounded.Md) == "border-radius:var(--radius-md)"`); 21, in five groups, verified nowhere and worth a plain test. onze holds 51 `.snap`, 24 of them realising §§ 50 · 51 · 52 · 70 · 71 via `snapshots.assertAs`; jhonstart holds 39, std 4. The maps' recorded literals predate the code (slug separator, `_links` order, `normalize`, emilia classes) — not expected values. Contract 7, `snapshots.md` rule 3 and 98 check (2) require at least one `assert<Subject>(loc, …)` in every `<lib>-test`.
- **Options.** (a) As proposed: (1) maps are closed records — no front records a `.snap` because a map names it; (2) existing `.snap` files stay (std 4, jhonstart 39, onze 51), change only with their test; (3) a new snapshot only where its exact bytes are a contract another package reads — this milestone, onze-release's `text_…` and `dockerfile_…` (on disk) for `107-release`; (4) helpers, no more than a consumer uses: `emilia-test`'s `assertClassName` (`cardTokens()` under `defaultTheme()`, recording `e_39b87d03`) and `assertCss(loc, tokens, th)`, `rakun-test`'s `assertResponse(loc, res)` over `MockMvc.perform`, jhonstart's and onze's existing helpers (onze's `assertAlias` goes with 218), no other map helper; (5) the 21 unverified values become plain tests — std's `mocks.verify` message with `throwsWith` on both targets (`"mocks.verify: find - expected exactly 1 matching call(s), got 2"`), onze-release's tree as a path table, `emilia-card`'s repeat collapse, onze 53's blog E2E boxes as asserts over `request(…)` and the dev/start gate as an equality property (runner = five harness functions, no snapshot writers); (6) 97 step 7, 26 step 7, 33 steps 3–4, 50 step 8 and 51 step 7 close with an `AGENTS.md` line ("the inline literals and the existing `__snapshots__/` are the evidence"). (b) Build the whole layer: every map's helpers and `.snap` (~2 500 files), recorded literals re-derived first. (c) Keep the maps open per library: each answers its own former question and keeps its map until then.
- **Recommendation.** (a): one rule for every library, every value verified once, only three new `.snap` (emilia-test 2, rakun-test 1).
- **Blocks.** Front 135 ([`20-snap`](./20-snap/README.md)) steps 1–5, which own 97 step 7 · 19 step 6 · 26 step 7 · 33 steps 1, 3, 4 · 50 step 8 · 51 step 7 · 53 step 1's runner and steps 2–6's wording · 71 step 6; 98 check (2) stands unchanged.

#### atm-a · Cookie hook names: nouns, or 294/295's verbs (*proposed*)
- **Measured.** jhonstart's rule (`hooks.bp` header): a hook is a noun, `use` the activation. Request locals are settled by 296 (cardume atoms; "each bridge spells the same hooks (`atomValue`, `atomState`, `atomSetter`, `atomReset` …)" — `use setLocal` becomes `use atomSetter`). Left: `Cookie<T>` stays in `http` (294, 296), written `use setCookie(decl)` / `use clearCookie(decl)` — verbs.
- **Options.** (a) Nouns: `use cookieSetter(c)`, `use cookieClearer(c)`. (b) Keep 294/295's verbs for cookies. (c) Each library its own.
- **Recommendation.** (a) — one rule, jhonstart's and cardume's.
- **Blocks.** 123; 127; 104 step 6; `07-onze/53` (the cookie sites).

#### ctr-p · Confirmation `std-a` against confirmation `03r-e`
- **Rules.** `std-a`: `querystring.parse` / `parseForm` "refuse … an escape that decodes to a control character", and rakun's `splitQuery` moves onto them. `03r-e`: a cookie or query component that would decode to a control character "stays exactly as written". 196 moves rakun's cookie readers into `http`.
- **Recommendation.** Confirm `std-a`; `03r-e` lapses when rakun reads queries via `querystring` and cookies via `http`.
- **Blocks.** rakun 04's readers; 104's consumer sweep.

#### 125-a · How the JSON Schema documents are checked against the 2020-12 meta-schema (*proposed*)
- **Measured.** Step 9's third box asks for "one node script under `test/tools/`, run by
  `test/json_schema_test.bp` on commonJS, skipped by nothing". A 2020-12 meta-schema check needs a
  validator (Ajv 2020, or another); none is reachable from `repository/validation`'s suite: the
  repository ships `.bp` only, has no `package.json`, and a test cannot install from the network
  (CI and a cold gate). Ajv exists on this machine only inside unrelated global npm packages
  (`kanban`, `logseq`). The documents are already pinned as literals against
  ZOD_DOCUMENTATION.md § 8 (`test/json_schema_test.bp`, sixteen documents and nodes).
- **Options.**
  (a) Vendor a validator under `test/tools/` (Ajv's standalone 2020 build, ~120 kB JS, MIT) and run
  it from `test/json_schema_test.bp` through `io.process.run("node", …)` on commonJS:
  `node test/tools/check-schema.js '<document>'` → `ok` / the error list.
  (b) A hand-written structural check of the keywords the library writes (`type`, `properties`,
  `required`, `items`, `prefixItems`, `$ref`, `$defs`, `anyOf`, `format`, …) against the
  meta-schema's vocabulary, in botopink — no dependency, but not "validates against the
  meta-schema".
  (c) Drop the box: the literals against § 8 are the evidence.
- **Recommendation.** (a) — the strictest reading of the box, a real validator, no network; the
  vendored file's version and hash recorded in `repository/validation/AGENTS.md`.
- **Blocks.** 125 step 9, box 3.

#### 07-g · OTP release rendering
- **Measured.** `rakun-release/release.bp` (into `rakun-cli` under 187) and `onze-release/otp.bp` render the same `.rel` / `vm.args` / `sys.config` / boot script / Dockerfile; onze cannot reuse rakun's (rakun erlang-only, onze-release also commonJS).
- **Options.** (a) A bundled `release` of pure renderers. (b) A `botopink` CLI feature (02). (c) Leave both.
- **Recommendation.** (a); the CLI may adopt the package later.
- **Blocks.** `107-release` (a conditional front: answer it or defer 107).

#### 106-a · What `log.fileSink` is on wasm (*proposed*)
- **Measured** (`56d4bc29`, `.tasks/106-s3`). Decision 349 asks for `log`'s sinks — console, a file
  with rotation, per-name levels — with one API on every target, each `@External` cell bound on
  erlang/beam, commonJS and wasm. The console sink needs no cell (`@print` is lowered on all four);
  the file sink needs four (`appendLine`, `fileBytes`, `moveFile`, `removeFile`), bound on
  erlang/beam and node, and no wasm binding can reach a file (language-gaps.md, **A wasm binding
  cannot reach the file system**): WASI preview 2 has `wasi:filesystem`, but decision 334's
  `browser` host has no file system at all, and 140 binds a cell on both hosts or on neither. Today
  every function reaching the four cells is refused on wasm (146), so `log` does not build there.
- **Options.**
  (a) One API, a located refusal on wasm: the four cells get `fn:` bindings, and `fileSink` answers
  an `Error` on wasm on both hosts — nothing is written, nothing is dropped silently:
  ```bp
  // a wasm build of a program calling it
  val sink = try fileSink(LogFile(path: "app.log", maxBytes: 10485760l, maxFiles: 7), Format.Ecs, levels);
  // → Error("log.fileSink: a wasm program has no file system - use consoleSink")
  ```
  (b) A real file on the `wasi` host through a `wasi:filesystem` adapter (`01-compiler/140`), the
  `Error` of (a) on `browser` only — a cell whose behaviour differs between the two hosts:
  ```bp
  #[@External.Wasm(wasi: .FileAppend, host: .Wasi)]
  #[@External.Wasm("fn:noFileAppend", host: .Browser)]
  declare fn appendLine(path: string, line: string) -> i32;
  ```
  (c) The file sink leaves `log` for a package of its own (`log-file`), declared for erlang,
  beam and commonJS only; `log` itself then imports on every target:
  ```bp
  import {logfile.fileSink} from "log-file";   // a wasm build refuses the import, at the import
  ```
- **Recommendation.** (a) — 349's one API on every target, with the refusal located and named at
  the one call that cannot be served; (c) refuses earlier (at the import) but takes a sink out of
  `log`, which 349 names as `log`'s; (b) only once 140 has `wasi:filesystem` and a reason to give
  wasm programs a file.
- **Blocks.** `03-bundled-libs/106` step 3 box 1's wasm column (with **A wasm binding cannot keep
  a value across calls**, `01-compiler/140`) and box 3 (also waiting on `02/97` step 15's `json` and
  std `io/clock`'s wasm bindings).

### Implementation choices of tracks 00–03

Each implemented with its recommended option; the maintainer confirms or reverses (a reversal is a
local change in the named place). Full 1.0.10 text under the same id in
[`../1.0.10-beta/decisions-pending.md`](../1.0.10-beta/decisions-pending.md).

#### 01-compiler (20)

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

#### erk-a · The source of an `erika "…"` query in a method body (*proposed*)
- **Measured.** 312: `from User` names the type; a database source implements erika's `QuerySource<T>` (rakun-data's `Table<T>`). In a `#[repository]` behavior the generated `Users.Sql(db)` owns the source (313). In a method body — `type Report(users: Table<User>) { fn active(self: Self) -> @Result<User[], StoreError> { return erika "select * from User where active = true"; } }` — nothing in the query says which value is the source.
- **Options.** (a) The source is a hole: `erika "select * from ${self.users} where active = true"` — the row type from `Table<User>`; `from User` is then the in-memory and annotation form only. (b) `from User` everywhere; in a body the source is the one field of `self` typed `Table<User>` — none or two is an error at the query (by type, as rakun's container injects). (c) Both: (b), and (a) when two fields of the same table type exist.
- **Recommendation.** (b): one spelling of `from` in every place; the source found by type, never by a name.
- **Blocks.** `04-rakun/137` step 2's body form; rakun 08 step 7's body-form cell.

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

#### 34-a · emilia's run-time entry points once a family is a `styled` component (*proposed*)
- **Measured** (front 34 step 5, `front/emilia-34-s5`, botopink-lang `0c544566`, styled `3ac4a07`). A
  `styledProperty` / `styled` value is a `@Component<…>`, and on commonJS every component function is an
  `async function` (the built `styled/styled.js`: `async function propertyConstant(bpContextMap__, …)`),
  the build-time constants included. Its fields are read after `await`, and `await` needs a `@Task` /
  `@Component` return (`effect-await-without-task`). So once `tokenToSheet` reads one family's
  `styledProperty`, the chain above it — `tokensToSheet`, `styleRule`, `emiliaWith`, `emilia`,
  `className`, `styled`, `styledWith`, `cls`, `clsWith`, `named`, `assertAsciiBody` — returns
  `@Task<…>`, and every caller of them changes: `jhonstart-emilia` (`src/root.bp`, the bridge test),
  onze 68's `styleRule` reader, `onze-cli`, and the fifteen examples (eleven of whose `src/main.bp` 34
  does not own). A field read without `await` compiles: erlang answers it, commonJS reads `undefined`
  (the confirmed gap row "A `@Component` value's field is read without `await`"; probed:
  `val p = padAll(4); p.declarations` passes on erlang and fails its assert on commonJS).
- **Options.**
  (a) Step 5 makes the entry points `@Task<…>`; the consumers gain `await` in the same landing (a
  carve-out of 34 into `jhonstart-emilia/src` + `test/bridge_test.bp`, onze 68's reader, `onze-cli`
  and the eleven examples' `src/main.bp`):
  ```bp
  pub fn emilia(tokens: Token[]) -> @Task<string> { … }
  val cls = await emilia([.Pad.All.__4]);          // was: val cls = emilia([.Pad.All.__4]);
  ```
  (b) Step 5 waits until no run-time consumer reads a token list: `08-bpp/119` step 4 first (a list is
  an annotation's comptime argument, `<div #[styled(.Pad.All.4)]>`, `class={emilia(tokens)}` refused)
  and step 5's deletion of `jhonstart-emilia`; order 119 s4 → 34 s5 → 119 s5 (today 119 s5 waits on
  34 s5):
  ```bp
  <div #[styled(.Pad.All.4)]>…</div>                // the only way a list reaches a page
  ```
  (c) The families stay string builders: emilia uses `styled` for its sheet only, amending 338 (3) and
  350 (no `@utility` literal per family):
  ```bp
  fn padAll(n: i32) -> string { return "padding:" + spacing(n); }   // as today
  ```
- **Recommendation.** (a): it is the model 338 accepted ("on commonJS an `async function`"), one path,
  and every miss is a red on commonJS (the 734 tests assert the strings). The field-read gap row is
  worth closing first (`01-checker`), so a missed `await` is refused at the read, not found by a test.
- **Blocks.** 34 step 5 boxes 1–4 (families, `@utility` comments, variants, `Token implement
  Styleable`), and through them step 2.

#### 34-b · Contract 4's class formula against 338's class over the rules (contradiction) (*proposed*)
- **Rules.** `contracts.md` § 4: `class = "e_" + hash.contentHash(encodeSheet(tokensToSheet(tokens,
  theme)))`, the shared fixture `e_39b87d03`; 34 step 5's box 6 keeps it unchanged and box 5 deletes
  `output.bp`'s sheet model (the codec `encodeSheet` with it). 338 (2): a component's class is
  `contentHash` over its rules, with the layer's prefix (emilia's `e_`).
- **Measured.** `cardTokens()`'s payload (four `R\tutilities\t…` records) hashes to `39b87d03`; the
  same list's rules as `styled` writes them —
  `\u{1}{background:#ffffff;padding:calc(var(--spacing) * 4);font-weight:bold}@media (hover: hover){\u{1}:hover{background-color:var(--color-gray-100)}}`
  — hash to `f51c2501`. The prefix alone does not keep the fixture: under 338 it is `e_f51c2501`, and
  every emilia class moves (`emilia-card`'s three included).
- **Options.**
  (a) Contract 4 follows 338: `class = prefix + contentHash(rules)`; the fixture is re-derived once in
  step 5 and its readers (emilia's inline test, `jhonstart-emilia`'s bridge test, onze 68's bundle
  test, `emilia-card`) re-recorded in the same landing:
  ```bp
  assert className(cardTokens(), defaultTheme()) == "e_f51c2501";   // was "e_39b87d03"
  ```
  (b) emilia keeps the formula and its codec: it hashes its payload and hands `styled` a finished
  component, `styledConstant("e_" + hash.contentHash(payload), rules)` — two class rules in one sheet,
  and `encodeSheet` stays:
  ```bp
  val c = "e_" + hash.contentHash(encodeSheet(tokensToSheet(tokens, th)));   // as today
  return styledConstant(c, rules);
  ```
- **Recommendation.** (a): one class rule for every component; the classes move once, in step 5,
  before `20-snap` records them (350's argument for the families).
- **Blocks.** 34 step 5 boxes 5–6; `contracts.md` § 4.

#### 34-c · The order of a class's rules, and the document around `styled`'s sheet (*proposed*)
- **Measured.** (1) `styled`'s reader writes a block's own declarations first and its nested rules
  after (`reader.bp` `readBlock`: `rulesOf(sels, decls, …) + nested`). emilia keeps token order among
  the rules with no at-rule: `[.Bg.White, Token.Focus([.Bg.Color.Gray.__100]), .Pad.All.__4]` renders
  today `.e_6a7c63ea{background:#ffffff}.e_6a7c63ea:focus{background-color:var(--color-gray-100)}.e_6a7c63ea{padding:calc(var(--spacing) * 4)}`;
  the same list as one literal, `styled "${bg} &:focus { ${gray} } ${pad}"`, renders
  `.k{background:#ffffff;padding:calc(var(--spacing) * 4)}.k:focus{…}` — other bytes, and two lists that
  differ only in where a selector variant stands get one class (contract 4 clause 2, "token order is
  class identity"). (2) `Sheet.render()` writes `@layer <name>{…}` per non-empty layer and nothing
  else; emilia's `flush()` document also holds `<style>`, the `@layer theme, base, components,
  utilities;` statement (and `@layer properties;`), the theme's `:root{…}` block, the base rules, the
  `@keyframes` blocks (deduplicated, outside every layer), the `@property` fallback under
  `@supports`, and the `prefix` / `important` / `layers: false` options.
- **Options.**
  (a) `styled`'s reading stands: emilia's output moves for every list with a selector variant between
  two plain tokens, recorded once in step 5, and clause 2 reads "rule order is class identity".
  (b) `styled`'s reader keeps source order — a declaration after a nested rule opens a new rule of the
  class, as CSS Nesting's nested-declarations rule does (`08-bpp/119`'s reader, before 34 s5); emilia
  composes a list's plain tokens before its conditioned ones (its rule today), and its `flush()` keeps
  the document frame — `<style>`, the statement, `:root`, the base rules, keyframes, the fallback —
  around `Sheet.render()`, the rule model and codec gone:
  ```text
  styled "${bg} &:focus { ${gray} } ${pad}"  →  .k{background:#ffffff}.k:focus{…}.k{padding:…}
  ```
  (c) emilia keeps its `Rule` / `Sheet` composition and takes only the families' declarations from
  `styled` — amends 338 (3) ("its own sheet model goes").
- **Recommendation.** (b): byte-identical output (step 5's claim) and clause 2 both hold, and the
  reading is what CSS Nesting does in a browser.
- **Blocks.** 34 step 5 boxes 3 and 5; `08-bpp/119` step 1 (the reader) under (b).

#### 05emilia-n · The unplaced Tailwind rows
- **Measured.** Four rows have no owner: named `:has()` / `:not()` / ARIA / data / `in-[…]` forms (reachable via `arbSel` only); named groups and peers; `@theme inline`; negative translate (`TranslateX/Y.Neg` absent, `tokens.bp:2259-2272`). The fifth — a cleared breakpoint emitting `@media (width >= )` — is decision 300's: "a token naming a cleared or absent breakpoint is a compile error where the token list is comptime-known" (34 step 3, unconditional).
- **Options.** (a) None: the four out of scope in `docs.md` § Deviations, written with `arbSel`. (b) Negative translate and named groups / peers. (c) All four, `@theme inline` included (a second render mode).
- **Recommendation.** (a); (b) is the feature answer if any is wanted.
- **Blocks.** 34 step 4 (conditional).

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

#### 119-f · A `val` holding a `styled` literal computed at render (decisions 352, 354, 355) (*proposed*)
- **Measured** (front 119 step 1 box 4, `front/styled-context`, botopink-lang `0c544566`). A literal
  with a hole known only at render (`${padAll(2)}`, a call) emits `styledComputed(<map>, …)`, which now
  reads `use context(StyledContext)`. A module `val` initializer runs outside every render — the hidden
  map is `undefined` / `null`: erlang evaluates it on the first read (`persistent_term`), a test module
  at its init, commonJS at module load — so `pub val code = styled """ … ${padAll(2)} … """;` (front
  119's own example until this step) is `context-unbound` there: the erlang test module dies in
  `_botopink_init` before its first test, and nothing refuses the `val` at build. The step rewrote
  `code` as a function (`fn code() -> StyledView`) in the example, the tests and `styled-example`.
- **Options.**
  (a) Refused at build: a module `val` whose initializer calls a `@Component` is an error at the
  initializer — no render tree there (354 (3)) — naming the function form:
  ```bp
  pub val code = styled "color: ${pick()};";
  // error: `code` is a module `val`, evaluated outside every render; a component computed at render is
  //        a function — `fn code() -> StyledView { return styled "…"; }`        (at `styled`)
  ```
  (b) Refused at build only when the initializer reaches a context read (`Decl.hooks` lists a
  `context`) — a `@Component` that reads none (`pub val tab4 = styledProperty "tab-size: 4;"`, a
  constant) stays legal:
  ```bp
  pub val tab4 = styledProperty "tab-size: 4;";    // ok: styledConstant reads no context
  pub val code = styled "${padAll(2)}";            // error at `styled`: reads StyledContext
  ```
  (c) Accepted; `context-unbound` at run time when first read (today):
  ```text
  escript: exception error: {panic,<<"context-unbound: no `use provide(StyledContext, ...)` …">>}
    in call from styled_test:code/0 … '_botopink_init'/0
  ```
- **Recommendation.** (b): fail at build where the program cannot work (decision 67) without
  refusing the build-time constants `styled` emits for a `val` today.
- **Blocks.** Nothing in 119 step 1 (built as functions). `06-emilia/34` step 5 (emilia's `val`
  families) and any library `val` of a computed component.

#### 119-g · A `@Component` thunk a host cell calls loses every provider above it (decision 354 (8)) (*proposed*)
- **Measured** (front 119 step 1, jhonstart's `compose` providing `StyledContext`). A lambda answering
  `@Component<R>` takes the hidden map as its first parameter, and "a host that calls one passes the
  map first (`null` when it has none)" (`context_lower.zig`). jhonstart's `__jhTryComponent` /
  `componentOutcome` (`signal_runtime.mjs` `tryTask(f)` → `f()`) and a `Suspense` boundary's child
  are such thunks: below an `error` or `not-found` segment, or in a boundary fill, the map is gone. A
  page under `withError(segment("/"), …)` whose component is a `styled` literal computed at render
  renders the segment's error view (`<div data-jh-e="/">caught</div>`) and writes no sheet — its
  `use context(StyledContext)` was `context-unbound` — on erlang and commonJS.
- **Options.**
  (a) The compiler: a `@Component` lambda handed to a host function captures the map where it is
  written (it takes no hidden parameter), so the host's call keeps the providers:
  ```bp
  val outcome = await __jhTryComponent({ -> notFoundLevel(chain, i, route, page) });
  // lowered: { -> notFoundLevel(bpContextKids__0, chain, i, route, page) } — the map captured
  ```
  (b) jhonstart: every thunk it hands a host is a `fn() -> @Task<Element>` (no hidden parameter; a
  component call in its body takes the enclosing body's map), `__jhTryComponent` goes:
  ```bp
  val outcome = await __jhTryTask({ -> notFoundLevel(chain, i, route, page) });
  ```
  (c) A host cell that calls a `@Component` thunk declares the map as a parameter, and the caller
  passes its own (`declare fn __jhTryComponent(map: unknown, f: …)` — a program names the map, which
  354 (8) says it never does).
- **Recommendation.** (a): a provider cannot be lost by the shape of a call — no library has to know
  which of its thunks a host calls.
- **Blocks.** 119 step 2's "rendered twenty times" box under an `error` / `not-found` / `loading`
  segment, step 3 (a boundary's fill), and every context read below one (`ElementContext`,
  `05-jhonstart/26`).

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

### From the maintainer's Portuguese record (`decisoes-pendentes.md`)

#### 07-i (revision) · Whether 163's ban on repeated names in bundled packages survives 170's alias
- **Measured.** 163 bans a bundled package exporting a name std or a framework exports "until the toolchain line closes"; 170 (an import naming its module is never ambiguous; alias when both are needed) closes it.
- **Options.** (a) Still banned: a new bundled package picks a non-colliding name (`http`'s `cookie` module, `actions`' `id.deriveActionId`). (b) Ban lifted: natural names, importers alias.
- **Recommendation.** (a).
- **Blocks.** Nothing; 102, 103 and 104 already chose free names.

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

### 05-jhonstart (10)

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
