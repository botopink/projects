# Front 01 — std

**Track:** A — std
**Priority:** critical/blocking — every library test in the ecosystem is written against `@src()`, `testing.asserts` and `testing.snapshots`; no `<lib>-test` submodule, no `__snapshots__/` directory and no green front exists without them
**Target:** both — `asserts` compiles on all four backends; `snapshots` runs on the two targets `botopink test` runs (commonJS, erlang); `@src()` lowers on all four
**Depends on:** none
**Owns:** compiler — the `@src()` builtin (`comptime.zig` `decl_reflection_src`, `comptime/infer.zig`, `comptime/env.zig` `srcPath`/`currentFnName`, `comptime/diagnostics.zig`, `comptime/error.zig`, `module.zig` `srcPath`, `compiler-cli/src/cli/` the `srcPath` plumb) and its `src_*.snap.md` fixtures · std — `libs/std/src/testing/{asserts,snapshots,mocks,mod}.bp`, `libs/std/src/root.bp` (the registry of `modules.md`), `libs/std/AGENTS.md` · meta — `.gitmodules` (the `repository/onze` entry is re-pointed, not removed), `repository/onze` · specs — this directory
**Does not touch:** the codegen backends — `@src()` is rewritten into a record constructor before lowering; `repository/{rakun,jhonstart,emilia}` sources — their `-test` submodules consume this contract
**Reference:** Zig `@src()` → `std.builtin.SourceLocation` · the compiler's snapshot harness — `codegen/tests/helpers.zig` (`slugify`, `slugFromSrc`), `utils/snap.zig` (`.new` on mismatch) · decision 67 — the most restrictive behaviour, no configuration that bypasses it · decisions 106 and 107 — the std tree and the import grammar · decisions 115–117 — the bundled libraries

---

## The contract

`@src()` answers a `SourceLocation(file, line, column, fnName)` for the place it is written; a `try`
on an `Error` inside a `test` body ends the test as `FAIL`; every assertion in `testing.asserts`
answers `@Result<void, string>`; `testing.snapshots` writes `<path>.new` on a mismatch or a missing
file and answers `Error`, and nothing but a person renaming the `.new` file records a snapshot — no
flag, no environment variable, no manifest key (decision 67). Mocking is `testing.mocks` (decision
71); the name `onze` passes to the orchestrator (decision 79).

## What exists

| Piece | Where |
|---|---|
| `@src()`, `SourceLocation` | compiler: the inference arm rewrites the call into `SourceLocation(file: …, line: …, column: …, fnName: …)`; `env.srcPath` / `env.currentFnName`; the diagnostics `src-takes-no-arguments` and `unknown-builtin`; fixtures `snapshots/codegen/*/*/src_*.snap.md`, `snapshots/comptime/ast/src_types_as_sourcelocation.snap.md`, `snapshots/comptime/errors/src_takes_no_arguments.snap.md`; `docs.md` and `libs/std/src/builtins.d.bp` document it |
| a `try` in a `test` body | `codegen/tests/builtins.zig` "test body ---- try on an Error fails the test" / "… prints the FAIL line" |
| `testing.asserts` | `libs/std/src/testing/asserts.bp` — the surface of [`asserts-api.md`](./asserts-api.md) |
| `testing.snapshots` | `libs/std/src/testing/snapshots.bp` — `path`, `pathNamed`, `suiteOf`, `slugOf`, `assertText`, `assertAs`, `assertNamed`, `assertNamedAs` ([`snapshots.md`](./snapshots.md)) |
| `testing.mocks` | `libs/std/src/testing/mocks.bp` — the old onze surface, lifted; the eight cells `pub declare fn` with Node and Erlang templates; a consumer writes `#[mocks.mock]` (`onze-migration.md` § *Decorator resolution*) |
| the std tree | decision 106's: pure root, `io/`, `testing/` — `modules.md` § *The tree* |
| the bundled libraries | `libs/routing`, `libs/actions`, `libs/validation` beside `libs/std`, embedded by `build.zig`'s `bundled_packages` (fronts 04–06 of this directory) |
| the old `onze` | still checked out at `repository/onze`: the retired mocking library with its archive banner and the tag `mocking-lib-final`; the submodule still points at `botopink/onze` |
| `*.snap.new` ignore rule | in `repository/botopink-lang/.gitignore`; not yet in rakun, jhonstart, emilia |

