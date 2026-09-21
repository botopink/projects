# Front 22 — Rakun File Routing

**Track:** B rakun
**Priority:** critical — without a route table there is no route to render, no route to prefetch, and no
place to hang a server action; fronts 23, 24, 25, 27, 60, 61 and 66 all read what this front writes
**Target:** both — boundary. The route table is matched on BEAM and prefetched in the browser, and it
is the same matcher compiled twice
**Wave:** 1
**Depends on:** 01 (the directory walk — `path` is already complete), 05 (`appDir` as a config value)
**Owns:** `repository/rakun/src/file_router.bp`, `repository/rakun/src/file_router.mjs`,
`repository/rakun/src/sidecars/rakun_file_router.erl`, `repository/rakun/test/file_router_test.bp`
**Does not touch:** `repository/rakun/src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` (frozen for the milestone), and the files owned by 23 · 24 · 25
**Reference:** `NEXTJS-DOCS.md § 3. Estrutura do Projeto`, `§ 4. App Router — Fundamentos`,
`§ 6. Rotas Dinâmicas`, `§ 21. Rotas Paralelas e Interceptadas` ·
<https://nextjs.org/docs/app/getting-started/project-structure> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/dynamic-routes> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/route-groups> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/parallel-routes>
**Replaces:** `1.0.7-beta/14-rakun-file-routing`

---

## Problem

`rakun` routes by decorator today: `#[restController]` marks a type, `#[route("/api")]` gives it a
prefix, `#[getMapping("/users")]` gives a method a path, and the emitted wiring calls
`rkRegisterRoute(verb, path, handler)` into a host-side registry
(`repository/rakun/src/decorators.bp:217-244`, `src/runtime.bp:76-90`). That model works and this
front does not replace it. What it cannot express is the shape Next.js calls the App Router: a URL
that comes from where a file sits, a layout that wraps every route below it, a segment that captures
part of the path, a folder that groups routes without appearing in the URL, and a folder that renders
into a named slot of its parent layout.

The consequence is not cosmetic. Every other server-render front needs an ordered list of the
segments a URL matched, because layout nesting *is* that list. Front 23 cannot nest layouts without
it, front 25 cannot decide whether `/api/posts` is a page or an endpoint, front 27 cannot decide
whether a `Link` target is worth prefetching, front 60 cannot enumerate what to prerender, and front
61 has no tree to hang `@slot` and `(.)` interception off. There is no such list today, and nothing
produces one.

There is also a mechanical problem the 1.0.7 draft did not see. Its plan was to scan `app/` at
startup with a host cell and load the matched page module by path. botopink compiles only declared
modules (`pub mod` in the package root, `docs.md:34-46`); a `.bp` file is not loadable at runtime, and
`@Decl` carries no source location, so a decorator cannot learn which file it was written in. A
file-convention router in botopink therefore has to be registration-driven, and the file path has to
reach the decorator as an argument. That is what this front builds, and the argument is generated and
checked against the real tree by the CLI (front 50), so a developer still only moves files around.

## Current state

- `repository/rakun/src/decorators.bp:217-244` — the five route-mapping decorators, all method-level,
  all taking a full path string. No file-convention decorator exists.
- `repository/rakun/src/runtime.bp:76-104` — `rkRegisterRoute` / `rkDispatch` / `rkDispatchHttp`. A
  flat `verb + path -> handler` registry; no segment list, no layouts, no params beyond `:name`.
- `repository/rakun/src/http.bp:35-43` — the `Request` behavior. `param`/`query`/`header`/`body` all
  return `string`, `""` when absent.
- `repository/jhonstart/src/router.d.bp:18-28` — `Router`/`useRouter`/`Link` are declaration-only and
  gated; the client half of routing does not exist either (front 26 · 27).
- `libs/std/src/path.bp:24-179` — `split`, `join`, `basename`, `dirname`, `normalize`, `relative`,
  `resolve` all exist today; `path` is a complete posix calculator and this front needs nothing added
  to it. What std does not have is a **directory walk**, which the scan in step 5 needs; front 01
  closes that.
- `repository/rakun/src/file_router.bp` does not exist.

## Mechanism

### What Next.js does

