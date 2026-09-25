# onze — snapshot-test map of the modules

The preventive map: for each front, the `.bp` tests its module ships and the exact `.snap` file each
one writes. Contract: [`../01-std/snapshots.md`](../01-std/snapshots.md) and
[`../01-std/src-builtin.md`](../01-std/src-builtin.md).

- `type SourceLocation(file: string, line: i32, column: i32, fnName: string)`; `@src()` is comptime.
- `snapshots.path(loc)` = `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap`; `suite` = text before
  the first `": "` of the test name; `slug` = the rest, lower-cased, every run outside `[a-z0-9]`
  → `-`, ends trimmed.
- Mismatch or missing file: `<path>.new` is written and the test fails. No update flag.
- Every helper is `assert<Subject>(loc: SourceLocation, …) -> @Result<void, string>` from
  `"onze-test"`; a test calls it with `try`.

## Fixture conventions

`fixtureTree(text)` takes a multi-line string where a line `== <path>` opens a file; every following
line until the next `==` is that file's content. `tmpProject(fixture)` materialises it under
`.botopinkbuild/tmp/<hex>/` and removes it after the test. The helpers that take a `tree` take that
text directly.

The **frozen fixture app** used across fronts 50, 68, 69 and 71 (its hashes are literals in the
snapshots; the fixture is frozen so the literals are stable):

```
== botopink.json
{ "name": "fixture", "alias": { "@/components": "components", "@/lib": "lib" } }
== onze.json
{ "name": "fixture", "port": 3000 }
== app/layout.bp
#[layout("")] #[@use] pub fn rootLayout(props: LayoutProps) -> @Component<Element> { … siteNav() … }
== app/page.bp
#[page("")] #[@use] pub fn home(route: PageContext) -> @Component<Element> { … }
== app/blog/[slug]/page.bp
#[page("blog/[slug]")] #[@use] pub fn post(route: PageContext) -> @Component<Element> { … LikeButton … }
== app/blog/[slug]/loading.bp
pub fn Loading() -> Element { … }
== app/globals.css
body { margin: 0; }
== app/blog/blog.module.css
.container { padding: 24px; }
.title { font-size: 2rem; }
== components/nav.bp
#[client] pub fn Nav(props: NavProps) -> Element { … }            (imports lib.format)
== components/like_button.bp
#[client] pub fn LikeButton(props: LikeProps) -> Element { … }    (imports lib.format; reads ONZE_PUBLIC_API_URL)
== lib/format.bp
pub fn plural(n: i32, word: string) -> string { … }
== lib/db.bp
import { serverOnly } from "jhonstart";  pub fn listPosts() -> Post[] { … }
== public/favicon.ico
```

Pinned literals: build id `b7f2a1`; `shared.41ab08.js`; `entry.9c1d40.js`; `r2.7e0055.js` (the
`/blog/[slug]` chunk); `app.2b91cc.css`; module hashes `4f21ab` (`blog.module.css`), `d0e1f2`
(`globals.css`); emilia classes `e_3f9a1c` (page), `e_77b0d4` (nav), `e_c5e2a0` (like button),
`e_19ee42` (loading).

## Helper signatures (`modules/onze-test/src/`)

```bp
pub type SourceLocation(file: string, line: i32, column: i32, fnName: string)

// core — 49
pub fn assertConfig(loc: SourceLocation, botopinkJson: string, onzeJson: string) -> @Result<void, string>
pub fn assertAppFiles(loc: SourceLocation, paths: string[]) -> @Result<void, string>
pub fn assertAlias(loc: SourceLocation, aliasJson: string, specs: string[]) -> @Result<void, string>
pub fn assertPublicEnv(loc: SourceLocation, env: Array<#(string, string)>, names: string[]) -> @Result<void, string>

// cli — 50
pub fn assertScan(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertGeneratedTree(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertTreeCheck(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertScaffold(loc: SourceLocation, args: string) -> @Result<void, string>
pub fn assertBuildOutput(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertDevServer(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertInfo(loc: SourceLocation, cwd: string) -> @Result<void, string>

// bundler — 68
pub fn assertGraph(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertRefusal(loc: SourceLocation, tree: string, config: string) -> @Result<void, string>
pub fn assertChunks(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertManifest(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertScriptTags(loc: SourceLocation, tree: string, route: string) -> @Result<void, string>
pub fn assertEntry(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertScriptPlan(loc: SourceLocation, decls: ScriptDecl[]) -> @Result<void, string>

// assets — 69 · 51 · 52
pub fn assertHead(loc: SourceLocation, links: Array<#(string, string)>, render: fn() -> Element) -> @Result<void, string>
pub fn assertStyleModule(loc: SourceLocation, path: string, css: string) -> @Result<void, string>
pub fn assertStylesheet(loc: SourceLocation, globalCss: string, modules: Array<#(string, string)>) -> @Result<void, string>
pub fn assertStaticRoots(loc: SourceLocation, publicDir: string, outDir: string, buildId: string) -> @Result<void, string>
pub fn assertImage(loc: SourceLocation, props: ImageProps, cfg: ImageConfig) -> @Result<void, string>
pub fn assertImageSource(loc: SourceLocation, cfg: ImageConfig, srcs: string[]) -> @Result<void, string>
pub fn assertImageHandler(loc: SourceLocation, cfg: ImageConfig, queries: string[]) -> @Result<void, string>
pub fn assertFontCss(loc: SourceLocation, family: string, opts: GoogleFontOptions) -> @Result<void, string>
pub fn assertFontHead(loc: SourceLocation, fonts: Font[]) -> @Result<void, string>
pub fn assertFontRefusals(loc: SourceLocation, cases: Array<#(string, GoogleFontOptions)>) -> @Result<void, string>

// og — 70
pub fn assertStyleParse(loc: SourceLocation, style: string) -> @Result<void, string>
pub fn assertLayout(loc: SourceLocation, tree: Element, size: ImageSize) -> @Result<void, string>
pub fn assertSvg(loc: SourceLocation, tree: Element, size: ImageSize, fonts: FontRef[]) -> @Result<void, string>
pub fn assertRasterizer(loc: SourceLocation, contentType: string, r: Rasterizer) -> @Result<void, string>

// release — 71
pub fn assertBuildId(loc: SourceLocation, moduleHashes: string[], manifestHash: string) -> @Result<void, string>
pub fn assertReleaseText(loc: SourceLocation, spec: ReleaseSpec) -> @Result<void, string>
pub fn assertDockerfile(loc: SourceLocation, spec: ReleaseSpec) -> @Result<void, string>
pub fn assertReleaseTree(loc: SourceLocation, tree: string) -> @Result<void, string>
pub fn assertShutdown(loc: SourceLocation, drainTimeoutMs: i32) -> @Result<void, string>
pub fn assertStaticExport(loc: SourceLocation, tree: string) -> @Result<void, string>
```

Every helper renders its subject to one canonical text (the tables and trees below), compares it
with the `.snap`, and on mismatch writes `<path>.new` and returns `Err("<path> differs; wrote <path>.new")`.
Refusal helpers render the **error list**; an empty list renders `(no refusals)`.

---

## 49 — stand-up · `modules/onze/test/`

### `config_test.bp`

```bp
import {assertConfig, assertAlias, assertPublicEnv} from "onze-test";

test "config: defaults ---- every field onze.json may omit" {
    try assertConfig(@src(),
        \\ { "name": "fixture" }
    ,
        \\ {}
    );
}
```

`modules/onze/test/__snapshots__/config/defaults-every-field-onze-json-may-omit.snap`

