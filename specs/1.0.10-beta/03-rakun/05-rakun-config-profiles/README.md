# Front 05 — Externalized Configuration and Profiles

**Track:** B rakun
**Priority:** critical — `#[value("key")]` reads a table that nothing fills; an application cannot change environment without changing source
**Target:** erlang (server)
**Wave:** 1
**Depends on:** 01 · `01-std/01-std-lib-enablement` (`json.decode`, the `.json` reader — decision 117) · `01-std/06-validation-lib` (the validator the boot runs)
**Owns:** `src/config.bp`, `src/profiles.bp`, `src/sidecars/rakun_config.erl` · `test/config_test.bp`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen · `src/runtime.bp` and `src/sidecars/rakun_runtime.erl` belong to front 04
**Reference:** `03-recursos-principais.md § Configuracao Externa` · `03-recursos-principais.md § Profiles` · <https://docs.spring.io/spring-boot/reference/features/external-config.html> · <https://docs.spring.io/spring-boot/reference/features/profiles.html>

---

## Problem

rakun has a property table and no way to fill it. `rkSetProp`/`rkProp`/`rkPropInt`
(`src/runtime.bp`, backed by front 04's ETS table) are a flat string-to-string `Map` that
something else is expected to seed, and nothing does: the example application
(`examples/rakun/src/config.bp:21-31`) declares `#[value("app.timezone")]` and the value it reads is
whatever a test called `rkSetProp` with, or `""`. There is no file loader, no environment mapping, no
profile, no ordering, no typed binding, and no defaults.

The practical shape of the problem is that `#[value]` is a promise the framework does not keep. A
developer who writes `#[value("server.port")] port: i32` gets `0`, silently, and the application binds
port 0. `rkPropInt` answers `0` for both "absent" and "unparsable", so there is
not even a way to tell the two apart — which is why one of this front's deliverables is a boot-time
refusal rather than a better default.

Spring's configuration surface is large and most of it is not decoration: ordering between sources is
what makes a container deployment work, activation conditions are what make one artifact serve dev and
prod, and `@ConfigurationProperties` is what makes a typo in a key a startup failure instead of a
runtime surprise. This front is the largest of the rakun core fronts for that reason.

## Mechanism

### Sources, highest precedence first

Spring's list (`03-recursos-principais.md § Ordem de Prioridade`) has fourteen entries, six of which
are JVM container concepts with nothing on the other side. The port keeps eight, in this order:

| # | Source | Form |
|---|---|---|
| 1 | Command-line arguments | `--server.port=9090`, read from `env.args()` |
| 2 | `RAKUN_APPLICATION_JSON` | one JSON object in one variable, flattened |
| 3 | OS environment variables | `RAKUN_SERVER_PORT` → `server.port`; `_` → `.`, `__` → `-`, lowercased |
| 4 | Profile-specific documents | `application-<profile>.<ext>`, later active profile wins |
| 5 | Base documents | `application.<ext>`, later location in the list wins |
| 6 | Configuration trees | `configtree:/etc/config/` — one file per key, body is the value |
| 7 | Programmatic defaults | `rkSetProp` / `rkBoot`, the `setDefaultProperties` analogue |
| 8 | Declared field defaults | the value written on the bound record |

`${random.*}` is not a source. It is resolved at reference time, so `${random.int[1024,65536]}`
answers differently per reference and is never cached.

### Where a document is looked for

`rakun.config.name` (default `application`) and `rakun.config.location`, an ordered comma-separated
list defaulting to `optional:classpath:/,optional:classpath:/config/,optional:file:./,optional:file:./config/`
in Spring's terms; in rakun's terms, `optional:file:./`, `optional:file:./config/`. An entry without
`optional:` that does not exist is a **startup failure** naming the path — the milestone's "most
restrictive, no escape hatch" rule applied to configuration: a typo in a location is not a warning.

`rakun.config.import=optional:file:./dev.yaml` pulls in another document at the importing document's
precedence, resolved after it. An import cycle is a startup failure naming both files.

### Formats

The sidecar reads three:

- **`.properties`** — `key=value`, `#`/`!` comments, `\` continuations. Twenty lines of Erlang.
- **`.json`** — std's `json.decode(text) -> @Result<Json, string>` (`01-std/01-std-lib-enablement`,
  decision 117), then the `Json` tree flattened to dot keys: an `Obj` field extends the key, an `Arr`
  becomes indexed keys (`spring.profiles.include[0]`), matching Spring's own relaxed list binding,
  and a `Str` / `Num` / `Bool` is the value. The hand scanner in `modules/rakun/src/config.bp`
  and its string reader (`config.bp:394-433`, `jsonString` /
  `jsonUnquote` / `unescape`, which misreads `\b`, `\f`, `\/` and `\u`) are deleted for std
  (decisions 116 and 117) — no token is sliced by hand.
- **`.yaml` / `.yml`** — a **subset** decoder in the sidecar: block mappings, block sequences, plain
  and quoted scalars, `#` comments, `---` document separators. Anchors, aliases, flow style,
  multi-line scalar blocks and tags are **refused with a located error naming the line**, not
  silently mis-parsed. This covers what `application.yaml` files actually contain and says plainly
  what it does not cover. A full YAML parser is not this front's work and is not on the critical path.

### Multi-document files and activation

A `---` separator splits a YAML file, and a `#---` line splits a properties file
(`03-recursos-principais.md § Multi-Document Files`). Each document may carry activation conditions:

```yaml
myprop: always-set
---
rakun.config.activate.on-profile: "prod | staging"
rakun.config.activate.on-cloud-platform: "kubernetes"
myotherprop: sometimes-set
```

`on-profile` takes the same expression grammar as `#[profile]` — names, `|`, `&`, `!` and
parentheses. `on-cloud-platform` is matched against a detected platform: `kubernetes` when
`KUBERNETES_SERVICE_HOST` is set, `cloud-foundry` on `VCAP_APPLICATION`, `heroku` on `DYNO`,
`azure-app-service` on `WEBSITE_SITE_NAME`, `none` otherwise. Detection is one function and it is
testable by setting environment variables, which is how its tests work.

A document whose conditions do not hold contributes nothing — not a lower-priority value, nothing.

### Placeholders

`${key}` and `${key:default}`, resolved recursively with a depth limit, and a cycle
(`a=${b}`, `b=${a}`) reported as a startup failure naming both keys rather than looping. `${random.value}`,
`${random.int}`, `${random.long}`, `${random.uuid}`, `${random.int(10)}` and `${random.int[1024,65536]}`
resolve over front 01's `random`.

An unresolvable `${key}` with no default is a startup failure naming the key and the property that
referenced it. There is no mode in which it silently becomes the empty string.

### Profiles

`rakun.profiles.active=dev,postgres` activates in order; `rakun.profiles.default` (default `default`)
applies when none is active; `rakun.profiles.include[0]` adds unconditionally; and
`rakun.profiles.group.production[0]=proddb` expands one name into a list, transitively, with a cycle
reported rather than followed.

`#[profile("prod | staging")]` on a component is **not** this front's decorator — conditional
registration belongs to front 72, and building a second condition mechanism here would leave two.
Front 05 owns the profile *set*; front 72 reads it.

### Typed binding: `#[configurationProperties("prefix")]`

A type-level decorator. It has everything it needs: `decl.name`, and `decl.fields` with each field's
`name`, `typeName` and own annotations (`libs/std/src/builtins.d.bp:437-476`). It emits two functions:

```bp
// written by the developer
#[configurationProperties("my.service")]
pub type MyService(
    enabled: bool,
    remoteAddress: string,
    #[unit("seconds")] sessionTimeout: Duration,
    bufferSize: DataSize,
    #[nested] security: Security,
)
```

```bp
// emitted at module level — prefix is a PARAMETER, which is what makes nesting work
pub fn __rkBind_MyService(prefix: string) -> MyService {
    return MyService(
        enabled: rkPropBool(prefix + ".enabled", false),
        remoteAddress: rkProp(prefix + ".remote-address"),
        sessionTimeout: rkPropDuration(prefix + ".session-timeout", "seconds"),
        bufferSize: rkPropSize(prefix + ".buffer-size", "bytes"),
        security: __rkBind_Security(prefix + ".security"),
    );
}
pub fn __rkMake_MyService() -> MyService {
    return rkSingleton("MyService", { -> __rkBind_MyService("my.service") });
}
```

Three things fall out of that shape and are worth naming:

- **Relaxed binding** is a rule in the emitter, not at run time: `remoteAddress` becomes
  `remote-address`. `rkProp` additionally tries the camel-case and the underscore spelling before
  giving up, so `REMOTE_ADDRESS` from the environment lands.
- **Nesting works** because the prefix is a parameter. `#[nested]` on a field of a type that itself
  carries `#[configurationProperties]` composes without either decorator knowing about the other.
  This matters: a rakun decorator body cannot call a sibling function (`decorators.bp:44-46`), so
  composition has to happen in the *emitted* code, not in the decorator.
- **`__rkMake_MyService` is the ordinary DI factory name**, so a bound configuration record is
  injectable by type into any `#[service]` with no further wiring.

`#[enableConfigurationProperties]` on a `#[configuration]` type is the explicit-registration form:
it takes the type names as arguments and emits the same `rkSingleton` registration for records that
carry `#[configurationProperties]` but live in a module the application does not otherwise import.

### `Duration` and `DataSize`

```bp
pub type Duration(millis: i64)
pub type DataSize(bytes: i64)
```

`30` with `#[unit("seconds")]` is 30 s; `30s`, `500ms`, `2m`, `1h`, `PT30S` and `PT1H30M` parse
regardless of the unit default. `10`, `10B`, `10KB`, `10MB`, `10GB` for sizes, with `#[unit("megabytes")]`
as the bare-number default. An unparsable value is a startup failure naming the key, the value and the
expected forms — never a zero.

### Validation at boot

The constraints are the bundled library `validation` (decision 116).
Front 05 owns the *moment*: after binding and before the first component is constructed, every
`#[configurationProperties]` record marked `#[validated]` (imported `from "validation"`) is run through
its emitted `validate<TypeName>`, the refusal text is front 14's `config_check.bp`, and a violation halts the boot with the full report — key, value, constraint, and the file
the value came from. "Refuse to start" is the requirement; a bound-but-invalid configuration reaching
a request is the failure this prevents.

### The key catalogue

Every `#[configurationProperties]` emission also registers its keys:

```bp
val __rkCat_MyService = rkRegisterConfigKeys("my.service", "enabled:bool:false|remote-address:string:|session-timeout:Duration:30s");
```

A rakun decorator body cannot accumulate comptime state across invocations, so there is no comptime
catalogue — the registry is built at run time, by the same module-load `val`s the rest of rakun uses.
`rakun config-catalogue` (front 88) boots the application headless (front 04's
`rakun.main.headless`), dumps the registry as JSON, and that file is what the botopink LSP reads for
`application.yaml` completion. Which is also why headless mode is a front 04 deliverable and not an
afterthought.

### Where the property table lives

Front 04 owns `?PROPS` and `rkProp`/`rkPropInt`. Front 05 adds the typed readers
(`rkPropBool`, `rkPropFloat`, `rkPropDuration`, `rkPropSize`, `rkPropList`) and the loader
(`rkConfigLoad`) as its own cells in `src/config.bp`, backed by `src/sidecars/rakun_config.erl`, which
writes through `rakun_runtime:set_prop/2`. Two modules, one table, no second store.

## Steps

### Step 1 — The sidecar readers

`rakun_config:read_properties/1`, `read_json/1`, `read_yaml/1`, each returning a flat key-value list
plus the document boundaries, and `read_tree/1` for `configtree:`.

**Acceptance:**
- [x] `server.port=8080` in a `.properties` file reads back through `rkProp("server.port")` — held: `test/config_test.bp` "rakun config: a .properties document reads back through rkProp"
- [x] `{"server":{"port":8080}}` flattens to `server.port` — held: `test/config_test.bp` "rakun config: a nested .json object flattens to dot keys"
- [x] `{"a":["x","y"]}` flattens to `a[0]` and `a[1]` — held: `test/config_test.bp` "rakun config: a .json array flattens to indexed keys"
- [x] A YAML block mapping, a block sequence and a quoted scalar all read correctly — held: `test/config_test.bp` "rakun config: a YAML block mapping, block sequence and quoted scalar all read"
- [x] A YAML anchor, alias or flow mapping is refused with an error naming the file and the line — it is not silently dropped — held: `test/config_test.bp` "rakun config: a YAML anchor is refused with the file and the line" + "…alias and a flow mapping are refused too" (one `origin:line` refusal path in `src/config.bp`)
- [x] `configtree:` over a directory containing `username` and `password` yields `username` and `password` keys with the file bodies as values, trailing newline stripped — held: `test/config_test.bp` "rakun config: configtree reads one file per key, newline stripped"

### Step 2 — Locations, names and imports

**Acceptance:**
- [x] `rakun.config.name=myproject` reads `myproject.yaml` instead of `application.yaml` — held: `test/config_test.bp` "rakun config: rakun.config.name picks the document stem"
- [x] A non-`optional:` location that does not exist fails the boot naming the path — held: `test/config_test.bp` "rakun config: a non-optional location that does not exist fails the boot"
- [x] An `optional:` location that does not exist contributes nothing and does not warn — held: `test/config_test.bp` "rakun config: an optional location that does not exist contributes nothing"
- [x] Later locations in the list override earlier ones — held: `test/config_test.bp` "rakun config: a later location overrides an earlier one"
- [x] `rakun.config.import` pulls in a second document, resolved after the importing one — held: `test/config_test.bp` "rakun config: rakun.config.import pulls a document resolved after the importer"
- [x] An import cycle fails the boot naming both files — held: `test/config_test.bp` "rakun config: an import cycle fails the boot naming both files" (message is the visited chain)

### Step 3 — Ordering

**Acceptance:**
- [x] `--server.port=9090` beats `RAKUN_SERVER_PORT=8081` beats `application.yaml` — held: `test/config_test.bp` "rakun config: the full stack — one key in six sources, one winner" + rows 1→5 tests
- [x] `application-prod.yaml` beats `application.yaml` when `prod` is active — held: `test/config_test.bp` "rakun config: row 4 beats row 5 — a profile document beats the base document"
- [x] With `dev,prod` active, `application-prod.yaml` beats `application-dev.yaml` — held: `test/config_test.bp` "rakun config: with dev and prod active the later profile wins"
- [x] `rkSetProp` loses to every file source and wins over a declared field default — held: `test/config_test.bp` "rakun config: row 6 beats row 7 — a configuration tree beats rkSetProp"; `test/typed_config_test.bp` "#[nested] composes two levels down" (rkSetProp over `#[defaultValue]`)
- [x] `RAKUN_APPLICATION_JSON` beats the environment variables beside it — held: `test/config_test.bp` "rakun config: row 2 beats row 3 — RAKUN_APPLICATION_JSON beats the variables beside it"
- [x] Each of the eight rows in the source table has one test asserting it beats the row below it — held: `test/config_test.bp` "row 1 beats row 2" … "row 7 beats row 8" (rakun `0a8deef`)

### Step 4 — Placeholders and random values

**Acceptance:**
- [x] `${app.name}` resolves from another key — held: `test/config_test.bp` "rakun config: ${key} resolves from another key, recursively"
- [x] `${missing:fallback}` resolves to `fallback` — held: `test/config_test.bp` "rakun config: ${missing:fallback} resolves to the default"
- [x] `${missing}` with no default fails the boot naming both keys — held: `test/config_test.bp` "rakun config: ${missing} with no default fails the boot naming both keys"
- [x] `a=${b}` / `b=${a}` fails the boot naming the cycle — held: `test/config_test.bp` "rakun config: a placeholder cycle fails the boot naming the chain"
- [x] `${random.uuid}` is a valid v4 UUID and differs between two references — held: `test/config_test.bp` "rakun config: ${random.uuid} is a v4 UUID and differs between references"
- [x] `${random.int[1024,65536]}` is inside the range, and one thousand draws cover more than one value — held: `test/config_test.bp` "rakun config: ${random.int[lo,hi]} stays in range and is not one value"

### Step 5 — Multi-document activation and cloud-platform detection

**Acceptance:**
- [x] A `---`-separated YAML document with `on-profile: prod` contributes only when `prod` is active — held: `test/config_test.bp` "rakun config: a conditional document contributes only when its profile is active"
- [x] `on-profile: "prod | staging"` matches either; `"!prod"` matches when it is not active — held: `test/config_test.bp` "rakun config: on-profile takes an expression" + "the profile expression grammar"
- [x] `on-cloud-platform: kubernetes` matches when `KUBERNETES_SERVICE_HOST` is set and not otherwise — held: `test/config_test.bp` "rakun config: on-cloud-platform matches a detected platform"
- [x] A document with two conditions needs both — held: `test/config_test.bp` "rakun config: a document with two conditions needs both"
- [x] A non-contributing document does not lower-priority-contribute; the key is absent — held: `test/config_test.bp` "rakun config: a conditional document contributes only when its profile is active" (`act.prodish` stays blank)

### Step 6 — Profiles, includes and groups

**Acceptance:**
- [x] `rakun.profiles.active=dev` loads `application-dev.yaml` — held: `test/config_test.bp` "rakun config: an active profile loads its document and is readable back"
- [x] `rakun.profiles.default` applies only when nothing is active — held: `test/config_test.bp` "rakun config: rakun.profiles.default applies only when nothing is active"
- [x] `rakun.profiles.include[0]=common` activates `common` regardless of the active list — held: `test/config_test.bp` "rakun config: an include activates a profile regardless of the active list"
- [x] `rakun.profiles.group.production[0]=proddb` and `[1]=prodmq` activates all three when `production` is activated — held: `test/config_test.bp` "rakun config: a group expands one name into a list, the name included"
- [x] A group referring to itself fails the boot naming the cycle — held: `test/config_test.bp` "rakun config: a group that refers to itself fails the boot naming the cycle"
- [x] The resolved profile list is readable at run time (`profiles.active()`), in activation order — held: `test/config_test.bp` "rakun config: an include activates a profile regardless of the active list" (`active()` = `dev,common`)

### Step 7 — `#[configurationProperties]` binding

**Acceptance:**
- [x] `#[configurationProperties("my.service")]` on a record binds every field from `my.service.*` — held: `test/typed_config_test.bp` "rakun config: #[configurationProperties] binds every field from the prefix"
- [x] `remoteAddress` binds from `remote-address`, from `remoteAddress` and from `REMOTE_ADDRESS` — held: `test/typed_config_test.bp` "rakun config: a field binds from the kebab, the camel and the screaming spelling"
- [ ] `bool`, `i32`, `i64`, `f64`, `string`, `string[]`, `Duration` and `DataSize` all coerce
- [x] A `#[nested]` field of a type that also carries `#[configurationProperties]` binds under `<prefix>.<field>` — held: `test/typed_config_test.bp` "rakun config: #[nested] composes two levels down"
- [x] Two levels of nesting work — held: `test/typed_config_test.bp` "rakun config: #[nested] composes two levels down"
- [x] The bound record is injectable by type into a `#[service]` with no extra wiring — held: `test/typed_config_test.bp` "rakun config: the bound record is injectable by type with no extra wiring"
- [x] `#[configurationProperties]` on an enum-shaped `type` fails at comptime with a located message — held: `src/config.bp` `configurationProperties` → `decl.fail("… not an enum")`
- [x] An unparsable value fails the boot naming the key, the value and the accepted forms — held: `test/config_test.bp` "rakun config: an unparsable typed value refuses rather than answering zero" (parser `assert`s on `durationProblem`/`dataSizeProblem`/`boolProblem`)

### Step 8 — `Duration` and `DataSize`

**Acceptance:**
- [x] `30`, `30s`, `PT30S` all give 30000 ms under `#[unit("seconds")]` — held: `test/config_test.bp` "rakun config: 30, 30s and PT30S are all 30000 ms under seconds"
- [x] `500ms`, `2m`, `1h`, `PT1H30M` parse without a unit annotation — held: `test/config_test.bp` "rakun config: a suffixed duration parses without a unit annotation"
- [x] `10` under `#[unit("megabytes")]` is 10485760 bytes; `10MB` is the same; `10KB` is 10240 — held: `test/config_test.bp` "rakun config: data sizes scale by their suffix or the unit default"
- [x] `30x` fails the boot naming the value — held: `test/config_test.bp` "rakun config: an unparsable typed value refuses rather than answering zero"

### Step 9 — Validation and the catalogue

**Acceptance:**
- [x] A `#[validated]` configuration record with a violated constraint halts the boot before any component is constructed — held: `test/config_check_test.bp` "an invalid configuration halts the boot before any component is constructed" (rakun `c8f185c`)
- [ ] The report names the key, the offending value and the source file it came from
- [x] `rkRegisterConfigKeys` records every bound key with its type and declared default — held: `test/typed_config_test.bp` "rakun config: every emission registers its keys in the catalogue"
- [x] The catalogue dump lists every key rakun itself reads (`rakun.main.*`, `rakun.server.*`, `rakun.config.*`, `rakun.profiles.*`) alongside the application's own — held: `test/typed_config_test.bp` "rakun config: every emission registers its keys in the catalogue" + `src/config.bp` own-key registration (`rakun.main`/`server`/`config`/`profiles`)

## Examples

- [`examples/typed-config-example.bp`](./examples/typed-config-example.bp) — a developer binding a
  nested typed configuration record, injecting it into a service, and reading the active profiles.
  Shows `#[configurationProperties]`, `#[nested]`, `#[unit]`, `Duration`, `#[value]` and the boot-time
  load in `main`.

## Language gaps

The milestone register is [`language-gaps.md`](../../language-gaps.md); the rows below are this front's entries in it, and the cross-front wire formats they touch are in [`contracts.md`](../../contracts.md).

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter and field defaults are never applied at a call site (`tests/language/expected-failures.txt`, `fn_defaults.bp`; `docs.md:502-505`). A `#[configurationProperties]` record therefore cannot carry its defaults where a reader would look for them. | `examples/typed-config-example.bp` — every default is written in the decorator's emitted reader (`rkPropBool(key, false)`) instead of on the field | Pass the default as the second argument of the typed reader, and declare it in `#[default("…")]` on the field so the catalogue can report it | Apply declared defaults at the call site. Then `enabled: bool = false` is both the default and the documentation |
| A decorator body cannot accumulate state across invocations — each is lowered alone into its own eval script (`decorators.bp:44-46`), so there is no comptime catalogue of every configuration key in the build. | The catalogue is a run-time registry (`rkRegisterConfigKeys`) dumped from a headless boot | The run-time registry, which is what this front ships | A comptime accumulator (`@collect`/`@registry`) visible to a build-final step, which would also let front 72 order auto-configurations without a run-time pass |

## Test plan

`test/config_test.bp`, `botopink test --target erlang` from `repository/rakun/`, and in the gate as
`zig build test-libs -- --target erlang --lib rakun`.

Fixture documents live under `test/fixtures/config/` and are read by path, so ordering tests set
`rakun.config.location` at the top of the test rather than depending on the working directory. The
environment-variable and cloud-platform tests set variables through `io.env`'s `write` (`libs/std/src/io/env.bp:30`)
and clear them afterwards, so they do not leak between test blocks — which matters, because the
property table is process-global by design.

The ordering tests are the ones that earn their keep: eight rows means eight "beats the row below"
assertions plus one full-stack test that sets the same key in all eight and asserts the single winner.

This front is erlang-only and ships no Node file (decision 113).

## Adjacent fronts

- **72-rakun-auto-configuration** reads the profile set and the property table to decide conditional
  registration. Front 05 does not own `#[profile]`, `#[conditionalOnProperty]` or any other condition.
- **14-rakun-validation** owns the refusal text (`config_check.bp`) and the message source; the
  constraints are the bundled library `validation` (decision 116). Front 05 owns running them at boot
  and refusing to start.
- **11-rakun-actuator** serves `configprops` and `env` by reading this front's binding registry;
  **76** owns the sanitization policy over it.
- **88-rakun-cli** owns `rakun config-catalogue`.
- **60-rakun-static-generation** reads this front's configuration at build time.

## Contradictions with fronts.md

1. **No Node cell.** A server front on the erlang target carries no `.mjs` file.
2. **The sidecar is `src/sidecars/rakun_config.erl`, not `src/config.erl`.** The atom `config` collides
   with the emitted `rakun/config` module, so `shipErlSidecars` skips it (`libs.zig:596`) and the
   failure is silent. `fronts.md` now mandates the `src/sidecars/rakun_<name>.erl` form everywhere.
3. `src/root.bp` and `botopink.json` belong to **front 04**. This front's
   `pub mod config;` and `pub mod profiles;` lines are appended in front-number order, never
   reordering an existing line — the same rule track A uses for `libs/std/src/root.bp`.

## Definition of done

- [x] `src/config.bp` and `src/profiles.bp` exist; the readers are botopink, so there is no `src/sidecars/rakun_config.erl` (`decisions-pending.md` 03r-c) — held: `modules/rakun/src/{config,profiles}.bp`
- [x] All eight sources resolve in the documented order, each with its own test — held: `test/config_test.bp` the seven "row N beats row N+1" cells + "the full stack — one key in six sources, one winner"
- [x] `.properties`, `.json` and the documented YAML subset all load; an unsupported YAML construct is a located error — held: `test/config_test.bp` step-1 reader tests (anchor refusal names `file:line`)
- [x] a `.json` value holding `\u0041`, `\b` and `\/` loads as `A`, U+0008 and `/`; a malformed document is refused with `json.decode`'s `Error` message, naming the file; `grep -n "fn jsonString\|fn jsonUnquote\|json\.unquote\|json\.parse" src/config.bp` is empty — held: `test/config_test.bp` "a .json value's escapes are decoded by std's json.decode" + "a malformed .json is refused with json.decode's message, naming the file"; the grep is empty (rakun `b742a4c`)
- [x] `#[configurationProperties]` binds nested records, `Duration` and `DataSize` — held: `test/typed_config_test.bp` "binds every field from the prefix" + "#[nested] composes two levels down"
- [x] A missing non-optional location, an unresolvable placeholder, a placeholder cycle, a profile-group cycle and an unparsable typed value each fail the boot with a message naming the input — held: `test/config_test.bp` (non-optional location, `${missing}`, placeholder cycle, group cycle, unparsable typed value tests)
- [x] `#[validated]` configuration refuses the boot on a violation — held: `test/config_check_test.bp` "an invalid configuration halts the boot before any component is constructed"
- [x] The key catalogue lists every key rakun reads — held: `test/typed_config_test.bp` "rakun config: every emission registers its keys in the catalogue"
- [x] `repository/rakun/AGENTS.md` documents the source order, the location syntax and the YAML subset — held: `repository/rakun/AGENTS.md` § Externalized configuration (eight sources, Locations, document formats)
- [x] The front's tests are green on its assigned target — held: `modules/rakun` `botopink test --target erlang` 310/0
