# stdlib interface redesign — loose functions → interface methods

**Slug**: `stdlib-interface`
**Depends on**: `generic-inference` (generic methods need fresh type vars per call site)
**Files**: `libs/std/src/*` (`.bp` + companion `.mjs`/`.erl`); `modules/compiler-core/src/comptime/infer.zig` + `src/codegen/*` (method dispatch, default methods, `@[external]` on methods)
**Touches docs**: `libs/std/AGENTS.md`; `libs/std/src/docs.md`; `libs/std/src/examples.md`
**Status**: src restructure + wiring DONE · compiler integration (dispatch/codegen) REMAINING

## Goal

Replace loose namespace functions (`list.map(xs, f)`, `bool.negate(x)`) with
method/interface dispatch consistent with `Array<T>` (`xs.map(f)`). Primitives,
collections and combinators are declared as **interfaces** in a single
controller; concrete data types are **records**; host-backed operations resolve
through per-target companion files.

## As-built architecture (DONE)

`libs/std/src/` — 8 `.bp` files:

| File | Form | Role |
|---|---|---|
| `primitives.d.bp` | interfaces (flattened into the global env) | numeric tower `Number → Integer → Signed` / `Number → Float` with thin concrete markers `I32/I64/U32/U64/F32/F64` (`Self`-typed, `extends`, no duplication); `Bool`; `String`; `Function`; `Array<T>`; co-located tests |
| `builtins.bp` | builtin model (registered programmatically, **not parsed**) | reflection, io, `Result`, lazy `Iterator<T>` (`next`), `Iterable`, generator, async, `Expr<E>`, annotations, `Target` |
| `dict.bp` `sets.bp` `queue.bp` `string_builder.bp` | `pub record` + `self`-methods + top-level constructors | concrete, constructible data types |
| `pair.bp` | `interface Pair` | tuple combinators over `#(A,B)` |
| `order.bp` | `pub enum Order` + companions | sum type |

Design rules fixed during the work:
- **interface = pure behaviour contract** (no state, never constructed); **record/enum = concrete constructible type**.
- **declared (bodyless) method ⇒ `@[external(…)]`**; pure-logic ops are `default fn` with bodies.
- `Iterator<T>` (lazy core) lives in `builtins.bp`; `Array<T>` (eager, rich) in `primitives.d.bp`.

Wiring DONE: `prelude.zig`, `build.zig`, `comptime.zig` updated to the 8-file
set; global `sources = { primitives }`; `std_pkg_modules = { pair, order, dict,
sets, string_builder, queue }`. `zig build` is clean.

`registerStdlib` DONE: strips `test` decls before inferring stdlib sources
(`comptime.zig stripTestDecls`) — registration infers *declarations*; co-located
tests run via the test runner. Parser DONE: `skipComments` inside interface/record
bodies. With these, the suite is **997/1010** green.

## External companion files — `primitives.{mjs,erl}`

Host-backed declared methods carry `@[external(erlang, "primitives", SYM),
external(node, "./primitives.mjs", SYM)]`. The implementations live in
**companion files next to the declarations**:

```
libs/std/src/primitives.d.bp   ← declarations (@[external] → SYM)
libs/std/src/primitives.mjs    ← node host impls (export const SYM = …)
libs/std/src/primitives.erl    ← erlang host impls (-export([SYM/N]))
```

The `SYM` argument accepts **both forms** (already parses + registers):
- **bare name** — `"abs"`, `"string_length"`: lower to `module.SYM(...callArgs)`.
- **call template** — `"range(start,stop)"`, `"repeat(value,times)"`: the
  parenthesised params name the receiver/args explicitly (arg order/mapping).

## Remaining — compiler integration ("fazer funcionar")

Parser:
- [x] Skip comments inside interface/record bodies.
- [ ] Generic-extends-generic (`interface Array<T> extends Iterator<T>`) — grammar puts generics after `extends`; `Array<T>` is standalone for now.
- [ ] Literal receivers (`[1,2].append(...)`) — tests bind a `val` first.

Inference (`infer.zig`):
- [ ] **Associated fn via `Type.fn()`** (`Function.compose(...)`, `Array.range(...)`) — receiver names an interface, not a value (current first blocker for the stdlib's own tests).
- [ ] **`default fn` bodies** — register + type-check default method bodies.
- [ ] **`extends` capability inheritance** — concrete type inherits base-interface members.
- [ ] **`@[external]` on interface methods** (currently only on top-level `declare fn`).
- [ ] **`self`-method dispatch on primitives** (`n.abs()`, `s.trim()`, `b.negate()`).

Codegen (node/erlang):
- [ ] Lower `@[external]` methods to the companion modules (`primitives.mjs` / `primitives.erl`), honouring both bare and call-template `SYM` forms.
- [ ] Lower `default fn` bodies and primitive method dispatch.
- [ ] Write `primitives.mjs` + `primitives.erl` host impls for every `SYM`.

builtins.bp:
- [ ] Not parseable (`fn typeOf<T>(val: T) type` — `val` keyword param, no-arrow return). The `Expr<E>` model (formerly parsed via `syntax.bp`) needs a parsed home or programmatic registration so expr-templates keep working.

## Remaining test failures (13/1010)

All 13 are **`codegen.tests.std_package`** snapshot mismatches — fixtures that
exercise the **removed loose-function API** (`bool.negate`, `list.map/filter/fold`,
`string` qualified wrappers, `pair.of`, `order` enum module, `array` dispatch
sugar). Their `.new` output is empty (those `std` modules no longer exist).
**Not promotable** — rewrite to the method-dispatch API once that codegen lands,
or retire.

## Erlang e2e harness

`modules/compiler-cli/tests/std_erlang.sh` runs `bp test --target=erlang`
against `libs/std` (builds the CLI, spawns `escript`). Not part of `zig build
test`. Currently `5/7 module(s) failed to compile` — needs the method-dispatch +
`@[external]` Erlang codegen above. Flips green once that lands.

## Notes

- camelCase is the standard (`isEven`, `toString`); snake_case in the legacy
  declarations was normalised.
- Records (`Dict`, `Set`, `Queue`, `StringBuilder`) already dispatch methods via
  `self` — confirm before relying on them in codegen.
