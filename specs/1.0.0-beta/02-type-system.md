# Spec 02 — Type System

**Prioridade:** 🟡 MÉDIA — não bloqueia testes verdes
**Depende de:** Spec 01 (comptime eval funcionando no erl)

---

## Objetivo

Tipos como valores comptime avaliados de verdade (não só resolvidos por casos especiais na
inferência), construção de tipos via `#[@code]`, funções de tipo da std escritas em `.bp`,
e narrowing completo.

---

## O que já existe

Caminhos relativos a `repository/botopink-lang/modules/compiler-core/src/`.

- **Builtins de inferência** (`comptime/infer.zig`): `@typeInfo(T)` → tipo `TypeInfo`,
  `@TypeOf(v)`, `@makeRecord(fields)`, `@RecordKeys(T)`, `@field(v, name)`,
  `@comptimeError(msg)`. Resolvem **tipos** na inferência; não calculam valores.
- **Funções de tipo por nome** (`infer.zig` `tryResolveTypeManipulationCall`): `mergeRecords`,
  `mapFields`, `partial`, `omit`, `pick` são reconhecidas pelo nome e resolvidas em Zig.
  `libs/std/src/types.bp` declara `mapFields`/`partial`/`omit`/`pick` sobre `@makeRecord`,
  mas os corpos não são executados.
- **Testes** `comptime/tests/builtins_typeinfo.zig` (31): typeInfo, TypeOf, makeRecord,
  RecordKeys, field, comptimeError, mergeRecords, partial, omit, pick.
- **Type guards**: o parser aceita `-> x is T` (`FnDecl.typeGuardParam`, `parser/decls.zig`).
- **Narrowing**: `comptime/tests/narrowing.zig` (19 testes: null-check, `case` em Result/enum,
  OR patterns, guards, `assert … is`, early return, type guard, `&&`, `?.`, `else if`) e
  `codegen/tests/narrowing.zig` (11 testes com RUN LOG).

---

## Pendente

### Part A — Tipos como valores

| Step | O que | Aceitação |
|---|---|---|
| 1 | `type` como valor comptime de primeira classe: `val T = i32`, `comptime T: type`, retorno `-> type` | usável como anotação, valor, parâmetro e retorno |
| 2 | `#[@code]` em fn: o `TypeInfo` retornado vira o tipo no call site (`val p: Point() = Point()(x: 1, y: 2)`), inclusive com parâmetros comptime | parse da anotação + lifting + construtor utilizável |
| 3 | `@typeInfo`/`@TypeOf` produzem **valores** (`TypeInfo.Record(fields: [...])`, `TypeInfo.Optional(inner: …)`) | valores corretos para primitivos, record, enum, optional, array |
| 4 | Loop de eval comptime para fns `.bp` com params `comptime` (`if`, `loop`, `break` com valor de tipo), sobre o eval no erl da Spec 01 | fns de `types.bp` executadas, não resolvidas por nome |
| 5 | Std em `.bp`: `mergeRecords`, `partial`, `omit`, `pick` com `#[@code]`; `recordKeys`, `field` como fns sobre `@typeInfo`. Remover `tryResolveTypeManipulationCall` e os builtins `@makeRecord`/`@RecordKeys`/`@field` | testes de `builtins_typeinfo.zig` passando sem os casos especiais |

### Part B — Narrowing

| Step | O que | Aceitação |
|---|---|---|
| 6 | Auditar os 13 padrões contra os testes existentes e fechar lacunas (ex.: narrowing no `else` de null-check, type guard em cadeia `else if`) | cada padrão com teste positivo; erros de narrowing com snapshot |
| 7 | Cobertura de codegen de narrowing nos 4 backends | ≥1 teste com RUN LOG por padrão relevante em runtime |

Part B é independente de Part A. Steps 2–5 e Part B mexem em `comptime/infer.zig` — evitar
paralelizá-los na mesma branch.

---

## Pontos em aberto

- `@code("…")` já existe como builtin de template (parse de texto em código); confirmar que o
  nome da anotação `#[@code]` não conflita ou escolher outro.
