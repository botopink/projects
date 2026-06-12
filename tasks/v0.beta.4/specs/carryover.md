# v0.beta.4 — carryover: finish stdlib-interface, backend-parity & editor-experience

**Slug**: `carryover`
**Supersedes**: the unfinished parts of every `tasks/v0.beta.3/specs/*` spec.
**Status**: pending

> Single consolidated spec. It collects **only what was NOT done** across the five
> v0.beta.3 specs, in one place, so v0.beta.4 has one source of intent. The
> original v0.beta.3 specs stay as immutable history; this is the live carryover.

## What was already DONE in v0.beta.3 (context, do not redo)

- **generic-inference** — F1 per-call-site instantiation of generic functions
  (`infer.zig` HM instantiation). F2/F3 superseded by stdlib-interface. ✅
- **tooling-update** — F0a (go-to-definition fix), F0–F5 (TextMate grammar sync,
  snippets, LSP test-block surface, std member completion, interface-method
  completion on builtin receivers, manifest bump). ✅
- **backend-parity** — F7 (`#[@external(node)]` JS globals), F8 (JS reserved-word
  sanitization), F0 (real `*fn` generator lowering), F9 (`?T` method surface on
  tuple-extracted elements). ✅
- **stdlib-interface** — source restructure to the 8-file interface model
  (`primitives.d.bp` controller + records + companions) and compiler wiring
  (`prelude.zig`/`build.zig`/`comptime.zig`, `registerStdlib` test-strip, parser
  comment-skip). `zig build` clean. ✅ **Integration (dispatch/codegen) is NOT
  done — see Part A.**

Current tree state after consolidation: `zig build` clean; `zig build test`
**915/928** (13 red); `botopink test` in `libs/std` fails (5/7 modules don't
compile). The 13 red + the 5 failing modules are Part A.

---

## Part A — stdlib-interface: compiler integration ("make it work")

The interface model is declared and wired but the compiler cannot yet *dispatch*
or *codegen* it. This is the largest and highest-priority block: it unblocks the
13 red tests and makes `libs/std` compile/run again.

### A.parser
- [ ] Generic-extends-generic (`interface Array<T> extends Iterator<T>`) — grammar
      currently puts generics after `extends`; `Array<T>` is standalone for now.
- [ ] Literal method receivers (`[1,2].append(…)`, `"a,b".split(",")`) — today
      tests must bind a `val` first. **(Same gap as backend-parity F1 — do once.)**
- [ ] `builtins.bp` parseability: `fn typeOf<T>(val: T) type` (`val` keyword param,
      no-arrow `type` return). The `Expr<E>` model (formerly in `syntax.bp`) needs
      a parsed home or programmatic registration so expr-templates keep working.

### A.inference (`comptime/infer.zig`)
- [~] **Associated fn via `Type.fn()`** (`Function.compose(…)`, `Array.range(…)`)
      — receiver names an interface, not a value. **INFERENCE DONE**:
      `registerInterfaceAssociatedFns` binds each `self`-less interface method
      under `"<Interface>.<method>"` (generics generalized to `.generic`);
      `inferCallExpr` resolves `Recv.callee(...)` and instantiates per call site.
      `Pair.of`/`Array.range`/`Function.identity` type-check. **JS CODEGEN DONE**
      for `default fn` associated fns: `emitInterface` emits a namespace object
      (`const Pair = {}; Pair.of = function(...){...}`), and codegen injects the
      stdlib interface decls used as receivers (`withUsedAssocInterfaces` +
      `env.usedAssocInterfaces`/`assocInterfaceDecls`; primitives.d.bp parsed into
      `env.arena` so the decls persist). `Pair.of`/`Pair.first`/`Function.identity`/
      `Function.compose` run end-to-end on node. **STILL PENDING**: `@[external]`
      associated fns (e.g. `Array.range`, host-backed via `gleam_stdlib.mjs`) need
      the companion-module lowering below; erlang/beam/wasm backends.
