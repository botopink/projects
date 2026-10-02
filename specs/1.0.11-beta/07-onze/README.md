# Track 07 — onze

**Repo:** `repository/onze` · **Reference:** Next.js docs, the framework half · **Carried from:**
`specs/1.0.10-beta/06-onze/` (nine fronts: 49–53 · 68–71) — the mapping is
[`carried.md`](./carried.md); the tree as it is on disk is [`modules.md`](./modules.md); the
Next.js rows no front covers are [`reference-holes.md`](./reference-holes.md).

onze wires (decision 113): it is the one package that imports jhonstart, rakun and the
`jhonstart-emilia` bridge together, and where the libraries meet in an example (decision 114).
1.0.10 landed the orchestrator as eight members — the core, `onze-server` (the rakun half of the
boot, 49-e), `onze-test`, `onze-cli`, `onze-bundler` (63 / 63), `onze-assets`, `onze-og`,
`onze-release` — and the blog under `examples/blog` serving `/`, `/blog/hello-world`, `/about`,
the gated dashboard and a hydrated island through `onze build && onze start`. What is left is
the wiring that waited on rakun, `onze dev`, the release end to end, and the second half of the
blog's acceptance script. Five fronts, cut by member.

## What onze still owes

| Id | Item | Where | Front |
|---|---|---|---|
| ONZ-49-4.3 | `RequestData.query` / `.headers` are `[]` (`onze-server/src/server.bp:76-77`) — rakun's `queryDict` (`rakun-app/src/ssr.bp:276`) and `headerNames` (`rakun/src/request_context.bp:402`) exist now; the public root is not registered (decision 201, after `04-rakun/65` step 1); the one-file wording of step 4's third box (49-e) | `onze-server`, `onze` | 49 |
| ONZ-49-4.5 | `serveActions` is not installed, and the missing-key refusal (rakun refuses to start its dispatcher naming `rakun.actions.field`) is not asserted — `rakun-app/src/actions.bp` has `serveActions` / `actionsConfigProblem` now | `onze-server` | 49 |
| ONZ-49-4.6 | `__bp_action` / `X-Bp-Action` as literals in `rakun-app/test/actions_test.bp:365` (rakun's) and `jhonstart-forms/test/form_test.bp` (jhonstart's, `05-jhonstart/67`) — onze's box closes on their greps | other repos | 49 (the grep) |
| ONZ-49-mark | the dynamic mark has two writers: jhonstart's `d` (26-b) and rakun 23's `markDynamic("searchParams")`, which fires on any read of the query — onze's `pageInput` reads it on every request. Decision 186: no run-time mark at all — the stage a page renders in is a compile-time fact and the build writes the route kind; until the checker capability lands, the renderer marks through `ChunkWriter.markDynamic(reason)` | `onze/src/integration.bp`, `onze-server`, rakun 23 | 49 step 5 |
| ONZ-49-err | the error digest reaches the log: onze sets the bundled `log`'s sink to rakun's logger and nothing else — the boundary logs and digests through `log` (decisions 194, 195; no `RenderHooks.onError`) | `onze-server` | 49 step 3, after `03-bundled-libs/106` and jhonstart 26 step 4 |
| ONZ-69-pub | the public root — rakun-web 82 answers 404 on a miss inside a matched root (`static.bp:44-49`); decision 201: a miss falls through, only `GET` / `HEAD` are served, a refusal stays final (`04-rakun/65` step 1); then `public/` at `/**` before the routes, `servedRoots` + `docs.md` | `onze-server` | 49 step 4, after 65 step 1 |
| ONZ-50-6 | `onze dev` — `main.bp:101` prints "not available yet"; no `dev.bp`; `onze-bundler/src/rebuild.bp` is not driven; the node is not reloaded | `onze-cli`, `onze-bundler` | 50 |
| ONZ-50-7 | `prerender/` in the build output (rakun 60's `static_gen.bp` exists now) | `onze-cli/src/build.bp` | 50 |
| ONZ-50-8 · 8b | `build && start` serves what `dev` served; `SIGTERM` reaches the node (`start.bp` waits on `process.run`) — shape decided by `std-d` | `onze-cli` | 50 |
| ONZ-50-DoD | `dev.bp`; `test/resolve_test.bp` (missing — `start_test.bp` exists instead); the defaults table from one source (`docs.md`, `--help`, `create`); the tails `--example`, the prompts (`std-d`), `-H` | `onze-cli` | 50 |
| ONZ-68-split | route-level chunk splitting (the entry imports every client component; lazy starters through `registerRouteStarters`); `assetPrefix`; `<Script onReady / onError>` | `onze-bundler/src/{entry,chunk,script}.bp`, `onze-cli/src/build.bp` | 50 |
| ONZ-51-5 | a cache miss encodes once under concurrent identical requests (rakun-cache's `rkCacheFlight` exists now) | `onze-assets/src/image_handler.bp`, `onze-server` (the route) | 51 |
| ONZ-51-DoD | the blog's README states the empty `remotePatterns`; § 16's prop table walked (`loader`, `unoptimized`, `overrideSrc`, `onLoad` / `onError` out of scope or honoured); the `/_onze/image` route registered through rakun 25; remote sources 501 | `onze-assets`, `examples/blog/README.md` (53's) | 51 |
| ONZ-52-gen | the font-metrics generator (`fontTools`) and the table's date (52-a); the local-font probe | `onze-assets/scripts/`, `font_metrics.bp` | 51 |
| ONZ-70-1 · 6 · 7 · DoD | defaults applied by route discovery (rakun 66); `measure` within 2 % of the rasterizer; one render per post under concurrency (rakun-cache 12); one supported-property table (`card_style.bp:39` adds `margin`, `border`) | `onze-og` | 51 |
| ONZ-71-2 · 5 · 7 · DoD | `includeErts`; `bin/onze` runs `verifyBuildId`; static export to disk + `examples/static-site/`; the release boots without source; the build id in three places; a non-root container; `scanForSecrets` over a real release | `onze-release`, `examples/static-site` | 71 |
| ONZ-53-3 … 7, DoD, e2e | prerender and metadata; `loading` / `error` / streaming; middleware, forms, `revalidateTag`, no-JS POST, `Origin` 403; the browser; `dev` serves every route and `dev == start`; the `// front NN` checker; `serve.sh` and the E2E runner (`bootApp`, `request`, `assertServeGate`) | `examples/blog/**`, `onze-test/src/e2e.bp` | 53 |
| PK-2 | `examples/blog/README.md`, `examples/scaffold/README.md` (the directory-level `examples/README.md` exists) | examples | 53 · 50 |
| the std copies | `onze/src/config.bp:98-130` (`pub` Json accessors), `onze-cli/src/{build:42,info:11}.bp`, `onze-bundler/src/entry.bp:182` (+ a `parseInt`), `onze-og/src/{svg:19,metrics:12}.bp` | per member | 49 · 50 · 51 ("consume std" steps after `97`) |

## Fronts

| Front | Priority | Carries | Parallel group | What |
|---|---|---|---|---|
| [`49-onze-stand-up/`](./49-onze-stand-up/README.md) | **critical** — the wiring every other front's proof runs through | 69 | A | `onze`, `onze-server`, `onze-test`'s root: query/headers, `serveActions`, the `log` sink, the public root (decision 201), the dynamic mark (decision 186), the `-test` group stubs |
| [`50-onze-cli/`](./50-onze-cli/README.md) | **high** — `onze dev` is the one command of the four that does not exist | 68 | A | `onze-cli`, `onze-bundler`, `examples/scaffold`: `dev`, `prerender/`, the signal, the defaults table, lazy starters, `assetPrefix`, `<Script>` callbacks |
| [`51-onze-image/`](./51-onze-image/README.md) | low | 52 · 70 | A | `onze-assets`' image and font files, `onze-og`: single-flight, the prop table, the metrics generator, the OG defaults, the 2 % test |
| [`71-onze-release-packaging/`](./71-onze-release-packaging/README.md) | medium | — | A (before `03-bundled-libs/107-release`) | `onze-release`, `examples/static-site`: `includeErts`, `bin/onze`, static export, the four gate boxes that need a real release |
| [`53-onze-example-app/`](./53-onze-example-app/README.md) | **high** — the proof of the whole stack; last | — | B | `examples/blog/**`, `onze-test/src/e2e.bp`: the acceptance script's second half, the browser, the E2E runner |

## Order

```
97-std-dedupe (02) ──► 49 step 1 · 50 step 1 · 51 step 1  (the "consume std" steps; the rest of each front does not wait)

03-bundled-libs/102 step 3 (types.bp, onze-cli/scan.bp, onze-bundler/chunk.bp) ──► before 49 and 50 open (decision 188)

49-onze-stand-up ──┐   49 step 6 (the onze-test group stubs) first: 50 · 51 · 71 · 53 each fill the file it creates for them
50-onze-cli ───────┤  (A: four members' worth of files, disjoint — see modules.md § Front → files)
51-onze-image ─────┤
71-onze-release ───┤   50 step 5 ("start calls bin/onze") waits on 71 step 2; 50 step 6 on 05-jhonstart/27 step 1
  (steps 1–4)      └──► 53-onze-example-app  (B: needs 49's wiring, 50's dev, 51's image route, 71's release; and 05-jhonstart 26 · 67, 04-rakun 22-front (24 · 25 · 60 · 66), 12-rakun-cache, 65-rakun-url-rules (82, decision 201))
                                  └──► 71 step 5 (the four gate boxes over the blog's real release: after 50 and 53)

inbound:  03-bundled-libs/106 (the `log` package) ──► 05-jhonstart/26 step 4 (the digest through log) ──► 49 step 3 (the sink)
          05-jhonstart/27 step 1 (applyTransition) ──► 50 step 6
          04-rakun 65 step 1 (the fall-through, decision 201) ──► 49 step 4 · 04-rakun 22-front (rakun 23's mark, 24's dispatcher, 60, 66) ──► 49 · 50 · 51 · 53
          03-bundled-libs/104's consumer sweep (onze-server/server.bp:61, image_handler.bp:92-99) — after 49 and 51 have landed · 107 (onze-release/{otp,docker,spec}.bp) — after 71 (decision 188)
          08-bpp, each after the front that owns the member: 117 (onze/src/paginate.bp, onze-cli/src/scan.bp) · 120 (one line of onze-server/server.bp) ·
                  121 (the new member onze-content; examples/blog/content after 53) · 122 (the `site` key of onze/src/config.bp) · 124 (onze-cli, onze-bundler, the other four keys, examples/scaffold)
```

49 is first because a request's query and headers, the action dispatcher and the error digest
are what 53's write path and error pages read; 50 is beside it because `dev` is a CLI concern
over the bundler's `rebuild`; 51 and 71 are independent members. 53 is last by construction:
it is read-only against every other repository and asserts what the four fronts land.

## Handed to 00-gate

| Item | File | Fix |
|---|---|---|
| ONZ-0 / PK-1 — three restricted cells with no ledger line; a full `zig build test-libs` fails on them | `repository/botopink-lang/scripts/restricted-targets.txt` | `00-gate/113-gate-ledger-and-scripts` — under `gate-a` the ledger file is **deleted**, not extended: a manifest's `targets` is the single source of truth, `test-libs` generates no cell for an excluded target, and an audit proves the exclusion is a host-binding refusal (`botopink build --target <excluded>` fails). No line is measured or added |
| STD-1 — no `*.snap.new` guard | `repository/onze/.gitignore`, `scripts/git-hooks/pre-commit` | the `02-std-and-packaging` track's row |
| the three markers in the copied 53 examples | `53-onze-example-app/examples/app-tree-example.bp:43` (`@Decl` carries no source location — row lg2-q, keep), `blog-slug-page-example.bp:84` and `lib-db-example.bp:88` ("no bottom type" — stale: `@panic` / `@todo` answer `noreturn` since 01-checker; lg2-l is the open half, whether a user fn may be `noreturn`) | 53 step 1 removes the two stale markers and keeps lg2-q's; the gate's marker grep then finds one marker with a row |
| the `// front NN` comments in `examples/blog/**` naming 1.0.10 fronts | `repository/onze/examples/blog/src/**` | 53 step 6 rewrites them to this milestone's directories; the gate's checker (53's DoD box) reads `specs/1.0.11-beta/` |

## Maintainer decisions

Ids kept from 1.0.10 (`specs/1.0.10-beta/decisions-pending.md` § Track E); new questions continue
each front's letter sequence. Numbered decisions continue from 225 when answered.

### To confirm

| Id | Choice | Closes |
|---|---|---|
| 49-a | the core's suites render through the core's `describe*`; `onze-test` wraps | — |
| 49-c | `onze.json` refuses an unknown key | — |
| 49-d | `chainFor` takes the ancestor patterns; onze imports nothing from `routing` — **`03-bundled-libs/102` reverses the second half** (`types.bp:101-127` consumes `routing.conventions`); confirm 49-d as amended by 102 | 49 |
| 49-e | the rakun half of the boot is `onze-server` | 49 step 2 (the wording box) |
| 50-a | `onze build` stages a server main; `onze start` runs it with `erl` — **amended**: `start` calls front 71's `bin/onze` once it exists (71 step 2; 50 step 5) | 50 |
| 52-a | the metrics table transcribed, its generator owed | 51 step 4 |
| 53-a | the blog under `src/` | — |
| 68-a · 68-c · 68-d | manifest escaping; starters decode `#[clientProps]` from source; the styleMap probe in both packages | — |
| 69-a | `AssetRoot` converted to front 82's `StaticRoot` in `onze-server` | — |
| 69-b | answered — decision 201: a miss inside a root falls through to the chain, only `GET` / `HEAD` are served, a refusal stays final (`04-rakun/65-rakun-url-rules`, carrying 82); `Onze.run` registers `public/` at `/**` before the routes | 49 step 4 |

### Answered

| Id | Decision | What the fronts implement |
|---|---|---|
| 49-f | 186 | nobody writes a dynamic mark at run time: the stage a page renders in is a compile-time fact, the build writes the route kind and rakun reads it. Until the checker capability lands, the renderer marks through `ChunkWriter.markDynamic(reason)` and rakun's own reads never mark (49 step 5; `04-rakun/22` step 4; `05-jhonstart/26` step 8) |
| 31-b (`05-jhonstart`) · 07-f (`03-bundled-libs`) | 194 · 195 | one digest, in the bundled `log`; onze sets the sink and nothing else (49 step 3) |

### 50-b · What `onze dev` does on a change — reload into the running node, or restart it

> **Raised by:** front 50, step 2
> **Measured.** `onze build` compiles the server package to BEAM (`server/beam/`) and `onze start`
> runs `erl -noshell -pa <outDir>/server/beam -eval …` (50-a). `onze-bundler/src/rebuild.bp` computes
> which modules a changed file invalidates. The BEAM can `code:load_file/1` a recompiled module
> into a running node; jhonstart's UI registry and rakun's route table are filled at module load
> (decision 140), so a reloaded page module re-registers, but a *new* route file needs the
> generated `onze_routes.bp` regenerated and the table rebuilt.
> **Options.** (a) restart the node on every change: `dev` is `build` + `start` in a loop over a
> file watcher — the same bytes `start` serves, by construction (the "dev == start" box is a
> tautology), a 1–3 s restart per edit; (b) hot-load changed modules (`code:load_file`) and
> regenerate + reload `onze_routes` when the app tree changes; island state in the browser is
> lost either way (Fast Refresh is a non-goal, `reference-holes.md` § 29); (c) (b) with a
> fallback to (a) when the changed set includes a convention file.
> **Recommendation.** (a) — the most restrictive: one code path, nothing that can drift from what
> `start` serves, and the "serves the same routes" box is proved by construction. (b) is an
> optimisation for a later milestone once (a) is measured too slow on the blog.
> **Blocks.** 50 step 2's acceptance (written for (a)); 53 step 5 ("`dev` serves every route").

### 53-b · The onze module-level snapshot maps — realise or retire; the E2E runner stays

> **Raised by:** front 53, from `06-onze/test-snap.md` §§ 50 · 51 · 52 · 70 · 71 and
> `test-snap-examples.md` (copied into the front directories)
> **Measured.** §§ 49 · 68 · 69 of the map are realised (the core's `describe*` suites through
> `snapshots.assertAs`, 49-a; the bundler's 42 tests; the assets' 12). §§ 50 · 51 · 52 · 70 · 71
> are not: the suites exist (`scan_test`, `generate_test`, `create_test`, `build_test`,
> `start_test`, `image_test`, `font_test`, `og_test`, `build_id_test`, `release_text_test`,
> `package_test`) with inline literals, no `.snap`. The one thing another library reads from
> these members is the client manifest (`client-manifest.txt`, § 68 — realised, both targets)
> and the release layout (`docs.md`).
> **Options.** (a) retire §§ 50 · 51 · 52 · 70 · 71: inline literals are the evidence; keep the
> E2E runner of `test-snap-examples.md` (`bootApp`, `request`, `assertResponse`, `assertServeGate`)
> because it is not a snapshot map but the harness 53's acceptance script runs on; (b) realise
> the five sections (~120 `.snap` files); (c) realise only § 71's `release_text_test.bp` (the
> `.rel` / `vm.args` / `sys.config` text is what `107-release` must reproduce byte for byte —
> a contract another package will read).
> **Recommendation.** (c) — the one section whose snapshot proves a contract another library
> reads (`107-release` extracts the renderers and must keep the text); the rest as (a). The E2E
> runner is written regardless (53 step 1).
> **Blocks.** 71 step 6 (conditional); 50 · 51's "record the map" steps (struck under (a)/(c)).
