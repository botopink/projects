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

### D1 — `Term` + 2 emitters em `codegen/beam/`

```
                   codegen/beam/term.zig
                     /                \
 codegen/beam/erl_emitter.zig     codegen/beam/beam_emitter.zig
 Term + nomes → fonte Erlang      Term → operandos .S ({literal, …} via erl_emitter)
```

- Emitters escrevem em `*std.Io.Writer`.
- Duas entradas de binário: `writeBinaryFromBytes` (dados de runtime: handle, valores
  comptime) e `writeBinaryFromLexeme` (literais do lexer).
- A migração dos codegens é byte-idêntica, exceto snapshots que antes geravam código
  inválido (átomos reservados/maiúsculos sem quote no `.S`).

### D2 — Eval pelo codegen real

O `codegen/erlang.zig` já lowera `ast.Program` não tipado com tudo que os corpos usam
(`if` → `case`, `decl.kind` → `maps:get`, `DeclKind.Record` → `'Record'`,
`decl.fail(m)` → `fail(Decl, M)`, `forEach` com `var` → `lists:foldl`).

```
FnDecl (decorator/template)
  → ast.Program{ decls = [fn] }
  → erlang.emitComptimeModule(program, .{ host_enums, exports = main/0, tail = host fns + main/0 })
      main/0 usa erl_emitter para o handle @Decl / captures (Term)
  → .erl único por avaliação → persistent_erl.evalDetailed → {kind, …} → Outcome
```

Modo comptime (corpo sem tipos): `+` → `'__bp_add'/2`, `.len`/`.length` → `'__bp_len'/2`.

---

## Fases

| Fase | Escopo | Estado |
|---|---|---|
| F0 | Housekeeping: `src/` acidental do meta, `.snap.md.new` commitados, `std.debug.print` em `decorator_eval.zig`/`infer.zig` | parcial (`src/` removido) |
| F1 | `term.zig`, `erl_emitter.zig`, `beam_emitter.zig`; `erlang.zig`/`beam_asm.zig` migrados; `handleToTerm` | feito |
| F2 | `emitComptimeModule` + modo `untyped` + versionamento de variáveis (`Count@1`); `persistent_erl`: `readExact`, `evalDetailed`, timeout de `main/0`, `halt()` + stderr em log (fim dos travamentos) | implementado |
| F3 | Decorators sobre `emitComptimeModule` (ver abaixo) | pendente |
| F4 | Templates sobre `emitComptimeModule` | pendente |
| F5 | `runtime/beam.zig` sem ida ao `erl` | pendente (não bloqueia verde) |
| F6 | Suíte verde | pendente |
| F7 | `AGENTS.md` do submódulo, `architecture.md`, esta spec; commit + bump | pendente |

### F3 — Decorators (`comptime/decorator_eval.zig`)

- `buildErlModule` sobre `emitComptimeModule`: program `[dfn]`, `host_enums = {"DeclKind"}`,
  `tail` = `fail/2`, `failAt/3`, `compilerError/1`, `emit/1` + `main/0`.
- `main/0` chama o decorator com `handleToTerm(handle)` e os plain args como `Term`
  (parâmetro sem arg → `undefined`); captura `throw:{comptime_fail, Msg, Span}` e `error:Reason`.
- Apagar `emitExpr`/`emitStmt`/`emitBody`/`emitDeclHandle`.
- Plain args (`PlainArg.jsValue`, lexema bp) → `Term`: string → binary, número → integer/float,
  bool → boolean; resto → erro claro.
- Nome de módulo/arquivo único por avaliação (hash do Erlang gerado, não do nome da fn).
- `parseOutcome` com struct no formato `{kind, contributions|message|span}`; `failAt` → `Outcome.fail.span`.
- Mensagem de erro de compilação/runtime do `erl` propagada para o `TypeError` em `infer.zig`.

### F4 — Templates (`comptime/template_eval.zig`)

- `evaluateErl` sobre `emitComptimeModule`; apagar `emitBpBody` e o decompilador.
- Host fns (`q.build`, `q.text`, `q.parts`, `q.lookup`, `q.bindings`, `q.fail`, `q.custom`,
  `@expr`, `makeExpr`, `makeCode`) no `tail`/prelude.
- Captures (`template.CapturedExpr`) → `Term` no `main/0`.
- `parseOutcome` no formato `{kind, …}`; valores JSON crus → `TypedValue`.
- Hint de erro sem menção a "node runtime".

### F5 — `comptime/runtime/beam.zig`

`renderExprValue` já calcula tudo em Zig. Gravar o valor direto no mapa `id → literal` e
apagar `buildScript`, `parseResults`, cache `beam_cache/`, `persistent_erl.loadBeam` e o cmd 2
do servidor; ajustar snapshots com seção `COMPTIME ERLANG`.

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

Os testes de *rejeição* de decorator passam hoje com o avaliador quebrado — confirmar no F3
que passam pelo motivo certo.

## Aceitação

- [ ] `decorator_invocation` 11/11 e `decorator_regression` 4/4
- [ ] `templates`, `sublanguage` e `completion` sem falhas
- [ ] Snapshots de codegen (5): diff do RUN LOG revisado e aceito
- [ ] Nenhum leak novo (os 13 de codegen são do Step 2)

## Notas de build

- `zig build test -- --test-filter` não funciona no Zig 0.16; rodar o binário
  `.zig-cache/o/<hash>/test` direto.
- Não usar `pkill -f botopink_comptime_server` no mesmo comando do teste (casa com a
  própria linha de comando); matar `beam.smp` por PID.