## Documents

| File | Holds |
|---|---|
| [`src-builtin.md`](./src-builtin.md) | step 1 — `@src()`, `SourceLocation`, the test body as a fallible context, the fixtures |
| [`asserts-api.md`](./asserts-api.md) | step 2 — the `import {testing.asserts} from "std"` surface, failure messages, backend notes, the old-name table |
| [`snapshots.md`](./snapshots.md) | step 3 — `snapshots.path(loc)`, the `.snap` format, `.new` on mismatch, the API, how a `<lib>-test` exposes `assert<Subject>` |
| [`onze-migration.md`](./onze-migration.md) | steps 4 and 5 — where each symbol of the old `onze` went, the submodule swap, the `onze13 → onze` checklist |
| [`modules.md`](./modules.md) | the package cut for std — the three-category tree, the old → new path table, ownership, why std has no `-test` submodule |
| [`test-snap.md`](./test-snap.md) | the snapshot-test map for std itself |
| [`examples/asserts-unit-example.bp`](./examples/asserts-unit-example.bp) | Example 1 — `testing.asserts` alone |
| [`examples/emilia-test-submodule-example.bp`](./examples/emilia-test-submodule-example.bp) · [`examples/emilia-test-consumer-example.bp`](./examples/emilia-test-consumer-example.bp) | Example 2 — an `emilia-test` submodule and the test file that consumes it with `@src()` |
| [`01-std-lib-enablement/`](./01-std-lib-enablement/README.md) · [`02-std-async-primitives/`](./02-std-async-primitives/README.md) · [`03-std-content-hash/`](./03-std-content-hash/README.md) | step 6 — the three std sub-fronts |
| [`04-routing-lib/`](./04-routing-lib/README.md) | step 8 — the bundled library `routing` (decision 115): the route matcher, the `k` / `z` / URL-rule codecs, the navigation vocabulary and the `:param` grammar (decision 116) |
| [`05-actions-lib/`](./05-actions-lib/README.md) · [`06-validation-lib/`](./06-validation-lib/README.md) | step 9 — the bundled libraries `actions` (the server-action envelope, `state` grammar, JSON-RPC body, `refresh`) and `validation` (rakun-validation moved, its message lookup injected) — decision 116 |
| [`01-std-lib-enablement/`](./01-std-lib-enablement/README.md) Steps 11–14 | step 10 — std reads and writes JSON: `json.quote` / `unquote` / `array` / `object`, `escape.scriptJson`, the `Json` type and `json.decode` (decisions 116, 117) |

## Order of what is open

```
5  onze13 → onze namespace takeover (directory, .gitmodules, botopink.json, docs)
   — waits on the maintainer's remote actions (decision 79; 02-packaging/95 step 2)

8  04-routing-lib — its compiler-suite bundled test (Step 2) and one pattern literal (Step 8)
9  05-actions-lib · 06-validation-lib — the consumer imports (rakun 24, jhonstart 67 / 26)
```

The open acceptance boxes of steps 1–4 below stand as written; each is checked against the code
named in *What exists*.

## Steps

### Step 1 — `@src()` and the test body as a fallible context

Specified in [`src-builtin.md`](./src-builtin.md). `pub type SourceLocation(file: string, line: i32,
column: i32, fnName: string)` is in the reflection prelude; `@src()` is rewritten at inference time
into the ordinary constructor call, so every backend lowers it through its record-constructor path
and no codegen file changes. An unknown `@name(…)` is `error[unknown-builtin]`. A `try` on an
`Error` inside a `test` body ends the test as `FAIL` with the error string as the message.

