# Front 01 — std

**Track:** A — std
**Priority:** critical/blocking — every library test in the ecosystem is written against `@src()`, `std/testing/asserts` and `std/testing/snapshots`; until the three exist no `<lib>-test` submodule can be written, no `__snapshots__/` directory can be recorded, and no track can prove a front green
**Target:** both — `asserts` compiles on all four backends; `snapshots` runs on the two targets `botopink test` runs (commonJS, erlang); `@src()` lowers on all four
**Wave:** 0 — runs alone until step 1 lands, then steps 2–7 in the order below
**Depends on:** none. Step 1 is the one compiler change track A admits this milestone, and it is what every other front's tests are written against
**Owns:** compiler — `modules/compiler-core/src/comptime.zig` (`decl_reflection_src`), `comptime/infer.zig` (`inferBuiltinCallReturnType`, `inferFnDecl`, `inferTestDecl`), `comptime/env.zig` (`currentFnName`), `comptime/diagnostics.zig`, `comptime/error.zig`, `module.zig` (`srcPath`), `modules/compiler-cli/src/cli/scanner.zig` + `resolver.zig` (the `srcPath` plumb), and the new `snapshots/codegen/{commonJS,erlang,beam,wasm}/src_*.snap.md` fixtures · std — `libs/std/src/testing/asserts.bp` (rewrite), `libs/std/src/testing/snapshots.bp` (new), `libs/std/src/testing/mocks.bp` (new, lifted from the old onze), `libs/std/src/testing/mod.bp`, `libs/std/src/root.bp` (exports: `snapshots`, `mocks`, plus the lines fronts 01/02/03 hand over — the registry as it reads after step 7 is in `modules.md`), `libs/std/AGENTS.md` · meta — `.gitmodules` (the `repository/onze` entry is re-pointed, not removed), `repository/onze` (directory reused by the orchestrator) · specs — this directory
**Does not touch:** every other std module (`01-std-lib-enablement/`, `02-std-async-primitives/`, `03-std-content-hash/` own theirs; `00-compiler-carry-over/23-std-purity` owns the tree move of step 7); the codegen backends — `@src()` needs **no** backend change because it is rewritten into a record constructor before lowering; `repository/{rakun,jhonstart,emilia}` sources — their `-test` submodules are theirs and consume this contract
**Reference:** Zig `@src()` → `std.builtin.SourceLocation{module, file, fn_name, line, column}` · the compiler's own snapshot harness — `modules/compiler-core/src/codegen/tests/helpers.zig:38` (`slugify`), `:80` (`slugFromSrc`), `modules/compiler-core/src/utils/snap.zig:120-200` (`.new` on mismatch) · decision 67 — the most restrictive behaviour, and no configuration that bypasses it · decisions 106 and 107 — the std tree and the import grammar

---

## Problem

The test contract every track writes against — `@src()`, `SourceLocation`, `snapshots.path(loc)`,
`.new` files, no update flag — has no implementation. An unknown `@src()` in a `.bp` file types as
`void` in silence (`modules/compiler-core/src/comptime/infer.zig:4443`).

Three further facts make this the blocking front rather than a documentation gap:

- **`std/asserts` panics; the contract returns.** `libs/std/src/asserts.bp` has nine functions that
  `@panic` on failure and return nothing. A `-test` helper that must be `-> @Result<void, string>`
  cannot be built on a function that panics through it. Nothing outside std calls the module —
  `grep -rn "asserts\." --include=*.bp repository/` finds only `asserts.bp` itself — so the
  rewrite costs the ten inline tests in that file and nothing else.
