# Front 14 — comptime-on-beam: the comptime pipeline's evidence and its cost per evaluation

**Priority:** medium · **State:** partial: steps 1 (fixture half), 3, 4, 7, decision 237 and step
2's slope on feat; step 2's N=200 wall clock on the BEAM runtime and step 6 open
**Depends on:** `18-comptime-runtimes` (step 2's runtime-evaluation stage) · `01-checker` (step 2's
memo key; body file name and T17 are 01's rows) · step 6 (decisions 341, 342, 343).
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
- Step 2, box 2, the slope — ≤ 1 ms per evaluation on both runtimes (`scripts/comptime_bench.sh`,
  18's table): the wat runtime keeps one wasm3 instance per module atom and resets it to its
  load-time memory and globals (`persistent_wat.zig` `Kept`; a trapped instance dropped; nothing
  outlives the process, decision 229); the trace listing renders only `main/1`'s argument
  (`argumentListing`), no Erlang listing of the module; the template memo key is O(text)
  (`template_eval.memoKey`, 01's row); the bench's E-2 is the in-compiler stage split
  (`runtime/stages.zig`, `BOTOPINK_COMPTIME_STAGES`)
- Step 3 — three round-trip fixtures, `COMPTIME REPLY` byte-identical on beam and wat
- Step 4 — T15 answered by decision 216: closes with `130-decorator-outputs` step 6, nothing built here
- Step 5 — T17 re-measured (holds for `Param`, `Field`): fix is `01-checker`'s row
- Step 7 — `decorator_invocation.zig`'s `a \u{…} literal in the body …`: a body literal and a plain
  argument carrying `\u{…}` reach the `@emit` reply as the code points' UTF-8 bytes, byte-identical
  on beam and wat (`02-erlang` step 5 box 2); reds if `writeStringFromLexeme` writes `\x{…}`

## Open

### Step 2 — the N=200 wall clock on the BEAM runtime (box 2's rest)

Measured 2026-10-09 (debug build, best of 3, load 8–10, 16 threads): slope 0.5 ms/eval (wat),
0.6–0.7 (BEAM); N=200 443 ms (commonJS), 712 ms (beam), 782 ms (erlang). The per-evaluation
stages total 0.39 ms (wat) and 0.92 ms (BEAM, the `erl` spawn included) — what keeps the BEAM
builds above 600 ms is not per evaluation:

| Cost | ms | Owner |
|---|---|---|
| the N=0 build (no evaluation): beam 442, erlang 533 (commonJS 304) — erlang's includes the CLI's OTP session compiling the emitted `.erl` (`cli/otp.zig`, `cli/build.zig`), a second `erl` boot | 140–230 over commonJS | 02 / 03 / CLI |
| the comptime node's spawn + handshake on the first evaluation (`persistent_beam.zig`), 115 ms idle, 235 under load | ≈ 115 | 18 |
| `module` stage (`buildModule`: `emitKey` formats the declarations per call site) | 0.17/eval | this front |

- [ ] N=200 ≤ 600 ms on the BEAM runtime, measured with `scripts/comptime_bench.sh` and recorded in
      18's table (wat: met)

### Step 6 — host cells, files and independence in a decorator (decisions 341, 342, 343)

- [ ] 341: a host function reached from a decorator body travels with the cell of the runtime that
      evaluates it — `@External.Beam` (or `@External.Erlang`) on the BEAM runtime, `@External.Wasm` on the
      wat runtime (which forms run there, and the bridge to the term layout, are front 18's); the cells
      required are those of the package's declared `targets` (`erlang`/`beam` → Beam, `commonJS`/`wasm` →
      Wasm, none declared → both); a missing one refused at the call when the package is compiled, naming
      the function, the cell and the reason; `@External.Node` never serves; a cell per case on both
      runtimes, `COMPTIME REPLY` byte-identical where both cells exist
- [ ] 342: `@embedFile` / `@embedBytes` read the file relative to the `botopink.json` of the package that
      wrote the path (the application's for a decorator annotating its declarations; the member's in a
      workspace); a missing file, or a non-UTF-8 one for `@embedFile`, is a compile error at the call; the
      content hash enters the cell's cache key (with 26 for watch and the LSP); `rakun ws generate`'s
      checked-in `.bp` can go (rakun 93)
- [ ] 343: a module-level `var` written by a decorator body stays refused, the message pointing at
      `@TypeInfo.all(with: …)` at the entry point; one cell refusing a duplicate there naming both
      declarations

**Gate:** standard (fronts.md § Gate) + `scripts/snap_audit.sh --mode=runtime-parity` green, every
re-recorded listing classified, `COMPTIME REPLY` byte-identical at every step ·
`scripts/beam_export_audit.sh` green (comptime listings included)

## Notes

- **Resident node stays.** The Erlang compiler left the compile path, not `erl`; commonJS /
  typescript / wasm builds evaluate on the wat runtime, spawn nothing (decision 84).
- One Erlang lowering per runtime (BEAM here, wasm in 18), cross-checked by parity.
