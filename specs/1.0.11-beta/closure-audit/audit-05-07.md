# Audit: tracks 05-jhonstart, 06-emilia, 07-onze (1.0.11-beta), checked against the code

Audited 2026-10-03, read-only. The tips I checked are the meta repo's pinned submodules, and each equals its remote `feat`:
jhonstart `eddd681`, emilia `42d51ec`, onze `b1a3110`, botopink-lang `ec77f649`. No front branch
of 26/27/67/33/34/49/50/51/53/71 exists on any remote. The only extra remote branch is
`jhonstart:origin/front/gate-lib-infra`, which has no commits beyond feat. None of these ten
fronts has a merge commit in any library repo.

## Prerequisites from 00-gate (100 / 101 / 109): all landed on feat

| Check | jhonstart | emilia | onze |
|---|---|---|---|
| `scripts/git-hooks/pre-commit` byte-identical (md5 `32614a7a…`), `lib/runner-standalone.sh` identical (`ca2bed0a…`) across all 5 libs | yes | yes | yes |
| `.gitignore` names `*.snap.new` and `*.snap.md.new` | yes | yes | yes |
| no `scripts/known-broken-examples.txt` | yes | yes | yes |
| `AGENTS.md` names `git config core.hooksPath scripts/git-hooks` | yes | yes | yes |
| parenthesised `(if …)` operand sites | 0 | 0 | 0. The 6 remaining hits are call arguments (`push(if …)`, `quote(if …)`, `scanFiles(if …)`), which 100 § Current state explicitly allows |
| targets | `jhonstart-dom-test` is `["commonJS"]` and structural (`7d63082`); counter/todo are on both rows (`f8e6235`) | all members and examples are on both rows | `onze-cli` and `onze-og` have no `targets` line (`87bcb88`); `onze-server` is `["erlang"]` |
| commits | `d2f7ce6`, `7d63082`, `0b4bf5c` | `96ae5d2` (gate-i), `6b766c1` (gate-j), `8e9705d` | `28eae9e` (gate-g), `87bcb88` (gate-d), `e0f78ba` (gate-i/j), `559771f` |

None of 100, 101 or 109 has an open `- [ ]` box. I could not check that GitHub CI is green.

**Other prerequisites have moved since status.md was written (2026-10-02).** On botopink-lang `feat`, all four of these
are ancestors of `origin/feat`:
- `front/106-log` merged at `3b715323` (`libs/log` with `digest.errorDigest` and `sink.bp`).
- `front/104-http` package half merged at `6d9e06cb`.
- `front/97-std-dedupe` merged at `d83613db` (`json.Json` methods `e14202f1`, `string.parseInt()` / `parseFloat()` `c944bbea`).
- `front/125-validation-zod` merged at `88679116`.

102 step 3, 103 step 2 and 08-bpp/118 have **not** landed: `jhonstart-html` still exists, and
`libs/routing` has no `conventions` and `libs/actions` no `id`.

---

## 05-jhonstart

### 26-jhonstart-router: NOT STARTED

Every item in the README still reproduces on `eddd681`:
- **Step 0 not done.** `modules/jhonstart-html/` still exists, and 118 has not landed.
- **Step 1 not done.** `grep -rni rakun modules/jhonstart/src` finds **26** lines. The README says 21. The extra lines come from `src/sidecars/jhonstart_server.erl:17,26` and `jhonstart_router.erl:20` (not named in the README) plus `src/AGENTS.md:44`. Line numbers have drifted: `router.bp:59,103,164,313,373,375,404`; `server.bp:…,307`; `client.bp:87`.
- **Step 2 not done.** `handleSignal` is at `client_app.bp:219` (the README says `:177-193`). `registerSignal` is at `render.mjs:199`, and its `replaceState` call is at `:213`.
- **Step 3 not done.** `__jhEachCompleted` is still used (`streaming.bp:136,810,834`).
- **Step 4 not done, but now unblocked by 106.** `digestOf` is still at `error_boundary.bp:77,83,89`, and nothing imports `log`.
- **Step 5 not done.** `docs.md:371,393` still name "front 23". The front-68 contract heading is at `docs.md:1091`.
- **Step 6 not done.** 0 of 8 example READMEs exist.
- **Step 8 not done.** `markDynamic` is at `router.bp:186,198,276`, `server.bp:87,254` and `streaming.bp:52,703`.
- Related change: `423d71d` ("#[client] records comptime meta instead of emitting a marker function", decision 216, via 130) has already touched the `#[client]` code that step 8 validates in.
- Counts match: the core has 204 tests (179 in `test/` plus 25 inline). `grep -i emilia src` is empty.