A folder under `app/` is a URL segment; a file in it gives that segment its UI
(`§ 3. Convenções de nomenclatura`). `layout` wraps everything below, `template` is a layout that is
recreated per navigation, `page` makes the route public, `route` makes it an endpoint, `default` fills
a slot that has no match. Four folder spellings are not segments: `(group)` is transparent to the URL,
`@slot` renders into a named prop of the parent layout, `_private` is excluded from routing entirely,
and `[dynamic]` / `[...catchAll]` / `[[...optionalCatchAll]]` capture instead of matching
(`§ 6. Rotas Dinâmicas`).

### How it maps onto botopink

**One decorator per file convention, taking the app-relative directory of the file it sits in.**

| File in `app/` | Decorator | Signature the registry pins |
|---|---|---|
| `layout.bp` | `#[layout(seg)]` | `fn(props: LayoutProps) -> Element` |
| `template.bp` | `#[template(seg)]` | `fn(props: LayoutProps) -> Element` |
| `page.bp` | `#[page(seg)]` | `#[@future] fn(route: PageContext) -> @Future<Element>` |
| `default.bp` | `#[defaultView(seg)]` | `fn(props: LayoutProps) -> Element` |
| `route.bp` | front 25's verb decorators | `#[@future] fn(req: Request) -> @Future<HandlerResponse>` |

`default` is a reserved keyword (`modules/compiler-core/src/lexer.zig:721-767`), so the `default.bp`
marker is spelled `#[defaultView]`. That is the only name in the set that does not match its file.

Each decorator body does three things, in the order rakun's own component markers do them
(`decorators.bp:48-64`): it `@emit`s the registration, it `@emit`s the per-route param accessor, and
then it enforces placement with `decl.fail`. The emitted registration is the rakun idiom exactly —
a module-level `val` calling a host cell, so it runs at module load:

```bp
val __rkPage_blogPostPage = rkAppRegisterPage("blog/[slug]", blogPostPage);
```

The registry lives in the host because botopink has no top-level mutable state — the same reason
rakun's scan registry and router live in `runtime.mjs` (`repository/rakun/src/runtime.bp:1-11`).
This front's registry is separate from `rkRegisterRoute`'s: `src/sidecars/rakun_file_router.erl` is
the BEAM one and is what serves requests, `file_router.mjs` is the browser one and holds only the
table. The sidecar's filename is not cosmetic: `shipErlSidecars` skips any atom matching a module this
build emitted (`libs.zig:596`), and rakun emits `rakun/file_router`, so a sidecar named
`src/file_router.erl` is silently not shipped. Every erlang sidecar in this track is
`src/sidecars/rakun_<name>.erl`.

**Three restrictions shape the decorator bodies, and none of them is negotiable.** A decorator body
cannot call sibling functions — the evaluator emits only the decorator function into the eval script
(`decorators.bp:44-46`), which is why rakun copy-pastes its field-injection block six times. So the
segment parser is inlined in each of the four bodies rather than shared. A `//` comment anywhere in
the body breaks the flattened emit, so every body is comment-free and the prose lives above the
`pub fn`. And nothing optional works in a comptime body — no `.at(i)`, no `?T` — so the bodies use
`split` / `forEach` / `push` / `join` / `indexOf` / `length` only.

**The `appDir` is configuration, not a literal.** `rkProp("onze.appDir")` (front 05) resolves to
`app` or `src/app`; the decorator argument is relative to it, so moving the tree between the two
layouts changes one config line and no source. The host-side scan reads `appDir` to verify that every
registered segment corresponds to a real directory and that every directory holding a convention file
registered something — a check the CLI runs, not the server.

### What crosses the boundary

The route table, and only the route table. It crosses as a line-oriented blob, not as JSON, because
`std/json` is `string -> @Result<string, string>` with no structured walker (`libs/std/src/json.bp:36`)
and this front's parser has to compile to BEAM as well as to the browser:

```
kind|pattern|slot|verb
```

one record per line, `\n`-separated, in registration order. `kind` is one letter:

| Letter | Convention | Registered by |
|---|---|---|
| `L` | `layout.bp` | this front |
| `T` | `template.bp` | this front |
| `P` | `page.bp` | this front |
| `D` | `default.bp` | this front |
| `R` | `route.bp` | front 25 |
| `S` | `loading.bp` | front 30 |
| `E` | `error.bp` | front 31 |
| `N` | `not-found.bp` | front 31 |

