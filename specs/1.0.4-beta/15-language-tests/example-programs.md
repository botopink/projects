# Example programs — one cell per gap

Every program below was run through `zig-out/bin/botopink` at `botopink-lang` `1193d3c`
(2026-09-17, node v25.8.0, OTP 29), in a scratch project shaped exactly like
[`run.sh`](../../../repository/botopink-lang/tests/language/run.sh)'s: a `botopink.json` with
`targets: ["commonJS", "erlang"]`, plus `test/<n>.bp` for a `test/` cell or `src/main.bp` for a
`run/` or `reject/` cell.

**Nothing here has been added to the repository.** Each block is the proposed source; the front that
lands it copies it into `tests/language/` and adds the `expected-failures.txt` lines given with it.

**Status legend**

| Mark | Meaning |
|---|---|
| **green** | passes on both commonJS and erlang today — a pure regression net, no expected-failure line |
| **split** | passes on one target, fails on the other — one expected-failure line, one owner |
| **red** | fails on both — the cell pins decision 8 ahead of the implementation, listed with its owner |
| **pending** | could not be verified here; says why |

Programs are drawn from real usage: `libs/std/src/{dict,order,http,json,fs}.bp`,
`libs/std/test/result_test.bp`, `onze/src/onze.bp`, `rakun/src/decorators.bp`, `erika/src/erika.bp`,
`jhonstart/src/hooks.bp`, `emilia/src/emilia.bp`, cut down to a minimal cell.

---

## 1 · `test/effect_result.bp` — §9 `#[@result]` · **green** · gap G-5

Cut from `libs/std/test/result_test.bp` and `libs/std/src/json.bp`. Pins §9's core rule: inside a
`#[@result]` fn a bare `return` is the success value and `throw` is the error — no `Ok(…)`/`Err(…)`
constructor — plus `catch`, `try … catch`, and the `map`/`flatMap` surface the std suite already
depends on.

```botopink
//// §9 — `#[@result]` plus `@Result<T, E>`: a bare `return` is the success
//// value, `throw` the error, `catch` unwraps with a fallback.

#[@result]
fn parse(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}

#[@result]
fn half(n: i32) -> @Result<i32, string> {
    if (n % 2 != 0) { throw "odd"; };
    return n / 2;
}

test "§9 a bare return is the success value" { assert (parse(7) catch -1) == 7; }
test "§9 throw makes the error" { assert (parse(-1) catch -1) == -1; }
test "§9 catch after a try unwraps" { assert (try parse(4) catch 0) == 4; }
test "§9 map over Ok transforms the payload" { assert parse(5).map({ x -> x + 1 }).unwrapOr(0) == 6; }
test "§9 flatMap short-circuits on the first error" { assert parse(7).flatMap({ x -> half(x) }).unwrapOr(-1) == -1; }
```

**Measured:** 5 passed / 0 failed on commonJS **and** erlang. No expected-failure line.

**Why it matters.** `#[@result]` is the one effect `libs/std` genuinely runs (`fs`, `json`,
`asserts`) and 06 owns every file that types it. This is the acceptance test that says the effect
still works after 06 moves `src/comptime/{infer,transform}.zig`.

## 2 · `test/effect_iterator.bp` — §9 `#[@iterator]` · **split** · gap G-5

```botopink
//// §9 — `#[@iterator]` plus `@Iterator<T>`: `yield` produces the elements and
//// `loop (gen)` consumes them.

#[@iterator]
fn upto(n: i32) -> @Iterator<i32> {
    var i = 0;
    loop (i < n) { yield i; i = i + 1; };
}

test "§9 an iterator yields its elements in order" {
    var acc = "";
    loop (upto(4)) { x -> acc = acc + x.toString(); };
    assert acc == "0123";
}

test "§9 an empty iterator runs no iteration" {
    var runs = 0;
    loop (upto(0)) { x -> runs = runs + 1; };
    assert runs == 0;
}
```

**Measured:** commonJS 2 passed / 0 failed. **erlang 0 passed / 2 failed** — the program compiles and
then raises `{error,{case_clause,4}}` and `{error,{case_clause,0}}` inside the generator protocol.

```
erlang   | test/effect_iterator.bp | 01 step 6 | `#[@iterator]` is not lowered on erlang: the generator protocol raises case_clause at run time
```

**Why it matters.** This is the failure mode the milestone rule "erlang is not the oracle" exists
for: the erlang backend accepts the program and answers wrongly at run time, so no compile-time gate
sees it. `#[@iterator]` is also the effect front 13's jhonstart work is gated on.

