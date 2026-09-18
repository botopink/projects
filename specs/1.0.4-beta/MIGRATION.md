# Migrating to 1.0.4-beta

> **Naming.** Written for 1.0.3-beta, which was folded into 1.0.4-beta before it shipped. Here
> "1.0.3" names the **new surface** and "1.0.2" the **old one**; both land in the 1.0.4-beta release
> ([`overview.md`](./overview.md)). The language design decided on 2026-09-17 —
> [decision 8](./08-review-backlog/decision-8-language.md), with decision 5 — is part of this
> migration.

1.0.4-beta is a hard cutover: the old spellings are parse errors, with a diagnostic that names the
replacement. Migration is manual (beta phase).

> **What the compiler enforces as of 1.0.4-beta.** Everything in *Keywords*, *Records*, *Enums*,
> *Behaviors*, *Tuples*, *Effects*, *Loops* and *Separators* below is checked: the old spellings do
> not parse, `#[@result]` requires `@Result<T, E>`, `while` is refused with a message naming `loop`,
> and `row.label` resolves to an index — including through a generic instantiation and on a
> function-typed element.
>
> Three sections describe the language as decision 8 defines it, and **the checker does not enforce
> them yet**; write your code this way — the grammar accepts it — and expect the diagnostics to
> arrive in 1.0.5-beta:
>
> | Section | State |
> |---|---|
> | *Generic types and `Self`* and *Declarations that would be `unknown`* | The forms parse. A bare `Self` in a generic declaration and an unannotated `[]` are still accepted, and `libs/std` itself has not been migrated to `Self<T>`. → 1.0.5-beta `01-checker` |
> | *`case`, `is` and guards* and *`unknown` and unions* | The **grammar** shipped — `unknown`, `i32 \| string`, `x is T`, `Pattern { body }` arms, `when` guards, `A...B`, `.Variant`. The arm's binding type, exhaustiveness, `_` on `unknown` and the narrowing are not checked yet. → 1.0.5-beta `01-checker` |
> | *Printing* | Not shipped on any backend. `@print` of an array or a tuple prints `[1, 2]` and `#(1, "a")` on commonJS, erlang and wasm; the one derived, source-shaped formatter per type — `Point(x: 1, y: 2)`, `5.0` for every `f64`, `Display` honoured when nested — is 1.0.5-beta's, one front per backend |

## Keywords

| 1.0.2-beta | 1.0.4-beta |
|---|---|
| `record Name { fields, methods }` | `type Name(fields) { methods }` |
| `enum Name { variants, methods }` | `type Name { variants, methods }` |
| `interface Name { … }` | `behavior Name { … }` |
| `record { x: 1 }` (value) | `#(1)`, or `#(x)` from a variable `x` — a tuple |
| `{ x: i32 }` (type) | `#(x: i32)` — a tuple type, labels optional |
| `record { }` / `{}` | `#()` |
| `auto`, `derive`, `get`, `macro`, `opaque`, `private`, `set` | ordinary identifiers |
| `delegate`, `new` | ordinary identifiers — `throw Error("x")`, not `throw new Error("x")` |
| `get name(self: Self) -> T` (accessor in `.d.bp`) | `fn name(self: Self) -> T;` |
| `while (cond) { … }` | `loop (cond) { … }` |
| `$self` in an `#[@External…]` template | `$0` (the first declared parameter, `self` included) |

`type` keeps its existing meaning in type position (`comptime T: type`, `-> type`).

## Records

```bp
// 1.0.2-beta
pub record Config {
    // where the server listens
    host: string = "0.0.0.0",
    port: i32,

    pub fn url(self: Self) -> string {
        return self.host + ":" + self.port.toString();
    }
}

// 1.0.4-beta
pub type Config(
    // where the server listens
    host: string = "0.0.0.0",
    port: i32,
) {
    pub fn url(self: Self) -> string {
        return self.host + ":" + self.port.toString();
    }
}
```

- Fields go in parentheses, like the call that builds the value: `Config(host: "h", port: 80)`.
- Fields keep defaults, annotations and comments. The `val` prefix on a field is gone.
- The body is optional: `pub type Point(x: i32, y: i32)`.
- A record with no fields has no parentheses: `pub type MathOps { pub fn add(…) … }`.

## Enums

```bp
pub type Shape {
    Circle(radius: f64),
    Square(side: f64),

    pub fn area(self: Self) -> f64 { … }
}
```

- A body with at least one variant or section is an enum.
- Variants come before methods.
- Variant payloads use the same field list as records (annotations and comments allowed).

