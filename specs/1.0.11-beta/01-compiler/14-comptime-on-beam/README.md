# Front 14 — comptime-on-beam

**Priority:** medium — the comptime pipeline is landed (C-20, C-26); what is open is the evidence
the design promised (three fixtures, one measurement) and two toolchain rows the rakun sweep
found in the decorator evaluator.
**Depends on:** `00-gate` (ZF-8, ZF-9 — `comptime/runtime/beam/{lower,program}.zig` are two of the
eleven `zig fmt` files; nothing here stages them before the gate) · `02-erlang` step 5 (C-36's fix
in the shared Erlang-text renderer; this front's fixture reads it) · decision-gated rows lg2-j
(comptime state across decorator invocations), lg2-o (filesystem access from a comptime body),
lg2-w (a host function called from a decorator body) — each opens a step here when answered.
**Owns:** `modules/compiler-core/src/comptime/template_eval.zig`, `decorator_eval.zig` ·
`src/comptime/runtime/beam/**` (the lowering) · `src/comptime/runtime/etf.zig` (the term round
trip) · `src/comptime/runtime/prelude.zig` (the resident preludes) · `src/codegen/beam/asm_text.zig`
(the listing) · `scripts/comptime_bench.sh` (with 18: this front measures, 18 records the table) ·
the `COMPTIME BEAM ASSEMBLY` cells and `snapshots/comptime/runtime/beam/**` · its fixtures in
`codegen/tests/comptime_module.zig` and `comptime/tests/**` (a carve-out of 07, named per commit)
**Does not touch:** `src/comptime/eval.zig`, `infer.zig` (01) · the typed `beam_asm.zig` (03) ·
`erlang.zig`'s `emitComptimeModule` and `beam/erl_emitter.zig` (02) · `comptime/runtime/{runtime,persistent_beam,persistent_wat}.zig`,
`runtime/wat/**` (18) · `libs/std/**` and the libraries.
**Does not touch until 00-gate lands:** `comptime/runtime/beam/lower.zig`, `program.zig` (ZF-8, ZF-9).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless they start with
`modules/`, `libs/` or `scripts/`, which are relative to `repository/botopink-lang/`.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| the three open boxes | `14-comptime-on-beam/README.md` | § Open, boxes 1–3 |
| T15, T17 | `language-gaps.md` | "An emitted `pub val` is visible to other emitted code only" · "Importing a type named like a reflection type hides the reflection one inside a decorator" |
| lg2-j, lg2-o, lg2-w | `language-gaps.md` · `decisions-pending.md` | the three decorator-body rows owned by 14 |
| the `\u{…}` known gap | `14-comptime-on-beam/README.md` | § Open, "Known gap, not this front's" → C-36 (02) |

## What holds

One module per declaration (`bp@comptime__{tpl,dec}__<decl>__<hash>`, 01c-a); the host glue
resident (`bp_comptime_template` / `bp_comptime_decorator`); a body reaches the node as BEAM bytes
(read back by `runtime/wat/erl_parse.zig`, lowered by `runtime/beam/lower.zig`, assembled by
`codegen/beam/beam_file.zig`, loaded by cmd 4); what it refuses it names as a compile error of that
module; `COMPTIME REPLY` byte-identical across both runtimes; 18's step 2 blocker (the prelude
re-parse per `emitComptimeModule`) closed by `erlang.zig:328`'s `prelude_cache`. Measured at
1.0.10's close; `scripts/comptime_bench.sh` re-measures — do not quote numbers.

## Open

