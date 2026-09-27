# Track 07 — bundled libraries: what the frameworks copy from each other

**Priority:** medium — runs beside the library tracks once `00-gate` is green; every front here
touches files a library front also owns, so the order in `fronts.md` is what makes it safe.
**Depends on:** `00-gate` (a green gate before any cross-repository refactor);
`02-std-and-packaging/97-std-dedupe` (wave 0 below — the std side lands first).

The criterion is decisions 115–117, unchanged: a bundled package exists only when **two or more
libraries** (or the server and the browser) need the same code and decision 113 keeps that code
out of each framework. It names no framework, speaks no protocol of its own, keeps no state beyond
an inline host table (the `persistent_term` / `globalThis` pattern of
`libs/validation/src/messages.bp`), ships `.bp` only with inline `#[@External]` templates,
targets `["erlang", "commonJS"]` erlang first, and imports only std and other bundled packages.
What is generic and has no protocol goes to **std** instead — that half is
[`02-std-and-packaging/97-std-dedupe`](../02-std-and-packaging/97-std-dedupe/README.md).

The measurement that opened this track: seven hand walks of the route-segment grammar outside
`routing`, two action-id derivations, **four `Cookie:` readers with three different duplicate
rules**, three q-value parsers, four reason-phrase tables, two MIME tables, two locale-tag
grammars that disagree on `zh-Hant-TW`, and two OTP release generators. Each is a place where the
server and the browser, or rakun and onze, can silently disagree byte for byte.

## Fronts

| Front | Priority | Wave | What |
|---|---|---|---|
| [`102-routing-conventions/`](./102-routing-conventions/README.md) | high | 1 | `routing` gains `conventions` (the eight app-file kinds, `classify`, `conflictProblems`) and segment helpers (`paramNames`, `fill`, `toColonPattern`); rakun-app, rakun-hateoas, onze, onze-cli, onze-bundler and jhonstart consume them |
| [`103-actions-id/`](./103-actions-id/README.md) | high | 1 | `actions` gains `id`: the one `actionId(secret, module, name, buildId)` and `isActionId` grammar rakun-app derives and jhonstart-forms re-checks |
| [`104-http/`](./104-http/README.md) | high | 1 | new bundled `http`: `cookie`, `accept`, `mime`, `status`, `date`, `range`, `cacheControl` — pure codecs of HTTP semantics, no wire parser, no compression |
| [`105-i18n/`](./105-i18n/README.md) | medium | 2 (after 104) | new bundled `i18n`: the locale set, one BCP 47 subset grammar, `negotiate`, path helpers, `alternatesFor`; rakun-app keeps its registry and cookie, jhonstart's `isLangTag` switches to it |
| [`106-log/`](./106-log/README.md) | low — conditional on `07-f` | 2 | new bundled `log`: levels, `LogRecord`, the four renderers, `errorDigest`, a sink-injected `Logger`; opened only if the maintainer chooses the package over 31-b option (a) |
| [`107-release/`](./107-release/README.md) | low — conditional on `07-g` | 2 | new bundled `release`: the pure OTP release renderers (`rel`, `vmArgs`, `sysConfig`, `bootScript`, `dockerfile`, `appup`) rakun-release and onze-release both write |

## Order

```
wave 0    02-std-and-packaging/97-std-dedupe ──────────────┐   parseInt/parseFloat · Json accessors ·
          (libs/std only)                                  │   pbkdf2Sha256 · clock.parseDuration ·
                                                           │   RetryPolicy
                                                           ▼
wave 1    102-routing-conventions · 103-actions-id · 104-http      (3 in parallel — file-disjoint
                                                                    but for three one-line
                                                                    registrations, see below)
                                                           │
wave 2    105-i18n (after 104: both edit rakun-app/i18n.bp) ▼
          106-log ∥ 107-release ∥ 105-i18n                          (conditional on 07-f, 07-g)
```

Wave 0 is first because every later front deletes a hand-rolled `parseInt` or `Json` accessor in
the files it already touches; if std does not have the replacement, the front cannot delete
anything. The wave-1 fronts share exactly three files, each by one line: `build.zig`'s
`bundled_packages` list (104 adds `http`; 102 and 103 add nothing), `libs/AGENTS.md`'s packages
table and `scripts/format-check.sh`'s `TREES`. **104 owns those three lines**; 102 and 103 touch
none of them.

