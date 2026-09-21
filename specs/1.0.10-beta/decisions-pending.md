# Decisions the maintainer owes — 1.0.10-beta

**Nineteen open, 71 to 89**, all raised on 2026-09-20 while the milestone was being cut — by
`01-std` (71–74), `02-packaging` (75–76), `06-onze` (77), `04-jhonstart` (78), the consolidation
itself (79), `05-emilia` (80–82), `00 · 18-comptime-runtimes` (83–86) and `00 · 19-use-activation`
(87–89). Each has a recommendation; none blocks writing the specs, several block the first commit of
the front that raised them. The next free number is **90**. Answers move to
[`decisions-taken.md`](./decisions-taken.md), whose numbering this file continues (1.0.5's record
stopped at 67; 68–70 were taken the same day).

The shape every question uses — **Measured · Options · Recommendation · Blocks** — is the one
1.0.5 used; the recommendation defaults to the most restrictive behaviour and no configuration
that bypasses it (decision 67).

---

## 71. Where does the old `onze` mocking surface go — `std/mocks` or each `<lib>-test`?

**Raised by:** `01-std` step 4 ([`onze-migration.md`](./01-std/onze-migration.md)).
**Measured.** `repository/onze/src/onze.bp` exports 8 assertion cells, 3 matchers, 3 specs, `OnzeStub`,
`when`, `verify`, the `#[mock]` decorator and an `onze.mjs` sidecar holding call-recording state; 8
tests. The plan moves 100 % of the *assertions* into `libs/std/src/asserts.bp` and says nothing about
the *mocks*.
**Options.** (a) `libs/std/src/mocks.bp` — one lib-agnostic module, the sidecar state becomes a
`globalThis.__bp_mocks` template pair (node + erlang) like `emilia.bp:24`'s; (b) a copy per
`<lib>-test` submodule; (c) drop mocking until a library asks for it.
**Recommendation.** (a). One runtime instead of a drifting copy per library, no
`jhonstart-test → rakun-test` dependency; the `-test` submodules keep only the injection pairing
(`#[mocks.mock]` + `#[bean]`). Nothing is lost, which (c) cannot claim.
**Blocks.** `01-std` step 4; `02-packaging`'s `<lib>-test` shape; `rakun-test`'s `@MockBean` twin.

## 72. The `.snap` file format and the slug rule

