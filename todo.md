# TODO — Step 1: comptime eval (decorators + templates) no erl

**Branch:** `fix/step-1-decorator-eval` (meta + submódulo `botopink-lang`)
**Prioridade:** 🔴 CRÍTICO

**Objetivo:**
1. Modelo de termo único (`Term`) com `erl_emitter` (fonte Erlang) e `beam_emitter` (BEAM asm `.S`),
   usado por `codegen/erlang.zig`, `codegen/beam_asm.zig` e pelo comptime.
2. Decorators e templates avaliados no `erl` persistente, gerando Erlang válido pelo codegen real.
3. `zig build test` verde.

---

## Estado atual

`zig build` ✅ · `zig build test`: **1390/1421 ok · 31 falhas · 13 leaks · ~17s · sem travamentos**

| Grupo | Falhas | Causa |
|---|---|---|
| `comptime.tests.decorator_invocation` | 6 | `decorator_eval` ainda usa emitter Erlang à mão → módulo não compila |
| `comptime.tests.decorator_regression` | 2 | idem |
| `comptime.tests.templates` | 9 | `template_eval.evaluateErl` gera bp sintético → `compile()` → `parse failed for module 'template_body'` |
| `tests.sublanguage` (LSP) | 8 | idem templates (erika `@ExprCustom`) |
| `tests.completion` | 1 | decorator falha → record com decorator perde bindings |
| `codegen` beam snapshots | 5 | RUN LOG passou a ter saída (`<<"started">>`, `[<<"a">>,…]`) que o `.snap.md` não tem |
| leaks | 13 | todos de `codegen/runtime.zig` `executeErlang`: saída do `erlc` (`compile_out`/`aux_out`) não liberada no retorno antecipado — escopo do step-2 |

⚠️ Os testes de *rejeição* de decorator passam por engano: `assertRejects` procura a mensagem no erro renderizado, que inclui
o código-fonte inteiro (onde a mensagem já aparece) — p.ex. `regression: loop/conditional`. Corrigir o helper no F6.

---

## Arquitetura

### Termos BEAM — `modules/compiler-core/src/codegen/beam/`

```
                    term.zig  (Term)
                   /                \
        erl_emitter.zig          beam_emitter.zig
        Term → fonte Erlang      Term → operando .S ({atom,…}/{integer,…}/nil/{literal, <term>})
        + atom/var/binary        (reusa erl_emitter p/ o conteúdo de {literal, …})
         ↑           ↑                 ↑
   erlang.zig   decorator_eval    beam_asm.zig
```

Regra única de atom (reservadas e não-minúsculas quotadas) nos dois backends. Binário a partir de bytes
crus (`writeBinaryFromBytes`) ou de lexema do parser (`writeBinaryFromLexeme`).

### Comptime eval pelo codegen real

```
FnDecl do decorator/template
  → ast.Program{ decls = [fn] }
  → erlang.emitComptimeModule(program, .{ host_enums, exports = main/0, tail = host fns + main/0 })
      (flag untyped: `+` → '__bp_add'/2, `.len`/`.length` → '__bp_len'/2)
      handle @Decl / args / captures como Term via erl_emitter
  → .erl único por avaliação → persistent_erl.evalDetailed → {kind,…} → Outcome
```

`codegen/erlang.zig` já lowera sobre AST não tipado: `if` → `case`, `decl.kind` → `maps:get`,
`DeclKind.Record` → `'Record'` (host enum), `decl.fail(m)` → `fail(Decl, M)`, `@emit`/`@compilerError`
→ `emit/1`/`compilerError/1`, `forEach` com `var` mutada → `lists:foldl`, reatribuição → `Msg@1`.

---

## Feito

- **F1** (submódulo `7dbb6f1`): `codegen/beam/{term,erl_emitter,beam_emitter}.zig`; `erlang.zig` e `beam_asm.zig`
  migrados (snapshots erlang idênticos; 3 snapshots beam corrigidos — `{atom, end}`, `{function, HOST, …}` não montavam);
  `decorator_eval.handleToTerm`; `comptime/erl_emitter.zig` removido.
