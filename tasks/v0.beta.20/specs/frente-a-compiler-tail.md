# frente-a-compiler-tail — closes every recorded gap left by v0.beta.19's frente-a-compiler partial

**Slug**: frente-a-compiler-tail
**Depends on**: nothing at the file level — the seven tracks below are
  file-disjoint and runnable in parallel on independent worktrees
  (`.tasks/<track>/`). The §B keystone (generic-inference foundation)
  unblocks one row of cross-backend reds; everything else is
  self-contained.
**Files**: `modules/compiler-core/src/comptime/{infer,unify,types,transform}.zig`
  · `modules/compiler-core/src/codegen/{wat,erlang,beam_asm,commonJS,typescript}.zig`
  · `modules/compiler-cli/src/cli/test_cmd.zig`
  · `libs/std/src/primitives.d.bp`
  · `libs/erika/src/erika.bp`
  · all touched `AGENTS.md` + `CHANGELOG.md`
**Touches docs**: `modules/compiler-core/AGENTS.md` ·
  `modules/compiler-core/src/codegen/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md` ·
  `libs/std/AGENTS.md` · `libs/erika/AGENTS.md`
**Status**: pending

## Background

v0.beta.19's `frente-a-compiler` (`tasks/v0.beta.19/specs/frente-a-compiler.md`)
landed **§G1 + §D1 + §D2(BEAM partial) + §B3 + §S + §U + §A6** but
deferred every other section with explicit reasoning recorded in the
relevant `codegen/AGENTS.md` "Remaining gaps" rows + `tasks/v0.beta.19/
status.md` Frente A table + memory `project_v0beta19_frente_a_done`.
This spec consolidates every deferral into seven independent tracks so
the closing wave can ship piece by piece without thrashing the same
files.

The deferrals are not architectural disagreements — each is a coherent
unit of compiler work that was simply larger than v0.beta.19's session
budget. They share zero source files with frente-b-rules-tooling or
frente-c-distribution, so this tail spec is file-disjoint with every
other v0.beta.20 surface.

## Internal ordering

```text
§B-foundation (generic-inference)  ──▶  §B-emit (primitive interface
                                          default fns)  ──▶  4 lib reds
                                          flip green on erlang+beam
§C-wat-refactor                    ──▶  §C-wasm-test-runner
§A7-instance-templates             — file-disjoint from §B/§C
§D3-typed-dispatch                 — needs §B-foundation's tagging pass
§D4-future-runtime                 — file-disjoint; reads contract from
                                          v0.beta.19 frente-b §1F
§D5-beam-inline-prims              — file-disjoint; ~6 methods
§G2-erika-runtime-string           — file-disjoint; tooling in core
```

- §B-foundation is the keystone for §B-emit + §D3 (both consume the
  inference tags it produces).
- §C-wat is internally serial (C1 gates C2/C3/C4).
- §A7, §D4, §D5, §G2 are file-disjoint from everything else and can
  ship in any order.
- §D6 cross-backend snapshots ride the §D3/§D4/§D5 commits — same
  worktree as the producing track.

## Coordination with other v0.beta.20 specs

- **`emilia` (CSS lib prototype)** — file-disjoint at the source level
  (touches `repository/emilia/src/**`, not the compiler core). May
  use §B's inference tagging if it ships first; otherwise queues
  behind.
- **Outside v0.beta.20**: no cross-spec dependency. Frente B
  (rules-tooling) and Frente C (distribution) of v0.beta.19 are fully
  closed.

---

## §B-foundation — generic-inference (closes v0.beta.19 §B1+§B2+§B5)

**Files**: `comptime/{infer,unify,types}.zig` · `libs/std/AGENTS.md`
  · `libs/std/src/{order,sets,dict,queue}.bp` (re-fold external inline
  tests) · new `modules/compiler-core/src/comptime/tests/inference.zig`

**Why it's the keystone**: `instance_lowering` is the bridge between
inference's typed tree and codegen's per-backend emitter. When `Self`
inside a primitive interface `default fn` body can't be resolved to
the call-site receiver's primitive kind, the body's nested method
calls (`self.slice`, `self.forEach`) never get tagged with
`instance_lowerings.prim` — so the codegen falls through to bare
local calls that resolve to nothing on erlang/beam, and 4 lib
test-libs rows (erika/jhonstart/onze/rakun) stay red.

