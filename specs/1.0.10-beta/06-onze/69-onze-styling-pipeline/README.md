# Front 69 — onze Styling Pipeline

**Track:** E onze
**Priority:** medium — an app has no CSS-module analogue, no global stylesheet and no preprocessor
hook, and nothing tells rakun-web's static server (front 82) to serve `public/`
**Target:** erlang (server)
**Wave:** 7 — after front 68 lands the manifest record this front appends to
**Depends on:** 49 (config, `publicDir`, `outDir`, and the boot that fills jhonstart's
`RenderHooks.headExtra` and registers the static roots) · 03 (fingerprints) · 68 (the manifest it
appends `Y` records to) · 82 (rakun-web's static-file server, which serves the roots this front
declares — decision 116) · 01 (`escape.html`, `escape.attribute`, `process.run`, `fs`, `path`)
**Owns:** `repository/onze/modules/onze-assets/src/**`,
`repository/onze/modules/onze-assets/test/**` — CSS modules, the global stylesheet and its
fingerprint, the `Y` manifest records, the two static roots handed to rakun-web front 82, the
preprocessor hook
**Does not touch:** `repository/emilia/src/**` (emilia's `flush()` contract is not called here at
all), `repository/jhonstart/**` — the moments emilia's sheet is flushed into the document are
jhonstart front 30's `RenderPlugin` calls, and the adaptation to `flush()` is the
`jhonstart-emilia` bridge's (decision 113) — `repository/onze/modules/onze-bundler/src/manifest.bp`
(front 68 owns the record and the parser; this front hands it the style records),
`repository/onze/src/integration.bp` (front 49, which registers the bridge plugin at boot),
`repository/rakun/**` — the static-file server is rakun-web front 82's
**Reference:** `NEXTJS-DOCS.md § 15. Estilização (CSS)` (CSS Modules · Global CSS · Sass ·
`useServerInsertedHTML`), `§ 3. Estrutura do Projeto` (`public/`) · `../../contracts.md § 4`
(class-name scheme, front 48) and `§ 6` (the manifest, front 68) ·
<https://nextjs.org/docs/app/getting-started/css> ·
<https://nextjs.org/docs/app/api-reference/functions/use-server-inserted-html> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/public-folder>

---

## Problem

`§ 15` (`NEXTJS-DOCS.md`) documents four styling routes and this ecosystem implements one — emilia's
`emilia(tokens)`. There is no CSS-module analogue, no global stylesheet and no preprocessor hook, and
— separately — nothing serves `public/` at all, so an app cannot ship a favicon.

The route that does exist is not this front's. When emilia's sheet is flushed into a server render —
once into the head after the shell, once per streamed boundary inside that boundary's fill
`<template>`, nothing left at the end — is decided by the package that writes the HTML: jhonstart
front 30 declares the asynchronous `RenderPlugin` point and awaits it, and the `jhonstart-emilia`
bridge awaits emilia's `@Task`-returning `flush()` in `head` and `chunk` and returns the flushed class names
from `payload()` as the payload's `s` key (decisions 113, 114). Next's `useServerInsertedHTML` is that seam, and it lives in
jhonstart. onze's only part in it is front 49 registering the bridge at boot.

## Current state

- `repository/onze/` does not exist; `modules/onze-assets/` is created by this front inside it.
- Nothing in the workspace reads or serves a `.css` file. `grep -rn "text/css" repository/` is empty.

## Mechanism

### What this front adds to a `<style>` body

A `<style>` body must not contain `</style`. emilia's own serialization cannot produce one, but a CSS
module's file content can, so the check runs over module CSS and global CSS and fails the build
naming the file. Attribute values this front writes — `href`, `rel` — go through front 01's
`escape.attribute`. The class names emilia produces (`contracts.md § 4`, front 48) are never
recomputed, re-hashed or rewritten here: this front does not handle emilia's block at all.

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
copy in every response is the opposite of that. The `<link>` reaches the document through
jhonstart's `RenderHooks.headExtra`, which front 49 fills at boot — jhonstart writes the head, onze
supplies the markup for that field.

The fingerprint, the URL and the byte count go into front 68's manifest as `Y` records. **Front 68
owns the manifest record and its parser; this front hands it the records** — the same
one-owner-per-file convention track A uses for `libs/std/src/root.bp`. This front never edits
`manifest.bp`.

### `public/` — served by rakun-web front 82, configured by onze

