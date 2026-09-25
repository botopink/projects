# Front 69 — onze Styling Pipeline

**Track:** E onze
**Priority:** medium — `emilia.flush()` exists and nothing in the render pipeline has a defined moment
at which to call it, so the CSS an app generates either arrives empty, arrives twice, or does not
arrive; and nothing serves `public/`
**Target:** erlang (server)
**Wave:** 7 — after front 68 lands the manifest record this front appends to
**Depends on:** 48 (the attribute slot and the class the tree carries) · 49 (config, `publicDir`,
`outDir`, and the ordering rule it states for the non-streaming case) · 23 (the pipeline this front
inserts into) · 30 (the streamed boundaries it inserts per chunk) · 03 (fingerprints) · 68 (the
manifest it appends `Y` records to) · 01 (`escape.html`, `escape.attribute`, `process.run`, `fs`,
`path`)
**Owns:** `repository/onze/modules/onze-assets/src/**`,
`repository/onze/modules/onze-assets/test/**` — including the four sink functions and the
`RenderHooks.openSink`/`collectHead`/`collectChunk`/`closeSink` values built from them, which
`Onze.run` (front 49) installs into front 23's record. The record itself is front 23's; this front
defines nothing outside `repository/onze/` (decision 77)
**Does not touch:** `repository/emilia/src/**` (emilia's `flush()` contract is consumed, never
changed), `repository/onze/modules/onze-bundler/src/manifest.bp` (front 68 owns the record and
the parser; this front hands it the style records), `repository/onze/src/integration.bp` (front 49),
`repository/rakun/src/ssr.bp` (front 23)
**Reference:** `NEXTJS-DOCS.md § 15. Estilização (CSS)` (CSS Modules · Global CSS · Sass ·
`useServerInsertedHTML`), `§ 3. Estrutura do Projeto` (`public/`), `§ 13. Streaming` · `../../contracts.md § 4`
(class-name scheme, front 48) and `§ 2` (payload envelope, front 23 — the `s` and `h` keys) ·
<https://nextjs.org/docs/app/getting-started/css> ·
<https://nextjs.org/docs/app/api-reference/functions/use-server-inserted-html> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/public-folder>

---

## Problem

`emilia(tokens)` registers a rule on a process-local sheet and returns a class name;
`flush()` serializes that sheet into a `<style>` block **and clears it**
(`repository/emilia/src/emilia.bp:46-51`, `:62-65`). The clearing is not incidental — it is the
per-render contract, and emilia's own test asserts that a second flush emits `<style></style>`
(`emilia.bp:53-56`). It follows that there is exactly one correct consumer per render, and that
whoever calls it early gets an empty block while whoever calls it late gets somebody else's.

Nothing in the milestone is that consumer. Front 49 states the ordering rule and implements it for
one case — `renderDocument`: render the tree, then flush, then serialize — and says in its own README
that the streaming case belongs here. Front 23 renders a route and front 30 streams it in chunks, and
a chunk that renders after the head has been written registers classes that no `<style>` block
contains. The symptom is not a crash: it is a page whose late content is unstyled, intermittently,
depending on how fast a database answered.

Next solves the same problem with `useServerInsertedHTML` (`NEXTJS-DOCS.md § 15`), a hook that lets a
style library push markup into the document at the right moment during a streamed server render. This
front is that seam, and it is on the BEAM side because the render is.

The rest of `§ 15` is also unowned. Four styling routes are documented and this ecosystem implements
one: there is no CSS-module analogue, no global stylesheet, no preprocessor hook, and — separately —
nothing serves `public/` at all, so an app cannot ship a favicon.

## Current state

- `repository/emilia/src/emilia.bp:46-51` — `emilia(tokens: Token[]) -> string`, returning
  `"e_" + hashHex(rules)`; `:62-65` — `#[@future] flush() -> @Future<string>`; `:23-30` — the sheet
  is a JS `Map` on commonJS and an ordered list in the process dictionary under `'__emilia_sheet'`
  on erlang, cleared by `erase/1`. Per-BEAM-process storage is why a per-request process gives
  per-request style isolation for free, and it is the one property this front depends on.
- `repository/jhonstart/src/element.bp:55-67` — `renderToString`, which produces a string, not a
  stream. There is no chunked render surface today; front 30 creates it.
