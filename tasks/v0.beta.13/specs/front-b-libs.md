# Front B — libs & examples test scenarios (`.bp` tests + demo apps)

**Slug**: front-b-libs
**Front territory** (edit ONLY here — disjoint from Fronts A/C):
`libs/**` (`.bp` `test {}` blocks) + `examples/**` (demo apps with their unit tests).
**Scope**: the standard library and the framework / sub-language libs as they behave
today, exercised by `botopink test` / `botopink-lib-test`, **plus** a runnable `examples/`
demo per area whose `main.bp` carries `.bp` unit tests. No compiler-core or LSP edits.
**Status**: DONE — every `[gap]` is closed by a `.bp` test/demo or recorded as a
limitation below. `botopink-lib-test --target commonJS` green (std/erika/jhonstart/onze/rakun ✓,
client/server no-tests); demos (`stdlib-tour`, `erika-linq`, `jhonstart-html`,
`jhonstart-counter`, `onze`) green under `botopink test`. erlang remains at the
pre-existing backends-parity baseline (it is Front A/C territory).

**Recorded limitations (gaps that expose a real product gap, not forced into a test):**
- B1: structural record keys / record-set dedup — `==` on records is *reference*
  equality (documented + asserted as identity semantics in `examples/stdlib-tour`).
- B1: `result.isOk`/`isError` (method or namespace form) not lowered by the commonJS
  backend — covered indirectly via `unwrapOr` (note in `libs/std/test/result_test.bp`).
- B3 jhonstart: a lone-child / bare-string `Children` type-checks but does not RENDER —
  `renderToString` walks `children` as an array, and normalizing a single value needs a
  runtime type tag the value doesn't carry (note in `examples/jhonstart-counter`).
- B3 onze: a `thenThrow` mock caught by the caller's `try/catch` — botopink `try/catch`
  only unwraps an `@Result`, not a host throw; and a fully generic `any<T>()` / argument
  captor needs a per-type default / new host cell (notes in `libs/onze/test/onze_test.bp`).
- B3 rakun: a missing-dependency-type error is a COMPILE diagnostic (annotation processing),
  not expressible as a runtime `assert` — covered by Front A's compiler-core suite.

> Tags + dead-syntax table: [`../README.md`](../README.md). Record construction is the call
> form `Name(field: value)`. The sub-language **LSP overlay** (semantic tokens / hover /
> go-to-def) is Front C; here we cover only the **lib-side** expansion + run behaviour.

---

## B1 · stdlib — std modules + `toString`
Source: **88 inline `test "…"`** across `libs/std/src/{dict,order,queue,sets,string_builder}.bp`
+ `primitives.d.bp`. No `*_test.bp`; Option/Result/Array are declaration-backed.
```
[have] comptime ---- Dict lookup→Option, hasKey/size/keys/values/insert; Order toInt/reverse/case
[have] comptime ---- Queue enqueue/dequeue/peek/fromList round-trip/fifo; Set union/intersect/diff
[have] comptime ---- StringBuilder append + toString; `i32 toString` / record `toString` camelCase
[gap]  comptime ---- Option.map/flatMap/unwrapOr; Result.map/flatMap/unwrapOr (no dedicated std test today)
[gap]  comptime ---- Array/List map/filter/fold + sort-with-Order has a std-level test (today: only snaps)
[gap]  gate    ---- no `to_string` (snake) in std botopink interfaces (external symbol names exempt)
# — net-new —
[gap]  comptime ---- Dict with RECORD keys (structural); Set of records dedups structurally
[gap]  comptime ---- an empty Dict/Queue/Set boundary (size 0, lookups miss, dequeue → none)
[gap]  run/node ---- a small Queue algorithm (BFS levels) returns the expected order
```
Examples + demo:
```botopink
test "queue fifo order preserved" {
  val q = Queue.empty<i32>().enqueue(1).enqueue(2).enqueue(3);
  val r = q.dequeue();
  assert r.front.unwrapOr(0) == 1; assert r.rest.size() == 2;
}
test "option map/unwrapOr" {
  val some = Dict.empty<string, i32>().insert("a", 1).lookup("a");
  assert some.map({ x -> x + 9 }).unwrapOr(0) == 10;
}
```
Demo: **`examples/stdlib-tour/`** (deps: std) — dict/queue/set/order tour with the tests.

