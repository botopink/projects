# Front 12 — language tests: every area front's cell exists and passes, the suite tolerates nothing

**Priority:** medium · **State:** partial: step 1 box 1, step 2 box 2, steps 3 and 4 on feat; step 1
box 2 and step 2 box 1 open
**Depends on:** area fronts with missing cells (`02-erlang` step 4 with `05-wasm`; `01-checker` step 6
with `04-js` step 6) · the landing's `scripts/gate.sh --cold` (`00-gate/114`)
**Owns:** `repository/botopink-lang/tests/language/**` — cells, their `.out` / `.expect` / `.exit` /
`.targets`, `AGENTS.md`, `run.sh`'s report (per-target line) and its `all)` line
**Does not touch:** compiler sources, `libs/std/**`, `examples/**`, snapshot dirs, `build.zig`,
`scripts/**`, rest of `run.sh`. A failing cell stays red until its owning front lands the fix —
**never** fixed here, never tolerated (no list).

## Goal

`run.sh --target all` (commonJS, erlang, wasm, beam) green with every owed cell, each proved able to
fail on the parent binary; `--cold` gate needs only the pre-existing tool set.

## The suite at feat

| Kind | What a cell is | Runs on | `.bp` / dirs |
|---|---|---|---|
| `test/` | `test "…" { assert … }` blocks | commonJS, erlang, beam (`botopink test` refuses wasm) | 68 |
| `run/` | whole program; stdout (and exit status with a `.exit`) is the assertion | commonJS, erlang, wasm, beam | 234 (19 `.targets`, 32 `.<target>.expect`, 2 `.exit`) |
| `reject/` | must not compile; `.expect` names code and location | once (`check` is target-independent) | 239 |
| `modules/` | whole project with its own `botopink.json` | commonJS, erlang, wasm, beam | 89 |

`expected-failures.txt` deleted (decision 154). Counts: `ls tests/language/<kind>/*.bp | wc -l`
(`modules/`: `ls -d modules/*/`).

## Done

Step 1 box 1 beam in `--target all` (00-gate/111); 03's by-hand note gone · 2 box 2
`run/try_in_for_writing_var` pins T10 · 3 `tests/language/AGENTS.md` names no shape that parses,
counts with commands, owner rule names this milestone's fronts · 4 C-06/C-07 bookkeeping: C-06's RUN
LOGs verified, C-07's `run/` and `test/` cells run on beam (`botopink test --target beam`); C-06's
stale `KNOWN` note is `07-residuals` step 5's · host-locale question answered by the program setting
`standard_io` (02 step 5, 03 step 6).

## Open

### Step 1 — `--cold` with the pre-existing tool set (box 2)

Suite half holds: `env -i HOME=… LANG=C.UTF-8 PATH=/usr/bin:/bin:<wasmtime>` runs four targets green
(node, erl, erlc, wasmtime — no zig), stated in `AGENTS.md` § The targets.

- [ ] `scripts/gate.sh --cold` green on a runner with the pre-existing tool set (the landing run)

### Step 2 — the owner rule for the area fronts' cells (box 1)

Owner rule: `../README.md` § Rules (`tests/language/AGENTS.md` § Who adds a cell). Every listed cell
exists at feat but two:

| Cell | Front | Row |
|---|---|---|
| `run/array_unique` | `02-erlang` step 4 (`05-wasm` step 1 for wasm) | C-35 |
| `run/throw_in_case_arm_result` | `01-checker` step 6 (`04-js` step 6) | row 29 |

- [ ] both cells exist at the close and pass on every target they declare

**Gate:** standard (fronts.md § Gate) + `tests/language/AGENTS.md` updated in the same commit as any
cell or owner-row change

## Notes

- **Tests describe the language, not today's compiler:** a wrong scenario stays as written and red,
  until the owing front's fix or a deleting decision.
- `test/case_arrow_arms.bp` = transition guard beside `test/case_arms.bp` (both arm forms parse);
  C-14's answer (`07-residuals` step 9) is how removal would be noticed.
- Cells needing a git dependency stay out (`zig build test-libs`' job); no network here.
