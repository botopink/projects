# Front 09 — ecosystem residuals

**Priority:** low — every library compiles, runs and passes its cells; what is left is one ledger
line and the rows the library tracks carry.
**Depends on:** nothing for erika. The rows named for the other four libraries follow their tracks.
**Owns ([`fronts.md`](../../fronts.md)):** `repository/erika/**` and the meta submodule pointers
**only**. The other four trees are tracks B–E's ([`03-rakun`](../../03-rakun/README.md),
[`04-jhonstart`](../../04-jhonstart/README.md), [`05-emilia`](../../05-emilia/README.md),
[`06-onze`](../../06-onze/README.md)); a row below that names one of them is that track's
**Does not touch:** `repository/botopink-lang/**` · `repository/vscode-extension/**`

Measured 2026-09-26 against the compiler `front/sweep-docs` builds, from an rsync copy of the
checkout outside `.tasks/` (inside a worktree the library runner sees every library twice — the
worktree's and the main checkout's — and refuses until C-33's `25-gate-perf` fix lands).

---

## What holds

| | erika | the other four |
|---|---|---|
| the 1.0.3 surface — no `record` / `enum` / `interface` keyword, no `while (` | holds | holds |
| cells | `modules/erika` **31/31**, `modules/erika-test` **1/1**, `examples/erika-linq` **9/9** — each on commonJS **and** erlang | their tracks' counts (`status.md`) |
| `botopink format --check` | **exit 0** in every member and at the root — both members formatted to decisions 132 and 133 and C-12's width rules. Verified four ways: word-and-literal tokens and comment text identical before and after, idempotent, the cells above unchanged, `examples/erika-linq`'s emitted output `diff -r` byte-identical on commonJS and erlang | red, and theirs to run (decision 132 step 1): jhonstart 47 files, rakun 48, emilia 25, onze 2 |
| a formatter hunk that loses information | none — the array-element trailing comment that kept `erika-linq` red (16-formatter's G7) now stays on its element's line | rakun `runtime.bp:13`'s comment column is the last one registered (16-formatter's trivia rows) |
| erlang output at decision 109's atoms | one module per `type`, `erika@erika@@Query`, `erika@erika@@Grouping`, `erika_linq@main@@Box`, …; `botopink run --target erlang` in the example prints the six lines commonJS prints | each track's exit gate re-runs its erlang cells |
| rakun's erlang story (step 2) | — | **superseded** by decisions 17 and 113: rakun supports every target and is the service on erlang; the host module is `modules/rakun/src/sidecars/rakun_runtime.erl`, shipped by `libs.shipErlSidecars`. The 1.0.4-beta row "a library cannot ship an erlang host module" is struck (1.0.4-beta `fronts.md`) |
| decision 8 §5.3b — section paths | — | **landed** in emilia (`Token.Text`, `Token.Text.Size`, …); `tests/language/test/case_sections.bp` passes on commonJS and erlang |
| `AGENTS.md` claims | re-derived: § Formatting, § Erlang output, the `erika-linq` `targets` row, the §1.4 note (the checker does not flag `val out = [];` yet — C-14), the parent link | dead `tasks/v0.beta.*` links in jhonstart's and emilia's documents repointed at their tracks |

## Open

**1. `erika-linq`'s `"targets": ["commonJS"]` has outlived its reason.** The erlang cell runs 9/9
and `scripts/restricted-targets.txt` pins it at `0` failed. Lifting it is two edits that land
together, because the runner refuses a stale ledger line: drop `"targets"` from
`repository/erika/examples/erika-linq/botopink.json`, and delete the `erika-linq erlang` line of
`repository/botopink-lang/scripts/restricted-targets.txt`. The second is a compiler-tree edit this
milestone's compiler threads keep to themselves; it lands with the next compiler sweep that touches
the ledger.

**2. Decision 8 §5.1 — `case` arms written `pattern -> value;`** are left in emilia, jhonstart and
rakun (erika has no `case`). The rewrite is [C-14](../README.md#c-14--decision-8-in-the-sources)'s,
run by each track on its own tree. `docs.md` § Case still teaches both arm forms as current, so the
row needs the maintainer's word on whether the `->` arm leaves the language before any tree is
rewritten.

**3. The other four libraries' rows** — theirs, listed so this front's ledger is complete:
`format` with decision 132's `;` migration (step 1 of that decision); rakun's two erlang reds and its
`allow_fail: true` erlang CI rows (`03-rakun`); the `"targets": ["commonJS"]` restrictions the
ledger measures at `0` on `emilia-card`, `jhonstart-counter`, `jhonstart-todo` and the three rakun
examples; rakun's and onze's dead `tasks/v0.beta.*` and `../AGENTS.md` links (`AGENTS.md`,
`docs.md`, `src/AGENTS.md`).

**Acceptance:**
- [x] erika: every member's cells green on commonJS and erlang (31 · 1 · 9) and `format --check`
      exit 0 in every member
- [x] erika's erlang cells and example re-run at decision 109's atoms — no cell worse
- [x] `tests/language/test/case_sections.bp` passes before emilia's §5.3b rewrite — it passes, and
      the rewrite has landed (`05-emilia`)
- [x] rakun's erlang story — superseded by decisions 17 and 113 (above); the struck 1.0.4-beta row
      is recorded as struck
- [x] every `AGENTS.md` claim in erika re-derived by running it
- [ ] `erika-linq`'s `targets` lifted with its ledger line (item 1)
- [ ] §5.1 arms rewritten in emilia, jhonstart and rakun, each cell green after its rewrite — C-14,
      by the tracks, after the maintainer's word (item 2)
- [ ] the submodule pointers of the five libraries bumped in one sweep after each library's branch
      merges into its own `feat` — the maintainer's

## Gate

- [x] erika's own gate (`scripts/git-hooks/pre-commit`: `botopink test` per member, `botopink build`
      per example) green at this front's commit; jhonstart's and emilia's green at theirs
- [x] `zig build test-libs -- --lib erika` / `--lib erika-linq`: 3 passed, 0 failed, 1 restricted
      (pinned at 0)
- [x] `AGENTS.md` of every directory touched updated in the same commit
- [x] Library commits on `front/sweep-docs`; the pointers bumped on the meta branch of the same name;
      no push, no merge
