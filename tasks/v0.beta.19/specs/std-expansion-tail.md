# std-expansion-tail — finish the 12 deferred stdlib modules + the F6/F7 surfaces

**Slug**: std-expansion-tail
**Depends on**: `std-expansion` (the 7 landed modules + the inline
  `@panic`/`@todo` dispatch fix bot-lang `c093e8f` — both already in
  `origin/feat`); the §F2 grammar extensions in `prim-op-annotation`
  (`when($argc == N)` arity branching + `"""…"""` raw templates) are in
  place already, but **two further grammar additions are required and
  authored here** (§A2 + §A3 below); the F6 coverage-matrix diagnostic
  is new infra also authored here.
**Files**:
- `libs/std/src/{json,base64,env,fs,process,os,regex,unicode,http,crypto}.bp`
  (10 new modules) ·
  `libs/std/src/{time,random,path,asserts,url}.bp` (5 in-module tails) ·
  `libs/std/src/primitives.d.bp` (`array_ext` + `string_ext` extension
  methods on `interface Array<T>` / `interface String`) ·
  `libs/std/src/root.bp` (every new module declared) ·
  `libs/std/{AGENTS,docs,examples}.md` + `CHANGELOG.md` (per-wave doc
  rolls).
- Sidecar adapters: `libs/std/src/sidecars/{json.mjs,json.erl}` +
  per-module pairs as each wave lands; the build's lib-test shipping
  step copies them next to the emitted module file.
- Coverage matrix gate: `modules/compiler-core/src/comptime/infer.zig`
  (the `std-unsupported-on-target` diagnostic at the `from "std"`
  import site, with a tested stable diagnostic code).
- Sidecar shipping: `modules/compiler-cli/src/cli/lib_test.zig` (or the
  current owner of the `--lib std` test-out layout) — copies the
  per-module sidecar next to the emitted `<name>.{js,erl}` so the
  emitted code can `require('./json.mjs')` / `-include_lib("json.erl")`
  without a path edit.
- prim-op-annotation grammar additions: `parser/decls.zig` +
  `ast.zig` (chained-host-call marker `$$prev` and the
  `#[@result]`-aware `try`-wrapped template form — §A2/§A3 below).
**Touches docs**:
- `libs/std/AGENTS.md` (`§Wave 3/4` modules + extension-method tables on
  `primitives.d.bp`) ·
- `libs/std/docs.md` ("What the stdlib currently exposes" extended;
  url entry corrected to mention `+ serialize(u)`) ·
- `libs/std/examples.md` ("Real-world examples" CLI tool — args + env
  + json file read + http get + write) ·
- `CHANGELOG.md` (per-wave entries + url-row correction: remove
  "serialize deferred" — `serialize(u)` landed in bot-lang `5788bd7`) ·
- `modules/compiler-core/src/codegen/AGENTS.md` (per-target coverage
  table — new row per backend × per module).
**Status**: pending

## Premise

`std-expansion` landed 7/19 modules and documented every deferred surface
under its own wave section. The deferrals fell into three classes:

1. **Needs richer `#[@external]` template grammar** beyond the §F2
   `when($argc == N)` + `"""…"""` shapes already in place — chained
   host-call shapes (`Buffer.from(s).toString('base64')`,
   `crypto.createHash('sha256').update(s).digest('hex')`) and
   `#[@result]`-aware `try`-wrapped templates (`JSON.parse`,
   `Number(JSON.stringify(...))`). §A2/§A3 author the two missing
   markers; the rest of `prim-op-annotation` is unchanged.
2. **Needs sidecar wiring** — `.mjs`/`.erl` adapter files shipped next
   to the emitted module at `botopink-lib-test` time (`json` is the
   canonical case; `base64` and `crypto` follow the same pattern).
   §C authors the shipping step + the per-module adapter convention.
3. **Needs F6 enforcement** — the documented `std-unsupported-on-target`
   diagnostic was never wired. Without it, `import {fs} from "std"` on
   `wat` silently elides instead of failing fast at type-check. §B
   authors the diagnostic with a stable code, a `wat` smoke test, and
   the spec link in the message.