The pre-existing reds are:

```
.botopinkbuild/test-out/erika.erl:90:  function drop/2 undefined
.botopinkbuild/test-out/erika.erl:95:  function forEach/2 undefined
.botopinkbuild/test-out/erika.erl:249: function fold/3 undefined
```

(Plus the LINQ `B unbound` codegen bug, which **v0.beta.19 §B3 fixed**
in `codegen/erlang.zig` `emitBranchBody` — the case arm now binds the
binding identifier instead of `_`. That fix landed at bot-lang
`8185829`; this section does **not** revisit it.)

- [ ] **B1** — Resolve `Self`'s primitive kind inside an interface
      `default fn` body. In `comptime/infer.zig` `instance_lowering`,
      when the enclosing interface is a primitive (Array/string/
      numeric/Bool — known via `primitiveInterfaceName`), substitute
      `Self`'s kind from the call-site receiver before re-typing the
      body. Records the resolved kind in
      `instance_lowerings[<callsite-loc>] = .prim{<kind>}` so codegen
      consumers (`emitPrimMethod` on erlang/beam, the prototype
      patcher on commonJS, the wat layout pass) all see the tag.
- [ ] **B2** — Instantiate callee generic vars before `unifyAt` so a
      generic inline `test { … }` re-uses the module's `<T>` for the
      test's local bindings. Then fold the externalised `*_test.bp`
      shadow files back to inline `test` blocks inside `order.bp` /
      `sets.bp` / `dict.bp` / `queue.bp`. Verify by `botopink test`
      green per module against the same fixture set.
- [ ] **B5** — Drop the generic-module inline-test caveat in
      `libs/std/AGENTS.md`; add inference unit tests for B1/B2 in a
      new file `modules/compiler-core/src/comptime/tests/inference.zig`.

### Test scenarios — §B-foundation

```
B1   ---- erika instance default fn for Array typechecks under
          inference; commonJS still green; the prim-tag for
          `xs.drop(n)` shows `.prim = .array` in the dump.
B2   ---- order.bp / sets.bp / dict.bp / queue.bp inline tests all
          green; the external `*_test.bp` shadow files are deleted.
B5   ---- comptime/tests/inference.zig: every B1/B2 case as a unit
          test (no shell, no codegen — pure infer).
```

## §B-emit — primitive interface instance default fns on erlang + beam (closes v0.beta.19 §B4)

**Files**: `codegen/erlang.zig` · `codegen/beam_asm.zig` · new
  `tests/codegen/primitive_interface_default_fns.zig` ·
  `codegen/AGENTS.md` Remaining-gaps row narrows

**Dependency**: §B-foundation. Without B1's prim-tag, this section
emits dead code (the body would still hit the bare-local-call
fallthrough at `self.slice`).

Once `instance_lowerings[<loc>] = .prim` is populated for every
`self.<method>(…)` call inside a primitive interface default fn
body, codegen can emit each instance `default fn` (`drop`/`take`/
`fold`/`find`/`count`/`all`/`any`/`first`/`rest`/`contains`) as a
local mangled fn (`'Array_drop'`/`'Array_fold'`/…) AND route the
consumer's call to the mangled name.

- [ ] **B4-erlang** — Extend `emitInterface` in `codegen/erlang.zig`
      to emit instance default fns (`has_self == true`) as bare local
      functions named after the method (so `drop(Items, N)` resolves
      locally). For methods carrying an `@external(erlang, …)`
      annotation, skip the local definition (the host-backed
      template wins via `emitPrimMethod`). Also walk
      `prelude.primitives` so the primitive interfaces (Array/String
      /Bool/numeric) join the per-module emission pass even though
      they aren't in `program.decls`.
- [ ] **B4-beam** — Mirror on `codegen/beam_asm.zig` with BEAM ASM
      label reservation (`reserveFn` for the new local) and body
      emission (`emitFn` reuses the standard expr pipeline since the
      body is pure botopink — closures, prim calls, branches all
      already work). Validate against `erlc +from_asm` by reassembling
      the snapshots.
- [ ] **B4-test** — `tests/codegen/primitive_interface_default_fns.zig`:
      one fixture per backend that exercises every emitted method
      (`drop`/`take`/`fold`/`find`/`count`/`all`/`any`/`first`/
      `rest`/`contains`) on Array<i32>; assert the emitted code +
      run under node / escript / `erlc +from_asm; erl`.
