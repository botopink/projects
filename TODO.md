# TODO — std-expansion-tail (v0.beta.19 follow-up)

> Branch: `task/std-expansion-tail` · Worktree: `.tasks/std-expansion-tail/`
> Spec: [`tasks/v0.beta.19/specs/std-expansion-tail.md`](tasks/v0.beta.19/specs/std-expansion-tail.md)
> Set umbrella: [`tasks/v0.beta.19/README.md`](tasks/v0.beta.19/README.md)
> Status rollup: [`tasks/v0.beta.19/status.md`](tasks/v0.beta.19/status.md)
>
> Reference URLs (cite verbatim in every new `.bp` header):
> - Node.js: <https://nodejs.org/api/>
> - Erlang stdlib: <https://www.erlang.org/doc/apps/stdlib/api-reference.html>
>
> Edit code **inside this worktree only**. Pre-commit runs zig fmt +
> build + test (no `--no-verify`).

## Mission

Close the 12 deferred std modules from `std-expansion`
(`json`/`base64`/`env`/`fs`/`process`/`os`/`regex`/`unicode`/`array_ext`/
`string_ext`/`http`/`crypto`), the in-module tails on the 5 landed
modules, the F6 `STD-001` `std-unsupported-on-target` diagnostic, the
F7 examples-CLI + per-target coverage doc, and add two grammar pieces
to `prim-op-annotation` (§A2 chained host calls + §A3 `#[@result]
declare fn` template-owned wrapper).

## Coordination

- **One worktree, sequential phases.** Each F# below is one or more
  commits; F0/F1 land first (cleanup + diagnostic — no impact on the
  deferred modules), then F2/F3 (infra + grammar — gated by their own
  snapshots), then F4 (in-module tails — one commit per module),
  then F5–F8 wave by wave (one commit per module). F9 closes.
- **Per-module sidecars** ship at `botopink-lib-test` time — the build
  copies `libs/std/src/sidecars/<m>.{mjs,erl}` next to the emitted
  `<m>.{js,erl}` so the emitted code can `require('./<m>.mjs')` /
  `-include("<m>.erl").` (F2 authors the shipping step; F5+ uses it).
- **Coverage matrix is the gate.** Importing a module marked ✗ on the
  active backend reds with `STD-001` at the import site (F1 enforces).

## §A — `prim-op-annotation` grammar additions

### §A2 — chained host-call passthrough

- [x] Regression tests in `tests/codegen/externals.zig`: A2 chained
      host call (`Buffer.from($0, 'utf8').toString('base64')`) and
      A2 method-on-class (`JSON.stringify($0)`) render verbatim.
      Snapshots created on all 4 backends.
- [x] commonJS backend now consumes per-callee templates — the
      legacy aliasing path (`const fn = recv.method`) stripped the
      receiver; §A2 added `Emitter.user_node_templates` +
      `tryEmitUserTemplate` mirroring the erlang shape. Decl emits a
      doc breadcrumb instead of the alias; call site renders inline.
- [x] `libs/std/src/time.bp` `monotonicTimeWithUnit` switched to the
      §A2 form (`@external(node, "performance.now($0)")`) — Node's
      real DOM high-res timestamp instead of the `Date.now(1000)`
      fallback that landed in F4.time.

### §A3 — `#[@result]`-aware `declare fn` template

- [ ] `parser/decls.zig` — relax §B-R7 to accept
      `#[@result] declare fn …` whose template body literally
      carries the target's `{ ok / error }` shape.
- [ ] `comptime/infer.zig` — for a `#[@result] declare fn`, skip the
      auto-wrap (the template already produces the wrapper). Add
      comptime check `result-template-shape-mismatch`: parse the
      template body looking for the target's `{ ok / error }`
      tokens; red if either branch is missing.
- [ ] `tests/codegen/result_template.zig` — round-trip
      `parse("42")` to `{ ok: 42 }` (JS) / `{ok, 42}` (erlang).
- [ ] `comptime/diagnostics.zig` — register
      `result-template-shape-mismatch` with a stable code.

## F0 — doc cleanup (no compiler edits)

- [x] `repository/botopink-lang/CHANGELOG.md` `url` row — drop the
      "serialize deferred" sentence (`serialize(u)` landed in bot-lang
      `5788bd7`). Replace with a one-line "round-trip closed" note
      linking to this spec.
- [x] `repository/botopink-lang/libs/std/docs.md` `url.bp` row — extend
      to `record Url { … } + parse(s) + serialize(u)`.
- [x] `repository/botopink-lang/libs/std/examples.md` — add a stub
      `## Real-world examples` heading with a one-line pointer to F9.
