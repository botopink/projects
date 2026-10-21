# Retired — what was discontinued and what replaced it

This page lists every form the language, the compiler, std, the libraries and the process have retired, with the form
that replaced each, so that nobody writes or reads an old form as current. It is derived from
[`decisions-taken.md`](decisions-taken.md) (the rules in force) and [`decisions-taken-steps.md`](decisions-taken-steps.md)
(the record), and every row cites the decisions it comes from; where the two differ, the later decision wins and this page
follows it. A form listed here appears legitimately only in a history sentence, in a decision's own text, in a codemod's
rule or in a cell that tests its refusal (`prelude_name_with_sigil` refuses an `@`-prefixed prelude name, for example).

## Language spellings

| Retired | Replaced by | Decisions | Since / note |
|---|---|---|---|
| `@Result<T, E>` | `Result<T, E>`, declared in `primitives.bp` | 606 (1), 609 | 2026-10-18 |
| `Option<T>`, `Optional<T>`, `optional<T>` (and the `@Option<T>` of 1.0.1), `.Some(v)` / `.None` over an optional | `?T`; absence is `null` | 2, 32, 44, 47, 54 | Each name is refused and the refusal names `?T`. The checker's internal `optional<T>` never reaches a hover (44) |
| The builtin `result` namespace; methods on `?T` | `r.map(f)`, `r.flatMap(f)`, `r.unwrapOr(x)`, `r.isOk()`, `r.isError()` on `Result`; `??`, `?.`, `?.[i]`, `?.(args)` and `!` on `?T` | 330 | |
| `Ok(…)` / `Error(…)` as constructors in an expression | `return v` / `throw e` | 208 | They stay `unbound variable` in an expression; they remain `case` patterns |
| `@Task<T>`; `Task` as a prelude name | `Async<T>`, with the `async` marker (`pub async fn f() -> Async<T>`) | 553 (2), 606 (1), 732 | 2026-10-15 (553), 2026-10-18 (732). 606 (1)'s `Task<User>` and 623's `Task<…>` read `Async<…>` |
| `map`, `then`, `mapError`, `catch` on a task | `try await … catch`, `case` on `await`'s `Result`, or an `async { … }` block | 523, 537 (3) | |
| `@Component<R>`; `@Component<C, R>` (the base parameter) | `Component<R>`, with the `component` marker (`component fn`) | 354 (1), 553 (2) | |
| `@Iterator<T>` | `Iter<T, R = void>`, with `iter fn` | 553 (2) | |
| `@Stream<T>` | `AsyncIter<T, R = void>`, with `async iter fn` | 553 (2) | |
| `@Hook` | `Component<R>`, read with `use` | 354 (1) | |
| `@Renderable`, `@Future`, `@Use` | `Renderable`, `Future`, `Use` (written bare, from `primitives.bp`) | 606 (1) | |
| `@Context<C>` (the context marker on a component's type) | — (removed): a `Component<R>` whose `R` implements `Renderable` is a component | 354 (1) | |
| `@embed("path")` — the `@` builtin call, in a program and as a printed form of the resolved program | `comptime compiler.embed("path")`, answering a `Link`, opened through `Asset(link).open()` (§ The `compiler` module and builtins) | 606 (1), 607 | 2026-10-18; no `@name` builtin remains. 835 (2)'s printing of a folded `Asset` as `@embed("path")` is a retired form too, its replacement under ctr-embed-resolved (the maintainer, 2026-10-21) |
| `@getContext(T)` | `use context(themeContext)` | 269, 354, 379, 722 | 269 is `Replaced by 354 and 379` |
| `Context<T>()` | `createContext(value)` (std's `context` module) | 378 (1) | std's `Context<T>` remains a record holding `contextValue: T` (683) |
| `use context(T)`, a context read by a bare type name | `use context(themeContext)`, a context value the reader imports | 722, 723 | 2026-10-18 |
| `use provide(ctx, value)` | `use provide(ctx)`, the context value alone; another value is a new `createContext(…)` in the body | 723, 379 (2) | 2026-10-18 |
| `context-unbound` | — (removed): a read answers the nearest provider above, else the declared default | 378 (3), 723 | 354 (4)'s root check stays open as a contradiction (§ contexts-and-components (3)) |
| `@is(…)` | `x is T` | 322 | `@is(…)` is refused naming `x is T` |
| `@block` | `{ … }`, a block (a `{` without `->`) | 525 | 2026-10-14 |
| `comptime { break v; }`; a `case` arm's `break <value>` | the block's or the arm's tail, its last expression written without `;` | 525, 541 (2)–(4) | `botopink format` rewrites both (588) |
| The `runtime` keyword | — (removed): a line runs on the side of the body it is written in; `comptime` and `compiler.init` are the two crossings | 632 | 2026-10-18 |
| Any other marker order (`async pub fn`, …) | `#[…] [pub] [default] <marker> fn` | 572 | 2026-10-16 |
| `async { x -> … }`, `iter { -> … }`, `async iter { x -> … }`, `component { -> … }` (a marked lambda's marker before the brace) | `{ async x -> … }`, `{ iter -> … }`, `{ async iter x -> … }`, `{ component -> … }` | 584 (1) | 2026-10-17. `async { … }` is the block and `iter loop { … }` the loop |
| `#[use]`, `#[future]`, `#[generator]`, `#[resultGenerator]` (effect annotations) | the body markers `component`, `async`, `iter`, `async iter` | 553, 606 (4) | Refused, `effect-annotation-removed` |
| A function whose return type is inferred from its body | the return type always written, `-> void` included | 622, 33 | Refused, `fn-return-missing` |
| A lambda typed by its later calls | a lambda whose position fixes its type, or `fn(x: T) -> R { … }` | 583 | Refused, `lambda-untyped` |
| `mod m;`, `pub mod`, `lib.bp` | every `.bp` under `src/` is a module, its path its name | 592 (1), 337 (2) | |
| The shorthand import (an item with no `from` whose first segment names no module) | the brace form `import {a.b.c};` | 337 (1) | Refused, `shorthand-import` |
| `from "<a module of this package>"`, `from "<the package's own name>"` | the brace form with no `from` (`import {log.logger};`) | 206, 309 | Refused, `module-import-with-from`; std included |
| `from "std"` inside std | `import {path.relative};` | 309 | |
| The "prefix module wins" rule; `expandImports` | 582's namespace and item rules; a collision is `module-item-collision` | 582 | |
| `.d.bp` declaration files (`builtins.d.bp`, `builtins_fns.d.bp`, `rakun.d.bp`) | ordinary `.bp` modules; each declaration in the std module that owns it | 575 (1), 605, 606 | A file still ending `.d.bp` is a module named `x.d` |
| `Array<T>`, `String`, `Bool`, `BigInt`, `Bytes` | `array<T>` (spelt `T[]`), `string`, `bool`, `bigint`, `bytes` | 641, 617 (1) | Statics move to the type: `string.fromCodepoint(65)`, `array.range(0, 3)`, `bytes.fromUtf8(s)` |
| `I32`, `I64` (per-width contracts) | the types `i32`, `i64`; contracts are `Number`, `Integer`, `Signed`, `Float` | 641, 496 | |
| `Pair<A, B>` | the tuple `#(A, B)` (`#(a, b)`, `p._0`, `val #(a, _) = p`) | 738 | 2026-10-18. `prelude_has_no_pair_or_function` refuses `Pair.of` |
| `Function` (and its statics) | `fn(A) -> B` as the type; `identity`, `compose`, `flip`, `constant` from std's `functions.bp` | 738 | 2026-10-18 |
| `any` | `unknown`, narrowed with `is` | 31 | |
| `@src()`, `src` | `compiler.src()` (`comptime compiler.src()` in a run-time body) | 575 (4), 606 (2), 718 | |
| `...` as a spread | `..` (`Pessoa(..p, nome: "Ana")`) | 359 (1), 529 (3) | `botopink format` migrates it; `...` is the inclusive range alone |
| `p.f = v` (assigning a record field) | `Person(..p, f: v)` | 37 | |
| `<pattern> as <name>` | — (removed): a `case` binds through its variant pattern | 11 | |
| A `Range` value, `.rev()` | — (removed): `a..b` / `a...b` is syntax of a pattern, a loop or a slice | 105 | |
| `===`, `behavior Eq`, a user `equals` | `==`, structural; another sameness is a method with its own name | 211, 348 | |
| `use client;` (a module-level directive) | `#[client]`, a library decorator | 87 | |

## The `compiler` module and builtins

| Retired | Replaced by | Decisions | Since / note |
|---|---|---|---|
| `#[builtin]`, `@name` prelude names, `compiler.setBuiltin`, `builtin-twice`, `setBuiltin-outside-std` | the prelude `primitives.bp`, members of `compiler`, and two imported std functions | 606 (1) (replaces 575 (2)) | 2026-10-18 |
| `compiler` as a keyword | `compiler`, a value std declares (`import {compiler} from "std";`) | 579 | The codemod adds the import |
| `@print`, `print` from `io.bp` | `terminal.print` (`import {io.terminal} from "std";`) | 606 (2) | |
| `@panic`, `panic.bp` | `panic` from `failure.bp` | 606 (2) | |
| `@println`, `println` | `print(a, b, "\n")` | 606 (2) | |
| `@todo`, `todo` | `panic("not implemented")` | 606 (2) | |
| `@debug`, `debug` | — (removed): `print` | 606 (2) | |
| `@typeInfo` | `compiler.typeInfo(T)` (`comptime compiler.typeInfo(T)` in a run-time body) | 606 (3) | |
| `@embed`, `embed(path) -> Bytes`, `compiler.embed(…) -> Asset` | `compiler.embed(path) -> Link`, opened through `Asset(link).open()` | 607 | 2026-10-18 |
| `TypeInfo<T>`, `reflection.bp` | `compiler.Info<T>` in `compiler.bp` | 606 (3), 608, 630 | |
| `compiler.find`, `compiler.catalogue`, `@TypeInfo.all`, a catalogue filled at an entry point | the run-time registry each marker's `compiler.init` executor writes | 576 (7), 665 | 2026-10-18. The cells' refusal names (`find-imported`, …) remain where their cells do (662) |
| `Declared<T>`, `DeclaredMeta`, `DeclaredTypedMeta` | the registry (665) and `compiler.*` reads on a handle | 576 (7) | |
| A `comptime` default that queries the catalogue (`boot(modules = …catalogue…)`) | a plain `boot` over the registry, `registry.modules()` | 551, 664 | 551 is `Replaced by 581 (1)` |
| `compiler.compile(syntax executor)` | `compiler.init(syntax executor: fn())` | 615 | 2026-10-18 |
| `Compiler.name -> string` | `compiler.name(e) -> ?string` | 612, 643 | 2026-10-18; 612 `Reversed by 643` |
| `compiler.wrapWith` | a proxy type the decorator builds, or a function written around the call (`retry(policy, { -> issue() })`) | 714 | 2026-10-18 |
| `Compiler.implement(source)` | `compiler.external(comptime ..sources: Implementation[])` | 606 (3) | |
| `compiler.record(fields)` | `compiler.buildType(name, fields, implements)` / `compiler.buildTypeInline(fields, implements)` | 578 (3), 625, 629 | |
| `compiler.failAt` | `compiler.fail(message, at:, span:)` | 576 (2) | |
| The `Decorator` type, `behavior Decorator`, `Decorator.same`, `==` on handles | `compiler.same(a, b)` | 666 | 2026-10-18. 268, 371 and 591 overtaken |
| `Annotation`; a type or enum used as an annotation key (`type Mark(…) implement Annotation`) | a decorator function recording a meta record with `compiler.setMeta` | 663 | 2026-10-18 |
| `#[Stage.Any]`, `#[@Stage.Any]` | `#[stage(.Any)]`; `Build` / `Run` are never written | 663, 681 | |
| `#[BeamMemory.…]`, `#[@BeamMemory(…)]` | `#[beamMemory(.Ets)]`, `#[beamMemory(.PersistentTerm)]` | 663, 547 | |
| `keyed: true` and the per-process placement of a module `var` | — (removed): one value for the whole program; `Dict.bump` is a plain `Dict` method | 547 | |
| `Decl`, `Decl<T>`, `@Decl`, std's `Expr<E>` behavior | an opaque declaration handle (`syntax decl: unknown`) read through `compiler.*` | 576 (1), (3) | |
| `d.hooks`, `d.fields`, `d.methods`, `d.params`, `d.returnType`, `d.owner`, `d.annotations`, `d.variants` | `compiler.hooks(d)`, `compiler.fields(d)`, … | 576 (8) | |
| `decl.loc` | `compiler.src()` inside the decorator body | 718 | |
| `decl.setMeta`, `decl.addMember`, … (216's four places) | `compiler.setMeta`, `compiler.addMeta`, `compiler.addMember`, `compiler.addType` | 575 (3), 576 (9) | 216 replaced by 575 (3) |
| The string meta: `setMeta(key, value)`, `.meta.<decorator>.<key>` | typed meta: `compiler.setMeta(M(…))`, read `compiler.meta<M>(d)` / `metaAll<M>(d)` | 576 (11) | |
| The string `addMember(name, source)` | the typed `compiler.addMember<F>(name, syntax member: F)` | 575 (3), 576 (14) | |
| The string `addType(name, source)` | `compiler.addType(name, compiler.buildType(…))` or a template text answering a type | 640 (2), 605 (2) | |
| `#[@Host]`; delegate forms | `#[compiler.external(…)]` | 575 (6) | |
| `#[stage(…)]`, `#[beamMemory(…)]` written bare | `#[compiler.stage(…)]`, `#[compiler.beamMemory(…)]` — members of `compiler`, as `external` | 774, 606 (4), 663 | 2026-10-19 |

## `syntax`, `comptime`, templates and code

| Retired | Replaced by | Decisions | Since / note |
|---|---|---|---|
| `@Expr<T>` (a parameter of type expression) | `syntax x: T` | 575 (4), 576 (1) | |
| The `expr` parameter modifier | `syntax` | 616 | |
| `.value` on a captured argument; `x.fail(…)` | the `comptime` value itself; `compiler.fail(…, at: x)` | 575 (4) | 411's `expr-value-of-function` went with `.value` (735) |
| `comptime x: @Expr<T>` | `comptime x: T` | 575 (4) | |
| A meta record's field written `@Expr<T>` | `T`, holding a tree when filled from a `syntax` | 576 (12) | |
| `-> @Expr<T>`, `-> @ExprCustom<T>`, `-> syntax T`, `-> expr` | `-> T`, `-> anyvalue` or `-> anytype`; a custom tree through `compiler.custom(ast)` | 576 (4), 578 (1), (2), 577 (6) | |
| `@expr(v)` | `v` | 605 (5), 578 | |
| `type T` (a type parameter's spelling) | `type<T>` (`comptime t: type<T>`) | 575 (5) | |
| A bare type-position `type` | `anytype` | 578 (2), 577 (6) | |
| `@emit` | a registration in a `compiler.init` executor; a generated type through `compiler.addType`; a member through typed `compiler.addMember` | 605 | 2026-10-17 |
| `@code` | the typed AST (`compiler.ast`, `code`) | 605, 625 | |
| `compiler.build(text)` and every code-from-text form | `compiler.ast(node)` over the `Node` records, `` code @`…` `` (`code.bp`), `compiler.buildType` / `buildTypeInline` | 625, 637, 629 | 2026-10-18 |
| A `Hole(index)` node | `compiler.lookup(e, name) -> ?Node`; the template parses its own text | 625 (4), 637, 802 | |
| `compiler.holes(t)` (the caller's `${…}` as `syntax` values) | the template parses its text and resolves each name with `compiler.lookup(e, name) -> ?Node` | 802 (reverses 637's caller-hole half), 577 (5) | 2026-10-20 |
| The `Syntax(e)` node; `compiler.isSyntax(v)` | `compiler.lookup` answering the code a `syntax` value holds, spliced as written; `syntax` a modifier, never a type | 802 (reverses 638) | 2026-10-20 |
| `compiler.parts`, `Part` | `compiler.text(q)` (raw); the sub-language parses its own holes | 577 (5), 578 (5) | |
| `Renderable` / `Renderable<T>` (std's marker; 791's node parameter) | nothing — `Component<R>` alone; what a tree holds is the render library's types (rakun-bpp's `NodeChild`) | 804 (2), (3) | 2026-10-20 |
| A type component's `fn render(self: Self) -> Component<R>` | `fn compose(self: Self) -> Component<R>` | 804 (1) | 2026-10-20 |
| rakun-bpp's compiler-known `Children` and its coercions | `NodeChildren = NodeChild[]`, `NodeChild = Component<Element>` | 804 (4), 809 (7) | 2026-10-20 |
| `NodeChild = Element \| Component<Element>` (a union the renderer narrows) | `NodeChild = Component<Element>`, the builders `component fn`s, every child resolved | 809 (7) | 2026-10-20 |
| `Component<R>` as a type of its own; `type X implement Component<R> { fn compose(self: Self) -> Component<R> }` | `Component<T> = Composition<T> \| Composable<T>`; `type X implement Composable<R> { component fn compose(self: Self) -> Composition<R> }` | 809 (1), (2) | 2026-10-20 |
| 811 (2)'s `pub opaque type Composition<T>(source: …)`, `Composition.of`, `Composition.resolve` | `pub type Composition<T> = fn(scope: Scope) -> T \| Async<T>` again, std's `resolve` a function, `is fn(Scope) -> …` | 815 (reverses 811 (2)) | 2026-10-20 |
| A public `scope.child()` made by the renderer before each child | `scope.childAt(place, c)`, std keeping the tree of cells by place and identity | 817 (1) | 2026-10-20 |
| `{ component -> v }` written as a child (813 (1)); a render library's `key` prop (816 (5)) | `{ _ -> v }` for a ready value, a named `component fn` or the factory's call for one with hooks; one `#[key]` parameter or field | 817 (3), (4) | 2026-10-20 |
| A component's identity by its declaration with its type arguments (817 (2)); `#[key]` on a parameter or a field, `key-twice` (817 (4)); hooks' slots in the node's own cell (816 (1)) | the call that made it, numbered within its declaration; `#[key(expr)]` at the call; a child cell per `use` that answers a value | 818 | 2026-10-21 |
| `Composition<T> = fn(scope: Scope) -> T \| Async<T>`; 817's places `Use(n)` / `Tail` / `Index(i)` / `Key(k)` and the identity apart from the place | `fn(scope: Scope, key: Place) -> T \| Async<T>`; a `Place` of the call's number and the item's number or key | 819 | 2026-10-21 |
| `context-provide-after-render` (the first component `use` read as the body's render) | a `use provide` counting in the order written; `use c` with a child cell | 812 | 2026-10-20 |
| `render-scope-construction`; `Module`'s readable fields `mod.name`, `mod.path` | `opaque-construction` / `opaque-field`; `mod.name()`, `mod.path()` | 811 (3), (4) | 2026-10-20 |
| `RenderScope`, `RenderScope.root()`, `c.run(scope)`, `Rendered<R>`, string-keyed frames (`push` / `find`) | `Scope` (`Scope.root()`, `scope.child()`), `resolve(c, scope)`, a persistent map keyed by the context's type | 809 (6), (8) | 2026-10-20 |
| Template calls `name "…"`, `name """…"""`, `name("lit")`, `#[name("lit")]` | `` name @`…` ``, `` #[name @`…`] `` | 577 (1), (3), (6) | The codemod resolves the escapes to raw bytes |
| `syntax-captures-build` | a `compiler.*` call inside a tree is evaluated at build and spliced | 575 (4), 614, 642 | |
| `decorator-member-captures` | the same splice rule inside a member | 642 (replaces 413) | |
| `decorator-member-fn-imported-name` | a member's names resolve where they were written | 384, 669 | |
| `#[mockable]`, the associated `Mock` type, the `mock()` member, std's `#[mock]` writing `T.Mock(…)` | `mock(T)` from `testing/mocks.bp` | 644 | 2026-10-18 |
| validation's `#[pick]`, `#[omit]`, `#[partial]`, `#[required]`, `#[extending]` | `Type.pick`, `Type.omit`, `Type.partial`, `Type.required`, `Type.merge` (`types.bp`) | 307 | |
| `Type.keys`, `Field.of`, `Field.all`; a field key matched by `case` | `compiler.Field<T>`, `.field` written where one is expected | 599 (1), (2) | |
| An expanded `boot`; `d.value` | a plain function over the registry | 581 | 562's example withdrawn |

## Host functions and targets

| Retired | Replaced by | Decisions | Since / note |
|---|---|---|---|
| `#[@External.<Target>(…)]`, `#[@external(.X(…))]`, `#[external(…)]` | `#[compiler.external(.Erlang(…), .JavaScript(…), .Wasm(…))]` with `import {compiler} from "std";` | 575 (6), 606 (4) | |
| `@External.Beam`, `.Beam(…)` | `.Erlang(…)`, which binds erlang and beam; `inline: true` declared by it alone | 437 | Writing `@External.Beam` is a located error |
| `Implementation.Node`, `.Node(…)` | `Implementation.JavaScript`, `.JavaScript(…)` | 618 | 2026-10-18 |
| The `Typescript` implementation; `JavaScript`'s `types:` field | `"typings": true` in `botopink.json`, or `botopink build --typescript` | 619, 620 | 2026-10-18 |
| `fn:` (the botopink-body label) | `body:` | 610 | 2026-10-18 |
| The prefixed strings `"fn:x"`, `"std:x"` | the labelled fields `body: x`, `std: "x"` | 481 | |
| `label = value` in the compiler's annotations | `label: value` | 305 | |
| `throws: true` | `result: true`, answering `Result<…, HostError>` | 490 | |
| `declare` inside a `behavior` | host code on the type; a behavior holds signatures and `default fn` bodies | 575 (6), 617 (2)–(4) | Refused, `declare-in-behavior` |
| `comptime-host-cell-unavailable` | a host function with a wasm form runs at build; one without is refused there, located | 633, 594 | |
| beam-to-wasm as a fallback at build; `modules/beam-to-wasm/` | a `std:` cell or a `.Wasm(body: f)`; the directory deleted with 164's B-84 | 452, 594, 544 | |
| The prebuilt `.wasm` library form (333 (B)) | — (removed): `Implementation.Wasm` is the enum's variant and nothing else | 333 (B), 731 (4) | |
| The BEAM comptime runtime (`persistent_beam.zig`, `runtime/beam/**`, the persistent `erl` spawn, `render_resident`'s erl step) | comptime on the wasm runtime only | 434 (1) | 2026-10-10. `persistent_erlang.zig` is never built |
| wasm3, `modules/wasm3/` | wasmtime (native), the page's `WebAssembly` (web) | 543 | 2026-10-14 |
| The linear-memory model of a wasm program; `std_wasm.wasm`, `heap.zig`, the Erlang term library | WasmGC values (`needs: [.Gc]`); std-wasm's logic in botopink, its leaves in hand-written `.wat` | 544, 550, 560 | 2026-10-14. The bump heap stands until B-83 lands; B-30 closed as superseded |
| The Zig-built wasm runtime (440, 442's split, `$__std_sp` 447, the heap per task 448/449/522/542, two tables 454) | hand-written `.wat` leaves read by the compiler's `.wat` reader | 544, 550, 560 | What survives is 442 (3)'s rule |
| `snapshots/codegen/{beam,wat}/<target>/` | `snapshots/codegen/<target>/` | 434 (1) | |

## std

| Retired | Replaced by | Decisions | Since / note |
|---|---|---|---|
| `base64` (module) | `encoding` | 106 | Merged; the new name wins |
| `dict`, `sets`, `queue`, `order` | `collections.bp` (`Dict.empty()`, `Set.fromList(xs)`, …) | 106, 111 | |
| `crypto`, `hmac`, `content_hash` | `hash` | 106 | |
| std's `json.bp`; `pub mod json;` in `root.bp` | the `json` repository (`from "json"`) | 396 (1) | std knows nothing of JSON |
| `json.parse`, `json.stringify` | `decode`, `encode` | 336 | |
| `Json.Num(value: f64)` | `Int(value: i64)`, `BigInt(value: bigint)`, `Dec(value: Decimal)` | 332 (4) | |
| `testing/snapshots.bp` (`import {testing.snapshots} from "std"`) | `snap` (`import {assertAs} from "snap";`) | 391, 407 | The old import answers the plain unknown-module error |
| `Pair.of`, `first`, `second`, `swap`, `mapFirst`, `mapSecond`; `Function.*` statics | tuples (`p._0`, `val #(a, _) = p`); std's `functions.bp` | 738 | |
| `fetch(url)` and its `string` error | `fetch(Request(method: .Get, url: u))` answering `Async<Result<Response, HttpError>>` | 623 | |
| `io.random.bool()` | `coin()` | 250 | |
| `fs.openAsset`; `Asset.path`, `.bytes`, `.size`, `.hash`, `.text()`; `File.ofBytes`; `embed-text-not-utf8`, `embed-text-not-at-build`, `embed-open-needs-fs` | `Asset(link).open()` and `File`'s reads, each a `Result<…, FsError>` | 607 (2) | |
| A `string` error from `io.fs` | `FsError`, with `e.message()` | 540 (1), 563 | |
| A library's own copy of a std function (`clock.parseDuration`, `async.RetryPolicy`, `async.nextDelay`) | std's | 170 | |
| `$stringify` (a template marker) | `$N`, `$args` (on a method `$0` is `self`) | 164, 239, 795 | Refused in every template; `$self` too (`template-self-marker`) |

## Libraries and repositories

| Retired | Replaced by | Decisions | Since / note |
|---|---|---|---|
| jhonstart, jhonstart-html, -link, -forms, -test | `rakun-bpp` | 724 | Repositories archived, history kept by `git subtree add` |
| `jhonstart-styled` | merged into `rakun-bpp` (jhonstart's core) | 361 (3) | |
| styled | `rakun-style` | 724 | |
| emilia, jhonstart-emilia | `rakun-stylesheet` | 724 | |
| onze and its eight members; the `onze` CLI (`onze create-key`); `onze.json` | `rakun-ssr`; `rakun-ssr build`, `rakun-ssr create-key`; `rakun-ssr.json` | 724, 271, 224 | The mocking library lives as the archived repository's tag `mocking-lib-final` (507). `ONZE_KEY` keeps its name |
| dbcontext (a repository) | `rakun-data` (dbcontext + rakun-data) | 724, 398 | |
| erika; `erika "…"` | `query` (`botopink/query`); `` query @`…` `` | 724, 312, 577 (6) | |
| rakun-web, rakun-actuator | `rakun-service` | 724 | |
| `rakun-actuator-api`, `rakun-logging` | absorbed by the `rakun` core | 187 | |
| `rakun-starter-*` | — (removed): a program declares the packages it uses | 724 | |
| Each `*-test` package | its package's `testing/` module | 724 | |
| The `botopink/conformance` repository | `repository/botopink-lang/conformance/` | 467 | |
| `actions`, `http`, `log`, `routing`, `validation` inside the compiler | repositories of their own, ordinary dependencies | 326 | |
| onze's `@/` alias (`from "@/…"`) | `import {lib.db.findPost};` | 218 | |
| A library's `"entry"` | — (removed): a library has no entry | 733 | 2026-10-18. Refused, `manifest-entry-in-library` |
| `botopink.json`'s `files` | the tree; `src/internal/` is private | 703 | 2026-10-18. Refused once B-69 / B-75 land |
| A `dependencies` string array | the object form | 76 | |
| `"bppKinds"`; a decorator applied by file name | the decorator written in the header; the route table rakun-app generates | 285 | |
| A `.bpp` header opened by a first-line `---` | the header starts on the first line | 212 | |
| `JhonstartNode`, `Children` | `Node` (`import {Node} from "rakun-bpp";`) | 191, 223 | |
| A `children` field | the default slot, `<Slot />` | 193, 360 | |
| Astro's `prefix:name` directives (`client:load`, …) | annotations inside the tag (`#[clientLoad]`, …); `set:html={s}` → `{raw(s)}`, `set:text={s}` → `{s}`, `class:list={[…]}` → `class={classList([…])}` | 278 | |
| `markDynamic`, `rakun_ssr.erl`'s implicit mark | the hooks list read by `#[page]` | 186, 277 | |
| `pub val prerender`, the `output` key; Next's `dynamic`, `fetchCache` | `#[page]` reads the stage from the hooks list; `revalidate:`, `dynamicParams:`, `headers:` | 202, 290, 291 | |
| A `pages/` tree | `app/…/page.bp` or `page.bpp` | 203 | |
| `route: PageContext`, `paramsOf`, `StaticPath.data: Json`, `isPrerendered()` | `use params<P>()`, `use pageData<T>()`, `use request()`, `use response()` | 293, 291 | |
| A route handler exported by the build (`<outDir>/rss.xml`) | a page-kind file, prerendered | 222, 273 | |
| The `"signed"` island mode | `"sealed"` (default) or `"server"` | 224, 271, 272 | |
| `LocalKey<T>(name)` | `atom(…)` (cardume's `Atom<T>`) | 295 | |
| `ActionOutcome`, `ActionErrorCode`, `orError()` | `Result<T, ActionError>` | 303 | |
| rakun-app's action-id wrapper | `actions.id.deriveActionId` | 324 | |
| `#[service]`, `#[managed]`, the core's `#[repository]` on a type; `#[configuration]`, `#[bean]`; `#[httpExchange]`, `#[getExchange]`; `#[amqpListener]`, `#[kafkaListener]`, `#[redisListener]`, `#[streamListener]`, `#[listener]`; `#[restController]` | `#[component(…)]`, `rakun-data`'s `#[repository]` on a behavior, `#[provides]`, `#[httpClient(…)]`, `#[listen(…)]`, `#[controller]` | 318 | |
| `#[value("…")]`, `rkProp*`, string profiles | `#[config("<prefix>")]` typed records | 299 | |
| `rkRoutes`, `rkBeans`, `rkHooks`; `__rkMake_<T>` | registration through each marker's `compiler.init`; `T.make()` | 625 (1), 234 | |
| The `try*` store twins | one API answering `Result<T, StoreError>` | 304 | |
| rakun's four `Cookie:` readers, the three q-value parsers | `http`'s `cookie` and `accept` | 196 | |
| `Schema<T>`, `Codec<A, B>`, `schemas.*`, `checks.*` (public); the module-level functions named after a type | `#[validated]` and its members (`T.parse`, `T.decode`, …) | 306, 327 | |
| `StyledView`, `StyledPropertyView` | `Styleable.toStyled(self) -> Component<Styled>` | 661 | |
| `rakun-stylesheet`'s run-time entry points (`emilia(tokens)`, `className`, `cls`) | `#[emilia(…)]` on a tag; `comptime className(…)` | 369 | |
| snap's local `fsText` | `e.message()` | 563 | |
| rakun's SAML 2.0 ACS | — (retired for the milestone): `saml2/` answers 501 under a `deferred.md` row | 713 | |
| `onze-server` (a package of its own after 724) | `rakun-ssr-server`, erlang only, a row of 724's table | 762 | 2026-10-19; renamed by 165 s5 |
| `jhonstart-dom-test` (a package of its own after 724) | `rakun-bpp-dom-test`, commonJS only, a row of 724's table | 762 | 2026-10-19; renamed by 165 s5 |
| `snap.matchesRefused`, `matchesRefusedAt` (a loaded file's refusals as a snapshot) | — (removed): a conformance module prints each case's answer, `cell check` records it | 784, 786, 796 | 2026-10-20 |

## Process and files

| Retired | Replaced by | Decisions | Since / note |
|---|---|---|---|
| `specs/<version>/decisions-taken.md`, `decisions-taken-steps.md`, `decisions-pending.md`, `decisoes-pendentes.md` (one copy per milestone) | the four files at `specs/`, one each | — (the maintainer) | 2026-10-18; the closed milestones' copies were folded into the record |
| `decisions-taken.md` as the record | `decisions-taken-steps.md` (the record, append-only from 730) and `decisions-taken.md` (the rules in force, by subject) | 730 | 2026-10-18 |
| The tier directories (`1-botopink-lang/`, `2-libraries/`, `3-medium/`) | `machine-1/`, `machine-2/` | 433, meta `AGENTS.md` § Layout | 2026-10-17 |
| The track directories (`00-gate` … `10-specs`, `20-snap`) | the fronts' subdirectories, old ids resolved through the alias tables | 433 | |
| The one-gate-at-a-time lock | the machine-wide job pool (`scripts/gate.sh run`, `exec`) | 468, 469, 674 | 2026-10-11 |
| `scripts/restricted-targets.txt`, `scripts/known-red-libs.txt`, `--include-unsupported`, `expected-failures.txt`, `scripts/known-broken-examples.txt` | the manifests' `"targets"`; a red cell is red | 153, 154, 161 | |
| A `// targets:` line in a single-file suite | a project suite with a `botopink.json` naming `"targets"` | 536 | |
| `docs-check: skip` | `reject <error-id>` and `project` fences | 157 | |
| The `format-check` stage; `blockStatementSemicolon` | `botopink format` applied by the commit hook | 524 | 2026-10-14 |
| `cache/erlcheck`, `cache/beam` | the code cache's level A | 509 (2) | 2026-10-12 |
| `cache/results/lib-test` (a cached test result) | — (removed): no test result is cached | 510 | 2026-10-12 |
| `~/.cache/botopink-lsp`; any cache in `$HOME` or `$XDG_CACHE_HOME` | `.botopinkbuild/cache/` (`lsp/` for the server) | 225, 233 | |
| The windows CI row | — (removed) until the snapshot capture normalises CRLF and path separators | 158 | |
| `gate.sh --cold` inside a `--repo` / `--lang` worktree | the commit hook's warm gate; a cold gate runs in the main checkout's `repository/botopink-lang` | meta `AGENTS.md` § Worktrees (4b) | |
| One full cell per case, `<module>/cases/<case>/` (765) | `<module>/run/` and `<module>/refused/`, two packages of cases, and `<module>/cells/<case>/` for a case that cannot share one; `scripts/pack-cells.py` | 765, 779 | 2026-10-19; `cell new` still writes a 765 case, which `pack-cells.py apply` packs |
| A scratch location named in a spec (`.tasks/<name>` paths, `` `/tmp/` ``, a task branch, a worktree by name) | what remains and what blocks it | 484, `scripts/scratch-refs.py` | |

## Decision rows replaced, reversed or overtaken

The record keeps these rows as one line (or as the reason they lost force); read the successor instead.

| Retired | Replaced by | Decisions | Since / note |
|---|---|---|---|
| 145 | 384 and 306 | 145 | |
| 149 | 348 | 149 | |
| 179 | 432 | 179 | |
| 184 | 187 | 184 | |
| 209 | 247 | 209 | |
| 252, 514, 515 | 575 (1) | 575 | 514 as amended by 515; 586 overtaken by 575 (1) as well |
| 268, 371, 591 | 666 | 666 | |
| 269 | 354 and 379 | 269 | |
| 279 | 286 | 279 | |
| 288 | 213 and 289 | 288 | |
| 316, 678 | 714 | 714 | |
| 333 (B) | withdrawn | 731 (4) | |
| 353, 698 | 665 | 665 | |
| 366 | 369 | 366 | |
| 374, 387 | 388 | 388 | |
| 411 | 735 with 575 (4) | 735 | |
| 413 | 642 | 642 | |
| 419 | 592 (5), (6) | 728 | |
| 435 | 438 and 452 | 435 | |
| 439 | 452 | 439 | |
| 476 | 477 | 476 | |
| 551 | 581 (1) | 664 | |
| 564 | 576 (1) and 665 | 564 | |
| 612 | 643 (reversed the same day) | 612 | 2026-10-18 |
| 633 | 594 (1), (3) | 633 | |
| 634 | 575 (3), 606 (3) and 632 | 634 | |
| 635 | 603 with 310 | 635 | |
| 636 | 576 (2) and 616 | 636 | |
| 652 | 575 (6) | 652 | |
| 653 | 504 and 593 (1) | 653 | |
| 654 | 392 (1) | 654 | |
| 655 | 316 and 576 (8) | 655 | |
| 656 | 595 (3), (5) and 431 | 656 | |
| 657 | 326 | 657 | |
| 658 | 433 (1) | 658 | |
| 693 | 575 (1) | 693 | |
| 694 | 664 and 665 | 694 | |
| 727 | 576 (3), (11), 631, 697, 698 | 727 | |
| 728 | 592 (5), (6) and 680 | 728 | |
| 729 | 592 and 665 | 729 | |
| 784 (2)–(3), 786 (3) (`snap`'s `matchesRefused`, the suite's refused cases through `snap`) | 789 (4)–(5), 796 | 784, 786 | 2026-10-20 |

## How to use this page

A thread or a machine that meets a form of the "Retired" column in a README, a cell, a comment or a library's source
rewrites it to the "Replaced by" column; where the replacement is "— (removed)", it writes what the row says one writes
instead. A box or a step whose whole mechanism is retired (a catalogue query, a `@emit` registration, a linear-memory
helper) is closed, not respelled. History sentences, a decision's own text, a codemod's rule and a cell that tests the
refusal keep the old form. A retirement this page misses is added here in the commit that records its decision.
