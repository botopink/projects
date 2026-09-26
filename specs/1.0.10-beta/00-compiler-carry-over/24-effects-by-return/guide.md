# The effects of botopink — the return decides, `async { }`, `iter` and `stream`

The maintainer's guide to the language **as decided** by the effect revision of 1.0.10-beta
(decisions [118–128](../../decisions-taken.md#118-the-return-type-is-the-annotation)), in English.
The effect of a function is its return type; the forms that left the language are listed in § 9
*Old names that left*, each a located compile error with a fix-it. `docs.md` carries the same text
(§ Effects, § Results, § Iterators, § use, § Loops, § Host bindings); what is left open is in the
front's [`README.md`](./README.md).

---

## 1. The idea on one page

An "ordinary" function cannot fail, wait, use hooks or produce a sequence. To gain one of those
capabilities, **write the wrapper in the return type**. There is no annotation: the return is the
annotation.

| Return | The body may write |
|---|---|
| `T` | only `try … catch` (handles the error on the spot) |
| `@Result<T, E>` | `throw` · `try` |
| `@Task<T>` | `await` |
| `@Component<C, T>` | `use` · `await` |
| `@Iterator<T>` | `yield` · `break v` |
| `@Stream<T>` | `yield` · `break v` · `await` |

In `@Task`, `@Component`, `@Iterator` and `@Stream`, **`throw` and `try` are also legal when the value (or
the item) is a `@Result<U, E>`** — for example `@Task<@Result<User, string>>`.

Blocks and loops have no signature, so they take a prefix:

| Form | Worth |
|---|---|
| `async { … }` | `@Task<T>` |
| `iter loop` · `iter while` · `iter for` | `@Iterator<T>` |
| `stream loop` · `stream while` · `stream for` · `stream for await` | `@Stream<T>` |

The rules that make it all work:

1. **The wrapper has to be written in the return.** `-> @Task<User>` activates the effect. An alias
   (`type Job<T> = @Task<T>`) does **not**: whoever reads the signature has to see the `@`. Since a
   function has only one return, it can have only one effect (the old R5 comes for free).
2. **The capabilities form a chain**, and each level grants everything below it:

```
   @Component<C, T>  ⊃  @Task<T>        use · await
   @Stream<T>        ⊃  @Task + yield   yield · await
   @Iterator<T>                         yield
```

   That is why a hook or a component may `await`, and a stream may `await`.
3. **Only `@Result` fails.** `@Task`, `@Component`, `@Iterator` and `@Stream` never fail. When something
   can fail, the failure goes **inside the value**: `@Task<@Result<T, E>>`,
   `@Iterator<@Result<T, E>>`. The body then gains `throw` and `try`, and the receiver decides what
   to do with the error.
4. **The chain only grants downwards.** `use` exists only with a `@Component` return;
   `yield` only in iterators and streams; `await` neither with a `@Result` return nor in an
   `@Iterator`; `throw` / `try` only when there is a `@Result` in the return. Writing a capability
   the return does not grant is a located **compile error**, with no flag to switch it off
   (decision 67).

---

## 2. Functions that can fail — `-> @Result<T, E>`

```bp
pub type ParseError { Empty, NotANumber(text: string), TooBig(value: i32) }

pub fn parsePort(s: string) -> @Result<i32, ParseError> {
    if (s == "") { throw ParseError.Empty; }
    val n = try toInt(s);                  // if toInt fails, the error rises from here (propagates)
    if (n > 65535) { throw ParseError.TooBig(value: n); }
    return n;                              // becomes Ok(n) automatically
}

fn toInt(s: string) -> @Result<i32, ParseError> {
    var n = 0;
    for (s.chars()) { c ->
        val digit = c.charCodeAt(0) - 48;
        if (digit < 0 || digit > 9) { throw ParseError.NotANumber(text: s); }
        n = n * 10 + digit;
    }
    return n;
}
```

### 2.1 What `return` does in an effect function

- `return v` with `v: T` → **wraps** (`Ok(v)`, a resolved Task, …);
- `return w` with `w` already of the wrapper's type → **passes it through** as is;
- if the wrapper is nested (`-> @Result<@Result<i32, E>, E>`) and the value fits both layers → an
  error asking for an explicit `Ok(…)`.

With `@Task<@Result<U, E>>`, both layers wrap: `return v` with `v: U` becomes a Task holding
`Ok(v)`; `return r` with `r: @Result<U, E>` becomes a Task holding `r`; `return t` with `t` already
of the whole type passes through.

```bp
fn firstOk<E>(a: @Result<i32, E>, b: @Result<i32, E>) -> @Result<i32, E> {
    return case a {
        Ok(_) -> a;                        // passes through: already @Result<i32, E>
        Error(_) -> b;
    };
}
```

### 2.2 Three ways to consume a `@Result`

```bp
// 1) try … catch — handles it on the spot; works in ANY function
fn portOrDefault(s: string) -> i32 {
    return try parsePort(s) catch 8080;
}

// 2) try alone — propagates the error; needs a @Result in the return
//    (@Result<…>, @Task<@Result<…>>, @Component<C, @Result<…>>, …)
pub type Config(port: i32)

fn loadConfig(text: string) -> @Result<Config, ParseError> {
    val port = try parsePort(text);
    return Config(port: port);
}

// 3) case — looks at both outcomes
fn describe(s: string) -> string {
    return case parsePort(s) {
        Ok(p) -> "port " + p.toString();
        Error(.Empty) -> "empty";
        Error(.NotANumber(text: t)) -> "not a number: " + t;
        Error(.TooBig(value: v)) -> "too big: " + v.toString();
    };
}

// extra: val assert — fatal if it does not match (for when a failure is a bug, not a use case)
fn mustParse() {
    val assert Ok(p) = parsePort("443");
    @print(p);
}
```

**`try` and `await` begin an expression** (decision 136). They stand where an expression starts — a
statement, a `val` / `var` initializer, the right side of `=`, a `return` / `yield` / `break` /
`throw` operand, a call argument, an element of an array, tuple or record literal, an `if` / `while`
condition, a `case` subject, a `for` iterable — and take the whole expression after them
(`try await f()` is `try (await f())`). They are never the operand of an operator, of a unary `-` /
`!`, of parentheses or of a `.` chain: `total + try r` and `(try batch).length` are
`try-await-operand`, whose fix-it binds the value first — `val x = try r; total + x`.

### 2.3 Compile errors

```bp
fn noChannel(s: string) -> i32 {
    return try parsePort(s);      // ✗ effect-try-without-fallible-channel: `try` needs a
}                                 //   @Result in the return (or use `try … catch`)

fn noTask() -> @Result<i32, string> {
    val x = await fetchCount();   // ✗ effect-await-without-task: `await` needs a @Task
    return x;                     //   return or above
}

pub type Parser<T> = @Result<T, ParseError>;
fn viaAlias(s: string) -> Parser<i32> {
    throw ParseError.Empty;       // ✗ effect-wrapper-behind-alias: write `@Result<i32, ParseError>`
}                                 //   in the return to activate the effect
```

---

## 3. Functions that wait — `-> @Task<T>`

`@Task<T>` is "a value that has not arrived yet". `await` unwraps it. A Task never fails: if the
operation can go wrong, the value is a `@Result`, and `await` hands over that `@Result`. To
propagate the error, combine with `try`:

```bp
import {async, io.http, json} from "std";

pub type User(id: i32, name: string)

pub fn fetchUser(id: i32) -> @Task<@Result<User, string>> {
    val res = try await http.fetch("https://api.example.com/users/" + id.toString());
    if (res.status == 404) { throw "user " + id.toString() + " does not exist"; }
    val body = try json.decode(res.body);            // throw/try are legal: the value is @Result
    return userFromJson(body);                       // becomes a Task holding Ok(…)
}

pub fn greetingFor(id: i32) -> @Task<@Result<string, string>> {
    val u = try await fetchUser(id);                 // await hands over the @Result; try propagates
    return "Hello, " + u.name;
}

// a Task that cannot fail: only await, no try
pub fn delayed(ms: i32) -> @Task<void> {
    await async.delay(ms, 0);
}
```

**`await` and `try` are separate things.** `await t` waits; `try r` propagates. With
`t: @Task<@Result<U, E>>`:

| I write | I get | Legal where |
|---|---|---|
| `await t` | `@Result<U, E>` | with an await channel |
| `try await t` | `U` (the error rises) | with an await channel **and** a `@Result` in the return |
| `try await t catch x` | `U` (or `x`) | with an await channel |

```bp
// waiting on several at once (std/async)
import {async} from "std";

pub fn dashboard() -> @Task<@Result<string, string>> {
    val all = try await async.allOf([fetchUser(1), fetchUser(2), fetchUser(3)]);   // stops at the first Error
    val fourth = try await async.timeout({ -> fetchUser(4) }, 2000);  // Error("timeout") past 2 s
    val late = try fourth;                                              // the task's own @Result
    return all.map({ u -> u.name }).join(", ") + ", " + late.name;
}
```

### 3.1 `async { … }` — a Task in the middle of a function

An `async` block creates a `@Task` without declaring a separate function. It can be used in **any**
function, ordinary ones included: the block waits for nothing, it **creates** the Task.

```bp
fn launch() -> @Task<@Result<Array<User>, string>> {
    return async.allOf([
        async { return try await fetchUser(1); },              // @Task<@Result<User, string>>
        async { val u = try await fetchUser(2); return User(id: u.id, name: u.name.toUpper()); },
    ]);
}

fn main() {
    val tick = async { return await async.delay(100, 1); };  // @Task<i32>, in an ordinary function
}
```

Rules of the block:

- `return v` **leaves the block** with `v`, not the surrounding function (the block behaves like a
  closure called in place);
- it is **closed**: inside a function with a `@Component` return, an `async { }` cannot `use`;
- `T` comes from the `return`s. If the body has `throw` or `try`, the value becomes `@Result<U, E>`
  on its own, with `E` coming from those `throw` / `try`. Two different error types → a compile
  error suggesting an annotation: `val x: @Task<@Result<User, string>> = async { … };`
- `break :outer` / `continue :outer` crossing the block's border is an error.

**Per backend:** on commonJS, every function with a `@Task` return becomes an `async function` and
the caller `await`s; `async { }` becomes `(async () => { … })()`. A `throw` in a
`@Task<@Result<…>>` does **not** reject the Promise: it resolves with the `Error` value. On
erlang / beam / wasm the `@Task` is eager, `await` is the identity and `async { }` runs the block
in place.

**Consuming without an await channel:** an ordinary function cannot `await`. Either the function
returns `@Task` too, or the value is handled with the `@Task`'s own functions (`.map`, `.then`, …).

---

## 4. Hooks and components — `-> @Component<C, T>`

Only this return grants `use`. `C` is the "base" of the context the `use`s anchor at
(`ElementBase` in jhonstart, `RequestBase` in rakun — the name is the library's, the compiler knows
neither); `T` is what the function returns. One wrapper serves both shapes, and `T` tells them apart:

- a **hook** returns any `T` — `@Component<ElementBase, State<T>>`;
- a **component** returns the context owner, a `T` that `implement`s `@Context<C>` —
  `@Component<ElementBase, Element>`.

The base is always written, for hooks and components alike; it is never read off `T`.

Since `@Component ⊃ @Task`, **every hook and every component may `await`.** `throw` and `try` follow the
general rule: legal if `T` is a `@Result`. A component returns `Element`, so it handles errors in
its own body — with `catch`, `case`, `notFound()` or an error screen.

### 4.1 On the library side (jhonstart): the context owner and the basic hooks

```bp
// jhonstart — the type that carries the context tree
pub type ElementBase(root: bool)
pub type Element(tag: string, value: string, children: Array<Element>, attrs: Array<#(string, string)>)
    implement @Context<ElementBase>

// a state hook
pub type State<T>(value: T, set: fn(next: T))

pub fn state<T>(initial: T) -> @Component<ElementBase, State<T>> {
    return State(value: initial, set: { next -> });   // the server pass; the client rebinds `set`
}

// a hook reading the request (decision 114, item 8: onze hands the RequestData to the render)
// (jhonstart's `RequestData` also carries the method, params, query and headers, and reads
// them with `param(name)`, `cookie(name)`, …)
pub type RequestData(path: string, cookies: Array<#(string, string)>)

pub fn request() -> @Component<ElementBase, RequestData> {
    return RequestData(path: "/", cookies: []);        // jhonstart reads it from the host
}
```

### 4.2 The application's hooks compose other hooks

```bp
import {ElementBase, state, request} from "jhonstart";

pub fn counter(start: i32) -> @Component<ElementBase, #(i32, fn())> {
    val s = use state(start);
    return #(s.value, { -> s.set(s.value + 1) });
}

pub fn currentUser() -> @Component<ElementBase, ?User> {
    val req = use request();
    val id = try toInt(req.cookie("uid")) catch 0;
    if (id == 0) { return null; }
    return try await fetchUser(id) catch null;       // await is legal (Component ⊃ Task)
}
```

### 4.3 Components: page, layout and ordinary components

Page, layout and template **are components** (decision 117): `-> @Component<ElementBase, Element>`.
`#[page(seg)]`, `#[layout(seg)]` and `#[template(seg)]` stay attributes — metadata (the route
segment the file serves), not effects — and each refuses, at the annotation, a function whose return
is not `@Component<ElementBase, Element>`. The site imports what a marker emits beside the marker
(`jhPage` / `jhLayout`, `ctxParam` / `ctxRest`), and jhonstart's builders take their `attrs`
explicitly (`text("…", [])`, `div([…], [])`).

```bp
import {
    ElementBase, Element, PageContext, LayoutProps,
    div, h1, p, span, button, text, redirect, notFound,
    layout, page, jhLayout, jhPage, ctxParam, ctxRest,
} from "jhonstart";

// an ordinary component
pub fn Counter() -> @Component<ElementBase, Element> {
    val #(n, inc) = use counter(0);
    return div([p([text("Clicks: " + n.toString(), [])], []), button([text("+1", [])], [])], []);
}

// layout: checks the session ONCE for the whole /dashboard/* area
#[layout("dashboard")]
pub fn DashboardLayout(props: LayoutProps) -> @Component<ElementBase, Element> {
    val user = use currentUser();
    if (user == null) { redirect("/login"); }         // a signal: becomes 307 (or a client navigation)
    return div([Sidebar(user: user), props.children], []);
}

// page: await + signals; the error is handled here (the component does not propagate)
#[page("posts/[id]")]
pub fn PostPage(ctx: PageContext) -> @Component<ElementBase, Element> {
    val post = try await loadPost(ctxParam(ctx, "id")) catch null;
    if (post == null) { notFound(); }
    if (post.movedTo != "") { redirect("/posts/" + post.movedTo); }
    return div([h1([text(post.title, [])], []), Counter()], []);   // a component is CALLED, not `use`d
}

// a function that only builds HTML and uses no hook is NOT a component — it returns a plain Element
pub fn Badge(label: string) -> Element {
    return span([text(label, [])], [#("class", "badge")]);
}
```

### 4.4 On the server (rakun): the same return, another base

```bp
// rakun — the owner of the request context
pub type RequestBase {}
pub type RequestScope(id: string) implement @Context<RequestBase>

pub fn requestId() -> @Component<RequestBase, string> {
    return "req-1";                            // rakun reads it from the request
}

pub fn tenant() -> @Component<RequestBase, @Result<Tenant, string>> {
    val id = use requestId();                  // same base: ok
    return try await tenantFor(id);            // try is legal: T is @Result
}
```

### 4.5 The rules of `use`, and the errors

```bp
fn Page() -> @Task<Element> {
    use request();                // ✗ use-without-context-effect: `use` requires a
}                                 //   @Component<…> return

fn Mixed() -> @Component<ElementBase, Element> {
    val a = use state(0);         // base ElementBase
    val t = use tenant();         // ✗ context-anchor-violation: two bases in one function (ElementBase
}                                 //   and RequestBase) — the error points at the second `use` and names both

fn Wrong() -> @Component<ElementBase, Element> {
    return use Counter();         // ✗ use-of-non-context-fn: a component (its T owns the context) is called
}                                 //   (`Counter()`); `use` is for hooks only

fn Propagates() -> @Component<ElementBase, Element> {
    val u = try await fetchUser(1);   // ✗ effect-try-without-fallible-channel: Element is not a
}                                     //   @Result; use `catch`, `case` or `notFound()`

fn outsideTheBody() {
    val f = { -> use state(0) };      // ✗ use-without-context-effect: `use` does not leave the body
}                                     //   of the function with the @Component return

#[layout("")]
pub fn OldLayout(props: LayoutProps) -> Element {   // ✗ decision 117: #[layout] requires
    return props.children;                          //   a @Component<ElementBase, Element> return
}
```

**Per backend:** on commonJS, every function with a `@Component` return becomes an
`async function` (decision 104), even without `await`; the caller `await`s. `use f(x)` compiles to
the call `f(x)` — `use` is a type check, not a run-time cost.

---

## 5. Iterators and streams — `-> @Iterator<T>` and `-> @Stream<T>`

An iterator produces a sequence on demand (lazily): each `next` runs the body up to the next
`yield`. A stream is the same, but asynchronous: finding out whether there is a next item may need
waiting (paging, a socket, a file).

```
@Iterator<T>    synchronous    yield · break v
@Stream<T>      asynchronous   yield · break v · await
```

Both use the same step:

```bp
pub type YieldStep<T> { Yield(value: T), Done }
```

**What each word does inside an iterator or stream:**

- `yield v` — emits `v` and **continues**;
- `break v` — emits `v` and **ends** (≡ `yield v; break;`);
- a bare `break` (outside any inner loop) — ends without emitting.

### 5.1 `@Iterator<T>` — any function may iterate one

```bp
pub fn fibonacci(limit: i32) -> @Iterator<i32> {
    var a = 0;
    var b = 1;
    var i = 0;
    while (i < limit) {
        yield a;
        val t = a + b; a = b; b = t;
        i = i + 1;
    }
}

pub fn firstNegative(xs: i32[]) -> @Iterator<i32> {
    for (xs) { x ->
        if (x < 0) { break x; }       // emits the negative and ends
        yield x;
    }
}

fn main() {
    for (fibonacci(10)) { n -> @print(n); }        // ok in an ordinary function
}
```

### 5.2 Items that can fail — `@Iterator<@Result<T, E>>`

The iterator does not fail; **each item** may be an error. When the item is `@Result<U, E>`, the
body gains sugar:

- `yield v` with `v: U` → emits `Ok(v)`; with `v: @Result<U, E>` → emits it as is;
- `throw e` → emits `Error(e)` and ends (≡ `break Error(e)`);
- a `try x` that fails → emits `Error(e)` and ends.

```bp
pub fn parseLines(text: string) -> @Iterator<@Result<i32, ParseError>> {
    for (text.split("\n")) { line ->
        if (line == "") { continue; }
        yield try parsePort(line);        // failed → emits Error(e) and ends
    }
}
```

Whoever iterates receives the `@Result` and decides. **`for` does no implicit `try`:**

```bp
// stop at the first error: an explicit try, inside a function with @Result in the return
fn sumPorts(text: string) -> @Result<i32, ParseError> {
    var total = 0;
    for (parseLines(text)) { r ->
        val p = try r;                    // `total + try r` is refused: bind it first
        total = total + p;
    }
    return total;
}

// carry on after the error: case, in any function
fn printPorts(text: string) {
    for (parseLines(text)) { r ->
        case r {
            Ok(p) -> @print(p);
            Error(e) -> @print(e);        // the variant, e.g. NotANumber(text: "x")
        }
    }
}
```

### 5.3 `@Stream<T>` — asynchronous; iterated with `for await`

The rules of 5.2 hold: with a `@Result` item, a failing `try await` also emits `Error(e)` and ends.

```bp
pub fn pages(url: string) -> @Stream<@Result<Array<User>, string>> {
    var next = url;
    while (next != "") {
        val res = try await http.fetch(next);     // failed → emits Error(e) and ends
        val body = try json.decode(res.body);
        yield usersFrom(body);                    // emits Ok(…)
        next = nextLink(body);
    }
}

fn countUsers() -> @Task<@Result<i32, string>> {
    var n = 0;
    for await (pages("https://api.example.com/users")) { batch ->
        val users = try batch;
        n = n + users.length;
    }
    return n;
}
```

`for await` needs an await channel: a `@Task` return or above, an `async { }` block or a `stream`.

**Per backend:** on commonJS, an `@Iterator` function with `yield` becomes a `function*` and a
`@Stream` one an `async function*`.

### 5.4 Iterator or factory

A function with an `@Iterator` or `@Stream` return **is an iterator if its body has `yield` or
`break v`**. If not, it is an ordinary function that **returns** a ready-made iterator (a factory).
Mixing `yield` with `return <iterator>` in the same body is an error.

```bp
// iterator: has yield
fn evens(xs: i32[]) -> @Iterator<i32> {
    for (xs) { x -> if (x % 2 == 0) { yield x; } }
}

// factory: no yield; returns an assembled iterator
fn evensOf(xs: i32[]) -> @Iterator<i32> {
    return iter for (xs) { x -> if (x % 2 == 0) { yield x; } };
}
```

### 5.5 A type that "is iterable": a method returning an iterator

There is no `Iterable`. The type exposes an ordinary method:

```bp
pub type Grid(cells: i32[]) {
    fn iter(self: Self) -> @Iterator<i32> {
        for (self.cells) { c -> yield c; }
    }
}

fn main() {
    val g = Grid(cells: [1, 2, 3]);
    for (g.iter()) { c -> @print(c); }
}
```

### 5.6 Compile errors

```bp
fn g() -> @Iterator<i32> {
    throw "x";                  // ✗ effect-try-without-fallible-channel: the item has to be
}                               //   @Result<i32, E> to use throw/try

fn h() -> @Iterator<User> {
    yield await fetchUser(1);   // ✗ iter-await: `await` does not exist in @Iterator; use @Stream
}

fn k(xs: i32[]) -> @Iterator<i32> {
    yield 0;
    return evens(xs);           // ✗ iter-mixed-yield-return: iterator (yield) and factory
}                               //   (return) in the same body

fn old() -> @Iterator<i32, ParseError> {
    yield 0;                    // ✗ iterator-error-param-removed: use
}                               //   @Iterator<@Result<i32, ParseError>>
```

---

## 6. Loops, `iter` and `stream`

Three words, one meaning each (decision 105). Alone, all three are **statements** (`void`):

```bp
loop { … }                  // repeats until `break`
while (cond) { … }          // repeats while cond
for (coll) { x -> … }       // walks a list, a range or an iterator
for await (s) { x -> … }    // walks a @Stream (with an await channel)
```

```bp
fn examples(xs: i32[]) {
    var i = 0;
    loop {
        i = i + 1;
        if (i == 3) { continue; }
        if (i > 5) { break; }
        @print(i);
    }

    while (i > 0) { i = i - 1; }            // counting down: while (there is no .rev())

    for (0..3) { k -> @print(k); }          // 0 1 2      (.. excludes the end)
    for (0...3) { k -> @print(k); }         // 0 1 2 3    (... includes the end)
    for (xs) { x -> @print(x); }
}
```

**`yield` and `break v` exist only in a generator scope** (an `@Iterator` / `@Stream` function, or
an `iter` / `stream` loop). To collect in an ordinary function, use `xs.map(…)` / `filter(…)` or a
`var`:

```bp
fn double(xs: i32[]) -> i32[] {
    for (xs) { x -> yield x * 2; }    // ✗ yield-without-generator: `yield` outside a generator scope
}
fn doubleRight(xs: i32[]) -> i32[] {
    return xs.map({ x -> x * 2 });
}
```

### 6.1 `iter` and `stream` in front of the loop — an iterator in the middle of a function

With `iter` or `stream` in front, any of the three loops becomes an **expression** worth the
iterator or the stream:

```bp
import {async, io.clock} from "std";

fn main() {
    val numbers = iter loop {                // @Iterator<i32>
        val n = readNumber();
        if (n < 0) { break n; }              // emits n and ends
        yield n * 2;                         // emits and continues
    };
    for (numbers) { x -> @print(x); }

    var i = 3;
    val countdown = iter while (i > 0) { yield i; i = i - 1; };

    val evens = iter for ([1, 2, 3, 4]) { x -> if (x % 2 == 0) { yield x; } };

    // the item becomes @Result on its own when the body has throw/try:
    val parsed = iter loop { yield try parsePort(readLine()); };
                                             // @Iterator<@Result<i32, ParseError>>
    val ids = [1, 2, 3];
    val remote = stream for (ids) { id -> yield try await fetchUser(id); };
                                             // @Stream<@Result<User, string>>
    val ticks = stream loop { yield await async.delay(1000, clock.nowMillis()); };
                                             // @Stream<i64>

    // as an argument:
    val xs = [1, 2, 3];
    @print(sum(iter for (xs) { x -> yield x * x; }));
}
```

Rules of the `iter` and `stream` loops:

- `iter` and `stream` are **contextual** words: they are keywords only immediately before `loop`,
  `while` or `for`. `g.iter()`, `val stream = …` and `http.stream(…)` stay legal;
- the prefixed loop **is** the iterator: `break` and `break v` in it end the sequence;
- it is **closed**: the body has only the iterator's / stream's own capabilities, not those of the
  surrounding function (inside a `@Component` function, an `iter loop` can neither `use` nor `await`);
- `await` only in `stream`; in `iter` it is an error suggesting "use `stream`";
- the item becomes `@Result<U, E>` when the body has `throw` / `try`. To pin the type, annotate the
  `val`: `val xs: @Iterator<i32> = iter loop { … }` — then a `try` in the body is a located error.
  Two different error types in the body → an error asking for the annotation;
- `yield` in a `for` / `while` / `loop` **without** a prefix feeds the nearest generator scope;
  `yield :label v` and `break :label v` pick another;
- `break :outer` / `continue :outer` crossing the border of an `iter` / `stream` loop is an error
  (like leaving a closure).

**Per backend:** on commonJS, `iter …` becomes `(function* () { … })()` and `stream …` becomes
`(async function* () { … })()`.

---

## 7. Navigation signals (`redirect`, `notFound`) in components

Decisions 116–117:

```bp
// page / layout / template (jhonstart) — always -> @Component<ElementBase, Element>
#[page("posts/[id]")]
pub fn Post(ctx: PageContext) -> @Component<ElementBase, Element> {
    val post = try await loadPost(ctxParam(ctx, "id")) catch null;
    if (post == null) { notFound(); }
    if (post.movedTo != "") { redirect("/posts/" + post.movedTo); }
    return div([h1([text(post.title, [])], [])], []);
}
```

- before the first piece of HTML goes out: it becomes `307` + `location` / a real `404`;
- after: it becomes markup in the stream (`<template data-jh-g="redirect" …><script>__bp2()</script>`)
  and the client navigates;
- in a client-only app (`jhonstart.clientApp(...)`): the router navigates / shows the not-found;
- a relative target must exist in the route table; an absolute one only if it is listed in
  `jhonstart.app(allowedRedirects: [...])`.

In a **server action** (rakun), the `redirect` is rakun's. Server actions are rakun's front 24,
not written yet: the example is the contract that front implements, and it type-checks today only
against stand-ins for `serverAction`, `ActionResult`, `FormData`, `redirect` and `insertPost`:

```bp
import {serverAction, ActionResult, FormData, redirect} from "rakun";

#[serverAction]
pub fn createPost(form: FormData) -> @Task<@Result<ActionResult, string>> {
    val id = try await insertPost(form.get("title"));
    return redirect("/posts/" + id);
}
```

---

## 8. `#[@External.<Target>]` — binding to host code (not an effect, but an annotation)

For a function implemented in each target's JavaScript / Erlang. Only the `External.<Target>` form
exists (lowercase `#[@external]` is an error).

```bp
// a function of a host module
#[@External.Node("./helpers.mjs", "parse"),
  @External.Erlang("helpers", "parse")]
pub declare fn parse(input: string) -> i32;

// inline template: $0, $1… are the parameters (in a method, self is $0)
#[@External.Node("$0.toUpperCase()"),
  @External.Erlang("string:uppercase($0)")]
pub declare fn shout(text: string) -> string;

// a target with no binding is a compile error of that target:
//   error: `shout` has no `#[@External.<Target>(…)]` for the wasm backend (located at the call)
```

An external function declared `-> @Task<@Result<T, E>>` turns a rejected Promise (Node) or an
`{error, …}` (Erlang) into `Error(e)`. Declared `-> @Task<T>`, a rejection is a fatal host failure —
use that form only when the host guarantees it does not fail.

`inline = true` (only on `External.Erlang` / `External.Beam`) keeps the backend's hand-written
shape. In the bundled libraries (`routing`, `actions`, `validation`) native code is inline templates
**only** — no `.erl` / `.mjs` files beside them (decision 117).

---

## 9. Quick reference

| I want… | I write | I call / use it with |
|---|---|---|
| a function that can fail | `fn f() -> @Result<T, E>` | `try f()` (propagates) · `try f() catch x` · `case` |
| an asynchronous function | `fn f() -> @Task<T>` | `await f()` (with an await channel) |
| an asynchronous function that can fail | `fn f() -> @Task<@Result<T, E>>` | `try await f()` · `try await f() catch x` · `case (await f())` |
| a Task in the middle of a function | `async { … }` | pass it along, `.map`, `async.allOf` |
| a hook | `fn h() -> @Component<Base, T>` | `use h()` (in `@Component`, same base) |
| a component / page / layout | `fn C() -> @Component<ElementBase, Element>` (+ `#[page]` / `#[layout]`) | `C()` (an ordinary call) |
| a sequence | `fn g() -> @Iterator<T>` | `for (g()) { x -> }` in any function |
| a sequence of items that fail | `fn g() -> @Iterator<@Result<T, E>>` | `for` + `try r` or `case` |
| an asynchronous sequence | `fn g() -> @Stream<T>` | `for await` with an await channel |
| an iterator in the middle of a function | `iter loop` · `iter while` · `iter for` | `for (it) { x -> }` |
| a stream in the middle of a function | `stream loop` · `stream while` · `stream for` | `for await (s) { x -> }` |
| host code | `#[@External.Node(…), @External.Erlang(…)]` | an ordinary call |

### Old names that left

| Old | Now |
|---|---|
| `#[@result] fn f() -> @Result<T, E>` | `fn f() -> @Result<T, E>` |
| `#[@future] fn f() -> @Future<T, E>` | `fn f() -> @Task<@Result<T, E>>` (and `await x` → `try await x`) |
| `@Future<T>` with no error | `@Task<T>` |
| `#[@use] fn f() -> @Use<C, T>` | `fn f() -> @Component<C, T>` (`throw` / `try` only if `T` is `@Result`) |
| `#[@use] fn f() -> @Component<T>` | `fn f() -> @Component<B, T>`, `B` from `T implement @Context<B>` |
| `#[@generator]` + `@Generator<T>` | `@Iterator<T>` |
| `#[@resultGenerator]` + `@ResultGenerator<T, E>` | `@Iterator<@Result<T, E>>` (`for` no longer does an implicit `try`) |
| `#[@futureGenerator]` + `@FutureGenerator<T, E>` | `@Stream<@Result<T, E>>` |
| `#[@generator] loop { … }` | `iter loop { … }` |
| `#[@resultGenerator] loop { … }` | `iter loop { … }` (the item becomes `@Result` from the body) |
| `#[@futureGenerator] loop { … }` | `stream loop { … }` |
| `YieldStep<T, E>` with `Error(error: E)` | `YieldStep<T>` = `{ Yield(value: T), Done }` |
| `@Iterator<T, E>` (the `#[@iterator]` era's name) | `@Iterator<@Result<T, E>>` |
| `#[@context]` / `@Context<B, R>` as an effect | `-> @Component<…>` |
| `#[@iterator]` / `#[@asyncGenerator]` / `@AsyncIterator` | `@Iterator<@Result<…>>` / `@Stream<@Result<…>>` |
| `Iterable`, `IteratorStep`, `Yield<T, R>` | `YieldStep<T>` |
| `loop (xs) { x -> }` · `loop (cond)` · `loop await` | `for (xs) { x -> }` · `while (cond)` · `for await` |
| `-> Element` on a component that uses a hook | `-> @Component<ElementBase, Element>` |
