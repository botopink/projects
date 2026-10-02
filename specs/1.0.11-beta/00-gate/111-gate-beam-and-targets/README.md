# Front 111 — gate-beam-and-targets: the beam build ships its sidecars, beam joins `--target all`, every narrowing is honoured and audited, `expected-failures.txt` is deleted

**Priority:** critical — the two beam expected-failure lines, a target no gate stage ran, and a
`modules/` cell whose manifest `targets` the runner ignored.
**Depends on:** `110` (its wasm line; the link fix) · `112` (the `tests/language` reformat). `110`'s
last step waits on `ck-host`, and so does this front's step 4. `115` starts from this front's
`run.sh`.
**Owns:** `modules/compiler-cli/src/cli/{build,run,test_cmd,libs}.zig` (the beam path of sidecar
shipping) · `modules/compiler-core/src/codegen/beam_asm.zig`, `codegen/beam/**` ·
`tests/language/run.sh` · `tests/language/expected-failures.txt` · the 17
`tests/language/run/*.targets` · every `tests/language/modules/*/botopink.json` `targets` ·
`tests/language/AGENTS.md` · the beam snapshots the emitter change re-records
(`modules/compiler-core/snapshots/codegen/{beam,wat}/beam/**`).
**Does not touch:** `wat.zig` (110's); `erlang.zig`, `commonJS.zig` (read, not edited — two rows
handed to them below); `scripts/format-check.sh` (112's); `scripts/test-libs.sh`,
`lib-test-runner/**` (113's); `scripts/gate.sh`, `build.zig` (115's — § Left for other owners).

---

## Current state

Measured in the front's worktree, compiler at `feat` + 110 (steps 1–2) + 112 + 114, OTP 28, node
v25, 16 CPUs under a load of 60–80 (other threads' suites).

```
$ bash tests/language/run.sh --target all
self-test: 8 malformed or unbacked narrowings refused, 3 backed ones scheduled on their declared targets alone
expected-failures.txt: 1 lines, 1 exercised by --target commonJS,erlang,wasm,beam — by target: wasm 1; …
expected [wasm] run/external_wrapper_keeps_refusal.bp — 05-wasm: … decisions-pending ck-host
narrowings: 30 exclusions audited — each stands on a host binding the target does not have
language tests: 1474 passed, 1 expected failures, 0 failed          # exit 0

$ bash tests/language/run.sh --target beam
narrowings: 3 exclusions audited — each stands on a host binding the target does not have
language tests: 393 passed, 0 expected failures, 0 failed           # exit 0
```

Before this front: `all` = three targets, `1251 / 1 / 0`; `--target beam` = `383 / 2 / 1` (the
third was `run/array_spread_literal`, red on beam with no line).

| Item | State |
|---|---|
| the beam build ships `.erl` sidecars; the assembled entry loads them | landed — step 1 |
| `botopink run --target beam` runs the program | landed — step 1 (it printed an `erlc +from_asm` hint and exited 0) |
| beam in `--target all` | landed — step 2 |
| a `modules/` cell's manifest `targets` honoured | landed — step 3 |
| every narrowing audited on every run; the runner proves its own audit | landed — step 5 |
| `expected-failures.txt` and its reader deleted | **open** — step 4, one `wasm |` line left, 110's, on `ck-host` |

## Mechanism

**Sidecars.** `libs.shipErlSidecars` reads the host modules out of either emitted text
(`HostText`): `host:fn(…)` in erlang source, `{extfunc, host, fn, N}` in BEAM assembly. `build.zig`
calls it for `.erlang` and `.beam` with the target's own directory (`out/erl/`, `out/beam/`), so a
host module that is neither shipped nor on the Erlang code path is the same located refusal on
both. `beam_asm.zig` emits `'__bp_load_siblings'/0` + `'-bp_load_sibling-'/1` into the entry of a
build in which some module declares a BEAM host binding of its own (`buildBindsBeamHost`: a
`declare fn`, or a `type` or one of its methods, under `#[@External.Erlang]` / `#[@External.Beam]`
— the prelude's behavior bindings, which name OTP alone, are not read): first thing in
`'_botopink_main'/0` it compiles and loads every `.erl` beside the module's own `.beam`
(`code:which/1` → `<dir>/*.erl` → `code:ensure_loaded/1`, else `compile:file/2` +
`code:load_binary/3`); a module that does not compile refuses the run (`halt(1)`, the compiler's
diagnostic on stderr). `run.zig` `runBeam` assembles every `.S` beside itself
(`erlc +from_asm -o out/beam`) and runs `erl -noshell -pa out/beam -eval "'<entry>':main([]),
halt()."` — it compiles no sidecar; the program does, so it runs the same way outside the command.

**Targets.** `run.sh` § the targets of a cell: a cell runs on every target its kind has unless it
narrows itself (`run/<name>.targets`, or `"targets"` in a `modules/<name>/botopink.json`); for each
target of the run a cell excludes, `botopink build --target <t>` in the cell must refuse the program
on a host binding (`` has no `#[@External.<Target>(…)]` `` · `std-unsupported-on-target:`). A target
the build accepts, or refuses for another reason, fails the run naming the cell; so does a narrowing
that names an unknown target, a target the kind does not have, a target twice, or every target of
the kind. `--self-test` runs a synthetic suite through the same script (`--suite`) and requires
each refusal's line; a whole run of the suite starts with it.

## Steps

### Step 1 — the beam build ships every `.erl` sidecar the erlang build ships

**Acceptance:**
- [x] `bash tests/language/run.sh --target beam --only modules/erlang_host_sidecar_shipped --only modules/erlang_sidecar_named_like_a_module` → `2 passed, 0 expected failures, 0 failed`; `botopink run --target beam` in each prints `hello, sidecar` / `HELLO, SIDECAR`
- [x] `botopink build --target beam` in each cell writes `out/beam/lt_greeter.erl` (`out/beam/text.erl`) beside the `.S`; `botopink run --target beam` exits 0 with no `undef`. Also run by hand: a sidecar that does not compile → `error: …/out/beam/lt_greeter.erl does not compile - refusing to run`, exit 1; a sidecar compiled by hand and its `.erl` removed → `hello, sidecar`; the sidecar deleted from `src/` → the erlang build's located refusal, exit 1
- [x] the beam snapshots that gain the loader are re-recorded, each with an unchanged RUN LOG — 13 under `snapshots/codegen/beam/beam/` and their 13 twins under `…/wat/beam/`: `external_1_arg_host_expression_declare_fn_renders_at_the_call_site`, `external_a2_chained_host_call_renders_verbatim`, `external_a2_method_on_global_template_keeps_receiver_bound`, `external_a3_result_template_owned_declare_fn`, `external_a_host_backed_method_on_a_local_type_is_a_method_of_the_type`, `external_a_host_backed_method_on_an_imported_type_is_answered_by_its_owner`, `external_a_host_backed_method_with_no_binding_for_the_backend_is_refused_at_the_call`, `external_an_imported_host_backed_declare_fn_is_wrapped_by_its_owner`, `external_call_emits_module_symbol`, `external_global_math`, `external_import_binds_symbol`, `external_target_mixed_with_external_in_one_decl`, `external_target_template_equivalent_to_external_target_template`. `scripts/beam_export_audit.sh` → `490/490 modules assembled`; `scripts/snap_audit.sh --mode=runtime-parity` → `1431 pairs, 0 differing or missing`
- [x] the two `beam |` lines deleted from `expected-failures.txt`

### Step 2 — beam joins `--target all`

`run.sh`: `all) targets=(commonJS erlang wasm beam)`; the `erlc`/`erl` pre-flight fires on `all`
(a machine without them fails the run, never skips beam); `exec_run` is `botopink run` on every
target. `zig build test-language` runs `run.sh` with its default, so stage 9 runs the four targets
with no change to `build.zig` or `gate.sh`.

Three beam reds met on the way, each a `beam_asm.zig` defect, fixed and pinned by the cell that
found it:

| Cell | On beam before | Fix |
|---|---|---|
| `run/array_spread_literal` | `2 1 null 1 null 0` at exit 0 — a trailing spread written as a bare name (`[1, 2, ..rest]`) was dropped | `lowerArrayLit` reads `spread` as well as `spreadExpr` |
| `run/external_host_record` | `badarith` — `+` over two host-built maps | `'__bp_adopt'/3` (`hostAdoption`, `ensureAdoptHelper`): a host answer is adopted into the record its declaration names, at `lowerExternalCall` and in the `pub` wrapper — the erlang backend's helper, in assembly |
| `run/external_method_on_host_record` | `badarg` from `element/2` on a map, then `length/1` on a record — an untyped lambda-parameter receiver called the FILE's `at/2` | the adoption above; and a method exactly one type of the file declares takes an untyped receiver's call (`soleOwnTypeOfMethod` — erlang's `method_owners` rule) |

**Acceptance:**
- [x] `bash tests/language/run.sh --target all` → `language tests: 1474 passed, 1 expected failures, 0 failed` on four targets (the `1` is step 4's)
- [ ] `zig build test-language` and `scripts/gate.sh --cold` stage 9 green with beam in it — `zig build test-language` measured green here; `gate.sh --cold` is the landing step (it is red at stage 8 until 113 lands)

### Step 3 — `modules/` cells honour their manifest `targets` (gate-d)

Measured before changing anything: 47 of the 59 manifests carried `"targets"` and none of the
lists was a claim — `["commonJS", "erlang", "wasm"]` in 33 cells and `["commonJS", "erlang"]` in
14, written when the suite had three targets, while the runner ignored the field and every one of
those cells ran (and passed) on wasm and on beam. Honoured as written the field would have taken
beam away from 33 passing cells and the wasm refusal pins (`wasm.expect`) away from two. So the 47
lists are deleted, a project that must be refused on a target keeps saying so with `<t>.expect`,
and the field means what `.targets` means.

**Acceptance:**
- [x] a `modules/` cell with `"targets"` and a host-only binding runs on its declared targets alone: `modules/manifest_targets_host_binding` (`["erlang", "beam"]`, `#[@External.Erlang("erlang", "abs")]`) → `2 passed`, `2 exclusions audited`; the self-test's `modules/manifest_backed` asserts the same on every whole run. A cell without `"targets"` runs on four
- [x] `grep -l '"targets"' tests/language/modules/*/botopink.json` → `modules/manifest_targets_host_binding/botopink.json`, the one the audit keeps

### Step 4 — `expected-failures.txt` is deleted (gate-b, decision 154) — done

The file had no live line once 110 step 3 closed wasm's (decision 146). It is deleted, and with it
`run.sh`'s reader: the header block, the parser of the three key shapes and the `\|` escape, the
tally line, the `expected` verdict. `run.sh` reports `<target>\t<key>\t<ok|fail|audit>` lines and
nothing else; the self-test's required tally is `13 passed, 11 failed`. `tests/language/AGENTS.md`
has § A red cell is red where it had the file's section, and its record of earlier fronts' tallies
(each a quote of the three-number line and of the file's count) is gone. The lines that named the
file elsewhere — `scripts/gate.sh` (header, stage 9), `scripts/AGENTS.md` (the stage list),
`.github/workflows/test.yml` (the `test-language` step's comment), `build.zig` (the step's
comment), the root `AGENTS.md` (stage 9), `codegen/AGENTS.md`, `codegen/wat/AGENTS.md`,
`codegen/tests/control_flow.zig` and five cells' header comments — say what is true now. A red
language cell is red.

**Acceptance:**
- [x] `test ! -e tests/language/expected-failures.txt`; `grep -c "expected-failures" tests/language/run.sh tests/language/AGENTS.md scripts/*.sh .github/workflows/test.yml build.zig AGENTS.md docs.md README.md` = 0 in every file
- [x] `bash tests/language/run.sh --target all` prints `language tests: 1483 passed, 0 failed` — two numbers, four targets; `bash tests/language/run.sh --self-test` exits 0

### Step 5 — the 17 `.targets` and the modules/ manifests audited (gate-d)

Each narrowing, each excluded target, and what `botopink build --target <t>` answers in the cell
(first `error` line; every one exits 1):

| Cell | Runs on | Excluded | The refusal |
|---|---|---|---|
| `run/async_block_all_of` | commonJS erlang beam | wasm | ``std-unsupported-on-target: std/async has no `@external` for target 'wasm' (for delay, race, raceOf)`` |
| `run/beam_memory_ets` | commonJS erlang beam | wasm | the same `std/async` line |
| `run/beam_memory_persistent_term` | commonJS erlang beam | wasm | the same `std/async` line |
| `run/beam_memory_process_dict` | erlang beam | wasm | the same `std/async` line |
| | | commonJS | none — exit 0; the cell declares `#[@BeamMemory.ProcessDict]` (§ Notes, decision 43) |
| `run/behavior_method_host_value` | commonJS erlang beam | wasm | `` `makeGreeter` has no `#[@External.<Target>(…)]` for the wasm backend `` |
| `run/external_erlang_host_module_missing` | erlang beam (both by `.expect`) | commonJS | `` `total` has no `#[@External.<Target>(…)]` for the node backend `` |
| | | wasm | `` `total` has no `#[@External.<Target>(…)]` for the wasm backend `` |
| `run/external_host_record` | commonJS erlang beam | wasm | `` `hostPoint` has no `#[@External.<Target>(…)]` for the wasm backend `` |
| `run/external_method_on_host_record` | commonJS erlang beam | wasm | `` `Pair.at` has no `#[@External.<Target>(…)]` for the wasm backend `` |
| `run/external_template_escaped_quote` | commonJS erlang beam | wasm | `` `say` has no `#[@External.<Target>(…)]` for the wasm backend `` |
| `run/external_template_refused_on_beam` | erlang beam | commonJS | `` `moduleNamed` has no `#[@External.<Target>(…)]` for the node backend `` |
| | | wasm | `` `moduleNamed` has no `#[@External.<Target>(…)]` for the wasm backend `` |
| `run/host_array_slice_without_start` | commonJS | erlang · wasm · beam | `` `copyAll` has no `#[@External.<Target>(…)]` for the erlang / wasm / beam backend `` |
| `run/host_erlang_task_result` | erlang beam | commonJS | `` `hostDouble` has no `#[@External.<Target>(…)]` for the node backend `` |
| | | wasm | `` `run` calls `hostDouble`, which has no `#[@External.<Target>(…)]` for the wasm backend `` |
| `run/host_node_task_result` | commonJS | erlang · beam | `` `hostDouble` has no `#[@External.<Target>(…)]` for the erlang / beam backend `` |
| | | wasm | `` `run` calls `hostDouble`, which has no `#[@External.<Target>(…)]` for the wasm backend `` |
| `run/host_unknown_parameter` | erlang beam | commonJS | ``std-unsupported-on-target: std/erlang.element has no `@external` for target 'node'`` |
| | | wasm | ``std-unsupported-on-target: std/erlang.element has no `@external` for target 'wasm'`` |
| `run/std_default_fn_in_a_std_module` | commonJS erlang beam | wasm | ``std-unsupported-on-target: std/encoding.percentEncode has no `@external` for target 'wasm'`` |
| `run/std_template_host_fns_across_modules` | commonJS erlang beam | wasm | ``std-unsupported-on-target: std/io/fs.exists has no `@external` for target 'wasm'`` |
| `run/task_throw_resolves_error` | commonJS | erlang · wasm · beam | `` `observe` has no `#[@External.<Target>(…)]` for the erlang / wasm / beam backend `` |
| `modules/manifest_targets_host_binding` | erlang beam | commonJS | `` `magnitude` has no `#[@External.<Target>(…)]` for the node backend `` |
| | | wasm | `` `magnitude` has no `#[@External.<Target>(…)]` for the wasm backend `` |

Thirty exclusions. What the audit changed, cell by cell:

| Cell | Was | Excluded with no host reason | Now |
|---|---|---|---|
| `run/async_block_all_of` | commonJS erlang | beam — builds, prints the `.out` | + beam, green |
| `run/host_erlang_task_result` | erlang | beam — builds, prints the `.out` | + beam, green |
| `run/std_default_fn_in_a_std_module` | commonJS erlang | beam — builds, prints the `.out` | + beam, green |
| `run/beam_memory_ets`, `run/beam_memory_persistent_term` | erlang beam | commonJS — builds, prints the `.out` (decision 43: the annotation is a no-op there and the numbers are the same) | + commonJS, green |
| `run/external_erlang_host_module_missing` | erlang | beam — refused, but for the cell's own subject (the host module is missing), which is a claim, not a narrowing | + beam, pinned by `.beam.expect` |
| `run/external_host_record`, `run/external_method_on_host_record` | commonJS erlang | beam — builds, crashed at run time | + beam, green after step 2's two fixes |
| 47 `modules/*/botopink.json` | boilerplate `"targets"` the runner ignored | — | the field deleted (step 3) |

**Acceptance:**
- [x] the table above: cell · excluded targets · the refusal line per excluded target, for the 17 `.targets` and the one narrowed `modules/` cell
- [x] `bash tests/language/run.sh --self-test` → `self-test: 8 malformed or unbacked narrowings refused, 3 backed ones scheduled on their declared targets alone`, exit 0; with the audit's refusal test replaced by `true` (a copy of the script) it prints `self-test: the report lacks: …` and exits 1. A whole run of the suite starts with it
- [x] every deleted narrowing's cell green on the target it now runs on (the second table)

## Gate

- [x] `zig build test` from a cold runtime cache — exit 0
- [x] `bash tests/language/run.sh --target all` → `0 failed`, four targets
- [ ] … no expected column — step 4
- [x] `scripts/beam_export_audit.sh` → `490/490 modules assembled`; `scripts/snap_audit.sh --mode=runtime-parity` → `1431 pairs, 0 differing or missing`
- [x] `bash scripts/format-check.sh` exit 0; `zig fmt --check modules` exit 0; `zig build test-cli` exit 0 (`cli contract: OK`, `backend-execution parity: OK`)
- [ ] `scripts/gate.sh --cold` green in this front's worktree — the landing step, after 113
- [x] `modules/compiler-cli/AGENTS.md`, `modules/compiler-cli/src/cli/AGENTS.md`, `modules/compiler-core/src/codegen/AGENTS.md`, `tests/language/AGENTS.md`, the root `AGENTS.md` (stage 9), `README.md` and `docs.md` (the Backends table: beam's runner) updated in the same change
- [ ] commit on `front/111-gate-beam-and-targets` in `repository/botopink-lang` — under a green gate, after 113

## Rows handed to other fronts

Each was found by the audit refusing a narrowing this front tried to write; neither is in a file
this front owns, and no cell stands on them.

| Row | Reproduction | Owner |
|---|---|---|
| commonJS accepts an IMPORTED host function with no node binding | `src/host.bp`: `#[@External.Erlang("erlang", "abs")] pub declare fn magnitude(n: i32) -> i32;` · `src/main.bp`: `pub mod host; import {magnitude} from "host"; pub fn main() { @print(magnitude(0 - 7)); }` → `botopink build --target commonJS` exits 0 and emits `// external fn magnitude (no node target)`; `botopink run` dies with `TypeError: magnitude is not a function`. Declared in `main.bp` itself the same function is refused (`` `magnitude` has no `#[@External.<Target>(…)]` for the node backend ``), and wasm refuses both | `01-compiler/04-js` (`commonJS.zig`) |
| erlang does not locate the same refusal | the mirror: `#[@External.Node("""Math.abs($0)""")] pub declare fn magnitude…` imported the same way → `botopink build --target erlang` answers `error: the OTP compiler refused emitted erlang — the build is not a program`; beam and wasm answer the located `` `magnitude` has no `#[@External.<Target>(…)]` `` | `01-compiler/02-erlang` (`erlang.zig`) |

## Left for other owners

- `scripts/gate.sh:36-38` (115) — the stage 9 comment says "on commonJS and erlang"; the stage itself needs no change.
- `build.zig:551-555` — the `test-language` comment says the same; the step runs `run.sh`'s default and needs no change.
- `.github/workflows/test.yml:166` (114) — names `expected-failures.txt` (step 4).
- `modules/compiler-cli/tests/cli_contract.sh` has no owner in this track and pins `build.zig`: its "build emits without running the program" row was edited here — `build --target beam` with a failing `erl` first on `PATH` now exits 1 (the host-module probe cannot run), and the erlang and the beam build each account for one allowed `erl` spawn. `mutual_recursion.sh`'s beam comment no longer says `botopink run --target beam` only writes the `.S`.

## Blast radius

- `botopink build --target beam` spawns one `erl` (the host-module probe every erlang build already
  ran): about a quarter of a second per beam build, and a beam build with no `erl` on `PATH` is
  refused. The comptime pass of a beam build already ran on `erl`.
- `botopink run --target beam` writes `.beam` files beside the `.S` under `out/beam/`.
- Stage 9 runs 220 more cells and 30 audit builds, after an eight-second self-test; under this
  machine's load the whole run measured 942 s. `115` budgets it; nothing is skipped to pay for it.
- `01-compiler/03-beam` and `26-cli-tooling` start from this landing; their EF-1/EF-2 rows are
  closed, and 03-beam's "beam adopts no host map" and "a named trailing spread" are closed with them.
- `01-compiler/12-language-tests` step 1 closes here, and the decision-29 row of its step 3 is
  struck in `tests/language/AGENTS.md`.

## Notes

- **`#[@BeamMemory]` is the one host binding the compiler does not refuse.** gate-d's test is "the
  build refuses on a host binding". `run/beam_memory_process_dict` excludes commonJS, where the
  program builds — decision 43 makes the annotation a silent no-op off the BEAM — and prints
  something else (`[5]` / `99` against the BEAM's `[0]` / `5`: one value per process is the cell's
  subject). The audit therefore accepts one more piece of evidence, read off the cell's own source:
  a cell that declares a module `var` under `#[@BeamMemory.<mode>]` may exclude commonJS and wasm,
  never erlang or beam. It is a structural rule (no list, no flag), it is exercised by the
  self-test in both directions, and one cell uses it; `test/beam_memory_noop` pins the no-op. The
  alternatives, if the maintainer reads gate-d more strictly: a per-target expected output
  (`<name>.<t>.out`), so the cell also runs on commonJS and pins decision 43's output there; or
  commonJS refusing the annotation, which decision 43 decided against.
- **The loader is emitted only where it can matter.** Every entry carrying it would have re-recorded
  219 beam snapshots (twice, for the two comptime runtimes) for programs that bind no host; the
  rule reads the build's own declarations instead, and 13 snapshots changed.
- **A sidecar is loaded from beside the `.beam`.** `erlc +from_asm -o out out/beam/x.S` (the
  `.beam` one directory up) leaves the sidecars unreached; `botopink run --target beam` assembles
  beside the `.S`, and `modules/compiler-cli/AGENTS.md` says so.
- `test/` cells and `modules/` test-kind cells stay off wasm and beam because `botopink test`
  refuses those targets — a CLI capability, not a tolerance.
