# Front 03 — Std Content Hash

**Track:** A std
**Priority:** medium — the cache (front 12), the SSR pipeline (front 23) and both asset optimizers
(fronts 51, 52) each key on content, and each would otherwise invent its own hash
**Target:** both — std is the floor under both halves
**Wave:** 0
**Depends on:** none
**Owns:** `src/content_hash.bp` — `contentHash`, `strongHash`, `cacheKey`, `strongCacheKey`, `etag`, `weakEtag`, `matches`, `fingerprint` — and its `pub mod content_hash;` line in `src/root.bp`. It is the content-hash half of `hash.bp` (decision 106); `00-compiler-carry-over/23-std-purity` folds it under the digests
**Does not touch:** every other std module, and every function already in `hash.bp` (`sha256`, `sha512`, `md5`, `hmacSha256`; front 01's `hmacSha256Base64Url`, `sha1Base64`, `sha256Base64Url`, `equalsConstantTime`). `strongHash` keeps its own cell as written below; the truncation lives in the template.
**Reference:** `NEXTJS-DOCS.md § 11. Cache` · [Caching](https://nextjs.org/docs/app/getting-started/caching) · [`ETag`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) · [RFC 9110 § 8.8.3](https://www.rfc-editor.org/rfc/rfc9110#field.etag) · [`crypto:hash/2`](https://www.erlang.org/doc/apps/crypto/crypto.html#hash/2)

---

## Problem

Four fronts in this milestone need to answer the question "is this the same content as last time?" —
the cache keys entries by it (front 12), the SSR pipeline puts it in an `ETag` (front 23), and the
image and font optimizers put it in a filename (fronts 51, 52). Nothing in std answers it. What std
has is `sha256` (`crypto.bp:22`), which is a 64-character hex string: correct, and the wrong shape
for a filename or a cache key, and slower than it needs to be for a value nobody is attacking.

What exists instead is a private copy: `emilia` carries its own djb2 fold as `hashHex`
(`repository/emilia/src/emilia.bp:40`), with a commonJS cell and an Erlang cell that were tuned until
they agreed byte-for-byte across targets. That function is the right primitive in the wrong place —
the moment front 12 needs a cache key it will either import from `emilia`, which is absurd, or write
a fifth copy of the same fold with its own subtly different rounding.

A multi-part key must be framed, not joined: `["user:1", "profile"]` and `["user", "1:profile"]`
join to the same string, hash to the same key, and a cache that collides across a user boundary
serves one user their neighbour's page. The separator-joined form is not offered at all.

## Current state

- **The digests stay hex-only.** The digest half of `hash.bp` (`crypto.bp:22-77` today) has `sha256`,
  `sha512`, `md5`, `hmacSha256`, and only in hex: every one renders its output as lowercase hex inside
  the host template.
- **`emilia` has the fast one, privately**: `declare fn hashHex(s: string) -> string`
  (`repository/emilia/src/emilia.bp:40`), a djb2 fold with `#[@External.node]` and
  `#[@External.Erlang]` cells proven to agree for ASCII input. It is not `pub`, it is not in std, and
  its docblock notes that astral characters diverge (one codepoint on Erlang, two UTF-16 units in JS).
- **`json.bp` has no structured value**: `parse` and `stringify` are both `string -> @Result<string,
  string>` (`json.bp:36,45`), and the module docblock says there is no `JsonValue` walker yet
  (`json.bp:9-16`). A `contentHashObject(obj: any)` is therefore not expressible.
- **No std module imports another** — zero `import` lines across `libs/std/src/`. `content_hash.bp`
  therefore cannot call `crypto.sha256`: `strongHash` carries its own SHA-256 cell, with the
  truncation in the template.

## Mechanism

Two hashes, one interface, and a rule for choosing between them that the docblock states rather than
leaving to taste.

**`contentHash` is djb2, rendered as hex, lifted verbatim from `emilia.bp:39-40`.** Verbatim is the
point: those two templates were tuned until the commonJS and Erlang cells produced the same hex for
the same input, which is the property the whole front rests on. Re-deriving them would be re-earning
a guarantee that already exists. It is fast, it is 8 hex characters, it is what belongs in a filename
and in an internal cache key, and it is not a security boundary: a caller who can choose the input
can find a collision in seconds.

**`strongHash` is SHA-256, truncated to 32 hex characters.** Used when the hashed value is
attacker-controlled and a collision means serving the wrong response to the wrong person — a cache
key that includes a request header, a tag a client supplies. The docblock says which is which, and
the two functions have different names precisely so that the choice is visible at the call site.

**Multi-part keys are framed, not joined.** `cacheKey(parts)` prefixes each part with its own length
before hashing — `["user:1", "profile"]` becomes `6:user:1|7:profile`, `["user", "1:profile"]`
becomes `4:user|9:1:profile`, and no two different part lists can produce the same framed string.
This is pure botopink over `String.length()` and `+`, so it runs everywhere `contentHash` does.

**ETags carry their RFC 9110 syntax in the primitive.** `etag(body)` answers `"<hash>"` *with the
quotes*, because an unquoted ETag is a protocol violation and a caller who has to remember to add
them is a caller who will forget. `weakEtag` answers `W/"<hash>"`. `matches(body, ifNoneMatch)` is
the 304 decision, and it handles the three cases a handler actually sees: an exact match, the `*`
wildcard, and a comma-separated list of candidates.

**Fingerprints keep the extension.** `fingerprint("app.js", contents)` answers `app.<hash>.js`, not
`app.js.<hash>` — a browser and a CDN both dispatch on the extension, and a hash appended after it
breaks both.

Every one of these is pure botopink except `contentHash` and `strongHash` themselves, which are
`declare fn`s with one cell per target in the shape of the digests above them. There is no sidecar.

**Where the functions sit.** The eight functions sit flat in `content_hash.bp`, registered by
`pub mod content_hash;` in `root.bp`; the pure ones call `contentHash`/`strongHash` unqualified, as
functions of the same file. A consumer writes `import {content_hash, crypto} from "std";` and
`content_hash.cacheKey(…)`, `content_hash.etag(…)`, next to `crypto.sha256(…)`. Front 23 folds the
file into `hash.bp`, and the consumer spelling becomes `hash.cacheKey(…)`.

## Steps

### Step 1 — `contentHash` and `strongHash`

```bp
// ── content hashes — stable hashes for cache keys, ETags and asset fingerprints ──
//
// Reference:
//   RFC 9110 § 8.8.3 — https://www.rfc-editor.org/rfc/rfc9110#field.etag
//   Next.js caching  — https://nextjs.org/docs/app/getting-started/caching
//
// TWO hashes, and the choice is not a matter of taste. `contentHash` is a
// djb2 fold rendered as 8 hex characters: fast, stable across both targets,
// and TRIVIAL TO COLLIDE ON PURPOSE. Use it when a collision costs a wrong
// cache hit you control — an asset filename, an internal fingerprint.
// `strongHash` is SHA-256 truncated to 32 hex characters. Use it whenever the
// hashed value came from outside: a request header, a client-supplied tag, a
// key that spans a user boundary.
//
// The `contentHash` templates are lifted verbatim from
// `repository/emilia/src/emilia.bp:39-40`, where they were tuned until both
// targets agreed byte-for-byte. Astral characters diverge (one codepoint on
// Erlang, two UTF-16 units in JS) — the same caveat emilia carries.

#[@External.Node("""(function(__S){ var __H = 5381; for (var __I = 0; __I < __S.length; __I++) { __H = (Math.imul(__H, 33) + __S.charCodeAt(__I)) >>> 0; } return __H.toString(16); })($0)""")]
#[@External.Erlang("""(fun(__S) -> __H = lists:foldl(fun(__C, __A) -> (__A * 33 + __C) band 16#FFFFFFFF end, 5381, unicode:characters_to_list(__S)), list_to_binary(string:lowercase(integer_to_list(__H, 16))) end)($0)""")]
pub declare fn contentHash(value: string) -> string;

#[@External.Node("""require('crypto').createHash('sha256').update($0).digest('hex').slice(0, 32)""")]
#[@External.Erlang("""binary:part(string:lowercase(binary:encode_hex(crypto:hash(sha256, $0))), 0, 32)""")]
pub declare fn strongHash(value: string) -> string;
```

**Acceptance:**
- [x] `contentHash("hello")` answers the same string on commonJS and on erlang
- [x] `contentHash` of the same input twice in the same process answers the same string
- [x] `contentHash("hello")` and `contentHash("world")` differ
- [x] `contentHash("")` answers `1505` (djb2's seed) on both targets rather than an empty string
- [x] `strongHash("")` answers the first 32 hex characters of the empty-string SHA-256, on both targets
- [x] the templates are character-identical to `emilia.bp:39-40` apart from the `__`-prefixed variable names

### Step 2 — `cacheKey`, framed

```bp
// A key over several parts. Each part is length-prefixed, so no two different
// part lists can collide: ["user:1", "profile"] and ["user", "1:profile"] frame
// to different strings and therefore hash to different keys. A cache that
// collides across a user boundary serves one user another user's page, so the
// framing is the whole reason this function exists instead of a `join`.
pub fn cacheKey(parts: string[]) -> string {
    val framed = parts.map({ p -> p.length().toString() + ":" + p }).join("|");
    return contentHash(framed);
}

// The same framing over the strong hash, for keys built from input the caller
// did not choose.
pub fn strongCacheKey(parts: string[]) -> string {
    val framed = parts.map({ p -> p.length().toString() + ":" + p }).join("|");
    return strongHash(framed);
}
```

**Acceptance:**
- [x] `cacheKey(["user:1", "profile"]) != cacheKey(["user", "1:profile"])`
- [x] `cacheKey(["a"]) != cacheKey(["a", ""])`
- [x] `cacheKey([])` answers a stable value rather than failing
- [x] `cacheKey` of the same parts answers the same key on both targets
- [x] no function in the module joins parts without framing them

### Step 3 — ETags

```bp
// A strong ETag, quoted as RFC 9110 requires. The quotes are part of the value:
// a caller who has to remember to add them is a caller who will forget.
pub fn etag(body: string) -> string {
    return "\"" + contentHash(body) + "\"";
}

pub fn weakEtag(body: string) -> string {
    return "W/\"" + contentHash(body) + "\"";
}

// The 304 decision. Handles the three shapes a handler actually receives: an
// exact match, the `*` wildcard, and a comma-separated candidate list.
pub fn matches(body: string, ifNoneMatch: string) -> bool {
    val header = ifNoneMatch.trim();
    val wildcard = header == "*";
    val current = etag(body);
    val weak = weakEtag(body);
    val candidates = header.split(",").map({ c -> c.trim() });
    // `indexOf`, not `Array.contains`: `contains` is a `default fn`, which a
    // consumer's embedded copy of a std module emits verbatim on commonJS
    // (`libs/std/AGENTS.md` § Conventions).
    val exact = candidates.indexOf(current) != -1;
    val loose = candidates.indexOf(weak) != -1;
    val hit = if (exact) true else loose;
    return if (wildcard) true else hit;
}
```

**Acceptance:**
- [x] `etag(b)` starts and ends with `"` and contains exactly one hash
- [x] `matches(b, etag(b))` is true; `matches(b, etag(b + "x"))` is false
- [x] `matches(b, "*")` is true for any body
- [x] `matches(b, "\"aaa\", " + etag(b))` is true — the candidate list is split and trimmed
- [x] `matches(b, "")` is false rather than true

### Step 4 — Fingerprints

```bp
// `app.js` → `app.3f2a91c7.js`. The extension stays last: a browser and a CDN
// both dispatch on it, and a hash appended after it breaks both.
//
// The extension is measured as the last `.`-separated piece rather than found
// with `lastIndexOf`: on Erlang `lastIndexOf` answers a BYTE offset while
// `length`/`slice` count characters, so a non-ASCII stem would be cut in the
// wrong place.
pub fn fingerprint(fileName: string, contents: string) -> string {
    val hash = contentHash(contents);
    val pieces = fileName.split(".");
    val tail = pieces.at(pieces.length - 1);
    val extLen = if (tail != null) tail.length() + 1 else 0;
    val hasExt = if (pieces.length > 1) extLen < fileName.length() else false;
    val cut = fileName.length() - extLen;
    val stem = if (hasExt) fileName.slice(0, cut) else fileName;
    val ext = if (hasExt) fileName.slice(cut, fileName.length()) else "";
    return stem + "." + hash + ext;
}
```

**Acceptance:**
- [x] `fingerprint("app.js", c)` matches `app.<hash>.js`
- [x] `fingerprint("LICENSE", c)` answers `LICENSE.<hash>` — no trailing dot
- [x] `fingerprint(".gitignore", c)` does not treat the leading dot as an extension boundary
- [x] the same contents answer the same filename on both targets
- [x] different contents answer different filenames for the same input name

### Step 5 — docs

The front sits flat in `src/content_hash.bp`, registered by `pub mod content_hash;` in `src/root.bp`,
and `00-compiler-carry-over/23-std-purity` folds it into `hash.bp`. `libs/std/AGENTS.md`'s
`content_hash` row names the eight functions.

**Acceptance:**
- [x] `import {content_hash, crypto} from "std";` resolves from a consumer package and `content_hash.cacheKey`, `content_hash.etag`, `content_hash.fingerprint` type-check and run beside `crypto.sha256`, on both targets (the example below runs 6/6 on each)
- [x] `libs/std/AGENTS.md` lists the functions in the same commit that adds them
- [x] a note in the section comment records that `emilia.hashHex` is now a duplicate and that
      collapsing it is a later, `emilia`-owned change — this milestone is additive only

## Examples

- [`examples/cache-key-and-etag-example.bp`](./examples/cache-key-and-etag-example.bp) — one request
  handler carrying all four uses: a framed cache key, a conditional-GET ETag check, an asset
  fingerprint, and the strong/weak choice at a trust boundary.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No bitwise operators and no `toString(radix)` on the integer behaviors | the djb2 fold needs `band 16#FFFFFFFF` and a base-16 rendering | do the fold and the rendering inside the host template — which is why `contentHash` is a `declare fn` and not four lines of `.bp` | `&`, `\|`, `^`, `<<`, `>>` on `Integer`, plus `fn toStringRadix(self: Self, radix: i32) -> string` |
| Consequence of the row above: `contentHash` cannot run on the wat or BEAM backends | `src/content_hash.bp` | accept two-target coverage; `cacheKey`, `etag` and `fingerprint` are pure `.bp` and would work everywhere if the hash did | the same |
| `std/json` has no structured value — `parse`/`stringify` are both `string -> @Result<string, string>` (`json.bp:36,45`) | a `contentHashObject(obj: any)` — not in this front's surface | hash the serialized string the caller already has, and frame multi-part keys with `cacheKey` | a `JsonValue` enum with a walker, so a hash can be taken over a canonical serialization rather than whatever the caller passed |

## Test plan

Inline `test` blocks at the bottom of `src/content_hash.bp`, suite `content_hash.`, run by `botopink test --target commonJS`
and `--target erlang` from `libs/std/`, and by `zig build test-libs` as part of the ecosystem gate.
Every test here is deterministic — no clock, no filesystem, no network — which makes this the
cheapest front in track A to keep green and the one whose failures always mean something.

The suite asserts four things:

- **Stability** — the same input answers the same hash within a run and between runs.
- **Cross-target agreement** — the expected hex for a fixed input is written into the test as a
  literal, not compared against a second call. A literal is the only form that catches the two
  targets drifting apart, which is the exact failure mode `emilia` tuned its templates to avoid.
- **Framing** — the two colliding part lists from the *Problem* section answer different keys. This
  test is the front's reason to exist and is written first.
- **Protocol shape** — `etag` is quoted, `weakEtag` carries `W/`, `matches` handles `*` and a
  candidate list, and `fingerprint` keeps the extension last.

There is no target whose coverage is partial: both cells of both hashes are exercised on both
backends.

## Definition of done

- `src/content_hash.bp` carries `contentHash`, `strongHash`, `cacheKey`, `strongCacheKey`, `etag`,
  `weakEtag`, `matches` and `fingerprint`.
- The two hash functions answer byte-identical output on commonJS and erlang, pinned by literal
  expectations in the tests.
- No function in the module builds a multi-part key by joining without framing.
- `libs/std/AGENTS.md`'s `content_hash` row names the eight functions, and the section comment records the
  `emilia.hashHex` duplication as a later `emilia`-owned change.
- Every `// LANGUAGE GAP:` marker in the example appears in the table above.
- The front's tests are green on its assigned target — here, both.
