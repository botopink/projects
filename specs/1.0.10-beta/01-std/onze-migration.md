# The old `onze` — discontinuation, migration, and the `onze13 → onze` takeover

Steps 4 and 5 of the front. `repository/onze` holds the retired Mockito-style mocking library
(`botopink.json` `"name": "onze"`); every track-E front (`../06-onze/`) writes `repository/onze/` as
the orchestrator's home. This document maps each piece of the old library to its place in std, and
holds the checklist that hands the name over (decision 79).

## Inventory — 100 % of the old `repository/onze`

### Files

| Path | What | Goes |
|---|---|---|
| `botopink.json` | `name: onze`, `targets: [commonJS, erlang]`, `files: [onze.bp]` | with the repository |
| `src/root.bp` | `pub mod onze;` | with the repository |
| `src/onze.bp` | everything: 8 host cells, 3 matchers, 3 verify specs, `when`/`OnzeStub`, `verify`, `#[mock]` | `libs/std/src/testing/mocks.bp` |
| `src/onze.mjs` | the Node runtime: module-global `calls`, `stubs`, `pending`, `pendingStub`, `verifyMode` | inlined into the Node templates of `mocks.bp` |
| `test/onze_test.bp` | 8 tests through `#[mock]`; two recorded limitations | inline tests of `mocks.bp` |
| `examples/mock_synthesis.bp`, `examples/onze/` (`onze-demo`) | a walkthrough and a demo project | with the repository |
| `README.md`, `docs.md`, `AGENTS.md`, `CHANGELOG.md`, `LICENSE`, `src/AGENTS.md` | docs | with the repository (the archive banner is in `README.md`) |
| `scripts/git-hooks/pre-commit`, `lib/runner-standalone.sh`, `.github/workflows/{test,tag}.yml` | the sibling-standard gate and CI | with the repository |

### Exported symbols of `src/onze.bp`

"Verbatim" means the body and the Erlang template moved unchanged; only the module and, where
noted, the name changed.

| Symbol | Kind | In std | Change |
|---|---|---|---|
| `onzeNewMock() -> string` | host cell | `mocks.newMock` | Node template on `globalThis.__bp_mocks` (see *No sidecar*); ids `mock#N` |
| `onzeKey<T>(v: T) -> string` | host cell (`JSON.stringify` / `io_lib:format("~0tp")`) | `mocks.key` **and** `asserts`' private `canonical` | two copies — a std module cannot call another |
| `onzePushMatcher(kind, k) -> i32` | host cell | `mocks.pushMatcher` | inlined |
| `onzeInvoke<T>(id, method, keys, def) -> T` | host cell — the single entry every synthesized method calls; records or verifies | `mocks.invoke` | inlined; the Erlang template verbatim |
| `onzeBeginVerify(spec) -> i32` | host cell | `mocks.beginVerify` | inlined |
| `onzeWhen() -> i32` | host cell | `mocks.whenCall` | renamed — `when` is the public fn's name |
| `onzeThenReturn<T>(v) -> i32` | host cell | `mocks.thenReturnCell` | renamed for the same reason |
| `onzeThenThrow(msg) -> i32` | host cell | `mocks.thenThrowCell` | renamed |
| `eq<T>(v: T) -> T` | matcher | `mocks.eq` | verbatim |
| `anyInt() -> i32` | matcher | `mocks.anyInt` | verbatim |
| `anyString() -> string` | matcher | `mocks.anyString` | verbatim |
| `atLeastOnce() -> i32` | verify spec (`-1`) | `mocks.atLeastOnce` | verbatim |
| `times(n: i32) -> i32` | verify spec | `mocks.times` | verbatim |
| `never() -> i32` | verify spec (`0`) | `mocks.never` | verbatim |
| `type OnzeStub(tag: string) { thenReturn<T>(self, v) -> bool; thenThrow(self, message) -> bool }` | the `when(…)` builder | `mocks.Stub` | renamed type; methods verbatim |
| `when<T>(value: T) -> OnzeStub` | stubbing entry | `mocks.when` | answers `Stub` |
| `verify<T>(mock: T, spec: i32) -> T` | verification entry | `mocks.verify` | message prefix `mocks.verify:` |
| `mock(comptime decl: @Decl)` | the `#[mock]` decorator — reflects a `behavior`, `@emit`s `type Mock<Name>(__id: string) implement <Name>` + `mock<Name>()` | `mocks.mock` | the emitted body calls `invoke`/`key`/`newMock` (see *Decorator resolution*) |

The private state keys are `'__bp_mocks_*'` on Erlang and `globalThis.__bp_mocks` on Node.

### Test surface `test/onze_test.bp`

