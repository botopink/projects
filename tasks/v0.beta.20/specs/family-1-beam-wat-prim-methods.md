# family-1-beam-wat-prim-methods — drive primitive-method lowering from annotations on BEAM + wat

**Slug**: family-1-beam-wat-prim-methods
**Depends on**: `prim-op-annotation` commits `485b635`, `fa1803d`,
`f3dc1d6`, `8cf57f7`, `59ab77f`, `0c8dddc`, `a64031f` (Family 1 erlang
landed); `4c2e62c` + `5f0f1d9` (the `External.<Target>` form + the
`expandTrailingDefaults` AST plumbing); `family-2-beam-wat-runtime-ops`
(landed first so BEAM + wat already have `tryEmitBuiltinAnnotation`-shape
infra to reuse).
**Files**:
- `modules/compiler-core/src/codegen/beam_asm.zig` — `emitPrimMethod`
  (~line 2269) shrinks to the annotation-driven path; the existing
  switch arms for `push` / `append` / `prepend` / `isEmpty` /
  string `split` / 1-arg `slice` migrate to inline-seed entries.
- `modules/compiler-core/src/codegen/wat.zig` — `emitPrimMethod`
  equivalent: the `.len` string-prefix arm migrates to a property-
  annotation; the rest follow the BEAM shape.
- `libs/std/src/primitives.d.bp` — `@External.Beam("template")` +
  `@External.Wasm("template")` rows added for the migrated methods.
**Touches docs**: `libs/std/AGENTS.md` (per-target template grammar
  table extended for BEAM + wat) ·
  `modules/compiler-core/src/codegen/AGENTS.md`.
**Status**: pending

## Background

`prim-op-annotation` Family 1 retired the hand-rolled `emitPrimMethod`
switch on the erlang backend (commits `485b635`, `fa1803d`, `f3dc1d6`,
`8cf57f7`, `59ab77f`, `0c8dddc`, `a64031f`). After this wave landed,
the §A6 closure recorded an "irreducible allow-list" of arms that the
template grammar of the time couldn't express:

- **BEAM ASM** — `prepend` / `push` / `append`, string `split` / 1-arg
  `slice`. These emit BEAM bytecode patterns (`put_list`,
  `lists:append`-with-`{x,_}`-juggling, atom-literal arguments,
  `is_eq`+`move`-branch sequences) that the single-string template
  initially couldn't capture without a target-specific marker
  vocabulary.

- **erlang** — `len`/`length`/`size`. Maps to the `length/1` BIF — a
  bare value-shape, **no module qualifier**. Either supported via a
  new "BIF" annotation form OR via `val length: i32` (the property
  surface).

- **commonJS** — `length-as-property`. Same property-vs-call decision
  as the erlang BIF case.

- **wat** — `.len` reads the string-length prefix from linear memory
  (wasm-untyped emit-form tied to the prefix-length string layout).

After `prim-op-annotation` shipped the `$stringify(...)` marker
(commits `72e17e9` + `23f7485`) and `family-2-beam-wat-runtime-ops`
lands the BEAM + wat dispatch infra, **every** Family 1 arm becomes
expressible in the template grammar. This spec ships the surface
migrations + arm deletions.

## Premise

After this spec lands:

- Every primitive interface method in `primitives.d.bp` carries
  `@External.<Target>("template")` for every backend it supports
  (erlang + node + beam + wat + typescript-on-`.d.ts`).
- `emitPrimMethod` in **every** codegen carries zero `mem.eql(callee, …)`
  arms — only the annotation-driven path remains.
- The `val length` property on Array + String becomes a real
  `@externalProperty` annotation (see §F1 below) instead of an inline
  switch arm.
- Adding a new primitive method on N backends is N lines in
  `primitives.d.bp`, never any `.zig` edit.

## Target surface

### Properties (`val length`) via `@externalProperty`

A new annotation form for **properties** (no receiver-method-shape, just
a value extractor):

```bp
interface Array<T> {
    #[@ExternalProperty.Erlang("length($self)"),
      @ExternalProperty.Node("$self.length"),
      @ExternalProperty.Beam("array_length $self"),
      @ExternalProperty.Wasm("(call $bp_arr_length $self)")]
    val length: i32

    // ... rest of the methods
}

interface String {
    #[@ExternalProperty.Erlang("string:length($self)"),
      @ExternalProperty.Node("$self.length"),
      @ExternalProperty.Beam("call_ext erlang string_length 1 $self"),
      @ExternalProperty.Wasm("(call $bp_str_length $self)")]
    val length: i32

    // ... rest of the methods
}
```

The `val`-property emit path already exists on JS (§A5 of frente-a);
this spec just generalises it to all four backends and migrates the
remaining inline arms.

### BEAM array primitives (the §A6 allow-list)

```bp
interface Array<T> {
    #[@External.Beam("call_ext lists prepend 2 $0 $self")]
    fn prepend(self: Self, item: T) -> Self

    #[@External.Beam("call_ext lists append 2 $self [$0]")]
    fn push(self: Self, item: T) -> Self

    #[@External.Beam("call_ext lists append 2 $self $0")]
    fn append(self: Self, other: Self) -> Self

    #[@External.Beam("call_ext erlang =:= 2 $self [] move_result")]
    fn isEmpty(self: Self) -> bool

    #[@External.Beam("call_ext lists nthtail 2 $0 $self")]
    fn sliceFrom(self: Self, start: i32) -> Self  // single-arg slice form, after fn-param-default-expansion
}
```

