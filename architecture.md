# Arquitetura: avaliação comptime no runtime wasm

Visão geral de como o compilador (`repository/botopink-lang/modules/compiler-core/src/`)
executa código em tempo de compilação. Detalhes de cada arquivo ficam nos `AGENTS.md`
das pastas citadas; o trabalho pendente está em [`specs/milestone/`](specs/milestone/README.md).

## O que roda onde

| Código comptime | Onde |
|---|---|
| `val x = comptime …` | Dobrado em Zig por `comptime/eval.zig` (literais, aritmética inteira, `@TypeOf`, valor de `break`). Nenhum runtime. Snapshots mostram a seção `COMPTIME VALUES` (`ct_N = literal`). |
| Corpos de decorator (`comptime/decorator_eval.zig`) | Módulo Erlang gerado por `erlang.emitComptimeModule` — **um módulo por declaração, não por avaliação** — executado no **runtime wasm**, para todo alvo (decisão 434, `comptime/runtime/runtime.zig`): o texto Erlang lido de volta, baixado a wasm, ligado à biblioteca de termos embutida (`wat/rt.zig`, com `modules/std-wasm` compilado junto) e executado no wasm3 dentro do processo do compilador, sem spawn. No build do navegador o executor é o motor da página (`bp_host`). |
| Corpos de template (`comptime/template_eval.zig`) e blocos `comptime` (`comptime/block_eval.zig`) | Idem. |

Um só runtime: compilar não sobe `erl` e construir o compilador não roda `erlc` (decisão 434). Os
alvos erlang e beam não mudam — `erl` / `erlc` servem só aos testes desses alvos. Os snapshots de
codegen ficam numa árvore só, `snapshots/codegen/<alvo>/`. Não há runtime Node para comptime.

Uma função de host alcançada em comptime responde, nesta ordem (decisão 434 (4)): a implementação
em `modules/std-wasm` (as funções de host da std em Zig, compiladas para wasm); senão a tradução
por `modules/beam-to-wasm` da sua célula `@External.Erlang` / `@External.Beam` (o `.beam` montado
pelo próprio compilador, `comptime/runtime/wat/cells.zig` — um subconjunto medido de opcodes e
BIFs, decisão 435); senão a sua célula `@External.Wasm("fn:…")`; nenhuma → recusada na chamada.

**Duas coisas mudaram em 2026-09-18** (frente `14-comptime-on-beam`, passos 1 e 2):

- **a cola de host é residente**: os dois prelúdios (`comptime/runtime/prelude.zig`) são lidos uma
  vez por processo e cada módulo os alcança por `-import`, em vez de reemiti-los em toda avaliação;
- **a captura viaja como termo ETF**, argumento de `main/1`, em vez de ser um mapa embutido no texto
  do módulo. Como o corpo deixa de depender do valor capturado, **um** módulo serve todos os sítios
  de chamada de uma declaração.

O efeito medido por `repository/botopink-lang/scripts/comptime_bench.sh`: com N=200 avaliações, 200
módulos e 2,8 MB de `.erl` viraram **1 módulo e 875 bytes**.

Até a decisão 434 havia um segundo runtime, o BEAM (um `erl` persistente que recebia o módulo como
bytes `.beam` montados em Zig); ele foi apagado com seus prelúdios compilados por `erlc`. A descida
Erlang → BEAM dele vive como o compilador de templates do alvo beam (`codegen/beam/erl_lower.zig`).

## Camada BEAM compartilhada (`codegen/beam/`)

```
 codegen/beam/term.zig      Term — valores (atom, binary, integer, float, boolean, nil, list, tuple, map)
 codegen/beam/erl_ast.zig   código Erlang — Expr, Clause, Body, Function, Form + Builder
        │                         │
 erl_emitter.zig            beam_emitter.zig
 Term + erl_ast → fonte     Term → operandos BEAM asm (.S)
        ↑                         ↑
 codegen/erlang.zig         codegen/beam_asm.zig
 comptime/decorator_eval
 comptime/template_eval
```

- Uma regra de quoting de átomos (reservadas e nomes não minúsculos sempre quotados).
- `writeBinaryFromBytes` para dados de runtime; `writeBinaryFromLexeme` para literais
  vindos do lexer.
- `codegen/erlang.zig` não escreve texto Erlang: monta nós e formas `erl_ast` e o
  `erl_emitter` renderiza (layout de `case`/`fun`/`try`, separadores de corpo, `-export`).

## `codegen/erlang.zig` em modo comptime

- `emitComptimeModule(alloc, module_name, program, ComptimeModule{ host_enums, host_records, exports, forms })`
  emite um `ast.Program` não tipado como módulo Erlang avaliável: `host_enums` faz
  `DeclKind.Record` virar átomo, `host_records` faz construtores de host virarem mapas,
  `exports` adiciona `main/0`, `forms` recebe as host fns e a entrada como `erl_ast.Form`.
- Sem tipos, lowerings dependentes de tipo despacham em runtime: `+` → `'__bp_add'/2`,
  `.len`/`.length` → `'__bp_len'/2`.
- Todo o backend Erlang versiona variáveis religadas na mesma função
  (`Count = 0, Count@1 = Count + 1`), cobrindo `=`, `+=`, sombreamento e mutação dentro de
  `if`/`loop`/`forEach` (o `case`/`foldl` devolve os novos valores).

## Avaliadores

| Avaliador | Fluxo |
|---|---|
| Decorators | `infer.zig` monta um `DeclHandle`; `handleToTerm` o converte em `Term`. `buildModule` emite `[dfn]` + host forms (`fail/2`, `failAt/3`, `compilerError/1`, `emit/1`, `main/0`); o módulo é nomeado pelo hash do código. `main/0` responde JSON `{kind, contributions \| message, span}` e `parseOutcome` o converte em `Outcome`. |
| Templates | Captures `@Expr` viram `Term` (`captureToTerm`); host forms (`text`, `parts`, `lookup`, `build`, `custom`, `fail`, …) e `main/0` montados com `Builder`. `parseOutcome` converte a resposta em `code` / `value` / `custom` / `capture` / `fail`. |