**Remaining:** steps 0–8.
**Blockers:** 118 landed (step 0 / opening); 102 step 3's `routes.bp` commit; 118 step 1's carve-out. In this member that carve-out is comments only, because `src/` has no `[name]={` code use. Also `30-h` (step 7), `29-a` confirmation (step 5), and the checker capability of decision 186 (step 8). 106 is no longer a blocker.

### 27-jhonstart-link: NOT STARTED

- No `applyTransition` or `DomOps` anywhere.
- `reconcile.bp:24-44` still says "why `reconcile(current, target)` is not in this file".
- No `use linkStatus()` test inside a `@Component` body, and no `refusals/` directory.
- The member has 38 tests (`link_test` 28 + `reconcile_test` 10). The README says "35 / 35".

**Remaining:** steps 1–3.
**Blockers:** none for step 1 box 1, step 2 or step 3. Step 1 box 2 waits on `04-rakun/22` (the `k` flag); `27-a` needs confirmation.

### 67-jhonstart-forms: NOT STARTED

- No `forms_dom_test.bp` and no `stubWireNames`.
- `form.bp:117-121` still hand-checks the id (`formAction`, waiting on 103).
- The wire-name literals are present well beyond the two places the README names:
  - `form_test.bp:49,58,59,63,65,69,73,94,96,98`
  - `examples/forms/src/like.bp:23`
  - **`examples/forms/src/main.bp:14`**
  - **`examples/forms/test/forms_test.bp:16,21,30,36`**
  - **4 `.snap` files** under `examples/forms/test/__snapshots__/forms/`

**Remaining:** steps 1–5.
**Blockers:** 26 (`fake_dom.mjs`), 103 step 2 and `67-a` (open, recommendation (a)) for steps 1–3. Step 4 needs only 103.

---

## 06-emilia

### 34-emilia-modifiers: NOT STARTED

- `hashHex` is still at `emilia.bp:97,114`, and `emilia.bp` does not import `hash`.
- `output.bp:379-388` still holds the prelude comment. C-37 is closed in the compiler (04-js), so the workaround could go.
- Transitions still write `var(--ease-out)` (`emilia.bp:13263,13281`).
- There is no `-webkit-backdrop-filter`.
- `border-spacing` still writes the property itself (`:313,12811`).

**Remaining:** steps 1–4.
**Blockers:**
- 118 step 1's carve-out. In emilia this is **comments only**: `attributes.bp:30,32,36` and `emilia.bp:185,202`. No code uses `[name]={`.
- `05emilia-l` needs confirmation (step 2).
- `05emilia-n` is open (step 4).
- Step 1 depends on nothing: `hash.contentHash` exists, and 97 has now landed anyway.

### 33-emilia-color-palette: NOT STARTED

- `modules/emilia-test/src/root.bp` has one test and exports nothing. There is no `test/` directory.
- `examples/emilia-card/botopink.json` still depends on jhonstart by path.
- 0 of 15 example READMEs exist.
- `modules/emilia/test/` does not exist.

**Remaining:** steps 1–4.
**Blockers:** steps 1–2 only nominally wait on 118's carve-out (one comment at `emilia-card/src/main.bp:5`). Steps 3–4 wait on 34 and `05emilia-m` (open, recommendation (a)).

---

## 07-onze

### 49-onze-stand-up: NOT STARTED

- `onze-server/src/server.bp:76-77` still has `query: [], headers: []`.
- `serveActions`, a log sink and `markDynamic` appear nowhere in onze.
- `onze/src/config.bp:98,105,112,130` still declares `pub fn membersOf` / `isObject` / `kindName` / `strOf`.
- `onze-test/src` holds only `core.bp`, `fixtures.bp` and `root.bp`. The step 6 stubs are absent.
- Counts: `onze` has 23 tests (the README says 22); `onze-server` 10; `onze-test` 7.