```
name      = fixture
port      = 3000
basePath  =
appDir    = app
publicDir = public
outDir    = .onze
dev       = false
origin    = http://localhost:3000
```

```bp
test "config: override ---- port from onze.json and basePath through" {
    try assertConfig(@src(),
        \\ { "name": "docs" }
    ,
        \\ { "port": 4000, "basePath": "/docs", "appDir": "src/app" }
    );
}
```

`modules/onze/test/__snapshots__/config/override-port-from-onze-json-and-basepath-through.snap`

```
name      = docs
port      = 4000
basePath  = /docs
appDir    = src/app
publicDir = public
outDir    = .onze
dev       = false
origin    = http://localhost:4000
```

```bp
test "alias: longest prefix ---- @/lib and @/lib/db" {
    try assertAlias(@src(),
        \\ { "@/components": "components", "@/lib": "lib", "@/lib/db": "lib/store" }
    , [
        "@/components.post_card",
        "@/lib.actions",
        "@/lib/db.posts",
        "jhonstart",
    ]);
}
```

`modules/onze/test/__snapshots__/alias/longest-prefix-lib-and-lib-db.snap`

```
@/components.post_card  ->  components.post_card
@/lib.actions           ->  lib.actions
@/lib/db.posts          ->  lib/store.posts
jhonstart               ->  jhonstart
```

```bp
test "alias: escape ---- a target outside the root is refused at load" {
    try assertAlias(@src(),
        \\ { "@/up": "..", "@/ok": "lib" }
    , ["@/ok.x"]);
}
```

`modules/onze/test/__snapshots__/alias/escape-a-target-outside-the-root-is-refused-at-load.snap`

```
error: alias "@/up" -> ".." escapes the package root
```

```bp
test "env: public prefix ---- case-sensitive filter" {
    val env = [
        #("ONZE_PUBLIC_API_URL", "https://api.example.com"),
        #("onze_public_x", "leak"),
        #("Onze_Public_Secret", "leak"),
        #("DATABASE_URL", "postgres://…"),
    ];
    try assertPublicEnv(@src(), env, [
        "ONZE_PUBLIC_API_URL", "onze_public_x", "Onze_Public_Secret", "DATABASE_URL", "ONZE_PUBLIC_MISSING",
    ]);
}
```

`modules/onze/test/__snapshots__/env/public-prefix-case-sensitive-filter.snap`

```
prefix = ONZE_PUBLIC_
ONZE_PUBLIC_API_URL   public   https://api.example.com
onze_public_x         dropped
Onze_Public_Secret    dropped
DATABASE_URL          dropped
ONZE_PUBLIC_MISSING   public   (unset)
```

### `types_test.bp`

```bp
import {assertAppFiles} from "onze-test";

test "types: app files ---- every routing convention and the group" {
    try assertAppFiles(@src(), [
        "app/page.bp",
        "app/layout.bp",
        "app/template.bp",
        "app/default.bp",
        "app/loading.bp",
        "app/error.bp",
        "app/not-found.bp",
        "app/blog/[slug]/page.bp",
        "app/(marketing)/about/page.bp",
        "app/api/posts/route.bp",
        "app/docs/[...rest]/page.bp",
        "app/_components/card.bp",
    ]);
}
```

`modules/onze/test/__snapshots__/types/app-files-every-routing-convention-and-the-group.snap`

```
authoredPath                      segment              kind
app/page.bp                                            page
app/layout.bp                                          layout
app/template.bp                                        template
app/default.bp                                         default
app/loading.bp                                         loading
app/error.bp                                           error
app/not-found.bp                                       not-found
app/blog/[slug]/page.bp           blog/[slug]          page
app/(marketing)/about/page.bp     (marketing)/about    page
app/api/posts/route.bp            api/posts            route
app/docs/[...rest]/page.bp        docs/[...rest]       page
app/_components/card.bp           -                    (not an app file)
```

---

## 50 — cli · `modules/onze-cli/test/`

### `scan_test.bp`

```bp
import {assertScan} from "onze-test";

test "scan: route table ---- the staging table, every row" {
    try assertScan(@src(),
        \\ == app/page.bp
        \\ #[page("")]
        \\ == app/blog/[slug]/page.bp
        \\ #[page("blog/[slug]")]
        \\ == app/docs/[...rest]/page.bp
        \\ #[page("docs/[...rest]")]
        \\ == app/shop/[[...rest]]/page.bp
        \\ #[page("shop/[[...rest]]")]
        \\ == app/(marketing)/about/page.bp
        \\ #[page("(marketing)/about")]
        \\ == app/dashboard/@analytics/page.bp
        \\ #[page("dashboard/@analytics")]
        \\ == app/_components/card.bp
        \\ pub fn card() -> Element { … }
        \\ == app/api/posts/route.bp
        \\ #[getRoute("api/posts")]
    );
}
```

`modules/onze-cli/test/__snapshots__/scan/route-table-the-staging-table-every-row.snap`

```
pattern                 kind    authoredPath                          modulePath                       declared
/                       page    app/page.bp                           app.page                         (empty)
/about                  page    app/(marketing)/about/page.bp         app.g_marketing.about.page       (marketing)/about
/api/posts              route   app/api/posts/route.bp                app.api.posts.route              api/posts
/blog/:slug             page    app/blog/[slug]/page.bp               app.blog.d_slug.page             blog/[slug]
/dashboard/@analytics   page    app/dashboard/@analytics/page.bp      app.dashboard.s_analytics.page   dashboard/@analytics
/docs/*rest             page    app/docs/[...rest]/page.bp            app.docs.c_rest.page             docs/[...rest]
/shop/*rest?            page    app/shop/[[...rest]]/page.bp          app.shop.o_rest.page             shop/[[...rest]]
skipped: app/_components/card.bp
```

```bp
test "scan: conflict ---- page.bp and route.bp in one segment" {
    try assertScan(@src(),
        \\ == app/posts/page.bp
        \\ #[page("posts")]
        \\ == app/posts/route.bp
        \\ #[getRoute("posts")]
    );
}
```

`modules/onze-cli/test/__snapshots__/scan/conflict-page-bp-and-route-bp-in-one-segment.snap`

```
error: app/posts holds both page.bp and route.bp — a segment is a page or a handler, not both
```

```bp
test "scan: staging collision ---- [slug] beside a literal d_slug" {
    try assertScan(@src(),
        \\ == app/blog/[slug]/page.bp
        \\ #[page("blog/[slug]")]
        \\ == app/blog/d_slug/page.bp
        \\ #[page("blog/d_slug")]
    );
}
```

`modules/onze-cli/test/__snapshots__/scan/staging-collision-slug-beside-a-literal-d-slug.snap`

```
error: app/blog/[slug] and app/blog/d_slug both stage to app/blog/d_slug
```

### `generate_test.bp`

```bp
import {assertGeneratedTree, assertTreeCheck} from "onze-test";

test "generate: app tree ---- sorted pub mod lines with the banner" {
    try assertGeneratedTree(@src(),
        \\ == app/page.bp
        \\ #[page("")]
        \\ == app/layout.bp
        \\ #[layout("")]
        \\ == app/blog/[slug]/page.bp
        \\ #[page("blog/[slug]")]
        \\ == app/blog/[slug]/loading.bp
        \\ pub fn Loading() -> Element { … }
        \\ == app/(marketing)/about/page.bp
        \\ #[page("(marketing)/about")]
    );
}
```

`modules/onze-cli/test/__snapshots__/generate/app-tree-sorted-pub-mod-lines-with-the-banner.snap`

