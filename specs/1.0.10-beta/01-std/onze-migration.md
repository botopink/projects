# The old `onze` — discontinuation, migration, and the `onze13 → onze` takeover

Steps 4 and 5 of the front. `repository/onze` today is a Mockito-style mocking library
(`botopink.json` `"name": "onze"`, `"description": "Mockito-style mocking + verification for
botopink unit tests"`). Every track-E front of 1.0.9 already writes `repository/onze/` as the
orchestrator's home. This document is the inventory of what the old library is, where each piece
goes, and the checklist that hands the name over. Measured 2026-09-20 at meta HEAD `b5ceb203`,
submodule `repository/onze`.

## Inventory — 100 % of `repository/onze`

### Files

| Path | Lines | What |
|---|---|---|
| `botopink.json` | 10 | `name: onze`, `targets: [commonJS, erlang]`, `files: [onze.bp]` |
| `src/root.bp` | 9 | `pub mod onze;` |
| `src/onze.bp` | 187 | everything: 8 host cells, 3 matchers, 3 verify specs, `when`/`OnzeStub`, `verify`, `#[mock]` |
| `src/onze.mjs` | 121 | the Node runtime: module-global `calls`, `stubs`, `pending`, `pendingStub`, `verifyMode` |
| `src/AGENTS.md` | — | internals |
| `test/onze_test.bp` | 125 | 8 tests through `#[mock]`; two recorded limitations |
| `examples/mock_synthesis.bp` | 42 | a `main()` walkthrough |
| `examples/onze/` | — | a project (`onze-demo`) with `src/main.bp` (4 tests + `main`) and a checked-in `out/` |
| `README.md`, `docs.md`, `AGENTS.md`, `CHANGELOG.md`, `LICENSE` | — | docs |
| `scripts/git-hooks/pre-commit`, `lib/runner-standalone.sh` | — | the sibling-standard gate |
| `.github/workflows/{test,tag}.yml` | — | CI over `zig build test-libs -- --lib onze --target <t>`; auto-tag on `feat`/`main` |

### Exported symbols of `src/onze.bp`

Every `pub` symbol, with the line at HEAD and the destination. "Verbatim" means the body and the
Erlang template move unchanged; only the module and, where noted, the name change.

| Symbol | Line | Kind | Destination | Change |
|---|---|---|---|---|
| `onzeNewMock() -> string` | 31 | host cell (Node: `onze.mjs newMock`; Erlang: process-dictionary counter) | `mocks.newMock` | Node template inlined as `globalThis.__bp_mocks` state (see *No sidecar*) |
| `onzeKey<T>(v: T) -> string` | 35 | host cell (`JSON.stringify` / `io_lib:format("~0tp")`) | `mocks.key` **and** `asserts.canonical` (private) | two copies — a std module cannot call another |
| `onzePushMatcher(kind, k) -> i32` | 39 | host cell | `mocks.pushMatcher` | inlined |
| `onzeInvoke<T>(id, method, keys, def) -> T` | 43 | host cell — the single entry every synthesized method calls; records or verifies | `mocks.invoke` | inlined; the Erlang template (one expression, ~40 lines) verbatim |
| `onzeBeginVerify(spec) -> i32` | 52 | host cell | `mocks.beginVerify` | inlined |
| `onzeWhen() -> i32` | 56 | host cell | `mocks.whenCall` | renamed — `when` is the public fn's name |
| `onzeThenReturn<T>(v) -> i32` | 60 | host cell | `mocks.thenReturnCell` | renamed for the same reason |
| `onzeThenThrow(msg) -> i32` | 64 | host cell | `mocks.thenThrowCell` | renamed |
| `eq<T>(v: T) -> T` | 68 | matcher | `mocks.eq` | verbatim |
| `anyInt() -> i32` | 74 | matcher | `mocks.anyInt` | verbatim |
| `anyString() -> string` | 79 | matcher | `mocks.anyString` | verbatim |
| `atLeastOnce() -> i32` | 88 | verify spec (`-1`) | `mocks.atLeastOnce` | verbatim |
| `times(n: i32) -> i32` | 92 | verify spec | `mocks.times` | verbatim |
| `never() -> i32` | 96 | verify spec (`0`) | `mocks.never` | verbatim |
| `type OnzeStub(tag: string) { thenReturn<T>(self, v) -> bool; thenThrow(self, message) -> bool }` | 106 | the `when(…)` builder | `mocks.Stub` | renamed type; methods verbatim |
| `when<T>(value: T) -> OnzeStub` | 120 | stubbing entry | `mocks.when` | verbatim, answers `Stub` |
| `verify<T>(mock: T, spec: i32) -> T` | 134 | verification entry | `mocks.verify` | verbatim |
| `mock(comptime decl: @Decl)` | 158 | the `#[mock]` decorator — reflects a `behavior`, `@emit`s `type Mock<Name>(__id: string) implement <Name>` + `mock<Name>()` | `mocks.mock`, applied as `#[mocks.mock]` | the emitted body calls `mocks.invoke`/`mocks.key`/`mocks.newMock` **qualified** (see *Decorator resolution*) |

