# Front 14 — comptime-on-beam: the comptime pipeline's evidence and its cost per evaluation

**Priority:** medium · **State:** partial: steps 1 (fixture half), 3, 4, 7 and decision 237 on
feat; steps 2, 6 open
**Depends on:** `18-comptime-runtimes` (step 2's runtime-evaluation stage) · `01-checker` (step 2's
memo key; body file name and T17 are 01's rows) · decision-gated rows lg2-j, lg2-o, lg2-w — each a step once answered.
**Owns:** `modules/compiler-core/src/comptime/template_eval.zig`, `decorator_eval.zig` ·
`src/comptime/runtime/beam/**` (lowering) · `src/comptime/runtime/etf.zig` (term round trip) ·
`src/comptime/runtime/prelude.zig` (resident preludes) · `src/codegen/beam/asm_text.zig` (listing) ·
`scripts/comptime_bench.sh` (with 18: this front measures, 18 records the table) · `COMPTIME BEAM
ASSEMBLY` cells and `snapshots/comptime/runtime/beam/**` · its fixtures in
`codegen/tests/comptime_module.zig` and `comptime/tests/**` (carve-out of 07, named per commit)
**Does not touch:** `src/comptime/eval.zig`, `infer.zig` (01) · typed `beam_asm.zig` (03) ·
`erlang.zig`'s `emitComptimeModule` and `beam/erl_emitter.zig` (02) ·
`comptime/runtime/{runtime,persistent_beam,persistent_wat}.zig`, `runtime/wat/**` (18) · `libs/std/**`

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`; those starting `modules/`,
`libs/`, `scripts/` relative to `repository/botopink-lang/`.

## Goal

Fixtures prove the promised comptime pipeline and it meets budget: ≤ 1 ms per evaluation, N=200
call-site project ≤ 600 ms on both runtimes.

## Mechanism

- One module per declaration (`bp@comptime__{tpl,dec}__<decl>__<hash>`, 01c-a); host glue resident
  (`bp_comptime_template` / `bp_comptime_decorator`).
- Body reaches the node as BEAM bytes: read back by `runtime/wat/erl_parse.zig`, lowered by
  `runtime/beam/lower.zig`, assembled by `codegen/beam/beam_file.zig`, loaded by cmd 4; `COMPTIME
  REPLY` byte-identical across both runtimes.
- Emitted once per declaration and plan (`template_eval.zig` `emitKey`).
- Template capture carries only bindings whose name is a **word** of its text (decision 237;
  `captureToTerm` / `appendWords`); `lookup` of a non-word fails at the literal (`runtime/prelude.zig`
  `lookup/2`).

## Done

- Step 1, fixture half — `L:C` and caret asserted (`comptime_module.zig`, `decorator_invocation.zig`, `templates.zig`, `reject/comptime_method_nothing_answers`); body's file is `01-checker`'s row
- Step 2, box 1 — decision 237: capture carries only the words of its text
- Step 3 — three round-trip fixtures, `COMPTIME REPLY` byte-identical on beam and wat
- Step 4 — T15 answered by decision 216: closes with `130-decorator-outputs` step 6, nothing built here
- Step 5 — T17 re-measured (holds for `Param`, `Field`): fix is `01-checker`'s row
- Step 7 — `decorator_invocation.zig`'s `a \u{…} literal in the body …`: a body literal and a plain
  argument carrying `\u{…}` reach the `@emit` reply as the code points' UTF-8 bytes, byte-identical
  on beam and wat (`02-erlang` step 5 box 2); reds if `writeStringFromLexeme` writes `\x{…}`

## Open

### Step 2 — the N=200 slope (box 2)

After decision 237 (debug build, best of 5, load 16–19, 16 cores): commonJS (wat) N=200 485 ms,
erlang (BEAM) 711 ms (443 ms of it the N=0 build); slope 1.3 ms/eval on both; no longer grows with N.
Remaining per-evaluation cost:

| Stage | Owner |
|---|---|
| runtime evaluation — wat: fresh wasm3 environment, parse and load of the linked module per evaluation (`persistent_wat.zig`); BEAM: the frame round trip | 18 |
| trace listing — `main/1`'s argument rendered as text per evaluation (`listingWithArgument`, `runtime.listingOf`) for `comptime_traces`, which every backend renders (`trace.renderAlloc`) and only the snapshot harness and browser build read: a build reading no trace need not render one | this front (listing) with the owner of `trace.zig` and the codegen `comptime_trace` field |
| `infer.zig`'s template memo key appends the whole scope's JSON per call site | 01 |

- [ ] slope ≤ 1 ms per evaluation and N=200 ≤ 600 ms on both runtimes, measured with
      `scripts/comptime_bench.sh` and recorded in 18's table

### Step 6 — the decision-gated rows

lg2-w (hit by every decorator), lg2-j, lg2-o: each a step once answered; nothing built before.

**Gate:** standard (fronts.md § Gate) + `scripts/snap_audit.sh --mode=runtime-parity` green, every
re-recorded listing classified, `COMPTIME REPLY` byte-identical at every step ·
`scripts/beam_export_audit.sh` green (comptime listings included)

## Notes

- **Resident node stays.** The Erlang compiler left the compile path, not `erl`; commonJS /
  typescript / wasm builds evaluate on the wat runtime, spawn nothing (decision 84).
- One Erlang lowering per runtime (BEAM here, wasm in 18), cross-checked by parity.
