# Front 102 — routing conventions: `routing` gains `conventions` and the segment helpers

**Priority:** high — the segment grammar is walked by hand in seven places outside `routing`, and two
of them disagree on what an app file is; 128 and the rakun group A wait on step 3 · **State:** not on
feat; steps 1–2 reported done on an unpushed branch `front/102-routing-conventions` — push it
**Depends on:** the branch pushed and landed (steps 1–2) · confirmation of 49-d as amended ("onze
imports nothing from routing" — this front reverses it) (step 3)
**Owns:** `repository/botopink-lang/libs/routing/src/conventions.bp` (new), `libs/routing/src/segment.bp`
(new helpers), `libs/routing/test/**`, `libs/routing/AGENTS.md`, `libs/routing/botopink.json`
(`files`) · consumers, one commit each: `repository/rakun/modules/rakun-app/src/{file_router,static_gen}.bp`,
`repository/rakun/modules/rakun-hateoas/src/hal.bp`, `repository/onze/modules/onze/src/types.bp`,
`repository/onze/modules/onze-cli/src/scan.bp`, `repository/onze/modules/onze-bundler/src/chunk.bp`,
`repository/jhonstart/modules/jhonstart/src/routes.bp`
**Does not touch:** `build.zig`, `libs/AGENTS.md`, `scripts/format-check.sh` (`routing` is already
registered) · any other file of the members above (their library fronts') ·
`onze-bundler/src/scan.bp` (`stagedSegment` is onze-specific staging and stays) · rakun-app's disk
walk (`walkSegments`, over `fs` — a bundled package declares no host cell)

## Goal

The route-segment grammar (`[x]`, `[...x]`, `[[...x]]`, `(group)`, `@slot`, `(.)`/`(..)`
interceptors) has one owner, `routing`, and its seven re-derivations are gone:

| Site (on feat) | What it re-derives |
|---|---|
| rakun-app `file_router.bp` `conventionFiles`, `conventionKind`, `conflictProblems` | the eight convention file kinds; the tree's two conflicts |
| onze `types.bp` `AppFile`, `appFileKinds`, `classifyAppFile` | the same eight kinds, a second time |
| onze-bundler `chunk.bp` `patternOfSegment` | group/slot stripping — `segment.patternOf(parsePath(..))` |
| onze-cli `scan.bp` (a different `patternOfSegment`) | the same, a third way |
| rakun-app `static_gen.bp` `segmentName`, `bound`, `expandRow`, `expandParams` | filling `[x]` / `[[...x]]` from `generateStaticParams` rows |
| rakun-hateoas `hal.bp` `bracketToColon` | `[x]` → `:x` |
| jhonstart `routes.bp` `#[page]` | the param names of a segment |

## Mechanism

`routing` already parses a path into segments (`parsePath`, `segment.patternOf`). A decorator body
may call a bodied package function (only a *host* function is refused), so jhonstart's `#[page]`
calls `segment.paramNamesOf` directly. On feat `libs/routing/src/` holds 9 modules (no
`conventions.bp`) and 66 tests.

The surface (names under decision 163 — an `import {x} from "<package>"` is ambiguous when two
packages of a program export `x`):

| In the package | Replaces | Why this name |
|---|---|---|
| `conventions.fileKinds() -> Array<string>` — `layout`, `template`, `error`, `loading`, `not-found`, `page`, `default`, `route` (the order the kinds wrap a page, decision 171) | onze `appFileKinds`, rakun-app `conventionFiles` | free |
| `conventions.kindOf(file) -> ?string` | rakun-app `conventionKind` (which answers the LETTER) | free |
| `conventions.kindLetter(kind) -> string` — the inverse of `table.kindLabel` (decision 172) | the letter half of rakun-app `conventionKind` | free |
| `conventions.classify(appDir, path) -> ?ConventionFile` — one path (decision 173), pure | onze `classifyAppFile` | free |
| `conventions.ConventionFile(authoredPath, segment, kind)` | onze `AppFile` (same three fields) | onze exports `AppFile` |
| `conventions.conventionConflicts(entries: Array<ConventionFile>) -> Array<string>` | rakun-app `conflictProblems(entries: ScanEntry[])` | rakun-app exports `conflictProblems` |
| `segment.paramNamesOf(seg) -> Array<string>` | jhonstart `#[page]`'s hand walk | `validation/table` exports `paramNames` |
| `segment.fillPattern(pattern, bindings: Array<#(string, string)>) -> @Result<string, string>` | rakun-app `expandRow` | jhonstart `router` exports `fill` |
| `segment.toColonPattern(pattern) -> string` | rakun-hateoas `bracketToColon` | free |

Where the package deliberately differs from the copy it replaces:

- `fillPattern` accepts an optional catch-all with **no** binding (rakun-app's `expandRow` refuses a
  row that does not bind it and accepts one that binds it to `""`), and refuses a name bound twice
  (`expandRow` takes the first).
- `paramNamesOf` reads through `parseSegment`: `[a.b]` captures `a.b` (the hand walk strips the dot)
  and an unclosed `[x` captures nothing (the hand walk captures `x`).
- `classify` compares the app directory part by part; over ASCII paths that is `startsWith(appDir +
  "/")` exactly, and it does not depend on `String.slice`'s unit.
- `conventionConflicts`' refusals read `routing: …` in ASCII (` - ` where rakun wrote a dash).

The branch reports each function identical to the copy it replaces over the same inputs on erlang
and commonJS (53 paths × 5 app directories for `classify`; 7 trees for `conventionConflicts`; 12
filling and 5 refused rows for `fillPattern`; 20 patterns for `toColonPattern`; 9 segments for
`paramNamesOf`) — re-checked on feat when it lands.

## Open

### Step 1 — `conventions.bp`

`fileKinds`, `kindOf`, `kindLetter`, `classify` (takes the path, never reads the disk),
`conventionConflicts` (moved in substance from rakun-app's `conflictProblems`, over the classified
files handed in).

- [ ] `libs/routing/test/conventions_test.bp`: every kind classifies, a stray file answers `null`,
      page-beside-route in one segment is a named conflict, `kindLetter` inverts `table.kindLabel`
      for the eight kinds; green on erlang and commonJS
- [ ] `classify` takes the path it is handed; `grep -rn "fs\." libs/routing/src` is empty

### Step 2 — segment helpers

`segment.paramNamesOf`, `segment.fillPattern` (a missing required binding is the `Error`; an
optional catch-all left empty is not), `segment.toColonPattern`.

- [ ] `fillPattern` refuses a missing `[x]` and accepts a missing `[[...x]]`; tests on both rows
- [ ] `toColonPattern("[id]/[...rest]")` is `":id/:...rest"` — what `hal.bp`'s `bracketToColon`
      produces today (only the outer bracket pair is replaced), byte-identical to it, asserted

### Step 3 — consumers, one commit per member

Each site deletes its copy and imports the package; the member's tests do not change their
assertions except where named.

| Member | Deletes | Imports from `routing` | Needs attention |
|---|---|---|---|
| rakun-app `file_router.bp` | `conventionFiles`, `conventionKind`, `conflictProblems`, `hasConvention`, `rootGroupOf` | `conventions.fileKinds`, `kindOf`, `kindLetter`, `ConventionFile`, `conventionConflicts` | `scanTable` writes the wire letter through `conventions.kindLetter` (decision 172); `conventionsIn` iterates `fileKinds()`, so a segment's records come out in the wrap order of decision 171 (no rakun test asserts the order); `file_router_scan_test.bp` asserts `conventionKind` itself; the refusals lose the `rakun ` prefix and the dash (the scan tests assert `both`, `page.bp`, `route.bp`, `/about`, `(marketing)`, `(shop)` — all kept) |
| rakun-app `static_gen.bp` | `segmentName`, `bound`, `expandRow`'s body (`expandParams` keeps the duplicate-path refusal over `fillPattern`) | `segment.fillPattern` | an `Error` becomes the halt — its text carries the three phrases `static_gen_test.bp` asserts (``binds no `slug` ``, ``binds `extra` ``, ``holds a `/` ``); a row that does not bind an optional catch-all starts to fill |
| rakun-hateoas `hal.bp` | `bracketToColon` | `segment.toColonPattern` | none |
| onze `types.bp` | `appFileKinds`, `classifyAppFile`; `AppFile` if `ConventionFile` replaces it | `conventions.fileKinds`, `classify`, `ConventionFile` | `AppFile` is imported by onze-cli (`scan.bp`, `generate.bp`) and constructed in `scan.bp`; `classifyAppFile` is imported by onze-cli and onze-bundler (`chunk.bp`, `graph.bp`); `describeAppFiles` (the `types` snapshot, `onze-test`'s `assertAppFiles`) stays in onze over `classify`; `onze/test/types_test.bp` asserts `appFileKinds`' order by name — rewritten to the wrap order (decision 171) |
| onze-cli `scan.bp`, onze-bundler `chunk.bp` | both `patternOfSegment` | `segment.pathProblem`, `segment.parsePath`, `segment.patternOf` (already in the package) | the two copies disagree on a segment `pathProblem` refuses: onze-cli answers `""`, onze-bundler strips by hand |
| jhonstart `routes.bp` | the hand walk of `#[page]` | `segment.paramNamesOf`, and `segment.parseSegment` / `kindName` for "is it a list" | `[a.b]` and an unclosed `[x` change (§ Mechanism) |

- [ ] rakun-app: `conventionFiles` / `conventionKind` / `expandParams`' hand fill gone; `rakun-app`
      tests green
- [ ] onze: `appFileKinds` / `classifyAppFile` / `_folder` gone; onze-cli and onze-bundler
      `patternOfSegment` gone; onze tests green on both rows
- [ ] rakun-hateoas `bracketToColon` gone; jhonstart `#[page]` calls `segment.paramNamesOf`
- [ ] the app tree of `onze/examples/blog` classifies identically before and after (diff of the
      staged tree)

Outside this front's files, and changed by their owners: `libs/AGENTS.md`'s packages row for
`routing` does not name the conventions yet (`104-http`'s line); `07-onze/modules.md`'s dependency
column gains onze → `routing` (49-d reversed).

**Gate:** standard (fronts.md § Gate) + each touched member's `AGENTS.md` updated in its commit
