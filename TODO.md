# TODO — Front B: libs & examples test coverage (v0.beta.13)

**Branch**: `task/v13-libs` (from `origin/feat` @ eac9313)
**Spec**: `tasks/v0.beta.13/specs/front-b-libs.md`
**Front territory** (edit ONLY here): `libs/**` (`.bp` `test {}` blocks) + `examples/**`
(demo apps with their `.bp` unit tests). File-disjoint from Fronts A (`task/v13-core`) and
C (`task/v13-tooling`).
**Status**: DONE — `botopink-lib-test --target commonJS` green (5 libs pass, 2 no-tests);
all six demo apps green under `botopink test`. erlang stays at the pre-existing
backends-parity baseline (erika/jhonstart/onze/rakun ✗ on erlang — `drop`/`forEach`/
`fold`/`toString` undefined in generated `.erl`; std ✓ on both targets).

> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test; lib
> behaviour runs via `botopink test` / `botopink-lib-test`. Goal: close each `[gap]` (add a
> `.bp` test or a demo) or record it. No production behaviour change expected.

## Areas (see front-b-libs.md for the tagged scenarios + examples)

- [x] B1 stdlib — Option map/flatMap/unwrapOr (`dict.bp` over `lookup`'s `?V`); Result
      map/flatMap/unwrapOr (`test/result_test.bp`, `#[@result]` producers); Array combinators +
      Order-driven sort + Queue BFS (`examples/stdlib-tour`); empty-collection boundary in
      dict/queue/sets; `to_string` gate verified (only `@external` host symbols — botopink
      surface is `toString`). RECORDED: structural record keys / record-set dedup (`==` on
      records is reference equality); `result.isOk`/`isError` not lowered by commonJS.
- [x] B2 sublanguages (lib-side) — erika two-column `where` (`w = h and h > 2`), `erika "…"` in
      argument position, two erika strings in one scope → independent queries (`examples/erika-linq`);
      deeply nested html with mixed text + `${holes}` (`examples/jhonstart-html`).
- [x] B3 frameworks — rakun overlapping path prefixes + leaf (no-dep) #[service] resolution
      (`test/overlapping_routes_test.bp`); jhonstart SSR-of-a-hook-consuming component
      (`examples/jhonstart-counter`); onze verify-after-different-arg-calls + new `examples/onze`
      demo. RECORDED: jhonstart lone-child/bare-string Children render (needs runtime
      normalization tag); onze `thenThrow` caught by try/catch (try/catch is `@Result`-only, host
      throw uncatchable) + generic `any<T>()`/captor (needs per-type default / host cell); rakun
      missing-dependency error is a COMPILE diagnostic (Front A annotation-processor suite).

## Demo apps to ship (each with `.bp` `test {}`)
- [x] `examples/stdlib-tour/` (B1, new) · `examples/erika-linq` + `examples/jhonstart-html` (B2)
- [x] `examples/rakun` + `examples/jhonstart-counter`; new `examples/onze/` (B3)

## Done means
`botopink-lib-test` green with the new `.bp` tests + demo apps; every B-front `[gap]` closed
or recorded. Integrate into `feat` via a throwaway `.tasks/_integrate-v13-libs`.
