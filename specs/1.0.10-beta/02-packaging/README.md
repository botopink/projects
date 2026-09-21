# Front 02 — packaging: the module and example structure of every library

**Track:** cross-cutting (A std · B rakun · C jhonstart · D emilia · E onze) — the packaging half of 1.0.9's front 95; the std/asserts half is [`../01-std/`](../01-std/)
**Priority:** high — every library front of this milestone writes into a directory this front creates, and every `-test` submodule and example project is invisible to the gate until the discovery change here lands
**Target:** none of its own — a structural front; each submodule and example declares the target its library is assigned (`overview.md` § Which target runs what)
**Wave:** 1, **alongside each library's first front** (rakun 04 · jhonstart 94 · emilia 54 · onze 49), after `01-std` (wave 0)
**Depends on:** `01-std` (the `onze` directory is free, `std/asserts` and `std/snapshots` exist, `@src()` is specified) · read-only: `00 · 10-cli-residuals` for the discovery carve-out, if needed
**Owns:** the rows of `02-packaging` in [`../fronts.md`](../fronts.md): every `repository/<lib>/botopink.json`, every `modules/<lib>/` and `modules/<lib>-test/` skeleton, every `examples/<project>/botopink.json`, `repository/botopink-lang/scripts/test-libs.sh`, `scripts/known-red-libs.txt`, `docs/botopink-json.md`, and — by carve-out — `modules/lib-test-runner/src/discovery.zig`
**Does not touch:** `libs/std/src/**` (01-std) · the source files inside any submodule (their fronts) · `repository/botopink-lang/modules/compiler-core/**` and `compiler-cli/**` (00) · the per-library cut beyond the three mandatory directories — that is each library's `modules.md`
**Reference:** `repository/rakun/modules/README.md` and the thirteen `modules/rakun-*/botopink.json` at HEAD · `repository/botopink-lang/modules/compiler-cli/src/cli/{config,libs}.zig` (what a manifest means to the compiler) · `modules/lib-test-runner/src/discovery.zig` (what the gate can see) · `libs/std/AGENTS.md` § Tests · Spring Boot 4 starters (`/home/ericfillipe/develop/spring-boot-4/docs/02-desenvolvendo-com-spring-boot.md` § Starters) · Next.js project structure (`NEXTJS-DOCS.md` § 3) · Tailwind's package cut (`TAILWIND_CSS_DOCS.md` § 2: one core, three integration packages)
**Replaces:** the packaging half of [`95-ecosystem-package-restructure/`](./95-ecosystem-package-restructure/README.md), carried verbatim beside this file

---


