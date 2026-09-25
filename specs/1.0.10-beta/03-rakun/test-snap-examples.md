# rakun — snapshot-test map of the example projects

**Track:** B — rakun · **Repo:** `repository/rakun/examples/` · **Contract:** [`test-snap.md § The contract`](./test-snap.md#the-contract) (same helpers, same `.snap` rules, same `.bp` rules) · **Cut:** [`modules.md § Examples`](./modules.md#examples-repositoryrakunexamples)

An example project is an application, not a module: its tests boot `main.bp`'s `App` and drive the
whole thing through the same `rakun-test` helpers the modules use, so a project's snapshots pin
that the fronts it exercises compose — not that each works alone. Every front in a project's
`Fronts` line is pinned by at least one case here; the module-level cases in
[`test-snap.md`](./test-snap.md) pin the front's own acceptance criteria.

| Project | Fronts | Depends on | Suite |
|---|---|---|---|
| `examples/rakun` | 04 · 05 · 06 | `rakun` | `rakun` |
| `examples/rest-service` | 05 · 06 · 07 · 08 · 11 · 14 · 17 · 19 · 72 · 77 · 78 | `rakun-starter-web`, `rakun-starter-data-sql`, `rakun-starter-actuator`, `rakun-starter-test` | `rest-service` |
| `examples/secured-api` | 10 · 18 · 74 · 76 · 79 · 87 | `rakun-security`, `rakun-session`, `rakun-actuator`, `rakun-web` | `secured-api` |
| `examples/blog-server` | 12 · 22 · 23 · 24 · 25 · 60 · 61 · 62 · 63 · 64 · 65 · 66 · 82 | `rakun-app`, `rakun-web`, `rakun-cache` | `blog-server` |
| `examples/order-pipeline` | 15 · 16 · 83 · 84 · 85 · 86 · 89 · 90 | `rakun-messaging`, `rakun-tx`, `rakun-stream`, `rakun-scheduling`, `rakun-mail`, `rakun-data` | `order-pipeline` |
| `examples/observed-service` | 11 · 12 · 13 · 17 · 21 · 75 · 76 · 87 | `rakun-actuator`, `rakun-metrics`, `rakun-logging`, `rakun-cache`, `rakun-client`, `rakun-hateoas` | `observed-service` |
| `examples/realtime-gateway` | 09 · 20 · 91 · 92 · 93 | `rakun-websocket`, `rakun-rsocket`, `rakun-pulsar`, `rakun-soap`, `rakun-data` | `realtime-gateway` |
| `examples/release-kit` | 72 · 73 · 80 · 81 · 88 | `starters/*`, `rakun-devtools`, `rakun-release`, `rakun-cli` | `release-kit` |

Rules specific to example projects:

- One suite per project, named after the directory; tests live in `examples/<name>/test/<name>_test.bp`
  and snapshots in `examples/<name>/test/__snapshots__/<name>/`.
- A project's `botopink.json` depends on starters or modules, never on `repository/rakun/src/`
  directly; `rakun-test` is its test-scope dependency.
- `examples/rakun` is the existing project; its tests are added, its sources are not rewritten
  (*additive only*). It declares `"targets": ["erlang"]` with front 04 (decision 113), and its
  snapshots are the first check that the BEAM runtime answers as the node one did.
- `examples/blog-server` is the erlang half of `repository/onze/examples/blog`; the browser half and
  the hydration round trip are onze's ([`../06-onze/`](../06-onze/)), not this project's.
- Every helper installs the test clock `2026-01-01T00:00:00Z` and seed ids (`req-0001`, `sess-0001`,
  `trace-0001`), so a project snapshot never carries a wall-clock or a random value.

## `examples/rakun`

**Fronts:** 04 · 05 · 06 · **Depends on:** `rakun` · **Tests:** `examples/rakun/test/rakun_test.bp` · **Snapshots:** `examples/rakun/test/__snapshots__/rakun/` · **Target:** erlang

```
examples/rakun/
├── botopink.json          name rakun-app · target erlang · dependencies: rakun
├── application.yaml       server.port 8080 · app.timezone UTC · rakun.profiles.active dev
├── application-prod.yaml  server.port 8443 · app.timezone Europe/Lisbon
├── src/main.bp            pub mod users · pub mod posts · pub mod config · fn main: rkConfigLoad() then Rakun.run(App(port: rkPropInt("server.port"), basePath: "/api"))
├── src/users.bp           UserRepository (#[repository]) · UserService (#[service]) · UserController (#[restController] #[route("/api/users")]: GET / · GET /:name)
├── src/posts.bp           PostRepository · PostService · PostController (#[route("/api/posts")]: GET / · POST / · DELETE /:id)
└── src/config.bp          Clock · AppConfig (#[configuration] · #[value("app.timezone")] · #[bean] clock) · TimeService (#[service], Clock injected by type)
```

### `rakun: boot listens on 8080 with nine beans and five routes`

```bp
test "rakun: boot listens on 8080 with nine beans and five routes" {
    try assertBoot(@src(),
        \\ import {Rakun, App} from "rakun";
        \\ import {rkConfigLoad, rkPropInt} from "rakun";
        \\ import {UserController, UserService, UserRepository} from "users";
        \\ import {PostController, PostService, PostRepository} from "posts";
        \\ import {TimeService, Clock, AppConfig} from "config";
        \\
        \\ pub mod users;
        \\ pub mod posts;
        \\ pub mod config;
        \\
        \\ fn main() {
        \\     val _cfg = rkConfigLoad();
        \\     Rakun.run(App(port: rkPropInt("server.port"), basePath: "/api"));
        \\ }
        , []);
}
```

`examples/rakun/test/__snapshots__/rakun/boot-listens-on-8080-with-nine-beans-and-five-routes.snap`
```
listen 0.0.0.0:8080
beans 9
routes 5
exit 0
```

### `rakun: a command-line port beats application.yaml at boot`

```bp
test "rakun: a command-line port beats application.yaml at boot" {
    try assertBoot(@src(),
        \\ import {Rakun, App} from "rakun";
        \\ import {rkConfigLoad, rkPropInt} from "rakun";
        \\ import {UserController, UserService, UserRepository} from "users";
        \\ import {PostController, PostService, PostRepository} from "posts";
        \\ import {TimeService, Clock, AppConfig} from "config";
        \\
        \\ pub mod users;
        \\ pub mod posts;
        \\ pub mod config;
        \\
        \\ fn main() {
        \\     val _cfg = rkConfigLoad();
        \\     Rakun.run(App(port: rkPropInt("server.port"), basePath: "/api"));
        \\ }
        , ["--server.port=9090"]);
}
```

`examples/rakun/test/__snapshots__/rakun/a-command-line-port-beats-application-yaml-at-boot.snap`
```
listen 0.0.0.0:9090
beans 9
routes 5
exit 0
```

### `rakun: users routes dispatch through the repository service controller chain`

```bp
test "rakun: users routes dispatch through the repository service controller chain" {
    try assertRoute(@src(),
        \\ import {repository, service, restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\
        \\ #[repository]
        \\ pub type UserRepository {
        \\     pub fn all(self: Self) -> Array<string> {
        \\         return ["ana", "bob", "cleo"];
        \\     }
        \\
        \\     pub fn has(self: Self, name: string) -> bool {
        \\         return self.all().indexOf(name) != -1;
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type UserService(
        \\     repo: UserRepository,
        \\ ) {
        \\     pub fn list(self: Self) -> Array<string> {
        \\         return self.repo.all();
        \\     }
        \\
        \\     pub fn greet(self: Self, name: string) -> string {
        \\         return if (self.repo.has(name)) "Hello, " + name + "!" else "unknown user: " + name;
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/users")]
        \\ pub type UserController(
        \\     service: UserService,
        \\ ) {
        \\     #[getMapping("/")]
        \\     pub fn index(self: Self, req: Request) -> Response {
        \\         return Response.json(self.service.list().join(", "));
        \\     }
        \\
        \\     #[getMapping("/:name")]
        \\     pub fn show(self: Self, req: Request) -> Response {
        \\         return Response.ok(self.service.greet(req.param("name")));
        \\     }
        \\ }
        , ["GET /api/users/", "GET /api/users/ana", "GET /api/users/zed", "GET /api/nope"]);
}
```

`examples/rakun/test/__snapshots__/rakun/users-routes-dispatch-through-the-repository-service-controller-chain.snap`
```
GET /api/users/ -> UserController.index
GET /api/users/:name -> UserController.show

GET /api/users/ -> 200 ana, bob, cleo
GET /api/users/ana -> 200 Hello, ana!
GET /api/users/zed -> 200 unknown user: zed
GET /api/nope -> 404
```

### `rakun: posts write endpoints answer 201, 400 and 204`

```bp
test "rakun: posts write endpoints answer 201, 400 and 204" {
    try assertRoute(@src(),
        \\ import {repository, service, restController, route, getMapping, postMapping, deleteMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\
        \\ #[repository]
        \\ pub type PostRepository {
        \\     pub fn all(self: Self) -> Array<string> {
        \\         return ["hello world", "rakun rocks"];
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type PostService(
        \\     repo: PostRepository,
        \\ ) {
        \\     pub fn list(self: Self) -> Array<string> {
        \\         return self.repo.all();
        \\     }
        \\
        \\     pub fn isValid(self: Self, title: string) -> bool {
        \\         return title != "";
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/posts")]
        \\ pub type PostController(
        \\     service: PostService,
        \\ ) {
        \\     #[getMapping("/")]
        \\     pub fn index(self: Self, req: Request) -> Response {
        \\         return Response.json(self.service.list().join(" | "));
        \\     }
        \\
        \\     #[postMapping("/")]
        \\     pub fn create(self: Self, req: Request) -> Response {
        \\         val title = req.body();
        \\         return if (self.service.isValid(title)) Response.created("created: " + title) else Response.badRequest("title must not be empty");
        \\     }
        \\
        \\     #[deleteMapping("/:id")]
        \\     pub fn remove(self: Self, req: Request) -> Response {
        \\         return Response.withStatus(204, "deleted " + req.param("id"));
        \\     }
        \\ }
        , ["GET /api/posts/", "POST /api/posts/ | hi", "POST /api/posts/ | ", "DELETE /api/posts/42"]);
}
```

`examples/rakun/test/__snapshots__/rakun/posts-write-endpoints-answer-201-400-and-204.snap`
```
GET /api/posts/ -> PostController.index
POST /api/posts/ -> PostController.create
DELETE /api/posts/:id -> PostController.remove

GET /api/posts/ -> 200 hello world | rakun rocks
POST /api/posts/ -> 201 created: hi
POST /api/posts/ -> 400 title must not be empty
DELETE /api/posts/42 -> 204 deleted 42
```

### `rakun: the bean factory and the value field wire the time service`

```bp
test "rakun: the bean factory and the value field wire the time service" {
    try assertContext(@src(),
        \\ import {configuration, bean, value, service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt} from "rakun";
        \\
        \\ pub type Clock(
        \\     zone: string,
        \\ ) {
        \\     pub fn now(self: Self) -> string {
        \\         return "<now@" + self.zone + ">";
        \\     }
        \\ }
        \\
        \\ #[configuration]
        \\ pub type AppConfig(
        \\     #[value("app.timezone")] timezone: string,
        \\ ) {
        \\     #[bean]
        \\     pub fn clock(self: Self) -> Clock {
        \\         return Clock(zone: self.timezone);
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type TimeService(
        \\     clock: Clock,
        \\ ) {
        \\     pub fn stamp(self: Self, label: string) -> string {
        \\         return label + ": " + self.clock.now();
        \\     }
        \\ }
        , ["TimeService", "Clock", "AppConfig", "Scheduler"]);
}
```

`examples/rakun/test/__snapshots__/rakun/the-bean-factory-and-the-value-field-wire-the-time-service.snap`
```
bean AppConfig scope=singleton deps=[]
bean Clock scope=singleton deps=[AppConfig]
bean TimeService scope=singleton deps=[Clock]
resolve TimeService -> ok
resolve Clock -> ok
resolve AppConfig -> ok
resolve Scheduler -> missing
```

### `rakun: application.yaml binds the port, the timezone and the active profile`

```bp
test "rakun: application.yaml binds the port, the timezone and the active profile" {
    try assertConfig(@src(),
        ["application.yaml"],
        ["server.port", "app.timezone", "rakun.profiles.active", "app.locale"]);
}
```

`examples/rakun/test/__snapshots__/rakun/application-yaml-binds-the-port-the-timezone-and-the-active-profile.snap`
```
server.port = 8080  (application.yaml)
app.timezone = UTC  (application.yaml)
rakun.profiles.active = dev  (application.yaml)
app.locale = <unset>
```

### `rakun: the prod profile document and an environment variable override the base document`

```bp
test "rakun: the prod profile document and an environment variable override the base document" {
    try assertConfig(@src(),
        [
            "application.yaml",
            "application-prod.yaml",
            "RAKUN_PROFILES_ACTIVE=prod",
            "RAKUN_APP_TIMEZONE=America/Sao_Paulo",
        ],
        ["server.port", "app.timezone", "rakun.profiles.active"]);
}
```

`examples/rakun/test/__snapshots__/rakun/the-prod-profile-document-and-an-environment-variable-override-the-base-document.snap`
```
server.port = 8443  (application-prod.yaml)
app.timezone = America/Sao_Paulo  (RAKUN_APP_TIMEZONE)
rakun.profiles.active = prod  (RAKUN_PROFILES_ACTIVE)
```

### `rakun: the boot sequence publishes the eight events around eager construction`

```bp
test "rakun: the boot sequence publishes the eight events around eager construction" {
    try assertLifecycle(@src(),
        \\ import {Rakun, App} from "rakun";
        \\ import {rkConfigLoad, rkPropInt} from "rakun";
        \\ import {UserController, UserService, UserRepository} from "users";
        \\ import {PostController, PostService, PostRepository} from "posts";
        \\ import {TimeService, Clock, AppConfig} from "config";
        \\
        \\ pub mod users;
        \\ pub mod posts;
        \\ pub mod config;
        \\
        \\ fn main() {
        \\     val _cfg = rkConfigLoad();
        \\     Rakun.run(App(port: rkPropInt("server.port"), basePath: "/api"));
        \\ }
        , ["boot"]);
}
```

`examples/rakun/test/__snapshots__/rakun/the-boot-sequence-publishes-the-eight-events-around-eager-construction.snap`
```
boot context ApplicationStarting
boot context ApplicationEnvironmentPrepared
boot context ApplicationContextInitialized
boot context ApplicationPrepared
construct UserRepository new
construct UserService new
construct UserController new
construct PostRepository new
construct PostService new
construct PostController new
construct AppConfig new
construct Clock AppConfig.clock
construct TimeService new
boot context ApplicationStarted
boot context AvailabilityChanged(LivenessCorrect)
boot context ApplicationReady
boot context AvailabilityChanged(ReadinessAcceptingTraffic)
```

## `examples/rest-service`

**Fronts:** 05 · 06 · 07 · 08 · 11 · 14 · 17 · 19 · 72 · 77 · 78 · **Depends on:** `rakun`, `rakun-web`, `rakun-data`, `rakun-validation`, `rakun-logging`, `rakun-actuator`, `rakun-test` (via `rakun-starter-web`, `rakun-starter-data-sql`, `rakun-starter-actuator`, `rakun-starter-test`) · **Tests:** `examples/rest-service/test/rest-service_test.bp` · **Snapshots:** `examples/rest-service/test/__snapshots__/rest-service/` · **Target:** erlang

> helper gap: front 19 has no helper of its own — its contract (the `rkScanSource` scratch context and `MockMvc.standalone()` dispatch with no socket) is what every case in this file runs through; the `assertContext`/`assertQuery` cases run with the manifest's auto-configuration applied (72), which is how `SqlTemplate` resolves without a `#[configuration]` in the project.

```
examples/rest-service/
├── botopink.json            dependencies: rakun-starter-web · rakun-starter-data-sql · rakun-starter-actuator · rakun-starter-test
├── application.yaml         server.port 8080 · rakun.datasource.url ets:memory · rakun.migration.{enabled true, validate-on-migrate true, lock-timeout 30000} · rakun.logging.level.root info · rakun.logging.level.app.orders debug · rakun.logging.structured.format.console ecs
├── application-prod.yaml    rakun.datasource.url postgres://db/app · rakun.migration.ddl-auto none
├── db/migration/            V1__create_users.sql · V2__create_orders.sql · V10__add_status.sql · R__order_summary_view.sql
├── src/main.bp              autoConfigure() · Rakun.run(App(port: rkPropInt("server.port"), basePath: "/api"))
├── src/entities.bp          User (#[entity("users")] · #[id] #[generated] · #[column("email_address")]) · UserRepo (#[entityRepository("User")] · #[derived] findByEmail)
├── src/orders.bp            OrderRepository (#[repository] · #[query] count/insert/audit/findByUser) · UserRepository (#[query] findById) · OrderService (#[service] #[transactional] #[managed]) · OrderApi (#[route("/api/orders")])
├── src/users.bp             CreateUserRequest (#[validated]) · UserService (raiseProblem "user.not-found") · UserController (#[route("/api/users")]) · ApiProblems (#[controllerAdvice] #[exceptionHandler("user.not-found")])
├── src/web.bp               RequestIdFilter (#[filter] #[order(-400)] #[managed])
└── src/health.bp            DataSourceHealth (#[healthIndicator("db")]) · DeploymentInfo (#[infoContributor("deployment")])
```

### `rest-service: application.yaml and the prod profile bind the datasource and the migration guard`

```bp
test "rest-service: application.yaml and the prod profile bind the datasource and the migration guard" {
    try assertConfig(@src(),
        ["application.yaml", "application-prod.yaml", "RAKUN_PROFILES_ACTIVE=prod"],
        ["server.port", "rakun.datasource.url", "rakun.migration.ddl-auto", "rakun.migration.lock-timeout"]);
}
```

`examples/rest-service/test/__snapshots__/rest-service/application-yaml-and-the-prod-profile-bind-the-datasource-and-the-migration-guard.snap`
```
server.port = 8080  (application.yaml)
rakun.datasource.url = postgres://db/app  (application-prod.yaml)
rakun.migration.ddl-auto = none  (application-prod.yaml)
rakun.migration.lock-timeout = 30000  (application.yaml)
```

### `rest-service: the container wires the transactional proxy between the api and the service`

```bp
test "rest-service: the container wires the transactional proxy between the api and the service" {
    try assertContext(@src(),
        \\ import {Request, Response} from "rakun";
        \\ import {repository, service, restController, route, getMapping, postMapping} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {managed} from "rakun";
        \\ import {raiseProblem} from "rakun-web";
        \\ import {SqlTemplate, Rows, Row, Param, Tx, param} from "rakun-data";
        \\ import {query, transactional, noTransaction} from "rakun-data";
        \\ import {rkRegisterQuery, rkTxRun, rkPoolStats} from "rakun-data";
        \\
        \\ #[repository]
        \\ #[managed]
        \\ pub type UserRepository(
        \\     sql: SqlTemplate,
        \\ ) {
        \\     #[query("SELECT id, name, email_address FROM users WHERE id = :id")]
        \\     pub fn findById(self: Self, id: i32) -> ?Row {
        \\         return self.sql.single(__rkQuery_findById(), [param("id", id.toString())]);
        \\     }
        \\ }
        \\
        \\ #[repository]
        \\ #[managed]
        \\ pub type OrderRepository(
        \\     sql: SqlTemplate,
        \\ ) {
        \\     #[query("SELECT count(*) AS n FROM orders")]
        \\     pub fn count(self: Self) -> i32 {
        \\         val row = self.sql.single(__rkQuery_count(), []);
        \\         var n = 0;
        \\         if (row) { r -> n = r.int("n"); };
        \\         return n;
        \\     }
        \\
        \\     #[query("INSERT INTO orders (id, user_id, total) VALUES (:id, :userId, :total)")]
        \\     pub fn insert(self: Self, id: i32, userId: i32, total: i32) -> i32 {
        \\         return self.sql.update(__rkQuery_insert(), [
        \\             param("id", id.toString()),
        \\             param("userId", userId.toString()),
        \\             param("total", total.toString()),
        \\         ]);
        \\     }
        \\
        \\     #[query("INSERT INTO order_audit (order_id, action) VALUES (:id, :action)")]
        \\     pub fn audit(self: Self, id: i32, action: string) -> i32 {
        \\         return self.sql.update(__rkQuery_audit(), [param("id", id.toString()), param("action", action)]);
        \\     }
        \\
        \\     #[query("SELECT id, total FROM orders WHERE user_id = :userId ORDER BY id")]
        \\     pub fn findByUser(self: Self, userId: i32) -> Rows {
        \\         return self.sql.query(__rkQuery_findByUser(), [param("userId", userId.toString())]);
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[transactional]
        \\ #[managed]
        \\ pub type OrderService(
        \\     users: UserRepository,
        \\     orders: OrderRepository,
        \\ ) {
        \\     pub fn place(self: Self, userId: i32, total: i32) -> i32 {
        \\         val owner = self.users.findById(userId);
        \\         var exists = false;
        \\         if (owner) { u -> exists = true; };
        \\         if (!exists) raiseProblem("user.not-found", "no user ${userId}");
        \\         val id = self.orders.count() + 1;
        \\         val _o = self.orders.insert(id, userId, total);
        \\         val _a = self.orders.audit(id, "placed");
        \\         return id;
        \\     }
        \\
        \\     #[noTransaction]
        \\     pub fn history(self: Self, userId: i32) -> string {
        \\         val rows = self.orders.findByUser(userId);
        \\         return rows.toList().map({ r -> r.get("id") + ":" + r.get("total") }).join(",");
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/orders")]
        \\ #[managed]
        \\ pub type OrderApi(
        \\     orders: OrderServiceTx,
        \\ ) {
        \\     #[postMapping("/")]
        \\     pub fn place(self: Self, req: Request) -> Response {
        \\         val userId = req.query("userId").length();
        \\         val id = self.orders.place(userId, 250);
        \\         return Response.created(id.toString());
        \\     }
        \\
        \\     #[getMapping("/:userId")]
        \\     pub fn history(self: Self, req: Request) -> Response {
        \\         return Response.json(self.orders.history(req.param("userId").length()));
        \\     }
        \\ }
        , ["OrderServiceTx", "OrderService", "SqlTemplate", "OrderApi"]);
}
```

`examples/rest-service/test/__snapshots__/rest-service/the-container-wires-the-transactional-proxy-between-the-api-and-the-service.snap`
```
bean OrderApi scope=singleton deps=[OrderServiceTx]
bean OrderRepository scope=singleton deps=[SqlTemplate]
bean OrderService scope=singleton deps=[OrderRepository, UserRepository]
bean OrderServiceTx scope=singleton deps=[OrderService]
bean UserRepository scope=singleton deps=[SqlTemplate]
resolve OrderServiceTx -> ok
resolve OrderService -> ok
resolve SqlTemplate -> ok
resolve OrderApi -> ok
```

### `rest-service: the request id filter tags every response before the router answers`

```bp
test "rest-service: the request id filter tags every response before the router answers" {
    try assertMiddleware(@src(),
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {managed} from "rakun";
        \\ import {rkSetReplyHeader} from "rakun";
        \\ import {Filter, Chain} from "rakun-web";
        \\ import {filter, order} from "rakun-web";
        \\ import {rkRegisterFilter, rkChainNext} from "rakun-web";
        \\
        \\ #[filter]
        \\ #[order(-400)]
        \\ #[managed]
        \\ pub type RequestIdFilter implement Filter {
        \\     pub fn handle(self: Self, req: Request, chain: Chain) -> Response {
        \\         val incoming = req.header("x-request-id");
        \\         val id = if (incoming == "") "req-" + req.path.length().toString() else incoming;
        \\         val _h = rkSetReplyHeader("X-Request-Id", id);
        \\         return chain.next(req);
        \\     }
        \\ }
        , ["GET /api/users/7", "GET /api/users/7 x-request-id: req-0001"]);
}
```

`examples/rest-service/test/__snapshots__/rest-service/the-request-id-filter-tags-every-response-before-the-router-answers.snap`
```
order -400 RequestIdFilter
> RequestIdFilter pass
= 404 X-Request-Id=req-12
> RequestIdFilter pass
= 404 X-Request-Id=req-0001
```

### `rest-service: placing an order commits one transaction and a missing user rolls it back`

```bp
test "rest-service: placing an order commits one transaction and a missing user rolls it back" {
    try assertQuery(@src(),
        \\ import {repository, service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {managed} from "rakun";
        \\ import {raiseProblem} from "rakun-web";
        \\ import {SqlTemplate, Rows, Row, Param, Tx, param} from "rakun-data";
        \\ import {query, transactional, noTransaction} from "rakun-data";
        \\ import {rkRegisterQuery, rkTxRun, rkPoolStats} from "rakun-data";
        \\
        \\ #[repository]
        \\ #[managed]
        \\ pub type UserRepository(
        \\     sql: SqlTemplate,
        \\ ) {
        \\     #[query("SELECT id, name, email_address FROM users WHERE id = :id")]
        \\     pub fn findById(self: Self, id: i32) -> ?Row {
        \\         return self.sql.single(__rkQuery_findById(), [param("id", id.toString())]);
        \\     }
        \\ }
        \\
        \\ #[repository]
        \\ #[managed]
        \\ pub type OrderRepository(
        \\     sql: SqlTemplate,
        \\ ) {
        \\     #[query("SELECT count(*) AS n FROM orders")]
        \\     pub fn count(self: Self) -> i32 {
        \\         val row = self.sql.single(__rkQuery_count(), []);
        \\         var n = 0;
        \\         if (row) { r -> n = r.int("n"); };
        \\         return n;
        \\     }
        \\
        \\     #[query("INSERT INTO orders (id, user_id, total) VALUES (:id, :userId, :total)")]
        \\     pub fn insert(self: Self, id: i32, userId: i32, total: i32) -> i32 {
        \\         return self.sql.update(__rkQuery_insert(), [
        \\             param("id", id.toString()),
        \\             param("userId", userId.toString()),
        \\             param("total", total.toString()),
        \\         ]);
        \\     }
        \\
        \\     #[query("INSERT INTO order_audit (order_id, action) VALUES (:id, :action)")]
        \\     pub fn audit(self: Self, id: i32, action: string) -> i32 {
        \\         return self.sql.update(__rkQuery_audit(), [param("id", id.toString()), param("action", action)]);
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[transactional]
        \\ #[managed]
        \\ pub type OrderService(
        \\     users: UserRepository,
        \\     orders: OrderRepository,
        \\ ) {
        \\     pub fn place(self: Self, userId: i32, total: i32) -> i32 {
        \\         val owner = self.users.findById(userId);
        \\         var exists = false;
        \\         if (owner) { u -> exists = true; };
        \\         if (!exists) raiseProblem("user.not-found", "no user ${userId}");
        \\         val id = self.orders.count() + 1;
        \\         val _o = self.orders.insert(id, userId, total);
        \\         val _a = self.orders.audit(id, "placed");
        \\         return id;
        \\     }
        \\ }
        , ["OrderServiceTx.place(1, 250)", "OrderServiceTx.place(9, 250)"]);
}
```

`examples/rest-service/test/__snapshots__/rest-service/placing-an-order-commits-one-transaction-and-a-missing-user-rolls-it-back.snap`
```
begin
UserRepository.findById(1) -> SELECT id, name, email_address FROM users WHERE id = :id  params=[1]
OrderRepository.count() -> SELECT count(*) AS n FROM orders  params=[]
OrderRepository.insert(1, 1, 250) -> INSERT INTO orders (id, user_id, total) VALUES (:id, :userId, :total)  params=[1, 1, 250]
OrderRepository.audit(1, placed) -> INSERT INTO order_audit (order_id, action) VALUES (:id, :action)  params=[1, placed]
commit
begin
UserRepository.findById(9) -> SELECT id, name, email_address FROM users WHERE id = :id  params=[9]
rollback
```

### `rest-service: the user entity maps its table and the renamed email column`

```bp
test "rest-service: the user entity maps its table and the renamed email column" {
    try assertEntity(@src(),
        \\ import {repository} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {SqlTemplate, Row, param} from "rakun-data";
        \\ import {entity, id, generated, column, derived, entityRepository} from "rakun-data";
        \\ import {Page, Pageable, Sort, queryOf, derivedSql} from "rakun-data";
        \\
        \\ #[entity("users")]
        \\ pub type User(
        \\     #[id]
        \\     #[generated]
        \\     id: i32,
        \\
        \\     name: string,
        \\
        \\     #[column("email_address")]
        \\     email: string,
        \\ )
        \\
        \\ #[repository]
        \\ #[entityRepository("User")]
        \\ pub type UserRepo(
        \\     sql: SqlTemplate,
        \\ ) {
        \\     #[derived]
        \\     pub fn findByEmail(self: Self, email: string) -> ?User {
        \\         return __rkDerived_UserRepo_findByEmail(self.sql, email);
        \\     }
        \\ }
        );
}
```

`examples/rest-service/test/__snapshots__/rest-service/the-user-entity-maps-its-table-and-the-renamed-email-column.snap`
```
create table users (id integer generated always as identity primary key, name varchar not null, email_address varchar not null)
map email <- email_address varchar
map id <- id integer
map name <- name varchar
```

### `rest-service: pending migrations run in version order after the applied one`

```bp
test "rest-service: pending migrations run in version order after the applied one" {
    try assertMigration(@src(),
        [
            "V1__create_users.sql: create table users (id integer primary key, name varchar not null, email_address varchar not null);",
            "V2__create_orders.sql: create table orders (id integer primary key, user_id integer not null, total integer not null);",
            "V10__add_status.sql: alter table orders add column status varchar;",
            "R__order_summary_view.sql: create or replace view order_summary as select user_id, sum(total) as total from orders group by user_id;",
        ],
        ["applied 1 535bbea29578998174250184458d718d81f2304cf708e809fb75cf5e18801d54"]);
}
```

`examples/rest-service/test/__snapshots__/rest-service/pending-migrations-run-in-version-order-after-the-applied-one.snap`
```
applied 1 535bbea29578998174250184458d718d81f2304cf708e809fb75cf5e18801d54
pending 2 create_orders
pending 10 add_status
pending - order_summary_view
```

### `rest-service: an edited applied migration refuses the boot`

```bp
test "rest-service: an edited applied migration refuses the boot" {
    try assertMigration(@src(),
        [
            "V1__create_users.sql: create table users (id integer primary key, name varchar not null, email_address varchar not null);",
            "V2__create_orders.sql: create table orders (id integer primary key, user_id integer not null, total integer not null);",
        ],
        [
            "applied 1 535bbea29578998174250184458d718d81f2304cf708e809fb75cf5e18801d54",
            "applied 2 0000000000000000000000000000000000000000000000000000000000000000",
        ]);
}
```

`examples/rest-service/test/__snapshots__/rest-service/an-edited-applied-migration-refuses-the-boot.snap`
```
applied 1 535bbea29578998174250184458d718d81f2304cf708e809fb75cf5e18801d54
refused V2__create_orders.sql checksum 0000000000000000000000000000000000000000000000000000000000000000 does not match 0d9f709303dcfead8aefe11ed59d5a24eeb754cd9944c5364ac185c3e1e3cfff
```

### `rest-service: a new user is refused field by field`

```bp
test "rest-service: a new user is refused field by field" {
    try assertValidation(@src(),
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
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
        , "name=A&email=not-mail&age=17&postalCode=1234");
}
```

`examples/rest-service/test/__snapshots__/rest-service/a-new-user-is-refused-field-by-field.snap`
```
invalid
age: minValue must be at least 18
email: email must be a well-formed email address
name: sizeBetween must be between 2 and 50 characters
postalCode: pattern must match ^[0-9]{5}-[0-9]{3}$
```

### `rest-service: health aggregates the db indicator and info carries the deployment`

```bp
test "rest-service: health aggregates the db indicator and info carries the deployment" {
    try assertHealth(@src(),
        \\ import {Request} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {managed} from "rakun";
        \\ import {SqlTemplate} from "rakun-data";
        \\ import {rkPoolStats} from "rakun-data";
        \\ import {Health, HealthIndicator, InfoContributor} from "rakun-actuator-api";
        \\ import {healthIndicator, infoContributor} from "rakun-actuator-api";
        \\ import {rkRegisterHealthIndicator, rkRegisterInfoContributor} from "rakun-actuator-api";
        \\
        \\ #[healthIndicator("db")]
        \\ #[managed]
        \\ pub type DataSourceHealth(
        \\     sql: SqlTemplate,
        \\ ) {
        \\     pub fn check(self: Self) -> Health {
        \\         val r = self.sql.tryQuery("SELECT 1 AS ok", []);
        \\         val status = if (r.isOk()) "UP" else "DOWN";
        \\         return Health(status: status, details: "{}");
        \\     }
        \\ }
        \\
        \\ #[infoContributor("deployment")]
        \\ #[managed]
        \\ pub type DeploymentInfo {
        \\     pub fn contribute(self: Self) -> string {
        \\         return "{\"deployment\": {\"region\": \"eu-west-1\", \"replica\": \"blue\"}}";
        \\     }
        \\ }
        , ["db up"]);
}
```

`examples/rest-service/test/__snapshots__/rest-service/health-aggregates-the-db-indicator-and-info-carries-the-deployment.snap`
```
status UP
components:
db UP {}
```

### `rest-service: ecs lines carry the level, the logger, the fields and the seeded trace id`

```bp
test "rest-service: ecs lines carry the level, the logger, the fields and the seeded trace id" {
    try assertLog(@src(),
        [
            "rakun.logging.structured.format.console=ecs",
            "rakun.logging.level.root=info",
            "rakun.logging.level.app.orders=debug",
        ],
        [
            "info app.orders order placed order.id=o-1",
            "debug app.orders gateway ok",
            "debug app.users skipped",
            "warn app.orders charge declined gateway.code=51",
        ]);
}
```

`examples/rest-service/test/__snapshots__/rest-service/ecs-lines-carry-the-level-the-logger-the-fields-and-the-seeded-trace-id.snap`
```
{"@timestamp":"2026-01-01T00:00:00Z","log.level":"INFO","message":"order placed","service.name":"rest-service","process.thread.name":"<0.1.0>","log.logger":"app.orders","trace.id":"trace-0001","order.id":"o-1"}
{"@timestamp":"2026-01-01T00:00:00Z","log.level":"DEBUG","message":"gateway ok","service.name":"rest-service","process.thread.name":"<0.1.0>","log.logger":"app.orders","trace.id":"trace-0001"}
{"@timestamp":"2026-01-01T00:00:00Z","log.level":"WARN","message":"charge declined","service.name":"rest-service","process.thread.name":"<0.1.0>","log.logger":"app.orders","trace.id":"trace-0001","gateway.code":"51"}
```

### `rest-service: the starters make the data source eligible and leave cache and mail unmatched`

```bp
test "rest-service: the starters make the data source eligible and leave cache and mail unmatched" {
    try assertAutoConfig(@src(),
        \\ import {Rakun, App} from "rakun";
        \\ import {autoConfigure} from "rakun";
        \\ import {rkConfigLoad, rkPropInt} from "rakun";
        \\
        \\ fn main() {
        \\     val _cfg = rkConfigLoad();
        \\     val _ = autoConfigure();
        \\     Rakun.run(App(port: rkPropInt("server.port"), basePath: "/api"));
        \\ }
        , ["rakun-starter-web", "rakun-starter-data-sql", "rakun-starter-actuator", "rakun-starter-test"]);
}
```

`examples/rest-service/test/__snapshots__/rest-service/the-starters-make-the-data-source-eligible-and-leave-cache-and-mail-unmatched.snap`
```
- RakunCacheAutoConfiguration  M|rakun-cache
+ RakunCoreAutoConfiguration  always
+ RakunDataSourceAutoConfiguration  M|rakun-data;X|SqlTemplate
- RakunMailAutoConfiguration  M|rakun-mail;P|rakun.mail.host|*
```

## `examples/secured-api`

**Fronts:** 10 · 18 · 74 · 76 · 79 · 87 · **Depends on:** `rakun-security`, `rakun-session`, `rakun-actuator`, `rakun-web` · **Tests:** `examples/secured-api/test/secured-api_test.bp` · **Snapshots:** `examples/secured-api/test/__snapshots__/secured-api/` · **Target:** erlang

> helper gap: `assertSession` replays its requests through one cookie jar (that is what `session=same` means), so no request carries a `Cookie:` header by hand; `set-cookie=<attrs>` renders the attributes after the value, never the signed id.

```
examples/secured-api/
├── botopink.json          dependencies: rakun-security · rakun-session · rakun-actuator · rakun-web
├── application.yaml       rakun.security.jwt.{issuer,audience,authorities-claim roles} · rakun.security.oauth2.keycloak.{client-id orders-api, issuer-uri https://auth.example.com/realms/shop} · rakun.session.{store ets, timeout 30m, cookie.name SESSION} · rakun.ssl.bundle.pem.{public,edge}.* · rakun.server.{port 8443, ssl.bundle public} · rakun.endpoints.web.exposure.include health,info,auditevents,httpexchanges · rakun.management.httpexchanges.recording.{enabled true, include request-headers} · rakun.endpoint.health.probes.enabled true · rakun.lifecycle.pre-drain-period 5000
├── src/main.bp            autoConfigure() · Rakun.run(App(port: 8443, basePath: "/api"))
├── src/policy.bp          apiSecurityPolicy() -> SecurityPolicy (#[provides]) · AuditRepository · AdminService (#[methodSecurity] · #[secured] · #[permitAll]) · OrdersApi (#[route("/api")])
├── src/sso.bp             SsoConfig (#[configuration] · #[bean] #[oauth2Provider] keycloak) · Greeter · MeController (#[secured("SCOPE_orders:read")])
├── src/cart.bp            CartService · CartController (#[route("/api/cart")]) · LoginController (#[route("/api/auth")] · rotate · sessionCookieHeader)
├── src/payouts.bp         Payouts (audit PAYOUT_APPROVED / PAYOUT_DENIED)
└── src/warmup.bp          CatalogWarmer (setReadiness false → warm → true)
```

### `secured-api: the path policy protects what no rule names and the jwt negative table is anonymous`

```bp
test "secured-api: the path policy protects what no rule names and the jwt negative table is anonymous" {
    try assertSecurity(@src(),
        \\ import {Request, Response} from "rakun";
        \\ import {service, restController, route, getMapping, deleteMapping} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {managed, provides} from "rakun";
        \\ import {SecurityPolicy, PathRule, Authentication, Principal} from "rakun-security";
        \\ import {methodSecurity, secured, permitAll} from "rakun-security";
        \\ import {security} from "rakun-security";
        \\ import {rkRequireAuthority} from "rakun-security";
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
        \\ #[managed]
        \\ pub type AuditRepository {
        \\     pub fn purgeOlderThan(self: Self, days: i32) -> i32 {
        \\         return days;
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[methodSecurity]
        \\ #[managed]
        \\ pub type AdminService(
        \\     audit: AuditRepository,
        \\ ) {
        \\     #[secured("ROLE_ADMIN")]
        \\     pub fn purge(self: Self, olderThanDays: i32) -> i32 {
        \\         return self.audit.purgeOlderThan(olderThanDays);
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
        \\     #[getMapping("/orders/mine")]
        \\     pub fn mine(self: Self, req: Request) -> Response {
        \\         val auth = security.current();
        \\         val who = auth.principal.name;
        \\         return Response.json("{\"user\":\"${who}\"}");
        \\     }
        \\
        \\     #[deleteMapping("/admin/audit")]
        \\     pub fn purge(self: Self, req: Request) -> Response {
        \\         val days = req.query("olderThanDays").length();
        \\         return Response.ok("purged " + self.admin.purge(days).toString());
        \\     }
        \\ }
        , [
            "GET /api/public/health",
            "GET /api/orders/mine",
            "GET /api/orders/mine Authorization: Bearer " + security.testToken("ana", ["ROLE_USER"]),
            "GET /api/orders/mine Authorization: Bearer " + security.testTokenAlgNone("ana", ["ROLE_USER"]),
            "GET /api/orders/mine Authorization: Bearer " + security.testTokenTampered("ana", ["ROLE_ADMIN"]),
            "DELETE /api/admin/audit Authorization: Bearer " + security.testToken("ana", ["ROLE_USER"]),
            "DELETE /api/admin/audit Authorization: Bearer " + security.testToken("root", ["ROLE_ADMIN"]),
            "GET /api/unmapped Authorization: Bearer " + security.testToken("ana", ["ROLE_USER"]),
        ]);
}
```

`examples/secured-api/test/__snapshots__/secured-api/the-path-policy-protects-what-no-rule-names-and-the-jwt-negative-table-is-anonymous.snap`
```
GET /api/public/health -> 200 granted permitAll /api/public/:path*
GET /api/orders/mine -> 401 anonymous
GET /api/orders/mine [ana] -> 200 authenticated
GET /api/orders/mine -> 401 anonymous
GET /api/orders/mine -> 401 anonymous
DELETE /api/admin/audit [ana] -> 403 denied hasRole:ADMIN /api/admin/:path*
DELETE /api/admin/audit [root] -> 200 granted hasRole:ADMIN /api/admin/:path*
GET /api/unmapped [ana] -> 404 authenticated
```

### `secured-api: the cart lives in the session and login rotates the id`

```bp
test "secured-api: the cart lives in the session and login rotates the id" {
    try assertSession(@src(),
        \\ import {service, restController, route, getMapping, postMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {Session, SessionStore, currentSession, rotate} from "rakun-session";
        \\ import {sessionCookieHeader} from "rakun-session";
        \\ import {withHeader} from "rakun-web";
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
        \\         val current = self.read(session);
        \\         val trimmed = current.slice(1, current.length() - 1);
        \\         val joined = if (trimmed == "") { "\"" + sku + "\"" } else { trimmed + ",\"" + sku + "\"" };
        \\         val next = session.withAttribute("cart", "[" + joined + "]");
        \\         val _saved = self.store.save(next);
        \\         return next;
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/cart")]
        \\ pub type CartController(
        \\     cart: CartService,
        \\ ) {
        \\     #[getMapping("/")]
        \\     pub fn show(self: Self, req: Request) -> Response {
        \\         val session = currentSession();
        \\         return Response.json(self.cart.read(session));
        \\     }
        \\
        \\     #[postMapping("/items")]
        \\     pub fn add(self: Self, req: Request) -> Response {
        \\         val session = currentSession();
        \\         val next = self.cart.addItem(session, req.query("sku"));
        \\         return Response.json(self.cart.read(next));
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/auth")]
        \\ pub type LoginController(
        \\     store: SessionStore,
        \\ ) {
        \\     #[postMapping("/login")]
        \\     pub fn login(self: Self, req: Request) -> Response {
        \\         val before = currentSession();
        \\         val rotated = rotate(before);
        \\         val authenticated = rotated.withAttribute("principal", req.query("user"));
        \\         val _saved = self.store.save(authenticated);
        \\         val cookie = sessionCookieHeader("SESSION", authenticated.id, 1800, "/", "Lax");
        \\         return withHeader(Response.json("{\"ok\":true}"), "set-cookie", cookie);
        \\     }
        \\ }
        , [
            "GET /api/cart/",
            "POST /api/cart/items?sku=A1",
            "GET /api/cart/",
            "POST /api/auth/login?user=ana",
            "GET /api/cart/",
        ]);
}
```

`examples/secured-api/test/__snapshots__/secured-api/the-cart-lives-in-the-session-and-login-rotates-the-id.snap`
```
GET /api/cart/ -> 200 session=new set-cookie=Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax
POST /api/cart/items?sku=A1 -> 200 session=same set-cookie=-
GET /api/cart/ -> 200 session=same set-cookie=-
POST /api/auth/login?user=ana -> 200 session=new set-cookie=Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax
GET /api/cart/ -> 200 session=same set-cookie=-
```

### `secured-api: the public and edge bundles terminate tls and a jks bundle is refused`

```bp
test "secured-api: the public and edge bundles terminate tls and a jks bundle is refused" {
    try assertSslBundle(@src(),
        [
            "rakun.ssl.bundle.pem.public.keystore.certificate=/etc/rakun/tls/fullchain.pem",
            "rakun.ssl.bundle.pem.public.keystore.private-key=/etc/rakun/tls/privkey.pem",
            "rakun.ssl.bundle.pem.public.protocols=tlsv1.3,tlsv1.2",
            "rakun.ssl.bundle.pem.public.client-auth=none",
            "rakun.ssl.bundle.pem.edge.keystore.certificate=/etc/rakun/tls/edge.pem",
            "rakun.ssl.bundle.pem.edge.keystore.private-key=/etc/rakun/tls/edge-key.pem",
            "rakun.ssl.bundle.pem.edge.truststore.certificate=/etc/rakun/tls/clients-ca.pem",
            "rakun.ssl.bundle.pem.edge.client-auth=need",
            "rakun.ssl.bundle.jks.legacy.keystore.location=/etc/rakun/tls/legacy.jks",
        ],
        [
            "handshake public tlsv1.3",
            "handshake public tlsv1.1",
            "handshake edge without-client-certificate",
            "handshake edge with-client-certificate",
            "bundle legacy",
        ]);
}
```

`examples/secured-api/test/__snapshots__/secured-api/the-public-and-edge-bundles-terminate-tls-and-a-jks-bundle-is-refused.snap`
```
bundle public kind=pem protocols=[tlsv1.3,tlsv1.2] ciphers=[]
bundle edge kind=pem protocols=[tlsv1.3,tlsv1.2] ciphers=[]
probe handshake public tlsv1.3 -> ok
probe handshake public tlsv1.1 -> err protocol not offered
probe handshake edge without-client-certificate -> err client certificate required
probe handshake edge with-client-certificate -> ok
probe bundle legacy -> err jks is not supported, convert the store to pem
```

### `secured-api: only health, info and the two audit endpoints are exposed`

```bp
test "secured-api: only health, info and the two audit endpoints are exposed" {
    try assertExposure(@src(),
        [
            "rakun.endpoints.web.exposure.include=health,info,auditevents,httpexchanges",
            "rakun.endpoints.access.default=read-only",
            "rakun.endpoints.access.max-permitted=read-only",
        ],
        [
            "/actuator/health",
            "/actuator/info",
            "/actuator/auditevents",
            "/actuator/httpexchanges",
            "/actuator/env",
            "/actuator/shutdown",
        ]);
}
```

`examples/secured-api/test/__snapshots__/secured-api/only-health-info-and-the-two-audit-endpoints-are-exposed.snap`
```
/actuator/health -> 200 exposed
/actuator/info -> 200 exposed
/actuator/auditevents -> 200 exposed
/actuator/httpexchanges -> 200 exposed
/actuator/env -> 404 hidden
/actuator/shutdown -> 404 hidden
```

### `secured-api: readiness drops during warm-up and before the drain while liveness stays correct`

```bp
test "secured-api: readiness drops during warm-up and before the drain while liveness stays correct" {
    try assertProbe(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkSetProp} from "rakun";
        \\ import {readinessState, livenessState, setReadiness, readinessDrained} from "rakun-actuator";
        \\ import {callEndpoint, signalReady, signalShutdown} from "rakun-actuator";
        \\ import {drainStartedAt, readinessFalseAt} from "rakun-actuator";
        \\
        \\ #[service]
        \\ pub type CatalogWarmer {
        \\     pub fn warm(self: Self) -> i32 {
        \\         val _notReady = setReadiness(false);
        \\         val loaded = loadCatalog();
        \\         val _ready = setReadiness(true);
        \\         return loaded;
        \\     }
        \\ }
        \\
        \\ pub fn loadCatalog() -> i32 {
        \\     return 1200;
        \\ }
        , ["boot", "CatalogWarmer.warm begin", "CatalogWarmer.warm end", "signalShutdown SIGTERM", "drain"]);
}
```

`examples/secured-api/test/__snapshots__/secured-api/readiness-drops-during-warm-up-and-before-the-drain-while-liveness-stays-correct.snap`
```
+0ms liveness=CORRECT readiness=ACCEPTING_TRAFFIC
+1ms liveness=CORRECT readiness=REFUSING_TRAFFIC
+2ms liveness=CORRECT readiness=ACCEPTING_TRAFFIC
+3ms liveness=CORRECT readiness=REFUSING_TRAFFIC
+5003ms liveness=CORRECT readiness=REFUSING_TRAFFIC
```

### `secured-api: the keycloak login redirect carries pkce, state and nonce`

```bp
test "secured-api: the keycloak login redirect carries pkce, state and nonce" {
    try assertOAuth(@src(),
        [
            "rakun.security.oauth2.keycloak.client-id=orders-api",
            "rakun.security.oauth2.keycloak.client-secret=test-secret",
            "rakun.security.oauth2.keycloak.issuer-uri=https://auth.example.com/realms/shop",
        ],
        "authorize keycloak returnTo=/api/orders");
}
```

`examples/secured-api/test/__snapshots__/secured-api/the-keycloak-login-redirect-carries-pkce-state-and-nonce.snap`
```
authorize https://auth.example.com/realms/shop/protocol/openid-connect/auth?client_id=orders-api&code_challenge=kadEzpr0sB5qQBp8dB_hax60Qp1pKI61YmSGXk5zYqE&code_challenge_method=S256&nonce=nonce-0001&redirect_uri=https%3A%2F%2Flocalhost%3A8443%2Flogin%2Foauth2%2Fcode%2Fkeycloak&response_type=code&scope=openid%20profile%20email&state=state-0001
```

### `secured-api: the code exchange yields a principal with scope and role authorities`

```bp
test "secured-api: the code exchange yields a principal with scope and role authorities" {
    try assertOAuth(@src(),
        [
            "rakun.security.oauth2.keycloak.client-id=orders-api",
            "rakun.security.oauth2.keycloak.client-secret=test-secret",
            "rakun.security.oauth2.keycloak.issuer-uri=https://auth.example.com/realms/shop",
        ],
        "token keycloak code=code-0001 state=state-0001");
}
```

`examples/secured-api/test/__snapshots__/secured-api/the-code-exchange-yields-a-principal-with-scope-and-role-authorities.snap`
```
token ok
principal ana authorities=[ROLE_USER, SCOPE_email, SCOPE_openid, SCOPE_orders:read, SCOPE_profile]
```

### `secured-api: payout decisions are audited with their data sorted`

```bp
test "secured-api: payout decisions are audited with their data sorted" {
    try assertAudit(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {AuditEvent, AuditRepository, audit, memoryAuditRepository} from "rakun-actuator";
        \\
        \\ #[service]
        \\ type Payouts {
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
        , ["Payouts.approve(p-1, ana)", "Payouts.deny(p-2, ana, insufficient funds)"]);
}
```

`examples/secured-api/test/__snapshots__/secured-api/payout-decisions-are-audited-with-their-data-sorted.snap`
```
PAYOUT_APPROVED principal=ana data={payout.amount.cents=120000, payout.id=p-1}
PAYOUT_DENIED principal=ana data={payout.id=p-2, reason=insufficient funds}
```

### `secured-api: recorded exchanges keep ordinary headers and drop the two credentials`

```bp
test "secured-api: recorded exchanges keep ordinary headers and drop the two credentials" {
    try assertExchanges(@src(),
        \\ import {Request, Response} from "rakun";
        \\ import {service, restController, route, getMapping} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {managed} from "rakun";
        \\
        \\ #[restController]
        \\ #[route("/api")]
        \\ #[managed]
        \\ pub type OrdersApi {
        \\     #[getMapping("/public/health")]
        \\     pub fn publicHealth(self: Self, req: Request) -> Response {
        \\         return Response.ok("ok");
        \\     }
        \\ }
        , [
            "GET /api/public/health accept: application/json user-agent: curl/8.5.0 authorization: Bearer eyJhbGciOi cookie: session=6f1c2a",
            "GET /api/nothing",
        ]);
}
```

`examples/secured-api/test/__snapshots__/secured-api/recorded-exchanges-keep-ordinary-headers-and-drop-the-two-credentials.snap`
```
GET /api/public/health -> 200 [include=request.header.accept,request.header.user-agent]
GET /api/nothing -> 404
```

## `examples/blog-server`

**Fronts:** 12 · 22 · 23 · 24 · 25 · 60 · 61 · 62 · 63 · 64 · 65 · 66 · 82 · **Depends on:** `rakun-app`, `rakun-web`, `rakun-cache` · **Tests:** `examples/blog-server/test/blog-server_test.bp` · **Snapshots:** `examples/blog-server/test/__snapshots__/blog-server/` · **Target:** erlang (the boundary halves — 22's matcher, 60's route kinds, 61's slot states, 65's canonicalization — are `rakun-routing`'s and run on both targets in its own tests)

rakun only (decision 114): every page is a `PageRenderer` writing plain text and every handler answers JSON. A `layout.bp` in a file list below is a table record the `rakun-test` helper registers the way onze's boot does (front 22's `rkAppRegisterEntry`); no layout function exists in this project. The blog rendered by jhonstart and styled by emilia — layouts, payload, forms, the browser half — is onze's (onze front 53, `repository/onze/examples/blog`).

> helper gap: `assertSlots` renders the four slot states of the 61 wire (`matched`, `default`, `unchanged`, `empty`), not only the two the table lists — a soft navigation that keeps a slot has to say so.

```
examples/blog-server/
├── botopink.json                        dependencies: rakun-app · rakun-web · rakun-cache
├── application.yaml                     rakun.cache.type ets · rakun.cache.names products,prices · rakun.web.static.build-dir dist/ · rakun.web.static.public-dir public/ · onze.appDir app
├── src/main.bp                          Rakun.run(App(port: 8080, basePath: ""))
├── src/i18n.bp                          appLocales() -> LocaleSet(["pt-BR","en","es"], "pt-BR") · registerLocales · localeFilter excluding /api, /dashboard, /sitemap.xml, /robots.txt
├── src/rules.bp                         appUrlRules() -> UrlRules (trailingSlash false · /old→/new permanent · /blog/:slug→/en/blog/:slug · /shop/:path*→/catalog/:path* · /api/external/:path*→https://api.example.com/:path*)
├── src/assets.bp                        AssetConfig (#[configuration] · buildAssets /_assets/** immutable · publicAssets /public/** index.html)
├── src/catalog.bp                       productsJson · priceJson · repriceProduct (cachePolicy · cacheThrough · updateTag · revalidateTag · revalidatePath)
├── src/posts.bp                         Post · findPost (#[@result]) · getPost (memoize) · allPosts
├── src/routes.bp                        the layout records (rkAppRegisterEntry "L" for /, /[locale], /[locale]/blog, /dashboard; "D" for the two slot defaults)
├── app/                                 sitemap.bp · robots.bp · manifest.bp · favicon.ico · icon.png · opengraph-image.png
├── app/[locale]/page.bp                 homePage — page("[locale]", renderer)
├── app/[locale]/blog/                   page.bp blogIndexPage · new/page.bp createPost (#[serverAction]) · [slug]/page.bp blogPostPage (memoize · notFound · registerStaticParams) · [slug]/opengraph-image.bp (registerImageRoute; no renderer set, 501)
├── app/dashboard/                       page.bp dashboardPage (cookies().get("session") → redirect("/login")) · @analytics/page.bp · @team/settings/page.bp
└── app/api/posts/route.bp               listPosts (#[getRoute("api/posts")]) · createPost (#[postRoute("api/posts")])
```

### `blog-server: the app tree registers pages, layout records, slots and handlers`

```bp
test "blog-server: the app tree registers pages, layout records, slots and handlers" {
    try assertRouteTree(@src(),
        [
            "app/layout.bp",
            "app/[locale]/layout.bp",
            "app/[locale]/page.bp",
            "app/[locale]/blog/layout.bp",
            "app/[locale]/blog/page.bp",
            "app/[locale]/blog/[slug]/page.bp",
            "app/[locale]/blog/new/page.bp",
            "app/dashboard/layout.bp",
            "app/dashboard/page.bp",
            "app/dashboard/@analytics/page.bp",
            "app/dashboard/@analytics/default.bp",
            "app/dashboard/@team/settings/page.bp",
            "app/dashboard/@team/default.bp",
            "app/api/posts/route.bp",
        ],
        ["/en", "/en/blog/hello", "/en/blog/new", "/dashboard", "/api/posts", "/nope"]);
}
```

`examples/blog-server/test/__snapshots__/blog-server/the-app-tree-registers-pages-layout-records-slots-and-handlers.snap`
```
L / layouts=[] kind=static
L /[locale] layouts=[/] kind=dynamic
P /[locale] layouts=[/, /[locale]] kind=dynamic
L /[locale]/blog layouts=[/, /[locale]] kind=static
P /[locale]/blog layouts=[/, /[locale], /[locale]/blog] kind=static
P /[locale]/blog/[slug] layouts=[/, /[locale], /[locale]/blog] kind=dynamic
P /[locale]/blog/new layouts=[/, /[locale], /[locale]/blog] kind=static
L /dashboard layouts=[/] kind=static
P /dashboard layouts=[/, /dashboard] kind=static
P /dashboard/@analytics layouts=[/, /dashboard] kind=static
P /dashboard/@team/settings layouts=[/, /dashboard] kind=static
R /api/posts layouts=[] kind=static

/en -> /[locale] {locale=en}
/en/blog/hello -> /[locale]/blog/[slug] {locale=en, slug=hello}
/en/blog/new -> /[locale]/blog/new {locale=en}
/dashboard -> /dashboard {}
/api/posts -> /api/posts {}
/nope -> 404
```

### `blog-server: a post page writes its text through the chunk writer`

```bp
test "blog-server: a post page writes its text through the chunk writer" {
    try assertPageDispatch(@src(),
        \\ import {page, ChunkWriter, Request} from "rakun";
        \\ val _post = page("[locale]/blog/[slug]", fn(req: Request, out: ChunkWriter) {
        \\     return out.write("Hello (" + req.param("locale") + "): first post");
        \\ });
        , "GET /en/blog/hello");
}
```

`examples/blog-server/test/__snapshots__/blog-server/a-post-page-writes-its-text-through-the-chunk-writer.snap`
```
status 200
headers:
content-type: text/html; charset=utf-8
chunks 1
Hello (en): first post
closed 1
```

> helper gap: `assertPageDispatch` is front 23's dispatch helper (status, headers, the chunks the renderer wrote, how many times the dispatch closed the response); it replaces `assertSsr` in this project because the markup, the layouts and the payload are jhonstart's, asserted in onze's `examples/blog`.

### `blog-server: publishing a post revalidates the blog and a short title is invalid`

```bp
test "blog-server: publishing a post revalidates the blog and a short title is invalid" {
    try assertAction(@src(),
        \\ import {serverAction, FormData, ActionResult} from "rakun";
        \\ import {rkRegisterAction} from "rakun";
        \\ import {cache} from "rakun-cache";
        \\ import {collections.Dict} from "std";
        \\
        \\ #[@future]
        \\ fn savePost(title: string, body: string) -> @Future<string> {
        \\     return title.toLower().replaceAll(" ", "-");
        \\ }
        \\
        \\ #[serverAction]
        \\ #[@future]
        \\ pub fn createPost(form: FormData) -> @Future<ActionResult> {
        \\     val title = form.field("title");
        \\     val body = form.field("body");
        \\     val tooShort = title.length() < 3;
        \\     if (tooShort) {
        \\         return ActionResult.invalid("title", "Title must be at least 3 characters");
        \\     };
        \\     val _id = await savePost(title, body);
        \\     cache.revalidatePath("/en/blog");
        \\     return ActionResult.done();
        \\ }
        , "title=Hello world&body=first");
}
```

`examples/blog-server/test/__snapshots__/blog-server/publishing-a-post-revalidates-the-blog-and-a-short-title-is-invalid.snap`
```
action createPost
result done
revalidate [/en/blog]
```

### `blog-server: the posts handler answers json with a location and refuses multipart`

```bp
test "blog-server: the posts handler answers json with a location and refuses multipart" {
    try assertHandler(@src(),
        \\ import {Request, HttpMethod} from "rakun";
        \\ import {getRoute, postRoute, HandlerResponse, bodyJson, streamed} from "rakun";
        \\ import {rkAppRegisterHandler} from "rakun";
        \\ import {collections.Dict} from "std";
        \\
        \\ #[@future]
        \\ fn allPosts() -> @Future<string[]> {
        \\     return ["{\"slug\":\"hello\"}"];
        \\ }
        \\
        \\ #[@future]
        \\ fn insertPost(payload: string) -> @Future<string> {
        \\     return "{\"id\":\"3\"}";
        \\ }
        \\
        \\ #[getRoute("api/posts")]
        \\ #[@future]
        \\ pub fn listPosts(req: Request) -> @Future<HandlerResponse> {
        \\     val posts = await allPosts();
        \\     val body = "[" + posts.join(",") + "]";
        \\     return HandlerResponse.json(body);
        \\ }
        \\
        \\ #[postRoute("api/posts")]
        \\ #[@future]
        \\ pub fn createPost(req: Request) -> @Future<HandlerResponse> {
        \\     val contentType = req.header("content-type");
        \\     val isMultipart = contentType.startsWith("multipart/form-data");
        \\     if (isMultipart) {
        \\         return HandlerResponse.unsupportedMedia("multipart/form-data is not supported");
        \\     };
        \\     val parsed = bodyJson(req);
        \\     val ok = parsed.isOk();
        \\     if (!ok) {
        \\         return HandlerResponse.badRequest("body is not valid JSON");
        \\     };
        \\     val payload = parsed.unwrapOr("{}");
        \\     val created = await insertPost(payload);
        \\     val res = HandlerResponse.created(created);
        \\     return res.withHeader("location", "/api/posts/3");
        \\ }
        , "POST /api/posts content-type: application/json | {\"title\":\"x\"}");
}
```

`examples/blog-server/test/__snapshots__/blog-server/the-posts-handler-answers-json-with-a-location-and-refuses-multipart.snap`
```
201
content-type: application/json
location: /api/posts/3
chunks 1
{"id":"3"}
```

### `blog-server: the post page is static with its params and the dashboard is dynamic`

```bp
test "blog-server: the post page is static with its params and the dashboard is dynamic" {
    try assertStaticGen(@src(),
        [
            "app/layout.bp",
            "app/[locale]/layout.bp",
            "app/[locale]/page.bp",
            "app/[locale]/blog/layout.bp",
            "app/[locale]/blog/page.bp",
            "app/[locale]/blog/[slug]/page.bp",
            "app/[locale]/blog/new/page.bp",
            "app/dashboard/layout.bp",
            "app/dashboard/page.bp",
        ],
        \\ import {registerSegmentConfig, registerStaticParams, SegmentConfig, DynamicMode, FetchCache, StaticParams, ParamBinding} from "rakun";
        \\
        \\ val _blogConfig = registerSegmentConfig("[locale]/blog/[slug]", SegmentConfig(
        \\     dynamic: DynamicMode.Auto,
        \\     dynamicParams: true,
        \\     revalidate: 3600,
        \\     fetchCache: FetchCache.Auto,
        \\ ));
        \\
        \\ #[@future]
        \\ pub fn blogStaticParams() -> @Future<StaticParams[]> {
        \\     return [
        \\         StaticParams(bindings: [ParamBinding(name: "locale", value: "en"), ParamBinding(name: "slug", value: "hello")]),
        \\         StaticParams(bindings: [ParamBinding(name: "locale", value: "pt-BR"), ParamBinding(name: "slug", value: "hello")]),
        \\     ];
        \\ }
        \\
        \\ val _blogParams = registerStaticParams("[locale]/blog/[slug]", blogStaticParams);
        \\
        \\ #[@future]
        \\ pub fn localeStaticParams() -> @Future<StaticParams[]> {
        \\     return [
        \\         StaticParams(bindings: [ParamBinding(name: "locale", value: "en")]),
        \\         StaticParams(bindings: [ParamBinding(name: "locale", value: "pt-BR")]),
        \\     ];
        \\ }
        \\
        \\ val _localeParams = registerStaticParams("[locale]", localeStaticParams);
        );
}
```

`examples/blog-server/test/__snapshots__/blog-server/the-post-page-is-static-with-its-params-and-the-dashboard-is-dynamic.snap`
```
/[locale] static because static params params=[locale=en, locale=pt-BR] revalidate=never
/[locale]/blog static because no dynamic api params=[] revalidate=never
/[locale]/blog/[slug] static because static params params=[locale=en&slug=hello, locale=pt-BR&slug=hello] revalidate=3600
/[locale]/blog/new static because no dynamic api params=[] revalidate=never
/dashboard dynamic because cookies() params=[] revalidate=never
```

### `blog-server: dashboard slots resolve on a hard load and keep their state on a soft navigation`

```bp
test "blog-server: dashboard slots resolve on a hard load and keep their state on a soft navigation" {
    try assertSlots(@src(),
        [
            "app/layout.bp",
            "app/dashboard/layout.bp",
            "app/dashboard/page.bp",
            "app/dashboard/@analytics/page.bp",
            "app/dashboard/@analytics/default.bp",
            "app/dashboard/@team/settings/page.bp",
            "app/dashboard/@team/default.bp",
        ],
        ["hard - -> /dashboard", "soft /dashboard -> /dashboard/settings", "hard - -> /dashboard/settings"]);
}
```

`examples/blog-server/test/__snapshots__/blog-server/dashboard-slots-resolve-on-a-hard-load-and-keep-their-state-on-a-soft-navigation.snap`
```
- -> /dashboard: slot children=matched slot @analytics=matched slot @team=default intercept=none
/dashboard -> /dashboard/settings: slot children=unchanged slot @analytics=unchanged slot @team=matched intercept=none
- -> /dashboard/settings: slot children=empty slot @analytics=default slot @team=matched intercept=none
```

### `blog-server: a post render reads the theme cookie and memoizes the post once`

```bp
test "blog-server: a post render reads the theme cookie and memoizes the post once" {
    try assertRequestContext(@src(),
        \\ import {cookies, headers, memoize, memoKey, preload} from "rakun";
        \\ import {page, ChunkWriter, Request} from "rakun";
        \\
        \\ pub type Post(slug: string, title: string, body: string, author: string)
        \\
        \\ fn loadPost(slug: string) -> Post {
        \\     return Post(slug: slug, title: "Hello", body: "first post", author: "ana");
        \\ }
        \\
        \\ fn loadRelatedCount(slug: string) -> i32 {
        \\     return 2;
        \\ }
        \\
        \\ pub fn getPost(slug: string) -> Post {
        \\     val key = memoKey("getPost", [slug]);
        \\     return memoize(key, { ->
        \\         loadPost(slug);
        \\     });
        \\ }
        \\
        \\ pub fn postTitle(slug: string) -> string {
        \\     return getPost(slug).title;
        \\ }
        \\
        \\ val _post = page("[locale]/blog/[slug]", fn(req: Request, out: ChunkWriter) {
        \\     val slug = req.param("slug");
        \\     val title = postTitle(slug);
        \\     val theme = cookies().get("theme").unwrapOr("system");
        \\     val relatedKey = memoKey("relatedCount", [slug]);
        \\     val _started = preload(relatedKey, { ->
        \\         loadRelatedCount(slug);
        \\     });
        \\     val post = getPost(slug);
        \\     val related = memoize(relatedKey, { ->
        \\         loadRelatedCount(slug);
        \\     });
        \\     return out.write(title + ": " + post.body + " (" + related.toString() + " related, " + theme + ")");
        \\ });
        , "GET /en/blog/hello Cookie: theme=dark");
}
```

`examples/blog-server/test/__snapshots__/blog-server/a-post-render-reads-the-theme-cookie-and-memoizes-the-post-once.snap`
```
phase: Render
cookies:
theme=dark
headers:
cookie: theme=dark
memo:
getPost[hello] miss
relatedCount[hello] miss
getPost[hello] hit
relatedCount[hello] hit
after:
```

### `blog-server: a missing post signals not-found from inside the render`

```bp
test "blog-server: a missing post signals not-found from inside the render" {
    try assertNavigation(@src(),
        \\ import {notFound, redirect} from "rakun";
        \\ import {page, ChunkWriter, Request} from "rakun";
        \\
        \\ pub type Post(slug: string, title: string, body: string)
        \\
        \\ #[@result]
        \\ fn findPost(slug: string) -> @Result<Post, string> {
        \\     if (slug == "hello") {
        \\         return Post(slug: "hello", title: "Hello", body: "first post");
        \\     };
        \\     throw "no such post: " + slug;
        \\ }
        \\
        \\ val _post = page("[locale]/blog/[slug]", fn(req: Request, out: ChunkWriter) {
        \\     val found = findPost(req.param("slug"));
        \\     if (found.isError()) {
        \\         val _gone = notFound();
        \\     };
        \\     val post = found.unwrapOr(Post(slug: "", title: "", body: ""));
        \\     return out.write(post.title + ": " + post.body);
        \\ });
        , "GET /en/blog/missing");
}
```

`examples/blog-server/test/__snapshots__/blog-server/a-missing-post-signals-not-found-from-inside-the-render.snap`
```
signal notFound
status 404
location -
```

### `blog-server: the locale is negotiated from accept-language and the prefix is redirected in`

```bp
test "blog-server: the locale is negotiated from accept-language and the prefix is redirected in" {
    try assertLocale(@src(),
        [
            "locales=pt-BR,en,es",
            "default=pt-BR",
            "exclude=/api/:path*,/dashboard/:path*,/sitemap.xml,/robots.txt",
        ],
        "GET /blog/hello Accept-Language: en-US,en;q=0.8,pt;q=0.5");
}
```

`examples/blog-server/test/__snapshots__/blog-server/the-locale-is-negotiated-from-accept-language-and-the-prefix-is-redirected-in.snap`
```
negotiated en from accept-language
redirect 307 /en/blog/hello
```

### `blog-server: url rules canonicalize, redirect and rewrite before the route match`

```bp
test "blog-server: url rules canonicalize, redirect and rewrite before the route match" {
    try assertUrlRules(@src(),
        [
            "basePath=",
            "trailingSlash=false",
            "redirect /old -> /new permanent",
            "redirect /blog/:slug -> /en/blog/:slug",
            "rewrite /shop/:path* -> /catalog/:path*",
            "rewrite /api/external/:path* -> https://api.example.com/:path*",
            "allowedOrigins=https://api.example.com",
        ],
        ["/old", "/blog/hello", "/shop/hats", "/api/external/v1/x", "/en/blog/hello/", "/a%252Fb"]);
}
```

`examples/blog-server/test/__snapshots__/blog-server/url-rules-canonicalize-redirect-and-rewrite-before-the-route-match.snap`
```
/old -> redirect 308 /new
/blog/hello -> redirect 307 /en/blog/hello
/shop/hats -> rewrite /catalog/hats
/api/external/v1/x -> rewrite https://api.example.com/v1/x
/en/blog/hello/ -> redirect 308 /en/blog/hello
/a%252Fb -> pass
```

### `blog-server: the sitemap is served from the tree with every post`

```bp
test "blog-server: the sitemap is served from the tree with every post" {
    try assertMetadataRoutes(@src(),
        [
            "app/layout.bp",
            "app/sitemap.bp",
            "app/robots.bp",
            "app/manifest.bp",
            "app/favicon.ico",
            "app/icon.png",
            "app/opengraph-image.png",
            "app/[locale]/blog/[slug]/opengraph-image.bp",
        ],
        "GET /sitemap.xml");
}
```

`examples/blog-server/test/__snapshots__/blog-server/the-sitemap-is-served-from-the-tree-with-every-post.snap`
```
/sitemap.xml -> 200 application/xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url><loc>https://example.com/</loc><lastmod>2026-03-01</lastmod><changefreq>daily</changefreq><priority>1.0</priority></url>
<url><loc>https://example.com/en/blog/hello</loc><lastmod>2026-01-01</lastmod><changefreq>weekly</changefreq><priority>0.7</priority></url>
</urlset>
```

### `blog-server: fingerprinted assets are immutable, public files revalidate and traversal is refused`

```bp
test "blog-server: fingerprinted assets are immutable, public files revalidate and traversal is refused" {
    try assertStatic(@src(),
        [
            "dist/app.7f3a91.css: body{margin:0}",
            "public/index.html: <h1>hi</h1>",
            "public/logo.svg: <svg/>",
        ],
        [
            "GET /_assets/app.7f3a91.css",
            "GET /public/",
            "GET /public/logo.svg If-None-Match: \"d4dc56669143034f31aa309635d4113d9ad76a02b1739da22c965ed2049be9e6\"",
            "GET /public/../secret",
        ]);
}
```

`examples/blog-server/test/__snapshots__/blog-server/fingerprinted-assets-are-immutable-public-files-revalidate-and-traversal-is-refused.snap`
```
200 text/css; charset=utf-8 etag="2007703776e20c24376ebae0a759bc90112c3d0632a9f44428e11f7a8444a297" cache-control=public, max-age=31536000, immutable
200 text/html; charset=utf-8 etag="e7fbb6fbbf4ce294913eb62b53ff03a7546649cfdc0d824d9e3a2b4541502f7f" cache-control=no-cache
304 image/svg+xml etag="d4dc56669143034f31aa309635d4113d9ad76a02b1739da22c965ed2049be9e6" cache-control=no-cache
404 - etag=- cache-control=-
```

### `blog-server: the product list is cached by tag and repricing revalidates it`

```bp
test "blog-server: the product list is cached by tag and repricing revalidates it" {
    try assertCache(@src(),
        \\ import {cachePolicy, cacheThrough, cacheLife, cacheLifeOf, CacheScope} from "rakun-cache";
        \\ import {revalidateTag, updateTag, revalidatePath} from "rakun-cache";
        \\
        \\ fn loadProductsJson(page: string) -> string {
        \\     return "{\"page\":\"" + page + "\",\"items\":[]}";
        \\ }
        \\
        \\ fn loadPrice(productId: string, currency: string) -> string {
        \\     return "{\"id\":\"" + productId + "\",\"currency\":\"" + currency + "\"}";
        \\ }
        \\
        \\ fn writePrice(productId: string, cents: string) -> string {
        \\     return cents;
        \\ }
        \\
        \\ pub fn productsJson(page: string) -> string {
        \\     val policy = cachePolicy(CacheScope.Shared, "products", cacheLife("hours"), ["products", "catalog"]);
        \\     return cacheThrough(policy, ["productsJson", page], { -> loadProductsJson(page) });
        \\ }
        \\
        \\ pub fn priceJson(productId: string, currency: string) -> string {
        \\     val life = cacheLifeOf(60, 600, 3600);
        \\     val policy = cachePolicy(CacheScope.Remote, "prices", life, ["price-" + productId]);
        \\     return cacheThrough(policy, ["priceJson", productId, currency], { -> loadPrice(productId, currency) });
        \\ }
        \\
        \\ pub fn repriceProduct(productId: string, cents: string) -> string {
        \\     val written = writePrice(productId, cents);
        \\     val _now = updateTag("price-" + productId);
        \\     val _soon = revalidateTag("products");
        \\     val _path = revalidatePath("/en/products/" + productId);
        \\     val readBack = priceJson(productId, "BRL");
        \\     return "{\"written\":" + written + ",\"readBack\":" + readBack + "}";
        \\ }
        , ["productsJson(1)", "productsJson(1)", "priceJson(p-1, BRL)", "repriceProduct(p-1, 999)", "productsJson(1)"]);
}
```

`examples/blog-server/test/__snapshots__/blog-server/the-product-list-is-cached-by-tag-and-repricing-revalidates-it.snap`
```
productsJson(1) -> miss key=products:productsJson:1 [products, catalog]
productsJson(1) -> hit key=products:productsJson:1 [products, catalog]
priceJson(p-1, BRL) -> miss key=prices:priceJson:p-1:BRL [price-p-1]
repriceProduct(p-1, 999) -> evict key=price-p-1 [price-p-1]
repriceProduct(p-1, 999) -> revalidate key=products [products]
repriceProduct(p-1, 999) -> revalidate key=/en/products/p-1 [path]
priceJson(p-1, BRL) -> miss key=prices:priceJson:p-1:BRL [price-p-1]
productsJson(1) -> revalidate key=products:productsJson:1 [products, catalog]
```

## `examples/order-pipeline`

**Fronts:** 15 · 16 · 83 · 84 · 85 · 86 · 89 · 90 · **Depends on:** `rakun-messaging`, `rakun-tx`, `rakun-stream`, `rakun-scheduling`, `rakun-mail`, `rakun-data` · **Tests:** `examples/order-pipeline/test/order-pipeline_test.bp` · **Snapshots:** `examples/order-pipeline/test/__snapshots__/order-pipeline/` · **Target:** erlang

> helper gap: `assertRetry` needs the module-level default policy behind `rakun.messaging.listener.<name>.retry.max-attempts` (initial delay and multiplier are not keys in 86 § Step 1) — the `+<ms>` column below assumes the 500 ms / 200 % defaults the README's `retryPolicy` example uses.

```
examples/order-pipeline/
├── botopink.json          dependencies: rakun-messaging · rakun-tx · rakun-stream · rakun-scheduling · rakun-mail · rakun-data
├── application.yaml       rakun.datasource.url ets:memory · rakun.messaging.amqp.host · rakun.messaging.kafka.bootstrap-servers · rakun.messaging.listener.orders.concurrency 1 · rakun.messaging.listener.orders-confirm.retry.max-attempts 3 · rakun.mail.{host,port,username,password} · app.housekeeping.retention-millis 86400000
├── src/main.bp            autoConfigure() · Rakun.run(App(port: 8080, basePath: "/api"))
├── src/orders.bp          OrderRepo · Orders (#[transactional] place → publishAfterCommit) · Shipping (onceOnly) · shippingListener (#[messageListener("order.placed")])
├── src/listeners.bp       OrderService (AmqpTemplate · KafkaTemplate) · OrderListeners (#[listener] · #[amqpListener("orders")] · #[kafkaListener("order-events", "order-service")])
├── src/confirmations.bp   chargeCard (#[@result]) · classifyOrder · OrderConfirmations (#[rabbitListener("orders.confirm")])
├── src/booking.bp         bookingSaga() -> Saga (reserve-seat · charge-card · issue-ticket) · Bookings
├── src/billing.bp         InvoiceRepo · Billing (#[persistentJob("nightly-invoices", "0 3 * * *")] · #[scheduled("*/5 * * * *")]) · nightlyInvoiceTrigger
├── src/housekeeping.bp    SessionRepo · HousekeepingService (#[scheduler] · #[scheduled("0 0 * * * *")] · #[fixedRate(5000)] · #[fixedDelay(30000)])
├── src/mail.bp            MailConfig (#[bean] smtp · #[healthIndicator("mail")]) · resetBody · resetText · ResetMailer
├── src/pipeline.bp        ordersPipeline (Source.Queue orders.paid · Filter · Transform · Split · Transform · Sink.Publish orders.normalised)
└── src/shipping.bp        classifyShipment · ShippingListener (#[jmsListener("shipping.requests")]) · ShippingClient
```

### `order-pipeline: the amqp and kafka listeners register and deliveries are acknowledged`

```bp
test "order-pipeline: the amqp and kafka listeners register and deliveries are acknowledged" {
    try assertListener(@src(),
        \\ import {service, component} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {listener, amqpListener, kafkaListener} from "rakun-messaging";
        \\ import {Message, AmqpTemplate, KafkaTemplate, rkRegisterListener} from "rakun-messaging";
        \\
        \\ #[service]
        \\ pub type OrderService(
        \\     amqp: AmqpTemplate,
        \\     kafka: KafkaTemplate,
        \\ ) {
        \\     pub fn place(self: Self, payload: string) -> i32 {
        \\         val accepted = self.kafka.send("order-events", "placed", payload);
        \\         return accepted;
        \\     }
        \\
        \\     pub fn record(self: Self, key: string, payload: string) -> i32 {
        \\         return if (payload == "") 1 else 0;
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[listener]
        \\ pub type OrderListeners(
        \\     orders: OrderService,
        \\ ) {
        \\     #[amqpListener("orders")]
        \\     pub fn onOrderPlaced(self: Self, msg: Message) -> i32 {
        \\         return self.orders.place(msg.payload);
        \\     }
        \\
        \\     #[kafkaListener("order-events", "order-service")]
        \\     pub fn onOrderEvent(self: Self, msg: Message) -> i32 {
        \\         return self.orders.record(msg.key, msg.payload);
        \\     }
        \\ }
        , [
            "amqp orders {\"orderId\":\"o-1\"}",
            "kafka order-events placed {\"orderId\":\"o-1\"}",
            "kafka order-events placed ",
        ]);
}
```

`examples/order-pipeline/test/__snapshots__/order-pipeline/the-amqp-and-kafka-listeners-register-and-deliveries-are-acknowledged.snap`
```
listener order-events -> OrderListeners.onOrderEvent broker=kafka
listener orders -> OrderListeners.onOrderPlaced broker=amqp
deliver orders {"orderId":"o-1"} -> ok
deliver order-events {"orderId":"o-1"} -> ok
deliver order-events  -> nack
```

### `order-pipeline: housekeeping tasks fire on the fixed clock by trigger kind`

```bp
test "order-pipeline: housekeeping tasks fire on the fixed clock by trigger kind" {
    try assertSchedule(@src(),
        \\ import {service, repository} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {scheduler, scheduled, fixedRate, fixedDelay} from "rakun-scheduling";
        \\ import {rkScheduleCron, rkScheduleFixedRate, rkScheduleFixedDelay, rkRunTaskNow} from "rakun-scheduling";
        \\ import {value} from "rakun";
        \\ import {io.clock} from "std";
        \\
        \\ #[repository]
        \\ pub type SessionRepo {
        \\     pub fn deleteExpired(self: Self, beforeMillis: i64) -> i32 {
        \\         return 0;
        \\     }
        \\
        \\     pub fn count(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[scheduler]
        \\ pub type HousekeepingService(
        \\     sessions: SessionRepo,
        \\     #[value("app.housekeeping.retention-millis")]
        \\     retentionMillis: i32,
        \\ ) {
        \\     #[scheduled("0 0 * * * *")]
        \\     pub fn pruneSessions(self: Self) -> i32 {
        \\         val cutoff = clock.nowMillis() - self.retentionMillis;
        \\         return self.sessions.deleteExpired(cutoff);
        \\     }
        \\
        \\     #[fixedRate(5000)]
        \\     pub fn heartbeat(self: Self) -> i32 {
        \\         return self.sessions.count();
        \\     }
        \\
        \\     #[fixedDelay(30000)]
        \\     pub fn compact(self: Self) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , [
            "2026-01-01T00:00:00Z",
            "2026-01-01T00:00:05Z",
            "2026-01-01T00:00:10Z",
            "2026-01-01T00:00:30Z",
            "2026-01-01T01:00:00Z",
        ]);
}
```

`examples/order-pipeline/test/__snapshots__/order-pipeline/housekeeping-tasks-fire-on-the-fixed-clock-by-trigger-kind.snap`
```
task HousekeepingService.compact fixedDelay 30000
task HousekeepingService.heartbeat fixedRate 5000
task HousekeepingService.pruneSessions cron 0 0 * * * *
2026-01-01T00:00:00Z fire HousekeepingService.pruneSessions
2026-01-01T00:00:00Z fire HousekeepingService.heartbeat
2026-01-01T00:00:00Z fire HousekeepingService.compact
2026-01-01T00:00:05Z fire HousekeepingService.heartbeat
2026-01-01T00:00:10Z fire HousekeepingService.heartbeat
2026-01-01T00:00:30Z fire HousekeepingService.heartbeat
2026-01-01T00:00:30Z fire HousekeepingService.compact
2026-01-01T01:00:00Z fire HousekeepingService.pruneSessions
2026-01-01T01:00:00Z fire HousekeepingService.heartbeat
2026-01-01T01:00:00Z fire HousekeepingService.compact
```

### `order-pipeline: a placed order enrols its event in the outbox and a raise leaves nothing`

```bp
test "order-pipeline: a placed order enrols its event in the outbox and a raise leaves nothing" {
    try assertOutbox(@src(),
        \\ import {service, repository} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {transactional, SqlTemplate} from "rakun-data";
        \\ import {OutboxMessage, publishAfterCommit} from "rakun-tx";
        \\
        \\ #[repository]
        \\ pub type OrderRepo(
        \\     sql: SqlTemplate,
        \\ ) {
        \\     pub fn insert(self: Self, id: string, customer: string, cents: i32) -> i32 {
        \\         return self.sql.update(
        \\             "insert into orders (id, customer, cents) values ($1, $2, $3)",
        \\             [id, customer, cents.toString()],
        \\         );
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
        \\         val headers = [
        \\             #("content-type", "application/json"),
        \\             #("order-id", id),
        \\         ];
        \\         val payload = "{\"id\":\"" + id + "\",\"customer\":\"" + customer + "\",\"cents\":" + cents.toString() + "}";
        \\         val event = OutboxMessage(
        \\             aggregate: "order:" + id,
        \\             topic: "order.placed",
        \\             key: id,
        \\             payload: payload,
        \\             headers: headers,
        \\         );
        \\         publishAfterCommit(event);
        \\         if (cents == 0) {
        \\             throw "an order must cost something";
        \\         };
        \\         return id;
        \\     }
        \\ }
        , ["OrdersTx.place(o-1, ana, 1250)", "relay", "OrdersTx.place(o-2, bob, 0)", "relay"]);
}
```

`examples/order-pipeline/test/__snapshots__/order-pipeline/a-placed-order-enrols-its-event-in-the-outbox-and-a-raise-leaves-nothing.snap`
```
write orders
write rakun_outbox
outbox 1 pending
relay -> published order.placed
outbox 0 pending
outbox 0 pending
relay -> published nothing
outbox 0 pending
```

### `order-pipeline: a failed charge compensates the reserved seat in reverse`

```bp
test "order-pipeline: a failed charge compensates the reserved seat in reverse" {
    try assertSaga(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Saga, SagaStep, SagaState, startSaga, sagaState} from "rakun-tx";
        \\ import {sagaHistory, sagaStatus} from "rakun-tx";
        \\
        \\ pub fn bookingSaga() -> Saga {
        \\     val steps = [
        \\         SagaStep(
        \\             name: "reserve-seat",
        \\             run: { ctx -> "seat:" + ctx },
        \\             compensate: { ctx -> "released:" + ctx },
        \\         ),
        \\         SagaStep(
        \\             name: "charge-card",
        \\             run: { ctx -> throw "card declined" },
        \\             compensate: { ctx -> "refunded:" + ctx },
        \\         ),
        \\         SagaStep(
        \\             name: "issue-ticket",
        \\             run: { ctx -> "ticket:" + ctx },
        \\             compensate: { ctx -> "voided:" + ctx },
        \\         ),
        \\     ];
        \\     return Saga(
        \\         name: "booking",
        \\         steps: steps,
        \\         retries: 0,
        \\         backoffMs: 0,
        \\     );
        \\ }
        \\
        \\ #[service]
        \\ pub type Bookings {
        \\     pub fn book(self: Self, customer: string, showing: string) -> string {
        \\         val ctx = "customer=" + customer + "&showing=" + showing;
        \\         return startSaga(bookingSaga(), ctx);
        \\     }
        \\ }
        , ["Bookings.book(ana, 21:00)"]);
}
```

`examples/order-pipeline/test/__snapshots__/order-pipeline/a-failed-charge-compensates-the-reserved-seat-in-reverse.snap`
```
step reserve-seat ok
step charge-card failed
compensate reserve-seat
```

### `order-pipeline: the nightly invoice job is acquired once and reclaimed after a dead lease`

```bp
test "order-pipeline: the nightly invoice job is acquired once and reclaimed after a dead lease" {
    try assertJobStore(@src(),
        \\ import {service, repository} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {SqlTemplate} from "rakun-data";
        \\ import {persistentJob, Trigger, MisfirePolicy, registerTrigger} from "rakun-scheduling";
        \\ import {jobData, jobField, jobHistory, jobStatus} from "rakun-scheduling";
        \\
        \\ #[repository]
        \\ pub type InvoiceRepo(
        \\     sql: SqlTemplate,
        \\ ) {
        \\     pub fn billPeriod(self: Self, period: string) -> i32 {
        \\         return self.sql.update(
        \\             "insert into invoices (period, state) select $1, 'draft' where not exists (select 1 from invoices where period = $1)",
        \\             [period],
        \\         );
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type Billing(
        \\     invoices: InvoiceRepo,
        \\ ) {
        \\     #[persistentJob("nightly-invoices", "0 3 * * *")]
        \\     pub fn runInvoices(self: Self, data: string) -> string {
        \\         val period = jobField(data, "period");
        \\         val billed = self.invoices.billPeriod(period);
        \\         return "billed=" + billed.toString();
        \\     }
        \\ }
        \\
        \\ pub fn nightlyInvoiceTrigger() -> Trigger {
        \\     return Trigger(
        \\         name: "nightly-invoices",
        \\         job: "nightly-invoices",
        \\         cron: "0 3 * * *",
        \\         startAt: 0,
        \\         endAt: 0,
        \\         misfire: MisfirePolicy.FireAll,
        \\         retries: 3,
        \\         backoffMs: 2000,
        \\     );
        \\ }
        \\
        \\ pub fn registerBillingSchedule() -> i32 {
        \\     return registerTrigger(nightlyInvoiceTrigger(), jobData([#("period", "current")]));
        \\ }
        , [
            "registerBillingSchedule",
            "advance 2026-01-01T03:00:00Z",
            "tick node-a",
            "kill node-a",
            "advance +lease",
            "tick node-b",
            "complete node-b",
        ]);
}
```

`examples/order-pipeline/test/__snapshots__/order-pipeline/the-nightly-invoice-job-is-acquired-once-and-reclaimed-after-a-dead-lease.snap`
```
job nightly-invoices state=waiting owner=-
job nightly-invoices state=waiting owner=-
job nightly-invoices state=acquired owner=node-a
job nightly-invoices state=acquired owner=node-a
job nightly-invoices state=waiting owner=-
job nightly-invoices state=acquired owner=node-b
job nightly-invoices state=waiting owner=-
```

### `order-pipeline: the reset mail is a multipart alternative with the html body`

```bp
test "order-pipeline: the reset mail is a multipart alternative with the html body" {
    try assertMail(@src(),
        \\ import {configuration, bean, value, service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {escape} from "std";
        \\ import {MailServer, TlsMode, Mail, Attachment, mailer, send} from "rakun-mail";
        \\
        \\ #[configuration]
        \\ pub type MailConfig(
        \\     #[value("rakun.mail.host")] host: string,
        \\     #[value("rakun.mail.port")] port: i32,
        \\     #[value("rakun.mail.username")] username: string,
        \\     #[value("rakun.mail.password")] password: string,
        \\ ) {
        \\     #[bean]
        \\     pub fn smtp(self: Self) -> MailServer {
        \\         return MailServer(
        \\             host: self.host,
        \\             port: self.port,
        \\             username: self.username,
        \\             password: self.password,
        \\             tlsMode: TlsMode.StartTls,
        \\             bundle: "smtp",
        \\             connectTimeoutMs: 5000,
        \\             readTimeoutMs: 3000,
        \\             writeTimeoutMs: 5000,
        \\         );
        \\     }
        \\ }
        \\
        \\ pub fn resetText(displayName: string, resetUrl: string) -> string {
        \\     return "Hello, " + displayName + ". Open " + resetUrl + " to choose a new password.";
        \\ }
        \\
        \\ pub fn resetBody(displayName: string, resetUrl: string) -> string {
        \\     val safeName = escape.html(displayName);
        \\     return "<div><h1>Password reset</h1><p>Hello, " + safeName + ".</p>"
        \\         + "<p>Open this link to choose a new password:</p><p>" + resetUrl + "</p>"
        \\         + "<p>If you did not ask for this, nothing has changed.</p></div>";
        \\ }
        \\
        \\ #[service]
        \\ pub type ResetMailer(
        \\     server: MailServer,
        \\ ) {
        \\     pub fn deliver(self: Self, to: string, displayName: string, url: string) -> string {
        \\         val recipients = [to];
        \\         val none: string[] = [];
        \\         val noAttachments: Attachment[] = [];
        \\         val extraHeaders: Array<#(string, string)> = [];
        \\         val m = Mail(
        \\             from: "Shop <no-reply@shop.example>",
        \\             to: recipients,
        \\             cc: none,
        \\             bcc: none,
        \\             replyTo: "",
        \\             subject: "Reset your password",
        \\             text: resetText(displayName, url),
        \\             html: resetBody(displayName, url),
        \\             attachments: noAttachments,
        \\             headers: extraHeaders,
        \\         );
        \\         return send(mailer(self.server), m);
        \\     }
        \\ }
        , "ResetMailer.deliver(ana@example.org, Ana, https://shop.example/reset?t=tok-0001)");
}
```

`examples/order-pipeline/test/__snapshots__/order-pipeline/the-reset-mail-is-a-multipart-alternative-with-the-html-body.snap`
```
Content-Type: multipart/alternative; boundary="boundary-0001"
Date: Thu, 01 Jan 2026 00:00:00 +0000
From: Shop <no-reply@shop.example>
MIME-Version: 1.0
Message-ID: <msg-0001@shop.example>
Subject: Reset your password
To: ana@example.org

--boundary-0001
Content-Type: text/plain; charset=utf-8

Hello, Ana. Open https://shop.example/reset?t=tok-0001 to choose a new password.
--boundary-0001
Content-Type: text/html; charset=utf-8

<div><h1>Password reset</h1><p>Hello, Ana.</p><p>Open this link to choose a new password:</p><p>https://shop.example/reset?t=tok-0001</p><p>If you did not ask for this, nothing has changed.</p></div>
--boundary-0001--
```

### `order-pipeline: a confirmation that keeps failing is retried to the ceiling then dead-lettered`

```bp
test "order-pipeline: a confirmation that keeps failing is retried to the ceiling then dead-lettered" {
    try assertRetry(@src(),
        [
            "rakun.messaging.listener.orders-confirm.retry.max-attempts=3",
            "rakun.messaging.listener.orders-confirm.dead-letter=orders.confirm.failed",
        ],
        [
            "retry payment gateway timeout",
            "retry payment gateway timeout",
            "retry payment gateway timeout",
        ]);
}
```

`examples/order-pipeline/test/__snapshots__/order-pipeline/a-confirmation-that-keeps-failing-is-retried-to-the-ceiling-then-dead-lettered.snap`
```
attempt 1 at +0ms -> fail
attempt 2 at +500ms -> fail
attempt 3 at +1500ms -> fail
dead-letter orders.confirm.failed
```

### `order-pipeline: paid orders are split per sku and normalised through the pipeline graph`

```bp
test "order-pipeline: paid orders are split per sku and normalised through the pipeline graph" {
    try assertStream(@src(),
        \\ import {Stage, Pipeline, Source, Sink, runStages, graphOf} from "rakun-stream";
        \\
        \\ val stages: Array<Stage> = [
        \\     Stage.Filter(name: "paid-only", keep: { item -> item.startsWith("paid:") }),
        \\     Stage.Transform(name: "strip-prefix", apply: { item -> item.replace("paid:", "") }),
        \\     Stage.Split(name: "one-per-sku", explode: { item -> item.split(",") }),
        \\     Stage.Transform(name: "normalise", apply: { item -> item.trim().toUpper() }),
        \\ ];
        \\
        \\ val ordersPipeline = Pipeline(
        \\     name: "orders",
        \\     source: Source.Queue(destination: "orders.paid", prefetch: 32),
        \\     stages: stages,
        \\     sink: Sink.Publish(destination: "orders.normalised"),
        \\ );
        , ["paid:hat, cap", "unpaid:shoe", "paid: sock "]);
}
```

`examples/order-pipeline/test/__snapshots__/order-pipeline/paid-orders-are-split-per-sku-and-normalised-through-the-pipeline-graph.snap`
```
graph:
orders.paid -> paid-only
paid-only -> strip-prefix
strip-prefix -> one-per-sku
one-per-sku -> normalise
normalise -> orders.normalised
out orders.normalised HAT
out orders.normalised CAP
out orders.normalised SOCK
```

### `order-pipeline: the jms shipping listener acks, retries and rejects by outcome`

```bp
test "order-pipeline: the jms shipping listener acks, retries and rejects by outcome" {
    try assertListener(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery, Outcome} from "rakun-messaging";
        \\ import {Destination, armFor, jmsSend, jmsRequest, jmsListener, selectorSupport, destinationName} from "rakun-messaging";
        \\
        \\ fn classifyShipment(delivery: Delivery) -> Outcome {
        \\     val order = delivery.header("order-id");
        \\     if (order == "") {
        \\         return Outcome.Reject(reason: "missing order-id header");
        \\     };
        \\     val body = delivery.body;
        \\     if (body == "") {
        \\         return Outcome.Retry(reason: "empty body, upstream may still be writing");
        \\     };
        \\     return Outcome.Done;
        \\ }
        \\
        \\ #[service]
        \\ type ShippingListener {
        \\     #[jmsListener("shipping.requests")]
        \\     pub fn onShipment(self: Self, delivery: Delivery) -> Outcome {
        \\         return classifyShipment(delivery);
        \\     }
        \\ }
        , [
            "jms shipping.requests order-id=o-1 | ship:o-1",
            "jms shipping.requests | ship:o-2",
            "jms shipping.requests order-id=o-3 | ",
        ]);
}
```

`examples/order-pipeline/test/__snapshots__/order-pipeline/the-jms-shipping-listener-acks-retries-and-rejects-by-outcome.snap`
```
listener shipping.requests -> ShippingListener.onShipment broker=jms
deliver shipping.requests ship:o-1 -> ok
deliver shipping.requests ship:o-2 -> dead-letter
deliver shipping.requests  -> nack
```

## `examples/observed-service`

**Fronts:** 11 · 12 · 13 · 17 · 21 · 75 · 76 · 87 · **Depends on:** `rakun-actuator`, `rakun-metrics`, `rakun-logging`, `rakun-cache`, `rakun-client`, `rakun-hateoas` · **Tests:** `examples/observed-service/test/observed-service_test.bp` · **Snapshots:** `examples/observed-service/test/__snapshots__/observed-service/` · **Target:** erlang

```
examples/observed-service/
├── botopink.json          dependencies: rakun-actuator · rakun-metrics · rakun-logging · rakun-cache · rakun-client · rakun-hateoas
├── application.yaml       rakun.endpoints.web.exposure.include health,info,metrics,prometheus,httpexchanges · rakun.endpoints.access.max-permitted read-only · rakun.metrics.tags.region us-east-1 · rakun.metrics.export.prometheus.enabled true · rakun.tracing.sampling.probability 1.0 · rakun.logging.structured.format.console plain · rakun.cache.type ets · rakun.cache.names products · app.partner.{base-url https://partner.example.com, token test-token} · rakun.http.serviceclient.shipping.base-url https://shipping.internal · rakun.management.httpexchanges.recording.{enabled true, include request-headers}
├── src/main.bp            autoConfigure() · Rakun.run(App(port: 8080, basePath: "/api"))
├── src/partner.bp         PartnerClientConfig (#[configuration] · #[bean] partnerClient RestClient.builder()) · PartnerCatalog · ShippingApi (#[httpExchange("shipping")] · #[getExchange]) · ShippingConfig
├── src/catalog.bp         ProductCatalog (#[cached] behavior · #[cacheable("products")] · #[cacheEvict("products", true)]) · SqlProductCatalog · CatalogConfig
├── src/settlement.bp      SettlementService (timed · counter · MeterRegistry) · PricingClient · QuoteController (#[route("/api")] · startSpan/endSpan · GET /quote/:sku · GET /whoami)
├── src/users.bp           UserResource (#[halResource]) · UserRepo · UserResources · UserController (#[route("/api/users")])
└── src/health.bp          QueueRepository · WorkQueueHealth (#[healthIndicator("workQueue")]) · DeploymentInfo (#[infoContributor("deployment")]) · QueueEndpoint (#[endpoint("queue")])
```

### `observed-service: the actuator registry lists the health indicator, the info contributor and the endpoint`

```bp
test "observed-service: the actuator registry lists the health indicator, the info contributor and the endpoint" {
    try assertRegistry(@src(),
        \\ import {Request} from "rakun";
        \\ import {service, repository} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {managed} from "rakun";
        \\ import {Health, HealthIndicator, InfoContributor, Endpoint, EndpointResponse} from "rakun-actuator-api";
        \\ import {healthIndicator, infoContributor, endpoint} from "rakun-actuator-api";
        \\ import {rkRegisterHealthIndicator, rkRegisterInfoContributor, rkRegisterEndpoint} from "rakun-actuator-api";
        \\
        \\ #[repository]
        \\ #[managed]
        \\ pub type QueueRepository {
        \\     pub fn depth(self: Self) -> i32 {
        \\         return 12;
        \\     }
        \\
        \\     pub fn oldestAgeSeconds(self: Self) -> i32 {
        \\         return 4;
        \\     }
        \\ }
        \\
        \\ #[healthIndicator("workQueue")]
        \\ #[managed]
        \\ pub type WorkQueueHealth(
        \\     queue: QueueRepository,
        \\ ) {
        \\     pub fn check(self: Self) -> Health {
        \\         val depth = self.queue.depth();
        \\         val oldest = self.queue.oldestAgeSeconds();
        \\         val backedUp = depth > 1000;
        \\         val stale = oldest > 300;
        \\         val unhealthy = backedUp || stale;
        \\         val status = if (unhealthy) "DOWN" else "UP";
        \\         return Health(
        \\             status: status,
        \\             details: "{\"depth\": ${depth}, \"oldestAgeSeconds\": ${oldest}}",
        \\         );
        \\     }
        \\ }
        \\
        \\ #[infoContributor("deployment")]
        \\ #[managed]
        \\ pub type DeploymentInfo {
        \\     pub fn contribute(self: Self) -> string {
        \\         return "{\"deployment\": {\"region\": \"eu-west-1\", \"replica\": \"blue\"}}";
        \\     }
        \\ }
        \\
        \\ #[endpoint("queue")]
        \\ #[managed]
        \\ pub type QueueEndpoint(
        \\     queue: QueueRepository,
        \\ ) implement Endpoint {
        \\     pub fn id(self: Self) -> string {
        \\         return "queue";
        \\     }
        \\
        \\     pub fn read(self: Self, req: Request) -> EndpointResponse {
        \\         val depth = self.queue.depth();
        \\         val oldest = self.queue.oldestAgeSeconds();
        \\         return EndpointResponse(
        \\             status: 200,
        \\             contentType: "application/json",
        \\             body: "{\"depth\": ${depth}, \"oldestAgeSeconds\": ${oldest}}",
        \\         );
        \\     }
        \\ }
        );
}
```

`examples/observed-service/test/__snapshots__/observed-service/the-actuator-registry-lists-the-health-indicator-the-info-contributor-and-the-endpoint.snap`
```
health workQueue
info deployment
endpoint queue [read]
```

### `observed-service: the cached catalog hits on the second read and repricing evicts every entry`

```bp
test "observed-service: the cached catalog hits on the second read and repricing evicts every entry" {
    try assertCache(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {value} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp} from "rakun";
        \\ import {cached, cacheable, cacheEvict} from "rakun-cache";
        \\ import {cacheThrough, cachePolicy, cacheLife, CacheScope, cacheKey} from "rakun-cache";
        \\ import {rkCacheEnabled, rkCacheLookup, rkCachePut, rkCacheEvict, rkCacheClear} from "rakun-cache";
        \\
        \\ #[cached]
        \\ pub behavior ProductCatalog {
        \\     #[cacheable("products")]
        \\     fn productJson(self: Self, id: string) -> string;
        \\
        \\     #[cacheable("products")]
        \\     fn listJson(self: Self, page: string) -> string;
        \\
        \\     #[cacheEvict("products", true)]
        \\     fn reprice(self: Self, id: string, body: string) -> string;
        \\
        \\     fn slugFor(self: Self, id: string) -> string;
        \\ }
        \\
        \\ #[service]
        \\ pub type SqlProductCatalog(
        \\     #[value("app.catalog.currency")]
        \\     currency: string,
        \\ ) implement ProductCatalog {
        \\     pub fn productJson(self: Self, id: string) -> string {
        \\         return "{\"id\":\"" + id + "\",\"currency\":\"" + self.currency + "\"}";
        \\     }
        \\
        \\     pub fn listJson(self: Self, page: string) -> string {
        \\         return "{\"page\":\"" + page + "\",\"items\":[]}";
        \\     }
        \\
        \\     pub fn reprice(self: Self, id: string, body: string) -> string {
        \\         return "{\"id\":\"" + id + "\",\"repriced\":true,\"body\":\"" + body + "\"}";
        \\     }
        \\
        \\     pub fn slugFor(self: Self, id: string) -> string {
        \\         return "product-" + id;
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
        , ["productJson(p-1)", "productJson(p-1)", "listJson(1)", "reprice(p-1, {})", "productJson(p-1)"]);
}
```

`examples/observed-service/test/__snapshots__/observed-service/the-cached-catalog-hits-on-the-second-read-and-repricing-evicts-every-entry.snap`
```
productJson(p-1) -> miss key=products:productJson:p-1 []
productJson(p-1) -> hit key=products:productJson:p-1 []
listJson(1) -> miss key=products:listJson:1 []
reprice(p-1, {}) -> evict key=products:* []
productJson(p-1) -> miss key=products:productJson:p-1 []
```

### `observed-service: the partner client sends its default headers and the exchange client its base url`

```bp
test "observed-service: the partner client sends its default headers and the exchange client its base url" {
    try assertClient(@src(),
        \\ import {service, configuration, bean} from "rakun";
        \\ import {value} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {httpExchange, getExchange} from "rakun-client";
        \\ import {RestClient, RestClientBuilder, RequestSpec, ClientResponse} from "rakun-client";
        \\
        \\ #[configuration]
        \\ pub type PartnerClientConfig(
        \\     #[value("app.partner.base-url")]
        \\     baseUrl: string,
        \\     #[value("app.partner.token")]
        \\     token: string,
        \\ ) {
        \\     #[bean]
        \\     pub fn partnerClient(self: Self) -> RestClient {
        \\         return RestClient.builder()
        \\             .baseUrl(self.baseUrl)
        \\             .defaultHeader("accept", "application/json")
        \\             .defaultHeader("authorization", "Bearer " + self.token)
        \\             .readTimeout(2000)
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
        \\         val body = if (res.isOk()) { res.body } else { "{\"error\":" + res.status.toString() + "}" };
        \\         return body;
        \\     }
        \\ }
        \\
        \\ #[httpExchange("shipping")]
        \\ pub behavior ShippingApi {
        \\     #[getExchange("/shipments/:trackingId")]
        \\     fn shipment(self: Self, trackingId: string) -> string;
        \\ }
        \\
        \\ #[configuration]
        \\ pub type ShippingConfig {
        \\     #[bean]
        \\     pub fn shippingApi(self: Self) -> ShippingApi {
        \\         return httpShippingApi();
        \\     }
        \\ }
        , [
            "PartnerCatalog.productJson(p-1) -> 200 {\"id\":\"p-1\"}",
            "ShippingApi.shipment(t-1) -> 404",
        ]);
}
```

`examples/observed-service/test/__snapshots__/observed-service/the-partner-client-sends-its-default-headers-and-the-exchange-client-its-base-url.snap`
```
GET https://partner.example.com/products/p-1 -> 200
accept: application/json
authorization: Bearer test-token
traceparent: 00-00000000000000000000000000000001-0000000000000001-01
GET https://shipping.internal/shipments/t-1 -> 404
accept: application/json
traceparent: 00-00000000000000000000000000000001-0000000000000002-01
```

### `observed-service: plain lines follow the console layout with the seeded pid`

```bp
test "observed-service: plain lines follow the console layout with the seeded pid" {
    try assertLog(@src(),
        [
            "rakun.logging.structured.format.console=plain",
            "rakun.logging.level.root=info",
        ],
        [
            "info app.quotes quote assembled sku=hat",
            "warn app.quotes partner slow took.ms=812",
            "debug app.quotes dropped",
        ]);
}
```

`examples/observed-service/test/__snapshots__/observed-service/plain-lines-follow-the-console-layout-with-the-seeded-pid.snap`
```
2026-01-01T00:00:00.000Z  INFO <0.1.0> --- [observed-service] [main] app.quotes : quote assembled sku=hat
2026-01-01T00:00:00.000Z  WARN <0.1.0> --- [observed-service] [main] app.quotes : partner slow took.ms=812
```

### `observed-service: a user resource renders hal with its links first`

```bp
test "observed-service: a user resource renders hal with its links first" {
    try assertHal(@src(),
        \\ import {service, repository} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {halResource, Link, link, linkTo, halCollection, halResponse} from "rakun-hateoas";
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
        \\ #[repository]
        \\ pub type UserRepo {
        \\     pub fn find(self: Self, id: string) -> UserResource {
        \\         return UserResource(id: 1, name: "Ana", email: "ana@example.org", active: true);
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ pub type UserResources(
        \\     repo: UserRepo,
        \\ ) {
        \\     pub fn one(self: Self, id: string) -> string {
        \\         val user = self.repo.find(id);
        \\         val links: Array<Link> = [
        \\             linkTo("self", "/api/users/:id", [#("id", id)]),
        \\             linkTo("orders", "/api/users/:id/orders", [#("id", id)]),
        \\             link("collection", "/api/users"),
        \\         ];
        \\         return userResourceToHal(user, links);
        \\     }
        \\ }
        , "UserResources.one(1)");
}
```

`examples/observed-service/test/__snapshots__/observed-service/a-user-resource-renders-hal-with-its-links-first.snap`
```
_links: {"self":{"href":"/api/users/1"},"orders":{"href":"/api/users/1/orders"},"collection":{"href":"/api/users"}}
active: true
email: ana@example.org
id: 1
name: Ana
```

### `observed-service: settlements and rejections are exposed as prometheus text with the common tag`

```bp
test "observed-service: settlements and rejections are exposed as prometheus text with the common tag" {
    try assertMetrics(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt} from "rakun";
        \\ import {MeterRegistry, Tag, counter, gauge, timed, meterNames, prometheusText} from "rakun-metrics";
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
        \\         val _ = counter("orders.settled", tags).increment(1);
        \\         return settled;
        \\     }
        \\
        \\     pub fn reject(self: Self, reason: string) -> i32 {
        \\         return counter("orders.rejected", [Tag(key: "reason", value: reason)]).increment(1);
        \\     }
        \\ }
        , ["SettlementService.settle(12)", "SettlementService.settle(7)", "SettlementService.reject(fraud)"]);
}
```

`examples/observed-service/test/__snapshots__/observed-service/settlements-and-rejections-are-exposed-as-prometheus-text-with-the-common-tag.snap`
```
# TYPE orders_rejected_total counter
orders_rejected_total{reason="fraud",region="us-east-1"} 1
# TYPE orders_settled_total counter
orders_settled_total{currency="usd",region="us-east-1"} 2
# TYPE orders_settlement_seconds summary
orders_settlement_seconds_count{currency="usd",region="us-east-1"} 2
orders_settlement_seconds_sum{currency="usd",region="us-east-1"} 0
orders_settlement_seconds_max{currency="usd",region="us-east-1"} 0
```

### `observed-service: a quote request opens a server span, an internal span and a client span`

```bp
test "observed-service: a quote request opens a server span, an internal span and a client span" {
    try assertTrace(@src(),
        \\ import {service, restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkRegisterRoute} from "rakun";
        \\ import {traceId, spanId, parentSpanId, sampled, traceparent, startSpan, endSpan} from "rakun-metrics";
        \\ import {adoptTraceparent, exportedSpanCount} from "rakun-metrics";
        \\ import {RestClient} from "rakun-client";
        \\
        \\ #[service]
        \\ pub type PricingClient(
        \\     http: RestClient,
        \\ ) {
        \\     pub fn quote(self: Self, sku: string) -> string {
        \\         return self.http.getText("https://pricing.internal/quote/" + sku);
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
        \\         val _ = endSpan(span);
        \\         return Response.json(body);
        \\     }
        \\
        \\     #[getMapping("/whoami")]
        \\     pub fn whoami(self: Self, req: Request) -> Response {
        \\         return Response.json(traceId() + " " + spanId() + " " + sampled().toString());
        \\     }
        \\ }
        , "GET /api/quote/hat");
}
```

`examples/observed-service/test/__snapshots__/observed-service/a-quote-request-opens-a-server-span-an-internal-span-and-a-client-span.snap`
```
trace 00000000000000000000000000000001 spans:
http.server.request parent=- kind=server
quote.assemble parent=http.server.request kind=internal
http.client.request parent=quote.assemble kind=client
```

### `observed-service: the exposure list serves prometheus and hides env and shutdown`

```bp
test "observed-service: the exposure list serves prometheus and hides env and shutdown" {
    try assertExposure(@src(),
        [
            "rakun.endpoints.web.exposure.include=health,info,metrics,prometheus,httpexchanges",
            "rakun.endpoints.access.max-permitted=read-only",
            "rakun.endpoint.shutdown.access=unrestricted",
        ],
        ["/actuator/health", "/actuator/prometheus", "/actuator/httpexchanges", "/actuator/env", "/actuator/shutdown"]);
}
```

`examples/observed-service/test/__snapshots__/observed-service/the-exposure-list-serves-prometheus-and-hides-env-and-shutdown.snap`
```
/actuator/health -> 200 exposed
/actuator/prometheus -> 200 exposed
/actuator/httpexchanges -> 200 exposed
/actuator/env -> 404 hidden
/actuator/shutdown -> 404 hidden
```

### `observed-service: recorded exchanges keep the accept header and never the credentials`

```bp
test "observed-service: recorded exchanges keep the accept header and never the credentials" {
    try assertExchanges(@src(),
        \\ import {service, restController, route, getMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {traceId, spanId, sampled} from "rakun-metrics";
        \\
        \\ #[restController]
        \\ #[route("/api")]
        \\ pub type QuoteController {
        \\     #[getMapping("/whoami")]
        \\     pub fn whoami(self: Self, req: Request) -> Response {
        \\         return Response.json(traceId() + " " + spanId() + " " + sampled().toString());
        \\     }
        \\ }
        , [
            "GET /api/whoami accept: application/json authorization: Bearer eyJhbGciOi cookie: session=6f1c2a",
            "GET /api/whoami",
        ]);
}
```

`examples/observed-service/test/__snapshots__/observed-service/recorded-exchanges-keep-the-accept-header-and-never-the-credentials.snap`
```
GET /api/whoami -> 200 [include=request.header.accept]
GET /api/whoami -> 200
```

## `examples/realtime-gateway`

**Fronts:** 09 · 20 · 91 · 92 · 93 · **Depends on:** `rakun-websocket`, `rakun-rsocket`, `rakun-pulsar`, `rakun-soap`, `rakun-data` · **Tests:** `examples/realtime-gateway/test/realtime-gateway_test.bp` · **Snapshots:** `examples/realtime-gateway/test/__snapshots__/realtime-gateway/` · **Target:** erlang

> helper gap: the front examples import the websocket surface from `"rakun-web"`, the Pulsar surface from `"rakun-messaging"` and the SOAP surface from `"rakun-ws"`; the cut names the submodules `rakun-websocket`, `rakun-pulsar` and `rakun-soap` — the sources below import from the cut's names.

```
examples/realtime-gateway/
├── botopink.json          dependencies: rakun-websocket · rakun-rsocket · rakun-pulsar · rakun-soap · rakun-data
├── application.yaml       rakun.nosql.url ets:memory · rakun.websocket.max-frame-bytes 65536 · rakun.websocket.heartbeat-seconds 30 · rakun.rsocket.server.{port 9898, mapping-path /rsocket, transport tcp}
├── src/main.bp            Rakun.run(App(port: 8080, basePath: "/api"))
├── src/chat.bp            RoomService · ChatEndpoint (#[service] #[wsEndpoint("/ws/chat")] · onOpen/onMessage/onClose) · ChatController (#[route("/api/chat")] · POST /:room/announce)
├── src/profiles.bp        ProfileRepository (#[repository] #[managed] · #[documentQuery]) · RateLimiter · SessionStore (KeyValueStore) · DocumentStoreHealth (#[healthIndicator("documents")])
├── src/invoices.bp        classifyInvoice · InvoiceListener (#[pulsarListener("persistent://acme/billing/invoices")]) · InvoiceBacklog (#[pulsarReader(…, "earliest")]) · InvoicePublisher
├── src/users.bp           UserEndpoint (#[messageMapping] user.seen · user.byId · user.events · user.sync) · fetchUser · UserClient
└── src/rates.bp           ConversionRequest · ConversionResponse · conversionRequestToXml · convert (#[@result]) · Rates (WsClient 1.1)
```

### `realtime-gateway: the document store answers by email, by plan and by id`

```bp
test "realtime-gateway: the document store answers by email, by plan and by id" {
    try assertStore(@src(),
        \\ import {repository} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {managed} from "rakun";
        \\ import {KeyValueStore, DocumentStore} from "rakun-data";
        \\ import {documentQuery, bind, param} from "rakun-data";
        \\ import {rkRegisterQuery} from "rakun-data";
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
        \\
        \\     #[documentQuery("{\"plan\": \":plan\", \"active\": true}")]
        \\     pub fn findActiveOnPlan(self: Self, plan: string) -> string[] {
        \\         val filter = bind(__rkQuery_findActiveOnPlan(), [param("plan", plan)]);
        \\         return self.docs.find("profiles", filter);
        \\     }
        \\
        \\     pub fn save(self: Self, id: string, doc: string) -> i32 {
        \\         return self.docs.replace("profiles", id, doc);
        \\     }
        \\
        \\     pub fn byId(self: Self, id: string) -> ?string {
        \\         return self.docs.findById("profiles", id);
        \\     }
        \\ }
        , [
            "docs.insert(profiles, p-1, {\"email\":\"ana@example.org\",\"plan\":\"pro\",\"active\":true})",
            "ProfileRepository.findByEmail(ana@example.org)",
            "ProfileRepository.findActiveOnPlan(pro)",
            "docs.count(profiles, {})",
            "ProfileRepository.byId(p-9)",
        ]);
}
```

`examples/realtime-gateway/test/__snapshots__/realtime-gateway/the-document-store-answers-by-email-by-plan-and-by-id.snap`
```
docs.insert(profiles, p-1, {"email":"ana@example.org","plan":"pro","active":true}) -> 1
ProfileRepository.findByEmail(ana@example.org) -> {"email":"ana@example.org","plan":"pro","active":true}
ProfileRepository.findActiveOnPlan(pro) -> [{"email":"ana@example.org","plan":"pro","active":true}]
docs.count(profiles, {}) -> 1
ProfileRepository.byId(p-9) -> null
```

### `realtime-gateway: the key-value store counts the rate window and expires the session`

```bp
test "realtime-gateway: the key-value store counts the rate window and expires the session" {
    try assertStore(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {managed} from "rakun";
        \\ import {KeyValueStore} from "rakun-data";
        \\
        \\ #[service]
        \\ #[managed]
        \\ pub type RateLimiter(
        \\     kv: KeyValueStore,
        \\ ) {
        \\     pub fn hit(self: Self, who: string) -> i32 {
        \\         val key = "rate:" + who;
        \\         val n = self.kv.increment(key, 1);
        \\         val fresh = n == 1;
        \\         if (fresh) {
        \\             val _t = self.kv.putExpiring(key, "1", 60);
        \\         };
        \\         return n;
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ #[managed]
        \\ pub type SessionStore(
        \\     kv: KeyValueStore,
        \\ ) {
        \\     pub fn put(self: Self, token: string, userId: string) -> i32 {
        \\         return self.kv.putExpiring("session:" + token, userId, 1800);
        \\     }
        \\
        \\     pub fn userFor(self: Self, token: string) -> string {
        \\         val hit = self.kv.get("session:" + token);
        \\         var id = "";
        \\         if (hit) { v -> id = v; };
        \\         return id;
        \\     }
        \\
        \\     pub fn secondsLeft(self: Self, token: string) -> i32 {
        \\         return self.kv.ttl("session:" + token);
        \\     }
        \\ }
        , [
            "RateLimiter.hit(ana)",
            "RateLimiter.hit(ana)",
            "kv.ttl(rate:ana)",
            "SessionStore.put(tok-1, u-1)",
            "SessionStore.userFor(tok-1)",
            "SessionStore.secondsLeft(tok-1)",
            "SessionStore.userFor(tok-9)",
        ]);
}
```

`examples/realtime-gateway/test/__snapshots__/realtime-gateway/the-key-value-store-counts-the-rate-window-and-expires-the-session.snap`
```
RateLimiter.hit(ana) -> 1
RateLimiter.hit(ana) -> 2
kv.ttl(rate:ana) -> 60
SessionStore.put(tok-1, u-1) -> 1
SessionStore.userFor(tok-1) -> u-1
SessionStore.secondsLeft(tok-1) -> 1800
SessionStore.userFor(tok-9) ->
```

### `realtime-gateway: a chat frame is broadcast to the room and a blank one is dropped`

```bp
test "realtime-gateway: a chat frame is broadcast to the room and a blank one is dropped" {
    try assertWebSocket(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {wsEndpoint, WsHandler, WsSession} from "rakun-websocket";
        \\ import {subscribe, unsubscribe, broadcast, sessionsOn, rkWsRegister} from "rakun-websocket";
        \\ import {Logger, logger} from "rakun-logging";
        \\
        \\ val log = logger("app.chat");
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
        \\
        \\     pub fn format(self: Self, who: string, text: string) -> string {
        \\         return who + ": " + text;
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
        \\         val _joined = broadcast(room, "{\"t\":\"" + room + "\",\"d\":\"" + session.principal + " joined\"}");
        \\         return log.infoWith("ws open", [#("session.id", session.id), #("room", room)]);
        \\     }
        \\
        \\     pub fn onMessage(self: Self, session: WsSession, message: string) -> i32 {
        \\         val room = self.rooms.roomFor(session.path);
        \\         val clean = message.trim();
        \\         if (clean == "") {
        \\             return 0;
        \\         };
        \\         return broadcast(room, "{\"t\":\"" + room + "\",\"d\":\"" + self.rooms.format(session.principal, clean) + "\"}");
        \\     }
        \\
        \\     pub fn onClose(self: Self, session: WsSession, code: i32, reason: string) -> i32 {
        \\         val room = self.rooms.roomFor(session.path);
        \\         val _un = unsubscribe(session, room);
        \\         return log.infoWith("ws close", [
        \\             #("session.id", session.id),
        \\             #("close.code", code.toString()),
        \\             #("close.reason", reason),
        \\         ]);
        \\     }
        \\ }
        , [
            "GET /ws/chat?room=lobby Sec-WebSocket-Protocol: rakun.v1",
            "> hi all",
            ">    ",
            "close 1000 bye",
        ]);
}
```

`examples/realtime-gateway/test/__snapshots__/realtime-gateway/a-chat-frame-is-broadcast-to-the-room-and-a-blank-one-is-dropped.snap`
```
upgrade 101
< {"t":"lobby","d":"anonymous joined"}
> hi all
< {"t":"lobby","d":"anonymous: hi all"}
>
close 1000
```

### `realtime-gateway: the announce route pushes into a room from an http handler`

```bp
test "realtime-gateway: the announce route pushes into a room from an http handler" {
    try assertRoute(@src(),
        \\ import {service, restController, route, postMapping} from "rakun";
        \\ import {Request, Response} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkRegisterRoute} from "rakun";
        \\ import {broadcast, sessionsOn} from "rakun-websocket";
        \\
        \\ #[service]
        \\ pub type RoomService {
        \\     pub fn format(self: Self, who: string, text: string) -> string {
        \\         return who + ": " + text;
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api/chat")]
        \\ pub type ChatController(
        \\     rooms: RoomService,
        \\ ) {
        \\     #[postMapping("/:room/announce")]
        \\     pub fn announce(self: Self, req: Request) -> Response {
        \\         val room = req.param("room");
        \\         val sent = broadcast(room, "{\"t\":\"" + room + "\",\"d\":\"" + req.body() + "\"}");
        \\         return Response.json("{\"sent\":" + sent.toString() + ",\"listeners\":" + sessionsOn(room).toString() + "}");
        \\     }
        \\ }
        , ["POST /api/chat/lobby/announce | maintenance at noon"]);
}
```

`examples/realtime-gateway/test/__snapshots__/realtime-gateway/the-announce-route-pushes-into-a-room-from-an-http-handler.snap`
```
POST /api/chat/:room/announce -> ChatController.announce

POST /api/chat/lobby/announce -> 200 {"sent":0,"listeners":0}
```

### `realtime-gateway: invoices are acknowledged, negatively acknowledged or dead-lettered by shape`

```bp
test "realtime-gateway: invoices are acknowledged, negatively acknowledged or dead-lettered by shape" {
    try assertPulsar(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Delivery, Outcome} from "rakun-messaging";
        \\ import {TopicName, parseTopic, renderTopic, pulsarSend, pulsarListener, pulsarReader, startCursor, subscriptionType} from "rakun-pulsar";
        \\
        \\ fn classifyInvoice(delivery: Delivery) -> Outcome {
        \\     val tenant = delivery.header("tenant");
        \\     if (tenant == "") {
        \\         return Outcome.Reject(reason: "message published outside a tenant");
        \\     };
        \\     val body = delivery.body;
        \\     if (body == "") {
        \\         return Outcome.Retry(reason: "empty payload");
        \\     };
        \\     return Outcome.Done;
        \\ }
        \\
        \\ #[service]
        \\ type InvoiceListener {
        \\     #[pulsarListener("persistent://acme/billing/invoices")]
        \\     pub fn onInvoice(self: Self, delivery: Delivery) -> Outcome {
        \\         return classifyInvoice(delivery);
        \\     }
        \\ }
        \\
        \\ #[service]
        \\ type InvoiceBacklog {
        \\     #[pulsarReader("persistent://acme/billing/invoices", "earliest")]
        \\     pub fn replay(self: Self, delivery: Delivery) -> i32 {
        \\         return 0;
        \\     }
        \\ }
        , [
            "deliver persistent://acme/billing/invoices tenant=acme | invoice:1",
            "deliver persistent://acme/billing/invoices tenant=acme | ",
            "deliver persistent://acme/billing/invoices | invoice:3",
        ]);
}
```

`examples/realtime-gateway/test/__snapshots__/realtime-gateway/invoices-are-acknowledged-negatively-acknowledged-or-dead-lettered-by-shape.snap`
```
listener persistent://acme/billing/invoices -> InvoiceBacklog.replay broker=pulsar
listener persistent://acme/billing/invoices -> InvoiceListener.onInvoice broker=pulsar
deliver persistent://acme/billing/invoices invoice:1 -> ok
ack acknowledge
deliver persistent://acme/billing/invoices  -> nack
ack negative
deliver persistent://acme/billing/invoices invoice:3 -> dead-letter
ack acknowledge
```

### `realtime-gateway: the four rsocket interaction models register and exchange their frames`

```bp
test "realtime-gateway: the four rsocket interaction models register and exchange their frames" {
    try assertRSocket(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {Outcome} from "rakun-messaging";
        \\ import {messageMapping, StreamHandle, Requester, rsocketRequester, requestResponse, fireAndForget, routeTag, parseRouteTag, grantCredit} from "rakun-rsocket";
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
        , [
            "fnf user.seen ana",
            "rr user.byId 7",
            "rs user.events 7 n=2",
            "channel user.sync a n=1",
        ]);
}
```

`examples/realtime-gateway/test/__snapshots__/realtime-gateway/the-four-rsocket-interaction-models-register-and-exchange-their-frames.snap`
```
route user.byId model=rr
route user.events model=rs
route user.seen model=fnf
route user.sync model=channel
> REQUEST_FNF user.seen ana
> REQUEST_RESPONSE user.byId 7
< PAYLOAD user:7
> REQUEST_STREAM user.events 7
> REQUEST_N 2
< credit events:7 = 2
> REQUEST_CHANNEL user.sync a
> REQUEST_N 1
< credit sync:a = 1
```

### `realtime-gateway: a conversion call wraps its body in a soap 1.1 envelope and reads the answer`

```bp
test "realtime-gateway: a conversion call wraps its body in a soap 1.1 envelope and reads the answer" {
    try assertSoap(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {WsClient, SoapFault, wsCall, soapEnvelope, soapBody, parseFault} from "rakun-soap";
        \\
        \\ pub type ConversionRequest(
        \\     from: string,
        \\     to: string,
        \\     amount: string,
        \\ )
        \\
        \\ pub type ConversionResponse(
        \\     rate: string,
        \\     converted: string,
        \\ )
        \\
        \\ fn between(xml: string, open: string, close: string) -> string {
        \\     val start = xml.indexOf(open) + open.length();
        \\     val end = xml.indexOf(close);
        \\     return xml.slice(start, end);
        \\ }
        \\
        \\ fn conversionRequestToXml(req: ConversionRequest) -> string {
        \\     return "<Convert xmlns=\"urn:rates\">"
        \\         + "<From>" + req.from + "</From>"
        \\         + "<To>" + req.to + "</To>"
        \\         + "<Amount>" + req.amount + "</Amount>"
        \\         + "</Convert>";
        \\ }
        \\
        \\ fn conversionResponseFromXml(xml: string) -> ConversionResponse {
        \\     return ConversionResponse(
        \\         rate: between(xml, "<Rate>", "</Rate>"),
        \\         converted: between(xml, "<Converted>", "</Converted>"),
        \\     );
        \\ }
        \\
        \\ #[@result]
        \\ pub fn convert(client: WsClient, req: ConversionRequest) -> @Result<ConversionResponse, SoapFault> {
        \\     val body = conversionRequestToXml(req);
        \\     val answer = try wsCall(client, "urn:rates/Convert", body) catch "";
        \\     if (answer == "") {
        \\         throw SoapFault(code: "Client", reason: "no response body", actor: "", detail: "");
        \\     };
        \\     return conversionResponseFromXml(answer);
        \\ }
        \\
        \\ #[service]
        \\ type Rates {
        \\     pub fn quote(self: Self, amount: string) -> string {
        \\         val client = WsClient(endpoint: "https://rates.example.com/soap", version: "1.1", timeoutMs: 5000);
        \\         val req = ConversionRequest(from: "EUR", to: "BRL", amount: amount);
        \\         val answered = convert(client, req);
        \\         val out = case answered {
        \\             Ok(result) -> result.converted;
        \\             Error(error) -> "fault:" + error.code;
        \\         };
        \\         return out;
        \\     }
        \\ }
        , "Rates.quote(100)");
}
```

`examples/realtime-gateway/test/__snapshots__/realtime-gateway/a-conversion-call-wraps-its-body-in-a-soap-1-1-envelope-and-reads-the-answer.snap`
```
POST https://rates.example.com/soap SOAPAction: "urn:rates/Convert"
<?xml version="1.0" encoding="UTF-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><Convert xmlns="urn:rates"><From>EUR</From><To>BRL</To><Amount>100</Amount></Convert></soap:Body></soap:Envelope>
200 <ConvertResponse xmlns="urn:rates"><Rate>6.1</Rate><Converted>610</Converted></ConvertResponse>
```

### `realtime-gateway: a soap fault is a distinguishable outcome with its code`

```bp
test "realtime-gateway: a soap fault is a distinguishable outcome with its code" {
    try assertSoap(@src(),
        \\ import {service} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone} from "rakun";
        \\ import {WsClient, SoapFault, wsCall, soapEnvelope, soapBody, parseFault} from "rakun-soap";
        \\
        \\ pub type ConversionRequest(
        \\     from: string,
        \\     to: string,
        \\     amount: string,
        \\ )
        \\
        \\ fn conversionRequestToXml(req: ConversionRequest) -> string {
        \\     return "<Convert xmlns=\"urn:rates\">"
        \\         + "<From>" + req.from + "</From>"
        \\         + "<To>" + req.to + "</To>"
        \\         + "<Amount>" + req.amount + "</Amount>"
        \\         + "</Convert>";
        \\ }
        \\
        \\ #[@result]
        \\ pub fn convert(client: WsClient, req: ConversionRequest) -> @Result<string, SoapFault> {
        \\     return wsCall(client, "urn:rates/Convert", conversionRequestToXml(req));
        \\ }
        \\
        \\ #[service]
        \\ type Rates {
        \\     pub fn quote(self: Self, amount: string) -> string {
        \\         val client = WsClient(endpoint: "https://rates.example.com/soap", version: "1.1", timeoutMs: 5000);
        \\         val req = ConversionRequest(from: "EUR", to: "BRL", amount: amount);
        \\         val answered = convert(client, req);
        \\         val out = case answered {
        \\             Ok(result) -> result;
        \\             Error(error) -> "fault:" + error.code;
        \\         };
        \\         return out;
        \\     }
        \\ }
        , "Rates.quote(-1)");
}
```

`examples/realtime-gateway/test/__snapshots__/realtime-gateway/a-soap-fault-is-a-distinguishable-outcome-with-its-code.snap`
```
POST https://rates.example.com/soap SOAPAction: "urn:rates/Convert"
<?xml version="1.0" encoding="UTF-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><Convert xmlns="urn:rates"><From>EUR</From><To>BRL</To><Amount>-1</Amount></Convert></soap:Body></soap:Envelope>
500 fault Client amount must be positive
```

## `examples/release-kit`

**Fronts:** 72 · 73 · 80 · 81 · 88 · **Depends on:** `starters/*`, `rakun-devtools`, `rakun-release`, `rakun-cli` · **Tests:** `examples/release-kit/test/release-kit_test.bp` · **Snapshots:** `examples/release-kit/test/__snapshots__/release-kit/` · **Target:** erlang

> open names: the `rakun new` stdout line and the scaffold's test filename are per README § Step 2 of 88; the web starter's auto-configuration name is per README § Mechanism of 72 (only `RakunCore`/`RakunDataSource`/`RakunCache`/`RakunMail` are literal there).

```
examples/release-kit/
├── botopink.json          name orders · dependencies: rakun-starter-web (path) · rakun-starter-data-sql (path) · rakun-devtools · rakun-release · rakun-cli
├── application.yaml       server.port 8080 · rakun.datasource.url ets:memory · rakun.observability.sampling 0.1
├── application-dev.yaml   rakun.devtools.db-console.enabled true
├── src/main.bp            OrderService (#[service] #[transactional] · SqlTemplate injected by front 72) · OrderController (#[route("/api")]) · autoConfigure() · Rakun.run(App(port: 8080, basePath: "/api"))
├── src/dev.bp             DevtoolsSettings · withProjectSettings · startDevtools · #[devReloadable("orders")] ordersModuleTag
├── src/release.bp         ordersRelease() -> Release (VmArgs · erts host) · writeArtifacts() (LayerPlan · DockerOptions · UnitOptions)
└── src/commands.bp        Seeder (#[service] · #[cliCommand("seed")] · flagValue --count · hasFlag --dry-run)
```

### `release-kit: the condition report matches the data source and skips cache and mail`

```bp
test "release-kit: the condition report matches the data source and skips cache and mail" {
    try assertAutoConfig(@src(),
        \\ import {service, restController, route, getMapping, postMapping} from "rakun";
        \\ import {Request, Response, Rakun, App} from "rakun";
        \\ import {autoConfigure, isAutoConfigured, rkModulePresent} from "rakun";
        \\ import {rkScan, rkSingleton, rkEnter, rkDone, rkProp, rkPropInt, rkRegisterRoute} from "rakun";
        \\ import {SqlTemplate, Param, param, transactional} from "rakun-data";
        \\
        \\ #[service]
        \\ #[transactional]
        \\ pub type OrderService(
        \\     sql: SqlTemplate,
        \\ ) {
        \\     pub fn total(self: Self, customer: string) -> i32 {
        \\         val rows = self.sql.query(
        \\             "select coalesce(sum(cents), 0) as cents from orders where customer = :customer",
        \\             [param("customer", customer)],
        \\         );
        \\         var cents = 0;
        \\         if (rows.first()) { r -> cents = r.int("cents"); };
        \\         return cents;
        \\     }
        \\ }
        \\
        \\ #[restController]
        \\ #[route("/api")]
        \\ pub type OrderController(
        \\     svc: OrderService,
        \\ ) {
        \\     #[getMapping("/orders/:customer")]
        \\     pub fn total(self: Self, req: Request) -> Response {
        \\         return Response.json(self.svc.total(req.param("customer")).toString());
        \\     }
        \\ }
        \\
        \\ fn main() {
        \\     val _ = autoConfigure();
        \\     Rakun.run(App(port: 8080, basePath: "/api"));
        \\ }
        , ["rakun-starter-web", "rakun-starter-data-sql"]);
}
```

`examples/release-kit/test/__snapshots__/release-kit/the-condition-report-matches-the-data-source-and-skips-cache-and-mail.snap`
```
- RakunCacheAutoConfiguration  M|rakun-cache
+ RakunCoreAutoConfiguration  always
+ RakunDataSourceAutoConfiguration  M|rakun-data;X|SqlTemplate
- RakunMailAutoConfiguration  M|rakun-mail;P|rakun.mail.host|*
```

### `release-kit: the web starter brings web, validation and logging in one resolution pass`

```bp
test "release-kit: the web starter brings web, validation and logging in one resolution pass" {
    try assertStarter(@src(), "rakun-starter-web");
}
```

`examples/release-kit/test/__snapshots__/release-kit/the-web-starter-brings-web-validation-and-logging-in-one-resolution-pass.snap`
```
brings [rakun, rakun-logging, rakun-starter, rakun-validation, rakun-web]
autoconfig [RakunCoreAutoConfiguration, RakunWebAutoConfiguration]
```

### `release-kit: the data starter brings rakun-data and its data source auto-configuration`

```bp
test "release-kit: the data starter brings rakun-data and its data source auto-configuration" {
    try assertStarter(@src(), "rakun-starter-data-sql");
}
```

`examples/release-kit/test/__snapshots__/release-kit/the-data-starter-brings-rakun-data-and-its-data-source-auto-configuration.snap`
```
brings [rakun, rakun-data, rakun-logging, rakun-starter]
autoconfig [RakunCoreAutoConfiguration, RakunDataSourceAutoConfiguration]
```

### `release-kit: a changed module reloads without doubling the route table or dropping a connection`

```bp
test "release-kit: a changed module reloads without doubling the route table or dropping a connection" {
    try assertReload(@src(), [
        "watch src",
        "watch app",
        "exclude static/**",
        "change src/orders.bp",
        "keep routes",
        "keep connections",
    ]);
}
```

`examples/release-kit/test/__snapshots__/release-kit/a-changed-module-reloads-without-doubling-the-route-table-or-dropping-a-connection.snap`
```
watch src
watch app
change src/orders.bp -> reload orders in 3 steps
keep routes=2
keep connections=1
```

### `release-kit: the dev defaults sit below the project file and vanish without the module`

```bp
test "release-kit: the dev defaults sit below the project file and vanish without the module" {
    try assertConfig(@src(),
        [
            "application.yaml",
            "application-dev.yaml",
            "RAKUN_PROFILES_ACTIVE=dev",
            "module rakun-devtools",
        ],
        ["rakun.web.error.include-message", "rakun.observability.sampling", "rakun.devtools.db-console.enabled"]);
}
```

`examples/release-kit/test/__snapshots__/release-kit/the-dev-defaults-sit-below-the-project-file-and-vanish-without-the-module.snap`
```
rakun.web.error.include-message = always  (rakun-devtools defaults)
rakun.observability.sampling = 0.1  (application.yaml)
rakun.devtools.db-console.enabled = true  (application-dev.yaml)
```

### `release-kit: the release tree is sorted and carries the sbom and both probe paths`

```bp
test "release-kit: the release tree is sorted and carries the sbom and both probe paths" {
    try assertRelease(@src(), [
        "name orders",
        "version 0.1.0",
        "erts host",
        "profile prod",
        "application kernel 10.2",
        "application stdlib 6.2",
        "application rakun 0.0.1",
        "application rakun_web 0.0.1",
        "application rakun_data 0.0.1",
        "application orders 0.1.0",
        "node orders@127.0.0.1 cookie-env ORDERS_ERLANG_COOKIE embedded",
    ]);
}
```

`examples/release-kit/test/__snapshots__/release-kit/the-release-tree-is-sorted-and-carries-the-sbom-and-both-probe-paths.snap`
```
bin/orders
lib/kernel-10.2/ebin/
lib/orders-0.1.0/ebin/
lib/rakun-0.0.1/ebin/
lib/rakun_data-0.0.1/ebin/
lib/rakun_web-0.0.1/ebin/
lib/stdlib-6.2/ebin/
releases/0.1.0/orders.rel
releases/0.1.0/sys.config
releases/0.1.0/vm.args
sbom.json
sbom 6 components
probes /actuator/health/liveness /actuator/health/readiness
```

### `release-kit: rakun new scaffolds a project with a manifest, a main, a config and one test`

```bp
test "release-kit: rakun new scaffolds a project with a manifest, a main, a config and one test" {
    try assertCli(@src(), ["new", "orders"]);
}
```

`examples/release-kit/test/__snapshots__/release-kit/rakun-new-scaffolds-a-project-with-a-manifest-a-main-a-config-and-one-test.snap`
```
exit 0
created orders
files:
orders/application.yaml
orders/botopink.json
orders/src/main.bp
orders/test/main_test.bp
```

### `release-kit: an empty argv prints the command table and exits 2`

```bp
test "release-kit: an empty argv prints the command table and exits 2" {
    try assertCli(@src(), []);
}
```

`examples/release-kit/test/__snapshots__/release-kit/an-empty-argv-prints-the-command-table-and-exits-2.snap`
```
exit 2
usage: rakun <command> [flags]
beans    list the beans the registry built
build    build the OTP release through rakun-release
config   print the resolved configuration for the active profile
help     print this table
new      scaffold a project
routes   list the registered routes
run      run the application, --watch for the dev loop
seed     seed orders, --count and --dry-run
test     run botopink test --target erlang
files:
```

### `release-kit: the seed command reads its flags and a dry run changes nothing`

```bp
test "release-kit: the seed command reads its flags and a dry run changes nothing" {
    try assertCli(@src(), ["seed", "--count=3", "--dry-run"]);
}
```

`examples/release-kit/test/__snapshots__/release-kit/the-seed-command-reads-its-flags-and-a-dry-run-changes-nothing.snap`
```
exit 0
would seed 3 orders
files:
```