## 3 · `test/comptime_template.bp` — comptime parameters and `@Expr` · **green** · gap G-6

Cut from `examples/yamlconf` and the call shape `erika`/`jhonstart` use.

```botopink
//// Comptime parameters and `@Expr<T>` templates: the argument arrives
//// unevaluated, and a `comptime` value parameter folds at the call site.

pub fn sql(comptime q: @Expr<string>) -> @Expr<string> { return q; }

fn twice(comptime n: i32) -> i32 { return n * 2; }

test "an @Expr parameter captures the call-site text" { assert sql "SELECT 1" == "SELECT 1"; }
test "a multi-line template is captured whole" { val t = sql """ab"""; assert t == "ab"; }
test "a comptime value parameter folds at the call site" { assert twice(21) == 42; }
test "a comptime val folds" { val x = comptime 10 + 5; assert x == 15; }
```

**Measured:** 4 passed / 0 failed on both targets. No expected-failure line.

**Note for whoever writes more of these.** `(sql """ab""").length` is `error: Unexpected token` — a
template call needs a `val` intermediate before a method. That is why the second test binds `t`.

## 4 · `test/decorator_emit.bp` — decorators, `@Decl`, `@emit` · **green** · gap G-6

Cut from `onze/src/onze.bp`'s `#[mock]` and `rakun/src/decorators.bp`'s `#[component]`, reduced to
the three mechanisms they share: recognition (`comptime _: @Decl`), reflection (`decl.kind`,
`decl.name`, `decl.fail`) and synthesis (`@emit`).

```botopink
//// Decorators and annotation processors: a fn whose first parameter is
//// `comptime _: @Decl` is a decorator; `#[name]` applies it; the body reflects
//// over the declaration and `@emit` splices a new top-level declaration.

fn wire(comptime decl: @Decl) {
    @emit("pub fn wiredSize() -> i32 { return 99; }");
    if (decl.kind != DeclKind.Type) { decl.fail("#[wire] must annotate a type"); }
}

#[wire]
type UserService(name: string)

test "@emit splices a top-level declaration" { assert wiredSize() == 99; }
test "the decorated type is unchanged" { assert UserService(name: "a").name == "a"; }
```

**Measured:** 2 passed / 0 failed on both targets. No expected-failure line.

**Note.** The `if` must be **last**. A bare `if` (no `else`) followed by another statement in a
decorator body is `error: Unexpected token` — writing `@emit` after the guard, the natural order, does
not parse. `rakun/src/decorators.bp` has the same ordering and says so in a comment. Worth a
`reject/` cell of its own once the maintainer decides whether that restriction stays.

## 5 · `test/external_host.bp` — §8 host externals · **green** · gap G-7

```botopink
//// §8 — a host-backed `declare fn`: one `#[@External.<Target>]` per backend,
//// positional `$0`/`$1` markers over the declared parameters.

#[@External.Node("Math.max($0, $1)")]
#[@External.Erlang("erlang", "max")]
declare fn hostMax(a: i32, b: i32) -> i32;

#[@External.Node("($0).toUpperCase()")]
#[@External.Erlang("string", "uppercase")]
declare fn hostUpper(s: string) -> string;

test "§8 a two-target external answers the same on every backend" { assert hostMax(2, 7) == 7; }
test "§8 positional markers follow the declared parameters" { assert hostUpper("ab") == "AB"; }
```

**Measured:** 2 passed / 0 failed on both targets. No expected-failure line.

**Why it matters.** 353 `#[@External.…]` sites in `libs/std` alone, and decision 5's `$0`/`$args`
numbering was re-decided during this milestone. Nothing at the botopink level says the numbering is
still right.

## 6 · `reject/external_lowercase_target.bp` — §8 · **red** · gap G-7

```botopink
//// §8 — an external target is `External.<Target>`; a lower-case target binds
//// no host and must be a located error, not silence.
#[@external(node, "console.log($0)")]
declare fn hostLog(msg: string);

pub fn main() { hostLog("hi"); }
```

`.expect`:
```
external target
3:3
```

**Measured:** `botopink check` exits **0**. The program type-checks, binds nothing, and would fail at
run time with an undefined symbol.

```
*        | reject/external_lowercase_target.bp | 06 | a lower-case `@external(node, …)` is accepted silently and binds no host (fronts.md § unowned items)
```

## 7 · `run/print_formatter.bp` — §7 the formatter table · **red** · gap G-2

