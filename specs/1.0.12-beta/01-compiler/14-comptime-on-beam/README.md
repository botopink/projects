# Front 14 — comptime-on-beam: the comptime pipeline's evidence and its cost per evaluation

**Priority:** medium · **State:** partial: steps 1 (fixture half), 3, 4 and decision 237 on feat;
steps 2, 6, 7 open
**Depends on:** `18-comptime-runtimes` (step 2's runtime-evaluation stage) · `01-checker` (step 2's
memo key; the body's file name and T17 are 01's rows) · decision-gated rows lg2-j (comptime state
across decorator invocations), lg2-o (filesystem access from a comptime body), lg2-w (a host
function called from a decorator body) — each opens a step here when answered.
**Owns:** `modules/compiler-core/src/comptime/template_eval.zig`, `decorator_eval.zig` ·
`src/comptime/runtime/beam/**` (the lowering) · `src/comptime/runtime/etf.zig` (the term round trip)
· `src/comptime/runtime/prelude.zig` (the resident preludes) · `src/codegen/beam/asm_text.zig` (the
listing) · `scripts/comptime_bench.sh` (with 18: this front measures, 18 records the table) · the
`COMPTIME BEAM ASSEMBLY` cells and `snapshots/comptime/runtime/beam/**` · its fixtures in
`codegen/tests/comptime_module.zig` and `comptime/tests/**` (a carve-out of 07, named per commit)
**Does not touch:** `src/comptime/eval.zig`, `infer.zig` (01) · the typed `beam_asm.zig` (03) ·
`erlang.zig`'s `emitComptimeModule` and `beam/erl_emitter.zig` (02) ·
`comptime/runtime/{runtime,persistent_beam,persistent_wat}.zig`, `runtime/wat/**` (18) · `libs/std/**`

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless they start with
`modules/`, `libs/` or `scripts/`, which are relative to `repository/botopink-lang/`.

## Goal

The comptime pipeline the design promised is proved by fixtures and meets its budget: a comptime
evaluation costs ≤ 1 ms and the N=200 call-site project builds in ≤ 600 ms on both runtimes.

## Mechanism

One module per declaration (`bp@comptime__{tpl,dec}__<decl>__<hash>`, 01c-a); the host glue resident
(`bp_comptime_template` / `bp_comptime_decorator`); a body reaches the node as BEAM bytes (read back
by `runtime/wat/erl_parse.zig`, lowered by `runtime/beam/lower.zig`, assembled by
`codegen/beam/beam_file.zig`, loaded by cmd 4); `COMPTIME REPLY` byte-identical across both runtimes.
A comptime module is emitted once per declaration and plan (`template_eval.zig` `emitKey`). A
template capture carries only the bindings whose name is a **word** of its text (decision 237;
`captureToTerm` / `appendWords`); `lookup` of a name that is not a word fails at the literal
(`runtime/prelude.zig` `lookup/2`).

## Done

- Step 1, fixture half — `L:C` and the caret asserted (`comptime_module.zig`, `decorator_invocation.zig`, `templates.zig`, `reject/comptime_method_nothing_answers`); the body's file is `01-checker`'s row
- Step 2, box 1 — decision 237: a capture carries only the words of its text
- Step 3 — the round-trip fixtures: three, `COMPTIME REPLY` byte-identical on beam and wat
- Step 4 — T15 answered by decision 216: closes with `130-decorator-outputs` step 6, nothing built here
- Step 5 — T17 re-measured (holds for `Param` and `Field`): the fix is `01-checker`'s row

## Open

### Step 2 — the N=200 slope (box 2)

After decision 237 (debug build, best of 5, load 16–19 on 16 cores): commonJS (wat) N=200 485 ms,
erlang (BEAM) 711 ms (443 ms of it the N=0 build); slope 1.3 ms/eval on both. The cost no longer
grows with N. What is left per evaluation, by owner:

| Stage | Owner |
|---|---|
| the runtime's evaluation — wat: a fresh wasm3 environment, parse and load of the linked module per evaluation (`persistent_wat.zig`); BEAM: the frame round trip | 18 |
| the trace listing — `main/1`'s argument rendered as text per evaluation (`listingWithArgument`, `runtime.listingOf`) for `comptime_traces`, which every backend renders (`trace.renderAlloc`) and only the snapshot harness and the browser build read: a build that reads no trace need not render one | this front (the listing) with the owner of `trace.zig` and the codegen `comptime_trace` field |
| `infer.zig`'s template memo key appends the whole scope's JSON per call site | 01 |

- [ ] slope ≤ 1 ms per evaluation and N=200 ≤ 600 ms on both runtimes, measured with
      `scripts/comptime_bench.sh` and recorded in 18's table

### Step 6 — the decision-gated rows

lg2-w (the row every decorator hits), lg2-j, lg2-o: each opens a step here when answered; nothing is
built before.

### Step 7 — a decorator body carrying `\u{…}` (from `02-erlang` step 5)

`02-erlang`'s renderer fix (`writeStringFromLexeme` decodes a `\u{…}` escape to its UTF-8 bytes)
serves the comptime module text too.

- [ ] a `comptime/tests/**` fixture: a decorator body carrying a `\u{…}` literal evaluates to the
      character, on both runtimes

**Gate:** standard (fronts.md § Gate) + `scripts/snap_audit.sh --mode=runtime-parity` green, every
re-recorded listing classified, `COMPTIME REPLY` byte-identical at every step ·
`scripts/beam_export_audit.sh` green (the comptime listings included)

## Notes

- **The resident node stays.** What left the compile path is the Erlang compiler, not `erl`; a
  commonJS / typescript / wasm build evaluates on the wat runtime and spawns nothing (decision 84).
- One lowering of Erlang per runtime (BEAM here, wasm in 18), cross-checked by parity.
