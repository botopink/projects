# Front 13 — pre-migration baseline

The observable output of every library example and test run, captured **before** the surface
cutover with the old-surface compiler, so [`../README.md`](../README.md) can prove after the
migration that nothing changed ("example programs run and their output matches the pre-migration
output").

Captured 2026-09-17.

## Versions

| What | Commit |
|---|---|
| compiler (`repository/botopink-lang/zig-out/bin/botopink`) | `botopink-lang` `b4cf700` (checkout later at `8887865`, no compiler change — it only deletes `modules/lib-test-runner/build.zig` + `.zon`; the binary was not rebuilt) |
| emilia | `a167c06` (`emilia-card` re-captured at `3b402ee`, after its fix) |
| erika | `17728e3` |
| jhonstart | `6c807d1` (`jhonstart-counter`/`-html`/`-todo` re-captured at `1257930`, after their fix) |
| onze | `cda9d01` |
| rakun | `d5ca84b` |

## How it was captured

Each library was copied (without `.git`, `.botopinkbuild`, `out`) into a scratch directory; nothing
ran inside `repository/`. Dependencies resolved from the scratch copies and the bundled `libs/std`:
`BOTOPINK_LIB_ROOTS=<scratch>/libs:repository/botopink-lang/libs`.

| File | Command |
|---|---|
| `<lib>/tests.<target>.txt` | `botopink test --target <target> --json` in the library root, for `commonJS` and `erlang` |
| `<lib>/<example>.commonJS.txt` | `botopink build --out <out>` in `examples/<example>` (every example's manifest target is `commonJS`), then `node main.js` in `<out>` |
| `<lib>/<example>.tests.commonJS.txt` | `botopink test --target commonJS --json` in `examples/<example>`, when it built |
| `rakun/rakun.commonJS.txt` | the server started with `node main.js` (port 8080 from the source), then `curl -i` against every route the example declares (users index/show; posts index, create with a body, create with an empty body, delete; an unknown path; `/`), then stopped |

`beam` and `wasm` rows of the libraries' CI matrices are not captured: `botopink test` accepts
`commonJS` and `erlang` only (the lib-test runner reports the other two as unsupported).

## Normalisation

- Test runs: one line per test, `status module :: name`, plus its `run_log` when non-empty, then the
  summary. File, line and `duration_ms` are dropped — line numbers move with the migration.
- stderr: ANSI colours stripped; the `Compiling N module(s)...` / `Compiled in …ms` progress lines
  dropped; the scratch path replaced by `<scratch>`.
- HTTP: `Date`, `Connection` and `Keep-Alive` headers dropped.
- Exit codes are kept as they are.

## State at capture (not defects of this capture)

- **Fixed before the migration and re-captured** (emilia `3b402ee`, jhonstart `1257930`: the calls pass
  the builders' defaulted `attrs` explicitly — default parameters are not applied yet, 06 N1). They
  build and their tests pass (4/4, 3/3, 7/7, 2/2). `jhonstart-html` runs; `emilia-card`,
  `jhonstart-counter` and `jhonstart-todo` **fail at run time** with `Cannot find module '../module'`:
  a sibling-module import inside a dependency is emitted as `require("../module")` (commonJS codegen).
  The baseline pins that failure; after the fix the files are re-captured, and the migration must not
  change the rest. Node's internal stack lines are dropped from stderr.
- **erlang test cells** (allowed to fail in CI): emilia and onze stop at `MissingExternalTarget`
  (no test runs); jhonstart runs 3 tests and rakun 1, but the run exits 127 with
  `escript: There were compilation errors.` — the modules that do not compile on erlang contribute no
  tests. erika passes 31/31.
- `rakun/examples/rakun` has no test blocks.
- Building `onze/examples/onze` wrote a sidecar `src/onze.mjs` **beside** the `--out` directory
  (`<out>/../src/onze.mjs`), not inside it.
