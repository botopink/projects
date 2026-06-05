# std/src

> Path: `libs/std/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

Source for the embedded stdlib — **`.bp`/`.d.bp` only, no Zig**. The loader
(`prelude.zig`) lives in `modules/compiler-core/src/comptime/stdlib/` and
exposes each `.bp` file as a compile-time string consumed by `compiler-core`'s
type inference; the root `build.zig` (`std_bp_files`) maps each file into that
module as an anonymous import.

## Tree

```text
src/
├── AGENTS.md          ← you are here
├── docs.md            ← registry + per-file roles
├── examples.md        ← stdlib usage in `.bp` (Array, String, builtins)
├── primitives.d.bp      ← numeric + bool interfaces
├── array.d.bp           ← generic Array<T> interface
├── string.d.bp          ← String interface methods
├── syntax.bp            ← std.syntax — `@Expr` template data model + interface Expr<E>;
│                          plain `.bp` (concrete types, not declaration-only interfaces)
├── builtins.d.bp        ← @typeOf / @sizeOf / @panic / … (NOT embedded yet — see below)
├── bool.bp              ← `bool` std module (impl — qualified calls via `from "std"`)
├── pair.bp              ← `pair` std module (impl — pairs are 2-tuples `#(a, b)`)
├── order.bp             ← `order` std module (impl — `pub enum Order` exported)
└── list.bp              ← `list` std module (impl — over the builtin Array<T>)
```

## Files

| File | Role |
|---|---|
| `primitives.d.bp` | `interface I32 { … }`, `interface U32 { … }`, …, `interface Bool { … }`. |
| `array.d.bp` | `interface Array<T>` — `length`, `at`, `push`, `pop`, `contains`, `slice`, `join`, `reverse`, `indexOf`, `forEach`, `map`, `filter`. |
| `string.d.bp` | `interface String` — `len`, `split`, `to_upper/lower`, `contains`, `starts_with`, `ends_with`, `trim*`, `replace`, `slice`, `char_at`, `index_of`, `to_string`. |
| `syntax.bp` | `std.syntax` — data model for `@Expr` templates: `struct Span`, `enum Part { Text, Interp }`, `enum BindingKind`, `struct Binding`, `struct Source` (declaration position), `struct Context` (the full second-layer input: source + text + shape), and `interface Expr<E>` declaring the comptime-only surface of an `@Expr<E>` value (`value`/`text`/`parts`/`source`/`context`/`lookup`/`bindings`/`build`/`fail`/`failAt`; `Binding.ref()` stays a doc comment). Resolved by inference (`comptime/infer.zig: inferTemplateMethod`), like the `@Result`/`@Option` methods — comptime-only, no codegen. Construction is explicit via the `@expr(value)`/`@code(text)` builtins. |
| `bool.bp` | Gleam-style `bool` module (first real `"std"` package module): `pub fn negate`, `nor`, `nand`, `exclusiveOr`, `exclusiveNor` — pure-operator logic, no host backing. Reached via `import {bool} from "std"`; qualified calls (`bool.negate(x)`) compile the module into its own output (`out/std/bool.*`). NOTE: `option`/`result` are deliberately NOT std modules — `result` is a builtin namespace (`result.map(r, f)`, no import, lowered inline to `__bp_result_*`), and `option` has no namespace at all (the optional surface is the `?T` syntax + builtin methods; JS-style optional chaining `?.` is the planned ergonomic surface). |
| `builtins.d.bp` | Reflection (`typeOf`, `typeName`, `sizeOf`, `alignOf`, `hasField`, `hasDecl`, `field`, `tagName`), numeric (`min`, `max`, `abs`, `as`), control-flow (`block`), runtime (`panic`, `trap`, `src`). **Not embedded by `prelude.zig` yet** — builtins are currently registered programmatically in `compiler-core`'s `comptime/env.zig` (`registerBuiltins`); wiring this file is part of the `stdlib-gleam` spec (`tasks/v0.beta.2/specs/stdlib-gleam.md`). Also declares the annotation builtin `external(target: Target, module: string, symbol: string)` + `enum Target { node, typescript, erlang, beam, wasm }` (F1), used inside `@[ … ]` blocks and validated programmatically in `comptime/infer.zig`. |

## Conventions

- Keep declarations stable and additive — renames force snapshot churn across
  every codegen/comptime suite.
- When adding a `.bp` file: add it to `std_bp_files` in the root `build.zig`
  **and** add a `pub const <name> = @embedFile("<name>.bp");` line to
  `modules/compiler-core/src/comptime/stdlib/prelude.zig`, otherwise inference
  will not see it.
- Interface declarations must stay declarative (no method bodies) — they're
  consumed by the type checker, not codegen.
