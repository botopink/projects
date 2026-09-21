# Unification — 1.0.10-beta: where every 1.0.6 / 1.0.7 / 1.0.8 / 1.0.9 document went

1.0.9-beta absorbed three drafts (1.0.6 rakun, 1.0.7 onze13, 1.0.8 emilia) into one milestone of
ninety-five fronts. 1.0.10-beta re-cuts that milestone by **library** — `01-std/`, `03-rakun/`,
`04-jhonstart/`, `05-emilia/`, `06-onze/` — adds the compiler carry-over (`00-compiler-carry-over/`)
and the cross-cutting package restructure (`02-packaging/`), and keeps every front number. This file
is the proof that the re-cut lost nothing: every top-level document of the four earlier milestones
has a row saying where its content is now, and every front number 01–96 has a row saying where its
directory is now.

Two levels of proof. This file covers the **top-level** documents and the **front-number map**. The
**per-front** proof — which sections of each old front README were carried, appended or superseded —
is each library's own `unification.md`: [`01-std/unification.md`](./01-std/unification.md),
[`03-rakun/unification.md`](./03-rakun/unification.md), [`04-jhonstart/unification.md`](./04-jhonstart/unification.md),
[`05-emilia/unification.md`](./05-emilia/unification.md), [`06-onze/unification.md`](./06-onze/unification.md).

## Top-level documents

`carried` = the content is in the named 1.0.10 file, links rewritten · `carried + added` = the same,
plus a `## Carried from 1.0.X-beta` section or new rows named in the last column · `per-lib` = the
content is front-level and the library's `unification.md` is its proof · `superseded` = replaced by a
stated 1.0.9 or 1.0.10 rule, with the replacement named.

### 1.0.9-beta

