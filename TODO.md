# TODO — rakun (port onto annotation-processors)

> Task branch `task/rakun-port` · spec
> [`tasks/v0.beta.7/specs/rakun.md`](../../tasks/v0.beta.7/specs/rakun.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test.
>
> ⛔ **BLOCKED on `annotation-processors`.** rakun is a pure-`.bp` client of the
> generic decorator mechanism — it cannot start until that lands in `feat`. When
> it does, `git merge feat` into this worktree, then implement all semantics in
> `libs/rakun/*.bp` (lib-side decorator bodies), **no new compiler-core code**.
>
> 📎 The interim core-coupled F2/F3 reference implementation is preserved on the
> `task/rakun` branch (`feb96f0`) — port the *behaviour*, do not merge that Zig.

## F2 — IoC container (lib-side, on annotation-processors)
- [ ] Comptime component scan: every `#[component]`/`#[service]`/`#[repository]`/
      `#[controller]`/`#[restController]` record in the unit.
- [ ] DI graph: a field whose type is a known component ⇒ a dependency edge;
      topo-sort; cycle → scoped diagnostic.
- [ ] Singleton scope (one instance per component type).
- [ ] `#[configuration]`+`#[bean]` factory contribution; `#[value("key")]` property.

## F3 — annotation argument validation
- [ ] Type-check `#[decorator(args)]` against the decorator signature (arity + types).
- [ ] Clear diagnostic for a marker on the wrong target.

## F4 — web layer / router
- [ ] `route` + `getMapping|postMapping|putMapping|patchMapping|deleteMapping(path)`
      → router table `{ method, path, handler }`.
- [ ] Path params (`:name`) → `req.param("name")`.
- [ ] `Response` builders type-check against the handler return type.

## F5 — bootstrap (`Rakun.run` + real HTTP backing)
- [ ] Promote `libs/server` from scaffold to a real minimal HTTP server (node
      first, then erlang) behind `#[@external]` host calls.
- [ ] `Request` gets a concrete server-supplied impl (`param`/`query`/`header`/`body`).
- [ ] `Rakun.run(app)` lowers (lib-driven): scan → instantiate singletons →
      register router → start server on `app.port`/`basePath`.
- [ ] e2e: a request to a mapped route invokes the handler and returns its `Response`.

## Done gate
- [ ] Tests live in `libs/rakun/*.bp` (`botopink test`), not compiler Zig suites.
- [ ] `grep -riE "rakun" modules/compiler-core/src` still returns nothing.
