# prim-op — annotation-grammar extension + family migration (closes v0.beta.19 `prim-op-annotation` partial)

**Slug**: prim-op
**Depends on**: v0.beta.19 `prim-op-annotation` partial close (`64a3436` Family 1 9/19 erlang merged; `7f8f259` Family 2 erlang; `f9918b1` Family 2 commonJS).
**Files**: see each sub-spec — `parser/decls.zig` · `ast.zig` · `comptime/{comptime,transform}.zig` · `codegen/{erlang,beam_asm,commonJS,wat}.zig` · `libs/std/src/{builtins,primitives}.d.bp` · every `libs/<sib>/src/**/*.bp` (External.<Target> migration) · all AGENTS.md under compiler-core/.
**Touches docs**: every AGENTS.md under `repository/botopink-lang/modules/compiler-core/` (sweep at closeout) · `CHANGELOG.md`.
**Status**: partial — 9 sub-specs across 3 stages; 5 sub-specs have landed code in `origin/feat`.

## Current state (partials landed on origin/feat — meta 28929e2 / bot-lang 0568466)

### Active reds traced to prim-op merge

After merging `task/prim-op-annotation` into `feat`, **7 codegen tests
still fail** on `zig build test` (bot-lang):

| Test | Symptom | Root cause |
|---|---|---|
| `js_features.test.js: iterator fromList yields array items` | snap mismatch | template dispatch |
| `js_features.test.js: option method on tuple element` | erlang output `Rest = :(Xs, 1, length(Xs))` — should be `lists:sublist(Xs, …)` | `@External.Erlang` template lost the `module:` prefix on call-site emit (2-arg form `(module, symbol)` not routed through `tryEmitPrimAnnotation` correctly) |
| `js_features.test.js: array instance default-fn methods` | similar | same template dispatch |
| `js_features.test.js: string methods map to native JS names` | similar | same |
| `wat.test.wat: string slice copies bytes …` | erlang twin emits `Mid = :(S, 1, 5)` — should be `string:slice(S, 1, 4)` | same |
| `wat.test.wat: string slice without end arg slices to source length` | same | same |
| `wat.test.wat: string slice result length is readable` | same | same |

**All 7 share one root cause**: the prim-op-annotation merge bumped
`tryEmitPrimAnnotation` / `tryEmitBuiltinAnnotation` paths on erlang
but lost the 2-arg `@External.Erlang("module", "symbol")` resolution
that emits `module:symbol(args)` at the call site. Need to restore the
`module:` prefix emit when the annotation arg is a quoted module name
(not a `$`-bearing template string).

### Annotation-driven BIF table — landed via std/erlang (0568466)

Replaces the hardcoded `auto_imported_bifs` array in `codegen/erlang.zig`
with a scan of `libs/std/src/erlang.bp` (new module, `pub mod erlang;`
in `root.bp`). The `@External.Erlang("erlang", "<symbol>")` annotations
drive (symbol, arity) extraction → shadow table. Future extension:
when `fn-param-default-expansion` lands trailing defaults in
`declare fn`, contiguous arity ranges collapse to one decl each.



| Sub-spec | Landed | Remaining |
|---|---|---|
| **family-2-beam-wat-runtime-ops** | erlang (`7f8f259`) + commonJS (`f9918b1`) via `tryEmitBuiltinAnnotation` | BEAM + wat dispatch infra |
| **family-3-block-builtin** | — | @block across every backend |
| **template-instance-methods** | — | instance method template path on every backend |
| **external-target-libs-migration** | `libs/std/` + `libs/server/` via `5f0f1d9` + `85b199d` | `libs/{onze,rakun,erika,jhonstart}` + examples + tests sweep + legacy form retirement |
| **fn-param-default-expansion** | AST plumbing `Param.default` + `EnumVariantField.default` + `expandTrailingDefaults` (`4c2e62c` + `5f0f1d9`) | F0–F6 (builtins.d.bp split + receiver-bound default + 4 diagnostics + when-argc consumers) |
| **family-1-beam-wat-prim-methods** | Family 1 erlang 9/19 via `64a3436` | Family 1 BEAM + wat (consumes family-2 dispatch infra) |
| **when-argc-removal** | — | retire grammar (after every consumer migrates via fn-param-default-expansion) |
| **annotation-tail (§A2)** | commonJS (`a7c6d07`) + erlang (`52d6101`) per-callee template dispatch | BEAM + wat user-template dispatch — **FIX FIRST**: restore `module:symbol(args)` emit for 2-arg `@External.Erlang("module", "symbol")` form (lost during merge; 7 reds tracked in "Active reds" above) — and reconcile `$stringify` Ctx: currently guarded by `@hasDecl` so backends without `emitStringifyOpen` surface `PrimOpStringifyUnsupported` (which surfaces in `std·erlang` lib-test when a BIF wrapper triggers stringify) — proper fix is adding the open/close pair to every backend's Ctx struct |
| **agents-md-resync** | — | umbrella docs sweep |

## DAG

```
01-keystones (5, parallel)
  family-2-beam-wat-runtime-ops   (authors BEAM+wat dispatch infra)
  family-3-block-builtin
  template-instance-methods
  external-target-libs-migration
  fn-param-default-expansion

02-consumers (3, parallel; each picks 01 deps)
  family-1-beam-wat-prim-methods  ← family-2 + external-target + fn-param
  when-argc-removal               ← fn-param + external-target
  annotation-tail (§A2)           ← family-1/2/3 + template-instance-methods

03-closeout
  agents-md-resync (umbrella docs sweep)
```

---


---

## family-2-beam-wat-runtime-ops — drive `@Result` / `@Option` ops from annotations on BEAM + wat

**Slug**: family-2-beam-wat-runtime-ops
**Depends on**: `prim-op-annotation` commits `7f8f259` (erlang) +
`f9918b1` (commonJS) — Family 2 erlang + node landed via
`tryEmitBuiltinAnnotation`; this spec closes the remaining two backends.
**Files**:
- `modules/compiler-core/src/codegen/beam_asm.zig` — delete
  `emitResultOptionOp` (~lines 2624–2740); add `__bp_…` entries to a
  new `registerInlineBuiltinBeamDispatch` (mirror the erlang one); route
  the `__bp_` callee path through `tryEmitBuiltinAnnotation` (or its
  BEAM-side sibling).
- `modules/compiler-core/src/codegen/wat.zig` — delete
  `emitResultOptionOp` (~lines 1417–1570); add `__bp_…` entries
  to a new `registerInlineBuiltinWatDispatch`; route through dispatch.
- `modules/compiler-core/src/codegen/AGENTS.md` — §"Annotation-driven
  lowering" gains a BEAM + wat row.
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md` ·
  `CHANGELOG.md`.
**Status**: pending

### Background

`prim-op-annotation` Family 2 retired the hand-rolled `emitResultOptionOp`
switch on the erlang + commonJS backends (commits `7f8f259` + `f9918b1`):
the nine comptime-synthesised `__bp_…` callees now lower through
`tryEmitBuiltinAnnotation` reading from the `builtin_<backend>_dispatch`
table seeded in `registerInlineBuiltinDispatch`. The same shape works
for **BEAM** and **wat**, with two complications:

1. BEAM is bytecode — templates emit text but BEAM-asm emits opcodes
   like `put_tuple2 {atom,ok} V`, `move {atom,ok} {x,N}`, branches.
   A template string can capture those sequences (BEAM-asm is text
   too), but the renderer's `$self` / `$N` markers need a different
   stringifier (`emitArg` writes register tokens or atoms, not the
   target's value-rendering).

2. wat is wasm S-exprs — same issue: `$0` / `$1` are virtual
   slot indices the renderer doesn't natively understand on a
   stack-based VM. The `emitArg(i)` callback needs a wat-aware
   stringifier that emits a `(local.get $arg_i)` style fragment, with
   the caller setting up the stack frame for the inline fun.

This spec addresses both via a small extension to the template renderer
(per-backend marker policy on `emitArg`) and bulk migration to the
annotation-driven path.

### Premise

After this spec lands, **every backend** consumes `@Result` / `@Option`
runtime ops via one entry in `builtin_<backend>_dispatch` instead of a
hand-rolled `emitResultOptionOp` switch. The grammar surface is the
same single-string template form; the per-backend differences live in
the ctx struct each backend supplies to `primOpTemplate.render`.

### Target surface

Each backend's `register…Dispatch` gains the nine `__bp_…` entries (mirror
the erlang shape from `prim-op-annotation/7f8f259`):

```zig
// BEAM
try this.putInlineBeamBuiltin("__bp_ok", &.{
    .{ .argc = 1, .template = "{put_tuple2 {atom,ok} $0}" },
});
try this.putInlineBeamBuiltin("__bp_result_map", &.{
    .{ .argc = 2, .template =
        "(fun(R) -> case R of {ok, V} -> {ok, ($1)(V)}; _ -> R end end)($0)" },
});
// ... etc, mirror the erlang templates (BEAM consumes the same Erlang
//     source emitter — the `$N` substitutions render the same way).
```

```zig
// wat
try this.putInlineWatBuiltin("__bp_ok", &.{
    .{ .argc = 1, .template =
        "(struct.new $bp_result_ok $0)" },
});
try this.putInlineWatBuiltin("__bp_result_map", &.{
    .{ .argc = 2, .template =
        "(if (struct.test $bp_result_ok $0) (then (struct.new $bp_result_ok (call_ref $1 (struct.get $bp_result_ok 0 $0)))) (else $0))" },
});
// ... etc.
```

The caller path collapses to:

```zig
if (std.mem.startsWith(u8, cc.callee, "__bp_")) {
    if (try this.tryEmitBuiltinAnnotation(cc.callee, cc)) return;
    return error.UnmappedBpRuntimeOp;
}
```

`emitResultOptionOp` is deleted on both backends.

### Compiler path

#### F0 — BEAM Family 2

- [ ] `beam_asm.zig`: add `registerInlineBuiltinBeamDispatch` mirroring
      the erlang shape; seed the nine `__bp_…` entries with BEAM-asm
      templates.
- [ ] Route the `__bp_` callee dispatch path through
      `tryEmitBuiltinBeamAnnotation` (or extend the existing
      `tryEmitBuiltinAnnotation` to accept BEAM ctx shape).
- [ ] Delete `emitResultOptionOp` in `beam_asm.zig`.

#### F1 — wat Family 2

- [ ] `wat.zig`: add `registerInlineBuiltinWatDispatch`; seed the nine
      `__bp_…` entries with wasm-instruction templates.
- [ ] Route the `__bp_` callee path through dispatch.
- [ ] Delete `emitResultOptionOp` in `wat.zig`.

#### F2 — tests + snapshots

- [ ] Existing `@Result` / `@Option` snapshot tests on BEAM + wat diff
      empty against pre-F0 HEAD (byte-identical migration).
- [ ] Negative: a synthesised `__bp_garbage` callee reds with
      `UnmappedBpRuntimeOp` on each backend (not silently emit nothing).

#### F3 — docs

- [ ] `codegen/AGENTS.md` §"Annotation-driven lowering" gains a row for
      BEAM + wat:
      `BEAM | tryEmitBuiltinBeamAnnotation → builtin_beam_dispatch | seeded inline at registerInlineBuiltinBeamDispatch.`
- [ ] `CHANGELOG.md` under v0.beta.20:
      `refactor(codegen): @Result/@Option ops annotation-driven on every backend; emitResultOptionOp deleted.`

### Test scenarios

```
F0-byte   ---- diff snapshots/codegen/beam/ for @Result/@Option fixtures against pre-F0 HEAD: empty
F1-byte   ---- diff snapshots/codegen/wat/ for @Result/@Option fixtures against pre-F1 HEAD: empty
F2-empty  ---- post-F1 `git grep emitResultOptionOp modules/compiler-core/src/codegen/` finds zero hits
F2-red    ---- `__bp_garbage` reds with UnmappedBpRuntimeOp on every backend
F3-docs   ---- codegen/AGENTS.md + CHANGELOG.md updated in the same commit as the last F1 hunk
gate      ---- `zig build test` + `zig build test-libs` + `zig build test-backends` green
```

### Notes

- **Cross-spec interaction.** Completes Family 2 of
  `prim-op-annotation`'s migration table — closes the last item on
  "post-F2 `git grep 'if (eq(u8, callee,' codegen/erlang.zig
  codegen/beam_asm.zig codegen/commonJS.zig codegen/wat.zig` finds zero
  hits" (the spec's F2-empty test scenario).
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.

---

## family-3-block-builtin — drive `@block` from annotations across every backend

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

### Background

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

### Premise

After this spec lands, **every** Frente B builtin (`@print` / `@todo` /
`@panic` / `@block`) lowers from a single `#[@External.<Target>(...)]`
entry; no codegen file has a `mem.eql(cc.callee, "block")` arm; the
trailing-lambda surface (`@block { ... }`) keeps parsing as today and
the renderer reads the body via the `$body` substitution marker (new —
see §F0 below).