- **The name `onze` is taken by the thing that is being removed.** `repository/onze/` is a
  Mockito-style mocking library (`src/onze.bp`, 187 lines; `src/onze.mjs`, 121 lines), and every
  track-E front writes `repository/onze/` as the orchestrator's home. `.gitmodules` points it at
  `git@github.com:botopink/onze.git`.
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
| enclosing fn name in `Env` | absent | `comptime/env.zig:423` `fnContext` holds only the effect anchor |
| module path in `Env` | present, `src/`-relative, no extension | `comptime/env.zig:379`; set at `comptime.zig:370`, `:465`; form documented at `compiler-cli/src/cli/scanner.zig:100-103` |
| `test` block emission | `__bp_test_{idx}`, `loc = "<module>.bp:<line>"` | `codegen/commonJS.zig:1518`, `:516-521`; `codegen/erlang.zig:3661` |
| `try` inside a `test` body | type-checks (`tryUnwrapOrError`); lowering into a FAIL line unverified | `comptime/infer.zig:6965-6969`; `codegen/commonJS.zig:615` (`TryForm.propagate`) |
| `std/asserts` | 9 panicking fns, 2 private host cells, 10 inline tests | `libs/std/src/asserts.bp` |
| `std/snapshots` | absent | `libs/std/src/root.bp:13-36` lists 24 modules, on the flat tree decision 106 replaces |
| old `onze` | present, green on commonJS + erlang, one consumer example in the specs | `repository/onze/`; `../03-rakun/19-rakun-test-utilities/examples/controller-test-example.bp:24` |
| `.snap.new` ignore rule | compiler repo ignores `*.snap.md.new`; no sibling repo ignores `*.snap.new` | `repository/botopink-lang/.gitignore`; `repository/emilia/.gitignore` |

## Documents

| File | Holds |
|---|---|
| [`src-builtin.md`](./src-builtin.md) | step 1 — `@src()`, `SourceLocation`, the test body as a fallible context, the compiler files and fixtures |
| [`asserts-api.md`](./asserts-api.md) | step 2 — the canonical `import {testing.asserts} from "std"` surface, failure messages, backend notes, the old-onze → std migration table |
| [`snapshots.md`](./snapshots.md) | step 3 — `snapshots.path(loc)`, the `.snap` format, `.new` on mismatch, the API, how a `<lib>-test` exposes `assert<Subject>` |
| [`onze-migration.md`](./onze-migration.md) | steps 4 and 5 — the inventory of `repository/onze`, where each symbol goes, the submodule swap, the `onze13 → onze` checklist |
| [`modules.md`](./modules.md) | the package cut for std — the three-category tree, the old → new path table, ownership, why std has no `-test` submodule |
| [`test-snap.md`](./test-snap.md) | the preventive snapshot-test map for std itself |
| [`examples/asserts-unit-example.bp`](./examples/asserts-unit-example.bp) | Example 1 — `std/testing/asserts` alone |
| [`examples/emilia-test-submodule-example.bp`](./examples/emilia-test-submodule-example.bp) · [`examples/emilia-test-consumer-example.bp`](./examples/emilia-test-consumer-example.bp) | Example 2 — an `emilia-test` submodule and the test file that consumes it with `@src()` |
| [`01-std-lib-enablement/`](./01-std-lib-enablement/README.md) · [`02-std-async-primitives/`](./02-std-async-primitives/README.md) · [`03-std-content-hash/`](./03-std-content-hash/README.md) | step 6 — the three std sub-fronts |
| [`04-routing-lib/`](./04-routing-lib/README.md) | step 8 — the second bundled library, `libs/routing` (decision 115): the route matcher, the `k` / `z` / URL-rule codecs, the navigation vocabulary and the `:param` grammar (decision 116) rakun and jhonstart both import |
| [`05-actions-lib/`](./05-actions-lib/README.md) · [`06-validation-lib/`](./06-validation-lib/README.md) | step 9 — the bundled libraries `libs/actions` (the server-action envelope, `state` grammar, JSON-RPC body, `refresh`) and `libs/validation` (rakun-validation moved, its message lookup injected) — decision 116 |
| [`01-std-lib-enablement/`](./01-std-lib-enablement/README.md) Steps 11–14 | step 10 — std reads and writes JSON: `json.quote` / `unquote` / `array` / `object`, `escape.scriptJson` (decision 116), the `Json` type and `json.decode` (decision 117) |

## Order

