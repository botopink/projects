# Front 49 — onze13 Stand-up

**Track:** E onze13
**Priority:** critical — no other track-E front has a package to land in, and nothing in the milestone
joins rakun's server to jhonstart's tree to emilia's stylesheet until this front says where the joint is
**Target:** both — the config value and the route registry are read by the BEAM server half and by the
JS build half; the render seam runs on erlang, the registry it reads is built by the js half
**Wave:** 0
**Depends on:** none
**Owns:** `botopink.json`, `src/root.bp`, `src/types.bp`, `src/config.bp`, `src/integration.bp`,
`test/config_test.bp`, `test/types_test.bp`
**Does not touch:** `repository/jhonstart/src/**`, `repository/rakun/src/**`,
`repository/emilia/src/**`, `libs/std/src/**`, `repository/onze13/src/image.bp` (F51),
`repository/onze13/src/font.bp` (F52), `repository/onze13/modules/onze13-cli/**` (F50),
`repository/onze13/examples/blog/**` (F53)
**Reference:** `NEXTJS-DOCS.md § 1. Introdução`, `§ 2. Instalação e Configuração` (alias de import),
`§ 3. Estrutura do Projeto`, `§ 7. Server e Client Components` (`NEXT_PUBLIC_`),
`§ 28. Configuração (next.config.js)` ·
<https://nextjs.org/docs/app/getting-started/project-structure> ·
<https://nextjs.org/docs/app/api-reference/config/next-config-js> ·
<https://nextjs.org/docs/app/guides/environment-variables>
**Replaces:** `1.0.7-beta/01-onze13-stand-up`

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

`repository/onze13/` does not exist. Nothing in the tree references it — `grep -r onze13 repository/`
returns nothing outside `specs/`. The name appears in `specs/1.0.7-beta/` as a plan and in
`specs/1.0.9-beta/overview.md` as track E, and that is the whole of its current existence.

The consequence is not that onze13 is missing a feature. It is that fronts 50–53 have no package to
write into, and fronts 22, 23, 24 and 25 have no consumer — they will build a file router, an SSR
pipeline, server actions and route handlers against a caller that nobody has written, which is the
reliable way to build four things that do not fit together.

## Current state

- `repository/onze13/` does not exist. The five libraries in the workspace are `emilia`, `erika`,
  `jhonstart`, `onze` (the mocking library — unrelated, and the name collision is worth noting) and
  `rakun`, plus `libs/std`.
- `repository/jhonstart/src/element.bp:3-8` — `Element(tag, value, children, attrs)`, and
  `element.bp:55-67` — `renderToString`. This is the whole render surface that exists today, and it
  is enough for onze13's render seam.
- `repository/emilia/src/emilia.bp:46-51` — `emilia(tokens: Token[]) -> string` registers a rule and
  returns a class name; `emilia.bp:62-65` — `#[@future] flush() -> @Future<string>` serializes the
  sheet **and clears it**. `emilia.bp:53-56` is the reason ordering matters: a second flush emits
  `<style></style>`.
- `repository/rakun/src/http.bp:75-78` — `App(port, basePath)`; `src/bootstrap.bp:28-37` —
  `Rakun.run(app)`. There is no `app/` convention, no layout chain, no page concept.
- `repository/rakun/modules/` shows the shape a module package takes in this ecosystem: a
  `botopink.json` with a `dependencies` map pointing at `../../`, and a `src/root.bp`. onze13 copies
  that shape rather than inventing one.

## Mechanism

Next.js is a router, a renderer and a build tool sharing one project convention. onze13 is the same
three things, except the router is rakun, the renderer is jhonstart, the stylesheet is emilia, and the
build tool is front 50. onze13 itself is **the joint** — five files that agree on the vocabulary the
three libraries do not share.

That vocabulary is four value types (`Params`, `PageProps`, `LayoutProps`, `RouteContext`), one config
record (`Onze13Config`), and one registry (`integration.bp`). Everything else in track E stands on
those.

### The three seams, precisely

**Seam 1 — how a project's `app/` tree reaches front 22's file router.**

