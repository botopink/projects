> Carried from `specs/1.0.5-beta/13-module-identity/halves-and-ordering.md`, status at carry (2026-09-20): half 1 landed (`154f3bc9`); halves 2–3 (steps 8–19) are C-01, decision 64 is C-03 (uncommitted in `.tasks/identity`), step 6's residuals are C-25. The README still reads T1 and an unticked step 0 — decisions 6, 21, 22, 23 and 62 override it

# The three halves, what each gives the next, and the circular dependency the milestone still owes

This front was two in 1.0.4-beta: **16 module-naming** (the atom, then policy 3) and **19 runtime
type identity** (the atom inside the value). The maintainer merged them for 1.0.5-beta. This
document is the ordering argument that merge rests on, kept as it was written and re-anchored: what
**half 1** (the atom, steps 0–6) gives **half 3** (the identity, steps 14–20), what **half 2**
(policy 3, steps 7–13) gives it for free, what half 3 still has to add on its own, why the three
land in that order and never in one commit, and the one decision the maintainer still owes.

Read "16" below as **half 1**, "policy 3" as **half 2**, and "19" as **half 3**.

## 1. What half 1 gives half 3, before policy 3

| From step 1 (half 1) | What half 3 does with it |
|---|---|
| `erlDeclAtom(alloc, id, kind, decl, ?hash)` with a `Kind` enum | **is** the tag. Half 3 calls it; it does not define an atom rule of its own |
| `erlAtom`'s clause 3b (runs of `_` collapsed, so `__` is reserved) | makes `__t__` / `__v__` parseable, and therefore the tag reversible |
| `RESERVED` (the OTP module names) and the 250-byte check | apply unchanged to a type atom — `bp@math__t__vector` cannot collide with OTP |
| **the collision check over rendered atoms** in `crossModule.build` (`crossModule.zig:86`) | extended by step 14 to the type and variant atoms: two declarations that render the same atom is a located diagnostic, not a silent winner. This is the check that makes the identity trustworthy |
| A2 § 5's decoder | extended by step 14 with one clause for `__v__` ([E15](./identity-evidence.md#e15--the-qualified-variant-tag)) |

Without half 1, half 3 would have to invent the same atom rule a second time. Two spellings of one
atom is precisely the failure half 1 exists to remove, so **half 3 never defines an atom**; it
defines a **placement**. In 1.0.4-beta this was a cross-front dependency and the `__v__` segment had
to be *agreed* between two fronts; in one front it is step 14's business.

## 2. What policy 3 (half 2) gives half 3 for free