### The Node runtime `src/onze.mjs`

| Export | Line | Destination |
|---|---|---|
| `newMock`, `key`, `pushMatcher`, `beginVerify`, `invoke`, `when`, `thenReturn`, `thenThrow` | 51–121 | the Node template of the matching `mocks.*` cell |
| `takeMatchers`, `argsMatch` (private helpers) | 26–44 | inlined into `invoke`'s template |
| module-global state `__counter`, `calls`, `stubs`, `pending`, `pendingStub`, `verifyMode` | 17–23 | `globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }` — the shape `emilia.bp:24` uses for its sheet cell |

### Test surface `test/onze_test.bp`

| Test | Destination |
|---|---|
| `an unstubbed method returns the type-default` | inline test in `mocks.bp`, verbatim |
| `when(...).thenReturn stubs a return value` | same |
| `eq(v) stubs only the matching argument` | same |
| `anyInt() matches any argument` | same |
| `the last matching stub wins` | same |
| `verify atLeastOnce / times / never` | same |
| `thenThrow raises when the call is matched` | same |
| `verify checks each matcher independently after different-arg calls` | same |
| LIMITATION: a matched `thenThrow` is a host throw, not a `@Result` — `try svc.name(0) catch …` does not compile | carried as a comment in `mocks.bp` and as a row in *Language gaps* |
| LIMITATION: no generic `any<T>()`, no argument captor | carried as a comment; `anyInt`/`anyString` only |

### Consumers to update

`grep -rn 'from "onze"' --include='*.bp' --include='*.md' repository/ specs/`, excluding the
orchestrator fronts (which mean the *new* onze):

| Consumer | Line | Change |
|---|---|---|
| `repository/onze/src/onze.bp`, `README.md`, `docs.md`, `AGENTS.md`, `examples/**` | — | gone with the repository |
| `specs/1.0.9-beta/19-rakun-test-utilities/examples/controller-test-example.bp` | 24 | not edited (1.0.9 is closed); its 1.0.10 copy under `03-rakun/19-…/examples/` becomes `import {mocks} from "std";` and `#[mocks.mock]` |
| `specs/1.0.9-beta/19-rakun-test-utilities/README.md` | 7, 33-35, 43, 177-183, 245, 272, 282 | its 1.0.10 copy: "mocking is `std/mocks`, not a second layer"; the `#[mock]` + `#[bean]` pairing stands |
| `specs/1.0.9-beta/95-ecosystem-package-restructure/README.md` § 3 | 193-207 | superseded by this document (`unification.md`) |

No `botopink.json` in `repository/{rakun,jhonstart,emilia,erika}` declares `onze` as a dependency
(`grep -rn '"onze"' repository/*/botopink.json repository/*/modules/*/botopink.json` — none).

## Where the assertion surface goes