```
1  @src() + test-body `try`  (compiler; runs alone — every later step's tests use it)
   │
2  std/testing/asserts ──────┐
   │                         │
3  std/testing/snapshots ────┤   (3 uses 2's `@Result` channel; 2 does not use 3)
   │                         │
4  onze removal → testing/asserts (100 % of assertions) + testing/mocks (100 % of mocking)
   │
5  onze13 → onze namespace takeover (directory, .gitmodules, botopink.json, docs)
   │
6  01-std-lib-enablement · 02-std-async-primitives · 03-std-content-hash
   (02 and 03 first, 01 last — its root.bp commit carries every export line)
   │
7  00-compiler-carry-over/23-std-purity — the tree of modules.md: io/, testing/, the merges,
   the root-does-not-import-io check, the import grammar (decisions 106, 107)

8  04-routing-lib — libs/routing beside libs/std (decision 115): the library and its tests from
   step 2 on, beside steps 3–7; its compiler bundling after step 7

9  05-actions-lib · 06-validation-lib — libs/actions and libs/validation (decision 116): the
   libraries from step 2 on (actions after 01's encoding, 10 and 8's navigation); each bundled by
   adding its name to step 8's registry

10 01-std-lib-enablement Steps 11–14 — json.quote, the writers and json.decode from step 2 on;
   escape.scriptJson after 01's escape.bp; all outside the window in which step 7 holds
   libs/std/src/**
```

Step 1 is first because it is what the other steps verify with: `asserts.bp`'s own inline tests are
written with `try`, `snapshots.bp` cannot compute a path without a `SourceLocation`, and the
`-test` submodules of tracks B–E open the moment `@src()` types.

Every std file in steps 2–6 is named in this directory by its **final** path (`modules.md` § *The
tree*). The files land at `src/<name>.bp` on the tree as it stands when they merge; step 7 moves
them. Docblocks and import lines are written for the final path from the start, so the move is a
`git mv` plus the three merges (`collections`, `hash`, `encoding`).

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

### Step 2 — `std/testing/asserts`

Specified in [`asserts-api.md`](./asserts-api.md). `libs/std/src/testing/asserts.bp` is rewritten:
every assertion answers `@Result<void, string>`; the canonical names are
`isTrue`, `isFalse`, `equals`, `notEquals`, `approxEquals`, `isNil`, `isNotNil`, `isOk`, `isError`,
`contains`, `notContains`, `startsWith`, `endsWith`, `matches`, `isEmpty`, `isNotEmpty`,
`lengthIs`, `includes`, `notIncludes`, `between`, `greaterThan`, `lessThan`, `deepEquals`,
`throws`, `throwsWith`, `fail`. Failure messages are `asserts.<fn>: <what>`, one literal per
function. The module stays free of `pub declare fn` so it passes STD-001 on every target; the four
functions that need a host cell (`matches`, `deepEquals`, `throws`, `throwsWith`) use private cells
with Node and Erlang templates and the docblock names them.

**Acceptance:**
- [ ] `import {testing.asserts} from "std"` type-checks for `--target commonJS`, `erlang`, `beam` and `wasm` (STD-001 does not fire — no `pub declare fn` in the file)
- [ ] every function's pass and fail path is covered by an inline `test` at the foot of the file, written with `try`; the fail paths assert the literal message through `throws`/`throwsWith`
- [ ] `botopink test` in `libs/std` green on commonJS and erlang; `zig build test-libs` reads `std · commonJS: pass` and `std · erlang: pass`
- [ ] the old names (`truthy`, `falsy`, `equal`, `notEqual`, `approxEqual`, `AssertError`) are gone and `grep -rn "asserts\.\(truthy\|equal\b\)" --include=*.bp repository/` is empty
- [ ] `libs/std/AGENTS.md`'s `asserts` row lists the new surface

### Step 3 — `std/testing/snapshots`

Specified in [`snapshots.md`](./snapshots.md). New `libs/std/src/testing/snapshots.bp`: `path(loc)`,
`pathNamed(loc, name)`, `suiteOf(name)`, `slugOf(name)`, `assert(loc, actual)`, `assertAs(loc,
subject, actual)`, `assertNamed(loc, name, actual)`, `assertNamedAs(loc, name, subject, actual)`.
A mismatch or a missing file writes `<path>.new` and answers `Error`. There is no flag, no
environment variable and no manifest key that records a snapshot.

