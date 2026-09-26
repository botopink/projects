# Options for the identity, and for its spelling

Two questions.

1. **What is the identity?** (a) the A2 atom, (b) some other per-type tag, (c) something the value
   carries that the atom can be recovered *from*, (d) nothing — structural typing at the call site.
2. **Where does it sit in the term?** T1 tagged map / T2 tagged tuple for a record; and — the
   question [`README.md`](./README.md) § 2.1 did not ask — **prefix the term** or **qualify the tag
   atom** for a variant. § 4 shows the second answer is free and the first is not.

Every mechanical claim below was run at OTP 29 / erts 17.0.6; the transcripts are in
[`evidence.md`](./identity-evidence.md).

---

## 1. The four identities, compared

| | (a) the A2 atom | (b) another per-type tag | (c) recovered from a carried function | (d) no stored identity |
|---|---|---|---|---|
| Shape in the value | `'__bp_type' => 'models@user__t__pessoa'` | `'__bp_type' => 7` (an id) or `'Pessoa'` (a short atom) | `'__bp_type' => fun m:ty/0` | — |
| Size, `Person(name, age)` | **13 words** (11 today) | **13 words** — identical: an atom and a small integer are both immediates ([E16](./identity-evidence.md#e16--the-size-of-every-candidate)) | **15 words** (+36 %) | 11 words |
| Size, an enum variant | **free** — an atom is 0 words, the tuple keeps its arity (§ 4) | free | not applicable | free |
| Readable in a **guard / pattern** — decision 8 §3.3, §5.4 | **yes** (E13, E15) | yes | **no — `illegal guard expression`** ([E17](./identity-evidence.md#e17--a-carried-function-cannot-be-read-in-a-guard)) | partly: only shapes, never names |
| Answers `is Person` vs `is Vec` | yes | yes | yes, after a call | **no** — 6 field-sets are already shared by 18 differently-named types ([E14](./identity-evidence.md#e14--how-often-the-names-already-collide)) |
| Answers `is Shape.Circle` across two enums | yes | yes if the tag is qualified; a bare `'Circle'` is today's bug | yes, after a call | **no** — `Circle` is declared in 5 files, `Some`/`None` in 4 (E14) |
| Survives cross-module | **yes** — the tag is in the value; the owner's path is already in `ExportInfo.module` (`crossModule.zig:30-50`), so no new index key (§ 6) | yes, but the id must be assigned by a whole-program pass the compiler does not have — `codegenEmit` runs per module | yes (an external fun survives `term_to_binary`; an anonymous one carries the defining module's MD5 and breaks across a reload) | n/a |
| Works on erlang / beam / commonJS / typescript / wasm | 4 of 5 directly; wasm stores an index into a per-module table of the atoms (§ 7) | same | erlang/beam and commonJS only; wasm has no funs in the value model | n/a |
| Names the §7 formatter | **yes, for free under [policy 3](./policy-3-module-per-type.md)** — the atom *is* the module holding `format/1` | no — needs a lookup table the backend must emit and keep in sync | yes — but the call is the dispatch, so the tag and the formatter are welded together and `is` cannot reuse it in a guard | no |
| Debuggability of a raw term in a crash | `#{'__bp_type' => models@user__t__pessoa, …}` — decodes back to `{decl,"models/user","t","pessoa"}` (A2 § 5) | `#{'__bp_type' => 7, …}` — needs the build's table | a `#Fun<…>` in every printed record | unchanged |
| Snapshots it moves | 130 (§ [`blast-radius.md`](./identity-blast-radius.md)) | 130, same lines | 130, and every `~p` of a record prints a fun | 0 |

**(d) is not an option, it is the status quo, and it is measurably insufficient.** Not
hypothetically: in the 115 `.bp` files of the seven repositories, `(repo)` is the field list of
five different services, `(items)` of `Query`/`Queue`/`Set`, `(name, pop)` of `City`/`ErikaCity`
(E14). Decision 8 §4.2 asks for "the constructor of a named type"; structure cannot answer it.

**(c) is ruled out by one measurement.** A fun cannot be called in a guard —

```
guardtest.erl:3:12: illegal guard expression
f(M) when (maps:get('__bp_id', M))() =:= 'p' -> yes;
```

— so a `case` over `Person | Car` needs a dispatch *before* the `case`, which reintroduces exactly
the catch-all arm decision 8 §5.4 forbids. It also costs the most space (15 words) and puts a
`#Fun<…>` in every printed record.

**(b) is (a) with the traceability removed.** It costs the same words and the same snapshots, it
needs a whole-program id assignment the per-module `codegenEmit` cannot do, and it gives the §7
formatter a table where (a) gives it a module. Its one honest advantage — a short tag is cheaper to
compare — does not exist: comparing atoms is pointer equality regardless of length, measured
identical to comparing a small integer (E16, E18).

**Recommendation: (a), the A2 atom.** It is the only one of the four that answers all four
decision-8 features, and it is the only one whose cost is a suffix on work
[half 1](./README.md#half-1--the-atom) is already doing.

## 2. The atom

```
typeAtom(path, decl)             = erlAtom(path) ++ "__t__" ++ lower(decl)
variantAtom(path, decl, variant) = typeAtom(path, decl) ++ "__v__" ++ lower(variant)
```

The first line is [A2](./declaration-qualifier.md)'s string, reused verbatim —
`erlDeclAtom(alloc, id, .t, decl, null)` from step 1. The second is **new** and is what this
front asks 16 for: one more `kind`-like segment, `__v__`, so a variant tag is decodable the same
way. Both are legal **unquoted** atoms and both decode with one extra clause on A2 § 5's decoder
([E15](./identity-evidence.md#e15--the-qualified-variant-tag)):

```
models@user__t__pessoa                {decl,    "models/user", "t", "pessoa"}
models@user__t__shape__v__circle      {variant, "models/user", "t", "shape", "circle"}
models@user__t__shape__v__dot         {variant, "models/user", "t", "shape", "dot"}
```

Longest real example: 31 characters, against the 250-byte filename cap
([E7](./atom-evidence.md#e7--the-real-length-cap-is-the-filename-not-the-atom)).

**If 16 refuses `__v__`**, the fallback is `erlDeclAtom(id, .t, "<type>_<variant>")` with the
existing three-segment shape; it loses the clean decode and reintroduces the `_`-collision A2 § 4
takes care to avoid. Ask first.

## 3. Where the tag sits in a **record** — T1 or T2

| | T1 — tagged map | T2 — tagged tuple | T3 — `-record` |
|---|---|---|---|
| The value | `#{'__bp_type' => 'app@models__t__person', name => …}` | `{'app@models__t__person', …}` | `#person{…}` |
| `p.x` | `maps:get(x, P)` — **unchanged** | `element(2, P)` — every access site rewritten | record accessor |
| an existing `#{x := X}` pattern | **still matches** ([E1](./identity-evidence.md#e1)) | breaks | breaks |
| `is` test | `maps:get('__bp_type', M, undefined) =:= T` ([E3](./identity-evidence.md#e3)) | `element(1, V) =:= T` | `is_record/2` |
| cross-module | works | works | **needs an `.hrl` the compiler emits nowhere** ([16 erlang-atoms § 2.3](./erlang-atoms.md)) |
| size | 13 words (11 today) | **7 words** | 7 words |
| construct, tight loop | 1.383 ns (1.218 today) | 1.383 ns | not measured |
| the `is` test through an opaque call | 18.41 ns — **indistinguishable from today's 18.89 and from T2's 18.43** (E18) | 18.43 ns | not measured |
| emitter change | one key added at 2 sites per backend | construct, access, destructure, pattern, `__bp_show` — 8 sites per backend | the above, plus a header-distribution problem |
| snapshot lines that move | the construct line only | construct **and** every access and pattern line | same |

**T1 for step 15, T2 kept open.** E1 is still the decisive measurement: a map pattern in erlang is a
subset match, so the tag lands without touching access, destructuring or `case`. T3 stays ruled out
on distribution grounds, not speed.

> **Correction to [`evidence.md` E10](./identity-evidence.md#e10--build-and-match-2-000-000-iterations).** E10
> reported "T1 costs nothing measurable, T2 is 2.5× faster". Neither half survives re-measurement.
> `erlc +to_asm` shows that when the value's shape is statically known the erlang compiler **deletes
> the test entirely** — the `.S` for the hoisted-tuple loop contains no test at all
> ([E18](./identity-evidence.md#e18--the-honest-timing)). Through an opaque call the three `is` lowerings are
> within 0.5 ns of one another. What is real and reproducible: T1 costs **+2 words per record value**
> and **+0.165 ns per construct**; T2 saves 4 words against today. Time is not the reason to prefer
> either. The 2.5× figure must not be used to justify step 18.

## 4. Where the tag sits in a **variant** — prefix the term, or qualify the tag

[`README.md`](./README.md) § 2.1 proposed prefixing: `{'…__t__shape', 'Circle', 5}` and boxing a unit
variant as `{'…__t__shape', 'Dot'}`. Applied to the compiler's own emitted erlang and executed
([E13](./identity-evidence.md#e13--both-spellings-applied-to-the-compilers-own-output)), that works — and it
changes the **kind** of a unit variant from an atom to a tuple and the **arity** of a payload
variant from `n+1` to `n+2`. Both are load-bearing:

| Site | Under "prefix the term" | Under "qualify the tag" |
|---|---|---|
| `beam_asm.zig:5333` `is_tagged_tuple` arity argument | `fields.len + 2` | **unchanged** |
| `beam_asm.zig:5272-5286` unit variant test | `is_eq` on an atom becomes `is_tagged_tuple` | **unchanged** — still `is_eq`, on a different atom |
| `erlang.zig:5030` `.ident` unit pattern | an atom pattern becomes a tuple pattern | **unchanged** |
| `erlang.zig:5038-5048` `.variant` pattern | one more element | **unchanged** |
| `erlang.zig:4194-4199` unit construct | `A(member)` becomes a 2-tuple | `A(qualified)` |
| `erlang.zig:4776-4782` payload construct | one more element | `items[0] = A(qualified)` |
| size of a unit variant | 3 words (was 0 — an atom is an immediate) | **0 words** |
| size of `{'Circle', 5}` | 4 words | **3 words — unchanged** |
| `is Shape` as a **guard** | arity + `element(1,…)` | an `orelse` chain over the enum's variants, which the checker knows statically — all guard-legal (E15) |

**Qualify the tag.** It is free in space, free in shape, changes no opcode and no arity, and is a
one-line substitution at each of the four sites — `variantTag()` (`erlang.zig:5073-5076`,
`beam_asm.zig:1684-1689`) becomes the only place that has to learn the owning type. Measured: the
qualified atom is unquoted, discriminates two enums that share a variant name, and every test stays
inside a guard (E15).

This also **corrects [`README.md`](./README.md) step 16**, which says "`is_tagged_tuple`'s arity
argument grows by one". Under the recommended spelling it does not grow at all.

### The exclusions

| Term | Stays as it is | Why |
|---|---|---|
| `{ok, V}` / `{error, E}` | untouched | built by the `@Result` lowering, not by a user `type`; `variantTag` already special-cases them (`erlang.zig:5074`, `beam_asm.zig:1685-1688`) |
| an anonymous record / tuple `#(1, "a")` → `{1, <<"a">>}` | untagged | decision 8 §6: a tuple is positional and compares without labels; `is #(i32, string)` stays an arity-plus-element test |
| an enum **section**'s synthesised name (`__Token__Color`) | gets a `typeAtom` like any other | decision 8 §5.3b makes a section a type of its own; `enum_sections_path_access_lowers_to_qualified_ctor_calls.snap.md` already emits `{'Color', {'Red', '__500'}}` with a compiler-invented name — a precedent for ad-hoc mangling this front replaces |

## 5. What each decision-8 item becomes

```erlang
%% x is Person
is_map(X) andalso maps:get('__bp_type', X, undefined) =:= 'app@models__t__person'

%% x is Shape          — the checker knows the variant list; all guard-legal
is_atom(X) andalso X =:= 'app@models__t__shape__v__dot'
  orelse (is_tuple(X) andalso tuple_size(X) > 0
          andalso element(1, X) =:= 'app@models__t__shape__v__circle')

%% case v { Person { p -> … } Car { c -> … } }   — exhaustive, no `_` (E4)
case V of
    #{'__bp_type' := 'app@models__t__person'} = P -> …;
    #{'__bp_type' := 'app@models__t__car'}    = C -> …
end

%% @print(p)  →  §7's `Person(name: "Ana", age: 30)`
'__bp_show'(#{'__bp_type' := T} = M, _) -> T:format(M);     %% under policy 3: one call_ext, no table
'__bp_show'(V, _) when is_atom(V) -> …                      %% a unit variant: decode the atom
```

## 6. Cross-module — verified, and free

`CrossModule.ExportInfo.module` is the **owner's module path** (`crossModule.zig:30-50`), already
carried for every `pub type` (`crossModule.zig:103-117`). A consumer that inlines an imported
record's map (`erlang.zig:2840-2841`) can therefore compute `erlDeclAtom(info.module, .t, name)`
with no new key and no new pass — the same conclusion
[policy 3 § 3](./policy-3-module-per-type.md#3-the-cross-module-index) reached for
methods. For a **local** type the emitter already holds the full path in `Emitter.module_name`
(`erlang.zig:1586`, `beam_asm.zig:1298`), which is the path, not the truncated atom.

The one pre-existing hole this front does not close: `exports` is keyed by the **bare symbol name**
(`crossModule.zig:112-135`), so two libraries exporting `pub type User` still collide in the index —
recorded by [step 6](./README.md#step-6--the-residuals-this-front-will-not-take)
and unchanged here. The *tag* would be correct for each; the *index* would pick one owner. Same
front, same residual.

## 7. The other three backends

| Backend | What option (a) means there | Owner |
|---|---|---|
| commonJS | records and payload variants already carry it. The hole is the **unit variant as a bare string** (§ 4 of [`representation.md`](./representation.md)). Minimal fix: emit `Object.freeze({ tag: "Dot" })` for a unit variant, and make `case`/`is` test `.tag` uniformly instead of `===` on the string; 13 snapshots. Alternative that costs 0 snapshots: keep the string and make `is string` refuse an enum value in the checker — which contradicts decision 8 §4.1's "`is` tests the value, not the origin" | this front (step 19) **or** [`../04-js/`](../04-js/README.md) — the maintainer decides; this front does not take it unilaterally, because `commonJS.zig` is 04's |
| typescript | `.d.ts` must describe whatever commonJS emits. Zero run-time cost | follows commonJS in the same commit |
| wasm | no atom table exists. The identity is an **index into a per-module type table** emitted as a `data` segment of A2 atoms, so `is` reads the index and the formatter reads the table. This is exactly decision 3's box generalised, which is [`../05-wasm/`](../05-wasm/README.md)'s D8-1/D8-2 | **05-wasm.** This front supplies the table's contents (the atom list) and the requirement that the index and the atom agree; it does not write `wat.zig` |

The invariant this front is responsible for, on every backend: **two values carry the same identity
if and only if they were built by the same declaration.** How each backend spells it is the
backend's business; that it agrees across backends is a gate condition (§ Gate of
[`README.md`](./README.md)).
