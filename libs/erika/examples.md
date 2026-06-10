# erika — examples

> Path: `libs/erika/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Docs: [`./docs.md`](docs.md)
> Parent: [`../AGENTS.md`](../AGENTS.md)

All examples assume `erika` is a declared dependency
(`"dependencies": ["erika"]` in `botopink.json`).

## The fluent layer

Wrap an array in a `Query<T>` with `erika.of(...)`, then chain fluent operators.
Everything is eager and immutable — each operator returns a fresh `Query`.

```bp
import {erika} from "erika";

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

Aggregations, grouping, flattening and element terminals:

```bp
val total    = erika.range(1, 101).where({ n -> n % 2 == 0 }).sum({ n -> n }); // 2550
val byParity = erika.of([1, 2, 3, 4]).groupBy({ n -> n % 2 });                 // Query<Grouping<i32, i32>>
val firstBig = erika.of([1, 5, 9]).firstWhere({ n -> n > 4 });                 // ?i32 → 5
val pairs    = erika.of([1, 2, 3]).selectMany({ n -> [n, n * 10] }).toArray(); // [1, 10, 2, 20, 3, 30]
```

## The `erika "…"` query string

`erika` is also a **template function**: a SQL-subset query string is parsed at
compile time and expanded into the fluent pipeline. The grammar (keywords
lowercase) is:

```text
select <* | f1[, f2…]> from <Name> [where <cond>] [order by <field> [asc|desc]]
```

```bp
record City { name: string, pop: i32 }
val cities = [
    City(name: "Lyon",  pop: 5),
    City(name: "Paris", pop: 9),
    City(name: "Nice",  pop: 3),
];

// `select field` projects a single column → Array<string>
//
// expands (at comptime) to:
//   of(cities).where({ row -> row.pop >= 5 })
//             .orderBy({ row -> row.name })
//             .select({ row -> row.name }).toArray()
val names = erika "select name from cities where pop >= 5 order by name asc";
// → ["Lyon", "Paris"]

// `select a, b` projects an anonymous record per row → Array<record { name, pop }>
val rows = erika "select name, pop from cities where pop >= 5 order by name asc";
val labels = rows.map({ r -> r.name + ":" + r.pop.toString() });
// → ["Lyon:5", "Paris:9"]

// `select *` returns whole rows → Array<City>
val all = erika "select * from cities";
```

The referenced collection (`cities`) is resolved against the caller's top-level
scope.

> **Note.** Within a *consumer* project the `erika "…"` form does not resolve yet
> after `import {erika} from "erika"` (`unbound variable 'erika'`) — a generic
> loader limit, see [`AGENTS.md`](AGENTS.md). The fluent `erika.of(...)` API works
> from any project today; the string form is exercised by erika's own in-file
> tests, where the template fn is directly in scope.

## See also

- The operator catalogue + grammar → [`./docs.md`](docs.md).
- The package contract + comptime-eval constraints → [`./AGENTS.md`](AGENTS.md).
