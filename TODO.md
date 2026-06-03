# beam-asm-finish

**Branch**: `task/beam-asm-finish` (nasce de `feat` 9d9b320)
**Depende de**: beam-asm Fases 1–6 (já em `feat`)
**Arquivos**: `codegen/beam_asm.zig`

## O que esta task fez

Fechou lacunas de **correção** do backend **BEAM ASM** que faziam o `.S`
emitido falhar no assembler/validador do `erlc +from_asm` (a maioria dos
programas com `case`/`>`/enum/`if`-como-valor nunca chegava a rodar — RUN LOG
vazio). Cada item foi validado montando o `.S` com `erlc +from_asm` e, quando há
entry-point, executando com `erl`.

- [x] **Guards de `case`** (`pat if guard -> body`): antes só o commonJS gerava;
      agora o BEAM avalia o guard após bindar o padrão (`emitGuardPre`/`Post`),
      restaurando o subject e caindo no próximo arm quando o guard falha.
      Validado: `classify(5)→"positive"`, `0→"zero"`, `-3→"negative"`;
      `Circle(15)→"big circle"`, `Circle(3)→"other"`.
- [x] **Opcodes de comparação válidos**: BEAM não tem `is_gt`/`is_le` — `>` e
      `<=` agora viram `is_lt`/`is_ge` com operandos trocados (`comparisonTestOp`).
      Validado: `isPositive(5)→true`, `-1→false` (antes não montava).
- [x] **Quoting de átomos**: tags de enum PascalCase (`{atom, 'Circle'}`),
      `.dotIdent`, nomes especializados em comptime (`'execute_$0'`) e funções de
      componente (`'Widget'`/`'Counter'`) — antes davam `bad term`/`syntax error`
      no parser de termos (`atomName`/`isUnquotedAtom`).
- [x] **Formato de `is_tagged_tuple`**: operandos em lista
      `[{x,0}, N, {atom,Tag}]` (antes args soltos → `unknown_instruction`).
- [x] **Contagem de y-slots** (`countLocalsRec`): passou a contar bindings de
      arm de `case` e destructure multi-campo, evitando `{invalid_store,{y,k}}`.
- [x] **`if`-como-valor**: `val r = if … else …` produz valor em `{x,0}` e cai
      através (`emitValueIf`/`emitValueBody`) em vez de emitir `return` nos
      branches (que gerava código morto e nunca atribuía). Validado:
      `abs(-5)→5`, `abs(3)→3`.
- [x] **`init_yregs`** (`emitFrame`): após `{allocate, N, A}` com N>0, zera os
      y-slots — exigência de GC-safety do BEAM, resolvendo toda a classe
      `{uninitialized_reg,{y,k}}` (try/catch, pipeline, destructure, etc.).
- [x] **Snapshots BEAM** regenerados e versionados por item; suíte `zig build
      test` verde. Validação `erlc` de programas com `main`: **35/44 montam+rodam**
      (antes ~8).

## Lacunas restantes (pré-existentes, fora do escopo desta task)

Os 9 programas-entry-point que ainda não montam têm 2 causas, **independentes**
do que foi corrigido aqui:

- [ ] **Closures via `make_fun2`** (8 casos: `lambda_*`, `loop_*`,
      `call_trailing_lambda_*`, `comptime_partial_*`): nenhum formato de
      `make_fun2`/`make_fun3` montou nesta versão do OTP — `+from_asm` exige a
      tabela de lambdas (chunk `FunT`) que este backend ainda não emite. É a
      continuação real da Fase 6 (closures executáveis no BEAM).
- [ ] **`negation_in_expression` (`{{x,2},not_live}`)**: o `Live` do `gc_bif '-'`
      em negação não-trivial está alto demais para os x-regs realmente vivos.
- [ ] **`@Result`/`@Option` (`__bp_*`)**, **imports cross-module**, **`*fn`
      async/await**, **dispatch de método em valor tipado** (`p.parse()`):
      quebrados também no backend Erlang por falta de tipo no codegen — não são
      específicos do BEAM.

## Ao concluir (commit → atualizar remote `feat` → excluir task)

Vars: `NOME=beam-asm-finish`  ·  `BR=task/beam-asm-finish`

1. **Commit** (dentro do worktree, sem `cd`):
   `git add -A && git commit -m "feat(beam-asm): <resumo>"`.
   O pre-commit roda `zig fmt` + `zig build` + `zig build test` — só passa se
   compila e os testes passam. (Não use `--no-verify`.)
2. **Atualizar a remote feature** (integrar em `feat`, sempre via **SSH** —
   `git@github.com:botopink/botopink-lang.git`):
   - `git fetch origin feat`
   - num worktree descartável a partir da remote (evita mexer no `feat` sujo):
     `git worktree add .tasks/_integrate-$NOME -b integrate/$NOME origin/feat`
   - lá dentro: `git merge --no-ff $BR`, resolver conflitos (em `beam_asm.zig`,
     conferir colisão com `ext-dispatch-backends`), rodar `zig build test`
   - `git push origin integrate/$NOME:feat` (fast-forward, sem `--force`)
3. **Excluir a task** (limpeza após integrar):
   - `git worktree remove .tasks/$NOME` e `git worktree remove .tasks/_integrate-$NOME`
   - `git branch -d $BR integrate/$NOME`
   - `git worktree prune`
