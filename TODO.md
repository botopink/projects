# TODO — rakun

> Live checklist for branch `task/rakun` (worktree `.tasks/rakun/`).
> Spec (intent, immutable): [`tasks/v0.beta.5/specs/rakun.md`](tasks/v0.beta.5/specs/rakun.md)
>
> rakun = Spring-style application framework for botopink: IoC container +
> constructor DI + `#[restController]` web layer + `Rakun.run` bootstrap.
> Wiring is **comptime** (compilation-unit scan), not runtime reflection.
> Scaffold-first: declarations land before any compiler wiring.

## F0 — package scaffold & docs
- [x] `libs/rakun/botopink.json` (`files: []`)
- [x] `libs/rakun/AGENTS.md` + `libs/rakun/docs.md` (Spring mapping, loading notes)
- [x] `libs/rakun/src/rakun.d.bp` — header + declarative surface
- [x] Update `libs/AGENTS.md` tree + Packages table (lives in `feat`)

## F1 — HTTP primitives
- [x] `HttpMethod` enum (declared in `rakun.d.bp`)
- [x] `interface Request` — `method`/`path`/`param`/`query`/`header`/`body`
- [x] `interface Response` — `status`/`body`/`header` + `ok`/`json`/`created`/`withStatus`/`notFound`/`badRequest`
- [ ] Split into `src/http.d.bp` once the surface grows; list it in `botopink.json`

## F2 — IoC container
- [x] `interface Context` — `resolve<T>()`, `has<T>()` (declared)
- [ ] Bean model: singleton scope; constructor injection by field type (semantics)
- [ ] Comptime DI graph: discover components, topo-sort, detect cycles → diagnostic

## F3 — component annotations (comptime scan)
- [x] Decorator signatures exported from `rakun` (`component`/`service`/`repository`/
      `controller`/`restController`/`configuration`/`bean`/`inject`/`value`)
- [ ] Annotation resolution: `#[ … ]` entries resolve to **imported** rakun symbols,
      not only `builtins.d.bp` (today `#[…]` is implicitly builtin) — compiler work
- [ ] `#[configuration]` + `#[bean]` factory contribution
- [ ] `#[value("key")]` property injection
- [ ] Scope rule: a record field whose type is a known component ⇒ a dependency edge

## F4 — web layer / router
- [x] `route` + `getMapping`/`postMapping`/`putMapping`/`patchMapping`/`deleteMapping` signatures
- [ ] `Router` build: prefix + method path → handler; path params (`:name`)
- [ ] `Response` builders type-check against handler return type

## F5 — bootstrap
- [x] `interface App` (`port`/`basePath`) + `interface Rakun` with `run(app)` (declared)
- [ ] `Rakun.run` lowering: scan → wire container → build router → start server
- [ ] Needs `libs/server` HTTP backing (scaffold → real: separate task)
- [ ] Decide compiler wiring (imported lib, not prelude-embedded)

## F6 — examples & docs
- [x] `examples/rakun/main.bp` (bootstrap) + `examples/rakun/users.bp` (DI triad + routes)
- [x] `examples/rakun/config.bp` — `#[configuration]`/`#[bean]`/`#[value]` + bean injection
- [x] `examples/rakun/posts.bp` — write side: `#[postMapping]`/`#[deleteMapping]`, `req.body()`, status codes
- [x] `examples/AGENTS.md` tree marks `rakun/` illustrative (lives in `feat`)
- [ ] Keep `libs/rakun/docs.md` usage guide in sync as semantics land

## Notes / next

- F0, F1, plus the **declarations** of F2/F4/F5 and the decorator exports of F3
  are done in the scaffold. The remaining work is **compiler-side** (the comptime
  component scan, annotation→imported-symbol resolution, router/DI codegen) and
  the `libs/server` HTTP backing for F5 — both large, both tracked above.
- This branch carries only rakun-exclusive files. The shared v0.beta.5 set index
  (`README`/`plan`/`status`) and the `AGENTS.md` edits live in `feat`.
