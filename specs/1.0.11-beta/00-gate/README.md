# Track 00 — the gate: 100 % green, in every repository, with zero tolerated reds

**Priority:** critical — the maintainer's first priority for this milestone: *the gate passes 100 %
for every library and everything inside every repository — zero tolerated reds* — and the work is
cut so that each part is fixed in a different worktree, in parallel.
**Depends on:** nothing. Every other track of `1.0.11-beta` depends on this one (their READMEs say
"`00-gate` green" in *Depends on*; the library fronts of `04-rakun` and `07-onze` start from the
gate fronts that touch their files).

The gate is `repository/botopink-lang/scripts/gate.sh` (stages 1–10, `scripts/gate.sh:10-38`) run
`--cold`, plus each library repository's own `test` workflow and pre-commit hook. Measured at the
milestone's open (report A, run read-only with `--cold` through a copy of `gate.sh` that continues
past a red stage; load 58–68 on 16 CPUs), **eight stages are green and two are red**: stage 8
`zig build test-libs` prints `84 passed, 36 failed, 0 known red, 13 restricted (pinned), 0 skipped,
9 without tests` and refuses the ledger twice more (21 restricted cells with no line, 9 pinned counts
that moved); stage 9 `zig build test-language` prints `1244 passed, 1 expected failures, 1 failed`.
Around the two reds sit the mechanisms that let a red be green: 3 live lines in
`tests/language/expected-failures.txt`; 21 lines in `scripts/restricted-targets.txt`, 3 of them
pinning `0` (a restriction that restricts nothing); 226 `.bp` files in trees `scripts/format-check.sh`
does not walk (`TREES`, `format-check.sh:41-48`) and 1 that cannot be formatted; 11 `.zig` files red
under `zig fmt --check modules` that the gate never sees (stage 1 checks staged files only,
`gate.sh:131-133`); 9 `<!-- docs-check: skip -->` fences, two of them code the compiler must
*refuse* and nothing verifies; `beam` outside `run.sh --target all` (`run.sh:155`) so its 2 expected
failures are exercised by no gate stage; the windows CI row `allow_fail: true`
(`.github/workflows/test.yml:51-52`); and in the libraries' own repositories: rakun's `erlang` CI axis
`allow_fail: true` (`repository/rakun/.github/workflows/test.yml:45,48`) while its `commonJS` axis is
hard — the reverse of decision 113; onze's CI loop that never runs `onze-server` or its examples
(`repository/onze/.github/workflows/test.yml:120`); a pre-commit hook that *warns and skips* the
`.bp` gate when the compiler binary is not found (`scripts/git-hooks/lib/runner-standalone.sh`,
`locateBotopink` miss); a `known-broken-examples.txt` skip list; two rakun cells green only because
they print `SKIPPED`; and no `*.snap.new` guard in any of the five library repositories.

Every one of those is either a red to fix or a tolerance to delete. This track does both, front by
front, by file ownership; the policy questions that decide *how* are `gate-a` … `gate-j` below,
each recommended at its most restrictive reading with no configuration that bypasses it
(decision 67).

## Current state · per repository (report L, measured at the open)

Each repository's *own* gate: its `test` workflow's step (at the open `zig build test-libs -- --lib
<core> --target <t>`; now one `botopink-lib-test --target <t> --strict` over the workspace's
members), its pre-commit hook (`runStandaloneGate` — at the open `botopink test` in every
`modules/*` member on its default target and `botopink build` of every example; now every
workspace member on every declared target, every example built on every declared target,
jhonstart's refusal cases, rakun's grep stage), and for the extension `npm test` / `npm run
compiler-check`. The emilia, erika and jhonstart rows are re-measured after their fronts and the
library-gate repair (2026-10-01, compiler `29cfffc8`); the others are as their fronts left them.

