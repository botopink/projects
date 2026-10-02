# rakun-test — the snapshot-helper contract, carried for decision 03r-ag

Copied from `specs/1.0.10-beta/03-rakun/test-snap.md` § *The contract* and § *Helpers `rakun-test` exposes*,
trimmed to the two sections the open item RX-5 still needs. The per-front case lists (11 000 lines,
one `.snap` per acceptance box) stay in the closed 1.0.10 record: none of those files was ever written
(`find repository/rakun -name "*.snap"` answers nothing), and whether they are still owed is decision
03r-ag in [`../README.md`](../README.md). If the answer keeps the layer, the case lists are copied then,
front by front, as the helper for that subject is written; if it retires the layer, this file is deleted.

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
  [`../../language-gaps.md`](../../../1.0.10-beta/language-gaps.md); this document assumes the contract in
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
| `rakun-app` | `assertPageDispatch(loc, source, request)` | `status`, `headers` sorted, `chunks <n>`, each chunk the `PageRenderer` wrote through its `ChunkWriter` on its own line, `closed <n>` — front 23's dispatch with no markup (decision 114) |
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
| `validation` (bundled — its own `test/`, decision 116) | `assertValidation(loc, source, input: string)` | `valid` or `invalid`, then `<field>: <constraint> <message>` sorted by field |
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
