# Front 01 — std

**Track:** A — std
**Priority:** critical/blocking — every library test in the ecosystem is written against `@src()`, `std/asserts` and `std/snapshots`; until the three exist no `<lib>-test` submodule can be written, no `__snapshots__/` directory can be recorded, and no track can prove a front green
**Target:** both — `asserts` compiles on all four backends; `snapshots` runs on the two targets `botopink test` runs (commonJS, erlang); `@src()` lowers on all four
**Wave:** 0 — runs alone until step 1 lands, then steps 2–6 in the order below
**Depends on:** none. Step 1 is the one compiler change track A admits this milestone, and it is what every other front's tests are written against
**Owns:** compiler — `modules/compiler-core/src/comptime.zig` (`decl_reflection_src`), `comptime/infer.zig` (`inferBuiltinCallReturnType`, `inferFnDecl`, `inferTestDecl`), `comptime/env.zig` (`currentFnName`), `comptime/diagnostics.zig`, `comptime/error.zig`, `module.zig` (`srcPath`), `modules/compiler-cli/src/cli/scanner.zig` + `resolver.zig` (the `srcPath` plumb), and the new `snapshots/codegen/{commonJS,erlang,beam,wasm}/src_*.snap.md` fixtures · std — `libs/std/src/asserts.bp` (rewrite), `libs/std/src/snapshots.bp` (new), `libs/std/src/mocks.bp` (new, lifted from the old onze), `libs/std/src/root.bp` (exports: `snapshots`, `mocks`, plus the seven lines fronts 01/02/03 hand over), `libs/std/AGENTS.md` · meta — `.gitmodules` (the `repository/onze` entry is re-pointed, not removed), `repository/onze` (directory reused by the orchestrator) · specs — this directory
**Does not touch:** every other std module (`01-std-lib-enablement/`, `02-std-async-primitives/`, `03-std-content-hash/` own theirs); the codegen backends — `@src()` needs **no** backend change because it is rewritten into a record constructor before lowering; `repository/{rakun,jhonstart,emilia}` sources — their `-test` submodules are theirs and consume this contract
**Reference:** Zig `@src()` → `std.builtin.SourceLocation{module, file, fn_name, line, column}` · the compiler's own snapshot harness — `modules/compiler-core/src/codegen/tests/helpers.zig:38` (`slugify`), `:80` (`slugFromSrc`), `modules/compiler-core/src/utils/snap.zig:120-200` (`.new` on mismatch) · 1.0.5-beta decision 67 (`specs/1.0.5-beta/decisions-taken.md:2214`) — the most restrictive behaviour, and no configuration that bypasses it · `specs/1.0.9-beta/tracks/README.md` § *The test contract every track writes against*
**Replaces:** the never-written `1.0.9-beta/96-src-builtin-and-snapshots` and `1.0.9-beta/tracks/std/{asserts,snapshots,modules}.md`; the std/asserts half of `1.0.9-beta/95-ecosystem-package-restructure`; carries `1.0.9-beta/01`, `02`, `03` verbatim as sub-directories

---

## Problem

`specs/1.0.9-beta/tracks/README.md:26-44` fixes a test contract — `@src()`, `SourceLocation`,
`snapshots.path(loc)`, `.new` files, no update flag — and every track's `test-snap.md` was to be
written against it. Neither the front that specifies it (`96-src-builtin-and-snapshots`) nor the
three reference documents (`tracks/std/asserts.md`, `snapshots.md`, `modules.md`) were ever written.
Measured 2026-09-20: `specs/1.0.9-beta/tracks/` holds one file, `README.md`; there is no `96-` directory;
`grep -rn "@src" repository/botopink-lang/docs.md libs/std/src/builtins.d.bp` returns nothing; an
unknown `@src()` in a `.bp` file today types as `void` in silence
(`modules/compiler-core/src/comptime/infer.zig:4443`).

Three further facts make this the blocking front rather than a documentation gap:

- **`std/asserts` panics; the contract returns.** `libs/std/src/asserts.bp` has nine functions that
  `@panic` on failure and return nothing. A `-test` helper that must be `-> @Result<void, string>`
  cannot be built on a function that panics through it. Nothing outside std calls the module —
  `grep -rn "asserts\." --include=*.bp repository/` finds only `asserts.bp` itself — so the
  rewrite costs the ten inline tests in that file and nothing else.
