# Front 03 — Std Content Hash

**Track:** A std
**Priority:** medium — the cache (front 12), the SSR pipeline (front 23) and both asset optimizers
(fronts 51, 52) each key on content, and each would otherwise invent its own hash
**Target:** both — std is the floor under both halves
**Wave:** 0
**Depends on:** none
**Owns:** `src/content_hash.bp`
**Does not touch:** every other std module, `crypto.bp` included — a std module cannot call another
std module, so this one re-declares the digest it needs. `src/root.bp` belongs to front 01; this
front hands it the line `pub mod content_hash;` and lands first.
**Reference:** `NEXTJS-DOCS.md § 11. Cache` · [Caching](https://nextjs.org/docs/app/getting-started/caching) · [`ETag`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) · [RFC 9110 § 8.8.3](https://www.rfc-editor.org/rfc/rfc9110#field.etag) · [`crypto:hash/2`](https://www.erlang.org/doc/apps/crypto/crypto.html#hash/2)
**Replaces:** `1.0.7-beta/18-std-crypto-hash`

---

## Problem

Four fronts in this milestone need to answer the question "is this the same content as last time?" —
the cache keys entries by it (front 12), the SSR pipeline puts it in an `ETag` (front 23), and the
image and font optimizers put it in a filename (fronts 51, 52). Nothing in std answers it. What std
has is `crypto.sha256` (`crypto.bp:22`), which is a 64-character hex string: correct, and the wrong
shape for a filename or a cache key, and slower than it needs to be for a value nobody is attacking.

What exists instead is a private copy: `emilia` carries its own djb2 fold as `hashHex`
(`repository/emilia/src/emilia.bp:40`), with a commonJS cell and an Erlang cell that were tuned until
they agreed byte-for-byte across targets. That function is the right primitive in the wrong place —
the moment front 12 needs a cache key it will either import from `emilia`, which is absurd, or write
a fifth copy of the same fold with its own subtly different rounding.

The 1.0.7 draft proposed lifting it, and got the interface wrong in a way that matters. Its example
key is `contentHash("user:123:profile")` — a hash over a string the caller built by joining parts
with a separator. `["user:1", "profile"]` and `["user", "1:profile"]` join to the same string, hash
to the same key, and a cache that collides across a user boundary serves one user their neighbour's
page. That is the repair this front carries: the multi-part key is framed, not joined, and the
separator-joined form is not offered at all.

## Current state

- **No `content_hash.bp`.** `libs/std/src/root.bp:13-36` does not list it.
- **`crypto.bp` has the strong digests and only in hex**: `sha256`, `sha512`, `md5`, `hmacSha256`,
  `randomBytes` (`crypto.bp:22-77`). Every one renders its output as lowercase hex inside the host
  template.
- **`emilia` has the fast one, privately**: `declare fn hashHex(s: string) -> string`
  (`repository/emilia/src/emilia.bp:40`), a djb2 fold with `#[@External.node]` and
  `#[@External.Erlang]` cells proven to agree for ASCII input. It is not `pub`, it is not in std, and
  its docblock notes that astral characters diverge (one codepoint on Erlang, two UTF-16 units in JS).
- **`json.bp` has no structured value**: `parse` and `stringify` are both `string -> @Result<string,
  string>` (`json.bp:36,45`), and the module docblock says there is no `JsonValue` walker yet
  (`json.bp:9-16`). The 1.0.7 draft's `contentHashObject(obj: any)` is therefore not expressible.
- **No std module imports another** — zero `import` lines across `libs/std/src/`. This front cannot
  call `crypto.sha256`; it re-declares the cell.

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
`declare fn`s with one cell per target in the `crypto.bp` shape. There is no sidecar.

## Steps

### Step 1 — `contentHash` and `strongHash`

```bp
//// std/content_hash — stable content hashes for cache keys, ETags and asset
//// fingerprints.
////
//// Reference:
////   RFC 9110 § 8.8.3 — https://www.rfc-editor.org/rfc/rfc9110#field.etag
////   Next.js caching  — https://nextjs.org/docs/app/getting-started/caching
////   Erlang crypto    — https://www.erlang.org/doc/apps/crypto/crypto.html
////
//// TWO hashes, and the choice is not a matter of taste. `contentHash` is a
//// djb2 fold rendered as 8 hex characters: fast, stable across both targets,
//// and TRIVIAL TO COLLIDE ON PURPOSE. Use it when a collision costs a wrong
//// cache hit you control — an asset filename, an internal fingerprint.
//// `strongHash` is SHA-256 truncated to 32 hex characters. Use it whenever the
//// hashed value came from outside: a request header, a client-supplied tag, a
//// key that spans a user boundary.
////
//// The `contentHash` templates are lifted verbatim from
//// `repository/emilia/src/emilia.bp:39-40`, where they were tuned until both
//// targets agreed byte-for-byte. Astral characters diverge (one codepoint on
//// Erlang, two UTF-16 units in JS) — the same caveat emilia carries.

#[@External.Node("""(function(__S){ var __H = 5381; for (var __I = 0; __I < __S.length; __I++) { __H = (Math.imul(__H, 33) + __S.charCodeAt(__I)) >>> 0; } return __H.toString(16); })($0)""")]
#[@External.Erlang("""(fun(__S) -> __H = lists:foldl(fun(__C, __A) -> (__A * 33 + __C) band 16#FFFFFFFF end, 5381, unicode:characters_to_list(__S)), list_to_binary(string:lowercase(integer_to_list(__H, 16))) end)($0)""")]
pub declare fn contentHash(value: string) -> string;

#[@External.Node("""require('crypto').createHash('sha256').update($0).digest('hex').slice(0, 32)""")]
#[@External.Erlang("""binary:part(string:lowercase(binary:encode_hex(crypto:hash(sha256, $0))), 0, 32)""")]
pub declare fn strongHash(value: string) -> string;
```

**Acceptance:**
- [ ] `contentHash("hello")` answers the same string on commonJS and on erlang
- [ ] `contentHash` of the same input twice in the same process answers the same string
- [ ] `contentHash("hello")` and `contentHash("world")` differ
- [ ] `contentHash("")` answers `1505` (djb2's seed) on both targets rather than an empty string
- [ ] `strongHash("")` answers the first 32 hex characters of the empty-string SHA-256, on both targets
- [ ] the templates are character-identical to `emilia.bp:39-40` apart from the `__`-prefixed variable names

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
- [ ] `cacheKey(["user:1", "profile"]) != cacheKey(["user", "1:profile"])`
- [ ] `cacheKey(["a"]) != cacheKey(["a", ""])`
- [ ] `cacheKey([])` answers a stable value rather than failing
- [ ] `cacheKey` of the same parts answers the same key on both targets
- [ ] no function in the module joins parts without framing them

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
    val exact = candidates.contains(current);
    val loose = candidates.contains(weak);
    val hit = if (exact) true else loose;
    return if (wildcard) true else hit;
}
```

**Acceptance:**
- [ ] `etag(b)` starts and ends with `"` and contains exactly one hash
- [ ] `matches(b, etag(b))` is true; `matches(b, etag(b + "x"))` is false
- [ ] `matches(b, "*")` is true for any body
- [ ] `matches(b, "\"aaa\", " + etag(b))` is true — the candidate list is split and trimmed
- [ ] `matches(b, "")` is false rather than true

### Step 4 — Fingerprints

```bp
// `app.js` → `app.3f2a91c7.js`. The extension stays last: a browser and a CDN
// both dispatch on it, and a hash appended after it breaks both.
pub fn fingerprint(fileName: string, contents: string) -> string {
    val hash = contentHash(contents);
    val dot = fileName.lastIndexOf(".");
    val hasExt = dot > 0;
    val stem = if (hasExt) fileName.slice(0, dot) else fileName;
    val ext = if (hasExt) fileName.slice(dot, fileName.length()) else "";
    return stem + "." + hash + ext;
}
```

**Acceptance:**
- [ ] `fingerprint("app.js", c)` matches `app.<hash>.js`
- [ ] `fingerprint("LICENSE", c)` answers `LICENSE.<hash>` — no trailing dot
- [ ] `fingerprint(".gitignore", c)` does not treat the leading dot as an extension boundary
- [ ] the same contents answer the same filename on both targets
- [ ] different contents answer different filenames for the same input name

### Step 5 — export line and docs

`pub mod content_hash;` handed to front 01 (which owns `src/root.bp`), and `libs/std/AGENTS.md`'s
tree listing gains `content_hash.bp`.

**Acceptance:**
- [ ] `import {content_hash} from "std";` resolves from a consumer package
- [ ] `libs/std/AGENTS.md` names the file in the same commit that adds it
- [ ] a note in the module docblock records that `emilia.hashHex` is now a duplicate and that
      collapsing it is a later, `emilia`-owned change — this milestone is additive only

## Examples

- [`examples/cache-key-and-etag-example.bp`](./examples/cache-key-and-etag-example.bp) — one request
  handler carrying all four uses: a framed cache key, a conditional-GET ETag check, an asset
  fingerprint, and the strong/weak choice at a trust boundary.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No bitwise operators and no `toString(radix)` on the integer behaviors | the djb2 fold needs `band 16#FFFFFFFF` and a base-16 rendering | do the fold and the rendering inside the host template — which is why `contentHash` is a `declare fn` and not four lines of `.bp` | `&`, `\|`, `^`, `<<`, `>>` on `Integer`, plus `fn toStringRadix(self: Self, radix: i32) -> string` |
| Consequence of the row above: `contentHash` cannot run on the wat or BEAM backends | `src/content_hash.bp` as a whole | accept two-target coverage; `cacheKey`, `etag` and `fingerprint` are pure `.bp` and would work everywhere if the hash did | the same |
| `std/json` has no structured value — `parse`/`stringify` are both `string -> @Result<string, string>` (`json.bp:36,45`) | the 1.0.7 draft's `contentHashObject(obj: any)`, dropped from this front's surface | hash the serialized string the caller already has, and frame multi-part keys with `cacheKey` | a `JsonValue` enum with a walker, so a hash can be taken over a canonical serialization rather than whatever the caller passed |

## Test plan

Inline `test` blocks at the bottom of `src/content_hash.bp`, run by `botopink test --target commonJS`
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

- `src/content_hash.bp` exists with `contentHash`, `strongHash`, `cacheKey`, `strongCacheKey`,
  `etag`, `weakEtag`, `matches` and `fingerprint`.
- The two hash functions answer byte-identical output on commonJS and erlang, pinned by literal
  expectations in the tests.
- No function in the module builds a multi-part key by joining without framing.
- `pub mod content_hash;` is handed to front 01 and appears in `src/root.bp`.
- `libs/std/AGENTS.md` names `content_hash.bp`, and the docblock records the `emilia.hashHex`
  duplication as a later `emilia`-owned change.
- Every `// LANGUAGE GAP:` marker in the example appears in the table above.
- The front's tests are green on its assigned target — here, both.
