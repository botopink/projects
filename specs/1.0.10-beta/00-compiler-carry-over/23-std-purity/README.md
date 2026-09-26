# Front 23 — std purity: a pure root, `io/`, `testing/`, and the import tree

**Track:** compiler (carry-over item **C-31**) — the compiler half is the import grammar and the
loader; the library half is `libs/std`
**Priority:** high — the tree, the import grammar and decisions 110/111's use side (step 6) are in;
what is left is the gate's open rows.
**Depends on:** [`01-std`](../../01-std/README.md) lands new std modules at their final path in this
tree. Shares `parser/decls.zig` with [`21-effect-chain`](../21-effect-chain/README.md).
**Owns:** `parser/decls.zig`'s `parseImportItem` (the grouped form) · `ast.zig`'s `ImportPath` if
the grouped form needs a field · `comptime/infer.zig`'s import binding (the multi-segment leaf,
`alias`, `import-name-collision`, the std-internal purity refusal) ·
`codegen/{commonJS,erlang,beam_asm,wat}.zig`'s `emitUse` (the leaf and the alias) ·
`modules/language-server/src/project_graph.zig` (the same tree for the LSP — a named carve-out of
[`11-tooling`](../11-tooling/README.md)) · `repository/botopink-lang/build.zig`'s
`stdPkgFilesFromRoot` (std is **embedded**, not resolved: it follows `pub mod io;` /
`pub mod testing;` into `io/mod.bp` and `testing/mod.bp`) · `libs/std/src/**` (the tree of decision
106: `root.bp`, `io/mod.bp`, `testing/mod.bp`, every module) ·
`libs/std/AGENTS.md` · `docs.md` § imports, § std · the snapshots that carry a std module name · in
`repository/rakun` and every `<lib>-test` member: the import lines.
**Does not touch:** `builtins.d.bp`, `primitives.bp`, `builtins_fns.d.bp` (ambient — unchanged;
`builtins.d.bp` is 21's) · `erlang.bp`, `beam.bp` (the target surface; outside the criterion) ·
`parser/exprs.zig`, `lexer.zig` (22) · the `-test` members' helper bodies (the libraries') ·
`mocks.bp`'s content (decision 71 fixed its name and uniqueness).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise.

---

## Current state

std is the tree below; the import grammar is decision 107's. The purity refusal is in `infer.zig`
(`std-root-imports-io`). Decisions 110 and 111's use side (step 6): `as` binds a type leaf as a
checker-local name; a folder leaf is a namespace of its submodules (`import {io} from "std";
io.fs.readText(p)`), and a module namespace reaches its types (`collections.Dict.empty()`) — both
rewritten by `comptime/std_namespace.zig` into the one-dot forms before the checker and the backends
see the module (`decisions-pending.md` std-c).

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

  collections.bp       Dict, Set, Queue, Order
  math.bp              pi, e, sqrt, …
  path.bp              basename, join, normalize, …
  url.bp  querystring.bp  json.bp
  encoding.bp          base64Encode, base64Decode, base64UrlEncode, base64UrlDecode, hex
  hash.bp              sha256, sha512, md5, hmac, contentHash
  unicode.bp  regex.bp  string_builder.bp  escape.bp
  async.bp             combinators over @Task
  erlang.bp  beam.bp   the target surface

  testing/
    mod.bp             pub mod asserts; pub mod snapshots; pub mod mocks;
    asserts.bp  snapshots.bp  mocks.bp

  io/
    mod.bp             pub mod fs; pub mod http; …
    fs.bp              readText, writeText, exists, list, mkdir, rm, absolutePath, walk, glob
    http.bp
    net.bp             TCP/TLS sockets (server-only)
    clock.bp           nowMillis, monotonicMillis, measureMillis, formatIso8601
    random.bp          coin, bool, intInRange, pick, randomBytes
    os.bp  env.bp  process.bp
```

`testing`, not `test` — `test` is a keyword (`test "…" { }`) and `import {test}` does not parse.
`io/mod.bp` and `testing/mod.bp` are the directory `mod.bp` of the module system; `root.bp` holds
`pub mod io;` and `pub mod testing;`. `libs/std/AGENTS.md` carries the tree and the table of the
retired flat names.

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
  tree; it holds for every library. `mod` gives the tree (`io.fs` is `pub mod io { pub mod fs; }` in
  `root.bp`) — nothing new in the file resolver.

```botopink
import {collections, io} from "std";                                   // namespace (step 6)
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
node refused.

**Acceptance:**
- [x] `import {collections.Dict, io: {fs: {readText as read}, clock: {nowMillis}}, collections: {ArraySets*}} from "std";`
      parses, binds `Dict`, `read`, `nowMillis`, activates `ArraySets`, and runs on four targets
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
follows `pub mod io;` / `pub mod testing;` into `io/mod.bp` and `testing/mod.bp` and embeds their
modules under the nested path, the same walk `project_graph.zig` and the loader do for a library.

### Step 3 — the tree (decision 106)

The tree above; inline tests travel with their functions.

**Acceptance:**
- [x] `zig build test-libs`'s std cell at its pre-move count on commonJS and erlang (417 / 0 on each)
- [x] every moved function reachable by its new path from a scratch consumer on four targets —
      `collections` (pure) answers on commonJS, erlang, beam and wasm; the host-bound modules
      (`hash`, `encoding`, everything under `io/`, `testing.mocks`/`snapshots`) answer on
      commonJS and erlang and are STD-001-refused on beam and wasm; `import {escape, encoding, hash, io: {net, clock}}` and
      `import {testing: {asserts, snapshots, mocks}}` resolve from a consumer and bind only the
      leaves