Everything else (the 12 module surfaces themselves) is straight-line
authoring once the three blockers above are in place. Each module ships
with its full inline `test { … }` block per the §spec "Inline tests"
sub-section that already exists in `std-expansion.md`, and the per-file
header cites the canonical Node + Erlang URLs verbatim (ref-cite gate
already in force).

## Target syntax additions (§A — `prim-op-annotation` extensions)

### §A2 — chained host-call marker `$$prev`

```bp
#[@external(node,
  """Buffer.from($0, 'utf8').toString('base64')""",
  """Buffer.from($0, 'base64').toString('utf8')""")]
declare fn encode(s: string) -> string;
```

A template whose rendered host shape is a method chain on a literal
constructor (`Buffer.from(...).toString(...)`,
`crypto.createHash(...).update(...).digest(...)`) is written **verbatim**
in the existing `"""…"""` form — no new marker needed. §A2 is the rule
that the template body MAY contain `.` and `(` / `)` for chains; the
existing renderer already passes them through. The clarification is
documentary: §A2 lifts the implicit ban (the current
`parseExternalCallTemplate` does NOT reject chains — confirm with a new
test in `tests/codegen/prim_op_chained.zig`).

### §A3 — `#[@result]`-aware `try`-wrapped template

```bp
#[@result]
#[@external(node, """
    (() => { try { return { ok: JSON.parse($0) } } catch (e) { return { error: e.message } } })()
""",
  erlang, """
    case json:decode($0) of {ok, __V} -> {ok, __V}; {error, __R} -> {error, __R} end
""")]
declare fn parse(s: string) -> @Result<JsonValue, string>;
```

A `#[@result]`-annotated `declare fn` whose template renders to the
target's `{ ok / error }` runtime shape lowers byte-identically — no
auto-wrap, no runtime allocation beyond what the template carries. §A3
authors:

- `comptime/infer.zig` recognises the `#[@result]` + `declare fn` combo
  as the "the template owns the wrapper" path (currently `#[@result]` on
  `declare fn` is forbidden by §B's R7 — relax R7 to a strict-check:
  the body must literally render an `{ ok / error }` shape on both
  targets, asserted at comptime with a `result-template-shape-mismatch`
  diagnostic if either branch is missing).
- A new tested fixture `tests/codegen/result_template.zig` that round-
  trips `parse("42")` to `{ ok: 42 }` on JS and `{ok, 42}` on erlang.

## Wave plan

Twelve module surfaces, five in-module completions, two grammar
extensions, two infra items, and the F7 docs cleanup. The build order
threads dependencies linearly — each later phase consumes its earlier
phase's exits.

```text
F0 — doc-cleanup (CHANGELOG + docs.md url-row + examples.md scaffold)
F1 — F6 enforcement (std-unsupported-on-target diagnostic)
F2 — sidecar shipping infra (build step + convention)
F3 — prim-op-annotation §A2 + §A3 grammar additions
F4 — in-module tails (path.relative/resolve · random.{intInRange,bool,shuffle,seed} ·
     time.{monotonicMillis,sleep,formatIso8601,measureMillis} ·
     asserts.{throws,matches,AssertError})
F5 — §W1 tails (json, base64)
F6 — §W2 tails (env, fs, process, os)
F7 — §W3 tails (regex, unicode, array_ext, string_ext)
F8 — §W4 tails (http, crypto)
F9 — F7 examples.md + AGENTS per-target coverage + final CHANGELOG roll
```

## Steps

### F0 — doc cleanup (no compiler edits)

- [ ] `CHANGELOG.md` line 41–44 — drop the "serialize deferred"
      sentence from the `url` row (`serialize(u)` landed in
      bot-lang `5788bd7`). Replace with a one-line "round-trip closed"
      note linking to `tasks/v0.beta.19/specs/std-expansion-tail.md`.
- [ ] `libs/std/docs.md` line 90 — extend the `url.bp` row to read
      `record Url { … } + parse(s) + serialize(u)`.
- [ ] `libs/std/examples.md` — add a stub `## Real-world examples`
      heading with a one-line "in progress — see F9" pointer. Lands in
      this commit so subsequent F9 work is additive.
