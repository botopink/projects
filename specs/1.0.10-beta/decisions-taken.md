# Decisions taken — 1.0.10-beta

Answered by the maintainer, kept here as the record the fronts implement against. The numbering
continues from [1.0.5-beta's record](../1.0.5-beta/decisions-taken.md), which stopped at 67 — a
number is never reused or renumbered across milestones, so a decision cited anywhere under `specs/`
is one decision. Questions are raised in [`decisions-pending.md`](./decisions-pending.md) and move
here when answered.

**Inherited by reference, not copied.** The 1.0.5 record stays where it is; four of its decisions
govern this milestone as standing principles and are cited by number throughout:
[67](../1.0.5-beta/decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it)
(the most restrictive behaviour, and no configuration that bypasses it — every option list below is
written against it),
[62](../1.0.5-beta/decisions-taken.md#62-the-order-of-what-is-left-in-the-milestone) (the order of
what was left, now `00-compiler-carry-over`'s order),
[63](../1.0.5-beta/decisions-taken.md#63-an-index-answers-t-and-an-absent-key-fails-rather-than-answering)
(an index is a method call and an absent key fails — item C-02) and
[66](../1.0.5-beta/decisions-taken.md#66-format---check-looks-at-the-whole-project--and-something-has-to-call-it)
(`format --check` over the whole project — item C-11).

| # | Question | Answer |
|---|---|---|
| [68](#68-one-milestone-the-109-numbers-kept-the-drafts-deleted) | Four spec directories or one? | One — `1.0.10-beta`; 1.0.9's front numbers are kept as directory names; `1.0.6-beta` … `1.0.9-beta` are deleted once the copy is verified |
| [69](#69-every-milestone-carries-a-living-statusmd) | Where does status live? | In `status.md`, and only there — done · in analysis · pending · open, with a rough percentage |
| [70](#70-every-milestone-carries-decisions-pendingmd-and-decisions-takenmd) | Where do questions go? | `decisions-pending.md` → `decisions-taken.md`, in every milestone, numbering continued |
| [71](#71-mocking-lives-in-stdmocks) | Where does the old `onze` mocking surface go? | `libs/std/src/mocks.bp` — one lib-agnostic module |
| [72](#72-the-snap-file-carries-a-header-and-one-slugifier) | `.snap` format and slug rule | Header (`botopink-snap 1` / `test:` / `subject:` / blank / body); the compiler's slugifier for both worlds |
| [73](#73-srcfile-is-package-root-relative-fnname-is-the-test-name) | `@src().file` and `fnName` in a test | Package-root-relative with extension; the test name |
| [74](#74-resultvoid-string-is-real-and-a-propagated-error-fails-the-test) | `@Result<void, string>` and `try` in a test body | Real `void` result; a propagated `error` is FAIL |
| [75](#75-a-workspaces-manifest-npm-style-declares-a-librarys-members) | How `test-libs` and the loader see `modules/**` and `examples/**` | (C) a `workspaces` array in the umbrella `botopink.json`; `{ "workspace": true }` is the only sibling dependency; every refusal structural |
| [76](#76-dependencies-is-the-object-form-only) | `dependencies` shape | Object form only; the string form is a located error |
| [77](#77-renderhooks-keeps-the-dependency-direction) | onze's inverted seams | `RenderHooks` in rakun, filled by `Onze.run`; `islandAttr` in jhonstart; waves from the dependency lines — **amended by 113** |
| [78](#78-the-readme-is-the-contract) | Two jhonstart signatures disagree | The README wins: `renderHead -> string`, `parseActionState(envelope)` |
| [79](#79-the-old-onze-repository-is-tagged-archived-and-re-pointed) | The old `onze` repository | Tag `mocking-lib-final`, archive remotely, re-point the submodule |
| [80](#80-fulltheme-in-emiliabp-owned-by-56) | Who composes the theme | `fullTheme()` in `emilia.bp`, owned by front 56, one `extend` per front |
| [81](#81-important-is-34s-modifier-accentauto-is-a-unit-variant) | `Important` / `accent-auto` | 34 declares `Important(inner)`; `AccentAuto` unit variant |
| [82](#82-dark-mode-is-tailwinds-default-owned-by-54-breakpoints-read-the-theme) | Dark mode / breakpoints | Tailwind v4 default, 54 owns it; 34 reads breakpoints from the theme |
| [83](#83-the-resident-comptime-modules-are-beam-bytes-embedded-at-build-time) | The three resident comptime modules | (c) `.beam` bytes produced by `erlc` at `zig build`, embedded in the compiler |
| [84](#84-the-comptime-runtime-follows-the-targets-vm-beam-by-default) | Default comptime runtime | beam for erlang/beam targets and by default; wat (wasm3) for js/node/wasm targets; server half → beam, client half → wat |
| [85](#85-the-snapshot-tree-is-doubled-as-asked) | Double the snapshot tree? | (a) as asked — `codegen/{beam,wat}/<target>`, pair equality asserted |
| [86](#86-opcodes-pinned-to-otp-28-with-the-stable-subset) | OTP opcode table | (a)+(c): OTP 28's table, the subset stable since OTP 24, refusal below the floor |
| [87](#87-the-boundary-directives-stay-library-decorators--use-never-leaves-a-function-body) | Boundary directives | (a) `#[client]` / `#[server]` / `#[cache]` stay library decorators; `use` is never a module-level directive |
| [88](#88-use-lowers-transparently-and-a-component-is-context-fn---element) | `use` lowering on commonJS | (a) transparent on every backend; **amended:** a component is `#[@Context] fn … -> Element` and `Element` implements the context behavior |
| [89](#89-future-is-unwrapped-for-the-context-owner) | `use` in `-> @Future<Element>` | (a) unwrap `@Future<T>`; `request()` is `-> @Context<Element, Request>` — **revoked by 104** |
| [102](#102-contextbase-is-the-context-owner-marker-only-use-answers-usec-t-or-componentt) | What is `@Context`, and what does a `use` body return? | `@Context<Base>` is the owner marker only (`Element implement @Context<ElementBase>`); `#[@use]` returns `@Use<C, T>` or `@Component<T>` (≡ `@Use<B, T>`); the bare `-> Element` form leaves — **superseded in part by 118, 120 and 121** |
| [103](#103-a-generators-prefix-is-the-level-it-extends-generatort--resultgeneratort-e--futuregeneratort-e) | Generator names, channels, and question 97 | `@Generator<T>` (infallible, 97-b) · `@ResultGenerator<T, E>` · `@FutureGenerator<T, E>`; `YieldStep` the one step; `Iterator`, `Iterable`, `IteratorStep`, `Yield`, `C`, `R` leave — **superseded in part by 118, 121, 122 and 123** |
| [104](#104-only-use-grants-use--decisions-89-and-90-revoked) | Who grants `use`? | Only `#[@use]`; **revokes 89 and 90**; nothing unwrapped; `inContextFn == annotated`; 91 moot, 92 (b), 93 (a); commonJS `async function` for every `#[@use]` — **superseded in part by 118, 120 and 121** |
| [105](#105-three-loop-keywords-and-generator-loop-is-a-generator-scope) | Loops | `loop` / `while (…)` / `for (…) { x -> }`; `#[@generator] loop { … }` is a generator scope worth its wrapper; `yield v` emits, `break v` emits and ends, only there; a plain fn's loops are statements — **superseded in part by 118, 122, 123 and 125** |
| [106](#106-std-in-three-categories-a-pure-root-io-and-testing) | The shape of std | Pure root · `io/` · `testing/`; a root module imports nothing from `io/`; merge only where the name wins (`collections`, `hash`, `encoding`); 71 amended in path only |
| [107](#107-import-a-dotted-path-and-a-braced-group-are-one-tree-and-only-the-leaf-enters-scope) | Import grammar | `import {a: {b: {c}}, x.y.z, e.t.r*}` — dotted path and braced group are one tree; only the leaf enters scope; `*` / `as` on the leaf; no `from` = the package root |
| [108](#108-getcontex--getcontext) | `getContex` | Renamed `getContext` (99-a) |
| [109](#109-a-module-atom-starts-with-its-package-and-the-declaration-boundary-is-) | How is a module, and a per-declaration BEAM module, named? | `<package>@<path>@@<Decl>` — the `botopink.json` `name` first, `@@` before the declaration, whose case is kept (`std@math@@PI`, `myapp@pond@@PatoNada`); A2's `__t__`/`__b__` qualifiers leave; an erlang/BEAM compilation with no `botopink.json` is refused, the compiler's tests compile as package `test` |
| [110](#110-import-aliases-reach-types-and-an-imported-folder-is-a-namespace-of-its-submodules) | `as` on a type; an imported folder | `as` binds a type too (`collections.Dict as D`), a checker-only local name — the emitted identity is unchanged; `import {io}` makes `io.fs.readText(p)` resolve; `as` on a `*` leaf stays refused (amends 107) |
| [111](#111-collections-functions-are-scoped-to-the-type-they-build) | `empty` / `fromList` collide in `collections.bp` | Type-scoped: `Dict.empty()`, `Set.fromList(xs)`, `Queue.empty()`; the one exception to 106's "moves paths, not function names" |
| [112](#112-dsl-hygiene-each-name-resolves-in-the-scope-of-whoever-wrote-it) | In which scope does DSL-generated code resolve names? | Hygiene (5-a): text the lib writes in `e.build` resolves in the lib's module, text from `e.text()` at the call site; `e.lookup(name)` resolves at the call site and returns the declaration's identity, never the alias |
| [113](#113-the-libraries-split-by-concern-emilia-is-css-jhonstart-is-html-rakun-is-the-service-on-erlang-onze-wires-them) | Which library owns what, and who may import whom? | emilia CSS · jhonstart HTML · rakun the service, erlang first · onze wires them; jhonstart ⇄ rakun never import each other; the render and `RenderHooks` move to jhonstart; `ElementView` leaves; markers `data-jh-*`; globals `__bp<N>` from a registry; emilia enters through `jhonstart-emilia`; answers 94, 100, 101; amends 77 — **amended by 115, 116 and 117** |
| [114](#114-the-seams-decision-113-left-open-rakun-routing-an-async-renderplugin-with-a-payload-rakuns-opaque-page-renderer-examples-in-onze-action-names-and-the-request-handed-in-by-onze) | The eight seams 113 left open | (a) on all eight: `rakun-routing` (`["erlang", "commonJS"]`) holds the pure matcher; `RenderPlugin` is asynchronous and gains `payload` (emilia's bridge fills `s`); rakun holds an opaque `PageRenderer` per route over `ChunkWriter`; `LayoutProps` and the UI conventions are jhonstart's; combining examples live in onze; onze passes the action wire names (default `__bp_action` / `X-Bp-Action`) and the `RequestData`; amends 113 — **amended by 115, 116 and 117** — **superseded in part by 120** |
| [115](#115-routing-is-a-bundled-library-a-signal-after-the-first-chunk-is-markup-jhonstart-gains-redirect-rakuns-keys-are-rakun) | The five points 114 left open | (a) on the four: the bundled library `routing` (`libs/routing`, erlang + commonJS, pure) holds the matcher and the `k` / `z` / URL-rule codecs, and rakun and jhonstart import it directly — `rakun-routing` and onze's `match` leave; after the first chunk `notFound` / `redirect` are markup jhonstart's client executes, status 200; jhonstart gains `redirect(url)` and pages import signals and `cookies` from jhonstart; rakun reads `rakun.*` keys only (`rakun.actions.bodyLimit`, `rakun.appDir`); 114's invented names stay; amends 113 and 114 — **amended by 116 and 117** |
| [116](#116-code-two-libraries-both-run-is-neutral-routing-gains-navigation-and-param-actions-and-validation-are-bundled-libraries-std-writes-json) | Nine more pieces two libraries both run | (a) on eight, (b) on validation: `routing` gains `navigation` (the signal vocabulary, neutral `nav:` reasons, the `n` codec) and `pattern` (the `:param` grammar); bundled libraries `actions` (the action envelope, `state` grammar, JSON-RPC body, `refresh`) and `validation` (rakun-validation moved, message lookup injected — rakun has no commonJS member left); std gains `json.quote` / `unquote` / `array` / `object` and `escape.scriptJson`, and `encoding` / `contentHash` replace every private copy; onze configures front 82's static server; amends 113, 114 and 115 — **amended by 117** |
| [117](#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only) | Nine points 113–116 left: who handles a page signal, the late-signal global, the layout form, the action `redirect`, the body limit, front 07, reading JSON, sidecars, rakun's targets | (a) on eight, (b) on front 07: jhonstart handles `redirect` / `notFound` itself over a generic `Response(status, header, write, close)`, server and client-only (`clientApp`) alike, and checks the target (`matchPath`, `allowedRedirects`); onze only adapts rakun's response, whose `ChunkWriter` gains `setStatus` / `setHeader`; rakun keeps `redirect` for actions only; `globals.signal` → `__bp2`; `#[layout]` / `#[page]` / `#[template]` require `#[@use] … -> @Component<Element>`; `OnzeConfig.actionsBodyLimit` (1 MiB); front 07 folded into `01-std-lib-enablement`; std `Json` + `json.decode`; bundled libraries `.bp` only; every rakun manifest `["erlang"]`; amends 113–116 — **superseded in part by 118, 120 and 121** |
| [118](#118-the-return-type-is-the-annotation) | How does a function gain an effect? | By writing the wrapper literally as its return (`@Result`, `@Task`, `@Use`, `@Component`, `@Iterator`, `@Stream`); an alias does not activate; the six effect annotations leave; one return, one effect (R5 by construction); `use` only under `@Use` / `@Component` — supersedes parts of 95, 98, 102–105 and 117 — **amended by 128** |
| [119](#119-what-return-does-in-an-effect-body) | What does `return` do in an effect body? | `T` is wrapped through every layer; a value of any layer passes through the outer ones; an ambiguous nested wrapper asks for `Ok(…)` (`effect-return-ambiguous-nesting`) |
| [120](#120-taskt-replaces-futuret-e-a-task-never-fails) | `@Future<T, E>`? | Replaced by `@Task<T>`, which never fails; `await` answers the value (a `@Result` when there is one), `try await` propagates; the chain is `@Use ⊃ @Task`, `@Result` leaves it; commonJS `async function` for every `@Task` / `@Use` / `@Component` return — **amended by 128** |
| [121](#121-only-result-fails) | Which wrappers fail? | Only `@Result`; `throw` / `try` are legal wherever a layer of the return is a `@Result`; a component handles its errors in its body |
| [122](#122-iteratort-and-streamt-over-yieldstept-for-does-no-implicit-try) | The generators | `@Iterator<T>` (was `@Generator`) and `@Stream<T>` over `YieldStep<T> { Yield, Done }`; `@ResultGenerator` / `@FutureGenerator` leave; a `@Result` item fails per item; `for` does no implicit `try` and iterates any `@Iterator` in any body |
| [123](#123-iterator-or-factory-a-body-that-yields-is-an-iterator) | An `@Iterator` return with no `yield`? | A factory — an ordinary function returning an iterator; mixing `yield` and `return <iterator>` is `iter-mixed-yield-return` |
| [124](#124-the-async-block-is-a-closed-expression-worth-taskt) | A Task inside a function | `async { … }`: a closed block worth `@Task<T>` (`@Task<@Result<U, E>>` when it throws or tries); `return` leaves the block; `async` is contextual |
| [125](#125-iter-and-stream-prefix-a-loop-and-make-it-an-iterator-or-a-stream) | An iterator inside a function | `iter` / `stream` before `loop` / `while` / `for`: a closed expression worth `@Iterator` / `@Stream`, the item `@Result` inferred from `throw` / `try`; replaces `#[@X] loop` |
| [126](#126-a-host-function-returning-taskresultt-e-turns-a-rejection-into-errore) | A host function that can fail | `#[@External…] … -> @Task<@Result<T, E>>` turns a rejection / `{error, …}` into `Error(e)`; `-> @Task<T>` makes a rejection a fatal host failure |
| [127](#127-no-coexistence-the-old-annotations-and-wrappers-are-errors-with-a-fix-it-and-a-codemod) | A compatibility window for the old forms? | None (decision 67): `effect-annotation-removed`, `effect-type-removed`, `iterator-error-param-removed`, each with a fix-it, and the codemod `botopink migrate effects` — **amended by 131** (no codemod) |
| [128](#128-one-context-wrapper-componentc-t) | `@Use<C, T>` and `@Component<T>`? | Unified into one wrapper, `@Component<C, T>`, for hooks and components alike; the base is always written; `@Use` leaves (`effect-type-removed`); a component is the `@Component<C, T>` whose `T` implements `@Context<C>` — amends 102, 104, 117 item 3 and 118–121 |
| [129](#129-type-aliases-four-restrictions-stand-as-reaches-an-imported-alias) | The type-alias details 118 leaves open | A bare generic alias, a parameter default, an annotation and a name taken are refused; `as` is legal on an imported type and alias (110) |
| [130](#130-a-failing-render-carries-e--string-the-writers-stay-infallible) | Which error does a failing render carry? | `renderStream -> @Task<@Result<void, string>>`; `Response.write` / `ChunkWriter.write` stay `@Task<void>`; rakun answers 500 (or closes) and logs under a digest — amends 117 item 1 |
| [131](#131-no-migration-routine-for-the-effect-change) | A codemod for the effect change? | None — `botopink migrate effects` and its migration-only mode leave; the old forms stay errors with a fix-it; `botopink migrate` keeps the module tree — amends 127 |
| [132](#132-the--after-a-braced-block-becomes-an-error-once-every-source-is-migrated) | When is `;` after `}` refused? | After every library and `tests/language` run `c13-migrate.py`; then front 15's patch, narrowed to `isBracedBlockStmt` |
| [133](#133-a-trailing-comma-keeps-a-list-in-its-open-form) | Does a trailing comma still open a list? | Yes — the author's explicit request; amends 65 part 2 |
| [134](#134-every-example-in-the-guide-and-in-docsmd-is-correct-against-the-compiler) | Guide examples that do not type | Fixed in the text; three checker gaps closed by `01-checker`; decision 117's decorator check written in jhonstart |
| [135](#135-specs-keep-only-what-still-holds) | Closed fronts spelling removed forms | Condensed to their current outcome; removed spellings only in the record and the removed-names tables |

## 68. One milestone, the 1.0.9 numbers kept, the drafts deleted

**Decided 2026-09-20 by the maintainer.** The open half of 1.0.5-beta and the whole of 1.0.9-beta
(which had already merged 1.0.6, 1.0.7 and 1.0.8) are one milestone, `1.0.10-beta`, ordered by what
blocks what: std/asserts/`@src()` first, the package restructure second, the four libraries after,
the compiler carry-over beside. Nothing is dropped — the proof is [`unification.md`](./unification.md)
and the per-library `unification.md` files — and a 1.0.9 front keeps its number as its directory
name under the library that owns it (`03-rakun/23-rakun-ssr-pipeline/` is still front 23), so every
cross-reference written in 1.0.9 still resolves.

The four absorbed directories are **deleted** at the end of the consolidation, after a
file-by-file check that every file has a copy here — the maintainer's words: *"pode deletar as
pastas 1.0.6 a 1.0.9 no final"*. Their mapping survives in `unification.md` and in
[`specs/1.0.5-beta/closure.md`](../1.0.5-beta/closure.md).

## 69. Every milestone carries a living `status.md`

**Decided 2026-09-20 by the maintainer:** a per-milestone `status.md`, in English, as a list —
*pending*, *in analysis*, *done*, *open* — with a percentage that need not be exact, always
updated. The convention is in [`specs/__template.md`](../__template.md) and the first instance is
[`status.md`](./status.md). It is the one spec file allowed to carry status; every other file keeps
describing current state and remaining work. It is updated in the same commit as the work it
reflects.

## 70. Every milestone carries `decisions-pending.md` and `decisions-taken.md`

**Decided 2026-09-20 by the maintainer:** the two files 1.0.5-beta kept are part of every
milestone's skeleton, from day one, and the template says so. Numbering continues across
milestones (this record starts at 68 because 1.0.5's stopped at 67). A front that cannot answer a
question from the code writes it in the pending file in the Measured / Options / Recommendation /
Blocks shape rather than guessing; the recommendation defaults to the stricter side (decision 67).

## 71. Mocking lives in `std/mocks`

**Decided 2026-09-20 by the maintainer: (a).** The old `onze` mocking surface (`OnzeStub`, `when`,
`verify`, the `#[mock]` decorator, the `onze.mjs` call-recording state) becomes `libs/std/src/mocks.bp`,
one lib-agnostic module; the sidecar state becomes a node + erlang template pair as `emilia.bp:24`
already does. The `<lib>-test` submodules keep only the injection pairing (`#[mocks.mock]` + `#[bean]`).
No copy per library, no `jhonstart-test → rakun-test` edge. Implements: `01-std` step 4
([`onze-migration.md`](./01-std/onze-migration.md)).

## 72. The `.snap` file carries a header, and one slugifier

**Decided 2026-09-20 by the maintainer: (a).** `botopink-snap 1` / `test: <name>` / `subject:
<helper>` / blank line / body. The slugifier is the compiler's (`codegen/tests/helpers.zig:38`) for
the compiler's snapshots and the libraries' alike. The library `test-snap.md` maps that assumed a
bare body (jhonstart) are re-read against this. Implements: `01-std` step 3
([`snapshots.md`](./01-std/snapshots.md)).

## 73. `@src().file` is package-root-relative; `fnName` is the test name

**Decided 2026-09-20 by the maintainer: (a) and (a).** `file` is the path relative to the package
root, with extension (`test/color_test.bp`) — the only value stable across machines and worktrees
and the only one `snapshots.path(loc)` can turn into a directory beside the test. Inside a `test
"…" {}` block `fnName` is the test name. `column` is the number the diagnostics print (1-based);
confirming it is step 1's acceptance. Implements: `01-std` step 1 ([`src-builtin.md`](./01-std/src-builtin.md)).

## 74. `@Result<void, string>` is real, and a propagated error fails the test

**Decided 2026-09-20 by the maintainer: (a).** An assertion returns `@Result<void, string>` with an
empty `return;` in the `ok` position; a test body is a fallible context in which a propagated
`error` is a FAIL (today `try` inside `__bp_test_N` lowers as `TryForm.propagate`,
`commonJS.zig:615`, and would end the test green). No `i32` sentinel. Implements: `01-std` steps 1–2.

## 75. A `workspaces` manifest, npm-style, declares a library's members

**Decided 2026-09-20 by the maintainer: (C)** — the counter-proposal he asked for (*"implementar algo
parecido com o npm workspaces para bp"*), agreed as written. The umbrella `repository/<lib>/botopink.json`
is a **workspace**, never a package: `"workspaces": ["modules/*", "examples/*"]`, no `src`/`files`/`entry`,
importing it is a located error. Each glob expansion holds a `botopink.json` whose `name` is its import
name (`from "rakun-web"`). `{ "workspace": true }` resolves a dependency to the sibling member by name
and is the **only** way a member depends on a sibling — a `path` to a sibling is a located error, so the
graph is always the workspace's own (the object form of decision 76 gains no second spelling).
`test-libs` and `botopink test` run every member, examples included, and report per member; a member
without `files` ships nothing and fails its own tests; two members with one `name` across roots is a
located error (today first-root-wins, silent). Discovery is one shared function in the runner and the
loader — read the umbrella, expand `workspaces`, treat each expansion as a lib-root entry — instead of
recursion or an environment variable. Details proposed with it and not contradicted: the field is
spelled `workspaces` (npm's name); a workspace may carry `targets` as a default its members inherit and
may only restrict; each `repository/<lib>` is a workspace and the meta-repo is not (it has no manifest),
so the gate iterates the workspaces. Cost: `discovery.zig`, `libs.zig`, `project_graph.zig`,
`bpmp/manifest.zig` learn `workspaces`; `docs/botopink-json.md` documents it; rakun's thirteen
manifests gain `files`. It is a `00 · 10-cli-residuals` carve-out. Implements: `02-packaging` step 1;
routes A/B in its § Mechanism are superseded.

## 76. `dependencies` is the object form only

**Decided 2026-09-20 by the maintainer: (a).** `"dependencies": { "<name>": { "path" | "git", "ref" } }`
is the one shape; every reader (`config.zig`, `bpmp/manifest.zig`, `project_graph.zig`) parses it and
`path` is honoured; the string array is a located error. Both-forms-forever is the configuration
decision 67 refuses. Implements: `02-packaging` step 2; every `examples/<project>/botopink.json`.

One spelling detail: the pin is the existing `branch | tag | rev` (exactly one), not a literal `ref` — bpmp's clone needs the pin's kind, and a second spelling would be the knob decision 67 refuses. `{ "workspace": true }` is the sibling form (decision 75).

## 77. `RenderHooks` keeps the dependency direction

**Decided 2026-09-20 by the maintainer: (a).** rakun (front 23) defines `RenderHooks(headExtra,
islandAttr, …)`; `Onze.run` fills it; `islandAttr` is defined in jhonstart. The three 1.0.9 seams that
reached from rakun/jhonstart into onze are removed, and the onze waves are re-stated from the
`Depends on` lines (`49 → 68 → 69 → 52 → 51 → 70 → 71 → 50 → 53`). Amends the `Owns:` lines of 23 and 29.

**Amended by [113](#113-the-libraries-split-by-concern-emilia-is-css-jhonstart-is-html-rakun-is-the-service-on-erlang-onze-wires-them):** `RenderHooks` moves to jhonstart with the render, and `islandAttr` leaves it.

## 78. The README is the contract

**Decided 2026-09-20 by the maintainer: (a).** `renderHead -> string` (front 32 owns it, front 94
follows); `parseActionState(envelope)` as the front 67 README says, and its example is corrected.
When a README and its example disagree, the example changes.

## 79. The old `onze` repository is tagged, archived and re-pointed

**Decided 2026-09-20 by the maintainer: (a).** The mocking library is tagged `mocking-lib-final` and
archived on the remote; the `repository/onze` submodule entry is re-pointed at the orchestrator's
repository; nothing is vendored. The orchestrator takes the name (decision 68). Implements: `01-std`
step 5; `06-onze/49-onze-stand-up`.

## 80. `fullTheme()` in `emilia.bp`, owned by 56

**Decided 2026-09-20 by the maintainer: (a).** Front 56 owns `fullTheme()`; each front appends one
`.extend(<its>Theme())` line as it lands; an undefined `var(--…)` is a failing snapshot in 56's own
tests, never a silent CSS no-op.

## 81. `Important` is 34's modifier; `AccentAuto` is a unit variant

**Decided 2026-09-20 by the maintainer: (a) and (a).** Front 34 declares `Important(inner: Token[])`
in the modifier section; front 46 gets the unit variant `AccentAuto` beside `Accent(color)`.

## 82. Dark mode is Tailwind's default, owned by 54; breakpoints read the theme

**Decided 2026-09-20 by the maintainer: (a) and (a).** Dark mode follows Tailwind v4
(`prefers-color-scheme`, the class strategy as the documented override), decided in front 54 and
consumed by 34; 34's breakpoint functions read the theme record 54 threads, so a `--breakpoint-*`
override works. A parsed-and-ignored override is the shape decision 67 rules out.

## 83. The resident comptime modules are `.beam` bytes embedded at build time

**Decided 2026-09-20 by the maintainer: (c).** `botopink_comptime_server`, `bp_comptime_template` and
`bp_comptime_decorator` are compiled by `erlc` **at `zig build` time** and embedded in the compiler
binary as bytes; `erlc` becomes a build-time dependency of the compiler and leaves every user's
machine. The bytes are OTP-release-specific and load under decision 86's floor. The `.S`-model route
(b) is not taken now. Implements: `00 · 18-comptime-runtimes` step 1c.

## 84. The comptime runtime follows the target's VM — beam by default

**Decided 2026-09-20 by the maintainer, in his words:** *"`beam` quando o alvo é erlang/beam e
`wasm` quando for js/node/wasmtime, sendo o padrão beam; e quando falamos de service/client: service
beam, client wasm."* So: a build whose target is erlang or beam evaluates comptime on the BEAM
runtime; a build whose target is commonJS, typescript or wasm evaluates it on the WAT runtime (wasm3);
when no target decides, the default is **beam**; in the client/server split of a project, server
modules use beam and client modules use wat. No flag — the runtime is a property of the target
(decision 67). Differs from the recommendation (c) only in the default, which is beam rather than wat.
Implements: `00 · 18-comptime-runtimes` step 3.

## 85. The snapshot tree is doubled as asked

**Decided 2026-09-20 by the maintainer: (a).** `snapshots/codegen/{beam,wat}/{beam,commonJS,erlang,errors,wasm}/`,
the existing files moved into `beam/` by `git mv`, `wat/` recorded once and audited pair by pair, the
harness asserting pair equality. Implements: `00 · 18-comptime-runtimes` step 4.

## 86. Opcodes pinned to OTP 28, with the stable subset

**Decided 2026-09-20 by the maintainer: (a)+(c).** One opcode table (OTP 28, CI's floor), the emitter
restricted to the subset stable since OTP 24, a `beam_lib` validator run in the test, and a clear
refusal below the floor. Implements: `00 · 18-comptime-runtimes` step 1c.

## 87. The boundary directives stay library decorators — `use` never leaves a function body

**Decided 2026-09-20 by the maintainer: (a)**, first written as `[A]` and then confirmed with the
reason, in his words: *"acho que o `use` não deve ser usado para `use client;` / `use server;` fora do
corpo de uma função"*. `use` is the activation keyword inside a body (`val c = use state(0)`,
decision 88) and does not take a second, module-level role; `#[client]`, `#[server]` and `#[cache]`
remain decorators defined by the libraries (front 29 owns `#[client]`), the bundler (front 68) splits
by reading the marker jhonstart emits, and the two refusals — an Erlang cell in a client module, a
client hook in a server module — are the libraries' to implement. Front 19's step 4 closes with no
compiler change; options (b), (c) and (d) are rejected, (d) for the reason quoted.

## 88. `use` lowers transparently, and a component is `#[@Context] fn … -> Element`

**Decided 2026-09-20 by the maintainer: (a), amended.** `use f(x)` lowers to `f(x)` on every backend;
the commonJS React rename and the inferred deps (`hookName`, `hookTakesDeps`, `buildHookDeps`,
`hook_state`, `commonJS.zig:813-815`, `:2466-2526`) are deleted; jhonstart's client runtime provides
`state`/`effect`/`memo` as cells on the client build. **And**, in the maintainer's words: *"deve usar
o `@Context` e o `Element` ter implementado o comportamento para contexto"*:

```bp
#[@Context]
fn Widget() -> Element {
    val c = use state(0);
    val k = use counter(5);
    ...
}
```

A component therefore carries the `#[@Context]` effect annotation on the function, and the owner type
(`Element`) implements the context behavior; a body without the annotation may not activate a hook.
This amends front 19's *rule for libraries* (a component was "any `fn … -> Element`").

The annotation is the lowercase effect `#[@context]` — every effect annotation is lowercase
(`#[@future]` → `@Future`), `#[@Context]` with a capital is an unknown annotation silently ignored,
and no alias is added (decision 67). A body that activates a hook without it is
`use-without-context-effect`. Decision 102 renames the annotation to `#[@use]` and the wrapper to
`@Component<Element>`; the refusal keeps its name.

## 89. `@Future` is unwrapped for the context owner

*Revoked by decision 104 (2026-09-24).*

**Decided 2026-09-20 by the maintainer: (a).** `contextInfoFromReturn` looks through `@Future<T>` (and
only `@Future`) and takes `T`'s owner, so `#[@future] fn … -> @Future<Element>` has owner `Element`
and `request()` is declared `-> @Context<Element, Request>`. A client hook becomes type-legal in a
server component; the client boundary (front 29's `#[client]`, decision 87) is the rule that says
which hooks a server body may activate. Closes `language-gaps.md` row 53.

## 90. A wrapper effect whose return owns a context activates on its own

*Revoked by decision 104 (2026-09-24).*

**Decided 2026-09-21 by the maintainer: (a), scoped to a wrapper effect.** In his words: *"crio que
isso não é necessa já que o element implemente context e o @Context já implemente o comportamento
para future"* — the second annotation says nothing the return type does not already say. A fn that
carries a **wrapper effect** annotation (`#[@future]` today) and whose return type unwraps to a
context owner (decision 89: through `@Future<T>`, to `T`'s owner) may activate hooks **without**
`#[@context]`:

```bp
#[@future]
fn Page() -> @Future<Element> {   // activates: the owner is Element
    val r = use request();
}

#[@context]
fn Widget() -> Element {          // no wrapper effect — the annotation is still required
    val c = use state(0);
}

fn Widget2() -> Element {         // use-without-context-effect
    val c = use state(0);
}
```

What this does **not** change: R5 stands unamended — one effect annotation per fn, and
`#[@future] #[@context]` is still `effect-duplicate-annotation`; option (b) (the wrapper/capability
split of the duplicate rule) and (c) (a combined spelling) are rejected. Decision 88 stands wherever
there is no wrapper effect: a body with **no** effect annotation that activates a hook is still
`use-without-context-effect`, and `#[@context]` on a fn whose return type owns no context is still
`effect-wrapper-mismatch` (decision 67 — the dispensation is not a way to switch a refusal off, it
is the return type answering the same question the annotation would).

The compiler half is front 19 step 2, with 89: `contextInfoFromReturn` looks through `@Future<T>`,
and `FnContext.annotated` (`infer.zig:987`) is set either by `#[@context]` or by a wrapper effect
whose unwrapped return type owns a context. Unblocks front 28's `request()` and every server
component in `04-jhonstart` that reads the request scope.

## 95. The effects are a chain: `@Context` ⊃ `@Future` ⊃ `@Result`, and every effect can fail

**Decided 2026-09-21 by the maintainer.** In his words: *"Future deve implementar o Result e se usar
a anotação `#[future]` poderá resolver tanto try tanto await · `#[context]` resolve tanto try await e
use · e ele `@Context` implementa o Future e o result · o Element implementa `@context`"*. The effect
wrappers are not six unrelated types: they form a subsumption order, a wrapper implements the one
below it, and **the annotation grants every capability at or below its own level**.

| Body | May write | Because the wrapper implements |
|---|---|---|
| `#[@context] fn … -> @Context<B, R>` (or a type implementing it, e.g. `Element`) | `use` · `await` · `try` | `@Context` ⊃ `@Future` ⊃ `@Result` |
| `#[@futureGenerator] fn … -> @FutureGenerator<T, E, C>` | `await` · `try` · `yield` | `@FutureGenerator` ⊃ `@Future` ⊃ `@Result` (decision 98) |
| `#[@future] fn … -> @Future<T, E>` | `await` · `try` | `@Future` ⊃ `@Result` |
| `#[@iterator] fn … -> @Iterator<T, E, C>` | `try` · `yield` | `@Iterator` ⊃ `@Result` |
| `#[@generator] fn … -> @Generator<T, R>` | `yield` · **`try` undecided** | question 97 — it is the one wrapper with no error channel |
| `#[@result] fn … -> @Result<T, E>` | `try` | — it is the base |

*Decisions 102–104 rename the rows: `@Context` → `@Use<C, T>` / `@Component<T>` under `#[@use]`, `@Iterator` → `@ResultGenerator<T, E>` under `#[@resultGenerator]`, `@FutureGenerator` loses `C`, and the generator row is closed by 103 (`@Generator<T>`, infallible).*

The rule that orders them, decided with the table: **every effectful body can fail**, so every
wrapper implements `@Result`; and a wrapper that suspends (`@Context`, `@AsyncGenerator`) implements
`@Future`. `yield` stays exclusive to the three generator wrappers and `use` stays exclusive to
`@Context` — the chain grants downwards, never upwards.

`@Future<T, E = any>` already carries the error channel this needs (`builtins.d.bp:115`, with
`return t` auto-wrapping to `Future.resolved(t)` and `throw e` to `Future.rejected(e)`), so
`@Future<T, E>` implementing `@Result<T, E>` adds no parameter and invents no error type. The same
holds for `@Iterator<T, E = any, C = void>`, whose body already carries `throw`, and for
`@FutureGenerator` under its decision-98 name. `@Generator<T, R>`
(`:109`) is the exception and is **left out of this decision**: it has no error channel, the
maintainer is not yet sure a generator should answer `try`, and the status quo — `throw`/`try` are
not legal in a `#[@generator]` body — stands until question 97 answers it.

What it does **not** change: R5 stands — one effect annotation per fn, and the chain is what makes
that sufficient rather than restrictive, since the highest annotation already grants the rest.
Decision 88 stands: a component is `#[@context] fn … -> Element`, and `Element` implements
`@Context`. Decision 90 stands: a wrapper effect whose unwrapped return owns a context activates
hooks without `#[@context]`, which is the one case the chain cannot spell because R5 forbids writing
two annotations.

Bears on: decision 103 (the generator's row above) and decision 104 (the context-owner unwrap and
the `inContextFn` gate are questions about this chain, not about one type — the body's base is what
decides).
Implements: the `implement` clauses in `libs/std/src/builtins.d.bp`, the `try`/`await`/`use`/`yield`
legality checks in `comptime/infer.zig`, and their refusals — a body that writes a capability above
its level is refused, located, with no flag (decision 67).

**Superseded in part by [118](#118-the-return-type-is-the-annotation), [120](#120-taskt-replaces-futuret-e-a-task-never-fails), [121](#121-only-result-fails) and [122](#122-iteratort-and-streamt-over-yieldstept-for-does-no-implicit-try) (2026-09-26):** the return grants the capabilities, not an annotation (118); the chain is `@Use ⊃ @Task`, with `@Stream ⊃ @Task`, and `@Result` is outside it (120); only `@Result` fails — "every effect can fail" no longer holds (121); the generator rows are `@Iterator<T>` / `@Stream<T>` (122). What stays: the chain grants downwards, never upwards; `use` and `yield` stay exclusive to their wrappers.

## 96. One `ContextBase` per function, and `Element` carries its base

**Decided 2026-09-21 by the maintainer.** In his words: *"todos da mesma função deve usar o mesmo
BaseContext não pode ser usar um BaseElement não se misturaria com um BaseQualquer outro tipo · no
Element deve ter o type base"*. Two rules, one idea — the anchor is a property of the body, not of
each call:

1. **Every `use` in one function resolves against the same `ContextBase`.** Mixing hooks anchored at
   two different bases in one body is refused, even where each `use` is legal on its own. Today
   RC2 asks only that a hook be anchored at a **subtype** of the body's `Base`
   (`builtins.d.bp` § 1C), so two different subtypes can meet in one function and nothing says no.
   The refusal is located at the second `use` and names both bases (decision 67 — no flag).
2. **`Element` carries its base type.** `Element` is its own base today
   (`repository/jhonstart/modules/jhonstart/src/element.bp:8` — `implement @Context<Element, Element>`),
   which makes "the same base" vacuous for every component and gives a library no way to state that
   its hooks belong to one tree and not another. `Element` declares a base type and names it in its
   `implement` clause; the name is jhonstart's to choose, and `@Context<ContextBase, Return>`
   (`builtins.d.bp:177`) is what it fills.

Bears on: decision 88 (a component is `#[@context] fn … -> Element`) is unchanged — what changes is
what `Element`'s first type argument is — the `Base` of decision 102's `@Context<Base>`.
Implements: the RC2 check in `comptime/infer.zig`, `Element`'s declaration in jhonstart, and front
20, which owns the surface both live on.

## 98. One word for suspension: `Future`. The async-generator effect is `#[@futureGenerator]` → `@FutureGenerator`

**Decided 2026-09-21 by the maintainer**, in two passes. He first asked whether `@AsyncGenerator`
made more sense than the `@AsyncIterator` the tree carries — *"fica muito estranho"* — and then, with
that on the table, named the thing underneath it: *"Async Future são duas nomenclaturas para mesma
coisa"*. Both passes are answered by one rename: `#[@asyncGenerator]` becomes
`#[@futureGenerator]` and its wrapper becomes `@FutureGenerator<T, E = any, C = void>`. The shape
does not change (`fn next(self) -> @Future<@IteratorStep<T, E, C>, E>`). *Decision 103 removes the
`C` channel (`@FutureGenerator<T, E>`, `fn next(self) -> @Future<YieldStep<T, E>, E>`) and keeps
the name.*

**What it fixes.** Three things, in the order they were found:

1. **The annotation and its wrapper disagreed.** `builtins.d.bp` states that an effect annotation
   "pairs with the matching return wrapper", and every other pair shares a name — `result`/`Result`,
   `future`/`Future`, `generator`/`Generator`, `iterator`/`Iterator`, `context`/`Context`. Only the
   async generator's did not, and `modules/compiler-core/src/comptime/AGENTS.md` has carried a
   standing *"spelling note for the maintainer"* about it, saying the enforcement uses the spelling
   that exists rather than the one decision 8 § 9's table decided (`@AsyncGenerator<T>`).
2. **The language had two words for one concept.** After fixing (1) with `Async`, suspension would
   be spelled `Future` in one wrapper and `Async` in the other. It is one concept: the value that
   is not here yet, which `await` unwraps. `Future` is the noun the language already chose, so it
   is the one that stays, and `Async` leaves the vocabulary entirely.
3. **`@Async` as a value type reads as an adjective standing in for a noun.** `val x: @Async<i32, string>`
   says less than `val x: @Future<i32, string>`, and `await` reads over a future, not over an async.

**The argument that was withdrawn.** The first pass of this decision also claimed that
`AsyncGenerator` "matches what the value is" because an `async function*` evaluates to an
AsyncGenerator in JavaScript. That reason does not survive: botopink does not use JavaScript's
names anywhere — it is `@Future`, not `Promise`; `@Iterator`, not `IterableIterator` — and
`codegen/typescript.zig` already translates every wrapper at the boundary. A reader coming from JS
does not find `Promise` in botopink source either. Internal consistency decides this, not one
backend's spelling; the TypeScript mapping simply gains one more row
(`@FutureGenerator` → TS's `AsyncGenerator`).

**The runner-up, and why it lost.** `@Stream` / `#[@stream]` is the name Rust and Dart give exactly
this shape (a `next` answering a future of one step), it is one familiar word, and it sidesteps the
adjective problem completely. It is rejected because this milestone ships `std/net` and `std/io`:
"stream" will want to name a flow of bytes, and an effect wrapper colliding with the IO type a user
reaches for costs more than `FutureGenerator` being a name nobody has seen. `FutureGenerator` is at
least derivable — it is a `Generator` whose steps are `Future`s.

**Cost, measured at `cbd5f1ec`:** 127 sites spell `asyncGenerator` and 64 spell `AsyncIterator`
(32 snapshot files among them), across `libs/std/src/builtins.d.bp`, `ast.zig`'s `EffectKind`
(the enum value renames too), `codegen/typescript.zig`'s type mapping, `codegen/wat.zig`'s wrapper
test, the comptime and codegen tests, `docs.md`, and the `comptime/AGENTS.md` note, which goes. The
`typescript.zig` and `wat.zig` edits are name mappings, not lowering changes, and are front 20's one
carve-out from its "touches no `codegen/**`" rule.

**`AsyncIterator` is not re-declared as a protocol** and no `AsyncIterable` is added: nothing needs
them, and unused surface is surface that drifts (decision 67's spirit). Implements: front 20 step 1 (F2).

**Superseded in part by [118](#118-the-return-type-is-the-annotation), [120](#120-taskt-replaces-futuret-e-a-task-never-fails), [122](#122-iteratort-and-streamt-over-yieldstept-for-does-no-implicit-try) and [124](#124-the-async-block-is-a-closed-expression-worth-taskt) (2026-09-26):** the one word for suspension is `Task` (`@Task<T>`, never failing), not `Future`; `#[@futureGenerator]` / `@FutureGenerator` leave for `@Stream<T>` — the runner-up this decision rejected; § 1's annotation ↔ wrapper pairing is moot because the annotations leave; `async` returns as the block keyword `async { }` only. What stays: no JavaScript names in botopink source, the TypeScript mapping as the one place they appear.

## 102. `@Context<Base>` is the context-owner marker only; `#[@use]` answers `@Use<C, T>` or `@Component<T>`

**Decided 2026-09-24 by the maintainer.** `@Context` stops being an effect wrapper and keeps one
role: the marker on the type that carries the context tree, with **one** parameter — the base its
hooks anchor at (decision 96). `pub behavior Context<Base> { }`; jhonstart writes
`pub type Element(…) implement @Context<ElementBase>`, rakun `implement @Context<RequestBase>` (the
name is the library's; the compiler knows neither). The second parameter (`Return`) leaves: it
existed only because one behavior served as both the owner marker and the return wrapper. `Context`
is the right name for the thing that carries the tree, as in React; what lied was using it as the
wrapper of "a function that may `use`". It is the one behavior of the chain a library fills by
`implement`; the others are filled by the compiler from the annotation, and it grants no capability.

The wrappers of `use` are two, because there are two real shapes and each name already exists in
the reader's vocabulary:

- **`@Use<C, T>`** — the return is any `T`; `C` is the **base** the body's `use` anchor at (one base
  per function, decision 96). `pub behavior Use<C, T> extends Future { }`.
- **`@Component<T>`** — the return *is* the context owner: `T: @Context<B>`, and `@Component<T>` ≡
  `@Use<B, T>`, `B` read from `T`'s `implement` clause. It exists so a component does not repeat
  the base its return type already declares. `@Component<X>` with an `X` that implements no
  `@Context` is `effect-wrapper-mismatch`. `pub behavior Component<T> extends Use { }`.

One annotation for both: **`#[@use]`**. The annotation names the capability (this body writes
`use`); the wrapper names the shape. Decision 98 §1 stays intact — `#[@use]` ↔ `@Use` share the
name as the other five pairs do, and `@Component<T>`, the one wrapper that does not repeat its
annotation's name, is sugar for `@Use<B, T>`, not a wrapper with a rule of its own.

```bp
#[@use] fn counter() -> @Use<ElementBase, i32> { val s = use state(0); return s.get(); }
#[@use] fn Page()    -> @Component<Element>     { val n = use counter(); return render(n); }
```

The bare form `-> Element` on an effect body (decisions 88 and 95: "or a type implementing the
wrapper") **leaves**. It was the only exception to "every effect body writes its wrapper", and it is
what produced decisions 89 and 90 and questions 91 and 93 — what is unwrapped to find the owner.
Without the exception the four do not arise; decision 104 closes them. `fn Loading() -> Element`
with no annotation stays an ordinary function.

In the compiler: `EffectKind.use` is the one value whose `returnWrapper` is a **set**
(`{Component, Use}`), and R1/R2 accept either member; `effect_chain.zig` gains one clause per
wrapper (`Use ⊃ Future`, `Component ⊃ Use`). `Self<R, E>` is covariant along the whole chain: `map`
on a `@Use<C, T>` answers `@Use<C, R>`, as on a `@Future<T, E>` it answers `@Future<R, E>`.

What it does **not** change: decision 96 (one base per function, and `Element` carries its base —
`@Context<Base>` is now the parameter that names it). R5 stands: one effect annotation per fn.
`@Future` / `#[@future]`, `@Result` / `#[@result]` and decision 98 are untouched.

Bears on: decision 95's table (its rows are renamed, note under it); decision 104, which follows
from the bare form leaving; decision 88's example, whose `#[@Context] fn Widget() -> Element` is
now spelled `#[@use] fn Widget() -> @Component<Element>`.
Implements: `libs/std/src/builtins.d.bp` (`Context<Base>`, `Use<C, T>`, `Component<T>`;
`Context<B, R>` removed), `ast.zig` (`.context` → `.use`, set-valued `returnWrapper`),
`comptime/effect_chain.zig` (clauses, doc, drift test), `parser/decls.zig` (the annotation name —
`use` is a keyword, so `parseAnnotations` accepts a keyword as an annotation name),
`comptime/infer.zig` (R1/R2 over the set; `@Component<T>` resolving `B` from `T: @Context<B>`),
the `codegen/typescript.zig` and `codegen/wat.zig` name mappings (decision 98's carve-out), and
jhonstart's `element.bp` plus its annotated bodies and wrappers — the `effect-chain` task
(front 21). The `04-jhonstart/**` specs already spell the new surface.

**Superseded in part by [118](#118-the-return-type-is-the-annotation), [120](#120-taskt-replaces-futuret-e-a-task-never-fails) and [121](#121-only-result-fails) (2026-09-26):** the annotation `#[@use]` leaves — `-> @Use<C, T>` / `-> @Component<T>` is itself the grant (118); `Use<C, T>` extends `Task`, not `Future` (120); a hook or component `throw`s / `try`s only when its `T` is a `@Result` (121). What stays: `@Context<Base>` as the owner marker only, the two wrappers, `@Component<T>` ≡ `@Use<B, T>`, the bare `-> Element` form leaving.

## 103. A generator's prefix is the level it extends: `@Generator<T>` · `@ResultGenerator<T, E>` · `@FutureGenerator<T, E>`

**Decided 2026-09-24 by the maintainer.** `Iterator` and `Generator` were two names for "the thing
that `yield`s", with two step enums (`Yield<T, R>`, `IteratorStep<T, E, C>`) for one protocol and
two names (`R`, `C`) for a completion payload nothing in the tree consumes. One protocol, three
wrappers, each named by the chain level it extends — a reader who knows `Future ⊃ Result` derives
the three names without a table:

```
@Generator<T>           (isolated)       yield                     #[@generator]
@ResultGenerator<T, E>  extends Result   yield · try               #[@resultGenerator]   (was @Iterator<T, E, C>)
@FutureGenerator<T, E>  extends Future   yield · await · try       #[@futureGenerator]   (loses C)
```

```bp
pub type YieldStep<T, E = void> { Yield(value: T), Done, Error(error: E) }

pub behavior Generator<T>                                { fn next(self: Self) -> YieldStep<T, void>; }
pub behavior ResultGenerator<T, E = any> extends Result  { fn next(self: Self) -> YieldStep<T, E>; }
pub behavior FutureGenerator<T, E = any> extends Future  { fn next(self: Self) -> Future<YieldStep<T, E>, E>; }
```

`YieldStep<T, E = void>` is the one step enum. `Iterator`, `Iterable`, `IteratorStep`, `Yield<T, R>`
and the `C` and `R` channels leave.

**Question 97 is answered (b): `@Generator<T>` is infallible**, and the argument is the consumer's
side. `for` over a fallible generator is an implicit `try`/`await` — `Error(e)` has to go somewhere,
and the place is the error channel of the body that iterates:

| `for (g) { … }` where `g` is | Legal in |
|---|---|
| `@Generator<T>` | **any body**, a plain `fn` included |
| `@ResultGenerator<T, E>` | a body that grants `try` (≥ `@Result`) — the error propagates as a `try` |
| `@FutureGenerator<T, E>` (`for await`) | a body that grants `await` and `try` (≥ `@Future`) |

Without an infallible wrapper no plain `fn` could iterate any generator — or the error would be
dropped silently, which decision 67 forbids. That is what `@Generator<T>` buys, and it is why it
does not gain `E = any`: `@Generator<i32>` would become fallible by default and the table would lose
its first row. `try`/`throw` in a `#[@generator]` body is refused naming the reason and the wrapper
that has a channel (`` `@Generator` has no error channel; use `@ResultGenerator<T, E>` ``).

**The `C` channel leaves; `break` in a generator carries an item, not a completion.**
`IteratorStep.Done(completion: C)` was the payload of `break <c>` in a `#[@iterator]` body; nothing
consumed it (its one client was the internal `transform.zig → @IteratorStep` of the F4I tail), and
it is the only choice compatible with decision 105's loops. A generator delivers a value in two
ways: `yield v` emits and continues, `break v` emits `v` and ends (≡ `yield v; break;`); a bare
`break` outside any loop ends the generator. The last value is an item like the others; whoever
needs a final value `yield`s it. A generator scope is a `#[@generator]` / `#[@resultGenerator]` /
`#[@futureGenerator]` body — of a `fn` **or of a `loop`** (decision 105).

**`Iterable` leaves.** `Iterable<T, E, C>` ("nothing implements it today") does not return. A type
that wants to be iterated exposes an ordinary method answering a generator, and the consumer calls
it — `for (g.iter())`:

```bp
pub type Grid(cells: i32[]) {
    #[@generator] fn iter(self: Self) -> @Generator<i32> { for (self.cells) { c -> yield c; }; }
}
```

A behavior would only buy the sugar `for (g)`, and surface nobody uses is surface that drifts
(decision 67).

What it does **not** change: the annotation names `#[@generator]` and `#[@futureGenerator]`;
decision 98 (the name `FutureGenerator` stays — only `C` goes, and its shape becomes
`fn next(self) -> @Future<YieldStep<T, E>, E>`); decision 95's rule (the annotation grants every
capability at or below its level; `yield` stays exclusive to the three generators).

Bears on: decision 95's table (the `@Iterator` row is renamed and the generator row is closed);
decision 98's closing asymmetry — front 15's question of two sync wrappers is answered: there are
three generators, differing by level, not by kind; decision 105 (`#[@generator] loop`).
Implements: `libs/std/src/builtins.d.bp` (the behaviors above; `Iterator`, `Iterable`,
`IteratorStep`, `Yield` removed), `ast.zig` (`.iterator` → `.resultGenerator`; `Generator<T, R>` →
`Generator<T>`), `comptime/effect_chain.zig` (`yielding_wrappers`), `comptime/infer.zig`
(`Generator` refuses `try`/`throw`; `break v` in a generator; `for` over a fallible generator
requires the level), the `codegen/typescript.zig` and `codegen/wat.zig` name mappings — the
`effect-chain` task, its first step.

**Superseded in part by [118](#118-the-return-type-is-the-annotation), [121](#121-only-result-fails), [122](#122-iteratort-and-streamt-over-yieldstept-for-does-no-implicit-try) and [123](#123-iterator-or-factory-a-body-that-yields-is-an-iterator) (2026-09-26):** the three generators become `@Iterator<T>` and `@Stream<T>` over `YieldStep<T> { Yield(value: T), Done }` — `@ResultGenerator`, `@FutureGenerator` and the `Error` step leave, a failing item is an `@Result` item (122); the consumer table goes: `for` does no implicit `try` and iterates any `@Iterator` in any body (122); the annotations leave (118); a function returning `@Iterator` without `yield` is a factory (123). What stays: 97 (b) as `@Iterator<T>` infallible, `break v` as an item, `Iterable` / `C` / `R` gone.

## 104. Only `#[@use]` grants `use` — decisions 89 and 90 revoked

**Decided 2026-09-24 by the maintainer.** Decision 90 let `#[@future] fn Page() -> @Future<Element>`
activate hooks with no context annotation, and its own example carries the maintainer's remark that
this should not be possible; decision 89 (`contextInfoFromReturn` looking through `@Future<T>`) is
its mechanism. Both existed because the bare form `-> Element` existed (decision 102) and R5 forbids
two annotations. With `@Component ⊃ @Future`, the case decision 90 served — a server component that
`await`s and `use`s — is covered **by the chain**, and both decisions are revoked:

```bp
#[@future] fn Page() -> @Future<Element>    { use pathname(); }   // refused: @Future grants no `use`
#[@use]    fn Page() -> @Component<Element> { use pathname(); }   // ok — and `await` too
```

The rules:

1. `use` is legal only in a `#[@use]` body. Without the annotation it is
   `use-without-context-effect` (decision 88, unchanged in what it enforces).
2. `use f()` requires `f: @Use<C, _>` with `C` equal to the body's base — the base of a `@Use<C, _>`
   is `C`; that of a `@Component<T>` is the `B` of `T: @Context<B>`. Every `use` in the body shares
   the base (decision 96); the refusal is at the second `use` and names both.
3. A component is **not `use`d**: it is called (`Card()`), as jhonstart already does — `use` takes
   hooks only.
4. Hooks compose: a `@Use<C, _>` may `use` another `@Use<C, _>`.
5. It serves UI (jhonstart, `ElementBase`) and server (rakun, `RequestBase` or whatever the
   library names it); the compiler knows neither.
6. **commonJS emits `async function` for every `#[@use]` body**, whether or not it suspends — as it
   already does for `#[@future]`. Every hook and every component answers a Promise on that target
   and the caller `await`s it. Erlang, wasm and beam do not change: their `@Future` is eager and
   `await` is the identity.

Nothing is unwrapped to find an owner: `contextInfoFromReturn` looks through no wrapper — the base is
`C` of `@Use<C, _>` or the `B` of `T: @Context<B>` in `@Component<T>`. `FnContext.annotated` and
`env.inContextFn` are **one flag**: `inContextFn == annotated`, set by `#[@use]` and by nothing else.

Questions closed with it: **91** is moot (there is no unwrap to widen); **92 is (b)** — only a body
that writes `use` carries the annotation, `fn Loading() -> Element` is a plain function, and the
`04-jhonstart/**` sites annotated as "every component" narrow to the library's reading; **93 is
(a)** — `@getContext` is gated by the same flag as activation, and the diagnostic's hint no longer
asks for an annotation R5 refuses to parse.

What it does **not** change: R5 — one effect annotation per fn, and the chain is what makes it
sufficient; decision 87 (`use` never leaves a function body); decision 88's refusal and its
transparent lowering (`use f(x)` → `f(x)`); decision 96.

Bears on: decision 95's last paragraph ("decision 90 stands") no longer holds — the chain now spells
the case R5 could not; front 28's `request()` and every `04-jhonstart` server component are
`#[@use] fn … -> @Component<Element>` (or `@Use<ElementBase, _>` for a hook).
Implements: `comptime/infer.zig` (`contextInfoFromReturn` without unwrap; `annotated == inContextFn`;
the RC5 hint), `codegen/commonJS.zig` (`fnKeyword`: `.use` → `async function`) — the `effect-chain`
task, in the same step as decision 102 (the two are not separable once the bare form is gone).

**Superseded in part by [118](#118-the-return-type-is-the-annotation), [120](#120-taskt-replaces-futuret-e-a-task-never-fails) and [121](#121-only-result-fails) (2026-09-26):** `use` is granted by a `@Use` / `@Component` return, not by `#[@use]` (118); `@Component ⊃ @Use ⊃ @Task` (120), and commonJS's `async function` keys on a `@Task` / `@Use` / `@Component` return; the chain case keeps `use` and `await`, not `try` (121). What stays: rules 2–5, one flag (`inContextFn == annotated`, now set by the return), and the revocation of 89 and 90.

## 105. Three loop keywords, and `#[@generator] loop` is a generator scope

**Decided 2026-09-24 by the maintainer.** `loop` did three things — collection, condition and
infinite loop in one keyword — with a `break v` that made the loop worth `[v]` and a `yield` that fed
"the loop's array" rather than the function, two semantics nobody remembers (`docs.md:1400`,
`:1014`). Rust and Zig separate them; so does botopink. Three keywords, one semantics each:

| Form | Does | An expression? |
|---|---|---|
| `loop { … }` | repeats until `break` | no (`void`) |
| `#[@generator] loop { … }` | the body is a generator: `yield` / `break v` emit | **yes** — worth `@Generator<T>` |
| `while (cond) { … }` | repeats while `cond` | no (`void`) |
| `for (coll) { x -> … }` | iterates a collection · a range · a generator | no (`void`) |
| `for await (gen) { x -> … }` | iterates a `@FutureGenerator` | no |

`for (xs) { x -> }` is today's `loop (xs) { x -> }` with the keyword swapped; `loop (cond)` becomes
`while (cond)`; `loop await` becomes `for await`. `while` stops being refused
(`removedKeywordWhile`) and `for` stops being an idle lexer keyword. `continue` exists in all three.

**`yield v` and `break v` require a generator scope** — an annotated `fn` or an annotated `loop`.
`yield v` emits and continues; `break v` emits and ends. Outside a generator scope both are refused
naming the three annotations; only bare `break` and `continue` exist, and `loop` / `while` / `for`
are statements (`void`). **Nothing evaluates to `[v]` any more**; `yield` in a plain `fn` is
refused. Whoever wants to collect in a plain `fn` writes `xs.map(…)` / `filter(…)` or accumulates in
a `var`. `yield` inside an unannotated `while` / `for` / `loop` feeds the **nearest** generator
scope (the `fn`, or a `#[@generator] loop` enclosing it). `for` over a fallible generator follows
decision 103: an implicit `try` / `await` that requires the level.

**Ranges.** `a..b` is exclusive, `a...b` inclusive (the token exists in patterns and gains a
literal value here, replacing the per-backend divergence). `start..end` stays an AST node, not a
value: there is **no `Range` value and no `.rev()`** — a countdown is a `while` or `xs.reverse()`.

**`#[@generator] loop` — the loop as a generator.** The generator annotation is valid in two
positions, on a `fn` (as today) and on a `loop`; in both it creates a generator scope with the same
capabilities, and it is the only thing that grants `yield` and `break v`:

```bp
fn main() {
    var i = #[@generator] loop {          // i: @Generator<i32>
        val n = readNumber();
        if (n < 0) { break n; };          // emits n and ends
        yield n * 2;                      // emits and continues
    };
    for (i) { x -> @println(x); };        // @Generator<T> is iterable in any body
}
```

- **The expression is worth the annotation's wrapper:** `#[@generator] loop` is `@Generator<T>`,
  `#[@resultGenerator] loop` is `@ResultGenerator<T, E>`, `#[@futureGenerator] loop` is
  `@FutureGenerator<T, E>`. `T` is the type of the body's `yield` / `break v`; `E` that of its
  `throw`.
- **The body is a generator body:** lazily evaluated, one step per `next`, capturing the enclosing
  scope's variables as a closure. It is implemented by desugaring to a local parameterless
  `#[@generator] fn` called in place — what the backends already emit; what remains is the capture
  of a mutable `var`, which on erlang/beam becomes generator state. A `#[@resultGenerator] loop`
  may `try` / `throw` and a `#[@futureGenerator] loop` may `await` **inside the body** without the
  enclosing `fn` having the level — the error or suspension surfaces only at the consumer, where
  `for` requires it.
- **`yield v` emits and continues; `break v` emits and ends; bare `break` ends** — the semantics of
  a `#[@generator] fn`; an annotated loop is a generator without parameters.
- **Only `loop` takes the annotation.** `#[@generator] for (xs) { … }` does not exist; one writes
  `#[@generator] loop { for (xs) { x -> yield f(x); }; break; }`. One form, not three.
- **Nesting:** `yield` / `break v` feed the **nearest** generator scope; `yield :label` and
  `break :label v` pick another. An unannotated `loop` inside a generator scope is an ordinary
  loop: bare `break` leaves it, `yield` passes through it.
- **An annotated loop is closed.** Its body has **only** its own annotation's capabilities, not the
  enclosing fn's: inside a `#[@use] fn`, a `#[@generator] loop` may neither `use` nor `await` — for
  `await` one writes `#[@futureGenerator] loop`. The body runs later, on demand: a lazy `use` would
  activate a hook outside the render, and an `await` inside a `@Generator<T>` cannot be honoured by
  the type. For the same reason `break :outer` / `continue :outer` crossing an annotated loop's
  border are refused, like leaving a closure.

Today's `loop (xs) { x -> yield … }` (the "loop's array") is exactly this form without saying its
name: `#[@generator] loop { for (xs) { x -> yield …; }; break; }`. The annotation now says what the
loop is, and the result is a real `@Generator<T>`, not an eager list.

**Parentheses stay** — `while (cond) {`, `for (xs) {` — for three reasons: `if (…)` already
requires them, and three control forms under one rule is one rule; botopink has the record literal
`{a: 1}` and the block-with-parameter `{ x -> … }`, so without parentheses `while x {` cannot tell
whether `{` opens the body or a literal, and with them there is no parser rule; and
`for (xs) { x -> }` is `loop (xs) { x -> }` with the keyword swapped. The parameter of `for` is
`{ x -> … }`, the block-with-parameter closures and `loop` already use.

**Labels** extend to `while`, `for` and the annotated `loop` with no change of form: `for :outer (xs)
{ x -> … }`, `break :outer [v]`, `continue :outer`, `yield :out v`, and the label after the return
type of a generator fn (`fn pairs(xs: i32[]) -> @Generator<#(i32, i32)> :out { … }`), which
disambiguates when generators nest.

What it does **not** change: decision 103's three wrappers and their annotations; `try … catch`,
which stays outside the chain — `yield` and `break v` enter it.

Bears on: decision 103 (`break v` as an item; the generator scope of a `loop`); the `loop (` sites
in rakun, jhonstart and the specs (a mechanical rewrite to `for (xs) { x -> }`; rakun's two
`break <value>` sites are reviewed by hand).
Implements: `lexer.zig`, `parser/exprs.zig`, `comptime/infer.zig` and the four codegens (`while` /
`for`; `#[@generator] loop` as a lazy generator expression; `yield` / `break v` gated by generator
scope; labels), `docs.md` — the `loops` task, after `effect-chain`.

**Superseded in part by [118](#118-the-return-type-is-the-annotation), [122](#122-iteratort-and-streamt-over-yieldstept-for-does-no-implicit-try), [123](#123-iterator-or-factory-a-body-that-yields-is-an-iterator) and [125](#125-iter-and-stream-prefix-a-loop-and-make-it-an-iterator-or-a-stream) (2026-09-26):** `#[@generator] loop` / `#[@resultGenerator] loop` / `#[@futureGenerator] loop` become `iter` / `stream` before any of `loop`, `while`, `for` (125); `for await` iterates a `@Stream`, and `for` over a fallible iterator is no implicit `try` (122); a generator scope is a function returning `@Iterator` / `@Stream` that yields (118, 123). What stays: the three keywords, statements `void`, ranges, parentheses, labels, the nearest-scope rule, the closed body.

## 106. std in three categories: a pure root, `io/` and `testing/`

**Decided 2026-09-24 by the maintainer.** One criterion: **`io/` is everything that talks to the
world outside the process.** A module at the root is pure by definition — same input, same output,
no clock, no disk, no network, no entropy — and the rule the compiler checks (decision 67, no flag)
is that **a root module imports nothing from `io/`**. The check applies **inside std** (vacuous
today, because a std module imports no other — `language-gaps.md` — and real the day that closes).
Outside std, `io.` on the import line is a **reading signal** (`grep 'io\.'` lists what a module
touches outside the process), not a guarantee: an external `declare fn` does what it wants.

| Category | Where | Rule |
|---|---|---|
| **pure** | root of `src/` | imports nothing from `io/`; the compiler refuses |
| **io** | `io/` | talks to the world; may import from the root |
| **testing** | `testing/` | the harness: `snapshots` writes to disk, `mocks` records calls — impure by nature, entered only under `botopink test`; may import from `io/` and the root |

`erlang.bp` and `beam.bp` are outside the criterion: they are the target's surface, not domain
modules, and exist only on the erlang/beam targets. Unchanged. The directory is `testing`, not
`test` — `test` is a keyword (`test "…" { }`) and `import {test}` does not parse.

Two rules of shape beside purity:

1. **Merge only where the new name wins.** `dict` + `sets` + `queue` + `order` → `collections`
   wins: the type becomes the namespace (`collections: {Dict, Set}` instead of `dict.Dict,
   sets.Set`), and — since a std module imports no other — only one file lets `Dict.keys()` answer
   `Set<K>`. `crypto` (hashes) + `hmac` + `content_hash` → `hash` wins: hashing is a pure function,
   and `crypto` without `randomBytes` is not "crypto". `base64` + `encoding` → `encoding` wins.
   `json`, `regex`, `unicode`, `string_builder`, `url`, `querystring` have no merge that earns a
   name and stay as they are (`url` and `querystring` both have `parse`; merging would collide).
2. **A directory groups function modules; a file groups types.** `io/` and `testing/` are
   directories because `fs`, `http`, `asserts` are function namespaces and each stays its own file
   (inline tests at the foot, as today). `collections.bp` is a file because `Dict`, `Set`, `Queue`,
   `Order` are types, and the type is already the namespace.

Purity beats domain at the edges: `random` and `crypto.randomBytes` go to `io/random.bp` (entropy
is a side effect); `path` stays at the root minus `absolutePath`, which reads the cwd and goes to
`io/fs.bp`; `time` and front 01's `clock` become `io/clock.bp` (front 01 already chose the name and
the wall/monotonic split); `os`, `env`, `process` stay three files under `io/` (in one `system`
module `env.get` would become `system.get`); `async` (front 02, combinators over `@Future` with no
I/O of its own) and `escape` (front 01, pure string) stay at the root; `snapshots` goes to
`testing/` because it writes files.

```
libs/std/src/
  root.bp              pub mod collections; … pub mod io; pub mod testing;
  primitives.bp  builtins.d.bp  builtins_fns.d.bp        ambient — unchanged

  collections.bp       Dict, Set, Queue, Order          (was dict, sets, queue, order)
  math.bp              (without random)
  path.bp              (without absolutePath)
  url.bp  querystring.bp  json.bp  unicode.bp  regex.bp  string_builder.bp   (unchanged)
  encoding.bp          base64 + encoding                (was base64; encoding from front 01)
  hash.bp              sha256, sha512, md5, hmac, contentHash   (was crypto minus randomBytes; hmac from 01, content_hash from 03)
  escape.bp            (front 01)      async.bp         (front 02)
  erlang.bp  beam.bp   target surface                   (unchanged)

  testing/
    mod.bp             pub mod asserts; pub mod snapshots; pub mod mocks;
    asserts.bp  snapshots.bp  mocks.bp                  (unchanged)

  io/
    mod.bp             pub mod fs; pub mod http; …
    fs.bp              readText, writeText, exists, list, mkdir, rm, absolutePath
    http.bp            (was http)
    net.bp             TCP/TLS sockets                  (front 01, server-only)
    clock.bp           nowMillis, monotonicMillis, measureMillis         (was time; front 01)
    random.bp          coin, bool, intInRange, pick, randomBytes
    os.bp  env.bp  process.bp                           (unchanged)
```

`io/mod.bp` and `testing/mod.bp` are the module system's directory `mod.bp`; `root.bp` gains
`pub mod io;` and `pub mod testing;` and loses the lines of the moved modules. The seven modules
fronts 01/02/03 planned at the root — `net`, `clock`, `encoding`, `hmac`, `escape` (01), `async`
(02), `content_hash` (03) — are absorbed by the tree above.

| Before | After |
|---|---|
| `dict`, `sets`, `queue`, `order` | `collections` (`Dict`, `Set`, `Queue`, `Order`) |
| `random`, `crypto.randomBytes` | `io.random` |
| `crypto` (hashes), `hmac` (01), `content_hash` (03) | `hash` |
| `base64`, `encoding` (01) | `encoding` |
| `math`, `path` (minus `absolutePath`), `json`, `regex`, `unicode`, `string_builder`, `url`, `querystring`, `escape` (01), `async` (02) | unchanged, at the root |
| `path.absolutePath`, `fs` | `io.fs` |
| `http` · `net` (01) | `io.http` · `io.net` |
| `time`, `clock` (01) | `io.clock` |
| `os`, `env`, `process` | `io.os`, `io.env`, `io.process` |
| `asserts`, `snapshots`, `mocks` | `testing.asserts`, `testing.snapshots`, `testing.mocks` |
| `erlang`, `beam` | unchanged |

**Decision 71 is amended in path only.** Since only the leaf enters scope (decision 107),
`import {testing: {mocks}} from "std"` brings `mocks`, and `#[mocks.mock]`, `mocks.when`,
`mocks.verify` stay letter for letter; what 71 fixed — the module's name and its uniqueness — both
stay. One import line changes per `<lib>-test`, and the three test helpers live together in the
category that says what they are.

What it does **not** change: any module's surface beyond the moves named — the gain is not the
line count but `Dict.empty()` beside `Set.empty()` instead of `dict.empty()` beside `sets.empty()`,
every side effect carrying `io.` on its import line, and a pure std module that imports `io.` being
refused at compile time.

Bears on: decision 71 (path); front 01's `net` / `clock` / `encoding` / `hmac` / `escape`, front
02's `async`, front 03's `content_hash` (their files land under this tree); every `import … from
"std"` in rakun, jhonstart, emilia and the `<lib>-test` members.
Implements: `libs/std/src/*`, `root.bp`, `io/mod.bp`, `testing/mod.bp`, the root-imports-no-`io`
check — the `std-purity` task, after front 01 (`01-std-lib-enablement`) and `.tasks/std-async`
merge, because the tree moves their modules.

## 107. Import: a dotted path and a braced group are one tree, and only the leaf enters scope

**Decided 2026-09-24 by the maintainer.** Today `ImportItem := DottedName "*"? ("as" Ident)?`
(`parser/decls.zig:246`): the parser collects `a.b.c` in segments, accepts `*` and accepts `as` — but
`alias` is read by neither `infer.zig` nor any codegen, an item with more than one segment is not
bound (`import {dict.Dict} from "std";` parses and fails resolution with `unknown "std" module in
import`), and the braced form does not parse (`import {dict: {Dict}}` is `unexpected ':'`). The
grammar becomes:

```
ImportDecl := "import" "{" ImportList "}" ("from" String)? ";"
ImportList := ImportItem ("," ImportItem)* ","?
ImportItem := DottedName ("*" | "as" Ident)?        // dotted path — one leaf
            | Ident ":" "{" ImportList "}"          // group — several leaves under one prefix
DottedName := Ident ("." Ident)*
```

Both spellings produce the **same** `ImportPath{segments, activate, alias}` per leaf: `a: {b: {c}}`
is `a.b.c`, and `io: {fs: {readText, writeText}}` is two paths with the prefix `io.fs` written once.
They mix in one list. Without `from`, the list imports from the current package's root (the
`.root` the parser already produces).

```bp
import {a: {b: {c}}, bbb.rr.dd, ee.tt.rr*} from "modulo";
//      └ group ─┘  └ path ──┘  └ path + activation
```

The three ways to bring a name:

```bp
import {collections, io} from "std";                                    // 1. namespace — unchanged
val d = collections.Dict.empty();  val t = io.fs.readText(p);

import {collections.Dict, io.fs.readText, io.clock.nowMillis} from "std";    // 2. dotted path — one leaf per item
val d = Dict.empty();  val t = readText(p);

import {                                                                // 3. group — several leaves, one prefix
    collections: {Dict, Set, ArraySets*},
    io: {fs: {readText, writeText}, clock: {now}},
} from "std";
val d = Dict.empty();  val s = [1, 2].toSet();  val t = readText(p);
```

The rules:

- **2 and 3 are the same tree.** `a.b.c` ≡ `a: {b: {c}}`; a group with one leaf is the dotted path.
  The dot serves one leaf, the braces several under one prefix — there is no formatter rule that
  converts one into the other.
- **Only the leaf enters scope.** `import {io.fs.readText}` brings `readText`, neither `io` nor
  `fs`; `io: {fs: {readText}}` likewise. Whoever wants the namespace and the leaf writes both:
  `import {io, io.fs.readText}` or `import {io, io: {fs: {readText}}}`.
- **An intermediate node may be a leaf:** `import {io.fs}` and `import {io: {fs}}` bring `fs` as a
  namespace (`fs.readText(p)`). Inside a group the prefix itself is a leaf if listed:
  `io: {fs, fs: {readText}}` brings `fs` and `readText`.
- **`*` and `as` belong to the leaf, in both spellings.** `io: {fs: {readText as read}}` ≡
  `io.fs.readText as read`; `collections: {ArraySets*}` ≡ `collections.ArraySets*`. A `*` or `as`
  on a node that opens braces (`io* : {…}`) is a syntax error. `as` is **bound** — today it is
  parsed and ignored.
- **`Name*` activation is unchanged.** An imported `implement` / `extend` enters scope only when
  activated with `*` on the item (it runs on all four backends today); `collections*` — a namespace
  — is `notAnExtension`: each extension is opt-in by name, so the reader sees where `toSet` came
  from.
- **A leaf collision is `import-name-collision`**, located at the second item, in either spelling:
  `import {url.parse, json.parse}` is refused; `import {url.parse as parseUrl, json: {parse as
  parseJson}}` passes.
- **Without `from`, the current package's root:** `import {html: {Element, tag}, router.pathname};`
  inside jhonstart brings the leaves of `pub mod html` and `pub mod router` from the library's own
  `root.bp` — same tree, same rules.
- **It holds for any library.** It is a loader feature (`project_graph.zig` plus the `emitUse` of the
  four codegens), independent of the std reorganisation — which works with form 1 alone.
- **`mod` already gives the tree.** `io.fs` is `pub mod io { pub mod fs; }` in `root.bp` (the
  module system); nothing new in the file resolver. What changes: `parseImportItem` gains the
  `Ident ":" "{" … "}"` branch (recursive, flattening to `ImportPath`s with the prefix), and the
  resolver binds a multi-segment path to its leaf instead of refusing the item.

What it does **not** change: form 1 (a namespace item) and `Name*` activation; the file resolver.
The change is additive.

Bears on: decision 106 (whose tree this grammar reads: `import {io: {fs, env, random}} from "std"`,
`import {testing: {asserts, snapshots, mocks}} from "std"`); decision 71 (`#[mocks.mock]` unchanged
because only the leaf `mocks` enters scope).
Implements: `parser/decls.zig` (`parseImportItem`), `project_graph.zig`, the four codegens'
`emitUse`, `docs.md` — the `std-purity` task.

## 108. `getContex` → `getContext`

**Decided 2026-09-24 by the maintainer: (a)** to question 99. The context-retrieval intrinsic is
renamed `getContext` everywhere it is spelled — `libs/std/src/builtins.d.bp`, `builtins_fns.d.bp`,
`docs.md`, `comptime/stdlib/prelude.zig`, `comptime.zig`, `env.zig`, `infer.zig` — and the two
diagnostic codes (`context-getcontex-outside-context-fn`, `context-getcontex-expects-type`), their
rules RC4/RC5 in `comptime/tests/infer_errors.zig` and the three snapshots whose slug carries the
name move with it. No library spells it today. Its gate is decision 104's one flag.
Implements: the `effect-chain` task, in the same sweep as decisions 102–104.

## 109. A module atom starts with its package, and the declaration boundary is `@@`

**Decided 2026-09-26 by the maintainer**, on his own proposal, in four messages. The boundary:
*"poderia usar `@@` — `io@fs@@File` — quando for um módulo interno"*. The package: *"sempre dever
começar o nome da lib que ta no botopink.json examplo `bp_std@math@@PI`"*, corrected the same day:
*"não precisa ter prefixo"* — the package name as it is, `std@math@@PI`. And the case with no
manifest: refused on erlang and beam, the compiler's tests under an implicit manifest `test`.

Policy 3 (front 13, half 2) emits one BEAM module per `type` and per `implement`, and A2 named that
module by appending a qualifier to the owning module's atom: `main__t__sourcelocation`, with
`__b__` reserved (decision 23). Option A named the file's own module by its path alone, so two
libraries' `main` were one atom and a single-segment `math` needed a `bp@` prefix to stay off OTP's
`math`. Both give way to one rule:

```
atom(module) = sanitise(package) ++ "@" ++ sanitise(path)
               sanitise: lowercase, '/' → '@', [^a-z0-9_@] → '_', a run of '_' → one '_'
atom(decl)   = atom(module) ++ "@@" ++ <Decl>                        (case kept)
```

`package` is the `name` of the `botopink.json` the module was loaded under; `<Decl>` is the
declaration's own name: a `type`'s, or the `val` an `implement` is bound to. A dependency's module
path is already `<dep>/<stem>` — that is how `from "<dep>"` resolves — so its package is not written
twice.

| Package (`botopink.json` `name`) | Source | Atom |
|---|---|---|
| `std` | `pub val PI` in `src/math.bp` → the module | `std@math` |
| `std` | `type File` in `src/io/fs.bp` | `std@io@fs@@File` |
| `myapp` | `type SourceLocation` in `src/main.bp` | `myapp@main@@SourceLocation` |
| `myapp` | the file's own module `src/main.bp` | `myapp@main` |
| `pond_pkg` | `val PatoNada = implement Swimmer for Pato { … }` in `src/pond.bp` | `pond_pkg@pond@@PatoNada` |
| `pond_pkg` | `type Pato(…) implement Swimmer { … }` (inline clause) | `pond_pkg@pond@@Pato` — the clause belongs to the type's module |
| `acme-web` | `src/main.bp` | `acme_web@main` |
| `test` (the compiler's tests, implicit) | `main` | `test@main` |
| none | any module, on erlang or beam | refused: `module main belongs to no package …` |

Five properties decide it:

1. **The package keeps libraries apart and keeps every module off OTP's namespace.** Two
   libraries' `main`, `http` or `root` are two atoms, and every atom holds an `@`, which no OTP
   module name does — option A's `RESERVED` list and its `bp@` prefix for `math`, `dict`, `queue`
   have nothing left to do and are deleted.
2. **`@@` cannot collide.** A path segment is never empty, so `@@` never occurs in `atom(module)`;
   and the sanitiser maps every foreign character to `_`, so no source name can produce `@`. The
   decoder is `split("@@")`, then the module half's first `@` for the package — no qualifier table.
3. **The declaration keeps its case.** A2 lowercased the whole atom, so `SourceLocation` reached
   the BEAM as `sourcelocation` and the atom stopped decoding back to its source.
   `myapp@main@@SourceLocation` is still a legal *unquoted* atom (E10). The module half stays
   lowercase because it is also a file name.
4. **The package must start with a lowercase letter, or it is refused.** The atom starts with it,
   and an atom that does not start with `[a-z]` has to be quoted. Decision 67: `manifest` refuses
   such a `name` (`"name" must start with a lowercase letter`), located at the name, for every tool,
   and `botopink new` refuses it before scaffolding; the renderer refuses it again
   (`invalid_package`) for a driver that did not read a manifest. Nothing is ever quoted.
5. **One rule for every declaration kind.** An `implement` block is named by the `val` that binds it,
   like a `type` by its own name. A behavior module, if decision 23 is ever reopened, is
   `<package>@<path>@@<Behavior>`. Should the language ever nest a declaration inside another, each
   `@@` descends one level; no construct does today.

**Without a `botopink.json` the compilation is refused on erlang and beam** — decided by the
maintainer the same day, the most restrictive reading: a diagnostic, no fallback name, no package
guessed from a directory. The renderer answers `MissingPackage` and `crossModule.build` turns it
into the located `no_package` fault (`module `main` belongs to no package — an erlang module atom
starts with the `name` of the botopink.json it is compiled under, and there is none`). The CLI
already needs a manifest for every command. **The compiler's own tests** compile under an
implicit manifest named `test` — `test@main`, `test@main@@Person` — which only the test harness
supplies (`crossModule.test_packages` on every `codegen/tests/helpers.configs` entry, and the
runtime harness that runs them); a user's run never gets it. The comptime evaluators' modules
live in the compiler's own package, `bp` (`bp@comptime__tpl__<decl>__<hash>`), and `manifest`
refuses `"name": "bp"`, so no package's atoms can meet those. The embedded library `std` is a
dependency of every compilation whether or not the driver lists it, so `std/math` is `std@math`
there too.

What it does **not** change: decision 6's flat `out/erl/` and `out/beam/` (the file is the atom:
`std@io@fs@@File.erl`); decision 21's T2 tag (the same atom is the value's identity on both BEAM
targets — `{'std@io@fs@@File', …}`; commonJS's identity is the class prototype, decision 5, and
wasm's is the descriptor address, decision 22, so neither carries a second spelling); decision 23 (a
behavior emits nothing); the comptime qualifier `__tpl__`/`__dec__` and its hash; commonJS and wasm
artifact paths, which stay the module path. The cross-module refusal that two declarations of one
module must not render one atom stays **case-insensitive**: `Person` and `person` are distinct
atoms but one file on a case-insensitive file system, so the pair is refused (decision 67).

Bears on: every erlang and beam snapshot (`-module(main)` is `-module(test@main)` in the harness);
host templates that spell a tag (`{'std@regex@@Match', …}` in `libs/std`); `tests/language`'s
`language_tests@main` entry; `crossModule.zig`'s `duplicate_decl` check and message;
`13-module-identity`'s A2 text (`declaration-qualifier.md`), which describes this spelling.
Implements: front 13 — `crossModule.erlAtom` / `declAtom` / `decodeAtom` / `Packages`, the erlang
and beam emitters, `Config.packages`, `cli/{build,run,test_cmd,libs,new}.zig`, `manifest`'s
`nameRefusal`, the snapshot re-record, `src/codegen/AGENTS.md`.

## 110. Import aliases reach types, and an imported folder is a namespace of its submodules

**Decided 2026-09-26 by the maintainer**, on the recommended options: *"`as` vale em tipo; pasta
importada vira namespace; … `* as X` continua recusado"*. Three rules amend decision 107's leaf
rules; its grammar is unchanged.

1. **`as` binds a type leaf like any other leaf.** `import {collections.Dict as D} from "std"` and
   `import {collections: {Dict as D}} from "std"` bring `D`. The alias is a local name **in the
   checker only**: the emitted identity is the declaration's own (`std@collections@@Dict`, decision
   109) on every backend, and no codegen sees `D`. Diagnostics and hover name both — `D` = `Dict` —
   so a message about `D` still points at the declaration. The `import-alias-on-type` refusal is
   removed.
2. **An imported folder is a namespace of its submodules.** A leaf that names a directory module
   (`pub mod io { pub mod fs; … }`) brings a namespace whose members are its submodules, so
   `import {io} from "std"; io.fs.readText(p)` resolves. This is decision 107's "dotted and braced
   are one tree" read from the use side: `io.fs.readText` means the same path whether the dots are
   on the import line or in the expression.
3. **`as` on a `*` leaf stays refused** (`import-alias-on-activation`). `Name*` activates every
   extension the item carries; an alias would have nothing to name.

```bp
import {collections.Dict as D, io} from "std";

val d: D<string, i32> = D.empty();        // D is Dict — hover: `D` = `Dict`
val t = io.fs.readText("a.txt");          // folder namespace → submodule → fn

import {collections: {ArraySets* as S}} from "std";
// error[import-alias-on-activation]: `*` activates every name; an alias has nothing to name
```

What it does **not** change: decision 107's grammar, its only-the-leaf-enters-scope rule and
`import-name-collision` (an alias is the leaf that is checked for collision); decision 109's
identity.

Bears on: decision 107 (amended as above); decision 109 (the identity an alias never alters).
Implements: front 23 (`00-compiler-carry-over/23-std-purity`) — `project_graph.zig` (folder leaf
as namespace), `comptime/infer.zig` (type alias as a checker-local name), the hover and diagnostic
renderers.

## 111. `collections` functions are scoped to the type they build

**Decided 2026-09-26 by the maintainer**, on the recommended option: *"`collections` com métodos do
tipo (`Dict.empty()`)"*. Merging `dict`, `sets`, `queue` and `order` into `collections.bp`
(decision 106) collides two names: `empty` (dict, sets, queue) and `fromList` (sets, queue). The
module-level constructors become **type-scoped**: each one is called on the type it builds.

| Before | After |
|---|---|
| `dict.empty()` | `Dict.empty()` |
| `sets.empty()` · `sets.fromList(xs)` | `Set.empty()` · `Set.fromList(xs)` |
| `queue.empty()` · `queue.fromList(xs)` | `Queue.empty()` · `Queue.fromList(xs)` |

```bp
import {collections: {Dict, Set, Queue}} from "std";

val d = Dict.empty();
val s = Set.fromList([1, 2, 3]);
val q = Queue.empty();
```

This is the **one exception** to decision 106's "moves paths, not function names": the name of the
function stays (`empty`, `fromList`), its owner moves from the module to the type. Every other
function of the merged modules keeps its name. If a `Type.fn()` static function does not yet
compile on every backend, making it compile is a step of front 23, not a reason to keep
module-level names.

Bears on: decision 106 (amended as above); every `dict.` / `sets.` / `queue.` call in rakun,
jhonstart, emilia and the `<lib>-test` members.
Implements: front 23 (`00-compiler-carry-over/23-std-purity`) — `libs/std/src/collections.bp`, and
type-scoped static functions on the four backends where they are missing.

## 112. DSL hygiene: each name resolves in the scope of whoever wrote it

**Decided 2026-09-26 by the maintainer: (a)**, with the lookup rule in his words: *"nesse caso
quando usar o e.ref(\"surface\") a lib deve entender que esta falando do area"*. A DSL (a template
returning `@ExprCustom`) produces code text compiled in the caller's module, and that text has two
authors: the library writes the frame in `e.build`, the user writes what is between the quotes
(`e.text()`). Each name resolves in the scope of the author who wrote it:

- **Text the library writes in `e.build` resolves in the library's module** — private names
  included — and carries that declaration's identity, `<lib>@<path>@@<Decl>` (decision 109).
- **Text from `e.text()` resolves at the call site**, like any other code of the consumer's module:
  its imports, its aliases (decision 110), its locals.
- **`e.lookup(name)` resolves at the call site and returns the declaration's identity, never the
  alias.** It is the library's way to ask about the user's names; the library's own names need no
  lookup — writing them in `e.build` is enough.

`e.build` already receives the two parts separately, so the compiler marks each span with its
author; the DSL author writes nothing extra.

```bp
// lib "shapesdsl" — deps/shapesdsl/src/shapesdsl.bp
pub fn area(w: i32, h: i32) -> i32 { return w * h; }

fn double(x: i32) -> i32 { return x * 2; }        // private to the lib

pub default fn shapesdsl<T>(comptime e: @Expr<string>) -> @ExprCustom<T> {
    val code = e.build("double(" + e.text() + ")");   // `double(` … `)` is the lib's text,
    …                                                 // `e.text()` is the user's
    return e.custom(root, code);
}
```

| Consumer | Resolves as | Result |
|---|---|---|
| `import shapesdsl, {area} from "shapesdsl";` `shapesdsl "area(4, 5)"` | `double` → `shapesdsl@shapesdsl@@double` (private, lib scope); `area` → call site | 40 |
| `import shapesdsl, {area as surface} from "shapesdsl";` `shapesdsl "surface(4, 5)"` | `double` → lib; `surface` → call site → `area` | 40 |
| `import shapesdsl, {area} from "shapesdsl";` `fn double(x: i32) -> i32 { return x + 1; }` `shapesdsl "area(4, 5)"` | `double` → lib's, not the consumer's; `area` → call site | 40 |

The first case was `unbound variable 'double'`, the second the same, and the third compiled and
printed 21 — the consumer's `double` silently captured. All three pass with 40.

```bp
// in the lib — "surface" came from e.text(), written by the user
val r = e.lookup("surface");
// r → shapesdsl@shapesdsl@@area — hover, go-to-definition and the CustomNode point at area
```

What it does **not** change: the `@Expr` / `@ExprCustom` surface (`e.build`, `e.text`,
`e.custom`); decision 109's identity; decision 110's alias rule, which `e.lookup` applies.

Bears on: decision 109 (the identity a lib-written name carries); decision 110 (an alias is a
checker-local name, so `e.lookup` returns the declaration); every DSL that calls a private helper
from its `e.build` text (erika, jhonstart's `html`, emilia).
Implements: front 01 (`00-compiler-carry-over/01-checker`) — name resolution by span author in the
generated text, `e.lookup`; front 12 (`00-compiler-carry-over/12-language-tests`) — three `run/`
cells under `tests/language` (private helper, alias, consumer's own `double`), each printing 40; no
`reject/` cell.

## 113. The libraries split by concern: emilia is CSS, jhonstart is HTML, rakun is the service on erlang, onze wires them

**Decided 2026-09-25 by the maintainer**, in his words: *"deveria ser assim emilia lida com css ---
jhonstart com o render de html --- rakun com o serviço --- onze é todas essas libs trabalhando
juntas"*, and for the one that settles most of what follows: *"quem deve ser responsável pelo html é
o jhonstart, ele é uma dependência do onze"*. Measured against the specs, the rule did not hold in
eight places; each is answered below, and questions 94, 100 and 101 close with it.

| Library | Owns | Does not know |
|---|---|---|
| **emilia** | CSS: rules, class names, `flush()` | HTML, streaming, HTTP, jhonstart, rakun, onze — it imports nobody |
| **jhonstart** | HTML rendering: elements, the walker and its escaping, islands, streaming (hole/fill), links, hydration, the client router, and the **render-plugin point** emilia enters through | HTTP, rakun, onze — and emilia, except through the plugin contract, never by name |
| **rakun** | the service, **on erlang (BEAM) first**: HTTP, the route table, actions, route handlers, request/cookies/headers, writing the response (in chunks too) | how the HTML is built, CSS, emilia, jhonstart, onze |
| **onze** | the three together: app boot, bundler, manifest, the generated client entry; registers emilia in jhonstart and wires jhonstart to rakun | — it is the one package that imports all three |

```
onze ──► jhonstart-emilia ──► jhonstart   (the plugin contract only)
  │                      └──► emilia
  ├────► jhonstart
  └────► rakun
```

An arrow is an import. **jhonstart and rakun never import each other** (*"jhonstart e rakun chamando
um ao outro isso não deve ocorrer"*): every link between them goes through onze, which takes a value
from one and hands it to the other — as a parameter, a record of functions, or a line of the
generated entry. **emilia enters jhonstart as a plugin, through a bridge** (*"emilia entra como um
plugin no jhonstart"*; *"ter um jhonstart-emilia que configura o emilia para trabalhar com o
jhonstart"*): jhonstart declares the plugin point and calls it at the right moments, the
`jhonstart-emilia` package adapts emilia to it, onze only registers the plugin at boot, and emilia
knows nobody.

```bp
// onze, at boot — the only package that names jhonstart and rakun together
val site = jhonstart.app(plugins: [jhonstartEmilia.plugin()]);  // CSS enters through the bridge

rakun.page(route, { req ->
    site.renderStream(page(req))                                  // jhonstart builds the HTML
});                                                               // rakun writes the chunks
```

The eight consequences:

1. **The HTML render moves from rakun to jhonstart.** The walker that turns an element tree into
   markup, its escaping, the composition of the segment chain, the document and the payload writer
   leave rakun front 23's `rakun/src/ssr.bp` for `jhonstart/src/render.bp`. rakun keeps the route →
   calls the function onze handed it → writes the chunks, with the request scope and the status.
   `RenderHooks` moves with the render and becomes jhonstart's render-plugin point (item 7); its
   `islandAttr` field leaves, because the package that writes the islands is now the one that
   defines their marker. Amends decision 77.
2. **`ElementView<El>` is deleted from the specs** — question 100. With no walker in rakun there is
   no foreign tree to walk and nothing to adapt; jhonstart walks its own `Element`. No `targets`
   array widens on its account, and no front carries the adapter.
3. **jhonstart and rakun never import each other.** jhonstart's router receives the route table,
   or a `match` function, from onze; front 26's Definition of done reads "the router has no
   matcher and no table parser of its own; it receives `match` from onze". `notFound` in a
   jhonstart page is jhonstart's own signal, which onze translates into rakun's 404 — no jhonstart
   example writes `import {notFound} from "rakun"`.
4. **An HTML marker carries the prefix of the package that writes it.** Every marker jhonstart
   writes is `data-jh-*`: `data-jh-i` (island), `data-jh-s` (server slot), `data-jh-h` / `data-jh-f`
   (hole and fill), `data-jh-l` with `data-jh-prefetch` / `data-jh-replace` / `data-jh-scroll`
   (link), `data-jh-e` / `data-jh-reset` (error boundary), `data-jh-on-click`, `data-jh-a` /
   `data-jh-sf` (forms), and the render's own `data-jh-root` / `data-jh-t` / `data-jh-n`. Only a
   marker onze itself writes keeps `data-onze-*`; the registry in `contracts.md § 2` records, per
   marker, the front and the package that write it.
5. **The CSS of a streamed chunk goes inside its fill** — question 94. jhonstart, rendering a
   boundary, asks the render plugin for that boundary's CSS and writes it inside the fill's
   `<template>`, with no marker of its own:

   ```html
   <template data-jh-f="h1"><style>.e_1a2b3c{…}</style>…the boundary's markup…</template><script>__bp1("h1")</script>
   ```

   The CSS is identified by the fill it sits in, and `data-jh-s` is only the server slot. "CSS
   before the markup, never an unstyled paint" holds by construction: the template's content reaches
   the document when the fill inserts style and markup together. onze takes no part in that moment;
   it only registered the plugin.
6. **A browser global exists only where the HTML names it by text, and its name is generated** —
   question 101. Two values qualify: the payload variable and the fill function the fill's
   `<script>` calls. Each gets an indexed alias `__bp<N>` from a globals registry jhonstart keeps
   (*"esse caso deveria ter um index que é incrementado como alias para não ter esse conflito"*);
   `N` counts up in registration order, and that order is the declaration order in jhonstart, so
   the server build and the client build agree. The render that writes the HTML and the client that
   reads it take the name from the same registry (`globals.payload`, `globals.fill`) and cannot
   diverge; no name is written by hand, so none collides with another script on the page. Link and
   form mount are not globals: they are ordinary imports, `linkMount` and `formMount`. No
   hand-written `__jh*` / `__onze*` global remains — `__onze`, `__onzeFill`, `__jhLinkMount` /
   `__onzeLinkMount` and `__jhFormMount` leave. A host cell (`declare fn` bound by
   `#[@External.…]`) is a module function, not a global, and keeps the `__jh` prefix of its owner.

   ```html
   <script>window.__bp0 = {…payload…}</script>
   <template data-jh-f="h1">…</template><script>__bp1("h1")</script>
   ```

   ```bp
   // generated by onze build — no `__` name written by hand
   import {readPayload, hydrateIsland, registerFill, linkMount, formMount, globals} from "jhonstart";

   pub fn main() {
       val payload = readPayload(globals.payload);   // "__bp0"
       registerFill(globals.fill, payload.h);        // "__bp1"
       linkMount();
       formMount();
   }
   ```

7. **emilia plugs into jhonstart through the bridge package `jhonstart-emilia`**, a member of
   jhonstart's workspace at `repository/jhonstart/modules/jhonstart-emilia` (as `rakun-web` is of
   rakun's), versioned with the contract it implements. jhonstart declares the point; the bridge is
   the only package that knows both; emilia does not change:

   ```bp
   // jhonstart/src/plugin.bp — jhonstart knows the contract only
   pub behavior RenderPlugin {
       fn head(self: Self) -> string;                   // once, after the shell
       fn chunk(self: Self, holeId: string) -> string;  // per boundary, before its markup
       fn close(self: Self) -> @Result<void, string>;   // at the end: nothing may be left
   }

   // jhonstart-emilia/src/root.bp — the bridge
   import {RenderPlugin} from "jhonstart";
   import {flush} from "emilia";
   pub fn plugin() -> RenderPlugin { … }               // head and chunk call flush()

   // onze, at boot
   import {app} from "jhonstart";
   import {plugin as emiliaPlugin} from "jhonstart-emilia";
   val site = app(plugins: [emiliaPlugin()]);
   ```

   The maintainer's sketch writes `pub interface`, `Result<(), string>` and a default import
   (`import jhonstartEmilia from "jhonstart-emilia"`); the spelling above is botopink's —
   `behavior` with `self: Self`, decision 74's `@Result<void, string>`, and decision 107's braced
   import with `as` — not a change of meaning. The two sketches at the top of this decision keep
   the maintainer's `jhonstart.app(…)` / `jhonstartEmilia.plugin()` shape as illustration. Front 69's four sink functions — `openSink`, `collectHead`, `collectChunk`, `closeSink`
   — leave onze. Their ordering rules ("`head` once", "CSS before the markup", "nothing left at
   `close`") become jhonstart's, because jhonstart is the caller; the adaptation to `flush()` is the
   bridge's.
8. **rakun targets erlang** (*"o rakun targets deve ser o erlang principalmente"*). The core member
   `modules/rakun` becomes `"target": "erlang"`, `"targets": ["erlang"]`; `runtime.mjs` and the node
   server leave when rakun front 04 closes — no second runtime with the same semantics to keep.
   `rakun-validation` stays `["erlang", "commonJS"]`, because the same validation runs in the
   client's form and that is a real client/server boundary; `rakun-test` follows the packages it
   tests (erlang); the workspace root becomes `["erlang", "commonJS"]` only to admit that exception.
   erlang comes first in every list and is the default target of `botopink run` / `test` in rakun.
   This also retires question 100's cost of "widening rakun's `targets` to erlang": it is rakun's
   normal state.

What it does **not** change: the payload's key table, the action-id scheme and envelope (contract
3), the class-name scheme (contract 4), the request context (contract 5), the navigation-signal
wire forms (contract 5b), emilia's API. The HTML moves between packages; the bytes each contract
fixes do not, beyond the marker and global names of items 4–6.

Bears on: decision 77 (amended — `RenderHooks` is jhonstart's, `islandAttr` leaves it); questions
94, 100 and 101 (answered by items 5, 2 and 6); `contracts.md` §§ 1, 2, 6 and 6a; rakun fronts 04,
22, 23 and 24; jhonstart fronts 26–31, 67 and 94; onze fronts 49, 53, 68 and 69; each track's
`modules.md` and `test-snap.md`.
Implements: jhonstart front 30 (`render.bp`, `plugin.bp`, `globals.bp`, the marker and global
spellings, and the `jhonstart-emilia` member); rakun fronts 04 and 23 (the erlang core and the
render leaving `ssr.bp`); onze fronts 49, 68 and 69 (the wiring, the entry, the plugin registration).

**Amended by [115](#115-routing-is-a-bundled-library-a-signal-after-the-first-chunk-is-markup-jhonstart-gains-redirect-rakuns-keys-are-rakun):** consequence 3's `match` is no longer handed in by onze — jhonstart's router imports the matcher from the bundled library `routing`.

**Amended by [116](#116-code-two-libraries-both-run-is-neutral-routing-gains-navigation-and-param-actions-and-validation-are-bundled-libraries-std-writes-json):** consequence 8's exception ends — `rakun-validation` leaves rakun for the bundled library `validation`, so rakun's core, every member and the workspace root are `["erlang"]`; the signal reasons consequence 3 has jhonstart raise are `routing`'s `nav:` reasons.

**Amended by [117](#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only):** consequence 3's translation leaves onze — jhonstart turns its own `notFound` / `redirect` into the 404 / 307 on a generic `Response` it writes to, and onze only adapts rakun's response to it.

## 114. The seams decision 113 left open: `rakun-routing`, an async `RenderPlugin` with a payload, rakun's opaque page renderer, examples in onze, action names and the request handed in by onze

**Decided 2026-09-26 by the maintainer**, all eight on the recommended option (a). Applying
decision 113 to the specs left eight places where the rule — *jhonstart and rakun never import each
other; onze wires them; rakun runs on erlang; emilia enters through `jhonstart-emilia`* — did not
settle the shape on its own. Each is answered below. Amends 113.

1. **The route matcher is a boundary module, `rakun-routing`.** rakun's workspace gains
   `repository/rakun/modules/rakun-routing`, `"targets": ["erlang", "commonJS"]` — the second
   exception to rakun's erlang-only core, for the same reason as `rakun-validation`: the same code
   runs on the server and in the browser. It holds **only the pure matcher** — the segment grammar,
   the route table and its wire (contract 1), `matchPath`, `layoutChain` — with no HTTP, no host
   cell and no registry. rakun's server imports it on erlang; onze's generated browser entry imports
   it on commonJS and hands `match` to jhonstart's router. jhonstart imports neither rakun nor
   `rakun-routing`.

   ```bp
   // onze — generated client entry
   import {parseTable, matchPath} from "rakun-routing";
   import {router, readPayload, globals} from "jhonstart";

   val payload = readPayload(globals.payload);
   val table = parseTable(payload.t);
   val r = router(match: { path -> matchPath(table, path) });
   ```

2. **A render plugin contributes to the payload.** `RenderPlugin` gains
   `fn payload(self: Self) -> @Future<?#(string, Json)>`, called once, after `close`; jhonstart
   writes whatever a plugin returns under the key the plugin gives, and a key the render writes
   itself (every key of `contracts.md § 2` but `s`), or given by two plugins, fails the render. The emilia bridge returns
   `#("s", <the class names it flushed>)`, so the payload's `s` key keeps its meaning and the client
   keeps `checkStyles(payload.s)`. The contract stays generic — jhonstart names no key a plugin may
   give. `Json` is the maintainer's word; std has no structured JSON value (the reason contract 1 is
   not JSON), so until it has one front 30 declares `Json` as JSON text the plugin serialised and
   `writePayload` writes verbatim, as it writes `t`, `a` and `b`.
3. **`RenderPlugin`'s methods are asynchronous.** The render is already streaming and `#[@future]`;
   awaiting a plugin is its normal shape, and a later plugin (a font file read, say) may need it too:

   ```bp
   // jhonstart/src/plugin.bp
   pub behavior RenderPlugin {
       fn head(self: Self) -> @Future<string>;                    // once, after the shell
       fn chunk(self: Self, holeId: string) -> @Future<string>;   // per boundary, before its markup
       fn close(self: Self) -> @Future<@Result<void, string>>;    // at the end: nothing may be left
       fn payload(self: Self) -> @Future<?#(string, Json)>;       // once, after close
   }
   ```

   The bridge awaits emilia's `#[@future] flush()` in `head` and `chunk`; emilia does not change.
4. **rakun's page registry holds an opaque renderer per route.** rakun registers a `PageRenderer`
   (item 5) for a pattern and knows nothing else about the page. Layout, page, template, default,
   `Element`, `PageContext` and `LayoutProps` are jhonstart's only: the UI file-convention decorators
   (`#[page]`, `#[layout]`, `#[template]`, `#[defaultView]`), the records a page and a layout
   receive, and the per-route parameter accessors move to jhonstart front 30, beside `Segment` and
   `compose`. `LayoutProps` and `rkAppRegisterPage` over `Element` leave rakun. onze reads
   jhonstart's UI registry at boot, registers each UI record in rakun's route table (so the table the
   server matches and the payload's `t` are still one table, contract 1) and hands rakun one renderer
   per page pattern.
5. **rakun spells the renderer's type, without knowing HTML:**

   ```bp
   // rakun
   pub type ChunkWriter(write: fn(string) -> @Future<void>, close: fn() -> @Future<void>);
   pub type PageRenderer = fn(req: Request, out: ChunkWriter) -> @Future<void>;
   pub fn page(pattern: string, render: PageRenderer) -> i32

   // onze, at boot
   rakun.page(route, fn(req, out) {
       return site.renderStream(page(req), requestData(req), fn(chunk) { return out.write(chunk); });
   });
   ```

   jhonstart receives only a `fn(string) -> @Future<void>` writer and never sees `ChunkWriter`;
   rakun calls the renderer inside the request scope (front 62, phase `Render`) and closes the
   response when the renderer's future resolves. `setPageRender` and `RenderedPage` leave.
6. **An example that combines libraries lives in onze.** Each library's examples and test fixtures
   use that library only: rakun's answer text or JSON, emilia's produce CSS and assert the string.
   Every rakun example that imported jhonstart is an onze example (front 53's application) or is
   deleted where front 53 already shows it; emilia's `integration_test.bp` becomes the
   `jhonstart-emilia` bridge's test, and contract 4's emilia-side literal is asserted by an emilia
   test that renders no HTML. No library carries a dev-dependency on another.
7. **onze passes the server-action wire names to both sides.** jhonstart's form binding (front 67)
   receives `actionField` and `actionHeader`; rakun's action dispatcher (front 24) reads the same two
   values from its configuration (`rakun.actions.field`, `rakun.actions.header`, front 05), which
   onze sets. Neither library spells a name, and rakun with either key unset refuses to start the
   dispatcher, naming the key. onze's defaults are `__bp_action` and `X-Bp-Action`;
   `__onze_action` and `X-Onze-Action` leave.
8. **onze hands the request to the render.** `site.renderStream(page, req: RequestData, write)` —
   jhonstart front 28's `request()`, `headers()` and `cookies()` read from the `RequestData` the
   render received, which onze builds from rakun's `Request`. The `rakun_request_context` host
   binding and the `fillRequest` seam leave jhonstart front 28; jhonstart and rakun share nothing at
   run time either.

```bp
// jhonstart (front 30)
#[@future] pub fn renderStream(self: App, input: PageInput, req: RequestData,
                               write: fn(string) -> @Future<void>) -> @Future<string>
```

What it does **not** change: the route table's wire and precedence (contract 1), the payload's key
table (contract 2), the action id and envelope (contract 3, beyond the two wire names), the
class-name scheme (contract 4), rakun's request context (contract 5), the navigation signals
(contract 5b), emilia's API.

Bears on: decision 113 (amended: item 7's three-method `RenderPlugin` gains `payload` and becomes
asynchronous; item 3's `match` comes from `rakun-routing`; item 8's erlang-only core admits
`rakun-routing` beside `rakun-validation`); `contracts.md` §§ 1, 2, 3, 4 and 6a; rakun fronts 05, 22,
23, 24, 60–66 and 85 and `test-snap*.md`; jhonstart fronts 26, 28, 30 and 67; emilia's README,
`modules.md`, examples and `test-snap*.md`; onze fronts 49, 53, 68 and 69.
Implements: rakun front 22 (`modules/rakun-routing`, the opaque page registry), 23 (`ChunkWriter`,
`PageRenderer`, `page`), 24 (the configured wire names); jhonstart front 28 (`RequestData` handed
in), 30 (the UI conventions, the asynchronous `RenderPlugin` with `payload`, `renderStream`'s
signature, the bridge's `s`), 67 (`actionField` / `actionHeader`); onze fronts 49 (the boot wiring),
53 (the combined examples) and 68 (the entry importing `rakun-routing`).

**Amended by [115](#115-routing-is-a-bundled-library-a-signal-after-the-first-chunk-is-markup-jhonstart-gains-redirect-rakuns-keys-are-rakun):**
item 1's `rakun-routing` member is replaced by the bundled library `routing`, which rakun and
jhonstart import directly; onze no longer hands `match` to the router. Item 7's
`rakun.actions.field` / `.header` are joined by `rakun.actions.bodyLimit` and `rakun.appDir`.

**Amended by [116](#116-code-two-libraries-both-run-is-neutral-routing-gains-navigation-and-param-actions-and-validation-are-bundled-libraries-std-writes-json):** item 7's names still come from onze, and the envelope, the `state` grammar and the JSON-RPC body both sides read and write are the bundled library `actions`; item 1's mention of `rakun-validation` as the other boundary member is void — validation is the bundled library `validation`.

**Amended by [117](#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only):** item 5's `ChunkWriter` gains `setStatus` / `setHeader` (legal before the first `write` only) and a renderer may close it; a navigation reason raised out of a page renderer is an error, not a status. Item 8's `renderStream` takes a jhonstart `Response` in place of the `write` function and answers no reason.

**Superseded in part by [120](#120-taskt-replaces-futuret-e-a-task-never-fails) (2026-09-26):** items 2, 3, 5 and 8 respelled — `@Future<X>` is `@Task<X>` in `RenderPlugin`, `ChunkWriter`, `PageRenderer` and `renderStream`, and `#[@future]` leaves `renderStream` and emilia's `flush()`.

## 115. Routing is a bundled library, a signal after the first chunk is markup, jhonstart gains `redirect`, rakun's keys are `rakun.*`

**Decided 2026-09-26 by the maintainer**, on the recommended option (a) of the four points decision
114 left open, and on the fifth by leaving it as written. On the first he went past the
recommendation — *"pode criar uma lib no repository/botopink-lang/libs para ajudar"* — so the
shared routing code is not a rakun member but a library bundled with the compiler. Amends 113
(consequence 3) and 114 (items 1 and 7).

1. **The routing code server and browser share is the bundled library `routing`.** It lives at
   `repository/botopink-lang/libs/routing/`, beside `libs/std`, and is neutral like std: it names no
   library, speaks no HTTP, keeps no state and declares no host cell. `"targets": ["erlang",
   "commonJS"]`. It holds every piece of routing code that both sides run:

   | Module | Holds | Specified by |
   |---|---|---|
   | `segment` | `SegmentKind`, `Segment`, `parseSegment`, `parsePath`, `patternOf`, `slotOf` | rakun front 22, Step 1 |
   | `table` | `RouteEntry`, `parseTable`, `writeTable`, `kindLabel` — the route table's wire | 22, Step 3; `contracts.md § 1` |
   | `match` | `RouteMatch`, `matchPath`, `layoutChain`, `paramOf` | 22, Step 4 |
   | `route_kinds` | `RouteKind`, `parseKinds`, `writeKinds`, `routeKindOf` — the `k` blob | rakun front 60, Step 6 |
   | `slot_states` | `SlotState`, `parseSlotStates`, `writeSlotStates` — the `z` blob | rakun front 61, Step 5 |
   | `url_rules` | `PathRules`, `canonicalize`, `clientHref`, `RedirectRule`, `parseRedirectTable`, `writeRedirectTable` | rakun front 65, Steps 2–3 |

   rakun (the server) and jhonstart (the browser router and `Link`) both `import {…} from
   "routing"`. A neutral library is not an edge between jhonstart and rakun — 113's rule is that the
   two frameworks never name each other, and `routing` names neither — so the dependency diagram
   gains one node both point at:

   ```
   onze ──► jhonstart ──► routing ◄── rakun ◄── onze
   ```

   onze no longer builds `match` for jhonstart's router: the router imports `parseTable` and
   `matchPath` and reads the table from the payload's `t` itself (front 26). The `rakun-routing`
   member of 114 item 1 does not exist; rakun's erlang-only core keeps one boundary member,
   `rakun-validation`. `from "routing"` resolves the way `from "std"` does — bundled with the
   compiler, never listed in a manifest's `dependencies` (the packaging rule std already has). Module
   atoms follow decision 109: `routing@match`, `routing@match@@RouteMatch`,
   `routing@url_rules@@PathRules`. The library, its embedding and its tests are front
   `01-std/04-routing-lib`; the formats stay specified where they were (fronts 22, 60, 61 and 65),
   and each of those fronts' server half imports the codec rather than owning it.

2. **After the first chunk, a navigation signal is markup and the status stays 200** — as Next.js
   does. Before the render's first `write`, jhonstart's `notFound` / `redirect` leave the render as
   its outcome and onze turns them into rakun's 404 / 307, as 113 and 114 have it. Once a chunk has
   been written the headers are gone, so jhonstart's render writes the signal into the stream as
   markup its own client executes, writes no further fill, and ends; the response closes normally
   with status 200:

   ```html
   <template data-jh-g="redirect" data-jh-to="/login"></template><script>__bp2()</script>
   <template data-jh-g="not-found">…the nearest not-found boundary's markup…</template><script>__bp2()</script>
   ```

   The client navigates with `location.replace` for `redirect`, and for `not-found` replaces the
   content of `data-jh-root` with the template's. `data-jh-g` joins the marker registry
   (`contracts.md § 2`) and `__bp2` is a third global, `globals.signal`, from the same registry as
   `__bp0` / `__bp1` (113 item 6). Because rakun's redirect checks (`contracts.md § 5b`: a relative
   target must match the route table, an absolute one must be in `rakun.navigation.allowedHosts`)
   cannot run once the stream has started, the render applies the stricter half itself: a late
   redirect to a relative target is written only when `routing`'s `matchPath` finds it in the table
   the render was handed, and a late redirect to an absolute target fails the render — decision 67;
   no option writes it anyway.

3. **jhonstart gains `redirect(url)`, a signal like `notFound`** (front 31). It raises the reason
   `jhonstart:redirect:<url>` of `contracts.md § 5b`; onze translates it into rakun's `redirect`
   (307) before the first chunk, and rule 2 applies after it. A page, layout or template — code
   jhonstart's render runs — imports `notFound`, `redirect` and `cookies` from `"jhonstart"` only;
   `cookies` is front 28's reader over the `RequestData` onze hands in (114 item 8). onze front 53's
   pages and examples are written that way. A server action or a route handler is rakun's code and
   keeps rakun's signals (front 63).
4. **rakun reads `rakun.*` keys only.** Front 24's body limit is `rakun.actions.bodyLimit` (default
   1 MiB, floor 4 KiB) and front 22's app directory is `rakun.appDir` (`app` when unset), beside
   114's `rakun.actions.field` / `rakun.actions.header`. onze writes all four into rakun's
   configuration at boot (front 49); no rakun front reads an `onze.` key.
5. **The names 114's sweep chose stay as written** — `rkAppRegisterEntry`, `rkAppRegisterPage<R>`,
   `servePage`, `setImageRenderer`, `PathRules`, `assertPageDispatch`, `jhRegisterPage` and its
   siblings, the `jhonstart_routes` sidecar, `enterRequest` / `leaveRequest`, `Payload.extras`,
   `PageContext.params` / `query` as pair lists, and `formMount(actionHeader)`.

What it does **not** change: the route table's wire and precedence (contract 1), the `k` and `z`
blob formats (fronts 60 and 61), the URL rules (front 65), the signal reasons (contract 5b), the
action id and envelope (contract 3), emilia's API.

Bears on: decision 113 (consequence 3 — `match` is imported, not handed in); decision 114 (item 1
replaced, item 7 extended); `contracts.md` §§ 1, 2, 5b and 6; rakun fronts 04, 22, 23, 24, 60, 61
and 65, the track README and `modules.md`; jhonstart fronts 26, 27, 30 and 31, the track README
and `modules.md`; onze fronts 49, 53 and 68, the track README and `modules.md`; `02-packaging`.
Implements: `01-std/04-routing-lib` (the library, its embedding, its tests); jhonstart front 26
(the router importing `routing`), 30 (the late-signal markup, `globals.signal`), 31 (`redirect`);
rakun fronts 22 (`file_router.bp` importing `routing`, `rakun.appDir`) and 24
(`rakun.actions.bodyLimit`); onze fronts 49 (the four keys at boot) and 53 (the pages' imports).

**Amended by [116](#116-code-two-libraries-both-run-is-neutral-routing-gains-navigation-and-param-actions-and-validation-are-bundled-libraries-std-writes-json):** rule 1's library gains the modules `navigation` (the signal vocabulary and the `n` codec) and `pattern` (the `:param` grammar), and "rakun's erlang-only core keeps one boundary member, `rakun-validation`" ends — validation is the bundled library `validation`; rule 3's reason is `nav:redirect:<url>`, not `jhonstart:redirect:<url>`.

**Amended by [117](#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only):** rule 2's pre-first-chunk translation is jhonstart's, not onze's, and the target check is jhonstart's too — relative through `matchPath`, absolute only when listed in `allowedRedirects`, the same before and after the first chunk; rule 3's `redirect` is never translated by onze, and a server action's `redirect` is rakun's.

## 116. Code two libraries both run is neutral: `routing` gains navigation and `:param`, `actions` and `validation` are bundled libraries, std writes JSON

**Decided 2026-09-26 by the maintainer**, on nine cases where applying decision 115's reasoning
past the matcher found code two libraries — or a server and a browser — both run, written twice or
reached across the 113 line. The criterion was the one 115 set: a bundled library under
`repository/botopink-lang/libs/` only when two or more libraries need the code and 113 keeps it out
of each of them; what is generic goes to std. Eight answers are the recommended option (a); on the
fifth he chose the other one — *"mover a validação para `libs/validation`"* — so validation leaves
rakun instead of staying there on std alone. Amends 113 (consequence 8), 114 (item 7) and 115
(rules 1 and 3).

```
onze ──► jhonstart ──► routing · actions · validation ◄── rakun ◄── onze
              │                                             │
              └──────────────────► std ◄────────────────────┘
```

A bundled library is neutral as `routing` is (115 rule 1): it names no framework, resolves like
`from "std"`, is never listed in a manifest's `dependencies`, and is not an edge between jhonstart
and rakun. `actions` and `validation` join `01-std/04-routing-lib`'s bundled-package list — `std`,
`routing`, `actions`, `validation` — and nothing else changes in how the compiler finds them.

1. **`routing` gains the module `navigation`: the signal vocabulary and its two codecs.** Everything
   about a navigation signal that more than one package reads moves out of rakun front 63 into
   `routing/navigation`, pure like the rest of the library:

   ```bp
   // routing/navigation
   pub type NavKind { None, NotFound, Redirect }
   pub type NavOutcome(kind: NavKind, location: string, status: i32)

   pub fn signalReason(out: NavOutcome) -> string      // the raised reason, below
   pub fn signalFromReason(reason: string) -> NavOutcome // an unknown `nav:` verb raises
   pub fn isSignalReason(reason: string) -> bool
   pub fn signalPrefixes() -> string[]
   pub fn signalToWire(out: NavOutcome) -> string       // "" · "N" · "R|307|/login" · "R|308|/new"
   pub fn signalFromWire(wire: string) -> NavOutcome    // garbage reads as None
   ```

   The reasons take a neutral prefix, because the package that defines them names no framework:

   | Raised by | Reason, literally | Status |
   |---|---|---|
   | `notFound()` | `nav:not-found` | 404 |
   | `redirect(loc)` | `nav:redirect:<loc>` | 307 |
   | `permanentRedirect(loc)` | `nav:permanent-redirect:<loc>` | 308 |
   | `redirectWithStatus(loc, 303)` | `nav:see-other:<loc>` | 303 |

   The `jhonstart:` spellings leave: rakun no longer writes jhonstart's name, and jhonstart's
   `notFound` / `redirect` (front 31, 115 rule 3) raise the same four reasons. What stays in rakun
   front 63 is what only the server does: the throw host cell (`rakun_navigation`), the per-request
   capture (`captureSignals`, `takeSignal`, `peekSignal`), the redirect-target checks and
   `rakun.navigation.allowedHosts`, and the response composition (`statusFor`, `locationHeaderFor`,
   `boundaryFor`). jhonstart imports the vocabulary where it needs it — front 31's boundary matches
   `isSignalReason`, front 26's router reads an action envelope's `n` with `signalFromWire`, front
   30 turns a late signal into markup with `signalFromReason` — and none of them keeps a copy: "the
   browser copy is front 26's file" is gone with the copy.

2. **The server-action protocol is the bundled library `actions`** (`libs/actions`, `"targets":
   ["erlang", "commonJS"]`, erlang first; it imports std and `routing`). It holds every text both
   sides of an action read or write:

   | Module | Holds |
   |---|---|
   | `state` | `ActionState(ok, message, redirectTo, fields)`, `newActionState`, `writeState`, `parseState` — the `state` grammar (`message`, `f.<name>`), percent-encoded by std's `encoding` |
   | `envelope` | `ActionEnvelope` and the v1 envelope `{"v":1,"ok":…,"state":…,"revalidated":[…],"redirect":…,"n":…,"payload":…}`: `writeEnvelope` (`v` first, `redirect` derived from `n` through `routing`'s `signalFromWire`), `flattenEnvelope` (the JSON to its flat querystring form), `readEnvelope`, and `parseActionState(envelope)` (decision 78's name) |
   | `rpc` | `RpcCall(id, args)`, `writeRpcBody`, `parseRpcBody` — the JSON-RPC body `{"v":1,"id":…,"args":[…]}`; an unknown `v` is an `Error` |
   | `refresh` | `refreshValue()` — the header value `refresh` that asks for a re-render with no action |

   It names no field and no header: `actionField` / `actionHeader` still come from onze (114 item 7)
   and are passed to both sides as before. rakun front 24 writes the envelope and reads the RPC body
   with it; jhonstart front 67 reads the envelope and writes the RPC body with it — the scripted
   invocation from an event handler is 67's, built with `writeRpcBody`, and no one else writes that
   body in the browser; jhonstart front 26's `refresh()` sends `refreshValue()`. The golden `state`
   literal "asserted on both sides, in place of sharing a parser between two targets that cannot
   share code" is gone: the parser is shared, and the literal is asserted once, in `libs/actions`, on
   both targets. JSON is read by an inline `#[@External]` template on each target (`JSON.parse` on
   node, `json:decode` on erlang), the way std's `json` reads it — no sidecar file.

3. **std `json` writes JSON.** It gains `json.quote(s)` — a JSON string literal, escaping `"`, `\`
   and **every control character below 0x20** (`\b` `\f` `\n` `\r` `\t` by name, the rest as
   `\u00XX`) — its inverse `json.unquote(s)`, and two small writers over values that are already
   encoded: `json.array(items: Array<string>)` and `json.object(fields: Array<#(string, string)>)`
   (keys quoted by the writer, values written as given). None of rakun's copies escapes a control
   character other than `\n` `\r` `\t`, so each can emit invalid JSON today. All of them are deleted:
   `jsonString` / `jsonStrings` / `jsonPairs` / `jsonTriples` (`rakun/src/ssr.bp:641-676`),
   `rakun-validation`'s `jsonEscape` (`report.bp:80`, which now lives in `libs/validation` and uses
   std), `rakun-web`'s `jsonEscape` (`error.bp:131`), and the hand scanner's string reader
   (`config.bp:394-433`, which also mis-reads `\b`, `\f`, `\/` and `\u`) — the JSON configuration
   reader checks the document with `json.parse` first and reads its string tokens with
   `json.unquote`. The envelope, the RPC body, jhonstart's payload and `RenderPlugin.payload` (114
   item 2) are written with the same functions.

4. **std `encoding` is the one percent and form codec, on both sides** (planned in
   `01-std/01-std-lib-enablement` Step 3: `percentEncode`, `percentDecode`, `formParse`,
   `formStringify`). rakun's `request_context` codec (`request_context.bp:507-610`) and jhonstart's
   `decodePairs` / `encodePairs` (`router.bp:123-162`, marked there as a stand-in) are deleted when
   that front lands. Today the server writes the payload's `m` / `q` percent-encoded and the router
   reads them **undecoded**, so a space arrives as `a%20b`; jhonstart front 26 carries the cell that
   pins the fix — `?q=a%20b` reads `a b`, and `a b` written back reads `q=a%20b`.

5. **Validation is the bundled library `validation`** (`libs/validation`, `"targets": ["erlang",
   "commonJS"]`, erlang first; it imports std and nothing else). It is rakun front 14's
   `modules/rakun-validation`, landed, moved: the constraints and their markers, `#[validated]` and
   the two functions it emits, the constraint SPI, the violation report, the constraint table, typed
   coercion, and the message templates with their interpolation. **The message lookup is injected**:
   the library resolves a template from a `MessageSource` it is handed —

   ```bp
   pub type MessageSource(locale: fn() -> string, template: fn(key: string) -> string)
   pub fn setMessageSource(source: MessageSource) -> i32
   ```

   — trying `<locale>.<code>`, then `<code>`, then the built-in text; with no source set the
   built-in text answers. rakun sets it at boot over its own keys (`rakun.validation.locale`,
   `rakun.validation.messages.*`, unchanged); onze sets the browser's in the entry it generates.
   The library spells no `rakun.` key and imports nothing of rakun's — `messages.bp:22`'s
   `import {rkProp} from "rakun"` is what made the module unbuildable for a browser once rakun's core
   became erlang-only (113 item 8). rakun, onze and application code (the client's form included)
   `import {…} from "validation"`; the `rakun-validation` member is removed from rakun. The boot
   refusal text (`boot.bp` — "rakun config: … will not start", property keys) names rakun's
   configuration and stays rakun's, beside front 05's binder. Its two host tables (the constraint
   registry and the per-request binding accumulator) become inline `#[@External]` templates, so the
   bundled registry keeps embedding `.bp` files only.

   With `rakun-validation` gone, rakun has no member on commonJS: the workspace root is
   `["erlang"]` like every member, and 113 item 8's exception and 115's "one boundary member" end.

6. **onze configures rakun-web's static-file server** (rakun front 82) instead of specifying one.
   onze front 69's `contentTypeOf`, `resolveAsset`, the ETag / `304` rule and the path-traversal
   guard leave its spec: onze hands front 82 its roots, its URL prefix and its cache policy at boot,
   and front 82's content-type table, conditional-request handling and traversal refusal serve them.
   Both run on the server and onze already depends on `rakun-web`, so there is nothing to share —
   only a second copy to delete.

7. **emilia and onze hash with std's `content_hash.contentHash`.** emilia's `hashHex`
   (`emilia.bp:80`, the same djb2 fold std already carries and annotates as a duplicate) is deleted
   and the class-name hash calls std; onze front 68's recomputation of "both folds" calls the same
   function, so contract 4 clause 3 compares one implementation compiled twice. Front 68's build-time
   evaluation of emilia's rules reaches emilia **through a function emilia exports for it** — onze
   imports emilia directly (it is the package that knows all of them, 113) — not through
   `jhonstart-emilia`, which stays the render-plugin bridge only. `06-onze/modules.md` states the
   same import.

8. **std `escape` gains `scriptJson`**: JSON placed inside a `<script>` element, escaping `&`, `<`,
   `>` (as `\u0026`, `\u003c`, `\u003e`) and U+2028 / U+2029 (as `\u2028`, `\u2029`) — the escape a
   payload needs and neither `escape.html` nor `escape.jsString` gives. jhonstart front 30's payload
   writer uses it; its private `payloadEscape` leaves.

9. **`routing` owns the `:param` path grammar too.** rakun-web's third and fourth path grammars —
   the middleware matcher (`middleware.bp:60-110`: a literal segment, `:param`, a trailing
   `:param*`, everything else refused by name) and the CORS preflight's `routeMatches`
   (`filter.bp:545-565`) — become calls into `routing`'s module `pattern`
   (`parsePattern`, `matchPattern`, `patternProblem`), which keeps the refusal. The file-convention
   grammar (`[slug]`, `[...rest]`) and the `:param` grammar stay two grammars — one names files, the
   other is written in code — but both now live in one library and have one test suite.

What it does **not** change: the route table's wire and precedence (contract 1), the payload's key
table (contract 2), the action id and the envelope's keys (contract 3 — only the code that reads and
writes them moves), the class-name scheme (contract 4 — only the function behind it), the request
context (contract 5), the `n` wire forms and the four verbs of contract 5b (only their prefix),
emilia's API, and `actionField` / `actionHeader` coming from onze.

Bears on: decision 113 (consequence 8 — rakun has no commonJS member left); decision 114 (item 7 —
the names still come from onze, the codec is `actions`'); decision 115 (rule 1 — `routing` gains
`navigation` and `pattern`, and "rakun's core keeps one boundary member" ends; rule 3 — the reason
jhonstart's `redirect` raises is `nav:redirect:<url>`); `contracts.md` §§ 2, 3, 4, 5b and 6;
`01-std` (its README, `01-std-lib-enablement`, `04-routing-lib`); rakun fronts 04, 05, 07, 14, 22,
23, 24, 60–66 and 82, the track README, `modules.md` and `test-snap*.md`; jhonstart fronts 26, 28,
30, 31 and 67, the track README and `modules.md`; emilia's `hashHex` fronts (41–48, 56, 59) and
`modules.md`; onze fronts 49, 53, 68 and 69, the track README and `modules.md`; `02-packaging`.
Implements: `01-std/04-routing-lib` (`navigation`, `pattern`), `01-std/05-actions-lib` (the
library), `01-std/06-validation-lib` (the library and the move), `01-std/07-std-json-writers`
(`json.quote` and the writers, `escape.scriptJson`); rakun fronts 14 (the member removed), 24 (the
envelope through `actions`), 63 (the vocabulary imported), 07 (the matcher through `routing`), 23 and
05 (std `json`), 62 (std `encoding`); jhonstart fronts 26 (`signalFromWire`, std `encoding`, the
`a b` cell), 30 (`escape.scriptJson`, the late signal through `signalFromReason`), 31 (the `nav:`
reasons), 67 (`actions`); emilia front 56 (`contentHash`); onze fronts 68 (`contentHash`, emilia's
build-time function) and 69 (front 82 configured).

**Amended by [117](#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only):** rule 2's `actions` reads JSON through std's `json.decode`, not per-target templates; rule 3's configuration reader uses `json.decode`, and the writers are steps of `01-std-lib-enablement` (front 07 folded into it); rule 5's end state is stricter — every rakun manifest, `rakun-test` included, is `["erlang"]`.

## 117. Navigation signals are jhonstart's end to end, pages and layouts are components, std reads JSON, bundled libraries are `.bp` only

**Decided 2026-09-26 by the maintainer**, on nine points left by applying decisions 113–116: seven
on the recommended option (a); on the first he went past the recommendation — *"o tratamento dos
sinais sai do onze e fica todo no jhonstart, funcionando igual com servidor e sem servidor"* — and
on the sixth he chose the other option, folding `01-std/07-std-json-writers` into
`01-std-lib-enablement`. Amends 113 (consequence 3), 114 (items 5 and 8), 115 (rules 2 and 3) and
116 (rules 2, 3 and 5).

1. **A navigation signal is handled entirely inside jhonstart**, the same way with a server (SSR and
   hydration) and without one (a client-only app). onze has no `case` on a signal and rakun knows
   no page signal. A page is the same file in both modes and imports only jhonstart:

   ```bp
   // app/posts/[id]/page.bp
   import {redirect, notFound, Element, PageContext} from "jhonstart";

   #[page]
   #[@use]
   pub fn PostPage(ctx: PageContext) -> @Component<Element> {
       val post = await loadPost(ctx.param("id"));
       if (post == null) { notFound(); }
       if (post.movedTo != "") { redirect("/posts/" + post.movedTo); }
       return article([h1([text(post.title)]), Suspense(fallback: spinner(), children: [Comments(post.id)])]);
   }
   ```

   **The render writes to a generic response and translates the signal itself.** jhonstart
   declares the one output contract its render writes to — status and headers are legal only
   before the first `write`, and a call after it fails the render (decision 67):

   ```bp
   // jhonstart/src/render.bp
   pub type Response(
       status: fn(code: i32) -> void,
       header: fn(name: string, value: string) -> void,
       write:  fn(chunk: string) -> @Future<void>,
       close:  fn() -> @Future<void>,
   );

   #[@future] pub fn renderStream(self: App, input: PageInput, req: RequestData, res: Response) -> @Future<void>
   ```

   | A signal raised | jhonstart writes |
   |---|---|
   | `redirect(to)` before the first chunk | `res.status(307)`, `res.header("location", to)`, `res.close()` |
   | `notFound()` before the first chunk | `res.status(404)`, the route's not-found boundary (front 31) as the document, `res.close()` |
   | either, after the first chunk | the late-signal markup (rule 2), status stays 200, `res.close()` |

   jhonstart calls `res.close()` on every path, once. `renderStream` answers no reason any more: it
   resolves when the response is closed, and a failed render (rule 1's target check, a plugin's
   `close`) is the future's error.

   **Server and client: onze only adapts rakun's response to jhonstart's `Response`.**

   ```bp
   // onze/src/boot.bp
   val ui = jhonstart.app(plugins: [jhonstartEmilia.plugin()], allowedRedirects: config.allowedRedirects);

   rakun.page("/posts/:id", fn(req: Request, out: ChunkWriter) -> @Future<void> {
       return ui.renderStream(input(req), requestData(req), Response(
           status: fn(c) { out.setStatus(c); },
           header: fn(n, v) { out.setHeader(n, v); },
           write:  fn(chunk) { return out.write(chunk); },
           close:  fn() { return out.close(); },
       ));
   });
   ```

   **Client only: `clientApp(routes, mount).start()`.** The same page runs in the browser under
   jhonstart's router, which catches the signal and acts alone:

   ```bp
   import {clientApp} from "jhonstart";

   clientApp(routes: routeTable, mount: "#root", allowedRedirects: []).start();
   //  notFound()      → renders the route's not-found boundary (front 31); the URL does not change
   //  redirect("/x")  → history.replaceState and a client navigation to /x, no reload
   ```

   **The redirect target is checked by jhonstart**, since jhonstart now writes the 307: a relative
   target must be found by `routing`'s `matchPath` in the route table (`PageInput.table` on the
   server, `clientApp`'s `routes` in the browser); an absolute target is accepted only when it is
   listed in `jhonstart.app(allowedRedirects: [...])` — `clientApp` takes the same list — and with
   the list empty (its default) every absolute target is refused. In an onze application the list is
   `OnzeConfig.allowedRedirects` (default empty), which onze hands to `app` at boot and writes into
   the entry it generates for the browser. Anything else fails the render.
   The check is the same before and after the first chunk, so a late absolute redirect is written
   when it is listed rather than always failing (115 rule 2's stricter half, now satisfiable).

   **rakun loses page-level `redirect` / `notFound`.** Its response gains `setStatus` and `setHeader`
   — 114's `ChunkWriter`, amended; the maintainer's sketch spells it `HttpResponse`, the name kept is
   114's:

   ```bp
   // rakun (front 23)
   pub type ChunkWriter(setStatus: fn(code: i32) -> void, setHeader: fn(name: string, value: string) -> void,
                        write: fn(string) -> @Future<void>, close: fn() -> @Future<void>);
   ```

   `setStatus` / `setHeader` after the first `write` fail the request, naming the call. A page
   renderer that closes the response is normal; the dispatch closes it only when the renderer's
   future resolves with it still open, and any call after `close` fails the request. A navigation
   reason raised out of a page renderer is not translated: it is an error of that request (500),
   because page signals are jhonstart's. rakun's `notFound` / `redirect` / `permanentRedirect` /
   `redirectWithStatus` stay for server actions (rule 4) and route handlers (front 25), with their
   checks against `rakun.navigation.allowedHosts`; `boundaryFor` and every page-signal path leave
   front 63.

2. **The late signal calls a third registry global.** `globals.bp` declares, after `payload` and
   `fill`, `pub val signal = alias("signal")` — `__bp2` — and the markup is:

   ```html
   <template data-jh-g="redirect" data-jh-to="/posts/99"></template><script>__bp2()</script>
   <template data-jh-g="not-found">…the nearest not-found boundary's markup…</template><script>__bp2()</script>
   ```

   Each global does one thing; the fill keeps one meaning. The client's `__bp2` performs rule 1's
   client-only behaviour.

3. **`#[layout]`, `#[page]` and `#[template]` require `#[@use] fn … -> @Component<Element>`**
   (decision 102). A layout, a page and a template are components: they may `await` and `use`
   hooks. `use cookies()` and the other request hooks read the `RequestData` the render was handed
   (114 item 8). A signal raised in a layout behaves as one raised in a page; the layout renders
   before the page, so a signal a layout raises before the first chunk means the page never runs:

   ```bp
   import {redirect, cookies, Element, LayoutProps} from "jhonstart";

   #[layout]
   #[@use]
   pub fn DashboardLayout(props: LayoutProps) -> @Component<Element> {
       val jar = use cookies();
       if (jar.get("session") == null) { redirect("/login"); }
       return div([Sidebar(), props.children]);
   }
   ```

   `fn(props) -> Element` without `#[@use]` under one of the three markers is a compile error raised
   by the marker, naming the function and the form it needs — no plain-layout escape (decision 67).

4. **A server action uses rakun's `redirect`.** An action runs inside rakun's action pipeline
   (front 24), with no render and no `Response`; its `redirect(loc)` is rakun's, and rakun writes
   the target into the `actions` envelope's `n` with `routing/navigation`'s `signalToWire`
   (`"R|303|/posts/7"`). jhonstart's client reads `n` with `signalFromWire` and navigates. Nobody
   imports anybody: page `redirect` is jhonstart's, action `redirect` is rakun's.

5. **`OnzeConfig.actionsBodyLimit`, default 1048576 (1 MiB).** The application sets it on onze;
   onze writes `rakun.actions.bodyLimit` at boot (beside 115 rule 4's keys); rakun front 24 reads
   its own key and answers 413 above it. jhonstart takes no part.

6. **`01-std/07-std-json-writers` is folded into `01-std/01-std-lib-enablement`.** Its steps —
   `json.quote` / `unquote` / `array` / `object` and `escape.scriptJson` — become steps of 01's
   README, appended at its end; the 07 directory is deleted and every reference points at 01.

7. **std gains a structured JSON reader.**

   ```bp
   pub type Json { Null, Bool(bool), Num(f64), Str(string), Arr(Array<Json>), Obj(Array<#(string, Json)>) }
   pub fn decode(s: string) -> @Result<Json, string>
   ```

   A step of `01-std-lib-enablement`, beside the folded writers. rakun's configuration reader
   (front 05), the `actions` library's envelope and RPC readers and jhonstart's payload reader all
   read through `json.decode`; the `json.parse` + `json.unquote` hand slicing leaves, and so do the
   per-target `JSON.parse` / `json:decode` templates 116 rule 2 gave `actions`.

8. **Bundled libraries ship `.bp` files only.** `routing`, `actions` and `validation` carry no
   `.erl` / `.mjs` sidecar under `libs/`; target-native code is an inline `#[@External]` template in
   the `.bp` file, as std's is. If something cannot be expressed inline, the front stops and raises
   it in `decisions-pending.md` rather than adding a sidecar.

9. **Every rakun manifest is `["erlang"]`**, `rakun-test` included — no member of rakun is on
   commonJS.

What it does **not** change: the four `nav:` reasons and the `n` wire forms (contract 5b), the
route table's wire (contract 1), the payload keys (contract 2, beyond reading it with
`json.decode`), the action id and envelope keys (contract 3), the marker registry's existing
entries, emilia's API, `actionField` / `actionHeader` from onze.

Bears on: decision 113 (consequence 3 — onze translates nothing); decision 114 (item 5 —
`ChunkWriter` gains `setStatus` / `setHeader` and a renderer may close; item 8 — `renderStream`
takes a `Response`); decision 115 (rule 2 — jhonstart turns the pre-first-chunk signal into 404 /
307 itself and checks the target against the table and `allowedRedirects`; rule 3 — onze no longer
translates `redirect`); decision 116 (rule 2 — `actions` reads JSON with `json.decode`; rule 3 — the
configuration reader uses `json.decode`, and front 07 is part of `01-std-lib-enablement`; rule 5 —
rakun has no commonJS manifest at all); `contracts.md` §§ 2, 3, 5b and 6a; `01-std` (its README,
`01-std-lib-enablement`, `04-routing-lib`, `05-actions-lib`, `06-validation-lib`); rakun fronts 05,
22, 23, 24 and 63; jhonstart fronts 26, 30 and 31; onze fronts 49 and 53; `fronts.md`,
`overview.md`, `status.md`.
Implements: `01-std/01-std-lib-enablement` (the folded writers, `Json`, `json.decode`); jhonstart
fronts 30 (`Response`, `renderStream` over it, `globals.signal`, the target check, the three markers'
refusal), 26 (`clientApp`, the client half of the signals) and 31 (the not-found boundary as a
404 document); rakun fronts 23 (`setStatus` / `setHeader`, a renderer's signal is an error), 63
(page signals leave), 24 (`redirect` into `n`) and 05 (`json.decode`); onze fronts 49 (the
`Response` adapter, `actionsBodyLimit`, `allowedRedirects`) and 53 (every page, layout and template
a component).

**Superseded in part by [118](#118-the-return-type-is-the-annotation), [120](#120-taskt-replaces-futuret-e-a-task-never-fails) and [121](#121-only-result-fails) (2026-09-26):** item 3's markers require `-> @Component<Element>` with no `#[@use]` (118); item 1's `Response`, `ChunkWriter` and boot closure are `@Task<void>`, `renderStream` loses `#[@future]` (120); item 1's page handles a failed load in its body (`try await loadPost(…) catch null`), and "a failed render is the future's error" has no home until `renderStream`'s `@Result` is decided (121 — front 24 step E7).

## 118. The return type is the annotation

**Decided 2026-09-26 by the maintainer** (D-A of the effect revision), in his words: *"Não existe
anotação: o retorno é a anotação."* An ordinary function may not fail, wait, use hooks or produce a
sequence. It gains one of those capabilities by writing the effect wrapper, literally, as its return
type, and by nothing else:

| Return | The body may write |
|---|---|
| `T` | only `try … catch` (the error is handled on the spot) |
| `@Result<T, E>` | `throw` · `try` |
| `@Task<T>` | `await` |
| `@Use<C, T>` or `@Component<T>` | `use` · `await` |
| `@Iterator<T>` | `yield` · `break v` |
| `@Stream<T>` | `yield` · `break v` · `await` |

`throw` and `try` are also legal in `@Task`, `@Use`, `@Iterator` and `@Stream` when the value (or the
item) is a `@Result<U, E>` — decision 121.

```bp
pub fn parsePort(s: string) -> @Result<i32, ParseError> {
    if (s == "") { throw ParseError.Empty; };
    val n = try toInt(s);                 // if toInt fails, the error propagates from here
    if (n > 65535) { throw ParseError.TooBig(value: n); };
    return n;                              // becomes Ok(n)
}
```

The rules:

1. **The wrapper must be written in the return.** `-> @Task<User>` activates the effect; an alias
   (`type Job<T> = @Task<T>`) does **not** — whoever reads the signature has to see the `@`. The
   alias is resolved to type the function, never to activate the effect; a capability used under an
   aliased return is `effect-wrapper-behind-alias`. An alias on a function that uses no capability
   (it only passes a value along) is legal.

   ```bp
   pub type Parser<T> = @Result<T, ParseError>;
   fn porAlias(s: string) -> Parser<i32> {
       throw ParseError.Empty;       // ✗ effect-wrapper-behind-alias: write `@Result<i32, ParseError>`
   }                                 //   in the return to activate the effect
   ```

2. **The capabilities form a chain, and each level grants everything below it:**

   ```
   @Component<T>  ≡  @Use<B, T>
        @Use<C, T>  ⊃  @Task<T>        use · await
        @Stream<T>  ⊃  @Task + yield   yield · await
        @Iterator<T>                   yield
   ```

   So a hook may `await`, and a stream may `await`. `@Result` is not a level of the chain
   (decision 120); `throw` / `try` follow the fallible channel (decision 121).
3. **The chain grants downwards only.** `use` exists only under a `@Use` / `@Component` return;
   `yield` only in iterators and streams; `await` neither under a `@Result` return nor in an
   `@Iterator`; `throw` / `try` only where the return carries a `@Result`. Writing a capability the
   return does not grant is a located compile error, with no flag to switch it off (decision 67).
4. **One function, one effect, by construction.** A function has one return, so it has one effect;
   R5 (one effect annotation per fn, `effect-duplicate-annotation`) is no longer a rule — it is what
   a single return means.
5. **The annotations leave.** `#[@result]`, `#[@future]`, `#[@use]`, `#[@generator]`,
   `#[@resultGenerator]` and `#[@futureGenerator]` are no longer part of the language; writing one is
   `effect-annotation-removed` with a fix-it (decision 127). `#[page]`, `#[layout]` and `#[template]`
   stay: they are library attributes — metadata, not effects.
6. **`use` is legal only under `-> @Use<…>` or `-> @Component<…>`.** Everything decisions 96 and 104
   say about the body's base holds, read off the return instead of an annotation: one base per
   function, the refusal at the second `use` naming both; a component is called (`Counter()`), never
   `use`d; hooks compose; the compiler knows no library's base.

   ```bp
   fn Page() -> @Task<Element> {
       use cookies();                // ✗ use-without-context-effect: `use` requires a
   }                                 //   @Use<…> or @Component<…> return

   fn Misturado() -> @Component<Element> {
       val a = use state(0);         // base ElementBase
       val t = use tenant();         // ✗ two bases in one function (ElementBase and RequestBase) —
   }                                 //   located at the second `use`, naming both

   fn Errado() -> @Component<Element> {
       return use Counter();         // ✗ a component is called (`Counter()`); `use` is for hooks
   }

   fn foraDoCorpo() {
       val f = fn() { use state(0); };   // ✗ `use` does not leave the body of the function whose
   }                                     //   return is @Use
   ```

   A function that only builds HTML and activates no hook is not a component — it returns `Element`
   (`pub fn Badge(label: string) -> Element`).

**Supersedes:**
- **95** — the annotation column of its table and the rule "the annotation grants every capability
  at or below its level": the *return* grants them. The paragraph "R5 stands — one effect annotation
  per fn" is replaced by rule 4. The chain itself is re-cut by 120 and the failure rule by 121.
- **98 § 1** — the annotation ↔ wrapper name pairing is moot: there are no annotations to pair.
- **102** — the annotation `#[@use]` and "One annotation for both"; the example becomes
  `fn counter() -> @Use<ElementBase, i32>` / `fn Page() -> @Component<Element>`. What stays:
  `@Context<Base>` as the owner marker only, `@Use<C, T>`, `@Component<T>` ≡ `@Use<B, T>`,
  `effect-wrapper-mismatch` for `@Component<X>` with `X` owning no context, and the bare
  `-> Element` form leaving (a component that activates a hook and returns `-> Element` is refused).
  "R5 stands" and "`@Future` / `#[@future]`, `@Result` / `#[@result]` and decision 98 are untouched"
  no longer hold.
- **103** — the annotation column (`#[@generator]`, `#[@resultGenerator]`, `#[@futureGenerator]`)
  and "What it does not change: the annotation names"; `Grid`'s `iter` is
  `fn iter(self: Self) -> @Iterator<i32>`.
- **104** — the title rule "only `#[@use]` grants `use`" becomes "only a `@Use` / `@Component`
  return grants `use`"; `FnContext.annotated` / `env.inContextFn` are set by that return, not by an
  annotation; "R5 — one effect annotation per fn" is replaced by rule 4. Its rules 2–5, the
  revocation of 89 and 90, and questions 91–93's closures stand; rule 6 is restated by 120.
- **105** — `#[@X] loop` as the loop's annotated form (replaced by 125) and "a generator scope is an
  annotated `fn`": it is a function whose return is `@Iterator` / `@Stream` and that yields
  (decision 123).
- **117 item 3** — `#[layout]` / `#[page]` / `#[template]` require `-> @Component<Element>` (no
  `#[@use]`); the refusal names the return form, not the annotation.
- **113, 115, 116** — not superseded: none of the three writes an effect annotation or wrapper.

Bears on: 120–127, which state the rest of the revision; decision 88's component form (already
restated by 102); decision 96 (unchanged, read off the return).
Implements: front [`24-effects-by-return`](./00-compiler-carry-over/24-effects-by-return/README.md)
steps E2 (the annotations parsed only to be refused) and E3 (effect mode read from the syntactic
return; `effect-wrapper-behind-alias`).

**Amended by [128](#128-one-context-wrapper-componentc-t) (2026-09-25):** `@Use<C, T>` and
`@Component<T>` are one wrapper, `@Component<C, T>`; read every `@Use` / `@Component` above as it.

## 119. What `return` does in an effect body

**Decided 2026-09-26 by the maintainer** (D-B). In a function whose return is an effect wrapper:

- `return v` with `v: T` **wraps** — `Ok(v)`, a resolved Task, … — through **every** layer: with
  `-> @Task<@Result<U, E>>`, `return v` with `v: U` is a Task holding `Ok(v)`;
- `return w` with `w` already of a layer's type **passes through** the layers outside it: `return r`
  with `r: @Result<U, E>` is a Task holding `r`; `return t` with `t` of the whole type passes as is;
- a nested wrapper where the value fits two layers (`-> @Result<@Result<i32, E>, E>`) is
  `effect-return-ambiguous-nesting`, asking for an explicit `Ok(…)`.

```bp
fn primeiroOk(a: @Result<i32, E>, b: @Result<i32, E>) -> @Result<i32, E> {
    case (a) {
        .Ok(_) -> return a;               // passes through: already @Result<i32, E>
        .Error(_) -> return b;
    }
}
```

Inside `async { }`, `return` leaves the block, not the enclosing function (decision 124).

**Supersedes:** **95**'s reliance on `builtins.d.bp`'s `Future` auto-wrap (`return t` →
`Future.resolved(t)`, `throw e` → `Future.rejected(e)`): wrapping is now this rule over every
layer, and `throw` never rejects a Task (decision 120).
Bears on: 121 (a `throw` in `@Task<@Result<…>>` lands in the value).
Implements: front 24 step E3.3.

## 120. `@Task<T>` replaces `@Future<T, E>`; a Task never fails

**Decided 2026-09-26 by the maintainer** (D-C). `@Task<T>` is "a value that has not arrived yet";
`await` unwraps it. A Task **never fails**: when the operation can go wrong, the value is a
`@Result`, and `await` hands over that `@Result`. To propagate the error, combine with `try`.

```bp
import {http} from "std";

pub type User(id: i32, name: string);

pub fn fetchUser(id: i32) -> @Task<@Result<User, string>> {
    val res = try await http.get("https://api.exemplo.com/users/" + id.toString());
    if (res.status == 404) { throw "user " + id.toString() + " does not exist"; };
    val body = try json.decode(res.body);            // throw/try legal: the value is @Result
    return userFromJson(body);                       // a Task holding Ok(…)
}

pub fn delayed(ms: i32) -> @Task<void> {             // a Task that cannot fail: await, no try
    await timer.sleep(ms);
}
```

**`await` and `try` are separate.** `await t` waits; `try r` propagates. With
`t: @Task<@Result<U, E>>`:

| Written | Answers | Legal where |
|---|---|---|
| `await t` | `@Result<U, E>` | an await channel |
| `try await t` | `U` (the error propagates) | an await channel **and** a `@Result` in the return |
| `try await t catch x` | `U` (or `x`) | an await channel |

`try await x` parses as `try (await x)`. `await` types `@Task<X>` → `X` and propagates nothing.
`await` without an await channel (a `@Task`, `@Use`, `@Component` or `@Stream` return, an
`async { }` block or a `stream` loop) is `effect-await-without-task`; a function with no await
channel consumes a Task through the Task's own functions (`.map`, `.then` …).

**The chain is `@Use ⊃ @Task`, and `@Result` leaves it.** `@Use<C, T>` and `@Component<T>` extend
`@Task`; `@Stream` is a `@Task` that also yields. So every hook and every component may `await`.

**Backends.** commonJS: every function returning `@Task`, `@Use` or `@Component` is an
`async function`, whether or not it awaits (decision 104 rule 6, kept), and its caller `await`s
it; a `throw` in a `@Task<@Result<…>>` body **does not reject the Promise** — it resolves with the
`Error` value. erlang, beam and wasm: the Task is eager and `await` is the identity.

**Supersedes:**
- **95** — the chain `@Context ⊃ @Future ⊃ @Result` and the rule "every effectful body can fail, so
  every wrapper implements `@Result`": the chain is `@Use ⊃ @Task` (`@Stream ⊃ @Task`), with
  `@Result` outside it (failure: 121). The `@Future<T, E = any>` error channel it relied on
  (`builtins.d.bp:140`) is removed.
- **98** — "one word for suspension: `Future`". The word is `Task`, and `@Future` leaves (with its
  `E`). The TypeScript mapping reads `@Task` → `Promise`. 98's sentence that `Async` leaves the
  vocabulary entirely no longer holds for the block keyword `async { }` (decision 124); no wrapper is
  named `Async`.
- **102** — `pub behavior Use<C, T> extends Future` becomes `extends Task`; "`map` on a
  `@Future<T, E>` answers `@Future<R, E>`" becomes `@Task<R>`.
- **104** — "`@Component ⊃ @Future`" becomes `@Component ⊃ @Use ⊃ @Task`; rule 6's commonJS
  `async function` now keys on the return (`@Task` / `@Use` / `@Component`), and its "their `@Future`
  is eager" reads `@Task`. The refused example is `fn Page() -> @Task<Element> { use pathname(); }`.
- **114** — items 2, 3, 5 and 8 respelled: `RenderPlugin`'s `head` / `chunk` / `payload` return
  `@Task<…>`, `close` returns `@Task<@Result<void, string>>`; `ChunkWriter`'s `write` / `close` and
  `PageRenderer` return `@Task<void>`; `renderStream` is `fn … -> @Task<…>` with no `#[@future]`;
  the bridge awaits emilia's `flush()`, whose annotation leaves.
- **117** — item 1's `Response.write` / `close` and rakun's `ChunkWriter` are `-> @Task<void>`;
  `renderStream` loses `#[@future]`; the onze boot closure is `fn(req, out) -> @Task<void>`.
  Item 1's "a failed render is the future's error" has no home under this decision (a Task does not
  fail) — see the note under 121.

Bears on: `01-std/02-std-async-primitives` (every signature is `@Task`, E7 of front 24); 121.
Implements: front 24 steps E1 (`@Task<T>` in `builtins.d.bp`), E3.4, E4 (`for await`'s channel) and
E5.

## 121. Only `@Result` fails

**Decided 2026-09-26 by the maintainer** (D-D), in his words: *"Só `@Result` falha."* `@Task`,
`@Use`, `@Iterator` and `@Stream` never fail. When something can fail, the failure goes **inside the
value**: `@Task<@Result<T, E>>`, `@Iterator<@Result<T, E>>`. `throw` and `try` are legal whenever
there is a `@Result` in **some layer** of the return — `@Result<…>`, `@Task<@Result<…>>`,
`@Use<C, @Result<…>>`, `@Iterator<@Result<…>>`, `@Stream<@Result<…>>` — and the receiver decides
what to do with the error. The checker computes two independent things from the return: the level
(`use` / `await` / `yield`) and whether a `@Result` is present; `throw` / `try` depend only on the
second. Without one they are `effect-try-without-fallible-channel`.

Three ways to consume a `@Result`, of which only the second needs the channel:

```bp
fn portOrDefault(s: string) -> i32 {                     // 1) try … catch — any function
    return try parsePort(s) catch 8080;
}

fn loadConfig(text: string) -> @Result<Config, ParseError> {   // 2) try alone — propagates
    val port = try parsePort(text);
    return Config(port: port);
}

fn describe(s: string) -> string {                       // 3) case — both outcomes
    case (parsePort(s)) {
        .Ok(p) -> return "port " + p.toString();
        .Error(.Empty) -> return "empty";
        .Error(.NotANumber(text: t)) -> return "not a number: " + t;
        .Error(.TooBig(value: v)) -> return "too big: " + v.toString();
    }
}

fn mustParse() {                                         // val assert — fatal if it does not match
    val assert Ok(p) = parsePort("443");
    @print(p);
}
```

**A component handles its errors in its body.** `@Component<Element>` returns `Element`, not a
`@Result`, so a component catches, `case`s, calls `notFound()` or renders an error screen; a hook
propagates only when its `T` is a `@Result`:

```bp
#[page]
pub fn PostPage(ctx: PageContext) -> @Component<Element> {
    val post = try await loadPost(ctx.param("id")) catch null;
    if (post == null) { notFound(); };
    if (post.movedTo != "") { redirect("/posts/" + post.movedTo); };
    return div([h1([text(post.title)]), Counter()]);   // a component is CALLED, not `use`d
}

pub fn tenant() -> @Use<RequestBase, @Result<Tenant, string>> {
    val id = use requestId();                // same base: ok
    return try await tenants.byRequest(id);  // try legal: T is @Result
}

fn Propaga() -> @Component<Element> {
    val u = try await fetchUser(1);          // ✗ effect-try-without-fallible-channel: Element is not
}                                            //   a @Result; use `catch`, `case` or `notFound()`
```

A type error that uses a `@Result` where a `U` is expected carries a hint: suggest `try await`
when the value came from an `await`, `try r` when it came from a `for` item, and point at the
`try` / `throw` that made an inferred value a `@Result` (decisions 124, 125).

**Supersedes:**
- **95** — "every effect can fail" (the title's second half), and the rows granting `try` to
  `#[@context]`, `#[@futureGenerator]`, `#[@future]` and `#[@iterator]` bodies by level.
- **102** — `@Use`'s and `@Component`'s inherited `try` (through `Future ⊃ Result`): they `throw` /
  `try` only when `T` is a `@Result`.
- **103** — the refusal text `` `@Generator` has no error channel; use `@ResultGenerator<T, E>` ``:
  the refusal is `effect-try-without-fallible-channel`, pointing at `@Iterator<@Result<T, E>>`.
- **104** — the chain case "a server component that `await`s and `use`s" keeps `await` and `use`,
  not `try`.
- **117** — item 1's page `val post = await loadPost(…)`, which relied on the page propagating a
  failed load, is `try await loadPost(…) catch null` (the guide's spelling); item 3's layouts and
  templates likewise handle their errors in the body. **Not decided here:** item 1 says a failed
  render (the target check, a plugin's `close`) "is the future's error"; a Task has no error, so
  `renderStream`'s return must carry a `@Result` — which `E`, and whether `Response.write` /
  `ChunkWriter.write` stay infallible `@Task<void>`, is front 24 step E7's question for the
  maintainer.

Bears on: 120, 122 (the item as the carrier of failure).
Implements: front 24 step E3.2 and E3.9.

## 122. `@Iterator<T>` and `@Stream<T>` over `YieldStep<T>`; `for` does no implicit `try`

**Decided 2026-09-26 by the maintainer** (D-E). An iterator produces a sequence on demand (lazy):
each `next` runs the body up to the next `yield`. A stream is the same, asynchronous: finding out
whether there is a next item may need to wait (paging, a socket, a file).

```
@Iterator<T>    synchronous    yield · break v
@Stream<T>      asynchronous   yield · break v · await
```

`@Generator` is renamed `@Iterator<T>`; `@ResultGenerator` and `@FutureGenerator` leave; `@Stream<T>`
enters. Both use one step, which loses the `E` and the `Error` variant:

```bp
pub type YieldStep<T> { Yield(value: T), Done }
```

Inside an iterator or a stream: `yield v` emits `v` and **continues**; `break v` emits `v` and
**ends** (≡ `yield v; break;`); a bare `break` outside any inner loop ends without emitting.

```bp
pub fn fibonacci(limit: i32) -> @Iterator<i64> {
    var a: i64 = 0;
    var b: i64 = 1;
    var i = 0;
    while (i < limit) {
        yield a;
        val t = a + b; a = b; b = t;
        i = i + 1;
    };
}

fn main() {
    for (fibonacci(10)) { n -> @println(n); };     // legal in a plain function
}
```

**Items that can fail — `@Iterator<@Result<T, E>>`.** The iterator does not fail; **each item** may
be an error. With an item `@Result<U, E>`: `yield v` with `v: U` emits `Ok(v)`, with
`v: @Result<U, E>` emits it as is; `throw e` emits `Error(e)` and ends (≡ `break Error(e)`); a `try x`
that fails emits `Error(e)` and ends. In a `@Stream<@Result<…>>` a failing `try await` does the same.

```bp
pub fn parseLines(text: string) -> @Iterator<@Result<i32, ParseError>> {
    for (text.split("\n")) { line ->
        if (line == "") { continue; };
        yield try parsePort(line);        // failed → emits Error(e) and ends
    };
}
```

**The consumer receives the `@Result` and decides. `for` does no implicit `try`**, and iterating any
`@Iterator` is legal in any function:

```bp
fn sumPorts(text: string) -> @Result<i32, ParseError> {  // stop at the first error: explicit try
    var total = 0;
    for (parseLines(text)) { r -> total = total + try r; };
    return total;
}

fn printPorts(text: string) {                             // carry on after an error: case
    for (parseLines(text)) { r ->
        case (r) {
            .Ok(p) -> @println(p);
            .Error(e) -> @println("error: " + e.toString());
        }
    };
}
```

**Streams are iterated with `for await`**, which needs an await channel (a `@Task`, `@Use`,
`@Component` or `@Stream` return, an `async { }` block, or a `stream` loop):

```bp
pub fn pages(url: string) -> @Stream<@Result<Array<User>, string>> {
    var next = url;
    while (next != "") {
        val res = try await http.get(next);       // failed → emits Error(e) and ends
        val body = try json.decode(res.body);
        yield usersFrom(body);                    // emits Ok(…)
        next = nextLink(body);
    };
}

fn countUsers() -> @Task<@Result<i32, string>> {
    var n = 0;
    for await (pages("https://api.exemplo.com/users")) { batch ->
        n = n + (try batch).length;
    };
    return n;
}
```

**No `Iterable`.** A type that wants to be iterated exposes an ordinary method answering an iterator
(`fn iter(self: Self) -> @Iterator<i32>`), called as `for (g.iter())`.

The refusals: `throw` / `try` with an item that is not a `@Result` is
`effect-try-without-fallible-channel`; `await` in an `@Iterator` is `iter-await` (use `@Stream`);
`@Iterator<T, E>` is `iterator-error-param-removed` (use `@Iterator<@Result<T, E>>`).

```bp
fn h() -> @Iterator<User> {
    yield await fetchUser(1);   // ✗ iter-await: `await` does not exist in @Iterator; use @Stream
}

fn velho() -> @Iterator<i32, ParseError> { … }
                                // ✗ iterator-error-param-removed: use
                                //   @Iterator<@Result<i32, ParseError>>
```

**Backends.** commonJS: an `@Iterator` that yields is a `function*`, a `@Stream` an
`async function*`; a failing `throw` / `try` on an `@Result` item is `yield {Error: e}; return;`.
erlang, beam and wasm: today's `@Generator` / `@FutureGenerator` representations, renamed; a failing
item emits `Error(e)` and ends.

**Supersedes:**
- **95** — the `#[@iterator]` / `@Iterator<T, E, C>`, `#[@futureGenerator]` and `#[@generator]` rows,
  and "`yield` stays exclusive to the three generator wrappers": it is exclusive to `@Iterator` and
  `@Stream` (and the loops of 125).
- **98** — `@FutureGenerator` and the argument rejecting `@Stream` because an IO type would want the
  name: the maintainer chose `@Stream`. Measured for front 24 step E1: no `Stream` or `Task` type in
  `libs/std/src/*.bp` at compiler `feat` `0beaa1f9`; the specs' only "stream" is rakun front 89's
  prose. The TypeScript mapping reads `@Iterator` → `IterableIterator`, `@Stream` → `AsyncGenerator`.
- **103** — the three wrappers and their table; `YieldStep<T, E = void>` with `Error(error: E)`;
  and the consumer's table (a `for` over a fallible generator is an implicit `try` / `await` that
  needs the level). Question 97's answer (b) — the plain iterator is infallible — stands as
  `@Iterator<T>`; `break v` as an item, `Iterable` leaving and the `C` / `R` channels leaving stand.
- **105** — `for await` iterates a `@Stream` (not a `@FutureGenerator`); the sentence "`for` over a
  fallible generator follows decision 103: an implicit `try` / `await` that requires the level";
  and the "surfaces only at the consumer, where `for` requires it" of the annotated loop.

Bears on: 123, 125; `docs.md` § generators.
Implements: front 24 steps E1 (`@Iterator<T>`, `@Stream<T>`, `YieldStep<T>`), E3.8, E4 and E5.

## 123. Iterator or factory: a body that yields is an iterator

**Decided 2026-09-26 by the maintainer** (D-F). A function whose return is `@Iterator` or `@Stream`
**is an iterator if its body has `yield` or `break v`** — searched in the function's own scope,
entering neither closures nor inner `iter` / `stream` loops. Without them it is an ordinary function
that **returns** a ready iterator (a factory). Mixing `yield` with `return <iterator>` in one body is
`iter-mixed-yield-return`.

```bp
fn pares(xs: i32[]) -> @Iterator<i32> {                 // iterator: has yield
    for (xs) { x -> if (x % 2 == 0) { yield x; }; };
}

fn paresDe(xs: i32[]) -> @Iterator<i32> {               // factory: returns an iterator
    return iter for (xs) { x -> if (x % 2 == 0) { yield x; }; };
}

fn k(xs: i32[]) -> @Iterator<i32> {
    yield 0;
    return xs.iter();           // ✗ iter-mixed-yield-return: iterator (yield) and factory
}                               //   (return) in the same body
```

A factory lowers as a plain function on every backend.

**Supersedes:** **103** / **105** — "a generator scope is a `#[@generator]` / `#[@resultGenerator]`
/ `#[@futureGenerator]` body — of a `fn` or of a `loop`": the function's half is this rule.
Implements: front 24 steps E3.5 and E5.

## 124. The `async` block is a closed expression worth `@Task<T>`

**Decided 2026-09-26 by the maintainer** (D-G). `async { … }` creates a `@Task` without declaring a
function. It is legal in **any** function, a plain one included: the block awaits nothing outside
itself, it **creates** the Task.

```bp
fn dispara() -> @Task<@Result<Array<User>, string>> {
    return async.allOf([
        async { return try await fetchUser(1); },              // @Task<@Result<User, string>>
        async { return (try await fetchUser(2)).withRole("admin"); },
    ]);
}

val tique = async { await timer.sleep(100); return 1; };       // @Task<i32>
```

The rules:

- `return v` **leaves the block** with `v`, not the enclosing function — the block behaves as a
  closure called in place;
- it is **closed**: its body starts a new capability context; inside a function returning `@Use`, an
  `async { }` may not `use`;
- `T` comes from the `return`s. If the body has `throw` or `try`, the value becomes `@Result<U, E>`
  on its own, `E` from those `throw` / `try`. Two different error types are
  `gen-infer-conflicting-errors`, suggesting an annotation: `val x: @Task<@Result<User, string>> =
  async { … };`
- `break :outer` / `continue :outer` crossing the block's border are refused.

`async` is a **contextual** word: it is a keyword only immediately before `{`. `import {async} from
"std"` and `async.allOf(…)` keep meaning the std module.

**Backends.** commonJS: `(async () => { … })()`. erlang, beam and wasm: the block runs in place.

**Supersedes:** **98**'s "`Async` leaves the vocabulary entirely" — for the block keyword only; there
is still no `@Async` wrapper.
Bears on: 119 (`return` inside the block), 121 (the hint pointing at the `try` that made the value a
`@Result`).
Implements: front 24 steps E2 (the `AsyncBlock` node), E3.6–E3.7 and E5.

## 125. `iter` and `stream` prefix a loop and make it an iterator or a stream

**Decided 2026-09-26 by the maintainer** (D-H). Alone, `loop`, `while` and `for` are statements
(`void`, decision 105). With `iter` or `stream` in front, any of the three becomes an **expression**
worth the iterator or the stream:

| Form | Worth |
|---|---|
| `iter loop` · `iter while` · `iter for` | `@Iterator<T>` |
| `stream loop` · `stream while` · `stream for` · `stream for await` | `@Stream<T>` |

```bp
fn main() {
    val numeros = iter loop {                // @Iterator<i32>
        val n = readNumber();
        if (n < 0) { break n; };             // emits n and ends
        yield n * 2;                         // emits and continues
    };
    for (numeros) { x -> @println(x); };

    val contagem = iter while (i > 0) { yield i; i = i - 1; };

    val pares = iter for ([1, 2, 3, 4]) { x -> if (x % 2 == 0) { yield x; }; };

    // the item becomes @Result on its own when the body has throw/try:
    val lidos = iter loop { yield try parsePort(readLine()); };
                                             // @Iterator<@Result<i32, ParseError>>
    val remotos = stream for (ids) { id -> yield try await fetchUser(id); };
                                             // @Stream<@Result<User, string>>
    val ticks = stream loop { await timer.sleep(1000); yield now(); };
                                             // @Stream<Instant>

    @println(soma(iter for (xs) { x -> yield x * x; }));   // as an argument
}
```

The rules:

- `iter` and `stream` are **contextual**: keywords only immediately before `loop`, `while` or `for`.
  `g.iter()`, `val stream = …` and `http.stream(…)` stay legal;
- the prefixed loop **is** the iterator: `break` and `break v` in it end the sequence;
- it is **closed**: its body has only the iterator's / stream's capabilities, never the enclosing
  function's — inside a function returning `@Use`, an `iter loop` may neither `use` nor `await`;
- `await` only in `stream`; in `iter` it is `iter-await`, suggesting `stream`;
- the item becomes `@Result<U, E>` when the body has `throw` / `try`. To pin the type, annotate the
  `val` — `val xs: @Iterator<i32> = iter loop { … }` — and a `try` in the body is then a located
  error. Two different error types in the body are `gen-infer-conflicting-errors`, asking for the
  annotation;
- `yield` inside an **unprefixed** `for` / `while` / `loop` feeds the nearest generator scope;
  `yield :label v` and `break :label v` choose another;
- `break :outer` / `continue :outer` crossing the border of an `iter` / `stream` loop are refused,
  as leaving a closure;
- `yield` and `break v` exist only in a generator scope (a function returning `@Iterator` /
  `@Stream` that yields, or an `iter` / `stream` loop). To collect in a plain function, use
  `xs.map(…)` / `filter(…)` or a `var`:

  ```bp
  fn dobro(xs: i32[]) -> i32[] {
      for (xs) { x -> yield x * 2; };   // ✗ `yield` outside a generator scope
  }
  ```

**Backends.** commonJS: `iter …` is `(function* () { … })()`, `stream …` is
`(async function* () { … })()`. erlang, beam and wasm: the function's lowering, inline.

**Supersedes:** **105** — `#[@generator] loop` / `#[@resultGenerator] loop` / `#[@futureGenerator]
loop` and the whole bullet list under "`#[@generator] loop` — the loop as a generator": the
expression's type (now `@Iterator` / `@Stream`, the `@Result` item inferred), "Only `loop` takes the
annotation" (all three forms take the prefix; `#[@generator] loop { for (xs) { … }; break; }` is
`iter for (xs) { … }`), and "a `#[@resultGenerator] loop` may `try` / `throw` … without the enclosing
fn having the level". What stays: the three keywords, statements `void`, ranges, parentheses,
labels, the nearest-scope rule, the closed body, the refused `break :outer` across the border, and
the desugaring to a local parameterless iterator called in place (with erlang/beam's mutable
capture).
Bears on: 122 (the item), 123 (a factory returns `iter for …`).
Implements: front 24 steps E2 (the `GenLoop { kind, loop }` node in expression position), E3.6–E3.7
and E5.

## 126. A host function returning `@Task<@Result<T, E>>` turns a rejection into `Error(e)`

**Decided 2026-09-26 by the maintainer** (D-I). A `#[@External.<Target>(…)]` function declared
`-> @Task<@Result<T, E>>` converts a rejected Promise (Node) or an `{error, …}` answer (Erlang) into
`Error(e)`. Declared `-> @Task<T>`, a rejection is a fatal host failure — that form is for a host
that guarantees it does not fail.

```bp
#[@External.Node("./helpers.mjs", "parse"),
  @External.Erlang("helpers", "parse")]
pub declare fn parse(input: string) -> i32;
```

| | commonJS | erlang / beam / wasm |
|---|---|---|
| `-> @Task<@Result<…>>` | `try { await p } catch (e) { return {Error: …} }` | `{error, R}` → `Error(R)` |
| `-> @Task<T>` | `await p`; a rejection is a fatal failure | as today |

Only the `External.<Target>` form exists (`#[@external]` in lowercase is an error); `inline = true`
(on `External.Erlang` / `External.Beam` only) keeps the backend's hand-written shape; the bundled
libraries' native code is inline templates only (decision 117 item 8, unchanged).

**Supersedes:** none of 95, 98, 102–105, 113–117 — it states the host boundary under decisions
120 and 121.
Implements: front 24 step E5 (the two host rows) and its host cells.

## 127. No coexistence: the old annotations and wrappers are errors with a fix-it and a codemod

**Decided 2026-09-26 by the maintainer** (D-J). The six effect annotations, `@Future`, `@Generator`,
`@ResultGenerator`, `@FutureGenerator` and `@Iterator<T, E>` become compile errors with a suggested
correction and a codemod, `botopink migrate effects`. There is **no compatibility mode** — no release
accepting the old forms with a warning, and no flag — because this is a beta and because of
[decision 67](../1.0.5-beta/decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it).
The migration plan's alternative (one version accepting the old forms with a warning, an error in
the next) is rejected; the codemod covers the mechanical part, and marks the rest for review with
`// TODO(migrate-effects)`.

| Written | Diagnostic | Fix-it |
|---|---|---|
| `#[@result]` · `#[@future]` · `#[@use]` · `#[@generator]` · `#[@resultGenerator]` · `#[@futureGenerator]` | `effect-annotation-removed` | remove the annotation (on a loop: `iter` / `stream`) |
| `@Future` · `@Generator` · `@ResultGenerator` · `@FutureGenerator` | `effect-type-removed` | the new name (`@Future<T, E>` → `@Task<@Result<T, E>>`) |
| `@Iterator<T, E>` | `iterator-error-param-removed` | `@Iterator<@Result<T, E>>` |

The old names that had already left stay gone: `#[@context]` / `@Context<B, R>` as an effect,
`#[@iterator]` / `#[@asyncGenerator]` / `@AsyncIterator`, `Iterable`, `IteratorStep`, `Yield<T, R>`,
`loop (xs) { x -> }` / `loop (cond)` / `loop await`.

**Supersedes:** nothing in 95–117 beyond what 118–126 state; it fixes how the change lands.
Bears on: every library front whose examples spell the old annotations (listed in front 24's README).
Implements: front 24 step E2 (the three diagnostics). **Amended by 131:** the codemod and its
`// TODO(migrate-effects)` marks left before release; the migration is done by hand, from the errors.

## 128. One context wrapper: `@Component<C, T>`

**Decided 2026-09-25 by the maintainer**, amending the effect revision before it lands: *"gostaria de
unificar `@Use<C, T>` or `@Component<T>` em `@Component<C, T>`"*. The two wrappers that grant `use`
become one:

| Return | The body may write |
|---|---|
| `@Component<C, T>` | `use` · `await` |

- **`C` is the base** the body's `use`s anchor at (`ElementBase`, `RequestBase` — the library's name;
  the compiler knows none). It is **always written**, for a hook and for a component; it is never
  read off `T`'s `implement @Context<…>` clause. `@Component<T>` with one argument is a type-arity
  error.
- **`T` is the return.** A **hook** returns any `T` (`@Component<ElementBase, State<T>>`); a
  **component** is the `@Component<C, T>` whose `T` implements `@Context<C>`
  (`@Component<ElementBase, Element>`). The rules of 96 / 104 stand, read off this one wrapper: one
  base per function; hooks compose (`use h()` needs `h: @Component<C, _>` with the body's `C`); a
  component is called (`Counter()`), never `use`d — `use` of a call whose `T` owns the context is
  refused.
- **The chain** is `@Component ⊃ @Task` (`@Stream ⊃ @Task`, `@Iterator`); `throw` / `try` follow
  121 (legal when `T` is a `@Result`); commonJS lowers every `@Component` return to an
  `async function` (120).
- **`@Use` leaves** without an alias (127): `@Use<C, T>` in a type is `effect-type-removed`, fix-it
  `@Component<C, T>`. The codemod rewrites `@Use<C, T>` → `@Component<C, T>` and `@Component<T>` →
  `@Component<B, T>`, `B` read from `T implement @Context<B>` (a typed rewrite, like `try await`).
- `effect-wrapper-mismatch`'s last case — `@Component<X>` with `X` owning no context — leaves with the
  sugar: any `T` is a legal hook return.

```bp
pub fn state<T>(initial: T) -> @Component<ElementBase, State<T>> { … }       // a hook

pub fn counter(start: i32) -> @Component<ElementBase, #(i32, fn() -> void)> {
    val s = use state(start);
    return #(s.get(), fn() { s.set(s.get() + 1); });
}

#[page]
pub fn PostPage(ctx: PageContext) -> @Component<ElementBase, Element> {      // a component
    val (n, inc) = use counter(0);
    return div([p([text(n.toString())])]);
}
```

**Amends:**
- **102** — `@Use<C, T>` and `@Component<T>` ≡ `@Use<B, T>` become `@Component<C, T>`; the sugar that
  read `B` from `T` leaves. `@Context<Base>` as the owner marker only stays.
- **104** — its rules are read off `@Component<C, T>`; "the base of a `@Component<T>` is the `B` of
  `T: @Context<B>`" becomes "the base is `C`".
- **117 item 3** — `#[layout]` / `#[page]` / `#[template]` require `-> @Component<ElementBase, Element>`.
- **118** — the table's `@Use<C, T>` or `@Component<T>` row is `@Component<C, T>`; rules 3 and 6 name
  one wrapper.
- **120, 121** — the chain is `@Component ⊃ @Task`; the await channel and the commonJS
  `async function` key on `@Task` / `@Component`; `@Component<C, @Result<…>>` carries a hook's failure.

Implements: front [`24-effects-by-return`](./00-compiler-carry-over/24-effects-by-return/README.md)
steps E1 (`Component<C, T> extends Task`, `Use` removed), E2 (`@Use` → `effect-type-removed`), E3
(the `use` gate and the component-is-called refusal keyed on `T: @Context<C>`), E6 (the two codemod
rows) and E8 (the spec examples).

## 129. Type aliases: four restrictions stand, `as` reaches an imported alias

**Decided 2026-09-26 by the maintainer** (pending item 129): *"corrigir para alias"* — `as` is legal
on an imported type and on an imported type alias (decision 110); the other four readings stay as
implemented. The alias declaration decision 118 rule 1 presupposes
(`pub type Parser<T> = @Result<T, ParseError>;`) has these edges:

| Written | Answer |
|---|---|
| a generic alias without its arguments (`x: Parser` for `type Parser<T> = …`) | refused, `type-alias-arity` — it is never read as `Parser<fresh>` |
| a parameter default (`type P<T = i32> = Box<T>;`) | refused at the parse, `type-alias-generic-default` |
| an annotation on the alias (`#[deprecated] type Old = New;`) | refused, `type-alias-annotated` |
| an alias taking the name of a type in scope (`type Dict = i32;`) | refused, `type-alias-name-taken` — an alias never shadows |
| `import {Parser as P} from "x"` — `as` on an imported alias or type | **legal** (decision 110 rule 1): `P` is a checker-local name for the alias, which has no emitted identity of its own |

A return spelled through an alias reaches the backends unexpanded (so none lowers it as an effect,
`effect-wrapper-behind-alias`); every other alias is expanded before codegen
(`comptime/alias_erase.zig`).

```bp
type Pair<A, B> = #(A, B);
val p: Pair = #(1, 2);            // error[type-alias-arity]
import {Pair as P} from "shapes";
val q: P<i32, i32> = #(1, 2);     // ✓ — P is Pair in the checker only
```

**Supersedes:** the `import-alias-on-type` refusal for an alias (decision 110 already removed it for
a type). Each refused reading can be relaxed later without breaking a program that compiles.
Implements: the alias declaration (`parser/decls.zig` `parseTypeAliasDecl`, `comptime/infer.zig`
`expandTypeAlias` / `checkTypeAliasDecl`) for the four refusals, landed; `as` on a type and an alias
is `00 · 01-checker`'s, with decision 110 rule 1.

## 130. A failing render carries `E = string`; the writers stay infallible

**Decided 2026-09-26 by the maintainer** (front 24 open point 8): option (a). Decision 117 item 1's
"a failed render is the future's error" is read under decisions 120 and 121:

- `renderStream(…) -> @Task<@Result<void, string>>`; rakun's
  `PageRenderer = fn(req: Request, out: ChunkWriter) -> @Task<@Result<void, string>>`, so onze's
  boot closure stays `return ui.renderStream(…)`.
- `ChunkWriter.write` / `close` and jhonstart's `Response.write` / `close` stay `@Task<void>`, as
  decision 120 spells them: a write never fails as a value. A write after `close`, and
  `setStatus` / `setHeader` after the first `write`, are misuse and raise (decision 67).
- rakun's dispatch answers an `Error(msg)` like an untagged raise of the renderer: status 500 when
  nothing was written, otherwise the response is closed; the message goes to the log under a
  correlation digest, never on the wire. `servePage` stays `@Task<i32>` (the status written).

```bp
fn renderStream(page: Page, out: ChunkWriter) -> @Task<@Result<void, string>> {
    await out.write(head);            // @Task<void>: nothing to propagate
    val body = try await renderBody(page);
    await out.write(body);
    return;
}
```

A typed `RenderError` can come later without breaking code that reads the string: the one fallible
piece of the pipeline today, `RenderPlugin.close`, is already `@Result<void, string>`, and the render
forwards the same `E`; rakun names no jhonstart type (decision 114 item 5).

**Amends:** 117 item 1 (the render's failure is a `@Result` value inside the Task).
Implements: rakun front 23 step 1 (`ChunkWriter`, `PageRenderer`, `servePage`, the dispatch), jhonstart
front 30 (`renderStream`'s signature), onze front 49 (the boot closure).

## 131. No migration routine for the effect change

**Decided 2026-09-26 by the maintainer** (front 24 open point 7 and pending item 24-d): *"não precisa
de rotina de migração — estamos em beta"*. The codemod `botopink migrate effects` and the
migration-only mode it needed leave the compiler:

- **Removed:** the `migrate effects` subcommand (`modules/compiler-cli/src/cli/migrate_effects.zig`,
  its snapshots, its unit tests and contract row C8b); the migration-only parse
  (`parser.effect_migration`, which read the removed annotations and wrappers as their new
  spelling); the checker's legacy typing (`infer.effect_migration_files`); the `ExprTypeLog` hook
  only the codemod read; `comptime.setEffectMigration`.
- **Kept:** every old form stays a located compile error with its fix-it —
  `effect-annotation-removed`, `effect-type-removed`, `iterator-error-param-removed` (decision 127's
  table) — and `docs.md` § *Migrating from the effect annotations* keeps the old → new table and the
  four changes that are not a rename. A migration is done by hand, error by error.
- **`botopink migrate`** keeps its meaning — it derives the module tree (`pub mod X;`) and predates
  front 24; it takes no subcommand (`botopink migrate effects` is a positional, refused by row C8).

**Amends:** 127 — "and a codemod" and the `// TODO(migrate-effects)` marks leave; the no-coexistence
rule and the three diagnostics stand. **Answers:** pending 24-d (the mode has nothing left to serve)
and front 24 open point 7.
Implements: front 24's closeout (compiler `front/24-closeout`); front 24's README drops step E6 and
§ *Codemod*.

## 132. The `;` after a braced block becomes an error once every source is migrated

**Decided 2026-09-26 by the maintainer** (pending item 16-d), on the recommendation. A braced
`if` / loop / `case` statement ends at its `}` (decision 29); the parser accepts the trailing `;`
and `botopink format` prints none until every tree has dropped it, in this order:

1. each library runs `00-compiler-carry-over/16-formatter/c13-migrate.py` (or `botopink format`) at
   the end of the threads writing in it (rakun, emilia, onze; jhonstart and erika with their
   next sweep);
2. `tests/language` migrates in the language-tests front;
3. front 15's parked patch lands, narrowed to `Parser.isBracedBlockStmt`
   (`blockStatementSemicolon`) — from then on the `;` is refused.

Refusing earlier would fail every open thread's tree at once.

**Amends:** 29's "rejected" — it holds from step 3.
Implements: `00 · 16-formatter` (the optional half, landed), the library fronts and
`12-language-tests` (steps 1–2), `00 · 15-language-surface` (step 3).

## 133. A trailing comma keeps a list in its open form

**Decided 2026-09-26 by the maintainer** (pending item 16-c): option (a). An array, tuple, argument,
record field or enum list written with a trailing comma prints open — one element per line — even
when it fits: the comma is the author's explicit request. A list without the comma is laid out by
width alone (decision 65 part 2), and the open form always ends with the comma, so the output is
stable.

```bp
val p = Point(x: 1, y: 2,);
// prints
val p = Point(
    x: 1,
    y: 2,
);
```

**Amends:** 65 part 2 — the trailing comma is the one input the canonical form reads.
Implements: nothing to change — `format.zig` does this today.

## 134. Every example in the guide and in `docs.md` is correct against the compiler

**Decided 2026-09-26 by the maintainer** (front 24, acceptance box of step E3): *"atualizar e deixar a
doc 100% correta"*. Each fence of `24-effects-by-return/guide.md` and of `docs.md` either types (✓)
or answers exactly the code it names (✗); an example the compiler does not yet accept for a reason
the language intends is a compiler gap to close, not an example to weaken:

- the guide's slips are fixed in the text — a return type that does not match its body, std
  functions that do not exist (`io.http.fetch` is the HTTP call; `json.decode` lives in `json`),
  `async.timeout` taking a thunk (`{ -> fetchUser(4) }`), a tuple bound as `val #(a, b)`, printing
  an error through what its type declares, and every import spelled against std's tree (decision 106);
- three checker gaps are closed by `00 · 01-checker`: `try x catch null` into a `?U`, a `null`
  check whose branch ends in a `noreturn` call narrowing what follows, and a component called in a
  component's body answering its `T` (`Element`);
- decision 117 item 3's check is jhonstart's: `#[layout]` / `#[page]` / `#[template]` refuse a
  function whose return is not `@Component<ElementBase, Element>`, located at the return.

Implements: front 24's closeout (the two documents and jhonstart's decorators), `00 · 01-checker`
(the three gaps); `zig build test-docs` compiles `docs.md`'s fences.

## 135. Specs keep only what still holds

**Decided 2026-09-26 by the maintainer** (front 24, acceptance box of step E8): *"remover o
histórico — as specs ficam só com o que ainda vale"*. A closed front's spec is condensed to its
outcome in today's surface and its remaining open items; status narratives, commit hashes and the
spellings the language removed leave it (the meta `AGENTS.md` convention, applied to closed fronts
too). The removed effect spellings appear in `specs/` only where a text is explicitly the record or
the table of removed names: this file, and the removed-names table of `guide.md` § 9 (as in
`docs.md` § *Migrating from the effect annotations*).

Implements: front 24's closeout — fronts 19, 20, 21 and 22, front 24's README, guide and status,
`decisions-pending.md` and `status.md` rewritten to the current state.

## 140. Library resolution stops at the enclosing checkout

**Decided 2026-09-26 by the maintainer** (pending 24-f, option (a)). The walk up from a project that
finds library roots — `BOTOPINK_LIB_ROOTS`, then for each ancestor `D`: `D` itself when it is a
workspace, `D/repository/botopink-lang/libs`, `D/repository`, `D/libs` — stops after the first `D`
that holds `repository/`: the enclosing checkout, which is the meta workspace, a worktree of it under
`.tasks/<name>`, or CI's `botopink-lang` checkout with the libraries cloned into `repository/`. An
ancestor of that directory belongs to another checkout. A worktree nested in the meta checkout used
to see the main checkout's `repository/*` as well, every library was "declared by two libraries",
and `test-libs` / `scripts/gate.sh` could only run from a copy of the tree outside it. The rule is one
predicate, `manifest.isCheckoutRoot`, used by the three walk-ups — the compiler's loader
(`compiler-cli` `libs.zig`), `botopink-lib-test` (`discovery.zig`) and the language server
(`project_graph.zig`) — so the three see the same libraries. No flag widens it: a library outside the
checkout is reached through `BOTOPINK_LIB_ROOTS`, `--lib-root` or a `path` dependency, as before.

The same resolution was not transitive, and a second defect of it is decided with this one: the
loader (`compiler-cli` `libs.zig`) loaded only the project's own `dependencies`, in the order the
manifest lists them, so a package outside the jhonstart workspace that depends on `jhonstart-forms`
compiled `jhonstart-forms/form` with `from "jhonstart"` and `from "jhonstart-link"` unbound — neither
was loaded, and listing both after it still failed on the order. Dependencies are now transitive:
each dependency's own entries resolve from its manifest and directory (`{ "workspace": true }` from
its workspace, `path` from its directory, `git` across the roots — as when it builds itself), every
package loads once by import name, after every package it depends on. Refused, located on the entry
that brought it in: one import name that two packages of a build resolve to two directories (one
`<name>/` prefix cannot hold both), and a cycle between packages.

Implements: `00 · 25-gate-perf` step 4; `test-libs` and the gate run in place in a worktree.
