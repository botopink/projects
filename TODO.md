# result-runtime

**Branch**: `task/result-runtime` (nasce de `feat` f0d9552)
**Depende de**: stdlib-result @Result/@Option methods (já em `feat`)
**Arquivos**: `codegen/beam_asm.zig`, `codegen/wat.zig` (+ runtime/prelude se preciso)

## O que esta task vai fazer

Dar **runtime real** a `@Result`/`@Option` em BEAM e WASM. Hoje CommonJS e
Erlang emitem a forma inline correta dos métodos (`map`, `flatMap`, `unwrapOr`,
`isOk`/`isError`); BEAM e WASM emitem só um **stub documentado**.

- [x] Representação de runtime de `Ok(v)`/`Error(e)` e `Some(v)`/`None`
      (BEAM: tupla `{tag, 'Ok'|'Error', V}` / átomo `undefined`; WASM: ponteiro
      `[tag, payload]` com tag 0 = Ok / `0` = None)
- [x] Inlining dos métodos de ordem superior (`map`/`flatMap` recebem closure)
      (BEAM via `call_fun`; WASM faz inline do corpo do lambda literal)
- [x] `unwrapOr` / `isOk` / `isError` e espelho `@Option`
- [x] Substituir os stubs pelos builtins `__bp_<domain>_<op>(...)` reais
- [x] Snapshots BEAM/WASM regenerados para os 6 cenários cobertos em JS/Erlang
      (mais correção: corpo de lambda BEAM agora retorna o valor da expressão
      tail em vez de `ok`, necessário para os closures de `map`/`flatMap`)

## Ao concluir (commit → atualizar remote `feat` → excluir task)

Vars: `NOME=result-runtime`  ·  `BR=task/result-runtime`

1. **Commit** (dentro do worktree, sem `cd`):
   `git add -A && git commit -m "feat(codegen): <resumo>"`.
   O pre-commit roda `zig fmt` + `zig build` + `zig build test` — só passa se
   compila e os testes passam. (Não use `--no-verify`.)
2. **Atualizar a remote feature** (integrar em `feat`, sempre via **SSH** —
   `git@github.com:botopink/botopink-lang.git`):
   - `git fetch origin feat`
   - num worktree descartável a partir da remote (evita mexer no `feat` sujo):
     `git worktree add .tasks/_integrate-$NOME -b integrate/$NOME origin/feat`
   - lá dentro: `git merge --no-ff $BR`, resolver conflitos (em `wat.zig`,
     conferir colisão com `wat-features`), rodar `zig build test`
   - `git push origin integrate/$NOME:feat` (fast-forward, sem `--force`)
3. **Excluir a task** (limpeza após integrar):
   - `git worktree remove .tasks/$NOME` e `git worktree remove .tasks/_integrate-$NOME`
   - `git branch -d $BR integrate/$NOME`
   - `git worktree prune`