### Who else owns the consumer files

Every front here edits library files that a library-track front also names. The rule of
`fronts.md` applies: the fronts are sequenced, never run together. The overlaps, so the sequencing
is visible from both sides:

| This front edits | Also owned by |
|---|---|
| rakun-app `file_router.bp`, `static_gen.bp`; rakun-hateoas `hal.bp` | `03-rakun` (the rakun-app front, the hateoas tail) |
| jhonstart `routes.bp`; jhonstart-forms `form.bp` | `04-jhonstart` (26/27 group; 67) |
| onze `types.bp`; onze-cli `scan.bp`; onze-bundler `chunk.bp` | `06-onze` (49; 50; 68) |
| rakun `request_context.bp`; rakun-web `negotiation.bp`, `compression.bp`, `static.bp`, `error.bp`; rakun-security `csrf.bp`; rakun-session `session_cookie.bp`; rakun-test `fake_request.bp` | `03-rakun` (core; rakun-web; security; session; test) |
| onze-server `server.bp`; onze-assets `image_handler.bp` | `06-onze` (49; 51) |
| rakun-app `i18n.bp`; jhonstart `render.bp`; `libs/validation/src/messages.bp` | `03-rakun` (64); `04-jhonstart` (30); nobody else (validation is bundled) |
| rakun-logging `formats.bp`, `levels.bp`, `digest.bp`; jhonstart `error_boundary.bp` | `03-rakun` (17); `04-jhonstart` (31) |
| rakun-release `release.bp`; onze-release `otp.bp`, `docker.bp`, `spec.bp` | `03-rakun` (81); `06-onze` (71) |

## What does not move, and why

Measured against the criterion, not against size alone:

- **emilia** (≈26 k LOC, 20 910 in `emilia.bp`) would almost triple the embedded source; one
  domain, its own cadence. Stays a repository. At most its CSS-value safety check
  (`arbitrary.bp`) becomes a std `escape.css*` — a `97-std-dedupe` question, not a package.
- **erika** is pure, dual-target and 1 025 lines — but no library imports it; it is a user-facing
  DSL. Stays, unless the maintainer wants LINQ in std `collections` (`07-h`).
- **jhonstart-html** is a comptime template bound to jhonstart's `Element` — a framework surface.
- **onze-og, onze-assets** carry font-metric tables and shell out for image work; image bytes
  are behind lg2-a. **onze-bundler**'s `importsOf` is a compiler concern (lg2-s) and becomes a
  CLI capability, never a library.
- **Erlang-only by nature** (processes, ETS, `gen_tcp`, binary framing behind lg2-a and the
  absent bitwise operators): rakun-data, rakun-cache (its `CacheLife` twin in rakun-client is a
  rakun-internal fix), rakun-metrics / actuator / tracing, websocket, rsocket, pulsar, JMS, mail,
  rakun-ws (SOAP), rakun-session's Redis client, LDAP / SAML / OAuth2.
- **rakun-client** does not become a package: std `io.http` grows method, headers and body on both
  targets instead (a `02-std-and-packaging` row); rakun-client keeps its SSRF address policy and
  its group/cache adapter.
- **Cron** is generic but has one consumer. Later, as pure `parse` + `nextFire` over
  `clock.toCivil`, when a second consumer appears — and only then does gap row "a decorator body
  cannot call a host function" stop biting `#[scheduled]`.
- **The config readers** (YAML subset, properties, placeholders) and **JWT**: one consumer each;
  std `yaml` / `properties` when a second appears.
- **The framework adapters**: DI, autoconfig, actuator, and every `-test` member.

## Decisions the maintainer owes

