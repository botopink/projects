# Snapshot review — codegen `comptime.zig`, `std_package.zig`, `runtime_scratch.zig`, `comptime_module.zig`, `dts_skips_templates.zig` (+ cross-cutting)

Repo: `/home/ericfillipe/develop/botopink-lang/repository/botopink-lang` (re-checked at HEAD `96ff203`;
first pass was written at `beb19e9`).
Snapshot root below: `modules/compiler-core/snapshots/codegen/` (abbrev. `S/`), now **flat**:
`S/<target>/<slug>.snap.md` with `<target>` ∈ `commonJS | erlang | beam | wasm`, plus
`S/errors/<target>/<slug>.snap.md` (`96ff203`, a pure move — every path in this document was
rewritten, no content changed).

> **Status (1.0.1-beta close):** the harness defects this report leans on (H1-H10) are fixed: the RUN LOG is decided by the process exit status, an `erlc` warning no longer blanks a log, a program that does not compile fails its snapshot test (or records a `COMPILE DIAGNOSTIC`), every backend is compared in one round, and the 0-byte snapshots are gone. The per-backend rows below predate the beam / erlang / wasm fix waves - re-derive each one at HEAD before acting on it. Residuals are tracked in [`1.0.2-beta/09-review-tooling/README.md`](../../1.0.2-beta/09-review-tooling/README.md). The tables below are the audit record and are kept verbatim.

## Re-check summary (2026-09-15)

All 30 finding rows and all cross-cutting notes (H1–H7, B1–B6) were re-verified at HEAD.

| classification | count |
|---|---|
| confirmed | 27 rows + H1–H6 + B2–B6 |
| corrected | 3 rows (`comptime_validation…`, `comptime_block_with_break`, `template_end_to_end_lookup_ref…`) + H7 (cache count) + B1 (body count) |
| withdrawn | 0 |
| uncertain | 0 |

What changed in the tree since the first pass, and what it does to this report:
- `4862f9b` added `COMPTIME ERLANG` / `COMPTIME REPLY` sections (`src/comptime/trace.zig`, rendered by
  `codegen/snapshot.zig:31-38`) and reformatted `COMPTIME VALUES` to
  `ct_N: <declaration> → literal`. In this batch that touches exactly 7 slugs: 3 template slugs gain
  the erl exchange (`template_end_to_end_holed_html_via_parts_runs`, `…cross_module…`,
  `…yaml_model…`) and 5 slugs get the new `ct_N:` line. **No generated code changed** — diffing every
  slug of this batch against `beb19e9` shows either byte-identical files or a difference confined to
  those sections (verified with `snapdiff.py`).
- The new `COMPTIME REPLY` blocks are now used as evidence below (they show what the template
  actually returned, which sharpens the `yaml_model` and `holed_html` rows).
- Line-number drift was re-resolved for every citation (`codegen/erlang.zig` +10 after ~line 795,
  `codegen/{commonJS,beam_asm,wat}.zig` +1 after their `codegenEmit` result literal,
  `codegen/snapshot.zig` rewritten, `legacyRuntimeTag` gone).

Notable corrections:
- **H7 / cache**: 474 entries (not 470); 434 dated 2026-06-27, 13 on 2026-07-02, 22 on 2026-09-14,
  5 on 2026-09-15. Every non-empty RUN LOG in this batch still resolves to a 2026-06-27 entry.
- **B1 count**: my rescan of `S/beam` finds **37** arity ≥ 1 bodies whose first instruction after
  `allocate` moves a constant into `{x,0}` (135 including arity-0 bodies, where it is harmless), not
  54. The behaviour itself is re-confirmed at runtime.
- **`comptime_block_with_break` / `comptime_validation…` fixes**: `comptime/error.zig:427-428`
  rejects *every* identifier inside a comptime block, not just runtime ones — so "allow local
  bindings in the validator" and "declare `val greeting`" are both insufficient on their own.
- **`template_end_to_end_lookup_ref…`**: the `pick` intercept still shadows the user fn (reproduced),
  but restoring the snapshot now needs more than that fix: with the fn renamed to `pick2`, the
  template module fails to compile in the erl host with `{undefined_function,{ref,1}}` — `b.ref()`
  has no host implementation at HEAD.

Execution evidence for the re-check lives in the scratch dir `rev-builtins-ctmisc/`:
`run_all.py` + `run_ctmisc.log` (extract every code section of every snapshot in this batch and run
it: node / erlc+erl / erlc +from_asm + erl / wasmtime compile+run), `beamrun/run_ct.py` (export-all
BEAM re-assembly + direct `erl -eval` calls into the specialized functions), `cachekey.py`
(recomputed `runtime.zig` cache keys), `orphans.py` (slug rule + orphan scan), `snapdiff.py`
(HEAD vs `beb19e9` per slug), `probe/` (throwaway `botopink new` project driven with
`zig-out/bin/botopink check`, binary built 2026-09-15 19:48 — after every parser/comptime commit in
this tree). Tools: node 25.8, OTP 29 `/usr/bin/erl`, wasmtime 45. Nothing in the repo was modified and
no `zig build` was run.

## Verdict counts (36 tests: 26 comptime.zig, 2 std_package.zig, 3 runtime_scratch.zig, 3 comptime_module.zig, 2 dts_skips_templates.zig)

Unchanged by the re-check:

| verdict | count |
|---|---|
| ok | 6 |
| wrong-output | 14 |
| wrong-test | 5 |
| weak | 5 |
| duplicate | 1 |
| known | 5 |
| skip-undocumented | 0 |
| orphan | 0 |
| uncertain | 0 |

(Each slug gets one primary verdict = most serious; secondary issues are listed in the evidence column.)

---

## 0. Cross-cutting harness defects that explain most of the batch (read first)

These are root causes; the per-slug table references them as H1..H7.

