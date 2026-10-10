# Front 24 — effects by return type: the guide as one program, four confirmations, one measurement

**Priority:** medium · **State:** not started (surface landed in 1.0.10, C-32, decisions 118–135)
**Depends on:** rakun track's `serverAction` (guide § 7 types against stubs until then) · maintainer
confirmations 24-a, 24-b, 24-c, 24-g
**Owns:** [`guide.md`](../../../1.0.10-beta/00-compiler-carry-over/24-effects-by-return/guide.md)
(stays in 1.0.10; fences run from there) · `scripts/check-docs.sh`'s guide entry (one-line carve-out
of `00-gate/114`'s script) · `docs.md` § Loops, § use, § Effects, § Results, § Iterators, § Host
bindings, § *Migrating from the effect annotations* (with 07) · `tests/language` effect, generator
and loop cells (verify only) · `comptime/effect_chain.zig` and its drift test ·
`comptime/diagnostics.zig`'s effect codes (24-a)
**Does not touch:** `lexer.zig`, `parser/**`, `infer.zig` beyond effect legality sites (01 — an
effect-typing defect is a row in 01's README) · backends' effect lowerings (02–05) ·
`libs/std/src/{builtins.d.bp,async.bp,io/http.bp}` (std track) · language server (26)

Paths relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says otherwise.

## Goal

Every effects-guide fence compiles as one program under `check-docs.sh`; 24-a/b/c/g confirmed by
number; cost of a `@Result` per iterator item measured.

## Open

### Step 1 — every guide fence compiles as one program (E3, decision 134)

`botopink check` over `guide.md`, jhonstart as path dependency: ✓ fences type, ✗ sites answer their
code located; § 7's server action types against rakun's `serverAction` once shipped (stubs until
then, named as stubs in the report). E3's three checker rows landed in 01
(`run/try_catch_null_and_noreturn_narrowing`, `run/component_call_renders`).

- [ ] `scripts/check-docs.sh` runs the guide as one program and is green
- [ ] § 7 against the real `serverAction`, or the stub named with the rakun front that replaces it

### Step 2 — the confirmations

24-a (effect codes), 24-b (`@Task`'s `map` / `then`), 24-c (prefixed loop's label), 24-g
(`std/async`'s shape) confirmed or reversed; 24-h answered (decision 179, replaced by 432).

- [ ] the four ids in `../../decisions-taken.md`; a reversal's step named in the owning front — 24-a → 431 (checked `@Result`; 24-b → 432, the failing task;
      `throws: true` and `attempt` are `01-checker` step 42 and `02/97` step 18)

### Step 3 — the cost of a `@Result` per item

`@Iterator<@Result<T, E>>` of 10⁵ items consumed by `for` with `try r`, on erlang and wasm, vs the
same loop over `@Iterator<T>`; if the `Ok` wrap weighs, the backend specialises the `Ok` `yield` — a
row for 02 and 05, not edited here.

- [ ] the two ratios in this README with the program and the machine; a row filed in 02 / 05 if either exceeds 1.5×

## Decisions

- 24-a, 24-b, 24-c, 24-g — to confirm (statements in
  [1.0.10's `decisions-pending.md`](../../../1.0.10-beta/decisions-pending.md))

**Gate:** standard (fronts.md § Gate) + `effect_chain.zig` drift test green · `test-cli`, `test-docs` green

## Notes

- Components have no propagation: a page decides what an error shows — the helper is jhonstart's.
- A `@Task<@Result<T, E>>`'s Promise rejects with `E` and resolves with `T`; JS callers catch the rejection (decision 432, replacing 179).
