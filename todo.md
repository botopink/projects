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

`zig build` ✅ · `zig build test`: **1571/1571 ok · 13 leaks · ~17s · sem travamentos**

| Grupo | Qtd | Causa |
|---|---|---|
| leaks | 13 | todos de `codegen/runtime.zig` `executeErlang`: saída do `erlc` (`compile_out`/`aux_out`) não liberada no retorno antecipado — escopo do step-2 |
| beam RUN LOG errado | 4 | aceitos como baseline, bugs do backend beam na spec 03 (ver F6) |

Decorators (`decorator_invocation` 12/12 · `decorator_regression` 4/4), templates (`templates` 9/9),
`sublanguage` e `completion` ✅. language-server 100% verde.

---|---|---|
| `codegen` beam snapshots | 5 | RUN LOG passou a ter saída (`<<"started">>`, `[<<"a">>,…]`) que o `.snap.md` não tem |
| leaks | 13 | todos de `codegen/runtime.zig` `executeErlang`: saída do `erlc` (`compile_out`/`aux_out`) não liberada no retorno antecipado — escopo do step-2 |

Decorators (`decorator_invocation` 11/11 · `decorator_regression` 4/4), templates (`templates` 9/9),
`sublanguage` e `completion` ✅. language-server 100% verde.

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
- **F3** (não commitado): `decorator_eval` sobre `emitComptimeModule` (host glue `fail`/`failAt`/`compilerError`/`emit` + `main/0`
  com handle `Term` e args), módulo/arquivo por hash do código, `evalDetailed` → `Outcome.err` com o diagnóstico Erlang,
  `parseOutcome` com struct plana, sem `std.debug.print`; testes inline. `assertRejects` passou a comparar só a mensagem do
  erro (antes casava com o fonte citado no render). Resultado: 31 → 22 falhas.
- **F4** (submódulo `009b093`): `template_eval` sobre `emitComptimeModule` — capture como `Term` (`captureToTerm`: text/parts com
  placeholders de hole/source/context/bindings), host fns (`text`, `parts`, `lookup`, `build`, `custom`, `fail`, `failAt`,
  `expr`, `code`…), `main/0` com reply por forma do resultado, `parseOutcome` com struct plana + `std.json.Value` →
  `TypedValue`/`CustomNodeTree` (`ref` com name+kind); decompilador `emitBpBody` removido; `PlainArg.writeErl` compartilhado
  com decorators. Codegen erlang: `host_records` no `ComptimeModule` e **mutação em `if`/`loop`/`forEach` retornando os
  valores** (`Acc@1 = case … end`, `lists:foldl`). Snapshots: `comptime_partial…` (loop de `COMMANDS`), 12 de
  `template_end_to_end_*` (node/erlang/beam/wasm, antes vazios/truncados), `lsp/sublanguage_semantic_tokens` (agora pinta
  keyword/property dentro da string). Resultado: 22 → 5 falhas.
- **F4b** (não commitado): removidos o warmup morto (`warmPersistentErlRunner` + `patchHostMethods`, que compilavam
  `template_runtime.bp` → Erlang), `libs/std/src/template_runtime.bp` + `std_internal_files`, `runtime/erl_prelude.zig`
  (`botopink_comptime_prelude`), helpers WAT/JSON do `template.zig` (`readWatString`, `readCustomNodeFromMemory`,
  `parseCustomNode`, `appendJsonString`, `contextJsonAlloc`) e `literalFromJson`; `PlainArg.jsValue` → `source` (lexema
  botopink, sem escape JSON; `literalToJsAlloc` → `literalSourceAlloc`); teste de contexto reescrito sobre `captureToTerm`.
  Bugs do backend erlang vistos nos snapshots (`Cfg`, `COMMANDS`) registrados na spec 03.
- **F0 parcial:** `.snap.md.new` commitados removidos; `src/` duplicado do meta removido; docs de todo o projeto auditadas.

---

## Pendente