### Target surface

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

### Compiler path

#### F0 — extend the template renderer with `$body`

- [ ] `comptime/primOpTemplate.zig`: add a `$body` marker that, when
      encountered, calls `ctx.emitBody()` — backend supplies the
      emit-lambda-body callback that walks `cc.trailing[0].body` and
      writes each statement to the output (each backend already has
      this routine).
- [ ] Diagnostic RP7 (new): `$body` in a template that doesn't carry
      a trailing lambda call site → `prim-op-body-no-trailing-lambda`.
- [ ] Tests in `tests/codegen/prim_op_templates.zig` cover happy path +
      RP7.

#### F1 — declare `fn block<T>` with annotations

- [ ] `libs/std/src/builtins_fns.d.bp`: add the `fn block<T>` row with
      the four `@External.<Target>(...)` annotations from §"Target
      surface" above.
- [ ] Verify `registerStdlib` (from `fn-param-default-expansion` §F0)
      picks up the `block` entry into `fn_decls`.
- [ ] `expandTrailingDefaults` (or its sibling for trailing lambdas)
      is unchanged — `block` takes exactly one fn-typed arg with no
      default, so arity check fires if user wrote `@block` without
      braces.

#### F2 — backend dispatch migration

- [ ] `erlang.zig`: delete the `mem.eql(cc.callee, "block")` arm in
      the builtin call switch (~line 2139); the
      `tryEmitBuiltinAnnotation` path picks it up via the entry seeded
      from F1.
- [ ] `commonJS.zig`: delete the `is_block` branch (~line 2597).
- [ ] `beam_asm.zig`: delete the `block` arm (~line 2591).
- [ ] `wat.zig`: delete the `block` arm (~line 1310).
- [ ] Each backend's ctx struct gains an `emitBody` method routing to
      its existing emit-block routine.

#### F3 — tests

- [ ] Existing `@block` snapshot scenarios diff empty against pre-F2
      HEAD on every backend (byte-identical migration).
- [ ] New: `@block` with a `return` inside the body lands in the
      enclosing fn's return slot (the IIFE convention) on every
      backend — guards against accidental swallowing.
- [ ] New: nested `@block` ( `@block { val r = @block { 1 + 1 }; r * 2 }`)
      renders the same on every backend.

#### F4 — docs

- [ ] `libs/std/AGENTS.md` §"Template grammar" — add the `$body`
      marker row + RP7 diagnostic.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` §"Annotation-driven
      lowering" — drop `@block` from the residual list.
- [ ] `CHANGELOG.md`:
      `refactor(codegen): @block annotation-driven on every backend.`

### Test scenarios

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

### Notes

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

---

## prim-op-template-instance-methods — extend `@external` template to instance methods on every backend

**Slug**: prim-op-template-instance-methods
**Depends on**: nothing in v0.beta.20 — file-disjoint with every other
  v0.beta.20 spec at the source level. (Honest discovery during
  v0.beta.19 §A7: the gate is not BEAM bytecode templates as
  originally framed — it's that NO backend's codegen consumes
  `@external(<backend>, "<template>")` for instance methods today.
  This spec fills that gap on all 4.)
**Files**: `modules/compiler-core/src/codegen/{commonJS,erlang,beam_asm,wat}.zig`
  (annotation consumer for instance methods) · `libs/std/src/primitives.d.bp`
  (new method authored via 1 annotation per backend) · new
  `modules/compiler-core/src/codegen/tests/primitive_methods_byte_identical.zig`
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md` ·
  `libs/std/AGENTS.md`
**Status**: pending

### Background

The `prim-op-annotation` keystone (v0.beta.19 satellite) landed
dispatch-table support for **associated** prim methods (no `self`
receiver — `Array.range`, `Pair.of`). Adding a new **instance**
method (`xs.zip(ys)`) via one `#[@external]` per backend was the
explicit goal of v0.beta.19's §A7, but the attempt revealed that
no backend's codegen consumes `@external(<backend>, "<template>")`
for instance method calls — the prototype patchers on commonJS and
the call-site emitters on erlang/beam/wat all assume host-symbol
form (`mod.symbol` / `module:symbol`), not `$`-marker template
form.

Once each backend's instance-method emitter learns to render a
template (`primOpTemplate.render` already exists — just route to
it), adding `Array.zip` (or any future method) is **one** annotation
per backend in `primitives.d.bp` + a test fixture.

This is the pattern that lets the language ship new prim methods at
zero `.zig` cost going forward — a strict generalisation of the §A
keystone refactor from v0.beta.19.

### Checklist

- [ ] **F1-commonJS** — Extend the prototype patcher in
      `codegen/commonJS.zig` so an interface `fn` (not `default fn`)
      carrying `@external(node, "<template>")` patches
      `<Owner>.prototype.<method>` with a JS body rendered via
      `primOpTemplate.render` (`$self → this`, `$N → arguments[N]`,
      `$args → ...arguments`).
- [ ] **F2-erlang** — At the call site in `codegen/erlang.zig`,
      `recv.method(args)` whose method is an annotated instance
      template renders the body inline. `tryEmitPrimAnnotation`
      already runs for receiver `.prim`-tagged calls; extend it to
      also recognise non-`default fn` instance methods (the existing
      iteration over `i.methods` filters out non-default — drop
      that filter and gate by "method has `@external(erlang, "<template>")`"
      instead).
- [ ] **F3-beam** — Same as F2 on `codegen/beam_asm.zig`. The
      `tryEmitPrimAnnotation` path already routes to
      `primRecvOnly` / `primFunThenList` / `primRecvThenArgs` based
      on the template shape — extend to read instance-method
      annotations alongside default-fn ones.
- [ ] **F4-wat** — Same on `codegen/wat.zig`. Simple
      `(local.get $self) ... call $...` shapes ship here. Inline-fun
      shapes (the `iolist_to_binary(lists:join(...))` family) are
      not portable to wasm without compile-time AST work — record
      as a known gap in the AGENTS row and route those to the
      [`beam-inline-prim-methods`](frente-a.md) spec
      for the BEAM equivalent.
- [ ] **F5-array-zip** — `Array.zip<U>(self: Self, other: U[]) ->
      Array<#(T, U)>` lands in `primitives.d.bp` with ONE annotation
      per backend. Suggested templates:
      - commonJS: `$self.map((__x, __i) => [__x, ($0)[__i]]).slice(0, Math.min($self.length, ($0).length))`
      - erlang: `lists:zipwith(fun(__X, __Y) -> {__X, __Y} end, lists:sublist($self, length($0)), lists:sublist($0, length($self)))`
      - beam: same shape (template-driven)
      - wat: deferred — log as known gap (no native zip in wat; needs
        a generated helper which is out of scope here).
- [ ] **F6-test** — `primitive_methods_byte_identical.zig`: compile a
      fixture using `xs.zip(ys)` on each backend and assert the
      emitted code shape **without editing any `.zig`** in the
      lowering paths. F4's wat deferral keeps the test 3-of-4 there.

### Test scenarios

