# Blast radius — what each checker row moves, and which library it reds

This is the point of front 07. A row that reds real code needs a migration plan, not just a fix.
The rows themselves (where, why, probe) are in [`rows.md`](./rows.md); the landing order that
follows from this file is [`groups.md`](./groups.md).

Counts were taken by reading the tree and by `zig-out/bin/botopink check` at HEAD; re-measure
after [`01-comptime-dispatch`](../01-comptime-dispatch/README.md) and before quoting any of them.

## Classes

| Class | Meaning |
|---|---|
| **none** | no fixture or library changes; only new tests |
| **few** | under ~20 snapshot files move, all mechanical regeneration |
| **many** | a whole snapshot family regenerates (≥ 100 files), review needed |
| **library** | `libs/std` or a sibling library stops compiling — needs a migration plan before the fix lands |
| **unblocks** | a library or fixture that is red *today* goes green |

## Per row

| Row | Class | Which library, and how much |
|---|---|---|
| C1 | **library** + **many** | 44 sites across std 9 · erika 1 · jhonstart 5 · emilia 29 |
| C2a | **many** | **zero** — all 32 `case`-as-value blocks in all six libraries are type-homogeneous |
| C2b | **none** | no fixture binds a `comptime` block to an annotated `val` |
| C3 | **many** + possible **library** | unquantified: string/number `+` mixing is common in `libs/std` and in erika/jhonstart string building |
| C4b | **none** | — |
| C5 | **few** + **unblocks** | — |
| C6 | **few** + **unblocks** | `libs/std` is red on it **today** |
| C7 | **few** | **zero** |
| C8 | **library** + **many** | 35 sites, **all in emilia** |
| C9 | **library** | 79 method bodies: erika 39 · std 31 · rakun 7 · onze 2 |
| C10 | **library** | 38 annotation sites: emilia 28 · std 9 · jhonstart 1 |
| C11 | **few** | **zero** |
| C12 | **few** | **zero** |
| C13 | **many** | none — error snapshots only, zero on programs |

## Library baseline — what a row can and cannot be measured against

`zig-out/bin/botopink check` at HEAD, per checked-out library:

| Library | `.bp` | Today | Owner of the red |
|---|---|---|---|
| `libs/std` | 30 files / 4823 lines | **red** — `error: pick expects a type and field names at random:141:13` | **C6** (and [`03-std-surface`](../03-std-surface/README.md)) |
| erika | 3 / 1031 | **red** — `the template module did not compile` | [`01-comptime-dispatch`](../01-comptime-dispatch/README.md) |
| rakun | 15 / 1064 | **red** — `a declared dependency was not found under the libs root` | [`12-library-repos`](../12-library-repos/README.md) |
| jhonstart | 16 / 894 | green | — |
| onze | 5 / 444 | green | — |
| emilia | 4 / 803 | green | — |