### F0 — Housekeeping
- [x] `.qwen/` removido (ok do Eric)
- [ ] `test_pub.zig` (importa `modules/core/src/parser.zig`, inexistente), `.env` vazio no meta — decisão do Eric

### F3 — Decorators — pendências menores
- [x] `TypeError` de decorator na loc da anotação (`ast.Annotation.loc`, fora do JSON do AST); `failAt` reporta na
      anotação (declaração não tem texto p/ mapear o span); `Span` virou host record do decorator; teste de loc

### F8 — Erlang AST + emitter (decisão do Eric: `erlang.zig` emite pelo emitter)
Regra: snapshots erlang **byte-idênticos** a cada etapa; `raw` é a ponte p/ o que ainda é texto.

- [x] **8.1** `codegen/beam/erl_ast.zig` (Expr/Clause/Body/Stmt/Function/Form + `Builder`) e renderer no
      `erl_emitter` (`writeExpr`/`writeBody`/`writeFunction`/`writeForm`) com as regras de layout do backend; testes
- [x] **8.2** código novo em nós: `ComptimeModule.forms` (sai o `tail` texto), `comptime_helper_forms`
      (`'__bp_add'`, `'__bp_len'`, `'__bp_text'`, `'__bp_json'`), host glue + `main/0` de `decorator_eval`/`template_eval`
      via `Builder`, `PlainArg.toExpr`; `emitMutatingIf`/`emitMutatingFold` montam `match`/`case_`/`fun` (corpos ainda `raw`)
- [x] **8.3** statements: `bodyNode` monta `Ast.Body` (`stmtExpr`: `return`/`bindExpr`/destructuring/comentários) e as
      lowerings de corpo viram nós (`propagateTryExpr`, `earlyReturnIfExpr`, `foldFusionExpr`, `mutatingExpr`);
      `bodyAsRawStmt` removido; expressões ainda entram como `raw` (`exprAsRaw`)
- [x] **8.4** `exprNode`: literal, identifier/identAccess (`maps:get`, `element/2`, `?.` como `fun` inline aplicado,
      length/`'__bp_len'`), binop/unop, lambda, grouped/array/tuple/range/record/interface, jumps, `if`/`tryCatch`, `loop`;
      `emitExprLegacy` só com `call`/`binding`/`useHook`/`comptime_` (+ `emitCase`) via `legacyAsRaw`
- [x] **8.5** `callNode` (pipeline, builtins/`@block`/`__bp_*` via `resultOptionNode`, receiver dispatch, user templates,
      externals, record ctor, locals), `primMethodNode`/`arrayPrimFallbackNode`, `bindingNode`, `comptimeNode`; templates de
      host viram `seq` (`templateNode`); `emitExprLegacy`/`legacyAsRaw`/`emitResultOptionOp`/`emitPattern`/`emitBind`/
      `emitBinaryOp` removidos; `erl_ast` ganhou `seq` e `case` inline
- [x] **8.6** `caseNode`/`caseBodyNode`/`patternNode`/`listPatElemNode` (padrões como `Ast.Expr`); `emitBranchBody` removido
- [x] **8.7** módulo como `[]Ast.Form` renderizado por `writeForms`: `module`/`no_auto_import` (`noAutoImportRefs`)/`exports`
      (`FnRef`; `ComptimeModule.exports` virou `[]FnRef`), `topValForms`/`fnForms`/`testFunction`/`recordForms`/`enumForms`/
      `interfaceForms`/`implementForms`/`extendForms`, wrapper `_botopink_main` e runner de testes (`testRunnerForms`) em nós;
      `erl_ast` ganhou `string`, `fun_ref`, `list_block` e `Form.blank`
- [x] **8.8** `Emitter` sem `out`/`w`/`fmt`/`writeIndent`/`emitExpr`/`emitBody`/`emitBinary`: `erlang.zig` só monta nós e
      formas, `erl_emitter` renderiza. `raw` sobra só p/ texto de template de host, nomes escritos como no fonte
      (chaves de record literal, tag de variante, `dotIdent`) e comentários `%%` no lugar de construções sem suporte
