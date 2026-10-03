# Status — 1.0.11-beta

**Updated:** 2026-10-02 · **Progress:** ~14 % landed (12 of 83 fronts done — the ten `00-gate`
fronts in § Done, on the remote `feat` under the green cold gate with no open box; 8 are in analysis and
count for their ticked steps; the milestone opened at 1.0.10-beta's close — [`closure.md`](../1.0.10-beta/closure.md))

Count: `00-gate` 11 · `01-compiler` 18 · `02-std-and-packaging` 2 · `03-bundled-libs` 7 · `04-rakun` 20 ·
`05-jhonstart` 3 · `06-emilia` 2 · `07-onze` 5 · `08-bpp` 11 — 79. A front in analysis counts for its ticked steps.
Order inside each list follows [`overview.md`](./overview.md) § Order (most blocking first); for
tracks 03–08 the waves are [`fronts.md`](./fronts.md) § Execution order of tracks 03–08.

**The gate now** (2026-10-02). `scripts/gate.sh --cold` is green on botopink-lang `0041d38c`, on the
remote `feat`, with OTP 28 on `PATH` — every stage: `test-libs` `123 passed, 0 failed, 15 without
tests, 38 restrictions audited` (no `FAILED cells:` line), `test-language` `2061 passed, 0 failed`
on commonJS, erlang, wasm and beam, `test-docs` `100 fences — 100 checked, 0 skipped, 0 failed`;
12m16s on a loaded machine (over the 10-min budget, printed yellow). GitHub CI is green on the
remote `feat` of rakun, onze, jhonstart, erika, emilia and vscode-extension, and the meta
`hook-integrity` is green; botopink-lang's own CI is not (test-web wasm32 and `test-libs.sh` under
macOS bash 3.2, both fixed on an unlanded branch). The next integration
(`gate-integration-3`: 97, 104, 106, 26, 04-js and the checker's shorthand-import fix) was red on
one cell — a module named like the bundled `log` — which decision 206 answers (front 129).

**The gate at the open** (measured 2026-09-26, `scripts/gate.sh --cold` forced past reds): 8 of 10
stages green; `test-libs` 84 passed / **36 failed** (rakun 25, onze 11); `test-language` 1244 / 1
expected / **1 failed** (wasm); 3 `expected-failures.txt` lines; 21 `restricted-targets.txt` lines
(3 dead, 21 cells unledgered, 9 counts moved); 226 files outside `format-check`'s trees; 11 `zig
fmt` reds; 9 `docs-check: skip`; windows `allow_fail`. Each repository under its own gate: emilia,
erika, jhonstart, vscode-extension **green**; onze ~29 %; rakun ~17 % and its pre-commit fails at
the grep stage before any test.

## Done

- [x] `00-gate/100-gate-onze` — onze's `(if …)` operand sites gone, `onze-cli` green on both targets, the workflow and the pre-commit green end to end
- [x] `00-gate/131-gate-build-cache` — every build cache (erlang verdicts, `.beam`, cell durations, the language server's) under `<workspace>/.botopinkbuild/cache/`, `botopink clean` and `gate.sh --cold` delete them all; the closure cache dropped (decision 232)
- [x] `00-gate/99-gate-rakun` — rakun's `(if …)` operand sites migrated, hook and CI hard; its cells green under the cold gate, its CI green
- [x] `00-gate/101-gate-jhonstart` · `108-gate-erika` · `109-gate-emilia` — one hook and one CI shape per library, every cell green; each CI green
- [x] `00-gate/112-gate-format` — every tree under `format-check` and `zig fmt` green
- [x] `00-gate/110-gate-wasm` — every wasm lowering that cannot proceed is a located refusal; std on wasm leaves 110 (decision 230)
- [x] `00-gate/111-gate-beam-and-targets` — beam in `--target all`, cells honour manifest `targets`, `expected-failures.txt` gone
- [x] `00-gate/113-gate-ledger-and-scripts` — both ledgers deleted, restrictions audited structurally; `test-libs` `0 failed`
- [x] `00-gate/132-gate-otp-pin` — the compiler declares OTP 28 and refuses another `erl`; the gate and the workflows read it
- [x] `00-gate/115-gate-perf` — the cold gate 56m43s → 9–12 min on the shared machine, every tally unchanged; its idle runs and diffs carried by 133 and 131

## In analysis

- [ ] `00-gate/133-gate-speed` — high · decision 229 · step 1 measured (the erl busy-wait the biggest sink) and step 2 landed (busy-wait off, fewer VMs per cell): the cold gate 12m16s → 7m48s on a loaded machine, every cell byte-identical · step 3 (the cell-result store, keyed by full content) next; the idle-machine runs after it
- [ ] `00-gate/114-gate-docs-and-ci` — on the remote `feat` under the green cold gate of `0041d38c`, meta checks 4 and 5 green; waits on botopink-lang's CI green (test-web wasm32, `test-libs.sh` under macOS bash 3.2 — fixed on an unlanded branch)
- [ ] `01-compiler/130-decorator-outputs` — steps 1–4 built (the four places); decisions 235 (`@typeInfo.all(with: [a, b])`) and 248 (one builtin, `@typeInfo`) built; step 5 at 34 of 119 sites (std `#[mocks.mock]`, validation `#[validated]`, jhonstart `#[client]`, rakun-data `#[entity]`/`#[entityRepository]`/`#[belongsTo]`/`#[query]` members, rakun-cache `#[cached]`, rakun-hateoas `#[halResource]`) with a type's members closed (`unknown-associated-fn`); rakun's DI onto the context (234) held on `dec-e` (the boot's `@typeInfo.all` over types whose `make()` differ cannot be typed); next, jhonstart's routes with onze's entry points (236), validation's `#[schema]` (5); rakun-client's `#[httpExchange]` held on a behavior's member reaching an importer
- [ ] `01-compiler/04-js` — steps 3, 4, 5, 7 and C-37 done (`scripts/tsc-check.sh` also runs `node --check` over every emitted module: 79 projects, 364 modules; `run/sibling_blocks_bind_one_name` on four targets, decision 205's legal half) on `front/04-js` · step 1 waits on the checker refusing `@block`'s tail form, step 2 on `0405-d` (raised) and 01's parser kind, step 6 on 01 step 6
- [ ] `01-compiler/01-checker` — steps 1–8 and 10–16 built on `front/01-checker` (the open boxes wait on 02/04/05 and 16); three more `language-gaps.md` rows closed (a generic value widens to its `?T`; a std namespace's type and `pub fn` reached through it; a declaration named like an import refused) · the primitive-named declaration refusal parked on std's `random.bool` · step 17 (decision 244, a default trailing everywhere) built · step 18 (decision 247's suffixes) next
- [ ] `01-compiler/17-beam-memory` — step 1 built on `front/17-beam-memory`: off the BEAM `#[@BeamMemory]` refused at the annotation (decision 167; `test/beam_memory_noop` gone, the `run.sh` exemption gone), `keyed = true` lowered row per key on erlang and beam (decisions 168, 174: `run/beam_memory_ets_keyed` prints `20000 20000`) · the per-row increment and the other row operations wait on `17-b`, `17-c` (raised) · step 2 is 08's text
- [ ] `02-std-and-packaging/97-std-dedupe` — high · the `fs.walk` fix, step 1 and step 2 committed on its branch · steps 3–5 and 8 in progress · steps 3 and 5 land after the checker's import fix (decision 170)
- [ ] `03-bundled-libs/102-routing-conventions` — steps 1–2 (the package), `kindLetter` and the wrap order of `fileKinds()` (decisions 171–173) committed on `front/102-routing-conventions` · step 3 (the consumers) goes first when the gate is green and 97 has landed (decision 188)
- [ ] `03-bundled-libs/103-actions-id` — step 1 (the package) committed on `front/103-actions-id` · step 2 (the consumers) goes first when the gate is green
- [ ] `03-bundled-libs/125-validation-zod` — steps 0–2 on `front/125-validation-zod`, written against the recommendation of `07-n`, which is open · they land with the gate, after 97 · steps 3–10 follow

## Pending

- [ ] `03-bundled-libs/106-log` — high · ready: no open question (decisions 194, 195) · waits on `00-gate` green and 97 · precedes 26 step 4, 17 and 49 step 3
- [ ] `03-bundled-libs/104-http` — ready: no open question (decision 196) · the package half (steps 1–4) waits on `00-gate` green and 97 · the consumer sweep (step 5) waits on 04, 65, 123, 79, 12, 19, 22, 49, 51
- [ ] `03-bundled-libs/105-i18n` — waits on 104, both halves, and on 22 and 26 (decision 180 answered its question)
- [ ] `03-bundled-libs/107-release` — conditional on `07-g` · waits on 71 and 81
- [ ] `04-rakun/128-rakun-consolidation` — critical · first front of the track (decision 187) · waits on `99-gate-rakun` landed and pushed, and on the rakun consumer commits of 102 step 3 and 103 step 2
- [ ] `04-rakun` group B (13 · 17 · 22 · 12 · 11 · 65 · 09 · 91 · 92) — wait on 128 and the group A step each names: `04` step 1 (13, 12), `04` step 5 (22), `19` step 1 (12, 09), 106 (17)
- [ ] `04-rakun` group C (88 · 19 steps 2–5) — wait on group B
- [ ] `05-jhonstart/67-jhonstart-forms` — waits on 26 (the fake DOM), 103 step 2 (`form.bp`) and `67-a`
- [ ] `06-emilia/33-emilia-color-palette` steps 3–4 — wait on `05emilia-m` and on 34
- [ ] `07-onze/53-onze-example-app` — waits on 49 · 50 · 51 · 71 steps 1–4, on 26 and 67, and on `04-rakun` 22 · 12 · 65 (the write path, the public root)
- [ ] `02-std-and-packaging/98-packaging-tail` — waits on every library track (it verifies across seven repositories)
- [ ] `01-compiler/05-wasm` step 5 (std on wasm, decisions 230, 238, 240, 241) — the `@External.Wasm` vocabulary, the codepoint unit, `math` and `escape` done; `unicode`, `json`, `encoding`/`querystring`, `hash`, `io/random` left; `05w-c` open; steps 1–4 done but the two cells 02 step 7 and C-35 owe
- [ ] `01-compiler/14-comptime-on-beam` — step 3 closed and step 1's located fixtures in; step 1's last half (the body's file in the message) and step 5 (T17, re-measured: holds) wait on 01 (`infer.zig` / `env.zig`); step 2 (the N=200 slope, re-measured 6.6 / 9.2 ms per evaluation) waits on `14-a` (which bindings a capture carries) and on an owner for the trace rendering; step 4 (T15) is decision 216's, closing with 130 step 6; step 6 waits on lg2-j/o/w
- [ ] `01-compiler/16-formatter` — waits on `00-gate` (112), the libraries' migrations and 01's parser rows
- [ ] `01-compiler/07-review-backlog` · `08-hygiene` · `09-ecosystem-residuals` — wait on 02–05, on every owner, on 16

## Open

- [ ] `01-compiler/02-erlang` · `03-beam` · `05-wasm` · `26-cli-tooling` — group A · after `00-gate`
- [ ] `01-compiler/12-language-tests` · `18-comptime-runtimes` · `23-std-purity` · `24-effects-by-return` · `25-gate-perf` — group B · after `00-gate`
- [ ] `04-rakun` group A: `04-rakun-erlang-runtime` (critical) · `74-rakun-tls-ssl-bundles` · `08-rakun-data-sql` · `15-rakun-messaging` · `79-rakun-oauth2-sso` · `81-rakun-packaging-release` · `93-rakun-soap-webservices` · `73-rakun-starters` · `19-rakun-test-utilities` step 1 — after 128
- [ ] `05-jhonstart/26-jhonstart-router` (high) · `27-jhonstart-link` — after `101-gate-jhonstart`; 26 after 102 step 3's `routes.bp` commit and after 118 (its step 0 merges `jhonstart-html` into the core — decision 200); its step 4 after 106; its step 8 on the checker capability of decision 186
- [ ] `06-emilia/34-emilia-modifiers` (high) · `33-emilia-color-palette` steps 1–2 — after `109-gate-emilia` and 118 step 1's carve-outs
- [ ] `07-onze/49-onze-stand-up` (critical) · `50-onze-cli` · `51-onze-image` · `71-onze-release-packaging` — after `100-gate-onze`; 49 and 50 after 102 step 3's onze commits; 49 step 4 after `04-rakun/65` step 1 (decision 201); 50 step 2 on `50-b`, steps 4 and 7 on `std-d`
- [ ] `08-bpp/118-bpp-components` (critical) — after `101-gate-jhonstart` · no open question (decisions 190–193)
- [ ] `08-bpp/121-bpp-content` — steps 1–3 after `100-gate-onze` (step 3 on `08-f`) · steps 4–5 after 125 steps 0–2 · step 6 after 118 and 117 · step 7 after 53
- [ ] `08-bpp/119-bpp-styling` — on `08-d` · after 118 and 26
- [ ] `08-bpp/123-bpp-middleware` — after `04-rakun` 04 and 65 (decision 189)
- [ ] `08-bpp/117-bpp-routing` · `120-bpp-islands` · `122-bpp-data` · `126-bpp-view-transitions` · `127-bpp-actions` — after 118 and the front of track 03 / 04 / 05 / 07 each names (`08-bpp/README.md` § Who else owns the files), one at a time where they append to one file; 117 on `08-b` (decision 202 answered `08-g`); 120 step 4 on `08-e`; 127 after 125 steps 0–2 and 6
- [ ] `08-bpp/116-bpp-file-format` — after 118, `05-jhonstart/26` step 0 (`jhonstart-html` merged into the core, decision 200) and `01-compiler/26` · no open question (decisions 198–200)
- [ ] `08-bpp/124-bpp-cli` — last in track 08 · after `07-onze/50`, 71 and every front above · `08-h`

## Deferred out of this milestone

- `04-rakun/91-rakun-pulsar`'s data plane → a decision (`03r-ad`, recommendation: defer until a
  broker double exists); the front carries the codec and admin arm only.
- `04-rakun/79`'s SAML ACS → `03r-ae` (no Exclusive XML c14n on OTP or std).
- The snapshot maps of rakun, jhonstart, emilia, onze, std → one answer for all (`03r-ag`, `30-h`,
  `05emilia-m`, `53-b`, `01std-f`; recommendation: retire, keep the helpers a contract needs and
  onze's § 71 release text).
- The windows CI row → deleted until the snapshot capture normalises CRLF and path separators
  (decision 158).
- Everything in [`deferred.md`](./deferred.md), carried.
