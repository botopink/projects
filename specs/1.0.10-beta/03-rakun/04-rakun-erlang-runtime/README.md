# Front 04 — rakun Erlang Runtime

**Track:** B rakun
**Priority:** critical — until this lands, every other track B front is a Node program wearing a botopink hat; nothing on the server side can be tested on its assigned target
**Target:** erlang (server)
**Wave:** 1
**Depends on:** 01
**Owns:** `src/sidecars/rakun_runtime.erl`, `src/runtime.bp` (the `#[@external(erlang)]` block, and the removal of every `#[@External.Node]` form in Step 10), the deletion of `src/runtime.mjs` (Step 10), `src/root.bp`, `botopink.json` (the core's `target` / `targets`) · `test/erlang_runtime_test.bp`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` — frozen for the milestone
**Reference:** `02-desenvolvendo-com-spring-boot.md § Beans e Injecao de Dependencias` · `03-recursos-principais.md § SpringApplication` · `04-web.md § Container Servlet Embutido` · <https://docs.spring.io/spring-boot/reference/using/spring-beans-and-dependency-injection.html> · <https://docs.spring.io/spring-boot/reference/features/spring-application.html> · <https://docs.spring.io/spring-boot/reference/web/servlet.html>

---

## Problem

rakun's whole runtime is a Node module. `src/runtime.bp` declares seventeen host cells and every one of
them carries exactly one form, `#[@External.Node("./runtime.mjs", …)]` (`src/runtime.bp:19-117`).
The state behind them — the component scan list, the singleton cache, the cycle guard, the property
map, the route table, the socket — is 231 lines of JavaScript in `src/runtime.mjs`, and
`runtime.mjs:11-12` says so in as many words: "State is module-global (one node process per run). The
Erlang/BEAM equivalent is a recorded follow-up." This is that follow-up.

The consequence is not "rakun is slower on BEAM". It is that a `botopink test --target erlang` run of
rakun dies at the first `rkScan/1` call with `undefined function`, so of rakun's five test files only
`http.bp`'s in-file test — which touches no host cell (`src/http.bp:80-86`) — can pass. rakun's own
manifest admits the situation: `botopink.json` declares `"targets": ["commonJS"]`, where decision 113
puts `["erlang"]`. Every front in
track B that claims to run on the server is, today, unfalsifiable: its tests cannot execute on the
target the milestone assigns it.

Two things follow. First, nothing here is a rewrite — the semantics are already specified, in
JavaScript, and this front's job is to reproduce them in Erlang term-for-term so that a test written
once passes on both rows. Second, "reproduce them" is not literal: Node has one process and a module
global; the BEAM has a scheduler, a supervision tree and per-process state, and the honest port uses
them rather than emulating a single-threaded runtime on top of them.

## Current state

| Piece | Where it lives today | Erlang counterpart today |
|---|---|---|
| Component scan (`rkScan`/`rkScannedNames`/`rkScannedCount`) | `runtime.mjs:20-31`, a module-level array | none |
| Cycle guard (`rkEnter`/`rkDone`/`rkBuildCount`) | `runtime.mjs:40-62`, a `Set` + a `Map` | none |
| Singleton cache (`rkSingleton`) | `runtime.mjs:71-78`, a `Map` | none |
| Properties (`rkSetProp`/`rkProp`/`rkPropInt`) | `runtime.mjs:84-97`, a `Map` | none |
| Router (`rkRegisterRoute`/`rkRouteCount`/`rkRoutePaths`/`rkDispatch`/`rkDispatchHttp`) | `runtime.mjs:107-196`, an array + `:name` segment matching | none |
| HTTP server (`rkServe`) | `runtime.mjs:206-231`, `node:http` `createServer` | none |
| Request value handed to a handler | `runtime.mjs:146-161`, a plain object with four closures | none |
| `.erl` sidecar shipping | `modules/compiler-cli/src/cli/libs.zig:564-635` — **already implemented** | works |
| `.erl` sibling loading in a test run | `modules/compiler-core/src/codegen/erlang.zig:1649-1678` — **already implemented** | works for `test`, not for `build`/`run` |
| BEAM primitives in std | `libs/std/src/beam.bp:72-103` — process dictionary, ETS, persistent_term, all `any`-typed | exists, insufficient |

`libs/std/src/beam.bp` is worth naming precisely because it is close and still not enough: it gives
`etsNew`/`etsGet`/`etsPut`/`pdGet`/`pdPut` as `any → any` declarations. It has no supervision, no
socket, no way to own a table across a crash, and no typed surface. rakun needs a host module, not a
pile of `any`.

## Mechanism

### One statement about reactive, once, for the whole track

Spring offers a second stack for every blocking one — WebFlux beside MVC, R2DBC beside JDBC, virtual
threads under both. **None of those is a gap in this port, and none of them is a front.** BEAM
processes already are the concurrency model: a request is a process, blocking a process blocks
nothing else, and there is no thread pool to starve. Where the Spring documentation offers a reactive
variant, the botopink answer is a `@Task`-returning form of the same call, folded into the front
that owns the blocking one (front 08 for queries, front 13 for HTTP clients). `spring.threads.virtual.enabled`,
`WebApplicationType.REACTIVE` and the whole `Mono`/`Flux` return surface have no counterpart here
because the problem they solve does not occur. This paragraph is the milestone's position; no other
track B front restates it.

### What the OTP pieces are, and why each one

| rakun concern | OTP piece | Why |
|---|---|---|
| The runtime as a startable unit | `application` (`rakun`) | `application:start/1` is the only thing that gives the ETS tables an owner that outlives a request, and it is what a release manifest names |
| Keeping the tables and the listener alive | `supervisor` (`rakun_sup`, `one_for_one`) | A crashed acceptor must not take the singleton cache with it |
| Owning the four ETS tables; serialising first construction | `gen_server` (`rakun_registry`) | ETS tables die with their owning process. A `gen_server` is the owner that never exits, and its mailbox is the natural serialisation point for "build this singleton once" |
| Scan list, singleton cache, property map, route table | ETS (`named_table, public`) | The Node `Map`/array equivalents. `public` + `read_concurrency` so a request process reads without a message round trip |
| Cycle guard, per-request reply headers | process dictionary | Per-process on the BEAM *is* per-request, which is exactly the scope Node gets by accident from being single-threaded |
| Accepting sockets | `gen_tcp` with `{packet, http_bin}` | OTP decodes the request line and headers itself, so rakun writes no HTTP parser |
| One process per connection | `supervisor` (`rakun_conn_sup`, `simple_one_for_one`) | A handler that throws kills its own connection process and nothing else — the BEAM answer to `runtime.mjs:222-224`'s try/catch |
| Boot-time keep-alive for a listener-less app | `receive after infinity` under the supervisor | `spring.main.keep-alive`'s analogue: a scheduler-only app must not halt when `main/1` returns |
| Optional production front end | `cowboy` | Named, not required — see *Why `gen_tcp` and not cowboy* below |
| TLS termination | OTP `ssl` via front 74's bundle registry | Front 04 exposes the listener option; front 74 owns the material |

### How a host cell reaches Erlang

The compiler already has both halves of the path and neither needs a change.

1. `shipErlSidecars` (`modules/compiler-cli/src/cli/libs.zig:564-635`) walks every `atom:fun(`
   qualifier in the emitted Erlang, and for an atom that is not a module this build emitted, it looks
   for `<lib-root>/rakun/src/sidecars/<atom>.erl`, then `<lib-root>/rakun/src/<atom>.erl`, and copies
   it flat into the output directory.
2. The test entry point's `__bp_load_siblings/0` (`modules/compiler-core/src/codegen/erlang.zig:1655-1668`)
   compiles and loads every `**/*.erl` beside the script before the tests run.

So the deliverable is one `.erl` file in `src/sidecars/` plus one `#[@External.Erlang("<atom>", "<fn>")]`
form on each existing cell. Nothing else.

**The module atom cannot be `runtime`.** `shipErlSidecars` skips any qualifier whose atom matches a
module this build emitted (`libs.zig:596`: `if (emitted.contains(atom)) continue;`), and rakun emits
`rakun/runtime` — basename `runtime`. Naming the host module `runtime` therefore ships nothing, and
the failure is silent: the build succeeds and the program dies at run time with
`undefined function runtime:scan/1`. The host module is **`rakun_runtime`**, and the file is
`src/sidecars/rakun_runtime.erl`. See *Contradictions with fronts.md* below.

### `src/root.bp` and `botopink.json`, and the append rule

Front 04 owns both, as the lowest-numbered front in `repository/rakun/`. Every later core front adds
its lines rather than editing the file's shape: front 05 appends `pub mod config;` and
`pub mod profiles;`, front 06 appends `pub mod context;`, `pub mod events;` and `pub mod lifecycle;`
and its declaration surface to the manifest's `files` list, fronts 22–25 append one `pub mod` each.
The rule is **append-only, in front-number order, never reorder an existing line** — the same rule
track A uses for `libs/std/src/root.bp`, and the reason sixteen fronts can share a file without a
merge conflict.

The same rule applies one level down: each `modules/<name>/` directory's `botopink.json` and
`src/root.bp` belong to the lowest-numbered front in that module — F07 for `rakun-web`, F08 for
`rakun-data`, F10 for `rakun-security`, F11 for both actuator modules — and every other front in that
module appends.

### The seventeen cells, paired

Each existing declaration gains a second annotation. Nothing about the Node form changes; the cells
are pre-existing surface and the milestone is additive.

```bp
#[@External.Node("./runtime.mjs", "scan"),
  @External.Erlang("rakun_runtime", "scan")]
pub declare fn rkScan(name: string) -> i32;
```

Name mapping is `camelCase → snake_case`, which is the only place the two hosts differ in spelling:
`scannedNames → scanned_names`, `buildCount → build_count`, `setProp → set_prop`, `propInt → prop_int`,
`registerRoute → register_route`, `routeCount → route_count`, `routePaths → route_paths`,
`dispatchHttp → dispatch_http`.

### What the record shapes must be

`rkDispatch` and `rkDispatchHttp` return a `Response`, and `rkRegisterRoute` receives a `fun` that
returns one. The host module does not get to pick that shape: it is whatever the Erlang backend lowers
`Response(status: 200, body: "hi")` to. This front pins it with a round-trip test rather than a
comment — `test/erlang_runtime_test.bp` registers a route whose handler returns `Response.ok("hi")`,
dispatches it through `rkDispatch`, and asserts `.status` and `.body` on the way back out. If the
shape ever moves, that test breaks in the right place.

The same applies to the `Request` value the host builds for a handler. `runtime.mjs:146-161` builds an
object with a `method` and `path` field and four closures; the Erlang side builds the same record with
four `fun`s, and `param`/`query`/`header` return `""` — never `undefined` — because
`src/http.bp:30-34` fixes the contract at plain `string`.

### Response headers, and why they are a new cell

`Response` is `(status: i32, body: string)` and `http.bp` is frozen, so there is no field to put a
header in and no `withHeader` to add one. Fronts 07 (CORS, compression), 10 (`WWW-Authenticate`), 11
(content types) and 13 all need one anyway. The BEAM answer costs nothing: a request is a process, so
the reply headers for the in-flight request are process-local state.

```bp
#[@External.Erlang("rakun_runtime", "set_reply_header")]
pub declare fn rkSetReplyHeader(name: string, value: string) -> i32;

#[@External.Erlang("rakun_runtime", "reply_headers_json")]
pub declare fn rkReplyHeaders() -> string;
```

These two are Erlang-only and carry no Node form: they are new server surface in a server front, which
is what the milestone's target rule asks for. `rakun_runtime:set_reply_header/2` writes into the
connection process's dictionary; the acceptor reads the accumulated list back after the handler
returns and writes it to the wire ahead of the body. A request that sets no header pays nothing.

### Boot options, and why they are not fields on `App`

Spring's `SpringApplication` carries banner mode, web-application type and keep-alive as builder
options (`03-recursos-principais.md § SpringApplication`). rakun's equivalent is `App(port, basePath)`
in `src/http.bp:75-78` — **frozen for the milestone**, so it cannot grow a field. Front 04 delivers the
same options through two channels instead:

- **Configuration keys**, read through `rkProp` and therefore automatically fed by front 05 once it
  lands: `rakun.main.banner-mode` (`console` | `off`), `rakun.main.headless` (start no listener),
  `rakun.main.keep-alive`, `rakun.main.pid-file`, `rakun.main.port-file`, `rakun.server.backlog`,
  `rakun.server.idle-timeout`, `rakun.server.max-connections`, `rakun.server.transport`.
- **One explicit cell** for the program that wants to set them in code rather than in a file:
  `rkBoot(optionsJson: string) -> i32`, called before `Rakun.run`. It writes the same properties, so
  there is exactly one resolution path and configuration still wins or loses by the ordering front 05
  defines.

This is a deliberate narrowing of the fold-in as written: "options on `App(...)`" is not available
this milestone, and inventing a second `App` record would leave two bootstrap types in the public
surface. The keys are the API; `rkBoot` is the escape from having to write a file in a test.

### Banner

`rakun.main.banner-mode=console` (the default) prints `banner.txt` from the working directory at boot
if it exists, substituting `${application.version}` from `botopink.json`, `${rakun.version}` from
rakun's own manifest, and `${otp.version}` from `erlang:system_info(otp_release)`. With no `banner.txt`
a one-line default is printed. `off` prints nothing — and prints nothing in a test run regardless, so
the banner never pollutes assertion output.

### Startup failure diagnostics

Spring's `FailureAnalyzer` turns a stack trace into a description and an action
(`03-recursos-principais.md § Falha no Startup`). rakun's version is a table in `rakun_runtime`, keyed
by the error term, consulted before the node halts:

| Error term | Description | Action |
|---|---|---|
| `{listen, eaddrinuse}` | The configured port is already bound | Name the port and the `rakun.server.port` key; suggest identifying the holder |
| `{listen, eacces}` | Binding a privileged port without the capability | Suggest a port above 1024 or `CAP_NET_BIND_SERVICE` |
| `{rakun_cycle, Name}` | A component depends transitively on itself | Print the construction stack from the process dictionary |
| `{missing_property, Key}` | A `#[value("key")]` field has no value and no default | Name the key and the files searched (front 05 supplies the list) |
| `{transport, Name}` | An unknown or unloadable transport | Name the value and the module it looked for |

An unmatched error prints the raw term and says so, rather than pretending to diagnose it. The table
is data, extended by later fronts (08 adds the bad-DB-URL row) through `rakun_runtime:add_failure/3`.

### Why `gen_tcp` and not cowboy

cowboy does not survive contact with how the sidecar is loaded: `__bp_load_siblings/0` calls `compile:file/2` on the source at
run time, with no rebar, no `.app` file and no code path beyond the output directory. A sidecar that
calls `cowboy:start_clear/3` compiles fine and then dies with `undefined function cowboy:start_clear/3`
on every machine that has not separately installed cowboy — and rakun's test row would depend on an
OTP application the gate does not install.

`gen_tcp` is in `kernel`. It is always there. With `{packet, http_bin}` the VM parses the request line
and headers, so the transport is roughly sixty lines and has no dependency at all. Cowboy stays in the
design as an **adapter**: `rakun_runtime:serve/2` reads `rakun.server.transport` and dispatches to
`rakun_cowboy:serve/2` when it is set to `cowboy` and the module is loadable, failing loudly rather
than falling back when it is set and missing.

### The one seam other fronts hang off

`Rakun.run` is frozen and hardcodes `rkDispatchHttp` as the dispatcher (`src/bootstrap.bp:33-35`), so
no later front can wrap the request path from outside. `dispatch_http/5` therefore carries one hook,
and exactly one:

```erlang
dispatch_http(Verb, Path, HeadersJson, QueryJson, Body) ->
    case erlang:function_exported(rakun_chain, run, 6) of
        true  -> rakun_chain:run(Verb, Path, HeadersJson, QueryJson, Body, fun handle/6);
        false -> handle(Verb, Path, HeadersJson, QueryJson, Body, undefined)
    end.
```

`rakun_chain` is front 07's module. When rakun-web is not in the build the branch is never taken and
the cost is one `function_exported/3` per request. Front 07's filter chain, CORS, compression, error
handling, API versioning and the `middleware.bp` convention all enter here; front 10's security filter
and front 11's request metrics enter through front 07's chain, not through a second hook. One seam,
named in one place.

### Where this front stops

`rkServe` blocks. On Node the listening socket keeps the event loop alive; on the BEAM the escript's
`main/1` returning halts the node, so `serve/2` starts the listener under `rakun_sup` and then waits
(`receive after infinity -> ok end`). Unlike a bare `timer:sleep(infinity)` in `main/1`, the socket is already supervised by the time
the wait begins, so a crash in the acceptor is restarted rather than losing the port. In headless mode there is no listener and the same wait is what
`rakun.main.keep-alive` controls.

## Steps

### Step 1 — `rakun_registry`: the table owner

A `gen_server` that creates and owns the four ETS tables, started by `rakun_sup` before anything else.
Every other function in the module reads and writes the tables directly; only "construct this
singleton for the first time" goes through the mailbox.

```erlang
-module(rakun_runtime).
-behaviour(application).

-define(SCAN,    rakun_scan).       %% ordered_set: {Seq, Name}
-define(SINGLE,  rakun_singletons). %% set:         {Name, Value}
-define(BUILDS,  rakun_builds).     %% set:         {Name, Count}
-define(PROPS,   rakun_props).      %% set:         {Key, Value}
-define(ROUTES,  rakun_routes).     %% ordered_set: {Seq, Verb, Segs, Handler}
```

**Acceptance:**
- [ ] `rakun_runtime.erl` compiles under `erlc` with `-Werror` and no warnings
- [ ] The four tables are `named_table, public, {read_concurrency, true}` and are created exactly once, by `rakun_registry`'s `init/1`
- [ ] Killing `rakun_registry` and letting the supervisor restart it recreates empty tables rather than leaving dangling ones
- [ ] `application:start(rakun)` is idempotent — a second call returns `{error, {already_started, rakun}}` and changes nothing

### Step 2 — Scan, singleton scope and the cycle guard

`scan/1` appends to `?SCAN` under a monotonically increasing sequence so `scanned_names/0` preserves
declaration order the way `runtime.mjs:26-28` does. `singleton/2` reads `?SINGLE`, and on a miss calls
the `fun`, then `ets:insert_new/2` — if two request processes race, the first insert wins and the
loser's value is discarded, which keeps "one instance per type" true without a lock. `build_count/1`
counts constructor runs, not resolves.

`enter/1` and `done/1` use the process dictionary: the guard is per-construction, and on the BEAM a
construction happens inside whichever process asked for it.

```erlang
enter(Name) ->
    Stack = case get(rakun_building) of undefined -> []; S -> S end,
    case lists:member(Name, Stack) of
        true  -> erlang:error({rakun_cycle, Name});
        false -> put(rakun_building, [Name | Stack]), bump(Name), 0
    end.
```

**Acceptance:**
- [ ] `rkScannedNames()` returns the component names comma-joined in declaration order, byte-identical to the commonJS row
- [ ] Resolving a type from three sites runs its constructor once: `rkBuildCount("UserService") == 1`
- [ ] A diamond (`A → B`, `A → C`, `B → D`, `C → D`) builds `D` once
- [ ] A cycle `A → B → A` raises `{rakun_cycle, "A"}` at first construction, not a stack overflow
- [ ] Two processes resolving the same uncached singleton concurrently observe the same value, and `build_count` is 1 or 2 but never grows with the number of readers

### Step 3 — Properties

`set_prop/2`, `prop/1`, `prop_int/1` over `?PROPS`. `prop/1` answers `""` for an absent key;
`prop_int/1` answers `0` for an absent or unparsable value — both matching `runtime.mjs:90-97`
exactly, because `#[value("key")]` fields depend on it. Front 05 seeds this table; front 04 only owns
the storage and the defaults.

**Acceptance:**
- [ ] `rkProp("absent") == ""` and `rkPropInt("absent") == 0`
- [ ] `rkPropInt` of `"8080"` is `8080`; of `"not a number"` is `0`; of `"12abc"` is `0`
- [ ] A `#[value("app.timezone")] timezone: string` field resolves through `prop/1` on the erlang row with the same value the commonJS row gives

### Step 4 — Router

`register_route/3` appends `{Seq, Verb, Segs, Handler}`; `match/2` walks in registration order and
takes the first route whose verb matches, whose segment count matches, and whose every segment either
equals the request's or starts with `:` (a path parameter, bound into a map). `dispatch/2` builds a
request with the bound params and everything else empty; `dispatch_http/5` decodes the header and
query JSON, lowercases header names, and builds a live request.

This is a direct port of `runtime.mjs:113-196`, and "direct" is the acceptance criterion: the router
tests that exist today (`test/router_test.bp`, `test/overlapping_routes_test.bp`) must pass unchanged.

**Acceptance:**
- [ ] `test/router_test.bp` and `test/overlapping_routes_test.bp` pass on `--target erlang` with no source change
- [ ] `rkRoutePaths()` is byte-identical across the two rows for the same registration order
- [ ] `/api/users/:name` binds `name` and `req.param("name")` returns it
- [ ] An unmatched path returns a `Response` with `status == 404` and `body == ""`
- [ ] Registration order decides between two routes that both match, on both rows
- [ ] With no `rakun_chain` module loaded, `dispatch_http/5` calls the handler directly and the branch costs one `function_exported/3`
- [ ] With a stub `rakun_chain:run/6` loaded, every request passes through it and the handler still answers correctly

### Step 5 — Reply headers

`set_reply_header/2` writes into the connection process's dictionary; `reply_headers_json/0` reads the
accumulated list back as a JSON object string. A later write to the same name replaces the earlier
one; the acceptor clears the dictionary entry when the connection process finishes a request so a
keep-alive connection does not leak headers from the previous one.

**Acceptance:**
- [ ] A handler calling `rkSetReplyHeader("X-Trace", "abc")` produces `X-Trace: abc` on the wire
- [ ] Two writes to the same name produce one header, the second value
- [ ] On a keep-alive connection, headers set during request *n* do not appear on the response to *n+1*
- [ ] A handler that sets no header produces the same bytes it produces today

### Step 6 — The `gen_tcp` acceptor, and its tuning keys

`serve/2` starts `rakun_sup`'s listener child: `gen_tcp:listen(Port, [binary, {packet, http_bin},
{active, false}, {reuseaddr, true}, {backlog, B}])`, an acceptor loop that `gen_tcp:accept/1`s and
hands each socket to a child of `rakun_conn_sup`. The connection process reads the request line and
headers with `{packet, http_bin}`, switches to `{packet, raw}` for the body when `Content-Length` says
there is one, calls the dispatcher `fun` with the five scalars, and writes status, accumulated headers
and body back. A handler that throws answers `500` with the reason as the body and the process exits.

Tuning is configuration, not code: `rakun.server.backlog` (default 128),
`rakun.server.idle-timeout` in milliseconds (default 60000; an idle keep-alive connection is closed),
`rakun.server.max-connections` (default 16384; over the limit the acceptor answers 503 and closes
without spawning). Front 74 supplies the TLS options when a bundle is named.

**Acceptance:**
- [ ] `Rakun.run(App(port: 0, basePath: "/"))` binds an ephemeral port and `serve/2` returns it
- [ ] `GET` on a registered route answers 200 with the handler's body
- [ ] `GET` on an unregistered path answers 404
- [ ] `POST` with a body reaches `req.body()` intact, including a body containing `\r\n\r\n`
- [ ] A query string reaches `req.query(name)`; a repeated key takes the first occurrence, as `runtime.mjs:212` does
- [ ] Header lookup is case-insensitive
- [ ] A handler that raises answers 500 and the next request on a new connection still answers 200
- [ ] Killing a connection process mid-request does not affect any other in-flight request
- [ ] With `rakun.server.max-connections=1`, the second concurrent connection is answered 503 and closed
- [ ] With `rakun.server.idle-timeout=200`, an idle keep-alive connection is closed within 500 ms

### Step 7 — Boot options: banner, headless, keep-alive, PID and port files

`boot/1` runs before the listener: it prints the banner, writes `os:getpid()` to `rakun.main.pid-file`
and — after the listener binds — the actual port to `rakun.main.port-file`, and decides whether to
start a listener at all. Headless plus keep-alive is the scheduler-only app: no socket, node stays up.
Headless without keep-alive boots, runs whatever `main` does, and exits, which is the CI smoke shape
front 19 builds on.

**Acceptance:**
- [ ] With a `banner.txt` present, `${application.version}`, `${rakun.version}` and `${otp.version}` are substituted; the file is printed once, before the first log line
- [ ] `rakun.main.banner-mode=off` prints nothing; a test run prints nothing regardless of the setting
- [ ] `rakun.main.pid-file=/tmp/x.pid` contains the OS PID, and the file is removed on a clean shutdown
- [ ] `rakun.main.port-file` contains the **bound** port, so `port: 0` writes the ephemeral one
- [ ] `rakun.main.headless=true` starts no listener, and `rkRouteCount()` is still correct
- [ ] `rakun.main.headless=true` with `keep-alive=true` does not halt; with `keep-alive=false` it halts with status 0

### Step 8 — Startup failure diagnostics

The table above, consulted by a boot-time `try`/`catch` around `boot/1` and `serve/2`. Output is three
blocks — the error, a description, an action — and the node halts with a non-zero status.

**Acceptance:**
- [ ] Binding an already-bound port prints the port, the `rakun.server.port` key and an action, then halts non-zero
- [ ] A dependency cycle prints the construction stack, innermost last
- [ ] An unknown `rakun.server.transport` prints the value it was given
- [ ] An unmatched error prints the raw term and states that no diagnosis is available — it does not guess
- [ ] `rakun_runtime:add_failure/3` lets a later front add a row without editing this front's table

### Step 9 — Transport seam for cowboy

`serve/2` reads `prop("rakun.server.transport")`. When it is `"cowboy"` and
`code:ensure_loaded(rakun_cowboy)` succeeds, delegate; otherwise use the `gen_tcp` acceptor. The
default is the acceptor, and an unknown transport name is an error at startup rather than a silent
fallback.

**Acceptance:**
- [ ] With no property set, the `gen_tcp` acceptor runs
- [ ] With `rakun.server.transport=cowboy` and no `rakun_cowboy` module present, startup fails with a message naming the missing module — it does not silently fall back
- [ ] With `rakun.server.transport=nonsense`, startup fails naming the value

### Step 10 — erlang is rakun's target, and the node runtime leaves

rakun is the service and the service runs on BEAM (decision 113): one runtime, not two with the same
semantics to keep. The core member becomes erlang-only, and `runtime.mjs` with the node server leaves
the tree once the erlang row carries everything it carried. `scripts/known-red-libs.txt` loses
rakun's erlang cell.

**Acceptance:**
- [ ] `modules/rakun/botopink.json` (the core) reads `"target": "erlang"` and `"targets": ["erlang"]`
- [ ] the workspace root `repository/rakun/botopink.json` and every member read `"targets":
      ["erlang"]` — what both sides run is a bundled library, not a rakun member: the matcher and the
      navigation vocabulary are `routing`, the action protocol `actions`, validation `validation`
      (decisions 115, 116); erlang is the default target of `botopink run` / `botopink test` there
- [ ] `src/runtime.mjs` is deleted, and no `#[@External.Node]` form remains in the core
      (`rtk proxy grep -rn 'External.Node' repository/rakun/src` is empty)
