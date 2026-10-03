# Track 03 — bundled libraries: what the frameworks copy from each other

**Depends on:** `02-std-and-packaging/97-std-dedupe` (its steps 0–5 are on feat — the std side of
this track).

The criterion is decisions 115–117: a bundled package exists only when **two or more libraries**
(or the server and the browser) need the same code and decision 113 keeps that code out of each
framework. It names no framework, speaks no protocol of its own, keeps no state beyond an inline
host table (the `persistent_term` / `globalThis` pattern of `libs/validation/src/messages.bp`),
ships `.bp` only with inline `#[@External]` templates, targets `["erlang", "commonJS"]` erlang
first, and imports only std and other bundled packages. What is generic and has no protocol goes to
**std** instead ([`97-std-dedupe`](../02-std-and-packaging/97-std-dedupe/README.md)).

The copies this track deletes: seven hand walks of the route-segment grammar outside `routing`, two
action-id derivations, four `Cookie:` readers with three duplicate rules, three q-value parsers,
four reason-phrase tables, two MIME tables, two locale-tag grammars that disagree on `zh-Hant-TW`,
two OTP release generators, three error digests. Each is a place where the server and the browser,
or rakun and onze, can disagree byte for byte. Every exported name is checked against decision 163
(`07-i`: no name std or a framework already exports).

## Fronts

| Front | Priority | State | What | Depends on |
|---|---|---|---|---|
| [`102-routing-conventions/`](./102-routing-conventions/README.md) | high | not on feat — steps 1–2 reported done on the unpushed branch `front/102-routing-conventions` | `routing.conventions` (the eight app-file kinds in wrap order — decision 171; `kindOf`, `kindLetter` — 172; `classify` over one path — 173; `conventionConflicts`) and segment helpers (`paramNamesOf`, `fillPattern`, `toColonPattern`); six consumer members switch to them | the branch pushed · 49-d confirmed as amended (step 3) |
| [`103-actions-id/`](./103-actions-id/README.md) | high | not on feat — step 1 reported done on the unpushed branch `front/103-actions-id` | `actions.id`: the one `deriveActionId(secret, module, name, buildId)` and `isActionId` grammar rakun-app derives and jhonstart-forms re-checks | the branch pushed |
| [`104-http/`](./104-http/README.md) | high | partial: steps 1–4 (the package) on feat; step 5 open | bundled `http`: `cookie`, `accept`, `mime`, `status`, `date`, `byteRange`, `cacheControl` (decisions 181, 182, 196); the consumer sweep | step 5: `04-rakun` 04, 65, 79, 12, 19, 22, `08-bpp/123`, `07-onze` 49, 51 (decision 188) |
| [`105-i18n/`](./105-i18n/README.md) | medium | not started | bundled `i18n`: one BCP 47 subset grammar (decision 180), `negotiate`, path helpers, `alternatesFor`, `interpolate` | 104 step 5 · `04-rakun/22` · `05-jhonstart/26` · 03r-q confirmed |
| [`106-log/`](./106-log/README.md) | high | partial: step 1 (the package) on feat; step 2 open | bundled `log` (decision 195): levels, `LogRecord`, four renderers, a sink-injected `Logger`, the one `errorDigest` (decision 194) | step 2: `04-rakun/17`, `05-jhonstart/26` step 4, `04-rakun/65` |
| [`107-release/`](./107-release/README.md) | low | not started (conditional on `07-g`) | bundled `release`: the pure OTP release renderers rakun-cli and onze-release both write | `07-g` · `04-rakun/81` · `07-onze/71` |
| [`125-validation-zod/`](./125-validation-zod/README.md) | high for the step 0–2 residue, medium after | partial: steps 0–2 on feat with residue; steps 3–10 open | Zod's feature set in `validation`: `#[schema]` derives `schemaOf<T>`, `parse<T>`, `decode<T>`, `bind<T>`, `encode<T>`, `jsonSchemaOf<T>`; `Schema<T>` combinators; 71 checks; report views; locales. Map: [`surface.md`](./125-validation-zod/surface.md). It extracts nothing — it is here because it owns `libs/validation/**` | `07-j` (size) |

## Order

```
packages   102 steps 1–2 · 103 step 1  ─► land the pushed branches (libs/routing, libs/actions)
           125 steps 3–10               (alone in libs/validation, beside the library fronts)
           105 package · 107 package    (each appends to the three registration lines in turn)
                                                           │
consumers  102 step 3 · 103 step 2 ─► before any library front opens (decision 188); the library
           fronts branch from them
           106 step 2 ─► the owning fronts' own steps (26 step 4, rakun 17); its one commit,
                  rakun-web's problem_digest cell, after 65
           104 step 5 ─► after the library fronts that own its consumer files have landed
           105 ─► after 104 step 5 (both edit rakun-app/i18n.bp); its messages.bp edit between
                  two steps of 125
           107 ─► after 71 and 81                                         (conditional on 07-g)
```

