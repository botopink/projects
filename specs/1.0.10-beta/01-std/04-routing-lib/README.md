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
Steps 4–6 before rakun 60, 61 and 65, Step 7 (`navigation`) before rakun 63 and jhonstart 26, 30 and
31, Step 8 (`pattern`) before rakun 07's matcher switches
**Depends on:** `01-std` step 2 (`testing.asserts`, which its tests are written with) ·
`01-std/01-std-lib-enablement` step 3 (`encoding.percentDecode`, for Step 6 only) ·
`00 · 23-std-purity` for Step 2 — the bundled-library registry generalises the std registry that
front rewrites (`build.zig`'s `stdPkgFilesFromRoot`, the four `emitUse`, `project_graph.zig`), so
Step 2 opens after 23 lands. Steps 1 and 3–6 do not wait on it: the library is compiled and tested
from its own directory as an ordinary package until Step 2 bundles it
**Owns:** `repository/botopink-lang/libs/routing/**` (`botopink.json`, `AGENTS.md`, `src/root.bp`,
`src/segment.bp`, `src/table.bp`, `src/match.bp`, `src/route_kinds.bp`, `src/slot_states.bp`,
`src/url_rules.bp`, `src/navigation.bp`, `src/pattern.bp`, `test/**`) · the `routing` row of `repository/botopink-lang/libs/AGENTS.md` ·
**by named carve-out from `00`** (Step 2 — recorded in `fronts.md` § *Conflict rules* beside `@src()`'s): the
bundled-library registry in `build.zig`, the `"std"` package checks named in *Mechanism* in
`modules/compiler-core/src/{comptime.zig, comptime/infer.zig, codegen/commonJS.zig,
codegen/erlang.zig, codegen/beam_asm.zig}`, `modules/compiler-cli/src/cli/resolver.zig`,
`modules/language-server/src/engine.zig`, their tests, and `scripts/format-check.sh`'s `TREES`
**Does not touch:** `libs/std/**` (the other `01-std` fronts and `00 · 23-std-purity`);
`repository/rakun/**` — rakun front 22 Step 7 switches rakun to this library and deletes rakun's
copy, fronts 60, 61 and 65 import the codecs from it; `repository/jhonstart/**` — front 26 imports
it in the router, front 27 in `Link`; `repository/onze/**`
**Reference:** [decision 115](../../decisions-taken.md#115-routing-is-a-bundled-library-a-signal-after-the-first-chunk-is-markup-jhonstart-gains-redirect-rakuns-keys-are-rakun)
(the library, its contents, `from "routing"` resolving like `from "std"`) ·
[decision 116](../../decisions-taken.md#116-code-two-libraries-both-run-is-neutral-routing-gains-navigation-and-param-actions-and-validation-are-bundled-libraries-std-writes-json)
rules 1 and 9 (the `navigation` and `pattern` modules; the bundled list gains `actions` and
`validation`) · [decision 117](../../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only) rule 8 (a bundled library ships `.bp` files
only) · decision 109 (module
atoms) · decision 113 (jhonstart and rakun never import each other) · `contracts.md § 1` (the route
table) · rakun fronts [22](../../03-rakun/22-rakun-file-routing/README.md) Steps 1, 3, 4,
[60](../../03-rakun/60-rakun-static-generation/README.md) Step 6,
[61](../../03-rakun/61-rakun-parallel-intercepting-routes/README.md) Step 5,
[65](../../03-rakun/65-rakun-url-rules/README.md) Steps 2–3,
[63](../../03-rakun/63-rakun-navigation-signals/README.md) Steps 6–7 (the formats this library
implements) · rakun front [07](../../03-rakun/07-rakun-middleware/README.md)'s matcher (the `:param`
grammar)

---

## Problem

The server and the browser have to agree on which route a URL is, which routes are static, which
parallel slots rendered, and what a URL looks like under `basePath`. Each of those is a small pure
function over a line-oriented wire, and each must be **one** implementation compiled twice, or the
two sides drift (`contracts.md § 1`). They belong to neither framework: rakun may not be imported by
jhonstart, and jhonstart's router is where the browser half runs. Decision 115 gives them a library
neutral like std, bundled with the compiler, that rakun and jhonstart both import by name — so no
package hands the matcher to another as a value.

Today there is no such library. The matcher exists, but inside rakun's core module, beside the
registry host cells and the `app/` scan, and it imports rakun's own `config` and `runtime` modules;
the three codecs exist only as specifications. Two more pieces of routing text are written twice
today (decision 116): the navigation-signal vocabulary — the raised reasons, and the `n` wire form an
action envelope carries — is specified in rakun front 63 with "the browser copy" left to jhonstart
front 26, and rakun-web runs two private `:param` path grammars beside the file-convention one
(`modules/rakun-web/src/middleware.bp:60-110`, `modules/rakun-web/src/filter.bp:545-565`). And the
compiler has exactly one bundled package:
`from "std"` is special-cased at a dozen sites, and `from "<anything else>"` is a declared
dependency found on disk.

## Current state

**Landed 2026-09-26** (Steps 1–9): `libs/routing/` holds the eight modules of *Mechanism*, pure
`.bp`, 66 tests in eight `test/*_test.bp` files, 66 / 0 on erlang and on commonJS, format-clean and
in `TREES`. It is bundled: `build.zig`'s `bundled_packages` (`std`, `routing`, `actions`,
`validation`) generates the table `comptime.bundled_packages`; the CLI (`libs.loadDependencies` →
`appendBundled`) and the LSP (`ProjectGraph.appendBundled`) load the embedded modules of every
bundled package a module imports as `<pkg>/<stem>`, first and in dependency order, so the codegens
see ordinary modules (`routing@match`, `./routing/match.js`) and compiler-core names no package but
`std`. A bundled name in `dependencies` is a located refusal; `checkImportSources` exempts every
bundled name. What differs from *Mechanism*: `expandStdImports` and the std checks were NOT
generalised — `std` keeps its own embedding and rules, and a non-std bundled package reaches the core
the way a declared dependency does (the table above says so). Open: the compiler-suite bundled test
(Step 2, see the box), one `middleware_test` literal (Step 8), and every consumer switch (Step 10).
The table below is the state this front started from.

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
| The navigation vocabulary | specified in rakun front 63 (Steps 1, 6, 7) with the prefix `jhonstart:`; not written | no `navigation.bp` under `repository/rakun/`; the reasons become `nav:` (decision 116 rule 1) |
| The `:param` grammar | two private copies in rakun-web | `middleware.bp:60-110` (`checkMatcher`, `matcherMatches` — literal, `:param`, trailing `:param*`, everything else refused by name) · `filter.bp:545-565` (`routeMatches`, `segments` — literal and `:param`, equal lengths) |

## Mechanism

**What a second bundled library needs**, derived from what std has:

| Need | std today | For `routing` |
|---|---|---|
| A package directory | `libs/std/` with `botopink.json`, `src/root.bp`, `AGENTS.md` | `libs/routing/`, same shape (Step 1) |
| Embedding | `stdPkgFilesFromRoot` walks `libs/std/src/root.bp`; one generated table | the walk takes the package directory and embeds `.bp` files only — no bundled library carries an `.erl` / `.mjs` sidecar under `libs/`, and target-native code is an inline `#[@External]` template (decision 117 rule 8); the generated table carries one row per module of **every** bundled package, keyed `<package>/<module>` (`routing/match`). The bundled list is a constant in `build.zig` — `std`, `routing`, `actions`, `validation` (decision 116) — and nowhere else; `01-std/05-actions-lib` and `01-std/06-validation-lib` add their names to it and change nothing else in the mechanism |
| `from "<pkg>"` resolution | `expandStdImports` matches the literal `"std"` | matches any name that owns a row in the table; a module is prepended with `srcPath` `src/<mod>.bp` inside its own package, as std's are (decision 73) |
| Checker, codegens, LSP | the `"std"` literal at the sites listed above | a `isBundledPackage(name)` read from the generated table replaces each literal; commonJS requires `<prefix><pkg>/<mod>.js`; erlang/BEAM atoms come from the module path through the cross-module index, so `routing/match` renders `routing@match` and a type `routing@match@@RouteMatch` (decision 109) with no new code there |
| std-only rules | root purity, no dispatch inside std, the BIF table, synthesised imports | unchanged, still keyed on `std/` — `routing` is ordinary code to the checker |
| The dependency check | `resolver.zig:620` skips `"std"` | skips every bundled name; a manifest that **lists** a bundled name in `dependencies` is refused with a located error, as `02-packaging` states for std |
| Tests | `libs/std` is a `test-libs` cell | `libs/routing` is a cell by discovery; its `targets` limit it to erlang and commonJS |
| Format | `libs/std` in `format-check.sh`'s `TREES` (red, named) | `libs/routing` joins `TREES` green on the day it lands |
| The lib-agnostic gate | `std` is the allowed exception | compiler-core spells no bundled package but `std`; `routing` appears only in `build.zig`'s list |

The library itself is the matcher of rakun's `file_router.bp`, cut at the line decision 114 drew
(the UI records are jhonstart's) and freed of its three rakun imports, plus the three codecs rakun
fronts 60, 61 and 65 specify, plus the navigation vocabulary front 63 specifies and the `:param`
grammar rakun-web runs (decision 116). Its module tree:

```
libs/routing/
├── botopink.json        "name": "routing", "target": "erlang", "targets": ["erlang", "commonJS"],
│                        "src": "src/", "entry": "root.bp", "files": [the nine modules]
├── AGENTS.md
├── src/root.bp          pub mod segment; pub mod table; pub mod match;
│                        pub mod route_kinds; pub mod slot_states; pub mod url_rules;
│                        pub mod navigation; pub mod pattern;
├── src/segment.bp       SegmentKind, Segment, parseSegment, parsePath, patternOf, slotOf, pathProblem
├── src/table.bp         RouteEntry, parseTable, writeTable, kindLabel
├── src/match.bp         RouteMatch, matchPath, layoutChain, paramOf, splitPath
├── src/route_kinds.bp   RouteKind, parseKinds, writeKinds, routeKindOf           (the `k` blob)
├── src/slot_states.bp   SlotState, parseSlotStates, writeSlotStates              (the `z` blob)
├── src/url_rules.bp     PathRules, canonicalize, clientHref,
│                        RedirectRule, parseRedirectTable, writeRedirectTable
├── src/navigation.bp    NavKind, NavOutcome, signalReason, signalFromReason, isSignalReason,
│                        signalPrefixes, signalToWire, signalFromWire
├── src/pattern.bp       PatternSegment, parsePattern, matchPattern, patternProblem   (`:param`)
└── test/                segment_test.bp · table_test.bp · match_test.bp ·
                         route_kinds_test.bp · slot_states_test.bp · url_rules_test.bp ·
                         navigation_test.bp · pattern_test.bp
```

It imports `std` and nothing else. Consumers write `import {match.matchPath, table.parseTable} from
"routing";` (decision 107's grammar).

## Steps

### Step 1 — Scaffold `libs/routing`

`botopink.json`, `AGENTS.md`, `src/root.bp` declaring the eight modules, and the `routing` row of
`libs/AGENTS.md` (*Provides*: the route matcher and the routing wires; *Embedded in compiler?*: yes,
from Step 2).

**Acceptance:**
- [x] `libs/routing/botopink.json` reads `"name": "routing"`, `"targets": ["erlang", "commonJS"]`
      with erlang first, and lists every `src/*.bp` in `files`
- [x] `grep -rn "External\|declare fn\|rakun\|jhonstart\|onze\|emilia" libs/routing/src` is empty —
      no host cell, no library name; no `*.erl` or `*.mjs` file under `libs/routing/` (decision 117
      rule 8 — a piece that cannot be written in `.bp` stops the front and goes to
      `decisions-pending.md`)
- [x] `zig build test-libs -- --lib routing` lists the two cells `routing · erlang` and
      `routing · commonJS` and no other target — measured in the full `zig build test-libs`: `routing · commonJS: pass`, `routing · erlang: pass`, no other routing cell
- [x] `libs/AGENTS.md`'s tree and packages table name `routing/`

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
- [x] a scratch project with **no** `dependencies` builds `import {match.matchPath, table.parseTable}
      from "routing";` on `--target erlang` and `--target commonJS`, and running it matches
      `/blog/x` against `P|/blog/[slug]` — the same result on both — both print `/blog/[slug] slug=x` (`$HOME/.cache/bp-01std/bundle-probe`)
- [x] the erlang output names the module `routing@match` and the record `routing@match@@RouteMatch`;
      the commonJS output requires `./routing/match.js`
- [x] a manifest with `"dependencies": { "routing": … }` is refused with a located error naming the
      key; `from "routing"` from inside the meta workspace resolves the embedded copy, never the
      directory the disk loader would find — `dependency "routing" is bundled with the compiler …` at `botopink.json:2:21`; the CLI (`libs.appendBundled`) and the LSP (`ProjectGraph.appendBundled`) load only the embedded copy
- [x] `grep -rn '"routing' modules/compiler-core/src` is empty; the lib-agnostic gate is unchanged
- [x] the compiler's `snapshots/codegen/**` are byte-identical — the std path is unchanged — `zig build test` green, no `.snap.md.new`
- [ ] `codegen/tests/std_package.zig`'s pattern gains a bundled-package test (two packages in the
      registry, an import from each, both atoms) — **open:** the bundling lives in the CLI and the LSP, not in compiler-core's codegen (a non-std bundled package is ordinary modules `<pkg>/<stem>` to the codegens), so its tests are `compiler-cli/src/cli/libs.zig` ("a bundled package a module imports is loaded from the compiler, first, as <pkg>/<stem>", "a bundled name listed in `dependencies` is refused") and `language-server/src/project_graph.zig` ("an import of a bundled package loads its embedded modules"); the two-atom assertion is the scratch run above, not a compiler-suite test
- [x] `modules/compiler-core/AGENTS.md`, `modules/compiler-cli/AGENTS.md` and `libs/AGENTS.md`
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
- [x] every acceptance line of rakun front 22 Steps 1, 3 and 4 is a test here, green on erlang and on
      commonJS with the same literals — plus `parsePath` halting on `_drafts` and on `|` through `asserts.throwsWith`
- [x] `parseTable(writeTable(xs))` equals `xs` field by field for one entry of each of the eight kinds
- [x] the 26 moved tests keep their assertions; `diff` of each function body against
      `file_router.bp` shows only the three changes above — a whitespace-insensitive diff shows the three changes plus the refusal prefix `rakun routing:` → `routing:` and the private-folder refusal's em dash → ` - ` (on erlang `throwsWith` cannot find a needle in non-ASCII text)

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

### Step 7 — The navigation vocabulary: `navigation.bp`

Rakun front 63's Steps 1, 6 and 7, the part more than one package reads (decision 116 rule 1): the
outcome record, the four raised reasons with the neutral prefix `nav:`, and the `n` wire form. The
throw, the capture, the redirect checks and the response composition stay in rakun front 63.

```bp
pub type NavKind { None, NotFound, Redirect }
pub type NavOutcome(kind: NavKind, location: string, status: i32)

pub fn signalReason(out: NavOutcome) -> string
pub fn signalFromReason(reason: string) -> NavOutcome
pub fn isSignalReason(reason: string) -> bool
pub fn signalPrefixes() -> string[]
pub fn signalToWire(out: NavOutcome) -> string
pub fn signalFromWire(wire: string) -> NavOutcome
```

| `NavOutcome` | `signalReason` | `signalToWire` |
|---|---|---|
| `None` | — (not a signal) | `""` |
| `NotFound`, 404 | `nav:not-found` | `N` |
| `Redirect`, 307, `/login` | `nav:redirect:/login` | `R\|307\|/login` |
| `Redirect`, 308, `/new` | `nav:permanent-redirect:/new` | `R\|308\|/new` |
| `Redirect`, 303, `/done` | `nav:see-other:/done` | `R\|303\|/done` |

**Acceptance:** front 63 Step 6's and Step 7's lines, from `test/navigation_test.bp` on both targets,
with the `nav:` spellings —
- [x] `signalReason` answers each of the four reasons as a literal; `signalFromReason(signalReason(o))`
      equals `o` field by field, and `signalReason(signalFromReason(r)) == r` for each literal,
      including a location containing `:` and `/`
- [x] `signalFromWire(signalToWire(o))` equals `o` for every row; `signalToWire` of `None` is `""`;
      `signalFromWire("garbage")` is `None`; `signalFromWire("R|307|/a|b")` has location `/a|b`
- [x] for each row, `signalToWire(signalFromReason(reason))` equals the table's wire literal — the
      test that ties the two artefacts together
- [x] `signalPrefixes()` is exactly `["nav:not-found", "nav:redirect:", "nav:permanent-redirect:",
      "nav:see-other:"]`; `isSignalReason("nav:")` and `isSignalReason("boom")` are false
- [x] `signalFromReason("nav:teleport:/x")` raises, naming the verb
- [x] `grep -rn "jhonstart:\|rakun:" libs/routing/src/navigation.bp` is empty

### Step 8 — The `:param` grammar: `pattern.bp`

rakun-web's two matchers, merged into one (decision 116 rule 9): a literal segment, `:param`, and a
trailing `:param*`; any other form — a glob, a character class, a group, `?`, `{` — is refused by
name with `patternProblem`, as `middleware.bp:62-90` refuses it today. A pattern and a path match
when every literal is equal and every `:param` captures one segment; `:param*` captures the rest,
including nothing.

```bp
pub type PatternSegment { Literal(text: string), Param(name: string), Rest(name: string) }
pub fn parsePattern(pattern: string) -> @Result<Array<PatternSegment>, string>
pub fn matchPattern(pattern: Array<PatternSegment>, path: string) -> ?Array<#(string, string)>
pub fn patternProblem(pattern: string, segment: string) -> string
```

**Acceptance:**
- [ ] every assertion of `modules/rakun-web/test/middleware_test.bp` on `matcherMatches` /
      `checkMatcher` and of the CORS preflight's `routeMatches` has a line here, green on both
      targets with the same literals — **open:** every line is here with the same literals except one: rakun-web's "an empty matcher matches every path" — in `pattern` the empty pattern matches only `/`, and "no pattern means every path" stays the consumer's rule (rakun front 07 keeps it at its call site)
- [x] `/api/:id` matches `/api/7` with `[#("id", "7")]` and not `/api/7/x`; `/files/:rest*` matches
      `/files` and `/files/a/b` (`rest` = `a/b`)
- [x] `parsePattern("/a/*.js")`, `"/a/[x]"`, `"/a/(x)"`, `"/a/x?"` and `"/a/{x}"` answer an `Error`
      whose text is `patternProblem`'s; `:param*` anywhere but last is an `Error`
- [x] `grep -rn "fn matcherMatches\|fn routeMatches\|fn checkMatcher" --include=*.bp repository/`
      is empty once rakun front 07 switches (Step 10) — measured empty: rakun-web's `middleware.bp` / `filter.bp` call `parsePattern` / `matchPattern` (`validateMatcher`, `matcherAdmits`, `routeAdmits`), rakun-web 104 / 0 on both rows before and after

### Step 9 — Both targets, in the gate

**Acceptance:**
- [x] `botopink test --target erlang` and `botopink test --target commonJS` from `libs/routing/` are
      green, and `zig build test-libs` reads `routing · erlang: pass` and `routing · commonJS: pass` — 66 passed / 0 failed on each; `routing · erlang: pass`, `routing · commonJS: pass`
- [x] every expected wire string in the tests is a literal, not the output of a second call — the
      only form that catches the two targets drifting
- [x] `libs/routing` is in `scripts/format-check.sh`'s `TREES`, and `botopink format --check` is green
      on it

### Step 10 — rakun and jhonstart import it

Not this front's files — each consumer switches in its own front, after Steps 3–8 land — but this
front is not done until both have:

| Consumer | Front | What it imports |
|---|---|---|
| rakun `file_router.bp` (registry, scan, dispatch) | 22 Step 7 | `segment`, `table`, `match` — and deletes `file_router.bp:49-479` |
| rakun static generation | 60 | `route_kinds` |
| rakun slots | 61 | `slot_states` |
| rakun-web URL rules | 65 | `url_rules` |
| jhonstart router | 26 | `table.parseTable`, `match.matchPath` — the table from the payload's `t` |
| jhonstart `Link` | 27 | `route_kinds.routeKindOf`, `slot_states.parseSlotStates`, `url_rules.clientHref` |
| rakun navigation (throw, capture, checks) | 63 | `navigation` — the outcome, the reasons, the wire; front 63 keeps only the server half |
| rakun actions (the envelope's `n`) | 24 | `navigation.signalToWire`, through `libs/actions` (decision 116) |
| rakun-web matchers | 07 | `pattern` — and deletes `middleware.bp`'s and `filter.bp`'s grammars |
| jhonstart router (an envelope's `n`) | 26 | `navigation.signalFromWire` |
| jhonstart render (a late signal) | 30 | `navigation.signalFromReason` |
| jhonstart boundaries, `notFound` / `redirect` | 31 | `navigation.signalReason`, `isSignalReason`, `signalPrefixes` |

**Acceptance:**
- [x] `grep -rn "fn matchPath\|fn parseTable\|fn parseKinds\|fn parseSlotStates\|fn canonicalize\|fn signalFromWire\|fn signalReason\|fn matchPattern"
      --include=*.bp repository/` finds only `repository/botopink-lang/libs/routing/src/` — measured: rakun's `file_router.bp` imports `segment` / `table` / `match` from "routing" and keeps the registry, markers and scan; the 26 tests left `file_router_test.bp`
- [x] `grep -rn '"jhonstart:' --include=*.bp repository/` is empty — no reason carries a framework's
      name — measured empty
- [x] no `botopink.json` under `repository/` lists `routing` in `dependencies` — measured; and the CLI now refuses one that does
- [x] `grep -rn "rakun-routing" repository/` is empty — measured empty

## Test plan

`libs/routing/test/*.bp`, one file per module, suite `routing:`, run by `botopink test --target
erlang` and `--target commonJS` from `libs/routing/`, and by `zig build test-libs` in the ecosystem
gate. Everything is deterministic — no clock, no filesystem, no network. The bundling itself
(Step 2) is tested in the compiler's own suite, beside `codegen/tests/std_package.zig`.

The tests assert: segment classification for all seven kinds and the private-folder and `|`
refusals; the wire round trip on all eight record kinds with no trailing `|`; match precedence,
capture, the optional catch-all, the layout chain and "a layout alone is not public"; the three
blob round trips and their tolerant defaults (`Dynamic`, `Empty`); `canonicalize`/`clientHref` as
inverses and the single decode; the four `nav:` reasons and the `n` wire form round-tripping both
ways and agreeing case for case; the `:param` grammar's matches, captures and refusals.

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in the compiler worktree (Step 2) — **open:** green on a warm cache on every commit; not re-run from a cold runtime cache
- [x] `zig build test-libs` green — `routing` on both targets; std, rakun and jhonstart unchanged
      by this front's commits — `zig build test-libs` 58 passed / 0 failed (19 restricted as pinned), emilia and erika included, run from an rsync copy of the worktree; std unchanged, jhonstart unchanged, rakun changed only by the moved tests (388 → 369 / 0 commonJS, 386 → 367 / 2 erlang with the pinned reds; rakun-web 104 / 0 both)
- [x] the compiler's `snapshots/codegen/**` byte-identical — `zig build test` green, no `.snap.md.new`; `tests/language/run.sh --target all` 799 passed / 28 expected / 0 failed
- [x] `AGENTS.md` of every directory touched (`libs/`, `libs/routing/`, `modules/compiler-core`,
      `modules/compiler-cli/src/cli/`, `modules/language-server`), updated in the same commit — also `modules/language-server/src/AGENTS.md` and the compiler root `AGENTS.md` tree
- [x] `docs.md` names the bundled packages beside § std — § Imports, *Bundled packages*

## Blast radius

- **Compiler:** the std registry becomes the bundled registry; every std output is unchanged, and a
  program that does not import `routing` is byte-identical. A project that happened to declare a
  disk library named `routing` is refused — none exists under `repository/`.
- **rakun:** `file_router.bp` loses some 430 lines to an import (front 22 Step 7); the 26 moved tests leave
  `file_router_test.bp`.
- **jhonstart:** gains its first import of a package other than std (front 26); nothing of rakun's.
  The `nav:` reasons replace the `jhonstart:` ones in fronts 30 and 31 (decision 116).
- **rakun-web:** the two `:param` matchers become calls into `pattern` (front 07).
- **onze:** the client entry stops building `match` (front 68).

## Notes

- **Why bundled, not a sibling repository.** The maintainer's words place it in
  `repository/botopink-lang/libs` (decision 115). A library in that directory that were *not*
  embedded would resolve only inside the meta workspace (`libs.zig:63-78`) — an installed compiler
  would not find it — so bundling is what makes `from "routing"` mean the same thing everywhere.
- **Why one front owns all eight modules.** Fronts 60, 61, 63 and 65 specify their formats and own
  their server halves, and rakun-web's `:param` matchers become callers (front 07); the files that implement the formats sit in one package with one owner, so its
  `root.bp`, manifest and test layout have no appenders.
- **Not in this front.** Removing rakun's copy (front 22), the router's switch (front 26), the late
  signal markup that uses `matchPath` to check a redirect target in jhonstart's render (front 30,
  decision 115 rule 2), the throw and capture that raise and catch the `nav:` reasons (rakun 63,
  jhonstart 31). The action protocol and validation are bundled libraries of their own
  (`05-actions-lib`, `06-validation-lib`), not modules here: each is read by a different pair of
  consumers and has its own reason to change.
