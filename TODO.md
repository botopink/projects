# beam-asm-closures

**Branch**: `task/beam-asm-closures` (nasce de `feat` 35d81bb)
**Arquivos**: `codegen/beam_asm.zig` (+ snapshots `beam/beam/*`)

## O que esta task fez

Fechar o **último gap real da Fase 6** do backend BEAM ASM: closures
executáveis. Antes, lambdas/loops emitiam `make_fun2`, que o `erlc +from_asm`
**rejeita** nesta OTP (nenhum formato montava). Agora montam e rodam.

- [x] **`emitMakeFun`** — substitui `make_fun2` por
      `{test_heap, {alloc, [{words,0},{floats,0},{funs,1}]}, Live}` +
      `{make_fun3, {f,Entry}, 0, 0, {x,0}, {list,[]}}` (o `make_fun3` exige um
      registrador de destino `{x,0}` — a tentativa anterior falhava sem ele).
      Usado por `lowerLambda` (standalone, trailing, module-qualified) e
      `lowerLoop`.
- [x] **`min_live` floor** — `emitMakeFun` usa `@max(live, self.min_live)`.
      Em `lowerResultOptionOp` (`map`/`flatMap`), o payload do `@Result` fica
      stashed em `{x, pstash}` e precisa sobreviver ao `test_heap` da closure;
      `min_live = pstash+1` mantém-no vivo (senão `{uninitialized_reg,{x,2}}`).
- [x] **`map` rewrap em `disc`** — o `{tag,'Ok',Result}` pós-`call_fun` stasha
      o resultado em `{x, disc}` (contíguo a `{x,0}`), não em `{x, pstash}`,
      para que o `test_heap` do `put_tuple2` cubra só registradores vivos
      (`x1` acima de `disc` morre após `call_fun` → era `{{x,1},not_live}`).
- [x] **`is_tagged_tuple` em LISTA** nos 3 sites de `@Result` (`map`/`flatMap`,
      `unwrapOr`, `isOk`/`isError`) que ainda usavam forma achatada
      `{x,0}, 3, {atom,tag}` → `[{x,0}, 3, {atom,tag}]` (vinha do merge
      `result-runtime`; era `unknown_instruction`).

**Validação**: as 23 snapshots beam afetadas montam com `erlc +from_asm`;
`map` confirmado end-to-end (`Ok(42).map(n -> n+1)` ⇒ `{tag,'Ok',43}`).
`zig build test` verde (0 mismatch / 0 falhas).

## Ao concluir (commit → atualizar remote `feat` → excluir task)

Vars: `NOME=beam-asm-closures`  ·  `BR=task/beam-asm-closures`

1. **Commit** (dentro do worktree, sem `cd`):
   `git add -A && git commit -m "feat(beam-asm): <resumo>"`.
   O pre-commit roda `zig fmt` + `zig build` + `zig build test` — só passa se
   compila e os testes passam. (Não use `--no-verify`.)
2. **Atualizar a remote feature** (integrar em `feat`, sempre via **SSH** —
   `git@github.com:botopink/botopink-lang.git`):
   - `git fetch origin feat`
   - num worktree descartável a partir da remote (evita mexer no `feat` sujo):
     `git worktree add .tasks/_integrate-$NOME -b integrate/$NOME origin/feat`
   - lá dentro: `git merge --no-ff $BR`, resolver conflitos, rodar `zig build test`
   - `git push origin integrate/$NOME:feat` (fast-forward, sem `--force`)
3. **Excluir a task** (limpeza após integrar):
   - `git worktree remove .tasks/$NOME` e `git worktree remove .tasks/_integrate-$NOME`
   - `git branch -d $BR integrate/$NOME`
   - `git worktree prune`
