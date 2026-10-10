# AGENTS.md

Guidance for AI agents working in the botopink meta repository.

This repository holds no source code of its own. It pins the compiler and the
libraries as submodules under `repository/` and keeps the planning documents
(`specs/`, `todo.md`). Code guidance lives next to the code: start at
[`repository/botopink-lang/AGENTS.md`](repository/botopink-lang/AGENTS.md) and read the
closest `AGENTS.md` in each directory you touch.

## Layout

| Path | What |
|---|---|
| `repository/botopink-lang/` | Compiler (`modules/compiler-core`), CLI, language server, lib-test-runner, `libs/std` |
| `repository/{emilia,erika,jhonstart,onze,rakun,actions,http,log,routing,validation,css,styled,snap,json,yaml,markdown,dbcontext}/` | Libraries written in botopink — `actions`, `http`, `log`, `routing` and `validation` left the compiler with their history (decision 326, front 138); `css`, the base for building CSS, and `styled`, the base for building CSS components over it (decision 338, `08-bpp/119` step 1), were born as repositories under the same rule; `snap`, the snapshot engine every `<lib>-test` writes through, leaves std's `testing/snapshots.bp` for a repository of its own (decision 391, `20-snap` step 0); `json` (std's `json.bp` whole — std knows nothing of JSON), `yaml` (one subset into `Json`) and `markdown` (a tree of its own) are the data-format libraries (decision 396, `03-bundled-libs/142`); `dbcontext`, botopink's JPA over erika — entities, the context, repositories — leaves rakun-data's persistence for a repository of its own (decision 398, `04-rakun/143`); `cardume`, decision 296, joins once `botopink/cardume` holds its scaffold |
| `repository/vscode-extension/` | VS Code extension |
| `specs/1.0.12-beta/` | Current milestone — 1.0.11-beta consolidated to current state only (same goals, every open step; history left in 1.0.11-beta). Tracks: `00-gate` (the gate's baseline rules + `114`, the gate's open residue) · `01-compiler` · `02-std-and-packaging` · `03-bundled-libs` (decisions 115–117; `125-validation-zod`) · `04-rakun` (`128` consolidation first; `137` erika's database target) · `05-jhonstart` · `06-emilia` · `07-onze` · `08-bpp` (Astro's feature set; `116` alone edits the toolchain, for the `.bpp` file kind) · `09-cardume` (front `136`: request and client state as atoms, decisions 295–297) · `10-specs` (front `141`: the retired spellings out of the current specs, text only) · `20-snap` (front 135, last: the snapshot maps re-evaluated case by case). Index in `README.md`, the only status in `status.md` (five lanes), ownership, conflict rules, order and § Gate in `fronts.md`, decisions in `decisions-taken.md` (the next free number is stated at its top) and `decisions-pending.md` (open questions, 1.0.10 confirmations, contradictions `ctr-*`). A reference-driven front carries a `surface.md` and an `examples/` directory; new fronts start from `specs/__template.md`; a front keeps its global number |
| `specs/1.0.11-beta/` | Closed milestone (`closure.md`, with the audits that measured it in `closure-audit/`); frozen — consolidated into `specs/1.0.12-beta/` on 2026-10-03 |
| `specs/1.0.10-beta/` | Closed ecosystem milestone (`closure.md`, measured at the close); frozen — every open item moved to `specs/1.0.11-beta/`, and from there to `specs/1.0.12-beta/` |
| `specs/1.0.5-beta/` | Closed compiler milestone (`closure.md`); its open work went to 1.0.10-beta's `00-compiler-carry-over/` and now lives in `specs/1.0.12-beta/01-compiler/` |
| `specs/1.0.0-beta/` … `1.0.4-beta/` | Closed. 1.0.6–1.0.9-beta were absorbed into 1.0.10-beta and deleted (decision 68); the mapping in `specs/1.0.10-beta/unification.md` |
| `.github/workflows/` | The meta repository's CI: `hook-integrity.yml`, one job on push/PR to `feat`/`main` — see § CI |
| `scripts/` | The meta repository's own tools: `worktree-add.sh <name> [<base>]` — opens a task worktree (§ Worktrees); `language-gap-markers.sh` — every `// LANGUAGE GAP` marker in a tracked `.bp` file (the repositories under `repository/`, and this one outside the closed milestones' spec trees) against the `## Marker index` of the milestone's `language-gaps.md`; CI check 5 |
| `todo.md` | Live plan of the task in the current checkout/worktree — git-ignored, never committed |
| `architecture.md` | Comptime evaluation pipeline, current state |
| `CHANGELOG.md` | Release log |

## CI

`.github/workflows/hook-integrity.yml` is the one job of this repository (00-gate, front 114), every check hard, plain bash over a checkout with submodules:

1. every submodule pointer is an ancestor of (or equal to) its remote `feat` — a bump never
   points at an unpushed commit (`git -C repository/<sub> merge-base --is-ancestor HEAD FETCH_HEAD`);
2. every path in § Layout above exists on disk (the first backticked path of each row, `{a,b}`
   expanded; the git-ignored `todo.md` row is excluded);
3. no `*.snap.new`, `*.snap.md.new` or `todo.md` is tracked in this repository or any submodule;
4. the library repositories' pre-commit guards are one text — `scripts/git-hooks/pre-commit` and
   `scripts/git-hooks/lib/runner-standalone.sh` byte-identical across emilia, erika, jhonstart,
   onze, rakun, actions, http, log, routing, validation, css, styled, snap, json, yaml, markdown and dbcontext, each `.gitignore` naming `*.snap.new` and `*.snap.md.new`, no
   `scripts/known-broken-examples.txt`, each `AGENTS.md` naming `git config core.hooksPath
   scripts/git-hooks`;
