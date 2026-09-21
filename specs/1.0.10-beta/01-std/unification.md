# Unification — what this front absorbed, and where it lives now

The proof that nothing was lost when the std half of 1.0.9 (and the two 1.0.7 std drafts behind it)
was gathered into `01-std/`. One row per source document or section; the last column says what,
if anything, had to be appended or changed.

## Sources → destination

| Source | Section(s) | Now in `01-std/` | Appended / changed |
|---|---|---|---|
| `specs/1.0.9-beta/01-std-lib-enablement/README.md` | whole | `01-std-lib-enablement/README.md` (verbatim copy, `cp -r`, diff-clean) | nothing — its *Test plan* says tests are `assert`-style; step 6 re-spells them with `try asserts.…`, a mechanical change the sub-front makes in its own files |
| `…/01-std-lib-enablement/examples/{net-server,path-and-process,crypto-and-encoding}-example.bp` | — | `01-std-lib-enablement/examples/` (verbatim) | nothing |
| `specs/1.0.9-beta/02-std-async-primitives/README.md` | whole | `02-std-async-primitives/README.md` (verbatim) | nothing |
| `…/02-std-async-primitives/examples/parallel-fetch-example.bp` | — | `02-std-async-primitives/examples/` (verbatim) | nothing |
| `specs/1.0.9-beta/03-std-content-hash/README.md` | whole | `03-std-content-hash/README.md` (verbatim) | nothing |
| `…/03-std-content-hash/examples/cache-key-and-etag-example.bp` | — | `03-std-content-hash/examples/` (verbatim) | nothing |
| `specs/1.0.9-beta/95-ecosystem-package-restructure/README.md` | *Problem* 1–2, *Current state* (onze, asserts rows) | `README.md` § *Problem*, `onze-migration.md` § *Inventory* | re-measured: line counts and the "does not exist" claim of front 49 reconciled with the disk |
| same | § 3 *The `onze` rename* (table: assertions → std/asserts; mocking → `-test`) | `onze-migration.md` § *Where the assertion surface goes*, § *Where the mocking surface goes* | **changed**: `eq`/`anyInt`/`anyString` are matchers, not assertions; mocking goes to `std/mocks`, not to the first `-test` (argued) |
| same | § 4 *`std/asserts` — the full surface* (nine tables) | `asserts-api.md` | **changed**: every fn returns `@Result<void, string>`; names aligned (`truthy → isTrue`, `equal → equals`, `empty → isEmpty`, `hasLength → lengthIs`, `isErr → isError`); `positive`/`negative` folded into `greaterThan`/`lessThan`; `isOkAnd`, `throwsType`, `typeOf`, lifecycle hooks **not shipped** (reasons in the migration table); the § 4 opening line "renamed to `assert.bp`" contradicted its own step 1 and the definition of done — `asserts.bp` stays |
| same | § 5 *The `-test` submodule pattern* | `snapshots.md` § *How a library exposes helpers*, `examples/emilia-test-submodule-example.bp` | **changed**: no one-by-one re-export of std/asserts from a `-test` (its own rule says import, don't re-implement); helpers take `loc: SourceLocation` first |
| same | step 1 (expand `asserts.bp`) | `README.md` step 2 | acceptance rewritten for the `@Result` shape |
| same | step 2 (`onze` structure, `_archived/onze-mock/`) | `README.md` step 5, `onze-migration.md` § *Removing the repository* | **changed**: archived on the remote by tag, not vendored under `repository/_archived/` |
| same | step 7 (deprecate the old lib, banner) | `onze-migration.md` swap step 2 | banner kept; lives in the old repository's README |
| same | *Language gaps* (hooks, deepEqual, cross-module, defaults) | `asserts-api.md` § *Language gaps*; hooks below | — |
| same | `examples/assert-usage-example.bp` | superseded by `examples/asserts-unit-example.bp` | rewritten against the `@Result` API; the two `LANGUAGE GAP` comments it carried (`@Result` literal construction; lifecycle hooks) are answered — `isOk` takes the result of a `#[@result]` call, hooks are a toolchain gap below |
| same | `examples/test-submodule-pattern-example.bp` | superseded by `examples/emilia-test-submodule-example.bp` + `emilia-test-consumer-example.bp` | rewritten: real emilia surface (`Token`, `tokensToCss`, `emilia`), `@src()`, snapshots; its `Token.padding(16)` / `Element.div()` placeholders had no counterpart in `repository/emilia/src/` |
| `specs/1.0.9-beta/tracks/README.md` | § *The test contract every track writes against* (the `SourceLocation` line, the `assertCss` example, the three bullets) | `src-builtin.md` (record + rules), `snapshots.md` § *The three rules, restated* + § *The two examples from the plan* | the `[.Md([.Hover([.Bg.Color.Red.500])])]` spelling does not parse and `Bg.Color` does not exist — the example is re-spelled with typed intermediates and `Bg.Red.500`; the rules are unchanged |
| same | Track A row (`std/asserts.md`, `std/snapshots.md`, `std/modules.md`) | `asserts-api.md`, `snapshots.md`, `modules.md` | written for the first time |
| `specs/1.0.9-beta/96-src-builtin-and-snapshots/` | never written | `src-builtin.md`, `snapshots.md` | written for the first time; the compiler files it would have named are named at HEAD `b5ceb203` |
| `specs/1.0.9-beta/contracts.md` | no std row exists — contracts 1–6a are owned by fronts 22–69; the std surfaces they cite (`crypto.hmacSha256`, `std/json` "has no walker") are 01's and 03's | `01-std-lib-enablement/README.md` requirements table | nothing to move; noted so the absence is a finding, not an omission |
| `specs/1.0.9-beta/language-gaps.md` | rows citing 01 · 02 · 03 (bitwise, `toString(radix)`, bytes, cross-module, destructuring, eager `@Future`, cancellation, defaults) | the three copied READMEs' own *Language gaps* tables carry them | nothing; rows citing 95 (hooks, deepEqual) → `asserts-api.md` |
| `specs/1.0.9-beta/fronts.md` | Track A ownership rows (F01/F02/F03) and the `root.bp` conflict note | `modules.md` § *Ownership table*, `README.md` § *Ownership and conflicts* | `root.bp` now also carries `snapshots` and `mocks` |
| `specs/1.0.9-beta/overview.md` | Track A rows (`01`–`03`), the F row (95), the wave-0 diagram, *Rules* (reuse std, compiler knows none of this) | `README.md` § *Order*; the *Rules* bind unchanged | the "compiler knows none of this" rule has one named exception this milestone — step 1 — stated in the README header |
| `specs/1.0.7-beta/17-std-async-primitives/README.md` | `all`/`allSettled`/`race`, `delay` in the test, `async.mjs` sidecar, "other futures are cancelled (or ignored)", `val [users, posts] = …` | all carried by the 1.0.9 `02` copy: *Mechanism* (the two surfaces), step 1 (`delay`, `failed`), *Mechanism* ("there is no sidecar"), *Language gaps* (no cancellation; no array destructuring) | **nothing missing** — no `## Carried from 1.0.7-beta F17` section needed |
| `specs/1.0.7-beta/18-std-crypto-hash/README.md` | `contentHash` (djb2 as emilia), `contentHashObject(obj: any)`, the ETag `withHeader` example, stability tests | carried by the 1.0.9 `03` copy: step 1 (`contentHash` lifted verbatim from `emilia.bp:39-40`), *Current state* + *Language gaps* (`contentHashObject` dropped — `std/json` has no structured value), steps 3–4, *Test plan* | **nothing missing** — `contentHashObject` is a documented, reasoned drop, not an omission; no `## Carried from 1.0.7-beta F18` section needed |
| `repository/onze/README.md`, `docs.md`, `AGENTS.md`, `src/AGENTS.md` | the API tables, the design notes, the two core fixes (`@emit` ordering, behavior-level markers) | `onze-migration.md` § *Inventory*, § `libs/std/src/mocks.bp` — *the shape* | the docblock of `mocks.bp` carries the design notes; the "two core fixes" are upstream since v0.beta.8 and need no mention beyond this row |
| `repository/onze/src/onze.bp` | 8 host cells, 3 matchers, 3 specs, `OnzeStub`, `when`, `verify`, `mock` | `onze-migration.md` § *Exported symbols* — every `pub` symbol with its line and destination | names: `onze*` prefix dropped, `OnzeStub → Stub`, three cells renamed to avoid clashing with the public fns |
| `repository/onze/src/onze.mjs` | 8 exports, 2 helpers, 6 module globals | `onze-migration.md` § *The Node runtime* | **changed**: no sidecar — inlined as `globalThis.__bp_mocks` templates |
| `repository/onze/test/onze_test.bp` | 8 tests, 2 recorded limitations | `onze-migration.md` § *Test surface*; `test-snap.md` § `mocks.bp` | the verify-message wording unified on the Erlang form, pinned by one snapshot |
| `repository/onze/examples/**` | `mock_synthesis.bp`, `examples/onze/` project | `onze-migration.md` § *Files* (inventory only) | not carried — the consumer example in `onze-migration.md` and the eight tests cover the surface; `examples/onze/out/` is build output |
| `repository/botopink-lang/libs/std/src/asserts.bp` | 9 fns, `AssertError`, 2 private cells, 10 tests | `asserts-api.md` § *Migration table* | rewritten; `AssertError` removed; cells kept |
| `repository/botopink-lang/libs/std/AGENTS.md` | § *Tests* (inline), § *Adding an importable module*, § *`#[@External…]`* (STD-001 paragraph) | `modules.md`, `asserts-api.md` rule 5 | nothing |
| `repository/botopink-lang/modules/compiler-core/src/utils/snap.zig` | the `.new` protocol and `BOTOPINK_SNAP_CREATE` | `snapshots.md` § *Mismatch, missing, match* | the `.new` protocol adopted; the create switch **not** adopted (decision 67) |
| `repository/botopink-lang/modules/compiler-core/src/codegen/tests/helpers.zig` | `slugify` (`:38`), `slugFromSrc` (`:80`), the `test "js: … ---- …"` naming, `assertJsSingle` (`:389`) | `snapshots.md` § *The path rule* (the slug rule byte-for-byte), § *The two examples* | adopted as the std rule so `.snap` names read like the 1 929 existing fixtures |

## Deferred out of this front

| Item | From | Why not here | Where it goes |
|---|---|---|---|
| Test lifecycle hooks `setup`/`teardown`/`setupAll`/`teardownAll` | 1.0.9 front 95 § *Test lifecycle* | the runner (`cli/test_cmd.zig`, `commonJS.zig:473-521`, `erlang.zig:1402-1407`) has no hook mechanism; a std fn cannot register one | a toolchain gap for the milestone's `language-gaps.md`: "the test runner calls registered hook functions around each `test` block" |
| `isOkAnd`, `throwsType`, `typeOf` | 1.0.9 front 95 § 4 | need a `case` over `@Result` inside a result body, a typed catch, a type-name intrinsic — none exists | the corresponding `language-gaps.md` rows |
| `BOTOPINK_SNAP_CREATE=1` in the compiler's own harness | `utils/snap.zig:139-143` | not this front's file; the std engine simply does not copy it | a question for the owner of `utils/snap.zig`, recorded here |
| `@Decl` gaining a `SourceLocation` | `language-gaps.md` (front 22's row) | `SourceLocation` now exists; threading it through decorator reflection is a separate compiler change | a follow-on compiler front |
| `mocks.verify:` message prefix (today `onze.verify:`) | `test-snap.md` § `mocks.bp` | kept for one milestone so old test output still greps | the next std front re-records one snapshot |
| `tokensToCss` made `pub` in emilia core | `examples/emilia-test-submodule-example.bp` | emilia's file, track D's front | `05-emilia` — one line, and front 56 replaces it anyway |

## What was measured, and when

Every count and every `file:line` in `01-std/` was read on 2026-09-20 at meta HEAD `b5ceb203` with
the six submodules at the commits the meta tree records. The three copies were verified with
`diff -r` against their 1.0.9 originals before anything else was written.
