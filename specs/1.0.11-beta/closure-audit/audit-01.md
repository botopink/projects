# Audit — `specs/1.0.11-beta/01-compiler/` against botopink-lang `feat`

Audited 2026-10-03. botopink-lang HEAD is `ec77f649`, which is `origin/feat`. The meta repo is at `9509581` ("Merge front/134-builtins-declared into feat").
I judged each front from commits, the cells under `tests/language/` and `codegen/tests/*.zig` files. No build was run.

**The main finding.** `status.md` is out of date by roughly 14 integrations.
- It says the gate is green on `0041d38c` (gate-integration-6).
- `feat` has 60 more commits after that point. They include merges from gate-integration-7 through gate-integration-14.
- Those merges bring in 01-checker, 02-erlang, 03-beam, 04-js, 05-wasm and 05-wasm-std, 14, 17, 26, 129, 130 and 134.
- They also bring in 97, 104 and 106, which `status.md` still lists as "In analysis" or "Pending". 97 is in gate-integration-13 and 104/106 are in gate-integration-3.

Every front's gate box "Commit on `front/<x>`; no push, no merge" is unticked, or names a `fix/<x>` branch that does not exist. For every merged front this box should now read "landed on feat via gate-integration-N".

---

## Per front

### 01-checker — PARTIAL (most steps landed on feat)
- **Evidence:**
  - Merges `7bf15738`, `819fbbb3` and `b0701647` (gate-integration-4 and gate-integration-11).
  - Commits `78a74c99` (step 1), `c283eb50` (2), `aa9fdf06` (3), `ccfc3fe8` (4), `3ef431e8` and `27b4653a` (5 and decision 205), `8ad1006d` (6), `2f234a1e` (7), `c7bbcba6` (8), `65f3db3f` (11), `682b3b2b` (12), `7d81c14b` (14), `cc56f13e` (15), `3fd080ba` (16), `23941815`, `70c9b576` and `19a7d70f` (decisions 208, 209 and 215), `3058925f` (three language-gaps rows), `33ac5bd9` (step 17).
  - Every cell the README cites as present exists, 69 of them checked by path.
- **Open:**
  - Step 6 box 3: `run/throw_in_case_arm_result` does not exist. It is blocked on 04-js codegen (`JumpInValuePosition`).
  - Step 10: `run/lambda_param_annotation` does not exist. It is blocked on 16's printer arm.
  - Step 13: `run/val_spread_only_list_pattern` and `run/val_nested_ctor_pattern` do not exist. They are blocked on 02 and 05 lowering.
  - Rows-found: the `primitive-type-name-taken` refusal. It is built but not on feat, and `grep` finds no such code in `modules/`.
  - Rows-found: the comptime body's file is not named (14 box 1).
  - Rows-found: T17 (`modules/reflection_type_not_shadowed_by_import` is absent).
  - Step 18 (decision 247, numeric suffixes) is not started. The lexer has no suffix handling.
  - Gate: `test-libs` box.
- **A blocker that is gone:** the parked primitive-name refusal waited on std's `random.bool`. That function was dropped on feat by `6330995b` ("random.bool dropped"), so the refusal can land now.

### 02-erlang — PARTIAL (all of its own lowering landed; the open boxes belong to other fronts)
- **Evidence:** merges `8e52c854`, `071d7b1f` and `2374e364`, plus `93b38dec` (R7 measured). Cells present:
  - `run/module_fn_named_like_bif`, `run/host_template_binding_inside_while`, `modules/dependency_module_level_print`
  - `run/string_literal_unicode_escape`, `modules/erlang_host_sidecar_shipped`, `modules/erlang_host_sidecar_in_a_test`
  - `run/list_pattern_spread_alone`, `run/lambda_binds_name_of_enclosing_fn`, `run/behavior_default_adopted_by_two_types`
  - `test/is_truth_table`
- **Open:**
  - Step 4: `run/array_unique` is missing. std's new body (decision 217) already landed in `6330995b` (`primitives.bp:761`), so only the cell and the wasm column are left.
  - Step 5 box 2: a decorator body carrying `\u{…}`. This is 14's file.
  - Step 7: the `run/is_truth_table` and `run/unknown_stores_nothing` cells are blocked on wasm.
  - Step 9 box 2: the T1 row.
  - Step 10 box 2: `@block` tail-form refusal. This is 01's.