> **Decision 75 was re-shaped on 2026-09-20:** the maintainer asked for an npm-`workspaces`-style counter-proposal — a `"workspaces": ["modules/*", "examples/*"]` array in the umbrella `botopink.json`, members named by their own manifests, `{ "workspace": true }` as the only sibling dependency. It is written in [`../decisions-pending.md` § 75](../decisions-pending.md#75-how-test-libs-and-the-dependency-loader-see-modules-and-examples--a-workspaces-manifest-npm-style) and, once taken, replaces routes A/B in § Mechanism below. Decision [76](../decisions-taken.md#76-dependencies-is-the-object-form-only) (object form only) is taken.

## Problem

Front 95 said every library gets `modules/` + `examples/` and stopped at a picture. Four things the
picture did not say, each measured against the tree and the compiler at HEAD:

1. **The compiler cannot see a submodule.** `from "rakun-web"` resolves by *name* across the root
   list — `BOTOPINK_LIB_ROOTS`, then for each ancestor `D` of cwd `D/repository/botopink-lang/libs`,
   `D/repository`, `D/libs`, then `.botopinkbuild/deps/` — and takes the first root with
   `rakun-web/botopink.json` as an **immediate child** (`compiler-cli/src/cli/libs.zig:loadOne`).
   `repository/rakun/modules/rakun-web/` is a child of no root. The `"path": "../../"` that every
   rakun submodule manifest already writes is parsed into `DepSpec.path` (`config.zig`) and **never
   read** by the loader.
2. **The gate cannot see a submodule or an example either.** `botopink-lib-test` discovers
   `<root>/*/botopink.json` (`lib-test-runner/src/discovery.zig:discover`), one level deep. Today
   `zig build test-libs` reports six libraries; the thirteen scaffolded rakun submodules and the seven
   existing example projects are not cells.
3. **A dependency's `entry` is never followed.** The loader reads only `src` and `files` of a
   dependency's manifest (`LibManifest`) and ships each listed file as `<dep>/<stem>`. Every
   `modules/rakun-*/botopink.json` declares `"entry": "root.bp"` and no `files`, so a consumer that
   did resolve one would get **zero modules**. `entry` is what the resolver follows for the package
   being *built*; `files` is what a *consumer* sees.
4. **`bpmp` rejects the object form.** `modules/bpmp/src/manifest.zig:85-96` returns
   `ManifestInvalid` unless `dependencies` is a string array; the compiler and the language server
   accept both. Every example manifest and every rakun submodule manifest is already in object form.

None of these is a library's problem to solve twice. This front states the shape once, states the
discovery mechanism the shape needs, and hands each library its `modules.md` to refine the cut.

## Current state

Measured by reading the trees on 2026-09-20.

| Repository | `botopink.json` shape | `modules/` | `examples/` | Tests |
|---|---|---|---|---|
| `rakun` | `name rakun`, `src src/`, `targets ["commonJS"]`, `files [http, runtime, decorators, bootstrap, rakun.d]` | **13** submodules, each `botopink.json` (`name rakun-<x>`, `entry root.bp`, `targets [commonJS, erlang]`, `dependencies {rakun: {path: ../../}}`, **no `files`**) + `src/root.bp` (a comment) + empty `test/` | `examples/rakun/` (`rakun-app`, git dep on `rakun` branch `feat`) | `test/{di,overlapping_routes,router,scopes,server}_test.bp` |
| `jhonstart` | `files [element, hooks, html, router.d, server.d]`, `targets [commonJS, erlang]` | none | `examples/{jhonstart-app,jhonstart-counter,jhonstart-html,jhonstart-todo}/` — three with a manifest (git dep, branch `feat`), `jhonstart-app` without one | `test/html_test.bp` |
| `emilia` | `files [root, tokens, emilia]`, `targets [commonJS, erlang]` | none | `examples/emilia-card/` (git deps on `jhonstart` + `emilia`) | inline `test` blocks in `src/*.bp` |
| `onze` (mocking) | `files [onze.bp]`, `targets [commonJS, erlang]` | none | `examples/onze/` (`onze-demo`) + a loose `examples/mock_synthesis.bp` | `test/onze_test.bp` |
| `erika` | `files [root, erika]`, `target commonJS` | none | `examples/erika-linq/` | inline |
| `libs/std` | `entry root.bp`, `files [primitives, builtins.d, builtins_fns.d]` | — (std is not a package tree) | — | inline in `src/*.bp`; `test/` compiles against the ambient global env (`libs/std/AGENTS.md`) |

Every `examples/*/out/` directory is committed build output (`out/jhonstart/element.js`, …). It is
what the old `git` dependency form produced; the path form below makes `out/` reproducible and it
stops being committed.

## Mechanism

### 1. The shape — one pattern, every library

```
repository/<lib>/
├── botopink.json                  the umbrella manifest: name, version, targets; no `files`
├── AGENTS.md
├── modules/
│   ├── <lib>/                     CORE — what `from "<lib>"` gives a consumer
│   │   ├── botopink.json          name <lib>, files [...], targets, dependencies (std is implicit)
│   │   ├── src/root.bp            `pub mod` tree of the core
│   │   ├── src/*.bp
│   │   ├── test/*_test.bp         flat suite; may import the package (`compiler-cli/AGENTS.md`)
│   │   └── test/__snapshots__/    contract 7 — beside the tests that write them
│   ├── <lib>-test/                ALWAYS PRESENT — assert<Subject>(loc, …) helpers, fixtures, builders
│   │   ├── botopink.json          name <lib>-test, dependencies {<lib>: {path: ../<lib>}}
│   │   ├── src/root.bp
│   │   └── test/                  the helpers' own tests + __snapshots__/
│   └── <lib>-<domain>/            WHERE WARRANTED — cut at a consumption boundary, not by file count
│       ├── botopink.json          name <lib>-<domain>, dependencies {<lib>: {path: ../<lib>}, …}
│       ├── src/root.bp
│       └── test/ (+ __snapshots__/)
└── examples/
    └── <project>/                 a RUNNABLE PROJECT, not a snippet
        ├── botopink.json          name <project>, entry, target, dependencies by PATH
        ├── src/main.bp            (or app/ for an onze app)
        ├── test/*_test.bp         + __snapshots__/ — an example is tested like a module
        └── README.md              what it demonstrates and the upstream section it mirrors
```

Three mandatory directories per library — `modules/<lib>/`, `modules/<lib>-test/`, `examples/` — and
the rest is the library's call. The three rules of front 95 still govern the cut, restated with the
reference each comes from:

- **Every package has a `<lib>-test` submodule.** Spring ships `spring-boot-starter-test` beside
  every starter; Next.js ships nothing and every project reinvents its test harness. The first is
  the model. `<lib>-test` depends on its core and on std, and a consumer that wants to test *against*
  a library adds `<lib>-test` — never `<lib>`'s own `test/`.
- **A submodule is cut at a consumption boundary.** Spring's starters are the reference: `-web`,
  `-data-jpa`, `-security`, `-actuator`, `-cache`, `-validation`, `-amqp`/`-kafka`, `-quartz`,
  `-mail`, `-websocket`, `-hateoas` each name a thing a consumer takes without the rest, and Spring's
  third-party rule (`<project>-spring-boot-starter`) is what `<lib>-<domain>` mirrors. Tailwind is
  the counter-reference: one core (`tailwindcss`) and three integration packages
  (`@tailwindcss/vite`, `@tailwindcss/postcss`, `@tailwindcss/cli`) — the utilities are one surface.
  `emilia` follows Tailwind, `rakun` follows Spring, `jhonstart` and `onze` sit between (Next.js
  exposes `next/link`, `next/image`, `next/font`, `next/navigation` as entry points of **one**
  package; the analogue is a submodule only where the target profile differs).
- **The core owns `from "<lib>"`.** The umbrella `repository/<lib>/botopink.json` has **no `files`**:
  nothing is importable from the umbrella. `from "<lib>"` resolves to `modules/<lib>/`; `from
  "<lib>-web"` to `modules/<lib>-web/`. A consumer never reaches into another package's `src/`.

### 2. Manifests — the fields the compiler actually reads

`compiler-cli/src/cli/config.zig` parses `name`, `version`, `target`, `entry`, `dependencies`,
`files` (and ignores everything else); `libs.zig:LibManifest` reads a **dependency's** `src` and
`files` only; the lib-test runner reads `targets`; `bpmp` reads `botopink` and `requires`. So:

| Field | Umbrella `repository/<lib>/` | Module `modules/<lib>[-x]/` | Example `examples/<p>/` | Read by |
|---|---|---|---|---|
| `name` | `<lib>` | `<lib>` or `<lib>-<x>` — this **is** the import name | `<p>` | compiler, runner, bpmp |
| `version` | the library's | the same, every submodule | `0.0.1` | bpmp |
| `description` | one line | one line, ending in the target profile | one line, naming the upstream section | — |
| `src` | omitted | `src/` (default) | `src/` or `app/` | compiler |
| `entry` | omitted | `root.bp` — followed when this package is **built/tested** | `main.bp` | resolver |
| `files` | **omitted — nothing importable from the umbrella** | every module a **consumer** may import, `root.bp` first — the only thing the loader ships | omitted | `libs.zig:loadOne` |
| `target` | the library's assigned target | the submodule's | the example's | `botopink build/run/test` default |
| `targets` | the whitelist the runner honours | narrower where a submodule is single-target (`onze-cli`: `["erlang"]`; `jhonstart-client`-style code: `["commonJS"]`) | the example's | `botopink-lib-test` |
| `dependencies` | omitted | object form, **path** to siblings: `{"<lib>": {"path": "../<lib>"}}`; std is implicit and never listed | object form, path to each library core it uses: `{"rakun": {"path": "../../modules/rakun"}, "jhonstart": {"path": "../../../jhonstart/modules/jhonstart"}}` | compiler (`DepEntry`), LSP; **not bpmp** (gap) |
| `botopink`, `requires` | omitted until a release | omitted | omitted | bpmp only |

Two consequences that are rules, not advice:

- **`files` is mandatory on every module manifest.** The thirteen rakun submodule manifests at HEAD
  have `entry` and no `files`; each gets `"files": ["root.bp", …]` listing every module a consumer
  may import. A submodule whose `files` is empty is unusable and `zig build test-libs` says so
  (the `–` cell compiles it and nothing imports it).
- **The path form, not the git form, inside the ecosystem.** `"git": …, "branch": "feat"` (1.0.7's
  "version pinning during development") is what every example writes today, and it is why every
  example commits its `out/`: the compiler does not fetch, `bpmp` does, and `bpmp` rejects the object
  form. A path dependency is resolved from the checkout, every example builds under the gate, and
  `out/` leaves git. The git form is for a consumer **outside** the ecosystem, after a release.

And one caveat the mechanism must state honestly: **the compiler resolves a path dependency by
name, not by path** (Problem 1). Until `00 · 10-cli-residuals` teaches `loadOne` to honour
`DepSpec.path`, the path field documents intent and the **root list** does the resolving — which is
§ 5's job.

### 3. `<lib>-test` — what it exposes, and on what it stands

```bp
//// <lib>-test — test helpers for <lib>.
////
//// Depends on: std (asserts, snapshots), <lib> (core)
//// Target: <lib>'s assigned target

import { asserts, snapshots } from "std";
import { Token, Theme, defaultTheme } from "emilia";

// One assert<Subject>(loc, …) per thing the library produces. The location is
// @src() at the call site (contract 7); the helper never computes a path itself.
pub fn assertCss(loc: SourceLocation, tokens: Token[]) -> @Result<void, string> {
    val css = emiliaToCss(tokens, defaultTheme());
    return snapshots.assertSnapshot(loc, css);
}

// Builders and fixtures — where most of the value is.
pub fn sampleTheme() -> Theme { … }

// No re-implementation of std: a `-test` that defines its own `equal` is a bug.
```

Rules, each checkable:

- **`assert<Subject>(loc, …) -> @Result<void, string>`** is the only helper shape. `loc` is the
  first parameter, always a `SourceLocation` from `@src()`, and the helper hands it to
  `snapshots` unchanged. A helper that takes a path string is wrong.
- **`__snapshots__/` lives beside the tests that write it** — `modules/<x>/test/__snapshots__/`
  for a module, `examples/<p>/test/__snapshots__/` for an example, and, for a library whose tests
  are inline (`emilia`, `std`), `src/__snapshots__/`. `snapshots.path(loc)` derives it from
  `loc.file`; nothing configures it.
- **A `-test` submodule re-exports nothing from std.** Front 95's example re-exported `truthy`,
  `equal`, … "so consumers import one module"; contract 7 and `01-std/asserts-api.md` make std the
  one place a predicate lives. A consumer writes `import { asserts } from "std"` beside
  `import { assertCss } from "emilia-test"`.
- **Mocking is documented, not shipped, until a front needs it.** The `#[mock]` + `#[bean]`
  convention and the host runtime of the old `onze` are [`../deferred.md`](../deferred.md) §
  ecosystem's row; the first `-test` submodule that needs a mock adopts it into its own `src/`.
- **The per-library `test-snap.md` is the map.** Every `assert<Subject>` a `-test` exposes, every
  test that calls it, and the exact `.snap` path it produces are enumerated in
  `0N-<lib>/test-snap.md`; `test-snap-examples.md` does the same for `examples/**`.

### 4. Examples are projects, tested like modules

An example is `repository/<lib>/examples/<project>/` with its own `botopink.json`, and it is a cell
of the gate: it compiles on its declared target and its `test/` runs. Next.js's project structure
(`app/`, `public/`, `next.config.js`, `package.json`) is the model for an `onze` example; a rakun or
jhonstart example is `src/main.bp` plus what it demonstrates. Three rules:

- **An example depends on libraries by path, and may depend on several** — `emilia-card` already
  depends on `jhonstart` and `emilia`; an `onze` example depends on all four. The direction rule in
  § 6 applies to the example as a consumer.
- **An example carries a `README.md`** naming the upstream section it mirrors (`overview.md` § Mapping
  the three sources) and the front whose feature it exercises. An example with no upstream section is
  an example nobody asked for.
- **`examples/<lib>-<thing>/`** is the name (`jhonstart-counter`, `emilia-card`, `rakun-app`,
  `onze-blog`) — the library first, so the flat listing across repositories reads.

The loose `examples/mock_synthesis.bp` in the old `onze` and the manifest-less
`jhonstart/examples/jhonstart-app/` are not examples under this rule: the first goes with the
mocking library, the second gets a manifest or moves under a front's `examples/` in the spec.

### 5. Discovery — what `zig build test-libs` and `botopink test` see, and the change

**Today.** `zig build test-libs` runs `scripts/test-libs.sh`, which execs
`zig-out/bin/botopink-lib-test`. The runner resolves roots (`BOTOPINK_LIB_ROOTS` entries → for each
ancestor `D` of cwd: `D/repository/botopink-lang/libs`, `D/repository`, `D/libs` → `--lib-root`
entries; de-duplicated, first-root-wins by name), takes every **immediate** subdirectory of a root
that holds a `botopink.json` as a lib, decides "has tests" by `test/*.bp` (non-`.d.bp`) or a
`src/**/*.bp` containing a `test` block, reads the manifest's `targets` whitelist, and spawns
`botopink test --target <t>` with cwd set to the lib (or `botopink build --target <t>` for a lib
with no tests — a library that never wrote a test still cannot break silently). One cell per
lib×target; `✗` is the only status that fails the run; `scripts/known-red-libs.txt` names a red cell
with the front that owns it. `botopink test` itself reads `botopink.json`, `src/`, the flat `test/`
(not a package, but it may import the package) and the declared dependencies, and runs each test
module through `node` or `escript`.

**The change.** Two routes, the first preferred because it needs no compiler-side edit:

| Route | Change | Where | Cost |
|---|---|---|---|
| **A — roots** | `scripts/test-libs.sh` exports `BOTOPINK_LIB_ROOTS` = every `repository/<lib>/modules` and `repository/<lib>/examples` it finds (`for d in repository/*/modules repository/*/examples`), prepended to whatever the caller set. Every submodule and example becomes an immediate child of a root, for the runner **and** for the compiler's `loadOne` — which is what makes `from "rakun-web"` and a path dependency resolve at all | `scripts/test-libs.sh` (this front's file) | none in Zig; the name-uniqueness rule below |
| **B — nested discovery** | `discovery.discover` also walks `<root>/<lib>/modules/*` and `<root>/<lib>/examples/*` when the lib's directory has them, naming each cell by its manifest `name` | `modules/lib-test-runner/src/discovery.zig` (carve-out of `00 · 10-cli-residuals`) | the compiler still does not resolve `from "rakun-web"` without route A's roots |

