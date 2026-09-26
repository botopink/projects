# Migration cost

Measured / . Re-measure before quoting;
the commands are given so the numbers can be reproduced.

---

## 1. Snapshots

```
$ grep -rl '^-module(' modules/compiler-core/snapshots | wc -l
304
$ find modules/compiler-core/snapshots -name '*.snap.md' | wc -l
2519
$ find modules/compiler-core/snapshots/codegen/erlang -name '*.snap.md' | wc -l   # 313
$ find modules/compiler-core/snapshots/codegen/beam   -name '*.snap.md' | wc -l   # 312
```

Which atoms are actually recorded:

```
$ grep -rho '^-module([a-z_0-9]*)' modules/compiler-core/snapshots | sed 's/.*(//;s/)//' | sort | uniq -c | sort -rn
    303 main
      2 pond
      1 view
      1 order
      1 math
      1 http
      1 hostlib
      1 config
      1 b
      1 a
```

The BEAM `{module, X}` forms are the same distribution (302 `main`).

**This is the decisive number for the choice of scheme.** 303 of 313 erlang snapshots and 302 of
312 beam snapshots record a **single-segment** module path (`main`), which
[option A](./atom-options.md#option-a--the-path-joined-with-) leaves byte-identical. Only the nine
multi-module fixtures move:

```
codegen/erlang/import_multi_module_pub_val_import.snap.md
codegen/erlang/import_multi_module_pub_fn_import.snap.md
codegen/erlang/import_cross_module_record_construct_and_assoc_fn.snap.md
codegen/erlang/import_a_call_to_an_imported_fn_names_its_module.snap.md
codegen/erlang/dispatch_multi_module_extension_activated_via_star_import.snap.md
codegen/erlang/dispatch_multi_module_implement_on_an_imported_record.snap.md
codegen/erlang/std_package_order_enum_module_with_type_export.snap.md
codegen/erlang/template_end_to_end_cross_module_html_mirrors_the_canonical_example.snap.md
codegen/erlang/external_an_imported_host_backed_declare_fn_is_wrapped_by_its_owner.snap.md
```

plus their `codegen/beam/` twins — **≈ 20 files**, each changing its `-module` / `{module, …}` form
and its `call_ext` / `Mod:Fun` targets. `RUN LOG` blocks do not change: the atom appears in the
header and the call targets, not in the printed values.

Under [option P](./atom-options.md#option-p--the-maintainers-proposal-as-stated) or
[option C](./atom-options.md#option-c--the-proposal-minus--dotted-and-quoted), every `main` becomes
`'main'` (or `'main#…'`) and **all ~620 files re-record**, none of them for a behaviour reason.
That is the single largest difference in the comparison table.

Comptime snapshots are unaffected either way:

```
$ grep -rl 'template_[0-9a-f]\{16\}\|decorator_[0-9a-f]\{16\}' modules/compiler-core/snapshots | wc -l
0
```

The one place a comptime module atom is pinned is a unit test, not a snapshot:
`modules/compiler-core/src/codegen/tests/comptime_module.zig:17` passes `"decorator_test"` and
`:45` asserts `-module(decorator_test).`; `src/comptime/decorator_eval.zig:370` asserts
`startsWith(m.code, "-module(decorator_")`.

---

## 2. Compiler source

| File | Change | Size |
|---|---|---|
| `src/codegen/crossModule.zig` | add `erlAtom` / `outputStem` / `RESERVED`; `ownerModuleAtom` delegates; keep `moduleBasename` only if something still needs a basename | ~80 LOC in a 144-line file |
| `src/codegen/erlang.zig:962-968` | replace the inline truncation with `crossModule.erlAtom` | ~6 LOC |
| `src/codegen/beam_asm.zig:907-913` | same | ~2 LOC |
| `src/codegen/runtime.zig:451-455` | `erlModuleName` delegates to `erlAtom`, so the harness writes `<atom>.erl` / `<atom>.S` and passes `-s <atom>` | ~5 LOC |
| `src/comptime/template_eval.zig:340`, `src/comptime/decorator_eval.zig:238` | `template_{x}` → `bp@comptime@template@{x}` (same for decorator) | 2 LOC + the two test assertions above |
| `modules/compiler-cli/src/cli/build.zig:184-208` | output stem per target: `out/<atom><ext>` for `.erl`/`.S`, `out/<path><ext>` unchanged for `.js`/`.d.ts`/`.wat` | ~20 LOC |
| `modules/compiler-cli/src/cli/build.zig:157-166` | `removeStaleArtifacts` uses the same stem | ~5 LOC |
| `modules/compiler-cli/src/cli/run.zig:51,66-71` | entry path for the erlang target | ~5 LOC |
| `scripts/beam_export_audit.sh:63-80` | none for option A (atoms stay unquoted and filename-safe); a quote-stripping step for P or C | 0 / ~10 lines |

Total for option A: **≈ 150 LOC across 8 files**, no new subsystem.

`src/codegen/wat.zig:211` calls `moduleBasename` only to compare an import's last segment; it is
not a naming site and does not move.

---

## 3. Libraries and examples

**Zero `.bp` changes.** The atom is derived from the module path the compiler produces
(`scanner.zig:62`, `resolver.zig:210`, `libs.zig:323`); no library or example writes a module atom
down. Verified by searching the seven repositories for a hand-written erlang module reference: the
only `@External.Erlang(...)` first arguments name **OTP** modules (`"erlang"`, `"lists"`, …), which
are untouched.

What *changes behaviour* for libraries, in their favour:

| Today | After option A |
|---|---|
| six libraries each emit `-module(root)` (`libs/std`, emilia, erika, jhonstart, onze, rakun) | `std@root`, `emilia@root`, … — distinct |
| `libs/std/src/http.bp` and `rakun/src/http.bp` both emit `-module(http)` | `std@http`, `rakun@http` |
| eleven `libs/std` modules shadow an OTP module ([E14](./atom-evidence.md#e14--eleven-libsstd-module-names-are-already-otp-module-names)), silently breaking that OTP module for the whole node ([E15](./atom-evidence.md#e15--what-shadowing-an-otp-module-actually-does)) | `std@math`, `std@os`, `std@crypto`, … — no shadow |

The library gate (`zig build test-libs`) runs each library's own cells; none of them today executes
two libraries in one erlang node, so the change should be **invisible to the gate** and visible only
as a cleaner `out/`. That is worth stating as a risk: the collisions being fixed are mostly *latent*,
and the gate cannot prove they were fixed. The front's step 4 adds the test that can.

---

## 4. What has to be re-verified by running, not reading

- The nine cross-module erlang fixtures and their beam twins, executed (`RUN LOG` unchanged).
- `scripts/beam_export_audit.sh` at 295/295 — it derives a filename from the recorded atom
  (`:80`), so a name it cannot use as a filename shows up here first.
- A two-library erlang program (new, step 4): `std/http` and `rakun/http` in one build, both called.
  It does not exist today and is the only direct proof the collision is gone.
- `botopink run --target erlang` on a multi-module project — today it is `escript out/<mod>.erl`
  with **no `-pa`** (`run.zig:66-71`), so a cross-module erlang program is not runnable from the CLI
  at all. Step 3 has to decide whether the front fixes that or records it as a residual.

---

## 5. Estimate

| Step | Days |
|---|---|
| 1 — `ModuleId` + `erlAtom` + `RESERVED`, four call sites | 1 |
| 2 — output layout per target, `run.zig`, stale-artifact cleanup | 0.5 |
| 3 — comptime atoms into the same shape | 0.25 |
| 4 — the two-library collision test and the OTP-shadow test | 0.5 |
| 5 — re-record ≈ 20 snapshots, each classified and executed | 0.5 |
| gate (`scripts/gate.sh --cold`) + `AGENTS.md` of the three touched directories | 0.5 |

**≈ 3 days**, 2 if nothing in the audit script or the harness surprises. Under option P or C add
**2–3 days** for the quoting rule in every emitter and the ~620 snapshot re-records, each of which
has to be classified rather than bulk-accepted ([the rule 1.0.4-beta ran
under](../../../1.0.4-beta/overview.md), carried into 1.0.5-beta).

---

## 6. Policy 3 on top

[Policy 3](./policy-3-module-per-type.md) (maintainer — one BEAM module per `type` and
per `behavior`) is a separate cost on top of everything above, and a different **kind** of cost:
the numbers in §§ 1–5 are names changing, policy 3 is emitted shape changing.

| | A + A2 (§§ 1–5) | Policy 3 |
|---|---|---|
| Snapshots | ≈ 20, one atom per file | **188** — 94 erlang + 94 beam, each gaining emitted sections ([§ 4](./policy-3-module-per-type.md#4-snapshot-cost--measured)) |
| Compiler | ≈ 180 LOC, 9 files | the four `*Forms` emitters split, `codegenEmit` yields N artifacts, `build.zig` + `run.zig`, `beam_asm.zig` mirrored, three mangling helpers deleted |
| Libraries | no `.bp` change | no `.bp` change; every erlang cell re-runs |
| Runtime | none | +0.372 ns per method call ([E26](./atom-evidence.md#e26--local-call-vs-remote-call)) |
| Breaks on the way | nothing | `botopink run --target erlang` for every type-bearing program ([E25](./atom-evidence.md#e25--botopink-run-breaks-under-policy-3)) |
| Days | ≈ 3.5 | **+5–7** |

Recommendation and the step cut are in
[`policy-3-module-per-type.md` § 9](./policy-3-module-per-type.md#9-sequencing--decided-one-front-not-two).