| Repository | Own CI verdict | Cells | Pre-commit | What is wrong besides the reds |
|---|---|---|---|---|
| emilia | **red on GitHub at the landed tip** — 4 of 5 rows: the three commonJS rows fail `zig build install` (`erlc: FileNotFound`), `ubuntu-22.04 · erlang` fails `GLIBC_2.36 not found`, `macos-14 · erlang` passes. Repaired (below), unrun until it is on `feat` | 34/34 (17 members × 2) | 34/34 cells, 30/30 example builds | left: the workflow's first run on `feat` (the landing) |
| erika | **red on GitHub at the landed tip** — the same 4 of 5 rows, the same two causes. Repaired (below), unrun until it is on `feat` | 6/6 (`erika` 31/0, `erika-test` 1/0, `erika-linq` 9/0, each on both targets) | 6/6 cells, 2/2 example builds | left: the workflow's first run on `feat` (the landing) |
| jhonstart | **red on GitHub at the landed tip** — the same 4 of 5 rows, the same two causes. Repaired (below), unrun until it is on `feat` | 29/29 (`jhonstart` 204/0, link 38/0, test 21/0, forms 15/0, emilia 10/0, html 5/0 and the 8 examples on both targets; dom-test 9/0 on commonJS) | 29/29 cells, 16/16 example builds, 3/3 refusals | left: the workflow's first run on `feat` (the landing); `modules/jhonstart-link/src/link.bp` through `botopink format` (`112`) |
| vscode-extension | **green, 100 %** | `npm test` 49/49; `compiler-check` passed (18 primitive types) | n/a | nothing measured red |
| onze | **red, ~89 %** after 100 (was ~29 %) | 15 pass, 2 no-tests, 2 FAIL of 19 (`onze-cli` on both rows — its `targets` line and `onze-og`'s were deleted under gate-d; `onze-server·erlang` green on 99's tree) | stops at the 4th of 8 members (`onze-cli`); `blog` and `scaffold` build on both targets | the five `onze-cli` reds are a checker row (`ambiguous-import-use` on a named import from a spelled module), 99's landing, and a BEAM `enoent` inside `onze build` (100's README § What is left); CI rewritten to the runner's discovery, every row hard, unrun |
| rakun | **green with the pinned compiler** (99) | 25 of 25 modules green under `botopink test` erlang (1,817 tests / 0 failed); 3 / 3 examples build; 8 starters linted | the greps read code and whole identifiers (`codeLines`); a missing compiler and a staged `*.snap.new` fail; no known-broken list | CI: `erlang` × 2 runners (ubuntu-24.04, macos-14 — the repair below), every row hard, no `commonJS` / `beam` row, every member and example through the runner's discovery; the R3 workaround is the seven-name closure import in `rakun-metrics/test/export_test.bp` (row in `language-gaps.md`); PK-5's reformat of `modules/{rakun,rakun-app}` landed (`format --check` exits 0); left: the workflow green on `feat` (the landing step) and the meta gate's stage 8 read by 113 |
| meta | **no CI** | — | — | no `.github/` directory: the hook-integrity workflow does not exist |

**The five library gates, as repaired.** The fronts above marked each library's own gate done on a
local measurement; on GitHub three of them were red at their landed tips and the other two had
never run, and the pre-commit runner had drifted into three texts. What holds now, measured
2026-10-01 with the compiler built from botopink-lang `29cfffc8`:

- **One hook text.** `scripts/git-hooks/pre-commit` and `scripts/git-hooks/lib/runner-standalone.sh`
  are byte-identical in emilia, erika, jhonstart, onze and rakun (the meta `hook-integrity` check 4
  exits 0 over the five trees). Stages: staged files (no `*.snap.new` / `*.snap.md.new`, no
  conflict marker) · the compiler (absent, or a `BOTOPINK_BIN` that is not an executable →
  refused) · the repository's own stages · `botopink test --target <t>` in every workspace member
  on every target its manifest declares · `botopink build --target <t>` of every example on every
  declared target · every `refusals/*/` case. No flag, variable or list skips a stage; the last
  three all run and every red is listed. Before, emilia, erika and jhonstart ran each member on
  its manifest's default `target` only — no erlang cell under a green pre-commit.
- **One extension point.** `scripts/git-hooks/repository-stages.sh` (rakun's front 22/23 greps are
  the only one) runs in a child process whose exit status is all the runner reads: it can add a
  red, it cannot remove or skip a shared stage.
- **One workflow shape.** Rows = the manifests' targets × {`ubuntu-24.04`, `macos-14`}, every row
  hard; Erlang/OTP 28 on every row (building the compiler runs `erlc` — the commonJS rows had
  none); one `botopink-lib-test --target <t> --strict` from a scratch directory with
  `BOTOPINK_LIB_ROOTS` naming the repository, so a workflow's rows are its own workspace's members
  and a sibling library's red is not its red; then the hook's other stages from the hook's runner.
- **What it rests on that is the compiler's.** `build.zig:745` pins the bundled glibc at 2.38; the
  compiler links libc, Zig's std then calls `arc4random_buf` (glibc ≥ 2.36), and `ubuntu-22.04`
  ships 2.35 — nothing built from botopink-lang starts there (`version 'GLIBC_2.36' not found`),
  botopink-lang's own `ubuntu-22.04` row included. The library rows run on `ubuntu-24.04`, which
  works with the pin as it is and with a lower one; the compiler's row needs a pin ≤ 2.35 at that
  line, or `ubuntu-24.04` (owner: `114` / `../01-compiler/`). No library has a windows row until the
  compiler's returns (gate-f).

