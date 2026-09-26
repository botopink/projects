# Front 82 — rakun Static Assets

**Track:** B rakun
**Priority:** medium — the server cannot serve a CSS file; `emilia`'s output, onze's client bundle and the image and font fronts all assume something will
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 07 (the filter chain this sits in), 03 (content hashes for ETags and fingerprints), 01 (`fs`, `path`, `clock`), 05 (root configuration), 04 (`rkSetReplyHeader`)
**Owns:** `modules/rakun-web/src/static/**` · `modules/rakun-web/test/static/**`
**Does not touch:** front 07's `modules/rakun-web/src/*.bp` at the top level, front 20's `src/websocket/**`, and the four frozen files in `repository/rakun/src/`
**Reference:** decision 116 rule 6 (onze configures this server instead of specifying one) · `04-web.md § Conteudo Estatico` · `04-web.md § Auto-configuracao Spring MVC` · `08-container-images.md § Reproducao e Cache` · <https://docs.spring.io/spring-boot/reference/web/servlet.html#web.servlet.spring-mvc.static-content>

---

## Problem

rakun answers requests from handlers. A handler is a function that returns a `Response(status, body)`,
and that is the only way a byte reaches a client. There is no path from a file on disk to a response:
no static root, no content-type table, no conditional request, no cache header, no range support,
nothing.

That is fine for a JSON API and fatal for everything else in this milestone. `emilia` emits a CSS
string that has to be served. onze's client bundle is JavaScript that has to be served. Front 51's
`Image` component and front 52's fonts both assume a URL exists that answers with the asset. Front 23
renders HTML that references all three. Every one of those fronts ends at a `<link>` or a `<script>`
whose href nothing answers.

Serving a file is also the part of a web server where the interesting mistakes live. A naive
implementation reads the path out of the URL, joins it to a root, and opens it — and now `GET
/static/../../etc/passwd` works. The second naive implementation reads the whole file into memory to
put it in the response body, and a 200 MB video is a 200 MB allocation per concurrent request. The
third sends no cache headers, so every page load re-fetches every asset. This front exists as much to
get those three wrong once, centrally, as to make a CSS file reachable.

## Current state

| Piece | Where it is today |
|---|---|
| `modules/rakun-web/src/static/` | does not exist |
| The only way to produce a body | `Response(status: i32, body: string)` and its six builders — `src/http.bp:45-73`. No header field, no streaming body, no file path |
| Reply headers | front 04 adds `rkSetReplyHeader(name, value)`; there is no other way to set one |
| Reading a file | `fs.readText(path) -> @Result<string, string>` — `libs/std/src/fs.bp:33`. Text only, whole file, into memory |
| File metadata | `fs.stat(path) -> @Result<FileStat, string>` — `fs.bp:99` |
| Path manipulation | front 01 delivers `path`; there is nothing today |
| A content hash | front 03 delivers it; `crypto.sha256` exists in the meantime |
| Content-type by extension | nothing, anywhere |

`fs.readText` is the entry that decides this front's shape. It returns a `string`, and botopink has no
type that says "these bytes are not text" — so a PNG cannot be read, held and written back through
botopink values without the type system losing track of what it is holding. The answer is not to try:
see *Mechanism*.

## Mechanism

### Bytes never enter botopink

A static response is produced by handing the host a **path**, not a body. The bp side resolves the
request to a file, decides the status and the headers, and calls one cell:

```bp
#[@External.Erlang("rakun_static", "send_file")]
pub declare fn rkSendFile(path: string, offset: i32, length: i32) -> i32;
```

`rakun_static:send_file/3` is `file:sendfile/5` on the connection's socket: the kernel copies the file
to the socket without the bytes crossing into the VM's heap, let alone into a botopink `string`. A
200 MB video costs one file descriptor and no allocation, and the byte-type question never arises
because no botopink value ever holds the bytes.

Two consequences follow, and both are design, not compromise. The `Response` a static handler returns
carries an empty body and a status; the body is written by the cell. And a pre-compressed variant is
selected by choosing a different **path** (`app.css.br`), which is exactly how it would be done
anyway.

The one case that reads a file into a `string` is the ETag, and it reads the file's *hash*, computed
by a cell, not its contents.

### Resolution, in the order the checks must happen

```
1. pattern match     does the request path match a root's pattern?      no → next filter
2. decode            percent-decode once, never twice                   double-encoded → 400
3. reject            any segment ".." or "." or empty, any NUL byte     → 404, before touching disk
4. join + canonical  root ++ relative, then realpath                    → 404 if outside the root
5. directory?        append the root's index file, re-run 4             → 404 if still a directory
6. stat              size, mtime                                        missing → 404
7. conditional       If-None-Match, then If-Modified-Since              match → 304, no body
8. range             If-Range, Range                                    → 206 or 416
9. encoding          Accept-Encoding vs pre-compressed variants         → pick a path
10. headers + send   content-type, cache-control, ETag, Vary            → rkSendFile
```

