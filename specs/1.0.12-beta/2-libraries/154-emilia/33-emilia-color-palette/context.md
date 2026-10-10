# Front 33 — emilia test member and examples: a usable `emilia-test`, an emilia-only `emilia-card`, fifteen READMEs (carries the test layer of 1.0.10's 35–48 · 54–59)

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — `emilia-card` violates decision 114 on disk; `emilia-test`'s helpers
(mandatory, `02-packaging` § 5) and the snapshot layer are `20-snap`'s ·
**State:** step 2 done; steps 1, 3, 4 → 20-snap
**Depends on:** step 2: nothing (`08-bpp/118`'s carve-out here is one comment,
`emilia-card/src/main.bp:5`, rewritten by step 2 anyway) · `02-std-and-packaging/98` reads the
README count — not a dependency
**Owns:** `repository/emilia/examples/*/README.md` (fifteen) · `examples/emilia-card/**` · this
directory (`modules/emilia-test/**` and `AGENTS.md`'s tests paragraph: `20-snap` step 4)
**Does not touch:** `modules/emilia/src/**` (34) · the other fourteen examples' `src/main.bp` (34 owns
four; the rest have no open item) · `.github/workflows/test.yml` (`00-gate`) · `repository/jhonstart/**`

## Goal

1. `modules/emilia-test/src/root.bp`: one resolve test, exports nothing. `02-packaging` § Step 4
   requires ≥ one `assert<Subject>(loc, …) -> @Result<void, string>` handing `loc` to `snapshots`
   unchanged: `20-snap` step 4 writes them.
2. `examples/emilia-card/botopink.json` depends on `jhonstart` by `path` (4 tests, printing a
   jhonstart-rendered card with three class names and the flushed sheet); decision 114: every emilia
   example uses emilia only; styled HTML is onze's.
3. `find repository/emilia/examples -maxdepth 2 -name README.md` finds 0 of 15.

[`examples/`](examples/): the worked helper shape (a submodule and its consumer with `@src()`).

## Mechanism

`emilia-card` prints what `emilia(tokens)` and `flush()` answer for the same three token lists, no
`Element`.