```botopink
//// §7 — one formatter per type, source-shaped, the same text on every backend.

type Point(x: i32, y: i32)
type Shape { Square(side: i32), Nothing }

pub fn main() {
    @print("hi");
    @print(5.0);
    @print(true);
    @print([1, 2]);
    @print(["a", "b"]);
    @print(#(1, "a"));
    @print(Point(x: 1, y: 2));
    @print(Shape.Square(side: 4));
    @print(Shape.Nothing);
}
```

`run/print_formatter.out`:
```
hi
5.0
true
[1, 2]
["a", "b"]
#(1, "a")
Point(x: 1, y: 2)
Shape.Square(side: 4)
Shape.Nothing
```

**Measured** — neither target produces it, and they differ from each other:

| Line | required | commonJS | erlang |
|---|---|---|---|
| 2 | `5.0` | `5` | `5.0` |
| 4 | `[1, 2]` | `[1,2]` | `[1,2]` |
| 5 | `["a", "b"]` | `["a","b"]` | `["a","b"]` |
| 6 | `#(1, "a")` | `#(1,"a")` | `#(1,"a")` |
| 7 | `Point(x: 1, y: 2)` | `Point { x: 1, y: 2 }` | `#{x => 1,y => 2}` |
| 8 | `Shape.Square(side: 4)` | `{ tag: 'Square', side: 4 }` | `{'Square',4}` |
| 9 | `Shape.Nothing` | `Nothing` | `'Nothing'` |

```
commonJS | run/print_formatter.bp | 01 step 6 | §7 formatter: f64 prints without a decimal part, arrays/tuples without spaces, records and variants in host shape
erlang   | run/print_formatter.bp | 01 step 6 | §7 formatter: arrays/tuples without spaces, records as maps, variants as raw tags
```

This cell **replaces** the scope of `run/tuple_print.bp`, which pins one row of the same table; keep
both or fold `tuple_print` into this one, but the table needs to be executable in one place.

## 8 · `run/display_print.bp` — §7 `Display` · **red** · gap G-2

```botopink
//// §7 — a type implementing `Display` prints as its `display()`, also nested.
behavior Display { fn display(self: Self) -> string; }
type Money(cents: i32) implement Display {
    pub fn display(self: Self) -> string { return "$" + self.cents.toString(); }
}
pub fn main() {
    @print(Money(cents: 5));
    @print([Money(cents: 1), Money(cents: 2)]);
}
```

`run/display_print.out`:
```
$5
[$1, $2]
```

**Measured:** commonJS prints `Money { cents: 5 }` then `[Money { cents: 1 },Money { cents: 2 }]`;
erlang prints `#{cents => 5}` then `[#{cents => 1},#{cents => 2}]`. `display()` is never consulted,
nested or not. `§7` names `libs/std`'s `Dict` as the motivating case (`Dict("a": 1, "b": 2)`).

```
commonJS | run/display_print.bp | 01 step 6 | §7: `@print` does not use a type's `Display` implementation
erlang   | run/display_print.bp | 01 step 6 | §7: `@print` does not use a type's `Display` implementation
```

## 9 · `test/loop_break_value.bp` — §10 `break <value>` · **red** · gap G-4

The scenario the README already lists and no cell contains.

```botopink
//// §10 — `break <value>` makes the loop an expression.

test "§10 break with a value is the loop's value" {
    var k = 0;
    val r = loop { k = k + 1; if (k > 2) { break k; }; };
    assert r == 3;
}

test "§10 break with a value out of a condition loop" {
    var i = 0;
    val found = loop (i < 10) { if (i == 4) { break i * 2; }; i = i + 1; };
    assert found == 8;
}
```

**Measured:** commonJS 0 passed / 2 failed — `r` is `[3]`, an array, not `3`. erlang does not
compile: `ConditionLoopValueUnsupported`.

```
commonJS | test/loop_break_value.bp | 06 N12 | `break <value>` yields a one-element array instead of the value
erlang   | test/loop_break_value.bp | 01 step 6 | `ConditionLoopValueUnsupported`: a loop with a value break does not compile
```

## 10 · `test/generic_behavior.bp` — generics, `behavior`, `implement`, `default fn` · **split** · gap G-9

Cut from `libs/std/src/dict.bp` (`Dict<K, V>.mapValues<W>`) and `libs/std/src/primitives.bp`
(`behavior` with `default fn`).

