# Front A — core-language test scenarios (compiler-core)

**Slug**: front-a-core
**Front territory** (edit ONLY here — disjoint from Fronts B/C):
`modules/compiler-core/src/**/tests/*.zig` + `modules/compiler-core/snapshots/**`.
**Scope**: type-inference, parse, comptime, and codegen-**snapshot** scenarios for the
current language, in current syntax (post effect-annotations · extension-discipline ·
module-system · expr-custom). Runtime *execution* (`run/*` on beam/wasm, scripts) belongs
to Front C; lib `.bp` tests belong to Front B.
**Status**: pending (test-audit)

> Tags + dead-syntax table: see [`../README.md`](../README.md). `[have]` = a test exists;
> `[gap]` = add it. Lines under `— net-new —` are gaps no prior spec covered. Record
> construction is the call form `Name(field: value)`.

---

## A1 · effects — `#[@result]` / `#[@future]` / `#[@generator]`
Source: `comptime/tests/effects.zig` (22) + codegen snapshots.
```
[have] parser  ---- #[@result]/#[@future]/#[@generator] before `fn`; effect on FnDecl
[have] parser  ---- #[@external(t,"m","s")] on a bodyless `declare fn` (stacked targets)
[have] infer   ---- #[@result] body may `throw`; throw unifies with E; wrong type → error
[have] infer   ---- #[@future] body may `await`; await unwraps T; await outside #[@future] → error
[have] infer   ---- annotation/return mismatch (#[@future] fn -> @Result) → clear error
[have] infer   ---- #[@<effect>] on an interface/bodyless decl (non-external) → impl-only error
[have] codegen/node ---- #[@future]→async function, #[@generator]→function*, #[@result]→plain fn
[have] codegen/erlang ---- effects eager-lower; @Result → {ok,_}/{error,_}
[gap]  codegen/beam ---- eager lowering on BEAM .S (snapshot parity)
[gap]  codegen/wasm ---- @Result → Ok/Error tag; future/generator limitation recorded
[gap]  gate    ---- no `*fn` remains in libs/std, examples, libs
# — net-new —
[gap]  infer   ---- an effect marker on a record/struct METHOD (not just a top-level fn)
[gap]  infer   ---- two markers on one fn (#[@result] + #[@future]) → conflict error
[gap]  infer   ---- a compound return @Future<@Result<T,E>> (await then unwrap) type-checks
[gap]  codegen/node ---- a #[@external] fn with NO target for the active backend → MissingExternalTarget
```
Example:
```botopink
#[@result] fn parse(n: i32) -> @Result<i32, string> {
  if (n < 0) { throw "negative"; }
  return n;
}
test "parse rejects negatives" { val r = parse(-1) catch "err"; assert r == "err"; }
```

## A2 · errors-result-option — `try`/`catch`, `throw`, `@Result`/`@Option`
Source: codegen snapshots (4 backends) + `comptime/tests/infer_errors.zig`.
```
[have] infer   ---- throw checks the enclosing #[@result] fn's E; nested fn uses its own; catch-handler throw too
[have] infer   ---- multiple throws all match E; `try` on a non-@Result → comptime error
[have] codegen/node ---- `try` unwraps Ok; catch literal fallback; catch lambda receives the error
[have] codegen/node ---- nested try/catch both lower to pattern match; independent temps
[have] codegen/erlang ---- try/catch → {ok,_}/{error,_} case clauses
[gap]  codegen/beam ---- try/catch snapshot parity; [gap] codegen/wasm if/else on Ok/Error tag
[have] comptime ---- Result.map/flatMap/unwrapOr/isOk/isError; map on Error skips; Option mirrors
[have] comptime ---- chain map().flatMap().unwrapOr() types end-to-end
# — net-new —
[gap]  infer   ---- a @Result/@Option as a record FIELD type checks + lowers
[gap]  comptime ---- `?.` optional chain yields an Option that unwrapOr resolves
[gap]  comptime ---- `val x = try f()` in expression position binds the unwrapped Ok value
[gap]  infer   ---- throw of an enum error variant unifies with E = that enum
```
Example:
```botopink
test "map on Error short-circuits" { assert parse(-1).map({ x -> x + 1 }).unwrapOr(99) == 99; }
record Cell { value: @Result<i32, string> }                 // net-new: @Result in a field
test "result-typed field" { assert Cell(value: parse(2)).value.unwrapOr(0) == 2; }
```

