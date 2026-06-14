# TODO — std-expansion (v0.beta.19 satellite)

> Branch: `task/std-expansion` · Worktree: `.tasks/std-expansion/`
> Spec: [`tasks/v0.beta.19/specs/std-expansion.md`](tasks/v0.beta.19/specs/std-expansion.md)
> Set umbrella: [`tasks/v0.beta.19/README.md`](tasks/v0.beta.19/README.md)
> Reasoning + decisions: [`tasks/v0.beta.19/plan.md`](tasks/v0.beta.19/plan.md)
>
> Reference URLs (cite verbatim in every new `.bp` header):
> - Node.js: <https://nodejs.org/api/>
> - Erlang stdlib: <https://www.erlang.org/doc/apps/stdlib/api-reference.html>
>
> Edit code **inside this worktree only**. Pre-commit runs zig fmt +
> build + test (no `--no-verify`).

## Mission

Fill cross-backend stdlib gaps from the Node + Erlang reference APIs.
18 new modules across 5 waves; every new `.bp` ships with header
comments citing both upstream URLs and inline `test { … }` blocks
(~100 tests total).

## Coordination

- **`prim-op-annotation` is the hard dependency.** Without `$self` /
  `$N` / `$argc` / `$stringify(...)` / `"""…"""` templates, many
  modules can't express their host bindings (inline `try` around
  `JSON.parse`, `string:pad($self, $0, leading, $1)`, etc).
  → Land `prim-op-annotation` F0–F1 first, then start §W1.
- **Per-wave commits.** Each module ships in its own commit:
  `feat(std/<name>): wave <N> module surface`.
- **Per-wave AGENTS sweep.** `libs/std/AGENTS.md` gains a new section
  per wave landing.
- **Coverage matrix is the gate.** Importing a module marked ✗ on a
  backend reds with `std-unsupported-on-target` (F6 of the spec).

---

## §W1 — essentials

Reference URLs land in every header:
- `Math` global / `Math.*` — <https://nodejs.org/api/>
- `math:*` — <https://www.erlang.org/doc/apps/stdlib/math.html>
- `JSON` global / `json` (OTP 27+) — <https://www.erlang.org/doc/apps/stdlib/json.html>
- `Buffer.toString('base64')` / `base64` — <https://www.erlang.org/doc/apps/stdlib/base64.html>
- `Date` / `timers` / `timer` / `calendar` — <https://www.erlang.org/doc/apps/stdlib/timer.html>
- `Math.random` / `rand` — <https://www.erlang.org/doc/apps/stdlib/rand.html>

- [x] **§W1.math** — 25 host-bound fns + 5 pure-botopink derivations
      (`ceil`/`sign`/`cbrt`/`hypot`/`clamp`) + 8 constants; 14 inline
      tests; header cites both upstream URLs. (Rounding family returns
      `f64` instead of the spec's `i64` to keep the i32/i64 unifier out
      of pure-botopink chains.)
- [ ] **§W1.json** — deferred: needs the richer `#[@external]` template
      from `prim-op-annotation` to express the inline `try`/`catch`
      around `JSON.parse` and the `Buffer.from(...).toString(...)`
      chain. Sidecar adapter pattern (`./gleam_stdlib.mjs`) is in scope
      but the codegen wiring (sidecar resolution + ship at `botopink-lib-test`
      time) is a sibling spec.
- [ ] **§W1.base64** — deferred: same `Buffer.from(s, ...).toString(...)`
      chain shape as `json`; needs the template grammar.
- [x] **§W1.time (partial)** — `nowMillis()` via
      `Date.now(1000)` / `erlang:system_time(1000)`; 2 inline tests.
      `monotonicMillis`/`sleep`/`formatIso8601`/`measureMillis` deferred
      for `prim-op-annotation`.