```
F5-erlang ---- `[1,2,3].zip(["a","b","c"])` emits the
                `lists:zipwith(fun(__X,__Y)->{__X,__Y} end, ...)`
                shape; runs under escript → `[{1,<<"a">>},{2,<<"b">>},{3,<<"c">>}]`.
F5-node    ---- same fixture on node emits the `$self.map((__x, __i)
                => [__x, ($0)[__i]])...` form; runs → `[[1,"a"],[2,"b"],
                [3,"c"]]`.
F5-beam    ---- same template renders at register level via
                `tryEmitPrimAnnotation`; `erlc +from_asm` assembles
                + the result matches the erlang fixture.
F6         ---- the test fixture compiles on 3+ targets with ZERO
                .zig edits in the codegen lowering paths.
```

### Notes

- **Template grammar** lives in `comptime/primOpTemplate.zig` (markers
  `$self` / `$0..N` / `$args`); this spec only adds **consumer**
  sites in the per-backend emitters.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.
- Future prim methods (`Array.chunks`, `String.repeat`,
  `Array.partition`) follow the same pattern.

---

## external-target-libs-migration — migrate libs to `@External.<Target>` and retire the legacy `@external` form

**Slug**: external-target-libs-migration
**Depends on**: `prim-op-annotation` commit `85b199d` (codegen recognises
`#[@External.<Target>(...)]`) + commit `5f0f1d9` (`libs/std/src/` and
`libs/server/src/` already migrated).
**Files**:
- `libs/onze/src/**/*.bp` · `libs/rakun/src/**/*.bp` ·
  `libs/erika/src/**/*.bp` · `libs/jhonstart/src/**/*.bp` — every
  `#[@external(target, ...)]` annotation migrates to
  `#[@External.<Target>("template")]`.
- `examples/**/*.bp` + `tests/**/*.bp` — same sweep over downstream test
  fixtures.
- `modules/compiler-core/src/ast.zig` — once every `.bp` file in the
  monorepo migrates, retire the legacy `fn external(target, mod, sym,
  inline: bool = false)` declaration in `builtins.d.bp` and remove the
  legacy branch in `externalAnnotationTargetsExt` / `externalBodyArgsExt`
  / `FnDecl.isExternal` / `InterfaceMethod.isExternal`.
- `modules/compiler-core/src/parser.zig` — no parser change needed (the
  qualified-path parsing already accepts `External.<Variant>`); the
  legacy `external` fn-annotation just falls out of test coverage.