- **Stale:** step 6 is done but unticked.
  - `run/string_index_of_codepoints` exists with one `.out` for four targets (`63f7b3dd`).
  - 02e-a was answered by decision 240.
  - README lines 166 and 172–175 still say "waits on 02e-a".

### 03-beam — PARTIAL (every step it owns landed; two boxes wait on 01, 02 and 05)
- **Evidence:** merges `6f122ea5` (`ba8d2ea0` JS-4, `0fb3b527` C-07 twins, `04f8cc5f` beam test runner, and others) and `a807239f` (`5c13d177` standard_io). `run/ctor_pattern_in_val_binding` exists. `expected-failures.txt` is deleted.
- **Open:**
  - Step 1 box 3: the cells of 01 step 13.
  - Step 2 box 1: `run/is_truth_table` and `run/unknown_stores_nothing`, which are 02's cells.
- **Stale:** `status.md:78` puts 03 in "Open — after 00-gate". In fact everything it owns is merged.

### 04-js — PARTIAL (steps 3, 4, 5, 7 and C-37 landed; 1, 2 and 6 wait on 01)
- **Evidence:**
  - Merge `524e5e20`: `6e9d4ca3` tsc-check, `a40636a8` default fn, `5808d418` the IIFE measured, `a1ea717e` decision 179.
  - Merge `0749c3c5`: decisions 210 and 214.
  - Merge `124c882b`: `c40c352f` `node --check` and `run/sibling_blocks_bind_one_name`.
- **Open:**
  - Step 1: the checker refusing `@block`'s tail form.
  - Step 2: `reject/external_template_stringify_marker` is absent, and the parser does not refuse `$stringify`.
  - Step 6: `throw` in a `case` arm.
  - Gate: RUN LOG verification and `test-libs` boxes.
- **Stale:** `status.md:50` says "on `front/04-js`", but it is merged (gate-integration-8). It also says "step 2 on `0405-d` (raised)", but 0405-d was answered by decision 239. std's `Array.join` no longer uses `$stringify` (`6330995b`), so step 2 now waits only on 01's parser error kind.

### 05-wasm — PARTIAL (steps 1–4 landed; step 5 under way; every blocking decision answered)
- **Evidence:**
  - Merge `0ecdbb42`: `2a896f23` step 1, `662f619e` step 2, `4b2d905e` step 3, `7838d015`.
  - Merge `9642df1d`: `63f7b3dd`, the vocabulary, codepoints, math and escape.
  - Merge `eb9de055`: `15a3d52f`, hash and io/random.
  - Merge `47f6210f`: `b737f8d2`, floats, i64 and overflow.
  - All the `run/std_*_on_every_target` cells exist.
- **Open:**
  - Step 1 and step 3 box 2 (the cells 02 owes).
  - Step 5: `unicode`, `json`, `encoding` and `querystring` on wasm; the AGENTS refusal list.
  - 05w-e heap growth: decision 261 is answered, but no `memory.grow` exists yet (`wat/AGENTS.md:431` still names the one page).
  - 05w-f `String.fromCodepoint`: decision 262 is answered, but it is not in `primitives.bp`.
  - All gate boxes are unticked.
- **Stale:**
  - `status.md:71` says "`05w-c`…`05w-g` open; blocked on `05w-f`". All five were answered by decisions 259–263, and gw-a by 264. They are no longer blockers; the work remains to be built.
  - README lines 125, 142–148: the same stale "blocked on 05w-f" and unticked "05w-c/05w-g answered" boxes.
  - README lines 159–163 list "i64 lowered as i32", "a float kept as its f32" and "`Float.toString` six digits / traps at 2^31" as open. `b737f8d2` on feat fixed all three.
  - README line 181 names the branch `fix/05-wasm`.
  - Front 05 is also listed both under "Pending" (`status.md:71`, step 5) and "Open" (`status.md:78`).

### 07-review-backlog — NOT STARTED
- **Evidence:**
  - `externals.zig:55,67` still carry the misleading names.
  - `infer_decls.zig:147` is not renamed.
  - `control_flow.zig:73,76` and `narrowing.zig:90` still say `06-wasm` / `07-checker`.
  - The only "front/07-review-backlog" merge (`4187b255`, 2026-09-25) predates the milestone.
- **Blockers:** 02–05 must be landed. They are now mostly merged, so wave A's commonJS, erlang and beam columns can be re-derived.

