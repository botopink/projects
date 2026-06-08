# v0.beta.6 — finish stdlib backends + remaining backend/tooling work

**Slug**: `stdlib-backends-and-tooling`
**Supersedes**: the unfinished parts of `tasks/v0.beta.4/specs/carryover.md`.
**Status**: pending

> Clean carry-forward of what's still open after v0.beta.4. The stdlib-interface
> **JS** path is done (instance + associated methods for Array/Bool/Numeric/String,
> and `Pair`/`Function`); this spec is the rest: the other backends, the stragglers
> in the dispatch, and the backend-parity / editor-experience features.

## Done in v0.beta.4 (context — do not redo)

- **stdlib-interface, JS codegen** — instance methods materialize as prototype
  patches: `Array.prototype.*` (`prepend`/`fold`/`isEmpty`/…; `append`→`concat`),
  `Boolean.prototype.*` (`negate`/`nor`/…, with `this.valueOf()` unwrap),
  `Number.prototype.*` (`abs`/`min`/`max`/`clamp`/`isEven`/… via `Math.*`),
  `String` (`toUpper`→`toUpperCase`, same-named host methods native). Associated
  fns (`Pair.of`, `Function.compose`) emit injected namespace objects.
- Dispatch: `resolveStdArrayMethod` → `primitiveInterfaceName` +
  `findInterfaceDefaultFn` (follows `extends`); `@[external]` accepted only for JS
  globals (`Math`) to avoid intercepting companion-backed methods.
- `1030/1030` zig tests + `31/31` `libs/std` tests green on node.

## Part A — stdlib-interface: finish the dispatch + other backends

### A1 — non-JS backends (erlang / beam / wasm)
- [ ] Mirror the JS instance/associated-method lowering in `erlang.zig`,
      `beam_asm.zig`, `wat.zig`. JS uses prototype patches + `Math.*`; erlang/beam
      need module-function dispatch (`erlang:abs/1`, companion `primitives.erl`),
      wasm needs intrinsics/host calls. The 4-backend golden snapshots already
      exist (recorded, not yet meaningful) — make them real.
- [ ] `modules/compiler-cli/tests/std_erlang.sh` green (currently the erlang e2e
      harness fails to compile the std modules).

### A2 — dispatch stragglers
- [ ] `s.contains()` → `includes`: NOT a global name-map (`record` `Set` declares
      `contains`). Add a type-aware `method_lowerings` entry when the receiver is
      `string`, lowered to `includes`.
- [ ] `@[external]` **associated** fns: `Array.range(start, stop)`,
      `Array.repeat(value, times)` — host-backed via `gleam_stdlib.mjs` with a
      call-template symbol (`"range(start,stop)"`). Need the companion file + the
      call-template arg mapping; today they hit `Array.range is not a function`.
- [ ] **Record-method bodies**: inference doesn't walk `record` method bodies, so
      an array default-fn used inside one (other than `concat`-mapped `append`)
      doesn't mark its interface used → no prototype patch emitted. Walk them (or
      emit the prototype unconditionally when arrays are constructed).
- [ ] **Companion modules** `libs/std/src/primitives.mjs` + `primitives.erl` for
      the `@[external]` symbols not backed by a JS/erlang global (string ops on
      non-native names, etc.). Honour bare + call-template `SYM` forms.

### A3 — inference correctness
- [ ] **`default fn` body type-checking** — currently a `default fn` body isn't
      type-checked (a wrong return type passes). Register + infer the bodies in a
      scope with `self`/params bound, without breaking stdlib registration.
- [ ] Parser: generic-extends-generic (`interface Array<T> extends Iterator<T>`);
      literal method receivers (`"a,b".split(",")`, `[1,2].append(...)`) — also
      backend-parity F1.

## Part B — backend-parity F1–F6 (from v0.beta.3)

- [ ] **F1 — Literal method receivers** (`"a,b".split(",")`); shared with A3.
- [ ] **F2 — snake_case → camelCase dispatch** — partly covered by the String
      name-mapping; finish the table / fold into definition-time normalization.
- [ ] **F3 — Erlang/BEAM std package loading** (heaviest) — multi-module compile
      or inline; overlaps A1.
- [ ] **F4 — `?.` codegen for Erlang/BEAM/WASM**.
- [ ] **F5 — WASM test runner** — shim + wire into `botopink test`.
- [ ] **F6 — Duplicate test-name warning** per file.

## Part C — editor-experience F0–F5 (from v0.beta.3, nothing implemented)

- [ ] **F0 — Semantic tokens (LSP)** — biggest LSP gap; drive from the typed AST.
- [ ] **F1 — Inlay hints** — inferred `val` types, lambda param types.
- [ ] **F2 — VS Code tasks + problem matcher** (check/build/test/format).
- [ ] **F3 — VS Code CodeLens + status bar** ("Run test" over `test "…"`, target switcher).
- [ ] **F4 — VS Code Testing API** (Test Explorer over `test "…"` blocks).
- [ ] **F5 — Docs + manifest** bump.

## Verification

- `zig build && zig build test` green; `botopink test` green in every `libs/*`
  (enforced by the pre-commit `botopink .bp` step).
- `modules/compiler-cli/tests/std_erlang.sh` green once A1 lands.

## Notes / lessons (from v0.beta.4)

- Accepting `@[external]` in the dispatch indiscriminately collapsed the whole
  suite (516 fails) — it intercepted companion-backed array/string methods that
  already worked via native JS. Restrict to JS globals (`Math`); keep companions
  on the permissive path until their lowering lands.
- Boxed primitives (`Boolean`/`Number`/`String`) box `this` into a truthy wrapper
  object — prototype-method bodies must unwrap via `this.valueOf()`.
- Global method-name maps are unsafe when a `record` shares the name (`contains`).