**Touches docs**: `libs/std/AGENTS.md` (§"External annotation
  vocabulary") · per-lib AGENTS.md (onze/rakun/erika/jhonstart) ·
  `CHANGELOG.md`.
**Status**: pending

### Background

`prim-op-annotation` commit `85b199d` plumbed the `#[@External.<Target>(...)]`
annotation form through the codegen readers (`externalAnnotationTargetsExt`
+ `externalBodyArgsExt` + `FnDecl.isExternal` + `InterfaceMethod.isExternal`).
Commit `5f0f1d9` migrated `libs/std/src/` + `libs/server/src/` to the new
form. The other four libs in the monorepo (`libs/onze`, `libs/rakun`,
`libs/erika`, `libs/jhonstart`) still ship `#[@external(target, "mod",
"sym")]` annotations — both forms parse + dispatch identically today.

After every consumer in the monorepo migrates, the legacy `external`
fn-annotation can retire:
- The `fn external(target: Target, module: string, symbol: string,
  inline: bool = false)` decl in `libs/std/src/builtins.d.bp`.
- The "legacy 2-arg form" branches in
  `externalAnnotationTargetsExt` / `externalBodyArgsExt`.
- The "external" name match in `FnDecl.isExternal` /
  `InterfaceMethod.isExternal`.

This spec ships both halves: the sweep + the retirement.

### Premise

After this spec lands, the only host-backed lowering annotation in the
monorepo is `#[@External.<Target>("template")]`. The grammar surface
is the single typed-enum form documented in `builtins.d.bp`'s
`pub enum External implement Annotation`. Legacy support is removed.

### Target migration table

Mechanical sed-driven transform per file:

| Before | After |
|---|---|
| `@external(erlang, "mod", "sym")` | `@External.Erlang("mod", "sym")` |
| `@external(erlang, "$self.template")` | `@External.Erlang("$self.template")` |
| `@external(node, "mod", "sym")` | `@External.Node("mod", "sym")` |
| `@external(node, "sym")` (node-prototype shorthand) | `@External.Node("sym")` |
| `@external(beam, ...)` | `@External.Beam(...)` |
| `@external(wasm, ...)` | `@External.Wasm(...)` |
| `@external(typescript, ...)` | `@External.Typescript(...)` |
| `@external(target, ...)` with `inline: true` | `@External.<Target>(..., inline: true)` |

Same sweep works for both `#[@external(...)]` and bare
`#[external(...)]` (the `@`-less form fires inside `builtins.d.bp`'s
own decls, per the user's bare-name rule for self-refs).

### Compiler path

#### F0 — migrate `libs/onze`

- [ ] `libs/onze/src/**/*.bp`: sed every `@external(target, ` to
      `@External.<Target>(`. Reconcile any `inline: true` flag
      positions.
- [ ] `libs/onze/AGENTS.md`: replace `@external` references with the
      new form.
- [ ] `botopink test` in `libs/onze/` stays green.

#### F1 — migrate `libs/rakun`

- [ ] Same shape as F0. The `rakun` framework has server-side
      `@external(erlang, "node_http", ...)` style annotations; migrate
      each carefully (host symbol templates may carry `:` characters
      that read as namespace separators).

#### F2 — migrate `libs/erika`

- [ ] Same shape as F0.

#### F3 — migrate `libs/jhonstart`

- [ ] Same shape as F0. The jhonstart `html` DSL has its own
      `@[external]` legacy pattern (memory `feedback_external_annotation_form`):
      the migration ALSO normalises any surviving `@[external]` →
      `#[@External.<Target>]`.

#### F4 — sweep `examples/` + `tests/`

- [ ] Same mechanical transform across `examples/**/*.bp` and
      `tests/**/*.bp`.

#### F5 — retire the legacy form in the compiler

- [ ] `libs/std/src/builtins.d.bp`: delete the `fn external(target,
      module, symbol, inline: bool = false)` declaration (the typed-enum
      `pub enum External implement Annotation` form remains).
- [ ] `modules/compiler-core/src/ast.zig`:
      - `externalAnnotationTargetsExt`: drop the
        `std.mem.eql(u8, a.name, "external")` branch.
      - `externalBodyArgsExt`: same.
      - `FnDecl.isExternal`: drop the `"external"` match (keep the
        `externalVariantTarget` match).
      - `InterfaceMethod.isExternal`: same.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` §"§A5 external
      annotation surface": replace the dual-form description with the
      single `@External.<Target>` form.

#### F6 — diagnostics for unknown variants

- [ ] `ast.externalVariantTarget` returns null for any unknown variant
      (already the case). Make a `parseAnnotationCall`-time diagnostic
      fire for `@External.Foo(...)` where `Foo` isn't one of
      `{ Erlang, Node, Beam, Wasm, Typescript, NodePrototype }`:
      diagnostic code `EX1` (`external-unknown-target`).
- [ ] Add tests covering EX1 + every known variant.

#### F7 — docs

- [ ] `libs/std/AGENTS.md` §"External annotation vocabulary": single
      grammar; the dual-form table goes away.
- [ ] Each lib's AGENTS.md updated in the migration commit.
- [ ] `CHANGELOG.md`:
      `refactor(annotations): @External.<Target> is the only host-backed
       lowering annotation form; legacy @external() retired.`

### Test scenarios

```
F0–F3      ---- every `botopink test` per migrated lib stays green; snapshot diffs empty
F4         ---- examples + tests sweep doesn't break any backend's example runner
F5         ---- post-F5 `git grep '@external(' libs/ modules/ examples/ tests/` finds zero hits outside comments
F5-empty   ---- post-F5 `git grep '"external"' modules/compiler-core/src/ast.zig` (case-sensitive) finds zero hits in the annotation-reading helpers
F6-EX1     ---- `@External.UnknownTarget("x")` reds with external-unknown-target
F7-docs    ---- AGENTS.md + CHANGELOG.md updated in the F5 commit
gate       ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green
```

### Notes

- **Cross-spec interaction.** Completes the migration started by
  `prim-op-annotation` commit `5f0f1d9` for the rest of the monorepo,
  closing the back-compat shim explicitly kept "so external callers
  (libs/onze, libs/rakun, libs/erika, libs/jhonstart) can migrate at
  their own pace" (see `5f0f1d9`'s commit message).
- **Coordinate with lib maintainers.** Each lib has its own task track
  in the meta repo. This spec assumes all four lib worktrees can land
  the per-lib F0–F3 hunks in parallel + the meta F5 retire commit
  bumps every submodule's tip in one go.
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.

---

## fn-param-default-expansion — unify call-site default injection across calls / annotations / record + enum constructors

**Slug**: fn-param-default-expansion
**Depends on**: `prim-op-annotation` commit `4c2e62c` (the unified
`Param.default: ?Expr` + `EnumVariantField.default: ?Expr` AST slot,
parsed by `parser/decls.parseParam` + `parseEnumBody`); commit `5f0f1d9`
(the partial `expandTrailingDefaults` helper in `comptime/transform.zig`
+ the `CallArg.is_default_inj` flag in `ast.zig`).
**Files**:
- `modules/compiler-core/src/comptime.zig` (extend `registerStdlib` so
  `prelude.builtins` enters the parse path without tripping inference on
  the pre-defined `Result<R, E>` / `Future<T, E>` / `Iterator<T>` /
  `Generator<T, R>` / `AsyncIterator<T, E>` / `Context<B, R>` interfaces).
- `modules/compiler-core/src/comptime/transform.zig` (extend
  `expandTrailingDefaults` to handle: receiver method calls; trailing
  lambdas + positional args mix; named-arg label `name: value` with
  defaults sitting before / between supplied args).
- `modules/compiler-core/src/comptime/infer.zig`
  (`recordFieldsAsParams` / `structFieldsAsParams` /
  `enumVariantAsParams` already pass `f.default` through unchanged after
  `4c2e62c`; this spec wires the **arity check + injection** at the
  record / enum constructor call site, mirroring `expandTrailingDefaults`
  for fn calls).
- `modules/compiler-core/src/codegen/{erlang,beam_asm,commonJS,wat}.zig`
  (collapse the two-branch `argc==0`/`argc==1` inline seeds for `todo` /
  `panic` to one branch; remove the `when(argc == N)` clause from
  `Array.slice` + `String.slice` in `libs/std/src/primitives.d.bp` once
  the inference path can inject `end: i32 = self.length()` defaults).
- `libs/std/src/builtins.d.bp` + `libs/std/src/primitives.d.bp` (the
  surface migrations once the compiler path is ready).
- `modules/compiler-core/src/parser/tests/declarations.zig` +
  `modules/compiler-core/src/codegen/tests/*` (per-surface regression
  tests; see §"Tests" below).
- `tests/codegen/fn_param_defaults.zig` (new — gate every default-
  injection shape against a snapshot bank).
**Touches docs**: `modules/compiler-core/AGENTS.md` (`parser/` +
  `comptime/` subsections) · `libs/std/AGENTS.md` (§"Default values in
  fn-decl param lists") · `CHANGELOG.md` (one line under v0.beta.20).
**Status**: pending

### Background

`prim-op-annotation` (v0.beta.19) needed `Param.default: ?Expr` so the
documented `fn todo(message: string = "not implemented") noreturn`
annotation surface in `libs/std/src/builtins.d.bp` could be a single
1-arity template under `@External.<Target>(...)`. The AST + parser
landed (commit `4c2e62c`), the call-site injection helper
`expandTrailingDefaults` landed too (commit `5f0f1d9`), but **two**
follow-up gaps blocked the full surface from landing:

1. `libs/std/src/builtins.d.bp` is **not** in the `registerStdlib` parse
   path — adding `prelude.builtins` to it trips inference on the
   pre-defined `Result<R, E>` / `Future<T, E>` / `Iterator<T>` /
   `Generator<T, R>` / `AsyncIterator<T, E>` / `Context<B, R>` interfaces
   the compiler synthesises before the user program is parsed. So
   `todo` / `panic` have no `FnDecl` entry in the `fn_decls` map
   `expandTrailingDefaults` consults; the inline-seeded dispatch in
   `erlang.zig` / `commonJS.zig` is forced to keep its two-branch
   (`argc==0` / `argc==1`) form, with `when(argc == N)` semantics
   reproduced in-Zig rather than in the `.bp` surface.

2. `Array.slice(self, start, end)` + `String.slice(self, start, end)` in
   `libs/std/src/primitives.d.bp` want `end: i32 = self.length()` as the
   default — a **non-literal** default (a method call on `self`). The
   `expandTrailingDefaults` helper today copies a *reference* to the
   `FnDecl.params[i].default` Expr; that Expr is owned by the decl's
   arena, and the method-receiver self is unbound at the call site. So
   the slice migrations away from `when(argc == N)` (the only surviving
   uses in the codebase) cannot land until the receiver-bound default
   path is wired.

This spec closes both gaps and ships the surface migrations they unblock.

### Premise

A `default` value on a param is the **same fact** whether it lives on a
fn call, an annotation, a record constructor, or an enum variant
constructor — à la Kotlin's named-arg + default rules. The only thing
that changes across surfaces is the brace / paren framing and the named-
arg sigil (`label: value` in bp). The compiler honours that uniformity:
one AST slot, one injection helper, one set of diagnostics.

The injection happens **before dispatch**, so the codegen sees a fully-
specified arg list and renders the same template every time. No backend
needs an `argc`-branch arm; no `when(argc == N)` syntax survives in the
surface.

### Target surface

#### 1 — fn-decl call with trailing literal default (`todo`)

**Before** (built-ins surface, the doc-only file
`libs/std/src/builtins.d.bp`):

```bp
#[External.Erlang("erlang:error({todo, $0})"),
  External.Node("(() => { throw new Error($0) })()")]
fn todo(message: string = "not implemented") noreturn

#[External.Erlang("erlang:error({panic, $0})"),
  External.Node("(() => { throw new Error($0) })()")]
fn panic(message: string = "panic") noreturn
```

**Before** (codegen inline-seeded dispatch, two-branch shape currently
held in `erlang.zig` + `commonJS.zig`):

```zig
try this.putInlineErlangBuiltin("todo", &.{
    .{ .argc = 0, .template = "erlang:error({todo, \"not implemented\"})" },
    .{ .argc = 1, .template = "erlang:error({todo, $0})" },
});
```

**After** (codegen one-branch shape — the default flows from
`prelude.builtins`'s `FnDecl.params[0].default` into the call's args at
`expandTrailingDefaults` time):

```zig
try this.putInlineErlangBuiltin("todo", &.{
    .{ .argc = 1, .template = "erlang:error({todo, $0})" },
});
```

**Caller surface** — unchanged. `todo()` / `todo("not yet")` / `panic()`
/ `panic("boom")` all parse, type-check, and lower correctly through the
single 1-arity template.

#### 2 — fn-decl call with receiver-bound default (`slice`)

**Before** (`primitives.d.bp`, the only surviving `when(argc == N)`
clauses in the codebase):

```bp
#[@External.Erlang(
    when(argc == 1): "string:slice($self, $0)",
    when(argc == 2): "string:slice($self, $0, (($1) - ($0)))"),
  @External.Node("./gleam_stdlib.mjs", "string_slice")]
fn slice(self: Self, start: i32, end: i32) -> string
```

**After**:

```bp
#[@External.Erlang("string:slice($self, $0, (($1) - ($0)))"),
  @External.Node("./gleam_stdlib.mjs", "string_slice")]
fn slice(self: Self, start: i32, end: i32 = self.length()) -> string
```

**Caller surface** — `s.slice(2)` and `s.slice(2, 5)` both parse; the
1-arg call expands to `s.slice(2, s.length())` at inference time and
renders through the single template.

#### 3 — record constructor with default field

```bp
record Config(
    host: string = "localhost",
    port: i32 = 8080,
    tls: bool = false,
)

val cfg1 = Config()                          // → Config("localhost", 8080, false)
val cfg2 = Config(host: "example.com")       // → Config("example.com", 8080, false)
val cfg3 = Config(port: 9000, tls: true)     // → Config("localhost", 9000, true)
```

#### 4 — enum variant constructor with default field

```bp
enum Level {
    Info(message: string = "info"),
    Warn(message: string = "warning"),
    Error(message: string, code: i32 = -1),
}

val a = Level.Info()                  // → Level.Info("info")
val b = Level.Warn()                  // → Level.Warn("warning")
val c = Level.Error("boom")           // → Level.Error("boom", -1)
val d = Level.Error("boom", code: 42) // → Level.Error("boom", 42)
```

#### 5 — annotation with default field (Kotlin parity)

```bp
struct ServiceOpts(
    name: string,
    replicas: i32 = 1,
    public: bool = false,
)

#[ServiceOpts(name: "api")]              // replicas=1, public=false
record ApiService(...)

#[ServiceOpts(name: "auth", replicas: 3)] // public=false
record AuthService(...)
```

This is the rule the `infer.zig` decorator validator already approximates
(via `recordFieldsAsParams` / `structFieldsAsParams`) — this spec wires
the *injection* of the missing trailing fields, not just the arity
check.

#### 6 — named args + defaults (skip-middle is the error)

Kotlin-style: trailing defaults are auto-injected; **middle** defaults
require the call to either supply that arg positionally or use the
named-arg label for the trailing arg(s).

```bp
fn connect(host: string, port: i32 = 80, timeout: i32 = 30) -> bool { ... }

connect("example.com")                       // ok → connect("example.com", 80, 30)
connect("example.com", 8080)                 // ok → connect("example.com", 8080, 30)
connect("example.com", timeout: 60)          // ok → connect("example.com", 80, 60)
connect("example.com", 8080, 60)             // ok
connect("example.com", port: 8080, timeout: 60) // ok
```

The rule mirrors the §1G strict-trailing-position rule already enforced
for generic type-parameter defaults: defaults occupy **trailing**
positions only (a non-defaulted param after a defaulted one is rejected
at parse time, with diagnostic code `D5`).

### Compiler path

#### F0 — `prelude.builtins` parse path (gap #1)

The current `registerStdlib` parses only `prelude.primitives`. Parsing
`prelude.builtins` trips inference because the file declares the
`Result<R, E>` / `Future<T, E>` / `Iterator<T>` / `Generator<T, R>` /
`AsyncIterator<T, E>` / `Context<B, R>` interfaces that the compiler
already synthesises before user code runs.

Two paths to pick from:

- **Path A** — split `builtins.d.bp` into a "decl-only fn block" file
  (`builtins_fns.d.bp` carrying only `fn todo`, `fn panic`, `fn emit`,
  `fn module`, `fn getContex<T>`, the runtime `fn trap`, and any future
  fn additions) and have `registerStdlib` parse just that. The
  interface-bearing chunks (`Result`, `Future`, …) stay declarative-only
  and the inference-side synthetic registration stays untouched.

- **Path B** — extend the parser with a `#[skipSeed]` marker on each
  pre-defined interface so `registerStdlib` can skip them during the
  builtins parse. More invasive (parser marker + skip table + diagnostic
  for an unknown marker) and reads less obviously.

**Picks Path A.** The file split is straightforward, keeps every doc
co-located in `builtins.d.bp` (the interface decls), and gives the
synthetic-fn parse path one small input that's known-clean.

After F0 lands, the `fn_decls` map in `comptime.zig` (lines 893 + 1062)
carries entries for `todo` / `panic` / `emit` / `module` / `trap` /
`getContex<T>` with their full `[]Param` lists; `expandTrailingDefaults`
finds them and injects the defaults.

#### F1 — receiver-bound defaults (gap #2)

`expandTrailingDefaults` today reuses the param's own `Expr` slot:

```zig
new_args[i] = .{
    .label = null,
    .value = @constCast(&fn_decl.params[i].default.?),
    .comments = &.{},
    .is_default_inj = true,
};
```

That works for literal defaults (string / int / float / bool) but
mishandles receiver-bound defaults like `end: i32 = self.length()` —
`self` inside the default refers to the param decl's `self`, not the
call site's receiver, so the injected Expr can't be rendered correctly
in every call context.

**Rewrite path**: when the default Expr contains a `self` identifier,
walk the Expr at injection time and rewrite each `self` reference to the
call's receiver Expr (cloned shallow into the spec arena). The walk is
target-agnostic — same code, all four backends benefit.

The walk must:
- Recurse through `binaryOp`, `unaryOp`, `methodCall`, `fieldAccess`,
  `subscript`, `case`, `if`, lambdas, etc.
- Stop at **inner** fn-decl boundaries (a lambda's own `self` if it
  declared one shouldn't be rebound).
- Preserve the loc of every rewritten node so diagnostics still point
  at the param's default-expression position.

#### F2 — diagnostics

| # | Author wrote | Diagnostic |
|---|---|---|
| D1 | `fn f(a: i32 = 1, b: i32)` | `fn-param-default-trailing-only: a defaulted parameter must be followed only by other defaulted parameters. Move \`a\` to the end of the list or give \`b\` a default.` |
| D2 | `Config(host: "x", "y")` (positional after named) | `fn-param-positional-after-named: positional argument supplied after a named one. Convert \`"y"\` to a named arg.` |
| D3 | `connect()` when `host` has no default | `fn-param-default-arity-mismatch: \`connect\` requires 1 argument (\`host\`), got 0.` |
| D4 | `Color.Rgb()` when the variant has 3 non-defaulted fields | `enum-variant-arity-mismatch: \`Color.Rgb\` expects 3 fields (\`r\`, \`g\`, \`b\`), got 0.` (D3 wording with the enum-variant tail) |
| D5 | `fn f(a: i32 = 1, b: i32)` at parse time (same source as D1) — the parse-time companion that fires before D1 at decoration of an interface method or struct getter. | `fn-param-default-trailing-only-parse: same wording, fires from `parser/decls.parseParam`.` |
| D6 | `s.slice(2, 5, 99)` (more args than params) | `fn-param-arity-exceeded: \`String.slice\` takes 2 arguments (after the receiver), got 3.` |

### Steps

#### F0 — split `builtins.d.bp`
- [ ] Extract `fn todo`, `fn panic`, `fn emit`, `fn module`, `fn trap`,
      `fn getContex<T>`, `fn field<T,F>` from `libs/std/src/builtins.d.bp`
      into a new `libs/std/src/builtins_fns.d.bp`. Keep the interface +
      enum + struct decls in `builtins.d.bp` unchanged (they remain
      doc-only for now).
- [ ] `comptime/std_prelude.zig` (or the embed-path equivalent) imports
      `builtins_fns.d.bp` alongside `primitives.d.bp` and exposes it as
      `prelude.builtin_fns`.
- [ ] `registerStdlib` in `comptime.zig` parses both `prelude.primitives`
      and `prelude.builtin_fns` into `env.arena`; `inferProgram` runs
      against both so the synthetic-fn binding lands in `env.bindings`
      and reaches the `fn_decls` map.
- [ ] Confirm that `expandTrailingDefaults` now matches a bare `todo()`
      call to the parsed `FnDecl` and injects `"not implemented"` into
      the args slice.

#### F1 — receiver-bound default rewrite
- [ ] `comptime/transform.zig`: extend `expandTrailingDefaults` so when
      `c.receiver` is non-null and the default Expr contains a `self`
      reference, clone the Expr shallow into `spec_cache.arena` and walk
      it rebinding `self` to a shallow-clone of the receiver.
- [ ] `comptime/expr_walk.zig` (new): tiny visitor that recurses through
      every Expr variant and applies a rewrite predicate at each
      `identifier` node. Re-usable for the F4 instance-method default
      case below.
- [ ] Test: `s.slice(2)` on a `string s = "hello"` lowers to the same
      bytes that `s.slice(2, s.length())` would lower to.

#### F2 — diagnostics
- [ ] Reserve D1–D6 in `comptime/diagnostics.zig`.
- [ ] `parser/decls.parseParam`: emit D5 when a non-defaulted param
      appears after a defaulted one (parse-time fail-fast).
- [ ] `comptime/infer.zig`: emit D1 / D3 / D4 / D6 at arity-check time.
- [ ] D2 fires from `parser/decls.parseAnnotationCall` +
      `parser/expressions.parseCallExpr` when a positional arg follows a
      named one.

#### F3 — surface migrations
- [ ] `libs/std/src/builtins.d.bp` — `todo` / `panic` keep their
      one-template `@External.<Target>(...)` annotations + the
      `= "not implemented"` / `= "panic"` defaults.
- [ ] `libs/std/src/primitives.d.bp` — `Array.slice` + `String.slice`
      drop their `when(argc == N)` clauses, gain `end: i32 = self.length()`
      defaults, and the templates collapse to one each.
- [ ] `codegen/{erlang,commonJS}.zig` — `registerInlineBuiltinErlangDispatch`
      / `registerInlineBuiltinDispatch` collapse to single-branch entries
      for `todo` and `panic` (the `argc==0` branches die).
- [ ] The arity-branch infra in `ast.zig`
      (`ArityBranch` / `parseArityBranchArg` /
      `externalHasArityBranches` / `externalArityBranchFor`) + the
      backend dispatch glue is **kept** as the safety net for any third-
      party host fn that still wants per-arity templates; the migration
      removes only stdlib usages.

#### F4 — extend to record + enum + struct constructors
- [ ] `comptime/infer.zig`: record / struct / enum variant constructor
      calls walk through `expandTrailingDefaults` (or a sibling that
      takes the synthetic param list returned by `recordFieldsAsParams`
      / `structFieldsAsParams` / `enumVariantAsParams`).
- [ ] Receiver-bound defaults inside record-method default expressions
      (e.g. `record Counter(value: i32 = 0) { fn step(self, by: i32 = 1) }`)
      rewrite `self` against the method-call receiver via the F1 walk.

#### F5 — tests
- [ ] `tests/codegen/fn_param_defaults.zig` (new):
      - Trailing literal default (`todo` / `panic`).
      - Receiver-bound default (`slice`).
      - Record constructor 0-arg / 1-named / mid-positional cases.
      - Enum variant 0-arg / pre-supplied / named-suffix cases.
      - Annotation `#[ServiceOpts(name: "api")]` resolves defaults.
- [ ] `parser/tests/declarations.zig`: D5 fires on
      `fn f(a: i32 = 1, b: i32) { }`.
- [ ] `comptime/tests/diagnostics.zig`: D1–D4 + D6 each pair with their
      author-error source.
- [ ] `lib-test`: a smoke `.bp` in `libs/std/test/` calls
      `panic()` + `s.slice(2)` and asserts behaviour matches the
      pre-spec snapshot bank byte-for-byte.

#### F6 — docs
- [ ] `modules/compiler-core/AGENTS.md` §"parser/" — `parseParam` reads
      `= <expr>` default; `parseEnumBody` reads variant-field defaults.
- [ ] `modules/compiler-core/AGENTS.md` §"comptime/" — `transform.zig
      expandTrailingDefaults` is the unified default-injection point.
- [ ] `libs/std/AGENTS.md` §"Default values in fn-decl param lists" —
      explain the rule + the unified surface across calls / annotations
      / record + enum constructors.
- [ ] `CHANGELOG.md` — one line under v0.beta.20:
      `feat(stdlib): fn-param defaults injected at every call surface;
       arity-branch \`when(argc == N)\` retired from libs/std.`

### Test scenarios

```
F0         ---- a bare `todo()` call resolves to the parsed FnDecl in fn_decls and `expandTrailingDefaults` injects "not implemented" as args[0]
F0-erl     ---- the erlang inline-seeded dispatch collapses to one branch (argc=1) and renders `erlang:error({todo, <<"not implemented">>})` byte-identical to the pre-spec two-branch path
F0-node    ---- the commonJS inline-seeded dispatch collapses to one branch (argc=1) and renders `(() => { throw new Error("not implemented") })()`
F1         ---- `s.slice(2)` lowers to the same bytes as `s.slice(2, s.length())`; receiver `self` rebinds to `s` inside the default Expr
F1-erl     ---- erlang template renders `string:slice(<<"hello">>, 2, ((string:length(<<"hello">>)) - (2)))`
F1-node    ---- node template renders the same expansion via gleam_stdlib's string_slice
F2-D1      ---- `fn f(a: i32 = 1, b: i32)` reds with `fn-param-default-trailing-only`
F2-D2      ---- `Config(host: "x", "y")` reds with `fn-param-positional-after-named`
F2-D3      ---- `connect()` reds with `fn-param-default-arity-mismatch`
F2-D4      ---- `Color.Rgb()` reds with `enum-variant-arity-mismatch`
F2-D5      ---- D1's wording fires from parse path before infer ever sees the fn
F2-D6      ---- `s.slice(2, 5, 99)` reds with `fn-param-arity-exceeded`
F3-byte    ---- diff snapshots/codegen/ against pre-F3 HEAD: empty (byte-identical migration)
F3-empty   ---- post-F3 `git grep "when(argc ==" libs/std/src/` finds zero hits
F4         ---- `Config(port: 9000, tls: true)` injects host="localhost" and emits the 3-arg record constructor
F4-enum    ---- `Level.Error("boom")` injects code=-1 and emits the 2-arg variant
F4-annot   ---- `#[ServiceOpts(name: "api")]` injects replicas=1, public=false and reaches the decorator validator with a complete arg list
F5-libtest ---- the libs/std smoke calls behave identically to the pre-spec snapshot bank
F6-docs    ---- AGENTS.md sweep across compiler-core + libs/std + CHANGELOG.md in the same commit as F3
gate       ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green
```

### Notes

- **Cross-spec interaction with `prim-op-annotation`.** This spec closes
  the two deferred items recorded in `prim-op-annotation`'s commit
  `5f0f1d9`:
  - "`when(argc == N): \"...\"` arity-branch syntax stays valid for the
    two Array/String `slice` methods in primitives.d.bp" → resolved by
    §F1 + §F3.
  - "`todo`/`panic` inline-seeded dispatch in erlang.zig + commonJS.zig
    still ships two arity branches" → resolved by §F0 + §F3.
- **Why a sibling spec, not a `prim-op-annotation` extension.** The two
  gaps are not template-grammar problems — they are *call-site*
  problems (default injection + receiver-bound default rewrite). They
  fit the broader Kotlin-style uniformity of defaults that record / enum
  constructors + annotations already partly enjoy; bundling them under
  `prim-op-annotation` would muddle the spec's scope (it stays focused
  on the template grammar). A separate spec keeps both stories crisp
  for a future reader.
- **Cross-spec interaction with Frente B §1G.** Frente B §1G already
  enforces "defaults occupy trailing positions" for generic type
  parameters (`<T, U = string>`). This spec extends the same rule to
  fn-decl value params (a non-defaulted param after a defaulted one
  reds D5), so the language stays consistent: defaults trail everywhere.
- **What this spec is NOT.**
  - Not a new effect, type-system feature, or runtime change.
  - Not a backwards-compat shim — the legacy `when(argc == N)` clause
    keeps parsing so third-party libs (libs/onze, libs/rakun, etc.) can
    migrate at their own pace, but the stdlib drops it.
  - Not concerned with `comptime` defaults (a default expression that
    needs comptime evaluation to land — that's a `@comptime`-marked
    param's job; out of scope here, gated behind its own future spec).
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.

---

## family-1-beam-wat-prim-methods — drive primitive-method lowering from annotations on BEAM + wat

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

### Background

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

### Premise

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

### Target surface

#### Properties (`val length`) via `@externalProperty`

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

#### BEAM array primitives (the §A6 allow-list)

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

#### wat property + array primitives

```bp
interface Array<T> {
    #[@ExternalProperty.Wasm("(i32.load (i32.sub $self (i32.const 4)))")]
    val length: i32

    #[@External.Wasm("(call $bp_arr_prepend (local.get $0) (local.get $self))")]
    fn prepend(self: Self, item: T) -> Self
}
```

#### Adjacent — `to_string` rename to `toString` in `primitives.d.bp`

Memory (`feedback_camelcase_naming`) flagged 2026-06-07: `to_string`
in `primitives.d.bp` is legacy snake_case — normalise to `toString`
during this migration sweep since the same lines are touched.

### Compiler path

#### F0 — extend the template renderer with property + BIF shape

- [ ] `comptime/primOpTemplate.zig`: nothing changes — the renderer is
      already structural. The new `@ExternalProperty.<Target>(...)`
      annotation just lands in a sibling dispatch table
      (`prop_<backend>_dispatch`) the val-access emit path consults.
- [ ] `ast.zig`: add `externalPropertyVariantTarget(name)` (mirror
      `externalVariantTarget`), reusing the same canonical-target table.
- [ ] `parser/decls.zig`: `parseValDecl` consumes property annotations
      on `val name: type` lines (today they parse but lower to nothing).

#### F1 — BEAM Family 1 surface migration

- [ ] `libs/std/src/primitives.d.bp`: add `@External.Beam("template")`
      rows for every Array + String + Bool method that today lives in
      `beam_asm.zig`'s `emitPrimMethod` switch.
- [ ] `beam_asm.zig`: `collectPrimBeamDispatch` reads those entries
      into `prim_beam_dispatch`.
- [ ] `emitPrimMethod` in `beam_asm.zig` shrinks to the
      `tryEmitPrimAnnotation` path; delete the now-empty switch arms.

#### F2 — wat Family 1 surface migration

- [ ] Same shape as F1 for the wat backend. The `.len` arm migrates
      via the `@ExternalProperty.Wasm(...)` form from F0.

#### F3 — erlang `length` BIF migration (closes the irreducible allow-list)

- [ ] `libs/std/src/primitives.d.bp`: convert `len()`/`length()`/`size()`
      from interface methods to a `val length: i32` property carrying
      `@ExternalProperty.Erlang("length($self)")`.
- [ ] `erlang.zig`: delete the `len`/`length`/`size` switch arms in
      `emitPrimMethod`.

#### F4 — commonJS property-vs-call surface

- [ ] `commonJS.zig`: route the `arr.length` / `s.length` call path
      through the `@ExternalProperty.Node("$self.length")` annotation
      instead of the inline `isNativeProperty` table; delete the table
      after every `length`-shape consumer migrates.

#### F5 — final closure assertion

- [ ] `git grep "if (.*mem\.eql.*callee" modules/compiler-core/src/codegen/`
      finds zero hits in `emitPrimMethod` on every backend.
- [ ] Snapshot diff against pre-F1 HEAD is empty (every migration is
      byte-identical).

#### F6 — `to_string` → `toString` normalisation

- [ ] Rename every `to_string` method in `primitives.d.bp` (and in
      consumers that haven't already aliased) to `toString`.
- [ ] Validate `zig build test-libs` stays green.

#### F7 — docs

- [ ] `libs/std/AGENTS.md` §"Template grammar" — extend with the
      `@ExternalProperty.<Target>` form.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` §"§A6 closure" —
      remove the "irreducible allow-list" section; replace with a
      one-liner pointing at this spec's commit hashes.
- [ ] `CHANGELOG.md` under v0.beta.20:
      `feat(stdlib): every primitive-method lowering annotation-driven
       on every backend; emitPrimMethod switch arms deleted.`

### Test scenarios

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

### Notes

- **Cross-spec interaction.** Together with
  `family-2-beam-wat-runtime-ops` and `family-3-block-builtin`, this
  spec retires the **last** `mem.eql(callee, …)` switch chains in
  `codegen/`. After all three land, every callee dispatch on every
  backend goes through `tryEmitPrimAnnotation` /
  `tryEmitBuiltinAnnotation`.
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.

---

## when-argc-removal — retire the `when(argc == N)` arity-branch grammar

**Slug**: when-argc-removal
**Depends on**: `fn-param-default-expansion` (F0+F3 — the surface
migrations that move every libs/std `when(argc == N)` usage to
default-value form); `external-target-libs-migration` (F4 — the lib
+ example sweep eliminates any third-party `when` usage).
**Files**:
- `modules/compiler-core/src/ast.zig` — delete `ArityBranch`,
  `parseArityBranchArg`, `externalHasArityBranches`,
  `externalArityBranchFor`.
- `modules/compiler-core/src/parser.zig` — delete the
  `when($argc == N): "..."` label parse path in `parseAnnotationCall`
  (~lines 686–716).
- `modules/compiler-core/src/codegen/{erlang,beam_asm,commonJS,wat}.zig`
  — `PrimErlangCall` / `BuiltinNodeCall` / siblings drop the
  `arity_branches: ?[]ArityBranch` field; the `branches[]` collector
  loops in `collect…Dispatch` shrink to single-template form.
- `modules/compiler-core/src/comptime/primOpTemplate.zig` — the
  renderer is unchanged (it never knew about arity branches; they
  live one level up at dispatch).
- `libs/std/src/primitives.d.bp` — verify zero `when(argc ==` hits
  post-`fn-param-default-expansion`.
- `libs/std/AGENTS.md` — drop the §"Arity branching" section; keep the
  ~5-line reference pointing at `fn-param-default-expansion`.
**Touches docs**: `libs/std/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md` (drop the §"Arity
  branching" row in the `primOpTemplate.zig` row) · `CHANGELOG.md`.
**Status**: pending

### Background

`prim-op-annotation` added `when($argc == N): "<template>"` arity-branch
syntax (commit `59ab77f`) to express the `slice(start)` vs
`slice(start, end)` shape — at the time, fn-param defaults weren't
expanded at call sites, so the dispatch had to branch on `argc`.

`fn-param-default-expansion` retires the underlying need: every
arity-branched usage in `libs/std` migrates to a default-value param
(`end: i32 = self.length()` for slice, `message: string = "panic"`
for panic, etc.). Third-party libs migrate via
`external-target-libs-migration`.

Once both land, the `when(argc == N)` grammar is dead code. This spec
retires it from the parser + AST + dispatch tables in one focused
commit.

### Premise

After this spec lands:

- The `when($argc == N)` token sequence inside `#[@External.*(...)]`
  reds with a parse error (the parser no longer recognises `when` as
  an annotation arg keyword).
- The `ArityBranch` AST type + its readers (`parseArityBranchArg`,
  `externalHasArityBranches`, `externalArityBranchFor`) are deleted.
- Each codegen backend's dispatch entry struct
  (`PrimErlangCall` / `BuiltinNodeCall` / siblings) drops the
  `arity_branches` field; the dispatch loop reads a single template
  per `(callee, target)` pair.
- The single-arity-template surface is the only annotation grammar.

### Compiler path

#### F0 — verify no surviving usage

- [ ] `git grep "when(argc ==" libs/ examples/ tests/` finds zero hits.
- [ ] `git grep "parseArityBranchArg" modules/compiler-core/src/` shows
      the readers are only consumed by codegen — no parser cross-ref
      remains besides the parser's own `parseAnnotationCall`.

#### F1 — delete the parser path

- [ ] `parser.zig`: remove the `when(argc == N): "..."` branch in
      `parseAnnotationCall` (~lines 686–716). The annotation arg loop
      reverts to its pre-`59ab77f` shape: balanced parens, comma-
      separated, no special label-spanning logic.

#### F2 — delete the AST readers

- [ ] `ast.zig`: delete `ArityBranch`, `parseArityBranchArg`,
      `externalHasArityBranches`, `externalArityBranchFor`. The
      remaining `externalRefFor` / `externalInlineFor` /
      `externalAnnotationTargetsExt` / `externalBodyArgsExt` are
      unaffected (they never knew about arity branches).

#### F3 — collapse the dispatch tables

- [ ] `codegen/erlang.zig`: `PrimErlangCall` drops `arity_branches`;
      `collectPrimErlangDispatch` + `collectBuiltinErlangDispatch`
      stop iterating `parseArityBranchArg`; only the single-template
      collection path stays. `tryEmitPrimAnnotation` +
      `tryEmitBuiltinAnnotation` drop the `if (call.arity_branches.len
      > 0)` branch.
- [ ] `codegen/commonJS.zig`: same shape — `BuiltinNodeCall` drops
      `arity_branches`; the collector + dispatch shrink.
- [ ] `codegen/beam_asm.zig`: same.
- [ ] `codegen/wat.zig`: same.

#### F4 — delete the inline-seeding test coverage

- [ ] `tests/comptime/primOpTemplate.zig`: delete the
      `parseArityBranchArg` test block.
- [ ] `tests/codegen/prim_op_templates.zig`: drop the `F1-arity` +
      `F3-RP2` scenarios; the RP2 diagnostic (no `when` clause
      matched) goes away with the grammar.

#### F5 — docs

- [ ] `libs/std/AGENTS.md`: §"Arity branching" section becomes a
      ~5-line "deprecated since v0.beta.20 — use param defaults
      instead, see `fn-param-default-expansion`" pointer.
- [ ] `modules/compiler-core/src/comptime/AGENTS.md`: drop the
      `Arity branching` subsection from the `primOpTemplate.zig` row.
- [ ] `CHANGELOG.md` under v0.beta.20:
      `refactor(annotations): when($argc == N) arity-branch grammar
       retired; defaults are the unified arity-flexibility mechanism.`

### Test scenarios

```
F0       ---- post-`fn-param-default-expansion` + `external-target-libs-migration`, `git grep "when(argc ==" libs/ examples/ tests/` finds zero hits
F1-red   ---- `#[@External.Erlang(when(argc == 1): "x")]` reds with `parser: unexpected token "when"` after the parser path is gone
F2-build ---- `zig build` builds clean after the AST type is deleted (no dangling references)
F3-byte  ---- snapshot diffs across every backend empty against pre-F3 HEAD (every test scenario already migrated to single-template form by F0)
F4-clean ---- the deleted tests' siblings still pass; no orphan helper functions linger
F5-docs  ---- libs/std/AGENTS.md + comptime/AGENTS.md + CHANGELOG.md updated in the F3 commit
gate     ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green
```

### Notes

- **Cross-spec interaction.** Strict dependency:
  `fn-param-default-expansion` + `external-target-libs-migration` MUST
  land first. If any in-tree `.bp` still uses `when(argc == N)`, the
  F1 parser deletion turns it into a build break. Pin landing order:
  `fn-param-default-expansion` → `external-target-libs-migration` →
  `when-argc-removal`.
- **What this spec is NOT.** Not a feature; pure code-deletion sweep
  (~300 lines net). The release notes call it out as the closure of
  the `prim-op-annotation` grammar cleanup.
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.

---

## prim-op-annotation-tail — finish §A2 four-backend story (BEAM + wat)

**Slug**: prim-op-annotation-tail
**Depends on**: `std-tail-followup` §A2 commonJS+erlang twin
  (**already landed** on `origin/feat` — `a7c6d07` + `52d6101`); local prerequisite
  is its commonJS/erlang surface available at call time. `prim-op-annotation`
  v0.beta.19 partial close (`64a3436` — Family 1 9/19 erlang done, BEAM/commonJS/wat
  deferred). **Consumed by** `frente-a-03-closeout` §A7 audit (it verifies the BEAM
  template path lands before declaring §A6 closed).
**Files**:
- `modules/compiler-core/src/codegen/beam_asm.zig` (`user_beam_templates` +
  `tryEmitUserTemplate` mirroring the commonJS/erlang shape).
- `modules/compiler-core/src/codegen/wat.zig` (template dispatch + emitter
  context for the wat instruction encoder).
- `libs/std/src/primitives.d.bp` (BEAM/wat external annotations on the
  15 §A6-deferred methods + the 4 inline BEAM allow-list arms).
- `tests/codegen/prim_op_chained_beam.zig` + `tests/codegen/prim_op_chained_wat.zig`
  (new fixtures pinning each backend's chained-template behaviour).
**Touches docs**: `libs/std/AGENTS.md` "Per-target reach (today)" row
  (4/4 backends), `modules/compiler-core/src/codegen/AGENTS.md`
  (Remaining gaps roll), `CHANGELOG.md`.
**Status**: pending

### Premise

`std-expansion-tail` landed the §A2 per-callee template dispatch on
the commonJS + erlang backends:

- `Emitter.user_node_templates` / `Emitter.user_erlang_templates` —
  populated from `collectExternals` when the annotation symbol is a
  `$`-bearing template or carries `when(argc == N)` branches.
- `tryEmitUserTemplate(callee, cc)` — renders inline at the call site
  via `primOpTemplate.render`.
- Decl emit skips the `const fn = recv.method;` (commonJS) /
  `:module:symbol(args)` (erlang) alias path; the template renders
  per call site.

The remaining backends — BEAM bytecode and wat (WebAssembly text) —
keep the inline allow-list switch arms that `prim-op-annotation`
v0.beta.19 deferred (memory `project_v0beta19_prim_op_annotation`:
"4 inline arms + BEAM/commonJS/wat deferred"). For BEAM the deferral
was the right call at the time — 3/4 backends viable without it — but
the `std-expansion-tail-followup` adds new chained-host-call surfaces
(`fs`, `http`, `json`) that BEAM's inline switch can't reach without
re-authoring every method. The cleaner path is the §A2 twin: register
the templates once in `collectExternals` and let the shared renderer
walk them.

The wat backend is at "not yet wired" status per the v0.beta.19
`libs/std/AGENTS.md` "Per-target reach (today)" row. The wat
template-dispatch builds on the existing instruction encoder; the
4-byte / 8-byte / control-flow shapes wat uses for the §A6-deferred
operations stay the same — the template carrier is just where the
emitter renders them from instead of an inline `eq(u8, callee, "X")`
switch arm.

### Steps

#### P-A — BEAM `user_beam_templates`

- [ ] `codegen/beam_asm.zig` — add `user_beam_templates:
      std.StringHashMap(BuiltinBeamCall)` (or whatever the existing
      struct shape is — verify against `prim_beam_dispatch`).
- [ ] `Emitter.init` — initialise the map; `Emitter.deinit` walks +
      frees the entries (mirror the commonJS/erlang shape).
- [ ] `collectExternals` — route templates into `user_beam_templates`
      when `externalHasArityBranches("beam")` OR
      `primOpTemplate.looksLikeTemplate(ref.symbol)`; skip the
      `externals` map.
- [ ] `tryEmitUserTemplate(callee, cc)` — mirror the
      commonJS/erlang shape (single-template path + arity-branched
      path; render via `primOpTemplate.render`).
- [ ] Call-site dispatch — insert the `if (user_beam_templates.contains
      (cc.callee))` arm before the existing `externals.get` path.
- [ ] Sub-emitter struct literals (the `var sw = Emitter{...}` shape) —
      pass `user_beam_templates` through.
- [ ] Decl emit — when the fn is in `user_beam_templates`, emit a doc
      breadcrumb (mirror commonJS) instead of the bare-symbol comment.

#### P-B — wat `user_wat_templates`

- [ ] `codegen/wat.zig` — add `user_wat_templates` field of the same
      shape.
- [ ] `collectExternals` (wat-side equivalent) routes templates.
- [ ] `tryEmitUserTemplate` for wat — the template renders wat
      instructions; the `primOpTemplate.render` walker passes through
      any byte that isn't a marker, so a wat template like
      `i32.const $0 i32.const $1 i32.add` lowers verbatim.
- [ ] Call-site dispatch — wat's call-emit point gets the same
      pre-`externals` arm.

#### P-C — migrate the 4 BEAM inline allow-list arms

The `project_v0beta19_prim_op_annotation` memory cites "4 inline arms"
on BEAM that the v0.beta.19 partial close kept. Audit them, add the
`@external(beam, "<template>")` annotation on each method in
`primitives.d.bp`, and delete the inline arms.

- [ ] Audit `codegen/beam_asm.zig` for surviving `mem.eql(callee, …)`
      arms (search pattern: `mem.eql(u8, callee, ` in `emitPrimMethod`).
- [ ] For each, author the equivalent BEAM template in
      `primitives.d.bp`. The byte-identical migration contract is the
      same as the erlang Family-1 close in `64a3436`.
- [ ] Per-method BEAM snapshots stay pinned (the run-log shape doesn't
      change; the emit path does).

#### P-D — wat backend §A6 dispatch parity

The wat backend currently doesn't have a `tryEmitPrimAnnotation`
equivalent at all per the AGENTS row. This phase wires it up using the
template carrier so wat closes the §A6 surface alongside BEAM.

- [ ] `codegen/wat.zig` — author `tryEmitPrimAnnotation` for `Array<T>`
      / `String` / `Bool` interface methods, mirroring the erlang
      shape from `codegen/erlang.zig` (the `PrimErlangCall` struct +
      `prim_erlang_dispatch` map). Reuse the shared
      `primOpTemplate.render` walker.
- [ ] `primitives.d.bp` — author `@external(wat, "<template>")` for
      every surviving §A6 method; the templates carry the wat
      instruction sequence.
- [ ] Per-method wat snapshots.

#### P-E — fixtures + AGENTS roll

- [ ] `tests/codegen/prim_op_chained_beam.zig` — pin two
      arity-branched + one chained template on BEAM (mirror the
      `tests/codegen/externals.zig` §A2 fixtures).
- [ ] `tests/codegen/prim_op_chained_wat.zig` — same for wat.
- [ ] `libs/std/AGENTS.md` "Per-target reach (today)" row — flip from
      "erlang full; commonJS uses jsMethodRenames; wat not yet wired"
      to "every backend reads the full template grammar".
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` Remaining-gaps
      roll — drop the §A6 "irreducible allow-list" row.
- [ ] `CHANGELOG.md` entry under `Added` / `Changed`.

### Test scenarios

```
beam   prim-op-annotation Family 1 ports (the 4 inline arms) emit byte-identical
beam   §A2 chained host call (BEAM template) renders at the call site, not aliased
wat    §A2 template renders at the call site
wat    §A6 method dispatch from primitives.d.bp annotations (no inline switch)
all   `botopink-lib-test --lib std --target all` green
```

### Notes

- The `commonJS template path strips this` discovery from
  `std-expansion-tail` doesn't apply to BEAM (BEAM emits bytecode, no
  alias) or wat (no method shape). But the template form still
  preserves the surface contract: one annotation row in
  `primitives.d.bp` per method per backend.
- Snapshots are the contract — every byte-identical re-emit pins the
  migration. Snapshot churn in this spec is **expected and contained**
  to the per-method `*.snap.md` files under
  `snapshots/codegen/{beam,wasm}/`.

### Exit gate

- [ ] All P-A through P-E checkboxes ticked.
- [ ] `botopink-lib-test --lib std --target all` green (4/4 backends).
- [ ] No remaining `mem.eql(u8, callee, "X")` arms in BEAM
      `emitPrimMethod` or wat's equivalent.
- [ ] `libs/std/AGENTS.md` "Per-target reach (today)" row reflects
      4/4 backend coverage.
- [ ] CHANGELOG entry under `Added`.

---

## agents-md-resync — refresh AGENTS.md across the v0.beta.19 surface changes

**Slug**: agents-md-resync
**Depends on**: `prim-op-annotation` (every commit landed) +
`fn-param-default-expansion` (F0–F3) + the four other v0.beta.20
specs (`family-1-beam-wat-prim-methods` /
`family-2-beam-wat-runtime-ops` / `family-3-block-builtin` /
`external-target-libs-migration` / `when-argc-removal`) — sweeps
documentation **after** the code lands so the surface is consistent.
**Files**:
- `modules/compiler-core/AGENTS.md` ·
  `modules/compiler-core/src/parser/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md` ·
  `modules/compiler-core/src/codegen/AGENTS.md` ·
  `modules/compiler-core/src/codegen/tests/AGENTS.md` ·
  `modules/compiler-core/snapshots/codegen/AGENTS.md` ·
  `modules/compiler-core/snapshots/comptime/AGENTS.md` ·
  `modules/language-server/AGENTS.md` ·
  `libs/std/AGENTS.md` ·
  `libs/std/src/AGENTS.md` ·
  `libs/{onze,rakun,erika,jhonstart,server}/AGENTS.md` ·
  per-lib `src/AGENTS.md` files where applicable ·
  `tasks/v0.beta.19/status.md` + `tasks/v0.beta.20/status.md` (rollups).
**Touches docs**: every AGENTS.md in the monorepo (sweep) ·
  `CHANGELOG.md` (single rollup line).
**Status**: pending

### Background

The v0.beta.19 wave (`prim-op-annotation` + neighbours) and the
v0.beta.20 follow-ups (`fn-param-default-expansion` and the four sister
specs) move several surfaces:

- `@external(target, ...)` retires; `@External.<Target>("template")` is
  the only host-backed lowering annotation form.
- `when($argc == N)` retires; defaults at every call surface are the
  unified arity-flexibility mechanism.
- `$stringify(...)` + arbitrary inner expression + arity-branch +
  triple-quoted form survive in the template grammar.
- Every backend's `emitPrimMethod` / `emitResultOptionOp` switch shrinks
  to the annotation-driven path.
- `builtins.d.bp` splits into a decl-only fn block + an interface block;
  `registerStdlib` reads both.
- `Param.default: ?Expr` + `EnumVariantField.default: ?Expr` are the
  unified default-value AST slot.
- `expandTrailingDefaults` is the unified call-site default injection
  point.
- New diagnostics D1–D6 + EX1 + RP7 land.

Each of these surfaces is documented in **multiple** AGENTS.md files
across the monorepo (compiler-core's per-subdir + libs/std + the
per-lib AGENTS.md). Per the memory rule (`feedback_agents_md_maintenance`:
"Toda mudança de código/layout exige atualizar o AGENTS.md correspondente
no mesmo commit"), each landing spec touches its own AGENTS.md inline —
but a sweep pass at the end catches any cross-references that drift
across spec boundaries.

This spec is that sweep — pure documentation, **no code changes**.

### Premise

After this spec lands, every AGENTS.md in the monorepo reflects the
state of the code on its branch. Stale references to retired surfaces
(`when($argc ==)`, `@external(target, ...)`, `emitResultOptionOp`,
`emitPrimMethod` switch arms) are gone. New surfaces are documented in
the file that owns them; cross-references between AGENTS.md files point
at the right anchors.

### Compiler path

#### F0 — monorepo-wide stale-reference grep

Run these greps and reconcile each hit:

```bash
git grep -nE '@external\(' -- '*.md'
git grep -nE 'when\(\$?argc' -- '*.md'
git grep -nE 'emitResultOptionOp' -- '*.md'
git grep -nE 'emitPrimMethod' -- '*.md'
git grep -nE 'arity_branches' -- '*.md'
git grep -nE 'ArityBranch' -- '*.md'
git grep -nE 'defaultVal' -- '*.md'
```

Each hit is either:
- (a) **historical reference** — keep, add a `// retired in v0.beta.20`
  marker pointing at the relevant spec.
- (b) **stale instruction** — rewrite to point at the new surface.

#### F1 — per-file refresh checklist

Touch each AGENTS.md and verify the on-disk content matches the code
state after every v0.beta.19 + v0.beta.20 spec lands:

- [ ] `modules/compiler-core/AGENTS.md` — top-level §"`comptime/`",
      §"`codegen/`", §"`parser/`" subsections call out the new shape.
- [ ] `modules/compiler-core/src/parser/AGENTS.md` — `parseParam`
      reads `= <expr>` default; `parseAnnotationCall` no longer reads
      `when(...)` labels; `parseEnumBody` reads variant-field defaults.
- [ ] `modules/compiler-core/src/comptime/AGENTS.md` —
      `primOpTemplate.zig` row drops the §"Arity branching" subsection;
      `transform.zig` row gains the `expandTrailingDefaults` line;
      diagnostics list reflects D1–D6 + EX1 + RP7.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` — §"§A6 closure"
      no longer carries the "irreducible allow-list" (every arm
      migrated); §"Annotation-driven lowering" lists every backend's
      consumer + dispatch table; the per-target `$stringify` expansion
      table sits here.
- [ ] `modules/compiler-core/src/codegen/tests/AGENTS.md` — new
      `prim_op_templates.zig` + `fn_param_defaults.zig` test banks
      noted.
- [ ] `modules/compiler-core/snapshots/codegen/AGENTS.md` +
      `…/comptime/AGENTS.md` — folder structure unchanged, but any
      "expected output shape" prose reflects the new templates.
- [ ] `modules/language-server/AGENTS.md` — the LSP completion snapshot
      reflects `@External.<Target>(...)` form; nothing else changes.
- [ ] `libs/std/AGENTS.md` — §"External annotation vocabulary" carries
      the single typed-enum form; §"Template grammar" carries the
      marker table + arity-branch deprecation note pointing at
      `fn-param-default-expansion`; §"Default values in fn-decl param
      lists" is a new section.
- [ ] `libs/std/src/AGENTS.md` — per-module surface description (math,
      random, time, querystring, asserts, path, url) reflects the
      annotation form actually shipping.
- [ ] `libs/{onze,rakun,erika,jhonstart,server}/AGENTS.md` — the
      per-lib section that quotes its own `#[@external(...)]` examples
      moves to `#[@External.<Target>(...)]`.
- [ ] `libs/{onze,rakun,erika,jhonstart}/src/AGENTS.md` — same shape,
      where the per-src-tree AGENTS.md carries lib-internal annotation
      examples.

#### F2 — meta-root TODO + status

- [ ] `tasks/v0.beta.19/status.md` — close out the
      `prim-op-annotation` row; add receipts for the eight commits
      (`72e17e9` … `5f0f1d9`).
- [ ] `tasks/v0.beta.20/status.md` (new) — rollup of the five
      v0.beta.20 specs (`fn-param-default-expansion` /
      `family-1-beam-wat-prim-methods` / `family-2-beam-wat-runtime-ops`
      / `family-3-block-builtin` / `external-target-libs-migration` /
      `when-argc-removal` / `agents-md-resync` itself).
- [ ] `tasks/v0.beta.20/specs/index.md` — one-line pointer per spec.
- [ ] Meta-root `TODO.md` flips the pending v0.beta.19 row to done
      and adds a v0.beta.20 row pointing at `tasks/v0.beta.20/status.md`.

#### F3 — cross-reference invariant

- [ ] `scripts/check-md-links.sh` (new — if not already in tree from
      `recursive-test-gate`): walks every AGENTS.md, follows relative
      links, reds on any broken link. The test gate runs it.
- [ ] Run it; reconcile.

#### F4 — final invariant assertion

- [ ] `git grep -nE 'when\(\$?argc'` returns hits **only** in this
      spec's "deprecated since v0.beta.20" prose blocks.
- [ ] `git grep -nE '@external\(' -- '*.md'` returns hits **only** in
      historical-reference contexts.
- [ ] `CHANGELOG.md` under v0.beta.20:
      `docs: AGENTS.md sweep — v0.beta.19 + v0.beta.20 surfaces
       reflected across the monorepo.`

### Test scenarios

```
F0-grep   ---- every stale-reference grep returns the expected reconciled set
F1-cover  ---- every AGENTS.md in the listed table is touched in this spec's commit
F2-status ---- v0.beta.20/status.md + meta TODO.md flip green
F3-links  ---- `scripts/check-md-links.sh` reds zero
F4-clean  ---- the final invariant grep set returns the expected residue (only historical refs)
gate      ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green (no code touched)
```

### Notes

- **Cross-spec interaction.** This spec depends on every prior
  v0.beta.19 + v0.beta.20 spec landing first. Authoring it before code
  lands is fine (so the spec exists as a placeholder + checklist);
  executing it before code lands risks "documents the future" which
  drifts back to stale on every re-merge.
- **No code changes.** Pure docs sweep. The gate runs to verify the
  monorepo still builds, not to validate any new behaviour.
- **Per-memory:** SSH for git remote ops; commit messages in English;
  this spec's commit message lists every AGENTS.md it touches in the
  trailing "Co-touched files" block.
