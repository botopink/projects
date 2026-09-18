# Front 06 — checker

**Delivered in part** — the front ran from 2026-09-17 to 2026-09-18 on `botopink-lang` `feat` and
landed five groups plus decision 8's grammar. It is the one front of 1.0.4-beta that did not close:
its remaining rows are the whole of 1.0.5-beta's `01-checker`.

**Landed:** G0 (merge `13f61fa`), G1 (`9b61ecf` … `1c9b60c`), C5, C12 and N25 (merge `62d4865`,
`d2b468d`, `3e7cd62`), C9 and N24 (merge `c2dd780`), C3 and C13's located `MissingExternalTarget`
(`f6d8ce6`, `7b1db40`), and decision 8's **grammar** — `unknown`, union types, `is`, `case` arms
(merge `d0c27f6`). Full table below.

**Ran after** [`../12-surface-cutover/`](../12-surface-cutover/README.md) (reordered by the maintainer
2026-09-17), so its rules were written on the unified `TypeDecl`/`BehaviorDecl` AST once instead of
being ported twice. It carried 1.0.2-beta front 07 whole, plus the rows collected since (N1–N30).

**Owned:** `comptime/infer.zig` · `comptime/types.zig` · `comptime/env.zig` · `comptime/unify.zig` ·
`comptime/transform.zig` · `comptime/eval.zig` · `comptime/error.zig` ·
`parser/{decls,exprs,patterns}.zig` · `lexer.zig` and `lexer/**` · `snapshots/comptime/**`, and it
could move all four codegen snapshot directories.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless stated otherwise.
Line numbers were measured at the 1.0.2-beta commit this spec was written against; re-locate by the
quoted symbol.

---

## Problem

`zig-out/bin/botopink check` on a scratch project accepted every one of these:

```
fn f() -> i32 { return "s"; }                                  → Checked
val a: bool = case 42 { 0 -> "a"; _ -> "b"; };                 → Checked
val q = "a" * "b";        val q = -"s";                        → Checked
enum E { A(v: i32), B }   case e { A(v) -> f(v); … }           → Checked   (f takes a string)
record D { val id: i32, fn bad(self: Self) -> string { val z: string = self.id; return z; } }
                                                               → Checked
val d = D(id: 1); val q = d.swim();                            → Checked   (no `swim`)
record Q { lat: bogusType }                                    → Checked
val n = 5; val x: n = 7;                                       → Checked
fn f(x: ?i32) -> i32 { return x + 1; }                         → Checked
val q = comptime 1 / 0;                                        → Checked
val assert 42 = answer catch 0;   (`answer` unbound)           → Checked
```

and rejected these, which are correct:

```
val q: bool = (1 && true);                  → expected i32, got bool at main:1:18   (reversed)
val n: Option2<i32> = Option2.None;         → expected Option2, got Option2
val b: bool = isPositive(5);                → expected bool, got i32   (a `-> n is i32` guard)
val alice = Person(name: "a", age: 1);
val b = Person(..alice, age: 25);           → expected string, got Person at main:3:18
fn pick(a: i32, b: i32) -> i32 { … } val v: i32 = pick(1, 2);
                                            → pick: first argument must be a type name
```

Every line of both blocks is closed. The last one is why `libs/std` did not compile at the
milestone's opening (`error: pick expects a type and field names at random:141:13`).

## Mechanism

Four mechanisms produced almost every row. Fixing a mechanism once was cheaper than fixing its
instances, and the rows that share a mechanism shared a snapshot regeneration.

