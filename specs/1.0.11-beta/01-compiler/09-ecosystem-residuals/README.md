# Front 09 — ecosystem residuals

**Priority:** low — every library compiles, runs and passes its cells; what is left is one manifest,
one arm form the maintainer has not ruled on, and the pointers' sweep.
**Depends on:** `00-gate` (RT-1 — `erika-linq`'s ledger line is deleted by the gate; this front drops
the manifest's `"targets"` in the same landing) · `16-formatter` steps 3–4 (the siblings' C-13
migration and C-12 reformat — the library tracks run them in their trees; this front runs them in
erika, the one library with no track this milestone) · the maintainer's word on C-14's `->` arms ·
every library track's merge into its own `feat` (the pointers last).
**Owns:** `repository/erika/**` (with `02-std-and-packaging/98-packaging-tail`, which owns
`erika/modules/erika-test/**`, `examples/erika-linq/README.md` and `erika/AGENTS.md` — this front
owns the sources and the manifests) · the meta submodule pointers **only**. The other four library
trees are their tracks' (`03-rakun`, `04-jhonstart`, `05-emilia`, `06-onze`); a row below that names
one of them is that track's.
**Does not touch:** `repository/botopink-lang/**` (the ledger is `00-gate`'s; `c13-migrate.py` is
16's — run, not edited) · `repository/vscode-extension/**`.
**Does not touch until 00-gate lands:** `repository/erika/examples/erika-linq/botopink.json` (RT-1).

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| erika-linq's `targets` | `09-ecosystem-residuals/README.md` | § Open, item 1 |
| the `->` arms (C-14) | `09-ecosystem-residuals/README.md` · `00/README.md` | § Open, item 2 · § C-14, box 2 |
| the libraries' C-13 migration and C-12 reformat | `16-formatter/README.md` | § Open, rows 1–2 (the trees that are not the compiler's) |
| the pointers' sweep | `09-ecosystem-residuals/README.md` | § Acceptance, last box |
| jhonstart's "always name the module" rule | `04-js/README.md` | § Step 5, last box |

## What holds

erika: `modules/erika` 31/31, `modules/erika-test` 1/1, `examples/erika-linq` 9/9 on commonJS and
erlang; `botopink format --check` exit 0 in every member; erlang output at decision 109's atoms.
The other four libraries: their tracks' counts. Measured at 1.0.10's close; re-measure at this
front's open (`zig build test-libs -- --lib erika`, `--lib erika-linq`).

## Open

**1. `erika-linq`'s `"targets": ["commonJS"]` has outlived its reason.** The erlang cell runs 9/9
and `scripts/restricted-targets.txt` pins it at `0`. Two edits land together, because the runner
refuses a stale ledger line and a restriction with no line alike: drop `"targets"` from
`repository/erika/examples/erika-linq/botopink.json` (this front), delete the `erika-linq erlang`
line (00-gate RT-1). `jhonstart-counter` and `jhonstart-todo` are the same shape (RT-2, RT-3) in
the jhonstart track's manifests.

**2. Decision 8 §5.1 — `case` arms written `pattern -> value;`** are left in emilia, jhonstart and
rakun (erika has no `case`). The rewrite is C-14's, run by each track on its own tree; `docs.md`
§ Case (`docs.md:870`) — re-measure whether it still teaches both arm forms (the audit's grep for
the arrow arm found none; `test/case_arrow_arms.bp` is the transition guard beside `test/case_arms.bp`).
The row needs the maintainer's word on whether the `->` arm leaves the language before any tree is
rewritten; until then it is a form the suite pins.

**3. The libraries' C-13 migration and C-12 reformat** — rakun 454 sites, jhonstart 40, erika 28,
onze 1 (1.0.10's count, unverified at the open): each track runs `16-formatter/c13-migrate.py` at
the end of the threads writing in its tree, then `botopink format` once 16-a/16-b are confirmed;
erika's is this front's (28 sites, then the reformat). 16's step 3 (the parser refusing the `;`)
waits for all five.

**4. The pointers' sweep** — the submodule pointers of the five libraries bumped in one sweep
after each library's branch merges into its own `feat`; the jhonstart "always name the module"
rule (`repository/jhonstart/AGENTS.md`) deletable since 04's step 5 — the jhonstart track's edit,
noted here so the sweep sees it.

**Acceptance:**
- [ ] erika-linq's `targets` lifted with its ledger line (item 1); `zig build test-libs -- --lib erika-linq` runs the erlang cell as an ordinary cell, 9/9
- [ ] erika's 28 `;` sites migrated by the script, the cells green before and after, `botopink format --check` exit 0 (item 3, erika's share); the reformat at C-12's rules after 16-a/16-b, token-identical and idempotent
- [ ] §5.1 arms rewritten in emilia, jhonstart and rakun, each cell green after its rewrite — C-14, by the tracks, after the maintainer's word (item 2)
- [ ] the submodule pointers of the five libraries bumped in one sweep (item 4)

## Gate

- [ ] erika's own gate (`scripts/git-hooks/pre-commit`: `botopink test` per member, `botopink build` per example) green at this front's commit
- [ ] `zig build test-libs -- --lib erika` / `--lib erika-linq` green in the meta worktree (decision 143: library resolution stops at the enclosing checkout)
- [ ] `AGENTS.md` of every directory touched updated in the same commit
- [ ] Library commits on `fix/09-ecosystem-residuals` in erika; the pointers bumped on the meta branch of the same name; no push, no merge

## Notes

- Measured inside the meta worktree since decision 143; the rsync-copy workaround of 1.0.10 is no
  longer needed.
- Rakun's `runtime.bp:13` comment column, the last information loss registered against the
  formatter, is closed (C-12's comment column); no formatter row is open against a library at the
  open.