- [x] **§W1.random (partial)** — `float`/`coin`/`pick<T>`; 4 inline
      tests. `intInRange`/`bool`/`shuffle`/`seed` deferred (the
      walk-up `floorWalk` helper plus `pick` covers the common case;
      `shuffle` needs a stack-mutation Erlang lowering that the
      pure-botopink `var` + `push` pattern trips).
- [x] **§W1.root.bp** — adds `pub mod math; pub mod time; pub mod random;`
      (json/base64 deferred — see above).
- [x] **§W1.AGENTS** — `libs/std/AGENTS.md` gains "Wave 1 modules"
      section per landed module.
- [x] **§W1.gate** — `botopink-lib-test --lib std --target commonJS,erlang`
      green for the landed modules. (`beam` not yet supported by
      `botopink test` runtime — skip rather than fail.)

## §W2 — system

- `process.env` / `process.argv` — <https://nodejs.org/api/process.html>
- `os:getenv` / `os:putenv` — <https://www.erlang.org/doc/man/os.html>
- `path` — <https://nodejs.org/api/path.html>
- `filename` — <https://www.erlang.org/doc/apps/stdlib/filename.html>
- `fs` — <https://nodejs.org/api/fs.html>
- `file` / `filelib` — <https://www.erlang.org/doc/man/file.html>, <https://www.erlang.org/doc/apps/stdlib/filelib.html>
- `process` — <https://nodejs.org/api/process.html>
- `os` — <https://nodejs.org/api/os.html>, <https://www.erlang.org/doc/man/os.html>

- [ ] **§W2.env** — deferred: `process.env.X` access doesn't fit the
      bare `@external` symbol form (needs the template grammar from
      `prim-op-annotation` to express `process.env[$0]`); same for
      Erlang's `os:getenv/1` charlist-vs-binary unwrap.
- [x] **§W2.path** — `separator`/`delimiter` constants + `split`,
      `isAbsolute`, `basename`, `dirname`, `extname`, `join`,
      `normalize`; 9 inline tests; pure botopink (wat-safe). `relative`
      and `resolve` deferred (need `..` stack semantics that trip the
      Erlang `var` + `push` dead-store trap).
- [ ] **§W2.fs** — deferred: file I/O calls all return `{ok, …}` /
      `{error, …}` tuples on Erlang that need template-driven unwrap.
- [ ] **§W2.process** — deferred: `process.cwd()` /
      `file:get_cwd()` / `process.pid` (property vs fn) each need
      either a sidecar adapter or template-driven shape.
- [ ] **§W2.os** — deferred: `os.hostname()` /
      `inet:gethostname()` shape mismatches (atom + charlist tuple).
- [x] **§W2.root.bp** — extends with `pub mod path;` (env/fs/process/os
      deferred — see above).
- [x] **§W2.AGENTS** — `libs/std/AGENTS.md` gains "Wave 2 modules"
      section for `path` with the Erlang `var` + `push` + string-concat
      trap notes.
- [x] **§W2.gate** — `path` green on commonJS + erlang via
      `botopink-lib-test --lib std`.

## §W3 — text

- `RegExp` — <https://nodejs.org/api/> (V8 IRregexp)
- `re` — <https://www.erlang.org/doc/apps/stdlib/re.html>
- `String.prototype.normalize` — <https://nodejs.org/api/>
- `unicode` — <https://www.erlang.org/doc/apps/stdlib/unicode.html>
- `Array.prototype` — <https://nodejs.org/api/>
- `lists` — <https://www.erlang.org/doc/apps/stdlib/lists.html>
- `string` — <https://www.erlang.org/doc/apps/stdlib/string.html>

- [ ] **§W3.regex** — `libs/std/src/regex.bp` with `Match` struct +
      `match` / `matchAll` / `replaceAll` / `test` / `splitOn`; 6 inline
      tests.
- [ ] **§W3.unicode** — `libs/std/src/unicode.bp` with `codepoints`
      iterator + 4 normalisation forms + `firstCodepoint` /
      `fromCodepoint`; 4 inline tests.