Route A is the mechanism; route B is taken only if the umbrella-vs-core naming (below) forces it.
Either way the gate's listing becomes the acceptance: `zig build test-libs` prints one cell per
submodule and per example, and a submodule that is not printed is not tested.

**Name uniqueness is the price of route A.** The runner and the loader key by directory name,
first-root-wins. `repository/rakun/` (the umbrella) and `repository/rakun/modules/rakun/` (the
core) both answer to `rakun`. The rule: the **umbrella has no `files`** and is never a dependency
target, and the roots are ordered `modules` first — so `rakun` resolves to the core. The umbrella
still carries a `botopink.json` (the runner needs it to see the directory at all) whose `targets` is
the library's whitelist and whose `files` is absent; the runner's `–` cell for it compiles nothing
(`has_sources` false) and stays green.

**`botopink test` inside a submodule** needs no change: cwd is the submodule, `src/` and `test/` are
its own, and `dependencies` resolves through the same roots. This is also how a developer runs one
submodule's tests by hand.

### 6. Dependency direction

Carried from 1.0.7's *Cross-repo Coordination* (the only place the inter-library graph was written)
and extended to submodules. An edge is a `dependencies` entry; the graph is acyclic and the gate
checks it by building.

```
std  ◄──  <lib>  ◄──  <lib>-<domain>  ◄──  <lib>-test  ◄──  examples/<project>
                                                            (and any -test of a library above it)

libraries:   emilia ──► jhonstart (Element)          rakun ──► (nothing)
             onze ──► rakun, jhonstart, emilia        jhonstart ──► (nothing)
```