## Behaviors

```bp
pub behavior Request {
    val method: HttpMethod;
    val path: string;

    fn param(self: Self, name: string) -> string;

    default fn isGet(self: Self) -> bool {
        return self.method == HttpMethod.Get;
    }
}
```

Same semantics as `interface`. Members end with `;` when they have no body; nothing follows a `}`.

## Generic types and `Self`

A written generic type carries all its type arguments — in a parameter, a return type, a field, an
annotation — and so does `Self` inside a generic `type` or `behavior`.

```bp
// 1.0.2-beta
pub interface Array<T> {
    fn filter(self: Self, pred: fn(item: T) -> bool) -> Self
    fn map<U>(self: Self, f: fn(item: T) -> U) -> Array<U>
}
fn isOk(r: Result) -> bool { … }

// 1.0.4-beta
pub behavior Array<T> {
    fn filter(self: Self<T>, pred: fn(item: T) -> bool) -> Self<T>;
    fn map<U>(self: Self<T>, f: fn(item: T) -> U) -> Self<U>;
}
fn isOk<T, E>(r: Result<T, E>) -> bool { … }
```

- In a type with no type parameters `Self` stays bare.
- A non-generic type implementing a generic behavior writes `Self`, and the behavior's extra type
  parameter is bound to its argument: `type Point(x: i32) implement Mappable<i32>` has
  `fn map(self: Self, f: fn(x: i32) -> i32) -> Self`.
- Explicit type arguments are allowed at a use: `Option<i32>.None`, `first<string>([])`.

## Declarations that would be `unknown`

A type argument is decided where the value is born — written at the use, from the arguments, or from
the immediate context (return type, annotation, parameter). Later uses never decide it, so an
unannotated empty literal is `unknown`, with a warning:

```bp
// 1.0.2-beta
var out = [];
out = out.append([1]);
return out;                       // fn … -> i32[]

// 1.0.4-beta
var out: i32[] = [];
out = out.append([1]);
return out;
```

`val z = Option.None;` is `Option<unknown>` — write `val z: Option<i32> = Option.None;`. A `pub`
declaration whose inferred type contains `unknown` is an error.

## Tuples

```bp
val name = "SP";
val pop = 12;
val row = #(name, pop);                 // labels name, pop, from the variables
row.pop;                                // 12 — rewritten to row.1 at compile time
row.1;                                  // 12

fn load() -> #(name: string, pop: i32) {
    return #("SP", 12);                 // labels come from the written return type
}
load().name;                            // "SP"

fn plain() -> #(string, i32) { … }
plain().name;                           // error: the written type has no label — use .0
```

- Construction never writes a label; an element that is a variable lends its name.
- A written type may carry labels; they are names for the compiler only.
- A tuple **is a tuple** at run time and prints positionally: `#("SP", 12)`.
- Labels never take part in type comparison: `#(name: string, pop: i32)` accepts `#(string, i32)`.
- In a pattern a tuple is positional: `case row { #("SP", p) { p } _ { 0 } }`.

## `case`, `is` and guards

```bp
// 1.0.2-beta
return case s {
    Circle(r) -> r * r;
    Square(side) -> side * side;
};

// 1.0.4-beta
return case s {
    Shape.Circle(r) { r * r }
    .Square(side) { side * side }
};
```

- An arm is `Pattern { body }`; `{ n -> body }` binds the whole matched value; the body's last
  expression is the arm's value; arms take no `;`.
- Guards: `Option.Some(value: v) when (v is string) { v.length }`.
- `_ { … }` is the catch-all — required unless no other value is possible; guarded arms never make a
  `case` exhaustive.
- `..` ignores the rest: `#(0, ..)`, `Shape.Rect(width: w, ..)`.
- `x is i32` tests the value (a float with an integral value in range is an `i32`, converted inside
  the block). *The new arm grammar shipped with 06's `d0c27f6`; the conversion and the exhaustiveness
  rule are carried to 1.0.5-beta `01-checker`.*

## `unknown` and unions

```bp
val data: unknown = json.parse(text);
if (data is string) { @print(data); };

val v = if (c) { 1 } else { "a" };      // i32 | string
case v {
    i32 { n -> n + 1 }
    string { s -> s.length }
}
```

Nothing leaves `unknown` or a union without `is` or a `case`; there is no `any`.

## Effects

```bp
// 1.0.2-beta
#[@result]
fn parse(s: string) -> i32 { … }

// 1.0.4-beta
#[@result]
fn parse(s: string) -> @Result<i32, string> {
    if (s == "") { throw "empty"; };
    return 42;
}
```