- [ ] **B4-libs** — `zig build test-libs` flips erika/jhonstart/
      onze/rakun rows green on the erlang column. Drop the
      "(also broken on Erlang)" qualifier from `codegen/AGENTS.md`
      Remaining-gaps.

### Test scenarios — §B-emit

```
B4-erlang ---- drop/2, forEach/2, fold/3 (+ the rest) emit as
               bare local fns in every consuming erlang module;
               the bodies cascade through emitPrimMethod for host
               calls. Snapshots regen byte-clean.
B4-beam   ---- same set emits as BEAM ASM labels; `erlc +from_asm`
               assembles + `erl` runs the snapshot fixtures end-to-end.
B4-libs   ---- the 4 lib reds flip green on erlang.
```

---

## §C-wat-refactor — wat stack-discipline + wasm aggregates (closes v0.beta.19 §C1-§C4 + §C6)

**Files**: `codegen/wat.zig` · `modules/compiler-cli/src/cli/test_cmd.zig`
  · `codegen/AGENTS.md` · `snapshots/codegen/wat/` (new fixtures)

The `wat` emitter is the only backend that can't run a typical test
fixture: the classifier is untyped, void builtins underflow the
stack, and named record-field access stubs to `i32.const 0`.

- [ ] **C1** — Track per-expression "produces a value" in the wat
      emitter. Classifier: `@print`/`@panic`/`@todo`/void-returning
      calls produce nothing; everything else produces one i32. Drop
      only value-producing statement-exprs; for a void function
      (`f.returnType == null`) the last statement is not the return,
      so drop its value too. Thread `returns_value` into `emitBody`.
- [ ] **C3** — Record field layout: stable 4-byte slot offsets per
      declared field order; constructor stores at offset; `recv.field`
      / `self.field` load `base + offset`; field assign stores.
- [ ] **C4** — `?.` on wasm: guards the base against null, reads the
      slot. Remove the JS-style short-circuit stub.
- [ ] **C6** — Update `codegen/AGENTS.md` `wat.zig` row; add `.wat`
      snapshots asserting field layout + `?.` byte sequences. (C5
      single-module note already landed in v0.beta.19.)

## §C-wasm-test-runner — `botopink test --target wasm` (closes v0.beta.19 §C2)

**Files**: `modules/compiler-cli/src/cli/test_cmd.zig` · `codegen/wat.zig`
  test-mode entrypoint emission · new snapshot under
  `snapshots/codegen/wat/`

**Dependency**: §C-wat-refactor's C1+C3 — without value tracking +
record layout the test fixtures don't run.

- [ ] **C2** — Wire `botopink test --target wasm`. `test_cmd.zig`'s
      target gate (currently `target != .commonJS and target != .erlang`)
      accepts `.wasm`; test-mode codegen emits a `__bp_run_tests` entry
      that walks an exported test-fn table; CLI invokes via `wasmtime`
      and parses the same `passed/failed` shape commonJS/erlang use.

### Test scenarios — §C combined

```
C1 ---- wat emit no longer underflows the stack for a fixture
         calling @print plus a value-returning fn.
C2 ---- `botopink test --target wasm` on a 1-test fixture runs
         under wasmtime → exit 0, 1/1 pass.
C3 ---- self.id reads the right slot under a stable record layout
         (snapshot pinned).
C4 ---- recv?.member guards null + reads slot (snapshot pinned).
C6 ---- codegen/AGENTS.md gaps row narrows; `.wat` snapshots
         assembled by wasmtime smoke.
```

---

## §A7-instance-templates — `Array.zip<U>` via ONE annotation per backend (closes v0.beta.19 §A7)

**Files**: `libs/std/src/primitives.d.bp` ·
  `codegen/{commonJS,erlang,beam_asm,wat}.zig` (annotation consumer
  for instance methods) · new
  `tests/codegen/primitive_methods_byte_identical.zig`

**Background**: v0.beta.19 attempted to add `Array.zip` as a single
`#[@external]` annotation but discovered that the §A keystone refactor
landed dispatch-table support only for **associated** prim methods
(no `self` receiver). Adding a new **instance** method via one
annotation still requires every emitter to (a) parse the per-target
template body, (b) substitute `$self`/`$0..N`/`$args` markers, and
(c) emit at the consumer call site.

