# BEAM ASM — fases restantes

**Branch**: `task/beam-asm`
**Depends on**: nada (independente)
**File**: `beam_asm.zig`

> **Situação (2026-06-02): ✅ Fase 6 (closures) + chamadas module-qualified concluídas.**
> Ao inspecionar o `feat` atual (`3746eae`) verificou-se que as Fases 3–5, 7 e a maior
> parte da 8 **já estavam implementadas** no `beam_asm.zig` (strings, `@print` via
> `io:format`, records como maps via `get_map_elements`/`put_map_exact`, enums como
> tagged tuples + dispatch `is_tagged_tuple`, ranges `lists:seq/2`, try/catch). O TODO
> anterior superestimava o trabalho restante.
>
> **Implementado nesta worktree:**
> - **Fase 6 — closures/lambdas**: aplicação de fun local via `{call_fun, N}`. Cobre
>   tanto `val f = {x -> …}; f(1)` (fun em registrador `y`) quanto `syntax fn`
>   parâmetros (fun em registrador `x`). O fun é carregado em `{x, arity}` **antes**
>   de materializar os argumentos, evitando que um argumento sobrescreva o registrador
>   do fun. Validado com `erlc +from_asm` (`apply(fun(X)->X+100 end) = 110`).
> - **Chamadas module-qualified**: `List.map(xs, f)` → remota `{call_ext, N, {extfunc,
>   list, map, N}}` (`call_ext_last` em tail), espelhando `isModuleRef`/`erlangModule`
>   do backend Erlang. Trailing lambdas (`List.map(xs) { x -> … }`) passam a ser
>   materializadas como fun-argumentos (antes eram descartadas). Validado com
>   `erlc +from_asm` (`lists:map/2 = [3,6,9]`).

## Steps

- [x] **Fase 1–2**: base (já em `feat`)
- [x] **Fase 3**: strings/binaries — `{literal, <<"…">>}`, `@print` via `io:format/2` (já em `feat`)
- [x] **Fase 4**: records/structs — map via `get_map_elements`/`put_map_exact` (já em `feat`)
- [x] **Fase 5**: enums — tagged tuple `{tag, Fields...}` + dispatch `is_tagged_tuple` (já em `feat`)
- [x] **Fase 6**: closures/lambdas — `call_fun` (local + param) e chamadas module-qualified remotas
- [x] **Fase 7**: ranges — `lists:seq/2` (já em `feat`)
- [~] **Fase 8**: try/catch — `is_tagged_tuple` em `{ok,_}`/`{error,_}`, expr + stmt (já em `feat`)
- [ ] **Fase 9**: polish — alocação de registradores, TCO, eliminação de dead code

## Lacunas conhecidas (fora do escopo desta task)

- **Construtores PascalCase** (`Error(...)`, `ApiError(msg: …)`, etc.) emitem
  `%% unresolved local call`. É uma lacuna **cross-backend** — o próprio backend
  Erlang emite `ApiError(<<"…">>)` quebrado. Exige lowering de construtor (tagged
  tuple / map) no transform ou em todos os backends, não só no `beam_asm.zig`.
- **`console.log(...)`** (`%% unresolved method call: log`) — `console` não é um
  módulo botopink; dispatch de método de valor.
- **`import` de fn de outro módulo** (`double/1`) — resolução de import.
- **`%% assign to unknown`** e **`%% unsupported expr in tail position: jump`** —
  pertencem à Fase 9 (polish).

## Examples

### Fase 3 — string + `@print`
```bp
fn greeting() -> string {
    val msg = "hi";
    @print(msg);
    return msg;
}
```
```erlang
%% esperado (BEAM asm)
{put_string, {string, "hi"}, {x,0}}.
{call_ext, 2, {extfunc, io, format, 2}}.
```

### Fase 5 — enum tagged tuple + dispatch de case
```bp
val Shape = enum { Circle(r: f64), Square(s: f64) };
fn area(sh: Self) -> f64 {
    return case sh {
        Circle(r) -> r * r * 3.14;
        Square(s) -> s * s;
    };
}
```
```erlang
%% {circle, R} / {square, S} — dispatch via is_tagged_tuple
```

## Test scenarios

```
beam ---- string literal via put_string + io:format (Fase 3)
beam ---- binary concat de duas strings (Fase 3)
beam ---- record com 2 campos → put_map_assoc + acesso (Fase 4)
beam ---- enum unit → atom; payload → tagged tuple (Fase 5)
beam ---- dispatch de case por tag via is_tagged_tuple (Fase 5)
beam ---- lambda capturando var → make_fun3 + apply (Fase 6)
beam ---- range 0..10 → lists:seq/2 (Fase 7)                ✅
beam ---- try/catch → try/try_end/try_case (Fase 8)         ~ parcial
beam ---- tail call em fn recursiva → call_only (Fase 9)
beam ---- dead code após return eliminado (Fase 9)
```
