# Front 19 — runtime type identity

**Premise (maintainer, 2026-09-17):** a type already gets a unique atom from
[`../16-module-naming/`](../16-module-naming/README.md) — `erlAtom(path)` plus the
[A2](../16-module-naming/declaration-qualifier.md) declaration suffix. Use **that atom, inside the
value**, so that at run time a `Person` can be told from a `Car` — which is what
[decision 8](../08-review-backlog/decision-8-language.md)'s `is` (§4), unions (§3), `case` (§5) and
one-formatter-per-type printing (§7) all need and none of them can get today.

**Priority:** high — it is the run-time half of decision 8 for every **named** type, and
[`../01-backend-residuals/`](../01-backend-residuals/README.md) step 6's rows D8-1, D8-3 and D8-5
cannot be written for a named type without it (§ 5).
**Depends on:** [`../16-module-naming/`](../16-module-naming/README.md) **in full, including
[policy 3](../16-module-naming/policy-3-module-per-type.md)** — it owns the atom rule, the collision
check and `erlang.zig` / `beam_asm.zig` wholesale ([`front-16.md`](./front-16.md) § 4) ·
[`../06-checker/`](../06-checker/README.md) N19–N22 for steps 4–6, which type what this front lowers
· runs **after** [`../01-backend-residuals/`](../01-backend-residuals/README.md) has closed
**Owns:** the value-shape sites of `src/codegen/erlang.zig` (`:4702-4708` record construct,
`:4194-4199` unit variant, `:4776-4782` payload variant, `:5030` / `:5038-5048` variant patterns,
`:5073-5076` `variantTag`, `:554` `show_helper_form`, `:2840-2841` imported-record inlining) and
their twins in `src/codegen/beam_asm.zig` (`:4516-4536` `lowerRecordConstruct`, `:3482-3494` its call
site, `:4563-4576` `lowerTaggedTuple`, `:3300-3315` its call site, `:6212-6225` unit variant,
`:5272-5286` / `:5333` variant tests, `:1684-1689` `variantTag`) · a `typeAtom` / `variantAtom` pair
beside 16's `erlDeclAtom` in `src/codegen/crossModule.zig` · the **130** `snapshots/codegen/{erlang,beam}/`
cells whose value shape changes ([`blast-radius.md`](./blast-radius.md))
**Does not touch:** `src/codegen/wat.zig` — wasm carries no identity at all
([`representation.md`](./representation.md) § 6) and its box is
[decision 3](../08-review-backlog/semantics-decisions.md)'s, owned by 01 step 6 · `src/comptime/**`
(06) · `libs/std/**` and the library repositories — **no `.bp` change anywhere** ·
`src/codegen/commonJS.zig` and `typescript.zig` **unless the maintainer assigns step 6** (§ 3)

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless they start with
`modules/`, `libs/`, `scripts/` or `tests/`. **Line numbers and counts read at `botopink-lang`
`26d4fdc` (2026-09-18)** — the first draft of this front was written against `0e5ff66` and every
line number in it has drifted by roughly +200. Re-locate by symbol. Every number below was run; the
transcripts are in [`evidence.md`](./evidence.md).