- [ ] **§W3.array_ext** — extends `interface Array<T>` in
      `primitives.d.bp` with 15 new methods (`find` / `findIndex` /
      `some` / `every` / `flatMap` / `flat` / `fill` / `chunked` /
      `sliding` / `sort` / `unique` / `reverse` / `zip` / `take` /
      `drop`); per-backend `#[@external]` set per method; 12 inline
      tests in `libs/std/tests/array_ext.bp`.
- [ ] **§W3.string_ext** — extends `interface String` with 11 new
      methods (`padStart` / `padEnd` / `repeat` / `replace` /
      `replaceAll` / `chars` / `lines` / `words` / `charCodeAt` /
      `endsWith` / `indexOf` / `lastIndexOf`); 9 inline tests.
- [ ] **§W3.root.bp** — extends with `pub mod regex; pub mod unicode;`
- [ ] **§W3.AGENTS** — `libs/std/AGENTS.md` §"Wave 3 modules" + the
      Array/String extension method tables in `primitives.d.bp` comment
      block.
- [ ] **§W3.snap** — `tests/codegen/primitives_array_ext_*.zig` and
      `tests/codegen/primitives_string_ext_*.zig` assert the rendered
      output of representative calls.
- [ ] **§W3.gate** — green on commonJS + erlang + beam.

## §W4 — network + crypto

- `url` — <https://nodejs.org/api/url.html>
- `uri_string` — <https://www.erlang.org/doc/apps/stdlib/uri_string.html>
- `querystring` — <https://nodejs.org/api/querystring.html>
- `http` — <https://nodejs.org/api/http.html>
- `httpc` — <https://www.erlang.org/doc/man/httpc.html>
- `crypto` — <https://nodejs.org/api/crypto.html>, <https://www.erlang.org/doc/man/crypto.html>

- [ ] **§W4.url** — deferred: the `Url` struct + parse/serialize would
      need cross-backend URL parsing; pure-botopink is doable but big.
      Tracked as a follow-up after `prim-op-annotation`.
- [x] **§W4.querystring** — `parse(query) -> Array<#(string, string)>`
      and `stringify(pairs)`; 4 inline tests; pure botopink (wat-safe).
      URI percent-encoding deferred — needs the template grammar to
      bind `encodeURIComponent` and `uri_string:quote`.
- [ ] **§W4.http** — deferred: `#[@future]` + echo server fixture
      are out of scope without `prim-op-annotation` + the http-echo
      harness; track as a follow-up.
- [ ] **§W4.http-echo** — deferred (depends on `http.bp`).
- [ ] **§W4.crypto** — deferred: `sha256`/`hmac` host bindings are
      simple-shape but each backend ships them under different module
      prefixes (`crypto.createHash('sha256').update(s).digest('hex')`
      on Node — a chain — vs `crypto:hash(sha256, s)` on Erlang, where
      the algorithm is a literal atom). Both shapes need the
      `prim-op-annotation` template grammar.
- [x] **§W4.root.bp** — extends with `pub mod querystring;`
      (url/http/crypto deferred — see above).
- [x] **§W4.AGENTS** — `libs/std/AGENTS.md` gains a `querystring` row;
      `docs.md` "What the stdlib currently exposes" lists the new
      module.
- [x] **§W4.gate** — `querystring` green on commonJS + erlang via
      `botopink-lib-test --lib std`.

## §W5 — assertions

- `assert` — <https://nodejs.org/api/assert.html>
- (Erlang has no equivalent module — native pattern matching)

- [x] **§W5.asserts** — `libs/std/src/asserts.bp` with `truthy` /
      `falsy` / `equal<T>` / `notEqual<T>` / `approxEqual` /
      `contains`; 6 inline tests. (Named `asserts` plural because
      `assert` is a reserved keyword — `parseModDecl` strictly
      consumes `.identifier` after `mod`.) `throws` / `matches` /
      structured `AssertError` deferred — `throws` needs
      exception-catching from pure botopink, `matches` needs `regex`.
