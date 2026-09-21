# Front 18 — Std Content Hash

**Referência Next.js:** [Caching](https://nextjs.org/docs/app/getting-started/caching) · [ETags](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag)

**Priority:** low — content hashing is needed for cache keys and ETags
**Depends on:** none
**Owns:** `libs/std/src/content_hash.bp`
**Does not touch:** any other std modules

---

## Problem

Cache keys and ETags need stable content hashes. The std lib has `crypto.sha256` but no simple content-hash utility for cache keys.

## Current state

- std has `crypto.sha256`, `crypto.md5`
- No simple `contentHash(value)` for cache keys
- Emilia has its own `hashHex` (djb2)

## Mechanism

Add a simple content hash utility:

```bp
import {contentHash} from "std";

val key = contentHash("user:123");  // "a1b2c3d4"
```

## Exemplos em bp

### Cache key generation

```bp
import {contentHash} from "std";

val key = contentHash("user:123:profile");
// → "a1b2c3d4"
```

### ETag

```bp
#[@future]
pub fn GET(request: Request) -> @Future<Response> {
    val data = await fetchData();
    val etag = contentHash(json.stringify(data));
    return Response.json(json.stringify(data)).withHeader("ETag", etag);
}
```

## Steps

### Step 1 — contentHash function

```bp
// libs/std/src/content_hash.bp
pub fn contentHash(value: string) -> string {
    // djb2 hash (same as emilia)
    // Returns hex string
}
```

**Acceptance:**
- [ ] `contentHash` produces stable hex strings
- [ ] Same input → same output
- [ ] Different input → different output (mostly)

### Step 2 — contentHash for objects

```bp
pub fn contentHashObject(obj: any) -> string {
    val json = json.stringify(obj);
    return contentHash(json);
}
```

**Acceptance:**
- [ ] Objects are serialized to JSON
- [ ] JSON is hashed

### Step 3 — Tests

```bp
test "contentHash is stable" {
    assert contentHash("hello") == contentHash("hello");
}

test "contentHash differs for different inputs" {
    assert contentHash("hello") != contentHash("world");
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `content_hash.bp` in `root.bp`
- [ ] AGENTS.md updated
- [ ] Commit on `fix/std-crypto-hash`

## Blast radius

- New file `content_hash.bp`
- No changes to existing std modules
- Cache layer can use content hashing

## Notes

- Uses djb2 (same as emilia) for consistency.
- Future: could use SHA-256 for stronger guarantees, but djb2 is faster for cache keys.
