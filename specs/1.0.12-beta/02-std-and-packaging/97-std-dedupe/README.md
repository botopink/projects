# Front 97 — std dedupe: one place for every shared primitive

**Priority:** high — every library's "consume std X" step is written against this surface ·
**State:** partial: steps 0–5, 8–10 on feat; residue of steps 1, 2, 4, step 6 (conditional), 11, 12
open; step 7 → 20-snap
**Depends on:** `std-d` (step 6) · `24-g` confirmed (step 5) · decision 230 (step 11) · decisions
259, 260, 262, 263 (step 12)
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
      `pub fn fieldOf(input, name) -> Json` (called by `#[schema]`'s emitted code); owner
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

- [ ] a question per module in [`../../decisions-pending.md`](../../decisions-pending.md) before it
      is done
- [ ] each of the four modules refuses wasm with a located message (recorded in `libs/std/AGENTS.md`
      as the design) or builds on wasm with no host cell reachable

### Step 12 — the std bodies `01-compiler/05-wasm` step 5 waits on (decisions 259, 260, 262, 263)

Std half of 05-wasm step 5 (lowering, cells, heap growth — decision 261 — are 05-wasm's). Not on
feat: no `String.fromCodepoint` in `primitives.bp`; `math.pow` still double-double `powBody`;
`contentHash`'s Node template folds UTF-16 units; transcendentals bind `math:*` on erlang and beam.

- [ ] `String.fromCodepoint(cp: i32) -> string` in `primitives.bp` — Node `String.fromCodePoint`,
      erlang `<<Cp/utf8>>`, wasm a prelude helper (05-wasm); `unicode.fromCodepoint` a `fn:` over it;
      `unicode`, `json`, `encoding`, `querystring` build text with it (decision 262)
- [ ] `math.pow` is std's private botopink port of glibc's `pow` (algorithm since glibc 2.28, its
      128-entry `log` and `exp` tables) on every target, commonJS included:
      `math.pow(158.42161580281933, 2.853827476501465)` is `1896229.4525711867` everywhere
      (decisions 259, 263)
- [ ] `hash.contentHash` folds code points on every target: `contentHash("🎉")` is
      `djb2([127881])`; Node template folds `Array.from(s)` (decision 260); emilia's fixture
      `e_39b87d03` (ASCII) unchanged
- [ ] `std/math`'s transcendentals call std's private botopink bodies on erlang and beam too
      (`#[@External.Erlang("fn:tanBody")]` / `Beam`, needs decision 238's `fn:` there); `sqrt`,
      `floor`, `abs` and other IEEE-754-exact operations stay host calls (decision 263)

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
| 1 | commonJS emits `Ok(x)` / `Error(e)` of a `primitives.bp` `default fn` as written — `ReferenceError: Ok is not defined` | `return Ok(1);` in a new `default fn` of `behavior String`, called from a scratch project | commonJS emitter |
| 2 | same body: commonJS emits `self.length()` as written (`self.length is not a function`); erlang emits `opt.unwrapOr(d)` as undefined `unwrapOr/2` | `val x = self.split(".").at(0).unwrapOr("");` / `self.length()` there | both emitters |
| 3 | erlang lowers a method on a LOCAL of such a body through a lookup another module's text changes: `exponent.startsWith("+")` → bare `startsWith(Exponent, <<"+">>)`, `function startsWith/2 undefined` | `parseFloat`'s first body + the three code-point index tests appended to `test/primitives_test.bp` | erlang emitter |
| 4 | a TYPE imported from a sibling (`import {RetryPolicy} from "reliability/policy"`) resolves to std's same-named type when the module also imports the std module declaring it (`import {async} from "std"`): `` `RetryPolicy` has no parameter named `initialMs` `` | dependency with `reliability/policy.bp` (`pub type RetryPolicy(initialMs: i32, …)`) and `reliability/dispatch.bp` importing it beside `{async}` | `01-compiler/01-checker` (import fix covers functions) |
| 5 | no record built through a std namespace: `async.RetryPolicy(3, 100, 2.0, 1000)` is `this "std" module has no such public function`; leaf import works | `import {async} from "std";` + that call | `01-compiler/01-checker` |
| 6 | consumer outside the checkout cannot import `io/random` on commonJS: `module 'std/io/random' requires "./sidecars/random.mjs", but its library 'std' resolves to no package directory` | `import {io.random} from "std"` in a package under `/tmp` | **unowned**; proposed `01-compiler/26-cli-tooling` (bundled-package resolution) |
| 7 | `nextDelay(policy, 1).unwrapOr(0)` is `type mismatch: expected i32, got i64` — a literal widens to `i64` as argument and field, not as `unwrapOr`'s default | that expression | `01-compiler/01-checker` |
| 8 | erlang `[[1, 2], [3]].join("+")` prints bytes `\x01\x02+\x03` (element taken as iolist); beam prints `[1,2]+[3]` | that expression | `01-compiler/02-erlang` (`primJoin`'s template) |

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
