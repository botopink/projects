# How a value is represented today, per backend

Measured 2026-09-18 at `botopink-lang` `26d4fdc` by compiling one scratch program with the installed
CLI and executing every backend. The program, the commands and the raw output are
[`evidence.md` § E11](./identity-evidence.md#e11--one-program-five-backends). Line numbers are at `26d4fdc`
— the [previous reading](./README.md) was taken at `0e5ff66` and every number in it has drifted by
roughly +200 lines; re-locate by symbol, not by line.

The program:

```botopink
type Person(name: string, age: i32) {
    fn greet(self: Self) -> string { return "hi " + self.name; }
}
type Vec(name: string, age: i32)          // same fields, different type
type Shape { Circle(radius: i32), Dot }   // one payload variant, one unit variant
```

---

## 1. The summary table

| | erlang | beam (`.S`) | commonJS | typescript (`.d.ts`) | wasm |
|---|---|---|---|---|---|
| `Person(name:…, age:…)` | `#{name => …, age => 30}` | `put_map_assoc` over the same keys | `new Person("Ana", 30)` | `declare class Person` | 8 bytes bump-allocated; the **pointer** is the value |
| `Shape.Circle(radius: 5)` | `{'Circle', 5}` | `put_tuple2 [{atom,'Circle'},{integer,5}]` | `{ tag: "Circle", radius: 5 }` | `{ tag: "Circle", radius: i32 }` | 8 bytes: ordinal `0` at `+0`, payload at `+4` |
| `Shape.Dot` | `'Dot'` | `{move,{atom,'Dot'},…}` | `"Dot"` — **a bare string** | `{ tag: "Dot" }` — **contradicts the `.js`** | 4 bytes holding the ordinal `1` |
| `Color.Red` (all-unit enum) | `'Red'` | `{atom,'Red'}` | `"Red"` | `enum Color` member | `i32.const 0` — **no allocation at all** |
| Can the value answer "what type am I?" | **no** for a record; **partly** for a variant (the variant's own name, unqualified) | same | **yes** for a record (`instanceof`); **yes** for a payload variant (`.tag`); **no** for a unit variant | n/a — types are erased at run time | **no**, for anything |

Nothing below is a proposal. It is what `26d4fdc` emits.

---

## 2. erlang

### 2.1 A record-shaped `type` is a bare, untagged map

```erlang
%% type Person: name, age

main() ->
    P = #{name => <<"Ana">>, age => 30},
    V = #{name => <<"Ana">>, age => 30},          %% this is a Vec
    '__bp_print'([(P =:= V)]).                    %% prints: true
```

Built at `erlang.zig:4702-4708` in `callNode`, gated on `record_fields.get(cc.callee)`
(`record_fields` declared `:1591`, filled for local types at `:2781`, for imported ones at
`:2840-2841`). The declaration itself emits **only a doc comment** — `recordForms` (`:5508-5512`)
says why:

```zig
// Records are maps at runtime (`#{field => V}`) — no decl needed.
// (`-record(PascalCase, …)` is invalid Erlang: a capitalised bare atom.)
```

| Consequence | Where |
|---|---|
| `Person(name:"Ana", age:30) =:= Vec(name:"Ana", age:30)` is **`true`** — executed, not reasoned ([E11](./identity-evidence.md#e11--one-program-five-backends)) | — |
| `p.name` → `maps:get(name, P)` | `erlang.zig:4258-4260` |
| `val #(a, b) = p` / field destructuring → the exact map pattern `#{name := N, age := A}` | `destructPatternExpr`, `:4036-4043` |
| an anonymous record is a **tuple**, not a map (`#(7, 11)` → `{7, 11}`) — decision 8 §6 already holds | `snapshots/codegen/erlang/anon_record_literal_two_fields.snap.md` |
| a cross-module record is inlined at the **consumer** — the owner emits no constructor | `import_cross_module_record_construct_and_assoc_fn.snap.md`: `main.erl` writes `A = #{port => 8080, path => <<"/">>}` for `App(8080, "/")` declared in `http.bp` |

That last row matters for the front: the consumer already resolves the owner's field order out of
`CrossModule.exports` (`crossModule.zig:30-50`), whose `ExportInfo.module` **is the owner's module
path**. An imported type's identity therefore costs no new index entry — § 5.

### 2.2 An enum variant is tagged by the variant, unqualified

```erlang
C = {'Circle', 5},
D = 'Dot',
```

| Form | Site |
|---|---|
| payload variant → tagged tuple | `erlang.zig:4776-4782`, inside the `enum_names.contains(name)` branch of the qualified-call path — `name` is the **enum's** name and is discarded |
| unit variant → bare atom | `:4194-4199`, `identAccess` on an enum receiver — likewise discards the receiver |
| the tag in a **pattern** | `patternNode` `:5038-5048` (payload) and `:5030` (unit) |
| the tag itself | `variantTag` `:5073-5076` — returns the variant's own name unless it is an `@Result` tag |

The tag is the variant's name in its original casing, with no enum and no module qualifier. Measured
across the seven repositories (115 `.bp` files, [E14](./identity-evidence.md#e14--how-often-the-names-already-collide)):
**`Circle` is declared in 5 files, `Rect` in 5, `Some` and `None` in 4 each** — seven variant names
occur in more than one file. Two of those enums in one erlang node produce the same term for
different values.

### 2.3 `'__bp_show'/2` sees what it is given

`show_helper_form` (`erlang.zig:554`, attached at `:1146`) has no clause for a record and no clause
for a named variant: a map falls to the final `io_lib:format("~p", [V])`, a tagged tuple to the
`is_tuple` + `is_atom(element(1,V))` clause, which also prints `~p`. Executed:

```
@print(p)  →  #{name => <<"Ana">>,age => 30}
@print(c)  →  {'Circle',5}
@print(d)  →  'Dot'
```

Decision 8 §7 wants `Person(name: "Ana", age: 30)`, `Shape.Circle(radius: 5)`, `Shape.Dot`. The
function cannot write any of the three, because none of the three names is in the term.

## 3. beam

The same two shapes, built by different opcodes, and **byte-identical program output** — the six
printed lines of E11 are the same on both backends.

| Form | Site | Opcode |
|---|---|---|
| record construct | `lowerRecordConstruct` `beam_asm.zig:4516-4536`, called from `:3482-3494` where `cc.callee` is the type name | `put_map_assoc` over atom keys |
| payload variant | `lowerTaggedTuple` `:4563-4576`, called from `:3300-3315` where `rn` is the enum's name | `test_heap` + `put_tuple2` |
| unit variant | `lowerIdentAccess` `:6212-6225` — detects `<PascalCase>.<Member>` **syntactically**, with no `enum_names` map | `{move,{atom,'Dot'},…}` |
| field read | `:6209` | `is_map` + `get_map_elements` |
| variant pattern (payload) | `:5333` | `is_tagged_tuple` with arity `fields.len + 1` |
| variant pattern (unit) | `:5272-5286` | `is_eq` against the atom |
| `variantTag` | `:1684-1689` | parity with erlang's |

One divergence found while measuring and **not** owned by this front: the instance method `greet`
is emitted as `greet/1` on erlang and as `'Person_greet'/1` on beam for the *same* program
(E11) — beam mangles unconditionally where erlang mangles only on collision
(`isRecordMethodCollision`, `erlang.zig:1868`). [Policy 3](./policy-3-module-per-type.md)
deletes both manglings; the divergence is recorded here, not fixed here.

## 4. commonJS — two thirds of the identity, and one hole

```javascript
class Person { constructor(name, age) { this.name = name; this.age = age; } greet() { … } }

const Shape = Object.freeze({
    Circle: (radius) => ({ tag: "Circle", radius }),
    Dot: "Dot",
});
```

| Value | Identity available | Site |
|---|---|---|
| a record | **yes** — a real class; `instanceof`, `constructor.name` | `commonJS.zig:1514-1518` |
| a payload variant | **yes** — an explicit `tag` property, matched at `:3874` | `:1570` |
| a **unit** variant | **no** — the value is the bare string `"Dot"` | `:1563-1566` |

**This corrects [`README.md`](./README.md) § 1.4**, which recorded commonJS as already having the
identity. It has it for two of the three shapes. The consequences of the third, all measured:

1. `Shape.Dot === "Dot"` is `true`. Under decision 8 §4.2 `d is string` would therefore answer
   `true` for an enum value, and a `case` over `Shape | string` (§3.3) would let the `string` arm
   swallow every unit variant.
2. `case` on a unit variant is emitted as `_s === "Get"` — a raw string compare
   (`enum_unit_variants_with_method_using_ident_case.snap.md`). It works only because nothing else
   in the program is that string.
3. The `.d.ts` **disagrees with the `.js` it describes**. `typescript.zig:123` writes
   `{ tag: "Dot" }` for every variant of a mixed enum; the emitter writes a bare string for the unit
   ones. Reproduced live ([E12](./identity-evidence.md#e12--the-dts-contradicts-the-js-for-a-unit-variant));
   **0 of the 314 commonJS snapshots** show the pair, because the `.d.ts` is only emitted for `pub`
   types and no fixture declares a `pub` mixed enum. It is a real divergence with no snapshot
   coverage.
4. `p === v` is `false` — but so is `Person("Ana",30) === Person("Ana",30)`. commonJS compares
   references, so it is right about *different* types for the wrong reason and wrong about *equal*
   values. 1.0.4-beta's front 15 ([`language-tests`](../../../1.0.4-beta/15-language-tests/README.md),
   delivered) already pins the same mechanism for tuples
   (`tests/language/expected-failures.txt`, two `tuple_equality.bp` rows, now
   [`../04-js/`](../04-js/README.md)'s).

13 commonJS snapshots emit a unit variant as a bare string; 12 emit a `tag:` object.

## 5. typescript

`.d.ts` only, erased at run time. It declares `class Person`, and for an enum either a TS `enum`
(all-unit, `typescript.zig:115-119`) or a discriminated union of `{ tag: … }` objects
(`:120-127`). It contributes no run-time identity and takes none; its only stake in this front is
that it must stop describing a shape the emitter does not produce (§ 4.3).

## 6. wasm — no identity of any kind

The worst of the five, and the measurement is unambiguous.

```wat
;; Person(name: "Ana", age: 30)  — 8 bytes off the bump allocator, the POINTER is the value
global.get $__heap_ptr  local.set $__mem0
global.get $__heap_ptr  i32.const 8  i32.add  global.set $__heap_ptr
local.get $__mem0  i32.const 264  i32.store          ;; .name
local.get $__mem0  i32.const 30    i32.store offset=4 ;; .age

;; Shape.Dot  — 4 bytes holding the variant ORDINAL
local.get $__mem3  i32.const 1  i32.store

;; Color.Red  — an all-unit enum is not boxed at all
i32.const 0 ;; Color.Red
```

| Value | Run-time form | What it cannot be told from |
|---|---|---|
| a record | a raw `i32` heap offset | any other record, any string, any `i32` |
| a variant of a **mixed** enum | a pointer to a cell holding the variant's **ordinal** | the first variant of any other mixed enum (both ordinal `0`) |
| a variant of an **all-unit** enum | the ordinal itself, inline | the `i32` of the same value — `Color.Red` *is* the number `0` |

And the printer is statically dispatched, so it prints the pointer. Executed under `wasmtime`, the
same program whose erlang run prints six correct lines prints:

```
Ana
300          ← p.greet(), a string: the POINTER was printed
false        ← p == v: pointer comparison
288          ← Shape.Circle(radius: 5)
296          ← Shape.Dot
272          ← Person(name: "Ana", age: 30)
```

This front does **not** own `wat.zig` ([`README.md`](./README.md) § *Does not touch*; decision 3's box
is [`../05-wasm/`](../05-wasm/README.md)'s D8-1/D8-2). It records the
shape here because 05 has to build the box, and the box's tag should be the **same identity**
this front puts in the erlang/beam value — otherwise `is Person` means two different things on two
backends. § 7 of [`options.md`](./identity-options.md) says what wasm can store: not the atom (wasm has no
atom table), but an index into a per-module type table whose entries are the atoms, so the two agree
by construction.

## 7. A type id exists in the compiler and never reaches codegen

`ast.TypeDecl.id`, `Env.allocTypeId()`, `Binding.typeId` and the `type_ids` map exist in
`src/comptime/**` (unchanged since the previous reading — re-verify by symbol). Grepping
`typeId|type_id|TypeId` across `src/codegen/**` still returns **zero hits**. A counter that restarts
per build is the wrong identity for a value that crosses a module boundary anyway; the stable,
collision-checked, human-readable one is [A2](./declaration-qualifier.md)'s atom.

## 8. What the four decision-8 features need — separately

Each row is the **minimum** the value must carry for that feature alone.

| Decision 8 | The minimum a value must carry | Why that, and not less |
|---|---|---|
| **§4.2 `x is Point`** — "the constructor of a named type" | a tag that is injective over the program's declared types | The bare type name is not enough: `CrossModule.exports` is keyed by the bare symbol name (`crossModule.zig:112-135`), so two modules may both export `type User`. The tag must be unique per *(module, declaration)*. **Structural typing does not reach it**: 6 distinct field-sets are already shared by 18 differently-named types in the tree (E14) |
| **§4.2 `x is Option.Some(v)`** — the variant | a tag unique per *(module, type, variant)* | `Circle` is declared in 5 files, `Some`/`None` in 4 (E14) |
| **§3.3 / §5.4 a `case` over `Person \| Car`, exhaustive with no `_`** | the tag must be readable **inside a pattern or a guard** | This is the sharpest requirement and it is what rules out option (c): a fun call in a guard is `illegal guard expression`, measured ([E17](./identity-evidence.md#e17--a-carried-function-cannot-be-read-in-a-guard)). A tag that can only be *called* forces a dispatch before the `case`, which is exactly the catch-all §5.4 forbids |
| **§7 one source-shaped formatter per type** | the tag must **name the formatter** | A tag is enough if the backend also emits a lookup table. It is *more* than enough if the tag is the A2 atom under [policy 3](./policy-3-module-per-type.md), because the atom is then a loadable module holding the type's functions: the formatter is `(maps:get('__bp_type', V)):format(V)`, one `call_ext`, no table, and a crash inside it names the type in the stack trace. **This is the only one of the four that forces the identity to be the module atom rather than any injective tag** — see [`halves-and-ordering.md`](./halves-and-ordering.md) § 2 |
| §2.1 nothing leaves `unknown` unchecked | the check it needs is §4.2's | — |

Sequencing note carried forward and re-verified at `26d4fdc`: `is` is a lexer token
(`lexer.zig`) parsed **only** as a type-guard return annotation (`parser/decls.zig`); there is no
`x is T` expression. [`../01-checker/`](../01-checker/README.md) N21 lands it, N20 the unions, N22
the `case` arms, N19 `unknown`. This front supplies what those expressions lower to.