**Acceptance:**
- [ ] `snapshots.path(SourceLocation(file: "src/emilia.bp", line: 1, column: 1, fnName: "css: modifiers ---- hover on md breakpoint"))` answers `src/__snapshots__/css/modifiers_hover_on_md_breakpoint.snap` on both targets
- [ ] a name with no `": "` answers `Error("snapshots: test name needs a suite …")` — asserted, not assumed
- [ ] missing → `.new` written + `Error`; mismatch → `.new` written + `Error`; match → `Ok` and a stale `.new` deleted; each is an inline test running against a scratch `__snapshots__/` under the host tmpdir
- [ ] `grep -rn "SNAP_CREATE\|update" libs/std/src/testing/snapshots.bp` finds no code path that writes `<path>` itself
- [ ] `*.snap.new` is in `.gitignore` of `botopink-lang`, `rakun`, `jhonstart`, `emilia` and the new `onze`, and each repo's `scripts/git-hooks/pre-commit` refuses a staged `*.snap.new`

### Step 4 — remove the old `onze`, migrate 100 % of it

Specified in [`onze-migration.md`](./onze-migration.md). The assertion surface (`eq`, `anyInt`,
`anyString` are matchers, not assertions — see the inventory) goes to `std/testing/asserts`; the
mocking surface (`#[mock]`, `when`, `verify`, `thenReturn`, `thenThrow`, `times`, `never`,
`atLeastOnce`, the eight host cells) goes to `std/testing/mocks`, lifted verbatim (decision 71 —
one mocking module, in std). The `.mjs` sidecar is not carried: its module-global tables become a
`globalThis` cell in the Node templates, the same shape `emilia.bp:24` already uses.

**Acceptance:**
- [ ] every row of the inventory table in `onze-migration.md` has a destination and a test that exercises it there
- [ ] `repository/onze/test/onze_test.bp`'s eight tests pass, re-spelled against `std/testing/mocks`, as inline tests at the foot of `libs/std/src/testing/mocks.bp`, on commonJS and erlang
- [ ] `../03-rakun/19-rakun-test-utilities/examples/controller-test-example.bp:24` imports from `"std"` instead of `"onze"`
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
- [ ] `grep -rn onze13 specs/1.0.10-beta/` finds only `../unification.md` and the lines that name the rename itself (this step, `onze-migration.md` § *The rename checklist*, `../02-packaging/README.md` § 10)
- [ ] `zig build test-libs` from `repository/botopink-lang` no longer lists an `onze` cell for the old library

### Step 6 — the std sub-fronts