`std/asserts` — every row of `asserts-api.md` § *Migration table*. Strictly, the old library
exported **no assertion**: `eq`/`anyInt`/`anyString` are matchers (they push onto a stack and return
a dummy), and `verify` raises from inside a host cell. 1.0.9 front 95 § 3 filed the three matchers
under "assertion helpers"; the inventory above corrects it. What the old library does contribute to
`asserts` is the `onzeKey` cell — the canonical renderer `deepEquals` needed.

## Where the mocking surface goes

Two candidates were on the table (1.0.9 front 95 § 3 chose the second):

| | `std/mocks` — one module in std | each `<lib>-test` submodule |
|---|---|---|
| copies of the runtime | one | one per library that mocks — rakun-test first, then jhonstart-test the day a hook test needs a double |
| the Erlang and Node templates "kept in step by hand" (`onze/AGENTS.md`) | one pair | a pair per copy, drifting |
| a library's tests depending on another library's `-test` for mocking | never | jhonstart-test → rakun-test, or a second copy |
| `#[mock]` reachable from a plain project with no framework | yes — `import {mocks} from "std"` | no |
| principle *no lib-specific code in core* | std is a library, not the compiler; the runtime is plain botopink + `@Decl` + `@emit` + host cells, exactly as it is today | same |
| principle *one place, no drift* (decision 67 as applied to duplication) | satisfied | violated by construction |
| what `-test` submodules still own | the **pairing** — how a mock is injected into *their* library (`#[mocks.mock]` + `#[bean]` for rakun, front 19 § 8) | the same pairing plus a runtime |

**Recommendation: `std/mocks`.** The runtime is library-agnostic, small (one file, no sidecar), and
already dual-target. The `-test` submodules keep what is genuinely theirs: the injection pattern,
documented and tested in each. 1.0.9 front 95's phrase "the host runtime moves to the first `-test`
submodule that needs it" would make rakun-test the mocking library of the ecosystem by accident of
order.

**No sidecar.** `onze.mjs` exists because the recorder needs mutable, identity-based state. The
Erlang side never needed a sidecar — it puts the same tables in the process dictionary inside the
template. The Node side can do the same with `globalThis`, as `emilia.bp:24` does for its sheet:
`(globalThis.__bp_mocks ||= {…})`. Every `onze.mjs` function is under twenty lines and becomes the
body of an IIFE in the matching `@External.Node` template. std then ships exactly one sidecar, as it
does today (`sidecars/random.mjs`), and `mocks` is subject to STD-001 like any std module: its cells
are `pub declare fn` with Node and Erlang templates, so `import {mocks} from "std"` is refused on
beam and wasm — honestly, since no test runs there.

**Decorator resolution.** `#[mock]` today resolves the bare name `mock` imported from `"onze"`.
With the decorator in std, the consumer writes `import {mocks} from "std";` and `#[mocks.mock]`.
The parser accepts the dotted form (`parser.zig:899-902` reads an `.Ident` chain and lands
`"mocks.mock"` as the annotation name — the same path `@External.Erlang` takes). Whether the
decorator lookup resolves a qualified std name is the one compiler question step 4 carries; if it
does not, the fix is in the lookup, not in a bare re-export, because a bare `import {mock} from
"std"` would make `std` the first library whose functions are reached unqualified. The emitted body
references `mocks.invoke(self.__id, …)`, `mocks.key(…)`, `mocks.newMock()` qualified, which is the
one cross-module form that lowers today (`emilia/src/root.bp` note; `libs/std/AGENTS.md`).

## Removing the repository and reusing the directory

The 1.0.9 plan (`95` step 2) moved the old library to `repository/_archived/onze-mock/`. This front
does not: a checked-out directory is scanned by `zig build test-libs`, read by every `grep -rn` in a
gate, and is one more `AGENTS.md` to keep true. The old code is preserved where git preserves
things — in its own repository, tagged.