| Rule | Why |
|---|---|
| A core depends on std and on other libraries' **cores** only — never on a submodule, never on a `-test` | The core is what `from "<lib>"` means; a core that needs `rakun-web` has the wrong cut |
| A domain submodule depends on its core, on std, and on other domain submodules of the **same** library (`rakun-actuator` → `rakun-actuator-api`, contract 5c) — never on another library's submodule | Cross-library edges are between cores, so a library is one node in the graph above |
| `<lib>-test` depends on its core, on std, and on the domain submodules it asserts over; **a core never depends on `-test`** | Test helpers see the library; the library does not see its helpers — an import of `<lib>-test` from `src/` is a build error the gate produces by construction (no root carries a `-test` under `src/`'s dependencies) |
| A `-test` may depend on a lower library's `-test` (`onze-test` → `rakun-test`, `jhonstart-test`) | `onze` tests reach the server through `rakun-test`'s request double (front 19); [`../deferred.md`](../deferred.md) records why there is no shared double |
| An example may depend on **several** libraries, always on cores or `-test`s, always by path | `emilia-card` → `jhonstart` + `emilia` today; `onze-blog` → all four |
| `std` is never listed | It is embedded; listing it is a resolver error today and stays one |
| No edge from any library into `repository/botopink-lang/**` | The compiler knows none of this (`overview.md` § Rules) |

Direction between libraries is unchanged from 1.0.7: `emilia` depends on `jhonstart` for `Element`
(front 48), `onze` depends on the other three, `rakun` and `jhonstart` depend on nothing but std.

### 7. The `onze` name takeover

The order is fixed by [`../fronts.md`](../fronts.md) § Conflict rules: `01-std` removes
`repository/onze/` (the mocking library — its predicates are in `std/asserts`, its runtime is a
`deferred.md` row); then this front creates `repository/onze/` as the orchestrator umbrella with the
five-to-six skeleton submodules (`onze`, `onze-test`, `onze-cli`, `onze-bundler`, `onze-assets`,
`onze-release` — `06-onze/modules.md` decides whether release is its own); then front 49 fills
`modules/onze/src/`. The two never hold the directory at once, and `grep -rl onze13 repository` is
empty from the first commit of this front — as is every `**Owns:**` line and every manifest `name`
under `specs/1.0.10-beta/`; the carried front 95 and `unification.md` keep the old name as history.

## Per-library proposal — the starting point

**To be refined by each library's `modules.md`** (`../03-rakun/modules.md`, `../04-jhonstart/modules.md`,
`../05-emilia/modules.md`, `../06-onze/modules.md`). This table is what front 95 and the 1.0.9
ownership rows imply; the library agent owns the final cut and the front → directory table that
[`../fronts.md`](../fronts.md) copies.

