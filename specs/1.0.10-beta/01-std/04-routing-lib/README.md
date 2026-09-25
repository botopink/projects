# Front 04 (std track) — the bundled `routing` library

The directory number is this front's index inside `01-std`, beside `01`/`02`/`03`; it is not a
milestone front number — rakun's front 04 is `03-rakun/04-rakun-erlang-runtime`. Everywhere else it
is named `01-std/04-routing-lib`.

**Track:** A std
**Priority:** critical — the route matcher is the one piece of code the server and the browser must
run identically (`contracts.md § 1`), and since decision 115 it has no other home: rakun front 22
cannot serve a route, jhonstart front 26 cannot navigate, and the `k` / `z` / URL-rule blobs of
fronts 60, 61 and 65 cannot be read in the browser until this library exists
**Target:** both — erlang and commonJS, every module. The library is pure: no HTTP, no state, no
host cell, so there is no half that runs on one target only
**Wave:** 0 — beside `01-std`'s own steps; Steps 1–3 before rakun 22 and jhonstart 26 (waves 1–2),
Steps 4–6 before rakun 60, 61 and 65
**Depends on:** `01-std` step 2 (`testing.asserts`, which its tests are written with) ·
`01-std/01-std-lib-enablement` step 3 (`encoding.percentDecode`, for Step 6 only) ·
`00 · 23-std-purity` for Step 2 — the bundled-library registry generalises the std registry that
front rewrites (`build.zig`'s `stdPkgFilesFromRoot`, the four `emitUse`, `project_graph.zig`), so
Step 2 opens after 23 lands. Steps 1 and 3–6 do not wait on it: the library is compiled and tested
from its own directory as an ordinary package until Step 2 bundles it
**Owns:** `repository/botopink-lang/libs/routing/**` (`botopink.json`, `AGENTS.md`, `src/root.bp`,
`src/segment.bp`, `src/table.bp`, `src/match.bp`, `src/route_kinds.bp`, `src/slot_states.bp`,
`src/url_rules.bp`, `test/**`) · the `routing` row of `repository/botopink-lang/libs/AGENTS.md` ·
**by carve-out from `00`** (Step 2, granted in `00`'s README the way `@src()`'s was): the
bundled-library registry in `build.zig`, the `"std"` package checks named in *Mechanism* in
`modules/compiler-core/src/{comptime.zig, comptime/infer.zig, codegen/commonJS.zig,
codegen/erlang.zig, codegen/beam_asm.zig}`, `modules/compiler-cli/src/cli/resolver.zig`,
`modules/language-server/src/engine.zig`, their tests, and `scripts/format-check.sh`'s `TREES`
**Does not touch:** `libs/std/**` (the other `01-std` fronts and `00 · 23-std-purity`);
`repository/rakun/**` — rakun front 22 Step 7 switches rakun to this library and deletes rakun's
copy, fronts 60, 61 and 65 import the codecs from it; `repository/jhonstart/**` — front 26 imports
it in the router, front 27 in `Link`; `repository/onze/**`
**Reference:** [decision 115](../../decisions-taken.md#115-routing-is-a-bundled-library-a-signal-after-the-first-chunk-is-markup-jhonstart-gains-redirect-rakuns-keys-are-rakun)
(the library, its contents, `from "routing"` resolving like `from "std"`) · decision 109 (module
atoms) · decision 113 (jhonstart and rakun never import each other) · `contracts.md § 1` (the route
table) · rakun fronts [22](../../03-rakun/22-rakun-file-routing/README.md) Steps 1, 3, 4,
[60](../../03-rakun/60-rakun-static-generation/README.md) Step 6,
[61](../../03-rakun/61-rakun-parallel-intercepting-routes/README.md) Step 5,
[65](../../03-rakun/65-rakun-url-rules/README.md) Steps 2–3 (the formats this library implements)

---

## Problem

The server and the browser have to agree on which route a URL is, which routes are static, which
parallel slots rendered, and what a URL looks like under `basePath`. Each of those is a small pure
function over a line-oriented wire, and each must be **one** implementation compiled twice, or the
two sides drift (`contracts.md § 1`). Decision 114 put them in a rakun member, `rakun-routing`, and
had onze hand the matcher to jhonstart's router as a value, because jhonstart may not import rakun.
Decision 115 moves them out of rakun altogether: a library neutral like std, bundled with the
compiler, that rakun and jhonstart both import by name.

Today there is no such library. The matcher exists, but inside rakun's core module, beside the
registry host cells and the `app/` scan, and it imports rakun's own `config` and `runtime` modules;
the three codecs exist only as specifications. And the compiler has exactly one bundled package:
`from "std"` is special-cased at a dozen sites, and `from "<anything else>"` is a declared
dependency found on disk.

## Current state

Measured 2026-09-25 on `repository/botopink-lang` `ac5f5703` and `repository/rakun` `a8ba8bd`.

| Piece | State | Evidence |
|---|---|---|
| The matcher | in rakun's core module, 1 030-line file mixing it with the registry and the scan | `repository/rakun/modules/rakun/src/file_router.bp:49-479` (grammar, wire, matcher) · `:480-523` (`PageContext`, `LayoutProps`, `contextOf` — jhonstart's since decision 114) · `:525-1030` (host-cell registry, UI decorators, `app/` scan) |
| Its imports | `std` (`dict`, `fs`) and three rakun modules | `file_router.bp:44-47` — `Request` from `"http"`, `rkProp` from `"runtime"`, `charOf`/`sub` from `"config"` (`config.bp:62-75`, the substring helpers the commonJS row needs) |
| Its tests | 26 pure tests, 5 registry tests | `repository/rakun/modules/rakun/test/file_router_test.bp:62-332` (segment, wire, match, chain) · `:373-435` (registry, context) |
| `k`, `z`, URL-rule codecs | specified, not written | rakun 60 Step 6, 61 Step 5, 65 Steps 2–3 |
| The one bundled package, `std` | embedded at build time from its module tree | `build.zig:25-56` generates `std_pkg_modules.zig` (`{ path = "std/<mod>", source = @embedFile(…) }`) from `stdPkgFilesFromRoot` (`build.zig:569-646`, a walk of `libs/std/src/root.bp`'s `pub mod` lines); `stdPreludeModule` (`build.zig:510-555`) wires it into `std_prelude`, re-exported as `pkg_modules` (`comptime/stdlib/prelude.zig:33`) |
| `from "std"` in the compiler | the literal `"std"` / prefix `"std/"`, at every site below | `comptime.zig:629` (`std_pkg_modules`), `:730-741` (`isStdModule`, `isStdPkgPath`), `:746-795` (`expandStdImports` — prepends the needed modules, `srcPath` `src/<mod>.bp`), `:809`, `:1187-1200` (each module inferred in a scratch env) · `comptime/infer.zig:110`, `:136` (`markStdImports`) · `codegen/commonJS.zig:2554-2575` (`require("<prefix>std/<mod>.js")`) · `codegen/erlang.zig:4218-4221` (`stdModuleAtom`), `:4233` · `codegen/beam_asm.zig:1911-1914`, `:1925`, `:2002` · `language-server/src/engine.zig:577-590` (`std_modules`) |
| std-only checks | stay std-only | `comptime/infer.zig:105` (`checkStdRootPurity`, decision 106), `:9375` (no method dispatch inside std), `codegen/erlang.zig:330` (the `std/erlang` BIF table), `comptime.zig:1424`, `:1627` (synthesised std imports) |
| The dependency check | exempts `"std"` by name | `compiler-cli/src/cli/resolver.zig:620` (`checkImportSources`), `:763` |
| The disk loader | already scans `libs/` as the bundled root | `compiler-cli/src/cli/libs.zig:63-78`, `:181-187` — `D/repository/botopink-lang/libs` is a lib root, so `libs/routing` is *found* by name inside the meta workspace, but only as a declared dependency and only inside it |
| `test-libs` | discovers every `libs/*/botopink.json` | `modules/lib-test-runner/src/discovery.zig:76-100` (the same roots); `scripts/test-libs.sh:8`; CI `.github/workflows/test.yml:187` — so `libs/routing` becomes a `routing` cell with no runner change |
| bpmp | knows nothing of std | no `libs/` or `"std"` reference under `modules/bpmp/src/`; std ships inside the compiler binary, so a bundled library needs nothing from bpmp. `02-packaging` § the dependency rules: "`std` is never listed — it is embedded" |
| The lib-agnostic gate | compiler-core may name `std` and no library | `build.zig:232-245` (`! grep -riIE 'rakun\|jhonstart\|erika' modules/compiler-core/src`) |

## Mechanism

**What a second bundled library needs**, derived from what std has:

| Need | std today | For `routing` |
|---|---|---|
| A package directory | `libs/std/` with `botopink.json`, `src/root.bp`, `AGENTS.md` | `libs/routing/`, same shape (Step 1) |
| Embedding | `stdPkgFilesFromRoot` walks `libs/std/src/root.bp`; one generated table | the walk takes the package directory; the generated table carries one row per module of **every** bundled package, keyed `<package>/<module>` (`routing/match`). The bundled list is a constant in `build.zig` — `std`, `routing` — and nowhere else |
| `from "<pkg>"` resolution | `expandStdImports` matches the literal `"std"` | matches any name that owns a row in the table; a module is prepended with `srcPath` `src/<mod>.bp` inside its own package, as std's are (decision 73) |
| Checker, codegens, LSP | the `"std"` literal at the sites listed above | a `isBundledPackage(name)` read from the generated table replaces each literal; commonJS requires `<prefix><pkg>/<mod>.js`; erlang/BEAM atoms come from the module path through the cross-module index, so `routing/match` renders `routing@match` and a type `routing@match@@RouteMatch` (decision 109) with no new code there |
| std-only rules | root purity, no dispatch inside std, the BIF table, synthesised imports | unchanged, still keyed on `std/` — `routing` is ordinary code to the checker |
| The dependency check | `resolver.zig:620` skips `"std"` | skips every bundled name; a manifest that **lists** a bundled name in `dependencies` is refused with a located error, as `02-packaging` states for std |
| Tests | `libs/std` is a `test-libs` cell | `libs/routing` is a cell by discovery; its `targets` limit it to erlang and commonJS |
| Format | `libs/std` in `format-check.sh`'s `TREES` (red, named) | `libs/routing` joins `TREES` green on the day it lands |
| The lib-agnostic gate | `std` is the allowed exception | compiler-core spells no bundled package but `std`; `routing` appears only in `build.zig`'s list |

The library itself is the matcher of rakun's `file_router.bp`, cut at the line decision 114 drew
(the UI records are jhonstart's) and freed of its three rakun imports, plus the three codecs rakun
fronts 60, 61 and 65 specify. Its module tree:

```
libs/routing/
├── botopink.json        "name": "routing", "target": "erlang", "targets": ["erlang", "commonJS"],
│                        "src": "src/", "entry": "root.bp", "files": [the seven modules]
├── AGENTS.md
├── src/root.bp          pub mod segment; pub mod table; pub mod match;
│                        pub mod route_kinds; pub mod slot_states; pub mod url_rules;
├── src/segment.bp       SegmentKind, Segment, parseSegment, parsePath, patternOf, slotOf, pathProblem
├── src/table.bp         RouteEntry, parseTable, writeTable, kindLabel
├── src/match.bp         RouteMatch, matchPath, layoutChain, paramOf, splitPath
├── src/route_kinds.bp   RouteKind, parseKinds, writeKinds, routeKindOf           (the `k` blob)
├── src/slot_states.bp   SlotState, parseSlotStates, writeSlotStates              (the `z` blob)
├── src/url_rules.bp     PathRules, canonicalize, clientHref,
│                        RedirectRule, parseRedirectTable, writeRedirectTable
└── test/                segment_test.bp · table_test.bp · match_test.bp ·
                         route_kinds_test.bp · slot_states_test.bp · url_rules_test.bp
```

It imports `std` and nothing else. Consumers write `import {match.matchPath, table.parseTable} from
"routing";` (decision 107's grammar).

## Steps

### Step 1 — Scaffold `libs/routing`

`botopink.json`, `AGENTS.md`, `src/root.bp` declaring the six modules, and the `routing` row of
`libs/AGENTS.md` (*Provides*: the route matcher and the routing wires; *Embedded in compiler?*: yes,
from Step 2).

**Acceptance:**
- [ ] `libs/routing/botopink.json` reads `"name": "routing"`, `"targets": ["erlang", "commonJS"]`
      with erlang first, and lists every `src/*.bp` in `files`
- [ ] `grep -rn "External\|declare fn\|rakun\|jhonstart\|onze\|emilia" libs/routing/src` is empty —
      no host cell, no library name
- [ ] `zig build test-libs -- --lib routing` lists the two cells `routing · erlang` and
      `routing · commonJS` and no other target
- [ ] `libs/AGENTS.md`'s tree and packages table name `routing/`

### Step 2 — Bundle it with the compiler

`build.zig`: the walk and the generated table take a package directory, and a constant
`bundled_packages = .{ "std", "routing" }` drives them; `std`'s three core files
(`primitives.bp`, `builtins.d.bp`, `builtins_fns.d.bp`) stay std-only. compiler-core: the
generated table is the one list of bundled names; each `"std"` package check in *Current state*
becomes a lookup in it, and each `std/`-prefixed path built for a module (`commonJS.zig:2575`,
`erlang.zig:4219`, `beam_asm.zig:1912`) is built from the import's package. The std-only rules keep
their `std/` test. `resolver.zig` exempts the bundled names and refuses one listed in a manifest's
`dependencies`. The LSP's `std_modules` becomes the bundled modules, so completion and hover work in
a `from "routing"` import.

**Acceptance:**
- [ ] a scratch project with **no** `dependencies` builds `import {match.matchPath, table.parseTable}
      from "routing";` on `--target erlang` and `--target commonJS`, and running it matches
      `/blog/x` against `P|/blog/[slug]` — the same result on both
- [ ] the erlang output names the module `routing@match` and the record `routing@match@@RouteMatch`;
      the commonJS output requires `./routing/match.js`
- [ ] a manifest with `"dependencies": { "routing": … }` is refused with a located error naming the
      key; `from "routing"` from inside the meta workspace resolves the embedded copy, never the
      directory the disk loader would find
- [ ] `grep -rn '"routing' modules/compiler-core/src` is empty; the lib-agnostic gate is unchanged
- [ ] the compiler's `snapshots/codegen/**` are byte-identical — the std path is unchanged
- [ ] `codegen/tests/std_package.zig`'s pattern gains a bundled-package test (two packages in the
      registry, an import from each, both atoms)
- [ ] `modules/compiler-core/AGENTS.md`, `modules/compiler-cli/AGENTS.md` and `libs/AGENTS.md`
      describe the bundled-package list in the same commit

### Step 3 — Port the matcher from rakun

`segment.bp`, `table.bp` and `match.bp` are `file_router.bp:49-479` moved, not rewritten: the
grammar (`:49-200`), the wire (`:201-270`), the matcher (`:271-479`). Three changes only:

- `charOf` and `sub` (`config.bp:62-75`) become private functions of `segment.bp` — the
  commonJS row still needs them (`file_router.bp:36`), and the library may not import rakun;
- `Request`, `rkProp` and `fs` are not imported — nothing in `:49-479` uses them;
- `dict.empty()` is spelled as std spells it when this lands (`Dict.empty()` after decision 111).

`PageContext`, `LayoutProps`, `contextOf` and `emptyParams` (`:480-523`) do not move: they are
jhonstart front 30's (decision 114). The tests at `file_router_test.bp:62-332` move with the code,
split per module, suite `routing:`; the registry and context tests (`:373-435`) stay rakun's and
jhonstart's.

**Acceptance:**
- [ ] every acceptance line of rakun front 22 Steps 1, 3 and 4 is a test here, green on erlang and on
      commonJS with the same literals
- [ ] `parseTable(writeTable(xs))` equals `xs` field by field for one entry of each of the eight kinds
- [ ] the 26 moved tests keep their assertions; `diff` of each function body against
      `file_router.bp` shows only the three changes above

### Step 4 — The `k` blob: `route_kinds.bp`

Rakun front 60 Step 6's codec, as specified there: `pattern|K` lines, `K` `S` or `D`;
`RouteKind { Static, Dynamic }` lives here, because the codec returns it, and rakun's static
generation imports it.

```bp
pub type RouteKind { Static, Dynamic }
pub fn parseKinds(wire: string) -> Array<#(string, RouteKind)>
pub fn writeKinds(kinds: Array<#(string, RouteKind)>) -> string
pub fn routeKindOf(wire: string, pattern: string) -> RouteKind
```

**Acceptance:** front 60 Step 6's five lines, run from `test/route_kinds_test.bp` on both targets —
round trip element by element, the recorded kind, `Dynamic` for `""` and for `"garbage"`.

### Step 5 — The `z` blob: `slot_states.bp`

Rakun front 61 Step 5's codec: `slot|pattern|state` lines, `state` one of `M` `D` `U` `E`.
`SlotState` lives here; rakun's `SlotResolution` (which carries a `RouteEntry` and params) stays in
rakun, and front 61's server half turns its resolutions into the triples this codec writes.

```bp
pub type SlotState { Matched, Defaulted, Unchanged, Empty }
pub fn writeSlotStates(states: Array<#(string, string, SlotState)>) -> string
pub fn parseSlotStates(wire: string) -> Array<#(string, string, SlotState)>
```

**Acceptance:** front 61 Step 5's lines, from `test/slot_states_test.bp` on both targets — the
field-by-field round trip, a `|` in a slot name refused, an unknown letter read as `Empty`.

### Step 6 — The URL rules: `url_rules.bp`

Rakun front 65's boundary half: `PathRules`, `canonicalize`, `clientHref` (its Step 2) and
`RedirectRule` with the `source|destination|permanent` table codec (its Step 3). The rule engine,
`UrlRules`, `pathRulesOf` and `redirectFor` stay in `rakun-web`. Percent-decoding is std's
`encoding.percentDecode` (front 01-std-lib-enablement), applied once.

```bp
pub type PathRules(basePath: string, trailingSlash: bool)
pub fn canonicalize(rules: PathRules, pathname: string) -> string
pub fn clientHref(rules: PathRules, pathname: string) -> string
pub type RedirectRule(source: string, destination: string, permanent: bool)
pub fn writeRedirectTable(rs: Array<RedirectRule>) -> string
pub fn parseRedirectTable(wire: string) -> Array<RedirectRule>
```

**Acceptance:** front 65 Step 2's eight lines and Step 3's blob round trip, from
`test/url_rules_test.bp` on both targets — including the twenty-path inverse and the
`/a%252Fb` → `/a%2Fb` single decode.

### Step 7 — Both targets, in the gate

**Acceptance:**
- [ ] `botopink test --target erlang` and `botopink test --target commonJS` from `libs/routing/` are
      green, and `zig build test-libs` reads `routing · erlang: pass` and `routing · commonJS: pass`
- [ ] every expected wire string in the tests is a literal, not the output of a second call — the
      only form that catches the two targets drifting
- [ ] `libs/routing` is in `scripts/format-check.sh`'s `TREES`, and `botopink format --check` is green
      on it

### Step 8 — rakun and jhonstart import it

Not this front's files — each consumer switches in its own front, after Steps 3–6 land — but this
front is not done until both have:

| Consumer | Front | What it imports |
|---|---|---|
| rakun `file_router.bp` (registry, scan, dispatch) | 22 Step 7 | `segment`, `table`, `match` — and deletes `file_router.bp:49-479` |
| rakun static generation | 60 | `route_kinds` |
| rakun slots | 61 | `slot_states` |
| rakun-web URL rules | 65 | `url_rules` |
| jhonstart router | 26 | `table.parseTable`, `match.matchPath` — the table from the payload's `t` |
| jhonstart `Link` | 27 | `route_kinds.routeKindOf`, `slot_states.parseSlotStates`, `url_rules.clientHref` |

**Acceptance:**
- [ ] `grep -rn "fn matchPath\|fn parseTable\|fn parseKinds\|fn parseSlotStates\|fn canonicalize"
      --include=*.bp repository/` finds only `repository/botopink-lang/libs/routing/src/`
- [ ] no `botopink.json` under `repository/` lists `routing` in `dependencies`
- [ ] `grep -rn "rakun-routing" repository/` is empty

## Test plan

`libs/routing/test/*.bp`, one file per module, suite `routing:`, run by `botopink test --target
erlang` and `--target commonJS` from `libs/routing/`, and by `zig build test-libs` in the ecosystem
gate. Everything is deterministic — no clock, no filesystem, no network. The bundling itself
(Step 2) is tested in the compiler's own suite, beside `codegen/tests/std_package.zig`.

The tests assert: segment classification for all seven kinds and the private-folder and `|`
refusals; the wire round trip on all eight record kinds with no trailing `|`; match precedence,
capture, the optional catch-all, the layout chain and "a layout alone is not public"; the three
blob round trips and their tolerant defaults (`Dynamic`, `Empty`); `canonicalize`/`clientHref` as
inverses and the single decode.

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in the compiler worktree (Step 2)
- [ ] `zig build test-libs` green — `routing` on both targets; std, rakun and jhonstart unchanged
      by this front's commits
- [ ] the compiler's `snapshots/codegen/**` byte-identical
- [ ] `AGENTS.md` of every directory touched (`libs/`, `libs/routing/`, `modules/compiler-core`,
      `modules/compiler-cli/src/cli/`, `modules/language-server`), updated in the same commit
- [ ] `docs.md` names the bundled packages beside § std

## Blast radius

- **Compiler:** the std registry becomes the bundled registry; every std output is unchanged, and a
  program that does not import `routing` is byte-identical. A project that happened to declare a
  disk library named `routing` is refused — none exists under `repository/`.
- **rakun:** `file_router.bp` loses some 430 lines to an import (front 22 Step 7); the 26 moved tests leave
  `file_router_test.bp`. `rakun-routing` is never created.
- **jhonstart:** gains its first import of a package other than std (front 26); nothing of rakun's.
- **onze:** the client entry stops building `match` (front 68).

## Notes

- **Why bundled, not a sibling repository.** The maintainer's words place it in
  `repository/botopink-lang/libs` (decision 115). A library in that directory that were *not*
  embedded would resolve only inside the meta workspace (`libs.zig:63-78`) — an installed compiler
  would not find it — so bundling is what makes `from "routing"` mean the same thing everywhere.
- **Why one front owns all six modules.** Fronts 60, 61 and 65 specify their formats and own their
  server halves; the files that implement the formats sit in one package with one owner, so its
  `root.bp`, manifest and test layout have no appenders.
- **Not in this front.** Removing rakun's copy (front 22), the router's switch (front 26), the late
  signal markup that uses `matchPath` to check a redirect target in jhonstart's render (front 30,
  decision 115 rule 2).
