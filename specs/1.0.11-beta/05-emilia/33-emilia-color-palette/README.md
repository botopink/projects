# Front 33 — emilia test member and examples (carries the test layer of 35–48 · 54–59)

**Priority:** medium — `emilia-test`'s helper is mandatory (`02-packaging` § 5) and `emilia-card`
is a decision-114 violation on disk; the snapshot suites and the eight examples are conditional
**Depends on:** steps 1–2: nothing · steps 3–4: `05-emilia/34` landed (they record what 34 pins)
and `05emilia-m` answered (b) or (c) · `00-gate`'s `.snap.new` guard in `repository/emilia` before
step 3 records anything · `02-std-and-packaging/98` reads this front's output (the README count,
the helper) — not a dependency
**Owns:** `repository/emilia/modules/emilia-test/**` · `examples/*/README.md` (fifteen) ·
`examples/emilia-card/**` · step 3: `modules/emilia/test/**` (new) · step 4: the eight new example
members · `repository/emilia/AGENTS.md` (the tests paragraph) · this directory
**Does not touch:** `modules/emilia/src/**` (34) · the other fourteen examples' `src/main.bp`
(34 owns four; the rest have no open item) · `repository/jhonstart/**`
**Carried from 1.0.10:** `modules.md` § What `emilia-test` is for ("not written yet") and
§ `repository/emilia/examples/**` (the two unowned items) · `test-snap.md` § The contract, § The
helpers and the 21 per-front sections (copied whole as [`test-snap.md`](./test-snap.md)) ·
`test-snap-examples.md` (copied whole as [`test-snap-examples.md`](./test-snap-examples.md)) ·
`01-std/examples/emilia-test-{submodule,consumer}-example.bp` (copied to [`examples/`](./examples/))
· `02-packaging` step 3 (the READMEs; PK-3 superseded)

---

## Problem

1. `modules/emilia-test/src/root.bp` holds one resolve test and exports nothing — the member
   exists to satisfy the workspace rule but a consumer cannot import a helper from it.
   `test-snap.md` § The helpers names eight; `02-packaging` § Step 4 requires at least one
   `assert<Subject>(loc, …) -> @Result<void, string>` that hands `loc` to `snapshots` unchanged.
2. `examples/emilia-card/botopink.json` depends on `jhonstart` by `path`; decision 114 says
   every emilia example uses emilia only, and an example that renders styled HTML is onze's.
3. `find repository/emilia/examples -maxdepth 2 -name README.md` finds nothing (0 of 15).
4. The two maps (2 341 + 735 lines) specify a snapshot layer that does not exist — `05emilia-m`.

## Current state

`emilia-test` 1 / 1 on both rows; `emilia-card` 4 / 4 on both rows, printing a jhonstart-rendered
card with three class names and the flushed sheet. The example files under
[`examples/`](./examples/) are the 1.0.10 worked example of the helper shape (a submodule and its
consumer with `@src()`).

## Mechanism

A helper renders its subject to one deterministic string and hands it to
`snapshots.assertAs(loc, "<subject>", text)`; the `.snap` lands beside the calling test
(`snapshots.path(loc)`), a `.new` on mismatch, no update flag. `assertCss` is
`tokensToSheet(tokens, fullTheme())` rendered as one class fixed to `e`; `assertClassName` is the
literal `e_<hex>` — the contract-4 form. `emilia-card` becomes emilia-only by printing what
`emilia(tokens)` and `flush()` answer for the same three token lists, with no `Element`.

## Steps

### Step 1 — the helpers

Unconditionally `assertCss`, `assertCssWith` and `assertClassName` plus the fixture builders
(`sampleTheme()`, the contract-4 token list); the other five of `test-snap.md` § The helpers
under `05emilia-m` (b) or (c) only. `test/helpers_test.bp` with one accepted snapshot per helper
on both rows.

**Acceptance:**
- [ ] `import {assertCss, assertClassName, sampleTheme} from "emilia-test"` resolves from a
      consumer; each helper's signature is `(loc: SourceLocation, …) -> @Result<void, string>` and
      hands `loc` to `snapshots.assertAs` unchanged (`grep -n "snapshots\." src/*.bp`)
- [ ] `test/__snapshots__/helpers/*.snap` — one per helper, identical on both rows; a
      deliberately wrong literal in a scratch copy produces the `.new` and fails
- [ ] `assertClassName(@src(), <the contract-4 list>)` records `e_39b87d03`
- [ ] the member re-exports nothing from std (`grep -n "pub.*from \"std\"" src/*.bp` empty)

### Step 2 — `emilia-card` emilia-only, and the fifteen READMEs

**Acceptance:**
- [ ] `examples/emilia-card/botopink.json` lists `emilia` only; `src/main.bp` imports nothing
      from jhonstart; the example prints the three class names and the flushed sheet, asserted
      inline on both rows (4 tests or more); the output is documented in its README (PK-3's
      "prints what it printed before" is superseded — the record says so in `carried.md`)
- [ ] `find repository/emilia/examples -maxdepth 2 -name README.md | wc -l` is 15; each names the
      Tailwind section it mirrors and the front(s) it exercises
- [ ] `grep -rn jhonstart repository/emilia` is empty

### Step 3 — conditional on `05emilia-m` (b) or (c): the module-level suites

After 34 lands: the 21 `modules/emilia/test/<front>_test.bp` of [`test-snap.md`](./test-snap.md)
through the helpers, recorded by renaming `.new` files (the guard from `00-gate` in place first),
identical on both rows.

**Acceptance:**
- [ ] every `.snap` the map names exists under `modules/emilia/test/__snapshots__/`; no `.new`
      left; `botopink test` in `modules/emilia` green on both rows with the inline 734 plus the
      suites
- [ ] under (a): `repository/emilia/AGENTS.md` § Tests says the inline literals and the three
      readers of the contract-4 literal are the evidence, and the map is retired

### Step 4 — conditional on `05emilia-m` (c): the eight examples

[`test-snap-examples.md`](./test-snap-examples.md) §§ `theme-brand` … `class-attributes`, each a
member with `botopink.json`, `src/main.bp`, `test/` and `__snapshots__/`, emilia only.

**Acceptance:**
- [ ] under (c): eight new rows in `zig build test-libs`, green on both rows, each with its README
- [ ] under (a) or (b): nothing; the map's § "What the examples cover that the module tests do
      not" is answered in `AGENTS.md` by pointing at the fifteen per-front examples

## Gate

- [ ] `zig build test-libs` — `emilia-test` at 1 + the helper tests on both rows; the fifteen
      (or twenty-three) examples green on both rows
- [ ] `grep -rn "jhonstart\|rakun\|onze" repository/emilia` empty
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/33-emilia-color-palette`; no push, no merge — landing is the maintainer's step

## Blast radius

None outside emilia. `emilia-card`'s change removes the only cross-library `path` dependency in
the emilia workspace; `02-packaging` § 6's example rule then holds without exception here.

## Notes

- Named after the lowest front number whose test layer it carries; the front is emilia's test
  member and examples, not the palette.
- The helper set is deliberately the smallest that satisfies the packaging rule unless the
  maintainer asks for the map; a helper nobody calls is a surface to keep green for nothing.
