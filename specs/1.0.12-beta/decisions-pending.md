# Decisions the maintainer owes — 1.0.12-beta

**55 questions and 8 contradictions are open, and 88 implementation choices await confirmation.**

- An answer goes into [`decisions-taken.md`](./decisions-taken.md) under the next free number (kept
  there only); a lettered id is never renumbered or reused.
- Every recommendation is the most restrictive reading, no configuration bypassing it (decision 67).
- A front meeting a question it cannot answer from the code adds it here: id · title · Measured
  (observed, re-runnable) · Options · Recommendation · Blocks. *Proposed* = raised without an id.

- **Part 1** — what blocks `00-gate`, `01-compiler`, `02-std-and-packaging` and `03-bundled-libs`, by track, then
  those tracks' implementation choices awaiting confirmation.
- **Part 2** — the rest (tracks 04–09, 20, ownership, contradictions that block no 00–03 step).
- **Part 3** — the implementation choices of tracks 04–09.

The Portuguese record (`decisoes-pendentes.md`) follows the same order, with examples for Part 1 and one line per item for
Parts 2 and 3. Answered ids leave this file; `decisions-taken.md` holds the answers and the next free number.

---

## Part 1 — What blocks tracks 00–03

### What blocks now (answer first)

Nothing open: 138-a answered (337).

### 01-compiler

`00-gate` has no open question: 114's steps wait on no decision.