Order 3 before 4 and 4 before 6 is the part that matters. Rejecting `..` **before** joining means a
traversal never becomes a filesystem operation, and canonicalising **before** `stat` means a symlink
pointing outside the root is caught by the containment check rather than by a later one that does not
exist. A 404 — not a 403 — is the answer to every containment failure: telling a prober that a path
exists but is refused is telling them the path exists.

### Conditional requests, and why ETag leads

Two validators, and they disagree on a reproducible build. `08 § Reproducao e Cache` notes that
buildpacks normalise resource timestamps; front 81 does the same for the release tarball. After
normalisation every asset has the same mtime, so `Last-Modified` carries no information — which is
exactly why the upstream doc offers `spring.web.resources.cache.use-last-modified=false`, and why
front 81 generates `rakun.web.static.use-last-modified=false` by default.

An ETag derived from content (front 03) is unaffected by normalisation and is therefore the primary
validator here. `Last-Modified` is emitted when the switch allows it and is always the weaker of the
two: when both are present and they disagree, the ETag decides.

### Cache policy, and the two shapes an asset has

| Asset shape | `Cache-Control` | Why |
|---|---|---|
| `app.css` — a stable name whose content changes | `no-cache` (revalidate every time, 304 on unchanged) | The name cannot tell a client the content changed, so the client must ask |
| `app.7f3a91.css` — a content-hashed name | `public, max-age=31536000, immutable` | The name *is* the version; a changed file gets a new name and the old one is never requested again |

The second is the point of fingerprinting, and this front provides the naming function
(`fingerprint(path) -> string`, over front 03's hash) so that `emilia`, front 68's bundle and front 51's
images all fingerprint the same way and the policy can be decided by shape rather than configured per
file.

### Where it sits in the chain

One filter in front 07's chain, ahead of the router: a request matching a static pattern is answered
and the chain stops; anything else falls through untouched. It does not register routes in front 04's
table — a static root is a prefix, not a route, and putting thousands of files in a route table would
make every dynamic request slower.

### The one static-file server

This front is the only static-file server in the stack (decision 116). onze does not specify one of
its own: at boot it calls `registerStaticRoot` for its build output, its `public/` directory and its
style chunks — the roots, the URL prefix of each (`pattern`) and the cache policy (`cacheSeconds`,
`immutable` for its fingerprinted chunks) — and this front's content-type table, conditional requests
and containment checks serve them (onze front 69). No onze name or path is spelled here; the prefix
is whatever onze passes.

## Steps

### Step 1 — Roots, patterns and content types

```bp
pub type StaticRoot(
    pattern: string,
    directory: string,
    indexFile: string,
    cacheSeconds: i32,
    immutable: bool,
    useLastModified: bool,
    precompressed: bool,
)

pub fn registerStaticRoot(r: StaticRoot) -> i32
pub fn contentTypeOf(path: string) -> string
```

Defaults mirror `04 § Conteudo Estatico`: `/static/**` → `static/`, `/public/**` → `public/`, plus
`index.html` resolution for a directory request.

**Acceptance:**
- [x] A request matching no pattern falls through to the router with nothing changed — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] Two roots whose patterns overlap resolve in registration order, and the front documents that — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] `contentTypeOf` covers at minimum html, css, js, mjs, json, svg, png, jpeg, webp, avif, woff2, wasm, txt, xml, ico, map — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] An unknown extension answers `application/octet-stream`, never a guess — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] `.css` and `.js` carry `; charset=utf-8`; binary types do not — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] A directory request with no `indexFile` present answers 404, never a listing — there is no directory-listing mode and no configuration key that adds one — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`

### Step 2 — Containment

**Acceptance:**
- [x] `/static/../../etc/passwd` answers 404 and performs no filesystem call — asserted by a `stat` counter — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] `/static/%2e%2e%2fsecret` answers 404; a single percent-decode happens, and a doubly-encoded `%252e` answers 400 — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] A path containing a NUL byte answers 400 — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] A symlink inside the root pointing outside it answers 404 — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] A symlink inside the root pointing inside it is served — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] Every containment failure answers 404 — no case answers 403, and none distinguishes "exists but refused" from "does not exist" — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] An absolute path in the request (`/static//etc/passwd`) answers 404 — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`

### Step 3 — Conditional requests

**Acceptance:**
- [x] A first request answers 200 with an `ETag` — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] The same request with `If-None-Match` carrying that ETag answers 304 with no body and no `Content-Length` of the file — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] A changed file answers 200 with a different ETag — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] With `useLastModified: true`, `If-Modified-Since` at or after the mtime answers 304 — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] With `useLastModified: false`, no `Last-Modified` is emitted and `If-Modified-Since` is ignored — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] When both validators are present and disagree, the ETag decides — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] A 304 carries the same `Cache-Control` and `ETag` the 200 carried — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`

### Step 4 — Ranges and streaming

**Acceptance:**
- [x] `Range: bytes=0-99` answers 206 with `Content-Range: bytes 0-99/<size>` and exactly 100 bytes — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] `Range: bytes=100-` answers the tail — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] `Range: bytes=-100` answers the last 100 bytes — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] An unsatisfiable range answers 416 with `Content-Range: bytes */<size>` — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] A multi-range request answers 200 with the whole file — multipart ranges are not implemented, and the front says so rather than emitting a broken multipart body — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] `If-Range` with a stale ETag answers 200, not 206 — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] Every root answers `Accept-Ranges: bytes` — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] Serving a 200 MB file allocates no proportional memory in the VM — asserted by `erlang:memory(total)` before and after — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`