`pattern` is the URL pattern with groups and slots removed and the bracket spelling preserved
(`/blog/[slug]`, `/shop/[...slug]`, `/docs/[[...slug]]`). `slot` is `""` for the children slot and the
slot name for an `@slot` entry. `verb` is `""` for UI entries and the HTTP method for an `R` entry.
Neither `|` nor a newline may appear in a segment name, and the scan fails if one does.

The server reads the table from its own registry. The client reads it out of the `"t"` field of front
23's payload and rebuilds it with `parseTable`, which is the same botopink function the server uses.
`matchPath` is likewise one function compiled to both targets. That is what makes this a boundary
front: if the two sides can disagree about which route a URL is, every fix downstream is a guess.

## Steps

### Step 1 — Segment grammar

`parseSegment` classifies one folder name. It is pure, total, and the only place the bracket and
parenthesis spellings are decoded.

```bp
pub type SegmentKind {
    Static,
    Dynamic,
    CatchAll,
    OptionalCatchAll,
    Group,
    Slot,
    Private,
}

pub type Segment(
    kind: SegmentKind,
    name: string,
    raw: string,
)

pub fn parseSegment(raw: string) -> Segment
pub fn parsePath(seg: string) -> Segment[]
pub fn patternOf(segments: Segment[]) -> string
pub fn slotOf(segments: Segment[]) -> string
```

**Acceptance:**
- [ ] `parseSegment("blog")` is `Static`/`blog`; `parseSegment("[slug]")` is `Dynamic`/`slug`.
- [ ] `parseSegment("[...slug]")` is `CatchAll`/`slug`; `parseSegment("[[...slug]]")` is
      `OptionalCatchAll`/`slug`. The optional form is tested against the required form, not only
      against a static one.
- [ ] `parseSegment("(marketing)")` is `Group`/`marketing`; `parseSegment("@team")` is `Slot`/`team`;
      `parseSegment("_components")` is `Private`/`components`.
- [ ] `patternOf(parsePath("(marketing)/about"))` is `/about` — a group contributes no segment.
- [ ] `patternOf(parsePath("dashboard/@team/settings"))` is `/dashboard/settings` and
      `slotOf(...)` is `team`.
- [ ] `parsePath("blog/_drafts/[slug]")` fails with a message naming `_drafts`: a private folder may
      not appear on a registered path at all.
- [ ] A segment name containing `|` or a newline fails with a message naming the segment.

### Step 2 — The four decorators

```bp
pub fn layout(comptime decl: @Decl, seg: string)
pub fn template(comptime decl: @Decl, seg: string)
pub fn page(comptime decl: @Decl, seg: string)
pub fn defaultView(comptime decl: @Decl, seg: string)
```

Each `@emit`s its registration and then enforces placement. Placement checking is limited to what a
`@Decl` handle actually carries for a top-level function — `kind`, `name`, `returnType`, `annotations`
(`libs/std/src/builtins.d.bp:455-477`); there is no parameter list on a `DeclKind.Fn` handle, so the
parameter contract is enforced by the type of the registration cell instead, which is stricter and
needs no reflection:

```bp
pub type PageContext(
    pathname: string,
    pattern: string,
    params: Dict<string, string>,
    query: Dict<string, string>,
    rest: string[],
)

pub type LayoutProps(
    route: PageContext,
    children: Element,
    slots: Dict<string, Element>,
)

#[@External.Erlang("rakun_file_router", "register_page")]
#[@External.Node("./file_router.mjs", "registerPage")]
pub declare fn rkAppRegisterPage(
    seg: string,
    render: fn(route: PageContext) -> @Future<Element>,
) -> i32;
```

`LayoutProps` is one record rather than three parameters because declared parameter defaults are
never applied: a layout that uses no slot would otherwise still have to spell out an empty `slots:`
argument at every call site the registry generates. One uniform arity is the only shape that survives
the gap.

Front 25's `route.bp` handlers register through the same registry, into the same table, as `R`
records. The cell they use is declared here and is generic over the response type — the same trick
`rkRegisterRoute<Req>` uses to stay typed without naming the caller's types
(`repository/rakun/src/runtime.bp:70-81`) — so this front never has to know what a `HandlerResponse`
is and front 25 never has to declare a host cell:

