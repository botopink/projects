# Front 05 — Externalized Configuration and Profiles

**Track:** B rakun
**Priority:** critical — `#[value("key")]` reads a table that nothing fills; an application cannot change environment without changing source
**Target:** erlang (server)
**Wave:** 1
**Depends on:** 01 · `01-std/07-std-json-writers` (`json.unquote` for the `.json` reader's string tokens) · `01-std/06-validation-lib` (the validator the boot runs)
**Owns:** `src/config.bp`, `src/profiles.bp`, `src/sidecars/rakun_config.erl` · `test/config_test.bp`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen · `src/runtime.bp` and `src/sidecars/rakun_runtime.erl` belong to front 04
**Reference:** `03-recursos-principais.md § Configuracao Externa` · `03-recursos-principais.md § Profiles` · <https://docs.spring.io/spring-boot/reference/features/external-config.html> · <https://docs.spring.io/spring-boot/reference/features/profiles.html>

---

## Problem

rakun has a property table and no way to fill it. `rkSetProp`/`rkProp`/`rkPropInt`
(`src/runtime.bp:56-63`, backed by `runtime.mjs:84-97`) are a flat string-to-string `Map` that
something else is expected to seed, and nothing does: the example application
(`examples/rakun/src/config.bp:21-31`) declares `#[value("app.timezone")]` and the value it reads is
whatever a test called `rkSetProp` with, or `""`. There is no file loader, no environment mapping, no
profile, no ordering, no typed binding, and no defaults.

The practical shape of the problem is that `#[value]` is a promise the framework does not keep. A
developer who writes `#[value("server.port")] port: i32` gets `0`, silently, and the application binds
port 0. `rkPropInt` answers `0` for both "absent" and "unparsable" (`runtime.mjs:93-97`), so there is
not even a way to tell the two apart — which is why one of this front's deliverables is a boot-time
refusal rather than a better default.

Spring's configuration surface is large and most of it is not decoration: ordering between sources is
what makes a container deployment work, activation conditions are what make one artifact serve dev and
prod, and `@ConfigurationProperties` is what makes a typo in a key a startup failure instead of a
runtime surprise. This front is the largest of the rakun core fronts for that reason.

## Current state

| Piece | Where | State |
|---|---|---|
| Property storage | `runtime.mjs:84-97`, ETS after front 04 | exists, empty |
| `#[value("key")]` injection | `decorators.bp:53-57` reads the field annotation and emits `rkProp`/`rkPropInt` | works, frozen, string and `i32` only |
| File loading | — | none |
| Environment mapping | — | none |
| Profiles | — | none |
| Typed binding | — | none |
| Ordering between sources | — | none; there is one source |
| `std` pieces this front stands on | `libs/std/src/fs.bp:33,61`, `env.bp:24,44,57` (`io.fs`, `io.env` after decision 106), `path`/`io.random` from front 01 | `fs`/`env` exist today; `path`/`io.random` are front 01's |
| JSON decoding | `libs/std/src/json.bp:36-45` returns `@Result<string, string>` — **there is no structured walker** (`json.bp:9-16`) | insufficient in botopink; decoding happens in the sidecar over OTP's `json` module |

That last row decides the shape of the front. Flattening `{"server": {"port": 8080}}` into
`server.port=8080` cannot be written in botopink today, because std's `json` gives back a string and
nothing to walk. It can be written in ten lines of Erlang over OTP 27's `json:decode/1`. So the parse
and flatten step lives in the sidecar, and the botopink half is resolution, ordering and binding.

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
- **`.json`** — OTP 27's `json:decode/1`, then flattened to dot keys. Arrays become indexed keys
  (`spring.profiles.include[0]`), matching Spring's own relaxed list binding. The landed reader is a
  hand scanner in botopink (`modules/rakun/src/config.bp`); its string reader
  (`config.bp:394-433`, `jsonString` / `jsonUnquote` / `unescape`, which misreads `\b`, `\f`, `\/`
  and `\u`) is deleted for std (decision 116): the document is checked with `json.parse` first, and
  each string token is read with `json.unquote` (`01-std/07-std-json-writers`).
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

The constraints are the bundled library `validation` (decision 116; front 14's landed member moved).
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
- [ ] `server.port=8080` in a `.properties` file reads back through `rkProp("server.port")`
- [ ] `{"server":{"port":8080}}` flattens to `server.port`
- [ ] `{"a":["x","y"]}` flattens to `a[0]` and `a[1]`
- [ ] A YAML block mapping, a block sequence and a quoted scalar all read correctly
- [ ] A YAML anchor, alias or flow mapping is refused with an error naming the file and the line — it is not silently dropped
- [ ] `configtree:` over a directory containing `username` and `password` yields `username` and `password` keys with the file bodies as values, trailing newline stripped

### Step 2 — Locations, names and imports

**Acceptance:**
- [ ] `rakun.config.name=myproject` reads `myproject.yaml` instead of `application.yaml`
- [ ] A non-`optional:` location that does not exist fails the boot naming the path
- [ ] An `optional:` location that does not exist contributes nothing and does not warn
- [ ] Later locations in the list override earlier ones
- [ ] `rakun.config.import` pulls in a second document, resolved after the importing one
- [ ] An import cycle fails the boot naming both files

### Step 3 — Ordering

**Acceptance:**
- [ ] `--server.port=9090` beats `RAKUN_SERVER_PORT=8081` beats `application.yaml`
- [ ] `application-prod.yaml` beats `application.yaml` when `prod` is active
- [ ] With `dev,prod` active, `application-prod.yaml` beats `application-dev.yaml`
- [ ] `rkSetProp` loses to every file source and wins over a declared field default
- [ ] `RAKUN_APPLICATION_JSON` beats the environment variables beside it
- [ ] Each of the eight rows in the source table has one test asserting it beats the row below it

### Step 4 — Placeholders and random values

**Acceptance:**
- [ ] `${app.name}` resolves from another key
- [ ] `${missing:fallback}` resolves to `fallback`
- [ ] `${missing}` with no default fails the boot naming both keys
- [ ] `a=${b}` / `b=${a}` fails the boot naming the cycle
- [ ] `${random.uuid}` is a valid v4 UUID and differs between two references
- [ ] `${random.int[1024,65536]}` is inside the range, and one thousand draws cover more than one value

### Step 5 — Multi-document activation and cloud-platform detection

**Acceptance:**
- [ ] A `---`-separated YAML document with `on-profile: prod` contributes only when `prod` is active
- [ ] `on-profile: "prod | staging"` matches either; `"!prod"` matches when it is not active
- [ ] `on-cloud-platform: kubernetes` matches when `KUBERNETES_SERVICE_HOST` is set and not otherwise
- [ ] A document with two conditions needs both
- [ ] A non-contributing document does not lower-priority-contribute; the key is absent

### Step 6 — Profiles, includes and groups

**Acceptance:**
- [ ] `rakun.profiles.active=dev` loads `application-dev.yaml`
- [ ] `rakun.profiles.default` applies only when nothing is active
- [ ] `rakun.profiles.include[0]=common` activates `common` regardless of the active list
- [ ] `rakun.profiles.group.production[0]=proddb` and `[1]=prodmq` activates all three when `production` is activated
- [ ] A group referring to itself fails the boot naming the cycle
- [ ] The resolved profile list is readable at run time (`profiles.active()`), in activation order

### Step 7 — `#[configurationProperties]` binding

**Acceptance:**
- [ ] `#[configurationProperties("my.service")]` on a record binds every field from `my.service.*`
- [ ] `remoteAddress` binds from `remote-address`, from `remoteAddress` and from `REMOTE_ADDRESS`
- [ ] `bool`, `i32`, `i64`, `f64`, `string`, `string[]`, `Duration` and `DataSize` all coerce
- [ ] A `#[nested]` field of a type that also carries `#[configurationProperties]` binds under `<prefix>.<field>`
- [ ] Two levels of nesting work
- [ ] The bound record is injectable by type into a `#[service]` with no extra wiring
- [ ] `#[configurationProperties]` on an enum-shaped `type` fails at comptime with a located message
- [ ] An unparsable value fails the boot naming the key, the value and the accepted forms

### Step 8 — `Duration` and `DataSize`

**Acceptance:**
- [ ] `30`, `30s`, `PT30S` all give 30000 ms under `#[unit("seconds")]`
- [ ] `500ms`, `2m`, `1h`, `PT1H30M` parse without a unit annotation
- [ ] `10` under `#[unit("megabytes")]` is 10485760 bytes; `10MB` is the same; `10KB` is 10240
- [ ] `30x` fails the boot naming the value

### Step 9 — Validation and the catalogue

**Acceptance:**
- [ ] A `#[validated]` configuration record with a violated constraint halts the boot before any component is constructed
- [ ] The report names the key, the offending value and the source file it came from
- [ ] `rkRegisterConfigKeys` records every bound key with its type and declared default
- [ ] The catalogue dump lists every key rakun itself reads (`rakun.main.*`, `rakun.server.*`, `rakun.config.*`, `rakun.profiles.*`) alongside the application's own

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
| std's `json` returns `@Result<string, string>` with no structured walker (`libs/std/src/json.bp:9-16`), so nested configuration cannot be flattened in botopink. | The `.json` and `.yaml` readers are Erlang, in `rakun_config.erl` | Do the decoding in the sidecar over OTP's `json` module | A `JsonValue` sum type and walker in std — this is front 01's territory and is named here because front 05 is the first front it blocks |

## Test plan

`test/config_test.bp`, `botopink test --target erlang` from `repository/rakun/`, and in the gate as
`zig build test-libs -- --target erlang --lib rakun`.

Fixture documents live under `test/fixtures/config/` and are read by path, so ordering tests set
`rakun.config.location` at the top of the test rather than depending on the working directory. The
environment-variable and cloud-platform tests set variables through `env.write` (`libs/std/src/env.bp:30`)
and clear them afterwards, so they do not leak between test blocks — which matters, because the
property table is process-global by design.

The ordering tests are the ones that earn their keep: eight rows means eight "beats the row below"
assertions plus one full-stack test that sets the same key in all eight and asserts the single winner.

This front is erlang-only. The commonJS row is not covered and does not need to be: the property
table's commonJS half is front 04's pre-existing `runtime.mjs`, and no configuration source is
implemented for it. This front ships no Node file: the property table's commonJS half is front 04's
pre-existing `runtime.mjs`, and a second Node file here would be new Node surface in a BEAM front.

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

Both of this front's original contradictions have been resolved by the coordinator and are recorded
here only so the reasoning survives:

1. **`src/config.mjs` was removed from this front's ownership.** A server front on the erlang target
   must not carry a Node cell, and the Node half of the property table already exists in the frozen
   `runtime.mjs`.
2. **The sidecar is `src/sidecars/rakun_config.erl`, not `src/config.erl`.** The atom `config` collides
   with the emitted `rakun/config` module, so `shipErlSidecars` skips it (`libs.zig:596`) and the
   failure is silent. `fronts.md` now mandates the `src/sidecars/rakun_<name>.erl` form everywhere.
3. **Resolved:** `src/root.bp` and `botopink.json` belong to **front 04**. This front's
   `pub mod config;` and `pub mod profiles;` lines are appended in front-number order, never
   reordering an existing line — the same rule track A uses for `libs/std/src/root.bp`.

## Definition of done

- [ ] `src/config.bp` and `src/profiles.bp` exist; `src/sidecars/rakun_config.erl` compiles under `erlc`
- [ ] All eight sources resolve in the documented order, each with its own test
- [ ] `.properties`, `.json` and the documented YAML subset all load; an unsupported YAML construct is a located error
- [ ] a `.json` value holding `\u0041`, `\b` and `\/` loads as `A`, U+0008 and `/`; a malformed document is refused by `json.parse` naming the file; `grep -n "fn jsonString\|fn jsonUnquote" src/config.bp` is empty
- [ ] `#[configurationProperties]` binds nested records, `Duration` and `DataSize`
- [ ] A missing non-optional location, an unresolvable placeholder, a placeholder cycle, a profile-group cycle and an unparsable typed value each fail the boot with a message naming the input
- [ ] `#[validated]` configuration refuses the boot on a violation
- [ ] The key catalogue lists every key rakun reads
- [ ] `repository/rakun/AGENTS.md` documents the source order, the location syntax and the YAML subset
- [ ] The front's tests are green on its assigned target
