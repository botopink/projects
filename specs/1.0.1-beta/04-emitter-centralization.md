# Spec 04 — Erlang emitter cleanup

**Version:** 1.0.1-beta
**Priority:** low — optional refactors
**Depends on:** spec 01 (clean baseline for the byte-identical gate)

---

## Objective

Finish the optional parts of the `Term` / `erl_ast` migration so `codegen/erlang.zig` builds
every Erlang construct as a node, with no ad-hoc text or per-call allocation left.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/codegen/`.

## Current state

- `beam/term.zig` (`Term`) and `beam/erl_ast.zig` (`Expr`/`Clause`/`Body`/`Stmt`/`Comment`/
  `Function`/`Form` + `Builder`) are rendered by `beam/erl_emitter.zig`; `beam/beam_emitter.zig`
  renders `Term` as `.S` operands.
- `erlang.zig` writes no Erlang text. Comments are already nodes: `%%` notes and source comments
  are `erl_ast.Comment` in `Stmt`, `Expr` and `Form` position. `ComptimeModule.listing`
  (`emitComptimeModule`) builds the `COMPTIME ERLANG` snapshot section from the same forms.
- `Term` appears only as scalar leaves: `Term.str("~p")` (~432), `Term.int` (~2574) and
  `Ast.str(...)` (~3019). Every tuple/list/map that `erlang.zig` builds mixes variables or
  sub-nodes, so there is no constant aggregate left to move to `Term`.
- `Body.raw_block`, `Form.raw` and `Form.attribute` have no producer anywhere in
  `compiler-core` (only the render arms in `erl_emitter.zig` use them).
- `Ast.Expr.r(` (`raw`) has **17** uses in `erlang.zig`:

| Kind | Sites (`erlang.zig`) | What is raw | Class |
|---|---|---|---|
| Host template text | ~1410 (`templateNode` `flush`); `emitStringifyOpen`/`Close` ~1427-1432 | The `#[@External.Erlang("…")]` text rendered by `comptime/primOpTemplate.zig`, including the `iolist_to_binary(io_lib:format("~p", [` … `]))` wrapper written for `$stringify(…)` (used by `Array.join` in `libs/std/src/primitives.bp`) | stays raw (host code), wrapper optional refactor |
| Pre-spelled call head | ~3048 `headCall`, 9 callers (~1602, 2861, 2879, 2891, 2913, 2922, 2927, 2943, 3188) | `mod:fn` from `qualified`, mangled atoms, `Var` from `arenaVar` | refactor |
| Unreachable fallbacks | ~2524 (unknown `__bp_result/option_*` op), ~2534 (`opArg` with no fn arg), ~2921 (`interfaceAssocAtom` buffer overflow), ~3123 (empty `or` pattern) | `r("")` | refactor |
| Missing values | ~2696-2701 (`return`/`throw`/`try`/`break`/`yield` with no value), ~1886 (`yield;` item in an eager generator list), ~3008/3012 (comptime block without `break` value) | `r("")` | **bug → spec 03** |
| Variant pattern | ~3104 `patternNode` `.variant` | `{tag, Ast.Expr.r(v.name), …}` | **bug → spec 03** |
| Array spread name | ~2667 (`al.spread`) | `[1, 2, rest]` | **bug → spec 03** |
| `dotIdent` | ~2610 | `.Foo` → `Foo` (a variable); `beam_asm.zig` ~1707 lowers it to the atom `'Foo'` | **bug → spec 03** |

The bug rows change Erlang output, so they are fixed in spec 03 (spec 06 already routes the
erlang root causes there), not here. Evidence:

- Missing value: `snapshots/codegen/erlang/range_open_ended_range.snap.md` — `break;` inside
  `if` renders `true ->` then `;` (erlc: `syntax error before: ';'`,
  `06-snapshot-review/codegen-features.md` row `range_open_ended_range | erlang`).
- Variant pattern: `narrow_case_enum_area_with_print`, `case_guard_variant_field_guard`,
  `enum_payload_variants_with_method_using_variantfields_case`, `assert_pattern_with_*` —
  `{tag, Circle, R} ->` binds `Circle` as a variable while constructors build `{'Circle', 2.0}`
  (`06-snapshot-review/codegen-features.md` S6, `codegen-wat-narrowing.md`). Fix is
  `{'Circle', R}` (`Ast.Expr.a(v.name)`, no `tag`).
- Array spread: `array_prepend_with_identifier` — `[1, 2, rest]` instead of `[1, 2] ++ rest()`
  (`06-snapshot-review/codegen-builtins-aggregates.md`).
- `dotIdent`: no erlang snapshot reaches it; spec 03 needs a test with the fix.

## Rule

Every step below is a pure refactor: Erlang and beam snapshots stay **byte-identical**. A step
that changes a snapshot has hit a bug — move that part to spec 03.

---

## Steps

| Step | What | Acceptance |
|---|---|---|
| 1 | `headCall` → `.call{ .module, .name }` (heads from `qualified`/`calleeAtom`/`interfaceAssocAtom`) or `.apply{ .fun = .variable }` (~2879); delete `qualified` if unused | no `r(head)`; snapshots identical (if a spelled external symbol now gets quoted by `writeAtom`, that diff is a fix → spec 03) |
| 2 | Unreachable fallbacks (~2524, ~2534, ~2921, ~3123) return an error (or assert) instead of `r("")` | no `r("")` in these 4 sites; snapshots identical |
| 3 | Variable names without the scratch allocation: `erlangVar` (`= erlEmitter.varName`, dupe + uppercase) has 4 call sites (~1657, ~1658 `varRef`; ~1676 `bindExpr`; ~2240 `arenaVar`), fanned out to 20 `arenaVar` and 3 `varRef` callers. Each read allocates on `this.alloc`, then copies into `b.arena` (`dupe`/`allocPrint`) and frees. Build the name once in `b.arena` (`varName(b.arena, …)`, `Name@N` printed straight into the arena via `writeVar`) | no `this.alloc` allocation per variable; `erlangVar` alias removed if unused; snapshots identical |
| 4 | Optional: `$stringify` wrapper as a `call` node (`iolist_to_binary(io_lib:format("~p", [Parts]))`, the shape `formatNode` ~2972 already builds) around the inner template parts, instead of open/close raw text | template `raw` is only host text; snapshots identical |
| 5 | Optional: constant number leaves `.{ .number = "0" / "1" }` (~889, ~925, ~926, ~2685) → `Term.int` | snapshots identical |
| 6 | Remove the dead bridge variants `Body.raw_block`, `Form.raw`, `Form.attribute` (and their `erl_emitter.zig` arms) | builds; snapshots identical |
| 7 | Document why each remaining `raw` stays (host template text; the bug rows until spec 03 lands) | reasons in `codegen/beam/AGENTS.md`; `codegen/AGENTS.md` "Names" bullet matches |

Update `codegen/AGENTS.md` and `codegen/beam/AGENTS.md` in the same commit as each step.