```
== .onze/app_tree.bp
// GENERATED by onze build — do not edit.
pub mod app;
== .onze/app/root.bp
// GENERATED by onze build — do not edit.
pub mod blog;
pub mod g_marketing;
pub mod layout;
pub mod page;
== .onze/app/blog/root.bp
// GENERATED by onze build — do not edit.
pub mod d_slug;
== .onze/app/blog/d_slug/root.bp
// GENERATED by onze build — do not edit.
pub mod loading;
pub mod page;
== .onze/app/g_marketing/root.bp
// GENERATED by onze build — do not edit.
pub mod about;
== .onze/app/g_marketing/about/root.bp
// GENERATED by onze build — do not edit.
pub mod page;
```

```bp
test "generate: check ---- decorator argument disagrees with the directory" {
    try assertTreeCheck(@src(),
        \\ == app/blog/[slug]/page.bp
        \\ #[page("posts/[slug]")]
        \\ == app/about/page.bp
        \\ #[@use] pub fn about(route: PageContext) -> @Component<Element> { … }
        \\ == app/page.bp
        \\ #[page("")]
    );
}
```

`modules/onze-cli/test/__snapshots__/generate/check-decorator-argument-disagrees-with-the-directory.snap`

```
error: app/blog/[slug]/page.bp is at segment "blog/[slug]" but declares #[page("posts/[slug]")]
error: app/about/page.bp is a page file and carries no #[page("about")]
```

### `create_test.bp`

```bp
import {assertScaffold} from "onze-test";

test "create: scaffold ---- --yes writes the minimal tree" {
    try assertScaffold(@src(), "my-app --yes");
}
```

`modules/onze-cli/test/__snapshots__/create/scaffold-yes-writes-the-minimal-tree.snap`

```
my-app/
  botopink.json
  onze.json
  app/
    layout.bp
    page.bp
  public/
    favicon.ico
== my-app/onze.json
{
  "name": "my-app",
  "port": 3000,
  "basePath": "",
  "appDir": "app",
  "publicDir": "public",
  "outDir": ".onze"
}
== my-app/botopink.json (alias)
{ "@/components": "components", "@/lib": "lib" }
== my-app/botopink.json (dependencies)
onze, jhonstart, rakun, emilia, std
== botopink check
ok
```

```bp
test "create: flags ---- --src-dir and --import-alias ~/" {
    try assertScaffold(@src(), "my-app --yes --src-dir --import-alias ~/ --port 4000");
}
```

`modules/onze-cli/test/__snapshots__/create/flags-src-dir-and-import-alias.snap`

```
my-app/
  botopink.json
  onze.json
  src/
    app/
      layout.bp
      page.bp
  public/
    favicon.ico
== my-app/onze.json
{
  "name": "my-app",
  "port": 4000,
  "basePath": "",
  "appDir": "src/app",
  "publicDir": "public",
  "outDir": ".onze"
}
== my-app/botopink.json (alias)
{ "~/components": "src/components", "~/lib": "src/lib" }
== my-app/botopink.json (dependencies)
onze, jhonstart, rakun, emilia, std
== botopink check
ok
```

```bp
test "create: refuse ---- a non-empty target directory" {
    try assertScaffold(@src(), "existing --yes");
}
```

`modules/onze-cli/test/__snapshots__/create/refuse-a-non-empty-target-directory.snap`

```
error: existing/ is not empty; --yes takes the defaults, it does not overwrite files
exit 1
```

### `build_test.bp` (fixture app, commonJS; the artifacts themselves are served by `examples/blog`)

```bp
import {assertBuildOutput, assertDevServer, assertInfo} from "onze-test";
import {fixtureApp} from "onze-test";

test "build: output tree ---- the five entries and the build id" {
    try assertBuildOutput(@src(), fixtureApp());
}
```

`modules/onze-cli/test/__snapshots__/build/output-tree-the-five-entries-and-the-build-id.snap`

```
.onze/
  app_tree.bp
  app/
    root.bp
    blog/
      root.bp
      d_slug/
        root.bp
        loading.bp
        page.bp
    layout.bp
    page.bp
  build-id
  client/
    entry.bp
  client-manifest.txt
  prerender/
    index.html
    manifest.txt
  server/
    app.beam
    app.blog.d_slug.loading.beam
    app.blog.d_slug.page.beam
    app.layout.beam
    app.page.beam
    lib.db.beam
    lib.format.beam
  static/
    b7f2a1/
      app.2b91cc.css
      entry.9c1d40.js
      r2.7e0055.js
      shared.41ab08.js
  styles/
    app_blog_blog.bp
== .onze/build-id
b7f2a1
== second build
build-id unchanged: b7f2a1
```

```bp
test "dev: route table ---- what onze dev prints on boot" {
    try assertDevServer(@src(), fixtureApp());
}
```

`modules/onze-cli/test/__snapshots__/dev/route-table-what-onze-dev-prints-on-boot.snap`

```
onze dev
  http://localhost:3000
  /               page    app/page.bp
  /blog/:slug     page    app/blog/[slug]/page.bp   (loading)
watching app/, components/, lib/ every 250 ms
```

```bp
test "info: outside a project ---- versions and project (none)" {
    try assertInfo(@src(), "/");
}
```

`modules/onze-cli/test/__snapshots__/info/outside-a-project-versions-and-project-none.snap`

```
onze          1.0.10-beta
botopink      1.0.10-beta
OTP/erts      28.0 / 16.0
jhonstart     (not found)
rakun         (not found)
emilia        (not found)
project       (none)
```

---

## 68 — client bundle · `modules/onze-bundler/test/`

### `graph_test.bp`

```bp
import {assertGraph} from "onze-test";
import {fixtureApp} from "onze-test";

test "graph: roots ---- one client island below a server page" {
    try assertGraph(@src(),
        \\ == app/page.bp
        \\ import { Card } from "@/components.card";
        \\ #[page("")] #[@use] pub fn home(route: PageContext) -> @Component<Element> { … }
        \\ == components/card.bp
        \\ #[client]
        \\ import { plural } from "@/lib.format";
        \\ pub fn Card(props: CardProps) -> Element { … }
        \\ == lib/format.bp
        \\ pub fn plural(n: i32, word: string) -> string { … }
        \\ == lib/db.bp
        \\ pub fn listPosts() -> Post[] { … }
    );
}
```

`modules/onze-bundler/test/__snapshots__/graph/roots-one-client-island-below-a-server-page.snap`

```
roots: components.card
components.card   root   chain: components.card
lib.format        -      chain: components.card > lib.format
not in graph: app.page, lib.db
```

```bp
test "graph: shared ---- a module reached by two roots appears once" {
    try assertGraph(@src(), fixtureApp());
}
```

`modules/onze-bundler/test/__snapshots__/graph/shared-a-module-reached-by-two-roots-appears-once.snap`

```
roots: components.nav, components.like_button
components.nav           root   chain: components.nav
lib.format               -      chain: components.nav > lib.format
components.like_button   root   chain: components.like_button
not in graph: app.layout, app.page, app.blog.d_slug.page, app.blog.d_slug.loading, lib.db
```

```bp
test "graph: cycle ---- terminates and lists each module once" {
    try assertGraph(@src(),
        \\ == app/page.bp
        \\ import { A } from "@/components.a";
        \\ #[page("")] #[@use] pub fn home(route: PageContext) -> @Component<Element> { … }
        \\ == components/a.bp
        \\ #[client]
        \\ import { b } from "@/components.b";
        \\ pub fn A(props: P) -> Element { … }
        \\ == components/b.bp
        \\ import { A } from "@/components.a";
        \\ pub fn b() -> i32 { return 1; }
    );
}
```

`modules/onze-bundler/test/__snapshots__/graph/cycle-terminates-and-lists-each-module-once.snap`

