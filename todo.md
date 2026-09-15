# TODO — Step 1: comptime eval (decorators + templates) no erl

**Branch:** `fix/step-1-decorator-eval` (meta + submódulo `botopink-lang`)
**Objetivo:**
1. Um **modelo de termo único** (`Term`) com dois emitters — `erl_emitter` (fonte Erlang) e
   `beam_emitter` (BEAM asm `.S`) — usados pelos codegens `erlang.zig`/`beam_asm.zig` e pelo comptime.
2. Decorators e templates avaliados no `erl` persistente geram Erlang **válido** reusando o
   codegen real (`codegen/erlang.zig`).
3. `zig build test` verde.

**Prioridade:** 🔴 CRÍTICO

---

## Estado verificado (2026-09-15, submódulo `8aa8008` + WIP em `codegen/erlang.zig`)

`zig build` ✅ · `zig build test` ❌ — **31 falhas · 18 leaks · 2 binários travados**
(`test runner failed to respond for 1m59` em compiler-core **e** language-server).
Rodado 2× (antes e depois do WIP em `erlang.zig`) — resultado idêntico.

| Grupo | Falhas | Causa |
|---|---|---|
| `decorator_invocation` | 6 (+5 não reportados — binário travou) | Erlang gerado não compila: `Decl() -> _ = #{…}`, `Path() -> "/users"`, corpo vira `undefined` |
| `decorator_regression` | 2 (+2 não reportados) | idem |
| `templates` | 7 | `template_eval.evaluateErl` ainda usa Abordagem 1 (bp sintético → `compile()`) → `parse failed for module 'template_body'` |
| `sublanguage` (LSP) | 8 | idem templates (erika `@ExprCustom`) |
| `completion` | 1 | decorator falha → record com decorator perde bindings |
| `codegen` beam snapshots | 5 | RUN LOG agora tem saída (`<<"started">>`…) que o `.snap.md` não tem — `.snap.md.new` **commitados** no `9f1133c` |
| leaks | 14 codegen + 4 `erl_emitter` | codegen = escopo step-2; `erl_emitter` = `allocPrint`/`alloc` sem free nos testes |

### O que o todo anterior marcava ✅ mas NÃO é verdade

- ❌ Decorators `parseOutcome` com `parseFromSliceLeaky(ErlResult)` — ainda é `std.json.Value` manual.
- ❌ "Código Erlang gerado é válido" — nenhum módulo de decorator compila.
- ❌ BEAM `BeamValue`/`BeamResultEntry` — não existem; `runtime/beam.zig:394` usa `std.json.Value`.
- ⚠️ Templates `ErlTemplateResult`/`TypedValue` como `union(enum)` — `std.json` espera
  `{"code":{…}}` (externally tagged), não `{"kind":"code",…}`; `TypedValue` não aceita
  `42`/`{…}` crus. Hoje não explode só porque o eval nunca chega no parse.

### Duplicação de serialização de termos (motivação do modelo único)

| Lógica | Onde está copiada |
|---|---|
| escape de binário `<<"…">>` | `erlang.zig` `emitBinary` · `beam_asm.zig` `emitStringLiteral` · `runtime/beam.zig` `renderExprValue` · `decorator_eval.zig` `emitExpr` · `erl_emitter.zig` `emitString` |
| atom quotado / palavra reservada | `erlang.zig` `atomName`/`fnAtom`/`isErlangReserved` · `beam_asm.zig` (13 usos de `atomName`) · `decorator_eval` (manual) |
| variável Erlang (maiúscula) | `erlang.zig` `erlangVar` (33 usos) · `decorator_eval` (5 cópias inline) · `erl_emitter.emitVar` |
| map literal `#{…}` | `erlang.zig` (8) · `beam_asm.zig` `{literal, #{}}` / `put_map_assoc` · `erl_emitter.emitMap` |

---

## Decisões de arquitetura

### D1 — Modelo de termo único + 2 emitters

```
                   codegen/beam/term.zig  (Term: modelo de dados)
                     /                              \
 codegen/beam/erl_emitter.zig                 codegen/beam/beam_emitter.zig
 Term → fonte Erlang                          Term → operando BEAM asm
 <<"x"/utf8>>, 'Record', #{k => V}, [..]      {atom,'Record'}, {integer,1}, {float,..}, nil,
 + naming: atom/fnAtom/var/reserved           {literal, <termo via erl_emitter>}
     ↑              ↑                                 ↑                 ↑
 codegen/erlang.zig  comptime (decorator_eval,   codegen/beam_asm.zig  comptime/runtime/beam.zig
                     template_eval)
```

