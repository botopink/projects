# Front 71 — onze Release Packaging

**Track:** E onze
**Priority:** medium — without it `onze build` produces artifacts that only run from the source tree
with a full toolchain present, and the milestone's exit gate requires `onze build && onze start`
**Target:** both — the release descriptor and the build-id derivation are read by the BEAM server at
boot and written by the build host; the client asset tree it packages is the js half
**Wave:** 8 — after front 68's manifest and front 69's asset tree exist to be packaged
**Depends on:** 04 (the BEAM runtime being packaged) · 50 (the CLI entry points; `onze start` runs
what this front produces) · 68 (the client assets and the manifest) · 69 (the static asset tree and
`public/`) · 60 (the prerender manifest) · 03 (the build id) · 05 (runtime configuration and
profiles) · 11 (health and readiness endpoints) · 62 (the request-scoped `after()` work that a
shutdown has to drain) · 01 (`process.run`, `fs`, `path`)
**Owns:** `repository/onze/modules/onze-release/src/**`,
`repository/onze/modules/onze-release/test/**`
**Does not touch:** `repository/onze/modules/onze-cli/**` (front 50 — it calls this front, it does
not contain it), `repository/onze/modules/onze-bundler/**` (front 68),
`repository/onze/modules/onze-assets/**` (front 69), `repository/rakun/src/**`
**Reference:** `NEXTJS-DOCS.md § 24. Deploy` (Self-hosting · Docker · Static Export),
`§ 28. Configuração` (`output`, `generateBuildId`, `env`), `§ 2. Instalação e Configuração` (scripts),
`§ 29. CLI` (`next start`) ·
<https://nextjs.org/docs/app/getting-started/deploying> ·
<https://nextjs.org/docs/app/api-reference/config/next-config-js/output> ·
<https://www.erlang.org/doc/apps/sasl/systools.html>

---

## Problem

`§ 24` is a whole section about getting an app onto a server, and this milestone's answer to it today
is "run it from the checkout". `onze build` (front 50) compiles the app to BEAM modules under a
build directory and writes a client asset tree beside them. To run that you need the botopink
compiler, the source tree, the dependency repositories at the right revisions, and whatever version
of OTP the developer happened to have. That is a development setup, not an artifact.

Next's answer is `output: 'standalone'` plus the Dockerfile in `§ 24`: trace the files the server
actually needs, copy them and the static tree into an image, run it as a non-root user on `PORT`. The
BEAM answer is strictly easier and nobody has written it. An OTP release *is* the standalone output —
the beam files, their applications, a boot script and, optionally, the ERTS itself — and it has been
in OTP since before file tracing was a problem anyone had. What is missing is the front that assembles
it, stamps the build id through it, and generates the container image around it.

The build id is the sharp edge. `contracts.md § 2` puts `b` — the build id — in every payload, front
68 puts it in every asset URL, and front 60 keys the prerender manifest on it. If the release's build
id is derived a second time, at a second moment, from a second input, then a deployment can serve a
payload from one build and assets from another, and the failure is a page that hydrates against the
wrong bundle. One derivation, stamped once, read everywhere.

## Current state

- `repository/onze/` does not exist; this front creates `modules/onze-release/` inside it.
- Nothing in the workspace produces a deployable artifact. There is no `rel/`, no `.rel` file, no
  `sys.config`, no `vm.args` and no Dockerfile anywhere under `repository/`.
- `repository/rakun/src/bootstrap.bp:28-37` — `Rakun.run(app)` starts the HTTP server from inside a
  running program. That is the thing a boot script has to call, and it is the only start path that
  exists.
- `repository/rakun/src/runtime.mjs` plus the `rk*` cells are Node-only today; front 04 is what makes
  a BEAM-only artifact possible at all, which is why this front depends on it rather than working
  around it.
- Front 01 records that there is **no byte or binary type**, so every archive this front produces is
  produced by an external command, never assembled in botopink.
- `libs/std/src/env.bp:24` — `read(name) -> ?string`, which is how a release reads its configuration
  at boot rather than at build time.

## Mechanism

### What a release is here

```
<outDir>/release/
  releases/<buildId>/            start.boot, sys.config, vm.args, onze.rel
  lib/<app>-<vsn>/ebin/          every compiled BEAM module, app by app
  erts-<vsn>/                    optional: the runtime system itself
  static/<buildId>/              front 68's chunks and front 69's stylesheets
  public/                        front 69's public tree, copied verbatim
  prerender/                     front 60's prerendered routes and its manifest
  bin/onze                     the boot script front 50's `start` executes
  BUILD_ID                       one line, the build id
```