- [x] `beam_emitter` continua no `Term` (o `.S` é máquina de registradores, não expressões)
- [x] AGENTS.md de `codegen/` e `codegen/beam/` a cada etapa
- [ ] Opcional: modelar `raw` restantes (`Expr.comment` p/ `%% continue`/field assign; `$stringify` como nó)

### F5 — comptime `val` sem `erl` ✅
- [x] `comptime/eval.zig` dobra cada entrada no Zig (`valueOf` → `Value`, `literal`) e devolve `id → literal`;
      `runtime/beam.zig` apagado (`buildScript`, `parseResults`, cache `beam_cache/`)
- [x] `persistent_erl`: sem `loadBeam`, cmd=2 do servidor, `load_error`, `eval`/`warm`/`isReady` mortos
- [x] `evaluateComptime(allocator, bindings)` (sem `io`/`build_root`)
- [x] Seção de snapshot `COMPTIME JAVASCRIPT`/`COMPTIME ERLANG` (que mostrava o módulo `.erl` com o JSON) virou
      `COMPTIME VALUES` com `ct_N = literal`; valores conferidos contra o JSON antigo (script em F9)
- Diferenças conscientes: identificador solto ≠ `true`/`false`/`null` → `error.UnsupportedComptimeValue` (antes: JSON
  inválido → erro no parse do array inteiro); número não-decimal cai em `parseFloat`

### F6 — Suíte verde
- [x] Beam snapshots (5) aceitos e `.snap.md.new` versionados removidos do git. **Só `builtin_print_return_value_void`
      está certo**; os outros 4 gravam saída errada do backend beam (zip, `@Result`/`unwrapOr`, `Pair.first`/`compose`,
      `case` em átomo de enum sem `select_val`) — registrados na spec 03 (step 1, linha beam) como baseline a corrigir
- [x] RUN LOG dos 3 snapshots beam do F1: vazio é o esperado (sem `main`); a spec 03 registra `deallocate` sem
      `allocate` e `pub val` importado virando átomo
- [x] Baseline na `feat` dispensado: suíte 1430/1430, só os 13 leaks (já atribuídos ao step-2)
- [x] Leaks de codegen (13) → step-2; F3–F8 não adicionaram nenhum
- [x] Testes do lexer registrados em `src/lexer/tests.zig` (+141 testes, todos verdes); removidos os 2 testes e a
      asserção do keyword `echo`, que não existe mais

### F7 — Fechamento
- [x] `comptime/AGENTS.md` com o fluxo final (decorators/templates no `erl`, `val` dobrado em Zig)
- [x] Spec `specs/1.0.0-beta/01-test-green/step-1-decorator-eval.md` e `architecture.md` alinhadas
- [x] Commit submódulo → bump no meta a cada fase (sem `--no-verify`)
- [ ] Push / merge na `feat` + sweep das `feat` remotas — **só quando o Eric pedir**

### F9 — Revisão final de todos os snapshots alterados ✅
Cada snapshot aceito nesta branch foi conferido na hora, mas vale uma revisão única no fim, com a branch completa,
verificando se cada mudança **faz sentido** (é correção/efeito esperado, não regressão mascarada).

Listar (submódulo, base = merge-base com `origin/feat`, hoje `8d88372`):
```bash
cd repository/botopink-lang
base=$(git merge-base HEAD origin/feat)
git diff --name-status $base..HEAD -- '*.snap.md'          # A = novo, M = alterado, D = removido
git diff $base..HEAD -- '<caminho do snapshot>'             # revisar um a um
```

Revisão feita no fim do F6 (84 arquivos: 20 A, 55 M, 9 D). Veredito por grupo:
- [x] `comptime/{node,erlang,beam,wasm}` (20 A): AST tipado dos 5 testes de template em runtime; as 4 cópias são
      idênticas; tipos certos (`six` → `i32`, demais `string`)
