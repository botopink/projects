# Situação das tasks

> Levantamento real cruzando cada arquivo de task (`tasks/*.md`) **e o `TODO.md`
> de cada worktree em `.tasks/{name}/`** com o histórico do git e o estado das
> branches. **Os campos `Status` em `tasks/*.md` estão desatualizados** (refletem
> o momento da criação da branch); os `TODO.md` dentro de cada worktree são mais
> fiéis, pois acompanham o tip da branch. Esta é a síntese.
>
> Branch de referência: `feat` (HEAD `3746eae`), já rebaseada sobre `origin/feat`.
> Data do levantamento: 2026-06-02.

## Resumo

| # | Task | Branch | Situação real | Onde está |
|---|---|---|---|---|
| 1 | ast-simplification | `task/ast-simplification` | ✅ Concluída (Fases 1–7) | em `feat` |
| 2 | import-rework | `task/import-rework` | ✅ Concluída (F0–F2) | em `feat` |
| 3 | use-await-prefix | `task/use-await-prefix` | ✅ Concluída (F3, absorvida) | em `feat` |
| 4 | implement-extend-decls | `task/implement-extend-decls` | ✅ Concluída (F4–F5) | em `feat` |
| 5 | context-inference | `task/context-inference` | ✅ Concluída (F7) | em `feat` |
| 6 | throw-check | `task/throw-check` | ✅ Concluída | em `feat` |
| 7 | trycatch-lowering | `task/trycatch-lowering` | ✅ Concluída (todos os backends) | em `feat` |
| 8 | typeparam | `task/typeparam` | ✅ Concluída | em `feat` |
| 9 | async-generators | `task/async-generators` | ✅ Concluída | em `feat` |
| 10 | erlang-gaps | `task/erlang-gaps` | ✅ Concluída | em `feat` |
| 11 | interface-coverage | `task/interface-coverage` | ✅ Concluída (Fases 1–4) | em `feat` |
| 12 | beam-asm | `task/beam-asm` | 🔶 Parcial (Fases 1–2 + ranges + try/catch; Fases 3–9 pendentes) | em `feat` |
| 13 | stdlib-result | `task/stdlib-result` | 🟡 Implementada (backends BEAM/WASM = stub), **fora do `feat`** | branch `task/stdlib-result` (`5f279b5`) |
| 14 | extension-dispatch | `task/extension-dispatch` | 🟡 Implementada (F6); codegen non-JS = follow-up, **fora do `feat`** | branch `task/extension-dispatch` (`fb43ef2`) |
| 15 | hook-codegen | `task/hook-codegen` | 🟡 Implementada (F8), **fora do `feat`** | branch `task/hook-codegen` (`26ee8a5`) |
| 16 | tooling | `task/tooling` | 🟡 Implementada (exaustividade de `case` = parcial), **fora do `feat`** | branch `task/tooling` (`464ce4c`) |
| 17 | wat-features | `task/wat-features` | ⛔ Não iniciada (branch parada no commit base) | — |

**Contagem:** 11 concluídas · 1 parcial · 4 prontas-mas-não-integradas · 1 não iniciada.

---

## ✅ Concluídas e integradas em `feat`

### 1. ast-simplification (Fases 1–7)
Refator completo de parser/AST. Commits `98eac26` → `5a89d88` (helpers de construção,
unificação de blocos, operadores binários table-driven, achatamento de `BinOp`/`UnaryOp`/`Loop`,
fusão `lambda`/`fnExpr` em `FunctionExpr`, unificação do preâmbulo de declaração, fusão de
variantes de pattern). Marcada done em `4538bf1`.

### 2. import-rework (F0–F2)
Sintaxe `import {A, X*} [from "name"]`. Commit `a0c77f1` (parse + ativação de dispatch via `*`).

### 3. use-await-prefix (F3)
Operadores prefixos `use` e `await`. Entregue de forma distribuída: `useHook` em `a42d948`,
suporte a use-hook em `3d00c0a`, e o token/prefixo `await` junto da entrega de async-generators.

### 4. implement-extend-decls (F4–F5)
`implement` nomeado (shorthand) + declarações `extend`. Commit `274da22`, done em `63da4ee`.

### 5. context-inference (F7)
Inferência de capacidade `@Context<B, R>` (regras de `use`). Commit `f78a5fc` (+ validação e testes).

### 6. throw-check
Type-check de `throw` contra o `E` do `@Result<D, E>` da função envolvente. Commit `5ed68d9`.