- **The name `onze` is taken by the thing that is being removed.** `repository/onze/` is a
  Mockito-style mocking library (`src/onze.bp`, 187 lines; `src/onze.mjs`, 121 lines). Every
  track-E front of 1.0.9 (`49`–`53`, `68`–`71`) already writes `repository/onze/` as the
  orchestrator's home — front 49's README says the directory "does not exist". On disk it does,
  and it holds the old library; `.gitmodules` points it at `git@github.com:botopink/onze.git`.
- **Snapshots today have an escape hatch.** The compiler's own harness writes `<snap>.new` on
  mismatch (`utils/snap.zig:175`), but also records a missing snapshot outright when
  `BOTOPINK_SNAP_CREATE=1` is set (`snap.zig:139-143`). Decision 67 forbids exactly that shape for
  the ecosystem engine: a person renames the `.new` file, and there is no flag.

## Current state

Verified by reading the trees at HEAD `b5ceb203` (meta) on 2026-09-20.

| Piece | State | Evidence |
|---|---|---|
| `@src()` | absent; unknown builtins type as `void` | `comptime/infer.zig:4246-4443` — no arm, silent fallback |
| `SourceLocation` | absent | `comptime.zig:576-594` (`decl_reflection_src`) has `Span(start, end, line)` and nothing with a file |
| enclosing fn name in `Env` | absent | `comptime/env.zig:423` `fnContext` holds only the `@Context` anchor |
| module path in `Env` | present, `src/`-relative, no extension | `comptime/env.zig:379`; set at `comptime.zig:370`, `:465`; form documented at `compiler-cli/src/cli/scanner.zig:100-103` |
| `test` block emission | `__bp_test_{idx}`, `loc = "<module>.bp:<line>"` | `codegen/commonJS.zig:1518`, `:516-521`; `codegen/erlang.zig:3661` |
| `try` inside a `test` body | type-checks (`tryUnwrapOrError`); lowering into a FAIL line unverified | `comptime/infer.zig:6965-6969`; `codegen/commonJS.zig:615` (`TryForm.propagate`) |
| `std/asserts` | 9 panicking fns, 2 private host cells, 10 inline tests | `libs/std/src/asserts.bp` |
| `std/snapshots` | absent | `libs/std/src/root.bp:13-36` lists 24 modules |
| old `onze` | present, green on commonJS + erlang, one consumer example in the specs | `repository/onze/`; `specs/1.0.9-beta/19-rakun-test-utilities/examples/controller-test-example.bp:24` |
| `onze13` | only as `**Replaces:** 1.0.7-beta/…-onze13-…` lines and in `95`/`overview.md` prose | `grep -rn onze13 specs/1.0.9-beta` |
| `.snap.new` ignore rule | compiler repo ignores `*.snap.md.new`; no sibling repo ignores `*.snap.new` | `repository/botopink-lang/.gitignore`; `repository/emilia/.gitignore` |

## Documents

| File | Holds |
|---|---|
| [`src-builtin.md`](./src-builtin.md) | step 1 — `@src()`, `SourceLocation`, the test body as a fallible context, the compiler files and fixtures |
| [`asserts-api.md`](./asserts-api.md) | step 2 — the canonical `import {asserts} from "std"` surface, failure messages, backend notes, the old-onze → std migration table |
| [`snapshots.md`](./snapshots.md) | step 3 — `snapshots.path(loc)`, the `.snap` format, `.new` on mismatch, the API, how a `<lib>-test` exposes `assert<Subject>` |
| [`onze-migration.md`](./onze-migration.md) | steps 4 and 5 — the inventory of `repository/onze`, where each symbol goes, the submodule swap, the `onze13 → onze` checklist |
| [`modules.md`](./modules.md) | the package cut for std — why std has no `-test` submodule |
| [`test-snap.md`](./test-snap.md) | the preventive snapshot-test map for std itself |
| [`unification.md`](./unification.md) | every absorbed source and where it now lives |
| [`examples/asserts-unit-example.bp`](./examples/asserts-unit-example.bp) | Example 1 — `std/asserts` alone |
| [`examples/emilia-test-submodule-example.bp`](./examples/emilia-test-submodule-example.bp) · [`examples/emilia-test-consumer-example.bp`](./examples/emilia-test-consumer-example.bp) | Example 2 — an `emilia-test` submodule and the test file that consumes it with `@src()` |
| [`01-std-lib-enablement/`](./01-std-lib-enablement/README.md) · [`02-std-async-primitives/`](./02-std-async-primitives/README.md) · [`03-std-content-hash/`](./03-std-content-hash/README.md) | step 6 — the 1.0.9 std fronts, copied verbatim |

