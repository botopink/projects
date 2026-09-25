# std — the package cut

The tree of `libs/std`, what it exposes to the `<lib>-test` submodules, and who owns which file.
std is the one library the `<name>/` + `<name>-test/` pattern does not apply to (§ *Why std has no
`-test` submodule*).

## The tree

Three categories (decision 106): a **pure root**, `io/` for everything that talks to the world
outside the process, and `testing/` for the harness. A root module may not import from `io/`; the
compiler refuses it inside std, with no flag. A directory groups function modules (`fs`, `http`,
`asserts` each keep their file); a file groups types (`collections.bp` holds `Dict`, `Set`,
`Queue`, `Order` — the type is the namespace, and one file is what lets `Dict.keys()` answer
`Set<K>` when a std module cannot import another). Merges only where the name wins: `collections`,
`hash`, `encoding`. `erlang.bp` and `beam.bp` are the target's surface, outside the criterion.

```
repository/botopink-lang/libs/std/
├── botopink.json            "name": "std" · files: primitives.bp, builtins.d.bp, builtins_fns.d.bp
├── AGENTS.md
├── test/                    the three ambient-surface files (result_test, primitives_test, primitives_gaps_test)
└── src/
    ├── root.bp              one `pub mod <name>;` per root module, plus `pub mod io;` and `pub mod testing;` — the registry the build reads
    ├── primitives.bp  builtins.d.bp  builtins_fns.d.bp      ambient; flattened into the global env
    │
    │   ── pure root: same input, same output; no clock, disk, network or entropy; imports nothing from io/
    ├── collections.bp       Dict, Set, Queue, Order
    ├── math.bp  path.bp  url.bp  querystring.bp  json.bp  regex.bp  unicode.bp  string_builder.bp
    ├── encoding.bp          base64 + hex, percent and the form codec        01-std-lib-enablement (codec half)
    ├── hash.bp              sha256, sha512, md5, hmacSha256 + the hmac half (01) + the content-hash half (03)
    ├── escape.bp            01-std-lib-enablement
    ├── async.bp             02-std-async-primitives
    ├── erlang.bp  beam.bp   target surface — outside the criterion
    │
    ├── io/                  talks to the world; may import from the root
    │   ├── mod.bp           pub mod fs; pub mod http; pub mod net; pub mod clock; pub mod random; pub mod os; pub mod env; pub mod process;
    │   ├── fs.bp            readText, writeText, exists, list, mkdir, rm, absolutePath, walk, glob
    │   ├── http.bp
    │   ├── net.bp           TCP/TLS sockets — server-only            01-std-lib-enablement (new)
    │   ├── clock.bp         nowMillis, monotonicMillis, formatIso8601, measureMillis + parse, civil, Duration, sleep (01)
    │   ├── random.bp        the rand-backed eight + randomBytes + secureToken, uuidV4 (01)
    │   ├── os.bp  env.bp
    │   └── process.bp       exit, cwd, platform, arch, pid + run, runShell (01)
    │
    ├── testing/             the harness — impure by nature, enters only under `botopink test`
    │   ├── mod.bp           pub mod asserts; pub mod snapshots; pub mod mocks;
    │   ├── asserts.bp       step 2 — rewritten
    │   ├── snapshots.bp     step 3 — new
    │   └── mocks.bp         step 4 — new, lifted from the old onze
    └── sidecars/random.mjs
```

One package, one `src/`, one `root.bp`. `io/mod.bp` and `testing/mod.bp` are directory `mod.bp`
files of the module system. There is no `modules/` directory and no `std-test`.

The registry: seventeen lines in `root.bp` (fifteen root modules, `pub mod io;`,
`pub mod testing;`), eight in `io/mod.bp`, three in `testing/mod.bp` — twenty-six importable
leaves.

### Old → new

Decision 106's table: every path a consumer writes on the flat tree, and where it is after
`00-compiler-carry-over/23-std-purity` lands.

