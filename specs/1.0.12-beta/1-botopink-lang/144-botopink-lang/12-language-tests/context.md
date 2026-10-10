# Front 12 — language tests: every area front's cell exists and passes, the suite tolerates nothing

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s2 → B-22 · s1 → B-29. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium · **State:** partial: step 1 box 1, step 2 box 2, steps 3 and 4 on feat; step 1
box 2 and step 2 box 1 open
**Depends on:** area fronts with missing cells (`01-checker` step 6 with `04-js` step 6) · the landing's `scripts/gate.sh --cold` (`00-gate/114`)
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

## Notes

- **Tests describe the language, not today's compiler:** a wrong scenario stays as written and red,
  until the owing front's fix or a deleting decision.
- `test/case_arrow_arms.bp` = transition guard beside `test/case_arms.bp` (both arm forms parse);
  C-14's answer (`07-residuals` step 9) is how removal would be noticed.
- Cells needing a git dependency stay out (`zig build test-libs`' job); no network here.
