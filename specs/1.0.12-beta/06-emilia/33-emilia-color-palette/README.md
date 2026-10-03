# Front 33 — emilia test member and examples: a usable `emilia-test`, an emilia-only `emilia-card`, fifteen READMEs (carries the test layer of 1.0.10's 35–48 · 54–59)

**Priority:** medium — `emilia-card` violates decision 114 on disk; `emilia-test`'s helpers
(mandatory, `02-packaging` § 5) and the snapshot layer are `20-snap`'s ·
**State:** not started — step 2 open now; steps 1, 3, 4 → 20-snap
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

[`examples/`](./examples/): the worked helper shape (a submodule and its consumer with `@src()`).

## Mechanism

`emilia-card` prints what `emilia(tokens)` and `flush()` answer for the same three token lists, no
`Element`.

## Open

### Step 1 — the helpers

→ 20-snap (front 135) step 4

### Step 2 — `emilia-card` emilia-only, and the fifteen READMEs

- [ ] `examples/emilia-card/botopink.json` lists `emilia` only (`description` names no other
      library); `src/main.bp` imports nothing from jhonstart; prints the three class names and the
      flushed sheet, asserted inline on both rows (4 tests or more); output documented in its README
      (1.0.10's PK-3 "prints what it printed before" superseded)
- [ ] `find repository/emilia/examples -maxdepth 2 -name README.md | wc -l` is 15; each names the
      Tailwind section it mirrors and the front(s) it exercises
- [ ] `grep -rn jhonstart repository/emilia/examples` is empty (this front's scope; `modules/` is
      34 step 1; `AGENTS.md`, `README.md`, `docs.md`, root `botopink.json` describe the relation,
      `CHANGELOG.md` is history)
- [ ] reported to `00-gate/114`: the CI step "Checkout jhonstart (dependency — examples/emilia-card
      depends on jhonstart)" (`.github/workflows/test.yml:94-99`) is dead once this lands
- `emilia-card`'s repeat-collapse assert is `20-snap` step 4's, written with this step

### Step 3 — the module-level suites

→ 20-snap (front 135) step 4

### Step 4 — the eight examples

→ 20-snap (front 135) step 4

**Gate:** standard (fronts.md § Gate) + the fifteen examples green on both rows ·
`grep -rn "jhonstart\|rakun\|onze" repository/emilia/examples` empty