```botopink
//// Generics and behaviors: a generic type, a method changing the type
//// argument, a behavior with an `implement`, and a behavior default method.

behavior Sized { fn size(self: Self) -> i32; default fn isEmpty(self: Self) -> bool { return self.size() == 0; } }

type Bag<T>(items: Array<T>) implement Sized {
    pub fn size(self: Self) -> i32 { return self.items.length; }
    pub fn map<U>(self: Self, f: fn(x: T) -> U) -> Bag<U> { return Bag(items: self.items.map(f)); }
}

test "a generic type carries its argument through a method" {
    assert Bag(items: [1, 2]).size() == 2;
}

test "a generic method changes the type argument" {
    val b = Bag(items: [1, 2]).map({ x -> x.toString() });
    assert b.items.at(0) == "1";
}

test "a behavior default method runs against the implementation" {
    assert Bag(items: []).isEmpty();
    assert !Bag(items: [1]).isEmpty();
}
```

**Measured:** commonJS 3 passed / 0 failed. erlang 2 passed / **1 failed** — the `default fn` test.

```
erlang   | test/generic_behavior.bp::a behavior default method runs against the implementation | 01 step 6 | a `behavior` default method is not dispatched to a user type on erlang
```

## 11 · `reject/generic_missing_argument.bp` — §1.1 · **red** · gap G-9

```botopink
//// §1.1 — a written generic type carries all its type arguments.
type Box<T>(value: T)

fn get(b: Box) -> i32 { return 0; }

pub fn main() { @print(get(Box(value: 1))); }
```

`.expect`:
```
Box needs 1 type argument
4:11
```

**Measured:** `botopink check` exits **0** — §1.1's headline rule is not enforced at all.

```
*        | reject/generic_missing_argument.bp | 06 N18 | a written generic type without its arguments is accepted (§1.1)
```

## 12 · `test/fn_defaults.bp` — trailing parameter defaults · **red** · gap G-11

```botopink
//// Trailing parameter defaults: an omitted trailing argument takes its
//// declared default.

fn connect(host: string, port: i32 = 80, timeout: i32 = 30) -> string {
    return host + ":" + port.toString() + "/" + timeout.toString();
}

test "every default applies" { assert connect("a") == "a:80/30"; }
test "one argument overrides the first default" { assert connect("a", 90) == "a:90/30"; }
test "every argument given" { assert connect("a", 90, 5) == "a:90/5"; }
```

**Measured:** does not compile on either target —
`error: 'connect' expects 3 argument(s), got 1`.

```
commonJS | test/fn_defaults.bp | 06 N1 | trailing parameter defaults are never applied at a call site
erlang   | test/fn_defaults.bp | 06 N1 | trailing parameter defaults are never applied at a call site
```

## 13 · `test/tuple_fn_field.bp` — §6, a function-typed labeled element · **red** · gap G-12

Cut from `jhonstart/src/hooks.bp` (`State<T>(value: T, set: fn(next: T))` and `reducer`'s
`#(state: S, dispatch: fn(action: A))`).

```botopink
//// §6 — a tuple label whose element is a function, called as a method.
fn counter(start: i32) -> #(value: i32, bump: fn(n: i32) -> i32) {
    val value = start;
    val bump = { n -> n + 1 };
    return #(value, bump);
}

test "§6 T4 a labeled function element is called through its label" {
    val c = counter(1);
    assert c.value == 1;
    assert c.bump(8) == 9;
}
```

**Measured:** commonJS 0 passed / 1 failed — `c.bump is not a function`. erlang does not compile.

```
commonJS | test/tuple_fn_field.bp | 06 N24 | a function-typed tuple label is not rewritten to a positional call
erlang   | test/tuple_fn_field.bp | 06 N24 | a function-typed tuple label is not rewritten to a positional call
```

## 14 · `test/closure_capture.bp` — closures as arguments and returns · **green** · gap G-13

```botopink
//// Closures: capture by value, an outer `var` reassigned inside a lambda
//// threads out, and a returned closure keeps its capture.

fn adder(n: i32) -> fn(x: i32) -> i32 { return { x -> x + n }; }
fn apply(f: fn(x: i32) -> i32, v: i32) -> i32 { return f(v); }

test "a lambda passed as an argument runs" { assert apply({ x -> x * 2 }, 5) == 10; }
test "a returned closure keeps its capture" { val f = adder(3); assert f(4) == 7; }
test "an outer var reassigned inside a lambda threads out" {
    var acc = 0;
    [1, 2, 3].forEach({ x -> acc = acc + x });
    assert acc == 6;
}
test "a closure inside a loop body sees the loop variable" {
    var acc = 0;
    loop ([1, 2, 3]) { x -> acc = acc + apply({ y -> y }, x); };
    assert acc == 6;
}
```

