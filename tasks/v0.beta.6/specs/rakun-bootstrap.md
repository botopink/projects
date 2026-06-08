# rakun-bootstrap — `Rakun.run` + real HTTP backing (rakun F5)

**Slug**: rakun-bootstrap
**Depends on**: `rakun-ioc-web` (needs the DI graph + router table to wire)
**Files**: `libs/rakun/src/*.bp`, `libs/server/src/*` (HTTP backing — scaffold → real), `modules/compiler-core/*` (`Rakun.run` lowering)
**Touches docs**: `libs/rakun/AGENTS.md`, `libs/rakun/docs.md`, `libs/server/AGENTS.md`
**Status**: pending

## Intent

Close the loop: `Rakun.run(App(port: 8080))` should **boot a real server** —
scan the compilation unit for components, wire the DI graph, build the router
table, and start an HTTP listener that dispatches requests to the resolved
controller handlers. This is rakun F5, and it is the one leg that needs a real
HTTP backing (`libs/server`), today a scaffold.

## Target syntax

```bp
import {Rakun, App} from "rakun";
import {UserController};

fn main() {
    Rakun.run(App(port: 8080, basePath: "/"));
}
```

## Steps

### F0 — `libs/server` HTTP backing
- [ ] Promote `libs/server` from scaffold to a real, minimal HTTP server
      surface (listen, route dispatch, request/response bridging) behind
      `#[@external]` host calls per backend (node `http`, erlang `cowboy`/
      `inets` or a minimal `gen_tcp` loop).
- [ ] `Request` (the rakun runtime-boundary interface) gets a concrete
      server-supplied implementation: `param`/`query`/`header`/`body`.

### F1 — `Rakun.run` lowering
- [ ] Lower `Rakun.run(app)` to: comptime scan → instantiate the DI singletons →
      register the router table → start `libs/server` on `app.port`/`basePath`.
- [ ] Decide compiler wiring: rakun is imported, not prelude-embedded — the
      lowering is driven by the imported lib, not hard-coded in the prelude.

### F2 — end-to-end
- [ ] A request to a mapped route invokes the handler with a live `Request` and
      returns its `Response` (status + body) over the wire.

## Test scenarios

```
run ---- GET /api/users/  returns 200 with the joined user list
run ---- GET /api/hello/ana returns 200 "Hello, ana!"
run ---- an unmapped path returns 404
```

## Notes

- Blocks on `rakun-ioc-web` (the scan/graph/router it boots).
- `libs/server` realness is the gating sub-task; keep it minimal (one backend
  first — node — then erlang).
- Singleton scope only; no graceful-shutdown / middleware in v1.