| Before | After |
|---|---|
| `dict`, `sets`, `queue`, `order` | `collections` (`Dict`, `Set`, `Queue`, `Order`) |
| `math` (without `random`) | `math` |
| `random`, `crypto.randomBytes` | `io.random` |
| `crypto` (the hashes), `hmac` (01), `content_hash` (03) | `hash` |
| `base64` (as `base64Encode`, `base64Decode`, `base64UrlEncode`, `base64UrlDecode` — front 01's names), `encoding` (01) | `encoding` |
| `json`, `regex`, `unicode`, `string_builder`, `url`, `querystring`, `escape` (01), `async` (02) | unchanged, at the root |
| `path` (minus `absolutePath`) | `path` |
| `path.absolutePath`, `path.walk` / `path.glob` (01 — they read the disk), `fs` | `io.fs` |
| `http` | `io.http` |
| `net` (01) | `io.net` |
| `time`, `clock` (01) | `io.clock` |
| `os`, `env`, `process` | `io.os`, `io.env`, `io.process` |
| `asserts`, `snapshots`, `mocks` | `testing.asserts`, `testing.snapshots`, `testing.mocks` (decision 71: name and uniqueness kept; only the path changes) |
| `erlang`, `beam` | unchanged |

## Why std has no `-test` submodule

1. **std's tests are inline.** Every std test sits in a `test` block at the foot of its own
   `src/*.bp` (`libs/std/AGENTS.md` § *Tests*); `test/` holds only the three ambient-surface files,
   because a core file is flattened into the global env and never compiled in test mode. A
   `std-test` submodule would test the one library whose modules cannot import each other
   (`language-gaps.md`) from outside it.
2. **std *is* the test library.** `testing/asserts`, `testing/snapshots` and `testing/mocks` are
   the helpers every `<lib>-test` builds on. A `std-test` that re-exported them would be a package
   importing itself.
3. **std is embedded, not resolved.** `build.zig` (`stdPkgFilesFromRoot`) reads `root.bp` and
   embeds each module as a compile-time string; the compiler exposes them through
   `comptime/stdlib/prelude.zig`. There is no `botopink.json` dependency graph to hang a second
   package on.

## What std exposes to the other `-test` submodules

| Module | What a `<lib>-test` uses it for | Backends |
|---|---|---|
| `testing.asserts` | the `@Result<void, string>` assertions every helper is built on — `asserts-api.md` | all four (STD-001 clean); `matches`/`deepEquals`/`throws`/`throwsWith` need Node or Erlang at run time |
| `testing.snapshots` | `assertAs(loc, subject, actual)` — the one call an `assert<Subject>` helper makes — `snapshots.md` | commonJS, erlang (the `botopink test` targets) |
| `testing.mocks` | `#[mocks.mock]`, `when`, `verify`, matchers — `onze-migration.md` | commonJS, erlang |

A `<lib>-test` submodule imports the three as

```bp
import {testing: {asserts, snapshots, mocks}} from "std";
```

and calls them qualified by the leaf — `asserts.equals`, `snapshots.assertAs`, `#[mocks.mock]`,
`mocks.when` — because only the leaf of an import path enters scope (decision 107; `testing`
itself does not). One module alone is the dotted form of the same tree:
`import {testing.asserts} from "std";`. A `<lib>-test` does **not** re-export them one by one: a
consumer would then have two `equals` with two messages.

## Ownership table

| Front | Directory / files | Tests it owns |
|---|---|---|
| **01-std** step 1 | `modules/compiler-core/src/…` (see README **Owns**) | `snapshots/codegen/*/src_*.snap.md`, `codegen/tests/builtins.zig` additions |
| **01-std** steps 2–4 | `src/testing/asserts.bp`, `snapshots.bp`, `mocks.bp`; `src/testing/mod.bp` | inline, at the foot of each |
| **01-std** step 6 → `01-std-lib-enablement` | the content of `io/net.bp` and `escape.bp` (new files); the hmac half of `hash.bp`; the codec half of `encoding.bp`; the additions to `path.bp`, `io/fs.bp` (`walk`, `glob`), `io/clock.bp`, `io/random.bp`, `regex.bp`, `io/process.bp`; the export lines in `root.bp` and `io/mod.bp` | inline |
| `02-std-async-primitives` | `async.bp`, at the root | inline |
| `03-std-content-hash` | the content-hash half of `hash.bp` (`contentHash`, `strongHash`, `cacheKey`, `strongCacheKey`, `etag`, `weakEtag`, `matches`, `fingerprint`) | inline |
| `00-compiler-carry-over/23-std-purity` | the move itself, after 01/02/03 and steps 2–4 have merged: `io/` and `testing/` with their `mod.bp`; `collections.bp`; the merges into `hash.bp` and `encoding.bp`; `absolutePath`, `walk`, `glob` into `io/fs.bp`; `randomBytes` into `io/random.bp`; `root.bp` rewritten to the registry above; `build.zig` `stdPkgFilesFromRoot` following `pub mod io;` into `io/mod.bp`; the root-does-not-import-`io/` check; the import grammar of decision 107 (`parser/decls.zig` `parseImportItem`, `project_graph.zig`, `emitUse` in the four codegens) | the compiler tests of the check and of the grammar; every std inline test green at the new paths; every `from "std"` line in the sibling libraries rewritten per the table above |

Fronts 01/02/03 own their modules' *content*; the *paths* are 23's. Their files land at
`src/<name>.bp` when they merge and 23 moves them: `net.bp`, `clock.bp` → `io/`; `hmac.bp` and
`content_hash.bp` → `hash.bp`; `encoding.bp` absorbs `base64.bp`; `escape.bp` and `async.bp` stay
at the root. Each sub-front's README names its modules by the final path, so the move is a
`git mv` plus the merges.

`src/root.bp` is the shared file. `01-std-lib-enablement` commits it last among the sub-fronts,
carrying every line handed over at that point (its five, `async`, `content_hash`, `snapshots`,
`mocks`); 23 then replaces those lines with the registry above.

## Snapshot directories

std's own snapshots — the ones `test-snap.md` lists — live beside the file that owns the test,
because `snapshots.path(loc)` puts them there: `libs/std/src/__snapshots__/<suite>/` for the root
modules and `libs/std/src/testing/__snapshots__/<suite>/` for the harness's own tests. No `io/`
module records a snapshot (`test-snap.md` § *What is not snapshotted*). No other front writes into
either directory.
