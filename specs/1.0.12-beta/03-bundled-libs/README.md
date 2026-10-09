# Track 03 — bundled libraries: what the frameworks copy from each other

**Depends on:** `02-std-and-packaging/97-std-dedupe` (steps 0–5 on feat — this track's std side).

Criterion: decisions 115–117 — a bundled package only when **two or more libraries** (or server and
browser) need the same code and decision 113 keeps it out of each framework. Names no framework, no
protocol of its own, no state beyond an inline host table (`persistent_term` / `globalThis`, as in
`libs/validation/src/messages.bp`), `.bp` only with inline `#[@External]` templates,
`["erlang", "commonJS"]` erlang first, imports only std and bundled packages. Generic,
protocol-free code → **std** ([`97-std-dedupe`](../02-std-and-packaging/97-std-dedupe/README.md)).

Copies deleted: seven hand walks of the route-segment grammar outside `routing`, two action-id
derivations, four `Cookie:` readers with three duplicate rules, three q-value parsers, four
reason-phrase tables, two MIME tables, two locale-tag grammars disagreeing on `zh-Hant-TW`, two OTP
release generators, three error digests. Every exported name checked against decision 163 (`07-i`:
no name std or a framework already exports).

## Fronts

| Front | Priority | State | What | Depends on |
|---|---|---|---|---|
| [`102-routing-conventions/`](./102-routing-conventions/README.md) | high | partial: steps 1–2 (the package) done; step 3 open | `routing.conventions` (eight app-file kinds in wrap order — decision 171; `kindOf`, `kindLetter` — 172; `classify` over one path — 173; `conventionConflicts`), segment helpers (`paramNamesOf`, `fillPattern`, `toColonPattern`); six consumer members switch | step 3: decision 323 |
| [`103-actions-id/`](./103-actions-id/README.md) | high | partial: step 1 (the package) done; step 2 open | `actions.id`: one `deriveActionId(secret, module, name, buildId)` and `isActionId` grammar (rakun-app derives, jhonstart-forms re-checks) | — |
| [`104-http/`](./104-http/README.md) | high | partial: steps 1–4 (the package) on feat; step 5 open | bundled `http`: `cookie`, `accept`, `mime`, `status`, `date`, `byteRange`, `cacheControl` (decisions 181, 182, 196); the consumer sweep | step 5: `04-rakun` 04, 65, 79, 12, 19, 22, `08-bpp/123`, `07-onze` 49, 51 (decision 188) |
| [`105-i18n/`](./105-i18n/README.md) | medium | not started | bundled `i18n`: one BCP 47 subset grammar (decision 180), `negotiate`, path helpers, `alternatesFor`, `interpolate` | 104 step 5 · `04-rakun/22` · `05-jhonstart/26` · 03r-q confirmed |
| [`106-log/`](./106-log/README.md) | high | partial: step 1 (the package) on feat; step 2 open | bundled `log` (decision 195): levels, `LogRecord`, four renderers, a sink-injected `Logger`, the one `errorDigest` (decision 194) | step 2: `04-rakun/17`, `05-jhonstart/26` step 4, `04-rakun/65` |
| [`107-release/`](./107-release/README.md) | low | not started (conditional on `07-g`) | bundled `release`: pure OTP release renderers rakun-cli and onze-release both write | `07-g` · `04-rakun/81` · `07-onze/71` |
| [`125-validation-zod/`](./125-validation-zod/README.md) | high for the step 0–2 residue, medium after | partial: steps 0–3 done; steps 4–12 open, blocked | Zod's feature set in `validation`: the `#[validated]` type is the only schema (306 — `#[schema]` folds into it) with parse members `parse`, `parseAt`, `decode`, `bind`, `encode`, `jsonSchema` (spelling `ctr-u`); field markers where Zod composes values (`Schema<T>`, `schemas.*`, `checks.*` private); 71 checks; report views; locales. Map: [`surface.md`](./125-validation-zod/surface.md). Extracts nothing — here as owner of `libs/validation/**` | `07-j` (reduced: ≈ option (c) under 306) |

## Order

```
packages   102 steps 1–2 · 103 step 1  ─► land front/102-103 (libs/routing, libs/actions)
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

- **Package half:** `libs/<pkg>/**`, collides with nothing.
- **Consumer half:** one commit per member on the named lines; never in a wave with the member's
  owning front (decision 188).
- Three files shared one line per package: `build.zig`'s `bundled_packages`, `libs/AGENTS.md`'s
  packages table, `scripts/format-check.sh`'s `TREES`; `routing`, `actions`, `validation`, `http`,
  `log` registered; 105 then 107 append one at a time (decision 189).

### Who else owns the consumer files

Sequenced, never together (`fronts.md`). rakun paths are the tree `04-rakun/128-rakun-consolidation`
leaves (decision 187).

| This front edits | Also owned by | Sequence |
|---|---|---|
| 102: rakun-app `file_router.bp`, `static_gen.bp`; rakun-hateoas `hal.bp` | `04-rakun` 22; 128 (moves `hal.bp` into `rakun-web/src/hateoas/`) | 102, then 128, then 22 |
| 103: rakun-app `actions.bp` (`actionId` deleted — 324 —, `resolveAction`); jhonstart-forms `form.bp` (`formAction`) | `04-rakun` 22; `05-jhonstart` 67 | 103 first |
| 102: jhonstart `routes.bp` | `05-jhonstart` 26 | 102 first |
| 102: onze `types.bp`; onze-cli `scan.bp`; onze-bundler `chunk.bp` | `07-onze` 49; 50 | 102 first |
| 104: rakun `request_context.bp`; rakun-web `negotiation.bp`, `compression.bp`, `static.bp`, `error.bp`; rakun-security `csrf.bp`; rakun-session `session_cookie.bp`; rakun-test `fake_request.bp`; rakun-app `i18n.bp` (`cookieFrom`, `qPerMille`) | `04-rakun` 04; 65 (and `08-bpp/123`, also in rakun-web); 79; 12; 19; 22 | after all of them |
| 104: onze-server `server.bp` (`cookiePairs`); onze-assets `image_handler.bp` | `07-onze` 49; 51 | after both |
| 105: rakun-app `i18n.bp`; jhonstart `render.bp` (`isLangTag`); `libs/validation/src/messages.bp` (`interpolate`) | `04-rakun` 22; `05-jhonstart` 26 (and `08-bpp/120`); `125-validation-zod` | after 104, 22, 26; `messages.bp` commit between two steps of 125 |
| 106: rakun-web `error.bp` (the `problem_digest` cell) | `04-rakun` 65 (and 104's sweep, `08-bpp/123`, also in rakun-web) | after 65; one front at a time in the member |
| written against 106's package, by their owners: rakun `src/logging/**`; jhonstart `error_boundary.bp`; onze's sink line | `04-rakun` 17; `05-jhonstart` 26 step 4 (and `08-bpp/122`, later); `07-onze` 49 step 3 | — |
| 107: rakun-cli `src/release/release.bp`; onze-release `otp.bp`, `docker.bp`, `spec.bp` | `04-rakun` 81; `07-onze` 71 | after 81 and 71 |

## What does not move, and why

- **emilia** (≈26 k LOC, 20 910 in `emilia.bp`): would almost triple the embedded source; one
  domain, own cadence. At most `arbitrary.bp`'s CSS-value check becomes a std `escape.css*` (std
  question).
- **erika**: pure, dual-target, 1 025 lines, but no library imports it — user-facing DSL. Stays,
  unless LINQ goes in std `collections` (`07-h`).
- **jhonstart-html**: comptime template bound to jhonstart's `Element` — framework surface.
- **onze-og, onze-assets**: font-metric tables, shell out for images; image bytes behind lg2-a.
  **onze-bundler**'s `importsOf`: compiler concern (lg2-s) → a CLI capability, never a library.
- **Erlang-only by nature** (processes, ETS, `gen_tcp`, binary framing behind lg2-a and the absent
  bitwise operators): rakun-data, rakun-cache (its `CacheLife` twin in rakun-client is a
  rakun-internal fix), rakun-metrics / actuator / tracing, websocket, rsocket, pulsar, JMS, mail,
  rakun-ws (SOAP), rakun-session's Redis client, LDAP / SAML / OAuth2.
- **rakun-client**: not a package; std `io.http` grows method, headers, body on both targets (a
  `02-std-and-packaging` row, not yet a front); rakun-client keeps its SSRF address policy and
  group/cache adapter.
- **Cron**: generic, one consumer. Later, pure `parse` + `nextFire` over `clock.toCivil` once a
  second consumer appears — only then does gap row "a decorator body cannot call a host function"
  stop biting `#[scheduled]`.
- **Config readers** (YAML subset, properties, placeholders), **JWT**: one consumer each; std
  `yaml` / `properties` when a second appears.
- **Framework adapters**: DI, autoconfig, actuator, every `-test` member.

## Decisions

Lettered `07-…`; numbered in [`../decisions-taken.md`](../decisions-taken.md) when answered.
Answered: `07-a` (196), `07-c` (180), `07-d` (181), `07-e` (182), `07-f` (195), `07-i` (163),
`07-k` (145), `07-l` (144), `07-m` (183), `07-n` (257). Open:

### 07-b · Does "one library, three or more copies with divergent semantics" also justify a package?

**Options.** (a) decision 115's "two or more libraries" only; (b) add the divergence test.
**Recommendation.** (a); single-library duplicates → std or the library's core. Cookie and q-value
copies qualify under (a) anyway (onze consumes them).
**Blocks.** nothing today; the rule for the next candidate.

### 07-g · OTP release rendering: a bundled `release`, a CLI feature, or no change?

**Measured.** `rakun-release/src/release.bp` and `onze-release/src/otp.bp` render the same `.rel` /
`vm.args` / `sys.config` / boot script / Dockerfile; onze cannot reuse rakun's (rakun erlang-only,
onze-release also commonJS).
**Options.** (a) bundled `release` of pure renderers; (b) a `botopink` CLI feature under
`02-std-and-packaging`; (c) leave both.
**Recommendation.** (a) now; the CLI adopts it later, neither framework depending on the other.
**Blocks.** `107-release`.

### 07-h · Bundled, or a separate shared non-bundled repository?

**Options.** (a) bundled — versioned with the compiler, no `dependencies` entry; (b) a shared
`botopink/common` repository, own cadence.
**Recommendation.** (a) while lg2-v (no `subdir` in a git dependency) and the "transitively loaded
package cannot be imported" toolchain row stay open; byte-exact wires belong with the compiler.
**Blocks.** the whole track's shape.

### 07-j · How much of Zod is `125-validation-zod` (reduced: ≈ option (c) under 306)

In full in [`125-validation-zod/README.md`](./125-validation-zod/README.md) § Decisions. 306 already
draws the shape; recommendation: every step, in order. Blocks: the front's size.