### Step 5 — Cache policy and fingerprints

**Acceptance:**
- [x] `immutable: true` emits `public, max-age=<cacheSeconds>, immutable` — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] `immutable: false` with `cacheSeconds: 0` emits `no-cache` — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] `fingerprint("app.css")` is stable for identical content and differs for one changed byte — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] A fingerprinted request for a file whose content no longer matches its name answers 404, not a stale file — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [ ] The dev property default from front 80 sets `cacheSeconds` to 0 for every root under a dev profile — open: the entry honours `rakun.web.resources.cache.period` (0 → `no-cache` on every root, `static_test.bp`); the dev-profile default that sets it is front 80's

### Step 6 — Encoding negotiation

**Acceptance:**
- [x] With `precompressed: true` and `app.css.br` present, `Accept-Encoding: br` answers the `.br` file with `Content-Encoding: br` and the *uncompressed* file's content type — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] With only `.gz` present and `Accept-Encoding: br, gzip`, the `.gz` is served — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] With neither variant present, the plain file is served with no `Content-Encoding` — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] Every response from a negotiating root carries `Vary: Accept-Encoding`, including the ones that did not compress — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] A variant whose mtime is older than the original is ignored and the original is served — a stale pre-compressed file is a wrong answer, not a fast one — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] `Accept-Encoding: br;q=0` does not select the `.br` variant — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`

## Examples

- [`examples/static-roots-example.bp`](./examples/static-roots-example.bp) — an application's static
  configuration, a fingerprinted `emilia` stylesheet, and the conditional-request and traversal
  assertions that make the policy falsifiable.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| There is no byte-string type: `fs.readText` answers `string`, every `String` method assumes text, and the type system cannot distinguish "these bytes are UTF-8" from "these bytes are a PNG". A binary asset therefore cannot be read, held or written back through botopink values. | `examples/static-roots-example.bp` — no example reads a file body at all; the front routes bytes through `rkSendFile` precisely because it cannot hold them | Hand the host a path and let `file:sendfile/5` write the socket; never bring the bytes into a botopink value | A `bytes` type with `fs.readBytes` / `fs.writeBytes`, length and slice but no text operations, so a binary body is expressible and a text operation on it does not compile |

## Test plan

`modules/rakun-web/test/static/`, run with `botopink test --target erlang` from
`modules/rakun-web/`, and in the gate as `zig build test-libs -- --target erlang --lib rakun`.

Fixtures are written into a scratch directory under `.botopinkbuild/tmp/` at test start — a text
file, a fingerprinted file, a `.br` and a `.gz` variant, a symlink inside the root, a symlink pointing
out of it, and a large sparse file for the streaming assertion. Nothing is checked into the
repository, because a checked-in symlink escaping a directory is a landmine in a git tree.

The traversal tests assert on a `stat` counter as well as on the status code: "answers 404" is not
the property under test, "answers 404 without touching the filesystem" is, and only the counter can
tell them apart.

The memory assertion in step 4 is the one test here with a real chance of flaking under a busy
scheduler. It compares `erlang:memory(total)` before and after against a generous ceiling — the
question is "is this proportional to file size", and a 200 MB file against a 4 MB ceiling answers it
without needing a tight bound.

This front is erlang-only. Serving a file is server work, and the client half of this milestone
consumes these URLs rather than implementing them.

## Definition of done

- [x] `modules/rakun-web/src/static/` exists and registers one filter in front 07's chain — `src/static.bp` (one file, not a directory), entry `static` at +150
- [ ] Traversal, encoded traversal and symlink escape all answer 404 without a filesystem call — traversal and encoded traversal: 404 with `rkStaticFsCalls()` unchanged (`static_test.bp`); a symlink escape is 404 but is found by resolving the link, which is a filesystem call by nature — open as worded
- [x] ETag-based conditional requests answer 304, and `Last-Modified` is off by default for a
      reproducible build — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] Ranges answer 206/416 correctly and a large file is streamed without a proportional allocation — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] Fingerprinted assets are `immutable`, unfingerprinted ones are `no-cache` — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] Pre-compressed variants are negotiated and every negotiating response carries `Vary` — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [x] No botopink value in this module ever holds a file body — `modules/rakun-web/test/static_test.bp`, rakun `3521aff`
- [ ] onze front 69's roots are served through `registerStaticRoot` with no second content-type table,
      ETag rule or traversal guard anywhere under `repository/` (`grep -rn "fn contentTypeOf"
      --include=*.bp repository/` finds only `modules/rakun-web/src/static/`) — the grep holds today (`src/static.bp:232` is the only one); onze registering its roots through `registerStaticRoot` is onze's half
- [x] `repository/rakun/AGENTS.md` documents the resolution order and why containment precedes `stat` — § Static files
- [x] The front's tests are green on its assigned target — rakun-web 209 / 0 on erlang