- `repository/onze/` does not exist; `modules/onze-assets/` is created by this front inside it.
- Nothing in the workspace reads or serves a `.css` file. `grep -rn "text/css" repository/` is empty.
- `libs/std/src/http.bp:16-18` — `@Future<T>` lowers eagerly on erlang. Style collection is ordered
  work by nature, so this costs nothing here, but it is why this front never claims that flushing
  overlaps rendering.

## Mechanism

### The seam

One record and four functions, in `src/style_sink.bp`. They are reached only as the
`RenderHooks.openSink`/`collectHead`/`collectChunk`/`closeSink` values that `Onze.run` installs
into front 23's record (decision 77): rakun declares the record and reads it, this front fills it,
and no file in `repository/rakun/` names this module. The record's fields carry no sink value —
the wrapper installed at boot holds the `StyleSink` in the request's own BEAM process, which is
where emilia's sheet already lives.

```bp
pub type StyleChunk(id: string, css: string, classes: Array<string>)

pub type StyleSink(
    chunks: Array<StyleChunk>,
    links: Array<#(string, string)>,   // rel -> href, from the manifest
    emitted: Array<string>,            // every class name already written into a block
    headWritten: bool,
)

pub fn openSink(links: Array<#(string, string)>) -> StyleSink

#[@future]
pub fn collectHead(sink: StyleSink) -> @Future<#(StyleSink, string)>

#[@future]
pub fn collectChunk(sink: StyleSink, holeId: string) -> @Future<#(StyleSink, string)>

pub fn closeSink(sink: StyleSink) -> #(StyleSink, string)

pub fn emittedClasses(sink: StyleSink) -> Array<string>
```

`emittedClasses` is what the pipeline writes into the payload's `s` key (`contracts.md § 2`): the class
names already present in the server-emitted `<style>`. It is the runtime half of the class-name
agreement — front 68's entry compares what its islands compute against that list — and it is a field
of the sink rather than a re-scan of the CSS, because re-parsing the block to recover the names it was
built from is a second implementation of the thing that just ran.

**The ordering rule, which is the whole front in one line: render, then flush, then serialize — once
per chunk.**

| When the pipeline calls the hook | What it does | What it returns |
|---|---|---|
| `openSink(links)` | before anything renders | an empty sink carrying the stylesheet `<link>`s from the manifest |
| `collectHead(sink)` | after the **shell** has been rendered to a string — everything above the first unresolved boundary — and before the head is serialized | the head fragment: the `<link>` tags, then one `<style>` block holding whatever the shell registered |
| `collectChunk(sink, holeId)` | after a streamed boundary has been rendered and before that boundary's markup is written to the wire | `<style data-onze-s="<holeId>">…</style>`, or `""` when the boundary registered nothing |
| `closeSink(sink)` | after the last chunk | `""` and a sink whose pending sheet must be empty |

`collectHead` is called exactly once. Calling it twice is an error naming the second call, not a
second empty block — the empty `<style></style>` that emilia would return is precisely the symptom
this front exists to prevent, so it is caught rather than emitted.

`closeSink` is the check that nothing was dropped: if a flush at close returns a non-empty sheet,
some chunk registered classes after its own `collectChunk`, and that is a bug in the pipeline, not a
style to hide in a trailing block. It fails the render in dev and logs with the route in production.

### Why this is safe on BEAM and would not be on Node

The sheet lives in the process dictionary (`emilia.bp:23-30`). rakun serves each request in its own
BEAM process, so two concurrent renders have two sheets and neither can flush the other's classes.
This is not a lock and not a registry — it is the process model doing the work, and it is the reason
the seam is four pure-ish calls rather than a synchronised collector. The commonJS half has one
global `Map`, which is exactly why front 68 refuses a `flush()` reference in the client graph: on the
browser there is nothing to isolate.

### Agreement with front 48

`contracts.md § 4` is front 48's, and this front does not restate it, weaken it or re-implement any
part of it. The class in the tree's `attrs` is whatever `emilia(tokens)` returned during **this**
render. The sink never recomputes a name, never re-hashes a rule body, never deduplicates by content,
never sorts and never rewrites a class — clause 4's merge order and clause 5's attribute order are
decided before a single byte reaches the sink. It copies the block emilia produced, verbatim, into the
document, and records the names it copied so front 23 can publish them as `s`. That is what makes this
front and front 48 independent: front 48 decides how a class reaches `attrs`, emilia decides what the
class is called, and this front decides only *where the block goes*.

