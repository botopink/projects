# TODO — Language Server: completion tests parity com Gleam

Contexto: o Gleam tem ~139 testes de completion snapshot em
`language-server/src/tests/completion.rs`. O botopink tem 6.
O objetivo é paridade de **cenários testados** (a sintaxe é outra,
o objeto do teste é o mesmo).

---

## Bloqueadores de infra

### #1 — Fix cursor `↑` rendering em snapshots

**Arquivo:** `modules/language-server/src/tests/snapshot.zig`
`appendSourceWithCursor()`

Problemas identificados:
- Em alguns testes o `↑` não aparece na saída do snapshot.
- A posição pode ficar desalinhada quando o cursor está numa coluna
  maior que o comprimento da linha (edge case de EOL).
- Gleam usa `|` **inline** na mesma linha; botopink usa `↑` em linha
  separada abaixo — essa diferença de estilo precisa ser documentada
  e os casos de falha corrigidos.

Ação:
- [ ] Escrever teste unitário mínimo para `appendSourceWithCursor`
      cobrindo: meio de linha, fim de linha, última linha sem `\n`.
- [ ] Corrigir a lógica para os casos que falham.

---

### #2 — Fix `inferProgramTyped`: imports de `use` somem dos bindings

**Arquivo:** `modules/compiler-core/src/comptime/infer.zig`

Situação atual:
- `resolveImports` já faz `env.bind(name, ty)` para cada símbolo
  importado via `use { foo, bar } from "mylib"`.
- Mas `inferDeclTyped` para `.use` retorna um único binding dummy
  `{ name = "", ... }` — que é filtrado em `completion()` por
  `if (b.name.len == 0) continue`.
- Resultado: símbolos importados **não aparecem no completion** do LSP.

Ação:
- [ ] Em `inferProgramTyped`, tratar `.use` fora do loop genérico:
      para cada `u.imports[i]`, buscar o tipo no env e criar um
      `TypedBinding` real com o nome correto.
- [ ] Remover o binding dummy com `name = ""` do case `.use`.
- [ ] Garantir que `registerExports` continue ignorando `.use`
      (já tem `b.decl == .use` na condição — verificar se ainda vale).

---

### #3 — Helper `h.compileMulti` para testes com múltiplos módulos

**Arquivo:** `modules/language-server/src/tests/helpers.zig`

Situação atual: `h.compile(gpa, source)` aceita apenas 1 source.
Os testes de `use` precisam de pelo menos 2 módulos.

Ação:
- [ ] Adicionar:
  ```zig
  pub fn compileMulti(
      gpa: std.mem.Allocator,
      entries: []const compiler_mod.ModuleEntry,
  ) !CompileHandle
  ```
  Espelha `TestProject.add_module("dep", dep)` do gleam.

---

## Engine guards

### #4 — `completion()`: cursor dentro de string literal → vazio ✅

**Arquivo:** `modules/language-server/src/engine.zig`

Gleam refs: `ignore_completions_inside_string`,
            `ignore_completions_inside_empty_string`,
            `no_completions_in_constant_string`

Ação:
- [x] Implementar `fn cursorInString(source: []const u8, pos: proto.Position) bool`
      — varre source do início rastreando se offset do cursor está
      entre `"..."` (respeitando `\"` escape e não cruzando `\n`).
- [x] Em `completion()`, antes de tudo:
  ```zig
  if (cursorInString(source, pos)) return &.{};
  ```

**Status:** CONCLUÍDO - `cursorInString()` implementado nas linhas 528-545, guard adicionado na linha 485-486.

---

### #5 — `completion()`: cursor dentro de comentário `//` → vazio ✅

**Arquivo:** `modules/language-server/src/engine.zig`

Gleam refs: `ignore_completions_in_empty_comment`,
            `ignore_completions_in_middle_of_comment`,
            `ignore_completions_in_end_of_comment`,
            `no_completion_inside_comment_that_is_more_than_three_lines`

Ação:
- [x] Implementar `fn cursorInComment(source: []const u8, pos: proto.Position) bool`
      — localiza o start-of-line do cursor; varre até o offset do cursor;
      se encontrar `//` fora de string retorna true.
- [x] Em `completion()`:
  ```zig
  if (cursorInComment(source, pos)) return &.{};
  ```

**Status:** CONCLUÍDO - `cursorInComment()` implementado nas linhas 557-593, guard adicionado na linha 489-490.

---

## Testes a portar (completion.zig + snapshots)

Convenção de nome: `C{N}` = número do teste no arquivo botopink.
Testes existentes são C1–C6.