| Row | Program | Answer at the open |
|---|---|---|
| box 1 | a decorator body calling `.foo(…)` no primitive type and no host function provides | the compiler's own refusal, before any runtime runs: the message names the call by `line:col` in the body, the caret is the annotation that ran it (`reject/comptime_method_nothing_answers`). The message does not name the body's **file**: the evaluator receives the owner's module path, not its display path, and the location is set by `infer.zig` `decoratorError` at the annotation (01). A template body is typed: the checker refuses the same call as `unknown-primitive-method` at the call in the body |
| box 2 | the generated N=200 call-site project | over budget (§ Step 2) |
| box 3 | the term round trip per shape | closed (§ Step 3) |
| T15 | `@emit("pub val FooCol = …")` | holds, re-measured on four targets. The module's own source: a module `val` is not visible before its declaration (a hand-written `pub fn main() { @print(later); } pub val later = 5;` is refused the same way) and contributions are merged after the module's own declarations (`comptime.zig` `parseAndMergeContributions`), so no own body sees an emitted `val`. The importer: `compiler-cli` `resolver.zig` `collectModuleRefs` reads a module's exports off its source text before comptime runs, so an emitted `pub val` **and an emitted `pub fn`** are `imported symbol is not exported` (26) |
| T17 | a decorator module importing a user `Param` | holds, re-measured on four targets: `unknown field 'name' on type 'Param'` at `p.name` of `m.params` — the reflection model is resolved by name in the module's scope (`infer.zig` / `env.zig`, 01) |

## Steps

### Step 1 — the located `unsupported_method` fixture (box 1)

