# Front 97 — std dedupe: one place for every shared primitive

**Priority:** high — every library's "consume std X" step is written against this surface ·
**State:** partial: steps 0–5, 8–10, 12 on feat; residue of steps 1, 2, 4, step 6 (conditional), 11
open (its questions: `97-a`, `97-b` → 334, 335; `97-c` → 335; `110-a` open), 13–15, 17 open; step 7 → 20-snap
**Depends on:** `std-d` (step 6) · `24-g` confirmed (step 5) · decision 230 (step 11) · decision
262 (step 12)
**Owns:** `repository/botopink-lang/libs/std/src/**`, `libs/std/AGENTS.md`, `libs/std/test/**` ·
consumer edits `libs/actions/src/{envelope,rpc}.bp`, `libs/validation/src/binding.bp` ·
`libs/AGENTS.md` · `docs.md` § std where it lists the surface
**Does not touch:** `repository/botopink-lang/modules/**` (a new primitive method is declared in
`libs/std/src/primitives.bp`; a needed backend lowering → stop and report) · `libs/routing/**`,
`libs/validation/src/schemas.bp` (`03-bundled-libs`) · `repository/{rakun,jhonstart,emilia,onze,erika}`
(copies deleted by the file's owner, § Consumers) · `.gitignore`, the hooks · `01-compiler/05-wasm`
step 5 (wasm half of step 12, also touches std's wasm bodies `fn:…Body`) — sequenced, never together

## Goal

Every primitive two libraries need lives once in std — `.bp` only, both targets,
`#[@External.<Target>]` template where a host is needed, no sidecar (decisions 115/116). Method on a
primitive receiver (`"42".parseInt()`), method on the type where one exists (`Json`), else a free
function in the concept's module. Each library copy deleted by its file's front.

## Done

- Step 0 — `fs.walk` same relative paths however the root is spelled; dangling link → `Error`
  naming it; `fs.glob` one rule on both targets (decisions 177, 178)
- Step 1 — `string.parseInt()` / `parseFloat()` (decision 176); erlang `indexOf` / `lastIndexOf` in
  code points (decisions 169, 197); `libs/validation`'s `i64` binder on `parseInt`
- Step 2 — `Json` accessor methods (`kindName`, `isObject`, `members`, `field`, `str`, `items`);
  `libs/actions` calls them
- Step 3 — `hash.pbkdf2Sha256` (decision 175), `clock.parseDuration`
- Step 4 — snapshot engine on `io/fs` and `path`; `fs.removeTree` public
- Step 5 — `async.RetryPolicy` / `nextDelay` / `retry` (decisions 170, 197)
- Steps 3, 5 rakun rows — `04-rakun/README.md` § Hygiene RX-10 · RX-11 · RX-12
- Step 8 — surface documented in `libs/std/AGENTS.md`, `docs.md`, `libs/AGENTS.md`
- Step 9 — `Dict.ofEntries` (decision 174)
- Step 10 — `Array.join` without `$stringify`, `Array.unique` keeps first occurrences, `random.bool`
  dropped (decisions 239, 217, 250)
- Step 12 — `String.fromCodepoint(cp: i32)` in `primitives.bp` (Node `String.fromCodePoint` behind a
  scalar-value check, erlang `<<Cp/utf8>>`), `json` / `encoding` build text with it; `math.pow` is
  `powBody`, glibc's `pow` ported, on four targets (`pow(158.42161580281933, 2.853827476501465)` row
  of `run/std_math_on_every_target`); transcendentals `fn:` bodies on erlang and beam, exact ops
  host calls (decisions 259, 262, 263 — `d71b89f5`, `a443f52d`); `contentHash` folds code points
  on every target (`Array.from(s)`, `hash.contentHash folds a code point above U+FFFF once`; decision
  260 — `d71b89f5`); `unicode.fromCodepoint` a `fn:` body over `String.fromCodepoint` on all four
  targets (`unicode.fromCodepoint of a code point above U+FFFF is one code point`)
- Step 3 — `clock.parseDuration` compares the count with `(2^53 − 1) / unit` before multiplying, so
  `"104249992d"` is the `out of range` `Error` on commonJS too (the product aborted there once an
  `i64` overflow aborts on every target)
- Step 16 — `unicode.normalize` (NFC, NFD, NFKC, NFKD) is std's botopink body on the four targets
  (decision 333 (A)): decompose recursively, canonical order by combining class, recompose (blocked
  and excluded pairs), Hangul by the algorithm; the Node and Erlang templates are gone. Its tables,
  `libs/std/src/unicode_tables.bp` (generated, never edited; a flat private `mod` — question
  `97-s16-a`), are written by `libs/std/tools/unicode-gen/main.zig` through `zig build gen-unicode`
  (one line of root `build.zig`, a carve-out of 26) from Unicode 17.0.0's `UnicodeData.txt`,
  `CompositionExclusions.txt` and `DerivedNormalizationProps.txt`, vendored beside it with their
  SHA-256 in `manifest.json`; the derived exclusions are checked equal to
  `Full_Composition_Exclusion`. `test/unicode_test.bp` checks every line of the six parts of the
  vendored `NormalizationTest.txt` (green on commonJS, erlang and beam); `run/std_unicode_on_every_target`
  one `.out` for the four targets, its `.wasm.expect` deleted; the bump procedure in
  `libs/std/AGENTS.md` § unicode
- Step 11 box 1 — a question per module: `97-a` (`io/http`) and `97-b` (`async`) → 334, 335, `97-c` → 335
  (`testing/mocks`), `110-a` (`testing/asserts`)

Facts the open rows rely on:
- `parseInt` answers `i64`, refuses beyond ±(2^53 − 1); on wasm a template-only `String` method traps.
- `parseDuration`: one unit (`ms`, `s`, `m`, `h`, `d`), digits only, no sign — not rakun's ISO `PT…`
  nor a bare number under a default unit; `config.parseDuration(raw, unit, key)` keeps those, calling
  std for the suffix form.
- A consumer's free `kindName(v: Json)` / `isObject` compiles beside the methods (each copy goes at
  its owner's pace).
- `import {testing.snapshots}` refused on wasm (STD-001 through `io/fs`).

## Open

### Step 1 residue — `bindInt`'s `i32`

- [ ] `libs/validation/src/binding.bp`'s `bindInt` reads its `i32` through std — no `i64` → `i32`
      narrowing in std, so `parseI32` (digit fold, no `i32` range check) stays until one exists

### Step 2 residue — no `Json` accessor copy left in `libs/`

- [ ] `grep -rn "fn membersOf\|fn strOf\|fn itemsOf\|fn fieldOf\|fn kindName" libs/` finds only
      `libs/routing/src/segment.bp`'s `pub fn kindName(k: SegmentKind)` — today also
      `libs/validation/src/schemas.bp`'s private `itemsOf` / `membersOf` and
      `pub fn fieldOf(input, name) -> Json` (called by `#[schema]`'s emitted code — `#[validated]`'s after
      306); owner
      `125-validation-zod` step 2 residue

### Step 4 residue — the engine under every `-test` member

- [ ] `zig build test-libs` reads every member's row at its previous count

### Step 6 — conditional on `std-d`: `io.process` signals and a line reader

(a): `process.onSignal`, `process.forwardSignals(child)`, `io.stdin.readLine()`. (b), recommended:
onze 50's boxes take their (b) shape.

- [ ] under (a): a spawned child receives the `SIGTERM` sent to its parent, asserted on both
      targets with a child that prints on the signal; `readLine` answers a line without its newline
- [ ] under (b): `libs/std/AGENTS.md` states std has no signal or TTY surface and why

### Step 7 — std's snapshot map

→ 20-snap (front 135) step 1

### Step 11 — std on wasm, group 3 (decision 230)

Modules whose wasm build is not a compiler question (groups 1, 2 are `01-compiler/05-wasm` step 5):
`io/http` (`fetch`), `async` (`gateHandle`), `testing/mocks` (`pushMatcher`), `testing/asserts`
(`canonical`, decision 146). Per module: (a) out of a wasm build — manifest or module refuses wasm
with a located message, recorded as the design; or (b) restructured so no host cell is reachable.

- [ ] `io/http` and `async` build on wasm through step 17 (334, 335); `testing/mocks` keeps its located refusal on wasm
      until `botopink test` runs the wasm column, then its registry moves to the module's memory (335 (3)); `testing/asserts` per
      `110-a` — each refusing module refuses with a located message, recorded in `libs/std/AGENTS.md` as the design

### Step 13 — std over the hybrid `i64` on commonJS (decision 319; with `04-js` step 9)

- [ ] every Node template of std taking or answering an `i64` (`io/clock.bp`'s `systemTimeWithUnit`,
      `monotonicTimeWithUnit`, `largestExactMillis`, `wide`; `io/fs.bp`'s `size` / `mtime`; the rest found
      by grep) passes and answers `number | bigint` in 319's canonical form
- [ ] `Json`: an `i64` written as its digits (the read half is step 15's `Int` node, 332)
      (`9223372036854775807l` round-trips on commonJS through `Int`)
- [ ] `string.parseInt()` answers `Error` only past the `i64` range (176 as amended by 319); its cells on
      the four targets
- [ ] `Math.min` / `max` / `abs` and `Integer`'s `default fn`s (`isEven`, `clamp`) answer past 2^53 on
      commonJS — today they throw a `TypeError` on a `BigInt` (from `04-js` step 9); one cell each across
      the 2^53 edge
- [ ] the explicit conversions 319 names (`toF64()`, `toI32()`, …) declared in std — none is declared
      anywhere; `04-js` step 9's conversions box waits on this surface

### Step 14 — erlang counts codepoints, not grapheme clusters (decision 320)

`primitives.bp`'s Erlang templates for `length`, `at`, `slice`, `indexOf`, `lastIndexOf` call
`string:length/1` / `string:slice/3`, which count grapheme clusters: `"e\u{301}".length` is 1 on erlang
and beam, 2 on wasm.

- [x] the five templates count codepoints (`unicode:characters_to_list/1`, re-encoded with
      `unicode:characters_to_binary/1`; the slice helpers normalise bounds as the Node forms do), on
      erlang and beam; `02-erlang` step 15's cell green there; `libs/std/AGENTS.md` § One unit
- [ ] std's Node templates for the five take and answer codepoint indices (`04-js` step 10's helpers)
- [ ] `docs.md` § Strings states the unit — codepoints on every target — handed to `07-residuals` (the prose)

### Step 15 — `Decimal` and `Json`'s numbers as Jackson reads them (decision 332; after `01-compiler/139`)

- [ ] `Decimal` in std (`math/decimal.bp` or the module the front names): an unscaled `bigint` and a
      `scale`; `add`, `sub`, `mul` exact; `div(b, scale:, rounding:)` with `Rounding { Up, Down, Ceiling,
      Floor, HalfUp, HalfDown, HalfEven, Unnecessary }` (Java's `RoundingMode`; `Unnecessary` aborts when
      rounding is needed); `compare`; `==` by numeric value (`1.0 == 1.00`); `toString()` plain with its
      scale (`"1.00"`, never `1E+2`); `parse(text) -> @Result<Decimal, string>`
- [ ] `Json`: `Num(value: f64)` replaced by `Int(value: i64)`, `BigInt(value: bigint)`, `Dec(value: Decimal)`,
      chosen by the numeral; readers `num() -> ?f64`, `i64() -> ?i64`, `bigint() -> ?bigint`,
      `decimal() -> ?Decimal`, `isNumber()`, `isIntegral()` (exact or `null`, never coerced); `encode` writes
      the digits and the plain decimal text; std's tests `decodesTo("9007199254740993", Int(value: 9007199254740993))`
- [ ] `json.parse` and `json.stringify` deleted with their Node / Erlang templates (336); their one caller (`tests/language/run/std_json_on_every_target.bp`)
      rewritten to `decode` / `encode`; `json` compiles on wasm under both hosts with no host cell
- [ ] the 13 files with a `case` over `Json` (std 6, rakun 3, jhonstart 2, onze 2) gain the arms, one commit per
      repository; `run/json_numbers_exact` one `.out` for the four targets

### Step 17 — `io/http` and `async` bound to the `wasi` host (decision 334; after `01-compiler/140` steps 1–4)

- [ ] `io/http`'s `fetch` binds `@External.Wasm(host: .Wasi, wasi: .HttpOutgoing)` and the `browser` host's JS `fetch`;
      the request and response mapped by each adapter; on `browser` a forbidden header or a `Set-Cookie` read answers
      `HttpError.NotAllowedOnHost(…)` naming it (335 (1)); `run/std_io_http_on_every_target` against a local double
- [ ] `async`'s twelve cells bind on `wasi` (`delay` on the monotonic clock, `race` / `raceOf` on pollables, the
      gate cells as pollables) and on `browser` (JSPI promises); `RetryPolicy` / `nextDelay` unchanged;
      `run/std_async_on_every_target` asserts results and answer order only — never effect interleaving (335 (2))
