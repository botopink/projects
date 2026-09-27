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
| box 1 | a template body calling `.foo(…)` no primitive type and no host function provides | `codegen/tests/comptime_module.zig:322` ("a method nothing answers is a located error, not an undefined function") exists — verify the diagnostic is **located** at the call in the body (the 1.0.10 box asks for the compiler's own message, not a runtime's) and tick |
| box 2 | the generated N=200 call-site project | slope and total unmeasured since `prelude_cache` landed; the budget is ≤ 1 ms per evaluation, N=200 build ≤ 600 ms |
| box 3 | the term round trip per shape | `runtime/etf.zig` has scalar / container / capture encoders only; no fixture for a holed template (`${…}` parts), an `@ExprCustom` return with its reference tree, or a `@Decl` handle carrying fields, methods, variants and annotations |
| T15 | `@emit("pub val FooCol = …")` | emitted functions read it; the module's own source gets `unbound variable 'FooCol'`, an importer "not exported" — unverified by the audit, the rakun repro is `$HOME/.cache/bp-rakun/emitval` |
| T17 | a decorator module importing `sql/params`' `Param` | `m.params` of a `@Decl` reads that `Param` (`unknown field 'typeName' on type 'Param'`) — unverified by the audit |

## Steps

### Step 1 — the located `unsupported_method` fixture (box 1)

Verify `comptime_module.zig:322` asserts the location (line and column of the call inside the
body, the body's file named); if it asserts the message only, add the location. The `reject/`
twin: `reject/comptime_method_nothing_answers` with the `.expect` at the call.

**Acceptance:**
- [ ] the fixture asserts `file:L:C`; the `reject/` cell names the code and the caret

### Step 2 — the N=200 slope (box 2)

`scripts/comptime_bench.sh` re-run at the open on the runner's machine; the slope and the N=200
total recorded in 18's table (18 step 3); if the budget is still unmet, the stage that costs it
named with its owner.

**Acceptance:**
- [ ] slope ≤ 1 ms per evaluation, N=200 ≤ 600 ms — or the row names the stage and the front (`prelude_cache` is landed; the next candidate is the per-call ETF encode of the capture map)

### Step 3 — the round-trip fixtures (box 3)

One fixture per shape in `comptime/tests/**` (or `snapshots/comptime/runtime/beam/**` with its
wat pair — `snap_audit.sh --mode=runtime-parity` pins them equal): a holed template whose `${…}`
parts carry a record, an array and a `?T`; an `@ExprCustom` return whose reference tree names a
declaration of another module; a decorator whose `@Decl` handle carries fields, methods, variants
and annotations, each read back in the body.

**Acceptance:**
- [ ] three fixtures, `COMPTIME REPLY` byte-identical on beam and wat; `runtime/AGENTS.md` names the encoded shapes

### Step 4 — an emitted `pub val` in scope and exported (T15)

Re-measure the repro; if it holds, an emitted `pub val` enters the module's binding list and its
export list like an emitted `pub fn` (the `@emit` merge in `decorator_eval.zig` /
`parseAndMergeContributions`).

**Acceptance:**
- [ ] `modules/emitted_pub_val_visible` — the module's own source reads it, an importer imports it, on four targets

### Step 5 — the reflection model's types resolve by identity (T17)

Re-measure; if it holds, `Decl`, `Param`, `Field`, `Method` and the rest of the reflection model
resolve inside a decorator body by their own identity (`bp@…`), not by name in the importing
scope, so an import named `Param` does not shadow them.

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