Verify `comptime_module.zig:322` asserts the location (line and column of the call inside the
body, the body's file named); if it asserts the message only, add the location. The `reject/`
twin: `reject/comptime_method_nothing_answers` with the `.expect` at the call.

**Acceptance:**
- [ ] the fixture asserts `file:L:C`; the `reject/` cell names the code and the caret — `L:C` and the
      caret are asserted (`comptime_module.zig`, `decorator_invocation.zig`, `templates.zig`,
      `reject/comptime_method_nothing_answers`); the body's file is not named (box 1): it needs
      `infer.zig` to hand the evaluator the owner's display path, or to locate the error at the body
      call when the decorator is the module's own (01)

### Step 2 — the N=200 slope (box 2)

`scripts/comptime_bench.sh` re-run at the open on the runner's machine; the slope and the N=200
total recorded in 18's table (18 step 3); if the budget is still unmet, the stage that costs it
named with its owner.

A comptime module is emitted once per declaration and plan (`template_eval.zig` `emitKey`), not once
per call site: `emitComptimeModule` re-lexes and re-parses `builtins.d.bp` and `primitives.bp` on
every emit (`erlang.zig` `collectBuiltinErlangDispatch` — `prelude_cache` does not cover it), which
was 55 % of an N=200 build's samples.

Measured with the generated project (`conf "cfg-<i>"`, a debug build, best of 5, on a host shared with
other builds — load average 25–45 on 16 cores):

| target (runtime) | N=0 | N=100 | N=200 | N=400 | slope 0→200 |
|---|---|---|---|---|---|
| commonJS (wat) | 205 ms | 425 ms | 918 ms | 2730 ms | 3.6 ms/eval |
| erlang (BEAM) | 605 ms | 1286 ms | 2036 ms | 4176 ms | 7.2 ms/eval |

The cost per evaluation still grows with N. Where an N=200 build spends it (stack samples):

| stage | commonJS | erlang | owner |
|---|---|---|---|
| the runtime's evaluation — wat: a fresh wasm3 environment, parse and load of the linked module per evaluation (`persistent_wat.zig`); BEAM: the frame round trip | 45 % | 29 % | 18 |
| the trace listing — `main/1`'s argument rendered as text per evaluation (`listingWithArgument`, `runtime.listingOf`) for `comptime_traces`, which every backend renders (`trace.renderAlloc`) and only the snapshot harness and the browser build read | 42 % | 32 % | 14 (the listing) · whoever owns `trace.zig` and the codegen `comptime_trace` field (a build that reads no trace need not render one) |
| the ETF encode of the argument | 5 % | — | 14 |
| `erlc` checks and sidecars in the CLI | — | 24 % | 26 |

The growth is the capture's `bindings`: every module-level `val` in scope is in every capture
(`captureToTerm`), so the argument — encoded, decoded by the runtime and rendered into the trace — is
O(N) per evaluation and O(N²) per build. Sending the scope only to a body that reads it
(`bindings`, `lookup`, `ref`, `context`) is a design question, not a measurement.

**Acceptance:**
- [ ] slope ≤ 1 ms per evaluation, N=200 ≤ 600 ms — unmet; the stages and their owners are the table above

### Step 3 — the round-trip fixtures (box 3)

One fixture per shape in `comptime/tests/**` (or `snapshots/comptime/runtime/beam/**` with its
wat pair — `snap_audit.sh --mode=runtime-parity` pins them equal): a holed template whose `${…}`
parts carry a record, an array and a `?T`; an `@ExprCustom` return whose reference tree names a
declaration of another module; a decorator whose `@Decl` handle carries fields, methods, variants
and annotations, each read back in the body.

**Acceptance:**
- [x] three fixtures, `COMPTIME REPLY` byte-identical on beam and wat; `runtime/AGENTS.md` names the encoded shapes
      — `comptime: round trip ---- …` (`templates.zig`, two) and `decorator invocation: round trip ---- …`
      (`decorator_invocation.zig`), each asserting the replies equal across runtimes
      (`helpers.repliesIdenticalAcrossRuntimes`) beside its `comptime/runtime/{beam,wat}/` pair

### Step 4 — an emitted `pub val` in scope and exported (T15)

Re-measure the repro; if it holds, an emitted `pub val` enters the module's binding list and its
export list like an emitted `pub fn` (the `@emit` merge in `decorator_eval.zig` /
`parseAndMergeContributions`).

Re-measured: holds (T15 row). The fix is outside this front's files on both halves — the merge order
and a `val`'s visibility before its declaration (`comptime.zig`, `infer.zig`: 01) and the
pre-comptime export check (`compiler-cli` `resolver.zig`: 26). Open question for the maintainer: is an
emitted declaration visible to the whole module (merged ahead of the module's own declarations, so an
emitted `val` whose initializer reads one of the module's own `val`s is refused instead), or only
after the declaration whose annotation emitted it?

**Acceptance:**
- [ ] `modules/emitted_pub_val_visible` — the module's own source reads it, an importer imports it, on four targets

### Step 5 — the reflection model's types resolve by identity (T17)

Re-measure; if it holds, `Decl`, `Param`, `Field`, `Method` and the rest of the reflection model
resolve inside a decorator body by their own identity (`bp@…`), not by name in the importing
scope, so an import named `Param` does not shadow them.

Re-measured: holds (T17 row). The resolution is the checker's (`infer.zig` / `env.zig`: 01).

**Acceptance:**
- [ ] `modules/reflection_type_not_shadowed_by_import` — a decorator module importing a user `Param` reads `m.params` of a `@Decl`

### Step 6 — the decision-gated rows

lg2-w (a host function from a decorator body — the row every decorator hits), lg2-j (comptime
state across invocations), lg2-o (filesystem access): each opens a step here when the maintainer
answers; nothing is built before.

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `scripts/snap_audit.sh --mode=runtime-parity` green; every re-recorded listing classified, never bulk-accepted; `COMPTIME REPLY` byte-identical at every step
- [ ] `scripts/beam_export_audit.sh` green (the comptime listings included)
- [ ] `AGENTS.md` of `src/comptime/`, `src/comptime/runtime/` in the same commit as each step
- [ ] Commit on `fix/14-comptime-on-beam`; no push, no merge

## Blast radius

Steps 1–3 add fixtures and move nothing; step 4 changes what every decorator's `@emit` may bind
(the libraries' decorators are the measured consumers: `zig build test-libs` at baseline is the
check); step 5 changes name resolution inside decorator bodies only.

## Notes

- **The resident node stays.** What left the compile path is the Erlang compiler, not `erl`; a
  commonJS / typescript / wasm build evaluates on the wat runtime and spawns nothing (decision 84).
- One lowering of Erlang per runtime (BEAM here, wasm in 18), cross-checked by parity.
- C-36 (`\u{…}` in `writeStringFromLexeme`) is 02's: the renderer is shared with the erlang target.