- [ ] the `browser` bindings of both modules in the same commit (334: a cell bound on both hosts or neither)

## Consumers — "consume std X" rows handed to the library fronts

Each row is a step of the named front; deletion measured by the grep.

| Copy | Owner front | Step | Measured by |
|---|---|---|---|
| `emilia.bp` `hashHex` | `06-emilia/34-emilia-modifiers` step 1 | `import {hash} from "std"`, `hash.contentHash`, fixture `e_39b87d03` unchanged | `grep -n hashHex repository/emilia/modules/emilia/src` empty |
| `onze/src/config.bp` (`pub` accessors) | `07-onze/49-onze-stand-up` step 1 | receiver swap; `pub` copies deleted (no consumer outside `onze`) | `grep -rn "fn membersOf\|fn strOf\|fn isObject\|fn kindName" repository/onze/modules/onze/src` empty |
| `onze-cli/src/{build,info}.bp`, `onze-bundler/src/entry.bp` (accessors, its `parseInt`) | `07-onze/50-onze-cli` step 1 | receiver swap | same grep over `onze-cli/src`, `onze-bundler/src` empty |
| `onze-og/src/svg.bp`, `metrics.bp` number parsers | `07-onze/51-onze-image` step 1 | `parseInt` / `parseFloat` | `grep -n "fn parse" repository/onze/modules/onze-og/src` empty |
| `libs/validation/src/schemas.bp` `itemsOf`, `membersOf`, `pub fn fieldOf` | `03-bundled-libs/125-validation-zod` (step 2 residue) | receiver swap (`input.items()`, `input.members()`); emitted `schemas.fieldOf(input, "…")` → `input.field("…") ?? Json.Null` or a function the grep does not match | `grep -n "fn itemsOf\|fn membersOf\|fn fieldOf" libs/validation/src` empty |
| rakun's copies (below) | `04-rakun` fronts, by file | one row each | `04-rakun`'s greps |