Lettered `07-a` … continuing; each becomes a number (next free **144**, allocated by the
milestone's `decisions-pending.md`) when answered.

### 07-a · Where do the HTTP codecs live — std modules or a bundled `http`?

**Measured.** Four `Cookie:` readers in rakun (`request_context.bp:577-685` first-wins and
percent-decoded; `csrf.bp:44` first-wins undecoded; `i18n.bp:238` prefix match; `session_cookie.bp:10-34`
**last-wins**), one in onze-server (`server.bp:61`), one in rakun-test (`fake_request.bp:136`).
Three q-value parsers (`negotiation.bp:15-85` = `compression.bp:89-145`; `i18n.bp:125-170` stricter).
**Options.** (a) a bundled `http` package; (b) std modules under `io.http`'s neighbourhood;
(c) leave the copies.
**Recommendation.** (a). It is a protocol domain with its own test suite; std stays language-level;
a root `http` module would clash with the leaf binding of `io.http`. The import experience is the
same either way.
**Blocks.** `104-http`.

### 07-b · Does "one library, three or more copies with divergent semantics" also justify a package?

**Options.** (a) keep decision 115's "two or more libraries" as the only test; (b) add the
divergence test.
**Recommendation.** (a). Single-library duplicates go to std or to the owning library's core. The
cookie and q-value copies qualify under (a) anyway — onze consumes them too.
**Blocks.** nothing today; the rule for the next candidate.

### 07-c · Which language-tag grammar does `i18n` own?

**Measured.** jhonstart `render.bp:453` `isLangTag` accepts `zh-Hant-TW`; rakun-app `i18n.bp`
`wellFormedTag` refuses it (only `ll(l)` plus optional `-RR` / `-999`).
**Options.** (a) a BCP 47 subset — language 2–3 letters, optional script 4 letters, optional
region 2 letters or 3 digits, normalised case; (b) rakun's grammar; (c) jhonstart's.
**Recommendation.** (a); both callers switch, and a tag outside the subset is refused, never
passed through.
**Blocks.** `105-i18n`.

### 07-d · Which rule applies to a duplicated cookie name?

**Options.** (a) first-wins everywhere (RFC 6265 § 5.4); (b) last-wins; (c) per caller.
**Recommendation.** (a). `session_cookie` changes from last-wins; control-character escapes stay
undecoded, as `request_context` does today.
**Blocks.** `104-http` step 1.

### 07-e · Which q-value grammar applies?

**Options.** (a) the strict one — at most three decimals, digits only, anything malformed reads
as 0; (b) the lenient one negotiation and compression use today.
**Recommendation.** (a), for media, encoding and language alike. Negotiation and compression lose
their leniency; a malformed `Accept` no longer negotiates by accident.
**Blocks.** `104-http` step 2.

### 07-f · Logging: a bundled `log`, or only 31-b option (a)?

**Measured.** jhonstart's error digest is `contentHash(message)` (`error_boundary.bp:77`);
rakun-logging's is `strongHash` over four parts (`digest.bp:63-70`). They never correlate.
**Options.** (a) resolve 31-b with its option (a) — an `onError` hook on `app` / `RenderHooks`
that onze sets — and open no package; (b) a bundled `log` with a neutral `errorDigest`.
**Recommendation.** (a) now; `106-log` opens only when jhonstart or onze needs a real logger.
**Blocks.** `106-log`; `04-jhonstart` 31's digest box; `03-rakun` 17's fixture box.

### 07-g · OTP release rendering: a bundled `release`, a CLI feature, or no change?

**Measured.** `rakun-release/release.bp:77-170` and `onze-release/otp.bp:24-60` render the same
`.rel` / `vm.args` / `sys.config` / boot script / Dockerfile; onze cannot reuse rakun's because rakun
is erlang-only and onze-release targets commonJS too.
**Options.** (a) a bundled `release` of pure renderers; (b) a `botopink` CLI feature under
`02-std-and-packaging`; (c) leave both.
**Recommendation.** (a) now; the CLI adopts the package later without either framework depending
on the other.
**Blocks.** `107-release`.

### 07-h · Bundled, or a separate shared non-bundled repository?

**Options.** (a) bundled — versioned with the compiler, no `dependencies` entry; (b) a shared
`botopink/common` repository with its own cadence.
**Recommendation.** (a) while lg2-v (no `subdir` in a git dependency) and the "transitively loaded
package cannot be imported" toolchain row stay open; wires both frameworks must agree on byte for
byte belong with the compiler that embeds them.
**Blocks.** the whole track's shape.

### 07-i · May a bundled package export a name std or a framework already exports?

**Measured.** `language-gaps.md`'s toolchain row: `import {x} from "<package>"` is refused as
ambiguous when std exports `x` too.
**Options.** (a) forbid it until the row closes — `cookie.parse`, never `cookies`; (b) allow and
rely on qualified imports.
**Recommendation.** (a).
**Blocks.** every surface table in this track.
