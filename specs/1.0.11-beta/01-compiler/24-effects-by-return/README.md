# Front 24 — effects by return type: the tail

**Priority:** medium — the surface is landed (C-32, decisions 118–135) and every cell is green;
what is open is the guide as one program, four confirmations, one decision and one measurement.
**Depends on:** `00-gate` (nothing of this front's files is a gate item) · the rakun track's
`serverAction` stubs (the guide's § 7 types against stubs only) · maintainer confirmations 24-a,
24-b, 24-c, 24-g · decision 24-h (`unwrapOrThrow`).
**Owns:** [`guide.md`](../../../1.0.10-beta/00-compiler-carry-over/24-effects-by-return/guide.md)
(stays in 1.0.10; the fences are re-run from there) · `scripts/check-docs.sh`'s guide entry (with
25, which owns the script — a one-line carve-out) · `docs.md` § Loops, § use, § Effects, § Results,
§ Iterators, § Host bindings, § *Migrating from the effect annotations* (with 08) · the
`tests/language` effect, generator and loop cells (verify only; a fix is the owning front's) ·
`comptime/effect_chain.zig` and its drift test · `comptime/diagnostics.zig`'s effect codes (24-a)
**Does not touch:** `lexer.zig`, `parser/**`, `infer.zig` beyond the effect legality sites (01 owns
the files; an effect-typing defect found here is a row in 01's README, not an edit) · the four
backends' effect lowerings (02–05) · `libs/std/src/{builtins.d.bp,async.bp,io/http.bp}` (the std
track) · the language server (26).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| E3's guide fences | `24-effects-by-return/README.md` | § Step E3, box 1 · § Open, "Guide fences (E3, decision 134)" |
| 24-a/b/c/g | `decisions-pending.md` | § Front 24 |
| `unwrapOrThrow` | `24-effects-by-return/README.md` | § Open, "The JS interop helper" → 24-h |
| the `@Result`-per-item cost | `24-effects-by-return/README.md` | § Risks, third bullet |

## What holds

Every step (E1, E2, E4, E5, E7, E8) and every cell of the 1.0.10 README; the three checker rows
E3 named (`try x catch null` into a `?U`, narrowing after a `noreturn` call, a component called
inside a component) landed in 01 (`run/try_catch_null_and_noreturn_narrowing`,
`run/component_call_renders`). Measured at 1.0.10's close.

## Steps

### Step 1 — every guide fence compiles as one program (E3, decision 134)

`botopink check` over `guide.md` with jhonstart as a path dependency: the ✓ fences type, the ✗
sites answer their code located; § 7's server action types against rakun's `serverAction` once the
rakun track ships it (until then the stubs, named as stubs in the check's report).

**Acceptance:**
- [ ] `scripts/check-docs.sh` runs the guide as one program (25's one-line carve-out) and is green; the three fences that waited on 01 type
- [ ] § 7 against the real `serverAction`, or the stub named with the rakun front that replaces it

### Step 2 — the confirmations and 24-h

24-a (the effect codes), 24-b (`@Task`'s `map` / `then`), 24-c (the prefixed loop's label), 24-g
(`std/async`'s shape) confirmed or reversed; 24-h answered (04 step 5 records it).

**Acceptance:**
- [ ] the five ids in `../decisions-taken.md`; a reversal's step named in the owning front

### Step 3 — the cost of a `@Result` per item

An `@Iterator<@Result<T, E>>` of 10⁵ items consumed by `for` with `try r`, measured on erlang and
wasm against the same loop over `@Iterator<T>`; if the `Ok` wrap weighs (a ratio written here), the
`Ok` `yield` is specialised in the backend — a row for 02 and 05, not this front's edit.

**Acceptance:**
- [ ] the two ratios in this README with the program and the machine; a row filed in 02 / 05 if either exceeds 1.5×

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green
- [ ] `zig build test-language` on four targets with § Cells (no line in `expected-failures.txt`); the `effect_chain.zig` drift test green
- [ ] `test-cli`, `test-docs` green
- [ ] `AGENTS.md` of every directory touched in the same commit
- [ ] Commit on `fix/24-effects-by-return`; no push, no merge

## Blast radius

None on emitted output; a measurement and documents.

## Notes

- Components have no propagation: a page decides what to show for an error — the library helper
  is jhonstart's to offer.
- botopink Promises resolve with `Error` on expected failures; JavaScript callers read the value
  (24-h decides whether anything else ships).