**H1 — parse/type errors produce an EMPTY snapshot that passes vacuously.** *(confirmed)*
`codegenEmit` silently drops modules with `.parseError`/`.typeError`:
`src/codegen/commonJS.zig:52-53` (`.parseError => continue, .typeError => continue`), same at
`erlang.zig:315-316`, `beam_asm.zig:403-404`, `wat.zig:96-97`. With zero outputs
`buildSnapshotMulti` (`codegen/snapshot.zig:142-154`) returns `""`; `utils/snap.zig:81-84` trims both
sides and `"" == ""` passes. A 0-byte `.snap.md` therefore means "this source does not compile" and
the test asserts nothing. Re-counted at HEAD: **29 slugs × 4 backends = 116 empty snapshot files**
(list in §3); 6 are in this batch. Fix: `assertJs` must fail when `outputs.items.len == 0` or when any
module had a parse/type error; delete the empty files and regenerate.

**H2 — `assertJs`/`assertJsSingle` ignore `comptime_err`.** *(confirmed)* A validation error is
emitted as `js = ""`, `comptime_script = null`, no run (`commonJS.zig:54-63`), and the snapshot
records an empty code block with no RUN LOG (see `comptime_block_with_break`). Only `assertJsError`
inspects `comptime_err` (`tests/helpers.zig:161-172`). Fix: in `helpers.assertJs` fail if
`o.result.comptime_err != null`.

**H3 — `executeBeamAsm` has an inverted success check** *(confirmed — now empirically)*
(`src/codegen/runtime.zig:365`, same at `:375`, introduced by `80e27667`, 2026-07-01):
```zig
const assemble_result = try runWithTimeout(allocator, io, &.{ "erlc", "+from_asm", "-o", tmp_dir, asm_filename }, RUNTIME_TIMEOUT_NS);
if (assemble_result.len == 0) return allocator.dupe(u8, "");
```
`runWithTimeout` returns `""` on non-zero exit AND a silent successful `erlc +from_asm` also prints
nothing (re-verified in scratch: rc=0, empty stdout/stderr on every successful assembly). So on a
cache miss every BEAM RUN LOG is `""` — known today: a cold cache empties 70 beam RUN LOGs (and 5
erlang ones via H4). Every non-empty BEAM RUN LOG in this batch (`page` ×4, `8081`,
`-1\n<<"less">>`) is a **runtime-cache hit from 2026-06-27** — re-verified by recomputing the SHA-256
key of `runtime.zig:cacheKey` for each snapshot's code and finding
`modules/compiler-core/.botopinkbuild/runtime-cache/<key>` with mtime `2026-06-27 01:12–01:14` (e.g.
`template_end_to_end_holed_html_via_parts_runs` beam → `a020387fa133…` = `OK:page\n`, shared with the
bounded/line-string slugs). On a clean cache (CI / fresh clone) these tests would mismatch. Fix:
`if (assemble_result.len != 0)` is also wrong (warnings) — check the exit status, not output length.

**H4 — `executeErlang` returns `""` whenever erlc emits any warning** *(confirmed)*
(`runtime.zig:306`, `:314`): `runWithTimeout:61-67` merges stderr into the returned buffer, and erlc
warnings go to stderr, so `if (compile_out.len > 0) return ""` drops the run for any module with an
unused-variable/shadowing warning. `builtin_result_namespace_qualified_call_lowers_inline` (warning
`main.erl:16:29: variable 'R' shadowed in 'fun'`, reproduced) and
`std_package_order_enum_module_with_type_export` (warnings `variable 'Lt' is unused` /
`this clause cannot match`, reproduced) keep their erlang RUN LOG only through June-27 cache hits
(`OK:42\n` = `41de431b4562…`, `OK:-1\n<<"less">>\n` = `2b745a1d417f…`). Fix: check exit status only.

**H5 — `executeWat` is a stub** *(confirmed)* (`runtime.zig:393-401`, `caa7377d`): returns `""`
unconditionally → every wasm RUN LOG empty (known). Note wasmtime would *reject* most wasm modules of
this batch (see table), so re-enabling execution will surface them.

**H6 — RUN LOG contains stderr on success** *(confirmed)*: the contract at `runtime.zig:8-26` says
"return `result.stdout` as-is. stderr is dropped", but `runWithTimeout` (`:61-67`) appends stderr
whenever it is non-empty. The stdout-only helper `combineOutput` (`:158-166`) is dead code — nothing
calls it.

**H7 — the runtime cache key excludes the harness/toolchain** *(corrected: counts)*, so H3/H4
regressions are masked locally by stale entries. At HEAD: **474** entries — 434 from 2026-06-27
(oldest), 13 from 2026-07-02, 22 from 2026-09-14, 5 from 2026-09-15. Note the aux list is never empty
for codegen fixtures (`codegen.zig:48-52` passes the entry module to itself as `("main", code)`),
which key recomputation must account for.

**Generic backend bugs seen repeatedly (outside this batch too):**
- **B1 (beam)** *(behaviour confirmed, count corrected)*: in any function with arity ≥ 1, the first
  local binding is materialized through `{x,0}` before the parameter is saved, clobbering the
  parameter. A rescan of `S/beam` finds **37** arity ≥ 1 function bodies whose first instruction after
  `allocate` is `{move, {integer|literal|atom|float, …}, {x, 0}}` (135 counting arity-0 bodies, where
  it is harmless) across 32 files (`b1scan.py`). Re-verified at runtime by exporting and calling the
  functions: `'scale_$0'(100)` → `4` (expected 200), `'scale_$1'(100)` → `9` (expected 300),
  `'multiply_$0'(21)` → `4` (expected 42), `'multiply_$1'(21)` → `9` (expected 63); loop-unrolled
  `'execute_$0'(10)` → `0` (expected 20).
- **B2 (wasm)** *(confirmed)*: specialized functions are injected with `.returnType = null`
  (`src/comptime/transform.zig:272`), so `wat.zig:876` omits `(result i32)` while the body still
  pushes a value + `return`. wasmtime reports the mismatch at the **caller**'s `local.set`, e.g.
  `failed to compile: wasm[0]::function[0]::main … Invalid input WebAssembly code at offset 88: type
  mismatch: expected i32 but nothing on stack`. Affects every `*_$N` function in the batch.
