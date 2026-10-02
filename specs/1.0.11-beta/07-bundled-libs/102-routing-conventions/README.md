# Front 102 — `routing` gains `conventions` and the segment helpers

**Priority:** high — the segment grammar is walked by hand in seven places outside `routing`, and
two of them disagree on what an app file is.
**Depends on:** `00-gate` green · `02-std-and-packaging/97-std-dedupe` (std `parseInt` — the
`[[...x]]` filler parses nothing, but the callers it edits do) · confirmation of 49-d ("onze imports
nothing from routing" — this front reverses it) · `07-i` (names).
**Owns:** `repository/botopink-lang/libs/routing/src/conventions.bp` (new), `libs/routing/src/segment.bp`
(new helpers), `libs/routing/test/**`, `libs/routing/AGENTS.md`, `libs/routing/botopink.json`
(`files`) · consumers, one commit each: `repository/rakun/modules/rakun-app/src/{file_router,static_gen}.bp`,
`repository/rakun/modules/rakun-hateoas/src/hal.bp`, `repository/onze/modules/onze/src/types.bp`,
`repository/onze/modules/onze-cli/src/scan.bp`, `repository/onze/modules/onze-bundler/src/chunk.bp`,
`repository/jhonstart/modules/jhonstart/src/routes.bp`.
**Does not touch:** `build.zig`, `libs/AGENTS.md`, `scripts/format-check.sh` (104's lines; `routing`
is already registered) · any other file of the members above (their library fronts') ·
`onze-bundler/src/scan.bp` (`stagedSegment` is onze-specific and stays).

---

## Problem

The route-segment grammar (`[x]`, `[...x]`, `[[...x]]`, `(group)`, `@slot`, `(.)`/`(..)` interceptors)
has one owner, `routing`, and seven readers that re-derive it:

| Site | What it re-derives |
|---|---|
| rakun-app `file_router.bp:193-225` (`conventionFiles`, `conventionKind`) and `:379-414` (`conflictProblems`) | the eight convention file kinds; the tree's two conflicts |
| onze `types.bp:101-127` (`AppFile`, `appFileKinds`, `classifyAppFile`) | the same eight kinds, a second time |
| onze-bundler `chunk.bp:31-34` (`patternOfSegment`) | group/slot stripping — `segment.patternOf(parsePath(..))` |
| onze-cli `scan.bp:58-61` (a different `patternOfSegment`) | the same, a third way |
| rakun-app `static_gen.bp:124-211` (`segmentName`, `bound`, `expandRow`, `expandParams`) | filling `[x]` / `[[...x]]` from `generateStaticParams` rows |
| rakun-hateoas `hal.bp:140-142` (`bracketToColon`) | `[x]` → `:x` |
| jhonstart `routes.bp:233-251` (`#[page]`) | the param names of a segment |

Two of those (rakun-app and onze) are the two halves of one app tree, and they classify the same
file independently.

## Current state

`libs/routing` has 9 modules and 95 tests, green on erlang and commonJS (`botopink test --target
<t>` in `libs/routing`), `botopink format --check src test` clean; it declares no host cell and is
imported by rakun-app, jhonstart and onze-cli already. Steps 1 and 2 are in the package; the seven
sites above are still on disk at the lines given (the libraries' landed tips) — step 3 deletes them.

The surface, as it is in the package (the names differ from this front's first draft wherever a
`pub` name of std, another bundled package or a framework already had it — `07-i`; an
`import {x} from "<package>"` is refused as ambiguous when two packages of a program export `x`):

| In the package | Replaces | Why this name |
|---|---|---|
| `conventions.fileKinds() -> Array<string>` | onze `appFileKinds`, rakun-app `conventionFiles` | free |
| `conventions.kindOf(file) -> ?string` | rakun-app `conventionKind` (which answers the LETTER) | free |
| `conventions.classify(appDir, path) -> ?ConventionFile` | onze `classifyAppFile` | free |
| `conventions.ConventionFile(authoredPath, segment, kind)` | onze `AppFile` (same three fields) | onze exports `AppFile` |
| `conventions.conventionConflicts(entries: Array<ConventionFile>) -> Array<string>` | rakun-app `conflictProblems(entries: ScanEntry[])` | rakun-app exports `conflictProblems` |
| `segment.paramNamesOf(seg) -> Array<string>` | jhonstart `#[page]`'s hand walk | `validation/table` exports `paramNames` |
| `segment.fillPattern(pattern, bindings: Array<#(string, string)>) -> @Result<string, string>` | rakun-app `expandRow` | jhonstart `router` exports `fill` |
| `segment.toColonPattern(pattern) -> string` | rakun-hateoas `bracketToColon` | free |

What was measured against the code being replaced, by running both over the same inputs on erlang
and commonJS (verbatim copies of the consumer functions beside the package, outside the tree):

| Pair | Inputs | Result |
|---|---|---|
| `classify` · onze `classifyAppFile` | 53 paths × 5 app directories (`app`, `src/app`, `""`, `app/`, `src`), every file of `onze/examples/blog/src` among them | identical |
| `fileKinds` · onze `appFileKinds` · rakun-app `conventionFiles` | — | the same order as onze's; the same eight names as rakun-app's (whose order is the wire's `L T P D R S E N`) |
| `kindOf` · `table.kindLabel(conventionKind(file))` | 16 names | identical |
| `conventionConflicts` · rakun-app `conflictProblems` | 7 trees | the same refusals in the same order; the text is `routing: …` and ASCII (` - ` where rakun wrote a dash) |
| `fillPattern` · rakun-app `expandRow` | 12 filling rows, 5 refused rows | identical paths; each refusal carries the phrase rakun-app's tests assert (``binds no `slug` ``, ``binds `extra` ``, ``holds a `/` ``) |
| `toColonPattern` · rakun-hateoas `bracketToColon` | 20 patterns | identical |
| `paramNamesOf` · jhonstart `#[page]` | 9 segments | identical |

Where the package deliberately differs from the copy it replaces:

- `fillPattern` accepts an optional catch-all with **no** binding (rakun-app's `expandRow` refuses a
  row that does not bind it and accepts one that binds it to `""`), and refuses a name bound twice
  (`expandRow` takes the first).
- `paramNamesOf` reads through `parseSegment`: `[a.b]` captures `a.b` (the hand walk strips the dot)
  and an unclosed `[x` captures nothing (the hand walk captures `x`).
- `classify` compares the app directory part by part; over ASCII paths that is `startsWith(appDir +
  "/")` exactly, and it does not depend on `String.slice`'s unit.

## Mechanism

`routing` already parses a path into segments (`parsePath`, `segment.patternOf`); the sites above
were written before those existed or before `routing` was bundled, and never went back. A decorator
body may call a bodied package function (only a *host* function is refused — `language-gaps.md`
toolchain row 19), so jhonstart's `#[page]` can call `segment.paramNamesOf` directly.

## Steps

### Step 1 — `conventions.bp`

`fileKinds() -> Array<string>` (the eight kinds, one order), `kindOf(file) -> ?string`,
`classify(appDir, path) -> ?ConventionFile` (pure: takes the path, never reads the disk),
`conventionConflicts(entries) -> Array<string>` (moved in substance from rakun-app's
`conflictProblems`, over the classified files handed in).

**Acceptance:**
- [x] `libs/routing/test/conventions_test.bp`: every kind classifies, a stray file answers `null`,
      page-beside-route in one segment is a named conflict; green on erlang and commonJS (17 tests)
- [x] `classify` takes the path it is handed; `grep -rn "fs\." libs/routing/src` is empty

### Step 2 — segment helpers

`segment.paramNamesOf(seg) -> Array<string>`, `segment.fillPattern(pattern, bindings) -> @Result<string, string>`
(a missing required binding is the `Error`; an optional catch-all left empty is not),
`segment.toColonPattern(pattern) -> string`.

**Acceptance:**
- [x] `fillPattern` refuses a missing `[x]` and accepts a missing `[[...x]]`; tests on both rows
- [x] `toColonPattern("[id]/[...rest]")` is `":id/:...rest"` — what `hal.bp:140` produces today
      (only the outer bracket pair is replaced), byte-identical to it, asserted

### Step 3 — consumers, one commit per member

Each site deletes its copy and imports the package; the member's tests must not change their
assertions. Not started: it waits on the libraries' landed tips.

| Member | Deletes | Imports from `routing` | Needs attention |
|---|---|---|---|
| rakun-app `file_router.bp` | `conventionFiles`, `conventionKind`, `conflictProblems`, `hasConvention`, `rootGroupOf` | `conventions.fileKinds`, `conventions.kindOf`, `conventions.ConventionFile`, `conventions.conventionConflicts` | `scanTable` needs the wire LETTER of a kind and the package has only the letter → word direction (`table.kindLabel`) — question 2 below; `conventionsIn` iterates `fileKinds()` in the package's order, so a segment's records come out `P L T D S E N R` instead of `L T P D R S E N` (no test asserts the order); `file_router_scan_test.bp:152-160` asserts `conventionKind` itself; the refusals lose the `rakun ` prefix and the dash (the scan tests assert `both`, `page.bp`, `route.bp`, `/about`, `(marketing)`, `(shop)` — all kept) |
| rakun-app `static_gen.bp` | `segmentName`, `bound`, `expandRow`'s body (`expandParams` keeps the duplicate-path refusal over `fillPattern`) | `segment.fillPattern` | an `Error` becomes the halt — its text carries the three phrases `static_gen_test.bp:245-256` asserts; a row that does not bind an optional catch-all starts to fill |
| rakun-hateoas `hal.bp` | `bracketToColon` | `segment.toColonPattern` | none — identical over the 20 patterns measured |
| onze `types.bp` | `appFileKinds`, `classifyAppFile`; `AppFile` if `ConventionFile` replaces it | `conventions.fileKinds`, `conventions.classify`, `conventions.ConventionFile` | `AppFile` is imported by onze-cli (`scan.bp:16`, `generate.bp:28`) and constructed at `scan.bp:72`; `classifyAppFile` is imported by onze-cli and onze-bundler (`chunk.bp:20`, `graph.bp:13`); `describeAppFiles` (the `types` snapshot, `onze-test`'s `assertAppFiles`) stays in onze over `classify`; `types_test.bp:14-23` asserts `appFileKinds` / `classifyAppFile` by name |
| onze-cli `scan.bp`, onze-bundler `chunk.bp` | both `patternOfSegment` | `segment.pathProblem`, `segment.parsePath`, `segment.patternOf` (already in the package) | the two copies disagree on a segment `pathProblem` refuses: onze-cli answers `""`, onze-bundler strips by hand |
| jhonstart `routes.bp` | the hand walk of `#[page]` | `segment.paramNamesOf`, and `segment.parseSegment` / `kindName` for "is it a list" | `[a.b]` and an unclosed `[x` change (above) |

**Acceptance:**
- [ ] rakun-app: `conventionFiles`/`conventionKind`/`expandParams` gone; `rakun-app` tests green
- [ ] onze: `appFileKinds`/`classifyAppFile`/`_folder` gone; onze-cli and onze-bundler
      `patternOfSegment` gone; onze tests green on both rows
- [ ] rakun-hateoas `bracketToColon` gone; jhonstart `#[page]` calls `segment.paramNamesOf`
- [ ] the app tree of `onze/examples/blog` classifies identically before and after (diff of the
      staged tree)

## Gate

- [ ] `zig build test` cold, green; `zig build test-libs` green with no new ledger line
- [ ] `libs/routing/AGENTS.md` (done for steps 1–2) and each touched member's `AGENTS.md` updated in
      the same commit
- [ ] Commit on `front/102-routing-conventions`; landing is the maintainer's step

## Blast radius

Six members change imports; no snapshot directory is shared. 49-d is reversed (onze now imports
`routing` in `types.bp`); `06-onze`'s modules.md dependency column changes.

## Notes

`libs/AGENTS.md`'s packages row for `routing` does not name the conventions yet: that table is
`104-http`'s line to edit.

Two questions the package half met and did not answer — both wait on the maintainer before step 3:

1. **The one order of `fileKinds()`.** onze's is `page, layout, template, default, loading, error,
   not-found, route` and `onze/test/types_test.bp:14` asserts it; rakun-app's is the wire's
   `L T P D R S E N` and nothing asserts it. The package ships onze's (the only order a test pins).
   The alternative is the wire's order, with onze's assertion rewritten.
2. **The wire letter of a kind.** rakun-app's `scanTable` writes `L`/`T`/`P`… from a convention
   file; the package has `table.kindLabel` (letter → word) and no inverse. Either `conventions`
   gains `kindLetter(kind)`, or rakun-app keeps a private eight-arm map — a re-derivation this
   front exists to delete.

`onze-bundler/src/scan.bp:47-58` (`stagedSegment`) is onze-specific staging and stays. The disk
walk (`walkSegments`, over `fs`) stays in rakun-app: a bundled package declares no host cell.
