# Front 68 — onze Client Bundle

**Track:** E onze
**Priority:** critical — without it `onze build` ships a BEAM server and no browser half: every
`'use client'` component renders once and is then dead HTML, and fronts 26, 27, 29, 31 and 67 deliver
nothing that runs
**Target:** both — the graph walk, the compile and the concatenation run at build time on the server
side (under `onze build`, on BEAM); the artifact they produce is the js client half. One file,
`manifest.bp`, compiles for both targets because the build host writes the manifest and the BEAM
server reads it back to emit script tags
**Wave:** 6
**Depends on:** 29 (the boundary marker, the `server-only` marker and the hydrate entry point) · 49
(config, `outDir`, and the `ONZE_PUBLIC_` rule this front enforces) · 03 (content hashes) · 50 (the
CLI that invokes it) · 01 (`path.walk`, `path.glob`, `process.run`, `fs`) · 30 (jhonstart's render:
the payload, the globals registry — `globals.fill` and `globals.signal` — and the `RenderHooks` head and body fields its tags fill) · 27 (the link runtime the entry mounts) · 48 (the class names the
tree carries) · 56 (emilia's `styleRule`, which the build-time rule evaluation calls — decision
116) · `01-std/06-validation-lib` (`setMessageSource`, which the entry calls) · 20 (the websocket the
dev rebuild pushes over)
**Owns:** `repository/onze/modules/onze-bundler/src/**`,
`repository/onze/modules/onze-bundler/test/**` — including `headScriptTags`/`scriptTags` and the
`RenderHooks.headExtra`/`bodyExtra` values built from them, which `Onze.run` (front 49) hands to
jhonstart's render at boot. This front owns **no** definition in another repository: `RenderHooks`,
the payload and the globals registry are jhonstart front 30's, the island marker is front 29's, and
`linkMount` / `formMount` are fronts 27's and 67's — all imported here (decisions 113, 114). The
entry imports nothing from the bundled library `routing`: jhonstart's router and `Link` import it
themselves (decision 115), the navigation vocabulary included (`routing`'s `navigation`, decision
116) — the entry keeps no copy of it. Build-time rule evaluation calls emilia's `styleRule` (emilia
front 56) directly and the hash-parity check calls std's `content_hash.contentHash` (decision 116)
**Does not touch:** `repository/onze/modules/onze/**` (front 49), `repository/onze/modules/onze-cli/**`
(front 50), `repository/onze/modules/onze-assets/**` (front 69), `repository/jhonstart/src/**`,
`repository/rakun/src/**`, `repository/emilia/src/**`
**Reference:** `NEXTJS-DOCS.md § 7. Server e Client Components` (Regras fundamentais · Protegendo
código server-only · `NEXT_PUBLIC_`), `§ 2. Instalação e Configuração` (scripts), `§ 25. Referência de
Componentes` (`<Script>`), `§ 28. Configuração` (`env`, `generateBuildId`), `§ 29. CLI` (`next build`,
`next dev`) · `../../contracts.md § 2` (payload envelope, jhonstart front 30) and `§ 4` (class-name
scheme, front 48) ·
<https://nextjs.org/docs/app/getting-started/server-and-client-components> ·
<https://nextjs.org/docs/app/guides/environment-variables> ·
<https://nextjs.org/docs/app/api-reference/components/script> ·
<https://nextjs.org/docs/app/api-reference/cli/next>
the milestone

---

## Problem

Five fronts in this milestone compile for the browser: 26 (`useRouter`), 27 (`Link`), 29 (the
`'use client'` boundary), 31 (error boundaries) and 67 (forms). Every one of them produces commonJS
that nothing collects, nothing links, nothing serves and nothing starts. `onze build` as the
milestone stands today walks `app/`, generates a route module, compiles the server to BEAM and stops.
The browser receives HTML with `data-jh-l` attributes that no listener reads, `data-jh-a` forms
with no interceptor, `data-jh-on-click` handler ids bound to nothing, and client components that
rendered exactly once.

That is not a degraded experience, it is a different product. A `'use client'` directive whose only
consequence is a marker in a manifest is a comment. `useState` never updates. `onClick` never fires.
The whole of track C's client half, and all of front 67, deliver code with no delivery mechanism.

The second problem is a security one, and it is why this front's failures are hard failures.
`NEXTJS-DOCS.md § 7` states two rules: only `NEXT_PUBLIC_`-prefixed variables are available on the
client, and a module that imports `server-only` fails the build when it reaches a client component.
Both rules are enforced *by the bundler* — they are statements about what ends up in the file the
browser downloads. Front 49 declares the prefix (`ONZE_PUBLIC_`, and it does not restate it here);
front 29 declares the marker. Neither can enforce anything: enforcement is the graph walk, and the
graph walk is this front. A miss here does not produce a bug report, it produces a database password
in a file served to the public.

