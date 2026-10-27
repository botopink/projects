# AGENTS.md

Guidance for AI agents working in the botopink meta repository.

This repository holds no source code of its own. It pins the compiler and the
libraries as submodules under `repository/` and keeps `todo.md`; the specs —
the milestone documents and the decisions — live in `botopink/specs-data` and are read and written only through
specs-bot (§ Specs). Code guidance lives next to the code: start at
[`repository/botopink-lang/AGENTS.md`](repository/botopink-lang/AGENTS.md) and read the
closest `AGENTS.md` in each directory you touch.

## Layout

| Path | What |
|---|---|
| `repository/botopink-lang/` | Compiler (`modules/compiler-core`), CLI, language server, `modules/std-wasm` and `modules/beam-to-wasm` (comptime on wasm, decision 434), `libs/std`, and `conformance/` — the language's conformance suite (decisions 457, 466, 475): `modules/<module>/cases/<cell>/` (one module per prefix or per decision, decision 765; B-157 P3 landed 2026-10-19) the root package `conformance/modules/` built once into one `.bpr` and run per target by `conformance/run.sh` (one module alone: `cd conformance/modules/<m> && botopink run --target <t>`; decisions 989, 990 (6), 1002), `test/` suites by `botopink test --json` |
| `repository/{rakun,query,actions,http,log,routing,validation,css,snap,json,yaml,markdown}/` | Libraries written in botopink — `rakun` is a botopink workspace (front 165) of plug-and-play packages under `modules/` (`rakun`, `rakun-data`, `rakun-restclient`, `rakun-style`, `rakun-bpp`, `rakun-stylesheet`, `rakun-service`, … `rakun-ssr`, plus `rakun-ssr-server` (was `onze-server`), `rakun-bpp-dom-test` (was `jhonstart-dom-test`) and `rakun-cli`, decision 762; the two renames land with 165 s5), one version, one gate, its cells under `conformance/<package>/`; it absorbed `emilia`, `styled`, `jhonstart`, `onze` and `dbcontext`, which are no longer repositories of the meta; `query` (erika renamed, a typed-query DSL depending on nothing of rakun; the repository is `botopink/query`); `actions`, `http`, `log`, `routing` and `validation` left the compiler with their history (decision 326, front 138); `css`, the base for building CSS, was born as a repository under the same rule (decision 338, `08-bpp/119` step 1); `snap`, the snapshot engine every `<lib>-test` writes through, leaves std's `testing/snapshots.bp` for a repository of its own (decision 391, `20-snap` step 0); `json` (std's `json.bp` whole — std knows nothing of JSON), `yaml` (one subset into `Json`) and `markdown` (a tree of its own) are the data-format libraries (decision 396, `03-bundled-libs/142`); `cardume`, decision 296, joins once `botopink/cardume` holds its scaffold |
| `repository/vscode-extension/` | VS Code extension |
| `.env` | specs-bot's address (`SPECS_BOT_API_URL`), the same on every machine; each machine's token lives in `.env.local`, ignored by git — see § Specs |
| `.github/workflows/` | The meta repository's CI: `hook-integrity.yml`, one job on push/PR to `feat`/`main` — see § CI |
| `scripts/` | The meta repository's own tools: `gate.sh` — the meta checks (CI's `hook-integrity.yml` calls it) and the machine's gate scheduler, `run <repository\|task>…` · `tasks` · `libs` · `status` (§ Gate orchestrator); `gate-test.sh` — the scheduler's admission test and its release race, in a private pool; `worktree-add.sh [--repo <repo>] <name> [<base>]` (`--lang` = `--repo botopink-lang`) — opens a task worktree; `--repo` one of a single repository, the rest linked from the main checkout (§ Worktrees); `thread-rules.md` — the rules every thread reads first, and its four-line report (decision 484); `stray-loops.sh [--kill]` — the wait loops threads left behind (§ Keeping the threads honest, rule 3); `land-check.ts <repo> <branch> [--base <ref>]` — the coordinator's check before a landing (decision 484): not a fast-forward of `origin/feat`, a tracked `*.snap.new` / `*.snap.md.new` / `todo.md`, in the meta specs a scratch reference or a commit hash or an English/Portuguese pair whose ids or code blocks differ, a `snapshot/targets/` file added; each reason one line, exit 1 when red; `scratch-refs.ts [<path>…]` — every line of the current milestone's specs (or the paths given) that names a scratch location: a concrete `.tasks/…` path, `/tmp/`, a task branch `front/<name>`, a worktree by name; exits 1 when one is found; `language-gap-markers.ts` — every `// LANGUAGE GAP` marker in a tracked `.bp` file (the repositories under `repository/`, and this one; the spec examples' markers are `specs-bot check`'s) against the `## Marker index` of the milestone's `language-gaps.md`; CI check 5; `decisions-split.ts [--check]` (decision 482) — writes `repository/<repo>/decisions-taken.md` from the record, `decisions-taken-steps.md` read through specs-bot (each row to the repositories its Binds column names, old ids through the fronts' alias tables; a row it cannot map is printed to stderr, never guessed); `--check` fails when a file differs; a slug is one row's, except that a row replaced or overtaken hands its cell's slug to the row that replaces it; CI check 6; a repository's commit holding only that file skips the hook (`--no-verify`, the maintainer, 2026-10-15); `decision-cells.ts scaffold [--list] \| compile \| promote <repo> \| check` (front 166) — keeps `conformance/modules/decisions-taken/<slug>-<N>/` (the ledger's `Cell` column, decision 647; a `docs.md` and one example program (a phase-1 draft may carry `draft/botopink.json` and `draft/deps/<pkg>/`, which `compile` stages as the package's manifest and dependencies and `promote` merges into the case's manifest and moves to its `deps/`, decision 775), or its cases — `run/` and `refused/`, two packages of cases, and `cells/<case>/` full cells, decision 779, or 765's `cases/<case>/`; `promote` moves `draft/` to `cells/example/`) for every ledger row that fixes program behaviour; a one-liner (`Replaced by` / `Reversed by` / `Overtaken by`) or a `process` row has none; `check` is CI check 7, tested by `decision-cells.test.ts`; the TypeScript tools run with Bun (`bun scripts/<tool>.ts`, or the file itself), share `lib/compat.ts` (the text, pattern, path and JSON semantics they keep), and `bun test scripts/` runs their tests (`decision-cells.test.ts`, `land-check.test.ts`) |
| `architecture.md` | Comptime evaluation pipeline, current state |
| `CHANGELOG.md` | Release log |


