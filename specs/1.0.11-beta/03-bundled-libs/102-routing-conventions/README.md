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
| rakun-app `file_router.bp:169-183` (`conventionFiles`, `conventionKind`) | the eight convention file kinds |
| onze `types.bp:109-127` (`appFileKinds`, `classifyAppFile`, `_folder`) | the same eight kinds, a second time |
| onze-bundler `chunk.bp:30-33` (`patternOfSegment`) | group/slot stripping — `segment.patternOf(parsePath(..))` |
| onze-cli `scan.bp:54` (a different `patternOfSegment`) | the same, a third way |
| rakun-app `static_gen.bp:120-156` (`expandParams`) | filling `[x]` / `[[...x]]` from `generateStaticParams` rows |
| rakun-hateoas `hal.bp:140` (`bracketToColon`) | `[x]` → `:x` |
| jhonstart `routes.bp:178-195` (`#[page]`) | the param names of a segment |

Two of those (rakun-app and onze) are the two halves of one app tree, and they classify the same
file independently.

## Current state

Measured on the worktree at the milestone's open: `libs/routing` has 8 modules and 66 tests, both
rows green; it declares no host cell and is imported by rakun-app, jhonstart and onze-cli already.
The seven sites above are on disk at the lines given.

## Mechanism

`routing` already parses a path into segments (`parsePath`, `segment.patternOf`); the sites above
were written before those existed or before `routing` was bundled, and never went back. A decorator
body may call a bodied package function (only a *host* function is refused — `language-gaps.md`
toolchain row 19), so jhonstart's `#[page]` can call `segment.paramNames` directly.

## Steps

### Step 1 — `conventions.bp`

`fileKinds() -> Array<string>` (the eight kinds, one order), `kindOf(file) -> ?string`,
`classify(appDir, path) -> ?AppFile` (pure: takes the path, never reads the disk),
`conflictProblems(entries) -> Array<string>` (moved from `file_router.bp:333`, over entries handed in).

**Acceptance:**
- [ ] `libs/routing/test/conventions_test.bp`: every kind classifies, a stray file answers `null`,
      page-beside-route in one segment is a named conflict; green on erlang and commonJS
- [ ] `classify` takes a file list; `grep -n "fs\." libs/routing/src` stays empty

### Step 2 — segment helpers

`segment.paramNames(seg) -> Array<string>`, `segment.fill(pattern, bindings) -> @Result<string, string>`
(a missing required binding is the `Error`; an optional catch-all left empty is not),
`segment.toColonPattern(pattern) -> string`.

**Acceptance:**
- [ ] `fill` refuses a missing `[x]` and accepts a missing `[[...x]]`; tests on both rows
- [ ] `toColonPattern("[id]/[...rest]")` is `":id/*rest"` (or whatever `hal.bp:140` produces today —
      byte-identical to it, asserted)

### Step 3 — consumers, one commit per member

Each site deletes its copy and imports the package; the member's tests must not change their
assertions.

**Acceptance:**
- [ ] rakun-app: `conventionFiles`/`conventionKind`/`expandParams` gone; `rakun-app` tests green
- [ ] onze: `appFileKinds`/`classifyAppFile`/`_folder` gone; onze-cli and onze-bundler
      `patternOfSegment` gone; onze tests green on both rows
- [ ] rakun-hateoas `bracketToColon` gone; jhonstart `#[page]` calls `segment.paramNames`
- [ ] the app tree of `onze/examples/blog` classifies identically before and after (diff of the
      staged tree)

## Gate

- [ ] `zig build test` cold, green; `zig build test-libs` green with no new ledger line
- [ ] `libs/routing/AGENTS.md` and each touched member's `AGENTS.md` updated in the same commit
- [ ] Commit on `front/102-routing-conventions`; landing is the maintainer's step

## Blast radius

Six members change imports; no snapshot directory is shared. 49-d is reversed (onze now imports
`routing` in `types.bp`); `07-onze`'s modules.md dependency column changes.

## Notes

`onze-bundler/src/scan.bp:47-58` (`stagedSegment`) is onze-specific staging and stays. The disk
walk (`walkSegments`, over `fs`) stays in rakun-app: a bundled package declares no host cell.