```
roots: components.a
components.a   root   chain: components.a
components.b   -      chain: components.a > components.b
not in graph: app.page
```

### `refusal_test.bp`

```bp
import {assertRefusal} from "onze-test";
import {fixtureApp} from "onze-test";

val plainConfig = "{}";

test "refusal: server-only ---- the chain from the root" {
    try assertRefusal(@src(),
        \\ == app/page.bp
        \\ import { Status } from "@/components.status";
        \\ #[page("")] #[@use] pub fn home(route: PageContext) -> @Component<Element> { … }
        \\ == components/status.bp
        \\ #[client]
        \\ import { fmt } from "@/lib.format";
        \\ pub fn Status(props: P) -> Element { … }
        \\ == lib/format.bp
        \\ import { listPosts } from "@/lib.db";
        \\ pub fn fmt() -> string { … }
        \\ == lib/db.bp
        \\ import { serverOnly } from "jhonstart";
        \\ pub fn listPosts() -> Post[] { … }
    , plainConfig);
}
```

`modules/onze-bundler/test/__snapshots__/refusal/server-only-the-chain-from-the-root.snap`

```
refused: server-only module lib.db reached from client root components.status
  components.status > lib.format > lib.db
build failed: 1 refusal
```

```bp
test "refusal: env ---- every row of the environment table" {
    try assertRefusal(@src(),
        \\ == app/page.bp
        \\ import { Widget } from "@/components.widget";
        \\ #[page("")] #[@use] pub fn home(route: PageContext) -> @Component<Element> { … }
        \\ == components/widget.bp
        \\ #[client]
        \\ import { io.env } from "std";
        \\ val a = env.read("ONZE_PUBLIC_API_URL");
        \\ val b = env.read("DATABASE_URL");
        \\ val c = env.read("onze_public_x");
        \\ val d = env.read(someName());
        \\ val e = env.vars();
        \\ val f = env.write("X", "1");
        \\ val g = env.clear();
        \\ pub fn Widget(props: P) -> Element { … }
    , plainConfig);
}
```

`modules/onze-bundler/test/__snapshots__/refusal/env-every-row-of-the-environment-table.snap`

```
inlined: ONZE_PUBLIC_API_URL (components.widget)
refused: env-non-public   DATABASE_URL     components.widget   components.widget
refused: env-non-public   onze_public_x    components.widget   components.widget
refused: env-dynamic      (expression)     components.widget   components.widget
refused: env-vars         env.vars()       components.widget   components.widget
refused: env-write        env.write        components.widget   components.widget
refused: env-write        env.clear        components.widget   components.widget
build failed: 6 refusals
```

```bp
test "refusal: adversarial config ---- no setting relaxes anything" {
    try assertRefusal(@src(),
        \\ == app/page.bp
        \\ import { Widget } from "@/components.widget";
        \\ #[page("")] #[@use] pub fn home(route: PageContext) -> @Component<Element> { … }
        \\ == components/widget.bp
        \\ #[client]
        \\ import { io.env } from "std";
        \\ val b = env.read("DATABASE_URL");
        \\ pub fn Widget(props: P) -> Element { … }
    ,
        \\ { "dev": true, "allowEnv": ["DATABASE_URL"], "publicEnvPrefix": "", "strict": false,
        \\   "bundler": { "warnOnly": true, "ignoreServerOnly": true } }
    );
}
```

`modules/onze-bundler/test/__snapshots__/refusal/adversarial-config-no-setting-relaxes-anything.snap`

```
ignored config keys: allowEnv, publicEnvPrefix, strict, bundler
refused: env-non-public   DATABASE_URL     components.widget   components.widget
build failed: 1 refusal
```

```bp
test "refusal: emilia ---- non-literal tokens, a client flush, a hash split" {
    try assertRefusal(@src(),
        \\ == app/page.bp
        \\ import { Badge } from "@/components.badge";
        \\ #[page("")] #[@use] pub fn home(route: PageContext) -> @Component<Element> { … }
        \\ == components/badge.bp
        \\ #[client]
        \\ import { emilia, flush, Token } from "emilia";
        \\ val ok = emilia([.Text.Size.Sm, .Color.Gray.700]);
        \\ pub fn Badge(props: P) -> Element {
        \\     val cls = emilia(props.tokens);
        \\     val sheet = await flush();
        \\     return span([text("x", attrs: [])], attrs: [#("class", cls)]);
        \\ }
    , plainConfig);
}
```

`modules/onze-bundler/test/__snapshots__/refusal/emilia-non-literal-tokens-a-client-flush-a-hash-split.snap`

```
styleMap: components.badge#1 -> e_c5e2a0
refused: emilia-non-literal   components.badge:9    emilia(props.tokens)
refused: emilia-flush         components.badge:10   flush() in a client module
build failed: 2 refusals
```

### `chunk_test.bp`

```bp
import {assertChunks} from "onze-test";
import {fixtureApp} from "onze-test";

test "chunks: plan ---- shared, one route chunk, entry" {
    try assertChunks(@src(), fixtureApp());
}
```

`modules/onze-bundler/test/__snapshots__/chunks/plan-shared-one-route-chunk-entry.snap`

```
shared               shared.41ab08.js    components.nav, lib.format, jhonstart.client_runtime
route:/blog/[slug]   r2.7e0055.js        components.like_button
entry                entry.9c1d40.js     .onze/client/entry.bp
routes: / -> (none) ; /blog/[slug] -> route:/blog/[slug]
prelude: __onze_require over 4 factories
== rebuild after editing lib/format.bp
changed: shared.41ab08.js -> shared.b03c19.js
unchanged: r2.7e0055.js, entry.9c1d40.js
```

### `manifest_test.bp` (both targets — the same literal on `commonJS` and on `erlang`)

```bp
import {assertManifest, assertScriptTags} from "onze-test";
import {fixtureApp} from "onze-test";

test "manifest: text ---- one client island" {
    try assertManifest(@src(),
        \\ == app/page.bp
        \\ import { LikeButton } from "@/components.like_button";
        \\ #[page("")] #[@use] pub fn home(route: PageContext) -> @Component<Element> { … }
        \\ == components/like_button.bp
        \\ #[client]
        \\ import { io.env } from "std";
        \\ val api = env.read("ONZE_PUBLIC_API_URL").unwrapOr("");
        \\ pub fn LikeButton(props: LikeProps) -> Element { … }
    );
}
```

`modules/onze-bundler/test/__snapshots__/manifest/text-one-client-island.snap`

```
V|1|b7f2a1
E|entry|/_onze/static/b7f2a1/entry.9c1d40.js|9c1d40|2480
S|shared|/_onze/static/b7f2a1/shared.41ab08.js|41ab08|18320
C|route:/|/_onze/static/b7f2a1/r1.7e0055.js|7e0055|5120
R|/|route:/
P|ONZE_PUBLIC_API_URL|https%3A%2F%2Fapi.example.com
```

```bp
test "manifest: round trip ---- both targets, same literal, pipe escaped" {
    try assertManifest(@src(), fixtureApp());
}
```

`modules/onze-bundler/test/__snapshots__/manifest/round-trip-both-targets-same-literal-pipe-escaped.snap`

```
V|1|b7f2a1
E|entry|/_onze/static/b7f2a1/entry.9c1d40.js|9c1d40|2480
S|shared|/_onze/static/b7f2a1/shared.41ab08.js|41ab08|18320
C|route:/blog/[slug]|/_onze/static/b7f2a1/r2.7e0055.js|7e0055|5120
R|/blog/[slug]|route:/blog/[slug]
Y|styles|/_onze/static/b7f2a1/app.2b91cc.css|2b91cc|940
P|ONZE_PUBLIC_API_URL|https%3A%2F%2Fapi.example.com
P|ONZE_PUBLIC_MOTTO|a%7Cb
== parseManifest(formatManifest(m)) == m
true
== unknown kind "Z|x|y" appended
ignored
== "V|2|b7f2a1"
error: client-manifest version 2 is not supported (this reader understands 1)
```