## Order

```
1  @src() + test-body `try`  (compiler; runs alone — every later step's tests use it)
   │
2  std/asserts ──────┐
   │                 │
3  std/snapshots ────┤   (3 uses 2's `@Result` channel; 2 does not use 3)
   │                 │
4  onze removal → std/asserts (100 % of assertions) + std/mocks (100 % of mocking)
   │
5  onze13 → onze namespace takeover (directory, .gitmodules, botopink.json, docs)
   │
6  01-std-lib-enablement · 02-std-async-primitives · 03-std-content-hash
   (02 and 03 first, 01 last — its root.bp commit carries every export line)
```

Step 1 is first because it is what the other five verify with: `asserts.bp`'s own inline tests are
written with `try`, `snapshots.bp` cannot compute a path without a `SourceLocation`, and the
`-test` submodules of tracks B–E open the moment `@src()` types. Nothing in steps 2–6 can be shown
green before it.

## Steps

### Step 1 — `@src()` and the test body as a fallible context

Specified in full in [`src-builtin.md`](./src-builtin.md). Summary: `pub type SourceLocation(file:
string, line: i32, column: i32, fnName: string)` joins the reflection prelude
(`comptime.zig:576`); `@src()` gets an arm in `inferBuiltinCallReturnType` (`infer.zig:4246`) that
rewrites the call, at inference time, into the ordinary constructor call
`SourceLocation(file: "…", line: N, column: C, fnName: "…")` — so every backend lowers it through
the record-constructor path it already has and no codegen file changes. The silent `void` fallback
at `infer.zig:4443` becomes the diagnostic `unknown-builtin`. A `try` on an `Error` inside a `test`
body ends the test as `FAIL` with the error string as the message.

**Acceptance:**
- [ ] `val loc = @src();` inside `test "x: y"` in `src/a.bp` at line 12 column 15 lowers, on all four backends, to the same code as `SourceLocation(file: "src/a.bp", line: 12, column: 15, fnName: "x: y")` — four `src_*.snap.md` fixtures byte-identical to the hand-written constructor's
- [ ] `@src(1)` → `error[src-takes-no-arguments]`; `@nope()` → `error[unknown-builtin]`, both located
- [ ] `fnName` is the test name inside a `test`, the fn name inside a `fn`, `Type.method` inside a method, `""` at module level — one snapshot per position
- [ ] `test "t: fails" { try failing(); }` prints `FAIL t: fails (<error string>) at src/a.bp:N` on commonJS and erlang — `codegen/tests/builtins.zig` gains a run-log fixture for each
- [ ] `docs.md` § Builtins and `libs/std/src/builtins.d.bp` document `@src()` and `SourceLocation`; `vscode-extension/syntaxes/botopink.tmLanguage.json` highlights `@src`
- [ ] `zig build test` green from a cold cache

### Step 2 — `std/asserts`

Specified in [`asserts-api.md`](./asserts-api.md). `libs/std/src/asserts.bp` is rewritten: every
assertion is `#[@result]` and answers `@Result<void, string>`; the canonical names are `isTrue`,
`isFalse`, `equals`, `notEquals`, `approxEquals`, `isNil`, `isNotNil`, `isOk`, `isError`,
`contains`, `notContains`, `startsWith`, `endsWith`, `matches`, `isEmpty`, `isNotEmpty`,
`lengthIs`, `includes`, `notIncludes`, `between`, `greaterThan`, `lessThan`, `deepEquals`,
`throws`, `throwsWith`, `fail`. Failure messages are `asserts.<fn>: <what>`, one literal per
function. The module stays free of `pub declare fn` so it passes STD-001 on every target; the four
functions that need a host cell (`matches`, `deepEquals`, `throws`, `throwsWith`) use private cells
with Node and Erlang templates and the docblock names them.

**Acceptance:**
- [ ] `import {asserts} from "std"` type-checks for `--target commonJS`, `erlang`, `beam` and `wasm` (STD-001 does not fire — no `pub declare fn` in the file)
- [ ] every function's pass and fail path is covered by an inline `test` at the foot of the file, written with `try`; the fail paths assert the literal message through `throws`/`throwsWith`
- [ ] `botopink test` in `libs/std` green on commonJS and erlang; `zig build test-libs` reads `std · commonJS: pass` and `std · erlang: pass`
- [ ] the old names (`truthy`, `falsy`, `equal`, `notEqual`, `approxEqual`, `AssertError`) are gone and `grep -rn "asserts\.\(truthy\|equal\b\)" --include=*.bp repository/` is empty
- [ ] `libs/std/AGENTS.md`'s `asserts` row lists the new surface