## A3 · pattern-matching — `case`, patterns, guards, exhaustiveness
Source: `comptime/tests/{variants,exhaustiveness}.zig` (33 + 9).
```
[have] parser  ---- case with literal / constructor / list / binding patterns
[have] infer   ---- enum unit + payload variants bind; nested Ok(Some(n)); guard typed as bool
[have] comptime ---- non-exhaustive → diagnostic; redundant arm reported
[have] infer   ---- list patterns `[]` / `[x]` / `[first, ..rest]` bind
[have] codegen/node ---- enum unit → tag check; payload → destructure
[have] codegen/erlang ---- case → `case…of`; unit → atom, payload → tagged tuple
[gap]  codegen/beam ---- is_tagged_tuple dispatch; [gap] codegen/wasm enum payload in linear memory
# — net-new —
[gap]  infer   ---- a wildcard `_` arm makes an otherwise-partial case exhaustive
[gap]  infer   ---- case over a string / int literal scrutinee (non-enum)
[gap]  infer   ---- nested record destructuring inside a pattern binds inner fields
[gap]  comptime ---- case as a `val` vs as the trailing expr type-check identically
```
Example:
```botopink
enum Shape { Circle(i32), Rect(i32, i32) }
fn area(s: Shape) -> i32 {
  return case s { Circle(r) -> r * r * 3, Rect(w, h) if w > 0 -> w * h, Rect(w, h) -> 0 };
}
test "case binds + guards" { assert area(Circle(2)) == 12; assert area(Rect(3, 4)) == 12; }
```

## A4 · generics-recursion-context
Source: `comptime/tests/infer_generics.zig` (17) + mutual-recursion/context specs.
```
[have] comptime ---- a generic fn call instantiates fresh vars; two calls at different types independent
[gap]  comptime ---- an inline `test {}` inside a generic module resolves (historic .generic gap)
[have] codegen/node ---- a generic fn at two call sites → one body, two typed calls
[have] infer   ---- forward reference + mutual recursion type-check; an unbound name still errors
[have] infer   ---- `use x` in -> @Context<Element,_> ok; in a non-@Context return → error; base mismatch → error
[have] infer   ---- inline `implement @Context` resolved; `implement Foo<A> for Bar<A>` resolves; `default fn` body checks
# — net-new —
[gap]  infer   ---- a generic RECORD/STRUCT instantiates at two concrete types
[gap]  infer   ---- recursion through a generic data type (Tree<T> sum) type-checks
[gap]  infer   ---- a generic fn return type inferred SOLELY from the call's usage context
[gap]  infer   ---- @Context composition across THREE hook layers stays Element-based
```
Example:
```botopink
record Box<T> { item: T }
fn unbox<T>(b: Box<T>) -> T { return b.item; }
test "generic record at two types" { assert unbox(Box(item: 7)) == 7; assert unbox(Box(item: "hi")) == "hi"; }
```