## Current state

- `repository/onze/` does not exist. Front 49 creates it; `modules/onze-bundler/` is created by
  this front inside it.
- Nothing in the workspace computes a module graph. The compiler resolves imports to compile them
  (`pub mod` declarations plus `from "<lib>"`), and exposes none of that: `@Decl` gives a
  declaration's kind, name, fields, methods and annotations (`libs/std/src/builtins.d.bp:425-477`)
  and says nothing about what a module imports.
- A decorator body runs in a minimal eval prelude with no filesystem and cannot call a sibling
  function (`repository/rakun/src/decorators.bp:44-46`), so a comptime graph walk is not available
  and was never the plan.
- `botopink build` emits one `.js` file per module under `out/` — visible in the checkout at
  `repository/jhonstart/out/element.js`, `hooks.js`, `html.js`, `root.js`. That is the compiler
  output this front concatenates; it is not a bundle and there is no entry point among those files.
- `repository/jhonstart/examples/jhonstart-counter/out/` shows the shape a consumer gets today: the
  app's own `main.js` beside a copied `jhonstart/` directory of `require`-linked modules. A browser
  cannot load that: there is no `require`.
- No `<script>` tag is emitted by anything in the milestone, because nothing has a URL to put in one.

## Mechanism

Next's bundler does four jobs, and only the first three matter here: find the client modules, compile
them, link them into loadable chunks, and (fourth) optimise. This front does the first three and
declines the fourth. It is not webpack and does not try to be: there is no loader model, no plugin
API, no tree shaking and no code splitting beyond one chunk per route group plus one shared chunk.
The audit records the plugin surfaces as deliberately deferred.

### Step 0 of everything — the graph is walked over files, not at comptime

The compiler exposes no module-graph API, so the walk is textual and happens at build time inside the
CLI, where `path.walk` and `fs.readText` (front 01) exist. `importsOf(source) -> Array<ImportRef>`
reads the `import { … } from "…";` and `pub mod …;` lines of one `.bp` file. This is a real design
cost and it is stated plainly rather than hidden: a dynamically constructed import would be invisible
to it, and botopink has none — every import is a literal line at the top of a file, which is what
makes a textual scan total rather than heuristic. The scan fails, loudly, on any `import` line it
cannot parse, rather than silently dropping an edge.

### The client module graph

The roots are front 29's boundary markers. Front 29 marks a module as client-side; front 22's route
table says which modules a route reaches; the intersection is the root set:

1. For every route in the table, take the page, layout, loading, error and not-found modules.
2. Walk their imports transitively, **on the server side**, until a module carrying front 29's
   client marker is reached. That module is a **root**. The walk does not descend past it on the
   server side — everything below it is client.
3. From each root, walk imports transitively again. That closure is the **client graph**.
4. A module reachable from a root is in the bundle whether or not it carries the marker. This is
   `§ 7`'s first fundamental rule — "`'use client'` cria uma boundary — tudo importado a partir desse
   arquivo vai para o bundle do cliente" — and it is the rule that makes the two refusals below
   meaningful.

`clientGraph(table, markers) -> ClientGraph` is the function. `ClientGraph` carries, for every module
in it, the **import chain from the root that pulled it in**. Every refusal below prints that chain,
because "module X reads a secret" is not enough to fix anything — what a developer needs is which
client component dragged X into the browser.

### Refusal 1 — `server-only` in the client graph

Front 29 ships a marker module (`§ 7` *Protegendo código server-only*: `import 'server-only'`). If it
appears anywhere in the client graph the build fails, printing the chain from the root to the
offending module. There is no flag, no config key and no annotation that downgrades it, per the
project's standing rule that the most restrictive behaviour wins and no knob gets around it.

### Refusal 2 — the public environment prefix

Front 49 owns the rule and the predicate (`isPublicEnvName`, `publicEnv`) and this front owns its
enforcement. During the walk, every environment read in a client module is classified:

| What the module wrote | Outcome |
|---|---|
| `env.read("ONZE_PUBLIC_…")` | inlined — the value goes into the manifest's public table and the read is rewritten to a table lookup |
| `env.read("ANYTHING_ELSE")` | **build fails**, naming the variable, the module, and the chain from the client root |
| `env.read(someExpression)` | **build fails** — a name the bundler cannot read is a name it cannot clear |
| `env.vars()` | **build fails** — it returns every variable, and filtering it would still publish the names of the ones it filtered |
| `env.write` / `env.clear` in a client module | **build fails** — a client has no environment to write |

