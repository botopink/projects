# rakun — snapshot-test map of the modules

**Track:** B — rakun · **Repo:** `repository/rakun` · **Contract:** [`../01-std/snapshots.md`](../01-std/snapshots.md) · [`../01-std/src-builtin.md`](../01-std/src-builtin.md) · [`../01-std/asserts-api.md`](../01-std/asserts-api.md) · **Cut:** [`modules.md`](./modules.md)

This is the preventive test plan of every `repository/rakun/modules/**` submodule: for each front, the
tests that pin its acceptance criteria as snapshots, and the exact `.snap` file each one writes. A
front that lands without its rows here green has not landed. The companion map for
`repository/rakun/examples/**` is [`test-snap-examples.md`](./test-snap-examples.md).

## The contract

```bp
type SourceLocation(file: string, line: i32, column: i32, fnName: string)   // @src(), comptime
```

- Every helper is `assert<Subject>(loc: SourceLocation, …) -> @Result<void, string>` and is exported
  by `modules/rakun-test`. A test calls it with `try`.
- `snapshots.path(loc)` = `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap`. `suite` is the text
  before the first `": "` of the test name; `slug` is the rest, lower-cased, every run of characters
  outside `[a-z0-9]` collapsed to one `-`, leading and trailing `-` trimmed. `"route: get ---- static
  path with a query"` → `__snapshots__/route/get-static-path-with-a-query.snap`.
- A mismatch or a missing file writes `<path>.new` and returns `err`. Nothing accepts a snapshot but a
  person renaming the `.new` file. There is no update flag.
- Snapshot bodies are UTF-8, LF, no trailing whitespace, one trailing newline. Keys inside a body are
  sorted where the rule below says `sorted`; everything else is in the order the subject produced it.
- The `\\` block a helper receives is **botopink source**, the same text a `.bp` file would hold.
  `rakun-test` feeds it to `rkScanSource(text)` — front 19's scratch context (§ *Slices and context
  caching*): the decorators run, the registries fill, the helper renders them, `resetContext()` runs
  after. The scratch context is what makes a snapshot of a *declaration* possible without a server.
  Whether comptime source evaluation at test time is a language gap is recorded in
  [`../../language-gaps.md`](../language-gaps.md); this document assumes the contract in
  `../01-std/snapshots.md`.
- Every test is on the submodule's assigned target (erlang unless the row says boundary). A boundary
  test writes ONE snapshot and is run on both targets; both runs must match the same file.

### `.bp` rules these tests obey

`if` is an expression and needs `else`; a bare `if` is only allowed as the last statement of a block.
No `//` comments inside closure, template or enum bodies. Array types are postfix `T[]`. `(expr).method()`
does not parse — bind to a `val`. `if (a && b)` in condition position does not parse — bind to a `val`.
Functions are camelCase. Multi-line strings are leading-`\\` lines.

## Helpers `rakun-test` exposes

One helper per subject. `source` is a `\\` block of botopink; `request` is `"<METHOD> <path>[ <header>: <v>]*[ | <body>]"`;
`requests`/`calls`/`events` are `string[]`. Bodies render as described; a value that would be
unstable (a timestamp, a random id, a pid) is rendered through a fixed test clock/seed the helper
installs, so no snapshot ever contains a wall-clock value.

| Module | Helper | Renders |
|---|---|---|
| `rakun` | `assertContext(loc, source, probes: string[])` | `bean <Type> scope=<s> deps=[…]` sorted by type; then `resolve <T> -> ok\|missing` per probe |
| `rakun` | `assertConfig(loc, sources: string[], keys: string[])` | one `key = value  (<source>)` per key, in key order given; `key = <unset>` when nothing binds |
| `rakun` | `assertLifecycle(loc, source, script: string[])` | the ordered hook/event log, one `<phase> <who> <what>` per line |
| `rakun` | `assertAutoConfig(loc, source, present: string[])` | the condition report: `+ <Config>  <condition>` / `- <Config>  <condition>` sorted by name |
| `rakun` | `assertRequestContext(loc, source, request)` | `phase`, `cookies`, `headers`, `memo` hits/misses, `after` queue, as `key: value` blocks |
| `rakun` | `assertSslBundle(loc, config: string[], probes: string[])` | `bundle <name> kind=<pem\|jks> protocols=[…] ciphers=[…]` then `probe <what> -> ok\|err <msg>` |
| `rakun` | `assertBoot(loc, source, argv: string[])` | `listen <host>:<port>`, `beans <n>`, `routes <n>`, `exit <code>` |
| `rakun-web` | `assertRoute(loc, source, requests)` | route table `<METHOD> <path> -> <Type>.<fn>` sorted by path then method; blank line; `<METHOD> <path> -> <status> <body>` per request |
| `rakun-web` | `assertMiddleware(loc, source, requests)` | chain `order <n> <name> [matcher <pat>]`; per request a trace `> <entry> pass\|redirect <s> <loc>\|rewrite <path>\|short <status>` and `= <status> [<header>=<v>…]` |
| `rakun-web` | `assertProblem(loc, source, request)` | the RFC 9457 body as sorted JSON keys, one per line, plus `content-type` |
| `rakun-web` | `assertCors(loc, config: string[], request)` | `preflight\|simple`, `allowed <bool>`, then response headers sorted |
| `rakun-web` | `assertUrlRules(loc, rules: string[], paths: string[])` | `<path> -> pass\|match\|rewrite <to>\|redirect <status> <to>\|refused <why>` per path |
| `rakun-web` | `assertStatic(loc, files: string[], requests)` | per request `<status> <content-type> etag=<h> cache-control=<v>` |
| `rakun-websocket` | `assertWebSocket(loc, source, frames: string[])` | `upgrade <status>`; then `< <frame>` / `> <frame>` in order; `close <code>` |
| `rakun-app` | `assertRouteTree(loc, tree: string[], paths: string[])` | table `P\|L\|R\|N <pattern> layouts=[…] kind=static\|dynamic\|catch-all\|optional`; blank; `<path> -> <pattern> {params}` or `-> 404` |
| `rakun-app` | `assertSsr(loc, tree, request)` | `status`, `headers` sorted, then `html:` block, then `payload:` block |
| `rakun-app` | `assertAction(loc, source, form: string)` | `action <name>`, `result <value>`, `revalidate [tags]`, `redirect <status> <loc>` when any |
| `rakun-app` | `assertHandler(loc, source, request)` | `<status>` line, headers sorted, `chunks <n>`, then body |
| `rakun-app` | `assertStaticGen(loc, tree, source)` | per route `<pattern> static\|dynamic because <reason> params=[…] revalidate=<n\|never>` |
| `rakun-app` | `assertSlots(loc, tree, navigation: string[])` | per navigation `<from> -> <to>: slot <name>=<matched\|default> intercept=<none\|(.)…>` |
| `rakun-app` | `assertNavigation(loc, source, request)` | `signal <redirect\|permanentRedirect\|notFound\|forbidden\|unauthorized>`, `status`, `location` |
| `rakun-app` | `assertLocale(loc, config: string[], request)` | `negotiated <locale> from <accept-language\|cookie\|path\|default>`, `redirect <status> <path>` or `serve <pattern>` |
| `rakun-app` | `assertMetadataRoutes(loc, tree, request)` | `<path> -> <status> <content-type>` and the body |
| `rakun-data` | `assertQuery(loc, source, calls)` | per call `<Repo>.<fn>(<args>) -> <SQL>  params=[…]`; a `#[transactional]` call is wrapped in `begin` / `commit\|rollback` lines |
| `rakun-data` | `assertMigration(loc, migrations: string[], state: string[])` | `pending <version> <name>`, `applied <version> <checksum>`, `refused <why>` |
| `rakun-data` | `assertEntity(loc, source)` | the DDL the entity produces, then `map <field> <- <column> <type>` sorted by field |
| `rakun-data` | `assertStore(loc, source, ops: string[])` | per op `<store>.<op>(<args>) -> <result>` |
| `rakun-tx` | `assertOutbox(loc, source, script: string[])` | `write <table>`, `outbox <n> pending`, `relay -> published <dest>\|failed <why>`, `outbox <n> pending` |
| `rakun-tx` | `assertSaga(loc, source, script: string[])` | per step `step <name> ok\|failed`, then `compensate <name>` lines in order |
| `rakun-security` | `assertSecurity(loc, source, requests)` | per request `<METHOD> <path> [<principal>] -> <status> <decision>` where decision is `anonymous\|authenticated\|denied <rule>\|granted <rule>` |
| `rakun-security` | `assertOAuth(loc, config: string[], step: string)` | `authorize <url>` with sorted query keys, or `token <ok\|err>`, `principal <name> authorities=[…]` |
| `rakun-session` | `assertSession(loc, source, requests)` | per request `<METHOD> <path> -> <status> session=<new\|same\|none> set-cookie=<attrs>` |
| `rakun-validation` | `assertValidation(loc, source, input: string)` | `valid` or `invalid`, then `<field>: <constraint> <message>` sorted by field |
| `rakun-cache` | `assertCache(loc, source, calls)` | per call `<fn>(<args>) -> <hit\|miss\|evict\|revalidate> key=<k> [tags]` |
| `rakun-client` | `assertClient(loc, source, exchanges: string[])` | per exchange `<METHOD> <url> -> <status>` then the request headers sorted, `retry <n>` when any |
| `rakun-actuator-api` | `assertRegistry(loc, source)` | `health <name>`, `info <name>`, `endpoint <id> [<ops>]` sorted |
| `rakun-actuator` | `assertHealth(loc, source, script: string[])` | `status <UP\|DOWN\|OUT_OF_SERVICE\|UNKNOWN>` then `components:` block sorted by name |
| `rakun-actuator` | `assertEndpoint(loc, source, request)` | `<status>` then the body as sorted JSON keys |
| `rakun-actuator` | `assertExposure(loc, config: string[], requests)` | per request `<path> [<principal>] -> <status> <exposed\|hidden\|denied>` |
| `rakun-actuator` | `assertProbe(loc, source, script: string[])` | `<t> liveness=<state> readiness=<state>` per script step |
| `rakun-actuator` | `assertAudit(loc, source, script: string[])` | `<type> principal=<p> data={…sorted}` per recorded event |
| `rakun-actuator` | `assertExchanges(loc, source, requests)` | per recorded exchange `<METHOD> <path> -> <status> [include=…]` |
| `rakun-metrics` | `assertMetrics(loc, source, events: string[])` | the Prometheus text exposition, meters sorted by name, labels sorted |
| `rakun-metrics` | `assertTrace(loc, source, request)` | `trace <id> spans:` then `<name> parent=<name\|-> kind=<server\|client\|internal>` in start order |
| `rakun-logging` | `assertLog(loc, config: string[], events: string[])` | one rendered line per event in the configured format, correlation id from the test seed |
| `rakun-messaging` | `assertListener(loc, source, deliveries: string[])` | `listener <destination> -> <Type>.<fn> broker=<amqp\|kafka\|jms>` sorted; then `deliver <dest> <payload> -> <ok\|nack\|dead-letter>` |
| `rakun-messaging` | `assertRetry(loc, config: string[], outcomes: string[])` | `attempt <n> at +<ms> -> <ok\|fail>`, `dead-letter <dest>` / `idempotent skip <key>` |
| `rakun-pulsar` | `assertPulsar(loc, source, script)` | as `assertListener` with `broker=pulsar`, plus `ack <mode>` |
| `rakun-stream` | `assertStream(loc, topology: string, inputs: string[])` | `graph:` block `<stage> -> <stage>`, then `out <sink> <value>` per emitted value |
| `rakun-rsocket` | `assertRSocket(loc, source, frames: string[])` | `route <name> model=<fnf\|rr\|rs\|channel>` sorted; then frame exchange lines |
| `rakun-scheduling` | `assertSchedule(loc, source, ticks: string[])` | `task <name> <cron\|fixedRate\|fixedDelay> <expr>` sorted; then `<t> fire <name>` per tick |
| `rakun-scheduling` | `assertJobStore(loc, source, script)` | `job <name> state=<state> owner=<node\|->` after each script step |
| `rakun-mail` | `assertMail(loc, source, send: string)` | the MIME message with `Date` from the test clock, headers sorted, body |
| `rakun-hateoas` | `assertHal(loc, source, call: string)` | the HAL document as sorted JSON keys, `_links` first |
| `rakun-soap` | `assertSoap(loc, source, call: string)` | the SOAP envelope sent, then `<status> <fault\|body>` |
| `rakun-devtools` | `assertReload(loc, script: string[])` | `watch <path>`, `change <file> -> reload <module> in <n> steps`, `keep <state>` |
| `rakun-release` | `assertRelease(loc, manifest: string[])` | the release tree, one path per line sorted, then `sbom <n> components`, `probes <paths>` |
| `rakun-cli` | `assertCli(loc, argv: string[])` | `exit <code>` then stdout, then `files:` created sorted |
| `starters` | `assertStarter(loc, starter: string)` | `brings [modules sorted]`, `autoconfig [names sorted]` |

The rendering rules above are the whole snapshot format: a helper renders nothing that is not
listed for it, and two helpers never render the same fact two ways.

## The fronts, grouped by submodule

Order inside each group is ascending front number; the groups follow the cut in [`modules.md`](./modules.md): core and configuration, the `app/` convention, web/data/security, cache/actuator/clients/observability, messaging/scheduling/operations.

## 04-rakun-erlang-runtime — `rakun`

**Test file:** `modules/rakun/test/erlang_runtime_test.bp` · **Snapshots:** `modules/rakun/test/__snapshots__/runtime/` · **Target:** erlang · **Pins:** Step 3 (`rkProp` absent → `""`, `rkPropInt` absent/unparsable → `0`), Step 4 (`:name` binds, unmatched → 404 empty body, registration order decides), Step 5 (second write replaces, no leak to request n+1, no header = same bytes), Step 6 (GET 200, 404, POST body intact, repeated query key → first, header case-insensitive, raise → 500 then next request 200), Step 7 (`rakun.main.headless` + `keep-alive=false` halts 0, `rkRouteCount` still correct), Step 9 (unknown transport fails naming the value, no silent fallback), Step 10 (erlang row green)

> helper gap: `assertBoot` renders `listen none` when no listener binds (headless, or a startup failure); the failure-diagnostic blocks are not rendered — only `exit <code>`. `argv` entries are front 05's command-line form `--<key>=<value>`.

### `runtime: a minimal app boots, scans three beans and registers two routes`

```bp
test "runtime: a minimal app boots, scans three beans and registers two routes" {
    try assertBoot(@src(),
        \\ import {repository, service, restController, route, getMapping, postMapping};
        \\ import {Rakun, App, Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\
        \\ #[repository]
        \\ type NoteRepository {
        \\     pub fn all(self: Self) -> Array<string> {
        \\         return ["first note", "second note"];
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ type NoteService(
        \\     repo: NoteRepository,
        \\ ) {
        \\     pub fn list(self: Self) -> string {
        \\         return self.repo.all().join(" | ");
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/notes")]
        \\ type NoteController(
        \\     svc: NoteService,
        \\ ) {
        \\     #[getMapping("/")]
        \\     pub fn index(self: Self, req: Request) -> Response {
        \\         return Response.ok(self.svc.list());
        \\     }
        \\
        \\     #[postMapping("/")]
        \\     pub fn create(self: Self, req: Request) -> Response {
        \\         val body = req.body();
        \\         return if (body == "") Response.badRequest("empty body") else Response.created("created: " + body);
        \\     }
        \\ }
        \\
        \\ fn main() {
        \\     Rakun.run(App(port: 8080, basePath: "/api"));
        \\ }
        , []);
}
```

`modules/rakun/test/__snapshots__/runtime/a-minimal-app-boots-scans-three-beans-and-registers-two-routes.snap`
```
listen 0.0.0.0:8080
beans 3
routes 2
exit 0
```

### `runtime: headless without keep-alive starts no listener and halts with status 0`

```bp
test "runtime: headless without keep-alive starts no listener and halts with status 0" {
    try assertBoot(@src(),
        \\ import {repository, service, restController, route, getMapping, postMapping};
        \\ import {Rakun, App, Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\
        \\ #[repository]
        \\ type NoteRepository {
        \\     pub fn all(self: Self) -> Array<string> {
        \\         return ["first note", "second note"];
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ type NoteService(
        \\     repo: NoteRepository,
        \\ ) {
        \\     pub fn list(self: Self) -> string {
        \\         return self.repo.all().join(" | ");
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/notes")]
        \\ type NoteController(
        \\     svc: NoteService,
        \\ ) {
        \\     #[getMapping("/")]
        \\     pub fn index(self: Self, req: Request) -> Response {
        \\         return Response.ok(self.svc.list());
        \\     }
        \\
        \\     #[postMapping("/")]
        \\     pub fn create(self: Self, req: Request) -> Response {
        \\         return Response.created("created: " + req.body());
        \\     }
        \\ }
        \\
        \\ fn main() {
        \\     Rakun.run(App(port: 8080, basePath: "/api"));
        \\ }
        , ["--rakun.main.headless=true", "--rakun.main.keep-alive=false"]);
}
```

`modules/rakun/test/__snapshots__/runtime/headless-without-keep-alive-starts-no-listener-and-halts-with-status-0.snap`
```
listen none
beans 3
routes 2
exit 0
```

### `runtime: an unknown transport fails the boot instead of falling back`

```bp
test "runtime: an unknown transport fails the boot instead of falling back" {
    try assertBoot(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Rakun, App, Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\
        \\ #[restController]
        \\ #[route("/ping")]
        \\ type PingController {
        \\     #[getMapping("/")]
        \\     pub fn ping(self: Self, req: Request) -> Response {
        \\         return Response.ok("pong");
        \\     }
        \\ }
        \\
        \\ fn main() {
        \\     Rakun.run(App(port: 8080, basePath: "/"));
        \\ }
        , ["--rakun.server.transport=nonsense"]);
}
```

`modules/rakun/test/__snapshots__/runtime/an-unknown-transport-fails-the-boot-instead-of-falling-back.snap`
```
listen none
beans 1
routes 1
exit 1
```

### `runtime: a path param binds and a miss answers 404 with an empty body`

```bp
test "runtime: a path param binds and a miss answers 404 with an empty body" {
    try assertRoute(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\
        \\ #[restController]
        \\ #[route("/probe")]
        \\ type ProbeController {
        \\     #[getMapping("/rows")]
        \\     pub fn rows(self: Self, req: Request) -> Response {
        \\         return Response.ok("a,b,c");
        \\     }
        \\
        \\     #[getMapping("/echo/:word")]
        \\     pub fn echo(self: Self, req: Request) -> Response {
        \\         return Response.ok(req.param("word"));
        \\     }
        \\ }
        , ["GET /probe/echo/hello", "GET /probe/nothing-here"]);
}
```

`modules/rakun/test/__snapshots__/runtime/a-path-param-binds-and-a-miss-answers-404-with-an-empty-body.snap`
```
GET /probe/echo/:word -> ProbeController.echo
GET /probe/rows -> ProbeController.rows

GET /probe/echo/hello -> 200 hello
GET /probe/nothing-here -> 404
```

### `runtime: registration order decides between two routes that both match`

```bp
test "runtime: registration order decides between two routes that both match" {
    try assertRoute(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\
        \\ #[restController]
        \\ #[route("/items")]
        \\ type ItemController {
        \\     #[getMapping("/:id")]
        \\     pub fn byId(self: Self, req: Request) -> Response {
        \\         return Response.ok("id=" + req.param("id"));
        \\     }
        \\
        \\     #[getMapping("/new")]
        \\     pub fn form(self: Self, req: Request) -> Response {
        \\         return Response.ok("form");
        \\     }
        \\ }
        , ["GET /items/new", "GET /items/42"]);
}
```

`modules/rakun/test/__snapshots__/runtime/registration-order-decides-between-two-routes-that-both-match.snap`
```
GET /items/:id -> ItemController.byId
GET /items/new -> ItemController.form

GET /items/new -> 200 id=new
GET /items/42 -> 200 id=42
```

### `runtime: a repeated query key takes the first occurrence and an absent one is empty`

```bp
test "runtime: a repeated query key takes the first occurrence and an absent one is empty" {
    try assertRoute(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\
        \\ #[restController]
        \\ #[route("/search")]
        \\ type SearchController {
        \\     #[getMapping("/")]
        \\     pub fn search(self: Self, req: Request) -> Response {
        \\         return Response.ok("q=" + req.query("q") + " page=" + req.query("page"));
        \\     }
        \\ }
        , ["GET /search/?q=a&q=b"]);
}
```

`modules/rakun/test/__snapshots__/runtime/a-repeated-query-key-takes-the-first-occurrence-and-an-absent-one-is-empty.snap`
```
GET /search/ -> SearchController.search

GET /search/?q=a&q=b -> 200 q=a page=
```

### `runtime: header lookup is case-insensitive and a post body arrives intact`

```bp
test "runtime: header lookup is case-insensitive and a post body arrives intact" {
    try assertRoute(@src(),
        \\ import {restController, route, postMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\
        \\ #[restController]
        \\ #[route("/echo")]
        \\ type EchoController {
        \\     #[postMapping("/")]
        \\     pub fn echo(self: Self, req: Request) -> Response {
        \\         return Response.ok(req.header("x-token") + ":" + req.body());
        \\     }
        \\ }
        , ["POST /echo/ X-Token: abc | hello world"]);
}
```

`modules/rakun/test/__snapshots__/runtime/header-lookup-is-case-insensitive-and-a-post-body-arrives-intact.snap`
```
POST /echo/ -> EchoController.echo

POST /echo/ -> 200 abc:hello world
```

### `runtime: a handler that raises answers 500 and the next request answers 200`

```bp
test "runtime: a handler that raises answers 500 and the next request answers 200" {
    try assertRoute(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\
        \\ #[restController]
        \\ #[route("/fault")]
        \\ type FaultController {
        \\     #[getMapping("/boom")]
        \\     pub fn boom(self: Self, req: Request) -> Response {
        \\         @panic("kaboom");
        \\         return Response.ok("unreachable");
        \\     }
        \\
        \\     #[getMapping("/ok")]
        \\     pub fn ok(self: Self, req: Request) -> Response {
        \\         return Response.ok("still here");
        \\     }
        \\ }
        , ["GET /fault/boom", "GET /fault/ok"]);
}
```

`modules/rakun/test/__snapshots__/runtime/a-handler-that-raises-answers-500-and-the-next-request-answers-200.snap`
```
GET /fault/boom -> FaultController.boom
GET /fault/ok -> FaultController.ok

GET /fault/boom -> 500 kaboom
GET /fault/ok -> 200 still here
```

### `runtime: a second write to one reply header replaces the first and the next request starts clean`

```bp
test "runtime: a second write to one reply header replaces the first and the next request starts clean" {
    try assertRoute(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {rkSetReplyHeader, rkReplyHeaders};
        \\
        \\ #[restController]
        \\ #[route("/reply")]
        \\ type ReplyController {
        \\     #[getMapping("/once")]
        \\     pub fn once(self: Self, req: Request) -> Response {
        \\         val _a = rkSetReplyHeader("X-Once", "first");
        \\         val _b = rkSetReplyHeader("X-Once", "second");
        \\         return Response.ok(rkReplyHeaders());
        \\     }
        \\
        \\     #[getMapping("/none")]
        \\     pub fn none(self: Self, req: Request) -> Response {
        \\         return Response.ok(rkReplyHeaders());
        \\     }
        \\ }
        , ["GET /reply/once", "GET /reply/none"]);
}
```

`modules/rakun/test/__snapshots__/runtime/a-second-write-to-one-reply-header-replaces-the-first-and-the-next-request-starts-clean.snap`
```
GET /reply/none -> ReplyController.none
GET /reply/once -> ReplyController.once

GET /reply/once -> 200 {"X-Once":"second"}
GET /reply/none -> 200 {}
```

### `runtime: the property store answers empty and zero for absent or unparsable keys`

```bp
test "runtime: the property store answers empty and zero for absent or unparsable keys" {
    try assertRoute(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {rkSetProp, rkProp, rkPropInt};
        \\
        \\ val _backlog = rkSetProp("rakun.server.backlog", "256");
        \\ val _idle = rkSetProp("rakun.server.idle-timeout", "12abc");
        \\
        \\ #[restController]
        \\ #[route("/props")]
        \\ type PropController {
        \\     #[getMapping("/")]
        \\     pub fn read(self: Self, req: Request) -> Response {
        \\         val absent = rkProp("no.such.key") + "|" + rkPropInt("no.such.key").toString();
        \\         val parsed = rkPropInt("rakun.server.backlog").toString() + "|" + rkPropInt("rakun.server.idle-timeout").toString();
        \\         return Response.ok(absent + "|" + parsed);
        \\     }
        \\ }
        , ["GET /props/"]);
}
```

`modules/rakun/test/__snapshots__/runtime/the-property-store-answers-empty-and-zero-for-absent-or-unparsable-keys.snap`
```
GET /props/ -> PropController.read

GET /props/ -> 200 |0|256|0
```

## 05-rakun-config-profiles — `rakun`

**Test file:** `modules/rakun/test/config_test.bp` · **Snapshots:** `modules/rakun/test/__snapshots__/config/` · **Target:** erlang · **Pins:** Step 1 (`.properties` reads back, JSON object → dot keys, JSON array → `a[0]`/`a[1]`), Step 3 (each of the eight rows beats the row below, `rkSetProp` loses to files and wins over a field default, `RAKUN_APPLICATION_JSON` beats env), Step 4 (`${key}` resolves, `${missing:fallback}`, unresolvable `${key}` refuses naming both, `a=${b}`/`b=${a}` refuses), Step 5 (`#---` document with `on-profile` contributes only when active, `"prod | staging"` grammar, non-contributing document leaves the key absent), Step 6 (`rakun.profiles.active` loads `application-<p>`, later active profile wins), Step 7 (`#[configurationProperties]` binds `my.service.*`, `#[nested]` under `<prefix>.<field>`, bound record injectable into a `#[service]`, `remoteAddress` ↔ `remote-address`), Step 8 (`30` under `#[unit("seconds")]` = 30000 ms, `250ms`, `2MB` = 2097152), env mapping (`_` → `.`, `__` → `-`, non-`RAKUN_` ignored)

> helper gap: `assertConfig` source strings are `<origin> <line>` — origin ∈ {`argv`, `RAKUN_APPLICATION_JSON`, `env`, `application-<profile>.<ext>`, `application.<ext>`, `configtree`, `programmatic`, `default`}; the lines of one origin, in order, form that document (so `#---` is a line of a `.properties` document). The rendered `(<source>)` is the origin verbatim.
> helper gap: `assertConfig` renders a boot refusal as one line `refused <message>` and nothing else.

### `config: every source beats the one below it across all eight rows`

```bp
test "config: every source beats the one below it across all eight rows" {
    try assertConfig(@src(), [
        "argv --order.k1=argv",
        "RAKUN_APPLICATION_JSON {\"order\":{\"k1\":\"json\",\"k2\":\"json\"}}",
        "env RAKUN_ORDER_K2=env",
        "env RAKUN_ORDER_K3=env",
        "application-prod.properties order.k3=profile",
        "application-prod.properties order.k4=profile",
        "application.properties order.k4=base",
        "application.properties order.k5=base",
        "configtree order/k5=tree",
        "configtree order/k6=tree",
        "programmatic order.k6=programmatic",
        "programmatic order.k7=programmatic",
        "programmatic rakun.profiles.active=prod",
        "default order.k7=declared",
        "default order.k8=declared",
    ], ["order.k1", "order.k2", "order.k3", "order.k4", "order.k5", "order.k6", "order.k7", "order.k8"]);
}
```

`modules/rakun/test/__snapshots__/config/every-source-beats-the-one-below-it-across-all-eight-rows.snap`
```
order.k1 = argv  (argv)
order.k2 = json  (RAKUN_APPLICATION_JSON)
order.k3 = env  (env)
order.k4 = profile  (application-prod.properties)
order.k5 = base  (application.properties)
order.k6 = tree  (configtree)
order.k7 = programmatic  (programmatic)
order.k8 = declared  (default)
```

### `config: a json document flattens nested objects and arrays to dot and indexed keys`

```bp
test "config: a json document flattens nested objects and arrays to dot and indexed keys" {
    try assertConfig(@src(), [
        "application.json {\"server\":{\"port\":8080},\"a\":[\"x\",\"y\"]}",
    ], ["server.port", "a[0]", "a[1]", "a[2]"]);
}
```

`modules/rakun/test/__snapshots__/config/a-json-document-flattens-nested-objects-and-arrays-to-dot-and-indexed-keys.snap`
```
server.port = 8080  (application.json)
a[0] = x  (application.json)
a[1] = y  (application.json)
a[2] = <unset>
```

### `config: a profile document beats the base and the later active profile wins`

```bp
test "config: a profile document beats the base and the later active profile wins" {
    try assertConfig(@src(), [
        "programmatic rakun.profiles.active=dev,prod",
        "application.properties db.url=base",
        "application.properties db.pool-size=1",
        "application.properties db.name=mydb",
        "application-dev.properties db.url=dev",
        "application-dev.properties db.pool-size=5",
        "application-prod.properties db.url=prod",
    ], ["db.url", "db.pool-size", "db.name"]);
}
```

`modules/rakun/test/__snapshots__/config/a-profile-document-beats-the-base-and-the-later-active-profile-wins.snap`
```
db.url = prod  (application-prod.properties)
db.pool-size = 5  (application-dev.properties)
db.name = mydb  (application.properties)
```

### `config: a placeholder resolves from another key or falls back to its default`

```bp
test "config: a placeholder resolves from another key or falls back to its default" {
    try assertConfig(@src(), [
        "application.properties app.name=billing",
        "application.properties app.title=\${app.name} service",
        "application.properties app.region=\${app.zone:eu-west-1}",
    ], ["app.title", "app.region"]);
}
```

`modules/rakun/test/__snapshots__/config/a-placeholder-resolves-from-another-key-or-falls-back-to-its-default.snap`
```
app.title = billing service  (application.properties)
app.region = eu-west-1  (application.properties)
```

### `config: an on-profile document contributes when its profile is active`

```bp
test "config: an on-profile document contributes when its profile is active" {
    try assertConfig(@src(), [
        "programmatic rakun.profiles.active=staging",
        "application.properties billing.endpoint=https://billing.internal",
        "application.properties #---",
        "application.properties rakun.config.activate.on-profile=prod | staging",
        "application.properties billing.endpoint=https://billing.example.com",
        "application.properties billing.region=eu-central-1",
    ], ["billing.endpoint", "billing.region"]);
}
```

`modules/rakun/test/__snapshots__/config/an-on-profile-document-contributes-when-its-profile-is-active.snap`
```
billing.endpoint = https://billing.example.com  (application.properties)
billing.region = eu-central-1  (application.properties)
```

### `config: an on-profile document contributes nothing when its profile is not active`

```bp
test "config: an on-profile document contributes nothing when its profile is not active" {
    try assertConfig(@src(), [
        "programmatic rakun.profiles.active=dev",
        "application.properties billing.endpoint=https://billing.internal",
        "application.properties #---",
        "application.properties rakun.config.activate.on-profile=prod | staging",
        "application.properties billing.endpoint=https://billing.example.com",
        "application.properties billing.region=eu-central-1",
    ], ["billing.endpoint", "billing.region"]);
}
```

`modules/rakun/test/__snapshots__/config/an-on-profile-document-contributes-nothing-when-its-profile-is-not-active.snap`
```
billing.endpoint = https://billing.internal  (application.properties)
billing.region = <unset>
```

### `config: environment variables map to relaxed keys and unprefixed ones are ignored`

```bp
test "config: environment variables map to relaxed keys and unprefixed ones are ignored" {
    try assertConfig(@src(), [
        "env RAKUN_SERVER_PORT=8081",
        "env RAKUN_APP_POOL__SIZE=10",
        "env OTHER_SERVER_PORT=1",
    ], ["server.port", "app.pool-size", "other.server.port"]);
}
```

`modules/rakun/test/__snapshots__/config/environment-variables-map-to-relaxed-keys-and-unprefixed-ones-are-ignored.snap`
```
server.port = 8081  (env)
app.pool-size = 10  (env)
other.server.port = <unset>
```

### `config: a typed record binds nested blocks, a unit default, a duration and a data size`

```bp
test "config: a typed record binds nested blocks, a unit default, a duration and a data size" {
    try assertRoute(@src(),
        \\ import {restController, route, getMapping};
        \\ import {configurationProperties, nested, unit};
        \\ import {Request, Response, Duration, DataSize};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute, rkSetProp};
        \\ import {rkProp, rkPropBool, rkPropDuration, rkPropSize};
        \\
        \\ val _p1 = rkSetProp("billing.enabled", "true");
        \\ val _p2 = rkSetProp("billing.endpoint", "https://billing.internal");
        \\ val _p3 = rkSetProp("billing.request-timeout", "30");
        \\ val _p4 = rkSetProp("billing.max-body", "2MB");
        \\ val _p5 = rkSetProp("billing.retry.attempts", "3");
        \\ val _p6 = rkSetProp("billing.retry.backoff", "250ms");
        \\
        \\ #[configurationProperties("billing.retry")]
        \\ type RetryProperties(
        \\     attempts: i32,
        \\     backoff: Duration,
        \\ )
        \\
        \\ #[configurationProperties("billing")]
        \\ type BillingProperties(
        \\     enabled: bool,
        \\     endpoint: string,
        \\     #[unit("seconds")]
        \\     requestTimeout: Duration,
        \\     #[unit("megabytes")]
        \\     maxBody: DataSize,
        \\     #[nested]
        \\     retry: RetryProperties,
        \\ )
        \\
        \\ #[restController]
        \\ #[route("/billing")]
        \\ type BillingController(
        \\     props: BillingProperties,
        \\ ) {
        \\     #[getMapping("/")]
        \\     pub fn describe(self: Self, req: Request) -> Response {
        \\         val timeout = self.props.requestTimeout.millis.toString();
        \\         val body = self.props.maxBody.bytes.toString();
        \\         val attempts = self.props.retry.attempts.toString();
        \\         val backoff = self.props.retry.backoff.millis.toString();
        \\         return Response.ok(self.props.endpoint + "|" + timeout + "|" + body + "|" + attempts + "|" + backoff);
        \\     }
        \\ }
        , ["GET /billing/"]);
}
```

`modules/rakun/test/__snapshots__/config/a-typed-record-binds-nested-blocks-a-unit-default-a-duration-and-a-data-size.snap`
```
GET /billing/ -> BillingController.describe

GET /billing/ -> 200 https://billing.internal|30000|2097152|3|250
```

### `config: an unresolvable placeholder with no default refuses the boot`

```bp
test "config: an unresolvable placeholder with no default refuses the boot" {
    try assertConfig(@src(), [
        "application.properties app.title=\${app.name} service",
    ], ["app.title"]);
}
```

`modules/rakun/test/__snapshots__/config/an-unresolvable-placeholder-with-no-default-refuses-the-boot.snap`
```
refused placeholder ${app.name} referenced by app.title (application.properties) has no value and no default
```

### `config: a placeholder cycle refuses the boot naming both keys`

```bp
test "config: a placeholder cycle refuses the boot naming both keys" {
    try assertConfig(@src(), [
        "application.properties a=\${b}",
        "application.properties b=\${a}",
    ], ["a"]);
}
```

`modules/rakun/test/__snapshots__/config/a-placeholder-cycle-refuses-the-boot-naming-both-keys.snap`
```
refused placeholder cycle a -> b -> a (application.properties)
```

## 06-rakun-context-api — `rakun`

**Test file:** `modules/rakun/test/context_test.bp` (suite `context`) · `modules/rakun/test/events_test.bp` (suite `events`) · **Snapshots:** `modules/rakun/test/__snapshots__/context/` · `modules/rakun/test/__snapshots__/events/` · **Target:** erlang · **Pins:** Step 1 (`#[managed]` registers one bean, `rkBeanNames` in declaration order, unregistered → `null`/`false`), Step 2 (`Context` injectable without declaration, `Context` absent from its own `beanNames()`), Step 3 (`#[provides]` makes the type injectable, distinct `#[qualifier]`s both register and `resolveNamed` picks each, `#[primary]` answers the unqualified lookup), Step 4 (`#[postConstruct]` runs once before `eagerInit` returns, `#[preDestroy]` in reverse registration order), Step 5 (two listeners in registration order, a raising listener is logged and does not stop the rest, eight boot events in order, `ApplicationFailed` replaces the tail), Step 6 (`#[scope("prototype")]`, `#[scope("request")]` registered as such), Step 7 (eager by default, cyclic graph reported through front 04's diagnostics), Step 8 (pre-destroy pass, `#[exitCode]` highest wins, raising pre-destroy does not stop the rest)

> helper gap: `assertContext` probes and bean lines carry a qualifier as `<T>@<qualifier>`; a bean marked `#[primary]` renders a trailing ` primary`.
> helper gap: `assertLifecycle` script verbs are `boot` (`context.bootSequence()`), `eagerInit` (`context.eagerInit()`), `publish <name> <payload>` (`ctx.publish(Event(...))`), `terminate` (`rakun_context:terminate/2`); phases in the log are `boot`, `post`, `pre`, `event`, `fail`, `exit`, `stop`.

### `context: managed beans resolve by type and an unregistered type is missing`

```bp
test "context: managed beans resolve by type and an unregistered type is missing" {
    try assertContext(@src(),
        \\ import {repository, service, managed, provides, Context};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone};
        \\ import {rkRegisterBean, rkRegisterLifecycle, rkRegisterListener};
        \\
        \\ type Clock(zone: string)
        \\
        \\ #[provides]
        \\ fn systemClock() -> Clock {
        \\     return Clock(zone: "UTC");
        \\ }
        \\
        \\ #[repository]
        \\ #[managed]
        \\ type OrderRepository {
        \\     pub fn ids(self: Self) -> Array<string> {
        \\         return ["o-1", "o-2", "o-3"];
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ type OrderCache(
        \\     repo: OrderRepository,
        \\     clock: Clock,
        \\ ) {
        \\     pub fn size(self: Self) -> i32 {
        \\         return self.repo.ids().length;
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ type ReportService(
        \\     ctx: Context,
        \\ ) {
        \\     pub fn count(self: Self) -> i32 {
        \\         return self.ctx.beanNames().length;
        \\     }
        \\ }
        , ["OrderCache", "OrderRepository", "Clock", "ReportService", "NoSuchBean"]);
}
```

`modules/rakun/test/__snapshots__/context/managed-beans-resolve-by-type-and-an-unregistered-type-is-missing.snap`
```
bean Clock scope=singleton deps=[]
bean OrderCache scope=singleton deps=[OrderRepository, Clock]
bean OrderRepository scope=singleton deps=[]
bean ReportService scope=singleton deps=[Context]
resolve OrderCache -> ok
resolve OrderRepository -> ok
resolve Clock -> ok
resolve ReportService -> ok
resolve NoSuchBean -> missing
```

### `context: two provides of one type are told apart by qualifier and primary answers the unqualified lookup`

```bp
test "context: two provides of one type are told apart by qualifier and primary answers the unqualified lookup" {
    try assertContext(@src(),
        \\ import {provides, qualifier, primary};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone};
        \\ import {rkRegisterBean, rkRegisterLifecycle, rkRegisterListener};
        \\
        \\ type Clock(zone: string)
        \\
        \\ #[provides]
        \\ #[qualifier("system")]
        \\ #[primary]
        \\ fn systemClock() -> Clock {
        \\     return Clock(zone: "UTC");
        \\ }
        \\
        \\ #[provides]
        \\ #[qualifier("fixed")]
        \\ fn fixedClock() -> Clock {
        \\     return Clock(zone: "fixed");
        \\ }
        , ["Clock", "Clock@fixed", "Clock@system", "Clock@none"]);
}
```

`modules/rakun/test/__snapshots__/context/two-provides-of-one-type-are-told-apart-by-qualifier-and-primary-answers-the-unqualified-lookup.snap`
```
bean Clock@fixed scope=singleton deps=[]
bean Clock@system scope=singleton deps=[] primary
resolve Clock -> ok
resolve Clock@fixed -> ok
resolve Clock@system -> ok
resolve Clock@none -> missing
```

### `context: scope markers register prototype and request beans`

```bp
test "context: scope markers register prototype and request beans" {
    try assertContext(@src(),
        \\ import {service, managed, scope};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone};
        \\ import {rkRegisterBean, rkRegisterLifecycle, rkRegisterListener};
        \\
        \\ #[service]
        \\ #[managed]
        \\ #[scope("prototype")]
        \\ type IdGenerator {
        \\     pub fn next(self: Self) -> string {
        \\         return "id";
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ #[scope("request")]
        \\ type RequestCounter {
        \\     pub fn tick(self: Self) -> i32 {
        \\         return 1;
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ type Registry {
        \\     pub fn name(self: Self) -> string {
        \\         return "registry";
        \\     }
        \\ }
        , ["IdGenerator", "Registry"]);
}
```

`modules/rakun/test/__snapshots__/context/scope-markers-register-prototype-and-request-beans.snap`
```
bean IdGenerator scope=prototype deps=[]
bean Registry scope=singleton deps=[]
bean RequestCounter scope=request deps=[]
resolve IdGenerator -> ok
resolve Registry -> ok
```

### `events: the boot sequence publishes the eight events in order with post-construct before started`

```bp
test "events: the boot sequence publishes the eight events in order with post-construct before started" {
    try assertLifecycle(@src(),
        \\ import {repository, service, managed, postConstruct, eventListener, Event};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone};
        \\ import {rkRegisterBean, rkRegisterLifecycle, rkRegisterListener};
        \\
        \\ #[repository]
        \\ #[managed]
        \\ type OrderRepository {
        \\     pub fn ids(self: Self) -> Array<string> {
        \\         return ["o-1", "o-2", "o-3"];
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ type OrderCache(
        \\     repo: OrderRepository,
        \\ ) {
        \\     #[postConstruct]
        \\     pub fn warm(self: Self) {
        \\         val n = self.repo.ids().length;
        \\         @print("order cache warmed with ${n} entries");
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ type AuditListener {
        \\     #[eventListener("ApplicationReady")]
        \\     pub fn onReady(self: Self, ev: Event) {
        \\         @print("ready at ${ev.timestampMillis}");
        \\     }
        \\ }
        , ["boot"]);
}
```

`modules/rakun/test/__snapshots__/events/the-boot-sequence-publishes-the-eight-events-in-order-with-post-construct-before-started.snap`
```
boot context ApplicationStarting
boot context ApplicationEnvironmentPrepared
boot context ApplicationContextInitialized
boot context ApplicationPrepared
post OrderCache warm
boot context ApplicationStarted
boot context AvailabilityChanged(LivenessCorrect)
boot context ApplicationReady
event AuditListener onReady(ApplicationReady)
boot context AvailabilityChanged(ReadinessAcceptingTraffic)
```

### `events: a published event reaches every listener in registration order and a raising one does not stop the rest`

```bp
test "events: a published event reaches every listener in registration order and a raising one does not stop the rest" {
    try assertLifecycle(@src(),
        \\ import {service, managed, eventListener, Event};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone};
        \\ import {rkRegisterBean, rkRegisterLifecycle, rkRegisterListener};
        \\
        \\ #[service]
        \\ #[managed]
        \\ type AuditListener {
        \\     #[eventListener("OrderPlaced")]
        \\     pub fn onOrderPlaced(self: Self, ev: Event) {
        \\         @print("audit " + ev.payload);
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ type BrokenListener {
        \\     #[eventListener("OrderPlaced")]
        \\     pub fn onOrderPlaced(self: Self, ev: Event) {
        \\         @panic("audit store offline");
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ type NotifyListener {
        \\     #[eventListener("OrderPlaced")]
        \\     pub fn onOrderPlaced(self: Self, ev: Event) {
        \\         @print("notify " + ev.payload);
        \\     }
        \\
        \\     #[eventListener("OrderCancelled")]
        \\     pub fn onOrderCancelled(self: Self, ev: Event) {
        \\         @print("never published");
        \\     }
        \\ }
        , ["publish OrderPlaced o-9"]);
}
```

`modules/rakun/test/__snapshots__/events/a-published-event-reaches-every-listener-in-registration-order-and-a-raising-one-does-not-stop-the-rest.snap`
```
event AuditListener onOrderPlaced(OrderPlaced)
event BrokenListener onOrderPlaced(OrderPlaced) raised audit store offline
event NotifyListener onOrderPlaced(OrderPlaced)
```

### `events: shutdown runs pre-destroy in reverse registration order and the highest exit code wins`

```bp
test "events: shutdown runs pre-destroy in reverse registration order and the highest exit code wins" {
    try assertLifecycle(@src(),
        \\ import {repository, service, managed, postConstruct, preDestroy, exitCode};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone};
        \\ import {rkRegisterBean, rkRegisterLifecycle, rkRegisterListener};
        \\
        \\ #[repository]
        \\ #[managed]
        \\ type OrderRepository {
        \\     #[postConstruct]
        \\     pub fn open(self: Self) {
        \\         @print("repository open");
        \\     }
        \\
        \\     #[preDestroy]
        \\     pub fn release(self: Self) {
        \\         @print("repository released");
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ type OrderCache(
        \\     repo: OrderRepository,
        \\ ) {
        \\     #[postConstruct]
        \\     pub fn warm(self: Self) {
        \\         @print("cache warmed");
        \\     }
        \\
        \\     #[preDestroy]
        \\     pub fn close(self: Self) {
        \\         @print("cache released");
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ type FlakyExporter {
        \\     #[preDestroy]
        \\     pub fn flush(self: Self) {
        \\         @panic("exporter offline");
        \\     }
        \\ }
        \\
        \\ #[exitCode]
        \\ fn drainExitCode() -> i32 {
        \\     return 0;
        \\ }
        \\
        \\ #[exitCode]
        \\ fn migrationExitCode() -> i32 {
        \\     return 3;
        \\ }
        , ["eagerInit", "terminate"]);
}
```

`modules/rakun/test/__snapshots__/events/shutdown-runs-pre-destroy-in-reverse-registration-order-and-the-highest-exit-code-wins.snap`
```
post OrderRepository open
post OrderCache warm
pre FlakyExporter flush raised exporter offline
pre OrderCache close
pre OrderRepository release
exit drainExitCode 0
exit migrationExitCode 3
stop context status 3
```

### `events: a cyclic graph fails eager initialization and ApplicationFailed replaces the tail`

```bp
test "events: a cyclic graph fails eager initialization and ApplicationFailed replaces the tail" {
    try assertLifecycle(@src(),
        \\ import {service, managed, eventListener, Event};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone};
        \\ import {rkRegisterBean, rkRegisterLifecycle, rkRegisterListener};
        \\
        \\ #[service]
        \\ #[managed]
        \\ type CycleA(
        \\     b: CycleB,
        \\ ) {
        \\     pub fn name(self: Self) -> string {
        \\         return "a";
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ type CycleB(
        \\     a: CycleA,
        \\ ) {
        \\     pub fn name(self: Self) -> string {
        \\         return "b";
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ type AuditListener {
        \\     #[eventListener("ApplicationReady")]
        \\     pub fn onReady(self: Self, ev: Event) {
        \\         @print("never reached");
        \\     }
        \\ }
        , ["boot"]);
}
```

`modules/rakun/test/__snapshots__/events/a-cyclic-graph-fails-eager-initialization-and-applicationfailed-replaces-the-tail.snap`
```
boot context ApplicationStarting
boot context ApplicationEnvironmentPrepared
boot context ApplicationContextInitialized
boot context ApplicationPrepared
fail CycleA rakun_cycle CycleA -> CycleB -> CycleA
boot context ApplicationFailed
```

## 62-rakun-request-context — `rakun`

**Test file:** `modules/rakun/test/request_context_test.bp` · **Snapshots:** `modules/rakun/test/__snapshots__/request/` · **Target:** erlang · **Pins:** Step 2 (`get` case-folds, repeated header joined with `", "`, `headers()` in `Handler` marks dynamic, in `Action` does not), Step 3 (`cookie` header percent-decoded, malformed entries invent nothing, `serializeCookie("s", "a b", cookieDefaults())` literal, `set` in `Render` raises with the action/handler/middleware message, two names → two lines, same name → one line with the later value, `delete` → `Max-Age=0`), Step 4 (`enable()` with `rakun.draft.secret` unset raises naming the property, forged cookie does not raise, `connection()` sets `dynamicReason() == "connection"`, first marker wins, untouched render is static), Step 5 (`after` work is queued and not run before `endRequest`), Step 6 (two `memoize` with one key → loader once, `memoHits() == 1`, `memoMisses() == 1`), Step 7 (front 04's dispatcher begins the frame in phase `Handler`)

> helper gap: `assertRequestContext` block layout is fixed as `phase: <Phase>`, `headers:` (one `  <name>: <value>` per frame header, lowercased, repeated values joined), `cookies:` (one `  <name>=<value>` per parsed request cookie in parse order, then one `  set: <serialized>` per queued `Set-Cookie` in queue order), `memo: hits=<n> misses=<n>`, `after: <n>`; an empty block is its key line alone. Two lines the table does not list: `dynamic: <true|false>[ <reason>]` always, and `raised: <message>` only when the handler raised. The frame is begun by front 04's dispatcher in phase `Handler`; a case that needs another phase calls `setPhase` inside the handler.

### `request: header names fold to lowercase and a repeated header joins with a comma`

```bp
test "request: header names fold to lowercase and a repeated header joins with a comma" {
    try assertRequestContext(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {headers};
        \\
        \\ #[restController]
        \\ #[route("/ctx")]
        \\ type HeaderProbe {
        \\     #[getMapping("/h")]
        \\     pub fn h(self: Self, req: Request) -> Response {
        \\         val agent = headers().get("User-Agent").unwrapOr("-");
        \\         val tags = headers().get("x-tag").unwrapOr("-");
        \\         val absent = headers().get("x-absent").unwrapOr("<null>");
        \\         return Response.ok(agent + "|" + tags + "|" + absent);
        \\     }
        \\ }
        , "GET /ctx/h User-Agent: probe X-Tag: a X-Tag: b");
}
```

`modules/rakun/test/__snapshots__/request/header-names-fold-to-lowercase-and-a-repeated-header-joins-with-a-comma.snap`
```
phase: Handler
headers:
  user-agent: probe
  x-tag: a, b
cookies:
memo: hits=0 misses=0
after: 0
dynamic: true headers
```

### `request: cookies parse percent-decoded and a malformed cookie header invents nothing`

```bp
test "request: cookies parse percent-decoded and a malformed cookie header invents nothing" {
    try assertRequestContext(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {cookies};
        \\
        \\ #[restController]
        \\ #[route("/ctx")]
        \\ type CookieProbe {
        \\     #[getMapping("/c")]
        \\     pub fn c(self: Self, req: Request) -> Response {
        \\         val theme = cookies().get("theme").unwrapOr("-");
        \\         val session = cookies().get("session").unwrapOr("-");
        \\         return Response.ok(theme + "|" + session + "|" + cookies().names().length.toString());
        \\     }
        \\ }
        , "GET /ctx/c Cookie: theme=dark%20mode; junk; =x; ; session = s-1 ;");
}
```

`modules/rakun/test/__snapshots__/request/cookies-parse-percent-decoded-and-a-malformed-cookie-header-invents-nothing.snap`
```
phase: Handler
headers:
  cookie: theme=dark%20mode; junk; =x; ; session = s-1 ;
cookies:
  theme=dark mode
  session=s-1
memo: hits=0 misses=0
after: 0
dynamic: true cookies
```

### `request: a cookie serializes with the restrictive defaults as a literal`

```bp
test "request: a cookie serializes with the restrictive defaults as a literal" {
    try assertRequestContext(@src(),
        \\ import {restController, route, postMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {cookies, cookieDefaults};
        \\
        \\ #[restController]
        \\ #[route("/ctx")]
        \\ type SetCookieProbe {
        \\     #[postMapping("/s")]
        \\     pub fn s(self: Self, req: Request) -> Response {
        \\         val _w = cookies().set("s", "a b", cookieDefaults());
        \\         return Response.ok("set");
        \\     }
        \\ }
        , "POST /ctx/s");
}
```

`modules/rakun/test/__snapshots__/request/a-cookie-serializes-with-the-restrictive-defaults-as-a-literal.snap`
```
phase: Handler
headers:
cookies:
  set: s=a%20b; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax
memo: hits=0 misses=0
after: 0
dynamic: true cookies
```

### `request: two sets for one name queue one line, two names queue two, and delete carries max-age 0`

```bp
test "request: two sets for one name queue one line, two names queue two, and delete carries max-age 0" {
    try assertRequestContext(@src(),
        \\ import {restController, route, postMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {cookies, cookieDefaults, CookieAttrs};
        \\
        \\ #[restController]
        \\ #[route("/ctx")]
        \\ type QueueProbe {
        \\     #[postMapping("/q")]
        \\     pub fn q(self: Self, req: Request) -> Response {
        \\         val year = CookieAttrs(
        \\             path: "/",
        \\             domain: "",
        \\             maxAge: 31536000,
        \\             httpOnly: false,
        \\             secure: true,
        \\             sameSite: "Lax",
        \\         );
        \\         val _t1 = cookies().set("theme", "dark", year);
        \\         val _t2 = cookies().set("theme", "light", year);
        \\         val _l = cookies().set("lang", "pt", cookieDefaults());
        \\         val _d = cookies().delete("session");
        \\         return Response.ok("queued");
        \\     }
        \\ }
        , "POST /ctx/q Cookie: session=s-1");
}
```

`modules/rakun/test/__snapshots__/request/two-sets-for-one-name-queue-one-line-two-names-queue-two-and-delete-carries-max-age-0.snap`
```
phase: Handler
headers:
  cookie: session=s-1
cookies:
  session=s-1
  set: theme=light; Path=/; Max-Age=31536000; Secure; SameSite=Lax
  set: lang=pt; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax
  set: session=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax
memo: hits=0 misses=0
after: 0
dynamic: true cookies
```

### `request: a cookie write during render raises`

```bp
test "request: a cookie write during render raises" {
    try assertRequestContext(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {cookies, cookieDefaults, setPhase, RequestPhase};
        \\
        \\ #[restController]
        \\ #[route("/ctx")]
        \\ type RenderWriteProbe {
        \\     #[getMapping("/r")]
        \\     pub fn r(self: Self, req: Request) -> Response {
        \\         val _p = setPhase(RequestPhase.Render);
        \\         val _w = cookies().set("theme", "dark", cookieDefaults());
        \\         return Response.ok("unreachable");
        \\     }
        \\ }
        , "GET /ctx/r");
}
```

`modules/rakun/test/__snapshots__/request/a-cookie-write-during-render-raises.snap`
```
phase: Render
headers:
cookies:
memo: hits=0 misses=0
after: 0
dynamic: true cookies
raised: cookies().set is not legal in phase Render — a cookie may be set from a server action, a route handler or middleware
```

### `request: the first function to mark dynamic names the reason`

```bp
test "request: the first function to mark dynamic names the reason" {
    try assertRequestContext(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {headers, cookies, connection, setPhase, RequestPhase};
        \\
        \\ #[restController]
        \\ #[route("/ctx")]
        \\ type ReasonProbe {
        \\     #[getMapping("/d")]
        \\     pub fn d(self: Self, req: Request) -> Response {
        \\         val _p = setPhase(RequestPhase.Render);
        \\         val _c = connection();
        \\         val agent = headers().get("user-agent").unwrapOr("-");
        \\         val theme = cookies().get("theme").unwrapOr("-");
        \\         return Response.ok(agent + "|" + theme);
        \\     }
        \\ }
        , "GET /ctx/d User-Agent: probe Cookie: theme=dark");
}
```

`modules/rakun/test/__snapshots__/request/the-first-function-to-mark-dynamic-names-the-reason.snap`
```
phase: Render
headers:
  cookie: theme=dark
  user-agent: probe
cookies:
  theme=dark
memo: hits=0 misses=0
after: 0
dynamic: true connection
```

### `request: reading headers in the action phase does not mark the render dynamic`

```bp
test "request: reading headers in the action phase does not mark the render dynamic" {
    try assertRequestContext(@src(),
        \\ import {restController, route, postMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {headers, setPhase, RequestPhase};
        \\
        \\ #[restController]
        \\ #[route("/ctx")]
        \\ type ActionProbe {
        \\     #[postMapping("/a")]
        \\     pub fn a(self: Self, req: Request) -> Response {
        \\         val _p = setPhase(RequestPhase.Action);
        \\         val agent = headers().get("user-agent").unwrapOr("-");
        \\         return Response.ok(agent);
        \\     }
        \\ }
        , "POST /ctx/a User-Agent: probe");
}
```

`modules/rakun/test/__snapshots__/request/reading-headers-in-the-action-phase-does-not-mark-the-render-dynamic.snap`
```
phase: Action
headers:
  user-agent: probe
cookies:
memo: hits=0 misses=0
after: 0
dynamic: false
```

### `request: memoize runs the loader once per key within a request`

```bp
test "request: memoize runs the loader once per key within a request" {
    try assertRequestContext(@src(),
        \\ import {restController, route, getMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {memoize, memoKey};
        \\
        \\ fn loadPost(slug: string) -> string {
        \\     return "Post " + slug;
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/ctx")]
        \\ type MemoProbe {
        \\     #[getMapping("/m")]
        \\     pub fn m(self: Self, req: Request) -> Response {
        \\         val key = memoKey("getPost", ["hello"]);
        \\         val first = memoize(key, { ->
        \\             loadPost("hello");
        \\         });
        \\         val second = memoize(key, { ->
        \\             loadPost("hello");
        \\         });
        \\         return Response.ok(first + "|" + second);
        \\     }
        \\ }
        , "GET /ctx/m");
}
```

`modules/rakun/test/__snapshots__/request/memoize-runs-the-loader-once-per-key-within-a-request.snap`
```
phase: Handler
headers:
cookies:
memo: hits=1 misses=1
after: 0
dynamic: false
```

### `request: deferred work is queued and has not run when the response is sent`

```bp
test "request: deferred work is queued and has not run when the response is sent" {
    try assertRequestContext(@src(),
        \\ import {restController, route, postMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {after};
        \\
        \\ fn recordView(label: string) -> i32 {
        \\     @print("view " + label);
        \\     return 1;
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/ctx")]
        \\ type AfterProbe {
        \\     #[postMapping("/w")]
        \\     pub fn w(self: Self, req: Request) -> Response {
        \\         val _a = after({ ->
        \\             recordView("first");
        \\         });
        \\         val _b = after({ ->
        \\             recordView("second");
        \\         });
        \\         return Response.ok("queued");
        \\     }
        \\ }
        , "POST /ctx/w");
}
```

`modules/rakun/test/__snapshots__/request/deferred-work-is-queued-and-has-not-run-when-the-response-is-sent.snap`
```
phase: Handler
headers:
cookies:
memo: hits=0 misses=0
after: 2
dynamic: false
```

### `request: draft mode with no secret raises instead of issuing an unsigned cookie`

```bp
test "request: draft mode with no secret raises instead of issuing an unsigned cookie" {
    try assertRequestContext(@src(),
        \\ import {restController, route, postMapping};
        \\ import {Request, Response};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute};
        \\ import {draftMode};
        \\
        \\ #[restController]
        \\ #[route("/ctx")]
        \\ type DraftProbe {
        \\     #[postMapping("/draft")]
        \\     pub fn draft(self: Self, req: Request) -> Response {
        \\         val forged = draftMode().isEnabled();
        \\         val _e = draftMode().enable();
        \\         return Response.ok(if (forged) "enabled" else "disabled");
        \\     }
        \\ }
        , "POST /ctx/draft Cookie: __rakun_draft=abc.forged");
}
```

`modules/rakun/test/__snapshots__/request/draft-mode-with-no-secret-raises-instead-of-issuing-an-unsigned-cookie.snap`
```
phase: Handler
headers:
  cookie: __rakun_draft=abc.forged
cookies:
  __rakun_draft=abc.forged
memo: hits=0 misses=0
after: 0
dynamic: true draftMode
raised: rakun.draft.secret is not set — draft mode cannot issue an unsigned cookie
```

## 72-rakun-auto-configuration — `rakun`

**Test file:** `modules/rakun/test/autoconfig_test.bp` · **Snapshots:** `modules/rakun/test/__snapshots__/autoconfig/` · **Target:** erlang · **Pins:** Step 1 (no conditions → empty blob, always matches; `rkAutoRegister` once per type with `decl.name`), Step 2 (conditions in source order, conjunctive; a bean condition registers against `Type.method`), Step 3 (`autoConfigureAfter` evaluated after its target regardless of load order, `conditionalOnMissingBean` sees the ordered state, a cycle halts naming both), Step 4 (`rakun.autoconfigure.exclude` leaves the configuration and its beans unapplied, excluded conditions are not evaluated, an exclusion matching nothing halts), Step 5 (every configuration in exactly one block, failed row names the record and the value seen, only the first failing condition is reported, stable sorted order), Step 6 (`#[profile("prod")]` on a `#[service]` unbuilt under `dev`, reported with `F|prod` and the active set, no active set → front 05's default profile named)

> helper gap: `assertAutoConfig` `present` entries are `module <name>` (a declared dependency), `property <key>=<value>` (seeded through `rkSetProp` before the apply pass) and `profile <name>` (appended to `rakun.profiles.active`); the helper calls `autoConfigure()` once after seeding. An applied row's `<condition>` is the registered blob verbatim, or `always` for an empty blob; an unapplied row's is `<record> — <value seen>`, `excluded by <channel>`, or `configuration not applied` for a `#[bean]` method whose configuration did not apply.
> helper gap: `assertBoot` renders `listen none` when no listener binds (as declared under 04); the two halting cases below use it.

### `autoconfig: all conditions hold and the module default bean is applied`

```bp
test "autoconfig: all conditions hold and the module default bean is applied" {
    try assertAutoConfig(@src(),
        \\ import {autoConfiguration, conditionalOnModule, conditionalOnProperty, conditionalOnMissingBean};
        \\ import {bean, value};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt};
        \\ import {rkAutoRegister, rkAutoMatched};
        \\
        \\ type MailSender(
        \\     host: string,
        \\     port: i32,
        \\ )
        \\
        \\ #[autoConfiguration]
        \\ #[conditionalOnModule("rakun-mail")]
        \\ #[conditionalOnProperty("rakun.mail.host", "*")]
        \\ type RakunMailAutoConfiguration(
        \\     #[value("rakun.mail.host")] host: string,
        \\     #[value("rakun.mail.port")] port: i32,
        \\ ) {
        \\     #[bean]
        \\     #[conditionalOnMissingBean("MailSender")]
        \\     pub fn mailSender(self: Self) -> MailSender {
        \\         return MailSender(host: self.host, port: self.port);
        \\     }
        \\ }
        , ["module rakun-mail", "property rakun.mail.host=smtp.example.org", "property rakun.mail.port=587"]);
}
```

`modules/rakun/test/__snapshots__/autoconfig/all-conditions-hold-and-the-module-default-bean-is-applied.snap`
```
+ RakunMailAutoConfiguration  M|rakun-mail;P|rakun.mail.host|*
+ RakunMailAutoConfiguration.mailSender  X|MailSender
```

### `autoconfig: an empty property is the first failure and names the value seen`

```bp
test "autoconfig: an empty property is the first failure and names the value seen" {
    try assertAutoConfig(@src(),
        \\ import {autoConfiguration, conditionalOnModule, conditionalOnProperty, conditionalOnMissingBean};
        \\ import {bean, value};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt};
        \\ import {rkAutoRegister, rkAutoMatched};
        \\
        \\ type MailSender(
        \\     host: string,
        \\     port: i32,
        \\ )
        \\
        \\ #[autoConfiguration]
        \\ #[conditionalOnModule("rakun-mail")]
        \\ #[conditionalOnProperty("rakun.mail.host", "*")]
        \\ type RakunMailAutoConfiguration(
        \\     #[value("rakun.mail.host")] host: string,
        \\     #[value("rakun.mail.port")] port: i32,
        \\ ) {
        \\     #[bean]
        \\     #[conditionalOnMissingBean("MailSender")]
        \\     pub fn mailSender(self: Self) -> MailSender {
        \\         return MailSender(host: self.host, port: self.port);
        \\     }
        \\ }
        , ["module rakun-mail", "property rakun.mail.host="]);
}
```

`modules/rakun/test/__snapshots__/autoconfig/an-empty-property-is-the-first-failure-and-names-the-value-seen.snap`
```
- RakunMailAutoConfiguration  P|rakun.mail.host|* — property is empty
- RakunMailAutoConfiguration.mailSender  configuration not applied
```

### `autoconfig: a missing module short-circuits before the property is read`

```bp
test "autoconfig: a missing module short-circuits before the property is read" {
    try assertAutoConfig(@src(),
        \\ import {autoConfiguration, conditionalOnModule, conditionalOnProperty, conditionalOnMissingBean};
        \\ import {bean, value};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt};
        \\ import {rkAutoRegister, rkAutoMatched};
        \\
        \\ type MailSender(
        \\     host: string,
        \\     port: i32,
        \\ )
        \\
        \\ #[autoConfiguration]
        \\ #[conditionalOnModule("rakun-mail")]
        \\ #[conditionalOnProperty("rakun.mail.host", "*")]
        \\ type RakunMailAutoConfiguration(
        \\     #[value("rakun.mail.host")] host: string,
        \\     #[value("rakun.mail.port")] port: i32,
        \\ ) {
        \\     #[bean]
        \\     #[conditionalOnMissingBean("MailSender")]
        \\     pub fn mailSender(self: Self) -> MailSender {
        \\         return MailSender(host: self.host, port: self.port);
        \\     }
        \\ }
        , ["property rakun.mail.host=smtp.example.org"]);
}
```

`modules/rakun/test/__snapshots__/autoconfig/a-missing-module-short-circuits-before-the-property-is-read.snap`
```
- RakunMailAutoConfiguration  M|rakun-mail — declared modules: none
- RakunMailAutoConfiguration.mailSender  configuration not applied
```

### `autoconfig: the application's own bean leaves the module default unapplied`

```bp
test "autoconfig: the application's own bean leaves the module default unapplied" {
    try assertAutoConfig(@src(),
        \\ import {autoConfiguration, conditionalOnModule, conditionalOnProperty, conditionalOnMissingBean};
        \\ import {configuration, bean, value};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt};
        \\ import {rkAutoRegister, rkAutoMatched};
        \\
        \\ type MailSender(
        \\     host: string,
        \\     port: i32,
        \\ )
        \\
        \\ #[autoConfiguration]
        \\ #[conditionalOnModule("rakun-mail")]
        \\ #[conditionalOnProperty("rakun.mail.host", "*")]
        \\ type RakunMailAutoConfiguration(
        \\     #[value("rakun.mail.host")] host: string,
        \\     #[value("rakun.mail.port")] port: i32,
        \\ ) {
        \\     #[bean]
        \\     #[conditionalOnMissingBean("MailSender")]
        \\     pub fn mailSender(self: Self) -> MailSender {
        \\         return MailSender(host: self.host, port: self.port);
        \\     }
        \\ }
        \\
        \\ #[configuration]
        \\ type MyMailConfig(
        \\     #[value("app.smtp.host")] host: string,
        \\ ) {
        \\     #[bean]
        \\     pub fn mailSender(self: Self) -> MailSender {
        \\         return MailSender(host: self.host, port: 2525);
        \\     }
        \\ }
        , ["module rakun-mail", "property rakun.mail.host=smtp.example.org", "property app.smtp.host=smtp.internal"]);
}
```

`modules/rakun/test/__snapshots__/autoconfig/the-application-s-own-bean-leaves-the-module-default-unapplied.snap`
```
+ RakunMailAutoConfiguration  M|rakun-mail;P|rakun.mail.host|*
- RakunMailAutoConfiguration.mailSender  X|MailSender — bean MailSender is registered by MyMailConfig.mailSender
```

### `autoconfig: after-ordering decides what conditionalOnMissingBean sees`

```bp
test "autoconfig: after-ordering decides what conditionalOnMissingBean sees" {
    try assertAutoConfig(@src(),
        \\ import {autoConfiguration, conditionalOnMissingBean, autoConfigureAfter};
        \\ import {bean};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt};
        \\ import {rkAutoRegister, rkAutoMatched};
        \\
        \\ type DataSource(url: string)
        \\
        \\ #[autoConfiguration]
        \\ #[autoConfigureAfter("AppDataAutoConfiguration")]
        \\ type FallbackDataAutoConfiguration {
        \\     #[bean]
        \\     #[conditionalOnMissingBean("DataSource")]
        \\     pub fn dataSource(self: Self) -> DataSource {
        \\         return DataSource(url: "mem://fallback");
        \\     }
        \\ }
        \\
        \\ #[autoConfiguration]
        \\ type AppDataAutoConfiguration {
        \\     #[bean]
        \\     pub fn dataSource(self: Self) -> DataSource {
        \\         return DataSource(url: "postgres://app");
        \\     }
        \\ }
        , []);
}
```

`modules/rakun/test/__snapshots__/autoconfig/after-ordering-decides-what-conditionalonmissingbean-sees.snap`
```
+ AppDataAutoConfiguration  always
+ AppDataAutoConfiguration.dataSource  always
+ FallbackDataAutoConfiguration  always
- FallbackDataAutoConfiguration.dataSource  X|DataSource — bean DataSource is registered by AppDataAutoConfiguration.dataSource
```

### `autoconfig: exclusion by property skips evaluation and the beans`

```bp
test "autoconfig: exclusion by property skips evaluation and the beans" {
    try assertAutoConfig(@src(),
        \\ import {autoConfiguration, conditionalOnModule, conditionalOnProperty, conditionalOnMissingBean};
        \\ import {bean, value};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt};
        \\ import {rkAutoRegister, rkAutoMatched};
        \\
        \\ type MailSender(
        \\     host: string,
        \\     port: i32,
        \\ )
        \\
        \\ #[autoConfiguration]
        \\ #[conditionalOnModule("rakun-mail")]
        \\ #[conditionalOnProperty("rakun.mail.host", "*")]
        \\ type RakunMailAutoConfiguration(
        \\     #[value("rakun.mail.host")] host: string,
        \\     #[value("rakun.mail.port")] port: i32,
        \\ ) {
        \\     #[bean]
        \\     #[conditionalOnMissingBean("MailSender")]
        \\     pub fn mailSender(self: Self) -> MailSender {
        \\         return MailSender(host: self.host, port: self.port);
        \\     }
        \\ }
        , ["module rakun-mail", "property rakun.mail.host=smtp.example.org", "property rakun.autoconfigure.exclude=RakunMailAutoConfiguration"]);
}
```

`modules/rakun/test/__snapshots__/autoconfig/exclusion-by-property-skips-evaluation-and-the-beans.snap`
```
- RakunMailAutoConfiguration  excluded by rakun.autoconfigure.exclude
- RakunMailAutoConfiguration.mailSender  configuration not applied
```

### `autoconfig: an exclusion naming nothing registered halts the boot`

```bp
test "autoconfig: an exclusion naming nothing registered halts the boot" {
    try assertBoot(@src(),
        \\ import {autoConfiguration, conditionalOnModule, autoConfigure};
        \\ import {bean};
        \\ import {Rakun, App};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt};
        \\ import {rkAutoRegister, rkAutoMatched};
        \\
        \\ type MailSender(
        \\     host: string,
        \\     port: i32,
        \\ )
        \\
        \\ #[autoConfiguration]
        \\ #[conditionalOnModule("rakun-mail")]
        \\ type RakunMailAutoConfiguration {
        \\     #[bean]
        \\     pub fn mailSender(self: Self) -> MailSender {
        \\         return MailSender(host: "localhost", port: 1025);
        \\     }
        \\ }
        \\
        \\ fn main() {
        \\     val _ = autoConfigure();
        \\     Rakun.run(App(port: 8080, basePath: "/api"));
        \\ }
        , ["--rakun.autoconfigure.exclude=Nonexistent"]);
}
```

`modules/rakun/test/__snapshots__/autoconfig/an-exclusion-naming-nothing-registered-halts-the-boot.snap`
```
listen none
beans 1
routes 0
exit 1
```

### `autoconfig: an ordering cycle halts the boot`

```bp
test "autoconfig: an ordering cycle halts the boot" {
    try assertBoot(@src(),
        \\ import {autoConfiguration, autoConfigureAfter, autoConfigure};
        \\ import {bean};
        \\ import {Rakun, App};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt};
        \\ import {rkAutoRegister, rkAutoMatched};
        \\
        \\ type Marker(name: string)
        \\
        \\ #[autoConfiguration]
        \\ #[autoConfigureAfter("SecondAutoConfiguration")]
        \\ type FirstAutoConfiguration {
        \\     #[bean]
        \\     pub fn first(self: Self) -> Marker {
        \\         return Marker(name: "first");
        \\     }
        \\ }
        \\
        \\ #[autoConfiguration]
        \\ #[autoConfigureAfter("FirstAutoConfiguration")]
        \\ type SecondAutoConfiguration {
        \\     #[bean]
        \\     pub fn second(self: Self) -> Marker {
        \\         return Marker(name: "second");
        \\     }
        \\ }
        \\
        \\ fn main() {
        \\     val _ = autoConfigure();
        \\     Rakun.run(App(port: 8080, basePath: "/api"));
        \\ }
        , []);
}
```

`modules/rakun/test/__snapshots__/autoconfig/an-ordering-cycle-halts-the-boot.snap`
```
listen none
beans 2
routes 0
exit 1
```

### `autoconfig: a profile-gated service is not applied under another active profile`

```bp
test "autoconfig: a profile-gated service is not applied under another active profile" {
    try assertAutoConfig(@src(),
        \\ import {service, profile};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt};
        \\ import {rkAutoRegister, rkAutoMatched};
        \\
        \\ #[service]
        \\ #[profile("prod")]
        \\ type MailAuditService {
        \\     pub fn auditLine(self: Self, to: string) -> string {
        \\         return "audit " + to;
        \\     }
        \\ }
        , ["profile dev"]);
}
```

`modules/rakun/test/__snapshots__/autoconfig/a-profile-gated-service-is-not-applied-under-another-active-profile.snap`
```
- MailAuditService  F|prod — active profiles: dev
```

### `autoconfig: a profile-gated service with no active profile is judged against the default`

```bp
test "autoconfig: a profile-gated service with no active profile is judged against the default" {
    try assertAutoConfig(@src(),
        \\ import {service, profile};
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt};
        \\ import {rkAutoRegister, rkAutoMatched};
        \\
        \\ #[service]
        \\ #[profile("prod")]
        \\ type MailAuditService {
        \\     pub fn auditLine(self: Self, to: string) -> string {
        \\         return "audit " + to;
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[profile("default")]
        \\ type LocalMailService {
        \\     pub fn describe(self: Self) -> string {
        \\         return "local";
        \\     }
        \\ }
        , []);
}
```

`modules/rakun/test/__snapshots__/autoconfig/a-profile-gated-service-with-no-active-profile-is-judged-against-the-default.snap`
```
+ LocalMailService  F|default
- MailAuditService  F|prod — active profiles: default
```

## 74-rakun-tls-ssl-bundles — `rakun`

**Test file:** `modules/rakun/test/ssl_bundle_test.bp` · **Snapshots:** `modules/rakun/test/__snapshots__/ssl/` · **Target:** erlang · **Pins:** Step 1 (two bundles resolve independently and one failing does not block the other, a missing file names the bundle, the property and the path, mismatched key and certificate fail at resolve naming the bundle, a half-configured keystore names the missing half, JKS refused naming `keytool -importkeystore -deststoretype PKCS12`, `sslBundle("absent")` is empty), Step 2 (no bundle → `gen_tcp`; `protocols=tlsv1.2` refuses a TLS 1.3-only client), Step 3 (`client-auth` `none`/`want`/`need` accept and reject per the table), Step 4 (`verify=full` refuses a hostname mismatch, `verify=none` connects, trust-store-only bundle is valid), Step 5 (a mismatched reload keeps the old material and returns false, `rkSslLastError` names the reason and is `""` after success), defaults (`protocols=[tlsv1.3, tlsv1.2]`, `ciphers=[]`)

> helper gap: `assertSslBundle` config values of the form `selftest:<file>` resolve into the directory `rakun_ssl:selftest_material/1` fills (`ca.pem`, `server.pem` for `inventory.internal`, `server-key.pem`, `client.pem`, `client-key.pem`, `untrusted-client.pem`, `mismatched-key.pem`); bundle lines render in property order. Probe verbs: `resolve <bundle>`, `listener <bundle>`, `handshake <bundle> <tlsv1.x|none|<client cert file>>` (a client against the bundle's listener), `client <bundle> <host>` (the bundle as a client against the selftest server), `rotate <bundle> <keystore half> selftest:<file>`, `reload <bundle>`, `lasterror <bundle>` (`ok` when `""`).

### `ssl: a pem bundle resolves with the default protocols and an absent name is an error`

```bp
test "ssl: a pem bundle resolves with the default protocols and an absent name is an error" {
    try assertSslBundle(@src(), [
        "rakun.ssl.bundle.pem.public.keystore.certificate=selftest:server.pem",
        "rakun.ssl.bundle.pem.public.keystore.private-key=selftest:server-key.pem",
        "rakun.server.ssl.bundle=public",
    ], ["resolve public", "listener public", "resolve absent"]);
}
```

`modules/rakun/test/__snapshots__/ssl/a-pem-bundle-resolves-with-the-default-protocols-and-an-absent-name-is-an-error.snap`
```
bundle public kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
probe resolve public -> ok
probe listener public -> ok
probe resolve absent -> err no bundle named absent
```

### `ssl: bundles resolve independently and each failure names the bundle and the missing half`

```bp
test "ssl: bundles resolve independently and each failure names the bundle and the missing half" {
    try assertSslBundle(@src(), [
        "rakun.ssl.bundle.pem.public.keystore.certificate=selftest:server.pem",
        "rakun.ssl.bundle.pem.public.keystore.private-key=selftest:server-key.pem",
        "rakun.ssl.bundle.pem.broken.keystore.certificate=selftest:server.pem",
        "rakun.ssl.bundle.pem.broken.keystore.private-key=selftest:mismatched-key.pem",
        "rakun.ssl.bundle.pem.gone.keystore.certificate=/etc/rakun/tls/nope.pem",
        "rakun.ssl.bundle.pem.gone.keystore.private-key=selftest:server-key.pem",
        "rakun.ssl.bundle.pem.halfway.keystore.certificate=selftest:server.pem",
    ], ["resolve public", "resolve broken", "resolve gone", "resolve halfway"]);
}
```

`modules/rakun/test/__snapshots__/ssl/bundles-resolve-independently-and-each-failure-names-the-bundle-and-the-missing-half.snap`
```
bundle public kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
bundle broken kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
bundle gone kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
bundle halfway kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
probe resolve public -> ok
probe resolve broken -> err bundle broken: certificate and private key do not correspond
probe resolve gone -> err bundle gone: rakun.ssl.bundle.pem.gone.keystore.certificate names /etc/rakun/tls/nope.pem, which does not exist
probe resolve halfway -> err bundle halfway: keystore.certificate is set and keystore.private-key is not
```

### `ssl: a jks keystore is refused with the keytool conversion`

```bp
test "ssl: a jks keystore is refused with the keytool conversion" {
    try assertSslBundle(@src(), [
        "rakun.ssl.bundle.jks.legacy.keystore.location=/etc/rakun/tls/legacy.jks",
        "rakun.ssl.bundle.jks.legacy.keystore.password=changeit",
    ], ["resolve legacy"]);
}
```

`modules/rakun/test/__snapshots__/ssl/a-jks-keystore-is-refused-with-the-keytool-conversion.snap`
```
bundle legacy kind=jks protocols=[tlsv1.3, tlsv1.2] ciphers=[]
probe resolve legacy -> err bundle legacy: JKS is not accepted; convert /etc/rakun/tls/legacy.jks with keytool -importkeystore -deststoretype PKCS12
```

### `ssl: protocols and ciphers come from the bundle and tlsv1.2 only refuses a tls 1.3 client`

```bp
test "ssl: protocols and ciphers come from the bundle and tlsv1.2 only refuses a tls 1.3 client" {
    try assertSslBundle(@src(), [
        "rakun.ssl.bundle.pem.legacy12.keystore.certificate=selftest:server.pem",
        "rakun.ssl.bundle.pem.legacy12.keystore.private-key=selftest:server-key.pem",
        "rakun.ssl.bundle.pem.legacy12.protocols=tlsv1.2",
        "rakun.ssl.bundle.pem.legacy12.ciphers=ECDHE-RSA-AES256-GCM-SHA384,ECDHE-RSA-AES128-GCM-SHA256",
    ], ["handshake legacy12 tlsv1.3", "handshake legacy12 tlsv1.2"]);
}
```

`modules/rakun/test/__snapshots__/ssl/protocols-and-ciphers-come-from-the-bundle-and-tlsv1-2-only-refuses-a-tls-1-3-client.snap`
```
bundle legacy12 kind=pem protocols=[tlsv1.2] ciphers=[ECDHE-RSA-AES256-GCM-SHA384, ECDHE-RSA-AES128-GCM-SHA256]
probe handshake legacy12 tlsv1.3 -> err protocol version
probe handshake legacy12 tlsv1.2 -> ok
```

### `ssl: the three client-auth postures accept and reject the right peers`

```bp
test "ssl: the three client-auth postures accept and reject the right peers" {
    try assertSslBundle(@src(), [
        "rakun.ssl.bundle.pem.open.keystore.certificate=selftest:server.pem",
        "rakun.ssl.bundle.pem.open.keystore.private-key=selftest:server-key.pem",
        "rakun.ssl.bundle.pem.open.truststore.certificate=selftest:ca.pem",
        "rakun.ssl.bundle.pem.open.client-auth=none",
        "rakun.ssl.bundle.pem.want.keystore.certificate=selftest:server.pem",
        "rakun.ssl.bundle.pem.want.keystore.private-key=selftest:server-key.pem",
        "rakun.ssl.bundle.pem.want.truststore.certificate=selftest:ca.pem",
        "rakun.ssl.bundle.pem.want.client-auth=want",
        "rakun.ssl.bundle.pem.need.keystore.certificate=selftest:server.pem",
        "rakun.ssl.bundle.pem.need.keystore.private-key=selftest:server-key.pem",
        "rakun.ssl.bundle.pem.need.truststore.certificate=selftest:ca.pem",
        "rakun.ssl.bundle.pem.need.client-auth=need",
    ], [
        "handshake open none",
        "handshake open untrusted-client.pem",
        "handshake want none",
        "handshake want client.pem",
        "handshake want untrusted-client.pem",
        "handshake need none",
        "handshake need client.pem",
    ]);
}
```

`modules/rakun/test/__snapshots__/ssl/the-three-client-auth-postures-accept-and-reject-the-right-peers.snap`
```
bundle open kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
bundle want kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
bundle need kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
probe handshake open none -> ok
probe handshake open untrusted-client.pem -> ok
probe handshake want none -> ok
probe handshake want client.pem -> ok
probe handshake want untrusted-client.pem -> err unknown ca
probe handshake need none -> err certificate required
probe handshake need client.pem -> ok
```

### `ssl: verify full refuses a hostname mismatch and a trust-store-only bundle connects`

```bp
test "ssl: verify full refuses a hostname mismatch and a trust-store-only bundle connects" {
    try assertSslBundle(@src(), [
        "rakun.ssl.bundle.pem.internal.keystore.certificate=selftest:client.pem",
        "rakun.ssl.bundle.pem.internal.keystore.private-key=selftest:client-key.pem",
        "rakun.ssl.bundle.pem.internal.truststore.certificate=selftest:ca.pem",
        "rakun.ssl.bundle.pem.internal.verify=full",
        "rakun.ssl.bundle.pem.trustonly.truststore.certificate=selftest:ca.pem",
        "rakun.ssl.bundle.pem.trustonly.verify=full",
        "rakun.ssl.bundle.pem.lax.truststore.certificate=selftest:ca.pem",
        "rakun.ssl.bundle.pem.lax.verify=none",
    ], [
        "client internal inventory.internal",
        "client internal wrong.host",
        "client trustonly inventory.internal",
        "client lax wrong.host",
    ]);
}
```

`modules/rakun/test/__snapshots__/ssl/verify-full-refuses-a-hostname-mismatch-and-a-trust-store-only-bundle-connects.snap`
```
bundle internal kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
bundle trustonly kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
bundle lax kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
probe client internal inventory.internal -> ok
probe client internal wrong.host -> err hostname check failed
probe client trustonly inventory.internal -> ok
probe client lax wrong.host -> ok
```

### `ssl: a failed reload keeps the previous material and records the error`

```bp
test "ssl: a failed reload keeps the previous material and records the error" {
    try assertSslBundle(@src(), [
        "rakun.ssl.bundle.pem.public.keystore.certificate=selftest:server.pem",
        "rakun.ssl.bundle.pem.public.keystore.private-key=selftest:server-key.pem",
    ], [
        "reload public",
        "lasterror public",
        "rotate public private-key selftest:mismatched-key.pem",
        "reload public",
        "lasterror public",
        "resolve public",
        "listener public",
    ]);
}
```

`modules/rakun/test/__snapshots__/ssl/a-failed-reload-keeps-the-previous-material-and-records-the-error.snap`
```
bundle public kind=pem protocols=[tlsv1.3, tlsv1.2] ciphers=[]
probe reload public -> ok
probe lasterror public -> ok
probe rotate public private-key selftest:mismatched-key.pem -> ok
probe reload public -> err certificate and private key do not correspond
probe lasterror public -> err certificate and private key do not correspond
probe resolve public -> ok
probe listener public -> ok
```

## 22-rakun-file-routing — `rakun-app`

**Test file:** `modules/rakun-app/test/file_router_test.bp` · **Snapshots:** `modules/rakun-app/test/__snapshots__/route/` · **Target:** both — boundary (the matcher runs on BEAM and, rebuilt from payload `t`, in the browser; one snapshot, two runs) · **Pins:** Step 1 group/slot/private classification, Step 2 `#[layout("")]` root, Step 3 registration order, Step 4 static-over-dynamic precedence + catch-all refuses zero + optional catch-all zero/many + layout-only pattern not public + `layoutChain` root-first, Step 5 `_` dir skipped, `N` kind letter

> helper gap: `assertRouteTree` renders no verb column, so the `R` row's verb is pinned in 25's `handler` suite; the table letters are `P|L|R|N` only, so `template.bp`/`default.bp` (`T`/`D`) trees are pinned in 23 (`ssr`) and 61 (`slots`).

### `route: a static page under the root layout`

```bp
test "route: a static page under the root layout" {
    try assertRouteTree(@src(),
        ["app/layout.bp", "app/page.bp", "app/about/page.bp"],
        ["/", "/about", "/missing"]);
}
```

`modules/rakun-app/test/__snapshots__/route/a-static-page-under-the-root-layout.snap`
```
L / layouts=[/] kind=static
P / layouts=[/] kind=static
P /about layouts=[/] kind=static

/ -> / {}
/about -> /about {}
/missing -> 404
```

### `route: a dynamic segment binds its param`

```bp
test "route: a dynamic segment binds its param" {
    try assertRouteTree(@src(),
        ["app/layout.bp", "app/blog/layout.bp", "app/blog/[slug]/page.bp"],
        ["/blog/hello", "/blog", "/blog/hello/extra"]);
}
```

`modules/rakun-app/test/__snapshots__/route/a-dynamic-segment-binds-its-param.snap`
```
L / layouts=[/] kind=static
L /blog layouts=[/,/blog] kind=static
P /blog/[slug] layouts=[/,/blog] kind=dynamic

/blog/hello -> /blog/[slug] {slug=hello}
/blog -> 404
/blog/hello/extra -> 404
```

### `route: a static sibling beats a dynamic segment`

```bp
test "route: a static sibling beats a dynamic segment" {
    try assertRouteTree(@src(),
        ["app/layout.bp", "app/blog/[slug]/page.bp", "app/blog/new/page.bp"],
        ["/blog/new", "/blog/old"]);
}
```

`modules/rakun-app/test/__snapshots__/route/a-static-sibling-beats-a-dynamic-segment.snap`
```
L / layouts=[/] kind=static
P /blog/[slug] layouts=[/] kind=dynamic
P /blog/new layouts=[/] kind=static

/blog/new -> /blog/new {}
/blog/old -> /blog/[slug] {slug=old}
```

### `route: a catch-all captures one or more segments and refuses zero`

```bp
test "route: a catch-all captures one or more segments and refuses zero" {
    try assertRouteTree(@src(),
        ["app/layout.bp", "app/shop/[...slug]/page.bp"],
        ["/shop/clothing/shirts", "/shop/a", "/shop"]);
}
```

`modules/rakun-app/test/__snapshots__/route/a-catch-all-captures-one-or-more-segments-and-refuses-zero.snap`
```
L / layouts=[/] kind=static
P /shop/[...slug] layouts=[/] kind=catch-all

/shop/clothing/shirts -> /shop/[...slug] {slug=clothing/shirts}
/shop/a -> /shop/[...slug] {slug=a}
/shop -> 404
```

### `route: an optional catch-all matches zero segments as well`

```bp
test "route: an optional catch-all matches zero segments as well" {
    try assertRouteTree(@src(),
        ["app/layout.bp", "app/docs/[[...slug]]/page.bp"],
        ["/docs", "/docs/routing/dynamic"]);
}
```

`modules/rakun-app/test/__snapshots__/route/an-optional-catch-all-matches-zero-segments-as-well.snap`
```
L / layouts=[/] kind=static
P /docs/[[...slug]] layouts=[/] kind=optional

/docs -> /docs/[[...slug]] {}
/docs/routing/dynamic -> /docs/[[...slug]] {slug=routing/dynamic}
```

### `route: a group contributes no url segment`

```bp
test "route: a group contributes no url segment" {
    try assertRouteTree(@src(),
        ["app/layout.bp", "app/(marketing)/about/page.bp"],
        ["/about", "/marketing/about", "/(marketing)/about"]);
}
```

`modules/rakun-app/test/__snapshots__/route/a-group-contributes-no-url-segment.snap`
```
L / layouts=[/] kind=static
P /about layouts=[/] kind=static

/about -> /about {}
/marketing/about -> 404
/(marketing)/about -> 404
```

### `route: a layout without a page is not public`

```bp
test "route: a layout without a page is not public" {
    try assertRouteTree(@src(),
        ["app/layout.bp", "app/settings/layout.bp", "app/settings/profile/page.bp"],
        ["/settings", "/settings/profile"]);
}
```

`modules/rakun-app/test/__snapshots__/route/a-layout-without-a-page-is-not-public.snap`
```
L / layouts=[/] kind=static
L /settings layouts=[/,/settings] kind=static
P /settings/profile layouts=[/,/settings] kind=static

/settings -> 404
/settings/profile -> /settings/profile {}
```

### `route: a route handler claims its url as an r entry`

```bp
test "route: a route handler claims its url as an r entry" {
    try assertRouteTree(@src(),
        ["app/layout.bp", "app/page.bp", "app/api/posts/route.bp", "app/api/posts/[id]/route.bp"],
        ["/api/posts", "/api/posts/7", "/api"]);
}
```

`modules/rakun-app/test/__snapshots__/route/a-route-handler-claims-its-url-as-an-r-entry.snap`
```
L / layouts=[/] kind=static
P / layouts=[/] kind=static
R /api/posts layouts=[/] kind=static
R /api/posts/[id] layouts=[/] kind=dynamic

/api/posts -> /api/posts {}
/api/posts/7 -> /api/posts/[id] {id=7}
/api -> 404
```

### `route: a private folder is skipped even when it holds a page`

```bp
test "route: a private folder is skipped even when it holds a page" {
    try assertRouteTree(@src(),
        ["app/layout.bp", "app/blog/page.bp", "app/blog/_drafts/page.bp", "app/blog/_drafts/[slug]/page.bp"],
        ["/blog", "/blog/_drafts", "/blog/drafts", "/blog/_drafts/x"]);
}
```

`modules/rakun-app/test/__snapshots__/route/a-private-folder-is-skipped-even-when-it-holds-a-page.snap`
```
L / layouts=[/] kind=static
P /blog layouts=[/] kind=static

/blog -> /blog {}
/blog/_drafts -> 404
/blog/drafts -> 404
/blog/_drafts/x -> 404
```

### `route: a not-found file registers an n entry under its layouts`

```bp
test "route: a not-found file registers an n entry under its layouts" {
    try assertRouteTree(@src(),
        ["app/layout.bp", "app/not-found.bp", "app/blog/layout.bp", "app/blog/not-found.bp", "app/blog/[slug]/page.bp"],
        ["/blog/hello", "/blog/hello/x"]);
}
```

`modules/rakun-app/test/__snapshots__/route/a-not-found-file-registers-an-n-entry-under-its-layouts.snap`
```
L / layouts=[/] kind=static
N / layouts=[/] kind=static
L /blog layouts=[/,/blog] kind=static
N /blog layouts=[/,/blog] kind=static
P /blog/[slug] layouts=[/,/blog] kind=dynamic

/blog/hello -> /blog/[slug] {slug=hello}
/blog/hello/x -> 404
```

## 23-rakun-ssr-pipeline — `rakun-app`

**Test file:** `modules/rakun-app/test/ssr_test.bp` · **Snapshots:** `modules/rakun-app/test/__snapshots__/ssr/` · **Target:** both — boundary (render, escaping and document are erlang; the payload block is what the commonJS row parses and re-serialises against the same file) · **Pins:** Step 1 `Content-Type: text/html; charset=utf-8` on every page, Step 2 six-convention nesting + root outermost/page innermost + no empty wrapper without `template.bp` + `data-onze-t="<pattern>#<nav>"` + `selected` depth 0/1/2, Step 3 text and attribute escaping, Step 4 `v` first = `1` + `t` verbatim + payload escaping leaves no `<`, Step 6 404 renders the nearest `not-found` boundary

> helper gap: `assertSsr` takes a tree, not a source, so the convention files render as the helper's stubs: layout → `<div data-onze-seg="<pattern>"><span>layout <depth></span>…</div>`, template → `<div data-onze-t="<pattern>#<nav>">…</div>` (`nav` = 1 in a fresh scratch context), error → `<div data-onze-e="<pattern>">…</div>`, loading → `<div data-onze-h="h1">…</div>` (resolved before the shell flush, so `h` stays `[]`), not-found → `<div data-onze-n="<pattern>">…</div>` as a boundary and `<span>not-found <pattern></span>` as the 404 body, page → `<main>page <pattern>[ <params qs>]</main>`. The payload block renders `key: <json value>` in the key order of § *The payload*; the `__onze` script's JSON is elided as `{…}` in the html block because the payload block is where it is rendered. Build id from the test seed is `build-0001`. `d: true` (route.query / cookies()) needs a source and is pinned in 60's `static` suite; the streaming chunk protocol (`renderStreaming`, `h`, fills) has no helper.

### `ssr: a static page renders inside the root layout`

```bp
test "ssr: a static page renders inside the root layout" {
    try assertSsr(@src(),
        ["app/layout.bp", "app/page.bp"],
        "GET /");
}
```

`modules/rakun-app/test/__snapshots__/ssr/a-static-page-renders-inside-the-root-layout.snap`
```
status 200
content-type: text/html; charset=utf-8
html:
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><style></style></head><body><div data-onze-root=""><div data-onze-seg="/"><span>layout 0</span><main>page /</main></div></div><script id="__onze" type="application/json">{…}</script><script src="/_onze/client-build-0001.js" defer></script></body></html>
payload:
v: 1
b: "build-0001"
p: "/"
r: "/"
m: ""
q: ""
t: "L|/||\nP|/||"
i: []
a: []
s: ""
h: []
d: false
k: ""
z: ""
```

### `ssr: layouts nest root-first and the page is innermost`

```bp
test "ssr: layouts nest root-first and the page is innermost" {
    try assertSsr(@src(),
        ["app/layout.bp", "app/blog/layout.bp", "app/blog/[slug]/page.bp"],
        "GET /blog/hello");
}
```

`modules/rakun-app/test/__snapshots__/ssr/layouts-nest-root-first-and-the-page-is-innermost.snap`
```
status 200
content-type: text/html; charset=utf-8
html:
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><style></style></head><body><div data-onze-root=""><div data-onze-seg="/"><span>layout 0</span><div data-onze-seg="/blog"><span>layout 1</span><main>page /blog/[slug] slug=hello</main></div></div></div><script id="__onze" type="application/json">{…}</script><script src="/_onze/client-build-0001.js" defer></script></body></html>
payload:
v: 1
b: "build-0001"
p: "/blog/hello"
r: "/blog/[slug]"
m: "slug=hello"
q: ""
t: "L|/||\nL|/blog||\nP|/blog/[slug]||"
i: []
a: []
s: ""
h: []
d: false
k: ""
z: ""
```

### `ssr: one segment holding all six conventions nests layout template error loading not-found page`

```bp
test "ssr: one segment holding all six conventions nests layout template error loading not-found page" {
    try assertSsr(@src(),
        ["app/layout.bp", "app/template.bp", "app/error.bp", "app/loading.bp", "app/not-found.bp", "app/page.bp"],
        "GET /");
}
```

`modules/rakun-app/test/__snapshots__/ssr/one-segment-holding-all-six-conventions-nests-layout-template-error-loading-not-found-page.snap`
```
status 200
content-type: text/html; charset=utf-8
html:
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><style></style></head><body><div data-onze-root=""><div data-onze-seg="/"><span>layout 0</span><div data-onze-t="/#1"><div data-onze-e="/"><div data-onze-h="h1"><div data-onze-n="/"><main>page /</main></div></div></div></div></div></div><script id="__onze" type="application/json">{…}</script><script src="/_onze/client-build-0001.js" defer></script></body></html>
payload:
v: 1
b: "build-0001"
p: "/"
r: "/"
m: ""
q: ""
t: "L|/||\nT|/||\nE|/||\nS|/||\nN|/||\nP|/||"
i: []
a: []
s: ""
h: []
d: false
k: ""
z: ""
```

### `ssr: a segment without a template contributes no wrapper`

```bp
test "ssr: a segment without a template contributes no wrapper" {
    try assertSsr(@src(),
        ["app/layout.bp", "app/template.bp", "app/blog/layout.bp", "app/blog/page.bp"],
        "GET /blog");
}
```

`modules/rakun-app/test/__snapshots__/ssr/a-segment-without-a-template-contributes-no-wrapper.snap`
```
status 200
content-type: text/html; charset=utf-8
html:
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><style></style></head><body><div data-onze-root=""><div data-onze-seg="/"><span>layout 0</span><div data-onze-t="/#1"><div data-onze-seg="/blog"><span>layout 1</span><main>page /blog</main></div></div></div></div><script id="__onze" type="application/json">{…}</script><script src="/_onze/client-build-0001.js" defer></script></body></html>
payload:
v: 1
b: "build-0001"
p: "/blog"
r: "/blog"
m: ""
q: ""
t: "L|/||\nT|/||\nL|/blog||\nP|/blog||"
i: []
a: []
s: ""
h: []
d: false
k: ""
z: ""
```

### `ssr: an unmatched url answers 404 with the root not-found boundary`

```bp
test "ssr: an unmatched url answers 404 with the root not-found boundary" {
    try assertSsr(@src(),
        ["app/layout.bp", "app/not-found.bp", "app/page.bp"],
        "GET /nope");
}
```

`modules/rakun-app/test/__snapshots__/ssr/an-unmatched-url-answers-404-with-the-root-not-found-boundary.snap`
```
status 404
content-type: text/html; charset=utf-8
html:
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><style></style></head><body><div data-onze-root=""><div data-onze-seg="/"><span>layout 0</span><span>not-found /</span></div></div><script id="__onze" type="application/json">{…}</script><script src="/_onze/client-build-0001.js" defer></script></body></html>
payload:
v: 1
b: "build-0001"
p: "/nope"
r: ""
m: ""
q: ""
t: "L|/||\nN|/||\nP|/||"
i: []
a: []
s: ""
h: []
d: false
k: ""
z: ""
```

### `ssr: a nested not-found boundary wins over the root one`

```bp
test "ssr: a nested not-found boundary wins over the root one" {
    try assertSsr(@src(),
        ["app/layout.bp", "app/not-found.bp", "app/blog/layout.bp", "app/blog/not-found.bp", "app/blog/[slug]/page.bp"],
        "GET /blog");
}
```

`modules/rakun-app/test/__snapshots__/ssr/a-nested-not-found-boundary-wins-over-the-root-one.snap`
```
status 404
content-type: text/html; charset=utf-8
html:
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><style></style></head><body><div data-onze-root=""><div data-onze-seg="/"><span>layout 0</span><div data-onze-seg="/blog"><span>layout 1</span><span>not-found /blog</span></div></div></div><script id="__onze" type="application/json">{…}</script><script src="/_onze/client-build-0001.js" defer></script></body></html>
payload:
v: 1
b: "build-0001"
p: "/blog"
r: ""
m: ""
q: ""
t: "L|/||\nN|/||\nL|/blog||\nN|/blog||\nP|/blog/[slug]||"
i: []
a: []
s: ""
h: []
d: false
k: ""
z: ""
```

### `ssr: a param from the url is escaped on the way into the document`

```bp
test "ssr: a param from the url is escaped on the way into the document" {
    try assertSsr(@src(),
        ["app/layout.bp", "app/blog/[slug]/page.bp"],
        "GET /blog/%3Cscript%3Ealert(1)%3C%2Fscript%3E");
}
```

`modules/rakun-app/test/__snapshots__/ssr/a-param-from-the-url-is-escaped-on-the-way-into-the-document.snap`
```
status 200
content-type: text/html; charset=utf-8
html:
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><style></style></head><body><div data-onze-root=""><div data-onze-seg="/"><span>layout 0</span><main>page /blog/[slug] slug=&lt;script&gt;alert(1)&lt;/script&gt;</main></div></div><script id="__onze" type="application/json">{…}</script><script src="/_onze/client-build-0001.js" defer></script></body></html>
payload:
v: 1
b: "build-0001"
p: "/blog/%3Cscript%3Ealert(1)%3C%2Fscript%3E"
r: "/blog/[slug]"
m: "slug=%3Cscript%3Ealert%281%29%3C%2Fscript%3E"
q: ""
t: "L|/||\nP|/blog/[slug]||"
i: []
a: []
s: ""
h: []
d: false
k: ""
z: ""
```

### `ssr: a query that tries to close the script block is escaped in the payload`

```bp
test "ssr: a query that tries to close the script block is escaped in the payload" {
    try assertSsr(@src(),
        ["app/layout.bp", "app/page.bp"],
        "GET /?q=<%2Fscript><script>alert(1)<%2Fscript>");
}
```

`modules/rakun-app/test/__snapshots__/ssr/a-query-that-tries-to-close-the-script-block-is-escaped-in-the-payload.snap`
```
status 200
content-type: text/html; charset=utf-8
html:
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><style></style></head><body><div data-onze-root=""><div data-onze-seg="/"><span>layout 0</span><main>page /</main></div></div><script id="__onze" type="application/json">{…}</script><script src="/_onze/client-build-0001.js" defer></script></body></html>
payload:
v: 1
b: "build-0001"
p: "/"
r: "/"
m: ""
q: "q=<%2Fscript><script>alert(1)<%2Fscript>"
t: "L|/||\nP|/||"
i: []
a: []
s: ""
h: []
d: false
k: ""
z: ""
```

### `ssr: a three-deep layout chain receives depths 0 1 2`

```bp
test "ssr: a three-deep layout chain receives depths 0 1 2" {
    try assertSsr(@src(),
        ["app/layout.bp", "app/docs/layout.bp", "app/docs/[[...slug]]/layout.bp", "app/docs/[[...slug]]/page.bp"],
        "GET /docs/routing/dynamic");
}
```

`modules/rakun-app/test/__snapshots__/ssr/a-three-deep-layout-chain-receives-depths-0-1-2.snap`
```
status 200
content-type: text/html; charset=utf-8
html:
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><style></style></head><body><div data-onze-root=""><div data-onze-seg="/"><span>layout 0</span><div data-onze-seg="/docs"><span>layout 1</span><div data-onze-seg="/docs/[[...slug]]"><span>layout 2</span><main>page /docs/[[...slug]] slug=routing%2Fdynamic</main></div></div></div></div><script id="__onze" type="application/json">{…}</script><script src="/_onze/client-build-0001.js" defer></script></body></html>
payload:
v: 1
b: "build-0001"
p: "/docs/routing/dynamic"
r: "/docs/[[...slug]]"
m: "slug=routing%2Fdynamic"
q: ""
t: "L|/||\nL|/docs||\nL|/docs/[[...slug]]||\nP|/docs/[[...slug]]||"
i: []
a: []
s: ""
h: []
d: false
k: ""
z: ""
```

## 24-rakun-server-actions — `rakun-app`

**Test file:** `modules/rakun-app/test/actions_test.bp` · **Snapshots:** `modules/rakun-app/test/__snapshots__/action/` · **Target:** both — boundary (decorator, id, CSRF, size, dispatch, revalidation and redirect are erlang; the envelope/form reader is commonJS over the same fixture) · **Pins:** Step 1 both spellings produce the same record + an unmarked `pub fn` is 404 not 500, Step 2 the name alone does not resolve, Step 4 `Origin`≠`Host` → 403 before the body + no `Origin` → 403 + `multipart/form-data` → 415 + unknown id → 404 empty, Step 5 `ok: true` with state + throw → `ok: false` and 200 + `revalidatePath` echoed + `redirect` → 303 progressive + `v: 1` first

> helper gap: the `form` argument's shape is not in the table; these cases write it as `<name>[ <header>: <v>]* | <urlencoded body>`, mirroring `request`. `result <value>` renders the envelope as `ok <state qs>` / `err <state qs>` and a refused dispatch as `refused <status>`; `revalidate […]` is always written, `redirect` only when a signal was raised. `notFound()` inside an action is pinned in 63's `navigation` suite, whose helper has a `status` line.

### `action: a valid submission clears the state and revalidates the list route`

```bp
test "action: a valid submission clears the state and revalidates the list route" {
    try assertAction(@src(),
        \\ import {serverAction, FormData, ActionResult, rkRegisterAction} from "rakun";
        \\ import {cache} from "rakun-cache";
        \\ #[serverAction]
        \\ #[@future]
        \\ pub fn createPost(form: FormData) -> @Future<ActionResult> {
        \\     val title = form.field("title");
        \\     val tooShort = title.length() < 3;
        \\     if (tooShort) {
        \\         return ActionResult.invalid("title", "Title must be at least 3 characters");
        \\     };
        \\     cache.revalidatePath("/blog");
        \\     return ActionResult.done();
        \\ }
        , "createPost Origin: https://app.example Host: app.example | title=Rendering+on+BEAM&body=a+body");
}
```

`modules/rakun-app/test/__snapshots__/action/a-valid-submission-clears-the-state-and-revalidates-the-list-route.snap`
```
action createPost
result ok
revalidate [/blog]
```

### `action: a title that is too short comes back as state not as an http error`

```bp
test "action: a title that is too short comes back as state not as an http error" {
    try assertAction(@src(),
        \\ import {serverAction, FormData, ActionResult, rkRegisterAction} from "rakun";
        \\ import {cache} from "rakun-cache";
        \\ #[serverAction]
        \\ #[@future]
        \\ pub fn createPost(form: FormData) -> @Future<ActionResult> {
        \\     val title = form.field("title");
        \\     val tooShort = title.length() < 3;
        \\     if (tooShort) {
        \\         return ActionResult.invalid("title", "Title must be at least 3 characters");
        \\     };
        \\     cache.revalidatePath("/blog");
        \\     return ActionResult.done();
        \\ }
        , "createPost Origin: https://app.example Host: app.example | title=hi&body=a+body");
}
```

`modules/rakun-app/test/__snapshots__/action/a-title-that-is-too-short-comes-back-as-state-not-as-an-http-error.snap`
```
action createPost
result ok title=Title+must+be+at+least+3+characters
revalidate []
```

### `action: an action that throws is ok false with the message in state`

```bp
test "action: an action that throws is ok false with the message in state" {
    try assertAction(@src(),
        \\ import {serverAction, FormData, ActionResult, rkRegisterAction} from "rakun";
        \\ #[serverAction]
        \\ #[@future]
        \\ pub fn deletePost(form: FormData) -> @Future<ActionResult> {
        \\     val id = form.field("id");
        \\     throw "no such post: " + id;
        \\ }
        , "deletePost Origin: https://app.example Host: app.example | id=9");
}
```

`modules/rakun-app/test/__snapshots__/action/an-action-that-throws-is-ok-false-with-the-message-in-state.snap`
```
action deletePost
result err message=no+such+post%3A+9
revalidate []
```

### `action: revalidateTag lands beside revalidatePath in the echoed list`

```bp
test "action: revalidateTag lands beside revalidatePath in the echoed list" {
    try assertAction(@src(),
        \\ import {serverAction, FormData, ActionResult, rkRegisterAction} from "rakun";
        \\ import {cache} from "rakun-cache";
        \\ #[serverAction]
        \\ #[@future]
        \\ pub fn publishPost(form: FormData) -> @Future<ActionResult> {
        \\     cache.revalidatePath("/blog");
        \\     cache.revalidateTag("posts");
        \\     return ActionResult.done();
        \\ }
        , "publishPost Origin: https://app.example Host: app.example | id=1");
}
```

`modules/rakun-app/test/__snapshots__/action/revalidatetag-lands-beside-revalidatepath-in-the-echoed-list.snap`
```
action publishPost
result ok
revalidate [/blog, posts]
```

### `action: redirect after the write is a 303 on the progressive path`

```bp
test "action: redirect after the write is a 303 on the progressive path" {
    try assertAction(@src(),
        \\ import {serverAction, FormData, ActionResult, rkRegisterAction, redirect} from "rakun";
        \\ import {cache} from "rakun-cache";
        \\ #[serverAction]
        \\ #[@future]
        \\ pub fn createPost(form: FormData) -> @Future<ActionResult> {
        \\     cache.revalidatePath("/blog");
        \\     val _navigated = redirect("/blog");
        \\     return ActionResult.done();
        \\ }
        , "createPost Origin: https://app.example Host: app.example | title=Rendering+on+BEAM");
}
```

`modules/rakun-app/test/__snapshots__/action/redirect-after-the-write-is-a-303-on-the-progressive-path.snap`
```
action createPost
result ok
revalidate [/blog]
redirect 303 /blog
```

### `action: an origin that differs from host is refused before the body is read`

```bp
test "action: an origin that differs from host is refused before the body is read" {
    try assertAction(@src(),
        \\ import {serverAction, FormData, ActionResult, rkRegisterAction} from "rakun";
        \\ import {cache} from "rakun-cache";
        \\ #[serverAction]
        \\ #[@future]
        \\ pub fn createPost(form: FormData) -> @Future<ActionResult> {
        \\     cache.revalidatePath("/blog");
        \\     return ActionResult.done();
        \\ }
        , "createPost Origin: https://evil.example Host: app.example | title=Rendering+on+BEAM");
}
```

`modules/rakun-app/test/__snapshots__/action/an-origin-that-differs-from-host-is-refused-before-the-body-is-read.snap`
```
action createPost
result refused 403
revalidate []
```

### `action: a post with no origin header is refused`

```bp
test "action: a post with no origin header is refused" {
    try assertAction(@src(),
        \\ import {serverAction, FormData, ActionResult, rkRegisterAction} from "rakun";
        \\ #[serverAction]
        \\ #[@future]
        \\ pub fn createPost(form: FormData) -> @Future<ActionResult> {
        \\     return ActionResult.done();
        \\ }
        , "createPost Host: app.example | title=Rendering+on+BEAM");
}
```

`modules/rakun-app/test/__snapshots__/action/a-post-with-no-origin-header-is-refused.snap`
```
action createPost
result refused 403
revalidate []
```

### `action: multipart form data is refused with 415`

```bp
test "action: multipart form data is refused with 415" {
    try assertAction(@src(),
        \\ import {serverAction, FormData, ActionResult, rkRegisterAction} from "rakun";
        \\ #[serverAction]
        \\ #[@future]
        \\ pub fn createPost(form: FormData) -> @Future<ActionResult> {
        \\     return ActionResult.done();
        \\ }
        , "createPost Origin: https://app.example Host: app.example Content-Type: multipart/form-data; boundary=x | --x--");
}
```

`modules/rakun-app/test/__snapshots__/action/multipart-form-data-is-refused-with-415.snap`
```
action createPost
result refused 415
revalidate []
```

### `action: an unmarked pub fn is not reachable by its name`

```bp
test "action: an unmarked pub fn is not reachable by its name" {
    try assertAction(@src(),
        \\ import {serverAction, FormData, ActionResult, rkRegisterAction} from "rakun";
        \\ #[@future]
        \\ pub fn savePost(form: FormData) -> @Future<ActionResult> {
        \\     return ActionResult.done();
        \\ }
        , "savePost Origin: https://app.example Host: app.example | title=x");
}
```

`modules/rakun-app/test/__snapshots__/action/an-unmarked-pub-fn-is-not-reachable-by-its-name.snap`
```
action savePost
result refused 404
revalidate []
```

### `action: the file-level useServer directive registers the same record as the decorator`

```bp
test "action: the file-level useServer directive registers the same record as the decorator" {
    try assertAction(@src(),
        \\ import {FormData, ActionResult, rkRegisterAction} from "rakun";
        \\ import {cache} from "rakun-cache";
        \\ pub val useServer = true;
        \\ #[@future]
        \\ pub fn createPost(form: FormData) -> @Future<ActionResult> {
        \\     val title = form.field("title");
        \\     val tooShort = title.length() < 3;
        \\     if (tooShort) {
        \\         return ActionResult.invalid("title", "Title must be at least 3 characters");
        \\     };
        \\     cache.revalidatePath("/blog");
        \\     return ActionResult.done();
        \\ }
        , "createPost Origin: https://app.example Host: app.example | title=Rendering+on+BEAM&body=a+body");
}
```

`modules/rakun-app/test/__snapshots__/action/the-file-level-useserver-directive-registers-the-same-record-as-the-decorator.snap`
```
action createPost
result ok
revalidate [/blog]
```

## 25-rakun-route-handlers — `rakun-app`

**Test file:** `modules/rakun-app/test/route_handler_test.bp` · **Snapshots:** `modules/rakun-app/test/__snapshots__/handler/` · **Target:** erlang · **Pins:** Step 1 `#[getRoute("api/posts")]` → `R|/api/posts||GET` + `[slug]`/`[id]` through `req.param`, Step 2 `bodyJson` malformed → 400 not 500 + `multipart/form-data` → 415 before the body, Step 3 `json` content type + `withHeader` returns a new value, Step 4 `streamed` one chunk per thunk in index order + `Transfer-Encoding: chunked` and no `Content-Length`, Step 5 405 with `Allow` listing the registered verbs + `HEAD` falls back to `GET` with the body dropped

### `handler: get answers json with its content type`

```bp
test "handler: get answers json with its content type" {
    try assertHandler(@src(),
        \\ import {Request, getRoute, HandlerResponse, rkAppRegisterHandler} from "rakun";
        \\ #[getRoute("api/posts")]
        \\ #[@future]
        \\ pub fn listPosts(req: Request) -> @Future<HandlerResponse> {
        \\     return HandlerResponse.json("[{\"id\":\"1\"},{\"id\":\"2\"}]");
        \\ }
        , "GET /api/posts");
}
```

`modules/rakun-app/test/__snapshots__/handler/get-answers-json-with-its-content-type.snap`
```
200
content-type: application/json
chunks 1
[{"id":"1"},{"id":"2"}]
```

### `handler: a create with a valid body is 201 and points at the new resource`

```bp
test "handler: a create with a valid body is 201 and points at the new resource" {
    try assertHandler(@src(),
        \\ import {Request, postRoute, HandlerResponse, bodyJson, rkAppRegisterHandler} from "rakun";
        \\ #[postRoute("api/posts")]
        \\ #[@future]
        \\ pub fn createPost(req: Request) -> @Future<HandlerResponse> {
        \\     val parsed = bodyJson(req);
        \\     val ok = parsed.isOk();
        \\     if (!ok) {
        \\         return HandlerResponse.badRequest("body is not valid JSON");
        \\     };
        \\     val res = HandlerResponse.created("{\"id\":\"3\"}");
        \\     return res.withHeader("location", "/api/posts/3");
        \\ }
        , "POST /api/posts Content-Type: application/json | {\"title\":\"x\"}");
}
```

`modules/rakun-app/test/__snapshots__/handler/a-create-with-a-valid-body-is-201-and-points-at-the-new-resource.snap`
```
201
content-type: application/json
location: /api/posts/3
chunks 1
{"id":"3"}
```

### `handler: a malformed json body is 400 not 500`

```bp
test "handler: a malformed json body is 400 not 500" {
    try assertHandler(@src(),
        \\ import {Request, postRoute, HandlerResponse, bodyJson, rkAppRegisterHandler} from "rakun";
        \\ #[postRoute("api/posts")]
        \\ #[@future]
        \\ pub fn createPost(req: Request) -> @Future<HandlerResponse> {
        \\     val parsed = bodyJson(req);
        \\     val ok = parsed.isOk();
        \\     if (!ok) {
        \\         return HandlerResponse.badRequest("body is not valid JSON");
        \\     };
        \\     return HandlerResponse.created(parsed.unwrapOr("{}"));
        \\ }
        , "POST /api/posts Content-Type: application/json | {not json");
}
```

`modules/rakun-app/test/__snapshots__/handler/a-malformed-json-body-is-400-not-500.snap`
```
400
content-type: text/plain; charset=utf-8
chunks 1
body is not valid JSON
```

### `handler: multipart is refused with 415 before the body is read`

```bp
test "handler: multipart is refused with 415 before the body is read" {
    try assertHandler(@src(),
        \\ import {Request, postRoute, HandlerResponse, bodyForm, rkAppRegisterHandler} from "rakun";
        \\ #[postRoute("api/upload")]
        \\ #[@future]
        \\ pub fn upload(req: Request) -> @Future<HandlerResponse> {
        \\     val fields = bodyForm(req);
        \\     return HandlerResponse.text(fields.lookup("name").unwrapOr(""));
        \\ }
        , "POST /api/upload Content-Type: multipart/form-data; boundary=x | --x--");
}
```

`modules/rakun-app/test/__snapshots__/handler/multipart-is-refused-with-415-before-the-body-is-read.snap`
```
415
content-type: text/plain; charset=utf-8
chunks 1
multipart/form-data is not supported
```

### `handler: a dynamic segment reaches the handler as a request param`

```bp
test "handler: a dynamic segment reaches the handler as a request param" {
    try assertHandler(@src(),
        \\ import {Request, getRoute, HandlerResponse, rkAppRegisterHandler} from "rakun";
        \\ #[getRoute("api/posts/[id]")]
        \\ #[@future]
        \\ pub fn showPost(req: Request) -> @Future<HandlerResponse> {
        \\     val id = req.param("id");
        \\     val empty = id == "";
        \\     if (empty) {
        \\         return HandlerResponse.notFound();
        \\     };
        \\     return HandlerResponse.json("{\"id\":\"" + id + "\"}");
        \\ }
        , "GET /api/posts/7");
}
```

`modules/rakun-app/test/__snapshots__/handler/a-dynamic-segment-reaches-the-handler-as-a-request-param.snap`
```
200
content-type: application/json
chunks 1
{"id":"7"}
```

### `handler: a verb the segment does not register answers 405 with allow`

```bp
test "handler: a verb the segment does not register answers 405 with allow" {
    try assertHandler(@src(),
        \\ import {Request, getRoute, postRoute, HandlerResponse, rkAppRegisterHandler} from "rakun";
        \\ #[getRoute("api/posts")]
        \\ #[@future]
        \\ pub fn listPosts(req: Request) -> @Future<HandlerResponse> {
        \\     return HandlerResponse.json("[]");
        \\ }
        \\ #[postRoute("api/posts")]
        \\ #[@future]
        \\ pub fn createPost(req: Request) -> @Future<HandlerResponse> {
        \\     return HandlerResponse.created("{}");
        \\ }
        , "DELETE /api/posts");
}
```

`modules/rakun-app/test/__snapshots__/handler/a-verb-the-segment-does-not-register-answers-405-with-allow.snap`
```
405
allow: GET, POST
chunks 0
```

### `handler: head falls back to get with the body dropped`

```bp
test "handler: head falls back to get with the body dropped" {
    try assertHandler(@src(),
        \\ import {Request, getRoute, HandlerResponse, rkAppRegisterHandler} from "rakun";
        \\ #[getRoute("api/posts")]
        \\ #[@future]
        \\ pub fn listPosts(req: Request) -> @Future<HandlerResponse> {
        \\     return HandlerResponse.json("[]");
        \\ }
        , "HEAD /api/posts");
}
```

`modules/rakun-app/test/__snapshots__/handler/head-falls-back-to-get-with-the-body-dropped.snap`
```
200
content-type: application/json
chunks 0
```

### `handler: the export streams one chunk per row in index order`

```bp
test "handler: the export streams one chunk per row in index order" {
    try assertHandler(@src(),
        \\ import {Request, getRoute, HandlerResponse, streamed, rkAppRegisterHandler} from "rakun";
        \\ #[@future]
        \\ fn exportRow(n: i32) -> @Future<string> {
        \\     return "row " + n.toString() + "\n";
        \\ }
        \\ #[getRoute("api/export")]
        \\ #[@future]
        \\ pub fn exportPosts(req: Request) -> @Future<HandlerResponse> {
        \\     var tasks: Array<fn() -> @Future<string>> = [];
        \\     loop (0..3) { n ->
        \\         tasks.push({ -> exportRow(n) });
        \\     };
        \\     val res = streamed(200, tasks);
        \\     return res.withHeader("content-type", "text/plain; charset=utf-8");
        \\ }
        , "GET /api/export");
}
```

`modules/rakun-app/test/__snapshots__/handler/the-export-streams-one-chunk-per-row-in-index-order.snap`
```
200
content-type: text/plain; charset=utf-8
transfer-encoding: chunked
chunks 3
row 0
row 1
row 2
```

## 60-rakun-static-generation — `rakun-app`

**Test file:** `modules/rakun-app/test/static_gen_test.bp` · **Snapshots:** `modules/rakun-app/test/__snapshots__/static/` · **Target:** both — boundary (decision, enumeration and config inheritance are erlang; the route-kind blob these rows are joined on is the commonJS half, read from payload `k`) · **Pins:** Step 1 default config `Auto`/`dynamicParams: true`/`revalidate: -1` + `configFor` inherits `revalidate` from `/blog` + `revalidate: 0` normalized to `ForceDynamic`, Step 2 rules 1–5 in order (`ForceDynamic` wins over `generateStaticParams`, `ForceStatic` + dynamic read stays static naming the conflict, dynamic pattern without params is dynamic, `isDynamic()` reason recorded, `reason == ""` only by rule 5) + `dynamicParams: false` with no rows is static, Step 3 `expandParams` for `[slug]`, `[...slug]`, `[[...slug]]`, Step 4 one static entry + one `skippedDynamic` with the reason

> helper gap: `reason` is `""` exactly when the kind is `Static` by rule 5 (Step 2); the row renders that as `because -` so no line carries a double space. `revalidate=` is the value `configFor` answers, `never` for `-1`.

### `static: a page that reads nothing is static`

```bp
test "static: a page that reads nothing is static" {
    try assertStaticGen(@src(),
        ["app/layout.bp", "app/page.bp", "app/about/page.bp"],
        \\ import {page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ #[page("")]
        \\ #[@future]
        \\ pub fn homePage(route: PageContext) -> @Future<Element> {
        \\     return p([text("home", attrs: [])], attrs: []);
        \\ }
        \\ #[page("about")]
        \\ #[@future]
        \\ pub fn aboutPage(route: PageContext) -> @Future<Element> {
        \\     return p([text("about", attrs: [])], attrs: []);
        \\ }
        );
}
```

`modules/rakun-app/test/__snapshots__/static/a-page-that-reads-nothing-is-static.snap`
```
/ static because - params=[/] revalidate=never
/about static because - params=[/about] revalidate=never
```

### `static: reading the query marks the route dynamic`

```bp
test "static: reading the query marks the route dynamic" {
    try assertStaticGen(@src(),
        ["app/layout.bp", "app/page.bp", "app/search/page.bp"],
        \\ import {page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ #[page("")]
        \\ #[@future]
        \\ pub fn homePage(route: PageContext) -> @Future<Element> {
        \\     return p([text("home", attrs: [])], attrs: []);
        \\ }
        \\ #[page("search")]
        \\ #[@future]
        \\ pub fn searchPage(route: PageContext) -> @Future<Element> {
        \\     val term = route.query.lookup("q").unwrapOr("");
        \\     return p([text("Results for " + term, attrs: [])], attrs: []);
        \\ }
        );
}
```

`modules/rakun-app/test/__snapshots__/static/reading-the-query-marks-the-route-dynamic.snap`
```
/ static because - params=[/] revalidate=never
/search dynamic because searchParams params=[] revalidate=never
```

### `static: reading cookies marks the route dynamic`

```bp
test "static: reading cookies marks the route dynamic" {
    try assertStaticGen(@src(),
        ["app/layout.bp", "app/dashboard/page.bp"],
        \\ import {page, PageContext, cookies, rkAppRegisterPage} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ #[page("dashboard")]
        \\ #[@future]
        \\ pub fn dashboardPage(route: PageContext) -> @Future<Element> {
        \\     val session = cookies().get("session").unwrapOr("");
        \\     return p([text("signed in as " + session, attrs: [])], attrs: []);
        \\ }
        );
}
```

`modules/rakun-app/test/__snapshots__/static/reading-cookies-marks-the-route-dynamic.snap`
```
/dashboard dynamic because cookies params=[] revalidate=never
```

### `static: a dynamic segment without generateStaticParams is dynamic`

```bp
test "static: a dynamic segment without generateStaticParams is dynamic" {
    try assertStaticGen(@src(),
        ["app/layout.bp", "app/blog/[slug]/page.bp"],
        \\ import {page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ #[page("blog/[slug]")]
        \\ #[@future]
        \\ pub fn blogPostPage(route: PageContext) -> @Future<Element> {
        \\     val slug = route.params.lookup("slug").unwrapOr("");
        \\     return p([text(slug, attrs: [])], attrs: []);
        \\ }
        );
}
```

`modules/rakun-app/test/__snapshots__/static/a-dynamic-segment-without-generatestaticparams-is-dynamic.snap`
```
/blog/[slug] dynamic because no generateStaticParams params=[] revalidate=never
```

### `static: generateStaticParams enumerates the paths to prerender`

```bp
test "static: generateStaticParams enumerates the paths to prerender" {
    try assertStaticGen(@src(),
        ["app/layout.bp", "app/blog/[slug]/page.bp", "app/shop/[...slug]/page.bp", "app/docs/[[...slug]]/page.bp"],
        \\ import {page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {registerSegmentConfig, registerStaticParams, SegmentConfig, DynamicMode, FetchCache, StaticParams, ParamBinding} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ val _blogConfig = registerSegmentConfig("blog/[slug]", SegmentConfig(
        \\     dynamic: DynamicMode.Auto,
        \\     dynamicParams: true,
        \\     revalidate: 3600,
        \\     fetchCache: FetchCache.Auto,
        \\ ));
        \\ #[@future]
        \\ pub fn blogStaticParams() -> @Future<StaticParams[]> {
        \\     return [
        \\         StaticParams(bindings: [ParamBinding(name: "slug", value: "hello")]),
        \\         StaticParams(bindings: [ParamBinding(name: "slug", value: "beam")]),
        \\     ];
        \\ }
        \\ val _blogParams = registerStaticParams("blog/[slug]", blogStaticParams);
        \\ #[@future]
        \\ pub fn shopStaticParams() -> @Future<StaticParams[]> {
        \\     return [StaticParams(bindings: [ParamBinding(name: "slug", value: "clothing/shirts")])];
        \\ }
        \\ val _shopParams = registerStaticParams("shop/[...slug]", shopStaticParams);
        \\ #[@future]
        \\ pub fn docsStaticParams() -> @Future<StaticParams[]> {
        \\     return [
        \\         StaticParams(bindings: [ParamBinding(name: "slug", value: "")]),
        \\         StaticParams(bindings: [ParamBinding(name: "slug", value: "routing/dynamic")]),
        \\     ];
        \\ }
        \\ val _docsParams = registerStaticParams("docs/[[...slug]]", docsStaticParams);
        \\ #[page("blog/[slug]")]
        \\ #[@future]
        \\ pub fn blogPostPage(route: PageContext) -> @Future<Element> {
        \\     val slug = route.params.lookup("slug").unwrapOr("");
        \\     return p([text(slug, attrs: [])], attrs: []);
        \\ }
        \\ #[page("shop/[...slug]")]
        \\ #[@future]
        \\ pub fn shopPage(route: PageContext) -> @Future<Element> {
        \\     return p([text(route.rest.join("/"), attrs: [])], attrs: []);
        \\ }
        \\ #[page("docs/[[...slug]]")]
        \\ #[@future]
        \\ pub fn docsPage(route: PageContext) -> @Future<Element> {
        \\     return p([text(route.rest.join("/"), attrs: [])], attrs: []);
        \\ }
        );
}
```

`modules/rakun-app/test/__snapshots__/static/generatestaticparams-enumerates-the-paths-to-prerender.snap`
```
/blog/[slug] static because - params=[/blog/hello, /blog/beam] revalidate=3600
/shop/[...slug] static because - params=[/shop/clothing/shirts] revalidate=never
/docs/[[...slug]] static because - params=[/docs, /docs/routing/dynamic] revalidate=never
```

### `static: forceDynamic wins over generateStaticParams`

```bp
test "static: forceDynamic wins over generateStaticParams" {
    try assertStaticGen(@src(),
        ["app/layout.bp", "app/blog/[slug]/page.bp"],
        \\ import {page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {registerSegmentConfig, registerStaticParams, SegmentConfig, DynamicMode, FetchCache, StaticParams, ParamBinding} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ val _blogConfig = registerSegmentConfig("blog/[slug]", SegmentConfig(
        \\     dynamic: DynamicMode.ForceDynamic,
        \\     dynamicParams: true,
        \\     revalidate: -1,
        \\     fetchCache: FetchCache.Auto,
        \\ ));
        \\ #[@future]
        \\ pub fn blogStaticParams() -> @Future<StaticParams[]> {
        \\     return [StaticParams(bindings: [ParamBinding(name: "slug", value: "hello")])];
        \\ }
        \\ val _blogParams = registerStaticParams("blog/[slug]", blogStaticParams);
        \\ #[page("blog/[slug]")]
        \\ #[@future]
        \\ pub fn blogPostPage(route: PageContext) -> @Future<Element> {
        \\     val slug = route.params.lookup("slug").unwrapOr("");
        \\     return p([text(slug, attrs: [])], attrs: []);
        \\ }
        );
}
```

`modules/rakun-app/test/__snapshots__/static/forcedynamic-wins-over-generatestaticparams.snap`
```
/blog/[slug] dynamic because ForceDynamic params=[] revalidate=never
```

### `static: forceStatic with a dynamic read stays static and names the conflict`

```bp
test "static: forceStatic with a dynamic read stays static and names the conflict" {
    try assertStaticGen(@src(),
        ["app/layout.bp", "app/dashboard/page.bp"],
        \\ import {page, PageContext, cookies, rkAppRegisterPage} from "rakun";
        \\ import {registerSegmentConfig, SegmentConfig, DynamicMode, FetchCache} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ val _dashConfig = registerSegmentConfig("dashboard", SegmentConfig(
        \\     dynamic: DynamicMode.ForceStatic,
        \\     dynamicParams: true,
        \\     revalidate: -1,
        \\     fetchCache: FetchCache.Auto,
        \\ ));
        \\ #[page("dashboard")]
        \\ #[@future]
        \\ pub fn dashboardPage(route: PageContext) -> @Future<Element> {
        \\     val session = cookies().get("session").unwrapOr("");
        \\     return p([text("signed in as " + session, attrs: [])], attrs: []);
        \\ }
        );
}
```

`modules/rakun-app/test/__snapshots__/static/forcestatic-with-a-dynamic-read-stays-static-and-names-the-conflict.snap`
```
/dashboard static because ForceStatic overrides cookies params=[/dashboard] revalidate=never
```

### `static: revalidate zero is normalized to forceDynamic`

```bp
test "static: revalidate zero is normalized to forceDynamic" {
    try assertStaticGen(@src(),
        ["app/layout.bp", "app/now/page.bp"],
        \\ import {page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {registerSegmentConfig, SegmentConfig, DynamicMode, FetchCache} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ val _nowConfig = registerSegmentConfig("now", SegmentConfig(
        \\     dynamic: DynamicMode.Auto,
        \\     dynamicParams: true,
        \\     revalidate: 0,
        \\     fetchCache: FetchCache.Auto,
        \\ ));
        \\ #[page("now")]
        \\ #[@future]
        \\ pub fn nowPage(route: PageContext) -> @Future<Element> {
        \\     return p([text("now", attrs: [])], attrs: []);
        \\ }
        );
}
```

`modules/rakun-app/test/__snapshots__/static/revalidate-zero-is-normalized-to-forcedynamic.snap`
```
/now dynamic because ForceDynamic params=[] revalidate=0
```

### `static: a segment inherits revalidate from its layout`

```bp
test "static: a segment inherits revalidate from its layout" {
    try assertStaticGen(@src(),
        ["app/layout.bp", "app/blog/layout.bp", "app/blog/page.bp", "app/blog/[slug]/page.bp"],
        \\ import {page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {registerSegmentConfig, registerStaticParams, SegmentConfig, DynamicMode, FetchCache, StaticParams, ParamBinding} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ val _blogConfig = registerSegmentConfig("blog", SegmentConfig(
        \\     dynamic: DynamicMode.Auto,
        \\     dynamicParams: true,
        \\     revalidate: 600,
        \\     fetchCache: FetchCache.Auto,
        \\ ));
        \\ #[@future]
        \\ pub fn blogStaticParams() -> @Future<StaticParams[]> {
        \\     return [StaticParams(bindings: [ParamBinding(name: "slug", value: "hello")])];
        \\ }
        \\ val _blogParams = registerStaticParams("blog/[slug]", blogStaticParams);
        \\ #[page("blog")]
        \\ #[@future]
        \\ pub fn blogIndexPage(route: PageContext) -> @Future<Element> {
        \\     return p([text("blog", attrs: [])], attrs: []);
        \\ }
        \\ #[page("blog/[slug]")]
        \\ #[@future]
        \\ pub fn blogPostPage(route: PageContext) -> @Future<Element> {
        \\     val slug = route.params.lookup("slug").unwrapOr("");
        \\     return p([text(slug, attrs: [])], attrs: []);
        \\ }
        );
}
```

`modules/rakun-app/test/__snapshots__/static/a-segment-inherits-revalidate-from-its-layout.snap`
```
/blog static because - params=[/blog] revalidate=600
/blog/[slug] static because - params=[/blog/hello] revalidate=600
```

### `static: dynamicParams false with no rows is static and enumerates nothing`

```bp
test "static: dynamicParams false with no rows is static and enumerates nothing" {
    try assertStaticGen(@src(),
        ["app/layout.bp", "app/blog/[slug]/page.bp"],
        \\ import {page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {registerSegmentConfig, SegmentConfig, DynamicMode, FetchCache} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ val _blogConfig = registerSegmentConfig("blog/[slug]", SegmentConfig(
        \\     dynamic: DynamicMode.Auto,
        \\     dynamicParams: false,
        \\     revalidate: -1,
        \\     fetchCache: FetchCache.Auto,
        \\ ));
        \\ #[page("blog/[slug]")]
        \\ #[@future]
        \\ pub fn blogPostPage(route: PageContext) -> @Future<Element> {
        \\     val slug = route.params.lookup("slug").unwrapOr("");
        \\     return p([text(slug, attrs: [])], attrs: []);
        \\ }
        );
}
```

`modules/rakun-app/test/__snapshots__/static/dynamicparams-false-with-no-rows-is-static-and-enumerates-nothing.snap`
```
/blog/[slug] static because - params=[] revalidate=never
```

## 61-rakun-parallel-intercepting-routes — `rakun-app`

**Test file:** `modules/rakun-app/test/route_slots_test.bp` · **Snapshots:** `modules/rakun-app/test/__snapshots__/slots/` · **Target:** both — boundary (slot enumeration, per-slot matching, `default` fallback and the header gate are erlang; the marker parser/resolver and the `slot|pattern|state` codec are the commonJS half) · **Pins:** Step 1 `Matched` with params + hard-unmatched → `Defaulted`/`Empty` + soft-unmatched → `Unchanged` + two slots match independently in one call, Step 2 the hard-reload case end to end, Step 3 `(.)`/`(..)(..)` resolution + `(marketing)` is not an interception, Step 4 `soft: true` answers the intercepting entry and `soft: false` answers `null` for the same URL (the round trip in one snapshot)

> helper gap: `assertSlots` renders `matched|default` only; `SlotState.Unchanged` and `SlotState.Empty` (Step 1) render as `unchanged` / `empty`. A hard request has no `from` and is written `- -> <to>`; a `from` pattern means the navigation carried `x-rakun-nav: soft`. One line per navigation, every slot of the layout on it in declaration order, then `intercept=`.

### `slots: a hard request for the layout url matches one slot and defaults the other`

```bp
test "slots: a hard request for the layout url matches one slot and defaults the other" {
    try assertSlots(@src(),
        ["app/layout.bp", "app/dashboard/layout.bp", "app/dashboard/page.bp", "app/dashboard/@analytics/page.bp", "app/dashboard/@analytics/default.bp", "app/dashboard/@team/settings/page.bp", "app/dashboard/@team/default.bp"],
        ["- -> /dashboard"]);
}
```

`modules/rakun-app/test/__snapshots__/slots/a-hard-request-for-the-layout-url-matches-one-slot-and-defaults-the-other.snap`
```
- -> /dashboard: slot analytics=matched slot team=default intercept=none
```

### `slots: an unmatched slot on a hard request falls back to its default`

```bp
test "slots: an unmatched slot on a hard request falls back to its default" {
    try assertSlots(@src(),
        ["app/layout.bp", "app/dashboard/layout.bp", "app/dashboard/page.bp", "app/dashboard/@analytics/page.bp", "app/dashboard/@analytics/default.bp", "app/dashboard/@team/settings/page.bp", "app/dashboard/@team/default.bp"],
        ["- -> /dashboard/settings"]);
}
```

`modules/rakun-app/test/__snapshots__/slots/an-unmatched-slot-on-a-hard-request-falls-back-to-its-default.snap`
```
- -> /dashboard/settings: slot analytics=default slot team=matched intercept=none
```

### `slots: an unmatched slot on a soft navigation is unchanged`

```bp
test "slots: an unmatched slot on a soft navigation is unchanged" {
    try assertSlots(@src(),
        ["app/layout.bp", "app/dashboard/layout.bp", "app/dashboard/page.bp", "app/dashboard/@analytics/page.bp", "app/dashboard/@analytics/default.bp", "app/dashboard/@team/settings/page.bp", "app/dashboard/@team/default.bp"],
        ["/dashboard -> /dashboard/settings"]);
}
```

`modules/rakun-app/test/__snapshots__/slots/an-unmatched-slot-on-a-soft-navigation-is-unchanged.snap`
```
/dashboard -> /dashboard/settings: slot analytics=unchanged slot team=matched intercept=none
```

### `slots: a slot with no default is empty on a hard request`

```bp
test "slots: a slot with no default is empty on a hard request" {
    try assertSlots(@src(),
        ["app/layout.bp", "app/dashboard/layout.bp", "app/dashboard/page.bp", "app/dashboard/@analytics/page.bp", "app/dashboard/@team/settings/page.bp"],
        ["- -> /dashboard/settings", "/dashboard -> /dashboard/settings"]);
}
```

`modules/rakun-app/test/__snapshots__/slots/a-slot-with-no-default-is-empty-on-a-hard-request.snap`
```
- -> /dashboard/settings: slot analytics=empty slot team=matched intercept=none
/dashboard -> /dashboard/settings: slot analytics=unchanged slot team=matched intercept=none
```

### `slots: the same url is intercepted on a soft navigation and not on a hard request`

```bp
test "slots: the same url is intercepted on a soft navigation and not on a hard request" {
    try assertSlots(@src(),
        ["app/layout.bp", "app/feed/page.bp", "app/feed/(.)photo/[photoId]/page.bp", "app/feed/photo/[photoId]/page.bp"],
        ["/feed -> /feed/photo/1", "- -> /feed/photo/1"]);
}
```

`modules/rakun-app/test/__snapshots__/slots/the-same-url-is-intercepted-on-a-soft-navigation-and-not-on-a-hard-request.snap`
```
/feed -> /feed/photo/1: intercept=(.)photo/[photoId]
- -> /feed/photo/1: intercept=none
```

### `slots: a two-level marker climbs to the root`

```bp
test "slots: a two-level marker climbs to the root" {
    try assertSlots(@src(),
        ["app/layout.bp", "app/feed/[id]/page.bp", "app/feed/[id]/(..)(..)photo/[photoId]/page.bp", "app/photo/[photoId]/page.bp"],
        ["/feed/[id] -> /photo/2", "- -> /photo/2"]);
}
```

`modules/rakun-app/test/__snapshots__/slots/a-two-level-marker-climbs-to-the-root.snap`
```
/feed/[id] -> /photo/2: intercept=(..)(..)photo/[photoId]
- -> /photo/2: intercept=none
```

### `slots: a route group is not an interception`

```bp
test "slots: a route group is not an interception" {
    try assertSlots(@src(),
        ["app/layout.bp", "app/page.bp", "app/(marketing)/about/page.bp"],
        ["/ -> /about", "- -> /about"]);
}
```

`modules/rakun-app/test/__snapshots__/slots/a-route-group-is-not-an-interception.snap`
```
/ -> /about: intercept=none
- -> /about: intercept=none
```

## 63-rakun-navigation-signals — `rakun-app`

**Test file:** `modules/rakun-app/test/navigation_test.bp` · **Snapshots:** `modules/rakun-app/test/__snapshots__/navigation/` · **Target:** erlang · **Pins:** Step 1 `notFound()` never returns + `redirect` → 307 + `permanentRedirect` → 308, Step 2 a signal inside `try … catch` still reaches `captureSignals`, Step 3 a signal crosses `await` (one and two levels), Step 4 `statusFor`/`locationHeaderFor` (`null` for `NotFound`), § *Where a signal becomes a response* server-action row (`redirect` → 303 progressive, `notFound()` → 404) and front 24 Step 5

> helper gap: `location` has no value for `NotFound` (`locationHeaderFor` answers `null`) and renders as `location -`.

### `navigation: notFound from a page unwinds to 404`

```bp
test "navigation: notFound from a page unwinds to 404" {
    try assertNavigation(@src(),
        \\ import {notFound, page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ #[page("blog/[slug]")]
        \\ #[@future]
        \\ pub fn blogPostPage(route: PageContext) -> @Future<Element> {
        \\     val slug = route.params.lookup("slug").unwrapOr("");
        \\     val missing = slug != "hello";
        \\     if (missing) {
        \\         val _gone = notFound();
        \\     };
        \\     return p([text(slug, attrs: [])], attrs: []);
        \\ }
        , "GET /blog/nope");
}
```

`modules/rakun-app/test/__snapshots__/navigation/notfound-from-a-page-unwinds-to-404.snap`
```
signal notFound
status 404
location -
```

### `navigation: redirect from a layout is 307 with location`

```bp
test "navigation: redirect from a layout is 307 with location" {
    try assertNavigation(@src(),
        \\ import {redirect, cookies, layout, page, LayoutProps, PageContext, rkAppRegisterPage, rkAppRegisterLayout} from "rakun";
        \\ import {Element, div, p, text} from "jhonstart";
        \\ #[layout("dashboard")]
        \\ pub fn dashboardLayout(props: LayoutProps) -> Element {
        \\     val session = cookies().get("session").unwrapOr("");
        \\     if (session == "") {
        \\         val _gone = redirect("/login");
        \\     };
        \\     return div([props.children], attrs: []);
        \\ }
        \\ #[page("dashboard")]
        \\ #[@future]
        \\ pub fn dashboardPage(route: PageContext) -> @Future<Element> {
        \\     return p([text("overview", attrs: [])], attrs: []);
        \\ }
        \\ #[page("login")]
        \\ #[@future]
        \\ pub fn loginPage(route: PageContext) -> @Future<Element> {
        \\     return p([text("login", attrs: [])], attrs: []);
        \\ }
        , "GET /dashboard");
}
```

`modules/rakun-app/test/__snapshots__/navigation/redirect-from-a-layout-is-307-with-location.snap`
```
signal redirect
status 307
location /login
```

### `navigation: permanentRedirect is 308`

```bp
test "navigation: permanentRedirect is 308" {
    try assertNavigation(@src(),
        \\ import {permanentRedirect, page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ #[page("old")]
        \\ #[@future]
        \\ pub fn oldPage(route: PageContext) -> @Future<Element> {
        \\     val _moved = permanentRedirect("/new");
        \\     return p([text("old", attrs: [])], attrs: []);
        \\ }
        \\ #[page("new")]
        \\ #[@future]
        \\ pub fn newPage(route: PageContext) -> @Future<Element> {
        \\     return p([text("new", attrs: [])], attrs: []);
        \\ }
        , "GET /old");
}
```

`modules/rakun-app/test/__snapshots__/navigation/permanentredirect-is-308.snap`
```
signal permanentRedirect
status 308
location /new
```

### `navigation: a signal inside try catch is not caught`

```bp
test "navigation: a signal inside try catch is not caught" {
    try assertNavigation(@src(),
        \\ import {notFound, page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ #[@result]
        \\ fn loadPost(slug: string) -> @Result<string, string> {
        \\     val _gone = notFound();
        \\     return "unreachable";
        \\ }
        \\ #[page("blog/[slug]")]
        \\ #[@future]
        \\ pub fn blogPostPage(route: PageContext) -> @Future<Element> {
        \\     val slug = route.params.lookup("slug").unwrapOr("");
        \\     val title = try loadPost(slug) catch "fallback";
        \\     return p([text(title, attrs: [])], attrs: []);
        \\ }
        , "GET /blog/hello");
}
```

`modules/rakun-app/test/__snapshots__/navigation/a-signal-inside-try-catch-is-not-caught.snap`
```
signal notFound
status 404
location -
```

### `navigation: a signal crosses two levels of await`

```bp
test "navigation: a signal crosses two levels of await" {
    try assertNavigation(@src(),
        \\ import {redirect, page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {Element, p, text} from "jhonstart";
        \\ #[@future]
        \\ fn inner() -> @Future<string> {
        \\     val _gone = redirect("/login");
        \\     return "unreachable";
        \\ }
        \\ #[@future]
        \\ fn outer() -> @Future<string> {
        \\     val v = await inner();
        \\     return v + "!";
        \\ }
        \\ #[page("account")]
        \\ #[@future]
        \\ pub fn accountPage(route: PageContext) -> @Future<Element> {
        \\     val v = await outer();
        \\     return p([text(v, attrs: [])], attrs: []);
        \\ }
        \\ #[page("login")]
        \\ #[@future]
        \\ pub fn loginPage(route: PageContext) -> @Future<Element> {
        \\     return p([text("login", attrs: [])], attrs: []);
        \\ }
        , "GET /account");
}
```

`modules/rakun-app/test/__snapshots__/navigation/a-signal-crosses-two-levels-of-await.snap`
```
signal redirect
status 307
location /login
```

### `navigation: redirect inside an action is 303 on the progressive path`

```bp
test "navigation: redirect inside an action is 303 on the progressive path" {
    try assertNavigation(@src(),
        \\ import {redirect, serverAction, FormData, ActionResult, rkRegisterAction, page, PageContext, rkAppRegisterPage} from "rakun";
        \\ import {cache} from "rakun-cache";
        \\ import {Element, p, text} from "jhonstart";
        \\ #[serverAction]
        \\ #[@future]
        \\ pub fn createPost(form: FormData) -> @Future<ActionResult> {
        \\     cache.revalidatePath("/blog");
        \\     val _navigated = redirect("/blog");
        \\     return ActionResult.done();
        \\ }
        \\ #[page("blog")]
        \\ #[@future]
        \\ pub fn blogIndexPage(route: PageContext) -> @Future<Element> {
        \\     return p([text("blog", attrs: [])], attrs: []);
        \\ }
        , "POST /blog/new Origin: https://app.example Host: app.example | __onze_action=createPost&title=x");
}
```

`modules/rakun-app/test/__snapshots__/navigation/redirect-inside-an-action-is-303-on-the-progressive-path.snap`
```
signal redirect
status 303
location /blog
```

### `navigation: notFound inside an action is 404 on the progressive path`

```bp
test "navigation: notFound inside an action is 404 on the progressive path" {
    try assertNavigation(@src(),
        \\ import {notFound, serverAction, FormData, ActionResult, rkRegisterAction} from "rakun";
        \\ #[serverAction]
        \\ #[@future]
        \\ pub fn deletePost(form: FormData) -> @Future<ActionResult> {
        \\     val _gone = notFound();
        \\     return ActionResult.done();
        \\ }
        , "POST /blog/9 Origin: https://app.example Host: app.example | __onze_action=deletePost&id=9");
}
```

`modules/rakun-app/test/__snapshots__/navigation/notfound-inside-an-action-is-404-on-the-progressive-path.snap`
```
signal notFound
status 404
location -
```

## 64-rakun-i18n-routing — `rakun-app`

**Test file:** `modules/rakun-app/test/i18n_test.bp` · **Snapshots:** `modules/rakun-app/test/__snapshots__/locale/` · **Target:** erlang · **Pins:** Step 2 `q=0` never selected + descending-q selection + unsupported-only header → `defaultLocale` + cookie beats header, Step 3 `localeOfPath("/klingon/about")` is `null`, Step 4 unprefixed path → 307 to the prefixed path + prefixed path served without a redirect + `/sitemap.xml` on the default exclude list + the query string preserved byte for byte

> helper gap: `assertLocale` takes a config list; the locale set is registered in code (`registerLocales(LocaleSet(locales, defaultLocale))`, Step 1), so the config keys `rakun.i18n.locales` / `rakun.i18n.defaultLocale` below are (names per README § Step 1); `rakun.i18n.exclude` is the README's own key. The locale cookie is written `locale=<tag>` (name per README § Mechanism — "an explicit locale cookie"). A request on the exclude list still renders a `negotiated` line, from `default`.

### `locale: an unprefixed path redirects to the accept-language locale keeping its query`

```bp
test "locale: an unprefixed path redirects to the accept-language locale keeping its query" {
    try assertLocale(@src(),
        ["rakun.i18n.locales=pt-BR,en,es", "rakun.i18n.defaultLocale=pt-BR"],
        "GET /about?tab=team Accept-Language: en");
}
```

`modules/rakun-app/test/__snapshots__/locale/an-unprefixed-path-redirects-to-the-accept-language-locale-keeping-its-query.snap`
```
negotiated en from accept-language
redirect 307 /en/about?tab=team
```

### `locale: a supported cookie wins over the header`

```bp
test "locale: a supported cookie wins over the header" {
    try assertLocale(@src(),
        ["rakun.i18n.locales=pt-BR,en,es", "rakun.i18n.defaultLocale=pt-BR"],
        "GET /about Accept-Language: en Cookie: locale=es");
}
```

`modules/rakun-app/test/__snapshots__/locale/a-supported-cookie-wins-over-the-header.snap`
```
negotiated es from cookie
redirect 307 /es/about
```

### `locale: a prefixed path is served without a redirect`

```bp
test "locale: a prefixed path is served without a redirect" {
    try assertLocale(@src(),
        ["rakun.i18n.locales=pt-BR,en,es", "rakun.i18n.defaultLocale=pt-BR"],
        "GET /pt-BR/about Accept-Language: en");
}
```

`modules/rakun-app/test/__snapshots__/locale/a-prefixed-path-is-served-without-a-redirect.snap`
```
negotiated pt-BR from path
serve /[locale]/about
```

### `locale: an unknown prefix is not a locale`

```bp
test "locale: an unknown prefix is not a locale" {
    try assertLocale(@src(),
        ["rakun.i18n.locales=pt-BR,en,es", "rakun.i18n.defaultLocale=pt-BR"],
        "GET /klingon/about Accept-Language: en");
}
```

`modules/rakun-app/test/__snapshots__/locale/an-unknown-prefix-is-not-a-locale.snap`
```
negotiated en from accept-language
redirect 307 /en/klingon/about
```

### `locale: q zero is never selected`

```bp
test "locale: q zero is never selected" {
    try assertLocale(@src(),
        ["rakun.i18n.locales=pt-BR,en,es", "rakun.i18n.defaultLocale=pt-BR"],
        "GET /about Accept-Language: en;q=0,fr");
}
```

`modules/rakun-app/test/__snapshots__/locale/q-zero-is-never-selected.snap`
```
negotiated pt-BR from default
redirect 307 /pt-BR/about
```

### `locale: the highest q supported tag wins regardless of header order`

```bp
test "locale: the highest q supported tag wins regardless of header order" {
    try assertLocale(@src(),
        ["rakun.i18n.locales=pt-BR,en,es", "rakun.i18n.defaultLocale=pt-BR"],
        "GET /about Accept-Language: es;q=0.8,de,en;q=0.9");
}
```

`modules/rakun-app/test/__snapshots__/locale/the-highest-q-supported-tag-wins-regardless-of-header-order.snap`
```
negotiated en from accept-language
redirect 307 /en/about
```

### `locale: sitemap xml is on the default exclude list`

```bp
test "locale: sitemap xml is on the default exclude list" {
    try assertLocale(@src(),
        ["rakun.i18n.locales=pt-BR,en,es", "rakun.i18n.defaultLocale=pt-BR"],
        "GET /sitemap.xml Accept-Language: en");
}
```

`modules/rakun-app/test/__snapshots__/locale/sitemap-xml-is-on-the-default-exclude-list.snap`
```
negotiated pt-BR from default
serve /sitemap.xml
```

## 66-rakun-metadata-file-routes — `rakun-app`

**Test file:** `modules/rakun-app/test/metadata_routes_test.bp` · **Snapshots:** `modules/rakun-app/test/__snapshots__/metadata/` · **Target:** erlang · **Pins:** Step 1 the exact sitemap XML with declaration and `urlset` namespace + `Content-Type: application/xml`, Step 2 the exact robots text + `/robots.txt` is 404 with no `registerRobots`, Step 3 `/manifest.webmanifest` with `application/manifest+json` + `"icons": []` kept, Step 4 `favicon.ico` served at `/favicon.ico` as `image/x-icon`, Step 5 a dynamic image route with front 70 absent answers 501 naming it, Step 6 a metadata file inside `_private` is not registered

> helper gap: `assertMetadataRoutes` takes a tree, not a source, so the producers are the helper's stubs: `sitemap.bp` → one entry per static `P` pattern in the tree at origin `https://example.com` with `lastModified` from the test clock, `robots.bp` → `RobotRule("*", allow: ["/"], disallow: [])` plus `sitemap` when `sitemap.bp` is in the tree, `manifest.bp` → `WebManifest("app", "app", "/", "standalone", "#ffffff", "#ffffff", icons: [])`. Static files in the tree are zero-length fixtures and render as `(binary 0 bytes)`; a 404 has no content type and renders `-`. The 501 message is (text per README § Step 5 — "a body naming front 70").

### `metadata: sitemap renders the tree pages as xml`

```bp
test "metadata: sitemap renders the tree pages as xml" {
    try assertMetadataRoutes(@src(),
        ["app/layout.bp", "app/page.bp", "app/about/page.bp", "app/blog/[slug]/page.bp", "app/sitemap.bp"],
        "GET /sitemap.xml");
}
```

`modules/rakun-app/test/__snapshots__/metadata/sitemap-renders-the-tree-pages-as-xml.snap`
```
/sitemap.xml -> 200 application/xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url><loc>https://example.com/</loc><lastmod>2026-01-01T00:00:00Z</lastmod></url>
<url><loc>https://example.com/about</loc><lastmod>2026-01-01T00:00:00Z</lastmod></url>
</urlset>
```

### `metadata: robots answers 404 when nothing is registered`

```bp
test "metadata: robots answers 404 when nothing is registered" {
    try assertMetadataRoutes(@src(),
        ["app/layout.bp", "app/page.bp", "app/sitemap.bp"],
        "GET /robots.txt");
}
```

`modules/rakun-app/test/__snapshots__/metadata/robots-answers-404-when-nothing-is-registered.snap`
```
/robots.txt -> 404 -
```

### `metadata: robots renders its rules and the sitemap line as text`

```bp
test "metadata: robots renders its rules and the sitemap line as text" {
    try assertMetadataRoutes(@src(),
        ["app/layout.bp", "app/page.bp", "app/sitemap.bp", "app/robots.bp"],
        "GET /robots.txt");
}
```

`modules/rakun-app/test/__snapshots__/metadata/robots-renders-its-rules-and-the-sitemap-line-as-text.snap`
```
/robots.txt -> 200 text/plain
User-Agent: *
Allow: /

Sitemap: https://example.com/sitemap.xml
```

### `metadata: the manifest is served as manifest json with an empty icons array`

```bp
test "metadata: the manifest is served as manifest json with an empty icons array" {
    try assertMetadataRoutes(@src(),
        ["app/layout.bp", "app/page.bp", "app/manifest.bp"],
        "GET /manifest.webmanifest");
}
```

`modules/rakun-app/test/__snapshots__/metadata/the-manifest-is-served-as-manifest-json-with-an-empty-icons-array.snap`
```
/manifest.webmanifest -> 200 application/manifest+json
{"name":"app","short_name":"app","start_url":"/","display":"standalone","background_color":"#ffffff","theme_color":"#ffffff","icons":[]}
```

### `metadata: favicon is served from the root`

```bp
test "metadata: favicon is served from the root" {
    try assertMetadataRoutes(@src(),
        ["app/layout.bp", "app/page.bp", "app/favicon.ico"],
        "GET /favicon.ico");
}
```

`modules/rakun-app/test/__snapshots__/metadata/favicon-is-served-from-the-root.snap`
```
/favicon.ico -> 200 image/x-icon
(binary 0 bytes)
```

### `metadata: a dynamic image route with front 70 absent answers 501`

```bp
test "metadata: a dynamic image route with front 70 absent answers 501" {
    try assertMetadataRoutes(@src(),
        ["app/layout.bp", "app/opengraph-image.png", "app/blog/[slug]/page.bp", "app/blog/[slug]/opengraph-image.bp"],
        "GET /blog/hello/opengraph-image");
}
```

`modules/rakun-app/test/__snapshots__/metadata/a-dynamic-image-route-with-front-70-absent-answers-501.snap`
```
/blog/hello/opengraph-image -> 501 text/plain
dynamic image routes need front 70 (image rendering), which is not present
```

### `metadata: a file inside a private folder is not a route`

```bp
test "metadata: a file inside a private folder is not a route" {
    try assertMetadataRoutes(@src(),
        ["app/layout.bp", "app/page.bp", "app/_assets/icon.png"],
        "GET /_assets/icon.png");
}
```

`modules/rakun-app/test/__snapshots__/metadata/a-file-inside-a-private-folder-is-not-a-route.snap`
```
/_assets/icon.png -> 404 -
```

## 07-rakun-middleware — `rakun-web`

**Test file:** `modules/rakun-web/test/middleware_test.bp` (suite `middleware`) · `modules/rakun-web/test/cors_test.bp` (suite `cors`) · `modules/rakun-web/test/error_test.bp` (suite `problem`) · **Snapshots:** `modules/rakun-web/test/__snapshots__/{middleware,cors,problem}/` · **Target:** erlang · **Pins:** Step 1 order −10/0/10 in and reverse out, same-order registration order, short-circuit, response replaced on the way out; Step 2 `#[middleware]` at −50 with `#[matcher]`, 307/308 redirects, rewrite with `req.path` unchanged, `Next.pass()` ≡ `chain.next`, sentinel never on the wire, non-matching path skipped; Step 3 allowed origin echoed (not `*`), non-allowed origin gets nothing, preflight answered without the handler, `Vary: Origin`; Step 4 tagged raise → mapped `ProblemDetail` as `application/problem+json`, unmatched raise → 500 `about:blank` + digest + no reason, two advice types contribute

> helper gap: boot-time refusals (`*` + `allowCredentials`, two `#[middleware]`, `withHeader("Set-Cookie", …)`, `br` compression) have no helper — they stay in front 50's CLI suite. Compression, `Accept` negotiation and shutdown are not renderable by any helper in the table.

### `middleware: three filters with orders -10 0 10 run in order in and reverse out`

```bp
test "middleware: three filters with orders -10 0 10 run in order in and reverse out" {
    try assertMiddleware(@src(),
        \\ import {Request, Response, rkSetReplyHeader, managed, restController, route, getMapping} from "rakun";
        \\ import {Filter, Chain, filter, order} from "rakun-web";
        \\
        \\ #[filter]
        \\ #[order(-10)]
        \\ #[managed]
        \\ pub type A implement Filter {
        \\     pub fn handle(self: Self, req: Request, chain: Chain) -> Response {
        \\         val out = chain.next(req);
        \\         val _h = rkSetReplyHeader("X-Seen", "A");
        \\         return out;
        \\     }
        \\ }
        \\
        \\ #[filter]
        \\ #[order(0)]
        \\ #[managed]
        \\ pub type B implement Filter {
        \\     pub fn handle(self: Self, req: Request, chain: Chain) -> Response {
        \\         val out = chain.next(req);
        \\         val _h = rkSetReplyHeader("X-Seen", "B");
        \\         return out;
        \\     }
        \\ }
        \\
        \\ #[filter]
        \\ #[order(10)]
        \\ #[managed]
        \\ pub type C implement Filter {
        \\     pub fn handle(self: Self, req: Request, chain: Chain) -> Response {
        \\         val out = chain.next(req);
        \\         val _h = rkSetReplyHeader("X-Seen", "C");
        \\         return out;
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api")]
        \\ #[managed]
        \\ pub type PingApi {
        \\     #[getMapping("/ping")]
        \\     pub fn ping(self: Self, req: Request) -> Response {
        \\         return Response.ok("pong");
        \\     }
        \\ }
        , ["GET /api/ping"]);
}
```

`modules/rakun-web/test/__snapshots__/middleware/three-filters-with-orders-10-0-10-run-in-order-in-and-reverse-out.snap`
```
order -10 A
order 0 B
order 10 C
> A pass
> B pass
> C pass
= 200 X-Seen=A
```

### `middleware: two filters with the same order run in registration order`

```bp
test "middleware: two filters with the same order run in registration order" {
    try assertMiddleware(@src(),
        \\ import {Request, Response, rkSetReplyHeader, managed, restController, route, getMapping} from "rakun";
        \\ import {Filter, Chain, filter, order} from "rakun-web";
        \\
        \\ #[filter]
        \\ #[order(0)]
        \\ #[managed]
        \\ pub type First implement Filter {
        \\     pub fn handle(self: Self, req: Request, chain: Chain) -> Response {
        \\         val out = chain.next(req);
        \\         val _h = rkSetReplyHeader("X-Seen", "First");
        \\         return out;
        \\     }
        \\ }
        \\
        \\ #[filter]
        \\ #[order(0)]
        \\ #[managed]
        \\ pub type Second implement Filter {
        \\     pub fn handle(self: Self, req: Request, chain: Chain) -> Response {
        \\         val out = chain.next(req);
        \\         val _h = rkSetReplyHeader("X-Seen", "Second");
        \\         return out;
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api")]
        \\ #[managed]
        \\ pub type PingApi {
        \\     #[getMapping("/ping")]
        \\     pub fn ping(self: Self, req: Request) -> Response {
        \\         return Response.ok("pong");
        \\     }
        \\ }
        , ["GET /api/ping"]);
}
```

`modules/rakun-web/test/__snapshots__/middleware/two-filters-with-the-same-order-run-in-registration-order.snap`
```
order 0 First
order 0 Second
> First pass
> Second pass
= 200 X-Seen=First
```

### `middleware: a filter that does not call chain.next short-circuits and the handler never runs`

```bp
test "middleware: a filter that does not call chain.next short-circuits and the handler never runs" {
    try assertMiddleware(@src(),
        \\ import {Request, Response, rkSetReplyHeader, managed, restController, route, getMapping} from "rakun";
        \\ import {Filter, Chain, filter, order} from "rakun-web";
        \\
        \\ #[filter]
        \\ #[order(0)]
        \\ #[managed]
        \\ pub type Gate implement Filter {
        \\     pub fn handle(self: Self, req: Request, chain: Chain) -> Response {
        \\         return Response.withStatus(401, "denied");
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api")]
        \\ #[managed]
        \\ pub type PingApi {
        \\     #[getMapping("/ping")]
        \\     pub fn ping(self: Self, req: Request) -> Response {
        \\         val _h = rkSetReplyHeader("X-Handler", "ran");
        \\         return Response.ok("pong");
        \\     }
        \\ }
        , ["GET /api/ping"]);
}
```

`modules/rakun-web/test/__snapshots__/middleware/a-filter-that-does-not-call-chain-next-short-circuits-and-the-handler-never-runs.snap`
```
order 0 Gate
> Gate short 401
= 401
```

### `middleware: a filter reads the response the chain returned and answers a different one`

```bp
test "middleware: a filter reads the response the chain returned and answers a different one" {
    try assertMiddleware(@src(),
        \\ import {Request, Response, managed, restController, route, getMapping} from "rakun";
        \\ import {Filter, Chain, filter, order} from "rakun-web";
        \\
        \\ #[filter]
        \\ #[order(-10)]
        \\ #[managed]
        \\ pub type Downgrade implement Filter {
        \\     pub fn handle(self: Self, req: Request, chain: Chain) -> Response {
        \\         val out = chain.next(req);
        \\         val broken = out.status >= 500;
        \\         return if (broken) Response.withStatus(503, "degraded") else out;
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api")]
        \\ #[managed]
        \\ pub type BoomApi {
        \\     #[getMapping("/boom")]
        \\     pub fn boom(self: Self, req: Request) -> Response {
        \\         return Response.withStatus(500, "boom");
        \\     }
        \\ }
        , ["GET /api/boom"]);
}
```

`modules/rakun-web/test/__snapshots__/middleware/a-filter-reads-the-response-the-chain-returned-and-answers-a-different-one.snap`
```
order -10 Downgrade
> Downgrade pass
= 503
```

### `middleware: middleware.bp registers at -50 with a matcher redirects with 307 and skips a non-matching path`

```bp
test "middleware: middleware.bp registers at -50 with a matcher redirects with 307 and skips a non-matching path" {
    try assertMiddleware(@src(),
        \\ import {Request, Response, rkSetReplyHeader, managed, restController, route, getMapping} from "rakun";
        \\ import {Filter, Chain, Next, middleware, matcher, filter, order} from "rakun-web";
        \\
        \\ #[middleware]
        \\ #[matcher("/dashboard/:path*")]
        \\ pub fn middleware(req: Request, chain: Chain) -> Response {
        \\     val token = req.header("authorization");
        \\     val unauthenticated = token == "";
        \\     if (unauthenticated) {
        \\         return Next.redirect("/login");
        \\     };
        \\     return chain.next(req);
        \\ }
        \\
        \\ #[filter]
        \\ #[managed]
        \\ pub type AppFilter implement Filter {
        \\     pub fn handle(self: Self, req: Request, chain: Chain) -> Response {
        \\         val _h = rkSetReplyHeader("X-App", "seen");
        \\         return chain.next(req);
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/")]
        \\ #[managed]
        \\ pub type Pages {
        \\     #[getMapping("/dashboard/reports")]
        \\     pub fn reports(self: Self, req: Request) -> Response {
        \\         return Response.ok("reports");
        \\     }
        \\
        \\     #[getMapping("/public/about")]
        \\     pub fn about(self: Self, req: Request) -> Response {
        \\         return Response.ok("about");
        \\     }
        \\ }
        , ["GET /dashboard/reports", "GET /public/about"]);
}
```

`modules/rakun-web/test/__snapshots__/middleware/middleware-bp-registers-at-50-with-a-matcher-redirects-with-307-and-skips-a-non-matching-path.snap`
```
order -50 middleware matcher /dashboard/:path*
order 0 AppFilter
> middleware redirect 307 /login
= 307 Location=/login
> AppFilter pass
= 200 X-App=seen
```

### `middleware: permanentRedirect answers 308 rewrite keeps req.path and pass equals next`

```bp
test "middleware: permanentRedirect answers 308 rewrite keeps req.path and pass equals next" {
    try assertMiddleware(@src(),
        \\ import {Request, Response, rkSetReplyHeader, managed, restController, route, getMapping} from "rakun";
        \\ import {Chain, Next, middleware} from "rakun-web";
        \\
        \\ #[middleware]
        \\ pub fn middleware(req: Request, chain: Chain) -> Response {
        \\     val retired = req.path == "/old";
        \\     if (retired) {
        \\         return Next.permanentRedirect("/new");
        \\     };
        \\     val legacy = req.path == "/dashboard/old-reports";
        \\     if (legacy) {
        \\         return Next.rewrite("/dashboard/reports");
        \\     };
        \\     val quiet = req.path == "/a";
        \\     if (quiet) {
        \\         return Next.pass();
        \\     };
        \\     return chain.next(req);
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/")]
        \\ #[managed]
        \\ pub type Pages {
        \\     #[getMapping("/dashboard/reports")]
        \\     pub fn reports(self: Self, req: Request) -> Response {
        \\         val _h = rkSetReplyHeader("X-Path", req.path);
        \\         return Response.ok("reports");
        \\     }
        \\
        \\     #[getMapping("/a")]
        \\     pub fn a(self: Self, req: Request) -> Response {
        \\         val _h = rkSetReplyHeader("X-Handler", "ran");
        \\         return Response.ok("a");
        \\     }
        \\
        \\     #[getMapping("/b")]
        \\     pub fn b(self: Self, req: Request) -> Response {
        \\         val _h = rkSetReplyHeader("X-Handler", "ran");
        \\         return Response.ok("b");
        \\     }
        \\ }
        , ["GET /old", "GET /dashboard/old-reports", "GET /a", "GET /b"]);
}
```

`modules/rakun-web/test/__snapshots__/middleware/permanentredirect-answers-308-rewrite-keeps-req-path-and-pass-equals-next.snap`
```
order -50 middleware
> middleware redirect 308 /new
= 308 Location=/new
> middleware rewrite /dashboard/reports
= 200 X-Path=/dashboard/old-reports
> middleware pass
= 200 X-Handler=ran
> middleware pass
= 200 X-Handler=ran
```

### `cors: a simple request from an allowed origin echoes that origin`

Config lines are `CorsPolicy` fields as `key=value` (name per README § *CORS*).

```bp
test "cors: a simple request from an allowed origin echoes that origin" {
    try assertCors(@src(),
        ["allowedOrigins=https://app.example.com", "allowedMethods=GET,POST", "allowedHeaders=Content-Type", "maxAgeSeconds=600", "allowCredentials=false"],
        "GET /api/orders Origin: https://app.example.com");
}
```

`modules/rakun-web/test/__snapshots__/cors/a-simple-request-from-an-allowed-origin-echoes-that-origin.snap`
```
simple
allowed true
Access-Control-Allow-Origin: https://app.example.com
Vary: Origin
```

### `cors: a request from a non-allowed origin gets no cors header and no policy sets none`

```bp
test "cors: a request from a non-allowed origin gets no cors header and no policy sets none" {
    try assertCors(@src(),
        ["allowedOrigins=https://app.example.com", "allowedMethods=GET,POST", "allowedHeaders=Content-Type", "maxAgeSeconds=600", "allowCredentials=false"],
        "GET /api/orders Origin: https://evil.example");
}
```

`modules/rakun-web/test/__snapshots__/cors/a-request-from-a-non-allowed-origin-gets-no-cors-header-and-no-policy-sets-none.snap`
```
simple
allowed false
```

### `cors: an options preflight is answered with allow-methods allow-headers and max-age`

```bp
test "cors: an options preflight is answered with allow-methods allow-headers and max-age" {
    try assertCors(@src(),
        ["allowedOrigins=https://app.example.com", "allowedMethods=GET,POST", "allowedHeaders=Content-Type", "maxAgeSeconds=600", "allowCredentials=false"],
        "OPTIONS /api/orders Origin: https://app.example.com Access-Control-Request-Method: POST Access-Control-Request-Headers: Content-Type");
}
```

`modules/rakun-web/test/__snapshots__/cors/an-options-preflight-is-answered-with-allow-methods-allow-headers-and-max-age.snap`
```
preflight
allowed true
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Methods: GET,POST
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Max-Age: 600
Vary: Origin
```

### `problem: a tagged raise becomes the mapped problem detail`

```bp
test "problem: a tagged raise becomes the mapped problem detail" {
    try assertProblem(@src(),
        \\ import {Request, Response, service, managed, restController, route, getMapping} from "rakun";
        \\ import {ProblemDetail, controllerAdvice, exceptionHandler, raiseProblem} from "rakun-web";
        \\
        \\ #[controllerAdvice]
        \\ #[managed]
        \\ pub type ApiProblems {
        \\     #[exceptionHandler("order.not-found")]
        \\     pub fn notFound(self: Self, tag: string, detail: string) -> ProblemDetail {
        \\         return ProblemDetail(
        \\             typeUri: "https://example.com/problems/order-not-found",
        \\             title: "Order not found",
        \\             status: 404,
        \\             detail: detail,
        \\             instance: "",
        \\         );
        \\     }
        \\ }
        \\
        \\ #[controllerAdvice]
        \\ #[managed]
        \\ pub type LockProblems {
        \\     #[exceptionHandler("order.locked")]
        \\     pub fn locked(self: Self, tag: string, detail: string) -> ProblemDetail {
        \\         return ProblemDetail(
        \\             typeUri: "https://example.com/problems/order-locked",
        \\             title: "Order is locked",
        \\             status: 409,
        \\             detail: detail,
        \\             instance: "",
        \\         );
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ pub type OrderLookup {
        \\     pub fn find(self: Self, id: string) -> string {
        \\         val locked = id == "o-2";
        \\         if (locked) raiseProblem("order.locked", "order " + id + " is locked");
        \\         val known = ["o-1"];
        \\         val hit = known.indexOf(id);
        \\         if (hit == -1) raiseProblem("order.not-found", "no order " + id);
        \\         return "order " + id;
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/orders")]
        \\ #[managed]
        \\ pub type OrderApi(
        \\     lookup: OrderLookup,
        \\ ) {
        \\     #[getMapping("/:id")]
        \\     pub fn show(self: Self, req: Request) -> Response {
        \\         return Response.json(self.lookup.find(req.param("id")));
        \\     }
        \\ }
        , "GET /api/orders/o-9");
}
```

`modules/rakun-web/test/__snapshots__/problem/a-tagged-raise-becomes-the-mapped-problem-detail.snap`
```
content-type: application/problem+json
detail: no order o-9
instance: /api/orders/o-9
status: 404
title: Order not found
type: https://example.com/problems/order-not-found
```

### `problem: a second advice type contributes its own tag`

Same source as the previous case, request `"GET /api/orders/o-2"`.

`modules/rakun-web/test/__snapshots__/problem/a-second-advice-type-contributes-its-own-tag.snap`
```
content-type: application/problem+json
detail: order o-2 is locked
instance: /api/orders/o-2
status: 409
title: Order is locked
type: https://example.com/problems/order-locked
```

### `problem: an unmatched raise answers 500 with about blank a digest and no reason text`

The digest key is the correlation digest of README § *RFC 9457 problem details* (name per README; it is the request id from the test seed).

```bp
test "problem: an unmatched raise answers 500 with about blank a digest and no reason text" {
    try assertProblem(@src(),
        \\ import {Request, Response, managed, restController, route, getMapping} from "rakun";
        \\
        \\ #[restController]
        \\ #[route("/api")]
        \\ #[managed]
        \\ pub type BoomApi {
        \\     #[getMapping("/boom")]
        \\     pub fn boom(self: Self, req: Request) -> Response {
        \\         val zero = req.path.length() - req.path.length();
        \\         val q = 10 / zero;
        \\         return Response.ok(q.toString());
        \\     }
        \\ }
        , "GET /api/boom");
}
```

`modules/rakun-web/test/__snapshots__/problem/an-unmatched-raise-answers-500-with-about-blank-a-digest-and-no-reason-text.snap`
```
content-type: application/problem+json
digest: req-0001
instance: /api/boom
status: 500
title: Internal Server Error
type: about:blank
```

## 08-rakun-data-sql — `rakun-data`

**Test file:** `modules/rakun-data/test/sql/query_test.bp` · **Snapshots:** `modules/rakun-data/test/sql/__snapshots__/query/` · **Target:** erlang (ETS arm, per README § *Test plan*) · **Pins:** Step 4 `:name` binds by name, same name twice binds once, hostile value stays a value; Step 5 `#[query]` emits `__rkQuery_<name>()` returning the statement verbatim; Step 6 `#[transactional]` emits `<Type>Tx` — commit when the thunk returns, rollback when it raises, nested `sql.transaction` joins (one commit), `#[noTransaction]` plain forward, bare `<Type>` is not transactional

> helper gap: pool behaviour (Step 3), `single`/`Row.int` failures, `tryQuery` vs `query`, futures and the `db` health indicator render through no helper here — they stay in `pool_test.bp`/`template_test.bp` as plain asserts.

Shared source for every case below (`__rkQuery_*` helpers are emitted by `#[query]`; `OrderServiceTx` by `#[transactional]`):

```bp
\\ import {managed, repository, service} from "rakun";
\\ import {raiseProblem} from "rakun-web";
\\ import {SqlTemplate, Rows, Row, Param, Tx, param, query, transactional, noTransaction} from "rakun-data";
\\
\\ #[repository]
\\ #[managed]
\\ pub type UserRepository(
\\     sql: SqlTemplate,
\\ ) {
\\     #[query("SELECT id, name, email FROM users WHERE id = :id")]
\\     pub fn findById(self: Self, id: i32) -> ?Row {
\\         return self.sql.single(__rkQuery_findById(), [param("id", id.toString())]);
\\     }
\\
\\     #[query("SELECT id FROM users WHERE id = :id OR parent = :id")]
\\     pub fn findFamily(self: Self, id: i32) -> Rows {
\\         return self.sql.query(__rkQuery_findFamily(), [param("id", id.toString())]);
\\     }
\\
\\     #[query("INSERT INTO users (id, name, email) VALUES (:id, :name, :email)")]
\\     pub fn insert(self: Self, id: i32, name: string, email: string) -> i32 {
\\         return self.sql.update(__rkQuery_insert(), [
\\             param("id", id.toString()),
\\             param("name", name),
\\             param("email", email),
\\         ]);
\\     }
\\ }
\\
\\ #[repository]
\\ #[managed]
\\ pub type OrderRepository(
\\     sql: SqlTemplate,
\\ ) {
\\     #[query("SELECT id, user_id, total, state FROM orders WHERE user_id = :userId ORDER BY id")]
\\     pub fn findByUser(self: Self, userId: i32) -> Rows {
\\         return self.sql.query(__rkQuery_findByUser(), [param("userId", userId.toString())]);
\\     }
\\
\\     #[query("INSERT INTO orders (id, user_id, total, state) VALUES (:id, :userId, :total, 'placed')")]
\\     pub fn create(self: Self, id: i32, userId: i32, total: i32) -> i32 {
\\         return self.sql.update(__rkQuery_create(), [
\\             param("id", id.toString()),
\\             param("userId", userId.toString()),
\\             param("total", total.toString()),
\\         ]);
\\     }
\\
\\     #[query("INSERT INTO order_audit (order_id, action) VALUES (:orderId, :action)")]
\\     pub fn audit(self: Self, orderId: i32, action: string) -> i32 {
\\         return self.sql.update(__rkQuery_audit(), [
\\             param("orderId", orderId.toString()),
\\             param("action", action),
\\         ]);
\\     }
\\
\\     #[query("SELECT COUNT(*) AS n FROM orders")]
\\     pub fn count(self: Self) -> i32 {
\\         val row = self.sql.single(__rkQuery_count(), []);
\\         var n = 0;
\\         if (row) { r -> n = r.int("n"); };
\\         return n;
\\     }
\\ }
\\
\\ #[service]
\\ #[transactional]
\\ #[managed]
\\ pub type OrderService(
\\     sql: SqlTemplate,
\\     users: UserRepository,
\\     orders: OrderRepository,
\\ ) {
\\     pub fn place(self: Self, userId: i32, total: i32) -> i32 {
\\         val owner = self.users.findById(userId);
\\         var exists = false;
\\         if (owner) { u -> exists = true; };
\\         if (!exists) raiseProblem("user.not-found", "no user ${userId}");
\\         val id = self.orders.count() + 1;
\\         val _o = self.orders.create(id, userId, total);
\\         val _a = self.orders.audit(id, "placed");
\\         return id;
\\     }
\\
\\     pub fn refund(self: Self, orderId: i32) -> i32 {
\\         return self.sql.transaction({ tx ->
\\             val _u = tx.update("UPDATE orders SET state = 'refunded' WHERE id = :id", [param("id", orderId.toString())]);
\\             val _a = tx.update("INSERT INTO order_audit (order_id, action) VALUES (:id, 'refunded')", [param("id", orderId.toString())]);
\\             orderId;
\\         });
\\     }
\\
\\     #[noTransaction]
\\     pub fn history(self: Self, userId: i32) -> string {
\\         val rows = self.orders.findByUser(userId);
\\         return rows.toList().map({ r -> r.get("id") + ":" + r.get("total") }).join(",");
\\     }
\\ }
```

### `query: a named parameter binds by name and the statement is emitted verbatim`

```bp
test "query: a named parameter binds by name and the statement is emitted verbatim" {
    try assertQuery(@src(),
        \\ <shared source>
        , ["UserRepository.findById(1)"]);
}
```

`modules/rakun-data/test/sql/__snapshots__/query/a-named-parameter-binds-by-name-and-the-statement-is-emitted-verbatim.snap`
```
UserRepository.findById(1) -> SELECT id, name, email FROM users WHERE id = :id  params=[id=1]
```

### `query: the same name used twice binds once and is passed once`

```bp
test "query: the same name used twice binds once and is passed once" {
    try assertQuery(@src(),
        \\ <shared source>
        , ["UserRepository.findFamily(7)"]);
}
```

`modules/rakun-data/test/sql/__snapshots__/query/the-same-name-used-twice-binds-once-and-is-passed-once.snap`
```
UserRepository.findFamily(7) -> SELECT id FROM users WHERE id = :id OR parent = :id  params=[id=7]
```

### `query: a hostile value is bound as a value and changes nothing`

```bp
test "query: a hostile value is bound as a value and changes nothing" {
    try assertQuery(@src(),
        \\ <shared source>
        , ["UserRepository.insert(1, \"'; DROP TABLE users; --\", \"a@example.com\")", "UserRepository.findById(1)"]);
}
```

`modules/rakun-data/test/sql/__snapshots__/query/a-hostile-value-is-bound-as-a-value-and-changes-nothing.snap`
```
UserRepository.insert(1, "'; DROP TABLE users; --", "a@example.com") -> INSERT INTO users (id, name, email) VALUES (:id, :name, :email)  params=[id=1, name='; DROP TABLE users; --, email=a@example.com]
UserRepository.findById(1) -> SELECT id, name, email FROM users WHERE id = :id  params=[id=1]
```

### `query: a transactional proxy call is wrapped in begin and commit`

```bp
test "query: a transactional proxy call is wrapped in begin and commit" {
    try assertQuery(@src(),
        \\ <shared source>
        , ["UserRepository.insert(1, \"ana\", \"a@example.com\")", "OrderServiceTx.place(1, 250)"]);
}
```

`modules/rakun-data/test/sql/__snapshots__/query/a-transactional-proxy-call-is-wrapped-in-begin-and-commit.snap`
```
UserRepository.insert(1, "ana", "a@example.com") -> INSERT INTO users (id, name, email) VALUES (:id, :name, :email)  params=[id=1, name=ana, email=a@example.com]
begin
UserRepository.findById(1) -> SELECT id, name, email FROM users WHERE id = :id  params=[id=1]
OrderRepository.count() -> SELECT COUNT(*) AS n FROM orders  params=[]
OrderRepository.create(1, 1, 250) -> INSERT INTO orders (id, user_id, total, state) VALUES (:id, :userId, :total, 'placed')  params=[id=1, userId=1, total=250]
OrderRepository.audit(1, "placed") -> INSERT INTO order_audit (order_id, action) VALUES (:orderId, :action)  params=[orderId=1, action=placed]
commit
```

### `query: a raise inside the proxy rolls back and the raise propagates`

```bp
test "query: a raise inside the proxy rolls back and the raise propagates" {
    try assertQuery(@src(),
        \\ <shared source>
        , ["OrderServiceTx.place(9, 10)"]);
}
```

`modules/rakun-data/test/sql/__snapshots__/query/a-raise-inside-the-proxy-rolls-back-and-the-raise-propagates.snap`
```
begin
UserRepository.findById(9) -> SELECT id, name, email FROM users WHERE id = :id  params=[id=9]
rollback
```

### `query: a nested transaction joins the open one with a single commit`

```bp
test "query: a nested transaction joins the open one with a single commit" {
    try assertQuery(@src(),
        \\ <shared source>
        , ["OrderServiceTx.refund(1)"]);
}
```

`modules/rakun-data/test/sql/__snapshots__/query/a-nested-transaction-joins-the-open-one-with-a-single-commit.snap`
```
begin
OrderService.refund(1) -> UPDATE orders SET state = 'refunded' WHERE id = :id  params=[id=1]
OrderService.refund(1) -> INSERT INTO order_audit (order_id, action) VALUES (:id, 'refunded')  params=[id=1]
commit
```

### `query: noTransaction emits a plain forward`

```bp
test "query: noTransaction emits a plain forward" {
    try assertQuery(@src(),
        \\ <shared source>
        , ["OrderServiceTx.history(1)"]);
}
```

`modules/rakun-data/test/sql/__snapshots__/query/notransaction-emits-a-plain-forward.snap`
```
OrderRepository.findByUser(1) -> SELECT id, user_id, total, state FROM orders WHERE user_id = :userId ORDER BY id  params=[userId=1]
```

### `query: injecting the bare type gets no transaction`

```bp
test "query: injecting the bare type gets no transaction" {
    try assertQuery(@src(),
        \\ <shared source>
        , ["UserRepository.insert(1, \"ana\", \"a@example.com\")", "OrderService.place(1, 250)"]);
}
```

`modules/rakun-data/test/sql/__snapshots__/query/injecting-the-bare-type-gets-no-transaction.snap`
```
UserRepository.insert(1, "ana", "a@example.com") -> INSERT INTO users (id, name, email) VALUES (:id, :name, :email)  params=[id=1, name=ana, email=a@example.com]
UserRepository.findById(1) -> SELECT id, name, email FROM users WHERE id = :id  params=[id=1]
OrderRepository.count() -> SELECT COUNT(*) AS n FROM orders  params=[]
OrderRepository.create(1, 1, 250) -> INSERT INTO orders (id, user_id, total, state) VALUES (:id, :userId, :total, 'placed')  params=[id=1, userId=1, total=250]
OrderRepository.audit(1, "placed") -> INSERT INTO order_audit (order_id, action) VALUES (:orderId, :action)  params=[orderId=1, action=placed]
```

## 09-rakun-data-nosql — `rakun-data`

**Test file:** `modules/rakun-data/test/nosql/store_test.bp` · **Snapshots:** `modules/rakun-data/test/nosql/__snapshots__/store/` · **Target:** erlang (ETS arm under the `test` profile) · **Pins:** Step 1 `increment` on an absent key starts at 0, `popRight` on an empty list answers `null` (not `""`), `putExpiring` + `ttl`; Step 2 filter subset `equality`/`$in`/`$gt`/`$lt`/`$exists` and an unsupported operator fails naming it; Step 5 `#[documentQuery]` + `bind` escapes the dialect's quote so a hostile value stays a value

Ops are `<store>.<op>(<args>)` with `kv` = `__rkMake_KeyValueStore()` and `docs` = `__rkMake_DocumentStore()`; a repository op names the repository and renders the store call it makes. Shared source:

```bp
\\ import {managed, repository} from "rakun";
\\ import {KeyValueStore, DocumentStore, documentQuery, bind, param} from "rakun-data";
\\
\\ #[repository]
\\ #[managed]
\\ pub type ProfileRepository(
\\     docs: DocumentStore,
\\ ) {
\\     #[documentQuery("{\"email\": \":email\"}")]
\\     pub fn findByEmail(self: Self, email: string) -> ?string {
\\         val filter = bind(__rkQuery_findByEmail(), [param("email", email)]);
\\         return self.docs.find("profiles", filter).first();
\\     }
\\ }
```

### `store: put get and remove round-trip and a removed key reads null`

```bp
test "store: put get and remove round-trip and a removed key reads null" {
    try assertStore(@src(),
        \\ <shared source>
        , ["kv.put(\"k\", \"v\")", "kv.get(\"k\")", "kv.remove(\"k\")", "kv.get(\"k\")"]);
}
```

`modules/rakun-data/test/nosql/__snapshots__/store/put-get-and-remove-round-trip-and-a-removed-key-reads-null.snap`
```
kv.put("k", "v") -> 1
kv.get("k") -> v
kv.remove("k") -> 1
kv.get("k") -> null
```

### `store: increment on an absent key starts at zero`

```bp
test "store: increment on an absent key starts at zero" {
    try assertStore(@src(),
        \\ <shared source>
        , ["kv.increment(\"counter:new\", 1)", "kv.increment(\"counter:new\", 2)"]);
}
```

`modules/rakun-data/test/nosql/__snapshots__/store/increment-on-an-absent-key-starts-at-zero.snap`
```
kv.increment("counter:new", 1) -> 1
kv.increment("counter:new", 2) -> 3
```

### `store: an expiring key reports its ttl at the fixed clock`

```bp
test "store: an expiring key reports its ttl at the fixed clock" {
    try assertStore(@src(),
        \\ <shared source>
        , ["kv.putExpiring(\"s:1\", \"user-7\", 60)", "kv.ttl(\"s:1\")", "kv.get(\"s:1\")", "kv.ttl(\"s:none\")"]);
}
```

`modules/rakun-data/test/nosql/__snapshots__/store/an-expiring-key-reports-its-ttl-at-the-fixed-clock.snap`
```
kv.putExpiring("s:1", "user-7", 60) -> 1
kv.ttl("s:1") -> 60
kv.get("s:1") -> user-7
kv.ttl("s:none") -> -1
```

### `store: lists and hashes and popRight on an empty list answers null`

```bp
test "store: lists and hashes and popRight on an empty list answers null" {
    try assertStore(@src(),
        \\ <shared source>
        , ["kv.pushLeft(\"l\", \"a\")", "kv.popRight(\"l\")", "kv.popRight(\"l\")", "kv.fieldPut(\"h\", \"f\", \"1\")", "kv.fieldGet(\"h\", \"f\")", "kv.fieldGet(\"h\", \"g\")"]);
}
```

`modules/rakun-data/test/nosql/__snapshots__/store/lists-and-hashes-and-popright-on-an-empty-list-answers-null.snap`
```
kv.pushLeft("l", "a") -> 1
kv.popRight("l") -> a
kv.popRight("l") -> null
kv.fieldPut("h", "f", "1") -> 1
kv.fieldGet("h", "f") -> 1
kv.fieldGet("h", "g") -> null
```

### `store: documents insert find replace remove and count`

```bp
test "store: documents insert find replace remove and count" {
    try assertStore(@src(),
        \\ <shared source>
        , [
            "docs.insert(\"profiles\", \"p-1\", \"{\\\"plan\\\": \\\"pro\\\"}\")",
            "docs.findById(\"profiles\", \"p-1\")",
            "docs.replace(\"profiles\", \"p-1\", \"{\\\"plan\\\": \\\"free\\\"}\")",
            "docs.count(\"profiles\", \"{}\")",
            "docs.remove(\"profiles\", \"p-1\")",
            "docs.findById(\"profiles\", \"p-1\")",
            "docs.find(\"nothing\", \"{}\")",
        ]);
}
```

`modules/rakun-data/test/nosql/__snapshots__/store/documents-insert-find-replace-remove-and-count.snap`
```
docs.insert("profiles", "p-1", "{\"plan\": \"pro\"}") -> 1
docs.findById("profiles", "p-1") -> {"plan": "pro"}
docs.replace("profiles", "p-1", "{\"plan\": \"free\"}") -> 1
docs.count("profiles", "{}") -> 1
docs.remove("profiles", "p-1") -> 1
docs.findById("profiles", "p-1") -> null
docs.find("nothing", "{}") -> []
```

### `store: the filter subset works and an unsupported operator fails naming it`

```bp
test "store: the filter subset works and an unsupported operator fails naming it" {
    try assertStore(@src(),
        \\ <shared source>
        , [
            "docs.insert(\"profiles\", \"p-1\", \"{\\\"plan\\\": \\\"pro\\\", \\\"age\\\": 40}\")",
            "docs.insert(\"profiles\", \"p-2\", \"{\\\"plan\\\": \\\"free\\\", \\\"age\\\": 20}\")",
            "docs.find(\"profiles\", \"{\\\"plan\\\": \\\"pro\\\"}\")",
            "docs.find(\"profiles\", \"{\\\"age\\\": {\\\"$gt\\\": 30}}\")",
            "docs.find(\"profiles\", \"{\\\"plan\\\": {\\\"$in\\\": [\\\"pro\\\", \\\"free\\\"]}}\")",
            "docs.count(\"profiles\", \"{\\\"nick\\\": {\\\"$exists\\\": true}}\")",
            "docs.find(\"profiles\", \"{\\\"plan\\\": {\\\"$regex\\\": \\\"p.*\\\"}}\")",
        ]);
}
```

`modules/rakun-data/test/nosql/__snapshots__/store/the-filter-subset-works-and-an-unsupported-operator-fails-naming-it.snap`
```
docs.insert("profiles", "p-1", "{\"plan\": \"pro\", \"age\": 40}") -> 1
docs.insert("profiles", "p-2", "{\"plan\": \"free\", \"age\": 20}") -> 1
docs.find("profiles", "{\"plan\": \"pro\"}") -> [{"plan": "pro", "age": 40}]
docs.find("profiles", "{\"age\": {\"$gt\": 30}}") -> [{"plan": "pro", "age": 40}]
docs.find("profiles", "{\"plan\": {\"$in\": [\"pro\", \"free\"]}}") -> [{"plan": "pro", "age": 40}, {"plan": "free", "age": 20}]
docs.count("profiles", "{\"nick\": {\"$exists\": true}}") -> 0
docs.find("profiles", "{\"plan\": {\"$regex\": \"p.*\"}}") -> error unsupported filter operator $regex
```

### `store: a documentQuery bound filter keeps a hostile value a value`

```bp
test "store: a documentQuery bound filter keeps a hostile value a value" {
    try assertStore(@src(),
        \\ <shared source>
        , [
            "docs.insert(\"profiles\", \"p-1\", \"{\\\"email\\\": \\\"a@example.com\\\", \\\"active\\\": true}\")",
            "ProfileRepository.findByEmail(\"\\\" , \\\"active\\\": false, \\\"x\\\": \\\"\")",
            "ProfileRepository.findByEmail(\"a@example.com\")",
        ]);
}
```

`modules/rakun-data/test/nosql/__snapshots__/store/a-documentquery-bound-filter-keeps-a-hostile-value-a-value.snap`
```
docs.insert("profiles", "p-1", "{\"email\": \"a@example.com\", \"active\": true}") -> 1
docs.find("profiles", "{\"email\": \"\\\" , \\\"active\\\": false, \\\"x\\\": \\\"\"}") -> []
docs.find("profiles", "{\"email\": \"a@example.com\"}") -> [{"email": "a@example.com", "active": true}]
```

## 10-rakun-security-auth — `rakun-security`

**Test file:** `modules/rakun-security/test/security_test.bp` · **Snapshots:** `modules/rakun-security/test/__snapshots__/security/` · **Target:** erlang · **Pins:** Step 1 no rule → authentication required; Step 2 declaration order, first match wins, `/api/public/**` before `/api/**`; Step 3 valid HS256 token → principal + authorities, expired / tampered / `alg: none` rejected identically; Step 6 `<Type>Sec` proxy, `#[secured("ROLE_ADMIN")]` → 403 naming the required authority, comma list admits either, `#[permitAll]` admits anonymous; Step 7 CSRF: `POST` with a session cookie and no token → 403, bearer-only exempt, `GET` never challenged; Step 8 403 names the required authority and not the caller's

Rendering: `[<principal>]` is `[-]` for no credentials; decision `denied|granted <pattern> <requirement>` for a path rule (`default authenticated` when no rule matched) and `denied|granted secured <authorities>` / `granted permitAll` when the deciding rule is method security. Tokens come from the `security.testToken*` fixtures of README § *Examples*, bound to `val`s and concatenated into the request.

> helper gap: Basic auth and PBKDF2 (Steps 4–5) need a stored hash the helper cannot mint — they stay in `basic_test.bp`/`password_test.bp`; `WWW-Authenticate` and problem bodies are not rendered by `assertSecurity` (front 07's `assertProblem` covers the shape).

Shared source:

```bp
\\ import {Request, Response, service, managed, provides, restController, route, getMapping, postMapping, deleteMapping} from "rakun";
\\ import {SecurityPolicy, PathRule, methodSecurity, secured, permitAll, security} from "rakun-security";
\\
\\ #[provides]
\\ pub fn apiSecurityPolicy() -> SecurityPolicy {
\\     return SecurityPolicy(
\\         rules: [
\\             PathRule(pattern: "/api/public/:path*", requirement: "permitAll"),
\\             PathRule(pattern: "/api/admin/:path*", requirement: "hasRole:ADMIN"),
\\             PathRule(pattern: "/api/:path*", requirement: "authenticated"),
\\         ],
\\         defaultRequirement: "authenticated",
\\     );
\\ }
\\
\\ #[service]
\\ #[methodSecurity]
\\ #[managed]
\\ pub type AdminService {
\\     #[secured("ROLE_ADMIN")]
\\     pub fn purge(self: Self, olderThanDays: i32) -> i32 {
\\         return olderThanDays;
\\     }
\\
\\     #[secured("ROLE_ADMIN,ROLE_OPERATOR")]
\\     pub fn depth(self: Self) -> i32 {
\\         return 42;
\\     }
\\
\\     #[permitAll]
\\     pub fn status(self: Self) -> string {
\\         return "ok";
\\     }
\\ }
\\
\\ #[restController]
\\ #[route("/api")]
\\ #[managed]
\\ pub type OrdersApi(
\\     admin: AdminServiceSec,
\\ ) {
\\     #[getMapping("/public/health")]
\\     pub fn publicHealth(self: Self, req: Request) -> Response {
\\         return Response.ok(self.admin.status());
\\     }
\\
\\     #[postMapping("/public/ping")]
\\     pub fn ping(self: Self, req: Request) -> Response {
\\         return Response.ok("pong");
\\     }
\\
\\     #[getMapping("/orders/mine")]
\\     pub fn mine(self: Self, req: Request) -> Response {
\\         val auth = security.current();
\\         return Response.json(auth.principal.name);
\\     }
\\
\\     #[getMapping("/ops/depth")]
\\     pub fn depth(self: Self, req: Request) -> Response {
\\         return Response.ok(self.admin.depth().toString());
\\     }
\\
\\     #[deleteMapping("/admin/audit")]
\\     pub fn purge(self: Self, req: Request) -> Response {
\\         return Response.ok(self.admin.purge(30).toString());
\\     }
\\ }
```

### `security: a path with no rule is protected`

```bp
test "security: a path with no rule is protected" {
    try assertSecurity(@src(),
        \\ <shared source>
        , ["GET /internal/metrics"]);
}
```

`modules/rakun-security/test/__snapshots__/security/a-path-with-no-rule-is-protected.snap`
```
GET /internal/metrics [-] -> 401 denied default authenticated
```

### `security: declaration order decides and the public subtree stays public`

```bp
test "security: declaration order decides and the public subtree stays public" {
    try assertSecurity(@src(),
        \\ <shared source>
        , ["GET /api/public/health", "GET /api/orders/mine"]);
}
```

`modules/rakun-security/test/__snapshots__/security/declaration-order-decides-and-the-public-subtree-stays-public.snap`
```
GET /api/public/health [-] -> 200 granted /api/public/:path* permitAll
GET /api/orders/mine [-] -> 401 denied /api/:path* authenticated
```

### `security: a valid hs256 token authenticates and its claims become the principal`

```bp
test "security: a valid hs256 token authenticates and its claims become the principal" {
    val ana = security.testToken("ana", ["ROLE_USER"], 3600);
    try assertSecurity(@src(),
        \\ <shared source>
        , ["GET /api/orders/mine Authorization: Bearer " + ana]);
}
```

`modules/rakun-security/test/__snapshots__/security/a-valid-hs256-token-authenticates-and-its-claims-become-the-principal.snap`
```
GET /api/orders/mine [ana] -> 200 granted /api/:path* authenticated
```

### `security: expired tampered and alg none tokens are rejected identically`

```bp
test "security: expired tampered and alg none tokens are rejected identically" {
    val expired = security.testToken("ana", ["ROLE_USER"], -60);
    val tampered = security.testTokenTampered("ana");
    val none = security.testTokenAlgNone("ana");
    try assertSecurity(@src(),
        \\ <shared source>
        , [
            "GET /api/orders/mine Authorization: Bearer " + expired,
            "GET /api/orders/mine Authorization: Bearer " + tampered,
            "GET /api/orders/mine Authorization: Bearer " + none,
            "GET /api/orders/mine Authorization: Bearer not.a.jwt.at.all",
        ]);
}
```

`modules/rakun-security/test/__snapshots__/security/expired-tampered-and-alg-none-tokens-are-rejected-identically.snap`
```
GET /api/orders/mine [-] -> 401 denied /api/:path* authenticated
GET /api/orders/mine [-] -> 401 denied /api/:path* authenticated
GET /api/orders/mine [-] -> 401 denied /api/:path* authenticated
GET /api/orders/mine [-] -> 401 denied /api/:path* authenticated
```

### `security: hasRole admits an admin and refuses a user with 403`

```bp
test "security: hasRole admits an admin and refuses a user with 403" {
    val ana = security.testToken("ana", ["ROLE_USER"], 3600);
    val root = security.testToken("root", ["ROLE_ADMIN"], 3600);
    try assertSecurity(@src(),
        \\ <shared source>
        , [
            "DELETE /api/admin/audit Authorization: Bearer " + ana,
            "DELETE /api/admin/audit Authorization: Bearer " + root,
            "DELETE /api/admin/audit",
        ]);
}
```

`modules/rakun-security/test/__snapshots__/security/hasrole-admits-an-admin-and-refuses-a-user-with-403.snap`
```
DELETE /api/admin/audit [ana] -> 403 denied /api/admin/:path* hasRole:ADMIN
DELETE /api/admin/audit [root] -> 200 granted /api/admin/:path* hasRole:ADMIN
DELETE /api/admin/audit [-] -> 401 denied /api/admin/:path* hasRole:ADMIN
```

### `security: the method security proxy refuses a non-admin naming the required authority and a comma list admits either`

```bp
test "security: the method security proxy refuses a non-admin naming the required authority and a comma list admits either" {
    val ana = security.testToken("ana", ["ROLE_USER"], 3600);
    val ops = security.testToken("ops", ["ROLE_OPERATOR"], 3600);
    try assertSecurity(@src(),
        \\ <shared source>
        , [
            "GET /api/ops/depth Authorization: Bearer " + ana,
            "GET /api/ops/depth Authorization: Bearer " + ops,
            "GET /api/public/health",
        ]);
}
```

`modules/rakun-security/test/__snapshots__/security/the-method-security-proxy-refuses-a-non-admin-naming-the-required-authority-and-a-comma-list-admits-either.snap`
```
GET /api/ops/depth [ana] -> 403 denied secured ROLE_ADMIN,ROLE_OPERATOR
GET /api/ops/depth [ops] -> 200 granted secured ROLE_ADMIN,ROLE_OPERATOR
GET /api/public/health [-] -> 200 granted permitAll
```

### `security: csrf challenges a cookie post without a token exempts a bearer post and never challenges get`

```bp
test "security: csrf challenges a cookie post without a token exempts a bearer post and never challenges get" {
    val ana = security.testToken("ana", ["ROLE_USER"], 3600);
    try assertSecurity(@src(),
        \\ <shared source>
        , [
            "POST /api/public/ping Cookie: SESSION=sess-0001",
            "POST /api/public/ping Cookie: SESSION=sess-0001 X-CSRF-Token: csrf-0001",
            "POST /api/public/ping Authorization: Bearer " + ana,
            "GET /api/public/health Cookie: SESSION=sess-0001",
        ]);
}
```

`modules/rakun-security/test/__snapshots__/security/csrf-challenges-a-cookie-post-without-a-token-exempts-a-bearer-post-and-never-challenges-get.snap`
```
POST /api/public/ping [-] -> 403 denied csrf
POST /api/public/ping [-] -> 200 granted /api/public/:path* permitAll
POST /api/public/ping [ana] -> 200 granted /api/public/:path* permitAll
GET /api/public/health [-] -> 200 granted /api/public/:path* permitAll
```

## 14-rakun-validation — `rakun-validation`

**Test file:** `modules/rakun-validation/test/constraints_test.bp` · **Snapshots:** `modules/rakun-validation/test/__snapshots__/validation/` · **Target:** both — boundary: the emitted `validate<TypeName>` is plain botopink and every case below runs on erlang and commonJS against the same `.snap` (this is the parity test of README § *Test plan*); the `bind*` accumulator (Step 4) is erlang-only and stays in `binding_test.bp` · **Pins:** Step 1 a field failing two constraints produces two violations; Step 2 `#[validated]` emits `validate<TypeName>`, all constraints on a field run in declaration order; Step 3 same input → same report on both targets; Step 5 `#[constraint("cpf")]` through the SPI, `rakun.validation.messages.<code>` override, `{min}`/`{max}` substituted and an unknown placeholder survives; the true and false case of every marker in the table

Input is `field=value&…`, one value per field of the single `#[validated]` type in the source. Built-in default templates are the README's codes; their wording is open (name per README § *Message interpolation*).

### `validation: a record satisfying every constraint is valid`

```bp
test "validation: a record satisfying every constraint is valid" {
    try assertValidation(@src(),
        \\ import {validated, notBlank, sizeBetween, email, minValue, maxValue, pattern} from "rakun-validation";
        \\ import {Violation, ValidationReport, checkNotBlank, checkSizeBetween, checkEmail, checkRange, checkPattern} from "rakun-validation";
        \\
        \\ #[validated]
        \\ pub type CreateUserRequest(
        \\     #[notBlank]
        \\     #[sizeBetween(2, 50)]
        \\     name: string,
        \\
        \\     #[notBlank]
        \\     #[email]
        \\     email: string,
        \\
        \\     #[minValue(18)]
        \\     #[maxValue(120)]
        \\     age: i32,
        \\
        \\     #[pattern("^[0-9]{5}-[0-9]{3}$")]
        \\     postalCode: string,
        \\ )
        , "name=Ana&email=ana@example.com&age=30&postalCode=12345-678");
}
```

`modules/rakun-validation/test/__snapshots__/validation/a-record-satisfying-every-constraint-is-valid.snap`
```
valid
```

### `validation: every failing constraint on one field is reported in declaration order`

Same source as the previous case.

```bp
test "validation: every failing constraint on one field is reported in declaration order" {
    try assertValidation(@src(),
        \\ <same source>
        , "name=&email=ana@example.com&age=30&postalCode=12345-678");
}
```

`modules/rakun-validation/test/__snapshots__/validation/every-failing-constraint-on-one-field-is-reported-in-declaration-order.snap`
```
invalid
name: notBlank name must not be blank
name: sizeBetween name must be between 2 and 50 characters
```

### `validation: every failing field is reported at once sorted by field`

Same source as the first case.

```bp
test "validation: every failing field is reported at once sorted by field" {
    try assertValidation(@src(),
        \\ <same source>
        , "name=A&email=nope&age=15&postalCode=abc");
}
```

`modules/rakun-validation/test/__snapshots__/validation/every-failing-field-is-reported-at-once-sorted-by-field.snap`
```
invalid
age: minValue age must be at least 18
email: email email must be a valid email address
name: sizeBetween name must be between 2 and 50 characters
postalCode: pattern postalCode must match ^[0-9]{5}-[0-9]{3}$
```

### `validation: numeric sign and bound markers`

```bp
test "validation: numeric sign and bound markers" {
    try assertValidation(@src(),
        \\ import {validated, positive, positiveOrZero, maxValue, notEmpty} from "rakun-validation";
        \\ import {Violation, ValidationReport, checkRange, checkNotEmpty} from "rakun-validation";
        \\
        \\ #[validated]
        \\ pub type StockLine(
        \\     #[positive]
        \\     qty: i32,
        \\
        \\     #[positiveOrZero]
        \\     stock: i32,
        \\
        \\     #[maxValue(120)]
        \\     age: i32,
        \\
        \\     #[notEmpty]
        \\     sku: string,
        \\ )
        , "qty=0&stock=-1&age=130&sku=");
}
```

`modules/rakun-validation/test/__snapshots__/validation/numeric-sign-and-bound-markers.snap`
```
invalid
age: maxValue age must be at most 120
qty: positive qty must be greater than 0
sku: notEmpty sku must not be empty
stock: positiveOrZero stock must be greater than or equal to 0
```

### `validation: a registered constraint is reached through the spi`

```bp
test "validation: a registered constraint is reached through the spi" {
    try assertValidation(@src(),
        \\ import {validated, notBlank, constraint} from "rakun-validation";
        \\ import {Constraint, Violation, ValidationReport, registerConstraint, checkNotBlank, checkRegistered} from "rakun-validation";
        \\
        \\ pub type CpfConstraint {
        \\     pub fn code(self: Self) -> string {
        \\         return "cpf";
        \\     }
        \\
        \\     pub fn check(self: Self, field: string, value: string) -> string {
        \\         val digits = value.replaceAll(".", "").replaceAll("-", "");
        \\         if (digits.length() != 11) {
        \\             return "{field} must be a CPF with 11 digits, got \"{value}\"";
        \\         };
        \\         val head = digits.slice(0, 1);
        \\         val allSame = digits.split("").every({ c -> c == head });
        \\         if (allSame) {
        \\             return "{field} must not be a repeated-digit CPF";
        \\         };
        \\         return "";
        \\     }
        \\ }
        \\
        \\ val __cpfRegistration = registerConstraint("cpf", CpfConstraint());
        \\
        \\ #[validated]
        \\ pub type TaxpayerRequest(
        \\     #[notBlank]
        \\     fullName: string,
        \\
        \\     #[notBlank]
        \\     #[constraint("cpf")]
        \\     document: string,
        \\ )
        , "fullName=Ana&document=111.111.111-11");
}
```

`modules/rakun-validation/test/__snapshots__/validation/a-registered-constraint-is-reached-through-the-spi.snap`
```
invalid
document: cpf document must not be a repeated-digit CPF
```

### `validation: a configured template overrides the default and substitutes min and max leaving an unknown placeholder verbatim`

```bp
test "validation: a configured template overrides the default and substitutes min and max leaving an unknown placeholder verbatim" {
    try assertValidation(@src(),
        \\ import {rkSetProp} from "rakun";
        \\ import {validated, sizeBetween} from "rakun-validation";
        \\ import {Violation, ValidationReport, checkSizeBetween} from "rakun-validation";
        \\
        \\ val _template = rkSetProp("rakun.validation.messages.sizeBetween", "{field} needs {min}-{max} chars, not {limit}");
        \\
        \\ #[validated]
        \\ pub type Handle(
        \\     #[sizeBetween(2, 8)]
        \\     nick: string,
        \\ )
        , "nick=x");
}
```

`modules/rakun-validation/test/__snapshots__/validation/a-configured-template-overrides-the-default-and-substitutes-min-and-max-leaving-an-unknown-placeholder-verbatim.snap`
```
invalid
nick: sizeBetween nick needs 2-8 chars, not {limit}
```

## 18-rakun-session — `rakun-session`

**Test file:** `modules/rakun-session/test/session_test.bp` · **Snapshots:** `modules/rakun-session/test/__snapshots__/session/` · **Target:** erlang (ETS arm) · **Pins:** Step 2 a bad signature is rejected and a valid signature for a deleted session is rejected as not-found — both give the client the same response; Step 4 the emitted cookie carries `HttpOnly`, `Secure`, `SameSite=Lax`, `Path=/`, `Max-Age` and nothing turns them off; Step 5 a request with no cookie gets a session only when a handler asks, `rotate` issues a new id and preserves attributes, the session-fixation attempt ends with a different cookie

Ids and signatures come from the test seed: `sess-0001.sig-0001`. The helper's scratch context is not a plain listener on loopback, so `Secure` is present (README § *Cookie attributes*).

> helper gap: store-lookup counting (bad signature never reaches the store), the three-arm suite, `findByPrincipal`/`deleteExpired`, the `sessions` endpoint and the `==` grep have no helper — they stay in `signing_test.bp`/`store_test.bp`/`endpoint_test.bp`.

Shared source:

```bp
\\ import {Request, Response, service, restController, route, getMapping, postMapping} from "rakun";
\\ import {Session, SessionStore, currentSession, rotate} from "rakun-session";
\\
\\ #[service]
\\ pub type CartService(
\\     store: SessionStore,
\\ ) {
\\     pub fn read(self: Self, session: Session) -> string {
\\         val raw = session.attribute("cart");
\\         val cart = if (raw == "") { "[]" } else { raw };
\\         return cart;
\\     }
\\
\\     pub fn addItem(self: Self, session: Session, sku: string) -> Session {
\\         val next = session.withAttribute("cart", "[\"" + sku + "\"]");
\\         val _saved = self.store.save(next);
\\         return next;
\\     }
\\ }
\\
\\ #[restController]
\\ #[route("/api")]
\\ pub type CartController(
\\     cart: CartService,
\\     store: SessionStore,
\\ ) {
\\     #[getMapping("/ping")]
\\     pub fn ping(self: Self, req: Request) -> Response {
\\         return Response.ok("pong");
\\     }
\\
\\     #[getMapping("/cart")]
\\     pub fn show(self: Self, req: Request) -> Response {
\\         val session = currentSession();
\\         return Response.json(self.cart.read(session));
\\     }
\\
\\     #[postMapping("/cart/items")]
\\     pub fn add(self: Self, req: Request) -> Response {
\\         val session = currentSession();
\\         val next = self.cart.addItem(session, req.query("sku"));
\\         return Response.json(self.cart.read(next));
\\     }
\\
\\     #[postMapping("/auth/login")]
\\     pub fn login(self: Self, req: Request) -> Response {
\\         val before = currentSession();
\\         val rotated = rotate(before);
\\         val authenticated = rotated.withAttribute("principal", req.query("user"));
\\         val _saved = self.store.save(authenticated);
\\         return Response.json("{\"ok\":true}");
\\     }
\\ }
```

### `session: a route that never asks for a session creates none`

```bp
test "session: a route that never asks for a session creates none" {
    try assertSession(@src(),
        \\ <shared source>
        , ["GET /api/ping"]);
}
```

`modules/rakun-session/test/__snapshots__/session/a-route-that-never-asks-for-a-session-creates-none.snap`
```
GET /api/ping -> 200 session=none set-cookie=-
```

### `session: a handler asking for a session creates one with the restrictive cookie attributes`

```bp
test "session: a handler asking for a session creates one with the restrictive cookie attributes" {
    try assertSession(@src(),
        \\ <shared source>
        , ["GET /api/cart"]);
}
```

`modules/rakun-session/test/__snapshots__/session/a-handler-asking-for-a-session-creates-one-with-the-restrictive-cookie-attributes.snap`
```
GET /api/cart -> 200 session=new set-cookie=SESSION=sess-0001.sig-0001; Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax
```

### `session: a request carrying the cookie reuses the session and sets no cookie`

```bp
test "session: a request carrying the cookie reuses the session and sets no cookie" {
    try assertSession(@src(),
        \\ <shared source>
        , [
            "GET /api/cart",
            "POST /api/cart/items?sku=a-1 Cookie: SESSION=sess-0001.sig-0001",
            "GET /api/cart Cookie: SESSION=sess-0001.sig-0001",
        ]);
}
```

`modules/rakun-session/test/__snapshots__/session/a-request-carrying-the-cookie-reuses-the-session-and-sets-no-cookie.snap`
```
GET /api/cart -> 200 session=new set-cookie=SESSION=sess-0001.sig-0001; Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax
POST /api/cart/items?sku=a-1 -> 200 session=same set-cookie=-
GET /api/cart -> 200 session=same set-cookie=-
```

### `session: a bad signature and a valid signature for an unknown id are treated the same`

```bp
test "session: a bad signature and a valid signature for an unknown id are treated the same" {
    try assertSession(@src(),
        \\ <shared source>
        , [
            "GET /api/cart Cookie: SESSION=sess-0001.forged",
            "GET /api/cart Cookie: SESSION=sess-0009.sig-0009",
        ]);
}
```

`modules/rakun-session/test/__snapshots__/session/a-bad-signature-and-a-valid-signature-for-an-unknown-id-are-treated-the-same.snap`
```
GET /api/cart -> 200 session=new set-cookie=SESSION=sess-0001.sig-0001; Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax
GET /api/cart -> 200 session=new set-cookie=SESSION=sess-0002.sig-0002; Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax
```

### `session: login rotates the id and a planted id does not survive authentication`

```bp
test "session: login rotates the id and a planted id does not survive authentication" {
    try assertSession(@src(),
        \\ <shared source>
        , [
            "GET /api/cart",
            "POST /api/auth/login?user=ana Cookie: SESSION=sess-0001.sig-0001",
            "GET /api/cart Cookie: SESSION=sess-0002.sig-0002",
            "GET /api/cart Cookie: SESSION=sess-0001.sig-0001",
        ]);
}
```

`modules/rakun-session/test/__snapshots__/session/login-rotates-the-id-and-a-planted-id-does-not-survive-authentication.snap`
```
GET /api/cart -> 200 session=new set-cookie=SESSION=sess-0001.sig-0001; Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax
POST /api/auth/login?user=ana -> 200 session=new set-cookie=SESSION=sess-0002.sig-0002; Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax
GET /api/cart -> 200 session=same set-cookie=-
GET /api/cart -> 200 session=new set-cookie=SESSION=sess-0003.sig-0003; Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax
```

## 20-rakun-websocket — `rakun-websocket`

**Test file:** `modules/rakun-websocket/test/websocket_test.bp` · **Snapshots:** `modules/rakun-websocket/test/__snapshots__/websocket/` · **Target:** erlang · **Pins:** Step 1 101 on a registered path, 404 on an unregistered one, a handler that raises closes with `1011`; Step 2 missing `onClose` emitted as a no-op; Step 3 `broadcast` reaches the subscriber; Step 4 the wire contract — subprotocol `rakun.v1` echoed, text frame `{"t":…,"d":…}`, close codes `1000`/`1011`, an unknown subprotocol refused at upgrade

Frames script: the first entry is the upgrade `upgrade <path> <subprotocol>`; then `text <payload>` for a client frame and `close <code>` for a client close (script per README § *Wire contract*). `>` is a client frame, `<` a server frame.

> helper gap: `max-connections` 503, backpressure `1013`, heartbeat idle close, oversize `1009`, binary refusal, the two-node broadcast and `websocketHealth()` need a second connection, a clock or a cluster — they stay in `limits_test.bp`/`broadcast_test.bp`/`health_test.bp`.

Shared source:

```bp
\\ import {service} from "rakun";
\\ import {wsEndpoint, WsHandler, WsSession, subscribe, broadcast, rkWsRegister} from "rakun-websocket";
\\
\\ #[service]
\\ pub type RoomService {
\\     pub fn roomFor(self: Self, path: string) -> string {
\\         val parts = path.split("?");
\\         val query = parts.at(1).unwrapOr("");
\\         val room = query.replace("room=", "");
\\         val out = if (room == "") { "lobby" } else { room };
\\         return out;
\\     }
\\ }
\\
\\ #[service]
\\ #[wsEndpoint("/ws/chat")]
\\ pub type ChatEndpoint(
\\     rooms: RoomService,
\\ ) {
\\     pub fn onOpen(self: Self, session: WsSession) -> i32 {
\\         val room = self.rooms.roomFor(session.path);
\\         val _sub = subscribe(session, room);
\\         return broadcast(room, "{\"t\":\"" + room + "\",\"d\":\"joined\"}");
\\     }
\\
\\     pub fn onMessage(self: Self, session: WsSession, message: string) -> i32 {
\\         val room = self.rooms.roomFor(session.path);
\\         val boom = message == "boom";
\\         val divisor = if (boom) 0 else 1;
\\         val _q = 1 / divisor;
\\         return broadcast(room, "{\"t\":\"" + room + "\",\"d\":\"" + message + "\"}");
\\     }
\\ }
```

### `websocket: an upgrade on a registered path answers 101 and the open broadcast reaches the subscriber`

```bp
test "websocket: an upgrade on a registered path answers 101 and the open broadcast reaches the subscriber" {
    try assertWebSocket(@src(),
        \\ <shared source>
        , ["upgrade /ws/chat?room=r1 rakun.v1", "close 1000"]);
}
```

`modules/rakun-websocket/test/__snapshots__/websocket/an-upgrade-on-a-registered-path-answers-101-and-the-open-broadcast-reaches-the-subscriber.snap`
```
upgrade 101
< {"t":"r1","d":"joined"}
close 1000
```

### `websocket: an unregistered path answers 404`

```bp
test "websocket: an unregistered path answers 404" {
    try assertWebSocket(@src(),
        \\ <shared source>
        , ["upgrade /ws/nope rakun.v1"]);
}
```

`modules/rakun-websocket/test/__snapshots__/websocket/an-unregistered-path-answers-404.snap`
```
upgrade 404
```

### `websocket: a text frame is broadcast to the room in the wire envelope`

```bp
test "websocket: a text frame is broadcast to the room in the wire envelope" {
    try assertWebSocket(@src(),
        \\ <shared source>
        , ["upgrade /ws/chat?room=r1 rakun.v1", "text hello", "text again", "close 1000"]);
}
```

`modules/rakun-websocket/test/__snapshots__/websocket/a-text-frame-is-broadcast-to-the-room-in-the-wire-envelope.snap`
```
upgrade 101
< {"t":"r1","d":"joined"}
> hello
< {"t":"r1","d":"hello"}
> again
< {"t":"r1","d":"again"}
close 1000
```

### `websocket: a handler that raises closes that connection with 1011`

```bp
test "websocket: a handler that raises closes that connection with 1011" {
    try assertWebSocket(@src(),
        \\ <shared source>
        , ["upgrade /ws/chat?room=r1 rakun.v1", "text boom"]);
}
```

`modules/rakun-websocket/test/__snapshots__/websocket/a-handler-that-raises-closes-that-connection-with-1011.snap`
```
upgrade 101
< {"t":"r1","d":"joined"}
> boom
close 1011
```

### `websocket: an unknown subprotocol is refused at upgrade and an omitted one is accepted`

Refusal status per README § *Wire contract* ("refused at upgrade"; the code is open — `400` here).

```bp
test "websocket: an unknown subprotocol is refused at upgrade and an omitted one is accepted" {
    try assertWebSocket(@src(),
        \\ <shared source>
        , ["upgrade /ws/chat?room=r1 other.v9"]);
}
```

`modules/rakun-websocket/test/__snapshots__/websocket/an-unknown-subprotocol-is-refused-at-upgrade-and-an-omitted-one-is-accepted.snap`
```
upgrade 400
```

## 65-rakun-url-rules — `rakun-web`

**Test file:** `modules/rakun-web/test/rules/apply_test.bp` · **Snapshots:** `modules/rakun-web/test/rules/__snapshots__/rules/` · **Target:** both — boundary: the rule engine (`applyRules`) is erlang; `canonicalize`/`clientHref` and the redirect blob carry no host cell and the basePath case below is the one that runs on both targets against the same `.snap` · **Pins:** Step 1 the three matcher forms, one segment means one segment, literal dot escaped, § 20's lookahead example; Step 2 basePath strip, trailing slash, a path outside the base path untouched, single percent-decode; Step 3 308/307, capture interpolation percent-encoded, first match wins, self-redirect refused; Step 4 internal rewrite continues at the target, `isExternal` protocol-relative, unlisted origin refused, a rewrite never feeds the redirect table; Step 6 the five-step order

Rule lines are `redirect|<source>|<destination>|<permanent 0/1>` (README § *Redirects* blob), `rewrite|<source>|<destination>`, `matcher|<source>`, and `basePath=…` / `trailingSlash=…` for `UrlRules` fields (name per README § Step 2). A matcher hit renders `match`.

### `rules: a permanent redirect answers 308 a temporary one 307 and an unmatched path passes`

```bp
test "rules: a permanent redirect answers 308 a temporary one 307 and an unmatched path passes" {
    try assertUrlRules(@src(),
        ["redirect|/old|/new|1", "redirect|/tmp|/now|0"],
        ["/old", "/tmp", "/other", "/old/x"]);
}
```

`modules/rakun-web/test/rules/__snapshots__/rules/a-permanent-redirect-answers-308-a-temporary-one-307-and-an-unmatched-path-passes.snap`
```
/old -> redirect 308 /new
/tmp -> redirect 307 /now
/other -> pass
/old/x -> pass
```

### `rules: a capture is interpolated percent-encoded and one segment means one segment`

```bp
test "rules: a capture is interpolated percent-encoded and one segment means one segment" {
    try assertUrlRules(@src(),
        ["redirect|/blog/:slug|/posts/:slug|0"],
        ["/blog/hello", "/blog/hello%20world", "/blog/a/b", "/blog"]);
}
```

`modules/rakun-web/test/rules/__snapshots__/rules/a-capture-is-interpolated-percent-encoded-and-one-segment-means-one-segment.snap`
```
/blog/hello -> redirect 307 /posts/hello
/blog/hello%20world -> redirect 307 /posts/hello%20world
/blog/a/b -> pass
/blog -> pass
```

### `rules: the three matcher forms and a literal dot`

```bp
test "rules: the three matcher forms and a literal dot" {
    try assertUrlRules(@src(),
        ["matcher|/dashboard", "matcher|/docs/:path*", "matcher|/a.b"],
        ["/dashboard", "/dashboard/x", "/dashboardx", "/docs", "/docs/a", "/docs/a/b", "/a.b", "/axb"]);
}
```

`modules/rakun-web/test/rules/__snapshots__/rules/the-three-matcher-forms-and-a-literal-dot.snap`
```
/dashboard -> match
/dashboard/x -> pass
/dashboardx -> pass
/docs -> match
/docs/a -> match
/docs/a/b -> match
/a.b -> match
/axb -> pass
```

### `rules: the negative lookahead example from section 20`

```bp
test "rules: the negative lookahead example from section 20" {
    try assertUrlRules(@src(),
        ["matcher|/((?!api|_next/static|_next/image|favicon.ico).*)"],
        ["/dashboard", "/api/posts", "/_next/static/x", "/favicon.ico"]);
}
```

`modules/rakun-web/test/rules/__snapshots__/rules/the-negative-lookahead-example-from-section-20.snap`
```
/dashboard -> match
/api/posts -> pass
/_next/static/x -> pass
/favicon.ico -> pass
```

### `rules: basePath is stripped trailing slash normalized and decoding happens once`

Boundary case — runs on erlang and commonJS against this one file.

```bp
test "rules: basePath is stripped trailing slash normalized and decoding happens once" {
    try assertUrlRules(@src(),
        ["basePath=/docs", "trailingSlash=false", "matcher|/about", "matcher|/a%2Fb"],
        ["/docs/about", "/docs/about/", "/docs", "/other/about", "/docs/a%252Fb", "/docs/a%2Fb"]);
}
```

`modules/rakun-web/test/rules/__snapshots__/rules/basepath-is-stripped-trailing-slash-normalized-and-decoding-happens-once.snap`
```
/docs/about -> match
/docs/about/ -> match
/docs -> pass
/other/about -> pass
/docs/a%252Fb -> match
/docs/a%2Fb -> pass
```

### `rules: redirects run before rewrites first match wins and a rewrite never feeds the redirect table`

```bp
test "rules: redirects run before rewrites first match wins and a rewrite never feeds the redirect table" {
    try assertUrlRules(@src(),
        ["redirect|/x|/first|0", "redirect|/x|/second|0", "redirect|/both|/redirected|0", "rewrite|/both|/rewritten", "rewrite|/loop-in|/loop-out", "redirect|/loop-out|/elsewhere|0", "rewrite|/shop/:path*|/catalog/:path*"],
        ["/x", "/both", "/loop-in", "/shop/a/b", "/catalog/z"]);
}
```

`modules/rakun-web/test/rules/__snapshots__/rules/redirects-run-before-rewrites-first-match-wins-and-a-rewrite-never-feeds-the-redirect-table.snap`
```
/x -> redirect 307 /first
/both -> redirect 307 /redirected
/loop-in -> rewrite /loop-out
/shop/a/b -> rewrite /catalog/a/b
/catalog/z -> pass
```

### `rules: a self-redirect and an external rewrite to an unlisted origin are refused`

`refused` wording per README § *Redirects* (self-redirect) and § *Rewrites* (`rakun.rules.allowedOrigins` unset → empty list; the protocol-relative form is external).

```bp
test "rules: a self-redirect and an external rewrite to an unlisted origin are refused" {
    try assertUrlRules(@src(),
        ["redirect|/loop|/loop|0", "rewrite|/api/external/:path*|https://api.example.com/:path*", "rewrite|/cdn/:path*|//cdn.example.com/:path*"],
        ["/loop", "/api/external/v1", "/cdn/logo.png"]);
}
```

`modules/rakun-web/test/rules/__snapshots__/rules/a-self-redirect-and-an-external-rewrite-to-an-unlisted-origin-are-refused.snap`
```
/loop -> refused self-redirect /loop -> /loop
/api/external/v1 -> refused origin api.example.com not in rakun.rules.allowedOrigins
/cdn/logo.png -> refused origin cdn.example.com not in rakun.rules.allowedOrigins
```

## 77-rakun-db-migrations — `rakun-data`

**Test file:** `modules/rakun-data/test/migration/migration_test.bp` · **Snapshots:** `modules/rakun-data/test/migration/__snapshots__/migration/` · **Target:** erlang (ETS arm, per README § *Test plan*) · **Pins:** Step 1 component-wise version order (`V10` after `V9`, `V1.1` after `V1`), repeatables after every versioned one, a misnamed file refused naming both shapes, a duplicate version refused naming both paths; Step 4 an edited applied migration refused naming the script and both checksums; Step 5 `out-of-order=false` refuses a lower version, baseline against an empty database refused; Step 7 `ddl-auto=create` under a production profile refused naming profile, property and value, `create` alongside migration files refused naming both, `validate` permitted under production

Migrations are `<file name>=<content>`; state lines are `applied <version> <checksum>` history rows and `<property>=<value>` for the keys of README § *Modes* and § *`ddl-auto`*. A repeatable's version renders as `R` (its `Migration.version` is `""`). Checksums are the SHA-256 of the file content (front 03).

### `migration: versions sort component-wise and repeatables run last`

```bp
test "migration: versions sort component-wise and repeatables run last" {
    try assertMigration(@src(),
        [
            "V10__add_population.sql=alter table cities add column population integer",
            "R__city_summary_view.sql=create or replace view city_summary as select * from cities",
            "V2__seed_cities.sql=insert into cities values (1)",
            "V1__create_cities.sql=create table cities (id int)",
            "V1.1__index_cities_state.sql=create index cities_state on cities (state)",
            "V9__nine.sql=select 9",
        ],
        []);
}
```

`modules/rakun-data/test/migration/__snapshots__/migration/versions-sort-component-wise-and-repeatables-run-last.snap`
```
pending 1 create_cities
pending 1.1 index_cities_state
pending 2 seed_cities
pending 9 nine
pending 10 add_population
pending R city_summary_view
```

### `migration: a misnamed file is refused naming both accepted shapes`

```bp
test "migration: a misnamed file is refused naming both accepted shapes" {
    try assertMigration(@src(),
        ["V1__create_cities.sql=create table cities (id int)", "init.sql=create table x (id int)"],
        []);
}
```

`modules/rakun-data/test/migration/__snapshots__/migration/a-misnamed-file-is-refused-naming-both-accepted-shapes.snap`
```
refused init.sql matches neither V<version>__<description>.sql nor R__<description>.sql
```

### `migration: two files declaring one version are refused naming both paths`

```bp
test "migration: two files declaring one version are refused naming both paths" {
    try assertMigration(@src(),
        ["V1__create_cities.sql=create table cities (id int)", "V2__a.sql=select 1", "V2__b.sql=select 2"],
        []);
}
```

`modules/rakun-data/test/migration/__snapshots__/migration/two-files-declaring-one-version-are-refused-naming-both-paths.snap`
```
refused duplicate version 2: V2__a.sql, V2__b.sql
```

### `migration: an applied row carries its checksum and an edited applied migration is refused naming both checksums`

```bp
test "migration: an applied row carries its checksum and an edited applied migration is refused naming both checksums" {
    try assertMigration(@src(),
        ["V1__create_cities.sql=create table cities (id int, name text)", "V2__seed_cities.sql=insert into cities values (1)"],
        ["applied 1 d91823cc4570e38b0e86e977feb8686af42207a52290892a6cbdf848fb16d9c3"]);
}
```

`modules/rakun-data/test/migration/__snapshots__/migration/an-applied-row-carries-its-checksum-and-an-edited-applied-migration-is-refused-naming-both-checksums.snap`
```
applied 1 d91823cc4570e38b0e86e977feb8686af42207a52290892a6cbdf848fb16d9c3
refused V1__create_cities.sql recorded checksum d91823cc4570e38b0e86e977feb8686af42207a52290892a6cbdf848fb16d9c3 current checksum da23e0868cf229d49698ee014c7685812aaa4311ecaf247776575e7a3c367437
```

### `migration: an unchanged applied migration is skipped and the rest is pending`

```bp
test "migration: an unchanged applied migration is skipped and the rest is pending" {
    try assertMigration(@src(),
        ["V1__create_cities.sql=create table cities (id int)", "V2__seed_cities.sql=insert into cities values (1)"],
        ["applied 1 d91823cc4570e38b0e86e977feb8686af42207a52290892a6cbdf848fb16d9c3"]);
}
```

`modules/rakun-data/test/migration/__snapshots__/migration/an-unchanged-applied-migration-is-skipped-and-the-rest-is-pending.snap`
```
applied 1 d91823cc4570e38b0e86e977feb8686af42207a52290892a6cbdf848fb16d9c3
pending 2 seed_cities
```

### `migration: out-of-order false refuses a lower version after a higher one and baseline against an empty database is refused`

```bp
test "migration: out-of-order false refuses a lower version after a higher one and baseline against an empty database is refused" {
    try assertMigration(@src(),
        ["V1__create_cities.sql=create table cities (id int)", "V2__seed_cities.sql=insert into cities values (1)"],
        ["applied 2 1a8ec56ab67d93dc668e92230bee631bc1feed9fcc1aa6b68ece39a547a74b3b", "rakun.migration.out-of-order=false"]);
}
```

`modules/rakun-data/test/migration/__snapshots__/migration/out-of-order-false-refuses-a-lower-version-after-a-higher-one-and-baseline-against-an-empty-database-is-refused.snap`
```
applied 2 1a8ec56ab67d93dc668e92230bee631bc1feed9fcc1aa6b68ece39a547a74b3b
refused version 1 is lower than applied 2 and rakun.migration.out-of-order=false
```

### `migration: ddl-auto create under a production profile is refused and validate is permitted`

```bp
test "migration: ddl-auto create under a production profile is refused and validate is permitted" {
    try assertMigration(@src(),
        [],
        ["rakun.profiles.active=prod", "rakun.migration.ddl-auto=create"]);
}
```

`modules/rakun-data/test/migration/__snapshots__/migration/ddl-auto-create-under-a-production-profile-is-refused-and-validate-is-permitted.snap`
```
refused profile prod: rakun.migration.ddl-auto=create
```

### `migration: ddl-auto create alongside migration files is refused naming both`

```bp
test "migration: ddl-auto create alongside migration files is refused naming both" {
    try assertMigration(@src(),
        ["V1__create_cities.sql=create table cities (id int)"],
        ["rakun.profiles.active=dev", "rakun.migration.ddl-auto=create"]);
}
```

`modules/rakun-data/test/migration/__snapshots__/migration/ddl-auto-create-alongside-migration-files-is-refused-naming-both.snap`
```
refused rakun.migration.ddl-auto=create and db/migration both own the schema
```

## 78-rakun-orm-entities — `rakun-data`

**Test file:** `modules/rakun-data/test/orm/entity_test.bp` (suite `entity`, `assertEntity`) · `modules/rakun-data/test/orm/derivation_test.bp` (suite `derived`, `assertQuery`) · **Snapshots:** `modules/rakun-data/test/orm/__snapshots__/{entity,derived}/` · **Target:** erlang (ETS arm) · **Pins:** Step 1 `camelCase → snake_case`, `#[column]` override, `#[transient]` in neither columns nor params, table name is the decorator's argument; Step 2 `findByName`, `AllIgnoringCase` lowers both sides, `Between` consumes two, `FirstBy…OrderBy…Desc` → `limit 1`, `countBy`, every statement asserted against a literal; Step 3 `Pageable` → page statement + count statement without `order by`; Step 4 `update` adds `and revision = :revision` and increments; Step 6 builder and derived query agree; Step 7 `#[revisions]` adds the revision table, its absence adds none

DDL rendering: one `create table` per table the entity produces, lowercase, `i32 → integer`, `string → text`, the `#[id]` column `primary key`; then `map <field> <- <column> <type>` sorted by field (type wording per README § *Step 8* metadata — open).

### `entity: camelCase maps to snake_case and column overrides it`

```bp
test "entity: camelCase maps to snake_case and column overrides it" {
    try assertEntity(@src(),
        \\ import {entity, id, generated, column} from "rakun-data";
        \\
        \\ #[entity("cities")]
        \\ pub type City(
        \\     #[id]
        \\     #[generated]
        \\     id: i32,
        \\
        \\     name: string,
        \\
        \\     #[column("state_name")]
        \\     state: string,
        \\
        \\     population: i32,
        \\
        \\     foundedYear: i32,
        \\ )
        );
}
```

`modules/rakun-data/test/orm/__snapshots__/entity/camelcase-maps-to-snake-case-and-column-overrides-it.snap`
```
create table cities (
  id integer primary key,
  name text,
  state_name text,
  population integer,
  founded_year integer
)
map foundedYear <- founded_year integer
map id <- id integer
map name <- name text
map population <- population integer
map state <- state_name text
```

### `entity: transient fields are neither columns nor params and version is an integer column`

```bp
test "entity: transient fields are neither columns nor params and version is an integer column" {
    try assertEntity(@src(),
        \\ import {entity, id, column, version, transient} from "rakun-data";
        \\
        \\ #[entity("session_tokens")]
        \\ pub type SessionToken(
        \\     #[id]
        \\     token: string,
        \\
        \\     #[column("account_id")]
        \\     accountId: i32,
        \\
        \\     #[version]
        \\     revision: i32,
        \\
        \\     #[transient]
        \\     cachedLabel: string,
        \\ )
        );
}
```

`modules/rakun-data/test/orm/__snapshots__/entity/transient-fields-are-neither-columns-nor-params-and-version-is-an-integer-column.snap`
```
create table session_tokens (
  token text primary key,
  account_id integer,
  revision integer
)
map accountId <- account_id integer
map revision <- revision integer
map token <- token text
```

### `entity: revisions adds a revision table and its absence adds none`

```bp
test "entity: revisions adds a revision table and its absence adds none" {
    try assertEntity(@src(),
        \\ import {entity, id, generated, column, version, revisions, createdAt, updatedAt, createdBy} from "rakun-data";
        \\
        \\ #[entity("accounts")]
        \\ #[revisions]
        \\ pub type Account(
        \\     #[id]
        \\     #[generated]
        \\     id: i32,
        \\
        \\     email: string,
        \\
        \\     #[column("balance_cents")]
        \\     balanceCents: i32,
        \\
        \\     #[version]
        \\     revision: i32,
        \\
        \\     #[createdAt]
        \\     createdAt: string,
        \\
        \\     #[updatedAt]
        \\     updatedAt: string,
        \\
        \\     #[createdBy]
        \\     createdBy: string,
        \\ )
        );
}
```

`modules/rakun-data/test/orm/__snapshots__/entity/revisions-adds-a-revision-table-and-its-absence-adds-none.snap`
```
create table accounts (
  id integer primary key,
  email text,
  balance_cents integer,
  revision integer,
  created_at text,
  updated_at text,
  created_by text
)
create table accounts_revisions (
  id integer,
  email text,
  balance_cents integer,
  revision integer,
  created_at text,
  updated_at text,
  created_by text,
  revision_number integer,
  revision_type text,
  revision_timestamp text,
  revision_author text
)
map balanceCents <- balance_cents integer
map createdAt <- created_at text
map createdBy <- created_by text
map email <- email text
map id <- id integer
map revision <- revision integer
map updatedAt <- updated_at text
```

Shared source for the `derived` suite (`__rkDerived_*` helpers, `CityCol` and `CityMeta` are emitted):

```bp
\\ import {repository} from "rakun";
\\ import {SqlTemplate, Row, param, entity, id, generated, column, derived, entityRepository} from "rakun-data";
\\ import {Page, Pageable, Sort, queryOf} from "rakun-data";
\\
\\ #[entity("cities")]
\\ pub type City(
\\     #[id]
\\     #[generated]
\\     id: i32,
\\
\\     name: string,
\\
\\     #[column("state_name")]
\\     state: string,
\\
\\     population: i32,
\\ )
\\
\\ #[repository]
\\ #[entityRepository("City")]
\\ pub type CityRepo(
\\     sql: SqlTemplate,
\\ ) {
\\     #[derived]
\\     pub fn findByName(self: Self, name: string) -> City[] {
\\         return __rkDerived_CityRepo_findByName(self.sql, name);
\\     }
\\
\\     #[derived]
\\     pub fn findByNameAndStateAllIgnoringCase(self: Self, name: string, state: string) -> City[] {
\\         return __rkDerived_CityRepo_findByNameAndStateAllIgnoringCase(self.sql, name, state);
\\     }
\\
\\     #[derived]
\\     pub fn findByPopulationBetween(self: Self, low: i32, high: i32) -> City[] {
\\         return __rkDerived_CityRepo_findByPopulationBetween(self.sql, low, high);
\\     }
\\
\\     #[derived]
\\     pub fn findFirstByStateOrderByPopulationDesc(self: Self, state: string) -> ?City {
\\         return __rkDerived_CityRepo_findFirstByStateOrderByPopulationDesc(self.sql, state);
\\     }
\\
\\     #[derived]
\\     pub fn countByState(self: Self, state: string) -> i32 {
\\         return __rkDerived_CityRepo_countByState(self.sql, state);
\\     }
\\
\\     #[derived]
\\     pub fn findAllByState(self: Self, state: string, page: Pageable) -> Page<City> {
\\         return __rkDerived_CityRepo_findAllByState(self.sql, state, page);
\\     }
\\
\\     pub fn builtByState(self: Self, state: string) -> City[] {
\\         return queryOf(CityMeta).where(CityCol.state, "=", state).fetch(self.sql);
\\     }
\\ }
```

### `derived: a single term derives select where with the overridden column`

```bp
test "derived: a single term derives select where with the overridden column" {
    try assertQuery(@src(),
        \\ <shared derived source>
        , ["CityRepo.findByName(\"Rio\")", "CityRepo.countByState(\"CA\")"]);
}
```

`modules/rakun-data/test/orm/__snapshots__/derived/a-single-term-derives-select-where-with-the-overridden-column.snap`
```
CityRepo.findByName("Rio") -> select id, name, state_name, population from cities where name = :name  params=[name=Rio]
CityRepo.countByState("CA") -> select count(*) from cities where state_name = :state  params=[state=CA]
```

### `derived: AllIgnoringCase lowers both sides Between consumes two and FirstBy OrderBy limits to one`

```bp
test "derived: AllIgnoringCase lowers both sides Between consumes two and FirstBy OrderBy limits to one" {
    try assertQuery(@src(),
        \\ <shared derived source>
        , [
            "CityRepo.findByNameAndStateAllIgnoringCase(\"rio\", \"rj\")",
            "CityRepo.findByPopulationBetween(1000, 5000)",
            "CityRepo.findFirstByStateOrderByPopulationDesc(\"CA\")",
        ]);
}
```

`modules/rakun-data/test/orm/__snapshots__/derived/allignoringcase-lowers-both-sides-between-consumes-two-and-firstby-orderby-limits-to-one.snap`
```
CityRepo.findByNameAndStateAllIgnoringCase("rio", "rj") -> select id, name, state_name, population from cities where lower(name) = lower(:name) and lower(state_name) = lower(:state)  params=[name=rio, state=rj]
CityRepo.findByPopulationBetween(1000, 5000) -> select id, name, state_name, population from cities where population between :low and :high  params=[low=1000, high=5000]
CityRepo.findFirstByStateOrderByPopulationDesc("CA") -> select id, name, state_name, population from cities where state_name = :state order by population desc limit 1  params=[state=CA]
```

### `derived: a Pageable method issues the page statement and a count without order by`

```bp
test "derived: a Pageable method issues the page statement and a count without order by" {
    try assertQuery(@src(),
        \\ <shared derived source>
        , ["CityRepo.findAllByState(\"CA\", Pageable(page: 1, size: 20, sort: []))"]);
}
```

`modules/rakun-data/test/orm/__snapshots__/derived/a-pageable-method-issues-the-page-statement-and-a-count-without-order-by.snap`
```
CityRepo.findAllByState("CA", Pageable(page: 1, size: 20, sort: [])) -> select id, name, state_name, population from cities where state_name = :state order by id asc limit :limit offset :offset  params=[state=CA, limit=20, offset=20]
CityRepo.findAllByState("CA", Pageable(page: 1, size: 20, sort: [])) -> select count(*) from cities where state_name = :state  params=[state=CA]
```

### `derived: the builder and a derived query agree on the same predicate`

```bp
test "derived: the builder and a derived query agree on the same predicate" {
    try assertQuery(@src(),
        \\ <shared derived source>
        , ["CityRepo.builtByState(\"CA\")", "CityRepo.findByName(\"'; drop table cities; --\")"]);
}
```

`modules/rakun-data/test/orm/__snapshots__/derived/the-builder-and-a-derived-query-agree-on-the-same-predicate.snap`
```
CityRepo.builtByState("CA") -> select id, name, state_name, population from cities where state_name = :p0  params=[p0=CA]
CityRepo.findByName("'; drop table cities; --") -> select id, name, state_name, population from cities where name = :name  params=[name='; drop table cities; --]
```

### `derived: update is version-checked and save omits a generated id`

```bp
test "derived: update is version-checked and save omits a generated id" {
    try assertQuery(@src(),
        \\ import {repository} from "rakun";
        \\ import {SqlTemplate, entity, id, generated, column, version, entityRepository} from "rakun-data";
        \\
        \\ #[entity("accounts")]
        \\ pub type Account(
        \\     #[id]
        \\     #[generated]
        \\     id: i32,
        \\
        \\     email: string,
        \\
        \\     #[column("balance_cents")]
        \\     balanceCents: i32,
        \\
        \\     #[version]
        \\     revision: i32,
        \\ )
        \\
        \\ #[repository]
        \\ #[entityRepository("Account")]
        \\ pub type AccountRepo(
        \\     sql: SqlTemplate,
        \\ )
        , [
            "AccountRepo.save(Account(id: 0, email: \"ana@example.org\", balanceCents: 1000, revision: 0))",
            "AccountRepo.update(Account(id: 1, email: \"ana@example.org\", balanceCents: 900, revision: 0))",
        ]);
}
```

`modules/rakun-data/test/orm/__snapshots__/derived/update-is-version-checked-and-save-omits-a-generated-id.snap`
```
AccountRepo.save(Account(id: 0, email: "ana@example.org", balanceCents: 1000, revision: 0)) -> insert into accounts (email, balance_cents, revision) values (:email, :balanceCents, :revision)  params=[email=ana@example.org, balanceCents=1000, revision=0]
AccountRepo.update(Account(id: 1, email: "ana@example.org", balanceCents: 900, revision: 0)) -> update accounts set email = :email, balance_cents = :balanceCents, revision = :revision + 1 where id = :id and revision = :revision  params=[email=ana@example.org, balanceCents=900, revision=0, id=1]
```

## 79-rakun-oauth2-sso — `rakun-security`

**Test file:** `modules/rakun-security/test/oauth2/oauth_test.bp` · **Snapshots:** `modules/rakun-security/test/oauth2/__snapshots__/oauth/` · **Target:** erlang (fixture provider of README § *Test plan*, no network) · **Pins:** Step 2 the URL carries `response_type=code`, `client_id`, `redirect_uri`, `scope`, `state`, `nonce`, `code_challenge`, `code_challenge_method=S256`, `returnTo` never in the URL; Step 3 unknown or consumed `state` → no exchange, `error=access_denied` → no exchange, a successful callback installs the principal; Step 4 a `nonce` mismatch names `nonce`; Step 5 `scope` → `SCOPE_…`, `roles` → `ROLE_…`, a `#[secured]` handler with no bearer answers 401 not 500

Config lines are `rakun.security.oauth2.<id>.<key>=<value>` (README § *Examples* keys `client-id`, `client-secret`, `issuer-uri`; the explicit-endpoint keys follow `ProviderEndpoints` fields — name per README § Step 1). Step strings: `authorize <id> <returnTo>`, `callback <id> <query>`, `bearer <claims>` (fixture claims per README § *Test plan*). Secrets come from the seed: `state-0001`, `nonce-0001`, `challenge-0001`.

> helper gap: boot refusals (duplicate `id`, empty secret without PKCE, issuer mismatch), the JWKS re-fetch counter, refresh, client credentials, LDAP and SAML have no helper — they stay in the README's fixture-counted tests.

### `oauth: the authorization request carries pkce state and nonce and never the return path`

```bp
test "oauth: the authorization request carries pkce state and nonce and never the return path" {
    try assertOAuth(@src(),
        [
            "rakun.security.oauth2.fixture.client-id=web-app",
            "rakun.security.oauth2.fixture.client-secret=s3cret",
            "rakun.security.oauth2.fixture.issuer-uri=",
            "rakun.security.oauth2.fixture.authorization=http://127.0.0.1:19080/auth",
            "rakun.security.oauth2.fixture.token=http://127.0.0.1:19080/token",
            "rakun.security.oauth2.fixture.userinfo=http://127.0.0.1:19080/userinfo",
            "rakun.security.oauth2.fixture.jwks=http://127.0.0.1:19080/jwks",
            "rakun.security.oauth2.fixture.scopes=openid,profile",
            "rakun.security.oauth2.fixture.pkce=true",
            "rakun.security.oauth2.fixture.redirect-path=/login/oauth2/code/fixture",
        ],
        "authorize fixture /dashboard");
}
```

`modules/rakun-security/test/oauth2/__snapshots__/oauth/the-authorization-request-carries-pkce-state-and-nonce-and-never-the-return-path.snap`
```
authorize http://127.0.0.1:19080/auth?client_id=web-app&code_challenge=challenge-0001&code_challenge_method=S256&nonce=nonce-0001&redirect_uri=http%3A%2F%2F127.0.0.1%3A18080%2Flogin%2Foauth2%2Fcode%2Ffixture&response_type=code&scope=openid%20profile&state=state-0001
```

### `oauth: a callback with an unknown state performs no exchange`

Same config as the previous case.

```bp
test "oauth: a callback with an unknown state performs no exchange" {
    try assertOAuth(@src(), [<same config>], "callback fixture code=c-1&state=bogus");
}
```

`modules/rakun-security/test/oauth2/__snapshots__/oauth/a-callback-with-an-unknown-state-performs-no-exchange.snap`
```
token err unknown state
```

### `oauth: a callback carrying access_denied answers with the provider description and no exchange`

```bp
test "oauth: a callback carrying access_denied answers with the provider description and no exchange" {
    try assertOAuth(@src(), [<same config>], "callback fixture error=access_denied&error_description=user%20cancelled&state=state-0001");
}
```

`modules/rakun-security/test/oauth2/__snapshots__/oauth/a-callback-carrying-access-denied-answers-with-the-provider-description-and-no-exchange.snap`
```
token err access_denied user cancelled
```

### `oauth: a successful callback exchanges verifies the id token and installs the principal`

The fixture token endpoint issues an ID token for `ana` with `roles: ["user"]` and `scope: "openid profile"`.

```bp
test "oauth: a successful callback exchanges verifies the id token and installs the principal" {
    try assertOAuth(@src(), [<same config>], "callback fixture code=c-1&state=state-0001");
}
```

`modules/rakun-security/test/oauth2/__snapshots__/oauth/a-successful-callback-exchanges-verifies-the-id-token-and-installs-the-principal.snap`
```
token ok
principal ana authorities=[SCOPE_openid, SCOPE_profile, ROLE_user]
```

### `oauth: a consumed state is single-use`

```bp
test "oauth: a consumed state is single-use" {
    try assertOAuth(@src(), [<same config>], "callback fixture code=c-1&state=state-0001 callback fixture code=c-1&state=state-0001");
}
```

`modules/rakun-security/test/oauth2/__snapshots__/oauth/a-consumed-state-is-single-use.snap`
```
token ok
principal ana authorities=[SCOPE_openid, SCOPE_profile, ROLE_user]
token err unknown state
```

### `oauth: a nonce mismatch names nonce`

The fixture issues the ID token with `nonce` `nonce-9999` when the code is `c-nonce`.

```bp
test "oauth: a nonce mismatch names nonce" {
    try assertOAuth(@src(), [<same config>], "callback fixture code=c-nonce&state=state-0001");
}
```

`modules/rakun-security/test/oauth2/__snapshots__/oauth/a-nonce-mismatch-names-nonce.snap`
```
token err nonce
```

### `oauth: scope and roles claims on a bearer token map to authorities`

```bp
test "oauth: scope and roles claims on a bearer token map to authorities" {
    try assertOAuth(@src(), [<same config>], "bearer sub=svc scope=orders:read orders:write roles=admin,auditor");
}
```

`modules/rakun-security/test/oauth2/__snapshots__/oauth/scope-and-roles-claims-on-a-bearer-token-map-to-authorities.snap`
```
token ok
principal svc authorities=[SCOPE_orders:read, SCOPE_orders:write, ROLE_admin, ROLE_auditor]
```

### `oauth: a secured handler with no bearer answers 401 not 500 and a scoped bearer is granted`

`assertSecurity` case in the same file (suite `oauth`, `principal` rendered as front 10 renders it).

```bp
test "oauth: a secured handler with no bearer answers 401 not 500 and a scoped bearer is granted" {
    val svc = security.fixtureBearer("svc", "orders:read", []);
    try assertSecurity(@src(),
        \\ import {Request, Response, restController, route, getMapping} from "rakun";
        \\ import {secured, currentPrincipal} from "rakun-security";
        \\
        \\ #[restController]
        \\ #[route("/api")]
        \\ pub type MeController {
        \\     #[getMapping("/hello")]
        \\     pub fn hello(self: Self, req: Request) -> Response {
        \\         return Response.ok("hello, " + currentPrincipal(req).name);
        \\     }
        \\
        \\     #[getMapping("/orders")]
        \\     #[secured("SCOPE_orders:read")]
        \\     pub fn orders(self: Self, req: Request) -> Response {
        \\         return Response.json("[]");
        \\     }
        \\ }
        , ["GET /api/hello", "GET /api/orders", "GET /api/orders Authorization: Bearer " + svc, "GET /api/orders Authorization: Bearer garbage"]);
}
```

`modules/rakun-security/test/oauth2/__snapshots__/oauth/a-secured-handler-with-no-bearer-answers-401-not-500-and-a-scoped-bearer-is-granted.snap`
```
GET /api/hello [-] -> 200 anonymous
GET /api/orders [-] -> 401 denied secured SCOPE_orders:read
GET /api/orders [svc] -> 200 granted secured SCOPE_orders:read
GET /api/orders [-] -> 401 denied secured SCOPE_orders:read
```

## 82-rakun-static-assets — `rakun-web`

**Test file:** `modules/rakun-web/test/static/static_test.bp` · **Snapshots:** `modules/rakun-web/test/static/__snapshots__/static/` · **Target:** erlang · **Pins:** Step 1 no-pattern request falls through, `contentTypeOf` table incl. `; charset=utf-8` on css/js and `application/octet-stream` for unknown, directory without `indexFile` → 404; Step 2 `..` → 404, `%2e%2e%2f` → 404, `%252e` → 400, `//etc/passwd` → 404; Step 3 first request 200 + `ETag`, `If-None-Match` → 304 carrying the same `ETag` and `Cache-Control`; Step 4 `Range` → 206, unsatisfiable → 416; Step 5 fingerprinted → `public, max-age=31536000, immutable`, stable → `no-cache`, a stale fingerprint → 404

Files are `<relative path>=<content>` under the default roots (`/static/**` → `static/`, `/public/**` → `public/`, `index.html`), per README § Step 1. ETags are the SHA-256 of the content (front 03); a fingerprint is its first 6 hex digits, as in `app.7f3a91.css`. Absent values render `-`.

> helper gap: `Content-Encoding`/`Vary` (Step 6), `Content-Range`/`Accept-Ranges`, `Last-Modified`, the `stat` counter and the memory ceiling are not rendered by `assertStatic` — they stay in `test/static/` fixture tests.

### `static: a stable name is no-cache and revalidates to 304 with the same validators`

```bp
test "static: a stable name is no-cache and revalidates to 304 with the same validators" {
    try assertStatic(@src(),
        ["static/app.css=body{}"],
        [
            "GET /static/app.css",
            "GET /static/app.css If-None-Match: \"7c98040a541657584690ae2a1cc3b42a8b53b159cc60c5d3abbfecbaeac6c94a\"",
            "GET /static/app.css If-None-Match: \"stale\"",
        ]);
}
```

`modules/rakun-web/test/static/__snapshots__/static/a-stable-name-is-no-cache-and-revalidates-to-304-with-the-same-validators.snap`
```
200 text/css; charset=utf-8 etag="7c98040a541657584690ae2a1cc3b42a8b53b159cc60c5d3abbfecbaeac6c94a" cache-control=no-cache
304 - etag="7c98040a541657584690ae2a1cc3b42a8b53b159cc60c5d3abbfecbaeac6c94a" cache-control=no-cache
200 text/css; charset=utf-8 etag="7c98040a541657584690ae2a1cc3b42a8b53b159cc60c5d3abbfecbaeac6c94a" cache-control=no-cache
```

### `static: a fingerprinted name is immutable and a stale fingerprint is 404`

```bp
test "static: a fingerprinted name is immutable and a stale fingerprint is 404" {
    try assertStatic(@src(),
        ["static/app.7c9804.css=body{}", "static/app.000000.css=body{}"],
        ["GET /static/app.7c9804.css", "GET /static/app.000000.css"]);
}
```

`modules/rakun-web/test/static/__snapshots__/static/a-fingerprinted-name-is-immutable-and-a-stale-fingerprint-is-404.snap`
```
200 text/css; charset=utf-8 etag="7c98040a541657584690ae2a1cc3b42a8b53b159cc60c5d3abbfecbaeac6c94a" cache-control=public, max-age=31536000, immutable
404 - etag=- cache-control=-
```

### `static: traversal encoded traversal and an absolute path answer 404 and double encoding 400`

```bp
test "static: traversal encoded traversal and an absolute path answer 404 and double encoding 400" {
    try assertStatic(@src(),
        ["static/app.css=body{}"],
        [
            "GET /static/../../etc/passwd",
            "GET /static/%2e%2e%2fsecret.txt",
            "GET /static/%252e%252e%252fsecret.txt",
            "GET /static//etc/passwd",
        ]);
}
```

`modules/rakun-web/test/static/__snapshots__/static/traversal-encoded-traversal-and-an-absolute-path-answer-404-and-double-encoding-400.snap`
```
404 - etag=- cache-control=-
404 - etag=- cache-control=-
400 - etag=- cache-control=-
404 - etag=- cache-control=-
```

### `static: content type comes from the extension and an unknown one is octet-stream`

```bp
test "static: content type comes from the extension and an unknown one is octet-stream" {
    try assertStatic(@src(),
        ["public/client.mjs=console.log(1)", "public/logo.svg=<svg/>", "public/font.woff2=AAAA", "public/archive.zzz=zzz"],
        ["GET /public/client.mjs", "GET /public/logo.svg", "GET /public/font.woff2", "GET /public/archive.zzz"]);
}
```

`modules/rakun-web/test/static/__snapshots__/static/content-type-comes-from-the-extension-and-an-unknown-one-is-octet-stream.snap`
```
200 text/javascript; charset=utf-8 etag="0a286891c11c056e1ab5bfc25bf5d6b2f5b06d38eac10944f678fd8a2e70c393" cache-control=no-cache
200 image/svg+xml etag="d4dc56669143034f31aa309635d4113d9ad76a02b1739da22c965ed2049be9e6" cache-control=no-cache
200 font/woff2 etag="63c1dd951ffedf6f7fd968ad4efa39b8ed584f162f46e715114ee184f8de9201" cache-control=no-cache
200 application/octet-stream etag="17f165d5a5ba695f27c023a83aa2b3463e23810e360b7517127e90161eebabda" cache-control=no-cache
```

### `static: a directory serves its index and one without an index is 404 never a listing`

```bp
test "static: a directory serves its index and one without an index is 404 never a listing" {
    try assertStatic(@src(),
        ["public/docs/index.html=<h1>hi</h1>", "public/empty/notes.txt=zzz"],
        ["GET /public/docs/", "GET /public/empty/", "GET /api/users"]);
}
```

`modules/rakun-web/test/static/__snapshots__/static/a-directory-serves-its-index-and-one-without-an-index-is-404-never-a-listing.snap`
```
200 text/html; charset=utf-8 etag="e7fbb6fbbf4ce294913eb62b53ff03a7546649cfdc0d824d9e3a2b4541502f7f" cache-control=no-cache
404 - etag=- cache-control=-
404 - etag=- cache-control=-
```

### `static: a range answers 206 and an unsatisfiable range 416`

```bp
test "static: a range answers 206 and an unsatisfiable range 416" {
    try assertStatic(@src(),
        ["static/app.css=body{}"],
        ["GET /static/app.css Range: bytes=0-3", "GET /static/app.css Range: bytes=999-1000", "GET /static/app.css Range: bytes=0-1,3-4"]);
}
```

`modules/rakun-web/test/static/__snapshots__/static/a-range-answers-206-and-an-unsatisfiable-range-416.snap`
```
206 text/css; charset=utf-8 etag="7c98040a541657584690ae2a1cc3b42a8b53b159cc60c5d3abbfecbaeac6c94a" cache-control=no-cache
416 - etag="7c98040a541657584690ae2a1cc3b42a8b53b159cc60c5d3abbfecbaeac6c94a" cache-control=no-cache
200 text/css; charset=utf-8 etag="7c98040a541657584690ae2a1cc3b42a8b53b159cc60c5d3abbfecbaeac6c94a" cache-control=no-cache
```

## 83-rakun-distributed-transactions — `rakun-tx`

**Test file:** `modules/rakun-tx/test/outbox_test.bp` (suite `outbox`, `assertOutbox`) · `modules/rakun-tx/test/saga_test.bp` (suite `saga`, `assertSaga`) · **Snapshots:** `modules/rakun-tx/test/__snapshots__/{outbox,saga}/` · **Target:** erlang (front 08's test datasource + front 19's broker double) · **Pins:** Step 1 a committed enrolment appears once, a rolled-back one nowhere, `publishAfterCommit` outside a transaction publishes nothing; Step 2 a pending row is published and marked sent, a relay killed between publish and mark republishes (at-least-once), a failed publish leaves the row pending, one aggregate's rows publish in `seq` order; Step 4 all-ok → three forward entries and no compensation, failure at step 3 compensates 2 then 1, failure at step 1 compensates nothing, a failing compensation is retried to the ceiling and parks

Outbox script verbs are the README's fixtures (§ *Examples*): `place <id>`, `place-then-raise <id>`, `amend <id> <cents>`, `publish-outside <id>`, `kill-relay-after-publish`, `broker-down`, `relay`. Saga script: `fail-next <step>`, `fail-always <call>`, `start <ctx>`.

> helper gap: the inbox (Step 3), 2PC (Step 5), broker-native transactions (Step 6), `needs_attention` state and coordinator resume after a kill render through no helper — they stay in the README's injection-point tests.

Shared outbox source:

```bp
\\ import {service, repository} from "rakun";
\\ import {transactional, SqlTemplate} from "rakun-data";
\\ import {OutboxMessage, publishAfterCommit} from "rakun-tx";
\\
\\ #[repository]
\\ pub type OrderRepo(
\\     sql: SqlTemplate,
\\ ) {
\\     pub fn insert(self: Self, id: string, customer: string, cents: i32) -> i32 {
\\         return self.sql.update("insert into orders (id, customer, cents) values ($1, $2, $3)", [id, customer, cents.toString()]);
\\     }
\\ }
\\
\\ #[service]
\\ pub type Orders(
\\     repo: OrderRepo,
\\ ) {
\\     #[transactional]
\\     pub fn place(self: Self, id: string, customer: string, cents: i32) -> string {
\\         self.repo.insert(id, customer, cents);
\\         val headers = [#("content-type", "application/json"), #("order-id", id)];
\\         val payload = "{\"id\":\"" + id + "\",\"customer\":\"" + customer + "\",\"cents\":" + cents.toString() + "}";
\\         val event = OutboxMessage(
\\             aggregate: "order:" + id,
\\             topic: "order.placed",
\\             key: id,
\\             payload: payload,
\\             headers: headers,
\\         );
\\         publishAfterCommit(event);
\\         return id;
\\     }
\\ }
```

### `outbox: a committed order leaves one pending row and the relay publishes it once`

```bp
test "outbox: a committed order leaves one pending row and the relay publishes it once" {
    try assertOutbox(@src(),
        \\ <shared outbox source>
        , ["place o-1", "relay", "relay"]);
}
```

`modules/rakun-tx/test/__snapshots__/outbox/a-committed-order-leaves-one-pending-row-and-the-relay-publishes-it-once.snap`
```
write orders
write rakun_outbox
outbox 1 pending
relay -> published order.placed
outbox 0 pending
outbox 0 pending
```

### `outbox: a rolled-back order and a publish outside a transaction leave nothing`

```bp
test "outbox: a rolled-back order and a publish outside a transaction leave nothing" {
    try assertOutbox(@src(),
        \\ <shared outbox source>
        , ["place-then-raise o-2", "publish-outside o-3", "relay"]);
}
```

`modules/rakun-tx/test/__snapshots__/outbox/a-rolled-back-order-and-a-publish-outside-a-transaction-leave-nothing.snap`
```
outbox 0 pending
outbox 0 pending
outbox 0 pending
```

### `outbox: a relay killed between publish and mark republishes rather than losing`

```bp
test "outbox: a relay killed between publish and mark republishes rather than losing" {
    try assertOutbox(@src(),
        \\ <shared outbox source>
        , ["place o-5", "kill-relay-after-publish", "relay"]);
}
```

`modules/rakun-tx/test/__snapshots__/outbox/a-relay-killed-between-publish-and-mark-republishes-rather-than-losing.snap`
```
write orders
write rakun_outbox
outbox 1 pending
relay -> published order.placed
outbox 1 pending
relay -> published order.placed
outbox 0 pending
```

### `outbox: a failed publish leaves the row pending`

```bp
test "outbox: a failed publish leaves the row pending" {
    try assertOutbox(@src(),
        \\ <shared outbox source>
        , ["place o-6", "broker-down", "relay"]);
}
```

`modules/rakun-tx/test/__snapshots__/outbox/a-failed-publish-leaves-the-row-pending.snap`
```
write orders
write rakun_outbox
outbox 1 pending
relay -> failed broker unavailable
outbox 1 pending
```

### `outbox: two messages for one aggregate publish in seq order`

```bp
test "outbox: two messages for one aggregate publish in seq order" {
    try assertOutbox(@src(),
        \\ <shared outbox source>
        , ["place o-4", "amend o-4 200", "relay"]);
}
```

`modules/rakun-tx/test/__snapshots__/outbox/two-messages-for-one-aggregate-publish-in-seq-order.snap`
```
write orders
write rakun_outbox
write orders
write rakun_outbox
outbox 2 pending
relay -> published order.placed
relay -> published order.placed
outbox 0 pending
```

Shared saga source:

```bp
\\ import {Saga, SagaStep, startSaga} from "rakun-tx";
\\ import {seats, payments, tickets} from "rakun-tx";
\\
\\ pub fn bookingSaga() -> Saga {
\\     val steps = [
\\         SagaStep(
\\             name: "reserve-seat",
\\             run: { ctx -> seats().reserve(ctx) },
\\             compensate: { ctx -> seats().release(ctx) },
\\         ),
\\         SagaStep(
\\             name: "charge-card",
\\             run: { ctx -> payments().charge(ctx) },
\\             compensate: { ctx -> payments().refund(ctx) },
\\         ),
\\         SagaStep(
\\             name: "issue-ticket",
\\             run: { ctx -> tickets().issue(ctx) },
\\             compensate: { ctx -> tickets().void(ctx) },
\\         ),
\\     ];
\\     return Saga(
\\         name: "booking",
\\         steps: steps,
\\         retries: 3,
\\         backoffMs: 250,
\\     );
\\ }
```

### `saga: every step succeeding completes with no compensation`

```bp
test "saga: every step succeeding completes with no compensation" {
    try assertSaga(@src(),
        \\ <shared saga source>
        , ["start customer=ana&showing=s1"]);
}
```

`modules/rakun-tx/test/__snapshots__/saga/every-step-succeeding-completes-with-no-compensation.snap`
```
step reserve-seat ok
step charge-card ok
step issue-ticket ok
```

### `saga: a failure at step three compensates two then one`

```bp
test "saga: a failure at step three compensates two then one" {
    try assertSaga(@src(),
        \\ <shared saga source>
        , ["fail-next issue-ticket", "start customer=bob&showing=s1"]);
}
```

`modules/rakun-tx/test/__snapshots__/saga/a-failure-at-step-three-compensates-two-then-one.snap`
```
step reserve-seat ok
step charge-card ok
step issue-ticket failed
compensate charge-card
compensate reserve-seat
```

### `saga: a failure at step one compensates nothing`

```bp
test "saga: a failure at step one compensates nothing" {
    try assertSaga(@src(),
        \\ <shared saga source>
        , ["fail-next reserve-seat", "start customer=cleo&showing=s2"]);
}
```

`modules/rakun-tx/test/__snapshots__/saga/a-failure-at-step-one-compensates-nothing.snap`
```
step reserve-seat failed
```

### `saga: a compensation that cannot complete is retried to the ceiling and parks`

Three `compensate charge-card` lines are the three configured retries; no `compensate reserve-seat` follows because the saga parks in `needs_attention` (state per README § *The saga*; not rendered).

```bp
test "saga: a compensation that cannot complete is retried to the ceiling and parks" {
    try assertSaga(@src(),
        \\ <shared saga source>
        , ["fail-next issue-ticket", "fail-always refund", "start customer=eve&showing=s4"]);
}
```

`modules/rakun-tx/test/__snapshots__/saga/a-compensation-that-cannot-complete-is-retried-to-the-ceiling-and-parks.snap`
```
step reserve-seat ok
step charge-card ok
step issue-ticket failed
compensate charge-card
compensate charge-card
compensate charge-card
```

## 11-rakun-actuator — `rakun-actuator-api`

**Test file:** `modules/rakun-actuator-api/test/registration_test.bp` · **Snapshots:** `modules/rakun-actuator-api/test/__snapshots__/registry/` · **Target:** erlang · **Pins:** Step 0 — `#[healthIndicator("db")]` with the API module as the only actuator dependency, registration succeeds with the host absent, nothing in the module decides a status/route/exposure (the body is registrations only)

### `registry: a health indicator registers by id with the host absent`

```bp
test "registry: a health indicator registers by id with the host absent" {
    try assertRegistry(@src(),
        \\ import {managed} from "rakun";
        \\ import {Health, healthIndicator, rkRegisterHealthIndicator} from "rakun-actuator-api";
        \\
        \\ #[healthIndicator("db")]
        \\ #[managed]
        \\ pub type DataSourceHealth {
        \\     pub fn check(self: Self) -> Health {
        \\         return Health(status: "UP", details: "{}");
        \\     }
        \\ }
    );
}
```

`modules/rakun-actuator-api/test/__snapshots__/registry/a-health-indicator-registers-by-id-with-the-host-absent.snap`
```
health db
```

### `registry: an info contributor and an endpoint register under their ids`

```bp
test "registry: an info contributor and an endpoint register under their ids" {
    try assertRegistry(@src(),
        \\ import {Request, managed} from "rakun";
        \\ import {Endpoint, EndpointResponse, InfoContributor} from "rakun-actuator-api";
        \\ import {infoContributor, endpoint} from "rakun-actuator-api";
        \\ import {rkRegisterInfoContributor, rkRegisterEndpoint} from "rakun-actuator-api";
        \\
        \\ #[infoContributor("deployment")]
        \\ #[managed]
        \\ pub type DeploymentInfo {
        \\     pub fn contribute(self: Self) -> string {
        \\         return "{\"deployment\": {\"region\": \"eu-west-1\"}}";
        \\     }
        \\ }
        \\
        \\ #[endpoint("queue")]
        \\ #[managed]
        \\ pub type QueueEndpoint implement Endpoint {
        \\     pub fn id(self: Self) -> string {
        \\         return "queue";
        \\     }
        \\
        \\     pub fn read(self: Self, req: Request) -> EndpointResponse {
        \\         return EndpointResponse(status: 200, contentType: "application/json", body: "{\"depth\":7}");
        \\     }
        \\ }
    );
}
```

`modules/rakun-actuator-api/test/__snapshots__/registry/an-info-contributor-and-an-endpoint-register-under-their-ids.snap`
```
info deployment
endpoint queue [read]
```

### `registry: two indicators and two endpoints render sorted by name`

```bp
test "registry: two indicators and two endpoints render sorted by name" {
    try assertRegistry(@src(),
        \\ import {Request, managed} from "rakun";
        \\ import {Health, Endpoint, EndpointResponse} from "rakun-actuator-api";
        \\ import {healthIndicator, endpoint} from "rakun-actuator-api";
        \\ import {rkRegisterHealthIndicator, rkRegisterEndpoint} from "rakun-actuator-api";
        \\
        \\ #[healthIndicator("workQueue")]
        \\ #[managed]
        \\ pub type WorkQueueHealth {
        \\     pub fn check(self: Self) -> Health {
        \\         return Health(status: "UP", details: "{}");
        \\     }
        \\ }
        \\
        \\ #[healthIndicator("db")]
        \\ #[managed]
        \\ pub type DataSourceHealth {
        \\     pub fn check(self: Self) -> Health {
        \\         return Health(status: "UP", details: "{}");
        \\     }
        \\ }
        \\
        \\ #[endpoint("queue")]
        \\ #[managed]
        \\ pub type QueueEndpoint implement Endpoint {
        \\     pub fn id(self: Self) -> string {
        \\         return "queue";
        \\     }
        \\
        \\     pub fn read(self: Self, req: Request) -> EndpointResponse {
        \\         return EndpointResponse(status: 200, contentType: "application/json", body: "{}");
        \\     }
        \\ }
        \\
        \\ #[endpoint("caches")]
        \\ #[managed]
        \\ pub type CachesEndpoint implement Endpoint {
        \\     pub fn id(self: Self) -> string {
        \\         return "caches";
        \\     }
        \\
        \\     pub fn read(self: Self, req: Request) -> EndpointResponse {
        \\         return EndpointResponse(status: 200, contentType: "application/json", body: "[]");
        \\     }
        \\ }
    );
}
```

`modules/rakun-actuator-api/test/__snapshots__/registry/two-indicators-and-two-endpoints-render-sorted-by-name.snap`
```
health db
health workQueue
endpoint caches [read]
endpoint queue [read]
```

## 11-rakun-actuator — `rakun-actuator`

**Test file:** `modules/rakun-actuator/test/health_test.bp` (suite `health`) · `modules/rakun-actuator/test/endpoint_test.bp` (suite `endpoint`) · **Snapshots:** `modules/rakun-actuator/test/__snapshots__/health/`, `modules/rakun-actuator/test/__snapshots__/endpoint/` · **Target:** erlang · **Pins:** Step 3 — only `ping` answers `{"status":"UP"}`, one `DOWN` makes the aggregate `DOWN`, a raising indicator becomes `DOWN` with the reason and the endpoint still answers, a timed-out indicator becomes `UNKNOWN`; Step 1 — `#[endpoint("x")]` reachable at `/actuator/x`, unknown id answers 404 through front 07's problem-detail shape, `base-path=/manage` moves every endpoint

### `health: with only ping the aggregate is UP`

```bp
test "health: with only ping the aggregate is UP" {
    try assertHealth(@src(),
        \\ import {rkScan} from "rakun";
        , ["check"]);
}
```

`modules/rakun-actuator/test/__snapshots__/health/with-only-ping-the-aggregate-is-up.snap`
```
status UP
components:
  ping UP {}
```

### `health: one DOWN indicator makes the aggregate DOWN`

```bp
test "health: one DOWN indicator makes the aggregate DOWN" {
    try assertHealth(@src(),
        \\ import {managed} from "rakun";
        \\ import {Health, healthIndicator, rkRegisterHealthIndicator} from "rakun-actuator-api";
        \\
        \\ #[healthIndicator("workQueue")]
        \\ #[managed]
        \\ pub type WorkQueueHealth {
        \\     pub fn check(self: Self) -> Health {
        \\         return Health(status: "DOWN", details: "{\"depth\":1200}");
        \\     }
        \\ }
        , ["check"]);
}
```

`modules/rakun-actuator/test/__snapshots__/health/one-down-indicator-makes-the-aggregate-down.snap`
```
status DOWN
components:
  ping UP {}
  workQueue DOWN {"depth":1200}
```

### `health: an indicator that raises becomes DOWN with the reason and the endpoint still answers`

```bp
test "health: an indicator that raises becomes DOWN with the reason and the endpoint still answers" {
    try assertHealth(@src(),
        \\ import {managed} from "rakun";
        \\ import {Health, healthIndicator, rkRegisterHealthIndicator} from "rakun-actuator-api";
        \\
        \\ #[healthIndicator("flaky")]
        \\ #[managed]
        \\ pub type FlakyHealth {
        \\     pub fn check(self: Self) -> Health {
        \\         @panic("broker unreachable");
        \\     }
        \\ }
        , ["check"]);
}
```

`modules/rakun-actuator/test/__snapshots__/health/an-indicator-that-raises-becomes-down-with-the-reason-and-the-endpoint-still-answers.snap`
```
status DOWN
components:
  flaky DOWN {"error":"broker unreachable"}
  ping UP {}
```

### `health: an indicator past its timeout becomes UNKNOWN and is abandoned`

```bp
test "health: an indicator past its timeout becomes UNKNOWN and is abandoned" {
    try assertHealth(@src(),
        \\ import {managed, rkSetProp} from "rakun";
        \\ import {Health, healthIndicator, rkRegisterHealthIndicator} from "rakun-actuator-api";
        \\
        \\ val _t = rkSetProp("management.health.slow.timeout", "100ms");
        \\
        \\ #[healthIndicator("slow")]
        \\ #[managed]
        \\ pub type SlowHealth {
        \\     pub fn check(self: Self) -> Health {
        \\         return Health(status: "UP", details: "{}");
        \\     }
        \\ }
        , ["stall slow", "check"]);
}
```

`modules/rakun-actuator/test/__snapshots__/health/an-indicator-past-its-timeout-becomes-unknown-and-is-abandoned.snap`
```
status UNKNOWN
components:
  ping UP {}
  slow UNKNOWN {"error":"timeout after 100ms"}
```

### `endpoint: an application endpoint is reachable by id under the base path`

```bp
test "endpoint: an application endpoint is reachable by id under the base path" {
    try assertEndpoint(@src(),
        \\ import {Request, managed} from "rakun";
        \\ import {Endpoint, EndpointResponse, endpoint, rkRegisterEndpoint} from "rakun-actuator-api";
        \\
        \\ #[endpoint("queue")]
        \\ #[managed]
        \\ pub type QueueEndpoint implement Endpoint {
        \\     pub fn id(self: Self) -> string {
        \\         return "queue";
        \\     }
        \\
        \\     pub fn read(self: Self, req: Request) -> EndpointResponse {
        \\         return EndpointResponse(status: 200, contentType: "application/json", body: "{\"depth\":7,\"oldestAgeSeconds\":12}");
        \\     }
        \\ }
        , "GET /actuator/queue");
}
```

`modules/rakun-actuator/test/__snapshots__/endpoint/an-application-endpoint-is-reachable-by-id-under-the-base-path.snap`
```
200
depth: 7
oldestAgeSeconds: 12
```

### `endpoint: an unknown id answers 404 through the problem-detail shape`

```bp
test "endpoint: an unknown id answers 404 through the problem-detail shape" {
    try assertEndpoint(@src(),
        \\ import {rkScan} from "rakun";
        , "GET /actuator/nope");
}
```

`modules/rakun-actuator/test/__snapshots__/endpoint/an-unknown-id-answers-404-through-the-problem-detail-shape.snap`
```
404
detail: "no endpoint registered as nope"
instance: "/actuator/nope"
status: 404
title: "Not Found"
type: "about:blank"
```

### `endpoint: base-path moves every endpoint`

```bp
test "endpoint: base-path moves every endpoint" {
    try assertEndpoint(@src(),
        \\ import {Request, managed, rkSetProp} from "rakun";
        \\ import {Endpoint, EndpointResponse, endpoint, rkRegisterEndpoint} from "rakun-actuator-api";
        \\
        \\ val _bp = rkSetProp("management.endpoints.web.base-path", "/manage");
        \\
        \\ #[endpoint("queue")]
        \\ #[managed]
        \\ pub type QueueEndpoint implement Endpoint {
        \\     pub fn id(self: Self) -> string {
        \\         return "queue";
        \\     }
        \\
        \\     pub fn read(self: Self, req: Request) -> EndpointResponse {
        \\         return EndpointResponse(status: 200, contentType: "application/json", body: "{\"depth\":7}");
        \\     }
        \\ }
        , "GET /manage/queue");
}
```

`modules/rakun-actuator/test/__snapshots__/endpoint/base-path-moves-every-endpoint.snap`
```
200
depth: 7
```

## 12-rakun-cache — `rakun-cache`

**Test file:** `modules/rakun-cache/test/cache_test.bp` · **Snapshots:** `modules/rakun-cache/test/__snapshots__/cache/` · **Target:** erlang · **Pins:** Step 3 — kill switch (`rakun.cache.type=none`) runs the loader on every call, a second call with the same keys does not run the loader, two calls with different keys both run it; Step 4 — `#[cacheEvict(name, true)]` clears the whole cache after the delegate returns; Step 5 — `revalidateTag` stale-then-fresh, an entry carrying two tags is invalidated by either; Definition of done — one store, written through `#[cacheable]` and read through `cacheThrough` on the same key

> helper gap: `key=<k>` is rendered as `<namespace>:<parts joined by ,>` (the pre-hash form of `cacheKey`) — the content hash is opaque and a snapshot of it pins nothing a reader can check.

### `cache: a second cacheable call with the same key is a hit`

```bp
test "cache: a second cacheable call with the same key is a hit" {
    try assertCache(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {cached, cacheable, cacheEvict} from "rakun-cache";
        \\ import {rkCacheEnabled, rkCacheLookup, rkCachePut, rkCacheEvict, rkCacheClear} from "rakun-cache";
        \\
        \\ val _t = rkSetProp("rakun.cache.type", "ets");
        \\
        \\ #[cached]
        \\ pub behavior ProductCatalog {
        \\     #[cacheable("products")]
        \\     fn productJson(self: Self, id: string) -> string;
        \\ }
        \\
        \\ #[service]
        \\ pub type SqlProductCatalog implement ProductCatalog {
        \\     pub fn productJson(self: Self, id: string) -> string {
        \\         return "{\"id\":\"" + id + "\"}";
        \\     }
        \\ }
        \\
        \\ #[configuration]
        \\ pub type CatalogConfig(
        \\     real: SqlProductCatalog,
        \\ ) {
        \\     #[bean]
        \\     pub fn productCatalog(self: Self) -> ProductCatalog {
        \\         return cachedProductCatalog(self.real);
        \\     }
        \\ }
        , ["ProductCatalog.productJson(7)", "ProductCatalog.productJson(7)"]);
}
```

`modules/rakun-cache/test/__snapshots__/cache/a-second-cacheable-call-with-the-same-key-is-a-hit.snap`
```
ProductCatalog.productJson(7) -> miss key=products:productJson,7 []
ProductCatalog.productJson(7) -> hit key=products:productJson,7 []
```

### `cache: two calls with different keys both run the loader`

```bp
test "cache: two calls with different keys both run the loader" {
    try assertCache(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {cached, cacheable, cacheEvict} from "rakun-cache";
        \\ import {rkCacheEnabled, rkCacheLookup, rkCachePut, rkCacheEvict, rkCacheClear} from "rakun-cache";
        \\
        \\ val _t = rkSetProp("rakun.cache.type", "ets");
        \\
        \\ #[cached]
        \\ pub behavior ProductCatalog {
        \\     #[cacheable("products")]
        \\     fn productJson(self: Self, id: string) -> string;
        \\ }
        \\
        \\ #[service]
        \\ pub type SqlProductCatalog implement ProductCatalog {
        \\     pub fn productJson(self: Self, id: string) -> string {
        \\         return "{\"id\":\"" + id + "\"}";
        \\     }
        \\ }
        \\
        \\ #[configuration]
        \\ pub type CatalogConfig(
        \\     real: SqlProductCatalog,
        \\ ) {
        \\     #[bean]
        \\     pub fn productCatalog(self: Self) -> ProductCatalog {
        \\         return cachedProductCatalog(self.real);
        \\     }
        \\ }
        , ["ProductCatalog.productJson(7)", "ProductCatalog.productJson(8)"]);
}
```

`modules/rakun-cache/test/__snapshots__/cache/two-calls-with-different-keys-both-run-the-loader.snap`
```
ProductCatalog.productJson(7) -> miss key=products:productJson,7 []
ProductCatalog.productJson(8) -> miss key=products:productJson,8 []
```

### `cache: cacheEvict with allEntries clears the whole cache after the delegate returns`

```bp
test "cache: cacheEvict with allEntries clears the whole cache after the delegate returns" {
    try assertCache(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {cached, cacheable, cacheEvict} from "rakun-cache";
        \\ import {rkCacheEnabled, rkCacheLookup, rkCachePut, rkCacheEvict, rkCacheClear} from "rakun-cache";
        \\
        \\ val _t = rkSetProp("rakun.cache.type", "ets");
        \\
        \\ #[cached]
        \\ pub behavior ProductCatalog {
        \\     #[cacheable("products")]
        \\     fn productJson(self: Self, id: string) -> string;
        \\
        \\     #[cacheEvict("products", true)]
        \\     fn reprice(self: Self, id: string, body: string) -> string;
        \\ }
        \\
        \\ #[service]
        \\ pub type SqlProductCatalog implement ProductCatalog {
        \\     pub fn productJson(self: Self, id: string) -> string {
        \\         return "{\"id\":\"" + id + "\"}";
        \\     }
        \\
        \\     pub fn reprice(self: Self, id: string, body: string) -> string {
        \\         return "{\"id\":\"" + id + "\",\"repriced\":true}";
        \\     }
        \\ }
        \\
        \\ #[configuration]
        \\ pub type CatalogConfig(
        \\     real: SqlProductCatalog,
        \\ ) {
        \\     #[bean]
        \\     pub fn productCatalog(self: Self) -> ProductCatalog {
        \\         return cachedProductCatalog(self.real);
        \\     }
        \\ }
        , [
            "ProductCatalog.productJson(7)",
            "ProductCatalog.reprice(7, {})",
            "ProductCatalog.productJson(7)",
        ]);
}
```

`modules/rakun-cache/test/__snapshots__/cache/cacheevict-with-allentries-clears-the-whole-cache-after-the-delegate-returns.snap`
```
ProductCatalog.productJson(7) -> miss key=products:productJson,7 []
ProductCatalog.reprice(7, {}) -> evict key=products:* []
ProductCatalog.productJson(7) -> miss key=products:productJson,7 []
```

### `cache: with rakun.cache.type=none every call runs the loader`

```bp
test "cache: with rakun.cache.type=none every call runs the loader" {
    try assertCache(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {cached, cacheable, cacheEvict} from "rakun-cache";
        \\ import {rkCacheEnabled, rkCacheLookup, rkCachePut, rkCacheEvict, rkCacheClear} from "rakun-cache";
        \\
        \\ val _t = rkSetProp("rakun.cache.type", "none");
        \\
        \\ #[cached]
        \\ pub behavior ProductCatalog {
        \\     #[cacheable("products")]
        \\     fn productJson(self: Self, id: string) -> string;
        \\ }
        \\
        \\ #[service]
        \\ pub type SqlProductCatalog implement ProductCatalog {
        \\     pub fn productJson(self: Self, id: string) -> string {
        \\         return "{\"id\":\"" + id + "\"}";
        \\     }
        \\ }
        \\
        \\ #[configuration]
        \\ pub type CatalogConfig(
        \\     real: SqlProductCatalog,
        \\ ) {
        \\     #[bean]
        \\     pub fn productCatalog(self: Self) -> ProductCatalog {
        \\         return cachedProductCatalog(self.real);
        \\     }
        \\ }
        , ["ProductCatalog.productJson(7)", "ProductCatalog.productJson(7)"]);
}
```

`modules/rakun-cache/test/__snapshots__/cache/with-rakun-cache-type-none-every-call-runs-the-loader.snap`
```
ProductCatalog.productJson(7) -> miss key=products:productJson,7 []
ProductCatalog.productJson(7) -> miss key=products:productJson,7 []
```

### `cache: cacheThrough reads the row the cacheable twin wrote`

```bp
test "cache: cacheThrough reads the row the cacheable twin wrote" {
    try assertCache(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {cached, cacheable, cacheEvict} from "rakun-cache";
        \\ import {cacheThrough, cachePolicy, cacheLife, CacheScope} from "rakun-cache";
        \\ import {rkCacheEnabled, rkCacheLookup, rkCachePut, rkCacheEvict, rkCacheClear} from "rakun-cache";
        \\
        \\ val _t = rkSetProp("rakun.cache.type", "ets");
        \\
        \\ #[cached]
        \\ pub behavior ProductCatalog {
        \\     #[cacheable("products")]
        \\     fn productJson(self: Self, id: string) -> string;
        \\ }
        \\
        \\ #[service]
        \\ pub type SqlProductCatalog implement ProductCatalog {
        \\     pub fn productJson(self: Self, id: string) -> string {
        \\         return "{\"id\":\"" + id + "\"}";
        \\     }
        \\ }
        \\
        \\ #[configuration]
        \\ pub type CatalogConfig(
        \\     real: SqlProductCatalog,
        \\ ) {
        \\     #[bean]
        \\     pub fn productCatalog(self: Self) -> ProductCatalog {
        \\         return cachedProductCatalog(self.real);
        \\     }
        \\ }
        \\
        \\ pub fn peekProduct(id: string) -> string {
        \\     val policy = cachePolicy(CacheScope.Shared, "products", cacheLife("hours"), []);
        \\     return cacheThrough(policy, ["productJson", id], { -> "loader ran" });
        \\ }
        , ["ProductCatalog.productJson(7)", "peekProduct(7)"]);
}
```

`modules/rakun-cache/test/__snapshots__/cache/cachethrough-reads-the-row-the-cacheable-twin-wrote.snap`
```
ProductCatalog.productJson(7) -> miss key=products:productJson,7 []
peekProduct(7) -> hit key=products:productJson,7 []
```

### `cache: revalidateTag serves the stale value once and the read after that is fresh`

```bp
test "cache: revalidateTag serves the stale value once and the read after that is fresh" {
    try assertCache(@src(),
        \\ import {rkSetProp} from "rakun";
        \\ import {cachePolicy, cacheThrough, cacheLife, CacheScope, revalidateTag} from "rakun-cache";
        \\ import {rkCacheEnabled, rkCacheLookup, rkCachePut, rkCachePhase} from "rakun-cache";
        \\
        \\ val _t = rkSetProp("rakun.cache.type", "ets");
        \\
        \\ fn loadProductsJson(page: string) -> string {
        \\     return "{\"page\":\"" + page + "\",\"items\":[]}";
        \\ }
        \\
        \\ pub fn productsJson(page: string) -> string {
        \\     val policy = cachePolicy(CacheScope.Shared, "products", cacheLife("hours"), ["products", "catalog"]);
        \\     return cacheThrough(policy, ["productsJson", page], { -> loadProductsJson(page) });
        \\ }
        \\
        \\ pub fn dropProducts() -> i32 {
        \\     return revalidateTag("products");
        \\ }
        , [
            "productsJson(1)",
            "dropProducts()",
            "productsJson(1)",
            "productsJson(1)",
        ]);
}
```

`modules/rakun-cache/test/__snapshots__/cache/revalidatetag-serves-the-stale-value-once-and-the-read-after-that-is-fresh.snap`
```
productsJson(1) -> miss key=products:productsJson,1 [products,catalog]
dropProducts() -> revalidate key=* [products]
productsJson(1) -> revalidate key=products:productsJson,1 [products,catalog]
productsJson(1) -> hit key=products:productsJson,1 [products,catalog]
```

### `cache: an entry carrying two tags is invalidated by either`

```bp
test "cache: an entry carrying two tags is invalidated by either" {
    try assertCache(@src(),
        \\ import {rkSetProp} from "rakun";
        \\ import {cachePolicy, cacheThrough, cacheLife, CacheScope, revalidateTag} from "rakun-cache";
        \\ import {rkCacheEnabled, rkCacheLookup, rkCachePut, rkCachePhase} from "rakun-cache";
        \\
        \\ val _t = rkSetProp("rakun.cache.type", "ets");
        \\
        \\ fn loadProductsJson(page: string) -> string {
        \\     return "{\"page\":\"" + page + "\",\"items\":[]}";
        \\ }
        \\
        \\ pub fn productsJson(page: string) -> string {
        \\     val policy = cachePolicy(CacheScope.Shared, "products", cacheLife("hours"), ["products", "catalog"]);
        \\     return cacheThrough(policy, ["productsJson", page], { -> loadProductsJson(page) });
        \\ }
        \\
        \\ pub fn dropCatalog() -> i32 {
        \\     return revalidateTag("catalog");
        \\ }
        , [
            "productsJson(1)",
            "productsJson(1)",
            "dropCatalog()",
            "productsJson(1)",
        ]);
}
```

`modules/rakun-cache/test/__snapshots__/cache/an-entry-carrying-two-tags-is-invalidated-by-either.snap`
```
productsJson(1) -> miss key=products:productsJson,1 [products,catalog]
productsJson(1) -> hit key=products:productsJson,1 [products,catalog]
dropCatalog() -> revalidate key=* [catalog]
productsJson(1) -> revalidate key=products:productsJson,1 [products,catalog]
```

## 13-rakun-http-clients — `rakun-client`

**Test file:** `modules/rakun-client/test/client_test.bp` · **Snapshots:** `modules/rakun-client/test/__snapshots__/client/` · **Target:** erlang · **Pins:** Step 1 — builder starts from the global settings and `defaultHeader` accumulates; Step 2 — `retrieve` and `retrieveFuture` agree on the same spec, a non-2xx is returned not raised, `POST` reaches the transport with its verb; Step 3 — loopback/link-local refused with status `-1` and no socket, `rakun.http.clients.allow` re-admits a range, a 302 to a private address is refused; Step 5 — `#[httpExchange]` substitutes `:param` from the method parameter and builds its client from `rakun.http.serviceclient.<group>.*`

Exchange strings are `"<Type>.<fn>(<args>) <- <stub status>[ <header>: <v>]*"` — the right-hand side is what the in-process stub answers; the stub listens on `127.0.0.1:18080`, so every source that reaches it re-admits `127.0.0.0/8` explicitly.

### `client: a GET carries the default headers and the configured base url`

```bp
test "client: a GET carries the default headers and the configured base url" {
    try assertClient(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {RestClient, RestClientBuilder, RequestSpec, ClientResponse} from "rakun-client";
        \\
        \\ val _allow = rkSetProp("rakun.http.clients.allow", "127.0.0.0/8");
        \\
        \\ #[configuration]
        \\ pub type PartnerClientConfig {
        \\     #[bean]
        \\     pub fn partnerClient(self: Self) -> RestClient {
        \\         return RestClient.builder()
        \\             .baseUrl("http://127.0.0.1:18080")
        \\             .defaultHeader("accept", "application/json")
        \\             .defaultHeader("authorization", "Bearer t-0001")
        \\             .build();
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type PartnerCatalog(
        \\     client: RestClient,
        \\ ) {
        \\     pub fn productJson(self: Self, id: string) -> string {
        \\         val res = self.client.get("/products/" + id).retrieve();
        \\         return res.body;
        \\     }
        \\ }
        , ["PartnerCatalog.productJson(7) <- 200"]);
}
```

`modules/rakun-client/test/__snapshots__/client/a-get-carries-the-default-headers-and-the-configured-base-url.snap`
```
GET http://127.0.0.1:18080/products/7 -> 200
accept: application/json
authorization: Bearer t-0001
```

### `client: retrieveFuture agrees with retrieve on the same spec`

```bp
test "client: retrieveFuture agrees with retrieve on the same spec" {
    try assertClient(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {RestClient, RequestSpec, ClientResponse, retrieveFuture} from "rakun-client";
        \\
        \\ val _allow = rkSetProp("rakun.http.clients.allow", "127.0.0.0/8");
        \\
        \\ #[configuration]
        \\ pub type PartnerClientConfig {
        \\     #[bean]
        \\     pub fn partnerClient(self: Self) -> RestClient {
        \\         return RestClient.builder()
        \\             .baseUrl("http://127.0.0.1:18080")
        \\             .defaultHeader("accept", "application/json")
        \\             .build();
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type PartnerCatalog(
        \\     client: RestClient,
        \\ ) {
        \\     pub fn productJson(self: Self, id: string) -> string {
        \\         return self.client.get("/products/" + id).retrieve().body;
        \\     }
        \\
        \\     #[@future]
        \\     pub fn productJsonLater(self: Self, id: string) -> @Future<string> {
        \\         val res = await retrieveFuture(self.client.get("/products/" + id));
        \\         return res.body;
        \\     }
        \\ }
        , ["PartnerCatalog.productJson(7) <- 200", "PartnerCatalog.productJsonLater(7) <- 200"]);
}
```

`modules/rakun-client/test/__snapshots__/client/retrievefuture-agrees-with-retrieve-on-the-same-spec.snap`
```
GET http://127.0.0.1:18080/products/7 -> 200
accept: application/json
GET http://127.0.0.1:18080/products/7 -> 200
accept: application/json
```

### `client: a non-2xx response is returned not raised`

```bp
test "client: a non-2xx response is returned not raised" {
    try assertClient(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {RestClient, RequestSpec, ClientResponse} from "rakun-client";
        \\
        \\ val _allow = rkSetProp("rakun.http.clients.allow", "127.0.0.0/8");
        \\
        \\ #[configuration]
        \\ pub type PartnerClientConfig {
        \\     #[bean]
        \\     pub fn partnerClient(self: Self) -> RestClient {
        \\         return RestClient.builder().baseUrl("http://127.0.0.1:18080").build();
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type PartnerCatalog(
        \\     client: RestClient,
        \\ ) {
        \\     pub fn productJson(self: Self, id: string) -> string {
        \\         val res = self.client.get("/products/" + id).retrieve();
        \\         val body = if (res.isOk()) { res.body } else { "{\"error\":" + res.status.toString() + "}" };
        \\         return body;
        \\     }
        \\ }
        , ["PartnerCatalog.productJson(7) <- 503"]);
}
```

`modules/rakun-client/test/__snapshots__/client/a-non-2xx-response-is-returned-not-raised.snap`
```
GET http://127.0.0.1:18080/products/7 -> 503
```

### `client: a POST reaches the transport with its verb and content type`

```bp
test "client: a POST reaches the transport with its verb and content type" {
    try assertClient(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {RestClient, RequestSpec, ClientResponse} from "rakun-client";
        \\
        \\ val _allow = rkSetProp("rakun.http.clients.allow", "127.0.0.0/8");
        \\
        \\ #[configuration]
        \\ pub type PartnerClientConfig {
        \\     #[bean]
        \\     pub fn partnerClient(self: Self) -> RestClient {
        \\         return RestClient.builder()
        \\             .baseUrl("http://127.0.0.1:18080")
        \\             .defaultHeader("accept", "application/json")
        \\             .build();
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type PartnerOrders(
        \\     client: RestClient,
        \\ ) {
        \\     pub fn submitOrder(self: Self, orderJson: string) -> string {
        \\         val res = self.client.post("/orders", orderJson)
        \\             .header("content-type", "application/json")
        \\             .retrieve();
        \\         return res.body;
        \\     }
        \\ }
        , ["PartnerOrders.submitOrder({\"sku\":\"a\"}) <- 201"]);
}
```

`modules/rakun-client/test/__snapshots__/client/a-post-reaches-the-transport-with-its-verb-and-content-type.snap`
```
POST http://127.0.0.1:18080/orders -> 201
accept: application/json
content-type: application/json
```

### `client: a link-local address is refused before any socket opens`

```bp
test "client: a link-local address is refused before any socket opens" {
    try assertClient(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {RestClient, RequestSpec, ClientResponse} from "rakun-client";
        \\
        \\ #[configuration]
        \\ pub type ProbeClientConfig {
        \\     #[bean]
        \\     pub fn probeClient(self: Self) -> RestClient {
        \\         return RestClient.builder().build();
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type WebhookProbe(
        \\     client: RestClient,
        \\ ) {
        \\     pub fn probe(self: Self, url: string) -> string {
        \\         val res = self.client.head(url).retrieve();
        \\         return res.status.toString() + " " + res.body;
        \\     }
        \\ }
        , ["WebhookProbe.probe(http://169.254.169.254/) <- 200", "WebhookProbe.probe(http://127.0.0.1:18080/) <- 200"]);
}
```

`modules/rakun-client/test/__snapshots__/client/a-link-local-address-is-refused-before-any-socket-opens.snap`
```
HEAD http://169.254.169.254/ -> -1
HEAD http://127.0.0.1:18080/ -> -1
```

### `client: a 302 to a private address is refused even from an admitted host`

```bp
test "client: a 302 to a private address is refused even from an admitted host" {
    try assertClient(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {RestClient, RequestSpec, ClientResponse} from "rakun-client";
        \\
        \\ val _allow = rkSetProp("rakun.http.clients.allow", "127.0.0.0/8");
        \\ val _follow = rkSetProp("rakun.http.clients.redirects", "follow");
        \\
        \\ #[configuration]
        \\ pub type PartnerClientConfig {
        \\     #[bean]
        \\     pub fn partnerClient(self: Self) -> RestClient {
        \\         return RestClient.builder().baseUrl("http://127.0.0.1:18080").build();
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type PartnerCatalog(
        \\     client: RestClient,
        \\ ) {
        \\     pub fn hop(self: Self) -> string {
        \\         return self.client.get("/hop").retrieve().body;
        \\     }
        \\ }
        , ["PartnerCatalog.hop() <- 302 location: http://10.0.0.1/secret"]);
}
```

`modules/rakun-client/test/__snapshots__/client/a-302-to-a-private-address-is-refused-even-from-an-admitted-host.snap`
```
GET http://127.0.0.1:18080/hop -> -1
```

### `client: httpExchange substitutes the path parameter from the method parameter`

```bp
test "client: httpExchange substitutes the path parameter from the method parameter" {
    try assertClient(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {httpExchange, getExchange, postExchange, deleteExchange} from "rakun-client";
        \\ import {RestClient, RequestSpec, ClientResponse} from "rakun-client";
        \\
        \\ val _allow = rkSetProp("rakun.http.clients.allow", "127.0.0.0/8");
        \\ val _base = rkSetProp("rakun.http.serviceclient.shipping.base-url", "http://127.0.0.1:18080");
        \\
        \\ #[httpExchange("shipping")]
        \\ pub behavior ShippingApi {
        \\     #[getExchange("/shipments/:trackingId")]
        \\     fn shipment(self: Self, trackingId: string) -> string;
        \\
        \\     #[deleteExchange("/shipments/:trackingId")]
        \\     fn cancelShipment(self: Self, trackingId: string) -> string;
        \\ }
        \\
        \\ #[configuration]
        \\ pub type ShippingConfig {
        \\     #[bean]
        \\     pub fn shippingApi(self: Self) -> ShippingApi {
        \\         return httpShippingApi();
        \\     }
        \\ }
        , ["ShippingApi.shipment(trk-0001) <- 200", "ShippingApi.cancelShipment(trk-0001) <- 204"]);
}
```

`modules/rakun-client/test/__snapshots__/client/httpexchange-substitutes-the-path-parameter-from-the-method-parameter.snap`
```
GET http://127.0.0.1:18080/shipments/trk-0001 -> 200
DELETE http://127.0.0.1:18080/shipments/trk-0001 -> 204
```

## 17-rakun-logging — `rakun-logging`

**Test file:** `modules/rakun-logging/test/format_test.bp` · **Snapshots:** `modules/rakun-logging/test/__snapshots__/log/` · **Target:** erlang · **Pins:** Step 2 — `ecs`, `gelf`, `logstash`, `plain` each produce their documented field set in fixed order, a quote and a newline round-trip through the JSON schemas; Step 1 — longest prefix wins and `root` applies with no key, a `Trace` record is discarded when the level is `Debug`; Step 3 — `rakun.logging.level.web=debug` raises every member of the predefined `web` group; Step 4 — every record of the request carries the correlation id

Event strings are `"<level> <logger> <message>[ | <k>=<v>,…]"`; the helper installs the fixed clock, the pid `<0.1.0>`, the node `node-0001` and the correlation id `trace-0001`. The application name key is `rakun.application.name` (name per README § The startup summary).

### `log: ecs renders the documented field set in fixed order`

```bp
test "log: ecs renders the documented field set in fixed order" {
    try assertLog(@src(),
        ["rakun.logging.structured.format.console=ecs", "rakun.application.name=billing"],
        ["info app.billing.invoices charging invoice | invoice.id=7"]);
}
```

`modules/rakun-logging/test/__snapshots__/log/ecs-renders-the-documented-field-set-in-fixed-order.snap`
```
{"@timestamp":"2026-01-01T00:00:00Z","log.level":"INFO","message":"charging invoice","service.name":"billing","process.thread.name":"<0.1.0>","log.logger":"app.billing.invoices","trace.id":"trace-0001","invoice.id":"7"}
```

### `log: gelf renders the documented field set with underscore extras`

```bp
test "log: gelf renders the documented field set with underscore extras" {
    try assertLog(@src(),
        ["rakun.logging.structured.format.console=gelf", "rakun.application.name=billing"],
        ["warn app.billing.invoices charge declined | invoice.id=7,gateway.code=51"]);
}
```

`modules/rakun-logging/test/__snapshots__/log/gelf-renders-the-documented-field-set-with-underscore-extras.snap`
```
{"version":"1.1","host":"node-0001","short_message":"charge declined","timestamp":1767225600,"level":4,"_logger":"app.billing.invoices","_trace_id":"trace-0001","_invoice_id":"7","_gateway_code":"51"}
```

### `log: logstash renders the documented field set`

```bp
test "log: logstash renders the documented field set" {
    try assertLog(@src(),
        ["rakun.logging.structured.format.console=logstash", "rakun.application.name=billing"],
        ["error app.billing.invoices gateway unreachable"]);
}
```

`modules/rakun-logging/test/__snapshots__/log/logstash-renders-the-documented-field-set.snap`
```
{"@timestamp":"2026-01-01T00:00:00Z","@version":"1","message":"gateway unreachable","logger_name":"app.billing.invoices","level":"ERROR","level_value":40000}
```

### `log: plain renders the console line`

```bp
test "log: plain renders the console line" {
    try assertLog(@src(),
        ["rakun.logging.structured.format.console=plain", "rakun.application.name=billing"],
        ["info app.billing.invoices charging invoice", "warn app.billing.invoices charge declined"]);
}
```

`modules/rakun-logging/test/__snapshots__/log/plain-renders-the-console-line.snap`
```
2026-01-01T00:00:00Z  INFO <0.1.0> --- [billing] [main] app.billing.invoices : charging invoice
2026-01-01T00:00:00Z  WARN <0.1.0> --- [billing] [main] app.billing.invoices : charge declined
```

### `log: a quote and a newline round-trip through ecs`

```bp
test "log: a quote and a newline round-trip through ecs" {
    try assertLog(@src(),
        ["rakun.logging.structured.format.console=ecs", "rakun.application.name=billing"],
        ["info app.billing.invoices say \"hi\"\nthen \\ stop"]);
}
```

`modules/rakun-logging/test/__snapshots__/log/a-quote-and-a-newline-round-trip-through-ecs.snap`
```
{"@timestamp":"2026-01-01T00:00:00Z","log.level":"INFO","message":"say \"hi\"\nthen \\ stop","service.name":"billing","process.thread.name":"<0.1.0>","log.logger":"app.billing.invoices","trace.id":"trace-0001"}
```

### `log: a trace record is discarded when the level is debug and root applies elsewhere`

```bp
test "log: a trace record is discarded when the level is debug and root applies elsewhere" {
    try assertLog(@src(),
        ["rakun.logging.structured.format.console=plain", "rakun.application.name=billing", "rakun.logging.level.app.billing=debug"],
        [
            "trace app.billing.invoices building request",
            "debug app.billing.invoices gateway result=0",
            "debug app.other pool idle",
            "info app.other pool ready",
        ]);
}
```

`modules/rakun-logging/test/__snapshots__/log/a-trace-record-is-discarded-when-the-level-is-debug-and-root-applies-elsewhere.snap`
```
2026-01-01T00:00:00Z DEBUG <0.1.0> --- [billing] [main] app.billing.invoices : gateway result=0
2026-01-01T00:00:00Z  INFO <0.1.0> --- [billing] [main] app.other : pool ready
```

### `log: longest prefix wins and the web group raises every member`

```bp
test "log: longest prefix wins and the web group raises every member" {
    try assertLog(@src(),
        [
            "rakun.logging.structured.format.console=plain",
            "rakun.application.name=billing",
            "rakun.logging.level.rakun.data=debug",
            "rakun.logging.level.rakun.data.sql=warn",
            "rakun.logging.level.web=debug",
        ],
        [
            "debug rakun.data.sql select 1",
            "debug rakun.data.datasource pool idle",
            "warn rakun.data.sql slow query",
            "debug rakun.client GET /products",
            "debug rakun.core.router matched /api",
        ]);
}
```

`modules/rakun-logging/test/__snapshots__/log/longest-prefix-wins-and-the-web-group-raises-every-member.snap`
```
2026-01-01T00:00:00Z DEBUG <0.1.0> --- [billing] [main] rakun.data.datasource : pool idle
2026-01-01T00:00:00Z  WARN <0.1.0> --- [billing] [main] rakun.data.sql : slow query
2026-01-01T00:00:00Z DEBUG <0.1.0> --- [billing] [main] rakun.client : GET /products
2026-01-01T00:00:00Z DEBUG <0.1.0> --- [billing] [main] rakun.core.router : matched /api
```

## 21-rakun-hateoas — `rakun-hateoas`

**Test file:** `modules/rakun-hateoas/test/hal_test.bp` · **Snapshots:** `modules/rakun-hateoas/test/__snapshots__/hal/` · **Target:** erlang · **Pins:** Step 2 — `#[halResource]` emits `userResourceToHal`, strings quoted and escaped, `i32`/`bool` bare, field order = declaration order; Step 1 — `link(rel, href)` renders `{"href":…}`, empty `title` omitted and `templated` only when true, duplicate `rel` becomes an array in insertion order, a quote in an `href` is escaped; Step 3 — `_embedded` keyed by `rel`, empty collection keeps the key, paging links in order; Step 4 — `linkTo` substitutes `:id` and percent-encodes `/`

`call` is `"<Type>.<fn>(<args>)"` or `"<fn>(<args>)"` resolved in the scanned source. The helper prints `_links` first and then the remaining top-level keys sorted; values are the JSON the subject produced, byte for byte.

### `hal: a resource renders its fields and its self link`

```bp
test "hal: a resource renders its fields and its self link" {
    try assertHal(@src(),
        \\ import {service, restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {halResource, Link, link, linkTo, halResponse} from "rakun-hateoas";
        \\ import {renderLinks, quoteJsonString} from "rakun-hateoas";
        \\
        \\ #[halResource]
        \\ pub type UserResource(
        \\     id: i32,
        \\     name: string,
        \\     email: string,
        \\     active: bool,
        \\ )
        \\
        \\ #[service]
        \\ pub type UserResources {
        \\     pub fn one(self: Self, id: string) -> string {
        \\         val user = UserResource(id: 1, name: "Alice", email: "alice@example.com", active: true);
        \\         val links: Array<Link> = [
        \\             linkTo("self", "/api/users/:id", [#("id", id)]),
        \\             linkTo("orders", "/api/users/:id/orders", [#("id", id)]),
        \\             link("collection", "/api/users"),
        \\         ];
        \\         return userResourceToHal(user, links);
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/users")]
        \\ pub type UserController(
        \\     resources: UserResources,
        \\ ) {
        \\     #[getMapping("/:id")]
        \\     pub fn show(self: Self, req: Request) -> Response {
        \\         return halResponse(self.resources.one(req.param("id")));
        \\     }
        \\
        \\     #[getMapping("/:id/orders")]
        \\     pub fn orders(self: Self, req: Request) -> Response {
        \\         return halResponse("{}");
        \\     }
        \\ }
        , "UserResources.one(1)");
}
```

`modules/rakun-hateoas/test/__snapshots__/hal/a-resource-renders-its-fields-and-its-self-link.snap`
```
_links: {"self":{"href":"/api/users/1"},"orders":{"href":"/api/users/1/orders"},"collection":{"href":"/api/users"}}
active: true
email: "alice@example.com"
id: 1
name: "Alice"
```

### `hal: two links with one rel render as an array in insertion order`

```bp
test "hal: two links with one rel render as an array in insertion order" {
    try assertHal(@src(),
        \\ import {halResource, Link, link} from "rakun-hateoas";
        \\ import {renderLinks, quoteJsonString} from "rakun-hateoas";
        \\
        \\ #[halResource]
        \\ pub type Shelf(
        \\     id: i32,
        \\ )
        \\
        \\ pub fn shelfHal() -> string {
        \\     return shelfToHal(Shelf(id: 3), [link("item", "/api/books/1"), link("item", "/api/books/2")]);
        \\ }
        , "shelfHal()");
}
```

`modules/rakun-hateoas/test/__snapshots__/hal/two-links-with-one-rel-render-as-an-array-in-insertion-order.snap`
```
_links: {"item":[{"href":"/api/books/1"},{"href":"/api/books/2"}]}
id: 3
```

### `hal: empty link attributes are omitted templated is emitted only when true and a quote is escaped`

```bp
test "hal: empty link attributes are omitted templated is emitted only when true and a quote is escaped" {
    try assertHal(@src(),
        \\ import {halResource, Link, link} from "rakun-hateoas";
        \\ import {renderLinks, quoteJsonString} from "rakun-hateoas";
        \\
        \\ #[halResource]
        \\ pub type Shelf(
        \\     id: i32,
        \\     label: string,
        \\ )
        \\
        \\ pub fn shelfHal() -> string {
        \\     val search = Link(rel: "search", href: "/api/books{?q}", mediaType: "", title: "Search", templated: true);
        \\     val plain = Link(rel: "self", href: "/api/shelves/3", mediaType: "", title: "", templated: false);
        \\     return shelfToHal(Shelf(id: 3, label: "say \"hi\""), [plain, search]);
        \\ }
        , "shelfHal()");
}
```

`modules/rakun-hateoas/test/__snapshots__/hal/empty-link-attributes-are-omitted-templated-is-emitted-only-when-true-and-a-quote-is-escaped.snap`
```
_links: {"self":{"href":"/api/shelves/3"},"search":{"href":"/api/books{?q}","title":"Search","templated":true}}
id: 3
label: "say \"hi\""
```

### `hal: a collection puts _embedded first and the paging links in order`

```bp
test "hal: a collection puts _embedded first and the paging links in order" {
    try assertHal(@src(),
        \\ import {halResource, Link, link, halCollection} from "rakun-hateoas";
        \\ import {renderLinks, quoteJsonString} from "rakun-hateoas";
        \\
        \\ #[halResource]
        \\ pub type UserResource(
        \\     id: i32,
        \\     name: string,
        \\ )
        \\
        \\ pub fn usersPage() -> string {
        \\     val rows = [
        \\         userResourceToHal(UserResource(id: 1, name: "Alice"), [link("self", "/api/users/1")]),
        \\         userResourceToHal(UserResource(id: 2, name: "Bob"), [link("self", "/api/users/2")]),
        \\     ];
        \\     val links: Array<Link> = [
        \\         link("self", "/api/users?page=2"),
        \\         link("first", "/api/users?page=1"),
        \\         link("prev", "/api/users?page=1"),
        \\         link("next", "/api/users?page=3"),
        \\         link("last", "/api/users?page=4"),
        \\     ];
        \\     return halCollection("users", rows, links);
        \\ }
        , "usersPage()");
}
```

`modules/rakun-hateoas/test/__snapshots__/hal/a-collection-puts-embedded-first-and-the-paging-links-in-order.snap`
```
_links: {"self":{"href":"/api/users?page=2"},"first":{"href":"/api/users?page=1"},"prev":{"href":"/api/users?page=1"},"next":{"href":"/api/users?page=3"},"last":{"href":"/api/users?page=4"}}
_embedded: {"users":[{"id":1,"name":"Alice","_links":{"self":{"href":"/api/users/1"}}},{"id":2,"name":"Bob","_links":{"self":{"href":"/api/users/2"}}}]}
```

### `hal: an empty collection keeps the _embedded key`

```bp
test "hal: an empty collection keeps the _embedded key" {
    try assertHal(@src(),
        \\ import {Link, link, halCollection} from "rakun-hateoas";
        \\ import {renderLinks, quoteJsonString} from "rakun-hateoas";
        \\
        \\ pub fn ordersOf(id: string) -> string {
        \\     return halCollection("orders", [], [link("self", "/api/users/" + id + "/orders")]);
        \\ }
        , "ordersOf(1)");
}
```

`modules/rakun-hateoas/test/__snapshots__/hal/an-empty-collection-keeps-the-embedded-key.snap`
```
_links: {"self":{"href":"/api/users/1/orders"}}
_embedded: {"orders":[]}
```

### `hal: linkTo substitutes the parameter and percent-encodes a slash`

```bp
test "hal: linkTo substitutes the parameter and percent-encodes a slash" {
    try assertHal(@src(),
        \\ import {restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {halResource, Link, linkTo, halResponse} from "rakun-hateoas";
        \\ import {renderLinks, quoteJsonString} from "rakun-hateoas";
        \\
        \\ #[halResource]
        \\ pub type FileResource(
        \\     path: string,
        \\ )
        \\
        \\ pub fn fileHal(path: string) -> string {
        \\     return fileResourceToHal(FileResource(path: path), [linkTo("self", "/api/files/:path", [#("path", path)])]);
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/files")]
        \\ pub type FileController {
        \\     #[getMapping("/:path")]
        \\     pub fn show(self: Self, req: Request) -> Response {
        \\         return halResponse(fileHal(req.param("path")));
        \\     }
        \\ }
        , "fileHal(a/b)");
}
```

`modules/rakun-hateoas/test/__snapshots__/hal/linkto-substitutes-the-parameter-and-percent-encodes-a-slash.snap`
```
_links: {"self":{"href":"/api/files/a%2Fb"}}
path: "a/b"
```

## 75-rakun-observability-metrics — `rakun-metrics`

**Test file:** `modules/rakun-metrics/test/metrics_test.bp` (suite `metrics`) · `modules/rakun-metrics/test/trace_test.bp` (suite `trace`) · **Snapshots:** `modules/rakun-metrics/test/__snapshots__/metrics/`, `modules/rakun-metrics/test/__snapshots__/trace/` · **Target:** erlang · **Pins:** Step 4 — a counter renders as `_total` with type `counter`, a gauge as `gauge`, a timer as `_seconds_count`/`_seconds_sum`/`_seconds_bucket` with type `histogram`, buckets cumulative and the last `+Inf`, the block is asserted literally; Step 1 — tag order does not create a second series, a gauge closure is called at scrape not at registration; Step 6 — `rakun.metrics.tags.*` on every series, `slo=…` buckets ascending whatever the property order, `rakun.metrics.enable.<prefix>=false` registers nothing; Step 8 — a valid `traceparent` continues the trace with the parent set, an absent one starts a new trace

> helper gap: `assertMetrics` renders only the meters the scanned source registered — the BEAM VM series (`beam.*`) are excluded from the body because their values are not reproducible; the VM table is asserted by relationship in `vm_test.bp`, not by snapshot.

Event strings are `"<Type>.<fn>(<args>)"` or `"<fn>(<args>)"`; the fixed clock makes every `timed` sample `0` seconds.

### `metrics: a counter renders as _total with the common tag on its series`

```bp
test "metrics: a counter renders as _total with the common tag on its series" {
    try assertMetrics(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {MeterRegistry, Tag, counter} from "rakun-metrics";
        \\
        \\ val _region = rkSetProp("rakun.metrics.tags.region", "us-east-1");
        \\
        \\ #[service]
        \\ pub type SettlementService(
        \\     meters: MeterRegistry,
        \\ ) {
        \\     pub fn reject(self: Self, reason: string) -> i32 {
        \\         return counter("orders.rejected", [Tag(key: "reason", value: reason)]).increment(1);
        \\     }
        \\ }
        , ["SettlementService.reject(fraud)", "SettlementService.reject(fraud)", "SettlementService.reject(limit)"]);
}
```

`modules/rakun-metrics/test/__snapshots__/metrics/a-counter-renders-as-total-with-the-common-tag-on-its-series.snap`
```
# TYPE orders_rejected_total counter
orders_rejected_total{reason="fraud",region="us-east-1"} 2
orders_rejected_total{reason="limit",region="us-east-1"} 1
```

### `metrics: tag order does not create a second series`

```bp
test "metrics: tag order does not create a second series" {
    try assertMetrics(@src(),
        \\ import {rkScan} from "rakun";
        \\ import {Tag, counter} from "rakun-metrics";
        \\
        \\ pub fn probeA() -> i32 {
        \\     return counter("http.probe", [Tag(key: "method", value: "GET"), Tag(key: "status", value: "200")]).increment(1);
        \\ }
        \\
        \\ pub fn probeB() -> i32 {
        \\     return counter("http.probe", [Tag(key: "status", value: "200"), Tag(key: "method", value: "GET")]).increment(1);
        \\ }
        , ["probeA()", "probeB()"]);
}
```

`modules/rakun-metrics/test/__snapshots__/metrics/tag-order-does-not-create-a-second-series.snap`
```
# TYPE http_probe_total counter
http_probe_total{method="GET",status="200"} 2
```

### `metrics: a timer renders as a histogram with cumulative slo buckets and +Inf`

```bp
test "metrics: a timer renders as a histogram with cumulative slo buckets and +Inf" {
    try assertMetrics(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {MeterRegistry, Tag, counter, timed} from "rakun-metrics";
        \\
        \\ val _slo = rkSetProp("rakun.metrics.distribution.slo.orders.settlement", "500ms,100ms,1s,200ms");
        \\
        \\ #[service]
        \\ pub type SettlementService(
        \\     meters: MeterRegistry,
        \\ ) {
        \\     pub fn settle(self: Self, amount: i32) -> i32 {
        \\         val tags = [Tag(key: "currency", value: "usd")];
        \\         val settled = timed("orders.settlement", tags, { ->
        \\             val cents = amount * 100;
        \\             cents;
        \\         });
        \\         val _c = counter("orders.settled", tags).increment(1);
        \\         return settled;
        \\     }
        \\ }
        , ["SettlementService.settle(3)", "SettlementService.settle(5)"]);
}
```

`modules/rakun-metrics/test/__snapshots__/metrics/a-timer-renders-as-a-histogram-with-cumulative-slo-buckets-and-inf.snap`
```
# TYPE orders_settled_total counter
orders_settled_total{currency="usd"} 2
# TYPE orders_settlement_seconds histogram
orders_settlement_seconds_bucket{currency="usd",le="0.1"} 2
orders_settlement_seconds_bucket{currency="usd",le="0.2"} 2
orders_settlement_seconds_bucket{currency="usd",le="0.5"} 2
orders_settlement_seconds_bucket{currency="usd",le="1"} 2
orders_settlement_seconds_bucket{currency="usd",le="+Inf"} 2
orders_settlement_seconds_count{currency="usd"} 2
orders_settlement_seconds_sum{currency="usd"} 0
```

### `metrics: a gauge is read at scrape time not at registration`

```bp
test "metrics: a gauge is read at scrape time not at registration" {
    try assertMetrics(@src(),
        \\ import {rkScan} from "rakun";
        \\ import {Tag, gauge} from "rakun-metrics";
        \\
        \\ pub fn pendingCount() -> i32 {
        \\     return 7;
        \\ }
        \\
        \\ pub fn registerPending() -> i32 {
        \\     return gauge("orders.pending", [], { -> pendingCount() });
        \\ }
        , ["registerPending()"]);
}
```

`modules/rakun-metrics/test/__snapshots__/metrics/a-gauge-is-read-at-scrape-time-not-at-registration.snap`
```
# TYPE orders_pending gauge
orders_pending 7
```

### `metrics: a denied prefix is not registered at all`

```bp
test "metrics: a denied prefix is not registered at all" {
    try assertMetrics(@src(),
        \\ import {rkScan, rkSetProp} from "rakun";
        \\ import {Tag, counter} from "rakun-metrics";
        \\
        \\ val _deny = rkSetProp("rakun.metrics.enable.http.client", "false");
        \\
        \\ pub fn outbound() -> i32 {
        \\     return counter("http.client.requests", [Tag(key: "host", value: "pricing.internal")]).increment(1);
        \\ }
        \\
        \\ pub fn rejected() -> i32 {
        \\     return counter("orders.rejected", [Tag(key: "reason", value: "fraud")]).increment(1);
        \\ }
        , ["outbound()", "rejected()"]);
}
```

`modules/rakun-metrics/test/__snapshots__/metrics/a-denied-prefix-is-not-registered-at-all.snap`
```
# TYPE orders_rejected_total counter
orders_rejected_total{reason="fraud"} 1
```

### `trace: an incoming traceparent continues the trace and the outbound call is its child`

```bp
test "trace: an incoming traceparent continues the trace and the outbound call is its child" {
    try assertTrace(@src(),
        \\ import {service, restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp, rkRegisterRoute} from "rakun";
        \\ import {traceId, spanId, startSpan, endSpan} from "rakun-metrics";
        \\ import {RestClient} from "rakun-client";
        \\
        \\ val _p = rkSetProp("rakun.tracing.sampling.probability", "1.0");
        \\ val _allow = rkSetProp("rakun.http.clients.allow", "127.0.0.0/8");
        \\
        \\ #[service]
        \\ pub type PricingClient(
        \\     http: RestClient,
        \\ ) {
        \\     pub fn quote(self: Self, sku: string) -> string {
        \\         return self.http.get("http://127.0.0.1:18080/quote/" + sku).retrieve().body;
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api")]
        \\ pub type QuoteController(
        \\     pricing: PricingClient,
        \\ ) {
        \\     #[getMapping("/quote/:sku")]
        \\     pub fn quote(self: Self, req: Request) -> Response {
        \\         val span = startSpan("quote.assemble");
        \\         val body = self.pricing.quote(req.param("sku"));
        \\         val _e = endSpan(span);
        \\         return Response.json(body);
        \\     }
        \\ }
        , "GET /api/quote/sku-1 traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01");
}
```

`modules/rakun-metrics/test/__snapshots__/trace/an-incoming-traceparent-continues-the-trace-and-the-outbound-call-is-its-child.snap`
```
trace 4bf92f3577b34da6a3ce929d0e0e4736 spans:
http.server.request parent=- kind=server
quote.assemble parent=http.server.request kind=internal
http.client.request parent=quote.assemble kind=client
```

### `trace: an absent traceparent starts a new trace with a fresh id`

```bp
test "trace: an absent traceparent starts a new trace with a fresh id" {
    try assertTrace(@src(),
        \\ import {restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp, rkRegisterRoute} from "rakun";
        \\ import {traceId, spanId, sampled} from "rakun-metrics";
        \\
        \\ val _p = rkSetProp("rakun.tracing.sampling.probability", "1.0");
        \\
        \\ #[restController]
        \\ #[route("/api")]
        \\ pub type WhoController {
        \\     #[getMapping("/whoami")]
        \\     pub fn whoami(self: Self, req: Request) -> Response {
        \\         return Response.json(traceId() + " " + spanId() + " " + sampled().toString());
        \\     }
        \\ }
        , "GET /api/whoami");
}
```

`modules/rakun-metrics/test/__snapshots__/trace/an-absent-traceparent-starts-a-new-trace-with-a-fresh-id.snap`
```
trace trace-0001 spans:
http.server.request parent=- kind=server
```

## 76-rakun-actuator-security-probes — `rakun-actuator`

**Test file:** `modules/rakun-actuator/test/exposure_test.bp` (suite `exposure`) · `modules/rakun-actuator/test/probes_test.bp` (suite `probe`) · **Snapshots:** `modules/rakun-actuator/test/__snapshots__/exposure/`, `modules/rakun-actuator/test/__snapshots__/probe/` · **Target:** erlang · **Pins:** Step 1 — with no configuration `health` answers and every other endpoint answers 404, an unexposed endpoint and an unknown path are byte-identical, `include=*` exposes every endpoint, `exclude` wins over `include` and over `*`; Step 2 — `access=none` answers 404 not 403, `read-only` refuses `POST` with 405, `max-permitted=read-only` demotes `unrestricted`; Step 3 — `endpoints.web.base-path=/manage` moves every path; Step 6 — readiness 503 before `Ready` and 200 after, liveness stays `CORRECT` while `db` is `DOWN`, `setReadiness(false)` flips the probe, on SIGTERM readiness flips before the drain by the full `pre-drain-period`, `/readyz` answers identically to the management path

Requests carry a principal as a pseudo-header `principal: <name>`; anonymous requests omit the bracket. Probe script steps are `boot`, `ready`, `sigterm`, `drain`, `indicator <id> <STATUS>`, `<Type>.<fn>()`; `<t>` is the offset from the fixed clock.

### `exposure: with no configuration only health is exposed and an unexposed endpoint looks unknown`

```bp
test "exposure: with no configuration only health is exposed and an unexposed endpoint looks unknown" {
    try assertExposure(@src(),
        [],
        [
            "GET /actuator/health",
            "GET /actuator/info",
            "GET /actuator/env",
            "GET /actuator/beans",
            "GET /actuator/there-is-no-such-thing",
        ]);
}
```

`modules/rakun-actuator/test/__snapshots__/exposure/with-no-configuration-only-health-is-exposed-and-an-unexposed-endpoint-looks-unknown.snap`
```
/actuator/health -> 200 exposed
/actuator/info -> 404 hidden
/actuator/env -> 404 hidden
/actuator/beans -> 404 hidden
/actuator/there-is-no-such-thing -> 404 hidden
```

### `exposure: include=* exposes every endpoint and exclude wins over the wildcard`

```bp
test "exposure: include=* exposes every endpoint and exclude wins over the wildcard" {
    try assertExposure(@src(),
        ["rakun.endpoints.web.exposure.include=*", "rakun.endpoints.web.exposure.exclude=env"],
        ["GET /actuator/beans", "GET /actuator/info", "GET /actuator/env"]);
}
```

`modules/rakun-actuator/test/__snapshots__/exposure/include-exposes-every-endpoint-and-exclude-wins-over-the-wildcard.snap`
```
/actuator/beans -> 200 exposed
/actuator/info -> 200 exposed
/actuator/env -> 404 hidden
```

### `exposure: access=none answers 404 and read-only refuses a POST with 405`

```bp
test "exposure: access=none answers 404 and read-only refuses a POST with 405" {
    try assertExposure(@src(),
        [
            "rakun.endpoints.web.exposure.include=*",
            "rakun.endpoint.beans.access=none",
            "rakun.endpoint.shutdown.access=read-only",
        ],
        ["GET /actuator/beans", "POST /actuator/shutdown", "GET /actuator/health"]);
}
```

`modules/rakun-actuator/test/__snapshots__/exposure/access-none-answers-404-and-read-only-refuses-a-post-with-405.snap`
```
/actuator/beans -> 404 hidden
/actuator/shutdown -> 405 denied
/actuator/health -> 200 exposed
```

### `exposure: max-permitted demotes an unrestricted endpoint`

```bp
test "exposure: max-permitted demotes an unrestricted endpoint" {
    try assertExposure(@src(),
        [
            "rakun.endpoints.web.exposure.include=*",
            "rakun.endpoints.access.max-permitted=read-only",
            "rakun.endpoint.shutdown.access=unrestricted",
        ],
        ["POST /actuator/shutdown principal: admin", "GET /actuator/shutdown principal: admin"]);
}
```

`modules/rakun-actuator/test/__snapshots__/exposure/max-permitted-demotes-an-unrestricted-endpoint.snap`
```
/actuator/shutdown [admin] -> 405 denied
/actuator/shutdown [admin] -> 405 denied
```

### `exposure: base-path moves every path`

```bp
test "exposure: base-path moves every path" {
    try assertExposure(@src(),
        ["rakun.endpoints.web.base-path=/manage"],
        ["GET /manage/health", "GET /actuator/health"]);
}
```

`modules/rakun-actuator/test/__snapshots__/exposure/base-path-moves-every-path.snap`
```
/manage/health -> 200 exposed
/actuator/health -> 404 hidden
```

### `probe: readiness refuses before Ready and accepts after`

```bp
test "probe: readiness refuses before Ready and accepts after" {
    try assertProbe(@src(),
        \\ import {rkScan, rkSetProp} from "rakun";
        \\ import {readinessState, livenessState} from "rakun-actuator";
        \\
        \\ val _probes = rkSetProp("rakun.endpoint.health.probes.enabled", "true");
        , ["boot", "ready"]);
}
```

`modules/rakun-actuator/test/__snapshots__/probe/readiness-refuses-before-ready-and-accepts-after.snap`
```
+0ms liveness=CORRECT readiness=REFUSING_TRAFFIC
+0ms liveness=CORRECT readiness=ACCEPTING_TRAFFIC
```

### `probe: liveness stays CORRECT while db is DOWN`

```bp
test "probe: liveness stays CORRECT while db is DOWN" {
    try assertProbe(@src(),
        \\ import {managed, rkScan, rkSetProp} from "rakun";
        \\ import {Health, healthIndicator, rkRegisterHealthIndicator} from "rakun-actuator-api";
        \\ import {readinessState, livenessState} from "rakun-actuator";
        \\
        \\ val _probes = rkSetProp("rakun.endpoint.health.probes.enabled", "true");
        \\ val _ready = rkSetProp("rakun.endpoint.health.group.readiness.include", "readinessState,db");
        \\
        \\ #[healthIndicator("db")]
        \\ #[managed]
        \\ pub type DataSourceHealth {
        \\     pub fn check(self: Self) -> Health {
        \\         return Health(status: "UP", details: "{}");
        \\     }
        \\ }
        , ["ready", "indicator db DOWN", "indicator db UP"]);
}
```

`modules/rakun-actuator/test/__snapshots__/probe/liveness-stays-correct-while-db-is-down.snap`
```
+0ms liveness=CORRECT readiness=ACCEPTING_TRAFFIC
+0ms liveness=CORRECT readiness=REFUSING_TRAFFIC
+0ms liveness=CORRECT readiness=ACCEPTING_TRAFFIC
```

### `probe: an application holds itself not-ready while it warms`

```bp
test "probe: an application holds itself not-ready while it warms" {
    try assertProbe(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp} from "rakun";
        \\ import {readinessState, livenessState, setReadiness} from "rakun-actuator";
        \\
        \\ val _probes = rkSetProp("rakun.endpoint.health.probes.enabled", "true");
        \\
        \\ #[service]
        \\ pub type CatalogWarmer {
        \\     pub fn hold(self: Self) -> i32 {
        \\         return setReadiness(false);
        \\     }
        \\
        \\     pub fn release(self: Self) -> i32 {
        \\         return setReadiness(true);
        \\     }
        \\ }
        , ["ready", "CatalogWarmer.hold()", "CatalogWarmer.release()"]);
}
```

`modules/rakun-actuator/test/__snapshots__/probe/an-application-holds-itself-not-ready-while-it-warms.snap`
```
+0ms liveness=CORRECT readiness=ACCEPTING_TRAFFIC
+0ms liveness=CORRECT readiness=REFUSING_TRAFFIC
+0ms liveness=CORRECT readiness=ACCEPTING_TRAFFIC
```

### `probe: on SIGTERM readiness flips before the drain by the full pre-drain period`

```bp
test "probe: on SIGTERM readiness flips before the drain by the full pre-drain period" {
    try assertProbe(@src(),
        \\ import {rkScan, rkSetProp} from "rakun";
        \\ import {readinessState, livenessState, readinessDrained} from "rakun-actuator";
        \\
        \\ val _probes = rkSetProp("rakun.endpoint.health.probes.enabled", "true");
        \\ val _pre = rkSetProp("rakun.lifecycle.pre-drain-period", "5000");
        , ["ready", "sigterm", "drain"]);
}
```

`modules/rakun-actuator/test/__snapshots__/probe/on-sigterm-readiness-flips-before-the-drain-by-the-full-pre-drain-period.snap`
```
+0ms liveness=CORRECT readiness=ACCEPTING_TRAFFIC
+0ms liveness=CORRECT readiness=REFUSING_TRAFFIC
+5000ms liveness=CORRECT readiness=REFUSING_TRAFFIC
```

## 87-rakun-audit-and-exchanges — `rakun-actuator`

**Test file:** `modules/rakun-actuator/test/audit/audit_test.bp` (suite `audit`) · `modules/rakun-actuator/test/exchanges/exchanges_test.bp` (suite `exchanges`) · **Snapshots:** `modules/rakun-actuator/test/__snapshots__/audit/`, `modules/rakun-actuator/test/__snapshots__/exchanges/` · **Target:** erlang · **Pins:** Step 4 — `audit(kind, principal, data)` records one event per call through the one-way seam; Step 2 — writing past `capacity` retains exactly `capacity` and drops the oldest; Step 6 — a `data` pair whose key matches the sanitize list is masked; Step 5 — with no include list an exchange carries only method, URI, status and duration, `request-headers` never carries `authorization` or `cookie`, `authorization-header` is the only way it is present, a request that raises is recorded with the status the error handler produced

Audit script steps are `"<Type>.<fn>(<args>)"`. Exchange requests follow the shared `request` form; the source turns recording on with `rakun.management.httpexchanges.recording.enabled=true` and names the include list with `rakun.management.httpexchanges.recording.include` (name per README § The include-list).

### `audit: a domain event is recorded with its pairs sorted`

```bp
test "audit: a domain event is recorded with its pairs sorted" {
    try assertAudit(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {AuditEvent, audit} from "rakun-actuator";
        \\
        \\ #[service]
        \\ pub type Payouts {
        \\     pub fn approve(self: Self, payoutId: string, principal: string) -> string {
        \\         val _ev = audit("PAYOUT_APPROVED", principal, [
        \\             #("payout.id", payoutId),
        \\             #("payout.amount.cents", "120000"),
        \\         ]);
        \\         return "approved " + payoutId;
        \\     }
        \\
        \\     pub fn deny(self: Self, payoutId: string, principal: string, why: string) -> string {
        \\         val _ev = audit("PAYOUT_DENIED", principal, [
        \\             #("payout.id", payoutId),
        \\             #("reason", why),
        \\         ]);
        \\         return "denied " + payoutId;
        \\     }
        \\ }
        , ["Payouts.approve(p-1, ana)", "Payouts.deny(p-2, bob, limit)"]);
}
```

`modules/rakun-actuator/test/__snapshots__/audit/a-domain-event-is-recorded-with-its-pairs-sorted.snap`
```
PAYOUT_APPROVED principal=ana data={payout.amount.cents=120000, payout.id=p-1}
PAYOUT_DENIED principal=bob data={payout.id=p-2, reason=limit}
```

### `audit: a data pair whose key matches the sanitize list is masked`

```bp
test "audit: a data pair whose key matches the sanitize list is masked" {
    try assertAudit(@src(),
        \\ import {rkScan} from "rakun";
        \\ import {AuditEvent, audit} from "rakun-actuator";
        \\
        \\ pub fn failLogin(principal: string) -> i32 {
        \\     return audit("AUTHENTICATION_FAILURE", principal, [
        \\         #("remote.address", "10.0.0.7"),
        \\         #("client.token", "abc123"),
        \\     ]);
        \\ }
        , ["failLogin(ana)"]);
}
```

`modules/rakun-actuator/test/__snapshots__/audit/a-data-pair-whose-key-matches-the-sanitize-list-is-masked.snap`
```
AUTHENTICATION_FAILURE principal=ana data={client.token=******, remote.address=10.0.0.7}
```

### `audit: the ring drops the oldest event past capacity`

```bp
test "audit: the ring drops the oldest event past capacity" {
    try assertAudit(@src(),
        \\ import {rkScan, rkSetProp} from "rakun";
        \\ import {AuditEvent, audit} from "rakun-actuator";
        \\
        \\ val _cap = rkSetProp("rakun.management.auditevents.capacity", "2");
        \\
        \\ pub fn logout(principal: string) -> i32 {
        \\     return audit("LOGOUT", principal, []);
        \\ }
        , ["logout(ana)", "logout(bob)", "logout(cam)"]);
}
```

`modules/rakun-actuator/test/__snapshots__/audit/the-ring-drops-the-oldest-event-past-capacity.snap`
```
LOGOUT principal=bob data={}
LOGOUT principal=cam data={}
```

### `exchanges: with no include list an exchange keeps only method uri status and duration`

```bp
test "exchanges: with no include list an exchange keeps only method uri status and duration" {
    try assertExchanges(@src(),
        \\ import {restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp, rkRegisterRoute} from "rakun";
        \\ import {HttpExchange, exchangeFields} from "rakun-actuator";
        \\
        \\ val _on = rkSetProp("rakun.management.httpexchanges.recording.enabled", "true");
        \\
        \\ #[restController]
        \\ #[route("/api/invoices")]
        \\ pub type InvoiceController {
        \\     #[getMapping("/:id")]
        \\     pub fn show(self: Self, req: Request) -> Response {
        \\         return Response.json("{\"id\":\"" + req.param("id") + "\"}");
        \\     }
        \\ }
        , ["GET /api/invoices/7 accept: application/json authorization: Bearer eyJhbGciOi"]);
}
```

`modules/rakun-actuator/test/__snapshots__/exchanges/with-no-include-list-an-exchange-keeps-only-method-uri-status-and-duration.snap`
```
GET /api/invoices/7 -> 200
```

### `exchanges: request-headers never carries authorization or cookie`

```bp
test "exchanges: request-headers never carries authorization or cookie" {
    try assertExchanges(@src(),
        \\ import {restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp, rkRegisterRoute} from "rakun";
        \\ import {HttpExchange, exchangeFields} from "rakun-actuator";
        \\
        \\ val _on = rkSetProp("rakun.management.httpexchanges.recording.enabled", "true");
        \\ val _inc = rkSetProp("rakun.management.httpexchanges.recording.include", "request-headers");
        \\
        \\ #[restController]
        \\ #[route("/api/invoices")]
        \\ pub type InvoiceController {
        \\     #[getMapping("/:id")]
        \\     pub fn show(self: Self, req: Request) -> Response {
        \\         return Response.json("{\"id\":\"" + req.param("id") + "\"}");
        \\     }
        \\ }
        , ["GET /api/invoices/7 accept: application/json user-agent: curl/8.5.0 authorization: Bearer eyJhbGciOi cookie: session=6f1c2a"]);
}
```

`modules/rakun-actuator/test/__snapshots__/exchanges/request-headers-never-carries-authorization-or-cookie.snap`
```
GET /api/invoices/7 -> 200 [include=request.header.accept,request.header.user-agent]
```

### `exchanges: authorization-header is its own switch`

```bp
test "exchanges: authorization-header is its own switch" {
    try assertExchanges(@src(),
        \\ import {restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp, rkRegisterRoute} from "rakun";
        \\ import {HttpExchange, exchangeFields} from "rakun-actuator";
        \\
        \\ val _on = rkSetProp("rakun.management.httpexchanges.recording.enabled", "true");
        \\ val _inc = rkSetProp("rakun.management.httpexchanges.recording.include", "authorization-header,principal");
        \\
        \\ #[restController]
        \\ #[route("/api/invoices")]
        \\ pub type InvoiceController {
        \\     #[getMapping("/:id")]
        \\     pub fn show(self: Self, req: Request) -> Response {
        \\         return Response.json("{\"id\":\"" + req.param("id") + "\"}");
        \\     }
        \\ }
        , ["GET /api/invoices/7 authorization: Bearer eyJhbGciOi cookie: session=6f1c2a principal: ana"]);
}
```

`modules/rakun-actuator/test/__snapshots__/exchanges/authorization-header-is-its-own-switch.snap`
```
GET /api/invoices/7 -> 200 [include=principal,request.header.authorization]
```

### `exchanges: a request that raises is recorded with the status the error handler produced`

```bp
test "exchanges: a request that raises is recorded with the status the error handler produced" {
    try assertExchanges(@src(),
        \\ import {restController, route, postMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkSetProp, rkRegisterRoute} from "rakun";
        \\ import {HttpExchange, exchangeFields} from "rakun-actuator";
        \\
        \\ val _on = rkSetProp("rakun.management.httpexchanges.recording.enabled", "true");
        \\
        \\ #[restController]
        \\ #[route("/api/payouts")]
        \\ pub type PayoutController {
        \\     #[postMapping("/")]
        \\     pub fn create(self: Self, req: Request) -> Response {
        \\         @panic("ledger unavailable");
        \\     }
        \\ }
        , ["POST /api/payouts/ | {\"amount\":1}", "GET /api/payouts/missing"]);
}
```

`modules/rakun-actuator/test/__snapshots__/exchanges/a-request-that-raises-is-recorded-with-the-status-the-error-handler-produced.snap`
```
POST /api/payouts/ -> 500
GET /api/payouts/missing -> 404
```

## 15-rakun-messaging — `rakun-messaging`

**Test file:** `modules/rakun-messaging/test/listener_test.bp` · **Snapshots:** `modules/rakun-messaging/test/__snapshots__/listener/` · **Target:** erlang · **Pins:** `#[listener]` emits one registration per broker marker; `rkListenerCount` = annotated methods; `rkDeliver` reaches the handler with no broker; a raising handler is redelivered (`auto` acks only a non-raising return); `#[kafkaListener]` takes topic + group; `#[streamListener]` offset keyword; Redis is fire-and-forget under `ack-mode = none`; `Message` carries the same fields on every arm (`key = ""`, `offset = -1` where absent)

> helper gap: the `broker=` enum in the `assertListener` row is `amqp|kafka|jms`; front 15's four arms need `redis` and `stream` too (rendered below as `broker=redis` / `broker=stream`).
> Delivery strings are `"<destination>[ <header>: <v>]* | <payload>"`; the destination alone selects the listener because a duplicate destination is refused at boot.

### `listener: three markers on one type register three destinations`

```bp
test "listener: three markers on one type register three destinations" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {listener, amqpListener, kafkaListener, redisListener} from "rakun-messaging";
        \\ import {Message, rkRegisterListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ #[listener]
        \\ pub type OrderListeners {
        \\     #[amqpListener("orders")]
        \\     pub fn onOrderPlaced(self: Self, msg: Message) -> i32 {
        \\         return 0;
        \\     }
        \\
        \\     #[kafkaListener("order-events", "order-service")]
        \\     pub fn onOrderEvent(self: Self, msg: Message) -> i32 {
        \\         return 0;
        \\     }
        \\
        \\     #[redisListener("cache-invalidation")]
        \\     pub fn onInvalidate(self: Self, msg: Message) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , []);
}
```

`modules/rakun-messaging/test/__snapshots__/listener/three-markers-on-one-type-register-three-destinations.snap`
```
listener cache-invalidation -> OrderListeners.onInvalidate broker=redis
listener order-events -> OrderListeners.onOrderEvent broker=kafka
listener orders -> OrderListeners.onOrderPlaced broker=amqp
```

### `listener: rkDeliver reaches the amqp handler with no broker running`

```bp
test "listener: rkDeliver reaches the amqp handler with no broker running" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {listener, amqpListener} from "rakun-messaging";
        \\ import {Message, rkRegisterListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ #[listener]
        \\ pub type OrderListeners {
        \\     #[amqpListener("orders")]
        \\     pub fn onOrderPlaced(self: Self, msg: Message) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , ["orders | order:A-1", "orders | order:A-2"]);
}
```

`modules/rakun-messaging/test/__snapshots__/listener/rkdeliver-reaches-the-amqp-handler-with-no-broker-running.snap`
```
listener orders -> OrderListeners.onOrderPlaced broker=amqp

deliver orders order:A-1 -> ok
deliver orders order:A-2 -> ok
```

### `listener: a raising handler is nacked under ack-mode auto`

```bp
test "listener: a raising handler is nacked under ack-mode auto" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {listener, amqpListener} from "rakun-messaging";
        \\ import {Message, rkRegisterListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ #[listener]
        \\ pub type StrictListeners {
        \\     #[amqpListener("orders")]
        \\     pub fn onOrderPlaced(self: Self, msg: Message) -> i32 {
        \\         val empty = msg.payload == "";
        \\         if (empty) {
        \\             throw "empty payload";
        \\         };
        \\         return 0;
        \\     }
        \\ }
        , ["orders | order:A-1", "orders | ", "orders | order:A-3"]);
}
```

`modules/rakun-messaging/test/__snapshots__/listener/a-raising-handler-is-nacked-under-ack-mode-auto.snap`
```
listener orders -> StrictListeners.onOrderPlaced broker=amqp

deliver orders order:A-1 -> ok
deliver orders  -> nack
deliver orders order:A-3 -> ok
```

### `listener: the kafka arm carries the key and the amqp arm carries an empty one`

```bp
test "listener: the kafka arm carries the key and the amqp arm carries an empty one" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {listener, amqpListener, kafkaListener} from "rakun-messaging";
        \\ import {Message, rkRegisterListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ #[listener]
        \\ pub type KeyedListeners {
        \\     #[amqpListener("orders")]
        \\     pub fn onQueue(self: Self, msg: Message) -> i32 {
        \\         val keyed = msg.key != "";
        \\         if (keyed) {
        \\             throw "amqp has no key";
        \\         };
        \\         return 0;
        \\     }
        \\
        \\     #[kafkaListener("order-events", "order-service")]
        \\     pub fn onTopic(self: Self, msg: Message) -> i32 {
        \\         val unkeyed = msg.key == "";
        \\         if (unkeyed) {
        \\             throw "kafka message without key";
        \\         };
        \\         return 0;
        \\     }
        \\ }
        , ["orders | order:A-1", "order-events key: A-1 | placed", "order-events | placed"]);
}
```

`modules/rakun-messaging/test/__snapshots__/listener/the-kafka-arm-carries-the-key-and-the-amqp-arm-carries-an-empty-one.snap`
```
listener order-events -> KeyedListeners.onTopic broker=kafka
listener orders -> KeyedListeners.onQueue broker=amqp

deliver orders order:A-1 -> ok
deliver order-events placed -> ok
deliver order-events placed -> nack
```

### `listener: a stream listener reads its offset and acks manually`

```bp
test "listener: a stream listener reads its offset and acks manually" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {listener, streamListener} from "rakun-messaging";
        \\ import {Message, rkRegisterListener, ackMessage, nackMessage} from "rakun-messaging";
        \\
        \\ #[service]
        \\ #[listener]
        \\ pub type AuditStreamListeners {
        \\     #[streamListener("audit-stream", "first")]
        \\     pub fn onAuditRecord(self: Self, msg: Message) -> i32 {
        \\         val negative = msg.offset < 0;
        \\         if (negative) {
        \\             return nackMessage(msg);
        \\         };
        \\         return ackMessage(msg);
        \\     }
        \\ }
        , ["audit-stream offset: 0 | rec-0", "audit-stream offset: 1 | rec-1"]);
}
```

`modules/rakun-messaging/test/__snapshots__/listener/a-stream-listener-reads-its-offset-and-acks-manually.snap`
```
listener audit-stream -> AuditStreamListeners.onAuditRecord broker=stream

deliver audit-stream rec-0 -> ok
deliver audit-stream rec-1 -> ok
```

### `listener: a redis handler that raises is neither nacked nor redelivered`

```bp
test "listener: a redis handler that raises is neither nacked nor redelivered" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {listener, redisListener} from "rakun-messaging";
        \\ import {Message, rkRegisterListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ #[listener]
        \\ pub type CacheListeners {
        \\     #[redisListener("cache-invalidation")]
        \\     pub fn onInvalidate(self: Self, msg: Message) -> i32 {
        \\         val empty = msg.payload == "";
        \\         if (empty) {
        \\             throw "nothing to forget";
        \\         };
        \\         return 0;
        \\     }
        \\ }
        , ["cache-invalidation | user:7", "cache-invalidation | "]);
}
```

`modules/rakun-messaging/test/__snapshots__/listener/a-redis-handler-that-raises-is-neither-nacked-nor-redelivered.snap`
```
listener cache-invalidation -> CacheListeners.onInvalidate broker=redis

deliver cache-invalidation user:7 -> ok
deliver cache-invalidation  -> ok
```

### `listener: two listener types share one registry`

```bp
test "listener: two listener types share one registry" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {listener, amqpListener, kafkaListener} from "rakun-messaging";
        \\ import {Message, rkRegisterListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ #[listener]
        \\ pub type OrderListeners {
        \\     #[amqpListener("orders")]
        \\     pub fn onOrderPlaced(self: Self, msg: Message) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[listener]
        \\ pub type ShippingListeners {
        \\     #[amqpListener("shipping-notifications")]
        \\     pub fn onShipped(self: Self, msg: Message) -> i32 {
        \\         return 0;
        \\     }
        \\
        \\     #[kafkaListener("order-events", "shipping-service")]
        \\     pub fn onOrderEvent(self: Self, msg: Message) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , ["shipping-notifications | {\"orderId\":\"A-1\"}"]);
}
```

`modules/rakun-messaging/test/__snapshots__/listener/two-listener-types-share-one-registry.snap`
```
listener order-events -> ShippingListeners.onOrderEvent broker=kafka
listener orders -> OrderListeners.onOrderPlaced broker=amqp
listener shipping-notifications -> ShippingListeners.onShipped broker=amqp

deliver shipping-notifications {"orderId":"A-1"} -> ok
```

## 16-rakun-scheduling — `rakun-scheduling`

**Test file:** `modules/rakun-scheduling/test/schedule_test.bp` · **Snapshots:** `modules/rakun-scheduling/test/__snapshots__/schedule/` · **Target:** erlang · **Pins:** three markers → one registry, one trigger per task; `fixedRate` measured from the previous start, `fixedDelay` from the previous finish; six-field cron with `*`, list, range, step and `?`; next-fire across month, year and leap-day boundaries from a fixed reference time; `rkRunTaskNow` runs once out of band; no test sleeps

> Ticks are instants on the fixed test clock (`2026-01-01T00:00:00Z` = t0, a Thursday); a tick renders one `fire` line per task due at that instant and nothing when none is due. The tick `run <name>` is `rkRunTaskNow(name)` and fires at the current clock. Task name = `<Type>.<fn>` (name per README § Examples, `rkRunTaskNow("HousekeepingService.pruneSessions")`).

### `schedule: three markers register three tasks and each fires on its own trigger`

```bp
test "schedule: three markers register three tasks and each fires on its own trigger" {
    try assertSchedule(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {scheduler, scheduled, fixedRate, fixedDelay} from "rakun-scheduling";
        \\ import {rkScheduleCron, rkScheduleFixedRate, rkScheduleFixedDelay} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ #[scheduler]
        \\ pub type HousekeepingService {
        \\     #[scheduled("0 0 * * * *")]
        \\     pub fn pruneSessions(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\
        \\     #[fixedRate(5000)]
        \\     pub fn heartbeat(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\
        \\     #[fixedDelay(30000)]
        \\     pub fn compact(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , ["2026-01-01T00:00:05Z", "2026-01-01T00:00:30Z", "2026-01-01T01:00:00Z"]);
}
```

`modules/rakun-scheduling/test/__snapshots__/schedule/three-markers-register-three-tasks-and-each-fires-on-its-own-trigger.snap`
```
task HousekeepingService.compact fixedDelay 30000
task HousekeepingService.heartbeat fixedRate 5000
task HousekeepingService.pruneSessions cron 0 0 * * * *

2026-01-01T00:00:05Z fire HousekeepingService.heartbeat
2026-01-01T00:00:30Z fire HousekeepingService.compact
2026-01-01T00:00:30Z fire HousekeepingService.heartbeat
2026-01-01T01:00:00Z fire HousekeepingService.compact
2026-01-01T01:00:00Z fire HousekeepingService.heartbeat
2026-01-01T01:00:00Z fire HousekeepingService.pruneSessions
```

### `schedule: a fixed rate fires from the previous start`

```bp
test "schedule: a fixed rate fires from the previous start" {
    try assertSchedule(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {scheduler, fixedRate} from "rakun-scheduling";
        \\ import {rkScheduleFixedRate} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ #[scheduler]
        \\ pub type Pulse {
        \\     #[fixedRate(5000)]
        \\     pub fn beat(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , ["2026-01-01T00:00:05Z", "2026-01-01T00:00:07Z", "2026-01-01T00:00:10Z", "2026-01-01T00:00:15Z"]);
}
```

`modules/rakun-scheduling/test/__snapshots__/schedule/a-fixed-rate-fires-from-the-previous-start.snap`
```
task Pulse.beat fixedRate 5000

2026-01-01T00:00:05Z fire Pulse.beat
2026-01-01T00:00:10Z fire Pulse.beat
2026-01-01T00:00:15Z fire Pulse.beat
```

### `schedule: a step expression fires every fifteen seconds`

```bp
test "schedule: a step expression fires every fifteen seconds" {
    try assertSchedule(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {scheduler, scheduled} from "rakun-scheduling";
        \\ import {rkScheduleCron} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ #[scheduler]
        \\ pub type Sampler {
        \\     #[scheduled("*/15 * * * * *")]
        \\     pub fn sample(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , ["2026-01-01T00:00:15Z", "2026-01-01T00:00:20Z", "2026-01-01T00:00:30Z", "2026-01-01T00:00:45Z", "2026-01-01T00:01:00Z"]);
}
```

`modules/rakun-scheduling/test/__snapshots__/schedule/a-step-expression-fires-every-fifteen-seconds.snap`
```
task Sampler.sample cron */15 * * * * *

2026-01-01T00:00:15Z fire Sampler.sample
2026-01-01T00:00:30Z fire Sampler.sample
2026-01-01T00:00:45Z fire Sampler.sample
2026-01-01T00:01:00Z fire Sampler.sample
```

### `schedule: a range and a weekday list fire on a thursday and not on a saturday`

```bp
test "schedule: a range and a weekday list fire on a thursday and not on a saturday" {
    try assertSchedule(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {scheduler, scheduled} from "rakun-scheduling";
        \\ import {rkScheduleCron} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ #[scheduler]
        \\ pub type OfficeHours {
        \\     #[scheduled("0 30 9-17 * * 1-5")]
        \\     pub fn halfPast(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , ["2026-01-01T09:30:00Z", "2026-01-01T17:30:00Z", "2026-01-01T18:30:00Z", "2026-01-03T09:30:00Z", "2026-01-05T09:30:00Z"]);
}
```

`modules/rakun-scheduling/test/__snapshots__/schedule/a-range-and-a-weekday-list-fire-on-a-thursday-and-not-on-a-saturday.snap`
```
task OfficeHours.halfPast cron 0 30 9-17 * * 1-5

2026-01-01T09:30:00Z fire OfficeHours.halfPast
2026-01-01T17:30:00Z fire OfficeHours.halfPast
2026-01-05T09:30:00Z fire OfficeHours.halfPast
```

### `schedule: next fire crosses a month a year and a leap day`

```bp
test "schedule: next fire crosses a month a year and a leap day" {
    try assertSchedule(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {scheduler, scheduled} from "rakun-scheduling";
        \\ import {rkScheduleCron} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ #[scheduler]
        \\ pub type Calendar {
        \\     #[scheduled("0 0 0 1 * ?")]
        \\     pub fn monthly(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\
        \\     #[scheduled("0 0 0 1 1 ?")]
        \\     pub fn yearly(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\
        \\     #[scheduled("0 0 0 29 2 ?")]
        \\     pub fn leapDay(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , ["2026-02-01T00:00:00Z", "2027-01-01T00:00:00Z", "2027-02-28T00:00:00Z", "2028-02-29T00:00:00Z"]);
}
```

`modules/rakun-scheduling/test/__snapshots__/schedule/next-fire-crosses-a-month-a-year-and-a-leap-day.snap`
```
task Calendar.leapDay cron 0 0 0 29 2 ?
task Calendar.monthly cron 0 0 0 1 * ?
task Calendar.yearly cron 0 0 0 1 1 ?

2026-02-01T00:00:00Z fire Calendar.monthly
2027-01-01T00:00:00Z fire Calendar.monthly
2027-01-01T00:00:00Z fire Calendar.yearly
2028-02-29T00:00:00Z fire Calendar.leapDay
```

### `schedule: rkRunTaskNow fires a task once out of band`

```bp
test "schedule: rkRunTaskNow fires a task once out of band" {
    try assertSchedule(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {scheduler, scheduled} from "rakun-scheduling";
        \\ import {rkScheduleCron, rkRunTaskNow} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ #[scheduler]
        \\ pub type HousekeepingService {
        \\     #[scheduled("0 0 * * * *")]
        \\     pub fn pruneSessions(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , ["run HousekeepingService.pruneSessions", "2026-01-01T00:30:00Z", "2026-01-01T01:00:00Z"]);
}
```

`modules/rakun-scheduling/test/__snapshots__/schedule/rkruntasknow-fires-a-task-once-out-of-band.snap`
```
task HousekeepingService.pruneSessions cron 0 0 * * * *

2026-01-01T00:00:00Z fire HousekeepingService.pruneSessions
2026-01-01T01:00:00Z fire HousekeepingService.pruneSessions
```

### `schedule: a scheduler type with a list expression fires at both instants`

```bp
test "schedule: a scheduler type with a list expression fires at both instants" {
    try assertSchedule(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {scheduler, scheduled} from "rakun-scheduling";
        \\ import {rkScheduleCron} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ #[scheduler]
        \\ pub type Reports {
        \\     #[scheduled("0 0 6,18 * * ?")]
        \\     pub fn digest(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , ["2026-01-01T06:00:00Z", "2026-01-01T12:00:00Z", "2026-01-01T18:00:00Z", "2026-01-02T06:00:00Z"]);
}
```

`modules/rakun-scheduling/test/__snapshots__/schedule/a-scheduler-type-with-a-list-expression-fires-at-both-instants.snap`
```
task Reports.digest cron 0 0 6,18 * * ?

2026-01-01T06:00:00Z fire Reports.digest
2026-01-01T18:00:00Z fire Reports.digest
2026-01-02T06:00:00Z fire Reports.digest
```

## 19-rakun-test-utilities — `rakun-test`

**Test file:** `modules/rakun-test/test/mockmvc_test.bp` (suite `route`) · `modules/rakun-test/test/context_test.bp` (suite `context`) · `modules/rakun-test/test/broker_test.bp` (suite `listener`) · `modules/rakun-test/test/boot_test.bp` (suite `boot`) · **Snapshots:** `modules/rakun-test/test/__snapshots__/<suite>/` · **Target:** erlang · **Pins:** `FakeRequest implement Request` accepted by a handler with no cast; absent name → `""`; case-insensitive headers; `MockMvc.perform` goes through the registered route table (404 from the router, `:id` binds, query and header reach the handler); `resetSingletons` keeps registrations and drops instances; `resetContext` empties scan/routes/listeners and a dispatch afterwards is 404; `deliver` reaches a `#[listener]` handler with no broker; `bootAndExit` exits 0 on an application that wires up and non-zero per wiring-failure class

> helper gap: `assertContext` probes are types only; a reset step is spelled as the probe `!resetSingletons` / `!resetContext` and rendered as `reset <fn> -> ok` in probe order.
> helper gap: `assertBoot` under `bootAndExit` binds nothing, so `listen` is rendered as `listen none`; the six non-zero exit codes follow README § Step 6's order 1–6 (the README fixes only "distinct non-zero").

### `route: perform on a registered route returns the handler response and binds the path parameter`

```bp
test "route: perform on a registered route returns the handler response and binds the path parameter" {
    try assertRoute(@src(),
        \\ import {repository, service, restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {FakeRequest, fakeGet, MockMvc} from "rakun-test";
        \\
        \\ #[repository]
        \\ pub type UserRepo {
        \\     pub fn find(self: Self, id: string) -> string {
        \\         val known = id == "7";
        \\         if (known) {
        \\             return "{\"id\":\"7\",\"name\":\"ana\"}";
        \\         };
        \\         return "";
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type UserService(
        \\     repo: UserRepo,
        \\ ) {
        \\     pub fn describe(self: Self, id: string) -> string {
        \\         val found = self.repo.find(id);
        \\         val out = if (found == "") { "{\"error\":\"not found\"}" } else { found };
        \\         return out;
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/users")]
        \\ pub type UserController(
        \\     users: UserService,
        \\ ) {
        \\     #[getMapping("/:id")]
        \\     pub fn show(self: Self, req: Request) -> Response {
        \\         val body = self.users.describe(req.param("id"));
        \\         val status = if (body == "{\"error\":\"not found\"}") { 404 } else { 200 };
        \\         return Response.withStatus(status, body);
        \\     }
        \\ }
        , ["GET /api/users/7", "GET /api/users/99"]);
}
```

`modules/rakun-test/test/__snapshots__/route/perform-on-a-registered-route-returns-the-handler-response-and-binds-the-path-parameter.snap`
```
GET /api/users/:id -> UserController.show

GET /api/users/7 -> 200 {"id":"7","name":"ana"}
GET /api/users/99 -> 404 {"error":"not found"}
```

### `route: perform on an unregistered path is a router 404`

```bp
test "route: perform on an unregistered path is a router 404" {
    try assertRoute(@src(),
        \\ import {restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {fakeGet, MockMvc} from "rakun-test";
        \\
        \\ #[restController]
        \\ #[route("/api/users")]
        \\ pub type UserController {
        \\     #[getMapping("/")]
        \\     pub fn index(self: Self, req: Request) -> Response {
        \\         return Response.json("[]");
        \\     }
        \\ }
        , ["GET /api/users/", "GET /nope", "POST /api/users/"]);
}
```

`modules/rakun-test/test/__snapshots__/route/perform-on-an-unregistered-path-is-a-router-404.snap`
```
GET /api/users/ -> UserController.index

GET /api/users/ -> 200 []
GET /nope -> 404
POST /api/users/ -> 404
```

### `route: query header and body from the double reach the handler through the real dispatch path`

```bp
test "route: query header and body from the double reach the handler through the real dispatch path" {
    try assertRoute(@src(),
        \\ import {restController, route, getMapping, postMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {fakeGet, fakePost, MockMvc} from "rakun-test";
        \\
        \\ #[restController]
        \\ #[route("/api/echo")]
        \\ pub type EchoController {
        \\     #[getMapping("/")]
        \\     pub fn index(self: Self, req: Request) -> Response {
        \\         val page = req.query("page");
        \\         val accept = req.header("accept");
        \\         val sort = req.query("sort");
        \\         return Response.json("page=" + page + ";accept=" + accept + ";sort=" + sort);
        \\     }
        \\
        \\     #[postMapping("/")]
        \\     pub fn create(self: Self, req: Request) -> Response {
        \\         return Response.created(req.body());
        \\     }
        \\ }
        , ["GET /api/echo/?page=2 Accept: application/json", "POST /api/echo/ | {\"name\":\"bob\"}"]);
}
```

`modules/rakun-test/test/__snapshots__/route/query-header-and-body-from-the-double-reach-the-handler-through-the-real-dispatch-path.snap`
```
GET /api/echo/ -> EchoController.index
POST /api/echo/ -> EchoController.create

GET /api/echo/?page=2 -> 200 page=2;accept=application/json;sort=
POST /api/echo/ -> 201 {"name":"bob"}
```

### `context: resetSingletons keeps the registrations and drops the instances`

```bp
test "context: resetSingletons keeps the registrations and drops the instances" {
    try assertContext(@src(),
        \\ import {repository, service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {resetSingletons} from "rakun-test";
        \\
        \\ #[repository]
        \\ pub type UserRepo {
        \\     pub fn all(self: Self) -> Array<string> {
        \\         return ["ana"];
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type UserService(
        \\     repo: UserRepo,
        \\ ) {
        \\     pub fn list(self: Self) -> Array<string> {
        \\         return self.repo.all();
        \\     }
        \\ }
        , ["UserService", "!resetSingletons", "UserService", "UserRepo"]);
}
```

`modules/rakun-test/test/__snapshots__/context/resetsingletons-keeps-the-registrations-and-drops-the-instances.snap`
```
bean UserRepo scope=singleton deps=[]
bean UserService scope=singleton deps=[UserRepo]

resolve UserService -> ok
reset resetSingletons -> ok
resolve UserService -> ok
resolve UserRepo -> ok
```

### `context: resetContext empties the registry and a resolution afterwards is missing`

```bp
test "context: resetContext empties the registry and a resolution afterwards is missing" {
    try assertContext(@src(),
        \\ import {service, restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {resetContext} from "rakun-test";
        \\
        \\ #[service]
        \\ pub type UserService {
        \\     pub fn list(self: Self) -> Array<string> {
        \\         return ["ana"];
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/users")]
        \\ pub type UserController(
        \\     users: UserService,
        \\ ) {
        \\     #[getMapping("/")]
        \\     pub fn index(self: Self, req: Request) -> Response {
        \\         return Response.json(self.users.list().join(","));
        \\     }
        \\ }
        , ["UserController", "!resetContext", "UserController", "UserService"]);
}
```

`modules/rakun-test/test/__snapshots__/context/resetcontext-empties-the-registry-and-a-resolution-afterwards-is-missing.snap`
```
bean UserController scope=singleton deps=[UserService]
bean UserService scope=singleton deps=[]

resolve UserController -> ok
reset resetContext -> ok
resolve UserController -> missing
resolve UserService -> missing
```

### `listener: deliver reaches a listener handler with no broker configured`

```bp
test "listener: deliver reaches a listener handler with no broker configured" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {listener, amqpListener} from "rakun-messaging";
        \\ import {Message, rkRegisterListener} from "rakun-messaging";
        \\ import {deliver, published, clearPublished} from "rakun-test";
        \\
        \\ #[service]
        \\ #[listener]
        \\ pub type OrderListeners {
        \\     #[amqpListener("orders")]
        \\     pub fn onOrderPlaced(self: Self, msg: Message) -> i32 {
        \\         val empty = msg.payload == "";
        \\         if (empty) {
        \\             throw "empty";
        \\         };
        \\         return 0;
        \\     }
        \\ }
        , ["orders | order:A-1", "orders | "]);
}
```

`modules/rakun-test/test/__snapshots__/listener/deliver-reaches-a-listener-handler-with-no-broker-configured.snap`
```
listener orders -> OrderListeners.onOrderPlaced broker=amqp

deliver orders order:A-1 -> ok
deliver orders  -> nack
```

### `boot: bootAndExit exits zero on an application that wires up`

```bp
test "boot: bootAndExit exits zero on an application that wires up" {
    try assertBoot(@src(),
        \\ import {Rakun, App, service, restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {bootAndExit} from "rakun-test";
        \\
        \\ #[service]
        \\ pub type UserService {
        \\     pub fn list(self: Self) -> Array<string> {
        \\         return ["ana"];
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/users")]
        \\ pub type UserController(
        \\     users: UserService,
        \\ ) {
        \\     #[getMapping("/")]
        \\     pub fn index(self: Self, req: Request) -> Response {
        \\         return Response.json(self.users.list().join(","));
        \\     }
        \\ }
        \\
        \\ fn main() {
        \\     val code = bootAndExit(App(port: 8080, basePath: "/api"));
        \\ }
        , []);
}
```

`modules/rakun-test/test/__snapshots__/boot/bootandexit-exits-zero-on-an-application-that-wires-up.snap`
```
listen none
beans 2
routes 1
exit 0
```

### `boot: a duplicate route is a distinct non-zero exit`

```bp
test "boot: a duplicate route is a distinct non-zero exit" {
    try assertBoot(@src(),
        \\ import {Rakun, App, restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {bootAndExit} from "rakun-test";
        \\
        \\ #[restController]
        \\ #[route("/api/users")]
        \\ pub type UserController {
        \\     #[getMapping("/")]
        \\     pub fn index(self: Self, req: Request) -> Response {
        \\         return Response.json("[]");
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/users")]
        \\ pub type LegacyUserController {
        \\     #[getMapping("/")]
        \\     pub fn index(self: Self, req: Request) -> Response {
        \\         return Response.json("[]");
        \\     }
        \\ }
        \\
        \\ fn main() {
        \\     val code = bootAndExit(App(port: 8080, basePath: "/api"));
        \\ }
        , []);
}
```

`modules/rakun-test/test/__snapshots__/boot/a-duplicate-route-is-a-distinct-non-zero-exit.snap`
```
listen none
beans 2
routes 2
exit 3
```

## 73-rakun-starters — `starters`

**Test file:** `repository/rakun/starters/test/starters_test.bp` · **Snapshots:** `repository/rakun/starters/test/__snapshots__/starter/` · **Target:** erlang · **Pins:** each starter resolves its module set transitively in one pass; starters overlap and the resolver de-duplicates; `rakun-starter-test` is the only starter reaching outside the repository (`onze`); declaring one starter makes the matching front 72 auto-configuration eligible (`RakunDataSourceAutoConfiguration` for `rakun-starter-data-sql`) and no other

> `autoconfig` names beyond `RakunCoreAutoConfiguration`, `RakunDataSourceAutoConfiguration` and `RakunCacheAutoConfiguration` follow front 72's `Rakun<Subsystem>AutoConfiguration` pattern (name per README § Step 4).

### `starter: rakun-starter brings the core and logging`

```bp
test "starter: rakun-starter brings the core and logging" {
    try assertStarter(@src(), "rakun-starter");
}
```

`repository/rakun/starters/test/__snapshots__/starter/rakun-starter-brings-the-core-and-logging.snap`
```
brings [rakun, rakun-logging]
autoconfig [RakunCoreAutoConfiguration]
```

### `starter: rakun-starter-web resolves web validation and the base starter in one pass`

```bp
test "starter: rakun-starter-web resolves web validation and the base starter in one pass" {
    try assertStarter(@src(), "rakun-starter-web");
}
```

`repository/rakun/starters/test/__snapshots__/starter/rakun-starter-web-resolves-web-validation-and-the-base-starter-in-one-pass.snap`
```
brings [rakun, rakun-logging, rakun-validation, rakun-web]
autoconfig [RakunCoreAutoConfiguration, RakunValidationAutoConfiguration, RakunWebAutoConfiguration]
```

### `starter: rakun-starter-data-sql makes the datasource auto-configuration eligible and nothing else`

```bp
test "starter: rakun-starter-data-sql makes the datasource auto-configuration eligible and nothing else" {
    try assertStarter(@src(), "rakun-starter-data-sql");
}
```

`repository/rakun/starters/test/__snapshots__/starter/rakun-starter-data-sql-makes-the-datasource-auto-configuration-eligible-and-nothing-else.snap`
```
brings [rakun, rakun-data, rakun-logging]
autoconfig [RakunCoreAutoConfiguration, RakunDataSourceAutoConfiguration]
```

### `starter: rakun-starter-security brings security and session`

```bp
test "starter: rakun-starter-security brings security and session" {
    try assertStarter(@src(), "rakun-starter-security");
}
```

`repository/rakun/starters/test/__snapshots__/starter/rakun-starter-security-brings-security-and-session.snap`
```
brings [rakun, rakun-logging, rakun-security, rakun-session]
autoconfig [RakunCoreAutoConfiguration, RakunSecurityAutoConfiguration, RakunSessionAutoConfiguration]
```

### `starter: rakun-starter-cache brings only the cache module`

```bp
test "starter: rakun-starter-cache brings only the cache module" {
    try assertStarter(@src(), "rakun-starter-cache");
}
```

`repository/rakun/starters/test/__snapshots__/starter/rakun-starter-cache-brings-only-the-cache-module.snap`
```
brings [rakun, rakun-cache, rakun-logging]
autoconfig [RakunCacheAutoConfiguration, RakunCoreAutoConfiguration]
```

### `starter: rakun-starter-test is the only starter that reaches outside the repository`

```bp
test "starter: rakun-starter-test is the only starter that reaches outside the repository" {
    try assertStarter(@src(), "rakun-starter-test");
}
```

`repository/rakun/starters/test/__snapshots__/starter/rakun-starter-test-is-the-only-starter-that-reaches-outside-the-repository.snap`
```
brings [onze, rakun, rakun-logging, rakun-test]
autoconfig [RakunCoreAutoConfiguration]
```

## 80-rakun-devtools — `rakun-devtools`

**Test file:** `modules/rakun-devtools/test/reload_test.bp` · **Snapshots:** `modules/rakun-devtools/test/__snapshots__/reload/` · **Target:** erlang · **Pins:** one touch → exactly one reload; two files in one interval → one cycle covering both; an `exclude` glob produces none; a trigger file defers every change until it is touched; reloading an unchanged module leaves `rkRouteCount()` unchanged; a compile error leaves the previous version answering

> Script steps: `watch <root>` · `exclude <glob>` · `trigger <file>` · `touch <file>` · `poll` (one interval, mtimes moved explicitly). A `poll` that reloads renders `change <files> -> reload <modules> in <n> steps` (`n` = steps completed of README § Mechanism's five-step sequence) followed by `keep routes <n>` (`rkRouteCount()` after the cycle); a `poll` with nothing to do renders nothing. Modules are the front's pre-built fixtures (`fixture_orders`, one route; `fixture_broken`, a compile error).

### `reload: touching one file under a root produces exactly one reload`

```bp
test "reload: touching one file under a root produces exactly one reload" {
    try assertReload(@src(), ["watch src", "touch src/fixture_orders.bp", "poll", "poll"]);
}
```

`modules/rakun-devtools/test/__snapshots__/reload/touching-one-file-under-a-root-produces-exactly-one-reload.snap`
```
watch src
change src/fixture_orders.bp -> reload fixture_orders in 5 steps
keep routes 1
```

### `reload: two files changed inside one interval produce one cycle covering both`

```bp
test "reload: two files changed inside one interval produce one cycle covering both" {
    try assertReload(@src(), ["watch src", "touch src/fixture_orders.bp", "touch src/fixture_users.bp", "poll"]);
}
```

`modules/rakun-devtools/test/__snapshots__/reload/two-files-changed-inside-one-interval-produce-one-cycle-covering-both.snap`
```
watch src
change src/fixture_orders.bp, src/fixture_users.bp -> reload fixture_orders, fixture_users in 5 steps
keep routes 2
```

### `reload: a file matching an exclude pattern produces no reload`

```bp
test "reload: a file matching an exclude pattern produces no reload" {
    try assertReload(@src(), ["watch src", "exclude static/**", "touch src/static/app.css", "poll"]);
}
```

`modules/rakun-devtools/test/__snapshots__/reload/a-file-matching-an-exclude-pattern-produces-no-reload.snap`
```
watch src
```

### `reload: a trigger file defers every change until it is touched`

```bp
test "reload: a trigger file defers every change until it is touched" {
    try assertReload(@src(), [
        "watch src",
        "trigger .reloadtrigger",
        "touch src/fixture_orders.bp",
        "poll",
        "touch src/fixture_users.bp",
        "poll",
        "touch .reloadtrigger",
        "poll",
    ]);
}
```

`modules/rakun-devtools/test/__snapshots__/reload/a-trigger-file-defers-every-change-until-it-is-touched.snap`
```
watch src
change src/fixture_orders.bp, src/fixture_users.bp -> reload fixture_orders, fixture_users in 5 steps
keep routes 2
```

### `reload: reloading an unchanged controller twice does not double the route table`

```bp
test "reload: reloading an unchanged controller twice does not double the route table" {
    try assertReload(@src(), ["watch src", "touch src/fixture_orders.bp", "poll", "touch src/fixture_orders.bp", "poll"]);
}
```

`modules/rakun-devtools/test/__snapshots__/reload/reloading-an-unchanged-controller-twice-does-not-double-the-route-table.snap`
```
watch src
change src/fixture_orders.bp -> reload fixture_orders in 5 steps
keep routes 1
change src/fixture_orders.bp -> reload fixture_orders in 5 steps
keep routes 1
```

### `reload: a compile error stops after the compile step and keeps the running code`

```bp
test "reload: a compile error stops after the compile step and keeps the running code" {
    try assertReload(@src(), ["watch src", "touch src/fixture_orders.bp", "poll", "touch src/fixture_broken.bp", "poll"]);
}
```

`modules/rakun-devtools/test/__snapshots__/reload/a-compile-error-stops-after-the-compile-step-and-keeps-the-running-code.snap`
```
watch src
change src/fixture_orders.bp -> reload fixture_orders in 5 steps
keep routes 1
change src/fixture_broken.bp -> reload fixture_broken in 2 steps
keep routes 1
```

## 81-rakun-packaging-release — `rakun-release`

**Test file:** `modules/rakun-release/test/release_test.bp` · **Snapshots:** `modules/rakun-release/test/__snapshots__/release/` · **Target:** erlang · **Pins:** the release tree holds `bin/`, `lib/<app>-<vsn>/ebin/`, `releases/<vsn>/` with `.rel`, `sys.config`, `vm.args` and the boot script, and nothing else (no source, no `.botopinkbuild/`); two renders of one `Release` are byte-identical (the snapshot is the second render); every dependency appears once in the SBOM, a diamond included; a build with no dependencies is a valid empty SBOM; the Kubernetes probes are front 76's own paths

> helper gap: `assertRelease` renders no file contents, so `.rel` ordering, `-mode embedded`, the cookie reference, the four `COPY` layers and the unit's `ExecStart` (steps 1, 3, 4) are not pinnable here.
> Manifest strings: `name=` · `version=` · `erts=host` (not bundled — the README spells only `bundled`) · `applications=` · `project=<fixture dir>` (its `botopink.json` drives the module list and the SBOM walk). Fixtures under `modules/rakun-release/test/fixtures/`: `shop` (modules `shop_app`, `shop_orders`; depends on `greeter@0.1.0`, module `greeter`), `shop-diamond` (depends on `left@0.1.0` and `right@0.1.0`, both depending on `greeter@0.1.0`), `bare` (module `bare_app`, no dependencies). `sbom.json` sits at the tree root (path per README § Mechanism, artefact table).

### `release: the tree holds the release layout and nothing else`

```bp
test "release: the tree holds the release layout and nothing else" {
    try assertRelease(@src(), [
        "name=shop",
        "version=1.4.0",
        "erts=host",
        "applications=kernel,stdlib,greeter,shop",
        "project=test/fixtures/shop",
    ]);
}
```

`modules/rakun-release/test/__snapshots__/release/the-tree-holds-the-release-layout-and-nothing-else.snap`
```
bin/shop
lib/greeter-0.1.0/ebin/greeter.app
lib/greeter-0.1.0/ebin/greeter.beam
lib/shop-1.4.0/ebin/shop.app
lib/shop-1.4.0/ebin/shop_app.beam
lib/shop-1.4.0/ebin/shop_orders.beam
releases/1.4.0/shop.boot
releases/1.4.0/shop.rel
releases/1.4.0/sys.config
releases/1.4.0/vm.args
sbom.json
sbom 1 components
probes /actuator/health/liveness /actuator/health/readiness
```

### `release: a diamond dependency appears once in the sbom`

```bp
test "release: a diamond dependency appears once in the sbom" {
    try assertRelease(@src(), [
        "name=shop",
        "version=1.4.0",
        "erts=host",
        "applications=kernel,stdlib,greeter,left,right,shop",
        "project=test/fixtures/shop-diamond",
    ]);
}
```

`modules/rakun-release/test/__snapshots__/release/a-diamond-dependency-appears-once-in-the-sbom.snap`
```
bin/shop
lib/greeter-0.1.0/ebin/greeter.app
lib/greeter-0.1.0/ebin/greeter.beam
lib/left-0.1.0/ebin/left.app
lib/left-0.1.0/ebin/left.beam
lib/right-0.1.0/ebin/right.app
lib/right-0.1.0/ebin/right.beam
lib/shop-1.4.0/ebin/shop.app
lib/shop-1.4.0/ebin/shop_app.beam
releases/1.4.0/shop.boot
releases/1.4.0/shop.rel
releases/1.4.0/sys.config
releases/1.4.0/vm.args
sbom.json
sbom 3 components
probes /actuator/health/liveness /actuator/health/readiness
```

### `release: a build with no dependencies produces a valid empty sbom`

```bp
test "release: a build with no dependencies produces a valid empty sbom" {
    try assertRelease(@src(), [
        "name=bare",
        "version=0.1.0",
        "erts=host",
        "applications=kernel,stdlib,bare",
        "project=test/fixtures/bare",
    ]);
}
```

`modules/rakun-release/test/__snapshots__/release/a-build-with-no-dependencies-produces-a-valid-empty-sbom.snap`
```
bin/bare
lib/bare-0.1.0/ebin/bare.app
lib/bare-0.1.0/ebin/bare_app.beam
releases/0.1.0/bare.boot
releases/0.1.0/bare.rel
releases/0.1.0/sys.config
releases/0.1.0/vm.args
sbom.json
sbom 0 components
probes /actuator/health/liveness /actuator/health/readiness
```

### `release: the version names the releases directory and the application directory`

```bp
test "release: the version names the releases directory and the application directory" {
    try assertRelease(@src(), [
        "name=bare",
        "version=2.0.0-rc.1",
        "erts=host",
        "applications=kernel,stdlib,bare",
        "project=test/fixtures/bare",
    ]);
}
```

`modules/rakun-release/test/__snapshots__/release/the-version-names-the-releases-directory-and-the-application-directory.snap`
```
bin/bare
lib/bare-2.0.0-rc.1/ebin/bare.app
lib/bare-2.0.0-rc.1/ebin/bare_app.beam
releases/2.0.0-rc.1/bare.boot
releases/2.0.0-rc.1/bare.rel
releases/2.0.0-rc.1/sys.config
releases/2.0.0-rc.1/vm.args
sbom.json
sbom 0 components
probes /actuator/health/liveness /actuator/health/readiness
```

### `release: the application order in the manifest does not change the tree`

```bp
test "release: the application order in the manifest does not change the tree" {
    try assertRelease(@src(), [
        "name=shop",
        "version=1.4.0",
        "erts=host",
        "applications=shop,greeter,stdlib,kernel",
        "project=test/fixtures/shop",
    ]);
}
```

`modules/rakun-release/test/__snapshots__/release/the-application-order-in-the-manifest-does-not-change-the-tree.snap`
```
bin/shop
lib/greeter-0.1.0/ebin/greeter.app
lib/greeter-0.1.0/ebin/greeter.beam
lib/shop-1.4.0/ebin/shop.app
lib/shop-1.4.0/ebin/shop_app.beam
lib/shop-1.4.0/ebin/shop_orders.beam
releases/1.4.0/shop.boot
releases/1.4.0/shop.rel
releases/1.4.0/sys.config
releases/1.4.0/vm.args
sbom.json
sbom 1 components
probes /actuator/health/liveness /actuator/health/readiness
```

### `release: a source tree and a build directory beside the project are not packed`

```bp
test "release: a source tree and a build directory beside the project are not packed" {
    try assertRelease(@src(), [
        "name=bare",
        "version=0.1.0",
        "erts=host",
        "applications=kernel,stdlib,bare",
        "project=test/fixtures/bare-with-scratch",
    ]);
}
```

`modules/rakun-release/test/__snapshots__/release/a-source-tree-and-a-build-directory-beside-the-project-are-not-packed.snap`
```
bin/bare
lib/bare-0.1.0/ebin/bare.app
lib/bare-0.1.0/ebin/bare_app.beam
releases/0.1.0/bare.boot
releases/0.1.0/bare.rel
releases/0.1.0/sys.config
releases/0.1.0/vm.args
sbom.json
sbom 0 components
probes /actuator/health/liveness /actuator/health/readiness
```

## 84-rakun-persistent-jobs — `rakun-scheduling`

**Test file:** `modules/rakun-scheduling/test/jobstore/jobstore_test.bp` · **Snapshots:** `modules/rakun-scheduling/test/jobstore/__snapshots__/jobstore/` · **Target:** erlang · **Pins:** three schedulers over one store fire a due trigger once and the winner is the recorded owner; a dead node's acquired trigger is reclaimed after its lease by another node; a handler longer than the lease renews it and is not reclaimed; a failing handler retries to its ceiling, is recorded `failed`, and the trigger returns to `waiting`; a trigger that is not due stays `waiting` with no owner

> helper gap: `assertJobStore` renders one state line per step, so fire *counts* (three nodes → one fire, `FireAll` × 3) are pinned by the ownership transition, not by a count. Script steps: `boot <node>` · `advance <instant>` (front 01's clock double) · `tick` (every booted node ticks, in boot order; node ids are the seed) · `kill <node> after acquire` · `slow <job> <ms>` · `fail <job>` · `succeed <job>`. The fixed clock starts at `2026-01-01T00:00:00Z`; the lease is the fixture's 60 s.

### `jobstore: three schedulers over one store fire a due trigger once`

```bp
test "jobstore: three schedulers over one store fire a due trigger once" {
    try assertJobStore(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {persistentJob, Trigger, MisfirePolicy, registerTrigger, jobData} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ pub type Billing {
        \\     #[persistentJob("nightly-invoices", "0 3 * * *")]
        \\     pub fn runInvoices(self: Self, data: string) -> string {
        \\         return "billed=1";
        \\     }
        \\ }
        \\
        \\ val registered = registerTrigger(Trigger(
        \\     name: "nightly-invoices",
        \\     job: "nightly-invoices",
        \\     cron: "0 3 * * *",
        \\     startAt: 0,
        \\     endAt: 0,
        \\     misfire: MisfirePolicy.FireAll,
        \\     retries: 3,
        \\     backoffMs: 2000,
        \\ ), jobData([#("period", "current")]));
        , ["boot node-1", "boot node-2", "boot node-3", "advance 2026-01-01T03:00:01Z", "tick"]);
}
```

`modules/rakun-scheduling/test/jobstore/__snapshots__/jobstore/three-schedulers-over-one-store-fire-a-due-trigger-once.snap`
```
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=node-1
```

### `jobstore: a dead node's acquired trigger is reclaimed after its lease`

```bp
test "jobstore: a dead node's acquired trigger is reclaimed after its lease" {
    try assertJobStore(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {persistentJob, Trigger, MisfirePolicy, registerTrigger, jobData} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ pub type Billing {
        \\     #[persistentJob("nightly-invoices", "0 3 * * *")]
        \\     pub fn runInvoices(self: Self, data: string) -> string {
        \\         return "billed=1";
        \\     }
        \\ }
        \\
        \\ val registered = registerTrigger(Trigger(
        \\     name: "nightly-invoices",
        \\     job: "nightly-invoices",
        \\     cron: "0 3 * * *",
        \\     startAt: 0,
        \\     endAt: 0,
        \\     misfire: MisfirePolicy.FireNow,
        \\     retries: 0,
        \\     backoffMs: 0,
        \\ ), jobData([#("period", "current")]));
        , ["boot node-1", "boot node-2", "kill node-1 after acquire", "advance 2026-01-01T03:00:01Z", "tick", "advance 2026-01-01T03:02:01Z", "tick"]);
}
```

`modules/rakun-scheduling/test/jobstore/__snapshots__/jobstore/a-dead-node-s-acquired-trigger-is-reclaimed-after-its-lease.snap`
```
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=acquired owner=node-1
job nightly-invoices state=acquired owner=node-1
job nightly-invoices state=waiting owner=node-2
```

### `jobstore: a handler longer than the lease renews it and is not reclaimed`

```bp
test "jobstore: a handler longer than the lease renews it and is not reclaimed" {
    try assertJobStore(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {persistentJob, Trigger, MisfirePolicy, registerTrigger, jobData} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ pub type Billing {
        \\     #[persistentJob("nightly-invoices", "0 3 * * *")]
        \\     pub fn runInvoices(self: Self, data: string) -> string {
        \\         return "billed=1";
        \\     }
        \\ }
        \\
        \\ val registered = registerTrigger(Trigger(
        \\     name: "nightly-invoices",
        \\     job: "nightly-invoices",
        \\     cron: "0 3 * * *",
        \\     startAt: 0,
        \\     endAt: 0,
        \\     misfire: MisfirePolicy.FireNow,
        \\     retries: 0,
        \\     backoffMs: 0,
        \\ ), jobData([#("period", "current")]));
        , ["boot node-1", "boot node-2", "slow nightly-invoices 180000", "advance 2026-01-01T03:00:01Z", "tick", "advance 2026-01-01T03:02:01Z", "tick"]);
}
```

`modules/rakun-scheduling/test/jobstore/__snapshots__/jobstore/a-handler-longer-than-the-lease-renews-it-and-is-not-reclaimed.snap`
```
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=acquired owner=node-1
job nightly-invoices state=acquired owner=node-1
job nightly-invoices state=acquired owner=node-1
```

### `jobstore: a failing handler retries to its ceiling and the trigger returns to waiting`

```bp
test "jobstore: a failing handler retries to its ceiling and the trigger returns to waiting" {
    try assertJobStore(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {persistentJob, Trigger, MisfirePolicy, registerTrigger, jobData} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ pub type Billing {
        \\     #[persistentJob("nightly-invoices", "0 3 * * *")]
        \\     pub fn runInvoices(self: Self, data: string) -> string {
        \\         return "billed=1";
        \\     }
        \\ }
        \\
        \\ val registered = registerTrigger(Trigger(
        \\     name: "nightly-invoices",
        \\     job: "nightly-invoices",
        \\     cron: "0 3 * * *",
        \\     startAt: 0,
        \\     endAt: 0,
        \\     misfire: MisfirePolicy.SkipToNext,
        \\     retries: 3,
        \\     backoffMs: 2000,
        \\ ), jobData([#("period", "current")]));
        , ["boot node-1", "fail nightly-invoices", "advance 2026-01-01T03:00:01Z", "tick", "succeed nightly-invoices", "advance 2026-01-02T03:00:01Z", "tick"]);
}
```

`modules/rakun-scheduling/test/jobstore/__snapshots__/jobstore/a-failing-handler-retries-to-its-ceiling-and-the-trigger-returns-to-waiting.snap`
```
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=node-1
job nightly-invoices state=waiting owner=node-1
job nightly-invoices state=waiting owner=node-1
job nightly-invoices state=waiting owner=node-1
```

### `jobstore: a trigger that is not due stays waiting with no owner`

```bp
test "jobstore: a trigger that is not due stays waiting with no owner" {
    try assertJobStore(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {persistentJob, Trigger, MisfirePolicy, registerTrigger, jobData} from "rakun-scheduling";
        \\
        \\ #[service]
        \\ pub type Billing {
        \\     #[persistentJob("nightly-invoices", "0 3 * * *")]
        \\     pub fn runInvoices(self: Self, data: string) -> string {
        \\         return "billed=1";
        \\     }
        \\ }
        \\
        \\ val registered = registerTrigger(Trigger(
        \\     name: "nightly-invoices",
        \\     job: "nightly-invoices",
        \\     cron: "0 3 * * *",
        \\     startAt: 0,
        \\     endAt: 0,
        \\     misfire: MisfirePolicy.SkipToNext,
        \\     retries: 0,
        \\     backoffMs: 0,
        \\ ), jobData([#("period", "current")]));
        , ["boot node-1", "boot node-2", "advance 2026-01-01T02:59:59Z", "tick"]);
}
```

`modules/rakun-scheduling/test/jobstore/__snapshots__/jobstore/a-trigger-that-is-not-due-stays-waiting-with-no-owner.snap`
```
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
```

## 85-rakun-mail — `rakun-mail`

**Test file:** `modules/rakun-mail/test/mail_test.bp` · **Snapshots:** `modules/rakun-mail/test/__snapshots__/mail/` · **Target:** erlang · **Pins:** text only → single-part `text/plain; charset=utf-8`; text + html → `multipart/alternative`, plain first; an attachment wraps the whole in `multipart/mixed`; an ASCII subject is not encoded and a non-ASCII one is RFC 2047 `=?UTF-8?B?…?=`; a display name with a comma is quoted and does not split the header; `bcc` appears in no header; `<script>` is escaped in the HTML part and literal in the plain part; `Date` comes from the test clock

> `send` is a call expression over the source producing a `Mail`; the helper renders the message the sender would put on the wire (LF in the snapshot). Header order is sorted case-insensitively. `Message-ID` and the boundary are seeded (`mail-0001`, `=_rakun_0001`). Text parts are quoted-printable (`=` → `=3D`).

### `mail: text only produces a single part text plain message`

```bp
test "mail: text only produces a single part text plain message" {
    try assertMail(@src(),
        \\ import {Mail, Attachment} from "rakun-mail";
        \\
        \\ pub fn welcome(to: string) -> Mail {
        \\     val recipients = [to];
        \\     val none: string[] = [];
        \\     val noAttachments: Attachment[] = [];
        \\     val extraHeaders: Array<#(string, string)> = [];
        \\     return Mail(
        \\         from: "Shop <no-reply@shop.example>",
        \\         to: recipients,
        \\         cc: none,
        \\         bcc: none,
        \\         replyTo: "",
        \\         subject: "Reset your password",
        \\         text: "Hello, Ana.\nOpen https://shop.example/reset?t=abc\n",
        \\         html: "",
        \\         attachments: noAttachments,
        \\         headers: extraHeaders,
        \\     );
        \\ }
        , "welcome(ana@example.org)");
}
```

`modules/rakun-mail/test/__snapshots__/mail/text-only-produces-a-single-part-text-plain-message.snap`
```
Content-Transfer-Encoding: quoted-printable
Content-Type: text/plain; charset=utf-8
Date: Thu, 01 Jan 2026 00:00:00 +0000
From: Shop <no-reply@shop.example>
Message-ID: <mail-0001@shop.example>
MIME-Version: 1.0
Subject: Reset your password
To: ana@example.org

Hello, Ana.
Open https://shop.example/reset?t=3Dabc
```

### `mail: text plus html produces multipart alternative with the plain part first`

```bp
test "mail: text plus html produces multipart alternative with the plain part first" {
    try assertMail(@src(),
        \\ import {Mail, Attachment} from "rakun-mail";
        \\
        \\ pub fn reset(to: string) -> Mail {
        \\     val recipients = [to];
        \\     val none: string[] = [];
        \\     val noAttachments: Attachment[] = [];
        \\     val extraHeaders: Array<#(string, string)> = [];
        \\     return Mail(
        \\         from: "Shop <no-reply@shop.example>",
        \\         to: recipients,
        \\         cc: none,
        \\         bcc: none,
        \\         replyTo: "",
        \\         subject: "Reset your password",
        \\         text: "Hello, Ana.\n",
        \\         html: "<p>Hello, Ana.</p>",
        \\         attachments: noAttachments,
        \\         headers: extraHeaders,
        \\     );
        \\ }
        , "reset(ana@example.org)");
}
```

`modules/rakun-mail/test/__snapshots__/mail/text-plus-html-produces-multipart-alternative-with-the-plain-part-first.snap`
```
Content-Type: multipart/alternative; boundary="=_rakun_0001"
Date: Thu, 01 Jan 2026 00:00:00 +0000
From: Shop <no-reply@shop.example>
Message-ID: <mail-0001@shop.example>
MIME-Version: 1.0
Subject: Reset your password
To: ana@example.org

--=_rakun_0001
Content-Transfer-Encoding: quoted-printable
Content-Type: text/plain; charset=utf-8

Hello, Ana.
--=_rakun_0001
Content-Transfer-Encoding: quoted-printable
Content-Type: text/html; charset=utf-8

<p>Hello, Ana.</p>
--=_rakun_0001--
```

### `mail: an attachment wraps the message in multipart mixed`

```bp
test "mail: an attachment wraps the message in multipart mixed" {
    try assertMail(@src(),
        \\ import {Mail, Attachment} from "rakun-mail";
        \\
        \\ pub fn invoice(to: string) -> Mail {
        \\     val recipients = [to];
        \\     val none: string[] = [];
        \\     val files = [Attachment(filename: "hello.txt", contentType: "text/plain", path: "test/fixtures/hello.txt", inline: false, cid: "")];
        \\     val extraHeaders: Array<#(string, string)> = [];
        \\     return Mail(
        \\         from: "Shop <no-reply@shop.example>",
        \\         to: recipients,
        \\         cc: none,
        \\         bcc: none,
        \\         replyTo: "",
        \\         subject: "Your invoice",
        \\         text: "Invoice attached.\n",
        \\         html: "",
        \\         attachments: files,
        \\         headers: extraHeaders,
        \\     );
        \\ }
        , "invoice(ana@example.org)");
}
```

`modules/rakun-mail/test/__snapshots__/mail/an-attachment-wraps-the-message-in-multipart-mixed.snap`
```
Content-Type: multipart/mixed; boundary="=_rakun_0001"
Date: Thu, 01 Jan 2026 00:00:00 +0000
From: Shop <no-reply@shop.example>
Message-ID: <mail-0001@shop.example>
MIME-Version: 1.0
Subject: Your invoice
To: ana@example.org

--=_rakun_0001
Content-Transfer-Encoding: quoted-printable
Content-Type: text/plain; charset=utf-8

Invoice attached.
--=_rakun_0001
Content-Disposition: attachment; filename="hello.txt"
Content-Transfer-Encoding: base64
Content-Type: text/plain; name="hello.txt"

aGVsbG8K
--=_rakun_0001--
```

### `mail: a non-ascii subject is rfc 2047 encoded and a quoted display name does not split`

```bp
test "mail: a non-ascii subject is rfc 2047 encoded and a quoted display name does not split" {
    try assertMail(@src(),
        \\ import {Mail, Attachment} from "rakun-mail";
        \\
        \\ pub fn reset(to: string) -> Mail {
        \\     val recipients = [to];
        \\     val none: string[] = [];
        \\     val noAttachments: Attachment[] = [];
        \\     val extraHeaders: Array<#(string, string)> = [];
        \\     return Mail(
        \\         from: "Shop <no-reply@shop.example>",
        \\         to: recipients,
        \\         cc: none,
        \\         bcc: none,
        \\         replyTo: "",
        \\         subject: "Redefinição de senha",
        \\         text: "Olá.\n",
        \\         html: "",
        \\         attachments: noAttachments,
        \\         headers: extraHeaders,
        \\     );
        \\ }
        , "reset(Silva, Ana <ana@example.org>)");
}
```

`modules/rakun-mail/test/__snapshots__/mail/a-non-ascii-subject-is-rfc-2047-encoded-and-a-quoted-display-name-does-not-split.snap`
```
Content-Transfer-Encoding: quoted-printable
Content-Type: text/plain; charset=utf-8
Date: Thu, 01 Jan 2026 00:00:00 +0000
From: Shop <no-reply@shop.example>
Message-ID: <mail-0001@shop.example>
MIME-Version: 1.0
Subject: =?UTF-8?B?UmVkZWZpbmnDp8OjbyBkZSBzZW5oYQ==?=
To: "Silva, Ana" <ana@example.org>

Ol=C3=A1.
```

### `mail: bcc recipients appear in no header`

```bp
test "mail: bcc recipients appear in no header" {
    try assertMail(@src(),
        \\ import {Mail, Attachment} from "rakun-mail";
        \\
        \\ pub fn audited(to: string) -> Mail {
        \\     val recipients = [to];
        \\     val none: string[] = [];
        \\     val hidden = ["audit@example.org"];
        \\     val noAttachments: Attachment[] = [];
        \\     val extraHeaders: Array<#(string, string)> = [];
        \\     return Mail(
        \\         from: "Shop <no-reply@shop.example>",
        \\         to: recipients,
        \\         cc: none,
        \\         bcc: hidden,
        \\         replyTo: "support@shop.example",
        \\         subject: "Order shipped",
        \\         text: "Shipped.\n",
        \\         html: "",
        \\         attachments: noAttachments,
        \\         headers: extraHeaders,
        \\     );
        \\ }
        , "audited(ana@example.org)");
}
```

`modules/rakun-mail/test/__snapshots__/mail/bcc-recipients-appear-in-no-header.snap`
```
Content-Transfer-Encoding: quoted-printable
Content-Type: text/plain; charset=utf-8
Date: Thu, 01 Jan 2026 00:00:00 +0000
From: Shop <no-reply@shop.example>
Message-ID: <mail-0001@shop.example>
MIME-Version: 1.0
Reply-To: support@shop.example
Subject: Order shipped
To: ana@example.org

Shipped.
```

### `mail: a display name with markup is escaped in html and literal in plain`

```bp
test "mail: a display name with markup is escaped in html and literal in plain" {
    try assertMail(@src(),
        \\ import {Mail, Attachment} from "rakun-mail";
        \\ import {escape} from "std";
        \\
        \\ pub fn greet(to: string, name: string) -> Mail {
        \\     val recipients = [to];
        \\     val none: string[] = [];
        \\     val noAttachments: Attachment[] = [];
        \\     val extraHeaders: Array<#(string, string)> = [];
        \\     val safeName = escape.html(name);
        \\     return Mail(
        \\         from: "Shop <no-reply@shop.example>",
        \\         to: recipients,
        \\         cc: none,
        \\         bcc: none,
        \\         replyTo: "",
        \\         subject: "Hello",
        \\         text: "Hello, " + name + ".\n",
        \\         html: "<p>Hello, " + safeName + ".</p>",
        \\         attachments: noAttachments,
        \\         headers: extraHeaders,
        \\     );
        \\ }
        , "greet(bob@example.org, <script>x</script>)");
}
```

`modules/rakun-mail/test/__snapshots__/mail/a-display-name-with-markup-is-escaped-in-html-and-literal-in-plain.snap`
```
Content-Type: multipart/alternative; boundary="=_rakun_0001"
Date: Thu, 01 Jan 2026 00:00:00 +0000
From: Shop <no-reply@shop.example>
Message-ID: <mail-0001@shop.example>
MIME-Version: 1.0
Subject: Hello
To: bob@example.org

--=_rakun_0001
Content-Transfer-Encoding: quoted-printable
Content-Type: text/plain; charset=utf-8

Hello, <script>x</script>.
--=_rakun_0001
Content-Transfer-Encoding: quoted-printable
Content-Type: text/html; charset=utf-8

<p>Hello, &lt;script&gt;x&lt;/script&gt;.</p>
--=_rakun_0001--
```

## 86-rakun-messaging-reliability — `rakun-messaging`

**Test file:** `modules/rakun-messaging/test/reliability/retry_test.bp` (suite `retry`) · `modules/rakun-messaging/test/reliability/outcome_test.bp` (suite `outcome`) · **Snapshots:** `modules/rakun-messaging/test/reliability/__snapshots__/<suite>/` · **Target:** erlang · **Pins:** backoff series `2000, 4000, 8000, 16000, 30000` for `initialMs: 2000, multiplierPercent: 200, maxMs: 30000`; `initialMs` above `maxMs` is clamped; `multiplierPercent: 100` is constant; `Retry` at `attempt == maxAttempts` dead-letters, at `maxAttempts - 1` retries; `Reject` dead-letters at attempt 1 consuming no attempt; `Done` acks; a crash is `Retry("crashed: …")`; `rakun.messaging.listener.<name>.dead-letter` overrides the `.dlq` suffix; the attempt count travels in `x-rakun-attempt`

> Config keys `rakun.messaging.listener.<name>.retry.initial-ms` / `.retry.multiplier-percent` / `.retry.max-ms` follow the `RetryPolicy` field names (name per README § Step 1); the README spells only `.retry.max-attempts` and `.dead-letter`. `attempt <n> at +<ms>` is the offset from the first delivery, i.e. the running sum of `nextDelay(policy, 1..n-1)`. Outcomes are `ok` / `fail` per attempt.

### `retry: the backoff doubles and stops at the ceiling`

```bp
test "retry: the backoff doubles and stops at the ceiling" {
    try assertRetry(@src(), [
        "rakun.messaging.listener.orders.retry.initial-ms=2000",
        "rakun.messaging.listener.orders.retry.multiplier-percent=200",
        "rakun.messaging.listener.orders.retry.max-ms=30000",
        "rakun.messaging.listener.orders.retry.max-attempts=6",
    ], ["fail", "fail", "fail", "fail", "fail", "ok"]);
}
```

`modules/rakun-messaging/test/reliability/__snapshots__/retry/the-backoff-doubles-and-stops-at-the-ceiling.snap`
```
attempt 1 at +0 -> fail
attempt 2 at +2000 -> fail
attempt 3 at +6000 -> fail
attempt 4 at +14000 -> fail
attempt 5 at +30000 -> fail
attempt 6 at +60000 -> ok
```

### `retry: a transient failure retries until the ceiling then dead-letters`

```bp
test "retry: a transient failure retries until the ceiling then dead-letters" {
    try assertRetry(@src(), [
        "rakun.messaging.listener.orders.retry.initial-ms=2000",
        "rakun.messaging.listener.orders.retry.multiplier-percent=200",
        "rakun.messaging.listener.orders.retry.max-ms=30000",
        "rakun.messaging.listener.orders.retry.max-attempts=3",
    ], ["fail", "fail", "fail"]);
}
```

`modules/rakun-messaging/test/reliability/__snapshots__/retry/a-transient-failure-retries-until-the-ceiling-then-dead-letters.snap`
```
attempt 1 at +0 -> fail
attempt 2 at +2000 -> fail
attempt 3 at +6000 -> fail
dead-letter orders.dlq
```

### `retry: an initial delay above the ceiling is clamped`

```bp
test "retry: an initial delay above the ceiling is clamped" {
    try assertRetry(@src(), [
        "rakun.messaging.listener.orders.retry.initial-ms=30000",
        "rakun.messaging.listener.orders.retry.multiplier-percent=200",
        "rakun.messaging.listener.orders.retry.max-ms=8000",
        "rakun.messaging.listener.orders.retry.max-attempts=3",
    ], ["fail", "fail", "ok"]);
}
```

`modules/rakun-messaging/test/reliability/__snapshots__/retry/an-initial-delay-above-the-ceiling-is-clamped.snap`
```
attempt 1 at +0 -> fail
attempt 2 at +8000 -> fail
attempt 3 at +16000 -> ok
```

### `retry: a multiplier of one hundred is a constant delay`

```bp
test "retry: a multiplier of one hundred is a constant delay" {
    try assertRetry(@src(), [
        "rakun.messaging.listener.orders.retry.initial-ms=500",
        "rakun.messaging.listener.orders.retry.multiplier-percent=100",
        "rakun.messaging.listener.orders.retry.max-ms=8000",
        "rakun.messaging.listener.orders.retry.max-attempts=4",
    ], ["fail", "fail", "fail", "ok"]);
}
```

`modules/rakun-messaging/test/reliability/__snapshots__/retry/a-multiplier-of-one-hundred-is-a-constant-delay.snap`
```
attempt 1 at +0 -> fail
attempt 2 at +500 -> fail
attempt 3 at +1000 -> fail
attempt 4 at +1500 -> ok
```

### `retry: the configured dead-letter destination overrides the dlq suffix`

```bp
test "retry: the configured dead-letter destination overrides the dlq suffix" {
    try assertRetry(@src(), [
        "rakun.messaging.listener.orders.retry.initial-ms=500",
        "rakun.messaging.listener.orders.retry.multiplier-percent=200",
        "rakun.messaging.listener.orders.retry.max-ms=8000",
        "rakun.messaging.listener.orders.retry.max-attempts=2",
        "rakun.messaging.listener.orders.dead-letter=orders.failed",
    ], ["fail", "fail"]);
}
```

`modules/rakun-messaging/test/reliability/__snapshots__/retry/the-configured-dead-letter-destination-overrides-the-dlq-suffix.snap`
```
attempt 1 at +0 -> fail
attempt 2 at +500 -> fail
dead-letter orders.failed
```

### `outcome: done acks reject dead-letters and retry nacks on the first attempt`

```bp
test "outcome: done acks reject dead-letters and retry nacks on the first attempt" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {rabbitListener, Delivery} from "rakun-messaging";
        \\ import {Outcome} from "rakun-messaging";
        \\
        \\ #[service]
        \\ type OrderConfirmations {
        \\     #[rabbitListener("orders.confirm")]
        \\     pub fn onOrder(self: Self, delivery: Delivery) -> Outcome {
        \\         val id = delivery.header("order-id");
        \\         if (id == "") {
        \\             return Outcome.Reject(reason: "missing order-id header");
        \\         };
        \\         if (id == "gateway-down") {
        \\             return Outcome.Retry(reason: "payment gateway timeout");
        \\         };
        \\         return Outcome.Done;
        \\     }
        \\ }
        , ["orders.confirm order-id: A-17 | {}", "orders.confirm | {}", "orders.confirm order-id: gateway-down | {}"]);
}
```

`modules/rakun-messaging/test/reliability/__snapshots__/outcome/done-acks-reject-dead-letters-and-retry-nacks-on-the-first-attempt.snap`
```
listener orders.confirm -> OrderConfirmations.onOrder broker=amqp

deliver orders.confirm {} -> ok
deliver orders.confirm {} -> dead-letter
deliver orders.confirm {} -> nack
```

### `outcome: a retry whose attempt header reached the ceiling dead-letters`

```bp
test "outcome: a retry whose attempt header reached the ceiling dead-letters" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {rabbitListener, Delivery} from "rakun-messaging";
        \\ import {Outcome, attemptOf} from "rakun-messaging";
        \\
        \\ #[service]
        \\ type OrderConfirmations {
        \\     #[rabbitListener("orders.confirm")]
        \\     pub fn onOrder(self: Self, delivery: Delivery) -> Outcome {
        \\         val attempt = attemptOf(delivery);
        \\         val done = attempt > 9;
        \\         if (done) {
        \\             return Outcome.Done;
        \\         };
        \\         return Outcome.Retry(reason: "still down on attempt " + attempt.toString());
        \\     }
        \\ }
        , ["orders.confirm x-rakun-attempt: 2 | {}", "orders.confirm x-rakun-attempt: 3 | {}", "orders.confirm x-rakun-attempt: 10 | {}"]);
}
```

`modules/rakun-messaging/test/reliability/__snapshots__/outcome/a-retry-whose-attempt-header-reached-the-ceiling-dead-letters.snap`
```
listener orders.confirm -> OrderConfirmations.onOrder broker=amqp

deliver orders.confirm {} -> nack
deliver orders.confirm {} -> dead-letter
deliver orders.confirm {} -> ok
```

> The second case runs under `rakun.messaging.listener.orders-confirm.retry.max-attempts=3` in the test file's module configuration (listener name per README § Examples, `rakun.messaging.listener.orders-confirm.*`); a non-numeric header counts as attempt 1.

### `outcome: a handler that crashes is handled as a retry`

```bp
test "outcome: a handler that crashes is handled as a retry" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {rabbitListener, Delivery} from "rakun-messaging";
        \\ import {Outcome} from "rakun-messaging";
        \\
        \\ #[service]
        \\ type OrderConfirmations {
        \\     #[rabbitListener("orders.confirm")]
        \\     pub fn onOrder(self: Self, delivery: Delivery) -> Outcome {
        \\         val empty = delivery.body == "";
        \\         if (empty) {
        \\             throw "decode failed";
        \\         };
        \\         return Outcome.Done;
        \\     }
        \\ }
        , ["orders.confirm | {}", "orders.confirm | "]);
}
```

`modules/rakun-messaging/test/reliability/__snapshots__/outcome/a-handler-that-crashes-is-handled-as-a-retry.snap`
```
listener orders.confirm -> OrderConfirmations.onOrder broker=amqp

deliver orders.confirm {} -> ok
deliver orders.confirm  -> nack
```

## 88-rakun-cli — `rakun-cli`

**Test file:** `modules/rakun-cli/test/cli_test.bp` · **Snapshots:** `modules/rakun-cli/test/__snapshots__/cli/` · **Target:** erlang · **Pins:** empty argv and an unknown command print the table and exit 2; a flag last with no value is a usage error, not the fallback; `rakun new <name>` writes `botopink.json`, `src/main.bp`, `application.yaml`; `--template library` generates no `Rakun.run`; `rakun routes` prints one line per route sorted by path and binds no port; `rakun beans` prints each component with its injected fields; exit 3 when the project does not compile; `rakun help` names the CLI for a full-stack project

> helper gap: `assertCli` takes argv only; the inspect cases (`routes`, `beans`, `config`) assume the helper runs argv inside `modules/rakun-cli/test/fixtures/plain-app/` — the same tree `rakun new orders --template plain` writes — and `fixtures/broken-app/` for exit 3. Command summaries are wording per README § Definition of done (the eight names are fixed; summaries are not). `files:` lists paths created relative to the scratch cwd; the line is present even when empty.

### `cli: an empty argv prints the table and exits 2`

```bp
test "cli: an empty argv prints the table and exits 2" {
    try assertCli(@src(), []);
}
```

`modules/rakun-cli/test/__snapshots__/cli/an-empty-argv-prints-the-table-and-exits-2.snap`
```
exit 2
rakun <command> [args]
  new      scaffold a project (--template plain|full-stack|library)
  run      start the application (--profile, --watch, --port)
  build    build the OTP release through rakun-release
  test     run botopink test --target erlang
  routes   print the route table without binding a port
  beans    print the registered components
  config   print the resolved configuration, sanitised
  help     print this table
full-stack project: use onze
files:
```

### `cli: help exits 0 with the same table`

```bp
test "cli: help exits 0 with the same table" {
    try assertCli(@src(), ["help"]);
}
```

`modules/rakun-cli/test/__snapshots__/cli/help-exits-0-with-the-same-table.snap`
```
exit 0
rakun <command> [args]
  new      scaffold a project (--template plain|full-stack|library)
  run      start the application (--profile, --watch, --port)
  build    build the OTP release through rakun-release
  test     run botopink test --target erlang
  routes   print the route table without binding a port
  beans    print the registered components
  config   print the resolved configuration, sanitised
  help     print this table
full-stack project: use onze
files:
```

### `cli: a flag last with no value is a usage error not the fallback`

```bp
test "cli: a flag last with no value is a usage error not the fallback" {
    try assertCli(@src(), ["run", "--profile"]);
}
```

`modules/rakun-cli/test/__snapshots__/cli/a-flag-last-with-no-value-is-a-usage-error-not-the-fallback.snap`
```
exit 2
usage: rakun run [--profile <name>] [--watch] [--port <n>]
--profile expects a value
files:
```

### `cli: new writes the plain scaffold`

```bp
test "cli: new writes the plain scaffold" {
    try assertCli(@src(), ["new", "orders"]);
}
```

`modules/rakun-cli/test/__snapshots__/cli/new-writes-the-plain-scaffold.snap`
```
exit 0
created orders (plain)
files:
orders/application.yaml
orders/botopink.json
orders/src/main.bp
```

### `cli: the library template generates no entry point`

```bp
test "cli: the library template generates no entry point" {
    try assertCli(@src(), ["new", "shared", "--template", "library"]);
}
```

`modules/rakun-cli/test/__snapshots__/cli/the-library-template-generates-no-entry-point.snap`
```
exit 0
created shared (library)
files:
shared/botopink.json
shared/src/root.bp
```

### `cli: routes prints the route table sorted by path without binding a port`

```bp
test "cli: routes prints the route table sorted by path without binding a port" {
    try assertCli(@src(), ["routes"]);
}
```

`modules/rakun-cli/test/__snapshots__/cli/routes-prints-the-route-table-sorted-by-path-without-binding-a-port.snap`
```
exit 0
GET /api/health -> OrdersController.health
GET /api/orders -> OrdersController.index
GET /api/orders/count -> OrdersController.count
files:
```

### `cli: beans prints each component with its injected fields`

```bp
test "cli: beans prints each component with its injected fields" {
    try assertCli(@src(), ["beans"]);
}
```

`modules/rakun-cli/test/__snapshots__/cli/beans-prints-each-component-with-its-injected-fields.snap`
```
exit 0
OrdersController <- orders: OrdersService
OrdersService
files:
```

### `cli: a project that does not compile exits 3 from an inspect command`

```bp
test "cli: a project that does not compile exits 3 from an inspect command" {
    try assertCli(@src(), ["routes", "--project", "test/fixtures/broken-app"]);
}
```

`modules/rakun-cli/test/__snapshots__/cli/a-project-that-does-not-compile-exits-3-from-an-inspect-command.snap`
```
exit 3
test/fixtures/broken-app/src/main.bp:12:5: error: unknown identifier `Respons`
files:
```

> `--project` is not a README flag (name per README § Step 5 — "a project whose database URL is wrong"); it exists only so one argv can name the broken fixture. If the helper gains a cwd argument this case drops the flag.

## 89-rakun-stream-pipelines — `rakun-stream`

**Test file:** `modules/rakun-stream/test/stream_test.bp` · **Snapshots:** `modules/rakun-stream/test/__snapshots__/stream/` · **Target:** erlang · **Pins:** `runStages([], items)` is identity; a `Filter` keeping nothing yields an empty result without raising; a `Split` feeds one item per part to the next stage; stage order matters; `graphOf` is `source → stage… → sink` with one edge per adjacent pair, in order; adding a stage changes the graph with no other edit; `Sink.Collect` makes a pipeline assertable without a broker

> `topology` is a `\\` block declaring a `Pipeline` value named `pipeline`; the helper renders `graphOf(pipeline)` and then runs `runStages(pipeline.stages, inputs)` into the sink, one `out <sink> <value>` per emitted value. The sink name is the `Publish` destination or the `Collect` name.

### `stream: a queue source four stages and a publish sink render as one edge per pair`

```bp
test "stream: a queue source four stages and a publish sink render as one edge per pair" {
    try assertStream(@src(),
        \\ import {Stage, Pipeline, Source, Sink} from "rakun-stream";
        \\
        \\ val stages: Array<Stage> = [
        \\     Stage.Filter(name: "paid-only", keep: { item -> item.startsWith("paid:") }),
        \\     Stage.Transform(name: "strip-prefix", apply: { item -> item.replace("paid:", "") }),
        \\     Stage.Split(name: "one-per-sku", explode: { item -> item.split(",") }),
        \\     Stage.Transform(name: "normalise", apply: { item -> item.trim().toUpper() }),
        \\ ];
        \\
        \\ val pipeline = Pipeline(
        \\     name: "orders",
        \\     source: Source.Queue(destination: "orders.paid", prefetch: 32),
        \\     stages: stages,
        \\     sink: Sink.Publish(destination: "orders.normalised"),
        \\ );
        , ["paid:a1, b2", "refunded:c3", "paid:d4"]);
}
```

`modules/rakun-stream/test/__snapshots__/stream/a-queue-source-four-stages-and-a-publish-sink-render-as-one-edge-per-pair.snap`
```
graph:
orders.paid -> paid-only
paid-only -> strip-prefix
strip-prefix -> one-per-sku
one-per-sku -> normalise
normalise -> orders.normalised

out orders.normalised A1
out orders.normalised B2
out orders.normalised D4
```

### `stream: an empty stage list passes its input through unchanged`

```bp
test "stream: an empty stage list passes its input through unchanged" {
    try assertStream(@src(),
        \\ import {Stage, Pipeline, Source, Sink} from "rakun-stream";
        \\
        \\ val stages: Array<Stage> = [];
        \\
        \\ val pipeline = Pipeline(
        \\     name: "passthrough",
        \\     source: Source.Queue(destination: "in", prefetch: 1),
        \\     stages: stages,
        \\     sink: Sink.Collect(name: "seen"),
        \\ );
        , ["a", "b"]);
}
```

`modules/rakun-stream/test/__snapshots__/stream/an-empty-stage-list-passes-its-input-through-unchanged.snap`
```
graph:
in -> seen

out seen a
out seen b
```

### `stream: a filter that keeps nothing produces an empty result and does not raise`

```bp
test "stream: a filter that keeps nothing produces an empty result and does not raise" {
    try assertStream(@src(),
        \\ import {Stage, Pipeline, Source, Sink} from "rakun-stream";
        \\
        \\ val stages: Array<Stage> = [
        \\     Stage.Filter(name: "never", keep: { item -> item == "impossible" }),
        \\     Stage.Transform(name: "shout", apply: { item -> item.toUpper() }),
        \\ ];
        \\
        \\ val pipeline = Pipeline(
        \\     name: "silent",
        \\     source: Source.Topic(name: "events", group: "silent-group"),
        \\     stages: stages,
        \\     sink: Sink.Collect(name: "seen"),
        \\ );
        , ["a", "b"]);
}
```

`modules/rakun-stream/test/__snapshots__/stream/a-filter-that-keeps-nothing-produces-an-empty-result-and-does-not-raise.snap`
```
graph:
events -> never
never -> shout
shout -> seen
```

### `stream: filter then transform keeps the paid order`

```bp
test "stream: filter then transform keeps the paid order" {
    try assertStream(@src(),
        \\ import {Stage, Pipeline, Source, Sink} from "rakun-stream";
        \\
        \\ val stages: Array<Stage> = [
        \\     Stage.Filter(name: "paid-only", keep: { item -> item.startsWith("paid:") }),
        \\     Stage.Transform(name: "strip", apply: { item -> item.replace("paid:", "") }),
        \\ ];
        \\
        \\ val pipeline = Pipeline(
        \\     name: "filter-first",
        \\     source: Source.Queue(destination: "orders", prefetch: 8),
        \\     stages: stages,
        \\     sink: Sink.Collect(name: "seen"),
        \\ );
        , ["paid:a1", "refunded:c3"]);
}
```

`modules/rakun-stream/test/__snapshots__/stream/filter-then-transform-keeps-the-paid-order.snap`
```
graph:
orders -> paid-only
paid-only -> strip
strip -> seen

out seen a1
```

### `stream: transform then filter keeps nothing because the prefix is already gone`

```bp
test "stream: transform then filter keeps nothing because the prefix is already gone" {
    try assertStream(@src(),
        \\ import {Stage, Pipeline, Source, Sink} from "rakun-stream";
        \\
        \\ val stages: Array<Stage> = [
        \\     Stage.Transform(name: "strip", apply: { item -> item.replace("paid:", "") }),
        \\     Stage.Filter(name: "paid-only", keep: { item -> item.startsWith("paid:") }),
        \\ ];
        \\
        \\ val pipeline = Pipeline(
        \\     name: "transform-first",
        \\     source: Source.Queue(destination: "orders", prefetch: 8),
        \\     stages: stages,
        \\     sink: Sink.Collect(name: "seen"),
        \\ );
        , ["paid:a1", "refunded:c3"]);
}
```

`modules/rakun-stream/test/__snapshots__/stream/transform-then-filter-keeps-nothing-because-the-prefix-is-already-gone.snap`
```
graph:
orders -> strip
strip -> paid-only
paid-only -> seen
```

### `stream: a poll source and an aggregate stage appear in the graph in declaration order`

```bp
test "stream: a poll source and an aggregate stage appear in the graph in declaration order" {
    try assertStream(@src(),
        \\ import {Stage, Pipeline, Source, Sink} from "rakun-stream";
        \\
        \\ val stages: Array<Stage> = [
        \\     Stage.Transform(name: "to-sku", apply: { item -> item.split(" ").at(0).unwrapOr("") }),
        \\     Stage.Aggregate(name: "per-minute", key: { item -> item }, windowMs: 60000),
        \\ ];
        \\
        \\ val pipeline = Pipeline(
        \\     name: "sku-counts",
        \\     source: Source.Poll(everyMs: 5000, cursor: "sku-counts"),
        \\     stages: stages,
        \\     sink: Sink.Publish(destination: "sku.counts"),
        \\ );
        , []);
}
```

`modules/rakun-stream/test/__snapshots__/stream/a-poll-source-and-an-aggregate-stage-appear-in-the-graph-in-declaration-order.snap`
```
graph:
sku-counts -> to-sku
to-sku -> per-minute
per-minute -> sku.counts
```

## 90-rakun-jms-brokers — `rakun-messaging`

**Test file:** `modules/rakun-messaging/test/jms_test.bp` · **Snapshots:** `modules/rakun-messaging/test/__snapshots__/jms/` · **Target:** erlang · **Pins:** `#[jmsListener]` emits the same registration shape as front 15's arms, tagged `jms`, and adds no second dispatch loop; `Outcome.Retry` / `Outcome.Reject` route through front 86 exactly as on the AMQP 0-9-1 arm; a text body reaches the handler unchanged; a JMS listener and an AMQP listener coexist in one registry

### `jms: a jms listener registers on the shared registry tagged jms`

```bp
test "jms: a jms listener registers on the shared registry tagged jms" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery, Outcome} from "rakun-messaging";
        \\ import {jmsListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ type ShippingListener {
        \\     #[jmsListener("shipping.requests")]
        \\     pub fn onShipment(self: Self, delivery: Delivery) -> Outcome {
        \\         return Outcome.Done;
        \\     }
        \\ }
        , ["shipping.requests order-id: A-1 | ship:A-1"]);
}
```

`modules/rakun-messaging/test/__snapshots__/jms/a-jms-listener-registers-on-the-shared-registry-tagged-jms.snap`
```
listener shipping.requests -> ShippingListener.onShipment broker=jms

deliver shipping.requests ship:A-1 -> ok
```

### `jms: a missing order id is rejected and an empty body is retried`

```bp
test "jms: a missing order id is rejected and an empty body is retried" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery, Outcome} from "rakun-messaging";
        \\ import {jmsListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ type ShippingListener {
        \\     #[jmsListener("shipping.requests")]
        \\     pub fn onShipment(self: Self, delivery: Delivery) -> Outcome {
        \\         val order = delivery.header("order-id");
        \\         if (order == "") {
        \\             return Outcome.Reject(reason: "missing order-id header");
        \\         };
        \\         val body = delivery.body;
        \\         if (body == "") {
        \\             return Outcome.Retry(reason: "empty body, upstream may still be writing");
        \\         };
        \\         return Outcome.Done;
        \\     }
        \\ }
        , ["shipping.requests | ship:A-1", "shipping.requests order-id: A-1 | ", "shipping.requests order-id: A-1 | ship:A-1"]);
}
```

`modules/rakun-messaging/test/__snapshots__/jms/a-missing-order-id-is-rejected-and-an-empty-body-is-retried.snap`
```
listener shipping.requests -> ShippingListener.onShipment broker=jms

deliver shipping.requests ship:A-1 -> dead-letter
deliver shipping.requests  -> nack
deliver shipping.requests ship:A-1 -> ok
```

### `jms: the jms arm and the amqp arm share one registry`

```bp
test "jms: the jms arm and the amqp arm share one registry" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery, Outcome} from "rakun-messaging";
        \\ import {jmsListener, rabbitListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ type ShippingListener {
        \\     #[jmsListener("shipping.requests")]
        \\     pub fn onShipment(self: Self, delivery: Delivery) -> Outcome {
        \\         return Outcome.Done;
        \\     }
        \\
        \\     #[rabbitListener("orders.confirm")]
        \\     pub fn onOrder(self: Self, delivery: Delivery) -> Outcome {
        \\         return Outcome.Done;
        \\     }
        \\ }
        , ["orders.confirm | {}", "shipping.requests | ship:A-1"]);
}
```

`modules/rakun-messaging/test/__snapshots__/jms/the-jms-arm-and-the-amqp-arm-share-one-registry.snap`
```
listener orders.confirm -> ShippingListener.onOrder broker=amqp
listener shipping.requests -> ShippingListener.onShipment broker=jms

deliver orders.confirm {} -> ok
deliver shipping.requests ship:A-1 -> ok
```

### `jms: a retry at the attempt ceiling dead-letters through front 86`

```bp
test "jms: a retry at the attempt ceiling dead-letters through front 86" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery, Outcome} from "rakun-messaging";
        \\ import {jmsListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ type ShippingListener {
        \\     #[jmsListener("shipping.requests")]
        \\     pub fn onShipment(self: Self, delivery: Delivery) -> Outcome {
        \\         return Outcome.Retry(reason: "carrier api unavailable");
        \\     }
        \\ }
        , ["shipping.requests | ship:A-1", "shipping.requests x-rakun-attempt: 2 | ship:A-1", "shipping.requests x-rakun-attempt: 3 | ship:A-1"]);
}
```

`modules/rakun-messaging/test/__snapshots__/jms/a-retry-at-the-attempt-ceiling-dead-letters-through-front-86.snap`
```
listener shipping.requests -> ShippingListener.onShipment broker=jms

deliver shipping.requests ship:A-1 -> nack
deliver shipping.requests ship:A-1 -> nack
deliver shipping.requests ship:A-1 -> dead-letter
```

> Runs under `rakun.messaging.listener.shipping.retry.max-attempts=3` in the test file's module configuration (listener name per README § Examples, `rakun.messaging.listener.shipping.*`).

### `jms: a text body reaches the handler byte for byte`

```bp
test "jms: a text body reaches the handler byte for byte" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery, Outcome} from "rakun-messaging";
        \\ import {jmsListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ type AuditListener {
        \\     #[jmsListener("audit.events")]
        \\     pub fn onEvent(self: Self, delivery: Delivery) -> Outcome {
        \\         val expected = delivery.body == "{\"event\":\"shipped\",\"id\":\"A-1\"}";
        \\         if (expected) {
        \\             return Outcome.Done;
        \\         };
        \\         return Outcome.Reject(reason: "body altered in transit");
        \\     }
        \\ }
        , ["audit.events | {\"event\":\"shipped\",\"id\":\"A-1\"}", "audit.events | {\"event\":\"shipped\"}"]);
}
```

`modules/rakun-messaging/test/__snapshots__/jms/a-text-body-reaches-the-handler-byte-for-byte.snap`
```
listener audit.events -> AuditListener.onEvent broker=jms

deliver audit.events {"event":"shipped","id":"A-1"} -> ok
deliver audit.events {"event":"shipped"} -> dead-letter
```

## 91-rakun-pulsar — `rakun-pulsar`

**Test file:** `modules/rakun-pulsar/test/pulsar_test.bp` · **Snapshots:** `modules/rakun-pulsar/test/__snapshots__/pulsar/` · **Target:** erlang · **Pins:** `#[pulsarListener]` registers on front 15's registry tagged `pulsar` with the same `Outcome` contract; `Outcome.Done` acks, `Outcome.Retry` negatively acknowledges, `Outcome.Reject` dead-letters through front 86 — three paths; `#[pulsarReader]` registers as a reader, acknowledges nothing and never dead-letters; a bare topic name is rendered fully qualified; a `non-persistent` topic is not promoted

> `ack <mode>` renders the registration's acknowledgement mode once, after the listener table: `auto` for a `#[pulsarListener]` (front 86's default `AckMode`), `none` for a `#[pulsarReader]`. The `listener` line carries `renderTopic(parseTopic(<arg>))`. Script strings are `"<topic>[ <header>: <v>]* | <payload>"`.

### `pulsar: a listener registers on the shared registry with the fully qualified topic`

```bp
test "pulsar: a listener registers on the shared registry with the fully qualified topic" {
    try assertPulsar(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery, Outcome} from "rakun-messaging";
        \\ import {pulsarListener} from "rakun-pulsar";
        \\
        \\ #[service]
        \\ type InvoiceListener {
        \\     #[pulsarListener("persistent://acme/billing/invoices")]
        \\     pub fn onInvoice(self: Self, delivery: Delivery) -> Outcome {
        \\         return Outcome.Done;
        \\     }
        \\ }
        , ["persistent://acme/billing/invoices tenant: acme | invoice:1"]);
}
```

`modules/rakun-pulsar/test/__snapshots__/pulsar/a-listener-registers-on-the-shared-registry-with-the-fully-qualified-topic.snap`
```
listener persistent://acme/billing/invoices -> InvoiceListener.onInvoice broker=pulsar
ack auto

deliver persistent://acme/billing/invoices invoice:1 -> ok
```

### `pulsar: done acks retry nacks and reject dead-letters`

```bp
test "pulsar: done acks retry nacks and reject dead-letters" {
    try assertPulsar(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery, Outcome} from "rakun-messaging";
        \\ import {pulsarListener} from "rakun-pulsar";
        \\
        \\ #[service]
        \\ type InvoiceListener {
        \\     #[pulsarListener("persistent://acme/billing/invoices")]
        \\     pub fn onInvoice(self: Self, delivery: Delivery) -> Outcome {
        \\         val tenant = delivery.header("tenant");
        \\         if (tenant == "") {
        \\             return Outcome.Reject(reason: "message published outside a tenant");
        \\         };
        \\         val body = delivery.body;
        \\         if (body == "") {
        \\             return Outcome.Retry(reason: "empty payload");
        \\         };
        \\         return Outcome.Done;
        \\     }
        \\ }
        , [
            "persistent://acme/billing/invoices tenant: acme | invoice:1",
            "persistent://acme/billing/invoices tenant: acme | ",
            "persistent://acme/billing/invoices | invoice:3",
        ]);
}
```

`modules/rakun-pulsar/test/__snapshots__/pulsar/done-acks-retry-nacks-and-reject-dead-letters.snap`
```
listener persistent://acme/billing/invoices -> InvoiceListener.onInvoice broker=pulsar
ack auto

deliver persistent://acme/billing/invoices invoice:1 -> ok
deliver persistent://acme/billing/invoices  -> nack
deliver persistent://acme/billing/invoices invoice:3 -> dead-letter
```

### `pulsar: a bare topic is rendered under the persistent public default parts`

```bp
test "pulsar: a bare topic is rendered under the persistent public default parts" {
    try assertPulsar(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery, Outcome} from "rakun-messaging";
        \\ import {pulsarListener} from "rakun-pulsar";
        \\
        \\ #[service]
        \\ type OrderListener {
        \\     #[pulsarListener("orders")]
        \\     pub fn onOrder(self: Self, delivery: Delivery) -> Outcome {
        \\         return Outcome.Done;
        \\     }
        \\ }
        , ["orders | order:1"]);
}
```

`modules/rakun-pulsar/test/__snapshots__/pulsar/a-bare-topic-is-rendered-under-the-persistent-public-default-parts.snap`
```
listener persistent://public/default/orders -> OrderListener.onOrder broker=pulsar
ack auto

deliver persistent://public/default/orders order:1 -> ok
```

### `pulsar: a non-persistent topic is not promoted`

```bp
test "pulsar: a non-persistent topic is not promoted" {
    try assertPulsar(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery, Outcome} from "rakun-messaging";
        \\ import {pulsarListener} from "rakun-pulsar";
        \\
        \\ #[service]
        \\ type PresenceListener {
        \\     #[pulsarListener("non-persistent://acme/chat/presence")]
        \\     pub fn onPresence(self: Self, delivery: Delivery) -> Outcome {
        \\         return Outcome.Done;
        \\     }
        \\ }
        , []);
}
```

`modules/rakun-pulsar/test/__snapshots__/pulsar/a-non-persistent-topic-is-not-promoted.snap`
```
listener non-persistent://acme/chat/presence -> PresenceListener.onPresence broker=pulsar
ack auto
```

### `pulsar: a reader acknowledges nothing and never dead-letters`

```bp
test "pulsar: a reader acknowledges nothing and never dead-letters" {
    try assertPulsar(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery} from "rakun-messaging";
        \\ import {pulsarReader} from "rakun-pulsar";
        \\
        \\ #[service]
        \\ type InvoiceBacklog {
        \\     #[pulsarReader("persistent://acme/billing/invoices", "earliest")]
        \\     pub fn replay(self: Self, delivery: Delivery) -> i32 {
        \\         val empty = delivery.body == "";
        \\         if (empty) {
        \\             throw "nothing to replay";
        \\         };
        \\         return 0;
        \\     }
        \\ }
        , ["persistent://acme/billing/invoices | invoice:1", "persistent://acme/billing/invoices | "]);
}
```

`modules/rakun-pulsar/test/__snapshots__/pulsar/a-reader-acknowledges-nothing-and-never-dead-letters.snap`
```
listener persistent://acme/billing/invoices -> InvoiceBacklog.replay broker=pulsar
ack none

deliver persistent://acme/billing/invoices invoice:1 -> ok
deliver persistent://acme/billing/invoices  -> ok
```

## 92-rakun-rsocket — `rakun-rsocket`

**Test file:** `modules/rakun-rsocket/test/rsocket_test.bp` · **Snapshots:** `modules/rakun-rsocket/test/__snapshots__/rsocket/` · **Target:** erlang · **Pins:** `#[messageMapping]` registers each route with its interaction model derived from the signature (`Outcome` → fnf, value → rr, `StreamHandle` → rs, `StreamHandle` in and out → channel); request/response returns exactly one `PAYLOAD`; request/stream emits no more than the credit granted and resumes on `REQUEST_N`; `CANCEL` stops the producer; a request with no routing metadata is answered with an `ERROR` naming the missing route; a handler error is an `ERROR` on that stream only; `RESUME` in `SETUP` is rejected as unsupported; credit is per stream

> helper gap: the `assertRSocket` row leaves "frame exchange lines" open; rendered here as `> <FRAME> <stream>[ <route>][ <data>][ n=<credit>]` (requester → responder) and `< <FRAME> <stream> <data>` (responder → requester). Frame strings share the `>` grammar without the arrow; a stream item is the handle's `source` plus `#<n>`.

### `rsocket: four mappings register four models`

```bp
test "rsocket: four mappings register four models" {
    try assertRSocket(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Outcome} from "rakun-messaging";
        \\ import {messageMapping, StreamHandle} from "rakun-rsocket";
        \\
        \\ #[service]
        \\ type UserEndpoint {
        \\     #[messageMapping("user.seen")]
        \\     pub fn seen(self: Self, name: string) -> Outcome {
        \\         return Outcome.Done;
        \\     }
        \\
        \\     #[messageMapping("user.byId")]
        \\     pub fn byId(self: Self, id: string) -> string {
        \\         return "user:" + id;
        \\     }
        \\
        \\     #[messageMapping("user.events")]
        \\     pub fn events(self: Self, id: string) -> StreamHandle {
        \\         return StreamHandle(source: "events:" + id, credit: 0);
        \\     }
        \\
        \\     #[messageMapping("user.sync")]
        \\     pub fn sync(self: Self, incoming: StreamHandle) -> StreamHandle {
        \\         return StreamHandle(source: "sync:" + incoming.source, credit: 0);
        \\     }
        \\ }
        , []);
}
```

`modules/rakun-rsocket/test/__snapshots__/rsocket/four-mappings-register-four-models.snap`
```
route user.byId model=rr
route user.events model=rs
route user.seen model=fnf
route user.sync model=channel
```

### `rsocket: request response returns exactly one payload`

```bp
test "rsocket: request response returns exactly one payload" {
    try assertRSocket(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {messageMapping} from "rakun-rsocket";
        \\
        \\ #[service]
        \\ type UserEndpoint {
        \\     #[messageMapping("user.byId")]
        \\     pub fn byId(self: Self, id: string) -> string {
        \\         return "user:" + id;
        \\     }
        \\ }
        , ["REQUEST_RESPONSE 1 user.byId 17", "REQUEST_RESPONSE 3 user.byId 42"]);
}
```

`modules/rakun-rsocket/test/__snapshots__/rsocket/request-response-returns-exactly-one-payload.snap`
```
route user.byId model=rr

> REQUEST_RESPONSE 1 user.byId 17
< PAYLOAD 1 user:17
> REQUEST_RESPONSE 3 user.byId 42
< PAYLOAD 3 user:42
```

### `rsocket: a stream emits only the credit granted and resumes on request n`

```bp
test "rsocket: a stream emits only the credit granted and resumes on request n" {
    try assertRSocket(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {messageMapping, StreamHandle} from "rakun-rsocket";
        \\
        \\ #[service]
        \\ type UserEndpoint {
        \\     #[messageMapping("user.events")]
        \\     pub fn events(self: Self, id: string) -> StreamHandle {
        \\         return StreamHandle(source: "events:" + id, credit: 0);
        \\     }
        \\ }
        , ["REQUEST_STREAM 3 user.events 1 n=2", "REQUEST_N 3 n=1", "CANCEL 3", "REQUEST_N 3 n=5"]);
}
```

`modules/rakun-rsocket/test/__snapshots__/rsocket/a-stream-emits-only-the-credit-granted-and-resumes-on-request-n.snap`
```
route user.events model=rs

> REQUEST_STREAM 3 user.events 1 n=2
< PAYLOAD 3 events:1#1
< PAYLOAD 3 events:1#2
> REQUEST_N 3 n=1
< PAYLOAD 3 events:1#3
> CANCEL 3
> REQUEST_N 3 n=5
```

### `rsocket: fire and forget sends nothing back`

```bp
test "rsocket: fire and forget sends nothing back" {
    try assertRSocket(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Outcome} from "rakun-messaging";
        \\ import {messageMapping} from "rakun-rsocket";
        \\
        \\ #[service]
        \\ type UserEndpoint {
        \\     #[messageMapping("user.seen")]
        \\     pub fn seen(self: Self, name: string) -> Outcome {
        \\         if (name == "") {
        \\             return Outcome.Reject(reason: "empty principal");
        \\         };
        \\         return Outcome.Done;
        \\     }
        \\ }
        , ["REQUEST_FNF 5 user.seen ana", "REQUEST_FNF 7 user.seen"]);
}
```

`modules/rakun-rsocket/test/__snapshots__/rsocket/fire-and-forget-sends-nothing-back.snap`
```
route user.seen model=fnf

> REQUEST_FNF 5 user.seen ana
> REQUEST_FNF 7 user.seen
```

### `rsocket: a request with no routing metadata is an error on its stream only`

```bp
test "rsocket: a request with no routing metadata is an error on its stream only" {
    try assertRSocket(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {messageMapping} from "rakun-rsocket";
        \\
        \\ #[service]
        \\ type UserEndpoint {
        \\     #[messageMapping("user.byId")]
        \\     pub fn byId(self: Self, id: string) -> string {
        \\         val missing = id == "";
        \\         if (missing) {
        \\             throw "empty id";
        \\         };
        \\         return "user:" + id;
        \\     }
        \\ }
        , ["REQUEST_RESPONSE 1 - 17", "REQUEST_RESPONSE 3 user.byId", "REQUEST_RESPONSE 5 user.byId 17"]);
}
```

`modules/rakun-rsocket/test/__snapshots__/rsocket/a-request-with-no-routing-metadata-is-an-error-on-its-stream-only.snap`
```
route user.byId model=rr

> REQUEST_RESPONSE 1 17
< ERROR 1 missing route
> REQUEST_RESPONSE 3 user.byId
< ERROR 3 empty id
> REQUEST_RESPONSE 5 user.byId 17
< PAYLOAD 5 user:17
```

### `rsocket: resume in setup is rejected as unsupported`

```bp
test "rsocket: resume in setup is rejected as unsupported" {
    try assertRSocket(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {messageMapping} from "rakun-rsocket";
        \\
        \\ #[service]
        \\ type UserEndpoint {
        \\     #[messageMapping("user.byId")]
        \\     pub fn byId(self: Self, id: string) -> string {
        \\         return "user:" + id;
        \\     }
        \\ }
        , ["SETUP 0 resume"]);
}
```

`modules/rakun-rsocket/test/__snapshots__/rsocket/resume-in-setup-is-rejected-as-unsupported.snap`
```
route user.byId model=rr

> SETUP 0 resume
< ERROR 0 resumption unsupported
```

## 93-rakun-soap-webservices — `rakun-soap`

**Test file:** `modules/rakun-soap/test/soap_test.bp` · **Snapshots:** `modules/rakun-soap/test/__snapshots__/soap/` · **Target:** erlang · **Pins:** a 1.1 envelope carries `http://schemas.xmlsoap.org/soap/envelope/` and a 1.2 envelope `http://www.w3.org/2003/05/soap-envelope`, never the other; a 200 with a normal body is `Ok`; a 500 with a `soap:Fault` body is `Error` carrying the decoded fault; a 500 with a non-XML body is a transport fault, distinguishably; a timeout is a transport error and never a fault; both fault shapes decode into one `SoapFault` record; `detail` preserves the raw element

> helper gap: `assertSoap` renders no request headers, so the `SOAPAction` header (1.1) versus `Content-Type` `action` parameter (1.2) split of step 4 is not pinnable here.
> The 1.0.9 README names the module `rakun-ws`; 1.0.10 renames it `rakun-soap`. `call` is `"<action> <bodyXml> | <status> <responseBody>"` — the stub answers with the given SOAP Body content, or `| timeout` for a connection that never answers. The second line is `<status> body <text>` or `<status> fault code=<c> reason=<r> actor=<a> detail=<d>` (transport faults carry `code=Transport`, name per README § Step 4; a timeout renders status `0`).

### `soap: a 1.1 call sends the 1.1 envelope and returns the body`

```bp
test "soap: a 1.1 call sends the 1.1 envelope and returns the body" {
    try assertSoap(@src(),
        \\ import {WsClient} from "rakun-soap";
        \\
        \\ val client = WsClient(endpoint: "https://rates.example.com/soap", version: "1.1", timeoutMs: 5000);
        , "urn:rates/Convert <Convert xmlns=\"urn:rates\"><From>EUR</From><To>BRL</To><Amount>100.00</Amount></Convert> | 200 <ConvertResponse xmlns=\"urn:rates\"><Rate>6.21</Rate><Converted>621.00</Converted></ConvertResponse>");
}
```

`modules/rakun-soap/test/__snapshots__/soap/a-1-1-call-sends-the-1-1-envelope-and-returns-the-body.snap`
```
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><Convert xmlns="urn:rates"><From>EUR</From><To>BRL</To><Amount>100.00</Amount></Convert></soap:Body></soap:Envelope>
200 body <ConvertResponse xmlns="urn:rates"><Rate>6.21</Rate><Converted>621.00</Converted></ConvertResponse>
```

### `soap: a 1.2 call sends the 1.2 envelope and returns the body`

```bp
test "soap: a 1.2 call sends the 1.2 envelope and returns the body" {
    try assertSoap(@src(),
        \\ import {WsClient} from "rakun-soap";
        \\
        \\ val client = WsClient(endpoint: "https://rates.example.com/soap", version: "1.2", timeoutMs: 5000);
        , "urn:rates/Convert <Convert xmlns=\"urn:rates\"><From>EUR</From><To>BRL</To><Amount>100.00</Amount></Convert> | 200 <ConvertResponse xmlns=\"urn:rates\"><Rate>6.21</Rate><Converted>621.00</Converted></ConvertResponse>");
}
```

`modules/rakun-soap/test/__snapshots__/soap/a-1-2-call-sends-the-1-2-envelope-and-returns-the-body.snap`
```
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body><Convert xmlns="urn:rates"><From>EUR</From><To>BRL</To><Amount>100.00</Amount></Convert></soap:Body></soap:Envelope>
200 body <ConvertResponse xmlns="urn:rates"><Rate>6.21</Rate><Converted>621.00</Converted></ConvertResponse>
```

### `soap: a 500 with a 1.1 fault body is a decoded fault`

```bp
test "soap: a 500 with a 1.1 fault body is a decoded fault" {
    try assertSoap(@src(),
        \\ import {WsClient} from "rakun-soap";
        \\
        \\ val client = WsClient(endpoint: "https://rates.example.com/soap", version: "1.1", timeoutMs: 5000);
        , "urn:rates/Convert <Convert xmlns=\"urn:rates\"><From>EUR</From><To>XXX</To><Amount>1</Amount></Convert> | 500 <soap:Fault><faultcode>soap:Client</faultcode><faultstring>unknown currency</faultstring><faultactor>rates</faultactor><detail><Code>E42</Code></detail></soap:Fault>");
}
```

`modules/rakun-soap/test/__snapshots__/soap/a-500-with-a-1-1-fault-body-is-a-decoded-fault.snap`
```
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><Convert xmlns="urn:rates"><From>EUR</From><To>XXX</To><Amount>1</Amount></Convert></soap:Body></soap:Envelope>
500 fault code=soap:Client reason=unknown currency actor=rates detail=<Code>E42</Code>
```

### `soap: a 1.2 fault decodes into the same record`

```bp
test "soap: a 1.2 fault decodes into the same record" {
    try assertSoap(@src(),
        \\ import {WsClient} from "rakun-soap";
        \\
        \\ val client = WsClient(endpoint: "https://rates.example.com/soap", version: "1.2", timeoutMs: 5000);
        , "urn:rates/Convert <Convert xmlns=\"urn:rates\"><From>EUR</From><To>XXX</To><Amount>1</Amount></Convert> | 500 <env:Fault><env:Code><env:Value>env:Sender</env:Value></env:Code><env:Reason><env:Text>unknown currency</env:Text></env:Reason><env:Role>rates</env:Role><env:Detail><Code>E42</Code></env:Detail></env:Fault>");
}
```

`modules/rakun-soap/test/__snapshots__/soap/a-1-2-fault-decodes-into-the-same-record.snap`
```
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body><Convert xmlns="urn:rates"><From>EUR</From><To>XXX</To><Amount>1</Amount></Convert></soap:Body></soap:Envelope>
500 fault code=env:Sender reason=unknown currency actor=rates detail=<Code>E42</Code>
```

### `soap: a 500 with a non-xml body is a transport fault not a soap fault`

```bp
test "soap: a 500 with a non-xml body is a transport fault not a soap fault" {
    try assertSoap(@src(),
        \\ import {WsClient} from "rakun-soap";
        \\
        \\ val client = WsClient(endpoint: "https://rates.example.com/soap", version: "1.1", timeoutMs: 5000);
        , "urn:rates/Convert <Convert xmlns=\"urn:rates\"><From>EUR</From><To>BRL</To><Amount>1</Amount></Convert> | 500 Internal Server Error");
}
```

`modules/rakun-soap/test/__snapshots__/soap/a-500-with-a-non-xml-body-is-a-transport-fault-not-a-soap-fault.snap`
```
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><Convert xmlns="urn:rates"><From>EUR</From><To>BRL</To><Amount>1</Amount></Convert></soap:Body></soap:Envelope>
500 fault code=Transport reason=non-xml body actor= detail=Internal Server Error
```

### `soap: a connection timeout is a transport error and never a fault`

```bp
test "soap: a connection timeout is a transport error and never a fault" {
    try assertSoap(@src(),
        \\ import {WsClient} from "rakun-soap";
        \\
        \\ val client = WsClient(endpoint: "https://rates.example.com/soap", version: "1.1", timeoutMs: 5000);
        , "urn:rates/Convert <Convert xmlns=\"urn:rates\"><From>EUR</From><To>BRL</To><Amount>1</Amount></Convert> | timeout");
}
```

`modules/rakun-soap/test/__snapshots__/soap/a-connection-timeout-is-a-transport-error-and-never-a-fault.snap`
```
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><Convert xmlns="urn:rates"><From>EUR</From><To>BRL</To><Amount>1</Amount></Convert></soap:Body></soap:Envelope>
0 fault code=Transport reason=timeout after 5000ms actor= detail=
```