```bp
#[@External.Erlang("rakun_file_router", "register_handler")]
#[@External.Node("./file_router.mjs", "registerHandler")]
pub declare fn rkAppRegisterHandler<Res>(
    verb: string,
    seg: string,
    handle: fn(req: Request) -> Res,
) -> i32;
```

**Acceptance:**
- [ ] `#[page("blog")]` on a `#[@future] fn(route: PageContext) -> @Future<Element>` compiles and
      registers one `P` entry at `/blog`.
- [ ] `#[page("blog")]` on a type fails with `#[page] must annotate a function`.
- [ ] `#[page("blog")]` on a function returning `Element` rather than `@Future<Element>` fails,
      naming the required return type — every page is async so the pipeline has one shape to drive.
- [ ] `#[page()]` and `#[page(1)]` are rejected by the automatic argument check
      (`decorators.bp:13-15`), with no code in this front.
- [ ] `#[layout("")]` registers the root layout at `/`.
- [ ] A decorator body contains no `//` comment and calls no sibling function — checked by the file
      compiling at all, which is the only check that matters here.

### Step 3 — The route table and its wire format

```bp
pub type RouteEntry(
    kind: string,
    pattern: string,
    slot: string,
    verb: string,
)

pub fn parseTable(wire: string) -> RouteEntry[]
pub fn writeTable(entries: RouteEntry[]) -> string

#[@External.Erlang("rakun_file_router", "table")]
#[@External.Node("./file_router.mjs", "table")]
pub declare fn rkAppTable() -> string;
```

**Acceptance:**
- [ ] `parseTable(writeTable(xs))` equals `xs` for a table holding one entry of each of the eight
      kinds — compared field by field, never with `==` on the arrays, which is reference equality
      (`docs.md`, gotcha: `==` on arrays lowers to `===`).
- [ ] `writeTable` emits records in registration order and terminates no line with a trailing `|`.
- [ ] The same assertion runs green on `--target erlang` and on `--target commonJS`. A wire format
      only one target can read is the bug this front exists to prevent.

### Step 4 — The matcher

One function, both targets, one precedence order.

```bp
pub type RouteMatch(
    entry: RouteEntry,
    params: Dict<string, string>,
    rest: string[],
    chain: RouteEntry[],
)

pub fn matchPath(table: RouteEntry[], pathname: string) -> ?RouteMatch
pub fn layoutChain(table: RouteEntry[], pattern: string) -> RouteEntry[]
```

Precedence, applied segment by segment, highest first: static, then dynamic, then catch-all, then
optional catch-all. Groups never consume a URL segment. Slots never consume a URL segment; a slot
entry is matched separately against the same URL by front 61.

**Acceptance:**
- [ ] `/blog/hello` against `/blog/[slug]` binds `slug` to `hello`.
- [ ] `/shop/a/b` against `/shop/[...slug]` binds `slug` to `a/b` and `rest` to `["a", "b"]`.
- [ ] `/docs` matches `/docs/[[...slug]]` with `rest` empty; `/docs/a/b` matches it with
      `rest == ["a", "b"]`. `/shop` does *not* match `/shop/[...slug]`.
- [ ] A table holding both `/blog/new` and `/blog/[slug]` matches `/blog/new` to the static entry.
- [ ] `matchPath` returns `null` for a pattern that has a `L` entry but no `P` or `R` entry — a route
      is public only when a page or a handler claims it (`§ 3. Convenções de nomenclatura`).
- [ ] `layoutChain(table, "/blog/[slug]")` returns the `L` entries for `/`, `/blog`, `/blog/[slug]`
      in root-first order, and skips group segments' patterns because they are not in the pattern.
- [ ] Every assertion above is run twice, once per target, from the same test file.

### Step 5 — Scan-time conflicts

The scan is the CLI-side half (`src/sidecars/rakun_file_router.erl` for the server's own startup
check, `file_router.mjs` for `onze dev`). It reads `appDir` from front 05, walks the tree, and fails loudly rather than
serving something surprising.

**Acceptance:**
- [ ] A segment holding both `page.bp` and `route.bp` fails the scan with a message naming the
      segment directory — `§ 19` states the rule and this is where it is enforced.
