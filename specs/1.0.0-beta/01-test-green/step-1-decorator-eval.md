# Step 1 — Comptime eval no erl (decorators + templates)

**Prioridade:** 🔴 CRÍTICO
**Branch:** `fix/step-1-decorator-eval` (meta + `repository/botopink-lang`)
**Checklist vivo:** [`todo.md`](../../../todo.md)

---

## Objetivo

1. Um modelo de termo único (`Term`) com dois emitters — fonte Erlang e BEAM asm —
   usado por `codegen/erlang.zig`, `codegen/beam_asm.zig` e pelo comptime.
2. Decorators e templates avaliados no `erl` persistente gerando Erlang válido pelo
   codegen real (`codegen/erlang.zig` `emitComptimeModule`), sem emitter manual nem
   decompilador para botopink.
3. `zig build test` sem as falhas de decorator/template/sublanguage/completion.

## Problema

- `decorator_eval.zig` traduz o corpo do decorator com um emitter à mão
  (`emitExpr`/`emitStmt`) que não cobre `if`, métodos, enums, lambdas nem `+` de string:
  sai `Decl() -> _ = #{…}`, corpo `undefined`, e nenhum módulo compila.
- `template_eval.zig` decompila o corpo para botopink sintético e roda `compile()` →
  `parse failed for module 'template_body'`. Afeta `templates` e os testes `sublanguage`
  do language server (erika `@ExprCustom`).
- O parse de resultado (`std.json.Value` manual em decorators; `union(enum)` do `std.json`
  em templates) não bate com o formato `{kind, …}` que o Erlang devolve.

---

## Arquitetura

### D1 — `Term` + `erl_ast` + 2 emitters em `codegen/beam/`

```
 codegen/beam/term.zig      Term — valores
 codegen/beam/erl_ast.zig   código Erlang (Expr/Clause/Body/Function/Form + Builder)
        │                         │
 erl_emitter.zig            beam_emitter.zig
 Term + erl_ast → fonte     Term → operandos .S ({literal, …} via erl_emitter)
```

- Emitters escrevem em `*std.Io.Writer`.
- Duas entradas de binário: `writeBinaryFromBytes` (dados de runtime: handle, valores
  comptime) e `writeBinaryFromLexeme` (literais do lexer).
- `codegen/erlang.zig` monta nós e formas `erl_ast` (corpos, expressões, chamadas,
  declarações, cabeçalho, runner de testes); só o `erl_emitter` escreve texto.
- A migração dos codegens é byte-idêntica, exceto snapshots que antes geravam código
  inválido (átomos reservados/maiúsculos sem quote no `.S`).

### D2 — Eval pelo codegen real

```
FnDecl (decorator/template)
  → ast.Program{ decls = [fn] }
  → erlang.emitComptimeModule(program, .{ host_enums, host_records, exports = main/0, forms = host fns + main/0 })
      handle @Decl / captures como Term
  → .erl único por avaliação (nome = hash do código) → persistent_erl.evalDetailed → JSON {kind, …} → Outcome
```

Modo comptime (corpo sem tipos): `+` → `'__bp_add'/2`, `.len`/`.length` → `'__bp_len'/2`.

### D3 — Valores `comptime` em Zig

`val x = comptime …` é dobrado em `comptime/eval.zig`, sem `erl`. Snapshots mostram
`COMPTIME VALUES` (`ct_N = literal`).

---

## Fases

| Fase | Escopo | Estado |
|---|---|---|
| F0 | Housekeeping (`src/` acidental do meta, `.snap.md.new` commitados, prints de debug) | parcial (`.snap.md.new` beam versionados; `.qwen/` removido; `test_pub.zig`, `.env` aguardam decisão) |
| F1 | `term.zig`, `erl_emitter.zig`, `beam_emitter.zig`; `erlang.zig`/`beam_asm.zig` migrados; `handleToTerm` | feito |
| F2 | `emitComptimeModule` + modo `untyped` + versionamento de variáveis; `persistent_erl` robusto (`readExact`, `evalDetailed`, timeout, `halt()`, stderr em log) | feito |
| F3 | Decorators sobre `emitComptimeModule` | feito (menor: loc do `TypeError`, span do `failAt`) |
| F4 | Templates sobre `emitComptimeModule`; runtime morto removido | feito |
| F5 | Valores `comptime` sem ida ao `erl` | feito |
| F6 | Suíte verde | feito: 1571/1571 (13 leaks do step-2); 4 RUN LOGs beam errados aceitos como baseline (spec 03); testes do lexer registrados |
| F7 | Docs (`AGENTS.md`, `architecture.md`, esta spec); commits | feito (push/merge aguardam pedido) |
| F8 | `erl_ast` + emitter: `erlang.zig` sem escrita de texto | feito |
| F9 | Revisão final de todos os snapshots alterados/criados | feito (bugs conhecidos anotados no `todo.md`) |

---

## Testes → requisitos

| Teste | Precisa de |
|---|---|
| body accepts a record / rejects wrong placement | `if`, `!=`, átomo `DeclKind.*`, `decl.fail` |
| method placement / method rejects a record | plain arg string → `Term`, handle `Method` |
| body reads the reflected name | `==` de binário |
| `@compilerError` accepts / rejects | host `compilerError/1` |
| `@emit` contributes / body references `@emit`'d decl | host `emit/1`, contribuições no outcome |
| interface-level marker | handle `Interface` |
| mock-style synthesis | `forEach` + fold de `var`, `'__bp_add'`, 2× `@emit` |
| regression: loop in body | `forEach` sem acumulador + `fail` em lambda |
| regression: conditional | `if` aninhado, `decl.fields.len` (`'__bp_len'`) |
| regression: string concat | religação `msg = msg + …` |
| regression: `@emit` in body | `'__bp_add'` dentro de `@emit` |

Os testes de *rejeição* de decorator comparam a mensagem do `TypeError` (não só o fato de rejeitar).

## Aceitação

- [x] `decorator_invocation` 11/11 e `decorator_regression` 4/4
- [x] `templates`, `sublanguage` e `completion` sem falhas
- [x] Snapshots de codegen beam (5): diff do RUN LOG revisado e aceito
- [x] Nenhum leak novo (os 13 de codegen são do Step 2)

## Notas de build

- `zig build test -- --test-filter` não funciona no Zig 0.16; rodar o binário
  `.zig-cache/o/<hash>/test` direto.
- Não usar `pkill -f botopink_comptime_server` no mesmo comando do teste (casa com a
  própria linha de comando); matar `beam.smp` por PID.
