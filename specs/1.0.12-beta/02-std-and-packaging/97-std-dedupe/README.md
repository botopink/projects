# Front 97 — std dedupe: one place for every shared primitive

**Priority:** high — every library front's "consume std X" step is written against the surface this
front lands · **State:** partial: steps 0–5, 8–10 on feat; the residue of steps 1, 2 and 4, step 6
(conditional), 11 and 12 open; step 7 → 20-snap
**Depends on:** `std-d` (step 6) · `24-g` confirmed (step 5's surface) ·
decision 230 (step 11) · decisions 259, 260, 262, 263 (step 12)
**Owns:** `repository/botopink-lang/libs/std/src/**`, `libs/std/AGENTS.md`, `libs/std/test/**` ·
the bundled libraries' consumer edits: `libs/actions/src/{envelope,rpc}.bp`,
`libs/validation/src/binding.bp` · `libs/AGENTS.md` · `docs.md` § std where it lists the surface
**Does not touch:** `repository/botopink-lang/modules/**` (the compiler — a new method on a primitive
is declared in `libs/std/src/primitives.bp`; if a backend needs a lowering the front stops and
reports it) · `libs/routing/**`, `libs/validation/src/schemas.bp` (`03-bundled-libs`) · any file under
`repository/{rakun,jhonstart,emilia,onze,erika}` — the copies there are deleted by the front that
owns the file (§ Consumers) · `.gitignore`, the hooks · `01-compiler/05-wasm` step 5 is the wasm half
of step 12's decisions and also touches std's wasm bodies (`fn:…Body`) — the two are sequenced,
never run together

## Goal

Every primitive two libraries need lives once, in std — `.bp` only, both targets, a
`#[@External.<Target>]` template where a host is needed, no sidecar (decisions 115/116). A method
where the receiver is a primitive (`"42".parseInt()`), a method on the type where one exists
(`Json`), a free function in the module that owns the concept otherwise. Each library copy is then
deleted by the front that owns its file.

## Done

- Step 0 — `fs.walk` answers the same relative paths however the root is spelled; a dangling link
  is an `Error` naming it; `fs.glob` reads one rule on both targets (decisions 177, 178)
- Step 1 — `string.parseInt()` / `parseFloat()` (decision 176); erlang `indexOf` / `lastIndexOf` in
  code points (decisions 169, 197); `libs/validation`'s `i64` binder on `parseInt`
- Step 2 — the `Json` accessors as methods (`kindName`, `isObject`, `members`, `field`, `str`,
  `items`); `libs/actions` calls them
- Step 3 — `hash.pbkdf2Sha256` (decision 175) and `clock.parseDuration`
- Step 4 — the snapshot engine on `io/fs` and `path`; `fs.removeTree` public
- Step 5 — `async.RetryPolicy` / `nextDelay` / `retry` (decisions 170, 197)
- Steps 3 and 5, the rakun rows — the copies are `04-rakun/README.md` § Hygiene items RX-10 · RX-11 · RX-12
- Step 8 — the surface documented in `libs/std/AGENTS.md`, `docs.md` and `libs/AGENTS.md`
- Step 9 — `Dict.ofEntries` (decision 174)
- Step 10 — std's own residue: `Array.join` without `$stringify`, `Array.unique` keeps first
  occurrences, `random.bool` dropped (decisions 239, 217, 250)

Facts the open rows rely on: `parseInt` answers `i64` and refuses beyond ±(2^53 − 1); on wasm a call
to a template-only `String` method traps. `parseDuration` reads one unit (`ms`, `s`, `m`, `h`, `d`),
digits only, no sign — not rakun's ISO `PT…` form nor a bare number under a default unit, which
`config.parseDuration(raw, unit, key)` keeps while calling std for the suffix form. A consumer's free
`kindName(v: Json)` / `isObject` keeps compiling beside the methods, so each copy goes at its owner's
pace. `import {testing.snapshots}` is refused on wasm (STD-001 through `io/fs`).

## Open

### Step 1 residue — `bindInt`'s `i32`

- [ ] `libs/validation/src/binding.bp`'s `bindInt` reads its `i32` through std — std has no `i64` →
      `i32` narrowing, so `parseI32` (a digit fold that does not check the `i32` range) stays until
      one exists

### Step 2 residue — no `Json` accessor copy left in `libs/`

- [ ] `grep -rn "fn membersOf\|fn strOf\|fn itemsOf\|fn fieldOf\|fn kindName" libs/` finds only
      `libs/routing/src/segment.bp`'s `pub fn kindName(k: SegmentKind)` (another function over
      another type) — today it also finds `libs/validation/src/schemas.bp`'s private `itemsOf` /
      `membersOf` and `pub fn fieldOf(input, name) -> Json`, which `#[schema]`'s emitted code
      calls; `125-validation-zod` owns the file (its step 2 residue)

### Step 4 residue — the engine under every `-test` member

