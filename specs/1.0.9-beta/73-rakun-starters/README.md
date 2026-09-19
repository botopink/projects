# Front 73 — rakun Starters

**Track:** B rakun
**Priority:** high — twenty-two `rakun-*` modules with no aggregation means every application declares a dozen dependencies by hand and discovers the one it forgot at run time, as a missing symbol rather than as a resolution error
**Target:** erlang (server) — the descriptors themselves are build metadata, and the code they gate is server code
**Wave:** 4
**Depends on:** 04 · 72 — and it lands after the modules it aggregates exist
**Owns:** `starters/rakun-starter-*/botopink.json`, `starters/rakun-starter-*/src/root.bp`, `starters/README.md`, `src/version_set.bp` · `test/version_set_test.bp`, `test/starter_manifest_test.bp`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs`; and no `modules/rakun-*/botopink.json` — a starter names a module, it does not edit one
**Reference:** `02-desenvolvendo-com-spring-boot.md § Starters`, `§ Sistemas de Build · Gerenciamento de Dependencias` · `11-topicos-avancados.md § Dependency Versions` · <https://docs.spring.io/spring-boot/reference/using/build-systems.html#using.build-systems.starters>
**Replaces:** new — no front in `1.0.6-beta` proposed it

---

## Problem

`repository/rakun/modules/` holds fourteen module directories today and this milestone takes the count
past twenty. Each has its own `botopink.json` and each declares exactly one dependency — `rakun` by
relative path (`modules/rakun-data/botopink.json`). Nothing aggregates them. An application that wants
a web service with a database, a cache and the actuator writes four dependency entries, gets the
versions right four times, and finds out it needed a fifth when `#[cacheable]` turns out to live in
`rakun-cache` rather than in `rakun-core`.

That is the problem Spring's starters solve, and it is the reason `spring-boot-starter-webmvc` is an
empty artifact: the value is not code, it is a curated, versioned, transitively-closed dependency set
with a name a human can remember (`02 § Starters`).

There is a second problem underneath it, and this front is where it surfaces. Front 72's
`#[conditionalOnModule("rakun-data")]` asks whether a module is a declared dependency. That question
only has a useful answer if declaring a dependency is something applications actually do deliberately
rather than by accretion. Starters are what make the condition mean something: "the application asked
for the data subsystem", not "some transitive edge dragged it in".

## Current state

| Piece | Where it is today | Shape |
|---|---|---|
| Module manifests | `modules/rakun-*/botopink.json` (14 of them) | `name`, `version: "0.0.1"`, `src`, `entry: "root.bp"` is implicit, `target: "commonJS"`, `targets: ["commonJS", "erlang"]`, `dependencies: { "rakun": { "path": "../../" } }` |
| rakun's own manifest | `repository/rakun/botopink.json` | `targets: ["commonJS"]` — front 04 adds `erlang`; `files` lists the five modules a consumer loads |
| Dependency shapes accepted | `modules/compiler-cli/src/cli/config.zig:64-73` | Both `["a","b"]` and `{ "a": { "git": …, "branch": … } }`, normalised to `[]DepEntry`; diagnostics `DEP-001` invalid shape, `DEP-002` no source, `DEP-003` ambiguous ref |
| What a dependency source may be | `config.zig:42-46` — `DepSpec { git, path, ref }` | A git URL, or a filesystem path. **No subdirectory field.** |
| Lockfile | `modules/bpmp/src/lockfile.zig:1-40` — `botopink.lock.json`, schema 1 | Pins every package and the toolchain by git commit SHA, carrying `version`, `commit`, `tag`, `constraint`, `sha256`, `source`, `requires[]` |
| Version resolution | `modules/bpmp/src/semver.zig`, `src/resolver.zig`, `src/dep/resolver.zig` | Constraint solving and materialisation exist |
| Starters | none | — |
| A curated version set | none | every module reads `0.0.1` and nothing checks that they agree |

The row that decides this front's shape is `DepSpec`. Every `rakun-*` module is a **directory inside
one git repository**, and a `DepSpec` can name a git URL or a path but not a path *within* a git
checkout. So a starter that says `{ "rakun-data": { "git": "…/rakun.git", "branch": "feat" } }` resolves
to the repository root, whose manifest is named `rakun` and not `rakun-data`. Today the only working
form for an out-of-tree consumer of a module is a relative `path`, which means a checkout of the rakun
repository beside the application. That is recorded as a gap below; it does not block the front, but it
does decide what the first version of a starter can promise.

