# Front 111 — gate-beam-and-targets: the beam build ships its sidecars, beam joins `--target all`, every narrowing is honoured and audited, `expected-failures.txt` is deleted

**Priority:** critical — the two remaining expected-failure lines, a target no gate stage runs, and
a `modules/` cell whose manifest `targets` the runner ignores (the wasm red of stage 9 ran on a
target the cell excludes).
**Depends on:** `110` (its wasm line deleted; its link fix landed — `modules/import_same_name_from_two_packages`
is then green on wasm *and* excluded from it by manifest, two independent truths) · `112` (the
`tests/language` reformat landed — this front's new cells are written formatted, and the tree is in
`TREES`). `115` starts from this front's `run.sh`.
**Owns:** `modules/compiler-cli/src/cli/{build,run,test_cmd,libs}.zig` (the beam path of sidecar
shipping) · `modules/compiler-core/src/codegen/beam_asm.zig`, `codegen/beam/**` (the
`__bp_load_siblings` twin) · `tests/language/run.sh` · `tests/language/expected-failures.txt`
(deleted) · the 17 `tests/language/run/*.targets` · every `tests/language/modules/*/botopink.json`
`targets` · `tests/language/AGENTS.md` · beam snapshots the sidecar loader changes
(`modules/compiler-core/snapshots/codegen/beam/**`).
**Does not touch:** `wat.zig` (110's); `erlang.zig` (`../../01-compiler/02-erlang`'s — the erlang
loader `:2405-2415` is read, not edited); `scripts/format-check.sh` (112's); `scripts/test-libs.sh`,
`lib-test-runner/**` (113's); `scripts/gate.sh` (115's, after this front).

---

## Problem

```
$ bash tests/language/run.sh --target beam modules/erlang_host_sidecar_shipped
expected [beam] modules/erlang_host_sidecar_shipped — 03-beam: … the beam build ships no host module: the `.S` output calls `lt_greeter:hello/1` and the run dies with `undef`
language tests: 382 passed, 2 expected failures, 0 failed
$ bash tests/language/run.sh --target all        # beam is not run: run.sh:155  all) targets=(commonJS erlang wasm)
```

Measured at the open (`lang_beam.txt`, `par/6.out`): beam `382 / 2 expected / 0 failed`; `all` =
three targets, `1244 / 1 / 1`. The two beam lines are exercised by no gate stage.

## Current state

| Item | Where | Measured |
|---|---|---|
| EF-1, EF-2: the beam build ships no `.erl` sidecar | `cli/build.zig:390-407` — `shipMjsSidecars` under `target == .commonJS`, `shipErlSidecars` under `target == .erlang`, nothing for `.beam`; `libs.zig:1063` `shipErlSidecars` is erlang-only; `run.zig`, `test_cmd.zig` the same; `erlang.zig:2405-2415` emits `__bp_load_siblings` for the erlang module and `beam_asm.zig` has no twin | `modules/erlang_host_sidecar_shipped` (`lt_greeter:hello/1` undef), `modules/erlang_sidecar_named_like_a_module` (`text:shout/1` undef) — `expected-failures.txt:236-237` |
| beam not in `--target all` | `run.sh:148-155` ("scheduling, not doubt: front 13's policy 3 … do it as 13's closing step" — 13 is closed) | `all) targets=(commonJS erlang wasm)` |
| `test/` cells never on wasm/beam; `modules/` test-kind cells never on wasm/beam | `run.sh:410-415`, `:426-434` | `botopink test` refuses wasm and beam — structural today, stays until the CLI runs tests there (not this milestone) |
| 17 `run/<name>.targets` narrowings | `run.sh:416-425` honours them | commonJS+erlang: `async_block_all_of`, `external_host_record`, `external_method_on_host_record`, `std_default_fn_in_a_std_module` · erlang+beam: `beam_memory_ets`, `beam_memory_persistent_term`, `beam_memory_process_dict`, `external_template_refused_on_beam`, `host_unknown_parameter` · commonJS+erlang+beam: `behavior_method_host_value`, `external_template_escaped_quote`, `std_template_host_fns_across_modules` · erlang: `external_erlang_host_module_missing`, `host_erlang_task_result` · commonJS: `host_array_slice_without_start`, `host_node_task_result`, `task_throw_resolves_error` |
| a `modules/` cell's manifest `targets` ignored | `run.sh:426-434` | `import_same_name_from_two_packages/botopink.json` declares `["commonJS","erlang"]`; the cell ran on wasm |

## Mechanism

Sidecars: `botopink build --target erlang` copies every `#[@External.Erlang("host", …)]` module's
`host.erl` beside the emitted modules (`out/erl/`) and the erlang program's `__bp_load_siblings`
compiles and loads them at start; the beam path writes `.S` files that `erlc +from_asm` assembles
and calls the same `host:fn/N`, which nothing shipped or loaded. The fix is the same shipping call
under `.beam` (into `out/beam/`) and a loader twin in the assembled module — or `run.sh`'s beam
runner compiling the sidecars the way `botopink run --target erlang` does, if the beam program's
entry is what loads siblings. Both cells then print what erlang prints (`hello, sidecar`,
`HELLO, SIDECAR`).

Targets: `run.sh` decides a cell's targets by cell kind and `.targets`; the manifest is read by
`botopink` for the build but not by `run.sh` for the matrix. gate-d: both are honoured and both are
audited.

## Steps

### Step 1 — the beam build ships every `.erl` sidecar the erlang build ships

`cli/build.zig:390-407`: the `.erlang` arm becomes `.erlang, .beam` with the target's subdirectory
(`out/beam/`); `libs.zig:1063` `shipErlSidecars` takes the target's directory (it already takes
`erl_dir`); `run.zig` and `test_cmd.zig` the same for `botopink run --target beam`. `beam_asm.zig`
emits the `__bp_load_siblings` twin of `erlang.zig:2405-2415` (compile-and-load every `.erl` beside
the module at start, in the assembled module's `_botopink_main`/0 or the module body), *or* the
beam runner in `run.sh` compiles `out/beam/*.erl` with `erlc` before `erl` — choose the first: a
built beam program must run outside the test runner, and the toolchain row "a built erlang
program cannot load its `.erl` sidecars outside test mode" (`../../01-compiler/README.md` § 26)
says the loader must not be test-only on either target.

**Acceptance:**
- [ ] `bash tests/language/run.sh --target beam modules/erlang_host_sidecar_shipped modules/erlang_sidecar_named_like_a_module` → both `passed`, stdout `hello, sidecar` / `HELLO, SIDECAR`
- [ ] `botopink build --target beam` in each cell writes `out/beam/lt_greeter.erl` (`text.erl`) beside the `.S`; `botopink run --target beam` runs it with no `undef`
- [ ] the beam snapshots that gain the loader are re-recorded and listed; `scripts/beam_export_audit.sh` green (488 + the new functions)
- [ ] the two lines deleted from `expected-failures.txt`

### Step 2 — beam joins `--target all`

`run.sh:155` → `all) targets=(commonJS erlang wasm beam)`; the `:148-153` comment deleted; the
`erlc`/`erl` pre-flight (`:159-163`) now fires on `all` — a machine without them fails the run
(never skips beam: decision 67). `tests/language/AGENTS.md` § the targets updated (`:1319`'s stale
decision-29 row and the "Open rows 1..9" bullet — `../../01-compiler/12-language-tests` names them —
are corrected here since this front owns the file this milestone).

**Acceptance:**
- [ ] `bash tests/language/run.sh --target all` → `language tests: 1630 passed, 0 expected failures, 0 failed` (1246 + 384 at the open's cell count; re-derive after 110 and step 5)
- [ ] `zig build test-language` (stage 9) runs `all` — the four targets — and `scripts/gate.sh --cold` stage 9 is green with beam in it

### Step 3 — `modules/` cells honour their manifest `targets` (gate-d)

`run.sh:426-434`: a `modules/<cell>/botopink.json` with `"targets"` narrows the cell the way
`.targets` narrows a `run/` cell; a `modules/` cell without `targets` runs on every target its kind
allows. `import_same_name_from_two_packages` then runs on commonJS and erlang — and its manifest
is audited (step 5): the cell has no host binding, so the narrowing is *not* structural and the
`targets` line is deleted; the cell runs on wasm (green after 110) and beam.

**Acceptance:**
- [ ] a `modules/` cell with `"targets": ["erlang"]` and a host-only binding runs on erlang alone (a new cell pins it); one without `targets` runs on four
- [ ] `grep -l '"targets"' tests/language/modules/*/botopink.json` lists only cells step 5's audit keeps

### Step 4 — `expected-failures.txt` is deleted (gate-b)

With 110's line and step 1's two lines gone the file has no live line. Delete it; delete `run.sh`'s
reader (the tally line, the three key shapes, the `\|` escape, the "expected" verdict); the
`AGENTS.md` § Status quote of the tally line goes with it. A red language cell is red.

**Acceptance:**
- [ ] `test ! -e tests/language/expected-failures.txt`; `grep -c "expected-failures" tests/language/run.sh tests/language/AGENTS.md scripts/*.sh .github/workflows/test.yml` = 0
- [ ] `run.sh` prints `language tests: <n> passed, <m> failed` — two numbers

### Step 5 — the 17 `.targets` and the modules/ manifests audited (gate-d)

For each narrowing: `botopink build --target <excluded>` in the cell must refuse with a host-binding
error (`has no #[@External.<Target>]`, `external_missing`, "host module … missing") — the reason a
cell *structurally* has no row there. Anything else is a gap: the `.targets` file is deleted, the
cell runs there, and if it is red the defect is a compiler row (`../../01-compiler/` — 05-wasm for
wasm, 03-beam for beam) that this front reports as a blocker rather than re-narrowing. Expected
from the names alone (verify by running): `async_block_all_of` and `std_default_fn_in_a_std_module`
exclude wasm and beam for no host reason — likely wasm/beam gaps; the `beam_memory_*` and
`external_template_refused_on_beam` cells are host-shaped; the `host_*`/`task_*` cells are
host-shaped. `run.sh` then enforces the audit on every run: a `.targets` file (or manifest
`targets`) whose excluded target does not refuse on a host binding fails the run naming the cell —
the audit is the runner's, not a one-time sweep.

**Acceptance:**
- [ ] a table in this README: cell · excluded targets · the refusal line per excluded target, for all 17 + the modules/ cells
- [ ] `run.sh` fails a synthetic cell whose `.targets` excludes a target it builds on (a `reject`-style self-test of the runner, `tests/language/run.sh --self-test` or a `compiler-cli/tests/*.sh` contract)
- [ ] every deleted narrowing's cell green on the target it now runs on, or a named compiler row and this front's `status.md` line saying so

## Gate

- [ ] `zig build test` from a cold runtime cache, green
- [ ] `bash tests/language/run.sh --target all` → `0 failed`, four targets, no expected column
- [ ] `scripts/beam_export_audit.sh` green; `scripts/snap_audit.sh --mode=runtime-parity` green
- [ ] `scripts/gate.sh --cold` green in this front's worktree (stage 9 now runs beam)
- [ ] `modules/compiler-cli/AGENTS.md`, `modules/compiler-core/src/codegen/AGENTS.md`, `tests/language/AGENTS.md` updated in the same commit
- [ ] commit on `fix/gate-beam-and-targets` in `repository/botopink-lang`; no push, no merge

## Blast radius

- `../../01-compiler/03-beam` and `26-cli-tooling` start from this landing (`beam_asm.zig`,
  `cli/**`, `libs.zig`); their *Does not touch until 00-gate lands* rows EF-1/EF-2 close.
- `../../01-compiler/12-language-tests` step 1 ("beam joins `--target all`") closes here; its
  `--cold` no-new-tool check stays 12's.
- `115` measures stage 9 with four targets: +384 cells (~28 s serial at the open) counted in the
  budget, never narrowed back.
- Stage 9's wall clock grows; nothing is skipped to pay for it (decision 67).

## Notes

- `test/` cells and `modules/` test-kind cells stay off wasm and beam because `botopink test`
  refuses those targets — a CLI capability, not a tolerance; the day the CLI runs tests there,
  `run.sh:410-415,426-434` lose their arms and no line in any file has to move.