### 7. trycatch-lowering
Lowering de `try`/`catch` para pattern-match Ok/Error em **todos** os backends
(CommonJS, Erlang, BEAM ASM, WAT). Commit `b108139`.

### 8. typeparam
Constraints de typeparam (`comptime f: typeparam A | B`) — parse, inferência, validação,
especialização. Commit `21b23be`.

### 9. async-generators
`*fn`, `await`, `yield :label`, `loop await`, iteradores. Commits `f6a0d62` (front-end),
`ffad0fb` (validação de inferência), `3ee8e44` (lowering Erlang/BEAM/WAT), `3746eae` (LSP).

### 10. erlang-gaps
Lowering de chamadas module-qualified + fechamento de lacunas em patterns de `case`. Commit `38117cb`.

### 11. interface-coverage (Fases 1–4)
Conforme `.tasks/interface-coverage/TODO.md` (Status: *done — all four phases*):
- ✅ Fase 1 parser, Fase 2 inferência, Fase 4 codegen (struct→class, record→constructor,
  Erlang map+acessores, BEAM/WAT) — em boa parte já pré-existentes.
- ✅ Fase 3 validação semântica — passe `validateProgram` (commit `e10b01b`):
  `missingMethod`, `unknownMethod`, `unknownInterface`, `ambiguousMethod` + getters/setters.
- Nota: o **dispatch externo** de métodos (`obj.m()` → `Sym.m(obj)`) NÃO faz parte desta task —
  vive em `extension-dispatch` (ver §14, não mesclada).

---

## 🔶 Parcialmente concluídas (em `feat`)

### 12. beam-asm
- ✅ Fases 1–2 + ranges via `lists:seq/2` + try/catch em posição de statement (commit `5a9302b`,
  além de `1705da2`, `d090e36`).
- ⏳ Pendentes: Fase 3 (strings/binaries), 4 (records/structs), 5 (enums), 6 (closures/lambdas),
  7 (ranges completos), 8 (try/catch completo), 9 (polish).

---

## 🟡 Implementadas, mas **ainda fora do `feat`** (aguardando integração)

> Estas têm código pronto na branch, mas não foram mescladas em `feat`. Cada uma vive
> também como worktree em `.tasks/`.

### 13. stdlib-result — `.tasks/stdlib-result/TODO.md` (Status: done)
Métodos de `@Result` / `@Option` (`map`, `flatMap`, `unwrapOr`, `isOk`/`isError`, espelho `@Option`).
Trouxe junto um subsistema de **method-call**: `CallExpr.receiver` virou expressão (cadeias
`a().map(f).unwrapOr(0)`), inferência registra lowerings em `Env.method_lowerings` (keyed por loc),
e o `transform` reescreve para builtins `__bp_<domain>_<op>(...)`.
- ✅ Todos os 5 passos + 9 cenários de teste.
- ⚠️ Codegen: **CommonJS e Erlang** emitem a forma inline correta; **BEAM e WASM** emitem um
  **stub documentado** (sem representação de runtime de `Result` / inlining de ordem superior ainda).
- Branch `task/stdlib-result` (`5f279b5`). **Worktree de integração:**
  `.tasks/_integrate-stdlib-result` (branch `integrate/stdlib-result`), onde foi combinada com as
  demais features; contém alterações **não commitadas** em `CHANGELOG.md` e `docs.md`.