## Mechanism

### What a starter is

A botopink package with a manifest, a `src/root.bp` that declares no `mod`, and no code. The resolver
needs a root file — it auto-detects `main.bp` for a binary and `root.bp` for a library — so the root
exists and holds the docblock naming what the starter pulls and why. Consumers keep importing from the
real modules (`import {cacheable} from "rakun-cache";`), exactly as a Spring application keeps importing
`org.springframework.*` rather than anything under the starter's own coordinates.

This is not a workaround for something botopink lacks. It is the same design Spring uses, for the same
reason: the aggregate and the API are different things, and fusing them would mean a starter could
never drop a module without breaking an import.

### The starter set

Eight starters, chosen so that each names a subsystem a developer would ask for by name. A module that
belongs to two subsystems is named by both — starters overlap, and the resolver de-duplicates.

| Starter | Pulls | Spring counterpart |
|---|---|---|
| `rakun-starter` | `rakun` (core), `rakun-logging` | `spring-boot-starter` |
| `rakun-starter-web` | `rakun-starter`, `rakun-web`, `rakun-validation` | `spring-boot-starter-webmvc` |
| `rakun-starter-data-sql` | `rakun-starter`, `rakun-data` | `spring-boot-starter-data-jpa` + `-jdbc` |
| `rakun-starter-security` | `rakun-starter`, `rakun-security`, `rakun-session` | `spring-boot-starter-security` |
| `rakun-starter-actuator` | `rakun-starter`, `rakun-actuator`, `rakun-metrics` | `spring-boot-starter-actuator` |
| `rakun-starter-cache` | `rakun-starter`, `rakun-cache` | `spring-boot-starter-cache` |
| `rakun-starter-messaging` | `rakun-starter`, `rakun-messaging` | `spring-boot-starter-amqp` + `-kafka` |
| `rakun-starter-test` | `rakun-starter`, `rakun-test`, `onze` | `spring-boot-starter-test` |

`onze` in the test starter is the existing mocking library (`repository/onze`), not a new one. It is
the only starter that reaches outside the rakun repository, and it is the reason the naming lint below
has to allow a non-`rakun-` name in a dependency list while forbidding one in a starter's own name.

### The version set

`src/version_set.bp` is a single table mapping every module name to the version this release of rakun
pins. It exists because three things need the same answer and would otherwise each invent one:

- front 11's `info` contributor, which reports the framework version and its module versions;
- the naming lint below, which rejects a starter naming a module the set does not know;
- a developer reading `rakun --version` and asking which `rakun-data` that is.

It is authored data, and it is kept honest by a test rather than by discipline: `test/version_set_test.bp`
reads every `modules/rakun-*/botopink.json` and every `starters/rakun-starter-*/botopink.json` through
`std/fs` and fails when a manifest's `version` disagrees with the table, when a module exists with no
table row, or when a table row names a module that does not exist. A version set that can drift from
the manifests is a table of claims, not a version set.

`std/json` is `string -> @Result<string, string>` with no structured walker (`libs/std/src/json.bp:9-16`),
so the test reads the `"version"` field by locating the key and slicing the quoted value rather than by
parsing. That is narrow and it is enough: the field is written by this front's own files, in a shape
this front's own test asserts.

### How a starter reaches front 72

`#[conditionalOnModule("rakun-data")]` is evaluated by `rakun_autoconfig` against the *resolved*
dependency names — the normalised `[]DepEntry` list, which includes transitive entries. So declaring
`rakun-starter-data-sql` makes `#[conditionalOnModule("rakun-data")]` true, which makes
`RakunDataSourceAutoConfiguration` eligible, which makes a `DataSource` appear for an application that
wrote one dependency line and no wiring. That chain is the whole reason both fronts exist, and the
consumer example below is the end-to-end assertion of it.

### What this front does not do

It does not add a package registry, a publish step, or a `bpmp` command. `bpmp` already resolves,
pins and materialises (`modules/bpmp/src/dep/resolver.zig`, `src/lockfile.zig`); this front writes
manifests that it consumes. It also does not change any `modules/rakun-*/botopink.json`: a starter
names a module from the outside, and a module that had to be edited to be aggregated would not be a
module.