| # | Step | Where | Acceptance |
|---|---|---|---|
| 1 | `std/mocks` and the `asserts` migration are merged and green (step 4 above) | `libs/std` | `botopink test` + `--target erlang` green; the eight old tests pass in their new home |
| 2 | In `botopink/onze` (the old repository): tag the last commit `mocking-lib-final`, add a README banner naming `std/mocks` and `std/asserts` as the successors, push, archive the repository on the remote | old remote | the tag resolves; the repository is read-only |
| 3 | Front 49 creates the orchestrator repository under the name `onze` on the remote (`botopink/onze` if the old one was renamed first — e.g. to `botopink/onze-mocking` — otherwise a fresh name the `.gitmodules` `url` points at) | remote | `repository/onze/botopink.json` reads `"name": "onze"` |
| 4 | Re-point the submodule: `.gitmodules` `[submodule "repository/onze"] url = <orchestrator url>`, `git submodule sync`, check out the orchestrator's `feat` at `repository/onze` | meta | `git submodule status` shows the orchestrator's commit at `repository/onze` |
| 5 | `zig build test-libs` reads an `onze` cell for the orchestrator, none for the old library | `repository/botopink-lang` | green |
| 6 | Sweep the seven remotes (meta + six submodules) on `feat` | all | unified |

The directory name never changes and the submodule *entry* never disappears — only what it points
at. That is what "the directory name is then reused" means in practice.

## The `onze13 → onze` rename checklist

1.0.9 already did most of this at the spec level: the track-E fronts are `49-onze-stand-up` …
`53-onze-example-app`, `68-onze-client-bundle` … `71-onze-release-packaging`, and their **Owns**
lines read `repository/onze/…`. What remains:

| Where | `onze13` today | Action |
|---|---|---|
| `specs/1.0.9-beta/{49,50,51,52,53}-onze-*/README.md` **Replaces:** lines | `1.0.7-beta/01-onze13-stand-up` etc. | historical — stays (they name the 1.0.7 directories, which are called that) |
| `specs/1.0.9-beta/49-onze-stand-up/README.md:293` | prose | stays (1.0.9 is closed) |
| `specs/1.0.9-beta/overview.md:80`, `:220`; `95-…/README.md` | "the orchestrator drafted as `onze13`" | stays; `unification.md` here records the takeover as done |
| `specs/1.0.10-beta/06-onze/**` | none expected | `grep -rn onze13 specs/1.0.10-beta/` finds only **Replaces:** lines and `unification.md` |
| `repository/onze/botopink.json` | the old library's `"name": "onze"` | becomes the orchestrator's `"name": "onze"` (step 4 of the swap) |
| `repository/onze/{README,AGENTS,docs}.md` | the mocking docs | the orchestrator's (front 49 writes them) |
| `import {…} from "onze"` in the 1.0.10 copies of fronts 49–53, 68–71 | already `onze` | nothing |
| `import {mock, …} from "onze"` (mocking) | front 19's example | `import {mocks} from "std"` |
| `.gitmodules` | old remote | orchestrator remote (swap step 4) |
| `specs/1.0.9-beta/fronts.md`, `overview.md` Track E headers | already `onze` | nothing |

## `libs/std/src/mocks.bp` — the shape

```bp
//// std/mocks — Mockito-style mocks over a `behavior`: `#[mocks.mock]` synthesizes
//// the double, `when(...)` stubs, `verify(...)` checks call counts.
////
//// Lifted 100 % from the retired `onze` library (`botopink/onze`, tag
//// `mocking-lib-final`). The Erlang templates are verbatim; the Node templates
//// inline what `onze.mjs` held, with the tables on `globalThis.__bp_mocks`.
//// commonJS and erlang only — every cell is a `pub declare fn` and STD-001
//// refuses the import on beam and wasm, where no test runs.

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

A consumer:

```bp
import {asserts, mocks} from "std";

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
| A decorator emitted body must see the runtime it calls | `#[mocks.mock]` | the consumer imports `mocks` | `@emit` that can name its own imports |
| Decorator lookup of a qualified std name (`#[mocks.mock]`) | step 4 | verify; fix the lookup if bare-only | — |