- [ ] the five pre-existing test files pass on `--target erlang` with no source change
- [ ] `botopink test --target erlang` is green from a cold cache in `repository/rakun/`
- [ ] `zig build test-libs -- --target erlang --lib rakun` is green
- [ ] rakun's erlang cell is not listed in `scripts/known-red-libs.txt` (a listed cell that passes fails the run)

## Examples

- [`examples/minimal-app-example.bp`](./examples/minimal-app-example.bp) — the smallest rakun
  application that boots on the BEAM: repository, service, REST controller, `Rakun.run`. This is the
  file a developer writes; nothing in it is Erlang-aware, which is the point.
- [`examples/runtime-probe-example.bp`](./examples/runtime-probe-example.bp) — the same wiring
  inspected from a `test` block through `rkScannedNames`, `rkBuildCount`, `rkRoutePaths` and
  `rkDispatch`, plus a reply header and a boot option. This is what "the erlang row is green"
  actually asserts.

## Language gaps

The milestone register is [`language-gaps.md`](../../language-gaps.md); the rows below are this front's entries in it, and the cross-front wire formats they touch are in [`contracts.md`](../../contracts.md).

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A sidecar `.erl` is loaded only for a `test` entry point. `__bp_load_siblings/0` is emitted under the test flag (`codegen/erlang.zig:1650-1670`); a `build`/`run` entry point emits no loader, so a built rakun program dies with `undefined function rakun_runtime:serve/2`. | `examples/minimal-app-example.bp` — the whole file is testable but not yet runnable on the erlang row | Run the example through `botopink test --target erlang`, which loads siblings | Emit the same sibling loader (or a `-pa` code-path entry) for `build`/`run` outputs. A toolchain gap, not a language one; recorded here because it decides whether front 04's *serve* half can be demonstrated at all |
| A `fn` cannot forward a `@Result` value it received: inside a `-> @Result<…>` fn `return v` wraps `v` in `Ok`, so returning an already-wrapped value double-wraps — until front 24 lands decision 119 (`return r` with `r` already a `@Result` passes through). | Not used in this front's examples — avoided by keeping the runtime cells total. Bites fronts 08–10. | `.map` / `.flatMap` / `.unwrapOr`, or return the unwrapped value and `throw` on the error path | A forwarding return (`return! r;`) or an implicit-forward rule when the returned expression is already `@Result<D, E>` |

