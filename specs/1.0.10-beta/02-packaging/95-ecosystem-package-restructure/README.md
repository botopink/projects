# Front 95 — Ecosystem package restructure

**Track:** cross-cutting (A std · B rakun · C jhonstart · D emilia · E onze) — the per-library half of [`../README.md`](../README.md) (`02-packaging`), which states the workspace rule every library follows; the assertion half is [`../../01-std/`](../../01-std/)
**Priority:** high — every library front writes its tests into a member this front creates
**Target:** none of its own — each member declares its library's targets
**Depends on:** `01-std` (`testing.asserts`, `testing.snapshots`, `testing.mocks` in std; the old `onze` retired) · the maintainer, for the `onze` takeover (decision [79](../../decisions-taken.md#79-the-old-onze-repository-is-tagged-archived-and-re-pointed))
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
- **re-exports nothing from std** — a consumer writes `import {testing.asserts} from "std"` beside
  `import {assertSheet} from "emilia-test"`;
- keeps no mocking runtime: mocking is `testing.mocks` (decision [71](../../decisions-taken.md#71-mocking-lives-in-stdmocks)),
  and a `-test` member documents only the injection pairing (`#[mocks.mock]` + `#[bean]` in rakun).

The worked examples are `01-std`'s: [`asserts-unit-example.bp`](../../01-std/examples/asserts-unit-example.bp),
[`emilia-test-submodule-example.bp`](../../01-std/examples/emilia-test-submodule-example.bp) and
[`emilia-test-consumer-example.bp`](../../01-std/examples/emilia-test-consumer-example.bp).

## Current state

| Library | Members | Final cut (its `modules.md`) | Still to create, and by whom |
|---|---|---|---|
| **std** | — (bundled, not a workspace) | — | — |
| **jhonstart** | `jhonstart` (core), `jhonstart-html`, `jhonstart-link`, `jhonstart-forms`, `jhonstart-emilia`, `jhonstart-test`; examples `jhonstart-counter`, `jhonstart-markup`, `jhonstart-todo` | six: core, `-html`, `-link`, `-forms`, `-emilia` (the bridge of decision 113), `-test` | — (`-forms` and `-emilia` are filled by fronts 67 and 30) |
| **emilia** | `emilia` (core), `emilia-test`; fifteen example members | two: core, `-test` | — |
| **rakun** | `rakun` (core), `rakun-app`, `rakun-web`, `rakun-test` and ten scaffolds; examples `rakun-example`, `rakun-container-example`, `rakun-ssr-example` | twenty-seven (`03-rakun/modules.md` § The cut) | the twelve members with no code yet (`rakun-actuator-api`, `rakun-websocket`, `rakun-tx`, `rakun-metrics`, …) are their fronts'; the core's and every member's `["erlang"]` targets are front 04 (decision 113) |
| **erika** | `erika` (core), `erika-test`; example `erika-linq` | two: core, `-test` | — |
| **onze** | the old mocking library, still in the `repository/onze` submodule; the orchestrator's workspace is prepared on a local branch (step 2) | seven (`06-onze/modules.md`): `onze`, `onze-test`, `onze-cli`, `onze-bundler`, `onze-assets`, `onze-og`, `onze-release` | all — step 2, after the maintainer's action |

The assertion surface is std's: `libs/std/src/testing/asserts.bp` (`import {testing.asserts} from "std"`)
carries the API of [`../../01-std/asserts-api.md`](../../01-std/asserts-api.md), the authority for its
names and signatures, and `libs/std/src/testing/mocks.bp` carries the old `onze` mocking surface
(decision 71).

## Steps

### Step 1 — std assertions — `01-std`'s

Nothing of this front's. `libs/std/src/testing/asserts.bp` and `libs/std/src/testing/mocks.bp`;
`asserts-api.md` lists what ships and what does not.

**Acceptance:**
- [x] `import {testing.asserts} from "std";` resolves from a consumer package, and every helper of `asserts-api.md` § *Migration table* marked shipped is green on commonJS and erlang
- [x] `import {testing.mocks} from "std";` carries the old `onze_test.bp` cases as inline tests (nine, green on commonJS and erlang)

### Step 2 — The `onze` workspace — WAITS on the maintainer

The directory `repository/onze` still holds the old mocking library. Decision 79 hands it over in
this order; the first two items are the maintainer's, because they act on the remotes:

1. **Retire the old repository** (`botopink/onze`): tag its last code commit `mocking-lib-final`;
   add a banner to its `README.md` naming std's `testing.mocks` and `testing.asserts`
   (`libs/std/src/testing/mocks.bp`, `libs/std/src/testing/asserts.bp`) as the successors; push the tag and the banner; archive the
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

**Prepared locally (not pushed).** Everything items 1 and 4 need that does not act on a remote:

- *The banner* — the old library's `README.md` opens with the archive notice (std's `mocks` and
  `asserts` as successors, the name passing to the orchestrator), and `AGENTS.md` and `CHANGELOG.md`
  say the same; it is on the old library's `feat`, one commit on top of the last code commit, which
  carries the local tag `mocking-lib-final`.
- *The orchestrator's workspace* — an **orphan** branch `front/95-onze-orchestrator` in the
  `repository/onze` clone (no history of the mocking library): the workspace `botopink.json` (`name onze`,
  `targets ["commonJS", "erlang"]`, `workspaces ["modules/*", "examples/*"]`), the seven members
  (`onze-cli` restricted to `["commonJS"]`, `onze-og` to `["erlang"]`; the in-workspace edges of
  `06-onze/modules.md` § Dependency graph as `{ "workspace": true }`; each `files ["root.bp"]` and
  a `src/root.bp` with an empty `pub` surface and one inline test), `examples/README.md` (the
  three planned examples; the directory must exist for the `examples/*` glob), `README.md`,
  `AGENTS.md`, `CHANGELOG.md`, `LICENSE`, `.gitignore`, and jhonstart's workspace-aware
  pre-commit hook and CI. Every member runs 1/1 on commonJS and on erlang (the two restricted cells
  included), with no `onze-demo` or old `onze` row.
- *The ledger lines* — the two restricted cells need these lines in
  `repository/botopink-lang/scripts/restricted-targets.txt`, added **in the same compiler commit
  that the takeover's meta bump pins** — before the takeover they are stale lines and the ledger
  refuses them:
  ```
  onze-cli                erlang    0          06-onze/F50           `"targets": ["commonJS"]`; the skeleton's one inline test is green on erlang — the CLI runs before any BEAM node exists
  onze-og                 commonJS  0          06-onze/F70           `"targets": ["erlang"]`; the skeleton's one inline test is green on commonJS — SVG → PNG leaves the VM through a port
  ```

**What the maintainer runs** (from the main checkout; `<orch-url>` is the orchestrator's remote):

```sh
# 1 — retire the old repository. The banner is on onze `feat`; the tag is the last code commit.
git -C repository/onze push origin feat refs/tags/mocking-lib-final
#   GitHub: botopink/onze → Settings → Archive; rename it (e.g. botopink/onze-mocking) to free the name
# 2 — the orchestrator's repository: create an empty botopink/onze (or another name — that URL is <orch-url>)
git -C repository/onze push <orch-url> front/95-onze-orchestrator:refs/heads/feat
# 3 — re-point the submodule (meta, on feat)
git config -f .gitmodules submodule.repository/onze.url <orch-url>
git submodule sync repository/onze
git -C repository/onze fetch origin feat && git -C repository/onze checkout -B feat FETCH_HEAD
#   + the two ledger lines above in repository/botopink-lang/scripts/restricted-targets.txt (a compiler commit)
git add .gitmodules repository/onze repository/botopink-lang
git commit -m "chore(95-packaging): repository/onze → the orchestrator's workspace (decision 79)"
# 4 — verify
git ls-remote <old-url> refs/tags/mocking-lib-final   # the tag resolves on the archived repository
git submodule status repository/onze                  # the orchestrator's commit
(cd repository/botopink-lang && zig build test-libs)  # onze, onze-test, onze-cli, … — no onze-demo row
```

**Acceptance:**
- [ ] `git -C <old repo> rev-parse mocking-lib-final` resolves and the old repository is archived on the remote — the maintainer's (item 1); the banner commit is prepared
- [ ] `git submodule status` shows the orchestrator's commit at `repository/onze` — the maintainer's (items 2–3)
- [ ] `repository/onze/botopink.json` is a workspace named `onze`; each of the seven members has `botopink.json` (`name onze[-<x>]`, `files`) and `src/root.bp` — prepared on `front/95-onze-orchestrator`; true of `repository/onze` once item 3 checks it out
- [ ] `zig build test-libs` lists each member, green, and no row for the old library — true of the prepared branch; in the tree after item 3 and the two ledger lines
- [x] no `botopink.json` in any repository names `"onze"` as a dependency for mocking — `grep -rn '"onze"' --include=botopink.json repository` finds only the old library's own name and its own demo `examples/onze` (`onze-demo`), both of which leave with it

### Step 3 — jhonstart: `jhonstart-html` and `jhonstart-test`

The DSL left the core (`04-jhonstart/modules.md` § 2, "keep, narrowed"): `modules/jhonstart-html/`
holds `html.bp` (`import {Element} from "jhonstart"`) and the two suites that exercise the DSL from a
consumer's position, `html_test.bp` and front 94's `elements_test.bp`. The element constructors stay
in core. The example that shows the DSL is `examples/jhonstart-markup/` — member names are unique in a
workspace and the DSL member holds `jhonstart-html`; it imports `html` from `"jhonstart-html"`.

**Acceptance:**
- [x] `import { Element } from "jhonstart";` resolves to the core; the core lists no `html` module
- [x] `import { html } from "jhonstart-html";` resolves; `html_test.bp` and `elements_test.bp` pass there
- [x] `import { … } from "jhonstart-test";` resolves (one inline test)
- [x] the runner: `jhonstart`, `jhonstart-html`, `jhonstart-test`, `jhonstart-markup` green on commonJS and erlang
- [x] `repository/jhonstart/AGENTS.md` and `modules/*/src/AGENTS.md` reflect the tree
- [x] merged into jhonstart's `feat`, and the main checkout's `zig build test-libs` shows the rows

### Step 4 — emilia: `emilia-test`

emilia's cut is two members (`05-emilia/modules.md`). emilia depends on no library, dev-dependency
included (decision 114).

**Acceptance:**
- [x] `import { Token } from "emilia";` resolves to the core
- [x] `import { … } from "emilia-test";` resolves (one inline test, 1/1 on both rows)
- [x] `repository/emilia/AGENTS.md` reflects the tree
- [x] merged into emilia's `feat`, and the main checkout's `zig build test-libs` shows the row

### Step 5 — rakun: `rakun-app` cut out of the core, `rakun-test` given its test

The core `modules/rakun/` and its members exist, each member depending on the core with
`{ "workspace": true }` and listing `files`. `03-rakun/modules.md` § The cut puts fronts 22–25 and
60–66 in `rakun-app`: `file_router.bp` and `ssr.bp` with their host halves, their suites and test
fixtures live in `modules/rakun-app/`, importing `from "rakun"` (the request context `from
"rakun/request_context"`, because a bare `from "rakun"` also finds std's `encoding.percentDecode` and
the compiler refuses the ambiguity); `examples/rakun-ssr` depends on `rakun-app`. The member declares
no `targets`: it inherits the workspace's. `modules/rakun-test/` has its one inline test.

**Acceptance:**
- [x] `import { … } from "rakun";` resolves to `modules/rakun/`
- [x] `repository/rakun/AGENTS.md` reflects the layout
- [x] `import { … } from "rakun-app";` resolves (`examples/rakun-ssr` imports the pipeline from it and prints the byte-identical document it printed before); the core lists neither `file_router` nor `ssr`
- [x] the moved suites keep their counts: `modules/rakun` 310 / 0 on commonJS and 308 / 2 on erlang (the two pinned reds, `server_test.bp`), `modules/rakun-app` 59 / 0 on both rows
- [x] `import { … } from "rakun-test";` resolves to a member with an empty `pub` surface and one inline test, 1/1 on both rows
- [ ] no rakun member lists `commonJS` — front 04's (the `rakun-validation` half is met: no such member)

### Step 6 — Ownership lines at the member paths

The track-E **Owns** / **Does not touch** lines of fronts 49–53 and 68–71 read the member paths of
`06-onze/modules.md` (51 and 52 hand their `pub mod` lines to 69), as do the rows of `fronts.md` §
*Track E*. `overview.md`'s `06-onze` row names `onze`. The remaining `onze13` strings in
`overview.md` and `fronts.md` describe the rename itself, which is `01-std` step 5; they go when it
closes.

**Acceptance:**
- [x] every track-E front README's **Owns** line names `modules/<member>/…`
- [x] `grep -rn onze13 specs/1.0.10-beta/` finds only `unification.md` and the lines naming the rename (`01-std/README.md` step 5, `onze-migration.md`, this README, `02-packaging/README.md` § 10 and Gate, `fronts.md`, `overview.md`, and two `status.md` rows); those go when step 2 closes

### Step 7 — jhonstart-link and erika-test

`04-jhonstart/modules.md` § 1 cuts front 27's render-time half into `jhonstart-link`: `link.bp`,
`reconcile.bp`, `link_test.bp` and `reconcile_test.bp` live in `modules/jhonstart-link/`, importing
`from "jhonstart"` (`reconcile.bp` keeps its sibling import of `link`). The member declares no
`targets` — the code is pure, so both rows; the four `#[@External.Node]` cells front 68 brings reopen
`modules.md` § 4's question. erika's `<lib>-test` member `modules/erika-test/` exists empty.

**Acceptance:**
- [x] `import { Link } from "jhonstart-link";` resolves; the core lists neither `link` nor `reconcile`; nothing outside the member names `linkProps`, `layoutKey`, `sharedDepth`, `prefetchMode` or `linkStatusOf`
- [x] the moved suites keep their counts: `jhonstart` 85/85 and `jhonstart-link` 35/35, each on commonJS and erlang
- [x] `import { … } from "erika-test";` resolves (one inline test, 1/1 on both rows); `erika` stays 31/31
- [x] `repository/jhonstart/AGENTS.md`, `repository/erika/AGENTS.md`, each README and CHANGELOG reflect the tree

## Gate

- [x] each library's pre-commit gate (`botopink test` per member, every example built) green on the branch commits
- [x] `botopink-lib-test` over the branches: green
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
  only as the archived, tagged repository, its surface in std's `testing.mocks` and `testing.asserts`.
- `zig build test-libs` in the main checkout lists every member on every target it declares, green or
  named in `scripts/known-red-libs.txt` with its owning front.
