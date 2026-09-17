# Fronts — 1.0.3-beta

## Ownership

| Front | Source it owns | Snapshots it owns | Spec |
|---|---|---|---|
| **F1 dead-keywords** | `compiler-core/src/lexer.zig`, `lexer/token.zig`, `parser.zig` (`isMemberName`), `lexer/tests/**`, `parser/tests/{errors,declarations}.zig`, `codegen/js/ts_emitter.zig` (escape) · `language-server/src/engine.zig` (keyword tables) · `vscode-extension/syntaxes/botopink.tmLanguage.json` · `jhonstart/src/{router,server}.d.bp` | one new commonJS snapshot (`.d.ts` escape) | [`01-dead-keywords/`](./01-dead-keywords/README.md) |
| **F2 surface-cutover** | `compiler-core/src/**`, `language-server/src/**` (compile-level), `compiler-cli/src/cli/resolver.zig`, `libs/std/**`, `examples/**` | `compiler-core/snapshots/**` (2442 files), LSP snapshots | [`02-surface-cutover/`](./02-surface-cutover/README.md) |
| **F3 ecosystem-migration** | `repository/{emilia,erika,jhonstart,onze,rakun}/**`; their submodule pointers in the meta repo | the libraries' own test outputs | [`03-ecosystem-migration/`](./03-ecosystem-migration/README.md) |
| **F4 tooling-and-docs** | `language-server/src/engine.zig` (user-facing texts, completions, symbol kinds) · `repository/vscode-extension/**` · botopink-lang user docs | LSP hover/completion/symbol snapshots | [`04-tooling-and-docs/`](./04-tooling-and-docs/README.md) |

## Conflict matrix

`yes` = may run at the same time. `no` = must be sequenced.

|  | F1 | F2 | F3 | F4 |
|---|---|---|---|---|
| **F1** | — | no¹ | no² | no³ |
| **F2** | no¹ | — | no⁴ | no⁵ |
| **F3** | no² | no⁴ | — | yes |
| **F4** | no³ | no⁵ | yes | — |

¹ F1 and F2 both edit `lexer.zig`, `lexer/token.zig`, `parser.zig` and `language-server/src/engine.zig`. **Sequence: F1 first** — it is small and ready.
² F1 edits `jhonstart/src/{router,server}.d.bp`, which F3 migrates. Sequence: F1 first (F3 follows F2 anyway).
³ F1 and F4 both edit `engine.zig` keyword lists and the tmLanguage grammar. Sequence: F1 first.
⁴ No shared file, but a **compiler dependency**: the libraries only compile against F2's compiler. F2 merges first.
⁵ F2 and F4 both edit `language-server/src/engine.zig` (F2 to compile, F4 for user-facing text) and LSP snapshots. Sequence: F2 first.

F3 and F4 share nothing: F3 owns the five library repositories, F4 owns the language server texts,
the VS Code extension and botopink-lang's own docs.

## Order

```
F1 dead-keywords ──► F2 surface-cutover ──┬──► F3 ecosystem-migration   (5 library worktrees in parallel)
                                           └──► F4 tooling-and-docs
```

Critical path: F1 → F2 → F3 ∥ F4. F2 runs alone; inside it, four commits keep the gate green
(unified AST → dual grammar → migrated sources → old surface removed). F3 fans out into one worktree
per library, all file-disjoint.