### 14. extension-dispatch (F6) — `.tasks/extension-dispatch/TODO.md` (Status: implemented ✅)
Dispatch estático de extensões (modelo Rust/C#): `obj.m()` só resolve se a impl/extensão estiver
**ativada** (`X*` no import ou `X*;`). Sintaxe `import {A, X*, B as C}`, `Name*;`, `val Name = extend T {…}`.
- ✅ Inferência: todos os 8 passos (set de ativação, tabela `env.extensions`, resolução
  inherent→activated→erro, chamadas qualificadas, mensagens de erro). Reescritas keyed por loc
  em `env.dispatchRewrites`.
- ✅ Codegen **CommonJS** completo (impl/extend → objeto namespace; `obj.m()` → `Sym.m(obj)`).
- ⏳ Codegen **Erlang / BEAM / WAT / TypeScript**: as decls compilam, mas a reescrita do call-site
  é **follow-up**.
- ⚠️ Nesta branch a suíte de snapshots não está ligada ao `zig build test` (root = `root.zig`);
  snapshots gerados rodando a suíte direto.
- Pontos em aberto: orphan rule (P2), re-export de `pub import` (P3), escopo de `X*` (P4).
- Branch `task/extension-dispatch` (`fb43ef2`). Pré-requisito do dispatch externo de interface-coverage.

### 15. hook-codegen (F8) — `.tasks/hook-codegen/TODO.md`
Lowering de hooks `use` (`val {v, s} = use state(0)` → `useState(0)` no CommonJS; emissão de
interfaces `@Context` no `.d.ts`; apagamento "phantom" do inline implement). Branch
`task/hook-codegen` (`26ee8a5`), construída sobre context-inference (F7).

### 16. tooling — `.tasks/tooling/TODO.md` (Status: done)
- ✅ **LSP**: go-to-definition de símbolos importados, autocomplete de campos de struct/record e de
  variantes de enum, diagnósticos (squiggles) de erro de tipo.
- ✅ **Formatter**: `@Result<D, E>`, `comptime` com constraints, inline `struct implement @Context<B, R>`.
- ✅ **Lambdas**: anotação de tipo completa `val f: fn(string,i32)->string = {…}` com inferência de params.
- ✅ **Pattern matching**: nested patterns (`Ok(Some(n))`), guard clauses (`case x { n if n>0 -> … }`
  com parser/AST/inferência/formatter/CommonJS; guard codegen erlang/beam/wasm segue o roadmap deles).
- 🔶 **Exaustividade de `case`**: parcial (pré-existente) — só rejeita um único arm não-wildcard;
  análise de cobertura completa é trabalho futuro.
- Branch `task/tooling` (`464ce4c`).

---

## ⛔ Não iniciada

### 17. wat-features
A branch `task/wat-features` está parada em `3d00c0a` (commit base do roadmap), sem trabalho próprio.
As features previstas (destructure, pipeline lowering, string ops, layout de enum/record em memória
linear, try/catch tag-based) **não foram implementadas** — o try/catch em WAT que existe veio de
`trycatch-lowering`, não desta task.

---

## Worktrees `.tasks/`

O projeto usa um worktree por task em `.tasks/`. Estado atual (`git worktree list`):

| Worktree | Branch | Commit | Observação |
|---|---|---|---|
| `_integrate-stdlib-result` | `integrate/stdlib-result` | `b02829b` | integração; alterações não commitadas |
| `async-generators` | `task/async-generators` | `821019c` | trabalho já em `feat` (rebaseado) |
| `extension-dispatch` | `task/extension-dispatch` | `fb43ef2` | fora do `feat` |
| `f6-dispatch` | `f6-dispatch` | `ad2fa44` | antigo tip pré-rebase do `feat` |
| `hook-codegen` | `task/hook-codegen` | `26ee8a5` | fora do `feat` |
| `interface-coverage` | `task/interface-coverage` | `e10b01b` | já em `feat` |
| `stdlib-result` | `task/stdlib-result` | `5f279b5` | fora do `feat` |
| `tooling` | `task/tooling` | `464ce4c` | fora do `feat` |
| `use-await-prefix` | `task/use-await-prefix` | `3d00c0a` | já em `feat` |
| `wat-features` | `task/wat-features` | `3d00c0a` | não iniciada |
| (vários `prunable`) | … | … | branches já em `feat`, worktrees podáveis (`git worktree prune`) |

> Cada worktree em `.tasks/{name}/` carrega seu próprio `TODO.md` no estado do tip da branch —
> é a fonte granular (checkboxes por passo) usada para montar este documento. Os worktrees
> `prunable` (branches já em `feat`) podem ser limpos com `git worktree prune`.

## Próximos passos sugeridos

1. **Integrar ao `feat`** as 4 features prontas em branch: `tooling`, `stdlib-result`,
   `extension-dispatch` (F6) e `hook-codegen` (F8) — respeitando dependências
   (`context-inference`, já em `feat`, habilita `hook-codegen`).
2. **Completar codegen** dos backends pendentes: dispatch externo Erlang/BEAM/WAT/TS
   (`extension-dispatch`) e runtime real de `@Result`/`@Option` em BEAM/WASM (`stdlib-result`).
3. **Avançar beam-asm** Fases 3–9 (strings, records, enums, closures, polish).
4. **Implementar wat-features** do zero.
5. **Exaustividade de `case`** (análise de cobertura completa) — pendente em `tooling`.