**Measured:** 4 passed / 0 failed on both targets. No expected-failure line.

**Note.** `adder(3)(4)` — calling the result of a call directly — is `error: Unexpected token`; the
second test binds `f` for that reason.

## 15 · `test/string_array.bp` — primitive methods · **split** · gap G-10

```botopink
//// Primitive methods on string and Array: the same answer on every backend.
test "string methods" {
    assert "abc".toUpperCase() == "ABC";
    assert "a,b,c".split(",").length == 3;
    assert "  x ".trim() == "x";
    assert "abc".startsWith("ab");
}
test "array methods" {
    val xs = [1, 2, 3, 4];
    assert xs.filter({ x -> x % 2 == 0 }).map({ x -> x * 10 }).join(",") == "20,40";
    assert xs.slice(1, 3).length == 2;
    assert xs.at(0) == 1;
    assert xs.indexOf(3) == 2;
}
test "fold accumulates" { assert [1, 2, 3].fold(0, { acc, x -> acc + x }) == 6; }
```

**Measured:** commonJS 3 passed / 0 failed. erlang **does not compile** — isolated one method per
cell, the offender is `"abc".toUpperCase()`: `out/main.erl: function toUpperCase/1 undefined`. The
other eight methods pass on erlang individually.

```
erlang   | test/string_array.bp | 01 step 6 | `String.toUpperCase` emits an undefined erlang function
```

If the front prefers a green cell plus a narrow red one, split `toUpperCase` into its own file.

## 16 · `reject/result_without_wrapper.bp` — §9 · **green** (rejects correctly) · gap G-5

```botopink
//// §9 — the annotation without its wrapper is an error.
#[@result]
fn parse(s: string) -> i32 { return 1; }

pub fn main() { @print(parse("a")); }
```

`.expect`:
```
requires a `-> @Result
3:30
```

**Measured:** rejected with
`error: effect-wrapper-mismatch: `#[@result]` requires a `-> @Result<…>` return type` at
`src/main.bp:3:30`. No expected-failure line.

## 17 · `reject/throw_outside_result.bp` — §9 · **green** (rejects correctly) · gap G-5

```botopink
//// §9 — `throw` outside a `#[@result]` fn stays an error.
fn parse(s: string) -> i32 { throw "boom"; }

pub fn main() { @print(parse("a")); }
```

`.expect`:
```
effect-throw-without-fallible-channel
2:30
```

**Measured:** rejected at `src/main.bp:2:30` with that key. No expected-failure line.

## 18 · `reject/wrapper_without_annotation.bp` — §9 · **red** (wrong diagnostic) · gap G-5

```botopink
//// §9 — the wrapper without its annotation is an error.
fn parse(s: string) -> @Result<i32, string> { return 1; }

pub fn main() { @print(1); }
```

`.expect`:
```
@Result needs #[@result]
2:24
```

**Measured:** rejected, but as `error: type mismatch: expected Result, got i32` at
`src/main.bp:2:54` — a consequence, not §9's rule, and it points at the `return` rather than the
annotation.

```
*        | reject/wrapper_without_annotation.bp | 06 | `@Result<…>` without `#[@result]` is reported as a return-type mismatch, not as §9's missing-annotation rule
```

## 19 · `crash/val_assert_binding.bp` — §9 / decision 4 · **pending (new kind)** · gap G-1

This one cannot be a `test/`, `run/` or `reject/` cell, because the compiler does not produce a
result of any kind: it aborts.

```botopink
//// §9 / decision 4 — `val assert Ok(n) = …` binds the success value; a failure
//// is a fatal assert.
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}

pub fn main() {
    val assert Ok(n) = parse(7);
    @print(n);
}
```

**Measured:** `General protection exception (no address available)`, exit **134**, for `check`, `run`
and `test` alike, on both targets. The same with a user enum
(`val assert Some(n) = Opt.Some(v: 3);`). With a non-call right-hand side (`= 5`) it is a plain parse
error instead.

The runner classifies an abort as "does not compile", which is true but hides that the compiler
crashed. Two options for the front:

1. add it as a `run/` cell listed against 06, and accept that "does not compile" understates it; or
2. add a fourth kind — `crash/` — whose rule is "`botopink check` must not terminate by signal", and
   which is empty once this is fixed. One file, one rule, and the gate says something true.

The layout document proposes (2).

## 20 · `modules/two_modules/` — modules · **pending (needs the layout change)** · gap G-8

Not expressible today: `run.sh` copies one file into `src/main.bp`. Verified by hand in a scratch
project of the shape below.

`src/main.bp`:
```botopink
//// Modules: a `pub mod` sibling, an `import` of its type and its fn, a method
//// on an imported type.
pub mod geometry;
import { Point, origin } from "geometry";

