# Front 81 — rakun Packaging and Release

**Track:** B rakun
**Priority:** high — nothing in the milestone produces a deployable artefact; fronts 04–25 are libraries an application has to be assembled from by hand
**Target:** erlang (server)
**Wave:** 6
**Depends on:** 04 (the release boots front 04's application and supervision tree), 05 (`sys.config` is where front 05's property file lands on a real deployment), 01 (`io.fs`, `path`), 76 (the probe paths the Kubernetes fragments point at), 11 (serves the SBOM this front emits)
**Owns:** `modules/rakun-release/botopink.json`, `modules/rakun-release/src/**`, `modules/rakun-release/templates/**` · `modules/rakun-release/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone. It generates files; it changes no running code
**Reference:** `08-container-images.md § Imagens Eficientes · Layering`, `§ Dockerfiles`, `§ Cloud Native Buildpacks`, `§ Reproducao e Cache` · `10-otimizacao-producao.md § Deployments Eficientes`, `§ Checkpoint e Restore (CRaC)` · `11-topicos-avancados.md § Deploy de Aplicacoes`, `§ Servico de SO`, `§ Apendice · Executable Jars` · `09-actuator.md § SBOM` · <https://docs.spring.io/spring-boot/reference/packaging/container-images/index.html> · <https://docs.spring.io/spring-boot/reference/packaging/efficient.html> · <https://docs.spring.io/spring-boot/how-to/deployment/installing.html>

---

## Problem

Twenty-two fronts in track B deliver libraries. None of them delivers a thing you can copy to a
server and start. There is no release descriptor, no boot script, no `sys.config`, no `vm.args`, no
tarball, no Dockerfile, no service unit — and no answer to the question a deployment asks first,
which is "what exactly am I starting, and with what on the code path".

Spring's answer is the executable jar: one file containing the application, its dependencies and a
loader that knows how to run them. `11 § Apendice · Executable Jars` describes it, `08 § Layering`
splits it into cache-friendly layers, `10 § Deployments Eficientes` extracts it again for a faster
start. All three are shapes of one idea — ship a self-contained artefact whose slow-changing parts
are separable from its fast-changing ones.

The BEAM has had that artefact since before the jar existed. An OTP release is a directory containing
the ERTS, the applications it needs at the versions it needs, a boot script that starts them in
dependency order, and configuration. It is the thing `rebar3 release` produces and the thing every
Erlang deployment in production is. rakun produces none of it, so today a rakun application is
deployed by copying a source tree next to an Erlang installation and hoping the code path is right.

There is a second absence behind the first. The actuator's `sbom` endpoint (`09 § SBOM`) serves a
software bill of materials that something else is supposed to have generated at build time. Front 11
can serve it; nothing produces it. A supply-chain question — "which version of which dependency is in
production" — currently has no answer that is not a person reading manifests.

## Current state

| Piece | Where it is today |
|---|---|
| `modules/rakun-release/` | `release.bp` (the renders, the tarball, the deployment files, the appup), `sbom.bp`, `src/sidecars/rakun_release.erl` |
| A release descriptor of any kind | nothing, in rakun or in botopink |
| `botopink.json` | `{name, version, description, src, target, targets, files}` for rakun; module manifests add `entry` and a `dependencies` map (`modules/rakun-security/botopink.json`) |
| What `botopink build` emits for erlang | `.erl` sources plus the sibling `.erl` sidecars `shipErlSidecars` copies flat (`modules/compiler-cli/src/cli/libs.zig:564-635`) — a directory of sources, not a release |
| Sibling loading | emitted under the **test** entry point only (`modules/compiler-core/src/codegen/erlang.zig:1649-1678`); front 04 records this as a blocker for `build`/`run` |
| A Dockerfile, a systemd unit, a k8s manifest | nothing anywhere in the repository |
| An SBOM | nothing. `09 § SBOM` is the consumer with no producer |

The sibling-loading limitation front 04 recorded is this front's central constraint, and it is worth
stating plainly: **until an erlang `build` output can find its sidecars, a release cannot boot.** This
front's artefacts are correct and testable without it — they are generated text — but the end-to-end
"the tarball starts and serves" acceptance depends on it. It is named under *Blocked*.

## Mechanism

### The front is a generator

Every deliverable here is a file rendered from a value. The developer writes a `Release` record; the
module renders six artefacts from it:

| Artefact | From | Upstream analogue |
|---|---|---|
| `rel/<name>.rel` | applications + versions | the jar manifest |
| `rel/sys.config` | front 05's configuration for the target profile | `application.yaml` on the classpath |
| `rel/vm.args` | node name, cookie source, scheduler and process limits | JVM flags |
| `Dockerfile` | the layer plan | `08 § Dockerfile Basico` + `layers.idx` |
| `<name>.service` | the release's boot script path and user | `11 § Servico de SO` |
| `sbom.json` | the resolved dependency set | `09 § SBOM` |

That makes the whole front testable with string assertions, which is the reason it can be green
without a container runtime, a registry or a Kubernetes cluster in the gate. A test that needs Docker
to pass is a test that does not run.

### Layers, translated

`08 § Layering` splits a jar four ways by rate of change: released dependencies, the loader, snapshot
dependencies, application code. A release splits the same way and the names are already OTP's:

| Spring layer | Release layer | Why it changes at a different rate |
|---|---|---|
| `dependencies` | `erts-*/` plus every OTP application | changes when the OTP version changes, which is quarterly at most |
| `spring-boot-loader` | `bin/` and the boot scripts | changes when the release tooling changes |
| `snapshot-dependencies` | `lib/rakun-*` and other path dependencies | changes when the framework moves |
| `application` | `lib/<app>-<vsn>/` | changes on every commit |

The generated Dockerfile puts each in its own `COPY`, in that order, so a code-only change invalidates
one layer and the image push is kilobytes. That is `layers.idx` by another name and it needs no index
file, because a release is already a directory tree split along exactly those lines.

### `-mode embedded`, and what it replaces

`10 § AOT Cache` and `§ CDS` both optimise the JVM's per-start class-loading cost. The BEAM has no
class loader, so neither has a translation — the audit defers both. The adjacent win that does exist
is `-mode embedded`: the boot script loads every module up front instead of resolving them lazily on
first call, which removes code-server round trips from the first requests after a start. It is one
line in `vm.args` and it is generated by default for a release, interactive shells excepted.

### Release upgrades, and the CRaC question

`10 § Checkpoint e Restore (CRaC)` is deferred — BEAM has no heap-image format and nothing is building
one. But CRaC's *operational goal* is not "snapshot a heap"; it is **redeploy without dropping
traffic**, and that goal is served here, by a different road. An OTP release upgrade (`appup` per
application, `relup` across the release) loads the new code into the running node, runs the state
transformations the `appup` declares, and switches over — connections intact, ETS intact, no second
process to drain into.

So the honest statement, which this README makes and the deferred table in the audit agrees with:
CRaC itself is deferred because the mechanism does not exist on BEAM; the thing people want CRaC for
is delivered by this front's step 5. Those are two different sentences and collapsing them into one
is how a spec ends up promising a checkpoint format nobody is writing.

The hot code loading in front 80 is the same underlying VM facility and a completely different
posture: front 80 is fast, unsafe and developer-only, with no state migration and no version rules.
This front is slow, verified and production-only, with declared state transformations and a rollback.
Neither replaces the other, and the boundary is that front 80 never generates an `appup`.

### The SBOM

CycloneDX 1.5 JSON, emitted at build time from the resolved dependency set: for each component its
name, version, the path or remote it came from, and a hash of its source tree. Front 11 serves it at
`/actuator/sbom`; this front writes it. The dependency set has to be resolved by walking
`botopink.json` manifests transitively — see *Language gaps* for why that walk cannot happen at
comptime and is therefore a build-time pass over the filesystem.

### Reproducible builds

`08 § Reproducao e Cache` notes that buildpacks normalise resource timestamps, and that an application
depending on those timestamps needs `spring.web.resources.cache.use-last-modified=false`. Both halves
land here: the release writer normalises every mtime it writes to a fixed epoch so two builds of the
same source produce byte-identical tarballs, and the generated configuration sets
`rakun.web.static.use-last-modified=false` — front 82's switch — because after normalisation a
`Last-Modified` header is a lie. ETags, which front 82 derives from content, are unaffected and become
the only conditional-request mechanism that means anything.

## Steps

### Step 1 — The `Release` value and the `.rel` file

```bp
pub type VmArgs(
    nodeName: string,
    cookieEnv: string,
    schedulers: i32,
    maxProcesses: i32,
    embedded: bool,
)

