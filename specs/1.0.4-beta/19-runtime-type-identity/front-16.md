# The coupling with front 16, and why 16 goes first

[Front 16](../16-module-naming/README.md) decides what a **module** is called. This front decides
what a **value** knows about itself. The premise that binds them: the identity to put inside the
value is the atom 16 gives the declaration
([A2](../16-module-naming/declaration-qualifier.md)), and under
[policy 3](../16-module-naming/policy-3-module-per-type.md) — decided 2026-09-17, one BEAM module per
`type` and per `behavior` — that atom is also a **loadable module**. This file says exactly what
that buys, exactly what it does not, and in which order the two fronts land.

---

## 1. What 16 gives 19, before policy 3

| From 16 step 1 | What 19 does with it |
|---|---|
| `erlDeclAtom(alloc, id, kind, decl, ?hash)` with a `Kind` enum | **is** the tag. 19 calls it; it does not define an atom rule of its own |
| `erlAtom`'s clause 3b (runs of `_` collapsed, so `__` is reserved) | makes `__t__` / `__v__` parseable, and therefore the tag reversible |
| `RESERVED` (the OTP module names) and the 250-byte check | apply unchanged to a type atom — `bp@math__t__vector` cannot collide with OTP |
| **the collision check over rendered atoms** in `crossModule.build` (`crossModule.zig:86`) | extended by 19 to the type and variant atoms: two declarations that render the same atom is a located diagnostic, not a silent winner. This is the check that makes the identity trustworthy |
| A2 § 5's decoder | extended by 19 with one clause for `__v__` ([E15](./evidence.md#e15--the-qualified-variant-tag)) |

Without 16, 19 would have to invent the same atom rule a second time. Two spellings of one atom is
precisely the failure 16 exists to remove, so **19 never defines an atom**; it defines a
**placement**.

## 2. What policy 3 gives 19 for free

