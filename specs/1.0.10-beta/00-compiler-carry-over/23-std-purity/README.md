# Front 23 — std purity: a pure root, `io/`, `testing/`, and the import tree

**Track:** compiler (carry-over item **C-31**) — the compiler half is the import grammar and the
loader; the library half is `libs/std`
**Priority:** high — twenty-six flat modules in `libs/std/src/`, plus the seven fronts 01/02/03 add
(`net`, `clock`, `encoding`, `hmac`, `escape`, `async`, `content_hash`), say nothing at the import
line about which of them touch the world; `dict.empty()` sits beside `sets.empty()` and
`queue.empty()`; `import {dict.Dict} from "std"` parses and fails to link, `import {dict: {Dict}}`
does not parse, and `as` is read and ignored (`parser/decls.zig:242-258`,
[`language-gaps.md`](../../language-gaps.md)).
**Depends on:** [`01-std`](../../01-std/README.md)'s `01-std-lib-enablement` and
`02-std-async-primitives` merged into `feat` — the tree below moves their modules (`net`, `clock`,
`encoding`, `hmac`, `escape`, `async`) and `03-std-content-hash`'s `content_hash`, which lands before
01 by that step's own order (02 · 03 · 01). Those fronts name their files by final path and land
them **flat** at `src/<name>.bp`; the `git mv` into `io/` and `testing/` and the three merges
(`collections`, `hash`, `encoding`) are this front's, after all three merge
([`01-std/README.md`](../../01-std/README.md) § Order step 7). Runs after
[`21-effect-chain`](../21-effect-chain/README.md) (shared `parser/decls.zig`); independent of 22.
**Owns:** `parser/decls.zig`'s `parseImportItem` (the grouped form) · `ast.zig`'s `ImportPath` if
the grouped form needs a field · `comptime/infer.zig`'s import binding (the multi-segment leaf,
`alias`, `import-name-collision`, the std-internal purity refusal) ·
`codegen/{commonJS,erlang,beam_asm,wat}.zig`'s `emitUse` (the leaf and the alias) ·
`modules/language-server/src/project_graph.zig` (the same tree for the LSP — a named carve-out of
[`11-tooling`](../11-tooling/README.md)) · `repository/botopink-lang/build.zig`'s
`stdPkgFilesFromRoot` (std is **embedded**, not resolved: it reads `root.bp` flat and must follow
`pub mod io;` / `pub mod testing;` into `io/mod.bp` and `testing/mod.bp`) · `libs/std/src/**` (the
tree of decision 106: `root.bp`, `io/mod.bp`, `testing/mod.bp`, every moved and fused module) ·
`libs/std/AGENTS.md` · `docs.md` § imports, § std · the snapshots that carry a std module name · in
`repository/rakun` and every `<lib>-test` member: the import lines, through
`scripts/known-red-libs.txt` as in 21 step 4.
**Does not touch:** `builtins.d.bp`, `primitives.bp`, `builtins_fns.d.bp` (ambient — unchanged;
`builtins.d.bp` is 21's) · `erlang.bp`, `beam.bp` (the target surface; outside the criterion) ·
`parser/exprs.zig`, `lexer.zig` (22) · the `-test` members' helper bodies (the libraries') ·
`mocks.bp`'s content (decision 71 fixed its name and uniqueness; only its path moves).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise.

---

## Problem

Three, each reproducible with `botopink check` on a scratch project:

1. `import {dict.Dict} from "std";` parses, then `unknown "std" module in import`: a multi-segment
   item is collected into segments and never bound. `import {dict: {Dict}} from "std";` is
   `unexpected ':'`. `import {main as mainTag} from "jhonstart";` parses and binds `main`
   (`language-gaps.md`'s alias row).
2. Nothing at an import line says `fs` writes disk, `time` reads a clock and `random` reads entropy,
   while `path`, `json` and `url` do not; a reader who wants "what does this module touch outside
   the process" reads every module.
3. `dict`, `sets`, `queue` and `order` are four modules whose only content is one type each, so a
   consumer writes `dict.Dict` / `dict.empty()` beside `sets.empty()`; `Dict.keys()` cannot answer
   `Set<K>` because a std module cannot import another (`language-gaps.md`).

## Current state

`libs/std/src/`: 26 modules, flat — `dict`, `sets`, `queue`, `order`, `fs`, `path`, `time`, `math`,
`random`, `os`, `env`, `process`, `unicode`, `string_builder`, `regex`, `json`, `base64`, `crypto`,
`http`, `url`, `querystring`, `asserts`, `mocks`, `snapshots`, `erlang`, `beam` — plus the seven
[`01-std/modules.md`](../../01-std/modules.md) adds in the same root. Import grammar today:
`ImportItem := DottedName "*"? ("as" Ident)?`; the parser fills `ImportPath{segments, activate, alias}`;
`infer.zig` and the four `emitUse` read `segments[0]` and `activate` only. `Name*` activation works
on all four backends
(`snapshots/codegen/*/dispatch_multi_module_extension_activated_via_star_import.snap.md`). A std
module importing another std module is `undefined` at run time on commonJS and `undef` on erlang
(C-03's row in `language-gaps.md`), so the purity refusal below is vacuous on the day it lands and
stops being vacuous when that row closes.

## Mechanism — decisions [106](../../decisions-taken.md#106-std-in-three-categories-a-pure-root-io-and-testing) and [107](../../decisions-taken.md#107-import-a-dotted-path-and-a-braced-group-are-one-tree-and-only-the-leaf-enters-scope)

**One criterion: `io/` is everything that talks to the world outside the process.** A root module
is pure by definition — same input, same output, no clock, no disk, no network, no entropy — and the
compiler refuses a root module that imports from `io/` (decision 67: no flag). The check holds
**inside std**; for user code `io.` on the import line is a reading signal (`grep 'io\.'`), not a
guarantee — a `declare fn` does what it wants. `testing/` is the harness: `snapshots` writes disk,
`mocks` records calls; impure by nature, only under `botopink test`, may import from `io/` and the
root. `erlang.bp` / `beam.bp` are the target surface, outside the criterion, unchanged.

Two rules of shape: **fuse only where the new name wins** (`dict` + `sets` + `queue` + `order` →
`collections` — the type is the namespace, `collections: {Dict, Set}` instead of `dict.Dict,
sets.Set`, and only inside one file can `Dict.keys()` answer `Set<K>`; `crypto`'s hashes + `hmac` +
`content_hash` → `hash`; `base64` + `encoding` → `encoding`; `json`, `regex`, `unicode`,
`string_builder`, `url`, `querystring` stay — `url` and `querystring` both have `parse`), and **a
directory groups function modules, a file groups types** (`io/fs.bp` is a namespace of functions;
`collections.bp` holds `Dict`, `Set`, `Queue`, `Order`). Purity beats domain at the edges: `random`
and `crypto.randomBytes` → `io/random.bp`; `path.absolutePath` (the one `path` function that reads
the cwd) → `io/fs.bp`; `time` + `clock` → `io/clock.bp`; `os` / `env` / `process` stay separate
under `io/` (`env.get` and `process.exit` in one `system` would read `system.get`).

```
libs/std/src/
  root.bp              pub mod collections; … pub mod io; pub mod testing;
  primitives.bp  builtins.d.bp  builtins_fns.d.bp        ambient — unchanged

  collections.bp       Dict, Set, Queue, Order          (was dict, sets, queue, order)
  math.bp              pi, e, sqrt, …                   (without random)
  path.bp              basename, join, normalize, …     (without absolutePath)
  url.bp  querystring.bp  json.bp                       (unchanged)
  encoding.bp          base64 + encoding                (was base64; encoding from front 01)
  hash.bp              sha256, sha512, md5, hmac, contentHash   (was crypto without randomBytes; hmac from 01, content_hash from 03)
  unicode.bp  regex.bp  string_builder.bp  escape.bp    (unchanged; escape from front 01)
  async.bp             combinators over @Future         (front 02, unchanged)
  erlang.bp  beam.bp   the target surface               (unchanged)

  testing/
    mod.bp             pub mod asserts; pub mod snapshots; pub mod mocks;
    asserts.bp  snapshots.bp  mocks.bp                  (unchanged)

  io/
    mod.bp             pub mod fs; pub mod http; …
    fs.bp              readText, writeText, exists, list, mkdir, rm, absolutePath, walk, glob
    http.bp            (was http)
    net.bp             TCP/TLS sockets                  (front 01, server-only)
    clock.bp           nowMillis, monotonicMillis, measureMillis, formatIso8601   (was time; front 01)
    random.bp          coin, bool, intInRange, pick, randomBytes
    os.bp  env.bp  process.bp                           (unchanged)
```

| Before | After |
|---|---|
| `dict`, `sets`, `queue`, `order` | `collections` (`Dict`, `Set`, `Queue`, `Order`) |
| `random`, `crypto.randomBytes` | `io.random` |
| `crypto` (hashes), `hmac` (01), `content_hash` (03) | `hash` |
| `base64`, `encoding` (01) | `encoding` |
| `path` minus `absolutePath`, `walk`, `glob` | `path` |
| `path.absolutePath`, `path.walk`, `path.glob` (host cells), `fs` | `io.fs` |
| `http` · `net` (01) · `time`, `clock` (01) | `io.http` · `io.net` · `io.clock` |
| `os`, `env`, `process` | `io.os`, `io.env`, `io.process` |
| `asserts`, `snapshots`, `mocks` | `testing.asserts`, `testing.snapshots`, `testing.mocks` (decision 71: name and uniqueness kept, path amended) |
| `math`, `json`, `regex`, `unicode`, `string_builder`, `url`, `querystring`, `escape` (01), `async` (02), `erlang`, `beam` | unchanged |

`testing`, not `test` — `test` is a keyword (`test "…" { }`) and `import {test}` does not parse.
`io/mod.bp` and `testing/mod.bp` are the directory `mod.bp` of the module system (v0.beta.11);
`root.bp` gains `pub mod io;` and `pub mod testing;` and loses the moved lines. Decision 106 moves
paths, not function names: `io.clock` keeps `nowMillis`, `monotonicMillis`, `measureMillis`,
`formatIso8601`; `encoding.bp` carries `base64`'s four functions under front 01's names
(`base64Encode`, `base64Decode`, `base64UrlEncode`, `base64UrlDecode`).

**Import grammar (107):**

```
ImportDecl := "import" "{" ImportList "}" ("from" String)? ";"
ImportList := ImportItem ("," ImportItem)* ","?
ImportItem := DottedName ("*" | "as" Ident)?        // a dotted path — one leaf
            | Ident ":" "{" ImportList "}"          // a group — several leaves under one prefix
DottedName := Ident ("." Ident)*
```

Both spellings produce the same `ImportPath{segments, activate, alias}` per leaf: `a: {b: {c}}` is
`a.b.c`; `io: {fs: {readText, writeText}}` is two paths with `io.fs` written once; they mix in one
list; without `from`, the list imports from the current package's root (the `.root` the parser
already produces). Rules:

- **Only the leaf enters scope.** `import {io.fs.readText}` brings `readText`, neither `io` nor `fs`;
  `io: {fs: {readText}}` likewise. Both are written to get both: `import {io, io.fs.readText}`.
- **An intermediate node may be a leaf.** `import {io.fs}` and `import {io: {fs}}` bring `fs` as a
  namespace; inside a group the prefix itself is a leaf if listed: `io: {fs, fs: {readText}}`.
- **`*` and `as` belong to the leaf**, in either spelling; on a node that opens braces
  (`io* : {…}`) they are a syntax error. `collections.ArraySets*` and `collections: {ArraySets*}`
  activate the same extension; `collections*` (a namespace) is `notAnExtension` — each extension is
  opt-in by name, so a reader sees where `toSet` came from.
- **A leaf collision is `import-name-collision`** at the second item, in either spelling:
  `import {url.parse, json.parse}` refuses; `import {url.parse as parseUrl, json: {parse as parseJson}}`
  passes.
- **It is a loader feature** (`project_graph.zig` + the four `emitUse`), independent of the std
  tree, which works with the namespace form alone; it holds for every library. `mod` already gives
  the tree (`io.fs` is `pub mod io { pub mod fs; }` in `root.bp`) — nothing new in the file resolver.

```botopink
import {collections, io} from "std";                                   // namespace — unchanged
val d = collections.Dict.empty();  val t = io.fs.readText(p);

import {collections.Dict, io.fs.readText, io.clock.nowMillis} from "std";   // dotted path — one leaf each
import {                                                                     // group — several leaves under one prefix
    collections: {Dict, Set, ArraySets*},
    io: {fs: {readText, writeText}, clock: {nowMillis}},
} from "std";
val s = [1, 2].toSet();

import {html: {div, span, button}, hooks: {state, effect}, router.pathname} from "jhonstart";
import {path: {join, normalize}};                                      // inside std: io/fs.bp reading a pure root module
```

## Steps

### Step 1 — the import tree (decision 107)

`parseImportItem` gains the `Ident ":" "{" … "}"` branch, recursive, flattening to `ImportPath`s
with the prefix; the resolver binds a multi-segment path to its leaf instead of refusing the item;
`alias` is read by `infer.zig` and the four `emitUse`; `import-name-collision`; `*`/`as` on a group
node refused. Lands before the tree, so every consumer can write the new lines against the old
modules and the sweep of step 5 is one edit per file.

**Acceptance:**
- [x] `import {collections.Dict, io: {fs: {readText as read}, clock: {nowMillis}}, collections: {ArraySets*}} from "std";`
      parses, binds `Dict`, `read`, `nowMillis`, activates `ArraySets`, and runs on four targets
      (against step 2's tree; against the flat tree, the same shape over `dict.Dict`)
- [x] `import {url.parse, json.parse}` is `import-name-collision` at the second item;
      `import {url.parse as parseUrl, json: {parse as parseJson}}` compiles; `import {io* : {fs}}` is
      a parse error; `import {main as mainTag} from "jhonstart"` binds `mainTag` (the
      `language-gaps.md` alias row closes here)
- [x] `import {html: {Element, tag}, router.pathname};` inside jhonstart (no `from`) resolves against
      the package root; the LSP resolves the same tree (`project_graph.zig`), one `lsp/` snapshot per
      spelling
- [ ] `docs.md:756`'s grammar replaced; `src/parser/AGENTS.md` in the same commit; no existing
      import snapshot re-records

### Step 2 — the embedded std follows `mod`

std is embedded in the compiler, not resolved from a root: `build.zig`'s `stdPkgFilesFromRoot`
reads `root.bp` flat and lists `src/<name>.bp` per `pub mod` line. It must follow `pub mod io;` /
`pub mod testing;` into `io/mod.bp` and `testing/mod.bp` and embed their modules under the nested
path, the same walk `project_graph.zig` and the loader do for a library. Lands before step 3 with
the tree unchanged, so the only thing it proves is that a nested `mod` embeds.

**Acceptance:** a scratch `pub mod probe;` directory under `libs/std/src/` embeds and its module
resolves from a consumer on four targets, then is deleted; `zig build` with the flat tree byte-identical.

### Step 3 — the tree (decision 106)

The moves and fusions above, by `git mv` where a file survives (fronts 01/02/03 land flat at
`src/<name>.bp`; this step re-homes them — `01-std/README.md` § Order step 7); `root.bp` gains
`pub mod io;` and `pub mod testing;` and loses the moved lines; `io/mod.bp` and `testing/mod.bp` as
directory `mod.bp`s; `absolutePath`, `walk`, `glob` and `randomBytes` re-homed; inline tests travel
with their functions.

**Acceptance:**
- [x] `zig build test-libs`'s std cell at its pre-move count on commonJS and erlang — 417 / 0 on
      each, as before the move (25 modules instead of 31: `base64`'s four tests re-spelled over
      `encoding`'s names, `crypto`'s and `content_hash`'s under `hash`, `randomBytes`' under
      `io.random`)
- [x] every moved function reachable by its new path from a scratch consumer on four targets —
      `collections` (pure) answers on commonJS, erlang, beam and wasm; the host-bound modules
      (`hash`, `encoding`, everything under `io/`, `testing.mocks`/`snapshots`) answer on
      commonJS and erlang and are STD-001-refused on beam and wasm exactly as their flat
      predecessors were; `import {escape, encoding, hash, io: {net, clock}}` and
      `import {testing: {asserts, snapshots, mocks}}` resolve from a consumer and bind only the
      leaves
- [x] `libs/std/AGENTS.md` carries the tree and the old → new table
- [x] `grep -rn 'pub mod \(dict\|sets\|queue\|order\|fs\|time\|clock\|net\|random\|crypto\|hmac\|content_hash\|base64\|http\|os\|env\|process\|asserts\|snapshots\|mocks\)' libs/std/src/root.bp`
      returns nothing — `root.bp` has seventeen lines, `io/mod.bp` eight, `testing/mod.bp` three
- [x] decision 111: `Dict.empty()`, `Set.empty()` / `Set.fromList(xs)`, `Queue.empty()` /
      `Queue.fromList(xs)` are type-scoped and compile on all four backends when the type is
      imported as a leaf (`import {collections.Dict}`, `collections: {Dict, Set}`) — **open:** the
      namespace-qualified spelling `collections.Dict.empty()` after `import {collections}` is
      `unbound variable 'collections'` in the checker (`decisions-pending.md` 23-a)

### Step 4 — the purity refusal

A module under `libs/std/src/` (the root) that imports from `io/` is a located error naming the
module and the `io.` path; `testing/` and `io/` may import anything. Vacuous until the std-to-std
import resolves (C-03's row), and the cell that proves it is written now and carried as an
`expected-failures.txt` line naming that row until then.

**Acceptance:** the `reject/` cell; the refusal has no configuration; `docs.md` § std states the
criterion in one paragraph.

### Step 5 — the consumer sweep

rakun's eight import lines (`config.bp`, `request_context.bp`, `events.bp`,
`autoconfig_registry.bp`, `file_router.bp`, `ssr.bp`, `ssl_bundle.bp`,
`constraints.bp` of `libs/validation` — rakun-validation's until `01-std/06-validation-lib` moves it, decision 116) and every `<lib>-test` member's
`import {testing: {asserts, snapshots, mocks}} from "std";` — `#[mocks.mock]`, `mocks.when`,
`mocks.verify` letter for letter; through `known-red-libs.txt` as 21 step 4.

```botopink
import {io: {fs, env, random}} from "std";           // config.bp
import {hash} from "std";                            // request_context.bp
import {io.clock} from "std";                        // events.bp
import {collections.Dict, io.fs} from "std";         // file_router.bp
import {path, io: {fs, process}} from "std";         // ssl_bundle.bp
import {regex, io.clock} from "std";                 // validation/constraints.bp
```

`request_context.bp` reads `import {hash, io.random} from "std";` — its token is
`randomBytes`, which is `io.random`'s. The `<lib>-test` members import nothing from std today, so
no `testing:` line was owed; routing, actions and validation (bundled, decision 116) import
`testing.asserts`, `collections.Dict`, `io.clock`.

**Acceptance:**
- [x] every library and example at its pre-sweep counts on its assigned rows — `zig build
      test-libs` from an rsync copy, per-cell counts identical to the pre-move baseline (58
      passed / 0 failed, 19 restricted at their pins; rakun 369 / 0 commonJS, rakun-web 104 / 0
      erlang, jhonstart 120, emilia 569, erika 31, onze 8, routing 66, actions 19, validation 54
      on both rows)
- [x] `grep -rn 'from "std"' repository/*/modules repository/*/examples` shows no retired module
      name in an import — the remaining hits are prose in the compiler's own sources (codegen and
      checker comments that recount a defect under its flat-tree spelling, in files held by
      parallel fronts) and the deliberate `import {dict.Dict}` of the "prefix is no module" test
- [x] `known-red-libs.txt` back to its header — rakun's seventeen cells (and fourteen restricted
      pins at `build`) were in the ledger for exactly the one commit before rakun's sweep
- [x] the meta pointers bumped

### Step 6 — decisions 110 and 111 on the use side

Decision 110 amends 107 after steps 1–5 were specified: `as` binds a type leaf as a checker-local
name (the emitted identity stays the declaration's), and a leaf that names a folder module is a
namespace of its submodules. Decision 111's constructors are type-scoped; reaching one through the
module namespace is the same use-side path as 110's rule 2. `project_graph.zig` (folder leaf as
namespace), `comptime/infer.zig` (type alias; `ns.Type.fn()`), the hover and diagnostic renderers.

**Acceptance:**
- [ ] `import {collections.Dict as D} from "std"; val d: D<string, i32> = D.empty();` compiles on
      four targets and hovers `D` = `Dict`; `import-alias-on-type` is gone and
      `reject/import_alias_on_type.bp` with it
- [ ] `import {io} from "std"; io.fs.readText(p)` resolves (today `unknown "std" module`)
- [ ] `import {collections} from "std"; collections.Dict.empty()` resolves on four targets (today
      `unbound variable 'collections'`)

## Gate

- [x] `scripts/gate.sh --cold` green at every commit; `test-libs` at baseline (the ledger only during
      step 5) — steps 3 and 5: green from an rsync copy at each compiler commit (the tree with
      rakun's seventeen cells in the ledger; the ledger back to its header; the headers), `test-libs`
      58 / 0 with per-cell counts identical to the pre-move run, `test-language` 799 / 28 expected / 0
- [ ] `zig build test-language` green on four targets with the import cells;
      `modules/language-server` tests green with the `project_graph.zig` cells
- [ ] `AGENTS.md` of `src/parser/`, `src/comptime/`, `src/codegen/`, `libs/std/`,
      `modules/language-server/` in the same commit
- [ ] Commit on `fix/std-purity`; no push, no merge — landing is the maintainer's step

## Blast radius

Every std module name in a snapshot (the erlang atoms `std@dict`, `std@time`, … and the commonJS
`require` paths); every library import of a moved module (rakun 8 files; the `-test` members);
[`01-std/modules.md`](../../01-std/modules.md)'s module list and its `test-snap.md`'s `escape`
filenames describe the flat root and are the maintainer's; [`contracts.md`](../../contracts.md)
§ 3 spells `hash.hmacSha256`. Two renames beside the moves: `path.walk` / `path.glob` (front 01's
host cells) become `io.fs.walk` / `io.fs.glob` under 106's criterion, and `base64`'s four functions
become `encoding.base64Encode` / `base64Decode` / `base64UrlEncode` / `base64UrlDecode` (front 01's
names). Nothing changes what any function answers.

## Handoff

- **To C-03 / `language-gaps.md`'s "a std module cannot call another std module":** step 3's
  refusal is what turns that row from a limitation into a rule the moment it closes — decision 106
  relies on the cross-module import staying closed only *inside* std, as the purity rule a root
  module may not break, never as a limitation.
- **To [`01-std`](../../01-std/README.md):** the seven new modules land in the flat root and are
  re-homed here, not written twice.

## Notes

- Decision 71 is amended in path only: `std/mocks` is `testing.mocks`, one module, lib-agnostic.
- The formatter has no rule converting the dotted spelling to the grouped one or back; a dot is for
  one leaf, braces for several under one prefix.