### 08-hygiene — NOT STARTED as a front (items 1–2 done by their owners)
- **Evidence:** `grep primitives.d.bp modules` leaves only `language-server/src/tests/hover.zig:304`, which is 07's, plus the two legitimate extension tests. The erlang and comptime sweeps landed with 01 and 02.
- **Open:** items 3–6. `docs.md` has 0 `BeamMemory` mentions.
- **Blocker gone:** item 5 part 2 waited on 17 step 1, which is merged (`45abf005`).

### 09-ecosystem-residuals — NOT STARTED (item 1 done elsewhere)
- **Evidence for item 1:** erika `f4fda89` deleted erika-linq's `targets`, and `scripts/restricted-targets.txt` no longer exists (113). The first acceptance box of item 1 is done.
- **Open:**
  - Items 2–4 (C-14 needs the maintainer's word).
  - Erika's C-13 migration (needs 16).
  - The pointer sweep.

### 12-language-tests — PARTIAL (merged via `65e6cb8c`: `b7363245`, `a8ab7820`, `50a2c7a5`, `c899d37b`)
- **Landed:**
  - Step 1 box 1 (beam in `all`).
  - Step 2 box 2 (`run/try_in_for_writing_var`).
  - Step 3.
- **Open:**
  - Step 1 `--cold` box.
  - Step 2 box 1.
  - Step 4.
- **Stale:**
  - README line 84 says "none of the ten area-front cells exists yet". Today 9 of the 11 listed cells exist; only `run/array_unique` and `run/throw_in_case_arm_result` are missing.
  - README lines 59 and 131: the `LANG=C` red on erlang and beam is fixed by 02 step 5 and 03 step 6 (both on feat).
  - The counts table (64/171/174/68) needs re-measuring. Today there are `.bp`/dirs: test 68, run 234, reject 239, modules 89.

### 14-comptime-on-beam — PARTIAL
- **Evidence:** merge `ac0ad62c` (`0f88ffb2` step 1 L:C, `d957e4c5`, `fcce1ed4` step 3) and merge `da9fae6a` (`6384f692`, decision 237).
- **Open:**
  - Step 1's file name; this is 01's.
  - Step 2's slope: 1.3 ms/eval, against a budget of ≤ 1 ms. Erlang N=200 is 711 ms, against ≤ 600 ms.
  - Step 5, T17: the cell is absent and the work is 01's.
  - Step 6, the lg2-gated rows.
- **Stale:** `status.md:72` says step 2 "re-measured 6.6 / 9.2 ms per evaluation, waits on `14-a`". 14-a was answered by decision 237 and built (`6384f692`); the README measures 1.3 ms/eval after it. What remains is 18's runtime evaluation and the trace listing.

### 16-formatter — NOT STARTED
- **Evidence:** no 16 commit in the milestone; `blockStatementSemicolon` is not in the parser.
- **Stale:** the Depends line (README lines 8–9) lists 16-c and 16-d as maintainer decisions owed. They were answered by decisions 165 and 166; the 243 scope note follows from 166.
- **Gap:** 01 step 10 is blocked on a 16 printer arm for lambda parameter annotations. 16 has no step for that, only a Note (README line 141).

### 17-beam-memory — PARTIAL (step 1 landed on feat)
- **Evidence:** merge `45abf005` (`116c27c1` decision 167, `9f6c41c4` decision 168). `run/beam_memory_ets_keyed` and three `reject/beam_memory_ets_keyed_*` cells exist.
- **Open:**
  - Step 1 box 4 (17-b, open).
  - Step 2 (08's docs text and the rakun track pointer).
  - Gate cold-test box.
- **Stale:**
  - `status.md:52` and README lines 4–6 say "built on `front/17-beam-memory`"; it is merged.
  - README line 88 and `01-compiler/README.md:206` say "the language has no `??`". `??` exists: 01 step 11 cells such as `run/nullish_tuple_operand`. This changes 17-b's premise: `counts.at(k) ?? 0` is expressible.

### 18-comptime-runtimes — NOT STARTED
- **Evidence:** no commits. `runtime/AGENTS.md` has no § Limits. There is no transport-error test beside `evalBeam`.
- **Partial progress elsewhere:** the `test-web` wasm32 fix `d5e8dbf8` and gate stage 12 `dcf86291` are on feat.
- **Stale:**
  - README line 45 still lists `windows-2022`. The windows row is deleted (decision 158; `test.yml` runs only `[ubuntu-22.04, macos-14]`).
  - `status.md:18–19` says test-web wasm32 and the bash 3.2 fix are "on an unlanded branch". Both are on feat: `d5e8dbf8`, plus `f95fc626`, `a8808e6e` and `2dcd7b54` for bash 3.2.

### 23-std-purity — NOT STARTED
- **Evidence:** no commits.
- **Blockers:** the confirmations 23-a/b/c and std-c are not in `decisions-taken.md`.

### 24-effects-by-return — NOT STARTED
- **Evidence:** no commits.
- **Stale:** README lines 7 and 53 treat 24-h as an owed decision. It was answered by decision 179 (and recorded by 04 step 5). 24-a/b/c/g are still unconfirmed.

### 25-gate-perf — PARTIAL (step 2 landed by 00-gate/115; boxes unticked)
- **Evidence:** meta `a3cd696` adds `scripts/worktree-add.sh`, and the meta `AGENTS.md` § Worktrees names it. The compiler's "hooks do not run in worktrees" note is gone.
- **Step 3** (re-time the gate) has in effect been done by 115 and 133: 56m → 12m16s → ~7m30s.
- **Open:** step 1, the per-cell dependency-compile row. 133's cell-result store may partly supersede it; re-scope it.
- **Stale:** `status.md:79` lists 25 as "Open".

### 26-cli-tooling — PARTIAL
- **Evidence:** merge `9ccd28ce`:
  - `57bc92d7` (step 1)
  - `97eff7af` (step 2; `modules/sidecar_called_from_folder_module`, `sidecar_named_like_emitted_atom`)
  - `751c53f9` (step 4 LSP)
  - `f553073f` (step 5)
- **Open:**
  - Step 1 box 2, the T1 row. Both halves are on feat (02 step 9 and 26 step 1), so the T1 row of `language-gaps.md:141` can close.
  - Step 3: `modules/transitive_package_import` is absent.
  - Step 4 CLI half: blocked on compiler-core, because `ModuleOutput` has no warnings field.
  - Step 6 (lg2-v).
- **Stale:** README line 94 says "26-a is open … nothing is implemented before the answer". It was answered by decision 242 ((a) direct dependencies only), so step 3 is unblocked.
- **Also:** `status.md:78` lists 26 as "Open".

### 129-import-without-from — DONE (code and migration on feat in every repository)
- **Evidence:**
  - botopink-lang merge `f7234657`: `7d1ad698` the rule, `f8586ab8` the codemod, `a7270d24` the migration, `466479d9`.
  - The three cells `modules/import_own_module_with_from`, `import_bundled_package_beside_own_module` and `import_module_path_in_braces` exist.
  - Each library has a "migrate to decision 206's brace import" commit merged into gate-integration-4: rakun `4a0e9f2`, onze `2755f5a`, jhonstart `4513de1`, emilia `52f31b8`.
- **Open** (README § Remaining):
  - The LSP runs no import-source check.
  - The `docs.md` § Imports sentence.
  - `from "<own package>"` inside a bundled library.
  - onze's `@/` alias question.
- **Gate boxes:** unticked.
- **Missing from:** `status.md`, `01-compiler/README.md` § Fronts, `fronts.md` and `overview.md`.

### 130-decorator-outputs — PARTIAL (steps 1–4 landed; step 5 at 34/119; step 6 not started)
- **Evidence:**
  - Merge `f4a07fde`: `cdad51af`, `81227795`, `17f3681f`, `0c8aa34f` (steps 1–4) and `56d4ceef`.
  - Merge `a1d2d845`: `34055fb5` decision 235, `43110502` `unknown-associated-fn`.
  - Merge `9fe660ec`: `33cd7bb8` decision 248.
- **`@emit(` still in source:** rakun 80 lines, jhonstart 5 and validation 5 (`libs/validation/src/decorators.bp`). This is consistent with about 85 sites left.
- **Open:**
  - Step 5: rakun DI is held on dec-e. Also open are jhonstart routes, validation `#[schema]` and rakun-client `#[httpExchange]`.
  - Step 6 (removing `@emit`).
- **Stale:** the README says "Measured on `front/130-decorator-outputs`"; it is merged.

### 134-builtins-declared — PARTIAL (steps 1 and 3 done; step 2 partial; on feat)
- **Evidence:**
  - `14cf36ce` and `ec77f649` are first-parent on feat (meta `9509581`).
  - `comptime/builtins.zig` `drift` and its test.
  - Cells `reject/builtin_arguments`, `run/typeinfo_all_unknown_value`, `reject/typeinfo_all_value_unknown`.
- **Open:**
  - Step 2 remainder: the type functions, the `result` namespace, the `@Result` / `?T` methods, `@is`.
  - 134-a…d.
  - Gate boxes.
- **Note:** `status.md:47` should say it is landed on feat. It currently reads as branch work.

---

## Spec inconsistencies (file:line → issue → fix)

1. **`status.md:3,7–8`.** The text says "13 of 84 fronts", but the Count line adds up to 79 (00-gate 11, 01-compiler 18). The directories hold 00-gate 14 and 01-compiler 20; with them the total is 84.
   **Fix:** `00-gate 14 · 01-compiler 20 … — 84`.
2. **`overview.md:28`.** It says 01-compiler has 17 fronts; there are 20. **`overview.md:22–23`** says "Numbers 97–128 are new … `26-cli-tooling` is new", which leaves out 129, 130 and 134.
   **Fix:** set the count to 20 and name 129, 130 and 134 as new.
3. **`overview.md:70–73`.** "Where it stands (2026-10-02): 00-gate is not green … CI red" contradicts `status.md` § Done.
   **Fix:** rewrite it to point at status.md, or update it.
4. **129 is missing from `status.md`, `01-compiler/README.md:49–69` (§ Fronts), the Order diagram (`:83`), `fronts.md` and `overview.md`.** It is only cited at `status.md:21`.
   **Fix:** add a § Done line to status.md (or "In analysis: § Remaining open"). Add 129 to the track's Fronts table and to fronts.md; 129, 130 and 134 are all absent from fronts.md.
5. **`status.md:12–21`.** The gate claim is pinned to `0041d38c` (gate-integration-6) and calls gate-integration-3 "the next integration". `feat` is at gate-integration-14 plus `ec77f649`.
   **Fix:** re-measure on `ec77f649`.
6. **`status.md:18–19`.** "test-web wasm32 and `test-libs.sh` under macOS bash 3.2, both fixed on an unlanded branch" — both are on feat (`d5e8dbf8`, `f95fc626`, `a8808e6e`, `2dcd7b54`).
   **Fix:** update this, and `status.md:48` (114) with it.
7. **`status.md:50,51,52`.** These say "on `front/04-js`", "on `front/01-checker`" and "on `front/17-beam-memory`", but all three are merged to feat (gate-integration-8, gate-integration-11 and gate-integration-13).
   **Fix:** say "landed on feat".
8. **`status.md:51`.** It says "steps 1–8 and 10–16 built", but steps 10 and 13 (and step 6 box 3) are open according to the README.
   **Fix:** "steps 1–9, 11, 12, 14–17; 6c, 10 and 13 wait on 04, 16 and 02/05". Also: "parked on std's `random.bool`" — it was dropped in `6330995b`, so the refusal can land.
9. **`status.md:50`.** "step 2 on `0405-d` (raised)" — 0405-d was answered by decision 239 and std was rewritten.
   **Fix:** "step 2 on 01's parser error kind".
10. **`status.md:71` and `05-wasm/README.md:46,125,142–148`.** 05w-c…g are called "open" or "blocked on 05w-f", but they were answered by decisions 259–263.
    **Fix:** reword them as build items (heap growth, `String.fromCodepoint`, glibc `pow`, the OS-independent `math`).
11. **`05-wasm/README.md:159–163`.** i64-as-i32, f32 floats and `Float.toString` are listed as open, but `b737f8d2` fixed them.
    **Fix:** move them to fixed. **`:181`** `fix/05-wasm` should become `front/05-wasm` (landed).
12. **`status.md:72`.** "step 2 … 6.6 / 9.2 ms … waits on `14-a`" — decision 237 is built and the README shows 1.3 ms/eval.
    **Fix:** "step 2: slope 1.3 ms/eval, erlang N=200 711 ms; left to 18 (runtime eval) and the trace owner".
13. **`status.md:78–79`.** 02, 03 and 26 (group A), and 12 and 25 (group B), are listed as "Open — after 00-gate". All of them have landed work on feat; 03's own steps are complete.
    **Fix:** move them to "In analysis" with their ticked steps.
14. **`status.md:53,60,61`.** 97 is "committed on `front/97-std-dedupe`", and 104 and 106 are "Pending". All three are merged (`d83613db` gate-integration-13; `6d9e06cb` and `3b715323` gate-integration-3). This is outside the 01 scope but blocks 01 rows such as `run/array_unique`.
15. **`02-erlang/README.md:166–167,172–175`.** Step 6's cell exists with one `.out` (decision 240), but the boxes are unticked and the text says "waits on 02e-a".
    **Fix:** tick box 1, and drop the 02e-a wait.
16. **`decisions-pending.md:3` and `:5`.** There are two contradictory header paragraphs, probably a merge leftover. Line 5 says ck2-c is open and that there are "Twenty-seven questions". Both lines list 02e-a as open, and the file still holds headings for `02e-a` (`:334`) and `gw-a` (`:368`), answered by decisions 240 and 264.
    **Fix:** keep one header, and drop 02e-a, gw-a and ck2-c.
17. **`01-compiler/README.md:125`.** "next free number (**146**)" — the next free number is 266.
    **Fix:** 266, or point to decisions-pending.
18. **`01-compiler/README.md:132–146` and `:148–252`.** Most of these are presented as owed, but they are answered: ck2-c (244), lg-a (147), lg-b (148), ck-host (146), D5 (150), 01c-c (151), 01c-d (152), 0405-c (164), 17-a (168), 23-d (169), 24-h (179), 16-c (165), 16-d (166).
    **Fix:** strike each answered entry, or replace it with "Answered: decision N", as 0405-d and 26-a already are.
19. **`01-compiler/README.md:206` and `17-beam-memory/README.md:88`.** "the language has no `??`" is false, because `??` parses and runs (`run/nullish_tuple_operand`).
    **Fix:** restate 17-b's premise.
20. **`01-compiler/README.md:99–117`** (§ Handed to 00-gate: EF-1…RT-3). Every item is landed: `expected-failures.txt` and `restricted-targets.txt` are deleted, and 110, 111, 112 and 113 are done.
    **Fix:** mark the section closed, or delete it.
21. **`01-checker/README.md:165,203–204,230`.** These boxes are ticked `[x]` while their text says "**open**".
    **Fix:** untick them, or split each into a landed half and an open half.
22. **`12-language-tests/README.md:84`.** "none of the ten area-front cells exists yet" — 9 of 11 exist.
    **Fix:** list only `run/array_unique` and `run/throw_in_case_arm_result`. **`:59` and `:131`**: the LANG=C issue is fixed by 02 step 5 and 03 step 6.
23. **`16-formatter/README.md:8–9`.** It waits on 16-c and 16-d, which are answered (165, 166). The lambda-parameter-annotation printer arm that 01 step 10 needs has no step here.
    **Fix:** add a step.
24. **`18-comptime-runtimes/README.md:45`.** The `windows-2022` row was deleted by decision 158.
    **Fix:** drop it.
25. **`24-effects-by-return/README.md:7,53`.** 24-h is owed, but it was answered by decision 179.
    **Fix:** "five ids" → four confirmations.
26. **`25-gate-perf/README.md`, step 2.** It is landed (meta `a3cd696`, `scripts/worktree-add.sh`, meta AGENTS § Worktrees), but its boxes are unticked. Step 3 is superseded by 115 and 133.
    **Fix:** tick step 2 and close or re-scope step 3.
27. **`26-cli-tooling/README.md:94`.** "26-a is open" — answered by decision 242 (a).
    **Fix:** step 3 is unblocked; build `modules/transitive_package_import`.
28. **`language-gaps.md:141`.** The T1 row ("A built erlang program cannot load its `.erl` sidecars") is still present, though both halves are on feat (02 step 9 `modules/erlang_host_sidecar_shipped`, 26 `57bc92d7`).
    **Fix:** close the row; check that `scripts/language-gap-markers.sh` stays green.
29. **`09-ecosystem-residuals/README.md`, item 1 and its first box.** It is done (erika `f4fda89`, the ledger is gone).
    **Fix:** tick it. The "Does not touch until 00-gate lands" line is moot.
30. **`08-hygiene/README.md`, item 1.** Only `hover.zig:304` (07's) remains. Item 5 part 2 is unblocked because 17 step 1 is merged.
31. **All merged fronts' READMEs.** Each has an unticked "Commit on `front/…`; no push, no merge" box. Several (05, 07, 08, 09, 16, 18, 23, 24, 25, 26) name `fix/<x>` branches, while the real branch names are `front/<x>`.
    **Fix:** a uniform "landed via gate-integration-N" line.