- [x] `repository/botopink-lang/libs/std/AGENTS.md` — add a
      "Wave-tail roadmap" row pointing at this spec.

## F1 — F6 enforcement (`STD-001` diagnostic)

- [ ] `modules/compiler-core/src/comptime/infer.zig` — at every
      `import { … } from "std"` resolve site, read the per-target
      `#[@external]` annotation set on each imported decl. If the
      active target has no matching annotation (and the decl is not
      a pure-bp `pub fn`), emit
      `std-unsupported-on-target: module '<name>' has no
      implementation for target '<target>'; see
      tasks/v0.beta.19/specs/std-expansion.md §"Coverage matrix".`
      Stable code: `STD-001`.
- [ ] `comptime/diagnostics.zig` — register `STD-001`
      (`stdUnsupportedOnTarget`) mirroring the existing diagnostic
      registry shape. Span = import-site span. Detail = module name.
- [ ] `tests/comptime/std_unsupported_on_target.zig` — new fixture:
      `import {fs} from "std";` compiled with `--target wat` reds
      with `STD-001`. Until F6 lands `fs.bp`, the fixture uses a
      throwaway `libs/std/src/_test_unsupported.bp` (cleaned up on
      F6 land).
- [ ] `tests/comptime/std_supported_on_target.zig` — counter-fixture:
      `import {path} from "std";` on `--target commonJS` does NOT
      red (path is ✓ on every target).

## F2 — sidecar shipping infra

- [ ] Per-module sidecar discovery: when emitting
      `libs/std/src/<m>.bp` for `--lib std` lib-test, the build
      looks for `libs/std/src/sidecars/<m>.{mjs,erl}` and copies it
      next to the emitted `<m>.{js,erl}`. Owner: the current
      `--lib std` test-out builder
      (`modules/compiler-cli/src/cli/test_cmd.zig` `runLibTests` or
      its successor in `lib_test.zig`).
- [ ] `libs/std/AGENTS.md` §"Sidecar adapters" — document the
      convention: one file per module per target; the adapter is
      plain target source (no botopink syntax); the emitted module
      imports it via the sibling path.
- [ ] `tests/cli/lib_test_sidecar.zig` — new fixture: drop a no-op
      `sidecars/_smoke.mjs` next to a stub `libs/std/src/_smoke.bp`,
      run lib-test, assert the `.mjs` is copied to the
      `test-out/` directory next to the emitted `.js`.

## F3 — completion of §A2 + §A3 (see §A above)

Tracked in `§A — prim-op-annotation grammar additions`. F3 is the
build-order marker: complete §A2 + §A3 before F4 starts (the tails
in F4 use chained-host-call shapes and `#[@result] declare fn`).

## F4 — in-module tails (5 landed modules)

### F4.path — `relative` + `resolve`

- [x] `libs/std/src/path.bp` — `relative(src: string, dst: string) -> string`
      using explicit head/tail recursion (`commonPrefixCount`
      tail-walk + `makeUps` prepend recursion). Renamed `(from, to)` →
      `(src, dst)` because `from` is the reserved import keyword.
- [x] `libs/std/src/path.bp` — `resolve(segments: string[]) -> string`
      (variadic via Array; `PathAccum` record + `applyPieces` /
      `resolveAll` tail-recursion).
- [x] 4 new inline `test { … }` blocks (relative same-dir, relative
      up-one, resolve absolute, resolve with `..`).
- [x] Update `libs/std/AGENTS.md` `path` row + `libs/std/docs.md`
      `path.bp` row.

### F4.random — `intInRange` + `bool` + `shuffle` + `seed`

- [x] `libs/std/src/random.bp` — `intInRange(lo: i32, hi: i32) -> i32`
      (closed interval; `lo` + floor(float() * (hi - lo + 1)) via
      `floorWalk`).
- [x] `random.bp` — `bool() -> bool` (alias for `coin()` per the
      Node `Math.random()` mental model).
- [ ] `random.bp` — `shuffle<T>(xs: Array<T>) -> Array<T>`
      (Fisher–Yates over a copy; see `shuffleLowering` note in spec
      §F4). **DEFERRED** — needs `?T` unwrap with a generic default,
      which the current option chain doesn't provide. Pull when the
      `Option.expect`/`Option.unsafeUnwrap` surface lands.
- [ ] `random.bp` — `seed(s: i64) -> unit` (Erlang
      `rand:seed(exsplus, {s, s, s})`; Node falls back to a userland
      Mulberry32 PRNG seeded via a module-local `state`). **DEFERRED**
      — needs F2 sidecar shipping for the Node Mulberry32 adapter.