It does not reach it at comptime. Botopink's comptime sees declarations, not directories: `@Decl`
exposes a declaration's kind, name, fields and methods (`libs/std/src/builtins.d.bp:425-477`), and a
decorator body runs in a minimal eval prelude with no `fs` (ground truth §2.4, §2.37). A comptime
`app/` walk is not possible, and pretending otherwise is how the 1.0.7 draft got here.

So the walk happens at build time, in the CLI, and produces botopink source. `onze13 build` and
`onze13 dev` (front 50) walk `<projectRoot>/<config.appDir>`, classify each file by basename against
the routing-file table (`NEXTJS-DOCS.md § 3`), convert the directory path to a rakun route pattern,
and write one generated module:

| `app/` path | route pattern | registry call |
|---|---|---|
| `app/page.bp` | `/` | `registerPage("/", HomePage)` |
| `app/layout.bp` | `/` | `registerLayout("/", RootLayout)` |
| `app/blog/page.bp` | `/blog` | `registerAsyncPage("/blog", BlogPage)` |
| `app/blog/[slug]/page.bp` | `/blog/:slug` | `registerAsyncPage("/blog/:slug", BlogPost)` |
| `app/(marketing)/about/page.bp` | `/about` | group segment dropped from the pattern |
| `app/blog/loading.bp` | `/blog` | `registerLoading("/blog", Loading)` |
| `app/api/posts/route.bp` | `/api/posts` | `registerHandler("/api/posts", …)` |
| `app/_components/card.bp` | — | `_`-prefixed folder, skipped |

`.onze13/routes.bp` is the generated module. It imports each `app/` module by its `mod` path and
calls the registry once per file. Front 22 never sees a filename; it sees `registerPage` calling its
route-table API with a pattern string. onze13 owns the filename→pattern translation, front 22 owns
pattern matching and param extraction, and the boundary between them is a string.

**Seam 2 — how front 23's SSR pipeline gets a jhonstart tree.**

Front 23 renders a matched route. What it needs is one `Element`, and what the `app/` convention
gives it is a page plus every `layout.bp` on the path above it, outermost first. `integration.bp`
folds them: `composeTree(route, props)` looks the page up in the registry, calls it, then wraps the
result through each registered layout by building a `LayoutProps(children: …, params: …)` and calling
the layout fn. The value handed to front 23 is an `Element` — no adapter type, because
`renderToString` already exists and already takes one.

Botopink has no effect polymorphism: a fn either returns `Element` or `@Future<Element>`, and one
registry slot cannot hold both. So the registry has **two** page entry points — `registerPage` for a
synchronous page and `registerAsyncPage` for a server component (front 28) — and two layout entry
points for the same reason. This is a design consequence, not a workaround, and it is visible in the
generated manifest: the CLI picks the entry point from the page's declared return type.

**Seam 3 — how front 48's emilia classes reach the HTML.**

`emilia(tokens)` has a side effect: it registers a rule on a process-local sheet and returns the class
name (`emilia.bp:46-51`). `flush()` serializes the sheet and clears it. The correct order is
build-the-tree, then flush, then serialize the document — and there is exactly one place in onze13
where that order is decided, `renderDocument`:

```bp
#[@future]
pub fn renderDocument(config: Onze13Config, head: string, body: Element) -> @Future<string> {
    val markup = renderToString(body);
    val styles = await flush();
    return "<!DOCTYPE html><html><head>" + head + styles + "</head><body>" + markup + "</body></html>";
}
```

Two properties follow and both are testable. On the erlang half the sheet is per-BEAM-process, so a
per-request process gives per-request style isolation with no work — two concurrent requests cannot
leak classes into each other. On the js half there is one process, so the client bundle must never
call `flush()`; the document's `<style>` block is produced on the server and nowhere else.

`renderDocument` is the **non-streaming** case, and it is the whole of front 49's claim here. The
streaming case — where a late chunk registers classes after the head has already been flushed — is
front 69's (`onze13-styling-pipeline`), which owns the insertion point inside front 23's pipeline, the
`useServerInsertedHTML` analogue. Front 49 gives front 69 the ordering rule and one working
implementation of it; front 69 generalizes that to a streamed response and to module CSS. A front-49
change that moves the flush out of `renderDocument` is a front-69 change and belongs there.