The pattern this section establishes generalises to every future
instance-method addition (`Array.chunks`, `String.repeat`,
`Array.partition`, …).

- [ ] **A7a** — `commonJS.zig`: extend the prototype patcher /
      call-site emitter so an interface `fn` (not `default fn`)
      carrying `@external(node, "<template>")` patches
      `<Owner>.prototype.<method>` with a JS body rendered through
      `primOpTemplate.render` (substituting `$self → this`, `$N →
      args[N]`, `$args → ...arguments`).
- [ ] **A7b** — `erlang.zig`: same as A7a but at the call site —
      `recv.method(args)` whose method is an annotated instance
      template renders the body inline (the renderer already runs
      via `tryEmitPrimAnnotation`; extend to non-default fns).
- [ ] **A7c** — `beam_asm.zig`: register-level rendering. For a
      template that reduces to `mod:sym(args)`, route through
      `primRecvOnly` / `primFunThenList` / `primRecvThenArgs`
      (existing layouts cover the common shapes). For inline-fun
      templates (the `iolist_to_binary(lists:join(...))` shape),
      the §D5-beam-inline-prims track is the right home — skip.
- [ ] **A7d** — `wat.zig`: same as A7c for wasm. Inline funs go to
      §C; simple `(local.get $self) call $...` shapes ship here.
- [ ] **A7e** — `Array.zip<U>(self: Self, other: U[]) -> #(T, U)[]`
      lands in `primitives.d.bp` with ONE annotation per backend
      (`lists:zipwith(fun(__X, __Y) -> {__X, __Y} end, lists:sublist
      ($self, length($0)), lists:sublist($0, length($self)))` on
      erlang; `$self.map((__x, __i) => [__x, ($0)[__i]])
      .slice(0, Math.min($self.length, ($0).length))` on node; ditto
      for beam + wasm). The fixture in
      `primitive_methods_byte_identical.zig` compiles + asserts the
      emitted code on all 4 targets **without editing any `.zig`**.

### Test scenarios — §A7

```
A7e ---- new prim method 'Array.zip' lowers on commonJS+erlang+beam
         +wasm via one #[@external(...)] each; the .zig delta is
         zero (only the .d.bp + the test fixture).
```

---

## §D3-typed-dispatch — typed-value method dispatch on erlang + beam (closes v0.beta.19 §D3)

**Files**: `comptime/infer.zig` (tagging pass) · `codegen/erlang.zig`
  + `codegen/beam_asm.zig` (consume `.record` tag)

**Dependency**: §B-foundation's instance_lowerings infrastructure.

Today, `p.parse(x)` where `p: Parser` lowers to the bare local call
`parse(P, X)` on erlang/beam — works for LOCAL records (the bare fn
exists) but the call doesn't honour the record's own associated-fn
mangling (`'Parser_parse'`). Imported records work via
`imported_types` but local-record method dispatch is still
type-blind.

- [ ] **D3a** — In `comptime/infer.zig`, when a call's receiver
      resolves to a record/struct type, record
      `instance_lowerings[<loc>] = .record{<TypeName>}`. The map
      already exists (B-emit consumes the `.prim` variant); this
      section adds the `.record` variant.
- [ ] **D3b** — erlang `emitCall` consumes `.record`: emits the
      mangled local `'Parser_parse'(P, X)` for local records,
      `<owner>:'Parser_parse'(P, X)` for cross-module ones. Same
      pattern beam_asm.
- [ ] **D3c** — Snapshot: a fixture defining `record Parser` with
      `parse(self, …)`, then `p.parse(x)` — the emitted call uses
      the mangled form on both erlang + beam.

---

## §D4-future-runtime — `#[@future]` lowering on erlang + beam (closes v0.beta.19 §D4)

**Files**: `codegen/erlang.zig` + `codegen/beam_asm.zig` (future
  emitter) · runtime `.erl` companion (`Future_*` ops) · contract
  reader for `@Future<T, E>` from frente-b's §1F (already in `feat`)

