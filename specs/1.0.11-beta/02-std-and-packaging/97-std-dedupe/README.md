# Front 97 — std dedupe: one place for every shared primitive

**Priority:** high — `07-bundled-libs` wave 1 (routing conventions, actions id, http) and every
library front's "consume std X" step are written against the surface this front lands; a primitive
landed after its consumers were rewritten is rewritten twice
**Depends on:** none for steps 1–5 · maintainer decision `01std-f` for step 7 · `std-d` for step 6 ·
`24-g` confirmed (step 5 builds on `std/async`'s started/unstarted surface as implemented)
**Owns:** `repository/botopink-lang/libs/std/src/{primitives,json,hash,async}.bp`,
`libs/std/src/io/{clock,fs,process}.bp`, `libs/std/src/testing/snapshots.bp`, `libs/std/AGENTS.md`,
`libs/std/test/**` and the inline tests of the files named · the bundled libraries' consumer edits:
`libs/actions/src/{envelope,rpc}.bp`, `libs/validation/src/binding.bp` · `libs/AGENTS.md` ·
`docs.md` § std where it lists the surface · `libs/std/src/__snapshots__/**` (step 7 only)
**Does not touch:** `repository/botopink-lang/modules/**` (the compiler — a new method on a primitive
is declared in `libs/std/src/primitives.bp`, whose declarations the checker reads; if a backend
needs a lowering the front stops and reports it) · `libs/routing/**` (`07-bundled-libs`) · any file
under `repository/{rakun,jhonstart,emilia,onze,erika}` — the copies there are deleted by the front
that owns the file (§ Consumers) · `scripts/restricted-targets.txt`, `.gitignore`, the hooks
(`00-gate`)
**Carried from 1.0.10:** `01-std/01-std-lib-enablement/README.md` § Step 14 (the copies are
deletable — reopened, see § Current state) · `01-std/README.md` § Step 3 (the engine's private
cells, `snapshots.bp`) · `01-std/test-snap.md` (step 7, conditional) · the *Std-level cleanup*
section of the bundled-libs extraction analysis (the source of steps 1–5)

---

## Problem

The same primitive is written in several libraries, each copy slightly different, and none is
std's. Measured on the trees at `repository/` (the extraction analysis, re-checked by `grep`):

| Primitive | Copies | Where |
|---|---|---|
| a string → integer / float parser answering a `@Result` | 21 files | `libs/validation/src/binding.bp:144`, `onze-og/src/svg.bp:19`, `onze-og/src/metrics.bp:12`, `onze-bundler/src/entry.bp`, rakun `rakun-metrics/src/registry.bp:102`, `rakun-scheduling/src/cron.bp:126`, `rakun/src/config.bp:79`, … |
| `Json` accessors `membersOf` / `isObject` / `fieldOf` / `strOf` / `itemsOf` / `kindName` | 8 | `libs/actions/src/envelope.bp:56-103`, `libs/actions/src/rpc.bp:26-66`, `onze/src/config.bp:98-130` (`pub`), `onze-cli/src/build.bp:42`, `onze-cli/src/info.bp:11`, `onze-bundler/src/entry.bp:182`, rakun `rakun-security/src/jwt.bp:117-168`, `rakun/src/autoconfig_registry.bp:164-178` |
| retry with backoff | 4 | rakun `rakun-messaging/src/reliability/policy.bp:34`, `rakun-tx/src/outbox.bp:107`, the mail sidecar, `rakun-scheduling/src/jobstore/scheduler.bp` |
| a duration parser (`"30s"`, `"5m"`) | 2 | rakun `config.parseDuration`, `jwt.skewOf` |
| PBKDF2-SHA256 | 1 host cell, no std | `rakun_security.erl` (`pbkdf2`) / Node `crypto.pbkdf2Sync` |
| an argv flag parser | 3 | rakun `rakun-cli/src/args.bp`, `config.cliEntries:568`, `onze-cli/src/create.bp:84` |
| a djb2 content hash | 1 copy of std's | emilia `emilia.bp:95-97` (`hashHex`) = `hash.contentHash` |
| constant-time equality, `sha256`, `xmlEscape`, `uuidV4`, an ISO-8601 formatter | 1 each | rakun `request_context.bp:797`, `rakun-ws/src/ws.bp:51`, `rakun/src/config.bp:1194`, `cron.rkFormatUtc`, `rakun-logging`'s `rkLogIso` — std has each already (`hash.equalsConstantTime`, `hash.sha256`, `escape.attribute`, `io.random.uuidV4`, `clock.formatIso8601`) |
| file cells inside the snapshot engine | 5 | `libs/std/src/testing/snapshots.bp:4-38` — private `readFile`, `writeFile`, `removeFile`, `exists`, `removeTree`, `tmpDir` host templates beside `io/fs.bp`'s |

## Current state

- `01-std-lib-enablement` step 14 ("no JSON copy left in jhonstart, emilia, rakun") was ticked in
  1.0.10 against a grep for the *writers*; the *readers* over `json.Json` were copied eight times
  after decision 117 introduced the type. Reopened here.
- **Landed (steps 0–2):** `fs.walk`'s relative paths on erlang, `string.parseInt()` /
  `string.parseFloat()` and the `Json` readers — `libs/std` reads 456 passed / 0 failed on commonJS
  and on erlang (433 before). The consumer edits in `libs/actions` and `libs/validation` and steps
  3, 4, 5 and 8 are not started; steps 6 and 7 wait on `std-d` and `01std-f`.
- `libs/std/src/async.bp` carries `allOf`, `all`, `race`, `runAll`, `raceOf`, `timeout`, `failed`
  (24-g's shape); no retry policy.
- `libs/std/src/hash.bp` carries `contentHash`, `strongHash`, `sha256`, the base64url digests,
  `equalsConstantTime`, `etag` / `weakEtag` / `matches`; no PBKDF2.
- `libs/std/src/io/clock.bp` carries `formatIso8601`, `toCivil`; no duration parser.
- `libs/std/src/testing/snapshots.bp` reaches the filesystem through its own six templates rather
  than `io/fs` and `path` (measured: `sed -n '1,40p'` shows the `declare fn` block).

## Mechanism

Each copy exists because the primitive was needed by a library front while std was frozen for it
(the 1.0.10 rule: a library front gets no compiler change and writes the nearest form). The rule
that replaces it is decision 115/116's: **what is generic goes to std** — `.bp` only, both targets,
a `#[@External.<Target>]` template where a host is needed, no sidecar. A std addition is a method
where the receiver is a primitive (`"42".parseInt()`), a method on the type where one exists
(`Json`), and a free function in the module that owns the concept otherwise.

## Steps

### Step 0 — `fs.walk` answers the same relative paths however the root is spelled

On erlang the template cut the root off each full path by the root's written length, while
`filelib:fold_files/5` builds those paths with `filename:join/2`, which drops a `.` segment: a root
ending in `/.` (what `path.join([dir, "."])` answers) lost the first two characters of every path
(`app/layout.bp` → `p/layout.bp`), and onze's `onze build` of a project whose `src` is `"."` read
`enoent`. The Erlang template walks `file:list_dir/1` itself and builds each relative path from the
names it descends through; the Node template reads `statSync` with `throwIfNoEntry: false` (a
dangling link made the whole walk an `ENOENT` there while erlang skipped it).

**Acceptance:**
- [x] one inline test per spelling — `dir`, `dir/`, `dir/.`, `dir/./sub`, `//dir//`, `dir/sub/..`,
      relative, relative with a leading `./` — plus links (file, directory, dangling) and a file
      root, green on commonJS and erlang
- [x] `tests/language` `run/std_fs_walk_root_spellings` from a consumer on commonJS, erlang and
      beam (wasm refuses the import); planting the old template reds it on erlang and beam only
- [x] `glob` and `list` carry no prefix arithmetic (measured: `filelib:wildcard/2` and
      `file:list_dir/1` answer relative names by construction for every spelling); `path.join`
      keeps a `.` segment and `path.normalize` drops it, on both targets alike

Left, not this front's: `fs.glob`'s MATCHING differs between the hosts — `filelib:wildcard` matches
a dot name with `*` / `**` and descends through a link to a directory, `fs.globSync` does neither
(`**/*.txt` over `.hid/h.txt`, `lnk -> sub`, `sub/s.txt`: three paths on erlang, one on commonJS);
`fs.list` answers the host's order.

### Step 1 — `string.parseInt()` and `string.parseFloat()`

Declared in `libs/std/src/primitives.bp` as methods of `string`, answering
`@Result<i64, string>` / `@Result<f64, string>`; a leading `+`/`-`, digits only, the whole
string (no trailing text, no whitespace); an `Error` names the input. Both targets through
templates (`Number` / `list_to_integer` with the refusal spelled in botopink over the digits, so the
two backends agree on every input — decision 142's rule for numerals).

**Acceptance:**
- [x] `"42".parseInt()` is `Ok(42)`, `"-0".parseInt()` is `Ok(0)`, `"4 2"`, `""`, `"42x"`, `"0x2A"`
      are `Error` naming the input — inline tests green on commonJS and erlang
- [x] `"1e3".parseFloat()` is `Ok(1000.0)` and agrees bit-for-bit with `json.decode`'s numeral on
      the boundary values it pins (`5e-324`, `1.7976931348623157e308`) — `json.bp`'s agreement test
      runs both over decision 142's whole boundary list
- [ ] `libs/validation/src/binding.bp:144` calls `parseInt` and its hand-rolled parser is gone;
      `libs/validation`'s 54 tests unchanged

As landed: both are `default fn`s of `behavior String` (`libs/std/test/primitives_test.bp`, six
tests). `parseInt` refuses a numeral beyond ±9007199254740991 — an `i64` is a JavaScript number on
commonJS, and past 2^53 `Number` rounds where Erlang is exact, so the range is the one both count
exactly. `parseFloat` refuses an overflow and answers `0.0` for an underflow. They run on commonJS,
erlang and beam; on wasm a call traps, as every template-only `String` method does. Two emitter gaps
met in a `default fn` of `primitives.bp`, worked around in std and recorded in `libs/std/AGENTS.md`
§ String numerals: commonJS emits `Ok(…)` / `Error(…)` as written, erlang emits `opt.unwrapOr(d)`
as a call to an undefined `unwrapOr/2`.

### Step 2 — the `Json` accessors as methods on `json.Json`

`libs/std/src/json.bp`: `Json.kindName() -> string`, `Json.isObject() -> bool`,
`Json.members() -> Array<#(string, Json)>` (`[]` for a non-object), `Json.field(key) -> ?Json`,
`Json.str() -> string` (`""` for a non-string), `Json.items() -> Array<Json>`. The names are the
copies' (`membersOf` → `members`, `fieldOf` → `field`, `strOf` → `str`, `itemsOf` → `items`), so a
consumer's edit is a receiver swap.

**Acceptance:**
- [x] each method has an inline test per `Json` variant, green on both targets
- [ ] `libs/actions/src/envelope.bp:56-103` and `rpc.bp:26-66` call the methods and declare none;
      `libs/actions`' tests unchanged; the envelope and RPC literals byte-identical
- [ ] `grep -rn "fn membersOf\|fn strOf\|fn itemsOf\|fn fieldOf\|fn kindName" libs/` is empty
      (today: the ten private copies of `libs/actions`, and `libs/routing/src/segment.bp:77`
      `pub fn kindName(k: SegmentKind)` — a different function over another type, which the grep
      has to exclude)

As landed: `field(key)` reads the value itself (`v.field(k)`, where the copies wrote
`fieldOf(membersOf(v), k)`). A consumer's free `pub fn kindName(v: Json)` / `isObject` keeps
compiling and answering beside the methods — measured from a dependency whose modules import the
copies by sibling path in a program that loads `std/json`, on commonJS and erlang — so each copy is
deleted by its owner at its own pace.

### Step 3 — `hash.pbkdf2Sha256` and `clock.parseDuration`

`hash.pbkdf2Sha256(password, salt, iterations, length) -> string` (base64url, Node
`crypto.pbkdf2Sync` / Erlang `crypto:pbkdf2_hmac`) and
`clock.parseDuration(text) -> @Result<i64, string>` (milliseconds; units `ms`, `s`, `m`, `h`, `d`;
one unit, digits only, refused otherwise — the stricter of the two rakun parsers).

**Acceptance:**
- [ ] `pbkdf2Sha256("password", "salt", 1, 32)` equals RFC 6070's vector on both targets
- [ ] `parseDuration("30s")` is `Ok(30000)`; `"1.5s"`, `"30"`, `"30 s"`, `"30S"` are `Error`
- [ ] the `03-rakun` track's `config.parseDuration` / `jwt.skewOf` rows name this function as
      their replacement (a "consume std" step there)

### Step 4 — the snapshot engine on `io/fs` and `path`

`libs/std/src/testing/snapshots.bp` drops its six `declare fn` templates for `io.fs.readFile`,
`writeFile`, `remove`, `exists`, `removeTree` and a scratch directory under `io.os.tmpDir()` /
`BOTOPINK_TEST_TMPDIR`, through `path.join`. Behaviour unchanged: `.new` on mismatch or missing,
`Ok` and a stale `.new` deleted on match, no update path.

**Acceptance:**
- [ ] `grep -n "External" libs/std/src/testing/snapshots.bp` is empty; the `engine ----` tests
      green on both targets; `grep -rn "SNAP_CREATE\|update" snapshots.bp` still finds the header only
- [ ] `zig build test-libs` reads every member's row at its previous count (the engine is what every
      `-test` member stands on)

### Step 5 — `async.RetryPolicy` and `nextDelay`

`pub type RetryPolicy(maxAttempts: i32, initialMillis: i64, multiplier: f64, maxMillis: i64)`,
`nextDelay(policy, attempt) -> ?i64` (`null` past `maxAttempts`), and
`retry(policy, work: fn() -> @Task<@Result<T, E>>) -> @Task<@Result<T, E>>` over `timeout`'s
shape (24-g): the last `Error` is answered, never rejected. No jitter without a decision.

**Acceptance:**
- [ ] `nextDelay(RetryPolicy(3, 100, 2.0, 1000), 1..4)` answers `100`, `200`, `400`, `null`
- [ ] `retry` over a work that fails twice then succeeds answers `Ok` after three calls, on both
      targets; over one that always fails answers the last `Error` after `maxAttempts`
- [ ] the four rakun loops are named as "consume std" rows in the `03-rakun` track

### Step 6 — conditional on `std-d`: `io.process` signals and a line reader

Only if the maintainer answers `std-d` (a): `process.onSignal`, `process.forwardSignals(child)`,
`io.stdin.readLine()`. Under (b) — the recommendation — this step is struck and onze 50's boxes
take their (b) shape.

**Acceptance:**
- [ ] under (a): a spawned child receives the `SIGTERM` sent to its parent, asserted on both
      targets with a child that prints on the signal; `readLine` answers a line without its newline
- [ ] under (b): nothing here; `libs/std/AGENTS.md` states that std has no signal or TTY surface
      and why

### Step 7 — conditional on `01std-f`: std's snapshot map

Only if the maintainer answers `01std-f` (b): write the ~40 `.snap` files of
[`test-snap.md`](./test-snap.md) under `libs/std/src/__snapshots__/`, each produced by an inline
test through `snapshots.assertAs`, recorded by renaming the `.new` (no flag). Under (a) — the
recommendation — the four existing files stay and the map is retired with a note in `AGENTS.md`.

**Acceptance:**
- [ ] under (b): every `.snap` the map names exists, identical on both targets; `botopink test`
      in `libs/std` green with no `.new` left
- [ ] under (a): `libs/std/AGENTS.md` § Tests says the inline literals are the evidence

### Step 8 — the surface documented

**Acceptance:**
- [ ] `libs/std/AGENTS.md` and `docs.md` list `parseInt`, `parseFloat`, the `Json` methods,
      `pbkdf2Sha256`, `parseDuration`, `RetryPolicy` / `nextDelay` / `retry`
- [ ] `libs/AGENTS.md` records that a shared primitive lands in std first and the copies are
      deleted by the file's owner

## Consumers — "consume std X" steps this front hands to the library fronts

Not this front's files. Each row is a step in the named 1.0.11-beta front; the deletion is measured by
the grep in the last column.

| Copy | Owner front | Step | Measured by |
|---|---|---|---|
| `emilia.bp:95-97` `hashHex` | `05-emilia/34-emilia-modifiers` step 1 | `import {hash} from "std"`, `hash.contentHash`, fixture `e_39b87d03` unchanged | `grep -n hashHex repository/emilia/modules/emilia/src` empty |
| `onze/src/config.bp:98-130` (`pub` accessors) | `06-onze/49-onze-stand-up` step 1 | receiver swap; the `pub` copies deleted (no consumer outside `onze`) | `grep -rn "fn membersOf\|fn strOf\|fn isObject\|fn kindName" repository/onze/modules/onze/src` empty |
| `onze-cli/src/{build,info}.bp`, `onze-bundler/src/entry.bp:182`, the `parseInt` in `entry.bp` | `06-onze/50-onze-cli` step 1 | receiver swap | the same grep over `onze-cli/src` and `onze-bundler/src` empty |
| `onze-og/src/svg.bp:19`, `metrics.bp:12` | `06-onze/51-onze-image` step 1 | `parseInt` / `parseFloat` | `grep -n "fn parse" repository/onze/modules/onze-og/src` empty |
| rakun's eleven copies (the table in § Problem) | the `03-rakun` track's fronts, by file | one row each | the `03-rakun` track's greps |

## Questions the maintainer owes

### 97-a · The names of steps 3 and 5 are names rakun already exports

**Measured.** rakun declares `pub fn parseDuration(raw, unit, key)` (`rakun/src/config.bp:1537`),
`pub type RetryPolicy` and `pub fn nextDelay(policy, attempt)`
(`rakun-messaging/src/reliability/policy.bp:12`, `:34`), imported by sibling path
(`reliability/dispatch.bp:50`, `test/config_test.bp:21`). On this compiler a dependency's module
that imports `{x} from "<sibling path>"` is refused as soon as the program loads a std module that
also declares `pub x` — "`x` is declared `pub` by `std/io/clock` and by `<pkg>/<module>`, and this
import does not say which" — for a type, and for a function whatever its arity (reproduced with
`Duration`, `add/2` and `seconds/3` against `std/io/clock`); when the same module imports both, a
type resolves to std's without a diagnostic. The same import inside the package's own build is not
refused.
**Options.** (a) the README's names — std lands them only together with rakun deleting its copies,
or after the import-resolution gap of `language-gaps.md` closes; (b) names no library exports
(decision 163's rule, applied to std), renamed never; (c) hold steps 3's `parseDuration` and 5.
**Recommendation.** (b) for the three colliding names, chosen with the `03-rakun` track so its
"consume std" rows name them; `pbkdf2Sha256` and `retry` collide with nothing.
**Blocks.** step 3's `parseDuration`, step 5.

### 97-b · `pbkdf2Sha256`'s salt is text; rakun's cell decodes it

**Measured.** `rakun_security.erl`'s `pbkdf2/3` derives over `base64:decode(SaltText, urlsafe)` —
the salt's 16 raw bytes — and stores `{pbkdf2}<iterations>$<salt>$<hash>`. Step 3's function takes
the salt as a `string` (its UTF-8 bytes — there is no byte type), and its acceptance vector
(`"salt"`) fixes that reading; the same stored salt therefore derives a different hash. RFC 6070's
vectors are PBKDF2-HMAC-SHA1: `("password", "salt", 1, 32)` under SHA-256 is
`120fb6cf…0be17b` (`Eg-2z_z4syxD5yJSVsT4N6hlSMkszDVICAWYfLcL4Xs` in base64url, identical on Node
`pbkdf2Sync` and `crypto:pbkdf2_hmac/5`); RFC 7914 §11 carries the published SHA-256 vectors.
**Options.** (a) text salt as written — rakun hashes stored under the old cell stop verifying;
(b) a second function over a base64url salt; (c) the salt always base64url.
**Recommendation.** (a) if no stored hash has to survive (rakun is unreleased), else (b).
**Blocks.** step 3's `pbkdf2Sha256`; `03-rakun`'s password row.

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `botopink test` and `botopink test --target erlang` green in `libs/std`, `libs/actions`,
      `libs/validation`; `zig build test-libs` every row at its previous count
- [ ] `snapshots/codegen/**` byte-identical (no compiler file changed)
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/97-std-dedupe`; no push, no merge — landing is the maintainer's step

## Blast radius

Additive in std; two bundled libraries lose private functions with no surface change. Every
consumer in a library keeps compiling until its own front deletes the copy — the point of landing
std first. Step 4 touches what every `-test` member runs on: the `test-libs` counts are the check.

## Notes

- `parseInt` answers `i64` because every consumer that hand-rolled it fed a port, a size or a
  count; a consumer wanting `i32` narrows.
- No jitter, no `retry` over a plain `@Task` (a Task never fails, decision 120), no `RetryPolicy`
  field a consumer could set to "unbounded" — the most restrictive shape (decision 67).
- The argv flag parser of the extraction analysis is **not** added here: three consumers with three
  grammars, and the CLI's own `parseXxxOpts` shape (`compiler-cli`) is the pattern each copies; a
  std `cli` module is a question for a later milestone once the grammars agree.
