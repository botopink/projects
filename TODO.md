# TODO — erika (de-couple the LINQ lib onto the generic loader)

> Task branch `task/erika-port` · spec
> [`tasks/v0.beta.7/specs/erika.md`](../../tasks/v0.beta.7/specs/erika.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test.
>
> ✅ **Unblocked.** `annotation-processors` merged into `feat` (the generic
> `from "<lib>"` loader landed: `compiler-cli/src/cli/libs.zig`). erika moved out
> of `std` into `libs/erika/*.bp` with **no new compiler-core code** (the gate
> covers `erika` too).

## F0 — package extraction + generic loader wiring
- [x] Created `libs/erika/` with `botopink.json` (`files: ["erika.bp"]`),
      `src/erika.bp` (moved from `libs/std/src/erika.bp`), `AGENTS.md`, `docs.md`,
      `examples.md`.
- [x] **Removed** `"erika.bp"` from `std_pkg_files` in **both** `build.zig` and
      `modules/compiler-core/build.zig`; dropped the erika rows from
      `libs/std/src/docs.md`/`examples.md`/`AGENTS.md` (left "moved" pointers).
      `std` no longer ships erika (verified: `libs/std` test suite still green).
- [x] `import {erika} from "erika"` resolves through the generic loader;
      `botopink test` in `libs/erika` discovers `src/erika.bp` (21 blocks pass).
      Zero `modules/compiler-core/src/**` edit. Added `erika` to the lib-agnostic
      gate alternation in root `build.zig`.

## F1 — close the `erika "…"` import-resolution limit
- [ ] **GAP RECORDED (not closed) — requires generic loader work that is out of
      scope here.** The generic `from "<lib>"` loader binds the lib **namespace**
      only (so `erika.of(...)` works), but does **not** bind bare imported values
      into value scope — confirmed with a throwaway probe lib where even a plain
      `import {plain} from "lib"` leaves bare `plain` unbound, and a non-colliding
      template fn `qq "…"` is unbound too. So `erika "…"` after
      `import {erika} from "erika"` is still `unbound variable 'erika'`. Closing it
      means **generic** bare-value / template-fn import binding in the loader/import
      resolver (compiler-core) — forbidden here (no new core code; the gate forbids
      erika in core). Fully documented in `libs/erika/AGENTS.md` + `docs.md`.
- [x] Confirmed the eager comptime body still runs over the minimal `node` prelude
      after the move — the in-file `erika "…"` tests pass (the template fn is a
      directly in-scope identifier there). No regression from the move.

## F2 — fluent ops the language now allows (v0.beta.6 deferrals)
- [x] `selectMany` **landed** — `fn(item: T) -> Array<U>` selector, flattened.
      Unblocked by `fn() -> T[]` in a function-type param (G3, in `feat`).
- [x] Multi-field projection **landed** — `select a, b` ⇒ an anonymous structural
      `record { a: row.a, b: row.b }` per row. Unblocked by anonymous record types
      (G2, in `feat`). Commas attached (`a, b`) or spaced (`a , b`) both parse.
- [x] Kept the distinct-name predicate variants (`countWhere`/`firstWhere`/
      `anyWhere`) — no arity overloading on the JS backend.

## F3 — docs + tests in the lib
- [x] `libs/erika/docs.md` + `examples.md` cover both forms; `libs/erika/AGENTS.md`
      documents the package, the loader path, the comptime-eval constraint, and the
      F1 gap. Updated in the same change as the code.
- [x] All tests live in `libs/erika/src/erika.bp`'s own `test "…"` blocks — the 19
      v0.beta.6 blocks moved with the file + `selectMany` + multi-field projection
      (21 total, all pass under `botopink test`).

## Done gate
- [x] Tests live in `libs/erika/src/erika.bp` (`botopink test`), not compiler Zig suites.
- [x] `grep -riE "erika" modules/compiler-core/src` returns nothing.
- [x] `zig build test` green (compiler suite + the erika-inclusive lib-agnostic gate).

## Notes / parser gotchas hit during the port
- The `erika "…"` comptime body runs over a **minimal `node` prelude** in
  `template_eval.zig` — native-JS ops only. `.split`/`.join`/`.slice`/`.trim`/
  `.map`/`.append`/`.length` are fine; optional `.at(i).unwrapOr(…)` is **not**
  (undefined in the eval script → surfaces as a terse "parse error"). The field
  list is built with `append`+`map`+`join`, never `fields.at(0).unwrapOr(…)`.
- A top-level binary boolean **directly inside `if (…)` fails to parse**
  (`if (a && b)`). Extract to a `val` first — the established `erika.bp` style.
