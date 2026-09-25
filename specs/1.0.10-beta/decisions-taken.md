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
| [102](#102-contextbase-is-the-context-owner-marker-only-use-answers-usec-t-or-componentt) | What is `@Context`, and what does a `use` body return? | `@Context<Base>` is the owner marker only (`Element implement @Context<ElementBase>`); `#[@use]` returns `@Use<C, T>` or `@Component<T>` (≡ `@Use<B, T>`); the bare `-> Element` form leaves |
| [103](#103-a-generators-prefix-is-the-level-it-extends-generatort--resultgeneratort-e--futuregeneratort-e) | Generator names, channels, and question 97 | `@Generator<T>` (infallible, 97-b) · `@ResultGenerator<T, E>` · `@FutureGenerator<T, E>`; `YieldStep` the one step; `Iterator`, `Iterable`, `IteratorStep`, `Yield`, `C`, `R` leave |
| [104](#104-only-use-grants-use--decisions-89-and-90-revoked) | Who grants `use`? | Only `#[@use]`; **revokes 89 and 90**; nothing unwrapped; `inContextFn == annotated`; 91 moot, 92 (b), 93 (a); commonJS `async function` for every `#[@use]` |
| [105](#105-three-loop-keywords-and-generator-loop-is-a-generator-scope) | Loops | `loop` / `while (…)` / `for (…) { x -> }`; `#[@generator] loop { … }` is a generator scope worth its wrapper; `yield v` emits, `break v` emits and ends, only there; a plain fn's loops are statements |
| [106](#106-std-in-three-categories-a-pure-root-io-and-testing) | The shape of std | Pure root · `io/` · `testing/`; a root module imports nothing from `io/`; merge only where the name wins (`collections`, `hash`, `encoding`); 71 amended in path only |
| [107](#107-import-a-dotted-path-and-a-braced-group-are-one-tree-and-only-the-leaf-enters-scope) | Import grammar | `import {a: {b: {c}}, x.y.z, e.t.r*}` — dotted path and braced group are one tree; only the leaf enters scope; `*` / `as` on the leaf; no `from` = the package root |
| [108](#108-getcontex--getcontext) | `getContex` | Renamed `getContext` (99-a) |
| [109](#109-the-declaration-boundary-in-a-module-atom-is--and-the-declaration-keeps-its-case) | How is a per-declaration BEAM module named? | `<path>@@<Decl>` — `@@` is the boundary, the path stays lowercase, the declaration keeps its case (`pond@@PatoNada` for `val PatoNada = implement …`); A2's `__t__`/`__b__` qualifiers leave |
| [113](#113-the-libraries-split-by-concern-emilia-is-css-jhonstart-is-html-rakun-is-the-service-on-erlang-onze-wires-them) | Which library owns what, and who may import whom? | emilia CSS · jhonstart HTML · rakun the service, erlang first · onze wires them; jhonstart ⇄ rakun never import each other; the render and `RenderHooks` move to jhonstart; `ElementView` leaves; markers `data-jh-*`; globals `__bp<N>` from a registry; emilia enters through `jhonstart-emilia`; answers 94, 100, 101; amends 77 |

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

## 109. The declaration boundary in a module atom is `@@`, and the declaration keeps its case

**Decided 2026-09-26 by the maintainer**, on his own proposal: *"poderia usar `@@` — `io@fs@@File` — quando
for um módulo interno"*. Policy 3 (front 13, half 2) emits one BEAM module per `type` and per
`implement`, and A2 named that module by appending a qualifier to the owning module's atom:
`main__t__sourcelocation`, with `__b__` reserved (decision 23). The qualifier is replaced by one
boundary token:

```
atom(module)       = lowercase(path), '/' → '@', [^a-z0-9_@] → '_'     (option A, unchanged)
atom(decl)         = atom(module) ++ "@@" ++ <Decl>                      (case kept)
```

`<Decl>` is the declaration's own name: a `type`'s, or the `val` an `implement` is bound to.

| Source | Atom |
|---|---|
| `type SourceLocation` in `src/main.bp` | `main@@SourceLocation` |
| `type File` in `src/io/fs.bp` | `io@fs@@File` |
| `val PatoNada = implement Swimmer for Pato { … }` in `src/pond.bp` | `pond@@PatoNada` |
| `type Pato(…) implement Swimmer { … }` (inline clause) | `pond@@Pato` — the clause belongs to the type's module |

Three properties decide it, each measured against the A2 spelling it replaces:

1. **`@@` cannot collide.** A path segment is never empty, so `@@` never occurs in `atom(module)`;
   and the sanitiser maps every foreign character to `_`, so a source name containing `__t__` is
   ambiguous to A2's decoder while no source name can produce `@`. The decoder is `split("@@")`,
   with no qualifier table.
2. **The declaration keeps its case.** A2 lowercased the whole atom, so `SourceLocation` reached
   the BEAM as `sourcelocation` and the atom stopped decoding back to its source — the property A2
   was written for. `main@@SourceLocation` is still a legal *unquoted* atom: it starts with a
   lowercase letter and holds only `[a-zA-Z0-9_@]` (E10). The module half stays lowercase because
   it is also a directory and file name.
3. **One rule for every declaration kind.** An `implement` block is a module under policy 3 and A2
   had no qualifier for it; under 109 it is named by the `val` that binds it, like a `type` is
   named by its own name. A behavior module, if decision 23 is ever reopened, is
   `<path>@@<Behavior>` like everything else, so the `__b__` reservation has nothing left to do.
   Should the language ever nest a declaration inside another, each `@@` descends one level;
   no construct does today.

What it does **not** change: option A for the module half; decision 6's flat `out/erl/` and
`out/beam/` (the file is still the atom: `io@fs@@File.erl`, and `@` was already in file names);
decision 21's T2 tag (the same atom is the value's identity on every backend, so
`{'io@fs@@File', …}` and the commonJS/wasm identity string are one spelling — front 13 step 1's
"one canonical identity, one renderer per backend"); decision 23 (a behavior emits nothing); the
`bp@comptime@…` atoms of template evaluations. The cross-module refusal that two declarations of
one module must not render one atom stays, and stays **case-insensitive**: `Person` and `person`
are distinct atoms but one file on a case-insensitive file system, so the pair is refused
(decision 67).

Bears on: the ≈ 188 erlang and beam snapshots policy 3 re-recorded, which move again by the atom
spelling alone; `crossModule.zig`'s `duplicate_decl` check and message; `13-module-identity`'s A2
text (`declaration-qualifier.md`), which now describes this spelling.
Implements: front 13 — the one renderer per backend (`erlang.zig`, `beam_asm.zig`, the commonJS
and wasm identity string), the decoder, the snapshot re-record, `src/codegen/AGENTS.md`.

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
