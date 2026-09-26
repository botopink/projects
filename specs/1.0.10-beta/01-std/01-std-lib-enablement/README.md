# Front 01 — Std Lib Enablement

**Track:** A std
**Priority:** critical — the milestone's fronts bottom out in a socket, a clock, a path, a digest or an escape; this front puts each one in std, dual-target, instead of a private `#[@External.Node]` cell per front
**Target:** both — std is the floor under both halves
**Owns:** `src/io/net.bp`, `src/escape.bp`; the base64url digests of `src/hash.bp`; the codec half of `src/encoding.bp`; the functions it added to `src/path.bp`, `src/io/fs.bp` (`walk`, `glob`), `src/io/clock.bp`, `src/io/random.bp`, `src/regex.bp`, `src/io/process.bp`; `json.bp`'s writers, `Json` and `decode` (Steps 11–14). Paths are the tree of `../modules.md` (decision 106)
**Does not touch:** `src/primitives.bp`, `src/builtins.d.bp`, `src/builtins_fns.d.bp` (the three ambient files); the functions that predate it in the modules it extends; `querystring.bp`, `url.bp`, `io/env.bp`, `io/os.bp`, `io/http.bp`, `erlang.bp`, `beam.bp`, `collections.bp`, `math.bp`, `string_builder.bp`, `unicode.bp`, `async.bp`, `testing/**`
**Reference:** Erlang/OTP — [`gen_tcp`](https://www.erlang.org/doc/apps/kernel/gen_tcp.html) · [`ssl`](https://www.erlang.org/doc/apps/ssl/ssl.html) · [`crypto`](https://www.erlang.org/doc/apps/crypto/crypto.html) · [`re`](https://www.erlang.org/doc/apps/stdlib/re.html) · [`filelib`](https://www.erlang.org/doc/apps/stdlib/filelib.html) · [`filename`](https://www.erlang.org/doc/apps/stdlib/filename.html) · [`calendar`](https://www.erlang.org/doc/apps/stdlib/calendar.html) · [`uri_string`](https://www.erlang.org/doc/apps/stdlib/uri_string.html). Node.js — [`net`](https://nodejs.org/api/net.html) · [`tls`](https://nodejs.org/api/tls.html) · [`child_process`](https://nodejs.org/api/child_process.html) · [`crypto`](https://nodejs.org/api/crypto.html) · [`path`](https://nodejs.org/api/path.html)

---

## State

Steps 1–13 hold. Step 14 holds for jhonstart and emilia; open: rakun's copies, which rakun's
fronts close.

Two of the primitives are security requirements rather than conveniences. `escape.html` is what
stands between the SSR pipeline (front 23) and a stored-XSS hole. `hash.equalsConstantTime` is what
stands between the session-cookie check (front 18) and a byte-at-a-time signature oracle; `==` on two
signature strings is a timing side channel on both backends.

## The surface

| Module | What this front put there | Needed by front(s) | Server-only? |
|---|---|---|---|
| `io/net` | `listen(port, backlog)`, `connect(host, port, timeoutMillis)`, `tlsListen(port, certFile, keyFile)`, `tlsConnect(host, port, caFile, timeoutMillis)`; the methods of `Listener` (`port`, `accept(timeoutMillis)`, `close`), `Socket` (`recv(length, timeoutMillis)`, `send(data)`, `close`, `peer`), `TlsListener`, `TlsSocket`; `Peer(host, port)` | 04, 07, 08, 09, 10, 13, 15, 17, 20 | **yes** |
| `io/clock` | `parseIso8601`, `toCivil` → `Civil`, `offsetMinutes`, `Duration` + `millis`/`seconds`/`minutes`/`hours`/`add`/`toMillis`, `sleep`, `deadline`, `isExpired` | 11, 12, 16, 17, 18, 19, 32 | no |
| `io/process` | `run(cmd, args) -> @Result<Exit, string>` (`Exit(status, stdout, stderr)`), `runShell(cmd)` | 50, 51, 52 | no |
| `path` | `withoutExtension`, `isInside` (the traversal guard) | 22, 25, 51, 52 | no |
| `io/fs` | `walk(root)`, `glob(pattern, root)` | 22, 50 | no |
| `io/random` | `secureToken(bytes)` (base64url), `uuidV4()` | 10, 17, 18 | no |
| `regex` | `Regex` with the method `matches(input)`, `compile`, `captures`, `namedCaptures`, `escapeLiteral` | 07, 14, 22 | no |
| `encoding` | `hexEncode`/`hexDecode`, `percentEncode`/`percentDecode`, `formStringify`/`formParse` (percent-aware) | 03, 07, 10, 13, 22, 24, 25 | no |
| `hash` | `hmacSha256Base64Url`, `sha1Base64`, `sha256Base64Url`, `equalsConstantTime` | 03, 10, 18, 20 | no |
| `escape` | `html`, `attribute`, `unescapeHtml`, `jsString`, `scriptJson` | 23, 24, 25, 32, 48 | no |
| `json` | `quote`, `unquote`, `array`, `object`, `Json`, `decode` | rakun 05, `05-actions-lib`, `06-validation-lib`, jhonstart 30 | no |

## Mechanism

**A std module cannot call another std module.** A cross-module bare import of an `#[@External.*]`
symbol resolves at type level and is `undefined` at run time. Decision 106 puts each addition in
the file that already holds what it extends, so nothing re-declares a sibling's cell; where two cells
in one file call the same host function, the duplication is in the template string, not in
behaviour.

**Every host call is a `declare fn` with one cell per target** — a `////` docblock naming both
upstream APIs, a `//` comment per fn explaining the two templates, the annotations, the bodyless
`declare fn`, in the shape of `io/fs.bp`. A host function that has an owner is a method inside its
type body (`Socket.send`, `Regex.matches`).

**Failure travels through a `@Result` return, and the template owns the wrapping.** The Node cell is
an IIFE with try/catch answering `{ ok: v }` or `{ error: msg }`, the Erlang cell a `fun` answering
`{ok, V}` or `{error, Bin}`, and the signature `-> @Result<T, string>`. Nothing returns a sentinel.

**Records cross the boundary as an Erlang map and a JS object**; opaque handles are
`pub type Socket(handle: any)` — a single `any` field wrapping the port or descriptor, so the type
system keeps a listener and a socket apart without the compiler knowing what either is.

**`io/net` refuses commonJS explicitly.** Node's socket API is callback-driven and cannot answer
`accept` inline, and a browser has no listener at all. The commonJS cells answer
`Error("std/io/net: server-only")`: std still compiles for both targets, the tests assert the
refusal, and a client front that reaches for a socket gets a `@Result` error instead of a lowering
diagnostic.

**`escape` and the `path` additions are pure botopink** at the pure root: they compose `String`
methods, so they run on every backend. `escape.html` replaces `&` first, or the ampersand it
introduces for `<` gets re-escaped; the tests pin that order.

## Steps

### Step 1 — `escape.bp`

Pure botopink, no host cell, no imports.

- [x] `escape.html("<a href=\"x\">&")` answers `&lt;a href=\"x\"&gt;&amp;` — the `&` is escaped once, not twice
- [x] `escape.unescapeHtml(escape.html(s)) == s` for the five entities, on both targets
- [x] `escape.attribute` escapes both quote characters and delegates the other three to `html`
- [x] `escape.jsString("</script>")` contains no literal `</script>` substring
- [x] the module declares no `#[@External.*]` cell and no `import`

### Step 2 — `path.bp` and `io/fs.bp` additions

- [x] `path.isInside("/app", "/app/blog/page.bp")` is true; `path.isInside("/app", "/app/../etc/passwd")` is false
- [x] `path.withoutExtension("page.bp")` answers `page`; `path.withoutExtension("noext")` answers `noext`
- [x] `fs.walk` on a fixture tree answers the same *set* of relative paths on both targets (order is not asserted — `filelib:fold_files` and `readdirSync` do not agree on it)
- [x] `fs.glob("**/page.bp", root)` finds a nested `page.bp` on both targets
- [x] the nine pre-existing `path` functions and the pre-existing `fs` functions are byte-unchanged; `path.bp` declares no `#[@External.*]` cell

### Step 3 — `encoding.bp`

Hex, percent-encoding and the percent-aware form codec, beside the base64 four, so one import covers
the wire-format surface.

- [x] `encoding.hexEncode("hi")` answers `6869` on both targets, lowercase
- [x] `encoding.hexDecode("zz")` answers an `Error`, not a crash
- [x] `encoding.percentEncode("a b&c=d")` answers `a%20b%26c%3Dd` on both targets
- [x] `encoding.percentDecode(encoding.percentEncode(s)) == s` for a string containing space, `&`, `=`, `+`, `/` and a non-ASCII character
- [x] `encoding.formStringify([#("q", "a b")])` answers `q=a%20b`
- [x] `encoding.base64UrlEncode` output contains no `+`, `/` or `=`

### Step 4 — `hash.bp`, the base64url digests

- [x] `hash.hmacSha256Base64Url("key", "The quick brown fox jumps over the lazy dog")` matches the RFC 4231 vector re-encoded as base64url, byte-identical on both targets
- [x] `hash.sha1Base64` reproduces the RFC 6455 §1.3 WebSocket accept-key example
- [x] `hash.sha256Base64Url("")` answers `47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU` on both targets
- [x] `hash.equalsConstantTime` answers false for equal-length-different and for different-length inputs, and never throws
- [x] a test asserts `equalsConstantTime(x, x)` for a 43-character base64url signature — the exact shape front 10 compares

### Step 5 — `io/clock.bp` additions

A deadline is an absolute epoch reading, so it survives being handed to another process — front 12
puts one in a cache entry and front 18 in a session.

- [x] `clock.parseIso8601(clock.formatIso8601(t))` answers `Ok(t)` truncated to whole seconds, on both targets
- [x] `clock.parseIso8601("not a date")` answers an `Error` on both targets
- [x] `clock.toCivil` of a fixed epoch reading answers the same `Civil` on both targets, and `weekday` follows ISO-8601 (Monday = 1)
- [x] `clock.isExpired(clock.deadline(clock.seconds(60)))` is false; `clock.isExpired(0)` is true
- [x] `clock.sleep(20)` returns after at least 20 monotonic milliseconds on both targets

### Step 6 — `io/random.bp` additions

The module docblock says which half is a CSPRNG and which is not — a caller reaching for `float()`
when they wanted `secureToken()` is the bug to avoid.

- [x] `random.secureToken(32)` answers 43 characters, containing none of `+`, `/`, `=`
- [x] two consecutive `random.secureToken(16)` calls differ, on both targets
- [x] `random.uuidV4()` matches `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$` on both targets
- [x] the eight `rand`-backed `random` functions and `randomBytes` are byte-unchanged and `random.seed`/`seededFloat` still round-trip

### Step 7 — `regex.bp` additions

The route matcher compiles each pattern once at start-up and runs it per request.

- [x] `regex.captures("^/blog/([^/]+)$", "/blog/hello")` answers a two-element array whose second element is `hello`, on both targets
- [x] `regex.captures("^/x$", "/y")` answers `null`, not an empty array
- [x] `regex.namedCaptures("(?<slug>[^/]+)", "/hello")` answers one `#("slug", "hello")` pair on both targets
- [x] `regex.compile("(")` answers an `Error`; a compiled pattern's `matches(input)` agrees with `regex.matches` of the same source
- [x] `regex.escapeLiteral(".*")` answers a pattern that matches the literal `.*` and nothing else
- [x] the six pre-existing `regex` functions and the `Match` record are unchanged

### Step 8 — `io/process.bp` additions

`stderr` is empty on the Erlang side because `stderr_to_stdout` folds the two streams; the record
keeps the field so the Node side stays faithful, and the docblock says which target splits them.

- [x] `process.run("echo", ["hi"])` answers `Ok` with `status == 0` and `stdout` starting `hi`, on both targets
- [x] `process.run("definitely-not-a-binary", [])` answers an `Error` rather than crashing the caller
- [x] a non-zero exit is an `Ok` carrying that status, not an `Error` — the process ran, it just failed
- [x] `process.runShell("exit 3")` is documented as status-losing on Erlang (`os:cmd/1` answers output only) and the docblock says so
- [x] the five pre-existing `process` functions are byte-unchanged

### Step 9 — `io/net.bp`

TCP and TLS sockets; the TLS path starts the `ssl` application idempotently.

- [x] on erlang, a test binds an ephemeral port, connects to itself, sends 11 bytes, receives the same 11 bytes, and closes both ends
- [x] `accept` with a 50 ms timeout and no pending connection answers `Error("timeout")` rather than blocking the test
- [x] `net.connect("127.0.0.1", <closed port>, 200)` answers an `Error` naming the refusal
- [x] on commonJS, every `net` function answers `Error("std/io/net: server-only")` — asserted, not assumed
- [x] `peer()` of an accepted socket answers the loopback address
- [x] the TLS path completes a handshake against a self-signed fixture cert and round-trips a payload

### Step 10 — export lines

`escape` and `async` are root modules of `root.bp`; `net` and `clock` are in `io/mod.bp`. The content
hashes live in `hash.bp` and hand over no line.

- [x] the build embeds every registered module without a `build.zig` edit (`libs/std/AGENTS.md`)
- [x] `import {escape, encoding, hash, io: {net, clock}} from "std";` resolves from a consumer package — a scratch consumer runs `escape.html`, `encoding.base64Encode`, `hash.sha256`, `clock.nowMillis` and `net.listen` on commonJS and erlang
- [x] `libs/std/AGENTS.md`'s tree listing names `io/net.bp` and `escape.bp` and lists the added functions on the rows of the eight modules extended
- [x] fronts 02 and 03 landed first, so front 02's line is in place

## Examples

- [`examples/net-server-example.bp`](./examples/net-server-example.bp) — a TCP echo accept loop and
  its client half: the primitive under rakun's HTTP server (front 04) and the WebSocket upgrade
  (front 20). Erlang only.
- [`examples/path-and-process-example.bp`](./examples/path-and-process-example.bp) — walking an
  `app/` tree into route segments with a traversal guard, then shelling out to the compiler: what
  the file router (front 22) and the onze CLI (front 50) need.
- [`examples/crypto-and-encoding-example.bp`](./examples/crypto-and-encoding-example.bp) — signing
  and verifying an HS256 token in constant time, and deriving an ETag: fronts 10, 18 and 03.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No bitwise operators (`&`, `\|`, `^`, `<<`, `>>`) | `random.uuidV4` sets the version/variant bits; `encoding.hexEncode` would fold nibbles | do the bit work inside the host template, in JS and Erlang | `&`, `\|`, `^`, `~`, `<<`, `>>` on the integer behaviors in `primitives.bp` |
| No byte/binary type — every host cell marshals through `string` | `hash.hmacSha256Base64Url` cannot take a raw key; `random.secureToken` answers base64url text rather than bytes; `Socket.recv` answers a UTF-8 `string` for what is a byte stream | text-encode at the boundary (hex or base64url) and accept that a non-UTF-8 payload is lossy on the Node side | a `bytes` primitive with `length`, `at`, `slice`, `concat`, and `@External` marshalling to an Erlang binary and a JS `Buffer` |
| A std module cannot call another std module | `io/net.bp`, `io/fs.bp` and `io/process.bp` declare their own cells | one file per name | make a cross-module bare import of an `#[@External.*]` symbol lower to the defining module's binding |
| Declared parameter defaults are never applied | `accept(timeoutMillis)`, `fs.glob(pattern, root)`, `process.run(cmd, args)` all want a default and cannot have one | every call passes every argument | apply defaults at the call site |
| No `toString(radix)` on the integer behaviors | hex rendering in `encoding` and `hash` | render inside the host template | `fn toStringRadix(self: Self, radix: i32) -> string` on `Integer` |
| A closure passed to a host cell is unverified on the Erlang target | `process.onSignal(name, handler)` | signals are left out; the CLI polls instead | pin fn-valued `$N` markers in the `@External.Erlang` template grammar |

## Test plan

Inline `test` blocks at the bottom of each `src/*.bp`, run by `botopink test --target commonJS` and
`botopink test --target erlang` from `libs/std/`, and by `zig build test-libs`.

- `escape.bp`, `path.bp` — pure functions, exact string equality, identical on every backend.
- `encoding.bp`, `hash.bp` — published vectors (RFC 4231, RFC 6455 §1.3, the empty-string SHA-256),
  byte-identical on both targets. A digest that differs between targets is a failure, not a
  platform difference.
- `io/clock.bp` — round trips rather than absolutes, plus ordering assertions (`isExpired` before and
  after a `sleep`). Wall-clock values are never asserted directly.
- `io/random.bp` — shape and distinctness, never a specific value.
- `regex.bp` — the same pattern and input on both targets answer the same captures; a construct
  PCRE and `re` disagree on belongs in the front that needs it, with its divergence documented.
- `io/process.bp` — `echo` and a missing binary, on both targets; `runShell`'s status loss on Erlang
  asserted as the documented behaviour.
- `io/net.bp` — **erlang only for the real path**: bind, self-connect, round-trip, close. On
  commonJS the suite asserts the refusal, so a green commonJS cell does not imply sockets work there.

## Definition of done

- `io/net.bp` and `escape.bp` exist and eight modules carry the functions of *The surface* (`path`,
  `io/fs`, `encoding`, `hash`, `io/clock`, `io/random`, `regex`, `io/process`).
- No module imports another std module; no function that predates the front is edited.
- The export lines of Step 10 are in place.
- `libs/std/AGENTS.md`'s tree listing names the files and functions.
- Every `// LANGUAGE GAP:` marker in this front's examples appears in the table above.
- The front's tests are green on both targets.

---

## Steps 11–14 — std reads and writes JSON

Decision 116 rules 3 and 8 and [decision 117](../../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only)
rules 6 and 7. Every library that answers JSON wrote its own string escaper and none escaped what
RFC 8259 requires; every library that reads JSON sliced it by hand. These steps give std the writer,
the `<script>`-safe form and a structured reader.

**Owns:** the functions at the foot of `libs/std/src/json.bp` (`quote`, `unquote`, `array`, `object`,
the `Json` type and `decode`) and their inline tests · `scriptJson` in `libs/std/src/escape.bp` · the
`json` and `escape` rows of `libs/std/AGENTS.md` (the added names only).
**Does not touch:** `root.bp`; `json.parse` and `json.stringify`; every consumer — rakun fronts 05 and
07, `05-actions-lib`, `06-validation-lib` and jhonstart front 30 switch in their own fronts.
**Reference:** [RFC 8259](https://www.rfc-editor.org/rfc/rfc8259) (§ 7: a JSON string must escape
`"`, `\` and U+0000–U+001F; § 4: object member names *should* be unique) ·
[HTML § 4.12.1.3](https://html.spec.whatwg.org/multipage/scripting.html#restrictions-for-contents-of-script-elements)
(what may not appear inside `<script>`)

### Mechanism

```bp
// json
pub declare fn quote(s: string) -> string                   // a JSON string literal, quotes included
pub declare fn unquote(literal: string) -> @Result<string, string>   // its inverse
pub fn array(items: Array<string>) -> string                // items already encoded
pub fn object(fields: Array<#(string, string)>) -> string   // keys quoted here, values already encoded

pub type Json { Null, Bool(bool), Num(f64), Str(string), Arr(Array<Json>), Obj(Array<#(string, Json)>) }
pub fn decode(s: string) -> @Result<Json, string>

// escape
pub fn scriptJson(json: string) -> string                   // JSON text, safe inside <script>
```

`quote` escapes `"` as `\"`, `\` as `\\`, U+0008 / U+000C / U+000A / U+000D / U+0009 as `\b` `\f`
`\n` `\r` `\t`, every other code point below U+0020 as `\u00xx` (lowercase hex), and nothing else —
non-ASCII text passes through as UTF-8. The literals below are the same on both targets. `unquote`
reads one string literal and refuses anything else (a bare word, a number, a missing quote) with an
`Error`.

`array` and `object` do no escaping of values: a value is the output of `quote`, a number's text,
`true` / `false` / `null`, or another writer's output. `object` quotes its keys with `quote` and keeps
the given order.

`decode` reads one RFC 8259 document into a `Json` and answers an `Error` naming the byte offset for
anything that is not exactly one. It is **written in botopink**: `JSON.parse` reorders integer-like
keys and keeps the last of two duplicates, and OTP's `json:decode` answers a map, so neither keeps
member order or refuses a duplicate. The reader is the most restrictive one RFC 8259 admits
(decision 67): `Obj` keeps members in document order; a duplicate member name in one object is an
`Error`; text after the value other than whitespace is an `Error`; a number follows the RFC grammar
exactly (`01`, `+1`, `.5`, `1.`, `NaN`, `Infinity` are refused), is an `f64`, and one that overflows
`f64` is an `Error`; `\u` escapes are decoded, a surrogate pair into its code point, an unpaired
surrogate is an `Error`; a raw control character below U+0020 inside a string is an `Error`.

`scriptJson` takes JSON text and replaces `&` with `&`, `<` with `<`, `>` with `>`,
U+2028 with ` ` and U+2029 with ` `. In JSON those characters can only occur inside a
string, where each `\u` form is a valid escape, so the output is the same JSON value — `decode` of it
equals `decode` of the input — and it contains no `</script`, no `<!--` and no line terminator a
script parser would see.

### Step 11 — `json.quote`, `json.unquote`, `json.array`, `json.object`

- [x] `json.quote("a\"b\\c")` answers `"a\"b\\c"` (as text: quote, `a`, `\"`, `b`, `\\`, `c`, quote)
- [x] `json.quote` of a string holding U+0001, U+0008, U+000C, U+001F, a newline and a tab answers
      `"\u0001\b\f\u001f\n\t"`, identical on erlang and commonJS
- [x] `json.quote("ação")` answers `"ação"` — non-ASCII is not escaped
- [x] for every string `s` in the test table, `json.parse(json.quote(s))` is `Ok` and
      `json.unquote(json.quote(s))` is `Ok(s)`
- [x] `json.unquote("abc")`, `json.unquote("\"abc")` and `json.unquote("1")` answer an `Error`
- [x] `json.array([json.quote("a"), "1", "true"])` answers `["a",1,true]`; `json.array([])` answers `[]`
- [x] `json.object([#("v", "1"), #("ok", "true"), #("s", json.quote("x"))])` answers
      `{"v":1,"ok":true,"s":"x"}` — order kept, keys quoted; `json.object([])` answers `{}`
- [x] a key containing `"` is quoted by `object`: `json.object([#("a\"b", "1")])` parses

### Step 12 — `escape.scriptJson`

- [x] `escape.scriptJson(json.object([#("h", json.quote("</script><!--&"))]))` contains no `<`, `>`
      or `&`, and `json.decode` of it equals `json.decode` of the input — `escape.bp`'s test pins the
      output literal; `json.bp`'s "reads escape.scriptJson's output as the same value" decodes that literal
      and the input to the same `Json` (a std module imports no other, so the halves meet in the literal)
- [x] U+2028 and U+2029 inside a string come out as ` ` and ` `
- [x] JSON text with none of the five characters comes out unchanged
- [x] the function declares no `#[@External]` cell (it composes `replaceAll`; U+2028/U+2029 come from
      `escape.bp`'s two private separator cells, because the erlang backend truncates a `\u{2028}` literal)

### Step 13 — `Json` and `json.decode`

- [x] `json.decode("{\"rakun\":{\"actions\":{\"bodyLimit\":5242880},\"appDir\":\"app\"}}")` answers
      `Ok(Obj([#("rakun", Obj([#("actions", Obj([#("bodyLimit", Num(5242880.0))])), #("appDir", Str("app"))]))]))`
      — members in document order, on both targets
- [x] `json.decode("{\"b\":1,\"a\":2,\"1\":3}")` keeps the order `b`, `a`, `1` on commonJS as on erlang
- [x] `json.decode("{\"a\":1,\"a\":2}")` answers an `Error` naming the duplicate `a`
- [x] `json.decode("[1,2] x")`, `json.decode("")`, `json.decode("1 2")` answer an `Error`
- [x] `json.decode("\"\\u0041\\u00e7\\ud83d\\ude00\\b\\f\\/\"")` answers `Ok(Str("Aç😀` + U+0008 +
      U+000C + `/"))`; `"\\ud83d"` alone (an unpaired surrogate) answers an `Error`
- [x] a raw U+0001 inside a string literal answers an `Error`; `"\\u0001"` answers `Ok(Str(U+0001))`
- [x] `01`, `+1`, `.5`, `1.`, `NaN`, `Infinity` and `1e400` each answer an `Error`; `-0.5e2` answers
      `Ok(Num(-50.0))`; `true`, `false`, `null` answer `Bool(true)`, `Bool(false)`, `Null`
- [x] for every string `s` in Step 11's table, `json.decode(json.quote(s))` is `Ok(Str(s))`, and for
      the envelope, RPC-body and payload literals of contracts 2 and 3, `decode` answers the same
      `Json` on both targets
- [x] `decode` declares no `#[@External]` cell — the grammar, order, duplicates and escapes are botopink;
      it calls one private conversion cell the language lacks, not a parser: `codepointText` (a `\u`
      escape's text); a numeral becomes its correctly rounded `f64` in botopink (decision 142)

### Step 14 — The copies are deletable

These steps delete nothing outside std; they are done when each consumer has switched:

| Copy | Replaced by | State |
|---|---|---|
| jhonstart's payload writer (was rakun-app `ssr.bp`'s `jsonString`, `jsonStrings`, `jsonPairs`, `jsonTriples`, `payloadEscape`) | `json.quote`, `json.array`, `json.object`, `escape.scriptJson` | switched — `modules/jhonstart/src/render.bp`; the `ssr.bp` copies are gone |
| jhonstart's payload reader | `json.decode` | switched — `modules/jhonstart/src/globals.bp` `readPayload` |
| jhonstart-emilia's class list | `json.quote`, `json.array` | switched — `modules/jhonstart-emilia/src/root.bp` |
| emilia | — | holds no JSON code: its one codec (`output.bp` `encodeSheet` / `decodeSheet`) is a tab/newline record format, not JSON |
| `rakun-web/src/error.bp` `jsonEscape` | `json.quote`, `json.object` | gone (rakun 07) |
| `rakun/src/config.bp`'s hand scanner (`jsonString`, `jsonStringEnd`) | `json.decode` | gone (rakun 05) |
| rakun's three sites: `rakun-data/src/sql/health.bp` `jsonText`, `rakun/src/autoconfig_registry.bp`'s `dependencies` scanner, `rakun-actuator/src/health.bp` `rkActuatorJsonObject` | `json.object` / `json.quote`, `json.decode` | gone — `dbHealth` writes with the std writers, `manifestDependencies` and `isJsonObject` read with `json.decode` |

**Acceptance:**
- [x] `grep -rn "fn jsonString\|fn jsonEscape\|fn jsonStrings\|fn jsonPairs\|fn jsonTriples\|fn payloadEscape" --include=*.bp repository/`
      is empty — and so is `JSON.parse` / `JSON.stringify` in jhonstart's and emilia's `.bp` and
      `.mjs` sources
- [x] no hand-written JSON reader or writer is left under `repository/` — rakun's three sites went
      to std's `json` (the table)
- [x] jhonstart and emilia green on both rows — `zig build test-libs`

### Test plan (Steps 11–14)

Inline `test` blocks at the foot of `json.bp` and `escape.bp`, run by `botopink test` and
`botopink test --target erlang` in `libs/std`. Every expected text is a literal; the round-trip table
covers the empty string, every code point below U+0020, `"`, `\`, `/`, U+2028, U+2029 and a
four-byte UTF-8 character. The `decode` table is asserted cell for cell on both targets.

### Gate (Steps 11–14)

- [x] `botopink test` green in `libs/std` on commonJS and erlang — 417 passed / 0 failed on each, `json` 23/0
- [x] `libs/std/AGENTS.md`'s `json` and `escape` rows list the added names
- [x] no `root.bp` line changed by these steps
