# Spec 06 — Snapshot review

**Version:** 1.0.1-beta
**Status:** closed for the review and the harness — the findings the waves did not reach are
carried by [`1.0.2-beta/06-snapshot-review.md`](../1.0.2-beta/06-snapshot-review.md)
**Priority:** critical — the snapshots are the oracle of most of the suite

---

## Objective (met)

Every `*.snap.md` was reviewed against the test that produces it and given a verdict, and the
harness was fixed so that a green suite means "the compiler does the right thing" rather than
"the compiler does what it did when the snapshot was first written".

Paths are relative to `repository/botopink-lang/modules/` unless stated otherwise.

---

## 1. The review

2442 snapshots, all tracked, across seven suites. The unique review volume was 278 codegen
sources × 4 backends (+ `test_runner` × 2), 306 comptime, 213 parser and 102 LSP.

For each snapshot the producing test was opened (the file name is the slug of the test
description) and three things checked: that the `SOURCE CODE` exercises what the test name says,
that the recorded output is what that source must produce — RUN LOGs computed by hand, not copied
from another backend — and that the test asserts something beyond the snapshot when it should.
Verdicts: `ok`, `wrong-output`, `wrong-test`, `weak`, `skip-undocumented`, `orphan`, `duplicate`.

Generated code was executed outside the repo (`node`, `erlc`/`erl`, `erlc +from_asm`,
`wasmtime`), checker claims re-probed with a `botopink` built from HEAD, and the LSP ones by
driving `botopink-lsp` over stdio. Every finding was then re-checked in a second pass, which
confirmed the large majority, withdrew 4 and corrected the rest in place.

**The evidence is the twelve reports in [`06-snapshot-review/`](./06-snapshot-review/)** — one per
batch, each with quoted lines, expected vs actual, a suggested fix site and a re-check
classification per row. They are the audit record and are kept verbatim.

| Report | Scope | Unit | ok | wrong-output | wrong-test | weak | duplicate | other |
|---|---|---|---|---|---|---|---|---|
| [`codegen-features`](./06-snapshot-review/codegen-features.md) | `codegen/tests/features.zig` | test×backend cells (252) | 130 | 108 | 4 | 3 | — | 4 uncertain, 3 known |
| [`codegen-control_flow`](./06-snapshot-review/codegen-control_flow.md) | `control_flow.zig` | tests (44) | 1 | 26 | 8 | 6 | 2 | 1 uncertain |
| [`codegen-wat-narrowing`](./06-snapshot-review/codegen-wat-narrowing.md) | `wat.zig` + `narrowing.zig` | tests (45) | 8 | 25 | 9 | 3 | — | — |
| [`codegen-values-dispatch-externals`](./06-snapshot-review/codegen-values-dispatch-externals.md) | `values`/`dispatch`/`externals.zig` | cells (204) | 62 | 60 | 27 | 26 | 16 | 11 known, 2 uncertain |
| [`codegen-builtins-aggregates`](./06-snapshot-review/codegen-builtins-aggregates.md) | `builtins`/`aggregates.zig` | tests (53) | 5 | 39 | 4 | 5 | — | — |
| [`codegen-comptime-misc`](./06-snapshot-review/codegen-comptime-misc.md) | `codegen/tests/comptime.zig` + misc | tests (36) | 6 | 14 | 5 | 5 | 1 | 5 known |
| [`comptime-errors-effects`](./06-snapshot-review/comptime-errors-effects.md) | `infer_errors`/`exhaustiveness`/`effect_*` | tests (92) | 44 | 24 | 9 | 9 | 6 | — |
| [`comptime-decls-variants`](./06-snapshot-review/comptime-decls-variants.md) | `infer_decls`/`variants` | tests (81) | 22 | 13 | 15 | 30 | — | 1 uncertain |
| [`comptime-templates-types-exprs`](./06-snapshot-review/comptime-templates-types-exprs.md) | `templates`/`types`/`infer_exprs` | tests (103) | 63 | 7 | 15 | 17 | 1 | — |
| [`comptime-generics-effects-decorators`](./06-snapshot-review/comptime-generics-effects-decorators.md) | typeinfo/effects/generics/defaults/narrowing/decorators | tests (161) | 83 | 8 | 30 | 28 | 11 | 1 uncertain |
| [`parser`](./06-snapshot-review/parser.md) | 213 parser snapshots | snapshots | 183 | 9 | 10 | 4 | 3 | 4 legacy-syntax |
| [`lsp`](./06-snapshot-review/lsp.md) | 102 LSP snapshots | snapshots | 70 | 12 | 4 | 9 | 5 | 2 uncertain |

