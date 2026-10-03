# Front 12 — language tests: every area front's cell exists and passes, the suite tolerates nothing

**Priority:** medium · **State:** partial: step 1 box 1, step 2 box 2, steps 3 and 4 on feat; step 1
box 2 and step 2 box 1 open
**Depends on:** the area fronts whose cells are missing (`02-erlang` step 4 with `05-wasm`;
`01-checker` step 6 with `04-js` step 6) · the landing's `scripts/gate.sh --cold` run (`00-gate/114`)
**Owns:** `repository/botopink-lang/tests/language/**` — the cells, their `.out` / `.expect` /
`.exit` / `.targets` files, `AGENTS.md`, and `run.sh`'s report (the per-target line) and its `all)`
line
**Does not touch:** any compiler source, `libs/std/**`, `examples/**`, any snapshot directory,
`build.zig`, `scripts/**`, the rest of `run.sh`. A cell that fails is red until the front that owns
the fix lands it — **never** fixed here, never tolerated (the suite keeps no list).

## Goal

`run.sh --target all` (commonJS, erlang, wasm, beam) is green with every cell the area fronts owe,
each proved able to fail on the parent binary, and the `--cold` gate needs no tool beyond the
pre-existing set.

## The suite at feat

| Kind | What a cell is | Runs on | `.bp` / dirs |
|---|---|---|---|
| `test/` | `test "…" { assert … }` blocks | commonJS, erlang, beam (`botopink test` refuses wasm) | 68 |
| `run/` | a whole program; stdout (and, with a `.exit`, the exit status) is the assertion | commonJS, erlang, wasm, beam | 234 (19 `.targets`, 32 `.<target>.expect`, 2 `.exit`) |
| `reject/` | must not compile; `.expect` names the code and the location | once (`check` is target-independent) | 239 |
| `modules/` | a whole project with its own `botopink.json` | commonJS, erlang, wasm, beam | 89 |

`expected-failures.txt` is deleted (decision 154). Counts: `ls tests/language/<kind>/*.bp | wc -l`
(`modules/`: `ls -d modules/*/`).

## Done

- Step 1, box 1 — beam in `--target all` (00-gate/111); 03's "run `--target beam` by hand" note gone
- Step 2, box 2 — `run/try_in_for_writing_var` pins T10
- Step 3 — `tests/language/AGENTS.md` names no shape that parses; counts with their commands; the owner rule names this milestone's fronts
- Step 4 — C-06/C-07 bookkeeping: C-06's RUN LOGs verified, C-07's `run/` cells and `test/` cells run on beam (`botopink test --target beam`); C-06's stale `KNOWN` note is `07-residuals` step 5's
- The host-locale question — answered by the emitted program setting `standard_io` (02 step 5, 03 step 6)

## Open

### Step 1 — `--cold` with the pre-existing tool set (box 2)

The suite's half holds: `env -i HOME=… LANG=C.UTF-8 PATH=/usr/bin:/bin:<wasmtime>` runs the four
targets green (node, erl, erlc, wasmtime — no zig, nothing new), and `AGENTS.md` § The targets says so.

- [ ] `scripts/gate.sh --cold` green on a runner with the pre-existing tool set (the landing run)

### Step 2 — the owner rule for the area fronts' cells (box 1)

Every cell an area front adds lands in that front's commit, one file per cell, proved able to fail
on the parent binary (`tests/language/AGENTS.md` § Who adds a cell). At feat every listed cell
exists but two:

| Cell | Front | Row |
|---|---|---|
| `run/array_unique` | `02-erlang` step 4 (`05-wasm` step 1 for wasm) | C-35 |
| `run/throw_in_case_arm_result` | `01-checker` step 6 (`04-js` step 6) | row 29 |

- [ ] both cells exist at the close and pass on every target they declare

**Gate:** standard (fronts.md § Gate) + `tests/language/AGENTS.md` updated in the same commit as any
cell or owner-row change

## Notes

- **Tests describe the language, not today's compiler.** A scenario the compiler gets wrong stays
  as written and is red: a cell that cannot pass lands with the fix of the front that owes it, or a
  decision deletes it.
- `test/case_arrow_arms.bp` is the transition guard beside `test/case_arms.bp`: both arm forms
  parse; C-14's answer (`07-residuals` step 9) is how a removal would be noticed.
- A cell that needs a git dependency stays out — `zig build test-libs`' job; this suite must not
  need the network.
</content>
</invoke>