## Steps

### Step 1 — the starter package shape

One directory per starter under `starters/`, each with `botopink.json` and `src/root.bp`. The manifest
carries `name`, `version` from the version set, `description`, `src`, `targets: ["commonJS", "erlang"]`
and `dependencies` in the object form. The root file declares no `mod` and holds a `////` docblock
listing what the starter pulls and what an application gets by declaring it.

```jsonc
// starters/rakun-starter-web/botopink.json
{
  "name": "rakun-starter-web",
  "version": "0.0.1",
  "description": "Rakun starter — HTTP server, middleware chain, validation",
  "src": "src/",
  "entry": "root.bp",
  "target": "erlang",
  "targets": ["commonJS", "erlang"],
  "dependencies": {
    "rakun-starter":    { "path": "../rakun-starter" },
    "rakun-web":        { "path": "../../modules/rakun-web" },
    "rakun-validation": { "path": "../../modules/rakun-validation" }
  }
}
```

**Acceptance:**
- [ ] Each of the eight starters loads with no `DEP-001`/`DEP-002`/`DEP-003` diagnostic
- [ ] Each starter's `src/root.bp` declares no `mod` and exports no symbol — a starter that ships code fails the manifest test
- [ ] `botopink build` in each starter directory succeeds and emits nothing importable
- [ ] Every path in every starter's `dependencies` resolves to a directory containing a `botopink.json`
- [ ] Declaring `rakun-starter-web` resolves `rakun`, `rakun-logging`, `rakun-web` and `rakun-validation` transitively, in one resolution pass

### Step 2 — the version set

```bp
// src/version_set.bp
pub type ModuleVersion(
    name: string,
    version: string,
)

pub fn rakunVersion() -> string {
    return "0.0.1";
}

pub fn moduleVersions() -> ModuleVersion[] {
    return [
        ModuleVersion(name: "rakun", version: "0.0.1"),
        ModuleVersion(name: "rakun-web", version: "0.0.1"),
        ModuleVersion(name: "rakun-data", version: "0.0.1"),
    ];
}

pub fn versionOf(name: string) -> string {
    val hit = moduleVersions().find({ m -> m.name == name });
    var out = "";
    if (hit) { m -> out = m.version; };
    return out;
}
```

`versionOf` answers `""` for an unknown module rather than an optional, matching the flat-string
contract `Request.param` already sets in `src/http.bp:30-34`. Callers that need to distinguish absent
from empty compare against the full list.

**Acceptance:**
- [ ] `versionOf("rakun-data")` returns the same string the module's manifest carries
- [ ] `versionOf("nope")` returns `""`
- [ ] `moduleVersions()` names every directory under `modules/` and every directory under `starters/`
- [ ] `test/version_set_test.bp` fails when a manifest version is edited and the table is not
- [ ] `test/version_set_test.bp` fails when a new module directory is added and no row is
- [ ] `rakunVersion()` is the version front 11's `info` contributor reports

### Step 3 — the naming convention and its lint

Official starters are `rakun-starter-*`. Third-party starters are `<project>-rakun-starter`, which is
Spring's convention inverted for the same reason: the prefix is reserved so that a name starting with
`rakun-starter` is a promise the rakun maintainers made (`02 § Convencao de Nomes`).

The lint is `test/starter_manifest_test.bp`, and it runs as part of the ordinary test suite rather than
as a separate tool. It reads every directory under `starters/` and asserts: the directory name equals
the manifest `name`; the name begins with `rakun-starter`; every dependency name is either a known
module, a known starter, or a name listed in the small allow-list for out-of-repo dependencies (`onze`
today); and no dependency is declared twice.

**Acceptance:**
- [ ] A starter directory whose name and manifest `name` disagree fails the lint, naming both
- [ ] A starter named `web-starter` fails the lint naming the required prefix
- [ ] A dependency on an unknown name fails the lint, listing the known names
- [ ] A third-party starter named `acme-rakun-starter` is documented in `starters/README.md` as the correct form and is *not* rejected by the lint's prefix rule, because it is not under `starters/`
- [ ] The allow-list is a literal list in the test file, not a pattern — a new out-of-repo dependency is a deliberate edit

