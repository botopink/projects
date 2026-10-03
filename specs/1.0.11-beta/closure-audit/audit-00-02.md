# Audit: tracks 00-gate and 02-std-and-packaging vs. code on `feat` (2026-10-03)

**Baseline used.** Meta `9509581`. Every submodule pin equals its `origin/feat`: botopink-lang
`ec77f649`, emilia `42d51ec`, erika `0a463f5`, jhonstart `eddd681`, onze `b1a3110`, rakun `fac248b`,
vscode-extension `7993f96`. botopink-lang `feat` is **60 commits past `0041d38c`**, the commit
status.md cites as "the gate now". It holds merges up to `gate-integration-14` (`47f6210f`).

**Limits.** Zig, erl and the GitHub API were not available. A clone of the public repo was possible, but `gh run list` returned 403 because the repo is not attached to this session. So no CI verdict was re-checked. The verdicts below rest on commits, files on disk and greps. Two meta checks were run locally and pass:
- check 3: no tracked `*.snap.new`, `*.snap.md.new` or `todo.md` in the meta repo or any of the 7 submodules;
- check 5: `scripts/language-gap-markers.sh` exits 0 (32 markers in 23 files).

Check 4 was verified by `sha256sum`: `pre-commit` and `runner-standalone.sh` are identical across all 5 libraries.

---

## Track 00-gate