| Document | Held | Where in 1.0.10 | Status |
|---|---|---|---|
| `overview.md` | the merge table, the audit table, numbering rule, tracks A–F with every front row, order (waves 0–5), rules, *Which target runs what*, source mapping | [`overview.md`](./overview.md) (coordinator) for the milestone text; the track tables are re-homed per library — `03-rakun/README.md`, `04-jhonstart/README.md`, `05-emilia/README.md`, `06-onze/README.md`, `01-std/README.md`; the blocking order and target table in [`fronts.md`](./fronts.md) | carried |
| `fronts.md` | ownership rows of tracks A–F, sidecar rule, shared-file rules (rakun `src/root.bp` + `botopink.json`, emilia `tokens.bp`/`emilia.bp` banners, jhonstart `root.bp`), frozen files, conflict exceptions, waves 0–7, exit gate | [`fronts.md`](./fronts.md) — every row, re-sectioned as `00` / `01-std` / `02-packaging` / tracks B–E; the per-lib `modules.md` files copy their own rows | carried + added (the `00` section, the `01-std` `@src()` carve-out, the packaging rows, a section-level *who may run together* matrix, *Rules for a front* from 1.0.6/7/8) |
| `contracts.md` | contracts 1–6a | [`contracts.md`](./contracts.md) | carried + added (contract 7 from `tracks/README.md`; 1.0.8's dispatcher rules under 4a) |
| `deferred.md` | Spring / Next / Tailwind deferrals, out-of-scope | [`deferred.md`](./deferred.md) | carried + added (*Deferred — ecosystem*: the old `onze` mocking runtime front 95 promised to record and never did) |
| `language-gaps.md` | 42 confirmed gaps, 4 toolchain gaps, unowned surface | [`language-gaps.md`](./language-gaps.md) | carried + added (the *1.0.10 owner* column pointing compiler rows at `00`; the *Compiler-front gaps* table; `@src()` owned by `01-std/src-builtin.md`; three packaging toolchain rows) |
| `tracks/README.md` | the per-track file plan (`modules.md`, `unification.md`, `test-snap.md`, `test-snap-examples.md`, `reference-coverage.md`, std's `asserts.md`/`snapshots.md`) and the test contract (`@src()`, `snapshots.path`, `.new`, no update flag) | the file plan **is** the 1.0.10 layout: `0N-<lib>/{README,modules,unification,test-snap,test-snap-examples}.md`, `05-emilia/reference-coverage.md`, `01-std/{asserts-api,snapshots,src-builtin}.md`; the test contract is [`contracts.md § 7`](./contracts.md#7--test-and-snapshot-contract--owned-by-01-std-consumed-by-every--test-submodule) | carried. None of the `tracks/<lib>/*.md` files it announced was ever written in 1.0.9; they are written here for the first time |
| `tracks/README.md`'s front `96-src-builtin-and-snapshots` | never written | [`01-std/src-builtin.md`](./01-std/src-builtin.md) · [`01-std/snapshots.md`](./01-std/snapshots.md) · [`01-std/asserts-api.md`](./01-std/asserts-api.md) | carried as three documents, no front number |
| `95-ecosystem-package-restructure/` | the restructure front + 2 examples | [`02-packaging/95-ecosystem-package-restructure/`](./02-packaging/95-ecosystem-package-restructure/README.md) verbatim (one provenance line prepended); its rules generalised in [`02-packaging/README.md`](./02-packaging/README.md); its std/asserts half in `01-std/` | carried + split |
| `NN-<front>/` (01–94) | the fronts | see the front-number map below | per-lib |

### 1.0.8-beta (emilia)

| Document | Held | Where in 1.0.10 | Status |
|---|---|---|---|
| `overview.md` — front table (F01–F15) | fifteen emilia fronts | fronts 33–47 under `05-emilia/` (map below) | per-lib |
| `overview.md` — Order (phases 1–4) and the three *why first* paragraphs (palette, modifiers, spacing) | palette/modifiers/spacing before the rest | superseded by 1.0.9's waves: 33/34/35 sit in wave 0–2 **after** 54 (theme) and 56 (cascade), for the reason stated in `fronts.md` § Waves ("four copies of the spacing ladder already drifted") | superseded — the 1.0.9 order is stricter and states why |
| `overview.md` — Regras: emilia-only · token enum expansion · **exhaustive dispatch, no `_`** · Tailwind parity · dual-target · **naming (camelCase / PascalCase / `__50`)** · no breaking changes · one in-file test per section | rules | emilia-only → `fronts.md` (one repo per front); token expansion → `fronts.md` banner convention; Tailwind parity → `overview.md` § Rules (byte-equality); dual-target → superseded (emilia is comptime, target-independent); no breaking changes → `overview.md` § Rules (*additive only*); one test per section → `fronts.md` track D. **Exhaustive dispatch** and **naming** were absent from 1.0.9 and are now [`contracts.md § 4a`](./contracts.md) *Carried from 1.0.8-beta*; the `__50` leaf spelling is recorded there as superseded by bare digits | carried + added |
| `overview.md` — *Mapeamento emilia → Tailwind* (current coverage per section) | the pre-milestone coverage table | [`05-emilia/reference-coverage.md`](./05-emilia/reference-coverage.md) | per-lib |
| `fronts.md` — ownership (section + dispatcher + test file per front) | F01–F15 rows | `fronts.md` track D rows (renumbered 33–47), unchanged in substance | carried |
| `fronts.md` — conflict matrix + notes (all fronts touch `tokens.bp`/`emilia.bp`, manual merge) | the shared-file problem | superseded by the **banner convention** in `fronts.md` (one variant block + one sub-dispatcher per front, arms in front-number order) — a rule, where 1.0.8 had a warning | superseded |
| `fronts.md` — Rules for a Front | worktree, only-your-sections, exhaustive case, Tailwind values, dual-target, verify by running, land | `fronts.md` § *Carried from 1.0.6/1.0.7/1.0.8-beta — Rules for a front* (merged with 1.0.6's and 1.0.7's) | carried + added |
| `tailwind-mapping.md` | the utility → token table | [`05-emilia/tailwind-mapping.md`](./05-emilia/tailwind-mapping.md) (carried as its own file) with the section-by-section walk in [`05-emilia/reference-coverage.md`](./05-emilia/reference-coverage.md) | carried (per-lib) |

### 1.0.7-beta (onze13)

| Document | Held | Where in 1.0.10 | Status |
|---|---|---|---|
| `overview.md` — front table (F01–F22) | 22 fronts across onze13, jhonstart, rakun, emilia, std | fronts 49–53 (onze), 26–32 (jhonstart), 22–25 + 07 + 12 (rakun), 48 (emilia), 02–03 (std) — map below | per-lib |
| `overview.md` — Order (phases 1–4) and *why 01 / 14 first* | onze13 stand-up first; file router before SSR | `overview.md` § Order and `fronts.md` § Waves (49 and 22 are wave 0/1; "why 22 before 23" is stated) | carried |
| `overview.md` — Regras: multi-repo · compiler-unaware · dual-target · std reuse · **convention over configuration** · no breaking changes · test coverage | rules | multi-repo → `overview.md` § Rules (*one repo per front*, 48 the exception); compiler-unaware → *the compiler knows none of this*; dual-target → superseded by *target is assigned, not chosen*; std reuse → *reuse std*; no breaking changes → *additive only*. **Convention over configuration** was absent from 1.0.9 and is now [`02-packaging/README.md`](./02-packaging/README.md) § *Carried from 1.0.7-beta* (it is a packaging rule: the file conventions are the API) | carried + added |
| `overview.md` — *Arquitetura onze13* diagram | the orchestrator over jhonstart/rakun/emilia/std | [`06-onze/README.md`](./06-onze/README.md) | per-lib |
| `overview.md` — *Mapeamento Next.js → onze13* (which library owns each Next feature) | feature → library | [`02-packaging/README.md`](./02-packaging/README.md) § *Carried from 1.0.7-beta*, re-stated with 1.0.9's front numbers and the `onze` name; per-feature detail in `06-onze/unification.md` | carried + added |
| `overview.md` — *Estrutura de um projeto onze13* (the `app/` tree, `onze13.json`) | the app layout | fronts 49 (config) and 53 (the blog) under `06-onze/`; `onze13.json` is `modules/onze/src/config.bp`'s concern | per-lib |
| `fronts.md` — ownership + conflict matrix + notes (F02↔F03 router/link, F09↔F14 runtime.bp, F15↔F16 emilia) | ownership | `fronts.md` tracks B/C/D rows; F09↔F14 dissolved by the frozen-file rule (`runtime.mjs` frozen, 22 and 23 own one file each); F15+F16 merged into 48 | carried / superseded |
| `fronts.md` — Rules for a Front | as 1.0.6 plus "from the submodule that owns the code" | `fronts.md` § *Carried from 1.0.6/1.0.7/1.0.8-beta* | carried + added |
| `fronts.md` — **Cross-repo Coordination** (interface contracts in READMEs · dependency order `onze → jhonstart, rakun, emilia`, `emilia → jhonstart` · `requires.<lib> = "feat"` + `bpmp sync` · F22 as the integration test) | the inter-library dependency graph | interface contracts → [`contracts.md`](./contracts.md); the **dependency direction between libraries** was absent from 1.0.9's top-level documents and is now [`02-packaging/README.md`](./02-packaging/README.md) § *Dependency direction*; version pinning → the same file § *Manifests* (`"branch": "feat"` is what every example manifest already does); F22 → front 53, wave 7 | carried + added |
| `examples-bp.md` | one code example per front, from the developer's point of view (22 sections) | per-front `examples/*.bp` under `03-rakun/`, `04-jhonstart/`, `05-emilia/`, `06-onze/` — 1.0.9 turned the single file into per-front example files; each library's `unification.md` maps its sections | per-lib |

### 1.0.6-beta (rakun)

| Document | Held | Where in 1.0.10 | Status |
|---|---|---|---|
| `overview.md` — front table (F01–F20, with module column) | twenty rakun fronts | fronts 04–21 under `03-rakun/` (F09+F19 → 13, F11+F16 → 15; map below) | per-lib |
| `overview.md` — Order (phases 1–3) and *why 01 / 02 first* | runtime and config first | `overview.md` § Order ("why 04 still comes before the rest of track B") and `fronts.md` § Waves | carried |
| `overview.md` — Regras: multi-module · **Erlang-first (every module has `runtime.erl`, not only `.mjs`)** · decorator-based · IoC integration · test coverage on both targets · no compiler changes · std reuse | rules | multi-module → `02-packaging/README.md` + `03-rakun/modules.md`; Erlang-first → strengthened into *Erlang/BEAM is the server* (`overview.md` § Which target runs what) and the sidecar rule (`src/sidecars/rakun_<name>.erl`, `fronts.md`); decorator-based and IoC integration → `03-rakun/README.md`; both-target tests → superseded by *target is assigned*; no compiler changes → `overview.md` § Rules; std reuse → the same | carried / superseded |
| `overview.md` — *Estrutura de Módulos* (`repository/rakun/src` + `modules/rakun-*` + `examples/`) | the module tree | [`02-packaging/README.md`](./02-packaging/README.md) (the generalised rule and the thirteen scaffolded submodules) and [`03-rakun/modules.md`](./03-rakun/modules.md) (the rakun cut) | carried |
| `overview.md` — *Mapeamento Spring Boot 4 → Rakun* (Spring area → rakun module → front) | the starter ↔ module table | [`02-packaging/README.md`](./02-packaging/README.md) § *Carried from 1.0.6-beta* — the module ↔ Spring starter table, re-pointed at 1.0.9 front numbers; `repository/rakun/modules/README.md` carries the same table at HEAD | carried + added |
| `fronts.md` — ownership (module + source + tests per front) | F01–F20 rows | `fronts.md` track B rows (renumbered), substance unchanged | carried |
| `fronts.md` — conflict matrix + notes (F01↔F03 `runtime.bp`; F04↔F06/F14/F18 middleware; F05↔F17 `rakun-data`; F09↔F19 `rakun-client`; F11↔F16 `rakun-messaging`) | five sequenced pairs | `fronts.md` § Conflict rules: F01↔F03 dissolved (04 appends one block to `runtime.bp`, 06 does not touch it); middleware pairs → *07 · 20 · 82* and the *07 owns the chain* rule; F05↔F17 → *08 · 09 · 77 · 78 · 83*; F09+F19 and F11+F16 merged into single fronts | carried / superseded |
| `fronts.md` — Rules for a Front | worktree, never edit unowned, verify by running, Erlang + commonJS, land | `fronts.md` § *Carried from 1.0.6/1.0.7/1.0.8-beta* | carried + added |
| `examples/01…10-*-example.bp` | ten example files for F01–F10 | the per-front `examples/` of fronts 04, 05, 06, 07, 08, 10, 11, 12, 13, 14 under `03-rakun/`; [`03-rakun/unification.md`](./03-rakun/unification.md) maps each | per-lib |

## Front-number map — 01 … 96

A front number is an identifier and never moves (`overview.md` § How fronts are numbered). The
directory moves once, here. Paths are relative to `specs/1.0.10-beta/`.

| # | 1.0.9 directory | 1.0.10 path | Came from |
|---|---|---|---|
| 01 | `01-std-lib-enablement/` | `01-std/01-std-lib-enablement/` | new in 1.0.9 |
| 02 | `02-std-async-primitives/` | `01-std/02-std-async-primitives/` | 1.0.7 F17 |
| 03 | `03-std-content-hash/` | `01-std/03-std-content-hash/` | 1.0.7 F18 |
| 04 | `04-rakun-erlang-runtime/` | `03-rakun/04-rakun-erlang-runtime/` | 1.0.6 F01 |
| 05 | `05-rakun-config-profiles/` | `03-rakun/05-rakun-config-profiles/` | 1.0.6 F02 |
| 06 | `06-rakun-context-api/` | `03-rakun/06-rakun-context-api/` | 1.0.6 F03 |
| 07 | `07-rakun-middleware/` | `03-rakun/07-rakun-middleware/` | 1.0.6 F04 + 1.0.7 F12 |
| 08 | `08-rakun-data-sql/` | `03-rakun/08-rakun-data-sql/` | 1.0.6 F05 |
| 09 | `09-rakun-data-nosql/` | `03-rakun/09-rakun-data-nosql/` | 1.0.6 F17 |
| 10 | `10-rakun-security-auth/` | `03-rakun/10-rakun-security-auth/` | 1.0.6 F06 |
| 11 | `11-rakun-actuator/` | `03-rakun/11-rakun-actuator/` | 1.0.6 F07 |
| 12 | `12-rakun-cache/` | `03-rakun/12-rakun-cache/` | 1.0.6 F08 + 1.0.7 F13 |
| 13 | `13-rakun-http-clients/` | `03-rakun/13-rakun-http-clients/` | 1.0.6 F09 + F19 |
| 14 | `14-rakun-validation/` | `03-rakun/14-rakun-validation/` | 1.0.6 F10 |
| 15 | `15-rakun-messaging/` | `03-rakun/15-rakun-messaging/` | 1.0.6 F11 + F16 |
| 16 | `16-rakun-scheduling/` | `03-rakun/16-rakun-scheduling/` | 1.0.6 F12 |
| 17 | `17-rakun-logging/` | `03-rakun/17-rakun-logging/` | 1.0.6 F13 |
| 18 | `18-rakun-session/` | `03-rakun/18-rakun-session/` | 1.0.6 F14 |
| 19 | `19-rakun-test-utilities/` | `03-rakun/19-rakun-test-utilities/` | 1.0.6 F15 |
| 20 | `20-rakun-websocket/` | `03-rakun/20-rakun-websocket/` | 1.0.6 F18 |
| 21 | `21-rakun-hateoas/` | `03-rakun/21-rakun-hateoas/` | 1.0.6 F20 |
| 22 | `22-rakun-file-routing/` | `03-rakun/22-rakun-file-routing/` | 1.0.7 F14 |
| 23 | `23-rakun-ssr-pipeline/` | `03-rakun/23-rakun-ssr-pipeline/` | 1.0.7 F09 |
| 24 | `24-rakun-server-actions/` | `03-rakun/24-rakun-server-actions/` | 1.0.7 F10 |
| 25 | `25-rakun-route-handlers/` | `03-rakun/25-rakun-route-handlers/` | 1.0.7 F11 |
| 26 | `26-jhonstart-router/` | `04-jhonstart/26-jhonstart-router/` | 1.0.7 F02 |
| 27 | `27-jhonstart-link/` | `04-jhonstart/27-jhonstart-link/` | 1.0.7 F03 |
| 28 | `28-jhonstart-server-components/` | `04-jhonstart/28-jhonstart-server-components/` | 1.0.7 F04 |
| 29 | `29-jhonstart-client-directive/` | `04-jhonstart/29-jhonstart-client-directive/` | 1.0.7 F05 |
| 30 | `30-jhonstart-streaming/` | `04-jhonstart/30-jhonstart-streaming/` | 1.0.7 F06 |
| 31 | `31-jhonstart-error-boundaries/` | `04-jhonstart/31-jhonstart-error-boundaries/` | 1.0.7 F07 |
| 32 | `32-jhonstart-metadata/` | `04-jhonstart/32-jhonstart-metadata/` | 1.0.7 F08 |
| 33 | `33-emilia-color-palette/` | `05-emilia/33-emilia-color-palette/` | 1.0.8 F14 |
| 34 | `34-emilia-modifiers/` | `05-emilia/34-emilia-modifiers/` | 1.0.8 F15 |
| 35 | `35-emilia-spacing-sizing/` | `05-emilia/35-emilia-spacing-sizing/` | 1.0.8 F03 |
| 36 | `36-emilia-layout/` | `05-emilia/36-emilia-layout/` | 1.0.8 F01 |
| 37 | `37-emilia-grid/` | `05-emilia/37-emilia-grid/` | 1.0.8 F02 (+ the unowned `Flex` section and the double-owned `gap`) |
| 38 | `38-emilia-typography/` | `05-emilia/38-emilia-typography/` | 1.0.8 F04 |
| 39 | `39-emilia-backgrounds/` | `05-emilia/39-emilia-backgrounds/` | 1.0.8 F05 |
| 40 | `40-emilia-borders/` | `05-emilia/40-emilia-borders/` | 1.0.8 F06 |
| 41 | `41-emilia-effects/` | `05-emilia/41-emilia-effects/` | 1.0.8 F07 |
| 42 | `42-emilia-filters/` | `05-emilia/42-emilia-filters/` | 1.0.8 F08 |
| 43 | `43-emilia-tables/` | `05-emilia/43-emilia-tables/` | 1.0.8 F09 |
| 44 | `44-emilia-transitions/` | `05-emilia/44-emilia-transitions/` | 1.0.8 F10 |
| 45 | `45-emilia-transforms/` | `05-emilia/45-emilia-transforms/` | 1.0.8 F11 |
| 46 | `46-emilia-interactivity/` | `05-emilia/46-emilia-interactivity/` | 1.0.8 F12 |
| 47 | `47-emilia-svg-accessibility/` | `05-emilia/47-emilia-svg-accessibility/` | 1.0.8 F13 |
| 48 | `48-emilia-attributes/` | `05-emilia/48-emilia-attributes/` | 1.0.7 F15 + F16 |
| 49 | `49-onze-stand-up/` (was `onze13-stand-up`) | `06-onze/49-onze-stand-up/` | 1.0.7 F01 |
| 50 | `50-onze-cli/` | `06-onze/50-onze-cli/` | 1.0.7 F19 |
| 51 | `51-onze-image/` | `06-onze/51-onze-image/` | 1.0.7 F20 |
| 52 | `52-onze-font/` | `06-onze/52-onze-font/` | 1.0.7 F21 |
| 53 | `53-onze-example-app/` | `06-onze/53-onze-example-app/` | 1.0.7 F22 |
| 54 | `54-emilia-theme/` | `05-emilia/54-emilia-theme/` | 1.0.9 audit |
| 55 | `55-emilia-preflight/` | `05-emilia/55-emilia-preflight/` | 1.0.9 audit |
| 56 | `56-emilia-cascade-and-output/` | `05-emilia/56-emilia-cascade-and-output/` | 1.0.9 audit |
| 57 | `57-emilia-escape-hatches/` | `05-emilia/57-emilia-escape-hatches/` | 1.0.9 audit |
| 58 | `58-emilia-container-queries/` | `05-emilia/58-emilia-container-queries/` | 1.0.9 audit |
| 59 | `59-emilia-custom-utilities-and-variants/` | `05-emilia/59-emilia-custom-utilities-and-variants/` | 1.0.9 audit |
| 60 | `60-rakun-static-generation/` | `03-rakun/60-rakun-static-generation/` | 1.0.9 audit |
| 61 | `61-rakun-parallel-intercepting-routes/` | `03-rakun/61-rakun-parallel-intercepting-routes/` | 1.0.9 audit |
| 62 | `62-rakun-request-context/` | `03-rakun/62-rakun-request-context/` | 1.0.9 audit |
| 63 | `63-rakun-navigation-signals/` | `03-rakun/63-rakun-navigation-signals/` | 1.0.9 audit |
| 64 | `64-rakun-i18n-routing/` | `03-rakun/64-rakun-i18n-routing/` | 1.0.9 audit |
| 65 | `65-rakun-url-rules/` | `03-rakun/65-rakun-url-rules/` | 1.0.9 audit |
| 66 | `66-rakun-metadata-file-routes/` | `03-rakun/66-rakun-metadata-file-routes/` | 1.0.9 audit |
| 67 | `67-jhonstart-forms/` | `04-jhonstart/67-jhonstart-forms/` | 1.0.9 audit |
| 68 | `68-onze-client-bundle/` | `06-onze/68-onze-client-bundle/` | 1.0.9 audit |
| 69 | `69-onze-styling-pipeline/` | `06-onze/69-onze-styling-pipeline/` | 1.0.9 audit |
| 70 | `70-onze-image-response/` | `06-onze/70-onze-image-response/` | 1.0.9 audit |
| 71 | `71-onze-release-packaging/` | `06-onze/71-onze-release-packaging/` | 1.0.9 audit |
| 72 | `72-rakun-auto-configuration/` | `03-rakun/72-rakun-auto-configuration/` | 1.0.9 audit |
| 73 | `73-rakun-starters/` | `03-rakun/73-rakun-starters/` | 1.0.9 audit |
| 74 | `74-rakun-tls-ssl-bundles/` | `03-rakun/74-rakun-tls-ssl-bundles/` | 1.0.9 audit |
| 75 | `75-rakun-observability-metrics/` | `03-rakun/75-rakun-observability-metrics/` | 1.0.9 audit |
| 76 | `76-rakun-actuator-security-probes/` | `03-rakun/76-rakun-actuator-security-probes/` | 1.0.9 audit |
| 77 | `77-rakun-db-migrations/` | `03-rakun/77-rakun-db-migrations/` | 1.0.9 audit |
| 78 | `78-rakun-orm-entities/` | `03-rakun/78-rakun-orm-entities/` | 1.0.9 audit |
| 79 | `79-rakun-oauth2-sso/` | `03-rakun/79-rakun-oauth2-sso/` | 1.0.9 audit |
| 80 | `80-rakun-devtools/` | `03-rakun/80-rakun-devtools/` | 1.0.9 audit |
| 81 | `81-rakun-packaging-release/` | `03-rakun/81-rakun-packaging-release/` | 1.0.9 audit |
| 82 | `82-rakun-static-assets/` | `03-rakun/82-rakun-static-assets/` | 1.0.9 audit |
| 83 | `83-rakun-distributed-transactions/` | `03-rakun/83-rakun-distributed-transactions/` | 1.0.9 audit |
| 84 | `84-rakun-persistent-jobs/` | `03-rakun/84-rakun-persistent-jobs/` | 1.0.9 audit |
| 85 | `85-rakun-mail/` | `03-rakun/85-rakun-mail/` | 1.0.9 audit |
| 86 | `86-rakun-messaging-reliability/` | `03-rakun/86-rakun-messaging-reliability/` | 1.0.9 audit |
| 87 | `87-rakun-audit-and-exchanges/` | `03-rakun/87-rakun-audit-and-exchanges/` | 1.0.9 audit |
| 88 | `88-rakun-cli/` | `03-rakun/88-rakun-cli/` | 1.0.9 audit |
| 89 | `89-rakun-stream-pipelines/` | `03-rakun/89-rakun-stream-pipelines/` | 1.0.9 audit |
| 90 | `90-rakun-jms-brokers/` | `03-rakun/90-rakun-jms-brokers/` | 1.0.9 audit |
| 91 | `91-rakun-pulsar/` | `03-rakun/91-rakun-pulsar/` | 1.0.9 audit |
| 92 | `92-rakun-rsocket/` | `03-rakun/92-rakun-rsocket/` | 1.0.9 audit |
| 93 | `93-rakun-soap-webservices/` | `03-rakun/93-rakun-soap-webservices/` | 1.0.9 audit |
| 94 | `94-jhonstart-element-surface/` | `04-jhonstart/94-jhonstart-element-surface/` | 1.0.9 audit |
| 95 | `95-ecosystem-package-restructure/` | `02-packaging/95-ecosystem-package-restructure/` (verbatim) · generalised in `02-packaging/README.md` · std half in `01-std/` | 1.0.9 audit |
| 96 | *(announced by `tracks/README.md`, never written)* | `01-std/src-builtin.md` · `01-std/snapshots.md` · `01-std/asserts-api.md` | 1.0.9 `tracks/README.md` |

The 1.0.5-beta compiler fronts (`01-checker` … `17-beam-memory`) keep **their own** numbering inside
[`00-compiler-carry-over/`](./00-compiler-carry-over/README.md); they are cited as `00 · 13-module-identity`
and never as a bare number, so a bare number in this milestone is always a library front.

## Link rewrite rule

Every relative link carried from `specs/1.0.9-beta/` was rewritten by this table. Any link that still
reads `../NN-<name>/` at the top level of `specs/1.0.10-beta/` is a defect.

| 1.0.9 form | 1.0.10 form |
|---|---|
| `./NN-<name>/README.md` (top-level file) | `./0T-<lib>/NN-<name>/README.md`, `0T` from the map above |
| `../NN-<name>/README.md` (from inside a front) | `../NN-<name>/README.md` when the target is in the same library directory; `../../0T-<lib>/NN-<name>/README.md` otherwise |
| `../96-src-builtin-and-snapshots/README.md` | `../01-std/src-builtin.md` (+ `snapshots.md`, `asserts-api.md`) |
| `./tracks/std/asserts.md`, `./tracks/std/snapshots.md` | `./01-std/asserts-api.md`, `./01-std/snapshots.md` |
| `./tracks/<lib>/modules.md` etc. | `./0T-<lib>/modules.md` etc. |
| `../1.0.8-beta/closure.md` (cited by `tracks/README.md`; the file does not exist) | `./05-emilia/reference-coverage.md` |
| `./fronts.md`, `./contracts.md`, `./deferred.md`, `./language-gaps.md` | unchanged (same level) — from inside a front, `../../<file>.md` |
