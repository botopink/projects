# Capability inventory — what the language has, and what `tests/language/**` pins

Every row is a language capability that **exists today**: it is defined by a compiler test suite, by
`libs/std`, by `docs.md`, or by one of the five libraries. The last column says whether
`tests/language/**` — front 15's botopink-level suite — pins it.

**Measured at** `botopink-lang` `1193d3c` (2026-09-17), meta `becb30d8`. Toolchain: node v25.8.0,
OTP 29. Every "verified" claim in this document was produced by running the program through
`zig-out/bin/botopink` (`check` / `run` / `test`) in a scratch project shaped exactly like
[`run.sh`](../../../repository/botopink-lang/tests/language/run.sh)'s — `botopink.json` +
`src/main.bp`, or `botopink.json` + `test/<n>.bp`.

**Coverage legend**

| Mark | Meaning |
|---|---|
| **pinned** | at least one cell in `tests/language/**` exercises it and passes today |
| **pinned-future** | a cell exists but is written for decision 8 and is an expected failure; today's behaviour is **not** pinned |
| **none** | no cell in `tests/language/**` touches it |

The distinction between **pinned** and **pinned-future** is the whole story of this front's first
delivery: the suite was written against decision 8, so nearly every `case` cell is an expected
failure and **today's working `case` has no botopink-level test at all**.

---

## 1. Declarations

