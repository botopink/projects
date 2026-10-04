# Status — 1.0.12-beta

**Date:** 2026-10-03 · **Base** (each repository's `feat`): botopink-lang `49455602` (decisions 263,
264 landed: `a443f52d`, `48a096ea`, `d71b89f5`; 01-checker and 130-rakun-di merged) · rakun
`a19340b` · jhonstart `eddd681` · emilia `42d51ec` · onze `b1a3110` · erika `0a463f5` ·
vscode-extension `7993f96`

**Fronts:** 69 — **1 done** (129) · **18 partial** · **50 not started** (102 and 103 count as not
started: their done steps are on unpushed branches only).

| Track | Done | Partial | Not started |
|---|---|---|---|
| `00-gate` | — | 114 | — |
| `01-compiler` | 129 | 01 · 02 · 03 · 04 · 05 · 12 · 14 · 17 · 26 · 130 · 134 | 07 · 16 · 18 · 23 · 24 |
| `02-std-and-packaging` | — | 97 | 98 |
| `03-bundled-libs` | — | 104 · 106 · 125 | 102 · 103 · 105 · 107 |
| `04-rakun` | — | 13 · 92 | the other 18 |
| `05-jhonstart` · `06-emilia` · `07-onze` · `08-bpp` · `20-snap` | — | — | all (3 · 2 · 5 · 11 · 1) |

**Gate:** a green `scripts/gate.sh --cold` was last recorded on botopink-lang `0041d38c`; no cold
gate is recorded on the current tip — [`00-gate/114`](./00-gate/114-gate-docs-and-ci/README.md)

**Merged without a gate run:** botopink-lang `49455602` (`front/01-checker`: decision 255, numeric
literal suffixes; `front/130-rakun-di`: `x is fn(…) -> T` narrowing) and rakun `a19340b`
(`front/130-rakun-di`: `T.make()` factories) were merged into `feat` without `gate.sh --cold` —
114 step 7 runs it.
step 7. botopink-lang's GitHub CI still owes a green run on `feat` (114 step 3).

Each line: `front/step — what is left · blocker`. Lanes: **L1** finish what is on `feat` · **L2**
the libraries' critical path · **L3** ready to open now · **L4** later, in the waves of
[`fronts.md`](./fronts.md) § Execution order of tracks 03–08 · **L5** blocked on a decision.

## L1 — finish what is already on `feat`