```bp
test "script tags: order ---- shared, route, entry after the payload" {
    try assertScriptTags(@src(), fixtureApp(), "/blog/[slug]");
}
```

`modules/onze-bundler/test/__snapshots__/script-tags/order-shared-route-entry-after-the-payload.snap`

```
== headScriptTags
(empty)
== scriptTags("/blog/[slug]")
<script src="/_onze/static/b7f2a1/shared.41ab08.js" defer></script>
<script src="/_onze/static/b7f2a1/r2.7e0055.js" defer></script>
<script src="/_onze/static/b7f2a1/entry.9c1d40.js" defer></script>
== scriptTags("/")
<script src="/_onze/static/b7f2a1/shared.41ab08.js" defer></script>
<script src="/_onze/static/b7f2a1/entry.9c1d40.js" defer></script>
== contains "window.__bp"
false
```

### `entry_test.bp`

```bp
import {assertEntry, assertScriptPlan} from "onze-test";
import {fixtureApp} from "onze-test";
import {ScriptDecl} from "onze-bundler";

test "entry: generated ---- islands, holes, mounts" {
    try assertEntry(@src(), fixtureApp());
}
```

`modules/onze-bundler/test/__snapshots__/entry/generated-islands-holes-mounts.snap`

```
// GENERATED by onze build — do not edit.
import {readPayload, hydrateIsland, registerFill, registerSignal, checkStyles, globals} from "jhonstart";
import {linkMount} from "jhonstart-link";
import {formMount} from "jhonstart-forms";
import {Nav} from "components.nav";
import {LikeButton} from "components.like_button";

pub fn main() {
    val payload = readPayload(globals.payload);
    registerFill(globals.fill, payload.h);
    registerSignal(globals.signal, allowedRedirects: []);
    val islands = payload.i;
    for (islands) { island ->
        val el = document.query("[data-jh-i=\"" + island.id + "\"]");
        val mounted = if (island.component == "Nav") hydrateIsland(el, Nav, island.props)
            else if (island.component == "LikeButton") hydrateIsland(el, LikeButton, island.props)
            else panic("island " + island.id + ": unknown component " + island.component);
        val _ = mounted;
    };
    checkStyles(payload.s);
    linkMount();
    formMount(actionHeader: "X-Bp-Action");
}
== islandAttr(0)
data-jh-i="i0"
== globals.payload · globals.fill
__bp0 · __bp1
== payload i1 with no element
error: island i1 is in the payload and not in the document
== element i2 with no payload entry
error: island i2 is in the document and not in the payload
== hole h1 with no [data-jh-h]
error: hole h1 is in the payload and not in the document
== order
registerFill < first hydrateIsland < linkMount < formMount
```

```bp
test "script: strategies ---- the four placements and two refusals" {
    try assertScriptPlan(@src(), [
        ScriptDecl(id: "analytics", src: "/a.js", strategy: "beforeInteractive", onLoad: ""),
        ScriptDecl(id: "chat", src: "/c.js", strategy: "afterInteractive", onLoad: "chatReady"),
        ScriptDecl(id: "ads", src: "/ads.js", strategy: "lazyOnload", onLoad: ""),
        ScriptDecl(id: "crunch", src: "/w.js", strategy: "worker", onLoad: ""),
        ScriptDecl(id: "bad", src: "/w2.js", strategy: "worker", onLoad: "never"),
        ScriptDecl(id: "odd", src: "/o.js", strategy: "eventually", onLoad: ""),
    ]);
}
```

`modules/onze-bundler/test/__snapshots__/script/strategies-the-four-placements-and-two-refusals.snap`

```
analytics   beforeInteractive   <head>, blocking      chunk script:analytics
chat        afterInteractive    entry, after hydrate  onLoad chatReady
ads         lazyOnload          entry, after load
crunch      worker              chunk worker:crunch, new Worker() in entry
refused: script "bad" — a worker script cannot declare onLoad
refused: script "odd" — unknown strategy "eventually"; expected beforeInteractive, afterInteractive, lazyOnload, worker
```

---

## 69 — styling pipeline · `modules/onze-assets/test/` (erlang)

### `style_module_test.bp`

```bp
import {assertStyleModule} from "onze-test";

test "css module: scoped names ---- blog.module.css" {
    try assertStyleModule(@src(), "app/blog/blog.module.css",
        \\ .container { padding: 24px; }
        \\ .title { font-size: 2rem; }
        \\ .title:hover .container { color: red; }
        \\ .external { color: blue; }
        \\ .container .missing { margin: 0; }
    );
}
```

`modules/onze-assets/test/__snapshots__/css-module/scoped-names-blog-module-css.snap`

```
== hash
4f21ab
== .onze/styles/app_blog_blog.bp
// generated — do not edit
pub val container: string = "blog_container_4f21ab";
pub val external: string = "blog_external_4f21ab";
pub val title: string = "blog_title_4f21ab";
== rewritten css
.blog_container_4f21ab { padding: 24px; }
.blog_title_4f21ab { font-size: 2rem; }
.blog_title_4f21ab:hover .blog_container_4f21ab { color: red; }
.blog_external_4f21ab { color: blue; }
.blog_container_4f21ab .missing { margin: 0; }
== reported
app/blog/blog.module.css: class "missing" is used but not defined; left unscoped
== botopink check .onze/styles/
ok
```

### `stylesheet_test.bp`

```bp
import {assertStylesheet} from "onze-test";

test "stylesheet: cascade ---- global before module CSS, fingerprinted" {
    try assertStylesheet(@src(),
        \\ body { margin: 0; }
    , [
        #("app/blog/blog.module.css", ".container { padding: 24px; }"),
        #("app/ui/card.module.css", ".container { display: flex; }"),
    ]);
}
```

`modules/onze-assets/test/__snapshots__/stylesheet/cascade-global-before-module-css-fingerprinted.snap`

```
== /_onze/static/b7f2a1/app.2b91cc.css
body { margin: 0; }
.blog_container_4f21ab { padding: 24px; }
.card_container_8a10c7 { display: flex; }
== Y records
Y|styles|/_onze/static/b7f2a1/app.2b91cc.css|2b91cc|94
== parseManifest reads back
Y|styles|/_onze/static/b7f2a1/app.2b91cc.css|2b91cc|94
== second build
2b91cc
```

### `assets_test.bp`

```bp
import {assertStaticRoots} from "onze-test";

test "assets: roots ---- the two roots handed to rakun-web front 82" {
    try assertStaticRoots(@src(), "public", ".onze", "b7f2a1");
}
```

`modules/onze-assets/test/__snapshots__/assets/roots-the-two-roots-handed-to-rakun-web-front-82.snap`

```
staticRoots(public, .onze, b7f2a1) = 2
/_onze/static/b7f2a1/**   -> .onze/static/b7f2a1/   immutable=1  cacheSeconds=31536000
/**                       -> public                 immutable=0  cacheSeconds=0
== every config field set adversarially
same 2 rows
```

Resolution, content types, `304` and the traversal refusals are rakun-web front 82's snapshots
(decision 116 rule 6); onze declares the roots and asserts nothing about serving them.

---

## 51 — image · `modules/onze-assets/test/image_test.bp` (both)

