# Landing groups — what lands together, and in which order

The checker rows (C1…C13, C4b) are cut into five landing groups. A group is one landing unit: its
rows share a library migration or a snapshot regeneration, so splitting it either leaves a library
red in between or regenerates the same snapshot family twice. The rows themselves (where, why,
probe) are in [`rows.md`](./rows.md); the per-row cost that drives this order is in
[`blast-radius.md`](./blast-radius.md).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless stated
otherwise. Line numbers are at `botopink-lang` HEAD; re-locate by the quoted symbol.

## The groups

| Group | Rows | Library cost | Why together |
|---|---|---|---|
| **G0 — free wins, land first** | C6, C4b, C11, C7, C12 pipeline | **zero** for all five (no `..`, no `\|>`, no generic unit variant anywhere; C6 *unblocks* `libs/std`) | File-disjoint from each other and from everything below. C6 must be first of all — `libs/std` is red on it today, and every measurement below needs std to compile |
| **G1 — the emilia wave** | C2(a), C1, C8, C10 | **92 sites in emilia**, 9 in std, 5 in jhonstart (C1's split; C10 adds std 9 and jhonstart 1, C1 adds erika 1) | emilia does not compile at any intermediate point: its nested-section `Token` enum supplies C10's 28 undeclared annotations, C8's 35 payload bindings and C1's 28 `return out;` at once, and 31 of C1's 44 library sites need C2a to have a type to check. Sequence *inside* the wave: C2a → C1 → C8 → C10, one commit each, emilia migrated alongside |
| **G2 — narrowing prerequisites** | C5, then C12 `val assert` | zero | C5 makes a guard call usable in an `if` (it is typed `T` today, so the type-guard narrowing is dead code); `val assert` needs C8's pattern-vs-type check. With G1 they unblock [`narrowing.md`](./narrowing.md) step B6 |
| **G3 — strictness** | C9 | **79 method bodies** — erika 39, std 31, rakun 7, onze 2 | Needs the measurement in its row, which needs std and erika compiling (G0's C6, and [`01-comptime-dispatch`](../01-comptime-dispatch/README.md) for erika) and needs G1 landed — many swallowed errors are `return`- and `case`-shaped |
| **G4 — diagnostics, land last** | C3, C13 | possible, from C3's arithmetic constraints | One regeneration of the 212 error-snapshot files instead of two — and G1/G3 add new error snapshots that would otherwise be written in the old format |

```
G0  C6 ─► C4b · C11 · C7 · C12-pipeline          (C6 first; the other four in any order)
 │
 ▼
G1  C2a ─► C1 ─► C8 ─► C10                        (one wave, one commit per row, emilia alongside)
 │
 ▼
G2  C5 ─► C12 val assert                          (needs C8 from G1)
 │
 ▼
G3  C9                                            (needs G1 + std compiling + erika compiling)
 │
 ▼
G4  C3 · C13                                      (one regeneration of snapshots/comptime/*/errors/)
```

C2b (the `comptime { break … }` block type) belongs to no group: it is class **none**, independent
of C2a ("two independent defects; they may land separately"), and can land whenever.

## G0 — the zero-cost group, and why C6 is first of all

### C6 is why `libs/std` is red today

`libs/std/src/random.bp` declares `pub fn pick<T>` and its own test calls it.
`tryResolveTypeManipulationCall` (`infer.zig` l.4041) is called at l.6901 for every non-builtin
call **before user bindings and before the receiver check**, and it claims the name:

```
$ botopink check          # in libs/std
error: pick expects a type and field names at random:141:13
```

A *method* is hijacked too: `record P { val x: i32, fn pick(self: Self) -> i32 { … } }
val v = p.pick();` → `error: pick expects a type and field names`, because l.6901 runs before the
receiver branch at l.6981. And a plain user fn: `fn pick(a: i32, b: i32) -> i32 {…}
val v: i32 = pick(1, 2);` → `pick: first argument must be a type name`.

That single red is what makes C6 first. The library baseline at HEAD is:

| Library | `.bp` | Today | Owner of the red |
|---|---|---|---|
| `libs/std` | 30 files / 4823 lines | **red** — `error: pick expects a type and field names at random:141:13` | **C6** (and [`03-std-surface`](../03-std-surface/README.md)) |
| erika | 3 / 1031 | **red** — `the template module did not compile` | [`01-comptime-dispatch`](../01-comptime-dispatch/README.md) |
| rakun | 15 / 1064 | **red** — `a declared dependency was not found under the libs root` | [`12-library-repos`](../12-library-repos/README.md) |
| jhonstart | 16 / 894 | green | — |
| onze | 5 / 444 | green | — |
| emilia | 4 / 803 | green | — |

So the measurement pass of every **library**-class row can only *compile* jhonstart, onze and
emilia today. `libs/std`, erika and rakun contribute nothing to a compile count until C6 and the
comptime-dispatch front land — **C6 first, then re-measure** every count in
[`blast-radius.md`](./blast-radius.md) before G1 starts.

**Cross-front decision, due before [`03-std-surface`](../03-std-surface/README.md) lands.** That
front also names the `pick` collision and cannot fix it without renaming a public std function.
The durable fix is C6 (or [`types-as-values.md`](./types-as-values.md) step A5, which supersedes
C6's builtin-specific rows but **not** its shadowing fix). If the std front lands first it renames
`random.pick`, and this front renames it back.

### Why the other four cost nothing

| Row | Why zero library migration |
|---|---|
| C4b | Touches `comptime/eval.zig` + `comptime/error.zig` only; no fixture or library changes, only new tests. Can run beside every other row |
| C11 | `..` appears in no `.bp` file in the repository (the `dotDot` token exists at `lexer/token.zig` l.41 and nothing uses it). **5** fixtures in total, all in `comptime/tests/variants.zig`. The current behaviour is wrong enough that no working code can depend on it — the cheapest correctness row in the front |
| C7 | The only three generic enums in the ecosystem (`Result<R,E>`, `IteratorStep<T,E,C>`, `Yield<T,R>`, all in `libs/std/src/builtins.d.bp`) carry a payload on every variant, and no `Option` enum exists — optionality is the `?T` / `null` sugar. **2** fixtures, neither showing a `?` today, so the row is invisible in the tripwire set — regenerate the two slugs deliberately |
| C12 pipeline | `\|>` appears in no `.bp` file in the repository (the `pipe` token is at `lexer/token.zig` l.38 and no surface code uses it). The `val assert` half is **not** in G0: it needs C8 and goes to G2 |

The five G0 rows are file-disjoint from each other and from everything below, so G0 can be one
commit per row in any order after C6.

**Acceptance of the group:**
- [ ] A user fn **or method** named `pick`/`omit`/`partial`/`mergeRecords` resolves to the user's;
      `botopink check` in `libs/std` no longer reds at `random:141:13`
- [ ] `val k: string[] = @RecordKeys(P)` checks; `@field(p, "x")` has the field's type
- [ ] `comptime 1 / 0` and `comptime -"s"` are comptime errors located at the expression
- [ ] `Person(..alice, age: 25)` checks; an unknown label reds at the label, a wrong value type at
      the value
- [ ] `val n: Option2<i32> = Option2.None;` checks
- [ ] `val r: i32 = 1 |> double;` checks; `1 |> add(1, 2)` for a 2-ary `add` reds

## G1 — the emilia wave: four rows that cannot be split

### One enum exhibits all four rows

**emilia carries 92 of the ~117 affected sites on 680 lines** (29 C1 + 35 C8 + 28 C10), all
funnelling through one design decision: `tokens.bp` declares a single `pub enum Token` with nested
sections, and `emilia.bp` annotates 27 presumed compiler-synthesized section names (`TokenText`,
`TokenPadX`, `TokenBorderColor`, …) that are declared nowhere, binds their payloads in `case` arms,
and returns the result through `return out;`.

| Row | What the `Token` enum contributes | Why the row reds emilia on its own |
|---|---|---|
| C10 | 28 annotation sites naming an undeclared type — `emilia.bp:103` `fn textTokenToCss(t: TokenText)`, `:187` `padScaleX(s: TokenPadX)`, `:334` `borderColorToCss(c: TokenBorderColor)`, …, plus `:23` `-> unit` | the unknown-type fallback (`env.zig` l.930-931) becomes an error |
| C8 | 35 of 44 binding arms bind a payload **and use it** (20 pass-to-fn, 12 pass-to-fn *and* string-concat, 3 pure concat) | the binding gets the payload field's declared type instead of `freshVar()` — and the payload type is one of the undeclared section types |
| C2a | 28 `case`-as-value blocks | none on its own (all type-homogeneous), but it gives the `case` a type for C1 to check |
| C1 | 29 of the 44 plausible library reds: 28 `return <ident>` where the ident came from a `case`, plus 1 effect-wrapper unwrap (`emilia.bp:57`) | the `return` is unified with the declared return type |

**C1, C2a, C8 and C10 must land in one wave or emilia does not compile at any intermediate point**
— the single hardest scheduling constraint in the front. emilia is migrated in the same wave (the
nested-section enum grows real declared section types, or emilia stops annotating them — decide
before C10).

### Why C1 and C2a in particular are inseparable

31 of C1's 44 library sites are `return <ident>` where the ident came from a `case` — 28 in
`emilia/src/emilia.bp`, plus `libs/std/src/order.bp:30` and `unicode.bp:88`. Today those idents
are fresh vars (C2a), so **C1 alone cannot check them and C2a alone has nothing to check them
against**. They are the concrete reason C1 and C2a are one landing group.

### Order inside the wave: C2a → C1 → C8 → C10

- **C2a first** — it gives a `case` a type, so C1 has something to unify a `return <ident>`
  against. It breaks **zero** libraries.
- **C1 second** — land it behind a walk that *reports* instead of failing, triage, then flip to
  hard errors. Pre-audit the two risky sub-populations first: the `return case` fixtures and the
  **107 bare-identifier returns** (where a fresh var from elsewhere is doing the work). See
  [`blast-radius.md`](./blast-radius.md#c1--migration).
- **C8 third, in its own commit** — a payload binding is often fed to a `return`, so C1 alone
  already surfaces some of these; folding C8 into C1's commit makes the triage unreadable. Same
  reporting-pass shape as C1.
- **C10 last** — the two-pass typedef registration must land *before* the fallback is removed, and
  the removal is the last commit of the row. The four `-> unit` `declare fn`s in `libs/std`
  (`env.bp:30`, `env.bp:35`, `process.bp:28`, `random.bp:28`) are renamed to `void` here.

The source analysis contradicts itself on the first two: the C2 row's *Ordering* cell says "One
branch, **C1 first**", while the landing-groups table says "C2a → C1". The README follows C2a → C1,
and so does this file, for the reason above (C1's triage over the 31 `case`-sourced returns is
only readable once those idents have a type). Confirm when the reporting pass runs.

### The effect-wrapper rule travels with C1

**The target of a `return` inside an effect body is the wrapper's inner channel, not the wrapper**
— `#[@result]` → the `R` of `@Result<R, E>`, `#[@future]` → the `T` of `@Future<T, E>`,
`#[@generator]` → the `R` channel, `#[@context]` → the `X` of `@Context<B, X>`; `#[@iterator]`
already forbids `return <expr>` (`infer.zig` l.5491-5501). That is the auto-wrap contract the
lowering already records (`wrap_ok` l.5544, `wrap_resolved` l.5560). It covers 9 library sites —
`libs/std/src/primitives.bp:517`, `libs/std/src/http.bp:71`, `jhonstart/src/hooks.bp:29,37,43,49,57`,
`emilia/src/emilia.bp:57` — five of them `@Context` in `jhonstart/src/hooks.bp`, which has **no
`@Context` lowering today**: extend the rule to `@Context<B, X>` → `X` or hooks dies wholesale.

The count does not add up as written: "9" effect-wrapper sites are claimed and the eight above are
listed, and the listed sites of all four shapes (8 + 30 + 3 + 1) total 42, not the 44 of the
per-library split in [`blast-radius.md`](./blast-radius.md#c1--library--many) — one std site and
the one erika site are unaccounted for. Recount during C1's reporting pass.

### What can be measured when

| Library | G1 exposure | Measurable |
|---|---|---|
| emilia | C1 29 · C8 35 · C10 28 | today |
| jhonstart | C1 5 · C10 1 (`server.d.bp:28` `-> @Context<Http, Request>` — `Http` is declared nowhere) | today |
| `libs/std` | C1 9 · C10 9 | after C6 (G0) |
| erika | C1 1 | **not until [`01-comptime-dispatch`](../01-comptime-dispatch/README.md) lands** |
| onze, rakun | 0 | onze today; rakun after [`12-library-repos`](../12-library-repos/README.md) |

**Acceptance of the group:**
- [ ] `val a: bool = case 42 { 0 -> "a"; _ -> "b"; };` reds; the mismatched-arm policy is pinned
      in `case_arms_with_different_types_string_i32_union` and
      `case_union_return_type_from_mismatched_arms`
- [ ] `fn f() -> i32 { return "s"; }` reds at the value with a caret; `#[@generator]` `return 42`
      against `R = string` reds; `val f = fn(x: i32) -> i32 { return "s"; };` reds
- [ ] `A(v) -> f(v)` reds; same for `Dog(b) | Cat(b)`, `x if (x > 0) -> f(x)`, `Ok(v)`/`Err(e)` on
      `@Result`, `[first, ..rest]`
- [ ] An unknown type name reds at the TypeRef; a non-type binding in annotation position reds;
      forward references to records/enums declared later still check
- [ ] emilia, jhonstart, onze and `libs/std` compile at the end of the wave

## G2 — narrowing prerequisites

C5 then C12's `val assert` half. Zero library cost.

- **C5** — `parser/decls.zig` l.349-357 stores the narrowed type as the guard fn's `returnType`, so
  a guard call is typed `T`. The `if` condition path calls `unifyAt(bool, condType)` at `infer.zig`
  l.5833, so the branch errors before the narrowed binding is used — the type-guard narrowing is
  unreachable today. Probe: `fn isPositive(n: i32) -> n is i32 { return n > 0; }
  val b: bool = isPositive(5);` → `expected bool, got i32 at main:2:15`. The guard body being
  checked against `bool` is only observable once C1 (G1) is in.
- **C12 `val assert`** — `val assert P = e catch h` must check `P` against `e`'s type, which is the
  pattern-vs-type machinery C8 (G1) builds. Probe: `val assert 42 = answer catch 0;` with `answer`
  unbound → `Checked`.

With G1 these unblock [`narrowing.md`](./narrowing.md) step B6 — **except** its "no narrowing
needed" false negatives, which B6's own row says depend on C3's fix to the subsumption leak, and C3
is in G4. B6 can start after G2; its negative tests for `?T` arithmetic (`return x + 1` on `?i32`)
can only red after G4.

(The source cites the dead type-guard narrowing as l.5808-5845 in C5, l.5836-5845 in the landing
groups and in the narrowing table, and l.5810-5832 for the type-guard arm of `inferBranchExpr`.
They are the same code; re-locate by `typeGuardFns`.)

**Acceptance of the group:**
- [ ] `val b: bool = isPositive(5);` checks; the guard body must return `bool`
- [ ] `if (isStr(y)) { val s: string = y; }` checks with `y: ?string`
- [ ] `val assert 42 = answer catch 0;` with `answer` unbound reds

## G3 — strictness: C9, and why it waits for three things

C9 makes method bodies join the strict contract that `default fn` interface bodies already have.
The best-effort walk (`inferTypeMethods` l.2916-2967, swallow site l.2970-2975) exists *because*
real bodies trip gaps, which makes C9 the least predictable row. **79 method bodies are swallowed
today**: erika 39, std 31, rakun 7, onze 2, jhonstart 0, emilia 0.

**Instrument before deciding anything**: make `inferTypeMethods` count and print the swallowed
errors over `libs/std` plus the five siblings, and read the list before deciding whether C9 is one
row or three. That measurement is only meaningful when:

| Precondition | Why | Group / front |
|---|---|---|
| `libs/std` compiles | 31 of the 79 bodies | G0 (C6) |
| erika compiles | 39 of the 79 bodies — the largest single exposure in the front, never type-checked (`erika/src/erika.bp:24` `pub fn toArray(self: Self) -> Array<T>`, `:105` `return Query(items: sorted);` inside `orderBy<K>`) | **[`01-comptime-dispatch`](../01-comptime-dispatch/README.md) — erika's 39 cannot be measured at all before it lands** |
| rakun compiles | 7 of the 79 | [`12-library-repos`](../12-library-repos/README.md) |
| G1 has landed | many swallowed method-body errors are `return`- and `case`-shaped, so the count only means something once C1 and C8 are strict | G1 |

The unknown-method half (the `inferCallExpr` l.7105-7114 fallback) is free: **0** calls in any
library reach a method the receiver does not declare.

**Acceptance of the group:**
- [ ] A type error in a record method body reds; `val a: string = d.quack()` reds when `quack`
      returns `self.id`
- [ ] Calling an undefined method reds (`methodNotActive` / `unknownMethod`) when the receiver's
      type is known and nominal, and stays permissive for an unresolved type variable
- [ ] An unannotated method's return type is inferred from its body once, then stored
- [ ] The swallowed-error count over the six libraries is published before the flip, and is 0
      after it

## G4 — diagnostics: why it lands last

C3 and C13 both rewrite the **212 files** under `snapshots/comptime/*/errors/` (107
`assertTypeErrorSnap` tests / 106 slugs × the `node` and `erlang` copies):

- **C3** flips expected/found in every message that names a boolean or arithmetic mismatch
  (`val q: bool = (1 && true);` → `expected i32, got bool at main:1:18`, reversed today) and adds
  locations to the bare-`unify` arithmetic errors (`infer.zig` l.5386, l.5394).
- **C13** adds a `┌─` box to every error that has none today — the `unify.zig` constructors
  (l.37/54/58/66/76/85/97/102/109/119/127), the 9 unlocated `TypeError.custom` sites and the
  method/interface constructors — and moves `effect-missing-wrapper` from the first body statement
  to the return type.

Doing them separately regenerates that family twice. And **every group before G4 adds new error
snapshots** — G1's return, `case`, pattern and unknown-type errors, G2's guard and `val assert`
errors, G3's method-body and unknown-method errors. Landing G4 earlier would write those new
snapshots in the old orientation and without locations, and then regenerate them again.

C3 carries the one unquantified library risk in G4: string/number `+` mixing is common in
`libs/std` and in erika/jhonstart string building, so the arithmetic constraints (not the
orientation fix) may red real code. Run the same reporting pass as G1 over the libraries before
flipping; erika's share is not measurable until
[`01-comptime-dispatch`](../01-comptime-dispatch/README.md) lands.

**Acceptance of the group:**
- [ ] `1 && true` → `expected: bool, found: i32` with a caret on `1`; `"a" * "b"` and `-"s"` red
      with a location
- [ ] `fn f(x: ?i32) -> i32 { return x + 1; }` reds
- [ ] `#[@result] fn f() -> i32` reports `effect-missing-wrapper` at the return type, not at the
      first body statement
- [ ] Every error snapshot listed in 1.0.1-beta `06-snapshot-review/comptime-errors-effects.md`
      root cause 5 has a `┌─` box

## Work outside the groups

| Work | Where | Ordering constraint |
|---|---|---|
| The five grammar gaps | [`parser-gaps.md`](./parser-gaps.md) | The `parser/exprs.zig` half (`&&`/`\|\|` in `if`, `_` binder) is independent of every group. `assert x is P` needs C8 (G1). `<Pattern> as name` and unnamed payloads, if implemented rather than deleted, cross all four backends |
| Types as values, A0…A5 | [`types-as-values.md`](./types-as-values.md) | A0 is [`03-std-surface`](../03-std-surface/README.md)'s; A1 lands after C10's two-pass registration (G1) and deletes C10's bindings arm; A5 lands after C6's shadowing fix (G0) |
| Narrowing, B6/B7 | [`narrowing.md`](./narrowing.md) | B6 after G1 + G2 (and G4 for the subsumption false negatives); B7 blocked on the `@print` string-rendering decision |
| Trailing default parameters at the call site | analysed with the module-health split (see the README's Notes) | edits `comptime/infer.zig`; pick it up before G1 |

**Do not parallelise inside this front.** Part 0 (every group above), types-as-values A2–A5 and
narrowing B6 all touch `comptime/infer.zig`. Only C4b, B7 and the `parser/exprs.zig` half of the
parser gaps are independent and can run beside everything else.

**Interaction with [`10-comptime-dedup`](../10-comptime-dedup/README.md).** That front deletes 3
of the 4 byte-identical typed-AST copies per slug. If it lands first, every regeneration above
costs a quarter as many files; if it lands after, it deletes files this front just re-recorded.
Either order works — they must not run at the same time (`fronts.md` note 3).
