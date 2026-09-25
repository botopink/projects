# Front 49 — onze Stand-up

**Track:** E onze
**Priority:** critical — no other track-E front has a package to land in, and nothing in the milestone
joins rakun's server to jhonstart's tree to emilia's stylesheet until this front says where the joint is
**Target:** both — the config value and the route registry are read by the BEAM server half and by the
JS build half; the render seam runs on erlang, the registry it reads is built by the js half
**Wave:** 5 — after jhonstart front 30, whose render and bridge the boot wires (decision 113)
**Depends on:** 30 (jhonstart's render: `app`, `renderStream`, `RenderPlugin`, `RenderHooks`, the UI
registry the `#[page]` / `#[layout]` decorators fill, and the `jhonstart-emilia` bridge member whose
`plugin()` the boot registers) · 28 (`RequestData`, built here from rakun's `Request`) · 23
(`ChunkWriter`, `PageRenderer` and `page(pattern, render)`, the registry the boot hands one renderer
per page) · 22 (rakun's route table, and the `rakun-routing` matcher the client entry hands
jhonstart's router as `match`) · 05 (the configuration the boot writes `rakun.actions.field` /
`rakun.actions.header` into — front 24 reads them later and is not a dependency of the boot)
**Owns:** `botopink.json`, `src/root.bp`, `src/types.bp`, `src/config.bp`, `src/integration.bp`,
`test/config_test.bp`, `test/types_test.bp`
**Does not touch:** `repository/jhonstart/**` (the render, `RenderHooks`, `RenderPlugin` and the
`jhonstart-emilia` bridge are jhonstart front 30's), `repository/rakun/src/**`,
`repository/emilia/src/**`, `libs/std/src/**`, `repository/onze/src/image.bp` (F51),
`repository/onze/src/font.bp` (F52), `repository/onze/modules/onze-cli/**` (F50),
`repository/onze/examples/blog/**` (F53)
**Reference:** `NEXTJS-DOCS.md § 1. Introdução`, `§ 2. Instalação e Configuração` (alias de import),
`§ 3. Estrutura do Projeto`, `§ 7. Server e Client Components` (`NEXT_PUBLIC_`),
`§ 28. Configuração (next.config.js)` ·
<https://nextjs.org/docs/app/getting-started/project-structure> ·
<https://nextjs.org/docs/app/api-reference/config/next-config-js> ·
<https://nextjs.org/docs/app/guides/environment-variables>

---

## Problem

The workspace has every piece of a full-stack framework and no framework. `repository/rakun` is a DI
container with a router and an HTTP server. `repository/jhonstart` is an `Element` tree with builders,
hooks and an SSR renderer. `repository/emilia` is a `Token` enum that emits CSS. Each compiles, each
has green tests, and none of them knows the other two exist. A developer who wants a page served over
HTTP with typed styles today writes the joining code themselves, per project, and gets it wrong in the
same three places every time: the route table has no idea a `page.bp` file exists, the SSR renderer
has no idea which layouts wrap a page, and `emilia`'s stylesheet is flushed either before the tree is
built (giving `<style></style>`) or twice (giving one real block and one empty one).

`repository/onze/` does not exist. Nothing in the tree references it — `grep -r onze repository/`
returns nothing outside `specs/`.

The consequence is not that onze is missing a feature. It is that fronts 50–53 have no package to
write into, and fronts 22, 23, 24 and 25 have no consumer — they will build a file router, an SSR
pipeline, server actions and route handlers against a caller that nobody has written, which is the
reliable way to build four things that do not fit together.

## Current state

- `repository/onze/` does not exist. The five libraries in the workspace are `emilia`, `erika`,
  `jhonstart`, `onze` (the mocking library — unrelated, and the name collision is worth noting) and
  `rakun`, plus `libs/std`.
- `repository/jhonstart/src/element.bp:3-8` — `Element(tag, value, children, attrs)`, and
  `element.bp:55-67` — `renderToString`. This is the whole render surface that exists today, and it
  is enough for onze's render seam.
- `repository/emilia/src/emilia.bp:46-51` — `emilia(tokens: Token[]) -> string` registers a rule and
  returns a class name; `emilia.bp:62-65` — `#[@future] flush() -> @Future<string>` serializes the
  sheet **and clears it**. `emilia.bp:53-56` is the reason ordering matters: a second flush emits
  `<style></style>`.
- `repository/rakun/src/http.bp:75-78` — `App(port, basePath)`; `src/bootstrap.bp:28-37` —
  `Rakun.run(app)`. There is no `app/` convention, no layout chain, no page concept.
- `repository/rakun/modules/` shows the shape a module package takes in this ecosystem: a
  `botopink.json` with a `dependencies` map pointing at `../../`, and a `src/root.bp`. onze copies
  that shape rather than inventing one.

## Mechanism

Next.js is a router, a renderer and a build tool sharing one project convention. onze is the same
three things, except the router is rakun, the renderer is jhonstart, the stylesheet is emilia, and the
build tool is front 50. onze itself is **the joint** — five files that agree on the vocabulary the
three libraries do not share, and the one package that imports all of them (decision 113):

```
onze ──► jhonstart-emilia ──► jhonstart   (the plugin contract only)
  │                      └──► emilia
  ├────► jhonstart
  ├────► rakun
  └────► rakun-routing       (the pure matcher, on the server and in the client entry)
```

jhonstart and rakun never import each other, and emilia imports nobody; every value that crosses
between jhonstart and rakun is handed across by onze.

What onze actually contributes, once fronts 22, 23, 30, 48 and 69 exist, is small and worth stating
plainly: one config record (`OnzeConfig`), one import-alias map, one
environment-variable rule, one project-file vocabulary the CLI and front 22 both read, and one boot
adapter. Everything else in track E stands on those five and on the other fronts' own surfaces.

### The three seams, and who actually owns each of them

**onze does not own a page registry, a props vocabulary, a renderer or a head-insertion point.**
rakun front 22 owns the route table (its matcher in `rakun-routing`) and front 23 the opaque page
registry, jhonstart front 30 owns the render, its plugin point and the UI conventions, and
onze's job is to be the package where they meet and the project-level configuration they read.

**Seam 1 — how a project's `app/` tree reaches front 22's route table.**

Not at comptime. `@Decl` carries no source location (`language-gaps.md`), so a decorator cannot learn
which file it annotates, and a decorator body runs in a minimal eval prelude with no `fs`. The answer
is an explicit argument: `#[page("blog/[slug]")]`, `#[layout("blog")]` (jhonstart front 30's UI
decorators), `#[getRoute("api/posts")]` (rakun front 25's), where the argument is the app-relative
directory and the segment grammar is front 22's, in `rakun-routing`. Front 50's CLI generates the `pub mod` lines from the
tree and **fails the scan when a file's location and its decorator argument disagree** — that check is
the whole of the file-system convention, and it lives in the CLI because nothing else can see a
directory.

onze's contribution to this seam is one config value: `appDir`. Front 22 scans what `OnzeConfig`
says to scan, so `app/` and `src/app/` are the same mechanism with a different string.

**Seam 2 — how a matched route becomes HTML, and the HTML reaches the wire.**

rakun serves and jhonstart renders; neither names the other, so onze hands each one what it needs
from the other (decision 113):

- to **rakun's route table** (front 22), the UI records: the `#[page]`, `#[layout]`, `#[template]`
  and `#[defaultView]` decorators are jhonstart front 30's and fill jhonstart's UI registry; the boot
  reads that registry and registers each record in rakun's table, so the table the server matches
  and the payload's `t` stay one table (contract 1, decision 114);
- to **rakun**, one opaque `PageRenderer` per page pattern (front 23, decision 114): rakun matches the
  route, opens the request scope (front 62), calls the renderer with its `Request` and a
  `ChunkWriter`, and closes the response when the renderer's future resolves. rakun knows no HTML:

  ```bp
  // onze/src/integration.bp — `site` is jhonstart's `App`, `page` the jhonstart page for `route`
  rakun.page(route, fn(req, out) {
      return site.renderStream(page(req), requestData(req), fn(chunk) { return out.write(chunk); });
  });
  ```

- to **jhonstart's render** (front 30), inside that renderer: the `PageInput` — the segment chain
  (layouts, templates and boundaries from jhonstart's UI registry, keyed by front 22's layout chain
  for the matched pattern) and the payload's rakun-side values as strings: the route table `t`, the
  actions `a` and the build id `b`; the `RequestData` (front 28) that `requestData(req)` builds from
  rakun's `Request`, which is what jhonstart's `request()`, `headers()` and `cookies()` read; and a
  `fn(string) -> @Future<void>` writer over rakun's `ChunkWriter`. jhonstart never sees the
  `ChunkWriter`;
- to **jhonstart's router** (front 26), the `match` function — `rakun-routing`'s `matchPath` over the
  payload's table, handed in by the generated client entry (front 68) — so the router keeps no
  matcher and no table parser of its own;
- to **both sides of a server action**, the wire names (decision 114): the boot sets rakun's
  `rakun.actions.field` / `rakun.actions.header` (fronts 05 and 24) and passes the same two values to
  jhonstart's form binding as `actionField` / `actionHeader` (front 67). onze's defaults are
  `__bp_action` and `X-Bp-Action`; neither library spells a name;
- back to **rakun**, the not-found outcome: a page that raises jhonstart's own not-found signal is
  answered by rakun with 404, and onze is the one that translates the signal into the status.

The vocabulary — `PageContext(pathname, pattern, params, query, rest)`, `LayoutProps.children` — is
jhonstart front 30's, and onze does not restate it as `PageProps`/`Params`: a second name for every
value in the stack is a translation layer and a class of bugs.

**Seam 3 — how emilia's classes reach the HTML.**

`emilia(tokens)` registers a rule on a process-local sheet and returns a class name; `flush()`
serialises the sheet **and clears it** (`emilia.bp:53-56`). The moments at which it is flushed —
once into the head after the shell, once per streamed boundary inside that boundary's fill
`<template>`, and nothing left at the end — are jhonstart's: front 30 declares the `RenderPlugin`
point, whose methods are asynchronous, and awaits it; the `jhonstart-emilia` bridge awaits emilia's
`#[@future] flush()` in `head` and `chunk`, and its `payload()` returns `#("s", <the classes it
flushed>)`, which jhonstart writes as the payload's `s` key (decision 114). onze's part is one line
at boot, registering the bridge:

```bp
import {app} from "jhonstart";
import {plugin as emiliaPlugin} from "jhonstart-emilia";

val site = app(plugins: [emiliaPlugin()]);
```

The same boot fills the two tag fields jhonstart's `RenderHooks` keeps — `headExtra` and
`bodyExtra` — with front 68's `headScriptTags` / `scriptTags`. No seam installs a style sink: onze
carries none.

Front 48 owns the attribute end: `styled(tokens)` is `#("class", emilia(tokens))` and
`styledWith(base, tokens)` merges a static class first, one ASCII space, no sorting
(`contracts.md § 4`).

Two properties of the sheet are onze's to document, because they are project-level rather than
library-level. On erlang the sheet is per-BEAM-process, so a per-request process gives per-request
style isolation for free — two concurrent requests cannot leak classes into each other. On the js half
there is one process, so **the client bundle must never call `flush()`**; the `<style>` block is a
server artifact, and front 68 fails a build whose client graph reaches it.

### Seam 4 — the environment split, which is a security rule

`OnzeConfig` is read on both halves, and environment variables are not. A value read through
`env.read` on the server may be a database password; the same read compiled into the client bundle
publishes it. The rule this front declares, and front 68 (`onze-client-bundle`) enforces at bundle
time:

> An environment variable is inlinable into the client bundle **only** if its name begins with
> `ONZE_PUBLIC_`. Any other `env.read` reached from a client module fails the build, naming the
> variable and the module that read it. There is no flag, config key or annotation that downgrades
> this to a warning.

Front 49 owns the prefix constant and the two predicates (`isPublicEnvName`, `publicEnv()`), so that
the rule has one definition rather than one per consumer; front 68 owns the graph walk that applies
it. Stating the prefix here and enforcing it there is deliberate: the rule must be readable by an app
author who never opens the bundler's front.

### What onze does not do

It does not re-export jhonstart, rakun or emilia: a consumer writes `import {div, text} from "jhonstart";` because that is where `div` lives,
and a re-export layer buys one shorter import line at the cost of a second name for every symbol in
three libraries. onze's public surface is only the vocabulary the three do not share.

## Steps

### Step 1 — Package shape

Copy the shape the workspace already uses. `botopink.json` mirrors `repository/emilia/botopink.json`
and `repository/jhonstart/botopink.json`: `name`, `version`, `description`, `src`, `targets`, `files`.
The `dependencies` map mirrors `repository/rakun/modules/rakun-web/botopink.json`. `bpmp` resolves
`onze`, `onze-cli`, `onze-bundler`, `onze-assets`, `onze-og`, `onze-release` and `onze-test` as sibling
libraries — front 50's `create` writes them into a scaffolded `botopink.json`.

```json
{
  "name": "onze",
  "version": "0.0.1",
  "description": "Full-stack orchestrator for botopink — joins rakun (server), jhonstart (UI) and emilia (CSS) under the app/ convention",
  "src": "src/",
  "targets": ["commonJS", "erlang"],
  "files": [
    "root.bp",
    "config.bp",
    "types.bp",
    "integration.bp"
  ],
  "dependencies": {
    "jhonstart": { "path": "../jhonstart" },
    "rakun": { "path": "../rakun" },
    "emilia": { "path": "../emilia" }
  }
}
```

`src/root.bp` declares the module tree, with the same one-shared-file rule track A uses for
`libs/std/src/root.bp`: F49 owns it, and F51 and F52 hand F49 their `pub mod` line rather than editing
it themselves.

```bp
pub mod config;
pub mod types;
pub default mod integration;
```

**Acceptance:**
- [ ] `repository/onze/botopink.json` parses and names exactly the four `files` above
- [ ] `botopink build` succeeds in `repository/onze/`
- [ ] `repository/onze/AGENTS.md`, `README.md` and `docs.md` exist and follow the sibling repos'
      layout (`repository/emilia/AGENTS.md` is the model)
- [ ] `zig build test-libs` discovers `onze` as a sibling library and reports a cell for it on both
      targets

### Step 2 — `config.bp`

`onze.json` is the project's configuration file, the analogue of `next.config.js`
(`NEXTJS-DOCS.md § 28`). It is read by the CLI, not by the library: `OnzeConfig` is a plain record,
`defaultConfig()` supplies every field the file omits, and the `with*` fns return new records because
botopink records are immutable.

```bp
pub type OnzeConfig(
    name: string,
    port: i32,
    basePath: string,
    appDir: string,
    publicDir: string,
    outDir: string,
    dev: bool,
) {
    pub fn origin(self: Self) -> string {
        return "http://localhost:" + self.port.toString();
    }
}

pub fn defaultConfig() -> OnzeConfig { … }
pub fn withPort(base: OnzeConfig, port: i32) -> OnzeConfig { … }
pub fn withDev(base: OnzeConfig, dev: bool) -> OnzeConfig { … }
```

**Acceptance:**
- [ ] `defaultConfig()` returns `port: 3000`, `basePath: ""`, `appDir: "app"`, `publicDir: "public"`,
      `outDir: ".onze"`, `dev: false` — the values the CLI's scaffold writes into `onze.json`
- [ ] `withPort(defaultConfig(), 4000).appDir == defaultConfig().appDir` — the copy carries every
      other field
- [ ] `withPort(defaultConfig(), 4000).origin() == "http://localhost:4000"`
- [ ] `test/config_test.bp` green on `commonJS` and on `erlang`

### Step 3 — `types.bp`

What is left after jhonstart front 30 and rakun fronts 22 and 23 own the render and routing vocabulary: the project-level values, and nothing
that duplicates a rakun or jhonstart type.

```bp
pub type OnzeProject(
    root: string,            // the directory holding botopink.json
    config: OnzeConfig,
    aliases: AliasMap,
)

pub type AppFile(
    authoredPath: string,    // "app/blog/[slug]/page.bp" — what an error message names
    segment: string,         // "blog/[slug]"  — the decorator argument, front 22's segment grammar
    kind: string,            // "page" | "layout" | "template" | "default" | "loading"
                             // | "error" | "not-found" | "route"
)
```

`AppFile.segment` is the value front 50 compares against a file's `#[page("…")]` argument. It is
declared here, not in the CLI, because front 22's README, front 50's scan and this package's `docs.md`
all have to agree on one spelling of the routing-file table, and one declaration is how three
documents agree.

**Acceptance:**
- [ ] `AppFile.kind` covers exactly the eight conventions in `NEXTJS-DOCS.md § 3` — no more, no fewer
- [ ] The `segment` produced for `app/blog/[slug]/page.bp` is `"blog/[slug]"`, matching front 22's
      decorator argument character for character, including the bracket spelling
- [ ] The `segment` produced for `app/(marketing)/about/page.bp` is `"(marketing)/about"` — the group
      is in the segment and absent from the route pattern, which is front 22's distinction, not this
      front's
- [ ] `test/types_test.bp` green on `commonJS` and on `erlang`

### Step 4 — `integration.bp`

The boot adapter, and nothing else. `OnzeConfig` becomes rakun's `App`, the jhonstart app is built
with the emilia bridge registered, the wiring of seam 2 is handed across, and the server starts; the
route table is already populated by the `#[page]`/`#[layout]` decorators in the app's own modules by
the time this runs.

```bp
pub type Onze {
    pub fn run(config: OnzeConfig) {
        Rakun.run(App(port: config.port, basePath: config.basePath));
    }
}
```

That is the core of the seam, and its smallness is the finding: once fronts 22, 23, 30, 48 and 69
exist, joining them needs a port number, a base path, and the hand-offs of seams 2 and 3 — each a
value passed from one library to the other, never a definition of onze's own. A front that proposed more than this was proposing to
duplicate one of them.

`integration.bp` also carries the package's `docs.md`-facing description of the three seams above,
because an app author reads onze's docs and not rakun's internals.

**Acceptance:**
- [ ] `Onze.run(defaultConfig())` starts a listener on 3000 and answers `/` from the app's `#[page("")]`
- [ ] `basePath: "/docs"` is passed through to `App` unchanged; onze does not reimplement prefixing
- [ ] `integration.bp` is the only file in onze that imports jhonstart, rakun and
      `jhonstart-emilia` together (decision 113): it builds `app(plugins: [emiliaPlugin()])`, fills
      jhonstart's `RenderHooks.headExtra` / `bodyExtra` with front 68's tags (empty while 68 does
      not exist), registers jhonstart's UI records in rakun's table and hands rakun one
      `PageRenderer` per page through `page(pattern, render)`, builds `RequestData` from rakun's
      `Request`, sets `rakun.actions.field` / `rakun.actions.header` and passes the same values to
      jhonstart as `actionField` / `actionHeader`, and translates jhonstart's not-found signal into
      rakun's 404. Any other onze file reaching for
      the seam means the seam is in the wrong place, and the front says so under *Blocked* rather
      than adding a second wiring point
- [ ] Nothing under `repository/onze/src/` calls emilia's `flush()`, and no onze file defines a style
      sink — the flush moments are jhonstart front 30's and the adaptation is the bridge's
- [ ] The renderer handed to rakun writes every chunk through `out.write` and resolves only after the
      last one; with the action-name keys removed from the boot, rakun refuses to start its action
      dispatcher naming the key — onze sets them, no library defaults them
- [ ] `__bp_action` and `X-Bp-Action` appear in onze's defaults and nowhere under `repository/rakun/`
      or `repository/jhonstart/`

### Step 5 — What this front deliberately does not build

Written down so the question is answered before it is asked.

| Not built | Why it is not here |
|---|---|
| `reexports.bp` | A consumer writes `import {div, text} from "jhonstart";` because that is where `div` lives. A re-export layer buys one shorter import line for a second name for every symbol in three libraries |
| `PageProps` / `LayoutProps` / `Params` | jhonstart front 30 delivers `PageContext` and `LayoutProps`, and `params` is a `std` `Dict` read with `lookup(k).unwrapOr("")`. A second vocabulary is a translation layer and a class of bugs |
| `registerPage` / `registerLayout` / `registerAction` | jhonstart front 30's `#[page]` / `#[layout]` decorators fill jhonstart's UI registry, the boot copies it into rakun's table and `page(pattern, render)`, front 24's `#[serverAction]` registers actions, and front 50's CLI generates the `pub mod` lines that make the decorated modules load |
| `renderDocument` | jhonstart front 30 owns the document and the moments the render plugin is called, because only the render knows whether the response is streaming |
| `ActionResponse<S>(state, success, message)` | Front 24's `ActionResult` is the action envelope |
| `RouteSegmentConfig(dynamic, revalidate)` | Front 60's `SegmentConfig(dynamic, dynamicParams, revalidate, fetchCache)` |

**Acceptance:**
- [ ] `repository/onze/src/` contains no type whose name also exists in rakun or jhonstart
- [ ] `docs.md` carries this table, so the question is answered before it is asked

### Step 6 — The import alias map

Next's `@/*` alias exists because a route tree is deep and `../../../components/button` is both ugly
and wrong the moment a file moves (`NEXTJS-DOCS.md § 2`, *Alias de import e imports absolutos*). An
`app/blog/[slug]/page.bp` importing a component four directories up has the same problem, and
botopink's module resolution — `mod` paths relative to the package root, plus `from "<lib>"` for a
dependency — gives no third form.

onze adds one: an `alias` map in the project's `botopink.json`, resolved by the CLI before the
compiler sees the import.

```json
{
  "name": "blog",
  "alias": {
    "@/components": "components",
    "@/lib": "lib"
  }
}
```

`import {PostCard} from "@/components.post_card";` resolves to the package-relative module path
`components.post_card`. The mechanism is textual and build-time: front 50's scan rewrites the alias
prefix to the mapped path when it generates `.onze/routes.bp` and when it compiles the app, exactly
as it rewrites `app/` paths into route patterns. The compiler is not changed and does not know aliases
exist — which is also the limit: an alias is not visible to `botopink check` run directly on the
source tree, only through `onze dev` / `onze build`, and the README says so rather than letting a
developer discover it.

onze owns the map's shape and its resolution function (`resolveAlias(map, spec) -> string`); front 50
owns calling it.

```bp
pub type AliasMap(entries: Array<#(string, string)>)

pub fn resolveAlias(map: AliasMap, spec: string) -> string
```

**Acceptance:**
- [ ] `resolveAlias` with `@/components → components` maps `"@/components.post_card"` to
      `"components.post_card"`
- [ ] A spec with no matching prefix is returned unchanged
- [ ] Two prefixes where one is a prefix of the other (`@/lib` and `@/lib/db`) resolve longest-first,
      asserted
- [ ] An alias whose target escapes the package root (`"..": ".."`) is rejected at config load, naming
      the entry

### Step 7 — `ONZE_PUBLIC_` and the env split

The rule from *Seam 4*, as code owned by this front.

```bp
pub val publicEnvPrefix: string = "ONZE_PUBLIC_";

pub fn isPublicEnvName(name: string) -> bool
pub fn publicEnv(names: string[]) -> Array<#(string, string)>
```

`publicEnv` reads each name through std's `env.read` and drops every name the predicate rejects, so
the list front 68 inlines into the bundle cannot contain a non-public value even if the bundler's
caller passes one.

**Acceptance:**
- [ ] `isPublicEnvName("ONZE_PUBLIC_API_URL")` is true; `isPublicEnvName("DATABASE_URL")` is false
- [ ] `isPublicEnvName("onze_public_x")` is false — the prefix is case-sensitive, asserted, because a
      case-insensitive match is how a secret named `Onze_Public_Secret` would leak
- [ ] `publicEnv(["ONZE_PUBLIC_A", "SECRET_B"])` returns at most one entry, never two
- [ ] The README of front 68 cites this front for the rule and does not restate the prefix

## Examples

- [`examples/config-example.bp`](./examples/config-example.bp) — `onze.json`'s shape as a botopink
  value: defaults, immutable overrides, and the origin string the CLI prints and `Link` prefetches
  against.
- [`examples/integration-example.bp`](./examples/integration-example.bp) — the boot adapter, and a
  page and layout written in jhonstart front 30's vocabulary rather than in a second one: `#[page]`,
  `#[layout]`, `PageContext`, `LayoutProps`, and emilia's class arriving through front 48's `styled`.
- [`examples/alias-and-env-example.bp`](./examples/alias-and-env-example.bp) — the import alias map
  resolving a deep app import, and the `ONZE_PUBLIC_` predicate refusing a server secret.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied | every `jhonstart` call in `examples/integration-example.bp` spells `attrs:` | pass every argument explicitly | apply the declared default at the call site (ground truth §2.24) |
| No assignment to a `self` field | `OnzeConfig` has `withPort`/`withDev` instead of setters | return a new record | mutable record fields, or a `with` expression |

## Test plan

`test/config_test.bp` and `test/types_test.bp`, both run by `botopink test` from
`repository/onze/` and by `zig build test-libs` from `repository/botopink-lang/` once onze is a
sibling library. Both targets: this front's values are plain records and both backends must agree on
them, which is the cheapest possible check that the package is wired for erlang at all — the first
front in track E to get an erlang red will otherwise get it much later and much less legibly.

`test/config_test.bp` asserts the six default values, that `with*` copies every other field,
`origin()`'s composition, `resolveAlias`'s longest-prefix rule, and the `ONZE_PUBLIC_` predicate
including its case sensitivity. `test/types_test.bp` asserts the `AppFile` classification for every
row of the routing-file table, including that the segment string it produces for
`app/blog/[slug]/page.bp` is `"blog/[slug]"` character for character — which is the value front 22's
decorator takes and front 50's scan compares against.

`test/` in this front is deliberately dependency-free: it imports only `std`, so a red there is
unambiguously onze's and not a sibling's. The assertions that need `emilia`, `jhonstart` or `rakun`
live with the examples.

## Definition of done

- [ ] `repository/onze/` exists with `botopink.json`, `src/root.bp`, `src/config.bp`,
      `src/types.bp`, `src/integration.bp` (the wiring), `AGENTS.md`, `README.md`, `docs.md`
- [ ] `.github/workflows/test.yml` runs `botopink test --target commonJS` and `--target erlang`
- [ ] `onze` appears as a cell in `zig build test-libs` on both targets
- [ ] The four seams are documented in `docs.md` with the same precision as the *Mechanism* section
      here, because fronts 22, 23, 48, 50, 53, 68 and 69 all read them
- [ ] `docs.md` carries the *What this front deliberately does not build* table
- [ ] `docs.md` states that onze is opt-in: nothing in `libs/std` or the compiler references it
- [ ] `docs.md` states the OTP version onze requires, as the replacement for Next's
      "Node.js >= 20.9" system requirement (`NEXTJS-DOCS.md § 2`)
- [ ] The front's tests are green on its assigned target — both, here
