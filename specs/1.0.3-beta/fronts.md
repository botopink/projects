# Fronts — 1.0.3-beta

## Ownership

| Front | Source it owns | Snapshots it owns | Spec rows |
|---|---|---|---|
| **F1 parser + AST** | `lexer/token.zig`, `lexer.zig`, `parser/**`, `ast.zig` | — | spec 01 steps 1–4, spec 02 steps 1–2 |
| **F2 comptime** | `comptime/types.zig`, `comptime/env.zig`, `comptime/infer.zig`, `comptime/transform.zig` | `snapshots/comptime/` | spec 01 step 5 |
| **F3 formatter** | `format.zig` | `snapshots/format/` | spec 01 step 6, spec 02 step 3 |
| **F4 dead keywords** | `lexer/token.zig`, `lexer.zig` | `snapshots/lexer/` | spec 03 steps 1–4 |
| **F5 commonJS** | `codegen/commonJS.zig`, `codegen/typescript.zig`, `codegen/js/**` | `snapshots/codegen/commonJS/`, `snapshots/codegen/typescript/` | spec 01 step 7a |
| **F6 erlang** | `codegen/erlang.zig`, `codegen/beam/erl_ast.zig`, `codegen/beam/erl_emitter.zig` | `snapshots/codegen/erlang/` | spec 01 step 7b |
| **F7 beam** | `codegen/beam_asm.zig`, `codegen/beam/beam_emitter.zig` | `snapshots/codegen/beam/` | spec 01 step 7c |
| **F8 wasm** | `codegen/wat.zig`, `codegen/wat/**` | `snapshots/codegen/wasm/` | spec 01 step 7d |
| **F9 std + libs** | `libs/std/**`, `repository/{emilia,erika,jhonstart,onze,rakun}/**/*.bp` | — | spec 01 step 8, spec 02 step 4 |
| **F10 tooling** | `modules/compiler-cli/**`, `modules/language-server/**`, `repository/vscode-extension/**` | — | spec 01 step 9, spec 02 step 5 |

## Conflict matrix

|  | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | F9 | F10 |
|---|---|---|---|---|---|---|---|---|---|---|
| **F1** | — | no¹ | no¹ | no² | no¹ | no¹ | no¹ | no¹ | no¹ | no¹ |
| **F2** | no¹ | — | no³ | no³ | no³ | no³ | no³ | no³ | no³ | no³ |
| **F3** | no¹ | no³ | — | no⁴ | yes | yes | yes | yes | yes | yes |
| **F4** | no² | no³ | no⁴ | — | yes | yes | yes | yes | yes | yes |
| **F5** | no¹ | no³ | yes | yes | — | yes | yes | yes | yes | yes |
| **F6** | no¹ | no³ | yes | yes | yes | — | yes | yes | yes | yes |
| **F7** | no¹ | no³ | yes | yes | yes | yes | — | yes | yes | yes |
| **F8** | no¹ | no³ | yes | yes | yes | yes | yes | — | yes | yes |
| **F9** | no¹ | no³ | yes | yes | yes | yes | yes | yes | — | yes |
| **F10** | no¹ | no³ | yes | yes | yes | yes | yes | yes | yes | — |

¹ F1 owns `ast.zig` and `parser/**` — every other front reads the AST. F1 must land first.
² F4 owns `lexer/token.zig` and `lexer.zig` — F1 also touches these files. F1 and F4 must be sequenced or merged.
³ F2 owns `comptime/**` — F3–F10 read the typed AST that comptime produces. F2 must land before F3–F10.
⁴ F3 and F4 both touch `lexer/**` — they must be sequenced or merged into one front.

## Order

```
F1 (parser + AST) ──┬──► F2 (comptime) ──┬──► F3 (formatter) ──┐
                    │                    ├──► F5 (commonJS)    ├──► F9 (std + libs) ──► F10 (tooling)
                    │                    ├──► F6 (erlang)      │
                    │                    ├──► F7 (beam)        │
                    │                    └──► F8 (wasm) ───────┘
                    └──► F4 (dead keywords)
```

F1 is the critical path. F2 is the second bottleneck. F4 (dead keywords) can run in parallel
with F2 since they touch different files (F4: lexer only, F2: comptime). F5–F8 run in parallel
(snapshot-disjoint). F9 starts once F2 lands (it needs comptime to compile the migrated `.bp`
files). F10 lands last (LSP and extension need the compiler to be stable).