A front has two halves. The **package half** lives in `libs/<pkg>/**` and collides with nothing.
The **consumer half** is one commit per member, on the lines the front names, and never shares a
wave with the front that owns the member (decision 188). Three files are shared by one line per
package: `build.zig`'s `bundled_packages`, `libs/AGENTS.md`'s packages table and
`scripts/format-check.sh`'s `TREES`; `routing`, `actions`, `validation`, `http` and `log` are
registered, and 105 then 107 append one at a time (decision 189).

### Who else owns the consumer files

The fronts are sequenced, never run together (`fronts.md`). rakun paths are the tree
`04-rakun/128-rakun-consolidation` leaves (decision 187).

| This front edits | Also owned by | Sequence |
|---|---|---|
| 102: rakun-app `file_router.bp`, `static_gen.bp`; rakun-hateoas `hal.bp` | `04-rakun` 22; 128 (it moves `hal.bp` into `rakun-web/src/hateoas/`) | 102 first, then 128, then 22 |
| 103: rakun-app `actions.bp` (`actionId`, `resolveAction`); jhonstart-forms `form.bp` (`formAction`) | `04-rakun` 22; `05-jhonstart` 67 | 103 first |
| 102: jhonstart `routes.bp` | `05-jhonstart` 26 | 102 first |
| 102: onze `types.bp`; onze-cli `scan.bp`; onze-bundler `chunk.bp` | `07-onze` 49; 50 | 102 first |
| 104: rakun `request_context.bp`; rakun-web `negotiation.bp`, `compression.bp`, `static.bp`, `error.bp`; rakun-security `csrf.bp`; rakun-session `session_cookie.bp`; rakun-test `fake_request.bp`; rakun-app `i18n.bp` (`cookieFrom`, `qPerMille`) | `04-rakun` 04; 65 (and `08-bpp/123`, also in rakun-web); 79; 12; 19; 22 | after all of them |
| 104: onze-server `server.bp` (`cookiePairs`); onze-assets `image_handler.bp` | `07-onze` 49; 51 | after both |
| 105: rakun-app `i18n.bp`; jhonstart `render.bp` (`isLangTag`); `libs/validation/src/messages.bp` (`interpolate`) | `04-rakun` 22; `05-jhonstart` 26 (and `08-bpp/120`); `125-validation-zod` | after 104, 22, 26; the `messages.bp` commit between two steps of 125 |
| 106: rakun-web `error.bp` (the `problem_digest` cell) | `04-rakun` 65 (and 104's sweep and `08-bpp/123`, also in rakun-web) | after 65; one front at a time in the member |
| written against 106's package, by their owners: rakun `src/logging/**`; jhonstart `error_boundary.bp`; onze's sink line | `04-rakun` 17; `05-jhonstart` 26 step 4 (and `08-bpp/122`, later); `07-onze` 49 step 3 | — |
| 107: rakun-cli `src/release/release.bp`; onze-release `otp.bp`, `docker.bp`, `spec.bp` | `04-rakun` 81; `07-onze` 71 | after 81 and 71 |

## What does not move, and why

- **emilia** (≈26 k LOC, 20 910 in `emilia.bp`) would almost triple the embedded source; one
  domain, its own cadence. At most its CSS-value safety check (`arbitrary.bp`) becomes a std
  `escape.css*` — a std question, not a package.
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
  targets instead (a `02-std-and-packaging` row, not yet a front); rakun-client keeps its SSRF
  address policy and its group/cache adapter.
- **Cron** is generic but has one consumer. Later, as pure `parse` + `nextFire` over
  `clock.toCivil`, when a second consumer appears — and only then does gap row "a decorator body
  cannot call a host function" stop biting `#[scheduled]`.
- **The config readers** (YAML subset, properties, placeholders) and **JWT**: one consumer each;
  std `yaml` / `properties` when a second appears.
- **The framework adapters**: DI, autoconfig, actuator, and every `-test` member.

## Decisions

Lettered `07-…`; each becomes a number in [`../decisions-taken.md`](../decisions-taken.md) when
answered. Answered and written into the fronts: `07-a` (196), `07-c` (180), `07-d` (181), `07-e`
(182), `07-f` (195), `07-i` (163), `07-k` (145), `07-l` (144), `07-m` (183), `07-n` (257). Open:

### 07-b · Does "one library, three or more copies with divergent semantics" also justify a package?

**Options.** (a) keep decision 115's "two or more libraries" as the only test; (b) add the
divergence test.
**Recommendation.** (a). Single-library duplicates go to std or to the owning library's core. The
cookie and q-value copies qualify under (a) anyway — onze consumes them too.
**Blocks.** nothing today; the rule for the next candidate.

### 07-g · OTP release rendering: a bundled `release`, a CLI feature, or no change?

**Measured.** `rakun-release/src/release.bp` and `onze-release/src/otp.bp` render the same `.rel` /
`vm.args` / `sys.config` / boot script / Dockerfile; onze cannot reuse rakun's because rakun is
erlang-only and onze-release targets commonJS too.
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

### 07-j · How much of Zod is `125-validation-zod`

Written in full in [`125-validation-zod/README.md`](./125-validation-zod/README.md) § Decisions.
Recommendation: every step, landed in order. Blocks: the front's size.