```bp
import {assertImage, assertImageSource, assertImageHandler} from "onze-test";
import {ImageProps, ImageConfig, RemotePattern, defaultImageProps, defaultImageConfig, withSizes, withPriority, withFill} from "onze-assets";

test "image: markup ---- lazy card with sizes" {
    val props = withSizes(defaultImageProps("/images/card.jpg", "A card", 640, 480), "(max-width: 768px) 100vw, 50vw");
    try assertImage(@src(), props, defaultImageConfig());
}
```

`modules/onze-assets/test/__snapshots__/image/markup-lazy-card-with-sizes.snap`

```
<img src="/_onze/image?src=%2Fimages%2Fcard.jpg&w=640&q=75&f=webp" alt="A card" width="640" height="480" loading="lazy" decoding="async" sizes="(max-width: 768px) 100vw, 50vw" srcset="/_onze/image?src=%2Fimages%2Fcard.jpg&w=640&q=75&f=webp 640w">
```

```bp
test "image: priority ---- eager hero with the two-candidate srcset" {
    val props = withPriority(defaultImageProps("/images/hero.jpg", "Hero", 1200, 600), true);
    try assertImage(@src(), props, defaultImageConfig());
}
```

`modules/onze-assets/test/__snapshots__/image/priority-eager-hero-with-the-two-candidate-srcset.snap`

```
<img src="/_onze/image?src=%2Fimages%2Fhero.jpg&w=1200&q=75&f=webp" alt="Hero" width="1200" height="600" loading="eager" fetchpriority="high" decoding="async" srcset="/_onze/image?src=%2Fimages%2Fhero.jpg&w=1200&q=75&f=webp 1x, /_onze/image?src=%2Fimages%2Fhero.jpg&w=2048&q=75&f=webp 2x">
```

```bp
test "image: fill ---- the box is reserved by style, not attributes" {
    val props = withFill(defaultImageProps("/images/bg.jpg", "", 0, 0), true);
    try assertImage(@src(), props, defaultImageConfig());
}
```

`modules/onze-assets/test/__snapshots__/image/fill-the-box-is-reserved-by-style-not-attributes.snap`

```
<img src="/_onze/image?src=%2Fimages%2Fbg.jpg&w=3840&q=75&f=webp" alt="" loading="lazy" decoding="async" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover" srcset="/_onze/image?src=%2Fimages%2Fbg.jpg&w=640&q=75&f=webp 640w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=750&q=75&f=webp 750w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=828&q=75&f=webp 828w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=1080&q=75&f=webp 1080w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=1200&q=75&f=webp 1200w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=1920&q=75&f=webp 1920w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=2048&q=75&f=webp 2048w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=3840&q=75&f=webp 3840w" sizes="100vw">
```

```bp
test "image: sources ---- the allowlist matrix" {
    val cdn = RemotePattern(protocol: "https", hostname: "*.example.com", pathPrefix: "/photos/", port: "");
    val cfg = ImageConfig(remotePatterns: [cdn], formats: ["image/webp"], deviceWidths: [640, 1200], encoder: "vips", encoderTimeoutMs: 5000);
    try assertImageSource(@src(), cfg, [
        "/images/hero.jpg",
        "/images/../../etc/passwd",
        "images/hero.jpg",
        "https://cdn.example.com/photos/a.jpg",
        "https://example.com/photos/a.jpg",
        "https://a.b.example.com/photos/a.jpg",
        "http://cdn.example.com/photos/a.jpg",
        "https://cdn.example.com:8443/photos/a.jpg",
        "https://cdn.example.com/private/a.jpg",
        "https://cdn.example.com/photos/../private/a.jpg",
        "data:image/png;base64,AAAA",
        "file:///etc/passwd",
    ]);
}
```

`modules/onze-assets/test/__snapshots__/image/sources-the-allowlist-matrix.snap`

```
/images/hero.jpg                                   ok        local  public/images/hero.jpg
/images/../../etc/passwd                           refused   local path escapes public/
images/hero.jpg                                    refused   relative path
https://cdn.example.com/photos/a.jpg               ok        remote *.example.com
https://example.com/photos/a.jpg                   refused   host example.com not in remotePatterns
https://a.b.example.com/photos/a.jpg               refused   host a.b.example.com not in remotePatterns
http://cdn.example.com/photos/a.jpg                refused   protocol http (pattern is https)
https://cdn.example.com:8443/photos/a.jpg          refused   port 8443 (pattern is default)
https://cdn.example.com/private/a.jpg              refused   path /private/a.jpg outside /photos/
https://cdn.example.com/photos/../private/a.jpg    refused   path /private/a.jpg outside /photos/
data:image/png;base64,AAAA                         refused   scheme data
file:///etc/passwd                                 refused   scheme file
== defaultImageConfig().remotePatterns
[]  -> https://cdn.example.com/photos/a.jpg refused: host cdn.example.com not in remotePatterns
== hostname "*"
error: remotePatterns[0].hostname "*" is not allowed (refused at config load)
```

```bp
test "image: handler ---- cache hit headers and the 400s" {
    try assertImageHandler(@src(), defaultImageConfig(), [
        "src=%2Fimages%2Fhero.jpg&w=1200&q=75&f=webp",
        "src=%2Fimages%2Fhero.jpg&w=1200&q=75&f=webp",
        "src=%2Fimages%2Fhero.jpg&w=999&q=75&f=webp",
        "src=%2Fimages%2Fhero.jpg&w=1200&q=101&f=webp",
        "src=https%3A%2F%2Fcdn.example.com%2Fa.jpg&w=640&q=75&f=webp",
    ]);
}
```

`modules/onze-assets/test/__snapshots__/image/handler-cache-hit-headers-and-the-400s.snap`

```
encoder: /bin/true (test double)
#1  200  image/webp  Cache-Control: public, max-age=31536000, immutable  ETag: "a91e3c"  encoder invocations: 1
#2  200  image/webp  Cache-Control: public, max-age=31536000, immutable  ETag: "a91e3c"  encoder invocations: 1
#3  400  w=999 is not a configured device width
#4  400  q=101 is outside 1..100
#5  400  host cdn.example.com not in remotePatterns
== cache key
hash(src, w, q, f, encoderVersion)
```

---

## 52 — font · `modules/onze-assets/test/font_test.bp` (both)

```bp
import {assertFontCss, assertFontHead, assertFontRefusals} from "onze-test";
import {GoogleFontOptions, googleFont, Font} from "onze-assets";

fn interOpts() -> GoogleFontOptions {
    return GoogleFontOptions(
        weights: ["400", "700"], styles: ["normal"], subsets: ["latin"], display: "swap",
        preload: true, variable: "--font-inter", fallback: ["system-ui", "sans-serif"], adjustFontFallback: true,
    );
}

test "font: google ---- Inter 400 and 700, latin, swap, adjusted" {
    try assertFontCss(@src(), "Inter", interOpts());
}
```

`modules/onze-assets/test/__snapshots__/font/google-inter-400-and-700-latin-swap-adjusted.snap`

```
== family / className / variable
Inter / onze-font-inter / --font-inter
== css
@font-face{font-family:"Inter";font-style:normal;font-weight:400;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}
@font-face{font-family:"Inter";font-style:normal;font-weight:700;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}
@font-face{font-family:"Inter Fallback";src:local("Arial");size-adjust:107.00%;ascent-override:96.88%;descent-override:24.15%;line-gap-override:0.00%}
:root{--font-inter:"Inter","Inter Fallback",system-ui,sans-serif}
.onze-font-inter{font-family:"Inter","Inter Fallback",system-ui,sans-serif}
== style
font-family:"Inter","Inter Fallback",system-ui,sans-serif
== preload
<link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2" crossorigin>
== contains fonts.googleapis.com or fonts.gstatic.com
false
== sidecars
.onze/static/b7f2a1/fonts/inter-400.6e1a90.metrics.txt
.onze/static/b7f2a1/fonts/inter-700.12c4f7.metrics.txt
```