Report L's R3 is the one compiler row this track hands *out*: `rakun-metrics/src/export.bp` imports
`RestClient` from `rakun-client`; at the import site the checker re-checks `RestClient`'s
declaration and cannot resolve its field type `cacheLife: CacheLife`, and the diagnostic is
mislocated to `test/export_test.bp:137` (past that 122-line file; really
`rakun-client/src/client.bp:137`). Owner: `../01-compiler/01-checker` (imported-type closure +
diagnostic file attribution); 99 applies the library workaround (import `CacheLife` in the
`rakun-metrics` module) and files the row.

| Document | Holds |
|---|---|
| [`carried.md`](./carried.md) | every report-A chunk (C1–C9) and every other track's *Handed to 00-gate* item, mapped to the front that owns it |
| `NN-gate-<name>/README.md` | the eleven fronts, template shape |

## The fronts

Global front numbers are identifiers and are never reassigned: 97 and 98 (std dedupe, packaging
tail) and 102–107 (bundled libraries) are taken by other tracks; this track uses **99, 100, 101 and
108–115**.

| Front | Priority | Owns (repository · files) | Parallel group |
|---|---|---|---|
| [`99-gate-rakun/`](./99-gate-rakun/README.md) | critical | `repository/rakun/**` — the 42 `(if …)` operand sites, the 2 `-> any`, `starters/rakun-starter-test/botopink.json`, the websocket runtime red, the 2 `SKIPPED` cells, `.github/workflows/test.yml`, `.gitignore` + `scripts/git-hooks/**`, the PK-5 reformat of `modules/{rakun,rakun-app}` | A |
| [`100-gate-onze/`](./100-gate-onze/README.md) | critical | `repository/onze/**` — the 23 `(if …)` sites and their cascades, `.github/workflows/test.yml`, `.gitignore` + `scripts/git-hooks/**` | A |
| [`101-gate-jhonstart/`](./101-gate-jhonstart/README.md) | high | `repository/jhonstart/**` — `examples/{jhonstart-counter,jhonstart-todo}/botopink.json` (`targets`), `modules/jhonstart-dom-test/**`, `.github/workflows/test.yml`, `.gitignore` + `scripts/git-hooks/**`, the PK-5 reformat of `modules/{jhonstart,jhonstart-link}` | A |
| [`108-gate-erika/`](./108-gate-erika/README.md) | medium | `repository/erika/**` — `examples/erika-linq/botopink.json` (`targets`), `.github/workflows/test.yml`, `.gitignore` + `scripts/git-hooks/**` | A |
| [`109-gate-emilia/`](./109-gate-emilia/README.md) | medium | `repository/emilia/**` — `.gitignore` + `scripts/git-hooks/**`, `scripts/known-broken-examples.txt`, `.github/workflows/test.yml` | A |
| [`110-gate-wasm/`](./110-gate-wasm/README.md) | critical | `modules/compiler-core/src/codegen/wat.zig` (the link loop, the 18 silent-degradation sites, `collectHostBound`) · `modules/compiler-core/snapshots/codegen/wasm/**` · `libs/std/src/testing/asserts.bp` (the ck-host restructure) · the one `wasm \|` line of `tests/language/expected-failures.txt` | A |
| [`112-gate-format/`](./112-gate-format/README.md) | high | `scripts/format-check.sh` · `modules/compiler-cli/src/cli/format_cmd.zig` (the structural exemption) · the 11 `zig fmt` files · `libs/std/src/**` (reformat only), `examples/{generic-loader-binding,stdlib-tour}/**`, `modules/compiler-cli/tests/**/*.bp`, `tests/language/{test,run,modules}/**/*.bp` (reformat only) · stage 1 of `scripts/gate.sh` (`zig fmt --check modules`) | A |
| [`111-gate-beam-and-targets/`](./111-gate-beam-and-targets/README.md) | critical | `modules/compiler-cli/src/cli/{build,run,test_cmd,libs}.zig` (beam sidecar shipping) · `modules/compiler-core/src/codegen/beam_asm.zig` and `codegen/beam/**` (the `__bp_load_siblings` twin) · `tests/language/run.sh` · `tests/language/expected-failures.txt` (deleted) · the 17 `run/*.targets` and every `modules/*/botopink.json` `targets` · `tests/language/AGENTS.md` | B — after 110 and 112 |
| [`113-gate-ledger-and-scripts/`](./113-gate-ledger-and-scripts/README.md) | critical | `scripts/restricted-targets.txt` (deleted), `scripts/known-red-libs.txt` (deleted), `scripts/test-libs.sh`, `modules/lib-test-runner/**` (the manifest rule and the restriction audit), `scripts/AGENTS.md`; verifies the five repositories' `*.snap.new` guards | C — after 99, 100, 101, 108, 109 |
| [`114-gate-docs-and-ci/`](./114-gate-docs-and-ci/README.md) | high | `scripts/check-docs.sh` (a `reject` fence kind), the 9 marker lines of `docs.md`, `.github/workflows/test.yml` of botopink-lang (the windows row), the meta repository's `.github/workflows/` (the `hook-integrity` workflow — measured absent at the open) | D — any time |
| [`115-gate-perf/`](./115-gate-perf/README.md) | high | `scripts/gate.sh`, `scripts/test-libs.sh`, `tests/language/run.sh` (after 111), `modules/compiler-cli/src/cli/libs.zig` (the dependency-closure cache), `modules/lib-test-runner/**` (after 113), the meta `scripts/` | E — after every other front |

