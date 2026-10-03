# Audit: track 08-bpp and decision bookkeeping, 1.0.11-beta

Audited 2026-10-03. Read-only. Code checked at each submodule's checked-out `origin/feat`:
botopink-lang `ec77f649`, jhonstart `eddd681`, onze `b1a3110`, emilia `42d51ec`, rakun `fac248b`.
Specs are under `/home/user/repo/specs/1.0.11-beta/`, and every path below is relative to it.

---

## Part A: track 08-bpp

### What the code holds today, across the whole track

A grep of jhonstart, onze, rakun, emilia and botopink-lang (`.bp`, `.mjs`, `.erl`, `.zig`) found
none of the track's surface:

| Probe | Result |
|---|---|
| `bpp` / `.bpp` / `"bpp"` / `bppKinds` | nothing (the only hits are erlang codegen variable names such as `BpPat`/`BpPop`). `modules/manifest/src/root.zig` reads `name`, `targets`, `otp`, `src`, `files`, `entry`, `dependencies` and `workspaces`, and has no `bpp` key |
| `pub default fn` in jhonstart | none. `jhonstart-html/` still exists as a member (`src/html.bp`, `root.bp`), so `05-jhonstart/26` step 0 (decision 200) has not happened |
| `onze/modules/onze-content` | absent. onze has `onze, onze-assets, onze-bundler, onze-cli, onze-og, onze-release, onze-server, onze-test` |
| `emilia/modules/emilia/src/scoped.bp` | absent. Nothing matches `scopeCss`, `is:global` or `define:vars`. The only `:global` hit is a comment in `onze-assets/src/style_module.bp:15` saying it is out of scope |
| `client:visible/idle/media/only`, `server:defer`, `server_islands.bp`, `island_strategy.bp` | none. Only the existing load-time hydration exists (`jhonstart/src/client.bp`, `island_runtime.mjs`, `sidecars/jhonstart_island.erl`) |
| `transition:name`, `startViewTransition` | none. `jhonstart-link/src` = `link.bp, link_runtime.mjs, reconcile.bp, root.bp` |
| `set:html`, `class:list` | none |
| `getCollection`, `frontmatter`, Markdown | none |
| `staticPaths`, `paginate`, `onze/src/paginate.bp` | none. `onze/src` = `config.bp integration.bp root.bp types.bp` |
| `rakun/src/locals.bp`, `sequence` | absent. `rakun-web/src/middleware.bp:54` already has `rewrite(path)` (a pass/rewrite `Response`), which 123 extends |
| `ActionError`, `typed_action.bp`, `typed_call.bp` | none |
| `onze sync`, `create-key`, `ONZE_KEY` | none. `onze-cli/src/main.bp:99-103` = `create, info, dev (stub: "not available yet", front 50 step 6), start, build` |
| `libs/routing/src/conventions.bp` (102, which 117 extends) | absent on feat, because 102 has not merged. `libs/actions` has no `id.bp`, because 103 has not merged |

No 08 front README has a ticked box. The open-box counts are 116: 25, 117: 20, 118: 27, 119: 16,
120: 23, 121: 25, 122: 15, 123: 16, 124: 16, 126: 16, 127: 16. Every front is **not started**,
which matches `status.md` (all of them sit under § Open).

### Per front