**Background**: spec v0.beta.19 deferred to follow-up under the
"scope to follow-up if too large" clause. Erlang's `spawn/1` + a
`Mref =/= make_ref()` message-passing scheme implements the
spawn-and-await semantics; the operating constraints are pinned by
frente-b's §1F (`@Future<T, E>` carries `await`/`map`/`flatMap` and
`E = any` by default).

- [ ] **D4a** — erlang: a `#[@future] fn body` lowers to a small
      record `{future, Pid, Ref}` returned to the caller; the body
      runs in a `spawn(fun() -> Caller ! {Ref, BodyResult} end)`;
      `await` does a selective receive on `Ref`.
- [ ] **D4b** — beam: the same shape at register level. `spawn/1`
      is `call_ext` to `erlang:spawn/1` with a closure built via
      `make_fun3`; the await branch is a `loop_rec` + `remove_message`
      sequence.
- [ ] **D4c** — `Future.map<R>(self, transform)` / `flatMap<R>(self,
      transform)` lower as new futures chained off the await
      (`spawn(fun() -> R = transform(await(Self)), … end)`).
- [ ] **D4d** — Cross-backend snapshot: a `#[@future] fn double(n:
      i32) -> i32 { return n * 2; }` produces a working future on
      erlang + beam under `erlc +from_asm`; the await + transform
      pipeline matches a hand-written equivalent byte-for-byte (or
      within the documented divergence in `codegen/AGENTS.md`).

---

## §D5-beam-inline-prims — BEAM inline-fun array/string methods (closes v0.beta.19 §D5)

**Files**: `codegen/beam_asm.zig` `emitPrimMethod` · snapshots under
  `snapshots/codegen/beam/beam/`

Methods that need an emitted helper fun or arity arithmetic on
BEAM — each one was deferred per-method in the v0.beta.19 spec.

- [ ] **D5-join** — `xs.join(sep)` → `iolist_to_binary∘lists:join`
      with a per-element stringify fun (mirrors the erlang template
      already in `primitives.d.bp`). Register choreography: `$self`
      in `{x, 0}`, stringify fun built via `make_fun3` in `{x, 1}`,
      `lists:map/2` call, then `lists:join/2`, then
      `iolist_to_binary/1`.
- [ ] **D5-indexOf** — `xs.indexOf(item)`: emit a recursive
      `__Find/2` fun (already documented in the erlang template);
      register layout `{x, 0} = Item, {x, 1} = List`.
- [ ] **D5-at** — `xs.at(i)` bounds-safe: guard `is_lt`+`is_ge`
      against `length`, then `lists:nth/2` with `I + 1`. Return
      `undefined` (the `@Option` absent atom) on out-of-range.
- [ ] **D5-slice-2** — 2-arg `xs.slice(start, end)`: arithmetic
      `lists:sublist(L, Start+1, End-Start)`. Already a 1-arg
      branch; this adds the 2-arg arity branch.
- [ ] **D5-string-contains** — `s.contains(needle)`:
      `(binary:match($self, $0) =/= nomatch)`.
- [ ] **D5-string-startsWith** — `s.startsWith(prefix)`:
      `(binary:longest_common_prefix([$self, $0]) =:= byte_size($0))`.

Each method ships with a snapshot fixture + `erlc +from_asm` smoke.

---

## §G2-erika-runtime-string — `var s = "select ..."; erika s` (closes v0.beta.19 §G2)

**Files**: `comptime/{template_eval,template,infer}.zig` (runtime-string
  capture support) · `libs/erika/AGENTS.md` "Recorded gaps" drops the
  remaining G2 row

**Background**: the `erika "…"` template form requires a literal at
the call site today because the comptime template body runs over a
`@Expr<string>` captured at parse time. A `var s = "select …";
erika s` form needs the compiler to:

1. Recognise the call site `erika <runtime-string-expr>` (not a
   template literal).
2. Synthesise a runtime path: parse the SQL string at runtime,
   resolve the source collection via the comptime scope snapshot,
   build the runtime query.

This is **pure generic mechanism** — no erika-specific code in core.
The same mechanism handles any template fn that wants
runtime-string mode.

- [ ] **G2a** — In `comptime/infer.zig`, when a template fn call
      receives a runtime `string` arg (not an `@Expr<string>`),
      synthesise a `runtime_template` dispatch: the template body
      runs at runtime over the string payload. The comptime scope
      snapshot binds named collections; the runtime form looks
      them up by name.
