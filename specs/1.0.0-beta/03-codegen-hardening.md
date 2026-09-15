# Spec 03 — Codegen Hardening

**Priority:** 🟡 medium
**Depends on:** Spec 01 for the template/`@Expr` items; everything else is independent.

---

## Objective

Every codegen snapshot either records real runtime output in its RUN LOG or is an
explicit, documented skip; the comptime `erl` runtime has direct regression tests.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`.

---

## Current state

- Snapshot tests run the generated code per backend through `src/codegen/runtime.zig`
  (`executeJavaScript` → `node`, `executeErlang` / `executeBeamAsm` → `erlc` + `erl`), all
  behind `runWithTimeout`.
- `executeWat` is a stub that returns an empty RUN LOG: WAT snapshots are generated but never
  executed. Its doc comment still mentions the removed `wasm3_host`.
- The comptime runtime (`src/comptime/runtime/persistent_erl.zig`) has no dedicated tests;
  it is only exercised indirectly (`src/comptime/tests/eval_pipeline.zig` has 2 tests).

---

## Steps

### Step 1 — Backend runtime gaps

Re-audit snapshots with an empty RUN LOG despite `@print`, or with `undefined` output, and fix
or mark each as an intentional skip. Known candidates:

| Backend | File | Gap |
|---|---|---|
| commonJS | `src/codegen/commonJS.zig` | `if` without `else` as expression; string/array method mapping; `try`/`catch` propagation |
| erlang | `src/codegen/erlang.zig` | top-level `val` bound in `'_botopink_main'/0` but read inside `main/0` (unbound — e.g. `template_end_to_end_yaml_model…`); a specialized fn reading a module-level `val` (`COMMANDS` in `comptime_partial_runtime_array_loop…`); pipeline `\|>` argument threading; instance methods from external modules; a template expansion's string concatenation lowers to `+` on binaries (`<<"">> + <<"<p>">>`, `template_end_to_end_*_html_*`) instead of `<<A/binary, B/binary>>` |
| beam | `src/codegen/beam_asm.zig` | `try`/`catch` on `@Result`; anonymous record literals; string `.len` in arithmetic. **Wrong RUN LOGs accepted as the current baseline** (step-1 F6): `array_zip_via_external_node_template` prints `[<<"a">>,<<"b">>,<<"c">>]` (want the zipped pairs); `external_a3_result_template_owned_declare_fn` prints `-1` (want `42` — the `@Result` template/`unwrapOr` path); `stdlib_associated_fn_namespace_injected` prints `<<"one">>` and `10` (want `1` for `Pair.first` and the composed `inc(10)`); `std_package_order_enum_module_with_type_export` prints `<<"less">>` (want `<<"greater">>` — `describe` has no `select_val` on the enum atom, every arm falls through). 0-arity `pub val` functions `deallocate` without `allocate`; an imported `pub val` lowers to the atom (`{atom, 'HOST'}`) instead of calling `config:'HOST'()` (`import_multi_module_pub_val_import`); a module-level `val` read from `main` is the atom `page` (`template_end_to_end_holed_html_via_parts_runs`) |
| wasm | `src/codegen/wat.zig` | `external` host functions; templates and iterators; `case` on literals (`br_table`); instance methods / array builtins |

Acceptance: no unexplained empty RUN LOG; each skip is documented in the test.

### Step 2 — WAT execution

Decide between running WAT through `wasmtime` in `executeWat` (same `runWithTimeout` wrapper)
or accepting empty WAT RUN LOGs as the baseline. Update the stale doc comment either way.

### Step 3 — Missing codegen coverage

Add snapshot tests (all backends, with documented skips) for: optional/null, cross-module
imports, interface/implement, records/enums, generics, lambdas/operators/annotations
(`src/codegen/tests/{values,features,aggregates}.zig`).

After Spec 01: template/`@Expr` holes with runtime values and comptime eval results
(`src/codegen/tests/comptime.zig`).

### Step 4 — `persistent_erl` regression tests

- Spawn + round-trip of a trivial module.
- Respawn after the `erl` child is killed mid-session.
- `main/0` exceeding the eval timeout → `runtime_error`, server keeps serving.
- Frame edge cases: empty payload, large payload, non-ASCII bytes.
- Compile/runtime error text reaches the caller (`evalDetailed`) and the compiler diagnostic.

### Step 5 — Final sweep

`zig build test && zig build test-libs && zig build test-backends` green.
