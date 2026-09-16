# Specs — 1.0.3-beta

Consolidation of the type-system surface: `record` and `enum` collapse into a single `type`
keyword, and `interface` becomes `behavior`. The language keeps the same expressive power —
named fields, variants with payloads, sections, generics, `implement`, methods — but with two
keywords instead of four. The previous milestone (1.0.2-beta) stabilised the backends and the
checker; this one spends that stability on the largest syntactic change since the comptime
rewrite.

| # | Spec | Priority | What |
|---|------|----------|------|
| 01 | [`01-type-keyword/`](./01-type-keyword/README.md) | critical | `record` and `enum` become `type`. The parser distinguishes fields (record) from variants (enum) by the shape of the body. |
| 02 | [`02-behavior-keyword/`](./02-behavior-keyword/README.md) | critical | `interface` becomes `behavior`. Pure rename; no semantic change. |
| 03 | [`03-dead-keywords/`](./03-dead-keywords/README.md) | medium | Remove 7 unused keywords (`auto`, `derive`, `macro`, `get`, `opaque`, `private`, `set`). They become valid identifiers. |

## Waves

### Wave 0 — parser + AST (blocking, run alone)

The lexer, parser and AST are the foundation every other layer reads. Nothing else can move
until `type` and `behavior` are the only accepted surface and the old keywords are gone.

| Row | Owns | Closes |
|---|---|---|
| parser + AST | `lexer/**`, `parser/**`, `ast.zig` | spec 01 + spec 02: `type` replaces `record`/`enum`, `behavior` replaces `interface` |

### Wave 1 — comptime + formatter (parallel, 2 rows)

| Row | Owns | Closes |
|---|---|---|
| comptime | `comptime/**` | `registerRecord`/`registerEnum` accept the new `TypeDecl` node; record-literal expression uses `type { … }` |
| formatter | `format.zig`, `format/tests/**` | round-trip: `format(parse(src))` re-parses to the same AST under the new keywords |
| dead keywords | `lexer/token.zig`, `lexer.zig` | remove 7 unused keywords; they become valid identifiers |

### Wave 2 — backends + cross-module (parallel, 4 rows)

Each backend owns its own snapshot directory, so they are file-disjoint.

| Row | Owns | Closes |
|---|---|---|
| commonJS | `codegen/commonJS.zig`, `snapshots/codegen/commonJS/` | `buildRecord`/`buildEnum` read the unified `TypeDecl` |
| erlang | `codegen/erlang.zig`, `snapshots/codegen/erlang/` | `recordForms`/`enumForms` read the unified `TypeDecl` |
| beam | `codegen/beam_asm.zig`, `snapshots/codegen/beam/` | `emitRecord`/`emitEnum` read the unified `TypeDecl` |
| wasm | `codegen/wat.zig`, `snapshots/codegen/wasm/` | `lowerRecordCtor`/`lowerEnumCtor` read the unified `TypeDecl` |

### Wave 3 — libraries + migration (parallel, 2 rows)

| Row | Owns | Closes |
|---|---|---|
| std + libs | `libs/std/**`, `repository/{emilia,erika,jhonstart,onze,rakun}/**` | every `.bp` file migrated; `zig build test-libs` green |
| tooling | `modules/compiler-cli/**`, `modules/language-server/**`, `repository/vscode-extension/**` | LSP completions, syntax highlighting, error messages use the new keywords |

## Dependencies

```
wave 0 (parser + AST)
  ├──► wave 1 (comptime · formatter)
  │      └──► wave 2 (commonJS · erlang · beam · wasm)
  └──► wave 3 (std + libs · tooling)   — can start once wave 1 lands, in parallel with wave 2
```

Wave 0 first is not a preference: the AST node change ripples through every layer, so no
downstream work can start until the parser produces the new shape.

## Rules carried from 1.0.2-beta

- **A backend builds a model, an emitter renders it.** The unified `TypeDecl` feeds the same
  per-backend models; the lowering does not change, only the AST node it reads from.
- **The gate is a cold runtime cache.** The migration touches every snapshot directory, so
  the gate must re-record from a cold cache after wave 2.
- **A snapshot is evidence, not a baseline.** Re-record only after running the program; the
  keyword rename must not alter runtime output.