**Acceptance:**
- [x] `val loc = @src();` inside `test "x: y"` in `src/a.bp` at line 12 column 15 lowers, on all four backends, to the same code as `SourceLocation(file: "src/a.bp", line: 12, column: 15, fnName: "x: y")` — four `src_*.snap.md` fixtures byte-identical to the hand-written constructor's — a project whose `locate()` returns `@src()` and its twin returning `SourceLocation(file: "src/main.bp", line: 2, column: 12, fnName: "locate")` build to byte-identical `out/` trees on commonJS, erlang, beam and wasm; `src_equals_a_hand_written_constructor.snap.md` on each
- [x] `@src(1)` → `error[src-takes-no-arguments]`; `@nope()` → `error[unknown-builtin]`, both located — `botopink check` reports each at `src/main.bp:2:13`
- [x] `fnName` is the test name inside a `test`, the fn name inside a `fn`, `Type.method` inside a method, `""` at module level — one snapshot per position — `src_in_a_test` / `in_a_fn` / `in_a_method` / `at_module_level`; run: `f`, `Box.where` and the empty string on the four targets, the test name under `botopink test`
- [x] `test "t: fails" { try failing(); }` prints `FAIL t: fails (<error string>) at src/a.bp:N` on commonJS and erlang — `codegen/tests/builtins.zig` gains a run-log fixture for each — `test_body_try_on_an_error_fails_the_test` on both (the harness passes no path, so `main.bp:N`); under the CLI the TEST, FAIL and `assert` locations name the scanned path (`ComptimeOutput.srcPath`): `modules/compiler-cli/tests/test_tooling.sh` pins `FAIL t: fails  (went wrong)  at src/main.bp:25` and the assert's `at src/main.bp:22` on commonJS and erlang
- [x] `docs.md` § Builtins and `libs/std/src/builtins.d.bp` document `@src()` and `SourceLocation`; `vscode-extension/syntaxes/botopink.tmLanguage.json` highlights `@src` — `docs.md` § Builtins › "`@src()` and `SourceLocation`", `builtins.d.bp` § Source location; the grammar's `builtins` rule `@[a-zA-Z_][A-Za-z0-9_]*` paints `@src`
- [x] `zig build test` green from a cold cache — `runtime-cache` deleted, 2565 / 2565

### Step 2 — `testing.asserts`

Specified in [`asserts-api.md`](./asserts-api.md). Every assertion answers `@Result<void, string>`;
the names are `isTrue`, `isFalse`, `equals`, `notEquals`, `approxEquals`, `isNil`, `isNotNil`,
`isOk`, `isError`, `contains`, `notContains`, `startsWith`, `endsWith`, `matches`, `isEmpty`,
`isNotEmpty`, `lengthIs`, `includes`, `notIncludes`, `between`, `greaterThan`, `lessThan`,
`deepEquals`, `throws`, `throwsWith`, `fail`, plus the reader `errorText`. Failure messages are
`asserts.<fn>: <what>`, one literal per function. The module has no `pub declare fn`, so it passes
STD-001 on every target; `matches`, `deepEquals`, `throws` and `throwsWith` use private cells with
Node and Erlang templates.

**Acceptance:**
- [x] `import {testing.asserts} from "std"` type-checks for `--target commonJS`, `erlang`, `beam` and `wasm` (STD-001 does not fire — no `pub declare fn` in the file) — and builds and runs on all four: `tests/language/run/std_asserts_on_every_target.bp`. wasm emits the module without the four host-backed assertions (`wat.zig` `collectHostBound`) and refuses a CALL of one where it is written — `` `deepEquals` calls `canonical`, which has no `#[@External.<Target>(…)]` for the wasm backend `` (`run/std_asserts_host_cell_on_wasm.bp`); `approxEquals` no longer binds an `f64` `if`-value, which wasm typed `i32`
- [x] every function's pass and fail path is covered by an inline `test` at the foot of the file, written with `try`; the fail paths assert the literal message through `errorText` (an assertion answers `@Result` and raises nothing a `throws` / `throwsWith` could catch)
- [x] `botopink test` in `libs/std` green on commonJS and erlang; `zig build test-libs` reads `std · commonJS: pass` and `std · erlang: pass` — 431 passed, 0 failed on each; `test-libs` 77 passed, 0 failed, both std rows `pass`
- [x] the old names (`truthy`, `falsy`, `equal`, `notEqual`, `approxEqual`, `AssertError`) are gone and `grep -rn "asserts\.\(truthy\|equal\b\)" --include=*.bp repository/` is empty — the grep and one for `AssertError` / `falsy` / `notEqual` / `approxEqual` are empty
- [x] `libs/std/AGENTS.md`'s `asserts` row lists the surface

