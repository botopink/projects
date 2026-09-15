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

`zig build` ✅ · `zig build test`: **1419/1424 ok · 5 falhas · 13 leaks · ~17s · sem travamentos**

| Grupo | Falhas | Causa |
|---|---|---|
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
- **F4** (não commitado): `template_eval` sobre `emitComptimeModule` — capture como `Term` (`captureToTerm`: text/parts com
  placeholders de hole/source/context/bindings), host fns (`text`, `parts`, `lookup`, `build`, `custom`, `fail`, `failAt`,
  `expr`, `code`…), `main/0` com reply por forma do resultado, `parseOutcome` com struct plana + `std.json.Value` →
  `TypedValue`/`CustomNodeTree` (`ref` com name+kind); decompilador `emitBpBody` removido; `PlainArg.writeErl` compartilhado
  com decorators. Codegen erlang: `host_records` no `ComptimeModule` e **mutação em `if`/`loop`/`forEach` retornando os
  valores** (`Acc@1 = case … end`, `lists:foldl`). Snapshots: `comptime_partial…` (loop de `COMMANDS`), 12 de
  `template_end_to_end_*` (node/erlang/beam/wasm, antes vazios/truncados), `lsp/sublanguage_semantic_tokens` (agora pinta
  keyword/property dentro da string). Resultado: 22 → 5 falhas.
- **F0 parcial:** `.snap.md.new` commitados removidos; `src/` duplicado do meta removido; docs de todo o projeto auditadas.

---

## Pendente

### F0 — Housekeeping
- [ ] `.qwen/`, `test_pub.zig` (importa `modules/core/src/parser.zig`, inexistente), `.env` vazio no meta — decisão do Eric

### F3 — Decorators — pendências menores
- [ ] Plain args: renomear `PlainArg.jsValue` → `source` (compartilhado com `template_eval`, fazer junto do F4)
- [ ] `TypeError` de decorator com loc da anotação (hoje coarse) e `failAt` usando o span

### F4b — Limpeza pós-templates
- [ ] `comptime.zig` `warmPersistentErlRunner`: remover a compilação de `template_runtime.bp` → `template_runtime.erl` e `patchHostMethods` (não usados pelo avaliador novo)
- [ ] `runtime/erl_prelude.zig` (`botopink_comptime_prelude`): remover se nada mais chama; tirar do `persistent_erl.ensureSpawned`
- [ ] `template.zig`: remover helpers WAT/JSON mortos (`readWatString`, leitura de `CustomNode` da memória WAT, `parseCustomNode(std.json.Value)`, `parseSpanJson`/`jsonStr` se sem uso); `contextJsonAlloc` tem teste — decidir
- [ ] `infer.zig`: remover `literalFromJson`
- [ ] `libs/std/src/template_runtime.bp`: ainda descreve o modelo WAT (`i32`) — remover ou alinhar ao modelo de capture em map
- [ ] `PlainArg.jsValue` → `source`
- [ ] Bug do backend erlang visto no snapshot `template_end_to_end_yaml…`: `Cfg` ligado em `'_botopink_main'` e lido em `main()` (top-level `val` com wrapper de entrypoint) → spec 03

### F8 — Erlang AST + emitter (decisão do Eric: `erlang.zig` emite pelo emitter)
Hoje o `erlang.zig` usa o `erl_emitter` só p/ nomes/atoms/binários (6 chamadas); ~385 `this.w("…")`/`this.fmt("…")`
escrevem Erlang à mão (`case`, `fun`, `lists:foldl`, maps, tuplas, chamadas), incluindo a mutação do F4 e o host glue
em texto de `decorator_eval`/`template_eval`.
- [ ] `codegen/beam/erl_ast.zig`: modelo de expressões/formas Erlang (module/attribute/function/clause, match, case,
      if/receive?, fun, call local/remote, binop/unop, var, atom, literal `Term`, map/list/tuple/cons, map get/update,
      try/catch, block) sobre o `Term` para literais
- [ ] `erl_emitter`: renderizar `erl_ast` (indentação idêntica à atual p/ snapshots byte-idênticos)
- [ ] Migrar `erlang.zig` construto por construto (expressões → statements → funções → módulo), snapshot erlang
      byte-idêntico a cada passo; `emitMutatingStmt` monta nós (sem side buffer de texto)
- [ ] Host glue de `decorator_eval`/`template_eval` (`fail/2`, `main/0`, `'__bp_reply'`…) como `erl_ast`
- [ ] `beam_emitter` continua no `Term` (o `.S` é máquina de registradores, não expressões)
- [ ] AGENTS.md de `codegen/` e `codegen/beam/`

### F5 — BEAM comptime (`comptime/runtime/beam.zig`) — remover a ida ao `erl`
`renderExprValue` já calcula tudo no Zig e grava o JSON como string fixa em `main() -> "…"`; o `erl` só devolve
a string e `parseResults` re-parseia o que o Zig gerou.
- [ ] `renderExprValue` → literal direto no mapa `id → literal`, sem script
- [ ] Apagar `buildScript`, `parseResults`, cache `beam_cache/`, `persistent_erl.loadBeam` e o cmd=2 do servidor
- [ ] Ajustar snapshots com seção `COMPTIME ERLANG`
- [ ] Não bloqueia teste verde

### F6 — Suíte verde
- [ ] Beam snapshots (5): revisar o RUN LOG novo e aceitar
- [ ] Verificar RUN LOG dos 3 snapshots beam corrigidos no F1 (antes o `.S` nem montava)
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