- [ ] A directory under `appDir` whose name starts with `_` is skipped, and nothing inside it is
      registered even if it holds a `page.bp`.
- [ ] Two route groups may each own a root layout (`§ 5. Múltiplos Root Layouts`); the scan fails
      when two root layouts' subtrees both match one URL, naming the URL and both groups.
- [ ] A registered segment with no corresponding directory under `appDir` fails the scan, naming the
      segment and the function that registered it. This is the check that keeps the decorator
      argument honest.
- [ ] The scan runs with `appDir` set to `app` and to `src/app` and produces the same table.
- [ ] A `middleware.bp` at the **project root** — beside `botopink.json`, not under `appDir` — is
      discovered by the same scan that discovers `appDir`, with no `pub mod` line naming it, and is
      handed to front 07. The discovery is this front's; what runs in it is front 07's. A project
      with no root `middleware.bp` scans clean and registers nothing, which is the common case and
      therefore the case that must not warn.

### Step 6 — Per-route parameter accessors, emitted at comptime

The `PageProps<'/route'>` equivalent from `§ 5. Props das páginas e layouts`. The decorator already
has the segment string; it walks it for bracket segments and emits one accessor per decorated page,
returning a labelled tuple whose labels come from the variable names (`docs.md:204-211`):

```bp
pub fn blogPostPageParams(route: PageContext) -> #(slug: string) {
    val slug = route.params.lookup("slug").unwrapOr("");
    return #(slug);
}
```

A catch-all emits `val slug = route.rest;` and types the field `string[]`. A route with no dynamic
segment emits `-> #()`.

**Acceptance:**
- [ ] `#[page("blog/[slug]")] pub fn blogPostPage(...)` makes `blogPostPageParams` available in the
      same module, with a `slug: string` field.
- [ ] `#[page("shop/[...slug]")]` emits an accessor whose field is `string[]`.
- [ ] `#[page("about")]` emits an accessor returning `#()`.
- [ ] The test that asserts this runs under `botopink test`, not `botopink check` — `check` skips
      decorator invocation and reports every `@emit`ted name as unbound (a known gotcha, not a bug in
      this front).

## Examples

- [`examples/app-tree-example.bp`](./examples/app-tree-example.bp) — a realistic `app/` tree in the
  header comment, then the `layout.bp` and `page.bp` bodies that populate it: a root layout, a blog
  layout, a home page, a dynamic post page and a route-group page.
- [`examples/route-table-example.bp`](./examples/route-table-example.bp) — the boundary artifact: the
  wire format, `parseTable`, and `matchPath` asserted over static, dynamic, catch-all, optional
  catch-all, group and slot segments.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `@Decl` carries no source location, so a decorator cannot learn which file it annotates — the defining premise of file-system routing is unreachable | every `#[page(...)]` / `#[layout(...)]` in both examples | the app-relative directory is an explicit decorator argument, generated and verified against the real tree by the CLI (front 50) | `decl.source() -> Source` — the `Source` record already exists and `@Expr` already returns it (`libs/std/src/builtins.d.bp:357-362`) |
| Declared parameter defaults are never applied | every `attrs:` in `app-tree-example.bp` | pass every argument explicitly, `attrs:` included | apply a declared default at the call site when the argument is omitted |

## Test plan

`repository/rakun/test/file_router_test.bp`, run by `botopink test --target erlang` and
`botopink test --target commonJS` from `repository/rakun/`, and by `zig build test-libs --  --lib rakun`
in the ecosystem gate. This front is a boundary front, so **both rows must be green** — the exit gate
in `fronts.md` names 22 as one of the three fronts required on both targets.

What the tests assert, grouped as the steps above: segment classification for all seven kinds; the
four decorators' placement failures; `parseTable` ∘ `writeTable` round-trip on all eight record kinds;
`matchPath` precedence and capture; `layoutChain` order; and the emitted parameter accessors.

Scan-time conflicts (page + route in one segment, two matching root layouts, a registered segment
with no directory) are compile/startup failures and cannot be written as a runtime `assert`; they go
in the CLI's own suite under front 50, and this front's README is where the expected message text is
specified. That split follows the precedent in `repository/rakun/test/di_test.bp:14-16`.

## Definition of done