- [ ] `libs/std/AGENTS.md` — add a "Wave-tail roadmap" row pointing at
      this spec.

### F1 — F6 enforcement

- [ ] `modules/compiler-core/src/comptime/infer.zig` — at every
      `import { … } from "std"` resolve site, read the per-target
      `#[@external]` annotation set on each imported decl. If the
      active target has no matching annotation (and the decl is not
      a pure-bp `pub fn` body), emit
      `std-unsupported-on-target: module '<name>' has no implementation
      for target '<target>'; see tasks/v0.beta.19/specs/std-expansion.md
      §"Coverage matrix".` Stable code: `STD-001`.
- [ ] `comptime/diagnostics.zig` — register `STD-001` (`stdUnsupported
      OnTarget`) in the same shape as the existing `bp-1xxx` codes. The
      diagnostic carries the module name, the import-site span, and the
      target name.
- [ ] `tests/comptime/std_unsupported_on_target.zig` — new fixture:
      `import {fs} from "std";` compiled with `--target wat` reds with
      `STD-001` at the import span. The fixture's `fs.bp` is the
      eventual F6 module — until F6 lands, the test uses a stub
      `libs/std/src/_test_unsupported.bp` (covered + removed on F6 land).

### F2 — sidecar shipping infra

- [ ] Per-module sidecar discovery: when emitting `libs/std/src/<m>.bp`
      for `--lib std` lib-test, the build looks for
      `libs/std/src/sidecars/<m>.{mjs,erl}` and copies it next to the
      emitted `<m>.{js,erl}` (so the emitted code can use a sibling-path
      `require('./<m>.mjs')` / `-include("<m>.erl").`). Owner: the
      `--lib std` test-out builder (currently `modules/compiler-cli/src
      /cli/test_cmd.zig`'s `runLibTests` or its successor in
      `lib_test.zig`).
- [ ] Sidecar convention documented in `libs/std/AGENTS.md` §"Sidecar
      adapters": one file per module per target; the adapter is plain
      target source (no botopink syntax); the emitted module imports it
      via the sibling path.
- [ ] New test: `tests/cli/lib_test_sidecar.zig` — drop a no-op
      `sidecars/_smoke.mjs` next to a stub `libs/std/src/_smoke.bp`,
      run lib-test, assert the `.mjs` is copied to the `test-out/`
      directory next to the emitted `.js`.

### F3 — `prim-op-annotation` §A2 + §A3 grammar additions

- [ ] §A2 chained-host-call passthrough — author the regression test
      `tests/codegen/prim_op_chained.zig`: a primitive method annotated
      with `#[@external(node, "Buffer.from($0).toString('base64')")]`
      renders the host shape verbatim. No parser edit expected (the
      passthrough already works); the test pins the behaviour.
- [ ] §A3 `#[@result]`-aware `declare fn` template — relax §B-R7 in
      `parser/decls.zig` to accept `#[@result] declare fn …` whose
      body literally carries the target's `{ ok / error }` shape.
- [ ] `comptime/infer.zig` — for a `#[@result] declare fn`, do NOT
      apply the auto-wrap (the template already produces the wrapper).
      Add the comptime check `result-template-shape-mismatch`: parse
      the template body looking for the target's `{ ok / error }`
      tokens; red if either is missing.
- [ ] New fixture: `tests/codegen/result_template.zig` — `JSON.parse`
      smoke at both backends.

### F4 — in-module tails (5 landed modules → completions)

- [ ] `path.bp` — `relative(from: string, to: string) -> string` +
      `resolve(...segments: string[]) -> string`. Both pure botopink;
      `..` stack accumulator uses an explicit head/tail recursion
      (sidestep the `var` + `push` dead-store trap recorded in the
      `AGENTS.md` traps section). 4 new inline tests. Per-target
      coverage stays ✓ commonJS / ✓ erlang / ✓ beam / ✓ wat.
- [ ] `random.bp` — `intInRange(lo: i32, hi: i32) -> i32` (closed
      interval, `lo` inclusive, `hi` inclusive); `bool() -> bool`
      (alias for `coin()` per the Node `Math.random()` mental model);
      `shuffle<T>(xs: Array<T>) -> Array<T>` (Fisher–Yates over a
      copy — see `shuffleLowering` note below); `seed(s: i64) -> unit`
      (Erlang `rand:seed(exsplus, {s, s, s})`; Node falls back to a
      userland Mulberry32 PRNG seeded via `state` module-local).
