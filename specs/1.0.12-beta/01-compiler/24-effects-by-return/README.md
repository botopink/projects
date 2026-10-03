# Front 24 — effects by return type: the guide as one program, four confirmations, one measurement

**Priority:** medium · **State:** not started (the surface landed in 1.0.10, C-32, decisions 118–135)
**Depends on:** the rakun track's `serverAction` (the guide's § 7 types against stubs until then) ·
maintainer confirmations 24-a, 24-b, 24-c, 24-g
**Owns:** [`guide.md`](../../../1.0.10-beta/00-compiler-carry-over/24-effects-by-return/guide.md)
(stays in 1.0.10; the fences are run from there) · `scripts/check-docs.sh`'s guide entry (a one-line
carve-out of `00-gate/114`'s script) · `docs.md` § Loops, § use, § Effects, § Results, § Iterators,
§ Host bindings, § *Migrating from the effect annotations* (with 07) · the `tests/language` effect,
generator and loop cells (verify only) · `comptime/effect_chain.zig` and its drift test ·
`comptime/diagnostics.zig`'s effect codes (24-a)
**Does not touch:** `lexer.zig`, `parser/**`, `infer.zig` beyond the effect legality sites (01 — an
effect-typing defect found here is a row in 01's README) · the four backends' effect lowerings
(02–05) · `libs/std/src/{builtins.d.bp,async.bp,io/http.bp}` (the std track) · the language server (26)

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise.

## Goal

Every fence of the effects guide compiles as one program under `check-docs.sh`, the 1.0.10 choices
24-a/b/c/g are confirmed by number, and the cost of a `@Result` per iterator item is measured.

## Open

### Step 1 — every guide fence compiles as one program (E3, decision 134)

`botopink check` over `guide.md` with jhonstart as a path dependency: the ✓ fences type, the ✗
sites answer their code located; § 7's server action types against rakun's `serverAction` once the
rakun track ships it (until then the stubs, named as stubs in the check's report). The three checker
rows E3 named landed in 01 (`run/try_catch_null_and_noreturn_narrowing`, `run/component_call_renders`).

- [ ] `scripts/check-docs.sh` runs the guide as one program and is green
- [ ] § 7 against the real `serverAction`, or the stub named with the rakun front that replaces it

### Step 2 — the confirmations

24-a (the effect codes), 24-b (`@Task`'s `map` / `then`), 24-c (the prefixed loop's label), 24-g
(`std/async`'s shape) confirmed or reversed; 24-h is answered (decision 179, recorded by `04-js`).

- [ ] the four ids in `../../decisions-taken.md`; a reversal's step named in the owning front

### Step 3 — the cost of a `@Result` per item

An `@Iterator<@Result<T, E>>` of 10⁵ items consumed by `for` with `try r`, measured on erlang and
wasm against the same loop over `@Iterator<T>`; if the `Ok` wrap weighs, the `Ok` `yield` is
specialised in the backend — a row for 02 and 05, not this front's edit.

- [ ] the two ratios in this README with the program and the machine; a row filed in 02 / 05 if either exceeds 1.5×

## Decisions

- 24-a, 24-b, 24-c, 24-g — to confirm (the full statements in
  [1.0.10's `decisions-pending.md`](../../../1.0.10-beta/decisions-pending.md))

**Gate:** standard (fronts.md § Gate) + the `effect_chain.zig` drift test green · `test-cli`,
`test-docs` green

## Notes

- Components have no propagation: a page decides what to show for an error — the library helper is
  jhonstart's to offer.
- botopink Promises resolve with `Error` on expected failures; JavaScript callers read the value
  (decision 179).