pub type Release(
    name: string,
    version: string,
    erts: string,
    applications: string[],
    vmArgs: VmArgs,
    configProfile: string,
)

pub fn renderRel(r: Release) -> string
pub fn renderVmArgs(r: Release) -> string
pub fn renderSysConfig(r: Release, props: Array<#(string, string)>) -> string
```

Templates are built by joining line arrays with `"\n"` rather than as triple-quoted literals: the
`"""…"""` form is verified in tagged-template and external-cell position, and this front does not
depend on it holding anywhere else.

**Acceptance:**
- [x] `renderRel` lists `kernel` and `stdlib` first, in that order, whatever order the application named them — `modules/rakun-release/test/release_test.bp` "release: the .rel puts kernel and stdlib first; a duplicate application is refused naming it"
- [x] An application listed twice is an error naming it, not a duplicate line — same test
- [x] `renderVmArgs` emits `-mode embedded` unless `embedded` is false — `modules/rakun-release/test/release_test.bp` "release: vm.args is embedded unless asked, and the cookie is a reference, never a value"
- [x] The cookie is emitted as a reference to `cookieEnv`, never as a literal — a cookie in a generated file is a cookie in a git repository — same test
- [x] `renderSysConfig` round-trips a property containing a quote, a newline and a UTF-8 character — `modules/rakun-release/test/release_test.bp` "release: sys.config round-trips a quote, a newline and UTF-8, and renders the same bytes twice"
- [x] Two renders of the same `Release` produce byte-identical output — same test

### Step 2 — The tarball

A self-contained directory — `bin/`, `lib/<app>-<vsn>/ebin/`, `releases/<vsn>/`, and the ERTS when the
release is built for a host without Erlang installed — packed with normalised mtimes and sorted
entries.

**Acceptance:**
- [x] Two builds from the same source produce byte-identical tarballs, including mtimes and entry order — `modules/rakun-release/test/release_test.bp` "release: two builds in two directories are the same bytes, with no source and nothing outside the applications"
- [x] The tarball contains no source file, no `.botopinkbuild/`, and no file outside the declared applications — same test
- [ ] Unpacking it and running `bin/<name> foreground` starts the node (gated by *Blocked* below) — open: blocked (see Blocked) — a built erlang program cannot load its `.erl` sidecars
- [x] A release naming an application that is not on the code path fails the build, naming it — not at boot — `modules/rakun-release/test/release_test.bp` "release: an application with no directory fails the build naming it"

### Step 3 — The Dockerfile

Multi-stage: a builder stage that compiles and assembles, a runtime stage that copies four layers in
change-rate order. The runtime stage runs as a non-root user and declares no shell entry point.

**Acceptance:**
- [x] The generated Dockerfile has exactly four `COPY` instructions from the builder stage, in ERTS → OTP → framework → application order — `modules/rakun-release/test/release_test.bp` "release: the Dockerfile copies four layers in change-rate order into a non-root runtime with the release script as entry"
- [x] Changing one application source file changes only the last layer's content hash — `modules/rakun-release/test/release_test.bp` "release: changing one application file changes only the application layer's hash"
- [x] The runtime stage contains no compiler, no source and no build tool — `modules/rakun-release/test/release_test.bp` "release: the Dockerfile copies four layers in change-rate order into a non-root runtime with the release script as entry"
- [x] `USER` is set to a non-root user and `WORKDIR` is the release root — same test
- [x] The image's entry point is the release boot script, not `sh -c` — same test

### Step 4 — systemd unit and Kubernetes fragments

`11 § Servico de SO` gives the unit shape. The Kubernetes fragments are a `Deployment` with liveness
and readiness probes pointing at front 76's paths, plus the `terminationGracePeriodSeconds` that
front 07's request draining needs to be true.

**Acceptance:**
- [x] The unit's `ExecStart` is the release's `foreground` script, so systemd supervises the node directly rather than a daemonising wrapper — `modules/rakun-release/test/release_test.bp` "release: the systemd unit runs the foreground script as its user, restarting on failure"
- [x] `Restart=on-failure` and a documented `RestartSec` — same test
- [x] The unit runs as the configured user and group and does not require root — same test
- [x] The readiness probe path is exactly front 76's readiness path — asserted by importing that front's constant, not by repeating the string — `modules/rakun-release/test/release_test.bp` "release: the Deployment's probes are front 76's paths, and a grace period inside the drain is refused" (`readinessPath()` / `livenessPath()` imported from rakun-actuator's `management`)
- [x] `terminationGracePeriodSeconds` is greater than front 07's configured shutdown timeout, and generation fails when it is not — same test

### Step 5 — Release upgrades

`appup` per application, `relup` across the release, a generated upgrade plan, and a rollback. The
plan names, for each changed module, whether it is a simple load or a `code_change` with a state
transformation, and refuses to generate when a `gen_server`'s state shape changed and no
transformation was declared.

**Acceptance:**
- [x] Upgrading a release whose only change is a function body generates a load-only `appup` — `modules/rakun-release/test/release_test.bp` "release: a body change loads, a supervisor updates as one, a state change without code_change refuses"
- [x] A changed supervisor child specification generates a supervisor-aware plan, not a load — same test
- [x] A changed `gen_server` state with no declared transformation **fails generation**, naming the module — same test
- [ ] An upgrade applied to a running node serves every request during the switch-over — asserted by a request loop across the upgrade with zero failures — open: the appup is generated; applying it to a running node needs a booting release (Blocked) and `release_handler`
- [ ] A downgrade to the previous version exists, is generated at the same time, and is tested on the same node — open: the downgrade instructions are generated beside the upgrade (`renderAppup`), untested on a node for the same reason
- [x] The README states that this is the answer to CRaC's operational goal and that CRaC itself is deferred — this README, § Release upgrades, and the CRaC question

### Step 6 — SBOM

CycloneDX 1.5 JSON over the transitively resolved dependency set.

**Acceptance:**
- [x] Every dependency in the manifest tree appears exactly once, with name, version and source — `modules/rakun-release/test/release_test.bp` "release: the SBOM names every dependency once, hashes a path dependency's tree, and is valid when empty"
- [x] A path dependency carries a hash of its source tree, so two builds against a moved sibling differ — same test (the hash moves with the sibling's content)
- [ ] The document validates against the CycloneDX 1.5 schema — asserted against a checked-in schema, with no network access — open: std has no JSON-schema validator; the document carries CycloneDX 1.5's required fields (`bomFormat`, `specVersion`, `version`, components with `type`/`name`/`version`), asserted field by field
- [x] Front 11 serves the file at `/actuator/sbom` unmodified, with the media type the endpoint declares — `modules/rakun-release/test/release_test.bp` "release: front 11 serves the SBOM file unmodified with its media type"
- [x] A build with no dependencies produces a valid document with an empty component list, not an empty file — `modules/rakun-release/test/release_test.bp` "release: the SBOM names every dependency once, hashes a path dependency's tree, and is valid when empty"

### Step 7 — Reproducibility

Normalised mtimes, sorted entries, and the `use-last-modified=false` default the doc calls for.

**Acceptance:**
- [x] Building the same commit twice, an hour apart, in two directories, produces identical bytes — `modules/rakun-release/test/release_test.bp` "release: two builds in two directories are the same bytes, with no source and nothing outside the applications" (mtime 0 in every entry, so the hour between builds cannot show)
- [x] The generated configuration sets `rakun.web.static.use-last-modified=false` — `modules/rakun-release/test/release_test.bp` "release: sys.config round-trips a quote, a newline and UTF-8, and renders the same bytes twice"
- [x] Front 82's ETag path is unaffected and still answers 304 for an unchanged asset — `modules/rakun-web/test/static_test.bp` "static: a first request is 200 with an ETag, and If-None-Match answers 304", "static: Last-Modified is emitted and honoured only with useLastModified"

## Examples

- [`examples/release-manifest-example.bp`](./examples/release-manifest-example.bp) — the `Release` an
  application writes, and the six artefacts rendered from it. Every assertion in the file is a string
  assertion, which is what lets this front be green in a gate with no container runtime.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Comptime has no reflection over the project: `@Decl` describes the one declaration it annotates, and there is no way to enumerate the modules of a package or read its manifest at compile time. The release's application list and the SBOM's component set therefore cannot be derived — they are written by hand or discovered by a build-time filesystem walk. | `examples/release-manifest-example.bp`, the hand-written `applications` array | List the applications explicitly, and resolve dependencies at build time with `fs.list` over the manifest tree | A comptime project view — `@Project.modules()` / `@Project.manifest()` — so a release descriptor cannot drift from the thing it describes |
| `@Decl` carries no source location, so no decorator can tell which file or module a declaration came from; a layer plan cannot be derived from where code lives. | Not visible in the example — it is why the layer plan is four fixed layers rather than a computed partition | Fixed layers by change rate, which is what the upstream does anyway | `decl.source()`, as fronts 22 and 80 propose for the same gap |

## Test plan

`modules/rakun-release/test/`, run with `botopink test --target erlang` from
`modules/rakun-release/`, and in the gate as `zig build test-libs -- --target erlang --lib rakun`.

Steps 1, 3, 4, 6 and 7 are tested entirely by rendering to a string and asserting on it — no Docker,
no systemd, no cluster, no network. The CycloneDX validation runs against a schema checked into
`test/fixtures/`, for the same reason.

Steps 2 and 5 cannot be fully covered that way. The tarball's *content* is asserted by unpacking into
a scratch directory under `.botopinkbuild/tmp/`; its *bootability* is gated by the sibling-loading
limitation below and is asserted as far as it can be — the boot script exists, is executable, and
names the right release. The upgrade tests run against a fixture release with two versions, on a node
the test starts and stops, and the zero-downtime assertion is a request loop across the switch-over
with a failure count of zero. That test is slow by nature and is the one place in this front where a
timeout is a real risk; it carries its own budget and is skipped with a named reason when the node
cannot be started, never silently passed.

This front is erlang-only and has no client half: a release is a BEAM artefact.

## Blocked

- **An erlang `build` output cannot load its `.erl` sidecars.** `__bp_load_siblings/0` is emitted for
  the test entry point only (`modules/compiler-core/src/codegen/erlang.zig:1649-1678`), so a built
  program dies with `undefined function rakun_runtime:serve/2`. Front 04 recorded this; it blocks
  step 2's "the tarball starts and serves" acceptance and nothing else in this front. The fix is one
  emitter change and belongs to whoever owns the erlang entry-point emitter.

## Definition of done

- [ ] `modules/rakun-release/` exists with its manifest, `src/` and `templates/` — open: the member has its manifest and `src/`; there is no `templates/` — every file is rendered from line arrays in `release.bp` (the front's own rule)
- [x] A `Release` value renders `.rel`, `vm.args`, `sys.config`, a Dockerfile, a systemd unit and the
      Kubernetes fragments, all deterministically — `release_test.bp` (every render asserted twice-equal where it matters)
- [x] Two builds of one commit produce byte-identical tarballs — `modules/rakun-release/test/release_test.bp` "release: two builds in two directories are the same bytes, with no source and nothing outside the applications"
- [x] The Dockerfile splits four layers in change-rate order and the runtime stage carries no build tool — `modules/rakun-release/test/release_test.bp` "release: the Dockerfile copies four layers in change-rate order into a non-root runtime with the release script as entry"
- [x] `relup` generation refuses a changed `gen_server` state with no declared transformation — `modules/rakun-release/test/release_test.bp` "release: a body change loads, a supervisor updates as one, a state change without code_change refuses" (the appup; a relup is not generated)
- [x] A CycloneDX SBOM is emitted at build time and served unmodified by front 11 — `modules/rakun-release/test/release_test.bp` "release: front 11 serves the SBOM file unmodified with its media type"
- [x] The README states the CRaC position: the mechanism is deferred, the operational goal is step 5 — this README, § Release upgrades, and the CRaC question
- [x] `repository/rakun/AGENTS.md` documents the release layout and the layer split — `repository/rakun/AGENTS.md` § Packaging and release
- [x] The front's tests are green on its assigned target — 12 tests (erlang)