Policy 3 emits `<pathAtom>__t__<decl>` as a real module holding the type's constructor and methods
([16 E22](../16-module-naming/evidence.md#e22--four-sibling-s-modules-from-one-source-file)). When
19's tag is that same atom:

| Free | Because |
|---|---|
| **The §7 formatter is a `call_ext`, not a table.** `'__bp_show'(#{'__bp_type' := T} = M, _) -> T:format(M);` | the tag *is* the module that holds `format/1`. Without policy 3 the backend must emit, per program, a dispatch table from atom to formatter and keep it in sync with the emitted types |
| **A `behavior`'s `Display` implementation is reachable the same way** — decision 8 §7's "a type implementing `Display` prints its `display()`, also when nested" | policy 3 emits `__im__<decl>`; the formatter can try the implement module and fall back to the derived one |
| **A crash inside a formatter names the type** | policy 3's own gain ([16 E24](../16-module-naming/evidence.md#e24--a-stack-trace-names-the-owning-type)): `{models@user__t__pessoa, format, 1, [{file,…},{line,3}]}` |
| **The identity is verifiable at run time** — `code:which(T)` on a tag answers a real `.beam` | nothing else in the scheme can be checked that cheaply |
| **`is` can become a `call_ext` if it ever needs to** (a generic `T:matches(V)`) | not needed for §4.2, but the door is open at zero cost |

## 3. What 19 still has to add — all of it

Policy 3 changes **where functions are emitted**. It changes nothing about what a value looks like.
After policy 3 lands, `Person(name: "Ana", age: 30)` is still the bare map `#{name => …, age => …}`
and `Shape.Dot` is still the bare atom `'Dot'`. Every row below is 19's, and none of it exists in
16's steps 1–13.

| 19 adds | Sites at `26d4fdc` |
|---|---|
| the `'__bp_type'` key in a record term | `erlang.zig:4702-4708`; `beam_asm.zig:4516-4536` |
| the type qualifier on a variant tag | `erlang.zig:5073-5076` + its four call sites (`:4194-4199`, `:4776-4782`, `:5030`, `:5038-5048`); `beam_asm.zig:1684-1689` + `:6212-6225`, `:3300-3315`, `:5272-5286`, `:5333` |
| the owner's atom for an **imported** type at the consumer's inline construct | `erlang.zig:2840-2841` reading `ExportInfo.module` (`crossModule.zig:30-50`) — no new index key (verified) |
| `'__bp_type'` hidden from user-visible output | `show_helper_form`, `erlang.zig:554` |
| the `x is T` lowering for a named type | new, after 06 N21 |
| the `case` arm over a named type or a union of them | new, after 06 N20/N22 |
| §7's per-type formatter dispatching on the tag | new; this is 01 step 6's **D8-5** row, transferred (§ 5) |
| the same identity, or an agreeing one, on commonJS's unit variants and in wasm's box | § 7 of [`options.md`](./options.md) |

**Measured overlap of the two fronts' snapshot sets** — the 188 files policy 3 re-records are those
carrying a `%% type` / `%% behavior` / `%% implement` marker; 19's 130 are those that also *build* a
record or a variant. They are largely the same files (62 of 19's 130 are erlang, and 81 erlang files
carry the marker), which is the whole reason the two cannot land together: a diff in one of those
files would carry a module split **and** a value reshaping at once, and
[`../overview.md`](../overview.md#rules-carried-forward) requires each re-recorded snapshot to be
classified.

## 4. Which lands first — 16, and it is not close

| Reason | Detail |
|---|---|
| **1. The helper is 16's** | 19 step 1 is a consumer of `erlDeclAtom`. Writing it twice creates two spellings of one atom |
| **2. The files** | 16 steps 7–13 own `erlang.zig` and `beam_asm.zig` **wholesale** ([16 § 9](../16-module-naming/policy-3-module-per-type.md#9-sequencing--decided-2026-09-17-one-front-not-two)). 19 edits eight functions in each. They cannot be open at the same time |
| **3. The snapshots** | 188 (16) and 130 (19) overlap heavily. Sequencing keeps one reason per diff; overlapping them makes classification impossible |
| **4. The formatter** | writing 19 step 5 before policy 3 means emitting a per-program dispatch table and then deleting it when policy 3 makes the tag a module |
| **5. `botopink run`** | policy 3's step 1 fixes `cli/run.zig` to `erl -pa` ([16 E25](../16-module-naming/evidence.md#e25--botopink-run-breaks-under-policy-3)). 19's `tests/language/` acceptance cells run programs through the CLI; they need that fix to exist |

**There is one argument the other way, and it does not hold.** 19 steps 1–3 (the tag in the value)
touch no atom-*rendering* site and could in principle land first with a private helper. But then
16's atom rename would move the tag too, re-recording 19's 130 snapshots a second time for a reason
that is 16's. Sequencing 16 → 19 costs nothing; sequencing 19 → 16 costs one full re-record.

## 5. The circular dependency this exposes, and how to cut it

The milestone's current order is a cycle:

```
06 checker ──► 01 step 6 (decision 8 at run time) ──► ... 01 closes ──► 16 ──► 19
                   ▲                                                         │
                   └──── needs the identity 19 supplies ──────────────────────┘
```

01 step 6's rows **D8-1** (`is`), **D8-3** (`case` arms) and **D8-5** (the formatter) cannot be
written for a *named* type before this front exists, and 16 cannot start until 01 closes
([`../fronts.md`](../fronts.md) note 9).

**The cut: 01 step 6 keeps every decision-8 row that needs no stored identity, and 19 takes the
named-type half.**

| Row | Stays with 01 step 6 | Moves to 19 |
|---|---|---|
| D8-1 `x is T` | `i32`/`i64`/`f64`/`string`/`bool` by range and kind; `#(i32, string)` by arity; wasm reads decision 3's box tag | `x is Point`, `x is Option.Some(v)`, `x is Box<unknown>` on erlang and beam |
| D8-2 `unknown` / unions | the wasm box, §2.3 numeric equality | a union whose members are **named types** on erlang/beam |
| D8-3 `case` arms | literal, range, tuple, `_`, guards, `..` | an arm that is a named type or a section (§5.3b) |
| D8-4 `row.label` → index | all of it | — |
| D8-5 the formatter | the primitive, array and tuple text; `f64` always `5.0` | the `record` and `variant` rows of §7's table, and `Display` |
| D8-6 `loop (condition)` | all of it (already delivered by 06 G0) | — |

With that cut the order is acyclic and every front keeps its files:

```
12 ──► 06 ──► 01 steps 5–6 (primitives, wasm box, labels, loop; named types deferred)
                       │
                       └──► 16 (atom rename, then policy 3) ──► 19 (the tag, then the named-type
                                                                     half of D8-1/2/3/5)
```

This is the one decision the front needs from the maintainer before it can be scheduled
([`README.md` § Open questions](./README.md#6-open-questions-for-the-maintainer)), and it changes
rows in [`../fronts.md`](../fronts.md) and [`../01-backend-residuals/`](../01-backend-residuals/README.md)
that this front does not edit.

## 6. If the maintainer prefers one front instead of two

Folding 19 into 16 as steps 14–17 is defensible — it is the same files, the same snapshots and the
same atom. Against it:

- 16 is already ≈ 9 days and 208 snapshots. 19 adds ≈ 3–4 days and 130 more, 62 of them
  files 16 has already re-recorded once.
- 19's steps 4–6 depend on **06**, which 16 does not; folding them in makes 16 depend on 06's
  N20/N21/N22 landing, which is a dependency 16 currently does not have.
- The front boundary is the unit of the `todo.md` and the branch. A nine-day front with two
  unrelated acceptance sets is what the milestone's own front rules exist to avoid.

**Recommendation: two fronts, 16 then 19**, with 16's `erlDeclAtom` and the `__v__` `Kind` variant
agreed while 16 is being written so 19 needs no change to 16's files.
