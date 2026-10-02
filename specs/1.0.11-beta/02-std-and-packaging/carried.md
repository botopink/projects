# Carried — `01-std` and `02-packaging` (1.0.10-beta) → track 02 (1.0.11-beta)

One row per 1.0.10 front or step; the items it still owed; where each went. **Closed on tick**
means the box was already true on disk when 1.0.10 was frozen (measured, not remembered); it is
ticked in the record and not carried. **Closed on confirmation** means it closes when the
maintainer confirms the lettered choice named in [`README.md`](./README.md) § Maintainer decisions.

| 1.0.10 front / step | 1.0.11-beta front | Carried | Closed on tick · on confirmation · handed |
|---|---|---|---|
| `01-std` step 3 — `testing.snapshots` | — | — | last box (`*.snap.new` guard in rakun, jhonstart, emilia, onze) → **00-gate** (STD-1, plus erika) |
| `01-std` step 4 — the old onze migrated | — | — | box 3 (`04-rakun/19-rakun-test-utilities/examples/controller-test-example.bp:24` imports `from "onze"`) → the `04-rakun` track's spec copy, not this one (STD-2); box 5 (`grep 'from "onze"'`) closes with it |
| `01-std` step 5 — the old-name → `onze` takeover | — | — | all four boxes → closed on confirmation of **95-f** (the tree is the orchestrator; `.gitmodules` one entry; no file of this milestone spells the old draft name) |
| `01-std` step 6 — the std sub-fronts' DoD | — | — | `02-std-async-primitives` and `03-std-content-hash` landed; `01-std-lib-enablement` step 14 → **97** (STD-3 re-measured: the JSON copies were not gone, see 97 § Current state) |
| `01-std` step 8 — routing imported by rakun and jhonstart | — | — | closed on tick: `rakun-app/src/file_router.bp` and `jhonstart/src/router.bp` import `from "routing"`; no matcher copy under `repository/` |
| `01-std` step 9 — actions and validation | — | — | closed on tick: `refreshValue` imported at `rakun-app/src/actions.bp:50` and `jhonstart/src/router.bp:24`; the `state` literal lives in `libs/actions/test/` only (the literal `"refresh"` at `rakun-app/test/actions_test.bp:365` is rakun front 24's row) |
| `01-std` Gate (7 boxes) | — | — | → **00-gate** (STD-4) |
| `01-std/01-std-lib-enablement` step 14 — the copies are deletable | **97** | S2 (`Json` accessors), S1 (`parseInt`), the consumer sweep | — |
| `01-std/02-std-async-primitives` — README specifies thunk-shaped `allOf` | — | — | closed on confirmation of **24-g**; the example's marker (`parallel-fetch-example.bp:31`) → **00-gate** (STD-10) |
| `01-std/04-routing-lib` step 2 box 6 — the compiler-suite bundled test | — | — | closed on confirmation of **01std-a** (STD-7); the library's extension (`conventions`, `segment` helpers) is `03-bundled-libs` |
| `01-std/04-routing-lib` step 8 box 1 — `middleware_test.bp` literals | — | — | closed on confirmation of **01std-c** (STD-8) |
| `01-std/06-validation-lib` step 2 box 2 — `diff` against `rakun-validation` | — | — | closed on tick with a note: `modules/rakun-validation/` no longer exists, so the diff cannot be run; the 54 tests moved with the bodies (STD-9) |
| `01-std/test-snap.md` — ~40 `.snap` (4 exist) | **97** step 7 | conditional on **01std-f** (recommendation: retire) | — |
| `01-std/snapshots.md` § The API · § How a library exposes helpers | **98** (`test-helpers.md`) | the contract 98 checks every `-test` member against | — |
| `01-std/examples/emilia-test-{submodule,consumer}-example.bp` | `06-emilia/33-emilia-color-palette/examples/` | the worked example of an `emilia-test` helper | — |
| `01-std` § Not in this front (lifecycle hooks, `isOkAnd`, `throwsType`, `typeOf`, `@Decl` location) | — | — | rows for this milestone's `language-gaps.md` (STD-10) → **00-gate** lists them; lg2-g / lg2-h / lg2-q are the ids |
| `01-std` — compiler rows (`io.process` shadows Node `process`; non-ASCII literal on erlang) | — | — | compiler rows (STD-11), listed under **Handed to 00-gate** so the milestone's `language-gaps.md` carries them |
| `02-packaging` step 2 — `rakun-web` resolves; every member lists `files`; no `../../` path | — | — | closed on tick: 49 members with `files`, no `path: "../../"` (measured by the 1.0.10 audit) |
| `02-packaging` step 2 — every `-test` resolves with one inline test | — | — | closed on tick: jhonstart, emilia, rakun, erika, and onze (`modules/onze-test/`, 7 tests) |
| `02-packaging` step 2 — moved suites green at their new paths | — | — | closed on tick (`html_test.bp` in `jhonstart-html/test/`, emilia inline tests, rakun's suites — the 1.0.10 counts) |
| `02-packaging` step 3 — `README.md` per example | library tracks (`05` front 26, `06` front 33, `07` fronts 50 · 53) + **98** (erika-linq; the check) | PK-2: 15 emilia, 8 jhonstart, 2 onze, 1 erika, 3 rakun (the `04-rakun` track's) | — |
| `02-packaging` step 3 — `emilia-card` prints what it printed | `06-emilia/33` | superseded by EM-7 (decision 114 changes what it prints) | — |
| `02-packaging` step 3 — no example `git` dependency on an ecosystem library | — | — | closed on tick (`emilia-card` → jhonstart by `path`); `botopink-lang/examples/generic-loader-binding/botopink.json`'s git dependency on erika is a compiler fixture for the `git` form, outside the rule |
| `02-packaging` step 4 — `<lib>-test` filled | library tracks (`06` front 33 for emilia; `04-rakun` for rakun) + **98** (erika; the check) | PK-4 | jhonstart's and onze's exist (closed on tick for those two) |
| `02-packaging` Gate — `format --check` clean | — | — | → **00-gate** (PK-5) |
| `02-packaging` Gate — one worktree per repository, seven remotes unified | — | — | → **00-gate** |
| `02-packaging` § 10 / `95` step 6 — the old draft name in the specs | — | — | closed by construction: no 1.0.11-beta file names it (PK-6); the 1.0.10 record keeps its lines |
| `95` step 2 — the takeover (maintainer's items 1–3, the workspace, the ledger lines) | **98** (as a confirmation) | 95-f | items 1–2 (tag, archive) amended by 95-f; item 4 (the workspace) closed on tick; the ledger lines → **00-gate** (PK-1) |
| `95` step 5 last box — no rakun member lists `commonJS` | — | — | closed on tick (rakun front 04: every member `["erlang"]`) |
| `95` Gate — branches merged, submodule bumps, `test-libs` green | — | — | → **00-gate** |
| lg2-v — a subdirectory in a git dependency (PK-7) | **98** step 4 | conditional on the answer; recommendation (1) makes it a no-op | blocks rakun front 73 (the `04-rakun` track) |
| 95-a … 95-e (PK-8) | — | — | closed on confirmation (README § To confirm) |
