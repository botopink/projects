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
    ├── encoding.bp          base64Encode/Decode, base64UrlEncode/Decode, hexEncode/Decode, percentEncode/Decode, formStringify, formParse
    ├── hash.bp              sha256, sha512, md5, hmacSha256 · hmacSha256Base64Url, sha1Base64, sha256Base64Url, equalsConstantTime · contentHash, strongHash, cacheKey, strongCacheKey, etag, weakEtag, matches, fingerprint
    ├── escape.bp            html, attribute, unescapeHtml, jsString, scriptJson
    ├── async.bp             delay, failed, errorText, allOf, all, race, runAll, raceOf, timeout
    ├── erlang.bp  beam.bp   target surface — outside the criterion
    │
    ├── io/                  talks to the world; may import from the root
    │   ├── mod.bp           pub mod fs; pub mod http; pub mod net; pub mod clock; pub mod random; pub mod os; pub mod env; pub mod process;
    │   ├── fs.bp            readText, writeText, exists, list, mkdir, rm, absolutePath, walk, glob
    │   ├── http.bp
    │   ├── net.bp           TCP/TLS sockets (Listener, Socket, TlsListener, TlsSocket, Peer) — server-only
    │   ├── clock.bp         nowMillis, monotonicMillis, formatIso8601, measureMillis, parseIso8601, toCivil, offsetMinutes, Duration, sleep, deadline, isExpired
    │   ├── random.bp        the rand-backed eight, randomBytes, secureToken, uuidV4
    │   ├── os.bp  env.bp
    │   └── process.bp       exit, cwd, platform, arch, pid, run, runShell
    │
    ├── testing/             the harness — impure by nature, enters only under `botopink test`
    │   ├── mod.bp           pub mod asserts; pub mod snapshots; pub mod mocks;
    │   ├── asserts.bp       asserts-api.md
    │   ├── snapshots.bp     snapshots.md
    │   └── mocks.bp         onze-migration.md — lifted from the old onze
    └── sidecars/random.mjs
```

One package, one `src/`, one `root.bp`. `io/mod.bp` and `testing/mod.bp` are directory `mod.bp`
files of the module system. There is no `modules/` directory and no `std-test`.

The registry: seventeen lines in `root.bp` (fifteen root modules, `pub mod io;`,
`pub mod testing;`), eight in `io/mod.bp`, three in `testing/mod.bp` — twenty-six importable
leaves.

### Old → new

Decision 106's table: every path a consumer wrote on the flat tree, and where it is.

| Before | After |
|---|---|
| `dict`, `sets`, `queue`, `order` | `collections` (`Dict`, `Set`, `Queue`, `Order`) |
| `math` (without `random`) | `math` |
| `random`, `crypto.randomBytes` | `io.random` |
| `crypto` (the hashes), `hmac`, `content_hash` | `hash` |
| `base64` (as `base64Encode`, `base64Decode`, `base64UrlEncode`, `base64UrlDecode`), `encoding` | `encoding` |
| `json`, `regex`, `unicode`, `string_builder`, `url`, `querystring`, `escape`, `async` | unchanged, at the root |
| `path` (minus `absolutePath`) | `path` |
| `path.absolutePath`, `path.walk` / `path.glob` (they read the disk), `fs` | `io.fs` |
| `http` | `io.http` |
| `net` | `io.net` |
| `time`, `clock` | `io.clock` |
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
| `testing.mocks` | `when`, `verify`, matchers, and `#[mocks.mock]` once a consumer can reach the decorator (`onze-migration.md` § *Language gaps*) | commonJS, erlang |

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
| **01-std** step 1 | `modules/compiler-core/src/…` (see README **Owns**) | `snapshots/codegen/*/*/src_*.snap.md`, `codegen/tests/builtins.zig` additions |
| **01-std** steps 2–4 | `src/testing/asserts.bp`, `snapshots.bp`, `mocks.bp`; `src/testing/mod.bp` | inline, at the foot of each |
| `01-std-lib-enablement` | `io/net.bp`, `escape.bp`; the base64url digests of `hash.bp`; the codec half of `encoding.bp`; the functions it added to `path.bp`, `io/fs.bp` (`walk`, `glob`), `io/clock.bp`, `io/random.bp`, `regex.bp`, `io/process.bp`; `json.bp`'s writers, `Json` and `decode` | inline |
| `02-std-async-primitives` | `async.bp`, at the root | inline |
| `03-std-content-hash` | the content hashes of `hash.bp` (`contentHash`, `strongHash`, `cacheKey`, `strongCacheKey`, `etag`, `weakEtag`, `matches`, `fingerprint`) | inline |
| `00-compiler-carry-over/23-std-purity` | the tree: `io/` and `testing/` with their `mod.bp`, the merged files, `root.bp`'s registry, `build.zig` `stdPkgFilesFromRoot` following `pub mod io;` into `io/mod.bp`, the root-does-not-import-`io/` check, the import grammar of decision 107 | the compiler tests of the check and of the grammar |

## Snapshot directories

std's own snapshots — the ones `test-snap.md` lists — live beside the file that owns the test,
because `snapshots.path(loc)` puts them there: `libs/std/src/__snapshots__/<suite>/` for the root
modules and `libs/std/src/testing/__snapshots__/<suite>/` for the harness's own tests. No `io/`
module records a snapshot (`test-snap.md` § *What is not snapshotted*). No other front writes into
either directory.
