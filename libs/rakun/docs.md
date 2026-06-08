# rakun — Spring-style application framework (scaffold)

> Path: `libs/rakun/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Spec: [`../../tasks/v0.beta.5/specs/rakun.md`](../../tasks/v0.beta.5/specs/rakun.md)

`rakun` is botopink's answer to Java's **Spring** / Spring Boot: a dependency-
injection container paired with a declarative web layer. Today it is an inert
**scaffold** — `botopink.json` claims no files, nothing is embedded into the
compiler, and the type environment does not load it. The full design lives in
the v0.beta.5 spec.

## What it will provide (planned)

- **IoC container** — managed singleton components, resolved by type.
- **Constructor dependency injection** — declare a dependency as a `record`
  field; rakun supplies it. No setter/field injection.
- **Web layer** — `@[restController]` records mapping HTTP routes to handler
  methods, with `Request`/`Response` records.
- **Bootstrap** — `Rakun.run(App(...))` to scan components, wire the graph,
  build the router, and start the HTTP server.

## Spring → rakun mapping

| Spring | rakun |
|---|---|
| `@Component` / `@Service` / `@Repository` | `@[component]` / `@[service]` / `@[repository]` |
| `@RestController` + `@RequestMapping("/api")` | `@[restController, route("/api")]` |
| `@GetMapping("/x")` … | `@[getMapping("/x")]`, `@[postMapping]`, `@[putMapping]`, `@[patchMapping]`, `@[deleteMapping]` |
| `@Autowired` (constructor) | a `record` field — injected by type |
| `@Configuration` + `@Bean` | `@[configuration]` + `@[bean]` |
| `@Value("server.port")` | `@[value("server.port")]` |
| `SpringApplication.run(App.class)` | `Rakun.run(App(port: 8080))` |
| `ApplicationContext` | `Context` (`ctx.resolve<T>()`) |
| `ResponseEntity` | `Response` (`Response.ok(...)`, `Response.json(...)`) |

The decorators (`service`, `restController`, `route`, `getMapping`, …) are
symbols **exported by rakun** — import them at the call site before applying
them in a `@[ … ]` block. Route decorators use Spring's names (`getMapping`, …)
because `get`/`set`/`new` are reserved keyword tokens.

## Usage (intended)

```bp
import {Rakun, App, Request, Response} from "rakun";
import {service, restController, route, getMapping} from "rakun";

@[service]
pub record GreetingService {
    pub fn greet(self: Self, name: string) -> string {
        return "Hello, " + name + "!";
    }
}

@[restController, route("/api")]
pub record GreetingController {
    greeting: GreetingService,           // injected by type

    @[getMapping("/hello/:name")]
    pub fn hello(self: Self, req: Request) -> Response {
        return Response.ok(self.greeting.greet(req.param("name").unwrapOr("world")));
    }
}

fn main() {
    Rakun.run(App(port: 8080));
}
```

See runnable showcase files under [`../../examples/rakun/`](../../examples/AGENTS.md).

## Loading notes

Unlike `libs/std`, this package is **not** `@embedFile`'d into a `prelude.zig`
and is **not** wired into `build.zig`. It is an **application-level** lib reached
via `from "rakun"`, opted into per project. Wiring it into the toolchain (so
`Rakun.run` can start a server) is spec phase **F5**, and depends on `libs/server`
graduating from scaffold to real HTTP backing.

## See also

- The embedded standard library → [`../std/docs.md`](../std/docs.md).
- The HTTP server backing F5 needs → [`../server/docs.md`](../server/docs.md).
- The `.bp` libraries group contract → [`../AGENTS.md`](../AGENTS.md).
