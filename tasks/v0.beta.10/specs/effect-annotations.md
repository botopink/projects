# effect-annotations — replace the `*fn` marker with `#[@<effect>]` annotations

**Slug**: effect-annotations
**Depends on**: nothing
**Files**: `modules/compiler-core/src/lexer.zig` + `parser.zig` (the `*fn` marker → annotation), `modules/compiler-core/src/ast.zig` (`FnDecl` effect kind), `modules/compiler-core/src/comptime/infer.zig` (effect ↔ return-type checking, `await`/`yield`/`throw` gating), `modules/compiler-core/src/codegen/{commonJS,erlang,beam_asm,wat}.zig` (drive lowering off the effect kind), `libs/std/src/builtins.d.bp` (register the annotations; the effect types already exist)
**Touches docs**: `docs.md` (§Effects), `modules/compiler-core/src/comptime/AGENTS.md`, `libs/std/src/builtins.d.bp`
**Status**: pending

> Make the function effect **named and explicit** as an annotation — the
> `#[@<name>]` form botopink already uses for host-bound surface
> ([[feedback_external_annotation_form]]) — instead of the bare `*` prefix on `fn`.
> Memory: [[project_stdlib_result_methods]] (`*fn` is today's effect marker).

## Context — what exists today

The effect system is mostly built; only the **marker syntax** changes here.

- **`*fn`** is the effect marker (a `*` prefix on `fn`); `FnDecl.isStarFn` carries it.
- The **return-type wrapper** discriminates the effect, and codegen maps the pair
  (`commonJS.zig:875`):
  - `*fn -> @Future<_>` → `async function`
  - `*fn -> @Iterator<_>` → `function*`
  - `*fn -> @AsyncIterator<_>` → `async function*`
  - `*fn -> @Result<_, _>` → plain `function` (checked-Result effect)
  - bare `*fn` → `function*` fallback
- The **effect types already exist** in `builtins.d.bp`: `@Result<R, E>`,
  `@Iterator<T>`, `@Generator<T, R>` (+ `Yield`), `@Future<T, E>`,
  `@AsyncIterator<T, E>`, `@Context<C, R>`. Body ops exist too: `await`, `yield`
  (generator delegation `return <iter>` → `yield*`), `throw`/`try`/`catch` on Result.
- Non-JS backends eager-lower `*fn` async/generator (`erlang.zig:762`,
  `beam_asm.zig:770`, `wat.zig:673`); `*fn -> @Result` is a plain fn everywhere.

## Target syntax (Eric, 2026-06-10)

```bp
#[@future]
fn myFn() -> @Future<T> { … }          // was:  *fn myFn() -> @Future<T> { … }

#[@result]    fn parse(n: i32) -> @Result<i32, string>
#[@generator] fn range(a: i32, b: i32) -> @Generator<i32>
#[@iterator]  fn lazyMap(...) -> @Iterator<T>
#[@context]   fn useThing() -> @Context<Base, T>
```

The annotation **names** the effect; the `@<Effect><…>` return type carries its type
parameters (parallel to `#[@external]` + a host-bound signature). The annotation is
the source of truth for the effect kind — it replaces `*` and the
discriminate-by-return-type guessing.

## Steps

### F0 — parse the effect annotations
- [ ] Recognize `#[@result]`, `#[@future]`, `#[@generator]`, `#[@iterator]`,
      `#[@asyncGenerator]`, `#[@context]` as **builtin effect decorators** on a `fn`.
      Replace `FnDecl.isStarFn: bool` with `FnDecl.effect: ?EffectKind`. The lexer/
      parser stops requiring the `*` prefix (see migration for its deprecation).

### F1 — effect ↔ return-type + body ops
- [ ] Check the annotation against the return wrapper: `#[@future]` requires
      `-> @Future<…>`, `#[@result]` requires `-> @Result<…>`, etc. (a clear
      diagnostic on mismatch). Gate body operations on the effect kind: `await` only
      under `#[@future]`/`#[@asyncGenerator]`; `yield`/generator-delegation only under
      `#[@generator]`/`#[@iterator]`/`#[@asyncGenerator]`; `throw`/`try` keep working
      under `#[@result]` (already enforced for `@Result` returns today).

### F1b — the annotation is implementation-only (interfaces use the wrapper)
- [ ] The effect annotation marks an **implementation** (a `fn` with a body) — it is
      the marker that replaces `*`. An **interface** method and a `.d.bp` declaration
      are **declarative** (no body): they express the effect purely through the return
      **wrapper** (`fn next(self: Self) -> @Future<?T, E>`), with **no annotation**.
      Using `#[@<effect>]` on an interface method / bodyless declaration is an
      **error**: "effect annotations mark an implementation; declare the effect in the
      return type". This mirrors TypeScript — the interface says `-> Promise<T>`, the
      impl marks `async`. **Consequence:** the wrapper is never inferred away; it is
      the effect's type everywhere (interfaces, `.d.bp`, and implementation returns),
      and the annotation is an implementation marker only. So the existing builtin
      interfaces (`Iterator`/`Generator`/`Future`/`AsyncIterator`/`Context` in
      `builtins.d.bp`) stay annotation-free — only their implementations carry
      `#[@<effect>]`.

### F2 — codegen off the effect kind (no behaviour change)
- [ ] Replace the `f.isStarFn` + `starFnKind(returnType)` dispatch
      (`commonJS.zig:883`) with the `FnDecl.effect` kind. Keep the exact lowering:
      `@future`→`async function`, `@generator`→`function*`,
      `@asyncGenerator`→`async function*`, `@iterator`→`function*`, `@result`→plain
      `function`. Mirror on erlang/beam/wasm (eager lowering; `@result` plain). Output
      is byte-identical to today for an equivalent `*fn`.

### F3 — register the annotations as builtins ("create the builtins")
- [ ] Declare the effect annotations in `builtins.d.bp` (the `#[@<effect>]` markers),
      alongside the existing effect types. Resolve the open type-shape decisions (see
      below): whether `@Future<T>` (the form Eric wrote) supersedes `@Future<T, E>`,
      and likewise for `@AsyncIterator`. The annotations are core-builtin, lib-agnostic.

### F4 — migrate every `*fn` + deprecate the prefix
- [ ] A codemod rewriting each `*fn -> @X` to `#[@<effect>] fn -> @X` by the
      return-type mapping. Apply to `libs/std` (`primitives.d.bp` `parse`,
      `iterator.bp` generators), `libs/jhonstart` (`server.d.bp` server components),
      and `examples/jhonstart-app` (`loadPost`/`Page`/`main`). Deprecate the `*`
      prefix (warn for one release, then remove — see Open decisions). Update the
      docs/comments that reference `*fn`.

### F5 — docs + tests
- [ ] `docs.md` §Effects: the `#[@<effect>]` model + the per-effect body ops +
      codegen mapping. Parser/infer/codegen tests: each annotation lowers to the right
      JS keyword; a `#[@future]` body using `yield` errors; an annotation/return-type
      mismatch errors; the migrated libs + examples stay green on every backend.

## Open design decisions (recommendations inline)

1. **Annotation vs return type redundancy.** *Recommend:* keep both — the annotation
   names the effect (the marker), the `@Effect<…>` return carries the type params,
   exactly like `#[@external]` + a signature. Don't infer one from the other; explicit
   reads best and keeps codegen simple.
2. **`@Future<T>` vs `@Future<T, E>`.** Eric wrote `@Future<T>`. *Recommend:* allow the
   one-arg form with a default error type (`@Future<T>` ≡ `@Future<T, _>`), keeping the
   two-arg form valid — least disruption, matches the example.
3. **Remove `*fn` or keep as a deprecated alias?** *Recommend:* deprecate for one
   release (warn + codemod), then remove, so the annotation is the single spelling.
4. **Effect set in v1:** `result`, `future`, `generator`, `iterator`, `asyncGenerator`,
   `context` — the existing return-type wrappers, one annotation each.
5. **Type/wrapper name length — DECIDED: long, for now (Eric, 2026-06-10).** Both the
   annotation and the type stay long: `#[@result]`/`#[@future]`/`#[@generator]`/
   `#[@iterator]`/`#[@asyncGenerator]`/`#[@context]` paired with `@Result`/`@Future`/
   `@Generator`/`@Iterator`/`@AsyncIterator`/`@Context` (already the builtin names — zero
   rename, no `@Res`/`Response` collision, reads clearly in interfaces). "For now" —
   short forms may be revisited later, not in this spec.
6. **Implementation verbosity.** With the wrapper required everywhere, an
   implementation reads `#[@future] fn f() -> @Future<T>` — the effect name twice.
   *Options:* (a) accept it (explicit; the impl signature matches the interface);
   (b) in an implementation only, allow the return to be the inner `T`
   (`#[@future] fn f() -> T`; the annotation supplies the wrapper) while interfaces/
   `.d.bp` keep the full `@Future<T>`. *Recommend (a)* for signature symmetry; adopt
   (b) only if the verbosity proves annoying in practice.

## Test scenarios

```
parse  ---- #[@future] fn … -> @Future<T> parses; effect kind = future on the FnDecl
infer  ---- #[@result] body may `throw`; #[@future] body may `await`; cross-use errors
infer  ---- annotation/return mismatch (#[@future] fn -> @Result<…>) is a clear error
infer  ---- #[@<effect>] on an interface method / bodyless decl is an error (impl-only)
infer  ---- an interface method declares its effect via the return wrapper, no annotation
codegen ---- #[@future]→async function, #[@generator]→function*, #[@result]→plain fn
codegen ---- erlang/beam/wasm eager-lower the effects identically to the old *fn
migrate ---- libs/std + jhonstart + examples build + test green after the codemod
```

## Notes

- This is a **syntax/marker** change over a working effect system — the effect types,
  the `await`/`yield`/`throw` machinery, and the backend lowerings already exist; the
  spec re-roots the marker on `#[@<effect>]` and migrates the call sites.
- `#[@<effect>]` follows the established host-annotation form
  ([[feedback_external_annotation_form]]): `@name` only inside `#[…]`, never
  `@[name]`.
- Keep it lib-agnostic — these are core-builtin effect annotations, not a framework
  feature. The gate stays green.