`releases/`, `lib/` and `erts-` are OTP's own layout, not an invention: the release is assembled by
`systools:make_script/2` and `systools:make_tar/2`, invoked through front 01's `process.run` as
`erl -noshell -eval`. **OTP's own tooling, not rebar3** — rebar3 is a fine tool and requiring it would
add a second build system to a project that already has one. The `.rel` file is generated from the
descriptor; everything `systools` needs is a text file this front writes.

Including ERTS is a flag (`includeErts`), and it is the difference between an image that needs no
Erlang installed and one that does. The default is to include it, because the default deployment is a
container and a container that depends on the host's OTP version is a container that breaks on a base
image bump.

### The descriptor

```bp
pub type ReleaseSpec(
    name: string,
    version: string,
    buildId: string,
    apps: Array<#(string, string)>,   // application name -> version
    includeErts: bool,
    ertsVersion: string,
    otpRelease: string,
    outDir: string,
)
```

`buildId` comes from front 03 and from nowhere else: `generateBuildId` is
`content_hash` over the sorted list of every compiled module's own hash plus the client manifest's
hash. Deterministic, so two builds of an unchanged tree produce the same release and a deployment can
tell whether anything actually changed. `§ 28`'s `generateBuildId` escape hatch — a user-supplied
function — is honoured as a config value that *replaces* the derivation, with one rule: a supplied id
must be non-empty and must match `[A-Za-z0-9_-]{1,64}`, because it ends up in a URL path.

**The build id is stamped in four places and asserted equal in all four:** `BUILD_ID`, the release
directory name, the client manifest's `buildId`, and the payload's `b` key. `verifyBuildId(release)`
is a function, not a convention, and front 50's `start` runs it before it boots.

### The container image

`§ 24`'s Dockerfile, ported. Multi-stage, non-root, `PORT` honoured:

```dockerfile
FROM erlang:27-alpine AS build
WORKDIR /src
COPY . .
RUN onze build

FROM alpine:3.20 AS runner
RUN addgroup -S onze && adduser -S -G onze onze
WORKDIR /app
COPY --from=build --chown=onze:onze /src/.onze/release ./
USER onze
ENV PORT=3000
EXPOSE 3000
CMD ["bin/onze", "start"]
```

The runner stage is `alpine` rather than `erlang` because the release carries its own ERTS; with
`includeErts: false` the generated file uses the `erlang` base image instead, and the generator picks
by the flag rather than by a comment telling the reader to edit it. `generateDockerfile(spec)` is a
pure function returning a string, so what it produces is asserted by a test rather than reviewed by
eye.

Three properties are non-negotiable and each is a test: the runner never runs as root, the build stage
never appears in the final image, and no environment value is baked into the image — see below.

### Configuration at boot, not at build

One image must serve every environment, which means the release reads its configuration when it
starts. Front 05 owns profiles; this front owns the rule that the release contains **no resolved
configuration at all**, only defaults: `sys.config` carries the app's static defaults, and every
deployment-specific value is an environment variable read at boot through `libs/std/src/env.bp:24`.

The one exception is the public environment table, which front 68 inlined into the client bundle at
build time because a browser cannot read an environment. That table is already restricted to
`ONZE_PUBLIC_`-prefixed names by front 49's rule and front 68's enforcement. This front adds a check
at package time: **if a release's client asset tree contains a string matching a non-public
environment value present at build time, packaging fails.** It is a belt-and-braces check behind
front 68's refusal, it costs one scan, and it is the last moment before an artifact leaves the
building.

### Health, readiness and graceful shutdown

An orchestrator needs to know when to send traffic and when to stop. Front 11 owns the endpoints; this
front wires them into the boot script and defines what they mean for a release:

| Probe | True when |
|---|---|
| liveness | the VM is up and the supervision tree is running |
| readiness | the router has a route table, the client manifest parsed, and every configured datasource answered once |

Readiness is deliberately stricter than liveness: an instance that is up but has no route table will
return 404 for every request, and routing traffic to it is worse than not starting it.

Shutdown is ordered, and the order is the whole point:

1. flip readiness to false, so the load balancer stops sending new requests
2. stop accepting new connections
3. drain in-flight renders, up to `drainTimeout`
4. drain front 62's `after()` work — the request-scoped tasks that outlive the response
5. stop the supervision tree and exit 0

A drain that exceeds its timeout exits non-zero with a count of what was still running, rather than
exiting 0 and letting an orchestrator record a clean shutdown that lost work.

### Static export

`§ 24`'s *Static Export* (`output: 'export'`) is the degenerate case: front 60 prerenders every route,
this front copies the prerendered tree plus the static assets and writes no boot script. It is a
mode of the same packager, and the rule that makes it honest is that **a route that cannot be
prerendered fails the export naming the route** — an app with one dynamic route does not get a
silently incomplete static site.