**No orphan snapshot and no test without its snapshot, in any suite.**

---

## 2. The harness contract that came out of it

The review found ten harness defects (H1–H10) that let the suite stay green on output nobody
checked: the BEAM backend never actually ran, an `erlc` warning silently blanked a RUN LOG,
a program that failed to compile was recorded as an empty snapshot and passed, a missing
snapshot was auto-accepted, and only the first of four backends was ever compared.

All ten are closed. What the harness guarantees now:

### RUN LOG — decided by exit status (H1, H2)

`codegen/runtime.zig` routes every spawn through `runCaptured`, which reports a `RunStatus`
alongside the captured text. Output length says nothing about success, which is exactly what kept
BEAM from ever executing: a successful `erlc +from_asm` prints nothing.

| Status | Meaning | Recorded | Cached |
|---|---|---|---|
| `.ok` | exited 0 | the captured text is the RUN LOG (stdout, stderr appended) | yes |
| `.failed` | ran, non-zero exit | compile/assemble: `COMPILE ERROR (<tool>):` + diagnostics; execute: empty | yes (deterministic) |
| `.unavailable` | missing binary, spawn error or timeout | nothing — as if the run never happened | never (host-dependent) |

- An `erlc` **warning** exits 0 and no longer stops the run; a real compile error is now *visible*
  in the snapshot as a `COMPILE ERROR` section instead of an empty RUN LOG (`compileFailureLog`
  keeps the errors and drops the warnings and the source echo — it has its own unit tests).
- The four leaked `erlc`/`erl` output slices are freed; the suite reports 0 leaks.
- `erlc`/`erl` are spawned with the per-execution scratch dir as cwd, so diagnostics name
  `<module>.erl` / `<module>.S` and no absolute path or stray `erl_crash.dump` reaches the tree.
- `HARNESS_VERSION` (`runtime.zig`) is folded into `cacheKey`, so entries written by an older
  harness miss instead of masking a change. A warm `.botopinkbuild/runtime-cache` can no longer
  hide a harness defect — which is how 70 BEAM and 5 erlang RUN LOGs had survived.

### A snapshot test fails when its program does not compile (H3, H9)

`codegen/tests/helpers.zig` and `comptime/tests/helpers.zig` share a `CompileExpectation`:

- `must_compile` (the default): a parse, type or validation error **fails** the test. The
  diagnostics the backends discard are recovered by re-running the comptime front end
  (`collectCompileDiagnostics`) and written as a `COMPILE DIAGNOSTIC` section.
- `expect_compile_error` (via `assertJsCompileError` / `assertComptimeCompileError`): the test is
  *about* a program that does not compile, and the recorded diagnostic is the assertion.

Effect on the tree: the **116 zero-byte codegen snapshots (29 slugs × 4) and the 39 source-only
comptime snapshots are gone**. Most became real tests; 11 slugs are explicit documented skips
(`codegen/tests/{narrowing,wat}.zig`, `comptime/tests/{narrowing,variants,eval_pipeline}.zig`),
each pinning its diagnostic in 44 `COMPILE DIAGNOSTIC` snapshots.

### Every backend is compared (H10)

`assertJs`, `assertJsError` and `assertJsTestMode` now loop the whole backend list, accumulate the
first error in `first_err` and return it at the end. One suite round writes every `.snap.md.new`
instead of one per backend.

### Missing snapshots are not auto-accepted (H4)

`utils/snap.zig` `compareOrCreate` writes a missing snapshot only when `BOTOPINK_SNAP_CREATE=1`;
otherwise the test fails. `*.snap.md.new` is git-ignored (spec 05 item 5.15).

### The rest