**Raised by:** `01-std` step 3 ([`snapshots.md`](./01-std/snapshots.md)); the four library
`test-snap.md` maps were written against it and diverge on one point.
**Measured.** The compiler's own snapshots (`modules/*/snapshots/**/*.snap.md`) carry a markdown
header; the libraries need a text file a person can diff. `snapshots.md` proposes
`botopink-snap 1` / `test:` / `subject:` / blank line / body; `04-jhonstart/test-snap.md` assumed
**no header** (body = the helper's text) and a slug of "lowercase, non-`[a-z0-9]` runs → `-`", while
`snapshots.md` pins the slugifier byte-identical to `codegen/tests/helpers.zig:38`.
**Options.** (a) the header, as proposed — the file names its test and subject, so a `.new` beside it
is self-describing; (b) body only — the path already names the test.
**Recommendation.** (a), and one slugifier (the compiler's) for both worlds; the jhonstart map is
re-read against it when 71–74 are answered, not before.
**Blocks.** `01-std` step 3's first commit; every `test-snap.md`'s `.snap` blocks are provisional
until then.

## 73. `@src().file` — package-root-relative with extension, and `fnName` inside a `test` block

**Raised by:** `01-std` step 1 ([`src-builtin.md`](./01-std/src-builtin.md)).
**Measured.** Zig's `@src().file` is the path as given to the compiler; a snapshot path derived from
an absolute file would differ per machine and per worktree (`.tasks/<name>/…`). Inside `test "…" {}`
there is no function name; the compiler's own `Loc` has `line`/`col`, and whether `col` is 1-based
was not confirmed from the lexer.
**Options.** `file`: (a) package-root-relative with extension (`src/tokens.bp`); (b) absolute; (c)
module path (`emilia@tokens`). `fnName` in a test: (a) the test name; (b) the synthesised
`__bp_test_N`; (c) empty.
**Recommendation.** `file` (a) — stable across machines and the only form `snapshots.path(loc)` can
turn into a directory beside the test; `fnName` (a) — it is what a failure message should print.
`column` is the same number the diagnostics print, 1-based, and `src-builtin.md` lists confirming
it as acceptance.
**Blocks.** `01-std` step 1 (the compiler carve-out); contract 7.

## 74. `-> @Result<void, string>` with an empty `return;`, and `try` inside a test body

**Raised by:** `01-std` steps 1–2 ([`asserts-api.md`](./01-std/asserts-api.md)).
**Measured.** No function in the tree returns `@Result<void, …>`; the precedent is `@Result<i32, …>`
with a sentinel. `try` inside `__bp_test_N` currently lowers as `TryForm.propagate`
(`commonJS.zig:615`) and would likely end a test *green* on an `error` value.
**Options.** (a) `@Result<void, string>` made real (empty `return;` in an `ok` position) and a test
body treated as a fallible context where a propagated `error` is a FAIL; (b) keep `@Result<i32,
string>` and a `0` sentinel in every assertion.
**Recommendation.** (a) — an assertion that returns a meaningless `0` is a surface everyone reads
and nobody wants; the test-body rule is the stricter one and it is what the plan's examples already
write (`try assertJsSingle(@src(), …)`).
**Blocks.** `01-std` steps 1–2; every `test-snap.md` case.

## 75. How `test-libs` and the dependency loader see `modules/**` and `examples/**`

**Raised by:** `02-packaging` ([`README.md`](./02-packaging/README.md) § Mechanism).
**Measured.** `modules/lib-test-runner/src/discovery.zig` treats every *immediate* child of a lib root
holding `botopink.json` as a lib; `compiler-cli/src/cli/libs.zig:loadOne` uses the same roots and
the same immediate-child rule and ships only a dependency's `files`. So `modules/**` and
`examples/**` are invisible to the gate and to `from "rakun-web"` today, and rakun's 13 scaffolded
manifests (`entry`, no `files`) would give a consumer zero modules.
**Options.** (A) export `repository/*/modules` and `repository/*/examples` as additional roots in
`scripts/test-libs.sh`, an umbrella manifest with no `files`, `files` mandatory on every module —
no compiler change; (B) nested discovery in `discovery.zig` and `libs.zig` — a carve-out of `00 ·
10-cli-residuals`.
**Recommendation.** (A) now, (B) filed as a `00` item; (A) is a shell change and a manifest rule, and
it fails loudly (a module without `files` ships nothing and its own tests say so).
**Blocks.** `02-packaging` step 1; the first `<lib>-test` submodule that a gate must run.

## 76. The `dependencies` manifest field — string array, object, or both

**Raised by:** `02-packaging` ([`README.md`](./02-packaging/README.md) § Manifests).
**Measured.** `config.zig` parses the object form (`DepSpec{git, path, ref}`) but never reads
`path`; `bpmp/manifest.zig` rejects the object form outright; `project_graph.zig` types it as
`[]const []const u8`, so rakun's `examples/rakun/botopink.json` object silently empties the list.
**Options.** (a) object form only, every reader made to parse it, the string form a located error;
(b) both forms forever; (c) string form only.
**Recommendation.** (a) — one shape, a located error for the other; (b) is the configuration
decision 67 refuses. Examples need `path` to depend on a lib by directory.
**Blocks.** `02-packaging` step 2; every `examples/<project>/botopink.json`.

## 77. onze's wave numbers contradict its dependency lines, and three seams reverse the dependency direction

**Raised by:** `06-onze` ([`README.md`](./06-onze/README.md), [`modules.md`](./06-onze/modules.md)).
**Measured.** Fronts 51 and 52 are wave 3 in their headers and depend on 69 (wave 4). Three 1.0.9
READMEs have rakun or jhonstart reaching *into* onze (23 → 69 style sink, 23 → 68 script tags,
29 → 68 `islandAttr`), against the rule `onze → rakun, jhonstart, emilia` and never back.
**Options.** (a) a `RenderHooks` record defined in rakun and wired by `Onze.run`, `islandAttr`
defined in jhonstart, waves re-stated from the dependency lines; (b) leave the seams and let 68/69
import from rakun's internals.
**Recommendation.** (a) — it is the only option that keeps the direction rule true, and the track
README already orders the fronts by dependency (`49 → 68 → 69 → 52 → 51 → 70 → 71 → 50 → 53`).
**Blocks.** 68 and 69's first step; 23 and 29's `Owns:` lines.

## 78. Two 1.0.9 jhonstart signatures disagree with each other

**Raised by:** `04-jhonstart` ([`unification.md`](./04-jhonstart/unification.md) § 1.2).
**Measured.** Front 94 and front 32 give `renderHead` different return types (32: `-> string`);
front 67's README names `parseActionState`'s parameter `envelope` while its example passes the bare
`state`.
**Options.** For each: take the README's or the example's spelling.
**Recommendation.** `renderHead -> string` (32 owns it); `parseActionState(envelope)` with the
example corrected — the README is the contract, the example is what it shows.
**Blocks.** 32, 67 and 94's first commit; `04-jhonstart/test-snap.md`'s corresponding cases.

## 79. What happens to the old `onze` repository

**Raised by:** the consolidation ([`01-std/onze-migration.md`](./01-std/onze-migration.md) step 5).
**Measured.** `.gitmodules` pins `repository/onze` to `git@github.com:botopink/onze.git`, the mocking
library. The orchestrator needs that directory and, ideally, that name on the remote.
**Options.** (a) tag the mocking library `mocking-lib-final`, archive it remotely, re-point the
submodule entry at the orchestrator's repository (new or the same remote re-initialised); (b) vendor
the old sources under `_archived/` in the new repo; (c) keep both under different directory names.
**Recommendation.** (a) — the history stays reachable, the tree carries nothing dead, and the name
is taken once. (c) contradicts decision 68's "the orchestrator takes the name".
**Blocks.** `01-std` step 5; `06-onze/49-onze-stand-up`.

## 80. Who composes the per-front theme entries into the default document

**Raised by:** `05-emilia` ([`unification.md`](./05-emilia/unification.md),
[`reference-coverage.md`](./05-emilia/reference-coverage.md)).
**Measured.** `defaultOptions()` carries a palette-free `defaultTheme()`, so a utility that emits
`var(--color-red-500)` refers to a variable no front defines in the document; sixteen fronts each
own a slice of the theme and no front owns the sum.
**Options.** (a) `fullTheme()` in `emilia.bp`, owned by front 56 (cascade and output), one
`extend` line appended per front as it lands; (b) each front emits its own `@theme` block into the
document; (c) the consumer composes the theme by hand.
**Recommendation.** (a) — one owner for the document, one line per front, and an undefined
variable becomes a failing snapshot in 56's own tests rather than a silent CSS no-op. (c) is the
configuration decision 67 refuses.
**Blocks.** 56's first commit; every utility snapshot that prints a `var(--…)`.

## 81. `Important(inner)` is cited by 56 and declared by nobody; `accent-auto` has no token

**Raised by:** `05-emilia` (fronts 56, 34, 46).
**Measured.** Front 56 emits the `!important` form through an `Important(inner)` modifier that
front 34 (modifiers) never declares. Tailwind's `accent-auto` is a real utility the payload-only
`Accent(color)` design cannot express.
**Options.** `Important`: (a) 34 declares it as a modifier; (b) 56 declares it beside the output
rules; (c) drop `!important` for this milestone. `accent-auto`: (a) a unit variant `AccentAuto`;
(b) `Accent(Color.Auto)` with a sentinel colour; (c) leave the row missing.
**Recommendation.** `Important` → (a), it is a modifier and 34 owns the modifier enum section;
`accent-auto` → (a), a unit variant is the honest spelling and the enum is additive.
**Blocks.** 34, 46 and 56's token sections; the `tokens.bp` banner blocks the restructure writes once.

## 82. Dark mode — class or attribute — and theme-blind breakpoints

**Raised by:** `05-emilia` (fronts 54 and 34).
**Measured.** Front 54 (theme) and front 34 (modifiers) contradict each other on whether dark mode is
selected by a class or by an attribute; 34's breakpoint functions read constants, so a
`--breakpoint-*` override in the theme is inert.
**Options.** Dark mode: (a) Tailwind v4's default — `prefers-color-scheme` with the class strategy as
the documented override, decided in 54 and consumed by 34; (b) attribute strategy. Breakpoints: (a)
34 reads them from the theme record 54 threads; (b) constants, override refused with a diagnostic.
**Recommendation.** Dark mode (a) with 54 as the single owner; breakpoints (a) — an override that
parses and does nothing is the shape decision 67 rules out, and (b)'s diagnostic is the fallback
only if threading the theme costs a `tokens.bp` change 34 does not own.
**Blocks.** 54 and 34's first commits; the modifier snapshots in `05-emilia/test-snap.md`.

## 83. Do the three resident comptime modules (server, two preludes) also stop being Erlang source?

**Raised by:** `00 · 18-comptime-runtimes` step 1 ([README § Questions Q1](./00-compiler-carry-over/18-comptime-runtimes/README.md#q1-do-the-three-resident-modules-server-two-preludes-also-stop-being-erlang-source)).
**Measured.** After step 1 the only `erlc` call left compiles `botopink_comptime_server.erl` and the
two preludes rendered from `erl_ast` forms — once per hash, ≈ 145 ms per compiler process.
**Options.** (a) keep `erlc` for the three; (b) assemble the preludes with the untyped BEAM mode and
hand-write the server in the `.S` model (needs `receive`/`spawn_monitor`/`try` instructions the model
lacks); (c) embed the three `.beam`s as bytes produced by `erlc` at `zig build` time.
**Recommendation.** (b) for the preludes, (c) for the server until the `.S` model has `receive`, then
(b) for it too; (a) contradicts decision 24's principle at the last three files.
**Blocks.** Step 1c's "no `erlc` on the path" acceptance.

## 84. Which comptime runtime does a native build use once parity is proven?

**Raised by:** `00 · 18-comptime-runtimes` step 3 ([README § Q2](./00-compiler-carry-over/18-comptime-runtimes/README.md#q2-which-runtime-does-a-native-build-use-by-default-once-parity-is-proven)).
**Measured.** The wat runtime spawns nothing; the beam runtime needs `erl` and is the reference
semantics. Today a commonJS or wasm build of a project with one decorator needs `erl` for that alone.
**Options.** (a) `beam` native, `wat` in the browser; (b) `wat` everywhere, `beam` for the parity test
and the erlang/beam targets only; (c) `wat` by default, `beam` when the target is erlang/beam — the
runtime follows the target's VM, no flag.
**Recommendation.** (c): a JavaScript build no longer depends on Erlang, an Erlang build already has
the VM; the choice is a property of the build target (structural, decision 67), not a knob.
**Blocks.** Step 3's selector and the CLI's `PATH` hint.

## 85. Double the whole snapshot tree, or only the files that can differ?

**Raised by:** `00 · 18-comptime-runtimes` step 4 ([README § Q3](./00-compiler-carry-over/18-comptime-runtimes/README.md#q3-double-the-whole-tree-or-only-the-snapshots-that-can-differ)).
**Measured.** 1 346 codegen snapshot files; 28 carry a `COMPTIME ERLANG` / `COMPTIME REPLY` section;
the other 1 318 are runtime-independent. The tree was collapsed twice this month for exactly this
redundancy.
**Options.** (a) the request as written — `codegen/{beam,wat}/<target>`, 2 692 files, pair equality
asserted by the harness; (b) the per-runtime sections alone under `codegen/comptime/{beam,wat}/`;
(c) the requested directory names with `wat/` holding only the files that can differ.
**Recommendation.** (a), because it is what was asked and its cost is mechanical; if the
two-files-per-row cost is what the 2026-09-18 collapse was about, (c) keeps the names and drops the
copies.
**Blocks.** Step 4's layout commit.

## 86. Which OTP release pins the BEAM opcode table?

**Raised by:** `00 · 18-comptime-runtimes` step 1 ([README § Q4](./00-compiler-carry-over/18-comptime-runtimes/README.md#q4-which-otp-release-pins-the-opcode-table)).
**Measured.** This machine runs OTP 29, CI OTP 28; the chunk set is stable since OTP 20, the `Code`
opcodes are per release; a module assembled with opcodes ≤ the oldest supported release loads on
every later one.
**Options.** (a) pin to OTP 28's table (CI's floor), refuse older with a diagnostic; (b) pin to the
release found at run time, one table per release; (c) emit only the opcode subset stable since OTP 24.
**Recommendation.** (a) with (c)'s subset — one table, one `beam_lib` validator run in the test, a
clear refusal below the floor; (b) is a knob in disguise.
**Blocks.** Step 1c.

## 87. The boundary directives — `#[client]` decorator, `Name*;`, `#![client]`, or `use client;` / `use server;`

**Raised by:** `00 · 19-use-activation` step 4 ([README § Step 4](./00-compiler-carry-over/19-use-activation/README.md#step-4--the-boundary-directives-question-87)).
**Measured.** Across the specs: `#[client]` 92 occurrences (front 29's decorator), `'use server'` 10
(prose), `#[useCache]` 3 and one proposed `#![useCache]` nobody parses; the parser already has a
module-level activation `Name*;` that inference always rejects. The compiler cannot act on a library
decorator, and a bundler that must split client from server needs a marker the compiler understands.
**Options.** (a) keep the library decorators `#[client]` / `#[server]` / `#[cache]`; (b) `client*;`
on the existing activation form — overloads `*`, which means "opt an extension in"; (c) an inner
attribute `#![client]`, a new production the compiler still ignores; (d) `use client;` /
`use server;` — a module-level `use <target>;` naming which half of the project's target split the
module runs on: library-agnostic because a target is something the compiler already knows; `cache`
is not a target and stays a library decorator.
**Recommendation.** (d) for `client`/`server`, (a) for `cache`; under decision 67 a `use client;`
module may not declare a `#[@External.Erlang]` cell and a `use server;` module may not activate a
hook whose owner is `Element` — refusals, no flag. Until answered the specs keep `#[client]`.
**Blocks.** Nothing in 1.0.10's server fronts; the landing rewrites 29's 5, 26/27/31's 5 and 24's 2 occurrences.

## 88. The `use` lowering on commonJS — React rename, explicit `#[@hook]`, or transparent

**Raised by:** `00 · 19-use-activation` step 5 ([README § Step 5](./00-compiler-carry-over/19-use-activation/README.md#step-5--the-lowering-contract-per-backend-question-88)).
**Measured.** commonJS renames `use <noun>(…)` to `use<Noun>(…)` and appends an inferred deps array for
five hard-coded names (`commonJS.zig:2469-2526`); the renamed identifier is never declared or
imported — `jhonstart-counter/out/main.js` imports `state` and calls `useState(0)`. A hook named by
the rule (`use counter(5)`) emits `useCounter(5)`, a ReferenceError. erlang, wasm and beam lower
`use f(x)` to `f(x)`.
**Options.** (a) transparent on every backend — `use f(x)` → `f(x)`; jhonstart's `state`/`effect`/
`memo` become client-build cells (front 29's split) and keep their pure SSR bodies on the server;
deps are the hook's own argument, never inferred; (b) keep the rename, made explicit by a
`#[@hook("useState")]` annotation that also emits the import; (c) as is.
**Recommendation.** (a) — the only option under which the compiler knows no library, the four
backends agree, and a rule-named hook runs; (c) is a silent ReferenceError, (b) is a knob. `hookName`,
`hookTakesDeps`, `buildHookDeps`, `hook_state` (`commonJS.zig:813-815`, `:2466-2526`) are deleted and
four commonJS snapshots re-record to plain calls.
**Blocks.** jhonstart's client runtime (fronts 29/68) must ship the hooks as cells.

## 89. `use` inside a `#[@future] fn … -> @Future<Element>` body

**Raised by:** `00 · 19-use-activation` step 2 ([README § Step 2](./00-compiler-carry-over/19-use-activation/README.md#step-2--use-inside-future-fn---futureelement)); `language-gaps.md` row 53; front 28.
**Measured.** `contextInfoFromReturn` (`infer.zig:976`) derives a body's owner from its declared return
type; `@Future<Element>` is not `Element`, so a server component cannot activate any hook and
`server.d.bp` stays gated.
**Options.** (a) unwrap the effect — `@Future<T>` (and only `@Future`) yields `T`'s owner, so
`-> @Future<Element>` has owner `Element` and `request()` is declared `-> @Context<Element, Request>`;
(b) the hook owns the future — `-> @Context<@Future<Element>, Request>`, two anchors for one tree,
every server hook redeclared per effect, a client hook refused by an accident of string equality.
**Recommendation.** (a); the strictness it loses (a client hook becomes type-legal in a server
component) is recovered by front 29's client boundary, which is the rule that says which hooks a
server body may activate. (b) invents an anchor that is not a type.
**Blocks.** Step 2 of front 19; front 28's `request()` declaration; `language-gaps.md` row 53.