## Steps

### Step 1 — `ReleaseSpec` and the build id

```bp
pub fn releaseSpec(name: string, version: string, buildId: string) -> ReleaseSpec
pub fn withErts(spec: ReleaseSpec, include: bool) -> ReleaseSpec
pub fn generateBuildId(moduleHashes: Array<string>, manifestHash: string) -> string
pub fn validateBuildId(id: string) -> Array<string>
pub fn verifyBuildId(spec: ReleaseSpec, manifestBuildId: string, payloadBuildId: string) -> Array<string>
```

**Acceptance:**
- [ ] `generateBuildId` is deterministic: the same inputs give the same id, asserted on a literal
- [ ] Reordering the module-hash list does not change the id — it is sorted first
- [ ] Changing one module hash changes the id
- [ ] `validateBuildId("")`, `validateBuildId("has/slash")` and a 65-character id are each rejected,
      naming the offending id
- [ ] `verifyBuildId` returns an error when the release, manifest and payload ids are not all equal,
      and names which two disagree

### Step 2 — The OTP release

```bp
pub fn relFileText(spec: ReleaseSpec) -> string
pub fn sysConfigText(spec: ReleaseSpec, defaults: Array<#(string, string)>) -> string
pub fn vmArgsText(spec: ReleaseSpec) -> string

#[@future]
pub fn assembleRelease(spec: ReleaseSpec) -> @Future<string>
```

**Acceptance:**
- [ ] `relFileText` is a valid Erlang term ending in `.`, names `kernel` and `stdlib` first, and lists
      every app in `spec.apps`
- [ ] `vmArgsText` sets a node name and a cookie read from the environment, never a literal cookie —
      a baked cookie is a remote shell for anyone who reads the image
- [ ] `sysConfigText` contains only defaults; a test asserts no value came from `env.read`
- [ ] `assembleRelease` invokes `systools` through `process.run` and fails with its stderr when the
      script cannot be made
- [ ] With `includeErts: true` the release contains an `erts-<vsn>` directory; with `false` it does
      not, and the generated Dockerfile's runner base image differs accordingly

### Step 3 — Packaging the asset tree

```bp
#[@future]
pub fn packageAssets(spec: ReleaseSpec, manifestPath: string, publicDir: string) -> @Future<Array<string>>
pub fn scanForSecrets(assetTree: Array<#(string, string)>, secrets: Array<string>) -> Array<string>
```

**Acceptance:**
- [ ] Every chunk named by front 68's manifest exists in the packaged tree, and a missing one fails
      packaging naming the chunk
- [ ] Every stylesheet named by front 69's `Y` records exists
- [ ] `public/` is copied verbatim, including files no manifest names
- [ ] `scanForSecrets` finds a non-public environment value present verbatim in a chunk and fails
      packaging naming the variable — the last check before the artifact leaves the building
- [ ] A public (`ONZE_PUBLIC_`-prefixed) value in a chunk is not a finding

### Step 4 — The Dockerfile

```bp
pub fn generateDockerfile(spec: ReleaseSpec) -> string
pub fn generateDockerignore() -> string
```

**Acceptance:**
- [ ] The output has two stages and the runner copies only from the build stage's release directory
- [ ] The runner declares a non-root `USER`, asserted on the literal
- [ ] `PORT` is an `ENV` with a default and is read at boot, not baked into a config file
- [ ] No `COPY` in the runner stage brings in source, the compiler, or `node_modules`
- [ ] `generateDockerignore` excludes `.git`, the build directory and `test/`
- [ ] With `includeErts: false` the runner base image is an `erlang:` image, not `alpine`

### Step 5 — The boot script and `onze start`

```bp
pub fn bootScriptText(spec: ReleaseSpec) -> string
```

**Acceptance:**
- [ ] The script runs `verifyBuildId` before starting and exits non-zero when it fails
- [ ] It honours `PORT`, defaulting to 3000
- [ ] It execs the OTP boot script rather than backgrounding it, so the container's PID 1 is the VM
      and signals reach it
- [ ] Front 50's `start` calls this script and adds no second start path

### Step 6 — Health, readiness and shutdown

```bp
pub type DrainReport(renders: i32, afterTasks: i32, timedOut: bool)

#[@future]
pub fn shutdown(drainTimeoutMs: i32) -> @Future<DrainReport>
pub fn readinessChecks(spec: ReleaseSpec) -> Array<string>
pub fn shutdownOrder() -> Array<string>
```

`shutdownOrder` returns the five step names as data, so the order is asserted by a test rather than
described by a comment above a function that could be edited out of agreement with it.