Policy 3 emits `<pathAtom>__t__<decl>` as a real module holding the type's constructor and methods
([E22](./atom-evidence.md#e22--four-sibling-s-modules-from-one-source-file)). When
half 3's tag is that same atom:

| Free | Because |
|---|---|
| **The §7 formatter is a `call_ext`, not a table.** `'__bp_show'(#{'__bp_type' := T} = M, _) -> T:format(M);` | the tag *is* the module that holds `format/1`. Without policy 3 the backend must emit, per program, a dispatch table from atom to formatter and keep it in sync with the emitted types |
| **A `behavior`'s `Display` implementation is reachable the same way** — decision 8 §7's "a type implementing `Display` prints its `display()`, also when nested" | policy 3 emits `__im__<decl>`; the formatter can try the implement module and fall back to the derived one |
| **A crash inside a formatter names the type** | policy 3's own gain ([E24](./atom-evidence.md#e24--a-stack-trace-names-the-owning-type)): `{models@user__t__pessoa, format, 1, [{file,…},{line,3}]}` |
| **The identity is verifiable at run time** — `code:which(T)` on a tag answers a real `.beam` | nothing else in the scheme can be checked that cheaply |
| **`is` can become a `call_ext` if it ever needs to** (a generic `T:matches(V)`) | not needed for §4.2, but the door is open at zero cost |

## 3. What half 3 still has to add — all of it

Policy 3 changes **where functions are emitted**. It changes nothing about what a value looks like.
After policy 3 lands, `Person(name: "Ana", age: 30)` is still the bare map `#{name => …, age => …}`
and `Shape.Dot` is still the bare atom `'Dot'`. Every row below is half 3's, and none of it exists in
steps 1–13.

| Half 3 adds (steps 14–18) | Sites at `26d4fdc`; at `c2dd780` they have drifted by roughly +115 |
|---|---|
| the `'__bp_type'` key in a record term | `erlang.zig:4702-4708`; `beam_asm.zig:4516-4536` |
| the type qualifier on a variant tag | `erlang.zig:5073-5076` + its four call sites (`:4194-4199`, `:4776-4782`, `:5030`, `:5038-5048`); `beam_asm.zig:1684-1689` + `:6212-6225`, `:3300-3315`, `:5272-5286`, `:5333` |
| the owner's atom for an **imported** type at the consumer's inline construct | `erlang.zig:2840-2841` reading `ExportInfo.module` (`crossModule.zig:30-50`) — no new index key (verified) |
| `'__bp_type'` hidden from user-visible output | `show_helper_form`, `erlang.zig:554` |
| the `x is T` lowering for a named type | new, after [`../01-checker/`](../01-checker/README.md) N21 |
| the `case` arm over a named type or a union of them | new, after 01's N20/N22 |
| §7's per-type formatter dispatching on the tag | new; this is 02/03's **D8-5** row, transferred — the pending decision of § 5 |
| the same identity, or an agreeing one, on commonJS's unit variants and in wasm's box | § 7 of [`options.md`](./identity-options.md) |

**Measured overlap of the two halves' snapshot sets** — the 188 files policy 3 re-records are those
carrying a `%% type` / `%% behavior` / `%% implement` marker; half 3's 130 are those that also *build*
a record or a variant. They are largely the same files (62 of the 130 are erlang, and 81 erlang files
carried the marker at `26d4fdc`; **98 at `c2dd780`**), which is the whole reason the two halves
cannot land in one commit: a diff in one of those
files would carry a module split **and** a value reshaping at once, and
[the rule 1.0.4-beta ran under](../../../1.0.4-beta/overview.md), carried into 1.0.5-beta,
requires each re-recorded snapshot to be
classified.

## 4. Which half lands first — the atom, and it is not close

| Reason | Detail |
|---|---|
| **1. The helper is half 1's** | Step 14 is a consumer of `erlDeclAtom`. Writing it twice creates two spellings of one atom |
| **2. The files** | Steps 7–13 own `erlang.zig` and `beam_asm.zig` **wholesale** ([§ 9](./policy-3-module-per-type.md#9-sequencing--decided-2026-09-17-one-front-not-two)). Half 3 edits eight functions in each. The two cannot be in flight at once |
| **3. The snapshots** | 188 (half 2) and 130 (half 3) overlap heavily. Sequencing keeps one reason per diff; overlapping them makes classification impossible |
| **4. The formatter** | writing step 18 before policy 3 means emitting a per-program dispatch table and then deleting it when policy 3 makes the tag a module |
| **5. `botopink run`** | policy 3's opening step fixes `cli/run.zig` to `erl -pa` ([E25](./atom-evidence.md#e25--botopink-run-breaks-under-policy-3)). Half 3's `tests/language/` acceptance cells run programs through the CLI; they need that fix to exist |

**There is one argument the other way, and it does not hold.** Steps 14–16 (the tag in the value)
touch no atom-*rendering* site and could in principle land first with a private helper. But then
half 1's atom rename would move the tag too, re-recording all 130 snapshots a second time for a
reason that is half 1's. Ordering 1 → 2 → 3 costs nothing; any other order costs one full re-record.

## 5. The circular dependency — and why the maintainer's order dissolves it

### 5.1 The cycle, as 1.0.4-beta left it

1.0.4-beta's order was a cycle:

```
06 checker ──► 01 step 6 (decision 8 at run time) ──► ... 01 closes ──► 16 ──► 19
                   ▲                                                         │
                   └──── needs the identity 19 supplies ──────────────────────┘
```

01 step 6's rows **D8-1** (`is`), **D8-3** (`case` arms) and **D8-5** (the formatter) cannot be
written for a *named* type before the identity exists, and 16 could not start until 01 had closed.
In 1.0.5-beta the same cycle survives the renumbering: decision 8's run-time half now lives in the
four backend fronts [`../02-erlang/`](../02-erlang/README.md),
[`../03-beam/`](../03-beam/README.md), [`../04-js/`](../04-js/README.md) and
[`../05-wasm/`](../05-wasm/README.md), and this front's halves 2–3 own `erlang.zig` and
`beam_asm.zig` wholesale.

### 5.2 The maintainer's order breaks it — **14 → 13 → the backends**

**Decided:** [`../14-comptime-on-beam/`](../14-comptime-on-beam/README.md) runs first, this front
runs immediately after it, and the four backend fronts follow.

Under that order the cycle simply does not arise. The identity **already exists** when 02, 03, 04
and 05 open, so each of them writes its decision-8 rows — `is`, unions, a `case` over named types,
the per-type formatter — against a value that already knows its own type. Nothing has to be split
and nothing has to wait for something that waits for it.

**This is the explicit confirmation the maintainer asked for: under this order the cut below is no
longer necessary, and it is no longer a decision the maintainer owes.** It is recorded here as the
fallback, because it becomes necessary again the moment 02 or 03 is allowed to open before this
front's halves 2–3 have landed.

**The fallback cut, if the order is ever reversed:** the backend fronts keep every decision-8 row
that needs no stored identity, and this front's half 3 takes the named-type half.

| Row | Stays with the backend fronts | Moves to half 3 |
|---|---|---|
| D8-1 `x is T` | `i32`/`i64`/`f64`/`string`/`bool` by range and kind; `#(i32, string)` by arity; wasm reads decision 3's box tag | `x is Point`, `x is Option.Some(v)`, `x is Box<unknown>` on erlang and beam |
| D8-2 `unknown` / unions | the wasm box, §2.3 numeric equality | a union whose members are **named types** on erlang/beam |
| D8-3 `case` arms | literal, range, tuple, `_`, guards, `..` | an arm that is a named type or a section (§5.3b) |
| D8-4 `row.label` → index | all of it | — |
| D8-5 the formatter | the primitive, array and tuple text; `f64` always `5.0` | the `record` and `variant` rows of §7's table, and `Display` |
| D8-6 `loop (condition)` | all of it (already delivered by 1.0.4-beta's 06 G0) | — |

### 5.3 What the order costs, stated plainly

**`02-erlang` and `03-beam` stall while halves 2 and 3 run.** This front owns `src/codegen/erlang.zig`
and `src/codegen/beam_asm.zig` **wholesale** for steps 7–20 — 318 re-recorded cells in
`snapshots/codegen/{erlang,beam}/` — so the two backend fronts cannot be open at the same time.
That is the price, and it buys three things:

1. **Each snapshot is written once.** With the backends first, this front would re-record 188 + 130
   cells on top of what they had just recorded. In this order every cell moves once.
2. **`buildModule` is not contested.** 14's step 2 makes the comptime module per *declaration*
   instead of per call site, which is exactly the key this front's step 5
   (`erlDeclAtom(owner_path, .tpl, decl_name, hash)`) wants. This front inherits the work rather than
   competing for the same function
   (`template_eval.zig:329-343`, `decorator_eval.zig:227-243`).
3. **No cut to negotiate.** § 5.2.

**`04-js` and `05-wasm` are not affected and run in parallel throughout.** This front does not write
`commonJS.zig`, `typescript.zig` or `wat.zig` — the one exception is the optional step 19, which it
takes only if the maintainer assigns it here rather than to 04.

The resulting order:

```
14 comptime-on-beam (steps 0–2)
      │
      └──► 13 module-identity   half 1: the atom        (≈ 20 snapshots, names)
                                half 2: policy 3        (188, shapes)      ── 02 and 03 stall here
                                half 3: the identity    (130, value lines)
                                     │
                                     └──► 02 erlang · 03 beam — decision 8's run-time rows,
                                          named types included, against a value that knows its type

            04 js · 05 wasm — in parallel throughout
            01 checker — N19–N22 (the checker half) before steps 17–19
```

## 6. Why one front rather than two

1.0.4-beta shipped this analysis as two fronts, 16 and 19, and recommended keeping them apart. The
maintainer merged them for 1.0.5-beta, and the arguments the split rested on are exactly the
arguments for the merge once the ordering rule is written down inside one front:

- **The same files.** Steps 7–13 own `erlang.zig` and `beam_asm.zig` wholesale; half 3 edits eight
  functions in each. Two fronts could never be open at once, so the front boundary bought no
  parallelism.
- **The same snapshots.** 188 and 130 overlap heavily — 62 of half 3's 130 erlang cells are files
  half 2 has already re-recorded once. Sequencing them across a front boundary and sequencing them
  across a commit boundary are the same discipline; only the second one is enforceable by the
  classification rule.
- **The same atom.** Half 3 never defines an atom; it places the one step 1 renders. Written as two
  fronts, the `__v__` segment had to be *agreed* between them while the first was being written —
  a negotiation that is now step 14's internal business.
- **Policy 3 pays for half of half 3.** The formatter is `T:format(M)`, one `call_ext`, only because
  the tag is a module policy 3 emitted.

What the split was protecting is kept: **three halves, three commit sets, one reason per diff.**
The estimate is ≈ 9 days for halves 1–2 and ≈ 7 for half 3, and the halves land in order.