```bp
test "font: head ---- preload before faces, one face per family and weight" {
    val inter = await googleFont("Inter", interOpts());
    val again = await googleFont("Inter", interOpts());
    try assertFontHead(@src(), [inter, again]);
}
```

`modules/onze-assets/test/__snapshots__/font/head-preload-before-faces-one-face-per-family-and-weight.snap`

```
<link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2" crossorigin>
<style>@font-face{font-family:"Inter";font-style:normal;font-weight:400;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}@font-face{font-family:"Inter";font-style:normal;font-weight:700;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}@font-face{font-family:"Inter Fallback";src:local("Arial");size-adjust:107.00%;ascent-override:96.88%;descent-override:24.15%;line-gap-override:0.00%}:root{--font-inter:"Inter","Inter Fallback",system-ui,sans-serif}.onze-font-inter{font-family:"Inter","Inter Fallback",system-ui,sans-serif}</style>
== @font-face count
3
```

```bp
test "font: refusals ---- empty subsets, unknown display, unknown family" {
    val base = interOpts();
    try assertFontRefusals(@src(), [
        #("Inter", GoogleFontOptions(weights: ["400"], styles: ["normal"], subsets: [], display: "swap", preload: false, variable: "", fallback: [], adjustFontFallback: false)),
        #("Inter", GoogleFontOptions(weights: ["400"], styles: ["normal"], subsets: ["latin"], display: "eventually", preload: false, variable: "", fallback: [], adjustFontFallback: false)),
        #("Nonexistent Sans", base),
    ]);
}
```

`modules/onze-assets/test/__snapshots__/font/refusals-empty-subsets-unknown-display-unknown-family.snap`

```
#1 Inter              error: subsets is empty — an unsubsetted font is a 300 kB font
#2 Inter              error: display "eventually" is not one of swap, block, fallback, optional
#3 Nonexistent Sans   error: family "Nonexistent Sans" is not in the metrics table and adjustFontFallback is true
```

---

## 70 — image response · `modules/onze-og/test/` (erlang)

```bp
import {assertStyleParse, assertLayout, assertSvg, assertRasterizer} from "onze-test";
import {Element, div, span, text} from "jhonstart";
import {ImageSize, FontRef, Rasterizer} from "onze-og";

test "og: style ---- supported parse and unsupported report" {
    try assertStyleParse(@src(),
        "display:flex;flexDirection:column;gap:16;padding:48px;background:linear-gradient(90deg,#4f46e5,#7c3aed);fontSize:64px;maxLines:3;boxShadow:0 0 4px #000;transform:rotate(3deg);padding:"
    );
}
```

`modules/onze-og/test/__snapshots__/og/style-supported-parse-and-unsupported-report.snap`

```
display        flex
flexDirection  column
gap            16
padding        48px
background     linear-gradient(90deg,#4f46e5,#7c3aed)
fontSize       64
maxLines       3
unsupported: boxShadow, transform
malformed: "padding:" (empty value)
```

```bp
fn card() -> Element {
    val frame = "display:flex;flexDirection:row;justifyContent:space-between;alignItems:center;width:1200px;height:630px;padding:64px;background:#111827;color:#ffffff";
    return div([
        span([text("Left", attrs: [])], attrs: [#("style", "fontSize:48px;fontFamily:Inter;fontWeight:700")]),
        span([text("Right", attrs: [])], attrs: [#("style", "fontSize:48px;fontFamily:Inter;fontWeight:700")]),
    ], attrs: [#("style", frame)]);
}

test "og: layout ---- row space-between inside 64px padding" {
    try assertLayout(@src(), card(), ImageSize(width: 1200, height: 630));
}
```

`modules/onze-og/test/__snapshots__/og/layout-row-space-between-inside-64px-padding.snap`

```
div    x=0    y=0    w=1200  h=630
  span x=64   y=286  w=100   h=58   lines: Left
  span x=1002 y=286  w=134   h=58   lines: Right
== wrapText("Hydration is a contract, not a hope", 400, Inter/700, 48, 2)
Hydration is a
contract, not a…
== wrapText("Supercalifragilistic", 100, Inter/700, 48, 1)
Supercalifragilistic   (overflows: 1 word wider than the box)
```

```bp
test "og: svg ---- the card, with a hostile title escaped" {
    val inter = FontRef(family: "Inter", weight: 700, path: "public/fonts/inter-700.woff2", metricsPath: "public/fonts/inter-700.metrics.txt");
    val tree = div([
        span([text("<script>alert(1)</script>", attrs: [])], attrs: [#("style", "fontSize:64px;fontFamily:Inter;fontWeight:700;color:#ffffff")]),
    ], attrs: [#("style", "display:flex;width:1200px;height:630px;padding:64px;background:linear-gradient(90deg,#4f46e5,#7c3aed)")]);
    try assertSvg(@src(), tree, ImageSize(width: 1200, height: 630), [inter]);
}
```

`modules/onze-og/test/__snapshots__/og/svg-the-card-with-a-hostile-title-escaped.snap`

```
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630"><defs><linearGradient id="g0" gradientTransform="rotate(0)"><stop offset="0" stop-color="#4f46e5"/><stop offset="1" stop-color="#7c3aed"/></linearGradient></defs><rect x="0" y="0" width="1200" height="630" fill="url(#g0)"/><text x="64" y="125" font-family="Inter" font-weight="700" font-size="64" fill="#ffffff">&lt;script&gt;alert(1)&lt;/script&gt;</text></svg>
== second render identical
true
```

```bp
test "og: rasterizer ---- png with no tool fails at the route, svg needs none" {
    try assertRasterizer(@src(), "image/png", Rasterizer(kind: "none", command: ""));
}
```

`modules/onze-og/test/__snapshots__/og/rasterizer-png-with-no-tool-fails-at-the-route-svg-needs-none.snap`

```
image/svg+xml  kind=none   ok
image/png      kind=none   error: route app/blog/[slug]/opengraph-image.bp declares image/png and no rasterizer is available; install resvg or rsvg-convert, or set contentType to image/svg+xml
image/png      kind=nif    error: rasterizer kind "nif" configured and no NIF is loaded
== fallback to svg under a png content type
none (asserted absent)
```

---

## 71 — release packaging · `modules/onze-release/test/`

```bp
import {assertBuildId, assertReleaseText, assertDockerfile, assertReleaseTree, assertShutdown, assertStaticExport} from "onze-test";
import {ReleaseSpec, releaseSpec, withErts} from "onze-release";
import {fixtureApp} from "onze-test";

test "release: build id ---- derived once, sort-independent, sensitive" {
    try assertBuildId(@src(), ["4f21ab", "7e0055", "9c1d40"], "41ab08");
}
```

`modules/onze-release/test/__snapshots__/release/build-id-derived-once-sort-independent-sensitive.snap`

```
generateBuildId(["4f21ab","7e0055","9c1d40"], "41ab08") = b7f2a1
generateBuildId(["9c1d40","4f21ab","7e0055"], "41ab08") = b7f2a1
generateBuildId(["4f21ab","7e0055","9c1d41"], "41ab08") = 3e8d27
validateBuildId("")          error: build id is empty
validateBuildId("has/slash") error: build id "has/slash" is not [A-Za-z0-9_-]{1,64}
validateBuildId(65 chars)    error: build id is 65 characters; the limit is 64
verifyBuildId(b7f2a1, b7f2a1, b7f2a1) ok
verifyBuildId(b7f2a1, b7f2a1, stale)  error: release and payload build ids disagree (b7f2a1 vs stale)
```