`01-std-lib-enablement/`, `02-std-async-primitives/` and `03-std-content-hash/`. Their steps,
acceptance and definition of done stand as written; their tests are spelled with `try asserts.…`.
Order within the step is 02 · 03 · 01 (01's `root.bp` commit carries `async`, `content_hash`, and
this front's `snapshots` and `mocks`).

**Acceptance:**
- [ ] each sub-front's own *Definition of done* holds
- [ ] `libs/std/src/root.bp` carries every export line handed over at this point: the twenty-four of the flat tree, `net`, `clock`, `encoding`, `hmac`, `escape`, `async`, `content_hash`, `snapshots`, `mocks`

### Step 7 — `23-std-purity` moves the tree

Owned by `00-compiler-carry-over/23-std-purity`, sequenced here because it moves this front's files
and the sub-fronts'. It creates `io/` and `testing/` with their `mod.bp`, merges `dict`/`sets`/
`queue`/`order` into `collections.bp`, `crypto`+`hmac`+`content_hash` into `hash.bp`,
`base64`+`encoding` into `encoding.bp`, moves `absolutePath`/`walk`/`glob` into `io/fs.bp` and
`randomBytes` into `io/random.bp`, rewrites `root.bp` to the registry in `modules.md`, adds the
root-does-not-import-`io/` check, and lands the import grammar of decision 107.

**Acceptance:**
- [x] `libs/std/src/` matches `modules.md` § *The tree* file for file; `root.bp` has seventeen lines, `io/mod.bp` eight, `testing/mod.bp` three
- [x] `import {testing: {asserts, snapshots, mocks}} from "std";` resolves from a consumer package and only the three leaves enter scope
- [x] a root module that imports from `io/` is refused by the compiler, inside std, with no flag (`std-root-imports-io`, `00 · 23-std-purity` step 4)
- [x] every `from "std"` line in `repository/{rakun,jhonstart,emilia,erika,onze}` is rewritten per `modules.md` § *Old → new*; `zig build test-libs` green — rakun's eight source files and eleven test files; jhonstart, emilia, erika and onze import nothing from std (three comments re-spelled)
- [x] every std inline test is green at its new path on commonJS and erlang — 417 / 0 on each

### Step 8 — `04-routing-lib`: the bundled `routing` library

`libs/routing/` beside `libs/std/` (decision 115): the route matcher ported from rakun's
`file_router.bp`, the `k` and `z` blob codecs and the URL rules, pure and compiled for erlang and
commonJS, and the compiler's std registry generalised into a bundled-package registry so
`from "routing"` resolves as `from "std"` does. Specified in
[`04-routing-lib/README.md`](./04-routing-lib/README.md). Its library steps need only step 2
(`testing.asserts`); its bundling step opens after step 7, because it rewrites the registry
`23-std-purity` rewrites.

**Acceptance:**
- [ ] the sub-front's own *Gate* holds
- [ ] rakun front 22 and jhonstart front 26 import the matcher from `"routing"`, and no copy of it
      remains under `repository/` — **open:** rakun imports it (`file_router.bp`, 2026-09-26) and no copy remains; jhonstart's router (`router.bp`) takes the matched pattern from the payload and matches nothing yet — its client-side `matchPath` import is jhonstart 26's remaining work

### Step 9 — `05-actions-lib` and `06-validation-lib`: two more bundled libraries

Decision 116 rules 2 and 5. `libs/actions/` holds the server-action protocol both sides read and
write — the `state` grammar and `ActionState`, the v1 envelope, the JSON-RPC body, the `refresh`
value — with no wire name built in; rakun front 24 and jhonstart front 67 import it. `libs/validation/`
is rakun front 14's `modules/rakun-validation` moved: its message lookup is handed in
(`setMessageSource`), it imports std only, and rakun, onze and application code import it by name.
Each is bundled by adding its name to step 8's registry. Specified in
[`05-actions-lib/README.md`](./05-actions-lib/README.md) and
[`06-validation-lib/README.md`](./06-validation-lib/README.md).

**Acceptance:**
- [ ] each sub-front's own *Gate* holds
- [x] `grep -rn "rakun-validation" repository/ --include=*.bp --include=botopink.json` is empty, and
      no action-envelope or `state` literal is asserted under `repository/rakun/` or
      `repository/jhonstart/` — measured 2026-09-26: rakun's member is deleted, and no envelope or `state` literal is asserted under rakun or jhonstart (the literal lives in `libs/actions/test/`)

### Step 10 — std reads and writes JSON (`01-std-lib-enablement` Steps 11–14)

Decision 116 rules 3 and 8 and [decision 117](../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only) rules 6 and 7: `json.quote` (every
control character escaped), `json.unquote`, `json.array`, `json.object`, `escape.scriptJson`, and a
structured reader — `pub type Json { Null, Bool(bool), Num(f64), Str(string), Arr(Array<Json>),
Obj(Array<#(string, Json)>) }` with `json.decode(s: string) -> @Result<Json, string>`. rakun's
configuration reader, the `actions` library and jhonstart's payload reader read through `decode`.
Specified as Steps 11–14 of [`01-std-lib-enablement/README.md`](./01-std-lib-enablement/README.md),
which carry their own ownership lines; `scriptJson` is appended to that front's `escape.bp` after its
Step 1.

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
| this front, step 1 | the compiler files in **Owns** | nothing in track A; any 1.0.10 front that touches `infer.zig` sequences after it |
| this front, steps 2–4 | `testing/asserts.bp`, `testing/snapshots.bp`, `testing/mocks.bp`, `testing/mod.bp`, `root.bp` (two lines) | `01-std-lib-enablement` on `root.bp` — resolved by order: 01 commits last and carries the lines |
| this front, step 5 | `.gitmodules`, `repository/onze` | `06-onze/49-onze-stand-up` — 49 creates the repository; this step swaps the submodule pointer. 49 cannot land before this step; this step cannot complete before 49's repository exists |
| `02`, `03` | `async.bp`, the content-hash half of `hash.bp` | none |
| `01-std-lib-enablement` | `io/net.bp`, `escape.bp`, the hmac half of `hash.bp`, the codec half of `encoding.bp`, additions to six existing modules, `root.bp`, `io/mod.bp` | none once ordered |
| `04-routing-lib` | `libs/routing/**`; by carve-out, the bundled-package registry in `build.zig` and the `"std"` package checks in compiler-core, the CLI resolver and the LSP (named in its README) | `00 · 23-std-purity` on `build.zig`'s registry and `emitUse` — resolved by order: its Step 2 opens after 23 lands; nothing on `libs/std/**` |
| `05-actions-lib` · `06-validation-lib` | `libs/actions/**`, `libs/validation/**`; one name each in the bundled-package list | `04-routing-lib` on that list — resolved by order: each adds its name after 04's Step 2; nothing on `libs/std/**` |
| `01-std-lib-enablement` Steps 11–14 | the functions, `Json` and `decode` at the foot of `json.bp`; `scriptJson` appended to `escape.bp` | Step 1 on `escape.bp` — resolved by order: Step 12 appends after Step 1; `00 · 23-std-purity` — these steps land before 23 opens or after it lands |
| `00-compiler-carry-over/23-std-purity` | every path under `libs/std/src/` (the move), `root.bp`, `build.zig` `stdPkgFilesFromRoot`, `parser/decls.zig`, `project_graph.zig`, `emitUse` ×4 | runs after steps 2–6 and after `.tasks/std-async` has merged; nothing else in track A edits std after it |

Tracks B–E consume `@src()`, `testing.asserts` and `testing.snapshots` and write their `-test`
submodules against [`snapshots.md`](./snapshots.md) § *How a library exposes helpers*. They do
not edit std.

## Blast radius

- **Compiler:** one new builtin, one new record in the reflection prelude, one new diagnostic
  replacing a silent fallback, one new `Env` field. Every pre-existing snapshot stays byte-identical.
  The `unknown-builtin` diagnostic can red a program that today compiles a typo to `void` — that is
  the point, and `zig build test-libs` is the measurement.
- **std:** `asserts.bp` changes shape (return type, names). Zero external callers. The ten inline
  tests are rewritten. Step 7 moves every file under `src/`; the sibling libraries' `from "std"`
  lines change once, per `modules.md` § *Old → new*.
- **Ecosystem:** `repository/onze` changes identity. One spec example imports mocks from it
  (front 19's); it moves to `std`. The old repository stays reachable by tag.
- **Snapshots on disk:** none exist yet under any `__snapshots__/`; this front creates the first
  ones (std's own, `test-snap.md`).

## Not in this front

| Item | Why not here | Where it goes |
|---|---|---|
| Test lifecycle hooks `setup`/`teardown`/`setupAll`/`teardownAll` (`asserts-api.md` § *Migration table*) | the runner (`cli/test_cmd.zig`, `commonJS.zig:473-521`, `erlang.zig:1402-1407`) has no hook mechanism; a std fn cannot register one | a toolchain gap for `language-gaps.md`: "the test runner calls registered hook functions around each `test` block" |
| `isOkAnd`, `throwsType`, `typeOf` (`asserts-api.md` § *Migration table*) | need a `case` over `@Result` inside a result body, a typed catch, a type-name intrinsic (`@typeName<T>()`) — none exists | the corresponding `language-gaps.md` rows |
| `BOTOPINK_SNAP_CREATE=1` in the compiler's own harness (`utils/snap.zig:139-143`) | not this front's file; the std engine simply does not copy it | a question for the owner of `utils/snap.zig`, recorded here |
| `@Decl` gaining a `SourceLocation` (`language-gaps.md`, front 22's row) | `SourceLocation` now exists; threading it through decorator reflection is a separate compiler change | a follow-on compiler front |
| `mocks.verify:` message prefix (today `onze.verify:`; `test-snap.md` § `mocks.bp`) | kept for one milestone so old test output still greps | the next std front re-records one snapshot |
| `tokensToCss` made `pub` in emilia core (`examples/emilia-test-submodule-example.bp`) | emilia's file, track D's front | `05-emilia` — one line, and front 56 replaces it anyway |
