# Status — 1.0.12-beta

**Date:** 2026-10-09 · **Base** (each repository's `feat`): botopink-lang `146c98ad` (batch 1 of
tracks 00–03 and feat's reds, landed after a green `gate.sh --cold`) · rakun `44831c9` · jhonstart
`324edac` · emilia `42d51ec` · onze `2c03bcb` · erika `0a463f5` · vscode-extension `f041865`

**Fronts:** 70 — **1 done** (129) · **22 partial** · **47 not started**.

| Track | Done | Partial | Not started |
|---|---|---|---|
| `00-gate` | — | 114 | — |
| `01-compiler` | 129 | 01 · 02 · 03 · 04 · 05 · 07 · 12 · 14 · 17 · 18 · 26 · 130 · 134 | 16 · 23 · 24 |
| `02-std-and-packaging` | — | 97 | 98 |
| `03-bundled-libs` | — | 102 · 103 · 104 · 106 · 125 | 105 · 107 |
| `04-rakun` | — | 13 · 92 | the other 18 |
| `05-jhonstart` · `06-emilia` · `07-onze` · `08-bpp` · `09-cardume` · `20-snap` | — | — | all (3 · 2 · 5 · 11 · 1 · 1) |

**Gate:** `scripts/gate.sh --cold` green on botopink-lang `146c98ad` (every stage; test-libs 123
passed, 0 failed; language tests 2353 passed, 0 failed) — 9m18s wall against the 7m30s budget under
load 19–22, so 114 step 7 (≤ 450 s on an idle machine) stays open. The merges of `49455602` / rakun
`a19340b` that went in without a gate are repaired by this landing. botopink-lang's GitHub CI still
owes a green run on `feat` (114 step 3).

Each line: `front/step — what is left · blocker`. Lanes: **L1** finish what is on `feat` · **L2**
the libraries' critical path · **L3** ready to open now · **L4** later, in the waves of
[`fronts.md`](./fronts.md) § Execution order of tracks 03–08 · **L5** blocked on a decision.

## L1 — finish what is already on `feat`

- [ ] 114 s3 — botopink-lang `test.yml` green on GitHub on `feat` · red on `49455602` (2026-10-03 run): `zig fmt --check` (`comptime/transform.zig:1172`, 19d59508 — 01-checker), 15 `std/math` templates refused by `beam_templates` (a443f52d — std-math-uniform), `comptime/eval.zig` literal test `3` vs `3.0` (01-checker) — none in `test.yml`
- [x] 114 s6 box 1 — vscode-extension workflow installs the compiler's OTP 28 (vscode-extension `f041865`)
- [ ] 114 s6 box 2 — one green run of that workflow · the push
- [ ] 114 s7 — a cold gate recorded on the current tip, ≤ 450 s, exit-check counts re-derived · a machine with `zig` and `erl`
- [x] 114 s8 boxes 1–2 — 133's emitted modules byte-identical, measured; rakun's `test.yml` glibc comment says 2.35
- [ ] 114 s8 box 3 — emilia `test.yml`'s jhonstart checkout removed · 06-emilia/33 s2
- [ ] 114 — the four other libraries' `test.yml` (emilia, erika, jhonstart, onze) carry a stale glibc 2.38 comment · none
- [ ] 01-checker s6 box 3 — `throw` in a `case` arm under `@Result` · 04 s6
- [ ] **01-checker s21 (priority, 331)** — every `comptime` runs on the comptime runtime (BEAM or WAT), never on the target; the same value on the four targets; a declared function's reference lifted · rakun `beans()` green unchanged
- [ ] 05-wasm s9 · 04-js s11 · 97 s16 (333) — a merged wasm library (utf8proc) for `unicode.normalize` on wasm and commonJS
- [ ] 139 (332) — `bigint` on the four targets · then 97 s15 (`Decimal`, `Json`'s `Int` / `BigInt` / `Dec`) · 125's bind rule
- [ ] 01-checker s13 — JS-4's two checker gaps · 05 lowering a nested constructor in a `val`
- [ ] 01-checker s18 — numeric literal suffixes (247): built on feat (`49455602`); left: the two `language-gaps.md` literal halves, a cold gate · the `l` literal rule on every target (319)
- [ ] 01-checker s21 — `comptime` evaluated at compile time everywhere (266; ck4-a (c)); a `comptime { … }` block in a function body fails at codegen on commonJS and wasm
- [ ] 01-checker s23 — `Decl.hooks`: every reachable node, annotations with their `Decorator` (277) · then 26 s8, 49 s5, 22 s4
- [ ] 01-checker s24 — typed comptime decorator arguments, `@Decl<T>`, `Field<T>` (`Type.Field<T>`, 308) and `.name` (280; cases in `01-checker/examples/decorator-arguments-280.md`) · then 125 s7, the `nat-*` rewrites
- [ ] decision 281 (references, not strings) — rakun 04 s6, 08 s4, 12 s4 · 130 s7 · 125 s11 · 120 s6 · 127 s5 · 126 s4 · 26 s9 · 53 s7 · each after 01-checker s24
- [ ] decision 282 (a role in the decorator) — 117 s6 · 53 s8 · 51 s8 · 121 s8 · after 01-checker s24
- [ ] decision 285 (the toolchain knows `bpp`, `html`, the prelude) — 116 s2 · 117 s1 · rakun 22 s7 · 26 s10
- [x] 01-checker s25 — the anonymous default `pub default fn (…)` and `pub default Name;` (289); the formatter arm handed to 16
- [x] 01-checker s26 — a `comptime` parameter taking a value or a type (`Atom<T> | type T`, 297); 280 (0)'s `comptime-arg-not-known`
- [ ] decision 290 (no segment config; `revalidate`, `dynamicParams` in `#[page]`) — rakun 22 s8 · 26 s10 · 53 s9
- [ ] decision 291 (`use request()` / `use response()`; no `isPrerendered`) — 122 s1, s3 · 26 s8, s10 · 120 s4
- [ ] decision 292 (`#[reload]`, `#[history]`, navigation hooks, `ScriptStrategy`) — 126 s1–2 · 50 s10
- [ ] decision 293 (`use params<P>()`, `use pageData<D>()`; no page parameter) — 26 s11 · 01-checker s23 (type args) · 117 s7 · 53 s10 · 120 s7 · 121 s9 · 122 s4 · 123 s5
- [ ] decision 294 (`Cookie<T>` declared once; `use cookie(decl)`, `setCookie`) — 104 s6 · 26 s12 · 123 · 127 · 53
- [ ] decision 295 (atoms: `Local<T>()`, `use local` / `use setLocal`; middleware `@Component<RequestBase, Response>`) — 104 s6 · 123 s7 · 127 · 26 s12 · 53
- [ ] decision 298 (typed meta keyed by type: `setMeta(v)`, `meta(T)`) — 130 s8 · 26 s8 · rakun 08
- [ ] decision 299 (`#[config("…")]` typed records; 03r-b reversed) — rakun 04 s7 · 08 · 13 · 15 · 88
- [ ] decision 300 (emilia's typed theme entries, one `#[theme]`) — 34 s3
- [ ] decision 301 (`#[styled(..tokens)]`) — 119 s4 · 53 s12 · after 34 s1 for the build-time sheet
- [ ] decision 302 (a tag's annotation = a decorator: `@Decl`, no return, meta) — 130 s9 · 118 s5 · 119 · 120 · 126
- [ ] decision 303 (an action answers `@Result<T, ActionError>`; no `ActionOutcome`) — 127 s1–s3
- [ ] decision 304 (a store answers `@Result<T, StoreError>`; no `try*` twin, no raise) — rakun 08 s6 · 09 s6 · 65 s4 · 02-erlang s14
- [ ] decisions 311–313 (`declare fn` in a `type` is host-only; the template annotation `#[f "…"]`; erika queries a database — `from User`, holes bound, `limit 1` against `?T`; a repository is `#[repository] behavior` with `#[erika "…"]` or `#[nativeQuery("…")]`, `#[query]` goes) — 01-checker s29 · 16 s9 · 137 · rakun 08 s7 · 130 s5
- [ ] decision 308 (`Field<T>` is `Type.Field<T>` in std; `Type.keys(T)`; a field key at run time) — 01-checker s24, s28 · 134 s2
- [ ] decision 307 (a derived type is a comptime function answering a new type: `pub val RecipeTitle = Type.pick(Recipe, .title);`, `Type` in std) — 01-checker s28 · 134 s2 · 125 s5
- [ ] decision 306 (`#[schema]` becomes `#[validated]`, the type is the only public schema; `Schema<T>` private; value-only forms become field markers) — 125 s12 · 121 s10 · 117 s8 · 127 s5
- [ ] decision 305 (compiler annotations: `label: value`; `@External(fn: f)`, `op: "…"`, `wasi: .X`) — 01-checker s27 · 16 s10 · 05-wasm s5 · 17
- [ ] 01-checker s22 — the `.bpp` prelude scope (270) · 116 hands the prelude list
- [x] 01-checker s19–s20 — type application and `comptime <expr>` (255): on feat (`49455602`)
- [x] 01-checker rows — the `@block` tail refusal, the `$stringify` parser refusal (239), `primitive-type-name-taken`, T17, row 33 re-measured (refused at the alias); a type reached twice through `@TypeInfo.all` and an import accepted
- [ ] 01-checker rows — the comptime body's file, a package's module namespace, two aliased same-named types (310), `@External.Wasm` read on every target, the template memo key, two diagnostics teaching retired spellings · none
- [ ] 01-checker row — a partially returning `@block` type-checks (commonJS prints `null` on the fall-through) · none
- [ ] 01-checker row — a type error in a decorator body (`decl.nope`) escapes the checker as a run-time `{badkey,nope}` · none
- [x] 04-js s1 — the `@block` tail form refused before commonJS (01's `block-tail-value`); the IIFE serves the two shapes left
- [x] 04-js s2 — `$stringify` in a template (164, 239); `render`'s arm and `emitStringify*` deleted
- [ ] 04-js s6 — `throw` in a `case` arm · 01 s6
- [x] 04-js s8 — an integer that leaves its type aborts (264): on feat (`48a096ea`)
- [ ] 05-wasm s1 box 1 · s3 box 2 — `Array.unique` and C-07's cells on wasm · 02 s4, s7
- [ ] 05-wasm s5 — the rest of std on wasm: heap growth, `pow`, astral `contentHash`, `encoding` / `querystring` family cells, the `wat/AGENTS.md` limits row done; left: `unicode` and `json` on wasm and their cells · 05w-i, 05w-j
- [x] 05-wasm s8 — overflow for `u32`/`u64` and the narrow integer types on wasm (264)
- [x] 05-wasm — an `@block`'s `return` is the block's value (decision 2), `run/block_return_is_block_value`
- [ ] 05-wasm row — `_` in a variant payload pattern binds `0` · none
- [ ] 05-wasm row — a nested variant pattern answers wrong · none
- [ ] 05-wasm row — unsigned compare and divide use the signed opcodes · none
- [ ] 02-erlang s4 — `run/array_unique` (C-35) · with 05 s1
- [x] 02-erlang s5 box 2 — a decorator body carrying `\u{…}` (cell: 14 s7)
- [ ] 02-erlang s7 — C-07's erlang tails as `run/` cells · 05's wasm column
- [x] 02-erlang s10 — the block-as-value lowering (R7): the valueless tail refused by the checker, a `return` the block's fun cannot answer last throws to the block's own guard
- [ ] 02-erlang row — an `@block` reassigning an enclosing `var` makes `erlc` refuse the module (`Acc@1` unbound) · none
- [x] 02-erlang s12 · 03-beam s7 — one `math` on every OS (263): on feat (`a443f52d`)
- [x] 02-erlang s13 · 03-beam s8 — an integer that leaves its type aborts (264): on feat (`48a096ea`)
- [x] 03-beam s9 — a lambda a `case` arm answers is the arm's value (`language-gaps.md` row 28 deleted); an `@block`'s `return` is the block's value; an in-frame loop's head keeps a forward entry under `beam_jump`
- [ ] 03-beam row — a variant name declared by two enums with different fields binds the whole value on a positional pattern (`modules/variant_positional_payload_same_name`, held) · none
- [ ] 03-beam s1 box 3 — the checker's two binding shapes on beam · 01 s13
- [ ] 03-beam s2 box 1 — C-07's `run/` cells on beam · 02 s7 · 05
- [ ] 12 s1 box 2 — `--cold` with the pre-existing tool set · 114 s7
- [ ] 12 s2 box 1 — `run/array_unique`, `run/throw_in_case_arm_result` · 02 s4 + 05 · 01 s6 + 04 s6
- [ ] 14 s2 — the N=200 slope · 18's runtime-evaluation stage · 01's memo key
- [ ] 14 s6 — the decision-gated rows · lg2-j, lg2-o, lg2-w
- [x] 14 s7 — a `comptime/tests` fixture for a `\u{…}` decorator body
- [ ] 17 s1 box 4 — the per-row increment of a keyed `Dict` · 17-b
- [ ] 17 s2 — the `@BeamMemory` text and the migration handed over · 07 s6 · the rakun track
- [x] 26 s2 box 3 — measured: rakun's `orm_host.bp` workaround deletable (move to `src/orm/host.bp`; rakun-data 128 passed) — the deletion is a rakun-track row (L2)
- [x] 26 s3 — only a direct dependency is importable (T4, 242): located refusal, `modules/transitive_package_import`
- [x] 26 s4 — `build` and `test` print checker warnings
- [ ] 26 s6 — lg2-v's resolver half · lg2-v
- [x] 26 s7 — `build.zig`'s `test-docs` comment
- [x] 26 s8 — 206's residuals: the LSP reports `module-import-with-from` and `unresolved import source`; a package importing itself by name refused (309), std's three sources migrated
- [ ] 26 s9 — a dependency's sidecars and imports answer as its own build does · none
- [ ] 26 row — the LSP does not yet make the 309 refusal (the engine's `importSourceProblems` passes no package name) · none
- [ ] 130 s5 — the remaining decorator sites (38 of 119 done, plus `#[schema]`'s 5) · rakun's DI on 01 s20 · rakun sites under the 130↔128 rule (03r-ao, only the record) · rakun-client's on the behavior-member gap (ctr-q closed: the table built at comptime, 281, 256)
- [ ] 130 s6 — module-level `@emit` removed · 130 s5 · `#[schema]`'s free functions → members of the type (306; `T.parse(…)`, 327)
- [ ] 134 s2 — the type functions, the `@Result` methods, `@is` refused (322), `result` deleted and `?T` methodless (330)
- [ ] 01-checker s31 — `?T` by `??`, `?.`, `?.[]`, `?.()`, `x!` (330); the migration script before the refusals
- [ ] 134 s4–s6 — variadic parameter and the print builtins (267); the `Decorator` type for `with:` (268); `use @getContext(T)` (269)
- [ ] 07-residuals s8 — the lib-agnostic gate names every library: the test-file comments reworded; the other owners' comments, then the `-w` pattern · 02 and the other owners landed (s3, s5–s7, s12, s13 done)
- [ ] 07-residuals s1, s2, s4 — the codegen and comptime report waves, three renames · 02–05 landed · 01 landed
- [ ] 07-residuals s9 · s10 · s11 — `->` arms · erika's C-13 migration · the pointers' sweep (last) · C-14 · 16 s1–2 · every library merged
- [ ] 97 s1 residue — `bindInt`'s `i32` through std · std has no `i64` → `i32` narrowing
- [ ] 97 s2 residue — no `Json` accessor copy left in `libs/` · 125 s2 residue (`schemas.bp`)
- [ ] 97 s3 · s5 residue — rakun's `parseDuration`, `skewOf` and four retry loops as "consume std" rows · no 04-rakun front carries them yet
- [ ] 97 s4 residue — the engine under every `-test` member, `test-libs` counts · none
- [ ] 97 s11 — std on wasm, group 3 (230) · 97-a, 97-b, 97-c (`io/http`, `async`, `testing/mocks`), 110-a
- [x] 97 s12 — `unicode.fromCodepoint` a `fn:` over `String.fromCodepoint` on all four targets (with `powBody`, `fn:` transcendentals, code-point `contentHash`)
- [ ] 97 row — an embedded std file's reserved-word error is unlocated · none
- [ ] 104 s5 — the consumer sweep · 04, 65, 79, 12, 19, 22, `08-bpp/123`, 49, 51 landed (188)
- [ ] 106 s2 — consumers: 17's and 26 s4's boxes; rakun-web's `problem_digest` commit · 65 landed · ctr-k
- [x] 125 s0 residue — the `f32` and `url.parse` platform facts as tests
- [x] 125 s2 residue — the examples as suite cases, the 2 000-deep test, the refusal test, `schemas.bp`'s accessors
- [x] 125 s3 — checks and formats (39 `surface.md` rows)

## L2 — the libraries' critical path

- [ ] 138 (decision 326) — `actions`, `http`, `log`, `routing`, `validation` to `repository/<pkg>` (history kept), `cardume` as a submodule, the compiler embeds std alone · the six GitHub repositories (maintainer) · before 102 s3 / 103 s2's consumer commits
- [x] 102 s1–2 — `conventions.bp` and the segment helpers in `libs/routing` (re-implemented)
- [x] 103 s1 — `id.bp` (`deriveActionId`, `isActionId`) in `libs/actions` (re-implemented)
- [ ] 102 s3 (W2) — consumers, one commit per member, rakun's first (`rakun-app`, `rakun-hateoas`), then jhonstart `routes.bp`, onze `types.bp`, `scan.bp`, `chunk.bp` · 102 s1–2 landed · decision 323
- [ ] 103 s2 (W2) — consumers: rakun-app `actions.bp`, jhonstart-forms `form.bp` · 103 s1 landed · the `deriveActionId` / rakun-app `actionId` wrapper choice to confirm
- [ ] 128 (W3) — the nine merges, alone in rakun · the rakun commits of 102 s3 and 103 s2 · ctr-k
- [ ] 130 ↔ 128 — 128 does not wait on 130; no 130 rakun commit while 128 is open; after it, each is a decision-188 consumer commit · **to confirm** (03r-ao — only the record; the fronts follow (a))
- [ ] rakun group A (W4–W5) — 04 (s1, the tag epoch, first) · 74 · 08 (s1 after 04 s4) · 15 · 79 · 81 · 93 · 73 · 19 s1 · 128 landed
- [ ] rakun group B (W5–W7) — 13 (04 s1) · 12 (04 s1, 19 s1) · 22 (04 s5) · 17 (13 s2) · 11 (22) · 65 · 09 (19 s1, 13) · 91 (15) · 92 (74, 15) · the A step each names
- [ ] rakun group C (W8) — 88 (81, 93, 92, 04 s4, 73) · 19 s2–5 (15 s1, 04 s4) · group B
- [ ] rakun-websocket `test/limits_test.bp:48` — a load-dependent cap the gate can meet · `00-gate/114` step 9
- [ ] rakun track — remove the workarounds the compiler made deletable: rakun-data `rows.bp`'s `longOf` (C2 fixed), `runtime.bp`'s row-89 named fn (row 28 fixed), `orm_host.bp` → `src/orm/host.bp` (26 s2) · `04-rakun` RX-14
- [ ] rakun track — latent `i32` clocks: `migration_host.cellNowMs`, the test-only monotonic `nowMs` in `rakun-mail`, `rakun-rsocket` and `tls_listener_test`, `Duration.millis` · `04-rakun` RX-15
- [ ] rakun track — stale `__rkMake_` text in rakun's `AGENTS.md` · `04-rakun` RX-16

## L3 — ready to open now

- [ ] 118 — the template language, tag annotations (278), `prelude.bp`, the node type · none (props-d/e/f hold their boxes; ctr-r closed: 118 goes first, org-3 holds)
- [ ] 121 s1–2 — Markdown to `Element` in the new member `onze-content` · none
- [ ] 34 s1–3 — `hashHex` → std and the cross-library comments; the five families; the breakpoint refusal · s2: 05emilia-l confirmed · opens before 118's carve-out (ctr-v / 189, only the record)
- [ ] 33 s2 — `emilia-card` emilia-only, the fifteen example READMEs (s1, s3, s4 are 135's) · none (ctr-v / 189, only the record)
- [ ] 49 s1 · s6 — consume std's `Json` accessors in `config.bp`; the `onze-test` group stubs · none — not beside 102 s3's onze commits (188)
- [ ] 50 s1 — consume std in `onze-cli` / `onze-bundler` · none — not beside 102 s3's `scan.bp` / `chunk.bp` commits (188)
- [ ] 51 s1 — consume std (`fn intOf` in `svg.bp`, `metrics.bp`) · none
- [ ] 27 s1 box 1 · s2 · s3 — the reconcile driver, `use linkStatus()` under a `@Component`, the example · 27-a to confirm

## L4 — later, in waves

Wave numbers are [`fronts.md`](./fronts.md) § Waves.

- [ ] decision 321 (qualified beans: `#[qualifier("label")]`, `ctx.resolveNamed(Type, "label")`, `resolveNamed(Type)` the primary, labels checked at build) — 130 s5 · rakun 04 s6
- [ ] decision 320 (string index: codepoints on every target; erlang leaves `string:length/1`; commonJS native when no surrogate pair) — 97 s14 · 04-js s10 · 02-erlang s15
- [ ] decision 319 (`i64` is 64-bit on every target; commonJS a number below 2^53, a `BigInt` above; literal refused past the type's range everywhere; 176, 264 amended) — 04-js s9 · 01-checker s18 · 97 s13
- [ ] decision 318 (one decorator per role, rakun's names: `#[component]`, `#[repository]` on a behavior, `#[provides]`, `#[httpClient]`, `#[listen(dest)]`, `#[controller]`, wrappers; closes 130-c, erk-c) — 130 s5 · rakun 04 s8 · 08 s7 · 12 s6 · 13 s6 · 15 s8 · 19 s7 · 79 s4 · 91 s2 · 93 s4
- [ ] decisions 315, 316 (no module annotation; a decorator wraps its function, `decl.wrapWith`, typed) — 01-checker s30 · rakun 12 s5 · 15's example
- [ ] 137 (`04-rakun`) — erika's database target: holes, `QuerySource<T>`, the grammar, `#[erika "…"]` · s5: 01-checker s29 · s2's body form: erk-a
- [ ] 136 (`09-cardume`) — cardume: the core, `rakun-cardume`, `jhonstart-cardume` · `botopink/cardume` to be created and pushed · 26 · 120 · 125 · atm-a (reduced: the cookie hooks) · atm-c · s8: atm-d
- [ ] 26 (W3) — the core: s0 merges `jhonstart-html`, s1–6 · 118 landed · 102 s3 `routes.bp` · s5: 29-a (reduced: `registerRouteStarters` + `globals.starters`) · s8: 01's hooks capability, ctr-l (only the record) (s7 is 135's)
- [ ] 27 s1 box 2 (W7) — the route-kind flag read · 22
- [ ] 67 (W4) — the DOM-side forms boxes, the wire names handed in · 26 · 103 s2 · 67-a (only the record) (s4 needs only 103 s2)
- [ ] 49 s2–5 (W3 → W7) — query, headers, dispatcher; the digest's sink; the public root; the dynamic mark · 102 s3 · s3: 26 s4 + 17 · s4: 65 s1 · s5: 22 s4 · 49-e
- [ ] 50 s2–7, s9 (W3 → W8) — `dev`, `prerender/`, the signal, `bin/onze`, the bundler tail, the defaults table; the `@/` alias gone (218) · 102 s3 · s2: 50-b · s4, s7: std-d · s5: 71 s2 · s6: 27 s1
- [ ] 51 s2–6 (W7) — single flight and the route, the prop table, the metrics generator, the OG defaults · 22 · s4: 52-a
- [ ] 71 s1–2 (W3) · s3–4 (W7) · s5 (W10) — ERTS copy and `bin/onze`; shutdown over real cells and static export; the four gate boxes over the blog · 49 s6 · s3: 11, 04, 81 · s4: 22 · s5: 50, 53
- [ ] 53 (W8) — the blog's `alias` gone, the acceptance script's second half, the browser · 49 · 50 · 51 · 71 s1–4 · 26 · 27 · 67 · 22 · 12 · 65 · 135 s5 (the runner) · s6: 50-b
- [ ] 119 (W3) — scoped `<style>` · 08-d · s2: 118, 26
- [ ] 117 (W7) — `.bpp` / `.md` app files, `staticPaths`, `paginate`, partials · 102 · 22 · 49 · 50 · 121 s1–2 · s1: 293
- [ ] 123 (W7) — `locals`, `sequence`, `actionContext` · 04 · 65 (s1 box 3: 08-j closed → 295/296, `use local(atom)`, the store `rakun-cardume`'s)
- [ ] 120 (W8) — hydration strategies as `#[client…]` / `#[serverDefer]` annotations (278), server islands · 118 · s1: 26 s8 (`clientOnly`) · 119 · 117 · 26 · 22 · 49 · 50
- [ ] 121 s3–6 (W9) · s7 (W10) — frontmatter, collections, references and RSS, `.md` pages; the blog reads Markdown · s3: 08-f · s6: 118, 117 · s7: 53
- [ ] 122 (W9) — page-side status and headers, `rewrite`, `site` · 26 · 49 · 102 · 118 · 120
- [ ] 126 (W9) — view transitions, `#[transition…]` annotations (278) · 27 · 118 · 120
- [ ] 127 (W10) — actions typed by a schema · 125 s6 · 103 · 22 · 67 · 49 · 117 · 120 · 126 · s4: 123
- [ ] 116 (W5 at the earliest) — the `.bpp` file kind · 118 · 26 s0 · 01-compiler/26 · with 01-checker s22 · s6: 293
- [ ] 105 (W9) — bundled `i18n` · 104 s5 · 22 · 26 · 03r-q confirmed
- [ ] 107 (W9) — bundled `release` · 07-g · 71 · 81
- [ ] 124 s1–4 (W10) · s5 (W11) — the commands, the config keys, the `.bpp` scaffold (08-h closed → 285, 224) · every other 08 front · s5: 116, 53
- [ ] 98 (W11) — packaging checked everywhere · every library track's `-test` and README steps · s3: 95-f · s4: lg2-v
- [ ] 16 s1–7 — the `;` re-count, migration and refusal, C-12's reformat, 165, 166/243, C-11 · s2: each library track runs the script · s4: 16-a/b · s6: ctr-s · s3 last, after every tree is migrated
- [ ] 18 s1, s3 — the CI matrix, the bench's open row (s2, s4, s5 done) · s1: the maintainer's push
- [ ] 23 — the import cells and LSP snapshots, the confirmations · 23-a/b/c, std-c
- [ ] 24 — the guide as one program, the confirmations, the per-item cost · 24-a/b/c/g · rakun's `serverAction`
- [ ] 135 s5 (W7) — onze: the E2E runner (five harness functions), the release tree as a path table, 107's README names the two snapshots · snap-a · before 53 s2–6
- [ ] 135 s1–4 (W11, last) — std's `mocks.verify` message; rakun-test's `assertResponse`; jhonstart's `AGENTS.md` paragraph; emilia-test's `assertClassName` / `assertCss` (they replace 97 s7, 19 s6, 26 s7, 33 s1/3/4, 50 s8, 51 s7) · snap-a · s4: 34 landed

## L5 — blocked on a decision

Full text in [`decisions-pending.md`](./decisions-pending.md); confirmations (1.0.10 choices) in its
last section. Open after the 9 Oct revalidation and the answers since (309–333): 56 questions, 8 contradictions, 88
implementation choices.

**First — what blocks now** (`decisoes-pendentes.md` § Prioridade 1, "O que trava agora", set by the maintainer 2026-10-09), in order:
- [ ] 05w-j — 05-wasm s5 (`json` on wasm) · 05w-i → 333
- [ ] 97-a · 97-b · 97-c — 97 s11 (`io/http`, `async`, `testing/mocks` on wasm)

**Then — the botopink shape** (raised 2026-10-04):
- [ ] nat-d6…d9 — case by case (283; nat-d1 → 303, nat-d2 → 304, nat-d3 and nat-d4 → 306, nat-d5 → 307): `nav:` strings (26, 53), lifecycle (rakun 04), `use use…` (53), erika's LINQ names (98)
- [ ] nat-f2…f4 — case by case (284): `onze.json` keys (124), `files`/`workspaces` (98), `ONZE_PUBLIC_` (50, 53)

Then:
- [ ] 17-b — 17 s1 box 4
- [ ] std-d — 97 s6 · 50 s4, s7
- [ ] 95-f — 98 s3
- [ ] 07-g — 107 whole
- [ ] 03r-ab — 09 s5 (and the scope of s1–4) · only the record
- [ ] 03r-ae — 79 s3
- [ ] 03r-af — 73 s3
- [ ] 03r-ak — 81 s3
- [ ] 03r-al — 15 s5
- [ ] 03r-am — 19 s3–4
- [ ] 03r-an — 92 s2 (boxes 1, 3)
- [ ] 67-a — 67 s1–3 · 53's write path · only the record
- [ ] 05emilia-n — 34 s4 (reduced: the four features; the refusal is 300)
- [ ] 50-b — 50 s2 · 53 s6
- [ ] 08-d — 119 every step
- [ ] 08-f — 121 s3
- [ ] props-d · props-e · props-f — 118 s1, s4 (native attributes, named slots, spread)
- [ ] snap-a — 135 s1–5 (replaces 01std-f, 03r-ag, 30-h, 05emilia-m, 53-b) · 53 s2–6 through 135 s5
- [ ] erk-a · erk-b — the body form's source (137 s2, 08 s7) · `#[documentQuery]` under 313 (09 s4) 
- [ ] lg2-a … lg2-w — none opens a front; each opens a step when answered: 01-checker (a, e — only `owner`, q — reduced), 14 s6 (j, o, w), 26 s6 / 98 s4 / 73 (v); the rakun boxes that name them — 04 (e, j), 08 (e), 13 · 65 · 09 · 91 · 92 (a, b), 15 (w), 22 (q), 88 (j), 93 (o) · answered: f, i (280), k (216, 253), r (311–313), t (314), m (315), c (316); g has no subject under 281
- [ ] C-14 — 07-residuals s9 (a 1.0.10 id)
- [ ] confirmations a step waits on — 49-e (49 s2) · 05emilia-l (34 s2) · 52-a (51 s4) · 29-a (26 s5; reduced: `registerRouteStarters` + `globals.starters`) · 27-a (27) · 03r-q (105) · 16-a/b (16 s4) · 23-a/b, std-c (23; 23-c → 317) · 24-a/b/c/g (24; 24-g also 97 s5's surface)
- [ ] ctr-k — 17 · 128 · 106 s2 (only the record)
- [ ] ctr-l — 26 s8's refusal list (only the record) · ctr-s — 16 s6 · ctr-v — 34 / 33 opening before 118 (only the record) · ctr-w — 09 s3
- [ ] ctr-o — lem-c · ctr-p — 04's readers · 104 s5 (ctr-h blocks nothing)
- [ ] 03r-ao — the 130 ↔ 128 rule (128, 130 s5) · only the record
- [ ] lg2-s — module-graph reflection

Closed on 9 Oct (no longer pending): 08-h → 285, 224 · 08-j → 295 · lg2-g → 281 · ctr-q → 281, 256 · ctr-m (= lg2-s) · ctr-n · ctr-r · 111-c → 228 · 03r-b (reversed), 03r-d → 299 · 95-e · 03r-o → 290 · 05emilia-h → 206 · 68-c → 280, 281. `#[schema]`'s free functions → 306 (ctr-u); `not-found.bpp` (213 against 221) → 289. own-a blocks nothing (`fronts.md` § Ownership's provisional rule).
