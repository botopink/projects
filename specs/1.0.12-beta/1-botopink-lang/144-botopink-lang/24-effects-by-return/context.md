# Front 24 — effects by return type: the guide as one program, four confirmations, one measurement

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s1 → B-27 · s2 → B-27 · s3 → B-27. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium · **State:** not started (surface landed in 1.0.10, C-32, decisions 118–135)
**Depends on:** rakun track's `serverAction` (guide § 7 types against stubs until then) · maintainer
confirmations 24-a, 24-b, 24-c, 24-g
**Owns:** [`guide.md`](../../../../1.0.10-beta/00-compiler-carry-over/24-effects-by-return/guide.md)
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

## Decisions

- 24-a, 24-b, 24-c, 24-g — to confirm (statements in
  [1.0.10's `decisions-pending.md`](../../../../1.0.10-beta/decisions-pending.md))

**Gate:** standard (fronts.md § Gate) + `effect_chain.zig` drift test green · `test-cli`, `test-docs` green

## Notes

- Components have no propagation: a page decides what an error shows — the helper is jhonstart's.
- A `@Task<@Result<T, E>>`'s Promise rejects with `E` and resolves with `T`; JS callers catch the rejection (decision 432, replacing 179).