## Specs — through specs-bot

The specs — the milestone documents, `decisions-taken.md`, `decisions-taken-steps.md`, `decisions-pending.md`,
`retired.md` — and the conversation between the machines live in
[`botopink/specs-data`](https://github.com/botopink/specs-data), and are read and written **only through
specs-bot** (the maintainer, 2026-10-25): an api on the host (`SPECS_BOT_API_URL` in `.env`), the `specs-bot` CLI
on each machine, the site at <http://192.168.1.15:7165>. Never read or edit a spec file, clone `specs-data`, or open
its files on GitHub. The bot keeps the conventions — the next free number in step everywhere, an id never reused,
the closed milestones frozen, no commit hash or scratch path in a spec's text (a hash goes in `--landed`, which
keeps it in the commit) — commits each write as the machine that made it, and tells the other machines at once.

- **Through MCP first**: each session gets the `specs-bot` MCP server (`.mcp.json`, `specs-bot mcp`): call its `as`
  tool first with your party (`maintainer`, `machine-1`, …) — the party is the session's, never the folder's, since
  two sessions may share a folder — and it is held for the whole session and let go when the session ends; its tools are the CLI's
  commands (`search`, `doc`, `append`, `claim`, `send`, …, answers in TOON, writes a dry run until `apply: true`),
  and every answer carries the events that arrived since the last call (`wait` blocks for the next one). The CLI
  stays for scripts and for a shell.