- [ ] 114 s3 — botopink-lang `test.yml` green on GitHub on `feat` (fixes landed) · a run
- [ ] 114 s5 — `gate.sh` `budget_cold=450` and its comment (decision 265) · none
- [ ] 114 s6 — vscode-extension workflow installs OTP 28, one green run · none
- [ ] 114 s7 — a cold gate recorded on the current tip, ≤ 450 s, exit-check counts re-derived · a machine with `zig` and `erl`
- [ ] 114 s8 — 133's emitted modules diffed; rakun `test.yml`'s glibc comment says 2.35 · none
- [ ] 01-checker s6 box 3 — `throw` in a `case` arm under `@Result` · 04 s6
- [ ] 01-checker s10 — a lambda parameter annotation (T12) · 16 s8
- [ ] 16 s8 — the lambda annotation's printer arm · none — lands before 01 s10
- [ ] 01-checker s13 — JS-4's two checker gaps · 05 lowering a nested constructor in a `val`
- [ ] 01-checker s18 — numeric literal suffixes (247): built on feat (`49455602`); left: the two `language-gaps.md` literal halves, a cold gate · ctr-j (the `l` literal rule)
- [ ] 01-checker s21 — `comptime` evaluated at compile time everywhere (266; ck4-a (c))
- [ ] 01-checker s23 — `Decl.hooks`: every reachable node, annotations with their `Decorator` (277) · then 26 s8, 49 s5, 22 s4
- [ ] 01-checker s24 — typed comptime decorator arguments, `@Decl<T>`, `Field<T>` and `.name` (280; cases in `01-checker/examples/decorator-arguments-280.md`) · then 125 s7, the `nat-*` rewrites
- [ ] decision 281 (references, not strings) — rakun 04 s6, 08 s4, 12 s4 · 130 s7 · 125 s11 · 120 s6 · 127 s5 · 126 s4 · 26 s9 · 53 s7 · each after 01-checker s24
- [ ] decision 282 (a role in the decorator) — 117 s6 · 53 s8 · 51 s8 · 121 s8 · after 01-checker s24
- [ ] decision 285 (the toolchain knows `bpp`, `html`, the prelude) — 116 s2 · 117 s1 · rakun 22 s7 · 26 s10
- [ ] 01-checker s25 — the anonymous default `pub default fn (…)` and `pub default Name;` (289) · then 116 s2
- [ ] 01-checker s26 — a `comptime` parameter taking a value or a type (`Atom<T> | type T`, 297) · then 136
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
- [ ] 01-checker s22 — the `.bpp` prelude scope (270) · 116 hands the prelude list
- [x] 01-checker s19–s20 — type application and `comptime <expr>` (255): on feat (`49455602`)
- [ ] 01-checker rows — the `@block` tail refusal, the `$stringify` parser refusal (239), `primitive-type-name-taken`, the comptime body's file, T17, a package's module namespace, two aliased same-named types (imp-a), `@External.Wasm` read on every target, the template memo key, row 33 · the first two unblock 04 s1–2 and 02 s10
- [ ] 04-js s1 — the `@block` tail-form IIFE · 01's `@block` tail refusal
- [ ] 04-js s2 — `$stringify` in a template (164, 239); `render`'s arm and `emitStringify*` deleted · 01's parser refusal
- [ ] 04-js s6 — `throw` in a `case` arm · 01 s6
- [x] 04-js s8 — an integer that leaves its type aborts (264): on feat (`48a096ea`) · ctr-j still open
- [ ] 05-wasm s1 box 1 · s3 box 2 — `Array.unique` and C-07's cells on wasm · 02 s4, s7
- [ ] 05-wasm s5 — the rest of std on wasm: heap growth, `pow`, astral `contentHash` done (`d71b89f5`, `a443f52d`); left: std-wide wasm build (`unicode`, `json` bindings), a four-target cell per family, `wat/AGENTS.md` limits row · 97 s12 box 1
- [ ] 05-wasm s8 — overflow for `u32`/`u64` and the narrow integer types on wasm (264): `run/int_overflow_sub_u32`, `run/int_overflow_add_i8` red on wasm (261's opcodes) · ctr-i
- [ ] 02-erlang s4 — `run/array_unique` (C-35) · with 05 s1
- [ ] 02-erlang s5 box 2 — a decorator body carrying `\u{…}` (cell: 14 s7) · none
- [ ] 02-erlang s7 — C-07's erlang tails as `run/` cells · 05's wasm column
- [ ] 02-erlang s10 — the block-as-value lowering (R7) · 01's `@block` tail refusal
- [x] 02-erlang s12 · 03-beam s7 — one `math` on every OS (263): on feat (`a443f52d`)
- [x] 02-erlang s13 · 03-beam s8 — an integer that leaves its type aborts (264): on feat (`48a096ea`) · ctr-j still open
- [ ] 03-beam s1 box 3 — the checker's two binding shapes on beam · 01 s13
- [ ] 03-beam s2 box 1 — C-07's `run/` cells on beam · 02 s7 · 05
- [ ] 12 s1 box 2 — `--cold` with the pre-existing tool set · 114 s7
- [ ] 12 s2 box 1 — `run/array_unique`, `run/throw_in_case_arm_result` · 02 s4 + 05 · 01 s6 + 04 s6
- [ ] 14 s2 — the N=200 slope · 18's runtime-evaluation stage · 01's memo key
- [ ] 14 s6 — the decision-gated rows · lg2-j, lg2-o, lg2-w
- [ ] 14 s7 — a `comptime/tests` fixture for a `\u{…}` decorator body · none
- [ ] 17 s1 box 4 — the per-row increment of a keyed `Dict` · 17-b
- [ ] 17 s2 — the `@BeamMemory` text and the migration handed over · 07 s6 · the rakun track
- [ ] 26 s2 box 3 — rakun's `orm_host.bp` workaround deletable (rakun's row) · none
- [ ] 26 s3 — only a direct dependency is importable (T4, 242) · none
- [ ] 26 s4 — `Env.warnings` reach `build` and `test` · a `codegen.zig` carve-out (`ModuleOutput`)
- [ ] 26 s6 — lg2-v's resolver half · lg2-v
- [ ] 26 s7 — `build.zig`'s `test-docs` comment (handed by 114) · none
- [ ] 26 s8 — 206's residuals: the LSP's import check, a package importing itself · none
- [ ] 130 s5 — the remaining decorator sites (34 of 119 done, plus `#[schema]`'s 5) · rakun's DI on 01 s20 · rakun sites under the 130↔128 rule · rakun-client's on the behavior-member gap · ctr-q
- [ ] 130 s6 — module-level `@emit` removed · 130 s5 · 216 against `#[schema]`'s free functions (no id)
- [ ] 134 s2 — the type functions, the `result` namespace, the `@Result` / `?T` methods, `@is` · 134-d
- [ ] 134 s4–s6 — variadic parameter and the print builtins (267); the `Decorator` type for `with:` (268); `use @getContext(T)` (269)
- [ ] 07-residuals s3, s5–s8, s12, s13 — `uncertain` rows, test comments, the `@BeamMemory` text, C-18's corrections + `docs.md:5` + § Imports, the lib-agnostic gate names every library, the per-cell compile row, the `async` delay flake · none (s8's comments after 02)
- [ ] 07-residuals s1, s2, s4 — the codegen and comptime report waves, three renames · 02–05 landed · 01 landed
- [ ] 07-residuals s9 · s10 · s11 — `->` arms · erika's C-13 migration · the pointers' sweep (last) · C-14 · 16 s1–2 · every library merged
- [ ] 97 s1 residue — `bindInt`'s `i32` through std · std has no `i64` → `i32` narrowing
- [ ] 97 s2 residue — no `Json` accessor copy left in `libs/` · 125 s2 residue (`schemas.bp`)
- [ ] 97 s3 · s5 residue — rakun's `parseDuration`, `skewOf` and four retry loops as "consume std" rows · no 04-rakun front carries them yet
- [ ] 97 s4 residue — the engine under every `-test` member, `test-libs` counts · none
- [ ] 97 s11 — std on wasm, group 3 (230) · none — sequenced with 05 s5
- [ ] 97 s12 — boxes 2–4 done (`powBody`, `fn:` transcendentals, code-point `contentHash`); left: `unicode.fromCodepoint` as a `fn:` over `String.fromCodepoint`
- [ ] 104 s5 — the consumer sweep · 04, 65, 79, 12, 19, 22, `08-bpp/123`, 49, 51 landed (188)
- [ ] 106 s2 — consumers: 17's and 26 s4's boxes; rakun-web's `problem_digest` commit · 65 landed · ctr-k
- [ ] 125 s0 residue — the `f32` and `url.parse` platform facts as tests · none
- [ ] 125 s2 residue — the examples as suite cases, the 2 000-deep test, the refusal test, `schemas.bp`'s accessors · none

