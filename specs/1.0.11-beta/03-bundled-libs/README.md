# Track 03 — bundled libraries: what the frameworks copy from each other

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

| Front | Priority | When ([`../fronts.md`](../fronts.md) § Execution order of tracks 03–08) | What |
|---|---|---|---|
| [`102-routing-conventions/`](./102-routing-conventions/README.md) | high | package (steps 1–2): with the gate · consumers (step 3): first, before the library fronts open | `routing` gains `conventions` (the eight app-file kinds in the order they wrap a page — decision 171; `kindOf`, `kindLetter` — decision 172; `classify` over one path — decision 173; `conventionConflicts`) and segment helpers (`paramNamesOf`, `fillPattern`, `toColonPattern` — names under decision 163); rakun-app, rakun-hateoas, onze, onze-cli, onze-bundler and jhonstart consume them |
| [`103-actions-id/`](./103-actions-id/README.md) | high | package (step 1): with the gate · consumers (step 2): first, before the library fronts open | `actions` gains `id`: the one `deriveActionId(secret, module, name, buildId)` and `isActionId` grammar rakun-app derives and jhonstart-forms re-checks |
| [`104-http/`](./104-http/README.md) | high | package half: with the gate, after 97 (decision 196 answered `07-a`) · consumer sweep: after the fronts that own its consumer files | new bundled `http`: `cookie`, `accept`, `mime`, `status`, `date`, `range`, `cacheControl` — pure codecs of HTTP semantics, no wire parser, no compression; first-wins cookies (decision 181), the strict q-value (decision 182) |
| [`105-i18n/`](./105-i18n/README.md) | medium | after 104 | new bundled `i18n`: the locale set, one BCP 47 subset grammar (decision 180), `negotiate`, path helpers, `alternatesFor`; rakun-app keeps its registry and cookie, jhonstart's `isLangTag` switches to it |
| [`106-log/`](./106-log/README.md) | high | package: with the gate, after 97 — before `05-jhonstart/26` step 4, `04-rakun/17` and `07-onze/49` step 3 · its one consumer commit (rakun-web's `problem_digest`) after `04-rakun/65` | new bundled `log` (decision 195): levels, `LogRecord`, the four renderers, a sink-injected `Logger`, the one `errorDigest` (decision 194) and the error-logging function that writes the record and answers the digest |
| [`107-release/`](./107-release/README.md) | low — conditional on `07-g` | after 71 and 81 | new bundled `release`: the pure OTP release renderers (`rel`, `vmArgs`, `sysConfig`, `bootScript`, `dockerfile`, `appup`) rakun's release (in `rakun-cli` after decision 187) and onze-release both write |
| [`125-validation-zod/`](./125-validation-zod/README.md) | high for steps 0–2, medium after | steps 0–2: with the gate, after 97 · steps 3–10: beside the library fronts | Zod's feature set in `validation`. `#[schema]` on a record or an enum derives `schemaOf<T>`, `parse<T>(Json)`, `decode<T>(text)`, `bind<T>(form pairs)`, `encode<T>` and `jsonSchemaOf<T>` — the function from untrusted data to a typed value the library does not have; `Schema<T>` is the composable value (unions, tuples, maps, transforms, pipes, codecs) that `08-bpp`'s collections and actions take; the checks grow from 13 markers to 71; reports gain paths, `flatten` / `tree` / `pretty`, and locales. The map of all 205 reference rows is [`surface.md`](./125-validation-zod/surface.md). Not an extraction: it is in this track because it owns `libs/validation/**` |

## Order

```
wave 0    02-std-and-packaging/97-std-dedupe ──────────────┐   parseInt/parseFloat · Json accessors ·
          (libs/std only)                                  │   pbkdf2Sha256 · clock.parseDuration ·
                                                           │   RetryPolicy
                                                           ▼
packages   102 steps 1–2 · 103 step 1 · 125 steps 0–2   (libs/routing, libs/actions, libs/validation —
           one front per package, disjoint from every library front; they land with the gate, after 97)
           104 package half   (libs/http + the three registration lines)
           106 package        (libs/log — 26 step 4, rakun 17 and onze 49 step 3 are written against it)
           125 steps 3–10     (alone in libs/validation, beside the library fronts)
                                                           │
consumers  102 step 3 · 103 step 2 ─► before any library front opens (decision 188): their consumer
           commits go first and the library fronts branch from them
           106 ─► its consumers are the owning fronts' own steps (26 step 4, 17, 49 step 3); its one
                  commit, rakun-web's problem_digest cell, after 65
           104 consumer sweep ─► after the library fronts that own its consumer files have landed
           105 ─► after 104 (both edit rakun-app/i18n.bp); its messages.bp edit between two steps of 125
           107 ─► after 71 and 81                                          (conditional on 07-g)
```

A front of this track has two halves. The **package half** lives in `libs/<pkg>/**` and collides
with nothing but 97. The **consumer half** is one commit per member, on the lines the front names,
and a consumer commit never shares a wave with the front that owns the member (decision 188): 102
step 3 and 103 step 2 take their consumer commits before the library fronts open; 104, 105 and
107 take the slot after the library fronts that own their consumer files have landed. 106 has
almost no consumer half of its own: the fronts that own the members switch to the package in their
own steps (decisions 194, 195).

125 is the one front here that extracts nothing. It waits on wave 0 for the same reason the others
do — step 2 reads a `Json` with 97's accessors and step 6 parses a float with 97's `parseFloat` —
and its first three steps are ahead of everything else because `08-bpp/121` and `08-bpp/127` take
the `Schema<T>` they define.

Wave 0 is first because every later front deletes a hand-rolled `parseInt` or `Json` accessor in
the files it already touches; if std does not have the replacement, the front cannot delete
anything. Three files are shared by one line each: `build.zig`'s `bundled_packages` list,
`libs/AGENTS.md`'s packages table and `scripts/format-check.sh`'s `TREES`. **104 owns those three
lines**; 102, 103 and 125 touch none of them (their packages are already registered); 105, 106
and 107 append to them one at a time (decision 189). 106 registers as soon as its package is
ready — three fronts wait on it (decision 195) — and 105 and 107 follow in number order.

### Who else owns the consumer files

Every front here edits library files that a library-track front also names. The rule of
`fronts.md` applies: the fronts are sequenced, never run together. The overlaps, so the sequencing
is visible from both sides (rakun paths are the tree `04-rakun/128-rakun-consolidation` leaves —
decision 187):

| This front edits | Also owned by | Sequence |
|---|---|---|
| 102: rakun-app `file_router.bp`, `static_gen.bp`; rakun-hateoas `hal.bp` | `04-rakun` 22; 128 (it moves `hal.bp` into `rakun-web/src/hateoas/`) | 102 first, then 128, then 22 |
| 103: rakun-app `actions.bp` (the derivation); jhonstart-forms `form.bp:117-121` | `04-rakun` 22; `05-jhonstart` 67 | 103 first |
| 102: jhonstart `routes.bp` | `05-jhonstart` 26 | 102 first |
| 102: onze `types.bp`; onze-cli `scan.bp`; onze-bundler `chunk.bp` | `07-onze` 49; 50 | 102 first |
| 104: rakun `request_context.bp`; rakun-web `negotiation.bp`, `compression.bp`, `static.bp`, `error.bp`; rakun-security `csrf.bp`; rakun-session `session_cookie.bp`; rakun-test `fake_request.bp`; rakun-app `i18n.bp` (`cookieFrom`, `qPerMille`) | `04-rakun` 04; 65 (and `08-bpp/123`, also in rakun-web); 79; 12; 19; 22 | after all of them |
| 104: onze-server `server.bp:61`; onze-assets `image_handler.bp:92-99` | `07-onze` 49; 51 | after both |
| 105: rakun-app `i18n.bp`; jhonstart `render.bp:453`; `libs/validation/src/messages.bp:96` | `04-rakun` 22; `05-jhonstart` 26 (and `08-bpp/120`, `render.bp:218`); `125-validation-zod` | after 104, 22, 26; the `messages.bp` commit between two steps of 125 |
| 106: rakun-web `error.bp:56-57,199` (the `problem_digest` cell) | `04-rakun` 65 (and `104`'s sweep and `08-bpp/123`, also in rakun-web) | after 65; one front at a time in the member |
| written against 106's package, by their owners: rakun `src/logging/**`; jhonstart `error_boundary.bp`; onze's sink line | `04-rakun` 17; `05-jhonstart` 26 step 4 (and `08-bpp/122`, later); `07-onze` 49 step 3 | 106's package first |
| 107: rakun-cli `src/release/release.bp`; onze-release `otp.bp`, `docker.bp`, `spec.bp` | `04-rakun` 81; `07-onze` 71 | after 81 and 71 |

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

Lettered `07-a` … continuing; each becomes a number (next free **214**, allocated by the
milestone's `decisions-pending.md`) when answered.

Answered, and written into the fronts — the text is in
[`../decisions-taken.md`](../decisions-taken.md): `07-c` (180: the BCP 47 subset — 105), `07-d`
(181: first-wins cookies — 104 step 1), `07-e` (182: the strict q-value — 104 step 2), `07-i`
(163: no exported name std or a framework exports — every surface table), `07-k` (145), `07-l`
(144), `07-m` (183: a grammar per target type — 125 step 6), `07-f` (195: the bundled `log`
exists — 106; with 194, its `errorDigest` is the one digest), `07-a` (196: a bundled `http` —
104). Open: `07-b`, `07-g`, `07-h`, `07-j`, `07-n`.

### 07-b · Does "one library, three or more copies with divergent semantics" also justify a package?

**Options.** (a) keep decision 115's "two or more libraries" as the only test; (b) add the
divergence test.
**Recommendation.** (a). Single-library duplicates go to std or to the owning library's core. The
cookie and q-value copies qualify under (a) anyway — onze consumes them too.
**Blocks.** nothing today; the rule for the next candidate.

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

### 07-j · 07-n · `125-validation-zod`

Two questions (`07-k`, `07-l` and `07-m` are decisions 145, 144 and 183), written in full in
[`125-validation-zod/README.md`](./125-validation-zod/README.md) § Decisions the maintainer owes:

| Id | Question | Recommendation | Blocks |
|---|---|---|---|
| 07-j | How much of Zod is the front | every step, landed in order | the front's size |
| 07-n | Where `Schema<T>` lives — `validation` or std | `validation` | 125 step 2 |