- **Setup**: `specs-bot` on the `PATH` (`bun build --compile` of `botopink/specs-bot`'s `packages/cli`); the
  token in `.env.local` (never committed): `SPECS_BOT_TOKEN=…`, or one per party when a machine hosts several
  (`SPECS_BOT_TOKEN_MAINTAINER=…`, `SPECS_BOT_TOKEN_MACHINE_1=…`) with `SPECS_BOT_AS=<party>` picking one — a task
  worktree's own `.env.local` names its party and reads the checkout's tokens; `--as <party>` overrides. `specs-bot
  whoami` names the party.
- **Read**: `specs-bot search <words>` · `step <n>` · `pending [<id>]` · `review --open` · `subject [<slug>]` ·
  `retired [<words>]` · `fronts` · `front <n>` · `doc <ref> --outline`, then `doc <ref> -s <anchor>` (one section,
  with its etag) · `chat --unread <machine>` · `check`. Output is TOON; `-f json` or `-f text` on request.
- **Write** — each command is a dry run that prints the diff; `--apply` writes it: `append <ref> -s <anchor> -t …` ·
  `edit <ref> -s <anchor> -e <etag> -t @section.md` · `add-section` · `new-doc` · `pending-add` · `pending-edit` ·
  `pending-withdraw` · `answer <id> --rule … --binds …` · `supersede` · `retire` · `send --to … --purpose …
  --subject … -t …` · `mark-read <id>`. Long text comes from a file (`-t @file.md`). Exit 6 means the section changed
  since it was read: read it again and redo the edit over it.
- **After `answer` or `supersede`**, regenerate the repositories' ledgers with `bun scripts/decisions-split.ts`
  (it reads the record through specs-bot) and commit them in each repository, as before.
- **Refs** are paths in a flat tree (2026-10-26): `150-rakun/README`, `144-checker/01-compiler/track`, and the
  milestone's own documents under `milestone/` (`milestone/status`, `milestone/language-gaps`, `milestone/machine-1`).
  Every document's metadata is the YAML block at its top (`milestone`, `owner` — the machine that works it —, then
  `priority`, `owns`, `depends-on`, …); `specs-bot meta <ref> --set key=value` changes it. A front of a closed
  milestone is frozen. An old ref (`1.0.12-beta/machine-1/150-rakun/README`) still answers, as its new one.
- **Hearing a message at once** (an idle session hears nothing until it calls a tool): keep one chat watcher
  running as a background Bash command (`run_in_background`) — `specs-bot watch --once --type chat --to <your party>`.
  It costs nothing while it waits and ends at the next message to you (or to all), which wakes the session: read it
  with the MCP `chat` tool, act, `mark_read`, then start the watcher again. One watcher per session; never poll.