- [x] 4 new inline tests (bool, intInRange in `[1,6]`, single-point,
      inverted-range fallback).
- [x] AGENTS + docs row update.

### F4.time — `monotonicMillis` + `sleep` + `formatIso8601` + `measureMillis`

- [x] `libs/std/src/time.bp` — `monotonicMillis() -> i64`. Erlang lowers
      to `erlang:monotonic_time(1000)` (integer divisor); Node falls
      back to `Date.now(1000)` until §A2 wires commonJS to consume
      per-callee templates (aliasing `performance.now` strips the
      receiver — the bare-`(target, module, symbol)` form can't bind
      `this`).
- [ ] `time.bp` — `sleep(ms: i64) -> *unit` with `#[@future]`
      (`setTimeout` Promise / `timer:sleep`). **DEFERRED** — needs
      §A3 `#[@future] declare fn` template ownership.
- [ ] `time.bp` — `formatIso8601(ms: i64) -> string`
      (`new Date(ms).toISOString()` /
      `calendar:system_time_to_rfc3339`). **DEFERRED** — needs §A2
      chained host call wired into commonJS.
- [x] `time.bp` — `measureMillis<T>(body: fn() -> T) -> #(T, i64)`.
      Pure botopink — composes two `nowMillis()` reads around the body.
- [x] 4 new inline tests (monotonic non-decreasing × 1, measureMillis
      result + elapsed × 1 — folded into the existing nowMillis pair).
- [x] AGENTS + docs row update.

### F4.asserts — `throws` + `matches` + `AssertError`

- [ ] `libs/std/src/asserts.bp` — `throws(body: fn() -> any,
      message: ?string)` catches a `@panic` from `body` and reds
      with `message` if none was thrown. **DEFERRED** — needs §A3
      `#[@result] declare fn` for a host-level try/catch wrapper so
      pure-bp can intercept the panic without owning the runtime exit.
- [ ] `asserts.bp` — `matches(pattern: string, actual: string)`
      regex-matches `actual` against `pattern`. **DEFERRED** — depends
      on §F7 `regex.test`.
- [x] `asserts.bp` — `pub record AssertError { message: string,
      file: string, line: i32 }` carried in the test runner's
      failure stream.
- [x] 1 new inline test (AssertError shape; the throws/matches tests
      land with §A3 + §F7).
- [x] AGENTS + docs row update.

### F4.url — verification only

- [x] No code edits — `url.bp` already carries `parse + serialize`
      from bot-lang `5788bd7`. The F0 doc cleanup folds it in.

## F5 — §W1 tails

### F5.json

- [ ] `libs/std/src/json.bp` — `JsonValue` enum
      (`Null`/`Bool`/`Number`/`String`/`Array<JsonValue>`/
      `Object<#(string, JsonValue)>`).
- [ ] `json.bp` — `#[@result] declare fn parse(s: string)
      -> @Result<JsonValue, string>` via §A3 template + sidecar
      `sidecars/json.{mjs,erl}` that wraps `JSON.parse` /
      `json:decode` in `try`/`catch`.
- [ ] `json.bp` — `stringify(v: JsonValue) -> string` +
      `stringifyPretty(v: JsonValue, indent: i32) -> string`.
- [ ] `sidecars/json.mjs` (Node) + `sidecars/json.erl` (Erlang).
- [ ] 6 inline tests (round-trip Number/String/Array/Object, error,
      nested, escaped strings).
- [ ] `root.bp` adds `pub mod json;`.
- [ ] AGENTS + docs + CHANGELOG entry.

### F5.base64

- [x] `libs/std/src/base64.bp` — `encode(s: string) -> string` /
      `decode(b: string) -> string` via §A2 chained template
      (`Buffer.from($0, 'utf8').toString('base64')` on Node,
      `base64:encode/1` on Erlang). Note: returns bare `string`
      rather than `@Result<string, string>` — the spec's `@Result`
      shape needs §A3 to land cleanly; the bare form matches the
      pre-existing Erlang BIF contract (raises on malformed input).
- [x] `base64.bp` — `encodeUrlSafe` / `decodeUrlSafe` (url-safe
      variant with `-`/`_` replacement + `=` padding helper via
      tail-recursive `padToMultipleOfFour`).
- [x] 4 inline tests (round-trip, empty, url-safe drops padding,
      url-safe round-trip).
- [x] `root.bp` adds `pub mod base64;`.
- [x] AGENTS + docs + CHANGELOG entry.

## F6 — §W2 tails