**Acceptance:**
- [ ] `readinessChecks` lists the route table, the client manifest and each datasource, and readiness
      is false until all three answer
- [ ] Readiness flips to false as step 1 of shutdown, before connections stop being accepted —
      asserted on the call order, because the reverse loses requests
- [ ] `shutdown` drains in-flight renders before front 62's `after()` work
- [ ] A drain that exceeds its timeout returns `timedOut: true` and the process exits non-zero
- [ ] A clean drain exits 0 with both counts at zero

### Step 7 — Static export

```bp
#[@future]
pub fn staticExport(spec: ReleaseSpec, prerendered: Array<#(string, string)>) -> @Future<Array<string>>
```

**Acceptance:**
- [ ] Every prerendered route is written as `<route>/index.html`
- [ ] The static asset tree and `public/` are copied
- [ ] No boot script and no `releases/` directory are produced
- [ ] A route front 60 could not prerender fails the export naming the route — never a partial site

## Examples

- [`examples/release-descriptor-example.bp`](./examples/release-descriptor-example.bp) — describing a
  release: the build id derived once, verified in four places, and the Dockerfile the descriptor
  generates, asserted rather than eyeballed.
- [`examples/boot-and-shutdown-example.bp`](./examples/boot-and-shutdown-example.bp) — configuration
  read at boot instead of baked in, the readiness checks, and the shutdown order that does not lose
  work.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No byte or binary type — also recorded by front 01 | the release tarball and the container image are produced by `systools` and `docker` through `process.run`; nothing archives in botopink | shell out, and keep the generated *text* files (`.rel`, `sys.config`, `vm.args`, `Dockerfile`) in botopink where they can be asserted | a `bytes` primitive plus `fs.readBytes`/`fs.writeBytes` |
| No bitwise operators and no `toString(radix)` — also recorded by front 01 | the build id is front 03's `content_hash`, whose fold lives in a host template | call front 03 | `&`, `\|`, `^`, `<<`, `>>` and `i32.toString(radix)` |
| No assignment to a `self` field | `ReleaseSpec` has `withErts`-style copies rather than setters | return a new record | mutable record fields, or a `with` expression |
| Tuple labels are lost through generic instantiation | `spec.apps` is `Array<#(string, string)>`, read as `a._0` / `a._1` | read positionally | preserve written labels through instantiation |

## Test plan

`repository/onze/modules/onze-release/test/` — four files. The text generators run on **both**
targets, because the build host writes them and the BEAM server's boot path reads the build id back;
the packaging steps run on `erlang` only, since they are the server side of a server artifact.

| File | Target | What it asserts |
|---|---|---|
| `build_id_test.bp` | **both** | Determinism on a literal, sort-independence, sensitivity, validation, and the four-way `verifyBuildId` mismatch |
| `release_text_test.bp` | **both** | `.rel`, `sys.config`, `vm.args` and the boot script as literals — including the no-baked-cookie and no-resolved-config assertions |
| `dockerfile_test.bp` | commonJS | Two stages, non-root user, `PORT`, no source in the runner, the `includeErts` base-image switch |
| `package_test.bp` | erlang | Manifest completeness, `public/` verbatim, the secret scan, the shutdown order and the drain timeout |

Everything above is a pure function over strings except `assembleRelease`, `packageAssets`,
`shutdown` and `staticExport`. That is deliberate: a release's correctness is almost entirely in the
*text it generates*, and text is assertable. `assembleRelease` is covered by one integration test that
runs `systools` for real and is skipped with a named reason when `erl` is absent — the only test in
this front that needs a machine rather than a string.

The end-to-end claim — `onze build && onze start` serving front 53's blog from a packaged release
— is the milestone's exit gate and is checked there, not here. What this front owes that gate is that
every artifact the gate needs exists and carries the same build id.

## Definition of done

- [ ] `repository/onze/modules/onze-release/` exists with `botopink.json`, `src/root.bp`,
      `src/spec.bp`, `src/otp.bp`, `src/docker.bp`, `src/package.bp`, `src/lifecycle.bp`
- [ ] `onze build` on front 53's example app produces a release directory matching the layout in
      *Mechanism*, and `onze start` boots it with no source tree and no compiler present
- [ ] The build id is derived exactly once and `verifyBuildId` passes across the release, the client
      manifest and the payload
- [ ] The generated Dockerfile builds and the resulting container runs as a non-root user on `PORT`
- [ ] No environment value is present in the release except the `ONZE_PUBLIC_` table front 68 inlined,
      and `scanForSecrets` proves it
- [ ] `repository/onze/docs.md` records the release layout and the shutdown order, because front 50
      and any operator read them
- [ ] The front's tests are green on its assigned targets — both for the text generators, `erlang` for
      packaging