## L2 — the libraries' critical path

- [ ] 102 s1–2 — `conventions.bp` and the segment helpers, done on unpushed `front/102-routing-conventions` · push, gate, land
- [ ] 103 s1 — `id.bp` (`deriveActionId`, `isActionId`), done on unpushed `front/103-actions-id` · push, gate, land
- [ ] 102 s3 (W2) — consumers, one commit per member, rakun's first (`rakun-app`, `rakun-hateoas`), then jhonstart `routes.bp`, onze `types.bp`, `scan.bp`, `chunk.bp` · 102 s1–2 landed · 49-d confirmed as amended
- [ ] 103 s2 (W2) — consumers: rakun-app `actions.bp`, jhonstart-forms `form.bp` · 103 s1 landed · the `deriveActionId` / rakun-app `actionId` wrapper choice to confirm
- [ ] 128 (W3) — the nine merges, alone in rakun · the rakun commits of 102 s3 and 103 s2 · ctr-k
- [ ] 130 ↔ 128 — 128 does not wait on 130; no 130 rakun commit while 128 is open; after it, each is a decision-188 consumer commit · **to confirm** (no id)
- [ ] rakun group A (W4–W5) — 04 (s1, the tag epoch, first) · 74 · 08 (s1 after 04 s4) · 15 · 79 · 81 · 93 · 73 · 19 s1 · 128 landed
- [ ] rakun group B (W5–W7) — 13 (04 s1) · 12 (04 s1, 19 s1) · 22 (04 s5) · 17 (13 s2) · 11 (22) · 65 · 09 (19 s1, 13) · 91 (15) · 92 (74, 15) · the A step each names
- [ ] rakun group C (W8) — 88 (81, 93, 92, 04 s4, 73) · 19 s2–5 (15 s1, 04 s4) · group B
- [ ] rakun-websocket `test/limits_test.bp:48` — a load-dependent cap the gate can meet · `00-gate/114` step 9