- [ ] **`default fn` bodies** — register + type-check default method bodies.
- [ ] **`extends` capability inheritance** — concrete type inherits base-interface members.
- [ ] **`@[external]` on interface methods** (currently only on top-level `declare fn`).
- [~] **`self`-method dispatch on primitives** (`n.abs()`, `s.trim()`, `b.negate()`).
      **Array DONE (JS)**: `resolveStdArrayMethod` resolves `xs.<m>()` against the
      `Array<T>` interface's `default fn` instance methods (`prepend`, `fold`,
      `isEmpty`, `all`, …), marks `Array` used, and `emitInterface` emits
      `Array.prototype.<m>` patches; `append` maps to native `concat`, native
      proto methods (`find`/`flatMap`) are left to the engine. **Bool DONE (JS)**:
      `b.negate()`/`nor`/`nand`/`exclusiveOr` emit `Boolean.prototype.<m>`;
      boxed-primitive `this` is unwrapped via `const self = this.valueOf()`
      (`jsPrototypeOwner` maps `Bool`→`Boolean`, `isBoxedPrototype`). Dispatch
      generalized: `resolveStdArrayMethod` → `primitiveInterfaceName` +
      `findInterfaceDefaultFn` (follows `extends`). **Numeric tower DONE (JS)**:
      `n.abs()`/`min`/`max`/`floor`/… (`@[external]` → JS global `Math`) emit
      `Number.prototype.<m> = function(a){ return Math.sym(this.valueOf(), a); }`,
      and `default fn`s (`clamp`/`isEven`/`isOdd`) materialize and call them.
      `findInterfaceDefaultFn` accepts `@[external]` ONLY when the node module is a
      JS global (`Math`) — relative companions (`./gleam_stdlib.mjs`: array
      `map`/`filter`/`join`, string `split`/`trim`) stay on the permissive native
      path, so this doesn't intercept methods that already work. `jsPrototypeOwner`
      maps the tower → `Number`. **String DONE (JS)**: same-named methods
      (`split`/`trim`/`slice`/`startsWith`/…) use the engine directly; the
      differently-named host methods map to natives via `jsBuiltinMethodName`
      (`toUpper`→`toUpperCase`, `toLower`→`toLowerCase`) — these names are unique
      to `String`, so the type-independent mapping is safe. **PENDING**:
      `s.contains()`→`includes` (NOT mapped: a `record` like `Set` declares
      `contains`, so a global name-map would clobber it — needs a type-aware
      `method_lowerings` entry); inference doesn't walk record-method bodies
      (non-`append` array default-fns used there won't emit a prototype patch).

### A.codegen (node / erlang / beam / wasm)
- [ ] Lower `@[external]` methods to companion modules (`primitives.mjs` /
      `primitives.erl`), honouring both **bare** (`"abs"`) and **call-template**
      (`"range(start,stop)"`) `SYM` forms.
- [ ] Lower `default fn` bodies and primitive method dispatch.
- [ ] Write `libs/std/src/primitives.mjs` + `primitives.erl` host impls for every `SYM`.

### A.tests
- [ ] Rewrite or retire the **13 `codegen.tests.std_package`** fixtures — they
      exercise the removed loose-function API (`bool.negate`, `list.map/filter/fold`,
      `string` qualified wrappers, `pair.of`, `order` enum module, `array` dispatch
      sugar). Rewrite to method-dispatch once that codegen lands, or retire.
- [ ] `modules/compiler-cli/tests/std_erlang.sh` — currently `5/7 modules failed
      to compile`; flips green once method-dispatch + `@[external]` erlang codegen land.
- [ ] `botopink test` in `libs/std` green again (all `.bp` modules compile + tests pass).
- [ ] Remove the inline-test restriction note from `libs/std/AGENTS.md`.

> Note: `comptime.zig` `array_interface_src`/`string_interface_src` were pointed at
> `primitives` during consolidation (Array/String live inside `primitives.d.bp`).

---

## Part B — backend-parity: remaining backend/stdlib gaps (F1–F6)

From `tasks/v0.beta.3/specs/backend-parity.md`. F7/F8/F0/F9 are done.

- [ ] **F1 — Literal method receivers** (known gap #4): parser support for
      `"a,b".split(",")`; formatter round-trips; snapshot `parser/literal_method_receiver`.
      **(Shared with A.parser literal receivers — implement once.)**
- [ ] **F2 — snake_case → camelCase dispatch** (known gap #1): JS name-mapping for
      builtin string/array methods (`to_upper`→`toUpperCase`); table shrinks once
      stdlib-interface normalizes names at definition. Snapshot
      `codegen/node/string_snake_to_camel_dispatch`.
- [ ] **F3 — Erlang/BEAM std package loading** (known gap #3, heaviest):
      multi-module compile (separate `.erl`/`.beam`) or inline into entry module;
      wire std package into `comptime/runtime/erlang.zig`. Snapshot
      `codegen/erlang/std_package_list_map_via_erlang`. **(Overlaps A.codegen erlang.)**
- [ ] **F4 — `?.` codegen for Erlang/BEAM/WASM** (known gap #7): erlang case/match
      on `{ok,Val}`; WASM conditional on optional tag. Snapshots
      `codegen/erlang/optional_chain`, `codegen/wasm/optional_chain`.
- [ ] **F5 — WASM test runner**: runner shim + wire into `botopink test`. Snapshot
      `codegen/wasm/test_runner_basic`.
- [ ] **F6 — Duplicate test name warning**: `Diagnostic.warning` on duplicate test
      names per file. Snapshot `comptime/duplicate_test_name_warning`.

Deferred (no fix here): known gap #5 (structural `==` on arrays in JS) — workaround
`.join(…)` documented.

---

## Part C — editor-experience: beyond-parity LSP + VS Code (F0–F5)

From `tasks/v0.beta.3/specs/editor-experience.md` — **nothing implemented yet**.
Depends on Part A (semantic data for primitive method dispatch).

- [ ] **F0 — Semantic tokens (LSP)**: advertise `semanticTokensProvider`; drive
      tokens from the typed AST (distinguish builtin `@Type`s, interface methods,
      `*fn` effectful fns, comptime params); `semanticTokens/full` + `range`;
      snapshots `snapshots/lsp/semantic_tokens_*`. *(Single biggest LSP gap.)*
- [ ] **F1 — Inlay hints (LSP)**: inferred `val` type hints (suppressed when
      annotated); parameter-name + lambda param type hints; respect resolve +
      `workspace/inlayHint/refresh`; snapshots `snapshots/lsp/inlay_hints_*`.
- [ ] **F2 — VS Code tasks + problem matcher**: `taskDefinitions` + `TaskProvider`
      for check/build/test/format; `problemMatcher` for `botopink check`; output channel.
- [ ] **F3 — VS Code CodeLens + status bar**: "Run test" lens over `test "…"`
      blocks; "Run" over `fn main`; status-bar active-target switcher.
- [ ] **F4 — VS Code Testing API**: discover `test "…"` via LSP `documentSymbol`;
      run via `botopink test`; map pass/fail + assertion messages to Test Explorer.
- [ ] **F5 — Docs + manifest**: bump `package.json`; refresh READMEs; update
      `AGENTS.md` + `docs.md`; LSP snapshots green.

---

## Suggested order

1. **Part A** (unblocks tests + makes `libs/std` compile) — A.parser → A.inference
   → A.codegen → A.tests.
2. **Part B** F1/F2/F6 (cheap; F1 shared with A.parser), then F3/F4/F5 (backend-heavy;
   F3 overlaps A.codegen erlang).
3. **Part C** (depends on A for primitive-method semantic data).

## Verification

- `zig build && zig build test` green (rewrite/retire the 13 std_package fixtures).
- `botopink test` green in every `libs/*` package (now enforced by the pre-commit
  step 5 `botopink .bp` hook).
- `modules/compiler-cli/tests/std_erlang.sh` green.
