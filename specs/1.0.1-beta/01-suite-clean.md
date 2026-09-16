# Spec 01 — Suite clean

**Version:** 1.0.1-beta
**Status:** delivered

---

## Objective

`zig build test` (in `repository/botopink-lang`) with 0 failures and 0 leaks **from a cold
runtime cache**, and a harness in which a snapshot test cannot pass by recording nothing.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Delivered

### The run is decided by the exit status — `codegen/runtime.zig`

Every spawn goes through one helper, `runCaptured`, which returns the captured text and a
`RunStatus` (`.ok` / `.failed`) taken from the process term instead of from the output's
length. The old contract — "empty output means success" — was what blanked the RUN LOG of
every BEAM snapshot (`erlc +from_asm` prints nothing on success) and of the erlang snapshots
whose module compiles with warnings (`erlc` prints, exits 0).

| Behaviour | Where |
|---|---|
| `runCaptured` + `RunStatus`, status from the process term | `runtime.zig` `runCaptured`, `RunStatus`, `isProcessSuccess` |
| A non-zero compile exit records `COMPILE ERROR (<tool>):` plus the tool's output, in place of the RUN LOG | `runtime.zig` `compileFailureLog`, used by `executeErlang` / `executeBeamAsm` |
| Every captured slice is freed — the four `erlc` results that used to be dropped by `if (… .len > 0) return dupe("")` included | `defer allocator.free(…)` on each `runCaptured` result in `executeJavaScript` / `executeErlang` / `executeBeamAsm` |
| A warm cache can no longer hide a harness change: `HARNESS_VERSION` is folded into `cacheKey`, so entries written by an older harness miss | `runtime.zig` `HARNESS_VERSION = "2-exit-status"` |
| The `CACHE_ROOT` doc comment says what is true — nothing reaps the directory, `clean-tmp` only touches `TMP_ROOT` | `runtime.zig` `CACHE_ROOT` |

### A program that does not compile fails its test — `codegen/tests/helpers.zig`, `codegen/snapshot.zig`

`assertJs` used to record a module the backend had dropped as nothing at all, and nothing
compares equal to nothing.

| Behaviour | Where |
|---|---|
| A module missing from the backend output is re-run through the comptime front end and its diagnostic recorded as a `COMPILE DIAGNOSTIC` section | `helpers.zig` `collectCompileDiagnostics`; `snapshot.zig` `buildSnapshot` (`result == null` or `comptime_err` set) |
| A test whose program does not compile fails with `error.ModuleDidNotCompile` unless it opts in | `helpers.zig` `assertJsExpecting`, `CompileExpectation` |
| A documented skip opts in explicitly and fails if the program *starts* compiling (`error.ExpectedCompileError`) | `helpers.zig` `assertJsCompileError`; comptime side `assertComptimeCompileError` |
| All four backends are compared before the first failure is reported, so one round writes every `.snap.md.new` | `helpers.zig` `assertJsExpecting` (`first_err`), `assertJsError` |
| A missing snapshot fails instead of being created silently | `utils/snap.zig` `CREATE_ENV` (`BOTOPINK_SNAP_CREATE=1` to record) |
| The comptime evidence (`COMPTIME ERLANG` / `COMPTIME REPLY`, then `COMPTIME VALUES`) is written for every backend, and for a V1-driver template expansion that never reaches `erl` | `snapshot.zig` `writeComptimeSections`; `comptime/snapshot.zig` (`OkData.template_expansions`) |

11 tests are documented skips carrying a `COMPILE DIAGNOSTIC` (3 codegen, 8 comptime), each
with a comment naming the missing feature at the call site.

### Library code no longer writes to stderr

`comptime.zig` and `parser.zig` printed a parse failure — with the whole source — to stderr,
on top of returning it as `ComptimeOutput.parseError` / `ParseError`. The Zig test runner
reads stderr, so every test that expected a non-compiling program failed the build even when
all tests passed. Both prints are gone; the diagnostic travels only in the result.

## Verified today

Run from `repository/botopink-lang`, `modules/compiler-core/.botopinkbuild/runtime-cache`
removed first, then a second time warm:

| Run | Result |
|---|---|
| `zig build test`, cold cache | exit 0, no `leaked`, no `.snap.md.new` |
| `zig build test`, warm cache | exit 0, no `leaked`, no `.snap.md.new`, same snapshots |

The warm run is no longer a weaker gate than the cold one: `HARNESS_VERSION` invalidates any
entry recorded by a different harness contract.

## Carried into 1.0.2-beta

`07-suite-and-harness.md` — proving the 4 decorator regression tests fail when the lowering
they name is broken.