| Front | status.md line | Verdict | Evidence | Remaining | Blockers |
|---|---|---|---|---|---|
| **118** components (critical) | `status.md:85` (after `101-gate-jhonstart` · no open question) | **Ready to open, not started.** 101 is done | Defects named in the README are still in the code (`jhonstart-html/src/html.bp` is unchanged, there are no `{expr}` holes, and static attributes are dropped) | Steps 0–6 (27 boxes) | None open. Decisions 190–193, 204, 207 and 223 are taken. Three points have no id yet (fronts.md §: how a named slot and a native tag's attributes follow 192/193). Note: README lines 71, 119, 132–135, 197 and 300 still show the pre-223 `Children` signatures as current state, which is fine as measurement |
| **121** content | `status.md:86` | **Steps 1–2 can open now, not started.** onze-content is absent | No Markdown code in any repository | Steps 1–7 | Step 3 waits on **`08-f`** (open). Steps 4–5 wait on 125 steps 0–2. **125 is already merged into botopink-lang feat** (`88679116`, `libs/validation/src/schemas.bp`), so steps 4–5 are effectively unblocked by the code; check whether 125 steps 0–2 count as landed |
| **119** styling | `status.md:87` (on `08-d` · after 118 and 26) | **Blocked by a decision.** scoped.bp is absent | — | Steps 1–3 | **`08-d`** (open) blocks every step, step 1 included. Step 2 waits on 118 and 26 |
| **123** middleware | `status.md:88` | **Blocked by other fronts.** No locals.bp | `rewrite()` exists in rakun-web | Steps 0–4 | `04-rakun/04`, `04-rakun/65` (both not started; they wait on 128). No decision |
| **117** routing | `status.md:89` ("117 on `08-b`") | **Blocked by other fronts. The decision blocker is stale** | No paginate or staticPaths; 102's `conventions.bp` is not on feat | Steps 0–5 | **`08-b` was answered by decision 203** ((a) one convention), yet status, fronts.md, the 08 README and decisions-pending still call it open. Step 4's second box ("how a route handler becomes a prerendered static file is not stated… waits on that answer", `117-bpp-routing/README.md:155-160`) **was answered by decision 222** (a route handler is never prerendered). That box (`app/rss.xml/route.bp exports to <outDir>/rss.xml`) now **contradicts 222** and must be rewritten or dropped. Decision 221 (`bppKinds`, the decorator from the file name) should be cited for step 1. Fronts still to land: 102 step 3, 04-rakun/22, 07-onze/49, 07-onze/50 |
| **120** islands | `status.md:89` ("120 step 4 on `08-e`") | **Blocked by other fronts. The decision blocker is stale and changed** | Only load-time hydration exists | Steps 0–5 | **`08-e` was answered by decision 224** (configurable, default sealed AES-256-GCM, mode in `onze.json` `"islands": {"props": "sealed"}`). That raises **`08-e2`** (which other modes the setting may name), and **`08-e2` is in no pending list**. The 120 README (`:9`, `:111`) cites "decision `08-e`" without 224 or the config key. Fronts still to land: 118, 119, 26, 22, 49, 50, 117 |
| **122** data | `status.md:89` | **Blocked by other fronts** | — | Steps 0–3 | 26, 49, 102 (navigation.bp), 120 (on the core's manifest). No decision |
| **126** view transitions | `status.md:89` | **Blocked by other fronts** | jhonstart-link has no transitions files | Steps 1–4 | `05-jhonstart/27` (the reconcile body), 118, 120 (html.bp order). No decision |
| **127** actions | `status.md:89` | **Blocked by other fronts** | — | Steps 0–4 | 125 steps 0–2 and 6 (0–2 merged on feat, 6 not), 103, 04-rakun/22, 05-jhonstart/67 (on `67-a`), 07-onze/49, 123. No decision of its own. Its example `examples/typed-action-example.bp` carries a LANGUAGE GAP marker (**A method's own `@Decl` has no parameter list**) |
| **116** file format | `status.md:90` (no open question, decisions 198–200) | **Blocked by other fronts. Spec partly stale** | No manifest key; no `.bpp` in the scanner, resolver, LSP or test runner | Steps 0–6 (25 boxes) | 118, 26 step 0, `01-compiler/26` (merged several times into feat, but its README still reads `26-a` as open, `26-cli-tooling/README.md:94`, although 242 answered it). README § Notes item 1 (`116-bpp-file-format/README.md:253-258`: "how a page gets its route and its decorator is not said") **is answered by decision 221**. Item 2 (the return type `-> Element` against `@Component<…>` when the header uses `use`/`await`) is still unstated and has **no id**. `examples/bpp-template-function-example.bp` is marked "to be deleted" and still exists. The README cites 212, but not 213 (the default fn is named after the file) or 221 |
| **124** CLI (last) | `status.md:91` (`08-h`) | **Blocked by a decision and by every other front** | `onze-cli` has no sync or key command | Steps 1–5 | **`08-h`** (open). 07-onze/50, 71, every 08 front. **Inconsistent with 224**: README `:10`, `:74`, `:84` define the config key `islandKeyEnv` (env var name, default `ASTRO_KEY`), but decision 224 fixes the key in `ONZE_KEY` or generates it per build, and puts the mode in `"islands": {"props": …}`. Reconcile the five-key list with 224 (`islandKeyEnv` against `islands.props`) |

### Track README (`08-bpp/README.md`) staleness

- `:174-177`: "each takes the next free number (225 onward…)". The next free number is **266**. "Open: `08-b`, `08-d`, `08-e`, `08-f`, `08-h`" should read **`08-d`, `08-e2`, `08-f`, `08-h`**, with `08-b` answered by 203 and `08-e` by 224.
- `:191-200` (§ 08-b) and `:225-236` (§ 08-e) still read as open questions. Move them to "Answered" blocks citing 203 and 224, and add the `08-e2` question text.
- `:183` (decision 198 row): "Everything before a `---` line…" is the spelling **superseded by 212** (the header sits between two `---` lines at the top of the file). `:69-71` repeats the old reading.
- `:184` (decision 199 row): "`pub fn card(props: Props)`" is **superseded by 213** (`pub default fn PostCard(props: Props)`, named after the file). 116's README already uses 213's form.
- `:110` (Order): "116 ◄── 118 · 05-jhonstart/26 · 01-compiler/26 (decisions 198–200)". It should also cite 212, 213 and 221.
- `surface.md:59`, `:215` cite "decision `08-b`" and "decision `08-e`" by id. Add 203 and 224.

---

## Part B: decision bookkeeping

### B.1 Open pending ids (genuinely unanswered after cross-checking decisions-taken 144–265)

| Id | Track | Blocks | Recommendation |
|---|---|---|---|
| `08-d` | 08 | all of 119 | Answer (a) `emilia.scopeCss` through jhonstart-emilia. It is the first html.bp appender after 118, so it is on the critical chain 118→119→120→126→127→124 |
| `08-f` | 08 | 121 step 3 (frontmatter); a 97 row under (b) | Answer (b): Markdown in onze-content, YAML in std. 121 steps 1–2 do not wait on it |
| `08-h` | 08 | 124 | Answer (a) `onze.json` + `onze <cmd>`. It is last in the track, so it is low urgency |
| `08-e2` (**unlisted**) | 08 | 120 step 4, 124 step 3 (which modes `islands.props` may name) | Add it to decisions-pending and the 08 README. The decision-67 reading is "sealed only", which would make the setting moot |
| `07-b`, `07-h` | 03 | nothing (fronts.md:292) | Confirm the recommendation in bulk |
| `07-g` | 03 | 107 (conditional front) | Answer it or defer 107 out of the milestone |
| `07-j` | 03 / 125 | the size of 125 steps 3–10 | Answer it, since 125 steps 0–2 are already merged |
| `std-d` | 02 | 97 step 6; 50 steps 4 and 7 | Answer it, because it blocks onze's `start`/`dev` signal path |
| `01std-f`, `03r-ag`, `30-h`, `05emilia-m`, `53-b` | 02/04/05/06/07 | the snapshot-map steps (97 s7, 19 s6, 26 s7, 33 s3–4, 50 s8, 51 s7, 71 s6) | Give one answer for all five: retire (status § Deferred already proposes it) |
| `std-e` | 02 | language-gaps row "No test lifecycle hooks" | Answer (a): no hooks. It closes a gap row |
| `95-f` | 02 | 98 (record only) | Confirm it |
| `03r-ab`, `03r-ad`, `03r-ae`, `03r-af`, `03r-ak`, `03r-al`, `03r-am` | 04 | 09, 91, 79 s3, 73 s3, 81 s3, 15 s5, 19 s3–4 | Answer them before 128 opens rakun group A/B |
| `67-a` | 05 | 67 steps 1–3 (onze 53's write path) | Answer it (it is listed as #2 by impact in fronts.md) |
| `50-b` | 07 | 50 step 2 (`onze dev`) | Answer it together with `67-a` |
| `05emilia-n` | 06 | 34 step 4 | Answer it |
| `17-b`, `17-c` | 01 | 17-beam-memory step 1, fourth box (`17-c` blocks nothing) | Answer (a) for both, which closes 17 step 1 |
| `134-a`, `134-b`, `134-c`, `134-d` | 01 | the three `@print` rows held `declaration` (a); nothing (b, c); the last undeclared builtin row (d) | Answer them now: the front merged (`ec77f649`), and a, c and d are confirmations of what was built |
| `lg2-a` … `lg2-w` (23) | 01 / libs | the language-gaps rows and the fronts each names | Confirm the (1)/most-restrictive recommendations in bulk, **except `lg2-k`** (de facto answered, see B.2) and `lg2-l` (01-compiler README:264 says "may be answered de facto") |
| Confirmations (24-a…, 23-a…, 01c-a/b, ck2-a/b/d/e, rc3-a…c, 16-a/b, 0405-b, 01std-a/c/d/e, std-a…c, 95-a…e, 03r-a…x, 26-b, 27-a, 29-a, 30-b…g, 31-a, 05emilia-a…l, 49-*, 50-a, 52-a, 53-a, 68-*, 69-a, lem-a…f) | all | mostly nothing; `05emilia-l` (34 s2), `52-a` (51 s4) | Confirm in bulk. `16-a` and `16-b` gate 16 step 4 |
| (no id) aliased imports of two same-named **types** | 01 | `01-checker/README.md:262-267` ("the question is open for the maintainer") | Give it an id in decisions-pending |
| (no id) 116's return type (`-> Element` against `@Component`) | 08 | 116 step 2 | Give it an id (fronts.md:299 lists it as "no id yet") |

### B.2 Pending ids listed as open but already answered

| File:line | Issue | Proposed fix |
|---|---|---|
| `decisions-pending.md:3` | Calls `02e-a`, `05w-c…f`, `05w-g` open. Answered: 02e-a = **240**, 05w-c = **259**, 05w-d = **260**, 05w-e = **261**, 05w-f = **262**, 05w-g = **263**. The line is also a truncated sentence ("…carried verbatim below from 1.0.10-beta's") | Delete line 3 and rewrite one header listing only `lg2-a…w`, `17-b`, `17-c`, `134-a…d`, `std-e` and the 08 / 07 / 02 / 04 / 05 / 06 / 07 ids |
| `decisions-pending.md:5` | "Twenty-seven questions are open — `ck2-c`, …, `02e-a`, `dec-e`, `gw-a`". ck2-c = **244**, 02e-a = **240**, dec-e = **254** (251 was withdrawn, then 254 answered it), gw-a = **264**. The count is wrong | Same as above. The `### 02e-a` (`:334-365`) and `### gw-a` (`:368-404`) sections should move out or say "Answered: 240 / 264" |
| `decisions-pending.md:32` | Lists `08-b`, `08-e` as open | Mark them answered, 08-b = **203** and 08-e = **224**. Add `08-e2` |
| `decisions-pending.md:35-39` | Promises sections "below" for `05w-c…g` ("open — below"); none exist, and all are answered | Rewrite as "answered: 238, 241, 259–263" |
| `decisions-pending.md:36-37` | `gate-k…p` answered 225–228, 230, 231. It omits gate-q (232), gate-r (233), gate-s (249) and gate-t (246) | List them for completeness |
| `status.md:49` | 130 "rakun's DI … held on `dec-e`" | Answered by **254** (+256), and `Declared<unknown>[]` is built (`14cf36ce`). Reword to "the rakun migration under 254/256" |
| `01-compiler/130-decorator-outputs/README.md:180-187` | "Open questions 1. `dec-e`" | Mark it answered by 254 |
| `status.md:50` | 04-js "step 2 on `0405-d` (raised)" | Answered by **239**, and its std half is merged (`6330995b`: "Array.join without $stringify") |
| `01-compiler/04-js/README.md:4`, `:52`, `:93` | Treats 0405-d as open | Cite 239 |
| `status.md:56` | 125 "written against the recommendation of `07-n`, which is open … they land with the gate" | 07-n = **257**, and 125 is **merged** into botopink-lang feat (`88679116`) |
| `03-bundled-libs/README.md:136`, `:166-174` | "Open: … `07-j`, `07-n`" and a 07-n row | Drop 07-n (257). The 125 README (`:9`) is already correct |
| `fronts.md:179`, `:276`, `:291` | `07-n` listed as a blocker or open | Drop it |
| `fronts.md:267`, `:269`, `:286`, `:289`, `:219`, `:220`, `:225` | `08-b` and `08-e` as open decisions (08-b ranked #1 by impact) | Replace them with 203 and 224 and add `08-e2`. 117 then has no decision blocker |
| `status.md:89` | "117 on `08-b`", "120 step 4 on `08-e`" | "117 under 203/221/222", "120 step 4 on `08-e2`" |
| `status.md:71` | 05-wasm step 5: "blocked on `05w-f`; `05w-c`, `05w-d`, `05w-e`, `05w-f`, `05w-g` open" | All answered (259–263); remaining is implementation only |
| `01-compiler/05-wasm/README.md:125`, `:143`, `:146-147`, `:139`, `:160` | "blocked on `05w-f`", "`05w-c` answered" / "`05w-g` answered" unticked | Tick the two decision boxes and cite 259/263; re-word "blocked" as "under 262" |
| `status.md:72` | 14-comptime-on-beam "step 2 … waits on `14-a`" | Answered by **237** (decisions-pending:39 and the 14 README:100 already say so) |
| `01-compiler/README.md:132-147` | Table "Open from 1.0.10": `ck2-c`, `lg-a`, `lg-b`, `ck-host`, `D5` | All answered (244, 147, 148, 146, 150). Drop them from the open table |
| `01-compiler/README.md:126` | "the next free number (**146**)" | 266 |
| `01-compiler/README.md:151-245` | Full open-question sections for 01c-c, 01c-d, 0405-c, 16-c, 16-d, 17-a, 23-d, 24-h with no "Answered:" line (0405-d and 26-a have one) | Add "Answered: 151 / 152 / 164 / 165 / 166 (+243) / 168 (+174) / 169 / 179" |
| `01-compiler/26-cli-tooling/README.md:94` | "26-a is open … nothing is implemented before the answer" | Answered by **242** (pending:19 says so) |
| `decisions-pending.md:31` + `lg2-k` (`:190-197`) | `lg2-k` (comptime reflection over the project) is listed open with recommendation (1) "none". Decision **216** (4) "Closes the gaps … No comptime reflection over the project", and `@TypeInfo.all` is built on feat (253/254) | Record lg2-k as answered by 216/253 (option 2-like). Move the language-gaps row (below) |
| `status.md:3` | "13 of 84 fronts done — the ten `00-gate` fronts", while the count line says 79 and § Done lists 13 (11 lines) | Fix the denominator (79) and drop "ten" |
| `status.md:53`, `:60-61` | 97 "committed on `front/97-std-dedupe` … lands after…", while 106-log and 104-http are under § Pending "waits on 00-gate green and 97" | On botopink-lang feat: `d83613db Merge front/97-std-dedupe`, `3b715323 Merge front/106-log`, `6d9e06cb Merge front/104-http` (`libs/log`, `libs/http` exist). Re-state as landed or partly landed |

### B.3 Ids referenced as blockers but missing from decisions-pending

| Id | Where referenced | State |
|---|---|---|
| `08-e2` | `decisions-taken.md:127` (decision 224) | **Missing everywhere else.** Add it to pending and to the 08 README |
| `dec-e` | `status.md:49`, 130 README | Answered (254), not missing. Only the references are stale |
| `05w-*`, `17-b`, `134-a…d`, `std-d`, `01std-f`, `0405-d` | status / track READMEs | All present in pending (05w-* and 0405-d are answered). `17-b`/`17-c` have their full text only in `01-compiler/README.md:200-232` and are not under pending § Open. That matches the "full text lives where raised" convention, but pending:3 lists them as open questions, so the two lists disagree |
| (no id) two aliased imports of two same-named types | `01-checker/README.md:267` | No id. Add one |
| (no id) the 116 return type; the 187 member count; R92-1; named slot / native-tag attributes | `fronts.md:296-299` | Listed as "no id yet". Give each an id, or a line in pending |

### B.4 language-gaps.md: rows closed or re-gated by merged work or decisions

| File:line | Row | Evidence | Fix |
|---|---|---|---|
| `language-gaps.md:20` | "gated … (`lg-a`, `lg-b`, `lg2-a…w`, `ck-host`)" | lg-a, lg-b and ck-host were answered (146–148) | `lg2-a…w`, `std-e` |
| `:92` | **No comptime reflection over the project** (waits on lg2-k) | Decision 216 closes it; `@TypeInfo.all` on feat (`14cf36ce`, `ec77f649`) | Close it, or re-own it to 130/134. Its marker `04-rakun/81-…/examples/release-manifest-example.bp` must go first (check 5) |
| `:115` | **A second binding of one name in one body type-checks…** | `binding-redeclared` on feat (`tests/language/reject/binding_redeclared_in_body.bp`, `binding_shadows_in_inner_block.bp`; decisions 152, 205; 01-checker merged) | Close the row (it has no marker) |
| `:122` | **No structural `==` on records / arrays**, "decision-gated (question `01c-e`)" | 149, then reversed by **210/211/214**; `tests/language/run/record_structural_equality.bp`, `f64_equality_total_order.bp` on feat | Close it |
| `:145` | **`try` inside a lambda does not propagate** (waits on lg-a) | 147; `effect-try-without-fallible-channel` in compiler-core, `run/lambda_result_return_try` | Close it, or drop the "waits on" |
| `:146` | **A `var` mutated inside a lambda … erlang** (waits on lg-b) | Answered by 148 (no matching code found by a quick grep) | Drop "waits on lg-b" and re-own to the step |
| `:144` | **A package reached only transitively … cannot be imported** | Decision 242 (a): that is now the rule, not a gap | Close it as "by design (242)" |
| `:158` | **`string.indexOf` counts bytes … (erlang)** | 169/197/240; `libs/std/src/primitives.bp:228` comment; `run/string_index_of_codepoints` has one `.out` | Close it |
| `:161` | **`Array.unique` answers `[1, 2, 1]` …** | `6330995b` "Array.unique keeps first occurrences" merged (217). The wasm-trap half was not verified | Close the std half; keep the wasm half if it is still red |
| `:154` | **A host template's `__Loop` collides with the erlang `while` lowering** | `run/host_template_binding_inside_while` exists on feat | Probably closed; verify |
| `:134` | **…`f32` has no literal** | 247 decided the suffixes (01-checker step 18, "next" in status); not built | Keep it; owner already cites 247 |
| `:163-166` | `.bpp`/template rows "waits on decision `08-a`" / "`08-a`, `08-i`" | Answered by 198/199/212. Per 198 "the template entry gains nothing — no `template.emit`", rows 164 (a template body cannot add a declaration) and 165 (an emitted import is not linked) are now **by design**, not 116's work. 166 (the diagnostic offset) is answered by 198's "the literal is the file" | Re-word: 163 → 116 under 198/212; 164 and 165 → "by design (198)"; 166 → 116 step 4 |
| `:135` | **A function's `@Decl` does not say which hooks it activates** | Decision 186's capability is still unbuilt (26 step 8 / 202) | Keep it |