## A5 · extension-dispatch — `implement`/`extend` discipline
Source: `comptime/tests` + extension-discipline; commonJS codegen snapshots.
```
[have] infer   ---- inherent always available; interface-covered impl resolves; extra/missing method → error
[have] infer   ---- `extend Type {}` with no interface → extendRequiresInterface
[have] infer   ---- local implement: `donald.fly()` resolves with NO activation; bare local `Name*;` → redundantActivation
[have] infer   ---- two activated impls of one method → ambiguous; qualified call needs no activation
[have] infer   ---- `import { Name* } from "./m"` activates cross-module; without `*` → error + hint
[have] codegen/node ---- `donald.fly()` → `PatoNada.fly(donald)`; cross-module → owner's `Type.method(recv)`
[gap]  codegen/{erlang,beam,wasm} ---- cross-module extension dispatch (LOCAL-only today — record or close)
# — net-new —
[gap]  infer   ---- precedence: inherent vs implemented same-name (win or clear conflict)
[gap]  infer   ---- implement an interface for a PRIMITIVE (string / i32) and dispatch
[gap]  infer   ---- chained `x.a().b()` where both are extension methods resolves each
[gap]  infer   ---- two imported libs activating the SAME method name → cross-module ambiguity
```
Example:
```botopink
interface Swim { fn swim(self: Self) -> string; }
record Duck { name: string }
PatoNada implement Swim for Duck { fn swim(self: Self) -> string { return self.name; } }
test "local implement, no activation" { assert Duck(name: "donald").swim() == "donald"; }
// PatoExtra extend Duck { … }  → expect extendRequiresInterface
```

## A6 · module-system — `mod` / `pub mod`
Source: parser tests (the pilot example lives in Front B / `examples/modules`).
```
[have] parse   ---- `pub mod foo;` / `mod foo;` parse; `mod` in a fn body errors
[have] resolve ---- `mod shapes;`→shapes/mod.bp; `mod circle;`→shapes/circle.bp; both present → ambiguous error
[have] visib   ---- import through a private `mod` fails (names the segment); pub mod chain imports across packages
[gap]  build   ---- a `.bp` not reached by any `mod` path is reported orphaned
# — net-new —
[gap]  resolve ---- a 3+-level nested folder package resolves through the full mod chain
[gap]  resolve ---- two sibling modules each defining a same-named symbol do NOT collide
[gap]  visib   ---- a `pub mod` re-exporting a TYPE used in another package's signature works
[gap]  build   ---- a circular `mod` reference is detected/reported (not infinite)
```
(Multi-folder build+run scenarios are Front C; the parser/resolve/visib checks are here.)

## A7 · expr-templates — `@Expr<T>`
Source: `comptime/tests/templates.zig` (32).
```
[have] lexer   ---- `"a ${x} b"` → text/expr/text; `\${` literal
[have] parser  ---- `comptime q: @Expr<string>`; tagged single-line + `"""…"""` parse + round-trip
[have] comptime ---- expr param unevaluated + typed; q.lookup hit→Binding, miss→Option none
[have] comptime ---- q.failAt points the diagnostic INSIDE the `"""…"""` in the caller
[have] comptime ---- hygiene; value lifting; bounded splice ok/violation; memoized by scope
# — net-new —
[gap]  comptime ---- a template fn called with a VARIABLE reference (not a literal) captures it
[gap]  comptime ---- a nested template (template call inside a template body) expands once each
[gap]  comptime ---- an empty template (`name ""`) handled gracefully (no crash)
[gap]  comptime ---- a splice that expands to a TYPE error reports at the splice site, not the def
```

## A8 · backends-parity — codegen SNAPSHOTS (execution is Front C)
Source: `codegen/{node,erlang,beam,wasm}` (~228 each).
```
[have] codegen/* ---- array map/filter/len chain lowers on all four (snapshot)
[have] codegen/node ---- `[1,2].map(f).len()` literal receiver reaches codegen (F1/F2)
[have] codegen/* ---- `u?.v?.w` optional chain lowers (F4 `?.`)
[have] codegen/{node,beam} ---- prim-method dispatch (string contains→includes; beam prim-methods)
[gap]  codegen/* ---- `Array.range(0,3)` → host external (needs companion .mjs/.erl) — open
# — net-new —
[gap]  codegen/* ---- string interpolation "${a}-${b}" lowers consistently on every backend (snapshot)
[gap]  codegen/* ---- structural record equality vs array `==` (ref-eq) snapshots pin the difference
```

## Notes
- This front is pure compiler-core: Zig `test {}` + `.snap.md`. No `.bp` lib edits, no
  `modules/language-server` or CLI edits → never collides with Front B or C.
- beam/wasm `run` parity + the `case…of` erlang reds are **Front C** (execution scripts).
