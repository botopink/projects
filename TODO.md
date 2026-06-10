# TODO — jhonstart (de-couple the UI framework into a pure client)

> Task branch `task/jhonstart-port` · spec
> [`tasks/v0.beta.7/specs/jhonstart.md`](../../tasks/v0.beta.7/specs/jhonstart.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test.
>
> ✅ **UNBLOCKED.** `annotation-processors` P0 landed in `feat` (merged here): the
> `comptime/tests/jhonstart.zig` probe + `infer.zig` comments are gone and the
> `grep -riE "rakun|jhonstart" modules/compiler-core/src` gate is green. jhonstart
> now stands up as a pure client of the generic `from "<lib>"` loader + the G1–G4
> gaps. F1/F3/F4/F5 done; F2 deferred (two generic core gaps); two generic
> cross-module compiler fixes were needed (committed separately, lib-agnostic).

## F0 — stand up as a pure client (post-decoupling)
- [x] `element.bp` + `hooks.bp` type-check and `renderToString` runs with **no**
      jhonstart reference in `compiler-core` (gate green). Consumer-side
      `import … from "jhonstart"` value binding is partially gated on the generic
      *loader-bare* fix (it binds the namespace, not bare values/template-fns —
      recorded; the lib's own `botopink test` validates the `.bp` directly).
- [x] The framework coverage lives as `test {}` blocks **inside
      `libs/jhonstart/src/*.bp`** (6 tests: render + G4 coercion in `element.bp`;
      the hook family + a `use`-component in `hooks.bp`). No compiler Zig suite.
- [x] `botopink.json` is the only wiring (now lists `element.bp`, `hooks.bp`, and
      the gated `.d.bp` surface); nothing embedded into the prelude.

## F1 — hooks: promote `hooks.d.bp` → real `.bp` (G1 + G2)  ✅
- [x] `record State<T> { value: T, set: fn(next: T) }` (G1) + the hook family
      (`state`/`effect`/`memo`/`ref`/`reducer` — the established names; React's
      `useState`/… is the per-target `use` lowering) get **real SSR bodies** over
      `@Context<Element, _>`, returning the `{value, set}`/`{current}`/`{state,
      dispatch}` shapes (G2 anon types). `hooks.d.bp` deleted. Bodies unit-tested
      by direct call; a `use`-component type-checks the capability.

## F2 — html DSL: implement the `html` template body (expr-templates)  ⛔ DEFERRED
- [ ] BLOCKED on two **generic** core gaps (neither jhonstart-specific, both
      recorded in `html.d.bp` + AGENTS): (1) a comptime template body sees only a
      native-JS prelude — a markup stack parser wants `pop()`/`at()` whose `?T`
      type-checks but has no Option runtime in the eval; (2) the generic loader
      binds a lib's namespace but not a bare imported template-fn, so
      `import {html} from "jhonstart"; html "…"` is unbound (same gap as
      `erika "…"`). `html.d.bp` kept as the declared surface with the gating note.

## F3 — children ergonomics + builder API (G3 + G4)  ✅
- [x] `Element.children` and every builder take a `Children` arg, so `div([a, b])`
      exercises the G4 `Element[]`→`Children` coercion; single-`Element`/`string`
      also type-check (asserted). The **list form** renders (the contract); nested
      lists build deep trees (tested). Trailing-lambda `div { [a, b] }` and
      lone-child/`string` *rendering* recorded as follow-ups.

## F4 — router + server context as real `.bp` where expressible  ✅
- [x] Nothing in `router.d.bp`/`server.d.bp` is promotable to renderable `.bp`
      yet: `useRouter`/`request` are host-bound `#[@external]`, `Link` needs an
      Element attribute slot (`href`), the interfaces use `.d.bp`-only `get`
      accessors, and the async SSR loaders are gated on
      `use-await-prefix`/`async-generators`. Both files keep the surface with an
      explicit **STILL GATED** note naming each gap.

## F5 — docs  ✅
- [x] `libs/jhonstart/AGENTS.md`, `src/AGENTS.md`, `docs.md` updated for the
      `.d.bp`→`.bp` promotions, the `Children` builders, the loader path, and the
      cleared (G1–G4) / remaining gaps — same commit as the code.

## Done gate
- [x] Tests live in `libs/jhonstart/src/*.bp` (`botopink test`), not compiler Zig suites.
- [x] `grep -riE "jhonstart" modules/compiler-core/src` returns nothing (P0 gate).

## Compiler fixes (committed separately — generic, lib-agnostic)
- [x] `fix(comptime): generic cross-module nominal-type resolution` — a local
      component `fn … -> Element` (imported type) feeding an imported
      `renderToString`/`use` now type-checks (`type_decl_registry` cross-module
      `TypeDef` propagation + `resolveTypeName` constructor-vs-type guard). The
      `grep` gate stays clean; full `zig build test` passes.