| Deep dive | Holds |
|---|---|
| [`representation.md`](./representation.md) | what a record and an enum value are on each of the five backends, measured, and what each of the four decision-8 features needs |
| [`options.md`](./options.md) | the four identities (a)–(d), T1/T2, and the variant-tag spelling, each with its cost |
| [`front-16.md`](./front-16.md) | what policy 3 gives this front free, what it still has to add, the ordering, and the circular dependency it exposes |
| [`blast-radius.md`](./blast-radius.md) | the counts, with the command that produced each |
| [`evidence.md`](./evidence.md) | Part 1 (hand-written fixtures, 2026-09-17) and Part 2 (the compiler's own output, 2026-09-18) |

---

## 1. Problem

Nothing in a record value names its type, on any backend; and where a variant *is* tagged, the tag is
the variant's bare name, which is not unique. Reproduced by compiling one program and running every
backend ([E11](./evidence.md#e11--one-program-five-backends)):

```botopink
type Person(name: string, age: i32) { fn greet(self: Self) -> string { … } }
type Vec(name: string, age: i32)                 // same fields, different type
type Shape { Circle(radius: i32), Dot }
```

| | erlang / beam | commonJS | wasm |
|---|---|---|---|
| `Person(name:"Ana", age:30)` | `#{name => <<"Ana">>, age => 30}` — no tag | `new Person(…)` | a bare heap pointer |
| `Person(…) == Vec(…)` | **`true`** | `false` (reference identity, so two *equal* Persons are also `false`) | `false` (pointer) |
| `Shape.Circle(radius: 5)` | `{'Circle', 5}` | `{ tag: "Circle", radius: 5 }` | ordinal `0` in a cell |
| `Shape.Dot` | `'Dot'` | `"Dot"` — **a bare string** | ordinal `1` in a cell |
| `Color.Red` (all-unit enum) | `'Red'` | `"Red"` | **`i32.const 0`** — the value *is* the number |
| `@print(p)` | `#{name => …,age => 30}` | `Person { name: 'Ana', age: 30 }` | `272` — the pointer |

Decision 8 §7 asks for `Person(name: "Ana", age: 30)` on all four. `'__bp_show'/2`
(`erlang.zig:554`) prints a map because a map is all it is given.

### 1.1 Three corrections to the first draft of this front

Kept because the first draft asserted them and they are wrong.

| First draft said | Measured at `26d4fdc` |
|---|---|
| "commonJS already has the identity — this is an erlang/beam gap" (§ 1.4) | **Two thirds true.** A record is a class and a payload variant carries `.tag`, but a **unit** variant is the bare string `"Dot"` (`commonJS.zig:1563-1566`), so `d is string` would answer `true` for an enum value, and the emitted `.d.ts` declares `{ tag: "Dot" }` for the same value ([E12](./evidence.md#e12--the-dts-contradicts-the-js-for-a-unit-variant)) — a live `.js`/`.d.ts` contradiction with **0** snapshots covering it |
| "Every record `RUN LOG` and construct line moves — the largest item" (§ 2.4) | **The `RUN LOG` half is zero.** Across all 1 254 snapshots and 997 non-empty `RUN LOG` lines, none prints a record, a tagged tuple, a unit variant atom, a JS class instance or a `tag:` object ([E19](./evidence.md#e19--the-snapshot-blast-radius)). Steps 2–3 change **no `RUN LOG`**, and one that moves is a bug |
| "T1 costs nothing measurable; T2 is 2.5× faster" ([E10](./evidence.md#e10--build-and-match-2-000-000-iterations)) | **Not reproducible.** `erlc +to_asm` shows the compiler **deletes the test entirely** when the value's shape is statically known ([E18](./evidence.md#e18--the-honest-timing)). Through an opaque call the three `is` lowerings are within 0.5 ns. What is real: T1 = +2 words per record and +0.165 ns per construct; the enum half is free |

And one thing the first draft did not consider, which changes the shape of steps 2–3: **qualify the
variant tag instead of prefixing the variant term** (§ 2.2). It is free in space, changes no opcode
and no arity, and makes step 3's "`is_tagged_tuple`'s arity argument grows by one" unnecessary.

## 2. The proposal

### 2.1 The identity is the A2 atom

```
typeAtom(path, decl)             = erlAtom(path) ++ "__t__" ++ lower(decl)
variantAtom(path, decl, variant) = typeAtom(path, decl) ++ "__v__" ++ lower(variant)
```

The first line is [A2](../16-module-naming/declaration-qualifier.md) verbatim —
`erlDeclAtom(alloc, id, .t, decl, null)`, written by [16 step 1](../16-module-naming/README.md#step-1--one-canonical-identity-one-renderer-per-backend).
The second is the **one thing this front asks 16 for**: a `__v__` segment so a variant tag decodes
the same way. Both are legal **unquoted** atoms and both decode with one extra clause on A2 § 5's
decoder ([E15](./evidence.md#e15--the-qualified-variant-tag)).

The other three identities are ruled out, each by a measurement, in [`options.md`](./options.md) § 1:
(b) a non-atom tag costs the same words and needs a whole-program id pass `codegenEmit` cannot do;
(c) an identity reached through a carried function **cannot be read in a guard**
(`illegal guard expression`, [E17](./evidence.md#e17--a-carried-function-cannot-be-read-in-a-guard)),
so decision 8 §5.4's exhaustive `case` is impossible under it; (d) structural typing already fails on
real code — 6 field-sets are shared by 18 differently-named types and `Circle` is declared in 5 files
([E14](./evidence.md#e14--how-often-the-names-already-collide)).

### 2.2 Where it sits

| | Recommended | Cost |
|---|---|---|
| a **record** | **T1** — one key, `#{'__bp_type' => 'app@models__t__person', name => …}` | +2 words; `maps:get` and `#{x := X}` patterns keep working unchanged ([E1](./evidence.md#e1), re-confirmed on the compiler's own output in [E13](./evidence.md#e13--both-spellings-applied-to-the-compilers-own-output)) |
| an **enum variant** | **qualify the tag atom**, not prefix the term: `{'app@models__t__shape__v__circle', 5}` and `'app@models__t__shape__v__dot'` | **zero words** — an atom is an immediate and the tuple keeps its arity ([E16](./evidence.md#e16--the-size-of-every-candidate)). No opcode changes: `is_eq` stays `is_eq`, `is_tagged_tuple` keeps `fields.len + 1` |
| an **anonymous** record / tuple | untagged | decision 8 §6 — positional, compared without labels; `is #(i32, string)` stays an arity-plus-element test |
| `{ok, V}` / `{error, E}` | untouched | built by the `#[@result]` transform, already special-cased in both `variantTag`s |

T2 (the whole record as a tagged tuple, 7 words instead of 13) stays open as step 7, and the reason
to take it is **space, not time** — see the E10 correction above.

### 2.3 What each decision-8 item becomes

```erlang
%% x is Person
is_map(X) andalso maps:get('__bp_type', X, undefined) =:= 'app@models__t__person'

%% x is Shape          — the checker knows the variant list; every test is guard-legal (E15)
X =:= 'app@models__t__shape__v__dot'
  orelse (is_tuple(X) andalso tuple_size(X) > 0
          andalso element(1, X) =:= 'app@models__t__shape__v__circle')

%% case v { Person { p -> … } Car { c -> … } }   — exhaustive, no `_` (E4)
case V of
    #{'__bp_type' := 'app@models__t__person'} = P -> …;
    #{'__bp_type' := 'app@models__t__car'}    = C -> …
end

%% @print(p)  →  §7's `Person(name: "Ana", age: 30)`
'__bp_show'(#{'__bp_type' := T} = M, _) -> T:format(M);   %% under policy 3: one call_ext, no table
```

The last line is the reason the identity must be the **module** atom and not any injective tag:
under [policy 3](../16-module-naming/policy-3-module-per-type.md) the tag *is* the module that holds
`format/1`, so §7's per-type formatter needs no dispatch table and a crash inside it names the type
in the stack trace ([`front-16.md`](./front-16.md) § 2).

### 2.4 What it fixes that was not asked for

`Person(name:"Ana", age:30) == Vec(name:"Ana", age:30)` is **`true`** on erlang and beam today and
becomes `false` (E11, E13). commonJS already answers `false`, but by reference identity, so it also
answers `false` for two *equal* Persons — the same mechanism front 15 already pins for tuples
(`tests/language/expected-failures.txt`, two `tuple_equality.bp` rows, owner 01 step 6). No row in
[`../01-backend-residuals/`](../01-backend-residuals/README.md) names the record case.

### 2.5 Costs, named

| Cost | Size |
|---|---|
| 130 erlang + beam snapshots change one or two emitted lines each | [`blast-radius.md`](./blast-radius.md) § 1 — classify, never bulk-accept ([`../overview.md`](../overview.md#rules-carried-forward)) |
| `RUN LOG`s that move | **0** — and one that moves is a bug (E19) |
| Between step 3 and step 5 the printed form of a record is *worse* than today (it shows `'__bp_type'`) | both steps must land in the same release; step 5's acceptance closes it |
| +2 words per record value, +0.165 ns per construct; the enum half free | E16, E18 |
| 142 new atoms for the whole ecosystem | against 10 397 in a bare node and a 1 048 576 limit (E14) |
| A user field literally named `__bp_type` | the `__` prefix is reserved by [A2 § 4](../16-module-naming/declaration-qualifier.md); 16's collision check rejects it |
| `.bp` source change in any library | **none** |

## 3. Steps

### Step 1 — `typeAtom` / `variantAtom`, no behaviour change

Beside 16's `erlDeclAtom` in `crossModule.zig`, reusing its `Kind` enum and its `RESERVED` / 250-byte
checks. Extend 16's collision check (`crossModule.build`, `crossModule.zig:86`) to the type and
variant atoms. **Nothing consumes them yet.**

**Acceptance:**
- [ ] Every snapshot in all four codegen directories byte-identical (`zig build test`)
- [ ] Unit tests: a single-segment path, a multi-segment path, a reserved name, a type whose name
      needs escaping, a variant whose name needs escaping, a name over 250 bytes
- [ ] Two declarations rendering the same atom is a **located diagnostic**, with a test
- [ ] A2 § 5's decoder, extended with the `__v__` clause, is a test — `variantAtom` round-trips to
      `{variant, path, "t", decl, variant}` (E15)

### Step 2 — the tag in the value, erlang

`erlang.zig:4702-4708` adds `'__bp_type' => typeAtom(owner, cc.callee)`, where `owner` is
`Emitter.module_name` (`:1586`) for a local type and `ExportInfo.module` (`crossModule.zig:30-50`,
read at `:2840-2841`) for an imported one — **no new cross-module index key**
([`options.md` § 6](./options.md#6-cross-module--verified-and-free)). `variantTag` (`:5073-5076`)
returns the qualified atom, which covers the construct sites (`:4194-4199`, `:4776-4782`) and the
pattern sites (`:5030`, `:5038-5048`) at once. Access, destructuring and `case` machinery are
**untouched**.

**Acceptance:**
- [ ] A new fixture: two types with identical fields are `!=`, executed on erlang (today `true`,
      E11)
- [ ] A new fixture: two enums declaring the same variant name, both `case`d in one program,
      executed — today they produce the same term (E14)
- [ ] Existing `#{x := X}` destructuring, `maps:get` access and every `case` cell still run
      (E13 pins this on real emitted output)
- [ ] The 62 erlang cells re-recorded and classified one by one; **no `RUN LOG` moves**
- [ ] An imported type constructed in a consumer carries the **owner's** atom, executed
      (`import_cross_module_record_construct_and_assoc_fn.snap.md` is the fixture to extend)

### Step 3 — the same on beam

`lowerRecordConstruct` (`:4516-4536`, called from `:3482-3494` where `cc.callee` is the type name),
`variantTag` (`:1684-1689`), the unit-variant construct (`:6212-6225`, where `rn` is the enum's
name), and the two tests (`:5272-5286` `is_eq`, `:5333` `is_tagged_tuple`). Under the recommended
spelling **no arity and no opcode changes** — only the atom the tests compare against.

**Acceptance:**
- [ ] `scripts/beam_export_audit.sh` green at its current total
- [ ] The erlang and beam `RUN LOG`s of every shared fixture agree, line for line
- [ ] The 68 beam cells re-recorded and classified; no `RUN LOG` moves
- [ ] `grep -c is_tagged_tuple` over `snapshots/codegen/beam/` is unchanged, and no
      `is_tagged_tuple` arity argument differs from before — the check that the free spelling was
      actually taken

### Step 4 — `is` and `case` over a named type — **after 06 N20/N21/N22**

`x is T` for a named type and a variant; a `case` arm that is a named type or a union of them
(decision 8 §4.2, §3.3, §5.1, §5.3b). These are 01 step 6's rows **D8-1** and **D8-3** for the
named-type half; see § 5 and [`front-16.md`](./front-16.md) § 5.

**Acceptance:**
- [ ] `tests/language/` cells for `x is Point`, `x is Option.Some(v)`, and a `case` over
      `Person | Car` with **no `_`**, passing on erlang and beam
- [ ] The matching lines leave `tests/language/expected-failures.txt`
- [ ] A `case` over a union is emitted as erlang patterns only — **no type test of the backend's
      own**, and no catch-all ([E4](./evidence.md#e4))
- [ ] erlang, beam and commonJS agree on every cell

### Step 5 — §7's formatter — **after step 4**

`'__bp_show'/2` dispatches on the tag. Under policy 3 that is `T:format(M)`, one `call_ext`; the
per-type `format/1` is emitted into the type's own module. Hide `'__bp_type'` from user-visible
output. This is 01 step 6's row **D8-5** for the `record` and `variant` rows of §7's table, plus
`Display`.

**Acceptance:**
- [ ] `@print(Point(x: 1, y: 2))` prints `Point(x: 1, y: 2)` on erlang and beam, `@print(Shape.Dot)`
      prints `Shape.Dot`, `@print(Shape.Circle(radius: 4))` prints `Shape.Circle(radius: 4)` — new
      `tests/language/` cells, because **no existing snapshot prints a composite value** (E19)
- [ ] A type implementing `Display` prints its `display()`, also when nested (decision 8 §7)
- [ ] `'__bp_type'` appears in no printed output
- [ ] The four backends produce the same text for the same program

### Step 6 — the commonJS unit-variant hole — **only if the maintainer assigns it**

`commonJS.zig:1563-1566` emits a unit variant as a bare string, so `Shape.Dot === "Dot"` and the
emitted `.d.ts` (`typescript.zig:115-127`) describes a shape the emitter does not produce (E12).
Two ways out, and the front does not choose unilaterally because `commonJS.zig` is 01's:

| | Cost |
|---|---|
| emit `{ tag: "Dot" }` and make `is` / `case` read `.tag` uniformly | 13 commonJS snapshots; the `.d.ts` becomes true |
| keep the string and make the checker refuse `is string` on an enum value | 0 snapshots; contradicts decision 8 §4.1 ("`is` tests the value, not the origin") |

**Acceptance (either way):**
- [ ] The `.js` and the `.d.ts` of the same program agree — a new fixture with a `pub` mixed enum,
      which no snapshot has today
- [ ] `x is string` answers `false` for a unit variant on commonJS, as it does on erlang

### Step 7 — decide T2

Re-measure on a wide record from a real program (erika's rows, jhonstart's html tree) before
committing. If the space win holds, rewrite construct + access + destructure + patterns to the
tagged tuple in one mechanical commit.

**Acceptance:**
- [ ] A maintainer decision recorded here, whichever way it goes, with the re-measured numbers —
      **not** E10's, which do not survive (E18)

## 4. Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] `zig build test-libs` at its baseline — `9 passed, 0 failed, 0 known red, 3 skipped, 2 without
      tests` (measured at `26d4fdc`); `scripts/known-red-libs.txt` still empty
- [ ] `scripts/beam_export_audit.sh` green at its current total
- [ ] Every re-recorded snapshot classified (construct line / variant atom / nothing else); **no
      `RUN LOG` re-recorded in steps 1–3**, and one that is, is a bug with an explanation in the
      commit message
- [ ] erlang, beam and commonJS agree on `is`, on a union `case`, and on §7's print text
- [ ] The invariant, as a test: **two values carry the same identity if and only if they were built
      by the same declaration** — one cell per backend
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Branch `fix/runtime-type-identity`; no push, no merge

## 5. Ownership conflicts

Against the fronts open in [`../fronts.md`](../fronts.md). `yes` = may run at the same time ·
`no` = shares a file or a snapshot directory, sequence them · `seq` = no shared file, but the
milestone orders them.

| Against | | Why |
|---|---|---|
| **01** backend-residuals | **no** | shares `erlang.zig`, `beam_asm.zig` and `snapshots/codegen/{erlang,beam}/` wholesale. **19 runs after 01 closes**, and 01 step 6's rows D8-1, D8-3 and D8-5 are split: the primitive, tuple, wasm-box and `loop` halves stay with 01; the **named-type** halves move to 19 steps 4–5 ([`front-16.md`](./front-16.md) § 5) |
| **06** checker | **no** | no shared source file (06 owns `src/comptime/**` and `src/parser/**`), but 06 may re-record **all four** codegen directories. 06 first; 19 steps 4–6 additionally *depend* on N19–N22 |
| **07** comptime-dedup | **yes** | 07 owns `src/comptime/snapshot.zig` and `snapshots/comptime/**`; 19 touches neither |
| **08** review-backlog | **no** | 08 owns `src/codegen/tests/**`, where 19 adds fixtures, and its wave A reads the snapshots 19 re-records. 19 needs a fixture carve-out, as 01 has one; wave A runs after 19 |
| **13** ecosystem-migration | **seq** | no library needs a source change (measured: 0 of 115 `.bp` files write a value shape), but every library's erlang and beam cell executes output whose value shape 19 changes. 13 re-runs after 19 lands |
| **16** module-naming | **no** | shares `crossModule.zig`, `erlang.zig`, `beam_asm.zig` and both snapshot directories; 16 owns the two emitters **wholesale** for its steps 7–13. **16 first, in full** — the helper, the files and the formatter dispatch all point the same way ([`front-16.md`](./front-16.md) § 4) |
| **17** language-test-expansion | **yes** | 17 adds no source change and re-records no snapshot. The one shared file is `tests/language/expected-failures.txt`, delete-only, and the `tests/language/` cells of steps 4–5 must be coordinated with it |
| **18** comptime-on-beam | **no**¹ | shares the **files** `erlang.zig` (18's carve-out is `ComptimeModule` / `emitComptimeModule`, 19's are the value-shape sites) and, for 18's step 3, `beam_asm.zig`'s untyped comptime mode — disjoint functions in both. Snapshot overlap **measured at 0**: none of 18's 48 `COMPTIME ERLANG` cells is one of 19's 130. A carve-out is defensible; the letter of the front rule says sequence |

¹ The only "no" in the table that a maintainer could turn into a "yes" by granting a carve-out, and
the measurement supporting it is in [`blast-radius.md`](./blast-radius.md) § 2.

## 6. Open questions for the maintainer

1. **The split of 01 step 6's D8 rows** ([`front-16.md`](./front-16.md) § 5). As written, 01 step 6
   needs this front and this front runs after 01 closes — a cycle. The proposed cut is that 01 keeps
   every row that needs no stored identity and 19 takes the named-type half of D8-1, D8-2, D8-3 and
   D8-5. **This is the decision that lets the front be scheduled at all**, and it changes rows in
   `fronts.md` and in `01-backend-residuals/README.md` that this front does not edit.
2. **`__v__` as an A2 `kind` segment** (§ 2.1). This front needs one addition to 16's atom rule.
   Agreeing it while 16 is being written costs 16 nothing; agreeing it afterwards means editing 16's
   files from 19.
3. **commonJS's unit variant** (step 6). Either 13 snapshots and a true `.d.ts`, or a checker rule
   that contradicts decision 8 §4.1. `commonJS.zig` is 01's, so this front will not take it
   unasked.
4. **T1 or T2 as the end state** (step 7). T1 now, T2 later is the recommendation. Landing T2
   directly saves one snapshot migration at the price of doing the semantics and the representation
   rewrite in one commit. The 2.5× speed argument from the first draft is **withdrawn** (E18); the
   remaining argument for T2 is 6 words per record value.
5. **Does a `behavior` need an atom too?** Nothing in decision 8 asks to test "implements `Show`" at
   run time. A2 reserves `__b__`; this front does not use it.
6. **wasm.** [`representation.md`](./representation.md) § 6 shows wasm has *no* identity — a record
   is a raw pointer and `Color.Red` is literally the integer `0`. The sketch in
   [`options.md`](./options.md) § 7 (an index into a per-module table of the atoms, so the index and
   the atom agree by construction) is untested and is 01 step 6's to design. If 01 designs it
   independently, `is Person` will mean two different things on two backends.

---

## Rows to add to `fronts.md` and `overview.md`

Paste as-is. **This front edits neither file.**

### 1. `fronts.md` — the ownership row

Add after front 18's row (or after 17's, if 18 has not been added yet):

```markdown
| **19** [`runtime-type-identity`](./19-runtime-type-identity/README.md) | the value-shape sites of `src/codegen/erlang.zig` (record construct, unit and payload variant, variant patterns, `variantTag`, `__bp_show`, the imported-record inlining) and their twins in `src/codegen/beam_asm.zig` · `typeAtom`/`variantAtom` beside 16's `erlDeclAtom` in `src/codegen/crossModule.zig` · the `tests/language/` cells for `is`, a named-type union `case` and decision 8 §7's printed form (coordinate with 17) | **130** of `snapshots/codegen/{erlang,beam}/` (62 + 68, measured) | not started — **after 16 in full, after 01 closes, after 06 N19–N22** |
```

### 2. `fronts.md` — the conflict matrix

Add a `19` column and a `19` row (open fronts only).

> **Numbering.** As of `4e778bfb` the matrix's notes end at **12** and neither 18 nor 19 is
> registered. [Front 18's own paste-ready rows](../18-comptime-on-beam/README.md) claim notes
> **13–18**, so 19's start at **19** below. If 19 is registered *before* 18, shift these six down to
> 13–18 and 18's up; the superscripts in the row must match whatever the file ends up carrying.

```markdown
|  | 01 (5–6) | 06 | 07 | 08 | 09 | 12 | 13 | 14 | 16 | 17 | 18 | 19 |
| **19** | no¹⁹ | no¹⁹ | yes | no²⁰ | no⁵ | no⁶ | seq²¹ | yes | no²² | yes²³ | no²⁴ | — |
```

and, in the other rows, a `19` cell each: `01` `no¹⁹` · `06` `no¹⁹` · `07` `yes` · `08` `no²⁰` ·
`09` `no⁵` · `12` `no⁶` · `13` `seq²¹` · `14` `yes` · `16` `no²²` · `17` `yes²³` · `18` `no²⁴`.

And the notes:

```markdown
19. **19 × 01 and 19 × 06.** 19 owns the value-shape sites of `erlang.zig` and `beam_asm.zig` and
    re-records 130 cells in directories 01 owns; 06 may re-record all four codegen directories.
    19 runs after both. **01 step 6's decision-8 rows are split** (maintainer decision pending,
    [`19-runtime-type-identity/front-16.md`](./19-runtime-type-identity/front-16.md) § 5): 01 keeps
    D8-1/D8-2/D8-3/D8-5 for primitives, tuples, the wasm box and `loop`; the **named-type** half of
    each moves to 19 steps 4–5, because none of them can be written before a value knows its type.
20. **19 × 08.** 08 owns `src/codegen/tests/**`, where 19 adds fixtures; 08's wave A reads the
    snapshots 19 re-records. 19 needs the same fixture carve-out 01 has, and wave A runs after 19.
21. **19 × 13.** No library needs a source change (measured: 0 of 115 `.bp` files write a value
    shape), but every library's erlang and beam cell executes output whose value shape 19 changes.
    13 re-runs after 19.
22. **19 × 16.** 19's identity **is** 16's A2 atom, and 16 steps 7–13 own `erlang.zig` and
    `beam_asm.zig` wholesale. 16 lands first, in full; 19 additionally asks 16 for one `__v__`
    segment in the atom rule, which should be agreed while 16 is written.
23. **19 × 17.** 17 adds no source change; the shared files are
    `tests/language/expected-failures.txt` (delete-only) and the `tests/language/` cells 19 step 4
    and step 5 add.
24. **19 × 18.** They share the file `erlang.zig` in disjoint functions — 18's `ComptimeModule` /
    `emitComptimeModule`, 19's value-shape sites — and, for 18's step 3, `beam_asm.zig`'s untyped
    comptime mode against 19's value-shape sites. Their snapshot sets are **disjoint, measured**
    (0 of 18's 48 `COMPTIME ERLANG` cells is one of 19's 130). A carve-out would let them overlap;
    the front rule as written sequences them.
```

### 3. `fronts.md` — the order diagram

Replace the tail of the diagram with:

```markdown
01–10 closed ──► 12 ──► 06 ──► 01 steps 5–6 (primitives, wasm box, labels, loop)
                                    │
                                    └──► 16 module-naming (atom, then policy 3)
                                                │
                                                └──► 19 runtime-type-identity
                                                       (the tag, then the named-type half
                                                        of D8-1/D8-2/D8-3/D8-5)
```

### 4. `overview.md` — the fronts table

```markdown
| [`19-runtime-type-identity`](./19-runtime-type-identity/README.md) | high | not started — after 16 and 06 | A value carries no name for its own type: a record is an untagged map on erlang and beam, a raw heap pointer on wasm, and a unit enum variant is a bare string on commonJS — so `is`, unions, a `case` over named types and [decision 8](./08-review-backlog/decision-8-language.md) §7's per-type formatter have nothing to test. Put [16's A2 atom](./16-module-naming/declaration-qualifier.md) inside the value: one key in a record map, a qualified tag atom on a variant. Closes a live equality divergence (`Point(x:1,y:2) == Vec(x:1,y:2)` is `true` on erlang today) and gives §7's formatter a module to call instead of a table |
```

### 5. `overview.md` — one line in the decision-8 paragraph

After "the run-time half [`01-backend-residuals`](./01-backend-residuals/README.md) step 6", add:

```markdown
— and, for a **named** type, [`19-runtime-type-identity`](./19-runtime-type-identity/README.md),
which supplies the identity `is`, a union `case` and the §7 formatter all test.
```