- **F2** (não commitado): `emitComptimeModule` + flag `untyped` (`'__bp_add'`, `'__bp_len'`); versionamento de
  variável no codegen erlang (`Count@1`, 5 snapshots corrigidos); `tests/comptime_module.zig`;
  `persistent_erl`: `readExact`, `evalDetailed`/`Response`, timeout de 10s no `main/0`, `write_frame` robusto,
  kill do filho em falha de transporte, `halt()` no EOF + stderr em `.botopinkbuild/tmp/persistent_erl/erl.stderr.log`
  (causa dos 2 binários travados: `beam.smp` órfão segurando o stderr do test runner).
- **F0 parcial:** `.snap.md.new` commitados removidos; `src/` duplicado do meta removido.

---

## Pendente

### F0 — Housekeeping
- [ ] Remover `std.debug.print` de `decorator_eval.zig` e `infer.zig` (`calling decoratorEval.evaluate…`) — erro vai no `Outcome`
- [ ] `.qwen/`, `test_pub.zig`, `.env` vazio no meta — confirmar com Eric se são intencionais

### F3 — Decorators (`comptime/decorator_eval.zig`)
- [ ] Reescrever `buildErlModule` sobre `erlang.emitComptimeModule`:
  - program = `[dfn]`; `host_enums = &.{"DeclKind"}`; export `main/0`
  - `tail` = host fns (`fail/2`, `failAt/3`, `compilerError/1`, `emit/1`, `emit_stack/0`) + `main/0`
  - `main/0` chama `<decorator>(<handle Term>, <plain args Term>)`; aridade = `dfn.params.len`, parâmetro sem arg → `undefined`
  - `main/0` captura `throw:{comptime_fail, Msg, Span}` e `error:Reason` → `{kind:"error", message}`
- [ ] Apagar `emitExpr`/`emitStmt`/`emitBody` manuais
- [ ] `handleToTerm`: `methods[].params`, `returnType`, `annotations[].args` coerentes com `builtins.d.bp`; `Interface` usa `fld.typeName`
- [ ] Plain args: `PlainArg.jsValue` é lexema bp → `Term` (string/número/bool; resto → erro claro); renomear campo p/ `source`
- [ ] Nome de módulo/arquivo único por avaliação (hash do Erlang gerado; hoje `hash(dfn.name)` → corrida em paralelo)
- [ ] Usar `evalDetailed`: `compile_error`/`runtime_error` viram `Outcome.err` com a mensagem
- [ ] `parseOutcome` com struct no formato do `main/0` (`{kind, contributions|message|span}`); não liberar `stdout` antes de usar os slices
- [ ] `failAt` → `Outcome.fail.span`
- [ ] `infer.zig`: mensagem do `Outcome.err` no `TypeError` (hint atual "check that `erl` is available" é enganoso)

### F4 — Templates (`comptime/template_eval.zig`)
- [ ] Migrar `evaluateErl` p/ `emitComptimeModule`; apagar `emitBpBody` (decompilador bp)
- [ ] Host fns de template no tail/prelude: `q.build`, `q.text`, `q.parts`, `q.lookup`, `q.bindings`, `q.fail`,
      `q.custom`, `@expr`, `makeExpr`, `makeCode` (`#[@Host]` em `template_runtime.bp` + `erl_prelude.zig`)
- [ ] Captures (`template.CapturedExpr`) → `Term` no `main/0`
- [ ] `parseOutcome`: `union(enum)` do `std.json` espera `{"code":{…}}`, não `{"kind":"code",…}` — trocar por struct plana
      com `kind` + campos opcionais, ou walk de `std.json.Value`; `TypedValue` não aceita JSON cru (`42`, `{…}`)
- [ ] Avaliar `TypedValue` = `Term`
- [ ] Hint de erro fala "node runtime" → erl
- [ ] Remover `literalFromJson` (`infer.zig`) se não restar uso