(The exact BEAM-asm syntax is for sketch — pin down the canonical form
against `beam_asm.zig`'s existing emit during F0 implementation.)

### wat property + array primitives

```bp
interface Array<T> {
    #[@ExternalProperty.Wasm("(i32.load (i32.sub $self (i32.const 4)))")]
    val length: i32

    #[@External.Wasm("(call $bp_arr_prepend (local.get $0) (local.get $self))")]
    fn prepend(self: Self, item: T) -> Self
}
```

### Adjacent — `to_string` rename to `toString` in `primitives.d.bp`

Memory (`feedback_camelcase_naming`) flagged 2026-06-07: `to_string`
in `primitives.d.bp` is legacy snake_case — normalise to `toString`
during this migration sweep since the same lines are touched.

## Compiler path

### F0 — extend the template renderer with property + BIF shape

- [ ] `comptime/primOpTemplate.zig`: nothing changes — the renderer is
      already structural. The new `@ExternalProperty.<Target>(...)`
      annotation just lands in a sibling dispatch table
      (`prop_<backend>_dispatch`) the val-access emit path consults.
- [ ] `ast.zig`: add `externalPropertyVariantTarget(name)` (mirror
      `externalVariantTarget`), reusing the same canonical-target table.
- [ ] `parser/decls.zig`: `parseValDecl` consumes property annotations
      on `val name: type` lines (today they parse but lower to nothing).

### F1 — BEAM Family 1 surface migration

- [ ] `libs/std/src/primitives.d.bp`: add `@External.Beam("template")`
      rows for every Array + String + Bool method that today lives in
      `beam_asm.zig`'s `emitPrimMethod` switch.
- [ ] `beam_asm.zig`: `collectPrimBeamDispatch` reads those entries
      into `prim_beam_dispatch`.
- [ ] `emitPrimMethod` in `beam_asm.zig` shrinks to the
      `tryEmitPrimAnnotation` path; delete the now-empty switch arms.

### F2 — wat Family 1 surface migration

- [ ] Same shape as F1 for the wat backend. The `.len` arm migrates
      via the `@ExternalProperty.Wasm(...)` form from F0.

### F3 — erlang `length` BIF migration (closes the irreducible allow-list)

- [ ] `libs/std/src/primitives.d.bp`: convert `len()`/`length()`/`size()`
      from interface methods to a `val length: i32` property carrying
      `@ExternalProperty.Erlang("length($self)")`.
- [ ] `erlang.zig`: delete the `len`/`length`/`size` switch arms in
      `emitPrimMethod`.

### F4 — commonJS property-vs-call surface

- [ ] `commonJS.zig`: route the `arr.length` / `s.length` call path
      through the `@ExternalProperty.Node("$self.length")` annotation
      instead of the inline `isNativeProperty` table; delete the table
      after every `length`-shape consumer migrates.

### F5 — final closure assertion

- [ ] `git grep "if (.*mem\.eql.*callee" modules/compiler-core/src/codegen/`
      finds zero hits in `emitPrimMethod` on every backend.
- [ ] Snapshot diff against pre-F1 HEAD is empty (every migration is
      byte-identical).

### F6 — `to_string` → `toString` normalisation

- [ ] Rename every `to_string` method in `primitives.d.bp` (and in
      consumers that haven't already aliased) to `toString`.
- [ ] Validate `zig build test-libs` stays green.

### F7 — docs

- [ ] `libs/std/AGENTS.md` §"Template grammar" — extend with the
      `@ExternalProperty.<Target>` form.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` §"§A6 closure" —
      remove the "irreducible allow-list" section; replace with a
      one-liner pointing at this spec's commit hashes.
- [ ] `CHANGELOG.md` under v0.beta.20:
      `feat(stdlib): every primitive-method lowering annotation-driven
       on every backend; emitPrimMethod switch arms deleted.`

## Test scenarios

```
F0       ---- @ExternalProperty annotation parses + the val-access emit path consults the prop dispatch table
F1-byte  ---- snapshot diff for every BEAM primitive-method scenario empty against pre-F1 HEAD
F1-empty ---- post-F1 `git grep "if (.*mem\.eql.*callee" codegen/beam_asm.zig | grep emitPrimMethod` finds zero hits
F2-byte  ---- snapshot diff for every wat primitive-method scenario empty against pre-F2 HEAD
F2-empty ---- post-F2 same grep in codegen/wat.zig finds zero hits in emitPrimMethod
F3-byte  ---- erlang `length($self)` snapshots match pre-F3
F4-byte  ---- commonJS `$self.length` snapshots match pre-F4
F5       ---- the §A6 closure assertion ships green; no codegen file has an emitPrimMethod switch arm
F6-libs  ---- libs/std + libs/erika + libs/jhonstart + libs/onze + libs/rakun all pass test-libs after the to_string→toString rename
F7-docs  ---- libs/std/AGENTS.md + codegen/AGENTS.md + CHANGELOG.md updated in the F5 commit
gate     ---- `zig build test` + `zig build test-libs` + `zig build test-backends` green
```

## Notes

- **Cross-spec interaction.** Together with
  `family-2-beam-wat-runtime-ops` and `family-3-block-builtin`, this
  spec retires the **last** `mem.eql(callee, …)` switch chains in
  `codegen/`. After all three land, every callee dispatch on every
  backend goes through `tryEmitPrimAnnotation` /
  `tryEmitBuiltinAnnotation`.
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.
