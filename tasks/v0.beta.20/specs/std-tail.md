# std-tail — std-expansion-tail follow-ups + Option.expect<T> (closes v0.beta.19 `std-expansion-tail` partial)

**Slug**: std-tail
**Depends on**: v0.beta.19 `std-expansion-tail` partial close (meta `fd3604d` / bot-lang local `6efa449` — §A2 commonJS+erlang + F0 docs + 4 F4 in-module tails + 8 net-new modules in 14 commits).
**Files**: `libs/std/src/**` · sidecars `.mjs`/`.erl` · `compiler-cli/src/cli/lib_test.zig` · `comptime/infer.zig` STD-001 · examples-CLI · `libs/std/src/builtins.d.bp` Option.expect addition.
**Touches docs**: `libs/std/AGENTS.md`, `libs/std/docs.md`, `libs/std/src/examples.md`, `CHANGELOG.md`.
**Status**: partial — 2 sub-specs (both independent, parallel); std-expansion-tail-followup has substantial code landed.

## Current state (partials landed on origin/feat — bot-lang 0568466)

### Active reds traced to std lib tests

`zig build test-libs` summary: 5 lib×backend combos red:

| Lib | Backend | Status | Cause |
|---|---|---|---|
| std | erlang | RED (new) | `PrimOpStringifyUnsupported` raised during compile — band-aid in `primOpTemplate.zig` (`@hasDecl` guard) leaks the error when a BIF template path triggers `$stringify` and the Ctx doesn't define `emitStringifyOpen`. Fix: add `emitStringifyOpen`/`emitStringifyClose` to every Ctx in erlang.zig (mirror commonJS) or migrate the band-aid to a proper feature flag. |
| erika / jhonstart / onze / rakun | erlang | RED (pre-existing) | tracked by `ci-tail-02-backends-parity` E-half (BIF shadowing + missing `no_auto_import` overrides for specific BIFs not yet in `libs/std/src/erlang.bp` — extend the catalog or fix lib code) |



| Sub-spec | Landed | Remaining |
|---|---|---|
| **std-expansion-tail-followup** | §A2 commonJS+erlang (`a7c6d07`+`52d6101`) · F0 docs · 4 F4 in-module tails (path `a135b4d`, random `0a29b0b`, time `0d14d2d`, asserts `5244743`) · 8 net-new modules: base64 `2c470d4`, env `140688e`, process `2f043ff`, os `fc2545d`, regex `36ffe1d`, unicode (in `52d6101`), crypto `2cef46b` | F1 STD-001 diag · F2 sidecar shipping · F3 §A3 `#[@result] declare fn` template · F5 json · F6 fs · F7 array_ext + string_ext · F8 http · F9 examples-CLI |
| **option-expect** | — | additive method on `?T` |

## DAG

```
flat (2, parallel)
  followup        (9 phases + 14 sub-deferrals — internal phase DAG F1..F9)
  option-expect   (additive method on ?T)
```

---


---

## std-expansion-tail-followup — close the remaining 9 phases + 14 sub-deferrals from std-expansion-tail

**Slug**: std-expansion-tail-followup
**Depends on**: `std-expansion-tail` partial close (meta `fd3604d`, bot-lang
  local `6efa449` — §A2 commonJS + erlang twin + F0 docs + 4 F4 in-module
  tails + 8 net-new modules landed in 14 commits, 5 modules per-module
  green on commonJS + erlang).
**Files**: see per-phase "Files" subsections below.
**Touches docs**: `libs/std/AGENTS.md`, `libs/std/docs.md`,
  `libs/std/src/examples.md`, `CHANGELOG.md`,
  `modules/compiler-core/src/codegen/AGENTS.md`,
  `modules/compiler-core/src/comptime/AGENTS.md`,
  `tasks/v0.beta.19/status.md`.
**Status**: pending

### Premise

`std-expansion-tail` closed 8 of 12 net-new modules + 4 of 5 in-module
tails on bot-lang local `feat` (push to `origin/feat` deferred per
shared-branch policy in this session). The remaining 4 modules and the
F1/F2 enforcement / shipping infra are blocked on a small set of
compiler-core extensions; once those land, every deferred sub-checkbox
becomes a focused commit.

### Landed surface (carry-forward — these stay green, do not retouch)