| Library | Core | `-test` | Domain submodules (proposed) | Cut follows |
|---|---|---|---|---|
| **rakun** | `rakun` — DI, `#[bean]`/`#[configuration]`/`#[value]`, `App`, bootstrap, config/profiles (05), context (06), the file router and SSR spine (22–25, 60–66, 72, 74) | `rakun-test` — `FakeRequest`, `MockMvc`, context reset, broker double (front 19) | `rakun-web` (07, 20, 65, 82) · `rakun-data` (08, 09, 77, 78, 83) · `rakun-security` (10, 79) · `rakun-actuator` + `rakun-actuator-api` (11, 76, 87) · `rakun-cache` (12) · `rakun-client` (13) · `rakun-validation` (14) · `rakun-messaging` (15, 86, 89–91) · `rakun-scheduling` (16, 84) · `rakun-logging` (17) · `rakun-session` (18) · `rakun-hateoas` (21) · and the 1.0.9 rows that name more: `rakun-i18n` (64), `rakun-starters` (73), `rakun-metrics`/`observability` (75), `rakun-devtools` (80), `rakun-release` (81), `rakun-tx` (83), `rakun-mail` (85), `rakun-cli` (88), `rakun-stream` (89), `rakun-rsocket` (92), `rakun-ws` (93) | Spring starters, one per `spring-boot-starter-*` a consumer takes alone |
| **jhonstart** | `jhonstart` — `Element`, hooks, rendering, router (26), server components (28), streaming (30), boundaries (31), metadata (32), elements (94) | `jhonstart-test` — render helpers, element comparison, `assertElement(loc, …)`, `assertHtml(loc, …)` | `jhonstart-html` (the `html` DSL — 95's proposal, the byte-equality tests live there) · `jhonstart-forms` (67 — js-target, so a different target profile) · `jhonstart-router`? — 95 said no (one file, coupled to the core); `04-jhonstart/modules.md` decides | Next.js entry points: one package, a submodule only where the target profile differs (`'use client'` code is commonJS-only) |
| **emilia** | `emilia` — tokens, every `<section>TokenToCss`, theme (54), preflight (55), cascade/output (56), escape hatches (57), containers (58), compose (59), attributes (48) | `emilia-test` — `assertCss(loc, tokens)`, `assertSheet(loc, …)`, `sampleTheme()`, the contract-4 literal fixture | `emilia-theme`? · `emilia-modifiers`? — 95 said **two submodules only**; the theme and the modifiers are layers of one pipeline and no consumer takes one without the others. Listed because the plan named them; `05-emilia/modules.md` confirms or refuses | Tailwind: one core, integrations apart. The integration here is front 48's html hook, which is part of the core because it is the only consumer |
| **onze** | `onze` — orchestrator types, config, integration layer (49), the styling seam (69) | `onze-test` — app scaffolding helpers, route-table assertions, `assertRouteTable(loc, …)`, `assertPayload(loc, …)` | `onze-cli` (50) · `onze-bundler` (68) · `onze-assets` (51, 52, 69, 70) · `onze-release` (71) · `onze-pipeline`? — the plan named it; if it is 69's styling seam it belongs in `onze-assets` as 1.0.9's rows already say | Next.js `next` + `create-next-app`: the CLI and the bundler are what a deploy takes without the other |
| **std** | — (not a package tree; `libs/std/src/*.bp` with `pub mod` in `root.bp`) | — (`asserts` and `snapshots` **are** the test surface every `-test` stands on) | — | `01-std/` |

**rakun already has thirteen scaffolded submodules** under `repository/rakun/modules/` —
`rakun-actuator`, `rakun-cache`, `rakun-client`, `rakun-data`, `rakun-hateoas`, `rakun-logging`,
`rakun-messaging`, `rakun-scheduling`, `rakun-security`, `rakun-session`, `rakun-test`,
`rakun-validation`, `rakun-web` — each with `botopink.json` (`entry root.bp`, `targets [commonJS,
erlang]`, `dependencies {rakun: {path: ../../}}`, no `files`), a `src/root.bp` holding a comment, and
an empty `test/`. `../03-rakun/modules.md` must reconcile them with the 1.0.9 ownership rows, which
name eleven more (`rakun-i18n`, `rakun-starters`, `rakun-metrics`, `rakun-observability`,
`rakun-devtools`, `rakun-release`, `rakun-tx`, `rakun-mail`, `rakun-cli`, `rakun-stream`,
`rakun-rsocket`, `rakun-ws`, plus `rakun-actuator-api` from contract 5c) and one inconsistency
(`75` owns `modules/rakun-metrics/**` and tests `modules/rakun-observability/test/**`). The core
`modules/rakun/` does not exist and `rakun-core` is what `modules/README.md` calls `../src/`.

## Carried from 1.0.6-beta — module ↔ Spring starter

`specs/1.0.6-beta/overview.md` § Mapeamento, re-pointed at 1.0.9 front numbers. It is the
consumption-boundary argument for the rakun cut, and `repository/rakun/modules/README.md` carries the
same table at HEAD.

| Spring Boot 4 | rakun module | Fronts |
|---|---|---|
| `spring-boot-starter` — auto-configuration, logging, YAML; `SpringApplication` | `rakun` (core) | 04 · 05 · 06 · 72 |
| Externalized config, profiles | `rakun` (core) | 05 |
| `-webmvc` / `-webflux` — MVC, filters, CORS, WebSocket, static resources | `rakun-web` | 07 · 20 · 65 · 82 |
| `-data-jpa` / `-data-jdbc` / `-data-mongodb` / `-data-redis` — SQL, NoSQL, migrations, entities | `rakun-data` | 08 · 09 · 77 · 78 |
| `-security`, `-security-oauth2-client`, `-security-saml2` | `rakun-security` | 10 · 79 |
| `-actuator` | `rakun-actuator` (+ `-api`) | 11 · 76 · 87 |
| `-cache` | `rakun-cache` | 12 |
| `RestClient` / `WebClient` | `rakun-client` | 13 |
| `-validation` | `rakun-validation` | 14 |
| `-amqp` / `-kafka` / `-activemq` / `-artemis` / `-pulsar` / `-rsocket` / `-integration` | `rakun-messaging` (+ `rakun-stream`, `rakun-rsocket`) | 15 · 86 · 89 · 90 · 91 · 92 |
| `-quartz`, `@Scheduled` | `rakun-scheduling` | 16 · 84 |
| logging | `rakun-logging` | 17 |
| `-session-data-redis` / `-session-jdbc` | `rakun-session` | 18 |
| `-test` | `rakun-test` | 19 |
| `-hateoas` | `rakun-hateoas` | 21 |
| `-mail` | `rakun-mail` | 85 |
| `-webservices` | `rakun-ws` | 93 |
| Erlang/BEAM runtime (no Spring analogue — the JVM) | `rakun` (core), `src/sidecars/rakun_runtime.erl` | 04 |

## Carried from 1.0.7-beta — which library owns each Next.js surface, and convention over configuration

`specs/1.0.7-beta/overview.md` § Mapeamento Next.js → onze13, with `onze13` → `onze` and the 1.0.9
front numbers. It is the cross-library ownership argument: a feature's package is decided by which
half of the boundary runs it (`overview.md` § Which target runs what), not by which upstream package
exported it.

| Next.js | botopink | Library · front |
|---|---|---|
| React | `Element`, hooks, `html` DSL | jhonstart · 94 (+ the existing core) |
| React Server Components | `#[@future] fn → @Future<Element>` | jhonstart · 28 |
| `'use client'` | the boundary, hydrate point | jhonstart · 29; the bundle, onze · 68 |
| `next/link` | `Link` | jhonstart · 27 |
| `next/navigation` (`useRouter`) | `useRouter` | jhonstart · 26 |
| `next/image` | `Image` | onze · 51 (`onze-assets`) |
| `next/font` | font loading | onze · 52 (`onze-assets`) |
| App Router (`app/`) | `app/` convention + file router | rakun · 22 |
| `layout` / `page` / `template` / `default` | `layout.bp` / `page.bp` / … | rakun · 22, 61 |
| `loading` | `loading.bp` | jhonstart · 30 |
| `error` / `not-found` / `global-error` | `error.bp` / `not-found.bp` / `global-error.bp` | jhonstart · 31 |
| `route.ts` | `route.bp` | rakun · 25 |
| Server Actions | `'use server'` + form dispatch | rakun · 24; the client half jhonstart · 67 |
| Middleware | `middleware.bp` | rakun · 07 |
| `fetch` + cache, `'use cache'`, `revalidatePath/Tag` | the cache store | rakun · 12 |
| `generateMetadata` | `generateMetadata` | jhonstart · 32 |
| `ImageResponse` | OG image generation | onze · 70 |
| `cookies()` / `headers()` / `after()` / `draftMode()` | request context | rakun · 62 |
| `redirect` / `notFound` | navigation signals | rakun · 63 |
| `generateStaticParams`, `revalidate` | static generation | rakun · 60 |
| Tailwind CSS | `emilia` tokens | emilia · 33–59 |
| CSS Modules | `emilia` scoped classes (contract 4) | emilia · 48 |
| `create-next-app`, `next dev/build/start` | `onze create/dev/build/start` | onze · 50 |
| `next.config.js` | `modules/onze/src/config.bp` | onze · 49 |
| self-hosting, `output: standalone` | OTP release | onze · 71, rakun · 81 |

**Convention over configuration** (1.0.7's rule, absent from 1.0.9's): file-system routing,
decorator-based metadata and emilia tokens are conventions, not configuration — and so is this
front's layout. `modules/<lib>/` is the core because of its **name**, `<lib>-test` is the test
submodule because of its **suffix**, `examples/<p>/test/__snapshots__/` is where a snapshot goes
because of **where the test is**. There is no manifest field that relocates any of them, and none is
added.

## Steps

### Step 1 — The umbrella manifests and the two mandatory submodules, per library

For each of `rakun`, `jhonstart`, `emilia`, `onze` (after `01-std` has removed the old `onze`):
write the umbrella `botopink.json` (no `files`), create `modules/<lib>/{botopink.json,src/root.bp,test/}`
and `modules/<lib>-test/{botopink.json,src/root.bp,test/}`, move the existing `src/*.bp` and `test/*.bp`
into `modules/<lib>/` (rakun: the core stays in `src/` and `modules/rakun/src/root.bp` re-exports it
until `03-rakun/modules.md` moves it), list every consumer-visible module in the core's `files`.

**Acceptance:**
- [ ] `import { Element } from "jhonstart";`, `import { Token } from "emilia";`, `import { … } from "rakun";` resolve from a consumer under `scripts/test-libs.sh`'s roots — each pinned by an example that imports it
- [ ] `import { … } from "jhonstart-test";` (and emilia, rakun, onze) resolves to a module with an empty `pub` surface and one inline `test` block that passes
- [ ] `jhonstart/modules/jhonstart/test/html_test.bp` green at its new path; every emilia inline test green at its new path; rakun's five `test/*_test.bp` green through the core
- [ ] every `AGENTS.md` in a moved directory reflects the tree, same commit

### Step 2 — `files` on every existing submodule manifest

The thirteen rakun submodule manifests gain `"files": ["root.bp"]` (plus each `src/*.bp` their front
adds later — appended by that front under the append-only rule), and the object-form `dependencies`
they already carry is kept as the documented shape.

**Acceptance:**
- [ ] `import { … } from "rakun-web";` from an example resolves to `rakun-web/root` (one module, not zero)
- [ ] no `modules/*/botopink.json` in any repository lacks `files`

### Step 3 — Discovery

`scripts/test-libs.sh` exports `BOTOPINK_LIB_ROOTS` with every `repository/*/modules` and
`repository/*/examples` (route A). `scripts/known-red-libs.txt` gains one row per cell that is red at
its new path, naming the front. Route B (the `discovery.zig` walk) only if route A's name rule fails
in practice — then the carve-out is requested from `00 · 10-cli-residuals` by name.

**Acceptance:**
- [ ] `zig build test-libs` prints one `lib · target` cell for every `modules/*` and `examples/*` directory carrying a `botopink.json`, on every target its `targets` allows — the listing is diffed against `find repository -name botopink.json`
- [ ] the umbrella `rakun`/`jhonstart`/`emilia`/`onze` cells are `–` (compiled nothing, no tests) and `from "rakun"` resolves to the **core**, pinned by a test that imports `rakun` and calls a core symbol
- [ ] `zig build test-libs` exits 0 with the known-red rows in place, and every known-red row names a front number that exists in `specs/1.0.10-beta/`

### Step 4 — Examples become projects

Every existing example gets a manifest in the path form, `out/` leaves git (and `.gitignore`), a
`README.md` names the upstream section, and `jhonstart-app` gets a manifest or is moved into a
front's spec `examples/`. `examples/mock_synthesis.bp` leaves with the old `onze`.

**Acceptance:**
- [ ] every `examples/<p>/` has `botopink.json`, `README.md`, and builds under `zig build test-libs` on its declared target
- [ ] `git ls-files | grep 'examples/.*/out/'` is empty in every repository
- [ ] `emilia-card` still runs and prints what it printed before the move (verified by running, output compared)

### Step 5 — `docs/botopink-json.md`

The schema document `discovery.zig:247` cites does not exist in this checkout. Write it, from the
parsers: both `dependencies` shapes, the `path`/`git`/`branch` spec, `files` vs `entry`, `targets`
vs `target`, and the bpmp gap ([`../language-gaps.md`](../language-gaps.md) § Toolchain gaps).

**Acceptance:**
- [ ] `repository/botopink-lang/docs/botopink-json.md` exists and every field it documents is read by a named parser (`config.zig`, `libs.zig`, `discovery.zig`, `bpmp/manifest.zig`) — no field documented that nothing reads
- [ ] the three packaging rows of `language-gaps.md` cite it

## Gate

- [ ] `zig build test` green in `repository/botopink-lang` (this front changes no Zig unless route B is taken; if it is, from a cold cache)
- [ ] `zig build test-libs` green with the discovered cell list as the acceptance artefact
- [ ] `botopink format --check` clean in every moved tree
- [ ] `grep -rl onze13 repository` empty; no `**Owns:**` line, manifest `name` or directory under `specs/1.0.10-beta/` carries `onze13` (history in `unification.md` and the carried front 95 excepted)
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] one worktree per repository moved; each lands as a merge into that repository's `feat`, then the meta submodule bump — the seven remotes unified at the end (`overview.md` exit gate)