The annotation and the wrapped return type go together: `#[@result]` ↔ `@Result<T, E>`,
`#[@future]` ↔ `@Future<T>`, `#[@iterator]` ↔ `@Iterator<T>`, `#[@asyncGenerator]` ↔
`@AsyncGenerator<T>`. `val assert Ok(n) = parse("42");` matches the result; after `catch` the value
is no longer a `@Result`.

## Loops

```bp
loop (xs) { x -> … }
loop (0..n) { i -> … }
loop (attempts < 3) { … }       // replaces while
loop { … break; }
```

## Printing

`@print` text is the same on every backend and shaped like the source: `[1, 2]`, `#(1, "a")`,
`Point(x: 1, y: 2)`, `Shape.Square(side: 4)`, `5.0` for an `f64`; a top-level string is printed bare,
a nested one quoted. A type implementing `behavior Display` prints its `display()`.

**Not shipped in 1.0.4-beta.** What landed is the array and tuple text — `[1, 2]`, `#(1, "a")`, a
nested string quoted with its source escapes — on commonJS, erlang and wasm (decision 1a,
`b4cf700`); beam has no printer of its own, an `f64` still prints `5` on commonJS, and a record
prints its backend's own shape. The one derived formatter per type is 1.0.5-beta's, one front per
backend.

## Separators

- `,` separates data: fields, variants, tuple elements, arguments.
- The trailing comma picks the layout: none → compact on one line; present → one item per line.
- A `fn` definition is always printed open.
- Declarations and `case` arms are not separated by commas: `;` after a bodyless member, nothing
  after `}`.

## What does not change

- `implement`, `extends`, `default fn`, `declare fn`
- Construction: `Point(x: 1, y: 2)`, `Point(1, 2)`, `Shape.Circle(radius: 1.0)`
- Annotations `#[…]`
- Runtime representation of named records, enums and behaviors

## Diagnostics you will see

| You wrote | Error | Shipped |
|---|---|---|
| `record Point { … }` | `removed-keyword-record` — use `type Point(fields) { methods }` | yes |
| `enum Color { … }` | `removed-keyword-enum` — use `type Color { variants }` | yes |
| `interface Printable { … }` | `removed-keyword-interface` — use `behavior Printable { … }` | yes |
| `record { x: 1 }` | `removed-record-literal` — use `#(x)` or `#(1)` | yes |
| `fn f(p: { x: i32 })` | `removed-record-type` — use `#(x: i32)` | yes |
| `type P(x: i32) { A }` | `type-record-with-variants` | yes |
| `type P(val x: i32)` | `type-field-val-prefix` | yes |
| `fn f(self: Self) -> i32,` in a behavior | `member-comma-separator` | yes |
| `while (c) { … }` | `while` does not exist — use `loop (c)` | yes (06 N26) |
| `throw new Error("x")` | use `throw Error("x")` | yes (06 N27) |
| `#[@result] fn f() -> i32` | `#[@result]` requires the return type `@Result<T, E>` | yes (06 N25) |
| `val assert Ok(n) = parse("42") catch 0;` | a `val assert` over a `@Result` takes no `catch` | yes (06 C12) |
| `row.name` where the type has no label | the written type has no label — use `row.N` | yes (06 N24) |
| `fn f(p: NoSuchType)` | `unknown type 'NoSuchType'`, with the caret on the annotation | yes (06 C10 + N30) |
| `absVal(-3)` where `absVal` has no external target for the backend | `` `absVal` has no `#[@External.<Target>(…)]` for the erlang backend``, with the call site | yes (06 C13) |
| `fn get(b: Box) -> i32` | `Box` is generic and needs 1 type argument | **not yet** — 1.0.5-beta `01-checker` (N18) |
| `fn get(self: Self) -> T` in `type Box<T>` | `Self` needs its type arguments — write `Self<T>` | **not yet** — `01-checker` (N18) |
| `#(x: 1)` | a tuple is built without labels — write `#(1)`, or label it in the destination type | **not yet** — `01-checker` (N24's warning half) |
| a `case` that is not exhaustive, or `_` missing on `unknown` | `not exhaustive`, `use _ {` | **not yet** — `01-checker` (N22) |

Error codes other than the first eight are sketches; the implementing fronts fix the wording. A row
marked **not yet** parses today and is simply accepted; `tests/language/expected-failures.txt` lists
the cell that will red when it lands.
