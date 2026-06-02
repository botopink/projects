# Hook codegen (`use`)

**Branch**: `task/hook-codegen`
**Phase**: F8
**Depends on**: `feat/context-inference` (F7) — ✅ já mesclada em `feat`

> **Situação (2026-06-02): ✅ integrada com `feat` nesta branch.**
> Commit `26ee8a5` ("feat(codegen): lower `use` hooks (F8) — React hooks, phantom erasure")
> + merge de `origin/feat` (`3746eae`) resolvido (conflitos com o trabalho async/try-catch
> já em `feat`). `zig build` e `zig build test` verdes; snapshots regenerados para a
> serialização atual (`isStarFn`/`label`).

## Steps

### CommonJS (alvo React-like) — ✅ feito
- [x] `val {v, s} = use state(0)` → `const {v, s} = useState(0)`
- [x] `val [v, s] = use state(0)` → `const [v, s] = useState(0)`
- [x] `val d = use memo({ -> v*2 })` → `const d = useMemo(() => v*2, [v])` (deps inferidas)
- [x] `use effect({ -> cleanup() })` → `useEffect(() => cleanup(), [])`
- [x] Mapeamento de nome de hook (`state` → `useState`) — convenção `"use" + Capitalize` (ver P1)

### TypeScript `.d.ts` — ✅ feito
- [x] Emitir os tipos de interface `@Context` no `.d.ts`
- [x] ContextBase apagado (phantom) — nenhum código emitido para o tipo fantasma

### Erlang / BEAM / WAT — ⏳ follow-up
- [ ] Erlang: `use` → slot no process dictionary ou estado de gen_server
- [ ] BEAM ASM: `use` → gerência de slot de hook
- [ ] WAT: `use` → load/store em offset fixo na memória linear

> O foco da branch é o alvo CommonJS (React) + erasure do inline implement; o gerenciamento
> de estado de `use` em Erlang/BEAM/WAT permanece como trabalho futuro.

## Test scenarios

```
codegen ---- val {v,s} = use state(0) → const {v,s} = useState(0)        ✅
codegen ---- val [v,s] = use state(0) → const [v,s] = useState(0)        ✅
codegen ---- val d = use memo(...) → const d = useMemo(..., [deps])      ✅
codegen ---- use effect() → useEffect(() => …, [])                       ✅
codegen ---- inline implement apagado em runtime (sem código p/ phantom)  ✅
```

## Open point
- **P1**: nome de hook específico de framework. `state` → `useState` via convenção
  (`"use" + Capitalize`) ou tabela de config?