## Test plan

`test/erlang_runtime_test.bp`, run with `botopink test --target erlang` from `repository/rakun/`, and
in the gate as `zig build test-libs -- --target erlang --lib rakun`. It is a new file; the five
existing test files (`di_test.bp`, `router_test.bp`, `scopes_test.bp`, `server_test.bp`,
`overlapping_routes_test.bp`) are **not** modified — they become the real regression suite the moment
the erlang row runs them, and "they pass unchanged" is a stronger statement than anything a new file
could assert.

The new file covers what the old five cannot reach because they were written against Node semantics:
concurrent resolution of one singleton from two processes, the reply-header accumulator, the 500 path
when a handler raises, the boot options, the failure table, and the round-trip shape of `Response`
through a host call.

This front is erlang-only, and so is the core once Step 10 closes. Until then the five existing
files still run on the commonJS row, and the acceptance criteria above are written as
"byte-identical to the commonJS row" wherever a difference would be invisible otherwise; after Step
10 the erlang row is the only one.

## Adjacent fronts

- **74-rakun-tls-ssl-bundles** owns TLS material; this front's listener consumes a named bundle and
  owns no cryptography.
- **17-rakun-logging** owns the one-line startup summary (elapsed, PID, port, active profiles). Front
  04 emits the banner and the failure diagnostics; it does not own the log format.