- [ ] `time.bp` — `monotonicMillis() -> i64` (`performance.now()` /
      `erlang:monotonic_time(millisecond)`); `sleep(ms: i64) -> *unit`
      `#[@future]` (`setTimeout` Promise / `timer:sleep`);
      `formatIso8601(ms: i64) -> string` (`new Date(ms).toISOString()`
      / `calendar:system_time_to_rfc3339`); `measureMillis(body: fn()
      -> T) -> #(T, i64)` (returns the body's result + elapsed ms).
- [ ] `asserts.bp` — `throws(body: fn() -> any, message: ?string)`
      catches a `@panic` from `body` and reds with `message` if none
      was thrown; `matches(pattern: string, actual: string)`
      regex-matches `actual` against `pattern` (depends on F7 `regex`
      module — if `regex` not yet landed, defer with a clear note in
      `asserts.bp`'s header). Promote `@panic("…")` to a structured
      `pub record AssertError { message: string, file: string, line:
      i32 }` carried in the test runner's failure stream (also lands
      a `lib-test-runner` update — out of scope for std-expansion-tail
      unless it stays inside the assertion's own `@panic` message).
- [ ] `url.bp` — _already complete_ in `5788bd7`; this row is a
      no-op verification step (the F0 doc cleanup folds it in).

### F5 — §W1 tails

- [ ] `json.bp` — `JsonValue` enum (`Null` / `Bool` / `Number` /
      `String` / `Array<JsonValue>` / `Object<#(string, JsonValue)>`),
      `parse(s: string) -> @Result<JsonValue, string>` via §A3
      template + sidecar adapter `sidecars/json.{mjs,erl}` that
      wraps `JSON.parse` / `json:decode` in `try`/`catch`,
      `stringify(v: JsonValue) -> string`,
      `stringifyPretty(v: JsonValue, indent: i32) -> string`. 6
      inline tests covering round-trip, error, nested arrays, escaped
      strings.
- [ ] `base64.bp` — `encode(s: string) -> string` /
      `decode(b: string) -> @Result<string, string>` via §A2
      chained template (`Buffer.from(s, 'utf8').toString('base64')`
      on Node, `base64:encode/1` on Erlang). 4 inline tests + a
      url-safe variant pair `encodeUrlSafe` / `decodeUrlSafe`.

### F6 — §W2 tails

- [ ] `env.bp` — `get(name: string) -> ?string` /
      `set(name: string, value: string) -> unit` /
      `unset(name: string) -> unit` /
      `args() -> Array<string>` /
      `vars() -> Array<#(string, string)>`. The `process.env[$0]`
      shape needs §A2 + a sidecar `sidecars/env.mjs` that exports a
      `get`/`set` pair (avoid the `[$0]` index marker — author a
      bare host fn instead so the template stays `$self`/`$0`-flat).
- [ ] `fs.bp` — `readText(path: string) -> @Result<string, string>` /
      `writeText(path: string, contents: string) -> @Result<unit,
      string>` / `exists(path: string) -> bool` /
      `list(path: string) -> @Result<Array<string>, string>` /
      `mkdir(path: string, recursive: bool = false) -> @Result<unit,
      string>` / `rm(path: string, recursive: bool = false) -> @Result
      <unit, string>` / `stat(path: string) -> @Result<FileStat,
      string>` / `copy(src: string, dest: string) -> @Result<unit,
      string>`. 8 inline tests over a temp dir; sidecar
      `sidecars/fs.{mjs,erl}` wraps the Node `fs/promises` API +
      Erlang `file:*/2` to a uniform `@Result` shape.
- [ ] `process.bp` — `exit(code: i32) -> noreturn` /
      `cwd() -> string` / `platform() -> string` (`'linux'`
      `'darwin'` `'win32'`) / `arch() -> string` /
      `pid() -> i32` / `hostname() -> string`. 5 inline tests.
- [ ] `os.bp` — `hostname() -> string` / `arch() -> string` /
      `cpuCount() -> i32` / `tmpdir() -> string` /
      `userInfo() -> #(string, string)` (uid/username pair) /
      `eol() -> string`. 5 inline tests. Per-target coverage: ✓ ✓ ✓
      ✗ (wat).

### F7 — §W3 tails

- [ ] `regex.bp` — `record Match { value: string, index: i32 }`,
      `match(pattern: string, input: string) -> ?Match`,
      `matchAll(pattern: string, input: string) -> Array<Match>`,
      `replace(pattern: string, input: string, replacement: string) ->
      string`, `replaceAll(...)`, `test(pattern: string, input: string)
      -> bool`, `splitOn(pattern: string, input: string) ->
      Array<string>`. 7 inline tests.
- [ ] `unicode.bp` — `codepoints(s: string) -> Array<i32>` /
      `fromCodepoint(cp: i32) -> string` /
      `firstCodepoint(s: string) -> ?i32` /
      `normalize(s: string, form: NormalizationForm) -> string` (form
      is an enum NFC/NFD/NFKC/NFKD). 4 inline tests.
- [ ] `array_ext` — extends `interface Array<T>` in `primitives.d.bp`
      with 15 new methods (`find` / `findIndex` / `some` / `every` /
      `flatMap` / `flat` / `fill` / `chunked` / `sliding` / `sort` /
      `unique` / `reverse` / `zip` / `take` / `drop`); per-method
      `#[@external]` set per backend. 12 inline tests in
      `libs/std/tests/array_ext.bp`. Per-method snapshots in
      `tests/codegen/primitives_array_ext_*.zig`.
- [ ] `string_ext` — extends `interface String` with 11 new methods
      (`padStart` / `padEnd` / `repeat` / `replace` / `replaceAll` /
      `chars` / `lines` / `words` / `charCodeAt` / `endsWith` /
      `indexOf` / `lastIndexOf`). 9 inline tests. Per-method
      snapshots in `tests/codegen/primitives_string_ext_*.zig`.

### F8 — §W4 tails

- [ ] `http.bp` — `record Request { method, url, headers, body }`,
      `record Response { status, headers, body }`,
      `send(req: Request) -> *@Result<Response, string>` `#[@future]`
      via §A2 chained template (`fetch(url, { method, headers, body
      }).then(r => r.text())`) + sidecar `sidecars/http.mjs` that
      wraps the Node `node:http` module to a Promise-based shape;
      `get(url: string) -> *@Result<Response, string>` /
      `postJson(url: string, body: JsonValue) -> *@Result<Response,
      string>` are pure-botopink composers. 4 inline tests via a
      `tests/cli/http_echo.zig` harness (out of scope here — defers
      to the existing `http-echo` deferral in std-expansion.md §W4).
- [ ] `crypto.bp` — `sha256(data: string) -> string` (hex digest) /
      `sha512(data: string) -> string` / `md5(data: string) -> string`
      / `hmacSha256(key: string, data: string) -> string` /
      `randomBytes(n: i32) -> Array<u8>` via §A2 chained template
      (`crypto.createHash('sha256').update(s).digest('hex')` on Node,
      `crypto:hash(sha256, s)` on Erlang). 5 inline tests with the
      canonical test vectors (`hello world` → `b94d27...`).

### F9 — examples.md "Real-world examples" + AGENTS per-target coverage

- [ ] `libs/std/examples.md` — replace the F0 stub with the full
      "Real-world examples" section: a 30-line CLI tool that reads
      `args()` + `env.get("HOME")` + `fs.readText` of a JSON file +
      `http.get` of a configured URL + writes the merged result. Each
      step references the source `std/<m>` module by file:line.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` — add a "Per-target
      coverage" subsection mirroring `std-expansion.md` §"Coverage
      matrix" but driven from `STD-001`'s per-target lookup (one row
      per module × four backends).
- [ ] `CHANGELOG.md` — accumulate the per-wave entries:
      `feat(std): wave 1 tail — json, base64`
      `feat(std): wave 2 tail — env, fs, process, os`
      `feat(std): wave 3 tail — regex, unicode + array/string_ext`
      `feat(std): wave 4 tail — http, crypto`
      Each line lands in its own commit per the §spec convention.

## Test scenarios

```
infra ---- F6 STD-001 fires at the import site, not at link time
infra ---- F6 STD-001 carries the spec-link in its message
infra ---- F6 ✓ targets do NOT red (path on commonJS/erlang/beam/wat)
infra ---- sidecar copy: emitting json.bp with --target node ships sidecars/json.mjs to test-out
infra ---- sidecar absence: emitting a module with no sidecar is a no-op (no warning)
grammar - §A2 chained host call: Buffer.from(s).toString('base64') renders verbatim
grammar - §A3 result template: JSON.parse('42') round-trips to { ok: 42 } / {ok, 42}
grammar - §A3 result template shape mismatch reds with result-template-shape-mismatch
math   ---- (already landed — no new test)
json   ---- parse round-trip on Number / String / Array / Object
json   ---- parse error on invalid JSON returns Error with the host message
json   ---- stringify nested arrays + escaped strings byte-identical to host JSON
base64 ---- encode 'hello' / decode round-trip
base64 ---- url-safe variant preserves '-' / '_' replacements
time   ---- monotonicMillis is non-decreasing across two calls
time   ---- sleep(50) blocks for >= 50ms (loose lower bound)
time   ---- formatIso8601 of 0 is '1970-01-01T00:00:00.000Z'
time   ---- measureMillis returns the body's result + a >=0 elapsed
random ---- intInRange(1, 6) draws are within [1, 6] over 100 samples
random ---- shuffle preserves multiset + does not always identity
random ---- seed makes two RNGs identical across N draws
env    ---- get/set/unset round-trip on a fresh key
env    ---- args() returns [] when the CLI was invoked with no extra argv
env    ---- vars() includes the just-set key
fs     ---- writeText + readText round-trips text content
fs     ---- exists is true after writeText, false after rm
fs     ---- list returns the just-written file's name
fs     ---- mkdir recursive: true creates intermediate parents
fs     ---- stat reports size / mtime within a reasonable range
fs     ---- copy + readText shows the copy matches the original
process ---- cwd is non-empty
process ---- platform is one of {linux, darwin, win32}
process ---- arch is non-empty
process ---- pid is positive
os     ---- hostname is non-empty
os     ---- cpuCount >= 1
os     ---- tmpdir is a path that exists
regex  ---- match returns ?Match with value + index
regex  ---- matchAll yields every overlapping-free match
regex  ---- replace replaces only the first occurrence
regex  ---- replaceAll replaces every occurrence
regex  ---- test returns true on a matching string
regex  ---- splitOn splits on the pattern
unicode ---- codepoints of 'aé€' is [97, 233, 8364]
unicode ---- fromCodepoint(233) is 'é'
unicode ---- normalize NFC of decomposed 'á' equals composed 'á'
array_ext ---- find returns the first matching element
array_ext ---- findIndex returns the index, or -1 when missing
array_ext ---- some / every short-circuit correctly
array_ext ---- flatMap unrolls one level + applies the fn
array_ext ---- flat: 1 unrolls one level; 2 unrolls two levels
array_ext ---- fill replaces in place to the given value
array_ext ---- chunked partitions into windows of the given size
array_ext ---- sliding overlaps by (size - 1)
array_ext ---- sort sorts ascending; with a comparator sorts by it
array_ext ---- unique removes consecutive duplicates
array_ext ---- reverse reverses in place
array_ext ---- zip pairs two arrays index-wise
array_ext ---- take / drop slice from the head
string_ext ---- padStart / padEnd pads to the target length
string_ext ---- repeat repeats N times
string_ext ---- replace replaces first; replaceAll replaces all
string_ext ---- chars / lines / words splits on the standard boundary
string_ext ---- charCodeAt at index returns the codepoint
string_ext ---- endsWith / indexOf / lastIndexOf behave like host
http   ---- get against the http-echo fixture returns the echoed body
http   ---- postJson sends a Content-Type: application/json header
http   ---- a 4xx status returns Error, not Ok
crypto ---- sha256('hello world') is b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9
crypto ---- hmacSha256 matches the RFC 4231 test vector
crypto ---- randomBytes(N) returns an array of exactly N bytes
asserts ---- throws catches a @panic from body
asserts ---- throws reds with the supplied message if body did not @panic
asserts ---- matches matches the regex pattern
docs   ---- examples.md "Real-world examples" compiles + runs end-to-end
docs   ---- CHANGELOG.md url-row drops "serialize deferred"
docs   ---- docs.md url-row reads "+ serialize(u)"
docs   ---- AGENTS per-target coverage table matches STD-001's lookup
```

## Notes

- **Order on the worktree side**: `.tasks/std-expansion-tail/` opens on
  a single worktree; phases F0/F1 land first (no test-gate impact on
  the deferred modules), then F2/F3 (infra + grammar — gated by their
  own snapshots), then F4 (in-module tails — all 4 in one commit per
  module). F5–F8 each take one wave at a time, each wave one commit
  per module. F9 closes the spec.
- **Coordinates with `recursive-test-gate`**: the per-module lib-test
  scenario assumes the meta + per-submodule pre-commit shim is in
  place (it is — `eede97d`). The sidecar shipping test in F2 also
  drops a `.mjs` sidecar in a fresh checkout — confirm the hook does
  not flag the untracked test-out files (.gitignore covers the test-out
  dir per the bot-lang root).
- **Coordinates with `frente-a-compiler` §B/§D**: `array_ext` and
  `string_ext` add methods that the existing `#[@external]` keystone
  refactor expects to be authored in `primitives.d.bp`. The extension
  methods are additive (no rewrites of existing methods); each backend's
  `emitPrimMethod` switch picks them up automatically via the
  annotation table. Confirm no naming collisions with `record`/`struct`
  methods (the §A4 collision filter already handles
  `contains` — every new method goes through the same filter).
- **Sidecar adapter language**: `.mjs` for Node (ESM, since the emit
  is `commonJS` but `require('./<m>.mjs')` is supported in Node ≥
  14 for sibling modules); `.erl` for Erlang (`-include_lib(...)` in
  the emitted module). The build's lib-test step copies the file
  verbatim — no transpile, no minify.
- **`#[@result] declare fn` template requirement** (§A3): the
  template MUST literally emit the target's `{ ok / error }` shape on
  every supported target. The `result-template-shape-mismatch` check
  parses the template body for the tokens — a missing branch is a
  comptime red, not a runtime trap. This keeps the auto-wrap path
  unchanged for the common case (`#[@result] fn …` with a body).
- **wat coverage**: per the §"Coverage matrix" matrix in
  `std-expansion.md`, most §W2–§W4 modules are ✗ on `wat`. F1's
  diagnostic is what makes the matrix enforceable — without it,
  `import {fs} from "std";` on `--target wat` silently elides the
  import and the call sites red with a generic "unknown symbol" much
  later. The `wat` row stays ✓ for the modules already wat-safe
  (`path`/`querystring`/`asserts`/`url` after F0; `math` partial).
- **Out of scope**: a `bigint` module (the `i64`/`u64` interfaces in
  `primitives.d.bp` already cover the integer surface); a `csv`/`yaml`
  module (defer to a downstream package once `json` lands); a
  `streams` API on top of `fs`/`http` (defer to a v0.beta.20+ once
  `#[@iterator]` runtime is more battle-tested).
- **Failure modes documented in the affected module's header**: every
  module that defers a sub-surface (e.g. `regex` may defer
  Unicode-class escapes initially) cites the deferral in its `////`
  header with a forward reference to its eventual closing spec.

## Exit gate

- [ ] All F0–F9 boxes ticked.
- [ ] All test scenarios above pass on a local rerun.
- [ ] `zig build test` + `botopink-lib-test --lib std --target
      commonJS,erlang` green; new `--target wat` smoke for the
      `STD-001` diagnostic green.
- [ ] The `Coverage matrix` table in `std-expansion.md` agrees with
      the `STD-001` lookup at runtime (cross-check by parsing the
      table and asserting every cell matches the per-module annotation
      set).
- [ ] `tasks/v0.beta.19/status.md` flips the `std-expansion-tail` row
      to `done` once merged into `feat`.
