# Front 102 — routing conventions: `routing` gains `conventions` and the segment helpers

**Priority:** high — segment grammar hand-walked in seven places outside `routing`, two disagreeing
on what an app file is; 128 and rakun group A wait on step 3 · **State:** not on feat; steps 1–2
reported done on unpushed branch `front/102-routing-conventions` — push it
**Depends on:** the branch pushed and landed (steps 1–2) · 49-d confirmed as amended ("onze imports
nothing from routing" — reversed here) (step 3)
**Owns:** `repository/botopink-lang/libs/routing/src/conventions.bp` (new), `libs/routing/src/segment.bp`
(new helpers), `libs/routing/test/**`, `libs/routing/AGENTS.md`, `libs/routing/botopink.json`
(`files`) · consumers, one commit each: `repository/rakun/modules/rakun-app/src/{file_router,static_gen}.bp`,
`repository/rakun/modules/rakun-hateoas/src/hal.bp`, `repository/onze/modules/onze/src/types.bp`,
`repository/onze/modules/onze-cli/src/scan.bp`, `repository/onze/modules/onze-bundler/src/chunk.bp`,
`repository/jhonstart/modules/jhonstart/src/routes.bp`
**Does not touch:** `build.zig`, `libs/AGENTS.md`, `scripts/format-check.sh` (`routing` registered) ·
other files of those members · `onze-bundler/src/scan.bp` (`stagedSegment`, onze-specific, stays) ·
rakun-app's disk walk (`walkSegments` over `fs` — no host cell in a bundled package)

## Goal

The route-segment grammar (`[x]`, `[...x]`, `[[...x]]`, `(group)`, `@slot`, `(.)`/`(..)`
interceptors) owned by `routing` alone; its seven re-derivations gone:

| Site (on feat) | What it re-derives |
|---|---|
| rakun-app `file_router.bp` `conventionFiles`, `conventionKind`, `conflictProblems` | the eight convention file kinds; the tree's two conflicts |
| onze `types.bp` `AppFile`, `appFileKinds`, `classifyAppFile` | the same eight kinds, again |
| onze-bundler `chunk.bp` `patternOfSegment` | group/slot stripping — `segment.patternOf(parsePath(..))` |
| onze-cli `scan.bp` (a different `patternOfSegment`) | the same, a third way |
| rakun-app `static_gen.bp` `segmentName`, `bound`, `expandRow`, `expandParams` | filling `[x]` / `[[...x]]` from `generateStaticParams` rows |
| rakun-hateoas `hal.bp` `bracketToColon` | `[x]` → `:x` |
| jhonstart `routes.bp` `#[page]` | a segment's param names |

## Mechanism

`routing` already parses paths (`parsePath`, `segment.patternOf`). A decorator body may call a bodied
package function (only *host* functions refused), so `#[page]` calls `segment.paramNamesOf`
directly. On feat `libs/routing/src/`: 9 modules (no `conventions.bp`), 66 tests.

Surface (names under decision 163 — `import {x} from "<package>"` is ambiguous when two packages
export `x`):

| In the package | Replaces | Why this name |
|---|---|---|
| `conventions.fileKinds() -> Array<string>` — `layout`, `template`, `error`, `loading`, `not-found`, `page`, `default`, `route` (wrap order, decision 171) | onze `appFileKinds`, rakun-app `conventionFiles` | free |
| `conventions.kindOf(file) -> ?string` | rakun-app `conventionKind` (answers the LETTER) | free |
| `conventions.kindLetter(kind) -> string` — inverse of `table.kindLabel` (decision 172) | the letter half of rakun-app `conventionKind` | free |
| `conventions.classify(appDir, path) -> ?ConventionFile` — one path (decision 173), pure | onze `classifyAppFile` | free |
| `conventions.ConventionFile(authoredPath, segment, kind)` | onze `AppFile` (same three fields) | onze exports `AppFile` |
| `conventions.conventionConflicts(entries: Array<ConventionFile>) -> Array<string>` | rakun-app `conflictProblems(entries: ScanEntry[])` | rakun-app exports `conflictProblems` |
| `segment.paramNamesOf(seg) -> Array<string>` | jhonstart `#[page]`'s hand walk | `validation/table` exports `paramNames` |
| `segment.fillPattern(pattern, bindings: Array<#(string, string)>) -> @Result<string, string>` | rakun-app `expandRow` | jhonstart `router` exports `fill` |
| `segment.toColonPattern(pattern) -> string` | rakun-hateoas `bracketToColon` | free |

Deliberate differences from the copies:
- `fillPattern` accepts an optional catch-all with **no** binding (`expandRow` refuses an unbound
  one, accepts `""`); refuses a name bound twice (`expandRow` takes the first).
- `paramNamesOf` reads through `parseSegment`: `[a.b]` captures `a.b` (hand walk strips the dot);
  unclosed `[x` captures nothing (hand walk captures `x`).
- `classify` compares the app directory part by part — over ASCII exactly `startsWith(appDir +
  "/")`, independent of `String.slice`'s unit.
- `conventionConflicts`' refusals read `routing: …` in ASCII (` - ` where rakun wrote a dash).

Branch reports each function identical to its copy on erlang and commonJS (53 paths × 5 app
directories for `classify`; 7 trees for `conventionConflicts`; 12 filling + 5 refused rows for
`fillPattern`; 20 patterns for `toColonPattern`; 9 segments for `paramNamesOf`) — re-checked on feat
at landing.

## Open

### Step 1 — `conventions.bp`

`fileKinds`, `kindOf`, `kindLetter`, `classify` (takes the path, never reads disk),
`conventionConflicts` (rakun-app's `conflictProblems` in substance, over the classified files handed in).

- [ ] `libs/routing/test/conventions_test.bp`: every kind classifies, a stray file answers `null`,
      page-beside-route in one segment is a named conflict, `kindLetter` inverts `table.kindLabel`
      for the eight kinds; green on erlang and commonJS
- [ ] `classify` takes the path it is handed; `grep -rn "fs\." libs/routing/src` is empty

### Step 2 — segment helpers

`segment.paramNamesOf`, `segment.fillPattern` (missing required binding → `Error`; empty optional
catch-all is not), `segment.toColonPattern`.

- [ ] `fillPattern` refuses a missing `[x]` and accepts a missing `[[...x]]`; tests on both rows
- [ ] `toColonPattern("[id]/[...rest]")` is `":id/:...rest"` — byte-identical to `hal.bp`'s
      `bracketToColon` today (only the outer bracket pair replaced), asserted

### Step 3 — consumers, one commit per member

Each site deletes its copy, imports the package; member tests keep their assertions except where named.

| Member | Deletes | Imports from `routing` | Needs attention |
|---|---|---|---|
| rakun-app `file_router.bp` | `conventionFiles`, `conventionKind`, `conflictProblems`, `hasConvention`, `rootGroupOf` | `conventions.fileKinds`, `kindOf`, `kindLetter`, `ConventionFile`, `conventionConflicts` | `scanTable` writes the wire letter via `conventions.kindLetter` (decision 172); `conventionsIn` iterates `fileKinds()` → a segment's records in decision 171's wrap order (no rakun test asserts order); `file_router_scan_test.bp` asserts `conventionKind` itself; refusals lose the `rakun ` prefix and the dash (scan tests assert `both`, `page.bp`, `route.bp`, `/about`, `(marketing)`, `(shop)` — all kept) |
| rakun-app `static_gen.bp` | `segmentName`, `bound`, `expandRow`'s body (`expandParams` keeps the duplicate-path refusal over `fillPattern`) | `segment.fillPattern` | an `Error` becomes the halt — text carries the three phrases `static_gen_test.bp` asserts (``binds no `slug` ``, ``binds `extra` ``, ``holds a `/` ``); a row not binding an optional catch-all starts to fill |
| rakun-hateoas `hal.bp` | `bracketToColon` | `segment.toColonPattern` | none |
| onze `types.bp` | `appFileKinds`, `classifyAppFile`; `AppFile` if `ConventionFile` replaces it | `conventions.fileKinds`, `classify`, `ConventionFile` | `AppFile` imported by onze-cli (`scan.bp`, `generate.bp`), constructed in `scan.bp`; `classifyAppFile` imported by onze-cli and onze-bundler (`chunk.bp`, `graph.bp`); `describeAppFiles` (`types` snapshot, `onze-test`'s `assertAppFiles`) stays in onze over `classify`; `onze/test/types_test.bp` asserts `appFileKinds`' order by name — rewritten to the wrap order (decision 171) |
| onze-cli `scan.bp`, onze-bundler `chunk.bp` | both `patternOfSegment` | `segment.pathProblem`, `segment.parsePath`, `segment.patternOf` (already in the package) | they disagree on a segment `pathProblem` refuses: onze-cli answers `""`, onze-bundler strips by hand |
| jhonstart `routes.bp` | `#[page]`'s hand walk | `segment.paramNamesOf`, `segment.parseSegment` / `kindName` for "is it a list" | `[a.b]` and unclosed `[x` change (§ Mechanism) |

- [ ] rakun-app: `conventionFiles` / `conventionKind` / `expandParams`' hand fill gone; `rakun-app`
      tests green
- [ ] onze: `appFileKinds` / `classifyAppFile` / `_folder` gone; onze-cli and onze-bundler
      `patternOfSegment` gone; onze tests green on both rows
- [ ] rakun-hateoas `bracketToColon` gone; jhonstart `#[page]` calls `segment.paramNamesOf`
- [ ] `onze/examples/blog`'s app tree classifies identically before and after (diff of the staged tree)

Changed by their owners: `libs/AGENTS.md`'s `routing` packages row does not name the conventions yet
(`104-http`'s line); `07-onze/modules.md`'s dependency column gains onze → `routing` (49-d reversed).

**Gate:** standard (fronts.md § Gate) + each touched member's `AGENTS.md` updated in its commit
