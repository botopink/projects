# AST & Parser Simplification

**Branch**: `feat/ast-simplification`
**Depends on**: nothing — but **do NOT parallelize** with other branches
**Status**: done (all 7 phases implemented & tested)

> ⚠️ Touches almost every AST consumer (`format.zig`, `infer.zig`, `transform.zig`,
> `beam_asm.zig`, `wat.zig`, `erlang.zig`, `typescript.zig`, `print.zig`). High merge-conflict
> risk. Run it **alone**, on a clean base, **before** opening the other branches **or**
> after they are all merged. Never in parallel.

**Files**: `ast.zig` (~1360 lines), `parser.zig` (~3630 lines)

## Steps

### Phase 1 — construction helpers (parser.zig only)
1. Replace 27 `alloc.create(Expr); ptr.* = expr` with `boxExpr()`
2. `makeBinOp(alloc, op, opTok, lhs, rhs)`
3. `makeCall(tok, receiver, callee, is_builtin, args, trailing)` — 11 sites
4. `makeJump(tok, comptime variant, inner)` — unifies return/throw/try/break/yield
5. `tryParseCommentStmt(alloc)` — extract the duplicated pattern (3-4 occurrences)

### Phase 2 — unify block parsing (parser.zig only)
6. `BlockParseOptions { trackEmptyLines, handleComments, semicolonPolicy }`
7. `parseBlock(alloc, opts)` unifying the 5 methods
8. Keep `parseBlockOrExpr` as a thin wrapper; remove the 5 old ones

### Phase 3 — unify binary operators (parser.zig only)
9. `precedence_table` (level → tokens + op enum)
10. recursive `parseBinaryExpr(alloc, comptime level)`
11. Remove `parseOrExpr`/`parseAndExpr`/`parseEqExpr`/`parseCompareExpr`/`parseAddExpr`/`parseMulExpr`

### Phase 4 — flatten AST (ast.zig + consumers)
12. Flatten `BinOpExprOf`/`UnaryOpExprOf`/`LoopExprOf` (fields directly on the struct)
13. Migrate consumers (search-and-replace) + update `deinit`

### Phase 5 — merge lambda/fnExpr (ast.zig + consumers)
14. `FunctionExprOf` → struct `{ syntax: enum { lambda, fnExpr }, params, body }`

### Phase 6 — unify declaration preamble (parser.zig only)
15. `DeclPreamble` + `parseDeclPreamble` for the 10 decl methods

### Phase 7 (optional) — merge pattern variants
16. `variantBinding`/`variantFields`/`variantLiterals` → `variant` with payload union (14 sites)

## Verification
After each phase: `zig build test`. The Zig compiler guarantees any access to a removed field fails to compile.