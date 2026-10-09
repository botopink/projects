# Front 102 — routing conventions: `routing` gains `conventions` and the segment helpers

**Priority:** high — segment grammar hand-walked in seven places outside `routing`, two disagreeing
on what an app file is; 128 and rakun group A wait on step 3 · **State:** steps 1–2 done (the
package); step 3 done as patches, one per member (`.tasks/102s3-103s2-b/patches/`), to land in
fronts.md's order
**Depends on:** decision 323 (49-d confirmed as amended: "onze imports nothing from routing"
reversed) (step 3)
**Owns:** `repository/routing/src/conventions.bp` (new), `repository/routing/src/segment.bp`
(new helpers), `repository/routing/test/**`, `repository/routing/AGENTS.md`, `repository/routing/botopink.json`
(`files`), `repository/routing/src/root.bp` (the module's line) · consumers, one commit each: `repository/rakun/modules/rakun-app/src/{file_router,static_gen}.bp`,
`repository/rakun/modules/rakun-hateoas/src/hal.bp`, `repository/onze/modules/onze/src/types.bp`,
`repository/onze/modules/onze-cli/src/scan.bp`, `repository/onze/modules/onze-bundler/src/chunk.bp`,
`repository/jhonstart/modules/jhonstart/src/routes.bp`
**Does not touch:** the compiler (`repository/botopink-lang/**` — `routing` is a repository of its own since 138 (decision 326)) ·
other files of those members · `onze-bundler/src/scan.bp` (`stagedSegment`, onze-specific, stays) ·
rakun-app's disk walk (`walkSegments` over `fs` — no host cell in `routing`)

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
package function (only *host* functions refused), a package record built in it included (01-checker
step 21), so `#[page]` calls `segment.paramNamesOf` directly. `repository/routing/src/`: 10 modules,
82 tests (66 before steps 1–2).

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
  unclosed `[x` captures nothing (hand walk captures `x`). In `#[page]` (measured with step 3's
  jhonstart patch): `#[page("x/[a.b]")]` is now refused at compile time — the emitted accessor's
  `val a.b` does not parse (the hand walk silently bound `ab`); `#[page("y/[z")]` emits an accessor
  with no field, as `routing` registers `[z` as a static segment.
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
  are named conflicts, `kindLetter` inverts `table.kindLabel`; `grep -rn "fs\." repository/routing/src`
  empty
- Step 2 — `segment.paramNamesOf`, `segment.fillPattern` (refuses a missing `[x]`, accepts a missing
  or empty `[[...x]]`, refuses a twice-bound name), `segment.toColonPattern`
  (`"[id]/[...rest]"` → `":id/:...rest"` asserted); 7 tests in `test/segment_test.bp`
- Both: `botopink test` 82 passed, 0 failed on erlang and on commonJS; `botopink format --check src
  test` clean; `repository/routing/AGENTS.md`, `botopink.json` `files`, `root.bp` updated

- Step 3 — consumers, one patch per member (decision 188), in fronts.md's order (rakun, jhonstart,
  onze), re-applied on 138's heads (the dependency lines 138 added kept); before = after on every
  member of the three repositories, every declared target:
  - rakun-app `file_router.bp`: `conventionFiles`, `conventionKind`, `conflictProblems`,
    `hasConvention`, `rootGroupOf` gone; `conventionsIn` iterates `conventions.fileKinds()` (wrap
    order, 171); `scanTable` writes `kindLetter(kindOf(f))` (172); `scanAppDir` hands its entries to
    `conventionConflicts` as `ConventionFile`s (texts now `routing: …`, the asserted words kept);
    `file_router_scan_test.bp`'s letter test reads `kindLetter(kindOf(…))`. `static_gen.bp`:
    `segmentName`, `bound`, `expandRow` gone; `expandParams` halts with `fillPattern`'s `Error` and
    keeps the duplicate-path refusal (the three asserted phrases unchanged). rakun-app 204 passed,
    0 failed on erlang (204 before)
  - rakun-hateoas `hal.bp`: `bracketToColon` gone, `segment.toColonPattern`; 14 passed, 0 failed
    on erlang
  - jhonstart `routes.bp`: `#[page]`'s hand walk gone — the names from `segment.paramNamesOf`, which
    of them is a list from `parseSegment` / `kindName`; jhonstart 204 passed, 0 failed on commonJS
    and on erlang (204 before), every jhonstart example and refusal unchanged
  - onze-cli `scan.bp` / `generate.bp`: `classify` / `ConventionFile`; `patternOfSegment` gone (the
    pattern `patternOf(parsePath(seg))`, `""` beside the `pathProblem` that already fails the scan).
    onze-bundler `chunk.bp` / `graph.bp`: `classify`; `patternOfSegment` gone (`patternOf(parsePath(
    seg))` — a refused segment halts with `routing`'s text; the scan refused it first);
    `chunk_test.bp`'s pattern test reads `routing`. onze `types.bp`: `AppFile`, `appFileKinds`,
    `classifyAppFile` gone; `describeAppFiles` over `classify` (its snapshot unchanged);
    `types_test.bp` asserts `fileKinds()` in wrap order. On commonJS and on erlang (before = after):
    onze-cli 31, onze-bundler 42, onze 23, onze-test 7 (`describeAppFiles` consumer) — 0 failed
  - `onze/examples/blog`: the scan table and the staged tree (`scanApp` + `stage`, 484 lines) dumped
    before and after on commonJS and on erlang — identical (a scratch test, not kept)

## Open

Nothing — step 3 lands as its patches (rakun-01, rakun-02, jhonstart-02, onze-01–03).

Changed by their owners: `07-onze/modules.md`'s dependency column gains onze → `routing` (323).

**Gate:** standard (fronts.md § Gate) + each touched member's `AGENTS.md` updated in its commit
