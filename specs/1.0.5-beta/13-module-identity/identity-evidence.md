# Evidence — runtime type identity on erlang

Every claim in [`README.md`](./README.md) that is not a `file:line` was run here. OTP **29**,
`erl` / `erlc` from `/usr/bin`, 2026-09-17. Each block is reproducible: write the fixture, compile,
run.

The tag used throughout is `models@user__t__pessoa` — [option A](./atom-options.md)'s
`erlAtom("models/user")` joined with [A2](./declaration-qualifier.md)'s
`__t__<decl>`.

---

## The fixture

`tag.erl`:

```erlang
-module(tag).
-export([go/0]).

% T1: tagged map. T2: tagged tuple.
t1()      -> #{'__bp_type' => 'models@user__t__pessoa', name => <<"Ana">>, age => 30}.
t1car()   -> #{'__bp_type' => 'models@user__t__car',    name => <<"Ka">>,  age => 3}.
untagged() -> #{name => <<"Ana">>, age => 30}.
t2()      -> {'models@user__t__pessoa', <<"Ana">>, 30}.

% E1 — an existing map pattern still matches a tagged map (subset match).
e1() -> #{name := N} = t1(), N.
% E2 — maps:get is unaffected.
e2() -> maps:get(age, t1()).
% E3 — the `is` test, both shapes.
isType(M, T) when is_map(M) -> maps:get('__bp_type', M, undefined) =:= T;
isType(V, T) when is_tuple(V), tuple_size(V) > 0 -> element(1, V) =:= T;
isType(_, _) -> false.
% E4 — a union case discriminates without a catch-all.
kind(#{'__bp_type' := 'models@user__t__pessoa'}) -> person;
kind(#{'__bp_type' := 'models@user__t__car'})    -> car.
% E6 — equality separates two types that were equal untagged.
e6() ->
    Bare    = maps:remove('__bp_type', t1()),
    BareCar = maps:remove('__bp_type', maps:put(name, <<"Ana">>, maps:put(age, 30, t1car()))),
    {Bare =:= BareCar, t1() =:= maps:put(name, <<"Ana">>, maps:put(age, 30, t1car()))}.
```

```console
$ erlc tag.erl && erl -noshell -pa . -s tag go -s init stop
```

## The run

```
E1 subset match on a tagged map: <<"Ana">>
E2 maps:get unaffected:          30
E3 is Pessoa (map):              true
E3 is Car (map):                 false
E3 is Pessoa (tuple):            true
E3 is on a plain int:            false
E4 union case, no catch-all:     person car
E5 ~p of a tagged map:           #{name => <<"Ana">>,age => 30,
                                   '__bp_type' => models@user__t__pessoa}
E5 ~p of a tagged tuple:         {models@user__t__pessoa,<<"Ana">>,30}
E6 untagged equal / tagged equal:{true,false}
E7 atom_count:                   10513
E8 map size tagged/untagged:     3/2
E9 term words tagged/untagged:   13/11
E9 term words tuple:             7
```

<a id="e1"></a>

### E1 — a tagged map still matches every pattern the backend emits today

`#{name := N} = #{'__bp_type' => …, name => …, age => …}` binds `N`. **A map pattern in erlang is a
subset match**, so adding a key breaks nothing: the destructuring the backend emits at
`erlang.zig:3819-3826` and the `get_map_elements` of `beam_asm.zig:6209` keep working unchanged.

This is the measurement the T1-before-T2 recommendation rests on: the tag can land **without**
touching access, destructuring or pattern lowering. A tagged *tuple* has no such property — every
one of those sites would change in the same commit.

<a id="e2"></a>

### E2 — `maps:get/2` is unaffected

`p.x` (`erlang.zig:4042`) needs no change.

<a id="e3"></a>

### E3 — `is` answers on both shapes, and answers `false` off them

`maps:get('__bp_type', M, undefined) =:= T` distinguishes `Pessoa` from `Car`, `element(1, V) =:= T`
does the same for the tuple, and a plain integer falls through to `false` — so
[decision 8](../../1.0.4-beta/08-review-backlog/decision-8-language.md) §4.2's `x is Point` has a lowering on both
shapes, and a value of a *different* kind is not a crash but a `false`.

<a id="e4"></a>

### E4 — a union `case` is exhaustive with no catch-all