- **05-rakun-config-profiles** owns every key named above. Front 04 reads them through `rkProp` and
  ships only the defaults.
- **81-rakun-packaging-release** owns the release boot script and `-mode embedded`; front 04 stops at
  `application:start/1`.

## Blocked

- **A built (not tested) erlang program cannot load the sidecar.** See the *Language gaps* table. Front
  04 can be fully green on `botopink test --target erlang` without this; it cannot demonstrate
  `botopink run` serving HTTP on the BEAM. The fix is one emitter change in `codegen/erlang.zig` and
  belongs to whoever owns the erlang entry-point emitter, not to rakun.

## Contradictions with fronts.md

Recorded here because `fronts.md` must stay true; this front does not edit it.

1. **Resolved:** the sidecar is `src/sidecars/rakun_runtime.erl`, not `src/runtime.erl` — the atom
   `runtime` collides with rakun's own emitted `rakun/runtime` module and `shipErlSidecars` skips it
   (`libs.zig:596`), silently. `fronts.md` now mandates the `src/sidecars/rakun_<name>.erl` form
   everywhere; the cowboy adapter seam, if built, is `src/sidecars/rakun_cowboy.erl`.
2. **Resolved:** `src/root.bp` and `botopink.json` are this front's, under the append-only rule above.
   Fronts 05, 06 and 22–25 append their `pub mod` lines; none reorders one.

## Definition of done

- [ ] `src/sidecars/rakun_runtime.erl` exists, compiles under `erlc`, and implements all seventeen
      existing cells plus `set_reply_header/2`, `reply_headers_json/0`, `boot/1` and `add_failure/3`
- [ ] Every cell in `src/runtime.bp` carries an `@External.Erlang` form; no cell in this front is
      Node-only, and no *new* cell carries a Node form at all
- [ ] the core member declares `"target": "erlang"`, `"targets": ["erlang"]`; `src/runtime.mjs` and
      every `#[@External.Node]` form are gone from the core (decision 113); `src/root.bp` plus the
      manifest are claimed by this front under the append-only, front-number-order rule
- [ ] The five pre-existing test files pass on `--target erlang` with no source change
- [ ] rakun's erlang cell is removed from `scripts/known-red-libs.txt`
- [ ] `repository/rakun/AGENTS.md` documents the host module, its OTP shape, the sidecar path and the
      `rakun.main.*` / `rakun.server.*` key set
- [ ] The front's tests are green on its assigned target