## L3 — ready to open now

- [ ] 118 — the template language, tag annotations (278), `prelude.bp`, the node type · none (props-d/e/f hold their boxes; ctr-r)
- [ ] 121 s1–2 — Markdown to `Element` in the new member `onze-content` · none
- [ ] 34 s1–3 — `hashHex` → std and the cross-library comments; the five families; the breakpoint refusal · s2: 05emilia-l confirmed · opens before 118's carve-out (ctr-r / 189)
- [ ] 33 s2 — `emilia-card` emilia-only, the fifteen example READMEs (s1, s3, s4 are 135's) · none (ctr-r / 189)
- [ ] 49 s1 · s6 — consume std's `Json` accessors in `config.bp`; the `onze-test` group stubs · none — not beside 102 s3's onze commits (188)
- [ ] 50 s1 — consume std in `onze-cli` / `onze-bundler` · none — not beside 102 s3's `scan.bp` / `chunk.bp` commits (188)
- [ ] 51 s1 — consume std (`fn intOf` in `svg.bp`, `metrics.bp`) · none
- [ ] 27 s1 box 1 · s2 · s3 — the reconcile driver, `use linkStatus()` under a `@Component`, the example · 27-a to confirm
- [ ] 125 s3 → s10 — in order, alone in `libs/validation` · 07-j (size) · 125's `@emit` shape against 216 (no id)

## L4 — later, in waves

Wave numbers are [`fronts.md`](./fronts.md) § Waves.

- [ ] 136 (`09-cardume`) — cardume: the core, `rakun-cardume`, `jhonstart-cardume` · `botopink/cardume` to be created and pushed · 26 · 120 · 125 · atm-a · atm-c · s8: atm-d
- [ ] 26 (W3) — the core: s0 merges `jhonstart-html`, s1–6 · 118 landed · 102 s3 `routes.bp` · s5: 29-a · s8: 01's hooks capability, ctr-l (s7 is 135's)
- [ ] 27 s1 box 2 (W7) — the route-kind flag read · 22
- [ ] 67 (W4) — the DOM-side forms boxes, the wire names handed in · 26 · 103 s2 · 67-a (s4 needs only 103 s2)
- [ ] 49 s2–5 (W3 → W7) — query, headers, dispatcher; the digest's sink; the public root; the dynamic mark · 102 s3 · s3: 26 s4 + 17 · s4: 65 s1 · s5: 22 s4 · 49-e
- [ ] 50 s2–7, s9 (W3 → W8) — `dev`, `prerender/`, the signal, `bin/onze`, the bundler tail, the defaults table; the `@/` alias gone (218) · 102 s3 · s2: 50-b · s4, s7: std-d · s5: 71 s2 · s6: 27 s1
- [ ] 51 s2–6 (W7) — single flight and the route, the prop table, the metrics generator, the OG defaults · 22 · s4: 52-a
- [ ] 71 s1–2 (W3) · s3–4 (W7) · s5 (W10) — ERTS copy and `bin/onze`; shutdown over real cells and static export; the four gate boxes over the blog · 49 s6 · s3: 11, 04, 81 · s4: 22 · s5: 50, 53
- [ ] 53 (W8) — the blog's `alias` gone, the acceptance script's second half, the browser · 49 · 50 · 51 · 71 s1–4 · 26 · 27 · 67 · 22 · 12 · 65 · 135 s5 (the runner) · s6: 50-b
- [ ] 119 (W3) — scoped `<style>` · 08-d · s2: 118, 26
- [ ] 117 (W7) — `.bpp` / `.md` app files, `staticPaths`, `paginate`, partials · 102 · 22 · 49 · 50 · 121 s1–2 · s1: 293
- [ ] 123 (W7) — `locals`, `sequence`, `actionContext` · 04 · 65 · s1 box 3: 08-j
- [ ] 120 (W8) — hydration strategies as `#[client…]` / `#[serverDefer]` annotations (278), server islands · 118 · s1: 26 s8 (`clientOnly`) · 119 · 117 · 26 · 22 · 49 · 50
- [ ] 121 s3–6 (W9) · s7 (W10) — frontmatter, collections, references and RSS, `.md` pages; the blog reads Markdown · s3: 08-f · s6: 118, 117 · s7: 53
- [ ] 122 (W9) — page-side status and headers, `rewrite`, `site` · 26 · 49 · 102 · 118 · 120
- [ ] 126 (W9) — view transitions, `#[transition…]` annotations (278) · 27 · 118 · 120
- [ ] 127 (W10) — actions typed by a schema · 125 s6 · 103 · 22 · 67 · 49 · 117 · 120 · 126 · s4: 123
- [ ] 116 (W5 at the earliest) — the `.bpp` file kind · 118 · 26 s0 · 01-compiler/26 · with 01-checker s22 · s2: 01-checker s25 (289) · s6: 293
- [ ] 105 (W9) — bundled `i18n` · 104 s5 · 22 · 26 · 03r-q confirmed
- [ ] 107 (W9) — bundled `release` · 07-g · 71 · 81
- [ ] 124 s1–4 (W10) · s5 (W11) — the commands, the config keys, the `.bpp` scaffold · 08-h · every other 08 front · s5: 116, 53
- [ ] 98 (W11) — packaging checked everywhere · every library track's `-test` and README steps · s3: 95-f · s4: lg2-v
- [ ] 16 s1–7 — the `;` re-count, migration and refusal, C-12's reformat, 165, 166/243, C-11 · s2: each library track runs the script · s4: 16-a/b · s6: ctr-s · s3 last, after every tree is migrated
- [ ] 18 — the CI matrix, the four limits, the bench table, the transport test, `memory.grow` (261) · s1: the maintainer's push
- [ ] 23 — the import cells and LSP snapshots, the confirmations · 23-a/b/c, std-c
- [ ] 24 — the guide as one program, the confirmations, the per-item cost · 24-a/b/c/g · rakun's `serverAction`
- [ ] 135 s5 (W7) — onze: the E2E runner (five harness functions), the release tree as a path table, 107's README names the two snapshots · snap-a · before 53 s2–6
- [ ] 135 s1–4 (W11, last) — std's `mocks.verify` message; rakun-test's `assertResponse`; jhonstart's `AGENTS.md` paragraph; emilia-test's `assertClassName` / `assertCss` (they replace 97 s7, 19 s6, 26 s7, 33 s1/3/4, 50 s8, 51 s7) · snap-a · s4: 34 landed

