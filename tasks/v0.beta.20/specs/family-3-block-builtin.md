# family-3-block-builtin — drive `@block` from annotations across every backend

**Slug**: family-3-block-builtin
**Depends on**: `prim-op-annotation` Frente B `33285f5` + `d51e935`
(`@todo` / `@panic` annotation-driven via builtin dispatch on commonJS +
erlang); the `External.<Target>` form lands in commit `85b199d`.
**Files**:
- `libs/std/src/builtins.d.bp` — declare `fn block<T>(body: fn() -> T) T`
  with `@External.<Target>("template")` annotations (the doc-only fn
  signature already exists in places; this spec makes it the canonical
  surface).
- `modules/compiler-core/src/codegen/{erlang,beam_asm,commonJS,wat}.zig`
  — delete the `mem.eql(cc.callee, "block")` switch arm in each
  emitter; the `@block { ... }` call site routes through
  `tryEmitBuiltinAnnotation` instead.
- `libs/std/src/builtins_fns.d.bp` (created by
  `fn-param-default-expansion` §F0) — adds the `fn block` row alongside
  `todo` / `panic` so `registerStdlib` picks it up.
**Touches docs**: `libs/std/AGENTS.md` ·
  `modules/compiler-core/src/codegen/AGENTS.md` · `CHANGELOG.md`.
**Status**: pending

## Background

After `prim-op-annotation` Frente B closed `@print` / `@todo` / `@panic`
via annotation-driven dispatch (commits `33285f5` for commonJS + `d51e935`
for erlang), one sibling builtin remained hardcoded on every backend:
`@block { ... }`. The call surface is a trailing-lambda builtin that
runs its body in a fresh scope:

```bp
val r = @block {
    val a = expensiveCompute();
    val b = a + 1;
    b
}
```

Each backend lowers this with an inline IIFE / fun:

| Target  | Inline shape (today) |
|---------|----------------------|
| erlang  | `(fun() -> <body> end)()` |
| beam    | inline `make_fun` + `call_fun` opcodes |
| node    | `(() => { <body> })()` |
| wat     | inline `block` + `end` opcodes |

Frente A §U listed `@block` as an unused-builtin candidate. **§U U1**
(removed unused builtins) kept `@block` (it has real users in stdlib
+ libs). So the lowering must stay — but it can move from a
hardcoded switch arm to an annotation entry on the `block` fn decl,
mirroring the `@todo` / `@panic` migration.

## Premise

After this spec lands, **every** Frente B builtin (`@print` / `@todo` /
`@panic` / `@block`) lowers from a single `#[@External.<Target>(...)]`
entry; no codegen file has a `mem.eql(cc.callee, "block")` arm; the
trailing-lambda surface (`@block { ... }`) keeps parsing as today and
the renderer reads the body via the `$body` substitution marker (new —
see §F0 below).

## Target surface

```bp
// in libs/std/src/builtins_fns.d.bp (the decl-only fn block from
// fn-param-default-expansion §F0)

#[@External.Erlang("(fun() -> $body end)()"),
  @External.Node("(() => { $body })()"),
  @External.Beam("$block_inline"),
  @External.Wasm("(block $bp_block_result $body end)")]
fn block<T>(body: fn() -> T) T
```

The `$body` template marker is **new**: it expands to the rendered body
of the call's trailing lambda. Caller surface stays the same:

```bp
val r = @block {
    val a = compute();
    a + 1
}
// renders on erlang: (fun() -> A = compute(), A + 1 end)()
// renders on node:    (() => { const a = compute(); return a + 1; })()
```

## Compiler path

### F0 — extend the template renderer with `$body`

- [ ] `comptime/primOpTemplate.zig`: add a `$body` marker that, when
      encountered, calls `ctx.emitBody()` — backend supplies the
      emit-lambda-body callback that walks `cc.trailing[0].body` and
      writes each statement to the output (each backend already has
      this routine).
