# Front 22 — Rakun File Routing

**Track:** B rakun
**Priority:** critical — without a route table there is no route to render, no route to prefetch, and no
place to hang a server action; fronts 23, 24, 25, 27, 60, 61 and 66 all read what this front writes
**Target:** erlang. The registry, the scan and the host cells are erlang (`rakun-app`); the pure
matcher — segment grammar, the route table's wire, `matchPath`, `layoutChain` — is the bundled
library `routing` (`libs/routing`, erlang and commonJS, front `01-std/04-routing-lib`), which rakun
imports and the browser imports too, so both match with the same code (decision 115)
**Wave:** 2
**Depends on:** 01 (the directory walk — `path` is already complete), 05 (`rakun.appDir` as a config
value), `01-std/04-routing-lib` (the matcher, Steps 1, 3 and 4's code and tests)
**Owns:** `repository/rakun/modules/rakun-app/src/file_router.bp` (the registry cells and the scan entry),
`repository/rakun/modules/rakun-app/src/sidecars/rakun_file_router.erl`, `repository/rakun/modules/rakun-app/test/file_router_test.bp` (the `rakun-app` member, `modules.md` § The cut)
**Does not touch:** `repository/rakun/src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` (frozen for the milestone), and the files owned by 23 · 24 · 25; the UI
conventions — `#[page]`, `#[layout]`, `#[template]`, `#[defaultView]`, `PageContext`, `LayoutProps`
and the per-route parameter accessors — are jhonstart
[front 30](../../04-jhonstart/30-jhonstart-streaming/README.md)'s (decision 114)
**Reference:** `NEXTJS-DOCS.md § 3. Estrutura do Projeto`, `§ 4. App Router — Fundamentos`,
`§ 6. Rotas Dinâmicas`, `§ 21. Rotas Paralelas e Interceptadas` ·
<https://nextjs.org/docs/app/getting-started/project-structure> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/dynamic-routes> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/route-groups> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/parallel-routes>

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

There is also a mechanical constraint: scanning `app/` at startup with a host cell and loading the
matched page module by path cannot work. botopink compiles only declared
modules (`pub mod` in the package root, `docs.md:34-46`); a `.bp` file is not loadable at runtime, and
`@Decl` carries no source location, so a decorator cannot learn which file it was written in. A
file-convention router in botopink therefore has to be registration-driven, and the file path has to
reach the decorator as an argument. That is what this front builds, and the argument is generated and
checked against the real tree by the CLI (front 50), so a developer still only moves files around.

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

**The route table is rakun's; what a UI convention file declares is jhonstart's.** rakun routes and
answers; it names no `Element` (decisions 113, 114). Each file convention reaches the table as one
record, registered by whoever owns the function behind it:

| File in `app/` | Declared by | What rakun's registry holds |
|---|---|---|
| `layout.bp` | jhonstart front 30's `#[layout(seg)]` | an `L` record, registered by onze at boot |
| `template.bp` | jhonstart front 30's `#[template(seg)]` | a `T` record, registered by onze at boot |
| `page.bp` | jhonstart front 30's `#[page(seg)]` | a `P` record and one opaque `PageRenderer` (front 23), handed in by onze through `page(pattern, render)` |
| `default.bp` | jhonstart front 30's `#[defaultView(seg)]` | a `D` record, registered by onze at boot |
| `loading.bp` · `error.bp` · `not-found.bp` | jhonstart fronts 30 · 31 | an `S` · `E` · `N` record, registered by onze at boot |
| `route.bp` | front 25's verb decorators | an `R` record and the handler, `fn(req: Request) -> @Task<HandlerResponse>` |

The UI decorators, `PageContext`, `LayoutProps` and the per-route parameter accessors are jhonstart
front 30's: they fill jhonstart's UI registry, and onze copies that registry into this front's table
at boot, so the table the server matches and the payload's `t` are one table (contract 1). A page's
renderer is opaque here — `fn(req: Request, out: ChunkWriter) -> @Task<@Result<void, string>>`
(front 23, decision 130); rakun
calls it and never looks inside. A page's `notFound` / `redirect` are jhonstart's and never reach
this table's dispatch as signals (decision 117 rule 1); an `N` record is the boundary jhonstart's
render uses for its own 404.

The registry lives in the host because botopink has no top-level mutable state — the same reason
rakun's scan registry lives in a host file (`repository/rakun/src/runtime.bp:1-11`). This front's
registry is separate from `rkRegisterRoute`'s, and it is `src/sidecars/rakun_file_router.erl`, on
BEAM. The sidecar's filename is not cosmetic: `shipErlSidecars` skips any atom matching a module this
build emitted (`libs.zig:596`), and rakun emits `rakun/file_router`, so a sidecar named
`src/file_router.erl` is silently not shipped. Every erlang sidecar in this track is
`src/sidecars/rakun_<name>.erl`.

**The `appDir` is configuration, not a literal.** `rkProp("rakun.appDir")` (front 05) resolves to
`app` or `src/app`, `app` when unset; onze writes the key at boot (decision 115) and rakun reads no
`onze.` key (`modules/rakun-app/src/file_router.bp` still reads `onze.appDir`; Step 5 renames it).
The decorator argument is relative to it, so moving the tree between the two
layouts changes one config line and no source. The host-side scan reads `appDir` to verify that every
registered segment corresponds to a real directory and that every directory holding a convention file
registered something — a check the CLI runs, not the server.

### What crosses the boundary

The route table, and only the route table. It crosses as a line-oriented blob, not as JSON — contract
1 fixes that wire, and decision 117's `json.decode` does not change it — and its parser is compiled to
BEAM as well as to the browser:

```
kind|pattern|slot|verb
```

one record per line, `\n`-separated, in registration order. `kind` is one letter:

| Letter | Convention | Registered by |
|---|---|---|
| `L` | `layout.bp` | onze, from jhonstart's UI registry |
| `T` | `template.bp` | onze, from jhonstart's UI registry |
| `P` | `page.bp` | onze, through front 23's `page(pattern, render)` |
| `D` | `default.bp` | onze, from jhonstart's UI registry |
| `R` | `route.bp` | front 25 |
| `S` | `loading.bp` | onze, from jhonstart's UI registry (front 30) |
| `E` | `error.bp` | onze, from jhonstart's UI registry (front 31) |
| `N` | `not-found.bp` | onze, from jhonstart's UI registry (front 31) |

`pattern` is the URL pattern with groups and slots removed and the bracket spelling preserved
(`/blog/[slug]`, `/shop/[...slug]`, `/docs/[[...slug]]`). `slot` is `""` for the children slot and the
slot name for an `@slot` entry. `verb` is `""` for UI entries and the HTTP method for an `R` entry.
Neither `|` nor a newline may appear in a segment name, and the scan fails if one does.

The server reads the table from its own registry. **The matcher is the bundled library
`routing`** (`libs/routing`, `["erlang", "commonJS"]`, decision 115): the segment grammar,
`RouteEntry`, `parseTable` / `writeTable`, `matchPath` and `layoutChain`, pure, with no HTTP, no host
cell and no registry. `rakun-app` imports it on erlang; jhonstart's router (front 26) imports it on
commonJS and parses the payload's `t` field itself. `routing` is neutral like std, so neither import
is an edge between jhonstart and rakun (decision 113). That is why the matcher is one library: if
the two sides can disagree about which route a URL is, every fix downstream is a guess. This front
specifies the grammar, the wire and the matcher (Steps 1, 3, 4); `01-std/04-routing-lib` owns the
code and runs these steps' acceptance on both targets.

## Steps

### Step 1 — Segment grammar

`parseSegment` classifies one folder name. It is pure, total, and the only place the bracket and
parenthesis spellings are decoded. It lives in `routing`'s `segment` module (Step 7).

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
- [x] `parseSegment("blog")` is `Static`/`blog`; `parseSegment("[slug]")` is `Dynamic`/`slug`. — held: `libs/routing/test/segment_test.bp` "a static folder is a static segment", "[slug] is a dynamic segment"
- [x] `parseSegment("[...slug]")` is `CatchAll`/`slug`; `parseSegment("[[...slug]]")` is
      `OptionalCatchAll`/`slug`. The optional form is tested against the required form, not only
      against a static one. — held: `libs/routing/test/segment_test.bp` "the catch-all and the optional catch-all are told apart"
- [x] `parseSegment("(marketing)")` is `Group`/`marketing`; `parseSegment("@team")` is `Slot`/`team`;
      `parseSegment("_components")` is `Private`/`components`. — held: `libs/routing/test/segment_test.bp` "a group, a slot and a private folder"
- [x] `patternOf(parsePath("(marketing)/about"))` is `/about` — a group contributes no segment. — held: `libs/routing/test/segment_test.bp` "a group contributes no URL segment"
- [x] `patternOf(parsePath("dashboard/@team/settings"))` is `/dashboard/settings` and
      `slotOf(...)` is `team`. — held: `libs/routing/test/segment_test.bp` "a slot contributes no URL segment and names itself"
- [x] `parsePath("blog/_drafts/[slug]")` fails with a message naming `_drafts`: a private folder may
      not appear on a registered path at all. — held: `libs/routing/test/segment_test.bp` "parsePath halts on a private folder, naming it"
- [x] A segment name containing `|` or a newline fails with a message naming the segment. — held: `libs/routing/test/segment_test.bp` "a `|` or a newline in a segment is refused by name" (`pathProblem` names the segment for both)

### Step 2 — The registry: table records and opaque page renderers

rakun's registry takes what onze hands it and names no type of jhonstart's. Three host cells, each
generic over the function it stores where it stores one — the trick `rkRegisterRoute<Req>` uses to
stay typed without naming the caller's types (`repository/rakun/src/runtime.bp:70-81`):

```bp
#[@External.Erlang("rakun_file_router", "register_entry")]
pub declare fn rkAppRegisterEntry(kind: string, pattern: string, slot: string) -> i32;

#[@External.Erlang("rakun_file_router", "register_page")]
pub declare fn rkAppRegisterPage<R>(pattern: string, render: R) -> i32;

#[@External.Erlang("rakun_file_router", "register_handler")]
pub declare fn rkAppRegisterHandler<Res>(
    verb: string,
    seg: string,
    handle: fn(req: Request) -> Res,
) -> i32;
```

`rkAppRegisterEntry` is how onze copies jhonstart's UI records (`L`, `T`, `D`, `S`, `E`, `N`) into
the table. `rkAppRegisterPage` is what front 23's `page(pattern, render: PageRenderer)` calls: it adds
the `P` record and keeps the renderer for the dispatch; this front never calls the renderer.
`rkAppRegisterHandler` is front 25's: `route.bp` handlers register through the same registry, into
the same table, as `R` records, so this front never has to know what a `HandlerResponse` is and
front 25 never has to declare a host cell.

**Acceptance:**
- [x] `rkAppRegisterEntry("L", "blog", "")` adds the record `L|/blog||` (written `L|/blog` — `routing`'s `writeTable` drops trailing empty fields); a `kind` outside the eight
      letters fails naming the letter. — held: `modules/rakun-app/test/file_router_test.bp` "an entry becomes one line of the host table" + "a kind outside the eight letters is refused naming the letter" (rakun `2e9b0e1`)
- [x] `rkAppRegisterPage("blog/[slug]", r)` adds `P|/blog/[slug]||` and the dispatch (front 23) finds
      `r` for a request matching that pattern. — held: `modules/rakun-app/test/file_router_test.bp` "a page is a P record whose renderer the dispatch finds"
- [x] Registering two renderers for one pattern fails at registration, naming the pattern — the
      table never holds two pages for one URL. — held: `modules/rakun-app/test/file_router_test.bp` "a second renderer for one pattern is refused naming the pattern"
- [x] `rkAppRegisterEntry("L", "", "")` registers the root layout at `/`. — held: `modules/rakun-app/test/file_router_test.bp` "an entry becomes one line of the host table"
- [x] `grep -rn "Element\|LayoutProps\|jhonstart" modules/rakun-app/src` is empty — the registry
      names no UI type (decision 114). — held: the grep is empty, and the pre-commit gate enforces it (`scripts/git-hooks/lib/runner-standalone.sh`)

### Step 3 — The route table and its wire format

```bp
pub type RouteEntry(
    kind: string,
    pattern: string,
    slot: string,
    verb: string,
)

// routing — the `table` module
pub fn parseTable(wire: string) -> RouteEntry[]
pub fn writeTable(entries: RouteEntry[]) -> string

// rakun-app — the server's own table, as a wire string
#[@External.Erlang("rakun_file_router", "table")]
pub declare fn rkAppTable() -> string;
```

**Acceptance:**
- [x] `parseTable(writeTable(xs))` equals `xs` for a table holding one entry of each of the eight
      kinds — compared field by field, never with `==` on the arrays, which is reference equality
      (`docs.md`, gotcha: `==` on arrays lowers to `===`). — held: `libs/routing/test/table_test.bp` "the wire format round-trips all eight kinds, field by field"
- [x] `writeTable` emits records in registration order and terminates no line with a trailing `|`. — held: `libs/routing/test/table_test.bp` "writeTable keeps registration order and ends no line with a bar"
- [x] The same assertion, in `routing`'s `test/table_test.bp`, runs green on `--target erlang` and on
      `--target commonJS`. A wire format only one target can read is the bug this front exists to
      prevent. — held: `libs/routing` 66/0 on erlang and on commonJS (2026-09-26)

### Step 4 — The matcher

One function, both targets, one precedence order — in `routing`'s `match` module (Step 7).

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
- [x] `/blog/hello` against `/blog/[slug]` binds `slug` to `hello`. — held: `libs/routing/test/match_test.bp` "a dynamic segment binds its parameter"
- [x] `/shop/a/b` against `/shop/[...slug]` binds `slug` to `a/b` and `rest` to `["a", "b"]`. — held: `libs/routing/test/match_test.bp` "a catch-all binds the remainder and fills rest"
- [x] `/docs` matches `/docs/[[...slug]]` with `rest` empty; `/docs/a/b` matches it with
      `rest == ["a", "b"]`. `/shop` does *not* match `/shop/[...slug]`. — held: `libs/routing/test/match_test.bp` "an optional catch-all matches with and without a remainder", "a required catch-all does not match its own bare prefix"
- [x] A table holding both `/blog/new` and `/blog/[slug]` matches `/blog/new` to the static entry. — held: `libs/routing/test/match_test.bp` "a static entry beats a dynamic one for the same URL"
- [x] `matchPath` returns `null` for a pattern that has a `L` entry but no `P` or `R` entry — a route
      is public only when a page or a handler claims it (`§ 3. Convenções de nomenclatura`). — held: `libs/routing/test/match_test.bp` "a layout alone does not make a route public"
- [x] `layoutChain(table, "/blog/[slug]")` returns the `L` entries for `/`, `/blog`, `/blog/[slug]`
      in root-first order, and skips group segments' patterns because they are not in the pattern. — held: `libs/routing/test/match_test.bp` "the layout chain is root-first…", "a group never reaches the chain…"
- [x] Every assertion above is run twice, once per target, from `routing`'s `test/match_test.bp`. — held: `libs/routing` 66/0 on erlang and on commonJS (2026-09-26)

### Step 5 — Scan-time conflicts

The scan is `src/sidecars/rakun_file_router.erl`: the server's own startup check, and the check
front 50's CLI runs. It reads `rakun.appDir` from front 05, walks the tree, and fails loudly rather
than serving something surprising.

**Acceptance:**
- [x] A segment holding both `page.bp` and `route.bp` fails the scan with a message naming the
      segment directory — `§ 19` states the rule and this is where it is enforced. — held: `modules/rakun-app/test/file_router_scan_test.bp` "a segment holding page.bp and route.bp is refused by name" (message names `e.seg`)
- [x] A directory under `appDir` whose name starts with `_` is skipped, and nothing inside it is
      registered even if it holds a `page.bp`. — held: `modules/rakun-app/test/file_router_scan_test.bp` "a `_`-prefixed directory is skipped, page.bp and all"
- [x] Two route groups may each own a root layout (`§ 5. Múltiplos Root Layouts`); the scan fails
      when two root layouts' subtrees both match one URL, naming the URL and both groups. — held: `modules/rakun-app/test/file_router_scan_test.bp` "two root layouts meeting at one URL name the URL and both groups"
- [x] A registered segment with no corresponding directory under `appDir` fails the scan, naming the
      segment and the function that registered it. This is the check that keeps the decorator
      argument honest. — held: `modules/rakun-app/test/file_router_scan_test.bp` "a registered segment with no directory names the segment and the fn"
- [x] The scan runs with `rakun.appDir` set to `app` and to `src/app` and produces the same table;
      unset, it scans `app`. `grep -rn '"onze\.' repository/rakun` is empty — rakun reads no
      `onze.` key (decision 115). — held: `modules/rakun-app/test/file_router_scan_test.bp` "app and src/app produce the same table" + "appDir is configuration, defaulting to app"; no `onze.` key in any rakun source (the gate's grep)
- [ ] A `middleware.bp` at the **project root** — beside `botopink.json`, not under `appDir` — is
      discovered by the same scan that discovers `appDir`, with no `pub mod` line naming it, and is
      handed to front 07. The discovery is this front's; what runs in it is front 07's. A project
      with no root `middleware.bp` scans clean and registers nothing, which is the common case and
      therefore the case that must not warn.

### Step 6 — The UI conventions leave `rakun-app`

The four UI decorators, `PageContext`, `LayoutProps`, the Element-typed `rkAppRegisterPage` and the
emitted `<page>Params(route)` accessors are jhonstart front 30's (decision 114). This front removes
its copies once jhonstart front 30 has them, and keeps Step 2's registry.

**Acceptance:**
- [x] `modules/rakun-app/src/file_router.bp` declares none of `layout`, `template`, `page`,
      `defaultView` (as decorators), `PageContext`, `LayoutProps`, and no `@emit` of a parameter
      accessor. — held: `modules/rakun-app/src/file_router.bp` (the markers, `PageContext`, `LayoutProps` and the accessor emission are gone)
- [x] `test/file_router_test.bp` registers pages through `rkAppRegisterPage` with a renderer that
      writes plain text through a `ChunkWriter` (front 23) — no `Element` in the file. — held: `modules/rakun-app/test/file_router_test.bp` (`textPage` writes plain text through `writeTo`)

### Step 7 — rakun imports `routing`

The matcher is not rakun's: it is the bundled library `routing` (decision 115), written by
`01-std/04-routing-lib` from this front's Steps 1, 3 and 4, with their tests. This step switches
rakun to it and deletes rakun's copy. rakun lists no dependency for it: `routing` is bundled with the compiler
and resolves like `std`.

```bp
// rakun-app — file_router.bp
import {segment.parsePath, segment.patternOf, table.RouteEntry, table.parseTable,
        table.writeTable, match.matchPath, match.layoutChain} from "routing";
```

**Acceptance:**
- [x] `rakun-app`'s `file_router.bp` imports `parsePath`, `patternOf`, `RouteEntry`, `parseTable`,
      `writeTable`, `matchPath` and `layoutChain` from `"routing"` and defines none of them. — held: `modules/rakun-app/src/file_router.bp` imports all seven from `routing` (`matchPath` / `layoutChain` behind `appMatch` / `appLayoutChain`) and defines none
- [x] `file_router_test.bp` keeps only the registry, the scan and the dispatch tests; the grammar,
      wire and matcher tests are `routing`'s. — held: `modules/rakun-app/test/file_router_test.bp` holds registry/dispatch tests only; grammar, wire and matcher tests are in `libs/routing/test/`
- [x] No `botopink.json` under `repository/rakun/` lists `routing` in `dependencies`, and no member
      named `rakun-routing` exists. — held: no `botopink.json` under `repository/rakun` names `routing`; `modules/` has no `rakun-routing`
- [x] `repository/rakun/AGENTS.md` names `routing` as the library the matcher comes from. — held: `repository/rakun/AGENTS.md` "The grammar, the wire and the matcher are the bundled library `routing`'s"

## Examples

- [`examples/route-table-example.bp`](./examples/route-table-example.bp) — the shared artifact: the
  wire format, `parseTable`, and `matchPath` from `routing`, asserted over static, dynamic,
  catch-all, optional catch-all, group and slot segments.
- [`examples/page-registry-example.bp`](./examples/page-registry-example.bp) — the registry: table
  records registered the way onze registers them, and one opaque renderer per page pattern writing
  plain text.

An `app/` tree with layouts and pages is jhonstart's and onze's together, so it is onze front 53's
example ([`app-tree-example.bp`](../../06-onze/53-onze-example-app/examples/app-tree-example.bp)).

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `@Decl` carries no source location, so a decorator cannot learn which file it annotates — the defining premise of file-system routing is unreachable | the app-relative directory every UI decorator (jhonstart front 30) and front 25's verb decorators take | the directory is an explicit decorator argument, generated and verified against the real tree by the CLI (front 50) and by this front's scan | `decl.source() -> Source` — the `Source` record already exists and `@Expr` already returns it (`libs/std/src/builtins.d.bp:357-362`) |

## Test plan

`repository/rakun/test/file_router_test.bp` on `--target erlang`, by `zig build test-libs -- --lib
rakun` in the ecosystem gate. The grammar, wire and matcher assertions of Steps 1, 3 and 4 run in
`libs/routing/test/` on `--target erlang` and `--target commonJS` (`01-std/04-routing-lib`); **both
rows of the `routing` cell must be green** before this front's Step 7 lands — the matcher is what
the server and the browser share. The registry and the scan are erlang.

What the tests assert, grouped as the steps above: segment classification for all seven kinds;
`parseTable` ∘ `writeTable` round-trip on all eight record kinds; `matchPath` precedence and capture;
`layoutChain` order (all in `routing`); the registry's records and the one-renderer-per-pattern
refusal; and the absence of any UI type in `rakun-app`.

Scan-time conflicts (page + route in one segment, two matching root layouts, a registered segment
with no directory) are compile/startup failures and cannot be written as a runtime `assert`; they go
in the CLI's own suite under front 50, and this front's README is where the expected message text is
specified. That split follows the precedent in `repository/rakun/test/di_test.bp:14-16`.

## Definition of done

- rakun imports the segment grammar, the wire, `matchPath` and `layoutChain` from the bundled
  library `routing` and defines none of them.
- `src/file_router.bp` declares its host cells for erlang only; `src/sidecars/rakun_file_router.erl`
  implements the registry, and the round-trip test proves the table it serves parses back.
- The registry holds table records and opaque renderers; no UI decorator, `PageContext`,
  `LayoutProps` or `Element` remains in `rakun-app` (decision 114).
- The eight `kind` letters, the four-field record and the precedence order are written down here and
  cited by fronts 23, 25, 27, 60, 61 and 66 rather than re-derived.
- `repository/rakun/AGENTS.md` names `routing`, `file_router.bp` and the wire format.
- `routing`'s tests are green on both rows; `file_router_test.bp` on erlang.
- `appDir` is read from `rakun.appDir`.