5. `scripts/language-gap-markers.sh` exits 0 — every `// LANGUAGE GAP` marker has a row in the
   milestone's `language-gaps.md`: each file that holds one is a row of its `## Marker index` with
   the file's marker count and the gap rows it names, and a missing row, a count that differs, a
   named gap row that is gone and a row for a file with no marker each fail the check.

A red check names the repository and the front that owns the fix; nothing here is soft.

## Worktrees

Parallel tasks run in git worktrees of this repository under `.tasks/<name>` (next to
the main checkout), one branch per task (`git worktree list` shows the active ones).
A worktree is opened one way:

```sh
scripts/worktree-add.sh <name> [<base>]   # base defaults to feat
```

It adds `.tasks/<name>` on a new branch `front/<name>` (under the main checkout,
from whichever worktree it runs), runs `git submodule update --init --recursive`
there, sets `core.hooksPath scripts/git-hooks` in every submodule that tracks
`scripts/git-hooks/pre-commit`, and puts `repository/botopink-lang` on a branch
`front/<name>`. The hooks step is the reason the script exists: a submodule of a
worktree is a repository of its own, so nothing configured in the main checkout's
submodules reaches it, and without the step a commit there runs no gate at all.

Inside a worktree, edit files under that worktree's path only — never the main
checkout. Work in `repository/botopink-lang` on the branch the script created (a
library on a branch of the same name, when the task commits there). Commit in the
submodule first, then commit the submodule bump in the meta repo.

### Which model a thread runs on

A coordinator that spawns a thread (a sub-agent working in its own worktree) picks
its agent and its model with one rule: **the cheapest that can make every decision the
thread will meet, one tier up when a wrong decision would slip past the checks.** Ask in
order:

1. **Agent type.** Only reads and reports (find where, measure, audit) → `Explore`;
   writes a plan and nothing else → `Plan`; edits or runs anything → `general-purpose`.
2. **What it must decide.** Something no decision or README fixes — a design, a reading
   of two decisions against each other, whether to raise a question → `opus`. The
   prompt and the specs fix every choice, only the code is unknown → `sonnet`. No
   choice at all, the steps are a script → `haiku`.
3. **What checks it.** The result is judged by an oracle that cannot be fooled — a
   cell red on the parent and green after, the cold gate, a library's hooks, a byte
   comparison — keep the tier from step 2. What it gets wrong would pass every check
   (a semantic rule, a decision's wording, every backend and every library at once) →
   one tier up (`haiku` → `sonnet` → `opus` → `fable`).
4. **On failure.** A thread that fails, or reports a judgement it was not asked to make,
   is redone one tier up — never the same model twice on the same work. `fable` only
   when the maintainer asks for it or `opus` failed on the work once.

Applied to the threads this workflow opens:

| Thread | Model |
|---|---|
| A compiler front that designs or changes semantics — checker, comptime, contexts, decorators, a decision's first build, a codemod tied to a new rule | `opus` |
| A rule that reaches every backend and every library at once, when the maintainer asks for it or `opus` failed on it once | `fable` |
| Batch integration and the cold gate — apply patches with `-3`, resolve conflicts keeping both sides, run `gate.sh --cold` and each library's own `pre-commit` runner, small fixes | `sonnet` |
| A backend bug with a measured repro; a library or std step whose README already fixes the design | `sonnet` |
| Mechanical work — rebasing a patch that applies, re-running a codemod or `regen.sh`, test sweeps, counts, grep audits, doc wording, CI version bumps | `haiku` |

A `sonnet` or `haiku` thread that reports a judgement it was not asked to make (a new
design, a decision, a red that needs a compiler change) has that part redone on
`opus`. Every thread works by patch; the coordinator lands it through the hooks, so a
thread's slip is caught at the landing.

## Build and test

All Zig commands run from `repository/botopink-lang/`:

```sh
zig build          # botopink + botopink-lsp
zig build test     # compiler-core + language-server (~17s)
zig build test-libs / test-backends / test-vscode / test-bpmp
```

- Comptime evaluation spawns a persistent `erl`; `erl`/`erlc` must be on `PATH`.
  CommonJS snapshot tests execute with `node`.
- `zig build test -- --test-filter` is not forwarded in Zig 0.16. To run a subset,
  run the test binary directly (`.zig-cache/o/<hash>/test`; the hash appears after
  `failed command:` in the log).
- `zig build test --test-timeout 20s` names the test that hangs; "test runner failed to
  respond" means nothing is running (e.g. a child process holding the runner's stdio).
- Quick iteration without the suite: `zig-out/bin/botopink build --target erlang --out out`
  in a scratch project.
- Do not `pkill -f <pattern>` in the same command line that contains the pattern — it kills
  the shell itself; kill `beam.smp` by PID.
- Snapshots live in `modules/<package>/snapshots/`; a mismatch writes `<slug>.snap.md.new`
  next to the snapshot. Do not commit `.snap.md.new` files.

## Conventions

- Code, comments, commit messages and compiler docs are in English. Planning documents
  (`todo.md`, `specs/1.0.0-beta/01-test-green/`, `02-type-system.md`, `architecture.md`)
  are in Portuguese — keep each file in its current language.
- Any code or layout change updates the matching `AGENTS.md` in the same commit.
- Specs describe current state and remaining work; do not keep status narratives,
  commit hashes or superseded approaches in them.
