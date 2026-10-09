# Front 102 — routing conventions: `routing` gains `conventions` and the segment helpers

**Priority:** high — segment grammar hand-walked in seven places outside `routing`, two disagreeing
on what an app file is; 128 and rakun group A wait on step 3 · **State:** steps 1–2 done (the
package); step 3 open
**Depends on:** decision 323 (49-d confirmed as amended: "onze imports nothing from routing"
reversed) (step 3)
**Owns:** `repository/botopink-lang/libs/routing/src/conventions.bp` (new), `libs/routing/src/segment.bp`
(new helpers), `libs/routing/test/**`, `libs/routing/AGENTS.md`, `libs/routing/botopink.json`
(`files`), `libs/routing/src/root.bp` (the module's line) · consumers, one commit each: `repository/rakun/modules/rakun-app/src/{file_router,static_gen}.bp`,
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
directly. `libs/routing/src/`: 10 modules, 82 tests (66 before steps 1–2).

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

Measured identical to the copies on erlang and commonJS, the copies run beside the package (a
scratch test, not kept): `classify` = onze `classifyAppFile` over 396 paths × 5 app directories
(segment and kind); `kindLetter(kindOf(f))` = rakun-app `conventionKind` over 12 names;
`toColonPattern` = rakun-hateoas `bracketToColon` over 20 patterns; `paramNamesOf` = jhonstart's
hand walk over 9 segments (none with a dot or an unclosed bracket); `fillPattern` = `expandRow` over
6 filling rows. `conventionConflicts` is `conflictProblems`' logic over classified files; its texts
differ as stated above.

## Done

- Step 1 — `conventions.bp`: `ConventionFile`, `fileKinds` (wrap order, 171), `kindOf`, `kindLetter`
  (172), `classify` (one path, 173), `conventionConflicts`; `test/conventions_test.bp` (9 tests) —
  every kind classifies, stray files answer `null`, page-beside-route and the two-root-groups claim
  are named conflicts, `kindLetter` inverts `table.kindLabel`; `grep -rn "fs\." libs/routing/src`
  empty
- Step 2 — `segment.paramNamesOf`, `segment.fillPattern` (refuses a missing `[x]`, accepts a missing
  or empty `[[...x]]`, refuses a twice-bound name), `segment.toColonPattern`
  (`"[id]/[...rest]"` → `":id/:...rest"` asserted); 7 tests in `test/segment_test.bp`
- Both: `botopink test` 82 passed, 0 failed on erlang and on commonJS; `botopink format --check src
  test` clean; `libs/routing/AGENTS.md`, `botopink.json` `files`, `root.bp` updated

## Open

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
(`104-http`'s line); `07-onze/modules.md`'s dependency column gains onze → `routing` (323).

**Gate:** standard (fronts.md § Gate) + each touched member's `AGENTS.md` updated in its commit