### Step 3 — `testing.snapshots`

Specified in [`snapshots.md`](./snapshots.md). `libs/std/src/testing/snapshots.bp`: `path(loc)`,
`pathNamed(loc, name)`, `suiteOf(name)`, `slugOf(name)`, `assertText(loc, actual)`, `assertAs(loc,
subject, actual)`, `assertNamed(loc, name, actual)`, `assertNamedAs(loc, name, subject, actual)`.
A mismatch or a missing file writes `<path>.new` and answers `Error`. There is no flag, no
environment variable and no manifest key that records a snapshot.

**Acceptance:**
- [x] `snapshots.path(SourceLocation(file: "src/emilia.bp", line: 1, column: 1, fnName: "css: modifiers ---- hover on md breakpoint"))` answers `src/__snapshots__/css/modifiers_hover_on_md_breakpoint.snap` on both targets — run on commonJS and erlang
- [x] a name with no `": "` answers `Error("snapshots: test name needs a suite …")` — asserted, not assumed — "path ---- a name without a suite is refused"
- [x] missing → `.new` written + `Error`; mismatch → `.new` written + `Error`; match → `Ok` and a stale `.new` deleted; each is an inline test running against a scratch `__snapshots__/` under the host tmpdir — the `engine ----` tests, green on both rows
- [x] `grep -rn "SNAP_CREATE\|update" libs/std/src/testing/snapshots.bp` finds no code path that writes `<path>` itself — the grep finds the header's "there is no update flag" only; the engine's one `writeFile` writes `<path>.new`
- [ ] `*.snap.new` is in `.gitignore` of `botopink-lang`, `rakun`, `jhonstart`, `emilia` and the new `onze`, and each repo's `scripts/git-hooks/pre-commit` refuses a staged `*.snap.new` — botopink-lang holds: `.gitignore` has it, and its hook's `scripts/gate.sh --staged` refuses a staged `*.snap.new` / `*.snap.md.new` (`git add -f` included); `botopink test` lists every candidate after the results (`modules/compiler-cli/tests/test_tooling.sh`). **Open:** rakun, jhonstart, emilia and onze — neither the `.gitignore` line nor the refusal

### Step 4 — the old `onze`, migrated 100 %

Specified in [`onze-migration.md`](./onze-migration.md). The mocking surface (`#[mock]`, `when`,
`verify`, `thenReturn`, `thenThrow`, `times`, `never`, `atLeastOnce`, the matchers, the eight host
cells) is `testing.mocks`, lifted verbatim (decision 71); its `onzeKey` renderer is also `asserts`'
private `canonical`. There is no `.mjs` sidecar: the Node tables are a `globalThis.__bp_mocks` cell.

**Acceptance:**
- [x] every row of the inventory table in `onze-migration.md` has a destination and a test that exercises it there — every symbol row lands in `mocks.bp` (or `asserts`' `canonical`) and is reached by the eight tests, `anyString()`'s and `deepEquals`'
- [x] `repository/onze/test/onze_test.bp`'s eight tests pass, re-spelled against `testing.mocks`, as inline tests at the foot of `libs/std/src/testing/mocks.bp`, on commonJS and erlang — the eight names, `mocks: …`, green on both rows
- [ ] `../03-rakun/19-rakun-test-utilities/examples/controller-test-example.bp` imports from `"std"` instead of `"onze"` — **open:** line 24 still reads `from "onze"`
- [x] no `.mjs` file is added under `libs/std/src/sidecars/` — `random.mjs` alone
- [ ] `grep -rn 'from "onze"' --include=*.bp repository/ specs/1.0.10-beta/` finds only orchestrator imports — **open:** the old library's own `repository/onze` files and the rakun example above

### Step 5 — `onze13 → onze` namespace takeover

Specified in [`onze-migration.md`](./onze-migration.md) § *The rename checklist*. The
`repository/onze` submodule entry is re-pointed at the orchestrator's repository (front 49's, under
the name `onze`); the old library's last commit is tagged in its own repository and the repository
is archived on the remote, not vendored under `repository/_archived/` — a directory the build would
otherwise scan. The maintainer's commands are in
[`../02-packaging/95-ecosystem-package-restructure/README.md`](../02-packaging/95-ecosystem-package-restructure/README.md) step 2.