| # | Defect | Now |
|---|---|---|
| H6 | parser error tests returned early when no error detail was produced ("assignment without val", "reserved word in expression" compared nothing) | `parser/tests/helpers.zig` fails with `TestParseErrorInfoMissing` — a parse that fails without filling `parseError` renders nothing for the user, so it is a failure, not a skip |
| H7 | dead language-server test files | closed as spec 05 item 5.11 |
| H8 | `BOTOPINK TRANSFORM CODE` only written when a comptime `val` existed | `comptime/snapshot.zig` writes it whenever a comptime script ran, a template expanded or a decorator contributed |
| H5 | `executeWat` stub — every wasm RUN LOG empty | **not a harness defect to fix here**: it needs a wasm runtime. Carried by the codegen-hardening spec (WAT execution) |

### Snapshot format changes from the same work

- The codegen tree was flattened to `snapshots/codegen/<target>/` and
  `snapshots/codegen/errors/<target>/`.
- Comptime snapshots now show the `erl` exchange: `COMPTIME ERLANG -- <template|decorator> <fn>`
  (the lowered body plus the `main/0` that encodes the reply) and `COMPTIME REPLY` (the JSON sent
  back, or the error text), plus `COMPTIME VALUES` listing `ct_N: <declaration> → literal` so a
  wrong fold is visible next to its source.
- Emitted erlang breaks wide terms across lines, so a diff points at the changed element.

---

## 3. Classes of finding the review closed

The reports were written at a tree that predates the fix waves. Acting on them closed these
classes outright (detail in the specs that own each layer):

| Class | Outcome |
|---|---|
| Harness (H1–H4, H6–H10) | closed — section 2 |
| Parse-error and token locations | closed — every parser diagnostic used to land on line 1 (the column was stored and printed as a byte offset); multi-line/backslash strings were stamped with their end line and `${…}` holes positioned relative to the hole. `ParseErrorInfo.fromToken`/`fromTokenSpan` now carry the real span |
| Retired syntax (the 4 `legacy-syntax` parser rows) | closed as spec 05 items 5.12 / 5.13 |
| Comptime folding | closed — the folder folded every binary op as an integer (`3.14 * 2.0 → 0`, `"Hello, " + "World" → 0`); it now folds by operand kind, and the comptime block has a scope |
| Erlang: emitted modules that do not compile or run | closed — module-level `val`s, variant patterns, case guards (`caseNode` never read `arm.guard`), string concatenation and loops |
| BEAM: register clobbering | closed — operands were staged into `{x,0}` before being saved, overwriting tuple elements, call arguments, parameters and `self` in ~54 bodies; staging now starts above the live floor (`scratchBase`), with the list accumulator parked on the stack |
| wasm: invalid modules | closed — every emitted module loads (`(local …)` mid-body, values left on the stack, missing functions, `(param $ i32)`) |
| Language server | closed — `collectInterfaceMembers` leaked comments, attributes and body locals into completion/hover; document symbols reported `val X = enum/record` as `Variable`; semantic tokens classified record fields and `true` as `variable` |

Three backends were additionally rebuilt around a code model rendered by a single emitter
(`beam_emitter`, the WAT model + `wat_emitter`, the JavaScript/TypeScript model + `js_emitter` /
`ts_emitter`), which is what made the per-backend fixes reviewable.

---

## 4. Verified at HEAD

- `zig build test` green; 0 leaks; 0 `*.snap.md.new` on disk.
- 2442 snapshots, **0 of them zero-byte**, and no snapshot carries only a `SOURCE CODE` section.
- 44 snapshots pin a `COMPILE DIAGNOSTIC` (the 11 documented skips).
- `find modules -name '*.snap.md.new'` empty and the pattern git-ignored.

## 5. Carried to 1.0.2-beta

Step 1's remaining tooling (the `BOTOPINK_SNAP_TRACE` orphan list, `snap_audit.sh --mode=review`),
the per-report residual rows, the comptime copy deduplication and the closing criteria are in
[`1.0.2-beta/06-snapshot-review.md`](../1.0.2-beta/06-snapshot-review.md). The wasm RUN LOGs (H5)
belong to the codegen-hardening spec, the checker root causes (C1–C13) to the type-system spec.
