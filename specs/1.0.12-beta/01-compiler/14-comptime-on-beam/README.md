# Front 14 — comptime-on-beam: the comptime pipeline's evidence and its cost per evaluation

**Priority:** medium · **State:** partial: steps 1 (fixture half), 3, 4, 7, decision 237, step 2's
slope, step 6's 341 and 343, step 8's boxes 1–3, 5, its imported `val` and `contentHash` (T19);
step 2's N=200 wall clock on the BEAM runtime, step 6's 342, and step 8's `Any` calls and 380 open
**Depends on:** `18-comptime-runtimes` (step 2's runtime-evaluation stage) · `01-checker` (step 2's
memo key; body file name and T17 are 01's rows; step 36's stages for step 8's `Any` calls; 342's
builtins) · 346 (`Bytes`, for `@embedBytes`).
**Owns:** `modules/compiler-core/src/comptime/template_eval.zig`, `decorator_eval.zig`, `host_cells.zig` ·
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
- `06-emilia/34` step 5's toolchain rows — a section value at comptime: inference's untyped rewrites
  (`enumSectionRewrites`, `indexRewrites`) applied to the block, this module's carried functions, a
  decorator's argument and the functions a decorator reaches (inferred first, as 371's), the section
  types carried (`block_eval.sectionType`, wrapper variants), an atom or tagged tuple lifted as the
  expected enum's constructor; a path in a function declared after the `comptime` refused naming it
  (`run/comptime_enum_section_value`, `run/comptime_decorator_section_value`,
  `modules/comptime_imported_section_path`, `reject/comptime_section_path_declared_after`) — and
  emilia's dispatcher: a record matched on the comptime runtime as its untagged map, no package atom
  (`run/comptime_record_pattern`); emilia's `comptime assertAsciiBody([.Pad.All.4, …], emptyTheme())`
  evaluates on both runtimes, `comptime className(…)` waits on T19 (`contentHash`, step 6) ·
  choices `cep-a`–`cep-c`
- Step 4 — T15 answered by decision 216: closes with `130-decorator-outputs` step 6, nothing built here
- Step 5 — T17 re-measured (holds for `Param`, `Field`): fix is `01-checker`'s row
- Step 7 — `decorator_invocation.zig`'s `a \u{…} literal in the body …`: a body literal and a plain
  argument carrying `\u{…}` reach the `@emit` reply as the code points' UTF-8 bytes, byte-identical
  on beam and wat (`02-erlang` step 5 box 2); reds if `writeStringFromLexeme` writes `\x{…}`
- Step 8, box 1 — a template reads a hole's build value (decision 355): each `Interp` part of
  `q.parts()` carries `known` and `value` (`template_eval.zig` `interpTerm`), computed by
  `block_eval.zig` `holeValue` (`infer.zig` `withHoleValues`): a literal, a `comptime`, a non-`var`
  `val` of the module whose initializer is known at build, a template call already expanded whose
  arguments all are (`knownAtBuild`) — evaluated on the comptime runtime as a `comptime` is, a value
  that raises refused at the hole; the spelling is `14s8-a`, the reach `14s8-b`, the refusal `14s8-c`
  (`run/styled_holes_known_at_build`, four targets; `reject/hole_known_at_build_raises`; `comptime:
  round trip ---- a hole known at build …`, the reply byte-identical on beam and wat)
- Step 8, box 2 — a record a `comptime` answers is lifted as its type's declared constructor; a type of
  a module this one does not import is imported where the value is written (`block_eval.zig`
  `constructorName`, `Env.templateImports` erased as a type alias) (`modules/comptime_reaches_package_template`)