**Acceptance:**
- [ ] `.gitmodules` has one `repository/onze` entry and it resolves to the orchestrator
- [ ] `repository/onze/botopink.json` reads `"name": "onze"` and none of its `files` is `onze.bp`/`onze.mjs`
- [ ] `grep -rn onze13 specs/1.0.10-beta/` finds only `../unification.md` and the lines that name the rename itself (this step, `onze-migration.md` § *The rename checklist*, `../02-packaging/README.md` § 10)
- [ ] `zig build test-libs` from `repository/botopink-lang` no longer lists an `onze` cell for the old library

### Step 6 — the std sub-fronts

`01-std-lib-enablement/`, `02-std-async-primitives/` and `03-std-content-hash/`, their tests spelled
with `try asserts.…`.

**Acceptance:**
- [ ] each sub-front's own *Definition of done* holds

The box asking `root.bp` to carry the flat tree's export lines left with decision 106: `root.bp` is
the registry of step 7.

### Step 7 — `23-std-purity` moves the tree

Owned by `00-compiler-carry-over/23-std-purity`: `io/` and `testing/` with their `mod.bp`,
`collections.bp`, `hash.bp` and `encoding.bp` merged, `absolutePath`/`walk`/`glob` in `io/fs.bp`,
`randomBytes` in `io/random.bp`, `root.bp` the registry of `modules.md`, the
root-does-not-import-`io/` check, and the import grammar of decision 107.

**Acceptance:**
- [x] `libs/std/src/` matches `modules.md` § *The tree* file for file; `root.bp` has seventeen lines, `io/mod.bp` eight, `testing/mod.bp` three
- [x] `import {testing: {asserts, snapshots, mocks}} from "std";` resolves from a consumer package and only the three leaves enter scope
- [x] a root module that imports from `io/` is refused by the compiler, inside std, with no flag (`std-root-imports-io`, `00 · 23-std-purity` step 4)
- [x] every `from "std"` line in `repository/{rakun,jhonstart,emilia,erika,onze}` is rewritten per `modules.md` § *Old → new*; `zig build test-libs` green — rakun's eight source files and eleven test files; jhonstart, emilia, erika and onze import nothing from std
- [x] every std inline test is green at its new path on commonJS and erlang — 417 / 0 on each

### Step 8 — `04-routing-lib`: the bundled `routing` library

`libs/routing/` beside `libs/std/` (decision 115): the route matcher, the `k` and `z` blob codecs,
the URL rules, the navigation vocabulary and the `:param` grammar, pure and compiled for erlang and
commonJS, resolved by `from "routing"` as `from "std"` is. Specified in
[`04-routing-lib/README.md`](./04-routing-lib/README.md).

**Acceptance:**
- [ ] the sub-front's own *Gate* holds
- [ ] rakun front 22 and jhonstart front 26 import the matcher from `"routing"`, and no copy of it
      remains under `repository/` — **open:** rakun imports it (`file_router.bp`) and no copy remains; jhonstart's router (`router.bp`) takes the matched pattern from the payload and matches nothing yet — its client-side `matchPath` import is jhonstart 26's remaining work

### Step 9 — `05-actions-lib` and `06-validation-lib`: two more bundled libraries

Decision 116 rules 2 and 5. `libs/actions/` holds the server-action protocol both sides read and
write — the `state` grammar and `ActionState`, the v1 envelope, the JSON-RPC body, the `refresh`
value — with no wire name built in; rakun front 24 and jhonstart front 67 import it.
`libs/validation/` is rakun-validation moved: its message lookup is handed in (`setMessageSource`),
it imports std only, and rakun, onze and application code import it by name. Specified in
[`05-actions-lib/README.md`](./05-actions-lib/README.md) and
[`06-validation-lib/README.md`](./06-validation-lib/README.md).