- **Saying what you are on** (the site's `/now` page shows it live): whenever you start a piece of work, call the MCP
  `doing` tool with one line and its front (`doing` "983 phase 1: cell check admits the folded layout", front `144`);
  a new line ends the last one as done. When you stop, `done` if it is finished, `done` with `paused: true` if you
  will come back to it (saying the same line again resumes it). `/now` shows running, paused and done (24 h) from
  these lines only; a claim is not enough.

## CI

`.github/workflows/hook-integrity.yml` is the one job of this repository (front 163 meta-ci, `specs-bot front 163`), every check hard, over a checkout with submodules. It calls `scripts/gate.sh check` (plain bash; the same command runs the seven checks locally, every red listed), and the checks are:

1. every submodule pointer is an ancestor of (or equal to) its remote `feat` — a bump never
   points at an unpushed commit (`git -C repository/<sub> merge-base --is-ancestor HEAD FETCH_HEAD`);
2. every path in § Layout above exists on disk (the first backticked path of each row, `{a,b}`
   expanded; the git-ignored `todo.md` row is excluded);
3. no `*.snap.new`, `*.snap.md.new` or `todo.md` is tracked in this repository or any submodule;
4. the library repositories' pre-commit guards are one text — `scripts/git-hooks/pre-commit`,
   `scripts/git-hooks/lib/runner-standalone.sh` and `scripts/gate.sh` byte-identical across rakun, query, actions, http,
   log, routing, validation, css, snap, json, yaml and markdown, each `.gitignore` naming `*.snap.new` and `*.snap.md.new`, no
   `scripts/known-broken-examples.txt`, each `AGENTS.md` naming `git config core.hooksPath
   scripts/git-hooks`, `scripts/gate.sh` and `conformance/`;
5. `scripts/language-gap-markers.ts` exits 0 — every `// LANGUAGE GAP` marker has a row in the
   milestone's `language-gaps.md`: each file that holds one is a row of its `## Marker index` with
   the file's marker count and the gap rows it names, and a missing row, a count that differs, a
   named gap row that is gone and a row for a file with no marker each fail the check.
6. `scripts/decisions-split.ts --check` exits 0 — every `repository/<repo>/decisions-taken.md` is exactly what
   the script writes from the record, `decisions-taken-steps.md` (decisions 482, 730) — read through
   `specs-bot export ledger`, or from `$SPECS_ROOT` in CI (a checkout of `botopink/specs-data`); a repository's file is generated and
   never edited there.
7. `scripts/decision-cells.ts check` exits 0 (front 166) — every `conformance/modules/decisions-taken/<slug>-<N>/` of a
   repository is the `Cell` slug of a code-bearing row of its generated ledger (not a one-liner, not `process`), holds a `docs.md`
   whose first line is the row's, with every `[…](…)` link resolving, no `{path}` placeholder and no fenced code, and
   exactly one of its program (`draft/main.bp`, or `src/main.bp` with `botopink.json` once promoted) under the row's
   generated header, or its cases: `run/` / `refused/` packages (decision 779: `botopink.json`, `src/main.bp`,
   `src/cases/mod.bp`, `snapshot/`, each `src/cases/<case>/` holding `mod.bp`), `cells/<case>/` and 765's `cases/<case>/`,
   each a full cell with `botopink.json`, `src/main.bp` and `snapshot/`; a promoted cell's or a case's `"targets"` within the workspace's; completeness (every code-bearing row has its directory) is
   checked per repository once the script's list names it (every slug has its directory); a row proven by a CLI test script (decision 1020) has a `Cell` value `tests/<name>.sh` instead of a slug and no directory — the script must exist at `modules/compiler-cli/tests/<name>.sh` of the repository, and a `<slug>-<N>/` directory for such a row is red. A red names the repository, the row and front 166.

A red check names the repository and the front that owns the fix; nothing here is soft.

## Gate orchestrator

`scripts/gate.sh` (decisions 468, 469, 473; front 163 s7) is the meta repository's own gate and the
machine's gate scheduler. A repository's gate — a library's `scripts/gate.sh`, botopink-lang's — knows
nothing of it.

```sh
scripts/gate.sh [check]          # the seven checks of § CI, locally
scripts/gate.sh run <target>…    # those gates together under the pool; --no-conformance is handed on
scripts/gate.sh tasks            # every open task's gate (its own repositories)
scripts/gate.sh libs             # every library's gate, on the main checkout's compiler
scripts/gate.sh status           # what runs and what waits: name, jobs, time, current stage
scripts/gate.sh exec [--jobs <N>] <name> -- <command>…   # one command under the pool
```

- **A library's `scripts/gate.sh`** (one text in every library, CI check 4): `[--staged] [--no-conformance]
  [--jobs <N>]`, running the shared `scripts/git-hooks/lib/runner-standalone.sh` — the stages, then
  `botopink cell check conformance/` when the repository has that directory (the libraries keep that until 996 / L5
  moves them to the root-package shape: until then that stage 7 is a known red, and a library commit runs with
  `--no-verify`, decision 1002 (c)). The commit hook runs it with
  `--staged --no-conformance` (470); CI on a push to `feat` and a front's Conformance step run it whole.
  `--jobs` is the total of its cell pools (default the machine's); it keeps no pool and no lock. On a machine whose
  fixed per-machine file (`~/.config/botopink/machine`) reads `machine-1` it adds `--no-conformance` itself and says so
  (decisions 768, 769).
- **A `<target>`** is a repository of the checkout (`repository/<name>/` with a `scripts/gate.sh`), or
  `task:<name>` (a bare name that is no repository also resolves to a task). Tasks are found by
  `git worktree list` of the meta repository and of every submodule of the main checkout: a task is a
  `.tasks/<name>` worktree; its **own** repositories are the checkouts on its branch `front/<name>`, the
  others (symlinks of a `--repo` / `--lang` task, checkouts left on the pointer) are linked siblings and
  are not gated by it.
- **The machine's name** (decisions 768, 769) is one fixed per-machine file, `$XDG_CONFIG_HOME/botopink/machine` (else
  `$HOME/.config/botopink/machine`), holding `machine-1` or `machine-2`. On `machine-1`, `run` / `tasks` / `libs` add
  `--no-conformance` by themselves and `exec` refuses a whole-suite conformance run (`conformance/run.sh` without an `--only` naming a
  `test/` suite or one module, `scripts/gate.sh --stage test-conformance`, `zig build test-conformance`) —
  conformance is machine 2's until the maintainer says otherwise; a module reached by a change is still run alone
  (`cd conformance/modules/<m> && botopink run --target <t>`).
  A machine with no file behaves as before.
- **The pool** is one directory at a fixed per-machine path, `$XDG_RUNTIME_DIR/botopink-gate-pool` (else
  `/tmp/botopink-gate-pool-<uid>`); not a flag or a variable (decision 67). The machine's jobs are the tighter of
  two bounds, read on every pass (decision 674): the CPUs, a job counted as ~2 runnable threads, and the
  memory, one job per 768 MiB of `MemAvailable` above a 2 GiB margin the pool always leaves free —
  `capacity = max(1, min(cpus / 2, (MemAvailable - 2 GiB) / 768 MiB))`; the CPU half is never applied to the
  memory bound, and below the margin no new gate is admitted while one runs (a 16-CPU machine with 5.8 GB
  free: 5 jobs, not 3). `status` prints the memory available and the margin. Each running gate owns a `lease.<id>` file (owner pid, child pid, jobs, name, start, log),
  each waiting one a `wait.<id>`; a `mkdir` lock serialises changes and a lease whose owner and child are
  both dead is reaped. A gate is admitted when at least one job is free and takes `min(share, free)`
  jobs, `share = max(1, capacity / gates of the run)`, returned when it ends; a library receives them as
  `--jobs`. Admission is first come, first served, with one exception (front 163 s13): while the pool is not
  empty, a gate asking for less than the capacity may pass older waiters that all ask for the whole pool, at most
  one such pass in flight; the full-pool gate still starts only on an empty pool. botopink-lang's gate takes no total of jobs yet (it sizes itself to the machine), so a run of
  it holds the whole pool. Measuring a gate's time waits for the pool to be empty (`status`) — that is
  the measurer's rule, not a lock on every gate. The commit hook's gate runs outside the pool (470).
  Every run waits for a free job, `--no-conformance` included (the maintainer, 2026-10-12: the lock
  is held while a gate executes, never skipped — unlocked runs piling up took the machine down).
- **`exec`** runs one command under the pool — a thread's `zig build`, `zig build test`, `botopink cell
  check`, or a library `git commit` and the hook it runs: it waits for a free job, holds `--jobs <N>`
  (default a quarter of the capacity) while the command runs, and gives them back when it ends; the command's
  exit status is its own. A thread runs every heavy command through it, so threads work in parallel and
  only their executions queue. `--jobs` at or above the capacity waits for an empty pool and holds all of
  it: a `git commit` in botopink-lang runs so (`exec --jobs 10 <name> -- git commit …`), its hook's gate
  sizing itself to the machine.
  On `machine-1` `exec` refuses, before taking a job, a command whose text — its arguments, a `bash -c` string, the
  non-comment lines of a script file it names — runs a whole-suite conformance run (`conformance/run.sh` without a narrowing `--only`,
  `gate.sh --stage test-conformance`, `zig build test-conformance`) or a library's `scripts/gate.sh`
  without `--no-conformance` (decisions 768, 769).
- **Logs** are scratch and git-ignored: `.tasks/.gate-logs/` of the main checkout, `.tasks/<name>/.gate-logs/`
  for a task; the report names each one. Specs never name them.
- It runs and reports; landing stays the coordinator's.

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

A task that changes **one repository alone** opens a lighter one — chosen by what the task
changes, never by habit:

```sh
scripts/worktree-add.sh --repo <repo> <name> [<base>]   # base defaults to origin/feat
scripts/worktree-add.sh --lang <name>                   # = --repo botopink-lang
```

It makes `.tasks/<name>/repository/<repo>` a git worktree of the main checkout's
submodule on `front/<name>`, and every other submodule path a symlink to the main
checkout's — no meta branch, no clone. Because `.tasks/<name>` holds `repository/`,
the compiler's library walk-up and a library hook's `locateBotopink` stop there:

- a **library** task (`--repo rakun`) runs the **main checkout's compiler**
  (`repository/botopink-lang/zig-out/bin/botopink`) — no compiler build per task;
- a **compiler** task (`--repo botopink-lang`) builds its own and its conformance stage's
  library jobs (`conformance/run.sh` `libraries/<name>`, decisions 996, 1004) see the main checkout's libraries;
- the hook is the repository's own (a worktree shares its repository's config).

Three rules make it safe:

1. **The main checkout's compiler stays at remote `feat` and built.** The coordinator
   rebuilds it (`zig build -Doptimize=ReleaseSafe`) once after each compiler landing,
   never during a library task's gate; `source_stamp` refuses a binary older than its
   sources, so a stale compiler fails a gate, it never measures silently.
2. **A library task never edits `repository/botopink-lang`** (decision 433): a missing
   language feature is a `language-gaps.md` row and waits on its 144 step. The one carve-out
   (decision 651): `conformance/modules/decisions-taken/**` of every repository is front 166's,
   its threads committing there directly, one per repository, nothing outside the subtree.
3. **The full worktree** (no `--repo`) is for a task that edits the meta repository or more
   than one repository.
4. **The hook runs `scripts/gate.sh --no-conformance`; conformance is `feat`'s pipeline's** (decisions
   470, 477): a step's commit checks the build, the unit tests and what it reaches, fast; the front lands on
   `feat` without waiting for conformance; its Conformance step reads `feat`'s pipeline run of
   `scripts/gate.sh` with conformance — a red is reproduced locally and fixed at once, and the cheap
   test the hook runs that would have caught it is written beside the fix (478).
   A front's Conformance step holds back no other front (479): the fronts that need its change open
   once its other steps have landed.
   It also updates the reference (480): the `docs.md` beside each cell it writes or changes, and the
   root `conformance/docs.md` where the change is not one cell's.
4b. **No `gate.sh --cold` inside a `--repo` / `--lang` worktree.** Its gate is the commit
   hook's (`--staged`, warm). `--cold` deletes every sibling library's cache, and the
   siblings there are the main checkout's: a cold gate, when a landing calls for one,
   runs in the main checkout's `repository/botopink-lang` on the commit being landed.
5. **A botopink-lang task proves itself in the conformance suite** (decision 458): every
   `tests/language` cell green and the cells of the behaviour it lands written in decision 457's
   shape; a front that changes botopink-lang **ends with its "Conformance" step** (459): the whole
   suite green, the front's changes analysed against the cells, the cells written, the missing ones
   proposed. The coordinator checks the cells at landing and files the proposals.
   A library front ends the same way (465): its "Conformance" step runs `botopink cell check
   conformance/` over the whole `<lib>/conformance/` (until 996 / L5 moves the libraries to the root-package shape,
   when it becomes that shape's run; the stage is a known red meanwhile, 1002 (c)).
   The Conformance step also reads the GitHub pipeline with `gh` (474): `feat`'s runs since the
   front's base green, or each red named and fixed or filed before landing.

The thread commits in its repository only; the coordinator writes the specs (through specs-bot) and the
pointer bump at landing, then removes it with `git -C repository/<repo> worktree remove
.tasks/<name>/repository/<repo>` and `rm -r .tasks/<name>`. The other repositories are
the main checkout's, at whatever they are checked out to.

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
5. **Text and expected answers have no oracle.** Spec or decision text is never `haiku`'s
   (`sonnet` at least); a thread that writes a cell's or a snapshot's expected answer decides
   language versus defect, so it runs on `opus` unless its prompt fixes every answer.

Every thread prompt opens with "Read `scripts/thread-rules.md` first" and then states only what is
the task's own (decision 484): the rules every thread follows (no `--no-verify`, no scratch paths
in specs, no timings, never a defect as a departure, rebase onto `origin/feat` before the final
commit, the four-line report) live there once, so no prompt forgets one. Before a landing the
coordinator runs `scripts/land-check.ts` on the branch (163 s12) instead of re-reading the diff
by hand.

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

### `fable` as a consultant (the maintainer, 2026-10-14)

`fable` works where no oracle checks the work, with small inputs, and never implements
(unless a plan and its `sonnet` / `opus` build have both failed):

1. **A plan, then another model builds it.** For a design step (a front's codegen or runtime
   change, a decision's first build, a step whose README leaves the design open), a `Plan`
   thread on `fable` reads the step and the decisions it names and returns a short plan:
   the design answers, the interfaces, the order of landable pieces with each piece's oracle,
   the risks, the model per piece. The coordinator keeps the plan in its scratch area and
   files its open points as questions. The pieces then run on `sonnet`, or on `opus` where
   the piece is still typed design.
2. **A targeted review after a landing.** Its input is only the expected answers that changed
   (cells, snapshots, refusal texts, departures), the report's Outside and Questions, and the
   decisions' text. It answers, per point: (A) the language, fine; (D) a defect — the 144 or
   164 row and the cell it calls for, red or out; (Q) a maintainer question, written in the
   pending page's shape. The coordinator files the rows and the questions (English first,
   the Portuguese page its translation).
3. **A trigger, not a routine.** The review runs only when a cell's or a snapshot's answer
   changed beyond what the step stated, a thread chose something no decision fixes, or the
   step is design. Mechanical work, migrations, and fixes whose answers the step states and
   whose cells go red to green get none.

| Thread | Model |
|---|---|
| The plan of a design step | `fable` (`Plan` agent) |
| The pieces of that plan | `sonnet`, or `opus` for a piece that is still typed design |
| The review of a landing whose answers changed or that made a choice no decision fixes | `fable`, read-only |
| A fix whose answers its step states (a 144 / 164 row with named cells) | `sonnet`, no review |

### Keeping the threads honest and the machine busy (the maintainer, 2026-10-15)

At each landing, each thread's end and before each status report, the coordinator reconciles what is listed with what
runs:

1. **A thread is active only if something of it runs.** That means a live `gate.sh exec` / `zig` / `botopink` process
   in its worktree, or recent progress there (`git log`, `git status`). A thread's listing alone proves nothing.
2. **A finished thread is stopped.** A sub-agent that handed back "with background work still running" stays listed with
   its last activity (e.g. "amending commit"). Once its work has landed, the coordinator stops it (`TaskStop`) and
   removes its worktree.
3. **Orphan loops are killed.** The coordinator runs `scripts/stray-loops.sh` (every shell polling in a `sleep` loop,
   flagged when the PID it waits on is gone, when every file it names went unwritten for 30 minutes, or when it is
   older than three hours with no `timeout`; exit 1 while one is flagged) and kills the flagged ones by PID with
   `--kill`, after a look. A loop that waits on `pgrep -f <pattern>` matches its own command line and never ends; a
   thread's every wait runs under `timeout`, on its own PID or file, and its scratch files sit under a subdirectory
   named after its task (`scripts/thread-rules.md`). Every thread prompt repeats that rule: kill your own background
   jobs before reporting.
4. **No idle slot.** After the reconciliation the coordinator checks free capacity: the really active threads and
   `MemAvailable`. Each free slot is filled with the next work that needs no maintainer decision and touches no
   running thread's area, up to about five threads, the machine's pool and memory permitting (§ Gate orchestrator).
   What stays blocked is named in the report, with what blocks it: a pending question, another front, a running
   thread's files.

## Build and test

All Zig commands run from `repository/botopink-lang/`:

```sh
zig build          # botopink + botopink-lsp
zig build test     # compiler-core + language-server (~17s)
zig build test-conformance / test-backends / test-vscode / test-bpmp   # the libraries run in test-conformance (996)
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
  (`todo.md`, `02-type-system.md`, `architecture.md`)
  are in Portuguese — keep each file in its current language.
- **The specs are in English.** A Portuguese page (`decisoes-pendentes.md`) changes only when the maintainer asks
  for its translation (the maintainer, 2026-10-25); then it is the English text's most direct translation — the
  prose translated, ids, code, examples, messages, paths and recommendations kept as in English.
- Any code or layout change updates the matching `AGENTS.md` in the same commit.
- Specs describe current state and remaining work; do not keep status narratives,
  commit hashes or superseded approaches in them.
