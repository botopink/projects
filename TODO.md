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

## F1 — core types (`element.d.bp`)

- [ ] Confirm `Element` is accepted as a ContextBase from a library declaration
      (today it is a builtin in `builtins.d.bp`) — decide re-export vs. re-declare
- [ ] `Children` coercions (`string`→text, `Element`→`[Element]`) — document + test

## F2 — DOM builders (`dom.d.bp`)

- [ ] Node runtime stub `jhonstart/runtime` (`el`, `mount`, `text`, `input`) so the
      counter/todo demos run on the `commonJS` target
- [ ] Attrs strategy for V1 (event handlers as explicit params; full attrs = future)

## F3 — hooks + composite ergonomics

- [ ] Verify `use state(0)` type-checks inside `-> Element`; rejected inside `-> string`
- [ ] `fragment.bp` (`Fragment`), custom hooks (`useToggle`) — `.bp` bodies on the intrinsics
- [ ] `html.bp` body: walk `q.parts()`, splice `${…}`, resolve `<Component/>` via
      `q.lookup` (miss → `q.failAt`), map lowercase tags to builders, `q.build`
- [ ] Confirm the expr-template surface composes for building `Element` (not just `string`)

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
check ---- counter_typechecks / use_outside_element_rejected / hook_compose_transitive
check ---- server_loader_await / request_http_context
check ---- html_component_tags / html_unknown_component / html_interp_hole
codegen/node ---- counter_runs / todo_runs / html_expands_to_tree / ssr_render_to_string
codegen/erlang ---- counter_typechecks (parity)
```