### F6.env

- [x] `libs/std/src/env.bp` — `read(name: string) -> ?string` /
      `write(name: string, value: string) -> unit` /
      `clear(name: string) -> unit`. Named `read`/`write`/`clear`
      rather than `get`/`set`/`unset` because `get`/`set` are reserved
      tokens (parser `isMemberName` — soft keywords for struct
      getters/setters).
- [ ] `args() -> Array<string>` and `vars() -> Array<#(string, string)>`
      **DEFERRED** — enumeration shapes differ cross-backend.
- [x] No sidecar needed — the §A2 template path handles the
      property-access shape `(process.env[$0] ?? null)` directly.
- [x] 3 inline tests (write/read round-trip, read of unset returns
      null, clear cancels prior write).
- [x] `root.bp` adds `pub mod env;`.
- [x] AGENTS + docs + CHANGELOG entry.

### F6.fs

- [ ] `libs/std/src/fs.bp` — `readText` / `writeText` / `exists` /
      `list` / `mkdir` / `rm` / `stat` / `copy` (all `@Result`-wrapped).
- [ ] `record FileStat { size, mtime, isDir }`.
- [ ] `sidecars/fs.{mjs,erl}` wraps Node `fs/promises` + Erlang
      `file:*/2` to the `@Result` shape.
- [ ] 8 inline tests over a temp dir.
- [ ] `root.bp` adds `pub mod fs;`.
- [ ] AGENTS + docs + CHANGELOG entry.

### F6.process

