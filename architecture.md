# Arquitetura: avaliação comptime na VM Erlang

Visão geral de como o compilador (`repository/botopink-lang/modules/compiler-core/src/`)
executa código em tempo de compilação. Detalhes de cada arquivo ficam nos `AGENTS.md`
das pastas citadas; o plano de trabalho em andamento está em [`todo.md`](todo.md).

## Runtime único: `erl` persistente

Todo código comptime roda num processo `erl` de longa duração, um por processo do
compilador (`comptime/runtime/`):

| Arquivo | Papel |
|---|---|
| `persistent_erl.zig` | Sobe o `erl` (servidor `botopink_comptime_server`) sob demanda. Protocolo binário com frames `<u32 BE len>` nos dois sentidos: cmd 1 compila+roda um `.erl`, cmd 2 carrega+roda um `.beam`. `main/0` roda num processo monitorado com timeout de 10s. `evalDetailed` devolve `ok` / `compile_error` / `load_error` / `runtime_error` com a mensagem. stderr do `erl` vai para `.botopinkbuild/tmp/persistent_erl/erl.stderr.log`. |
| `erl_prelude.zig` | Módulo `botopink_comptime_prelude`: walkers de descritor (`lookup`, `bindings`, `context`, `parts`) e host fns de templates. |
| `beam.zig` | Valores `comptime`: `renderExprValue` dobra cada expressão em Zig, `buildScript` embute o resultado em `main/0`, o script roda no `erl` (cache de `.beam`) e `parseResults` converte de volta. |

Não há runtime Node, wasm3 ou WAT para comptime.

## Camada de termos BEAM compartilhada

`codegen/beam/` concentra a escrita de valores e nomes Erlang, usada pelos dois backends
da VM BEAM e pelo comptime:

```
                   codegen/beam/term.zig  (Term: atom, binary, integer, float,
                     /                     boolean, nil, list, tuple, map)
 codegen/beam/erl_emitter.zig           codegen/beam/beam_emitter.zig
 Term + nomes → fonte Erlang            Term → operandos BEAM asm (.S)
     ↑                ↑                          ↑
 codegen/erlang.zig   comptime/decorator_eval   codegen/beam_asm.zig
```

- Uma regra de quoting de átomos (reservadas e nomes não minúsculos sempre quotados).
- `writeBinaryFromBytes` para dados de runtime; `writeBinaryFromLexeme` para literais
  vindos do lexer.
- `beam_emitter` delega o conteúdo de `{literal, …}` ao `erl_emitter`.

## `codegen/erlang.zig` em modo comptime

- `emitComptimeModule(alloc, module_name, program, ComptimeModule{ host_enums, exports, tail })`
  emite um `ast.Program` não tipado como módulo Erlang avaliável: `host_enums` faz
  `DeclKind.Record` virar átomo, `exports` adiciona `main/0`, `tail` recebe host fns e a
  entrada.
- Sem tipos, lowerings dependentes de tipo despacham em runtime: `+` → `'__bp_add'/2`,
  `.len`/`.length` → `'__bp_len'/2`.
- Todo o backend Erlang versiona variáveis religadas na mesma função
  (`Count = 0, Count@1 = Count + 1`), cobrindo `=`, `+=` e sombreamento.

## Avaliadores

| Avaliador | Estado atual |
|---|---|
| Decorators (`comptime/decorator_eval.zig`) | `infer.zig` monta um `DeclHandle`; `handleToTerm` o converte em `Term`. O corpo do decorator ainda é traduzido por um emitter manual (`emitExpr`/`emitStmt`) que não cobre `if`, métodos, enums, lambdas e concatenação — os módulos gerados não compilam. Resultado volta como JSON (`{kind, …}`) lido via `std.json.Value`. |
| Templates (`comptime/template_eval.zig`) | Decompila o corpo para botopink sintético (`emitBpBody`), roda o pipeline `compile()` + codegen Erlang e executa no `erl`. Host methods `#[@Host]` de `template_runtime.bp` são reescritos por `patchHostMethods` (`comptime.zig`). Falha hoje com `parse failed for module 'template_body'`. |
| Valores comptime (`comptime/runtime/beam.zig`) | Funcional; a ida ao `erl` é redundante porque os valores já são calculados em Zig. |

Destino (fases F3–F5 do `todo.md`): decorators e templates emitidos por
`erlang.emitComptimeModule` com handle/captures como `Term`, sem emitter manual nem
decompilador; `beam.zig` sem ida ao `erl`.
