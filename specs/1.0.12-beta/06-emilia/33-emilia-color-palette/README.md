# Front 33 — emilia test member and examples: a usable `emilia-test`, an emilia-only `emilia-card`, fifteen READMEs (carries the test layer of 1.0.10's 35–48 · 54–59)

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

[`examples/`](./examples/): the worked helper shape (a submodule and its consumer with `@src()`).

## Mechanism

`emilia-card` prints what `emilia(tokens)` and `flush()` answer for the same three token lists, no
`Element`.

## Done

Step 2 `examples/emilia-card` depends on `emilia` only (`botopink.json`'s `dependencies` and
`description` name no other library; `src/main.bp` imports `emilia`, `flush`, `Token` and nothing
else) and prints the three class names and the flushed document; 4 tests pin the three names as
literals (`e_486b0b4f`, `e_b63a108`, `e_74f3ae56`), the repeat collapse, the utilities layer as one
literal and a second `flush()` holding no rule — `botopink test` 4 passed, 0 failed on commonJS and on
erlang, `botopink build` exit 0 on both; a planted wrong literal reddens two of them. The output is
documented in its `README.md`. `find repository/emilia/examples -maxdepth 2 -name README.md | wc -l`
is 15, each naming the Tailwind section it mirrors (with the upstream pages) and the fronts it
exercises; `grep -rn "jhonstart\|rakun\|onze" repository/emilia/examples` is empty. Reported to
`00-gate/114` step 8 box 3, which removed the dead jhonstart checkout from emilia's `test.yml`.

## Open

### Step 1 — the helpers

→ 20-snap (front 135) step 4

### Step 2 — `emilia-card` emilia-only, and the fifteen READMEs

Done (§ Done). `emilia-card`'s repeat-collapse test moves onto `emilia-test`'s helper with `20-snap`
step 4.

### Step 3 — the module-level suites

→ 20-snap (front 135) step 4

### Step 4 — the eight examples

→ 20-snap (front 135) step 4

**Gate:** standard (fronts.md § Gate) + the fifteen examples green on both rows ·
`grep -rn "jhonstart\|rakun\|onze" repository/emilia/examples` empty
