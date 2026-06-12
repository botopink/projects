# rakun — Spring-style application framework for botopink

**Slug**: rakun
**Depends on**: nothing — but **F5 needs `libs/server` HTTP backing** (today a scaffold; embedding it is a separate task, tracked in `libs/server`)
**Files**: `libs/rakun/botopink.json`, `libs/rakun/AGENTS.md`, `libs/rakun/docs.md`, `libs/rakun/src/rakun.d.bp` (split into `http.d.bp` / `di.d.bp` / `web.d.bp` / `app.d.bp` as the surface grows), `examples/rakun/*`
**Touches docs**: `libs/AGENTS.md`, `libs/rakun/AGENTS.md`, `libs/rakun/docs.md`, `examples/AGENTS.md`, `tasks/v0.beta.5/{README,plan,status}.md`
**Status**: pending

## Intent

`rakun` is botopink's answer to Java's **Spring** / Spring Boot: a declarative
application framework built on three pillars —

1. **Inversion of Control (IoC) container** — managed *components* (singletons)
   whose dependencies are resolved automatically.
2. **Dependency injection by constructor** — a component declares each
   dependency as a record field; rakun supplies it *by type*. This is the
   idiomatic, immutable-friendly analogue of Spring's `@Autowired` constructor
   injection.
3. **Web layer** — `#[restController]` records map HTTP routes to handler
   methods, with `Request`/`Response` records and path/query/body access.

The wiring is **comptime**, not runtime reflection. Spring scans the classpath
at startup; rakun scans the *compilation unit* at compile time — it discovers
`#[component]`-family declarations, topologically resolves their constructor
dependencies, and emits the wiring + router table. This reuses the same
comptime machinery that powers `expr-templates` (no host reflection needed).

`rakun` is an **application-level** library: it is imported with
`from "rakun"`, **not** embedded into the stdlib prelude. It is a **scaffold**
until built — `botopink.json` claims no files and nothing is wired into the
compiler.

## Spring → rakun mapping

| Spring | rakun | Form |
|---|---|---|
| `@Component` | `#[component]` | annotation on a `record`/`struct` |
| `@Service` | `#[service]` | semantic alias of component (business logic) |
| `@Repository` | `#[repository]` | semantic alias (data access) |
| `@Controller` / `@RestController` | `#[controller]` / `#[restController]` | HTTP controller |
| `@Autowired` (constructor) | constructor injection | declare a dependency as a record field — resolved by type |
| `@Configuration` | `#[configuration]` | record whose `#[bean]` methods are factories |
| `@Bean` | `#[bean]` | factory fn whose return value becomes a managed singleton |
| `@Value("server.port")` | `#[value("server.port")]` | inject a config property |
| `@GetMapping("/x")` … | `#[getMapping("/x")]`, `#[postMapping]`, `#[putMapping]`, `#[patchMapping]`, `#[deleteMapping]` | route mapping on a handler method |
| `@RequestMapping("/api")` | `#[route("/api")]` | controller-level path prefix |
| `SpringApplication.run(App.class)` | `Rakun.run(App(port: 8080))` | bootstrap |
| `ApplicationContext` | `Context` | `ctx.resolve<T>()` resolves a managed bean |
| `ResponseEntity` | `Response` | `Response.ok(...)`, `Response.json(...)`, … |

**Decorators are rakun symbols.** Every marker above (`service`, `repository`,
`restController`, `route`, `getMapping`, …) is exported by `rakun` and **imported
at the call site** — `import {service, restController, route, getMapping} from "rakun";`
— then applied in a `#[ … ]` block. Annotations in botopink are call entries
type-checked against a signature (the same mechanism as the builtin `external`);
rakun supplies those signatures. The route decorators use Spring's own names
(`getMapping`, …) because `get`/`set`/`new` are reserved keyword tokens.

## Target syntax

```bp
import {Rakun, App, Request, Response} from "rakun";
import {repository, service, restController, route, getMapping} from "rakun";

#[repository]
pub record UserRepository {
    pub fn all(self: Self) -> Array<string> {
        return ["ana", "bob", "cleo"];
    }
}

#[service]
pub record UserService {
    repo: UserRepository,                 // injected by type (constructor injection)

    pub fn list(self: Self) -> Array<string> {
        return self.repo.all();
    }
}

#[restController, route("/api/users")]
pub record UserController {
    service: UserService,                 // injected by type

    #[getMapping("/")]
    pub fn index(self: Self, req: Request) -> Response {
        return Response.json(self.service.list().join(", "));
    }
}

fn main() {
    // component scan → resolve DI graph → build router → start server
    Rakun.run(App(port: 8080));
}
```

## Examples

### Constructor injection resolves a 3-level chain
```bp
#[repository] record R { pub fn n(self: Self) -> i32 { return 1; } }
#[service]    record S { r: R, pub fn n(self: Self) -> i32 { return self.r.n() + 1; } }
#[restController] record C { s: S, /* #[getMapping("/")] … self.s.n() == 2 */ }
```
At comptime, rakun discovers `R`, `S`, `C`; resolves `R()` first (no deps),
then `S(r: <R singleton>)`, then `C(s: <S singleton>)`. Each type is a single
shared instance (singleton scope).

### A route maps a method to a path + verb
```bp
#[restController, route("/api")]
record Greet {
    #[getMapping("/hello/:name")]
    pub fn hello(self: Self, req: Request) -> Response {
        return Response.ok("Hello, " + req.param("name").unwrapOr("world") + "!");
    }
}
```
Lowers to a router entry `{ method: Get, path: "/api/hello/:name", handler: Greet.hello }`.
`req.param("name")` reads the `:name` path segment.

