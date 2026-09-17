# Group C — `libs/std` declarations and one stale filename (5.1, 5.2, 5.3, 5.14)

> Carried from `1.0.2-beta/11-hygiene/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

`libs/std`'s declared surface, and the comments still naming `primitives.d.bp`. Paths are relative
to `repository/botopink-lang/`; bare `codegen/…`, `comptime/…` and `comptime.zig` are under
`modules/compiler-core/src/`, `language-server/…` under `modules/`.

**The code half has landed.** The 1.0.2-beta std-surface front (its steps 5, 6 and 7 are items 5.3,
5.1 and 5.2 seen from the code side) deleted `reflect.bp` and `types.bp`, moved `primitives.bp`'s
tests to `libs/std/test/primitives_test.bp` + `primitives_gaps_test.bp`, and made the manifest's
`files` resolve. What is left here: re-derive 5.1–5.3 and strike what holds (the `AGENTS.md` tree,
which of the two file sets `primitives.bp` is in), and the 5.14 comment sweep. The `libs.zig:302`
diagnostic in 5.3 is [`../05-cli-residuals/`](../05-cli-residuals/README.md) step 5.

---

## Items

| # | Deciding site | What a reader sees | Smallest fix |
|---|---|---|---|
| 5.1 | `libs/std/src/root.bp:13-35` (23 `pub mod`, neither `reflect` nor `types`); `build.zig:35-39` `std_core_files` (three entries, neither) | `reflect.bp` (`mergeRecords`) and `types.bp` (`mapFields`, `partial`, `omit`, `pick`) are embedded by nothing: `stdPkgFilesFromRoot` (`build.zig:56`) derives the package set from `root.bp` alone. `libs/std/AGENTS.md:27-29` already lists them as "not declared". Neither has tests | Follow `std-surface` (1.0.2-beta, landed), which establishes that four of the five functions already exist as Zig builtins and the fifth (`mapFields`) exists nowhere. Recommended: delete both files and the `AGENTS.md:27-29` lines |
| 5.2 | `build.zig:36` + `comptime/stdlib/prelude.zig:12` | `primitives.bp`'s 67 `test` blocks (from `:296`) are `@embedFile`d as a source string and never compiled in test mode. `libs/std/test/` holds only `result_test.bp`. `pub mod primitives;` is not the fix — it would put the file in `std_core_files` **and** `std_pkg_files`, declaring the primitive interfaces twice | `std-surface` (1.0.2-beta, landed) step 7 (§6f) owns the move. This item closes when the file is in exactly one of the two sets |
| 5.3 | `libs/std/botopink.json:8-11` | `files` names `primitives.d.bp`, `array.d.bp`, `string.d.bp`, `builtins.d.bp`; only the last exists. `array.d.bp`/`string.d.bp` were folded into `primitives.bp` — `comptime.zig:615-618` binds both interface sources to the same blob. Read at `modules/compiler-cli/src/cli/libs.zig:300-312`; the `try` at `:302` aborts on the first miss with a bare `FileNotFound` and no diagnostic, unlike the manifest probe at `:289` | `std-surface` (1.0.2-beta, landed) step 5 (§6b). Additionally: make `libs.zig:302` name the missing path — a CLI change, so [`../05-cli-residuals/`](../05-cli-residuals/README.md)'s |
| 5.14 | the comment sites [below](#514--the-stale-primitivesdbp-name) | `primitives.d.bp` was renamed to `primitives.bp`. Two sites assert a location rather than just a name: `codegen/tests/features.zig:926` gives the full path `libs/std/src/primitives.d.bp`, and `language-server/src/engine.zig:4172` names all three phantom files together — the likely origin of the `botopink.json` drift | Rename in comments. Fix the `root.bp:9` header — the ambient files are `primitives.bp`, `builtins.d.bp`, `builtins_fns.d.bp`. **Leave** the two extension assertions (see below) |

## 5.14 — the stale `primitives.d.bp` name

Full list of comment sites to rename:

| File | Lines |
|---|---|
| `libs/std/src/root.bp` | `:9` (also fix the header's list of ambient files) |
| `libs/std/src/erlang.bp` | `:22` |
| `libs/std/src/math.bp` | `:27` |
| `comptime/stdlib/prelude.zig` | `:7` |
| `comptime/env.zig` | `:622` |
| `comptime/infer.zig` | `:6558, 6620` |
| `comptime.zig` | `:378, 615` |
| `test_warmup.zig` | `:3` |
| `codegen/erlang.zig` | `:1085, 1113, 1168, 1280, 1607, 1632, 1634, 1645, 2188, 3825` |
| `codegen/beam_asm.zig` | `:58, 832, 917` |
| `codegen/commonJS.zig` | `:779` |
| `codegen/tests/std_package.zig` | `:11` |
| `codegen/tests/features.zig` | `:825, 926` (`:926` gives the full, wrong path) |
| `language-server/src/engine.zig` | `:1100, 1113, 4172, 4448` (`:4172` names all three phantom files) |
| `language-server/src/tests/hover.zig` | `:181` |

That is 32 lines. The group summary in [`README.md`](./README.md) says 33; a grep for
`primitives\.d\.bp` over `*.zig`, `*.bp` and `*.md` in `repository/botopink-lang/` (excluding
`.botopinkbuild/`, `.tasks/`, `.zig-cache/`, `zig-out/`; measured 2026-09-16) returns 34 — these 32
plus the two below — and `libs/std/botopink.json:8` is a 35th match that 5.3 removes. A bare
`grep -rn` also matches the built binaries in `zig-out/bin/`; the acceptance row means source files.

**Leave these two.** Both assert that the `.d.bp` *extension* is not a compilable source, so the
string is an example of the extension, not a reference to a file:

- `modules/compiler-cli/src/cli/resolver.zig:635`
- `modules/lib-test-runner/src/discovery.zig:384`

`codegen/erlang.zig:3825` and `codegen/beam_asm.zig:917` also appear in
[`vocabulary.md`](./vocabulary.md)'s 5.13 list — one comment line carries both stale forms, so
rewrite it once.

## Steps

1. Wait for `std-surface` (1.0.2-beta, landed) steps 5–7 to land.
2. **5.1** — confirm `reflect.bp`/`types.bp` are gone (or declared with tests), and make
   `libs/std/AGENTS.md:27-29` match.
3. **5.2** — confirm `primitives.bp` sits in exactly one of `std_core_files` / `std_pkg_files`.
4. **5.3** — confirm `libs/std/botopink.json` `files` resolves; hand the `libs.zig:302` diagnostic
   to [`../05-cli-residuals/`](../05-cli-residuals/README.md) if it has not taken it.
5. **5.14** — rename the 32 comment sites, one commit per owning file (see
   [Ownership](#ownership)); rewrite the `root.bp:9` header.

## Acceptance

- [ ] `grep -rn 'primitives\.d\.bp'` returns only the two extension-assertion tests
- [ ] Every `files` entry in every `botopink.json` in the workspace resolves
- [ ] `libs/std/AGENTS.md`'s tree matches `src/`

Group C may add known failures to `zig build test-libs` (for example the tests 5.2 makes
reachable) — register them by name in the front that owns them, do not fix them here.

## Ownership

`libs/std/**` is `std-surface` (1.0.2-beta, landed)'s, and that front's step 5
also claims `libs/std/botopink.json`. Whichever lands first makes the manifest edit; the other
verifies it.

The 5.14 sweep edits comments in files other fronts own:

| Files | Owner |
|---|---|
| `codegen/erlang.zig` | `comptime-dispatch` (1.0.2-beta, landed) (untyped path), [`../01-backend-residuals/`](../01-backend-residuals/README.md) (both paths now) |
| `codegen/beam_asm.zig` | [`../01-backend-residuals/`](../01-backend-residuals/README.md) |
| `codegen/commonJS.zig` | [`../01-backend-residuals/`](../01-backend-residuals/README.md) |
| `comptime/infer.zig`, `comptime/env.zig` | [`../06-checker/`](../06-checker/README.md) |
| `codegen/tests/**` | [`../08-review-backlog/`](../08-review-backlog/README.md) |
| `libs/std/src/*.bp` | `std-surface` (1.0.2-beta, landed) |

A comment-only edit in another front's file is safe to make and expensive to merge: do it last,
after the owning front has landed, or hand the line to that front.