```bp
test "release: text ---- rel, sys.config, vm.args and the boot script" {
    try assertReleaseText(@src(), releaseSpec("blog", "0.1.0", "b7f2a1"));
}
```

`modules/onze-release/test/__snapshots__/release/text-rel-sys-config-vm-args-and-the-boot-script.snap`

```
== releases/b7f2a1/onze.rel
{release, {"blog", "0.1.0"}, {erts, "16.0"},
 [{kernel, "10.3"}, {stdlib, "7.0"}, {sasl, "4.3"}, {rakun, "0.0.1"}, {jhonstart, "0.0.1"}, {emilia, "0.0.1"}, {onze, "0.0.1"}, {blog, "0.1.0"}]}.
== releases/b7f2a1/sys.config
[{blog, [{port, 3000}, {base_path, ""}]}].
== releases/b7f2a1/vm.args
-name blog@127.0.0.1
-setcookie ${RELEASE_COOKIE}
+K true
== bin/onze
#!/bin/sh
set -e
BUILD_ID="$(cat "$(dirname "$0")/../BUILD_ID")"
[ "$BUILD_ID" = "b7f2a1" ] || { echo "build id mismatch: $BUILD_ID != b7f2a1" >&2; exit 1; }
[ -n "$RELEASE_COOKIE" ] || { echo "RELEASE_COOKIE is not set" >&2; exit 1; }
export PORT="${PORT:-3000}"
exec "$(dirname "$0")/../erts-16.0/bin/erl" -boot "$(dirname "$0")/../releases/b7f2a1/start" -config "$(dirname "$0")/../releases/b7f2a1/sys" -args_file "$(dirname "$0")/../releases/b7f2a1/vm.args" -noshell
== sys.config contains a value from env.read
false
```

```bp
test "release: dockerfile ---- two stages, non-root, erts bundled and not" {
    try assertDockerfile(@src(), releaseSpec("blog", "0.1.0", "b7f2a1"));
}
```

`modules/onze-release/test/__snapshots__/release/dockerfile-two-stages-non-root-erts-bundled-and-not.snap`

```
== includeErts: true
FROM erlang:28-alpine AS build
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
== includeErts: false — runner line
FROM erlang:28-alpine AS runner
== .dockerignore
.git
.onze
.botopinkbuild
test/
== runner stage contains COPY . . / onze build / USER root
false / false / false
```

```bp
test "release: tree ---- the standalone layout" {
    try assertReleaseTree(@src(), fixtureApp());
}
```

`modules/onze-release/test/__snapshots__/release/tree-the-standalone-layout.snap`

```
.onze/release/
  BUILD_ID
  bin/
    onze
  erts-16.0/
  lib/
    blog-0.1.0/ebin/
    emilia-0.0.1/ebin/
    jhonstart-0.0.1/ebin/
    onze-0.0.1/ebin/
    rakun-0.0.1/ebin/
  prerender/
    index.html
    manifest.txt
  public/
    favicon.ico
  releases/
    b7f2a1/
      onze.rel
      start.boot
      sys.config
      vm.args
  static/
    b7f2a1/
      app.2b91cc.css
      entry.9c1d40.js
      r2.7e0055.js
      shared.41ab08.js
== BUILD_ID
b7f2a1
== manifest chunks present
4 of 4
== scanForSecrets (DATABASE_URL=postgres://secret@db)
none
== scanForSecrets with the value planted in shared.41ab08.js
error: release refused — value of DATABASE_URL found in static/b7f2a1/shared.41ab08.js
```

```bp
test "release: shutdown ---- the five steps and a clean drain" {
    try assertShutdown(@src(), 5000);
}
```

`modules/onze-release/test/__snapshots__/release/shutdown-the-five-steps-and-a-clean-drain.snap`

```
readinessChecks: route-table, client-manifest, datasource:default
shutdownOrder:
  1 readiness=false
  2 stop-accepting
  3 drain-renders
  4 drain-after-tasks
  5 stop-supervision-tree
drain(5000): renders=0 afterTasks=0 timedOut=false exit=0
drain(1) with 2 renders in flight: renders=2 afterTasks=0 timedOut=true exit=1
```

```bp
test "release: static export ---- three routes out, a dynamic route refused" {
    try assertStaticExport(@src(),
        \\ == app/page.bp
        \\ #[page("")]
        \\ == app/about/page.bp
        \\ #[page("about")]
        \\ == app/docs/page.bp
        \\ #[page("docs")]
        \\ == app/blog/[slug]/page.bp
        \\ #[page("blog/[slug]")]
        \\ (no registerStaticParams)
    );
}
```

`modules/onze-release/test/__snapshots__/release/static-export-three-routes-out-a-dynamic-route-refused.snap`

```
== without app/blog/[slug]
out/
  index.html
  about/index.html
  docs/index.html
  favicon.ico
  _onze/static/b7f2a1/app.2b91cc.css
  _onze/static/b7f2a1/entry.9c1d40.js
  _onze/static/b7f2a1/shared.41ab08.js
no bin/, no releases/
== with app/blog/[slug]
error: static export refused — route /blog/:slug (app/blog/[slug]/page.bp) cannot be prerendered: no static params registered
```

---

## Coverage of the acceptance boxes

| Front | Acceptance boxes | Covered by the tests above | Left to plain `assert` tests (no snapshot value) |
|---|---|---|---|
| 49 | 20 | defaults, copies, `origin`, `AppFile` rows, alias longest-first, alias escape, prefix + case | `botopink build` in the package, `test-libs` cell, `Onze.run` starts a listener (E2E) |
| 50 | 38 | staging table, conflict, collision, banner + sorting, decorator check, scaffold + flags + refusal, build tree + stable id, dev table, info | editing a file re-renders without restart (E2E), `PORT`/`-p` precedence (E2E), SIGTERM forwarding (71's drain) |
| 68 | 45 | roots, shared, cycle, all three refusals + adversarial config, chunk plan + rebuild, manifest round trip/version/unknown kind/pipe, tag order, entry + mismatch errors + mount order, four strategies + refusals | `moduleIdOf` backslash stability, hash parity of emilia rule bodies (numeric, `assert`) |
| 69 | 16 | scoped names + set equality + undefined class, cascade + fingerprint + `Y` round trip, the two static roots + adversarial config (serving is rakun-web 82's) | preprocessor hook (`process.run` doubles, `assert`) |
| 51 | 23 | markup lazy/priority/fill, allowlist matrix, `hostname:"*"`, handler hit/400/refuse, single encoder invocation | prop validation reds (`quality`, `blur` without URL, `fill` + size, `priority` + lazy) — `assert`; timeout kill (`assert`, slow double) |
| 52 | 20 | faces per weight, no Google host, `display`, `subsets`, `variable`, preload, unknown family, four descriptors, identity, head order + dedup | `localFont` copy + escape + missing file (`assert` over a temp dir); probe-absent degradation log |
| 70 | 28 | supported/unsupported/malformed, row/gap/padding/wrap/`maxLines`, header/escape/gradient/attributes/determinism, `requireRasterizer` outcomes + no fallback | metrics sidecar parse, `advanceOf` `.notdef`, 2 % agreement (needs a rasterizer; skipped with reason) |
| 71 | 34 | id determinism/sort/sensitivity/validation/verify, `.rel`/`sys.config`/`vm.args`/boot, Dockerfile properties + `includeErts`, tree + completeness + secret scan, order + drain, export + refusal | `assembleRelease` runs `systools` (skipped without `erl`); the container actually runs as non-root (E2E, `DEPLOY.md`) |