No flag, no config key, no annotation, no per-module exemption. The consequence of a miss is a secret
in a public file, so the rule fails the build rather than warning. The values themselves reach the
browser through the manifest's public table and the payload, never through a second mechanism.

### Refusal 3 — an unresolvable `emilia` call in a client module

This is the hydration-correctness rule, and it is the subtlest of the three. The scheme itself is not
this front's: `contracts.md § 4` pins it, front 48 owns it, and the five clauses there — pure function
of the token list, token order is class identity, ASCII-only rule bodies, fixed merge order, fixed
attribute order — are what make a class name reproducible at all. This front's job is to make the
client half obey them, because the server render already put a class name in the HTML and a bundle
that computes a different one replaces correct markup with differently-classed markup.

Four things enforce it, and they are this front's:

1. **Same input, same function.** Clause 3 of `contracts.md § 4` is the ASCII restriction: the JS cell
   folds UTF-16 units and the erlang cell folds codepoints, and they diverge above U+10000. The
   function is std's `content_hash.contentHash` — emilia's class name and this check call the same
   one, compiled for two targets (decision 116; emilia's private `hashHex` duplicate is gone). The
   bundler **recomputes both hashes for every rule body reachable from the client graph and fails the
   build when they differ**, naming the token list. It is the second line of defence behind front
   48's payload-leaf gate, and it costs nothing.
2. **Same tokens.** Every `emilia(...)` call in a client module must have a statically resolvable
   `Token[]` argument — a literal, or a module-level `val` of literals — **in author order**, since
   clause 2 makes order identity. The bundler evaluates the rule body at build time with emilia's
   `styleRule(tokens, th)` (emilia front 56 — the class name and the encoded body, registering
   nothing) and records it in a `styleMap` (call-site id → class name + rule body). onze imports emilia
   for this directly — onze is the package that knows every library (decision 113) — and never goes
   through the `jhonstart-emilia` bridge, which stays jhonstart's render plugin only (decision 116). A call it cannot resolve fails the build naming
   the call site: a class computed from runtime data cannot be in the server's stylesheet, and a class
   with no rule is invisible breakage.
3. **One stylesheet, and it is the server's.** The client bundle never calls `flush()` — front 49
   states it, this front enforces it by refusing a `flush` reference in the client graph. Every
   `styleMap` rule is handed to front 69, which puts it in the document's `<style>` block during the
   server render. A client island that mounts after hydration finds its class already styled.
4. **Checkable at run time, not only at build time.** The payload's `s` key lists the class names
   already present in the server-emitted `<style>` (`contracts.md § 2`); the `jhonstart-emilia`
   bridge's `RenderPlugin.payload()` returns it under `"s"` and jhonstart's render writes it
   (decision 114). The generated entry calls `checkStyles(payload.s)`, which compares every name its
   islands compute against `s` and fails loudly in dev when one is missing. The shared fixture of
   `contracts.md § 4` — the literal hex for a fixed token list, asserted by emilia's own test and by
   the bridge's — is asserted by this front's bundle test as well, which is the third of the three
   assertions the contract requires.

### What the bundle contains

Compilation is the compiler: `botopink build --target commonJS` over the client graph produces one
`.js` per module under the project's build directory. Linking is concatenation plus a small
module-registry prelude — the modules `require` each other, and the prelude is a fifteen-line
`__onze_require` over a table of factory functions, which is what makes concatenation sufficient.

| Chunk | Contents | When it loads |
|---|---|---|
| `shared` | every client module reached by two or more routes, plus the jhonstart client runtime | every page, `defer` |
| `route:<pattern>` | the client modules reached only by that route | on that route, `defer` |
| `entry` | the generated hydration entry | last, `defer` |
| `script:<id>` | one `<Script strategy="beforeInteractive">` per chunk | in `<head>`, blocking |
| `worker:<id>` | a `<Script strategy="worker">` body | as a `Worker`, from the entry |

Chunk file names are `<id>.<hash>.js` under `/_onze/static/<buildId>/`, where `<hash>` is front 03's
content hash of the chunk. A content-hashed URL is immutable, which is what lets front 69 serve it
with a one-year cache header and what lets front 71 copy the tree into a release unchanged.

### The bundle contract

This is the interface every other front reads, and it is one record plus one text format.

```bp
// modules/onze-bundler/src/manifest.bp — compiled for BOTH targets
pub type ChunkRef(id: string, url: string, hash: string, bytes: i32)

pub type ClientBundleManifest(
    version: string,                        // "1" — the format version, checked on read
    buildId: string,                        // front 03's build id, also the static path segment
    entry: ChunkRef,
    shared: Array<ChunkRef>,
    chunks: Array<ChunkRef>,                // every route chunk and script chunk
    routes: Array<#(string, string)>,       // route pattern -> chunk id
    styles: Array<ChunkRef>,                // filled by front 69, carried in the same manifest
    publicEnv: Array<#(string, string)>,    // every ONZE_PUBLIC_ name and its value, and nothing else
)

pub fn parseManifest(text: string) -> ClientBundleManifest
pub fn formatManifest(m: ClientBundleManifest) -> string
pub fn chunkFor(m: ClientBundleManifest, route: string) -> ChunkRef
pub fn headScriptTags(m: ClientBundleManifest) -> string
pub fn scriptTags(m: ClientBundleManifest, route: string) -> string
```

The on-disk form is `<outDir>/client-manifest.txt`, a line-oriented `|`-delimited table — the same
shape front 22 uses for the route table, and for the same reason: `libs/std/src/json.bp:36,45` is
`parse`/`stringify` over strings with no structured walker, so there is no JSON object to decode.

```
V|1|<buildId>
E|entry|/_onze/static/<buildId>/entry.<hash>.js|<hash>|<bytes>
S|shared|/_onze/static/<buildId>/shared.<hash>.js|<hash>|<bytes>
C|route:/blog/[slug]|/_onze/static/<buildId>/r3.<hash>.js|<hash>|<bytes>
R|/blog/[slug]|route:/blog/[slug]
Y|styles|/_onze/static/<buildId>/app.<hash>.css|<hash>|<bytes>
P|ONZE_PUBLIC_API_URL|https%3A%2F%2Fapi.example.com
```

`|` and newline may not appear in a field; every value is percent-encoded with front 01's encoder. A
line whose kind byte is unknown is ignored, so front 69 and front 71 may add record kinds without
breaking a reader. A `V` line with a version other than `1` is a hard error, not a best effort.

`parseManifest` and `formatManifest` are pure botopink compiled to **both** targets, and this is the
only reason this front is not js-only: the build host writes the file, and the BEAM server reads it on
every render to emit the script tags for the matched route. One parser, two targets, one round-trip
test — the alternative is two parsers that agree until they do not.

**The emission order is fixed, and it straddles two packages.** `contracts.md § 2` places the
payload that jhonstart's render writes — one `<script>window.__bp0 = {…}</script>`, the global named
by jhonstart's registry as `globals.payload` — last in `<body>`, before the bundle. This front emits
the script tags and respects that placement:

| # | What | Where | Owner |
|---|---|---|---|
| 1 | every `beforeInteractive` script chunk, blocking | `<head>` | front 68 |
| 2 | the document's markup | `<body>` | jhonstart front 30's render |
| 3 | the payload script, `<script>window.__bp0 = {…}</script>` | end of `<body>` | **front 30's render, never 68's** (`contracts.md § 2`) |
| 4 | `shared`, `defer` | after the payload | front 68 |
| 5 | the route chunk for the matched pattern, `defer` | after `shared` | front 68 |
| 6 | `entry`, `defer` | last | front 68 |

`scriptTags(m, route)` returns groups 4-6 as one string and `headScriptTags(m)` returns group 1.
Neither is called by jhonstart: they are wrapped as `RenderHooks.headExtra` and
`RenderHooks.bodyExtra` and handed to jhonstart's render by `Onze.run`, so the render writes the
string this front returns without knowing where it came from (decision 113 — the record is
jhonstart's, and the dependency points from onze into jhonstart, never back). This front never
formats the payload tag and never moves it; it asserts only that the entry comes after it, because
an entry that runs before `globals.payload` exists finds no payload and hydrates nothing.

`afterInteractive` and `lazyOnload` scripts are not tags at all — the entry schedules them, which is
what the strategy names mean.

### The hydration entry, and how it finds its roots

The entry is generated, not written: `generateEntry(graph, manifest) -> string` emits a `.bp` module
under `<outDir>/client/entry.bp`, which is then compiled and concatenated like any other client
module. Generating source rather than emitting JavaScript directly means the entry is type-checked by
the same compiler as the rest of the app, and it means a developer can read it.

Roots are found in the DOM, not in a side table, and the marker is `contracts.md § 2`'s: an island is
`<div data-jh-i="i0">`, and the payload's `i` key carries `[id, component, props]` — the id that
appears in the attribute, the component that renders it, and its serialized props. This front does not
invent a marker; it consumes that one. The entry:

1. reads the payload through `readPayload(globals.payload)` — the global jhonstart's render wrote
   last in `<body>`, named by jhonstart's globals registry (`__bp0`), never by a hand-written string,
2. reads the `i` triples, `props` being form-urlencoded and parsed with `querystring.parse`
   (`libs/std/src/querystring.bp:35`),
3. queries `[data-jh-i]` in document order,
4. pairs each element with the triple whose id matches, and calls front 29's hydrate entry point for
   that component,
5. registers the fill function under `globals.fill` (`__bp1`) with `registerFill(globals.fill,
   payload.h)`, so front 30's `<template data-jh-f="h1">…</template><script>__bp1("h1")</script>`
   has a function to call when a late chunk lands,
6. registers the signal function under `globals.signal` (`__bp2`) with
   `registerSignal(globals.signal, allowedRedirects: …)`, so a navigation signal front 30 writes
   after the first chunk (`<template data-jh-g="…">…</template><script>__bp2()</script>`, decision
   115) has a function to call; the list it hands is `OnzeConfig.allowedRedirects` — the list front 49 passes to `app(…)` on the
   server, so a redirect the client router raises is checked against the same list (decision 117).
   The entry reads no signal itself: jhonstart's client acts on it. The entry builds no matcher and hands the router nothing: front 26's router reads the
   payload's `t` and matches with the bundled library `routing` itself,
7. sets the browser's validation message source with `setMessageSource(…)` from the bundled library
   `validation` (`01-std/06-validation-lib`, decision 116), over the message table onze ships for the
   client; with none configured, the library's built-in texts answer. The entry imports nothing of
   rakun — validation is a bundled library, not a rakun member,
8. calls front 27's `linkMount()` and front 67's `formMount(actionHeader)` once, after every island
   is mounted — ordinary imports from `jhonstart-link` and `jhonstart-forms`, not globals; the header
   name is onze's configured value (`X-Bp-Action` by default), the same one front 49's boot sets in
   rakun's configuration, as the server render hands `actionField` (`__bp_action`) to front 67's
   `formAction`,
9. schedules `afterInteractive` scripts, then `lazyOnload` ones.

An island in the DOM with no entry in the payload, or an entry with no element, is a **hard error at
run time with the island id in the message**, not a silent skip — a mismatch here is the failure mode
that produces "it works in dev" bug reports, and it must announce itself. The same applies to a hole
id in `h` with no `[data-jh-h]` element.

### Dev mode

`onze dev` (front 50) builds the same graph and keeps it. On a file change: recompute the hash of
the changed module, recompile it and the chunks that contain it, rewrite the manifest, and push the
chunk id over front 20's websocket. The page replaces that chunk and re-runs the entry. Nothing else
is rebuilt, because the graph already says which chunks a module is in. A change to an import line
re-walks the graph, because that is the one edit that can change the graph's shape — and if the
re-walk turns up a `server-only` module or a non-public environment read, dev fails with the same
message `build` would give. The rules are not relaxed in dev; that is where a developer would
otherwise learn to ignore them.

## Steps

### Step 1 — `importsOf` and the module scanner

```bp
pub type ImportRef(spec: string, names: Array<string>, isModDecl: bool)

pub fn importsOf(source: string) -> Array<ImportRef>
pub fn moduleIdOf(packageRoot: string, filePath: string) -> string
```

**Acceptance:**
- [x] `import { div, text } from "jhonstart";` yields one ref, spec `"jhonstart"`, two names
- [x] `import { perimeter };` — the sibling shorthand — yields a ref with an empty spec and
      `isModDecl: false`
- [x] `pub mod tokens;` yields a ref with `isModDecl: true`
- [x] A commented-out import is not an edge
- [x] An `import` line the scanner cannot parse fails the scan, naming the file and the line
- [x] `moduleIdOf` is stable across platforms: a backslash path and a slash path give the same id

### Step 2 — `clientGraph`

```bp
pub type GraphNode(moduleId: string, path: string, chain: Array<string>, isRoot: bool)
pub type ClientGraph(nodes: Array<GraphNode>, roots: Array<string>)

pub fn clientGraph(routeModules: Array<#(string, string)>, markers: Array<string>) -> ClientGraph
pub fn chainOf(graph: ClientGraph, moduleId: string) -> Array<string>
```

**Acceptance:**
- [x] A module imported only by a server module is absent from the graph
- [x] A module imported by a client root is present even though it carries no marker
- [x] A module imported by two roots appears once, with the chain of the first root that reached it
- [x] An import cycle terminates and each module appears once
- [x] `chainOf` of a module three levels below a root returns four ids, root first

### Step 3 — the three refusals

```bp
pub type BuildRefusal(kind: string, subject: string, moduleId: string, chain: Array<string>)
pub type EmiliaCall(moduleId: string, literal: bool, rules: string, jsHash: string, beamHash: string)

pub fn checkServerOnly(graph: ClientGraph) -> Array<BuildRefusal>
pub fn checkEnvReads(graph: ClientGraph, reads: Array<#(string, string)>) -> Array<BuildRefusal>
pub fn checkEmiliaCalls(graph: ClientGraph, calls: Array<EmiliaCall>) -> Array<BuildRefusal>
pub fn refusalMessage(r: BuildRefusal) -> string
```

**Acceptance:**
- [x] `checkServerOnly` refuses a graph containing front 29's marker and the message contains every
      id of the chain, root first
- [x] `checkEnvReads` passes `ONZE_PUBLIC_API_URL` and refuses `DATABASE_URL`, `onze_public_x`,
      a non-literal name, `env.vars()`, `env.write` and `env.clear`
- [x] The refusal message names the variable **and** the chain — asserted on the string, because a
      message that names only the module is a message that does not fix the problem
- [x] No configuration value, decorator or CLI flag changes any of these outcomes — asserted by a
      test that builds with every config field set adversarially and still gets the refusal
- [ ] `checkEmiliaCalls` refuses a non-literal token list, a `flush()` reference, and a rule body
      whose commonJS and erlang hashes differ; both hashes are `content_hash.contentHash`, and the
      class a `styleMap` entry records equals `styleRule(tokens, th)._0` for the contract-4 fixture
- [x] A build with more than one refusal reports all of them, not the first

### Step 4 — chunking and emission

```bp
pub fn planChunks(graph: ClientGraph, routes: Array<#(string, string)>) -> Array<ChunkPlan>
pub fn emitChunk(plan: ChunkPlan, compiledDir: string) -> @Task<ChunkRef>
```

Compilation is `process.run` (front 01) over `botopink build --target commonJS`; concatenation is
`fs.readText`/`fs.writeText` plus the module-registry prelude. `@Task` lowers eagerly on erlang
(`libs/std/src/http.bp:16-18`), so chunk emission is sequential unless it is handed to front 02's
task runner over unstarted tasks — the parallel path is front 02's, and this front does not fake it.

**Acceptance:**
- [x] A module reached by two routes lands in `shared` and in no route chunk
- [x] A module reached by one route lands in that route's chunk only
- [x] Two builds of an unchanged tree produce identical chunk hashes — the build is reproducible
- [x] A chunk's URL contains its own hash, and changing one byte of one module changes exactly the
      chunks containing it
- [x] The prelude resolves a `require` between two concatenated modules without a network fetch

### Step 5 — the manifest

As specified under *The bundle contract*.

**Acceptance:**
- [x] `parseManifest(formatManifest(m))` equals `m` for a manifest with every field populated —
      asserted on `commonJS` **and** on `erlang`, with the same literal
- [x] A `V` line with version `2` is an error naming the version
- [x] An unknown record kind is ignored, so a front-69 `Y` line does not break a front-68 reader
- [x] A value containing `|` round-trips, because it is percent-encoded
- [x] `scriptTags` emits `shared`, then the route chunk, then the entry, and nothing else
- [x] `headScriptTags` emits only `beforeInteractive` chunks, and never a `defer` attribute
- [x] `scriptTags` for a route with no route chunk emits shared and entry, never an empty `src`
- [x] Neither function emits the payload script (`window.__bp0 = …`) — the payload is jhonstart
      front 30's render and this front formats no part of it

### Step 6 — the hydration entry

```bp
pub type Island(id: string, component: string, props: Array<#(string, string)>)

pub fn generateEntry(graph: ClientGraph, manifest: ClientBundleManifest) -> string
pub fn parseIslands(payloadField: string) -> Array<Island>
```

`islandAttr(ordinal) -> #(string, string)` is **imported** from jhonstart (front 29), which owns the
island marker; the generated entry calls it and this front defines no second copy. The globals the
entry names — `globals.payload`, `globals.fill` — come from jhonstart's registry (front 30), so the
render that writes them and the entry that reads them cannot diverge (decision 113).

**Acceptance:**
- [x] `islandAttr(0)` is `#("data-jh-i", "i0")`, matching `contracts.md § 2` — asserted here
      against front 29's definition, not against a local one
- [x] `parseIslands` of the payload's `i` key returns one `Island` per triple, props parsed
- [x] The generated entry compiles: `botopink build` over `<outDir>/client/` succeeds
- [x] An island id present in the DOM and absent from the payload raises, with the id in the message
- [x] An island id present in the payload and absent from the DOM raises, with the id in the message
- [x] A hole id in the payload's `h` key with no `[data-jh-h]` element raises, with the id
- [x] The fill function is registered under `globals.fill` before the first streamed chunk can
      arrive — asserted by generating an entry for a route with holes and checking the registration
      precedes the island loop
- [x] `linkMount` and `formMount` are called exactly once each, after the last island, and
      `formMount` receives the configured `actionHeader`, not a literal of the bundler's own
- [x] The entry registers `globals.signal` before the first streamed chunk can arrive, next to
      `globals.fill`, with the configured `allowedRedirects` — `[]` by default, never a literal of
      the bundler's own
- [x] The entry calls `setMessageSource` from `"validation"` before the first island mounts, and the
      client graph contains no `rakun` package
- [x] The entry imports nothing from `routing` and hands the router no `match`; it contains no
      matcher and no table parser, and the bundle's client graph reaches `routing` compiled for
      commonJS only through jhonstart's router and `Link`
- [ ] The generated entry contains no hand-written `__`-prefixed name: every global it reads is
      `globals.<name>` from jhonstart's registry
- [ ] Every class name the entry's islands compute is present in the payload's `s` key — the runtime
      half of the class-name check, failing loudly in dev

### Step 7 — `<Script>` and its four strategies

```bp
pub type ScriptDecl(id: string, src: string, strategy: string, onLoad: string)

pub fn scriptChunks(decls: Array<ScriptDecl>) -> Array<ChunkPlan>
pub fn scriptPlacement(strategy: string) -> string
```

**Acceptance:**
- [x] `beforeInteractive` is a blocking tag in `<head>`, before the payload
- [x] `afterInteractive` is scheduled by the entry after hydration completes
- [x] `lazyOnload` is scheduled after the load event
- [x] `worker` produces a worker chunk and a `Worker` construction in the entry; a `worker` script
      that also declares `onLoad` is refused, naming the script, because the callback cannot run
- [x] An unknown strategy is refused, naming it and listing the four

### Step 8 — dev rebuild

```bp
pub fn rebuild(graph: ClientGraph, changed: string) -> @Task<#(ClientGraph, Array<string>)>
```

**Acceptance:**
- [x] A change to a module body rebuilds only the chunks containing it
- [x] A change to an import line re-walks the graph
- [x] A change that introduces a `server-only` import fails dev with the same message `build` gives
- [x] A change that introduces a non-public env read fails dev with the same message `build` gives
- [x] The manifest on disk is rewritten before the websocket push, so a reload during a rebuild
      never serves a URL the manifest does not name

## Examples

- [`examples/client-island-example.bp`](./examples/client-island-example.bp) — what a developer
  writes: a client component that reads a public configuration value and hydrates. The only file in
  this front an app author ever touches.
- [`examples/bundle-manifest-example.bp`](./examples/bundle-manifest-example.bp) — the bundle
  contract as code: the manifest record, its text form, the round trip both targets run, and the
  script tags it produces for one route.
- [`examples/env-refusal-example.bp`](./examples/env-refusal-example.bp) — the three refusals, each
  as the code that triggers it and the message the build prints.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No bitwise operators and no `toString(radix)` — also recorded by front 01 | chunk and build-id hashing in `emitChunk` | front 03's `content_hash`, whose fold lives in a host template | `&`, `|`, `^`, `<<`, `>>` on `i32`, and `i32.toString(radix)` |
| No byte or binary type — also recorded by front 01 | `ChunkRef.bytes` counts characters, not octets; a font or image asset is copied by `process.run`, never read into botopink | keep binary assets out of botopink and move them with the filesystem | a `bytes` primitive with indexing and a length, and `fs.readBytes` |
| No module-graph reflection: `@Decl` exposes declarations, not imports | `importsOf` is a textual scan of `import`/`pub mod` lines | scan the source text; fail loudly on an unparsable line | a comptime `@Module` with `imports()`, so the graph is the compiler's answer and not a parallel parser |
| No array or tuple destructuring in a binding — also recorded by front 01 | `rebuild`'s `#(ClientGraph, Array<string>)` result is read as `r.0` / `r.1` | one `val` per element, read by index | `val #(graph, dirty) = rebuild(…);` |

## Test plan

`repository/onze/modules/onze-bundler/test/` — five files, run by `botopink test` from the module
root and by `zig build test-libs`.

| File | Target | What it asserts |
|---|---|---|
| `manifest_test.bp` | **both** | The round trip, the version check, the unknown-kind rule, the `\|` escape, and `scriptTags`'s order. The only test that must pass on erlang, and the reason it must is that the server reads what the build host wrote. |
| `graph_test.bp` | commonJS | `importsOf` on fixture sources, `clientGraph` on a fixture tree with a shared module, a cycle and a server-only branch |
| `refusal_test.bp` | commonJS | Every row of the environment table, the `server-only` chain, the emilia rules, and the adversarial-config test that no setting relaxes any of them |
| `entry_test.bp` | commonJS | the imported `islandAttr`, `parseIslandTable`, and both mismatch errors |
| `chunk_test.bp` | commonJS | Chunk assignment, hash reproducibility, and that one changed module changes exactly the right chunk hashes |

The graph, chunk and refusal suites run against **fixture source strings**, not against a real
project on disk: `importsOf` takes a string, and `clientGraph` takes a module table. That keeps them
fast, hermetic and free of `process.run`, and it means a failure names a rule rather than an
environment. The end-to-end path — a real `app/` tree producing a real bundle a real browser loads —
is front 53's example app, which is where a browser first enters the loop.

Nothing in this front is exercised through `@External.Node`: the bundler owns no host cell. It reaches
the filesystem and the compiler through `libs/std` (fronts 01 and 03), which is the milestone's
*reuse std* rule and also the reason the erlang cell of `manifest_test.bp` is green rather than
skipped.

## Where it stands

Landed on onze `front/06-onze` (`5e68a7e`, `6ba1b25`, `c90199d`): `modules/onze-bundler/src/`
`manifest`, `scan`, `graph`, `refusal`, `chunk`, `entry`, `script`, `rebuild`, `hooks` (the tags as
jhonstart's `RenderHooks`) and `fixture` (the frozen fixture app every track-E suite reads); six
suites, **37 tests, all on commonJS and on erlang** (the build half is pure and runs on both rows;
the prelude's `require` test evaluates the chunk under node and answers `no-js-engine` on erlang).
The generated entry is compiled by `onze build` (front 50) inside the staged client package,
and linked by file (`link.bp`: the relative-`require` closure, `.mjs` sidecars as factories,
jhonstart's `hooks` → `client_runtime` substitution); the scaffold's bundle boots under node.
Route-level splitting at the file level is not done — the entry imports every client component,
so every island's closure lands in `shared` — until the entry starts islands lazily.

Open, and why:

- the `styleMap` class (`styleRule(tokens, th)._0`) and the runtime `s` check: emilia front 56's
  `styleRule` does not exist yet, so a literal call records its token text; the hash-parity rule
  is enforced statically — a non-ASCII token list is refused (`emilia-hash-split`), which is
  contract 4 clause 3 and covers the astral divergence the two `contentHash` cells have;
- "no hand-written `__` name": the island starters go into `globalThis.__jhIslandStarters`,
  jhonstart's table outside its globals registry — jhonstart owes a registry entry (or a
  `registerStarter`) for it;
- `onze build` over the blog, and the tags handed over by `Onze.run` (fronts 50 and 49's rakun
  half).

Choices recorded in `../../decisions-pending.md` 68-a…c.

## Definition of done

- [x] `repository/onze/modules/onze-bundler/` exists with `botopink.json`, `src/root.bp` and the
      modules named in *Steps*
- [ ] `onze build` on front 53's example app writes `<outDir>/client-manifest.txt`, a chunk tree
      under `<outDir>/client/`, and a generated `entry.bp` that compiles
- [ ] The bundle's script tags reach the document through jhonstart's `RenderHooks.headExtra` /
      `bodyExtra`, handed over by `Onze.run`; no other front formats one, and jhonstart's render
      keeps its own payload script per `contracts.md § 2`
- [x] `repository/onze/modules/onze-bundler/` names jhonstart in its `botopink.json`, and jhonstart
      does not name `onze` — the seam is one-directional (decision 113)
- [x] `contracts.md § 6` is filled in from this front's *The bundle contract* section, verbatim
- [x] The three refusals are covered by a test each **and** by an adversarial-config test proving no
      setting relaxes them
- [x] `islandAttr` is defined by front 29 and imported by this front's entry generator — one
      definition, in jhonstart, cited in both READMEs
- [x] The emilia hash-parity check runs on every build, not only on request
- [x] `repository/onze/docs.md` carries the manifest format and the script-tag order verbatim,
      because fronts 30, 49, 50, 53, 69 and 71 all read them
- [x] The front's tests are green on its assigned targets — `commonJS` for the build half, and
      `erlang` for `manifest_test.bp`