- [x] `libs/std/AGENTS.md` carries the tree and the old → new table
- [x] `root.bp` declares no flat module that moved under `io/` or `testing/` or fused into
      `collections`, `hash` or `encoding` — `root.bp` has seventeen lines, `io/mod.bp` eight,
      `testing/mod.bp` three
- [x] decision 111: `Dict.empty()`, `Set.empty()` / `Set.fromList(xs)`, `Queue.empty()` /
      `Queue.fromList(xs)` are type-scoped and compile on all four backends when the type is
      imported as a leaf (`import {collections.Dict}`, `collections: {Dict, Set}`), and through the
      namespace (`collections.Dict.empty()` after `import {collections}`, step 6)

### Step 4 — the purity refusal

A module under `libs/std/src/` (the root) that imports from `io/` is a located error naming the
module and the `io.` path (`std-root-imports-io`, `infer.zig`; the `std_package_a_root_module_importing_*`
codegen snapshots); `testing/` and `io/` may import anything.

**Acceptance:** the `reject/` cell; the refusal has no configuration; `docs.md` § std states the
criterion in one paragraph.

### Step 5 — the consumer sweep

The consumers import from the tree — rakun's `config.bp`, `request_context.bp`, `events.bp`,
`autoconfig_registry.bp`, `file_router.bp`, `ssr.bp`, `ssl_bundle.bp`, and `constraints.bp` of
`libs/validation` (decision 116); a `<lib>-test` member writes
`import {testing: {asserts, snapshots, mocks}} from "std";` with `#[mocks.mock]`, `mocks.when`,
`mocks.verify`.

```botopink
import {io: {fs, env, random}} from "std";           // config.bp
import {hash} from "std";                            // request_context.bp
import {io.clock} from "std";                        // events.bp
import {collections.Dict, io.fs} from "std";         // file_router.bp
import {path, io: {fs, process}} from "std";         // ssl_bundle.bp
import {regex, io.clock} from "std";                 // validation/constraints.bp
```

`request_context.bp` reads `import {hash, io.random} from "std";` — its token is `randomBytes`,
which is `io.random`'s. Routing, actions and validation (bundled, decision 116) import
`testing.asserts`, `collections.Dict`, `io.clock`.

**Acceptance:**
- [x] every library and example at its pre-sweep counts on its assigned rows (`zig build
      test-libs`, per-cell counts identical to the pre-move baseline)
- [x] `grep -rn 'from "std"' repository/*/modules repository/*/examples` shows no retired module
      name in an import — the remaining hits are prose in the compiler's own sources and the
      deliberate "prefix is no module" test
- [x] `known-red-libs.txt` back to its header
- [x] the meta pointers bumped

### Step 6 — decisions 110 and 111 on the use side

Decision 110 amends 107: `as` binds a type leaf as a checker-local
name (the emitted identity stays the declaration's), and a leaf that names a folder module is a
namespace of its submodules. Decision 111's constructors are type-scoped; reaching one through the
module namespace is the same use-side path as 110's rule 2. `project_graph.zig` (folder leaf as
namespace), `comptime/infer.zig` (type alias; `ns.Type.fn()`), the hover and diagnostic renderers.

**Acceptance:**
- [x] `import {collections.Dict as D} from "std"; val d: D<string, i32> = D.empty();` compiles on
      four targets and hovers `D` = `Dict`; `import-alias-on-type` is gone and
      `reject/import_alias_on_type.bp` with it — `tests/language/modules/import_alias_on_type` and
      `import_std_type_through_module` run on commonJS, erlang, beam and wasm; the hover card of `D`
      reads `D = Dict` (`language-server` "hover: a std type imported under an alias hovers as the
      declared type"); no `import-alias-on-type` and no `reject/import_alias_on_type.bp` is left
- [x] `import {io} from "std"; io.fs.readText(p)` resolves — `io.fs.exists("/")` runs on commonJS
      and erlang; `modules/import_std_folder_namespace` (`io.clock` through the folder) runs on
      commonJS, erlang and beam and is refused on wasm by STD-001 as `import {io.clock}` is
- [x] `import {collections} from "std"; collections.Dict.empty()` resolves on four targets —
      `modules/import_std_type_through_module` (`Dict`, `Set`, `Queue` through the namespace, beside
      `collections.lt()`) on commonJS, erlang, beam and wasm

## Gate

- [x] `scripts/gate.sh --cold` green at every commit; `test-libs` at baseline
- [ ] `zig build test-language` green on four targets with the import cells;
      `modules/language-server` tests green with the `project_graph.zig` cells
- [ ] `AGENTS.md` of `src/parser/`, `src/comptime/`, `src/codegen/`, `libs/std/`,
      `modules/language-server/` in the same commit
- [ ] Commit on `fix/std-purity`; no push, no merge — landing is the maintainer's step

## Blast radius

Every std module name in a snapshot (the erlang atoms and the commonJS `require` paths) and every
library import follows the tree. [`01-std/modules.md`](../../01-std/modules.md) and its `test-snap.md`
are the maintainer's; [`contracts.md`](../../contracts.md) § 3 spells `hash.hmacSha256`.

## Handoff

- **To C-03 / `language-gaps.md`'s "a std module cannot call another std module":** step 4's
  refusal is the rule — decision 106 closes the cross-module import only *inside* std, as the purity
  rule a root module may not break, never as a limitation.
- **To [`01-std`](../../01-std/README.md):** a new std module lands at its path in this tree.

## Notes

- Decision 71 holds with the path `testing.mocks`: one module, lib-agnostic.
- The formatter has no rule converting the dotted spelling to the grouped one or back; a dot is for
  one leaf, braces for several under one prefix.
