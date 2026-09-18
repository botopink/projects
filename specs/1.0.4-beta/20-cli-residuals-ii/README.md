# Front 20 — cli-residuals-ii

**Delivered in part** 2026-09-18 — defects **B** (`de4aa87`) and **C** (`c01695f`) landed; **D** was
verified closed on the CLI side and reported, not edited, on the language-server side, where
[`14-tooling-and-docs`](../14-tooling-and-docs/README.md) landed it (`aed8a60`); **A** is implemented
and verified but could not be committed, because it reds a `docs.md` fence this front does not own —
see [Blocked on `docs.md`](#blocked-on-docsmd).

**Owned:** `modules/compiler-cli/**` **except** `src/cli/build.zig` and `src/cli/run.zig` (held by
the module-naming front — the output layout and `botopink run --target erlang`) ·
`modules/lib-test-runner/**` where a fix needs it · this directory · no snapshot directory.

Paths are relative to `repository/botopink-lang/`; `main.zig` and `cli/*.zig` live under
`modules/compiler-cli/src/`. Line numbers were measured at `botopink-lang` `26d4fdc` (2026-09-18).

---

## Problem

Four defects in `modules/compiler-cli/**`, each reported by another front and each reproducible.
They are unrelated to one another; what they share is the directory and the fact that nobody had
owned it since [`05-cli-residuals`](../05-cli-residuals/README.md) delivered.

| # | Defect | Where | Found by |
|---|---|---|---|
| A | An `import` naming a module that does not exist passes `check` **and** `build` in silence — exit 0, code emitted | `cli/resolver.zig`, `cli/sources.zig` | the user-docs work: it is why every import example in `docs.md` is green |
| B | `botopink new`'s template compiles to a program that prints nothing, so the README's quick start has no visible effect | `cli/new.zig` | this front |
| C | A library cannot ship an erlang host module — `cli/libs.zig` has `shipMjsSidecars` and no `.erl` counterpart | `cli/libs.zig` | 13's erlang-cells investigation ([`../fronts.md`](../fronts.md#unowned-items)) |
| D | A missing dependency and an unreadable `files` entry are swallowed with `catch continue` — the CLI half only; the file is another front's | `language-server/src/project_graph.zig` `:171`, `:210` | 1.0.2-beta library-repos, re-confirmed by 05 |

## Current state

Measured at `26d4fdc` by running the CLI from a scratch project outside any repository, and by
reading the file for D.

**A.** A project whose only module is

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
   Checked in 66.96ms
0
$ botopink build ; echo $?
  Compiling 1 module(s)...
   Compiled in 68.99ms
0
$ ls out/
main.js
```

The *other* half already reds: with `mod geometry;` declared and `geometry.bp` exporting only
`perimeter`, `import {area} from "geometry";` gives `error: imported symbol is not exported by the
named module` and exit 1 — but with no location.

**B.** `botopink new hello && cd hello && botopink run` — exit 0, no output. The template is
`pub fn main() { "Hello, world!" }`; the emitted commonJS is `"Hello, world!";`, an expression
statement whose value is dropped, because a block's value is its `break`
([decision 2](../08-review-backlog/semantics-decisions.md), option B). `grep` finds the template
text in no test and in no document; `README.md`'s quick start runs `new` then `run` and shows no
expected output.

**C.** A throwaway library whose only surface is
`#[@External.Erlang("hostlib_native", "greet")] pub declare fn greet(name: string) -> string;`,
with `hostlib_native.erl` beside its `.bp` sources, consumed by a project that tests it on erlang:

```
$ botopink test --target erlang
TEST main.bp:3 the host module answers
  FAIL the host module answers  ({error,undef})  at main.bp:3
0 passed, 1 failed
```

Nothing copies `hostlib_native.erl` anywhere. `shipMjsSidecars` (`cli/libs.zig`) ships `.mjs` and
only `.mjs`.

**D. The CLI half is closed.** Both cases report, located:

```
$ botopink check                      # dependency "absentlib" declared, nowhere on disk
error: dependency 'absentlib' was not found under any library root
 hint: libraries resolve from BOTOPINK_LIB_ROOTS, then <ancestor>/repository/botopink-lang/libs, …

$ botopink check                      # dependency lists "gone.bp" in `files`
error: dependency 'halflib' lists "gone.bp" in `files`, but …/halflib/src/gone.bp does not exist
 --> …/halflib/botopink.json:2:27
  |
2 |   "files": ["halflib.bp", "gone.bp"] }
  |                           ^^^^^^^^^
```

**The language-server half closed while this front ran.** At `26d4fdc`,
`modules/language-server/src/project_graph.zig` still read

```zig
:171                self.loadLib(a, &deps, roots, dep) catch continue;
:210            const source = std.Io.Dir.cwd().readFileAlloc(self.io, path, a, …) catch continue;
```

[`14-tooling-and-docs`](../14-tooling-and-docs/README.md) owns the file and landed both as located
`Problem`s on `feat` (`aed8a60`) — the same two messages the CLI prints, published against the
manifest that names the entry. This front reported and did not touch it, which is what the two
sessions overlapping on the same file required.

**A third site is still open and no row has ever named it:** `loadSrcTree`'s read of a `.bp` under
the project's own `src` (`catch continue`, `:347` at `aed8a60`). A file the server cannot read
drops out of the graph with no diagnostic, and the editor then blames whatever imported it. It
belongs to whoever next owns `modules/language-server/**`; the fix is the `Problem` shape 14 just
built, located at the file itself.

## Mechanism

**A.** `cli/resolver.zig` builds the package's module set and already runs two import passes — F2
(path visibility) and F3 (`UnexportedImport`). F3's guard is

```zig
const target = analysis.paths.get(from) orelse continue; // not a package module
```

so a `from` naming nothing at all falls straight through, by design: the resolver could not tell a
dependency from a typo, having never been told the dependency set. Downstream, the comptime
pipeline's `resolveImports` (`compiler-core/src/comptime.zig:703`) binds an imported name by
*searching* the export registry and simply not binding when nothing matches — no diagnostic, and
that file is the checker's.

The answer therefore belongs in the CLI, which holds both halves of the question: the module tree
and `botopink.json`'s `dependencies`. Because every command loads `src/` through `sources.load`,
one check there covers `build`, `check` and `test` — which the command contract already requires to
agree.

`ast.ImportDecl` carries no `Loc`, and adding one is
[`06-checker`](../06-checker/README.md)'s file. The location is read instead off the token stream
the resolver already produces: `from` is a keyword of its own and occurs only in an import, so the
n-th `from` + string-literal pair belongs to the n-th `import … from` the parser reports.

**B.** `cli/new.zig`'s `MAIN_BP` constant.

**C.** What each runtime *looks up* differs, so "ship the file into place" means different things.
Node reads a path out of the emitted text (`require("…/x.mjs")`), which is why `shipMjsSidecars`
scans for that path, resolves it, and puts the file there. The erlang code server resolves a module
**atom** and the emitted text carries no path at all: `#[@External.Erlang("host", "fn")]` lowers to
`host:fn(…)` and nothing more. So the erlang counterpart has to work from the qualifiers, and the
place to put the file is the output directory — which is exactly where the emitted test runner's
`__bp_load_siblings/0` looks: it compiles and loads every `**/*.erl` beside the script before
running. Plain `escript` does not (measured: `escript out/main.erl` with `out/host.erl`, and even
with `out/host.beam`, raises `undefined function host:greet/0`), so a `build`/`run` output needs
the loader its emitter does not write — the same reason `examples/modules` is red on erlang.

**D.** `catch continue` in `loadLib`'s caller and in `loadLib`'s file read.

## Steps

### Step 1 — an import that names nothing is a located error (A)

Give `resolver.resolve` an `externals` argument (the project's declared dependency names; `null`
disables the check for a caller that does not know the set) and add pass **F4**, before F3, so the
"no such module" case is reported as such and not as a missing symbol. A `from` is accepted when it
is `std`, a package module (dotted path → the `mod` chain), or a declared dependency (`<dep>` or
`<dep>.<module>`); otherwise `UnresolvedImportSource`, naming what the `from` said. Keep
`UnexportedImport` as the separate message — the two failures have different fixes. Give
`resolver.Diagnostic` `file`/`line`/`col` and render them on both.

**Acceptance:**
- [x] The reproduction above exits 1 on `check` **and** on `build`, with
      `unresolved import source — no such module or dependency`, the name, and `at: src/main.bp:1:20`
- [x] The missing-symbol case still reds with its own message, now located
- [x] `from "std"`, a package module, a nested `a.b` module, a declared dependency and a
      dependency's module all still resolve; `zig build test-cli` and `test-libs` unchanged
- [x] Three resolver unit tests: the located rejection, the accepted shapes, the `null` no-op
- [ ] **Landed** — not met. The change is complete and verified but uncommittable; see
      [Blocked on `docs.md`](#blocked-on-docsmd) below

### Step 2 — the scaffold prints (B)

`botopink new` writes a program whose `main` calls `@print`.

**Acceptance:**
- [x] `botopink new hello && cd hello && botopink run` prints `Hello, world!` and exits 0, on
      commonJS and on erlang
- [x] A row in `tests/cli_contract.sh`: the written `src/main.bp` contains `@print`, and the run
      prints it (the run half skips by name when `node` is absent)
- [x] The command contract in `modules/compiler-cli/AGENTS.md` says the scaffold prints, and why

### Step 3 — a library ships its erlang host module (C)

`libs.shipErlSidecars`, the `.erl` counterpart of `shipMjsSidecars`: read the `atom:atom(`
qualifiers out of each emitted erlang module and copy, into the output directory, the ones for
which a source file exists under the owning lib's `src/sidecars/` or `src/` (a project-own module
probes `src/sidecars/` then `src/`). Lib-agnostic by the same rule the `.mjs` half uses — a
qualifier ships only when a file of that name is found, so an OTP call or a call to another module
of this build is a no-op.

**Acceptance:**
- [x] The reproduction above passes; removing the shipped file from the output brings
      `{error,undef}` back
- [x] The scan is unit-tested: a real qualifier, the shapes that are not one (`::`, an upper-case
      variable, a bare atom with no call head, a quoted local call, a map key), a quoted function name
- [x] An end-to-end cell in `tests/test_tooling.sh`, skipped by name when `escript` is absent
- [x] Wired into `botopink test`. **`build`/`run` are not** — see the handoff below

### Step 4 — `project_graph.zig`'s swallowed diagnostics (D)

Verify the CLI half and report the rest.

**Acceptance:**
- [x] The CLI half is confirmed closed, with its output quoted (see Current state)
- [x] The language-server half was confirmed open at `:171` and `:210` at this front's base, was
      **reported, not edited**, and has since landed with 14 (`aed8a60`)
- [x] A third site, `loadSrcTree`'s read of a project `.bp` (`:347` at `aed8a60`), is named here —
      still open, still nobody's

## Gate

- [x] `scripts/gate.sh --staged` green on each commit (the pre-commit hook; no `--no-verify`)
- [x] `zig build test` (78 CLI unit tests), `test-cli`, `test-libs` green in this worktree
- [x] `AGENTS.md` of every directory touched, updated in the same commit
- [x] Commits on `fix/cli`; no push, no merge, no submodule bump

Commits: `de4aa87` (step 2), `c01695f` (step 3).

## Blast radius

- **Step 1 reds real code.** Any project whose `from` names nothing stops compiling. Measured
  across the checkout: `zig build test`, `test-cli` and `test-libs` (11 library cells) are
  unaffected — every library and example resolves what it imports. The one casualty is a
  documentation fence, below.
- **Step 2** changes nothing but the bytes `botopink new` writes.
- **Step 3** adds files to the output directory of `botopink test --target erlang` — only for a
  qualifier whose source file was found, so a project with no erlang host module sees no change.
- **Step 4** changes nothing.

<a id="blocked-on-docsmd"></a>

### Blocked on `docs.md`

Step 1 reds one fence, `docs.md:78`:

````markdown
### Imports

```botopink
import {dict, queue, order} from "std";   // stdlib modules
import {area} from "geometry";             // module in this package
import {name} from "shapes.circle";        // nested module path
import {of, erika} from "erika";           // library dependency
```
````

`scripts/check-docs.sh` compiles a fence with no directive as a whole module in a scratch project
that has no `mod` declarations and no dependencies, so all three non-`std` lines are exactly the
defect step 1 fixes. This is the fence the user-docs front meant when it said the import examples
were vacuously green — the fix is what proves it.

`docs.md` belongs to [`09-hygiene`](../09-hygiene/README.md) step 5 / [`14`](../14-tooling-and-docs/README.md); this
front stops and reports. **The exact edit**, one line immediately above that fence:

```markdown
<!-- docs-check: skip illustrative import forms — `geometry`, `shapes.circle` and the `erika` dependency exist only inside a project that declares them -->
```

The richer alternative, if the owner prefers to keep the coverage: move the `geometry` and
`shapes.circle` lines into the existing `project modules` group (`docs.md:41`, which already
defines `src/geometry.bp` and `src/shapes/mod.bp` — it would also need a `src/shapes/circle.bp`
fence and a `pub mod circle;`), and leave only the `erika` line under a `skip`.

Until one of the two lands, `zig build test-docs` — gate stage 9, run by the pre-commit hook —
fails, so step 1 cannot be committed. **Its implementation is complete and verified, and is parked as
`stash@{0}` in `botopink-lang`**, named
`front 20 defect A — unresolved import source is a located error (blocked on docs.md:78)`, taken on
branch `fix/cli` (worktree `.tasks/cli`, at `c01695f`). Confirmed present 2026-09-18.

## What it left, and where

| Residual | Owner in 1.0.5-beta |
|---|---|
| **Defect A** — an `import` naming nothing passes `check` and `build` in silence. Implemented (resolver pass F4, `UnresolvedImportSource`, located off the token stream, three unit tests) and parked in the stash above. It lands the moment `docs.md:78` carries a `docs-check` directive | `10-cli-residuals`, unblocked by `08-hygiene` |
| **`loadSrcTree`'s `catch continue`** in `project_graph.zig` (`:347` at `aed8a60`) — a project `.bp` the server cannot read drops out of the graph with no diagnostic, and the editor then blames whatever imported it. Named by this front's step 4; nobody has ever owned it. The fix is the `Problem` shape front 14 built, located at the file itself | `11-tooling` |
| **A located `UnresolvedImportSource` for the flat `test/` suite** — it loads through `scanner.zig`, not through the resolver, so an unresolved import in a `*_test.bp` stays silent even after defect A lands | `10-cli-residuals` |
| **`shipErlSidecars` is wired into `botopink test` only.** `cli/build.zig` holds the `shipMjsSidecars` call site and was not this front's file; the one-line twin (`if (target == .erlang) { _ = libs.shipErlSidecars(gpa, io, outputs, out_dir, env_map) catch 0; }` beside the existing `if (target == .commonJS)`) is still to be added. It only becomes *useful* once an erlang `build`/`run` output can reach a sibling module at all — the same gap that keeps `examples/modules` red on erlang | `10-cli-residuals`, with the module-naming front |
| **`ast.ImportDecl` carries no `Loc`.** Defect A reads its location off the token stream instead (`fromLocations` in `cli/resolver.zig`); if the checker gives `ImportDecl` a `Loc`, that token walk should be deleted in favour of it | `01-checker`, then `10-cli-residuals` |

## Notes

- **The two import failures keep two messages.** "No such module" and "the module does not export
  this" have different fixes (declare the module or the dependency; declare the symbol `pub`), so
  F4 runs before F3 rather than folding into it.
- **Rakun's erlang cell is still skipped**, for its own reason (`botopink test` cannot run the
  target, or the library's `targets` list excludes it), not for the missing `.erl` shipping — which
  step 3 closed. The row that named host modules as its blocker is retired.