The one thing it does add is a check: a `<style>` body must not contain `</style`. emilia's own
serialization cannot produce one, but a CSS module's file content can, so the check runs over module
CSS and global CSS and fails the build naming the file. Attribute values the sink writes —
`data-onze-chunk`, `href`, `rel` — go through front 01's `escape.attribute`.

### CSS Modules

`§ 15` *CSS Modules*: a `*.module.css` file yields an object of scoped class names. The botopink
analogue is a **generated module**, produced by the CLI at build time alongside the route module,
because the compiler cannot import a `.css` file:

```
app/blog/blog.module.css   →   .onze/styles/app_blog_blog.bp
```

```bp
// generated — do not edit
pub val container: string = "blog_container_4f21ab";
pub val title: string = "blog_title_4f21ab";
```

The suffix is front 03's content hash of the file, truncated to six characters, so two modules that
define `.container` do not collide and an unchanged file produces an unchanged name across builds.
The rewritten CSS — every local class renamed to its scoped form — is appended to the app stylesheet,
which is fingerprinted and served like any other asset. `scopeName(file, className, hash)` is the one
function that decides a scoped name and it is pure, which is what makes "the generated module and the
rewritten CSS agree" a test rather than a hope.

A class that is not defined in the file but used in it (a global escape) is left alone and reported
once at build time. `:global(...)` is out of scope for this milestone and the README says so rather
than silently mangling it.

### Global CSS and the stylesheet

`§ 15` *Global CSS*: one file, imported once from the root layout, emitted once. Here it is a config
path (`app/globals.css` by default), read at build time, appended ahead of the module CSS, and
emitted as one fingerprinted file `/_onze/static/<buildId>/app.<hash>.css`. It is a `<link>` in the
head, not an inline block: it does not change per request, so it must be cacheable, and an inline
copy in every response is the opposite of that.

The fingerprint, the URL and the byte count go into front 68's manifest as `Y` records. **Front 68
owns the manifest record and its parser; this front hands it the records** — the same
one-owner-per-file convention track A uses for `libs/std/src/root.bp`. This front never edits
`manifest.bp`.

### `public/`

`§ 3`: `public/` is served from `/`. The rules:

| Path shape | Cache-Control | ETag |
|---|---|---|
| `/_onze/static/<buildId>/…` — fingerprinted | `public, max-age=31536000, immutable` | yes |
| everything else under `public/` | `public, max-age=0, must-revalidate` | yes, front 03's content hash |

**Two prefixes are served and nothing else is.** `public/`, mapped at `/`, and the manifest's
`/_onze/static/<buildId>/` asset prefix. Every other directory in a project — `app/`, `src/`,
`content/`, `lib/`, `.onze/` and anything a developer adds — is **not reachable over HTTP**, and a
request for one is a 404. There is no configuration key, manifest record or route that adds a third
served prefix: a project's data directory is data, and an app that wants a file published copies it
into `public/` deliberately. Front 53 keeps its blog posts in `content/` and relies on this; it should
not have to ask for it, and a later front that wants to serve a directory has found a design question,
not a missing option.

A request that escapes the public directory — `..`, an absolute path, a symlink out — is a 404, not
a 403, and never a file. Content types come from a fixed extension table, not from sniffing; an
unknown extension is `application/octet-stream`, never `text/html`, because a served-as-HTML upload
is a stored-XSS vector.

Binary files are copied and streamed by path, never read into botopink: there is no byte type
(front 01 records the gap), so `fs` and the runtime move them and this front only decides the
headers.

### The preprocessor hook

`§ 15` *Sass* is an npm tool. It stays one: `preprocess(config, inputPath) -> @Future<string>` runs
the command named in the config through front 01's `process.run` and takes its stdout. If no command
is configured the file is used as-is. A configured command that is missing fails the build naming the
command — not a silent fallback, because a silent fallback ships unprocessed source as CSS.

There is no plugin API and no loader model. The audit deferred both, and one process invocation is
the whole extension surface.

## Steps

### Step 1 — `StyleSink` and the ordering rule

**Acceptance:**
- [ ] `collectHead` on a sink whose render registered two classes returns one `<style>` block
      containing both rules, in registration order
- [ ] `collectHead` on a sink whose render registered nothing returns the `<link>` tags and **no**
      `<style>` element — not an empty one
- [ ] A second `collectHead` is an error naming the call, not a second block
- [ ] `collectChunk` returns `""` for a boundary that registered nothing
- [ ] `emittedClasses` after a head and two chunks lists every class written, once each, in emission
      order — this is the payload's `s` key and front 68's entry checks against it