- `src/file_router.bp` compiles with no `@External.Node`-only path: every host cell declares both an
  `@External.Erlang` and an `@External.Node` target, because both sides run the table.
- `src/sidecars/rakun_file_router.erl` and `file_router.mjs` implement the same registry protocol,
  and the round-trip test proves it rather than asserting it.
- The eight `kind` letters, the four-field record and the precedence order are written down here and
  cited by fronts 23, 25, 27, 60, 61 and 66 rather than re-derived.
- `repository/rakun/AGENTS.md` names `file_router.bp` and the wire format.
- The front's tests are green on its assigned target — here, on both.

## Carried from 1.0.7-beta F14 rakun-file-routing

Source: `specs/1.0.7-beta/14-rakun-file-routing/README.md` and `specs/1.0.7-beta/examples-bp.md § F14`.
Items below are absent from the 1.0.9 text above; items the merge already covers elsewhere are listed
at the end with the front that holds them.

### Reference rows

All four 1.0.7 references (Project Structure · Dynamic Routes · Route Groups · Parallel Routes) are
cited in the 1.0.9 header. "Depends on: F01 (onze13-stand-up)" → 49-onze-stand-up.

### Requirements and API names (quoted)

| # | 1.0.7 item | Where in 1.0.7 | Note |
|---|---|---|---|
| 1 | Startup scan as a host cell: `#[@External.Node("rakun/file_router", "scanAppDir")] #[@External.Erlang("rakun_file_router", "scan_app_dir")] declare fn scanAppDir(appDir: string) -> RouteNode[];` — "Scans `app/` directory at startup"; acceptance "`scanAppDir` scans directory recursively · Returns tree of `RouteNode` · Detects special files" | Mechanism, Step 1 | superseded by: 22 § Problem ("Its plan was to scan `app/` at startup with a host cell and load the matched page module by path. botopink compiles only declared modules … A file-convention router in botopink therefore has to be registration-driven"). The scan survives as a CLI-side verification (22 Step 5), not as the source of routes |
| 2 | `pub type RouteNode(path: string, filePath: string, segment: string, isDynamic: bool, isCatchAll: bool, isGroup: bool, children: RouteNode[], hasPage: bool, hasLayout: bool, hasLoading: bool, hasError: bool, hasNotFound: bool, hasRoute: bool)` — a tree with per-convention flags | Step 1 | superseded by: 22 § What crosses the boundary — flat `RouteEntry(kind, pattern, slot, verb)` records, one per convention file, eight `kind` letters. `filePath` has no 1.0.9 counterpart (`@Decl` carries no source location; 22 § Language gaps) |
| 3 | `pub fn matchRoute(path: string, routes: RouteNode[]) -> ?RouteMatch` with `pub type RouteMatch(node: RouteNode, params: Dict<string, string>)`; comments "Match static segments exactly · Match dynamic segments ([slug]) and capture params · Match catch-all ([...slug]) and capture remaining · Skip route groups ((group))" | Step 2 | Covered by 22 Step 4 `matchPath(table, pathname) -> ?RouteMatch` with `RouteMatch(entry, params, rest, chain)`; precedence static > dynamic > catch-all > optional catch-all is 22's addition |
| 4 | `pub fn renderWithLayouts(node: RouteNode, page: Element) -> Element { var content = page; loop (node.layouts) { layout -> content = layout(content); }; return content; }` — "Wrap in each layout from root to leaf"; acceptance "Layouts nest correctly · Root layout wraps all pages · Segment layouts wrap their children" | Step 3 | Covered by 22 Step 4 `layoutChain` (root-first) + 23 Step 2 `compose(chain, page)`. Note the 1.0.7 loop wraps root-first, which yields the root layout **innermost**; 23 wraps "from the inside out" so the root layout is outermost |
| 5 | `// src/file_router.mjs (sidecar) import fs from "fs"; import path from "path"; export function scanAppDir(appDir) { … node.hasPage = files.includes("page.bp"); node.hasLayout = files.includes("layout.bp"); … files.filter(f => fs.statSync(path.join(dir, f)).isDirectory()).forEach(subdir => { const child = createNode(subdir); node.children.push(child); scan(path.join(dir, subdir), child); }); … }`; acceptance "`scanAppDir` implemented in JS · Erlang equivalent implemented · Both targets work" | Step 4 | superseded by: 22 § How it maps ("`file_router.mjs` is the browser one and holds only the table"); the directory walk is front 01's, used by the CLI (22 Step 5) |
| 6 | `// In ssr.bp … val routes = scanAppDir("app"); val match = matchRoute(path, routes); if (match == null) { return renderNotFound(); }; val page = await loadPageComponent(match.node); val withLayouts = renderWithLayouts(match.node, page); return renderToString(withLayouts);` | Step 5 | superseded by: 22 § Problem (no load by path), 23 § Mechanism pipeline (`matchPath → layoutChain → compose → renderNode`), 23 Step 3 (no `renderToString`) |
| 7 | Tests: `val routes = [RouteNode(path: "/blog", ...), RouteNode(path: "/about", ...)]; val match = matchRoute("/blog", routes); assert match != null; assert match.node.path == "/blog";` and `assert match.params.get("slug") == "hello";` | Step 6 | Covered by 22 Step 4 acceptance and `examples/route-table-example.bp` (optional read via `if (matchPath(...)) { m -> … }`; `params.lookup("slug").unwrapOr("")`) |
| 8 | Note: "The file router scans at startup; changes require restart (dev mode can watch)." | Notes | 50 § `dev` ("Editing `app/page.bp` re-renders on the next request without restarting the node · Adding `app/about/page.bp` makes `/about` resolve without a restart"; polling, not `fs.watch`) and 80 (devtools restart classes) |
| 9 | Gate: "Commit on `fix/rakun-file-routing`" | Gate | Branch-naming convention; 1.0.9 fronts name no branch |
| 10 | Blast radius: "SSR pipeline uses file router · No breaking changes to existing decorator-based routing" | Blast radius | 23 depends on 22; 22 § Problem ("That model works and this front does not replace it") |