```erlang
kind(#{'__bp_type' := 'models@user__t__pessoa'}) -> person;
kind(#{'__bp_type' := 'models@user__t__car'})    -> car.
```

compiles with no warning and answers `person` / `car`. Decision 8 §3.3 ("a `case` covering every
member needs no `_`") and §5.4 therefore hold at run time, not only in the checker — the erlang
matcher does the discrimination, so the backend emits no test of its own.

<a id="e5"></a>

### E5 — the atom needs no quoting, and `~p` shows it

`models@user__t__pessoa` prints **bare** in both shapes: `@` and `__` are legal in an unquoted atom
after a lowercase start, which is what [option A](./atom-options.md)'s steps 3–5
guarantee. Nothing in the emitters, the `.S` writer or `beam_export_audit.sh` has to learn quoting
(contrast the `#Pessoa` proposal, [erlang-atoms.md § 2.2 B2](./erlang-atoms.md)).

It also shows the cost: **every `RUN LOG` that prints a record moves**, because `~p` of the term now
carries the key. `'__bp_show'` (`erlang.zig:546-556`) has to hide it — and § 7 of decision 8 rewrites
that function anyway, into a per-type formatter that this tag is what makes writable.

<a id="e6"></a>

### E6 — the tag fixes an equality divergence nobody filed

```
{true, false}
```

Left: two records with the same field names and values, untagged, are `=:=` — so
`Point(x: 1, y: 2) =:= Vec(x: 1, y: 2)` is **true** on erlang and beam today. Right: tagged, they
are `=/=`. commonJS already answers `false` (different classes, `commonJS.zig:1514-1518`). The tag
closes a live cross-backend correctness divergence that no row in
[`../02-erlang/`](../02-erlang/README.md) or [`../03-beam/`](../03-beam/README.md) currently names.

<a id="e7"></a>

### E7 — the atom table is a non-issue

A bare OTP node holds **10 513** atoms before a single user type exists, against a limit of
1 048 576. One atom per declared type is noise. (The unbounded growth that does exist is the
comptime server's `template_<hash>` / `decorator_<hash>` modules, never purged —
[erlang-atoms.md § 2.1](./erlang-atoms.md) and
[`../14-comptime-on-beam/`](../14-comptime-on-beam/README.md).)

<a id="e8"></a>

### E8 / E9 — the size cost, and the tuple's advantage

| Shape | `maps:size` | `erts_debug:flat_size` |
|---|---|---|
| untagged map (today) | 2 | 11 words |
| tagged map (T1) | 3 | 13 words (**+18 %**) |
| tagged tuple (T2) | — | **7 words** (−36 % against today) |

The tagged tuple is *smaller* than the map botopink emits today. That is the case for eventually
moving to T2 — and the reason § 2.1 keeps it open rather than closing it.

<a id="e10"></a>

### E10 — build and match, 2 000 000 iterations

`bench.erl` builds the value and matches it in a tight recursive loop:

```
build+match, 2000000 iterations, ms
  untagged map (today):  5 ms
  tagged map (T1):       5 ms
  tagged tuple (T2):     2 ms
```

T1 costs **nothing measurable** over today. T2 is 2.5× faster than either. Decision 8 §11's
promise — "code with concrete types emits exactly what it emits today" — is kept by T1 in time and
paid for in 2 words of space; T2 keeps it in both and costs a mechanical rewrite instead.

---

## What was *not* measured, and should be before step 18

- The numbers above use one record of two fields. Re-measure on a real program (erika's row
  handling, jhonstart's html tree) before committing to T2: a wide record's map may behave
  differently from a 2-field one, and the `flat_size` gap grows with arity.
- `-record` / `is_record/2` (T3) was not benchmarked. It is ruled out on distribution grounds — the
  consumer must `-include` a header the CLI emits nowhere
  ([erlang-atoms.md § 2.3](./erlang-atoms.md)) — not on speed.
- The beam `.S` side was reasoned from `beam_asm.zig`, not run. `is_tagged_tuple`'s arity argument
  grows by one under T2; step 16's acceptance is where that gets executed.

---

# Part 2 — measured 2026-09-18, against the compiler

Part 1 above was measured with hand-written erlang fixtures at OTP 29 (2026-09-17). Everything from
here was measured **against the compiler's own output** at `botopink-lang` `26d4fdc`, same OTP 29 /
erts 17.0.6, plus `node` and `wasmtime`. Where Part 2 contradicts Part 1 it says so and the
correction stands.

Scratch projects were built outside every repository.

<a id="e11--one-program-five-backends"></a>

## E11 — one program, five backends

```botopink
type Person(name: string, age: i32) {
    fn greet(self: Self) -> string { return "hi " + self.name; }
}
type Vec(name: string, age: i32)
type Shape { Circle(radius: i32), Dot }

pub fn main() {
    val p = Person(name: "Ana", age: 30);
    val v = Vec(name: "Ana", age: 30);
    val c = Shape.Circle(radius: 5);
    val d = Shape.Dot;
    @print(p.name); @print(p.greet()); @print(p == v);
    @print(c); @print(d); @print(p);
}
```

```console
$ botopink build --target <t> --out out-<t>          # for commonJS, erlang, beam, wasm
$ botopink build --target commonJS --typescript --out out-ts
```

### erlang — `out-erlang/main.erl`, executed

```erlang
main() ->
    P = #{name => <<"Ana">>, age => 30},
    V = #{name => <<"Ana">>, age => 30},
    C = {'Circle', 5},
    D = 'Dot',
    ...
```

```console
$ erlc main.erl && erl -noshell -pa . -s main _botopink_main -s init stop
Ana
hi Ana
true                         ← Person =:= Vec
{'Circle',5}
'Dot'
#{name => <<"Ana">>,age => 30}
```

### beam — `out-beam/main.S`, assembled and executed

```
{put_map_assoc, {f,0}, {literal, #{}}, {x,0}, 1, {list, [{atom,name},{x,0},{atom,age},{integer,30}]}}.
{put_tuple2, {x,0}, {list, [{atom,'Circle'}, {integer,5}]}}.
```

```console
$ erlc +from_asm main.S && erl -noshell -pa . -s main _botopink_main -s init stop
Ana
hi Ana
true
{'Circle',5}
'Dot'
#{name => <<"Ana">>,age => 30}
```

Byte-identical to erlang's six lines. One divergence in the *code*: the method is `greet/1` on
erlang and `'Person_greet'/1` on beam — beam mangles unconditionally, erlang only on collision.
Recorded, not this front's ([policy 3](./policy-3-module-per-type.md) deletes both).

### commonJS — `out-commonJS/main.js`, executed

```javascript
class Person { constructor(name, age) { … } greet() { … } }
class Vec    { constructor(name, age) { … } }
const Shape = Object.freeze({
    Circle: (radius) => ({ tag: "Circle", radius }),
    Dot: "Dot",                                   // ← a bare string
});
```

```console
$ node main.js
Ana
hi Ana
false                         ← reference comparison, right answer for the wrong reason
{ tag: 'Circle', radius: 5 }
Dot
Person { name: 'Ana', age: 30 }
```

### wasm — `out-wasm/main.wat`, executed

```wat
;; Person(...) — 8 bytes off the bump allocator; the POINTER is the value
global.get $__heap_ptr  local.set $__mem0
global.get $__heap_ptr  i32.const 8  i32.add  global.set $__heap_ptr
local.get $__mem0  i32.const 264  i32.store           ;; .name
local.get $__mem0  i32.const 30    i32.store offset=4 ;; .age
;; Shape.Dot — 4 bytes holding the variant ORDINAL 1
local.get $__mem3  i32.const 1  i32.store
```

```console
$ wasmtime main.wat
Ana
300          ← p.greet() returns a string; the pointer was printed
false        ← pointer comparison
288          ← Shape.Circle(radius: 5)
296          ← Shape.Dot
272          ← Person(name: "Ana", age: 30)
```

**wasm carries no identity of any kind**, and its printer is statically dispatched, so five of the
six lines are wrong. A second program shows the ordinal is not even boxed for an all-unit enum:

```botopink
type Shape { Circle(radius: i32), Dot }
type Color { Red, Green }
val a = Shape.Dot;   val b = Color.Red;
```

```wat
;; Shape.Dot  — boxed, because Shape has a payload variant
local.get $__mem0  i32.const 1  i32.store
;; Color.Red  — not boxed at all
i32.const 0 ;; Color.Red
```

`Color.Red` **is** the integer `0`. It cannot be told from an `i32`, nor from the first variant of
any other all-unit enum.

<a id="e12--the-dts-contradicts-the-js-for-a-unit-variant"></a>

## E12 — the `.d.ts` contradicts the `.js` for a unit variant

```botopink
pub type Shape { Circle(radius: i32), Dot }
```

```console
$ botopink build --target commonJS --typescript --out out-ts
$ cat out-ts/main.d.ts
export declare type Shape = { tag: "Circle", radius: i32 } | { tag: "Dot" };
$ grep -A3 'const Shape' out-ts/main.js
const Shape = Object.freeze({
    Circle: (radius) => ({ tag: "Circle", radius }),
    Dot: "Dot",
});
```

`typescript.zig:115-127` writes `{ tag: "Dot" }`; `commonJS.zig:1563-1566` emits the bare string.
A TypeScript consumer that narrows on `s.tag === "Dot"` compiles and fails at run time.

**0 of the 314 commonJS snapshots** record the pair — the `.d.ts` section is emitted only for `pub`
types and no fixture declares a `pub` mixed enum. The divergence is real and has no snapshot
coverage.

<a id="e13--both-spellings-applied-to-the-compilers-own-output"></a>

## E13 — both spellings applied to the compiler's own output, executed

E11's `out-erlang/main.erl` was edited in place (module renamed, constructors tagged) and re-run.
No other line was touched.

### Spelling A — prefix the term (what `README.md` § 2.1 proposed)

```erlang
P = #{'__bp_type' => 'main__t__person', name => <<"Ana">>, age => 30},
V = #{'__bp_type' => 'main__t__vec',    name => <<"Ana">>, age => 30},
C = {'main__t__shape', 'Circle', 5},
D = {'main__t__shape', 'Dot'},
```

```
Ana
hi Ana
false                                          ← the equality divergence closes
{main__t__shape,'Circle',5}
{main__t__shape,'Dot'}                         ← a unit variant is no longer an ATOM
#{name => <<"Ana">>,'__bp_type' => main__t__person,age => 30}
```

Field access, the method call and destructuring all keep working untouched — E1 and E2 hold on real
emitted code. But the unit variant's **kind** changed (atom → tuple) and the payload variant's
**arity** grew, which are the two things `is_tagged_tuple` and `is_eq` read.

### Spelling B — qualify the tag atom (recommended)

```erlang
P = #{'__bp_type' => 'main__t__person', name => <<"Ana">>, age => 30},
V = #{'__bp_type' => 'main__t__vec',    name => <<"Ana">>, age => 30},
C = {'main__t__shape@Circle', 5},              %% spelling of the qualifier settled in E15
D = 'main__t__shape@Dot',
```

```
Ana
hi Ana
false
{main__t__shape@Circle,5}
main__t__shape@Dot                             ← still an atom, still unquoted
#{name => <<"Ana">>,'__bp_type' => main__t__person,age => 30}
```

Same discrimination, no kind change, no arity change.

<a id="e14--how-often-the-names-already-collide"></a>

## E14 — how often the names already collide

Scan of every `.bp` in the seven repositories (115 files: `libs/std`, `examples`, `tests` and the
five sibling libraries).

```
record-shaped type decls: 54      enum-shaped type decls: 30      variants: 88

DISTINCT field-sets shared by 2+ differently-named record types: 6
   (repo)        → DiamService, GreetService, HttpUserService, PostService, UserService
   (items)       → Query, Queue, Set
   (name, pop)   → City, ErikaCity
   (service)     → DiamController, PostController, UserController
   (clock)       → CartController, StampService
   (svc)         → HttpController, UserController

variant names declared in 2+ files: 7
   Circle 5 files · Rect 5 files · Some 4 · None 4 · Lt 2 · Eq 2 · Gt 2
```

**Option (d), structural typing at the call site, already cannot answer decision 8 §4.2** for 18 of
the 54 record types or for 7 of the 88 variants — not hypothetically, in the code that exists.

The atom-table cost of the recommended scheme: 54 + 88 = **142 new atoms** for the whole ecosystem,
against 10 397 in a bare node and a 1 048 576 limit (E7 re-measured at OTP 29 on 2026-09-18:
`atom_count` 10 397).

<a id="e15--the-qualified-variant-tag"></a>

## E15 — the qualified variant tag

The spelling, checked against A2's decoder and against erlang's guard grammar.

```erlang
decode(A) ->
  P = fun(X) -> lists:flatten(string:replace(X,"@","/",all)) end,
  case string:split(atom_to_list(A), "__", all) of
    [Path]           -> {module, P(Path)};
    [Path,K,D]       -> {decl,   P(Path), K, D};
    [Path,K,D,H]     -> {gen,    P(Path), K, D, H};
    [Path,K,D,"v",V] -> {variant,P(Path), K, D, V}      %% the one new clause
  end.
```

```
models@user__t__shape__v__circle  unquoted=yes  {variant,"models/user","t","shape","circle"}
models@user__t__shape__v__dot     unquoted=yes  {variant,"models/user","t","shape","dot"}
main__t__shape__v__circle         unquoted=yes  {variant,"main","t","shape","circle"}
models@user__t__pessoa            unquoted=yes  {decl,"models/user","t","pessoa"}
models@user                       unquoted=yes  {module,"models/user"}
```

Every form is a legal **unquoted** atom and decodes with no ambiguity. And `is Shape` is expressible
**entirely in guards** — no string operation, no BIF beyond `is_tuple`/`element`/`=:=` — because the
checker knows the variant list statically:

```erlang
F = fun(V) when V =:= 'models@user__t__shape__v__dot' -> unit_variant;
       (V) when is_tuple(V), tuple_size(V) > 0,
                element(1, V) =:= 'models@user__t__shape__v__circle' -> payload_variant;
       (_) -> not_a_shape end.
```

```
F('models@user__t__shape__v__dot')        → unit_variant
F({'models@user__t__shape__v__circle',5}) → payload_variant
F({'main__t__shape__v__circle',5})        → not_a_shape     ← a different enum, same variant name
```

<a id="e16--the-size-of-every-candidate"></a>

## E16 — the size of every candidate

`erts_debug:flat_size/1`, OTP 29.

| Term | Words |
|---|---|
| atom `'Dot'` | **0** — an atom is an immediate |
| atom `'models@user__t__shape__v__dot'` | **0** — length is irrelevant |
| tuple `{'Circle', 5}` (today) | 3 |
| tuple `{'models@user__t__shape__v__circle', 5}` | **3 — unchanged** |
| untagged record map (today) | 11 |
| **(a)** atom-tagged map | 13 (+18 %) |
| **(b)** integer-tagged map `'__bp_type' => 7` | **13 — identical to (a)** |
| **(b′)** short-atom map `'__bp_type' => 'Pessoa'` | **13 — identical to (a)** |
| **(c)** fun-tagged map `'__bp_type' => fun m:ty/0` | **15 (+36 %)** |
| T2 tagged tuple `{'…__t__pessoa', <<"Ana">>, 30}` | 7 (−36 % against today) |

**The entire enum half of this front is free.** A shorter tag buys nothing: an atom and a small
integer are both immediates, so option (b)'s only claimed advantage does not exist.

<a id="e17--a-carried-function-cannot-be-read-in-a-guard"></a>

## E17 — a carried function cannot be read in a guard

Option (c) — the value carries a function and the identity is what that function answers.

```erlang
f(M) when (maps:get('__bp_id', M))() =:= 'p' -> yes;
f(_) -> no.
```

```console
$ erlc guardtest.erl
guardtest.erl:3:12: illegal guard expression
```

A fun call is not a guard expression, so the identity can only be reached by a **call**, which means
a `case` over a union has to dispatch before it matches — the catch-all arm decision 8 §5.4 forbids.
The rest of the option, measured for completeness:

```
C1 flat_size with a fun         : 15   (vs 11 untagged, 13 atom)
C2 can a `case` discriminate?   : only after a CALL (no pattern, no guard)
C3 term_to_binary round trip    : models@user__t__pessoa      ← an EXTERNAL fun survives
C4 the same for an ANONYMOUS fun: anon                        ← survives here; breaks across a reload
C5 two values of the same type =:= ? true
```

**Option (c) is ruled out on C2.**

<a id="e18--the-honest-timing"></a>

## E18 — the honest timing, and why E10's numbers do not survive

### The artefact

`erlc +to_asm` on a loop that tests a **hoisted, statically-known** value:

```erlang
it(_,0,A) -> A;
it(V,N,A) -> case V of {'p',_,_} -> it(V,N-1,A+1); _ -> it(V,N-1,A) end.
```

```
{function, it, 3, 25}.
  {label,26}.
    {gc_bif,'-', …}. {gc_bif,'+', …}. {call_only,3,{f,25}}.
```

**There is no test in the emitted code.** The compiler proved the shape and deleted it. Any
benchmark that builds the value where the compiler can see it measures the loop, not the test.
[E10](#e10--build-and-match-2-000-000-iterations)'s fixture is of that shape, which is why its
numbers (5 ms / 5 ms / 2 ms at 2 M iterations) are not reproducible and must not be used to justify
step 6.

### The honest measurement

Value produced by an exported `mk/1` the compiler cannot fold, tested through an exported
non-inlinable function, 10 000 000 iterations, best of 5:

```
flat_size: today=11  T1=13  T2=7 (words)
  (d) structural: both keys present        188920 us  18.892 ns/op
  (a/b) T1 tag lookup + atom compare       184109 us  18.411 ns/op   −0.481 vs today
  T2 element(1) + atom compare             184280 us  18.428 ns/op   −0.464 vs today
```

**The three `is` lowerings are indistinguishable** — every difference is under 0.5 ns and under the
cost of the dispatch that reaches them.

Construct, in a tight loop where the compiler can see the literal (so this is a lower bound on the
build cost, not on the test):

```
today  untagged map    12175 us   1.218 ns/op
T1     tagged map      13830 us   1.383 ns/op     (+0.165 ns)
T2     tagged tuple    13826 us   1.383 ns/op
```

**What is real:** T1 costs **+2 words per record value** and **+0.165 ns per construct**; the enum
half costs **nothing** (E16); the `is` test costs nothing measurable in any spelling. Time is not a
reason to prefer T1 or T2 — space and the size of the emitter diff are.

Machine: Linux 7.2.4-arch1-2, Erlang/OTP 29, erts 17.0.6.

<a id="e19--the-snapshot-blast-radius"></a>

## E19 — the snapshot blast radius

Commands and counts in [`blast-radius.md`](./identity-blast-radius.md). The two results worth repeating here:

```
erlang cells whose emitted code moves : 62 of 314
beam   cells whose emitted code moves : 68 of 313
RUN LOG lines that print a record or a variant, across all four backends
  (997 non-empty lines in 611 blocks) : 0
overlap with front 14's 48 COMPTIME ERLANG cells : 0
```

**Correction to [`README.md`](./README.md) § 2.4.** "Every record `RUN LOG` … the largest item" is
wrong: no snapshot in any backend prints a record or a variant, so steps 15–16 change **no `RUN LOG`
at all**, and a `RUN LOG` that moves is a bug. The evidence for decision 8 §7's new printed form has
to be written as new `tests/language/` cells, because no existing snapshot can carry it.

Library baseline at `26d4fdc`, 2026-09-18 (`zig build test-libs`):

```
test-libs: 9 passed, 0 failed, 0 known red, 3 skipped, 2 without tests
```

<a id="e20--what-was-not-measured"></a>

## E20 — what was not measured

- **The beam `.S` side of the tag was not executed.** E13 patched the *erlang* output. The
  equivalent `.S` edit (`put_map_assoc` with one more pair, `Op.atom(qualified)` in `put_tuple2`
  and in `is_eq`/`is_tagged_tuple`) is reasoned from `beam_asm.zig`, not run. Step 3's acceptance is
  where it gets executed.
- **wasm's type table** (`options.md` § 7) is a sketch. Nothing about it was built or measured; it
  is [`../05-wasm/`](../05-wasm/README.md)'s to design.
- **The `.d.ts` fix** (E12) was not implemented, only reproduced.
- **Elixir's `:"Elixir.MyApp.User"`** remains unverified here as in
  [step 0](./README.md#step-0--the-maintainer-picks-a-scheme) — `elixir` is not
  installed.
- **Wide records.** Every size figure uses a 2-field record. The `flat_size` gap between a map and a
  tuple grows with arity; re-measure on erika's row handling or jhonstart's html tree before
  deciding T2 (unchanged from Part 1's caveat).
