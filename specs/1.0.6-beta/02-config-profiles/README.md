# Front 02 — Externalized Configuration & Profiles

**Priority:** critical — Spring Boot's power comes from externalized config; without it, apps can't target multiple environments
**Depends on:** none (parallel with F01)
**Owns:** `src/config.bp`, `src/config.erl`, `src/config.mjs`, `src/profiles.bp`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.erl`

---

## Problem

Rakun's `#[value("key")]` reads from a flat key-value store (`rkProp`/`rkPropInt`) seeded manually. There is no:
- YAML/properties file loading
- Environment variable mapping
- Profile-specific configuration (`application-dev.yaml`, `application-prod.yaml`)
- Config property ordering/priority
- `@ConfigurationProperties`-style typed binding

Spring Boot applications need all of these to run in different environments without code changes.

## Current state

- `runtime.mjs` has a `props` Map with `setProp`/`prop`/`propInt` — flat, string-only, manually seeded
- `#[value("key")]` in `decorators.bp` reads from `rkProp`/`rkPropInt` — works but no source behind it
- No file loading, no env var mapping, no profiles
- Example app seeds props manually (not shown in current examples, but the mechanism exists)

## Mechanism

Spring Boot's config resolution order (simplified for Rakun):

1. Command-line arguments
2. OS environment variables (`RAKUN_SERVER_PORT` → `server.port`)
3. Profile-specific config (`application-{profile}.yaml`)
4. Application config (`application.yaml`)
5. Default values in `@ConfigurationProperties`

Rakun will implement:
- **YAML loading** via `std.json` (YAML subset that's valid JSON, or a YAML parser)
- **Env var mapping** via `std.env` (`RAKUN_SERVER_PORT` → `server.port`)
- **Profiles** via `rakun.profiles.active` property
- **Typed binding** via new `#[configurationProperties("prefix")]` decorator

## Steps

### Step 1 — YAML config file loading

Load `application.yaml` (or `application.json`) from the working directory at startup. Use `std.fs.readText` + `std.json.parse`.

```bp
// config.bp
import {fs, json} from "std";

pub fn loadConfigFile(path: string) -> @Result<Dict<string, string>, string> {
    val content = fs.readText(path);
    // flatten nested JSON to dot-notation keys
    // { "server": { "port": 8080 } } → { "server.port": "8080" }
}
```

**Acceptance:**
- [ ] `application.yaml` loaded from cwd at startup
- [ ] Nested keys flattened to dot-notation
- [ ] Values accessible via `rkProp("server.port")`

### Step 2 — Environment variable mapping

Map env vars to config keys: `RAKUN_SERVER_PORT` → `server.port`. Use `std.env.vars()`.

```bp
pub fn loadEnvVars() -> Dict<string, string> {
    val vars = env.vars();
    // filter RAKUN_* prefix, strip prefix, lowercase, replace _ with .
    // RAKUN_SERVER_PORT → server.port
}
```

**Acceptance:**
- [ ] `RAKUN_SERVER_PORT=9090` overrides `server.port`
- [ ] Env vars take precedence over file config
- [ ] Non-RAKUN_ vars ignored

### Step 3 — Profile support

Activate profiles via `rakun.profiles.active=dev,prod`. Load `application-dev.yaml` after `application.yaml`.

```bp
pub fn loadProfileConfig(profiles: Array<string>) -> Dict<string, string> {
    // for each profile, load application-{profile}.yaml
    // later profiles override earlier ones
}
```

```bp
#[value("rakun.profiles.active")]
profiles: string,  // "dev,prod"
```

**Acceptance:**
- [ ] `rakun.profiles.active=dev` loads `application-dev.yaml`
- [ ] Profile config overrides base config
- [ ] Multiple profiles: last wins

### Step 4 — Config priority ordering

Implement priority: CLI args > env vars > profile config > base config > defaults.

```bp
pub fn resolveProperty(key: string) -> string {
    // check in order: cliArgs, envVars, profileConfig, baseConfig, defaults
}
```

**Acceptance:**
- [ ] CLI arg `--server.port=9090` overrides env var
- [ ] Env var overrides file config
- [ ] Profile config overrides base config

### Step 5 — `@ConfigurationProperties` decorator

New decorator for typed config binding:

```bp
#[configurationProperties("my.service")]
pub type MyServiceConfig(
    enabled: bool,
    remoteAddress: string,
    timeout: i32,
)
```

Auto-binds `my.service.enabled`, `my.service.remote-address`, `my.service.timeout`.

```bp
pub fn configurationProperties(comptime decl: @Decl, prefix: string) {
    // @emit a factory that reads each field from config
    // field name → prefix + "." + kebab-case(field-name)
    // type coercion: string → bool, i32, etc.
}
```

**Acceptance:**
- [ ] `#[configurationProperties("my.service")]` binds fields from config
- [ ] Kebab-case binding: `remote-address` → `remoteAddress`
- [ ] Type coercion: string "true" → bool true, "8080" → i32 8080
- [ ] Default values used when property not set

### Step 6 — Erlang runtime for config

Implement config loading in `config.erl`:

```erlang
-module(rakun_config).
-export([load_file/1, load_env/0, resolve/1, set_prop/2, get_prop/1]).

load_file(Path) ->
    {ok, Content} = file:read_file(Path),
    % parse JSON/YAML, flatten, store in ETS
    ok.

load_env() ->
    % read os:getenv(), filter RAKUN_, map to keys
    ok.
```

**Acceptance:**
- [ ] Config loading works on Erlang target
- [ ] ETS table stores resolved properties
- [ ] `get_prop/1` returns correct value with priority

### Step 7 — Bootstrap integration

`Rakun.run()` loads config before starting the server:

```bp
pub fn run(app: App) {
    rkLoadConfig();  // load files, env, profiles
    val _port = rkServe(rkPropInt("server.port"), ...);
}
```

**Acceptance:**
- [ ] `Rakun.run()` loads `application.yaml` automatically
- [ ] `server.port` from config used instead of `App.port`
- [ ] Profiles activated before server starts

## Gate

- [ ] `botopink test --target commonJS` green
- [ ] `botopink test --target erlang` green
- [ ] Example app loads `application.yaml` and reads `server.port`
- [ ] `RAKUN_SERVER_PORT=9090` overrides file config
- [ ] `rakun.profiles.active=dev` loads `application-dev.yaml`
- [ ] `#[configurationProperties]` binds typed config

## Blast radius

- **rakun-core** gains `config.bp`, `config.erl`, `config.mjs` — new files, no changes to existing
- **`#[value]`** now reads from loaded config instead of manual seeding — backward compatible (manual `rkSetProp` still works)
- **Bootstrap** calls `rkLoadConfig()` before `rkServe` — minor change to `bootstrap.bp`
- **Example app** can now use `application.yaml` instead of manual prop seeding

## Notes

- YAML support: start with JSON (valid YAML subset), add full YAML later if needed
- Env var mapping follows Spring Boot convention: `RAKUN_` prefix, uppercase, `_` → `.`
- `@ConfigurationProperties` is a new decorator — does not break existing `@value`
- Config file location: cwd for now, `rakun.config.location` property later
- No encryption support in this front (Spring Cloud Vault is out of scope)
