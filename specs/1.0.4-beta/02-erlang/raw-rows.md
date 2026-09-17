# erlang — the `raw` inventory

> Carried from `1.0.2-beta/05-erlang/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

`Ast.Expr.r(` is the erlang model's escape hatch: a node that carries already-spelled target text
instead of a structure the emitter renders. There are **13** of them in `src/codegen/erlang.zig`,
and they are not one thing — they are four classes with four different answers.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`. Every `file:line` is at
HEAD. Find them with:

```sh
rg 'Expr\.r\(' src/codegen/erlang.zig
rg -n '\.(print|writeAll|writeByte)\(' src/codegen/erlang.zig src/codegen/beam_asm.zig
```

## The four classes

| Class | Sites | Snapshots it pins | Answer |
|---|---|---|---|
| **missing value** | **7** — `:2308`, `:3174`, `:3175`, `:3176`, `:3184`, `:3628`, `:3632` | 1 (`comptime_block_with_break`, a `COMPILE ERROR`) | give each a real node — an output bug, [`README.md`](./README.md) step 4 |
| **unreachable fallback** | 4 — `:2967`, `:2977`, `:3537`, `:3768` | 0 | return an error or assert — byte-identical, step 8 |
| **pre-spelled call head** | 1 helper (`:3668`), **11** callers | all erlang snapshots | build the real `call` / `apply` node — byte-identical, step 8 |
| **host template text** | 1 — `:1566` | — | **stays**; this is the one thing a `raw` node is for |

1.0.1-beta recorded five missing-value sites. There are **seven**.

## Missing value — 7 sites

Each renders as **nothing**, which is how the bare-`break` bug produced a syntactically broken
module before it was fixed. A `raw` that renders to the empty string is not a placeholder; it is a
hole in the output that `erlc` finds later, or does not.

| Site | What is absent |
|---|---|
| `:2308` | a bare `yield;` item in an eager generator list |
| `:3174` | `return` with no value |
| `:3175` | `throw` with no value |
| `:3176` | `try` with no value |
| `:3184` | `yield` with no value |
| `:3628` | a comptime block whose `break` carries no value |
| `:3632` | a comptime block with **no `break` at all** — this is what makes `comptime_block_with_break` emit `result() -> (X * 2).`, the one `COMPILE ERROR` block left in the tree (cause E5) |

Two of these have twins in the JS backend, and the semantics must be decided once for both:

| erlang site | commonJS twin | The question |
|---|---|---|
| `:3175` (bare `throw`) | `src/codegen/commonJS.zig:2224` (`Stmt.throw_ = null` → `throw;`, a SyntaxError) | what a bare `throw` means — rethrow the caught value, or reject it in the checker. [`../04-js-bridges/bridges.md`](../04-js-bridges/bridges.md) JS-6 |
| `:3176` (`try` with no value) | `src/codegen/commonJS.zig:2227` | the same absence on the JS side, part of JS-2's audit |
| `:3632` (comptime block, no `break`) | `src/codegen/commonJS.zig:2414` | the same latent defect; unreached on commonJS only because the decl-level path folds `val result = comptime {…}` first |

## Unreachable fallback — 4 sites

| Site | What it falls back from |
|---|---|
| `:2967` | an unknown `__bp_result` / `__bp_option_*` op |
| `:2977` | `opArg` with no fn argument |
| `:3537` | `interfaceAssocAtom` buffer overflow |
| `:3768` | an empty `or` pattern |

All four return `Ast.Expr.r("")` for a state that should not happen. Return an error (or assert)
instead — a state that cannot happen must not have an output spelling. Byte-identical.

## Pre-spelled call head — 1 helper, 11 callers

`headCall` (`src/codegen/erlang.zig:3667-3669`) takes a head that has already been spelled as text
and wraps it in `Ast.Expr.r` at `:3668`. Callers: `1758`, `3448`, `3476`, `3498`, `3509`, `3529`,
`3538`, `3543`, `3559`, `3853`, `3875`.

Replace by the node the head actually is:

| Head shape | Node |
|---|---|
| a `qualified` head (`:3662`), a `calleeAtom`, an `interfaceAssocAtom` | `.call{ .module, .name }` |
| the `arenaVar` head (`:3476`) | `.apply{ .fun = .variable }` |

Delete `qualified` if it goes unused. **If a spelled external symbol now gets quoted by
`writeAtom`, that diff is a fix, not a regression** — record it as a cause in
[`causes.md`](./causes.md) rather than re-spelling the head to keep the old bytes.

## Host template text — the one that stays

`:1566` carries a `#[@External.Erlang]` template body: genuine host text, written by the program
author, which the compiler has no business restructuring. It stays, and
`src/codegen/beam/AGENTS.md` must say why — otherwise the next audit deletes it or, worse, adds a
second one beside it.

The beam equivalent is the `#[@External.Beam]` passthrough at `src/codegen/beam_asm.zig:2690`,
`:2693`, `:2710` — see [`../01-beam/emitter.md`](../01-beam/emitter.md).

## Dead scaffolding and per-call allocation

Byte-identical cleanups left from the `Term` / `erl_ast` migration, owned by this front.

| What | Where | Why |
|---|---|---|
| `Body.raw_block`, `Form.attribute`, `Form.raw` | `src/codegen/beam/erl_ast.zig:213`, `:253`, `:260`; render arms at `src/codegen/beam/erl_emitter.zig:577`, `:604` (both `raw_block`), `:670` (`attribute`), `:676` (`raw`) | No producer anywhere in `compiler-core` — three ways to write verbatim text that nothing uses |
| Variable names built on `this.alloc`, then copied into `b.arena` and freed | `src/codegen/erlang.zig:2046` (`varRef`, 4 call sites: 1987, 2073, 2635, 3003), `:2069` (inside `bindExpr`), `:2661` (`arenaVar`, 18 call sites: 2064, 2254, 2294, 2480, 2481, 2678, 2712, 2738, 2836, 2861, 2864, 3115, 3201, 3260, 3262, 3277, 3476, 3817); `erlangVar` = `erlEmitter.varName` at `:1003` | Every variable read allocates and frees. Build the name once in `b.arena` (`Name@N` printed straight into it); drop the `erlangVar` alias if it goes unused |
| Constant number leaves `.{ .number = "0" / "1" }` | `src/codegen/erlang.zig:943`, `:979`, `:980`, `:1980`, `:3163`, `:3292` | `Term.int` already exists (`:3017` uses it) |
| The `$stringify(…)` wrapper written as template text | `src/codegen/erlang.zig:1583-1588` (`emitStringifyOpen` / `emitStringifyClose`) — the only two `writeAll` calls left in the file | It is the compiler's own `iolist_to_binary(io_lib:format("~p", [ … ]))`, not host text; build it as the `call` node `formatNode` (`:3592`) already produces, so the template `raw` at `:1566` carries host text only |

## Acceptance for the whole inventory

- [ ] 0 `Ast.Expr.r("")` in a value position (the 7 missing-value sites)
- [ ] 0 `Ast.Expr.r("")` as an unreachable fallback (the 4 sites return an error or assert)
- [ ] `headCall` is gone; its 11 callers build `.call` or `.apply`
- [ ] `rg 'Expr\.r\(' src/codegen/erlang.zig` returns **1**, and `src/codegen/beam/AGENTS.md`
      documents why that one stays
- [ ] 0 writer calls in `src/codegen/erlang.zig`
- [ ] Erlang and beam snapshots byte-identical for every step in this file except the missing-value
      class, whose whole point is that the output changes
