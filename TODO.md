# TODO — task/jhonstart

> Live checklist for branch `task/jhonstart` (worktree `.tasks/jhonstart/`).
> Spec (intent, immutable): [`tasks/v0.beta.5/specs/jhonstart.md`](tasks/v0.beta.5/specs/jhonstart.md)
>
> A React/Next-style UI framework written in botopink, on the language's own
> primitives (no new compiler features). Work happens in THIS worktree.

## Compiler prerequisites (cross-set, not part of this task)

- [x] `context-inference` — `@Context<B,R>` gating `use` (landed)
- [x] `expr-templates` — `@Expr`, tagged calls, `parts/lookup/build` (landed; powers `html`)
- [ ] `use-await-prefix` — `use`/`await` prefix operators (pending, `tasks/v0.beta.1/`)
- [ ] `async-generators` — `*fn`, `await`, `@Future` (pending, `tasks/v0.beta.1/`)

> Gate: F1–F3 (hooks/`use`) land once `use` is in `feat`; F4–F5 (SSR/server
> loaders) gate on the async work. The `html` DSL itself needs only expr-templates.

## F0 — package scaffold ✅ (this commit)

- [x] `libs/jhonstart/botopink.json` (`files: []` — inert, not embedded)
- [x] `libs/jhonstart/AGENTS.md` + `src/AGENTS.md` + `docs.md`
- [x] Add the package row to `libs/AGENTS.md` (table + tree)
- [x] Declaration surface: `src/{element,dom,hooks,html,render,router,server}.d.bp`
- [x] Examples landed: `examples/jhonstart-{counter,todo,html,app}/`
- [x] `examples/AGENTS.md` updated with the four demos

## ⚠ Language gaps surfaced while probing F1–F3 (BLOCKERS — split out as language specs)

> Verified empirically on this branch via `modules/compiler-core/src/comptime/tests/jhonstart.zig`.
> Per "no new compiler features", jhonstart does NOT work around these. Full
> detail in the spec Notes ("Language gaps surfaced by F1–F3").

- [ ] **G1** — records cannot carry function-typed fields (`set: fn(next)`), so
      the hook shape `{value, set}` is inexpressible → blocks builder-API hooks
- [ ] **G2** — no anonymous record TYPE syntax (only value literals)
- [ ] **G3** — `fn() -> T[]` does not parse (array as a function-type return)
- [ ] **G4** — no `Element[]` → `Children` coercion → blocks `div { [a, b] }`

## F1 — core types (`element.d.bp`)

- [x] Confirm `Element` is accepted as a ContextBase (it is a builtin; usable as
      `@Context<Element, _>` from inlined declarations — verified in check tests)
- [ ] `Children` coercions (`string`→text, `Element`→`[Element]`) — **blocked by G3/G4**

## F2 — DOM builders (`dom.d.bp`)

- [ ] Builder children model `div { [a, b] }` — **blocked by G3/G4**; V1 uses the
      `html` DSL + `fragment(Element[])` assembly instead
- [ ] Node runtime stub `jhonstart/runtime` (`el`, `mount`, `text`, `input`) so the
      counter/todo demos run on the `commonJS` target
- [ ] Attrs strategy for V1 (event handlers as explicit params; full attrs = future)

## F3 — hooks + composite ergonomics

- [x] `use state(0)` type-checks inside a component; rejected inside `-> string`;
      ContextBase mismatch (Element vs Http) rejected — `check` tests landed
- [x] Confirm the expr-template surface builds an `Element` (not just `string`) —
      `html_component_tags` + `html_interp_hole` compile end-to-end
- [ ] `{value, set}`-shaped hook returns + `useToggle({on, toggle})` — **blocked by G1**
- [ ] `html.bp` body (full markup scan): walk `q.parts()`, splice `${…}`, resolve
      `<Component/>` via `q.lookup` (miss → `q.failAt`), map lowercase tags to
      builders, `q.build` — mechanism verified; full `appendMarkup` body pending

## F4 — render (`render.d.bp`)

- [ ] `mount` (client) + `*fn renderToString` (SSR) runtime stubs
- [ ] End-to-end: `renderToString(Page) -> HTML string`

## F5 — app layer (`router.d.bp`, `server.d.bp`)

- [ ] `Router`/`useRouter`/`Link`; `Http` ContextBase `request()`
- [ ] Document file-routing convention (`app/`, `page.bp`, `layout.bp`, `[id]`)

## F6 — docs

- [ ] `docs.md` (lib) full pass; root `docs.md` + `README.md` "Frameworks → jhonstart" pointer

## Test scenarios (acceptance)

```
check ---- counter_typechecks            ✅ (tests/jhonstart.zig)
check ---- use_outside_element_rejected  ✅ (snapshot)
check ---- hook_compose_transitive       ✅ (named-record return; {on,toggle} blocked by G1)
check ---- contextbase_mismatch          ✅ (snapshot; Element vs Http)
check ---- html_component_tags           ✅ (q.build → Page1(); via fragment)
check ---- html_interp_hole              ✅ (${expr} → text child)
check ---- html_unknown_component        ☐  needs full html.bp body (q.failAt path)
check ---- server_loader_await           ☐  gated on async-generators
check ---- request_http_context          ☐  gated on async-generators (Http ctx ok today)
codegen/node ---- counter_runs / todo_runs / html_expands_to_tree / ssr_render_to_string ☐
codegen/erlang ---- counter_typechecks (parity) ☐
```