### Step 3 — `std/snapshots`

Specified in [`snapshots.md`](./snapshots.md). New `libs/std/src/snapshots.bp`: `path(loc)`,
`pathNamed(loc, name)`, `suiteOf(name)`, `slugOf(name)`, `assert(loc, actual)`, `assertAs(loc,
subject, actual)`, `assertNamed(loc, name, actual)`, `assertNamedAs(loc, name, subject, actual)`.
A mismatch or a missing file writes `<path>.new` and answers `Error`. There is no flag, no
environment variable and no manifest key that records a snapshot.

**Acceptance:**
- [ ] `snapshots.path(SourceLocation(file: "src/emilia.bp", line: 1, column: 1, fnName: "css: modifiers ---- hover on md breakpoint"))` answers `src/__snapshots__/css/modifiers_hover_on_md_breakpoint.snap` on both targets
- [ ] a name with no `": "` answers `Error("snapshots: test name needs a suite …")` — asserted, not assumed
- [ ] missing → `.new` written + `Error`; mismatch → `.new` written + `Error`; match → `Ok` and a stale `.new` deleted; each is an inline test running against a scratch `__snapshots__/` under the host tmpdir
- [ ] `grep -rn "SNAP_CREATE\|update" libs/std/src/snapshots.bp` finds no code path that writes `<path>` itself
- [ ] `*.snap.new` is in `.gitignore` of `botopink-lang`, `rakun`, `jhonstart`, `emilia` and the new `onze`, and each repo's `scripts/git-hooks/pre-commit` refuses a staged `*.snap.new`

### Step 4 — remove the old `onze`, migrate 100 % of it

Specified in [`onze-migration.md`](./onze-migration.md). The assertion surface (`eq`, `anyInt`,
`anyString` are matchers, not assertions — see the inventory) goes to `std/asserts`; the mocking
surface (`#[mock]`, `when`, `verify`, `thenReturn`, `thenThrow`, `times`, `never`, `atLeastOnce`,
the eight host cells) goes to a new `std/mocks` module, lifted verbatim. **Recommendation: `std/mocks`,
not the `<lib>-test` submodules** — the argument is in `onze-migration.md` § *Where the mocking
surface goes*. The `.mjs` sidecar is not carried: its module-global tables become a `globalThis`
cell in the Node templates, the same shape `emilia.bp:24` already uses.

**Acceptance:**
- [ ] every row of the inventory table in `onze-migration.md` has a destination and a test that exercises it there
- [ ] `repository/onze/test/onze_test.bp`'s eight tests pass, re-spelled against `std/mocks`, as inline tests at the foot of `libs/std/src/mocks.bp`, on commonJS and erlang
- [ ] `specs/1.0.9-beta/19-rakun-test-utilities/examples/controller-test-example.bp:24` and its 1.0.10 copy import from `"std"` instead of `"onze"`
- [ ] no `.mjs` file is added under `libs/std/src/sidecars/`
- [ ] `grep -rn 'from "onze"' --include=*.bp repository/ specs/1.0.10-beta/` finds only orchestrator imports

### Step 5 — `onze13 → onze` namespace takeover

Specified in [`onze-migration.md`](./onze-migration.md) § *The rename checklist*. The
`repository/onze` submodule entry is re-pointed at the orchestrator's repository (created by front
49 under the name `onze`); the old library's last commit is tagged in its own repository and the
repository is archived on the remote, not vendored under `repository/_archived/` — a directory the
build would otherwise scan.

**Acceptance:**
- [ ] `.gitmodules` has one `repository/onze` entry and it resolves to the orchestrator
- [ ] `repository/onze/botopink.json` reads `"name": "onze"` and none of its `files` is `onze.bp`/`onze.mjs`
- [ ] `grep -rn onze13 specs/1.0.10-beta/` finds only `**Replaces:**` lines and `unification.md`
- [ ] `zig build test-libs` from `repository/botopink-lang` no longer lists an `onze` cell for the old library

### Step 6 — the copied std fronts