| Module | Landing commit (bot-lang) | Surface |
|---|---|---|
| F0 docs | `9848a4e` | url-row reflects `parse + serialize`; wave-tail roadmap row; examples stub |
| F4.path | `a135b4d` | `relative(src, dst)` + `resolve(segments)` via head/tail recursion |
| F4.random partial | `0a29b0b` | `bool()` + `intInRange(lo, hi)` |
| F4.time partial | `0d14d2d` | `monotonicMillis()` (Erlang real; Node `Date.now` fallback pre-§A2) + `measureMillis<T>(body)` |
| F4.asserts partial | `5244743` | `record AssertError { message, file, line }` |
| F4.url | folded into F0 | verification only — `parse + serialize` already landed in `5788bd7` |
| §A2 commonJS | `a7c6d07` | `user_node_templates` + `tryEmitUserTemplate`; chained-host-call passthrough on the node backend |
| §A2 erlang twin | `52d6101` | `user_erlang_templates` + matching dispatch on erlang |
| `validateExternalAnnotation` relax | `f7a0af5` | accept `when(argc == N)` args on top-level declare fn |
| F5.base64 | `2c470d4` | `encode`/`decode` + `encodeUrlSafe`/`decodeUrlSafe` via §A2 chained template |
| F6.process | `2f043ff` | `exit` / `cwd` / `platform` / `arch` / `pid` |
| F6.os | `fc2545d` | `hostname` / `arch` / `cpuCount` / `tmpdir` |
| F6.env | `140688e` | `read` / `write` / `clear` (renamed from `get`/`set`/`unset` — reserved tokens) |
| F7.unicode partial | folded into `52d6101` | `fromCodepoint` + `firstCodepoint` |
| F7.regex partial | `36ffe1d` | `matches` (renamed from `test`) + `replace` + `replaceAll` + `splitOn` |
| F8.crypto partial | `2cef46b` | `sha256` / `sha512` / `md5` + `hmacSha256` |

### Wave plan (phase build-order)

```text
P1 — §A3 #[@result] declare fn template-owned wrapper          (compiler infra)
P2 — F4.time.formatIso8601 backfill                            (1-fn ship)
P3 — F4.asserts.matches backfill                               (1-fn ship)
P4 — F5.json                                                   (gated on P1)
P5 — F7.array_ext (15 methods on interface Array<T>)           (primitives.d.bp)
P6 — F7.string_ext (11 methods on interface String)            (primitives.d.bp)
P7 — F7.unicode tails (codepoints + normalize)                 (record-shape sub-checkbox)
P8 — F7.regex tails (record Match + match + matchAll)
P9 — F1 STD-001 diagnostic + 2 fixtures                        (compiler-core infra)
P10 — F2 sidecar shipping infra + smoke fixture                (compiler-cli infra)
P11 — F4.time.sleep + F4.asserts.throws backfill               (gated on P1)
P12 — F4.random.seed + F8.crypto.randomBytes                   (gated on P10 sidecar)
P13 — F6.env tails (args + vars)
P14 — F6.os tails (userInfo + eol)
P15 — F6.fs                                                    (heavy; gated on P1 + P10)
P16 — F8.http                                                  (heavy; gated on P10)
P17 — F4.random.shuffle (gated on Option.expect)
P18 — F9 — examples.md "Real-world examples" + per-target coverage
P19 — final unification sweep + push to origin/feat
```

### Steps

#### P1 — `#[@result] declare fn` template-owned wrapper (§A3)

**Files**: `parser/decls.zig` (R1 effect-on-declare check relaxed for the
`@result + @external` combo), `comptime/infer.zig` (skip the auto-wrap
when the template owns it + new comptime check
`result-template-shape-mismatch`), `comptime/diagnostics.zig` (register
the new code), `tests/codegen/result_template.zig` (round-trip
fixture).

- [ ] `parser/decls.zig` — relax R1 (line ~397-412) to allow `effect ==
      .result` on `declare fn` ONLY when at least one `@external`
      annotation is present (template ownership is signalled by the
      external). All other effect kinds remain rejected on declare fn.
- [ ] `comptime/infer.zig` — for `#[@result] declare fn` (line ~2117),
      skip the rejection branch when the fn carries `@external` AND its
      return type is `@Result<R, E>`. The template owns the wrapper;
      the body-less form expresses the wrapper shape through the
      annotation, not the return-type alone.
- [ ] `comptime/infer.zig` — add the strict-shape check: parse the
      `@external(<target>, "<template>")` body looking for both `ok`
      and `error` tokens on each registered target. Red with
      `result-template-shape-mismatch` if either branch is missing on
      any target the fn declares.
- [ ] `comptime/diagnostics.zig` — register
      `result_template_shape_mismatch: []const u8 = "result-template-shape-mismatch"`
      in `all_codes` (the table is the contract — the existing
      consistency tests pin the spelling).
- [ ] `tests/codegen/result_template.zig` — new fixture: a
      `#[@result] declare fn parse(s: string) -> @Result<i32, string>`
      whose JS template renders
      `(() => { try { return { ok: Number($0) } } catch (e) { return { error: e.message } } })()`
      and whose erlang template renders the `{ok, _}` / `{error, _}`
      pattern. Round-trip `parse("42")` → `{ ok: 42 }` (JS) / `{ok, 42}`
      (erlang). Snapshot the lowering on commonJS + erlang.