- **B3 (erlang)** *(confirmed)*: module-level runtime vals are bound as locals in `'_botopink_main'/0`
  (`src/codegen/erlang.zig:762-776`) but referenced as free variables from other functions →
  `variable 'X' is unbound` compile error (root cause of the known `Cfg`/`Page`/`COMMANDS` issues,
  also `Base`).
- **B4 (erlang)** *(confirmed)*: string `+` is emitted as arithmetic `+` on binaries (badarith) — also
  present in non-template fixtures such as `S/erlang/builtin_print_with_variable.snap.md` line 16
  `io:format("~p~n", [(<<"Hello, ">> + Name)])`.
- **B5 (beam)** *(confirmed)*: references to module-level vals are lowered to atoms
  (`{move, {atom, page}, {x, 0}}`, `{atom, cfg}`, `{atom, base}`, `{atom, 'COMMANDS'}`).
- **B6 (wasm)** *(confirmed)*: module-level non-literal vals are not emitted (`global.get $page` /
  `$base` → `unknown global`), and `(local ...)` declarations are emitted mid-body (invalid WAT).

---

## 1. Findings table (all non-`ok`)

| slug | backend(s) | verdict | re-check | evidence | expected vs actual | suggested fix |
|---|---|---|---|---|---|---|
| comptime_folding_integer_addition_folds_to_literal | all 4 | wrong-test | confirmed | All 4 files are 0 bytes (`S/{commonJS,erlang,beam,wasm}/comptime_folding_integer_addition_folds_to_literal.snap.md`, blob `e69de29`, empty since `0c30a38`). Source (`comptime.zig:17-22`) has a top-level statement `@print(v1);`; `@print` lexes as `builtinIdent` and `parser.zig:333-347` returns `UnexpectedToken` → parseError → H1. Re-probed with the current binary: this source → `error: parse error in main`; the same source with `@print` inside `fn main()` checks clean. | Expected (after wrapping in `fn main`): `const v1 = 2;`, `ct_0: val v1 = comptime 1 + 1 → 2`, RUN LOG `2`. Actual: nothing pinned; test passes vacuously. | Move `@print` into `fn main() {}`; delete the empty files; fix H1. |
| comptime_folding_block_with_break_value_inlines_result | all 4 | wrong-test | confirmed | 0-byte snapshots; source `comptime.zig:24-31` ends with top-level `@print(t);` → parseError (H1). | Expected `const t = 24;`, `ct_0 … → 24`, RUN LOG `24`. Actual: empty. | Same as above. |
| comptime_folding_float_multiplication_folds_to_literal | all 4 | wrong-test | confirmed | 0-byte snapshots; top-level `@print(pi2);` (`comptime.zig:38`). | Expected `ct_0 … → 6.28`, RUN LOG `6.28` (3.14*2.0 = 6.28 exactly in IEEE double). Actual: empty. | Same. |
| comptime_folding_multiplication_binds_tighter_than_addition | all 4 | wrong-test | confirmed | 0-byte snapshots; top-level `@print(n);` (`comptime.zig:47`). | Expected `ct_0 … → 14`, RUN LOG `14`. Actual: empty. | Same. |
| comptime_val_comptime_val_folds_arithmetic_to_literal | all 4 | wrong-test | confirmed | 0-byte snapshots; top-level `@print(result);` (`comptime.zig:69`). | Expected `const result = 30;`, `ct_0 … → 30`, RUN LOG `30`. Actual: empty. | Same. |
| comptime_validation_runtime_identifier_inside_comptime_raises_error | errors/all 4 | weak | **corrected** (fix was insufficient) | Error text identical on 4 backends, location correct: `2 │     break greeting;` / `^^^^^^^^` at `:2:11` (col 11 = `g`) in `S/errors/<target>/…`. But (a) `greeting` is never declared — the title says "runtime identifier" and the message says `'greeting' is a runtime identifier`, yet there is no runtime val at all: `comptime/error.zig:427-428` (`.identifier => .ident => return ComptimeError{ .ident = name … }`) rejects **any** identifier, bound or not; (b) the full source does not parse (top-level `@print(msg);` — re-probed: `error: parse error in main`), so `codegen.generate` yields no outputs and the error is recovered by `helpers.extractComptimeValidationError` (`tests/helpers.zig:182-211`) re-parsing a truncated prefix; (c) header `┌─ :2:11` has an empty file name. | Expected: a fixture with `val greeting = "hi";` before the comptime block, inside a parseable program, rendered with `main.bp:2:11`. Actual: validates an undeclared identifier in a truncated source. | **Corrected fix:** adding `val greeting = "hi";` alone changes nothing — the validator must first learn which identifiers are comptime-known (`error.zig:427-431`). Then wrap `@print` in `fn main` and pass a path so the location reads `main.bp:2:11`. |
| comptime_specialization_distinct_string_args_generate_specialized_functions | erlang, beam, wasm | wrong-output (also duplicate) | confirmed | erlang: `((Prefix + <<": ">>) + Name).` → re-ran: `CRASH error:badarith [{erlang,'+',[<<"INFO">>,<<": ">>]…` (B4); erlc also warns `evaluation of operator '+'/2 will fail with a 'badarith' exception` at lines 11 and 15. beam `'build_$0'`: `{move, {literal, <<"INFO">>}, {x, 0}}.` overwrites param `Name` (B1), then `{gc_bif, '+', …}` → re-ran `'build_$0'(<<"x">>)` = `CRASH error:badarith`. wasm: `(func $build_$0 (param $name i32)` has no `(result i32)` (B2); wasmtime: `function[0]::main … expected i32 but nothing on stack` (offset 89). RUN LOG empty everywhere only because `main` never prints. All 4 outputs are byte-identical to `comptime_specialization_same_string_arg_reuses_specialized_function` except SOURCE line 3 (`prefix comptime:` vs `comptime prefix:`) — re-diffed on all four backends. | Expected `r1 = "INFO: Sistema iniciado"`, `r2 = "WARN: Memória alta"` (JS gives exactly that when called). Actual: crash (erlang/beam), invalid module (wasm). | Fix B1/B2/B4; add `@print(r1); @print(r2); @print(r3);` so RUN LOG pins behavior; rename the test to cover the postfix `name comptime:` syntax or make the call sites differ from the "reuse" test. |
| comptime_specialization_same_string_arg_reuses_specialized_function | all 4 | duplicate | confirmed | Same call sites and same generated code as the test above; the only difference in any of the 4 files is the SOURCE param-modifier position. Inherits the same erlang/beam/wasm wrong-output. | Expected: a distinct fixture (e.g. only repeated `"INFO"` args, asserting a single `build_$0`). Actual: duplicate. | Merge or differentiate. |
| comptime_specialization_distinct_integer_args_generate_specialized_functions | beam, wasm (+weak) | wrong-output | confirmed | beam `'multiply_$0'`: `{move, {integer, 2}, {x, 0}}. {move, {x, 0}, {y, 0}}. {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 0}], {x, 0}}.` → re-ran: `'multiply_$0'(21)` = `4`, `'multiply_$1'(21)` = `9`, `'multiply_$0'(10)` = `4` (B1). wasm: `(func $multiply_$0 (param $x i32)` no result → wasmtime `function[0]::calculate … expected i32 but nothing on stack` (offset 61) (B2). No `main`, so `calculate` never runs (erlang: `erl` → `CRASH error:undef` for `_botopink_main`) and the RUN LOG can never show it. | Expected `double=42, triple=63, doubleAgain=20` (JS verified). Actual beam `4, 9, 4`; wasm invalid. | Fix B1/B2; rename `calculate`→`main` and print the three values. |
| comptime_specialization_comptime_val_used_as_specialization_argument | erlang, beam, wasm (+wrong-test) | wrong-output | confirmed | erlang: `Doubled = 'scale_$0'(Base),` with `Base = 15` bound only in `'_botopink_main'` → erlc exit 1, `main.erl:6:26: variable 'Base' is unbound` (B3). beam: `{move, {atom, base}, {x, 0}}.` (B5) and param clobber in `'scale_$0'` — re-ran: `'scale_$0'(15)` = `4`, `'scale_$1'(15)` = `9`, `'scale_$0'(100)` = `4` (B1). wasm: `global.get $base` → wasmtime `unknown global: failed to find name $base --> main.wat:8:16` (B6) + missing result (B2). Test-name mismatch: `base` is passed in the *runtime* position (`scale(2, base)`), the comptime args are literals `2`/`3`. `ct_0: val base = comptime 10 + 5 → 15` is correct. | Expected `30, 45, 200` (JS verified). Actual: erlang compile error, beam `4, 9, 4`, wasm invalid. | Fix B1/B3/B5/B6; use `scale(base, 2)` to actually specialize on the comptime val; add prints. |
| comptime_specialization_constrained_type_meta_kind_specializes_per_value | wasm | wrong-output | confirmed | `(func $coerce_$0 (param $x i32)\n    local.get $x\n    return\n  )` — no `(result i32)`; wasmtime: `Invalid input WebAssembly code at offset 88: type mismatch` (B2). JS/erlang/beam correct (re-ran on beam: `'coerce_$0'(10)` = `10`, `'coerce_$1'(42)` = `42`). No prints (weak). | Expected valid module. Actual invalid. | Fix B2 (`transform.zig:272` should carry `fn_decl.returnType`). |
| comptime_specialization_simple_function_body_without_loop | wasm | wrong-output | confirmed | `(func $execute_$0 (param $input i32)` … `i32.add\n    return` without result (B2) → wasmtime type mismatch (offset 88). Other backends correct (beam re-ran: `'execute_$0'(10)` = `10`, `'execute_$1'(42)` = `42`). No prints (weak). | Valid module expected. | Fix B2. |
| comptime_loop_unrolling_single_if_condition_resolved_per_element | beam, wasm (+erlang minor) | wrong-output | confirmed | beam `'execute_$0'`: `{move, {integer, 0}, {x, 0}}.` (`var output = 0`) overwrites `Input`, then `{gc_bif, '*', … [{x, 0}, {integer, 2}] …}` → re-ran: `'execute_$0'(10)` = `0`, `'execute_$1'(42)` = `0` (B1). wasm: missing result (B2) → invalid. erlang line 47: `COMMANDS = ["calc", "noop", "help"],` emits charlists (the ct value text pasted verbatim) while every other string in the backend is a binary (compare the partial test's line 62 `[<<"calc">>, <<"noop">>, <<"help">>]`); harmless here only because unused. `ct_0: val COMMANDS = comptime ["calc", "noop", "help"] → ["calc", "noop", "help"]` correct. | Expected `20, 84` (JS: `execute_$1` folds to `output = input * 2` for the matching "noop" arm). Actual beam `0, 0`; wasm invalid. | Fix B1/B2; render comptime string arrays as binaries in erlang; add prints. |
| comptime_loop_unrolling_nested_if_else_chain_fully_folded | beam, wasm | wrong-output | confirmed | beam `'execute_$1'`: `{move, {integer, 0}, {x, 0}}. {move, {x, 0}, {y, 0}}. {move, {x, 0}, {y, 0}}. {move, {y, 0}, {x, 0}}.` → re-ran `'execute_$0'(10)` = `0`, `'execute_$1'(42)` = `0`. wasm missing result (B2). JS/erlang correct (`execute_$1` folds to `output = input`). | Expected `20, 42`. Actual beam `0, 0`; wasm invalid. | Fix B1/B2; add prints. |
| comptime_loop_unrolling_case_expression_folded_inside_unrolled_loop | beam, wasm | wrong-output | confirmed | Generated code identical to the nested-if test on every backend — re-diffed: the only difference in any file is the SOURCE block (`case cmd { … }` vs the if/else chain). Re-ran beam: `0, 0`; wasm missing result. | Expected `20, 42`. | Fix B1/B2; add prints. |
| comptime_partial_runtime_array_loop_preserved_comptime_param_specialized | erlang (known), beam, wasm | wrong-output | confirmed | erlang (known): `end, Output, COMMANDS),` (lines 43 and 58) with `COMMANDS` bound only in `'_botopink_main'` (line 62) → erlc exit 1: `main.erl:21:18: variable 'COMMANDS' is unbound` (and `:36:18`) (B3, root `erlang.zig:762-776`). beam: `{move, {atom, 'COMMANDS'}, {x, 0}}` (lines 56, 76; B5), `{call_ext, 2, {extfunc, lists, foreach, 2}}` instead of a fold, closure body `%% assign to unknown variable: output` (unsupported, `beam_asm.zig:1547`), `{move, {atom, slug}, {x, 0}}`; re-ran: `CRASH error:function_clause [{lists,foreach_1,[#Fun<…>,'COMMANDS']…`. wasm: `i32.const 0 ;; loop over non-range` + `drop` (lines 45 and 57; `wat.zig:2543`) — loop silently dropped — plus missing result. | Expected `20, 84` (JS verified). Actual erlang compile error, beam crash, wasm loop removed + invalid. | Fix B3/B5; beam: lower mutated-var loops as `lists:foldl` like erlang; wasm: implement array loops or fail loudly. |
| comptime_block_with_break | all 4 | wrong-output | **corrected** (fix was insufficient) | All 4 snapshots show an empty code block and no RUN LOG/typedef, e.g. node: ```` ```javascript\n``` ````. Cause re-confirmed with the current binary — checking this source prints `┌─ :2:5 │ val x = 10; ^^^^^^^ 'binding' is a runtime identifier`: `comptime/error.zig:384` `validateComptimeExpr` has no arm for the `val x = 10;` statement and falls to `else => return ComptimeError{ .ident = @tagName(expr) … }` (`:431`), so a validation error is produced; `commonJS.zig:54-63` emits `js = ""` and `assertJsSingle` never checks `comptime_err` (H2). | Expected `const result = 20;` with `ct_0 … → 20` (and equivalents). Actual: a silent validation error snapshotted as success. | **Corrected fix:** allowing local bindings is not enough — `error.zig:427-428` then rejects `x` in `break x * 2` (every identifier is treated as runtime). The validator needs a comptime scope. Independently, make `assertJs` fail on `comptime_err`. |
| template_end_to_end_bounded_html_expansion | erlang, wasm, beam | known | confirmed | erlang: `main() ->\n    io:format("~p~n", [Page]).` + `Page = ((<<"\n<p>">> + Name) + <<"</p>\n">>),` inside `'_botopink_main'` → erlc exit 1, `main.erl:7:24: variable 'Page' is unbound` (B3) and B4. beam: `{move, {atom, page}, {x, 0}}.` → re-ran the assembled module: prints `page` (B5), and that RUN LOG is only a cache hit (`a020387fa133…`, H3). wasm: `global.get $page` → `unknown global --> main.wat:6:16` (B6) + `__print_i32` on a string; RUN LOG empty (H5). JS correct (`\n<p>world</p>\n`; `"""` preserves newlines by lexer design, `lexer.zig:372-377`). This slug has no `COMPTIME ERLANG` section — the identity template is folded without an erl round-trip. | Expected the `<p>world</p>` block on every backend. | Fix B3/B4/B5/B6/H3/H5. |
| template_end_to_end_generic_expr_via_code_builtin | wasm | known | confirmed | Code is correct on all 4 backends; the wasm module is valid and `wasmtime run` prints `8081` (re-run), but the RUN LOG is empty because of H5. beam RUN LOG `8081` exists only via cache hit `45c2d1e0e6d9…` dated 2026-06-27 01:13 (H3); erlang `8081` likewise (`b98514e560c5…`). | Expected wasm RUN LOG `8081`. | Restore executeWat; fix H3. |
| template_end_to_end_holed_html_via_parts_runs | erlang, beam, wasm | known | confirmed (sharpened by COMPTIME REPLY) | The new `COMPTIME REPLY -- template html` section shows what the template returned: `{"source": "\"\" + \"<p>\" + __bp_hole_q_0 + \"</p>\"", "kind": "code"}` — i.e. the `<<"">>` seed in `Page = (((<<"">> + <<"<p>">>) + Name) + <<"</p>">>),` comes from the template's `var acc = "\"\""`, not from codegen. erlang: that binding sits in `'_botopink_main'` while `io:format("~p~n", [Page])` is in `main()` (B3+B4; erlc: `main.erl:7:24: variable 'Page' is unbound`); beam `{move, {atom, page}, {x, 0}}.` → re-ran: prints `page` (B5; RUN LOG from the June-27 cache, H3); wasm `global.get $page` undefined (B6). JS `((("" + "<p>") + name) + "</p>")` → `<p>world</p>` correct (re-run). | — | as above |
| template_end_to_end_line_string_template_with_hole | erlang, beam, wasm | known | confirmed | Same three root causes (`Page = ((<<"<div>\n  <p>">> + Name) + <<"</p>\n</div>">>),`; erlc `variable 'Page' is unbound` at 7:24; beam prints `page`, cache-only; wasm `global.get $page` at main.wat:6:16). JS `<div>\n  <p>world</p>\n</div>` correct (re-run). | — | as above |
| template_end_to_end_cross_module_html_mirrors_the_canonical_example | node typedef + erlang/beam/wasm (known) | wrong-output | confirmed | node `main.d.ts` is exactly `import { html } from "view";` while `view.d.ts` is blank (template fns are dropped) → dangling import in the generated typedef. erlang/beam/wasm: same known root causes (`main.erl:9:24: variable 'Page' is unbound`; beam prints `page`, cache key `fbb40ac601cb…`; wasm `unknown global $page` — `view.wat` compiles, `main.wat` does not). JS RUN LOG `<div>\n  <p>world</p>\n  <Page1/>\n</div>` correct (re-run). | Expected main.d.ts without the import of a template-only symbol. | Drop imports of template fns from `.d.ts` (the `dts_skips_templates` tests should cover this). |
| template_end_to_end_lookup_ref_splices_a_caller_scope_reference | all 4 | wrong-output | **corrected** (second root cause) | All 4 files are 0 bytes, truncated in commit `e699be9` ("add comptime type-manipulation functions mergeRecords/partial/omit/pick"). That commit added an inference-time builtin intercept on the bare callee name `pick` (`comptime/infer.zig:4047-4054` name filter, dispatch `:4066-4068`, called unconditionally at `:6899` before user bindings), which shadows the test's user fn `pick` → typeError → H1 empty output. Reproduced at HEAD with the current binary: `error: pick expects a type and field names at main:9:9`. The same commit emptied the two `wat.zig` tests that also define `fn pick` (`optional_fn_return_null_path`, `optional_fn_return_present_path_with_optional_chaining`). Previous node snapshot (`git show e699be9^:…`) had `const s = greeting;` and RUN LOG `ola mundo`. **New:** renaming the fn to `pick2` does *not* restore it — the template now fails in the erl host with `the template module did not compile: … {undefined_function,{ref,1}}`, i.e. `b.ref()` has no host implementation at HEAD. | Expected JS `const s = greeting;` RUN LOG `ola mundo` (erlang/beam had their own known val issues). Actual: regression hidden by an emptied snapshot, now compounded by a missing `ref/1` host fn. | Only intercept `pick/omit/partial/mergeRecords` when no user binding of that name exists (or namespace them); **and** restore `ref/1` in the template host (`erlang.zig` comptime helper forms) before regenerating. |
| template_end_to_end_yaml_model_computes_a_typed_record | erlang, wasm (known), beam | known | confirmed (sharpened by COMPTIME REPLY) | The new `COMPTIME REPLY -- template conf` shows `{"value": {"port": 8004, "debug": true}, "kind": "value"}` — the fold `8000 + len("yaml") = 8004` is correct and returned as a *value*, not code. erlang: `io:format("~p~n", [(maps:get(port, Cfg) + 1)]).` with `Cfg = #{port => 8004, debug => true},` in `'_botopink_main'` → erlc exit 1: `main.erl:6:40: variable 'Cfg' is unbound` (B3). beam: `{move, {atom, cfg}, {x, 0}}.` → re-ran: `CRASH error:badarith [{erlang,'+',[cfg,1]…` (B5; RUN LOG empty). wasm: `i32.const 0 ;; field access .port (unknown receiver type)` (line 69) → `wasmtime run` prints `1`, not 8005. JS RUN LOG `8005`. | Expected `8005` everywhere. | Fix B3/B5; wasm record field access. |
| builtin_result_namespace_qualified_call_lowers_inline | beam, wasm (+erlang H4) | wrong-output | confirmed | beam `.S` is rejected by erlc (re-run, exit 1): `main:1: function main/0+11: … Instruction: {test_heap,{alloc,[{words,0},{floats,0},{funs,1}]},3} Error: {{x,1},not_live}` and `function parse/1+9: … {test_heap,3,3} … {{x,1},not_live}`; the snapshot's empty RUN LOG hides it. wasm: `(local $_res0 i32)` inside `(then …)` → wasmtime `unknown operator or unexpected token --> main.wat:12:6`. erlang output correct (`42`) but erlc warns `main.erl:16:29: variable 'R' shadowed in 'fun'`, so the RUN LOG survives only via the June-27 cache (H4). JS correct (`42`). | Expected RUN LOG `42` on beam/wasm. Actual: assembly rejected / invalid WAT. | beam: correct live counts for `test_heap`; wasm: hoist locals; erlang: avoid shadowing `R` in the inline fun. |
| std_package_order_enum_module_with_type_export | erlang, beam, node typedef, wasm | wrong-output | confirmed (typedef root cause found) | erlang `describe/1`: `S = case O of\n        Lt ->\n            <<"less">>;\n        Gt ->` — imported enum variants lowered as *variables*; erlc (re-run): `main.erl:8:9: Warning: variable 'Lt' is unused` + `main.erl:10:9: Warning: this clause cannot match because a previous clause at line 8 always matches` → RUN LOG `-1\n<<"less">>` (reproduced by running it). beam `describe/1` and `order:toInt/1`/`reverse/1`: arms are emitted with no test/`select_val` (`{move, {literal, <<"less">>}, {x, 0}}. {jump, {f, 10}}.` then unreachable arms) → always first arm; same `-1\n<<"less">>` (cache-only per H3). node JS correct: `-1\ngreater`. node typedef `std/order.d.ts`: `export declare function toInt(o: ): i32;` / `reverse(o: ): Order;` — the empty param type comes from `codegen/typescript.zig:326-330`, which prints `p.typeName` (empty when the param carries a `typeRef`), and `i32` leaks because `emitTypeRef` (`:392-396`) writes named types verbatim; `Order` is declared in `.d.ts` but never `exports.Order`-ed from `order.js`. wasm: `(local $__case_0 i32)` mid-body → invalid (`std/order.wat:23:6`, `main.wat:9:6`), case collapsed to the first arm. Also erlang/beam print `<<"less">>` (`~p`) vs JS `less` — cross-backend `@print` format divergence. | `describe(reverse(lt()))` = `describe(Gt)` = `"greater"`. Actual erlang/beam `"less"`. | Atomize imported enum variant patterns (erlang), emit `select_val` (beam), render param types from `typeRef` and map `i32`→`number` in the typedef, hoist wasm locals. |
| executeJavaScript cleans up scratch dir on success (runtime_scratch.zig:25) | — | weak | confirmed | Calls `runtime.executeJavaScript(…, "console.log(42);", &.{}, io)` with empty `aux`; that path (`runtime.zig:193-198`) runs `node -e` and never creates a scratch dir (and may short-circuit on a cache hit), so `before == after` holds trivially. | Should exercise the aux path (`aux.len > 0`) that actually calls `makeScratchDir` + `deleteTree`. | Pass a non-empty `aux`. |
| executeJavaScript leaks under .botopinkbuild/tmp/, never as a root sibling (runtime_scratch.zig:39) | — | weak | confirmed | Same: empty `aux` → no scratch dir created, so asserting no `.tmp-exec-*` sibling is vacuous. Title says "leaks under" but nothing is created. | Use the aux path with a throwing script. | Pass non-empty `aux`; rename. |
| .d.ts: free fn returning @Expr<T> is skipped (dts_skips_templates.zig:36) | node typedef | weak | confirmed | Only negative checks (`Expr<`/`ExprCustom<` absent, `dts_skips_templates.zig:26-33`); does not assert that `plain` IS emitted, nor that no import of a template symbol leaks (the cross-module snapshot shows `import { html } from "view";` dangling). | Positive assertion for `export declare function plain(x: …)` expected. | Add positive needles + an importer module case. |
| .d.ts: interface method returning @Expr<T> is skipped (dts_skips_templates.zig:45) | node typedef | weak | confirmed | Same: no assertion that `Tpl` / `name(): string` survive; a typedef that drops the whole interface (or `typedef == null`, `orelse ""` at `:25`) also passes. | — | Add positive needles. |

---

## 2. Known items — root causes confirmed (re-verified)

- **wasm RUN LOG always empty**: `runtime.zig:393-401` `executeWat` discards its input and returns
  `""` (commit `caa7377d`). For this batch only `template_end_to_end_generic_expr_via_code_builtin`
  (prints `8081`), `template_end_to_end_yaml_model_computes_a_typed_record` (valid but prints `1`
  instead of `8005`), `comptime_basic_comptime_val_and_plain_function_coexist` and
  `comptime_val_runtime_val_with_string_literal` produce wasmtime-valid modules; all others fail
  validation (B2/B6/mid-body locals) — re-confirmed with `wasmtime compile` on every file.
- **erlang `template_end_to_end_*`**: `erlang.zig:762-776` binds runtime module-level vals as locals
  of `'_botopink_main'/0`, then `main/0` reads them → erlc "variable 'Page'/'Cfg' is unbound" →
  compile fails → `executeErlang` returns `""`. Independently the concat is `(<<…>> + Name)` (B4)
  which would badarith, and `~p` would print `<<"…">>` not raw text.
- **erlang `comptime_partial_runtime_array_loop…`**: same B3 (`COMMANDS` free in `'execute_$0'/1`).
- **beam `template_end_to_end_holed_html_via_parts_runs` prints `page`**: `{move, {atom, page}, {x, 0}}`
  (B5); beam never materializes module-level vals. The `page` RUN LOG (identical in
  bounded/line_string/cross_module) is reproducible only from runtime-cache entries dated 2026-06-27
  because of H3 — the bounded/line-string/holed slugs even share one cache key (`a020387fa133…`),
  since their `.S` bodies are identical.
- **wasm `template_end_to_end_*` empty**: H5 + `global.get $page` on a never-declared global (B6) +
  `__print_i32` used for strings.

---

## 3. Orphans / missing snapshots (all codegen) — restated for the flat tree

Method (`rev-builtins-ctmisc/orphans.py`): for every `test "…" {` in
`modules/compiler-core/src/codegen/tests/*.zig`, take the body up to the next test, detect
`h.assertJs|assertJsSingle|assertJsError|assertJsTestMode(std.testing.allocator, @src()`. Slug =
`helpers.slugFromSrc`: strip `test.`, take the text after the first `": "` (whole name if none),
ASCII-alnum lowercased, runs of other chars → single `_`, trailing `_` dropped. Expected files:
assertJs/assertJsSingle → `codegen/{commonJS,erlang,beam,wasm}/<slug>.snap.md`; assertJsTestMode →
`codegen/commonJS` + `codegen/erlang` only (`helpers.zig:257`, `configs[0..2]`); assertJsError →
`codegen/errors/{commonJS,erlang,beam,wasm}/<slug>.snap.md`.

Results at HEAD (counts unchanged by the flattening — only the directories moved):
- 296 `test` blocks; 280 produce snapshots (16 are needle/unit tests: 272 `assertJsSingle`, 6
  `assertJs`, 1 `assertJsTestMode`, 1 `assertJsError`). No duplicate slugs, no test with two snapshot
  asserts, no `SkipZigTest`.
- `codegen/commonJS` 279 files = 279 expected; `codegen/erlang` 279 = 279; `codegen/beam` 278 = 278;
  `codegen/wasm` 278 = 278; `codegen/errors/<target>` 1 each = 1 each. No non-`.snap.md` files (no
  stray `.new`).
- **Orphans: 0. Missing: 0.**
- The 3 tests in `runtime_scratch.zig`, 3 in `comptime_module.zig` and 2 in `dts_skips_templates.zig`
  produce no snapshots by design.

**But 29 slugs have 0-byte snapshots on all 4 backends (116 files) — vacuous passes via H1:**
`builtin_print_in_if_branch`, `builtin_print_in_loop`,
`comptime_folding_block_with_break_value_inlines_result`,
`comptime_folding_float_multiplication_folds_to_literal`,
`comptime_folding_integer_addition_folds_to_literal`,
`comptime_folding_multiplication_binds_tighter_than_addition`,
`comptime_val_comptime_val_folds_arithmetic_to_literal`, `fn_private_function_with_return`,
`fn_pub_exported_function`, `fn_with_local_binding`, `interface_literal_basic`,
`interface_literal_with_fields`, `lambda_standalone_with_params`, `loop_even_numbers_with_break`,
`loop_filter_with_conditional_break`, `loop_map_with_break_add_tax`, `loop_map_with_break_simple`,
`narrow_and_condition_field_access`, `narrow_assert_pattern_with_print`,
`narrow_case_option_some_none`, `narrow_early_return_with_print`, `narrow_type_guard_if_codegen`,
`optional_fn_return_null_path`, `optional_fn_return_present_path_with_optional_chaining`,
`string_slice_without_end_arg_slices_to_source_length`,
`template_end_to_end_lookup_ref_splices_a_caller_scope_reference`, `throw_inside_case_arm`,
`throw_inside_loop_body`, `val_binary_expression`.
(Spot checks re-run with the current binary: top-level statements do not parse — `@print(v1);` at
module level, `if x > 0 {`, `loop {` — and `val X = record { k: "v" };` does not parse either, which
is what empties the two `interface_literal_*` slugs; three `pick` fixtures were emptied by `e699be9`.)
Commit `80e27667`'s message claims "Delete 110 orphaned empty snapshot files" — these 116 are not
orphans; they are live tests whose output is empty.

---

## 4. `test_runner` asymmetry (restated for the flat tree)

- Produced by `src/codegen/tests/builtins.zig:291` `test "codegen: test runner"` → slug `test_runner`
  (text after `": "`). It calls `h.assertJsTestMode`, which iterates `configs[0..2]` (commonJS +
  erlang only, `helpers.zig:257`). The missing `codegen/beam/test_runner.snap.md` and
  `codegen/wasm/test_runner.snap.md` are therefore **intended, not orphans**.
- Weaknesses (all re-verified):
  - `S/erlang/test_runner` RUN LOG is empty because the test-mode module has no `'_botopink_main'`
    (`-export([main/1]).`; `grep -c _botopink_main` = 0), so `executeErlang` early-returns at
    `runtime.zig:275`. Running `main:main([])` by hand prints the full envelope ending in
    `2 passed, 0 failed`. The erlang runner body (`'__bp_run_tests'/1`) is never executed by the
    snapshot.
  - `S/commonJS/test_runner` RUN LOG pins timing: `  duration 0ms` twice — it would break if a test
    body took ≥ 0.5 ms on a cold node; only stable thanks to the output cache (H7): recomputed key
    `7c83e68fac1b…`, mtime 2026-06-27 01:13, payload identical to the snapshot's RUN LOG.
  - The node RUN LOG embeds nested ```` ``` ```` fences and `----- RUN LOG -----` inside the outer
    ```` ```logs ```` block, which breaks Markdown fencing of the snapshot (cosmetic, but confuses
    section parsers).
  - beam/wasm test mode is untested by design (no documented reason in the test).

---

## 5. `ok` slugs / tests (re-verified)

- `comptime_val_runtime_val_with_string_literal` — correct on all 4 (wasm
  `(data (i32.const 256) "\0d\00\00\00Hello, World!")`, heap 276 = align4(256+4+13), module compiles);
  empty RUN LOG is correct (no main). Note: it lives in the "comptime val" group but has no comptime.
  Secondary: exporting `greeting/0` in the beam module trips the known missing-`allocate` family
  (`{deallocate,0}` / `{allocated,none}`), same as the array/tuple fixtures.
- `comptime_basic_comptime_val_and_plain_function_coexist` — `ct_0: val x = comptime 1 + 2 → 3`
  correct (new format); JS/erlang/beam/wasm valid (wasmtime compiles and runs, beam assembles), empty
  RUN LOG correct (no print).
- `makeScratchDir lands under .botopinkbuild/tmp/<hex>/` (runtime_scratch.zig:9).
- `comptime module: host enum member lowers to an atom, method call to a host fn`
  (comptime_module.zig:27) — static review only (not executed; `zig build` forbidden); needles
  consistent with the `erlang.zig` comptime helper forms.
- `comptime module: \`+\` and \`.len\` dispatch at runtime, rebinding versions the variable`
  (comptime_module.zig:52) — static review only; `'__bp_add'`/`'__bp_len'`/`'__bp_json'`/`'__bp_text'`
  clauses exist in `erlang.zig:384-470` in the asserted shape.
- `comptime module: forEach with a mutated var fuses into a fold` (comptime_module.zig:72) — static
  review only.

## 6. COMPTIME VALUES audit (every `ct_N` in the batch, new `ct_N: <decl> → literal` format)

| slug | ct line | hand-computed | result |
|---|---|---|---|
| comptime_basic_comptime_val_and_plain_function_coexist | `ct_0: val x = comptime 1 + 2 → 3` | 1 + 2 = 3 | correct |
| comptime_specialization_comptime_val_used_as_specialization_argument | `ct_0: val base = comptime 10 + 5 → 15` | 10 + 5 = 15 | correct |
| comptime_loop_unrolling_* (3 tests) | `ct_0: val COMMANDS = comptime ["calc", "noop", "help"] → ["calc", "noop", "help"]` | array literal | correct |
| comptime_folding_* (4), comptime_val_comptime_val_folds_arithmetic_to_literal | none (empty file) | 2, 24, 6.28, 14, 30 | missing (H1) |
| comptime_block_with_break | none | 20 | missing (validation error, H2) |
| template_end_to_end_yaml_model_computes_a_typed_record | no `COMPTIME VALUES`; the `COMPTIME REPLY` shows `{"value": {"port": 8004, "debug": true}, "kind": "value"}` | 8000 + len("yaml") = 8004 | correct |
| template_end_to_end_holed_html_via_parts_runs, …cross_module… | no `COMPTIME VALUES`; `COMPTIME REPLY` `{"source": "\"\" + \"<p>\" + __bp_hole_q_0 + \"</p>\"", "kind": "code"}` | template returns code, not a value | correct (explains the `<<"">>` seed) |