- [ ] `closeSink` on a sink with a non-empty pending sheet is an error naming the route
- [ ] A `<style>` body containing `</style` is refused, naming the source file

### Step 2 — The non-streaming case agrees with front 49

Front 49's `renderDocument` is the specialization: `openSink`, render, `collectHead`, serialize. This
front does not reimplement it; it asserts the two produce the same document.

**Acceptance:**
- [ ] A document built through `renderDocument` and one built through `openSink`/`collectHead` are
      byte-identical for the same tree
- [ ] Exactly one `<style>` element appears in the document
- [ ] A second render in the same process starts from an empty sheet — asserted, because that is
      emilia's clearing contract and an app that relies on the opposite is relying on a bug

### Step 3 — Streaming insertion

```bp
pub fn chunkAttr(holeId: string) -> #(string, string)
```

`holeId` is `contracts.md § 2`'s streaming-hole id — the `h1` of `<div data-onze-h="h1">` — so the
style block for a boundary and the boundary itself are named by one identifier and a mismatch is
visible in the HTML rather than only in a symptom.

**Acceptance:**
- [ ] A class registered only by a late boundary appears in that boundary's chunk block, not in the
      head
- [ ] The chunk block is written **before** the chunk's markup, so the browser never paints the
      chunk unstyled
- [ ] Three boundaries resolving out of order each carry their own rules, and no rule appears twice
- [ ] `chunkAttr("h1")` is `#("data-onze-s", "h1")`, and its value goes through `escape.attribute`
- [ ] A render with no boundaries emits exactly the step-2 document, with no chunk blocks at all

### Step 4 — CSS Modules

```bp
pub type StyleModule(sourcePath: string, hash: string, names: Array<#(string, string)>, css: string)

pub fn scopeName(sourcePath: string, className: string, hash: string) -> string
pub fn compileStyleModule(sourcePath: string, source: string) -> StyleModule
pub fn generateStyleModuleSource(m: StyleModule) -> string
```

**Acceptance:**
- [ ] Two files each defining `.container` produce two different scoped names
- [ ] The same file produces the same scoped names on a second build
- [ ] Every name in the generated `.bp` module appears in the rewritten CSS, and vice versa —
      asserted as a set comparison, since that pair is the whole contract
- [ ] A class used but not defined is left unscoped and reported once
- [ ] The generated module compiles: `botopink build` over `<outDir>/styles/` succeeds

### Step 5 — Global CSS, fingerprinting, and the manifest records

```bp
pub fn buildStylesheet(globalCss: string, modules: Array<StyleModule>) -> #(string, string)
pub fn styleRecords(buildId: string, sheetHash: string, bytes: i32) -> Array<string>
```

**Acceptance:**
- [ ] Global CSS precedes module CSS in the emitted file — the cascade depends on it
- [ ] The emitted URL contains the sheet's own content hash
- [ ] An unchanged app produces an unchanged sheet hash across two builds
- [ ] `styleRecords` returns `Y|…` lines front 68's `parseManifest` reads back unchanged
- [ ] This front's source contains no edit to `manifest.bp` — checked by ownership, stated here

### Step 6 — Serving `public/`

```bp
pub type AssetResponse(status: i32, contentType: string, cacheControl: string, etag: string, path: string)

pub fn servedPrefixes(buildId: string) -> Array<string>
pub fn resolveAsset(publicDir: string, urlPath: string) -> AssetResponse
pub fn contentTypeOf(extension: string) -> string
```

**Acceptance:**
- [ ] `/favicon.ico` resolves to `public/favicon.ico` with `image/x-icon`
- [ ] `servedPrefixes()` returns exactly two entries, and a test asserts the count — the list is the
      rule, not a comment describing one
- [ ] `/../secrets.env`, `/%2e%2e/secrets.env` and an absolute path all give `404`, and the resolved
      path field is empty
- [ ] `/content/posts/hello.md` gives `404` with an empty path even though the file exists in the
      project — only `public/` and `/_onze/static/<buildId>/` are served
- [ ] `/app/page.bp`, `/src/main.bp` and `/.onze/client-manifest.txt` give `404` for the same reason
- [ ] No config field, manifest record or call adds a third served prefix — asserted by resolving
      every path above with every config field set adversarially and still getting `404`
- [ ] A fingerprinted path gets `immutable`; a plain public path gets `must-revalidate`
- [ ] An unknown extension is `application/octet-stream`, never `text/html`
- [ ] A conditional request whose `If-None-Match` matches gives `304` with no body

