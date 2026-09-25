# Front 95 — Ecosystem Package and Test Infrastructure Restructure

**Track:** cross-cutting (A std · B rakun · C jhonstart · D emilia · E onze) — the std/testing/asserts half is specified in [`../../01-std/`](../../01-std/) (`asserts-api.md`, `snapshots.md`, `src-builtin.md`); the packaging half is governed by [`../README.md`](../README.md)
**Priority:** high — every front in the milestone writes tests against a library, and the library they test through does not yet exist under the name or shape the other fronts assume
**Target:** both — std/testing/asserts runs on every backend; each `-test` submodule runs on its library's assigned target
**Wave:** 0 (std/testing/asserts) · 1 (package restructure, parallel with each library's own wave)
**Depends on:** none for the std/testing/asserts half; the package restructure lands alongside each library's first front
**Owns:** `libs/std/src/testing/asserts.bp` (expands the existing module), `libs/std/src/testing/mod.bp` (no change needed — `pub mod asserts;` already exists); the `modules/` layout and `botopink.json` of every library package
**Does not touch:** the source files inside each library's existing submodules — those are owned by their respective fronts; this front moves directories and renames exports, it does not rewrite behaviour
**Reference:** the current `repository/onze/src/onze.bp` (assertion and mocking surface) · [`../../overview.md`](../../overview.md) track E (the orchestrator, drafted as `onze13`) · `libs/std/src/testing/asserts.bp` (current assertion primitives)

---

## Problem

The testing and packaging story of the ecosystem has three defects that get worse the further
the milestone progresses without being fixed.

**1. The name `onze` means two things, and only one of them exists.** The `repository/onze/`
directory holds a Mockito-style mocking library — `#[mock]`, `when`, `verify`, `eq`, `times`
(`repository/onze/src/onze.bp:1-187`). Track E of this milestone plans a full-stack orchestrator
called `onze13` (fronts 49–53, 68–71) that does not have a repository yet. When that repository
is created under the name `onze13`, the ecosystem will ship two packages whose relationship a
new contributor cannot guess: `onze` is the mock library, `onze13` is the orchestrator, and
neither name says what it does.

**2. There is no standard assertion module a library's test helpers can build on.** The
existing `onze` library (`repository/onze/src/onze.bp:1-187`) already provides assertion
helpers and mocking decorators, but they live in a separate package rather than in std.
The result is that every `-test` submodule the milestone is about to create would need to
depend on `onze` for basic assertions, or reinvent them independently. The assertion
surface from `onze` belongs in std, where every package can reach it without a dependency
on a mocking library.

**3. No library has a test submodule.** `rakun` has `modules/rakun-test/` but it holds a TODO
comment (front 19 owns it). `jhonstart`, `emilia` and `onze13` have no `modules/` directory at
all. The consequence is that a front wanting to expose test helpers for its library has no
conventional place to put them and no pattern to follow — front 19 is already designing
`FakeRequest` and `MockMvc` in isolation, and front 33 (the first emilia front) has nowhere to
put an `emilia` snapshot helper when it needs one.

The old `onze` library's assertion and helper surface belongs in std, where every package can
reach it. Its mocking decorators are comptime code-generation and belong in a different home
(see *Mechanism*). The `onze13` repository should be created as `onze`, taking the name the
mocking library is vacating. And every library in the ecosystem should follow the same
`<name>/` + `<name>-test/` + domain-specific submodules pattern, so that a front adding test
helpers always has a directory to put them in and a consumer always knows where to look.

## Current state

Verified by reading the repository trees.

- **`repository/onze/`** — single-module mocking library. `botopink.json` declares
  `"name": "onze"`. `src/onze.bp` (187 lines) holds `#[mock]`, `when().thenReturn/thenThrow`,
  `verify(mock, spec)`, `eq`/`anyInt`/`anyString`, `atLeastOnce`/`times`/`never`, backed by host
  cells on both Node and BEAM. `src/onze.mjs` (121 lines) is the Node runtime with module-global
  mutable state. No `modules/` directory.
- **`repository/onze13/`** — does not exist on disk. Track E plans it as a new repository.
- **`repository/rakun/modules/`** — thirteen submodules: `rakun-web`, `rakun-data`,
  `rakun-security`, `rakun-cache`, `rakun-client`, `rakun-validation`, `rakun-messaging`,
  `rakun-scheduling`, `rakun-logging`, `rakun-session`, `rakun-actuator`, `rakun-hateoas`,
  `rakun-test`. Each has `botopink.json`, `src/`, `test/`.
- **`repository/jhonstart/`** — flat library. `src/` holds `element.bp`, `hooks.bp`, `html.bp`,
  `router.d.bp`, `server.d.bp`. No `modules/` directory.
- **`repository/emilia/`** — flat library. `src/` holds `tokens.bp` and `emilia.bp`. No `modules/`
  directory.
- **`libs/std/src/testing/asserts.bp`** — 161 lines, nine assertion functions, ten inline `test` blocks.
  Pure botopink plus two private host cells (`tryCatch`, `regexMatches`). Exported from
  `testing/mod.bp` as `pub mod asserts;`.

## Mechanism

### 1. The package restructure — one pattern, four libraries

Every library in the ecosystem follows the same submodule convention:

```
repository/<name>/
├── botopink.json              (the package manifest)
├── modules/
│   ├── <name>/                (core — the library's primary surface)
│   │   ├── botopink.json
│   │   ├── src/
│   │   └── test/
│   ├── <name>-test/           (test helpers — always present)
│   │   ├── botopink.json
│   │   ├── src/
│   │   └── test/
│   └── <name>-<domain>/       (additional domain submodules — where warranted)
│       ├── botopink.json
│       ├── src/
│       └── test/
└── examples/
```

Three rules govern the pattern:

- **Every package has a `<name>-test` submodule.** It imports `std/testing/asserts` and re-exports
  domain-specific test helpers. A consumer adds `"<name>-test"` to its dev-dependencies and
  gets assertion helpers, fixtures and builders that know the library's types.
- **Additional submodules are cut at functional boundaries, not at file count.** A submodule
  is warranted when a consumer might want one part of the library without the rest, or when
  a piece has a different target profile. A submodule is *not* warranted just because a file
  is large — `emilia`'s sixty-odd audit rows of CSS utilities are one functional surface and
  stay in one submodule.
- **The core `<name>/` submodule owns the `root.bp` re-exports.** A consumer that imports
  `"rakun"` gets the curated public surface; a consumer that needs a specific domain imports
  `"rakun-web"` or `"rakun-data"` directly.

### 2. Submodule decisions per library

#### `rakun` — thirteen existing + one new

The thirteen existing submodules already reflect natural functional boundaries — web, data,
security, cache, client, validation, messaging, scheduling, logging, session, actuator,
hateoas, test. This front adds none and removes none; it only confirms the pattern and adds
`rakun-test` as the canonical test-helper submodule (already scaffolded, front 19 fills it).

```
modules/
├── rakun/                     (core: DI, bootstrap, configuration, the component model)
├── rakun-web/                 (HTTP, middleware, CORS, WebSocket)
├── rakun-data/                (SQL, NoSQL)
├── rakun-security/            (auth, authz, JWT)
├── rakun-cache/               (cache abstraction, #[cacheable])
├── rakun-client/              (RestClient, WebClient)
├── rakun-validation/          (constraints, violation report — now the bundled `validation`, decision 116)
├── rakun-messaging/           (AMQP, Kafka listener registry)
├── rakun-scheduling/          (#[scheduled], cron)
├── rakun-logging/             (structured logging)
├── rakun-session/             (session store, cookie binding)
├── rakun-actuator/            (health, info, metrics)
├── rakun-hateoas/             (HAL, link builders)
└── rakun-test/                (FakeRequest, MockMvc, context reset, broker double)
```

The core `rakun/` submodule is new — it collects the DI container, `#[bean]`, `#[configuration]`,
`#[value]`, `App`, `rkScan`, `rkBuild` and the bootstrap path that today live in `rakun/src/`.
Every other submodule depends on it.

#### `jhonstart` — core + html + test

```
modules/
├── jhonstart/                 (core: Element, hooks, server.d, router.d, rendering)
├── jhonstart-html/            (the html`` DSL and element constructors)
└── jhonstart-test/            (render helpers, element comparison, snapshot assertions)
```

**Why `jhonstart-html` is separate.** The HTML DSL (`html.bp` today) is the largest single
surface in jhonstart — every element constructor, the attribute spread, the child flattening —
and it is the surface front 94 extends with `form`, `input`, `button`, `a`, `img`, `nav`,
`html`, `head`, `body`. A consumer that uses jhonstart for server components without writing
inline HTML (driving the element API from a template engine, say) should not pay for the DSL
it does not call. The DSL is also where the byte-equality tests with upstream HTML live, and
keeping those in their own submodule means the core's test suite stays fast.

**Why nothing else.** `hooks.bp` and `router.d.bp` are small and coupled to the core's
rendering types; splitting them would produce submodules with one file each.

#### `emilia` — core + test

```
modules/
├── emilia/                    (core: tokens, utilities, cascade, theme, output)
└── emilia-test/               (token snapshot helpers, CSS diff, fixture utilities)
```

**Why only two.** The sixty-odd fronts in track D all extend the same functional surface —
CSS utility generation from tokens through a cascade. The theme (front 54), the cascade
(front 56), the preflight (front 55) and the escape hatches (front 57) are not independent
consumption choices; they are layers of one pipeline. Splitting them into submodules would
create a dependency graph that mirrors the pipeline anyway, with no consumer able to take one
without the others.

#### `onze` (formerly `onze13`) — core + test + cli + bundler + assets

```
modules/
├── onze/                      (core: orchestrator types, config, integration layer)
├── onze-test/                 (app scaffolding test helpers, route-table assertions)
├── onze-cli/                  (create, dev, build, start — front 50)
├── onze-bundler/              ('use client' module graph, browser bundle — front 68)
└── onze-assets/               (styling pipeline, image optimizer — fronts 69, 51, 52)
```

**Why five.** The orchestrator has genuinely different consumption patterns: a production
deploy needs the core and the bundler but not the CLI; a dev environment needs the CLI but
not the bundler; the asset pipeline is its own build step. Each boundary is a front in the
overview and each front owns a disjoint set of files.

### 3. The `onze` rename — how the old mocking library dissolves

The current `repository/onze/` holds two kinds of functionality:

| What | Where today | Where it goes |
|---|---|---|
| Assertion helpers (`eq`, `anyInt`, `anyString` — matchers used in test bodies) | `onze.bp` | `std/testing/asserts` — these are general-purpose test predicates |
| Mocking decorators (`#[mock]`, `when`, `verify`, `thenReturn`, `thenThrow`) | `onze.bp` + `onze.mjs` | Each library's `-test` submodule re-exports a mocking convention built on `#[mock]` + `#[bean]`; the host runtime moves to the first `-test` submodule that needs it |
| Verification specs (`times`, `atLeastOnce`, `never`) | `onze.bp` | Same — part of the mocking convention in `-test` |

The `repository/onze/` directory is then free to become the new `onze` orchestrator package.
Front 49 (`onze13-stand-up`, now `onze-stand-up`) creates it under the name `onze` with the
module tree above. The old mocking code is archived in the milestone's `deferred.md` as a
source for the `-test` submodules' mocking conventions — it is not deleted until at least one
`-test` submodule has absorbed its host runtime.

### 4. `std/testing/asserts` — the full surface

The existing `asserts.bp` is renamed to `assert.bp` and expanded. The table below lists every
function, marks which ones exist today, and says which are new.

#### Boolean assertions

| Function | Exists | Signature | Notes |
|---|---|---|---|
| `truthy` | yes | `(condition: bool) -> bool` | `asserts.bp:14` |
| `falsy` | yes | `(condition: bool) -> bool` | `asserts.bp:22` |

#### Equality assertions

| Function | Exists | Signature | Notes |
|---|---|---|---|
| `equal` | yes | `<T>(a: T, b: T) -> bool` | `asserts.bp:30` |
| `notEqual` | yes | `<T>(a: T, b: T) -> bool` | `asserts.bp:40` |
| `approxEqual` | yes | `(a: f64, b: f64, tolerance: f64) -> bool` | `asserts.bp:50` |
| `deepEqual` | **new** | `<T>(a: T, b: T) -> bool` | Structural equality for records and arrays. Serializes both sides to a canonical form and compares; the failure message carries the first differing field path. |

#### String assertions

| Function | Exists | Signature | Notes |
|---|---|---|---|
| `contains` | yes | `(haystack: string, needle: string) -> bool` | `asserts.bp:60` |
| `matches` | yes | `(pattern: string, actual: string) -> bool` | `asserts.bp:90` |
| `startsWith` | **new** | `(s: string, prefix: string) -> bool` | |
| `endsWith` | **new** | `(s: string, suffix: string) -> bool` | |

#### Collection assertions

| Function | Exists | Signature | Notes |
|---|---|---|---|
| `empty` | **new** | `<T>(collection: Array<T>) -> bool` | Empty array or zero-length string. |
| `notEmpty` | **new** | `<T>(collection: Array<T>) -> bool` | |
| `hasLength` | **new** | `<T>(collection: Array<T>, expected: i32) -> bool` | |
| `includes` | **new** | `<T>(collection: Array<T>, element: T) -> bool` | Array membership via `equal`. |

#### Numeric assertions

| Function | Exists | Signature | Notes |
|---|---|---|---|
| `between` | **new** | `(value: i32, low: i32, high: i32) -> bool` | Inclusive on both ends. |
| `positive` | **new** | `(value: i32) -> bool` | |
| `negative` | **new** | `(value: i32) -> bool` | |

#### Result assertions

| Function | Exists | Signature | Notes |
|---|---|---|---|
| `isOk` | **new** | `<T, E>(result: @Result<T, E>) -> bool` | |
| `isErr` | **new** | `<T, E>(result: @Result<T, E>) -> bool` | |
| `isOkAnd` | **new** | `<T, E>(result: @Result<T, E>, predicate: fn(T) -> bool) -> bool` | Asserts Ok *and* the value satisfies the predicate. |

#### Exception assertions

| Function | Exists | Signature | Notes |
|---|---|---|---|
| `throws` | yes | `(body: fn() -> i32, message: string) -> bool` | `asserts.bp:72`. The `message` parameter is a substring expected in the panic. |
| `throwsType` | **new** | `<E>(body: fn() -> i32, errorType: E) -> bool` | Asserts the raised error matches a specific type or value. |

#### Utility

| Function | Exists | Signature | Notes |
|---|---|---|---|
| `fail` | **new** | `(message: string) -> i32` | Explicit test failure. Always panics with `AssertError`. |
| `typeOf` | **new** | `<T>(value: T) -> string` | Returns the type name as a string, for diagnostic messages. |

#### Test lifecycle

| Function | Exists | Signature | Notes |
|---|---|---|---|
| `setup` | **new** | `(fn: fn() -> i32) -> i32` | Registers a before-each hook in the test runner. The function runs before every `test` block in the file. |
| `teardown` | **new** | `(fn: fn() -> i32) -> i32` | After-each hook. |
| `setupAll` | **new** | `(fn: fn() -> i32) -> i32` | Before-all hook. Runs once before the first test in the file. |
| `teardownAll` | **new** | `(fn: fn() -> i32) -> i32` | After-all hook. |

The lifecycle hooks require test-runner support — the runner must call registered hooks in
order around each `test` block. The current runner (`botopink test`) does not have this
mechanism; this front specifies the surface and the runner integration is a compiler-side
change filed as a language gap (see *Language gaps*). Until the runner supports hooks, the
functions are specified, the types check, and the first call in each `-test` submodule is a
manual invocation at the top of each `test` block.

### 5. The `-test` submodule pattern

Every `-test` submodule follows the same shape:

```bp
//// <name>-test — test helpers for the <name> library.
////
//// Depends on: std/testing/asserts, <name> (core)
//// Target: <the library's assigned target>

import {testing.asserts} from "std";

// Domain-specific assertion helpers
pub fn expectShape(element: Element, tag: string) -> bool {
    return asserts.equal(element.tagName, tag);
}

// Fixture builders
pub fn fixtureElement(tag: string) -> Element { … }

// Re-export std/testing/asserts for convenience — consumers import one module
pub fn truthy(c: bool) -> bool { return asserts.truthy(c); }
pub fn equal<T>(a: T, b: T) -> bool { return asserts.equal(a, b); }
// …etc
```

Three rules:

- **Import `std/testing/asserts`, do not re-implement.** A `-test` submodule that defines its own
  `equal` is a bug — the consumer now has two `equal` functions and no way to know which
  panic message they get.
- **Expose builders and fixtures, not just assertions.** The value of a `-test` submodule is
  mostly in the builders — `fakeGet("/path")`, `fixtureElement("div")`, `sampleToken()` —
  that save every test from constructing domain values by hand.
- **The mocking convention is documented, not implemented.** Each `-test` submodule's README
  shows the `#[mock]` + `#[bean]` pairing as the way to mock a dependency in that library's
  tests. The host runtime that backs `#[mock]` lives in the first `-test` submodule that
  needs it, not in std.

## Steps

### Step 1 — Expand `asserts.bp` with the new functions

In `libs/std/src/`:

1. Keep the existing `asserts.bp` name and all existing functions byte-unchanged (the ten inline `test` blocks must still pass).
2. Append the new functions from the table above.
3. No `root.bp` change needed — `testing/mod.bp` already has `pub mod asserts;`.

**Acceptance:**
- [ ] `import {testing.asserts} from "std";` resolves from a consumer package (already works today)
- [ ] `asserts.truthy`, `asserts.equal`, `asserts.contains`, `asserts.throws`, `asserts.matches` — all five existing functions, byte-unchanged, tests green
- [ ] `asserts.deepEqual({a: 1, b: [2, 3]}, {a: 1, b: [2, 3]})` is true; `asserts.deepEqual({a: 1}, {a: 2})` panics with a message naming the `a` field
- [ ] `asserts.empty([])` is true; `asserts.empty([1])` panics
- [ ] `asserts.isOk(Ok(42))` is true; `asserts.isOk(Err("x"))` panics
- [ ] `asserts.between(5, 1, 10)` is true; `asserts.between(0, 1, 10)` panics
- [ ] `asserts.fail("nope")` panics with `"nope"` in the message
- [ ] `asserts.startsWith("hello world", "hello")` is true
- [ ] `asserts.includes([1, 2, 3], 2)` is true; `asserts.includes([1, 2, 3], 4)` panics
- [ ] `libs/std/AGENTS.md` reflects the new functions

> **Superseded at HEAD.** `01-std` landed the module as `libs/std/src/asserts.bp` (flat, reached as
> `import {asserts} from "std"`; the `testing/` path waits on decision 106's layout) with the surface of
> [`../../01-std/asserts-api.md`](../../01-std/asserts-api.md), which is the authority: every helper
> answers `@Result<void, string>` instead of `bool`/panic, and the names differ (`isTrue`, `equals`,
> `deepEquals`, `isEmpty`, `lengthIs`, `isError`, `throwsWith`, …). `positive`/`negative`, `isOkAnd`,
> `throwsType`, `typeOf` and the four lifecycle hooks are *not shipped* there, by that document's
> § Migration table. The boxes above are left open because they name the withdrawn surface; nothing
> of this step is front 95's to do.

### Step 2 — Create the `onze` package structure (rename from `onze13` plan)

The planned Track E repository is created as `repository/onze/` — the old mocking library
directory is moved aside first.

```
repository/onze/                        (the old mocking lib, archived)
  → repository/_archived/onze-mock/     (preserved for the host runtime)

repository/onze/                        (new — the orchestrator)
├── botopink.json                       { "name": "onze", ... }
├── modules/
│   ├── onze/                           (core)
│   │   ├── botopink.json
│   │   ├── src/root.bp
│   │   └── test/
│   ├── onze-test/
│   │   ├── botopink.json
│   │   ├── src/root.bp
│   │   └── test/
│   ├── onze-cli/
│   │   ├── botopink.json
│   │   ├── src/root.bp
│   │   └── test/
│   ├── onze-bundler/
│   │   ├── botopink.json
│   │   ├── src/root.bp
│   │   └── test/
│   └── onze-assets/
│       ├── botopink.json
│       ├── src/root.bp
│       └── test/
└── examples/
```

Front 49's stand-up work now targets `modules/onze/` instead of `src/`. Every other Track E
front number is unchanged; only the directory paths in their ownership tables update.

**Acceptance:**
- [ ] `repository/onze/botopink.json` declares `"name": "onze"` and lists the five submodules
- [ ] Each submodule has a `botopink.json` with `"name": "onze-<domain>"` and a `src/root.bp`
- [ ] `zig build test-libs` from the meta repo does not red on the empty modules
- [ ] The old `onze` mocking library is archived, not deleted — `repository/_archived/onze-mock/`

> **Contradicted by decision 79, and blocked.** The old library is tagged `mocking-lib-final` and
> archived **on its remote**; nothing is vendored under `repository/_archived/`
> ([`../../01-std/onze-migration.md`](../../01-std/onze-migration.md) § *Removing the repository*). The
> `repository/onze` submodule entry is re-pointed at the orchestrator's repository, which does not exist
> yet; that waits on the maintainer's tag-and-archive (`status.md`, `01-std` step 5). The member list is
> [`../../06-onze/modules.md`](../../06-onze/modules.md)'s (`onze-og`, `onze-release` beside the five
> above), and the skeletons are `02-packaging` step 2's once the directory is free.

### Step 3 — Create the `jhonstart` package structure

Convert the flat `repository/jhonstart/src/` into `modules/`:

```
repository/jhonstart/
├── botopink.json                       (updated — points at modules/)
├── modules/
│   ├── jhonstart/
│   │   ├── botopink.json
│   │   ├── src/
│   │   │   ├── root.bp                 (re-exports element, hooks, router.d, server.d)
│   │   │   ├── element.bp              (moved from src/)
│   │   │   ├── hooks.bp                (moved from src/)
│   │   │   ├── router.d.bp             (moved from src/)
│   │   │   └── server.d.bp             (moved from src/)
│   │   └── test/
│   │       └── html_test.bp            (moved from test/)
│   ├── jhonstart-html/
│   │   ├── botopink.json
│   │   ├── src/
│   │   │   ├── root.bp
│   │   │   └── html.bp                 (moved from src/)
│   │   └── test/
│   └── jhonstart-test/
│       ├── botopink.json
│       ├── src/root.bp
│       └── test/
└── examples/
```

**Acceptance:**
- [x] `import { Element } from "jhonstart";` still resolves — the core re-exports it
- [x] `import { html } from "jhonstart-html";` resolves
- [x] `import { ... } from "jhonstart-test";` resolves (empty for now, filled by fronts 26–32)
- [x] `zig build test-libs` green — existing `html_test.bp` passes in its new location (runner over the two branches: 54 passed, 0 failed; `jhonstart`, `jhonstart-html`, `jhonstart-test`, `jhonstart-markup` ✓ on both rows — the main checkout's gate sees it once the library branches merge)
- [x] `repository/jhonstart/AGENTS.md` reflects the new tree

> **As landed.** The picture above predates the workspace migration (`02-packaging` step 2): the core
> was already `modules/jhonstart/` with its own `src/root.bp` (`element`, `hooks`, `router`,
> `elements`, `server`, `link`, `reconcile`, `client` — `router.d.bp`/`server.d.bp` are promoted to
> `.bp`). What this step did: `html.bp` moved to `modules/jhonstart-html/` (its one edit is
> `import {Element} from "jhonstart"`), and **both** DSL suites went with it — `html_test.bp` *and*
> front 94's `elements_test.bp` — because the core cannot depend on the DSL member, so neither can stay
> in `modules/jhonstart/test/` as the tree above says (`04-jhonstart/modules.md` § 1.4 agrees). The
> constructors stay in core (front 94; `modules.md` § 2 "keep, narrowed"). The example
> `examples/jhonstart-html/` was renamed `examples/jhonstart-markup/`: a member name is unique in the
> workspace and the DSL member takes it. `jhonstart-link`, `-forms` and `-emilia` (decision 113) are
> their fronts' (`modules.md` § 1).

### Step 4 — Create the `emilia` package structure

Convert the flat `repository/emilia/src/` into `modules/`:

```
repository/emilia/
├── botopink.json                       (updated — points at modules/)
├── modules/
│   ├── emilia/
│   │   ├── botopink.json
│   │   ├── src/
│   │   │   ├── root.bp                 (re-exports tokens, emilia)
│   │   │   ├── tokens.bp               (moved from src/)
│   │   │   └── emilia.bp               (moved from src/)
│   │   └── test/
│   └── emilia-test/
│       ├── botopink.json
│       ├── src/root.bp
│       └── test/
└── examples/
```

**Acceptance:**
- [x] `import { Token } from "emilia";` still resolves
- [x] `import { ... } from "emilia-test";` resolves (empty for now, filled by fronts 33–48)
- [x] `zig build test-libs` green (same run: `emilia-test` ✓ on both rows)
- [x] `repository/emilia/AGENTS.md` reflects the new tree

> **As landed.** The core member `modules/emilia/` (with `theme.bp`, `spacing.bp`, `output.bp` beside
> `tokens.bp`/`emilia.bp`) was already the `02-packaging` step 2 migration; this step added
> `modules/emilia-test/`. emilia depends on no library, dev-dependency included (decision 114).

### Step 5 — Confirm the `rakun` package structure

`rakun` already has `modules/` with thirteen submodules. This step creates the core
`modules/rakun/` submodule (collecting the DI/bootstrap code from `rakun/src/`) and confirms
the layout.

```
repository/rakun/
├── botopink.json                       (updated if needed)
├── src/                                (existing — DI, bootstrap, decorators, http, runtime)
│   └── ...                             (fronts 04–06 own these files)
├── modules/
│   ├── rakun/                          (new core — re-exports from src/)
│   │   ├── botopink.json
│   │   ├── src/root.bp
│   │   └── test/
│   ├── rakun-web/                      (existing)
│   ├── rakun-data/                     (existing)
│   ├── ...                             (eleven more existing submodules)
│   └── rakun-test/                     (existing scaffold — front 19 fills it)
└── examples/
```

**Acceptance:**
- [x] `import { ... } from "rakun";` resolves through the new core submodule
- [ ] All thirteen existing submodules are byte-unchanged
- [ ] `zig build test-libs` green
- [x] `repository/rakun/AGENTS.md` reflects the layout

> **Done on feat by the rakun workspace migration (`02-packaging` step 2), not here.** The core
> `modules/rakun/` holds the code that was `rakun/src/` (there is no `src/` left to "re-export from").
> "Byte-unchanged" contradicts `02-packaging` § 11 move 3 — every member manifest had to trade
> `{ "path": "../../" }` for `{ "workspace": true }` and gain `files`. Decisions 113–116 change the
> member list further, and not in this front: `rakun-validation` leaves for the bundled library
> `validation` (decision 116, rakun front 14), and the core becomes `["erlang"]` (113 item 8, rakun
> front 04). `test-libs` green over rakun is the known-red ledger's, owned by those fronts.

### Step 6 — Update overview.md and fronts.md

The overview's Track E table, the fronts.md ownership table, and every Track E front's
**Owns:** line are updated to reference `onze` instead of `onze13` and the new `modules/`
paths.

**Acceptance:**
- [ ] `overview.md` Track E header reads `Track E — onze (49–53 · 68–71)`
- [x] `fronts.md` ownership table rows for F49–F53, F68–F71 reference `repository/onze/modules/`
- [ ] No remaining `onze13` string in `overview.md` or `fronts.md`
- [x] Each Track E front README's **Owns:** line is updated

> **Against HEAD.** `overview.md` has no "Track E" header: tracks are rows of its directory table, and
> the `06-onze/` row names `onze` (the draft name only through `unification.md`). `fronts.md` § *Track E
> — onze (`repository/onze/`, recreated)* writes its rows relative to that repository
> (`modules/onze/…`, `modules/onze-assets/…`), which is what the second box asks. Four `onze13`
> strings stay on purpose — `overview.md` wave 0 and § *What this milestone delivers* item 1,
> `fronts.md` blocking order and the `01-std` ownership row — because each names the rename itself,
> which is `01-std` step 5 and still open; `01-std` step 5's own acceptance and `02-packaging` § 10
> except exactly those lines. The **Owns** / **Does not touch** lines of 49, 50, 51, 52 and 68 now
> read the member paths of `06-onze/modules.md` (51 and 52 hand their `pub mod` lines to 69, not 49);
> 53 and 69–71 already did.

### Step 7 — Deprecate the old `onze` mocking library

The archived `repository/_archived/onze-mock/` is marked as deprecated. Its README gains a
banner:

```
> **Deprecated.** This library's assertion surface has moved to `std/testing/asserts` (front 95).
> Its mocking decorators (`#[mock]`, `when`, `verify`) are absorbed by each library's
> `-test` submodule. This archive is preserved for the host runtime implementation and
> will be removed once the first `-test` submodule has absorbed it.
```

**Acceptance:**
- [ ] The archive directory exists with the banner
- [x] No active `botopink.json` in any live package references `"onze"` as a dependency for mocking
- [ ] `deferred.md` records the mocking host runtime as a source for the `-test` submodules

> **Superseded by decisions 71 and 79.** The mocking runtime is not deferred and not per `-test`
> submodule: it is `std/mocks` (decision 71, landed with the old library's state as
> `globalThis.__bp_mocks`), and `deferred.md` says so ("The mocking surface is not deferred"). There is
> no archive directory (decision 79: tagged and archived on the remote); the banner belongs in the old
> repository's README at tagging time, the maintainer's step.

## Examples

- [`examples/assert-usage-example.bp`](./examples/assert-usage-example.bp) — demonstrates
  `std/testing/asserts` in practice: boolean, equality, collection, result, string and lifecycle
  assertions. Shows the shape of a test file that imports only `std/testing/asserts`.
- [`examples/test-submodule-pattern-example.bp`](./examples/test-submodule-pattern-example.bp)
  — demonstrates how a `-test` submodule (using `emilia-test` as the concrete example)
  imports `std/testing/asserts`, adds domain-specific helpers, and exposes them to consumers.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `asserts.setup`/`teardown`/`setupAll`/`teardownAll` need test-runner hook support | `std/testing/asserts` lifecycle | manual invocation at the top of each `test` block | the test runner calls registered hook functions around each `test` block, in registration order |
| `asserts.deepEqual` needs structural equality for records | `std/testing/asserts` | serialize both sides to JSON and compare strings (loses field-path information in the failure message) | a compiler-builtin structural equality that walks record fields and array elements, reporting the first differing path |
| A std module cannot call another std module | `asserts.deepEqual` wants to use `json.stringify` for the canonical form | inline the serialization in `assert.bp` (duplicates the host cell) | make a cross-module bare import of an `#[@External.*]` symbol lower to the defining module's binding (same gap front 01 records) |
| Declared parameter defaults are never applied | `assert.between(value, low, high)` might want a default tolerance | every call passes every argument | apply defaults at the call site |

## Test plan

The std/testing/asserts tests are inline `test` blocks at the bottom of `libs/std/src/testing/asserts.bp`,
following the existing std convention (`io/clock.bp`, `io/process.bp`). They run on both
targets via `zig build test-libs`.

The package-structure tests are structural: `zig build test-libs` must be green after each
step, which verifies that every `botopink.json` resolves, every `root.bp` re-export is
valid, and every moved file is found at its new path.

| What | Asserts | How |
|---|---|---|
| `asserts.bp` functions | Each function's success and failure path, on both targets | inline `test` blocks |
| `asserts.deepEqual` | Record field comparison, nested array comparison, failure message field path | inline `test` blocks |
| Package import resolution | `import { ... } from "<name>"` works for every restructured package | `zig build test-libs` green |
| File moves | Existing tests pass at their new paths | `zig build test-libs` green |
| Name consistency | No `onze13` string in any live spec or `botopink.json` | `grep -r onze13` in `specs/` and `repository/` |

## Blast radius

This front touches every package in the ecosystem, but it touches each one *structurally* —
directory moves and `botopink.json` edits, not behaviour changes. The risk profile is:

- **std/testing/asserts expansion**: the existing `asserts.bp` module gains new functions; no rename,
  no breaking change for existing consumers. The module name `asserts` is unchanged.
- **`onze` → `onze` rename**: front 49 has not created the `onze13` repository yet, so there
  is no code to rename — only the spec documents update.
- **File moves in `jhonstart` and `emilia`**: the existing tests (`html_test.bp`) must be
  updated with new import paths. Both libraries have one test file each.
- **`rakun`**: the thirteen existing submodules are not moved; only a new `modules/rakun/`
  core is added. Zero existing code changes.

## Notes

- The old `onze` mocking library is archived, not deleted. Its host runtime (`onze.mjs` and
  the Erlang cells in `onze.bp`) is the reference implementation for the mocking convention
  each `-test` submodule will document. Deleting it before the first `-test` submodule has
  absorbed the runtime would lose working code.
- The `asserts` → `assert` rename is a breaking change for any consumer that imports
  `asserts` today. The call sites are listed in the blast radius and updated in the same
  commit.
- The submodule pattern is a convention, not a compiler feature. A `modules/` directory is
  just a directory — the compiler resolves `import { ... } from "<name>"` through
  `botopink.json`'s `"name"` field. The convention is that `<name>-test` is the test-helper
  submodule and additional submodules are cut at functional boundaries.
- Front 49's name changes from `onze13-stand-up` to `onze-stand-up`. The front number (49)
  is unchanged; only the slug and the directory paths in its README update.

## Definition of done

- `libs/std/src/testing/asserts.bp` exists with every original function
  byte-unchanged and the new functions from the table above implemented and tested.
- `libs/std/src/root.bp` exports `asserts` (unchanged — no rename).
- `repository/onze/` is the new orchestrator package with five submodules (`onze`,
  `onze-test`, `onze-cli`, `onze-bundler`, `onze-assets`).
- `repository/jhonstart/` has three submodules (`jhonstart`, `jhonstart-html`,
  `jhonstart-test`).
- `repository/emilia/` has two submodules (`emilia`, `emilia-test`).
- `repository/rakun/` has fourteen submodules (thirteen existing + the new core `rakun/`).
- The old `onze` mocking library is archived at `repository/_archived/onze-mock/` with a
  deprecation banner.
- `overview.md` and `fronts.md` reference `onze` (not `onze13`) throughout Track E.
- Every `AGENTS.md` in a touched directory reflects the new tree in the same commit.
- `zig build test-libs` is green after each step.
- Both examples compile and demonstrate the patterns.

> **Against decisions 71, 79 and 113–116.** `onze` has seven members in `../../06-onze/modules.md`
> (`onze-og`, `onze-release` beside the five), not five; nothing is archived under
> `repository/_archived/` (79); rakun ends with thirteen members, not fourteen — the core arrives and
> `rakun-validation` leaves for the bundled `validation` (116); jhonstart's final cut is six members
> (`04-jhonstart/modules.md` § 2, with the `jhonstart-emilia` bridge of 113), of which this front made
> `jhonstart-html` and `jhonstart-test`. The `-test` members re-export nothing from std
> (`../README.md` § 5), unlike *Mechanism* § 5's sketch.