`§ 3`: `public/` is served from `/`. onze does not serve it: rakun-web front 82 is the static-file
server — its content-type table, its `ETag` / `304` handling and its traversal refusal — and onze
already depends on `rakun-web`, so a second server here would be a second copy of the same rules
(decision 116 rule 6). What this front decides is **which roots exist and how they are cached**, and
it states that as front 82's `StaticRoot` records, which front 49's boot registers with
`registerStaticRoot`:

| Root (`pattern` → `directory`) | `immutable` | `cacheSeconds` | Resulting `Cache-Control` (front 82) |
|---|---|---|---|
| `/_onze/static/<buildId>/**` → `<outDir>/static/<buildId>/` — fingerprinted | `true` | `31536000` | `public, max-age=31536000, immutable` |
| `/**` → `public/` | `false` | `0` | `no-cache` |

**Two roots are registered and nothing else is.** `public/`, mapped at `/`, and the manifest's
`/_onze/static/<buildId>/` asset prefix. Every other directory in a project — `app/`, `src/`,
`content/`, `lib/`, `.onze/` and anything a developer adds — is **not reachable over HTTP**: no root
points at it, so front 82 answers 404. There is no configuration key, manifest record or route that
adds a third root: a project's data directory is data, and an app that wants a file published copies
it into `public/` deliberately. Front 53 keeps its blog posts in `content/` and relies on this; it
should not have to ask for it, and a later front that wants to serve a directory has found a design
question, not a missing option.

A request that escapes a root (`..`, an encoded `..`, an absolute path, a symlink out), the content
type of an extension (`application/octet-stream` for an unknown one, never `text/html`) and a
matching `If-None-Match` (`304`, no body) are front 82's rules and front 82's tests; this front
asserts none of them again. onze passes front 82 its URL prefix (`/_onze/static/`) as data, so no
rakun file spells `_onze`.

### The preprocessor hook

`§ 15` *Sass* is an npm tool. It stays one: `preprocess(config, inputPath) -> @Task<string>` runs
the command named in the config through front 01's `process.run` and takes its stdout. If no command
is configured the file is used as-is. A configured command that is missing fails the build naming the
command — not a silent fallback, because a silent fallback ships unprocessed source as CSS.

There is no plugin API and no loader model. The audit deferred both, and one process invocation is
the whole extension surface.

## Steps

### Step 1 — CSS Modules

```bp
pub type StyleModule(sourcePath: string, hash: string, names: Array<#(string, string)>, css: string)

pub fn scopeName(sourcePath: string, className: string, hash: string) -> string
pub fn compileStyleModule(sourcePath: string, source: string) -> StyleModule
pub fn generateStyleModuleSource(m: StyleModule) -> string
```

**Acceptance:**
- [x] Two files each defining `.container` produce two different scoped names
- [x] The same file produces the same scoped names on a second build
- [x] Every name in the generated `.bp` module appears in the rewritten CSS, and vice versa —
      asserted as a set comparison, since that pair is the whole contract
- [x] A class used but not defined is left unscoped and reported once
- [ ] The generated module compiles: `botopink build` over `<outDir>/styles/` succeeds

### Step 2 — Global CSS, fingerprinting, and the manifest records

```bp
pub fn buildStylesheet(globalCss: string, modules: Array<StyleModule>) -> #(string, string)
pub fn styleRecords(buildId: string, sheetHash: string, bytes: i32) -> Array<string>
```

**Acceptance:**
- [x] Global CSS precedes module CSS in the emitted file — the cascade depends on it
- [x] The emitted URL contains the sheet's own content hash
- [x] An unchanged app produces an unchanged sheet hash across two builds
- [x] `styleRecords` returns `Y|…` lines front 68's `parseManifest` reads back unchanged
- [x] This front's source contains no edit to `manifest.bp` — checked by ownership, stated here

### Step 3 — The static roots onze hands front 82

```bp
import {StaticRoot} from "rakun-web";

pub fn staticRoots(publicDir: string, outDir: string, buildId: string) -> Array<StaticRoot>
```

Front 49's boot calls `registerStaticRoot` (rakun-web front 82) once per record. This front defines
no content-type table, no path resolver, no conditional-request handling and no traversal check —
those are front 82's (decision 116 rule 6).

**Acceptance:**
- [x] `staticRoots("public", ".onze", "b7f2a1")` returns exactly two records, and a test asserts the
      count — the list is the rule, not a comment describing one