## Order

```
99-rakun ──┐
100-onze ──┤  (group A: seven worktrees, no shared file — the library repositories are
101-jhon ──┤   disjoint; 110 owns wat.zig + wasm snapshots + asserts.bp; 112 owns the
108-erika ─┤   formatter side and only *reformats* the trees it touches)
109-emilia ┤
110-wasm ──┼──► 111-beam-and-targets   (group B: run.sh + expected-failures.txt deleted;
112-format ┘                             starts from 110's and 112's landings)
     │
     └──► 113-ledger-and-scripts        (group C: counts depend on the five library fronts)

114-docs-and-ci                         (group D: independent files; any time)

115-gate-perf                           (group E: last — it optimises a green gate)
```

Why group A is first: nothing later can be *verified* before it. `113` cannot state the number of
cells the manifests declare until rakun and onze compile; `111` cannot delete
`expected-failures.txt` while `110`'s wasm line is live; `115` cannot budget a gate that is red
(a red `test-libs` cell costs the whole dependency closure compile and then fails — its time is not
the gate's time). Group A's fronts share no file: the five library fronts each own one repository;
`110` and `112` split the compiler by file (`wat.zig` and wasm snapshots vs. `format-check.sh`,
`format_cmd.zig` and reformat-only commits). `112`'s `libs/std` reformat and `110`'s `asserts.bp`
edit are the one near-miss: `112` reformats `asserts.bp` as it stands at the open; `110` rebases
its restructure over the reformat (a formatter commit rebases in one step).

## Exit gate of the track

The track is done when every line below prints what it says, in the main checkout, from a cold
runtime cache, with every sibling library at its `feat` tip. Numbers are the milestone's open;
a front that adds cells re-derives the number in its own README and here.

```
$ cd repository/botopink-lang
$ scripts/gate.sh --cold
…
gate: every stage passed                        # exit 0; ten stages, each printed green

$ zig build test-libs
test-libs: <N> passed, 0 failed, <M> without tests, <A> restrictions audited
                                                # no "known red", no "restricted", no "skipped"
                                                # column: the two files are gone (gate-a, 113) and
                                                # an excluded target is not a cell. N + M is the
                                                # number of cells the manifests declare (`zig build
                                                # test-libs -- --list`, the `cell:*` lines) and A
                                                # the excluded (member, target) pairs, each audited
                                                # structural (gate-d). Measured by 113 on the five
                                                # landed library tips: 134 cells (N = 119, M = 15)
                                                # and A = 38; "<X> restrictions not structural" is
                                                # appended only when X > 0, and fails the run

$ bash tests/language/run.sh --target all       # all = commonJS erlang wasm beam (111)
language tests: <X> passed, 0 expected failures, 0 failed
                                                # X = 1246 + 384 = 1630 at the open's cell count;
                                                # expected-failures.txt does not exist (gate-b)

$ bash scripts/format-check.sh                  # every tree ✓, including libs/std,
  ✓ examples/modules … ✓ tests/language …        # examples/generic-loader-binding, examples/stdlib-tour,
                                                # modules/compiler-cli/tests, tests/language (112)
$ zig fmt --check modules; echo $?
0                                               # no file listed

$ bash scripts/check-docs.sh
docs: 94 fences — 94 checked, 0 skipped, 0 failed   # (114): 9 skips → 7 reject/project fences,
                                                     # 2 tables/grammars are no longer ```botopink

$ time scripts/gate.sh --cold                   # (115): every stage's wall clock and CPU-s printed,
gate: every stage passed — <w> wall, <c> CPU-s (budget 10m00s cold)
                                                # w ≤ 10 min cold / 5 min warm on 16 idle cores
                                                # (`budget_cold` / `budget_warm`); stages 8–10 held
                                                # to their `--list` plans
```

For each repository's own CI (fronts 99, 100, 101, 108, 109, 114):

```
repository/<lib>/.github/workflows/test.yml     every matrix row `allow_fail: false`; the rows are
                                                exactly the targets the workspace's manifests declare
                                                (rakun: erlang only, decision 113); every member
                                                and every example is a row of the loop (onze:
                                                onze-server and the three examples join); a `beam`
                                                row exists only where a cell actually runs there
(cd repository/<lib> && scripts/git-hooks/pre-commit)
                                                refuses when the compiler binary is absent (never
                                                "skipping .bp gate"); refuses a staged *.snap.new;
                                                no scripts/known-broken-examples.txt
repository/vscode-extension                     `npm test` and `npm run compiler-check` green
meta .github/workflows/hook-integrity.yml       exists (114 step 4 — measured at the open: no
                                                `.github/` directory at the meta root); one job:
                                                every submodule pointer is on its remote `feat`,
                                                every path in the meta AGENTS.md layout table
                                                exists, no tracked *.snap.new / todo.md, the five
                                                libraries' hook guard clauses identical
```

## Decisions for the maintainer

Each in the `decisions-pending.md` shape. The recommendation is always the most restrictive option,
with no configuration that bypasses it (decision 67). The letters are this track's; they move to
`../decisions-taken.md` with the next free number (146 upward) when answered.

### gate-a · The restricted-targets ledger: a pinned count is a tolerated red

**Raised by:** this track, for `113-gate-ledger-and-scripts` (and `04-rakun`'s 03r-ah, which asks
the same from rakun's side).
**Measured.** `scripts/restricted-targets.txt` holds 21 lines (`:53-82`), each pinning the *failed*
count of a cell a member's `"targets"` excludes; `scripts/test-libs.sh:326` always passes
`--include-unsupported`, so every restricted cell runs and its count is compared (`:238-272`). At
the open the ledger is wrong in both directions: 21 restricted cells have no line and 9 pinned counts
moved (`libs.txt:12342-12343`). Three lines pin `0` — `erika-linq erlang`, `jhonstart-counter
erlang`, `jhonstart-todo erlang` (`:53,54,58`) — the cell passes and the restriction restricts
nothing. Every rakun line is `commonJS` (`:65-82`): a row rakun does not have by decision 113.
`jhonstart-dom-test erlang 1` (`:55`) is red by construction (no DOM on the BEAM,
`modules/jhonstart-dom-test/src/root.bp:30`).
**Options.** (a) keep the ledger: complete the 21 lines, re-pin the 9 counts, delete the 3 zero
lines; a pinned red stays a red the gate tolerates by number. (b) the manifest is the single source
of truth: `test-libs` runs a member on the targets its manifest declares and on no other, so a cell
that exists must be green; the ledger file is deleted, and with it `--include-unsupported`; a
restriction is audited structurally (gate-d) so it cannot hide a red. (c) as (b) but the ledger
stays as documentation.
**Recommendation.** (b). A ledger line for a row a library does not have is a tolerated red by
another name, and 30 of its 21+21 cells would be rakun `commonJS` — rows decision 113 says do not
exist. The compiler knows no library; it reads the manifest. What the ledger bought — "a restriction
cannot enter silently" — gate-d buys without a count: a restriction is refused unless the excluded
target is one the member structurally cannot run on.
**Blocks.** `113` steps 1–3; the `test-libs` line of the exit gate; rakun's and onze's own CI
matrices (99, 100).

### gate-b · `expected-failures.txt` reaches zero lines and is deleted

**Raised by:** this track, for `110-gate-wasm` and `111-gate-beam-and-targets`.
**Measured.** 3 live lines (`tests/language/expected-failures.txt:236,237,243`): two `beam |
modules/…` (the beam build ships no erlang host sidecar; exercised only by `run.sh --target beam`,
which no gate stage runs — `lang_beam.txt`: `382 passed, 2 expected failures, 0 failed`) and one
`wasm | run/external_wrapper_keeps_refusal.bp` (open question ck-host). The file's own header
(`:68-100`) already says a number kept by hand drifts.
**Options.** (a) the file stays as the mechanism, empty, for the next red. (b) the two beam lines
close with 111 and the wasm line with 110; the file is deleted and `run.sh` no longer reads one: a
red language cell is red. (c) the lines stay until each owner's 1.0.11 sub-front lands.
**Recommendation.** (b). An empty expected-failures file is an invitation; a red cell that must be
tolerated is a decision to delete the cell, not a line. `run.sh`'s parser of the file (the tally
line, the three key shapes) goes with it.
**Blocks.** `111` step 4; the `run.sh` line of the exit gate.

### gate-c · The deliberately unlexable fixture meets `format --check`: a structural exemption, never a skip list

**Raised by:** this track, for `112-gate-format`.
**Measured.** `tests/language/modules/lexer_error_in_imported_module/src/pattern.bp:3` is a bad
string escape on purpose (the cell's four `.expect` files name `bad string escape` at
`src/pattern.bp:3:2`); `botopink format --check tests/language` cannot format it, so the tree cannot
join `TREES`. `format_cmd.zig:15-18,123-128` already leaves out one fixture shape structurally: a
`reject/<n>.bp` beside its `<n>.expect`.
**Options.** (a) a skip list in `format-check.sh` naming the file. (b) the same structural rule
extended one step: a `.bp` under a `modules/<cell>/` whose `<target>.expect` files name a lexer or
parser error *at that file* is the fixture working, and `format --check` leaves it out the way it
leaves out `reject/`. (c) move the fixture so it is a `reject/` pair.
**Recommendation.** (b) — it is (c)'s rule generalised to a project cell, decided by the cell's own
evidence (`.expect`) and not by a list; decision 67 forbids (a). The rule is asserted by a
`format_cmd.zig` test with a synthetic cell.
**Blocks.** `112` step 3.

### gate-d · A `.targets` narrowing and a manifest `targets` list are honoured everywhere, and audited

**Raised by:** this track, for `111-gate-beam-and-targets` and `113-gate-ledger-and-scripts`.
**Measured.** `run.sh:416-425` honours `run/<name>.targets` (17 files) and `run.sh:426-434` ignores
a `modules/` cell's manifest `targets` (`modules/import_same_name_from_two_packages/botopink.json`
declares `["commonJS","erlang"]` and the cell ran — and failed — on wasm). Four of the 17 narrow
away wasm for no host reason (`async_block_all_of`, `std_default_fn_in_a_std_module`,
`external_host_record`, `external_method_on_host_record` — the last two do have a host binding).
In the libraries, `"targets"` is honoured by the runner only without `--include-unsupported`
(`lib-test-runner/src/discovery.zig:307`).
**Options.** (a) honour both everywhere (manifest and `.targets`), no audit. (b) honour both, and
audit: a cell may exclude a target only when `botopink build --target <t>` refuses it with a
*host-binding* error (`has no #[@External.<t>]`, `external_missing`); any other outcome — it builds,
or fails for another reason — is a refusal of the narrowing itself, so a narrowing is never a
hidden compiler gap. (c) delete narrowing; every cell runs on every target.
**Recommendation.** (b). A narrowed cell is one that has a host binding only on those targets;
anything else is a wasm/beam gap that becomes a compiler row (`../01-compiler/`), not a
`.targets` line. (c) is not available while `botopink test` refuses wasm and beam.
**Blocks.** `111` step 5 (the 17 files re-audited, the modules/ rule), `113` step 2 (the runner's
audit), rakun's and jhonstart-dom-test's restrictions (99, 101).

### gate-e · `docs-check: skip` markers become `reject` and `project` fences

**Raised by:** this track, for `114-gate-docs-and-ci`.
**Measured.** 9 markers in `docs.md` (`:223,235,684,736,773,809,1137,1351,1765`; `check-docs.sh:26`
calls `skip` "the only escape"). Two are real programs unchecked (`:223` a library dependency,
`:235` `routing`/`actions`/`validation` imports); two are code the compiler must *refuse*
(`:1351` an arity error, `:1765` effect refusals) and nothing verifies the refusal; five are
tables, a grammar and a layout sample fenced as `botopink`.
**Options.** (a) keep `skip` with a reason. (b) a `reject <error-id>` fence kind that runs
`botopink check` and asserts the named refusal (a fence that compiles fails the run); the two
programs become `project` fences of a scratch project whose manifest declares the dependency the
harness resolves from the checkout (`erika` via `repository/erika`, the bundled packages by name);
the five non-programs lose the `botopink` fence language (a table is not code), so no marker is
needed; `skip` is deleted from `check-docs.sh`. (c) as (b) but `skip` stays for the five.
**Recommendation.** (b). "Skipped" is not "checked": a docs claim about a refusal is a test of the
refusal.
**Blocks.** `114` steps 1–2; the `check-docs.sh` line of the exit gate.

### gate-f · The windows CI row stops being `allow_fail`

**Raised by:** this track, for `114-gate-docs-and-ci`.
**Measured.** `.github/workflows/test.yml:48-52`: `windows-2022` with `allow_fail: true` since
"CRLF / path-separator drift" in snapshot capture; the row also skips `beam export audit` and
`test-language` (`:159,178`) for want of erlc/erl/node. A row whose failure fails nothing is a
row that measures nothing.
**Options.** (a) keep the soft row until the normalisation lands. (b) the row is hard once the
snapshot capture normalises CRLF and path separators, and it runs every stage the ubuntu row runs
(OTP via `erlef/setup-beam` works on windows — the `test` job already installs it there, `:75-85`);
until then the row is *deleted*, not soft. (c) delete the row for good.
**Recommendation.** (b). A soft row is the tolerance; a missing row is an honest gap the milestone's
`status.md` lists. The normalisation is 114's step 3; if it does not land in this milestone the row
stays deleted and the gap is carried.
**Blocks.** `114` step 3.

### gate-g · rc3-a — the `(if …)` operand refusal is confirmed; the libraries migrate

**Raised by:** this track, for `99-gate-rakun` and `100-gate-onze`; the question itself is
`specs/1.0.10-beta/decisions-pending.md` § rc3-a, still open.
**Measured.** The compiler refuses `if` as an operand, parentheses included (`error[if-operand]`,
`parser/tests/effect_rejections.zig:266`, `tests/language/reject/if_in_parentheses`). rakun writes
the form in 42 places and onze in 23 (the lists are in 99 and 100); 244 `if-operand` diagnostics
across the 36 red cells, and nearly every `unbound variable` and `asserts.contains` red is its
cascade (report A § R1).
**Options.** (a) confirm the refusal (rc3-a's option a) and migrate both libraries to
`val x = if (c) { a } else { b };` before the use. (b) re-admit the parenthesised form (rc3-a's b).
(c) re-admit `if` as an operand anywhere (rc3-a's c).
**Recommendation.** (a) — the most restrictive, and the one already implemented and pinned by three
`reject/` cells; (b) would delete cells to make libraries compile. The migration is mechanical and
is what 99 and 100 do first.
**Blocks.** `99` step 1, `100` step 1 — both start on the recommendation and stop only if the
maintainer answers otherwise.

### gate-h · A cell that needs an external service is not a gate cell

**Raised by:** this track, for `99-gate-rakun` (the cells `04-rakun`'s README names).
**Measured.** `repository/rakun/modules/rakun-session/test/store_test.bp:68-71` — "the suite runs on
the Redis arm when `RAKUN_TEST_REDIS_URL` is set": with the variable unset it prints `SKIPPED` and
passes; `rakun-websocket/test/broadcast_test.bp:102` accepts `out.startsWith("skipped: ")` when the
runner cannot start a peer node. Both are green on every gate and assert nothing. `04-rakun` names
the never-written integration suites (`RAKUN_TEST_AMQP_URL`, `RAKUN_TEST_KAFKA_BROKERS`) and
answers them the same way (03r-aa).
**Options.** (a) keep env-gated cells; document the variable. (b) a cell that needs an external
service is deleted from the gate: it is replaced by an in-process double (the RESP double
`04-rakun` 12 specifies; a same-node `pg` broadcast for websocket) so the *behaviour* is asserted
in the gate; the real-driver arm, if wanted, lives behind an explicit `botopink test --integration`
flag that CI runs only in a job that provides the service, and a `--integration` cell that cannot
reach its service **fails** — "skipped" is never "passed". (c) as (b) without the `--integration`
flag: real-driver verification is a `deferred.md` row, no cell.
**Recommendation.** (b) for the two existing cells' behaviour halves (the double is the gate arm),
and (c) for the arm: no `--integration` flag lands in this milestone, because no CI job provides a
service today and a flag with no job is a configuration nobody runs. If the maintainer wants the
flag, it is a `26-cli-tooling` row with a CI job in the same landing.
**Blocks.** `99` step 4.

### gate-i · A library pre-commit hook that cannot find the compiler refuses; `known-broken-examples.txt` is deleted

**Raised by:** this track, for 99, 100, 101, 108, 109.
**Measured.** `repository/<lib>/scripts/git-hooks/lib/runner-standalone.sh` (identical in the five
repositories): when `locateBotopink` misses, the hook prints `⚠ botopink binary not found … —
skipping .bp gate` and returns 0 — a commit with no `.bp` gate at all; `runExamplesGate` reads
`scripts/known-broken-examples.txt` (a skip list with a rot check; the file exists in emilia with
0 lines, in no other repository). None of the five `.gitignore` or hooks names `*.snap.new`
(`grep -c snap.new` = 0 in all five).
**Options.** (a) keep the warn-and-skip. (b) the hook fails when the binary is not found (the
message says how to build it or set `BOTOPINK_BIN`), `known-broken-examples.txt` and its branch
are deleted (an example that does not build fails the gate), and each hook refuses a staged
`*.snap.new` / `*.snap.md.new` the way `gate.sh:135` does, `.gitignore` listing both.
**Recommendation.** (b). Fail beats warn (decision 67, the `restricted-targets.txt` header's own
words).
**Blocks.** the hook step of each library front; `113` step 5 verifies all five.

### gate-j · A library's own CI matrix is the manifests' target set, every row hard

**Raised by:** this track, for 99, 100, 101, 108, 109.
**Measured.** rakun (`.github/workflows/test.yml:44-50`): `commonJS` rows hard on three runners and
`erlang` rows `allow_fail: true` — rakun is erlang-only (decision 113), so the hard rows measure the
restricted matrix and the soft rows are the library; two `beam` rows run `zig build test-libs …
--target beam`, which `botopink test` cannot run, so they print `skipped` and pass. erika
(`:43-49`) has the same two `beam` rows. onze (`:120`) loops over seven members and omits
`onze-server` and the three examples. All five run the examples gate only on the `commonJS` row.
**Options.** (a) leave the matrices; fix the reds. (b) each matrix is derived from the manifests:
one row per (runner × target the workspace's members declare), `allow_fail: false` everywhere, no
row for a target `botopink test` cannot run, the member loop generated from the workspace
(`botopink-lib-test --lib <root>` already discovers members — one call, no hand-written loop).
**Recommendation.** (b). A CI row that cannot fail, or that runs nothing, is a tolerance in the
repository the gate is supposed to cover. Report L adds the coverage half: emilia, erika,
jhonstart and rakun CI test **the core member only** (`--lib <name>`); rakun's other 35 members
run only under its pre-commit — so (b) also means the step runs every member and every example the
workspace declares (the runner discovers them from the root; no hand-written loop), and the
examples gate runs on every row. This is gate-f's principle (a row that measures nothing is not a
row) applied to the libraries.
**Blocks.** the CI step of each library front.

## Blast radius on the other tracks

| Track | What moves when this track lands | What it must do |
|---|---|---|
| `01-compiler` | `expected-failures.txt` is gone (03-beam, 05-wasm no longer delete lines); `wat.zig` (110), `beam_asm.zig` + `cli/**` + `libs.zig` (111), `format_cmd.zig` (112), the 11 `zig fmt` files (112) are edited first; `tests/language` and `libs/std` are reformatted (112); two rows handed *to* it: report L's R3 (an imported type's field type unresolved at the import site, diagnostic attributed to the wrong file — `01-checker`) and the five library `// LANGUAGE GAP` notes 113 lists (`language-gaps.md` rows) | its fronts list these under *Does not touch until 00-gate lands* and start from the gate's landing; a red cell it wants to pin is a decision to delete the cell, never a line |
| `02-std-and-packaging` | `libs/std/src/**` reformatted (112); `asserts.bp` restructured (110); STD-1/EM-6 guards land per repository (99–109) and are verified by 113; PK-1's three onze lines are not written — the ledger is deleted (gate-a) | `97-std-dedupe` rebases over the reformat and the `asserts.bp` restructure; PK-5's reformat is done by 99 and 101 |
| `04-rakun` | 99 rewrites 42 sites across `rakun-data`, `rakun-messaging`, `rakun-app`, `rakun-ws`, `rakun-release`, `rakun-scheduling`, `rakun-devtools`, `rakun-security`, `rakun-web` and their tests; edits `rakun-starter-test/botopink.json`; reformats `modules/{rakun,rakun-app}`; replaces the two `SKIPPED` cells; rewrites the CI matrix | every `04-rakun` front starts from 99's landing (its README says so); 03r-ah is answered by gate-a; 03r-aa by gate-h |
| `05-jhonstart` | 101 drops `targets` from two example manifests, decides the `dom-test` erlang cell, reformats `modules/{jhonstart,jhonstart-link}` | `26-jhonstart-router` and `67-jhonstart-forms` start from 101's landing |
| `06-emilia` | 109 adds the guard and deletes `known-broken-examples.txt` | nothing else moves |
| `07-onze` | 100 rewrites 23 sites across `onze-assets`, `onze-bundler`, `onze-cli`, `onze-og`, `onze-release` and their tests; rewrites the CI loop | every `07-onze` front starts from 100's landing |
| `03-bundled-libs` | none of its files; it depends on "`00-gate` green" | starts after the track's exit gate |

## Rules

- A red cell is fixed or its test is deleted by a decision — never allow-listed, pinned, expected,
  skipped or made soft (decision 67).
- The compiler knows no library: no gate front adds a library name to `compiler-core`, `compiler-cli`
  or `lib-test-runner`; the manifest is what the runner reads.
- rakun is erlang-only (decision 113): no front here proposes a commonJS row, cell or ledger line
  for rakun.
- A front that needs a file it does not own stops and reports it (`../../__template.md` § Working a
  front).
- Every count in a front README says how it was measured and that it was measured at the milestone's
  open; the front re-measures before it ticks a box.
