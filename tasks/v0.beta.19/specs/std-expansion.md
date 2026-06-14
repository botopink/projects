# std-expansion — fill cross-backend stdlib gaps from Node + Erlang reference APIs

**Slug**: std-expansion
**Depends on**: `prim-op-annotation` (the rich annotation grammar — every new
  module here declares its host bindings via `#[@external(<target>, "<template>")]`;
  this spec assumes `$self` / `$0..N` / `$argc` / `$stringify(...)` / `"""…"""`
  templates are available)
**Reference URLs** (cited verbatim in every new `.bp` file's header):
  - Node.js stdlib: <https://nodejs.org/api/>
  - Erlang stdlib (OTP): <https://www.erlang.org/doc/apps/stdlib/api-reference.html>
**Files**: see §"Module inventory" below — 13 new `.bp` / `.d.bp` files
  under `libs/std/src/` + one `interface String` extension on
  `primitives.d.bp` + `libs/std/src/root.bp` (`pub mod` entries) +
  `libs/std/AGENTS.md` + `libs/std/docs.md` + `libs/std/examples.md` +
  `libs/std/tests/` (new per-module test files)
**Touches docs**: `libs/std/AGENTS.md` · `libs/std/docs.md` ·
  `libs/std/examples.md` · `modules/compiler-core/src/codegen/AGENTS.md`
  (per-backend coverage matrix per §"Coverage matrix") · `CHANGELOG.md`
**Status**: pending

## Premise

`libs/std/` today is intentionally minimal:

| Surface | What |
|---|---|
| `primitives.d.bp` | `Number` / `Integer` / `Signed` / `Float` / `Bool` / `String` / `Pair` / `Array` / `Function` interfaces — the type-system primitives |
| `builtins.d.bp` | `typeOf` / `sizeOf` / `panic` / `emit` / `external` + the six effect markers + `Result` / `Option` / `Iterator` / `Generator` / `Future` / `Context` |
| `dict.bp` / `queue.bp` / `sets.bp` | functional collections |
| `order.bp` | comparison enum |
| `string_builder.bp` | imperative string accumulator |

That's it. There's no `math`, no `json`, no `time`, no `regex`, no file or
env access, no `random`, no `url`, no `crypto`, no `os` info. Anyone
shipping a real botopink program currently reaches for the host directly
via raw `#[@external]` annotations. This spec identifies the gaps
cross-referenced against Node's stdlib (<https://nodejs.org/api/>) and
Erlang's stdlib (<https://www.erlang.org/doc/apps/stdlib/api-reference.html>),
and proposes a portable expansion that lowers cleanly on every backend
(commonJS + erlang + beam_asm where applicable; wat boundary per
§"Coverage matrix").

## Module inventory

Thirteen new modules + one extension to `primitives.d.bp`. Each row is
file-disjoint from the others; the wave column groups them for landing
order.

| Module | File | Wave | Surface area | Node ref | Erlang ref |
|---|---|---|---|---|---|
| `math` | `libs/std/src/math.bp` | §W1 | 30+ fns + 5 constants | [`Math`](https://nodejs.org/api/) global | [`math`](https://www.erlang.org/doc/apps/stdlib/math.html) |
| `json` | `libs/std/src/json.bp` | §W1 | parse / stringify + `JsonValue` enum | [`JSON`](https://nodejs.org/api/) global | [`json`](https://www.erlang.org/doc/apps/stdlib/json.html) (OTP 27+) |
| `base64` | `libs/std/src/base64.bp` | §W1 | encode / decode + url-safe variants | [`Buffer`](https://nodejs.org/api/buffer.html) `.toString('base64')` | [`base64`](https://www.erlang.org/doc/apps/stdlib/base64.html) |
| `time` | `libs/std/src/time.bp` | §W1 | wall + monotonic clocks + sleep + format | [`Date`](https://nodejs.org/api/), [`timers`](https://nodejs.org/api/timers.html) | [`erlang:system_time`](https://www.erlang.org/doc/man/erlang.html#system_time-0) + [`timer`](https://www.erlang.org/doc/apps/stdlib/timer.html) + [`calendar`](https://www.erlang.org/doc/apps/stdlib/calendar.html) |
| `random` | `libs/std/src/random.bp` | §W1 | floats / ints / sampling / seeding | `Math.random` | [`rand`](https://www.erlang.org/doc/apps/stdlib/rand.html) |
| `env` | `libs/std/src/env.bp` | §W2 | get / set / unset / args / vars map | [`process.env`](https://nodejs.org/api/process.html) | [`os:getenv`](https://www.erlang.org/doc/man/os.html) |
| `path` | `libs/std/src/path.bp` | §W2 | 9 fns: join / split / basename / dirname / extname / isAbsolute / normalize / relative / resolve | [`path`](https://nodejs.org/api/path.html) | [`filename`](https://www.erlang.org/doc/apps/stdlib/filename.html) |
| `fs` | `libs/std/src/fs.bp` | §W2 | read+write text, exists, list, mkdir, rm, stat, copy | [`fs`](https://nodejs.org/api/fs.html) | [`file`](https://www.erlang.org/doc/man/file.html) + [`filelib`](https://www.erlang.org/doc/apps/stdlib/filelib.html) |
| `process` | `libs/std/src/process.bp` | §W2 | exit / cwd / platform / arch / pid / hostname | [`process`](https://nodejs.org/api/process.html) | [`erlang:halt`](https://www.erlang.org/doc/man/erlang.html#halt-0) + [`os`](https://www.erlang.org/doc/man/os.html) |
| `os` | `libs/std/src/os.bp` | §W2 | hostname / arch / cpuCount / tmpdir / userInfo / eol | [`os`](https://nodejs.org/api/os.html) | [`os`](https://www.erlang.org/doc/man/os.html) |
| `regex` | `libs/std/src/regex.bp` | §W3 | match / matchAll / replace / test / split / compile | [`RegExp`](https://nodejs.org/api/) global | [`re`](https://www.erlang.org/doc/apps/stdlib/re.html) |
| `unicode` | `libs/std/src/unicode.bp` | §W3 | codepoints / normalize NFC/NFD/NFKC/NFKD / category | [`String.normalize`](https://nodejs.org/api/) global | [`unicode`](https://www.erlang.org/doc/apps/stdlib/unicode.html) |
| `array_ext` | extension methods on `interface Array<T>` in `primitives.d.bp` | §W3 | sort / find / findIndex / some / every / flatMap / flat / fill / chunked / sliding | [`Array.prototype`](https://nodejs.org/api/) global | [`lists`](https://www.erlang.org/doc/apps/stdlib/lists.html) |
| `string_ext` | extension methods on `interface String` in `primitives.d.bp` | §W3 | padStart / padEnd / repeat / replace / replaceAll / chars / lines / words / charCodeAt | `String.prototype` | [`string`](https://www.erlang.org/doc/apps/stdlib/string.html) |
| `url` | `libs/std/src/url.bp` | §W4 | parse / serialize / `Url` struct (scheme / host / port / path / query / fragment) | [`url`](https://nodejs.org/api/url.html) | [`uri_string`](https://www.erlang.org/doc/apps/stdlib/uri_string.html) |
| `querystring` | `libs/std/src/querystring.bp` | §W4 | parse / stringify (form-urlencoded) | [`querystring`](https://nodejs.org/api/querystring.html) | [`uri_string:dissect_query`](https://www.erlang.org/doc/apps/stdlib/uri_string.html) |
| `http` | `libs/std/src/http.bp` | §W4 | client only: send / get / postJson / `Request` / `Response` | [`http`](https://nodejs.org/api/http.html) | [`httpc`](https://www.erlang.org/doc/man/httpc.html) |
| `crypto` | `libs/std/src/crypto.bp` | §W4 | sha256 / sha512 / md5 / hmacSha256 / randomBytes | [`crypto`](https://nodejs.org/api/crypto.html) | [`crypto`](https://www.erlang.org/doc/man/crypto.html) |
| `assert` | `libs/std/src/assert.bp` | §W5 | 8 assertion fns + a `@assert(cond)` builtin macro | [`assert`](https://nodejs.org/api/assert.html) | (no equivalent — native pattern matching) |

## Coverage matrix (per backend)

Symbol: ✓ supported · ⚠ partial (see notes per module) · ✗ unsupported.

| Module | commonJS (node) | erlang | beam_asm | wat |
|---|---|---|---|---|
| `math` | ✓ | ✓ | ✓ | ⚠ (constants only; `sqrt`/`sin`/... missing wasm impls — module reds with `std-unsupported-on-wat`) |
| `json` | ✓ | ✓ (OTP 27+) | ✓ | ✗ |
| `base64` | ✓ | ✓ | ✓ | ✗ |
| `time` | ✓ | ✓ | ✓ | ⚠ (`nowMillis` via host import; `sleep` ✗) |
| `random` | ✓ | ✓ | ✓ | ⚠ (`float` via host import seed; advanced seeding ✗) |
| `env` | ✓ | ✓ | ✓ | ✗ |
| `path` | ✓ | ✓ | ✓ | ✓ (pure botopink; no host calls) |
| `fs` | ✓ | ✓ | ✓ | ✗ |
| `process` | ✓ | ✓ | ✓ | ⚠ (`exit` via `unreachable`; rest ✗) |
| `os` | ✓ | ✓ | ✓ | ✗ |
| `regex` | ✓ | ✓ | ✓ | ✗ |
| `unicode` | ✓ | ✓ | ✓ | ✗ |
| `array_ext` | ✓ | ✓ | ✓ | ⚠ (extends `Array<T>` — host bindings per method) |
| `string_ext` | ✓ | ✓ | ✓ | ⚠ (extends `String` — same shape) |
| `url` | ✓ | ✓ | ✓ | ✗ |
| `querystring` | ✓ | ✓ | ✓ | ✓ (pure botopink) |
| `http` | ✓ | ✓ | ✓ | ✗ |
| `crypto` | ✓ | ✓ | ✓ | ✗ |
| `assert` | ✓ | ✓ | ✓ | ✓ (pure botopink + `@panic`) |

A `from "std"` import of a module marked ✗ on the active target reds with
`std-unsupported-on-target: module 'foo' has no implementation for target 'wat'; see tasks/v0.beta.19/specs/std-expansion.md §"Coverage matrix".` The error fires
at type-check time (the annotation set is missing the active target's
template), not at link time.

---

## §W1 — essentials

### `math` — `libs/std/src/math.bp`

File header (verbatim, lands in the file):

```bp
//// std/math — math functions and constants (cross-backend).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/  (the `Math` global)
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/math.html
////
//// Surface mirrors the intersection of `Math.*` (JS) and `math:*` (Erlang).
//// Floor / ceil / round return i64 (not f64) to match common use.
//// Constants live as `pub val`; every fn is host-bound via #[@external].
```

#### Constants

```bp
pub val pi:        f64 = 3.141592653589793
pub val e:         f64 = 2.718281828459045
pub val tau:       f64 = 6.283185307179586
pub val sqrt2:     f64 = 1.4142135623730951
pub val ln2:       f64 = 0.6931471805599453
pub val ln10:      f64 = 2.302585092994046
pub val log2e:     f64 = 1.4426950408889634
pub val log10e:    f64 = 0.4342944819032518
pub val infinity:  f64 = 1e308 * 10.0   // host folds to +Infinity
pub val negInfinity: f64 = -infinity
pub val nan:       f64 = 0.0 / 0.0      // host folds to NaN
```

#### Arithmetic + rounding (10 fns)

```bp
// Absolute value (overloaded via Number interface — annotation set per
// branch ensures the right host call lands).
#[@external(node, "Math.abs($0)"), @external(erlang, "abs($0)"), @external(beam, "abs($0)")]
pub declare fn abs(x: f64) -> f64

#[@external(node, "Math.floor($0)"), @external(erlang, "trunc($0)"), @external(beam, "trunc($0)")]
pub declare fn floor(x: f64) -> i64

// ceil has no direct erlang BIF; emit inline arithmetic
#[@external(node,   "Math.ceil($0)"),
  @external(erlang, """
    (fun(__X) ->
        __T = trunc(__X),
        case (__X - __T) of
            0   -> __T;
            _   -> if __X > 0 -> __T + 1; true -> __T end
        end
    end)($0)
"""),
  @external(beam,   /* same erlang shape */)]
pub declare fn ceil(x: f64) -> i64

#[@external(node, "Math.round($0)"), @external(erlang, "round($0)"), @external(beam, "round($0)")]
pub declare fn round(x: f64) -> i64

#[@external(node, "Math.trunc($0)"), @external(erlang, "trunc($0)"), @external(beam, "trunc($0)")]
pub declare fn trunc(x: f64) -> i64

#[@external(node,   "Math.sign($0)"),
  @external(erlang, "(case $0 of N when N > 0 -> 1.0; N when N < 0 -> -1.0; _ -> 0.0 end)"),
  @external(beam,   /* same */)]
pub declare fn sign(x: f64) -> f64

#[@external(node, "Math.min($0, $1)"), @external(erlang, "min($0, $1)"), @external(beam, "min($0, $1)")]
pub declare fn minF(a: f64, b: f64) -> f64

#[@external(node, "Math.max($0, $1)"), @external(erlang, "max($0, $1)"), @external(beam, "max($0, $1)")]
pub declare fn maxF(a: f64, b: f64) -> f64

pub fn clamp(x: f64, lo: f64, hi: f64) -> f64 {
    return maxF(lo, minF(hi, x))
}
```

#### Powers + roots + exp/log (8 fns)

```bp
#[@external(node, "Math.sqrt($0)"), @external(erlang, "math:sqrt($0)"), @external(beam, "math:sqrt($0)")]
pub declare fn sqrt(x: f64) -> f64

#[@external(node, "Math.cbrt($0)"), @external(erlang, "math:pow($0, 1.0 / 3.0)"), @external(beam, /* same */)]
pub declare fn cbrt(x: f64) -> f64

#[@external(node, "Math.pow($0, $1)"), @external(erlang, "math:pow($0, $1)"), @external(beam, "math:pow($0, $1)")]
pub declare fn pow(x: f64, y: f64) -> f64

#[@external(node, "Math.exp($0)"), @external(erlang, "math:exp($0)"), @external(beam, "math:exp($0)")]
pub declare fn exp(x: f64) -> f64

#[@external(node, "Math.log($0)"), @external(erlang, "math:log($0)"), @external(beam, "math:log($0)")]
pub declare fn ln(x: f64) -> f64

#[@external(node, "Math.log2($0)"), @external(erlang, "math:log2($0)"), @external(beam, "math:log2($0)")]
pub declare fn log2(x: f64) -> f64

#[@external(node, "Math.log10($0)"), @external(erlang, "math:log10($0)"), @external(beam, "math:log10($0)")]
pub declare fn log10(x: f64) -> f64

#[@external(node, "Math.hypot($0, $1)"), @external(erlang, "math:sqrt($0 * $0 + $1 * $1)"), @external(beam, /* same */)]
pub declare fn hypot(x: f64, y: f64) -> f64
```

#### Trigonometry (10 fns)

```bp
#[@external(node, "Math.sin($0)"),   @external(erlang, "math:sin($0)"),   @external(beam, /* same */)]
pub declare fn sin(x: f64) -> f64
#[@external(node, "Math.cos($0)"),   @external(erlang, "math:cos($0)"),   @external(beam, /* same */)]
pub declare fn cos(x: f64) -> f64
#[@external(node, "Math.tan($0)"),   @external(erlang, "math:tan($0)"),   @external(beam, /* same */)]
pub declare fn tan(x: f64) -> f64
#[@external(node, "Math.asin($0)"),  @external(erlang, "math:asin($0)"),  @external(beam, /* same */)]
pub declare fn asin(x: f64) -> f64
#[@external(node, "Math.acos($0)"),  @external(erlang, "math:acos($0)"),  @external(beam, /* same */)]
pub declare fn acos(x: f64) -> f64
#[@external(node, "Math.atan($0)"),  @external(erlang, "math:atan($0)"),  @external(beam, /* same */)]
pub declare fn atan(x: f64) -> f64
#[@external(node, "Math.atan2($0, $1)"), @external(erlang, "math:atan2($0, $1)"), @external(beam, /* same */)]
pub declare fn atan2(y: f64, x: f64) -> f64
#[@external(node, "Math.sinh($0)"),  @external(erlang, "math:sinh($0)"),  @external(beam, /* same */)]
pub declare fn sinh(x: f64) -> f64
#[@external(node, "Math.cosh($0)"),  @external(erlang, "math:cosh($0)"),  @external(beam, /* same */)]
pub declare fn cosh(x: f64) -> f64
#[@external(node, "Math.tanh($0)"),  @external(erlang, "math:tanh($0)"),  @external(beam, /* same */)]
pub declare fn tanh(x: f64) -> f64
```

#### Inline tests (land verbatim in `math.bp`)

```bp
test "math.abs of -5 is 5" {
    @assert(math.abs(-5.0) == 5.0)
}

test "math.floor of 3.7 is 3" {
    @assert(math.floor(3.7) == 3)
}

test "math.ceil of 3.2 is 4" {
    @assert(math.ceil(3.2) == 4)
}

test "math.round of 0.5 is 1" {
    @assert(math.round(0.5) == 1)
}

test "math.sqrt of 4 is 2" {
    @assert(math.sqrt(4.0) == 2.0)
}

test "math.pow of 2^10 is 1024" {
    @assert(math.pow(2.0, 10.0) == 1024.0)
}

test "math.pi is 3.14159..." {
    @assert(math.pi > 3.141 && math.pi < 3.142)
}

test "math.sin(0) is 0" {
    @assert(math.sin(0.0) == 0.0)
}

test "math.atan2(1, 0) is pi/2" {
    @assert(math.atan2(1.0, 0.0) > 1.570 && math.atan2(1.0, 0.0) < 1.571)
}

test "math.clamp keeps value in range" {
    @assert(math.clamp(5.0, 0.0, 10.0) == 5.0)
    @assert(math.clamp(-5.0, 0.0, 10.0) == 0.0)
    @assert(math.clamp(15.0, 0.0, 10.0) == 10.0)
}

test "math.hypot of (3, 4) is 5" {
    @assert(math.hypot(3.0, 4.0) == 5.0)
}
```

### `json` — `libs/std/src/json.bp`

File header:

```bp
//// std/json — JSON encode / decode.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/  (the `JSON` global)
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/json.html  (OTP 27+)
////
//// Round-trip safe for valid JSON; uses {ok, V} / {error, Reason} on parse
//// failure. Numbers are f64 across backends — integer fidelity may degrade
//// past 2^53 on commonJS. Object key order is preserved (insertion order on
//// JS, map ordering on Erlang OTP 27+).
```

#### Surface

```bp
pub enum JsonValue {
    Null,
    Bool(value: bool),
    Number(value: f64),
    String(value: string),
    Array(items: JsonValue[]),
    Object(entries: Dict<string, JsonValue>);
}

#[@result]
#[@external(node,   """
    (() => {
        try { return { ok: __toJsonValue(JSON.parse($0)) }; }
        catch (e) { return { error: String(e) }; }
    })()
"""),
  @external(erlang, """
    (fun() ->
        try { ok, __to_json_value(json:decode($0)) }
        catch _:E -> { error, io_lib:format("~p", [E]) }
        end
    end)()
"""),
  @external(beam, /* same erlang shape */)]
pub declare fn parse(source: string) -> @Result<JsonValue, string>

#[@external(node,   "JSON.stringify(__fromJsonValue($0))"),
  @external(erlang, "json:encode(__from_json_value($0))"),
  @external(beam,   /* same */)]
pub declare fn stringify(value: JsonValue) -> string

// Pretty-printed stringify (indent 2 spaces).
#[@external(node,   "JSON.stringify(__fromJsonValue($0), null, 2)"),
  @external(erlang, "json:encode(__from_json_value($0), [pretty])"),
  @external(beam,   /* same */)]
pub declare fn stringifyPretty(value: JsonValue) -> string

// Convenience constructors.
pub fn obj(entries: Pair<string, JsonValue>[]) -> JsonValue {
    let d = dict.empty<string, JsonValue>()
    for entry in entries { d.insert(entry.a, entry.b) }
    return JsonValue::Object(d)
}

pub fn arr(items: JsonValue[]) -> JsonValue {
    return JsonValue::Array(items)
}
```

The `__toJsonValue` / `__fromJsonValue` adapters live in a host-side
sidecar (`.mjs` on node, helper module on erlang) shipped by the std
build. They convert between the host's native JSON tree and the
`JsonValue` enum representation; see `comptime/AGENTS.md`
§"std-shipped sidecars" for the build-time wiring.

#### Inline tests

```bp
test "json.stringify of null" {
    @assert(json.stringify(JsonValue::Null) == "null")
}

test "json.stringify of true" {
    @assert(json.stringify(JsonValue::Bool(true)) == "true")
}

test "json.stringify of a number" {
    @assert(json.stringify(JsonValue::Number(3.14)) == "3.14")
}

test "json.stringify of a string with escapes" {
    @assert(json.stringify(JsonValue::String("hi \"x\"")) == "\"hi \\\"x\\\"\"")
}

test "json.parse round-trip of an object" {
    let src = "{\"k\":1,\"v\":\"a\"}"
    let parsed = json.parse(src)?
    @assert(json.stringify(parsed) == src)
}

test "json.parse of malformed input returns Err" {
    let r = json.parse("{bad")
    @assert(r.isError())
}

test "json.obj + arr constructors round-trip" {
    let v = json.obj([
        pair("name", JsonValue::String("alice")),
        pair("scores", json.arr([JsonValue::Number(10.0), JsonValue::Number(20.0)])),
    ])
    let s = json.stringify(v)
    @assert(json.parse(s)?.stringify() == s)
}
```

### `base64` — `libs/std/src/base64.bp`

File header:

```bp
//// std/base64 — base64 encode / decode (RFC 4648 + URL-safe variant).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/buffer.html  (Buffer.from / .toString('base64'))
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/base64.html
////
//// Standard alphabet `+`/`/` + padding; `urlSafe*` variants use `-`/`_` with
//// no padding (per RFC 4648 §5). Input is treated as UTF-8 text; for raw
//// bytes wait for the `bytes` type (recorded out of scope).
```

#### Surface

```bp
#[@external(node,   "Buffer.from($0, 'utf8').toString('base64')"),
  @external(erlang, "binary_to_list(base64:encode(list_to_binary($0)))"),
  @external(beam,   /* same */)]
pub declare fn encode(input: string) -> string

#[@result]
#[@external(node,   """
    (() => {
        try { return { ok: Buffer.from($0, 'base64').toString('utf8') }; }
        catch (e) { return { error: String(e) }; }
    })()
"""),
  @external(erlang, """
    (fun() ->
        try { ok, binary_to_list(base64:decode(list_to_binary($0))) }
        catch _:E -> { error, io_lib:format("~p", [E]) }
        end
    end)()
"""),
  @external(beam, /* same erlang */)]
pub declare fn decode(input: string) -> @Result<string, string>

// URL-safe variant: '+' → '-', '/' → '_', strip padding.
pub fn encodeUrlSafe(input: string) -> string {
    let s = encode(input)
    return s.replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "")
}

pub fn decodeUrlSafe(input: string) -> @Result<string, string> {
    let pad_len = (4 - input.length % 4) % 4
    let padded = input.replaceAll("-", "+").replaceAll("_", "/") + "=".repeat(pad_len)
    return decode(padded)
}
```

#### Inline tests

```bp
test "base64.encode of empty string" {
    @assert(base64.encode("") == "")
}

test "base64.encode of 'hello'" {
    @assert(base64.encode("hello") == "aGVsbG8=")
}

test "base64.decode round-trip" {
    let s = "the quick brown fox"
    @assert(base64.decode(base64.encode(s))? == s)
}

test "base64.decode of malformed reds" {
    @assert(base64.decode("!!!").isError())
}

test "base64.encodeUrlSafe strips padding" {
    let s = base64.encodeUrlSafe("hi")
    @assert(!s.contains("="))
}

test "base64.url-safe round-trip" {
    let s = "the quick brown fox"
    @assert(base64.decodeUrlSafe(base64.encodeUrlSafe(s))? == s)
}
```

### `time` — `libs/std/src/time.bp`

File header:

```bp
//// std/time — wall-clock and monotonic time + sleep + ISO 8601 helpers.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/  (Date global)
////              https://nodejs.org/api/timers.html
////   Erlang   — https://www.erlang.org/doc/man/erlang.html#system_time-0
////              https://www.erlang.org/doc/apps/stdlib/timer.html
////              https://www.erlang.org/doc/apps/stdlib/calendar.html
////
//// `nowMillis()` is wall-clock; `monotonicMillis()` is for measuring
//// durations (immune to wall-clock jumps). `sleep` is #[@future] — async
//// on node (Promise via setTimeout), blocking on erlang/beam (timer:sleep
//// wrapped in the same shape).
```

#### Surface

```bp
// Wall-clock milliseconds since the Unix epoch.
#[@external(node,   "Date.now()"),
  @external(erlang, "erlang:system_time(millisecond)"),
  @external(beam,   "erlang:system_time(millisecond)")]
pub declare fn nowMillis() -> i64

// Wall-clock nanoseconds since the Unix epoch.
#[@external(node,   "Number(process.hrtime.bigint())"),
  @external(erlang, "erlang:system_time(nanosecond)"),
  @external(beam,   "erlang:system_time(nanosecond)")]
pub declare fn nowNanos() -> i64

// Monotonic milliseconds since an arbitrary fixed point.
#[@external(node,   "Number(process.hrtime.bigint() / 1000000n)"),
  @external(erlang, "erlang:monotonic_time(millisecond)"),
  @external(beam,   "erlang:monotonic_time(millisecond)")]
pub declare fn monotonicMillis() -> i64

// Sleep for `millis` milliseconds. Async on node, blocking on erlang/beam.
#[@future]
#[@external(node,   "new Promise(resolve => setTimeout(resolve, $0))"),
  @external(erlang, "(timer:sleep($0), ok)"),
  @external(beam,   "(timer:sleep($0), ok)")]
pub declare fn sleep(millis: i64) -> @Future<unit, never>

// ISO 8601 string of a wall-clock millisecond reading.
#[@external(node,   "(new Date($0)).toISOString()"),
  @external(erlang, """
    (fun(__Ms) ->
        __S = __Ms div 1000,
        __M = __Ms rem 1000,
        {{Y, Mo, D}, {H, Mi, Se}} = calendar:gregorian_seconds_to_datetime(
            __S + calendar:datetime_to_gregorian_seconds({{1970,1,1},{0,0,0}})),
        io_lib:format("~4..0w-~2..0w-~2..0wT~2..0w:~2..0w:~2..0w.~3..0wZ",
                      [Y, Mo, D, H, Mi, Se, __M])
    end)($0)
"""),
  @external(beam, /* same */)]
pub declare fn formatIso8601(millis: i64) -> string

// Convenience: measure how long `body` takes (millis).
pub fn measureMillis<T>(body: fn() -> T) -> Pair<T, i64> {
    let start = monotonicMillis()
    let v = body()
    let elapsed = monotonicMillis() - start
    return pair(v, elapsed)
}
```

#### Inline tests

```bp
test "time.nowMillis is positive" {
    @assert(time.nowMillis() > 0)
}

test "time.monotonic non-decreasing" {
    let a = time.monotonicMillis()
    let b = time.monotonicMillis()
    @assert(b >= a)
}

test "time.sleep blocks (or awaits) for ~10ms" {
    let start = time.monotonicMillis()
    await time.sleep(10)
    let elapsed = time.monotonicMillis() - start
    @assert(elapsed >= 10)
}

test "time.formatIso8601 starts with year" {
    let s = time.formatIso8601(0)
    @assert(s.startsWith("1970-01-01T"))
}

test "time.measureMillis returns (value, duration)" {
    let result = time.measureMillis({-> 42})
    @assert(result.a == 42)
    @assert(result.b >= 0)
}
```

### `random` — `libs/std/src/random.bp`

File header:

```bp
//// std/random — pseudo-random numbers and sampling.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/  (Math.random)
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/rand.html
////
//// Default generator is unseeded — re-seed for reproducibility (`seed`).
//// `pick` / `shuffle` are pure botopink; the host primitive is `float()`.
```

#### Surface

```bp
// Random float in [0, 1).
#[@external(node,   "Math.random()"),
  @external(erlang, "rand:uniform()"),
  @external(beam,   "rand:uniform()")]
pub declare fn float() -> f64

// Seed the generator. Best-effort on node (no built-in seedable generator
// — emits a noop with a warning; reproducible randomness needs a userland
// library for now); deterministic on erlang/beam.
#[@external(node,   "(() => { /* TODO: PRNG userland */ })()"),
  @external(erlang, "(rand:seed(exsss, {$0, $0, $0}), ok)"),
  @external(beam,   /* same erlang */)]
pub declare fn seed(value: i64) -> unit

// Random integer in [min, max).
pub fn intInRange(min: i32, max: i32) -> i32 {
    let r = float()
    return min + (r * ((max - min)).toF64()).floor().toI32()
}

// Random bool with the given true-probability (default 0.5).
pub fn bool(probability: f64 = 0.5) -> bool {
    return float() < probability
}

// Pick a random element from a non-empty array; returns ?T (None if empty).
pub fn pick<T>(xs: Array<T>) -> ?T {
    if xs.isEmpty() { return null }
    return xs.at(intInRange(0, xs.length))
}

// Fisher–Yates shuffle, returning a new array.
pub fn shuffle<T>(xs: Array<T>) -> Array<T> {
    let r = xs.toMutable()
    var i = r.length - 1
    while i > 0 {
        let j = intInRange(0, i + 1)
        let tmp = r.at(i)
        r.set(i, r.at(j))
        r.set(j, tmp)
        i = i - 1
    }
    return r.freeze()
}
```

#### Inline tests

```bp
test "random.float is in [0, 1)" {
    let r = random.float()
    @assert(r >= 0.0)
    @assert(r < 1.0)
}

test "random.intInRange respects bounds" {
    let r = random.intInRange(0, 10)
    @assert(r >= 0 && r < 10)
}

test "random.pick from empty returns None" {
    @assert(random.pick<i32>([]) == null)
}

test "random.pick from singleton returns it" {
    @assert(random.pick([42]) == 42)
}

test "random.shuffle preserves length and elements" {
    let xs = [1, 2, 3, 4, 5]
    let ys = random.shuffle(xs)
    @assert(ys.length == xs.length)
    @assert(ys.contains(1) && ys.contains(5))
}
```

---

## §W2 — system

### `env` — `libs/std/src/env.bp`

File header:

```bp
//// std/env — environment variables and program arguments.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/process.html  (process.env, process.argv)
////   Erlang   — https://www.erlang.org/doc/man/os.html  (os:getenv, os:putenv)
////
//// `get(name)` returns `?string` (None when unset). `args()` returns user
//// args only (program path excluded). `set`/`unset` mutate the process
//// table — global state, use sparingly.
```

#### Surface

```bp
#[@external(node,   "(process.env[$0] ?? undefined)"),
  @external(erlang, "(case os:getenv($0) of false -> undefined; V -> V end)"),
  @external(beam,   /* same erlang */)]
pub declare fn get(name: string) -> ?string

#[@external(node,   "(process.env[$0] = $1, undefined)"),
  @external(erlang, "(os:putenv($0, $1), ok)"),
  @external(beam,   /* same */)]
pub declare fn set(name: string, value: string) -> unit

#[@external(node,   "(delete process.env[$0], undefined)"),
  @external(erlang, "(os:unsetenv($0), ok)"),
  @external(beam,   /* same */)]
pub declare fn unset(name: string) -> unit

// All variables as a Dict<string, string>.
#[@external(node,   "Object.fromEntries(Object.entries(process.env))"),
  @external(erlang, "maps:from_list([{K, V} || S <- os:getenv(), [K | V] <- [string:split(S, \"=\")]])"),
  @external(beam,   /* same erlang */)]
pub declare fn vars() -> Dict<string, string>

// Program arguments excluding the program path.
#[@external(node,   "process.argv.slice(2)"),
  @external(erlang, """
    (fun() ->
        case init:get_argument(extra) of
            {ok, [_ | Rest]} -> Rest;
            _ -> []
        end
    end)()
"""),
  @external(beam, /* same erlang */)]
pub declare fn args() -> string[]
```

#### Inline tests

```bp
test "env.get of an unset var is None" {
    @assert(env.get("__BOTOPINK_TEST_UNSET__") == null)
}

test "env.set + env.get round-trip" {
    env.set("__BOTOPINK_TEST__", "hello")
    @assert(env.get("__BOTOPINK_TEST__") == "hello")
    env.unset("__BOTOPINK_TEST__")
    @assert(env.get("__BOTOPINK_TEST__") == null)
}

test "env.args returns an array" {
    let a = env.args()
    @assert(a.length >= 0)
}
```

### `path` — `libs/std/src/path.bp`

File header:

```bp
//// std/path — file path manipulation (POSIX-style).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/path.html
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/filename.html
////
//// Joins, splits, and normalises path strings. Wholly pure botopink — no
//// host calls (so this module is one of the few that ships green on wat).
//// Operates on POSIX-style paths ("/" separator); Windows backslash paths
//// are not normalised in v0.beta.19 (recorded follow-up).
```

#### Surface

```bp
pub val separator: string = "/"
pub val delimiter: string = ":"

pub fn join(parts: string[]) -> string {
    let filtered = parts.filter({p -> !p.isEmpty()})
    if filtered.isEmpty() { return "" }
    return filtered.reduce({acc, p ->
        if acc.endsWith("/") || p.startsWith("/") {
            acc + p
        } else {
            acc + "/" + p
        }
    })
}

pub fn basename(p: string) -> string {
    let i = p.lastIndexOf("/")
    if i == -1 { return p }
    return p.slice(i + 1)
}

pub fn dirname(p: string) -> string {
    let i = p.lastIndexOf("/")
    if i == -1 { return "." }
    if i == 0 { return "/" }
    return p.slice(0, i)
}

pub fn extname(p: string) -> string {
    let base = basename(p)
    let i = base.lastIndexOf(".")
    if i <= 0 { return "" }
    return base.slice(i)
}

pub fn isAbsolute(p: string) -> bool {
    return p.startsWith("/")
}

pub fn normalize(p: string) -> string {
    let segs = p.split("/").filter({s -> !s.isEmpty() && s != "."})
    var stack: string[] = []
    for s in segs {
        if s == ".." {
            if !stack.isEmpty() && stack.at(-1) != ".." { stack = stack.dropLast() }
            else if !p.startsWith("/") { stack = stack.push(s) }
        } else {
            stack = stack.push(s)
        }
    }
    let joined = stack.joinSep("/")
    if p.startsWith("/") { return "/" + joined }
    if joined.isEmpty() { return "." }
    return joined
}

pub fn relative(from: string, to: string) -> string {
    let f = normalize(from).split("/").filter({s -> !s.isEmpty()})
    let t = normalize(to).split("/").filter({s -> !s.isEmpty()})
    var i = 0
    while i < f.length && i < t.length && f.at(i) == t.at(i) { i = i + 1 }
    let ups = (f.length - i)
    let downs = t.slice(i)
    return [".."].repeat(ups).concat(downs).joinSep("/")
}

pub fn resolve(parts: string[]) -> string {
    return normalize(join(parts))
}
```

#### Inline tests

```bp
test "path.join of three parts" {
    @assert(path.join(["a", "b", "c"]) == "a/b/c")
}

test "path.join skips empty parts" {
    @assert(path.join(["a", "", "b"]) == "a/b")
}

test "path.basename of '/a/b/c.bp' is 'c.bp'" {
    @assert(path.basename("/a/b/c.bp") == "c.bp")
}

test "path.dirname of '/a/b/c.bp' is '/a/b'" {
    @assert(path.dirname("/a/b/c.bp") == "/a/b")
}

test "path.dirname of bare filename is '.'" {
    @assert(path.dirname("file.bp") == ".")
}

test "path.extname of 'foo.tar.gz' is '.gz'" {
    @assert(path.extname("foo.tar.gz") == ".gz")
}

test "path.extname of 'no-ext' is empty" {
    @assert(path.extname("no-ext") == "")
}

test "path.isAbsolute" {
    @assert(path.isAbsolute("/foo"))
    @assert(!path.isAbsolute("foo"))
}

test "path.normalize collapses dots" {
    @assert(path.normalize("/a/./b/../c") == "/a/c")
}

test "path.relative across siblings" {
    @assert(path.relative("/a/b/c", "/a/d/e") == "../../d/e")
}
```

### `fs` — `libs/std/src/fs.bp`

File header:

```bp
//// std/fs — filesystem operations.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/fs.html
////   Erlang   — https://www.erlang.org/doc/man/file.html
////              https://www.erlang.org/doc/apps/stdlib/filelib.html
////
//// All fns are #[@result] — file ops fail. Text I/O is UTF-8; binary I/O
//// waits on the `bytes` type (recorded out of scope). Synchronous on every
//// backend — async file I/O ships when streams settle.
```

#### Surface

```bp
#[@result]
#[@external(node,   """
    (() => {
        try { return { ok: require('fs').readFileSync($0, 'utf8') }; }
        catch (e) { return { error: String(e) }; }
    })()
"""),
  @external(erlang, """
    (fun() ->
        case file:read_file($0) of
            {ok, B} -> {ok, binary_to_list(B)};
            {error, R} -> {error, atom_to_list(R)}
        end
    end)()
"""),
  @external(beam, /* same */)]
pub declare fn readText(p: string) -> @Result<string, string>

#[@result]
#[@external(node,   """
    (() => {
        try { require('fs').writeFileSync($0, $1, 'utf8'); return { ok: ({}) }; }
        catch (e) { return { error: String(e) }; }
    })()
"""),
  @external(erlang, """
    (fun() ->
        case file:write_file($0, list_to_binary($1)) of
            ok -> {ok, {}};
            {error, R} -> {error, atom_to_list(R)}
        end
    end)()
"""),
  @external(beam, /* same */)]
pub declare fn writeText(p: string, content: string) -> @Result<unit, string>

#[@external(node,   "require('fs').existsSync($0)"),
  @external(erlang, "filelib:is_file($0)"),
  @external(beam,   /* same */)]
pub declare fn exists(p: string) -> bool

#[@external(node,   "require('fs').statSync($0).isDirectory()"),
  @external(erlang, "filelib:is_dir($0)"),
  @external(beam,   /* same */)]
pub declare fn isDir(p: string) -> bool

#[@result]
#[@external(node,   """
    (() => {
        try { return { ok: require('fs').readdirSync($0) }; }
        catch (e) { return { error: String(e) }; }
    })()
"""),
  @external(erlang, """
    (fun() ->
        case file:list_dir($0) of
            {ok, Files} -> {ok, Files};
            {error, R} -> {error, atom_to_list(R)}
        end
    end)()
"""),
  @external(beam, /* same */)]
pub declare fn listDir(p: string) -> @Result<string[], string>

#[@result]
#[@external(node,   """
    (() => {
        try { require('fs').mkdirSync($0, { recursive: true }); return { ok: ({}) }; }
        catch (e) { return { error: String(e) }; }
    })()
"""),
  @external(erlang, """
    (case filelib:ensure_dir(filename:join($0, "x")) of
         ok -> {ok, {}};
         {error, R} -> {error, atom_to_list(R)}
     end)
"""),
  @external(beam, /* same */)]
pub declare fn mkdirAll(p: string) -> @Result<unit, string>

#[@result]
#[@external(node,   """
    (() => {
        try { require('fs').unlinkSync($0); return { ok: ({}) }; }
        catch (e) { return { error: String(e) }; }
    })()
"""),
  @external(erlang, """
    (case file:delete($0) of
         ok -> {ok, {}};
         {error, R} -> {error, atom_to_list(R)}
     end)
"""),
  @external(beam, /* same */)]
pub declare fn remove(p: string) -> @Result<unit, string>

#[@result]
pub fn copy(src: string, dst: string) -> @Result<unit, string> {
    let content = readText(src)?
    return writeText(dst, content)
}

#[@result]
#[@external(node,   "(() => { const s = require('fs').statSync($0); return { ok: { size: s.size, isDir: s.isDirectory(), mtime: s.mtimeMs } }; })()"),
  @external(erlang, "(case file:read_file_info($0) of {ok, I} -> {ok, #{size => I#file_info.size, isDir => I#file_info.type =:= directory, mtime => 0}}; {error, R} -> {error, atom_to_list(R)} end)"),
  @external(beam,   /* same */)]
pub declare fn stat(p: string) -> @Result<FileStat, string>

pub struct FileStat {
    size: i64,
    isDir: bool,
    mtime: f64,        // millis since epoch
}
```

#### Inline tests

```bp
test "fs.exists on a known-good path" {
    @assert(fs.exists("./LICENSE") || fs.exists("./README.md"))
}

test "fs.exists on a definitely-missing path" {
    @assert(!fs.exists("/__no_such_path_botopink_test__"))
}

test "fs.readText round-trip via writeText" {
    let p = "/tmp/__botopink_fs_test"
    fs.writeText(p, "hello")?
    @assert(fs.readText(p)? == "hello")
    fs.remove(p)?
}

test "fs.readText of missing path returns Err" {
    @assert(fs.readText("/__no_such_path__").isError())
}

test "fs.listDir of '.' is non-empty" {
    @assert(fs.listDir(".")?.length > 0)
}

test "fs.mkdirAll of nested then exists" {
    let p = "/tmp/__bp_test/a/b"
    fs.mkdirAll(p)?
    @assert(fs.exists(p))
    fs.remove("/tmp/__bp_test/a/b")?
}
```

### `process` — `libs/std/src/process.bp`

File header:

```bp
//// std/process — process-level operations.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/process.html
////   Erlang   — https://www.erlang.org/doc/man/erlang.html#halt-0
////              https://www.erlang.org/doc/man/os.html
```

#### Surface

```bp
#[@external(node,   "process.exit($0)"),
  @external(erlang, "erlang:halt($0)"),
  @external(beam,   "erlang:halt($0)")]
pub declare fn exit(code: i32) -> never

#[@external(node,   "process.cwd()"),
  @external(erlang, "(fun() -> {ok, D} = file:get_cwd(), D end)()"),
  @external(beam,   /* same */)]
pub declare fn cwd() -> string

#[@external(node,   "process.chdir($0)"),
  @external(erlang, "(file:set_cwd($0), ok)"),
  @external(beam,   /* same */)]
pub declare fn chdir(p: string) -> unit

#[@external(node,   "process.platform"),
  @external(erlang, "atom_to_list(case os:type() of {unix, U} -> U; {win32, _} -> win32 end)"),
  @external(beam,   /* same */)]
pub declare fn platform() -> string

#[@external(node,   "process.pid"),
  @external(erlang, "list_to_integer(pid_to_list(self()))"),  // erlang pids aren't ints; this is a hash
  @external(beam,   /* same */)]
pub declare fn pid() -> i32
```

#### Inline tests

```bp
test "process.cwd returns a non-empty string" {
    @assert(!process.cwd().isEmpty())
}

test "process.platform is one of the known values" {
    let p = process.platform()
    @assert(p == "linux" || p == "darwin" || p == "win32" || p == "freebsd")
}
```

### `os` — `libs/std/src/os.bp`

File header:

```bp
//// std/os — operating system information.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/os.html
////   Erlang   — https://www.erlang.org/doc/man/os.html
```

#### Surface

```bp
#[@external(node,   "require('os').hostname()"),
  @external(erlang, "(fun() -> {ok, H} = inet:gethostname(), H end)()"),
  @external(beam,   /* same */)]
pub declare fn hostname() -> string

#[@external(node,   "require('os').arch()"),
  @external(erlang, "erlang:system_info(system_architecture)"),
  @external(beam,   /* same */)]
pub declare fn arch() -> string

#[@external(node,   "require('os').cpus().length"),
  @external(erlang, "erlang:system_info(logical_processors_available)"),
  @external(beam,   /* same */)]
pub declare fn cpuCount() -> i32

#[@external(node,   "require('os').tmpdir()"),
  @external(erlang, "(case os:getenv(\"TMPDIR\") of false -> \"/tmp\"; V -> V end)"),
  @external(beam,   /* same */)]
pub declare fn tmpdir() -> string

#[@external(node,   "require('os').homedir()"),
  @external(erlang, "(case os:getenv(\"HOME\") of false -> \"/\"; V -> V end)"),
  @external(beam,   /* same */)]
pub declare fn homedir() -> string

#[@external(node,   "require('os').EOL"),
  @external(erlang, "(case os:type() of {unix, _} -> \"\\n\"; _ -> \"\\r\\n\" end)"),
  @external(beam,   /* same */)]
pub declare fn eol() -> string
```

#### Inline tests

```bp
test "os.hostname is non-empty" {
    @assert(!os.hostname().isEmpty())
}

test "os.cpuCount is positive" {
    @assert(os.cpuCount() > 0)
}

test "os.tmpdir exists" {
    @assert(fs.exists(os.tmpdir()))
}

test "os.eol is \\n or \\r\\n" {
    let e = os.eol()
    @assert(e == "\n" || e == "\r\n")
}
```

---

## §W3 — text

### `regex` — `libs/std/src/regex.bp`

File header:

```bp
//// std/regex — regular expressions (PCRE-flavoured on every backend).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/  (RegExp global; V8 IRregexp)
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/re.html  (PCRE)
////
//// Patterns and flags are the standard PCRE surface (`i` case-insensitive,
//// `m` multiline, `s` dotall, `u` unicode). Compiled patterns can be reused
//// across many matches.
```

#### Surface

```bp
pub struct Match {
    text: string,
    start: i32,
    groups: string[],
}

#[@external(node,   "(()=>{ const m = $0.match(new RegExp($1)); return m ? { text: m[0], start: m.index, groups: m.slice(1) } : undefined; })()"),
  @external(erlang, """
    (fun() ->
        case re:run($0, $1, [{capture, all, list}]) of
            {match, [F | Rest]} -> #{ text => F, start => 0, groups => Rest };
            nomatch -> undefined
        end
    end)()
"""),
  @external(beam, /* same erlang */)]
pub declare fn match(haystack: string, pattern: string) -> ?Match

#[@external(node,   "[...$0.matchAll(new RegExp($1, 'g'))].map(m => ({ text: m[0], start: m.index, groups: m.slice(1) }))"),
  @external(erlang, """
    (fun() ->
        case re:run($0, $1, [global, {capture, all, list}]) of
            {match, MatchesList} -> [#{ text => F, start => 0, groups => Rest } || [F | Rest] <- MatchesList];
            nomatch -> []
        end
    end)()
"""),
  @external(beam, /* same */)]
pub declare fn matchAll(haystack: string, pattern: string) -> Match[]

#[@external(node,   "$0.replace(new RegExp($1, 'g'), $2)"),
  @external(erlang, "re:replace($0, $1, $2, [global, {return, list}])"),
  @external(beam,   /* same */)]
pub declare fn replaceAll(haystack: string, pattern: string, replacement: string) -> string

#[@external(node,   "new RegExp($1).test($0)"),
  @external(erlang, "re:run($0, $1, [{capture, none}]) =/= nomatch"),
  @external(beam,   /* same */)]
pub declare fn test(haystack: string, pattern: string) -> bool

#[@external(node,   "$0.split(new RegExp($1))"),
  @external(erlang, "re:split($0, $1, [{return, list}])"),
  @external(beam,   /* same */)]
pub declare fn splitOn(haystack: string, pattern: string) -> string[]
```

#### Inline tests

```bp
test "regex.test of '.+'" {
    @assert(regex.test("hello", ".+"))
}

test "regex.test of unmatch is false" {
    @assert(!regex.test("abc", "^z"))
}

test "regex.match captures group" {
    let m = regex.match("name=alice", "name=(.+)")
    @assert(m?.groups.at(0) == "alice")
}

test "regex.matchAll returns all" {
    let ms = regex.matchAll("a1 b2 c3", "[a-z]\\d")
    @assert(ms.length == 3)
}

test "regex.replaceAll" {
    @assert(regex.replaceAll("aaa", "a", "b") == "bbb")
}

test "regex.splitOn comma-and-whitespace" {
    @assert(regex.splitOn("a, b ,c", "\\s*,\\s*") == ["a", "b", "c"])
}
```

### `unicode` — `libs/std/src/unicode.bp`

File header:

```bp
//// std/unicode — codepoint walking and normalisation.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/  (String.prototype.normalize)
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/unicode.html
////
//// Codepoints are i32 (max 0x10FFFF fits). Normalisation forms NFC/NFD
//// /NFKC/NFKD per UAX #15. Case-folding by locale is recorded follow-up.
```

#### Surface

```bp
// Walk a string as an Iterator of codepoints (NOT bytes).
pub fn codepoints(s: string) -> @Iterator<i32> {
    // host-bound iterator — driven by `String.prototype[Symbol.iterator]`
    // on node, `unicode:characters_to_list/1` on erlang
}

#[@external(node,   "$0.normalize('NFC')"),
  @external(erlang, "unicode:characters_to_nfc_list($0)"),
  @external(beam,   /* same */)]
pub declare fn normalizeNfc(s: string) -> string

#[@external(node,   "$0.normalize('NFD')"),
  @external(erlang, "unicode:characters_to_nfd_list($0)"),
  @external(beam,   /* same */)]
pub declare fn normalizeNfd(s: string) -> string

#[@external(node,   "$0.normalize('NFKC')"),
  @external(erlang, "unicode:characters_to_nfkc_list($0)"),
  @external(beam,   /* same */)]
pub declare fn normalizeNfkc(s: string) -> string

#[@external(node,   "$0.normalize('NFKD')"),
  @external(erlang, "unicode:characters_to_nfkd_list($0)"),
  @external(beam,   /* same */)]
pub declare fn normalizeNfkd(s: string) -> string

#[@external(node,   "$0.codePointAt(0)"),
  @external(erlang, "hd($0)"),
  @external(beam,   /* same */)]
pub declare fn firstCodepoint(s: string) -> i32

#[@external(node,   "String.fromCodePoint($0)"),
  @external(erlang, "unicode:characters_to_list([$0])"),
  @external(beam,   /* same */)]
pub declare fn fromCodepoint(cp: i32) -> string
```

#### Inline tests

```bp
test "unicode.firstCodepoint of 'a' is 97" {
    @assert(unicode.firstCodepoint("a") == 97)
}

test "unicode.fromCodepoint of 97 is 'a'" {
    @assert(unicode.fromCodepoint(97) == "a")
}

test "unicode.normalize NFC ~= NFD/NFC compose" {
    let s = "café"   // composed
    @assert(unicode.normalizeNfc(s) == s)
}

test "unicode.codepoints counts emoji as one" {
    let cps: i32[] = []
    for cp in unicode.codepoints("a😀b") { cps = cps.push(cp) }
    @assert(cps.length == 3)
}
```

### `array_ext` — extension methods on `interface Array<T>` in `primitives.d.bp`

Added inside the existing `interface Array<T>` block. Each method gets a
full `#[@external(...)]` annotation per backend (driven by
`prim-op-annotation`):

| Method | node | erlang |
|---|---|---|
| `find(pred)` | `$self.find($0)` | `(fun(__L, __F) -> case lists:dropwhile(fun(__X) -> not __F(__X) end, __L) of [H \| _] -> H; [] -> undefined end end)($self, $0)` |
| `findIndex(pred)` | `$self.findIndex($0)` | inline recursive fun |
| `some(pred)` | `$self.some($0)` | `lists:any($0, $self)` |
| `every(pred)` | `$self.every($0)` | `lists:all($0, $self)` |
| `flatMap(fn)` | `$self.flatMap($0)` | `lists:flatmap($0, $self)` |
| `flat()` | `$self.flat()` | `lists:append($self)` |
| `fill(value)` | `Array($self.length).fill($0)` | `lists:duplicate(length($self), $0)` |
| `chunked(n)` | inline JS array-of-arrays | `inline erlang fun that windows by n` |
| `sliding(n)` | inline JS windowing | inline erlang windowing |
| `sort(cmp)` | `[...$self].sort($0)` | `lists:sort($0, $self)` |
| `unique()` | `[...new Set($self)]` | `lists:usort($self)` |
| `reverse()` | `[...$self].reverse()` | `lists:reverse($self)` |
| `zip(other)` | `$self.map((x, i) => [x, $0[i]])` | `lists:zip($self, $0)` |
| `take(n)` | `$self.slice(0, $0)` | `lists:sublist($self, $0)` |
| `drop(n)` | `$self.slice($0)` | `lists:nthtail($0, $self)` |

#### Inline tests (added to `primitives.d.bp`'s adjacent `.bp` test file)

```bp
test "Array.find returns first match" {
    @assert([1, 2, 3, 4].find({x -> x > 2}) == 3)
}

test "Array.findIndex returns position" {
    @assert([10, 20, 30].findIndex({x -> x == 20}) == 1)
}

test "Array.some / every" {
    @assert([1, 2, 3].some({x -> x > 2}))
    @assert(![1, 2, 3].every({x -> x > 2}))
}

test "Array.flatMap flattens one level" {
    @assert([1, 2, 3].flatMap({x -> [x, x]}) == [1, 1, 2, 2, 3, 3])
}

test "Array.flat collapses nested" {
    @assert([[1, 2], [3], [4, 5]].flat() == [1, 2, 3, 4, 5])
}

test "Array.fill fills with value" {
    @assert([0, 0, 0].fill(7) == [7, 7, 7])
}

test "Array.chunked groups by N" {
    @assert([1, 2, 3, 4, 5].chunked(2) == [[1, 2], [3, 4], [5]])
}

test "Array.sliding windows of N" {
    @assert([1, 2, 3, 4].sliding(2) == [[1, 2], [2, 3], [3, 4]])
}

test "Array.sort with comparator" {
    @assert([3, 1, 2].sort({a, b -> a - b}) == [1, 2, 3])
}

test "Array.unique drops dupes" {
    @assert([1, 2, 2, 3, 1].unique() == [1, 2, 3])
}

test "Array.zip pairs elements" {
    @assert([1, 2, 3].zip([10, 20, 30]) == [pair(1, 10), pair(2, 20), pair(3, 30)])
}

test "Array.take / drop" {
    @assert([1, 2, 3, 4, 5].take(2) == [1, 2])
    @assert([1, 2, 3, 4, 5].drop(2) == [3, 4, 5])
}
```

### `string_ext` — extension methods on `interface String` in `primitives.d.bp`

| Method | node | erlang |
|---|---|---|
| `padStart(len, fill)` | `$self.padStart($0, $1)` | `string:pad($self, $0, leading, $1)` |
| `padEnd(len, fill)` | `$self.padEnd($0, $1)` | `string:pad($self, $0, trailing, $1)` |
| `repeat(n)` | `$self.repeat($0)` | `lists:flatten(lists:duplicate($0, $self))` |
| `replace(needle, repl)` | `$self.replace($0, $1)` | `string:replace($self, $0, $1)` |
| `replaceAll(needle, repl)` | `$self.replaceAll($0, $1)` | `string:replace($self, $0, $1, all)` |
| `chars()` | `[...$self]` | inline UTF-8 walk |
| `lines()` | `$self.split('\\n')` | `string:split($self, "\\n", all)` |
| `words()` | `$self.split(/\\s+/)` | `string:tokens($self, " \\t\\n")` |
| `charCodeAt(i)` | `$self.charCodeAt($0)` | `lists:nth($0 + 1, $self)` |
| `endsWith(suffix)` | `$self.endsWith($0)` | `(string:suffix($self, $0) =/= nomatch)` |
| `indexOf(needle)` | `$self.indexOf($0)` | `string:str($self, $0) - 1` |
| `lastIndexOf(needle)` | `$self.lastIndexOf($0)` | inline `string:rstr` |
| `toLowerCase()` already exists | — | — |
| `toUpperCase()` already exists | — | — |
| `trim()` already exists | — | — |

#### Inline tests

```bp
test "String.padStart pads with zero" {
    @assert("5".padStart(3, "0") == "005")
}

test "String.padEnd pads to length" {
    @assert("hi".padEnd(5, ".") == "hi...")
}

test "String.repeat" {
    @assert("ab".repeat(3) == "ababab")
}

test "String.replace first only" {
    @assert("aaa".replace("a", "b") == "baa")
}

test "String.replaceAll" {
    @assert("aaa".replaceAll("a", "b") == "bbb")
}

test "String.lines splits on \\n" {
    @assert("a\nb\nc".lines() == ["a", "b", "c"])
}

test "String.words splits on whitespace" {
    @assert("the   quick brown\tfox".words() == ["the", "quick", "brown", "fox"])
}

test "String.indexOf returns position or -1" {
    @assert("hello".indexOf("ll") == 2)
    @assert("hello".indexOf("x") == -1)
}

test "String.endsWith" {
    @assert("hello.bp".endsWith(".bp"))
    @assert(!"hello.bp".endsWith(".js"))
}
```

---

## §W4 — network + crypto + url + querystring

### `url` — `libs/std/src/url.bp`

File header:

```bp
//// std/url — URL parsing and serialisation (RFC 3986).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/url.html
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/uri_string.html
////
//// `Url` struct is the canonical decomposition; `parse` returns ?Url so
//// callers handle invalid input via pattern match.
```

#### Surface

```bp
pub struct Url {
    scheme: string,
    user: ?string,
    password: ?string,
    host: ?string,
    port: ?i32,
    path: string,
    query: ?string,
    fragment: ?string,
}

#[@external(node,   """
    (() => {
        try {
            const u = new URL($0);
            return {
                scheme: u.protocol.replace(':', ''),
                user: u.username || undefined,
                password: u.password || undefined,
                host: u.hostname || undefined,
                port: u.port ? Number(u.port) : undefined,
                path: u.pathname,
                query: u.search ? u.search.slice(1) : undefined,
                fragment: u.hash ? u.hash.slice(1) : undefined,
            };
        } catch (_) { return undefined; }
    })()
"""),
  @external(erlang, """
    (fun() ->
        case uri_string:parse($0) of
            #{scheme := S} = M -> __uri_to_url(M);
            _ -> undefined
        end
    end)()
"""),
  @external(beam, /* same erlang */)]
pub declare fn parse(s: string) -> ?Url

#[@external(node,   """
    (() => {
        const u = new URL($0.scheme + '://' + ($0.host ?? ''));
        if ($0.user) u.username = $0.user;
        if ($0.password) u.password = $0.password;
        if ($0.port) u.port = String($0.port);
        u.pathname = $0.path;
        if ($0.query) u.search = $0.query;
        if ($0.fragment) u.hash = $0.fragment;
        return u.toString();
    })()
"""),
  @external(erlang, "uri_string:recompose(__url_to_uri($0))"),
  @external(beam,   /* same */)]
pub declare fn serialize(u: Url) -> string
```

#### Inline tests

```bp
test "url.parse of full URL" {
    let u = url.parse("https://alice@example.com:8443/foo?x=1#bar")?
    @assert(u.scheme == "https")
    @assert(u.user == "alice")
    @assert(u.host == "example.com")
    @assert(u.port == 8443)
    @assert(u.path == "/foo")
    @assert(u.query == "x=1")
    @assert(u.fragment == "bar")
}

test "url.parse of invalid returns None" {
    @assert(url.parse("not-a-url") == null)
}

test "url.serialize round-trip" {
    let s = "https://example.com/a/b?k=v"
    @assert(url.serialize(url.parse(s)?) == s)
}
```

### `querystring` — `libs/std/src/querystring.bp`

File header:

```bp
//// std/querystring — application/x-www-form-urlencoded parsing.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/querystring.html
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/uri_string.html (dissect_query)
////
//// Pure botopink — no host calls. Round-trip safe for valid input;
//// percent-decoded values are utf-8 strings.
```

#### Surface

```bp
pub fn parse(s: string) -> Dict<string, string> {
    let d = dict.empty<string, string>()
    if s.isEmpty() { return d }
    for pair_s in s.split("&") {
        let kv = pair_s.split("=")
        let k = decodeComponent(kv.at(0))
        let v = if kv.length > 1 { decodeComponent(kv.at(1)) } else { "" }
        d.insert(k, v)
    }
    return d
}

pub fn stringify(d: Dict<string, string>) -> string {
    return d.entries().map({ entry ->
        encodeComponent(entry.a) + "=" + encodeComponent(entry.b)
    }).joinSep("&")
}

#[@external(node,   "encodeURIComponent($0)"),
  @external(erlang, "uri_string:quote($0)"),
  @external(beam,   /* same */)]
pub declare fn encodeComponent(s: string) -> string

#[@external(node,   "decodeURIComponent($0)"),
  @external(erlang, "uri_string:unquote($0)"),
  @external(beam,   /* same */)]
pub declare fn decodeComponent(s: string) -> string
```

#### Inline tests

```bp
test "querystring.parse simple" {
    let d = querystring.parse("a=1&b=2")
    @assert(d.get("a")? == "1")
    @assert(d.get("b")? == "2")
}

test "querystring.parse percent-encoded" {
    let d = querystring.parse("name=alice%20wonder")
    @assert(d.get("name")? == "alice wonder")
}

test "querystring.stringify round-trip" {
    let d = querystring.parse("k=v&x=y")
    @assert(querystring.parse(querystring.stringify(d)).get("k")? == "v")
}

test "querystring.encodeComponent escapes spaces" {
    @assert(querystring.encodeComponent("a b") == "a%20b")
}
```

### `http` — `libs/std/src/http.bp`

File header:

```bp
//// std/http — HTTP client (no server; rakun owns servers).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/http.html  (http.request / fetch)
////   Erlang   — https://www.erlang.org/doc/man/httpc.html
////
//// All ops are #[@future]. `Request` body is utf-8 string for v0.beta.19;
//// binary bodies wait on the `bytes` type. SSL/TLS verification is
//// host-default (node: built-in CA store; erlang: `ssl` app must start).
```

#### Surface

```bp
pub struct Request {
    method: string,            // "GET" / "POST" / "PUT" / "PATCH" / "DELETE"
    url: string,
    headers: Dict<string, string>,
    body: ?string,
}

pub struct Response {
    status: i32,
    headers: Dict<string, string>,
    body: string,
}

#[@future]
#[@external(node,   """
    (async () => {
        try {
            const res = await fetch($0.url, {
                method: $0.method,
                headers: Object.fromEntries(Object.entries($0.headers)),
                body: $0.body ?? undefined,
            });
            const text = await res.text();
            return {
                status: res.status,
                headers: Object.fromEntries(res.headers),
                body: text,
            };
        } catch (e) { throw String(e); }
    })()
"""),
  @external(erlang, """
    (fun() ->
        application:ensure_all_started(inets),
        application:ensure_all_started(ssl),
        Req = case $0#{body} of
            undefined -> { $0#{url}, maps:to_list($0#{headers}) };
            B -> { $0#{url}, maps:to_list($0#{headers}), "application/octet-stream", B }
        end,
        case httpc:request(list_to_atom(string:lowercase($0#{method})), Req, [], []) of
            {ok, {{_, Status, _}, Hs, Body}} ->
                #{ status => Status, headers => maps:from_list(Hs), body => Body };
            {error, R} -> throw(io_lib:format("~p", [R]))
        end
    end)()
"""),
  @external(beam, /* same erlang */)]
pub declare fn send(req: Request) -> @Future<Response, string>

pub fn get(url: string) -> @Future<Response, string> {
    return send(Request {
        method: "GET",
        url: url,
        headers: dict.empty(),
        body: null,
    })
}

pub fn postJson(url: string, body: JsonValue) -> @Future<Response, string> {
    let hs = dict.empty<string, string>()
    hs.insert("content-type", "application/json")
    return send(Request {
        method: "POST",
        url: url,
        headers: hs,
        body: json.stringify(body),
    })
}
```

#### Inline tests

```bp
// These tests hit a localhost-only echo server provided by the lib-test
// runner. The runner spins it on a free port and injects the URL via env.
test "http.get returns 200 on echo" {
    let url = env.get("__BP_HTTP_ECHO__")?
    let resp = await http.get(url + "/ok")?
    @assert(resp.status == 200)
}

test "http.postJson round-trips" {
    let url = env.get("__BP_HTTP_ECHO__")?
    let resp = await http.postJson(url + "/echo", json.obj([
        pair("k", JsonValue::Number(1.0)),
    ]))?
    @assert(resp.status == 200)
    @assert(resp.body.contains("\"k\":1"))
}
```

### `crypto` — `libs/std/src/crypto.bp`

File header:

```bp
//// std/crypto — cryptographic digest + HMAC + random bytes.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/crypto.html
////   Erlang   — https://www.erlang.org/doc/man/crypto.html
////
//// Digest output is lowercase hex. HMAC takes a key + message. Symmetric
//// encryption + asymmetric keys deferred (PEM/DER decisions).
```

#### Surface

```bp
#[@external(node,   "require('crypto').createHash('sha256').update($0, 'utf8').digest('hex')"),
  @external(erlang, "binary_to_list(binary:encode_hex(crypto:hash(sha256, $0), lowercase))"),
  @external(beam,   /* same */)]
pub declare fn sha256(message: string) -> string

#[@external(node,   "require('crypto').createHash('sha512').update($0, 'utf8').digest('hex')"),
  @external(erlang, "binary_to_list(binary:encode_hex(crypto:hash(sha512, $0), lowercase))"),
  @external(beam,   /* same */)]
pub declare fn sha512(message: string) -> string

#[@external(node,   "require('crypto').createHash('md5').update($0, 'utf8').digest('hex')"),
  @external(erlang, "binary_to_list(binary:encode_hex(crypto:hash(md5, $0), lowercase))"),
  @external(beam,   /* same */)]
pub declare fn md5(message: string) -> string

#[@external(node,   "require('crypto').createHmac('sha256', $0).update($1, 'utf8').digest('hex')"),
  @external(erlang, "binary_to_list(binary:encode_hex(crypto:mac(hmac, sha256, $0, $1), lowercase))"),
  @external(beam,   /* same */)]
pub declare fn hmacSha256(key: string, message: string) -> string

// `n` random bytes as a lowercase-hex string.
#[@external(node,   "require('crypto').randomBytes($0).toString('hex')"),
  @external(erlang, "binary_to_list(binary:encode_hex(crypto:strong_rand_bytes($0), lowercase))"),
  @external(beam,   /* same */)]
pub declare fn randomHex(n: i32) -> string
```

#### Inline tests

```bp
test "crypto.sha256 of empty string is the known hash" {
    @assert(crypto.sha256("") == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
}

test "crypto.sha256 of 'hello' is known" {
    @assert(crypto.sha256("hello") == "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
}

test "crypto.sha512 is 128 hex chars" {
    @assert(crypto.sha512("anything").length == 128)
}

test "crypto.md5 is 32 hex chars" {
    @assert(crypto.md5("anything").length == 32)
}

test "crypto.hmacSha256 same inputs produce same output" {
    let a = crypto.hmacSha256("key", "msg")
    let b = crypto.hmacSha256("key", "msg")
    @assert(a == b)
}

test "crypto.randomHex returns 2N chars" {
    @assert(crypto.randomHex(16).length == 32)
}
```

---

## §W5 — assertions

### `assert` — `libs/std/src/assert.bp`

File header:

```bp
//// std/assert — assertion functions for tests.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/assert.html
////   Erlang   — (built-in pattern matching; no equivalent module)
////
//// `@assert(cond)` is a builtin macro that panics on false; the fns here
//// add structured messages. All assertions throw a uniform `AssertError`
//// the test runner catches.
```

#### Surface

```bp
pub struct AssertError {
    message: string,
    file: string,
    line: i32,
}

// Panic when `cond` is false; the message includes the source location.
pub fn truthy(cond: bool, message: string = "assertion failed") -> unit {
    if !cond { @panic(message) }
}

pub fn falsy(cond: bool, message: string = "expected false") -> unit {
    truthy(!cond, message)
}

pub fn equal<T>(actual: T, expected: T, message: string = "") -> unit {
    if actual != expected {
        @panic("expected " + expected + " but got " + actual + (if message.isEmpty() { "" } else { ": " + message }))
    }
}

pub fn notEqual<T>(actual: T, expected: T, message: string = "") -> unit {
    if actual == expected {
        @panic("expected != " + expected + (if message.isEmpty() { "" } else { ": " + message }))
    }
}

pub fn approxEqual(actual: f64, expected: f64, epsilon: f64 = 1e-9) -> unit {
    if math.abs(actual - expected) > epsilon {
        @panic("approx-equal failed: " + actual + " vs " + expected + " (epsilon " + epsilon + ")")
    }
}

pub fn throws<T>(body: fn() -> T, message: string = "expected throw") -> unit {
    var threw = false
    try { body() } catch _ { threw = true }
    truthy(threw, message)
}

pub fn contains(haystack: string, needle: string) -> unit {
    truthy(haystack.contains(needle), "'" + haystack + "' does not contain '" + needle + "'")
}

pub fn matches(haystack: string, pattern: string) -> unit {
    truthy(regex.test(haystack, pattern), "'" + haystack + "' does not match /" + pattern + "/")
}
```

#### Inline tests

```bp
test "assert.equal passes on match" {
    assert.equal(1, 1)
}

test "assert.notEqual passes on mismatch" {
    assert.notEqual(1, 2)
}

test "assert.approxEqual with default epsilon" {
    assert.approxEqual(0.1 + 0.2, 0.3)
}

test "assert.throws catches a panic" {
    assert.throws({-> @panic("boom")})
}

test "assert.contains finds substring" {
    assert.contains("hello world", "world")
}

test "assert.matches with regex" {
    assert.matches("abc123", "^[a-z]+\\d+$")
}
```

---

## Test scenarios — whole spec

The per-module sections above carry the **inline test blocks** that ship
verbatim inside each new `.bp` file. The top-level acceptance gate
aggregates them:

```
gate-W1   ---- libs/std/tests/math.bp, json.bp, base64.bp, time.bp, random.bp all green on commonJS + erlang + beam
gate-W2   ---- libs/std/tests/env.bp, path.bp, fs.bp, process.bp, os.bp all green on commonJS + erlang + beam
gate-W3   ---- libs/std/tests/regex.bp, unicode.bp green; new Array/String extension methods green on every backend
gate-W4   ---- libs/std/tests/url.bp, querystring.bp, http.bp (against the lib-test echo server), crypto.bp green
gate-W5   ---- libs/std/tests/assert.bp green; consumed by every other test file
wat-gate  ---- importing any module not marked ✓-wat from a wat target reds with std-unsupported-on-target; modules marked ✓-wat (path, querystring, assert) ship green
docs      ---- libs/std/AGENTS.md + docs.md + examples.md updated alongside each module's commit (memory rule)
ref-cite  ---- every new .bp / .d.bp file's header comment cites both upstream URLs verbatim per §"Module inventory"
```

---

## Steps

### F0 — `prim-op-annotation` lands first
- [ ] Dependency: the §"Steps" of `prim-op-annotation.md` complete through
      F1 (grammar + shared renderer). This spec consumes that grammar.

### F1 — §W1 essentials
- [ ] `libs/std/src/math.bp` authored; tests green on commonJS+erlang+beam.
- [ ] `libs/std/src/json.bp` + sidecar adapters (`__toJsonValue`,
      `__fromJsonValue`) shipped via `libs/std/.mjs` (node) +
      `libs/std/std_json.erl` (erlang). Tests green.
- [ ] `libs/std/src/base64.bp` authored; tests green.
- [ ] `libs/std/src/time.bp` authored; tests green (note: `sleep` test
      tolerates host-scheduler jitter — `>= 10` not `== 10`).
- [ ] `libs/std/src/random.bp` authored; tests green.
- [ ] `root.bp` adds `pub mod math; pub mod json; pub mod base64; pub mod time; pub mod random;`.
- [ ] `libs/std/AGENTS.md` gains a §"Wave 1 modules" section.
- [ ] One commit per module: `feat(std/<name>): wave 1 module surface`.

### F2 — §W2 system
- [ ] `libs/std/src/env.bp`, `path.bp`, `fs.bp`, `process.bp`, `os.bp`
      authored with their full surface per §"§W2".
- [ ] `root.bp` extended; tests green.
- [ ] `fs.bp` tests use `/tmp` + cleanup; the test fixtures coordinate so
      none collide.
- [ ] `libs/std/AGENTS.md` gains §"Wave 2 modules" + a per-target
      coverage note (some fns are `⚠` on wat — `process.exit` only).

### F3 — §W3 text
- [ ] `libs/std/src/regex.bp` + `unicode.bp` authored; tests green.
- [ ] `primitives.d.bp` `interface Array<T>` block gains the 15
      extension methods per §"array_ext"; each gets its full per-backend
      `#[@external]` set.
- [ ] `primitives.d.bp` `interface String` block gains the 11 new
      methods per §"string_ext".
- [ ] Snapshots under `tests/codegen/primitives_array_ext_*.zig` and
      `tests/codegen/primitives_string_ext_*.zig` assert the rendered
      output of representative calls.

### F4 — §W4 network + crypto
- [ ] `libs/std/src/url.bp`, `querystring.bp` authored; tests green
      (`querystring` is pure botopink — also tests on wat).
- [ ] `libs/std/src/http.bp` authored; lib-test runner gains a local
      echo server fixture (`tests/cli/http_echo_server.zig` spawns a
      tiny node + erlang echo server on a free port, injects
      `__BP_HTTP_ECHO__`); tests green.
- [ ] `libs/std/src/crypto.bp` authored; tests green (digest values
      verified against known reference hashes).

### F5 — §W5 assertions
- [ ] `libs/std/src/assert.bp` authored; tests green.
- [ ] `lib-test-runner` recognises `AssertError` and reports the failure
      with the structured `{message, file, line}` (the v0.beta.19 §T
      `----- RUN LOG -----` fence shows the message; the file:line lands
      in the failure tail).

### F6 — coverage matrix enforcement
- [ ] `comptime/infer.zig` (or the equivalent type-check pass) reads the
      `#[@external(<target>, …)]` annotation set on every `declare fn`
      in `from "std"` imports; emits `std-unsupported-on-target` when
      the active target has no matching annotation. The diagnostic text
      cites `tasks/v0.beta.19/specs/std-expansion.md §"Coverage matrix"`.

### F7 — docs + examples
- [ ] `libs/std/docs.md` reorganised: per-module subsection with
      one example per fn.
- [ ] `libs/std/examples.md` gains a "Real-world examples" section: a
      mini CLI tool reading args + env + parsing JSON from a file + http
      get + writing the result.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` "Per-target coverage"
      table updated.
- [ ] `CHANGELOG.md` accumulates `feat(std): wave <N> — <list>` lines as
      each wave ships.

## Out of scope (explicit, recorded)

Recorded so future contributors don't re-litigate:

- **`Buffer` (node) / `binary` (erlang) — different representations.**
  A botopink `bytes` type that maps cleanly to both needs its own
  design wave. Until then, `fs.readText` is utf-8 only; binary I/O is
  host-direct via `#[@external]`. Revisit post v0.beta.20.
- **Streams / async iterables of bytes.** Node's `stream` is push-based;
  erlang's gen_server-style is request/reply. The bridge story needs
  the effect system to settle.
- **OTP behaviours** (`gen_server`, `supervisor`, `gen_statem`) live in
  rakun, not core std.
- **`Cluster`, `Worker threads`** are host-runtime concepts; their
  botopink mapping is a multi-process story that needs effects.
- **`dns`, `net`, `tls`, `udp`, `http2`** — revisit after `http` (§W4)
  ships and the practical demand is measurable.
- **`child_process`** is risky as a user-facing surface (shell injection,
  cross-platform paths); bpmp uses `std.process.run` zig-side because
  it's compiler tooling. A user-facing version is post-v20.
- **`events` (EventEmitter).** Custom-effect territory; dedicated
  effect-kind spec in a later wave.
- **Full Unicode normalisation / case-folding by locale.** §W3 covers
  the four standard normalisation forms and codepoint walking; locale-
  aware case-folding is a follow-up.
- **`crypto` keys / certificates / TLS primitives.** §W4 covers digest
  + hmac + randomBytes only; PEM / DER / X.509 / symmetric encryption
  need their own spec.
- **Erlang `digraph` / `sofs`** — niche graph theory; revisit on
  demand.
- **Erlang code / parse / pp / lint** — only erlang; not portable.
- **Windows-specific `path` semantics** — POSIX-style paths only in
  v0.beta.19; Windows backslash + drive-letter normalisation is a
  recorded follow-up.

## Notes

- **Why this is a satellite, not a Frente B / Frente A track.** The new
  modules are pure additions — they don't touch existing comptime,
  parser, or codegen surface beyond the annotation grammar `prim-op-
  annotation` already extends. Each wave spins its own worktree (e.g.
  `.tasks/std-wave1/`).
- **Why `prim-op-annotation` is the only hard dependency.** Without the
  `$self` / `$N` / `$argc` / multi-line template grammar, many of these
  modules can't express their host bindings (e.g. inline `try` around
  `JSON.parse`, `string:pad($self, $0, leading, $1)`).
- **Reference-URL header comments are mandatory.** Every new `.bp` /
  `.d.bp` file lands with a `////` block at the top citing both
  upstream URLs (see §"Module inventory" for the exact per-module
  Node + Erlang link). Drives discoverability — anyone reading
  `math.bp` knows where the canonical behaviour is defined.
- **`#[@external]` per-backend coverage.** Every host-bound fn declares
  at minimum `node` + `erlang` + `beam` annotations. `wat` is **not
  required** here — most modules ✗ on wat per §"Coverage matrix";
  importing them from a wat target reds at type-check time.
- **No "compat shim" wave.** If something doesn't lower cleanly on a
  target, the std module **omits** it rather than faking slow / leaky
  behaviour. A user reaching for `fs.readText` in a wasm program sees
  a compile error pointing them at this spec's coverage matrix.
- **Naming conventions.** Fn names follow `camelCase`
  (`feedback_camelcase_naming`); module names are lowercase singular
  (`math`, not `Math`). Type / interface / enum / struct names stay
  `PascalCase`.
- **`.bp` vs `.d.bp` choice.** A module is `.bp` when it has pure-
  botopink helpers (e.g. `path.normalize`, `assert.equal`, `random.shuffle`).
  It's `.d.bp` when every fn is host-bound with no pure helpers — but
  in this spec every module ends up `.bp` because the constants (`pi`,
  `e`, `separator`) and the convenience wrappers (`get`/`postJson`,
  `pick`/`shuffle`, `clamp`/`hypot`) are pure.
- **Per-memory:** AGENTS.md updated in the same commit as the code;
  commit messages in English (e.g. `feat(std/math): wave 1 module
  surface`); SSH for git remote ops; implement in `.bp` when possible.