- [ ] `tests/comptime/result_template_shape_mismatch.zig` — net-new
      diagnostic fixture: a `#[@result] declare fn` whose template
      body is missing the `error` branch reds with
      `result-template-shape-mismatch`.

#### P2 — F4.time.formatIso8601 backfill (§A2-wired)

**Files**: `libs/std/src/time.bp`, AGENTS + docs + CHANGELOG rows.

- [ ] `time.bp` — add
      `#[@external(node, "new Date($0).toISOString()"),
        @external(erlang, "list_to_binary(calendar:system_time_to_rfc3339($0 div 1000, [{unit, second}]))")]
      pub declare fn formatIso8601(epochMillis: i64) -> string;`.
      Erlang gates the divisor down to seconds and supplies the unit
      option so the resulting RFC3339 string matches Node's `toISOString()`
      shape (modulo fractional seconds — Node always renders `.000`,
      Erlang's `system_time_to_rfc3339/2` does not).
- [ ] 2 inline tests (formatIso8601(0) starts with "1970-01-01"; round-
      trip 1700000000000ms decodes to the right ISO-prefix).
- [ ] AGENTS + docs row update; CHANGELOG entry.

#### P3 — F4.asserts.matches backfill (regex.matches landed)

**Files**: `libs/std/src/asserts.bp`, AGENTS + docs + CHANGELOG.

- [ ] `asserts.bp` — add
      `pub fn matches(pattern: string, actual: string)` calling
      `regex.matches(pattern, actual)` and `@panic("asserts.matches:
      pattern did not match")` on red. Pure-bp wrapper over the
      already-landed regex.
- [ ] 2 inline tests (matches a digit class against a digit-bearing
      string; matches negation when pattern doesn't match — checks via
      a try/catch wrapper around the panic).
- [ ] Drop the `matches` deferral from the asserts header + AGENTS rows.

#### P4 — F5.json (gated on P1)

**Files**: `libs/std/src/json.bp`, `libs/std/src/sidecars/json.{mjs,erl}`
(once P10 lands; until then the templates inline the try/catch directly
without a sidecar import), `libs/std/src/root.bp` (`pub mod json;`),
AGENTS + docs + CHANGELOG.

- [ ] `pub enum JsonValue` — `Null` / `Bool(bool)` / `Number(f64)` /
      `String(string)` / `Array(Array<JsonValue>)` /
      `Object(Array<#(string, JsonValue)>)`.
- [ ] `#[@result] declare fn parse(s: string) -> @Result<JsonValue, string>`
      using the §A3 template-owned wrapper. The Node template wraps
      `JSON.parse` in `try`/`catch` returning `{ ok }` / `{ error }`;
      the Erlang template uses `json:decode/1` over the `{ok, _}` /
      `{error, _}` shape.
- [ ] `pub fn stringify(v: JsonValue) -> string` + `pub fn
      stringifyPretty(v: JsonValue, indent: i32) -> string` — pure-bp
      recursion over the enum cases; emits via per-backend
      `JSON.stringify` / `json:encode` external host fns.
- [ ] 6 inline tests (round-trip Number, String, Array, Object,
      error on invalid JSON, nested arrays + escaped strings).
- [ ] `root.bp` adds `pub mod json;`.
- [ ] AGENTS + docs + CHANGELOG entry.

#### P5 — F7.array_ext (15 methods on `interface Array<T>`)

**Files**: `libs/std/src/primitives.d.bp` (extension methods on
`interface Array<T>`), AGENTS extension-method table, CHANGELOG.

- [ ] Verify which methods already exist (`find`, `flatMap`, `reverse`,
      `take`, `drop`, `fold`, etc.) — only the missing ones from the
      `std-expansion-tail.md` §F7.array_ext list need adding.
- [ ] Add: `findIndex(self, pred) -> i32`, `some(self, pred) -> bool`,
      `every(self, pred) -> bool`, `flat<E>(self) -> Array<E>` (one
      level), `fill(self, value) -> Self` (in-place semantics modulo
      Erlang immutability — return new), `chunked(self, n) -> Array<Self>`,
      `sliding(self, n) -> Array<Self>`, `sort(self, comparator) -> Self`,
      `unique(self) -> Self` (consecutive de-dup, matching Node
      semantics — non-consecutive callers use `xs.fold(...)`),
      `zip<U>(self, other: Array<U>) -> Array<#(T, U)>`.
- [ ] Each method's per-backend `#[@external]` set per the existing
      interface-method pattern in `primitives.d.bp`. Most are
      `Array.prototype.<name>` on Node (chained shape — §A2-wired) +
      `lists:<name>/N` on Erlang (or an inline fun where no BIF
      exists, e.g. `chunked`/`sliding`).
- [ ] 12 inline tests in `libs/std/tests/array_ext.bp` (one test per
      method's golden-path semantic).
- [ ] Per-method snapshots in `tests/codegen/primitives_array_ext_*.zig`.
- [ ] AGENTS extension-method table + CHANGELOG entry.

#### P6 — F7.string_ext (11 methods on `interface String`)

**Files**: `libs/std/src/primitives.d.bp`, AGENTS, CHANGELOG.

- [ ] Verify which methods already exist (`split`, `slice`, `length`,
      `toUpper`/`toLower`, `contains`, `startsWith`, `endsWith`, `trim*`,
      `replace`, `char_at`, `index_of`).
- [ ] Add the missing ones from the §F7.string_ext list: `padStart`,
      `padEnd`, `repeat`, `replaceAll`, `chars`, `lines`, `words`,
      `charCodeAt`, `lastIndexOf`. (`replace`/`indexOf` may already be
      present — confirm before adding.) Each is a Node prototype method
      + an Erlang `string:`/`re:`/`unicode:` mapping.
- [ ] 9 inline tests in `libs/std/tests/string_ext.bp`.
- [ ] Per-method snapshots.
- [ ] AGENTS + CHANGELOG.

#### P7 — F7.unicode tails (codepoints + normalize)

**Files**: `libs/std/src/unicode.bp`, AGENTS + docs + CHANGELOG.

- [ ] `pub fn codepoints(s: string) -> Array<i32>` — Node template:
      `Array.from($0).map((c) => c.codePointAt(0))`. Erlang template:
      `unicode:characters_to_list($0, utf8)`.
- [ ] `pub enum NormalizationForm { NFC, NFD, NFKC, NFKD }`.
- [ ] `pub fn normalize(s: string, form: NormalizationForm) -> string`
      — pure-bp dispatcher over the enum that calls one of four
      per-target external fns (`normalizeNfc`/`normalizeNfd`/
      `normalizeNfkc`/`normalizeNfkd`), each annotated with
      `s.normalize('NFC')` etc. on Node and
      `unicode:characters_to_nfc_binary` / `nfd` / `nfkc` / `nfkd` on
      Erlang.
- [ ] 4 inline tests (codepoints of `"aé€"` is `[97, 233, 8364]`;
      normalize NFC of decomposed `"á"` (U+0061 U+0301) equals composed
      (U+00E1); NFKC of an unusual form; round-trip via codepoints +
      Array.fold + fromCodepoint).
- [ ] AGENTS + docs + CHANGELOG.

#### P8 — F7.regex tails (`record Match` + `match` + `matchAll`)

**Files**: `libs/std/src/regex.bp`, AGENTS + docs + CHANGELOG.

- [ ] `pub record Match { value: string, index: i32 }`.
- [ ] `pub fn match(pattern: string, input: string) -> ?Match` —
      Node template: `(() => { const m = $1.match(new RegExp($0));
      return m ? { value: m[0], index: m.index } : null })()`. Erlang
      template: `(fun() -> case re:run($1, $0, [{capture, first, binary}])
      of {match, [V]} -> #{value => V, index => ...}; nomatch -> undefined
      end end)()`.
- [ ] `pub fn matchAll(pattern: string, input: string) -> Array<Match>`
      — uses the `g` flag on Node, `[global, {capture, first, binary},
      {return, list}]` on Erlang.
- [ ] 3 inline tests (single match returns ?Match with value + index;
      matchAll yields every overlapping-free match; empty input
      returns null / empty array).
- [ ] AGENTS + docs + CHANGELOG; drop the deferral notes from the
      file header.

#### P9 — F1 STD-001 `std-unsupported-on-target` diagnostic

**Files**: `comptime/env.zig` (add `target: ?[]const u8 = null` field),
`comptime/infer.zig` (`markStdImports` extended), `comptime.zig`
(thread `target_name: ?[]const u8` through `compile` → `analyzeModule`
→ `analyzeSource` → set on env), `comptime/diagnostics.zig` (register
`std_unsupported_on_target`), `codegen.zig` (`generate` derives target
name and passes through), `tests/comptime/std_unsupported_on_target.zig`
+ `tests/comptime/std_supported_on_target.zig`.

- [ ] `Env` field `target: ?[]const u8 = null`; null = no STD-001
      check (preserves the existing LSP / test path defaults).
- [ ] `Env` field `stdModuleFns: std.StringHashMap([]const ast.FnDecl)`
      populated in `comptimeMod.registerStdlib` alongside
      `stdModuleTypes`. Stores the full FnDecl (annotations + body
      presence) so STD-001 can read `externalFor(target)` on each.
- [ ] `markStdImports` extended: when `env.target != null`, walk each
      imported module's `stdModuleFns` entry; for each declare fn (no
      body) with no `externalFor(env.target.?)` match, red with
      `TypeError.custom("std-unsupported-on-target: module '<name>'
      has no implementation for target '<target>'; see
      tasks/v0.beta.19/specs/std-expansion.md §'Coverage matrix'.",
      "STD-001")`.
- [ ] Thread `target_name: ?[]const u8` through `compile` →
      `analyzeModule` → `analyzeSource`. Default null; CLI codegen
      passes the cfg.targetSource string (`"commonJS"`/`"erlang"`/
      `"beam"`/`"wasm"` matching `externalFor` keys).
- [ ] `comptime/diagnostics.zig` — register
      `std_unsupported_on_target: []const u8 = "std-unsupported-on-target"`
      in `all_codes`.
- [ ] `tests/comptime/std_unsupported_on_target.zig` —
      `import {fs} from "std";` (uses an `fs` stub if F6.fs hasn't
      landed) on `--target wat` reds with STD-001 at the import span.
- [ ] `tests/comptime/std_supported_on_target.zig` —
      `import {path} from "std";` on `--target commonJS` is green
      (path is wat-safe too — pure-bp).

#### P10 — F2 sidecar shipping infra + smoke fixture

**Files**: `modules/compiler-cli/src/cli/lib_test.zig` or `test_cmd.zig`
(whichever owns the `--lib std` test-out layout — verify which is
current), `libs/std/AGENTS.md` §"Sidecar adapters" section,
`tests/cli/lib_test_sidecar.zig`.

- [ ] In the `--lib std` lib-test out-dir builder, for each emitted
      module `<m>.{js,erl}`, look for a sibling
      `libs/std/src/sidecars/<m>.{mjs,erl}` in the source. If present,
      copy verbatim next to the emitted file so the emitted code can
      `require('./<m>.mjs')` (Node ≥ 14 sibling-path) or
      `-include("<m>.erl")` (Erlang preprocessor).
- [ ] No transpile, no minify — the adapter is plain target source.
- [ ] `libs/std/AGENTS.md` — new §"Sidecar adapters" subsection:
      convention (one file per module per target; placed at
      `libs/std/src/sidecars/<m>.<ext>`; the emitted module imports it
      via the sibling path; the lib-test runner copies it during
      `--lib std`).
- [ ] `tests/cli/lib_test_sidecar.zig` — fixture drops a no-op
      `sidecars/_smoke.mjs` next to a stub `libs/std/src/_smoke.bp`,
      runs lib-test, asserts the `.mjs` was copied to the `test-out/`
      directory next to the emitted `.js`. The stub `_smoke.bp` +
      `_smoke.mjs` are cleaned up by the test teardown.

#### P11 — F4.time.sleep + F4.asserts.throws backfill (gated on P1)

**Files**: `libs/std/src/time.bp`, `libs/std/src/asserts.bp`, AGENTS +
docs + CHANGELOG rows.

- [ ] `time.bp` — add
      `#[@result]
      #[@external(node, """(s => new Promise(r => setTimeout(() => r({ ok: 0 }), s)))($0)"""),
        @external(erlang, """(fun(__M) -> timer:sleep(__M), {ok, 0} end)($0)""")]
      pub declare fn sleepMs(ms: i64) -> @Result<i32, string>;`
      using §A3 template-owned wrapper. (`#[@future]` for the JS
      Promise is the alternative spec form but `#[@result]` + the
      sync-wait erlang form keeps the surface uniform.)
- [ ] Alternatively, ship `pub declare fn sleep(ms: i64) -> *unit`
      with `#[@future]` if §A3 grows to also cover `#[@future] declare
      fn`. Choose at land time.
- [ ] `asserts.bp` — implement `throws(body, message)` once §A3 lands a
      `#[@result] declare fn _bpAssertsTryCatch(body) -> @Result<unit, string>`
      template, then wrap the body in a pure-bp `match` over the
      result. Drop the deferral note.
- [ ] 4 new inline tests across the two modules.

#### P12 — F4.random.seed + F8.crypto.randomBytes (gated on P10 sidecar)

**Files**: `libs/std/src/random.bp`, `libs/std/src/crypto.bp`,
`libs/std/src/sidecars/random.mjs`, `libs/std/src/sidecars/crypto.mjs`,
AGENTS + docs + CHANGELOG.

- [ ] `sidecars/random.mjs` — Mulberry32 PRNG + `seed(s)` /
      `seededFloat()` exports.
- [ ] `random.bp` — `seed(s: i64) -> unit` lowers to
      `require('./random.mjs').seed($0)` on Node + `rand:seed(exsplus,
      {$0, $0, $0})` on Erlang. After seeding, `float()` reads from the
      module-local `state` via the sidecar (the change to `float()` is
      additive — it reads from the sidecar if seeded, falls back to
      `Math.random` otherwise).
- [ ] `crypto.bp` — `randomBytes(n: i32) -> Array<u8>`. Node template
      uses `require('crypto').randomBytes($0)`; Erlang uses
      `crypto:strong_rand_bytes($0)`. The byte-array conversion needs
      a per-target template that emits a comprehension or `Array.from`.
- [ ] 3 inline tests (seeded random reproducible across two calls;
      randomBytes(N) length == N; randomBytes(0) is empty).

#### P13 — F6.env tails (args + vars)

**Files**: `libs/std/src/env.bp`, AGENTS + docs + CHANGELOG.

- [ ] `args() -> Array<string>` — Node template:
      `process.argv.slice(2)` (drop `node` + script path). Erlang
      template: `init:get_plain_arguments()` + per-element
      `list_to_binary`.
- [ ] `vars() -> Array<#(string, string)>` — Node template:
      `Object.entries(process.env)`. Erlang template: walk
      `os:list_env_vars/0` projecting `{k, v}` → `#(k, v)`.
- [ ] 2 inline tests (args returns the runner's argv tail; vars
      contains a `BOTOPINK_TEST_ARGSVARS=alive` key after a `write`).

#### P14 — F6.os tails (userInfo + eol)

**Files**: `libs/std/src/os.bp`, AGENTS + docs + CHANGELOG.

- [ ] `pub record UserInfo { uid: i32, username: string }`.
- [ ] `userInfo() -> UserInfo` — Node:
      `(() => { const u = require('os').userInfo(); return { uid: u.uid, username: u.username } })()`.
      Erlang: `#{uid => element(2, file:read_file_info("/")), username =>
      list_to_binary(os:getenv("USER"))}` (best-effort — Erlang has no
      direct `os.userInfo` BIF).
- [ ] `eol() -> string` — Node: `require('os').EOL`. Erlang: per-platform
      `case os:type() of {win32, _} -> <<"\r\n">>; _ -> <<"\n">> end`.
- [ ] 3 inline tests (userInfo username non-empty, eol on POSIX is
      "\n", eol length is 1 or 2).

#### P15 — F6.fs (heavy, gated on P1 + P10)

**Files**: `libs/std/src/fs.bp`, `libs/std/src/sidecars/fs.{mjs,erl}`,
AGENTS + docs + CHANGELOG.

- [ ] `pub record FileStat { size: i64, mtime: i64, isDir: bool }`.
- [ ] `#[@result] declare fn` family wrapping Node `fs/promises` +
      Erlang `file:*` to the uniform `@Result` shape:
      `readText(path) -> @Result<string, string>`,
      `writeText(path, contents) -> @Result<unit, string>`,
      `exists(path) -> bool`,
      `list(path) -> @Result<Array<string>, string>`,
      `mkdir(path, recursive: bool = false) -> @Result<unit, string>`,
      `rm(path, recursive: bool = false) -> @Result<unit, string>`,
      `stat(path) -> @Result<FileStat, string>`,
      `copy(src, dest) -> @Result<unit, string>`.
- [ ] Each external annotation sources its body from
      `sidecars/fs.{mjs,erl}` exports (the sidecar shipper from P10
      copies them next to the emitted file).
- [ ] 8 inline tests over a temp dir (`os.tmpdir()` joined with a
      random UUID — `time.nowMillis()` for entropy in pre-§A3 PRNG).
- [ ] `root.bp` adds `pub mod fs;`.
- [ ] AGENTS + docs + CHANGELOG.

#### P16 — F8.http (heavy, gated on P10)

**Files**: `libs/std/src/http.bp`, `libs/std/src/sidecars/http.mjs`,
`tests/cli/http_echo.zig` (test harness — echo server), AGENTS + docs
+ CHANGELOG.

- [ ] `pub record Request { method: string, url: string, headers:
      Array<#(string, string)>, body: string }`.
- [ ] `pub record Response { status: i32, headers: Array<#(string,
      string)>, body: string }`.
- [ ] `send(req: Request) -> *@Result<Response, string>` with
      `#[@future]` via chained §A2 template + sidecar
      `sidecars/http.mjs` wrapping `node:http` as a Promise.
- [ ] Pure-bp composers: `get(url) -> *@Result<Response, string>` and
      `postJson(url, body: JsonValue) -> *@Result<Response, string>`.
- [ ] `tests/cli/http_echo.zig` — echo-server harness spawning a
      throwaway `node:http` server bound to a free port, asserting the
      `send` round-trip + the `postJson` Content-Type header.
- [ ] 4 inline tests (get round-trip, postJson Content-Type, 4xx →
      Error, header pass-through).
- [ ] `root.bp` adds `pub mod http;`.
- [ ] AGENTS + docs + CHANGELOG.

#### P17 — F4.random.shuffle (gated on Option.expect)

**Files**: `libs/std/src/random.bp`, AGENTS + docs + CHANGELOG.

- [ ] Add `Option.expect<T>(default_for_unwrap: T) -> T` to the option
      surface in `builtins.d.bp` — pure-bp lift over `unwrapOr(default)`
      that makes shuffle's "we know the index is in bounds" assertion
      readable.
- [ ] `random.bp` — `shuffle<T>(xs: Array<T>) -> Array<T>` via
      head/tail recursion + `xs.at(idx).expect(<the first elem>)` to
      unwrap with a known-valid default.
- [ ] 2 inline tests (shuffle preserves the multiset; shuffle is not
      always identity over 5 draws).

#### P18 — F9 examples-CLI + per-target coverage table

**Files**: `libs/std/src/examples.md`, `modules/compiler-core/src/codegen/AGENTS.md`,
`CHANGELOG.md`, `tasks/v0.beta.19/status.md`.

- [ ] `libs/std/src/examples.md` — replace the F0 stub with the full
      "Real-world examples" section: a ~30-line CLI tool reading
      `env.read("HOME")` + `process.cwd()` + `fs.readText` of a JSON
      file + `http.get` of a configured URL + writes the merged
      result. Each step references the `std/<m>` source by `file:line`.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` — new "Per-target
      coverage" subsection mirroring `std-expansion.md` §"Coverage
      matrix" but driven from the `STD-001` per-target lookup landed
      in P9 (one row per module × 4 backends; checkboxes generated
      from the actual annotation set).
- [ ] `CHANGELOG.md` — per-wave entries collated:
      `feat(std): wave 1 tail — base64, json`
      `feat(std): wave 2 tail — env, fs, process, os`
      `feat(std): wave 3 tail — regex, unicode + array/string_ext`
      `feat(std): wave 4 tail — http, crypto`
      Each line lands in its own commit per the §spec convention.
- [ ] `tasks/v0.beta.19/status.md` — flip the `std-expansion-tail`
      row to `done` once everything merges into `feat`.

#### P19 — final unification sweep + push to origin/feat

**Files**: meta worktree submodule pointers, bot-lang `feat` branch.

- [ ] Re-fetch `origin/feat` on every sibling (memory:
      `feedback_feat_remotes_unified`). Resolve drift.
- [ ] Bump the bot-lang submodule pointer in the meta to the final
      `feat` SHA carrying every phase above.
- [ ] Push the meta task branch + the bot-lang `feat` (requires
      user authorization for the shared-branch push).
- [ ] Memory updates — flip `project_v0beta19_std_expansion_tail.md`
      to `DONE+PUSHED`; bump MEMORY.md row.

### Test scenarios

The §"Test scenarios" table in `std-expansion-tail.md` already
captures the canonical contract for every module. The follow-up
inherits it; the additions specific to this spec are:

```
P1 — §A3 ok/error template fixture round-trips parse("42") → {ok: 42} / {ok, 42}
P1 — §A3 missing-error branch reds with result-template-shape-mismatch
P5/P6 — array_ext + string_ext per-method snapshots stay byte-identical at every site
P9 — STD-001 fires at the import-site span on `--target wat` for fs
P9 — STD-001 carries the spec-link in the message
P9 — STD-001 does NOT fire on `--target commonJS` for path
P10 — sidecar smoke: emitting _smoke.bp with --target node ships sidecars/_smoke.mjs
P10 — sidecar absence: emitting a module with no sidecar is a no-op
```

### Notes

- **Build order: P1 → P4 → (P5 || P6 || P7 || P8) → P9 → P10 → P11 →
  P12 → P13 → P14 → P15 → P16 → P17 → P18 → P19.** The infra phases
  (P1/P9/P10) are sequential; the module phases (P5–P8, P11–P17) are
  pairwise file-disjoint and can interleave per-spec rolling-commit
  policy.
- **Gate on every commit**: pre-commit shim runs `zig build test` +
  `botopink-lib-test --lib std --target commonJS,erlang` on every land,
  per the project pre-commit convention.
- **Snapshots** for the new fixtures regenerate on first run and stay
  pinned; the parallel-test scratch-dir contract
  (`project_zig016_parallel_test_flakiness`) keeps them stable.
- **No `--no-verify`** — every commit gates green.
- **The bot-lang push to `origin/feat`** stays the final P19 step; per
  shared-branch policy in this session, requires explicit user
  authorization (cannot be bypassed by the harness).

### Exit gate

- [ ] All P1–P19 checkboxes ticked.
- [ ] All test scenarios in `std-expansion-tail.md` §"Test scenarios"
      AND the additions above pass on a local rerun.
- [ ] `zig build test` + `botopink-lib-test --lib std --target
      commonJS,erlang` green; new `--target wat` smoke for the
      STD-001 diagnostic green.
- [ ] The `Coverage matrix` table in `std-expansion.md` agrees with
      the STD-001 lookup at runtime.
- [ ] `tasks/v0.beta.19/status.md` flips the `std-expansion-tail`
      row to `done`.
- [ ] Memory updated to `DONE+PUSHED`.

---

## option-expect — `Option.expect<T>(default: T) -> T` for proven-in-bounds unwraps

**Slug**: option-expect
**Depends on**: nothing — single additive method on the existing `?T` surface.
**Files**: `libs/std/src/builtins.d.bp` (1 new method on `?T`),
  `comptime/infer.zig` (handler arm in the option-method dispatch),
  `comptime/transform.zig` (lowering — same shape as `unwrapOr`),
  `tests/comptime/option_expect.zig` (new — exact ordering + sentinel),
  `tests/codegen/option_expect.zig` (new — round-trip on commonJS +
  erlang).
**Touches docs**: `libs/std/AGENTS.md` (option method table — new row),
  `libs/std/src/builtins.d.bp` doc comments, `CHANGELOG.md`.
**Status**: pending

### Premise

`std-expansion-tail`'s F4.random.shuffle deferred because shuffling a
generic `Array<T>` needs to extract an element at a known-valid index
without a `match` ceremony. The current `?T` surface offers
`unwrapOr(default)` which forces every caller to supply a value of type
`T` — fine for concrete primitives, but for a generic shuffle/swap
implementation over `T` there is no natural default. Three landed
modules already work around this with sentinel values
(`xs.at(idx).unwrapOr("")` in `path.bp`/`random.bp`/`unicode.bp`), and
each call site documents the "we know this won't fire" intent inline.

`Option.expect<T>(default: T) -> T` formalises the pattern: identical
runtime semantics to `unwrapOr`, but the name signals to the reader
"the absent branch is unreachable; this default is the sentinel".
Adding it is one annotation row on `?T` in `builtins.d.bp`, one
handler arm in `inferBuiltinOptionMethod`, and one lowering line in
the option-method transform. The §A2 templates already wired for
`unwrapOr` reuse verbatim.

### Surface

```bp
//// On `?T` (option), declared in `builtins.d.bp`:
//
// Unwrap the value, falling back to `default` when absent. Identical
// runtime behaviour to `unwrapOr` — the name is the only difference.
// Use when you can prove the value is present (e.g. `xs.at(i)` after a
// bounds check) and want the reader to see the assertion intent.
default fn expect<T>(self: ?T, default: T) -> T
```

### Steps

- [ ] `libs/std/src/builtins.d.bp` — add the `expect<T>` row next to
      `unwrapOr<T>` in the `?T` section. The doc comment explicitly
      cites the "proven in bounds" use case so reviewers don't read it
      as a synonym to `unwrapOr` (the choice is intentional — see the
      "Why a synonym" note below).
- [ ] `comptime/infer.zig` — extend `inferBuiltinOptionMethod` (or
      whichever function carries the `unwrapOr` arm) to recognise
      `expect` as a method on `?T` with the same arity / typing as
      `unwrapOr`. Returns the inner type `T`.
- [ ] `comptime/transform.zig` — extend the option-method lowering to
      emit the same shape as `unwrapOr` for `expect` (no per-backend
      branch needed — every backend already handles `unwrapOr`).
- [ ] `tests/comptime/option_expect.zig` — new fixture: `val o: ?i32 =
      some(42); val v = o.expect(0)` returns 42; `val n: ?i32 = null;
      val v = n.expect(99)` returns 99 (semantically identical to
      `unwrapOr` — pin the contract).
- [ ] `tests/codegen/option_expect.zig` — round-trip on commonJS +
      erlang. Snapshots regenerate on first run, stay pinned.
- [ ] `libs/std/AGENTS.md` — extend the option-method table row to
      mention `expect`.
- [ ] `CHANGELOG.md` — `feat(std): Option.expect — proven-in-bounds
      unwrap surface` entry under "Added".

### Test scenarios

```
ok   option.expect on Some returns the inner value
ok   option.expect on None returns the default
ok   option.expect lowers to the same JS / Erlang shape as unwrapOr
green   xs.at(i).expect(sentinel) round-trips through the §A2 template path
```

### Why a synonym

The `expect` / `unwrapOr` distinction matches the Rust convention
(`Option::expect("msg")` panics with a message on None; `Option::unwrap_or(default)`
returns the default). botopink's `Option` runtime doesn't carry a panic
surface for `expect` (the spec deliberately keeps the `?T` shape
backend-portable; `@panic` is opt-in at the call site), so `expect`
takes a `default` argument identical to `unwrapOr` — what changes is
the name's documentation contract. Use `unwrapOr(default)` when the
default is a meaningful fallback; `expect(sentinel)` when the absent
branch is unreachable and the default is purely a type witness.

### Exit gate

- [ ] `zig build test` green; new fixtures pass on the first run after
      snapshots seed.
- [ ] `botopink-lib-test --lib std --target commonJS,erlang` green.
- [ ] `random.shuffle<T>` (`std-expansion-tail-followup` P17) ships
      with `expect` consuming the surface — pull this spec **before**
      P17.
- [ ] `libs/std/AGENTS.md` option-method table updated; CHANGELOG
      entry under "Added".