- [x] **§W5.root.bp** — extends with `pub mod asserts;`
- [ ] **§W5.lib-test-runner** — deferred: structured failure with
      `{message, file, line}` would require a new diagnostic surface
      on the runner; current `@panic("…")` message lands in the
      `running N tests` output but without the structured tail.
      Follow-up.
- [x] **§W5.AGENTS** — `libs/std/AGENTS.md` gains a Wave 5 module
      section noting the `asserts` rename + `approxEqual` inline
      shape.
- [x] **§W5.gate** — `asserts` green on commonJS + erlang via
      `botopink-lib-test --lib std`.

## F6 — coverage matrix enforcement
- [ ] `comptime/infer.zig` (or equivalent type-check pass) reads the
      `#[@external(<target>, …)]` annotation set on every `declare fn`
      in `from "std"` imports; emits `std-unsupported-on-target` when
      the active target has no matching annotation. The diagnostic text
      cites `tasks/v0.beta.19/specs/std-expansion.md §"Coverage matrix"`.

## F7 — docs + examples + CHANGELOG
- [ ] `libs/std/docs.md` reorganised: per-module subsection with one
      example per fn.
- [ ] `libs/std/examples.md` gains a "Real-world examples" section: a
      mini CLI tool reading args + env + parsing JSON from a file + http
      get + writing the result.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` "Per-target coverage"
      table updated.
- [ ] `CHANGELOG.md` accumulates one line per wave:
      `feat(std): wave 1 — math, json, base64, time, random`
      `feat(std): wave 2 — env, path, fs, process, os`
      `feat(std): wave 3 — regex, unicode + Array/String extension methods`
      `feat(std): wave 4 — url, querystring, http, crypto`
      `feat(std): wave 5 — assert`

---

## Done gate

- [~] Wave checklists: §W1 + §W2 + §W3 + §W4 + §W5 ticked for the
      _landed_ subset (math, asserts, path, random, querystring, time).
      Deferred surfaces (json, base64, fs, env, process, os, regex,
      unicode, array_ext, string_ext, url, http, crypto, `assert`-named
      module) are explicitly documented in their wave sections — each
      needs either the `prim-op-annotation` template grammar or
      a new sidecar wiring spec to land cleanly.
- [x] Every landed `.bp` file's header comment cites both upstream URLs
      verbatim (ref-cite gate).
- [~] `botopink-lib-test --lib std --target commonJS,erlang` green on
      every landed module (`zig build test-libs` would run all libs;
      pre-existing red on jhonstart/onze/rakun erlang stayed unchanged
      by this task, per the `project_v0beta9_tail` memory note).
- [x] `wat-gate`: `path`, `querystring`, `asserts` are pure botopink and
      compile without host bindings — wat-safe by construction.
      (`std-unsupported-on-target` enforcement at type-check time is
      gated on F6 below, deferred.)
- [x] Every touched `AGENTS.md` updated in the same commit as the code.
- [x] Commit message convention: `feat(std/<name>): wave <N> module
      surface`; English; no `--no-verify` used at any point.

## Per-memory reminders

- SSH for all git remote ops (`feedback_always_ssh_git`).
- Worktree paths for Read/Edit (`project_worktree_workflow`); this
  worktree is at `.tasks/std-expansion/`.
- Functions in camelCase (`feedback_camelcase_naming`); module names
  lowercase singular (`math`, not `Math`).
- Implement in `.bp` when possible (`feedback_prefer_bp_over_dbp`);
  `.d.bp` only when 100% host-backed with no pure-botopink helpers.
- After each commit, advance to the next checkbox
  (`feedback_continue_after_commit`).
- Every new `.bp` carries a `////` header citing the Node + Erlang URLs
  for the module (per spec §"Module inventory").
