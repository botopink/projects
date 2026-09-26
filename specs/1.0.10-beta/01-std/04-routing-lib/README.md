# Front 04 (std track) — the bundled `routing` library

The directory number is this front's index inside `01-std`, beside `01`/`02`/`03`; it is not a
milestone front number — rakun's front 04 is `03-rakun/04-rakun-erlang-runtime`. Everywhere else it
is named `01-std/04-routing-lib`.

**Track:** A std
**Priority:** critical — the route matcher is the one piece of code the server and the browser must
run identically (`contracts.md § 1`), and since decision 115 it has no other home
**Target:** both — erlang and commonJS, every module. The library is pure: no HTTP, no state, no
host cell
**Owns:** `repository/botopink-lang/libs/routing/**` · the `routing` row of
`repository/botopink-lang/libs/AGENTS.md` · **by named carve-out from `00`** (recorded in `fronts.md`
§ *Conflict rules*): the bundled-package list in `build.zig`, the bundled-package loading in
`modules/compiler-cli/src/cli/{libs,resolver}.zig` and `modules/language-server/src/project_graph.zig`,
their tests, and `scripts/format-check.sh`'s `TREES`
**Does not touch:** `libs/std/**`; `repository/rakun/**` — rakun fronts 22, 60, 61, 63 and 65 import
from it; `repository/jhonstart/**` — front 26 imports it in the router, front 27 in `Link`;
`repository/onze/**`
**Reference:** [decision 115](../../decisions-taken.md#115-routing-is-a-bundled-library-a-signal-after-the-first-chunk-is-markup-jhonstart-gains-redirect-rakuns-keys-are-rakun)
(the library, its contents, `from "routing"` resolving like `from "std"`) ·
[decision 116](../../decisions-taken.md#116-code-two-libraries-both-run-is-neutral-routing-gains-navigation-and-param-actions-and-validation-are-bundled-libraries-std-writes-json)
rules 1 and 9 (the `navigation` and `pattern` modules; the bundled list gains `actions` and
`validation`) · [decision 117](../../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only) rule 8 (a bundled library ships `.bp` files
only) · decision 109 (module atoms) · decision 113 (jhonstart and rakun never import each other) ·
`contracts.md § 1` (the route table) · rakun fronts [22](../../03-rakun/22-rakun-file-routing/README.md) Steps 1, 3, 4,
[60](../../03-rakun/60-rakun-static-generation/README.md) Step 6,
[61](../../03-rakun/61-rakun-parallel-intercepting-routes/README.md) Step 5,
[65](../../03-rakun/65-rakun-url-rules/README.md) Steps 2–3,
[63](../../03-rakun/63-rakun-navigation-signals/README.md) Steps 6–7 (the formats this library
implements) · rakun front [07](../../03-rakun/07-rakun-middleware/README.md)'s matcher (the `:param`
grammar)

---

## Problem

The server and the browser have to agree on which route a URL is, which routes are static, which
parallel slots rendered, what a URL looks like under `basePath`, and how a navigation signal reads.
Each is a small pure function over a line-oriented wire, and each must be **one** implementation
compiled twice, or the two sides drift (`contracts.md § 1`). They belong to neither framework:
rakun may not be imported by jhonstart, and jhonstart's router is where the browser half runs.
Decision 115 gives them a library neutral like std, bundled with the compiler, that rakun and
jhonstart both import by name.

## The library

```
libs/routing/
├── botopink.json        "name": "routing", "target": "erlang", "targets": ["erlang", "commonJS"],
│                        "src": "src/", "entry": "root.bp", "files": [the modules]
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

It imports `std` and nothing else, declares no host cell, and ships no `*.erl` / `*.mjs` file.
Consumers write `import {match.matchPath, table.parseTable} from "routing";` (decision 107's grammar).

**Bundling.** `build.zig`'s `bundled_packages` (`std`, `routing`, `actions`, `validation`) is the one
list of bundled names; it generates `comptime.bundled_packages`, one row per module of every bundled
package, keyed `<package>/<module>`. The CLI (`libs.loadDependencies` → `appendBundled`) and the LSP
(`ProjectGraph.appendBundled`) load the embedded modules of every bundled package a module imports,
first and in dependency order, as `<pkg>/<stem>`, so the codegens see ordinary modules
(`routing@match`, `routing@match@@RouteMatch`, `./routing/match.js`) and compiler-core names no
package but `std`. `std` keeps its own embedding and its std-only rules (root purity, no dispatch
inside std, the BIF table). `checkImportSources` exempts every bundled name; a bundled name listed in
`dependencies` is a located refusal (`dependency "routing" is bundled with the compiler …`), and
`from "routing"` inside the meta workspace resolves the embedded copy, never the directory on disk.
`libs/routing` is a `test-libs` cell by discovery, limited by its `targets` to erlang and commonJS,
and is in `scripts/format-check.sh`'s `TREES`.

## Steps

### Step 1 — Scaffold `libs/routing`

- [x] `libs/routing/botopink.json` reads `"name": "routing"`, `"targets": ["erlang", "commonJS"]`
      with erlang first, and lists every `src/*.bp` in `files`
- [x] `grep -rn "External\|declare fn\|rakun\|jhonstart\|onze\|emilia" libs/routing/src` is empty —
      no host cell, no library name; no `*.erl` or `*.mjs` file under `libs/routing/` (decision 117
      rule 8 — a piece that cannot be written in `.bp` stops the front and goes to
      `decisions-pending.md`)
- [x] `zig build test-libs` lists the two cells `routing · erlang` and `routing · commonJS` and no
      other routing cell
- [x] `libs/AGENTS.md`'s tree and packages table name `routing/`

### Step 2 — Bundle it with the compiler

- [x] a scratch project with **no** `dependencies` builds `import {match.matchPath, table.parseTable}
      from "routing";` on `--target erlang` and `--target commonJS`, and running it matches
      `/blog/x` against `P|/blog/[slug]` — both print `/blog/[slug] slug=x`
- [x] the erlang output names the module `routing@match` and the record `routing@match@@RouteMatch`;
      the commonJS output requires `./routing/match.js`
- [x] a manifest with `"dependencies": { "routing": … }` is refused with a located error naming the
      key; `from "routing"` from inside the meta workspace resolves the embedded copy, never the
      directory the disk loader would find
- [x] `grep -rn '"routing' modules/compiler-core/src` is empty; the lib-agnostic gate is unchanged
- [x] the compiler's `snapshots/codegen/**` are byte-identical — the std path is unchanged
- [ ] `codegen/tests/std_package.zig`'s pattern gains a bundled-package test (two packages in the
      registry, an import from each, both atoms) — **open:** the bundling lives in the CLI and the LSP, not in compiler-core's codegen, so its tests are `compiler-cli/src/cli/libs.zig` ("a bundled package a module imports is loaded from the compiler, first, as <pkg>/<stem>", "a bundled name listed in `dependencies` is refused") and `language-server/src/project_graph.zig` ("an import of a bundled package loads its embedded modules"); the two-atom assertion is the scratch run above, not a compiler-suite test
- [x] `modules/compiler-core/AGENTS.md`, `modules/compiler-cli/AGENTS.md` and `libs/AGENTS.md`
      describe the bundled-package list in the same commit

### Step 3 — The matcher: `segment.bp`, `table.bp`, `match.bp`

rakun's `file_router.bp` matcher, moved: the grammar, the wire and the matcher, with `charOf`/`sub`
private to `segment.bp`, no rakun import, `Dict.empty()` as std spells it, and the refusal prefix
`routing:`. `PageContext`, `LayoutProps`, `contextOf` and `emptyParams` are jhonstart front 30's
(decision 114); the registry and context tests stay rakun's and jhonstart's.

- [x] every acceptance line of rakun front 22 Steps 1, 3 and 4 is a test here, green on erlang and on
      commonJS with the same literals — plus `parsePath` halting on `_drafts` and on `|` through `asserts.throwsWith`
- [x] `parseTable(writeTable(xs))` equals `xs` field by field for one entry of each of the eight kinds
- [x] the 26 moved tests keep their assertions; each function body differs from rakun's only by the
      moves above, the refusal prefix `rakun routing:` → `routing:`, and the private-folder refusal's
      em dash → ` - ` (on erlang `throwsWith` cannot find a needle in non-ASCII text)

### Step 4 — The `k` blob: `route_kinds.bp`

Rakun front 60 Step 6's codec: `pattern|K` lines, `K` `S` or `D`.

```bp
pub type RouteKind { Static, Dynamic }
pub fn parseKinds(wire: string) -> Array<#(string, RouteKind)>
pub fn writeKinds(kinds: Array<#(string, RouteKind)>) -> string
pub fn routeKindOf(wire: string, pattern: string) -> RouteKind
```

**Acceptance:** front 60 Step 6's five lines, run from `test/route_kinds_test.bp` on both targets —
round trip element by element, the recorded kind, `Dynamic` for `""` and for `"garbage"`.

### Step 5 — The `z` blob: `slot_states.bp`

Rakun front 61 Step 5's codec: `slot|pattern|state` lines, `state` one of `M` `D` `U` `E`. rakun's
`SlotResolution` stays in rakun; front 61's server half turns its resolutions into the triples this
codec writes.

```bp
pub type SlotState { Matched, Defaulted, Unchanged, Empty }
pub fn writeSlotStates(states: Array<#(string, string, SlotState)>) -> string
pub fn parseSlotStates(wire: string) -> Array<#(string, string, SlotState)>
```

**Acceptance:** front 61 Step 5's lines, from `test/slot_states_test.bp` on both targets — the
field-by-field round trip, a `|` in a slot name refused, an unknown letter read as `Empty`.

### Step 6 — The URL rules: `url_rules.bp`

Rakun front 65's boundary half. The rule engine, `UrlRules`, `pathRulesOf` and `redirectFor` stay in
`rakun-web`. Percent-decoding is std's `encoding.percentDecode`, applied once.

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
name with `patternProblem`. A pattern and a path match when every literal is equal and every `:param`
captures one segment; `:param*` captures the rest, including nothing.

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
      is empty — rakun-web's `middleware.bp` / `filter.bp` call `parsePattern` / `matchPattern`
      (`validateMatcher`, `matcherAdmits`, `routeAdmits`)

### Step 9 — Both targets, in the gate

- [x] `botopink test --target erlang` and `botopink test --target commonJS` from `libs/routing/` are
      green, and `zig build test-libs` reads `routing · erlang: pass` and `routing · commonJS: pass` — 66 / 0 on each
- [x] every expected wire string in the tests is a literal, not the output of a second call — the
      only form that catches the two targets drifting
- [x] `libs/routing` is in `scripts/format-check.sh`'s `TREES`, and `botopink format --check` is green
      on it

### Step 10 — rakun and jhonstart import it

Each consumer switches in its own front; this front is not done until both have:

| Consumer | Front | What it imports |
|---|---|---|
| rakun `file_router.bp` (registry, scan, dispatch) | 22 Step 7 | `segment`, `table`, `match` |
| rakun static generation | 60 | `route_kinds` |
| rakun slots | 61 | `slot_states` |
| rakun-web URL rules | 65 | `url_rules` |
| jhonstart router | 26 | `table.parseTable`, `match.matchPath` — the table from the payload's `t` |
| jhonstart `Link` | 27 | `route_kinds.routeKindOf`, `slot_states.parseSlotStates`, `url_rules.clientHref` |
| rakun navigation (throw, capture, checks) | 63 | `navigation` — the outcome, the reasons, the wire; front 63 keeps only the server half |
| rakun actions (the envelope's `n`) | 24 | `navigation.signalToWire`, through `libs/actions` (decision 116) |
| rakun-web matchers | 07 | `pattern` |
| jhonstart router (an envelope's `n`) | 26 | `navigation.signalFromWire` |
| jhonstart render (a late signal) | 30 | `navigation.signalFromReason` |
| jhonstart boundaries, `notFound` / `redirect` | 31 | `navigation.signalReason`, `isSignalReason`, `signalPrefixes` |

**Acceptance:**
- [x] `grep -rn "fn matchPath\|fn parseTable\|fn parseKinds\|fn parseSlotStates\|fn canonicalize\|fn signalFromWire\|fn signalReason\|fn matchPattern"
      --include=*.bp repository/` finds only `repository/botopink-lang/libs/routing/src/` — rakun's `file_router.bp` imports `segment` / `table` / `match` from "routing" and keeps the registry, markers and scan
- [x] `grep -rn '"jhonstart:' --include=*.bp repository/` is empty — no reason carries a framework's
      name
- [x] no `botopink.json` under `repository/` lists `routing` in `dependencies`, and the CLI refuses
      one that does
- [x] `grep -rn "rakun-routing" repository/` is empty

## Test plan

`libs/routing/test/*.bp`, one file per module, suite `routing:`, run by `botopink test --target
erlang` and `--target commonJS` from `libs/routing/`, and by `zig build test-libs`. Everything is
deterministic. The tests assert: segment classification for all seven kinds and the private-folder
and `|` refusals; the wire round trip on all eight record kinds with no trailing `|`; match
precedence, capture, the optional catch-all, the layout chain and "a layout alone is not public";
the three blob round trips and their tolerant defaults (`Dynamic`, `Empty`); `canonicalize` /
`clientHref` as inverses and the single decode; the four `nav:` reasons and the `n` wire form
round-tripping both ways and agreeing case for case; the `:param` grammar's matches, captures and
refusals.

## Gate

- [x] `zig build test` from a **cold** runtime cache, green, in the compiler worktree (Step 2)
- [x] `zig build test-libs` green — `routing` on both targets; std, rakun and jhonstart unchanged by
      this front's commits (rakun changed only by the moved tests)
- [x] the compiler's `snapshots/codegen/**` byte-identical
- [x] `AGENTS.md` of every directory touched (`libs/`, `libs/routing/`, `modules/compiler-core`,
      `modules/compiler-cli/src/cli/`, `modules/language-server`), updated in the same commit
- [x] `docs.md` names the bundled packages beside § std — § Imports, *Bundled packages*

## Notes

- **Why bundled, not a sibling repository.** The maintainer's words place it in
  `repository/botopink-lang/libs` (decision 115). A library in that directory that were *not*
  embedded would resolve only inside the meta workspace — an installed compiler would not find it —
  so bundling is what makes `from "routing"` mean the same thing everywhere.
- **Why one front owns all eight modules.** Fronts 60, 61, 63 and 65 specify their formats and own
  their server halves, and rakun-web's `:param` matchers are callers (front 07); the files that
  implement the formats sit in one package with one owner, so its `root.bp`, manifest and test
  layout have no appenders.
- **Not in this front.** The router's switch (front 26), the late signal markup that uses
  `matchPath` to check a redirect target in jhonstart's render (front 30, decision 115 rule 2), the
  throw and capture that raise and catch the `nav:` reasons (rakun 63, jhonstart 31). The action
  protocol and validation are bundled libraries of their own (`05-actions-lib`, `06-validation-lib`):
  each is read by a different pair of consumers and has its own reason to change.
