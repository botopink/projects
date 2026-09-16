# Spec 04 — Emitter Centralization

**Version:** 1.0.1-beta
**Status:** delivered
**Carried forward:** [`../1.0.2-beta/04-emitter-centralization.md`](../1.0.2-beta/04-emitter-centralization.md)

---

## Objective

Give every backend the split the Erlang side already had: **the backend builds a model, an
emitter renders it**. A backend that writes target text by hand owns nothing — no type can
refuse an illegal shape, and every defect is a text defect discovered by running the output.
After this milestone no backend prints target syntax, and the shapes the lowering still gets
wrong are *named* nodes rather than accidental strings.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/codegen/`.

## The rule that made it safe

Each refactor is a pure refactor: the snapshots stay **byte-identical**. A step that changed
a snapshot had hit a bug, and that part moved to spec 03 instead. All three refactors below
landed byte-identical.

## What changed

### beam — `beam/beam_emitter.zig`

`beam_asm.zig` no longer prints `.S` syntax. It builds typed operands (`Op` / `Dst` =
`beamEmitter.Operand` / `Dest`) and calls one `beam_emitter.write*` function per `.S` line —
494 call sites. The emitter owns atom quoting, operand shape, indentation and the trailing
`.`, and grew a typed instruction vocabulary for it (`writeMove`, `writeTest`,
`writeTestHeap`, `writeGcBif`, `writeCall`, `writeCallFun`, `writeMakeFun3`, `writePutList`,
`writePutTuple2`, `writeGetTupleElement`, `writeGetList`, `writeGetMapElements`,
`writePutMap`, `writeAllocate` / `writeDeallocate` / `writeInitYregs`, `writeLabel`,
`writeFunctionHeader`, `writeFuncInfo`, `writeLine`, the comment forms). A missing
instruction is added to the vocabulary, never printed at the call site. The single verbatim
passthrough is a `#[@External.Beam]` template body.

### wasm — `wat/` (new)

| File | Role |
|---|---|
| `wat/wat_ast.zig` | The code model (`ValType`, `Stack`, `Instr`, `Line`, `Seq`, `Param`, `Local`, `Func`, `Global`, `Import`, `Memory`, `DataSegment`, `Item`, `Module`) plus `validateFunc` / `validateModule` / `declaresCall` and `Builder`. |
| `wat/wat_emitter.zig` | The only writer of `.wat`: s-expressions, the item/body columns, `$`-prefixing, folded vs flat form, inline `if` arms, `offset=` suppression, data-segment escaping. |
| `wat/wat_prelude.zig` | The runtime helpers wasm has no opcode for (`$__print_i32`, `$__print_str`, `$__print_bool`, `$__print_f64`, `$__str_concat`, `$__str_eq`, `$__str_slice`, `$__arr_at`, `$__memmove`) as built `Func` nodes, with the scratch layout they assume. |

`wat.zig` went from 382 writer sites to **0**. The model is what now makes the five defects
the previous wave had to repair unrepresentable: there is no local-declaration instruction
(locals are `Func.locals`), every `Seq` carries the `Stack` it leaves and `Builder.func`
refuses a body that disagrees with the declared `(result …)`, `Builder.param` refuses an
unnamed parameter, `validateModule` walks every `call` against the module's functions,
imports and declared externs before a byte is written, and `Builder.helper` is the only way
to obtain a runtime helper's symbol — "called" and "defined" are one operation. There is
deliberately **no** raw-text instruction: an unlowerable construct emits an honest
`Instr.comment`.

### JavaScript / TypeScript — `js/` (new)

| File | Role |
|---|---|
| `js/js_ast.zig` | `Expr` / `Stmt` / `Pattern` / `Param` / `Block` / `Class` / `Item`, the `.d.ts` subset `TsType` / `TsField` / `TsParam` / `TsMember` / `TsDecl`, and `Builder`. |
| `js/js_emitter.zig` | The only writer of JavaScript: the ES reserved-word rename (`delete` → `delete_`, never in property position), lexeme-string escaping, `writeExpr` / `writeStmt` / `writeBlock` / `writePattern` / `writeProgram`. |
| `js/ts_emitter.zig` | The only writer of `.d.ts`. |

`commonJS.zig` and `typescript.zig` were migrated onto it and write no target text. The
model carries the invariants the old string building could not: `Expr` and `Stmt` are
different types (no `return for (…)` by accident), a rest element is a *field* of the
pattern rather than an element of its list, an `if` carries an `Expr` condition, a `.d.ts`
parameter carries a `TsType` rather than a possibly-empty string, and layout is part of the
model wherever the emitted bytes depend on it (`Block.Layout`, `Array.Layout`,
`Object.Layout` — the same rule `beam/erl_ast.zig` follows).

### The bridges

Where the lowering still produces a shape the model would otherwise forbid, the model
carries a **named** node for it instead of letting the backend spell it out. Six of them
exist on the JS side (`js/AGENTS.md`, JS-1…JS-6), one on the wat side (`Module.externs`),
and the Erlang side keeps `Ast.Expr.r` for genuine host text. Each has to be named explicitly
at the build site, so a grep finds every one, and fixing a defect means deleting its build
site rather than its node. `Expr.host` (JS) and the `#[@External.Erlang]` / `#[@External.Beam]`
template text are **not** bridges: they carry host code by definition.

The remaining bridges are the inventory
[`1.0.2-beta/04-emitter-centralization.md`](../1.0.2-beta/04-emitter-centralization.md)
works through.

### Erlang emitter leftovers closed in this milestone

The variant-pattern, array-spread, `dotIdent` and bare-`break` `raw` rows were output bugs,
and were fixed in spec 03 — which removed them from `erlang.zig`. `Ast.Expr.r(` went from 17
uses to 13, and the remaining ones are host template text, pre-spelled call heads, and the
missing-value / unreachable fallbacks that spec 04 in 1.0.2-beta still owns.

## How it is verified today

- `zig build test` is green from `repository/botopink-lang/`, with the codegen snapshots
  byte-compared across all four targets.
- No `print` / `writeAll` of target syntax outside the emitters:
  `wat.zig`, `commonJS.zig`, `typescript.zig` and `erlang.zig` have **0** writer calls;
  `beam_asm.zig` has **9**, all in the `.S` module preamble (`emitBeamAsm`, `:603-617`).
- `Ast.Expr.r(` in `erlang.zig`: **13** uses.
- Each emitter's rules are pinned in its own `AGENTS.md`
  ([`beam/AGENTS.md`](../../repository/botopink-lang/modules/compiler-core/src/codegen/beam/AGENTS.md),
  [`wat/AGENTS.md`](../../repository/botopink-lang/modules/compiler-core/src/codegen/wat/AGENTS.md),
  [`js/AGENTS.md`](../../repository/botopink-lang/modules/compiler-core/src/codegen/js/AGENTS.md)),
  and the emitters carry inline unit tests aggregated by `codegen/tests.zig`.
