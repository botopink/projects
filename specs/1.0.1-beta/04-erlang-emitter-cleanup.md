# Spec 04 — Erlang emitter cleanup

**Version:** 1.0.1-beta
**Priority:** low — optional refactors
**Depends on:** spec 01 (clean baseline for the byte-identical gate)

---

## Objective

Finish the optional parts of the `Term` / `erl_ast` migration so `codegen/erlang.zig` builds
every Erlang construct as a node or term, with no ad-hoc text or per-call allocation left.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/codegen/`.

## Current state

- `beam/term.zig` (`Term`) and `beam/erl_ast.zig` (`Expr`/`Clause`/`Body`/`Function`/`Form` +
  `Builder`) are rendered by `beam/erl_emitter.zig`; `beam/beam_emitter.zig` renders `Term` as
  `.S` operands.
- `erlang.zig` only builds nodes and forms. `raw` remains for host template text, names written
  as in the source (record literal keys, variant tags, `dotIdent`) and `%%` comments in place of
  unsupported constructs.

## Rule

Erlang and beam snapshots stay **byte-identical** at every step.

---

## Steps

| Step | What | Acceptance |
|---|---|---|
| 1 | Template `$stringify` as an `erl_ast` node instead of `raw` text | no `raw` for `$stringify`; snapshots identical |
| 2 | Constant map/list/tuple literals in `erlang.zig` built as `Term` and rendered with `writeTerm` | literals go through `Term`; snapshots identical |
| 3 | `erlangVar` (33 call sites, each allocates) → `writeVar` straight into the writer / a non-allocating node | no `erlangVar` allocation per call; snapshots identical |
| 4 | Review the remaining `raw` uses; turn each into a node where `erl_ast` can express it, or document why it stays | every remaining `raw` has a reason in `codegen/beam/AGENTS.md` |

Update `codegen/AGENTS.md` and `codegen/beam/AGENTS.md` in the same commit as each step.
