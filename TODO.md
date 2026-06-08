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

## F1 — core types (`element.bp`) ✅ — real botopink, compiled + runtime-tested

- [x] `Element` modelled as a `pub record Element { tag, value, children: Element[] }`
      (recursive record) — `libs/jhonstart/src/element.bp`, in `botopink.json`
- [x] `Element` usable as `@Context<Element, _>` base (builtin) — verified in check tests
- [x] String→text via the `text(...)` builder; child lists are `Element[]` (no
      `Children` interface needed — array-arg builders, see F2)

## F2 — DOM builders (`element.bp`) ✅ — `.bp`, not `@[external]`

- [x] `text`, `fragment`, `div`/`span`/`p`/`h1`/`ul`/`li` — real `.bp`, take `Element[]`
- [x] Sidestep G3/G4: builders take `Element[]` args (`div([a, b])`), not the
      `fn() -> Children` trailing-lambda form (`div { [a, b] }`, which IS blocked)
- [ ] `button`/`input` with event handlers — client-only; deferred (handlers can't
      be stored in the record, G1; SSR ignores them)
- [ ] Attrs strategy for V1 (full attrs record = future)

## F3 — hooks + composite ergonomics

- [x] `use state(0)` type-checks inside a component; rejected inside `-> string`;
      ContextBase mismatch (Element vs Http) rejected — `check` tests landed
- [x] Confirm the expr-template surface builds an `Element` (not just `string`) —
      `html_component_tags` + `html_interp_hole` compile end-to-end
- [ ] `{value, set}`-shaped hook returns + `useToggle({on, toggle})` — **blocked by G1**
- [ ] `html.bp` body (markup scan) — **next focused increment**. Comptime string
      ops in a template body (`q.text`/`.split`/`.trim`/accumulate/`q.build`) are
      VERIFIED to run. With the array-arg builders, it can lower **nested**
      `<div><p>…</p></div>` → `div([p([…])])`, `<Comp/>` → `q.lookup` → `Comp()`
      (miss → `q.failAt`), `${…}` → `text(…)`. G4 no longer caps this (it only
      blocked the `fn() -> Children` form, which the core avoids).
- [ ] `html_unknown_component` check (`<Page9/>` → `q.failAt`) — lands with `html.bp`

## F4 — render (`element.bp`) ✅ for SSR string; client `mount` pending

- [x] `renderToString(e: Element) -> string` — **pure, synchronous `.bp`**; needs
      NO async-generators. `test {}` asserts `<div><p>hi</p>!</div>` etc.
- [ ] `mount` (client DOM attach) — host-bound `#[@external]`; pending runtime stub
- [ ] `*fn renderToString` async variant (await server loaders) — gated on async

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
ssr_render_to_string                     ✅ (element.bp `test {}` — runs via `botopink test`)
codegen/node ---- counter_runs / todo_runs / html_expands_to_tree ☐
codegen/erlang ---- counter_typechecks (parity) ☐
```

> **Architecture note (per user guidance "prefer `.bp` over `.d.bp`")**: the UI
> core (`element.bp`) is implemented in real botopink — recursive `Element`
> record, array-arg builders, synchronous `renderToString` — compiled by
> `botopink.json` and runtime-tested by its own `test {}`. Only genuinely
> host-bound / gap-blocked surface (interactive hooks, client `mount`, router,
> Http server context) stays as illustrative `.d.bp`.