- [ ] Diagnostic RP7 (new): `$body` in a template that doesn't carry
      a trailing lambda call site → `prim-op-body-no-trailing-lambda`.
- [ ] Tests in `tests/codegen/prim_op_templates.zig` cover happy path +
      RP7.

### F1 — declare `fn block<T>` with annotations

- [ ] `libs/std/src/builtins_fns.d.bp`: add the `fn block<T>` row with
      the four `@External.<Target>(...)` annotations from §"Target
      surface" above.
- [ ] Verify `registerStdlib` (from `fn-param-default-expansion` §F0)
      picks up the `block` entry into `fn_decls`.
- [ ] `expandTrailingDefaults` (or its sibling for trailing lambdas)
      is unchanged — `block` takes exactly one fn-typed arg with no
      default, so arity check fires if user wrote `@block` without
      braces.

### F2 — backend dispatch migration

- [ ] `erlang.zig`: delete the `mem.eql(cc.callee, "block")` arm in
      the builtin call switch (~line 2139); the
      `tryEmitBuiltinAnnotation` path picks it up via the entry seeded
      from F1.
- [ ] `commonJS.zig`: delete the `is_block` branch (~line 2597).
- [ ] `beam_asm.zig`: delete the `block` arm (~line 2591).
- [ ] `wat.zig`: delete the `block` arm (~line 1310).
- [ ] Each backend's ctx struct gains an `emitBody` method routing to
      its existing emit-block routine.

### F3 — tests

- [ ] Existing `@block` snapshot scenarios diff empty against pre-F2
      HEAD on every backend (byte-identical migration).
- [ ] New: `@block` with a `return` inside the body lands in the
      enclosing fn's return slot (the IIFE convention) on every
      backend — guards against accidental swallowing.
- [ ] New: nested `@block` ( `@block { val r = @block { 1 + 1 }; r * 2 }`)
      renders the same on every backend.

### F4 — docs

- [ ] `libs/std/AGENTS.md` §"Template grammar" — add the `$body`
      marker row + RP7 diagnostic.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` §"Annotation-driven
      lowering" — drop `@block` from the residual list.
- [ ] `CHANGELOG.md`:
      `refactor(codegen): @block annotation-driven on every backend.`

## Test scenarios

```
F0-marker  ---- `$body` substitution emits the trailing lambda's body verbatim
F0-RP7     ---- `$body` template invoked with no trailing lambda reds with prim-op-body-no-trailing-lambda
F1-decl    ---- fn block<T> entry from builtins_fns.d.bp reaches fn_decls
F2-byte    ---- diff snapshots/codegen/<backend>/ for every @block scenario empty against pre-F2 HEAD
F2-empty   ---- post-F2 `git grep '"block"' modules/compiler-core/src/codegen/` finds zero hits in callee-dispatch arms
F3-return  ---- @block with `return X` inside the body lands in the enclosing fn's return slot
F3-nested  ---- nested @block { @block { ... } } renders consistently on every backend
F4-docs    ---- libs/std/AGENTS.md + codegen/AGENTS.md + CHANGELOG.md updated in F2 commit
gate       ---- `zig build test` + `zig build test-libs` + `zig build test-backends` green
```

## Notes

- **Cross-spec interaction.** Together with `family-1-beam-wat-prim-methods`
  and `family-2-beam-wat-runtime-ops`, this spec closes the last
  hardcoded callee-keyed switch arm in any codegen file. The
  `prim-op-annotation` §F2-empty assertion can then be re-pinned green
  on every backend.
- **`fn-param-default-expansion` dependency.** This spec needs the
  `builtins_fns.d.bp` split (§F0 of `fn-param-default-expansion`) so
  the `fn block<T>` row reaches `fn_decls`. Without that split, the
  migration is the same as `prim-op-annotation`'s inline-seeded
  workaround — workable but uglier. Pin landing order:
  `fn-param-default-expansion` → `family-3-block-builtin`.
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.