- [x] `libs/std/src/process.bp` — `exit(code: i32)` /
      `cwd() -> string` / `platform() -> string` (`'linux'`/
      `'darwin'`/`'win32'`) / `arch() -> string` / `pid() -> i32`.
      `hostname() -> string` deferred — needs `require('os')` threaded
      through the per-module require set on Node (`os.hostname()`
      isn't a global).
- [x] 4 inline tests (cwd non-empty, platform one-of, arch non-empty,
      pid positive).
- [x] `root.bp` adds `pub mod process;`.
- [x] AGENTS + docs + CHANGELOG entry.

### F6.os

- [x] `libs/std/src/os.bp` — `hostname` / `arch` / `cpuCount` /
      `tmpdir`. `userInfo` (uid/username pair) / `eol` deferred —
      cross-backend shape mismatch (Node `os.userInfo()` returns a
      record-shaped object; Erlang has no direct equivalent without
      multi-call composition).
- [x] 4 inline tests (hostname non-empty, arch non-empty, cpuCount
      >= 1, tmpdir non-empty).
- [x] `root.bp` adds `pub mod os;`.
- [x] AGENTS + docs + CHANGELOG entry.

## F7 — §W3 tails

### F7.regex

- [ ] `libs/std/src/regex.bp` — `record Match { value: string,
      index: i32 }`, `match` / `matchAll` / `replace` / `replaceAll`
      / `test` / `splitOn`.
- [ ] 7 inline tests.
- [ ] `root.bp` adds `pub mod regex;`.
- [ ] AGENTS + docs + CHANGELOG entry.

### F7.unicode

- [x] `libs/std/src/unicode.bp` — `fromCodepoint(cp)` +
      `firstCodepoint(s)` (returns `?i32`). `codepoints` and
      `normalize(form)` deferred — `NormalizationForm` enum spans 4
      flavors that don't compose under a single template without
      arity-on-enum dispatch; `codepoints` needs the codepoint→array
      conversion that splits cross-backend (`Array.from(s).map(...)`
      on Node vs `unicode:characters_to_list/2` on Erlang) without
      a clean wrapper.
- [x] 4 inline tests (ASCII 'A' round-trip, ASCII '0' round-trip,
      firstCodepoint of empty is null, firstCodepoint of 'A' is 65).
- [x] `root.bp` adds `pub mod unicode;`.
- [x] AGENTS + docs + CHANGELOG entry.

### F7.array_ext

- [ ] `libs/std/src/primitives.d.bp` — extend `interface Array<T>`
      with 15 methods (`find` / `findIndex` / `some` / `every` /
      `flatMap` / `flat` / `fill` / `chunked` / `sliding` / `sort`
      / `unique` / `reverse` / `zip` / `take` / `drop`). Per-method
      `#[@external]` set per backend.
- [ ] 12 inline tests in `libs/std/tests/array_ext.bp`.
- [ ] Per-method snapshots in
      `tests/codegen/primitives_array_ext_*.zig`.
- [ ] AGENTS extension-method table + CHANGELOG entry.

### F7.string_ext

- [ ] `libs/std/src/primitives.d.bp` — extend `interface String`
      with 11 methods (`padStart` / `padEnd` / `repeat` / `replace`
      / `replaceAll` / `chars` / `lines` / `words` / `charCodeAt` /
      `endsWith` / `indexOf` / `lastIndexOf`).
- [ ] 9 inline tests in `libs/std/tests/string_ext.bp`.
- [ ] Per-method snapshots in
      `tests/codegen/primitives_string_ext_*.zig`.
- [ ] AGENTS extension-method table + CHANGELOG entry.

## F8 — §W4 tails

### F8.http

- [ ] `libs/std/src/http.bp` — `record Request { method, url,
      headers, body }`, `record Response { status, headers, body }`,
      `send(req: Request) -> *@Result<Response, string>` with
      `#[@future]` via §A2 chained template + sidecar
      `sidecars/http.mjs` (wraps `node:http` as Promise).
- [ ] `http.bp` — `get(url: string) -> *@Result<Response, string>`
      and `postJson(url: string, body: JsonValue) ->
      *@Result<Response, string>` (pure-botopink composers over
      `send`).
- [ ] `tests/cli/http_echo.zig` — echo-server harness (out of
      direct scope; coordinates with the existing `http-echo`
      deferral in `std-expansion.md` §W4).
- [ ] 4 inline tests (against the echo fixture).
- [ ] `root.bp` adds `pub mod http;`.
- [ ] AGENTS + docs + CHANGELOG entry.

### F8.crypto

- [ ] `libs/std/src/crypto.bp` — `sha256` / `sha512` / `md5`
      (hex-digest strings) / `hmacSha256(key, data)` /
      `randomBytes(n: i32) -> Array<u8>`. §A2 chained template
      (`crypto.createHash('sha256').update(s).digest('hex')` on Node,
      `crypto:hash(sha256, s)` on Erlang).
- [ ] 5 inline tests with canonical vectors
      (`hello world` → `b94d27...`).
- [ ] `root.bp` adds `pub mod crypto;`.
- [ ] AGENTS + docs + CHANGELOG entry.

## F9 — examples-CLI + per-target coverage doc

- [ ] `repository/botopink-lang/libs/std/examples.md` — replace the
      F0 stub with the full "Real-world examples" section: a
      ~30-line CLI tool reading `args()` + `env.get("HOME")` +
      `fs.readText` of a JSON file + `http.get` of a configured URL
      + writes the merged result. Each step references the
      `std/<m>` source by file:line.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` — add a
      "Per-target coverage" subsection mirroring
      `std-expansion.md` §"Coverage matrix" but driven from
      `STD-001`'s per-target lookup (one row per module × four
      backends).
- [ ] `CHANGELOG.md` per-wave entries:
      - `feat(std): wave 1 tail — json, base64`
      - `feat(std): wave 2 tail — env, fs, process, os`
      - `feat(std): wave 3 tail — regex, unicode + array/string_ext`
      - `feat(std): wave 4 tail — http, crypto`
- [ ] `tasks/v0.beta.19/status.md` — flip the `std-expansion-tail`
      row to `done` once merged into `feat`.

## Done gate (per spec "Exit gate")

- [ ] All F0–F9 boxes ticked.
- [ ] All test scenarios in `std-expansion-tail.md` §"Test
      scenarios" pass on a local rerun.
- [ ] `zig build test` + `botopink-lib-test --lib std --target
      commonJS,erlang` green; new `--target wat` smoke for
      `STD-001` green.
- [ ] The `Coverage matrix` table in `std-expansion.md` agrees with
      the `STD-001` lookup at runtime (parse the table + assert
      every cell matches the per-module annotation set).
- [ ] `tasks/v0.beta.19/status.md` flips the row to `done`.

## Per-memory reminders

- SSH for all git remote ops (`feedback_always_ssh_git`).
- Worktree paths for Read/Edit (`project_worktree_workflow`); this
  worktree is at `.tasks/std-expansion-tail/`.
- Functions in camelCase (`feedback_camelcase_naming`); module names
  lowercase singular (`regex`, not `Regex`).
- Implement in `.bp` when possible (`feedback_prefer_bp_over_dbp`);
  `.d.bp` only when 100% host-backed with no pure-botopink helpers.
- After each commit, advance to the next checkbox
  (`feedback_continue_after_commit`).
- Every new `.bp` carries a `////` header citing the Node + Erlang
  URLs for the module (per spec §"Module inventory").
- Update remote feat in every submodule before/during work
  (`feedback_always_update_remote_feat_submodules`); always unify
  to feat at task end.