### #6 — Cursor dentro de string → vazio ✅

Depende de: **#4**

| botopink | gleam equivalente |
|---|---|
| C7: `val x = "hel↑lo"` → vazio | `ignore_completions_inside_string` |
| C8: `val x = "↑"` → vazio | `ignore_completions_inside_empty_string` |
| C9: `val x = "io.↑"` → vazio | `no_completions_in_constant_string` |

Snapshots: `completion_cursor_in_string.snap.md`,
           `completion_cursor_in_empty_string.snap.md`,
           `completion_cursor_in_const_string.snap.md`

**Status:** CONCLUÍDO - Todos os 3 testes (C7, C8, C9) implementados e passando.

---

### #7 — Cursor dentro de comentário → vazio ✅

Depende de: **#5**

| botopink | gleam equivalente |
|---|---|
| C10: cursor após `//` sem texto | `ignore_completions_in_empty_comment` |
| C11: cursor no meio de `// comentário` | `ignore_completions_in_middle_of_comment` |
| C12: cursor no final de `// comentário` | `ignore_completions_in_end_of_comment` |

Snapshots: `completion_comment_empty.snap.md`,
           `completion_comment_middle.snap.md`,
           `completion_comment_end.snap.md`

**Status:** CONCLUÍDO - Todos os 3 testes (C10, C11, C12) implementados e passando.

---

### #8 — Prefixo numérico → vazio ✅

Depende de: nenhum (já funciona por coincidência — adicionar teste formal)

| botopink | gleam equivalente |
|---|---|
| C13: cursor sobre `42` em `val x = 42` | `do_not_show_completions_when_typing_a_number` |

Snapshot: `completion_number_prefix.snap.md`

**Status:** CONCLUÍDO - Teste C13 já existia e está passando.

---

### #9 — Shadowing

Depende de: verificar primeiro como o compiler lida com redeclaração

| botopink | gleam equivalente |
|---|---|
| C14: `val x = 1; val x = "hello";` → x é string | `variable_shadowing` |
| C15: `val x = 1; fn foo(x: string) {}` → x no corpo é string | `argument_shadowing` |
| C16: `val x = 1; fn foo(x: string) { val x = true; }` | `argument_variable_shadowing` |

Snapshots: `completion_shadow_val.snap.md`,
           `completion_shadow_param.snap.md`,
           `completion_shadow_param_val.snap.md`

---

### #10 — Imports via `use`

Depende de: **#2**, **#3**

| botopink | gleam equivalente |
|---|---|
| C17: `use {foo} from "mylib"` → foo no completion | `imported_module_function` |
| C18: `use {Foo, bar} from "mylib"` → ambos com tipos | `imported_unqualified_module_function` |
| C19: símbolo não importado do módulo não aparece | `private_function_in_dep` |
| C20: fn importada tem kind=Function | `imported_public_enum` (adaptado) |

Snapshots: `completion_use_single.snap.md`,
           `completion_use_multi.snap.md`,
           `completion_use_not_imported.snap.md`,
           `completion_use_fn_kind.snap.md`

---

## Ordem de execução sugerida

```
Semana 1
  #1  cursor ↑ fix             (snapshot.zig)
  #4  engine: in-string guard  (engine.zig)
  #5  engine: in-comment guard (engine.zig)
  → habilita: #6, #7, #8

Semana 2
  #6  testes string/comment/número
  #9  shadowing (investigar compiler primeiro)

Semana 3
  #2  fix use→TypedBinding     (infer.zig)
  #3  helper compileMulti      (helpers.zig)
  → habilita: #10

Semana 4
  #10 testes de use imports
```

---

## Referência rápida

| Arquivo botopink | Papel |
|---|---|
| `modules/language-server/src/engine.zig` | implementação das features LSP |
| `modules/language-server/src/tests/completion.zig` | testes de completion |
| `modules/language-server/src/tests/snapshot.zig` | infra de snapshots |
| `modules/language-server/src/tests/helpers.zig` | helpers de compilação |
| `modules/language-server/snapshots/lsp/` | arquivos `.snap.md` |
| `modules/compiler-core/src/comptime/infer.zig` | inferência de tipos + TypedBinding |
| `modules/compiler-core/src/comptime.zig` | resolveImports + compileTypesOnly |

| Arquivo gleam (referência) | Papel |
|---|---|
| `language-server/src/tests/completion.rs` | 139 testes de completion |
| `language-server/src/tests/snapshots/gleam_*__completion__*.snap` | snapshots gleam |