- [x] the fingerprinted record is `/_onze/static/b7f2a1/**` → `.onze/static/b7f2a1/`, `immutable:
      true`, `cacheSeconds: 31536000`; the other is `/**` → `public`, `immutable: false`,
      `cacheSeconds: 0`
- [x] No config field, manifest record or call adds a third root — asserted by building the list
      with every config field set adversarially and still getting two
- [x] `grep -rn "fn contentTypeOf\|fn resolveAsset" repository/onze` is empty — the table and the
      resolver are front 82's

### Step 4 — The preprocessor hook

```bp
pub fn preprocess(command: string, inputPath: string) -> @Task<string>
```

**Acceptance:**
- [x] With no command configured the file's own text is returned unchanged
- [x] With a command configured its stdout is returned
- [x] A missing command fails the build naming the command — no silent fallback
- [x] A command exiting non-zero fails the build with its stderr attached

## Examples

- [`examples/css-module-example.bp`](./examples/css-module-example.bp) — a CSS module's scoped names
  and the generated botopink module, plus the two static roots handed to rakun-web front 82.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No byte or binary type — also recorded by front 01 | `public/` binaries are moved by path; this front only chooses headers | keep binary assets out of botopink | a `bytes` primitive plus `fs.readBytes` |

## Test plan

`repository/onze/modules/onze-assets/test/` — three files, `botopink test --target erlang` from
the module root, and `zig build test-libs`.

| File | What it asserts |
|---|---|
| `style_module_test.bp` | `scopeName` determinism and collision-freedom, the name-set equality between the generated module and the rewritten CSS, the undefined-class report, the `</style` refusal |
| `assets_test.bp` | `staticRoots`: exactly two records, their patterns, directories and cache policies, and no third root under an adversarial config (traversal, content types and `304` are front 82's tests) |
| `stylesheet_test.bp` | Cascade order, fingerprint stability, and that `styleRecords` round-trips through front 68's `parseManifest` |

**Erlang only, and what that costs.** This front is server-side — it declares the served roots and
builds the stylesheet the server links; a green commonJS cell would be a claim it does not make. The one place
the two targets must agree is the manifest, and that round trip is front 68's `manifest_test.bp`,
which runs on both. `stylesheet_test.bp` asserts only that the records this front emits are readable
by that parser.

## Where it stands

Landed on onze `front/06-onze` (`2c48df7`, `3f42122`): `modules/onze-assets/src/`
`style_module`, `stylesheet`, `assets`, `preprocess` and `head` (`pageRenderHooks`: the stylesheet
links, then front 68's head scripts, and the body tags), 12 tests on erlang **and** commonJS (the
functions are pure or go through std's `process` / `fs`, which answer on both rows). The gate test
walks every `modules/*/src/*.bp` and finds no `flush()` call and no sink.

Open: the generated style module compiling under `onze build` (front 50 — it is four-line
accessor functions, but the box names the build), and the two roots **registered** with rakun-web
front 82, whose `StaticRoot` / `registerStaticRoot` do not exist at rakun `2a01ea5`: the roots are
onze's `AssetRoot(pattern, directory, immutable, cacheSeconds)`, field for field what the README
gives front 82's record, and the boot registers them when front 82 lands (69-a). The generated
module's accessors are `pub fn`, not the README's `pub val` (front 49's finding F1).

## Definition of done

- [x] `repository/onze/modules/onze-assets/` exists with `botopink.json`, `src/root.bp`,
      `src/style_module.bp`, `src/stylesheet.bp`, `src/assets.bp`
- [x] Nothing under `repository/onze/` calls `emilia.flush()` or defines a style sink — asserted by
      a grep in the front's own gate; the flush moments are jhonstart front 30's and the adaptation
      is the `jhonstart-emilia` bridge's (decision 113)
- [ ] Exactly two static roots are registered with rakun-web front 82, `public/` and
      `/_onze/static/<buildId>/`, with no configuration path to a third; `repository/onze/docs.md` states it, because front 53 depends
      on its `content/` directory being unreachable
- [x] The `Y` records this front emits are read back unchanged by front 68's `parseManifest`
- [x] `repository/onze/docs.md` states that emilia's block is written by jhonstart's render
      through the `jhonstart-emilia` plugin that front 49 registers, and points at jhonstart front 30
      for the ordering rule — onze restates none of it
- [x] The front's tests are green on its assigned target — `erlang`