- [ ] `zig build test-libs` reads every member's row at its previous count (the engine is what every
      `-test` member stands on)

### Step 6 — conditional on `std-d`: `io.process` signals and a line reader

Under (a): `process.onSignal`, `process.forwardSignals(child)`, `io.stdin.readLine()`. Under (b) —
the recommendation — onze 50's boxes take their (b) shape.

- [ ] under (a): a spawned child receives the `SIGTERM` sent to its parent, asserted on both
      targets with a child that prints on the signal; `readLine` answers a line without its newline
- [ ] under (b): `libs/std/AGENTS.md` states that std has no signal or TTY surface and why

### Step 7 — std's snapshot map

→ 20-snap (front 135) step 1

### Step 11 — std on wasm, group 3 (decision 230)

The std modules whose wasm build is not a compiler question (groups 1 and 2 are
`01-compiler/05-wasm` step 5): `io/http` (`fetch`), `async` (`gateHandle`), `testing/mocks`
(`pushMatcher`), `testing/asserts` (`canonical`, decision 146). For each module, one of (a) out of
a wasm build — the manifest or the module refuses wasm with a located message, as today, recorded as
the design; or (b) restructured so no host cell is reachable on wasm.

- [ ] a question per module in [`../../decisions-pending.md`](../../decisions-pending.md) before it
      is done
- [ ] each of the four modules either refuses wasm with a located message, recorded in
      `libs/std/AGENTS.md` as the design, or builds on wasm with no host cell reachable

### Step 12 — the std bodies `01-compiler/05-wasm` step 5 waits on (decisions 259, 260, 262, 263)

The std half of 05-wasm step 5; the wasm lowering, the cells and the heap growth (decision 261) are
05-wasm's. Not started on feat: `String.fromCodepoint` is not in `primitives.bp`, `math.pow` is
still the double-double `powBody`, `contentHash`'s Node template folds UTF-16 units, the
transcendental functions bind `math:*` on erlang and beam.

- [ ] `String.fromCodepoint(cp: i32) -> string` in `primitives.bp` — Node `String.fromCodePoint`,
      erlang `<<Cp/utf8>>`, wasm a prelude helper (05-wasm); `unicode.fromCodepoint` a `fn:` over it;
      `unicode`, `json`, `encoding` and `querystring` build text with it (decision 262)
- [ ] `math.pow` is std's private botopink port of glibc's `pow` (the algorithm since glibc 2.28,
      its 128-entry `log` and `exp` tables) on every target, commonJS included:
      `math.pow(158.42161580281933, 2.853827476501465)` is `1896229.4525711867` everywhere
      (decisions 259, 263)
- [ ] `hash.contentHash` folds code points on every target: `contentHash("🎉")` is
      `djb2([127881])`; the Node template folds `Array.from(s)` (decision 260); emilia's fixture
      `e_39b87d03` (ASCII) unchanged
- [ ] `std/math`'s transcendental functions call std's private botopink bodies on erlang and beam
      too (`#[@External.Erlang("fn:tanBody")]` / `Beam`, which needs decision 238's `fn:` on those
      bindings); `sqrt`, `floor`, `abs` and the other operations IEEE 754 makes exact stay host
      calls (decision 263)

## Consumers — "consume std X" rows handed to the library fronts

Not this front's files. Each row is a step of the named front; the deletion is measured by the grep.

| Copy | Owner front | Step | Measured by |
|---|---|---|---|
| `emilia.bp` `hashHex` | `06-emilia/34-emilia-modifiers` step 1 | `import {hash} from "std"`, `hash.contentHash`, fixture `e_39b87d03` unchanged | `grep -n hashHex repository/emilia/modules/emilia/src` empty |
| `onze/src/config.bp` (`pub` accessors) | `07-onze/49-onze-stand-up` step 1 | receiver swap; the `pub` copies deleted (no consumer outside `onze`) | `grep -rn "fn membersOf\|fn strOf\|fn isObject\|fn kindName" repository/onze/modules/onze/src` empty |
| `onze-cli/src/{build,info}.bp`, `onze-bundler/src/entry.bp` (accessors and its `parseInt`) | `07-onze/50-onze-cli` step 1 | receiver swap | the same grep over `onze-cli/src` and `onze-bundler/src` empty |
| `onze-og/src/svg.bp`, `metrics.bp` number parsers | `07-onze/51-onze-image` step 1 | `parseInt` / `parseFloat` | `grep -n "fn parse" repository/onze/modules/onze-og/src` empty |
| `libs/validation/src/schemas.bp` `itemsOf`, `membersOf`, `pub fn fieldOf` | `03-bundled-libs/125-validation-zod` (step 2 residue) | receiver swap (`input.items()`, `input.members()`); `#[schema]`'s emitted `schemas.fieldOf(input, "…")` becomes `input.field("…") ?? Json.Null` or keeps a function under a name the grep does not match | `grep -n "fn itemsOf\|fn membersOf\|fn fieldOf" libs/validation/src` empty |
| rakun's copies (below) | the `04-rakun` track's fronts, by file | one row each | the `04-rakun` track's greps |