## Blast radius

Every repository moves files; no behaviour changes. What re-records: nothing — this front owns no
snapshot directory and creates only empty `__snapshots__/` locations. What goes red and is listed as
known-red until its front lands: any submodule cell whose `src/root.bp` is still a comment on a
target its `targets` allows (`–`, not red — it compiles), and the four erlang cells of
`erika/jhonstart/onze/rakun` already listed today. What a library front must redo if it lands
*before* this front: nothing, by construction — the wave rule sequences the tree before the first
front of each library.

## Notes

- The umbrella keeping a `botopink.json` with no `files` is a compromise with the runner's
  "a lib is a directory with a manifest" rule; the alternative (no umbrella manifest) makes the
  library invisible to `--lib <name>` and to the LSP's project root search. Revisit when route B
  lands.
- `path` dependencies are honest about intent and dishonest about mechanism until `loadOne` reads
  `DepSpec.path`. The rows in `language-gaps.md` say so; this front does not paper over it with a
  symlink.
- Front 95's `asserts` → `assert` rename was already withdrawn in its own Step 1 ("keep the existing
  `asserts.bp` name"); `01-std/asserts-api.md` is the authority.
- What this front deliberately does not decide: whether `jhonstart-html`, `emilia-theme`,
  `emilia-modifiers`, `onze-pipeline` or `onze-release` exist. Each library's `modules.md` decides,
  with the consumption-boundary test above as the criterion, and `../fronts.md` copies the result.