- Step 8, box 3 — a `comptime` reaching a template call evaluates its expansion (`Preparer.replace`,
  `expandedFn` for a carried function of the module), the template module's functions it names carried
  under their aliases (`comptime.zig` `importTemplateAliasClosures`); a function holding a template call
  declared after the `comptime` is refused naming the call (`unexpandedTemplateCall`, `14s8-d`); `"${…}"`
  in a carried function lowers in the comptime module (`erlang.zig`'s untyped `stringTemplate` arm), so
  the erlang emitter no longer aborts (`modules/comptime_reaches_package_template`,
  `run/comptime_interpolation_in_called_fn`, `reject/comptime_template_call_declared_after`)
- Step 6, 341 — a host function a body that runs at build reaches travels with the cell of the runtime
  that evaluates it (`comptime/host_cells.zig`): the BEAM runtime runs the `@External.Erlang` cell (an
  `@External.Beam("module", "symbol")` read as one), the wat runtime the function an
  `@External.Wasm("fn:…")` binding names (`forRuntime`; an `op:` / `wasi:` binding, or no cell, a
  refusal naming the function — `has no #[@External.<Target>(…)] for the wat comptime runtime`); std's
  functions travel too, through a namespace or a leaf import, each renamed `__bp_std__<module>__<name>`
  with its module's closure (`Env.stdCarried`, built once by `registerStdlib`), and an export carries
  its own (`registerExports` `exportedFn` / `exportedSupport`). What a decorator may call is decided
  when its package is compiled (`checkDecorators`, from `Module.targets`, filled by the CLI's
  loaders): a host function it reaches without a cell its declared `targets` need is
  `decorator-host-cell-missing` at the call, naming the function, the cell and the reason
  (`run/decorator_host_cells`, `modules/decorator_imported_host_function`,
  `modules/decorator_host_cell_targets`, `reject/decorator_host_cell_missing`; `COMPTIME REPLY`
  byte-identical on beam and wat, `decorator_invocation.zig`'s round trip); `docs.md` § Host
  functions at compile time
- Step 6, 343 — a decorator body writing a module-level `var` (directly or through a function of its
  module) is `decorator-writes-module-var` at the write, the hint pointing at `@TypeInfo.all(with: …)`
  (`decorator_eval.checkIndependent`, `reject/decorator_writes_module_var`); a duplicate across
  declarations is refused at the entry point naming both (`reject/typeinfo_all_duplicate_at_entry`)
- Step 8, the imported `val` — a hole naming a `val` another module exports is known at build when
  its initializer is: the export carries the value (`block_eval.exportedBuildValue`, read through
  `Env.importedBuildValues`) — `modules/hole_imported_val_known_at_build`, four targets
- Step 8, `contentHash` at comptime (T19, with step 6's cells) — `comptime hash.contentHash("hello")`
  is `"f923099"` on the four targets (`run/comptime_std_host_function`); a private type of another
  module a carried function builds travels too (`block_eval.findDeclared`, emilia's `Placed`).
  `comptime padAll(2)` now reaches styled's `use context(StyledContext)` and is refused naming the
  `use` (`block_eval.useReached`, question `14s8-e` (a) ★); emilia's `comptime className(…)` evaluates
  on the BEAM runtime and is refused on the wat one at `register` (no `@External.Wasm`) — emilia's
  369 step, 34 step 5 box 5
- Step 8, box 5 — `styled "${tab4} color: red;"` with `tab4 = styledProperty "tab-size: 4;"` is emitted
  `styledConstant("s_b480a37a", ".s_b480a37a{tab-size:4;color:red}")` on erlang and commonJS (styled's
  `repository-stages.sh` reads it; `${padAll(2)}` stays `styledComputed`); the four-target cell is
  `run/styled_holes_known_at_build` (a template of its own: the compiler knows no library)

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

### Step 6 — files at compile time (decision 342)

- [ ] 342: `@embedFile` / `@embedBytes` read the file relative to the `botopink.json` of the package that
      wrote the path (the application's for a decorator annotating its declarations; the member's in a
      workspace); a missing file, or a non-UTF-8 one for `@embedFile`, is a compile error at the call; the
      content hash enters the cell's cache key (with 26 for watch and the LSP); `rakun ws generate`'s
      checked-in `.bp` can go (rakun 93). Waits on `01-checker` (the builtins' declaration in
      `builtins.d.bp` and their checking) and 346 (`Bytes`, not built); this front's half is the
      package root on `Module` and the read at the call

**Gate:** standard (fronts.md § Gate) + `scripts/snap_audit.sh --mode=runtime-parity` green, every
re-recorded listing classified, `COMPTIME REPLY` byte-identical at every step ·
`scripts/beam_export_audit.sh` green (comptime listings included)

### Step 8 — a `styled` literal whose holes are known at build, computed at build (decision 355)

```bp
pub val tab4 = styledProperty "tab-size: 4;";
pub val code = styled "${tab4} color: red;";   // styledConstant("s_…", ".s_…{tab-size:4;color:red}")
```

Both open boxes wait on `01-checker` step 36 (every function's stage, not built): which call is `Any`
is the checker's answer. `padAll(2)` also reads styled's context (`use context(StyledContext)`), which
no `comptime` provides — question `14s8-e`.

- [ ] a call of an `Any` function (376) whose arguments are known at build is known at build and computed
      by the comptime runtime — in a hole (`styled "${padAll(2)}"`, `padAll(ESPACO)`) and in a `val`'s
      initializer; a raise refused at the hole (14s8-c); `padAll(n)` with `n` a parameter stays at render —
      `run/hole_any_call_at_build`, `reject/hole_any_call_raises`
- [ ] every expression with build inputs and `Any` functions computed at build wherever it is written (380):
      a body's `val raio = ESPACO * 2 + 4;` emitted as `12`; no step or time budget — a raise an error at the
      expression (`reject/fold_raises_at_build`); `@panic` / `throw` computed only under a written `comptime`
      (`run/fold_keeps_dead_panic`)

## Notes

- **Resident node stays.** The Erlang compiler left the compile path, not `erl`; commonJS /
  typescript / wasm builds evaluate on the wat runtime, spawn nothing (decision 84).
- One Erlang lowering per runtime (BEAM here, wasm in 18), cross-checked by parity.
