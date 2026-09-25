# Front 95 — Ecosystem package restructure

**Track:** cross-cutting (A std · B rakun · C jhonstart · D emilia · E onze) — the per-library half of [`../README.md`](../README.md) (`02-packaging`), which states the workspace rule every library follows; the assertion half is [`../../01-std/`](../../01-std/)
**Priority:** high — every library front writes its tests into a member this front creates
**Target:** none of its own — each member declares its library's targets
**Wave:** 1, beside each library's first front
**Depends on:** `01-std` (`asserts`, `snapshots`, `mocks` in std; the old `onze` retired) · the maintainer, for the `onze` takeover (decision [79](../../decisions-taken.md#79-the-old-onze-repository-is-tagged-archived-and-re-pointed))
**Owns:** the `modules/<lib>/` and `modules/<lib>-test/` skeletons and their `botopink.json`, and the relocations the cut in each library's `modules.md` needs — the directory moves and the import lines a move changes, never behaviour
**Does not touch:** `libs/std/src/**` (01-std) · the source of any library beyond the one import line a move changes (its fronts) · the members a library front creates for its own code (`jhonstart-link` 27, `jhonstart-forms` 67, `jhonstart-emilia` 30, `onze-*` 49–71)
**Reference:** [`../README.md`](../README.md) §§ 2, 5, 9, 11 · `03-rakun/modules.md` · `04-jhonstart/modules.md` · `05-emilia/modules.md` · `06-onze/modules.md` · [`../../01-std/asserts-api.md`](../../01-std/asserts-api.md) · [`../../01-std/onze-migration.md`](../../01-std/onze-migration.md)

---

## What this front delivers

Every library is a workspace (decision 75) with three mandatory places: the core member
`modules/<lib>/` (what `from "<lib>"` resolves to), the test-helper member `modules/<lib>-test/`, and
`examples/`. Further members are cut at a consumption boundary, as each library's `modules.md`
decides. This front creates the `-test` members, makes the cuts that exist only to relocate code,
and keeps the ownership lines of the specs pointing at the member paths.

A `<lib>-test` member:

- depends on its core (`{ "workspace": true }`) and on std; a core never depends on it;
- exposes `assert<Subject>(loc: SourceLocation, …) -> @Result<void, string>` helpers that hand `loc`
  to std's `snapshots` unchanged, plus fixtures and builders — filled by the library's fronts;
- **re-exports nothing from std** — a consumer writes `import {asserts} from "std"` beside
  `import {assertCss} from "emilia-test"`;
- keeps no mocking runtime: mocking is `std/mocks` (decision [71](../../decisions-taken.md#71-mocking-lives-in-stdmocks)),
  and a `-test` member documents only the injection pairing (`#[mocks.mock]` + `#[bean]` in rakun).

The worked examples are `01-std`'s: [`asserts-unit-example.bp`](../../01-std/examples/asserts-unit-example.bp),
[`emilia-test-submodule-example.bp`](../../01-std/examples/emilia-test-submodule-example.bp) and
[`emilia-test-consumer-example.bp`](../../01-std/examples/emilia-test-consumer-example.bp).

## Current state

| Library | Members at HEAD of this front | Final cut (its `modules.md`) | Still to create, and by whom |
|---|---|---|---|
| **std** | — (bundled, not a workspace) | — | — |
| **jhonstart** | `jhonstart` (core), `jhonstart-html`, `jhonstart-test`; examples `jhonstart-counter`, `jhonstart-markup`, `jhonstart-todo` | six: core, `-html`, `-link`, `-forms`, `-emilia` (the bridge of decision 113), `-test` | `jhonstart-link` (front 27 — `link.bp`, `reconcile.bp` are still in core), `jhonstart-forms` (67), `jhonstart-emilia` (30) |
| **emilia** | `emilia` (core), `emilia-test`; fifteen example members | two: core, `-test` | — |
| **rakun** | `rakun` (core) and thirteen members, `rakun-test` among them | thirteen: `rakun-validation` leaves for the bundled library `validation` (decision 116) | the removal is rakun front 14; the core's `["erlang"]` targets are front 04 (decision 113) |
| **onze** | the old mocking library, still in the `repository/onze` submodule | seven (`06-onze/modules.md`): `onze`, `onze-test`, `onze-cli`, `onze-bundler`, `onze-assets`, `onze-og`, `onze-release` | all — step 2, after the maintainer's action |

The assertion surface is done: `libs/std/src/asserts.bp` (`import {asserts} from "std"`) carries the
API of [`../../01-std/asserts-api.md`](../../01-std/asserts-api.md), the authority for its names and
signatures, and `libs/std/src/mocks.bp` carries the old `onze` mocking surface (decision 71).

## Steps

### Step 1 — std assertions — DONE by `01-std`

Nothing of this front's. `libs/std/src/asserts.bp` and `libs/std/src/mocks.bp` are on feat;
`asserts-api.md` lists what ships and what does not.

**Acceptance (met):**
- [x] `import {asserts} from "std";` resolves from a consumer package, and every helper of `asserts-api.md` § *Migration table* marked shipped is green on commonJS and erlang
- [x] `import {mocks} from "std";` carries the old `onze_test.bp` cases as inline tests (nine, green on commonJS and erlang)

### Step 2 — The `onze` workspace — WAITS on the maintainer

The directory `repository/onze` still holds the old mocking library. Decision 79 hands it over in
this order; the first two items are the maintainer's, because they act on the remotes:

1. **Retire the old repository** (`botopink/onze`): tag its last `feat` commit `mocking-lib-final`;
   add a banner to its `README.md` naming `std/mocks` and `std/asserts` (`libs/std/src/mocks.bp`,
   `libs/std/src/asserts.bp`) as the successors; push the tag and the banner; archive the
   repository on GitHub (read-only). Nothing is vendored into the meta repository — there is no
   `repository/_archived/`.
2. **Free the name and create the orchestrator's repository**: rename the archived one (for example
   to `botopink/onze-mocking`) and create an empty `botopink/onze` with a `feat` branch — or create
   the orchestrator under a fresh name and give that URL below.
3. **Re-point the submodule** (meta): `.gitmodules` `[submodule "repository/onze"] url = <the
   orchestrator's URL>`, `git submodule sync`, check out the orchestrator's `feat` at
   `repository/onze`. The directory name and the submodule entry stay; only what they point at
   changes.
4. **This front** then creates the workspace: `repository/onze/botopink.json` (`name onze`,
   `targets`, `"workspaces": ["modules/*", "examples/*"]`) and the seven member skeletons of
   `06-onze/modules.md`, each `botopink.json` + `src/root.bp` with one inline `test`; front 49 fills
   `modules/onze/`.

**Acceptance:**
- [ ] `git -C <old repo> rev-parse mocking-lib-final` resolves and the old repository is archived on the remote
- [ ] `git submodule status` shows the orchestrator's commit at `repository/onze`
- [ ] `repository/onze/botopink.json` is a workspace named `onze`; each of the seven members has `botopink.json` (`name onze[-<x>]`, `files`) and `src/root.bp`
- [ ] `zig build test-libs` lists each member, green, and no row for the old library
- [ ] no `botopink.json` in any repository names `"onze"` as a dependency for mocking (met today)

### Step 3 — jhonstart: `jhonstart-html` and `jhonstart-test` — DONE (jhonstart `4c02054`, on `front/95-package-restructure`)

The DSL left the core (`04-jhonstart/modules.md` § 2, "keep, narrowed"): `modules/jhonstart-html/`
holds `html.bp` — its one edit is `import {Element} from "jhonstart"` — and the two suites that
exercise the DSL from a consumer's position, `html_test.bp` and front 94's `elements_test.bp`. The
element constructors stay in core. `modules/jhonstart-test/` exists with an empty `pub` surface.
The example `examples/jhonstart-html/` is now `examples/jhonstart-markup/`, because member names are
unique in a workspace and the DSL member took the name; it imports `html` from `"jhonstart-html"`.
The other three members of the cut are their fronts' (table above).

**Acceptance:**
- [x] `import { Element } from "jhonstart";` resolves to the core; the core lists no `html` module
- [x] `import { html } from "jhonstart-html";` resolves; `html_test.bp` and `elements_test.bp` pass there
- [x] `import { … } from "jhonstart-test";` resolves (one inline test)
- [x] the runner over the branch: `jhonstart` 120/120, `jhonstart-html` 5/5, `jhonstart-test` 1/1, `jhonstart-markup` 7/7, each on commonJS and erlang
- [x] `repository/jhonstart/AGENTS.md` and `modules/*/src/AGENTS.md` reflect the tree
- [ ] merged into jhonstart's `feat`, and the main checkout's `zig build test-libs` shows the rows

### Step 4 — emilia: `emilia-test` — DONE (emilia `f6e740e`, on `front/95-package-restructure`)

emilia's cut is two members (`05-emilia/modules.md`); the core member was already in place.
`modules/emilia-test/` exists with an empty `pub` surface. emilia depends on no library,
dev-dependency included (decision 114).

**Acceptance:**
- [x] `import { Token } from "emilia";` resolves to the core
- [x] `import { … } from "emilia-test";` resolves (one inline test, 1/1 on both rows)
- [x] `repository/emilia/AGENTS.md` reflects the tree
- [ ] merged into emilia's `feat`, and the main checkout's `zig build test-libs` shows the row

### Step 5 — rakun — the layout is on feat; the member changes are other fronts'

The core `modules/rakun/` and the thirteen members exist, each member depending on the core with
`{ "workspace": true }` and listing `files`. What remains changes the member list and belongs to the
fronts that own the code: rakun front 14 deletes `rakun-validation` (now the bundled `validation`,
decision 116), and front 04 makes the core and every member `["erlang"]` (decision 113 item 8, as
amended by 116). This front has nothing left in rakun.

**Acceptance:**
- [x] `import { … } from "rakun";` resolves to `modules/rakun/`
- [x] `repository/rakun/AGENTS.md` reflects the layout
- [ ] (front 14) no `rakun-validation` member; (front 04) no rakun member lists `commonJS`

### Step 6 — Ownership lines at the member paths — DONE (meta `8bf3b218`)

The track-E **Owns** / **Does not touch** lines of fronts 49–52 and 68 read the member paths of
`06-onze/modules.md` (51 and 52 hand their `pub mod` lines to 69); 50, 53 and 69–71 already did, as
do the rows of `fronts.md` § *Track E*. `overview.md`'s `06-onze` row names `onze`. The remaining
`onze13` strings in `overview.md` and `fronts.md` describe the rename itself, which is `01-std`
step 5; they go when it closes.

**Acceptance:**
- [x] every track-E front README's **Owns** line names `modules/<member>/…`
- [ ] `grep -rn onze13 specs/1.0.10-beta/` finds only `unification.md` and the lines naming the rename (closes with step 2)

## Gate

- [x] each library's pre-commit gate (`botopink test` per member, every example built) green on the branch commits
- [x] `botopink-lib-test` over the branches (compiler `0beaa1f9`): 54 passed, 0 failed
- [ ] the library branches merged into their `feat`, the meta submodule bumps on feat, `zig build test-libs` green in the main checkout
- [ ] step 2 closed, with the onze rows in the same run

## Blast radius

Directory moves and manifests only. A consumer of the DSL writes `import {html} from
"jhonstart-html";` beside the builders `from "jhonstart"`; nothing else in any library's public
surface changes. No snapshot is re-recorded.

## Definition of done

- jhonstart, emilia, rakun and onze are workspaces whose members match their `modules.md`, each with a
  `<lib>-test` member that re-exports nothing from std.
- `repository/onze` is the orchestrator's workspace with its seven members; the mocking library lives
  only as the archived, tagged repository, its surface in `std/mocks` and `std/asserts`.
- `zig build test-libs` in the main checkout lists every member on every target it declares, green or
  named in `scripts/known-red-libs.txt` with its owning front.
