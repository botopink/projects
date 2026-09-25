# Blast radius — what moves when the checker becomes strict

Every number here was measured against `botopink-lang` `c2dd780` on 2026-09-18, from the working
tree of a scratch worktree of that commit. The command is beside the number so it can be repeated.

---

## The snapshot families this front owns

```
find modules/compiler-core/snapshots/comptime -type f | wc -l
```

| Directory | Files | What a change here moves |
|---|---|---|
| `snapshots/comptime/node/` | 337 | typed-AST dumps + 135 error snapshots |
| `snapshots/comptime/erlang/` | 337 | the same, erlang target |
| `snapshots/comptime/beam/` | 202 | typed-AST dumps only |
| `snapshots/comptime/wasm/` | 202 | typed-AST dumps only |
| `snapshots/comptime/templates/` | 1 | — |
| **total** | **1079** | |

## The error family — step 9's whole subject

```
find modules/compiler-core/snapshots/comptime -path '*errors*' -type f | wc -l     → 270
```

| Measurement | Count | How |
|---|---|---|
| error snapshots | **270** (135 `node/errors` + 135 `erlang/errors`) | the command above |
| of those, the box reads `┌─ :L:C` — **no file name** (1.0.4 N9) | **226** | `re.search(r'┌─ :\d+:\d+', text)` over the set |
| of those, **no `┌─` box at all** (C13's unlocated raisers) | **44** = 22 slugs × 2 directories | `'┌─' not in text` |

The 22 box-less slugs, so the sweep can be checked off by name:

| Family | Slugs |
|---|---|
| interface / implement | `implement_missing_a_required_interface_method`, `implement_declares_method_not_in_interface`, `implement_method_not_declared_in_the_interface`, `implement_qualified_prefix_is_not_a_declared_interface`, `duplicate_method_across_interfaces_without_qualification`, `extend_without_an_interface_requires_implement`, `activation_of_non_extension_symbol`, `redundant_local_activation_star_is_for_imports` |
| effect wrappers | `1g_rg3_future_rejects_t_is_required`, `1g_rg3_iterator_rejects_t_is_required`, `1g_rg3_result_i32_rejects_e_is_required_no_default`, `rg3_future_rejects_t_is_required`, `rg3_iterator_rejects_t_is_required`, `rg3_result_i32_rejects_e_is_required_no_default` |
| optionals | `option_t_is_rejected_the_optional_type_is_t`, `optional_t_is_rejected_the_optional_type_is_t` |
| externals | `external_builtin_typechecks_args`, `external_wrong_arity` |
| packages | `std_package_unknown_module`, `two_pub_default_fn_in_one_package`, `two_pub_default_mod_in_one_package` |
| unify | `type_mismatch_i32_bool` |

The last one is the tell: a plain `i32`/`bool` mismatch raised straight out of `comptime/unify.zig`
carries no location at all.

## The raiser sites

```
grep -c 'TypeError'        modules/compiler-core/src/comptime/unify.zig   → 27
grep -c 'withLoc'          modules/compiler-core/src/comptime/unify.zig   → 0
grep -c 'TypeError.custom' modules/compiler-core/src/comptime/infer.zig   → 92
grep 'TypeError.custom' modules/compiler-core/src/comptime/infer.zig | grep -c withLoc → 9
```

| File | Raisers | Located today | To locate |
|---|---|---|---|
| `comptime/unify.zig` | 27 | **0** | all 27 — a location reaches `unify` only when the caller went through `unifyAt` |
| `comptime/infer.zig`, `TypeError.custom` | 92 | 9 | **83** |

`unify` never carries a location by construction. Two fixes are possible and they are not the same:
thread a `loc` through `unify`'s signature (touches every caller), or make every caller go through
`unifyAt` (touches the two bare arithmetic call sites and whatever else `grep -n 'unify(' infer.zig`
turns up). Decide in step 9 and record which; the second is smaller and was already half-done by C3
(`f6d8ce6`).

## The codegen directories this front can move — but does not own

A fixture that **newly fails to compile** takes its codegen snapshots with it, in all four
directories at once. It is all-or-nothing: a codegen snapshot carries no type rendering, so a fixture
that still compiles does not move a byte.

| Directory | Files | Owner |
|---|---|---|
| `snapshots/codegen/erlang/` | 315 | [`../02-erlang/`](../02-erlang/README.md) |
| `snapshots/codegen/beam/` | 314 | [`../03-beam/`](../03-beam/README.md) |
| `snapshots/codegen/commonJS/` | 315 | [`../04-js/`](../04-js/README.md) |
| `snapshots/codegen/wasm/` | 314 | [`../05-wasm/`](../05-wasm/README.md) |
| **total** | **1258** | |

**The rule for this front:** a fixture that a strictness step kills is *reported to the owning
backend front*, with the program and the diagnostic, and migrated to a program that says what it
meant — never deleted. That is what C9 did for the three fixtures it killed (`75a6906`), and it is
what turned a vacuous test into an assertion each time.

## Library exposure

`zig build test-libs` at `c2dd780`: **11 cells, 0 failed**, `scripts/known-red-libs.txt` empty.
`botopink check` is clean in `libs/std` and in all five sibling repositories.

That is the baseline a strictness step must not break. The rows with a **library** class — the ones
that can red a library — and what the 1.0.4 measurement said about each:

| Step | Class | Why |
|---|---|---|
| 1 `unknown` | few | `unknown` appears in no `.bp` outside `tests/language` |
| 2 unions | few | no `.bp` writes `A \| B` today |
| 3 `is` | few | `x is T` as an expression is new grammar; only `tests/language` uses it |
| 4 `case` arms | **library** | every library writes arrow arms (`pattern -> value;`); the decision-8 form is additive, but arm typing is not — an arm whose body was accepted as a `function` becomes a real unification |
| 5 exhaustiveness | **library** | a `case` that compiles today because a guarded arm counted stops compiling |
| 6 generics §1.1/§1.2 | **library** | **16** generic declarations in `libs/std` write a bare `Self`, plus the sibling libraries. Step 11 migrates `libs/std` and `examples`; the libraries are [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)'s |
| 7 defaults | unblocks | it only accepts more. `repository/jhonstart/src/element.bp` carried 24 `attrs: []` paddings, 22 of them pure arity padding |
| 8 R7 (decision 2) | **library** | a non-`unit` fn falling off its end is legal today |
| 9 diagnostics | many | 270 error snapshots |
| 11 sources | — | it *is* the migration |

Steps 4, 5, 6 and 8's R7 each need the same discipline C1/C8 used: land the walk **reporting**
first, read the list over `libs/std` plus the five siblings, then flip to a hard error in a second
commit. A library that reds gets a migration in the same landing, not a `known-red-libs.txt` line.
