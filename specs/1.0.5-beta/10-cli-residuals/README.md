# Front 10 — cli-residuals

**Priority:** medium — one user-facing defect is fully implemented and parked because a documentation
fence reds; the rest of the directory has had no owner since 1.0.4-beta's front 05 delivered.
**Depends on:** [`08-hygiene`](../08-hygiene/README.md) step 3.3 — the `docs.md:78` edit, which is the
only thing between step 1 and a commit. Nothing else blocks
**Owns:** `modules/compiler-cli/**` **except** `src/cli/build.zig` and `src/cli/run.zig`
([`13-module-identity`](../13-module-identity/README.md) owns those two — the output layout and
`botopink run --target erlang`) · `modules/lib-test-runner/**` where a fix needs it · this directory ·
no snapshot directory
**Does not touch:** `modules/compiler-core/src/**` ([`01-checker`](../01-checker/README.md), 02–05) ·
`modules/language-server/**` ([`11-tooling`](../11-tooling/README.md)) · `libs/std/**`, `examples/**`,
`docs.md`, `README.md` ([`08-hygiene`](../08-hygiene/README.md)) · `scripts/**`, `build.zig`,
`.github/**` · the sibling repositories under `repository/`
([`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md))

Paths are relative to `repository/botopink-lang/`; `main.zig` and `cli/*.zig` live under
`modules/compiler-cli/src/`. Measured at `botopink-lang` `c2dd780` (2026-09-18).

---

## What 1.0.4-beta's front 20 delivered, verified here

| # | Defect | State at `c2dd780` |
|---|---|---|
| B | `botopink new`'s template compiled to a program that printed nothing | **closed** (`de4aa87`). `botopink new hello && cd hello && botopink run` prints `Hello, world!`; the template is a `greet` fn plus `@print(greet("world"))` |
| C | a library could not ship an erlang host module | **closed** (`c01695f`). `libs.shipErlSidecars` exists (`cli/libs.zig:564`, the erlang twin of `shipMjsSidecars:415`) and is wired into `botopink test` (`cli/test_cmd.zig:189`). **`build`/`run` are not** — see [R2](#r2-buildrun-does-not-ship-an-erl-sidecar) |
| D | a missing dependency and an unreadable `files` entry swallowed with `catch continue` | **CLI half closed** (1.0.4-beta 05); **language-server half closed** by `84e493a` — `project_graph.zig:67` now carries the comment "Both failures used to be `catch continue`". A **third** site survives — see [R3](#r3-a-third-catch-continue-in-project_graphzig) |
| A | an `import` naming a module that does not exist passes `check` **and** `build` in silence | **open, and implemented** — see [R1](#r1-an-import-that-names-nothing-is-still-silent) |

## Problem

### R1 — an `import` that names nothing is still silent

Reproduced at `c2dd780` in a scratch project outside any repository, whose only module is

```botopink
import {area} from "geometry";

pub fn main() {
  @print("hi");
}
```

with no module and no dependency named `geometry`:

```
$ botopink check ; echo $?
  Checking 1 module(s)...
   Checked in 61.54ms
0
$ botopink build ; echo $?
  Compiling 1 module(s)...
   Compiled in 64.05ms
0
$ ls out/
main.js
```

The *other* half already reds: with `mod geometry;` declared and `geometry.bp` exporting only
`perimeter`, `import {area} from "geometry";` gives `error: imported symbol is not exported by the
named module` and exit 1 — but with no location.

**The fix is written, verified and parked.** `git stash list` in `botopink-lang`:

```
stash@{0}: On fix/cli: front 20 defect A — unresolved import source is a located error (blocked on docs.md:78)
```

231 lines in `cli/resolver.zig`, 29 in `cli/sources.zig`, plus two `AGENTS.md`s. The branch
`fix/cli` and its worktree `.tasks/cli` (at `c01695f`) still exist.

**Mechanism.** `cli/resolver.zig` runs two import passes — F2 (path visibility, `:394`) and F3
(import resolution through the tree, `:426`). F3's guard is

```zig
:443            const target = analysis.paths.get(from) orelse continue; // not a package module
```

so a `from` naming nothing at all falls straight through, by design: the resolver could not tell a
dependency from a typo, having never been told the dependency set. Downstream, the comptime pipeline's
`resolveImports` binds an imported name by *searching* the export registry and simply not binding when
nothing matches — no diagnostic, and that file is [`01-checker`](../01-checker/README.md)'s.

The answer belongs in the CLI, which holds both halves of the question: the module tree and
`botopink.json`'s `dependencies`. Because every command loads `src/` through `sources.load`, one check
there covers `build`, `check` and `test` — which the command contract already requires to agree.

`ast.ImportDecl` carries no `Loc`, and adding one is [`01-checker`](../01-checker/README.md)'s file.
The location is read instead off the token stream the resolver already produces: `from` is a keyword of
its own and occurs only in an import, so the n-th `from` + string-literal pair belongs to the n-th
`import … from` the parser reports. `resolver.Diagnostic` (`:29-40`) has `kind`, `name`,
`declared_in`, `sibling`, `folder`, `importer`, `target` — and no `file`/`line`/`col`.

<a id="r2-buildrun-does-not-ship-an-erl-sidecar"></a>

### R2 — `build`/`run` does not ship an `.erl` sidecar

```
$ grep -n 'ship.*Sidecars' modules/compiler-cli/src/cli/*.zig
build.zig:215:        libs.shipMjsSidecars(gpa, io, outputs, out_dir, ext, env_map) catch {};
libs.zig:415:pub fn shipMjsSidecars(
libs.zig:564:pub fn shipErlSidecars(
test_cmd.zig:180:        libs.shipMjsSidecars(gpa, io, outputs.items, TEST_OUT_DIR, ext, env_map) catch {};
test_cmd.zig:189:        _ = libs.shipErlSidecars(gpa, io, outputs.items, TEST_OUT_DIR, env_map) catch 0;
```

`cli/build.zig` is [`13-module-identity`](../13-module-identity/README.md)'s file. The one-line twin

```zig
if (target == .erlang) { _ = libs.shipErlSidecars(gpa, io, outputs, out_dir, env_map) catch 0; }
```

beside the existing `if (target == .commonJS)` is handed to it. It only becomes *useful* once an
erlang `build`/`run` output can reach a sibling module at all, which is the same gap 13 closes.

<a id="r3-a-third-catch-continue-in-project_graphzig"></a>

### R3 — a third `catch continue` in `project_graph.zig`

```
$ grep -n 'catch continue' modules/language-server/src/project_graph.zig
 67:/// Both failures used to be `catch continue`: a dependency named in
347:            const source = entry.dir.readFileAlloc(self.io, entry.basename, a, .limited(10 * 1024 * 1024)) catch continue;
```

`loadSrcTree`'s read of a `.bp` under the project's own `src`. A file the server cannot read drops out
of the graph with no diagnostic, and the editor then blames whatever imported it.
`modules/language-server/**` is **not this front's file**; it belongs to
[`11-tooling`](../11-tooling/README.md), which claims it. Recorded here because this is the front that
found it, and because the CLI has no equivalent hole.

### R4 — the flat `test/` suite never reaches the resolver

`botopink test` discovers a flat `test/` directory through `cli/scanner.zig`
(`scanSources`, `:37`), which lists files and sorts them; it never calls `resolver.resolve`. So an
unresolved `import` in a `*_test.bp` stays silent **even after step 1 lands**. Named in 1.0.4-beta's
front 20 Notes as "not done, and nobody's"; **claimed here.**

### R5 — a manifest `files` entry is warned about as an unreached module

Handed over by [`08-hygiene`](../08-hygiene/README.md). Every `zig build test-libs` run prints, twice,
for `libs/std` itself:

```
warning: module not reached by any `mod` path — not compiled: src/primitives.bp
warning: 1 module(s) not reached by any `mod` path were not compiled
```

`primitives.bp` is listed in `libs/std/botopink.json`'s `files` and flattened into the global type env
through `std_core_files` in `build.zig`; it is deliberately not in `root.bp`'s `pub mod` chain. The
warning fires on the standard library on every gate run.

## Steps

### Step 1 — an import that names nothing is a located error (R1)

Unstash, rebase onto `feat`, commit. The implementation is complete; what follows is its acceptance,
re-verified after the rebase.

Give `resolver.resolve` an `externals` argument (the project's declared dependency names; `null`
disables the check for a caller that does not know the set) and add pass **F4**, before F3, so the
"no such module" case is reported as such and not as a missing symbol. A `from` is accepted when it is
`std`, a package module (dotted path → the `mod` chain), or a declared dependency (`<dep>` or
`<dep>.<module>`); otherwise `UnresolvedImportSource`, naming what the `from` said. Keep
`UnexportedImport` as the separate message — the two failures have different fixes. Give
`resolver.Diagnostic` `file`/`line`/`col` and render them on both.

**Acceptance:**
- [ ] The reproduction above exits 1 on `check` **and** on `build`, with
      `unresolved import source — no such module or dependency`, the name, and `at: src/main.bp:1:20`
- [ ] The missing-symbol case still reds with its own message, now located
- [ ] `from "std"`, a package module, a nested `a.b` module, a declared dependency and a dependency's
      module all still resolve
- [ ] Three resolver unit tests: the located rejection, the accepted shapes, the `null` no-op
- [ ] `zig build test`, `test-cli`, `test-libs`, `test-language` and **`test-docs`** green — the last
      only after [`08-hygiene`](../08-hygiene/README.md) step 3.3 lands
- [ ] The stash is dropped and the branch `fix/cli` and worktree `.tasks/cli` cleaned up

### Step 2 — the flat `test/` suite resolves its imports too (R4)

Route `botopink test`'s flat-`test/` discovery through the same F4 check, or give `scanner.zig` the
dependency set and run the check there. Which one depends on whether a `*_test.bp` may import a sibling
test file — measure it and say so.

**Acceptance:**
- [ ] A `test/x_test.bp` with `import {nothing} from "nowhere";` exits 1 with the located
      `unresolved import source`, on `botopink test`
- [ ] Every library's `test/` cell still passes (`zig build test-libs`: 11 passed, 0 failed)
- [ ] `modules/compiler-cli/AGENTS.md` says which loader each command uses and that both check imports

### Step 3 — a `files` entry is not an unreached module (R5)

A module listed in `botopink.json`'s `files` is declared surface; the "not reached by any `mod` path"
warning should not fire for it.

**Acceptance:**
- [ ] `zig build test-libs` prints no `not reached by any mod path` line for `libs/std`
- [ ] A module that is in neither `files` nor a `mod` chain **still** warns — asserted by a CLI unit
      test, so the fix narrows the warning rather than deleting it
- [ ] `modules/compiler-cli/AGENTS.md` states the rule

### Step 4 — hand on what this front does not own

No code. Register, in the owning front's README, with the reproduction:

| Row | Owner |
|---|---|
| the `shipErlSidecars` call site in `cli/build.zig` ([R2](#r2-buildrun-does-not-ship-an-erl-sidecar)) | [`13-module-identity`](../13-module-identity/README.md) |
| `loadSrcTree`'s `catch continue` (`project_graph.zig:347`, [R3](#r3-a-third-catch-continue-in-project_graphzig)) | [`11-tooling`](../11-tooling/README.md) |
| `ast.ImportDecl` has no `Loc`; if one is added, delete this front's token walk (`fromLocations`) | [`01-checker`](../01-checker/README.md) |

**Acceptance:**
- [ ] Each row appears in the named front's README with the file, the line and the reproduction
- [ ] None of the three is edited from this front

## Gate

- [ ] `scripts/gate.sh --staged` green on each commit (the pre-commit hook; no `--no-verify`)
- [ ] `zig build test` (the CLI unit tests), `test-cli`, `test-libs`, `test-language`, `test-docs`
      green in this worktree
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commits on `fix/cli-residuals`; no push, no merge, no submodule bump

## Blast radius

- **Step 1 reds real code.** Any project whose `from` names nothing stops compiling. Measured across
  the checkout by the front that wrote the patch: `zig build test`, `test-cli` and `test-libs`
  (11 library cells) are unaffected — every library and example resolves what it imports. Re-measure
  after the rebase, because [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) may have
  moved imports since. **The one casualty is `docs.md:78`**, which
  [`08-hygiene`](../08-hygiene/README.md) step 3.3 fixes; it is checked and vacuously green today
  (`zig build test-docs`: 36 fences — 32 checked, 2 skipped, 0 failed, and `docs.md:78` is one of the
  32).
- **Step 2 reds any `*_test.bp` with a bad import** — none in the checkout at `c2dd780`, verified by
  `test-libs` and `test-language` passing after step 1's resolver change, but re-measure.
- **Step 3 removes two warning lines** from every `test-libs` run and adds a unit test.

## Notes

- **The two import failures keep two messages.** "No such module" and "the module does not export
  this" have different fixes (declare the module or the dependency; declare the symbol `pub`), so F4
  runs before F3 rather than folding into it.
- **Step 1's location is read from tokens, not from the AST.** `ast.ImportDecl` has no `Loc`; giving it
  one is [`01-checker`](../01-checker/README.md)'s file.
- **The 1.0.4-beta unowned row "a library cannot ship an erlang host module" is closed** (`c01695f`)
  and should be struck from the carried table — with the `build`/`run` half named as
  [`13-module-identity`](../13-module-identity/README.md)'s, not as a survival of the old row.
- Rakun's erlang cell is skipped for its own reason — 17 node-only host cells and a 231-line
  `runtime.mjs` — not for the missing `.erl` shipping. That is
  [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) R2.

## Decisions the maintainer owes

1. **`docs.md:78`** — the `docs-check: skip` directive or the richer `project modules` rewrite (both
   written out in [`08-hygiene`](../08-hygiene/README.md) step 3.3). Step 1 cannot be committed until
   one lands. This is the *only* thing blocking a finished, verified patch.

---

## Rows for `fronts.md`

**Ownership table:**

```markdown
| **10** [`cli-residuals`](./10-cli-residuals/README.md) | `modules/compiler-cli/**` **except** `src/cli/{build,run}.zig` (13's) · `modules/lib-test-runner/**` where a fix needs it | — | not started — step 1 implemented and parked in `stash@{0}` on `fix/cli`, blocked on `docs.md:78` (08 step 3.3) |
```

**Conflict notes** (against the other thirteen fronts):

| With | Verdict | Why |
|---|---|---|
| **01 checker · 02 erlang · 03 beam · 04 js · 05 wasm · 06 comptime-dedup · 07 review-backlog** | yes | No shared file. If 01 gives `ast.ImportDecl` a `Loc`, this front's `fromLocations` token walk is deleted in favour of it — a follow-up, not a conflict |
| **08 hygiene** | **no**, both ways | 08 owns `docs.md`, whose `:78` fence is step 1's precondition; 08 hands this front the `libs/std` manifest-warning row (step 3); 08's comment sweep over `modules/compiler-cli/**` lands after this front |
| **09 ecosystem-residuals** | **seq** — 10 first | Step 1 reds any project whose `from` names nothing. Measured: none of the five libraries or their examples. Re-run 09's cells after landing |
| **11 tooling** | yes | This front only *reports* `project_graph.zig:347`; 11 owns the file and claims the fix |
| **12 language-tests** | **seq** | Step 1 and step 2 change what `check` and `test` reject, which is what `reject/` cells assert. No shared file; 12 re-runs after |
| **13 module-identity** | **no** — shared file | Both want `modules/compiler-cli/src/cli/{build,run}.zig`. 13 owns both; 10 owns the rest of `modules/compiler-cli/**` and hands 13 the one-line `shipErlSidecars` call site in `build.zig` |
| **14 comptime-on-beam** | yes | No shared file |

**Front-table row (`overview.md`):**

```markdown
| [`10-cli-residuals`](./10-cli-residuals/README.md) | medium | not started — step 1 parked in a stash, blocked on `docs.md:78` | An `import` naming a module that does not exist still passes `check` and `build` in silence, exit 0, code emitted — the fix is written, verified and stashed because it reds the one `docs.md` fence that is vacuously green for exactly that reason. Plus the flat `test/` suite, which never reaches the resolver at all, and a `botopink.json` `files` entry the compiler warns about as an unreached module on every gate run |
```