### Example material (quoted from `examples-bp.md § F14`)

Carried verbatim to [`examples/layout-and-params-carried-example.bp`](./examples/layout-and-params-carried-example.bp). The file tree (`Estrutura de arquivos`) is covered by the header comment of [`examples/app-tree-example.bp`](./examples/app-tree-example.bp) (plus `api/posts/route.bp` in 25's example). The two `.bp` snippets differ in shape and are marked as language gaps in the file:

| 1.0.7 example | 1.0.9 counterpart |
|---|---|
| `pub fn BlogLayout(children: Element) -> Element` — a positional `children` parameter, no decorator | 22 Step 2 `#[layout("blog")] pub fn blogLayout(props: LayoutProps) -> Element` — "one uniform arity is the only shape that survives the gap" (declared parameter defaults never applied) |
| `Link("/blog", [text("Todos os Posts", attrs: [])])` inside a layout's `nav` | 27 § Problem records the 1.0.7 `Link("/about", [text("About")])` form and its six-parameter gap; 1.0.9 spelling is `Link(linkProps(href), children)` |
| `#[@future] pub fn BlogPost(params: Dict<string, string>) -> @Future<Element>` with `params.get("slug")`, no decorator | 22 Step 2 `#[page("blog/[slug]")] pub fn blogPostPage(route: PageContext)` + the emitted `blogPostPageParams(route).slug` (Step 6). `Dict` reads are `lookup(...).unwrapOr(...)` in every 1.0.9 example |

### Covered elsewhere (not carried)

- "Detects special files: `page.bp`, `layout.bp`, `loading.bp`, `error.bp`, `not-found.bp`, `route.bp`" → 22 kind table (`P`/`L`/`S`/`E`/`N`/`R`; 30, 31, 25 register the last three).
- "Handles dynamic segments `[slug]`, catch-all `[...slug]`, route groups `(group)`" → 22 Step 1 (`parseSegment`, seven kinds incl. `[[...slug]]`, `@slot`, `_private`).
- "Route groups `(group)` are transparent in the URL but can have their own layouts." → 22 Step 1 (`patternOf` drops groups) and Step 5 (two root layouts).
- "Maps folder structure to URL paths" → 22 `patternOf(parsePath(seg))`.
- Tree `(marketing)/about/page.bp → /about (group ignored in URL)` · `api/posts/route.bp → /api/posts` → 22 and 25 example headers.
