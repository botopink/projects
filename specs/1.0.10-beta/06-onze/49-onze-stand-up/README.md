# Front 49 — onze Stand-up

**Track:** E onze
**Priority:** critical — no other track-E front has a package to land in, and nothing in the milestone
joins rakun's server to jhonstart's tree to emilia's stylesheet until this front says where the joint is
**Target:** both — the config value and the route registry are read by the BEAM server half and by the
JS build half; the render seam runs on erlang, the registry it reads is built by the js half
**Wave:** 5 — after jhonstart front 30, whose render and bridge the boot wires (decision 113)
**Depends on:** 30 (jhonstart's render: `app`, `renderStream`, `Response`, `RenderPlugin`, `RenderHooks`, the UI
registry the `#[page]` / `#[layout]` decorators fill, and the `jhonstart-emilia` bridge member whose
`plugin()` the boot registers) · 28 (`RequestData`, built here from rakun's `Request`) · 23
(`ChunkWriter` with `setStatus` / `setHeader`, `PageRenderer` and `page(pattern, render)`, the
registry the boot hands one renderer per page) · 22 (rakun's route table and `rakun.appDir`) · 05 (the configuration the boot writes
`rakun.appDir`, `rakun.actions.field`, `rakun.actions.header`, `rakun.actions.bodyLimit` and
`rakun.i18n.exclude` into — fronts 22, 24 and 64 read them later and are not dependencies
of the boot) · 82 (rakun-web's `registerStaticRoot`, which the boot calls with front 69's
`staticRoots` — decision 116)
**Owns:** `repository/onze/botopink.json` (the workspace), `modules/onze/botopink.json`, `modules/onze/src/root.bp`, `modules/onze/src/types.bp`, `modules/onze/src/config.bp`, `modules/onze/src/integration.bp`,
`modules/onze/test/config_test.bp`, `modules/onze/test/types_test.bp` — the member cut of [`../modules.md`](../modules.md)
**Does not touch:** `repository/jhonstart/**` (the render, `RenderHooks`, `RenderPlugin` and the
`jhonstart-emilia` bridge are jhonstart front 30's), `repository/rakun/src/**`,
`repository/emilia/src/**`, `libs/std/src/**`, `repository/onze/modules/onze-assets/src/image.bp` (F51),
`repository/onze/modules/onze-assets/src/font.bp` (F52), `repository/onze/modules/onze-cli/**` (F50),
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

The orchestrator has no code: `repository/onze/` holds only the retired mocking library, which
front 01-std removes ([`../../01-std/onze-migration.md`](../../01-std/onze-migration.md)).

The consequence is not that onze is missing a feature. It is that fronts 50–53 have no package to
write into, and fronts 22, 23, 24 and 25 have no consumer — they will build a file router, an SSR
pipeline, server actions and route handlers against a caller that nobody has written, which is the
reliable way to build four things that do not fit together.

## Current state

- `repository/onze/` holds only the mocking library (`src/onze.bp`), which front 01-std removes;
  the orchestrator's modules do not exist.
- `repository/jhonstart/modules/jhonstart/src/element.bp` — `Element(tag, value, children, attrs)`
  and `renderToString`.
- `repository/emilia/modules/emilia/src/emilia.bp` — `emilia(tokens: Token[]) -> string` registers a
  rule and returns a class name; `flush() -> @Task<string>` serializes the sheet **and clears it**,
  which is why ordering matters: a second flush emits no rules.
- `repository/rakun/modules/rakun/src/http.bp` — `App(port, basePath)`; `src/bootstrap.bp` —
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
  └────► rakun
```

jhonstart and rakun never import each other, and emilia imports nobody; every value that crosses
between jhonstart and rakun is handed across by onze. The route matcher and the routing codecs are
not one of those values: they are the compiler-bundled library `routing`, which rakun and jhonstart
each import directly (decision 115), so onze neither imports nor hands it.

What onze actually contributes, once fronts 22, 23, 30, 48 and 69 exist, is small and worth stating
plainly: one config record (`OnzeConfig`), one import-alias map, one
environment-variable rule, one project-file vocabulary the CLI and front 22 both read, and one boot
adapter. Everything else in track E stands on those five and on the other fronts' own surfaces.

### The three seams, and who actually owns each of them

**onze does not own a page registry, a props vocabulary, a renderer or a head-insertion point.**
rakun front 22 owns the route table (its matcher is the bundled `routing`) and front 23 the opaque page
registry, jhonstart front 30 owns the render, its plugin point and the UI conventions, and
onze's job is to be the package where they meet and the project-level configuration they read.

**Seam 1 — how a project's `app/` tree reaches front 22's route table.**

Not at comptime. `@Decl` carries no source location (`language-gaps.md`), so a decorator cannot learn
which file it annotates, and a decorator body runs in a minimal eval prelude with no `fs`. The answer
is an explicit argument: `#[page("blog/[slug]")]`, `#[layout("blog")]` (jhonstart front 30's UI
decorators), `#[getRoute("api/posts")]` (rakun front 25's), where the argument is the app-relative
directory and the segment grammar is front 22's, in the bundled library `routing`. Front 50's CLI generates the `pub mod` lines from the
tree and **fails the scan when a file's location and its decorator argument disagree** — that check is
the whole of the file-system convention, and it lives in the CLI because nothing else can see a
directory.

onze's contribution to this seam is one config value: `appDir`, which the boot writes into rakun's
configuration as `rakun.appDir` (decision 115 — rakun reads no `onze.` key). Front 22 scans what that
key says to scan, so `app/` and `src/app/` are the same mechanism with a different string.

**Seam 2 — how a matched route becomes HTML, and the HTML reaches the wire.**

rakun serves and jhonstart renders; neither names the other, so onze hands each one what it needs
from the other (decision 113):

- to **rakun's route table** (front 22), the UI records: the `#[page]`, `#[layout]`, `#[template]`
  and `#[defaultView]` decorators are jhonstart front 30's and fill jhonstart's UI registry; the boot
  reads that registry and registers each record in rakun's table, so the table the server matches
  and the payload's `t` stay one table (contract 1, decision 114);
- to **rakun**, one opaque `PageRenderer` per page pattern (front 23, decision 114): rakun matches the
  route, opens the request scope (front 62), calls the renderer with its `Request` and a
  `ChunkWriter`, and closes the response if the renderer's future resolves with it still open.
  rakun knows no HTML. The renderer is an adapter and nothing more: it wraps rakun's `ChunkWriter`
  in jhonstart's `Response` (decision 117) and hands it to the render:

  ```bp
  // onze/src/integration.bp — `site` is jhonstart's `App`, `input` the jhonstart page input for `route`
  rakun.page(route, fn(req: Request, out: ChunkWriter) -> @Task<@Result<void, string>> {
      return site.renderStream(input(req), requestData(req), Response(
          status: fn(c) { out.setStatus(c); },
          header: fn(n, v) { out.setHeader(n, v); },
          write:  fn(chunk) { return out.write(chunk); },
          close:  fn() { return out.close(); },
      ));
  });
  ```

- to **jhonstart's render** (front 30), inside that renderer: the `PageInput` — the segment chain
  (layouts, templates and boundaries from jhonstart's UI registry, keyed by front 22's layout chain
  for the matched pattern) and the payload's rakun-side values as strings: the route table `t`, the
  actions `a` and the build id `b`; the `RequestData` (front 28) that `requestData(req)` builds from
  rakun's `Request`, which is what jhonstart's `request()`, `headers()` and `cookies()` read; and a
  jhonstart `Response` over rakun's `ChunkWriter`. jhonstart never sees the `ChunkWriter`, and rakun
  never sees the `Response`;
- to **both sides of a server action**, the wire names (decision 114): the boot sets rakun's
  `rakun.actions.field` / `rakun.actions.header` (fronts 05 and 24) and passes the same two values to
  jhonstart's form binding as `actionField` / `actionHeader` (front 67). onze's defaults are
  `__bp_action` and `X-Bp-Action`; neither library spells a name. The same boot writes
  `rakun.actions.bodyLimit` from `OnzeConfig.actionsBodyLimit` (default 1048576, decision 117) and
  `rakun.appDir` from
  `OnzeConfig.appDir` — every key rakun reads is a `rakun.*` key (decision 115) — and
  `rakun.i18n.exclude` with onze's asset prefix `/_onze` appended, so rakun's locale redirect skips
  onze's URLs without rakun spelling them (decision 116);
- to **rakun-web's static-file server** (front 82), the two roots front 69's `staticRoots(publicDir,
  outDir, buildId)` returns, each registered with `registerStaticRoot`; onze serves no file itself
  (decision 116 rule 6);
- to **jhonstart's `app`**, the redirect allow-list: `OnzeConfig.allowedRedirects` (default empty)
  is passed as `app(allowedRedirects: …)`, and front 68's generated entry hands the same list to the
  browser (decision 117).

**Navigation signals never reach onze.** A page, layout or template that raises jhonstart's
`notFound()` or `redirect(url)` (front 31) is handled entirely inside jhonstart's render (decision
117): before the first chunk the render itself calls `res.status(307)` / `res.header("location", …)`
or `res.status(404)` and the not-found boundary through the `Response` onze built, and after it the
render writes the late-signal markup (front 30). jhonstart also checks the redirect target — a
relative one against the route table, an absolute one against `allowedRedirects`. onze has no `case`
on a signal, reads no `nav:` reason and calls none of rakun's signals; `renderStream` answers no
outcome for it to read.

The vocabulary — `PageContext(pathname, pattern, params, rest)` (no `query`: `searchParams()` reads it and marks the render dynamic), `LayoutProps.children` — is
jhonstart front 30's, and onze does not restate it as `PageProps`/`Params`: a second name for every
value in the stack is a translation layer and a class of bugs.

**Seam 3 — how emilia's classes reach the HTML.**

`emilia(tokens)` registers a rule on a process-local sheet and returns a class name; `flush()`
serialises the sheet **and clears it**. The moments at which it is flushed —
once into the head after the shell, once per streamed boundary inside that boundary's fill
`<template>`, and nothing left at the end — are jhonstart's: front 30 declares the `RenderPlugin`
point, whose methods are asynchronous, and awaits it; the `jhonstart-emilia` bridge awaits emilia's
`flush()` (a `@Task<string>`) in `head` and `chunk`, and its `payload()` returns `#("s", <the classes it
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
- [x] `repository/onze/botopink.json` parses and names exactly the four `files` above
- [x] `botopink build` succeeds in `repository/onze/`
- [x] `repository/onze/AGENTS.md`, `README.md` and `docs.md` exist and follow the sibling repos'
      layout (`repository/emilia/AGENTS.md` is the model)
- [x] `zig build test-libs` discovers `onze` as a sibling library and reports a cell for it on both
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
    actionsBodyLimit: i32,           // bytes; written into rakun.actions.bodyLimit at boot
    allowedRedirects: Array<string>, // absolute redirect targets jhonstart accepts; handed to app(…)
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
- [x] `defaultConfig()` returns `port: 3000`, `basePath: ""`, `appDir: "app"`, `publicDir: "public"`,
      `outDir: ".onze"`, `dev: false`, `actionsBodyLimit: 1048576` (rakun front 24's 1 MiB default,
      decision 117), `allowedRedirects: []` — the values the CLI's scaffold writes into `onze.json`
- [x] `withPort(defaultConfig(), 4000).appDir == defaultConfig().appDir` — the copy carries every
      other field
- [x] `withPort(defaultConfig(), 4000).origin() == "http://localhost:4000"`
- [x] `test/config_test.bp` green on `commonJS` and on `erlang`

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
- [x] `AppFile.kind` covers exactly the eight conventions in `NEXTJS-DOCS.md § 3` — no more, no fewer
- [x] The `segment` produced for `app/blog/[slug]/page.bp` is `"blog/[slug]"`, matching front 22's
      decorator argument character for character, including the bracket spelling
- [x] The `segment` produced for `app/(marketing)/about/page.bp` is `"(marketing)/about"` — the group
      is in the segment and absent from the route pattern, which is front 22's distinction, not this
      front's
- [x] `test/types_test.bp` green on `commonJS` and on `erlang`

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
      `jhonstart-emilia` together (decision 113): it builds `app(plugins: [emiliaPlugin()],
      allowedRedirects: config.allowedRedirects)`, fills
      jhonstart's `RenderHooks.headExtra` / `bodyExtra` with front 68's tags (empty while 68 does
      not exist), registers jhonstart's UI records in rakun's table and hands rakun one
      `PageRenderer` per page through `page(pattern, render)`, builds `RequestData` from rakun's
      `Request`, sets `rakun.actions.field` / `rakun.actions.header` and passes the same values to
      jhonstart as `actionField` / `actionHeader`, sets `rakun.appDir`, `rakun.actions.bodyLimit` and
      `rakun.i18n.exclude` from `OnzeConfig`, registers front 69's two static roots with
      rakun-web front 82, and wraps rakun's `ChunkWriter` in jhonstart's `Response` (decision 117).
      It has no `case` on a navigation signal, imports nothing from `routing` and hands jhonstart
      no matcher. Any other onze file reaching for
      the seam means the seam is in the wrong place, and the front says so under *Blocked* rather
      than adding a second wiring point
- [x] Nothing under `repository/onze/modules/` calls emilia's `flush()`, and no onze file defines a style
      sink — the flush moments are jhonstart front 30's and the adaptation is the bridge's
- [ ] The renderer handed to rakun maps `Response.status` / `header` / `write` / `close` onto
      `out.setStatus` / `setHeader` / `write` / `close` one to one and resolves when jhonstart's
      render does; a page whose layout calls `redirect("/login")` answers 307 with
      `location: /login` without onze code on the path; with the action-name keys removed from the boot, rakun refuses to start its action
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
- [x] `repository/onze/modules/onze/src/` contains no type whose name also exists in rakun or jhonstart
- [x] `docs.md` carries this table, so the question is answered before it is asked

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
- [x] `resolveAlias` with `@/components → components` maps `"@/components.post_card"` to
      `"components.post_card"`
- [x] A spec with no matching prefix is returned unchanged
- [x] Two prefixes where one is a prefix of the other (`@/lib` and `@/lib/db`) resolve longest-first,
      asserted
- [x] An alias whose target escapes the package root (`"..": ".."`) is rejected at config load, naming
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
- [x] `isPublicEnvName("ONZE_PUBLIC_API_URL")` is true; `isPublicEnvName("DATABASE_URL")` is false
- [x] `isPublicEnvName("onze_public_x")` is false — the prefix is case-sensitive, asserted, because a
      case-insensitive match is how a secret named `Onze_Public_Secret` would leak
- [x] `publicEnv(["ONZE_PUBLIC_A", "SECRET_B"])` returns at most one entry, never two
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

## Where it stands

Implemented (the orchestrator's workspace, before the decision-79 takeover):
`modules/onze/src/{config,types,integration}.bp`, `test/{config,types,integration}_test.bp`
(21 tests, commonJS and erlang, `botopink test` and `botopink-lib-test` rows), `docs.md`, and
`modules/onze-test/src/{core,fixtures}.bp` with its 7 tests. The file cut is `modules.md`'s:
`repository/onze/src/…` in this README reads `repository/onze/modules/onze/src/…`, and step 1's
`botopink build` runs in the member (the workspace root refuses it, decision 75).

**Blocked on rakun** (the boxes left open in step 4): rakun's `ChunkWriter` with `setStatus` /
`setHeader`, `PageRenderer` and `page(pattern, render)` (front 23 step 1), the core on
`["erlang"]` (front 04 — today `modules/rakun` is `["commonJS"]` and `rakun-web` `["erlang"]`, so
no both-target member can import the pair), `registerStaticRoot` (front 82) and a library-side way
to apply configuration entries do not exist in rakun today. The boot therefore hands rakun
data and adapters — `rakunEntries(config, i18nExclude)` (the five `rakun.*` keys),
`responseOver(setStatus, setHeader, write, close)`, `chainFor(patterns)` over the ancestor
patterns rakun's layout chain names — and `Onze.run` (`Rakun.run(App(port, basePath))` after the
boot), the per-page renderer registration and `requestData(req)` from rakun's `Request` land
when those do. The `__bp_action` box stays open because `jhonstart-forms/test/form_test.bp`
passes the two names in as literals (a test of the setter, not a default). Step 7's last box stays
open: front 68's README names the prefix while citing this front.

**Choices** recorded in `../../decisions-pending.md` 49-a…d.

### Compiler findings (each repro is the whole program, inline)

| # | Finding | Minimal repro | Workaround in onze |
|---|---|---|---|
| F1 | **Closed** (the erlang test runner loads the sibling a `pub val` is read from; `tests/language/modules/pub_val_in_a_test`). A `pub val` imported from a sibling module is `undefined` on commonJS and fails the erlang compile (`escript: There were compilation errors`) | `src/a.bp`: `pub val greeting: string = "hi";` · `test/a_test.bp`: `import {greeting} from "a"; test "r: x" { assert greeting == "hi"; }` | every constant is a `pub fn` |
| F2 | **Closed** (the type closure also reads the types the declaring module imports; `tests/language/modules/import_type_closure_across_modules`). Importing a record type from another package does not bring the types its fields or methods name from the package's *other* modules: `unknown type 'Other'`, located at the dependency's line in the consumer's file | lib `a.bp`: `pub type Other(y: i32)`; lib `c.bp`: `import {Other} from "a"; pub type Outer(others: Array<Other>) {…} pub fn outer() -> Outer {…}`; app: `import {Outer, outer} from "lib"; pub fn seven() -> Outer { return outer(); }` | `integration.bp` imports `RenderPlugin`, `RequestData`, `ErrorInfo`, `LayoutProps`, `PageContext`, `OpenGraph`, `TwitterCard`, `Icons` beside `App` / `PageInput` / `UiSegment` |
| F3 | **Closed** by decision 143 — a dependency's own `dependencies` load transitively, each package once, after the packages it depends on; a name on two directories and a cycle are refused on the manifest entry |
| F4 | **Closed** (method bodies receive the `@Option` / `@Result` method lowerings; `tests/language/run/unwrap_or_positions.bp`). `xs.at(i).unwrapOr(d)` inside a record method is not lowered: commonJS `__bp_array_at(...).unwrapOr is not a function`, erlang module does not compile; the same body in a free function works | `pub type Box(items: Array<R>) { pub fn firstV(self: Self) -> string { val hit: Array<R> = self.items.filter({ r -> r.v != "" }); return hit.at(0).unwrapOr(R(v: "")).v; } }` | the method calls a free function |
| F5 | **Closed** (`build`, `check` and `test` read the manifest's `src`; `tests/language/modules/src_at_package_root`). A package whose `"src"` is `"."` is not honoured: `botopink check` answers "no source files found in src/ or test/", and a test cannot import a nested module | `{ "src": ".", "entry": "root.bp" }`, `root.bp` `pub mod lib;`, `lib/mod.bp` `pub mod db;`, `lib/db.bp` `pub fn one() -> i32 { return 1; }`, `test/a_test.bp` `import {one} from "lib.db"; test "p: x" { assert one() == 1; }` | the blog and the scaffold keep their sources under `src/` |
| F6 | **Closed** (every expression statement of an `if` branch is walked by the transform; `tests/language/run/string_slice_in_if_branch.bp`). On erlang, a one-argument `s.slice(1)` as an `if`-expression branch lowers to an undefined `string_slice/2` in a module with no statement-form one-argument slice | `pub fn tail(s: string) -> string { return if (s == "/") "index.html" else s.slice(1) + "/index.html"; }` | `s.slice(1, s.length())` |
| F7 | **Closed** (integer `/` truncates toward zero on every backend; `tests/language/run/integer_division_truncates.bp`). `i32 / i32` divides as a float on commonJS (`7 / 2` is `3.5`) and as an integer on erlang (`3`) | `pub fn half(n: i32) -> i32 { return n / 2; }` with `assert half(7) == 3` — fails on commonJS only | an `idiv` host cell (`Math.trunc` / `div`) |
| F8 | **Closed** (an import from a module that does not lex or parse reports that module's located error; `tests/language/modules/lexer_error_in_imported_module`). A lexer error inside an imported module is not printed; the importer reports "imported symbol is not exported by the named module" | a module whose triple-quoted template holds `\.` ("bad string escape"), imported by a sibling | `[.]` in the regex; `botopink test` on the module alone shows the real error |
| F9 | **Closed** (a parenthesised expression is walked like the one it holds; `tests/language/run/unwrap_or_positions.bp`). F4 widens: `xs.at(i).unwrapOr(d)` is emitted as a call to an undefined `unwrapOr` also as an `if`-expression branch followed by a field read, nested inside another `unwrapOr`, or over a `map` result whose element type is not annotated (commonJS `is not a function`, erlang `unwrapOr/2 undefined`) | `val sizes = xs.map({ x -> #(1, 2) }); for (xs) { x -> val z = sizes.at(0).unwrapOr(#(0, 0)); }` | a `val` per step and an annotated `Array<…>` |
| F10 | **Closed** by decision 140 (the entry runs each imported module's `'_botopink_init'/0`, dependencies first, in a build and in a test runner; `tests/language/modules/pub_val_across_modules`). On erlang a module-level `val` with an effect is the module's `'_botopink_init'/0`, and nothing calls it for a module that is only imported — a `#[page]` / `#[layout]` registration in `app/layout.bp` never runs when a test (or a server) imports it; on node the require runs it | `lib/a.bp`: `val _r = register("x");` (any effectful call), imported by a test that reads the registry | onze core's `loadModuleBodies(atoms)` calls each module's init; the boot owes the call for the staged app |

## Definition of done

- [x] `repository/onze/` exists with `botopink.json`, `src/root.bp`, `src/config.bp`,
      `src/types.bp`, `src/integration.bp` (the wiring), `AGENTS.md`, `README.md`, `docs.md`
- [x] `.github/workflows/test.yml` runs `botopink test --target commonJS` and `--target erlang`
- [x] `onze` appears as a cell in `zig build test-libs` on both targets
- [x] The four seams are documented in `docs.md` with the same precision as the *Mechanism* section
      here, because fronts 22, 23, 48, 50, 53, 68 and 69 all read them
- [x] `docs.md` carries the *What this front deliberately does not build* table
- [x] `docs.md` states that onze is opt-in: nothing in `libs/std` or the compiler references it
- [x] `docs.md` states the OTP version onze requires, as the replacement for Next's
      "Node.js >= 20.9" system requirement (`NEXTJS-DOCS.md § 2`)
- [x] The front's tests are green on its assigned target — both, here