pub fn main() {
    @print(Point(x: 1, y: 2).norm());
    @print(origin().norm());
}
```

`src/geometry.bp`:
```botopink
pub type Point(x: i32, y: i32) {
    pub fn norm(self: Self) -> i32 { return self.x + self.y; }
}
pub fn origin() -> Point { return Point(x: 0, y: 0); }
```

`.out`:
```
3
0
```

**Measured:** commonJS prints `3` then `0` — correct. **erlang** fails at run time:
`escript: exception error: undefined function geometry:norm/1`. A method on an imported `pub type` is
emitted as a call to the module rather than resolved to the record's method.

```
erlang   | modules/two_modules | 01 step 6 | a method on a type imported from a sibling module is emitted as `<module>:<method>/1` and is undefined
```

This is the single highest-value cell blocked purely by the suite's layout.

## 21 · Cells that need a library dependency · **pending**

`@ExprCustom<T>`, `q.custom(root, …)` and `CustomNode` (inventory C4) are the mechanism behind
`erika`'s SQL subset and `jhonstart`'s markup. A minimal cell needs either a second module declaring
the template fn plus a consumer, or a `botopink.json` dependency — neither is expressible today.
Once the layout supports a multi-file cell, the `modules/` kind covers the first shape; the
dependency shape (`examples/generic-loader-binding`) stays out of scope for this suite and belongs to
`test-libs`.

## 22 · §5.3b sections and refinement · **pending (06 N22)** · gap G-15

Decided 2026-09-17, after the suite was written; no cell exists in any form. The source below is the
decision's own example reduced; it does **not** parse today — `case` arms are 06 N22 — so it would be
added listed.

```botopink
//// §5.3b — a section of an enum-shaped `type` is a type named by its path, and
//// matching into a section is a refinement, never coverage of the section.
type Token {
    Text { Bold, Italic },
    Color { Red },
    Hover(inner: Token[]),
}

fn kind(t: Token) -> string {
    return case t {
        Text(inner)  { "text" }
        Color(inner) { "color" }
        Hover(inner) { "hover" }
    };
}

test "§5.3b a section arm binds the section type" { assert kind(Token.Text.Bold) == "text"; }
```

**Measured:** `error: Unexpected token` at the first arm (`Text(inner) { "text" }`) — the §5.1 arm
form, 06 N22. The enum with sections itself parses (verified separately).

```
commonJS | test/case_sections.bp | 06 N22, 06 N28 | §5.3b section arms do not parse; section-as-a-type is not implemented
erlang   | test/case_sections.bp | 06 N22, 06 N28 | §5.3b section arms do not parse; section-as-a-type is not implemented
```

---

## Tally

**21 programs** are given as source above. **20 were run to a measured result**; **1** could not be
written at all (§21, `@ExprCustom` — it needs a second module or a dependency, which no kind
expresses today).

By measured result:

| Status | Count | Cells |
|---|---|---|
| **green** — passes on both targets | 7 | effect_result, comptime_template, decorator_emit, external_host, closure_capture, result_without_wrapper, throw_outside_result |
| **split** — passes on one target | 4 | effect_iterator, generic_behavior, string_array, two_modules |
| **red** — fails on both | 8 | print_formatter, display_print, loop_break_value, fn_defaults, tuple_fn_field, generic_missing_argument, external_lowercase_target, wrapper_without_annotation |
| **crash** — compiler terminates by signal | 1 | val_assert_binding |
| **red, and blocked on 06 N22 parsing** | 1 | case_sections |
| **unwritable today** | 1 | @ExprCustom (§21) |

Three of the measured cells are "pending" only as *cells*, not as measurements — they need a kind or
a layout that does not exist yet: `val_assert_binding` (needs `crash/`), `two_modules` (needs
`modules/`), and `case_sections` (writable today, listed against 06 N22/N28).

Every measured result above was produced at `botopink-lang` `1193d3c`, node v25.8.0, OTP 29;
re-measure before quoting, as the carried-deep-dive rule requires.