| Test | In std |
|---|---|
| `an unstubbed method returns the type-default` | inline test in `mocks.bp` |
| `when(...).thenReturn stubs a return value` | same |
| `eq(v) stubs only the matching argument` | same |
| `anyInt() matches any argument` | same |
| `the last matching stub wins` | same |
| `verify atLeastOnce / times / never` | same |
| `thenThrow raises when the call is matched` | same |
| `verify checks each matcher independently after different-arg calls` | same |
| LIMITATION: a matched `thenThrow` is a host throw, not a `@Result` — `try svc.name(0) catch …` does not compile | a comment in `mocks.bp` and a row in *Language gaps* |
| LIMITATION: no generic `any<T>()`, no argument captor | a comment; `anyInt`/`anyString` only |

### Consumers to update

`grep -rn 'from "onze"' --include='*.bp' --include='*.md' repository/ specs/`, excluding the
orchestrator fronts (which mean the *new* onze):

| Consumer | Change |
|---|---|
| `repository/onze/**` | gone with the repository |
| `../03-rakun/19-rakun-test-utilities/examples/controller-test-example.bp` | `import {testing.mocks} from "std";` and `#[mocks.mock]` in place of `import {mock, when, verify, eq, times, onzeInvoke, onzeKey, onzeNewMock} from "onze"` |
| `../03-rakun/19-rakun-test-utilities/README.md` | "mocking is `testing.mocks`, not a second layer"; the `#[mock]` + `#[bean]` pairing stands |

No `botopink.json` in `repository/{rakun,jhonstart,emilia,erika}` declares `onze` as a dependency.

## Where the assertion surface goes

`testing.asserts` — `asserts-api.md` § *Migration table*. Strictly, the old library exported **no
assertion**: `eq`/`anyInt`/`anyString` are matchers (they push onto a stack and return a dummy), and
`verify` raises from inside a host cell. What it contributes to `asserts` is the `onzeKey` renderer
`deepEquals` needs.

## Where the mocking surface goes

`testing.mocks` (decision 71; decision 106 sets the path): one copy of the runtime, in std, next to
`asserts` — library-agnostic, one file, no sidecar, dual-target, reachable from a plain project with
no framework (`import {testing.mocks} from "std"`). The `-test` submodules own the **pairing**: how a
mock is injected into *their* library (`#[mocks.mock]` + `#[bean]` for rakun, front 19 § 8),
documented and tested in each.

**No sidecar.** The recorder needs mutable, identity-based state. The Erlang side keeps its tables in
the process dictionary inside each template; the Node side keeps them on one lazily created
`globalThis.__bp_mocks` cell, the shape emilia's stylesheet cell uses. std ships exactly one sidecar
(`sidecars/random.mjs`), and `mocks` is subject to STD-001 like any std module: its cells are
`pub declare fn` with Node and Erlang templates, so `import {testing.mocks} from "std"` is refused on
beam and wasm — honestly, since no test runs there.

**Decorator resolution.** The consumer spelling is `import {testing.mocks} from "std";` and
`#[mocks.mock]` — the leaf `mocks` is what enters scope (decision 107), and `mocks.when` /
`mocks.verify` read the same. Today `#[mock]` fires only inside `mocks.bp`: `#[mocks.mock]` parses
(the annotation name lands as `"mocks.mock"`) but a std import puts nothing into the decorator
table, so from a consumer the marker does nothing and `mock<Name>()` is unbound; and the emitted body
writes the bare `invoke`/`key`/`newMock`, which resolve only in `mocks.bp`. A consumer writes the
double by hand over the qualified runtime (`docs.md` § Tests ---- Mocks). The fix is in the lookup
and in an emission that is bare inside `mocks.bp` and qualified (`mocks.invoke(self.__id, …)`)
elsewhere — not a bare re-export, because a bare `import {mock} from "std"` would make `std` the
first library whose functions are reached unqualified.

## Removing the repository and reusing the directory

The old code is preserved where git preserves things — in its own repository, tagged — and not
under `repository/_archived/`: a checked-out directory is scanned by `zig build test-libs`, read by
every `grep -rn` in a gate, and is one more `AGENTS.md` to keep true.

| # | Step | Where | Acceptance |
|---|---|---|---|
| 1 | `testing.mocks` and the `asserts` migration merged and green (step 4) | `libs/std` | `botopink test` + `--target erlang` green; the eight old tests pass in their new home |
| 2 | In `botopink/onze` (the old repository): tag the last commit `mocking-lib-final`, add a README banner naming `testing.mocks` and `testing.asserts` as the successors, push, archive the repository on the remote | old remote | the tag resolves; the repository is read-only |
| 3 | Front 49's orchestrator repository exists on the remote under the name `onze` (`botopink/onze` if the old one was renamed first — e.g. to `botopink/onze-mocking` — otherwise a fresh name the `.gitmodules` `url` points at) | remote | `repository/onze/botopink.json` reads `"name": "onze"` |
| 4 | Re-point the submodule: `.gitmodules` `[submodule "repository/onze"] url = <orchestrator url>`, `git submodule sync`, check out the orchestrator's `feat` at `repository/onze` | meta | `git submodule status` shows the orchestrator's commit at `repository/onze` |
| 5 | `zig build test-libs` reads an `onze` cell for the orchestrator, none for the old library | `repository/botopink-lang` | green |
| 6 | Sweep the seven remotes (meta + six submodules) on `feat` | all | unified |