- [x] 22 M com `COMPTIME VALUES` (F5): só a seção muda; valores conferidos contra o JSON antigo por script
- [x] `codegen/node` 3× `template_end_to_end_*`: expansão e RUN LOG corretos (`8005`, `<p>world</p>`, `<div>…`)
- [x] `codegen/erlang` `assign_update_var_with_pluseq` (`Count@1`, RUN LOG `1`) e 3× `comptime_loop_unrolling_*`
      (`Output@1`): corretos
- [x] `lsp/sublanguage_semantic_tokens`: `q` como função + `keyword`/`property` dentro da string — correto
- [x] `.snap.md.new` versionados por engano (9 D): removidos
- **Aceitos registrando bug conhecido** (todos na spec 03, não são "aprovação"):
  - erlang `template_end_to_end_*`: `Cfg`/`Page` ligados em `'_botopink_main'` e lidos em `main()`; concat de string
    da expansão sai como `+` em binários; RUN LOG vazio
  - erlang `comptime_partial_runtime_array_loop…`: `COMMANDS` lido na fn especializada; RUN LOG vazio
  - beam `template_end_to_end_holed_html…` imprime o átomo `page`; 4 RUN LOGs errados do F6 (zip, `@Result`,
    `Pair.first`/`compose`, `case` em enum); `import_multi_module_pub_val_import` / `val_pub_val_declaration`
    (`pub val` importado vira átomo, `deallocate` sem `allocate`)
  - wasm `template_end_to_end_*`: RUN LOG vazio (sem execução de WAT — spec 03 step 2)

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

---

## Para um agente revisar depois (achados da auditoria de docs)

Itens que a auditoria dos `.md` do submódulo encontrou mas **não corrigiu** (fora do escopo ou sem certeza).
Verificar cada um no código antes de agir.

- [ ] `libs/std/src/reflect.bp` e `types.bp` não estão no `root.bp` nem no `build.zig` — órfãos ou WIP? Ligar ou remover.
- [ ] Os 67 testes inline de `libs/std/src/primitives.bp` provavelmente não rodam no `botopink test` (o `root.bp` não declara o arquivo). Confirmar e decidir onde rodam.
- [ ] `libs/std/botopink.json` lista em `files` arquivos inexistentes (`primitives.d.bp`, `array.d.bp`, `string.d.bp`).
- [ ] `zig build test-vscode` chama `../../scripts/test-vscode.sh`, que não existe no meta.
- [ ] `scripts/git-hooks/pre-commit` procura `scripts/git-hooks/lib/test-runner.sh` no meta (não existe) e não há mais script que instale o hook (`install-hooks.sh` sumiu).
- [ ] Comentários de código ainda citam wasm3/wat3/`wat_runtime`/`wasm3_host`: doc de `executeWat` (`codegen/runtime.zig`), cabeçalho de `libs/std/src/template_runtime.bp`, `comptime/stdlib/prelude.zig`, `build.zig` (`std_internal_files`), `comptime.zig:674`.
- [ ] `.github/workflows/test.yml`: comentários desatualizados (wasmtime p/ "26 wasm snapshots", contagens de testes).
- [ ] Cabeçalho de `examples/hello.bp` diz `botopink run examples/hello.bp`, mas a CLI é baseada em projeto (`botopink.json`).
- [ ] `README.md` diz licença MIT, mas não há arquivo LICENSE no repo.
- [ ] Dica removida do `AGENTS.md` por falta de verificação: "logger do OTP escreve SIGTERM no stdout e corrompe o protocolo de frames do `persistent_erl`". Confirmar e, se valer, recolocar.
- [ ] Spec 03 (`specs/1.0.0-beta/03-codegen-hardening.md`): atualizar com as contagens medidas na working tree —
      snapshots com `@print` e RUN LOG vazio: node 14 · erlang 33 · beam 26 · wasm 95 (stub `executeWat`);
      com `undefined`: node 9 · erlang 1 · beam 4. Listar com `scripts/snap_audit.sh --mode=runlog`.
