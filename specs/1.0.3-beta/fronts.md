# Fronts — 1.0.3-beta

## Ownership

| Front | Source it owns | Snapshots it owns | Spec |
|---|---|---|---|
| **F1 dead-keywords** | `compiler-core/src/lexer.zig`, `lexer/token.zig`, `parser.zig` (`isMemberName`), `lexer/tests/**`, `parser/tests/{errors,declarations}.zig`, `codegen/js/ts_emitter.zig` (escape) · `language-server/src/engine.zig` (keyword tables) · `vscode-extension/syntaxes/botopink.tmLanguage.json` · `jhonstart/src/{router,server}.d.bp` | one new commonJS snapshot (`.d.ts` escape) | [`01-dead-keywords/`](./01-dead-keywords/README.md) |
| **F2 migration-tooling** | `compiler-cli/src/cli/migrate_syntax.zig` (new), `migrate.zig` + `main.zig` flag wiring, `compiler-cli/tests/**` for it · `scripts/snap_audit.sh` | — (golden files under `compiler-cli/tests`) | [`02-migration-tooling/`](./02-migration-tooling/README.md) |
| **F3 surface-cutover** | `compiler-core/src/**`, `language-server/src/**` (compile-level), `compiler-cli/src/cli/resolver.zig`, `libs/std/**`, `examples/**` | `compiler-core/snapshots/**` (2442 files), LSP snapshots | [`03-surface-cutover/`](./03-surface-cutover/README.md) |
| **F4 ecosystem-migration** | `repository/{emilia,erika,jhonstart,onze,rakun}/**`; their submodule pointers in the meta repo | the libraries' own test outputs | [`04-ecosystem-migration/`](./04-ecosystem-migration/README.md) |
| **F5 tooling-and-docs** | `language-server/src/engine.zig` (user-facing texts, completions, symbol kinds) · `repository/vscode-extension/**` · botopink-lang user docs | LSP hover/completion/symbol snapshots | [`05-tooling-and-docs/`](./05-tooling-and-docs/README.md) |

## Conflict matrix

`yes` = may run at the same time. `no` = must be sequenced.

|  | F1 | F2 | F3 | F4 | F5 |
|---|---|---|---|---|---|
| **F1** | — | yes | no¹ | no² | no³ |
| **F2** | yes | — | no⁴ | no⁴ | yes |
| **F3** | no¹ | no⁴ | — | no⁵ | no⁶ |
| **F4** | no² | no⁴ | no⁵ | — | yes |
| **F5** | no³ | yes | no⁶ | yes | — |

¹ F1 and F3 both edit `lexer.zig`, `lexer/token.zig`, `parser.zig` and `language-server/src/engine.zig`. **Sequence: F1 first** — it is small and ready.
² F1 edits `jhonstart/src/{router,server}.d.bp`, which F4 migrates. Sequence: F1 first (F4 follows F3 anyway).
³ F1 and F5 both edit `engine.zig` keyword lists and the tmLanguage grammar. Sequence: F1 first.
⁴ No shared file, but a **tool dependency**: F3 and F4 run F2's codemod and audit. F2 merges first.
⁵ No shared file, but a **compiler dependency**: the libraries only compile against F3's compiler. F3 merges first.
⁶ F3 and F5 both edit `language-server/src/engine.zig` (F3 to compile, F5 for user-facing text) and LSP snapshots. Sequence: F3 first.

F4 and F5 share nothing: F4 owns the five library repositories, F5 owns the language server texts,
the VS Code extension and botopink-lang's own docs.

## Order

```
F1 dead-keywords ─────┐
                      ├──► F3 surface-cutover ──┬──► F4 ecosystem-migration   (5 library worktrees in parallel)
F2 migration-tooling ─┘                         └──► F5 tooling-and-docs
```

Critical path: F1 ∥ F2 → F3 → F4 ∥ F5. F3 runs alone; inside it, four commits keep the gate green
(unified AST → dual grammar → migrated sources → old surface removed). F4 fans out into one worktree
per library, all file-disjoint.