The banner and the tag are in the local `repository/onze` clone; pushing the tag, archiving, and
items 3–4 act on the remotes and are the maintainer's
(`../02-packaging/95-ecosystem-package-restructure/README.md` step 2 has the commands). The directory
name never changes and the submodule *entry* never disappears — only what it points at.

## The `onze13 → onze` rename checklist

The track-E fronts are `49-onze-stand-up` … `53-onze-example-app`, `68-onze-client-bundle` …
`71-onze-release-packaging`, and their **Owns** lines read `repository/onze/…`. What remains:

| Where | `onze13` today | Action |
|---|---|---|
| `../02-packaging/95-ecosystem-package-restructure/README.md`, `../overview.md` | "the orchestrator drafted as `onze13`" | reads `onze` once the takeover lands |
| `../06-onze/**` | none | nothing |
| `repository/onze/botopink.json` | the old library's `"name": "onze"` | becomes the orchestrator's `"name": "onze"` (item 4 of the swap) |
| `repository/onze/{README,AGENTS,docs}.md` | the mocking docs | the orchestrator's (front 49 writes them) |
| `import {…} from "onze"` in fronts 49–53, 68–71 | already `onze` | nothing |
| `import {mock, …} from "onze"` (mocking) | front 19's example | `import {testing.mocks} from "std"` |
| `.gitmodules` | old remote | orchestrator remote (item 4) |
| `../fronts.md`, `../overview.md` Track E headers | already `onze` | nothing |

## `libs/std/src/testing/mocks.bp` — the shape

```bp
//// std/testing/mocks — Mockito-style mocks over a `behavior`: `#[mock]` synthesizes
//// the double, `when(...)` stubs, `verify(...)` checks call counts.

pub declare fn newMock() -> string;
pub declare fn key<T>(v: T) -> string;
pub declare fn pushMatcher(kind: string, k: string) -> i32;
pub declare fn invoke<T>(id: string, method: string, keys: Array<string>, def: T) -> T;
pub declare fn beginVerify(spec: i32) -> i32;
pub declare fn whenCall() -> i32;
pub declare fn thenReturnCell<T>(v: T) -> i32;
pub declare fn thenThrowCell(msg: string) -> i32;

pub fn eq<T>(v: T) -> T
pub fn anyInt() -> i32
pub fn anyString() -> string
pub fn atLeastOnce() -> i32
pub fn times(n: i32) -> i32
pub fn never() -> i32

pub type Stub(tag: string) {
    pub fn thenReturn<T>(self: Self, v: T) -> bool
    pub fn thenThrow(self: Self, message: string) -> bool
}
pub fn when<T>(value: T) -> Stub
pub fn verify<T>(mock: T, spec: i32) -> T
pub fn mock(comptime decl: @Decl)
```

A consumer, once the decorator resolves from outside `mocks.bp`:

```bp
import {testing: {asserts, mocks}} from "std";

#[mocks.mock]
behavior UserRepo {
    fn find(self: Self, id: i32) -> string;
    fn all(self: Self) -> Array<string>;
}

test "mocks: eq(v) stubs only the matching argument" {
    val repo = mockUserRepo();
    val _s = mocks.when(repo.find(mocks.eq(7))).thenReturn("ana");
    try asserts.equals(repo.find(7), "ana");
    try asserts.equals(repo.find(8), "");
    val _v = mocks.verify(repo, mocks.times(2)).find(mocks.anyInt());
}
```

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A matched `thenThrow` is a host throw; `try … catch` unwraps only a `@Result` | `mocks.thenThrow` | the test asserts the non-matching path answers the default (old test 7) | typed raise / catch by tag (`language-gaps.md`), or a synthesized method that answers `@Result<R, string>` |
| No generic `any<T>()` — a matcher must answer a per-type dummy | `mocks.anyInt`, `anyString` only | add `anyBool`, `anyFloat` per type as needed | a `@default<T>()` intrinsic |
| `#[mocks.mock]` does not fire from a consumer: a std import registers no decorator, and the emitted body's bare `invoke`/`key`/`newMock` resolve only inside `mocks.bp` | every consumer of `#[mocks.mock]` | write the double by hand over the qualified runtime | a decorator lookup that resolves a qualified std name, and an `@emit` that can name its own imports |