**Acceptance:**
- [ ] each sub-front's own *Gate* holds
- [x] `grep -rn "rakun-validation" repository/ --include=*.bp --include=botopink.json` is empty, and
      no action-envelope or `state` literal is asserted under `repository/rakun/` or
      `repository/jhonstart/` (the literal lives in `libs/actions/test/`)

### Step 10 — std reads and writes JSON (`01-std-lib-enablement` Steps 11–14)

Decision 116 rules 3 and 8 and [decision 117](../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only) rules 6 and 7: `json.quote`,
`json.unquote`, `json.array`, `json.object`, `escape.scriptJson`, and the structured reader
`pub type Json { Null, Bool(bool), Num(f64), Str(string), Arr(Array<Json>), Obj(Array<#(string, Json)>) }`
with `json.decode(s: string) -> @Result<Json, string>`. rakun's configuration reader, the `actions`
library and jhonstart's payload reader read through `decode`.

**Acceptance:**
- [x] `01-std-lib-enablement`'s *Gate (Steps 11–14)* holds — std 417 / 0 on both rows

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in the compiler worktree (steps 1, 7, 8)
- [ ] `botopink test` and `botopink test --target erlang` green in `libs/std` (steps 2–4, 6, 7)
- [ ] `zig build test-libs` green — std, emilia, jhonstart, rakun, erika, and the new `onze`
- [ ] the compiler's `snapshots/codegen/{commonJS,erlang,beam,wasm}/` are byte-identical for every pre-existing fixture — `@src()` is additive
- [ ] `AGENTS.md` of every directory touched (`modules/compiler-core`, `comptime/`, `comptime/tests/`, `codegen/tests/`, `compiler-cli/src/cli/`, `libs/std/`), updated in the same commit
- [ ] `docs.md` gains `@src()` under *Builtins* and a *Tests* paragraph on `try`
- [ ] the seven remotes unified on `feat` at the end (meta + six submodules — the `onze` entry now the orchestrator)

## Ownership and conflicts

| Who | Files | Conflicts with |
|---|---|---|
| this front, step 1 | the compiler files in **Owns** | any 1.0.10 front that touches `infer.zig` sequences after it |
| this front, steps 2–4 | `testing/asserts.bp`, `testing/snapshots.bp`, `testing/mocks.bp`, `testing/mod.bp` | none |
| this front, step 5 | `.gitmodules`, `repository/onze` | `06-onze/49-onze-stand-up` — 49 creates the repository; this step swaps the submodule pointer. 49 cannot land before this step; this step cannot complete before 49's repository exists |
| `04-routing-lib` | `libs/routing/**`; by carve-out, the bundled-package list in `build.zig` and the bundled-package loading in the CLI and the LSP | nothing on `libs/std/**` |
| `05-actions-lib` · `06-validation-lib` | `libs/actions/**`, `libs/validation/**`; one name each in the bundled-package list | nothing on `libs/std/**` |

Tracks B–E consume `@src()`, `testing.asserts` and `testing.snapshots` and write their `-test`
submodules against [`snapshots.md`](./snapshots.md) § *How a library exposes helpers*. They do
not edit std.

## Not in this front

| Item | Why not here | Where it goes |
|---|---|---|
| Test lifecycle hooks `setup`/`teardown`/`setupAll`/`teardownAll` (`asserts-api.md` § *Migration table*) | the runner has no hook mechanism; a std fn cannot register one | a toolchain gap for `language-gaps.md`: "the test runner calls registered hook functions around each `test` block" |
| `isOkAnd`, `throwsType`, `typeOf` (`asserts-api.md` § *Migration table*) | need a `case` over `@Result` inside a result body, a typed catch, a type-name intrinsic (`@typeName<T>()`) — none exists | the corresponding `language-gaps.md` rows |
| `BOTOPINK_SNAP_CREATE=1` in the compiler's own harness (`utils/snap.zig`) | not this front's file; the std engine does not copy it | a question for the owner of `utils/snap.zig` |
| `@Decl` gaining a `SourceLocation` (`language-gaps.md`, front 22's row) | threading `SourceLocation` through decorator reflection is a separate compiler change | a follow-on compiler front |