- Pasta **`codegen/beam/`** (`term.zig`, `erl_emitter.zig`, `beam_emitter.zig`, `AGENTS.md`): camada compartilhada
  pelos dois backends da VM BEAM (`.erl` e `.S`). Em `codegen/` porque os consumidores principais são
  `erlang.zig`/`beam_asm.zig` (comptime já depende de codegen, não o contrário); em subpasta porque a raiz
  de `codegen/` é um arquivo por backend. `comptime/erl_emitter.zig` **move** p/ `codegen/beam/`.
- Os dois emitters escrevem em `*std.Io.Writer` (o que os codegens já usam), não em `ArrayListUnmanaged`.
- `beam_emitter` reusa `erl_emitter` para o conteúdo de `{literal, …}` — a sintaxe de termo no `.S` é a mesma do `.erl`.
- Duas entradas de string: `binaryFromBytes` (bytes crus em runtime — handle, valores comptime) e
  `binaryFromLexeme` (conteúdo do lexer com escapes da fonte: `\n`, `\$`, `\u{…}` — o `emitBinary` atual).
- Migração dos codegens é **byte-idêntica**: os snapshots de erlang/beam não podem mudar
  (qualquer mudança de formato, ex. `/utf8`, é decisão separada com regen explícito).

### D2 — Comptime eval pelo codegen real (Abordagem 4)

Não manter um terceiro emitter de expressões à mão. O `codegen/erlang.zig` já trabalha sobre
`ast.Program` **não tipado** e lowera tudo que os decorators usam — verificado compilando
corpos equivalentes com `botopink build --target erlang`:

| botopink | Erlang gerado pelo codegen real |
|---|---|
| `if (c) { … }` | `case C of true -> …; _ -> ok end` |
| `decl.kind` | `maps:get(kind, Decl)` |
| `DeclKind.Record` | `'Record'` (se `DeclKind` ∈ `enum_names`) |
| `decl.fail(msg)` | `fail(Decl, Msg)` |
| `@emit(src)` / `@compilerError(m)` | `emit(Src)` / `compilerError(M)` |
| `var s = ""; xs.forEach({ m -> s = s + … })` | `S = lists:foldl(fun(M, S) -> … end, <<"">>, Xs)` |
| `a + b` (strings) | ❌ `(A + B)` — resolvido com `'__bp_add'/2` em modo comptime |

Fluxo:

```
FnDecl (AST do decorator/template)
  → ast.Program{ decls = [fn] }
  → erlang.emitComptimeModule(program, .{ host_enums, exports = main/0, tail = host fns + main/0 })
      tail/main usa erl_emitter p/ o handle @Decl / captures (Term)
  → .erl único por avaliação → persistent_erl.eval → JSON {kind,…} → parseOutcome → Outcome
```

---

## Plano

### F0 — Housekeeping (meta + submódulo)

- [ ] Meta: `git rm -r src/` — cópia acidental de 11k linhas do submódulo commitada no `b0025c1c`
- [ ] Submódulo: remover `.snap.md.new` commitados (9 arquivos, `9f1133c`); os testes já apagam 4 deles ao rodar
- [ ] Remover `std.debug.print` de `decorator_eval.zig` (8) e `infer.zig:2264/2266` — trocar por
      mensagem de erro propagada no `Outcome.err` (ver F2 persistent_erl)
- [ ] Remover `.qwen/`, `test_pub.zig`, `.env` vazio do meta se não forem intencionais (confirmar com Eric)

### F1 — Modelo de termo + `erl_emitter` + `beam_emitter` (✅ commitado — submódulo `7dbb6f1`)

**`codegen/beam/term.zig`** ✅
- [x] `Term = union(enum) { atom, binary, integer, float, boolean, nil, list, tuple, map }`
- [x] `Term.MapEntry { key: Term, value: Term }`
- [x] Construtores: `atomOf`, `str`, `int`, `listOf`, `tupleOf`, `mapOf`, `field`, `undefined_atom`
- [x] Teste unitário

