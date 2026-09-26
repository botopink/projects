# Arquitetura: avaliação comptime na VM Erlang

Visão geral de como o compilador (`repository/botopink-lang/modules/compiler-core/src/`)
executa código em tempo de compilação. Detalhes de cada arquivo ficam nos `AGENTS.md`
das pastas citadas; o trabalho pendente está em [`specs/1.0.5-beta/`](specs/1.0.5-beta/overview.md).

## O que roda onde

| Código comptime | Onde |
|---|---|
| `val x = comptime …` | Dobrado em Zig por `comptime/eval.zig` (literais, aritmética inteira, `@TypeOf`, valor de `break`). Nenhum runtime. Snapshots mostram a seção `COMPTIME VALUES` (`ct_N = literal`). |
| Corpos de decorator (`comptime/decorator_eval.zig`) | Módulo Erlang gerado por `erlang.emitComptimeModule` — **um módulo por declaração, não por avaliação** — executado no runtime do alvo (decisão 84, `comptime/runtime/runtime.zig`): alvo `erlang`/`beam` (ou nenhum alvo, como no LSP) no **runtime BEAM** — o `erl` persistente, que recebe o módulo já como bytes `.beam` montados em Zig (o texto Erlang lido de volta, baixado a instruções BEAM por `comptime/runtime/beam/` e montado por `codegen/beam/beam_file.zig`; nenhum `compile:file`, nenhum `.erl` em disco); alvo `commonJS`/`wasm` no **runtime wat** — o mesmo texto Erlang lido de volta, baixado a wasm, ligado à biblioteca de termos embutida (`wat/rt.zig`) e executado no wasm3 dentro do processo do compilador, sem spawn. No build do navegador o executor do runtime wat é o motor da página (`bp_host`). |
| Corpos de template (`comptime/template_eval.zig`) | Idem. |

Os dois runtimes rodam o mesmo programa — o Erlang que o modo não tipado de `erlang.zig` gerou, baixado uma vez a BEAM e uma vez a wasm; a igualdade das respostas é verificada em todo fixture
(`runtime.parity`) e registrada na árvore dobrada `snapshots/codegen/{beam,wat}/`, auditada par a par
(`snap_audit.sh --mode=runtime-parity`). Não há runtime Node para comptime.

**Duas coisas mudaram em 2026-09-18** (frente `14-comptime-on-beam`, passos 1 e 2), e a tabela acima
já as reflete:

- **a cola de host é residente**: ela é compilada uma vez no warmup do servidor e cada módulo a
  alcança por `-import`, em vez de ser reemitida em toda avaliação;
- **a captura viaja como termo ETF**, argumento de `main/1`, em vez de ser um mapa embutido no texto
  do módulo. Como o corpo deixa de depender do valor capturado, **um** módulo serve todos os sítios
  de chamada de uma declaração.

O efeito medido por `repository/botopink-lang/scripts/comptime_bench.sh`: com N=200 avaliações, 200
módulos e 2,8 MB de `.erl` viraram **1 módulo e 875 bytes**, e o lado erl do `erika-linq`
(compilar + carregar) caiu de 1 039 ms para **49 ms**.

**Passo 3 (2026-09-26)**: o módulo chega ao nó como bytes BEAM (cmd 4) e não como fonte — a
compilação do módulo do `erika-linq` caiu de 49,1 ms (`compile:file`) + 1,4 ms (load) para 2,9 ms
em Zig (ReleaseSafe) + 0,6 ms de `code:load_binary`. O que a descida não aceita é erro de compilação
nomeando a construção, como no runtime wat.

## `erl` persistente

`comptime/runtime/persistent_beam.zig` sobe o `erl` (servidor `botopink_comptime_server`)
sob demanda, um por processo do compilador. Protocolo binário com frames `<u32 BE len>`
nos dois sentidos: o cmd 4 carrega bytes `.beam`, o cmd 3 chama `main/1` com o argumento ETF.
`main/1` roda num processo monitorado com timeout de 10s. `evalBeamWithArg` devolve `ok` /
`compile_error` / `runtime_error` com a mensagem. O stderr do `erl` vai para
`.botopinkbuild/tmp/persistent_beam/erl.<id>.stderr.log` (herdar o stderr do pai trava o
`zig build test`).

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