#### 03r-ao · `01-compiler/130`'s rakun sites against 128 (*proposed*, raised by the 04-rakun consolidation)
- **Measured.** 130 step 5 (decision 216) edits files 128 moves or the rakun fronts own (core's `decorators.bp`, `autoconfig.bp`, `config.bp`, `context.bp`, `lifecycle.bp`, `conditions.bp`; `rakun-web/src/convention.bp`; `rakun-app`; `rakun-scheduling`; `rakun-messaging`; `rakun-cli`; `rakun-data`; `rakun-security`; `rakun-websocket`; `rakun-client`; `actuator_api`). The fronts already follow (a) as a provisional rule: 130 step 5 targets post-128 paths (`modules/rakun/src/actuator_api/**`, today `rakun-actuator-api`) and makes no rakun commit while 128 is open; [`04-rakun/README.md`](./04-rakun/README.md) § Order and § Rules make 130 the frozen `decorators.bp`'s one writer ("to confirm"). Landed sites (`#[entity]`, `#[entityRepository]`, `#[belongsTo]`, `#[query]`, `#[cached]`, `#[halResource]`, `front/130-rakun-di`'s `T.make()`) are on `feat` and move with their files. Only the record is missing.
- **Options.** (a) 128 first and alone; 130's rakun sites re-pointed at post-128 paths; after 128 each is a consumer commit under 188 (never in a wave with the owning front); the frozen-files rule excepts 130's rewrite of `src/decorators.bp`. (b) 130's rakun sites before 128 opens. (c) 128 performs 130's rewrite of the files it moves.
- **Recommendation.** (a): 128 holds all of rakun, and (b) holds every rakun front on 130.
- **Blocks.** Only the record — 130 and 04-rakun already follow (a); 128's opening and 130 step 5's rakun rows proceed under the provisional rule until confirmed.

#### 17-b · The per-row increment of a `keyed: true` `Dict`
- **Measured.** A row is written `counts = counts.insert(k, v)`; `counts.insert(k, (counts.at(k) ?? 0) + 1)` now types but stays refused — a row computed from the var's own rows is 1.0.5's 40 (rule 5(b)) refusal; `counts.at(k)` is a `?V`; `counts.at(k) += 1` / `counts[k] += 1` are not assignment targets. `label: value` per 305.
- **Options.** (a) None: a keyed row written whole; a per-key counter refused; a counter several processes bump is one `#[@BeamMemory.Ets] var n: i32` each. (b) A std `Dict.bump(key, by) -> Dict<K, V>` (integer `V`, absent key counts from 0), lowered under `keyed: true` to `ets:update_counter(T, K, By, {K, 0})`. (c) An index assignment `counts[k] += 1` in the grammar. (d) Recognise exactly `counts.insert(k, (counts.at(k) ?? 0) + n)` and lower it to `ets:update_counter(T, k, n, {k, 0})`; any other shape stays refused.
- **Recommendation.** (a): no method or grammar for an annotation; (d) makes a written form change meaning by pattern.
- **Blocks.** `17-beam-memory` step 1, fourth box.

#### lg2-w · A host function called from a decorator body
- **Measured.** `json.quote(…)` in a decorator (`comptime path: string`, writing typed meta — module-level `@emit` leaves, 216) refused as a method nothing provides; via `import {json.quote}` it is `call to undefined function quote/1` on both comptime runtimes; a project's own host `declare fn` fails the same — only bodied functions travel into the decorator module.
- **Options.** (1) A comptime body calls bodied functions only; a host call there refused at the call, located, naming the function, on every target. (2) The Erlang cell travels into the decorator module on the BEAM runtime, refused on wat. (3) Decorators reaching a host cell run on the BEAM runtime whatever the target.
- **Recommendation.** (1): the answer never depends on the runtime the target selected (1.0.10's 84).
- **Blocks.** The row; front 16 (`#[scheduled]`); every decorator that would reuse std.

#### lg2-o · Filesystem access from a comptime body
- **Measured.** `fs.readText(path)` in a decorator body (`comptime path: string`, 280 (0)) refused at the annotation.
- **Options.** (1) None: generated `.bp` is checked in (`rakun ws generate`). (2) A sandboxed read of declared build inputs, keyed into the build cache.
- **Recommendation.** (1): a build reads only its sources.
- **Blocks.** The row; rakun 88, 93.

#### lg2-j · Comptime state across decorator invocations
- **Measured.** A module-level `var` written by a decorator body is refused at the annotation; each invocation is its own module call.
- **Options.** (1) Each invocation independent; a catalogue is read with `@TypeInfo.all(with: …)` at the entry point (256, without `member: "make"` or a type-name key, both removed by 281; the type key is `321's). (2) Comptime mutable state scoped to one compilation.
- **Recommendation.** (1): a decorator's answer depends on its declaration alone.
- **Blocks.** The row; rakun 05.

#### lg2-v · A subdirectory in a git dependency
- **Measured.** `DepSpec` is `{git, path, ref, workspace}` (`modules/manifest/src/root.zig`); a package inside a repository is reachable by `path` only.
- **Options.** (1) None: a git dependency is a repository root; a monorepo member installs by `path`. (2) A `subdir` field on a git `DepSpec`, resolved by `bpmp`.
- **Recommendation.** (1). Cost: no `rakun-*` starter installs from git outside the meta checkout. Under (2) a `subdir` without `git`, or escaping the checkout (`..`), is refused.
- **Blocks.** The row; rakun 73; `02/98` step 4 (conditional); `07-h`'s argument.

#### ctr-s · Decision 166 against decision 243
- **Rules.** 166: "a list written without [a trailing comma] stays on one line". 243: "without it, the width rules (`16-a` / `16-b`) decide", while saying it "extends" 166.
- **Recommendation.** Record 243 as amending 166's no-comma half; the confirmation of `16-a` / `16-b` then covers it.
- **Blocks.** 16-formatter step 6.

#### lg2-a · A byte type
- **Measured.** No primitive, std type or literal holds bytes (`val b: Bytes = "a";` mismatches everywhere); every host cell marshals via `string`.
- **Options.** (1) None: a binary payload refused where it enters. (2) A `Bytes` primitive with an explicit, fallible boundary (`Bytes.fromUtf8`, `toUtf8 -> @Result`), no implicit conversion. (3) `string` also carries raw bytes.
- **Recommendation.** (1). Cost: every upload, download, image endpoint; under (2) no conversion without a fallible call; (3) stays refused (how `Socket.recv` mangles UTF-8 today).
- **Blocks.** The row; rakun 01, 13, 15, 24, 25, 70, 71; `03r-ab`.

#### lg2-e · A method-level `@Decl`'s owner
- **Measured.** 280 answered the parameters: `@Decl<T>` binds the function's type (`@Decl<fn(e: E) -> unknown>`), and 280's approved example 1 (`01-checker` step 24) reads `decl.params`, `decl.params[0].module`, `decl.module` on a fn's `@Decl`. Left: `decl.owner` on a method-level decorator is the checker's unknown field of `Decl`, at the read (was `badkey`); only the type-level handle sees the whole type.
- **Options.** (1) A method-level marker sees its own method (parameters per 280); the type-level decorator reads the type. (2) `owner` on a method-level `@Decl`.
- **Recommendation.** (1).
- **Blocks.** The row (marker in `08-bpp/127`'s `typed-action-example.bp`, its parameter half closing with `01-checker` step 24); rakun 06–10, 29.

#### lg2-q · `@Decl`'s source location
- **Measured.** `decl.loc.file` is the checker's unknown field of `Decl`, at the read (was `badkey` at the annotation). 289 and 290 already write option (1): a route file's decorator carries the route (`#[page("blog/[slug]", paths: allPosts)]`), the page reads its segments by hook (293), takes no parameter and returns `View` (275, 276). An anonymous default's `decl.name` is the file name (289), not its path.
- **Options.** (1) None: the app-relative segment is an explicit decorator argument (`#[page("blog/[slug]")] pub fn BlogPost() -> View`). (2) A `loc` field on `@Decl` (`@src()`'s `SourceLocation`).
- **Recommendation.** (1): a decorator's output never depends on where its file sits; 289/290 are written so.
- **Blocks.** The row; rakun 22 (the `#[page("…")]` examples already follow (1)).

#### ctr-o · Decision 146 against confirmation `lem-c`
- **Rules.** 146: a function whose body reaches a host function with no binding for the target "is refused at its declaration, called or not". `lem-c` (built, to confirm): a host method with no binding "is refused where it is CALLED" — refusing the declaration was the option not taken; 311 keeps the same at the call.
- **Recommendation.** Confirm `lem-c` for a bodyless host declaration (a type declared once still compiles for a target its method lacks); state that 146 governs any bodied function, free or method, reaching one; `docs.md` says both.
- **Blocks.** `lem-c`'s confirmation.

#### ctr-h · Decision 149 against decisions 210 and 211
- **Rules.** 149: "`==` is reference equality on an array and is refused on a record … a record that wants equality implements `behavior Eq`". 210: "structural equality on every target"; 211: "a type cannot define its own equality". 210 does not cite 149.
- **Recommendation.** Record 149 as superseded by 210, its `behavior Eq` clause by 211; code on `feat` follows 210 / 214 (`run/record_structural_equality`).
- **Blocks.** Nothing; the record.

#### 17-c · What else names a `keyed: true` var
- **Measured.** Built: only `counts.at(k)` (`ets:lookup`) and `counts = counts.insert(k, v)` (`ets:insert`); everything else (`counts[k]`, `hasKey`, `delete`, `size()`, passing it on) refused at the identifier; a keyed var is never `pub`. 1.0.5's 63: an index answers `V` and fails on an absent key; `at` answers `?V` (`null`).
- **Options.** (a) The two forms, as built. (b) (a) plus `counts[k]` with 63's meaning (`ets:lookup`, `V`, failure on a missing row). (c) (b) plus `hasKey` (`ets:member`) and `delete` (`ets:delete`), each a new `std/beam` primitive.
- **Recommendation.** (a).
- **Blocks.** Nothing — the built surface stands until widened.

### 02-std-and-packaging

#### 110-a · `testing.asserts` on wasm under the strict rule (146)
- **Measured.** A wasm program importing `testing.asserts` is refused: 4 of its 27 functions reach host cells with no wasm binding (`deepEquals → canonical`, `matches → regexMatches`, `throws`/`throwsWith → tryCatch`); uses: throwsWith ~290, throws 4, deepEquals 2, matches 1; 140 files import the module.
- **Rules.** 230: front 110 closes on "a std module wasm cannot build is a located refusal"; `02/97` step 11 offers (a) out of a wasm build or (b) restructured, a question per module. 146's last clause ("`testing.asserts` is restructured so nothing without a wasm binding is reachable from it on wasm") asks for (2)/(3); answering (1) amends it.
- **Options.** (1) ★ As is: not importable on wasm. (2) The four move to their own module; the other 23 import on wasm (changes decision 74's API). (3) The three cells gain wasm versions (a regex engine in the wasm prelude; a catchable `@panic`).
- **Recommendation.** (1) now; (2) if wasm must run asserts.
- **Blocks.** Nothing in the gate; "std compiles on wasm" (05-wasm step 5, 97 step 11).

#### std-d · `io.process` signals and a TTY reader
- **Measured.** `io/process.bp` neither registers nor forwards a signal; std has no TTY line reader; `onze start` waits on `process.run` → `SIGTERM` leaves the node running; `onze create` without `--yes` has no prompt to fall back to.
- **Options.** (a) `process.onSignal(name, fn)`, `process.forwardSignals(child)`, `io.stdin.readLine()` — three host cells on two targets. (b) No std change: `onze start` execs the node (71's `bin/onze` is PID 1); `onze create` without `--yes` refused naming the flags it needs.
- **Recommendation.** (b).
- **Blocks.** onze 50 steps 4 and 7; 97 step 6 (conditional).

#### 08-f · Where Markdown and YAML live
- **Measured.** No Markdown code anywhere; one YAML-subset reader, in rakun's `config.bp`; `03-bundled-libs` sends config readers to std "when a second consumer appears".
- **Options.** (a) Both in a new member `onze-content`. (b) Markdown in `onze-content`; YAML in std as `yaml`, rakun's reader deleted by rakun's front. (c) A bundled `markdown` package.
- **Recommendation.** (b): frontmatter is YAML's second consumer; Markdown has one (115). Until std's `yaml` lands, 121 step 3 reads frontmatter with its own copy and deletes it then.
- **Blocks.** 121 step 3; a row for `02/97`.

#### 95-f · The onze takeover — amend decision 79
- **Measured.** `repository/onze` is the orchestrator's workspace, built on tag `mocking-lib-final` in the same history and remote — not decision 79's orphan branch; nothing archived or renamed; the name resolves only to the orchestrator's members.
- **Options.** (1) Confirm the tree: a new decision amends 79 — the old library lives as the tagged history of the same repository. (2) Rewrite the remote to an orphan branch, archive the old history (every checkout re-clones).
- **Recommendation.** (1).
- **Blocks.** `02/98` step 3 ("front 95 closed as a confirmation"), written under (1).

#### nat-f3 · `files` and `workspaces` in `botopink.json` (98)
- **Measured.** `files` lists, relative to `src`, the modules a consumer may import; a library without it ships nothing (`docs/botopink-json.md:52`). `workspaces` lists members; a manifest with it is a workspace and refuses `src`, `files`, `entry`, `dependencies` (`:159-170`) — the two never share a file (`98-packaging-tail/README.md:27`). 270 relies on `files` (the prelude `src/prelude.bp` is listed there).
- **Options.** (a) Both kept — packaging, not code. (b) `files` derived from `pub` modules (an internal module marked in code — `#![internal]` has no spelling since 315), 270 reworded; `workspaces` kept. (c) Both derived.
- **Recommendation.** (a): what ships is a packaging fact, and 270 already relies on it.
- **Blocks.** 98.

#### nat-d9 · LINQ's names in erika beside std's (98)
- **Measured.** `98-packaging-tail/README.md:47-51`; `erika.bp`: `where`, `select`, `selectMany`, `orderByDescending`, `toList`; erika is eager — every operator materializes a new array (`erika.bp:5`); std has `filter`, `map`, `flatMap`, `unique` (217).
- **Options.** (a) std's names (`filter`, `map`), erika adding only what std lacks (`groupBy`, the aggregates). (b) LINQ's names — erika's identity is LINQ. (c) As is.
- **Recommendation.** none from this review: erika's purpose decides (b) is a fair reading.
- **Blocks.** 98 (erika).

### 03-bundled-libs

#### snap-a · The snapshot maps — retired; the snapshots that exist or that a contract reads stay (replaces `01std-f`, `03r-ag`, `30-h`, `05emilia-m`, `53-b`)
- **Measured.** The nine maps carried from 1.0.10 (history under `../1.0.11-beta/`; re-evaluated case by case in [`20-snap/README.md`](./20-snap/README.md)) hold 473 cases plus helper tables: 27 obsolete (renamed, deleted or changed by decisions 186, 194, 200, 218, 34 step 2, 50-a, or deferred by `03r-ad`); 418 verified today by a named inline test or an existing `.snap` (e.g. `emilia.bp:10615` `tokenDeclarations(.Border.Rounded.Md) == "border-radius:var(--radius-md)"`); 21, in five groups, verified nowhere and worth a plain test. onze holds 51 `.snap`, 24 of them realising §§ 50 · 51 · 52 · 70 · 71 via `snapshots.assertAs`; jhonstart holds 39, std 4. The maps' recorded literals predate the code (slug separator, `_links` order, `normalize`, emilia classes) — not expected values. Contract 7, `snapshots.md` rule 3 and 98 check (2) require at least one `assert<Subject>(loc, …)` in every `<lib>-test`.
- **Options.** (a) As proposed: (1) maps are closed records — no front records a `.snap` because a map names it; (2) existing `.snap` files stay (std 4, jhonstart 39, onze 51), change only with their test; (3) a new snapshot only where its exact bytes are a contract another package reads — this milestone, onze-release's `text_…` and `dockerfile_…` (on disk) for `107-release`; (4) helpers, no more than a consumer uses: `emilia-test`'s `assertClassName` (`cardTokens()` under `defaultTheme()`, recording `e_39b87d03`) and `assertCss(loc, tokens, th)`, `rakun-test`'s `assertResponse(loc, res)` over `MockMvc.perform`, jhonstart's and onze's existing helpers (onze's `assertAlias` goes with 218), no other map helper; (5) the 21 unverified values become plain tests — std's `mocks.verify` message with `throwsWith` on both targets (`"mocks.verify: find - expected exactly 1 matching call(s), got 2"`), onze-release's tree as a path table, `emilia-card`'s repeat collapse, onze 53's blog E2E boxes as asserts over `request(…)` and the dev/start gate as an equality property (runner = five harness functions, no snapshot writers); (6) 97 step 7, 26 step 7, 33 steps 3–4, 50 step 8 and 51 step 7 close with an `AGENTS.md` line ("the inline literals and the existing `__snapshots__/` are the evidence"). (b) Build the whole layer: every map's helpers and `.snap` (~2 500 files), recorded literals re-derived first. (c) Keep the maps open per library: each answers its own former question and keeps its map until then.
- **Recommendation.** (a): one rule for every library, every value verified once, only three new `.snap` (emilia-test 2, rakun-test 1).
- **Blocks.** Front 135 ([`20-snap`](./20-snap/README.md)) steps 1–5, which own 97 step 7 · 19 step 6 · 26 step 7 · 33 steps 1, 3, 4 · 50 step 8 · 51 step 7 · 53 step 1's runner and steps 2–6's wording · 71 step 6; 98 check (2) stands unchanged.

#### atm-a · Cookie hook names: nouns, or 294/295's verbs (*proposed*)
- **Measured.** jhonstart's rule (`hooks.bp` header): a hook is a noun, `use` the activation. Request locals are settled by 296 (cardume atoms; "each bridge spells the same hooks (`atomValue`, `atomState`, `atomSetter`, `atomReset` …)" — `use setLocal` becomes `use atomSetter`). Left: `Cookie<T>` stays in `http` (294, 296), written `use setCookie(decl)` / `use clearCookie(decl)` — verbs.
- **Options.** (a) Nouns: `use cookieSetter(c)`, `use cookieClearer(c)`. (b) Keep 294/295's verbs for cookies. (c) Each library its own.
- **Recommendation.** (a) — one rule, jhonstart's and cardume's.
- **Blocks.** 123; 127; 104 step 6; `07-onze/53` (the cookie sites).

#### ctr-p · Confirmation `std-a` against confirmation `03r-e`
- **Rules.** `std-a`: `querystring.parse` / `parseForm` "refuse … an escape that decodes to a control character", and rakun's `splitQuery` moves onto them. `03r-e`: a cookie or query component that would decode to a control character "stays exactly as written". 196 moves rakun's cookie readers into `http`.
- **Recommendation.** Confirm `std-a`; `03r-e` lapses when rakun reads queries via `querystring` and cookies via `http`.
- **Blocks.** rakun 04's readers; 104's consumer sweep.

#### ctr-k · Decision 187 against decision 195
- **Rules.** 187: "the core absorbs `rakun-actuator-api` and `rakun-logging` … the core calls its own logger and no failure-report plugin exists". 195 (later): "rakun-logging keeps its erlang cells and installs itself as the sink".
- **Recommendation.** Read 195 as "rakun's core logging (after 128) installs its erlang logger as `log`'s sink at boot", and record it. The fronts already follow it (`04-rakun/17` R17-1 and step 2; `03-bundled-libs/106-log`); only 195's row is pending.
- **Blocks.** Nothing in the fronts; the record.

#### 07-g · OTP release rendering
- **Measured.** `rakun-release/release.bp` (into `rakun-cli` under 187) and `onze-release/otp.bp` render the same `.rel` / `vm.args` / `sys.config` / boot script / Dockerfile; onze cannot reuse rakun's (rakun erlang-only, onze-release also commonJS).
- **Options.** (a) A bundled `release` of pure renderers. (b) A `botopink` CLI feature (02). (c) Leave both.
- **Recommendation.** (a); the CLI may adopt the package later.
- **Blocks.** `107-release` (a conditional front: answer it or defer 107).

### Implementation choices of tracks 00–03

Each implemented with its recommended option; the maintainer confirms or reverses (a reversal is a
local change in the named place). Full 1.0.10 text under the same id in
[`../1.0.10-beta/decisions-pending.md`](../1.0.10-beta/decisions-pending.md).

#### 01-compiler (22)

| Id | Choice implemented | Where |
|---|---|---|
| 24-a | Annotation-only effect codes deleted; `effect-throw-without-fallible-channel` merges into `effect-try-without-fallible-channel`; `effect-wrapper-mismatch` only for a component whose `T` implements `@Context<B>` with `B` other than its `C`; `for-over-stream` / `for-await-expects-stream` are the renamed generator codes | `comptime/diagnostics.zig` |
| 24-b | `@Task`'s methods are `map` and `then`; no `flatMap` alias | `builtins.d.bp` |
| 24-c | `iter for` / `iter while` parse as prefixed `loop { for (…) { … }; break; }` (keyword kept in `LoopExpr.prefixedKeyword`); `iter loop :l` labels the generator scope, `iter for :l` the written `for` | parser |
| 23-b | `base64`'s four functions retired, not aliased; `encoding.base64Decode` / `base64UrlDecode` answer `@Result` | `libs/std/src/encoding.bp` |
| 01c-a | A comptime module's atom is `bp@comptime@<owner path>__tpl__<decl>__<hash>` | comptime |
| 01c-b | A section leaf takes the leading-dot shorthand where the position's type is that section; with no expectation refused naming its section | checker |
| ck2-a | `@module()` refused at the call (`builtin-not-lowered`) until a rule says what a module value is | `builtins.d.bp` · `reject/builtin_module_not_lowered` |
| ck2-b | A section member may share a name with a top-level variant of the same enum (path and position type tell them apart); a variant declared twice at one level is `enum-variant-duplicate` | `modules/enum_section_leaf_beside_variant` |
| ck2-d | A label in a call of a function value is `label-on-function-value` | `reject/label_on_function_value` |
| ck2-e | A std decorator is reached via its module handle (`#[<handle>.<fn>]`); a leaf import of one is `std-decorator-leaf-import`; `#[<handle>.<not a decorator>]` is `unknown-annotation`; the handle is still needed after 216 (`mocks.mock`'s `addType` / `addMember` text names `mocks.invoke`, `testing/mocks.bp:212-220`), while 282/289 already leaf-import other libraries' decorators | checker |
| rc3-b | `unknown` is the host vocabulary's spelling where `any` was (tested with `is` before use) | `run/host_unknown_parameter` |
| rc3-c | Assigning a narrowed `var` checks against its declared type and ends the narrowing | `reject/narrow_ends_at_assignment` |
| 16-a | C-12's argument list enabled with the constructs around it — binary run, brace-less `if`, argument list, array / tuple / behavior literals — one all-or-nothing `groupMeasured` each, outer deciding first | formatter; the libraries' reformat (16 step 4) |
| 16-b | An array literal written without a trailing comma, when open, is one element per line (with one, 166/243 keep it open) | formatter |
| 0405-b | commonJS's `__bp_show` prints `undefined` as `null` | commonJS prelude |
| onze F7 | Integer `/` integer truncates toward zero and is an integer on every target (`7.0 / 2.0` stays `3.5`); `docs.md:961-963` already states it | `run/integer_division_truncates` |
| lem-a | A host method is a real method of its type whose body is the binding, never inlined at the call site | `codegen/hostMethods.zig` |
| lem-b | `inline: true` (305's spelling; code still writes `inline = true` until 01-checker step 27) on a type method's `External.Erlang` / `Beam` accepted, changes nothing (refusing it is 01-checker's to add; recommended: refuse) | `run/external_method_local` |
| lem-c | A host method with no binding for the target refused where called (`MissingExternal` naming `Type.method`); wasm refuses every host method; an untyped receiver fails at run time (`ctr-o`) | `hostMethods.missingAt` |
| lem-d | One name per operation on every type (`Listener.port/accept/close`, `Socket.recv/send/close/peer`, `TlsListener.port/accept`, `TlsSocket.recv/send/close`, `Regex.matches`); constructors stay module functions | `io.net` · `regex` |
| lem-e | Private helpers taking a type stay free (`tlsEchoOnce`, `rkvPush`, `putMessageSource`, `messageSourceOr`) | std · `validation` |
| lem-f | commonJS adopts a host-built record into its class (`__bp_adopt`) directly and through `?T`, arrays and a `@Result`'s ok side, not through `@Task` | `run/external_method_on_host_record` |

#### 02-std-and-packaging (10)

| Id | Choice implemented | Where |
|---|---|---|
| 24-g | `std/async`: started `allOf` over `@Task<@Result<T, E>>` (stops at the first `Error` in input order), `all`, `race`; unstarted `runAll`, `raceOf`, `timeout(task, millis) -> @Task<@Result<T, string>>` (`Error("timeout")`); `failed(message)` answers `Error`; `allSettled`, `settleOf`, `unwrapAll`, `attempt` removed | `libs/std/src/async.bp` |
| 01std-a | A bundled library loaded by CLI and LSP (`appendBundled`), not `expandStdImports`; compiler-core names no package but `std` | `build.zig` `bundled_packages` |
| 01std-c | `routing.pattern`'s empty pattern matches only `/`; rakun-web keeps "empty runs everywhere" at its call site (`matcherAdmits`) | `routing` |
| 01std-e | `actions.readEnvelope` refuses a `redirect` disagreeing with `n` | `actions` |
| std-a | `querystring.parse` / `parseForm` answer `@Result`, refuse a malformed escape, non-UTF-8 and a control character raw or decoded; `stringify` refuses a control character; `parse` is RFC 3986 (`+` stays), `parseForm` the form flavour (`ctr-p`) | `libs/std/src/querystring.bp` |
| std-b | `fs.exists` follows a symbolic link (dangling link is `false`) | `io/fs.bp` |
| std-c | Decision 110's folder namespace is a rewrite of the parsed program | `comptime/std_namespace.zig` |
| 95-a | Front 95 relocated `jhonstart-link` and `rakun-app` as moves with no behaviour | jhonstart · rakun |
| 95-b | `rakun-app` declares its own `"targets": ["erlang"]`, as all 36 rakun manifests do (option (b); 1.0.10's "inherits the workspace" is not what the code does) | `rakun-app` manifest |
| 95-c | `erika-test` exists | erika |

#### Choices made by the 00-gate threads and the consolidation (5)

| Id | ★ implemented | Where |
|---|---|---|
| 111-b | the beam sidecar loader is emitted only when the build binds a host function (13 snapshots changed); the erlang backend follows the same rule (`buildBindsErlangHost`) | botopink-lang `codegen/beam_asm.zig` |
| 113-a | a target `botopink test` cannot run (wasm today — it runs commonJS, erlang and beam) is `NOT RUNNABLE` and fails `test-libs`, as `fronts.md` § Gate item 3 requires | `scripts/test-libs.sh` |
| 113-b | the restriction audit matches the refusal by its text (alternative, recommended: give the refusal an id — 07-residuals) | `lib-test-runner` |
| 110-b | the count history left `tests/language/AGENTS.md` | `tests/language/AGENTS.md` |
| 112-a | `format-check`'s `TREES` holds `examples` as one entry plus `modules/manifest/tests` | `scripts/format-check.sh` |

#### Other tracks' choices a 00–03 step waits on

| Id | Choice implemented | Where |
|---|---|---|
| 03r-q | Locale routing lives in `rakun-app/src/i18n.bp`; no `rakun-i18n` member | 22 |

---

## Part 2 — The rest

### Priority — the botopink shape (`nat-*`)

#### nat-d · A second model of what the language has — case by case (decision 283)
No general rule (283): each case below is its own question, (a) the language's own, (b) both — the foreign one a thin layer over the native — or (c) as is.

#### nat-d6 · `throw "nav:not-found"` beside `noreturn` (53)
- **Measured.** A signal is a host-raised `nav:`-prefixed string (`contracts.md` § 5b); jhonstart's `notFound()` / `redirect()` declare `-> string`, rakun's `-> i32` (`jhonstart/src/error_boundary.bp:180-189`, `rakun-app/src/navigation.bp:47-55`); `isSignal` → `isSignalReason` by prefix; `boundaries-example.bp:89-91` (a `throw` inside `-> @Result`, an `Error` value by 118, not a raise); `server-action-example.bp:79` `val _gone = redirect(…)`.
- **Rules.** 303: an action answers `@Result<T, ActionError>` and `throw e` there is `Error(e)`; `ActionError` has `NotFound` but no redirect case — the answer must also say how an action redirects.
- **Options.** (a) `fn notFound() -> noreturn`, boundaries matching the `NavOutcome` type. (b) The string signal kept under a typed wrapper. (c) As is.
- **Recommendation.** (a). With lg2-l and lg2-h.
- **Blocks.** `05-jhonstart/26`, `07-onze/53`; lg2-l, lg2-h, 31-a.

#### nat-d7 · Lifecycle annotations beside interfaces (rakun 04)
- **Measured.** `context-lifecycle-example.bp:66,72`: `#[postConstruct]`, `#[preDestroy]`.
- **Options.** (a) `implement Lifecycle { fn start(self); fn stop(self) }`. (b) Both. (c) As is.
- **Recommendation.** (a).
- **Blocks.** rakun 04.

#### nat-d8 · A `use…` hook name under `use` (53)
- **Measured.** `new-post-form-example.bp:118`: `use useActionState("createPost", actionState(""))` — jhonstart exports no `useActionState`; jhonstart-forms' hook is `actionState(actionId: string, initial)` (`form.bp:182`).
- **Rules.** 281 already settles the argument: the action is passed as a reference (`createPost`), never a string — in the example and in `actionState`'s signature. Only the hook's name is open.
- **Options.** (a) `use actionState(createPost, initial)`; a hook named `use…` refused. (b) Both names. (c) As is.
- **Recommendation.** (a).
- **Blocks.** `07-onze/53`'s examples.

#### nat-f · Configuration in JSON — case by case (decision 284)
`botopink.json` as clean as possible, configuration allowed where it makes sense (284); `"bpp": "<package>"` stays. Each case below is its own question.

#### nat-f2 · `onze.json`'s `trailingSlash`, `redirects`, `markdown`, `allowedRedirects` (124, 08-h)
- **Measured.** `onze.json` is read and validated by `loadConfig` whenever the CLI resolves the project, `onze build` included (`onze-cli/src/resolve.bp:48-50`); an unknown key is refused (49-c) without a line. Only `allowedRedirects` exists (`onze/src/config.bp:192-193`); `trailingSlash`, `redirects`, `markdown` are 124's planned keys (`124-bpp-cli/README.md:67-69`), which 08-h already writes; all four restate options onze's code types (`url_rules`, `MarkdownOptions`, `app(allowedRedirects:)`). Precedent: 299 (typed record bound from a file, errors naming file, line and expected type).
- **Options.** (a) Kept in `onze.json`, read into the typed record at build as 299 does, a wrong key or value an error at its line in the file. (b) A typed record in the app's code (`pub val config = OnzeConfig(trailingSlash: .Never, …)`), no JSON. (c) As is.
- **Recommendation.** (a) — configuration is allowed there (284); the build checks it as code would, as 299 does for rakun.
- **Blocks.** 124; 08-h; `07-onze/49`, `50`.

#### nat-f4 · The `ONZE_PUBLIC_` prefix on environment variables (53, `contracts.md`)
- **Measured.** A variable reaches client code only when its name starts with `ONZE_PUBLIC_` (Next's `NEXT_PUBLIC_`). A missing prefix is not silent: the bundler refuses at build a client module's `env.read("X")` without it, naming the variable (`env-non-public`, `onze-bundler/src/refusal.bp:13-14`; `contracts.md:440-442`). What remains is a stage fact (186) carried by a naming convention the environment must follow (`client-island-example.bp:41`).
- **Options.** (a) Kept. (b) The declaration says it — `#[publicEnv] val apiUrl = env.read("API_URL")`, its use from a `#[client]` component checked at comptime (186); a marker of its own, since `#[clientVisible]` is 278's hydration annotation; 299's `#[env("…")]` the precedent in a record. (c) A list of public variables in `onze.json`.
- **Recommendation.** (b).
- **Blocks.** `07-onze/50`, `53`; `contracts.md`.

### 01-compiler — the language

#### lg2-b · What `@Task<T>` means on the BEAM
- **Measured.** On erlang and beam a Task body runs to completion where created: two `async.delay(300, …)` created before either is awaited take ≥ 600 ms (under 600 ms on commonJS).
- **Options.** (1) A Task promises the value, nothing about when its body runs; concurrency = `std/async`'s explicit process per unstarted thunk, documented. (2) A scheduler behind `@Task` on the BEAM (a process per Task, `await` a receive). (3) `spawn` / `join` in the language.
- **Recommendation.** (1) — the restrictive reading of 1.0.10's 120.
- **Blocks.** The row; rakun 02, 23, 25, 28, 30, 60.

#### lg2-d · A decorator that reads the body it annotates
- **Measured.** `decl.body` is the checker's `unknown field 'body' on type 'Decl'`, located at the read in the decorator body (`01-checker`'s decorator-body row; it was `{error,{badkey,body}}` at the annotation); the handle carries kind, name, fields, variants, methods, return type, annotations.
- **Options.** (1) No statement access. (2) A read-only statement tree on `@Decl`. (3) A body-walking comptime API.
- **Recommendation.** (1); rakun 83's saga stays a value pairing each step with its compensation.
- **Blocks.** The row; rakun 83.

#### lg2-h · Raising and catching by type
- **Measured.** `try load(p) catch { e: NotFound -> … }` does not parse; a `@Result<T, E>`'s error is typed by `E`, read with `case` in the `catch` body; a host exception is not an `E`.
- **Options.** (1) An error is a `@Result`'s `E` (1.0.10's 121): a typed error is an enum matched with `case`. (2) A `catch` arm per type. (3) Typed host exceptions.
- **Recommendation.** (1) — the row becomes documentation of 121.
- **Blocks.** The row; rakun 07, 31, 63.

#### lg2-l · Whether `noreturn` is a bottom type
- **Measured.** `fn notFound() -> noreturn { raise("…"); }` ends the path on commonJS and erlang, but `throw notFound();` in a `@Result` body and `val s: string = notFound();` mismatch → jhonstart's `notFound()` / `redirect()` declare `-> string` (`error_boundary.bp:180-188`); front 53's example writes `val _gone = redirect(…)` (`server-action-example.bp:79`); onze's blog app calls `notFound();` as a statement. `@panic` / `@todo` are `noreturn`; a branch ending in a `noreturn` call already narrows — may be confirmed de facto.
- **Options.** (1) `noreturn` unifies with nothing: a call to it is a statement ending its path; the signals become `-> noreturn` called as statements (in a page: `fn() -> View`, `use params<P>()`). (2) `noreturn` is the bottom type, fits any position.
- **Recommendation.** (1).
- **Blocks.** The row; jhonstart's signals (63, `31-a`); rakun's navigation tests.

#### lg2-n · A thunk coerced into `Node`
- **Measured.** `show({ -> "x" })` against `fn show(children: Children)` (`Node` under 223) mismatches.
- **Options.** (1) No thunk coercion: a deferred child is a named field of the boundary. (2) `fn() -> Element` coerces into `Node`.
- **Recommendation.** (1): compiler-known coercions stay three (array, `Element`, `string`).
- **Blocks.** The row; jhonstart 30.

#### lg2-p · Cancellation
- **Measured.** `std/async` has no cancel handle; a losing racer and an expired timeout run to completion.
- **Options.** (1) None: losing work completes, result discarded, documented. (2) Explicit cancellation tokens. (3) Linked processes with a kill path on the BEAM.
- **Recommendation.** (1), in step with `lg2-b` (1).
- **Blocks.** The row; rakun 02.

#### lg2-s · Module-graph reflection
- **Measured.** `decl.imports` is the checker's unknown field of `Decl`, at the read (was `badkey` at the annotation); `onze-bundler/src/graph.bp` reads imports with `importsOf`, a textual scan.
- **Options.** (1) None: `importsOf` stays a textual scan that fails loudly. (2) An `imports` field on a module-level `@Decl`.
- **Recommendation.** (1); its old argument ("in step with `lg2-k`") fell with 216.
- **Blocks.** The row; onze 68 (client bundle).

#### lg2-u · An expression-position decorator outside markup
- **Measured.** `val x = #[deco] 1;` refused (`loop-annotation-not-generator`). Emilia front 48's markup case is answered: a tag annotation is a decorator (278, 302), and emilia reaches markup as `<h1 #[styled(…)]>` (301). Left: a decorator on an ordinary expression.
- **Options.** (1) None: outside markup, expression-level work is a call (`traced(compute())`). (2) Expression-position decorators run in the eval script (`#[traced] compute()`).
- **Recommendation.** (1).
- **Blocks.** The row (emilia 48's markup case covered by 301).

### 02-std-and-packaging

#### std-e · Test lifecycle hooks
- **Measured.** Library tests reset state by hand at the top of the body: rakun-web's `resetChain()` 77×, `rkAppReset(…)` 20×, `resetTables(…)` 14×, among others; rakun-test's `resetSingletons` / `resetContext` only in its own `context_test.bp`; jhonstart-dom-test's `installDocument(…)` 11×.
- **Options.** (a) None: a test body calls its reset helper. (b) `#[before]` / `#[after]` on a module-level fn the runner calls around every `test`. (c) `beforeEach { … }` blocks in the grammar.
- **Recommendation.** (a): nothing implicit runs around a test.
- **Blocks.** The `language-gaps.md` row "No test lifecycle hooks".

### 03-bundled-libs

#### 07-b · Does "one library, several divergent copies" also justify a package?
- **Measured.** rakun has four divergent `Cookie:` readers inside itself (`request_context.bp`, `csrf.bp`, `rakun-app/i18n.bp`, `session_cookie.bp`; 196, front 104). The cookie and q-value copies already qualify under 115's test (onze consumes them too).
- **Options.** (a) 115's "two or more libraries" stays the only test. (b) Add the divergence test.
- **Recommendation.** (a): a single-library duplicate goes to std or the owning library's core.
- **Blocks.** Nothing; the rule for the next candidate (front 104's `http` exists; rakun adopts it in its step 5).

#### 07-h · Bundled, or a separate shared repository
- **Measured.** Wires both frameworks must agree on byte for byte ship with the compiler that embeds them; a separate repository = a git dependency, constrained by `lg2-v` (no `subdir`) and 242 (only a direct dependency importable).
- **Options.** (a) Bundled — versioned with the compiler, no `dependencies` entry. (b) A shared `botopink/common` repository with its own cadence.
- **Recommendation.** (a).
- **Blocks.** Nothing waits; the track is cut as (a).

#### 138-a · Does the shorthand import reach a dependency's modules?
- **Measured.** Decision 170's compiler side (`comptime.zig` `outsideShorthandReach`) keeps the shorthand (`import {x};`, no `from`) out of a **bundled** package's modules only. After 326 std is the one bundled package, and std's modules are reached anyway (another refusal: `` `split` is declared `pub` by `std/path` and by `config`, and this import does not say which ``), so the exclusion covers nothing. `tests/language/modules/shorthand_import_beside_bundled_package`, rewritten to declare a fixture `routing` by `path`, answers on all four targets: `error: ambiguous-import-use: `splitPath` is imported from two declarations — declared `pub` by `config` and by `routing/match` — and this use does not say which`. On the parent binary (bundled `routing`) it printed `own` / `2`.
- **Options.** Over `src/config.bp` = `pub fn splitPath(p: string) -> string[] { return ["own", p]; }` and `src/main.bp` = `pub mod config; import {splitPath}; import {splitPath as routeSplit} from "routing";` with `routing` declared:
  (a) the shorthand resolves among the importing package's own modules only — never a dependency's, never std's: the program prints `own` then `2`, as it did while `routing` was bundled (326: "their names, exports and import sources do not change"); `comptime.zig`'s exclusion keys on "a module of another package of the build" instead of "a bundled package" (01-compiler).
  (b) the shorthand reaches every loaded module, own or not: `import {splitPath};` is `ambiguous-import-use`, and the program must write `import {config.splitPath};` (170: "a bare name reaching two declarations is refused"); the cell becomes a `<target>.expect` refusal, and `outsideShorthandReach` is deleted as dead code.
- **Recommendation.** (b) — the strictest (decision 67: refuse > accept), and no code to keep for a package kind that no longer exists; a consumer that met the case writes the module path once.
- **Blocks.** The cell above (red until decided) and with it front 138's botopink-lang patch; under (b) also any consumer member whose shorthand reached a moved package's name (none measured in `zig build test-libs`).

### 04-rakun

#### erk-a · The source of an `erika "…"` query in a method body (*proposed*)
- **Measured.** 312: `from User` names the type; a database source implements erika's `QuerySource<T>` (rakun-data's `Table<T>`). In a `#[repository]` behavior the generated `Users.Sql(db)` owns the source (313). In a method body — `type Report(users: Table<User>) { fn active(self: Self) -> @Result<User[], StoreError> { return erika "select * from User where active = true"; } }` — nothing in the query says which value is the source.
- **Options.** (a) The source is a hole: `erika "select * from ${self.users} where active = true"` — the row type from `Table<User>`; `from User` is then the in-memory and annotation form only. (b) `from User` everywhere; in a body the source is the one field of `self` typed `Table<User>` — none or two is an error at the query (by type, as rakun's container injects). (c) Both: (b), and (a) when two fields of the same table type exist.
- **Recommendation.** (b): one spelling of `from` in every place; the source found by type, never by a name.
- **Blocks.** `04-rakun/137` step 2's body form; rakun 08 step 7's body-form cell.

#### erk-b · `#[documentQuery]` under 313 (*proposed*)
- **Measured.** 09 step 4: `#[documentQuery("…")]` follows `#[query]`'s shape — a member of the repository type answering the template verbatim. 313 deletes that shape for SQL: a repository is a `#[repository] behavior`, its methods carrying `#[erika "…"]` or `#[nativeQuery("…")]`. erika's grammar is SQL's; a document store's filter is JSON (`$in`, `$gt`, …).
- **Options.** (a) The same shape: a document repository is a `#[repository] behavior` whose methods carry `#[documentQuery("…")]`, an ordinary string handed to the store as `#[nativeQuery]` hands SQL to the driver (`:name` placeholders matched against the parameters, escaped by `bind`). (b) erika gains a document target — the same `select … where …` lowered to the store's filter. (c) As is: a member of the type.
- **Recommendation.** (a) now — one repository shape for every store; (b) when a measured need asks for it.
- **Blocks.** 09 step 4.

#### 03r-ab · Front 09's binary-protocol stores
- **Measured.** The store is selected by `rakun.nosql.url`. MongoDB, Neo4j, Cassandra, Couchbase are byte protocols (`lg2-a`) needing OTP drivers a sidecar cannot load; ETS and Mnesia are in the VM; Redis is RESP over `gen_tcp`; Elasticsearch is HTTP + JSON. 09's README is already written to (a): the former steps 4 and 7 are step 5's refusal cells plus one `deferred.md` row each — only the record is missing.
- **Options.** (a) 09 ships `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://`, `https://` with the behavior suite against all four in the gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` are recognised schemes whose boot refusal names `lg2-a` and the driver (step 5). (b) Four protocol clients in Erlang sidecars, a front each. (c) Defer 09.
- **Recommendation.** (a): never a fallback to ETS under a Mongo URL; the Elasticsearch arm without a `rakun-client` edge (`ctr-w`; 09 step 3 still goes through it). The front already follows (a).
- **Blocks.** 09 step 5 (the refusal cells).

#### 03r-ae · SAML 2.0 ACS
- **Measured.** Verifying an IdP signature needs Exclusive XML Canonicalisation, which neither OTP's `xmerl` nor std provides; `saml2/saml2.bp` answers 501.
- **Options.** (a) exc-c14n over `xmerl`'s tree in `src/sidecars/rakun_saml2.erl` (~300 lines), the three boxes closed by a fixture signed with a checked-in key. (b) Retire the SP: the three boxes go, `saml2/` keeps 501 with a `deferred.md` row. (c) Leave them open.
- **Recommendation.** (a) if 79 is staffed this milestone, else (b); never (c).
- **Blocks.** 79 step 3.

#### 03r-af · The seven unbuilt example projects
- **Measured.** `examples/` holds `rakun`, `rakun-container`, `rakun-ssr` (gate cells); `rest-service`, `secured-api`, `blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit` never started; every member's contract asserted by its own tests.
- **Options.** (a) Retire the seven (1.0.10 example list a closed record; the three on disk gain a `README.md` each). (b) Build them, one front each, after every member front. (c) Build `rest-service` only.
- **Recommendation.** (a).
- **Blocks.** 73 step 3.

#### 03r-ak · CycloneDX validation
- **Measured.** The box asks for validation against a checked-in CycloneDX 1.5 schema, no network; std has no JSON-schema validator; `release_test.bp:168` asserts fields by name (`rakun-cli/test/release/` after 128).
- **Options.** (a) `release_test.bp` walks the SBOM against `test/release/fixtures/bom-1.5.schema.json`'s `required`, `type`, `enum` and local `$ref`s (~120 lines), as 81 step 3 already reads. (b) Amend the box to the field-by-field list. (c) A `json.schema` in std.
- **Recommendation.** (a).
- **Blocks.** 81 step 3.

#### 03r-al · Kafka producer transactions against the in-process broker
- **Measured.** `rakun-messaging/src/reliability/transaction.bp:39` provides `withProducerTransaction(prefix, body)` (sends held, released on commit, dropped on a raise; `read_committed` reader tested in `transaction_test.bp`). 15 step 5 is already written for (a): four boxes (outbox path through `withProducerTransaction`, no outbox row; nothing visible to `read_committed` after an abort; the path in the log; one `deferred.md` row for a real broker). Only the record is missing.
- **Options.** (a) 83's outbox path publishes through `withProducerTransaction` on the in-process broker; real-broker run a `deferred.md` row. (b) Delete step 5's broker boxes. (c) Leave step 5 open until a real Kafka is in the gate.
- **Recommendation.** (a).
- **Blocks.** 15 step 5 (the record only; the front follows (a)).

#### 03r-am · Where the broker and scheduler doubles live
- **Measured.** `rakun-test` depends on `rakun` only; no `rakun-messaging/test/*.bp` imports `rakun-test` today, but 19 step 3 makes `container_test.bp` run through the double — with the double in `rakun-test` that is `rakun-test → rakun-messaging` beside `rakun-messaging (tests) → rakun-test`, a package cycle unless the loader honours test scope (not verified). `rkOnReset(name, reset)` (`rakun/src/runtime.bp:215`).
- **Options.** (a) Measure: add the edge and `container_test.bp`'s import; if `botopink test` refuses the cycle, the doubles live beside the module they double (`rakun-messaging/src/broker_double.bp` + `rakun_messaging_fixture.erl`, `rakun-scheduling/src/task_double.bp`) and `rakun-test` documents them. (b) Take the edge, assuming the rule landed. (c) The doubles in `rakun-test`, reaching the registries only through core hooks (`rkOnReset("broker-double", …)`, the listener-names term).
- **Recommendation.** (a), with (c)'s shape either way.
- **Blocks.** 19 steps 3 and 4.

#### 03r-an · RSocket's WebSocket transport after decision 187 (*proposed*, raised as R92-1)
- **Measured.** R92-1 mounts the transport via `rakun-websocket`'s `#[wsEndpoint]`; after 187 RSocket lives in `rakun-messaging` → the edge would load `rakun-websocket`'s tree (security, data) for every messaging consumer; today the WebSocket transport is refused at boot (`rakun-rsocket/src/rsocket.bp:69`, TCP only).
- **Options.** (a) Take the edge `rakun-messaging → rakun-websocket`. (b) The core defines a transport extension point `rakun-websocket` plugs into (185's rule), keyed by the transport enum's variant (`rkRegisterTransport(.WebSocket, …)` — 299 types the config, 281 no string). (c) Retire the WebSocket transport: R92-1's two boxes and R92-7's `ws://` / `wss://` arms deleted, TCP and TLS only, a `deferred.md` row.
- **Recommendation.** (b).
- **Blocks.** 92 step 2's first and third boxes.

### 05-jhonstart

#### 67-a · Where the DOM-side forms boxes are asserted
- **Measured.** `fieldError` after `__jhFormState`, in-place re-render on `ok: false`, two forms' `pending`, optimistic commit / roll-back read `document` and `FormData`; `botopink test` has no DOM; `jhonstart-dom-test` (`fake_dom.mjs`, commonJS only) already serves the render's browser half. Front 67's header says "`67-a` answered", but no decision records it — still open.
- **Options.** (a) Extend `fake_dom.mjs` with `<form>`, `<input>`, `FormData`, `submit`; assert the five boxes (1.0.10's 3a, 3b, 4, 5) in `jhonstart-dom-test/test/forms_dom_test.bp` now, and again in onze 53's browser. (b) Only in onze 53's browser. (c) A real DOM library as a dev dependency.
- **Recommendation.** (a).
- **Blocks.** 67 steps 1–3 (written for (a)); onze 53's write path.

### 06-emilia

#### 05emilia-n · The unplaced Tailwind rows
- **Measured.** Four rows have no owner: named `:has()` / `:not()` / ARIA / data / `in-[…]` forms (reachable via `arbSel` only); named groups and peers; `@theme inline`; negative translate (`TranslateX/Y.Neg` absent, `tokens.bp:2259-2272`). The fifth — a cleared breakpoint emitting `@media (width >= )` — is decision 300's: "a token naming a cleared or absent breakpoint is a compile error where the token list is comptime-known" (34 step 3, unconditional).
- **Options.** (a) None: the four out of scope in `docs.md` § Deviations, written with `arbSel`. (b) Negative translate and named groups / peers. (c) All four, `@theme inline` included (a second render mode).
- **Recommendation.** (a); (b) is the feature answer if any is wanted.
- **Blocks.** 34 step 4 (conditional).

### 07-onze

#### 50-b · What `onze dev` does on a change
- **Measured.** `onze build` compiles the server to BEAM (`server/beam/`), `onze start` runs `erl -noshell -pa <outDir>/server/beam -eval …` (50-a); `onze-bundler/src/rebuild.bp` computes invalidated modules; the BEAM can `code:load_file/1`; UI registry and route table fill at module load (decision 140): a reloaded page re-registers, a new route file needs `onze_routes.bp` regenerated and the table rebuilt.
- **Options.** (a) Restart the node on every change (`build` + `start` looped over a file watcher — same bytes as `start`, 1–3 s per edit). (b) Hot-load changed modules; regenerate and reload `onze_routes` when the app tree changes. (c) (b), falling back to (a) when a convention file changed. Browser island state lost either way (Fast Refresh a non-goal, `07-onze/reference-holes.md` § 29).
- **Recommendation.** (a): one code path, the same bytes `start` serves; (b) later, if (a) measures too slow on the blog.
- **Blocks.** 50 step 2; 53 step 6.

### 08-bpp

#### 08-d · Who scopes CSS
- **Measured.** emilia compiles `Token[]`, "not a CSS processor"; onze-assets renames `*.module.css` classes (`style_module.bp`); decision 113.
- **Options.** (a) emilia gains `scopeCss(scope, css)`, reached via `jhonstart-emilia`. (b) onze-assets, beside the module renamer. (c) core `jhonstart`'s `html` scopes its own `<style>` (the `jhonstart-html` member goes, 200).
- **Recommendation.** (a): (c) puts a CSS parser in the HTML library; (b) leaves scoped styles unavailable without onze.
- **Blocks.** 119, every step — on the critical chain 118 → 119 → 120 → 126 → 127 → 124.

#### props-d · A native tag's attributes (*proposed*)
- **Measured.** 192 covers component tags only; a native tag is `fn <tag>(children: Children, attrs: Array<#(string, string)> = [])` in jhonstart (118 § Notes).
- **Options.** (a) A native tag's attributes = fields of a props type jhonstart declares per element (unknown attribute or wrong type refused, as 192). (b) Any attribute name, a `string` value or a 191 hole. (c) A global attribute set plus per-tag lists, `string` values.
- **Recommendation.** (a): one rule for every tag, the most restrictive.
- **Blocks.** 118 steps 1 and 4.

#### props-e · A named slot (*proposed*)
- **Measured.** 193 names the `children` field, no other; Astro writes `<p slot="footer">` / `<slot name="footer">` (118 § Notes). 287 already dropped islands' `slot="fallback"` (the fallback is an annotation argument) and left named slots in general here.
- **Options.** (a) A named slot is a props field of type `Node` (223), written as an attribute (`type Props(children: Node, footer: Node)`, `footer={…}`); `slot="…"` refused. (b) `slot="footer"` on a child routes it to props field `footer`. (c) No named slots.
- **Recommendation.** (a): 192 already covers it, no second routing mechanism — the path 287 took for the fallback.
- **Blocks.** 118's slot boxes (steps 1 and 4).

#### props-f · A spread on a component (*proposed*)
- **Measured.** 118 step 1 refuses `{...expr}` on a component (it accepts one on an element) for a reason 192 removes (attributes are now one record's fields).
- **Options.** (a) Still refused: the attributes are the form. (b) `{...p}` with `p` of the props type, explicit attributes overriding.
- **Recommendation.** (a).
- **Blocks.** 118 step 1.

### 09-cardume

#### atm-c · An atom's `T` across the server/browser seam (*proposed*)
- **Measured.** The server seeds the values an island read into its payload (136 step 6); a value crossing must be encodable — after 306, a `#[validated]` type's `encode` member (`T.encode(v)`, 327; another library takes `T` only with `@typeInfo(T).meta(Validated)`), or one of the `T`s 294 accepts for a cookie (string, number, `bool`, enum, one-field record); some state is browser-only by nature (a DOM handle, a function).
- **Options.** (a) Every atom's `T` encodable, checked where the atom is declared. (b) Any `T`; an island's read set checked at build — a non-encodable atom an island reads must be declared client-only (`clientAtom(…)`, or 278's `#[clientOnly]` extended to declarations, 282). (c) Any `T`, refused only at run time.
- **Recommendation.** (b): restrictive where it matters (what crosses), free elsewhere.
- **Blocks.** 136 step 6.

#### atm-d · Which atom effects ship (*proposed*)
- **Measured.** Recoil's atom effects persist or sync an atom (localStorage, URL, a server push); none exists here.
- **Options.** (a) None in the first cut. (b) `persistLocal("cart")` only. (c) `persistLocal` and a search-param sync (`syncSearchParam("tab")`).
- **Recommendation.** (a): land the store first; effects as their own step after a measured need.
- **Blocks.** 136 step 8.

### From the maintainer's Portuguese record (`decisoes-pendentes.md`)

#### 07-i (revision) · Whether 163's ban on repeated names in bundled packages survives 170's alias
- **Measured.** 163 bans a bundled package exporting a name std or a framework exports "until the toolchain line closes"; 170 (an import naming its module is never ambiguous; alias when both are needed) closes it.
- **Options.** (a) Still banned: a new bundled package picks a non-colliding name (`http`'s `cookie` module, `actions`' `id.deriveActionId`). (b) Ban lifted: natural names, importers alias.
- **Recommendation.** (a).
- **Blocks.** Nothing; 102, 103 and 104 already chose free names.

### Ownership

#### own-a · Who owns the test runners (*proposed*)
- **Measured.** `scripts/{gate.sh,test-libs.sh,lib/pool.sh}` (beyond 114's budget lines), `tests/language/run.sh` (beyond 12's report), `modules/test-shard/**`, `modules/lib-test-runner/**`, the meta `scripts/**` were owned by `25-gate-perf`, 113, 115, 133, all closed (`fronts.md` § Ownership, open item). Provisional rule there (`fronts.md:55-59`) = option (c): an editing front names the carve-out in its commit; no two open fronts edit the same file. No open step edits a runner: 07-residuals step 12 "edits no runner", 114 step 5's budget lines are already 114's, 114 step 7 only runs the gate.
- **Options.** (a) `01-compiler/07-residuals`, which already holds 25's open step (the per-cell dependency compile). (b) `00-gate/114`, the gate's residue. (c) none: each front names a carve-out per commit (today's provisional rule, kept).
- **Recommendation.** (a): one owner, the front that inherited 25's open step.
- **Blocks.** Nothing today; the provisional rule (c) holds until answered.

### Contradictions that block no 00–03 step

#### ctr-l · Decision 186's third refusal against decision 202
- **Rules.** 186 refuses "a `#[serverOnly]` hook in a page that declares itself prerendered (`08-g`)". 202: "No declaration … no `pub val prerender` … no way to force". A page is `pub fn blog() -> View` reading `use cookie(sessionCookie)` (293, 294): rendered per request, no error.
- **Recommendation.** Drop 186's third refusal: under 202 no page declares itself prerendered. `05-jhonstart/26` step 8 already lists the two refusals only (`README.md:58-59,182-183`); only 186's row is pending.
- **Blocks.** Nothing in the fronts; the record.

#### ctr-v · Decision 189 (org-3) against emilia's fronts opening before 118
- **Rules.** org-3: 118's carve-outs land before the owning front opens. `06-emilia/34` step 1 and `33` step 2 open now; emilia's `[class]={…}` lines (`attributes.bp:30,32,36`, `emilia.bp:185,202`) and `emilia-card/src/main.bp:5`'s `[emilia]={…}` are comments only, reworded by those fronts.
- **Recommendation.** Record that a comments-only carve-out is taken by the owning front; 118 keeps the code lines (its own tests, `jhonstart-emilia`'s bridge test, `document-shell`). The fronts already follow it (118 § Does not touch, 34 step 1, `fronts.md:49`); only org-3's row is pending.
- **Blocks.** Nothing in the fronts; the record.

#### ctr-w · Front 09's Elasticsearch arm against decision 185
- **Rules.** 185: an optional capability goes through a core extension point, "no member-to-member edge". `04-rakun/09` § Open point: the Elasticsearch arm over `rakun-client` adds a `rakun-data → rakun-client` edge every data consumer loads.
- **Recommendation.** The arm reaches HTTP via a core extension point (or `httpc` directly, as 65's relay does), not a `rakun-client` edge; answered with `03r-ab`'s arm list.
- **Blocks.** 09 step 3.

---

## Part 3 — Implementation choices of tracks 04–09

### 04-rakun (21)

| Id | Choice implemented | Where |
|---|---|---|
| 03r-a | Every rakun manifest is `["erlang"]`; a built erlang program ships and loads its `.erl` sidecars (ledger half moot under 153) | every member |
| 03r-c | Front 05's readers stay botopink (`config.bp`); no `rakun_config.erl`; under 299 they feed the `#[config]` records | 04 |
| 03r-e | A cookie or query component std refuses, or that would decode to a control character, stays as written (`decodeComponent`) (`ctr-p`) | 04 |
| 03r-f | A cache key is `namespace + ":" + hash.strongCacheKey(parts)` | 12 |
| 03r-g | A private-scope read with no session runs the loader, stores nothing | 12 |
| 03r-h | A twin's key is `[method, args…]`; `#[cacheEvict(name, false)]` evicts it under every `#[cacheable(name)]` reader | 12 |
| 03r-i | Redis cache provider reuses rakun-session's RESP wire (`rkSessRedis`); `revalidateTag` deletes; unreachable Redis runs the loader uncached (health DOWN) | 12 |
| 03r-j | Outside a request `revalidateTag` / `revalidatePath` legal, `updateTag` raises; global `rakun.cache.type=none` disables every cache whatever its own type | 12 |
| 03r-k | Every messaging arm runs on the in-process broker (`transport=memory`); a real address without it refuses the boot naming the driver | 15 |
| 03r-l | A listener container is named after its destination (`#[amqpListener("orders")]` → `rakun.messaging.listener.orders.*`, `#[streamListener("audit-stream", "@next")]` → `listener.audit-stream.*`); Redis defaults to ack-mode `none` (explicit `auto` / `manual` on Redis refuses the boot). Key spellings follow 299 (`ackMode` or `#[key("ack-mode")]`) | 15 · `markers.bp:90,103` · `container.bp:125` |
| 03r-m | Inside a server action `revalidatePath` / `revalidateTag` expire at once; outside, stale-then-fresh | 12 · 22 |
| 03r-n | A JSON-RPC argument is a form-encoded field list, read in order into one form | 22 |
| 03r-p | A slot belongs to the nearest layout at or above its shortest entry; a conflict is two pages of one slot at one URL | 22 |
| 03r-r | Starters name sibling members `{ "workspace": true }` | 73 |
| 03r-s | OTLP pushed as HTTP/JSON (`json:encode` in `rakun_metrics.erl`) | 17 |
| 03r-t | Front 76's keys under `rakun.management.*`, in one `management.bp` plus the `rakun_probes` sidecar | 11 |
| 03r-u | Liveness group admits only `livenessState`, `ping`, `diskSpace`; any other name refuses the boot | 11 |
| 03r-v | Typed query builder's operator is the enum `Op` (`Eq`, `Ne`, `Lt`, `Gt`, `Le`, `Ge`, `Like`): `queryOf(City.entityMeta()).where(City.columns().state, Op.Eq, "CA")`; the column as `Type.Field<City>` (308) is a separate question | 08 · `orm/query.bp:84-115` |
| 03r-w | OAuth2's explicit endpoints are `OAuth2Provider` fields (`authorizationUri`, `tokenUri`, `userinfoUri`, `jwksUri`); client credentials are `withClientToken(id, call)`, retrying once on 401 | 79 · 13 |
| 03r-x | Outbox relay claims by conditional `UPDATE` (a crashed relay's claims return via `reclaimStale`); saga and 2PC coordinators persist every transition and resume at boot (`resumeSagas`, `recover2pc`); job store claims triggers and takes over leases the same way | 15 |

### 05-jhonstart (10)

| Id | Choice implemented | Where |
|---|---|---|
| 26-a (jhonstart) | Every router cell dual-target (a `router_runtime.mjs` twin). Id shared with 01-compiler's `26-a`, decision 242 | core |
| 27-a | A browser cell in a two-target member is dual-target, its erlang twin answering the server's truth: on the server `use linkStatus()` is `LinkStatus(pending: false, href: "")` | `jhonstart-link` (`link.bp:187,231`) · core |
| 29-a | What 281 leaves: the island starter table is the registry's `globals.starters`, filled per route by `registerRouteStarters(pattern, load)` (a route pattern is a URL, a string under 281); a second loader for one route fails. The per-name `registerStarter(name, start)` goes — 281 builds the starter table at comptime (`@TypeInfo.all(with: client)`, 120 step 6, 53 step 7) | core · 26 step 5 (its `docs.md` row still names `registerStarter`) |
| 30-b | `RenderPlugin` is a record of async functions; `payload` answers `Array<#(key, json)>`; `chunk(id)` runs in the boundary's own process | `streaming.bp` |
| 30-c | `render` / `renderStream` / `App` in `streaming.bp`; `compose` takes the page as a thunk, runs the layouts first — `compose(chain, { -> Page() })`; today's `route: PageContext` parameter goes with 293, the page is `fn() -> View` (276) | `streaming.bp` · `render.bp:341` |
| 30-d | `Suspense(Boundary(id, fallback, child))` registers its boundary with the render via one host cell; the page returns only the tree (`-> View`) | `suspense.bp:19-34` |
| 30-e | The segment record is `UiSegment` | core |
| 30-f | `app(…, lang = "en")`: one checked language per app. The check becomes decision 180's BCP 47 subset once 105 replaces `isLangTag` with `i18n.wellFormedTag`; a per-request `PageInput.lang` from rakun-app's existing `htmlLang()` stays additive | core · `streaming.bp:197-204` · 105 |
| 30-g | Browser half asserted in the commonJS-only member `jhonstart-dom-test` over `fake_dom.mjs` | `jhonstart-dom-test` |
| 31-a | `notFound()` / `redirect(url)` raise via one host cell (`__jhRaise`); a boundary captures via `__jhCapture`; `notFoundReason()` / `redirectReason(url)` answer the reason without raising. They declare `-> string` until `noreturn` fits a value position — waits on nat-d6 and lg2-l (if nat-d6 is (a), they become `-> noreturn`) | core · `error_boundary.bp:118-187` |

### 06-emilia (11)

| Id | Choice implemented | Where |
|---|---|---|
| 05emilia-a | Filter reader is upstream's inline chain (`filterChain()`, `backdropFilterChain()`), not `var(--tw-filter)` | 42 |
| 05emilia-b | The backdrop section is `BackdropFilter` | 42 |
| 05emilia-c | `drop-shadow-none` follows upstream (`--tw-drop-shadow: ` and the reader) | 42 |
| 05emilia-d | Snap strictness is the fallback `var(--tw-scroll-snap-strictness, proximity)` | 46 |
| 05emilia-e | `fullTheme()` rides on `fullOptions()` in `emilia.bp` (`flush()` renders with it); `defaultOptions()` / `defaultTheme()` stay palette-free. Open with 300: 300 names `defaultTheme()` as the `#[theme]` base and the no-`#[theme]` fallback, which has no palette — recommended: read it as `fullTheme()` (alternatives: make `defaultTheme()` the full theme, or take 300 literally and leave `var(--color-…)` undefined) | 56 · 34 step 3 |
| 05emilia-f | `--inset-shadow-*` entries drop upstream's leading `inset` | 41 |
| 05emilia-g | `space-*` / `divide-*` follow upstream's selector and reverse-aware margins | 35 · 40 |
| 05emilia-i | `--tw-*` transform variables are `@property` blocks with upstream's `properties` layer — `translate-*`, `skew-*` and `scale-*` (`--tw-scale-*`) alike | 45 · 54 · 56 |
| 05emilia-j | A selector-list modifier (`marker:`, `selection:`) is a list of one-`&` variants | 34 · 56 |
| 05emilia-k | Negative half step is `spacingNegHalf(n)`; `spacingHalf` refuses a negative `n` | 54 |
| 05emilia-l | Confirming a column moves its whole family to upstream's form, one helper per shape; the five families still out of parity are 06-emilia's EM-8 table (transition presets, `backdrop-opacity-*`, `border-spacing-*`, `-webkit-backdrop-filter`, `divide-*`'s border style) | 35–45; 34 step 2 moves the five under it |

### 07-onze (9)

| Id | Choice implemented | Where |
|---|---|---|
| 49-a | The core's suites render via its own `describe*` over `snapshots.assertAs`; `onze-test`'s helpers are thin wrappers | onze core |
| 49-c | `onze.json` refuses an unknown key, a duplicate, a wrong kind, a port outside `1..65535`, a non-string `allowedRedirects` entry | `config.bp` |
| 49-e | The rakun half of the boot is the erlang member `onze-server` | 49 step 2 |
| 50-a | `onze build` stages a server main, compiles it to BEAM; `onze start` runs it with `erl` — as amended: `start` calls front 71's `bin/onze` once it exists | 50 · 71 step 2 |
| 52-a | Font-metrics table has five transcribed rows; its generator is owed | 51 step 4 |
| 53-a | The blog's sources under `src/` (`appDir: "src/app"`) | 53 |
| 68-a | A client-manifest field escapes `%`, `\|`, LF and CR only | bundler |
| 68-d | The styleMap is evaluated by a probe compiled into both packages (`emilia-hash-split`, `emilia-unevaluated`) — moot once 34 step 1 and 119 step 4 land (301: `#[styled]` tokens are comptime, the class and rule computed at build over std's `contentHash`); holds until then | bundler |
| 69-a | onze-assets keeps `AssetRoot`; onze-server converts it to rakun-web's `StaticRoot` | assets · server |