## L5 — blocked on a decision

Full text in [`decisions-pending.md`](./decisions-pending.md); confirmations (1.0.10 choices) in its
last section.

**First — the botopink shape** (raised 2026-10-04; answer `nat-0`, then the rest):
- [ ] nat-d3…d9 — case by case (283; nat-d1 → 303, nat-d2 → 304): `Schema<T>` (125), arity families (125), `Partial`/`Pick` (125, 134), `nav:` strings (26, 53), lifecycle (rakun 04), `use use…` (53), erika's LINQ names (98)
- [ ] nat-e — Spring's annotations · 130 s5, rakun 04/08/13/15/19/79/91/93, 130-b, 130-c
- [ ] nat-f2…f4 — case by case (284): `onze.json` keys (124, 08-h), `files`/`workspaces` (98), `ONZE_PUBLIC_` (50, 53)
- [ ] nat-g — foreign syntax in annotations · 17

Then:
- [ ] 17-b — 17 s1 box 4
- [ ] 134-d — 134 s2 (`@is`)
- [ ] std-d — 97 s6 · 50 s4, s7
- [ ] 95-f — 98 s3
- [ ] 07-g — 107 whole
- [ ] 07-j — 125 s3–10 (size)
- [ ] 03r-ab — 09 s5 (and the scope of s1–4)
- [ ] 03r-ae — 79 s3
- [ ] 03r-af — 73 s3
- [ ] 03r-ak — 81 s3
- [ ] 03r-al — 15 s5
- [ ] 03r-am — 19 s3–4
- [ ] 03r-an — 92 s2 (boxes 1, 3)
- [ ] 67-a — 67 s1–3 · 53's write path
- [ ] 05emilia-n — 34 s4
- [ ] 50-b — 50 s2 · 53 s6
- [ ] 08-d — 119 every step
- [ ] 08-f — 121 s3
- [ ] 08-h — 124 whole
- [ ] 08-j — 123 s1 box 3
- [ ] props-d · props-e · props-f — 118 s1, s4 (native attributes, named slots, spread)
- [ ] snap-a — 135 s1–5 (replaces 01std-f, 03r-ag, 30-h, 05emilia-m, 53-b) · 53 s2–6 through 135 s5
- [ ] lg2-a … lg2-w — none opens a front; each opens a step when answered: 01-checker (a, e, f, m, q, r, t), 14 s6 (j, o, w), 26 s6 / 98 s4 / 73 (v); the rakun boxes that name them — 04 (e, g, j), 08 (e, f), 13 · 65 · 09 · 91 · 92 (a, b), 15 (w), 22 (q), 88 (j), 93 (o)
- [ ] C-14 — 07-residuals s9 (a 1.0.10 id)
- [ ] confirmations a step waits on — 49-d (102 s3) · 49-e (49 s2) · 05emilia-l (34 s2) · 52-a (51 s4) · 29-a (26 s5) · 27-a (27) · 03r-q (105) · 16-a/b (16 s4) · 23-a/b/c, std-c (23) · 24-a/b/c/g (24; 24-g also 97 s5's surface)
- [ ] ctr-k — 17 · 128 · 106 s2
- [ ] ctr-i — 05's string lowering · 02's codepoint cell · ctr-j — 04 s8 · 02 s13 · 03 s8 · 01 s18
- [ ] ctr-l — 26 s8's refusal list · ctr-q — 130 s5 · ctr-r — 118's carve-outs, 34 / 33 opening first · ctr-s — 16 s6
- [ ] ctr-m — lg2-s · ctr-n — imp-a · ctr-o — lem-c · ctr-p — 04's readers · 104 s5 (ctr-h blocks nothing)
- [ ] no id yet — the 130 ↔ 128 rule (128, 130 s5) · 216 against `#[schema]`'s free `@emit` functions (125, 130 s6) · 213 against 221 for `not-found.bpp` (116 s2, 124's scaffold)