rakun's copies, by primitive: number parsers answering a `@Result` (e.g.
`rakun-metrics/src/registry.bp`, `rakun-scheduling/src/cron.bp`, `rakun/src/config.bp`) →
`parseInt` / `parseFloat`; `Json` accessors in `rakun-security/src/jwt.bp` and
`rakun/src/autoconfig_registry.bp` → the `Json` methods; the four retry loops → `async.retry`;
`config.parseDuration`, `jwt.skewOf` → `clock.parseDuration`; `rakun_security.erl`'s `pbkdf2` →
`hash.pbkdf2Sha256` (its salt changes from base64url-decoded to text, decision 175); constant-time
equality (`request_context.bp`), `sha256` (`rakun-ws/src/ws.bp`), `xmlEscape` (`config.bp`),
`cron.rkFormatUtc`, `rakun-logging`'s `rkLogIso` → `hash.equalsConstantTime`, `hash.sha256`,
`escape.attribute`, `clock.formatIso8601`. `rakun-messaging/reliability/policy.bp` declares its own
`RetryPolicy` / `nextDelay` until its step (decision 170).

## Compiler residuals — met here, worked around in std, owned elsewhere

| # | What | Reproduction | Owner |
|---|---|---|---|
| 1 | commonJS emits `Ok(x)` / `Error(e)` of a `default fn` of `primitives.bp` as written — `ReferenceError: Ok is not defined` | `return Ok(1);` in a new `default fn` of `behavior String`, called from a scratch project | the commonJS emitter |
| 2 | in such a body commonJS emits `self.length()` as written (`self.length is not a function`) and erlang emits `opt.unwrapOr(d)` as a call to an undefined `unwrapOr/2` | `val x = self.split(".").at(0).unwrapOr("");` / `self.length()` in the same place | both emitters |
| 3 | erlang lowers a method called on a LOCAL of such a body through a lookup another module's text changes: `exponent.startsWith("+")` came out as the bare `startsWith(Exponent, <<"+">>)` — `function startsWith/2 undefined` | `parseFloat`'s body as first landed, with the three code-point index tests appended to `test/primitives_test.bp` | the erlang emitter |
| 4 | a TYPE a module imports from a sibling (`import {RetryPolicy} from "reliability/policy"`) resolves to std's type of the same name when the same module also imports the std module that declares it (`import {async} from "std"`): `` `RetryPolicy` has no parameter named `initialMs` `` | a dependency with `reliability/policy.bp` (`pub type RetryPolicy(initialMs: i32, …)`) and `reliability/dispatch.bp` importing it beside `{async}` | `01-compiler/01-checker` (the import fix covers functions) |
| 5 | a record cannot be built through a std module namespace: `async.RetryPolicy(3, 100, 2.0, 1000)` is `this "std" module has no such public function`; the leaf import works | `import {async} from "std";` and that call | `01-compiler/01-checker` |
| 6 | a consumer outside the checkout cannot import `io/random` on commonJS: `module 'std/io/random' requires "./sidecars/random.mjs", but its library 'std' resolves to no package directory` | `import {io.random} from "std"` in a package under `/tmp` | **unowned** — no front of this track carries it; proposed `01-compiler/26-cli-tooling` (the CLI's bundled-package resolution) |
| 7 | `nextDelay(policy, 1).unwrapOr(0)` is `type mismatch: expected i32, got i64` — a literal widens to `i64` as an argument and as a field, not as `unwrapOr`'s default | that expression | `01-compiler/01-checker` |
| 8 | on erlang `[[1, 2], [3]].join("+")` prints the bytes `\x01\x02+\x03` (a list element is taken as an iolist) where beam prints `[1,2]+[3]` | that expression | `01-compiler/02-erlang` (`primJoin`'s template) |

Residual 4 breaks nothing today (no rakun module that names `RetryPolicy` imports `std/async`); it is
what a rakun step meets if it imports both before deleting its copy.

## Notes

- No jitter, no `retry` over a plain `@Task` (a Task never fails, decision 120), no `RetryPolicy`
  field a consumer could set to "unbounded" — the most restrictive shape (decision 67).
- The argv flag parser (rakun `rakun-cli/src/args.bp`, `config.cliEntries`,
  `onze-cli/src/create.bp`) is **not** added: three consumers, three grammars; a std `cli` module is
  a question for a later milestone once the grammars agree.

**Gate:** standard (fronts.md § Gate) + `botopink test` and `botopink test --target erlang` green in
`libs/std`, `libs/actions`, `libs/validation`
- [ ] the landing of steps 0–5, 8–10 merged before this gate was recorded: one cold `zig build
      test` and a full `zig build test-libs` on feat with this front's steps in, recorded here
