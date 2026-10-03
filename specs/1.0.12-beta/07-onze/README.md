# Track 07 — onze

**Repo:** `repository/onze` · **Reference:** Next.js docs, the framework half · the tree on disk
is [`modules.md`](./modules.md); the Next.js rows no front covers are
[`reference-holes.md`](./reference-holes.md).

onze wires (decision 113): it is the one package that imports jhonstart, rakun and the
`jhonstart-emilia` bridge together, and where the libraries meet in an example (decision 114).
Its eight members and the blog (`examples/blog`, served by `onze build && onze start`) exist.
What this track owes: the wiring that waited on rakun, `onze dev`, the release end to end, the
image/font/OG tails, and the second half of the blog's acceptance script. Five fronts, cut by
member.

## Fronts

| Front | Priority | State | What | Depends on (open) |
|---|---|---|---|---|
| [`49-onze-stand-up/`](./49-onze-stand-up/README.md) | **critical** | not started | `onze`, `onze-server`, `onze-test`'s root: std's Json accessors, query/headers, `serveActions`, the `log` sink, the public root (decision 201), the dynamic-mark bridge (decision 186), the `-test` group stubs | 102 step 3 (`types.bp`); jhonstart 26 step 4 · `04-rakun/17` (step 3); `04-rakun/65` step 1 (step 4); `04-rakun/22` step 4 (step 5); 49-e |
| [`50-onze-cli/`](./50-onze-cli/README.md) | **high** | not started (step 7: the defaults record already drives `--help`) | `onze-cli`, `onze-bundler`, `examples/scaffold`: `dev`, `prerender/`, the signal, the defaults table, lazy starters, `assetPrefix`, `<Script>` callbacks | 102 step 3 (`scan.bp`, `chunk.bp`); 50-b; `std-d`; 71 step 2 (step 5); jhonstart 27 step 1 (step 6); 49 step 6 |
| [`51-onze-image/`](./51-onze-image/README.md) | low | not started | `onze-assets`' image and font files, `onze-og`: single flight, the route, the § 16 prop table, the metrics generator, the OG defaults, the 2 % test | `04-rakun/22` (25, 66); 52-a; 53-b; 49 step 6 |
| [`71-onze-release-packaging/`](./71-onze-release-packaging/README.md) | medium | not started (step 6's snapshots on disk) | `onze-release`, `examples/static-site`: the ERTS copy, `bin/onze`, the shutdown over real cells, static export, the four gate boxes over a real release | 49 step 6; `04-rakun` 11 · 04 (62) · 81 (step 3); 50 · 53 (step 5) |
| [`53-onze-example-app/`](./53-onze-example-app/README.md) | **high** — the proof of the whole stack; last | not started | `examples/blog/**`, `onze-test/src/e2e.bp`: the acceptance script's second half, the browser, the E2E runner | every front above; jhonstart 26 · 27 · 67; `04-rakun` 22 (24 · 25 · 60 · 66) · 12 · 65 |

The "consume std" first steps of 49, 50 and 51 are unblocked (`97` is on `feat`), and so is 49
step 3's half that needs the bundled `log` (`106` is on `feat`).

## Order

```
03-bundled-libs/102 step 3 (types.bp, onze-cli/scan.bp, onze-bundler/chunk.bp) ──► before 49 and 50 open (decision 188)

49 step 6 (the onze-test group stubs) first: 50 · 51 · 71 · 53 each fill the file it creates for them
49 · 50 · 51 · 71 steps 1, 2, 4 ── parallel (disjoint members, modules.md § Front → files)
   50 step 5 waits on 71 step 2 · 50 step 6 on 05-jhonstart/27 step 1 · 71 step 3 on 04-rakun 11 / 04 (62) / 81
   └──► 53 (needs 49's wiring, 50's dev, 51's image route, 71's release)
          └──► 71 step 5 (the four gate boxes over the blog's real release)

inbound:  05-jhonstart/26 step 4 · 04-rakun/17 ──► 49 step 3 (the sink)
          04-rakun/65 step 1 (the fall-through, decision 201) ──► 49 step 4
          04-rakun/22 (rakun 23's mark, 24, 25, 60, 66) ──► 49 · 50 · 51 · 53
outbound: 03-bundled-libs/104's consumer sweep (onze-server/server.bp `cookiePairs`, image_handler.bp's MIME table) — after 49 and 51
          03-bundled-libs/107 (onze-release/{otp,docker,spec}.bp) — after 71 (decision 188)
          08-bpp 117 · 120 · 121 · 122 · 124 — each after the front that owns the member (modules.md)
```

49 is first because a request's query and headers, the action dispatcher and the error digest
are what 53's write path and error pages read; 51 and 71 are independent members; 53 is
read-only against every other member and asserts what the four fronts land.

## Decisions

Ids kept from 1.0.10 (`../1.0.10-beta/decisions-pending.md` § Track E); new questions continue
each front's letter sequence; numbered decisions continue from the last one in
`../decisions-taken.md`.

### To confirm

| Id | Choice | Closes |
|---|---|---|
| 49-a | the core's suites render through the core's `describe*`; `onze-test` wraps | — |
| 49-c | `onze.json` refuses an unknown key | — |
| 49-d | `chainFor` takes the ancestor patterns; onze imports nothing from `routing` — **amended by `03-bundled-libs/102`** (`types.bp`'s segment classification consumes `routing.conventions`) | 49 |
| 49-e | the rakun half of the boot is `onze-server` | 49 step 2 (the wording box) |
| 50-a | `onze build` stages a server main; `onze start` runs it — **amended**: `start` calls 71's `bin/onze` (71 step 2; 50 step 5) | 50 |
| 52-a | the metrics table transcribed, its generator owed | 51 step 4 |
| 53-a | the blog under `src/` | — |
| 68-a · 68-c · 68-d | manifest escaping; starters decode `#[clientProps]` from source; the styleMap probe in both packages | — |
| 69-a | `AssetRoot` converted to rakun-web's `StaticRoot` in `onze-server` | — |

### 50-b · What `onze dev` does on a change — reload into the running node, or restart it

> **Raised by:** front 50, step 2
> **Facts.** `onze build` compiles the server package to BEAM (`server/beam/`); `onze start` runs
> `erl -noshell -pa <outDir>/server/beam -eval …` (50-a). `onze-bundler/src/rebuild.bp` computes
> which modules a changed file invalidates. The BEAM can `code:load_file/1` a recompiled module;
> jhonstart's UI registry and rakun's route table are filled at module load (decision 140), so a
> reloaded page module re-registers, but a *new* route file needs `onze_routes.bp` regenerated
> and the table rebuilt.
> **Options.** (a) restart the node on every change: `dev` is `build` + `start` in a loop over a
> file watcher — the same bytes `start` serves by construction, a 1–3 s restart per edit;
> (b) hot-load changed modules and regenerate + reload `onze_routes` when the app tree changes
> (island state is lost either way; Fast Refresh is a non-goal, `reference-holes.md` § 29);
> (c) (b) with a fallback to (a) when the changed set includes a convention file.
> **Recommendation.** (a) — one code path, nothing that can drift from `start`; (b) is a later
> optimisation once (a) is measured too slow on the blog.
> **Blocks.** 50 step 2 (written for (a)); 53 step 6 ("`dev` serves every route").

### 53-b · The onze module-level snapshot maps — realise or retire; the E2E runner stays

> **Raised by:** front 53, from the maps copied as `50-onze-cli/test-snap.md` (§ 50),
> `51-onze-image/test-snap.md` (§§ 51 · 52 · 70), `71-onze-release-packaging/test-snap.md` (§ 71)
> and `53-onze-example-app/test-snap-examples.md`
> **Facts.** §§ 49 · 68 · 69 are realised (the core's `describe*` suites, the bundler's 42 tests,
> the assets' styling). The members of §§ 50–71 hold 24 `.snap` files, written through std's
> `snapshots.assertAs` rather than the map's `onze-test` helpers: `onze-cli` 5 (`scan` 2,
> `generate` 1, `create` 2), `onze-assets` 10 (`font` 4, `image` 3, `assets`, `css_module`,
> `stylesheet` 1 each), `onze-og` 4, `onze-release` 5 (the `.rel` / `sys.config` / `vm.args` /
> boot-script text, the Dockerfile, the build id, the shutdown, the static export). The rest of
> each map is inline literals. What another library reads from these members is the client
> manifest (§ 68, realised) and the release text, which `03-bundled-libs/107-release` must
> reproduce byte for byte.
> **Options.** (a) retire the unrealised rows of §§ 50 · 51 · 52 · 70 · 71: the 24 `.snap` and
> the inline literals are the evidence; (b) realise every section through the `onze-test`
> helpers (~120 `.snap`); (c) as (a), naming § 71's release snapshots as the one contract
> another package keeps — already on disk.
> **Recommendation.** (c). The E2E runner of `test-snap-examples.md` (`bootApp`, `request`,
> `assertResponse`, `assertServeGate`) is not a snapshot map but the harness 53's acceptance
> script runs on, and is written regardless (53 step 1).
> **Blocks.** 71 step 6 (its last box); 50 step 8 and 51 step 7 (struck under (a)/(c)).