| # | Mechanism | Rows |
|---|---|---|
| M1 | **A fresh type variable is the escape hatch.** `env.freshVar()` unifies with anything, so any construct the checker cannot type yet is given one and nothing downstream ever contradicts it | C1, C2, C5, C8, C9, C12 |
| M2 | **`unifyAt` is target-first and several callers pass operand-first** (`infer.zig` l.3769-3777 documents `a` = the declared/expected type) | C3, C13 |
| M3 | **One-way optional subsumption is reached from the wrong side** — `unify.zig` l.48-52 lets an *expected* `?T` accept a plain `T`, and arithmetic passes an operand as `a` | C3, and every "narrowing is not needed" false negative in [`narrowing.md`](./narrowing.md) |
| M4 | **Best-effort walks swallow errors** — `inferTypeMethods` (l.2916-2967) skips a method body that trips an inference gap | C9 |

Why each is written that way, and the one row (C6) that belongs to none of them, is in
[`rows.md`](./rows.md#the-four-mechanisms). `unify` itself never carries a location: a location
appears only when the caller went through `unifyAt`, and the two arithmetic call sites
(`infer.zig` l.5386, l.5394) did not.

## Measurements at the front's base

| What | Measured |
|---|---|
| Rows | 13 correctness rows (C1…C13, C4b), 4 of them behind one shared mechanism each — [`rows.md`](./rows.md) |
| Suite | 733 `test` declarations (437 comptime + 296 codegen), 726 carrying inline `.bp` source |
| Fixtures a fix moves | 76 `assertInfersOk` · 212 error-snapshot files · 796 typed-AST files · 9 documented compile-error skips — [`blast-radius.md`](./blast-radius.md) |
| The tripwire set | 17 slugs / 68 files carry a `typeNameOf` `?` — the checker visibly punting |
| Library migration cost | ~117 sites, **92 of them in emilia on 680 lines**; C7, C11 and C12's pipeline half cost **zero** |

The three rows that cost **zero** library migration did so for a measured reason: there is no `..`
record-update spread, no `|>` pipeline and no `Option`-shaped generic enum in any `.bp` file in the
repository.

## Delivered

| Group | Rows | Commits |
|---|---|---|
| **G0** — the free wins | C4b (comptime folding residual), C6 (user `pick`/`omit`/`partial`/`mergeRecords` beat the builtin intercept; `@RecordKeys`/`@field` typing), C7 (generic unit variants), C11 (record update `Person(..alice, age: 25)`), C12's pipeline half; **N17** the path error's caret; **N26** `loop (condition)` typed and `while` refused with a located message; **N27** `delegate` and `new` stop being keywords, `.@"const"` deleted | `ada3911`, `cab0bf7`, `c51aadd`, merge `13f61fa` |
| — | Two rows landed with G0 that are not the checker's: `loop (condition)` **lowered on all four backends** and commonJS's call-shaped `while` special case deleted (01 step 6's D8-6, pulled forward), and `libs/std`'s `Array.chunked` / `sliding` rewritten with `loop` (a `fronts.md` unowned item) | `c51aadd`, `cab0bf7` |
| **G1** — the emilia wave | **C1** a `return` unifies with the declared return type; **C2a** a `case` is typed from its arms, mismatched arms giving a union (decision 8 §3.2), **C2b** a `comptime { … }` block from its `break`; **N4/N23** the `@emit` fallback keeps well-typed `val`s; **C8** pattern bindings are typed and **N28** a section is a type named by its path (`Token.Text`); **C10** an annotation naming no type reds at the annotation, with **N30**'s `typeLoc` caret; **N8** (the `botopink check` view of C1 and C10) closed with them | `9b61ecf`, `a45f51b`, `574134a`, `9242b66`, `3a5ac7a`, `6135cf9`, `1c9b60c` |
| **G2** — narrowing prerequisites | **C5** a type guard is typed `bool`, not the type it narrows; **C12** a pattern assert checks its subject and its handler, then `val assert` takes no `catch` and its pattern binds (**N13**'s probe, `val assert 42 = answer catch 0;` with `answer` unbound, reds with it); **N25** a `@Result` return needs `#[@result]` (decision 8 §9) | `2b03e41`, `ae146e0`, merge `62d4865`, `d2b468d`, `3e7cd62` |
| **G3** — strictness | **C9** a record method body joins the strict contract `default fn` bodies already had; **N24** decision 8 §6 — a tuple label survives instantiation, and a fn-typed label called as a method is rewritten to positional and lowered on commonJS, erlang and beam | `75a6906`, `174e0e4`, merge `c2dd780` |
| **G4** — diagnostics, in part | **C3** boolean operands report target-first with the caret on the offending operand, and `*`/`/`/`%`/binary `-`/unary `-` require numbers; **C13's** `MissingExternalTarget` names the function, the backend and the call site, and a module that raises it fails alone instead of aborting the build | `f6d8ce6`, `7b1db40` |
| **Decision 8's grammar** | `unknown` is a keyword and a type of its own; a type may be a union `i32 \| string`; `x is T` is an expression; `case` arms are `Pattern { body }` with `when` guards, the inclusive range `A...B` (Zig spelling) and `.Variant` — the **grammar** half of N19–N22 | `6c849ae`, `4a3449f`, `3b491e3`, `dff3446`, merge `d0c27f6` |

Side effects worth the record:

- **The formatter follow-up** (`6bf0817`): `format` output compiles on every library — loop bodies
  keep their semicolons, package imports keep the handle, one-line lambdas are idempotent.
- **`libs/std`'s four `-> unit` declarations return `void`** (`6135cf9`); `unit` is not a type.
- **N24 struck two unowned rows** by probe: a tuple label on an array element and on a lambda
  parameter both resolve at this base. The spelling `#(a: i32, b: string)[]` does not parse — that is
  the array-suffix grammar, carried.
- **`registerStdlib`'s pending-name list is cleared per program** (C10): one env infers one std
  module per call, and a name left pending by one must not red in the next.

## Gate

- [x] `zig build test` from a cold runtime cache, green, in each landing worktree
- [x] `zig build test-libs`: **11 passed, 0 failed, 1 skipped** (rakun's erlang cell), no known-red line
- [x] `zig build test-language` at the last merge: **205 passed, 54 expected failures, 0 failed**
- [x] Regenerated snapshots reviewed, not blanket-accepted — C2a's 45 typed-AST re-records, C3's 12
      error snapshots and C10's caret family each read by hand, classified in the landing commit
- [x] `AGENTS.md` of every directory touched, updated in the same commit

## What it left, and where

Everything below is **1.0.5-beta `01-checker`** unless a row names another front. It is the whole
`comptime/**` tail of this front: the rows that never landed, the steps that never opened, and the
two conditions front 14 handed over.

### Rows

| Row | What is left |
|---|---|
| **N1 / N2** | Trailing default parameters at the call site, and a default on a non-last record field. Never executed — it was 1.0.2-beta comptime-dispatch step 3. Evidence: [`trailing-defaults.md`](./trailing-defaults.md). 2 lines of the language suite's expected failures |
| **N3** | `if (guard(v))` with `v: ?string` — C5 seen from a call site (`narrow_type_guard_basic_codegen`) |
| **N5** | `transform.zig` `makeLiteralExpr` wraps a comptime array as a `numberLit`; erlang renders a charlist and beam aborts `{unlowered_comptime_value, …}` |
| **N6** | **Decision 2** — a block is a statement, its value comes from `break`. The enforcement half of C1/C2, and the row that makes the four backends' block-as-value lowerings dead code (→ the backend fronts) |
| **N7** | A record field typed by a behavior rejects an implementing record |
| **N9** | Error snapshots render `┌─ :L:C` with no file name (`comptime/error.zig` ~`:33`) — verified still open at `c2dd780` |
| **N10** | E8 — the `#[@result]` wrap goes into each non-jumping arm; decided in `transform.zig`, so it re-records erlang **and** commonJS |
| **N11** | A pattern in binding position: `val Circle(r) = s` binds nothing, `assert x is Some(n)` does not parse. Its commonJS half is [`../01-backend-residuals/pattern-binding.md`](./../01-backend-residuals/pattern-binding.md) → `04-js` |
| **N12** | `loop_break_with_value`'s declared `-> i32` returning a list. 2 expected failures |
| **N14** | `run {…}` / `use effect {…}` arity mismatches reach codegen |
| **N15** | No lowering recorded for a method on an associated fn's result (`Array.range(…).map(…)`) |
| **N18** | Decision 8 §1 — written generic types carry all their arguments, `Self<…>` included; explicit type arguments at a use; the `unknown` fallback warning. 2 expected failures |
| **N19–N22** | The **inference** halves of `unknown`, union types, `is` by value and `case` arms — the grammar landed, the typing did not. 23 of the 54 expected failures name N22 — 16 of them alone, 7 combined with N19–N21 or N28 (arm binding, exhaustiveness, `_` on `unknown`, guarded arms never counting) |
| **N29** | A section value only writes as the leading-dot form with context (`.Text.Bold`); the qualified `Token.Text.Bold` is refused, so the value side does not mirror the type path N28 gave the language |
| **C6 residual** | The `@makeRecord`-with-a-comptime-binding case, left out of G0 |
| **C13 bulk** | The `.withLoc` sweep over `unify.zig` and the 9 `TypeError.custom` sites, plus `effect-missing-wrapper` at the return type — 212 files under `snapshots/comptime/*/errors/`. Only the `MissingExternalTarget` half landed, deliberately, so the sweep lands once and whole |

### Steps never opened

| Step | What is left |
|---|---|
| **6 — the parser gaps** | Five grammar gaps owning seven of the nine `assertComptimeCompileError` skips plus two `codegen/tests/narrowing.zig` skips. No checker row closes any of them. Two carry a recommendation to delete the tests instead: [`parser-gaps.md`](./parser-gaps.md) |
| **7 — types as values** | `type` as a first-class comptime value, `#[@code]`, and std type functions written in `.bp` that are actually executed (A0…A5): [`types-as-values.md`](./types-as-values.md). A5 supersedes C6's builtin-specific rows but not its shadowing fix, which landed |
| **8 — narrowing** | Every narrowing fixture compiles or is a documented skip; what they *assert* is still open. The per-pattern table, the 4-backend RUN LOG table and steps B6/B7: [`narrowing.md`](./narrowing.md) |
| **9 — decision 8 in the sources** | `Self<T>` in every generic `type` and `behavior`, annotations on the `val`/`var … = []` that would fall to `unknown`, `Display` for `Dict`, in the compiler test sources, `libs/std` and `examples/`. Verified not landed: `grep -c 'Self<' libs/std/src/primitives.bp` is 0. The `while` half of this step landed early with G0 |

### Handed to this front by others, still open

| Item | From |
|---|---|
| **A `type` declaration's constructor binding is named `record { name: string, count: i32 }`** by `buildRecordDeclName` (`:1832`) and its siblings `buildEnumDeclName` (`:1934`) / `buildInterfaceDeclName` (`:1891`), so hover and completion print a surface that no longer parses. Re-record `completion_decorator_record` with the fix | [`../14-tooling-and-docs/`](../14-tooling-and-docs/README.md), 2026-09-18 |
| **The VS Code `Case expression` snippet still teaches `pattern -> result;` arms** — it flips in a one-commit `vscode-extension` follow-up once N22's arm syntax is enforced (the extension's own `compiler-check` gate reds it today) | 14 → `11-tooling` |
| **`#[@external(node, "…")]` in lower case passes `check` and binds no host, silently** — only `External.<Target>` matches `FnDecl.isExternal`; it should be a located error. 1 expected failure | 09 step 5 sweep |
| **Importing a type requires importing the whole type closure its declaration mentions** — a field's type and a method signature's types must each be imported by name. Found migrating `examples/rakun`; worked around by naming every type in the `from` clause | 13, 2026-09-18 |
| **A type error's location names the wrong module** — `unknown type 'UserService'` reported at `src/main.bp:48:14` for a declaration in `src/users.bp:48:14` | 13, 2026-09-18 |
| **The formatter cannot keep source order and trivia the AST does not record**: payload variants move before sections (emilia's `Token`), an end-of-line comment moves to the next line, blank lines inside `loop` bodies and `if` branches are dropped. `format` output compiles and is stable (`6bf0817`); the parser keeps no member positions or trailing trivia | formatter follow-up, 2026-09-17 |
| **A label access in an untyped comptime body lowers to `maps:get`** (`badmap`) — jhonstart's html reads tokens positionally (`t.0…t.6`) to route around it. N24 struck the two sibling rows by probe; this one was not among them | 13 jhonstart migration |
| **`ConditionLoopValueUnsupported`** — a condition loop used as a value is refused on erlang and beam, unlocated | 06 G0's own residual |

### Decisions the maintainer still owes

None of these is a defect; each blocks the row above it from being written.

| Question | Why it is open |
|---|---|
| **`@code(text)` versus `#[@code]`** | `@code(text)` already exists as a builtin valid only inside template fns (`infer.zig` l.3808-3828, lowered through `template_eval.zig`). `#[@code]` would be the first `#[@…]` annotation that is neither an effect (`ast.zig` `EffectKind`) nor `@external`. The positions do not clash syntactically — confirm the shared name is intended, or pick another. Blocks step 7 |
| **`<Pattern> as <name>`** | Implement or delete the three tests. A new `Pattern` node reaches all four backends for a form no library uses. Blocks step 6 |
| **Unnamed enum variant payloads** | The recommendation is to drop them and keep `name: Type` as the convention, keeping only the nested-pattern half. Blocks step 6 |
| **[`external-annotations.md`](./external-annotations.md)'s compiler rows** | C1 (one validator for every annotated declaration) and C8 (STD-001 keyed on what each backend lowers) name this front but were never in its steps. Decide whether they join `01-checker` or move on |
| **The `SymbolKind.Function` → `Method` flip** | 14 left it deliberately: the VS Code Test Explorer classifies every `Method` symbol as a `test "…"` block, so the two repositories must move together. Not a checker question, but it is the last of 14's three handoffs → `11-tooling` |

The mismatched-`case`-arm question ("a union type or an error?") was answered by implementation:
C2a gives a union, pinned by `case_arms_with_different_types_string_i32_union` and
`case_union_return_type_from_mismatched_arms`.

## Blast radius as measured

| Class | Rows |
|---|---|
| **library** (a library stops compiling — needs a migration plan) | C1, C8, C9, C10, and possibly C3 |
| **many** (≥ 100 files regenerate, review needed) | C1, C2a, C3, C8, C13 |
| **few** (under ~20 files, mechanical) | C5, C6, C7, C11, C12 |
| **none** | C4b, C2b |
| **unblocks** (something red today goes green) | C5, C6 |

Full table per row, with the class and the named library, in
[`blast-radius.md`](./blast-radius.md). This front could move all four codegen snapshot directories,
because a fixture that newly fails to compile takes its codegen snapshots with it — which is why it
ran alone.

## Notes

- **Do not parallelise inside the carried work.** The remaining rows of steps 7 and 8 all touch
  `comptime/infer.zig`. Only the `parser/exprs.zig` half of step 6 is independent.
- **C6 and the std front.** The 1.0.2-beta std-surface front landed the shadowing guard without
  renaming `random.pick`; this front did not rename it either. A5 (step 7) supersedes the builtin
  rows, not the guard.
- **C7's chained-default claim** (`record Sym<T, U = T>` accepting `Sym<i32>` with `right: "two"`) is
  a C1 observation, not a separate defect; verify it now that C1 has landed.