### Step 4 — the auto-configuration tie-in

Nothing in this step is code in this front; it is the acceptance that the two fronts meet. An
application declaring exactly one starter must reach a configured subsystem with no wiring of its own,
and the condition report must say so in those words.

**Acceptance:**
- [ ] An application declaring only `rakun-starter-data-sql` has `#[conditionalOnModule("rakun-data")]` evaluate true
- [ ] The same application declaring only `rakun-starter-web` has it evaluate false
- [ ] A transitive dependency counts: `rakun-starter-web` makes `#[conditionalOnModule("rakun")]` true
- [ ] `rkModulePresent("rakun-starter-web")` is true for the starter itself, so a condition may name either the starter or the module
- [ ] The condition report names the resolved dependency list as the value observed when a module condition fails

### Step 5 — `starters/README.md`

The table of starters, what each pulls, the third-party naming rule, and — stated plainly — the
subdirectory limitation below and what it means for an out-of-tree consumer today. A README that
describes the intended end state without saying which half works is worse than none.

**Acceptance:**
- [ ] Every starter in `starters/` appears in the table, and every row in the table is a directory
- [ ] The third-party convention is stated with an example name
- [ ] The subdirectory limitation is stated with the interim form (`path`) and the condition for lifting it
- [ ] The document names `bpmp` as the resolver and the lockfile as the pin, rather than describing a mechanism rakun does not own

## Examples

- [`examples/one-starter-application-example.bp`](./examples/one-starter-application-example.bp) — an
  application whose entire dependency declaration is `rakun-starter-web` plus
  `rakun-starter-data-sql`, and whose code contains no wiring: the controller, the service, and a
  `Rakun.run`. The manifest is quoted in the header comment because a manifest is not botopink.
- [`examples/version-set-example.bp`](./examples/version-set-example.bp) — the version set read back:
  what `info` reports, what the lint asserts, and what happens for a name nobody pinned.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A dependency cannot name a subdirectory of a git repository. `DepSpec` is `{ git, path, ref }` (`modules/compiler-cli/src/cli/config.zig:42-46`), and every `rakun-*` module is a directory inside one repository, so `{ "git": "…/rakun.git", "branch": "feat" }` resolves to the repository root — whose manifest is named `rakun`. An out-of-tree application therefore cannot depend on a rakun module by git at all. | `examples/one-starter-application-example.bp` — the manifest in its header uses `path` for exactly this reason | A relative `path` dependency, which requires a checkout of the rakun repository beside the application | A `subdir` field on `DepSpec`, carried through `bpmp`'s clone and lockfile the way `ref` already is. This is a toolchain gap, not a language one; it is recorded here because it decides what a starter can promise |

`std/json` having no structured walker is not listed as a gap: it is a known std shape
(`libs/std/src/json.bp:9-16`), this front works within it by slicing one known field, and front 01 is
where a walker would be asked for.

## Test plan

`test/version_set_test.bp` and `test/starter_manifest_test.bp`, run with `botopink test --target erlang`
from `repository/rakun/` and in the gate as `zig build test-libs -- --target erlang --lib rakun`. Both
read the repository's own manifests through `std/fs` (`readText`, `list` — `libs/std/src/fs.bp:33,61`),
so they are filesystem tests and they run on both rows: nothing in them is target-specific, and running
them on commonJS as well costs nothing and catches a `std/fs` divergence.

What they cannot cover: that a *published* starter resolves for a consumer outside this repository.
That path runs through `bpmp` and git, and it is blocked by the subdirectory gap above. The honest
statement of coverage is that the in-tree resolution is tested and the out-of-tree one is not
achievable this milestone; `starters/README.md` says so in the same words.

## Definition of done

- Eight starter directories exist, each with a manifest and a code-free root
- `src/version_set.bp` names every module and every starter, and the test fails on drift in either direction
- The naming lint rejects a wrong prefix, a name/directory mismatch and an unknown dependency
- An application declaring one starter reaches a configured subsystem through front 72, asserted end to end
- `starters/README.md` states the subdirectory limitation and the interim form
- The subdirectory gap appears in a `specs/1.0.10-beta/` spec
- The front's tests are green on its assigned target