`01-std-lib-enablement/`, `02-std-async-primitives/` and `03-std-content-hash/` are the 1.0.9 fronts,
unchanged. Their steps, acceptance and definition of done stand as written; their tests are
re-spelled with `try asserts.…` where they would otherwise `assert`, which is a mechanical change
each front makes in its own file. Order within the step is 02 · 03 · 01 (01's `root.bp` commit
carries `async`, `content_hash`, and this front's `snapshots` and `mocks`).

**Acceptance:**
- [ ] each sub-front's own *Definition of done* holds
- [ ] `libs/std/src/root.bp` declares thirty-three modules: the twenty-four of today, `net`, `clock`, `encoding`, `hmac`, `escape`, `async`, `content_hash`, `snapshots`, `mocks`
- [ ] `unification.md` records that nothing from `1.0.7-beta/17` and `18` is missing from the copies

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in the compiler worktree (step 1)
- [ ] `botopink test` and `botopink test --target erlang` green in `libs/std` (steps 2–4, 6)
- [ ] `zig build test-libs` green — std, emilia, jhonstart, rakun, erika, and the new `onze`
- [ ] the compiler's `snapshots/codegen/{commonJS,erlang,beam,wasm}/` are byte-identical for every pre-existing fixture — `@src()` is additive
- [ ] `AGENTS.md` of every directory touched (`modules/compiler-core`, `comptime/`, `comptime/tests/`, `codegen/tests/`, `compiler-cli/src/cli/`, `libs/std/`), updated in the same commit
- [ ] `docs.md` gains `@src()` under *Builtins* and a *Tests* paragraph on `try`
- [ ] the seven remotes unified on `feat` at the end (meta + six submodules — the `onze` entry now the orchestrator)

## Ownership and conflicts

| Who | Files | Conflicts with |
|---|---|---|
| this front, step 1 | the compiler files in **Owns** | nothing in track A; any 1.0.10 front that touches `infer.zig` sequences after it |
| this front, steps 2–4 | `asserts.bp`, `snapshots.bp`, `mocks.bp`, `root.bp` (two lines) | `01-std-lib-enablement` on `root.bp` — resolved by order: 01 commits last and carries the lines |
| this front, step 5 | `.gitmodules`, `repository/onze` | `06-onze/49-onze-stand-up` — 49 creates the repository; this step swaps the submodule pointer. 49 cannot land before this step; this step cannot complete before 49's repository exists |
| `02`, `03` | `async.bp`, `content_hash.bp` | none |
| `01-std-lib-enablement` | its nine modules + `root.bp` | none once ordered |

Tracks B–E consume `@src()`, `asserts` and `snapshots` and write their `-test` submodules against
[`snapshots.md`](./snapshots.md) § *How a library exposes helpers*. They do not edit std.

## Blast radius

- **Compiler:** one new builtin, one new record in the reflection prelude, one new diagnostic
  replacing a silent fallback, one new `Env` field. Every pre-existing snapshot stays byte-identical.
  The `unknown-builtin` diagnostic can red a program that today compiles a typo to `void` — that is
  the point, and `zig build test-libs` is the measurement.
- **std:** `asserts.bp` changes shape (return type, names). Zero external callers. The ten inline
  tests are rewritten.
- **Ecosystem:** `repository/onze` changes identity. One spec example imports mocks from it
  (front 19's); it moves to `std`. The old repository stays reachable by tag.
- **Snapshots on disk:** none exist yet under any `__snapshots__/`; this front creates the first
  ones (std's own, `test-snap.md`).

## Notes

- **Why `asserts` returns instead of panicking.** A `-test` helper is `-> @Result<void, string>` by
  contract; a panic inside it bypasses the caller's `try`, cannot be composed (`throws` could not be
  written over it without a host cell), and cannot carry a location. `@Result` + `try` at the call
  site gives the runner a message and a line for free.
- **Why `std/mocks` and not `<lib>-test`.** The mocking runtime is lib-agnostic, its erlang and
  node templates have to stay in step by hand, and the first `-test` submodule to absorb it would
  become a dependency of every other library's tests. One copy, in std, next to `asserts`. Detailed
  in `onze-migration.md`.
- **Why the old library is archived remotely, not under `repository/_archived/`.** 1.0.9's front 95
  proposed `repository/_archived/onze-mock/`. A checked-out directory is scanned by `zig build
  test-libs` and read by every `grep -rn` in a gate; an archived remote with a tag is reachable and
  invisible. Nothing in it is needed after step 4 lands: `std/mocks` is the code.
- **What is deliberately not here.** Test lifecycle hooks (`setup`/`teardown`, 1.0.9 front 95
  § *Test lifecycle*) need runner support and are a toolchain gap, recorded in `unification.md`.
  `typeOf` needs a type-name intrinsic that does not exist (`language-gaps.md` — no `@typeName<T>()`).