Front 48 matters to this seam only for the `html """…"""` path: with the builder API the class already
reaches `attrs` today (`attrs: [#("class", cls)]`), and front 48 is what lets
`html """<div [class]={cls}>…</div>"""` do the same. `renderDocument` is indifferent to which produced
the tree, which is what makes front 48 and front 49 independent.

### Seam 4 — the environment split, which is a security rule

`Onze13Config` is read on both halves, and environment variables are not. A value read through
`env.read` on the server may be a database password; the same read compiled into the client bundle
publishes it. The rule this front declares, and front 68 (`onze13-client-bundle`) enforces at bundle
time:

> An environment variable is inlinable into the client bundle **only** if its name begins with
> `ONZE_PUBLIC_`. Any other `env.read` reached from a client module fails the build, naming the
> variable and the module that read it. There is no flag, config key or annotation that downgrades
> this to a warning.

Front 49 owns the prefix constant and the two predicates (`isPublicEnvName`, `publicEnv()`), so that
the rule has one definition rather than one per consumer; front 68 owns the graph walk that applies
it. Stating the prefix here and enforcing it there is deliberate: the rule must be readable by an app
author who never opens the bundler's front.

### What onze13 does not do

It does not re-export jhonstart, rakun or emilia. The 1.0.7 draft proposed a `reexports.bp` and it is
dropped: a consumer writes `import {div, text} from "jhonstart";` because that is where `div` lives,
and a re-export layer buys one shorter import line at the cost of a second name for every symbol in
three libraries. onze13's public surface is only the vocabulary the three do not share.

## Steps

### Step 1 — Package shape

Copy the shape the workspace already uses. `botopink.json` mirrors `repository/emilia/botopink.json`
and `repository/jhonstart/botopink.json`: `name`, `version`, `description`, `src`, `targets`, `files`.
The `dependencies` map mirrors `repository/rakun/modules/rakun-web/botopink.json`.