## B2 · sublanguages (lib-side) — `@ExprCustom` expansion + run
Source: erika-query-ast (29 in-file tests) + jhonstart-html-ast (9 lib + 6 example) — both
LANDED. (The LSP overlay for these is **Front C**.)
```
[have] infer   ---- a fn returning @ExprCustom<T> is recognized as a template fn
[have] run     ---- q.custom(tree, code) runs `code` identically to returning that @Expr<T>
[have] comptime ---- erika: select…from…where…order expands + runs; failAt at the bad token
[have] comptime ---- erika: CustomNode labels select/from/where keyword, fields property; ref on source
[have] comptime ---- html: `<div><p>${x}</p></div>` builds the nested Element tree; mismatched close → failAt
[have] comptime ---- html: CustomNode labels tags "tag", attrs "property", values "string"; ${hole} neutral
[have] gate    ---- no sub-language vocabulary (sql/html) in compiler-core/src
# — net-new —
[gap]  comptime ---- erika `where` referencing TWO columns (a = b and c > d) lowers + labels both
[gap]  comptime ---- two sub-language strings in ONE file produce independent CustomNode trees
[gap]  comptime ---- a sub-language string in ARGUMENT position (f(erika "…")) still expands
```
Example + demo:
```botopink
val people = [ Person(name: "Ann", age: 30), Person(name: "Bo", age: 15) ];
val names = erika "select name from people where age >= 18 order by name asc";
test "erika filters + projects" { assert names.len() == 1; }
```
Demo: **`examples/erika-linq/`** + **`examples/jhonstart-html/`** (existing) — add `test {}`
blocks (query / markup parity).

## B3 · frameworks — rakun · jhonstart · onze
Source: `libs/rakun/test/{di,router}_test.bp` (5) + rakun F2-scopes/F5 (LANDED, 13 tests,
`examples/rakun` over real HTTP), `libs/onze/test/onze_test.bp` (7),
`libs/jhonstart/{src inline (6), test/html_test.bp (9)}`.
```
# rakun
[have] comptime ---- #[service]/#[repository]/#[controller] place on a record; scan registers each
[have] comptime ---- a 3-level DI chain wires + resolves; a cycle raises a scoped diagnostic
[have] infer   ---- #[getMapping("/x")] handler (Request) -> Response type-checks
[have] run     ---- rkDispatch builds the chain + runs; mapped GET → 200; unmapped → 404
[have] comptime ---- singleton scope: a 3-level chain resolves a SINGLE shared instance per type
[have] comptime ---- #[bean] factory output injectable by return type; #[value("port")] filled, NOT a DI edge
[have] run     ---- Rakun.run(app) starts a REAL http server; GET over the wire → 200 (examples/rakun)
# jhonstart
[have] infer   ---- Counter() -> Element; `use state/effect` in an Element ok; in -> string → @Context mismatch
[have] infer   ---- a custom hook propagates @Context<Element,_>; Children coercion (Element[]/single/string) checks
[have] run     ---- text/fragment/nested tags render to HTML (renderToString); html """…""" builds the tree
[gap]  run     ---- a lone-child / bare `string` Children actually RENDERS (today type-checks, needs normalization)
[gap]  run     ---- renderToString of a component using a hook produces the expected SSR string
# onze
[have] comptime ---- mock(T) synthesizes every method; run unstubbed → type-default
[have] run     ---- when().thenReturn (last match wins); eq()/anyInt()/anyString(); verify times/never; thenThrow
[gap]  run     ---- a generic any<T>() matcher / argument captor (record or build)
[have] gate    ---- no framework name appears in compiler-core/src
# — net-new —
[gap]  rakun:comptime ---- two controllers with overlapping path prefixes both register; dispatch picks the right one
[gap]  rakun:infer    ---- a leaf component (no deps) resolves; a missing dependency type → clear error
[gap]  jhonstart:run  ---- deeply nested html with mixed text + ${holes} renders the right tree
[gap]  onze:run       ---- verify after multiple DIFFERENT-arg calls checks each matcher independently
[gap]  onze:run       ---- a thenThrow mock method is caught by the caller's try/catch
```
Examples + demos:
```botopink
#[service]
record Greeter { fn hello(self: Self, who: string) -> string { return "Hello, ${who}!"; } }
#[controller]
#[route("/api")]
record HelloCtl {
  greeter: Greeter,
  #[getMapping("/hello")]
  fn hi(self: Self, req: Request) -> Response { return Response.ok(self.greeter.hello("ana")); }
}
test "GET /api/hello → 200" { assert rkDispatch("GET", "/api/hello").status == 200; }
```
```botopink
#[mock] interface Counter { fn count(self: Self) -> i32; }
test "stub + verify" { val m = mockCounter(); when(m.count()).thenReturn(3); assert m.count() == 3; verify(m, times(1)).count(); }
```
Demos: **`examples/rakun/`**, **`examples/jhonstart-counter/`** (existing) — add `test {}`;
**`examples/onze/`** (new) — a mock-driven unit-test demo.

## Notes
- Pure lib/example territory: `.bp` `test {}` + `examples/<dir>/`. Runs via `botopink test`
  / `botopink-lib-test`. No Zig, no LSP edits → never collides with Front A or C.
- rakun / erika / html all LANDED this cycle — their `[have]`s are regression guards; the
  `[gap]`s are edge cases + the jhonstart Children-render normalization.
