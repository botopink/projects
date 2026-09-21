# std — the package cut

The per-library `modules.md` of 1.0.9 (`tracks/README.md:20`) records the submodule tree of a
library, the target of each submodule, what its `<lib>-test` exposes, and the front → directory
ownership table. std has the shortest answer of the five tracks, and it is worth writing down
because the pattern every other library follows does **not** apply to it.

## The tree

```
repository/botopink-lang/libs/std/
├── botopink.json            "name": "std" · files: primitives.bp, builtins.d.bp, builtins_fns.d.bp
├── AGENTS.md
├── test/                    the three ambient-surface files (result_test, primitives_test, primitives_gaps_test)
└── src/
    ├── root.bp              one `pub mod <name>;` per importable module — the registry the build reads
    ├── primitives.bp  builtins.d.bp  builtins_fns.d.bp      ambient; flattened into the global env
    ├── asserts.bp           step 2 — rewritten
    ├── snapshots.bp         step 3 — new
    ├── mocks.bp             step 4 — new, lifted from the old onze
    ├── async.bp             02-std-async-primitives
    ├── content_hash.bp      03-std-content-hash
    ├── net.bp  clock.bp  encoding.bp  hmac.bp  escape.bp      01-std-lib-enablement (new)
    ├── path.bp  random.bp  regex.bp  process.bp              01-std-lib-enablement (additions)
    ├── <the other nineteen modules of today>
    └── sidecars/random.mjs
```

One package, one `src/`, one `root.bp`. There is no `modules/` directory and no `std-test`.

## Why std has no `-test` submodule

Every other library gets `<name>/` + `<name>-test/` (1.0.9 front 95 § *The `-test` submodule
pattern*). std does not, for three reasons that are structural rather than stylistic:

1. **std's tests are inline.** `libs/std/AGENTS.md` § *Tests*: "Inline `test "name" { … }` blocks
   live in the importable module files; the `primitives.bp` interfaces are tested from `test/`,
   because a core file is flattened into the global env and never compiled in test mode."
   `1.0.9-beta/fronts.md:35-38` repeats it for track A: "std tests are **inline**, not in `test/`
   … Every real std test sits in a `test` block at the foot of its own `src/*.bp`." A `std-test`
   submodule would hold tests of std written outside std, against the one library whose modules
   cannot import each other (`language-gaps.md`, *A std module cannot call another std module*).
2. **std *is* the test library.** `asserts`, `snapshots` and `mocks` are the helpers every
   `<lib>-test` builds on. A `std-test` that re-exported them would be a package importing itself.
3. **std is embedded, not resolved.** `build.zig` (`stdPkgFilesFromRoot`) reads `root.bp` and
   embeds each module as a compile-time string; the compiler exposes them through
   `comptime/stdlib/prelude.zig`. There is no `botopink.json` dependency graph to hang a second
   package on, and `libs/std/AGENTS.md` § *Adding an importable module* is two steps — a file and a
   `pub mod` line — precisely because there is no third.

## What std exposes to the other `-test` submodules

| Module | What a `<lib>-test` uses it for | Backends |
|---|---|---|
| `asserts` | the `@Result<void, string>` assertions every helper is built on — `asserts-api.md` | all four (STD-001 clean); `matches`/`deepEquals`/`throws`/`throwsWith` need Node or Erlang at run time |
| `snapshots` | `assertAs(loc, subject, actual)` — the one call an `assert<Subject>` helper makes — `snapshots.md` | commonJS, erlang (the `botopink test` targets) |
| `mocks` | `#[mocks.mock]`, `when`, `verify`, matchers — `onze-migration.md` | commonJS, erlang |

A `<lib>-test` submodule imports the three as `import {asserts, snapshots, mocks} from "std";` and
calls them qualified. It does **not** re-export them one by one (1.0.9 front 95's example did; a
consumer then has two `equals` with two messages, and the front's own rule — "import `std/asserts`,
do not re-implement" — says why not).

## Ownership table

| Front | Directory / files | Tests it owns |
|---|---|---|
| **01-std** step 1 | `modules/compiler-core/src/…` (see README **Owns**) | `snapshots/codegen/*/src_*.snap.md`, `codegen/tests/builtins.zig` additions |
| **01-std** steps 2–4 | `libs/std/src/asserts.bp`, `snapshots.bp`, `mocks.bp` | inline, at the foot of each |
| **01-std** step 6 → `01-std-lib-enablement` | `net`, `clock`, `encoding`, `hmac`, `escape`, `path`, `random`, `regex`, `process`, `root.bp` | inline |
| `02-std-async-primitives` | `async.bp` | inline |
| `03-std-content-hash` | `content_hash.bp` | inline |

`src/root.bp` is the one shared file. `01-std-lib-enablement` commits it last, carrying nine lines:
its five, `async`, `content_hash`, `snapshots`, `mocks`.

## Snapshot directories

std's own snapshots — the ones `test-snap.md` lists — live at `libs/std/src/__snapshots__/<suite>/`,
because `snapshots.path(loc)` puts them beside the file that owns the test and every std test is in
`src/`. No other front writes into that directory.