rakun's copies, by primitive:
- number parsers answering a `@Result` (e.g. `rakun-metrics/src/registry.bp`,
  `rakun-scheduling/src/cron.bp`, `rakun/src/config.bp`) → `parseInt` / `parseFloat`
- `Json` accessors in `rakun-security/src/jwt.bp`, `rakun/src/autoconfig_registry.bp` → `Json` methods
- the four retry loops → `async.retry`
- `config.parseDuration`, `jwt.skewOf` → `clock.parseDuration`
- `rakun_security.erl`'s `pbkdf2` → `hash.pbkdf2Sha256` (salt changes from base64url-decoded to text,
  decision 175)
- constant-time equality (`request_context.bp`), `sha256` (`rakun-ws/src/ws.bp`), `xmlEscape`
  (`config.bp`), `cron.rkFormatUtc`, `rakun-logging`'s `rkLogIso` → `hash.equalsConstantTime`,
  `hash.sha256`, `escape.attribute`, `clock.formatIso8601`
- `rakun-messaging/reliability/policy.bp` keeps its own `RetryPolicy` / `nextDelay` until its step
  (decision 170)

## Compiler residuals — met here, worked around in std, owned elsewhere

| # | What | Reproduction | Owner |
|---|---|---|---|
| 1 | commonJS emits `Ok(x)` / `Error(e)` of a `primitives.bp` `default fn` as written — `ReferenceError: Ok is not defined` | `return Ok(1);` in a new `default fn` of `behavior String`, called from a scratch project (`Ok`/`Error` are never constructors, 208/303: re-measure with `return 1;` / `throw e`) | commonJS emitter |
| 2 | same body: commonJS emits `self.length()` as written (`self.length is not a function`); erlang emits `opt.unwrapOr(d)` as undefined `unwrapOr/2` | `val x = self.split(".").at(0).unwrapOr("");` / `self.length()` there | both emitters |
| 3 | erlang lowers a method on a LOCAL of such a body through a lookup another module's text changes: `exponent.startsWith("+")` → bare `startsWith(Exponent, <<"+">>)`, `function startsWith/2 undefined` | `parseFloat`'s first body + the three code-point index tests appended to `test/primitives_test.bp` | erlang emitter |
| 4 | a TYPE imported from a sibling (`import {RetryPolicy} from "reliability/policy"`) resolves to std's same-named type when the module also imports the std module declaring it (`import {async} from "std"`): `` `RetryPolicy` has no parameter named `initialMs` `` | dependency with `reliability/policy.bp` (`pub type RetryPolicy(initialMs: i32, …)`) and `reliability/dispatch.bp` importing it beside `{async}` | `01-compiler/01-checker` (import fix covers functions) |
| 5 | no record built through a std namespace: `async.RetryPolicy(3, 100, 2.0, 1000)` is `this "std" module has no such public function`; leaf import works | `import {async} from "std";` + that call | `01-compiler/01-checker` |
| 6 | consumer outside the checkout cannot import `io/random` on commonJS: `module 'std/io/random' requires "./sidecars/random.mjs", but its library 'std' resolves to no package directory` | `import {io.random} from "std"` in a package under `/tmp` | **unowned**; proposed `01-compiler/26-cli-tooling` (bundled-package resolution) |
| 7 | `nextDelay(policy, 1).unwrapOr(0)` is `type mismatch: expected i32, got i64` — a literal widens to `i64` as argument and field, not as `unwrapOr`'s default | that expression | `01-compiler/01-checker` |
| 8 | erlang `[[1, 2], [3]].join("+")` prints bytes `\x01\x02+\x03` (element taken as iolist); beam prints `[1,2]+[3]` | that expression | `01-compiler/02-erlang` (`primJoin`'s template) |
| 9 | an embedded std file's reserved-word error is unlocated | a reserved word used as a name in a `libs/std/src` file | `01-compiler/01-checker` |
| 10 | beam lowers an or-pattern of enum variants to no test: `case f { C \| D -> true; _ -> false }` answers `false` for `C` on beam, `true` on the other three (`unicode.normalize` writes one arm per form) | `type Form { A, B, C, D }` and that `case` over `Form.C` | `01-compiler/03-beam` |
| 11 | the embedded std registry carries no module visibility: `mod unicode_tables;` (private in `root.bp`) is importable by a consumer, `import {unicode_tables} from "std"` | that import from a scratch package | `01-compiler/26-cli-tooling` (`build.zig`'s registry) |

Residual 4 breaks nothing today (no rakun module naming `RetryPolicy` imports `std/async`); a rakun
step meets it if it imports both before deleting its copy.

## Notes

- No jitter, no `retry` over a plain `@Task` (never fails, decision 120), no "unbounded"
  `RetryPolicy` field — most restrictive (decision 67).
- No std argv flag parser (rakun `rakun-cli/src/args.bp`, `config.cliEntries`,
  `onze-cli/src/create.bp`): three consumers, three grammars; a std `cli` module waits until they agree.

**Gate:** standard (fronts.md § Gate) + `botopink test` and `botopink test --target erlang` green in
`libs/std`, `libs/actions`, `libs/validation`
- [ ] steps 0–5, 8–10 landed before this gate was recorded: one cold `zig build test` and a full
      `zig build test-libs` on feat with them in, recorded here
