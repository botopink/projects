# Front 33 — emilia test member and examples: a usable `emilia-test`, an emilia-only `emilia-card`, fifteen READMEs (carries the test layer of 1.0.10's 35–48 · 54–59)

**Priority:** medium — `emilia-test`'s helper is mandatory (`02-packaging` § 5) and `emilia-card`
is a decision-114 violation on disk; the snapshot suites and the eight examples are conditional ·
**State:** not started — steps 1–2 open now
**Depends on:** steps 1–2: nothing (`08-bpp/118`'s carve-out here is one comment,
`emilia-card/src/main.bp:5`, which step 2 rewrites anyway) · steps 3–4: `06-emilia/34` landed
(they record what 34 pins) and `05emilia-m` · `02-std-and-packaging/98` reads this front's output
(the README count, the helper) — not a dependency
**Owns:** `repository/emilia/modules/emilia-test/**` · `examples/*/README.md` (fifteen) ·
`examples/emilia-card/**` · step 3: `modules/emilia/test/**` (new) · step 4: the eight new example
members · `repository/emilia/AGENTS.md` (the tests paragraph) · this directory
**Does not touch:** `modules/emilia/src/**` (34) · the other fourteen examples' `src/main.bp`
(34 owns four; the rest have no open item) · `.github/workflows/test.yml` (`00-gate`) ·
`repository/jhonstart/**`

## Goal

1. `modules/emilia-test/src/root.bp` holds one resolve test and exports nothing — a consumer
   cannot import a helper from it. `02-packaging` § Step 4 requires at least one
   `assert<Subject>(loc, …) -> @Result<void, string>` that hands `loc` to `snapshots` unchanged.
2. `examples/emilia-card/botopink.json` depends on `jhonstart` by `path` (4 tests, printing a
   jhonstart-rendered card with three class names and the flushed sheet); decision 114 says every
   emilia example uses emilia only, and an example that renders styled HTML is onze's.
3. `find repository/emilia/examples -maxdepth 2 -name README.md` finds 0 of 15.
4. [`test-snap.md`](./test-snap.md) and [`test-snap-examples.md`](./test-snap-examples.md) specify
   a snapshot layer that does not exist — realised or retired on `05emilia-m`.

[`examples/`](./examples/) holds the worked example of the helper shape (a submodule and its
consumer with `@src()`).

## Mechanism

A helper renders its subject to one deterministic string and hands it to
`snapshots.assertAs(loc, "<subject>", text)`; the `.snap` lands beside the calling test
(`snapshots.path(loc)`), a `.new` on mismatch, no update flag. `assertCss` is
`tokensToSheet(tokens, fullTheme())` rendered as one class fixed to `e`; `assertClassName` is the
literal `e_<hex>` — the contract-4 form. `emilia-card` becomes emilia-only by printing what
`emilia(tokens)` and `flush()` answer for the same three token lists, with no `Element`. The
helper set is the smallest that satisfies the packaging rule unless the maintainer asks for the
map: a helper nobody calls is a surface to keep green for nothing.

## Open

### Step 1 — the helpers

Unconditionally `assertCss`, `assertCssWith` and `assertClassName` plus the fixture builders
(`sampleTheme()`, the contract-4 token list); the other five of `test-snap.md` § The helpers
under `05emilia-m` (b) or (c) only. `test/helpers_test.bp` with one accepted snapshot per helper
on both rows.

- [ ] `import {assertCss, assertClassName, sampleTheme} from "emilia-test"` resolves from a
      consumer; each helper's signature is `(loc: SourceLocation, …) -> @Result<void, string>` and
      hands `loc` to `snapshots.assertAs` unchanged (`grep -n "snapshots\." src/*.bp`)
- [ ] `test/__snapshots__/helpers/*.snap` — one per helper, identical on both rows; a
      deliberately wrong literal in a scratch copy produces the `.new` and fails
- [ ] `assertClassName(@src(), <the contract-4 list>)` records `e_39b87d03`
- [ ] the member re-exports nothing from std (`grep -n "pub.*from \"std\"" src/*.bp` empty)

### Step 2 — `emilia-card` emilia-only, and the fifteen READMEs

- [ ] `examples/emilia-card/botopink.json` lists `emilia` only (its `description` names no other
      library); `src/main.bp` imports nothing from jhonstart; the example prints the three class
      names and the flushed sheet, asserted inline on both rows (4 tests or more); the output is
      documented in its README (1.0.10's PK-3 "prints what it printed before" is superseded)
- [ ] `find repository/emilia/examples -maxdepth 2 -name README.md | wc -l` is 15; each names the
      Tailwind section it mirrors and the front(s) it exercises
- [ ] `grep -rn jhonstart repository/emilia/examples` is empty (the scope this front owns;
      `modules/` is 34's step 1; `AGENTS.md`, `README.md`, `docs.md` and the root `botopink.json`
      describe the relation and `CHANGELOG.md` is history)
- [ ] reported to `00-gate/114`: the CI step "Checkout jhonstart (dependency — examples/emilia-card
      depends on jhonstart)" (`.github/workflows/test.yml:94-99`) is dead once this step lands

### Step 3 — the module-level suites (on `05emilia-m`)

- Under (b) or (c), after 34 lands: the 21 `modules/emilia/test/<front>_test.bp` of
  [`test-snap.md`](./test-snap.md) through the helpers, recorded by renaming `.new` files,
  identical on both rows.
  - [ ] every `.snap` the map names exists under `modules/emilia/test/__snapshots__/`; no `.new`
        left; `botopink test` in `modules/emilia` green on both rows with the inline 734 plus the
        suites
- Under (a) — the recommendation:
  - [ ] `repository/emilia/AGENTS.md` § Tests says the inline literals and the three readers of
        the contract-4 literal are the evidence, and the map is retired

### Step 4 — the eight examples (on `05emilia-m`)

- Under (c): [`test-snap-examples.md`](./test-snap-examples.md) §§ `theme-brand` …
  `class-attributes`, each a member with `botopink.json`, `src/main.bp`, `test/` and
  `__snapshots__/`, emilia only.
  - [ ] eight new rows in `zig build test-libs`, green on both rows, each with its README
- Under (a) or (b):
  - [ ] the map's § "What the examples cover that the module tests do not" is answered in
        `AGENTS.md` by pointing at the fifteen per-front examples

**Gate:** standard (fronts.md § Gate) + `emilia-test` at 1 + the helper tests on both rows; the
fifteen (or twenty-three) examples green on both rows · `grep -rn "jhonstart\|rakun\|onze"
repository/emilia/modules/emilia-test repository/emilia/examples` empty
