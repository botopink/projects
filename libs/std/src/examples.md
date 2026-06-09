# Examples — using the `.bp` stdlib

> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Docs: [`./docs.md`](docs.md)

Practical `.bp` snippets that use the embedded stdlib. Every interface
mentioned here is defined in this directory.

## Primitives — `primitives.d.bp`

```text
val n: i32 = 42;
val big: i64 = n.as(i64);     // upcast
val flag: bool = true;

val s = n.to_string();        // "42"
val absx = (-5).abs();        // 5
val m = (-3).max(7);          // 7
```

## Arrays — `array.d.bp`

```text
val xs: Array<i32> = [10, 20, 30, 40];

val len   = xs.length();      // 4
val first = xs.at(0);         // 10
val tail  = xs.slice(1, 4);   // [20, 30, 40]

val doubled = xs.map(fn(x) { x * 2 });
val evens   = xs.filter(fn(x) { x % 2 == 0 });
val sum     = xs.forEach(fn(x) { /* side effect */ });

val joined  = ["a", "b", "c"].join(",");   // "a,b,c"
val r       = xs.reverse();                // [40, 30, 20, 10]
val idx     = xs.indexOf(30);              // 2
val has     = xs.contains(99);             // false
```

Pipelines pair naturally with `Array`:

```text
val total = [1, 2, 3, 4, 5]
    |> filter(fn(x) { x % 2 == 1 })   // [1, 3, 5]
    |> map(fn(x) { x * x })           // [1, 9, 25]
    |> sum();                         // 35
```

## Strings — `string.d.bp`

```text
val s = "Hello, world";

val n = s.len();              // 12
val u = s.to_upper();         // "HELLO, WORLD"
val l = s.to_lower();         // "hello, world"

val has   = s.contains("world");      // true
val starts = s.starts_with("Hello");  // true
val parts = s.split(",");             // ["Hello", " world"]

val clean = "  hi  ".trim();          // "hi"
val left  = "  hi  ".trim_left();     // "hi  "
val right = "  hi  ".trim_right();    // "  hi"

val r = s.replace("world", "botopink");  // "Hello, botopink"
val c = s.char_at(0);                    // "H"
val i = s.index_of("w");                 // 7
val sub = s.slice(0, 5);                 // "Hello"
```

## Builtins — `builtins.d.bp`

### Reflection (all comptime)

```text
val t  = typeOf(42);          // type at comptime
val tn = typeName(42);        // "i32" at comptime
val sz = sizeOf(Point);       // bytes, at comptime
val al = alignOf(Point);

record User { name: string, age: i32 }
val has_name = hasField(User, "name");   // true
```

### Numeric

```text
val m1 = min(3, 7);           // 3
val m2 = max(3.5, 1.2);       // 3.5
val a  = abs(-9);             // 9
val as_f = (10).as(f32);      // 10.0
```

### Result type — `@Result<D, E>`

```text
val ParseError = enum { InvalidInput, UnexpectedEnd }

fn parse(input: string) -> @Result<i32, ParseError> {
    if (input == "") {
        return @Result.Error(error: ParseError.UnexpectedEnd);
    }
    return @Result.Ok(result: 42);
}

// try propagates the error upward
fn process() -> @Result<string, ParseError> {
    val n = try parse("hello");
    return @Result.Ok(result: n.to_string());
}

// try-catch handles the error inline
fn safe_parse(input: string) -> i32 {
    val n = try parse(input) catch 0;
    return n;
}

// catch with throw — re-throw a different error
fn strict_parse(input: string) -> @Result<i32, string> {
    val n = try parse(input) catch throw "parse failed";
    return @Result.Ok(result: n);
}
```

### Control-flow

```text
val r = block {
    val a = compute1();
    val b = compute2();
    a + b
};
```

`block` lets you scope a multi-statement expression and return its last
value.

### Runtime helpers

```text
fn must_be_positive(n: i32) {
    if n < 0 { panic("expected positive, got " + n.to_string()); }
}

fn unreachable_branch() {
    trap();   // hard-stop; emits target-specific abort
}

val loc = src();   // SrcLoc { file, line } — comptime
```

## A complete example

```text
use std.{println};

fn main() {
    val words = "the quick brown fox jumps over the lazy dog"
        .split(" ")
        .filter(fn(w) { w.len() > 3 })
        .map(fn(w) { w.to_upper() });

    words.forEach(fn(w) { println(w); });
}
```

Output:

```text
QUICK
BROWN
JUMPS
OVER
LAZY
```

## erika — LINQ-style queries

The `erika` module is a C#/LINQ-style query library over `Array<T>`. Import it
from `"std"`, wrap an array in a `Query<T>` with `erika.of(...)`, then chain
fluent operators. Everything is eager and immutable — each operator returns a
fresh `Query`.

```text
import {erika} from "std";

record Person { name: string, age: i32 }

fn main() {
    val people = [
        Person(name: "Ann", age: 30),
        Person(name: "Bob", age: 17),
        Person(name: "Cy",  age: 22),
    ];

    val adults = erika.of(people)
        .where({ p -> p.age >= 18 })
        .orderBy({ p -> p.name })
        .select({ p -> p.name })
        .toArray();

    @print(adults.join(", ")); // Ann, Cy
}
```

Aggregations, grouping and element terminals:

```text
val total    = erika.range(1, 101).where({ n -> n % 2 == 0 }).sum({ n -> n }); // 2550
val byParity = erika.of([1, 2, 3, 4]).groupBy({ n -> n % 2 });                 // Query<Grouping<i32, i32>>
val firstBig = erika.of([1, 5, 9]).firstWhere({ n -> n > 4 });                 // ?i32 → 5
```

### The `erika "…"` query string

`erika` is also a **template function**: a SQL-subset query string is parsed at
compile time and expanded into the fluent pipeline. The grammar (keywords
lowercase) is:

```text
select <* | field> from <Name> [where <cond>] [order by <field> [asc|desc]]
```

```text
// expands (at comptime) to:
//   of(erikaCities).where({ row -> row.pop >= 5 })
//                  .orderBy({ row -> row.name })
//                  .select({ row -> row.name }).toArray()
val names = erika "select name from erikaCities where pop >= 5 order by name asc";
```

The referenced collection (`erikaCities`) is resolved against the caller's
top-level scope. `select *` yields `Array<Row>`; `select field` yields
`Array<FieldType>`. Multi-field projection (`select a, b`) is a deliberate
not-yet error in v1. See [`../AGENTS.md`](../AGENTS.md) for the current resolution
caveat on the `erika "…"` form.

## See also

- Stdlib loading + conventions → [`./docs.md`](docs.md).
- Full language reference → [`../../../docs.md`](../../../docs.md).