**Remaining:** steps 1–6.
**Blockers:**
- 102 step 3's `types.bp` commit (opening).
- Step 3: 26 step 4 and `04-rakun/17` (rakun's logger). 106 has landed.
- Step 4: `04-rakun/65` step 1.
- Step 5: `04-rakun/22` step 4.
- `49-e` and `49-d` need confirmation.
- Step 1 is now unblocked (97 landed). Step 6 has no blocker.

### 50-onze-cli: NOT STARTED, with fragments already present

- `main.bp:101` still says "onze dev: not available yet". There is no `dev.bp` and no `resolve_test.bp`.
- Local `membersOf` remains at `build.bp:42` and `info.bp:11`, and `itemsOf` at `onze-bundler/src/entry.bp:182`.
- Partly in place for step 7: `create.bp:36` `createDefaults()` already feeds `--help`. The snapshot `create/help_the_flag_table_from_the_one_defaults_record.snap` exists. The `docs.md` comparison is still missing.

**Remaining:** all 8 steps.
**Blockers:**
- 102 step 3's `scan.bp` / `chunk.bp` commits.
- `50-b` (step 2).
- `std-d` (steps 4, 7).
- 71 step 2 (step 5).
- 27 step 1 (step 6).
- 49 step 6.
- `53-b` (step 8).
- Step 1 is unblocked.

### 51-onze-image: NOT STARTED

- Nothing in onze uses `rkCacheFlight`, although it exists in `rakun-cache/src/cache.bp:321`.
- The local `intOf` copies remain at `onze-og/src/svg.bp:21` and `metrics.bp:14` (the README says `:19` and `:12`).
- There is no `onze-assets/scripts/`.

**Remaining:** steps 1–7.
**Blockers:** `52-a` needs confirmation (step 4); `04-rakun/22` (routes 25 and 66); `53-b` (step 7); 49 step 6 (the `assets` / `og` stubs). Step 1 is unblocked.

### 71-onze-release-packaging: NOT STARTED (step 6 is effectively already on disk)

- `includeErts` is in `spec.bp`, `otp.bp:54` and `docker.bp:10`, but `package.bp` copies no ERTS.
- `verifyBuildId` exists as a pure function (`spec.bp:78`).
- `static_export.bp` writes nothing to disk, and `examples/static-site/` does not exist.
- **Already on disk:** `onze-release/test/__snapshots__/release/` already holds 5 `.snap` files: release text (rel / sys.config / vm.args / boot script), Dockerfile, build id, shutdown and static export. All come from `0db4091` in 1.0.10.

**Remaining:** steps 1–5. Step 6 needs only re-checking against its acceptance.
**Blockers:** 49 step 6; `04-rakun` 11, 04 (62) and 81 (step 3); 50 and 53 (step 5).

### 53-onze-example-app: NOT STARTED

The blog matches § Current state:
- no `middleware.bp`, `error.bp`, `loading.bp`, `lib/actions.bp`, `README.md` or `test/serve.sh`;
- `onze-test` has no `e2e.bp`;
- tests are `db_test`, `render_test` and `tags_test` only.

**Remaining:** steps 1–6.
**Blockers:** every front above. The E2E runner in step 1 could start once 49 step 6 lands.

---

## Spec inconsistencies (file:line, issue, proposed fix)

1. **`status.md:13-46`, Pending lines `106` / `104` / "In analysis" lines `97` / `125`.** These are stale. 106, 104 (steps 1–4), 97 and 125 (steps 0–2) are all merged into botopink-lang `origin/feat`, which is the pinned `ec77f649`. **Fix:** move them to Done (or partial), and say that 26 step 4 and the "consume std" steps 49/50/51 step 1 are now unblocked.
2. **`status.md:5-7`.** "13 of 84 fronts" conflicts with the per-track counts, which add to **79**. "`00-gate` 11" conflicts with the 14 front directories (13 done plus 114). **Fix:** recount.
3. **`status.md:15`.** The text "`gate-integration-3`: 97, 104, 106, 26, 04-js" means `01-compiler/26-cli-tooling` (`front/26-cli-tooling`), but reads as `05-jhonstart/26`. **Fix:** spell it `01-compiler/26`.
4. **`07-onze/53-onze-example-app/README.md:43-45`, `07-onze/README.md` § Handed to 00-gate, and `07-onze/carried.md` row 53.** These three say the `blog-slug-page-example.bp:84` marker is "stale … closed in the compiler", to be removed in 53 step 1. But `language-gaps.md:60` indexes that marker against a **live** row, `language-gaps.md:93` "The navigation signals do not return `noreturn`" (waiting on lg2-l). Removing the marker without editing the index would also turn CI check 5 red. Separately, `lib-db-example.bp:88` is not a marker by the script's definition (`MARK='// LANGUAGE GAP'`; that line says "see the LANGUAGE GAP"), so the claim "three markers" is wrong. **Fix:** count two markers, both live. Strike "remove the two stale markers" from step 1, or have it remove both the marker and the `language-gaps.md` index row together.
5. **`07-onze/README.md` (53-b § Measured).** It says §§ 50 · 51 · 52 · 70 · 71 have "inline literals, no `.snap`". On disk, `onze-cli` has 5 `.snap`, `onze-assets` 10, `onze-og` 4 and `onze-release` 5, including the § 71 release text. **Fix:** re-measure 53-b. Under its own recommendation (c), 71 step 6 is effectively satisfied by the existing `__snapshots__/release/*.snap`.
6. **`07-onze/71-onze-release-packaging/README.md` (Problem 1, Step 1).** It says the "Dockerfile's runner base image does not differ" and expects `debian:bookworm-slim` / `erlang:<vsn>-slim`. The code (`docker.bp:10` and its snapshot) already uses different runners: `alpine:3.20` with ERTS, and `erlang:28-alpine` without. **Fix:** restate step 1 as the ERTS copy in `package.bp` only, and adopt the alpine images, or record a decision to change them.
7. **`07-onze/71-…/README.md` (Depends on).** It lists "`07-onze/50` step 5" as a dependency, but the dependency runs the other way: 50 step 5 waits on 71 step 2 (track README § Order; `fronts.md` row 50). It also omits 49 step 6, which `fronts.md` row "71 steps 1–4" requires for `onze-test/src/release.bp`. **Fix:** swap the direction and add 49 step 6.
8. **`fronts.md` row "71 steps 1–4".** It needs only "gate (100) · 49 step 6", yet step 3 waits on `04-rakun` 11 / 04 (62) / 81. **Fix:** make the row read "71 steps 1, 2, 4", plus a separate step 3 row.
9. **`07-onze/49-…/README.md` (Gate "commonJS per the ledger").** The same stale wording appears in `50-…/README.md` (Gate "erlang per the ledger") and `51-…/README.md` (Depends "`00-gate` for the `onze-og commonJS` ledger line"). The ledger was deleted by 113, and `onze-cli` / `onze-og` now run on both rows (`87bcb88`). **Fix:** replace these with "every target its manifest declares".
10. **`fronts.md` row 49.** It omits `04-rakun/17` (rakun's logger, which the README requires for step 3). Row 53 also omits `27`, which 53 step 5's Link box needs; it is reached transitively through 50 step 6, so it should be stated. **Fix:** add both.
11. **`07-onze/51-…/README.md` step 1.** The acceptance grep `grep -n "fn parse" modules/onze-og/src` can never be empty: `card_style.bp:128` `parseStyle` and `metrics.bp:20` `parseMetrics` are legitimate parsers. The actual copies are `intOf` at `svg.bp:21` and `metrics.bp:14`. **Fix:** grep `fn intOf` and update the line numbers. The same drift is in `07-onze/README.md` "the std copies" row.
12. **`05-jhonstart/67-…/README.md` (Problem 2, Step 4, Blast radius).** These sections name only `form_test.bp` and `like.bp:23`, and say nothing re-records. The grep in step 4 also hits `examples/forms/src/main.bp:14`, `examples/forms/test/forms_test.bp` (4 lines) and 4 recorded `.snap` files, which must re-record. **Fix:** list them, and change Blast radius to "re-records the 4 `examples/forms` snapshots".
13. **`05-jhonstart/67-…/README.md` Problem 1.** It says "Six acceptance boxes". The track README, `carried.md:17` and 67-a say "four open DOM boxes (3a, 3b, 4, 5)", and the steps hold five boxes. **Fix:** use one number.
14. **`05-jhonstart/26-…/README.md` Problem 1 / Step 1 and `05-jhonstart/README.md` row JH-30-4.**
    - "21 lines" and the line lists are stale: there are 26 lines with `-i`, and the `.erl` sidecars `jhonstart_server.erl:17,26` and `jhonstart_router.erl:20` are unnamed.
    - Step 1's grep covers `src/`, which includes `sidecars/`.
    - The Problem 2 citation `client_app.bp:177-193` should be `:219`.
    - **Fix:** re-measure and name the sidecars.
15. **`05-jhonstart/26-…/README.md` § Current state.** "`jhonstart-dom-test` 1 red on erlang by construction" contradicts the README's own Notes and 101 (`7d63082`: commonJS-only, structural, no erlang row). **Fix:** delete the clause.
16. **`05-jhonstart/27-…/README.md` (Current state, Gate).** It says "35 / 35". The member has 38 tests. **Fix:** say 38.
17. **`05-jhonstart/README.md`, § Handed to 00-gate (JH-LEDGER ×2, PK-5, STD-1).** The same kind of section in `06-emilia/README.md` (EM-6/STD-1) and `07-onze/README.md` (ONZ-0, STD-1) is also stale. All of it is done by 101/109/100/113/112/114, but it reads as open work. STD-1 is also attributed to "the `02-std-and-packaging` track's row" although 00-gate did it. **Fix:** mark each one closed, naming the gate front.
18. **`06-emilia/34-…/README.md` § Gate and `33-…/README.md` step 2 / § Gate.** These greps are not reachable as written:
    - 34's `grep -rn "jhonstart\|rakun\|onze" repository/emilia/modules` finds 6 comment lines (`attributes.bp:4,30`, `emilia.bp:110,16500,16501,16510`), and no step rewords them.
    - 33's `grep -rn jhonstart repository/emilia` also hits `AGENTS.md` (25 lines), `CHANGELOG.md` (10, which is history), `README.md`, `docs.md`, the root `botopink.json` description, and `.github/workflows/test.yml:94-99` (the jhonstart checkout for emilia-card, which is a 00-gate-owned file).
    - **Fix:** add a step 1 box to 34 rewording the 6 comments. Narrow 33's grep to `modules examples`, and hand the CI checkout removal to 00-gate/114.
19. **`06-emilia/33-…/README.md` step 3.** The step is titled "conditional on (b) or (c)" but contains an "under (a)" box. **Fix:** move the (a) box into an unconditional sub-bullet, as 26 step 7 does.
20. **`06-emilia/README.md` § Order and `fronts.md` wave 3 / wave 8.** 34 and 33 steps 1–2 are gated on "118 step 1's carve-out". In emilia that carve-out is 6 comment lines and 0 code uses, so it blocks nothing structurally. **Fix:** let 34 reword those comments itself, and open 34 and 33 steps 1–2 now rather than at waves 3 and 8.
21. **`06-emilia/README.md` and `07-onze/README.md` § Maintainer decisions.** Both say "Numbered decisions continue from 225". Decisions already reach 265 (`decisions-taken.md:168`). The meta `AGENTS.md` "decisions continue at 144" is also stale. **Fix:** say "continue from the last number in `decisions-taken.md`", or 266.
22. **`07-onze/49-…/README.md` § Current state.** It says "`onze` 22 / 22"; there are 23 tests. **Fix:** re-measure.
23. **`07-onze/53-…/acceptance.md:453`.** It still points the marker check at `specs/1.0.10-beta/`. It is a copied record, so it should note that 53 step 6 reads `specs/1.0.11-beta/` (the README says so, the copy does not).