A library-class row can therefore only be *compiled* against jhonstart, onze and emilia today.
`libs/std`, erika and rakun contribute nothing to a compile count until C6 and the
comptime-dispatch front land — **so C6 first, then re-measure**. This matters most for C9, whose
largest single exposure (erika's 39 method bodies) cannot be measured at all until
[`01-comptime-dispatch`](../01-comptime-dispatch/README.md) is in.

## Library exposure, counted by construct

Counted over library `src/` only (tests and examples excluded), by reading every `.bp` file. This
is what decides each row's class; three rows turn out to cost **nothing**.

| Construct (row) | std | erika | jhonstart | onze | rakun | emilia | total |
|---|---|---|---|---|---|---|---|
| fns with `-> T` and ≥1 `return e;` (**C1** denominator) | 122 | 45 | 11 | 10 | 6 | 30 | **224 fns / 245 returns** |
| …of those, would plausibly red (**C1**) | 9 | 1 | 5 | 0 | 0 | 29 | **44** |
| `case` arms binding a payload **and using** the binding (**C8**) | 0 | 0 | 0 | 0 | 0 | 35 | **35** |
| `case` as a value / with genuinely different arm types (**C2a**) | 4 / 0 | 0 | 0 | 0 | 0 | 28 / 0 | **32 / 0** |
| record-update spread `Name(..x, f: v)` (**C11**) | 0 | 0 | 0 | 0 | 0 | 0 | **0** |
| calls to a method the receiver does not declare (**C9**) | 0 | 0 | 0 | 0 | 0 | 0 | **0** |
| record/enum method bodies currently best-effort (**C9**) | 31 | 39 | 0 | 2 | 7 | 0 | **79** |
| annotations naming an undeclared type (**C10**) | 9 | 0 | 1 | 0 | 0 | 28 | **38** |
| generic enum unit variant at a concrete instantiation (**C7**) | 0 | 0 | 0 | 0 | 0 | 0 | **0** |
| `\|>` pipelines of any shape (**C12**) | 0 | 0 | 0 | 0 | 0 | 0 | **0** |

**C7, C11 and C12's pipeline half cost zero library migration.** There is no `..` spread, no `|>`,
and no `Option`-shaped generic enum in any `.bp` file in the repository — the three generic enums
(`Result<R,E>`, `IteratorStep<T,E,C>`, `Yield<T,R>` in `libs/std/src/builtins.d.bp`) carry payloads
on every variant, and optionality is the `?T` / `null` sugar. The `dotDot` token exists at
`lexer/token.zig` l.41 and the `pipe` token at l.38, and nothing in surface code uses either.

**emilia carries 92 of the ~117 affected sites on 680 lines** (29 C1 + 35 C8 + 28 C10), all
funnelling through one design decision: `tokens.bp` declares a single `pub enum Token` with nested
sections, and `emilia.bp` annotates 27 presumed compiler-synthesized section names (`TokenText`,
`TokenPadX`, `TokenBorderColor`, …) that are declared nowhere, binds their payloads in `case` arms,
and returns the result through `return out;`. **C1, C2a, C8 and C10 must land in one wave or emilia
does not compile at any intermediate point** — the single hardest scheduling constraint in the
front.

### Two shapes that need a decision before the migration starts

| Shape | Sites | Why it is not simply "wrong code" |
|---|---|---|
| **Effect-wrapper unwrap**: a fn declared `-> @Result<D,E>` / `-> @Future<T>` / `-> @Context<B,X>` whose body returns the **bare inner value** | 9 — `libs/std/src/primitives.bp:517`, `libs/std/src/http.bp:71`, `jhonstart/src/hooks.bp:29,37,43,49,57`, `emilia/src/emilia.bp:57` | This *is* the auto-wrap contract: `infer.zig` l.5531-5547 records `wrap_ok` and l.5554-5561 `wrap_resolved` precisely because the author writes the bare value. C1's unification target inside an effect body is therefore the wrapper's **inner** channel, never the wrapper. `@Context` has no such lowering today and `jhonstart/src/hooks.bp` is five of the nine sites — extend the rule to `@Context<B, X>` → `X` or hooks dies wholesale |
| **`return <ident>` where the ident came from a `case`** | 31 — 28 in `emilia/src/emilia.bp`, plus `libs/std/src/order.bp:30` and `unicode.bp:88` | Today those idents are fresh vars (C2a), so C1 alone cannot check them and C2a alone has nothing to check them against. They are the concrete reason C1 and C2a are one landing group |

One fixture-free finding travels with C10: `libs/std` annotates `-> unit` in four `declare fn`s
(`env.bp:30`, `env.bp:35`, `process.bp:28`, `random.bp:28`). `unit` is not a primitive (`env.zig`
l.855-868 lists `void`) and is declared nowhere — it exists only because of the C10 fallback.
Rename to `void` as part of C10.

## Suite size — the regeneration cost of any row

733 `test` declarations (437 comptime + 296 codegen), 726 of them carrying inline `.bp` source.

| Artefact | Count | Moved by |
|---|---|---|
| `assertInfersOk` fixtures (no snapshot — "it compiles") | 76 | C1, C2, C8, C9, C10 — these are where a fix turns a vacuous test into a real one, or into a red |
| `assertTypeErrorSnap` fixtures (error snapshots, 2 copies each under `snapshots/comptime/{node,erlang}/errors/`) | 107 tests / 106 slugs × 2 dirs = 212 files | C3, C13 (message text and `┌─` boxes) |
| `assertComptimeAst*` typed-AST snapshots (4 byte-identical copies per slug: `node`, `erlang`, `wasm`, `beam`) | 199 slugs / 796 files | C2, C5, C6, C7, C8, C11 |
| …of which carry a `typeNameOf` `.typeVar` `?` | **17 slugs / 68 files** | the tripwire set — 10× `case_*`, 5× extension/method dispatch, 2× `@makeRecord` (measured by `10-comptime-dedup/renderer.md`) |
| `assertComptimeCompileError` documented skips | 9 | the parser gaps ([`parser-gaps.md`](./parser-gaps.md)) |
| codegen snapshots | 279 commonJS / 279 erlang / 278 beam / 278 wasm | only a fixture that **newly fails to compile** (all-or-nothing); codegen snapshots carry no type rendering |
| parser snapshots | 215 | the parser gaps |

The four copies per typed-AST slug are what
[`10-comptime-dedup`](../10-comptime-dedup/README.md) removes. If that front lands first, every
regeneration below costs a quarter as many files; if it lands after, it deletes files this front
just re-recorded. Either order works — they must not run at the same time.

## Per-row detail for the expensive rows

### C1 — **library** + **many**

The single highest-risk row. **301** of the 726 source-carrying fixtures pair a declared `-> T`
with a non-trivial `return` (380 such returns: 107 bare identifier, 77 other, 74 binop, 63
call/ctor, 25 `return case`, 21 trivially-matching literal, 4 `return if`). **15** fixtures pin a
type *only* through `return v` and assert nothing today — `infer_generics.zig` (6), `effects.zig` +
`effect_result.zig` (6), `infer_decls.zig` (2); `generic_defaults.zig` is the same shape
(`fn pair() -> Sym<i32> { return Sym(left: 1, right: 2); }`). Library code has never been checked
on this axis at all.

**Library exposure:** 224 fns / 245 `return` statements have a declared type; **44** would plausibly
red, in four shapes — 9 effect-wrapper unwraps (covered by the inner-channel rule, so 0 after it),
**31 `return <ident>` where the ident came from a `case`** (unfixable without C2a — 28 of them in
`emilia/src/emilia.bp`, plus `libs/std/src/order.bp:30` and `unicode.bp:88`), 3 returns into an
unconstrained method generic (`libs/std/src/primitives.bp:711,737,761` in
`default fn flatten/flat/fill<E>`) and 1 `return if (…) {…} else {…}` into a scalar
(`libs/std/src/path.bp:84`, whose arms are also not unified today).

#### C1 — migration

The 301 fixtures are an upper bound, not a work estimate — most unify on the first try. Pre-audit
the two risky sub-populations: the **`return case`** fixtures and the **107 bare-identifier
returns** (where a fresh var from elsewhere is doing the work). Land C1 behind a walk that
*reports* instead of failing, triage, then flip to hard errors. C1 and C2a must be in the same
wave (31 of the 44 library sites need both); C8 must be a separate commit within it, or the triage
becomes unreadable.

### C2a — **many**, and zero library breakage

All 32 `case`-as-value blocks in the libraries are type-homogeneous, so arm unification only newly
type-checks them (8 emilia blocks mix a string literal, a call and a concat, but all three are
`string`). In the suite, 45 fixtures use `case` as a value (24 of them `return case`, against the 25 counted
in the C1 row above — recount when the pre-audit runs), **none** binds it to an *annotated* `val`,
and 10 of the 17 tripwire slugs are `case_*` — including two whose names already promise
the union policy (`case_arms_with_different_types_string_i32_union`,
`case_union_return_type_from_mismatched_arms`); read those two before deciding the policy.

C2b is **none**: no fixture at HEAD binds a `comptime` block to an annotated `val`, which is
exactly why the defect survived.

### C3 — **many** on the error snapshots, possible **library**

Any fixture under `snapshots/comptime/*/errors/` (212 files) whose message names a boolean or
arithmetic mismatch flips its expected/found. The library risk comes from the arithmetic
constraints, not from the orientation fix. Regenerate together with C13 — both rewrite the same
family.

### C8 — **library** + **many**, but concentrated

**emilia is the only library that binds a payload and uses it** — 35 sites of 44 binding arms in
`emilia/src/emilia.bp` (20 pass-to-fn, 12 pass-to-fn *and* string-concat, 3 pure concat), all on
the nested-section `Token` enum. **No OR alternation, no `x if (…)` guard and no `[first, ..rest]`
pattern exists in any library** — those three sub-cases are fixture-only work. In the suite, **36**
fixtures bind and use a pattern name (20 guards, 16 ctor payloads, 5 OR, 3 list), concentrated in
`comptime/tests/narrowing.zig` (9), `variants.zig` (7), `codegen/tests/control_flow.zig` (6),
`codegen/tests/narrowing.zig` (4). Second-highest-risk row after C1, and what makes half of
[`narrowing.md`](./narrowing.md) assertable.

**Migration:** same shape as C1 — a reporting pass over the libraries first. Land after C1 (a
payload binding is often fed to a `return`, so C1 alone already surfaces some of these) but in its
own commit.

### C9 — **library**, and the least predictable row

The best-effort walk exists *because* real bodies trip gaps. **Unknown-method calls: 0** — every
`.m(` in every library resolves to a declared fn, a primitive-interface method, a builtin (`?T` /
`@Result` dispatch: 73 `unwrapOr`, 8 `isOk`/`isError`, 5 `unwrap`/`then`) or a fn-typed record
field (`jhonstart/src/hooks.bp:70` `c.set(9)`), so the l.7105-7114 half is free. **Method bodies
currently swallowed: 79** — erika 39, std 31, rakun 7, onze 2, jhonstart 0, emilia 0. erika's 39
are the largest single exposure in the front and have *never* been type-checked
(`erika/src/erika.bp:24` `pub fn toArray(self: Self) -> Array<T>`, `:105`
`return Query(items: sorted);` inside `orderBy<K>` — every `Query<T>` method chains generic
`Array<T>` methods). Interface `default fn` bodies (std 48, erika 1) are already strict via
`inferInterfaceDefaultBodies` and are not part of this delta.

erika is red today for a reason this front does not own, so **its 39 bodies cannot be measured
until [`01-comptime-dispatch`](../01-comptime-dispatch/README.md) lands**. In the *suite* the
exposure is small — 5 of the 17 tripwire slugs are extension/method dispatch, and a wider grep for
undeclared receiver methods returns 73 fixtures that are almost all false positives (stdlib
array/string methods resolved elsewhere, the 12 `@Expr` template methods, and negative tests that
already assert a red). **Instrument first**: make `inferTypeMethods` count and print the swallowed
errors over `libs/std` + the five siblings, and read the list before deciding whether C9 is one row
or three.

### C10 — **library**

emilia's 28 are the real work and they are the same 28 that C8 touches — the nested-section enum
has to grow real declared section types (or emilia has to stop annotating them) before C10 can
land. Host/FFI type names in `#[@external]` declarations also become hard errors. In the suite the
exposure is **~7** fixtures — the ones annotating with a *variant* name or an undeclared name
(`Circle`, `Square`, `Some`, `None`, `Wibble`, `Wobble`, `Container`, plus
`Order`/`TypeInfoKind`/`RecordField`); 9 more that a naive grep flags (`Array`, `Span`, `Binding`,
`Children`, `TypeInfo`, `Option`, `Result`) are registered builtins and resolve legitimately. **The
two-pass registration must land before the fallback is removed**, and the removal is the last
commit of the row.

### C13 — **many** on error snapshots, zero on programs

Adding a `┌─` box to a snapshot that had none is a pure diff; it is the *only* way a future
regression in those errors becomes visible.

## Cheap rows, for contrast

- **C5** — `narrow_type_guard_basic_codegen` and `narrow_type_guard_if_codegen` exist in all four
  backend snapshot dirs; the JS lowering already emits a plain `return true`, so the emitted text
  should not move — only the typed-AST snapshots. Check that no backend keys on the guard fn's
  return type being `T`.
- **C6** — `comptime/tests/builtins_typeinfo.zig` (31 tests) is the only fixture family that pins
  these: 27 `assertComptimeAstSingle` and 4 `assertTypeErrorSnap` (`comptimeError: string literal
  raises custom error`, `mergeRecords: conflict raises error`, `omit: non-existent field raises
  error`, `pick: field email not found raises type error`). The file's header says it verifies
  resolution "during inference" and defers full comptime evaluation — exactly the layer
  [`types-as-values.md`](./types-as-values.md) replaces. 3 of its slugs already render a
  `typeNameOf` `?`. 30 fixtures across the suite use any of these builtins or names. **The
  shadowing fix makes `libs/std` compile.**
- **C7** — **2** fixtures (`infer: generic enum Option<T> ---- unit and payload variants`, where
  `val n = Option.None;` pins no `T` at all, and `variant inference: pattern matching on generic
  enum`, where a bare `None` is returned into `-> Option<i32>`); 6 fixtures declare a generic enum
  at all. Neither shows a `?` today, so this row is **invisible in the tripwire set** — regenerate
  the two slugs deliberately. No codegen change: variant lowering is name-keyed, not type-keyed.
- **C11** — **5** fixtures in total, all in `comptime/tests/variants.zig`, 3 of them already error
  tests. The current behaviour is wrong enough that no working code can depend on it — the cheapest
  correctness row in the front.
- **C12** — both pipeline fixes are free of library migration; the `val assert` half needs C8's
  pattern-vs-type machinery.