**`codegen/beam/erl_emitter.zig`** ✅ (substitui `comptime/erl_emitter.zig`, removido)
- [x] `writeTerm` — termo puro (corrige o `_ = #{…}`)
- [x] `isReserved`, `isUnquotedAtom`, `atomText(name, buf)`, `writeAtom`, formatter `atom(name)` p/ `{f}`
      — regra única: bare se `[a-z][A-Za-z0-9_@]*` e não reservado; senão quota + escapa `'`/`\`; pré-quotado passa intacto
- [x] `writeVar` / `varName` / `moduleName`
- [x] `writeBinaryFromBytes` — bytes ≥ 0x80 e controle como `\x{HH}` (binário exato, sem depender de encoding da fonte)
- [x] `writeBinaryFromLexeme` — ex-`erlang.zig` `emitBinary`
- [x] `writeFloat` (sempre com `.`, erro p/ não-finito)
- [x] Testes unitários sem leak (os 4 leaks do emitter antigo sumiram)

**`codegen/beam/beam_emitter.zig`** ✅
- [x] `writeOperand` (`{atom,…}`/`{integer,…}`/`{float,…}`/`nil`/`{literal, <term>}`), `writeLiteral`,
      `writeAtomOperand`, `writeLexemeBinaryOperand`, `writeMove`
- [x] Testes unitários

**Wiring** ✅
- [x] `codegen/tests.zig` importa os 3 arquivos
- [x] `codegen/beam/AGENTS.md` + linha/árvore em `codegen/AGENTS.md`

**Migração `codegen/erlang.zig`** ✅
- [x] `atomName`/`fnAtom` = `erlEmitter.atomText`, `erlangVar` = `varName`, `erlangModule` = `moduleName`
- [x] `erlang_reserved`/`isErlangReserved` removidos (vivem no emitter)
- [x] `emitBinary` → `writeBinaryFromLexeme`
- [x] Snapshots erlang sem diff
- [ ] Literais constantes de map/list/tuple → `Term` + `writeTerm` (poucos sites; opcional)
- [ ] Trocar chamadas `erlangVar` (33, alocam) por `writeVar` direto no writer (opcional, perf)

**Migração `codegen/beam_asm.zig`** ✅
- [x] `atomName` = `erlEmitter.atomText` (`isUnquotedAtom` local removido)
- [x] `emitStringLiteral` → `beamEmitter.writeLexemeBinaryOperand` (antes escapava `\` do lexema errado)
- [x] `{move, {literal, <<"~p">>}…}`, `{literal, #{}}`, `put_map_assoc` keys, `move` de atoms → `beam_emitter`
- [x] `{function, …}` / `{func_info, …}` / `get_map_elements` / `put_map_exact` / `put_tuple2` / `is_tagged_tuple` com nome cru → `erlEmitter.atom(…)`
- [x] **Snapshots beam corrigidos (bug real, antes não montavam):**
  - `record_returned_then_field_read_on_call_result` — `{atom, end}` → `{atom, 'end'}`
  - `val_pub_val_declaration` — `{function, HOST, …}` / `{atom, VERSION}` → quotados
  - `import_multi_module_pub_val_import` — `{function, PORT, …}` / `{atom, HOST}` → quotados
- [ ] Verificar se esses 3 snapshots passam a ter RUN LOG com saída (antes o `.S` nem montava)

**Consumidores comptime**
- [x] `decorator_eval.zig`: `handleToTerm(arena, DeclHandle) Term` (`kind` como atom) + `writeTerm`
- [ ] `comptime/runtime/beam.zig` `renderExprValue` → `Term` (F5)
- [ ] `template_eval.zig` captures → `Term` (F4)

**Suíte após F1:** 31 → 31 falhas pré-existentes, **0 novas**; leaks 18 → 14 (só os de codegen/step-2).

### F2 — Infra comptime Erlang

**`codegen/erlang.zig`** (base commitada em `7dbb6f1`)
- [x] `pub const ComptimeModule { host_enums, exports, tail }`
- [x] `pub fn emitComptimeModule(alloc, module_name, program, module)` → `emitErlangModule(…, comptime_module)`
- [x] `host_enums` → `em.enum_names` (qualified member vira atom)
- [x] `exports` extras no `-export([...])`
- [x] `dynamic_add`: `+` → `'__bp_add'(A, B)` + helper emitido no tail
- [ ] `.len`/`.length` sem `instance_lowering` em modo comptime → `'__bp_len'(X)`
      (`is_binary → string:length`, `is_list → length`) — necessário p/ `decl.fields.len > 5`
- [ ] Verificar rebinding de `var` fora de fold (`msg = msg + decl.name` → `Msg = …` duas vezes = `badmatch`);
      se o codegen não renomeia (`Msg1`), implementar renomeação no modo comptime
- [ ] Verificar `forEach` com `fail` dentro do lambda (sem acumulador) → `lists:foreach`
- [ ] Confirmar que `cross = null` + mapas vazios bastam (sem `collectStdImports` quebrando)
- [ ] Teste unitário: snapshot do módulo comptime de um decorator simples

**`comptime/runtime/persistent_erl.zig`**
- [ ] **Bug de framing:** `readFrame` usa `readStreaming` ignorando o count → leitura curta em payload grande
      (ex. `__BP_ERL_COMPILE_ERROR__` com `~p`) dessincroniza o protocolo e trava o próximo eval.
      Loop até ler `len` bytes. **Suspeito nº 1 dos 2 binários travados.**
- [ ] `eval` devolver o payload de erro (compile/runtime) em vez de só `error.PersistentErlCompileError`
      — sem isso não dá pra debugar o Erlang gerado
- [ ] Timeout no `readFrame` (erl travado não pode segurar o test runner 2 min)
- [ ] Documentar/tratar o `beam.smp` órfão por execução de teste

### F3 — Decorators (`comptime/decorator_eval.zig`)

- [ ] Reescrever `buildErlModule` sobre `erlang.emitComptimeModule`:
  - program = `[dfn]`; export só `main/0`
  - `host_enums = &.{"DeclKind"}`
  - `tail` = host fns (`fail/2`, `failAt/3`, `compilerError/1`, `emit/1`, `emit_stack/0`) + `main/0`
  - `main/0` chama `<decorator>(<handle Term>, <plain args Term>)`; aridade = `dfn.params.len`,
    parâmetro sem arg → `undefined`
  - `main/0` captura `throw:{comptime_fail, Msg, Span}` **e** `error:Reason` → `{kind:"error", message}`
- [ ] Apagar `emitExpr`/`emitStmt`/`emitBody`/`emitDeclHandle` manuais
- [ ] `handleToTerm(arena, DeclHandle) Term`:
  - `kind` como **atom** (`'Record'`), batendo com o lowering de `DeclKind.Record`
  - `methods[].params`, `returnType`, `annotations[].args` coerentes com `builtins.d.bp` (`DeclAnnotation`, …)
  - `Interface`: `fields[].typeName` vem de `fld.typeName` (checar `infer.zig` ~2370)
- [ ] Plain args: `PlainArg.jsValue` é lexema bp (`"/users"`, `42`, `true`) → `Term`
      (string → `binary`, número → `integer`/`float`, bool → `boolean`; resto → erro claro). Renomear campo p/ `source`
- [ ] Nome de módulo/arquivo **único por avaliação**: hash do Erlang gerado (hoje `hash(dfn.name)` → corrida em testes paralelos)
- [ ] `parseOutcome` com struct real no formato que o `main/0` emite (`{kind, contributions|message|span}`)
- [ ] Não dar `arena.free(stdout)` antes de usar slices parseadas (`parseFromSliceLeaky` pode referenciar o input)
- [ ] `fail` com span (`failAt`) → `Outcome.fail.span`
- [ ] `infer.zig`: mensagem do `Outcome.err`/erro de compilação vai pro `TypeError` (hoje hint fala "check that `erl` is available")

### F4 — Templates (`comptime/template_eval.zig`)

- [ ] Migrar `evaluateErl` p/ `emitComptimeModule` (mesmo padrão do F3); apagar `emitBpBody`/decompilador bp
- [ ] Host fns de template no `tail` / prelude: `q.build`, `q.text`, `q.parts`, `q.lookup`, `q.bindings`,
      `q.fail`, `q.custom`, `@expr`, `makeExpr`, `makeCode` (hoje `#[@Host]` em `template_runtime.bp` +
      `botopink_comptime_prelude` em `erl_prelude.zig`)
- [ ] Captures (`template.CapturedExpr`) → `Term` no `main/0`
- [ ] `parseOutcome`: trocar `union(enum)` do `std.json` por parse do formato `{kind:…}`
      (struct plana com `kind` + campos opcionais, ou walk de `std.json.Value` → `TypedValue`/`CustomNodeTree`)
- [ ] Avaliar `TypedValue` = `Term` (mesmo modelo de dados na volta) — JSON cru (`42`, `"x"`, `[…]`, `{…}`) → `Term`
- [ ] Hint do erro ainda fala "node runtime" → corrigir p/ erl
- [ ] Remover `literalFromJson` se não restar uso (`infer.zig:3543`)

### F5 — BEAM comptime (`comptime/runtime/beam.zig`)

- [ ] `renderExprValue` (JSON montado à mão) → `TypedExpr` → `Term` + `erl_emitter`/`beam_emitter`
- [ ] `parseResults` → struct/`Term` em vez de `std.json.Value`
- [ ] Não bloqueia teste verde — pode ir depois de F6 se apertar

### F6 — Suíte verde

- [ ] `decorator_invocation` 11/11
- [ ] `decorator_regression` 4/4
- [ ] `templates` 7 falhas → 0
- [ ] `sublanguage` 8 falhas → 0 · `completion` R2 → 0
- [ ] Nenhum binário de teste trava (depende de F2 persistent_erl)
- [ ] Beam snapshots (5): revisar diff do RUN LOG (`<<"started">>`, `[<<"a">>,…]` — saída nova parece correta) e aceitar os `.new`
- [ ] Snapshots erlang/beam sem diff causado por F1 (migração byte-idêntica)
- [ ] Rodar baseline na `feat` pra separar regressão desta branch de falha pré-existente
- [ ] Leaks de codegen (14) → step-2 (`fix/step-2-allocation-leaks`); só garantir que F1–F5 não adicionam novos

### F7 — Fechamento

- [ ] `AGENTS.md` do submódulo: `codegen/AGENTS.md` + `codegen/beam/AGENTS.md` (term + emitters) e `comptime/AGENTS.md` (fluxo novo, sem decompilador bp)
- [ ] `architecture.md`, `STATUS.md`, spec `specs/1.0.0-beta/01-test-green/step-1-decorator-eval.md`
- [ ] Commit submódulo → bump no meta (pre-commit sem `--no-verify`)
- [ ] Sweep das `feat` remotas (meta + submódulos)

**Ordem sugerida:** F0 → F1 (term + erl_emitter) → F2 → F3 → F4 → F1 (beam_emitter + migrações) → F6 → F5 → F7.
`erl_emitter` é pré-requisito de F3; a migração do `beam_asm.zig` é independente e pode andar em paralelo.

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
| regression: string concat | rebinding `msg = msg + …` |
| regression: `@emit` in body | `'__bp_add'` dentro de `@emit` |

---

## Notas de build

- `zig build test -- --test-filter` **não funciona** no Zig 0.16; rodar o binário direto
  (`.zig-cache/o/<hash>/test`) ou a suíte inteira (~4 min hoje por causa dos 2 travamentos).
- `zig build test` em background, log em arquivo; cap de 60s em foreground.
- `persistent_erl` deixa `beam.smp` órfão; matar por PID (`/bin/kill -9 <pid>`).
  **Não** usar `pkill -f botopink_comptime_server` no mesmo comando do teste — casa com a própria linha de comando.
- Iteração rápida sem suíte: `zig-out/bin/botopink build --target erlang --out out` num projeto de scratch
  com o decorator aplicado (os prints de debug mostram o Erlang gerado).

---

## Histórico de abordagens

1. **bp sintético → `compile()` → codegen** (abandonada p/ decorators; ainda usada em templates):
   `parse failed for module 'template_body'`, causa raiz nunca confirmada.
2. **Emitter Erlang à mão sobre o AST** (`decorator_eval.emitExpr/emitStmt`): cobre só literal/ident/binop/call;
   `if`, métodos, enums, lambdas e `+` de string saem `undefined`/errados. Nenhum módulo compila.
3. **Structs nativas no pipeline** (`DeclHandle`, `TypedValue`): `DeclHandle` ok; parse de resultado em
   `union(enum)` incompatível com o formato `{kind:…}`.
4. **Codegen real em modo comptime + modelo de termo único** (atual): `erlang.emitComptimeModule` sobre o AST
   não tipado; valores (handle, args, captures) como `Term` emitidos por `erl_emitter`/`beam_emitter`.