### F5 — BEAM comptime (`comptime/runtime/beam.zig`) — remover a ida ao `erl`
`renderExprValue` já calcula tudo no Zig e grava o JSON como string fixa em `main() -> "…"`; o `erl` só devolve
a string e `parseResults` re-parseia o que o Zig gerou.
- [ ] `renderExprValue` → literal direto no mapa `id → literal`, sem script
- [ ] Apagar `buildScript`, `parseResults`, cache `beam_cache/`, `persistent_erl.loadBeam` e o cmd=2 do servidor
- [ ] Ajustar snapshots com seção `COMPTIME ERLANG`
- [ ] Não bloqueia teste verde

### F6 — Suíte verde
- [ ] `decorator_invocation` 11/11 · `decorator_regression` 4/4
- [ ] `templates` 9 → 0 · `sublanguage` 8 → 0 · `completion` 1 → 0
- [ ] Beam snapshots (5): revisar o RUN LOG novo e aceitar
- [ ] Verificar RUN LOG dos 3 snapshots beam corrigidos no F1 (antes o `.S` nem montava)
- [ ] `assertRejects` (decorator_invocation/regression): comparar só a mensagem do erro, não o render com fonte
- [ ] Rodar baseline na `feat` p/ separar regressão desta branch de falha pré-existente
- [ ] Leaks de codegen (13) → step-2; garantir que F3–F5 não adicionam novos
- [ ] **Testes do lexer não rodam:** `src/lexer/tests.zig` é só `test {}` — os 7 arquivos de `lexer/tests/` (~1,2k linhas) nunca compilam; re-registrar e corrigir o que quebrar (pode ir p/ step-3)

### F7 — Fechamento
- [ ] `comptime/AGENTS.md` com o fluxo final (sem decompilador bp)
- [ ] Spec `specs/1.0.0-beta/01-test-green/step-1-decorator-eval.md` alinhada
- [ ] Commit submódulo → bump no meta (sem `--no-verify`)
- [ ] Sweep das `feat` remotas (meta + submódulos)

### Opcionais (F1)
- [ ] Literais constantes de map/list/tuple do `erlang.zig` → `Term` + `writeTerm`
- [ ] `erlangVar` (33 chamadas, alocam) → `writeVar` direto no writer

---

## Testes → requisitos

| Teste | Precisa de |
|---|---|
| body accepts a record / rejects wrong placement | `if`, `!=`, `DeclKind.*` atom, `decl.fail` |
| method placement / method rejects a record | plain arg string (`"/users"`) → `Term`, handle `Method` |
| body reads the reflected name | `==` binário |
| `@compilerError` accepts / rejects | host `compilerError/1` |
| `@emit` contributes / body references `@emit`'d decl | host `emit/1`, contribuições no outcome |
| interface-level marker | handle `Interface` |
| mock-style synthesis | `forEach` + `var` fold, `'__bp_add'`, 2× `@emit` |
| regression: loop in body | `forEach` sem acumulador + `fail` dentro de lambda |
| regression: conditional | `if` aninhado, `decl.fields.len` (`'__bp_len'`) |
| regression: string concat | `msg = msg + …` → `Msg@1` |
| regression: `@emit` in body | `'__bp_add'` dentro de `@emit` |

---

## Notas de build

- `zig build test` roda em ~17s; rodar em background com log em arquivo.
- `zig build test -- --test-filter` não funciona no Zig 0.16; p/ um binário só, rodar `.zig-cache/o/<hash>/test`
  (o hash aparece em `failed command:` no log).
- `zig build test --test-timeout 20s` nomeia o teste que estoura; "test runner failed to respond" = nada rodando
  (ex.: processo filho segurando stdio do runner).
- Iteração rápida sem suíte: `zig-out/bin/botopink build --target erlang --out out` num projeto de scratch.
- Não usar `pkill -f <padrão>` no mesmo comando que contém o padrão — mata o próprio shell.
