# Measuring a backend, and why erlang is not the oracle

> Kept from the deep dives of the landed backend fronts (`1.0.4-beta/02-erlang/causes.md`, and its
> beam, wasm and commonJS twins), which were carried from 1.0.2-beta. Counts are from the 1.0.2-beta
> commit and are history; the method and the rule still hold.

## How a backend's output is measured

A RUN LOG only says what the harness recorded. Since the backend fronts landed, the harness records
the failures that used to look like an empty log — `COMPILE ERROR (erlc):`,
`COMPILE ERROR (node --check):`, `RUNTIME TRAP (wasmtime):` — and `executeWat` runs. To check a
value outside the suite, extract each backend's emitted code from the snapshot and run it:

| Backend | How |
|---|---|
| commonJS | `node --check <module>.js` on every emitted module, then `node main.js` |
| erlang | `erlc -o . <mod>.erl` per module, then `erl -noshell -eval "main:'_botopink_main'()"` inside a `try … catch C:E:S -> …`, so the crash class and stack are visible |
| beam | `erlc +from_asm` per module, same runner; `scripts/beam_export_audit.sh` assembles every module with all functions exported |
| wasm | `wasmtime run <module>.wat`, stdout and exit status |

<a id="representation-mapping"></a>

## The representation mapping

The 1.0.2-beta measurement compared backends under a mapping that undid erlang's `~p`
(`<<"x">>` → `x`, `<<>>` → empty, `1.0` → `1`, `[ 2, 4 ]` → `[2,4]`). Decision 1 (`__bp_print/1`,
implemented on all four backends) removed it for strings. What is left is **numeric text**: the
erlang family prints `5.0` where commonJS prints `5`, intended and written in
`src/codegen/AGENTS.md`. Compare floats under that one rule and everything else byte for byte.

## Erlang is not the oracle

The 1.0.1-beta measurement assumed erlang was the reference backend. Running all four found seven
fixtures where **erlang** was the wrong one, four of them silently:

| Fixture | erlang printed | who was right | Closed by |
|---|---|---|---|
| `throw_inside_case_arm` | `true true` | beam (`true false`) | open — E8, [`../06-checker/`](../06-checker/README.md#step-0--rows-added-in-104-beta) N10 |
| `std_package_order_enum_module_with_type_export` | `-1 less` | commonJS (`-1 greater`) | erlang E6 |
| `narrow_type_guard_if_codegen` | `false` | commonJS (`true`) | erlang E7 |
| `iterator_fromlist_yields_array_items` | `<<>>` | commonJS (`1,2,3`) | the erlang and beam landings |
| `comptime_block_with_break` | `COMPILE ERROR` | commonJS (`20`) | erlang E5 |
| `endswith_lowers_via_external_beam_single_line_body` | crash | commonJS (`true`) | 1.0.2-beta std-surface |
| `destructure_record_val_binding` / `destructure_record_parameter_in_fn` | crash | commonJS, beam, wasm | erlang E1 |

> **A cross-backend assertion is written against the *program's* expected output, not against
> whatever one backend printed.** The same holds after the fix: 26 of the wasm RUN LOGs recorded by
> the wasm landing are right where another backend is wrong.