```json
{
  "name": "onze13",
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
- [ ] `repository/onze13/botopink.json` parses and names exactly the four `files` above
- [ ] `botopink build` succeeds in `repository/onze13/`
- [ ] `repository/onze13/AGENTS.md`, `README.md` and `docs.md` exist and follow the sibling repos'
      layout (`repository/emilia/AGENTS.md` is the model)
- [ ] `zig build test-libs` discovers `onze13` as a sibling library and reports a cell for it on both
      targets

### Step 2 — `config.bp`

`onze13.json` is the project's configuration file, the analogue of `next.config.js`
(`NEXTJS-DOCS.md § 28`). It is read by the CLI, not by the library: `Onze13Config` is a plain record,
`defaultConfig()` supplies every field the file omits, and the `with*` fns return new records because
botopink records are immutable.

```bp
pub type Onze13Config(
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

pub fn defaultConfig() -> Onze13Config { … }
pub fn withPort(base: Onze13Config, port: i32) -> Onze13Config { … }
pub fn withDev(base: Onze13Config, dev: bool) -> Onze13Config { … }
```

**Acceptance:**
- [ ] `defaultConfig()` returns `port: 3000`, `basePath: ""`, `appDir: "app"`, `publicDir: "public"`,
      `outDir: ".onze13"`, `dev: false` — the values the CLI's scaffold writes into `onze13.json`
- [ ] `withPort(defaultConfig(), 4000).appDir == defaultConfig().appDir` — the copy carries every
      other field
- [ ] `withPort(defaultConfig(), 4000).origin() == "http://localhost:4000"`
- [ ] `test/config_test.bp` green on `commonJS` and on `erlang`

### Step 3 — `types.bp`

The vocabulary. `Params` is a labeled-tuple array rather than a `Dict` because a route's params are a
handful of entries read by name once, and because `Dict`'s type name is reached through a qualified
module import that does not survive a `pub type` field position cleanly. Lookup returns `""` for an
absent key, matching `rakun`'s `Request.param` (`repository/rakun/src/http.bp:35-43`) — one absence
convention for the whole stack rather than two.

```bp
pub type Params(entries: Array<#(string, string)>) {
    pub fn param(self: Self, name: string) -> string { … }
    pub fn has(self: Self, name: string) -> bool { … }
}

pub type PageProps(params: Params, search: Params)
pub type LayoutProps(children: Element, params: Params)
pub type RouteContext(method: string, path: string, params: Params, search: Params)
pub type ActionResult(ok: bool, message: string, redirectTo: string)
pub type SegmentConfig(dynamicMode: string, revalidate: i32)
```

`SegmentConfig.dynamicMode` carries `"auto"`, `"force-dynamic"`, `"force-static"` or `"error"`, and
`revalidate` is seconds with `0` meaning "never cache" — the two route-segment knobs front 12 reads.

**Acceptance:**
- [ ] `Params(entries: [#("slug", "hello")]).param("slug") == "hello"`
- [ ] `Params(entries: []).param("slug") == ""` — absent is empty, never an error
- [ ] `Params(entries: [#("a", "1"), #("a", "2")]).param("a")` is documented and asserted (last wins)
- [ ] `LayoutProps` type-checks with a `jhonstart` `Element` in its `children` field
- [ ] `test/types_test.bp` green on `commonJS` and on `erlang`

### Step 4 — `integration.bp`, render half (wave 0)

The half that needs only jhonstart and emilia, and therefore lands in wave 0 with the rest of this
front: `renderDocument`, plus the layout fold that does not touch rakun.

```bp
#[@future]
pub fn renderDocument(config: Onze13Config, head: string, body: Element) -> @Future<string>

pub fn wrapInLayout(layout: fn(props: LayoutProps) -> Element, child: Element, params: Params) -> Element
```

**Acceptance:**
- [ ] `renderDocument` emits `<!DOCTYPE html>` once, `<style>` exactly once, and the rendered body
- [ ] A document built from a tree containing two `emilia(...)` calls carries both class rules in its
      single `<style>` block
- [ ] A second `renderDocument` in the same process emits `<style></style>` — asserted, because that
      is the sheet-clearing behaviour of `flush()` and the app must know it
- [ ] `wrapInLayout` applied twice nests outermost-first

### Step 5 — `integration.bp`, registry half (wave 3 follow-on)

The half that calls into fronts 22–25. It is written here and lands when those fronts do; front 49's
own definition of done stops at step 4.

```bp
pub fn registerPage(route: string, render: fn(props: PageProps) -> Element) -> i32
pub fn registerAsyncPage(route: string, render: fn(props: PageProps) -> @Future<Element>) -> i32
pub fn registerLayout(route: string, render: fn(props: LayoutProps) -> Element) -> i32
pub fn registerAsyncLayout(route: string, render: fn(props: LayoutProps) -> @Future<Element>) -> i32
pub fn registerLoading(route: string, render: fn() -> Element) -> i32
pub fn registerErrorBoundary(route: string, render: fn(props: ErrorProps) -> Element) -> i32
pub fn registerNotFound(route: string, render: fn() -> Element) -> i32
pub fn registerAction(name: string, run: fn(form: Params) -> @Future<ActionResult>) -> i32
pub fn registerHandler(route: string, method: string, run: fn(ctx: RouteContext) -> @Future<Response>) -> i32
```

Every registration takes a **lambda**, not a bare fn name — `registerPage("/", { p -> HomePage(p) })`.
The generated manifest writes it that way uniformly, so nothing in the registry depends on a top-level
fn being a first-class value, and page, layout, loading and action references all have one spelling.

Each returns the registry's new size, mirroring `rkScan`/`rkRegisterRoute`
(`repository/rakun/src/runtime.bp:19-117`) — an `i32` the generated manifest can bind to a `val`, which
is what makes a sequence of registrations a sequence of statements rather than a block of discarded
expressions.

**Acceptance:**
- [ ] Every `register*` fn forwards to front 22's route table with the pattern unchanged
- [ ] `composeTree("/blog/:slug", props)` returns the page wrapped by `app/blog/layout.bp` wrapped by
      `app/layout.bp`, in that order
- [ ] Registering the same route twice is an error naming the route, not a silent overwrite

### Step 6 — The import alias map

Next's `@/*` alias exists because a route tree is deep and `../../../components/button` is both ugly
and wrong the moment a file moves (`NEXTJS-DOCS.md § 2`, *Alias de import e imports absolutos*). An
`app/blog/[slug]/page.bp` importing a component four directories up has the same problem, and
botopink's module resolution — `mod` paths relative to the package root, plus `from "<lib>"` for a
dependency — gives no third form.

onze13 adds one: an `alias` map in the project's `botopink.json`, resolved by the CLI before the
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
prefix to the mapped path when it generates `.onze13/routes.bp` and when it compiles the app, exactly
as it rewrites `app/` paths into route patterns. The compiler is not changed and does not know aliases
exist — which is also the limit: an alias is not visible to `botopink check` run directly on the
source tree, only through `onze13 dev` / `onze13 build`, and the README says so rather than letting a
developer discover it.

onze13 owns the map's shape and its resolution function (`resolveAlias(map, spec) -> string`); front 50
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

- [`examples/config-example.bp`](./examples/config-example.bp) — `onze13.json`'s shape as a botopink
  value: defaults, immutable overrides, and the origin string the CLI prints and `Link` prefetches
  against.
- [`examples/integration-example.bp`](./examples/integration-example.bp) — the three render seams in
  one file: a page fn that produces a jhonstart tree, `Params` carrying a dynamic segment, and
  `renderDocument` putting emilia's sheet in the document head exactly once.
- [`examples/alias-and-env-example.bp`](./examples/alias-and-env-example.bp) — the import alias map
  resolving a deep app import, and the `ONZE_PUBLIC_` predicate refusing a server secret.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No effect polymorphism — one registry slot cannot hold both `fn(P) -> Element` and `fn(P) -> @Future<Element>` | `integration.bp` step 5 | two entry points, `registerPage` and `registerAsyncPage`, and the CLI picks by declared return type | a `?fn` effect variable, or an `@Future<T>` that a non-future value coerces into |
| Declared parameter defaults are never applied | every `jhonstart` call in `examples/integration-example.bp` spells `attrs:` | pass every argument explicitly | apply the declared default at the call site (ground truth §2.24) |
| No assignment to a `self` field | `Onze13Config` has `withPort`/`withDev` instead of setters | return a new record | mutable record fields, or a `with` expression |

## Test plan

`test/config_test.bp` and `test/types_test.bp`, both run by `botopink test` from
`repository/onze13/` and by `zig build test-libs` from `repository/botopink-lang/` once onze13 is a
sibling library. Both targets: this front's values are plain records and both backends must agree on
them, which is the cheapest possible check that the package is wired for erlang at all — the first
front in track E to get an erlang red will otherwise get it much later and much less legibly.

`test/config_test.bp` asserts the six default values, that `with*` copies every other field, and
`origin()`'s composition. `test/types_test.bp` asserts `Params` lookup including absence and
duplicate keys, and that `LayoutProps` accepts a real `Element`.

The `renderDocument` assertions live with the examples rather than in `test/`, because they need
`emilia` and `jhonstart` as dependencies and `test/` in this front is deliberately dependency-free —
a failure in `test/config_test.bp` is then unambiguously onze13's, not a sibling's.

## Definition of done

- [ ] `repository/onze13/` exists with `botopink.json`, `src/root.bp`, `src/config.bp`,
      `src/types.bp`, `src/integration.bp` (render half), `AGENTS.md`, `README.md`, `docs.md`
- [ ] `.github/workflows/test.yml` runs `botopink test --target commonJS` and `--target erlang`
- [ ] `onze13` appears as a cell in `zig build test-libs` on both targets
- [ ] The four seams are documented in `docs.md` with the same precision as the *Mechanism* section
      here, because fronts 22, 23, 48, 50, 53, 68 and 69 all read them
- [ ] `docs.md` states the OTP version onze13 requires, as the replacement for Next's
      "Node.js >= 20.9" system requirement (`NEXTJS-DOCS.md § 2`)
- [ ] The front's tests are green on its assigned target — both, here
