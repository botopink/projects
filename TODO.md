# ext-dispatch-backends

**Branch**: `task/ext-dispatch-backends` (nasce de `feat` f0d9552)
**Depende de**: extension-dispatch F6 (já em `feat`)
**Arquivos**: `codegen/erlang.zig`, `codegen/beam_asm.zig`, `codegen/wat.zig`, `codegen/typescript.zig`

## O que esta task vai fazer

Completar o **codegen non-JS** do dispatch estático de extensões. Hoje só o
CommonJS reescreve o call-site `obj.m()` → `Sym.m(obj)` usando os
`dispatch_rewrites` (loc-keyed) produzidos pela inferência. As decls
`implement`/`extend` já compilam nos outros backends, mas a **reescrita da
chamada** falta em:

- [x] Erlang — `obj.m(args)` → função local `m(obj, args)` (bare; mantém `self`
      como primeiro param). Qualified `Sym.m(obj)` também vira local em vez de
      remote. `extend` agora também é emitido.
- [x] BEAM ASM — `call '<target>_m'(...)` para o símbolo resolvido (activated
      prepende o receiver; qualified usa os args como estão). `extend`
      reservado/emitido/exportado como `'<target>_m'`.
- [x] WAT — métodos viram funções linear-memory `$<target>_m` (mantêm `self`);
      o call-site faz `call $<target>_m`. Limitação pré-existente: acesso a
      campo nomeado (`self.id`) ainda não resolve no WAT (gera `i32.const 0`),
      afeta todos os métodos, não só dispatch.
- [x] TypeScript (`.d.ts`) — não há call-site a reescrever: `.d.ts` é só tipo e
      blocos `implement`/`extend` são invisíveis à binding list.

Consome os mesmos `env.dispatch_rewrites` (por loc) que o CommonJS já usa.
Snapshots por backend para cada cenário (inherent / activated / qualified /
extend) em `snapshots/codegen/*/dispatch_*`.

> Notas: construção de record com args posicionais (`Pato(2)`) ainda fica
> `%% unresolved`/sem `new` em alguns backends — gap pré-existente de records,
> ortogonal ao dispatch.

## Ao concluir (commit → atualizar remote `feat` → excluir task)

Vars: `NOME=ext-dispatch-backends`  ·  `BR=task/ext-dispatch-backends`

1. **Commit** (dentro do worktree, sem `cd`):
   `git add -A && git commit -m "feat(codegen): <resumo>"`.
   O pre-commit roda `zig fmt` + `zig build` + `zig build test` — só passa se
   compila e os testes passam. (Não use `--no-verify`.)
2. **Atualizar a remote feature** (integrar em `feat`, sempre via **SSH** —
   `git@github.com:botopink/botopink-lang.git`):
   - `git fetch origin feat`
   - num worktree descartável a partir da remote (evita mexer no `feat` sujo):
     `git worktree add .tasks/_integrate-$NOME -b integrate/$NOME origin/feat`
   - lá dentro: `git merge --no-ff $BR`, resolver conflitos (em `beam_asm.zig`,
     conferir colisão com `beam-asm-finish`), rodar `zig build test`
   - `git push origin integrate/$NOME:feat` (fast-forward, sem `--force`)
3. **Excluir a task** (limpeza após integrar):
   - `git worktree remove .tasks/$NOME` e `git worktree remove .tasks/_integrate-$NOME`
   - `git branch -d $BR integrate/$NOME`
   - `git worktree prune`
