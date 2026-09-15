# Spec 03 — Codegen Hardening

**Version:** 1.0.1-beta
**Priority:** medium
**Depends on:** spec 01 step 1 (leak-free `executeErlang`; same file)

---

## Objective

Every codegen snapshot either records real runtime output in its RUN LOG or is an explicit,
documented skip; the wrong RUN LOGs accepted as baseline in 1.0.0-beta are fixed; the
comptime `erl` runtime has direct regression tests.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`.

## Current state

- Snapshot tests run generated code per backend through `src/codegen/runtime.zig`
  (`executeJavaScript` → `node`, `executeErlang` / `executeBeamAsm` → `erlc` + `erl`), all
  behind `runWithTimeout`.
- `executeWat` is a stub returning an empty RUN LOG: WAT snapshots are generated but never
  executed. Its doc comment still describes the removed embedded `wasm3` interpreter.
- `src/comptime/runtime/persistent_erl.zig` has no dedicated tests; it is exercised only
  indirectly (`src/comptime/tests/eval_pipeline.zig`, 2 tests, plus decorator/template tests).
- Measured on the working tree (`scripts/snap_audit.sh --mode=runlog` lists them):

  | RUN LOG | node | erlang | beam | wasm |
  |---|---|---|---|---|
  | empty despite `@print` | 14 | 33 | 26 | 95 (stub `executeWat`) |
  | contains `undefined` | 9 | 1 | 4 | — |

---

## Step 1 — Backend runtime gaps

Re-audit every snapshot in the table above and fix it or mark it as an intentional skip
(documented in the test). Known causes:

| Backend | File | Gap |
|---|---|---|
| commonJS | `src/codegen/commonJS.zig` | `if` without `else` as expression; string/array method mapping; `try`/`catch` propagation |
| erlang | `src/codegen/erlang.zig` | top-level `val` bound in `'_botopink_main'/0` but read inside `main/0` (unbound — `Cfg`/`Page` in `template_end_to_end_*`, e.g. `template_end_to_end_yaml_model…`); a specialized fn reading a module-level `val` (`COMMANDS` in `comptime_partial_runtime_array_loop…`); pipeline `\|>` argument threading; instance methods from external modules; a template expansion's string concatenation lowers to `+` on binaries (`<<"">> + <<"<p>">>`, `template_end_to_end_*_html_*`) instead of `<<A/binary, B/binary>>` |
| beam | `src/codegen/beam_asm.zig` | `try`/`catch` on `@Result`; anonymous record literals; string `.len` in arithmetic; 0-arity `pub val` functions `deallocate` without `allocate`; an imported `pub val` lowers to the atom (`{atom, 'HOST'}`) instead of calling `config:'HOST'()` (`import_multi_module_pub_val_import`, `val_pub_val_declaration`); a module-level `val` read from `main` is the atom `page` (`template_end_to_end_holed_html_via_parts_runs`) |
| wasm | `src/codegen/wat.zig` | `external` host functions; templates and iterators; `case` on literals (`br_table`); instance methods / array builtins; `template_end_to_end_*` RUN LOG empty (see step 2) |

**Wrong beam RUN LOGs accepted as baseline** — fix and re-accept:

| Snapshot | Prints | Want | Cause |
|---|---|---|---|
| `array_zip_via_external_node_template` | `[<<"a">>,<<"b">>,<<"c">>]` | the zipped pairs | zip lowering |
| `external_a3_result_template_owned_declare_fn` | `-1` | `42` | `@Result` template / `unwrapOr` path |
| `stdlib_associated_fn_namespace_injected` | `<<"one">>` and `10` | `1` and `inc(10)` | `Pair.first` / `compose` |
| `std_package_order_enum_module_with_type_export` | `<<"less">>` | `<<"greater">>` | `describe` has no `select_val` on the enum atom; every arm falls through |

**Acceptance:**
- [ ] No unexplained empty or `undefined` RUN LOG; each skip documented in its test
- [ ] The 4 beam baseline snapshots print the expected values
- [ ] `template_end_to_end_*` run on erlang and beam with the expected output

## Step 2 — WAT execution

Decide between running WAT through `wasmtime` in `executeWat` (same `runWithTimeout`
wrapper; CI already installs `wasmtime`) or accepting empty WAT RUN LOGs as the baseline.
Rewrite the stale `executeWat` doc comment either way.

**Acceptance:**
- [ ] Decision recorded in `src/codegen/AGENTS.md`
- [ ] wasm RUN LOGs either populated or explicitly documented as not executed

## Step 3 — Missing codegen coverage

Add snapshot tests (all backends, documented skips) for: optional/null, cross-module imports,
interface/implement, records/enums, generics, lambdas/operators/annotations
(`src/codegen/tests/{values,features,aggregates}.zig`), and template/`@Expr` holes with runtime
values and comptime eval results (`src/codegen/tests/comptime.zig`).

## Step 4 — `persistent_erl` regression tests

- Spawn + round-trip of a trivial module.
- Respawn after the `erl` child is killed mid-session.
- `main/0` exceeding the eval timeout → `runtime_error`, server keeps serving.
- Frame edge cases: empty payload, large payload, non-ASCII bytes.
- Compile/runtime error text reaches the caller (`evalDetailed`) and the compiler diagnostic.
- No orphan `beam.smp` after the tests.

## Step 5 — Final sweep

`zig build test && zig build test-libs && zig build test-backends` green.
