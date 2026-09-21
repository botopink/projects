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
| [77](#77-renderhooks-keeps-the-dependency-direction) | onze's inverted seams | `RenderHooks` in rakun, filled by `Onze.run`; `islandAttr` in jhonstart; waves from the dependency lines |
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
| [89](#89-future-is-unwrapped-for-the-context-owner) | `use` in `-> @Future<Element>` | (a) unwrap `@Future<T>`; `request()` is `-> @Context<Element, Request>` |

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

**Implemented 2026-09-20 on `feat` `81e10a18`** (`02-packaging` step 1) with one spelling detail: the pin is the existing `branch | tag | rev` (exactly one), not a literal `ref` — bpmp's clone needs the pin's kind, and a second spelling would be the knob decision 67 refuses. `path` is honoured; `{ "workspace": true }` is the sibling form.

## 77. `RenderHooks` keeps the dependency direction

**Decided 2026-09-20 by the maintainer: (a).** rakun (front 23) defines `RenderHooks(headExtra,
islandAttr, …)`; `Onze.run` fills it; `islandAttr` is defined in jhonstart. The three 1.0.9 seams that
reached from rakun/jhonstart into onze are removed, and the onze waves are re-stated from the
`Depends on` lines (`49 → 68 → 69 → 52 → 51 → 70 → 71 → 50 → 53`). Amends the `Owns:` lines of 23 and 29.

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
This amends front 19's *rule for libraries* (a component was "any `fn … -> Element`") and is a sweep
over `04-jhonstart/**` examples and maps, tracked in `status.md`.

**Implemented 2026-09-20 on `fix/use-activation` (front 19 step 1)** as the existing lowercase effect
`#[@context]` — every effect annotation is lowercase (`#[@future]` → `@Future`), `#[@Context]` with a
capital is an unknown annotation silently ignored, and no alias was added (decision 67). A body that
activates a hook without it is `use-without-context-effect`. The collision with R5 on server components
is question 90.

## 89. `@Future` is unwrapped for the context owner

**Decided 2026-09-20 by the maintainer: (a).** `contextInfoFromReturn` looks through `@Future<T>` (and
only `@Future`) and takes `T`'s owner, so `#[@future] fn … -> @Future<Element>` has owner `Element`
and `request()` is declared `-> @Context<Element, Request>`. A client hook becomes type-legal in a
server component; the client boundary (front 29's `#[client]`, decision 87) is the rule that says
which hooks a server body may activate. Closes `language-gaps.md` row 53.

## 90. A wrapper effect whose return owns a context activates on its own

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
| `#[@asyncGenerator] fn … -> @AsyncGenerator<T>` | `await` · `try` · `yield` | `@AsyncGenerator` ⊃ `@Future` ⊃ `@Result` |
| `#[@future] fn … -> @Future<T, E>` | `await` · `try` | `@Future` ⊃ `@Result` |
| `#[@generator]` · `#[@iterator]` | `try` · `yield` | `@Generator` / `@Iterator` ⊃ `@Result` |
| `#[@result] fn … -> @Result<T, E>` | `try` | — it is the base |

The rule that orders them, decided with the table: **every effectful body can fail**, so every
wrapper implements `@Result`; and a wrapper that suspends (`@Context`, `@AsyncGenerator`) implements
`@Future`. `yield` stays exclusive to the three generator wrappers and `use` stays exclusive to
`@Context` — the chain grants downwards, never upwards.

`@Future<T, E = any>` already carries the error channel this needs (`builtins.d.bp:115`, with
`return t` auto-wrapping to `Future.resolved(t)` and `throw e` to `Future.rejected(e)`), so
`@Future<T, E>` implementing `@Result<T, E>` adds no parameter and invents no error type.

What it does **not** change: R5 stands — one effect annotation per fn, and the chain is what makes
that sufficient rather than restrictive, since the highest annotation already grants the rest.
Decision 88 stands: a component is `#[@context] fn … -> Element`, and `Element` implements
`@Context`. Decision 90 stands: a wrapper effect whose unwrapped return owns a context activates
hooks without `#[@context]`, which is the one case the chain cannot spell because R5 forbids writing
two annotations.

Bears on: question 91 (whether the context-owner unwrap widens past `@Future`) is now a question
about this chain, not about one type — the payload's owner is what decides; question 93
(`@getContex` gated by `inContextFn` alone) is the same shape and should be answered with it.
Implements: the `implement` clauses in `libs/std/src/builtins.d.bp`, the `try`/`await`/`use`/`yield`
legality checks in `comptime/infer.zig`, and their refusals — a body that writes a capability above
its level is refused, located, with no flag (decision 67).
