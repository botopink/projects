# Front 03 — Std Content Hash

**Track:** A std
**Priority:** medium — the cache (front 12), the SSR pipeline (front 23) and both asset optimizers
(fronts 51, 52) each key on content, and each would otherwise invent its own hash
**Target:** both — std is the floor under both halves
**Owns:** the content hashes of `src/hash.bp` — `contentHash`, `strongHash`, `cacheKey`, `strongCacheKey`, `etag`, `weakEtag`, `matches`, `fingerprint` (decision 106 puts them beside the digests)
**Does not touch:** every other std module, and the digests of `hash.bp` (`sha256`, `sha512`, `md5`, `hmacSha256`, and front 01's `hmacSha256Base64Url`, `sha1Base64`, `sha256Base64Url`, `equalsConstantTime`)
**Reference:** `NEXTJS-DOCS.md § 11. Cache` · [Caching](https://nextjs.org/docs/app/getting-started/caching) · [`ETag`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) · [RFC 9110 § 8.8.3](https://www.rfc-editor.org/rfc/rfc9110#field.etag) · [`crypto:hash/2`](https://www.erlang.org/doc/apps/crypto/crypto.html#hash/2)

---

## Problem

Four fronts need to answer "is this the same content as last time?" — the cache keys entries by it
(front 12), the SSR pipeline puts it in an `ETag` (front 23), and the image and font optimizers put
it in a filename (fronts 51, 52). `sha256` is a 64-character hex string: correct, and the wrong shape
for a filename or a cache key, and slower than it needs to be for a value nobody is attacking.

A multi-part key must be framed, not joined: `["user:1", "profile"]` and `["user", "1:profile"]`
join to the same string, hash to the same key, and a cache that collides across a user boundary
serves one user their neighbour's page. The separator-joined form is not offered at all.

## The surface

`import {hash} from "std";` — the functions sit in `hash.bp` beside the digests.

```bp
pub declare fn contentHash(value: string) -> string     // djb2, 8 hex characters
pub declare fn strongHash(value: string) -> string      // SHA-256, first 32 hex characters
pub fn cacheKey(parts: string[]) -> string              // framed, over contentHash
pub fn strongCacheKey(parts: string[]) -> string        // framed, over strongHash
pub fn etag(body: string) -> string                     // "\"<hash>\"" — quoted
pub fn weakEtag(body: string) -> string                 // "W/\"<hash>\""
pub fn matches(body: string, ifNoneMatch: string) -> bool
pub fn fingerprint(fileName: string, contents: string) -> string   // app.js → app.<hash>.js
```

**`contentHash` is djb2, rendered as hex**, with the Node and Erlang templates emilia tuned until
both targets produced the same hex for the same input (astral characters diverge: one codepoint on
Erlang, two UTF-16 units in JS). It is fast, 8 hex characters, what belongs in a filename and an
internal cache key, and **not** a security boundary: a caller who can choose the input can find a
collision in seconds.

**`strongHash` is SHA-256, truncated to 32 hex characters**, for a hashed value that is
attacker-controlled — a cache key that includes a request header, a tag a client supplies. The two
functions have different names so the choice is visible at the call site; the section comment says
which is which.

**Multi-part keys are framed.** `cacheKey(parts)` prefixes each part with its length before hashing —
`["user:1", "profile"]` becomes `6:user:1|7:profile`, `["user", "1:profile"]` becomes
`4:user|9:1:profile` — so no two different part lists produce the same framed string. Pure botopink.

**ETags carry their RFC 9110 syntax.** `etag(body)` answers `"<hash>"` *with the quotes*; `weakEtag`
answers `W/"<hash>"`. `matches(body, ifNoneMatch)` is the 304 decision over an exact match, the `*`
wildcard and a comma-separated candidate list (read with `indexOf`, not the `Array.contains`
`default fn` a consumer's embedded copy would emit verbatim).

**Fingerprints keep the extension.** `fingerprint("app.js", contents)` answers `app.<hash>.js` — a
browser and a CDN both dispatch on the extension. The extension is measured as the last
`.`-separated piece rather than with `lastIndexOf`, which answers a byte offset on Erlang.

Everything but `contentHash` and `strongHash` is pure botopink; the two are `declare fn`s with one
cell per target. There is no sidecar.

## Delivered

- [x] `contentHash("hello")` answers the same string on commonJS and on erlang, twice in a process the same, and differs from `contentHash("world")`
- [x] `contentHash("")` answers `1505` (djb2's seed) on both targets rather than an empty string
- [x] `strongHash("")` answers the first 32 hex characters of the empty-string SHA-256, on both targets
- [x] the `contentHash` templates are character-identical to emilia's `hashHex` apart from the `__`-prefixed variable names
- [x] `cacheKey(["user:1", "profile"]) != cacheKey(["user", "1:profile"])`; `cacheKey(["a"]) != cacheKey(["a", ""])`; `cacheKey([])` answers a stable value; the same parts answer the same key on both targets; no function joins parts without framing them
- [x] `etag(b)` starts and ends with `"` and contains exactly one hash
- [x] `matches(b, etag(b))` is true; `matches(b, etag(b + "x"))` is false; `matches(b, "*")` is true; `matches(b, "\"aaa\", " + etag(b))` is true; `matches(b, "")` is false
- [x] `fingerprint("app.js", c)` matches `app.<hash>.js`; `fingerprint("LICENSE", c)` answers `LICENSE.<hash>`; `fingerprint(".gitignore", c)` does not treat the leading dot as an extension boundary; the same contents answer the same filename on both targets
- [x] `libs/std/AGENTS.md` lists the functions, and the section comment records that emilia's `hashHex` duplicates `contentHash`

The box that imported the functions as `content_hash` beside `crypto` left with decision 106: the
consumer spelling is `hash.cacheKey(…)`, `hash.etag(…)` beside `hash.sha256(…)`.

Still owed, by emilia and onze (decision 116 rule 7): emilia's class-name hash and onze front 68's
recomputation call `contentHash`, and emilia's private `hashHex` is deleted.

## Examples

- [`examples/cache-key-and-etag-example.bp`](./examples/cache-key-and-etag-example.bp) — one request
  handler carrying all four uses: a framed cache key, a conditional-GET ETag check, an asset
  fingerprint, and the strong/weak choice at a trust boundary.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No bitwise operators and no `toString(radix)` on the integer behaviors | the djb2 fold needs `band 16#FFFFFFFF` and a base-16 rendering | do the fold and the rendering inside the host template — which is why `contentHash` is a `declare fn` | `&`, `\|`, `^`, `<<`, `>>` on `Integer`, plus `fn toStringRadix(self: Self, radix: i32) -> string` |
| Consequence of the row above: `contentHash` cannot run on the wat or BEAM backends | `hash.bp` | accept two-target coverage; `cacheKey`, `etag` and `fingerprint` are pure `.bp` and would work everywhere if the hash did | the same |

## Test plan

Inline `test` blocks at the foot of `src/hash.bp`, run by `botopink test --target commonJS` and
`--target erlang` from `libs/std/`, and by `zig build test-libs`. Deterministic — no clock, no
filesystem, no network. They assert stability, cross-target agreement (the expected hex is a
literal, not a second call), framing (the two colliding part lists answer different keys), and
protocol shape (`etag` quoted, `weakEtag` with `W/`, `matches` over `*` and a list, `fingerprint`
keeping the extension last).