- [ ] **G2b** — `comptime/template_eval.zig` ships a runtime
      bootstrapper: the same JS prelude (`text`/`parts`/`lookup`/
      `bindings`/`build`/`custom`/`fail`) but parameterised over a
      runtime string + a runtime scope-snapshot dict.
- [ ] **G2c** — Erika test: `var s = "select name from
      erikaCities"; erika s` returns the same `Array<string>` the
      literal form would. The scope snapshot resolves
      `erikaCities` by name at runtime; the lex/parse path is the
      same erika.bp tokenizer (already pure-bp, no comptime
      coupling).

---

## §D6-cross-backend-snapshots — close the v0.beta.19 §D6 doc tail

**Files**: `codegen/AGENTS.md` Remaining-gaps rows · cross-backend
  snapshots for §D3 + §D5 (riding their respective tracks) ·
  `snapshots/codegen/erlang/erlang/negation_in_expression.snap.md`
  (the `gc_bif Live count` outstanding note in `codegen/AGENTS.md:57`)

- [ ] **D6a** — Per `§D3`/`§D5` track, regen cross-backend
      snapshots; pin them in their producing commit.
- [ ] **D6b** — Sweep the `negation_in_expression gc_bif Live count`
      note: pin the actual register layout in beam_asm + add an
      `erlc +from_asm` smoke snapshot.
- [ ] **D6c** — Update beam + erlang AGENTS "Remaining gaps" rows
      to drop every row this spec closes (everything except the
      §G2 runtime-template caveat, which is in libs/erika/AGENTS.md
      already).

---

## Test scenarios (whole spec)

```
§B-foundation B1 ---- erika Array.drop body typechecks; the prim-tag
                       for `xs.drop(n)` shows `.prim = .array` in dump
§B-foundation B2 ---- order/sets/dict/queue inline tests green; shadow
                       *_test.bp files deleted
§B-emit B4-libs  ---- zig build test-libs erika/jhonstart/onze/rakun
                       rows flip green on erlang
§C2              ---- `botopink test --target wasm` 1/1 pass under
                       wasmtime
§A7              ---- Array.zip lowers on 4 backends via ONE annotation
                       each; 0 .zig edits in the lowering paths
§D3              ---- p.parse(x) lowers to 'Parser_parse'(P, X) on
                       erlang+beam (mangled, not bare)
§D4              ---- #[@future] fn double(n) -> i32 spawns on erlang
                       + beam; the chained Future.map preserves
                       semantics across the await
§D5-join         ---- BEAM xs.join(", ") emits the iolist_to_binary∘
                       lists:join shape; assembles via `erlc +from_asm`
§D5-rest         ---- indexOf/at/slice-2/string contains/startsWith all
                       ship snapshot-pinned BEAM forms
§G2              ---- `var s = "select …"; erika s` returns the same
                       Array the literal form does; the scope
                       snapshot resolves the collection by name
gate             ---- `zig build test` + `zig build test-libs` + 
                       `botopink-lib-test` all green; every backend's
                       Remaining-gaps row narrows
docs             ---- every touched AGENTS.md updated in the same
                       commit (memory rule feedback_agents_md_maintenance)
```

## Notes

- **No new language surface.** This spec only closes recorded gaps;
  zero new keywords, zero new syntax. Frente B's effect-annotation
  rules + frente C's distribution + v0.beta.19 keystones already
  cover the surface.
- **Worktree convention.** Each track gets its own worktree under
  `.tasks/<track>/` (e.g. `.tasks/frente-a-tail-generic-inference/`,
  `.tasks/frente-a-tail-wat-refactor/`, etc.). The 7 tracks are file-
  disjoint at the source level so 7 parallel worktrees compose.
- **Per-memory rules**: SSH for all git remote ops
  (`feedback_always_ssh_git`); functions in camelCase
  (`feedback_camelcase_naming`); implement in `.bp` when possible
  (`feedback_prefer_bp_over_dbp`); AGENTS.md updated in the same
  commit as the code (`feedback_agents_md_maintenance`); commit
  messages in English; no `--no-verify`.
- **Forward-only merges**. v0.beta.19's frente-a-compiler partial is
  already on `origin/feat`; do not rebase the existing landings.
  Every track's worktree branches off whatever `origin/feat` is at
  spawn time and merges back forward-only.