| Front | Verdict | Evidence on feat | Remaining / blockers |
|---|---|---|---|
| 99 gate-rakun | **DONE** | 0 `(if …)` operand sites (README's grep). No `SKIPPED` / `RAKUN_TEST_` left (only the `migrate.bp` field). `.gitignore` names both snap patterns. No `known-broken-examples.txt`. CI matrix is erlang × {ubuntu-24.04, macos-14} with no `allow_fail` | The `rakun-websocket` cap is load-dependent (handed to 04-rakun). The comment at `rakun/.github/workflows/test.yml:13-15` (glibc 2.36, "22.04 cannot start") is stale since decision 219 |
| 100 gate-onze | **DONE** | 0 if-operand sites. CI comment says no `allow_fail`; `onze-server` and the examples come from runner discovery. `.gitignore` guards present. Hook identical | none in-front |
| 101 gate-jhonstart | **DONE** | `targets` gone from the counter/todo manifests. `dom-test` is `["commonJS"]`. `repro/` is gone. Guards and hook identical | — |
| 108 gate-erika | **DONE** | Guards present. CI has no beam/windows row. `"otp"` read from `botopink.json` | — |
| 109 gate-emilia | **DONE** | `known-broken-examples.txt` is gone. Guards and hook identical | — |
| 110 gate-wasm | **DONE** | `e221a35b` (merge). `tests/language/expected-failures.txt` is absent | std-on-wasm group 3 moved to the 02 README (decision 230). **No front owns it** (see I-14) |
| 111 beam-and-targets | **DONE** | `910017ea`. `run.sh:199-201` has `all=(commonJS erlang wasm beam)`. 19 `run/*.targets` remain (the README audited them) | — |
| 112 gate-format | **DONE** | `fc6e4590`. `format-check.sh` TREES covers `examples`, `libs/{std,routing,actions,validation,log,http}`, `compiler-cli/tests`, `manifest/tests` and `tests/language`. The structural exemption is documented | — |
| 113 ledger-and-scripts | **DONE** | `413d7544`, `d904773b`. `restricted-targets.txt` and `known-red-libs.txt` are absent. Meta `scripts/language-gap-markers.sh` exits 0 | — |
| 114 docs-and-ci | **PARTIAL.** Steps 1, 2, 4 and gate landed (`29cfffc8`). Step 3 box 1 landed: no `allow_fail`, no windows row in `test.yml`. **Step 3 box 2 open** | The four CI fixes the spec calls "unlanded" **are on feat, first-parent**: `d5e8dbf8` (test-web wasm32), `f95fc626` (`test-libs.sh` bash 3.2), `a8808e6e` and `2dcd7b54` (`run.sh` bash 3.2 / BSD xargs). Also on feat: `bbfb61d7` (pool.sh `with_timeout`, no GNU timeout), `192f87d9` (macOS `/private/var`). `test.yml` rows are `[ubuntu-22.04, macos-14]`, with `test-web` at `:239-241` | Only blocker: a green GitHub run of botopink-lang `test` on `feat`, which could not be checked here. Carried items: windows drift measurement; handed-out `docs.md:5` and `build.zig:574` (still describe `skip`) |
| 115 gate-perf | **DONE** | `b51d34a7` | Idle runs carried by 133 / next milestone |
| 131 build-cache | **DONE** (step 3 dropped, decision 232) | `e3b0aa8b`, `6637b626`. `cli/clean.zig` exists. Caches under `.botopinkbuild/cache/`. `userCacheDir` absent | — |
| 132 otp-pin | **DONE in botopink-lang + 5 libs.** One gap | `f6c8722d`. `OTP_RELEASE` in `manifest/src/root.zig`, read by `gate.sh:222`. All 5 library manifests carry `"otp"`. All 5 library workflows read it | **vscode-extension `test.yml:81-85` still runs `apt-get install -y erlang`** (ubuntu-22.04 ships OTP 24, not 28), although its comment says `botopink check` evaluates comptime through erl. 132 step 3's "every workflow's install step takes the release from the compiler" is false there. vscode's last CI-relevant commit (10-02) may predate the OTP check reaching feat, so its "green" may be stale. Likely a latent red |
| 133 gate-speed | **DONE per decision 265, with gaps** | `838f565a`, `b22aaa1d`. Result store under `.botopinkbuild/cache/results/` | **`scripts/gate.sh:102` is still `budget_cold=300`**, and the comment at `:492` still says "5 minutes cold". Decision 265 (`decisions-taken.md:168`) says `budget_cold=450`. That change has not landed. Step 2 box 2 is ticked but `README.md:118-119` says "emitted modules not yet diffed". No ~7m30s cold run is recorded in the README; the last full cold figure there is 9m31s loaded (`:60`) |

Track exit gate: every front except 114 step 3 box 2 is landed on feat. The last *recorded* green cold gate is on `0041d38c`. No cold-gate verdict is recorded on any tree that contains `gate-integration-7…14` (including 97's merge). The spec's "green under the cold gate" claims for later merges are therefore unrecorded.

## Track 02-std-and-packaging

| Front | Verdict | Evidence | Remaining / blockers |
|---|---|---|---|
| 97 std-dedupe | **PARTIAL.** Steps 0, 1 (3 of 4 boxes), 2 (2 of 3), 3 (2 of 3), 4 (1 of 2), 5 (2 of 3), 8, 9 and 10 **are merged into feat**: botopink-lang `d83613db` "Merge front/97-std-dedupe into gate-integration-13"; meta `df03bc1` | `primitives.bp:306,323` has `parseInt` / `parseFloat`. `json.bp:129-175` has `kindName`, `isObject`, `members`, `field`, `items`. `hash.bp:85` has `pbkdf2Sha256`. `io/clock.bp:256` has `parseDuration`. `async.bp:259,317` has `RetryPolicy` / `nextDelay`. `collections.bp:115` has `ofEntries`. `snapshots.bp` has 0 `External`. No `$stringify` template and no `fn bool()` in `libs/std/src`. `libs/actions` calls `.kindName()` | Open: `bindInt`'s `i32` (`validation/src/binding.bp:124` `parseI32`, needs std narrowing). `schemas.bp:153-170` accessors (owned by 125). 04-rakun has **no** `parseDuration` / `skewOf` / `RetryPolicy` "consume std" rows (grep over `04-rakun/` is empty): step 3 box 3 and step 5 box 3. Step 4 box 2 (`test-libs` counts; now measurable on feat). Steps 6 and 7 (`std-d`, `01std-f` still pending). All 5 Gate boxes are unticked even though it merged. Compiler residuals 1–7; #6 is assigned to "02 (packaging)", but no front of track 02 carries it |
| 98 packaging-tail | **NOT STARTED** | No `erika-test` helper (`modules/erika-test/src/root.bp` only, no `test/`). No `scripts/check-packaging.sh`. 0 per-example READMEs in any library. `docs/botopink-json.md` has no takeover line | All 4 steps. Step 3's first fact already holds on disk: `git -C repository/onze rev-parse mocking-lib-final` resolves to `239293a8`. Blocked on the library tracks' helpers/READMEs and on `95-f` and `lg2-v` (both still pending; neither is in `decisions-taken.md`) |

---

## Spec inconsistencies (file:line — problem — proposed fix)

1. **status.md:3-5.** It says "13 of 84 fronts done — the ten `00-gate` fronts", but § Done lists 13 entries, all from 00-gate. It also says "8 are in analysis", but § In analysis has 10 entries. Fix: "the thirteen `00-gate` fronts"; "10 are in analysis".
2. **status.md:7-8.** The count line reads `00-gate 11 · 01-compiler 18 … — 79`. On disk: 00-gate has 14 dirs and 01-compiler has 20, so the total is 84, which matches line 3. Fix: `00-gate 14 · 01-compiler 20 … — 84`.
3. **status.md:12-21, "The gate now".** Three problems:
   - It pins `0041d38c`, but feat is `ec77f649` (gate-integration-14).
   - It says the CI fixes are "on an unlanded branch", but `d5e8dbf8`, `f95fc626`, `a8808e6e` and `2dcd7b54` are on feat.
   - It says "next integration (`gate-integration-3`: 97, 104, 106, 26, 04-js …) was red", but integrations 3 through 14 are merged.

   Fix: re-measure the cold gate on `ec77f649` and rewrite the paragraph. If no measurement exists, say so.
4. **status.md:48 and 114 README:97.** Both say "fixed on an unlanded branch". Fix: "fixes on feat (`d5e8dbf8`, `f95fc626`, `a8808e6e`, `2dcd7b54`); waits on a green GitHub run".
5. **status.md:53 (97).** It says "committed on `front/97-std-dedupe` · … · lands after the checker's import fix". It is merged (`d83613db`, meta `df03bc1`). Fix: "steps 0–5, 8–10 landed on feat; left: …". Consider listing the missing 04-rakun consume-std rows.
6. **status.md:60-61 (104, 106; outside this audit's scope, but contradicts "The gate now").** They say "waits on `00-gate` green and 97". `libs/http` and `libs/log` are on feat (`6d9e06cb`, `3b715323`, gate-integration-3). 125 `88679116`, 04-js, 01-checker, 17 and 130 are merged too, yet status says "on `front/…`". This needs a status pass for tracks 01 and 03.
7. **overview.md:70-73, "Where it stands (2026-10-02)".** It says "00-gate is not green … compiler fronts on one local integration branch … only jhonstart/erika/emilia tips on a remote, CI red". This contradicts status.md § Done (13 gate fronts on the remote feat, library CI green). Fix: replace it with a one-line pointer to status.md, or update it.
8. **overview.md:27.** It says 114 covers "the meta repo, which has none", and the per-track count for 01-compiler reads 17 (on disk: 20). Fix: "(meta `hook-integrity` landed)"; 01-compiler fronts = 20.
9. **00-gate/README.md:82-87.** It says "`build.zig:745` pins the bundled glibc at 2.38 … the compiler's row needs a pin ≤ 2.35". `build.zig:746-749` now pins 2.35 (decision 219), and `test.yml` runs ubuntu-22.04. Fix: state that decision 219 landed. Same for `rakun/.github/workflows/test.yml:13-15`.
10. **00-gate/README.md:56 (onze row).** It says "Pre-commit: not re-run end to end … left: one end-to-end hook run". This contradicts `100-gate-onze/README.md:197`, which is ticked: "green end to end … 19 cells … 4 example builds". Fix: update the row.
11. **00-gate/README.md:121-122, 142.** The 115 row owns "`libs.zig` (the dependency-closure cache)". The 131 row owns "the dependency-closure cache and `compiler-core`'s pre-typed package entry". The order diagram says "131 … adds the closure cache". Decision 232 dropped that cache. `fronts.md:41` repeats the same claim. Fix: remove it.
12. **00-gate/README.md:124 and 133 README:20.** They say "budgets: 5 min cold" / "Cold ≤ 5 min (`budget_cold=300`)". Decision 265 sets 450. The code also still says 300 (`scripts/gate.sh:102`, `:492`). Fix: land `budget_cold=450` in gate.sh, or tick nothing until it lands; then update both lines.
13. **00-gate/README.md:177, 183, 193, 197 (exit gate).** It expects 134 cells, 1630 language tests, "94 fences" and "budget 10m00s cold". Measured: 138 (123 + 15), 2061, 100 fences; budget 7m30s per decision 265. The README's own rule (`:160`) requires re-deriving these. Fix: update the numbers.
14. **02-std-and-packaging/README.md:57-61.** The "std on wasm, group 3" box (`io/http`, `async`, `mocks`, `asserts`; decision 230) belongs to no front (neither 97 nor 98) and has no line in status.md. Fix: assign it to 97, as a new step, or to a new front, and add a status line.
15. **97 README:60-66.** "Current state" still says `async.bp` has "no retry policy", `hash.bp` has "no PBKDF2", `clock.bp` has "no duration parser", and `snapshots.bp` uses "its own six templates". Each is false on feat and contradicts the "Landed" bullet at `:48`. Fix: delete these bullets.
16. **97 README:337-346 (Gate).** All boxes are unticked, including "Commit on `front/97-std-dedupe`; no push, no merge", but the front was merged. Fix: tick what the landing satisfied, or record that it merged partially before its gate.
17. **97 README:325 (residual 6).** It is assigned to "`02-std-and-packaging` (packaging)", but 98 does not carry it. Fix: give it to 98, or to `01-compiler/26-cli-tooling`.
18. **98 README:37 and 02 README:24.** They say "30 of 31: 15 emilia, 8 jhonstart, 3 rakun, 2 onze, 1 erika". Those numbers add up to 29, and disk has 29 examples. Fix: "29 of 29 (no per-example README; onze has one directory-level `examples/README.md`)".
19. **02 README:82.** "Numbered decisions continue from 146" is stale; decisions are now at 265. Fix: "continue from the next free number". Also, `decisions-pending.md:21` links to "§ Decisions", but the heading is "§ Maintainer decisions".
20. **132 README:66-71 (step 3).** It is ticked although vscode-extension `test.yml:81-85` installs distro erlang with no OTP pin. Fix: pin OTP from `botopink.json` / the compiler's `OTP_RELEASE` in vscode-extension, or untick the box.
21. **133 README:116-119.** The box is ticked while its own text says "emitted modules not yet diffed". status.md:33 claims "every cell byte-identical". Fix: untick the sub-claim or record the diff. Also, status.md:33's "~7m30s" has no matching measurement in 133's README (last cold figure 9m31s at `:60`). Fix: add the measurement.
22. **100 README:128-131 and `language-gaps.md:158`.** The `indexOf` byte-vs-codepoint row on erlang is still open in both. 97 step 1 says it is fixed (decision 169, `97 README:142-146`). Fix: close or annotate the row in `language-gaps.md` and update the hand-out in 100.
