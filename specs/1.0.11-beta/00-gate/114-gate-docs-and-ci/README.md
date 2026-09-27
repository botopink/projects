# Front 114 — gate-docs-and-ci: no `skip` fence, no soft CI row, the meta workflow measured

**Priority:** high — stage 10 is green with 8 of 93 fences unchecked, two of them claims about
refusals that nothing verifies; the compiler's CI has a row that cannot fail; the meta
repository's hook-integrity workflow does not exist at the open.
**Depends on:** none — group D, independent files. `115` measures stage 10 after it.
**Owns:** `scripts/check-docs.sh` · the 9 marker lines of `docs.md` (`:223,235,684,736,773,809,1137,1351,1765`)
and the fence lines immediately after them (a fence language change or a `project` manifest fence —
no prose edit: `docs.md`'s text is `../../01-compiler/08-hygiene`'s) · `.github/workflows/test.yml`
of botopink-lang (the windows row `:44-54,159,178`; the `libs` job comment is 113's) · the meta
repository's `.github/workflows/**` (new) · the snapshot-capture normalisation for windows (the
framework's capture in `modules/compiler-core/src/codegen/tests/helpers.zig` and
`modules/test-scratch/**` — measure where CRLF and separators enter; if it is the emitters, it is
not this front's and the row stays deleted).
**Does not touch:** `docs.md` prose; `README.md`'s one fence (green); the library repositories'
workflows (99–109's); `scripts/gate.sh` (115's).

---

## Problem

```
$ bash scripts/check-docs.sh
  — docs.md:1351  skipped: a call the compiler must REFUSE; compiling it is the opposite of the claim
  — docs.md:1765  skipped: bodies the compiler must REFUSE; compiling them is the opposite of the claim
…
docs: 93 fences — 77 checked, 8 skipped, 0 failed
```

Measured at the open (report A stage 10; `grep -n "docs-check: skip" docs.md`: 9 markers, 8
skipped fences in the run — one marker precedes a fence the extractor does not count as
`botopink`; step 1 re-measures). `check-docs.sh:26` calls `skip` "the only escape".

## Current state

| Marker | Fence | Kind | Answer (gate-e) |
|---|---|---|---|
| `docs.md:223` | `import {of, erika} from "erika";` — a library dependency | real program, unchecked | `project` fence with a manifest fence that declares `erika` (the harness resolves `repository/erika` through `libs.zig`'s roots, the way `test-libs` does) |
| `:235` | `import {match.matchPath, …} from "routing"; … "actions"; … "validation"` | real program, unchecked | `project` fence; the bundled packages resolve by name (`build.zig` `bundled_packages`) — no manifest entry needed; the harness's scratch project gets them |
| `:684` | a table of literal forms | not a module | the fence stops being ```` ```botopink ```` (a table is `text`); no marker |
| `:736` | the two behaviors as `libs/std` declares them | not a module | same, or a `body` fence if it type-checks — measure |
| `:773` | an operator table | not a module | `text` fence |
| `:809` | a layout sample | not a program | `text` fence |
| `:1137` | a grammar | not a module | `text` fence |
| `:1351` | `connect();` with a trailing default — must refuse | a refusal claim | `reject <error-id>` fence: `botopink check` must fail with the named id |
| `:1765` | `fn g() -> @Iterator<i32> { throw "x"; }` and siblings — must refuse | refusal claims | `reject` fence(s), one per named error id (`effect-try-without-fallible-channel`, …) |

CI (`.github/workflows/test.yml`): `windows-2022` `allow_fail: true` (`:51-52`, "CRLF /
path-separator drift"); the row skips `beam export audit` (`:159`) and `test-language` (`:178`)
though it installs OTP (`:75-85`). The meta repository: **no `.github/` directory at the open**
(`ls .github` at the meta root: no such file; `grep -rn hook-integrity` across the checkout,
`.tasks/` excluded: 0; report L confirms) — the "hook-integrity workflow" the track brief names
does not exist, so nothing in CI checks that a submodule bump points at a pushed `feat` commit or
that the layout `AGENTS.md` describes is the one on disk.

Report L's per-repository CI facts this front does *not* own but sequences with: emilia, erika,
jhonstart and rakun CI test the core member only (`--lib <name>`); onze's loop omits `onze-server`
and the examples; examples build only on the commonJS row; rakun's `erlang` rows are soft and its
`beam` rows (and erika's) vacuous — all gate-j, owned by 99, 100, 101, 108, 109. The compiler's
`libs` job (`test.yml:195-246`) runs every library through `zig build test-libs` and is complete;
only its header comment (`:13-23`, the ledger sentences) moves, with 113.

## Mechanism

`check-docs.sh:173-207` dispatches on the directive: none → module, `body` → wrapped in `main`,
`project <name> <path>` → one file of a scratch project, `skip <reason>` → counted and not run.
A `reject` directive is the same extraction with the opposite verdict: `botopink check` must
exit non-zero and its first diagnostic must carry the named error id (the ids `tests/language/reject/*.expect`
already assert; `docs.md` names them in the comments beside the code — `:1351` "expects 2
argument(s), got 0", `:1765` `effect-try-without-fallible-channel`).

## Steps

### Step 1 — `reject` and `project` replace `skip` (gate-e)

`check-docs.sh`: add `<!-- docs-check: reject <error-id> [<error-id>…] -->` — extract as a module
(or `body`, a second word), run `botopink check`, pass only when it fails and every named id
appears; a `reject` that compiles fails the run ("the doc claims a refusal the compiler does not
make"). Delete the `skip` arm (`:203-207`) — an unknown directive already fails (`:32`). `docs.md`:
the nine markers rewritten as the table says; the five non-programs lose the `botopink` fence
language and their marker. The two `project` fences get a manifest fence (`project deps botopink.json`)
declaring `erika` as a path dependency the harness rewrites to the checkout's `repository/erika`
(`--lib-root`, the same roots `libs.zig:88` resolves).

**Acceptance:**
- [ ] `bash scripts/check-docs.sh` → `docs: 93 fences — 93 checked, 0 skipped, 0 failed` (or 88 checked if the five become `text` and the extractor no longer counts them — state which; `0 skipped` either way)
- [ ] `grep -c "docs-check: skip" docs.md README.md` = 0; `grep -c '"skip"\|skip)' scripts/check-docs.sh` = 0
- [ ] a synthetic doc in `scripts/`' own test (`modules/compiler-cli/tests/*.sh` or a `check-docs.sh --self-test`): a `reject` fence that compiles → exit 1; one that refuses with the wrong id → exit 1; the right id → ✓
- [ ] `--list` prints `reject` and `project` for the rewritten fences

### Step 2 — `scripts/AGENTS.md` § check-docs.sh

The directive table (`:330-337`): `reject` added, `skip` gone, the sentence "the only escape"
deleted.

**Acceptance:**
- [ ] `grep -c "only escape" scripts/AGENTS.md` = 0

### Step 3 — the windows row is hard or absent (gate-f)

Measure the drift: run the `test` job's steps on a windows runner (or a local windows checkout) and
list the failing snapshot tests by cause (CRLF in captured stdout; `\` in captured paths). If the
capture can be normalised in the test framework (`helpers.zig`'s RUN LOG capture: normalise line
endings; paths rendered with `/`) without touching an emitter, do it, run every stage the ubuntu
row runs (beam export audit and test-language included — OTP and node install there), and set the
row `allow_fail: false`. If the drift is in the emitters or the row cannot be made hard in this
milestone, **delete the row** and write the gap in `../../status.md` (a soft row is a tolerance; a
missing row is a gap).

**Acceptance:**
- [ ] `grep -c "allow_fail" .github/workflows/test.yml` = 0 (the key is gone; every row is hard by absence of the key), and either the windows row runs every step (`grep -c "matrix.runner != 'windows-2022'"` = 0) or there is no windows row
- [ ] the workflow green on `feat` after the maintainer's push

### Step 4 — the meta repository's workflow

The meta checkout gates nothing in CI today (no `.github/`). Recommendation (report L's, adopted):
the meta CI **is** a front step — one job, `.github/workflows/hook-integrity.yml` at the meta root,
on push/PR to `feat`, checkout with submodules, every check hard:

1. every submodule pointer is an ancestor of (or equal to) its remote `feat` — a bump never points
   at an unpushed commit (`git -C repository/<sub> merge-base --is-ancestor HEAD origin/feat`);
2. every path in the meta `AGENTS.md` § Layout table exists on disk (`repository/<sub>/`, the
   `specs/<version>/` directories it names, `architecture.md`, `CHANGELOG.md`);
3. no `*.snap.new` / `*.snap.md.new` / `todo.md` is tracked in the meta repository or any
   submodule (`git ls-files` of each);
4. the five libraries' `runner-standalone.sh` guard clauses are identical (113 step 5's check, made
   continuous) and each library's `AGENTS.md` names `git config core.hooksPath scripts/git-hooks`;
5. `scripts/language-gap-markers.sh` (113 step 4c) exits 0 — every `// LANGUAGE GAP` marker has a
   row.

**Acceptance:**
- [ ] `.github/workflows/hook-integrity.yml` exists at the meta root; a synthetic tracked `x.snap.new`, a submodule pointer moved to an unpushed commit, and a deleted layout path each fail it (three synthetic runs on a branch)
- [ ] the meta `AGENTS.md` names the workflow and its five checks

## Gate

- [ ] `zig build test-docs` green with `0 skipped`; `zig build test` green (a `check-docs.sh` self-test, if written as a CLI contract, under `test-cli`)
- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] `scripts/AGENTS.md`, the meta `AGENTS.md` updated in the same commit
- [ ] commits on `fix/gate-docs-and-ci` in `repository/botopink-lang` and `front/gate-docs-and-ci` in the meta repository; no push, no merge

## Blast radius

- `../../01-compiler/08-hygiene` owns `docs.md`'s prose (the `@BeamMemory` text, C-18's
  corrections): this front changes fence languages and marker lines only, and lands first; 08
  rebases.
- `../../01-compiler/18-comptime-runtimes` "CI matrix run test.yml (ubuntu/macos/windows)" is
  the same file: its rows are the maintainer's after the push; this front's edit is the windows
  row only.
- 99–109's workflows are theirs; this front's windows normalisation, if it lands, lets their
  windows rows stay hard (they are hard today).