### Step 7 — The preprocessor hook

```bp
#[@future]
pub fn preprocess(command: string, inputPath: string) -> @Future<string>
```

**Acceptance:**
- [ ] With no command configured the file's own text is returned unchanged
- [ ] With a command configured its stdout is returned
- [ ] A missing command fails the build naming the command — no silent fallback
- [ ] A command exiting non-zero fails the build with its stderr attached

## Examples

- [`examples/styled-page-example.bp`](./examples/styled-page-example.bp) — the seam in use: a server
  render whose head carries the shell's styles and whose late boundary carries its own, with the
  order asserted.
- [`examples/css-module-example.bp`](./examples/css-module-example.bp) — a CSS module's scoped names
  and the generated botopink module, plus `public/` resolution including the paths that must 404.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| The streamed render is not a generator: `#[@futureGenerator] fn … -> @FutureGenerator<string, string>` can `await` and `yield` in one body (decision 103), but nothing in front 30's streaming consumes one | `collectChunk` is called per boundary by front 30 rather than driving a `@FutureGenerator<string, string>` | a callback per chunk, with the sink threaded through the return | front 30 consuming the chunks with `for await` (decision 105) |
| No byte or binary type — also recorded by front 01 | `public/` binaries are moved by path; this front only chooses headers | keep binary assets out of botopink | a `bytes` primitive plus `fs.readBytes` |
| No assignment to a `self` field | every sink call returns a new `StyleSink` instead of mutating one | thread the sink through the return as `#(StyleSink, string)` | mutable record fields, or a `with` expression |
| Tuple labels are lost through generic instantiation | `collectHead`'s `#(StyleSink, string)` is read as `r.0` / `r.1` | one `val` per element | preserve written labels through instantiation |

## Test plan

`repository/onze/modules/onze-assets/test/` — four files, `botopink test --target erlang` from
the module root, and `zig build test-libs`.

| File | What it asserts |
|---|---|
| `sink_test.bp` | The ordering rule: one head block, per-chunk blocks, the empty-render case, the double-`collectHead` error, the non-empty-at-close error, the `</style` refusal |
| `style_module_test.bp` | `scopeName` determinism and collision-freedom, the name-set equality between the generated module and the rewritten CSS, the undefined-class report |
| `assets_test.bp` | `resolveAsset`'s traversal cases, the two-prefix rule including `/content/…`, the two cache policies, the content-type table, `304` |
| `stylesheet_test.bp` | Cascade order, fingerprint stability, and that `styleRecords` round-trips through front 68's `parseManifest` |

**Erlang only, and what that costs.** This front is the server half of a server-side seam; a green
commonJS cell would be a claim it does not make, and the process-dictionary isolation it depends on
is a BEAM property. The one place the two targets must agree is the manifest, and that round trip is
front 68's `manifest_test.bp`, which runs on both. `stylesheet_test.bp` asserts only that the records
this front emits are readable by that parser.

`sink_test.bp` drives `flush()` for real — emilia is a dependency of the module and the sheet is a
process-dictionary cell, so a test can register classes and assert what comes back without any
scaffolding. That is the reason these tests are worth writing: the failure mode is an ordering
mistake, and ordering is exactly what a test can pin.

## Definition of done

- [ ] `repository/onze/modules/onze-assets/` exists with `botopink.json`, `src/root.bp`,
      `src/style_sink.bp`, `src/style_module.bp`, `src/stylesheet.bp`, `src/assets.bp`
- [ ] The four calls reach front 23's pipeline as `RenderHooks` values installed by `Onze.run`, and
      nothing else in the milestone calls `emilia.flush()` — asserted by a grep in the front's own
      gate, which also checks that `repository/rakun/` names no module of this one (decision 77)
- [ ] Exactly two URL prefixes are served, `public/` and `/_onze/static/<buildId>/`, with no
      configuration path to a third; `repository/onze/docs.md` states it, because front 53 depends
      on its `content/` directory being unreachable
- [ ] Front 49's `renderDocument` and this front's seam produce byte-identical documents for the
      non-streaming case
- [ ] The `Y` records this front emits are read back unchanged by front 68's `parseManifest`
- [ ] `repository/onze/docs.md` carries the ordering rule and the four-call sequence verbatim,
      because fronts 23, 30, 49 and 53 all read them
- [ ] The front's tests are green on its assigned target — `erlang`

