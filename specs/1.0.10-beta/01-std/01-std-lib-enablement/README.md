# Front 01 — Std Lib Enablement

**Track:** A std
**Priority:** critical — fifty of the fifty-three fronts bottom out in a socket, a clock, a path, a digest or an escape; without this front they are `declare fn`s with nothing behind them
**Target:** both — std is the floor under both halves
**Wave:** 0
**Depends on:** none
**Owns:** `src/net.bp`, `src/process.bp`, `src/path.bp`, `src/clock.bp`, `src/random.bp`, `src/regex.bp`, `src/encoding.bp`, `src/hmac.bp`, `src/escape.bp`, `src/root.bp` (exports only)
**Does not touch:** `src/primitives.bp`, `src/builtins.d.bp`, `src/builtins_fns.d.bp` (the three ambient files), and the std modules it does not own — `time.bp`, `crypto.bp`, `base64.bp`, `querystring.bp`, `url.bp`, `env.bp`, `os.bp`, `fs.bp`, `json.bp`, `http.bp`, `erlang.bp`, `beam.bp`, `dict.bp`, `sets.bp`, `queue.bp`, `order.bp`, `math.bp`, `string_builder.bp`, `asserts.bp`, `unicode.bp`
**Reference:** Erlang/OTP — [`gen_tcp`](https://www.erlang.org/doc/apps/kernel/gen_tcp.html) · [`ssl`](https://www.erlang.org/doc/apps/ssl/ssl.html) · [`crypto`](https://www.erlang.org/doc/apps/crypto/crypto.html) · [`re`](https://www.erlang.org/doc/apps/stdlib/re.html) · [`filelib`](https://www.erlang.org/doc/apps/stdlib/filelib.html) · [`filename`](https://www.erlang.org/doc/apps/stdlib/filename.html) · [`calendar`](https://www.erlang.org/doc/apps/stdlib/calendar.html) · [`uri_string`](https://www.erlang.org/doc/apps/stdlib/uri_string.html). Node.js — [`net`](https://nodejs.org/api/net.html) · [`tls`](https://nodejs.org/api/tls.html) · [`child_process`](https://nodejs.org/api/child_process.html) · [`crypto`](https://nodejs.org/api/crypto.html) · [`path`](https://nodejs.org/api/path.html)
**Replaces:** new

---

## Problem

Every one of the three merged drafts was written as if std already did things std does not do. 1.0.6
opens a socket in its data-source front and signs a JWT in its security front. 1.0.7 walks a
directory in its file-router front and escapes HTML in its SSR front. Neither checked. The result is
that fifty of the fifty-three fronts in this milestone name a primitive in their mechanism section
that does not exist anywhere in `libs/std/src/`, and would therefore have to grow a private
`#[@External.Node]` cell of their own — which is exactly what the overview's *Reuse std* rule
forbids, and exactly what would leave the erlang half of this milestone unimplemented while the
commonJS half looked finished.

The gap is not uniform, and the interesting part of this front is the audit rather than the code.
std today has twenty-four modules and several of them are further along than the drafts assumed:
`path.bp` is a complete posix path calculator written in pure botopink, `regex.bp` already wraps
`re:run/3` with a capture-carrying `Match` record, `crypto.bp` already has SHA-256 and HMAC-SHA256,
`time.bp` already reads both the wall clock and the monotonic clock on both targets. What is missing
is narrower and sharper than "std has nothing": there is no socket at all, no directory walk, no
child process, no percent-encoding, no constant-time compare, no base64url of a raw digest, and no
HTML escaping. Those seven absences are what block the milestone.

Two of them are security requirements rather than conveniences. `escape.html` is what stands between
the SSR pipeline (front 23) and a stored-XSS hole — a render path that interpolates a database string
into markup without it is not a pipeline with a missing feature, it is a vulnerability with a
release date. `hmac.equalsConstantTime` is what stands between the session-cookie check (front 18)
and a byte-at-a-time signature oracle; `==` on two signature strings is a timing side channel on both
backends.

## Current state

Verified by reading `repository/botopink-lang/libs/std/src/` in full.

- **Twenty-four importable modules**, declared one `pub mod` per line in `src/root.bp:13-36`:
  `order, dict, sets, string_builder, queue, math, asserts, path, random, querystring, time, url,
  base64, unicode, process, os, env, crypto, regex, erlang, beam, json, fs, http`. Three further
  files (`primitives.bp`, `builtins.d.bp`, `builtins_fns.d.bp`) are ambient — flattened into the
  global type env, not imported (`src/root.bp:9-11`).
- **`path.bp` is pure botopink and complete for the calculations it covers**: `split`, `isAbsolute`,
  `basename`, `dirname`, `extname`, `join`, `normalize`, `relative`, `resolve`, plus `separator` and
  `delimiter` as `pub val` (`path.bp:13-190`). It touches no host cell, which is why it runs on
  every backend including wat. It cannot see the filesystem at all — there is no `walk` and no
  `glob`.
- **`process.bp` is introspection only**: `exit`, `cwd`, `platform`, `arch`, `pid`
  (`process.bp:28-62`). There is no way to start a child process.
- **`random.bp` is not a CSPRNG**: `float`, `seed`, `seededFloat`, `coin`, `bool`, `intInRange`,
  `pick`, `shuffle` (`random.bp:17-116`), backed by `Math.random` and `rand:uniform`. The only strong
  source in std today is `crypto.randomBytes(n) -> string` (hex, `crypto.bp:77`), in a module this
  front does not own.
- **`regex.bp` covers matching but not capture groups**: `matches`, `replace`, `replaceAll`,
  `splitOn`, `match`, `matchAll`, and a `Match(value, index)` record (`regex.bp:35-90`). `match`
  captures `first` only — a route pattern like `/blog/(?<slug>[^/]+)` has no way to read `slug`.
- **`crypto.bp` answers hex, and only hex**: `sha256`, `sha512`, `md5`, `hmacSha256`, `randomBytes`
  (`crypto.bp:22-77`). RFC 7515 wants base64url of the *raw* digest, so JWT cannot be built on it as
  it stands. There is no SHA-1 (front 20's WebSocket handshake needs one) and no constant-time
  compare.
- **`time.bp` has the clock but not the calendar**: `nowMillis`, `monotonicMillis`, `formatIso8601`,
  `measureMillis` (`time.bp:56-104`). No parse, no civil breakdown, no timezone, no duration type,
  and `sleep` is explicitly deferred in its own docblock (`time.bp:31-34`).
- **`querystring.bp` does not percent-encode.** Its docblock says so: "URI percent-encoding for
  component values is deferred… callers pre-escape" (`querystring.bp:10-15`). Nothing in std can do
  that pre-escaping.
- **`base64.bp` encodes text, not bytes**: `encode`, `decode`, `encodeUrlSafe`, `decodeUrlSafe`
  (`base64.bp:22-45`), all `string -> string` through UTF-8.
- **There is no `net.bp`, no `clock.bp`, no `encoding.bp`, no `hmac.bp`, no `escape.bp`.** Nothing in
  std opens a socket, and nothing in std escapes HTML.
- **No std module imports another.** Zero `import` lines across all twenty-seven files in
  `src/`. This is structural, not stylistic — see *Mechanism*.
- **Tests live inline.** Every std module carries its `test` blocks at the bottom of its own source
  file (`time.bp:108`, `process.bp:66`, `fs.bp:107`, `regex.bp:98`). `libs/std/test/` holds three
  files and they test the ambient surface against the global env, with no module import path
  (`libs/std/AGENTS.md`).

## Requirements table

This table is the front. Each row is a primitive some downstream front bottoms out in; the rightmost
columns say what has to exist behind it on each target. "Exists today" cites the file when the answer
is yes.

| Primitive | Needed by front(s) | Exists today | BEAM backing | JS backing | Server-only? |
|---|---|---|---|---|---|
| **net** — `listen(port, backlog)` | 04, 20 | no | `gen_tcp:listen/2` | — | **yes** |
| `accept(listener, timeoutMillis)` | 04, 20 | no | `gen_tcp:accept/2` | — | **yes** |
| `connect(host, port, timeoutMillis)` | 08, 09, 13, 15 | no | `gen_tcp:connect/4` | — | **yes** |
| `recv(sock, length, timeoutMillis)` / `send(sock, data)` | 04, 08, 09, 13, 15, 20 | no | `gen_tcp:recv/3`, `gen_tcp:send/2` | — | **yes** |
| `close(sock)` / `closeListener(l)` | 04, 20 | no | `gen_tcp:close/1` | — | **yes** |
| `peer(sock) -> Peer(host, port)` | 07, 17 | no | `inet:peername/1` | — | **yes** |
| `tlsListen` / `tlsAccept` / `tlsConnect` / `tlsRecv` / `tlsSend` / `tlsClose` | 10, 13, 15 | no | `ssl` application | — | **yes** |
| **clock** — `nowMillis` / `monotonicMillis` / `formatIso8601` | 11, 12, 16, 17, 18 | **yes** — `time.bp:56,80,92` | `erlang:system_time/1`, `erlang:monotonic_time/1`, `calendar:system_time_to_rfc3339/2` | `Date.now`, `performance.now`, `Date#toISOString` | no |
| `parseIso8601(s) -> @Result<i64, string>` | 12, 16, 18, 32 | no | `calendar:rfc3339_to_system_time/2` | `Date.parse` | no |
| `toCivil(epochMillis) -> Civil(...)` | 16, 17 | no | `calendar:system_time_to_universal_time/2` + `calendar:day_of_the_week/3` | `Date` getters | no |
| `offsetMinutes(epochMillis)` (host timezone) | 16, 32 | no | `calendar:universal_time_to_local_time/1` | `Date#getTimezoneOffset` | no |
| `Duration` + `millis/seconds/minutes/hours/add/toMillis` | 12, 16, 18 | no | pure `.bp` | pure `.bp` | no |
| `sleep(millis)` | 16, 19 | no — deferred in `time.bp:31-34` | `timer:sleep/1` | `Atomics.wait` on a scratch `SharedArrayBuffer` | no |
| `deadline(millis)` / `isExpired(d)` | 12, 18 | no | pure `.bp` | pure `.bp` | no |
| **process** — `exit/cwd/platform/arch/pid` | 50 | **yes** — `process.bp:28-62` | `erlang:halt/1`, `file:get_cwd/0`, `os:type/0`, `erlang:system_info/1`, `os:getpid/0` | `process.*` | no |
| `run(cmd, args) -> @Result<Exit, string>` | 50, 51, 52 | no | `open_port({spawn_executable, _}, [exit_status, stderr_to_stdout, binary])` | `child_process.spawnSync` | no |
| `runShell(cmd) -> string` | 50 | no | `os:cmd/1` | `child_process.execSync` | no |
| `argv()` | 50 | **yes** — `env.args()`, `env.bp:44` (not owned here) | `init:get_plain_arguments/0` | `process.argv.slice(2)` | no |
| `onSignal(name, handler)` | 50, dev server | no | `os:set_signal/2` + a handler process | `process.on` | no |
| **path** — `split/isAbsolute/basename/dirname/extname/join/normalize/relative/resolve` | 22, 50, 51, 52 | **yes** — `path.bp:24-190`, pure `.bp` | pure `.bp` | pure `.bp` | no |
| `withoutExtension(p)` | 22, 51, 52 | no | pure `.bp` | pure `.bp` | no |
| `isInside(parent, child)` — traversal guard | 22, 25 | no | pure `.bp` | pure `.bp` | no |
| `walk(root) -> @Result<string[], string>` | 22, 50 | no | `filelib:fold_files/5` | `fs.readdirSync(p, {recursive: true})` | no |
| `glob(pattern, root) -> @Result<string[], string>` | 22, 50 | no | `filelib:wildcard/2` | `fs.globSync` | no |
| **random** — `float/coin/bool/intInRange/pick/shuffle` | — | **yes** — `random.bp:17-116`, **not** a CSPRNG | `rand:uniform/0` | `Math.random` | no |
| `secureBytesHex(n)` | 10, 18 | **yes** — `crypto.randomBytes`, `crypto.bp:77` (not owned here) | `crypto:strong_rand_bytes/1` | `crypto.randomBytes` | no |
| `secureToken(bytes) -> base64url` | 10, 18 | no | `crypto:strong_rand_bytes/1` + `base64:encode/1` | `randomBytes(n).toString('base64url')` | no |
| `uuidV4()` | 17, 18 | no | `crypto:strong_rand_bytes(16)` + version/variant rewrite | same | no |
| **regex** — `matches/replace/replaceAll/splitOn/match/matchAll` | 07, 14, 22 | **yes** — `regex.bp:35-90` | `re:run/3`, `re:replace/4`, `re:split/3` | `RegExp` | no |
| `compile(pattern) -> @Result<Regex, string>` | 07, 22 | no | `re:compile/2` | `new RegExp` | no |
| `captures(pattern, input) -> ?Array<string>` | 14, 22 | no | `re:run(_, _, [{capture, all, binary}])` | `String#match` | no |
| `namedCaptures(pattern, input) -> Array<#(string, string)>` | 22 | no | `re:inspect/2` + `{capture, all_names, binary}` | named groups | no |
| `escapeLiteral(s)` | 07, 22 | no | pure `.bp` | pure `.bp` | no |
| **encoding** — `base64Encode/Decode`, `base64UrlEncode/Decode` | 10, 13, 18 | **yes** — `base64.bp:22-45` (not owned here) | `base64:encode/1`, `base64:decode/1` | `Buffer` | no |
| `hexEncode(s)` / `hexDecode(s)` | 03, 10 | no | `binary:encode_hex/1`, `binary:decode_hex/1` | `Buffer#toString('hex')` | no |
| `percentEncode(s)` / `percentDecode(s)` | 13, 22, 25 | no — `querystring.bp:10-15` defers it | `uri_string:quote/1`, `uri_string:unquote/1` | `encodeURIComponent` | no |
| `formParse(q)` / `formStringify(pairs)` — percent-aware | 07, 24, 25 | partly — `querystring.bp:35,48` is escape-naive | `uri_string:dissect_query/1`, `uri_string:compose_query/1` | pure `.bp` over `percentEncode` | no |
| **hmac** — `sha256Hex/sha512Hex/md5Hex/hmacSha256Hex` | 03, 10, 18 | **yes** — `crypto.bp:22-38` (not owned here) | `crypto:hash/2`, `crypto:mac/4` | `node:crypto` | no |
| `sha1Base64(data)` | 20 (WebSocket accept key) | no | `crypto:hash(sha, _)` + `base64:encode/1` | `createHash('sha1').digest('base64')` | no |
| `sha256Base64Url(data)` | 03, 10 | no | `crypto:hash(sha256, _)` + base64url rewrite | `digest('base64url')` | no |
| `hmacSha256Base64Url(key, data)` | 10 (JWT), 18 | no | `crypto:mac(hmac, sha256, _, _)` + base64url rewrite | `createHmac(...).digest('base64url')` | no |
| `equalsConstantTime(a, b)` | 10, 18 | no | `crypto:hash_equals/2` | `crypto.timingSafeEqual` | no |
| **escape** — `html(s)` | 23, 25, 32 | no | pure `.bp` | pure `.bp` | no |
| `attribute(s)` | 23, 48 | no | pure `.bp` | pure `.bp` | no |
| `unescapeHtml(s)` | 23 | no | pure `.bp` | pure `.bp` | no |
| `jsString(s)` — the `<script>` payload block | 23, 24 | no | pure `.bp` | pure `.bp` | no |

Read down the "Exists today" column and the front's real size appears: nineteen rows are already
there, thirty-one are not, and the thirty-one cluster into exactly the five new modules plus five
additions to modules that exist.

## Mechanism

Four structural facts about `libs/std` decide how every row above gets built, and all four were
verified by reading the tree rather than assumed.

**A std module cannot call another std module.** There is not one `import` line in any of the
twenty-seven files under `src/`. This is not a convention someone could relax: a cross-module bare
import of an `#[@External.*]` symbol resolves at type level and is `undefined` at run time — the same
lowering gap that made `emilia` fold its host cells back into `emilia.bp` instead of keeping a
`stylesheet.bp`. The consequence for this front is concrete and slightly ugly: `clock.bp` cannot call
`time.nowMillis()`, `hmac.bp` cannot call `crypto.sha256()`, `encoding.bp` cannot call
`base64.encode()`. Each new module re-declares the host cell it needs. Where that produces a
duplicate — `hmac.sha256Base64Url` and `crypto.sha256` both call `crypto:hash(sha256, _)` — the
duplication is in the template string, not in behaviour, and the alternative is a module graph the
compiler cannot lower.

**Every host call is a `declare fn` with one cell per target.** The shape is fixed by the rest of
std: a `////` docblock naming both upstream APIs, then a `//` comment per fn explaining the two
templates, then the annotations, then the bodyless `pub declare fn`. `fs.bp` is the reference
implementation and this front copies it exactly.

**Failure travels through `#[@result]`, and the template owns the wrapping.** `fs.bp:30-33` is the
pattern: the Node cell is an IIFE with try/catch answering `{ ok: v }` or `{ error: msg }`, the
Erlang cell is a `fun` answering `{ok, V}` or `{error, Bin}`, and the botopink signature is
`-> @Result<T, string>`. Every fallible row in the table above — `net.*`, `path.walk`, `path.glob`,
`process.run`, `clock.parseIso8601`, `regex.compile`, `encoding.hexDecode`, `encoding.percentDecode`
— uses it. Nothing in this front returns a sentinel.

**Records cross the boundary as an Erlang map and a JS object.** `fs.stat` answers a `FileStat` from
a host template by building `#{size => _, mtime => _, isDir => _}` on Erlang and
`{ size, mtime, isDir }` on Node (`fs.bp:97-99`). That is how `Exit`, `Peer`, `Civil`, `Match` and
the opaque socket handles are shaped: a one- or few-field record whose payload the host template
constructs. Opaque handles are `pub type Socket(handle: any)` — a single `any` field wrapping the
port or the file descriptor, so the type system keeps a listener and a socket apart without the
compiler needing to know what either is.

**Server-only modules carry an explicit refusal on commonJS.** `net` is the one module in this front
that has no browser meaning and no synchronous Node equivalent — Node's `net` is callback-driven and
cannot answer `accept` inline. Rather than omit the Node cell and have std's commonJS build red at
the first call site, `net.bp` declares the commonJS cell as a refusal that answers
`Error("std/net: server-only")`. That has three properties worth the ugliness: std still compiles for
both targets, the test file can *assert the refusal* rather than hoping nobody calls it, and a client
front that reaches for a socket gets a clear `@Result` error instead of a lowering diagnostic nobody
reads. This is the only module in track A that does it; every other row above is genuinely dual.

Two modules are pure botopink with no host cell at all — `escape.bp` and the new additions to
`path.bp`. They compose `String` methods (`replaceAll`, `split`, `slice`, `startsWith`) exactly the
way `path.bp` already does, which is what makes them work on wat and BEAM as well as the two targets
this milestone cares about. `escape.html` in particular must replace `&` first, or the ampersand it
introduces for `<` gets re-escaped; that ordering is the whole correctness of the function and the
test file pins it.

## Steps

The order is dependency order and also risk order: the pure modules land first and cannot break
anything, `net` lands last because it is the one that needs an OTP application started.

### Step 1 — `escape.bp`

Pure botopink, no host cell, no imports. Four functions and the ordering rule.

```bp
//// std/escape — HTML/attribute escaping for server-rendered markup.
////
//// Reference:
////   OWASP — https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
////   WHATWG — https://html.spec.whatwg.org/multipage/parsing.html#character-reference-state
////
//// Lib-self-contained: every function composes `String.replaceAll`, so the
//// module runs on every backend including wat. `&` is replaced FIRST; any
//// other order re-escapes the ampersands the later rules introduce.

pub fn html(s: string) -> string {
    val amp = s.replaceAll("&", "&amp;");
    val lt = amp.replaceAll("<", "&lt;");
    val gt = lt.replaceAll(">", "&gt;");
    return gt;
}

pub fn attribute(s: string) -> string {
    val base = html(s);
    val dq = base.replaceAll("\"", "&quot;");
    return dq.replaceAll("'", "&#39;");
}

pub fn unescapeHtml(s: string) -> string {
    val dq = s.replaceAll("&quot;", "\"");
    val sq = dq.replaceAll("&#39;", "'");
    val gt = sq.replaceAll("&gt;", ">");
    val lt = gt.replaceAll("&lt;", "<");
    return lt.replaceAll("&amp;", "&");
}

pub fn jsString(s: string) -> string {
    val bs = s.replaceAll("\\", "\\\\");
    val dq = bs.replaceAll("\"", "\\\"");
    val lt = dq.replaceAll("<", "\\u003c");
    return lt.replaceAll(" ", "\\u2028");
}
```

**Acceptance:**
- [ ] `escape.html("<a href=\"x\">&")` answers `&lt;a href=\"x\"&gt;&amp;` — the `&` is escaped once, not twice
- [ ] `escape.unescapeHtml(escape.html(s)) == s` for the five entities, on both targets
- [ ] `escape.attribute` escapes both quote characters and delegates the other three to `html`
- [ ] `escape.jsString("</script>")` contains no literal `</script>` substring
- [ ] the module declares no `#[@External.*]` cell and no `import`

### Step 2 — `path.bp` additions

Four functions appended below the existing ones; nothing already in the file changes. `withoutExtension`
and `isInside` are pure; `walk` and `glob` are the file's first host cells.

```bp
pub fn withoutExtension(p: string) -> string {
    val ext = extname(p);
    val n = p.length();
    val stem = if (ext == "") p else p.slice(0, n - ext.length());
    return stem;
}

// True when `child` resolves inside `parent`. The traversal guard front 22
// applies before it turns a request path into a file path.
pub fn isInside(parent: string, child: string) -> bool {
    val up = normalize(parent);
    val down = normalize(child);
    val rel = relative(up, down);
    val escapes = rel.startsWith("..");
    return escapes == false;
}

#[@result]
#[@External.Node("""(() => { try { return { ok: require('fs').readdirSync($0, { recursive: true, withFileTypes: false }) } } catch (__e) { return { error: String(__e) } } })()""")]
#[@External.Erlang("""(fun(__R) -> {ok, filelib:fold_files(__R, ".*", true, fun(__F, __A) -> [list_to_binary(__F) | __A] end, [])} end)($0)""")]
pub declare fn walk(root: string) -> @Result<string[], string>;

#[@result]
#[@External.Node("""(() => { try { return { ok: require('fs').globSync($0, { cwd: $1 }) } } catch (__e) { return { error: String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __R) -> {ok, [list_to_binary(__F) || __F <- filelib:wildcard(binary_to_list(__P), binary_to_list(__R))]} end)($0, $1)""")]
pub declare fn glob(pattern: string, root: string) -> @Result<string[], string>;
```

**Acceptance:**
- [ ] `path.isInside("/app", "/app/blog/page.bp")` is true; `path.isInside("/app", "/app/../etc/passwd")` is false
- [ ] `path.withoutExtension("page.bp")` answers `page`; `path.withoutExtension("noext")` answers `noext`
- [ ] `path.walk` on a fixture tree answers the same *set* of relative paths on both targets (order is not asserted — `filelib:fold_files` and `readdirSync` do not agree on it)
- [ ] `path.glob("**/page.bp", root)` finds a nested `page.bp` on both targets
- [ ] the nine existing `path` functions are byte-unchanged

### Step 3 — `encoding.bp`

Hex, percent-encoding, and the percent-aware form codec. It re-declares base64 rather than importing
`base64.bp` (see *Mechanism*), so a caller needs one import for the whole wire-format surface.

```bp
#[@External.Node("""Buffer.from($0, 'utf8').toString('hex')""")]
#[@External.Erlang("""string:lowercase(binary:encode_hex($0))""")]
pub declare fn hexEncode(s: string) -> string;

#[@result]
#[@External.Node("""(() => { try { return { ok: Buffer.from($0, 'hex').toString('utf8') } } catch (__e) { return { error: String(__e) } } })()""")]
#[@External.Erlang("""(fun(__H) -> try {ok, binary:decode_hex(string:uppercase(__H))} catch _:__E -> {error, iolist_to_binary(io_lib:format("~p", [__E]))} end end)($0)""")]
pub declare fn hexDecode(s: string) -> @Result<string, string>;

#[@External.Node("""encodeURIComponent($0)""")]
#[@External.Erlang("""uri_string:quote($0)""")]
pub declare fn percentEncode(s: string) -> string;

pub fn formStringify(pairs: Array<#(string, string)>) -> string {
    return pairs.map({ p -> percentEncode(p._0) + "=" + percentEncode(p._1) }).join("&");
}
```

**Acceptance:**
- [ ] `encoding.hexEncode("hi")` answers `6869` on both targets, lowercase
- [ ] `encoding.hexDecode("zz")` answers an `Error`, not a crash
- [ ] `encoding.percentEncode("a b&c=d")` answers `a%20b%26c%3Dd` on both targets
- [ ] `encoding.percentDecode(encoding.percentEncode(s)) == s` for a string containing space, `&`, `=`, `+`, `/` and a non-ASCII character
- [ ] `encoding.formStringify([#("q", "a b")])` answers `q=a%20b` — the case `querystring.stringify` documents itself as not handling
- [ ] `encoding.base64UrlEncode` output contains no `+`, `/` or `=`

### Step 4 — `hmac.bp`

The digests the security fronts actually need: base64url rather than hex, SHA-1 for the WebSocket
handshake, and a constant-time compare.

```bp
#[@External.Node("""require('crypto').createHmac('sha256', $0).update($1).digest('base64url')""")]
#[@External.Erlang("""(fun(__K, __D) -> __B = base64:encode(crypto:mac(hmac, sha256, __K, __D)), binary:replace(binary:replace(binary:replace(__B, <<"=">>, <<>>, [global]), <<"+">>, <<"-">>, [global]), <<"/">>, <<"_">>, [global]) end)($0, $1)""")]
pub declare fn hmacSha256Base64Url(key: string, data: string) -> string;

#[@External.Node("""require('crypto').createHash('sha1').update($0).digest('base64')""")]
#[@External.Erlang("""base64:encode(crypto:hash(sha, $0))""")]
pub declare fn sha1Base64(data: string) -> string;

#[@External.Node("""(() => { const __c = require('crypto'); const __a = Buffer.from($0); const __b = Buffer.from($1); return __a.length === __b.length && __c.timingSafeEqual(__a, __b) })()""")]
#[@External.Erlang("""crypto:hash_equals($0, $1)""")]
pub declare fn equalsConstantTime(a: string, b: string) -> bool;
```

**Acceptance:**
- [ ] `hmac.hmacSha256Base64Url("key", "The quick brown fox jumps over the lazy dog")` matches the RFC 4231 vector re-encoded as base64url, byte-identical on both targets
- [ ] `hmac.sha1Base64` reproduces the RFC 6455 §1.3 WebSocket accept-key example
- [ ] `hmac.sha256Base64Url("")` answers `47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU` on both targets
- [ ] `hmac.equalsConstantTime` answers false for equal-length-different and for different-length inputs, and never throws
- [ ] a test asserts `equalsConstantTime(x, x)` for a 43-character base64url signature — the exact shape front 10 compares

### Step 5 — `clock.bp`

Parsing, civil breakdown, durations and deadlines. The three readings `time.bp` already has are
re-declared here so a caller scheduling work needs one import rather than two; `time.bp` is not
edited and its callers are unaffected.

```bp
pub type Civil(
    year: i32, month: i32, day: i32,
    hour: i32, minute: i32, second: i32,
    weekday: i32,
)

pub type Duration(millis: i64)

#[@result]
#[@External.Node("""(() => { const __t = Date.parse($0); return Number.isNaN(__t) ? { error: 'not an RFC 3339 timestamp' } : { ok: __t } })()""")]
#[@External.Erlang("""(fun(__S) -> try {ok, calendar:rfc3339_to_system_time(binary_to_list(__S), [{unit, millisecond}])} catch _:_ -> {error, <<"not an RFC 3339 timestamp">>} end end)($0)""")]
pub declare fn parseIso8601(s: string) -> @Result<i64, string>;

pub fn seconds(n: i64) -> Duration { return Duration(millis: n * 1000); }
pub fn minutes(n: i64) -> Duration { return Duration(millis: n * 60000); }

// A deadline is an absolute epoch reading, so it survives being handed to
// another process — front 12 puts one in a cache entry and front 18 in a session.
pub fn deadline(d: Duration) -> i64 { return nowMillis() + d.millis; }
pub fn isExpired(at: i64) -> bool { return nowMillis() > at; }
```

**Acceptance:**
- [ ] `clock.parseIso8601(clock.formatIso8601(t))` answers `Ok(t)` truncated to whole seconds, on both targets
- [ ] `clock.parseIso8601("not a date")` answers an `Error` on both targets
- [ ] `clock.toCivil` of a fixed epoch reading answers the same `Civil` on both targets, and `weekday` follows ISO-8601 (Monday = 1)
- [ ] `clock.isExpired(clock.deadline(clock.seconds(60)))` is false; `clock.isExpired(0)` is true
- [ ] `clock.sleep(20)` returns after at least 20 monotonic milliseconds on both targets

### Step 6 — `random.bp` additions

The CSPRNG surface, appended below the existing `rand`-backed functions, which do not change. The
module docblock gains one sentence saying which half is which — a caller reaching for `float()` when
they wanted `secureToken()` is the bug this front is trying not to ship.

```bp
#[@External.Node("""require('crypto').randomBytes($0).toString('base64url')""")]
#[@External.Erlang("""(fun(__N) -> __B = base64:encode(crypto:strong_rand_bytes(__N)), binary:replace(binary:replace(binary:replace(__B, <<"=">>, <<>>, [global]), <<"+">>, <<"-">>, [global]), <<"/">>, <<"_">>, [global]) end)($0)""")]
pub declare fn secureToken(bytes: i32) -> string;

#[@External.Node("""require('crypto').randomUUID()""")]
#[@External.Erlang("""(fun() -> <<__A:32, __B:16, _:4, __C:12, _:2, __D:14, __E:48>> = crypto:strong_rand_bytes(16), iolist_to_binary(io_lib:format("~8.16.0b-~4.16.0b-4~3.16.0b-~4.16.0b-~12.16.0b", [__A, __B, __C, __D bor 16#8000, __E])) end)()""")]
pub declare fn uuidV4() -> string;
```

**Acceptance:**
- [ ] `random.secureToken(32)` answers 43 characters, containing none of `+`, `/`, `=`
- [ ] two consecutive `random.secureToken(16)` calls differ, on both targets
- [ ] `random.uuidV4()` matches `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$` on both targets
- [ ] the existing eight `random` functions are byte-unchanged and `random.seed`/`seededFloat` still round-trip

### Step 7 — `regex.bp` additions

Capture groups and a compiled-pattern handle. The route matcher in front 22 compiles each pattern
once at start-up and runs it per request; without `compile` it re-parses the pattern on every
request, which on the BEAM means `re:run/3` re-compiling inside the hot path.

```bp
pub type Regex(handle: any)

#[@result]
#[@External.Node("""(() => { try { return { ok: { handle: new RegExp($0) } } } catch (__e) { return { error: String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case re:compile(__P) of {ok, __M} -> {ok, #{handle => __M}}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn compile(pattern: string) -> @Result<Regex, string>;

// Every capture group, group 0 first. `null` when the pattern does not match —
// distinguishing "no match" from "matched with empty groups".
#[@External.Node("""(() => { const __m = $1.match(new RegExp($0)); return __m ? Array.from(__m).map(__g => __g ?? '') : null })()""")]
#[@External.Erlang("""(fun(__P, __S) -> case re:run(__S, __P, [{capture, all, binary}]) of {match, __G} -> __G; nomatch -> undefined end end)($0, $1)""")]
pub declare fn captures(pattern: string, input: string) -> ?Array<string>;
```

**Acceptance:**
- [ ] `regex.captures("^/blog/([^/]+)$", "/blog/hello")` answers a two-element array whose second element is `hello`, on both targets
- [ ] `regex.captures("^/x$", "/y")` answers `null`, not an empty array
- [ ] `regex.namedCaptures("(?<slug>[^/]+)", "/hello")` answers one `#("slug", "hello")` pair on both targets
- [ ] `regex.compile("(")` answers an `Error`; `regex.runCompiled` of a compiled pattern agrees with `regex.matches` of the same source
- [ ] `regex.escapeLiteral(".*")` answers a pattern that matches the literal `.*` and nothing else
- [ ] the six existing `regex` functions and the `Match` record are unchanged

### Step 8 — `process.bp` additions

Child processes and signals, appended below the five introspection functions.

```bp
pub type Exit(status: i32, stdout: string, stderr: string)

#[@result]
#[@External.Node("""(() => { try { const __r = require('child_process').spawnSync($0, $1, { encoding: 'utf8' }); return { ok: { status: __r.status ?? -1, stdout: __r.stdout ?? '', stderr: __r.stderr ?? '' } } } catch (__e) { return { error: String(__e) } } })()""")]
#[@External.Erlang("""(fun(__C, __A) -> try __P = open_port({spawn_executable, os:find_executable(binary_to_list(__C))}, [binary, exit_status, stderr_to_stdout, {args, [binary_to_list(__X) || __X <- __A]}]), __L = fun __F(__Acc) -> receive {__P, {data, __D}} -> __F([__D | __Acc]); {__P, {exit_status, __S}} -> {__S, iolist_to_binary(lists:reverse(__Acc))} end end, {__St, __Out} = __L([]), {ok, #{status => __St, stdout => __Out, stderr => <<>>}} catch _:__E -> {error, iolist_to_binary(io_lib:format("~p", [__E]))} end end)($0, $1)""")]
pub declare fn run(cmd: string, args: string[]) -> @Result<Exit, string>;
```

`stderr` is empty on the Erlang side because `stderr_to_stdout` folds the two streams — the record
keeps the field so the Node side stays faithful, and the docblock says which target splits them. A
front that needs them split on both targets is asking for a redirect through a temp file, and should
say so rather than assume.

**Acceptance:**
- [ ] `process.run("echo", ["hi"])` answers `Ok` with `status == 0` and `stdout` starting `hi`, on both targets
- [ ] `process.run("definitely-not-a-binary", [])` answers an `Error` rather than crashing the caller
- [ ] a non-zero exit is an `Ok` carrying that status, not an `Error` — the process ran, it just failed
- [ ] `process.runShell("exit 3")` is documented as status-losing on Erlang (`os:cmd/1` answers output only) and the docblock says so
- [ ] the five existing `process` functions are byte-unchanged

### Step 9 — `net.bp`

Last, because it is the only module that needs an OTP application running and the only one that
refuses one of the two targets.

```bp
//// std/net — TCP and TLS sockets. SERVER-ONLY.
////
//// Reference:
////   Erlang — https://www.erlang.org/doc/apps/kernel/gen_tcp.html
////            https://www.erlang.org/doc/apps/ssl/ssl.html
////   Node   — https://nodejs.org/api/net.html (for the shape only)
////
//// The commonJS cells are explicit refusals answering
//// `Error("std/net: server-only")`. Node's socket API is callback-driven and
//// cannot answer `accept` inline, and a browser has no listener at all. The
//// refusal keeps std compiling for both targets and makes the absence
//// assertable instead of hopeful.

pub type Listener(handle: any)
pub type Socket(handle: any)
pub type Peer(host: string, port: i32)

#[@result]
#[@External.Node("""({ error: 'std/net: server-only' })""")]
#[@External.Erlang("""(fun(__P, __B) -> case gen_tcp:listen(__P, [binary, {packet, raw}, {active, false}, {reuseaddr, true}, {backlog, __B}]) of {ok, __L} -> {ok, #{handle => __L}}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0, $1)""")]
pub declare fn listen(port: i32, backlog: i32) -> @Result<Listener, string>;

#[@result]
#[@External.Node("""({ error: 'std/net: server-only' })""")]
#[@External.Erlang("""(fun(__L, __T) -> case gen_tcp:accept(maps:get(handle, __L), __T) of {ok, __S} -> {ok, #{handle => __S}}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0, $1)""")]
pub declare fn accept(listener: Listener, timeoutMillis: i32) -> @Result<Socket, string>;
```

`recv`, `send`, `close`, `closeListener`, `connect`, `peer` follow the same shape; the TLS six are the
same again with `ssl:` in place of `gen_tcp:` and a `(catch ssl:start())` prelude, the idempotent
start `http.bp:54` already uses for `inets`.

**Acceptance:**
- [ ] on erlang, a test binds an ephemeral port, connects to itself, sends 11 bytes, receives the same 11 bytes, and closes both ends
- [ ] `net.accept` with a 50 ms timeout and no pending connection answers `Error("timeout")` rather than blocking the test
- [ ] `net.connect("127.0.0.1", <closed port>, 200)` answers an `Error` naming the refusal
- [ ] on commonJS, every `net` function answers `Error("std/net: server-only")` — asserted, not assumed
- [ ] `net.peer` of an accepted socket answers the loopback address
- [ ] the TLS path completes a handshake against a self-signed fixture cert and round-trips a payload

### Step 10 — `root.bp` exports

The last commit of the front, and the only shared file in track A. Five new lines for this front plus
the two that fronts 02 and 03 hand over:

```bp
pub mod net;
pub mod clock;
pub mod encoding;
pub mod hmac;
pub mod escape;
pub mod async;          // front 02
pub mod content_hash;   // front 03
```

**Acceptance:**
- [ ] `root.bp` declares all thirty-one modules and the build embeds each without a `build.zig` edit (`libs/std/AGENTS.md`)
- [ ] `import {net, clock, encoding, hmac, escape} from "std";` resolves from a consumer package
- [ ] `libs/std/AGENTS.md`'s tree listing names the five new files
- [ ] fronts 02 and 03 have landed first, so this commit adds their lines rather than waiting on them

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
| No bitwise operators (`&`, `\|`, `^`, `<<`, `>>`) | `random.uuidV4` must set the version/variant bits; `encoding.hexEncode` would fold nibbles | do the bit work inside the host template, in JS and Erlang | `&`, `\|`, `^`, `~`, `<<`, `>>` on the integer behaviors in `primitives.bp` |
| No byte/binary type — every host cell marshals through `string` | `hmac.*` cannot take a raw key; `random.secureToken` must answer base64url text rather than bytes; `net.recv` answers a UTF-8 `string` for what is a byte stream | text-encode at the boundary (hex or base64url) and accept that a non-UTF-8 payload is lossy on the Node side | a `bytes` primitive with `length`, `at`, `slice`, `concat`, and `@External` marshalling to an Erlang binary and a JS `Buffer` |
| A std module cannot call another std module | `clock.bp` re-declares `nowMillis`; `hmac.bp` re-declares SHA-256; `encoding.bp` re-declares base64 | re-declare the host cell in each module | make a cross-module bare import of an `#[@External.*]` symbol lower to the defining module's binding |
| Declared parameter defaults are never applied | `net.accept(l, timeoutMillis)`, `path.glob(pattern, root)`, `process.run(cmd, args)` all want a default and cannot have one | every call passes every argument | apply defaults at the call site |
| No `toString(radix)` on the integer behaviors | hex rendering in `encoding`, `hmac` and front 03 | render inside the host template | `fn toStringRadix(self: Self, radix: i32) -> string` on `Integer` |
| A closure passed to a host cell is unverified on the Erlang target | `process.onSignal(name, handler)` | leave signals out of the first cut; the CLI polls instead | pin fn-valued `$N` markers in the `@External.Erlang` template grammar |

## Test plan

Tests are inline `test` blocks at the bottom of each `src/*.bp`, which is what every existing std
module does (`time.bp:108`, `process.bp:66`, `fs.bp:107`) and what the lib-test harness runs. They
are invoked by `botopink test --target commonJS` and `botopink test --target erlang` from
`libs/std/`, and by `zig build test-libs` from `repository/botopink-lang/` as part of the ecosystem
gate.

What each module's tests assert:

- `escape.bp`, `path.bp` — pure functions, exact string equality, identical on every backend. These
  are the only modules in the front whose tests are fully deterministic cross-target.
- `encoding.bp`, `hmac.bp` — published vectors (RFC 4231 for HMAC-SHA256, RFC 6455 §1.3 for the
  WebSocket accept key, the empty-string SHA-256), asserted byte-identical on both targets. A digest
  that differs between targets is a failure, not a platform difference.
- `clock.bp` — round trips rather than absolutes (`parseIso8601(formatIso8601(t)) == t` to whole
  seconds), plus ordering assertions (`isExpired` before and after a `sleep`). Wall-clock values are
  never asserted directly.
- `random.bp` — shape and distinctness, never a specific value: length, alphabet, the UUID v4
  pattern, and two draws differing.
- `regex.bp` — the same pattern and input on both targets must answer the same captures. PCRE and
  `re` agree on the constructs used here; a test that needs a construct they disagree on belongs in
  the front that needs it, with its divergence documented.
- `process.bp` — `echo` and a missing binary, on both targets. `runShell`'s status-loss on Erlang is
  asserted as the documented behaviour rather than treated as a bug.
- `net.bp` — **erlang only for the real path**: bind, self-connect, round-trip, close. On commonJS
  the suite asserts the refusal. This is the one module where one target's coverage is a refusal
  assertion rather than behaviour, and the README says so rather than letting a green commonJS cell
  imply sockets work there.

## Definition of done

- Five new modules exist (`net`, `clock`, `encoding`, `hmac`, `escape`) and four existing ones gained
  the functions in the requirements table (`path`, `random`, `regex`, `process`).
- Every row of the requirements table is either implemented, or cited as already existing with its
  file and line.
- No new module imports another std module; no existing std module was edited outside the four this
  front owns.
- `src/root.bp` declares all thirty-one modules, including front 02's `async` and front 03's
  `content_hash`.
- `libs/std/AGENTS.md`'s tree listing is updated in the same commit as the files it describes.
- Every `// LANGUAGE GAP:` marker in this front's examples appears in the table above.
- The front's tests are green on its assigned target — here, both.