### A `#[bean]` factory contributes a managed singleton
```bp
#[configuration]
record AppConfig {
    #[bean]
    pub fn clock(self: Self) -> Clock {
        return Clock(zone: "UTC");
    }
}
```
`Clock` becomes injectable by type wherever a component declares a `clock: Clock`
field — identical to Spring's `@Bean` methods on a `@Configuration` class.

## Steps

### F0 — package scaffold & docs
- [ ] `libs/rakun/botopink.json` (`files: []` — claims nothing yet, like `server`)
- [ ] `libs/rakun/AGENTS.md` + `libs/rakun/docs.md` (scaffold notes, Spring mapping)
- [ ] `libs/rakun/src/rakun.d.bp` — header + declarative surface
- [ ] Update `libs/AGENTS.md` tree + Packages table (new scaffold row)

### F1 — HTTP primitives
- [ ] `HttpMethod` enum (`Get`/`Post`/`Put`/`Patch`/`Delete`/`Head`/`Options`)
- [ ] `interface Request` — `method`, `path`, `param`, `query`, `header`, `body`
- [ ] `interface Response` — `status`, `body`, `header`, builders `ok`/`json`/`created`/`withStatus`/`notFound`/`badRequest`

### F2 — IoC container
- [ ] `interface Context` — `resolve<T>() -> ?T`, `has<T>() -> bool`
- [ ] Bean model: singleton scope; constructor injection by field type
- [ ] Comptime DI graph: discover components, topo-sort, detect cycles → diagnostic

### F3 — component annotations (comptime scan)
- [ ] Export the decorator symbols from `rakun` (`component`/`service`/`repository`/
      `controller`/`restController`/`configuration`/`bean`/`inject`/`value`) so the
      call site `import {service, …} from "rakun";` brings them into scope
- [ ] Annotation resolution: `#[ … ]` entries resolve to **imported** rakun
      symbols, not only `builtins.d.bp` (today `#[…]` is implicitly builtin)
- [ ] `#[configuration]` + `#[bean]` factory contribution
- [ ] `#[value("key")]` property injection
- [ ] Scope rule: a record field whose type is a known component ⇒ a dependency edge

### F4 — web layer / router
- [ ] `#[restController]` + `#[route(prefix)]` (exported from `rakun`)
- [ ] `#[getMapping|postMapping|putMapping|patchMapping|deleteMapping(path)]` method mappings
- [ ] `Router` build: prefix + method path → handler; path params (`:name`)
- [ ] `Response` builders type-check against handler return type

### F5 — bootstrap
- [ ] `interface App` (config: `port`, `basePath`, properties)
- [ ] `interface Rakun` with associated `run(app: App)`
- [ ] `Rakun.run` lowering: scan → wire container → build router → start server (`libs/server`)
- [ ] Decide compiler wiring (this lib is imported, not prelude-embedded)

### F6 — examples & docs
- [ ] `examples/rakun/main.bp` (bootstrap) + `examples/rakun/users.bp` (DI triad + routes)
- [ ] Update `examples/AGENTS.md` tree (mark `rakun/` illustrative)
- [ ] `libs/rakun/docs.md` usage guide; keep `AGENTS.md` in sync

## Test scenarios

```
comptime ---- component scan discovers every #[service]/#[repository]/#[controller] decl
comptime ---- container resolves a 3-level DI chain (repo → service → controller)
comptime ---- dependency cycle (A needs B, B needs A) raises a scoped diagnostic
comptime ---- #[bean] factory output is injectable by its return type
infer    ---- imported decorator (`import {service} from "rakun"`) resolves at the #[ ] site
infer    ---- #[getMapping("/x")] handler signature (Request) -> Response type-checks
infer    ---- unresolved dependency (field type is not a component) is a clear error
codegen  ---- router table emitted for node + beam targets
run      ---- GET /api/users/  returns 200 with the joined user list
run      ---- GET /api/hello/ana returns 200 "Hello, ana!"
```

## Notes

- **Scaffold today.** Like `libs/server`/`libs/client`, `botopink.json` claims
  no files and nothing is embedded. Embedding/wiring is part of F5, a deliberate
  step — not a side effect.
- **Comptime, not reflection.** Component discovery + DI wiring happen at compile
  time over the compilation unit (reuses the `expr-templates`/`@Expr` machinery).
  No runtime classpath scanning, no host reflection.
- **Constructor injection only** (immutable-first). No field/setter injection —
  a dependency is a `record` field, resolved by type. This sidesteps mutability
  and keeps components pure.
- **Singleton scope only** in v1. Prototype/request scopes are out of scope until
  the web layer proves out.
- **Needs `libs/server`.** F5 starts an HTTP server; that backing is currently a
  scaffold. The web layer (F4) and DI (F1–F3) can be designed/declared first;
  only `Rakun.run`'s "start server" leg blocks on `server` becoming real.
- **Imported, not prelude.** `from "rakun"` — never auto-loaded into the type
  `Env`. App authors opt in per project via `botopink.json` deps. The
  **decorators are imported too** (`import {service, getMapping, …} from "rakun";`),
  which means F3 must extend annotation resolution to imported symbols — today
  every `#[…]` entry is treated as builtin (`is_builtin = true`) and checked only
  against `builtins.d.bp`.
- **Naming.** camelCase methods; `new`/`get`/`set` are reserved keyword tokens —
  hence `Context.resolve<T>()` (not `get<T>()`) and the Spring-style
  `getMapping`/`postMapping`/… route decorators (not bare `get`/`post`).
