# Decision 8 — types, `unknown`, unions, `is`, patterns, printing, effects and `loop`

**Decided 2026-09-17 by the maintainer**, over several rounds of proposal and counter-proposal. It
**supersedes** [decision 1a](./semantics-decisions.md#decision-1a) (print text),
[decision 6](./semantics-decisions.md#decision-6) (generics, `unknown`) and
[decision 7](./semantics-decisions.md#decision-7) (`val assert` on an effect result). Decisions 1–5
stand; where this file refines one of them it says so.

Examples use the 1.0.3 surface ([`../12-surface-cutover/`](../12-surface-cutover/README.md)):
`type`, `behavior`, `#(…)`. Diagnostics are sketched; the implementing front fixes the wording,
every one carries a location and the fix.

Where it lands is at the end: [Implementation](#implementation).

---

## 1. Generic types

### 1.1 A written type carries all its type arguments

Parameters, return types, fields and annotations, at any depth.

```botopink
fn get(b: Box) -> i32 { … }                        // error: Box needs 1 type argument
fn swap(p: Pair<i32>) -> Pair<i32> { … }           // error: Pair needs 2, got 1
fn swap<A, B>(p: Pair<A, B>) -> Pair<B, A> { … }   // ok
val xs: Box<Option<i32>>[] = [];                   // ok
```

Parameter and return types are always written; they are never inferred.

### 1.2 `Self` follows 1.1, in types and in behaviors

| Declaration has type parameters? | Form |
|---|---|
| no (`type Point(x: i32)`, `behavior Show`) | `Self` |
| yes (`type Box<T>`, `behavior Mappable<T>`) | `Self<T>`, `Self<U>`, … — bare `Self` is an error |

```botopink
type Box<T>(value: T) {
    fn get(self: Self<T>) -> T { … }
    fn map<U>(self: Self<T>, f: fn(x: T) -> U) -> Self<U> { … }   // returns Box<U>
}
```

**A non-generic type implementing a generic behavior** (A1): `Self<…>` becomes `Self` and every
behavior type parameter the member introduces is bound to the implementation's argument.

```botopink
behavior Mappable<T> { fn map<U>(self: Self<T>, f: fn(x: T) -> U) -> Self<U>; }

type Point(x: i32) implement Mappable<i32> {
    fn map(self: Self, f: fn(x: i32) -> i32) -> Self { return Point(x: f(self.x)); }   // U = T = i32
}
Point(x: 1).map({ x -> x + 1 })     // ok: Point(x: 2)
Point(x: 1).map({ x -> "a" })       // error: Point maps i32 to i32 only
Box(value: 1).map({ x -> "a" })     // ok: Box<string>
```

### 1.3 Explicit type arguments at a use

`name<…>` is a type-argument list when `<` is **adjacent** to the name, the contents parse as a type
list, and `>` is followed by `(` or `.`; otherwise `<` is a comparison.

```botopink
val z = Option<i32>.None;           // ok
val c = first<string>([]);          // ok: c is string
val c: string = first<string>([]);  // ok: must agree
val c: i32 = first<string>([]);     // error: expected i32, the call gives string
val c: i32 = first([]);             // ok: T from the destination
a < b                               // comparison
```

### 1.4 Where a type argument is decided — only where the value is born

In order: (1) written at the use; (2) the arguments; (3) the immediate context — return type,
annotation, parameter; (4) otherwise `unknown`. **Later uses never change it.**

```botopink
fn safeDiv(a: i32, b: i32) -> Option<i32> {
    if (b == 0) { return Option.None; };    // (3) Option<i32>
    …
}
takesInt(Option.None);                      // (3) Option<i32>

val z = Option.None;                        // warning: z is Option<unknown> — annotate it
takesInt(z);                                // error: expected Option<i32>, got Option<unknown>
val z: Option<i32> = Option.None;           // ok

var out = [];                               // warning: out is unknown[]
var out: i32[] = [];                        // ok
```

Measured 2026-09-17: 27 `val`/`var … = [];` without annotation — 5 in `libs/std`, 18 in erika, 4 in
jhonstart.

---

## 2. `unknown`

### 2.1 Every value goes in; nothing comes out unchecked

```botopink
val a: unknown = 42;
val y: i32 = a;          // error: unknown is not i32 — check it with `is`
```

### 2.2 Direct operations

| Allowed | Refused |
|---|---|
| `@print(x)`, `x == y`, `x != y`, assigning to `unknown`, passing to a generic (`T = unknown`) | arithmetic, field access, indexing, method calls |

### 2.3 Equality with `unknown` compares numbers by value (B1)

```botopink
val a: unknown = 2.0;
a == 2        // true on every backend
```

Between two statically-typed operands decision B2 stands (exact equality on erlang/beam; mixing
`i32` and `f64` is already a type error).

### 2.4 Public API (D1)

A `pub` declaration whose **inferred** type contains `unknown` is an **error**; writing `unknown`
on purpose is fine (`pub fn parse(s: string) -> unknown`). Non-`pub` declarations get 1.4's warning.

### 2.5 No `any`

There is no type that turns the checker off.

---

## 3. Union types

### 3.1 Syntax

```botopink
val v: i32 | string = 1;
val xs: (i32 | string)[] = [1, "a"];    // array of a union
val ys: i32 | string[] = ["a"];         // i32, or an array of string
```

### 3.2 Inferred unions

| Expression | Type |
|---|---|
| `[1, "a"]` | `(i32 \| string)[]` |
| `[1, 2.5]` | `f64[]` — an integer literal fits `f64` |
| `#(1, "a")` | `#(i32, string)` |
| `if (c) { 1 } else { "a" }` | `i32 \| string` — **no error** (C2) |
| `case` arms of different types | the union of the arm types |
| branches `1` and `null` | `?i32` |
| a branch that `return`s / `throw`s / `break`s | does not contribute |

A misuse is reported **at the use**, pointing at the branch that widened it:

```
error: `v` is i32 | string, and string cannot be added to i32
  |
1 | val v = if (c) { 1 } else { "a" };
  |                              --- this branch makes it i32 | string
2 | val n: i32 = v + 1;
  |              ^ check it with `is`, or make both branches the same type
```

### 3.3 Using a union

Only what every member allows (as 2.2), or narrow first; a `case` covering every member needs no `_`.

```botopink
val v: i32 | string = pick();
v + 1                   // error
if (v is i32) { v + 1 } // ok
case v {
    i32 { n -> n + 1 }
    string { s -> s.length }
}                       // ok, exhaustive
```

### 3.4 Joining (U1–U3)

| Type | `X<A> \| X<B>` becomes |
|---|---|
| `Option<T>`, `Box<T>`, `@Result<T, E>` — one immutable value | `X<A \| B>` |
| `Dict<K, V>` (immutable: `insert` returns a new dict) | `Dict<K, A \| B>` (and the key likewise) |
| `T[]` | **not joined** — `i32[] \| string[]` differs from `(i32 \| string)[]` |

A user `type` joins when its type parameter is only read (no member takes a `T` to change the
value); when unsure, it does not. Diagnostics print the joined form.

### 3.5 `unknown` versus a union

A union is "one of these, and only these"; `unknown` is "anything". Same run-time test, same wasm
box; the difference is what the checker guarantees (exhaustiveness, assignability).

---

## 4. `is` — tests the value, not the origin

### 4.1 Numbers by range; the value is converted inside the block

```botopink
val a: unknown = 2.0;
a is i32      // true on every backend: 2.0 fits i32
a is f64      // true: any number
val b: unknown = 2.5;
b is i32      // false everywhere
if (a is i32) { @print(a + 1); }   // prints 3 everywhere — inside, a is the i32 2
```

### 4.2 What may follow `is`

| Form | Tests |
|---|---|
| `i32`, `i64`, `u8`, … | an integer within the range |
| `f64` | any number |
| `string`, `bool` | the primitive |
| `Point` | the constructor of a named type |
| `Option.Some(v)` / `.Some(v)` | the variant, binding `v` |
| `#(i32, string)` | arity and each element |
| `Box<unknown>` | the constructor; `Box<i32>` is an error (the argument is not checkable) |

### 4.3 On a statically known type

```botopink
val a: i32 = 1;
a is string      // warning: always false
```

---

## 5. `case` and patterns

### 5.1 Arms

```botopink
return case x {
    i32 { n -> "number " + n }
    string { s -> "text " + s }
    Point { p -> "point at " + p.x }
    Option.Some(value: v) { "some " + v }
    .None { "none" }
    #(a, b) when (a is string) { a }
    0 { "zero" }
    _ { v -> "other: " + v }
};
```

| # | Rule |
|---|---|
| P1 | `Pattern { body }`; `{ name -> body }` binds the whole matched value, already narrowed |
| P2 | an arm ends with `}` and takes no `;` (separators rule) |
| P3 | the body is a lambda body: its last expression is the arm's value (a plain block still follows decision 2) |
| P4 | a variant binds by label (`Option.Some(value: v)`) or by position (`Option.Some(v)`) |
| P5 | a bound variable's type comes from the matched value: `Option<string>` → `v: string`; `Option<i32 \| string>` → `v: i32 \| string`; `unknown` → `v: unknown` |
| P6 | a tuple pattern is **positional only** — `#(a, b)`, `#(0, b)`; a label in a tuple pattern is an error |
| P7 | `..` ignores the rest, at the end, once; without it the arity / the fields must match (tuples and variants); on `unknown`, `#(a, ..)` checks at least one element |
| P8 | `.Some(v)` / `.None` — the enum comes from the matched value's type; on `unknown` write the full name |

### 5.2 What a name means in a pattern

| Form | Means |
|---|---|
| `i32`, `string`, `bool`, … | a primitive type |
| `Point`, `Box<unknown>` | a named type |
| `Option.Some(…)`, `.Some(…)` | a variant |
| `0`, `"a"`, `true` | equal to this literal |
| `1...9` | **an inclusive range** — both ends included (decided 2026-09-17, Zig's `switch` spelling). `..` is iteration only: `1..9` in a pattern is an error, "use `1...9`". An open end is a guard (`_ when (x < 0)`). A range never covers a type on its own, so `_` stays required |
| `_` | any value |
| a lower-case name **inside** `Some(…)` / `#(…)` | a variable |
| a lower-case name **alone** as an arm | error: `use _ { n -> … }` |
| a constant (`MAX`) | error: `use _ when (x == MAX) { … }` |

### 5.3 Guards: `when (…)`

```botopink
case b {
    Option.Some(value: v) when (v is string) { v.length }
    Option.Some(value: v) { "some other" }
    _ { "not an Option" }
}
```

- Parentheses required; `when` is special only after an arm's pattern (a `when` identifier elsewhere
  is untouched).
- `is` inside the guard narrows the variable in that arm's body.

### 5.4 Exhaustiveness

A `case` needs a final `_` **unless no other value is possible** from its unguarded arms.

| Situation | `_` required? |
|---|---|
| every enum variant / union member / `true`+`false` covered | no |
| a type covered whole (`i32 { … }` on an `i32`) | no |
| an arm has `when` and no unguarded arm covers the rest | **yes** — guarded arms never count |
| the matched value is `unknown` | **yes** |
| literals only (`0 { … }`) on `i32` / `string` | **yes** |
| a variant or member missing | yes, or handle it |

---

## 6. Tuples and labels

Labels are **names for the compiler**; a tuple is positional at run time.

| Rule | |
|---|---|
| T1 | Construction has no labels: `#("SP", 12)`; an element that is a **variable** lends its name as a label — `#(name, pop)` |
| T2 | A written type may carry labels: `#(name: string, pop: i32)` or `#(string, i32)` |
| T3 | A written type wins: a value entering a labeled type takes the type's labels |
| T4 | `row.pop` is rewritten to `row.1` at compile time; an unknown label is an error: `use row.N` |
| T5 | Type comparison ignores labels: `#(name: string, pop: i32)` accepts `#(string, i32)` and `#(city: string, pop: i32)` |
| T6 | Run time and printing are positional: `#("SP", 12)` |
| T7 | Warning when a construction variable's name differs from the destination type's label |

```botopink
fn load() -> #(name: string, pop: i32) {
    val name = "SP";
    val pop = 12;
    return #(name, pop);
}
@print(load().name);                  // ok → .0
fn show(r: #(name: string, pop: i32)) { @print(r.pop); }
show(#("SP", 12));                    // ok: labels from the parameter
fn loadTyped() -> #(string, i32) { … }
loadTyped().name                      // error: the written type has no label — use .0
```

**Cutover:** anonymous records still become tuples — with labels in the types that cross functions
([`../12-surface-cutover/labeled-tuples.md`](../12-surface-cutover/labeled-tuples.md) and front 13
follow T1–T7, not the earlier "labels live in the type and in construction").

---

## 7. Printing — one formatter per type, source-shaped

The compiler derives **one formatter per type** that every backend uses. Supersedes decision 1a (no
spaces) and ends decision 1's accepted numeric divergence.

| Value | Text |
|---|---|
| top-level string | `hi` |
| nested string | `"hi"`, with source escapes (`\"`, `\\`, `\n`) |
| array | `[1, 2]` |
| tuple | `#(1, "a")` (labels never printed) |
| record | `Point(x: 1, y: 2)` |
| variant | `Shape.Square(side: 4)`, `Option.None` |
| `i32`, `i64` | `5` |
| `f64` | `5.0` — always with a decimal part, every backend |
| `bool` | `true` / `false` |
| a type implementing `Display` | its `display()` — also when nested |

```botopink
behavior Display { fn display(self: Self) -> string; }
type Dict<K, V>(pairs: Array<#(K, V)>) implement Display { … }   // → Dict("a": 1, "b": 2)
```

`libs/std` implements `Display` for `Dict` (and any record hiding its representation).

---

## 8. External templates

Decision 5 stands: `$0`, `$1`, … are the declared parameters, `self` included. `$args` is all of them,
`self` included.

```botopink
#[@External.Node("console.log($args)")]
fn log(self: Self<T>, a: T)          // $args = self, a
```

---

## 9. Effects — annotation plus the wrapped return type

```botopink
#[@result]
fn parse(s: string) -> @Result<i32, string> {
    if (s == "") { throw "empty"; };
    return 42;                          // the success value, no Ok(…)
}
val r = parse("42");                    // @Result<i32, string>
val m = parse("42") catch 0;            // i32
val assert Ok(n) = parse("42");         // n: i32; a failure is a fatal assert (decision 4)
val assert Err(e) = parse("");          // e: string
val assert Ok(n) = parse("42") catch 0; // error: after `catch` the value is not a @Result
```

| Annotation | Return type required |
|---|---|
| `#[@result]` | `@Result<T, E>` — the error type is always written |
| `#[@future]` | `@Future<T>` |
| `#[@iterator]` | `@Iterator<T>` |
| `#[@asyncGenerator]` | `@AsyncGenerator<T>` |

The annotation without its wrapper, or the wrapper without its annotation, is an error. `throw`
outside a `#[@result]` fn stays an error.

---

## 10. `loop` — the only way to repeat

```botopink
loop (xs) { x -> … }              // a collection or generator
// `..` belongs to iteration and slicing only; a pattern range is `A...B` (section 5)
loop (0..n) { i -> … }            // a range
loop (attempts < 3) { … }         // a condition: repeats while true
loop { … break; }                 // until a break
```

The form is decided by the type in parentheses; a parameter on a condition loop is an error.
`while` does not exist (`while (…)` → error: `use loop (condition)`); commonJS's `while` special case
is deleted.

---

## 11. Performance — pay only where used

Code with concrete types emits exactly what it emits today.

| Backend | A value entering `unknown` / a union | `x is i32` |
|---|---|---|
| commonJS | nothing | `typeof` + `Number.isInteger` + range |
| erlang / beam | nothing | `is_integer` + range (or `is_float` + integral check + conversion) |
| wasm | one small allocation (tag + payload) — the boxed `?T` of decision 3, generalised | read the tag + range |

Guidance for users: `unknown` and unions at the edge (JSON, input), concrete types inside.

---

<a id="implementation"></a>

## Implementation

| Part | Front |
|---|---|
| Checker: 1.1–1.4, 2, 3, 4, 5, 6 (T3–T5, T7), 9, 10's typing, diagnostics | [`../06-checker/`](../06-checker/README.md) N18–N30 |
| Parser: type-argument lists (1.3), `\|` types, `is` patterns, arm syntax, `when`, `..`, `.Variant`, `loop (cond)` | 06 (parser files it owns) |
| Run time: `is`, unions/`unknown` (wasm box), 2.3 equality, `row.label` → index, formatter (7) and `Display`, on all four backends | [`../01-backend-residuals/`](../01-backend-residuals/README.md) step 6, **after 06** |
| Source migration: `Self<T>`, `@Result<T, E>` returns, `[]` annotations, tuple labels, `loop (cond)` for `while`, `Display` for `Dict` | [`../12-surface-cutover/`](../12-surface-cutover/README.md) step 3 (compiler, `libs/std`, tests, examples) and [`../13-ecosystem-migration/`](../13-ecosystem-migration/README.md) (libraries) |
| Language server: hover/completion texts for unions, `unknown`, labels | [`../14-tooling-and-docs/`](../14-tooling-and-docs/README.md) |

Every re-recorded RUN LOG is checked against section 7, not bulk-accepted; the print-text snapshots
recorded under decision 1a (`botopink-lang` `b4cf700`) are re-recorded once, by 01 step 6.
