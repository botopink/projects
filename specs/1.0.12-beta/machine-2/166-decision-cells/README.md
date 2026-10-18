# Front 166 — decision cells: one cell per decision, in the repository it binds

**Priority:** medium (the maintainer, 2026-10-18) — the ledger becomes code: every decision in force has one real program that shows it, checked by the gate once the gate is solid.
**Repository:** the meta repository for the script and the CI check (a full worktree, s1–s2); then one `--repo <repo>` / `--lang` worktree per repository under `repository/` that has a `conformance/` (s3, s5); s4's compiler boxes a `--lang` worktree.
**Model:** sonnet for the script and the check (s1, s4 compiler boxes), haiku for the scaffold commits, **opus for every cell's docs, code and accepted answer** (`AGENTS.md` § Which model: text and expected answers have no oracle), opus for the Conformance step.
**Depends on:** decision 482 (the generated ledgers), 457 / 464 / 475 (the cell shape), 461 / 462 / 463 (the reference beside its cells), 511 / 512 (the name, the workspace); per repository, the builtins group's codemods over it (§ Order).
**Owns:** `scripts/decision-cells.py`, meta CI check 7 (`scripts/gate.sh check`, `hook-integrity.yml`, `AGENTS.md` § CI / § Layout); in every repository `conformance/modules/decisions-taken/**` and the one row that names it in the root `conformance/docs.md` and the workspace manifest (`conformance/modules/botopink.json`; rakun's root `conformance/botopink.json`, 548).
**Does not touch:** any other cell, `libs/std/**`, `modules/**` beyond s4's two boxes, the ledger's rules (the coordinator's; s2 adds a tag, never a word), a library's members.
**Gate:** standard (fronts.md § Gate); the hook's gate for every commit, check 7 green on the meta.

---

## Problem

`repository/<repo>/decisions-taken.md` (482) tells a reader which decisions bind a repository, in prose; nothing in that repository shows a decision as code, and nothing reds when the compiler or a library departs from one. The ~1,595 cells of `botopink-lang/conformance/modules/` prove behaviours, 256 of them naming a decision in their header, but no cell is reachable from a decision's number, and most decisions name no cell. The maintainer, 2026-10-18: `*/conformance/modules/decisions-taken/<slug>-<N>/docs.md` and `src/*.bp` for every conformance directory — first the code that shows how the decision works, tied to real code; last, the cells really run under a gate that is solid by then.

## Current state (measured 2026-10-18 by `scripts/decision-cells.py scaffold --list` over the ledger's `Cell` column, 504 rows)

| Repository | Ledger rows | One-liners (`Replaced by` / `Reversed by` / `Overtaken by` / `Withdrawn`) | Process rows | **Cells** | Cells today |
|---|---|---|---|---|---|
| botopink-lang | 405 | 14 | 21 | **370** | 1,594 |
| rakun | 174 | 6 | 10 | **158** | 1 (plus the feature cells of 548) |
| query | 43 | 1 | 4 | **38** | 4 |
| validation | 41 | 1 | 4 | **36** | 0 |
| routing · http · log | 17 · 15 · 11 | 0 | 2 each | **15 · 13 · 9** | 0 |
| json · actions · markdown · snap · yaml · css | 8 · 7 · 7 · 7 · 7 · 6 | 0 | 2 each | **6 · 5 · 5 · 5 · 5 · 4** | 0 |
| vscode-extension | 26 | 1 | 2 | **0** — no `conformance/`, no `.bp`; its 23 slugged rows are the extension's | — |

**669 cells.** A row binding several repositories gets a cell in each (the rule as that repository meets it). A rule that opens `Overtaken by N` / `Reversed by N` and only restates the row in force (586, 612, 633–636) counts as a one-liner, as does `Withdrawn`.

## Mechanism

**One decision, one cell, in the ledger's shape.** `conformance/modules/decisions-taken/<slug>-<N>/` — `N` the decision's global number — exists in a repository exactly when `N` is a row of that repository's generated `decisions-taken.md` that **fixes program behaviour**: not a one-liner (a row whose rule is `Replaced by N.` / `Reversed by N` / `Overtaken by N` — the row in force has the cell, and it shows what is in force), and not a process row (specs, CI, the gate's scheduling, a step's order, a front's shape: the ledger marks it with `process` in its id column — the tag the ledger already uses, s2 completes it; a process row has no code to show and a `docs.md` alone would be the ledger's prose in a second form, so it gets nothing). A row amended but in force keeps its cell, showing the rule as amended.

**What the cell holds.** `docs.md`: what the decision fixes, as the example shows it — a walk through the program, never the ledger's rule retyped (the generated ledger beside it is the source) — then the list of the existing cells that prove the decision (`modules/<cell>`, found by their header and their `docs.md`); it **never contains code**: one line `[src/main.bp](src/main.bp)` references the example (and `[src/<other>.bp](src/<other>.bp)` where the decision needs several modules — a second package, a refusal in a dependency), in the spirit of the root reference's `<!-- example: modules/<cell> -->` (461 (2)); see 166-c. `src/main.bp`: **the one real example**, a whole program in the spelling in force (575–643: `compiler` imported, `syntax` / `comptime` parameters, `compiler.init`, no `@name` builtins, `-> void` on every function (622), `#[compiler.external(…)]`, `Implementation.JavaScript`, lowercase primitives (641), `{ async x -> … }`, `try { … } catch …`), showing the decision's points together where the proving cells show them one by one; a refusal decision's example is the refused program (its `.snap` the `refused` / `at` record, 475). The existing cells are not moved, renamed or aliased: a cell proves one behaviour and the reference names it; the decision cell is the ledger's index into them plus its one example — one thing in one form each.

**Generated versus written.** `scripts/decision-cells.py` (s1) reads the repository's generated ledger and: `scaffold <repo>` creates every missing directory with `docs.md` (`# Decision <N> — <the row's bold lead>`, a blank line, `[src/main.bp](src/main.bp)`) and the stub `main.bp` (a `////` header `Decision <N> — <lead>`, `pub fn main() -> void {}`); `compile <repo>` puts each `main.bp` into a scratch cell (the workspace's dependencies, `src/main.bp`, a manifest) and runs `botopink cell check` on the copy, red on a refusal, the output candidate discarded — the writing thread's local check in phase 1, never a gate verdict; `promote <repo>` (s4) moves `main.bp` to `src/main.bp` and writes `botopink.json`; `check` is CI check 7. Generated and kept by check 7: the first line of `docs.md` and the `////` header (equal to the ledger's row; `scaffold` rewrites those two lines when a lead changes). Everything else — the prose, the include lines, the program, the manifest's `"targets"`, the accepted `.snap` — is written by the thread.

**Phase 1 is not in the gate, by shape, not by a flag.** `botopink cell check` walks every directory and takes one holding `src/` for a cell (`compiler-cli/src/cli/cell.zig`, `discover`), and a cell without a snapshot is red by design (464 (3), 475 (6)); 67 forbids a flag, a list or a `pending` verdict that lets a cell pass unrun. So in phase 1 the example is `decisions-taken/<slug>-<N>/draft/main.bp` — `docs.md` references it as `{main.bp}` — and nothing under `decisions-taken/` is a cell yet: the walk finds no `src/`, the workspace glob `"*"` names no member there, `compile` proves the programs build. The last phase promotes every directory to the full shape (475) in one commit per repository and adds `"decisions-taken/*"` to the workspace manifest; from then on `botopink cell check conformance/` runs them like any cell. The alternatives are 166-b's.

**The name.** A package name starts with a lowercase letter (`modules/manifest/src/root.zig`, the erlang atom) and a cell's name is its directory's (511): `<N>` cannot be both. 166-a decides; the scaffold waits on it only for `promote`.

**CI check 7** (`scripts/gate.sh check`, `hook-integrity.yml`): for every repository with a `conformance/`, (i) *consistency*, from the first batch — every `decisions-taken/<slug>-<N>/` names a row of that repository's generated ledger that is neither a one-liner nor `process`; it holds `docs.md` whose first line is the row's and which contains the `{…}` include line(s), each naming a file that exists, and no fenced code; it holds `main.bp` (phase 1) or `botopink.json` + `src/main.bp` (promoted) with the generated header; a promoted cell's `"targets"` is a subset of the workspace's; (ii) *completeness*, switched on by s4 per repository, no exemption after — every code-bearing row has its directory. A red names the repository, the row and this front.

## Steps

### s1 — the script and check 7 (meta)

**Repository:** meta (full worktree) · **Model:** sonnet · **After:** nothing — `scripts/**` and the workflow are disjoint from the group (machine-2 README rule 1).

- [x] `scripts/decision-cells.py` with `scaffold`, `compile`, `promote`, `check`, as § Mechanism; the row classification (one-liner, `process`, code-bearing) read from the generated ledger only, never guessed; `--check` exit 1 with one line per reason; a test per reason (`scripts/decision-cells-test.py`, the shape of `land-check-test.py`)
- [x] check 7 in `scripts/gate.sh check` and `hook-integrity.yml`; `AGENTS.md` § CI, § Layout; the meta `scripts/gate.sh check` green on the tree as it is (no directory exists yet)

### s2 — the ledger's `Cell` column: the slugs and the `process` tags (meta, the coordinator; decision 647)

**Repository:** meta · **Model:** opus (a reading of every row) · **After:** s1's `scaffold --list`, which prints the rows it would scaffold and the candidates it reads as process.

- [x] the ledger's table gains the fifth column `Cell` (647): every row that fixes program behaviour gets its slug (`lowercase_with_underscores`, unique, readable — `function_return_type_written`), a one-liner or a process row an empty cell; `scripts/decisions-split.py` carries the column into every repository's ledger and refuses two rows with one slug; the header's column list updated
- [x] every row that fixes no program behaviour carries `process` in its id column — the ledger's existing tag, added in the meta ledger only, no word of a rule changed; the per-repository ledgers regenerated (482, CI check 6)
- [x] `scripts/decision-cells.py scaffold --list` per repository agrees with the table in § Current state within what s2 found; the counts written into that table

### s3 — the cells, phase 1: docs and code, one repository per thread

**Repository:** one per thread — `--lang` for botopink-lang (under 166-d), `--repo <repo>` for each library · **Model:** opus · **After:** 166-a … 166-d answered; per repository, § Order.

- [ ] `scaffold <repo>` committed alone (haiku; the hook), then the writing in batches of about forty rows, one commit per batch: each `docs.md` as § Mechanism (prose, the proving cells, `{main.bp}`), each `main.bp` the one real example in the spelling in force, `compile <repo>` green on the batch, `botopink format` applied to each file
- [ ] a row whose example cannot be written because the compiler or the library departs from it: the example written as the decision says, the departure a row (`language-gaps.md` for a library, a 144 / 164 row for botopink-lang) named in the report — never an example bent to what compiles
- [ ] the root `conformance/docs.md` gains one row naming `modules/decisions-taken/` (the ledger's index; 462 / 548); rakun's root manifest and `conformance/docs.md` the same (its tree stays grouped by package; the decision cells are the ledger's, not a package's feature)
- [ ] check 7 (i) green on every batch; `AGENTS.md` of `conformance/` names the subtree

### s4 — the flip: the cells run

**Repository:** botopink-lang (`--lang`, the two compiler boxes, 144's rule 1 under 166-d), then one `--repo <repo>` / `--lang` per repository · **Model:** sonnet for the compiler boxes and `promote`; opus for the accepted answers · **After:** s3 whole in that repository; the gate solid — the group's end (B-140 landed, the cold gate with conformance green on machine 2, § The group's end).

- [ ] compiler boxes, as 166-a and 166-c decide: `cell check`'s name rule for `decisions-taken/<slug>-<N>/` (511), `test-docs` reading the include form; a unit test each
- [ ] per repository, `promote <repo>` in one commit (haiku): `main.bp` → `src/main.bp`, `botopink.json` (`name`, `"targets"` = the targets the decision names, else none — the workspace's), the `{main.bp}` lines → `[src/main.bp](src/main.bp)`, the workspace glob; then `botopink cell check conformance/modules/decisions-taken/` under `scripts/gate.sh exec`, every candidate read and accepted as the language's answer (opus, thread-rules § Cells) or the cell left red with its row filed; no cell narrowed or edited to pass (458)
- [ ] check 7 (ii) switched on for that repository in the same landing — every code-bearing row has its cell, no exemption
- [ ] the hook (`--no-conformance`) still green on each commit; `feat`'s pipeline with conformance read (477)

### s5 — Conformance (decisions 459, 465, 477–480)

**Repository:** each repository s4 promoted · **Model:** opus · **After:** s4 in every repository.

- [ ] `feat`'s pipeline green in every repository with the decision cells in its `conformance/` — each red reproduced locally, fixed first (430) with 478's cheap test, or filed; every departure found by s3 and s4 listed with its row and its cell's state
- [ ] the cells' answers audited against the ledger: a cell whose answer contradicts its decision's text is a red of the step; the reference (480): the root `conformance/docs.md` row, no text contradicting a cell
- [ ] `scripts/decision-cells.py check` green on the meta with completeness on everywhere; `status.md` moves the front to Done; the gate's time with the cells is 163 s9's to measure, not this step's

## Order

s1 and s2 open now (meta files only, disjoint from the group). s3 opens **per repository** once the spelling the cells are written in is the one in force there: botopink-lang after the group's end (B-139's codemod, B-148, B-140 landed; B-21's `-> void` codemod, 622); a library after B-139's codemod commit over it, B-116 P3's marker codemod and B-21's codemod over it — a cell written before those lands is rewritten by them, and its thread's files would collide with theirs. Inside a repository the subtree is new, so s3 runs beside any front of that repository; its landings are one commit per batch, rebased, never a shared file. s4 waits for the gate solid (§ The group's end of machine 2's queue) and lands one repository at a time, botopink-lang first (the compiler boxes), then the libraries in the order of the library tier. **Exception (the coordinator, 2026-10-18, night):** a library with no front open and no codemod pending in its own files — css, json, yaml, snap, actions, markdown, log, http, routing — opens s3 before its codemods, drafts only (`draft/main.bp`, 649), one thread per repository on `--repo <lib>`, nothing outside `conformance/modules/decisions-taken/**` (651); a later codemod that misses a draft is a second pass filed as a box, not a defect. botopink-lang's, rakun's, query's and validation's s3 keep this section's order.

## Oracle

Phase 1: `compile <repo>` green on every batch, check 7 (i) green, every example in the spelling in force (the group's codemods leave it unchanged). The flip: `botopink cell check conformance/modules/decisions-taken/` green on every target each cell declares, in every repository, read from `feat`'s pipeline; check 7 (ii) green; the departures found filed as rows with their cells red or out — a decision cell is red exactly when the implementation departs from the decision, and the suite's count equals the cells that exist (265).

## Open

- **166-a** — answered by decisions 646 and 647: the directory is the slug the ledger's `Cell` column gives the decision (`decisions-taken/<slug>-<N>/`), carried by `decisions-split.py`; `scaffold` reads it, check 7 derives the directories from the repository's ledger; 511 untouched.
- **166-b** — answered by decision 649: phase 1 writes `draft/main.bp` (no `src/`, no manifest), `compile` holds it compiling, `promote` moves `draft/` to `src/` and writes the manifest; check 7 holds `draft/` or `src/`, never both.
- **166-c** — answered by decision 650: the include is an ordinary Markdown relative link (`[src/main.bp](src/main.bp)`), rendered on GitHub as a link and expanded by `test-docs`; the root reference's `<!-- example: … -->` markers migrate to links in s4.
- **166-d** — answered by decision 651: `conformance/modules/decisions-taken/**` is this front's in every repository, the one carve-out of 433 and rule 1; one thread per repository.