| # | Capability | Surface defined in | Coverage |
|---|---|---|---|
| D1 | `type Name(fields)` record, body optional | `parser/tests/declarations.zig`; `libs/std/src/dict.bp`, `url.bp`, `regex.bp` | **pinned** (`test/case_arms.bp` declares one; `run/case_values.bp`) |
| D2 | `type Name { Variant, Variant(f: T) }` enum | `parser/tests/declarations.zig`; `libs/std/src/order.bp`, `unicode.bp` | **pinned** (`test/case_arms.bp`'s `Order`) |
| D3 | Enum **sections**, nested, with numeric leaves (`Color { Red { 100, 500 } }`) and dot-path values (`.Color.Red.__500`) | `parser/tests/declarations.zig` (ES1/ES2); `emilia/src/tokens.bp` | **none** |
| D4 | §5.3b — a section is a type named by its path (`Token.Text`), and matching into a section is a refinement | decision 8 §5.3b; 06 N28 | **none** |
| D5 | `behavior Name { … }`, abstract members | `parser/tests/declarations.zig`; `libs/std/src/primitives.bp` | **none** |
| D6 | `behavior … extends A, B` | `parser/tests/declarations.zig`; `primitives.bp` (`behavior Signed extends Integer`) | **none** |
| D7 | `default fn` inside a `behavior` (interface default method) | `primitives.bp` (`default fn clamp`) | **none** |
| D8 | `implement B` on a record and on an enum, multiple behaviors | `parser/tests/declarations.zig`; `builtins.d.bp` (`type External implement Annotation`) | **none** |
| D9 | `declare fn` (bodyless, host-backed or delegate) | `parser/tests/declarations.zig`; every std FFI module | **none** |
| D10 | Record/variant field **defaults** and `fn` parameter defaults | `parser/tests/declarations.zig`; `builtins_fns.d.bp` (`message: string = "not implemented"`) | **none** |
| D11 | `pub` on `val`/`fn`/`type`/`behavior`/`mod` | `imports.zig`; everywhere | **none** (every cell is single-module, so `pub` is never observable) |
| D12 | Default **generic** parameters (`<T, E = any, C = void>`) | `comptime/tests/generic_defaults.zig`; `builtins.d.bp` (`Iterator<T, E = any, C = void>`) | **none** |

## 2. Generics

| # | Capability | Surface defined in | Coverage |
|---|---|---|---|
| G1 | Generic fn `f<T>(…)`, generic `type Box<T>`, fresh instantiation per call | `comptime/tests/infer_generics.zig`; `libs/std/src/dict.bp`, `queue.bp`; `erika/src/erika.bp` (`Query<T>`) | **none** |
| G2 | A generic method changing the type argument (`map<U>(…) -> Self<U>`) | decision 8 §1.2; `erika` `select<U>`, `Dict.mapValues<W>` | **none** |
| G3 | §1.1 — a written generic type carries **all** its arguments | decision 8 §1.1 → 06 N18 | **none** — and **accepted today**: `fn get(b: Box) -> i32` passes `check` (verified) |
| G4 | §1.2 — `Self` vs `Self<T>` | decision 8 §1.2 → 06 N18 | **none** |
| G5 | §1.3 — explicit type arguments at a use (`first<string>([])`) | decision 8 §1.3 → 06 | **none** |
| G6 | §1.4 — where a type argument is decided; the `unknown` warning | decision 8 §1.4 → 06 | **none** |
| G7 | `comptime T: type` and constrained meta-kinds (`comptime T: type \| Numeric`) | `parser/tests/declarations.zig`; `builtins.d.bp` (`comptime _: type`) | **none** |

## 3. Functions, closures, effects

| # | Capability | Surface defined in | Coverage |
|---|---|---|---|
| F1 | Lambda `{ x -> … }`, multi-param, as argument and as return value | `codegen/tests/features.zig`; all five libraries | **partial** — lambdas appear inside `loop` cells only; never as a parameter or a return |
| F2 | A closure reassigning an outer `var` threads the value out | `codegen/tests/control_flow.zig`; `Dict.fold`, `Dict.merge` | **pinned** for `loop` bodies (`test/loop_*.bp`); **none** for `forEach`/`map` bodies |
| F3 | A returned closure keeps its capture (`adder(3)` then `f(4)`) | `codegen/tests/features.zig`; `rakun/src/bootstrap.bp` | **none** |
| F4 | `#[@result]` + `-> @Result<T, E>`, bare `return`/`throw`, `catch`, `try` | `comptime/tests/effect_result.zig`; `libs/std/src/{fs,json,asserts}.bp`; `libs/std/test/result_test.bp` | **none** |
| F5 | `#[@future]` + `-> @Future<T>` and `await` | `comptime/tests/effect_future.zig`; `libs/std/src/http.bp`; `emilia/src/emilia.bp` | **none** |
| F6 | `#[@iterator]` / `#[@generator]` / `#[@asyncGenerator]` + `yield`, labelled `yield :label` | `comptime/tests/effect_generator.zig` | **none** |
| F7 | `@Context<Host, T>` and the `use` prefix (`val c = use state(0)`) | `codegen/tests/features.zig`; `jhonstart/src/hooks.bp` | **none** |
| F8 | Two effect markers on one fn rejected (R5); the annotation without its wrapper and the wrapper without its annotation (§9) | `parser/tests/effect_rejections.zig`; decision 8 §9 | **none** |
| F9 | `val assert Ok(n) = …` — decision 4 / §9's fatal-assert binding | decision 8 §9; `docs.md` | **none** — and it **crashes the compiler** today (see the gap analysis, G-1) |
| F10 | Trailing parameter defaults actually applied at a call | `docs.md`; 06 N1 | **none** — and **not implemented**: `connect("a")` on a 3-parameter fn with 2 defaults is "expects 3 argument(s), got 1" (verified) |

## 4. Comptime, templates and sub-languages

| # | Capability | Surface defined in | Coverage |
|---|---|---|---|
| C1 | `comptime` **value** parameter, specialised per call site | `codegen/tests/comptime.zig` | **none** |
| C2 | `comptime q: @Expr<string>` — the argument arrives unevaluated; call form `sql "SELECT 1"` and `sql """…"""` | `comptime/tests/templates.zig`; `erika`, `jhonstart/src/html.bp`, `examples/yamlconf` | **none** |
| C3 | `@Expr` methods: `.parts()`, `.text()`, `.build()`, `.lookup()`, `.failAt()` | `comptime/tests/templates.zig`; `erika/src/erika.bp` | **none** |
| C4 | `@ExprCustom<T>` + `q.custom(root, …)` + `CustomNode` (the LSP-visible sub-language AST) | `erika/src/erika.bp`, `jhonstart/src/html.bp` | **none** |
| C5 | `@expr(value)` / `@code("…")` — lift a comptime value back into code | `codegen/tests/comptime.zig`; `examples/yamlconf` | **none** |
| C6 | `val x = comptime <expr>` folding | `comptime/tests/eval_pipeline.zig` | **none** |
| C7 | Type-manipulation builtins `@typeInfo`, `@TypeOf`, `@makeRecord`, `partial`, `omit`, `pick`, `@Field` | `comptime/tests/builtins_typeinfo.zig` | **none** |
| C8 | Comptime **loop unrolling** and `if`/`case` folding in a specialised body | `codegen/tests/comptime.zig` | **none** |

## 5. Decorators and annotation processors

| # | Capability | Surface defined in | Coverage |
|---|---|---|---|
| A1 | A fn whose first parameter is `comptime _: @Decl` is a decorator; `#[name]` / `#[name(args)]` applies it | `comptime/tests/decorators.zig`; `onze/src/onze.bp`, `rakun/src/decorators.bp` | **none** |
| A2 | `@Decl` reflection: `decl.kind`, `decl.name`, `decl.fields`, `decl.methods`, `decl.variants`, `decl.annotations` | `comptime/tests/decorator_invocation.zig`; `rakun` reads `#[value("k")]` off a field and the verb off a method | **none** |
| A3 | `decl.fail(msg)` / `decl.failAt(span, msg)` — a located comptime diagnostic | `comptime/tests/decorator_invocation.zig` | **none** |
| A4 | `@emit("<source>")` splices a new top-level declaration, referenceable later | `comptime/tests/decorator_invocation.zig`; `onze` `#[mock]`, every `rakun` marker | **none** |
| A5 | Decorator on a `behavior` member and on a record field | `comptime/tests/decorators.zig`; `jhonstart`, `rakun` | **none** |
| A6 | Plain annotations that are not processors (`#[inline]`, `#[target(.erlang)]`, `#[derive(Eq)]`) | `parser/tests/declarations.zig` | **none** |

## 6. Host externals

| # | Capability | Surface defined in | Coverage |
|---|---|---|---|
| X1 | `#[@External.Node(template)]` / `#[@External.Erlang(module, symbol)]` on a `declare fn`, one per backend | `codegen/tests/externals.zig`; all of `libs/std` (353 occurrences) | **none** |
| X2 | Positional markers `$0`, `$1`, `$args` over the declared parameters, `self` included (§8, decision 5) | `parser/tests/declarations.zig`; `primitives.bp`, `builtins.d.bp` | **none** |
| X3 | Keyword form `#[@External.Erlang(module: "lists", method: "reverse(self)")]` and `inline: true` | `parser/tests/declarations.zig` | **none** |
| X4 | Multi-line inline templates (`"""(fun(N__) -> … end)($0)"""`) | `emilia`, `onze`, `libs/std/src/{http,json,asserts}.bp` | **none** |
| X5 | "No target for the active backend" is a located error | `codegen/tests/externals.zig`; the `MissingExternalTarget` unowned item | **none** |
| X6 | `#[@external(node, "…")]` in lower case must be an error | fronts.md § unowned items | **none** — and **accepted silently today**, binding no host (verified) |

## 7. Modules

| # | Capability | Surface defined in | Coverage |
|---|---|---|---|
| M1 | `pub mod x;` / `mod x;` sibling module, `mod.bp` folder index | `parser/tests/imports.zig`; `libs/std/src/root.bp`; `examples/modules` | **none** — structurally impossible in the current layout (one file per cell) |
| M2 | `import { A, B } from "module"`, dotted paths, aliases, `X*` activate | `parser/tests/imports.zig` | **none** |
| M3 | `pub default mod` / `pub default fn` (package handle: `import erika` calls `erika "…"`) | `parser/tests/imports.zig`; `erika/src/root.bp`, `emilia/src/root.bp` | **none** |
| M4 | `from "std"` — the embedded std package, per-module | `codegen/tests/std_package.zig`; `examples/stdlib-tour` | **none** |
| M5 | A git dependency in `botopink.json` and `from "<lib>"` | `examples/generic-loader-binding` | **none** |
| M6 | `.d.bp` declaration modules shipped through `botopink.json` `files`, outside the `mod` tree | `jhonstart/src/router.d.bp`, `rakun/src/rakun.d.bp` | **none** |

## 8. Pattern matching, `case`, `loop`

| # | Capability | Surface defined in | Coverage |
|---|---|---|---|
| P1 | `case` with **arrow arms** — `case o { Lt -> -1; Eq -> 0; _ -> 1; }` — today's working syntax | `parser/tests/expressions.zig`; `libs/std/src/{order,unicode}.bp`; `emilia` | **none** — see the gap analysis, G-3 |
| P2 | §5.1 `Pattern { body }` arms, `{ n -> … }` whole-value binding | decision 8 §5 → 06 N22 | **pinned-future** (6 `test/` + 1 `run/` + 9 `reject/` cells, all expected failures) |
| P3 | List patterns `[]`, `[first, ..rest]`; or-patterns `2 \| 4 \| 6`; guard clause `x if x > 0` | `parser/tests/expressions.zig` | **none** |
| P4 | Exhaustiveness checking (missing variant, unreachable arm, duplicate arm) | `comptime/tests/exhaustiveness.zig` | **pinned-future** (`reject/case_missing_variant.bp` etc.) |
| P5 | Narrowing: null-check binding `if (x) { n -> … }`, variant narrowing, `assert` narrowing | `comptime/tests/narrowing.zig`; `docs.md` | **none** |
| P6 | `loop (xs)`, `loop (xs, 1..)`, `loop (0..n)`, `loop (cond)`, `loop { … break; }` | decision 8 §10; `codegen/tests/control_flow.zig` | **pinned** (5 `test/` cells, all passing on both targets) |
| P7 | `break <value>` — the loop as an expression | decision 8 §10; README scenario list | **none** — the README lists the scenario, `test/loop_break.bp` does not contain it (see G-4) |
| P8 | `continue` | `codegen/tests/control_flow.zig` | **none** |
| P9 | `yield` inside a `loop` (comprehension-style accumulation) | `codegen/tests/control_flow.zig` | **none** |

## 9. Types, values, operators

| # | Capability | Surface defined in | Coverage |
|---|---|---|---|
| V1 | Tuples `#(a, b)`, nested, in arrays, positional `.0` **and** `._0` | `parser/tests/destructuring.zig`; `libs/std` uses `._0`, the suite uses `.1` | **pinned** (`test/tuple_construct.bp`, `tuple_nested.bp`) — but only the `.N` spelling |
| V2 | §6 tuple **labels** T1–T5 | decision 8 §6 | **pinned** (`test/tuple_labels.bp`, passing) |
| V3 | T6 — run-time equality is positional | decision 8 §6 | **pinned-future** on commonJS (`==` compares references) |
| V4 | A labeled tuple element of **function** type called through its label (`c.bump(8)`) | fronts.md § unowned items; `jhonstart/src/hooks.bp` (`reducer` returns `#(state, dispatch)`) | **none** — and broken on commonJS and erlang (verified) |
| V5 | `?T` optional (the only optional spelling — `Option<T>` is **rejected**), `?.` chaining | `builtins.d.bp:58`; `libs/std/test/primitives_test.bp` | **none** |
| V6 | `unknown` (§2) and union types `A \| B` (§3), `is` (§4) | decision 8 §2–§4 → 06 N19–N21 | **pinned-future** (`test/case_unknown.bp`, `case_exhaustive.bp`) |
| V7 | String interpolation `"hi ${name}!"` | `codegen/tests/values.zig`; `docs.md` | **none** (unused anywhere in std/examples too) |
| V8 | Pipe operator `\|>` | `comptime/tests/types.zig`; `docs.md` | **none** (unused anywhere in std/examples too) |
| V9 | Array/string primitive methods (`filter`/`map`/`fold`/`join`/`slice`/`at`/`indexOf`, `toUpperCase`/`split`/`trim`/`startsWith`) | `primitives.bp`; `codegen/tests/features.zig` | **none** — and `"abc".toUpperCase()` **does not compile on erlang** (verified) |
| V10 | `throw` / `try` / `catch` as a tail operator (`getPerson() catch return null`) | `parser/tests/expressions.zig`; `codegen/tests/control_flow.zig` | **none** |
| V11 | §7 — one source-shaped formatter per type, identical on every backend | decision 8 §7 | **pinned-future**, one row only (`run/tuple_print.bp`) — see G-2 |
| V12 | `Display` used by `@print`, including nested | decision 8 §7 | **none** — and not implemented (verified) |
| V13 | `@panic`, `@todo`, `@block`, `assert cond, "msg"` | `codegen/tests/builtins.zig`; `libs/std/src/asserts.bp` | **partial** (`assert` is the suite's own mechanism; the two-argument form and `@panic` are untouched) |

## 10. Backends

`botopink test` and `botopink run` execute on **commonJS** and **erlang** only; `beam` and `wasm`
build but do not run, so `tests/language/**` runs on two of the four backends by construction.

| Backend | Reachable from `tests/language/**` | Codegen fixtures elsewhere |
|---|---|---|
| commonJS | yes (`test/`, `run/`) | `snapshots/codegen/commonJS/` — 312 |
| erlang | yes (`test/`, `run/`) | `snapshots/codegen/erlang/` — 312 |
| beam | **no** | `snapshots/codegen/beam/` — 311 |
| wasm | **no** | `snapshots/codegen/wasm/` — 311 |
| typescript (`--typescript` `.d.ts`) | **no** | `codegen/tests/dts_skips_templates.zig` |

Decision 8's run-time half is 01 step 6 on **all four** backends; the language suite can only witness
two of them. That is by design (the README says so), but it means every cross-backend claim this
suite makes is a claim about half the matrix.

---

## What the docs promise that nothing exercises

Read from `docs.md` and cross-checked against `libs/std/**`, `examples/**` and the five libraries.

| Promised in `docs.md` | Status |
|---|---|
| `val assert Ok(value) = result catch throw Error(…)` | **crashes the compiler** (G-1) |
| `if (x) { n -> @print(n); }` optional-unwrap sugar | works (verified), used nowhere in std/examples, pinned nowhere |
| List patterns `[first, ..rest]`, or-patterns `Red \| Green` | parser tests only; used nowhere in std/examples; pinned nowhere |
| `assert x is Some(n)` narrowing | `is` does not parse today (06 N21) |
| Pipe operator `\|>` | works (verified), used nowhere in std/examples, pinned nowhere |
| String interpolation `"hi ${name}"` | works (verified), used nowhere in std/examples, pinned nowhere |
| `comptime { … break x * 2 }` block form | only the **parameter** form (`comptime n: i32`) is used anywhere |
| `@field(...)` and `@emit(...)` builtins | `@emit` works (verified); `@field` is declared in `builtins.d.bp` and invoked nowhere |
| `#[@Host]` annotation | declared in `builtins.d.bp`, applied nowhere |
| `External.Wasm` / `External.Typescript` templates | declared in the `External` enum, no real template anywhere |
| `Option<T>` as a named type | **rejected by design** — `builtins.d.bp:58` says `?T` is the only spelling. Decision 8 §1.3, §4.2, §5.1 and §5.3 write `Option<i32>.None` and `Option.Some(v)` throughout; `val z = Option<i32>.None;` is "unbound variable 'Option'" today (verified). Either decision 8 introduces `Option` as a real type or its examples need rewriting to `?T` — **unresolved, flagged for the maintainer** |
